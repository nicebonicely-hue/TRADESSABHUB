--[[
=========================================================================
  VENICE | Steal a Brainrot - PvP Toolkit
  Delta Executor / Lua
  Modulos: Lag, AutoGrab (bases ajenas), BatAimbot, AutoMedusa,
           FakePos, AntiKnockback, AutoDrop, Logger
=========================================================================
  Estructura pensada para el log del place de duelos:
    ReplicatedStorage.Packages.Net.RE  (RemoteEvents)
    ReplicatedStorage.Packages.Net.RF  (RemoteFunctions)
  Remotes confirmados en log: UseItem, Tools/Equip, LaserGun_Impact,
  LaserGun_ImpactCharacter, BaseIndexService/Claim,
  DuelsMachineService/*, CandyCornDropService/GetDrops
=========================================================================
]]

if _G.__VENICE_SAB_PVP then
    pcall(function() _G.__VENICE_SAB_PVP:Destroy() end)
end

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")

local lp = Players.LocalPlayer

-- ======================================================================
-- CONFIG
-- ======================================================================

local CFG = {
    -- AutoGrab
    grabEnabled     = false,
    grabDelay       = 0.15,
    grabTeleport    = true,
    grabReturn      = true,
    grabRadius      = 260,
    grabOnlyTargets = false,
    grabBlacklist   = {},

    -- BatAimbot
    batEnabled      = false,
    batRange        = 14,
    batRepath       = 0.10,

    -- AutoMedusa
    medusaEnabled   = false,
    medusaWindow    = 1.0,

    -- FakePos
    fakeEnabled     = false,
    fakeRadius      = 6,
    fakeHz          = 0.02,

    -- AntiKnockback
    akbEnabled      = false,
    akbPreserveMove = true,

    -- AutoDrop
    dropEnabled     = false,

    -- Lag
    lagEnabled      = false,
    lagRadius       = 22,
    lagHz           = 0.06,

    -- Targets marcados (clave: nombre normalizado)
    targets         = {},
}

local STEAL_WORDS = { "steal", "grab", "take", "robar", "agarrar", "tomar" }
local DROP_WORDS  = { "drop", "soltar", "dejar" }
local BAT_WORDS   = { "bat", "bate" }
local MEDUSA_WORDS= { "medusa" }

local NAME_ATTRS = {
    "BrainrotName", "DisplayName", "ItemName", "UnitName", "PetName",
    "Name", "Rarity",
}
local OWNER_ATTRS = {
    "Owner", "OwnerId", "UserId", "PlayerName", "BaseOwner",
    "OwnerName", "DisplayName", "BaseId",
}
local BASE_HINTS = { "base", "bases", "playerbase", "playerbases", "plots", "plot", "slot" }

-- ======================================================================
-- UTILIDADES
-- ======================================================================

local function net()
    local pkg = ReplicatedStorage:FindFirstChild("Packages")
    local n = pkg and pkg:FindFirstChild("Net")
    if not n then return nil, nil end
    return n:FindFirstChild("RE"), n:FindFirstChild("RF")
end

local function remote(name)
    local RE = net()
    return RE and RE:FindFirstChild(name, true)
end

local function fire(name, ...)
    local r = remote(name)
    if not r then return false end
    local args = { ... }
    return pcall(function() r:FireServer(unpack(args)) end)
end

local function norm(s)
    return tostring(s or ""):match("^%s*(.-)%s*$"):lower():gsub("%s+", " ")
end

local function hasWord(str, list)
    str = tostring(str or ""):lower()
    for _, w in ipairs(list) do
        if str:find(w, 1, true) then return true end
    end
    return false
end

local function hrp()
    local c = lp.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function hum()
    local c = lp.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function alive()
    local h = hum()
    return h and h.Health > 0 and hrp() ~= nil
end

local function dist(a, b)
    return (a - b).Magnitude
end

local function normalizeName(v)
    if type(v) ~= "string" then return nil end
    v = v:match("^%s*(.-)%s*$")
    if #v < 2 or #v > 64 then return nil end
    if v:match("^%$?[%d%.,]+$") then return nil end
    local l = v:lower()
    if l == "part" or l == "model" or l == "base" or l == "prompt"
        or l == "pedestal" or l == "hitbox" then return nil end
    return v
end

local function brainrotName(inst)
    local node = inst
    for _ = 1, 8 do
        if not node then break end
        for _, a in ipairs(NAME_ATTRS) do
            local v = normalizeName(node:GetAttribute(a))
            if v then return v end
        end
        if node:IsA("Model") then
            local v = normalizeName(node.Name)
            if v then return v end
        end
        node = node.Parent
    end
    return nil
end

local function ownerOfBase(container)
    local node = container
    for _ = 1, 4 do
        if not node or node == workspace then break end
        for _, a in ipairs(OWNER_ATTRS) do
            local v = node:GetAttribute(a)
            if typeof(v) == "number" then
                local p = Players:GetPlayerByUserId(v)
                if p then return p end
            elseif type(v) == "string" then
                local p = Players:FindFirstChild(v)
                if p then return p end
            end
        end
        for _, p in ipairs(Players:GetPlayers()) do
            if node.Name == p.Name or node.Name == p.DisplayName then
                return p
            end
        end
        node = node.Parent
    end
    return nil
end

local function toolByWords(list)
    local c = lp.Character
    if c then
        for _, t in ipairs(c:GetChildren()) do
            if t:IsA("Tool") and hasWord(t.Name, list) then return t, true end
        end
    end
    local bp = lp:FindFirstChildOfClass("Backpack")
    if bp then
        for _, t in ipairs(bp:GetChildren()) do
            if t:IsA("Tool") and hasWord(t.Name, list) then return t, false end
        end
    end
    return nil, false
end

local function activateTool(tool, equipped)
    local h = hum()
    if not h or not tool then return end
    if not equipped then pcall(function() h:EquipTool(tool) end) end
    pcall(function() tool:Activate() end)
    fire("UseItem", tool)
    fire("Tools/Equip", tool)
end

local function firePrompt(prompt)
    if typeof(fireproximityprompt) == "function" then
        if pcall(fireproximityprompt, prompt) then return true end
    end
    return pcall(function()
        prompt:InputHoldBegin()
        task.wait(0.02)
        prompt:InputHoldEnd()
    end)
end

-- ======================================================================
-- LOGGER
-- ======================================================================

local Logger = { lines = {}, gui = nil, frame = nil }

function Logger.push(kind, msg)
    local stamp = os.date("%H:%M:%S")
    local line = string.format("[%s] %s %s", stamp, kind, msg)
    table.insert(Logger.lines, 1, line)
    if #Logger.lines > 60 then table.remove(Logger.lines) end
    if Logger.frame then
        local ok, lbl = pcall(function() return Logger.frame end)
        if ok and lbl then
            lbl.Text = table.concat(Logger.lines, "\n", 1, math.min(#Logger.lines, 14))
        end
    end
end

-- ======================================================================
-- DETECCION DE BASES Y BRAINROTS
-- ======================================================================

local BaseScan = {
    entries = {},
    lastScan = 0,
}

local function isStealPrompt(p)
    return hasWord(p.ActionText, STEAL_WORDS) or hasWord(p.ObjectText, STEAL_WORDS)
end

local function baseContainers()
    local out = {}
    local seen = {}

    local function consider(inst)
        if not inst or seen[inst] then return end
        if not (inst:IsA("Model") or inst:IsA("Folder")) then return end
        seen[inst] = true
        if ownerOfBase(inst) then out[#out + 1] = inst end
    end

    -- Estrategia 1: carpeta de bases en workspace
    for _, child in ipairs(workspace:GetChildren()) do
        if (child:IsA("Folder") or child:IsA("Model"))
            and hasWord(child.Name, BASE_HINTS) then
            for _, sub in ipairs(child:GetChildren()) do consider(sub) end
        end
    end

    -- Estrategia 2: hijos directos de workspace que parezcan base
    if #out == 0 then
        for _, child in ipairs(workspace:GetChildren()) do consider(child) end
    end

    return out
end

function BaseScan.run()
    local entries = {}
    local containers = baseContainers()

    for _, base in ipairs(containers) do
        local owner = ownerOfBase(base)
        if owner and owner ~= lp then
            for _, d in ipairs(base:GetDescendants()) do
                if d:IsA("ProximityPrompt") and isStealPrompt(d) then
                    local name = brainrotName(d)
                    if name and not CFG.grabBlacklist[norm(name)] then
                        local node = d.Parent
                        local pos
                        for _ = 1, 6 do
                            if not node then break end
                            if node:IsA("BasePart") then pos = node.Position break end
                            if node:IsA("Model") then pos = node:GetPivot().Position break end
                            node = node.Parent
                        end
                        if pos then
                            entries[#entries + 1] = {
                                prompt = d,
                                name = name,
                                key = norm(name),
                                owner = owner.Name,
                                ownerId = owner.UserId,
                                position = pos,
                                base = base,
                            }
                        end
                    end
                end
            end
        end
    end

    BaseScan.entries = entries
    BaseScan.lastScan = os.clock()
    return entries
end

-- ======================================================================
-- MODULO: AUTO GRAB
-- ======================================================================

local AutoGrab = { active = false, thread = nil, cooldowns = setmetatable({}, { __mode = "k" }) }
local stats = { grabs = 0, tries = 0 }

function AutoGrab.tick()
    if not alive() then return end
    local root = hrp()
    local now = os.clock()

    local best, bestDist
    for _, e in ipairs(BaseScan.entries) do
        local p = e.prompt
        if p and p.Parent and p.Enabled then
            if not CFG.grabOnlyTargets or CFG.targets[e.key] then
                local d = dist(root.Position, e.position)
                if d <= CFG.grabRadius then
                    local cd = AutoGrab.cooldowns[p]
                    if not cd or (now - cd) >= CFG.grabDelay then
                        if not bestDist or d < bestDist then
                            best, bestDist = e, d
                        end
                    end
                end
            end
        end
    end

    if not best then return end
    AutoGrab.cooldowns[best.prompt] = now
    stats.tries = stats.tries + 1

    local saved = root.CFrame
    local moved = false

    if CFG.grabTeleport then
        root.CFrame = CFrame.new(best.position + Vector3.new(0, 3, 0))
        moved = true
        task.wait(0.05)
    end

    local p = best.prompt
    if not p or not p.Parent then
        if moved and root.Parent then root.CFrame = saved end
        return
    end

    local hold = p.HoldDuration
    pcall(function() p.HoldDuration = 0 end)
    firePrompt(p)
    pcall(function() p.HoldDuration = hold end)

    task.wait(0.04)

    if moved and CFG.grabReturn and root.Parent then
        root.CFrame = saved
    end

    if p.Parent and not p.Enabled then
        stats.grabs = stats.grabs + 1
        Logger.push("[GRAB]", "Robado: " .. best.name .. " (" .. best.owner .. ")")
    end
end

function AutoGrab.start()
    if AutoGrab.thread then return end
    AutoGrab.thread = task.spawn(function()
        while AutoGrab.active do
            local ok, err = pcall(AutoGrab.tick)
            if not ok then Logger.push("[ERR]", "Grab: " .. tostring(err)) end
            task.wait(CFG.grabDelay)
        end
        AutoGrab.thread = nil
    end)
end

function AutoGrab.stop()
    AutoGrab.active = false
    AutoGrab.thread = nil
end

-- ======================================================================
-- MODULO: BAT AIMBOT
-- ======================================================================

local Bat = { active = false, thread = nil, target = nil }

local function nearestEnemy(maxDist)
    local root = hrp()
    if not root then return nil end
    local best, bestD
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= lp and p.Character then
            local t = p.Character:FindFirstChild("HumanoidRootPart")
            local h = p.Character:FindFirstChildOfClass("Humanoid")
            if t and h and h.Health > 0 then
                local d = dist(root.Position, t.Position)
                if d <= maxDist and (not bestD or d < bestD) then
                    best, bestD = p, d
                end
            end
        end
    end
    return best
end

function Bat.tick()
    if not alive() then return end
    local h, root = hum(), hrp()

    local enemy = nearestEnemy(300)
    Bat.target = enemy
    if not enemy then return end

    local t = enemy.Character:FindFirstChild("HumanoidRootPart")
    if not t then return end

    local d = dist(root.Position, t.Position)

    -- Rotacion hacia el objetivo
    local look = CFrame.new(root.Position, Vector3.new(t.Position.X, root.Position.Y, t.Position.Z))
    root.CFrame = look

    if d > CFG.batRange then
        pcall(function() h:MoveTo(t.Position) end)
        return
    end

    local tool, equipped = toolByWords(BAT_WORDS)
    if not tool then
        Logger.push("[BAT]", "Sin bate equipado")
        return
    end
    activateTool(tool, equipped)
end

function Bat.start()
    if Bat.thread then return end
    Bat.thread = task.spawn(function()
        while Bat.active do
            local ok, err = pcall(Bat.tick)
            if not ok then Logger.push("[ERR]", "Bat: " .. tostring(err)) end
            task.wait(CFG.batRepath)
        end
        Bat.thread = nil
    end)
end

function Bat.stop()
    Bat.active = false
    Bat.thread = nil
    Bat.target = nil
    local h = hum()
    if h then pcall(function() h:MoveTo(h.Parent.HumanoidRootPart.Position) end) end
end

-- ======================================================================
-- MODULO: AUTO MEDUSA
-- ======================================================================

local Medusa = {
    active = false,
    enemyUsedAt = 0,
    lastFire = 0,
    conns = {},
}

local FREEZE_WORDS = { "freeze", "frozen", "ice", "hielo", "stone", "piedra", "medusa", "stun" }

function Medusa.watchCharacter(p)
    if p == lp then return end
    local function hook(char)
        char.ChildAdded:Connect(function(c)
            if c:IsA("Tool") and hasWord(c.Name, MEDUSA_WORDS) then
                Medusa.enemyUsedAt = os.clock()
                Logger.push("[MED]", p.Name .. " equipó Medusa")
            end
            if hasWord(c.Name, FREEZE_WORDS) then
                Medusa.enemyUsedAt = os.clock()
            end
        end)
    end
    if p.Character then hook(p.Character) end
    table.insert(Medusa.conns, p.CharacterAdded:Connect(hook))
end

function Medusa.fireBack()
    if not alive() then return end
    local now = os.clock()
    if (now - Medusa.lastFire) < 0.05 then return end
    Medusa.lastFire = now

    local tool, equipped = toolByWords(MEDUSA_WORDS)
    if not tool then return end

    -- Reset de cooldown local antes de disparar
    pcall(function()
        tool:SetAttribute("Cooldown", 0)
        tool:SetAttribute("LastUse", 0)
        tool:SetAttribute("LastUsed", 0)
        tool:SetAttribute("NextUse", 0)
    end)

    activateTool(tool, equipped)
    Logger.push("[MED]", "Contra-Medusa disparada")
end

local function onLocalFreeze()
    if not Medusa.active then return end
    if not alive() then return end
    local recent = (os.clock() - Medusa.enemyUsedAt) <= CFG.medusaWindow
    if recent then
        Medusa.fireBack()
    end
end

function Medusa.start()
    Medusa.active = true
    for _, p in ipairs(Players:GetPlayers()) do Medusa.watchCharacter(p) end
    table.insert(Medusa.conns, Players.PlayerAdded:Connect(Medusa.watchCharacter))

    -- Deteccion de congelamiento local
    local lastSpeed = 0
    table.insert(Medusa.conns, RunService.Heartbeat:Connect(function()
        if not Medusa.active then return end
        local h = hum()
        if not h then return end
        if lastSpeed > 1 and h.WalkSpeed < 0.5 then
            onLocalFreeze()
        end
        lastSpeed = h.WalkSpeed
    end))
end

function Medusa.stop()
    Medusa.active = false
    for _, c in ipairs(Medusa.conns) do pcall(function() c:Disconnect() end) end
    Medusa.conns = {}
end

-- ======================================================================
-- MODULO: FAKE POSITION (evasion de aimbot enemigo)
-- ======================================================================

local FakePos = { active = false, conn = nil, originXZ = nil, rot = nil }

local function randCircle(r)
    local a = math.random() * math.pi * 2
    local d = math.random() * r
    return Vector3.new(math.cos(a) * d, 0, math.sin(a) * d)
end

function FakePos.start()
    if FakePos.active then return end
    local root = hrp()
    if not root then return end
    FakePos.active = true
    FakePos.originXZ = root.Position * Vector3.new(1, 0, 1)
    FakePos.rot = root.CFrame - root.CFrame.Position
    local acc = 0

    FakePos.conn = RunService.Heartbeat:Connect(function(dt)
        if not FakePos.active then return end
        if CFG.lagEnabled then return end -- no pelear con el modulo de lag
        local h, r = hum(), hrp()
        if not h or not r then return end

        local md = h.MoveDirection
        if md.Magnitude > 0.05 then
            FakePos.originXZ = FakePos.originXZ
                + Vector3.new(md.X, 0, md.Z) * (h.WalkSpeed * dt)
        end

        acc = acc + dt
        if acc < CFG.fakeHz then return end
        acc = 0

        local y = r.Position.Y
        local base = FakePos.originXZ + randCircle(CFG.fakeRadius)
        r.CFrame = CFrame.new(Vector3.new(base.X, y, base.Z)) * FakePos.rot
    end)
end

function FakePos.stop()
    FakePos.active = false
    if FakePos.conn then FakePos.conn:Disconnect() end
    FakePos.conn = nil
end

-- ======================================================================
-- MODULO: ANTI-KNOCKBACK CON MOVIMIENTO
-- ======================================================================

local AKB = { active = false, conn = nil }

function AKB.start()
    if AKB.active then return end
    AKB.active = true
    AKB.conn = RunService.Heartbeat:Connect(function()
        if not AKB.active then return end
        local h, r = hum(), hrp()
        if not h or not r then return end

        local v = r.AssemblyLinearVelocity
        local md = h.MoveDirection

        local wantX, wantZ = 0, 0
        if CFG.akbPreserveMove and md.Magnitude > 0.05 then
            local spd = h.WalkSpeed
            wantX = md.Unit.X * spd
            wantZ = md.Unit.Z * spd
        end

        -- Conserva la vertical (gravedad/salto) y anula el impulso horizontal
        r.AssemblyLinearVelocity = Vector3.new(wantX, v.Y, wantZ)
        r.AssemblyAngularVelocity = Vector3.new(0, r.AssemblyAngularVelocity.Y, 0)

        if h.PlatformStand then h.PlatformStand = false end
    end)
end

function AKB.stop()
    AKB.active = false
    if AKB.conn then AKB.conn:Disconnect() end
    AKB.conn = nil
end

-- ======================================================================
-- MODULO: AUTO DROP
-- ======================================================================

local AutoDrop = { active = false, thread = nil, conn = nil, busy = false }

local function carryingBrainrot()
    local c = lp.Character
    if not c then return nil end
    for _, t in ipairs(c:GetChildren()) do
        if t:IsA("Tool")
            and not hasWord(t.Name, BAT_WORDS)
            and not hasWord(t.Name, MEDUSA_WORDS) then
            return t
        end
    end
    return nil
end

function AutoDrop.tick()
    if not alive() then return end
    local tool = carryingBrainrot()
    if not tool then return end

    local h, r = hum(), hrp()
    local saved = r.AssemblyLinearVelocity

    pcall(function() tool:Activate() end)
    fire("UseItem", tool)

    -- Ventana de 0 knockback
    local t0 = os.clock()
    while os.clock() - t0 < 0.25 do
        if r.Parent then
            r.AssemblyLinearVelocity = Vector3.new(0, r.AssemblyLinearVelocity.Y, 0)
        end
        task.wait(0.01)
    end
    Logger.push("[DROP]", "Drop forzado: " .. tool.Name)
end

function AutoDrop.start()
    if AutoDrop.thread then return end
    AutoDrop.active = true
    AutoDrop.thread = task.spawn(function()
        while AutoDrop.active do
            pcall(AutoDrop.tick)
            task.wait(0.2)
        end
        AutoDrop.thread = nil
    end)
end

function AutoDrop.stop()
    AutoDrop.active = false
    AutoDrop.thread = nil
end

-- ======================================================================
-- MODULO: LAG / DESINCRONIZACION
-- ======================================================================

local Lag = { active = false, thread = nil }

function Lag.start()
    if Lag.thread then return end
    Lag.active = true
    Lag.thread = task.spawn(function()
        while Lag.active do
            local r, h = hrp(), hum()
            if r and h then
                local saved = r.CFrame
                local far = saved.Position + randCircle(CFG.lagRadius) + Vector3.new(0, math.random(-6, 6), 0)
                r.CFrame = CFrame.new(far) * (saved - saved.Position)
                task.wait(CFG.lagHz / 2)
                if r.Parent then r.CFrame = saved end
                task.wait(CFG.lagHz / 2)
            else
                task.wait(0.1)
            end
        end
        Lag.thread = nil
    end)
end

function Lag.stop()
    Lag.active = false
    Lag.thread = nil
end

-- ======================================================================
-- INTERFAZ
-- ======================================================================

local parentGui
if typeof(gethui) == "function" then
    local ok, res = pcall(gethui)
    if ok then parentGui = res end
end
parentGui = parentGui or game:GetService("CoreGui")

local gui = Instance.new("ScreenGui")
gui.Name = "VeniceSAB_PVP"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = parentGui
_G.__VENICE_SAB_PVP = gui

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 300, 0, 470)
main.Position = UDim2.new(0, 24, 0, 90)
main.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.ClipsDescendants = true
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 8)

local stroke = Instance.new("UIStroke", main)
stroke.Color = Color3.fromRGB(40, 52, 78)
stroke.Thickness = 1

local bar = Instance.new("Frame")
bar.Size = UDim2.new(1, 0, 0, 28)
bar.BackgroundColor3 = Color3.fromRGB(22, 24, 32)
bar.BorderSizePixel = 0
bar.Parent = main
Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 8)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -70, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.Text = "SAB // PVP TOOLKIT"
title.TextColor3 = Color3.fromRGB(190, 205, 235)
title.Font = Enum.Font.GothamBold
title.TextSize = 11
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = bar

local function mkIcon(txt, x, color, cb)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 22, 0, 22)
    b.Position = UDim2.new(1, x, 0, 3)
    b.BackgroundColor3 = Color3.fromRGB(30, 33, 44)
    b.BorderSizePixel = 0
    b.Text = txt
    b.TextColor3 = color
    b.Font = Enum.Font.GothamBold
    b.TextSize = 11
    b.Parent = bar
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)
    b.MouseButton1Click:Connect(cb)
    return b
end

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -16, 1, -100)
scroll.Position = UDim2.new(0, 8, 0, 34)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 3
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.Parent = main

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 5)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = scroll
layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 6)
end)

local logBox = Instance.new("Frame")
logBox.Size = UDim2.new(1, -16, 0, 58)
logBox.Position = UDim2.new(0, 8, 1, -64)
logBox.BackgroundColor3 = Color3.fromRGB(9, 9, 12)
logBox.BorderSizePixel = 0
logBox.Parent = main
Instance.new("UICorner", logBox).CornerRadius = UDim.new(0, 5)

local logLabel = Instance.new("TextLabel")
logLabel.Size = UDim2.new(1, -10, 1, -6)
logLabel.Position = UDim2.new(0, 5, 0, 3)
logLabel.BackgroundTransparency = 1
logLabel.Text = ""
logLabel.TextColor3 = Color3.fromRGB(120, 150, 130)
logLabel.Font = Enum.Font.Code
logLabel.TextSize = 9
logLabel.TextXAlignment = Enum.TextXAlignment.Left
logLabel.TextYAlignment = Enum.TextYAlignment.Top
logLabel.Parent = logBox
Logger.frame = logLabel

local function section(text)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, 0, 0, 14)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = Color3.fromRGB(90, 100, 130)
    l.Font = Enum.Font.GothamBold
    l.TextSize = 9
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = scroll
    return l
end

local toggles = {}

local function toggleRow(key, label, initial, onChange)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 24)
    f.BackgroundColor3 = Color3.fromRGB(20, 21, 27)
    f.BorderSizePixel = 0
    f.Parent = scroll
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 5)

    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -56, 1, 0)
    l.Position = UDim2.new(0, 8, 0, 0)
    l.BackgroundTransparency = 1
    l.Text = label
    l.TextColor3 = Color3.fromRGB(200, 205, 220)
    l.Font = Enum.Font.GothamMedium
    l.TextSize = 10
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = f

    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 40, 0, 16)
    b.Position = UDim2.new(1, -48, 0, 4)
    b.BackgroundColor3 = Color3.fromRGB(38, 40, 52)
    b.BorderSizePixel = 0
    b.Text = initial and "ON" or "OFF"
    b.TextColor3 = initial and Color3.fromRGB(120, 220, 150) or Color3.fromRGB(130, 135, 150)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 9
    b.Parent = f
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)

    local state = initial
    toggles[key] = function(v)
        state = v
        b.Text = v and "ON" or "OFF"
        b.BackgroundColor3 = v and Color3.fromRGB(28, 80, 52) or Color3.fromRGB(38, 40, 52)
        b.TextColor3 = v and Color3.fromRGB(120, 220, 150) or Color3.fromRGB(130, 135, 150)
    end

    b.MouseButton1Click:Connect(function()
        local v = not state
        toggles[key](v)
        onChange(v)
    end)
    return f
end

local function stepper(label, get, set, step, min, max)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 22)
    f.BackgroundColor3 = Color3.fromRGB(17, 18, 23)
    f.BorderSizePixel = 0
    f.Parent = scroll
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 5)

    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -92, 1, 0)
    l.Position = UDim2.new(0, 8, 0, 0)
    l.BackgroundTransparency = 1
    l.Text = label
    l.TextColor3 = Color3.fromRGB(150, 158, 180)
    l.Font = Enum.Font.Gotham
    l.TextSize = 9
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = f

    local val = Instance.new("TextLabel")
    val.Size = UDim2.new(0, 34, 1, 0)
    val.Position = UDim2.new(1, -76, 0, 0)
    val.BackgroundTransparency = 1
    val.Text = tostring(get())
    val.TextColor3 = Color3.fromRGB(120, 170, 230)
    val.Font = Enum.Font.GothamBold
    val.TextSize = 9
    val.Parent = f

    local function mk(txt, x, delta)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, 16, 0, 14)
        b.Position = UDim2.new(1, x, 0, 4)
        b.BackgroundColor3 = Color3.fromRGB(32, 34, 44)
        b.BorderSizePixel = 0
        b.Text = txt
        b.TextColor3 = Color3.fromRGB(200, 205, 220)
        b.Font = Enum.Font.GothamBold
        b.TextSize = 9
        b.Parent = f
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 3)
        b.MouseButton1Click:Connect(function()
            local v = math.clamp(get() + delta, min, max)
            set(v)
            val.Text = string.format("%.2f", v)
        end)
    end
    mk("-", -40, -step)
    mk("+", -20, step)
    return f
end

-- ---- Seccion: robo ----
section("ROBO")
toggleRow("grab", "Auto Grab (bases ajenas)", false, function(v)
    CFG.grabEnabled = v
    if v then
        BaseScan.run()
        AutoGrab.active = true
        AutoGrab.start()
        Logger.push("[UI]", "AutoGrab ON")
    else
        AutoGrab.stop()
        Logger.push("[UI]", "AutoGrab OFF")
    end
end)
stepper("Delay de robo (s)", function() return CFG.grabDelay end,
    function(v) CFG.grabDelay = v end, 0.05, 0.05, 1.0)

-- ---- Seccion: combate ----
section("COMBATE")
toggleRow("bat", "Bat Aimbot", false, function(v)
    CFG.batEnabled = v
    Bat.active = v
    if v then Bat.start() else Bat.stop() end
    Logger.push("[UI]", "Bat " .. (v and "ON" or "OFF"))
end)
stepper("Rango de bate (studs)", function() return CFG.batRange end,
    function(v) CFG.batRange = v end, 1, 6, 40)

toggleRow("medusa", "Auto Medusa (delay 0)", false, function(v)
    CFG.medusaEnabled = v
    if v then Medusa.start() else Medusa.stop() end
    Logger.push("[UI]", "Medusa " .. (v and "ON" or "OFF"))
end)

-- ---- Seccion: defensa ----
section("DEFENSA")
toggleRow("akb", "Anti-Knockback + movimiento", false, function(v)
    CFG.akbEnabled = v
    if v then AKB.start() else AKB.stop() end
    Logger.push("[UI]", "AntiKB " .. (v and "ON" or "OFF"))
end)
toggleRow("fake", "Posicion falsa (anti-aimbot)", false, function(v)
    CFG.fakeEnabled = v
    if v then FakePos.start() else FakePos.stop() end
    Logger.push("[UI]", "FakePos " .. (v and "ON" or "OFF"))
end)
toggleRow("lag", "Lag / desincronizacion", false, function(v)
    CFG.lagEnabled = v
    if v then Lag.start() else Lag.stop() end
    Logger.push("[UI]", "Lag " .. (v and "ON" or "OFF"))
end)

-- ---- Seccion: utilidades ----
section("UTILIDADES")
toggleRow("drop", "Auto Drop (0 knockback)", false, function(v)
    CFG.dropEnabled = v
    if v then AutoDrop.start() else AutoDrop.stop() end
    Logger.push("[UI]", "AutoDrop " .. (v and "ON" or "OFF"))
end)

local rescanBtn = Instance.new("TextButton")
rescanBtn.Size = UDim2.new(1, 0, 0, 22)
rescanBtn.BackgroundColor3 = Color3.fromRGB(30, 40, 58)
rescanBtn.BorderSizePixel = 0
rescanBtn.Text = "Escanear bases"
rescanBtn.TextColor3 = Color3.fromRGB(180, 200, 235)
rescanBtn.Font = Enum.Font.GothamBold
rescanBtn.TextSize = 9
rescanBtn.Parent = scroll
Instance.new("UICorner", rescanBtn).CornerRadius = UDim.new(0, 5)

local listLabel = Instance.new("TextLabel")
listLabel.Size = UDim2.new(1, 0, 0, 14)
listLabel.BackgroundTransparency = 1
listLabel.Text = "sin datos"
listLabel.TextColor3 = Color3.fromRGB(110, 120, 145)
listLabel.Font = Enum.Font.Gotham
listLabel.TextSize = 9
listLabel.TextXAlignment = Enum.TextXAlignment.Left
listLabel.Parent = scroll

local function refreshList()
    local seen = {}
    local out = {}
    for _, e in ipairs(BaseScan.entries) do
        local k = e.owner .. "|" .. e.key
        if not seen[k] then
            seen[k] = true
            out[#out + 1] = e
        end
    end
    local txt = {}
    for i = 1, math.min(#out, 6) do
        local e = out[i]
        local mark = CFG.targets[e.key] and "[x]" or "[ ]"
        txt[#txt + 1] = string.format("%s %s -> %s", mark, e.name, e.owner)
    end
    if #out == 0 then txt[1] = "sin brainrots detectados" end
    listLabel.Text = string.format("detectados: %d\n%s", #out, table.concat(txt, "\n"))
end

rescanBtn.MouseButton1Click:Connect(function()
    local ok, n = pcall(function()
        local e = BaseScan.run()
        return #e
    end)
    if ok then
        Logger.push("[SCAN]", n .. " brainrots en bases")
        refreshList()
    else
        Logger.push("[ERR]", "Scan fallo")
    end
end)

-- ---- Iconos ----
mkIcon("-", -54, Color3.fromRGB(190, 200, 225), function()
    main.Visible = false
    local reopen = Instance.new("TextButton")
    reopen.Size = UDim2.new(0, 90, 0, 22)
    reopen.Position = UDim2.new(0, 24, 0, 90)
    reopen.BackgroundColor3 = Color3.fromRGB(22, 24, 32)
    reopen.Text = "SAB PVP"
    reopen.TextColor3 = Color3.fromRGB(190, 205, 235)
    reopen.Font = Enum.Font.GothamBold
    reopen.TextSize = 10
    reopen.Parent = gui
    Instance.new("UICorner", reopen).CornerRadius = UDim.new(0, 5)
    reopen.MouseButton1Click:Connect(function()
        main.Visible = true
        reopen:Destroy()
    end)
end)

mkIcon("X", -26, Color3.fromRGB(240, 100, 100), function()
    AutoGrab.stop(); Bat.stop(); Medusa.stop()
    FakePos.stop(); AKB.stop(); AutoDrop.stop(); Lag.stop()
    gui:Destroy()
end)

-- ======================================================================
-- LOOPS DE SOPORTE
-- ======================================================================

task.spawn(function()
    while gui.Parent do
        task.wait(1.5)
        if CFG.grabEnabled then
            pcall(BaseScan.run)
            pcall(refreshList)
        end
    end
end)

lp.CharacterAdded:Connect(function()
    task.wait(1)
    if CFG.grabEnabled then AutoGrab.active = true; AutoGrab.start() end
    if CFG.batEnabled then Bat.active = true; Bat.start() end
    if CFG.fakeEnabled then FakePos.stop(); FakePos.start() end
    if CFG.akbEnabled then AKB.stop(); AKB.start() end
end)

Logger.push("[SYS]", "Toolkit cargado")
pcall(BaseScan.run)
refreshList()

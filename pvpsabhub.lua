--[[
=========================================================================
  VENICE | Steal a Brainrot - PvP Toolkit  (build 2, log-wired)
  Place 99606176102979 / Version 270
=========================================================================
  Remotes confirmados por log:
    CombatService/ApplyImpulse   (S->C) impacto recibido
    Tools/Cooldown               reset de cooldown
    WorldBrainrotService/Drop    soltar brainrot
    Snapshot/UnrealiableChannel  snapshots de posicion
    Tools/Equip, UseItem         uso de herramienta
    BaseIndexService/Claim       reclamo de base
=========================================================================
]]

if _G.__VENICE_SAB_PVP then pcall(function() _G.__VENICE_SAB_PVP:Destroy() end) end

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local lp = Players.LocalPlayer

-- ======================================================================
-- REMOTES
-- ======================================================================

local R = {
    useItem   = "UseItem",
    equip     = "Tools/Equip",
    cooldown  = "Tools/Cooldown",
    impulse   = "CombatService/ApplyImpulse",
    drop      = "WorldBrainrotService/Drop",
    snapshot  = "Snapshot/RealiableChannel",
    snapU     = "Snapshot/UnrealiableChannel",
}

local TOOL_BAT    = "Bat"
local TOOL_MEDUSA = "Medusa's Head"

local CFG = {
    grabEnabled = false, grabDelay = 0.15, grabTeleport = true, grabReturn = true,
    grabRadius = 260, grabOnlyTargets = false, grabBlacklist = {},

    batEnabled = false, batRange = 14, batRepath = 0.10,

    medusaEnabled = false, medusaWindow = 1.0,

    fakeEnabled = false, fakeRadius = 6, fakeHz = 0.02, snapMode = 1,

    akbEnabled = false, akbWindow = 0.40, akbAlways = false,

    dropEnabled = false,

    lagEnabled = false, lagRadius = 22, lagHz = 0.06,

    targets = {},
}

local STEAL_WORDS  = { "steal", "grab", "take", "robar", "agarrar", "tomar" }
local FREEZE_WORDS = { "freeze", "frozen", "ice", "hielo", "stone", "piedra", "medusa", "stun" }
local NAME_ATTRS   = { "BrainrotName", "DisplayName", "ItemName", "UnitName", "PetName" }
local OWNER_ATTRS  = { "Owner", "OwnerId", "UserId", "PlayerName", "BaseOwner", "OwnerName" }
local BASE_HINTS   = { "base", "bases", "playerbase", "playerbases", "plot", "plots", "slot" }

-- ======================================================================
-- NET
-- ======================================================================

local resolved = { RE = nil, URE = nil, RF = nil }

local function netInit()
    local pkg = ReplicatedStorage:FindFirstChild("Packages")
    local n = pkg and pkg:FindFirstChild("Net")
    if not n then return end
    resolved.RE  = n:FindFirstChild("RE")
    resolved.URE = n:FindFirstChild("URE")
    resolved.RF  = n:FindFirstChild("RF")
end
netInit()

local function ev(name)
    if not resolved.RE then netInit() end
    if not resolved.RE then return nil end
    return resolved.RE:FindFirstChild(name, true)
end

local function ure(name)
    if not resolved.URE then netInit() end
    if not resolved.URE then return nil end
    return resolved.URE:FindFirstChild(name, true)
end

local function fire(name, ...)
    local r = ev(name)
    if not r then return false end
    local a = { ... }
    return pcall(function() r:FireServer(unpack(a)) end)
end

local function fireU(name, ...)
    local r = ure(name)
    if not r then return false end
    local a = { ... }
    return pcall(function() r:FireServer(unpack(a)) end)
end

-- ======================================================================
-- UTIL
-- ======================================================================

local function norm(s)
    return tostring(s or ""):match("^%s*(.-)%s*$"):lower():gsub("%s+", " ")
end
local function hasWord(s, list)
    s = tostring(s or ""):lower()
    for _, w in ipairs(list) do if s:find(w, 1, true) then return true end end
    return false
end
local function hrp() local c = lp.Character; return c and c:FindFirstChild("HumanoidRootPart") end
local function hum() local c = lp.Character; return c and c:FindFirstChildOfClass("Humanoid") end
local function alive() local h = hum(); return h and h.Health > 0 and hrp() ~= nil end
local function dist(a, b) return (a - b).Magnitude end

local function cleanName(v)
    if type(v) ~= "string" then return nil end
    v = v:match("^%s*(.-)%s*$")
    if #v < 2 or #v > 64 then return nil end
    if v:match("^%$?[%d%.,]+$") then return nil end
    local l = v:lower()
    if l == "part" or l == "model" or l == "base" or l == "prompt" or l == "pedestal" then return nil end
    return v
end

local function brainrotName(inst)
    local n = inst
    for _ = 1, 8 do
        if not n then break end
        for _, a in ipairs(NAME_ATTRS) do
            local v = cleanName(n:GetAttribute(a)); if v then return v end
        end
        if n:IsA("Model") then
            local v = cleanName(n.Name); if v then return v end
        end
        n = n.Parent
    end
    return nil
end

local function ownerOfBase(c)
    local n = c
    for _ = 1, 4 do
        if not n or n == workspace then break end
        for _, a in ipairs(OWNER_ATTRS) do
            local v = n:GetAttribute(a)
            if typeof(v) == "number" then
                local p = Players:GetPlayerByUserId(v); if p then return p end
            elseif type(v) == "string" then
                local p = Players:FindFirstChild(v); if p then return p end
            end
        end
        for _, p in ipairs(Players:GetPlayers()) do
            if n.Name == p.Name or n.Name == p.DisplayName then return p end
        end
        n = n.Parent
    end
    return nil
end

local function findTool(exact, words)
    local function scan(container)
        for _, t in ipairs(container:GetChildren()) do
            if t:IsA("Tool") then
                if exact and t.Name == exact then return t, true end
            end
        end
        if words then
            for _, t in ipairs(container:GetChildren()) do
                if t:IsA("Tool") and hasWord(t.Name, words) then return t, true end
            end
        end
        return nil
    end
    local c = lp.Character
    if c then
        local t, e = scan(c); if t then return t, e end
    end
    local bp = lp:FindFirstChildOfClass("Backpack")
    if bp then
        local t = scan(bp); if t then return t, false end
    end
    return nil, false
end

local function useTool(tool, equipped)
    local h = hum()
    if not h or not tool then return end
    if not equipped then pcall(function() h:EquipTool(tool) end) end
    fire(R.equip, tool)
    pcall(function() tool:Activate() end)
    fire(R.useItem, tool)
end

local function resetCooldown(tool)
    fire(R.cooldown, tool, 0)
    pcall(function()
        tool:SetAttribute("Cooldown", 0)
        tool:SetAttribute("LastUse", 0)
        tool:SetAttribute("NextUse", 0)
    end)
end

local function firePrompt(p)
    if typeof(fireproximityprompt) == "function" then
        if pcall(fireproximityprompt, p) then return true end
    end
    return pcall(function() p:InputHoldBegin(); task.wait(0.02); p:InputHoldEnd() end)
end

-- ======================================================================
-- LOGGER
-- ======================================================================

local Logger = { lines = {}, frame = nil }
function Logger.push(k, m)
    table.insert(Logger.lines, 1, string.format("[%s] %s %s", os.date("%H:%M:%S"), k, m))
    if #Logger.lines > 60 then table.remove(Logger.lines) end
    if Logger.frame then
        Logger.frame.Text = table.concat(Logger.lines, "\n", 1, math.min(#Logger.lines, 12))
    end
end

-- ======================================================================
-- IMPACTOS (CombatService/ApplyImpulse)
-- ======================================================================

local Combat = { lastHit = 0, count = 0, conn = nil }

function Combat.start()
    local r = ev(R.impulse)
    if not r then Logger.push("[ERR]", "ApplyImpulse no resuelto"); return end
    Combat.conn = r.OnClientEvent:Connect(function(...)
        Combat.lastHit = os.clock()
        Combat.count = Combat.count + 1
        local args = { ... }
        Logger.push("[HIT]", "Impulso recibido (" .. #args .. " args)")
    end)
end

function Combat.stop()
    if Combat.conn then Combat.conn:Disconnect() end
    Combat.conn = nil
end

-- ======================================================================
-- BASES
-- ======================================================================

local BaseScan = { entries = {} }

local function isStealPrompt(p) return hasWord(p.ActionText, STEAL_WORDS) or hasWord(p.ObjectText, STEAL_WORDS) end

local function containers()
    local out, seen = {}, {}
    local function consider(i)
        if not i or seen[i] then return end
        if not (i:IsA("Model") or i:IsA("Folder")) then return end
        seen[i] = true
        if ownerOfBase(i) then out[#out + 1] = i end
    end
    for _, c in ipairs(workspace:GetChildren()) do
        if (c:IsA("Folder") or c:IsA("Model")) and hasWord(c.Name, BASE_HINTS) then
            for _, s in ipairs(c:GetChildren()) do consider(s) end
        end
    end
    if #out == 0 then
        for _, c in ipairs(workspace:GetChildren()) do consider(c) end
    end
    return out
end

function BaseScan.run()
    local list = {}
    for _, base in ipairs(containers()) do
        local owner = ownerOfBase(base)
        if owner and owner ~= lp then
            for _, d in ipairs(base:GetDescendants()) do
                if d:IsA("ProximityPrompt") and isStealPrompt(d) then
                    local name = brainrotName(d)
                    if name and not CFG.grabBlacklist[norm(name)] then
                        local n, pos = d.Parent
                        for _ = 1, 6 do
                            if not n then break end
                            if n:IsA("BasePart") then pos = n.Position break end
                            if n:IsA("Model") then pos = n:GetPivot().Position break end
                            n = n.Parent
                        end
                        if pos then
                            list[#list + 1] = {
                                prompt = d, name = name, key = norm(name),
                                owner = owner.Name, position = pos,
                            }
                        end
                    end
                end
            end
        end
    end
    BaseScan.entries = list
    return list
end

-- ======================================================================
-- AUTO GRAB
-- ======================================================================

local Grab = { active = false, thread = nil, cd = setmetatable({}, { __mode = "k" }) }
local stats = { ok = 0, try = 0 }

function Grab.tick()
    if not alive() then return end
    local root, now = hrp(), os.clock()
    local best, bestD
    for _, e in ipairs(BaseScan.entries) do
        local p = e.prompt
        if p and p.Parent and p.Enabled then
            if not CFG.grabOnlyTargets or CFG.targets[e.key] then
                local d = dist(root.Position, e.position)
                if d <= CFG.grabRadius then
                    local c = Grab.cd[p]
                    if (not c or now - c >= CFG.grabDelay) and (not bestD or d < bestD) then
                        best, bestD = e, d
                    end
                end
            end
        end
    end
    if not best then return end

    Grab.cd[best.prompt] = now
    stats.try = stats.try + 1

    local saved, moved = root.CFrame, false
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
    if moved and CFG.grabReturn and root.Parent then root.CFrame = saved end

    if p.Parent and not p.Enabled then
        stats.ok = stats.ok + 1
        Logger.push("[GRAB]", best.name .. " <- " .. best.owner)
    end
end

function Grab.start()
    if Grab.thread then return end
    Grab.active = true
    Grab.thread = task.spawn(function()
        while Grab.active do
            pcall(Grab.tick)
            task.wait(CFG.grabDelay)
        end
        Grab.thread = nil
    end)
end
function Grab.stop() Grab.active = false; Grab.thread = nil end

-- ======================================================================
-- BAT AIMBOT
-- ======================================================================

local Bat = { active = false, thread = nil }

local function nearestEnemy(max)
    local root = hrp(); if not root then return nil end
    local best, bd
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= lp and p.Character then
            local t = p.Character:FindFirstChild("HumanoidRootPart")
            local h = p.Character:FindFirstChildOfClass("Humanoid")
            if t and h and h.Health > 0 then
                local d = dist(root.Position, t.Position)
                if d <= max and (not bd or d < bd) then best, bd = p, d end
            end
        end
    end
    return best
end

function Bat.tick()
    if not alive() then return end
    local h, root = hum(), hrp()
    local e = nearestEnemy(300)
    if not e then return end
    local t = e.Character:FindFirstChild("HumanoidRootPart")
    if not t then return end

    root.CFrame = CFrame.new(root.Position, Vector3.new(t.Position.X, root.Position.Y, t.Position.Z))

    if dist(root.Position, t.Position) > CFG.batRange then
        pcall(function() h:MoveTo(t.Position) end)
        return
    end

    local tool, eq = findTool(TOOL_BAT, { "bat", "bate" })
    if tool then useTool(tool, eq) end
end

function Bat.start()
    if Bat.thread then return end
    Bat.active = true
    Bat.thread = task.spawn(function()
        while Bat.active do
            pcall(Bat.tick)
            task.wait(CFG.batRepath)
        end
        Bat.thread = nil
    end)
end
function Bat.stop() Bat.active = false; Bat.thread = nil end

-- ======================================================================
-- AUTO MEDUSA
-- ======================================================================

local Medusa = { active = false, enemyUsed = 0, lastFire = 0, conns = {} }

local function enemyWatch(p)
    if p == lp then return end
    local function hook(ch)
        ch.ChildAdded:Connect(function(c)
            if (c:IsA("Tool") and hasWord(c.Name, { "medusa" })) or hasWord(c.Name, FREEZE_WORDS) then
                Medusa.enemyUsed = os.clock()
                Logger.push("[MED]", p.Name .. " -> Medusa")
            end
        end)
    end
    if p.Character then hook(p.Character) end
    table.insert(Medusa.conns, p.CharacterAdded:Connect(hook))
end

function Medusa.fireBack()
    if not alive() then return end
    local now = os.clock()
    if now - Medusa.lastFire < 0.05 then return end
    Medusa.lastFire = now

    local tool, eq = findTool(TOOL_MEDUSA, { "medusa" })
    if not tool then return end
    resetCooldown(tool)
    useTool(tool, eq)
    Logger.push("[MED]", "contra-Medusa (delay 0)")
end

function Medusa.start()
    if Medusa.active then return end
    Medusa.active = true
    for _, p in ipairs(Players:GetPlayers()) do enemyWatch(p) end
    table.insert(Medusa.conns, Players.PlayerAdded:Connect(enemyWatch))

    local last = 0
    table.insert(Medusa.conns, RunService.Heartbeat:Connect(function()
        if not Medusa.active then return end
        local h = hum(); if not h then return end
        local frozen = h.WalkSpeed < 0.5 and last > 1
        local hit = (os.clock() - Combat.lastHit) <= CFG.medusaWindow
        if frozen and ((os.clock() - Medusa.enemyUsed) <= CFG.medusaWindow or hit) then
            Medusa.fireBack()
        end
        last = h.WalkSpeed
    end))
end

function Medusa.stop()
    Medusa.active = false
    for _, c in ipairs(Medusa.conns) do pcall(function() c:Disconnect() end) end
    Medusa.conns = {}
end

-- ======================================================================
-- POSICION FALSA (snapshots)
-- ======================================================================

local Fake = { active = false, conn = nil, oxz = nil, rot = nil }

local function randCircle(r)
    local a = math.random() * math.pi * 2
    local d = math.random() * r
    return Vector3.new(math.cos(a) * d, 0, math.sin(a) * d)
end

function Fake.send(pos)
    local mode = CFG.snapMode
    if mode == 1 then
        fireU(R.snapU, pos)
    elseif mode == 2 then
        fireU(R.snapU, { position = pos, Position = pos, t = os.clock() })
    elseif mode == 3 then
        fireU(R.snapU, CFrame.new(pos))
    else
        fireU(R.snapU, pos, os.clock())
    end
    fire(R.snapshot, pos)
end

function Fake.start()
    if Fake.active then return end
    local root = hrp(); if not root then return end
    Fake.active = true
    Fake.oxz = root.Position * Vector3.new(1, 0, 1)
    Fake.rot = root.CFrame - root.CFrame.Position
    local acc = 0

    Fake.conn = RunService.Heartbeat:Connect(function(dt)
        if not Fake.active or CFG.lagEnabled then return end
        local h, r = hum(), hrp()
        if not h or not r then return end

        local md = h.MoveDirection
        if md.Magnitude > 0.05 then
            Fake.oxz = Fake.oxz + Vector3.new(md.X, 0, md.Z) * (h.WalkSpeed * dt)
        end

        acc = acc + dt
        if acc < CFG.fakeHz then return end
        acc = 0

        local y = r.Position.Y
        local b = Fake.oxz + randCircle(CFG.fakeRadius)
        local p = Vector3.new(b.X, y, b.Z)
        r.CFrame = CFrame.new(p) * Fake.rot
        Fake.send(p)
    end)
end

function Fake.stop()
    Fake.active = false
    if Fake.conn then Fake.conn:Disconnect() end
    Fake.conn = nil
end

-- ======================================================================
-- ANTI-KNOCKBACK
-- ======================================================================

local AKB = { active = false, conn = nil }

function AKB.start()
    if AKB.active then return end
    AKB.active = true
    AKB.conn = RunService.Heartbeat:Connect(function()
        if not AKB.active then return end
        if not CFG.akbAlways and (os.clock() - Combat.lastHit) > CFG.akbWindow then return end
        local h, r = hum(), hrp()
        if not h or not r then return end
        local v, md = r.AssemblyLinearVelocity, h.MoveDirection
        local x, z = 0, 0
        if md.Magnitude > 0.05 then
            x, z = md.Unit.X * h.WalkSpeed, md.Unit.Z * h.WalkSpeed
        end
        r.AssemblyLinearVelocity = Vector3.new(x, v.Y, z)
        r.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        if h.PlatformStand then h.PlatformStand = false end
    end)
end
function AKB.stop() AKB.active = false; if AKB.conn then AKB.conn:Disconnect() end; AKB.conn = nil end

-- ======================================================================
-- AUTO DROP
-- ======================================================================

local Drop = { active = false, thread = nil }

local function carrying()
    local c = lp.Character; if not c then return nil end
    for _, t in ipairs(c:GetChildren()) do
        if t:IsA("Tool") and t.Name ~= TOOL_BAT and t.Name ~= TOOL_MEDUSA
            and not hasWord(t.Name, { "bat", "medusa" }) then
            return t
        end
    end
    return nil
end

function Drop.tick()
    if not alive() then return end
    local tool = carrying()
    if not tool then return end

    local r = hrp()
    fire(R.drop, tool)
    pcall(function() tool:Activate() end)

    local t0 = os.clock()
    while os.clock() - t0 < 0.25 do
        if r.Parent then r.AssemblyLinearVelocity = Vector3.new(0, r.AssemblyLinearVelocity.Y, 0) end
        task.wait(0.01)
    end
    Logger.push("[DROP]", "soltado: " .. tool.Name)
end

function Drop.start()
    if Drop.thread then return end
    Drop.active = true
    Drop.thread = task.spawn(function()
        while Drop.active do pcall(Drop.tick); task.wait(0.2) end
        Drop.thread = nil
    end)
end
function Drop.stop() Drop.active = false; Drop.thread = nil end

-- ======================================================================
-- LAG
-- ======================================================================

local Lag = { active = false, thread = nil }
function Lag.start()
    if Lag.thread then return end
    Lag.active = true
    Lag.thread = task.spawn(function()
        while Lag.active do
            local r = hrp()
            if r then
                local s = r.CFrame
                r.CFrame = CFrame.new(s.Position + randCircle(CFG.lagRadius) + Vector3.new(0, math.random(-6, 6), 0)) * (s - s.Position)
                task.wait(CFG.lagHz / 2)
                if r.Parent then r.CFrame = s end
                task.wait(CFG.lagHz / 2)
            else
                task.wait(0.1)
            end
        end
        Lag.thread = nil
    end)
end
function Lag.stop() Lag.active = false; Lag.thread = nil end

-- ======================================================================
-- UI
-- ======================================================================

local pg
if typeof(gethui) == "function" then local ok, r = pcall(gethui); if ok then pg = r end end
pg = pg or game:GetService("CoreGui")

local gui = Instance.new("ScreenGui")
gui.Name = "VeniceSAB"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = pg
_G.__VENICE_SAB_PVP = gui

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 300, 0, 480)
main.Position = UDim2.new(0, 24, 0, 90)
main.BackgroundColor3 = Color3.fromRGB(13, 13, 17)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.ClipsDescendants = true
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 8)
local stk = Instance.new("UIStroke", main)
stk.Color = Color3.fromRGB(40, 52, 78); stk.Thickness = 1

local bar = Instance.new("Frame")
bar.Size = UDim2.new(1, 0, 0, 26)
bar.BackgroundColor3 = Color3.fromRGB(21, 23, 31)
bar.BorderSizePixel = 0
bar.Parent = main
Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 8)

local ttl = Instance.new("TextLabel")
ttl.Size = UDim2.new(1, -60, 1, 0)
ttl.Position = UDim2.new(0, 10, 0, 0)
ttl.BackgroundTransparency = 1
ttl.Text = "SAB // PVP"
ttl.TextColor3 = Color3.fromRGB(190, 205, 235)
ttl.Font = Enum.Font.GothamBold
ttl.TextSize = 11
ttl.TextXAlignment = Enum.TextXAlignment.Left
ttl.Parent = bar

local function icon(t, x, col, cb)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 20, 0, 20); b.Position = UDim2.new(1, x, 0, 3)
    b.BackgroundColor3 = Color3.fromRGB(30, 33, 44); b.BorderSizePixel = 0
    b.Text = t; b.TextColor3 = col; b.Font = Enum.Font.GothamBold; b.TextSize = 11
    b.Parent = bar
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)
    b.MouseButton1Click:Connect(cb)
end

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -16, 1, -104)
scroll.Position = UDim2.new(0, 8, 0, 32)
scroll.BackgroundTransparency = 1; scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 3; scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.Parent = main

local lay = Instance.new("UIListLayout")
lay.Padding = UDim.new(0, 4); lay.Parent = scroll
lay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    scroll.CanvasSize = UDim2.new(0, 0, 0, lay.AbsoluteContentSize.Y + 6)
end)

local logF = Instance.new("Frame")
logF.Size = UDim2.new(1, -16, 0, 62); logF.Position = UDim2.new(0, 8, 1, -68)
logF.BackgroundColor3 = Color3.fromRGB(8, 8, 11); logF.BorderSizePixel = 0
logF.Parent = main
Instance.new("UICorner", logF).CornerRadius = UDim.new(0, 5)

local logL = Instance.new("TextLabel")
logL.Size = UDim2.new(1, -10, 1, -6); logL.Position = UDim2.new(0, 5, 0, 3)
logL.BackgroundTransparency = 1; logL.Text = ""
logL.TextColor3 = Color3.fromRGB(115, 150, 125); logL.Font = Enum.Font.Code
logL.TextSize = 9; logL.TextXAlignment = Enum.TextXAlignment.Left
logL.TextYAlignment = Enum.TextYAlignment.Top; logL.Parent = logF
Logger.frame = logL

local function sec(t)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, 0, 0, 13); l.BackgroundTransparency = 1
    l.Text = t; l.TextColor3 = Color3.fromRGB(88, 98, 128)
    l.Font = Enum.Font.GothamBold; l.TextSize = 9
    l.TextXAlignment = Enum.TextXAlignment.Left; l.Parent = scroll
end

local function row(label, init, cb)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 23); f.BackgroundColor3 = Color3.fromRGB(19, 20, 26)
    f.BorderSizePixel = 0; f.Parent = scroll
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 5)

    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -56, 1, 0); l.Position = UDim2.new(0, 8, 0, 0)
    l.BackgroundTransparency = 1; l.Text = label
    l.TextColor3 = Color3.fromRGB(200, 205, 220); l.Font = Enum.Font.GothamMedium
    l.TextSize = 10; l.TextXAlignment = Enum.TextXAlignment.Left; l.Parent = f

    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 40, 0, 15); b.Position = UDim2.new(1, -48, 0, 4)
    b.BackgroundColor3 = Color3.fromRGB(38, 40, 52); b.BorderSizePixel = 0
    b.Text = "OFF"; b.TextColor3 = Color3.fromRGB(130, 135, 150)
    b.Font = Enum.Font.GothamBold; b.TextSize = 9; b.Parent = f
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)

    local st = init
    local function paint()
        b.Text = st and "ON" or "OFF"
        b.BackgroundColor3 = st and Color3.fromRGB(28, 80, 52) or Color3.fromRGB(38, 40, 52)
        b.TextColor3 = st and Color3.fromRGB(120, 220, 150) or Color3.fromRGB(130, 135, 150)
    end
    paint()
    b.MouseButton1Click:Connect(function()
        st = not st; paint(); cb(st)
    end)
end

local function step(label, get, set, d, mn, mx)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 21); f.BackgroundColor3 = Color3.fromRGB(16, 17, 22)
    f.BorderSizePixel = 0; f.Parent = scroll
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 5)

    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -92, 1, 0); l.Position = UDim2.new(0, 8, 0, 0)
    l.BackgroundTransparency = 1; l.Text = label
    l.TextColor3 = Color3.fromRGB(150, 158, 180); l.Font = Enum.Font.Gotham
    l.TextSize = 9; l.TextXAlignment = Enum.TextXAlignment.Left; l.Parent = f

    local v = Instance.new("TextLabel")
    v.Size = UDim2.new(0, 34, 1, 0); v.Position = UDim2.new(1, -76, 0, 0)
    v.BackgroundTransparency = 1; v.Text = string.format("%.2f", get())
    v.TextColor3 = Color3.fromRGB(120, 170, 230); v.Font = Enum.Font.GothamBold
    v.TextSize = 9; v.Parent = f

    local function mk(t, x, dd)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, 16, 0, 13); b.Position = UDim2.new(1, x, 0, 4)
        b.BackgroundColor3 = Color3.fromRGB(32, 34, 44); b.BorderSizePixel = 0
        b.Text = t; b.TextColor3 = Color3.fromRGB(200, 205, 220)
        b.Font = Enum.Font.GothamBold; b.TextSize = 9; b.Parent = f
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 3)
        b.MouseButton1Click:Connect(function()
            set(math.clamp(get() + dd, mn, mx))
            v.Text = string.format("%.2f", get())
        end)
    end
    mk("-", -40, -d); mk("+", -20, d)
end

sec("ROBO")
row("Auto Grab (bases)", false, function(v)
    CFG.grabEnabled = v
    if v then BaseScan.run(); Grab.start() else Grab.stop() end
end)
step("Delay robo (s)", function() return CFG.grabDelay end, function(v) CFG.grabDelay = v end, 0.05, 0.05, 1.0)

sec("COMBATE")
row("Bat Aimbot", false, function(v) CFG.batEnabled = v; if v then Bat.start() else Bat.stop() end end)
step("Rango bate", function() return CFG.batRange end, function(v) CFG.batRange = v end, 1, 6, 40)
row("Auto Medusa (delay 0)", false, function(v) CFG.medusaEnabled = v; if v then Medusa.start() else Medusa.stop() end end)

sec("DEFENSA")
row("Anti-Knockback", false, function(v) CFG.akbEnabled = v; if v then AKB.start() else AKB.stop() end end)
row("Posicion falsa", false, function(v) CFG.fakeEnabled = v; if v then Fake.start() else Fake.stop() end end)
row("Lag / desync", false, function(v) CFG.lagEnabled = v; if v then Lag.start() else Lag.stop() end end)

sec("UTILIDADES")
row("Auto Drop", false, function(v) CFG.dropEnabled = v; if v then Drop.start() else Drop.stop() end end)

local payloadBtn = Instance.new("TextButton")
payloadBtn.Size = UDim2.new(1, 0, 0, 21)
payloadBtn.BackgroundColor3 = Color3.fromRGB(28, 36, 52)
payloadBtn.BorderSizePixel = 0
payloadBtn.Text = "Payload snapshot: Vector3"
payloadBtn.TextColor3 = Color3.fromRGB(175, 195, 230)
payloadBtn.Font = Enum.Font.GothamBold; payloadBtn.TextSize = 9
payloadBtn.Parent = scroll
Instance.new("UICorner", payloadBtn).CornerRadius = UDim.new(0, 5)

local MODES = { "Vector3", "Tabla", "CFrame", "Vector3+clock" }
payloadBtn.MouseButton1Click:Connect(function()
    CFG.snapMode = (CFG.snapMode % #MODES) + 1
    payloadBtn.Text = "Payload snapshot: " .. MODES[CFG.snapMode]
end)

local scanBtn = Instance.new("TextButton")
scanBtn.Size = UDim2.new(1, 0, 0, 21)
scanBtn.BackgroundColor3 = Color3.fromRGB(30, 40, 58)
scanBtn.BorderSizePixel = 0
scanBtn.Text = "Escanear bases"
scanBtn.TextColor3 = Color3.fromRGB(180, 200, 235)
scanBtn.Font = Enum.Font.GothamBold; scanBtn.TextSize = 9
scanBtn.Parent = scroll
Instance.new("UICorner", scanBtn).CornerRadius = UDim.new(0, 5)

local info = Instance.new("TextLabel")
info.Size = UDim2.new(1, 0, 0, 40); info.BackgroundTransparency = 1
info.Text = "-"; info.TextColor3 = Color3.fromRGB(110, 120, 145)
info.Font = Enum.Font.Gotham; info.TextSize = 9
info.TextXAlignment = Enum.TextXAlignment.Left; info.TextWrapped = true
info.Parent = scroll

scanBtn.MouseButton1Click:Connect(function()
    local ok, n = pcall(function() return #BaseScan.run() end)
    info.Text = ok and (n .. " brainrots en bases") or "scan fallo"
    if ok then Logger.push("[SCAN]", n .. " encontrados") end
end)

icon("-", -50, Color3.fromRGB(190, 200, 225), function()
    main.Visible = false
    local r = Instance.new("TextButton")
    r.Size = UDim2.new(0, 80, 0, 20); r.Position = UDim2.new(0, 24, 0, 90)
    r.BackgroundColor3 = Color3.fromRGB(21, 23, 31); r.Text = "SAB"
    r.TextColor3 = Color3.fromRGB(190, 205, 235); r.Font = Enum.Font.GothamBold
    r.TextSize = 10; r.Parent = gui
    Instance.new("UICorner", r).CornerRadius = UDim.new(0, 5)
    r.MouseButton1Click:Connect(function() main.Visible = true; r:Destroy() end)
end)

icon("X", -24, Color3.fromRGB(240, 100, 100), function()
    Grab.stop(); Bat.stop(); Medusa.stop(); Fake.stop(); AKB.stop(); Drop.stop(); Lag.stop(); Combat.stop()
    gui:Destroy()
end)

-- ======================================================================
-- INIT
-- ======================================================================

Combat.start()
task.spawn(function()
    while gui.Parent do
        task.wait(2)
        if CFG.grabEnabled then pcall(BaseScan.run) end
    end
end)

lp.CharacterAdded:Connect(function()
    task.wait(1)
    if CFG.fakeEnabled then Fake.stop(); Fake.start() end
    if CFG.akbEnabled then AKB.stop(); AKB.start() end
end)

Logger.push("[SYS]", "remotes: RE=" .. tostring(resolved.RE ~= nil) .. " URE=" .. tostring(resolved.URE ~= nil))
Logger.push("[SYS]", "listo")

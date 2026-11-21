--[[
============================================================
 FREEZE + GOD + FAST PROMPTS + AUTO ROBO  |  Roba un Huevo
 Madium / executor con Lua puro
------------------------------------------------------------
 FAST PROMPTS = HoldDuration 0 + disparo instantaneo
 AUTO ROBO    = busca el prompt mas cercano y lo spamea
 AUTO-IR      = se acerca al huevo y el freeze te sostiene ahi
============================================================
]]

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local player     = Players.LocalPlayer

local frozen   = false
local god      = true
local spot     = nil
local fastOn   = false
local autoOn   = false
local autoGo   = true
local onlySteal = true
local running  = true

local RADIUS = 14
local GO_RADIUS = 420
local cooldowns = setmetatable({}, { __mode = "k" })
local originals = setmetatable({}, { __mode = "k" })
local cache = {}

local STEAL_WORDS = { "steal", "robar", "roba", "rob", "carry", "llevar",
                      "recoger", "recoge", "pick", "take", "agarra", "grab", "e" }
local SKIP_WORDS  = { "buy", "comprar", "compra", "purchase", "sell", "vender",
                      "upgrade", "mejorar", "rebirth", "reset", "hatch", "abrir",
                      "eclos", "equip", "equipar", "fuse", "fusionar", "claim", "reclamar" }

local function char()
    local c = player.Character
    if not c or not c:FindFirstChildOfClass("Humanoid") then return nil, nil, nil end
    return c, c:FindFirstChildOfClass("Humanoid"), c:FindFirstChild("HumanoidRootPart")
end

local function hasWord(text, list)
    for _, w in ipairs(list) do
        if text:find(w, 1, true) then return true end
    end
    return false
end

local function passes(prompt)
    local ok, res = pcall(function()
        local txt = (tostring(prompt.ActionText or "") .. " " .. tostring(prompt.ObjectText or "")):lower()
        if hasWord(txt, SKIP_WORDS) then return false end
        if hasWord(txt, STEAL_WORDS) then return true end
        return not onlySteal
    end)
    return ok and res
end

local function promptPos(prompt)
    local node = prompt.Parent
    for _ = 1, 8 do
        if not node then break end
        if node:IsA("Attachment") then return node.WorldPosition end
        if node:IsA("BasePart") then return node.Position end
        if node:IsA("Model") then return node:GetPivot().Position end
        node = node.Parent
    end
    return nil
end

local function fire(prompt)
    if type(fireproximityprompt) == "function" then
        if pcall(fireproximityprompt, prompt) then return true end
    end
    return pcall(function()
        prompt:InputHoldBegin()
        task.wait(0.02)
        prompt:InputHoldEnd()
    end)
end

-- ===== FREEZE / GOD =====
RunService.Heartbeat:Connect(function()
    local _, h, hrp = char()
    if not hrp then return end
    if frozen then
        pcall(function()
            hrp.Anchored = true
            if spot then hrp.CFrame = spot end
        end)
    else
        pcall(function() hrp.Anchored = false end)
    end
    if god and h then
        pcall(function()
            if h.MaxHealth < 1e9 then h.MaxHealth = 1e9 end
            if h.Health < 1e9 then h.Health = 1e9 end
            h.BreakJointsOnDeath = false
        end)
    end
end)

player.CharacterAdded:Connect(function()
    task.wait(1)
    local _, _, hrp = char()
    if frozen and hrp and spot then pcall(function() hrp.CFrame = spot end) end
end)

-- ===== FAST PROMPTS =====
local function zeroPrompt(p)
    if originals[p] == nil then originals[p] = p.HoldDuration end
    if p.HoldDuration ~= 0 then pcall(function() p.HoldDuration = 0 end) end
end

local function scanFast()
    for _, p in ipairs(workspace:GetDescendants()) do
        if p:IsA("ProximityPrompt") then zeroPrompt(p) end
    end
end

workspace.DescendantAdded:Connect(function(inst)
    if fastOn and inst:IsA("ProximityPrompt") then zeroPrompt(inst) end
end)

local function restorePrompts()
    for p, h in pairs(originals) do
        if p.Parent and type(h) == "number" then pcall(function() p.HoldDuration = h end) end
    end
    table.clear(originals)
end

-- ===== CACHE + AUTO ROBO =====
task.spawn(function()
    while running do
        task.wait(0.5)
        local list = {}
        for _, p in ipairs(workspace:GetDescendants()) do
            if p:IsA("ProximityPrompt") and p.Enabled and passes(p) then
                local pos = promptPos(p)
                if pos then list[#list + 1] = { prompt = p, pos = pos } end
            end
        end
        cache = list
    end
end)

task.spawn(function()
    while running do
        task.wait(0.08)
        if fastOn then pcall(scanFast) end
        if autoOn then
            local _, _, hrp = char()
            if hrp then
                local best, bestD
                for _, e in ipairs(cache) do
                    local p = e.prompt
                    if p.Parent and p.Enabled then
                        local d = (e.pos - hrp.Position).Magnitude
                        if d <= GO_RADIUS and (not bestD or d < bestD) then
                            best, bestD = e, d
                        end
                    end
                end
                if best then
                    if bestD > 9 and autoGo then
                        spot = CFrame.new(best.pos + Vector3.new(0, 3, 0))
                        pcall(function() hrp.CFrame = spot end)
                    elseif bestD <= RADIUS then
                        local now = os.clock()
                        if not cooldowns[best.prompt] or now - cooldowns[best.prompt] > 0.15 then
                            cooldowns[best.prompt] = now
                            fire(best.prompt)
                        end
                    end
                end
            end
        end
    end
end)

-- ===== PANEL =====
local gui = Instance.new("ScreenGui")
gui.Name = "EggFreezeGui"
gui.ResetOnSpawn = false
if not pcall(function() gui.Parent = game:GetService("CoreGui") end) then
    gui.Parent = player:WaitForChild("PlayerGui")
end

local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 200, 0, 322)
panel.Position = UDim2.new(0, 14, 0.2, 0)
panel.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
panel.BorderSizePixel = 0
panel.Active = true
panel.Draggable = true
panel.Parent = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 10)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -30, 0, 26)
title.Position = UDim2.new(0, 10, 0, 4)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 12
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = Color3.fromRGB(120, 190, 255)
title.Text = "FREEZE: OFF"
title.Parent = panel

local close = Instance.new("TextButton")
close.Size = UDim2.new(0, 24, 0, 24)
close.Position = UDim2.new(1, -28, 0, 4)
close.BackgroundTransparency = 1
close.Font = Enum.Font.GothamBold
close.TextSize = 16
close.TextColor3 = Color3.fromRGB(230, 90, 90)
close.Text = "X"
close.Parent = panel

local function mkBtn(text, x, y, w, color)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, w, 0, 30)
    b.Position = UDim2.new(0, x, 0, y)
    b.BackgroundColor3 = color
    b.Font = Enum.Font.GothamBold
    b.TextSize = 11
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Text = text
    b.Parent = panel
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 7)
    return b
end

local frz    = mkBtn("FREEZE",     10, 36,  84, Color3.fromRGB(45, 90, 150))
local godB   = mkBtn("GOD: ON",   104, 36,  84, Color3.fromRGB(45, 120, 75))
local saveB  = mkBtn("GUARDAR",    10, 72,  84, Color3.fromRGB(70, 70, 80))
local goB    = mkBtn("IR",        104, 72,  84, Color3.fromRGB(70, 70, 80))
local fastB  = mkBtn("FAST PROMPTS: OFF", 10, 108, 178, Color3.fromRGB(60, 60, 70))
local autoB  = mkBtn("AUTO ROBO: OFF",    10, 144, 178, Color3.fromRGB(60, 60, 70))
local autoGoB = mkBtn("AUTO-IR: ON",  10, 180, 84, Color3.fromRGB(45, 120, 75))
local filtB  = mkBtn("FILTRO: ROBO", 104, 180, 84, Color3.fromRGB(45, 120, 75))

local hint = Instance.new("TextLabel")
hint.Size = UDim2.new(1, -20, 0, 62)
hint.Position = UDim2.new(0, 10, 0, 216)
hint.BackgroundTransparency = 1
hint.Font = Enum.Font.Gotham
hint.TextSize = 10
hint.TextWrapped = true
hint.TextXAlignment = Enum.TextXAlignment.Left
hint.TextColor3 = Color3.fromRGB(150, 150, 160)
hint.Text = "Si no agarra nada, pasá FILTRO a TODO. Congelado no caminás: AUTO-IR te lleva al huevo y el freeze te sostiene."
hint.Parent = panel

local st = Instance.new("TextLabel")
st.Size = UDim2.new(1, -20, 0, 16)
st.Position = UDim2.new(0, 10, 0, 288)
st.BackgroundTransparency = 1
st.Font = Enum.Font.Gotham
st.TextSize = 10
st.TextXAlignment = Enum.TextXAlignment.Left
st.TextColor3 = Color3.fromRGB(140, 200, 140)
st.Text = "listo"
st.Parent = panel

local function refresh()
    title.Text = frozen and "FREEZE: ON" or "FREEZE: OFF"
    title.TextColor3 = frozen and Color3.fromRGB(120, 220, 140) or Color3.fromRGB(120, 190, 255)
    frz.BackgroundColor3 = frozen and Color3.fromRGB(45, 140, 80) or Color3.fromRGB(45, 90, 150)
    godB.Text = god and "GOD: ON" or "GOD: OFF"
    godB.BackgroundColor3 = god and Color3.fromRGB(45, 120, 75) or Color3.fromRGB(70, 70, 80)
    fastB.Text = fastOn and "FAST PROMPTS: ON" or "FAST PROMPTS: OFF"
    fastB.BackgroundColor3 = fastOn and Color3.fromRGB(110, 50, 160) or Color3.fromRGB(60, 60, 70)
    autoB.Text = autoOn and "AUTO ROBO: ON" or "AUTO ROBO: OFF"
    autoB.BackgroundColor3 = autoOn and Color3.fromRGB(170, 70, 45) or Color3.fromRGB(60, 60, 70)
    autoGoB.Text = autoGo and "AUTO-IR: ON" or "AUTO-IR: OFF"
    autoGoB.BackgroundColor3 = autoGo and Color3.fromRGB(45, 120, 75) or Color3.fromRGB(70, 70, 80)
    filtB.Text = onlySteal and "FILTRO: ROBO" or "FILTRO: TODO"
    filtB.BackgroundColor3 = onlySteal and Color3.fromRGB(45, 120, 75) or Color3.fromRGB(140, 100, 45)
end

frz.MouseButton1Click:Connect(function()
    local _, _, hrp = char()
    if not frozen then
        if hrp then spot = hrp.CFrame end
        frozen = true
        st.Text = "congelado"
    else
        frozen = false
        st.Text = "libre"
    end
    refresh()
end)

godB.MouseButton1Click:Connect(function() god = not god; refresh() end)
saveB.MouseButton1Click:Connect(function()
    local _, _, hrp = char()
    if hrp then spot = hrp.CFrame; st.Text = "punto guardado" end
end)
goB.MouseButton1Click:Connect(function()
    local _, _, hrp = char()
    if hrp and spot then pcall(function() hrp.CFrame = spot end) end
end)

fastB.MouseButton1Click:Connect(function()
    fastOn = not fastOn
    if fastOn then scanFast(); st.Text = "fast prompts ON" else restorePrompts(); st.Text = "fast prompts OFF" end
    refresh()
end)

autoB.MouseButton1Click:Connect(function()
    autoOn = not autoOn
    st.Text = autoOn and "auto robo ON" or "auto robo OFF"
    refresh()
end)

autoGoB.MouseButton1Click:Connect(function() autoGo = not autoGo; refresh() end)
filtB.MouseButton1Click:Connect(function() onlySteal = not onlySteal; refresh() end)

close.MouseButton1Click:Connect(function()
    running = false
    autoOn = false
    frozen = false
    restorePrompts()
    local _, _, hrp = char()
    if hrp then pcall(function() hrp.Anchored = false end) end
    gui:Destroy()
end)

refresh()
print("[Combo] Cargado. FAST PROMPTS + AUTO ROBO listos.")

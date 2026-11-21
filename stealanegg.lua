--[[
============================================================
 FREEZE + FAST PROMPTS + AUTO ROBO  |  Roba un Huevo
 Madium / executor con Lua puro (Con Keybinds & Config Save)
============================================================
]]

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService      = game:GetService("HttpService")
local player           = Players.LocalPlayer

-- ===== CONFIGURACIÓN Y PERSISTENCIA =====
local CONFIG_FILE = "EggFreezeConfig.json"
local config = {
    fastOn      = false,
    autoOn      = false,
    onlySteal   = true,
    freezeKey   = "F",
    autoRoboKey = "R",
    toggleGuiKey = "RightShift"
}

local function saveConfig()
    if type(writefile) == "function" then
        pcall(function()
            writefile(CONFIG_FILE, HttpService:JSONEncode(config))
        end)
    end
end

local function loadConfig()
    if type(isfile) == "function" and type(readfile) == "function" and isfile(CONFIG_FILE) then
        pcall(function()
            local data = HttpService:JSONDecode(readfile(CONFIG_FILE))
            if type(data) == "table" then
                for k, v in pairs(data) do
                    if config[k] ~= nil then
                        config[k] = v
                    end
                end
            end
        end)
    end
end

loadConfig()

-- ===== VARIABLES DE ESTADO =====
local frozen    = false
local spot      = nil
local fastOn    = config.fastOn
local autoOn    = config.autoOn
local onlySteal = config.onlySteal
local running   = true

local RADIUS    = 14
local cooldowns = setmetatable({}, { __mode = "k" })
local originals = setmetatable({}, { __mode = "k" })
local cache     = {}

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

-- ===== FREEZE =====
RunService.Heartbeat:Connect(function()
    local _, _, hrp = char()
    if not hrp then return end
    if frozen then
        pcall(function()
            hrp.Anchored = true
            if spot then hrp.CFrame = spot end
        end)
    else
        pcall(function() hrp.Anchored = false end)
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

if fastOn then scanFast() end

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
                        if d <= RADIUS and (not bestD or d < bestD) then
                            best, bestD = e, d
                        end
                    end
                end
                if best then
                    local now = os.clock()
                    if not cooldowns[best.prompt] or now - cooldowns[best.prompt] > 0.15 then
                        cooldowns[best.prompt] = now
                        fire(best.prompt)
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
panel.Size = UDim2.new(0, 210, 0, 276)
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

-- Fila 1: FREEZE + Tecla
local frz    = mkBtn("FREEZE",        10, 36, 134, Color3.fromRGB(45, 90, 150))
local frzKey = mkBtn("[" .. config.freezeKey .. "]", 148, 36, 52, Color3.fromRGB(35, 35, 42))

-- Fila 2: AUTO ROBO + Tecla
local autoB   = mkBtn("AUTO ROBO: OFF", 10, 72, 134, Color3.fromRGB(60, 60, 70))
local autoKey = mkBtn("[" .. config.autoRoboKey .. "]", 148, 72, 52, Color3.fromRGB(35, 35, 42))

-- Fila 3: PANEL GUI (Ocultar/Mostrar) + Tecla
local guiBtn = mkBtn("PANEL GUI: ON",  10, 108, 134, Color3.fromRGB(55, 85, 115))
local guiKey = mkBtn("[" .. config.toggleGuiKey .. "]", 148, 108, 52, Color3.fromRGB(35, 35, 42))

-- Fila 4: GUARDAR SPOT + FILTRO
local saveB = mkBtn("GUARDAR",      10, 144, 92, Color3.fromRGB(70, 70, 80))
local filtB = mkBtn("FILTRO: ROBO", 108, 144, 92, Color3.fromRGB(45, 120, 75))

-- Fila 5: FAST PROMPTS
local fastB = mkBtn("FAST PROMPTS: OFF", 10, 180, 190, Color3.fromRGB(60, 60, 70))

local hint = Instance.new("TextLabel")
hint.Size = UDim2.new(1, -20, 0, 32)
hint.Position = UDim2.new(0, 10, 0, 216)
hint.BackgroundTransparency = 1
hint.Font = Enum.Font.Gotham
hint.TextSize = 10
hint.TextWrapped = true
hint.TextXAlignment = Enum.TextXAlignment.Left
hint.TextColor3 = Color3.fromRGB(150, 150, 160)
hint.Text = "Clic en [Tecla] para cambiar bind. Todo se guarda automatico."
hint.Parent = panel

local st = Instance.new("TextLabel")
st.Size = UDim2.new(1, -20, 0, 16)
st.Position = UDim2.new(0, 10, 0, 252)
st.BackgroundTransparency = 1
st.Font = Enum.Font.Gotham
st.TextSize = 10
st.TextXAlignment = Enum.TextXAlignment.Left
st.TextColor3 = Color3.fromRGB(140, 200, 140)
st.Text = "listo"
st.Parent = panel

local function shortKeyName(k)
    if k == "RightShift" then return "RShift" end
    if k == "LeftShift" then return "LShift" end
    if k == "RightControl" then return "RCtrl" end
    if k == "LeftControl" then return "LCtrl" end
    return k
end

local function refresh()
    title.Text = frozen and "FREEZE: ON" or "FREEZE: OFF"
    title.TextColor3 = frozen and Color3.fromRGB(120, 220, 140) or Color3.fromRGB(120, 190, 255)
    frz.BackgroundColor3 = frozen and Color3.fromRGB(45, 140, 80) or Color3.fromRGB(45, 90, 150)

    fastB.Text = fastOn and "FAST PROMPTS: ON" or "FAST PROMPTS: OFF"
    fastB.BackgroundColor3 = fastOn and Color3.fromRGB(110, 50, 160) or Color3.fromRGB(60, 60, 70)

    autoB.Text = autoOn and "AUTO ROBO: ON" or "AUTO ROBO: OFF"
    autoB.BackgroundColor3 = autoOn and Color3.fromRGB(170, 70, 45) or Color3.fromRGB(60, 60, 70)

    filtB.Text = onlySteal and "FILTRO: ROBO" or "FILTRO: TODO"
    filtB.BackgroundColor3 = onlySteal and Color3.fromRGB(45, 120, 75) or Color3.fromRGB(140, 100, 45)

    guiBtn.Text = panel.Visible and "PANEL GUI: ON" or "PANEL GUI: OFF"
    frzKey.Text  = "[" .. shortKeyName(config.freezeKey) .. "]"
    autoKey.Text = "[" .. shortKeyName(config.autoRoboKey) .. "]"
    guiKey.Text  = "[" .. shortKeyName(config.toggleGuiKey) .. "]"
end

-- ===== ACCIONES TOGGLE =====
local function toggleFreeze()
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
end

local function toggleAutoRobo()
    autoOn = not autoOn
    config.autoOn = autoOn
    saveConfig()
    st.Text = autoOn and "auto robo ON" or "auto robo OFF"
    refresh()
end

local function togglePanelGui()
    panel.Visible = not panel.Visible
    refresh()
end

-- ===== CONEXIONES DE CLIC =====
frz.MouseButton1Click:Connect(toggleFreeze)
autoB.MouseButton1Click:Connect(toggleAutoRobo)
guiBtn.MouseButton1Click:Connect(togglePanelGui)

saveB.MouseButton1Click:Connect(function()
    local _, _, hrp = char()
    if hrp then spot = hrp.CFrame end
    saveConfig()
    st.Text = "punto y config guardados"
end)

fastB.MouseButton1Click:Connect(function()
    fastOn = not fastOn
    config.fastOn = fastOn
    saveConfig()
    if fastOn then scanFast(); st.Text = "fast prompts ON" else restorePrompts(); st.Text = "fast prompts OFF" end
    refresh()
end)

filtB.MouseButton1Click:Connect(function()
    onlySteal = not onlySteal
    config.onlySteal = onlySteal
    saveConfig()
    refresh()
end)

-- ===== SISTEMA DE VINCULACIÓN DE TECLAS (KEYBINDS) =====
local bindingTarget = nil -- "freezeKey" | "autoRoboKey" | "toggleGuiKey"

frzKey.MouseButton1Click:Connect(function()
    bindingTarget = "freezeKey"
    frzKey.Text = "..."
    st.Text = "presiona tecla para FREEZE"
end)

autoKey.MouseButton1Click:Connect(function()
    bindingTarget = "autoRoboKey"
    autoKey.Text = "..."
    st.Text = "presiona tecla para AUTO ROBO"
end)

guiKey.MouseButton1Click:Connect(function()
    bindingTarget = "toggleGuiKey"
    guiKey.Text = "..."
    st.Text = "presiona tecla para PANEL GUI"
end)

local inputConn
inputConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    local keyName = input.KeyCode.Name

    if bindingTarget then
        if keyName == "Escape" then
            bindingTarget = nil
            st.Text = "asignacion cancelada"
            refresh()
            return
        end
        config[bindingTarget] = keyName
        bindingTarget = nil
        saveConfig()
        st.Text = "tecla guardada: " .. keyName
        refresh()
        return
    end

    if gameProcessed then return end

    if keyName == config.freezeKey then
        toggleFreeze()
    elseif keyName == config.autoRoboKey then
        toggleAutoRobo()
    elseif keyName == config.toggleGuiKey then
        togglePanelGui()
    end
end)

close.MouseButton1Click:Connect(function()
    running = false
    autoOn = false
    frozen = false
    if inputConn then inputConn:Disconnect() end
    restorePrompts()
    local _, _, hrp = char()
    if hrp then pcall(function() hrp.Anchored = false end) end
    gui:Destroy()
end)

refresh()
print("[Combo] Cargado. Keybinds y guardado activo.")

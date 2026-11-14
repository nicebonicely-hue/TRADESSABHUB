-- =========================================
-- SAB HUB | Steal a Brainrot - Optimizado & Creado desde Cero
-- =========================================

if _G.SAB then
    pcall(function()
        _G.SAB:Destroy()
    end)
end

local Players = game:GetService("Players")
local lp = Players.LocalPlayer

local CFG = {
    scanDelay = 1.0,
    promptCooldown = 0.45,
    teleport = true,
    autoBuy = false,
    freeze = false,
    lockHP = true,
    antiRagdoll = false,
    fastPrompts = false,
    selected = {},
}

local promptEntries = {}
local promptCooldowns = setmetatable({}, {__mode = "k"})
local scannerAlive = true
local isBuying = false

local stats = {
    attempts = 0,
    confirmed = 0,
}

local st
local btnBuy, btnFreeze, btnTp, btnAntiRagdoll, btnFastPrompts

-- =========================================
-- UTILIDADES Y FILTROS SEGUROS
-- =========================================

local GENERIC_NAMES = {
    part = true, model = true, stand = true, pedestal = true,
    base = true, prompt = true, proximityprompt = true, buy = true,
    spawn = true, hitbox = true, workspace = true, folder = true
}

local function cleanName(val)
    if type(val) ~= "string" then return nil end
    val = val:match("^%s*(.-)%s*$")
    if #val < 2 or #val > 64 then return nil end
    local lower = val:lower()
    if GENERIC_NAMES[lower] or lower == "purchase" or lower == "comprar" or lower == "buy" then
        return nil
    end
    if val:match("^%$?[%d%.,]+$") then return nil end
    return val
end

local function getBrainrotName(prompt)
    if not prompt or not prompt.Parent then return "Desconocido" end
    
    local node = prompt.Parent
    for i = 1, 6 do
        if not node then break end
        
        local ok, attrs = pcall(function() return node:GetAttributes() end)
        if ok and attrs then
            for _, attrName in ipairs({"BrainrotName", "DisplayName", "ItemName", "UnitName", "PetName"}) do
                local cleaned = cleanName(attrs[attrName])
                if cleaned then return cleaned end
            end
        end
        
        local okName, nameVal = pcall(function() return node.Name end)
        if okName and nameVal then
            local cleaned = cleanName(nameVal)
            if cleaned and not GENERIC_NAMES[cleaned:lower()] then
                return cleaned
            end
        end
        
        node = node.Parent
    end

    local okText, objText = pcall(function() return prompt.ObjectText end)
    if okText and cleanName(objText) then
        return cleanName(objText)
    end

    return "Brainrot Pasarela"
end

local function isBuyPrompt(prompt)
    local ok, result = pcall(function()
        local action = tostring(prompt.ActionText or ""):lower()
        local object = tostring(prompt.ObjectText or ""):lower()
        local combined = action .. " " .. object
        return combined:find("buy", 1, true) ~= nil 
            or combined:find("purchase", 1, true) ~= nil 
            or combined:find("comprar", 1, true) ~= nil
    end)
    return ok and result
end

-- =========================================
-- ESCANEO DE PASARELA (Sin Warnings)
-- =========================================

local function scanPrompts()
    local entries = {}
    local success, descendants = pcall(function() return workspace:GetDescendants() end)
    if not success or not descendants then return entries end

    for _, obj in ipairs(descendants) do
        local isPrompt = pcall(function() return obj:IsA("ProximityPrompt") end)
        if isPrompt and obj:IsA("ProximityPrompt") then
            if isBuyPrompt(obj) then
                local name = getBrainrotName(obj)
                table.insert(entries, {
                    prompt = obj,
                    name = name,
                    key = name:lower():gsub("%s+", " "),
                })
            end
        end
    end
    return entries
end

local function getPromptPosition(prompt)
    local node = prompt.Parent
    for i = 1, 6 do
        if not node then break end
        if node:IsA("Attachment") then return node.WorldPosition end
        if node:IsA("BasePart") then return node.Position end
        if node:IsA("Model") then return node:GetPivot().Position end
        node = node.Parent
    end
    return nil
end

local function toast(msg)
    if st then st.Text = msg end
end

-- =========================================
-- GUI / INTERFAZ GRÁFICA
-- =========================================

local parent = (pcall(gethui) and gethui()) or game:GetService("CoreGui")

local gui = Instance.new("ScreenGui")
gui.Name = "SAB_Hub"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = parent
_G.SAB = gui

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 270, 0, 470)
main.Position = UDim2.new(0, 20, 0, 80)
main.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 8)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
title.BorderSizePixel = 0
title.Text = "SAB | Pasarela Optimizada"
title.TextColor3 = Color3.fromRGB(235, 235, 245)
title.Font = Enum.Font.GothamBold
title.TextSize = 13
title.Parent = main
Instance.new("UICorner", title).CornerRadius = UDim.new(0, 8)

st = Instance.new("TextLabel")
st.Size = UDim2.new(1, -20, 0, 16)
st.Position = UDim2.new(0, 10, 0, 34)
st.BackgroundTransparency = 1
st.Text = "Escaneando pasarela..."
st.TextColor3 = Color3.fromRGB(140, 200, 140)
st.Font = Enum.Font.Gotham
st.TextSize = 11
st.TextXAlignment = Enum.TextXAlignment.Left
st.Parent = main

local function mkButton(txt, y, color, callback)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -20, 0, 28)
    b.Position = UDim2.new(0, 10, 0, y)
    b.BackgroundColor3 = color
    b.BorderSizePixel = 0
    b.Text = txt
    b.TextColor3 = Color3.fromRGB(240, 240, 245)
    b.Font = Enum.Font.GothamSemibold
    b.TextSize = 12
    b.Parent = main
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    b.MouseButton1Click:Connect(callback)
    return b
end

local search = Instance.new("TextBox")
search.Size = UDim2.new(1, -20, 0, 26)
search.Position = UDim2.new(0, 10, 0, 224)
search.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
search.BorderSizePixel = 0
search.PlaceholderText = "buscar brainrot..."
search.Text = ""
search.TextColor3 = Color3.fromRGB(230, 230, 235)
search.Font = Enum.Font.Gotham
search.TextSize = 12
search.Parent = main
Instance.new("UICorner", search).CornerRadius = UDim.new(0, 6)

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -20, 1, -260)
scroll.Position = UDim2.new(0, 10, 0, 254)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 4
scroll.Parent = main

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 3)
listLayout.Parent = scroll

listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    scroll.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 4)
end)

local function buildGroups()
    local groups = {}
    for _, entry in ipairs(promptEntries) do
        if not groups[entry.key] then
            groups[entry.key] = { name = entry.name, count = 0 }
        end
        groups[entry.key].count = groups[entry.key].count + 1
    end
    return groups
end

local function updateStatus()
    local groups = buildGroups()
    local detected = 0
    for _ in pairs(groups) do detected = detected + 1 end
    st.Text = string.format("Pasarela: %d un. | Intentos: %d", detected, stats.attempts)
end

local function refreshList()
    for _, child in ipairs(scroll:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end

    local groups = buildGroups()
    local keys = {}
    for k in pairs(groups) do table.insert(keys, k) end
    table.sort(keys)

    local query = search.Text:lower():gsub("%s+", " ")
    local order = 0

    for _, key in ipairs(keys) do
        local group = groups[key]
        if query == "" or key:find(query, 1, true) then
            local selected = CFG.selected[key] == true
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 0, 26)
            btn.BackgroundColor3 = selected and Color3.fromRGB(35, 110, 70) or Color3.fromRGB(32, 32, 40)
            btn.BorderSizePixel = 0
            btn.Text = string.format(" %s %s (%d)", selected and "[X]" or "[ ]", group.name, group.count)
            btn.TextColor3 = Color3.fromRGB(225, 225, 235)
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 11
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.LayoutOrder = order
            btn.Parent = scroll
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)

            local capturedKey = key
            btn.MouseButton1Click:Connect(function()
                CFG.selected[capturedKey] = not CFG.selected[capturedKey]
                refreshList()
            end)
            order = order + 1
        end
    end
    updateStatus()
end

search:GetPropertyChangedSignal("Text"):Connect(refreshList)

local function updateButtons()
    local function setBtn(b, name, state, col)
        if b then
            b.Text = name .. ": " .. (state and "ON" or "OFF")
            b.BackgroundColor3 = state and col or Color3.fromRGB(60, 60, 70)
        end
    end
    setBtn(btnBuy, "AutoBuy", CFG.autoBuy, Color3.fromRGB(35, 130, 70))
    setBtn(btnFreeze, "Freeze", CFG.freeze, Color3.fromRGB(35, 110, 150))
    setBtn(btnTp, "Teletransporte", CFG.teleport, Color3.fromRGB(100, 90, 160))
    setBtn(btnAntiRagdoll, "Anti-Ragdoll", CFG.antiRagdoll, Color3.fromRGB(150, 90, 35))
    setBtn(btnFastPrompts, "Fast Prompts", CFG.fastPrompts, Color3.fromRGB(110, 50, 160))
end

btnBuy = mkButton("AutoBuy: OFF", 54, Color3.fromRGB(60, 60, 70), function()
    CFG.autoBuy = not CFG.autoBuy
    updateButtons()
    toast(CFG.autoBuy and "AutoBuy activado" or "AutoBuy desactivado")
end)

btnFreeze = mkButton("Freeze: OFF", 88, Color3.fromRGB(60, 60, 70), function()
    CFG.freeze = not CFG.freeze
    updateButtons()
end)

btnTp = mkButton("Teletransporte: ON", 122, Color3.fromRGB(60, 60, 70), function()
    CFG.teleport = not CFG.teleport
    updateButtons()
end)

btnAntiRagdoll = mkButton("Anti-Ragdoll: OFF", 156, Color3.fromRGB(60, 60, 70), function()
    CFG.antiRagdoll = not CFG.antiRagdoll
    updateButtons()
end)

btnFastPrompts = mkButton("Fast Prompts: OFF", 190, Color3.fromRGB(60, 60, 70), function()
    CFG.fastPrompts = not CFG.fastPrompts
    updateButtons()
end)

task.spawn(function()
    while scannerAlive and gui.Parent do
        task.wait(CFG.scanDelay)
        if scannerAlive then
            local ok, entries = pcall(scanPrompts)
            if ok and entries then
                promptEntries = entries
                refreshList()
            end
        end
    end
end)

task.spawn(function()
    while scannerAlive and gui.Parent do
        task.wait(0.05)
        if CFG.autoBuy and not isBuying then
            isBuying = true
            for _, entry in ipairs(promptEntries) do
                if not CFG.autoBuy then break end
                if CFG.selected[entry.key] == true then
                    local prompt = entry.prompt
                    if prompt and prompt.Parent and prompt.Enabled then
                        stats.attempts = stats.attempts + 1
                        pcall(function()
                            if CFG.teleport then
                                local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
                                local pos = getPromptPosition(prompt)
                                if hrp and pos then
                                    hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
                                    task.wait(0.05)
                                end
                            end
                            prompt.HoldDuration = 0
                            if type(fireproximityprompt) == "function" then
                                fireproximityprompt(prompt)
                            else
                                prompt:InputHoldBegin()
                                task.wait(0.03)
                                prompt:InputHoldEnd()
                            end
                        end)
                        task.wait(CFG.promptCooldown)
                    end
                end
            end
            isBuying = false
        end
    end
end)

local close = Instance.new("TextButton")
close.Size = UDim2.new(0, 30, 0, 30)
close.Position = UDim2.new(1, -32, 0, 0)
close.BackgroundTransparency = 1
close.Text = "X"
close.TextColor3 = Color3.fromRGB(255, 90, 90)
close.Font = Enum.Font.GothamBold
close.TextSize = 14
close.Parent = main

close.MouseButton1Click:Connect(function()
    scannerAlive = false
    gui:Destroy()
end)

updateButtons()
toast("SAB actualizado y cargado correctamente")

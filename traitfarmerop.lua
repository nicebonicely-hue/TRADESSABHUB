--[[ 
    Steal a Brainrot | SAB Hub | GUI + Scanner + Freeze + Verified AutoBuy + Anti-Ragdoll + Fast Prompts
    Versión Completa Optimizada y Corregida desde Cero
]]

-- =========================================
-- LIMPIEZA PREVIA
-- =========================================

if _G.SAB then
    pcall(function()
        _G.SAB:Destroy()
    end)
end

local Players = game:GetService("Players")
local lp = Players.LocalPlayer

local CFG = {
    delay = 0.05,          
    scanDelay = 1.2,
    verifyTimeout = 0.35,  
    promptCooldown = 0.45, 

    teleport = true,
    autoBuy = false,
    freeze = false,
    lockHP = true,
    antiRagdoll = false,   
    fastPrompts = false,   

    selected = {},
}

local promptCooldowns = setmetatable({}, {__mode = "k"})
local promptWatchers = setmetatable({}, {__mode = "k"})
local promptEntries = {}
local scanConnections = {}

local lastSignature = nil
local freezeState = nil
local scheduleScan

local st
local btnBuy, btnFreeze, btnTp, btnAntiRagdoll, btnFastPrompts

local scannerAlive = true
local scanQueued = false
local isBuying = false

local stats = {
    attempts = 0,
    confirmed = 0,
}

-- =========================================
-- UTILIDADES
-- =========================================

local GENERIC = {
    part = true,
    model = true,
    stand = true,
    pedestal = true,
    base = true,
    prompt = true,
    proximityprompt = true,
    buy = true,
    spawn = true,
    hitbox = true,
    workspace = true,
    folder = true,
    proximitypromptpart = true,
    warning = true,
}

local NAME_ATTRIBUTES = {
    "BrainrotName",
    "DisplayName",
    "ItemName",
    "UnitName",
    "PetName",
}

local CURRENCY_NAMES = {
    "cash", "coins", "money", "gold", "points", 
    "dinero", "monedas", "bux", "tokens", "credits"
}

local function normalizeName(name)
    return tostring(name or "")
        :match("^%s*(.-)%s*$")
        :lower()
        :gsub("%s+", " ")
end

local function cleanName(value)
    if type(value) ~= "string" then
        return nil
    end

    value = value:match("^%s*(.-)%s*$")

    if #value < 2 or #value > 64 then
        return nil
    end

    local lower = value:lower()

    if GENERIC[lower] or lower:find("warning", 1, true) then
        return nil
    end

    if lower == "purchase"
        or lower == "comprar"
        or lower == "buy" then
        return nil
    end

    if lower:match("^purchase%s")
        or lower:match("^comprar%s")
        or lower:match("^buy%s") then
        return nil
    end

    if value:match("^%$?[%d%.,]+$") then
        return nil
    end

    return value
end

-- =========================================
-- IDENTIFICACION DE NOMBRES (CORREGIDO Y BLINDADO)
-- =========================================

local function ancestorName(prompt)
    if not prompt or not prompt.Parent then return nil end
    
    local nodes = {}
    local node = prompt.Parent

    for i = 1, 12 do
        if not node then
            break
        end

        nodes[#nodes + 1] = node
        node = node.Parent
    end

    -- Búsqueda blindada por pcall en atributos actuales del servidor de Sammy
    for _, current in ipairs(nodes) do
        local okAttrs, attrs = pcall(function() return current:GetAttributes() end)
        if okAttrs and attrs then
            for _, attribute in ipairs(NAME_ATTRIBUTES) do
                local value = cleanName(attrs[attribute])
                if value then
                    return value
                end
            end
            for _, value in pairs(attrs) do
                local cleaned = cleanName(value)
                if cleaned then
                    return cleaned
                end
            end
        end
    end

    local okText, objectText = pcall(function() return cleanName(prompt.ObjectText) end)
    if okText and objectText then
        return objectText
    end

    for _, current in ipairs(nodes) do
        local okModel, nameVal = pcall(function()
            if current:IsA("Model") or current:IsA("BasePart") then
                return cleanName(current.Name)
            end
            return nil
        end)
        if okModel and nameVal then
            return nameVal
        end
    end

    return nil
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
-- ESCANEO (CORREGIDO Y BLINDADO)
-- =========================================

local function scanPrompts()
    local entries = {}
    local activePrompts = {}

    local success, descendants = pcall(function() return workspace:GetDescendants() end)
    if not success or not descendants then
        return entries, activePrompts
    end

    for _, obj in ipairs(descendants) do
        local isPrompt = pcall(function() return obj:IsA("ProximityPrompt") end)
        if isPrompt and obj:IsA("ProximityPrompt") then
            activePrompts[obj] = true

            if isBuyPrompt(obj) then
                local name = ancestorName(obj)

                if name then
                    entries[#entries + 1] = {
                        prompt = obj,
                        name = name,
                        key = normalizeName(name),
                    }
                end
            end
        end
    end

    table.sort(entries, function(a, b)
        if a.key == b.key then
            return a.name < b.name
        end
        return a.key < b.key
    end)

    return entries, activePrompts
end

local function getPromptPosition(prompt)
    local node = prompt.Parent

    for i = 1, 8 do
        if not node then
            break
        end

        if node:IsA("Attachment") then
            return node.WorldPosition
        end

        if node:IsA("BasePart") then
            return node.Position
        end

        if node:IsA("Model") then
            return node:GetPivot().Position
        end

        node = node.Parent
    end

    return nil
end

-- =========================================
-- MENSAJES Y ESTADO
-- =========================================

local function toast(message)
    if st then
        st.Text = message
    end
    print("[SAB] " .. message)
end

-- =========================================
-- FREEZE
-- =========================================

local function applyFreeze()
    local char = lp.Character
    if not char then
        return
    end

    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")

    if not hum and not hrp then
        return
    end

    if not freezeState or freezeState.character ~= char then
        freezeState = {
            character = char,
            humanoid = hum,
            root = hrp,

            walkSpeed = hum and hum.WalkSpeed,
            jumpPower = hum and hum.JumpPower,
            jumpHeight = hum and hum.JumpHeight,
            autoRotate = hum and hum.AutoRotate,
            platformStand = hum and hum.PlatformStand,

            maxHealth = hum and hum.MaxHealth,
            health = hum and hum.Health,

            anchored = hrp and hrp.Anchored,
        }
    end

    if hum then
        hum.WalkSpeed = 0
        hum.JumpPower = 0
        hum.JumpHeight = 0
        hum.AutoRotate = false
        hum.PlatformStand = true

        if CFG.lockHP then
            hum.MaxHealth = math.huge
            hum.Health = math.huge
        end
    end

    if hrp then
        hrp.Anchored = true
    end
end

local function clearFreeze()
    local state = freezeState
    if not state then
        return
    end

    local hum = state.humanoid
    local hrp = state.root

    if hum and hum.Parent then
        if state.walkSpeed ~= nil then hum.WalkSpeed = state.walkSpeed end
        if state.jumpPower ~= nil then hum.JumpPower = state.jumpPower end
        if state.jumpHeight ~= nil then hum.JumpHeight = state.jumpHeight end
        if state.autoRotate ~= nil then hum.AutoRotate = state.autoRotate end
        if state.platformStand ~= nil then hum.PlatformStand = state.platformStand end
        if state.maxHealth ~= nil then hum.MaxHealth = state.maxHealth end
        if state.health ~= nil then
            hum.Health = math.min(state.health, hum.MaxHealth)
        end
    end

    if hrp and hrp.Parent then
        hrp.Anchored = state.anchored or false
    end

    freezeState = nil
end

lp.CharacterAdded:Connect(function()
    freezeState = nil
    task.wait(1)
    if CFG.freeze then
        applyFreeze()
    end
end)

-- =========================================
-- SISTEMA DE CONFIRMACION Y AUTOBUY
-- =========================================

local function getCurrencySnapshot()
    local snapshot = {}
    local ls = lp:FindFirstChild("leaderstats")
    if ls then
        for _, stat in ipairs(ls:GetChildren()) do
            if stat:IsA("IntValue") or stat:IsA("NumberValue") then
                local sName = stat.Name:lower()
                for _, cName in ipairs(CURRENCY_NAMES) do
                    if sName:find(cName, 1, true) then
                        snapshot[stat] = stat.Value
                        break
                    end
                end
            end
        end
    end
    return snapshot
end

local function getBackpackCount()
    local bp = lp:FindFirstChildOfClass("Backpack")
    local char = lp.Character
    local count = bp and #bp:GetChildren() or 0
    if char then
        for _, child in ipairs(char:GetChildren()) do
            if child:IsA("Tool") then
                count = count + 1
            end
        end
    end
    return count
end

local function verifyPurchase(prompt, initialParent, initialCurrency, initialItems, timeout)
    local start = os.clock()

    while os.clock() - start < timeout do
        if not prompt or not prompt.Parent or not prompt:IsDescendantOf(workspace) then
            return true, "Prompt consumido"
        end
        if not prompt.Enabled then
            return true, "Prompt deshabilitado"
        end
        if prompt.Parent ~= initialParent then
            return true, "Objeto movido"
        end

        for stat, oldVal in pairs(initialCurrency) do
            if stat and stat.Parent and stat.Value < oldVal then
                return true, "Saldo descontado"
            end
        end

        if getBackpackCount() > initialItems then
            return true, "Item en inventario"
        end

        task.wait(0.03)
    end

    return false, "Sin respuesta del servidor"
end

local function triggerPrompt(prompt)
    if type(fireproximityprompt) == "function" then
        local ok = pcall(fireproximityprompt, prompt)
        if ok then return true end
    end

    local ok = pcall(function()
        prompt:InputHoldBegin()
        task.wait(0.03)
        prompt:InputHoldEnd()
    end)
    return ok
end

local function tryBuy(entry)
    local prompt = entry.prompt
    if not prompt or not prompt.Parent or not prompt.Enabled then
        return false
    end

    local now = os.clock()
    if promptCooldowns[prompt] and (now - promptCooldowns[prompt]) < CFG.promptCooldown then
        return false
    end

    local char = lp.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then
        return false
    end

    local initialParent = prompt.Parent
    local initialCurrency = getCurrencySnapshot()
    local initialItems = getBackpackCount()
    local originalHold = prompt.HoldDuration

    local savedCFrame = nil
    local teleported = false

    promptCooldowns[prompt] = now
    stats.attempts = stats.attempts + 1

    if CFG.teleport and not CFG.freeze then
        local targetPosition = getPromptPosition(prompt)
        if not targetPosition then
            return false
        end

        savedCFrame = hrp.CFrame
        hrp.CFrame = CFrame.new(targetPosition + Vector3.new(0, 3, 0))
        teleported = true
        task.wait(0.08)
    end

    if not prompt or not prompt.Parent or not prompt.Enabled then
        if teleported and hrp and hrp.Parent and savedCFrame then
            hrp.CFrame = savedCFrame
        end
        return false
    end

    toast("Intentando: " .. entry.name)

    pcall(function()
        prompt.HoldDuration = 0
    end)

    local firedOk = triggerPrompt(prompt)

    local confirmed, reason = false, "Error al disparar prompt"
    if firedOk then
                        confirmed, reason = verifyPurchase(
            prompt,
            initialParent,
            initialCurrency,
            initialItems,
            CFG.verifyTimeout
        )
    end

    if prompt and prompt.Parent then
        pcall(function()
            prompt.HoldDuration = originalHold
        end)
    end

    if teleported and hrp and hrp.Parent and savedCFrame then
        hrp.CFrame = savedCFrame
    end

    if confirmed then
        stats.confirmed = stats.confirmed + 1
        toast(string.format("Confirmado: %s (%s)", entry.name, reason))
        scheduleScan()
        return true
    else
        toast(string.format("No confirmado: %s", entry.name))
        return false
    end
end

-- =========================================
-- GUI
-- =========================================

local parent
if type(gethui) == "function" then
    local ok, result = pcall(gethui)
    if ok then
        parent = result
    end
end
parent = parent or game:GetService("CoreGui")

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
title.Text = "SAB | AutoBuy + Freeze"
title.TextColor3 = Color3.fromRGB(235, 235, 245)
title.Font = Enum.Font.GothamBold
title.TextSize = 13
title.Parent = main

Instance.new("UICorner", title).CornerRadius = UDim.new(0, 8)

st = Instance.new("TextLabel")
st.Size = UDim2.new(1, -20, 0, 16)
st.Position = UDim2.new(0, 10, 0, 34)
st.BackgroundTransparency = 1
st.Text = "Listo"
st.TextColor3 = Color3.fromRGB(140, 200, 140)
st.Font = Enum.Font.Gotham
st.TextSize = 11
st.TextXAlignment = Enum.TextXAlignment.Left
st.TextTruncate = Enum.TextTruncate.AtEnd
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

-- =========================================
-- BUSCADOR Y LISTA
-- =========================================

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
search.ClearTextOnFocus = false
search.Parent = main

Instance.new("UICorner", search).CornerRadius = UDim.new(0, 6)

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -20, 1, -260)
scroll.Position = UDim2.new(0, 10, 0, 254)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 4
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.Parent = main

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 3)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = scroll

listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    scroll.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 4)
end)

-- =========================================
-- AGRUPACION Y CONTADORES
-- =========================================

local function buildGroups()
    local groups = {}
    for _, entry in ipairs(promptEntries) do
        local group = groups[entry.key]
        if not group then
            group = {
                key = entry.key,
                name = entry.name,
                count = 0,
            }
            groups[entry.key] = group
        end
        group.count = group.count + 1
    end
    return groups
end

local function countSelected(groups)
    local amount = 0
    for key in pairs(groups) do
        if CFG.selected[key] == true then
            amount = amount + 1
        end
    end
    return amount
end

local function updateStatus()
    if isBuying then
        return
    end

    local groups = buildGroups()
    local detected = 0
    for _ in pairs(groups) do
        detected = detected + 1
    end

    st.Text = string.format(
        "Brainrots: %d | Marcados: %d | OK: %d/%d",
        detected,
        countSelected(groups),
        stats.confirmed,
        stats.attempts
    )
end

-- =========================================
-- DIBUJAR LISTA
-- =========================================

local function refreshList()
    for _, child in ipairs(scroll:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end

    local groups = buildGroups()
    local keys = {}
    for key in pairs(groups) do
        keys[#keys + 1] = key
    end
    table.sort(keys)

    local query = normalizeName(search.Text)
    local order = 0

    for _, key in ipairs(keys) do
        local entry = groups[key]
        local matches = (query == "") or (key:find(query, 1, true) ~= nil)

        if matches then
            local selected = CFG.selected[key] == true
            local button = Instance.new("TextButton")

            button.Size = UDim2.new(1, 0, 0, 26)
            button.BackgroundColor3 = selected
                and Color3.fromRGB(35, 110, 70)
                or Color3.fromRGB(32, 32, 40)
            button.BorderSizePixel = 0
            button.Text = string.format(
                " %s %s (%d)",
                selected and "[X]" or "[ ]",
                entry.name,
                entry.count
            )
            button.TextColor3 = Color3.fromRGB(225, 225, 235)
            button.Font = Enum.Font.Gotham
            button.TextSize = 11
            button.TextXAlignment = Enum.TextXAlignment.Left
            button.LayoutOrder = order
            button.Parent = scroll

            Instance.new("UICorner", button).CornerRadius = UDim.new(0, 5)

            local selectedKey = key
            button.MouseButton1Click:Connect(function()
                if not groups[selectedKey] then
                    return
                end
                if CFG.selected[selectedKey] then
                    CFG.selected[selectedKey] = nil
                else
                    CFG.selected[selectedKey] = true
                end
                refreshList()
                updateStatus()
            end)

            order = order + 1
        end
    end

    scroll.CanvasSize = UDim2.new(0, 0, 0, order * 29)
    updateStatus()
end

search:GetPropertyChangedSignal("Text"):Connect(refreshList)

-- =========================================
-- BOTONES Y ESTADOS
-- =========================================

local function updateButtons()
    local function update(button, label, enabled, color)
        if not button then return end
        button.Text = label .. ": " .. (enabled and "ON" or "OFF")
        button.BackgroundColor3 = enabled and color or Color3.fromRGB(60, 60, 70)
    end

    update(btnBuy, "AutoBuy", CFG.autoBuy, Color3.fromRGB(35, 130, 70))
    update(btnFreeze, "Freeze", CFG.freeze, Color3.fromRGB(35, 110, 150))
    update(btnTp, "Teletransporte", CFG.teleport, Color3.fromRGB(100, 90, 160))
    update(btnAntiRagdoll, "Anti-Ragdoll", CFG.antiRagdoll, Color3.fromRGB(150, 90, 35))
    update(btnFastPrompts, "Fast Prompts", CFG.fastPrompts, Color3.fromRGB(110, 50, 160))
end

btnBuy = mkButton("AutoBuy: OFF", 54, Color3.fromRGB(60, 60, 70), function()
    CFG.autoBuy = not CFG.autoBuy
    updateButtons()
    toast(CFG.autoBuy and "AutoBuy activado" or "AutoBuy desactivado")
end)

btnFreeze = mkButton("Freeze: OFF", 88, Color3.fromRGB(60, 60, 70), function()
    CFG.freeze = not CFG.freeze
    if CFG.freeze then
        applyFreeze()
        toast("Freeze activado")
    else
        clearFreeze()
        toast("Freeze desactivado")
    end
    updateButtons()
end)

btnTp = mkButton("Teletransporte: ON", 122, Color3.fromRGB(60, 60, 70), function()
    CFG.teleport = not CFG.teleport
    updateButtons()
    toast(CFG.teleport and "Teletransporte activado" or "Teletransporte desactivado")
end)

btnAntiRagdoll = mkButton("Anti-Ragdoll: OFF", 156, Color3.fromRGB(60, 60, 70), function()
    CFG.antiRagdoll = not CFG.antiRagdoll
    updateButtons()
    toast(CFG.antiRagdoll and "Anti-Ragdoll activado" or "Anti-Ragdoll desactivado")
end)

btnFastPrompts = mkButton("Fast Prompts: OFF", 190, Color3.fromRGB(60, 60, 70), function()
    CFG.fastPrompts = not CFG.fastPrompts
    updateButtons()
    toast(CFG.fastPrompts and "Fast Prompts activado (0.1s)" or "Fast Prompts desactivado")
end)

-- =========================================
-- ACTUALIZACION DE ESCANEO
-- =========================================

local function updatePromptWatchers(activePrompts)
    for prompt in pairs(activePrompts) do
        if not promptWatchers[prompt] then
            local connections = {}

            table.insert(connections, prompt:GetPropertyChangedSignal("ActionText"):Connect(function()
                if scannerAlive then scheduleScan() end
            end))

            table.insert(connections, prompt:GetPropertyChangedSignal("ObjectText"):Connect(function()
                if scannerAlive then scheduleScan() end
            end))

            table.insert(connections, prompt:GetPropertyChangedSignal("Enabled"):Connect(function()
                if scannerAlive then scheduleScan() end
            end))

            promptWatchers[prompt] = connections
        end
    end

    for prompt, connections in pairs(promptWatchers) do
        if not activePrompts[prompt] then
            for _, connection in ipairs(connections) do
                connection:Disconnect()
            end
            promptWatchers[prompt] = nil
        end
    end
end

local function refreshScan()
    local newEntries, activePrompts = scanPrompts()
    promptEntries = newEntries

    updatePromptWatchers(activePrompts)

    local sortedKeys = {}
    local groups = buildGroups()

    for key in pairs(groups) do
        sortedKeys[#sortedKeys + 1] = key
    end
    table.sort(sortedKeys)

    local signatureParts = {}
    for _, key in ipairs(sortedKeys) do
        local group = groups[key]
        signatureParts[#signatureParts + 1] = key .. ":" .. tostring(group.count)
    end

    local signature = table.concat(signatureParts, "|")

    if signature ~= lastSignature then
        lastSignature = signature
        refreshList()
    else
        updateStatus()
    end
end

scheduleScan = function()
    if not scannerAlive or scanQueued then
        return
    end

    scanQueued = true

    task.delay(0.12, function()
        scanQueued = false
        if not scannerAlive or not gui.Parent then
            return
        end

        local ok, err = pcall(refreshScan)
        if not ok then
            warn("[SAB] Error al actualizar escaneo:", err)
        end
    end)
end

table.insert(scanConnections, workspace.DescendantAdded:Connect(function(instance)
    if instance:IsA("ProximityPrompt") then
        scheduleScan()
    end
end))

table.insert(scanConnections, workspace.DescendantRemoving:Connect(function(instance)
    if instance:IsA("ProximityPrompt") then
        scheduleScan()
    end
end))

-- =========================================
-- CERRAR Y LIMPIAR
-- =========================================

local close = Instance.new("TextButton")
close.Size = UDim2.new(0, 30, 0, 30)
close.Position = UDim2.new(1, -32, 0, 0)
close.BackgroundTransparency = 1
close.Text = "X"
close.TextColor3 = Color3.fromRGB(255, 90, 90)
close.Font = Enum.Font.GothamBold
close.TextSize = 14
close.Parent = main

local function cleanupScanner()
    if not scannerAlive then
        return
    end

    scannerAlive = false
    CFG.autoBuy = false

    for _, connection in ipairs(scanConnections) do
        connection:Disconnect()
    end

    for _, connections in pairs(promptWatchers) do
        for _, connection in ipairs(connections) do
            connection:Disconnect()
        end
    end

    table.clear(promptWatchers)
end

close.MouseButton1Click:Connect(function()
    CFG.autoBuy = false
    if CFG.freeze then
        CFG.freeze = false
        clearFreeze()
    end
    updateButtons()
    cleanupScanner()
    gui:Destroy()
end)

gui.Destroying:Connect(cleanupScanner)

-- =========================================
-- LOOPS PRINCIPALES
-- =========================================

task.spawn(function()
    while scannerAlive and gui.Parent do
        task.wait(CFG.scanDelay)
        if scannerAlive and gui.Parent then
            local ok, err = pcall(refreshScan)
            if not ok then
                warn("[SAB] Error en reconciliacion:", err)
            end
        end
    end
end)

task.spawn(function()
    while scannerAlive and gui.Parent do
        task.wait(CFG.delay)

        if CFG.autoBuy and not isBuying then
            isBuying = true

            local queue = table.clone(promptEntries)

            for _, entry in ipairs(queue) do
                if not CFG.autoBuy or not scannerAlive or not gui.Parent then
                                                                    break
                end

                if CFG.selected[entry.key] == true then
                    local prompt = entry.prompt
                    local now = os.clock()
                    local ready = not promptCooldowns[prompt] or (now - promptCooldowns[prompt] >= CFG.promptCooldown)

                    if prompt and prompt.Parent and prompt.Enabled and ready then
                        tryBuy(entry)
                        task.wait(CFG.delay)
                    end
                end
            end

            isBuying = false
            updateStatus()
        end
    end
end)

task.spawn(function()
    while scannerAlive and gui.Parent do
        task.wait(0.15)
        if CFG.freeze then
            pcall(applyFreeze)
        end
    end
end)

-- Loop Anti-Ragdoll Definitivo (Con reactivación de W, A, S, D y movimiento continuo)
task.spawn(function()
    while scannerAlive and gui.Parent do
        task.wait(0.05)
        if CFG.antiRagdoll then
            pcall(function()
                local char = lp.Character
                if not char then return end
                local hum = char:FindFirstChildOfClass("Humanoid")
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if not hum or not hrp or hum.Health <= 0 then return end

                local state = hum:GetState()
                if state == Enum.HumanoidStateType.Physics or state == Enum.HumanoidStateType.Ragdoll or state == Enum.HumanoidStateType.FallingDown or state == Enum.HumanoidStateType.PlatformStanding then
                    hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                    hrp.Velocity = Vector3.zero
                    hrp.RotVelocity = Vector3.zero
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                    
                    for _, desc in ipairs(char:GetDescendants()) do
                        if desc:IsA("Motor6D") or desc:IsA("Weld") then
                            desc.Enabled = true
                        end
                    end
                    
                    hum.AutoRotate = true
                    hum.PlatformStand = false
                    hum.Sit = false

                    if hum.WalkSpeed < 1 then
                        hum.WalkSpeed = 16
                    end

                    local playerScripts = lp:FindFirstChild("PlayerScripts")
                    if playerScripts then
                        local playerModule = playerScripts:FindFirstChild("PlayerModule")
                        if playerModule then
                            local controls = require(playerModule):GetControls()
                            if controls then
                                controls:Enable()
                            end
                        end
                    end
                end
            end)
        end
    end
end)

task.spawn(function()
    while scannerAlive and gui.Parent do
        task.wait(0.1)
        if CFG.fastPrompts then
            pcall(function()
                for _, prompt in pairs(workspace:GetDescendants()) do
                    if prompt:IsA("ProximityPrompt") then
                        prompt.HoldDuration = 0
                    end
                end
            end)
        end
    end
end)

-- =========================================
-- INICIALIZACION
-- =========================================

updateButtons()

local ok, err = pcall(refreshScan)
if not ok then
    warn("[SAB] Error en escaneo inicial:", err)
end

toast("SAB cargado correctamente")

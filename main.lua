
--[[ 
    Steal a Brainrot | SAB Hub | GUI + Scanner + Freeze
    Scanner con eventos + reconciliacion periodica
]]

-- =========================================
-- LIMPIEZA
-- =========================================

if _G.SAB then
    pcall(function()
        _G.SAB:Destroy()
    end)
end

local Players = game:GetService("Players")
local lp = Players.LocalPlayer

local CFG = {
    delay = 0.25,
    scanDelay = 1.2,

    teleport = true,
    autoBuy = false,
    freeze = false,
    lockHP = true,

    selected = {},
}

local fired = setmetatable({}, {__mode = "k"})
local promptEntries = {}
local lastSignature = nil
local freezeState = nil

local st
local btnBuy, btnFreeze, btnTp

local scanConnections = {}
local promptWatchers = setmetatable({}, {__mode = "k"})

local scannerAlive = true
local scanQueued = false

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
}

local NAME_ATTRIBUTES = {
    "BrainrotName",
    "DisplayName",
    "ItemName",
    "UnitName",
    "PetName",
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

    if GENERIC[lower] then
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
-- IDENTIFICACION DE NOMBRES
-- =========================================

local function ancestorName(prompt)
    local nodes = {}
    local node = prompt.Parent

    for i = 1, 10 do
        if not node then
            break
        end

        nodes[#nodes + 1] = node
        node = node.Parent
    end

    -- Primero: atributos conocidos.
    for _, current in ipairs(nodes) do
        for _, attribute in ipairs(NAME_ATTRIBUTES) do
            local value = cleanName(
                current:GetAttribute(attribute)
            )

            if value then
                return value
            end
        end
    end

    -- Segundo: otros atributos de texto.
    for _, current in ipairs(nodes) do
        local attributes = current:GetAttributes()

        for _, value in pairs(attributes) do
            local cleaned = cleanName(value)

            if cleaned then
                return cleaned
            end
        end
    end

    -- Tercero: ObjectText.
    local objectText = cleanName(prompt.ObjectText)

    if objectText then
        return objectText
    end

    -- Cuarto: nombres de modelos.
    for _, current in ipairs(nodes) do
        if current:IsA("Model") then
            local value = cleanName(current.Name)

            if value then
                return value
            end
        end
    end

    -- Ultimo recurso: nombre de algun antecesor.
    for _, current in ipairs(nodes) do
        local value = cleanName(current.Name)

        if value then
            return value
        end
    end

    return nil
end

local function isBuyPrompt(prompt)
    local action = tostring(prompt.ActionText or ""):lower()
    local object = tostring(prompt.ObjectText or ""):lower()

    local combined = action .. " " .. object

    return combined:find("buy", 1, true) ~= nil
        or combined:find("purchase", 1, true) ~= nil
        or combined:find("comprar", 1, true) ~= nil
end

-- =========================================
-- ESCANEO
-- =========================================

local function scanPrompts()
    local entries = {}
    local activePrompts = {}

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then

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
-- MENSAJES
-- =========================================

local function toast(message)
    if st then
        st.Text = message
    end

    print("[SAB] " .. message)
end

-- =========================================
-- FREEZE
-- IMPLEMENTACION ORIGINAL DE LA VERSION CORREGIDA
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
        if state.walkSpeed ~= nil then
            hum.WalkSpeed = state.walkSpeed
        end

        if state.jumpPower ~= nil then
            hum.JumpPower = state.jumpPower
        end

        if state.jumpHeight ~= nil then
            hum.JumpHeight = state.jumpHeight
        end

        if state.autoRotate ~= nil then
            hum.AutoRotate = state.autoRotate
        end

        if state.platformStand ~= nil then
            hum.PlatformStand = state.platformStand
        end

        if state.maxHealth ~= nil then
            hum.MaxHealth = state.maxHealth
        end

        if state.health ~= nil then
            hum.Health = math.min(
                state.health,
                hum.MaxHealth
            )
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
-- COMPRA
-- =========================================

local function tryBuy(entry)
    local prompt = entry.prompt

    if not prompt or not prompt.Parent then
        return false
    end

    if not prompt.Enabled then
        return false
    end

    local now = os.clock()

    if fired[prompt] and now - fired[prompt] < 0.7 then
        return false
    end

    local char = lp.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")

    if not hrp then
        return false
    end

    if type(fireproximityprompt) ~= "function" then
        return false
    end

    local targetPosition = nil
    local savedCFrame = nil
    local teleported = false

    if CFG.teleport and not CFG.freeze then
        targetPosition = getPromptPosition(prompt)

        if not targetPosition then
            return false
        end

        savedCFrame = hrp.CFrame

        fired[prompt] = now

        pcall(function()
            prompt.HoldDuration = 0
        end)

        hrp.CFrame = CFrame.new(
            targetPosition + Vector3.new(0, 3, 0)
        )

        teleported = true

        task.wait(0.15)

    else
        fired[prompt] = now

        pcall(function()
            prompt.HoldDuration = 0
        end)
    end

    local success = pcall(function()
        fireproximityprompt(prompt)
    end)

    if teleported then
        task.wait(0.1)

        if hrp and hrp.Parent then
            hrp.CFrame = savedCFrame
        end
    end

    return success
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
main.Size = UDim2.new(0, 260, 0, 400)
main.Position = UDim2.new(0, 20, 0, 80)
main.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.Parent = gui

Instance.new("UICorner", main).CornerRadius =
    UDim.new(0, 8)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
title.BorderSizePixel = 0
title.Text = "SAB | AutoBuy + Freeze"
title.TextColor3 = Color3.fromRGB(235, 235, 245)
title.Font = Enum.Font.GothamBold
title.TextSize = 13
title.Parent = main

Instance.new("UICorner", title).CornerRadius =
    UDim.new(0, 8)

-- =========================================
-- ESTADO
-- =========================================

st = Instance.new("TextLabel")
st.Size = UDim2.new(1, -20, 0, 16)
st.Position = UDim2.new(0, 10, 0, 34)
st.BackgroundTransparency = 1
st.Text = "Listo"
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

    Instance.new("UICorner", b).CornerRadius =
        UDim.new(0, 6)

    b.MouseButton1Click:Connect(callback)

    return b
end

-- =========================================
-- BUSCADOR
-- =========================================

local search = Instance.new("TextBox")
search.Size = UDim2.new(1, -20, 0, 26)
search.Position = UDim2.new(0, 10, 0, 156)
search.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
search.BorderSizePixel = 0
search.PlaceholderText = "buscar brainrot..."
search.Text = ""
search.TextColor3 = Color3.fromRGB(230, 230, 235)
search.Font = Enum.Font.Gotham
search.TextSize = 12
search.ClearTextOnFocus = false
search.Parent = main

Instance.new("UICorner", search).CornerRadius =
    UDim.new(0, 6)

-- =========================================
-- LISTA
-- =========================================

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -20, 1, -192)
scroll.Position = UDim2.new(0, 10, 0, 186)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 4
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.Parent = main

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 3)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = scroll

listLayout:GetPropertyChangedSignal(
    "AbsoluteContentSize"
):Connect(function()

    scroll.CanvasSize = UDim2.new(
        0,
        0,
        0,
        listLayout.AbsoluteContentSize.Y + 4
    )
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
    local groups = buildGroups()

    local detected = 0
    local promptCount = #promptEntries

    for _ in pairs(groups) do
        detected = detected + 1
    end

    st.Text = string.format(
        "Brainrots: %d | Prompts: %d | Marcados: %d",
        detected,
        promptCount,
        countSelected(groups)
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

        local matches =
            query == ""
            or key:find(query, 1, true) ~= nil

        if matches then
            local selected = CFG.selected[key] == true

            local button = Instance.new("TextButton")

            button.Size = UDim2.new(1, 0, 0, 26)

            button.BackgroundColor3 = selected
                and Color3.fromRGB(35, 110, 70)
                or Color3.fromRGB(32, 32, 40)

            button.BorderSizePixel = 0

            button.Text = string.format(
                "%s %s (%d)",
                selected and "[X]" or "[ ]",
                entry.name,
                entry.count
            )

            button.TextColor3 =
                Color3.fromRGB(225, 225, 235)

            button.Font = Enum.Font.Gotham
            button.TextSize = 11
            button.TextXAlignment =
                Enum.TextXAlignment.Left

            button.LayoutOrder = order
            button.Parent = scroll

            Instance.new("UICorner", button).CornerRadius =
                UDim.new(0, 5)

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

    scroll.CanvasSize = UDim2.new(
        0,
        0,
        0,
        order * 29
    )

    updateStatus()
end

search:GetPropertyChangedSignal("Text"):Connect(refreshList)

-- =========================================
-- BOTONES Y ESTADOS
-- =========================================

local function updateButtons()
    local function update(button, label, enabled, color)
        if not button then
            return
        end

        button.Text = label .. ": " ..
            (enabled and "ON" or "OFF")

        button.BackgroundColor3 = enabled
            and color
            or Color3.fromRGB(60, 60, 70)
    end

    update(
        btnBuy,
        "AutoBuy",
        CFG.autoBuy,
        Color3.fromRGB(35, 130, 70)
    )

    update(
        btnFreeze,
        "Freeze",
        CFG.freeze,
        Color3.fromRGB(35, 110, 150)
    )

    update(
        btnTp,
        "Teletransporte",
        CFG.teleport,
        Color3.fromRGB(100, 90, 160)
    )
end

-- =========================================
-- BOTONES
-- =========================================

btnBuy = mkButton(
    "AutoBuy: OFF",
    54,
    Color3.fromRGB(60, 60, 70),
    function()
        CFG.autoBuy = not CFG.autoBuy

        updateButtons()

        toast(
            CFG.autoBuy
            and "AutoBuy activado"
            or "AutoBuy desactivado"
        )
    end
)

btnFreeze = mkButton(
    "Freeze: OFF",
    88,
    Color3.fromRGB(60, 60, 70),
    function()
        CFG.freeze = not CFG.freeze

        if CFG.freeze then
            applyFreeze()
            toast("Freeze activado")
        else
            clearFreeze()
            toast("Freeze desactivado")
        end

        updateButtons()
    end
)

btnTp = mkButton(
    "Teletransporte: ON",
    122,
    Color3.fromRGB(60, 60, 70),
    function()
        CFG.teleport = not CFG.teleport

        updateButtons()

        toast(
            CFG.teleport
            and "Teletransporte activado"
            or "Teletransporte desactivado"
        )
    end
)

-- =========================================
-- ACTUALIZACION DE ESCANEO
-- =========================================

local function updatePromptWatchers(activePrompts)
    for prompt in pairs(activePrompts) do
        if not promptWatchers[prompt] then
            local connections = {}

            table.insert(
                connections,
                prompt:GetPropertyChangedSignal("ActionText"):Connect(
                    function()
                        if scannerAlive then
                            scheduleScan()
                        end
                    end
                )
            )

            table.insert(
                connections,
                prompt:GetPropertyChangedSignal("ObjectText"):Connect(
                    function()
                        if scannerAlive then
                            scheduleScan()
                        end
                    end
                )
            )

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

    local presentKeys = {}
    local groups = buildGroups()

    for key in pairs(groups) do
        presentKeys[key] = true
    end

    -- Limpiar selecciones que ya no existen.
    for key in pairs(CFG.selected) do
        if not presentKeys[key] then
            CFG.selected[key] = nil
        end
    end

    -- La firma incluye cantidad de prompts.
    -- Asi se redibuja cuando cambia el conjunto de objetos
    -- aunque se conserve el mismo nombre.

    local sortedKeys = {}

    for key in pairs(groups) do
        sortedKeys[#sortedKeys + 1] = key
    end

    table.sort(sortedKeys)

    local signatureParts = {}

    for _, key in ipairs(sortedKeys) do
        local group = groups[key]

        signatureParts[#signatureParts + 1] =
            key .. ":" .. tostring(group.count)
    end

    local signature = table.concat(signatureParts, "|")

    if signature ~= lastSignature then
        lastSignature = signature
        refreshList()
    else
        updateStatus()
    end
end

-- =========================================
-- ESCANEO POR EVENTOS
-- =========================================

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

table.insert(
    scanConnections,
    workspace.DescendantAdded:Connect(function(instance)
        if instance:IsA("ProximityPrompt") then
            scheduleScan()
        end
    end)
)

table.insert(
    scanConnections,
    workspace.DescendantRemoving:Connect(function(instance)
        if instance:IsA("ProximityPrompt") then
            scheduleScan()
        end
    end)
)

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
-- LOOP DE RECONCILIACION
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

-- =========================================
-- LOOP AUTOBUY
-- =========================================

task.spawn(function()
    while scannerAlive and gui.Parent do
        task.wait(math.max(CFG.delay, 0.1))

        if CFG.autoBuy then
            for _, entry in ipairs(promptEntries) do
                if CFG.selected[entry.key] == true then
                    if tryBuy(entry) then
                        break
                    end
                end
            end
        end
    end
end)

-- =========================================
-- LOOP FREEZE
-- =========================================

task.spawn(function()
    while gui.Parent do
        task.wait(0.15)

        if CFG.freeze then
            pcall(applyFreeze)
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

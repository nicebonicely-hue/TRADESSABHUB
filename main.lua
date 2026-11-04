
--[[ Steal a Brainrot | SAB Hub | GUI + Scanner + Freeze ]]
-- Version corregida de la estructura original.

-- ===== LIMPIEZA =====

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
    buyAll = false,
    autoBuy = false,
    freeze = false,
    lockHP = true,

    selected = {},
}

local fired = setmetatable({}, {__mode = "k"})
local promptEntries = {}
local lastSignature = nil
local freezeState = nil

-- IMPORTANTE:
-- Declarar estas referencias antes de usarlas.
local st
local btnBuy, btnFreeze, btnTp, btnAll

-- ===== UTILIDADES =====

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
}

local function normalizeName(name)
    return tostring(name or "")
        :match("^%s*(.-)%s*$")
        :lower()
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

    if lower:find("buy", 1, true)
        or lower:find("purchase", 1, true)
        or lower:find("comprar", 1, true) then
        return nil
    end

    if value:match("^%$?[%d%.,]+$") then
        return nil
    end

    return value
end

local NAME_ATTRIBUTES = {
    "BrainrotName",
    "DisplayName",
    "ItemName",
    "UnitName",
    "PetName",
}

local function ancestorName(prompt)
    local node = prompt.Parent

    if not node then
        return nil
    end

    local fallback

    for i = 1, 8 do
        if not node then
            break
        end

        -- Buscar atributos conocidos.
        for _, attribute in ipairs(NAME_ATTRIBUTES) do
            local value = cleanName(
                node:GetAttribute(attribute)
            )

            if value then
                return value
            end
        end

        -- Buscar un nombre de modelo.
        if node:IsA("Model") then
            local value = cleanName(node.Name)

            if value then
                return value
            end
        end

        if not fallback then
            fallback = cleanName(node.Name)
        end

        node = node.Parent
    end

    -- Último recurso: texto del prompt.
    local objectText = cleanName(prompt.ObjectText)

    return objectText or fallback
end

local function isBuyPrompt(prompt)
    local action = tostring(prompt.ActionText or ""):lower()
    local object = tostring(prompt.ObjectText or ""):lower()

    local combined = action .. " " .. object

    return combined:find("buy", 1, true) ~= nil
        or combined:find("purchase", 1, true) ~= nil
        or combined:find("comprar", 1, true) ~= nil
end

-- ===== ESCANEO =====

local function scanPrompts()
    local entries = {}

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") and isBuyPrompt(obj) then

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

    table.sort(entries, function(a, b)
        if a.key == b.key then
            return tostring(a.prompt) < tostring(b.prompt)
        end

        return a.key < b.key
    end)

    return entries
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

-- ===== MENSAJES =====

local function toast(message)
    if st then
        st.Text = message
    end

    print("[SAB] " .. message)
end

-- ===== FREEZE =====

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

    -- Guardar los valores originales una sola vez
    -- para poder restaurarlos correctamente.

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

-- ===== COMPRA =====

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

    -- Función específica del entorno Delta.
    -- No es una confirmación de compra del servidor.

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

-- ===== GUI =====

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

-- ===== ESTADO =====

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

-- IMPORTANTE: actualizar todos los textos y colores
-- desde una sola función.

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

    update(
        btnAll,
        "Comprar TODO",
        CFG.buyAll,
        Color3.fromRGB(160, 110, 35)
    )
end

-- ===== BOTONES =====

btnBuy = mkButton(
    "AutoBuy: OFF",
    54,
    Color3.fromRGB(60, 60, 70),
    function()

        CFG.autoBuy = not CFG.autoBuy

        updateButtons()

        if CFG.autoBuy then
            toast("AutoBuy activado")
        else
            toast("AutoBuy desactivado")
        end
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

btnAll = mkButton(
    "Comprar TODO: OFF",
    156,
    Color3.fromRGB(60, 60, 70),
    function()

        CFG.buyAll = not CFG.buyAll

        updateButtons()

        toast(
            CFG.buyAll
            and "Modo comprar todo activado"
            or "Modo comprar todo desactivado"
        )
    end
)

-- ===== CERRAR =====

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
    CFG.autoBuy = false

    if CFG.freeze then
        CFG.freeze = false
        clearFreeze()
    end

    gui:Destroy()
end)

-- ===== BUSCADOR =====

local search = Instance.new("TextBox")
search.Size = UDim2.new(1, -20, 0, 26)
search.Position = UDim2.new(0, 10, 0, 190)
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

-- ===== LISTA =====

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -20, 1, -226)
scroll.Position = UDim2.new(0, 10, 0, 220)
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

-- ===== CONTADORES =====

local function countSelected()
    local amount = 0

    for _, selected in pairs(CFG.selected) do
        if selected then
            amount = amount + 1
        end
    end

    return amount
end

local function updateStatus()
    local names = {}

    for _, entry in ipairs(promptEntries) do
        names[entry.key] = true
    end

    local detected = 0

    for _ in pairs(names) do
        detected = detected + 1
    end

    st.Text = string.format(
        "Detectados: %d | Marcados: %d",
        detected,
        countSelected()
    )
end

-- ===== DIBUJAR LISTA =====

local function refreshList()

    -- Borrar solamente los botones anteriores.
    for _, child in ipairs(scroll:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end

    local seen = {}
    local order = 0

    local query = normalizeName(search.Text)

    for _, entry in ipairs(promptEntries) do

        if not seen[entry.key] then

            seen[entry.key] = true

            local matches =
                query == ""
                or entry.key:find(query, 1, true) ~= nil

            if matches then

                local selected =
                    CFG.selected[entry.key] == true

                local button = Instance.new("TextButton")

                button.Size = UDim2.new(1, 0, 0, 26)

                button.BackgroundColor3 = selected
                    and Color3.fromRGB(35, 110, 70)
                    or Color3.fromRGB(32, 32, 40)

                button.BorderSizePixel = 0

                button.Text = (selected and "[X] " or "[ ] ")
                    .. entry.name

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

                button.MouseButton1Click:Connect(function()

                    if CFG.selected[entry.key] then
                        CFG.selected[entry.key] = nil
                    else
                        CFG.selected[entry.key] = true
                    end

                    refreshList()
                    updateStatus()
                end)

                order = order + 1
            end
        end
    end

    scroll.CanvasSize = UDim2.new(
        0,
        0,
        0,
        order * 29
    )
end

search:GetPropertyChangedSignal("Text"):Connect(
    refreshList
)

-- ===== ESCANEO Y ACTUALIZACIÓN =====

local function refreshScan()

    promptEntries = scanPrompts()

    local names = {}

    for _, entry in ipairs(promptEntries) do
        names[entry.key] = entry.name
    end

    local sortedNames = {}

    for key in pairs(names) do
        sortedNames[#sortedNames + 1] = key
    end

    table.sort(sortedNames)

    local signature = table.concat(sortedNames, "|")

    -- Solo reconstruir la interfaz cuando cambie la lista.
    if signature ~= lastSignature then
        lastSignature = signature
        refreshList()
    end

    updateStatus()
end

-- ===== LOOP DE ESCANEO =====

task.spawn(function()

    while gui.Parent do

        task.wait(CFG.scanDelay)

        if gui.Parent then
            pcall(refreshScan)
        end
    end
end)

-- ===== LOOP AUTOBUY =====

task.spawn(function()

    while gui.Parent do

        task.wait(math.max(CFG.delay, 0.1))

        if CFG.autoBuy then

            for _, entry in ipairs(promptEntries) do

                local shouldBuy =
                    CFG.buyAll
                    or CFG.selected[entry.key] == true

                if shouldBuy then

                    if tryBuy(entry) then
                        break
                    end
                end
            end
        end
    end
end)

-- ===== LOOP FREEZE =====

task.spawn(function()

    while gui.Parent do

        task.wait(0.15)

        if CFG.freeze then
            pcall(applyFreeze)
        end
    end
end)

-- ===== INICIALIZACIÓN =====

updateButtons()

pcall(refreshScan)

toast("SAB cargado correctamente")


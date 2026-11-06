--[[
    SAB ULTIMATE COORDINATE SYSTEM
    Scanner + Manual Teleport + Saved Locations
]]

-- LIMPIAR VERSION ANTERIOR
if _G.SABUltimate and _G.SABUltimate.Destroy then
    pcall(_G.SABUltimate.Destroy)
end

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer

local State = {
    Results = {},
    Saved = {},
    PreviousPosition = nil,
    Destroyed = false
}

local Positive = {
    "collect", "collection", "pickup", "pick up",
    "craftpad", "craft pad", "output", "claim",
    "recoger", "recoleccion", "recolección",
    "ingredient", "submit", "dropoff", "drop off"
}

local Negative = {
    "open", "abrir", "buy", "comprar",
    "interact", "trade", "duel"
}

local function containsAny(text, words)
    text = string.lower(tostring(text or ""))
    for _, word in ipairs(words) do
        if string.find(text, word, 1, true) then
            return true
        end
    end
    return false
end

local function getCharacter()
    return Player.Character
end

local function getRoot()
    local char = getCharacter()
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getPosition(obj)
    if obj:IsA("BasePart") then
        return obj.Position
    elseif obj:IsA("Attachment") then
        return obj.WorldPosition
    elseif obj:IsA("ProximityPrompt") then
        local parent = obj.Parent
        if parent and parent:IsA("BasePart") then
            return parent.Position
        end
    end
    return nil
end

local function teleport(position)
    local root = getRoot()
    if not root then return false end

    State.PreviousPosition = root.Position

    local success = pcall(function()
        root.CFrame = CFrame.new(position + Vector3.new(0, 3, 0))
    end)

    return success
end

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "SABUltimateCoordinateSystem"
gui.ResetOnSpawn = false

pcall(function()
    gui.Parent = gethui()
end)

if not gui.Parent then
    gui.Parent = CoreGui
end

local main = Instance.new("Frame")
main.Size = UDim2.fromOffset(570, 490)
main.Position = UDim2.new(0.5, -285, 0.5, -245)
main.BackgroundColor3 = Color3.fromRGB(18, 20, 29)
main.BorderSizePixel = 0
main.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = main

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(75, 105, 190)
stroke.Thickness = 1.5
stroke.Parent = main

local function make(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props) do
        obj[k] = v
    end
    obj.Parent = parent
    return obj
end

local header = make("Frame", {
    Size = UDim2.new(1, 0, 0, 55),
    BackgroundColor3 = Color3.fromRGB(28, 34, 53),
    BorderSizePixel = 0
}, main)

local title = make("TextLabel", {
    Size = UDim2.new(1, -65, 1, 0),
    Position = UDim2.fromOffset(17, 0),
    BackgroundTransparency = 1,
    Text = "SAB  |  ULTIMATE COORDINATE SYSTEM",
    TextColor3 = Color3.fromRGB(235, 240, 255),
    TextSize = 16,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left
}, header)

local close = make("TextButton", {
    Size = UDim2.fromOffset(35, 35),
    Position = UDim2.new(1, -45, 0, 10),
    BackgroundColor3 = Color3.fromRGB(180, 55, 70),
    Text = "X",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 16,
    Font = Enum.Font.GothamBold
}, header)

make("UICorner", {CornerRadius = UDim.new(0, 8)}, close)

-- ARRASTRAR VENTANA
local dragging = false
local dragStart, startPosition

header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPosition = main.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (
        input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
    ) then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

local content = make("ScrollingFrame", {
    Size = UDim2.new(1, -24, 1, -115),
    Position = UDim2.fromOffset(12, 65),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y
}, main)

make("UIListLayout", {
    Padding = UDim.new(0, 8),
    SortOrder = Enum.SortOrder.LayoutOrder
}, content)

local function label(text, height)
    return make("TextLabel", {
        Size = UDim2.new(1, -5, 0, height or 25),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = Color3.fromRGB(220, 225, 240),
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left
    }, content)
end

local function button(text, callback, color)
    local b = make("TextButton", {
        Size = UDim2.new(1, -5, 0, 36),
        BackgroundColor3 = color or Color3.fromRGB(48, 67, 115),
        Text = text,
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = 13,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = true
    }, content)

    make("UICorner", {CornerRadius = UDim.new(0, 7)}, b)
    b.MouseButton1Click:Connect(callback)
    return b
end

local function textbox(placeholder, default)
    local box = make("TextBox", {
        Size = UDim2.new(1, -5, 0, 35),
        BackgroundColor3 = Color3.fromRGB(33, 37, 51),
        TextColor3 = Color3.new(1, 1, 1),
        PlaceholderColor3 = Color3.fromRGB(140, 145, 165),
        PlaceholderText = placeholder,
        Text = default or "",
        TextSize = 14,
        Font = Enum.Font.Gotham,
        ClearTextOnFocus = false
    }, content)

    make("UICorner", {CornerRadius = UDim.new(0, 7)}, box)
    return box
end

local status = label("Estado: listo", 25)

local function setStatus(text)
    status.Text = "Estado: " .. text
end

-- SCANNER
label("01  |  COLLECTION ZONE SCANNER")

local resultsFrame = make("Frame", {
    Size = UDim2.new(1, -5, 0, 5),
    BackgroundTransparency = 1
}, content)

local resultsLayout = make("UIListLayout", {
    Padding = UDim.new(0, 5),
    SortOrder = Enum.SortOrder.LayoutOrder
}, resultsFrame)

local function clearResults()
    for _, child in ipairs(resultsFrame:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
end

local function addResult(obj, pos)
    local index = #State.Results + 1
    local entry = {
        Object = obj,
        Position = pos,
        Name = obj:GetFullName()
    }

    table.insert(State.Results, entry)

    local b = make("TextButton", {
        Size = UDim2.new(1, 0, 0, 42),
        BackgroundColor3 = Color3.fromRGB(36, 48, 72),
        Text = string.format(
            "%02d  |  %s\nX %.1f   Y %.1f   Z %.1f",
            index, obj.Name, pos.X, pos.Y, pos.Z
        ),
        TextColor3 = Color3.fromRGB(225, 235, 255),
        TextSize = 11,
        Font = Enum.Font.Gotham,
        TextWrapped = true
    }, resultsFrame)

    make("UICorner", {CornerRadius = UDim.new(0, 6)}, b)

    b.MouseButton1Click:Connect(function()
        teleport(entry.Position)
        setStatus("Teletransporte solicitado a " .. entry.Name)
    end)
end

local function scan()
    State.Results = {}
    clearResults()

    local found = 0

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("Attachment")
        or obj:IsA("ProximityPrompt") then

            local searchText = obj.Name

            if obj:IsA("ProximityPrompt") then
                searchText = searchText .. " " ..
                    obj.ActionText .. " " .. obj.ObjectText
            end

            local position = getPosition(obj)

            if position
            and containsAny(searchText, Positive)
            and not containsAny(searchText, Negative) then
                addResult(obj, position)
                found += 1
            end
        end
    end

    resultsFrame.Size = UDim2.new(1, -5, 0, math.max(5, found * 47))

    setStatus(found .. " posibles zonas encontradas")
end

button("SCAN COLLECTION ZONES", scan, Color3.fromRGB(42, 105, 85))

button("COPY FIRST RESULT XYZ", function()
    local entry = State.Results[1]
    if not entry then
        setStatus("No hay resultados")
        return
    end

    local p = entry.Position
    local value = string.format("%.3f, %.3f, %.3f", p.X, p.Y, p.Z)

    if setclipboard then
        setclipboard(value)
        setStatus("Coordenadas copiadas")
    else
        setStatus(value)
    end
end)

-- TELETRANSPORTE MANUAL
label("02  |  MANUAL TELEPORT")

local xBox = textbox("Coordenada X", "0")
local yBox = textbox("Coordenada Y", "10")
local zBox = textbox("Coordenada Z", "0")

button("TELEPORT TO XYZ", function()
    local x = tonumber(xBox.Text)
    local y = tonumber(yBox.Text)
    local z = tonumber(zBox.Text)

    if not x or not y or not z then
        setStatus("Introduce coordenadas validas")
        return
    end

    if teleport(Vector3.new(x, y, z)) then
        setStatus("Teletransporte solicitado")
    else
        setStatus("No se encontro tu personaje")
    end
end, Color3.fromRGB(55, 95, 165))

-- POSICION ACTUAL
label("03  |  PLAYER POSITION")

local positionLabel = label("X: --   Y: --   Z: --", 30)

button("GET MY POSITION", function()
    local root = getRoot()
    if not root then return end

    local p = root.Position
    local coords = string.format(
        "%.3f, %.3f, %.3f", p.X, p.Y, p.Z
    )

    positionLabel.Text = "X: " .. string.format("%.2f", p.X)
        .. "   Y: " .. string.format("%.2f", p.Y)
        .. "   Z: " .. string.format("%.2f", p.Z)

    if setclipboard then
        setclipboard(coords)
    end

    setStatus("Posicion obtenida")
end)

-- GUARDAR Y VOLVER
label("04  |  SAVED LOCATIONS")

local saveName = textbox("Nombre de la ubicacion")

local savedFrame = make("Frame", {
    Size = UDim2.new(1, -5, 0, 5),
    BackgroundTransparency = 1
}, content)

make("UIListLayout", {
    Padding = UDim.new(0, 5)
}, savedFrame)

local function refreshSaved()
    for _, child in ipairs(savedFrame:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end

    for i, entry in ipairs(State.Saved) do
        local b = make("TextButton", {
            Size = UDim2.new(1, 0, 0, 35),
            BackgroundColor3 = Color3.fromRGB(65, 65, 95),
            Text = "GO TO: " .. entry.Name,
            TextColor3 = Color3.new(1, 1, 1),
            TextSize = 12,
            Font = Enum.Font.GothamBold
        }, savedFrame)

        make("UICorner", {CornerRadius = UDim.new(0, 6)}, b)

        b.MouseButton1Click:Connect(function()
            teleport(entry.Position)
            setStatus("Ubicacion: " .. entry.Name)
        end)
    end

    savedFrame.Size = UDim2.new(1, -5, 0, #State.Saved * 40)
end

button("SAVE CURRENT LOCATION", function()
    local root = getRoot()
    if not root then return end

    local name = saveName.Text
    if name == "" then name = "Location " .. (#State.Saved + 1) end

    table.insert(State.Saved, {
        Name = name,
        Position = root.Position
    })

    refreshSaved()
    setStatus("Ubicacion guardada")
end)

button("RETURN TO PREVIOUS POSITION", function()
    if not State.PreviousPosition then
        setStatus("No hay posicion anterior")
        return
    end

    local old = State.PreviousPosition
    State.PreviousPosition = nil

    local root = getRoot()
    if root then
        root.CFrame = CFrame.new(old + Vector3.new(0, 3, 0))
        setStatus("Regreso solicitado")
    end
end, Color3.fromRGB(130, 75, 65))

close.MouseButton1Click:Connect(function()
    State.Destroyed = true
    gui:Destroy()
end)

_G.SABUltimate = {
    Destroy = function()
        gui:Destroy()
    end,
    Scan = scan,
    GetResults = function()
        return State.Results
    end
}

setStatus("Sistema iniciado")

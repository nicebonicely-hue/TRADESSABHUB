
-- SAB GRAB HUB
-- Compact GUI + Local Carry Hide
-- Para Roblox Studio / experiencias propias

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer

if _G.SABGrabHub then
    pcall(function()
        _G.SABGrabHub:Destroy()
    end)
end

local Settings = {
    AutoHide = false,
    Hidden = false,
    GrabDelay = 0.01,
    Scale = 1,
}

local Original = {}
local Connections = {}

local function getCharacter()
    return Player.Character
end

local function isCarriedTool(obj)
    return obj:IsA("Tool")
end

local function getCarriedObjects()
    local result = {}
    local char = getCharacter()

    if not char then return result end

    for _, obj in ipairs(char:GetChildren()) do
        if isCarriedTool(obj) then
            table.insert(result, obj)
        end
    end

    return result
end

local function hideObject(obj)
    if not Original[obj] then
        Original[obj] = {}
    end

    for _, part in ipairs(obj:GetDescendants()) do
        if part:IsA("BasePart") then
            if Original[obj][part] == nil then
                Original[obj][part] = {
                    Transparency = part.LocalTransparencyModifier
                }
            end

            part.LocalTransparencyModifier = 1
        elseif part:IsA("Decal") or part:IsA("Texture") then
            if Original[obj][part] == nil then
                Original[obj][part] = {
                    Transparency = part.Transparency
                }
            end

            part.Transparency = 1
        end
    end
end

local function restoreObject(obj)
    local saved = Original[obj]
    if not saved then return end

    for part, data in pairs(saved) do
        if part and part.Parent then
            pcall(function()
                if part:IsA("BasePart") then
                    part.LocalTransparencyModifier =
                        data.Transparency
                else
                    part.Transparency = data.Transparency
                end
            end)
        end
    end

    Original[obj] = nil
end

local function hideCarried()
    for _, obj in ipairs(getCarriedObjects()) do
        hideObject(obj)
    end
    Settings.Hidden = true
end

local function restoreCarried()
    for obj in pairs(Original) do
        restoreObject(obj)
    end
    Settings.Hidden = false
end

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "SABGrabHub"
gui.ResetOnSpawn = false

local parent
pcall(function()
    parent = gethui()
end)

gui.Parent = parent or game:GetService("CoreGui")

local main = Instance.new("Frame")
main.Size = UDim2.fromOffset(245, 285)
main.Position = UDim2.new(0.5, -122, 0.5, -142)
main.BackgroundColor3 = Color3.fromRGB(19, 22, 32)
main.BorderSizePixel = 0
main.Active = true
main.Parent = gui

Instance.new("UICorner", main).CornerRadius =
    UDim.new(0, 12)

local outline = Instance.new("UIStroke", main)
outline.Color = Color3.fromRGB(75, 115, 210)
outline.Thickness = 1.5

local function create(class, props, parentObject)
    local obj = Instance.new(class)
    for key, value in pairs(props) do
        obj[key] = value
    end
    obj.Parent = parentObject
    return obj
end

local header = create("TextButton", {
    Size = UDim2.new(1, 0, 0, 40),
    BackgroundColor3 = Color3.fromRGB(32, 42, 67),
    Text = "SAB GRAB HUB     [-]",
    TextColor3 = Color3.new(1, 1, 1),
    Font = Enum.Font.GothamBold,
    TextSize = 13,
}, main)

Instance.new("UICorner", header).CornerRadius =
    UDim.new(0, 10)

local body = create("Frame", {
    Size = UDim2.new(1, -20, 1, -55),
    Position = UDim2.fromOffset(10, 48),
    BackgroundTransparency = 1,
}, main)

local layout = create("UIListLayout", {
    Padding = UDim.new(0, 8),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, body)

local function makeButton(text, color, callback)
    local button = create("TextButton", {
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundColor3 = color,
        Text = text,
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamSemibold,
        TextSize = 12,
    }, body)

    Instance.new("UICorner", button).CornerRadius =
        UDim.new(0, 7)

    button.MouseButton1Click:Connect(callback)
    return button
end

local status = create("TextLabel", {
    Size = UDim2.new(1, 0, 0, 27),
    BackgroundTransparency = 1,
    Text = "Estado: listo",
    TextColor3 = Color3.fromRGB(170, 200, 255),
    Font = Enum.Font.Gotham,
    TextSize = 11,
}, body)

local function updateStatus(message)
    status.Text = "Estado: " .. message
end

local hideButton = makeButton(
    "HIDE CARRIED BRAINROT",
    Color3.fromRGB(45, 105, 85),
    function()
        hideCarried()
        updateStatus("Brainrot ocultado localmente")
    end
)

local restoreButton = makeButton(
    "UNHIDE BRAINROT",
    Color3.fromRGB(55, 85, 145),
    function()
        restoreCarried()
        updateStatus("Brainrot restaurado")
    end
)

local autoButton = makeButton(
    "AUTO HIDE: OFF",
    Color3.fromRGB(90, 70, 110),
    function()
        Settings.AutoHide = not Settings.AutoHide
        autoButton.Text = "AUTO HIDE: " ..
            (Settings.AutoHide and "ON" or "OFF")
        updateStatus("Auto Hide actualizado")
    end
)

local delayLabel = create("TextLabel", {
    Size = UDim2.new(1, 0, 0, 22),
    BackgroundTransparency = 1,
    Text = "Intervalo solicitado: 0.01 segundos",
    TextColor3 = Color3.fromRGB(210, 215, 230),
    Font = Enum.Font.Gotham,
    TextSize = 10,
}, body)

makeButton(
    "RESET SETTINGS",
    Color3.fromRGB(110, 65, 65),
    function()
        Settings.AutoHide = false
        Settings.Hidden = false
        restoreCarried()
        autoButton.Text = "AUTO HIDE: OFF"
        updateStatus("Configuracion reiniciada")
    end
)

-- Auto Hide local
table.insert(Connections, game:GetService("RunService").Heartbeat:Connect(
    function()
        if Settings.AutoHide then
            for _, obj in ipairs(getCarriedObjects()) do
                hideObject(obj)
            end
        end
    end
))

-- Detectar respawn
table.insert(Connections, Player.CharacterAdded:Connect(
    function()
        Original = {}
        Settings.Hidden = false
    end
))

-- Minimizar
local minimized = false

header.MouseButton1Click:Connect(function()
    minimized = not minimized
    body.Visible = not minimized
    main.Size = minimized
        and UDim2.fromOffset(245, 40)
        or UDim2.fromOffset(245, 285)
    header.Text = minimized
        and "SAB GRAB HUB     [+]"
        or "SAB GRAB HUB     [-]"
end)

-- Redimensionar
local resize = create("TextButton", {
    Size = UDim2.fromOffset(22, 22),
    Position = UDim2.new(1, -22, 1, -22),
    BackgroundColor3 = Color3.fromRGB(75, 105, 180),
    Text = "↘",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 14,
}, main)

local resizing = false
local startSize
local startInput

resize.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        resizing = true
        startSize = main.Size
        startInput = input.Position
    end
end)

table.insert(Connections, UserInputService.InputChanged:Connect(
    function(input)
        if resizing and (
            input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch
        ) then
            local delta = input.Position - startInput
            main.Size = UDim2.fromOffset(
                math.clamp(startSize.X.Offset + delta.X, 190, 450),
                math.clamp(startSize.Y.Offset + delta.Y, 40, 550)
            )
        end
    end
))

table.insert(Connections, UserInputService.InputEnded:Connect(
    function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            resizing = false
        end
    end
))

_G.SABGrabHub = {
    Destroy = function()
        restoreCarried()
        for _, connection in ipairs(Connections) do
            connection:Disconnect()
        end
        gui:Destroy()
    end
}

print("[SAB GRAB HUB] Loaded")


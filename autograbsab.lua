
-- SAB GRAB HUB - FIXED LOCAL HIDE
-- Para pruebas locales / experiencias propias.
-- No automatiza robos ni interacciones de otros jugadores.

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer

if _G.SABGrabHub then
    pcall(_G.SABGrabHub.Destroy)
end

local CFG = {
    AutoHide = false,
    Delay = 0.15,
    MinWidth = 220,
    MaxWidth = 420,
}

local saved = {}
local connections = {}
local gui

local function getCharacter()
    return player.Character
end

local function isCharacterBody(obj)
    local names = {
        Humanoid = true,
        HumanoidRootPart = true,
        Head = true,
        Torso = true,
        UpperTorso = true,
        LowerTorso = true,
        LeftHand = true,
        RightHand = true,
        LeftFoot = true,
        RightFoot = true,
        LeftUpperArm = true,
        RightUpperArm = true,
        LeftLowerArm = true,
        RightLowerArm = true,
        LeftUpperLeg = true,
        RightUpperLeg = true,
        LeftLowerLeg = true,
        RightLowerLeg = true,
    }

    return names[obj.Name] == true
        or obj:IsA("Accessory")
        or obj:IsA("Humanoid")
        or obj:IsA("Script")
        or obj:IsA("LocalScript")
    end

local function getCandidates()
    local char = getCharacter()
    local result = {}

    if not char then return result end

    for _, obj in ipairs(char:GetChildren()) do
        if (obj:IsA("Model") or obj:IsA("Tool"))
        and not isCharacterBody(obj)
        and #obj:GetDescendants() > 0 then
            table.insert(result, obj)
        end
    end

    return result
end

local function hideObject(obj)
    if not obj or not obj.Parent then return end

    saved[obj] = saved[obj] or {}

    local parts = {}

    if obj:IsA("BasePart") then
        table.insert(parts, obj)
    end

    for _, item in ipairs(obj:GetDescendants()) do
        if item:IsA("BasePart") then
            table.insert(parts, item)
        end
    end

    for _, part in ipairs(parts) do
        if saved[obj][part] == nil then
            saved[obj][part] = part.LocalTransparencyModifier
        end

        part.LocalTransparencyModifier = 1
    end
end

local function restoreObject(obj)
    local data = saved[obj]
    if not data then return end

    for part, transparency in pairs(data) do
        if part and part.Parent then
            pcall(function()
                part.LocalTransparencyModifier = transparency
            end)
        end
    end

    saved[obj] = nil
end

local function hideAll()
    local candidates = getCandidates()

    for _, obj in ipairs(candidates) do
        hideObject(obj)
    end

    return #candidates
end

local function restoreAll()
    for obj in pairs(saved) do
        restoreObject(obj)
    end
end

-- GUI
local parent

pcall(function()
    parent = gethui()
end)

if not parent then
    parent = game:GetService("CoreGui")
end

gui = Instance.new("ScreenGui")
gui.Name = "SABGrabHubFixed"
gui.ResetOnSpawn = false
gui.Parent = parent

local main = Instance.new("Frame")
main.Size = UDim2.fromOffset(260, 245)
main.Position = UDim2.new(0.5, -130, 0.5, -122)
main.BackgroundColor3 = Color3.fromRGB(19, 22, 32)
main.BorderSizePixel = 0
main.Active = true
main.Parent = gui

Instance.new("UICorner", main).CornerRadius =
    UDim.new(0, 10)

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

local header = create("TextLabel", {
    Size = UDim2.new(1, 0, 0, 38),
    BackgroundColor3 = Color3.fromRGB(32, 42, 67),
    Text = "SAB GRAB HUB",
    TextColor3 = Color3.new(1, 1, 1),
    Font = Enum.Font.GothamBold,
    TextSize = 14,
}, main)

Instance.new("UICorner", header).CornerRadius =
    UDim.new(0, 10)

local status = create("TextLabel", {
    Size = UDim2.new(1, -20, 0, 26),
    Position = UDim2.fromOffset(10, 43),
    BackgroundTransparency = 1,
    Text = "STATUS: READY",
    TextColor3 = Color3.fromRGB(170, 200, 255),
    Font = Enum.Font.GothamBold,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
}, main)

local function setStatus(message, color)
    status.Text = "STATUS: " .. message
    status.TextColor3 = color or Color3.fromRGB(170, 200, 255)
end

local function makeButton(text, y, callback)
    local b = create("TextButton", {
        Size = UDim2.new(1, -20, 0, 34),
        Position = UDim2.fromOffset(10, y),
        BackgroundColor3 = Color3.fromRGB(48, 67, 115),
        Text = text,
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamBold,
        TextSize = 12,
    }, main)

    Instance.new("UICorner", b).CornerRadius =
        UDim.new(0, 7)

    b.MouseButton1Click:Connect(callback)
    return b
end

local hideButton = makeButton(
    "HIDE CARRIED BRAINROT",
    78,
    function()
        local count = hideAll()

        if count > 0 then
            setStatus(
                "HIDDEN: " .. count .. " OBJECT(S)",
                Color3.fromRGB(100, 230, 150)
            )
        else
            setStatus(
                "NO CARRIED MODEL DETECTED",
                Color3.fromRGB(255, 190, 100)
            )
        end
    end
)

local restoreButton = makeButton(
    "UNHIDE BRAINROT",
    118,
    function()
        restoreAll()
        setStatus("OBJECTS RESTORED")
    end
)

local autoButton = makeButton(
    "AUTO HIDE: OFF",
    158,
    function()
        CFG.AutoHide = not CFG.AutoHide

        if CFG.AutoHide then
            autoButton.Text = "AUTO HIDE: ON"
            autoButton.BackgroundColor3 =
                Color3.fromRGB(35, 125, 75)

            local count = hideAll()

            setStatus(
                "AUTO HIDE ENABLED (" .. count .. ")",
                Color3.fromRGB(100, 230, 150)
            )
        else
            autoButton.Text = "AUTO HIDE: OFF"
            autoButton.BackgroundColor3 =
                Color3.fromRGB(48, 67, 115)

            setStatus("AUTO HIDE DISABLED")
        end
    end
)

makeButton(
    "RESTORE ALL / RESET",
    198,
    function()
        CFG.AutoHide = false
        autoButton.Text = "AUTO HIDE: OFF"
        autoButton.BackgroundColor3 =
            Color3.fromRGB(48, 67, 115)

        restoreAll()
        setStatus("RESET COMPLETE")
    end
)

-- Detectar objetos que aparezcan mientras Auto Hide está ON
local function watchCharacter(char)
    if connections.ChildAdded then
        connections.ChildAdded:Disconnect()
    end

    connections.ChildAdded = char.ChildAdded:Connect(function(obj)
        if not CFG.AutoHide then return end

        task.delay(CFG.Delay, function()
            if CFG.AutoHide and obj.Parent == char then
                if obj:IsA("Model") or obj:IsA("Tool") then
                    hideObject(obj)
                    setStatus("NEW OBJECT HIDDEN",
                        Color3.fromRGB(100, 230, 150))
                end
            end
        end)
    end)
end

if player.Character then
    watchCharacter(player.Character)
end

connections.CharacterAdded = player.CharacterAdded:Connect(function(char)
    restoreAll()
    saved = {}
    task.wait(0.5)
    watchCharacter(char)
    setStatus("CHARACTER UPDATED")
end)

-- Minimizar
local minimized = false

local minimize = create("TextButton", {
    Size = UDim2.fromOffset(28, 28),
    Position = UDim2.new(1, -34, 0, 5),
    BackgroundColor3 = Color3.fromRGB(60, 75, 110),
    Text = "-",
    TextColor3 = Color3.new(1, 1, 1),
    Font = Enum.Font.GothamBold,
    TextSize = 16,
}, main)

minimize.MouseButton1Click:Connect(function()
    minimized = not minimized
    for _, item in ipairs(main:GetChildren()) do
        if item:IsA("TextButton") and item ~= minimize then
            item.Visible = not minimized
        elseif item == status then
            item.Visible = not minimized
        end
    end

    main.Size = minimized
        and UDim2.fromOffset(260, 38)
        or UDim2.fromOffset(260, 245)

    minimize.Text = minimized and "+" or "-"
end)

-- Redimensionamiento sencillo
local resize = create("TextButton", {
    Size = UDim2.fromOffset(20, 20),
    Position = UDim2.new(1, -20, 1, -20),
    BackgroundColor3 = Color3.fromRGB(75, 105, 180),
    Text = "↘",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 13,
}, main)

local resizing = false
local startPoint
local startSize

resize.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        resizing = true
        startPoint = input.Position
        startSize = main.Size
    end
end)

connections.InputChanged = UIS.InputChanged:Connect(function(input)
    if not resizing then return end

    if input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch then
        local delta = input.Position - startPoint

        main.Size = UDim2.fromOffset(
            math.clamp(startSize.X.Offset + delta.X,
                CFG.MinWidth, CFG.MaxWidth),
            math.clamp(startSize.Y.Offset + delta.Y, 38, 420)
        )
    end
end)

connections.InputEnded = UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        resizing = false
    end
end)

-- Arrastrar panel
local dragging = false
local dragStart
local originalPosition

header.Active = true

header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        originalPosition = main.Position
    end
end)

connections.DragChanged = UIS.InputChanged:Connect(function(input)
    if not dragging then return end

    if input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch then
        local delta = input.Position - dragStart

        main.Position = UDim2.new(
            originalPosition.X.Scale,
            originalPosition.X.Offset + delta.X,
            originalPosition.Y.Scale,
            originalPosition.Y.Offset + delta.Y
        )
    end
end)

connections.DragEnded = UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

_G.SABGrabHub = {
    Destroy = function()
        CFG.AutoHide = false
        restoreAll()

        for _, connection in pairs(connections) do
            if typeof(connection) == "RBXScriptConnection" then
                connection:Disconnect()
            end
        end

        gui:Destroy()
    end
}

print("[SAB GRAB HUB] Fixed version loaded")

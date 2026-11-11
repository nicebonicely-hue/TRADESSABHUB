--[[
    ANTI RAGDOLL - DELTA
    Panel compacto con estado, toggle y contador.
    Recuperacion local: no garantiza anular efectos del servidor.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local UIS = game:GetService("UserInputService")

local Player = Players.LocalPlayer
if not Player then
    warn("[AntiRagdoll] No se encontro LocalPlayer.")
    return
end

-- Limpiar una ejecucion anterior
if _G.AntiRagdollUI and _G.AntiRagdollUI.Destroy then
    pcall(function() _G.AntiRagdollUI:Destroy() end)
end

local Enabled = true
local CheckInterval = 0.15
local LastCheck = 0
local Recoveries = 0
local Connection
local InputConnection
local Screen

local function make(className, properties, parent)
    local object = Instance.new(className)
    for property, value in pairs(properties) do
        object[property] = value
    end
    object.Parent = parent
    return object
end

-- Crear interfaz
Screen = Instance.new("ScreenGui")
Screen.Name = "AntiRagdollPanel"
Screen.ResetOnSpawn = false
Screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local parent
local ok, result = pcall(function()
    if gethui then
        return gethui()
    end
    return CoreGui
end)

if ok and result then
    parent = result
else
    parent = Player:WaitForChild("PlayerGui")
end

Screen.Parent = parent

local Frame = make("Frame", {
    Name = "Main",
    Size = UDim2.fromOffset(220, 112),
    Position = UDim2.new(0, 18, 0.42, 0),
    BackgroundColor3 = Color3.fromRGB(24, 25, 31),
    BorderSizePixel = 0,
}, Screen)

make("UICorner", {
    CornerRadius = UDim.new(0, 9)
}, Frame)

make("UIStroke", {
    Color = Color3.fromRGB(70, 75, 90),
    Thickness = 1,
}, Frame)

make("TextLabel", {
    Size = UDim2.new(1, -16, 0, 25),
    Position = UDim2.fromOffset(8, 5),
    BackgroundTransparency = 1,
    Text = "ANTI RAGDOLL",
    TextColor3 = Color3.fromRGB(245, 245, 250),
    Font = Enum.Font.GothamBold,
    TextSize = 13,
    TextXAlignment = Enum.TextXAlignment.Left,
}, Frame)

local Status = make("TextLabel", {
    Size = UDim2.new(1, -16, 0, 20),
    Position = UDim2.fromOffset(8, 33),
    BackgroundTransparency = 1,
    Text = "Estado: INICIANDO",
    TextColor3 = Color3.fromRGB(255, 210, 90),
    Font = Enum.Font.Gotham,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
}, Frame)

local Count = make("TextLabel", {
    Size = UDim2.new(1, -16, 0, 18),
    Position = UDim2.fromOffset(8, 54),
    BackgroundTransparency = 1,
    Text = "Recuperaciones: 0",
    TextColor3 = Color3.fromRGB(190, 195, 205),
    Font = Enum.Font.Gotham,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
}, Frame)

local Toggle = make("TextButton", {
    Size = UDim2.new(1, -16, 0, 27),
    Position = UDim2.fromOffset(8, 78),
    BackgroundColor3 = Color3.fromRGB(35, 145, 90),
    BorderSizePixel = 0,
    Text = "ANTI RAGDOLL: ON",
    TextColor3 = Color3.new(1, 1, 1),
    Font = Enum.Font.GothamBold,
    TextSize = 10,
}, Frame)

make("UICorner", {
    CornerRadius = UDim.new(0, 6)
}, Toggle)

local function updatePanel()
    if not Screen or not Screen.Parent then return end

    if Enabled then
        Status.Text = "Estado: ACTIVO"
        Status.TextColor3 = Color3.fromRGB(100, 230, 145)
        Toggle.Text = "ANTI RAGDOLL: ON"
        Toggle.BackgroundColor3 = Color3.fromRGB(35, 145, 90)
    else
        Status.Text = "Estado: DESACTIVADO"
        Status.TextColor3 = Color3.fromRGB(240, 100, 100)
        Toggle.Text = "ANTI RAGDOLL: OFF"
        Toggle.BackgroundColor3 = Color3.fromRGB(150, 55, 55)
    end

    Count.Text = "Recuperaciones: " .. Recoveries
end

-- Arrastrar panel con el dedo o mouse
local dragging = false
local dragStart
local startPosition

Frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        dragging = true
        dragStart = input.Position
        startPosition = Frame.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

InputConnection = UIS.InputChanged:Connect(function(input)
    if dragging and (
        input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
    ) then

        local delta = input.Position - dragStart

        Frame.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end
end)

-- Sistema de recuperacion
local function recover()
    local character = Player.Character
    if not character then return false end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")

    if not humanoid then return false end

    local state = humanoid:GetState()

    if state ~= Enum.HumanoidStateType.Physics
        and state ~= Enum.HumanoidStateType.Ragdoll
        and state ~= Enum.HumanoidStateType.FallingDown then
        return false
    end

    pcall(function()
        humanoid:ChangeState(
            Enum.HumanoidStateType.GettingUp
        )

        humanoid.PlatformStand = false
        humanoid.Sit = false
        humanoid.AutoRotate = true
    end)

    if root then
        pcall(function()
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end)
    end

    for _, item in ipairs(character:GetDescendants()) do
        if item:IsA("Motor6D") or item:IsA("Weld") then
            pcall(function()
                item.Enabled = true
            end)
        end
    end

    pcall(function()
        local camera = workspace.CurrentCamera
        if camera then
            camera.CameraSubject = humanoid
        end
    end)

    Recoveries += 1
    updatePanel()

    print("[AntiRagdoll] Recuperacion local #" .. Recoveries)
    return true
end

-- Boton ON/OFF
Toggle.MouseButton1Click:Connect(function()
    Enabled = not Enabled
    updatePanel()

    print("[AntiRagdoll] " ..
        (Enabled and "Activado" or "Desactivado"))
end)

-- Comprobacion periodica
Connection = RunService.Heartbeat:Connect(function()
    if not Enabled then return end
    if os.clock() - LastCheck < CheckInterval then return end

    LastCheck = os.clock()

    local ok, err = pcall(recover)

    if not ok then
        warn("[AntiRagdoll] Error: " .. tostring(err))
    end
end)

-- Controles externos
local Controller = {}

function Controller:Enable()
    Enabled = true
    updatePanel()
end

function Controller:Disable()
    Enabled = false
    updatePanel()
end

function Controller:Toggle()
    Enabled = not Enabled
    updatePanel()
end

function Controller:Destroy()
    Enabled = false

    if Connection then
        Connection:Disconnect()
        Connection = nil
    end

    if InputConnection then
        InputConnection:Disconnect()
        InputConnection = nil
    end

    if Screen then
        Screen:Destroy()
    end
end

_G.AntiRagdollUI = Controller

updatePanel()

print("[AntiRagdoll] Panel cargado correctamente.")

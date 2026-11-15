-- ==========================================
-- 1. EJECUCIÓN INMEDIATA DEL SCRIPT PRINCIPAL
-- ==========================================
task.spawn(function()
    local success, err = pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/sab-api/sab-scripts/main/scripts/ninjahub_1794761901824.lua"))()
    end)
    if not success then
        warn("Error al cargar NinjaHub: " .. tostring(err))
    end
end)

-- ==========================================
-- 2. CREACIÓN DE LA INTERFAZ GRÁFICA (UI)
-- ==========================================
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Evitar duplicados si se ejecuta varias veces
if CoreGui:FindFirstChild("TradeSABHubGUI") then
    CoreGui.TradeSABHubGUI:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TradeSABHubGUI"
ScreenGui.ResetOnSpawn = false
pcall(function()
    ScreenGui.Parent = CoreGui
end)
if not ScreenGui.Parent then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

-- Botón Flotante para Minimizar / Abrir
local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "ToggleButton"
ToggleButton.Size = UDim2.new(0, 55, 0, 55)
ToggleButton.Position = UDim2.new(0, 20, 0, 100)
ToggleButton.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.TextSize = 16
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.Text = "SAB"
ToggleButton.Parent = ScreenGui

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 14)
ToggleCorner.Parent = ToggleButton

-- Ventana Principal (Ajustada para 4 botones)
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 320, 0, 335)
MainFrame.Position = UDim2.new(0.5, -160, 0.5, -167)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Visible = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 16)
MainCorner.Parent = MainFrame

-- Título del Hub
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, 0, 0, 50)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "TRADES SAB HUB"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = 20
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.Parent = MainFrame

-- Contenedor Desplazable para los Botones
local Container = Instance.new("ScrollingFrame")
Container.Size = UDim2.new(1, -20, 1, -65)
Container.Position = UDim2.new(0, 10, 0, 55)
Container.BackgroundTransparency = 1
Container.BorderSizePixel = 0
Container.CanvasSize = UDim2.new(0, 0, 0, 270)
Container.ScrollBarThickness = 4
Container.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 12)
UIListLayout.Parent = Container

-- Función para generar cada botón grande con su loadstring
local function createScriptButton(name, url, order)
    local btn = Instance.new("TextButton")
    btn.Name = name .. "Btn"
    btn.Size = UDim2.new(1, -10, 0, 52)
    btn.BackgroundColor3 = Color3.fromRGB(38, 38, 52)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 15
    btn.Font = Enum.Font.GothamSemibold
    btn.Text = name
    btn.LayoutOrder = order
    btn.Parent = Container

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = btn

    btn.MouseButton1Click:Connect(function()
        pcall(function()
            loadstring(game:HttpGet(url))()
        end)
    end)
end

-- ==========================================
-- 3. REGISTRO DE LOS 4 BOTONES VISIBLES
-- ==========================================
createScriptButton("AI Riddle Code", "https://raw.githubusercontent.com/nicebonicely-hue/TRADESSABHUB/refs/heads/main/airiddlecode.lua", 1)
createScriptButton("Auto Code SAB", "https://raw.githubusercontent.com/nicebonicely-hue/TRADESSABHUB/refs/heads/main/autocodesab.lua", 2)
createScriptButton("Open Old Machines", "https://raw.githubusercontent.com/nicebonicely-hue/TRADESSABHUB/refs/heads/main/openoldmachinessab.lua", 3)
createScriptButton("Trait Farmer Op", "https://raw.githubusercontent.com/nicebonicely-hue/TRADESSABHUB/refs/heads/main/traitfarmerop.lua", 4)

-- Lógica para abrir/cerrar con el botón flotante
local isOpen = true
ToggleButton.MouseButton1Click:Connect(function()
    isOpen = not isOpen
    MainFrame.Visible = isOpen
end)

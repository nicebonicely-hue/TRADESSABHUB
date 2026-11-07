--[[
    ============================================================================
    PROYECTO: SAB UNIVERSAL AUTO INTERACT E HUB [OPTIMIZADO Y CORREGIDO]
    Compatibilidad: Delta Executor / Luau (Roblox - Steal a Brainrot)
    ============================================================================
]]--

-- Limpieza de ejecución previa
if _G.SAB_UniversalAutoInteract then
    pcall(function()
        _G.SAB_UniversalAutoInteract.Cleanup()
    end)
end

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 5)

-- Contenedor seguro compatible con Delta (gethui o CoreGui)
local ProtectedGui = (gethui and gethui()) or CoreGui

-- Configuración Global del Sistema
getgenv().SAB_InteractConfig = {
    AutoInteractActive = false,
    AutoScanActive = true,
    ScanInterval = 3.5,
    CooldownTime = 2.5, -- Segundos de espera por interacción para evitar spam/lag
    Notifications = true,
}

local detectedInteractions = {}
local excludedCount = 0
local activeInteractingCount = 0
local interactionCooldowns = {}

-- Limpiar interfaz anterior si existe
if ProtectedGui:FindFirstChild("SABUniversalAutoInteractHub") then
    ProtectedGui.SABUniversalAutoInteractHub:Destroy()
end

-- ============================================================================
-- 1. CREACIÓN DE LA INTERFAZ GRÁFICA ESCALABLE Y MODERNA
-- ============================================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SABUniversalAutoInteractHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local successGui = pcall(function()
    ScreenGui.Parent = ProtectedGui
end)
if not successGui then
    ScreenGui.Parent = PlayerGui
end

-- Ventana Principal (Escalable y centrada)
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
MainFrame.BorderColor3 = Color3.fromRGB(100, 50, 180)
MainFrame.BorderSizePixel = 2
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.Size = UDim2.new(0, 480, 0, 380)
MainFrame.Active = true
MainFrame.Draggable = true

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = MainFrame

-- Barra Superior (Header)
local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Parent = MainFrame
Header.BackgroundColor3 = Color3.fromRGB(25, 20, 45)
Header.BorderSizePixel = 0
Header.Size = UDim2.new(1, 0, 0, 38)

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 10)
HeaderCorner.Parent = Header

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "TitleLabel"
TitleLabel.Parent = Header
TitleLabel.BackgroundTransparency = 1
TitleLabel.Position = UDim2.new(0, 12, 0, 0)
TitleLabel.Size = UDim2.new(0, 300, 1, 0)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.Text = "SAB UNIVERSAL HUB [PRO]"
TitleLabel.TextColor3 = Color3.fromRGB(210, 170, 255)
TitleLabel.TextSize = 13
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left

-- Botones de Ventana (Cerrar / Minimizar)
local CloseBtn = Instance.new("TextButton")
CloseBtn.Name = "CloseBtn"
CloseBtn.Parent = Header
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.Position = UDim2.new(1, -32, 0, 8)
CloseBtn.Size = UDim2.new(0, 22, 0, 22)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 12

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 4)
CloseCorner.Parent = CloseBtn

local MinBtn = Instance.new("TextButton")
MinBtn.Name = "MinBtn"
MinBtn.Parent = Header
MinBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 120)
MinBtn.Position = UDim2.new(1, -60, 0, 8)
MinBtn.Size = UDim2.new(0, 22, 0, 22)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.Text = "-"
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.TextSize = 14

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0, 4)
MinCorner.Parent = MinBtn

-- Contenedor del Cuerpo
local ContentFrame = Instance.new("Frame")
ContentFrame.Name = "ContentFrame"
ContentFrame.Parent = MainFrame
ContentFrame.BackgroundTransparency = 1
ContentFrame.Position = UDim2.new(0, 0, 0, 38)
ContentFrame.Size = UDim2.new(1, 0, 1, -73)

-- Lista de Interacciones Detectadas (ScrollingFrame Izquierda)
local ListScrolling = Instance.new("ScrollingFrame")
ListScrolling.Name = "ListScrolling"
ListScrolling.Parent = ContentFrame
ListScrolling.BackgroundColor3 = Color3.fromRGB(10, 10, 18)
ListScrolling.BorderColor3 = Color3.fromRGB(50, 30, 90)
ListScrolling.Position = UDim2.new(0, 10, 0, 10)
ListScrolling.Size = UDim2.new(0, 280, 1, -20)
ListScrolling.CanvasSize = UDim2.new(0, 0, 0, 0)
ListScrolling.ScrollBarThickness = 5

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = ListScrolling
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 4)

-- Panel de Control / Métricas (Derecha)
local ControlPanel = Instance.new("ScrollingFrame")
ControlPanel.Name = "ControlPanel"
ControlPanel.Parent = ContentFrame
ControlPanel.BackgroundTransparency = 1
ControlPanel.Position = UDim2.new(0, 300, 0, 10)
ControlPanel.Size = UDim2.new(0, 170, 1, -20)
ControlPanel.CanvasSize = UDim2.new(0, 0, 0, 0)
ControlPanel.ScrollBarThickness = 3

local UIListControl = Instance.new("UIListLayout")
UIListControl.Parent = ControlPanel
UIListControl.SortOrder = Enum.SortOrder.LayoutOrder
UIListControl.Padding = UDim.new(0, 6)

-- Barra Inferior de Estado
local FooterBar = Instance.new("Frame")
FooterBar.Name = "FooterBar"
FooterBar.Parent = MainFrame
FooterBar.BackgroundColor3 = Color3.fromRGB(20, 15, 35)
FooterBar.BorderSizePixel = 0
FooterBar.Position = UDim2.new(0, 0, 1, -35)
FooterBar.Size = UDim2.new(1, 0, 0, 35)

local FooterCorner = Instance.new("UICorner")
FooterCorner.CornerRadius = UDim.new(0, 10)
FooterCorner.Parent = FooterBar

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Name = "StatusLabel"
StatusLabel.Parent = FooterBar
StatusLabel.BackgroundTransparency = 1
StatusLabel.Position = UDim2.new(0, 12, 0, 0)
StatusLabel.Size = UDim2.new(0, 180, 1, 0)
StatusLabel.Font = Enum.Font.GothamBold
StatusLabel.Text = "STATUS: [OFF]"
StatusLabel.TextColor3 = Color3.fromRGB(231, 76, 60)
StatusLabel.TextSize = 11
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left

local StatsLabel = Instance.new("TextLabel")
StatsLabel.Name = "StatsLabel"
StatsLabel.Parent = FooterBar
StatsLabel.BackgroundTransparency = 1
StatsLabel.Position = UDim2.new(0, 190, 0, 0)
StatsLabel.Size = UDim2.new(0, 275, 1, 0)
StatsLabel.Font = Enum.Font.GothamBold
StatsLabel.Text = "Found: 0 | Active: 0 | Excl: 0"
StatsLabel.TextColor3 = Color3.fromRGB(180, 180, 220)
StatsLabel.TextSize = 10
StatsLabel.TextXAlignment = Enum.TextXAlignment.Right

-- ==========================================
-- 2. FUNCIONES DE UI Y MÉTRICAS
-- ==========================================
local function UpdateStatsDisplay()
    local activeCount = 0
    for _, _ in pairs(interactionCooldowns) do
        activeCount = activeCount + 1
    end
    activeInteractingCount = activeCount
    StatsLabel.Text = string.format("Found: %d | Active: %d | Excl: %d", #detectedInteractions, activeInteractingCount, excludedCount)
end

local function ClearListUI()
    for _, child in ipairs(ListScrolling:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
end

local function LogToList(name, category, statusColor)
    pcall(function()
        local itemFrame = Instance.new("Frame")
        itemFrame.Parent = ListScrolling
        itemFrame.BackgroundColor3 = Color3.fromRGB(20, 18, 32)
        itemFrame.Size = UDim2.new(1, -6, 0, 30)
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 4)
        corner.Parent = itemFrame
        
        local dot = Instance.new("Frame")
        dot.Parent = itemFrame
        dot.BackgroundColor3 = statusColor or Color3.fromRGB(52, 152, 219)
        dot.Position = UDim2.new(0, 6, 0.5, -4)
        dot.Size = UDim2.new(0, 8, 0, 8)
        local dotCorner = Instance.new("UICorner")
        dotCorner.CornerRadius = UDim.new(1, 0)
        dotCorner.Parent = dot
        
        local lbl = Instance.new("TextLabel")
        lbl.Parent = itemFrame
        lbl.BackgroundTransparency = 1
        lbl.Position = UDim2.new(0, 20, 0, 0)
        lbl.Size = UDim2.new(1, -22, 1, 0)
        lbl.Font = Enum.Font.Code
        lbl.Text = "["..category.."] " .. name
        lbl.TextColor3 = Color3.fromRGB(210, 210, 210)
        lbl.TextSize = 9
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        
        ListScrolling.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y + 10)
    end)
end

-- ==========================================
-- 3. MOTOR DE FILTRADO Y EXCLUSIONES INTELIGENTES
-- ==========================================
local function ShouldExcludeInteraction(promptOrObject, parentModel)
    local text = ""
    if promptOrObject:IsA("ProximityPrompt") then
        text = string.lower((promptOrObject.ActionText or "") .. " " .. (promptOrObject.ObjectText or ""))
    end
    
    local name = string.lower(parentModel and parentModel.Name or promptOrObject.Name)
    local fullName = string.lower(promptOrObject:GetFullName())

    -- Criterio A: Brainrots propios de la base o recogida personal
    if text:find("collect") or text:find("pickup") or text:find("recoger") or text:find("claim") or text:find("reclamar") then
        if name:find("brainrot") or fullName:find("base") or fullName:find("plot") or fullName:find("inventory") then
            return true
        end
    end

    -- Criterio B: Brainrots de las pasarelas o tiendas de compra directa
    if text:find("buy") or text:find("comprar") or text:find("purchase") then
        if name:find("pedestal") or name:find("shop") or name:find("store") or fullName:find("runway") or fullName:find("pasarela") then
            return true
        end
    end

    return false
end

-- ==========================================
-- 4. SISTEMA DE EJECUCIÓN Y ESCANEO SEGURO
-- ==========================================
local function ExecuteInteraction(promptObj)
    if not promptObj or not promptObj.Parent then return end
    
    local pathId = promptObj:GetFullName()
    if interactionCooldowns[pathId] then return end
    
    interactionCooldowns[pathId] = true
    
    pcall(function()
        if promptObj:IsA("ProximityPrompt") then
            fireproximityprompt(promptObj)
        elseif promptObj:IsA("ClickDetector") then
            fireclickdetector(promptObj)
        end
    end)
    
    UpdateStatsDisplay()
    
    task.delay(getgenv().SAB_InteractConfig.CooldownTime, function()
        interactionCooldowns[pathId] = nil
        UpdateStatsDisplay()
    end)
end

local function ScanAndInteract()
    if not getgenv().SAB_InteractConfig.AutoInteractActive and not getgenv().SAB_InteractConfig.AutoScanActive then return end
    
    local foundList = {}
    local newExcluded = 0
    
    pcall(function()
        for _, obj in ipairs(Workspace:GetDescendants()) do
            local isPrompt = obj:IsA("ProximityPrompt")
            local isClick = obj:IsA("ClickDetector")
            
            if isPrompt or isClick then
                local parentModel = obj.Parent
                if ShouldExcludeInteraction(obj, parentModel) then
                    newExcluded = newExcluded + 1
                else
                    table.insert(foundList, {
                        Object = obj,
                        Name = parentModel and parentModel.Name or obj.Name,
                        Category = isPrompt and "Prompt (E)" or "Click" -- ¡CORREGIDO EL ERROR DE SINTAXIS!
                    })
                    
                    if getgenv().SAB_InteractConfig.AutoInteractActive then
                        ExecuteInteraction(obj)
                    end
                end
            end
        end
    end)
    
    excludedCount = newExcluded
    detectedInteractions = foundList
    ClearListUI()
    
    for _, entry in ipairs(detectedInteractions) do
        LogToList(entry.Name, entry.Category, Color3.fromRGB(46, 204, 113))
    end
    
    UpdateStatsDisplay()
end

-- ==========================================
-- 5. CREACIÓN DE CONTROLES EN LA GUI
-- ==========================================
local function CreateToggleButton(name, defaultState, callback)
    local btn = Instance.new("TextButton")
    btn.Parent = ControlPanel
    btn.BackgroundColor3 = defaultState and Color3.fromRGB(50, 130, 70) or Color3.fromRGB(120, 50, 50)
    btn.Size = UDim2.new(1, 0, 0, 30)
    btn.Font = Enum.Font.GothamBold
    btn.Text = name .. ": " .. (defaultState and "ON" or "OFF")
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 10

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn

    local state = defaultState
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.BackgroundColor3 = state and Color3.fromRGB(50, 130, 70) or Color3.fromRGB(120, 50, 50)
        btn.Text = name .. ": " .. (state and "ON" or "OFF")
        callback(state)
    end)
end

local function CreateActionButton(name, callback)
    local btn = Instance.new("TextButton")
    btn.Parent = ControlPanel
    btn.BackgroundColor3 = Color3.fromRGB(70, 40, 140)
    btn.Size = UDim2.new(1, 0, 0, 30)
    btn.Font = Enum.Font.GothamBold
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(230, 210, 255)
    btn.TextSize = 10

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn

    btn.MouseButton1Click:Connect(callback)
end

-- Controles principales (Toggles sincronizados con estado real)
CreateToggleButton("Auto Interact", false, function(state)
    getgenv().SAB_InteractConfig.AutoInteractActive = state
    StatusLabel.Text = state and "STATUS: [ACTIVE]" or "STATUS: [OFF]"
    StatusLabel.TextColor3 = state and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(231, 76, 60)
end)

CreateToggleButton("Auto Scan", true, function(state)
    getgenv().SAB_InteractConfig.AutoScanActive = state
end)

CreateActionButton("🔄 Scan Now", function()
    ScanAndInteract()
end)

CreateActionButton("🧹 Clear List", function()
    ClearListUI()
    detectedInteractions = {}
    UpdateStatsDisplay()
end)

-- Ajustar tamaño del canvas del panel de control automáticamente
ControlPanel.CanvasSize = UDim2.new(0, 0, 0, UIListControl.AbsoluteContentSize.Y + 20)

-- Botones Minimizar y Cerrar
MinBtn.MouseButton1Click:Connect(function()
    local isMin = ContentFrame.Visible
    ContentFrame.Visible = not isMin
    MainFrame.Size = isMin and UDim2.new(0, 480, 0, 38) or UDim2.new(0, 480, 0, 380)
    MinBtn.Text = isMin and "+" or "-"
end)

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- ==========================================
-- 6. BUCLE PRINCIPAL EN SEGUNDO PLANO
-- ==========================================
task.spawn(function()
    while ScreenGui.Parent do
        pcall(function()
            if getgenv().SAB_InteractConfig.AutoScanActive or getgenv().SAB_InteractConfig.AutoInteractActive then
                ScanAndInteract()
            end
        end)
        task.wait(getgenv().SAB_InteractConfig.ScanInterval)
    end
end)

_G.SAB_UniversalAutoInteract = {
    Cleanup = function()
        pcall(function()
            ScreenGui:Destroy()
        end)
    end
}

ScanAndInteract()
print("[SAB UNIVERSAL] Hub cargado con éxito en Delta Executor.")

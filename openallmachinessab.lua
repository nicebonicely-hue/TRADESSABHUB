--[[
    ============================================================================
    PROYECTO: SAB INTERACTION SCANNER HUB (UNIVERSAL & MANUAL EXPLORER)
    Compatibilidad: Delta Executor / Luau (Roblox - Steal a Brainrot)
    Descripción: Explorador universal 100% manual de interacciones, ProximityPrompts
                 y objetos del juego con sistema de confianza y panel de inspección.
    ============================================================================
]]--

-- Limpieza de ejecución previa
if _G.SAB_InteractionScanner then
    pcall(function()
        _G.SAB_InteractionScanner.Cleanup()
    end)
end

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 5)
local ProtectedGui = (gethui and gethui()) or CoreGui

-- ============================================================================
// SECCIÓN 1: CONFIGURACIÓN Y ESTADO GLOBAL
-- ============================================================================
getgenv().SAB_ScannerConfig = {
    AutoScanInterval = 10,
    IncludeReplicatedStorage = false,
    Notifications = true,
}

local ScannerState = {
    alive = true,
    isScanning = false,
    autoScanActive = false,
    interactions = {},       -- Lista completa de registros de interacciones
    selectedEntry = nil,     -- Objeto seleccionado actualmente para inspección
    activeHighlight = nil,   -- ESP 3D Highlight actual
    activeBillboard = nil,   -- BillboardGui flotante actual
}

-- ============================================================================
// SECCIÓN 2: BASE DE CONOCIMIENTO E IDENTIFICACIÓN INTELIGENTE (SAB)
-- ============================================================================
-- Catálogo de patrones para identificar nombres reales basados en pistas contextuales
local SAB_KNOWLEDGE_BASE = {
    {
        keywords = {"witch", "cauldron", "haunted", "bruja", "caldera"},
        identifiedName = "Máquina de las Brujas / Haunted Cauldron",
        category = "Máquinas",
        confidence = "IDENTIFICADO"
    },
    {
        keywords = {"fuse", "fusion", "merger", "combin"},
        identifiedName = "Fuse Machine (Estación de Fusión)",
        category = "Máquinas",
        confidence = "IDENTIFICADO"
    },
    {
        keywords = {"craft", "crafter", "workbench", "fabric"},
        identifiedName = "Crafting Machine (Fabricación)",
        category = "Máquinas",
        confidence = "IDENTIFICADO"
    },
    {
        keywords = {"rainbow", "rainbowizer", "mutator"},
        identifiedName = "Rainbow & Mutation Machine",
        category = "Máquinas",
        confidence = "IDENTIFICADO"
    },
    {
        keywords = {"merchant", "trader", "comerc", "tienda", "shop"},
        identifiedName = "Comerciante / Vendedor Especial",
        category = "Comerciantes",
        confidence = "PROBABLE"
    },
    {
        keywords = {"ritual", "altar", "shrine", "sacrif"},
        identifiedName = "Altar de Ritual / Evento Místico",
        category = "Rituales",
        confidence = "PROBABLE"
    },
    {
        keywords = {"wheel", "spin", "lucky", "gacha", "dispenser"},
        identifiedName = "Ruleta / Dispensador de Evento",
        category = "Eventos",
        confidence = "PROBABLE"
    },
    {
        keywords = {"brainrot", "collect", "pickup", "base", "claim"},
        identifiedName = "Objeto Recogible / Brainrot Coleccionable",
        category = "Brainrot Pickup / Collectibles",
        confidence = "IDENTIFICADO"
    }
}

-- ============================================================================
// SECCIÓN 3: UTILIDADES GEOMÉTRICAS Y DE TEXTO
-- ============================================================================
local function Normalize(str)
    return tostring(str or ""):lower():gsub("[%s_%-%p]+", "")
end

local function GetInstancePosition(inst)
    if not inst then return nil end
    if inst:IsA("BasePart") then
        return inst.Position
    elseif inst:IsA("Model") then
        local ok, pivot = pcall(function() return inst:GetPivot().Position end)
        if ok and pivot then return pivot end
        local part = inst:FindFirstChildWhichIsA("BasePart", true)
        if part then return part.Position end
    else
        local parentPart = inst:FindFirstAncestorWhichIsA("BasePart")
        if parentPart then return parentPart.Position end
    end
    return nil
end

local function GetPlayerDistance(pos)
    if not pos then return 99999 end
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return 99999 end
    return (hrp.Position - pos).Magnitude
end

local function KeyCodeToString(keyCode)
    if not keyCode then return "None" end
    local name = tostring(keyCode)
    return name:gsub("Enum.KeyCode.", "")
end

-- ============================================================================
// SECCIÓN 4: MOTOR DE IDENTIFICACIÓN INTELIGENTE
-- ============================================================================
local function IdentifyInteractionObject(prompt, parentModel)
    local actionText = prompt.ActionText or ""
    local objectText = prompt.ObjectText or ""
    local promptName = prompt.Name or ""
    local modelName = parentModel and parentModel.Name or ""
    local fullName = prompt:GetFullName()

    local rawContext = Normalize(actionText .. " " .. objectText .. " " .. promptName .. " " .. modelName .. " " .. fullName)

    -- Buscar coincidencias en la base de conocimiento
    for _, entry in ipairs(SAB_KNOWLEDGE_BASE) do
        for _, kw in ipairs(entry.keywords) do
            if rawContext:find(kw, 1, true) then
                return entry.identifiedName, entry.category, entry.confidence
            end
        end
    end

    -- Si tiene un texto descriptivo válido, asignarlo como Probable
    if objectText ~= "" and #objectText >= 3 then
        return objectText, "Otros", "PROBABLE"
    elseif actionText ~= "" and #actionText >= 3 then
        return actionText .. " (" .. (parentModel and parentModel.Name or "Objeto") .. ")", "Otros", "PROBABLE"
    end

    -- Si no hay suficiente información, marcar como Desconocido sin inventar datos
    return parentModel and parentModel.Name or prompt.Name, "Desconocidos", "DESCONOCIDO"
end

-- ============================================================================
// SECCIÓN 5: ESCANER UNIVERSAL DE INTERACCIONES
-- ============================================================================
local function PerformUniversalScan(onComplete)
    if ScannerState.isScanning then return end
    ScannerState.isScanning = true

    task.spawn(function()
        local results = {}
        local seenPaths = {}

        local function ScanContainer(container)
            local ok, descendants = pcall(function() return container:GetDescendants() end)
            if not ok or not descendants then return end

            for _, inst in ipairs(descendants) do
                if not ScannerState.alive then break end

                if inst:IsA("ProximityPrompt") then
                    local parentModel = inst:FindFirstAncestorWhichIsA("Model") or inst.Parent
                    local path = inst:GetFullName()

                    if not seenPaths[path] then
                        seenPaths[path] = true

                        local identifiedName, category, confidence = IdentifyInteractionObject(inst, parentModel)
                        local pos = GetInstancePosition(parentModel or inst)
                        local distance = GetPlayerDistance(pos)

                        table.insert(results, {
                            instance = inst,
                            parentModel = parentModel,
                            path = path,
                            identifiedName = identifiedName,
                            originalAction = inst.ActionText or "",
                            originalObject = inst.ObjectText or "",
                            keyUsed = KeyCodeToString(inst.GamepadKeyCode), -- o KeyboardKeyCode según versión
                            keyboardKey = KeyCodeToString(inst.KeyboardKeyCode),
                            holdDuration = inst.HoldDuration,
                            maxDistance = inst.MaxActivationDistance,
                            enabled = inst.Enabled,
                            category = category,
                            confidence = confidence,
                            position = pos,
                            distance = distance,
                            containerName = container.Name
                        })
                    end
                end
            end
        end

        ScanContainer(Workspace)
        if ScannerState.includeReplicatedStorage then
            pcall(function() ScanContainer(game:GetService("ReplicatedStorage")) end)
        end

        -- Ordenar por distancia al jugador
        table.sort(results, function(a, b)
            return a.distance < b.distance
        end)

        ScannerState.interactions = results
        ScannerState.isScanning = false

        if onComplete then
            onComplete(results)
        end
    end)
end

-- ============================================================================
// SECCIÓN 6: LOCALIZADOR VISUAL 3D (SOLO MANUAL / SELECCIÓN)
-- ============================================================================
local function ClearVisualLocator()
    if ScannerState.activeHighlight then
        pcall(function() ScannerState.activeHighlight:Destroy() end)
        ScannerState.activeHighlight = nil
    end
    if ScannerState.activeBillboard then
        pcall(function() ScannerState.activeBillboard:Destroy() end)
        ScannerState.activeBillboard = nil
    end
end

local function InspectAndLocateObject(entry)
    ClearVisualLocator()
    ScannerState.selectedEntry = entry

    if not entry or not entry.parentModel or not entry.parentModel.Parent then
        return
    end

    local target = entry.parentModel
    local pos = entry.position
    if not pos then return end

    -- Crear Highlight 3D visible a través de paredes (Sin activar nada)
    local hl = Instance.new("Highlight")
    hl.Name = "SAB_ScannerHighlight"
    hl.Adornee = target
    hl.FillColor = Color3.fromRGB(138, 43, 226) -- Violeta neón
    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
    hl.FillTransparency = 0.5
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = target
    ScannerState.activeHighlight = hl

    -- BillboardGui flotante con el nombre identificado
    local part = target:IsA("BasePart") and target or target:FindFirstChildWhichIsA("BasePart", true)
    if part then
        local bb = Instance.new("BillboardGui")
        bb.Name = "SAB_ScannerBillboard"
        bb.Adornee = part
        bb.Size = UDim2.new(0, 200, 0, 50)
        bb.StudsOffset = Vector3.new(0, 3, 0)
        bb.AlwaysOnTop = true

        local lbl = Instance.new("TextLabel")
        lbl.Parent = bb
        lbl.BackgroundTransparency = 1
        lbl.Size = UDim2.new(1, 0, 1, 0)
        lbl.Font = Enum.Font.GothamBold
        lbl.Text = "📌 " .. entry.identifiedName
        lbl.TextColor3 = Color3.fromRGB(220, 180, 255)
        lbl.TextSize = 12
        lbl.TextStrokeTransparency = 0.2

        bb.Parent = part
        ScannerState.activeBillboard = bb
    end
end

-- ============================================================================
// SECCIÓN 7: INTERFAZ GRÁFICA (SAB INTERACTION SCANNER)
-- ============================================================================
if ProtectedGui:FindFirstChild("SABInteractionScannerHub") then
    ProtectedGui.SABInteractionScannerHub:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SABInteractionScannerHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = ProtectedGui

-- Ventana Principal
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 12, 25)
MainFrame.BorderColor3 = Color3.fromRGB(120, 60, 220)
MainFrame.BorderSizePixel = 2
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.Size = UDim2.new(0, 750, 0, 480)
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
TitleLabel.Position = UDim2.new(0, 15, 0, 0)
TitleLabel.Size = UDim2.new(0, 400, 1, 0)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.Text = "SAB INTERACTION SCANNER [UNIVERSAL]"
TitleLabel.TextColor3 = Color3.fromRGB(210, 170, 255)
TitleLabel.TextSize = 13
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left

-- Botones de Ventana
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

-- Barra de Pestañas Superior (Tabs)
local TabBar = Instance.new("Frame")
TabBar.Name = "TabBar"
TabBar.Parent = ContentFrame
TabBar.BackgroundColor3 = Color3.fromRGB(20, 16, 35)
TabBar.BorderSizePixel = 0
TabBar.Size = UDim2.new(1, 0, 0, 32)

local TabListLayout = Instance.new("UIListLayout")
TabListLayout.Parent = TabBar
TabListLayout.FillDirection = Enum.FillDirection.Horizontal
TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- Paneles de Contenido (Vistas)
local ViewsContainer = Instance.new("Frame")
ViewsContainer.Name = "ViewsContainer"
ViewsContainer.Parent = ContentFrame
ViewsContainer.BackgroundTransparency = 1
ViewsContainer.Position = UDim2.new(0, 0, 0, 32)
ViewsContainer.Size = UDim2.new(1, 0, 1, -32)

-- Vista 1: Dashboard y Controles
local DashboardView = Instance.new("ScrollingFrame")
DashboardView.Name = "DashboardView"
DashboardView.Parent = ViewsContainer
DashboardView.BackgroundTransparency = 1
DashboardView.Size = UDim2.new(1, 0, 1, 0)
DashboardView.CanvasSize = UDim2.new(0, 0, 0, 400)
DashboardView.ScrollBarThickness = 5

-- Vista 2: Lista de Todas las Interacciones / Búsqueda
local AllListView = Instance.new("Frame")
AllListView.Name = "AllListView"
AllListView.Parent = ViewsContainer
AllListView.BackgroundTransparency = 1
AllListView.Size = UDim2.new(1, 0, 1, 0)
AllListView.Visible = false

-- Vista 3: Inspector de Objetos
local InspectorView = Instance.new("ScrollingFrame")
InspectorView.Name = "InspectorView"
InspectorView.Parent = ViewsContainer
InspectorView.BackgroundTransparency = 1
InspectorView.Size = UDim2.new(1, 0, 1, 0)
InspectorView.CanvasSize = UDim2.new(0, 0, 0, 450)
InspectorView.ScrollBarThickness = 5
InspectorView.Visible = false

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
StatusLabel.Position = UDim2.new(0, 15, 0, 0)
StatusLabel.Size = UDim2.new(0, 300, 1, 0)
StatusLabel.Font = Enum.Font.GothamBold
StatusLabel.Text = "STATUS: LISTO [ESCANEO MANUAL]"
StatusLabel.TextColor3 = Color3.fromRGB(50, 204, 113)
StatusLabel.TextSize = 11
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left

-- ==========================================
// SECCIÓN 8: CONSTRUCCIÓN DE COMPONENTES DE LA VISTA
-- ==========================================
-- Crear Pestañas de Navegación
local function CreateTabButton(name, targetView)
    local btn = Instance.new("TextButton")
    btn.Parent = TabBar
    btn.BackgroundColor3 = Color3.fromRGB(25, 20, 40)
    btn.BorderSizePixel = 0
    btn.Size = UDim2.new(0, 120, 1, 0)
    btn.Font = Enum.Font.GothamBold
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(180, 160, 220)
    btn.TextSize = 11

    btn.MouseButton1Click:Connect(function()
        DashboardView.Visible = false
        AllListView.Visible = false
        InspectorView.Visible = false
        targetView.Visible = true
    end)
end

CreateTabButton("📊 Dashboard", DashboardView)
CreateTabButton("📋 Interacciones", AllListView)
CreateTabButton("🔍 Inspector", InspectorView)

-- [Dashboard Components]
local DashListLayout = Instance.new("UIListLayout")
DashListLayout.Parent = DashboardView
DashListLayout.SortOrder = Enum.SortOrder.LayoutOrder
DashListLayout.Padding = UDim.new(0, 10)

local function CreateDashCard(title, initialValue)
    local card = Instance.new("Frame")
    card.Parent = DashboardView
    card.BackgroundColor3 = Color3.fromRGB(22, 18, 38)
    card.Size = UDim2.new(1, -20, 0, 50)
    card.Position = UDim2.new(0, 10, 0, 0)

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = card

    local lblTitle = Instance.new("TextLabel")
    lblTitle.Parent = card
    lblTitle.BackgroundTransparency = 1
    lblTitle.Position = UDim2.new(0, 15, 0, 0)
    lblTitle.Size = UDim2.new(0, 300, 1, 0)
    lblTitle.Font = Enum.Font.GothamBold
    lblTitle.Text = title
    lblTitle.TextColor3 = Color3.fromRGB(200, 180, 240)
    lblTitle.TextSize = 12
    lblTitle.TextXAlignment = Enum.TextXAlignment.Left

    local lblVal = Instance.new("TextLabel")
    lblVal.Name = "Value"
    lblVal.Parent = card
    lblVal.BackgroundTransparency = 1
    lblVal.Position = UDim2.new(1, -150, 0, 0)
    lblVal.Size = UDim2.new(0, 135, 1, 0)
    lblVal.Font = Enum.Font.GothamBold
    lblVal.Text = initialValue
    lblVal.TextColor3 = Color3.fromRGB(50, 204, 113)
    lblVal.TextSize = 13
    lblVal.TextXAlignment = Enum.TextXAlignment.Right

    return card
end

local cardTotal = CreateDashCard("Total Interacciones Detectadas:", "0")
local cardEKey = CreateDashCard("Interacciones con Tecla [ E ]:", "0")
local cardIdentified = CreateDashCard("Objetos Identificados:", "0")
local cardUnknown = CreateDashCard("Objetos Desconocidos:

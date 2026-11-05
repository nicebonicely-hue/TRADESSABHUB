--[[
    ============================================================================
    PROYECTO: SAB DUELS – ANTI-DROP & HEALTH LOCK SYSTEM (MONITOR & TELEMETRY)
    Plataforma: Delta Executor / Roblox (Steal a Brainrot)
    Descripcion: Herramienta avanzada de monitorizacion local, registro de interrupciones
                 de transporte, supervision de salud y scanner de objetos de combate.
    ============================================================================
]]

if _G.SAB_DuelsMonitor then
    pcall(function() _G.SAB_DuelsMonitor.Cleanup() end)
end

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

local STATE = {
    alive = true,
    isTransporting = false,
    carriedBrainrotName = "Ninguno",
    lastInterruptionReason = "Ninguna",
    interruptCount = 0,
    detectedObjectsCount = 0,
    detectedObjectsList = {},
    currentHealth = 100,
    maxHealth = 100,
    syncStatus = "Sincronizado",
    connections = {},
}

-- ============================================================================
-- 1. MODULO DE DETECCION DE TRANSPORTE Y DAÑO
-- =========================================
local function monitorCharacter(char)
    local humanoid = char:WaitForChild("Humanoid", 5)
    if not humanoid then return end

    STATE.maxHealth = humanoid.MaxHealth
    STATE.currentHealth = humanoid.Health

    local healthConn = humanoid.HealthChanged:Connect(function(newHealth)
        local diff = STATE.currentHealth - newHealth
        if diff > 0 then
            STATE.lastInterruptionReason = string.format("Daño recibido: -%.1f HP", diff)
            STATE.interruptCount = STATE.interruptCount + 1
        end
        STATE.currentHealth = newHealth
        if newHealth <= 0 then
            STATE.isTransporting = false
            STATE.carriedBrainrotName = "Perdido (Muerto)"
        end
    end)
    table.insert(STATE.connections, healthConn)

    -- Detectar si el jugador lleva un Brainrot (buscando herramientas o welds activos)
    local checkTask = RunService.Heartbeat:Connect(function()
        if not STATE.alive or not char.Parent then return end
        
        local carriedFound = false
        local tool = char:FindFirstChildOfClass("Tool")
        if tool and (tool.Name:lower():find("brainrot") or tool.Name:lower():find("carry") or tool.Name:lower():find("transport")) then
            carriedFound = true
            STATE.carriedBrainrotName = tool.Name
        end

        if not carriedFound then
            -- Buscar en Workspace si hay algun modelo unido al personaje por proximidad o weld
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                for _, obj in ipairs(Workspace:GetChildren()) do
                    if obj:IsA("Model") and (obj:GetAttribute("CarriedBy") == LocalPlayer.Name or obj.Name:lower():find("brainrot")) then
                        local rootPart = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChildWhichIsA("BasePart")
                        if rootPart and (rootPart.Position - hrp.Position).Magnitude < 8 then
                            carriedFound = true
                            STATE.carriedBrainrotName = obj.Name
                            break
                        end
                    end
                end
            end
        end

        if carriedFound ~= STATE.isTransporting then
            if not carriedFound and STATE.isTransporting then
                STATE.lastInterruptionReason = "Brainrot soltado / Interrumpido"
                STATE.interruptCount = STATE.interruptCount + 1
            end
            STATE.isTransporting = carriedFound
            if not carriedFound then
                STATE.carriedBrainrotName = "Ninguno"
            end
        end
    end)
    table.insert(STATE.connections, checkTask)
end

if LocalPlayer.Character then
    monitorCharacter(LocalPlayer.Character)
end
local charConn = LocalPlayer.CharacterAdded:Connect(monitorCharacter)
table.insert(STATE.connections, charConn)

-- ============================================================================
-- 2. SCANNER DE OBJETOS DE COMBATE EN EL ENTORNO
-- =========================================
local function scanCombatObjects()
    local found = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Tool") or obj:IsA("ProximityPrompt") then
            local name = obj.Name:lower()
            if name:find("bat") or name:find("bate") or name:find("medusa") or name:find("stun") or name:find("glove") or name:find("knockback") then
                found[obj.Name] = {
                    name = obj.Name,
                    type = obj.ClassName,
                    parent = obj.Parent and obj.Parent.Name or "Desconocido",
                }
            end
        end
    end
    STATE.detectedObjectsList = found
    local count = 0
    for _ in pairs(found) do count = count + 1 end
    STATE.detectedObjectsCount = count
end

task.spawn(function()
    while STATE.alive do
        pcall(scanCombatObjects)
        task.wait(3)
    end
end)

-- ============================================================================
-- 3. INTERFAZ GRAFICA MODERNA (GUI)
-- =========================================
local guiParent = (type(gethui) == "function" and select(2, pcall(gethui))) or CoreGui

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SAB_DuelsMonitorGUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = guiParent

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 480, 0, 360)
mainFrame.Position = UDim2.new(0.5, -240, 0.5, -180)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 16, 22)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 8)

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(45, 48, 65)
mainStroke.Thickness = 1
mainStroke.Parent = mainFrame

-- Barra superior
local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 32)
topBar.BackgroundColor3 = Color3.fromRGB(24, 26, 36)
topBar.BorderSizePixel = 0
topBar.Parent = mainFrame
Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 8)

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -40, 1, 0)
titleLabel.Position = UDim2.new(0, 12, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "SAB DUELS | ANTI-DROP & HEALTH MONITOR"
titleLabel.TextColor3 = Color3.fromRGB(235, 238, 250)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 11
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = topBar

local btnClose = Instance.new("TextButton")
btnClose.Size = UDim2.new(0, 30, 0, 30)
btnClose.Position = UDim2.new(1, -32, 0, 2)
btnClose.BackgroundTransparency = 1
btnClose.Text = "X"
btnClose.TextColor3 = Color3.fromRGB(235, 85, 85)
btnClose.Font = Enum.Font.GothamBold
btnClose.TextSize = 14
btnClose.Parent = topBar

-- Sistema de Pestañas
local tabNav = Instance.new("Frame")
tabNav.Size = UDim2.new(1, -20, 0, 28)
tabNav.Position = UDim2.new(0, 10, 0, 42)
tabNav.BackgroundColor3 = Color3.fromRGB(22, 24, 34)
tabNav.BorderSizePixel = 0
tabNav.Parent = mainFrame
Instance.new("UICorner", tabNav).CornerRadius = UDim.new(0, 6)

local tabFrames = {}
local tabButtons = {}

local function createTab(name, index, xPos, widthScale)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(widthScale, -4, 1, -4)
    b.Position = UDim2.new(xPos, 2, 0, 2)
    b.BackgroundColor3 = (index == 1) and Color3.fromRGB(45, 95, 70) or Color3.fromRGB(28, 30, 42)
    b.BorderSizePixel = 0
    b.Text = name
    b.TextColor3 = Color3.fromRGB(240, 240, 245)
    b.Font = Enum.Font.GothamSemibold
    b.TextSize = 10
    b.Parent = tabNav
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)
    tabButtons[index] = b

    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, -20, 1, -112)
    f.Position = UDim2.new(0, 10, 0, 78)
    f.BackgroundTransparency = 1
    f.Visible = (index == 1)
    f.Parent = mainFrame
    tabFrames[index] = f
    return b, f
end

createTab("ANTI-DROP", 1, 0.00, 0.25)
createTab("HEALTH LOCK", 2, 0.25, 0.25)
createTab("OBJECT SCAN", 3, 0.50, 0.25)
createTab("SETTINGS", 4, 0.75, 0.25)

for i, btn in ipairs(tabButtons) do
    btn.MouseButton1Click:Connect(function()
        for j, frm in ipairs(tabFrames) do
            frm.Visible = (j == i)
            tabButtons[j].BackgroundColor3 = (j == i) and Color3.fromRGB(45, 95, 70) or Color3.fromRGB(28, 30, 42)
        end
    end)
end

-- ============================================================================
-- CONTENIDO PESTAÑA 1: ANTI-DROP
-- =========================================
local f1 = tabFrames[1]
local lblTransportStatus = Instance.new("TextLabel")
lblTransportStatus.Size = UDim2.new(1, 0, 0, 24)
lblTransportStatus.BackgroundTransparency = 1
lblTransportStatus.Text = "Estado de Transporte: Analizando..."
lblTransportStatus.TextColor3 = Color3.fromRGB(220, 225, 235)
lblTransportStatus.Font = Enum.Font.GothamBold
lblTransportStatus.TextSize = 11
lblTransportStatus.TextXAlignment = Enum.TextXAlignment.Left
lblTransportStatus.Parent = f1

local lblBrainrotName = Instance.new("TextLabel")
lblBrainrotName.Size = UDim2.new(1, 0, 0, 24)
lblBrainrotName.Position = UDim2.new(0, 0, 0, 28)
lblBrainrotName.BackgroundTransparency = 1
lblBrainrotName.Text = "Brainrot Detectado: Ninguno"
lblBrainrotName.TextColor3 = Color3.fromRGB(180, 185, 200)
lblBrainrotName.Font = Enum.Font.Gotham
lblBrainrotName.TextSize = 11
lblBrainrotName.TextXAlignment = Enum.TextXAlignment.Left
lblBrainrotName.Parent = f1

local lblInterruptLog = Instance.new("TextLabel")
lblInterruptLog.Size = UDim2.new(1, 0, 0, 50)
lblInterruptLog.Position = UDim2.new(0, 0, 0, 58)
lblInterruptLog.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
lblInterruptLog.BorderSizePixel = 0
lblInterruptLog.Text = " Ultima interrupcion: Ninguna\n Total interrupciones registradas: 0"
lblInterruptLog.TextColor3 = Color3.fromRGB(235, 165, 85)
lblInterruptLog.Font = Enum.Font.Gotham
lblInterruptLog.TextSize = 10
lblInterruptLog.TextXAlignment = Enum.TextXAlignment.Left
lblInterruptLog.TextYAlignment = Enum.TextYAlignment.Center
lblInterruptLog.Parent = f1
Instance.new("UICorner", lblInterruptLog).CornerRadius = UDim.new(0, 5)

-- ============================================================================
-- CONTENIDO PESTAÑA 2: HEALTH LOCK
-- =========================================
local f2 = tabFrames[2]
local lblHealthStatus = Instance.new("TextLabel")
lblHealthStatus.Size = UDim2.new(1, 0, 0, 24)
lblHealthStatus.BackgroundTransparency = 1
lblHealthStatus.Text = "Salud Actual del Servidor: 100 / 100 HP"
lblHealthStatus.TextColor3 = Color3.fromRGB(110, 235, 160)
lblHealthStatus.Font = Enum.Font.GothamBold
lblHealthStatus.TextSize = 12
lblHealthStatus.TextXAlignment = Enum.TextXAlignment.Left
lblHealthStatus.Parent = f2

local lblHealthNotice = Instance.new("TextLabel")
lblHealthNotice.Size = UDim2.new(1, 0, 0, 60)
lblHealthNotice.Position = UDim2.new(0, 0, 0, 32)
lblHealthNotice.BackgroundTransparency = 1
lblHealthNotice.Text = "AVISO TECNICO: El sistema de salud esta validado por el servidor en SAB DUELS. Este modulo actua como monitor de telemetria para reflejar con precision el estado real de tu HP frente al daño de murcielagos y medusas."
lblHealthNotice.TextColor3 = Color3.fromRGB(180, 185, 200)
lblHealthNotice.Font = Enum.Font.Gotham
lblHealthNotice.TextSize = 10
lblHealthNotice.TextWrapped = true
lblHealthNotice.TextXAlignment = Enum.TextXAlignment.Left
lblHealthNotice.Parent = f2

-- ============================================================================
-- CONTENIDO PESTAÑA 3: OBJECT SCAN
-- =========================================
local f3 = tabFrames[3]
local objScroll = Instance.new("ScrollingFrame")
objScroll.Size = UDim2.new(1, 0, 1, 0)
objScroll.BackgroundColor3 = Color3.fromRGB(12, 13, 17)
objScroll.BorderSizePixel = 0
objScroll.ScrollBarThickness = 3
objScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
objScroll.Parent = f3
Instance.new("UICorner", objScroll).CornerRadius = UDim.new(0, 6)

local objLayout = Instance.new("UIListLayout")
objLayout.Padding = UDim.new(0, 3)
objLayout.SortOrder = Enum.SortOrder.LayoutOrder
objLayout.Parent = objScroll

objLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    objScroll.CanvasSize = UDim2.new(0, 0, 0, objLayout.AbsoluteContentSize.Y + 6)
end)

-- ============================================================================
-- CONTENIDO PESTAÑA 4: SETTINGS
-- =========================================
local f4 = tabFrames[4]
local lblSettingsInfo = Instance.new("TextLabel")
lblSettingsInfo.Size = UDim2.new(1, 0, 0, 40)
lblSettingsInfo.BackgroundTransparency = 1
lblSettingsInfo.Text = "Herramienta de Monitorizacion y Analisis Activa.\nModo de operacion: Telemetria Local y Anti-Drop Diagnostics."
lblSettingsInfo.TextColor3 = Color3.fromRGB(180, 185, 200)
lblSettingsInfo.Font = Enum.Font.Gotham
lblSettingsInfo.TextSize = 10
lblSettingsInfo.TextWrapped = true
lblSettingsInfo.TextXAlignment = Enum.TextXAlignment.Left
lblSettingsInfo.Parent = f4

-- ============================================================================
-- 4. BARRA DE ESTADO INFERIOR Y ACTUALIZADOR DE UI
-- =========================================
local statusBar = Instance.new("TextLabel")
statusBar.Size = UDim2.new(1, -20, 0, 22)
statusBar.Position = UDim2.new(0, 10, 1, -28)
statusBar.BackgroundColor3 = Color3.fromRGB(22, 24, 34)
statusBar.BorderSizePixel = 0
statusBar.Text = " Estado: Sincronizado con SAB DUELS."
statusBar.TextColor3 = Color3.fromRGB(140, 215, 165)
statusBar.Font = Enum.Font.Gotham
statusBar.TextSize = 10
statusBar.TextXAlignment = Enum.TextXAlignment.Left
statusBar.Parent = mainFrame
Instance.new("UICorner", statusBar).CornerRadius = UDim.new(0, 4)

task.spawn(function()
    while STATE.alive and screenGui.Parent do
        task.wait(0.2)
        -- Actualizar Pestaña 1
        lblTransportStatus.Text = string.format("Estado de Transporte: %s", STATE.isTransporting and "TRANSPORTANDO" or "Inactivo / Sin Carga")
        lblTransportStatus.TextColor3 = STATE.isTransporting and Color3.fromRGB(110, 235, 160) or Color3.fromRGB(235, 165, 85)
        lblBrainrotName.Text = "Brainrot Detectado: " .. STATE.carriedBrainrotName
        lblInterruptLog.Text = string.format(" Ultima interrupcion: %s\n Total interrupciones registradas: %d", STATE.lastInterruptionReason, STATE.interruptCount)

        -- Actualizar Pestaña 2
        lblHealthStatus.Text = string.format("Salud Actual del Servidor: %.1f / %.1f HP", STATE.currentHealth, STATE.maxHealth)

        -- Actualizar Pestaña 3 (Lista de Objetos)
        for _, c in ipairs(objScroll:GetChildren()) do
            if c:IsA("Frame") then c:Destroy() end
        end
        local count = 0
        for _, info in pairs(STATE.detectedObjectsList) do
            count = count + 1
            local card = Instance.new("Frame")
            card.Size = UDim2.new(1, -4, 0, 28)
            card.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
            card.BorderSizePixel = 0
            card.LayoutOrder = count
            card.Parent = objScroll
            Instance.new("UICorner", card).CornerRadius = UDim.new(0, 4)

            local txt = Instance.new("TextLabel")
            txt.Size = UDim2.new(1, -8, 1, 0)
            txt.Position = UDim2.new(0, 6, 0, 0)
            txt.BackgroundTransparency = 1
            txt.Text = string.format("[%s] %s (Ubicado en: %s)", info.type, info.name, info.parent)
            txt.TextColor3 = Color3.fromRGB(220, 225, 235)
            txt.Font = Enum.Font.GothamSemibold
            txt.TextSize = 9
            txt.TextXAlignment = Enum.TextXAlignment.Left
            txt.TextTruncate = Enum.TextTruncate.AtEnd
            txt.Parent = card
        end
    end
end)

-- ============================================================================
-- 5. LIMPIEZA Y CIERRE
-- =========================================
local function cleanupAll()
    if not STATE.alive then return end
    STATE.alive = false
    for _, conn in ipairs(STATE.connections) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(STATE.connections)

    if screenGui and screenGui.Parent then
        pcall(function() screenGui:Destroy() end)
    end
end

btnClose.MouseButton1Click:Connect(cleanupAll)
screenGui.Destroying:Connect(cleanupAll)

_G.SAB_DuelsMonitor = {
    Cleanup = cleanupAll,
}

--[[
    ============================================================================
    PROYECTO: SAB MONEY & BRAINROT INCOME EDITOR
    Compatibilidad: Delta Executor / Roblox (Steal a Brainrot)
    Arquitectura:
      1. Interfaz Oscura, Moderna y Compacta con 3 Pestañas (Brainrot, Money, Settings).
      2. Escáner automático de Brainrots en la base del jugador con detección dinámica.
      3. Editor individual de producción por Brainrot (Modificación Local / Visual).
      4. Editor de Dinero con formateo automático de sufijos (K, M, B, T, Qa, etc.).
      5. Sistema de verificación honesto que distingue cambios locales de datos del servidor.
    ============================================================================
]]

-- Limpieza de ejecucion previa
if _G.SAB_IncomeEditor then
    pcall(function()
        _G.SAB_IncomeEditor.Cleanup()
    end)
end

-- ============================================================================
-- SECCION 1: SERVICIOS Y REFERENCIAS BASE
-- ============================================================================
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

-- ============================================================================
-- SECCION 2: UTILIDADES DE FORMATO (K, M, B, T, Qa...)
-- ============================================================================
local SUFFIXES = {"", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc"}

local function formatNumberAbbreviated(val)
    if type(val) ~= "number" then
        val = tonumber(val) or 0
    end
    if val < 1000 then
        return string.format("$%.0f", val)
    end

    local magnitude = math.floor(math.log10(math.abs(val)) / 3)
    local scaled = val / (10 ^ (magnitude * 3))
    local suffix = SUFFIXES[magnitude + 1] or "Un"
    return string.format("$%.2f%s", scaled, suffix)
end

local function parseFormattedNumber(str)
    if type(str) == "number" then return str end
    if not str then return 0 end
    
    str = tostring(str):upper():gsub("[%$,%s]", "")
    local lastChar = str:sub(-1)
    local multiplier = 1

    local suffixMap = {
        K = 1e3, M = 1e6, B = 1e9, T = 1e12,
        QA = 1e15, QI = 1e18, SX = 1e21, SP = 1e24
    }

    for suf, mult in pairs(suffixMap) do
        if str:find(suf) then
            multiplier = mult
            str = str:gsub(suf, "")
            break
        end
    end

    local num = tonumber(str) or 0
    return num * multiplier
end

-- ============================================================================
-- SECCION 3: ESTADO Y GESTION DE DATOS
-- ============================================================================
local STATE = {
    alive = true,
    brainrots = {},         -- Lista de registros detectados en la base
    selectedBrainrot = nil, -- Registro seleccionado actualmente
    connections = {},
    searchQuery = "",
}

-- Intenta localizar la base (Plot) del jugador actual en Workspace
local function findPlayerPlot()
    local plotsFolder = Workspace:FindFirstChild("Plots") or Workspace:FindFirstChild("Bases") or Workspace:FindFirstChild("PlayerPlots")
    if not plotsFolder then
        -- Buscar carpetas generales en Workspace
        for _, child in ipairs(Workspace:GetChildren()) do
            if child:IsA("Folder") or child:IsA("Model") then
                local lname = child.Name:lower()
                if lname:find("plot") or lname:find("base") then
                    plotsFolder = child
                    break
                end
            end
        end
    end

    if not plotsFolder then return Workspace end -- Fallback a Workspace entero

    -- Comprobar si alguna subcarpeta pertenece al jugador
    for _, plot in ipairs(plotsFolder:GetChildren()) do
        local ownerAttr = plot:GetAttribute("Owner") or plot:GetAttribute("Player")
        if ownerAttr == LocalPlayer.Name or plot.Name:find(LocalPlayer.Name) then
            return plot
        end
        -- Comprobar si hay un modelo con el nombre del jugador dentro
        if plot:FindFirstChild(LocalPlayer.Name) then
            return plot[LocalPlayer.Name]
        end
    end

    return plotsFolder -- Fallback general
end

-- Escanea la base en busca de Brainrots y objetos de produccion
local function scanPlayerBase()
    local baseRoot = findPlayerPlot()
    local detected = {}

    local function inspectItem(inst)
        if not inst or not inst:IsA("Model") then return end
        local name = inst.Name
        local incomeVal = 1
        local incomeObj = nil

        -- Buscar atributos o valores numericos de ingresos
        for _, attr in ipairs({"Income", "Generation", "CashPerSecond", "Rate", "CPS"}) do
            local v = inst:GetAttribute(attr)
            if type(v) == "number" then
                incomeVal = v
                break
            end
        end

        -- Buscar subobjetos de valor (NumberValue / IntValue)
        for _, desc in ipairs(inst:GetDescendants()) do
            if desc:IsA("NumberValue") or desc:IsA("IntValue") then
                local lname = desc.Name:lower()
                if lname:find("income") or lname:find("cash") or lname:find("gen") or lname:find("rate") then
                    incomeVal = desc.Value
                    incomeObj = desc
                    break
                end
            end
        end

        -- Filtrar objetos genericos o partes del mapa
        local lname = name:lower()
        if lname ~= "workspace" and not lname:find("baseplate") and not lname:find("terrain") then
            detected[#detected + 1] = {
                instance = inst,
                name = name,
                income = incomeVal,
                incomeObject = incomeObj,
                originalIncome = incomeVal,
                modified = false,
            }
        end
    end

    for _, desc in ipairs(baseRoot:GetDescendants()) do
        if desc:IsA("Model") then
            -- Verificar si es un Brainrot colocado (tiene partes y no es un jugador)
            if not Players:GetPlayerFromCharacter(desc) and desc:FindFirstChildWhichIsA("BasePart") then
                inspectItem(desc)
            end
        end
    end

    -- Si no se encontro nada en la base especifica, escanear todo Workspace como respaldo
    if #detected == 0 and baseRoot ~= Workspace then
        for _, desc in ipairs(Workspace:GetDescendants()) do
            if desc:IsA("Model") and not Players:GetPlayerFromCharacter(desc) then
                local lname = desc.Name:lower()
                if lname ~= "workspace" and not lname:find("baseplate") then
                    detected[#detected + 1] = {
                        instance = desc,
                        name = desc.Name,
                        income = 1,
                        originalIncome = 1,
                        modified = false,
                    }
                end
            end
        end
    end

    STATE.brainrots = detected
    return detected
end

-- ============================================================================
-- SECCION 4: INTERFAZ GRAFICA MODERNA (GUI)
-- ============================================================================
local guiParent = (type(gethui) == "function" and select(2, pcall(gethui))) or CoreGui

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SAB_IncomeEditor"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = guiParent

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 520, 0, 390)
mainFrame.Position = UDim2.new(0.5, -260, 0.5, -195)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 16, 21)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 8)

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(42, 45, 60)
mainStroke.Thickness = 1
mainStroke.Parent = mainFrame

-- Barra superior
local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 32)
topBar.BackgroundColor3 = Color3.fromRGB(22, 24, 33)
topBar.BorderSizePixel = 0
topBar.Parent = mainFrame
Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 8)

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -40, 1, 0)
titleLabel.Position = UDim2.new(0, 12, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "SAB | MONEY & BRAINROT INCOME EDITOR"
titleLabel.TextColor3 = Color3.fromRGB(230, 235, 245)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 11
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = topBar

local btnClose = Instance.new("TextButton")
btnClose.Size = UDim2.new(0, 28, 0, 28)
btnClose.Position = UDim2.new(1, -30, 0, 2)
btnClose.BackgroundTransparency = 1
btnClose.Text = "X"
btnClose.TextColor3 = Color3.fromRGB(235, 85, 85)
btnClose.Font = Enum.Font.GothamBold
btnClose.TextSize = 14
btnClose.Parent = topBar

-- Sistema de Pestañas (Tabs)
local tabNav = Instance.new("Frame")
tabNav.Size = UDim2.new(1, -20, 0, 30)
tabNav.Position = UDim2.new(0, 10, 0, 42)
tabNav.BackgroundColor3 = Color3.fromRGB(22, 24, 33)
tabNav.BorderSizePixel = 0
tabNav.Parent = mainFrame
Instance.new("UICorner", tabNav).CornerRadius = UDim.new(0, 6)

local tabFrames = {}
local tabButtons = {}

local function createTabButton(name, index, xPos, widthScale)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(widthScale, -4, 1, -4)
    b.Position = UDim2.new(xPos, 2, 0, 2)
    b.BackgroundColor3 = (index == 1) and Color3.fromRGB(45, 90, 70) or Color3.fromRGB(28, 30, 40)
    b.BorderSizePixel = 0
    b.Text = name
    b.TextColor3 = Color3.fromRGB(240, 240, 245)
    b.Font = Enum.Font.GothamSemibold
    b.TextSize = 10
    b.Parent = tabNav
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)
    tabButtons[index] = b
    return b
end

local function createTabContainer(index)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, -20, 1, -118)
    f.Position = UDim2.new(0, 10, 0, 82)
    f.BackgroundTransparency = 1
    f.Visible = (index == 1)
    f.Parent = mainFrame
    tabFrames[index] = f
    return f
end

createTabButton("BRAINROT EDITOR", 1, 0.00, 0.36)
createTabButton("MONEY EDITOR", 2, 0.36, 0.32)
createTabButton("SETTINGS", 3, 0.68, 0.32)

local containerBrainrot = createTabContainer(1)
local containerMoney = createTabContainer(2)
createTabContainer(3) -- Settings

for i, btn in ipairs(tabButtons) do
    btn.MouseButton1Click:Connect(function()
        for j, frm in ipairs(tabFrames) do
            frm.Visible = (j == i)
            tabButtons[j].BackgroundColor3 = (j == i) and Color3.fromRGB(45, 90, 70) or Color3.fromRGB(28, 30, 40)
        end
    end)
end

-- ============================================================================
-- SECCION 5: CONSTRUCCION DE CONTENEDORES (PESTAÑA 1: BRAINROT EDITOR)
-- ============================================================================

-- Buscador
local searchBox = Instance.new("TextBox")
searchBox.Size = UDim2.new(0.55, 0, 0, 26)
searchBox.Position = UDim2.new(0, 0, 0, 0)
searchBox.BackgroundColor3 = Color3.fromRGB(22, 24, 32)
searchBox.BorderSizePixel = 0
searchBox.PlaceholderText = "Buscar Brainrot por nombre..."
searchBox.Text = ""
searchBox.TextColor3 = Color3.fromRGB(235, 235, 245)
searchBox.Font = Enum.Font.Gotham
searchBox.TextSize = 10
searchBox.ClearTextOnFocus = false
searchBox.Parent = containerBrainrot
Instance.new("UICorner", searchBox).CornerRadius = UDim.new(0, 5)

-- Boton Scan Base
local btnScanBase = Instance.new("TextButton")
btnScanBase.Size = UDim2.new(0.42, 0, 0, 26)
btnScanBase.Position = UDim2.new(0.58, 0, 0, 0)
btnScanBase.BackgroundColor3 = Color3.fromRGB(40, 110, 180)
btnScanBase.BorderSizePixel = 0
btnScanBase.Text = "ESCANEAR BASE"
btnScanBase.TextColor3 = Color3.fromRGB(245, 245, 250)
btnScanBase.Font = Enum.Font.GothamSemibold
btnScanBase.TextSize = 10
btnScanBase.Parent = containerBrainrot
Instance.new("UICorner", btnScanBase).CornerRadius = UDim.new(0, 5)

-- Lista Izquierda
local brainrotScroll = Instance.new("ScrollingFrame")
brainrotScroll.Size = UDim2.new(0.55, 0, 1, -36)
brainrotScroll.Position = UDim2.new(0, 0, 0, 32)
brainrotScroll.BackgroundColor3 = Color3.fromRGB(12, 13, 17)
brainrotScroll.BorderSizePixel = 0
brainrotScroll.ScrollBarThickness = 3
brainrotScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
brainrotScroll.Parent = containerBrainrot
Instance.new("UICorner", brainrotScroll).CornerRadius = UDim.new(0, 6)

local brainrotListLayout = Instance.new("UIListLayout")
brainrotListLayout.Padding = UDim.new(0, 3)
brainrotListLayout.SortOrder = Enum.SortOrder.LayoutOrder
brainrotListLayout.Parent = brainrotScroll

brainrotListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    brainrotScroll.CanvasSize = UDim2.new(0, 0, 0, brainrotListLayout.AbsoluteContentSize.Y + 6)
end)

-- Panel Derecho (Editor Individual)
local detailBrainrotPanel = Instance.new("Frame")
detailBrainrotPanel.Size = UDim2.new(0.42, 0, 1, -36)
detailBrainrotPanel.Position = UDim2.new(0.58, 0, 0, 32)
detailBrainrotPanel.BackgroundColor3 = Color3.fromRGB(20, 22, 29)
detailBrainrotPanel.BorderSizePixel = 0
detailBrainrotPanel.Parent = containerBrainrot
Instance.new("UICorner", detailBrainrotPanel).CornerRadius = UDim.new(0, 6)

local lblDetailTitle = Instance.new("TextLabel")
lblDetailTitle.Size = UDim2.new(1, -12, 0, 24)
lblDetailTitle.Position = UDim2.new(0, 6, 0, 6)
lblDetailTitle.BackgroundTransparency = 1
lblDetailTitle.Text = "SELECCIONA UN BRAINROT"
lblDetailTitle.TextColor3 = Color3.fromRGB(240, 240, 250)
lblDetailTitle.Font = Enum.Font.GothamBold
lblDetailTitle.TextSize = 10
lblDetailTitle.TextXAlignment = Enum.TextXAlignment.Left
lblDetailTitle.TextTruncate = Enum.TextTruncate.AtEnd
lblDetailTitle.Parent = detailBrainrotPanel

local lblDetailInfo = Instance.new("TextLabel")
lblDetailInfo.Size = UDim2.new(1, -12, 0, 40)
lblDetailInfo.Position = UDim2.new(0, 6, 0, 32)
lblDetailInfo.BackgroundTransparency = 1
lblDetailInfo.Text = "Produccion actual: --\nEstado: Seleccionado localmente"
lblDetailInfo.TextColor3 = Color3.fromRGB(175, 180, 195)
lblDetailInfo.Font = Enum.Font.Gotham
lblDetailInfo.TextSize = 9
lblDetailInfo.TextWrapped = true
lblDetailInfo.TextXAlignment = Enum.TextXAlignment.Left
lblDetailInfo.Parent = detailBrainrotPanel

local inputIncomeBox = Instance.new("TextBox")
inputIncomeBox.Size = UDim2.new(1, -12, 0, 28)
inputIncomeBox.Position = UDim2.new(0, 6, 0, 85)
inputIncomeBox.BackgroundColor3 = Color3.fromRGB(14, 15, 20)
inputIncomeBox.BorderSizePixel = 0
inputIncomeBox.PlaceholderText = "Ej. 1000000 o 1B"
inputIncomeBox.Text = ""
inputIncomeBox.TextColor3 = Color3.fromRGB(235, 235, 245)
inputIncomeBox.Font = Enum.Font.Gotham
inputIncomeBox.TextSize = 11
inputIncomeBox.ClearTextOnFocus = false
inputIncomeBox.Parent = detailBrainrotPanel
Instance.new("UICorner", inputIncomeBox).CornerRadius = UDim.new(0, 5)

local btnApplyIncome = Instance.new("TextButton")
btnApplyIncome.Size = UDim2.new(1, -12, 0, 26)
btnApplyIncome.Position = UDim2.new(0, 6, 0, 122)
btnApplyIncome.BackgroundColor3 = Color3.fromRGB(35, 125, 70)
btnApplyIncome.BorderSizePixel = 0
btnApplyIncome.Text = "APPLY (LOCAL)"
btnApplyIncome.TextColor3 = Color3.fromRGB(245, 245, 250)
btnApplyIncome.Font = Enum.Font.GothamSemibold
btnApplyIncome.TextSize = 10
btnApplyIncome.Parent = detailBrainrotPanel
Instance.new("UICorner", btnApplyIncome).CornerRadius = UDim.new(0, 5)

local btnResetIncome = Instance.new("TextButton")
btnResetIncome.Size = UDim2.new(1, -12, 0, 26)
btnResetIncome.Position = UDim2.new(0, 6, 0, 154)
btnResetIncome.BackgroundColor3 = Color3.fromRGB(110, 50, 50)
btnResetIncome.BorderSizePixel = 0
btnResetIncome.Text = "RESET"
btnResetIncome.TextColor3 = Color3.fromRGB(245, 245, 250)
btnResetIncome.Font = Enum.Font.GothamSemibold
btnResetIncome.TextSize = 10
btnResetIncome.Parent = detailBrainrotPanel
Instance.new("UICorner", btnResetIncome).CornerRadius = UDim.new(0, 5)

-- ============================================================================
-- SECCION 6: CONSTRUCCION DE CONTENEDORES (PESTAÑA 2: MONEY EDITOR)
-- =========================================
local moneyPanel = Instance.new("Frame")
moneyPanel.Size = UDim2.new(1, 0, 1, 0)
moneyPanel.Position = UDim2.new(0, 0, 0, 0)
moneyPanel.BackgroundTransparency = 1
moneyPanel.Parent = containerMoney

local lblMoneyTitle = Instance.new("TextLabel")
lblMoneyTitle.Size = UDim2.new(1, 0, 0, 24)
lblMoneyTitle.Position = UDim2.new(0, 0, 0, 10)
lblMoneyTitle.BackgroundTransparency = 1
lblMoneyTitle.Text = "SALDO ACTUAL DETECTADO:"
lblMoneyTitle.TextColor3 = Color3.fromRGB(170, 175, 195)
lblMoneyTitle.Font = Enum.Font.GothamBold
lblMoneyTitle.TextSize = 11
lblMoneyTitle.TextXAlignment = Enum.TextXAlignment.Left
lblMoneyTitle.Parent = moneyPanel

local lblMoneyDisplay = Instance.new("TextLabel")
lblMoneyDisplay.Size = UDim2.new(1, 0, 0, 36)
lblMoneyDisplay.Position = UDim2.new(0, 0, 0, 36)
lblMoneyDisplay.BackgroundColor3 = Color3.fromRGB(22, 24, 33)
lblMoneyDisplay.BorderSizePixel = 0
lblMoneyDisplay.Text = "$0 (Escaneando...)"
lblMoneyDisplay.TextColor3 = Color3.fromRGB(110, 235, 160)
lblMoneyDisplay.Font = Enum.Font.GothamBold
lblMoneyDisplay.TextSize = 16
lblMoneyDisplay.TextXAlignment = Enum.TextXAlignment.Left
lblMoneyDisplay.Parent = moneyPanel
Instance.new("UICorner", lblMoneyDisplay).CornerRadius = UDim.new(0, 6)

local lblMoneyInputTitle = Instance.new("TextLabel")
lblMoneyInputTitle.Size = UDim2.new(1, 0, 0, 20)
lblMoneyInputTitle.Position = UDim2.new(0, 0, 0, 88)
lblMoneyInputTitle.BackgroundTransparency = 1
lblMoneyInputTitle.Text = "NUEVA CANTIDAD PERSONALIZADA (Modificación Local/Visual):"
lblMoneyInputTitle.TextColor3 = Color3.fromRGB(170, 175, 195)
lblMoneyInputTitle.Font = Enum.Font.GothamBold
lblMoneyInputTitle.TextSize = 10
lblMoneyInputTitle.TextXAlignment = Enum.TextXAlignment.Left
lblMoneyInputTitle.Parent = moneyPanel

local inputMoneyBox = Instance.new("TextBox")
inputMoneyBox.Size = UDim2.new(1, 0, 0, 32)
inputMoneyBox.Position = UDim2.new(0, 0, 0, 112)
inputMoneyBox.BackgroundColor3 = Color3.fromRGB(14, 15, 20)
inputMoneyBox.BorderSizePixel = 0
inputMoneyBox.PlaceholderText = "Ej. 100Qa o 500T"
inputMoneyBox.Text = ""
inputMoneyBox.TextColor3 = Color3.fromRGB(235, 235, 245)
inputMoneyBox.Font = Enum.Font.Gotham
inputMoneyBox.TextSize = 12
inputMoneyBox.ClearTextOnFocus = false
inputMoneyBox.Parent = moneyPanel
Instance.new("UICorner", inputMoneyBox).CornerRadius = UDim.new(0, 6)

local btnApplyMoney = Instance.new("TextButton")
btnApplyMoney.Size = UDim2.new(0.48, 0, 0, 30)
btnApplyMoney.Position = UDim2.new(0, 0, 0, 156)
btnApplyMoney.BackgroundColor3 = Color3.fromRGB(35, 125, 70)
btnApplyMoney.BorderSizePixel = 0
btnApplyMoney.Text = "APPLY (VISUAL)"
btnApplyMoney.TextColor3 = Color3.fromRGB(245, 245, 250)
btnApplyMoney.Font = Enum.Font.GothamSemibold
btnApplyMoney.TextSize = 11
btnApplyMoney.Parent = moneyPanel
Instance.new("UICorner", btnApplyMoney).CornerRadius = UDim.new(0, 6)

local btnResetMoney = Instance.new("TextButton")
btnResetMoney.Size = UDim2.new(0.48, 0, 0, 30)
btnResetMoney.Position = UDim2.new(0.52, 0, 0, 156)
btnResetMoney.BackgroundColor3 = Color3.fromRGB(110, 50, 50)
btnResetMoney.BorderSizePixel = 0
btnResetMoney.Text = "RESET"
btnResetMoney.TextColor3 = Color3.fromRGB(245, 245, 250)
btnResetMoney.Font = Enum.Font.GothamSemibold
btnResetMoney.TextSize = 11
btnResetMoney.Parent = moneyPanel
Instance.new("UICorner", btnResetMoney).CornerRadius = UDim.new(0, 6)

local lblMoneyNotice = Instance.new("TextLabel")
lblMoneyNotice.Size = UDim2.new(1, 0, 0, 50)
lblMoneyNotice.Position = UDim2.new(0, 0, 0, 196)
lblMoneyNotice.BackgroundTransparency = 1
lblMoneyNotice.Text = "AVISO DE SEGURIDAD: El saldo de dinero esta protegido por el servidor de SAB. Este boton actualiza unicamente la interfaz visual local para fines de demostracion."
lblMoneyNotice.TextColor3 = Color3.fromRGB(235, 165, 85)
lblMoneyNotice.Font = Enum.Font.Gotham
lblMoneyNotice.TextSize = 9
lblMoneyNotice.TextWrapped = true
lblMoneyNotice.TextXAlignment = Enum.TextXAlignment.Left
lblMoneyNotice.TextYAlignment = Enum.TextYAlignment.Top
lblMoneyNotice.Parent = moneyPanel

-- ============================================================================
-- SECCION 7: BARRA DE ESTADO INFERIOR
-- =========================================
local statusBar = Instance.new("TextLabel")
statusBar.Size = UDim2.new(1, -20, 0, 22)
statusBar.Position = UDim2.new(0, 10, 1, -28)
statusBar.BackgroundColor3 = Color3.fromRGB(22, 24, 33)
statusBar.BorderSizePixel = 0
statusBar.Text = " Estado: Listo. Escanea tu base para empezar."
statusBar.TextColor3 = Color3.fromRGB(140, 215, 165)
statusBar.Font = Enum.Font.Gotham
statusBar.TextSize = 10
statusBar.TextXAlignment = Enum.TextXAlignment.Left
statusBar.Parent = mainFrame
Instance.new("UICorner", statusBar).CornerRadius = UDim.new(0, 4)

local function setStatus(msg, col)
    if not statusBar then return end
    statusBar.Text = " Estado: " .. tostring(msg)
    statusBar.TextColor3 = col or Color3.fromRGB(200, 205, 220)
end

-- ============================================================================
-- SECCION 8: RENDERIZADO Y LOGICA DE INTERACCION
-- =========================================
local function renderBrainrotList()
    for _, child in ipairs(brainrotScroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    local query = STATE.searchQuery:lower()
    local count = 0

    for idx, entry in ipairs(STATE.brainrots) do
        if query == "" or entry.name:lower():find(query, 1, true) then
            count = count + 1

            local card = Instance.new("Frame")
            card.Size = UDim2.new(1, -6, 0, 36)
            card.BackgroundColor3 = (STATE.selectedBrainrot == entry) and Color3.fromRGB(38, 72, 55) or Color3.fromRGB(22, 24, 32)
            card.BorderSizePixel = 0
            card.LayoutOrder = count
            card.Parent = brainrotScroll
            Instance.new("UICorner", card).CornerRadius = UDim.new(0, 5)

            local lblName = Instance.new("TextLabel")
            lblName.Size = UDim2.new(1, -80, 1, 0)
            lblName.Position = UDim2.new(0, 8, 0, 0)
            lblName.BackgroundTransparency = 1
            lblName.Text = entry.name
            lblName.TextColor3 = Color3.fromRGB(235, 235, 245)
            lblName.Font = Enum.Font.GothamBold
            lblName.TextSize = 10
            lblName.TextXAlignment = Enum.TextXAlignment.Left
            lblName.TextTruncate = Enum.TextTruncate.AtEnd
            lblName.Parent = card

            local lblIncome = Instance.new("TextLabel")
            lblIncome.Size = UDim2.new(0, 72, 1, 0)
            lblIncome.Position = UDim2.new(1, -76, 0, 0)
            lblIncome.BackgroundTransparency = 1
            lblIncome.Text = formatNumberAbbreviated(entry.income) .. "/s"
            lblIncome.TextColor3 = entry.modified and Color3.fromRGB(110, 235, 160) or Color3.fromRGB(180, 185, 200)
            lblIncome.Font = Enum.Font.GothamSemibold
            lblIncome.TextSize = 10
            lblIncome.TextXAlignment = Enum.TextXAlignment.Right
            lblIncome.Parent = card

            local btnSelect = Instance.new("TextButton")
            btnSelect.Size = UDim2.new(1, 0, 1, 0)
            btnSelect.BackgroundTransparency = 1
            btnSelect.Text = ""
            btnSelect.Parent = card

            btnSelect.MouseButton1Click:Connect(function()
                STATE.selectedBrainrot = entry
                lblDetailTitle.Text = entry.name:upper()
                lblDetailInfo.Text = string.format("Produccion actual: %s/s\nEstado: Seleccionado", formatNumberAbbreviated(entry.income))
                inputIncomeBox.Text = tostring(entry.income)
                renderBrainrotList()
                setStatus("Seleccionado: " + entry.name, Color3.fromRGB(130, 195, 255))
            end)
        end
    end
end

-- Obtener dinero actual del jugador desde leaderstats
local function getPlayerMoney()
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    if leaderstats then
        for _, stat in ipairs(leaderstats:GetChildren()) do
            local lname = stat.Name:lower()
            if lname:find("money") or lname:find("cash") or lname:find("coin") or lname:find("gold") then
                if stat:IsA("NumberValue") or stat:IsA("IntValue") then
                    return stat.Value
                end
            end
        end
    end
    return 0
end

-- Actualizar visualizador de dinero
task.spawn(function()
    while STATE.alive and screenGui.Parent do
        task.wait(1)
        local rawMoney = getPlayerMoney()
        lblMoneyDisplay.Text = " " .. formatNumberAbbreviated(rawMoney)
    end
end)

-- Eventos de botones
btnScanBase.MouseButton1Click:Connect(function()
    scanPlayerBase()
    renderBrainrotList()
    setStatus(string.format("Escaneo completo: %d Brainrots detectados en tu base.", #STATE.brainrots), Color3.fromRGB(46, 204, 113))
end)

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    STATE.searchQuery = searchBox.Text
    renderBrainrotList()
end)

btnApplyIncome.MouseButton1Click:Connect(function()
    if not STATE.selectedBrainrot then
        setStatus("Selecciona un Brainrot de la lista primero.", Color3.fromRGB(235, 120, 120))
        return
    end

    local newVal = parseFormattedNumber(inputIncomeBox.Text)
    if newVal <= 0 then
        setStatus("Introduce un valor numerico valido.", Color3.fromRGB(235, 120, 120))
        return
    end

    local entry = STATE.selectedBrainrot
    entry.income = newVal
    entry.modified = true

    -- Modificacion Local / Visual en atributos o subobjetos si existen
    pcall(function()
        if entry.incomeObject then
            entry.incomeObject.Value = newVal
        end
        entry.instance:SetAttribute("Income", newVal)
    end)

    renderBrainrotList()
    lblDetailInfo.Text = string.format("Produccion actual: %s/s\nEstado: Modificado (Local)", formatNumberAbbreviated(newVal))
    setStatus(string.format("Aplicado (Visual): %s ahora produce %s/s", entry.name, formatNumberAbbreviated(newVal)), Color3.fromRGB(46, 204, 113))
end)

btnResetIncome.MouseButton1Click:Connect(function()
    if not STATE.selectedBrainrot then return end
    local entry = STATE.selectedBrainrot
    entry.income = entry.originalIncome
    entry.modified = false

    pcall(function()
        if entry.incomeObject then
            entry.incomeObject.Value = entry.originalIncome
        end
        entry.instance:SetAttribute("Income", entry.originalIncome)
    end)

    inputIncomeBox.Text = tostring(entry.originalIncome)
    renderBrainrotList()
    lblDetailInfo.Text = string.format("Produccion actual: %s/s\nEstado: Restaurado", formatNumberAbbreviated(entry.income))
    setStatus("Restaurado valor original para " .. entry.name, Color3.fromRGB(160, 215, 175))
end)

btnApplyMoney.MouseButton1Click:Connect(function()
    local customVal = parseFormattedNumber(inputMoneyBox.Text)
    lblMoneyDisplay.Text = " " .. formatNumberAbbreviated(customVal) .. " (Modificado Localmente)"
    setStatus("Saldo visual actualizado a " .. formatNumberAbbreviated(customVal) .. " (El servidor mantiene el valor real).", Color3.fromRGB(235, 165, 85))
end)

btnResetMoney.MouseButton1Click:Connect(function()
    local realMoney = getPlayerMoney()
    lblMoneyDisplay.Text = " " .. formatNumberAbbreviated(realMoney)
    inputMoneyBox.Text = ""
    setStatus("Saldo reiniciado al valor real del servidor.", Color3.fromRGB(160, 215, 175))
end)

-- ============================================================================
-- SECCION 9: LIMPIEZA Y CIERRE
-- ============================================================================
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

_G.SAB_IncomeEditor = {
    Cleanup = cleanupAll,
}

-- Escaneo inicial al cargar la GUI
task.defer(function()
    scanPlayerBase()
    renderBrainrotList()
end)

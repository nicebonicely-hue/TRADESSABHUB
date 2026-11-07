--[[
    ==================================================
    SAB CODE HUNTER HUB - Steal a Brainrot (Delta)
    Versión: 3.1 - Escaneo Activo cada 5 Segundos
    Autor: Asistente Experto Luau
    ==================================================
]]--

-- Verificar entorno de exploit compatible
if not syn and not http and not request and not fluxus and not identifyexecutor then
    warn("[SAB CODE HUNTER] Entorno no compatible o función HTTP no disponible.")
end

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui")

-- Variables de Estado y Configuración Global (Escaneo restaurado a 5 segundos)
getgenv().SAB_Config = {
    CodeHunterActive = true,
    RiddleSolverActive = true,
    AutoRedeemActive = false,
    NotificationsActive = true,
    ScanInterval = 5, -- Escaneo exacto cada 5 segundos
    GeminiApiKey = "",
}

local Database = {}
local scannedCache = {}
local isMinimized = false

-- Limpiar interfaz anterior si existe para evitar duplicados
if CoreGui:FindFirstChild("SABCodeHunterHub") then
    CoreGui.SABCodeHunterHub:Destroy()
end

-- ==========================================
-- 1. CREACIÓN DE LA INTERFAZ GRÁFICA
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SABCodeHunterHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local successGui = pcall(function()
    ScreenGui.Parent = CoreGui
end)
if not successGui then
    ScreenGui.Parent = PlayerGui
end

-- Ventana Principal
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
MainFrame.BorderColor3 = Color3.fromRGB(80, 40, 140)
MainFrame.BorderSizePixel = 2
MainFrame.Position = UDim2.new(0.5, -250, 0.5, -175)
MainFrame.Size = UDim2.new(0, 500, 0, 350)
MainFrame.Active = true
MainFrame.Draggable = true

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 8)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(120, 60, 220)
MainStroke.Thickness = 1.5
MainStroke.Parent = MainFrame

-- Barra Superior (Header)
local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Parent = MainFrame
Header.BackgroundColor3 = Color3.fromRGB(25, 20, 40)
Header.BorderSizePixel = 0
Header.Size = UDim2.new(1, 0, 0, 35)

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 8)
HeaderCorner.Parent = Header

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "TitleLabel"
TitleLabel.Parent = Header
TitleLabel.BackgroundTransparency = 1
TitleLabel.Position = UDim2.new(0, 10, 0, 0)
TitleLabel.Size = UDim2.new(0, 250, 1, 0)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.Text = "SAB CODE HUNTER HUB [PRO]"
TitleLabel.TextColor3 = Color3.fromRGB(200, 160, 255)
TitleLabel.TextSize = 13
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left

-- Botones de Ventana
local CloseBtn = Instance.new("TextButton")
CloseBtn.Name = "CloseBtn"
CloseBtn.Parent = Header
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.Position = UDim2.new(1, -30, 0, 7)
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
MinBtn.Position = UDim2.new(1, -58, 0, 7)
MinBtn.Size = UDim2.new(0, 22, 0, 22)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.Text = "-"
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.TextSize = 14

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0, 4)
MinCorner.Parent = MinBtn

-- Contenedor Principal
local ContentFrame = Instance.new("Frame")
ContentFrame.Name = "ContentFrame"
ContentFrame.Parent = MainFrame
ContentFrame.BackgroundTransparency = 1
ContentFrame.Position = UDim2.new(0, 0, 0, 40)
ContentFrame.Size = UDim2.new(1, 0, 1, -40)

-- Consola de Logs Interna
local LogsScrolling = Instance.new("ScrollingFrame")
LogsScrolling.Name = "LogsScrolling"
LogsScrolling.Parent = ContentFrame
LogsScrolling.BackgroundColor3 = Color3.fromRGB(10, 10, 18)
LogsScrolling.BorderColor3 = Color3.fromRGB(50, 30, 90)
LogsScrolling.Position = UDim2.new(0, 10, 0, 10)
LogsScrolling.Size = UDim2.new(0, 310, 0, 240)
LogsScrolling.CanvasSize = UDim2.new(0, 0, 0, 0)
LogsScrolling.ScrollBarThickness = 5

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = LogsScrolling
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 4)

-- Panel de Configuración (Derecha)
local ControlPanel = Instance.new("ScrollingFrame")
ControlPanel.Name = "ControlPanel"
ControlPanel.Parent = ContentFrame
ControlPanel.BackgroundTransparency = 1
ControlPanel.Position = UDim2.new(0, 330, 0, 10)
ControlPanel.Size = UDim2.new(0, 160, 0, 240)
ControlPanel.CanvasSize = UDim2.new(0, 0, 0, 0)
ControlPanel.ScrollBarThickness = 3

local UIListControl = Instance.new("UIListLayout")
UIListControl.Parent = ControlPanel
UIListControl.SortOrder = Enum.SortOrder.LayoutOrder
UIListControl.Padding = UDim.new(0, 8)

-- Botón Quick Redeem Instantáneo
local QuickRedeemBtn = Instance.new("TextButton")
QuickRedeemBtn.Name = "QuickRedeemBtn"
QuickRedeemBtn.Parent = MainFrame
QuickRedeemBtn.BackgroundColor3 = Color3.fromRGB(60, 30, 130)
QuickRedeemBtn.Position = UDim2.new(0, 10, 1, -35)
QuickRedeemBtn.Size = UDim2.new(0, 310, 0, 25)
QuickRedeemBtn.Font = Enum.Font.GothamBold
QuickRedeemBtn.Text = "⚡ QUICK REDEEM INSTANT"
QuickRedeemBtn.TextColor3 = Color3.fromRGB(220, 200, 255)
QuickRedeemBtn.TextSize = 11

local QuickCorner = Instance.new("UICorner")
QuickCorner.CornerRadius = UDim.new(0, 6)
QuickCorner.Parent = QuickRedeemBtn

-- Indicador de Estado
local StatusIndicator = Instance.new("TextLabel")
StatusIndicator.Name = "StatusIndicator"
StatusIndicator.Parent = MainFrame
StatusIndicator.BackgroundTransparency = 1
StatusIndicator.Position = UDim2.new(0, 330, 1, -35)
StatusIndicator.Size = UDim2.new(0, 160, 0, 25)
StatusIndicator.Font = Enum.Font.GothamBold
StatusIndicator.Text = "STATUS: [ACTIVE]"
StatusIndicator.TextColor3 = Color3.fromRGB(50, 220, 100)
StatusIndicator.TextSize = 11

-- ==========================================
-- 2. UTILIDADES Y LOGS
-- ==========================================
local function LogMessage(text, color)
    pcall(function()
        local msg = Instance.new("TextLabel")
        msg.Parent = LogsScrolling
        msg.BackgroundTransparency = 1
        msg.Size = UDim2.new(1, -10, 0, 18)
        msg.Font = Enum.Font.Code
        msg.Text = "["..os.date("%H:%M:%S").."] " .. text
        msg.TextColor3 = color or Color3.fromRGB(200, 200, 200)
        msg.TextSize = 10
        msg.TextXAlignment = Enum.TextXAlignment.Left
        LogsScrolling.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y + 10)
        LogsScrolling.CanvasPosition = Vector2.new(0, LogsScrolling.CanvasSize.Y.Offset)
    end)
end

local function SendNotification(title, text)
    if not getgenv().SAB_Config.NotificationsActive then return end
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = 2.5
        })
    end)
end

-- ==========================================
-- 3. BASE DE DATOS LOCAL
-- ==========================================
local function AddToDatabase(codeText, origin, status)
    codeText = string.upper(string.gsub(codeText, "%s+", ""))
    if #codeText < 3 then return end
    
    for _, item in ipairs(Database) do
        if item.Code == codeText then return end
    end
    
    table.insert(Database, {
        Code = codeText,
        Origin = origin,
        Status = status or "UNKNOWN",
        Time = os.date("%H:%M:%S")
    })
    
    LogMessage("Detectado: " .. codeText, Color3.fromRGB(255, 220, 100))
    SendNotification("Code Hunter", "¡Código encontrado: " .. codeText)
    
    if getgenv().SAB_Config.AutoRedeemActive then
        task.spawn(function()
            TryRedeemCodeInstant(Database[#Database])
        end)
    end
end

-- ==========================================
-- 4. SMART RIDDLE SOLVER (GEMINI API)
-- ==========================================
local function SolveRiddleWithGemini(riddleText)
    if not getgenv().SAB_Config.RiddleSolverActive or getgenv().SAB_Config.GeminiApiKey == "" then return end

    task.spawn(function()
        local url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=" .. getgenv().SAB_Config.GeminiApiKey
        local headers = { ["Content-Type"] = "application/json" }
        local promptBody = {
            contents = {{
                parts = {{
                    text = "Analiza este acertigio de 'Steal a Brainrot' de Sammy y extrae el código promocional exacto o respuesta corta:\n\n" .. riddleText
                }}
            }}
        }
        
        local success, response = pcall(function()
            return request({
                Url = url,
                Method = "POST",
                Headers = headers,
                Body = HttpService:JSONEncode(promptBody)
            })
        end)

        if success and response and response.StatusCode == 200 then
            local data = HttpService:JSONDecode(response.Body)
            if data and data.candidates and data.candidates[1] then
                local answer = data.candidates[1].content.parts[1].text
                LogMessage("Gemini: " .. answer, Color3.fromRGB(100, 255, 200))
                AddToDatabase(answer, "Gemini Solver", "VALID")
            end
        end
    end)
end

-- ==========================================
-- 5. CODE HUNTER ACTIVO (ESCANEA CADA 5 SEGUNDOS)
-- ==========================================
local function ScanUIElements()
    if not getgenv().SAB_Config.CodeHunterActive then return end
    
    pcall(function()
        for _, gui in ipairs(PlayerGui:GetDescendants()) do
            if gui:IsA("TextLabel") or gui:IsA("TextButton") or gui:IsA("TextBox") then
                local text = gui.Text
                if text and #text > 3 and #text < 40 then
                    local lowerText = string.lower(text)
                    if string.find(lowerText, "code") or string.find(lowerText, "sammy") or string.find(lowerText, "riddle") or string.find(lowerText, "free") then
                        if not scannedCache[text] then
                            scannedCache[text] = true
                            LogMessage("Texto UI: " .. text, Color3.fromRGB(180, 150, 255))
                            
                            if string.find(lowerText, "riddle") or string.find(lowerText, "hint") then
                                SolveRiddleWithGemini(text)
                            else
                                for codeMatch in string.gmatch(text, "[A-Z0-9_%-]+") do
                                    if #codeMatch >= 4 and #codeMatch <= 15 then
                                        AddToDatabase(codeMatch, "UI Scan", "UNKNOWN")
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end)
end

-- ==========================================
-- 6. CANJE INSTANTÁNEO
-- ==========================================
function TryRedeemCodeInstant(codeObj)
    if codeObj.Status == "VALID" or codeObj.Status == "EXPIRED" then return end
    
    LogMessage("Canjeando: " .. codeObj.Code, Color3.fromRGB(255, 180, 100))
    local redeemed = false
    
    pcall(function()
        for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
            if obj:IsA("RemoteEvent") and (string.find(string.lower(obj.Name), "code") or string.find(string.lower(obj.Name), "redeem")) then
                obj:FireServer(codeObj.Code)
                redeemed = true
            end
        end
    end)
    
    if redeemed then
        codeObj.Status = "VALID"
        LogMessage("Enviado al servidor: " .. codeObj.Code, Color3.fromRGB(100, 255, 100))
    else
        codeObj.Status = "REJECTED"
        LogMessage("Remote de canje no localizado.", Color3.fromRGB(255, 100, 100))
    end
end

QuickRedeemBtn.MouseButton1Click:Connect(function()
    LogMessage("Procesando Quick Redeem instantáneo...", Color3.fromRGB(255, 220, 100))
    for _, item in ipairs(Database) do
        if item.Status == "UNKNOWN" then
            task.spawn(function()
                TryRedeemCodeInstant(item)
            end)
        end
    end
end)

-- ==========================================
-- 7. CONTROLES Y CONFIGURACIÓN
-- ==========================================
local function CreateToggle(name, defaultState, callback)
    local btn = Instance.new("TextButton")
    btn.Parent = ControlPanel
    btn.BackgroundColor3 = defaultState and Color3.fromRGB(50, 120, 70) or Color3.fromRGB(120, 50, 50)
    btn.Size = UDim2.new(1, 0, 0, 26)
    btn.Font = Enum.Font.GothamBold
    btn.Text = name .. ": " .. (defaultState and "ON" or "OFF")
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 10

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = btn

    local state = defaultState
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.BackgroundColor3 = state and Color3.fromRGB(50, 120, 70) or Color3.fromRGB(120, 50, 50)
        btn.Text = name .. ": " .. (state and "ON" or "OFF")
        callback(state)
    end)
end

CreateToggle("Code Hunter", true, function(state) getgenv().SAB_Config.CodeHunterActive = state end)
CreateToggle("Riddle Solver", true, function(state) getgenv().SAB_Config.RiddleSolverActive = state end)
CreateToggle("Auto Redeem", false, function(state) getgenv().SAB_Config.AutoRedeemActive = state end)
CreateToggle("Notifications", true, function(state) getgenv().SAB_Config.NotificationsActive = state end)

MinBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    ContentFrame.Visible = not isMinimized
    QuickRedeemBtn.Visible = not isMinimized
    MainFrame.Size = isMinimized and UDim2.new(0, 500, 0, 35) or UDim2.new(0, 500, 0, 350)
    MinBtn.Text = isMinimized and "+" or "-"
end)

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- ==========================================
-- 8. BUCLE PRINCIPAL DE ESANEO CADA 5 SEGUNDOS
-- ==========================================
task.spawn(function()
    LogMessage("SAB Code Hunter v3.1 Iniciado. Escaneando cada 5s.", Color3.fromRGB(100, 220, 255))
    while ScreenGui.Parent do
        pcall(function()
            if getgenv().SAB_Config.CodeHunterActive then
                ScanUIElements()
            end
        end)
        task.wait(getgenv().SAB_Config.ScanInterval) -- Intervalo exacto de 5 segundos
    end
end)

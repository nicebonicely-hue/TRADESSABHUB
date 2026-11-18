local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
if CoreGui:FindFirstChild("TradeSABHubGUI") then CoreGui.TradeSABHubGUI:Destroy() end
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TradeSABHubGUI"
ScreenGui.ResetOnSpawn = false
pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
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
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 320, 0, 420)
MainFrame.Position = UDim2.new(0.5, -160, 0.5, -210)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Visible = true
MainFrame.Parent = ScreenGui
local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 16)
MainCorner.Parent = MainFrame
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, 0, 0, 50)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "TRADES SAB HUB"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = 20
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.Parent = MainFrame
local Container = Instance.new("ScrollingFrame")
Container.Size = UDim2.new(1, -20, 1, -65)
Container.Position = UDim2.new(0, 10, 0, 55)
Container.BackgroundTransparency = 1
Container.BorderSizePixel = 0
Container.CanvasSize = UDim2.new(0, 0, 0, 590)
Container.ScrollBarThickness = 4
Container.Parent = MainFrame
local UIListLayout = Instance.new("UIListLayout")
UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 12)
UIListLayout.Parent = Container
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
        pcall(function() loadstring(game:HttpGet(url))() end)
    end)
end
createScriptButton("AI Riddle Code", "https://raw.githubusercontent.com/nicebonicely-hue/TRADESSABHUB/refs/heads/main/airiddlecode.lua", 1)
createScriptButton("Auto Code SAB", "https://raw.githubusercontent.com/nicebonicely-hue/TRADESSABHUB/refs/heads/main/autocodesab.lua", 2)
createScriptButton("Open Old Machines", "https://raw.githubusercontent.com/nicebonicely-hue/TRADESSABHUB/refs/heads/main/openoldmachinessab.lua", 3)
createScriptButton("Trait Farmer Op", "https://raw.githubusercontent.com/nicebonicely-hue/TRADESSABHUB/refs/heads/main/traitfarmerop.lua", 4)
createScriptButton("Open All Machines", "https://raw.githubusercontent.com/nicebonicely-hue/TRADESSABHUB/refs/heads/main/openallmachinessab.lua", 5)
createScriptButton("Log SAB", "https://raw.githubusercontent.com/nicebonicely-hue/TRADESSABHUB/refs/heads/main/logsab.lua", 6)
createScriptButton("Teleport SAB XYZ", "https://raw.githubusercontent.com/nicebonicely-hue/TRADESSABHUB/refs/heads/main/teleportsabxyz.lua", 7)
createScriptButton("Auto Accept Trade", "https://raw.githubusercontent.com/nicebonicely-hue/TRADESSABHUB/refs/heads/main/autoaccept.lua", 8)
createScriptButton("FPS Booster God-Mode", "https://raw.githubusercontent.com/nicebonicely-hue/TRADESSABHUB/refs/heads/main/fpsbooster.lua", 9)
local isOpen = true
ToggleButton.MouseButton1Click:Connect(function()
    isOpen = not isOpen
    MainFrame.Visible = isOpen
end)
```[cite: 1]

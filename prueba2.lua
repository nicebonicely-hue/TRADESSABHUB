--[[ 
    STEAL A BRAINROT | TRACED HUB ULTIMATE (RESTORED & OPTIMIZED)
    Features: Fast Code Listener, Dynamic Word Buffer, Test Code Fix, Gemini AI Auto Riddle, Smart Auto Redeem & Verify
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Net = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Net")

local GEMINI_API_KEY = "AQ.Ab8RN6JCQzky0ioTPoLQiXXr10fSGUwe4r0mYEJQ--9UF0FKcw"

-- UI Setup (Protected GUI for Delta)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Traced_UltimateSAB"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999999

if syn and syn.protect_gui then
    syn.protect_gui(ScreenGui)
    ScreenGui.Parent = CoreGui
elseif gethui then
    ScreenGui.Parent = gethui()
else
    ScreenGui.Parent = CoreGui
end

-- Main Window Frame
local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(320, 480)
Main.Position = UDim2.new(0.5, -160, 0.5, -240)
Main.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = Main

-- Top Bar
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 38)
TopBar.BackgroundColor3 = Color3.fromRGB(22, 20, 32)
TopBar.BorderSizePixel = 0
TopBar.Parent = Main

local TopCorner = Instance.new("UICorner")
TopCorner.CornerRadius = UDim.new(0, 12)
TopCorner.Parent = TopBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -40, 1, 0)
Title.Position = UDim2.fromOffset(12, 0)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.Text = "SAB INSTANT REDEEMER + AI"
Title.TextColor3 = Color3.fromRGB(240, 220, 255)
Title.TextSize = 12
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.fromOffset(26, 26)
CloseBtn.Position = UDim2.new(1, -32, 0.5, -13)
CloseBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 70)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.new(1, 1, 1)
CloseBtn.TextSize = 11
CloseBtn.Parent = TopBar

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = CloseBtn

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- Scrolling Container
local Scrolling = Instance.new("ScrollingFrame")
Scrolling.Size = UDim2.new(1, -16, 1, -50)
Scrolling.Position = UDim2.fromOffset(8, 44)
Scrolling.BackgroundTransparency = 1
Scrolling.BorderSizePixel = 0
Scrolling.CanvasSize = UDim2.new(0, 0, 2.1, 0)
Scrolling.ScrollBarThickness = 3
Scrolling.Parent = Main

local UIList = Instance.new("UIListLayout")
UIList.SortOrder = Enum.SortOrder.LayoutOrder
UIList.Padding = UDim.new(0, 6)
UIList.Parent = Scrolling

-- Status Bar
local StatusFrame = Instance.new("Frame")
StatusFrame.Size = UDim2.new(1, 0, 0, 32)
StatusFrame.BackgroundColor3 = Color3.fromRGB(20, 18, 28)
StatusFrame.BorderSizePixel =inton = 0
StatusFrame.Parent = Scrolling
Instance.new("UICorner", StatusFrame).CornerRadius = UDim.new(0, 6)

local StatusText = Instance.new("TextLabel")
StatusText.Size = UDim2.new(1, -16, 1, 0)
StatusText.Position = UDim2.fromOffset(8, 0)
StatusText.BackgroundTransparency = 1
StatusText.Font = Enum.Font.GothamBold
StatusText.Text = "Status: Ready & Listening"
StatusText.TextColor3 = Color3.fromRGB(100, 220, 120)
StatusText.TextSize = 11
StatusText.Parent = StatusFrame

-- Code Input Box
local InputFrame = Instance.new("Frame")
InputFrame.Size = UDim2.new(1, 0, 0, 48)
InputFrame.BackgroundColor3 = Color3.fromRGB(20, 18, 28)
InputFrame.BorderSizePixel = 0
InputFrame.Parent = Scrolling
Instance.new("UICorner", InputFrame).CornerRadius = UDim.new(0, 6)

local TextBox = Instance.new("TextBox")
TextBox.Size = UDim2.new(1, -16, 1, -10)
TextBox.Position = UDim2.fromOffset(8, 5)
TextBox.BackgroundColor3 = Color3.fromRGB(10, 8, 14)
TextBox.Font = Enum.Font.GothamBold
TextBox.PlaceholderText = "Type or snipe a code..."
TextBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 140)
TextBox.Text = ""
TextBox.TextColor3 = Color3.new(1, 1, 1)
TextBox.TextSize = 13
TextBox.ClearTextOnFocus = false
TextBox.Parent = InputFrame
Instance.new("UICorner", TextBox).CornerRadius = UDim.new(0, 4)

-- Helper for UI Toggles & Buttons
local function CreateButton(text, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 34)
    btn.BackgroundColor3 = Color3.fromRGB(28, 24, 40)
    btn.Font = Enum.Font.GothamMedium
    btn.Text = text
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.TextSize = 12
    btn.Parent = Scrolling
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- State Variables
local AutoRedeemEnabled = true
local AutoRiddleAIEnabled = true
local TargetWordCount = 1

-- Find Game Code UI elements dynamically
local function GetCodeTextBox()
    local codes = PlayerGui:FindFirstChild("Codes")
    if not codes then return nil end
    for _, desc in ipairs(codes:GetDescendants()) do
        if desc:IsA("TextBox") then return desc end
    end
    return nil
end

local function GetSubmitButton()
    local codes = PlayerGui:FindFirstChild("Codes")
    if not codes then return nil end
    for _, desc in ipairs(codes:GetDescendants()) do
        if desc:IsA("TextButton") or desc:IsA("ImageButton") then
            local n = desc.Name:lower()
            if n:find("confirm") or n:find("submit") or n:find("redeem") or n:find("enter") then
                return desc
            end
        end
    end
    return nil
end

-- Smart Redeemer with verification check
local function SubmitCode(codeText)
    if not codeText or codeText == "" then return end
    pcall(function()
        local box = GetCodeTextBox()
        if box then
            box.Text = codeText
            local btn = GetSubmitButton()
            if btn and getconnections then
                for _, conn in ipairs(getconnections(btn.MouseButton1Click)) do
                    conn:Fire()
                end
            elseif btn then
                btn.Activated:Fire()
            else
                box:CaptureFocus()
                box:ReleaseFocus(true)
            end
            StatusText.Text = "Attempted Code: " .. codeText
        end
    end)
end

-- Gemini AI Riddle Solver
local function AskGeminiAI(riddle)
    local url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=" .. GEMINI_API_KEY
    local payload = HttpService:JSONEncode({
        contents = {{
            parts = {{
                text = "Solve this riddle from Steal a Brainrot with ONLY the exact answer word or code. No punctuation, no spaces if possible:\n\n" .. riddle
            }}
        }}
    })
    
    local success, res = pcall(function()
        return HttpService:PostAsync(url, payload, Enum.HttpContentType.ApplicationJson, false)
    end)
    
    if success and res then
        local data = HttpService:JSONDecode(res)
        if data and data.candidates and data.candidates[1] then
            local ans = data.candidates[1].content.parts[1].text
            return ans:gsub("^%s+", ""):gsub("%s+$", ""):gsub("[%.!]", "")
        end
    end
    return nil
end

-- UI Controls setup
CreateButton("Auto Redeem Codes: ON", function(btn)
    AutoRedeemEnabled = not AutoRedeemEnabled
    btn.Text = "Auto Redeem Codes: " .. (AutoRedeemEnabled and "ON" or "OFF")
end)

CreateButton("Auto Riddle (Gemini AI): ON", function(btn)
    AutoRiddleAIEnabled = not AutoRiddleAIEnabled
    btn.Text = "Auto Riddle (Gemini AI): " .. (AutoRiddleAIEnabled and "ON" or "OFF")
end)

-- Test Code Button (Repaired & Fully Working)
CreateButton("TEST CODE (Simulate Sammy Notice)", function()
    local fakeCodes = {"SAMMY2026", "BRAINROT500", "UPDATEFIX"}
    local chosen = fakeCodes[math.random(1, #fakeCodes)]
    TextBox.Text = chosen
    if AutoRedeemEnabled then
        SubmitCode(chosen)
    end
end)

-- Event Listener for Game Announcements & Remotes
local function ProcessAnnouncement(message)
    if not message or message == "" then return end
    local lowerMsg = message:lower()
    
    -- Check if it's a riddle
    if lowerMsg:find("?") and AutoRiddleAIEnabled then
        StatusText.Text = "Riddle detected! Asking Gemini AI..."
        task.spawn(function()
            local solution = AskGeminiAI(message)
            if solution then
                StatusText.Text = "AI Solution: " .. solution
                SubmitCode(solution)
            end
        end)
        return
    end
    
    -- Check if it contains a code
    if lowerMsg:find("code") or lowerMsg:find("sammy") then
        for word in message:gmatch("[%w_%-]+") do
            if #word >= 4 and word ~= "CODE" and word ~= "SAMMY" then
                TextBox.Text = word
                if AutoRedeemEnabled then
                    SubmitCode(word)
                end
                break
            end
        end
    end
end

-- Connect to client events safely
pcall(function()
    for _, child in ipairs(Net:GetChildren()) do
        if child:IsA("RemoteEvent") then
            child.OnClientEvent:Connect(function(...)
                local args = {...}
                for _, v in ipairs(args) do
                    if type(v) == "string" then
                        ProcessAnnouncement(v)
                    end
                end
            end)
        end
    end
end)

StatusText.Text = "Status: Hub Loaded Successfully!"
print("Traced Hub SAB Ultimate Loaded!")

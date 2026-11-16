--[[ SAB AutoTrade v2 — acepta y da ready solo, sin ocultar nada ]]
local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local LP      = Players.LocalPlayer
local PG      = LP:WaitForChild("PlayerGui")

local ON, CD  = true, 0.25
local fired   = {}
local count   = 0

local ACCEPT_WORDS = {"accept","aceptar","confirm","confirmar"}
local READY_WORDS  = {"ready","listo","preparado"}

local function hit(txt, words)
	txt = string.lower(txt)
	for _, w in ipairs(words) do
		if string.find(txt, w, 1, true) then return true end
	end
	return false
end

local function click(btn)
	local t = os.clock()
	if (fired[btn] or 0) + CD > t then return end
	fired[btn] = t
	local ok = false
	for _, c in ipairs(getconnections(btn.MouseButton1Click)) do
		if pcall(c.Fire, c) then ok = true end
	end
	if not ok then pcall(function() btn:Activate() end) end
end

local function remoteFallback(word)
	for _, o in ipairs(RS:GetDescendants()) do
		if o:IsA("RemoteEvent") and string.find(string.lower(o.Name), string.lower(word), 1, true) then
			pcall(function() o:FireServer() end)
		end
	end
end

local function scan()
	for _, d in ipairs(PG:GetDescendants()) do
		if d:IsA("TextButton") and d.Visible and d.AbsoluteSize.X > 10 then
			local txt = d.Text or ""
			if hit(txt, ACCEPT_WORDS) then
				click(d); remoteFallback("Accept")
			elseif hit(txt, READY_WORDS) then
				click(d); remoteFallback("Ready")
			end
		end
	end
end

task.spawn(function()
	while task.wait(0.1) do
		if ON then pcall(scan) end
	end
end)

task.spawn(function()
	for _, o in ipairs(RS:GetDescendants()) do
		if o:IsA("RemoteEvent") and string.find(string.lower(o.Name), "tradecompleted", 1, true) then
			o.OnClientEvent:Connect(function() count += 1 end)
		end
	end
end)

-- panel mínimo
local gui = Instance.new("ScreenGui")
gui.Name = "SAB_AutoTrade"
gui.ResetOnSpawn = false
gui.Parent = PG

local f = Instance.new("Frame")
f.Size = UDim2.fromOffset(150, 66)
f.Position = UDim2.new(0, 12, 0.5, -33)
f.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
f.BorderSizePixel = 0
f.Active = true
f.Parent = gui
Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)

local lbl = Instance.new("TextLabel")
lbl.Size = UDim2.new(1, -12, 0, 18)
lbl.Position = UDim2.new(0, 6, 0, 4)
lbl.BackgroundTransparency = 1
lbl.Font = Enum.Font.GothamBold
lbl.TextSize = 12
lbl.TextColor3 = Color3.fromRGB(120, 235, 150)
lbl.TextXAlignment = Enum.TextXAlignment.Left
lbl.Text = "AUTOTRADE  ON"
lbl.Parent = f

local cnt = Instance.new("TextLabel")
cnt.Size = UDim2.new(1, -12, 0, 14)
cnt.Position = UDim2.new(0, 6, 0, 24)
cnt.BackgroundTransparency = 1
cnt.Font = Enum.Font.Gotham
cnt.TextSize = 11
cnt.TextColor3 = Color3.fromRGB(170, 170, 180)
cnt.TextXAlignment = Enum.TextXAlignment.Left
cnt.Text = "trades: 0"
cnt.Parent = f

local btn = Instance.new("TextButton")
btn.Size = UDim2.new(1, -12, 0, 20)
btn.Position = UDim2.new(0, 6, 1, -26)
btn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
btn.BorderSizePixel = 0
btn.Font = Enum.Font.GothamBold
btn.TextSize = 11
btn.TextColor3 = Color3.fromRGB(240, 240, 240)
btn.Text = "APAGAR"
btn.Parent = f
Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

btn.MouseButton1Click:Connect(function()
	ON = not ON
	lbl.Text = ON and "AUTOTRADE  ON" or "AUTOTRADE  OFF"
	lbl.TextColor3 = ON and Color3.fromRGB(120, 235, 150) or Color3.fromRGB(235, 120, 120)
	btn.Text = ON and "APAGAR" or "PRENDER"
end)

task.spawn(function()
	while task.wait(0.25) do cnt.Text = "trades: " .. count end
end)

-- arrastrar
local drag, start, pos0
f.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
		drag, start, pos0 = true, i.Position, f.Position
	end
end)
f.InputChanged:Connect(function(i)
	if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
		local d = i.Position - start
		f.Position = UDim2.new(pos0.X.Scale, pos0.X.Offset + d.X, pos0.Y.Scale, pos0.Y.Offset + d.Y)
	end
end)
f.InputEnded:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
		drag = false
	end
end)

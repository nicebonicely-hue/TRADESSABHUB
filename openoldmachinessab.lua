--[[
    ============================================================================
    PROYECTO: SAB LEGACY MACHINE SCANNER & OPENER
    Compatibilidad: Delta Executor / Luau (Roblox - Steal a Brainrot)
    Arquitectura:
      1. Catalogo historico de maquinas (Fusion, Fabricacion, Mutacion, Eventos).
      2. Escaner recursivo anti-lag (Workspace + inspeccion residual).
      3. Clasificador de 4 estados reales (Activa, Desactivada, Incompleta, Detectada).
      4. Localizador 3D (Highlight + BillboardGui a traves de paredes).
      5. Sistema de interaccion nativo con verificacion real de respuesta en PlayerGui.
    ============================================================================
]]

-- Limpieza de ejecucion previa
if _G.SAB_LegacyScanner then
    pcall(function()
        _G.SAB_LegacyScanner.Cleanup()
    end)
end

-- ============================================================================
-- SECCION 1: SERVICIOS Y REFERENCIAS BASE
-- ============================================================================
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 5)

-- ============================================================================
-- SECCION 2: BASE DE DATOS DE MAQUINAS E IDENTIFICADORES INVESTIGADOS
-- ============================================================================
local MACHINE_CATALOG = {
    {
        category = "Fusion / Bruja",
        displayName = "Witch Cauldron / Haunted Fuse",
        keywords = {"witchcauldron", "hauntedfuse", "witchmachine", "cauldron", "spookyfuse", "witch", "bruja", "caldera"},
    },
    {
        category = "Fusion",
        displayName = "Fuse Machine (Estandar)",
        keywords = {"fusemachine", "fusionmachine", "fusestation", "merger", "combinemachine", "fuse", "fusion"},
    },
    {
        category = "Fabricacion (Crafting)",
        displayName = "Crafting Machine",
        keywords = {"craftingmachine", "craftmachine", "crafter", "craftstation", "recipemachine", "workbench", "crafting", "fabricacion"},
    },
    {
        category = "Mutacion Permanente",
        displayName = "Rainbow Machine",
        keywords = {"rainbowmachine", "rainbowstation", "rainbowizer", "rainbowmaker"},
    },
    {
        category = "Mutacion / Evento",
        displayName = "Mutation / Trait Machine",
        keywords = {"mutationmachine", "mutator", "traitmachine", "rerollmachine", "upgrademachine"},
    },
    {
        category = "Evento Eclipse / Crystal / Cyber",
        displayName = "Event Mutation Station",
        keywords = {"eclipsemachine", "crystalmachine", "cybermachine", "candymachine", "galaxymachine", "lavamachine", "bloodrotmachine", "divinemachine", "cursedmachine", "phantommachine", "yinyangmachine"},
    },
    {
        category = "Especial / Dispensador",
        displayName = "Bubblegum / Gacha Machine",
        keywords = {"bubblegummachine", "bubblegum", "gumballmachine", "gachamachine", "vendingmachine", "dispenser", "clawmachine"},
    },
    {
        category = "Evento Temporal / Altar",
        displayName = "Lucky Block / Wheel / Shrine",
        keywords = {"luckyblockmachine", "skullmachine", "spinwheel", "eventwheel", "altar", "shrine", "ritualmachine", "gravehunt", "timemachine", "portalmachine"},
    },
}

-- Palabras genericas que indican que un modelo es una maquina aunque tenga nombre nuevo
local GENERIC_MACHINE_TOKENS = {
    "machine", "maquina", "cauldron", "crafter", "station", "altar", "dispenser", "incubator", "reactor"
}

-- Exclusiones para NO confundir pedestales normales de compra de la pasarela ni jugadores con maquinas
local EXCLUDED_NAMES = {
    baseplate = true, terrain = true, camera = true,
    humanoidrootpart = true, head = true, torso = true,
}

-- ============================================================================
-- SECCION 3: ESTADOS Y COLORES DE CLASIFICACION
-- ============================================================================
local STATUS = {
    ACTIVE = {
        id = "ACTIVA",
        label = "Aparentemente Activa (Con Interaccion)",
        color = Color3.fromRGB(46, 204, 113), -- Verde
        bgColor = Color3.fromRGB(24, 52, 36),
        order = 1,
    },
    DISABLED = {
        id = "DESACTIVADA",
        label = "Aparentemente Desactivada (Prompt OFF / Oculta)",
        color = Color3.fromRGB(243, 156, 18), -- Ambar / Naranja
        bgColor = Color3.fromRGB(58, 42, 20),
        order = 2,
    },
    INCOMPLETE = {
        id = "INCOMPLETA",
        label = "Incompleta / Sin Interaccion (Residual)",
        color = Color3.fromRGB(231, 76, 60), -- Rojo Coral
        bgColor = Color3.fromRGB(56, 24, 24),
        order = 3,
    },
    DETECTED = {
        id = "ENCONTRADA",
        label = "Maquina Encontrada (Estructura / Atributos)",
        color = Color3.fromRGB(52, 152, 219), -- Azul
        bgColor = Color3.fromRGB(22, 42, 58),
        order = 4,
    },
}

local STATE = {
    alive = true,
    isScanning = false,
    autoScan = false,
    autoScanInterval = 10,
    includeReplicatedStorage = true,
    machines = {},         -- Lista de registros detectados
    selectedEntry = nil,   -- Maquina seleccionada actualmente en la UI
    activeHighlight = nil, -- Instancia Highlight actual
    activeBillboard = nil, -- Instancia BillboardGui actual
    connections = {},
}

-- ============================================================================
-- SECCION 4: FUNCIONES AUXILIARES Y ANALISIS GEOMETRICO
-- ============================================================================
local function normalizeText(str)
    return tostring(str or ""):lower():gsub("[%s_%-%p]+", "")
end

local function isPlayerCharacter(model)
    if not model or not model:IsA("Model") then return false end
    if Players:GetPlayerFromCharacter(model) then return true end
    if model:FindFirstChildOfClass("Humanoid") and model:FindFirstChild("HumanoidRootPart") then
        return true
    end
    return false
end

local function getInstancePosition(inst)
    if not inst then return nil end
    if inst:IsA("BasePart") then
        return inst.Position
    elseif inst:IsA("Model") then
        local ok, pivot = pcall(function() return inst:GetPivot().Position end)
        if ok and pivot then return pivot end
        local part = inst:FindFirstChildWhichIsA("BasePart", true)
        if part then return part.Position end
    elseif inst:IsA("Attachment") then
        return inst.WorldPosition
    else
        local parentPart = inst:FindFirstAncestorWhichIsA("BasePart")
        if parentPart then return parentPart.Position end
        local parentModel = inst:FindFirstAncestorWhichIsA("Model")
        if parentModel then
            local ok, pivot = pcall(function() return parentModel:GetPivot().Position end)
            if ok and pivot then return pivot end
        end
    end
    return nil
end

local function getDistanceFromPlayer(pos)
    if not pos then return nil end
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    return (hrp.Position - pos).Magnitude
end

local function isOutOfBounds(pos)
    if not pos then return true, "Sin coordenadas 3D" end
    if pos.Y < -35 then
        return true, string.format("Bajo el mapa (Y=%.0f)", pos.Y)
    end
    if pos.Y > 450 then
        return true, string.format("En el cielo (Y=%.0f)", pos.Y)
    end
    if math.abs(pos.X) > 1500 or math.abs(pos.Z) > 1500 then
        return true, string.format("Fuera de limites (X=%.0f, Z=%.0f)", pos.X, pos.Z)
    end
    return false, string.format("Mapa (%.0f, %.0f, %.0f)", pos.X, pos.Y, pos.Z)
end

-- ============================================================================
-- SECCION 5: MOTOR DE DETECCION Y CLASIFICACION PROFUNDA
-- ============================================================================

-- Determina la raiz logica de la maquina para no duplicar sus piezas internas
local function resolveMachineRoot(inst)
    local curr = inst
    local bestCandidate = inst

    for _ = 1, 6 do
        if not curr or curr == Workspace or curr == ReplicatedStorage then
            break
        end
        if curr:IsA("Model") or curr:IsA("Folder") then
            local lower = curr.Name:lower()
            if lower ~= "workspace" and lower ~= "map" and lower ~= "machines"
                and lower ~= "models" and lower ~= "assets" and lower ~= "events"
                and lower ~= "world" then
                bestCandidate = curr
            end
        end
        curr = curr.Parent
    end
    return bestCandidate
end

-- Analiza nombres, atributos y textos internos para determinar si es una maquina
local function identifyMachineType(rootInst, prompts, clickDetectors, guiTexts)
    local combinedRaw = rootInst.Name .. " " .. (rootInst.Parent and rootInst.Parent.Name or "")

    -- Añadir atributos del objeto raiz
    local okAttr, attrs = pcall(function() return rootInst:GetAttributes() end)
    local attrSummary = {}
    if okAttr and attrs then
        for k, v in pairs(attrs) do
            combinedRaw = combinedRaw .. " " .. tostring(k) .. " " .. tostring(v)
            attrSummary[#attrSummary + 1] = tostring(k) .. "=" .. tostring(v)
        end
    end

    -- Añadir textos de ProximityPrompts
    for _, p in ipairs(prompts) do
        local action = (p.ActionText or ""):lower()
        -- Descartar pedestales normales de compra de Brainrots en la pasarela
        if (action == "buy" or action == "comprar" or action == "purchase")
            and not combinedRaw:lower():find("machine") then
            return nil
        end
        combinedRaw = combinedRaw .. " " .. (p.ActionText or "") .. " " .. (p.ObjectText or "")
    end

    -- Añadir textos de carteles (BillboardGui / SurfaceGui)
    for _, txt in ipairs(guiTexts) do
        combinedRaw = combinedRaw .. " " .. txt
    end

    local norm = normalizeText(combinedRaw)

    -- 1. Comparar contra el catalogo investigado de Steal a Brainrot
    for _, item in ipairs(MACHINE_CATALOG) do
        for _, kw in ipairs(item.keywords) do
            if norm:find(kw, 1, true) then
                return {
                    category = item.category,
                    matchedType = item.displayName,
                    matchedKeyword = kw,
                    attributesText = (#attrSummary > 0) and table.concat(attrSummary, ", ") or "Ninguno",
                }
            end
        end
    end

    -- 2. Comparar contra tokens genericos de maquinas
    for _, token in ipairs(GENERIC_MACHINE_TOKENS) do
        if norm:find(token, 1, true) then
            return {
                category = "Maquina / Estacion",
                matchedType = "Maquina Detectada (" .. rootInst.Name .. ")",
                matchedKeyword = token,
                attributesText = (#attrSummary > 0) and table.concat(attrSummary, ", ") or "Ninguno",
            }
        end
    end

    return nil
end

-- Inspecciona la estructura interna de un candidato (Prompts, ClickDetectors, Visibilidad)
local function inspectCandidate(rootInst, containerName)
    if not rootInst or not rootInst.Parent then return nil end
    if EXCLUDED_NAMES[rootInst.Name:lower()] or isPlayerCharacter(rootInst) then
        return nil
    end

    local prompts = {}
    local clickDetectors = {}
    local guiTexts = {}
    local totalParts = 0
    local hiddenParts = 0

    local descendants = {}
    pcall(function()
        descendants = rootInst:GetDescendants()
    end)

    if rootInst:IsA("ProximityPrompt") then
        prompts[#prompts + 1] = rootInst
    elseif rootInst:IsA("ClickDetector") then
        clickDetectors[#clickDetectors + 1] = rootInst
    elseif rootInst:IsA("BasePart") then
        totalParts = 1
        if rootInst.Transparency >= 0.95 then hiddenParts = 1 end
    end

    for _, d in ipairs(descendants) do
        if d:IsA("ProximityPrompt") then
            prompts[#prompts + 1] = d
        elseif d:IsA("ClickDetector") then
            clickDetectors[#clickDetectors + 1] = d
        elseif d:IsA("TextLabel") and d.Text ~= "" and #d.Text <= 60 then
            guiTexts[#guiTexts + 1] = d.Text
        elseif d:IsA("BasePart") then
            totalParts = totalParts + 1
            if d.Transparency >= 0.95 then
                hiddenParts = hiddenParts + 1
            end
        end
    end

    local matchInfo = identifyMachineType(rootInst, prompts, clickDetectors, guiTexts)
    if not matchInfo then
        return nil
    end

    -- Evaluar estado de interaccion
    local enabledPrompts = 0
    local disabledPrompts = 0
    for _, p in ipairs(prompts) do
        if p.Enabled then
            enabledPrompts = enabledPrompts + 1
        else
            disabledPrompts = disabledPrompts + 1
        end
    end

    local pos = getInstancePosition(rootInst)
    local outOfMap, zoneText = isOutOfBounds(pos)
    local isMostlyInvisible = (totalParts > 0) and ((hiddenParts / totalParts) >= 0.85)

    -- Clasificacion rigurosa en los 4 estados solicitados
    local statusObj = STATUS.DETECTED

    if containerName ~= "Workspace" then
        statusObj = STATUS.INCOMPLETE
        zoneText = "Archivo en " .. containerName .. " (No instanciada en el mapa)"
    elseif enabledPrompts > 0 or #clickDetectors > 0 then
        if outOfMap or isMostlyInvisible then
            statusObj = STATUS.DISABLED
        else
            statusObj = STATUS.ACTIVE
        end
    elseif disabledPrompts > 0 then
        statusObj = STATUS.DISABLED
    elseif totalParts == 0 or (#prompts == 0 and #clickDetectors == 0) then
        statusObj = STATUS.INCOMPLETE
    end

    return {
        instance = rootInst,
        name = rootInst.Name,
        fullName = rootInst:GetFullName(),
        container = containerName,
        category = matchInfo.category,
        machineType = matchInfo.matchedType,
        attributesText = matchInfo.attributesText,
        status = statusObj,
        position = pos,
        zoneText = zoneText,
        outOfMap = outOfMap,
        isInvisible = isMostlyInvisible,
        prompts = prompts,
        clickDetectors = clickDetectors,
        enabledPrompts = enabledPrompts,
        disabledPrompts = disabledPrompts,
        guiSummary = (#guiTexts > 0) and table.concat(guiTexts, " | "):sub(1, 90) or "Sin texto UI",
    }
end

-- Escaner recursivo por lotes para evitar congelamientos (Zero Lag)
local function performFullScan(onProgress, onComplete)
    if STATE.isScanning then return end
    STATE.isScanning = true

    task.spawn(function()
        local foundMap = {}
        local candidateRoots = {}

        local function collectFromContainer(container, label)
            local ok, list = pcall(function() return container:GetDescendants() end)
            if not ok or not list then return end

            for i, inst in ipairs(list) do
                if not STATE.alive then break end
                if i % 450 == 0 then
                    if onProgress then
                        onProgress(string.format("Escaneando %s (%d/%d)...", label, i, #list))
                    end
                    task.wait()
                end

                if inst:IsA("Model") or inst:IsA("Folder") or inst:IsA("ProximityPrompt") or inst:IsA("ClickDetector") then
                    local normName = normalizeText(inst.Name)
                    local shouldInspect = false

                    if inst:IsA("ProximityPrompt") or inst:IsA("ClickDetector") then
                        shouldInspect = true
                    else
                        for _, cat in ipairs(MACHINE_CATALOG) do
                            for _, kw in ipairs(cat.keywords) do
                                if normName:find(kw, 1, true) then
                                    shouldInspect = true
                                    break
                                end
                            end
                            if shouldInspect then break end
                        end
                        if not shouldInspect then
                            for _, tok in ipairs(GENERIC_MACHINE_TOKENS) do
                                if normName:find(tok, 1, true) then
                                    shouldInspect = true
                                    break
                                end
                            end
                        end
                    end

                    if shouldInspect then
                        local root = resolveMachineRoot(inst)
                        if root and not candidateRoots[root] then
                            candidateRoots[root] = label
                        end
                    end
                end
            end
        end

        collectFromContainer(Workspace, "Workspace")
        if STATE.includeReplicatedStorage then
            collectFromContainer(ReplicatedStorage, "ReplicatedStorage")
        end

        local results = {}
        local count = 0
        for root, containerLabel in pairs(candidateRoots) do
            if not STATE.alive then break end
            count = count + 1
            if count % 25 == 0 then task.wait() end

            local entry = inspectCandidate(root, containerLabel)
            if entry and not foundMap[entry.fullName] then
                foundMap[entry.fullName] = true
                results[#results + 1] = entry
            end
        end

        table.sort(results, function(a, b)
            if a.status.order ~= b.status.order then
                return a.status.order < b.status.order
            end
            return a.name:lower() < b.name:lower()
        end)

        STATE.machines = results
        STATE.isScanning = false

        if onComplete then
            onComplete(results)
        end
    end)
end

-- ============================================================================
-- SECCION 6: LOCALIZADOR VISUAL 3D (ESP / HIGHLIGHT)
-- ============================================================================
local function clearVisualLocator()
    if STATE.activeHighlight then
        pcall(function() STATE.activeHighlight:Destroy() end)
        STATE.activeHighlight = nil
    end
    if STATE.activeBillboard then
        pcall(function() STATE.activeBillboard:Destroy() end)
        STATE.activeBillboard = nil
    end
end

local function locateMachineVisually(entry, statusCallback)
    clearVisualLocator()

    if not entry or not entry.instance or not entry.instance.Parent then
        statusCallback("El objeto ya no existe en el juego.", Color3.fromRGB(231, 76, 60))
        return
    end

    if entry.container ~= "Workspace" then
        statusCallback("Esta maquina reside en ReplicatedStorage (no tiene posicion 3D en el mapa).", Color3.fromRGB(243, 156, 18))
        return
    end

    local target = entry.instance
    local pos = getInstancePosition(target)
    if not pos then
        statusCallback("La maquina no contiene piezas 3D (BaseParts) para resaltar.", Color3.fromRGB(231, 76, 60))
        return
    end

    -- 1. Crear Highlight 3D visible a traves de paredes
    local hl = Instance.new("Highlight")
    hl.Name = "SAB_MachineHighlight"
    hl.Adornee = target
    hl.FillColor = entry.status.color
    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
    hl.FillTransparency = 0.45
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = target
    STATE.activeHighlight = hl

    -- 2. Crear etiqueta flotante 3D (BillboardGui)
    local adorneePart = target:IsA("BasePart") and target or target:FindFirstChildWhichIsA("BasePart", true)
    if adorneePart then
        local bb = Instance.new("BillboardGui")
        bb.Name = "SAB_MachineTag"
        bb.Adornee = adorneePart
        bb.Size = UDim2.new(0, 220, 0, 54)
        bb.StudsOffset = Vector3.new(0, 4.5, 0)
        bb.AlwaysOnTop = true
        bb.Parent = adorneePart

        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 1, 0)
        frame.BackgroundColor3 = Color3.fromRGB(14, 14, 20)
        frame.BackgroundTransparency = 0.15
        frame.BorderSizePixel = 0
        frame.Parent = bb
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)

        local stroke = Instance.new("UIStroke")
        stroke.Color = entry.status.color
        stroke.Thickness = 1.5
        stroke.Parent = frame

        local txt = Instance.new("TextLabel")
        txt.Size = UDim2.new(1, -8, 1, -4)
        txt.Position = UDim2.new(0, 4, 0, 2)
        txt.BackgroundTransparency = 1
        txt.TextColor3 = Color3.fromRGB(245, 245, 250)
        txt.Font = Enum.Font.GothamBold
        txt.TextSize = 11
        txt.TextWrapped = true
        local dist = getDistanceFromPlayer(pos)
        txt.Text = string.format(
            "[%s]\n%s (%s)",
            entry.status.id,
            entry.name,
            dist and string.format("%.0f studs", dist) or entry.zoneText
        )
        txt.Parent = frame

        STATE.activeBillboard = bb
    end

    statusCallback("Localizador 3D activado sobre: " .. entry.name, Color3.fromRGB(46, 204, 113))
end

-- ============================================================================
-- SECCION 7: SISTEMA DE INTERACCION REAL Y VERIFICACION DE APERTURA
-- ============================================================================

-- Toma una captura del estado actual de PlayerGui para comprobar si la maquina abrio una ventana real
local function captureGuiSnapshot()
    local snapshot = {}
    if not PlayerGui then return snapshot end
    for _, d in ipairs(PlayerGui:GetDescendants()) do
        if d:IsA("ScreenGui") then
            snapshot[d] = d.Enabled
        elseif d:IsA("GuiObject") then
            snapshot[d] = d.Visible
        end
    end
    return snapshot
end

local function detectGuiChange(beforeSnapshot)
    if not PlayerGui then return false, nil end
    for _, d in ipairs(PlayerGui:GetDescendants()) do
        if d:IsA("ScreenGui") then
            if beforeSnapshot[d] == nil and d.Enabled then
                return true, "Nueva ScreenGui: " .. d.Name
            elseif beforeSnapshot[d] == false and d.Enabled == true then
                return true, "ScreenGui activada: " .. d.Name
            end
        elseif d:IsA("Frame") or d:IsA("ImageLabel") or d:IsA("CanvasGroup") then
            if beforeSnapshot[d] == false and d.Visible == true and d.AbsoluteSize.X > 120 and d.AbsoluteSize.Y > 120 then
                return true, "Ventana abierta: " .. d.Name
            end
        end
    end
    return false, nil
end

local function triggerNativePrompt(prompt)
    if type(fireproximityprompt) == "function" then
        local ok = pcall(fireproximityprompt, prompt)
        if ok then return true, "fireproximityprompt" end
    end
    local okHold = pcall(function()
        prompt:InputHoldBegin()
        task.wait(math.clamp(prompt.HoldDuration, 0.05, 0.25))
        prompt:InputHoldEnd()
    end)
    if okHold then return true, "InputHoldBegin/End" end
    return false, "Funcion no soportada"
end

local function triggerNativeClick(cd)
    if type(fireclickdetector) == "function" then
        local ok = pcall(fireclickdetector, cd)
        if ok then return true, "fireclickdetector" end
    end
    return false, "fireclickdetector no disponible"
end

local function attemptOpenMachine(entry, allowTeleport, statusCallback)
    if not entry or not entry.instance or not entry.instance.Parent then
        statusCallback("Error: El objeto ya no existe en Workspace.", Color3.fromRGB(231, 76, 60))
        return
    end

    if entry.container ~= "Workspace" then
        statusCallback(
            "No interactuable: El modelo esta guardado en ReplicatedStorage, no en el mapa.",
            Color3.fromRGB(231, 76, 60)
        )
        return
    end

    local prompts = entry.prompts or {}
    local clickDetectors = entry.clickDetectors or {}

    if #prompts == 0 and #clickDetectors == 0 then
        statusCallback(
            "Resultado: Maquina incompleta/retirada. No tiene ProximityPrompt ni ClickDetector.",
            Color3.fromRGB(231, 76, 60)
        )
        return
    end

    task.spawn(function()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local pos = getInstancePosition(entry.instance)

        -- Verificar distancia: Roblox ignora ProximityPrompts en el servidor si estas lejos de la maquina
        if pos and hrp then
            local dist = (hrp.Position - pos).Magnitude
            if dist > 14 then
                if allowTeleport then
                    statusCallback("Acercando personaje a la maquina para rango valido...", Color3.fromRGB(52, 152, 219))
                    hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3.5, 3))
                    task.wait(0.18)
                else
                    statusCallback(
                        string.format("Aviso: Estas a %.0f studs. Si el servidor valida distancia, activa 'Acercarse al abrir'.", dist),
                        Color3.fromRGB(243, 156, 18)
                    )
                end
            end
        end

        local guiBefore = captureGuiSnapshot()
        local methodUsed = nil
        local wasOriginallyDisabled = false

        -- 1. Intentar con ProximityPrompt
        if #prompts > 0 then
            local targetPrompt = prompts[1]
            for _, p in ipairs(prompts) do
                if p.Enabled then
                    targetPrompt = p
                    break
                end
            end

            local origEnabled = targetPrompt.Enabled
            local origHold = targetPrompt.HoldDuration
            local origDist = targetPrompt.MaxActivationDistance

            if not origEnabled then
                wasOriginallyDisabled = true
                pcall(function() targetPrompt.Enabled = true end)
            end
            pcall(function()
                targetPrompt.HoldDuration = 0
                targetPrompt.MaxActivationDistance = math.max(origDist, 35)
            end)

            local ok, mName = triggerNativePrompt(targetPrompt)
            if ok then methodUsed = mName end

            task.delay(0.3, function()
                pcall(function()
                    targetPrompt.Enabled = origEnabled
                    targetPrompt.HoldDuration = origHold
                    targetPrompt.MaxActivationDistance = origDist
                end)
            end)
        -- 2. Intentar con ClickDetector
        elseif #clickDetectors > 0 then
            local targetCd = clickDetectors[1]
            local origDist = targetCd.MaxActivationDistance
            pcall(function() targetCd.MaxActivationDistance = math.max(origDist, 50) end)
            local ok, mName = triggerNativeClick(targetCd)
            if ok then methodUsed = mName end
            task.delay(0.3, function()
                pcall(function() targetCd.MaxActivationDistance = origDist end)
            end)
        end

        if not methodUsed then
            statusCallback("Fallo: Tu ejecutor no pudo disparar la interaccion nativa.", Color3.fromRGB(231, 76, 60))
            return
        end

        statusCallback("Interaccion enviada (" .. methodUsed .. "). Esperando respuesta del servidor...", Color3.fromRGB(52, 152, 219))

        -- Esperar hasta 1.0s comprobando si el servidor o el cliente abrieron una interfaz real
        local openedGui, guiDetail = false, nil
        for _ = 1, 10 do
            task.wait(0.1)
            openedGui, guiDetail = detectGuiChange(guiBefore)
            if openedGui then break end
        end

        if openedGui then
            statusCallback("Exito confirmado: Se abrio " .. tostring(guiDetail), Color3.fromRGB(46, 204, 113))
        elseif wasOriginallyDisabled then
            statusCallback(
                "Sin respuesta: El Prompt estaba desactivado y el servidor rechazo la apertura (Evento inactivo).",
                Color3.fromRGB(243, 156, 18)
            )
        else
            statusCallback(
                "Señal enviada sin cambio de GUI: La maquina requiere tener un Brainrot equipado o fue deshabilitada en el servidor.",
                Color3.fromRGB(243, 156, 18)
            )
        end
    end)
end

-- ============================================================================
-- SECCION 8: INTERFAZ GRAFICA MODERNA (GUI)
-- ============================================================================
local guiParent = (type(gethui) == "function" and select(2, pcall(gethui))) or CoreGui

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SAB_LegacyMachineScanner"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = guiParent

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 540, 0, 430)
mainFrame.Position = UDim2.new(0.5, -270, 0.5, -215)
mainFrame.BackgroundColor3 = Color3.fromRGB(16, 17, 22)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 8)

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(45, 48, 62)
mainStroke.Thickness = 1
mainStroke.Parent = mainFrame

-- Barra de titulo
local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 34)
topBar.BackgroundColor3 = Color3.fromRGB(24, 26, 34)
topBar.BorderSizePixel = 0
topBar.Parent = mainFrame
Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 8)

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -45, 1, 0)
titleLabel.Position = UDim2.new(0, 12, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "SAB | LEGACY MACHINE SCANNER & OPENER"
titleLabel.TextColor3 = Color3.fromRGB(235, 238, 248)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 12
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = topBar

local btnClose = Instance.new("TextButton")
btnClose.Size = UDim2.new(0, 30, 0, 30)
btnClose.Position = UDim2.new(1, -32, 0, 2)
btnClose.BackgroundTransparency = 1
btnClose.Text = "X"
btnClose.TextColor3 = Color3.fromRGB(235, 85, 85)
btnClose.Font = Enum.Font.GothamBold
btnClose.TextSize = 14
btnClose.Parent = topBar

-- Controles Superiores: SCAN MACHINES | AUTO SCAN | INCLUIR REPLICATEDSTORAGE
local controlsBar = Instance.new("Frame")
controlsBar.Size = UDim2.new(1, -20, 0, 30)
controlsBar.Position = UDim2.new(0, 10, 0, 40)
controlsBar.BackgroundTransparency = 1
controlsBar.Parent = mainFrame

local function createControlBtn(text, xScale, wScale, color)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(wScale, -4, 1, 0)
    b.Position = UDim2.new(xScale, 0, 0, 0)
    b.BackgroundColor3 = color
    b.BorderSizePixel = 0
    b.Text = text
    b.TextColor3 = Color3.fromRGB(245, 245, 250)
    b.Font = Enum.Font.GothamSemibold
    b.TextSize = 11
    b.Parent = controlsBar
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    return b
end

local btnScan = createControlBtn("SCAN MACHINES", 0.00, 0.34, Color3.fromRGB(45, 115, 200))
local btnAutoScan = createControlBtn("AUTO SCAN: OFF", 0.34, 0.32, Color3.fromRGB(52, 55, 68))
local btnToggleRS = createControlBtn("ARCHIVOS (RS): ON", 0.66, 0.34, Color3.fromRGB(42, 85, 115))

-- Barra de Contadores por Estado
local countersBar = Instance.new("TextLabel")
countersBar.Size = UDim2.new(1, -20, 0, 20)
countersBar.Position = UDim2.new(0, 10, 0, 74)
countersBar.BackgroundColor3 = Color3.fromRGB(22, 24, 30)
countersBar.BorderSizePixel = 0
countersBar.Text = " Total: 0  |  Activas: 0  |  Desactivadas: 0  |  Incompletas/Residuales: 0"
countersBar.TextColor3 = Color3.fromRGB(200, 205, 220)
countersBar.Font = Enum.Font.GothamSemibold
countersBar.TextSize = 10
countersBar.TextXAlignment = Enum.TextXAlignment.Left
countersBar.Parent = mainFrame
Instance.new("UICorner", countersBar).CornerRadius = UDim.new(0, 4)

-- Contenedor central dividido: Lista (Izquierda) + Inspector de Seleccion (Derecha)
local listScroll = Instance.new("ScrollingFrame")
listScroll.Size = UDim2.new(0.54, -12, 1, -134)
listScroll.Position = UDim2.new(0, 10, 0, 98)
listScroll.BackgroundColor3 = Color3.fromRGB(12, 13, 17)
listScroll.BorderSizePixel = 0
listScroll.ScrollBarThickness = 4
listScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
listScroll.Parent = mainFrame
Instance.new("UICorner", listScroll).CornerRadius = UDim.new(0, 6)

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 4)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = listScroll

listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    listScroll.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 8)
end)

-- Panel Derecho: Detalles e Interaccion con la Maquina Seleccionada
local detailPanel = Instance.new("Frame")
detailPanel.Size = UDim2.new(0.46, -12, 1, -134)
detailPanel.Position = UDim2.new(0.54, 2, 0, 98)
detailPanel.BackgroundColor3 = Color3.fromRGB(20, 22, 29)
detailPanel.BorderSizePixel = 0
detailPanel.Parent = mainFrame
Instance.new("UICorner", detailPanel).CornerRadius = UDim.new(0, 6)

local detailTitle = Instance.new("TextLabel")
detailTitle.Size = UDim2.new(1, -16, 0, 22)
detailTitle.Position = UDim2.new(0, 8, 0, 6)
detailTitle.BackgroundTransparency = 1
detailTitle.Text = "SELECCIONA UNA MAQUINA"
detailTitle.TextColor3 = Color3.fromRGB(240, 240, 250)
detailTitle.Font = Enum.Font.GothamBold
detailTitle.TextSize = 11
detailTitle.TextXAlignment = Enum.TextXAlignment.Left
detailTitle.TextTruncate = Enum.TextTruncate.AtEnd
detailTitle.Parent = detailPanel

local detailBody = Instance.new("TextLabel")
detailBody.Size = UDim2.new(1, -16, 1, -128)
detailBody.Position = UDim2.new(0, 8, 0, 30)
detailBody.BackgroundTransparency = 1
detailBody.Text = "Haz clic en 'SCAN MACHINES' y selecciona cualquier maquina de la lista para ver su ruta en Workspace, atributos, estado real y opciones de interaccion."
detailBody.TextColor3 = Color3.fromRGB(185, 190, 205)
detailBody.Font = Enum.Font.Gotham
detailBody.TextSize = 10
detailBody.TextWrapped = true
detailBody.TextXAlignment = Enum.TextXAlignment.Left
detailBody.TextYAlignment = Enum.TextYAlignment.Top
detailBody.Parent = detailPanel

local allowTpToOpen = true

local function createActionBtn(text, bottomOffset, color)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -16, 0, 26)
    b.Position = UDim2.new(0, 8, 1, bottomOffset)
    b.BackgroundColor3 = color
    b.BorderSizePixel = 0
    b.Text = text
    b.TextColor3 = Color3.fromRGB(245, 245, 250)
    b.Font = Enum.Font.GothamSemibold
    b.TextSize = 10
    b.Parent = detailPanel
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)
    return b
end

local btnLocate = createActionBtn("LOCALIZAR VISUALMENTE (ESP 3D)", -92, Color3.fromRGB(45, 105, 165))
local btnTpMode = createActionBtn("ACERCARSE AL ABRIR (TP): ON", -62, Color3.fromRGB(60, 85, 110))
local btnOpenMachine = createActionBtn("INTENTAR ABRIR MAQUINA", -32, Color3.fromRGB(40, 140, 80))

-- Barra de estado inferior
local statusBar = Instance.new("TextLabel")
statusBar.Size = UDim2.new(1, -20, 0, 22)
statusBar.Position = UDim2.new(0, 10, 1, -28)
statusBar.BackgroundColor3 = Color3.fromRGB(22, 24, 30)
statusBar.BorderSizePixel = 0
statusBar.Text = " Listo. Presiona 'SCAN MACHINES' para analizar el servidor."
statusBar.TextColor3 = Color3.fromRGB(160, 215, 175)
statusBar.Font = Enum.Font.Gotham
statusBar.TextSize = 10
statusBar.TextXAlignment = Enum.TextXAlignment.Left
statusBar.TextTruncate = Enum.TextTruncate.AtEnd
statusBar.Parent = mainFrame
Instance.new("UICorner", statusBar).CornerRadius = UDim.new(0, 4)

local function setStatus(msg, color)
    if not statusBar or not statusBar.Parent then return end
    statusBar.Text = " " .. tostring(msg)
    statusBar.TextColor3 = color or Color3.fromRGB(200, 205, 220)
end

-- ============================================================================
-- SECCION 9: RENDERIZADO DE RESULTADOS Y SELECCION
-- ============================================================================
local function updateDetailPanel(entry)
    STATE.selectedEntry = entry
    if not entry then
        detailTitle.Text = "SELECCIONA UNA MAQUINA"
        detailTitle.TextColor3 = Color3.fromRGB(240, 240, 250)
        detailBody.Text = "Ninguna maquina seleccionada."
        return
    end

    detailTitle.Text = entry.name:upper()
    detailTitle.TextColor3 = entry.status.color

    local dist = getDistanceFromPlayer(entry.position)
    local distStr = dist and string.format("%.1f studs", dist) or "N/A"

    local interactionSummary = string.format(
        "Prompts Activos: %d | Prompts OFF: %d | ClickDetectors: %d",
        entry.enabledPrompts,
        entry.disabledPrompts,
        #entry.clickDetectors
    )

    detailBody.Text = string.format(
        "Tipo: %s\nCategoria: %s\nEstado: %s\n\nUbicacion: %s\nZona: %s (Dist: %s)\nOculta/Invisible: %s\n\nInteraccion:\n%s\n\nTextos UI: %s\nAtributos: %s",
        entry.machineType,
        entry.category,
        entry.status.label,
        entry.fullName,
        entry.zoneText,
        distStr,
        entry.isInvisible and "Si (Transparencia alta)" or "No",
        interactionSummary,
        entry.guiSummary,
        entry.attributesText
    )
end

local function renderMachineList(results)
    for _, child in ipairs(listScroll:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end

    local cActive, cDisabled, cIncomplete = 0, 0, 0

    for idx, entry in ipairs(results) do
        if entry.status == STATUS.ACTIVE then
            cActive = cActive + 1
        elseif entry.status == STATUS.DISABLED then
            cDisabled = cDisabled + 1
        else
            cIncomplete = cIncomplete + 1
        end

        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, -6, 0, 58)
        card.BackgroundColor3 = entry.status.bgColor
        card.BorderSizePixel = 0
        card.LayoutOrder = idx
        card.Parent = listScroll
        Instance.new("UICorner", card).CornerRadius = UDim.new(0, 6)

        local indicator = Instance.new("Frame")
        indicator.Size = UDim2.new(0, 4, 1, -8)
        indicator.Position = UDim2.new(0, 4, 0, 4)
        indicator.BackgroundColor3 = entry.status.color
        indicator.BorderSizePixel = 0
        indicator.Parent = card
        Instance.new("UICorner", indicator).CornerRadius = UDim.new(0, 2)

        local lblName = Instance.new("TextLabel")
        lblName.Size = UDim2.new(1, -86, 0, 18)
        lblName.Position = UDim2.new(0, 14, 0, 4)
        lblName.BackgroundTransparency = 1
        lblName.Text = string.format("[%s] %s", entry.status.id, entry.name)
        lblName.TextColor3 = entry.status.color
        lblName.Font = Enum.Font.GothamBold
        lblName.TextSize = 10
        lblName.TextXAlignment = Enum.TextXAlignment.Left
        lblName.TextTruncate = Enum.TextTruncate.AtEnd
        lblName.Parent = card

        local lblType = Instance.new("TextLabel")
        lblType.Size = UDim2.new(1, -86, 0, 16)
        lblType.Position = UDim2.new(0, 14, 0, 21)
        lblType.BackgroundTransparency = 1
        lblType.Text = entry.machineType .. " (" .. entry.category .. ")"
        lblType.TextColor3 = Color3.fromRGB(220, 225, 235)
        lblType.Font = Enum.Font.GothamSemibold
        lblType.TextSize = 9
        lblType.TextXAlignment = Enum.TextXAlignment.Left
        lblType.TextTruncate = Enum.TextTruncate.AtEnd
        lblType.Parent = card

        local lblPath = Instance.new("TextLabel")
        lblPath.Size = UDim2.new(1, -86, 0, 15)
        lblPath.Position = UDim2.new(0, 14, 0, 37)
        lblPath.BackgroundTransparency = 1
        lblPath.Text = entry.fullName
        lblPath.TextColor3 = Color3.fromRGB(155, 160, 175)
        lblPath.Font = Enum.Font.Gotham
        lblPath.TextSize = 8
        lblPath.TextXAlignment = Enum.TextXAlignment.Left
        lblPath.TextTruncate = Enum.TextTruncate.AtEnd
        lblPath.Parent = card

        -- Boton Seleccionar en cada tarjeta
        local btnSelect = Instance.new("TextButton")
        btnSelect.Size = UDim2.new(0, 34, 0, 22)
        btnSelect.Position = UDim2.new(1, -74, 0, 6)
        btnSelect.BackgroundColor3 = Color3.fromRGB(38, 42, 54)
        btnSelect.BorderSizePixel = 0
        btnSelect.Text = "Info"
        btnSelect.TextColor3 = Color3.fromRGB(235, 235, 245)
        btnSelect.Font = Enum.Font.GothamSemibold
        btnSelect.TextSize = 9
        btnSelect.Parent = card
        Instance.new("UICorner", btnSelect).CornerRadius = UDim.new(0, 4)

        -- Boton Localizar rapido en cada tarjeta
        local btnQuickEsp = Instance.new("TextButton")
        btnQuickEsp.Size = UDim2.new(0, 34, 0, 22)
        btnQuickEsp.Position = UDim2.new(1, -37, 0, 6)
        btnQuickEsp.BackgroundColor3 = Color3.fromRGB(45, 95, 150)
        btnQuickEsp.BorderSizePixel = 0
        btnQuickEsp.Text = "ESP"
        btnQuickEsp.TextColor3 = Color3.fromRGB(245, 245, 255)
        btnQuickEsp.Font = Enum.Font.GothamSemibold
        btnQuickEsp.TextSize = 9
        btnQuickEsp.Parent = card
        Instance.new("UICorner", btnQuickEsp).CornerRadius = UDim.new(0, 4)

        -- Boton Abrir rapido en cada tarjeta
        local btnQuickOpen = Instance.new("TextButton")
        btnQuickOpen.Size = UDim2.new(0, 71, 0, 20)
        btnQuickOpen.Position = UDim2.new(1, -74, 0, 32)
        btnQuickOpen.BackgroundColor3 = (entry.status == STATUS.ACTIVE)
            and Color3.fromRGB(38, 130, 75)
            or Color3.fromRGB(65, 65, 78)
        btnQuickOpen.BorderSizePixel = 0
        btnQuickOpen.Text = "Abrir / Probar"
        btnQuickOpen.TextColor3 = Color3.fromRGB(240, 240, 245)
        btnQuickOpen.Font = Enum.Font.GothamSemibold
        btnQuickOpen.TextSize = 9
        btnQuickOpen.Parent = card
        Instance.new("UICorner", btnQuickOpen).CornerRadius = UDim.new(0, 4)

        btnSelect.MouseButton1Click:Connect(function()
            updateDetailPanel(entry)
            setStatus("Maquina seleccionada: " .. entry.name, entry.status.color)
        end)

        btnQuickEsp.MouseButton1Click:Connect(function()
            updateDetailPanel(entry)
            locateMachineVisually(entry, setStatus)
        end)

        btnQuickOpen.MouseButton1Click:Connect(function()
            updateDetailPanel(entry)
            attemptOpenMachine(entry, allowTpToOpen, setStatus)
        end)
    end

    countersBar.Text = string.format(
        " Total: %d  |  Activas: %d  |  Desactivadas: %d  |  Incompletas/Residuales: %d",
        #results, cActive, cDisabled, cIncomplete
    )

    if STATE.selectedEntry then
        updateDetailPanel(STATE.selectedEntry)
    elseif results[1] then
        updateDetailPanel(results[1])
    end
end

local function triggerScan()
    if STATE.isScanning then return end
    btnScan.Text = "ESCANEANDO..."
    btnScan.BackgroundColor3 = Color3.fromRGB(90, 95, 110)

    performFullScan(
        function(progressMsg)
            setStatus(progressMsg, Color3.fromRGB(130, 195, 255))
        end,
        function(results)
            if not STATE.alive then return end
            btnScan.Text = "SCAN MACHINES"
            btnScan.BackgroundColor3 = Color3.fromRGB(45, 115, 200)
            renderMachineList(results)
            setStatus(
                string.format("Escaneo completado: %d maquinas encontradas.", #results),
                Color3.fromRGB(46, 204, 113)
            )
        end
    )
end

-- ============================================================================
-- SECCION 10: EVENTOS DE BOTONES Y CICLO AUTO-SCAN
-- ============================================================================
btnScan.MouseButton1Click:Connect(triggerScan)

btnAutoScan.MouseButton1Click:Connect(function()
    STATE.autoScan = not STATE.autoScan
    btnAutoScan.Text = "AUTO SCAN: " .. (STATE.autoScan and "ON" or "OFF")
    btnAutoScan.BackgroundColor3 = STATE.autoScan
        and Color3.fromRGB(40, 135, 80)
        or Color3.fromRGB(52, 55, 68)
    setStatus(
        STATE.autoScan and "Auto-Scan activado (cada 10s)." or "Auto-Scan desactivado.",
        Color3.fromRGB(160, 215, 175)
    )
end)

btnToggleRS.MouseButton1Click:Connect(function()
    STATE.includeReplicatedStorage = not STATE.includeReplicatedStorage
    btnToggleRS.Text = "ARCHIVOS (RS): " .. (STATE.includeReplicatedStorage and "ON" or "OFF")
    btnToggleRS.BackgroundColor3 = STATE.includeReplicatedStorage
        and Color3.fromRGB(42, 85, 115)
        or Color3.fromRGB(52, 55, 68)
    triggerScan()
end)

btnLocate.MouseButton1Click:Connect(function()
    if not STATE.selectedEntry then
        setStatus("Selecciona primero una maquina de la lista.", Color3.fromRGB(243, 156, 18))
        return
    end
    locateMachineVisually(STATE.selectedEntry, setStatus)
end)

btnTpMode.MouseButton1Click:Connect(function()
    allowTpToOpen = not allowTpToOpen
    btnTpMode.Text = "ACERCARSE AL ABRIR (TP): " .. (allowTpToOpen and "ON" or "OFF")
    btnTpMode.BackgroundColor3 = allowTpToOpen
        and Color3.fromRGB(60, 85, 110)
        or Color3.fromRGB(52, 55, 68)
end)

btnOpenMachine.MouseButton1Click:Connect(function()
    if not STATE.selectedEntry then
        setStatus("Selecciona primero una maquina de la lista.", Color3.fromRGB(243, 156, 18))
        return
    end
    attemptOpenMachine(STATE.selectedEntry, allowTpToOpen, setStatus)
end)

-- Bucle controlado para Auto-Scan sin causar lag
task.spawn(function()
    while STATE.alive and screenGui.Parent do
        task.wait(1)
        if STATE.autoScan and not STATE.isScanning then
            local elapsed = 0
            while elapsed < STATE.autoScanInterval and STATE.alive and STATE.autoScan do
                task.wait(0.5)
                elapsed = elapsed + 0.5
            end
            if STATE.alive and STATE.autoScan and not STATE.isScanning then
                triggerScan()
            end
        end
    end
end)

-- ============================================================================
-- SECCION 11: LIMPIEZA TOTAL AL CERRAR
-- ============================================================================
local function cleanupAll()
    if not STATE.alive then return end
    STATE.alive = false
    STATE.autoScan = false
    clearVisualLocator()

    for _, conn in ipairs(STATE.connections) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(STATE.connections)

    if screenGui and screenGui.Parent then
        pcall(function() screenGui:Destroy() end)
    end
end

btnClose.MouseButton1Click:Connect(cleanupAll)
screenGui.Destroying:Connect(cleanupAll)

_G.SAB_LegacyScanner = {
    Cleanup = cleanupAll,
    TriggerScan = triggerScan,
}

-- Ejecutar primer escaneo automatico al iniciar
triggerScan()

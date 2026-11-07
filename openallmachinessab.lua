--[[
    ============================================================================
    PROYECTO: SAB UNIVERSAL INTERACTION (E) & LEGACY MACHINE OPENER v2
    Compatibilidad: Delta Executor | Roblox Luau | Steal a Brainrot (v2648+)
    Mejoras clave v2:
      1. Escanea ABSOLUTAMENTE TODO lo interactuable con la letra E (ProximityPrompts
         y ClickDetectors: "View Trader", "View", "Open", "Bee Lucky Block", Tiendas,
         Incubadoras, Maquinas antiguas y Eventos).
      2. Filtro quirurgico Anti-Basura: Ignora automaticamente todos los Brainrots de la
         pasarela (caminando) y los Brainrots colocados en las bases de los jugadores.
      3. Apertura Directa en 3 modos:
         - FLASH OPEN (Micro-TP de 0.12s + Disparo E + Regreso instantaneo a tu sitio).
         - REMOTO SIN TP (Rango infinito 999999 studs sin mover tu personaje).
         - IR Y QUEDARSE (Teletransporte directo frente al objeto).
      4. Buscador integrado en vivo para filtrar por texto (ej. "view", "trader", "bee", "fuse").
    ============================================================================
]]

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
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 5)

-- ============================================================================
-- SECCION 2: CATALOGO COMPLETO (ACTUALIZADO CON LOG 2026-11-07)
-- ============================================================================
local KNOWN_STATIONS = {
    { category = "Trader / Tienda",     name = "Trader / Trade Plaza",       kw = {"trader", "tradeplaza", "viewtrader", "merchant", "dealer", "vendor"} },
    { category = "Trader Evento",       name = "Taco Merchant",              kw = {"tacomerchant", "taco", "tacodrop"} },
    { category = "Trader Evento",       name = "Santa Merchant",             kw = {"santamerchant", "santa", "christmas", "xmas"} },
    { category = "Trader Evento",       name = "Trick Or Treat Merchant",    kw = {"trickortreat", "halloweenmerchant", "candycorn"} },
    { category = "Tienda Evento",       name = "Valentines Shop",            kw = {"valentinesshop", "valentine", "opengift"} },
    { category = "Tienda Herramientas", name = "Rods Shop (Cañas)",          kw = {"rodsshop", "rodshop", "fishingrod", "rods"} },
    { category = "Tienda Herramientas", name = "Shovel Shop (Palas)",        kw = {"shovelshop", "shovel", "agarrinishovel"} },
    { category = "Lucky Block",         name = "Bee / Event Lucky Block",    kw = {"beeluckyblock", "skullluckyblock", "luckyblock", "lucky", "mysteryblock"} },
    { category = "Incubadora / Huevos", name = "Trait Incubator / Egg Hatch",kw = {"traitincubator", "incubator", "egghatch", "eggplace", "jumpltm", "egg"} },
    { category = "Maquina RNG / Spin",  name = "RNG Machine / Spin Wheel",   kw = {"rngmachine", "spinstage", "luckexplosion", "spinwheel", "wheel", "gacha", "bubblegum"} },
    { category = "Fusion / Bruja",      name = "Witch Cauldron / Haunted",   kw = {"witchcauldron", "hauntedfuse", "witchmachine", "cauldron", "witch", "bruja"} },
    { category = "Fusion Estandar",     name = "Fuse Machine",               kw = {"fusemachine", "fusionmachine", "confirmfusion", "fuse", "fusion"} },
    { category = "Fabricacion",         name = "Crafting Machine",           kw = {"craftingmachine", "craftmachine", "crafter", "craft", "workbench"} },
    { category = "Duelos",              name = "Duels Machine / Arena",      kw = {"duelsmachine", "duelmachine", "selectbrainrot", "duels"} },
    { category = "Mutacion / Mejora",   name = "Rainbow / Mutation Machine", kw = {"rainbowmachine", "mutationmachine", "cyberbeacon", "phantomcave", "eclipse", "crystal"} },
    { category = "Evento Especial",     name = "Pinata / Fat Sammy / Turkey",kw = {"pinata", "fatsammy", "sammy", "turkey", "thanksgiving", "lavacca", "crabrave", "soccer", "tsunami"} },
    { category = "Base / Indice",       name = "Base Index / Admin Board",   kw = {"baseindex", "index", "adminboard", "leaderboard"} },
}

-- Estados y colores en la lista
local STATUS = {
    ACTIVE = {
        id = "INTERACTUABLE (E)",
        label = "Activa en el Mapa (Lista para abrir con E)",
        color = Color3.fromRGB(46, 204, 113), -- Verde
        bgColor = Color3.fromRGB(22, 48, 34),
        order = 1,
    },
    DISABLED = {
        id = "PROMPT OFF / OCULTA",
        label = "En el Mapa pero Desactivada u Oculta (Forzable)",
        color = Color3.fromRGB(243, 156, 18), -- Naranja
        bgColor = Color3.fromRGB(54, 38, 18),
        order = 2,
    },
    RESIDUAL = {
        id = "ARCHIVO / SIN E",
        label = "Modelo o Servicio Residual (Sin Prompt E en Mapa)",
        color = Color3.fromRGB(155, 89, 182), -- Morado
        bgColor = Color3.fromRGB(42, 26, 52),
        order = 3,
    },
}

-- Modos de apertura
local OPEN_MODES = {
    { id = "FLASH_TP", label = "MODO: FLASH OPEN (Ida y Vuelta 0.12s)" },
    { id = "NO_TP",    label = "MODO: DIRECTO SIN TP (Remoto Puro)" },
    { id = "STAY_TP",  label = "MODO: IR A LA MAQUINA (Quedarse)" },
}

local STATE = {
    alive = true,
    minimized = false,
    isScanning = false,
    autoScan = false,
    autoScanInterval = 12,
    includeResidual = true,
    openModeIndex = 1,     -- Por defecto: FLASH OPEN (abre todo sin dejarte alla)
    searchQuery = "",
    entries = {},
    selectedEntry = nil,
    activeHighlight = nil,
    activeBillboard = nil,
    connections = {},
}

-- ============================================================================
-- SECCION 3: FILTRO QUIRURGICO PARA IGNORAR BRAINROTS (PASARELA Y BASES)
-- ============================================================================
local function normalizeText(str)
    return tostring(str or ""):lower():gsub("[%s_%-%p]+", "")
end

local function isPlayerCharacter(model)
    if not model then return false end
    if Players:GetPlayerFromCharacter(model) then return true end
    if model:FindFirstChildOfClass("Humanoid") and model:FindFirstChild("HumanoidRootPart") then
        for _, p in ipairs(Players:GetPlayers()) do
            if model.Name == p.Name or model.Name == p.DisplayName then
                return true
            end
        end
    end
    return false
end

local function isStationKeywordMatch(text)
    local norm = normalizeText(text)
    if norm == "" then return nil end
    for _, item in ipairs(KNOWN_STATIONS) do
        for _, kw in ipairs(item.kw) do
            if norm:find(kw, 1, true) then
                return item
            end
        end
    end
    return nil
end

-- Determina con precision si un objeto/Prompt es un Brainrot normal de pasarela o de base
local function isNormalBrainrotUnit(inst, prompts)
    if not inst then return false end

    -- Primero: Si el nombre coincide con un Lucky Block, Trader, Shop, Machine o Incubator, NUNCA lo ignores
    local fullPath = inst:GetFullName()
    if isStationKeywordMatch(fullPath) then
        return false
    end

    for _, p in ipairs(prompts or {}) do
        local pText = (p.ActionText or "") .. " " .. (p.ObjectText or "") .. " " .. p.Name
        if isStationKeywordMatch(pText) then
            return false
        end
        -- Si el ActionText dice "View", "View Trader", "Open", "Talk", "Craft", "Fuse", "Spin", "Swap", es una estacion/NPC!
        local actLow = (p.ActionText or ""):lower()
        if actLow:find("view", 1, true)
            or actLow:find("open", 1, true)
            or actLow:find("abrir", 1, true)
            or actLow:find("talk", 1, true)
            or actLow:find("hablar", 1, true)
            or actLow:find("trader", 1, true)
            or actLow:find("shop", 1, true)
            or actLow:find("tienda", 1, true)
            or actLow:find("fuse", 1, true)
            or actLow:find("craft", 1, true)
            or actLow:find("spin", 1, true)
            or actLow:find("hatch", 1, true)
            or actLow:find("place", 1, true)
            or actLow:find("swap", 1, true) then
            return false
        end
    end

    -- Segundo: Comprobar si tiene atributos exclusivos de unidad Brainrot (Pasarela o Base)
    local curr = inst
    for _ = 1, 6 do
        if not curr or curr == Workspace then break end
        if curr:GetAttribute("BrainrotName") ~= nil
            or curr:GetAttribute("Income") ~= nil
            or curr:GetAttribute("CashPerSecond") ~= nil
            or curr:GetAttribute("Rate") ~= nil
            or curr:GetAttribute("Mutation") ~= nil then
            return true
        end
        local lowName = curr.Name:lower()
        if lowName == "runway" or lowName == "conveyor" or lowName == "pasarela"
            or lowName == "spawnedbrainrots" or lowName == "movingbrainrots"
            or lowName == "brainrots" then
            return true
        end
        curr = curr.Parent
    end

    -- Tercero: Revisar los textos del ProximityPrompt tipicos de un Brainrot de pasarela o base
    for _, p in ipairs(prompts or {}) do
        local act = (p.ActionText or ""):lower()
        local obj = (p.ObjectText or ""):lower()
        local comb = act .. " " .. obj

        -- Prompts de robo/recoleccion/venta de Brainrots en bases o compra de Brainrots con $/s
        if act == "steal" or act == "robar" or act == "grab"
            or act == "collect" or act == "pick up" or act == "sell"
            or comb:match("%$[%d%.,]+/s") then
            return true
        end

        -- Si dice "Buy" en un pedestal de la pasarela o base y no es una tienda ni un Lucky Block
        if (act:find("buy", 1, true) or act:find("purchase", 1, true) or act:find("comprar", 1, true)) then
            local pathLow = fullPath:lower()
            if pathLow:find("plot") or pathLow:find("base") or pathLow:find("slot")
                or pathLow:find("pedestal") or pathLow:find("stand") or pathLow:find("track") then
                return true
            end
            -- Si el modelo tiene Humanoid y no dice trader/merchant/npc/shop/lucky, es un Brainrot caminando
            if inst:IsA("Model") and inst:FindFirstChildOfClass("Humanoid") then
                return true
            end
        end
    end

    return false
end

-- ============================================================================
-- SECCION 4: FUNCIONES GEOMETRICAS Y DE ESCANEO PROFUNDO
-- ============================================================================
local function getInstancePosition(inst)
    if not inst then return nil end
    if inst:IsA("ProximityPrompt") or inst:IsA("ClickDetector") then
        inst = inst.Parent
    end
    if not inst then return nil end

    if inst:IsA("Attachment") then
        return inst.WorldPosition
    elseif inst:IsA("BasePart") then
        return inst.Position
    elseif inst:IsA("Model") then
        local ok, pivot = pcall(function() return inst:GetPivot().Position end)
        if ok and pivot then return pivot end
        local part = inst:FindFirstChildWhichIsA("BasePart", true)
        if part then return part.Position end
    else
        local part = inst:FindFirstChildWhichIsA("BasePart", true)
            or inst:FindFirstAncestorWhichIsA("BasePart")
        if part then return part.Position end
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

-- Agrupa un ProximityPrompt o ClickDetector en el modelo/objeto interactivo al que pertenece
local function resolveInteractiveRoot(inst)
    if not inst then return nil end
    local curr = inst
    local best = inst.Parent or inst

    for _ = 1, 5 do
        if not curr or curr == Workspace or curr == ReplicatedStorage then
            break
        end
        if curr:IsA("Model") or curr:IsA("Folder") or curr:IsA("BasePart") then
            local low = curr.Name:lower()
            if low ~= "workspace" and low ~= "map" and low ~= "world"
                and low ~= "plots" and low ~= "bases" and low ~= "machines"
                and low ~= "npcs" and low ~= "shops" and low ~= "events"
                and low ~= "interactables" and low ~= "models" then
                best = curr
            end
        end
        curr = curr.Parent
    end
    return best
end

-- Construye la ficha completa de cualquier estacion, NPC ("View Trader"), Lucky Block o Maquina
local function buildInteractiveEntry(rootInst, containerName)
    if not rootInst or not rootInst.Parent then return nil end
    if isPlayerCharacter(rootInst) then return nil end

    local prompts = {}
    local clickDetectors = {}
    local guiTexts = {}

    if rootInst:IsA("ProximityPrompt") then
        prompts[1] = rootInst
    elseif rootInst:IsA("ClickDetector") then
        clickDetectors[1] = rootInst
    end

    local okDesc, descendants = pcall(function() return rootInst:GetDescendants() end)
    if okDesc and descendants then
        for _, d in ipairs(descendants) do
            if d:IsA("ProximityPrompt") then
                prompts[#prompts + 1] = d
            elseif d:IsA("ClickDetector") then
                clickDetectors[#clickDetectors + 1] = d
            elseif d:IsA("TextLabel") and d.Text ~= "" and #d.Text <= 60 then
                guiTexts[#guiTexts + 1] = d.Text
            end
        end
    end

    -- Excluir Brainrots de la pasarela y de las bases
    if isNormalBrainrotUnit(rootInst, prompts) then
        return nil
    end

    -- Recopilar todos los textos de accion (ej. "View Trader", "View", "Open", "Spin")
    local actionLabels = {}
    local enabledCount = 0
    local disabledCount = 0

    for _, p in ipairs(prompts) do
        if p.Enabled then
            enabledCount = enabledCount + 1
        else
            disabledCount = disabledCount + 1
        end
        local aTxt = (p.ActionText ~= "" and p.ActionText) or "E"
        local oTxt = (p.ObjectText ~= "" and (" (" .. p.ObjectText .. ")")) or ""
        actionLabels[#actionLabels + 1] = "[" .. aTxt .. oTxt .. "]"
    end

    for _, cd in ipairs(clickDetectors) do
        actionLabels[#actionLabels + 1] = "[Click: " .. cd.Name .. "]"
    end

    local combinedSearchText = rootInst:GetFullName()
        .. " " .. table.concat(actionLabels, " ")
        .. " " .. table.concat(guiTexts, " ")

    local matchedStation = isStationKeywordMatch(combinedSearchText)

    -- Si no tiene ni ProximityPrompt ni ClickDetector y tampoco es una estacion conocida, descartar
    if #prompts == 0 and #clickDetectors == 0 and not matchedStation then
        return nil
    end

    -- Determinar nombre legible (priorizando ActionText/ObjectText como "View Trader" o "Bee Lucky Block")
    local displayTitle = rootInst.Name
    if prompts[1] then
        local p = prompts[1]
        if p.ObjectText ~= "" and p.ActionText ~= "" then
            displayTitle = p.ActionText .. " - " .. p.ObjectText
        elseif p.ActionText ~= "" and normalizeText(rootInst.Name) == "part" or normalizeText(rootInst.Name) == "model" or normalizeText(rootInst.Name) == "proxpart" then
            displayTitle = p.ActionText .. " (" .. rootInst.Name .. ")"
        elseif p.ObjectText ~= "" then
            displayTitle = p.ObjectText .. " (" .. rootInst.Name .. ")"
        elseif p.ActionText ~= "" then
            displayTitle = rootInst.Name .. " [" .. p.ActionText .. "]"
        end
    end

    local category = matchedStation and matchedStation.category or "Interactuable (Letra E)"
    local stationType = matchedStation and matchedStation.name or ("Objeto E / Click (" .. rootInst.ClassName .. ")")

    local pos = getInstancePosition(prompts[1] or clickDetectors[1] or rootInst)
    local statusObj = STATUS.RESIDUAL

    if containerName == "Workspace" then
        if enabledCount > 0 or #clickDetectors > 0 then
            statusObj = STATUS.ACTIVE
        elseif disabledCount > 0 then
            statusObj = STATUS.DISABLED
        end
    end

    return {
        instance = rootInst,
        name = displayTitle,
        rawName = rootInst.Name,
        fullName = rootInst:GetFullName(),
        container = containerName,
        category = category,
        machineType = stationType,
        status = statusObj,
        position = pos,
        prompts = prompts,
        clickDetectors = clickDetectors,
        enabledPrompts = enabledCount,
        disabledPrompts = disabledCount,
        actionsSummary = (#actionLabels > 0) and table.concat(actionLabels, ", ") or "Sin Prompt E activo",
        guiSummary = (#guiTexts > 0) and table.concat(guiTexts, " | "):sub(1, 100) or "Ninguno",
        searchKey = (displayTitle .. " " .. category .. " " .. stationType .. " " .. table.concat(actionLabels, " ") .. " " .. rootInst:GetFullName()):lower(),
    }
end

-- Escaneo completo y sin lag
local function performUniversalScan(onProgress, onComplete)
    if STATE.isScanning then return end
    STATE.isScanning = true

    task.spawn(function()
        local candidateRoots = {}
        local foundMap = {}
        local results = {}

        -- 1. Escanear todo Workspace buscando cualquier ProximityPrompt, ClickDetector o Estacion
        local okW, wsList = pcall(function() return Workspace:GetDescendants() end)
        if okW and wsList then
            for i, inst in ipairs(wsList) do
                if not STATE.alive then break end
                if i % 500 == 0 then
                    if onProgress then
                        onProgress(string.format("Escaneando Workspace (%d/%d)...", i, #wsList))
                    end
                    task.wait()
                end

                if inst:IsA("ProximityPrompt") or inst:IsA("ClickDetector") then
                    local root = resolveInteractiveRoot(inst)
                    if root and not candidateRoots[root] then
                        candidateRoots[root] = "Workspace"
                    end
                elseif (inst:IsA("Model") or inst:IsA("Folder")) and STATE.includeResidual then
                    if isStationKeywordMatch(inst.Name) then
                        local root = resolveInteractiveRoot(inst)
                        if root and not candidateRoots[root] then
                            candidateRoots[root] = "Workspace"
                        end
                    end
                end
            end
        end

        -- 2. Opcional: Escanear ReplicatedStorage para ver maquinas/servicios de eventos guardados
        if STATE.includeResidual then
            local okRS, rsList = pcall(function() return ReplicatedStorage:GetDescendants() end)
            if okRS and rsList then
                for i, inst in ipairs(rsList) do
                    if not STATE.alive then break end
                    if i % 600 == 0 then task.wait() end
                    if (inst:IsA("Model") or inst:IsA("Folder")) and isStationKeywordMatch(inst.Name) then
                        if not inst:GetFullName():lower():find("packages.net") then
                            local root = resolveInteractiveRoot(inst)
                            if root and not candidateRoots[root] then
                                candidateRoots[root] = "ReplicatedStorage"
                            end
                        end
                    end
                end
            end
        end

        local idx = 0
        for root, containerLabel in pairs(candidateRoots) do
            if not STATE.alive then break end
            idx = idx + 1
            if idx % 30 == 0 then task.wait() end

            local entry = buildInteractiveEntry(root, containerLabel)
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

        STATE.entries = results
        STATE.isScanning = false

        if onComplete then
            onComplete(results)
        end
    end)
end

-- ============================================================================
-- SECCION 5: SISTEMA DE APERTURA DIRECTA (FLASH OPEN / REMOTO / GUI FORCER)
-- ============================================================================
local function captureGuiSnapshot()
    local snap = {}
    if not PlayerGui then return snap end
    for _, d in ipairs(PlayerGui:GetDescendants()) do
        if d:IsA("ScreenGui") then
            snap[d] = d.Enabled
        elseif d:IsA("GuiObject") then
            snap[d] = d.Visible
        end
    end
    return snap
end

local function detectNewGuiOpened(beforeSnap)
    if not PlayerGui then return false, nil end
    for _, d in ipairs(PlayerGui:GetDescendants()) do
        if d:IsA("ScreenGui") then
            if (beforeSnap[d] == nil or beforeSnap[d] == false) and d.Enabled == true then
                return true, "ScreenGui: " .. d.Name
            end
        elseif d:IsA("Frame") or d:IsA("CanvasGroup") or d:IsA("ImageLabel") then
            if beforeSnap[d] == false and d.Visible == true and d.AbsoluteSize.X > 110 and d.AbsoluteSize.Y > 110 then
                return true, "Ventana: " .. d.Name
            end
        end
    end
    return false, nil
end

-- Dispara un ProximityPrompt forzando rango infinito, sin linea de vision y HoldDuration = 0
local function firePromptDirect(prompt)
    if not prompt or not prompt.Parent then return false end

    local origEnabled = prompt.Enabled
    local origHold = prompt.HoldDuration
    local origDist = prompt.MaxActivationDistance
    local origLos = prompt.RequiresLineOfSight

    pcall(function()
        prompt.Enabled = true
        prompt.HoldDuration = 0
        prompt.MaxActivationDistance = 999999
        prompt.RequiresLineOfSight = false
    end)

    local firedOk = false
    if type(fireproximityprompt) == "function" then
        firedOk = pcall(fireproximityprompt, prompt)
    end
    if not firedOk then
        firedOk = pcall(function()
            prompt:InputHoldBegin()
            task.wait(0.03)
            prompt:InputHoldEnd()
        end)
    end

    task.delay(0.35, function()
        if prompt and prompt.Parent then
            pcall(function()
                prompt.Enabled = origEnabled
                prompt.HoldDuration = origHold
                prompt.MaxActivationDistance = origDist
                prompt.RequiresLineOfSight = origLos
            end)
        end
    end)

    return firedOk
end

local function fireClickDirect(cd)
    if not cd or not cd.Parent then return false end
    local origDist = cd.MaxActivationDistance
    pcall(function() cd.MaxActivationDistance = 999999 end)

    local firedOk = false
    if type(fireclickdetector) == "function" then
        firedOk = pcall(fireclickdetector, cd)
    end

    task.delay(0.35, function()
        if cd and cd.Parent then
            pcall(function() cd.MaxActivationDistance = origDist end)
        end
    end)
    return firedOk
end

-- Intenta buscar y abrir directamente en PlayerGui cualquier ventana asociada a la maquina/trader
local function forceOpenMatchingLocalGui(entry, statusCallback)
    if not PlayerGui or not entry then return false end
    local kwList = {}

    for token in entry.rawName:lower():gmatch("%w+") do
        if #token >= 3 and token ~= "model" and token ~= "part" and token ~= "folder" then
            kwList[#kwList + 1] = token
        end
    end
    for _, p in ipairs(entry.prompts or {}) do
        for token in ((p.ActionText or "") .. " " .. (p.ObjectText or "")):lower():gmatch("%w+") do
            if #token >= 4 and token ~= "view" and token ~= "open" then
                kwList[#kwList + 1] = token
            end
        end
    end

    local openedNames = {}
    for _, guiObj in ipairs(PlayerGui:GetChildren()) do
        if guiObj:IsA("ScreenGui") and guiObj.Name ~= "SAB_UniversalOpener_v2" then
            local gLow = guiObj.Name:lower()
            for _, kw in ipairs(kwList) do
                if gLow:find(kw, 1, true) then
                    guiObj.Enabled = true
                    for _, child in ipairs(guiObj:GetChildren()) do
                        if child:IsA("Frame") or child:IsA("CanvasGroup") or child:IsA("ImageLabel") then
                            child.Visible = true
                        end
                    end
                    openedNames[#openedNames + 1] = guiObj.Name
                    break
                end
            end
        end
    end

    if #openedNames > 0 then
        statusCallback("Ventana GUI forzada localmente: " .. table.concat(openedNames, ", "), Color3.fromRGB(46, 204, 113))
        return true
    else
        statusCallback("No se encontro una ScreenGui oculta con ese nombre en PlayerGui.", Color3.fromRGB(243, 156, 18))
        return false
    end
end

-- Ejecuta la interaccion completa con el objeto seleccionado (Flash Open, Remoto o Stay TP)
local function executeDirectInteraction(entry, statusCallback)
    if not entry or not entry.instance or not entry.instance.Parent then
        statusCallback("Error: El objeto ya no existe en el mapa.", Color3.fromRGB(231, 76, 60))
        return
    end

    local prompts = entry.prompts or {}
    local clickDetectors = entry.clickDetectors or {}

    if #prompts == 0 and #clickDetectors == 0 then
        statusCallback("Este objeto no tiene Prompt E en el mapa. Intentando forzar su GUI local...", Color3.fromRGB(243, 156, 18))
        forceOpenMatchingLocalGui(entry, statusCallback)
        return
    end

    task.spawn(function()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local mode = OPEN_MODES[STATE.openModeIndex].id
        local targetPos = getInstancePosition(prompts[1] or clickDetectors[1] or entry.instance)
        local savedCFrame = hrp and hrp.CFrame
        local didFlashTp = false

        local guiBefore = captureGuiSnapshot()

        -- Si estamos lejos y el modo es FLASH_TP o STAY_TP, acercarnos para que el servidor acepte la tecla E
        if hrp and targetPos then
            local dist = (hrp.Position - targetPos).Magnitude
            if mode == "FLASH_TP" and dist > 11 then
                statusCallback("Flash Open: Enviando interaccion E en " .. entry.name .. "...", Color3.fromRGB(52, 152, 219))
                hrp.CFrame = CFrame.new(targetPos + Vector3.new(0, 3.2, 2.5))
                didFlashTp = true
                task.wait(0.11)
            elseif mode == "STAY_TP" and dist > 11 then
                statusCallback("Teletransportado frente a: " .. entry.name, Color3.fromRGB(52, 152, 219))
                hrp.CFrame = CFrame.new(targetPos + Vector3.new(0, 3.2, 2.5))
                task.wait(0.12)
            end
        end

        -- Disparar TODOS los ProximityPrompts y ClickDetectors de esa estacion (ej. "View Trader", "View", "Open")
        local firedCount = 0
        for _, p in ipairs(prompts) do
            if firePromptDirect(p) then
                firedCount = firedCount + 1
            end
        end
        for _, cd in ipairs(clickDetectors) do
            if fireClickDirect(cd) then
                firedCount = firedCount + 1
            end
        end

        -- Si fue Flash Open, regresar instantaneamente a la posicion original
        if didFlashTp and hrp and hrp.Parent and savedCFrame then
            task.wait(0.06)
            hrp.CFrame = savedCFrame
        end

        if firedCount == 0 then
            statusCallback("No se pudo disparar el Prompt E en tu ejecutor.", Color3.fromRGB(231, 76, 60))
            return
        end

        -- Comprobar si se abrio una interfaz en PlayerGui
        local opened, detail = false, nil
        for _ = 1, 8 do
            task.wait(0.08)
            opened, detail = detectNewGuiOpened(guiBefore)
            if opened then break end
        end

        if opened then
            statusCallback("¡Abierto con exito! (" .. tostring(detail) .. ")", Color3.fromRGB(46, 204, 113))
        else
            statusCallback(
                string.format("Interaccion E enviada a '%s' (%d prompts disparados).", entry.name, firedCount),
                Color3.fromRGB(46, 204, 113)
            )
        end
    end)
end

-- ============================================================================
-- SECCION 6: LOCALIZADOR VISUAL 3D (ESP)
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

local function locateVisually(entry, statusCallback)
    clearVisualLocator()
    if not entry or not entry.instance or not entry.instance.Parent then
        statusCallback("El objeto ya no existe en el mapa.", Color3.fromRGB(231, 76, 60))
        return
    end
    if entry.container ~= "Workspace" then
        statusCallback("Guardado en ReplicatedStorage (sin coordenadas 3D en el mapa).", Color3.fromRGB(243, 156, 18))
        return
    end

    local target = entry.instance
    local pos = getInstancePosition(entry.prompts[1] or target)
    if not pos then
        statusCallback("Sin piezas 3D para resaltar.", Color3.fromRGB(231, 76, 60))
        return
    end

    local hl = Instance.new("Highlight")
    hl.Name = "SAB_UniversalHighlight"
    hl.Adornee = target
    hl.FillColor = entry.status.color
    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
    hl.FillTransparency = 0.4
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = target
    STATE.activeHighlight = hl

    local adorneePart = (target:IsA("BasePart") and target) or target:FindFirstChildWhichIsA("BasePart", true)
    if adorneePart then
        local bb = Instance.new("BillboardGui")
        bb.Name = "SAB_UniversalTag"
        bb.Adornee = adorneePart
        bb.Size = UDim2.new(0, 230, 0, 52)
        bb.StudsOffset = Vector3.new(0, 4.5, 0)
        bb.AlwaysOnTop = true
        bb.Parent = adorneePart

        local f = Instance.new("Frame")
        f.Size = UDim2.new(1, 0, 1, 0)
        f.BackgroundColor3 = Color3.fromRGB(14, 15, 22)
        f.BackgroundTransparency = 0.15
        f.BorderSizePixel = 0
        f.Parent = bb
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)

        local st = Instance.new("UIStroke")
        st.Color = entry.status.color
        st.Thickness = 1.5
        st.Parent = f

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -8, 1, -4)
        lbl.Position = UDim2.new(0, 4, 0, 2)
        lbl.BackgroundTransparency = 1
        lbl.TextColor3 = Color3.fromRGB(245, 245, 250)
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 10
        lbl.TextWrapped = true
        local d = getDistanceFromPlayer(pos)
        lbl.Text = string.format("%s\n%s (%s)", entry.name, entry.actionsSummary, d and string.format("%.0f studs", d) or "")
        lbl.Parent = f

        STATE.activeBillboard = bb
    end

    statusCallback("ESP 3D activado sobre: " .. entry.name, Color3.fromRGB(46, 204, 113))
end

-- ============================================================================
-- SECCION 7: INTERFAZ GRAFICA MODERNA Y COMPACTA
-- ============================================================================
local guiParent = (type(gethui) == "function" and select(2, pcall(gethui))) or CoreGui

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SAB_UniversalOpener_v2"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = guiParent

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 560, 0, 450)
mainFrame.Position = UDim2.new(0.5, -280, 0.5, -225)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 16, 22)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 8)

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(45, 52, 72)
mainStroke.Thickness = 1.2
mainStroke.Parent = mainFrame

-- Barra de titulo
local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 32)
topBar.BackgroundColor3 = Color3.fromRGB(23, 25, 35)
topBar.BorderSizePixel = 0
topBar.Parent = mainFrame
Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 8)

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -75, 1, 0)
titleLabel.Position = UDim2.new(0, 12, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "SAB | UNIVERSAL E-SCANNER & DIRECT MACHINE OPENER v2"
titleLabel.TextColor3 = Color3.fromRGB(235, 240, 250)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 11
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = topBar

local btnMin = Instance.new("TextButton")
btnMin.Size = UDim2.new(0, 28, 0, 28)
btnMin.Position = UDim2.new(1, -62, 0, 2)
btnMin.BackgroundTransparency = 1
btnMin.Text = "-"
btnMin.TextColor3 = Color3.fromRGB(210, 215, 230)
btnMin.Font = Enum.Font.GothamBold
btnMin.TextSize = 16
btnMin.Parent = topBar

local btnClose = Instance.new("TextButton")
btnClose.Size = UDim2.new(0, 28, 0, 28)
btnClose.Position = UDim2.new(1, -30, 0, 2)
btnClose.BackgroundTransparency = 1
btnClose.Text = "X"
btnClose.TextColor3 = Color3.fromRGB(240, 85, 85)
btnClose.Font = Enum.Font.GothamBold
btnClose.TextSize = 14
btnClose.Parent = topBar

local bodyFrame = Instance.new("Frame")
bodyFrame.Size = UDim2.new(1, 0, 1, -32)
bodyFrame.Position = UDim2.new(0, 0, 0, 32)
bodyFrame.BackgroundTransparency = 1
bodyFrame.Parent = mainFrame

-- Controles Superiores
local controlsBar = Instance.new("Frame")
controlsBar.Size = UDim2.new(1, -20, 0, 28)
controlsBar.Position = UDim2.new(0, 10, 0, 6)
controlsBar.BackgroundTransparency = 1
controlsBar.Parent = bodyFrame

local function createTopBtn(text, xScale, wScale, color)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(wScale, -4, 1, 0)
    b.Position = UDim2.new(xScale, 0, 0, 0)
    b.BackgroundColor3 = color
    b.BorderSizePixel = 0
    b.Text = text
    b.TextColor3 = Color3.fromRGB(245, 245, 250)
    b.Font = Enum.Font.GothamSemibold
    b.TextSize = 10
    b.Parent = controlsBar
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)
    return b
end

local btnScan = createTopBtn("ESCANEAR TODO (E)", 0.00, 0.32, Color3.fromRGB(45, 115, 200))
local btnAutoScan = createTopBtn("AUTO SCAN: OFF", 0.32, 0.28, Color3.fromRGB(50, 54, 68))
local btnOpenMode = createTopBtn(OPEN_MODES[1].label, 0.60, 0.40, Color3.fromRGB(38, 120, 85))

-- Buscador en vivo y contadores
local searchBox = Instance.new("TextBox")
searchBox.Size = UDim2.new(0.54, -12, 0, 24)
searchBox.Position = UDim2.new(0, 10, 0, 38)
searchBox.BackgroundColor3 = Color3.fromRGB(22, 24, 32)
searchBox.BorderSizePixel = 0
searchBox.PlaceholderText = "Buscar (ej: view, trader, bee, lucky, fuse, taco, egg)..."
searchBox.Text = ""
searchBox.TextColor3 = Color3.fromRGB(235, 240, 250)
searchBox.Font = Enum.Font.Gotham
searchBox.TextSize = 10
searchBox.ClearTextOnFocus = false
searchBox.Parent = bodyFrame
Instance.new("UICorner", searchBox).CornerRadius = UDim.new(0, 5)

local countersBar = Instance.new("TextLabel")
countersBar.Size = UDim2.new(0.46, -12, 0, 24)
countersBar.Position = UDim2.new(0.54, 2, 0, 38)
countersBar.BackgroundColor3 = Color3.fromRGB(22, 24, 32)
countersBar.BorderSizePixel = 0
countersBar.Text = " Activas (E): 0 | Ocultas: 0 | Total: 0"
countersBar.TextColor3 = Color3.fromRGB(195, 205, 225)
countersBar.Font = Enum.Font.GothamSemibold
countersBar.TextSize = 9
countersBar.TextXAlignment = Enum.TextXAlignment.Left
countersBar.Parent = bodyFrame
Instance.new("UICorner", countersBar).CornerRadius = UDim.new(0, 5)

-- Lista Izquierda
local listScroll = Instance.new("ScrollingFrame")
listScroll.Size = UDim2.new(0.54, -12, 1, -98)
listScroll.Position = UDim2.new(0, 10, 0, 66)
listScroll.BackgroundColor3 = Color3.fromRGB(11, 12, 16)
listScroll.BorderSizePixel = 0
listScroll.ScrollBarThickness = 4
listScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
listScroll.Parent = bodyFrame
Instance.new("UICorner", listScroll).CornerRadius = UDim.new(0, 6)

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 4)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = listScroll

listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    listScroll.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 8)
end)

-- Panel Derecho: Inspector y Botones de Apertura Directa
local detailPanel = Instance.new("Frame")
detailPanel.Size = UDim2.new(0.46, -12, 1, -98)
detailPanel.Position = UDim2.new(0.54, 2, 0, 66)
detailPanel.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
detailPanel.BorderSizePixel = 0
detailPanel.Parent = bodyFrame
Instance.new("UICorner", detailPanel).CornerRadius = UDim.new(0, 6)

local detailTitle = Instance.new("TextLabel")
detailTitle.Size = UDim2.new(1, -16, 0, 22)
detailTitle.Position = UDim2.new(0, 8, 0, 6)
detailTitle.BackgroundTransparency = 1
detailTitle.Text = "SELECCIONA UN OBJETO / MAQUINA"
detailTitle.TextColor3 = Color3.fromRGB(240, 240, 250)
detailTitle.Font = Enum.Font.GothamBold
detailTitle.TextSize = 11
detailTitle.TextXAlignment = Enum.TextXAlignment.Left
detailTitle.TextTruncate = Enum.TextTruncate.AtEnd
detailTitle.Parent = detailPanel

local detailBody = Instance.new("TextLabel")
detailBody.Size = UDim2.new(1, -16, 1, -132)
detailBody.Position = UDim2.new(0, 8, 0, 28)
detailBody.BackgroundTransparency = 1
detailBody.Text = "Escanea el mapa para listar todas las interacciones con letra E (Traders, View Trader, Bee Lucky Block, Incubadoras, Maquinas de Fusion, Tiendas de Cañas/Palas y Eventos).\n\nLos Brainrots de pasarela y de bases se ignoran automaticamente."
detailBody.TextColor3 = Color3.fromRGB(185, 192, 210)
detailBody.Font = Enum.Font.Gotham
detailBody.TextSize = 9
detailBody.TextWrapped = true
detailBody.TextXAlignment = Enum.TextXAlignment.Left
detailBody.TextYAlignment = Enum.TextYAlignment.Top
detailBody.Parent = detailPanel

local function createDetailBtn(text, bottomOffset, color)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -16, 0, 26)
    b.Position = UDim2.new(0, 8, 1, bottomOffset)
    b.BackgroundColor3 = color
    b.BorderSizePixel = 0
    b.Text = text
    b.TextColor3 = Color3.fromRGB(245, 245, 250)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 10
    b.Parent = detailPanel
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)
    return b
end

local btnLocate = createDetailBtn("LOCALIZAR CON ESP 3D", -94, Color3.fromRGB(45, 100, 160))
local btnForceGui = createDetailBtn("FORZAR VENTANA EN PLAYERGUI", -64, Color3.fromRGB(115, 70, 145))
local btnOpenMain = createDetailBtn("ABRIR / INTERACTUAR DIRECTO (E)", -34, Color3.fromRGB(38, 145, 80))

-- Barra inferior de estado
local statusBar = Instance.new("TextLabel")
statusBar.Size = UDim2.new(1, -20, 0, 22)
statusBar.Position = UDim2.new(0, 10, 1, -26)
statusBar.BackgroundColor3 = Color3.fromRGB(22, 24, 32)
statusBar.BorderSizePixel = 0
statusBar.Text = " Listo. Modo Flash Open activo (abre cualquier E a distancia y te regresa a tu sitio)."
statusBar.TextColor3 = Color3.fromRGB(145, 225, 175)
statusBar.Font = Enum.Font.Gotham
statusBar.TextSize = 10
statusBar.TextXAlignment = Enum.TextXAlignment.Left
statusBar.TextTruncate = Enum.TextTruncate.AtEnd
statusBar.Parent = bodyFrame
Instance.new("UICorner", statusBar).CornerRadius = UDim.new(0, 4)

local function setStatus(msg, col)
    if not statusBar or not statusBar.Parent then return end
    statusBar.Text = " " .. tostring(msg)
    statusBar.TextColor3 = col or Color3.fromRGB(200, 205, 220)
end

-- ============================================================================
-- SECCION 8: RENDERIZADO DE LA LISTA Y SELECCION
-- ============================================================================
local function updateDetailPanel(entry)
    STATE.selectedEntry = entry
    if not entry then return end

    detailTitle.Text = entry.name:upper()
    detailTitle.TextColor3 = entry.status.color

    local dist = getDistanceFromPlayer(entry.position)
    local distTxt = dist and string.format("%.1f studs", dist) or "N/A"

    detailBody.Text = string.format(
        "Accion E / Click: %s\nCategoria: %s\nTipo: %s\nEstado: %s\nDistancia actual: %s\n\nRuta completa:\n%s\n\nCarteles / Textos 3D:\n%s",
        entry.actionsSummary,
        entry.category,
        entry.machineType,
        entry.status.label,
        distTxt,
        entry.fullName,
        entry.guiSummary
    )
end

local function renderList()
    for _, child in ipairs(listScroll:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end

    local query = STATE.searchQuery:lower()
    local cActive, cDisabled, cShown = 0, 0, 0

    for idx, entry in ipairs(STATE.entries) do
        if entry.status == STATUS.ACTIVE then
            cActive = cActive + 1
        elseif entry.status == STATUS.DISABLED then
            cDisabled = cDisabled + 1
        end

        if query == "" or entry.searchKey:find(query, 1, true) then
            cShown = cShown + 1

            local card = Instance.new("Frame")
            card.Size = UDim2.new(1, -6, 0, 56)
            card.BackgroundColor3 = entry.status.bgColor
            card.BorderSizePixel = 0
            card.LayoutOrder = idx
            card.Parent = listScroll
            Instance.new("UICorner", card).CornerRadius = UDim.new(0, 6)

            local bar = Instance.new("Frame")
            bar.Size = UDim2.new(0, 4, 1, -8)
            bar.Position = UDim2.new(0, 4, 0, 4)
            bar.BackgroundColor3 = entry.status.color
            bar.BorderSizePixel = 0
            bar.Parent = card
            Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 2)

            local lblName = Instance.new("TextLabel")
            lblName.Size = UDim2.new(1, -92, 0, 18)
            lblName.Position = UDim2.new(0, 12, 0, 3)
            lblName.BackgroundTransparency = 1
            lblName.Text = entry.name
            lblName.TextColor3 = entry.status.color
            lblName.Font = Enum.Font.GothamBold
            lblName.TextSize = 10
            lblName.TextXAlignment = Enum.TextXAlignment.Left
            lblName.TextTruncate = Enum.TextTruncate.AtEnd
            lblName.Parent = card

            local lblAct = Instance.new("TextLabel")
            lblAct.Size = UDim2.new(1, -92, 0, 16)
            lblAct.Position = UDim2.new(0, 12, 0, 20)
            lblAct.BackgroundTransparency = 1
            lblAct.Text = entry.actionsSummary .. " | " .. entry.category
            lblAct.TextColor3 = Color3.fromRGB(225, 230, 240)
            lblAct.Font = Enum.Font.GothamSemibold
            lblAct.TextSize = 9
            lblAct.TextXAlignment = Enum.TextXAlignment.Left
            lblAct.TextTruncate = Enum.TextTruncate.AtEnd
            lblAct.Parent = card

            local lblPath = Instance.new("TextLabel")
            lblPath.Size = UDim2.new(1, -92, 0, 14)
            lblPath.Position = UDim2.new(0, 12, 0, 36)
            lblPath.BackgroundTransparency = 1
            lblPath.Text = entry.fullName
            lblPath.TextColor3 = Color3.fromRGB(155, 162, 178)
            lblPath.Font = Enum.Font.Gotham
            lblPath.TextSize = 8
            lblPath.TextXAlignment = Enum.TextXAlignment.Left
            lblPath.TextTruncate = Enum.TextTruncate.AtEnd
            lblPath.Parent = card

            local btnInfo = Instance.new("TextButton")
            btnInfo.Size = UDim2.new(0, 38, 0, 20)
            btnInfo.Position = UDim2.new(1, -82, 0, 6)
            btnInfo.BackgroundColor3 = Color3.fromRGB(36, 40, 52)
            btnInfo.BorderSizePixel = 0
            btnInfo.Text = "Info"
            btnInfo.TextColor3 = Color3.fromRGB(235, 235, 245)
            btnInfo.Font = Enum.Font.GothamSemibold
            btnInfo.TextSize = 9
            btnInfo.Parent = card
            Instance.new("UICorner", btnInfo).CornerRadius = UDim.new(0, 4)

            local btnEsp = Instance.new("TextButton")
            btnEsp.Size = UDim2.new(0, 38, 0, 20)
            btnEsp.Position = UDim2.new(1, -41, 0, 6)
            btnEsp.BackgroundColor3 = Color3.fromRGB(42, 95, 150)
            btnEsp.BorderSizePixel = 0
            btnEsp.Text = "ESP"
            btnEsp.TextColor3 = Color3.fromRGB(245, 245, 255)
            btnEsp.Font = Enum.Font.GothamSemibold
            btnEsp.TextSize = 9
            btnEsp.Parent = card
            Instance.new("UICorner", btnEsp).CornerRadius = UDim.new(0, 4)

            local btnOpenDirect = Instance.new("TextButton")
            btnOpenDirect.Size = UDim2.new(0, 79, 0, 22)
            btnOpenDirect.Position = UDim2.new(1, -82, 0, 29)
            btnOpenDirect.BackgroundColor3 = Color3.fromRGB(36, 138, 78)
            btnOpenDirect.BorderSizePixel = 0
            btnOpenDirect.Text = "ABRIR (E)"
            btnOpenDirect.TextColor3 = Color3.fromRGB(245, 255, 245)
            btnOpenDirect.Font = Enum.Font.GothamBold
            btnOpenDirect.TextSize = 9
            btnOpenDirect.Parent = card
            Instance.new("UICorner", btnOpenDirect).CornerRadius = UDim.new(0, 4)

            btnInfo.MouseButton1Click:Connect(function()
                updateDetailPanel(entry)
                setStatus("Seleccionado: " .. entry.name, entry.status.color)
            end)

            btnEsp.MouseButton1Click:Connect(function()
                updateDetailPanel(entry)
                locateVisually(entry, setStatus)
            end)

            btnOpenDirect.MouseButton1Click:Connect(function()
                updateDetailPanel(entry)
                executeDirectInteraction(entry, setStatus)
            end)
        end
    end

    countersBar.Text = string.format(
        " Activas (E): %d | Ocultas: %d | Mostrando: %d",
        cActive, cDisabled, cShown
    )

    if not STATE.selectedEntry and STATE.entries[1] then
        updateDetailPanel(STATE.entries[1])
    end
end

local function triggerScan()
    if STATE.isScanning then return end
    btnScan.Text = "ESCANEANDO..."
    btnScan.BackgroundColor3 = Color3.fromRGB(85, 90, 108)

    performUniversalScan(
        function(msg)
            setStatus(msg, Color3.fromRGB(130, 195, 255))
        end,
        function(results)
            if not STATE.alive then return end
            btnScan.Text = "ESCANEAR TODO (E)"
            btnScan.BackgroundColor3 = Color3.fromRGB(45, 115, 200)
            renderList()
            setStatus(
                string.format("Escaneo completado: %d interacciones/maquinas encontradas (Brainrots ignorados).", #results),
                Color3.fromRGB(46, 204, 113)
            )
        end
    )
end

-- ============================================================================
-- SECCION 9: EVENTOS DE CONTROLES Y CIERRE LIMPIO
-- ============================================================================
btnScan.MouseButton1Click:Connect(triggerScan)

btnAutoScan.MouseButton1Click:Connect(function()
    STATE.autoScan = not STATE.autoScan
    btnAutoScan.Text = "AUTO SCAN: " .. (STATE.autoScan and "ON" or "OFF")
    btnAutoScan.BackgroundColor3 = STATE.autoScan
        and Color3.fromRGB(40, 135, 80)
        or Color3.fromRGB(50, 54, 68)
end)

btnOpenMode.MouseButton1Click:Connect(function()
    STATE.openModeIndex = (STATE.openModeIndex % #OPEN_MODES) + 1
    local m = OPEN_MODES[STATE.openModeIndex]
    btnOpenMode.Text = m.label
    setStatus("Modo de apertura cambiado a: " .. m.label, Color3.fromRGB(130, 205, 255))
end)

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    STATE.searchQuery = searchBox.Text
    renderList()
end)

btnLocate.MouseButton1Click:Connect(function()
    if not STATE.selectedEntry then
        setStatus("Selecciona primero un elemento de la lista.", Color3.fromRGB(243, 156, 18))
        return
    end
    locateVisually(STATE.selectedEntry, setStatus)
end)

btnForceGui.MouseButton1Click:Connect(function()
    if not STATE.selectedEntry then
        setStatus("Selecciona primero un elemento de la lista.", Color3.fromRGB(243, 156, 18))
        return
    end
    forceOpenMatchingLocalGui(STATE.selectedEntry, setStatus)
end)

btnOpenMain.MouseButton1Click:Connect(function()
    if not STATE.selectedEntry then
        setStatus("Selecciona primero un elemento de la lista.", Color3.fromRGB(243, 156, 18))
        return
    end
    executeDirectInteraction(STATE.selectedEntry, setStatus)
end)

btnMin.MouseButton1Click:Connect(function()
    STATE.minimized = not STATE.minimized
    bodyFrame.Visible = not STATE.minimized
    mainFrame.Size = STATE.minimized and UDim2.new(0, 560, 0, 32) or UDim2.new(0, 560, 0, 450)
    btnMin.Text = STATE.minimized and "+" or "-"
end)

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

local function cleanupAll()
    if not STATE.alive then return end
    STATE.alive = false
    STATE.autoScan = false
    clearVisualLocator()

    for _, c in ipairs(STATE.connections) do
        pcall(function() c:Disconnect() end)
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

-- Escaneo automatico al ejecutar
triggerScan()

--[[
    ============================================================================
    PROYECTO: SAB DUEL HUB - ADVANCED CLIENT SCRIPT
    Compatibilidad: Delta Executor | Roblox Luau | Steal a Brainrot (v2648+)
    Pestañas:
      - DUEL: Anti Drop Brainrot (Knockback/Stun Purge + Auto Re-Grab) & Duel Disruptor (Lagger/Desync)
      - STEAL: Auto Grab Brainrot (0.15s Configurable Delay, Zero-Spam, Native Prompt Trigger)
    ============================================================================
]]

-- Limpieza segura si el script ya estaba abierto
if _G.SAB_DuelHub then
    pcall(function()
        _G.SAB_DuelHub.Cleanup()
    end)
end

-- ============================================================================
-- SECCION 1: SERVICIOS Y VALIDACION DE ENTORNO DELTA
-- ============================================================================
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- Comprobacion segura de funciones del ejecutor (Delta)
local getSafeGuiParent = function()
    if type(gethui) == "function" then
        local ok, res = pcall(gethui)
        if ok and res then return res end
    end
    return CoreGui
end

local hasFirePrompt = (type(fireproximityprompt) == "function")

-- ============================================================================
-- SECCION 2: CONFIGURACION Y ESTADO GLOBAL
-- ============================================================================
local CFG = {
    -- Pestaña DUEL
    antiDrop = false,
    autoReGrabOnDrop = true,
    duelLagger = false,
    laggerRange = 22,
    baseWalkSpeed = 34, -- Velocidad nativa detectada en SAB Logger v2648 (34.0009)
    maxKnockbackSpeed = 58,

    -- Pestaña STEAL
    autoGrab = false,
    grabDelay = 0.15,   -- Delay inicial solicitado: 0.15 segundos
    grabRange = 20,
}

local STATE = {
    alive = true,
    minimized = false,
    carryingBrainrot = false,
    carriedObjectName = "Ninguno",
    lastDroppedPrompt = nil,
    lastDropTime = 0,

    -- Estadisticas en vivo
    stunsBlocked = 0,
    grabsExecuted = 0,
    disruptTicks = 0,

    -- Caches para evitar lag
    stealPrompts = setmetatable({}, {__mode = "k"}),
    promptCooldowns = setmetatable({}, {__mode = "k"}),
    connections = {},
}

-- ============================================================================
-- SECCION 3: DETECTOR INTELIGENTE DE PROMPTS DE ROBO / BRAINROTS
-- ============================================================================
local STEAL_KEYWORDS = {
    "steal", "grab", "take", "pick", "carry", "robar", "agarrar", "tomar", "brainrot", "drop"
}

local EXCLUDED_PROMPT_WORDS = {
    "fuse", "witch", "cauldron", "craft", "upgrade", "wheel", "spin", "shop", "vip", "robux"
}

local function isStealOrGrabPrompt(prompt)
    if not prompt or not prompt:IsA("ProximityPrompt") then return false end

    local action = tostring(prompt.ActionText or ""):lower()
    local object = tostring(prompt.ObjectText or ""):lower()
    local name = tostring(prompt.Name or ""):lower()
    local parentName = (prompt.Parent and tostring(prompt.Parent.Name) or ""):lower()
    local combined = action .. " " .. object .. " " .. name .. " " .. parentName

    for _, bad in ipairs(EXCLUDED_PROMPT_WORDS) do
        if combined:find(bad, 1, true) then
            return false
        end
    end

    for _, kw in ipairs(STEAL_KEYWORDS) do
        if combined:find(kw, 1, true) then
            return true
        end
    end

    -- En SAB muchos Brainrots tienen ActionText vacio o de precio pero estan dentro de un Model de unidad
    local ancestor = prompt.Parent
    for _ = 1, 5 do
        if not ancestor or ancestor == Workspace then break end
        if ancestor:GetAttribute("BrainrotName") or ancestor:GetAttribute("Mutation") or ancestor:GetAttribute("Income") then
            return true
        end
        ancestor = ancestor.Parent
    end

    return false
end

local function getPromptWorldPosition(prompt)
    local node = prompt and prompt.Parent
    for _ = 1, 6 do
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

local function registerPromptCandidate(inst)
    if not inst or not inst:IsA("ProximityPrompt") then return end
    if isStealOrGrabPrompt(inst) then
        STATE.stealPrompts[inst] = true
    end
end

-- Escaneo inicial unico de Workspace (sin bucles pesados)
for _, desc in ipairs(Workspace:GetDescendants()) do
    if desc:IsA("ProximityPrompt") then
        registerPromptCandidate(desc)
    end
end

table.insert(STATE.connections, Workspace.DescendantAdded:Connect(function(desc)
    if desc:IsA("ProximityPrompt") then
        task.defer(function()
            registerPromptCandidate(desc)
        end)
    end
end))

table.insert(STATE.connections, Workspace.DescendantRemoving:Connect(function(desc)
    if desc:IsA("ProximityPrompt") then
        STATE.stealPrompts[desc] = nil
        STATE.promptCooldowns[desc] = nil
    end
end))

-- ============================================================================
-- SECCION 4: DISPARADOR NATIVO DE INTERACCION (SIN SIMULACION VISUAL)
-- ============================================================================
local function triggerNativeGrab(prompt)
    if not prompt or not prompt.Parent or not prompt.Enabled then
        return false
    end

    local origHold = prompt.HoldDuration
    pcall(function()
        prompt.HoldDuration = 0
    end)

    local success = false
    if hasFirePrompt then
        success = pcall(fireproximityprompt, prompt)
    end

    if not success then
        success = pcall(function()
            prompt:InputHoldBegin()
            task.wait()
            prompt:InputHoldEnd()
        end)
    end

    if prompt and prompt.Parent then
        pcall(function()
            prompt.HoldDuration = origHold
        end)
    end

    return success
end

-- ============================================================================
-- SECCION 5: MODULO ANTI-DROP BRAINROT (PROTECCION FISICA + RE-GRAB)
-- ============================================================================
local BAD_STATES = {
    Enum.HumanoidStateType.FallingDown,
    Enum.HumanoidStateType.Ragdoll,
    Enum.HumanoidStateType.PlatformStand,
    Enum.HumanoidStateType.Seated,
    Enum.HumanoidStateType.GettingUp,
}

local BODY_MOVER_CLASSES = {
    BodyVelocity = true,
    BodyAngularVelocity = true,
    BodyForce = true,
    BodyThrust = true,
    BodyPosition = true,
    LinearVelocity = true,
    AngularVelocity = true,
    VectorForce = true,
}

-- Detecta si el jugador lleva actualmente un Brainrot (por Tool, Weld o Atributo)
local function checkCarryingState(char, hrp)
    if not char or not hrp then return false, "Ninguno" end

    -- 1. Revisar atributos del personaje o jugador
    for _, container in ipairs({char, LocalPlayer}) do
        for k, v in pairs(container:GetAttributes()) do
            local lk = tostring(k):lower()
            if (lk:find("carry") or lk:find("brainrot") or lk:find("holding") or lk:find("steal")) and v ~= false and v ~= "" then
                return true, tostring(v ~= true and v or k)
            end
        end
    end

    -- 2. Revisar Tools equipadas que no sean armas de combate conocidas
    local combatTools = { ["bat"] = true, ["grapple hook"] = true, ["bee launcher"] = true, ["coil combo"] = true }
    for _, child in ipairs(char:GetChildren()) do
        if child:IsA("Tool") and not combatTools[child.Name:lower()] then
            return true, child.Name
        end
        if child:IsA("Model") and child ~= char then
            return true, child.Name
        end
    end

    -- 3. Revisar Welds o WeldConstraints conectados al HumanoidRootPart o Torso
    for _, desc in ipairs(char:GetDescendants()) do
        if desc:IsA("WeldConstraint") or desc:IsA("Weld") or desc:IsA("Motor6D") then
            local p0, p1 = desc.Part0, desc.Part1
            local externalPart = (p0 and not p0:IsDescendantOf(char) and p0) or (p1 and not p1:IsDescendantOf(char) and p1)
            if externalPart and externalPart.Parent then
                return true, externalPart.Parent.Name
            end
        end
    end

    return false, "Ninguno"
end

local function applyCharacterProtection(char)
    if not char then return end
    local hum = char:WaitForChild("Humanoid", 5)
    local hrp = char:WaitForChild("HumanoidRootPart", 5)
    if not hum or not hrp then return end

    if hum.WalkSpeed > 20 then
        CFG.baseWalkSpeed = hum.WalkSpeed
    end

    -- Destruir al instante cualquier fuerza de empuje (Bat / Bee Launcher knockback) inyectada en el personaje
    table.insert(STATE.connections, char.DescendantAdded:Connect(function(inst)
        if not CFG.antiDrop then return end
        if BODY_MOVER_CLASSES[inst.ClassName] then
            STATE.stunsBlocked = STATE.stunsBlocked + 1
            task.defer(function()
                pcall(function() inst:Destroy() end)
            end)
        end
    end))
end

if LocalPlayer.Character then
    task.spawn(applyCharacterProtection, LocalPlayer.Character)
end
table.insert(STATE.connections, LocalPlayer.CharacterAdded:Connect(applyCharacterProtection))

-- ============================================================================
-- SECCION 6: MODULO DUEL DISRUPTOR / LAGGER (DESYNC DE HITBOX SIN BANEOS)
-- ============================================================================
local function getClosestRivalDistance(hrp)
    local minDist = math.huge
    local rivalRoot = nil
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local rHrp = plr.Character:FindFirstChild("HumanoidRootPart")
            local rHum = plr.Character:FindFirstChildOfClass("Humanoid")
            if rHrp and rHum and rHum.Health > 0 then
                local d = (rHrp.Position - hrp.Position).Magnitude
                if d < minDist then
                    minDist = d
                    rivalRoot = rHrp
                end
            end
        end
    end
    return minDist, rivalRoot
end

-- ============================================================================
-- SECCION 7: INTERFAZ GRAFICA (SAB DUEL HUB)
-- ============================================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SAB_DuelHub_UI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = getSafeGuiParent()

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 320, 0, 330)
mainFrame.Position = UDim2.new(0.5, -160, 0.5, -165)
mainFrame.BackgroundColor3 = Color3.fromRGB(16, 17, 23)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 8)

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(45, 50, 68)
mainStroke.Thickness = 1.2
mainStroke.Parent = mainFrame

-- Barra superior arrastrable (Compatible con tactil y raton en Delta)
local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 32)
topBar.BackgroundColor3 = Color3.fromRGB(24, 26, 36)
topBar.BorderSizePixel = 0
topBar.Parent = mainFrame
Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 8)

local titleLbl = Instance.new("TextLabel")
titleLbl.Size = UDim2.new(1, -70, 1, 0)
titleLbl.Position = UDim2.new(0, 12, 0, 0)
titleLbl.BackgroundTransparency = 1
titleLbl.Text = "SAB DUEL HUB"
titleLbl.TextColor3 = Color3.fromRGB(240, 242, 250)
titleLbl.Font = Enum.Font.GothamBold
titleLbl.TextSize = 12
titleLbl.TextXAlignment = Enum.TextXAlignment.Left
titleLbl.Parent = topBar

local btnMinimize = Instance.new("TextButton")
btnMinimize.Size = UDim2.new(0, 28, 0, 28)
btnMinimize.Position = UDim2.new(1, -60, 0, 2)
btnMinimize.BackgroundTransparency = 1
btnMinimize.Text = "-"
btnMinimize.TextColor3 = Color3.fromRGB(200, 205, 220)
btnMinimize.Font = Enum.Font.GothamBold
btnMinimize.TextSize = 16
btnMinimize.Parent = topBar

local btnClose = Instance.new("TextButton")
btnClose.Size = UDim2.new(0, 28, 0, 28)
btnClose.Position = UDim2.new(1, -30, 0, 2)
btnClose.BackgroundTransparency = 1
btnClose.Text = "X"
btnClose.TextColor3 = Color3.fromRGB(240, 85, 85)
btnClose.Font = Enum.Font.GothamBold
btnClose.TextSize = 13
btnClose.Parent = topBar

-- Arrastre personalizado fluido (Touch & Mouse)
do
    local dragging, dragInput, dragStart, startPos
    topBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
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
            mainFrame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end))
end

-- Contenedor colapsable para el boton minimizar
local bodyContainer = Instance.new("Frame")
bodyContainer.Size = UDim2.new(1, 0, 1, -32)
bodyContainer.Position = UDim2.new(0, 0, 0, 32)
bodyContainer.BackgroundTransparency = 1
bodyContainer.Parent = mainFrame

-- Barra de Pestañas (DUEL | STEAL)
local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, -20, 0, 28)
tabBar.Position = UDim2.new(0, 10, 0, 8)
tabBar.BackgroundColor3 = Color3.fromRGB(22, 24, 33)
tabBar.BorderSizePixel = 0
tabBar.Parent = bodyContainer
Instance.new("UICorner", tabBar).CornerRadius = UDim.new(0, 6)

local tabDuelBtn = Instance.new("TextButton")
tabDuelBtn.Size = UDim2.new(0.5, -3, 1, -4)
tabDuelBtn.Position = UDim2.new(0, 2, 0, 2)
tabDuelBtn.BackgroundColor3 = Color3.fromRGB(45, 105, 75)
tabDuelBtn.BorderSizePixel = 0
tabDuelBtn.Text = "DUEL"
tabDuelBtn.TextColor3 = Color3.fromRGB(245, 245, 250)
tabDuelBtn.Font = Enum.Font.GothamBold
tabDuelBtn.TextSize = 11
tabDuelBtn.Parent = tabBar
Instance.new("UICorner", tabDuelBtn).CornerRadius = UDim.new(0, 5)

local tabStealBtn = Instance.new("TextButton")
tabStealBtn.Size = UDim2.new(0.5, -3, 1, -4)
tabStealBtn.Position = UDim2.new(0.5, 1, 0, 2)
tabStealBtn.BackgroundColor3 = Color3.fromRGB(28, 30, 42)
tabStealBtn.BorderSizePixel = 0
tabStealBtn.Text = "STEAL"
tabStealBtn.TextColor3 = Color3.fromRGB(210, 215, 230)
tabStealBtn.Font = Enum.Font.GothamBold
tabStealBtn.TextSize = 11
tabStealBtn.Parent = tabBar
Instance.new("UICorner", tabStealBtn).CornerRadius = UDim.new(0, 5)

local pageDuel = Instance.new("Frame")
pageDuel.Size = UDim2.new(1, -20, 1, -74)
pageDuel.Position = UDim2.new(0, 10, 0, 42)
pageDuel.BackgroundTransparency = 1
pageDuel.Visible = true
pageDuel.Parent = bodyContainer

local pageSteal = Instance.new("Frame")
pageSteal.Size = UDim2.new(1, -20, 1, -74)
pageSteal.Position = UDim2.new(0, 10, 0, 42)
pageSteal.BackgroundTransparency = 1
pageSteal.Visible = false
pageSteal.Parent = bodyContainer

tabDuelBtn.MouseButton1Click:Connect(function()
    pageDuel.Visible = true
    pageSteal.Visible = false
    tabDuelBtn.BackgroundColor3 = Color3.fromRGB(45, 105, 75)
    tabStealBtn.BackgroundColor3 = Color3.fromRGB(28, 30, 42)
end)

tabStealBtn.MouseButton1Click:Connect(function()
    pageDuel.Visible = false
    pageSteal.Visible = true
    tabStealBtn.BackgroundColor3 = Color3.fromRGB(45, 105, 75)
    tabDuelBtn.BackgroundColor3 = Color3.fromRGB(28, 30, 42)
end)

-- Constructor de tarjetas con interruptor ON/OFF independiente
local function createToggleCard(parentPage, yPos, titleText, subText, initialValue, onToggle)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 58)
    card.Position = UDim2.new(0, 0, 0, yPos)
    card.BackgroundColor3 = Color3.fromRGB(22, 24, 34)
    card.BorderSizePixel = 0
    card.Parent = parentPage
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 6)

    local lblTitle = Instance.new("TextLabel")
    lblTitle.Size = UDim2.new(1, -82, 0, 20)
    lblTitle.Position = UDim2.new(0, 10, 0, 6)
    lblTitle.BackgroundTransparency = 1
    lblTitle.Text = titleText
    lblTitle.TextColor3 = Color3.fromRGB(238, 240, 250)
    lblTitle.Font = Enum.Font.GothamBold
    lblTitle.TextSize = 11
    lblTitle.TextXAlignment = Enum.TextXAlignment.Left
    lblTitle.Parent = card

    local lblSub = Instance.new("TextLabel")
    lblSub.Size = UDim2.new(1, -82, 0, 28)
    lblSub.Position = UDim2.new(0, 10, 0, 24)
    lblSub.BackgroundTransparency = 1
    lblSub.Text = subText
    lblSub.TextColor3 = Color3.fromRGB(165, 172, 190)
    lblSub.Font = Enum.Font.Gotham
    lblSub.TextSize = 9
    lblSub.TextWrapped = true
    lblSub.TextXAlignment = Enum.TextXAlignment.Left
    lblSub.Parent = card

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 62, 0, 28)
    toggleBtn.Position = UDim2.new(1, -70, 0.5, -14)
    toggleBtn.BorderSizePixel = 0
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.TextSize = 11
    toggleBtn.TextColor3 = Color3.fromRGB(245, 245, 250)
    toggleBtn.Parent = card
    Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 6)

    local state = initialValue
    local function refreshVisual()
        toggleBtn.Text = state and "ON" or "OFF"
        toggleBtn.BackgroundColor3 = state
            and Color3.fromRGB(40, 145, 80)
            or Color3.fromRGB(60, 62, 78)
    end
    refreshVisual()

    toggleBtn.MouseButton1Click:Connect(function()
        state = not state
        refreshVisual()
        onToggle(state)
    end)

    return card, lblSub
end

-- ============================================================================
-- CONTENIDO PESTAÑA 1: DUEL (ANTI DROP BRAINROT + LAGGER)
-- ============================================================================
local _, lblAntiDropSub = createToggleCard(
    pageDuel,
    0,
    "Anti Drop Brainrot",
    "Anula empuje (Bat/Coil), purga Stun/Medusa, fija WalkSpeed (34) y Re-Agarra si cae.",
    CFG.antiDrop,
    function(enabled)
        CFG.antiDrop = enabled
    end
)

local _, lblLaggerSub = createToggleCard(
    pageDuel,
    64,
    "Lagger (Duel Hitbox Disruptor)",
    "Micro-Desync fisico en tu HRP cuando un rival entra a <22 studs (No satura red).",
    CFG.duelLagger,
    function(enabled)
        CFG.duelLagger = enabled
    end
)

local duelTelemetryBox = Instance.new("TextLabel")
duelTelemetryBox.Size = UDim2.new(1, 0, 0, 82)
duelTelemetryBox.Position = UDim2.new(0, 0, 0, 130)
duelTelemetryBox.BackgroundColor3 = Color3.fromRGB(19, 21, 29)
duelTelemetryBox.BorderSizePixel = 0
duelTelemetryBox.Text = " Estado Transporte: Inactivo\n Stuns/Empujes neutralizados: 0\n Estado Rival cercano: Ninguno"
duelTelemetryBox.TextColor3 = Color3.fromRGB(195, 205, 225)
duelTelemetryBox.Font = Enum.Font.Gotham
duelTelemetryBox.TextSize = 10
duelTelemetryBox.TextXAlignment

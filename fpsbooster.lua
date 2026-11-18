-- Steal a Brainrot | ULTIMATE CPU & LAG KILLER + ANTI-ZOOM + FPS COUNTER
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local MaterialService = game:GetService("MaterialService")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Terrain = Workspace:FindFirstChildOfClass("Terrain")
local LocalPlayer = Players.LocalPlayer

-- 0. BLOQUEO ABSOLUTO DE ZOOMS DINÁMICOS Y EFECTOS DE IMPACTO EN CÁMARA
task.spawn(function()
    RunService.RenderStepped:Connect(function()
        pcall(function()
            local cam = Workspace.CurrentCamera
            if cam then
                -- Forzar FOV estático para evitar cualquier zoom dinámico por abrir interfaces o golpes
                cam.FieldOfView = 70
                -- Anular sacudidas de cámara (CameraShakes) forzando el tipo de cámara estándar
                if cam.CameraType ~= Enum.CameraType.Custom and cam.CameraType ~= Enum.CameraType.Follow then
                    cam.CameraType = Enum.CameraType.Custom
                end
            end
        end)
    end)
end)

-- 1. Desbloquear FPS y forzar renderizado mínimo del motor
pcall(function()
    if setfpscap then setfpscap(999) end
    settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level01
    settings().Rendering.EagerBulkExecution = false
end)

pcall(function()
    if setfflag then
        setfflag("DFFlagDebugRenderForceTechnologyVoxel", "True")
        setfflag("FFlagDebugDisableOTAMaterialTexture", "True")
        setfflag("DFIntTaskSchedulerTargetFps", "999")
    end
end)

-- 2. Contador de FPS en tiempo real
local FpsGui = Instance.new("ScreenGui")
FpsGui.Name = "SAB_FpsCounter"
FpsGui.IgnoreGuiInset = true
FpsGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

pcall(function()
    FpsGui.Parent = CoreGui
end)
if not FpsGui.Parent and LocalPlayer:FindFirstChild("PlayerGui") then
    FpsGui.Parent = LocalPlayer.PlayerGui
end

local FpsLabel = Instance.new("TextLabel")
FpsLabel.Name = "FpsText"
FpsLabel.Size = UDim2.new(0, 120, 0, 30)
FpsLabel.Position = UDim2.new(0.5, -60, 0, 5)
FpsLabel.BackgroundTransparency = 0.5
FpsLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
FpsLabel.TextColor3 = Color3.fromRGB(0, 255, 128)
FpsLabel.TextSize = 16
FpsLabel.Font = Enum.Font.Code
FpsLabel.Text = "FPS: --"
FpsLabel.Parent = FpsGui

local frameCount = 0
local lastTick = tick()

RunService.RenderStepped:Connect(function()
    frameCount = frameCount + 1
    local currentTick = tick()
    if currentTick - lastTick >= 0.5 then
        local fps = math.floor(frameCount / (currentTick - lastTick) + 0.5)
        FpsLabel.Text = "FPS: " .. tostring(fps)
        
        if fps < 30 then
            FpsLabel.TextColor3 = Color3.fromRGB(255, 60, 60)
        elseif fps < 60 then
            FpsLabel.TextColor3 = Color3.fromRGB(255, 220, 0)
        else
            FpsLabel.TextColor3 = Color3.fromRGB(0, 255, 128)
        end

        frameCount = 0
        lastTick = currentTick
    end
end)

-- 3. Ahorro de CPU al minimizar la ventana
UserInputService.WindowFocusReleased:Connect(function()
    pcall(function() RunService:Set3dRenderingEnabled(false) end)
end)

UserInputService.WindowFocused:Connect(function()
    pcall(function() RunService:Set3dRenderingEnabled(true) end)
end)

-- 4. Clases a DESTRUIR (Partículas, efectos de golpe, brillos, luces y física pesada)
local DestroyClasses = {
    ["ParticleEmitter"] = true, ["Trail"] = true, ["Beam"] = true,
    ["Fire"] = true, ["Smoke"] = true, ["Sparkles"] = true,
    ["Highlight"] = true, ["PointLight"] = true, ["SpotLight"] = true, ["SurfaceLight"] = true,
    ["Explosion"] = true, ["ForceField"] = true, ["SelectionBox"] = true, ["SelectionSphere"] = true,
    ["SurfaceAppearance"] = true, ["MaterialVariant"] = true,
    ["Accessory"] = true, ["Hat"] = true, ["WrapLayer"] = true, ["WrapTarget"] = true,
    ["Shirt"] = true, ["Pants"] = true, ["ShirtGraphic"] = true, ["CharacterMesh"] = true,
    ["Sky"] = true, ["Atmosphere"] = true, ["Clouds"] = true,
    ["BloomEffect"] = true, ["BlurEffect"] = true, ["ColorCorrectionEffect"] = true,
    ["SunRaysEffect"] = true, ["DepthOfFieldEffect"] = true, ["Animation"] = true
}

-- Palabras clave para eliminar textos flotantes de dinero, daños y elementos de bases ajenas
local BlockedKeywords = {
    "cash", "money", "coin", "cha-ching", "register", "buy", "purchase",
    "damage", "hit", "popup", "floating", "text", "label", "ui",
    "music", "bgm", "theme", "song", "ambient", "wind", "rain",
    "click", "hover", "button", "error", "fail", "notification",
    "footstep", "step", "walk", "jump", "land", "punch", "slap",
    "event", "nyan", "cat", "taco", "raining", "crab", "rave",
    "meteor", "comet", "starfall", "solar", "flare", "galactic",
    "blood", "moon", "glitch", "bomb", "bombardiro", "raid",
    "firework", "ufo", "alien", "zombie", "explosion", "boom", "laser"
}

local function ShouldMuteSound(soundObj)
    if soundObj:IsDescendantOf(SoundService) or (LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui") and soundObj:IsDescendantOf(LocalPlayer.PlayerGui)) then
        return true
    end
    if soundObj.Looped then return true end

    local name = soundObj.Name:lower()
    local parentName = soundObj.Parent and soundObj.Parent.Name:lower() or ""
    for _, kw in ipairs(BlockedKeywords) do
        if name:find(kw) or parentName:find(kw) then return true end
    end
    return false
end

-- Decoración y elementos de bases a eliminar
local DecorKeywords = {"tree", "bush", "grass", "flower", "rock", "stone", "cloud", "star", "lamp", "light", "fence", "decor", "prop", "plant", "foliage", "leaves"}
local TrackedBillboards = {}

local function NukeAll(obj)
    if not obj or not obj.Parent then return end
    if obj == FpsGui or obj:IsDescendantOf(FpsGui) then return end

    -- Si es texto flotante de dinero o daño en pantalla, destruirlo al instante
    if obj:IsA("TextLabel") or obj:IsA("BillboardGui") or obj:IsA("SurfaceGui") then
        local name = obj.Name:lower()
        local textVal = (obj:IsA("TextLabel") and obj.Text:lower() or "")
        for _, kw in ipairs(BlockedKeywords) do
            if name:find(kw) or textVal:find(kw) or textVal:find("$") or textVal:find("🪙") or textVal:find("💵") then
                pcall(function() obj:Destroy() end)
                return
            end
        end
    end

    if DestroyClasses[obj.ClassName] then
        pcall(function() obj:Destroy() end)
        return
    end

    if obj:IsA("Animator") or obj:IsA("AnimationController") then
        pcall(function()
            if obj:IsA("Animator") then
                for _, track in ipairs(obj:GetPlayingAnimationTracks()) do track:Stop(0) end
            end
            obj:Destroy()
        end)
        return
    end

    if obj:IsA("LocalScript") and obj.Name == "Animate" then
        pcall(function() obj.Disabled = true obj:Destroy() end)
        return
    end

    if obj:IsA("Decal") or obj:IsA("Texture") then
        pcall(function() obj:Destroy() end)
        return
    end

    if obj:IsA("BillboardGui") then
        pcall(function() obj.MaxDistance = 60 end) -- Reducir distancia drásticamente para que no carguen carteles lejanos
        table.insert(TrackedBillboards, obj)
        return
    end

    if obj:IsA("BasePart") then
        local n = obj.Name:lower()
        for _, kw in ipairs(DecorKeywords) do
            if n:find(kw) and not obj:FindFirstChildOfClass("TouchTransmitter") and not obj:FindFirstChildOfClass("ProximityPrompt") and not obj:FindFirstChildOfClass("ClickDetector") then
                pcall(function() obj:Destroy() end)
                return
            end
        end

        pcall(function()
            obj.Material = Enum.Material.SmoothPlastic
            obj.Reflectance = 0
            obj.CastShadow = false
            obj.EnableFluidForces = false
            -- Desactivar canCollide en piezas decorativas lejanas para liberar CPU en físicas
            if not obj.Anchored and not obj:IsDescendantOf(LocalPlayer.Character or workspace) then
                obj.CustomPhysicalProperties = PhysicalProperties.new(0.01, 0.01, 0, 0, 0)
            end
        end)
        if obj:IsA("MeshPart") then
            pcall(function()
                obj.TextureID = ""
                obj.RenderFidelity = Enum.RenderFidelity.Performance
            end)
        end
        return
    end

    if obj:IsA("SpecialMesh") then
        pcall(function() obj.TextureId = "" end)
        return
    end

    if obj:IsA("Sound") then
        pcall(function()
            if ShouldMuteSound(obj) then
                obj.Volume = 0
                obj:Stop()
            else
                obj.Volume = 1
            end
        end)
    end
end

-- Optimizar jugadores lejanos y sus Brainrots (Congelar animaciones y lógica de CPU lejana)
local function OptimizePlayer(player)
    if player == LocalPlayer then return end
    local function onChar(char)
        if not char then return end
        task.defer(function()
            for _, item in ipairs(char:GetDescendants()) do NukeAll(item) end
        end)
        -- Si un jugador u objeto de su base se aleja, desactivamos scripts y animaciones para ahorrar CPU
        task.spawn(function()
            while char and char.Parent do
                task.wait(1)
                local root = char:FindFirstChild("HumanoidRootPart")
                local localRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if root and localRoot then
                    local dist = (root.Position - localRoot.Position).Magnitude
                    local isFar = dist > 80 -- Si están a más de 80 studs, congelamos su render de CPU secundario
                    for _, part in ipairs(char:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.LocalTransparencyModifier = isFar and 0.8 or 0
                        end
                    end
                end
            end
        end)
    end
    if player.Character then onChar(player.Character) end
    player.CharacterAdded:Connect(onChar)
end

for _, p in ipairs(Players:GetPlayers()) do OptimizePlayer(p) end
Players.PlayerAdded:Connect(OptimizePlayer)

-- Barrido inicial en todo el mapa
for _, v in ipairs(Workspace:GetDescendants()) do NukeAll(v) end
for _, v in ipairs(Lighting:GetDescendants()) do NukeAll(v) end
for _, v in ipairs(MaterialService:GetDescendants()) do NukeAll(v) end
for _, v in ipairs(SoundService:GetDescendants()) do NukeAll(v) end

if Terrain then
    pcall(function()
        Terrain.WaterWaveSize = 0
        Terrain.WaterWaveSpeed = 0
        Terrain.WaterReflectance = 0
        Terrain.WaterTransparency = 0
        Terrain.Decoration = false
        Terrain:Clear()
    end)
end

local function EnforceBasicLighting()
    pcall(function()
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        Lighting.FogStart = 9e9
        Lighting.Brightness = 1.5
        Lighting.Ambient = Color3.fromRGB(185, 185, 185)
        Lighting.OutdoorAmbient = Color3.fromRGB(185, 185, 185)
        Lighting.ClockTime = 14
        Lighting.EnvironmentDiffuseScale = 0
        Lighting.EnvironmentSpecularScale = 0
        Lighting.ShadowSoftness = 0
    end)
end
EnforceBasicLighting()

-- Vigilancia en tiempo real para destruir nuevos elementos de dinero o partículas de golpes
Workspace.DescendantAdded:Connect(function(desc) task.defer(function() NukeAll(desc) end) end)
Lighting.DescendantAdded:Connect(function(desc) task.defer(function() NukeAll(desc) end) end)
SoundService.DescendantAdded:Connect(function(desc) task.defer(function() NukeAll(desc) end) end)

-- Gestión dinámica de distancia para billboards y rendimiento de cámara
task.spawn(function()
    while task.wait(0.35) do
        EnforceBasicLighting()
        local cam = Workspace.CurrentCamera
        if cam then
            local camPos = cam.CFrame.Position
            local camLook = cam.CFrame.LookVector
            for i = #TrackedBillboards, 1, -1 do
                local bGui = TrackedBillboards[i]
                if not bGui or not bGui.Parent then
                    table.remove(TrackedBillboards, i)
                else
                    local adornee = bGui.Adornee or bGui.Parent
                    if adornee and adornee:IsA("BasePart") then
                        local offset = adornee.Position - camPos
                        local dist = offset.Magnitude
                        if dist > 60 or (dist > 15 and camLook:Dot(offset.Unit) < -0.2) then
                            bGui.Enabled = false
                        else
                            bGui.Enabled = true
                        end
                    end
                end
            end
        end
    end
end)

-- Limpieza agresiva de memoria RAM
task.spawn(function()
    while task.wait(10) do
        collectgarbage("collect")
    end
end)

print("[SAB CPU & LAG KILLER] Rendimiento extremo activado.")

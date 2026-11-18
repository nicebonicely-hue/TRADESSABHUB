-- Steal a Brainrot | ULTIMATE CPU, LAG & TARGETED SOUND KILLER (V2 FIXED)
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

-- 0. EVITAR CONGELAMIENTO DE CÁMARA Y BOMBA DE BAILE
task.spawn(function()
    RunService.RenderStepped:Connect(function()
        pcall(function()
            local cam = Workspace.CurrentCamera
            if cam then
                cam.FieldOfView = 70
                if cam.CameraType ~= Enum.CameraType.Custom and cam.CameraType ~= Enum.CameraType.Follow then
                    cam.CameraType = Enum.CameraType.Custom
                end
            end
            
            local char = LocalPlayer.Character
            if char then
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    if humanoid:GetState() == Enum.HumanoidStateType.PlatformStanding or humanoid:GetState() == Enum.HumanoidStateType.FallingDown then
                        humanoid.PlatformStand = false
                    end
                end
            end
        end)
    end)
end)

-- 1. BLOQUEO DE MICRO-LAGS POR NUEVOS JUGADORES
Players.PlayerAdded:Connect(function(player)
    task.spawn(function()
        pcall(function()
            player.CharacterAdded:Connect(function(char)
                local humanoid = char:WaitForChild("Humanoid", 3)
                if humanoid then
                    pcall(function() humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None end)
                end
            end)
        end)
    end)
end)

-- 2. Desbloquear FPS y forzar renderizado mínimo del motor
pcall(function()
    if setfpscap then setfpscap(999) end
    settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level01
    settings().Rendering.EagerBulkExecution = false
end)

pcall(function()
    if setfflag then
        setfflag("DFFlagDebugRenderForceTechnologyVoxel", "True")
        setfflag("DFIntTaskSchedulerTargetFps", "999")
    end
end)

-- 3. Contador de FPS en tiempo real
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

-- 4. Clases a DESTRUIR por completo (Partículas, rastros, etc.)
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

-- Filtro estricto de audio (Mantiene compras y gears, elimina clics y dinero)
local function ShouldMuteSound(soundObj)
    local name = soundObj.Name:lower()
    local parentName = soundObj.Parent and soundObj.Parent.Name:lower() or ""
    
    if name:find("buy") or name:find("purchase") or name:find("gear") or name:find("equip") or name:find("tool") or
       parentName:find("buy") or parentName:find("purchase") or parentName:find("gear") or parentName:find("equip") or parentName:find("tool") then
        return false
    end

    local MuteKeywords = {
        "click", "hover", "button", "ui", "menu", "press",
        "cash", "money", "coin", "cha-ching", "register",
        "music", "bgm", "theme", "song", "ambient", "wind", "rain",
        "nyan", "cat", "taco", "raining", "crab", "rave", "event",
        "meteor", "comet", "starfall", "solar", "flare", "galactic",
        "blood", "moon", "glitch", "bomb", "bombardiro", "raid",
        "firework", "ufo", "alien", "zombie", "explosion", "boom", "laser",
        "error", "fail", "notification", "footstep", "step", "walk", "jump", "land", "punch", "slap"
    }

    for _, kw in ipairs(MuteKeywords) do
        if name:find(kw) or parentName:find(kw) then
            return true
        end
    end

    return false
end

local DecorKeywords = {"tree", "bush", "grass", "flower", "rock", "stone", "cloud", "star", "lamp", "light", "fence", "decor", "prop", "plant", "foliage", "leaves"}
local TrackedBillboards = {}

local function NukeAll(obj)
    if not obj or not obj.Parent then return end
    if obj == FpsGui or obj:IsDescendantOf(FpsGui) then return end

    if DestroyClasses[obj.ClassName] then
        pcall(function() obj:Destroy() end)
        return
    end

    if obj:IsA("Animator") or obj:IsA("AnimationController") then
        pcall(function()
            if obj:IsA("Animator") then
                for _, track in ipairs(obj:GetPlayingAnimationTracks()) do
                    track:Stop(0)
                end
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
        pcall(function() obj.MaxDistance = 60 end)
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
        end)
        -- SE CORRIGIÓ AQUÍ: NO borramos las texturas de los MeshParts para que los Brainrots mantengan sus colores originales
        if obj:IsA("MeshPart") then
            pcall(function()
                obj.RenderFidelity = Enum.RenderFidelity.Performance
            end)
        end
        return
    end

    if obj:IsA("SpecialMesh") then
        -- Mantenemos el SpecialMesh intacto para que no pierda textura
        return
    end

    if obj:IsA("Sound") then
        pcall(function()
            if ShouldMuteSound(obj) then
                obj.Volume = 0
                obj:Stop()
            end
        end)
    end
end

local function OptimizePlayer(player)
    if player == LocalPlayer then return end
    local function onChar(char)
        if not char then return end
        task.defer(function()
            for _, item in ipairs(char:GetDescendants()) do NukeAll(item) end
        end)
        char.DescendantAdded:Connect(function(desc)
            task.defer(function() NukeAll(desc) end)
        end)
    end
    if player.Character then onChar(player.Character) end
    player.CharacterAdded:Connect(onChar)
end

for _, p in ipairs(Players:GetPlayers()) do OptimizePlayer(p) end
Players.PlayerAdded:Connect(OptimizePlayer)

-- Barrido inicial
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

Workspace.DescendantAdded:Connect(function(desc) task.defer(function() NukeAll(desc) end) end)
Lighting.DescendantAdded:Connect(function(desc) task.defer(function() NukeAll(desc) end) end)
SoundService.DescendantAdded:Connect(function(desc) task.defer(function() NukeAll(desc) end) end)

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

-- Limpieza agresiva de RAM
task.spawn(function()
    while task.wait(10) do
        collectgarbage("collect")
    end
end)

print("[SAB V2 FIXED] Brainrots con colores originales y texturas seguras restaurados.")

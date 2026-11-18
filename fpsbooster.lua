-- Steal a Brainrot | ULTIMATE FPS OPTIMIZER + LIVE FPS COUNTER (Delta Executor)
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

-- 2. Crear Contador de FPS en tiempo real en la parte superior
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
FpsLabel.Position = UDim2.new(0.5, -60, 0, 5) -- Centrado arriba
FpsLabel.BackgroundTransparency = 0.5
FpsLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
FpsLabel.TextColor3 = Color3.fromRGB(0, 255, 128) -- Verde brillante legible
FpsLabel.TextSize = 16
FpsLabel.Font = Enum.Font.Code
FpsLabel.Text = "FPS: --"
FpsLabel.Parent = FpsGui

-- Bucle ultrarrápido para actualizar los FPS reales en tiempo real sin congelar
local frameCount = 0
local lastTick = tick()

RunService.RenderStepped:Connect(function()
    frameCount = frameCount + 1
    local currentTick = tick()
    if currentTick - lastTick >= 0.5 then -- Actualiza cada medio segundo para que el número sea estable
        local fps = math.floor(frameCount / (currentTick - lastTick) + 0.5)
        FpsLabel.Text = "FPS: " .. tostring(fps)
        
        -- Cambiar color a rojo si bajan de 30, amarillo si están estables, verde si van a más de 60
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

-- 3. Apagar renderizado 3D cuando sales de la ventana / minimizas (ahorra batería y CPU)
UserInputService.WindowFocusReleased:Connect(function()
    pcall(function() RunService:Set3dRenderingEnabled(false) end)
end)

UserInputService.WindowFocused:Connect(function()
    pcall(function() RunService:Set3dRenderingEnabled(true) end)
end)

-- 4. Clases a DESTRUIR por completo
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

-- Lista negra de sonidos (dinero, UI, música y eventos)
local BlockedSoundKeywords = {
    "cash", "money", "coin", "cha-ching", "register", "buy", "purchase",
    "music", "bgm", "theme", "song", "ambient", "wind", "rain",
    "click", "hover", "button", "error", "fail", "notification",
    "footstep", "step", "walk", "jump", "land", "hit", "punch", "slap",
    "event", "nyan", "cat", "taco", "raining", "crab", "rave",
    "meteor", "comet", "starfall", "solar", "flare", "galactic",
    "blood", "moon", "glitch", "bomb", "bombardiro", "raid",
    "firework", "4th", "july", "ufo", "alien", "zombie", "explosion", "boom", "laser"
}

local function ShouldMuteSound(soundObj)
    if soundObj:IsDescendantOf(SoundService) or (LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui") and soundObj:IsDescendantOf(LocalPlayer.PlayerGui)) then
        return true
    end
    if soundObj.Looped then return true end

    local name = soundObj.Name:lower()
    local parentName = soundObj.Parent and soundObj.Parent.Name:lower() or ""
    for _, kw in ipairs(BlockedSoundKeywords) do
        if name:find(kw) or parentName:find(kw) then return true end
    end
    return false
end

-- Decoración a destruir
local DecorKeywords = {"tree", "bush", "grass", "flower", "rock", "stone", "cloud", "star", "lamp", "light", "fence", "decor", "prop", "plant", "foliage", "leaves"}
local TrackedBillboards = {}

local function NukeAll(obj)
    if not obj or not obj.Parent then return end
    if obj == FpsGui or obj:IsDescendantOf(FpsGui) then return end -- No tocar nuestro contador de FPS

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
        pcall(function() obj.MaxDistance = 120 end)
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

-- Limpieza de personajes visibles estáticos
local function StripCharacter(char)
    if not char then return end
    task.defer(function()
        for _, item in ipairs(char:GetDescendants()) do NukeAll(item) end
    end)
    char.DescendantAdded:Connect(function(desc)
        task.defer(function() NukeAll(desc) end)
    end)
end

for _, player in ipairs(Players:GetPlayers()) do
    if player.Character then StripCharacter(player.Character) end
    player.CharacterAdded:Connect(StripCharacter)
end
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(StripCharacter)
end)

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

-- Vigilancia en tiempo real
Workspace.DescendantAdded:Connect(function(desc) task.defer(function() NukeAll(desc) end) end)
Lighting.DescendantAdded:Connect(function(desc) task.defer(function() NukeAll(desc) end) end)
SoundService.DescendantAdded:Connect(function(desc) task.defer(function() NukeAll(desc) end) end)

-- Oclusión por cámara
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
                        if dist > 110 or (dist > 15 and camLook:Dot(offset.Unit) < -0.2) then
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

-- Limpieza de RAM
task.spawn(function()
    while task.wait(15) do
        collectgarbage("collect")
    end
end)

print("[SAB GOD-MODE + FPS COUNTER] Todo listo al máximo rendimiento.")

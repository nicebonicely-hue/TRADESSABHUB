-- Steal a Brainrot | GOD-MODE FPS + BRAINROT VOICES ONLY (Delta Executor)
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local MaterialService = game:GetService("MaterialService")
local SoundService = game:GetService("SoundService")
local Terrain = Workspace:FindFirstChildOfClass("Terrain")
local LocalPlayer = Players.LocalPlayer

-- 1. Desbloquear FPS y forzar renderizado mínimo absoluto
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

-- 2. Clases a DESTRUIR por completo en todo el juego
local DestroyClasses = {
    ["ParticleEmitter"] = true,
    ["Trail"] = true,
    ["Beam"] = true,
    ["Fire"] = true,
    ["Smoke"] = true,
    ["Sparkles"] = true,
    ["Highlight"] = true,
    ["PointLight"] = true,
    ["SpotLight"] = true,
    ["SurfaceLight"] = true,
    ["Explosion"] = true,
    ["ForceField"] = true,
    ["SelectionBox"] = true,
    ["SelectionSphere"] = true,
    ["SurfaceAppearance"] = true,
    ["MaterialVariant"] = true,
    ["Accessory"] = true,
    ["Hat"] = true,
    ["WrapLayer"] = true,
    ["WrapTarget"] = true,
    ["Shirt"] = true,
    ["Pants"] = true,
    ["ShirtGraphic"] = true,
    ["CharacterMesh"] = true,
    ["Sky"] = true,
    ["Atmosphere"] = true,
    ["Clouds"] = true,
    ["BloomEffect"] = true,
    ["BlurEffect"] = true,
    ["ColorCorrectionEffect"] = true,
    ["SunRaysEffect"] = true,
    ["DepthOfFieldEffect"] = true,
    ["Animation"] = true
}

-- Lista negra de sonidos genéricos que SÍ queremos apagar (dinero, música, clics, eventos)
local BlockedSoundKeywords = {
    "cash", "money", "coin", "cha-ching", "register", "buy", "purchase",
    "music", "bgm", "theme", "song", "ambient", "wind", "rain",
    "click", "hover", "button", "error", "fail", "notification",
    "event", "taco", "meteor", "explosion", "boom", "laser", "glitch",
    "footstep", "step", "walk", "jump", "land", "hit", "punch", "slap"
}

-- Función para decidir si el sonido debe silenciarse o si es la voz de un Brainrot
local function ShouldMuteSound(soundObj)
    -- Si está en SoundService o PlayerGui, casi siempre es música, UI o dinero -> silenciar
    if soundObj:IsDescendantOf(SoundService) or (LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui") and soundObj:IsDescendantOf(LocalPlayer.PlayerGui)) then
        return true
    end

    -- Si está en bucle (Looped = true), es música de fondo o ruido ambiental -> silenciar
    if soundObj.Looped then
        return true
    end

    local name = soundObj.Name:lower()
    local parentName = soundObj.Parent and soundObj.Parent.Name:lower() or ""

    -- Revisar si coincide con sonidos de dinero, música, clics o eventos
    for _, kw in ipairs(BlockedSoundKeywords) do
        if name:find(kw) or parentName:find(kw) then
            return true
        end
    end

    -- Si está dentro de un modelo/pieza en Workspace y no es música ni dinero, es la voz del Brainrot -> DEJAR ACTIVO
    return false
end

-- Función limpiadora universal
local function NukeAll(obj)
    if not obj or not obj.Parent then return end

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
        pcall(function()
            obj.Disabled = true
            obj:Destroy()
        end)
        return
    end

    if obj:IsA("Decal") or obj:IsA("Texture") then
        pcall(function() obj:Destroy() end)
        return
    end

    if obj:IsA("BasePart") then
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

    -- Filtro de Audio: Silencia dinero, música y eventos; deja intactas las voces de los Brainrots
    if obj:IsA("Sound") then
        pcall(function()
            if ShouldMuteSound(obj) then
                obj.Volume = 0
                obj:Stop()
            else
                obj.Volume = 1 -- Voz del Brainrot (ej. Nobini Pizzanini) activa
            end
        end)
    end
end

-- Limpieza del propio personaje al reaparecer
local function StripCharacter(char)
    if not char then return end
    task.defer(function()
        for _, item in ipairs(char:GetDescendants()) do NukeAll(item) end
    end)
    char.DescendantAdded:Connect(function(desc)
        task.defer(function() NukeAll(desc) end)
    end)
end

if LocalPlayer then
    if LocalPlayer.Character then StripCharacter(LocalPlayer.Character) end
    LocalPlayer.CharacterAdded:Connect(StripCharacter)
end

-- 3. Barrido masivo inicial
for _, v in ipairs(Workspace:GetDescendants()) do NukeAll(v) end
for _, v in ipairs(Lighting:GetDescendants()) do NukeAll(v) end
for _, v in ipairs(MaterialService:GetDescendants()) do NukeAll(v) end
for _, v in ipairs(SoundService:GetDescendants()) do NukeAll(v) end

-- 4. Limpiar terreno y agua
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

-- 5. Iluminación plana
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

-- 6. Limpiar overlays de pantalla
local function CleanGui(gui)
    if not gui or not gui.Parent then return end
    local n = gui.Name:lower()
    if n:find("vignette") or n:find("flash") or n:find("glitch") or n:find("blood") or n:find("effect") or n:find("vfx") or n:find("shader") or n:find("overlay") then
        if gui:IsA("ImageLabel") or gui:IsA("Frame") then
            pcall(function() gui:Destroy() end)
        end
    end
end

if LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui") then
    for _, g in ipairs(LocalPlayer.PlayerGui:GetDescendants()) do CleanGui(g) end
    LocalPlayer.PlayerGui.DescendantAdded:Connect(function(d)
        task.defer(function() CleanGui(d) end)
    end)
end

-- 7. Monitoreo en tiempo real
Workspace.DescendantAdded:Connect(function(desc)
    task.defer(function() NukeAll(desc) end)
end)

Lighting.DescendantAdded:Connect(function(desc)
    task.defer(function() NukeAll(desc) end)
end)

SoundService.DescendantAdded:Connect(function(desc)
    task.defer(function() NukeAll(desc) end)
end)

-- Mantenimiento y limpieza de RAM
task.spawn(function()
    while task.wait(0.5) do
        EnforceBasicLighting()
    end
end)

task.spawn(function()
    while task.wait(25) do
        collectgarbage("collect")
    end
end)

print("[SAB GOD-MODE] Dinero/música/efectos silenciados. Solo voces de Brainrots activas.")

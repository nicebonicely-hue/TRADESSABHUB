--[[
    ========================================================
    SAB MACHINE HUB v3.1 - Force Insert & Bypass Edition
    Game: Steal a Brainrot (SAB)
    ========================================================
]]--

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

local _G_Settings = {
    SelectedMachine = nil,
    SelectedMachineObj = nil,
    FastPrompt = false
}

-- Crear interfaz flotante optimizada para Delta
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SABForceHub"
ScreenGui.ResetOnSpawn = false
if syn and syn.protect_gui then
    syn.protect_gui(ScreenGui)
    ScreenGui.Parent = CoreGui
elseif gethui then
    ScreenGui.Parent = gethui()
else
    ScreenGui.Parent = CoreGui
end

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 380, 0, 380)
MainFrame.Position = UDim2.new(0.5, -190, 0.5, -190)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 14, 28)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = MainFrame

-- Barra superior
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 35)
TopBar.BackgroundColor3 = Color3.fromRGB(28, 22, 44)
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame

local TopCorner = Instance.new("UICorner")
TopCorner.CornerRadius = UDim.new(0, 10)
TopCorner.Parent = TopBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -50, 1, 0)
Title.Position = UDim2.new(0, 12, 0, 0)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.Text = "SAB FORCE INSERTER v3.1"
Title.TextColor3 = Color3.fromRGB(220, 200, 255)
Title.TextSize = 13
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 28, 0, 28)
CloseBtn.Position = UDim2.new(1, -33, 0, 3.5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.new(1, 1, 1)
CloseBtn.TextSize = 11
CloseBtn.Parent = TopBar

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = CloseBtn

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- Contenedor de pestañas
local ContentContainer = Instance.new("ScrollingFrame")
ContentContainer.Size = UDim2.new(1, -20, 1, -55)
ContentContainer.Position = UDim2.new(0, 10, 0, 45)
ContentContainer.BackgroundTransparency = 1
ContentContainer.BorderSizePixel = 0
ContentContainer.CanvasSize = UDim2.new(0, 0, 2.5, 0)
ContentContainer.ScrollBarThickness = 4
ContentContainer.Parent = MainFrame

local UIList = Instance.new("UIListLayout")
UIList.SortOrder = Enum.SortOrder.LayoutOrder
UIList.Padding = UDim.new(0, 6)
UIList.Parent = ContentContainer

local function AddButton(text, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 34)
    btn.BackgroundColor3 = Color3.fromRGB(45, 35, 70)
    btn.Font = Enum.Font.GothamMedium
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(230, 220, 255)
    btn.TextSize = 11
    btn.Parent = ContentContainer
    
    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(0, 6)
    bc.Parent = btn
    
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- Función para detectar qué objeto llevamos en las manos
local function GetCarriedBrainrot()
    local char = LocalPlayer.Character
    if not char then return nil end
    -- Buscar herramientas equipadas o modelos en las manos
    for _, item in pairs(char:GetChildren()) do
        if item:IsA("Tool") then
            return item
        end
    end
    return nil
end

-- 1. ESCANEAR Y SELECCIONAR MÁQUINAS
AddButton("🔍 Scan & List Machines (Click to Select)", function()
    -- Limpiar botones anteriores de máquinas en la UI si existen
    for _, child in pairs(ContentContainer:GetChildren()) do
        if child.Name == "DynamicMachineBtn" then
            child:Destroy()
        end
    end

    local count = 0
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("Part") then
            local nameLower = obj.Name:lower()
            if nameLower:find("machine") or nameLower:find("cauldron") or nameLower:find("craft") or nameLower:find("fuse") or nameLower:find("sab") then
                count = count + 1
                local mBtn = Instance.new("TextButton")
                mBtn.Name = "DynamicMachineBtn"
                mBtn.Size = UDim2.new(1, 0, 0, 30)
                mBtn.BackgroundColor3 = Color3.fromRGB(32, 25, 50)
                mBtn.Font = Enum.Font.Gotham
                mBtn.Text = "⚙️ [" .. obj.Name .. "] (Select & TP)"
                mBtn.TextColor3 = Color3.fromRGB(200, 180, 240)
                mBtn.TextSize = 10
                mBtn.Parent = ContentContainer
                
                local mc = Instance.new("UICorner")
                mc.CornerRadius = UDim.new(0, 5)
                mc.Parent = mBtn
                
                mBtn.MouseButton1Click:Connect(function()
                    _G_Settings.SelectedMachine = obj.Name
                    _G_Settings.SelectedMachineObj = obj
                    mBtn.BackgroundColor3 = Color3.fromRGB(80, 40, 140)
                    print("Máquina seleccionada:", obj.Name)
                    
                    -- Teletransportarse cerca para facilitar el contacto del servidor
                    local targetPart = obj:IsA("Model") and obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                    if targetPart and HumanoidRootPart then
                        HumanoidRootPart.CFrame = targetPart.CFrame + Vector3.new(0, 2, 0)
                    end
                end)
            end
        end
    end
    print("Máquinas encontradas:", count)
end)

-- 2. FORZAR INSERCIÓN MEDIANTE PROXIMITY PROMPT
AddButton("⚡ Force ProximityPrompt on Selected Machine", function()
    local target = _G_Settings.SelectedMachineObj
    if not target then
        print("¡Primero selecciona una máquina de la lista!")
        return
    end

    local promptFound = false
    for _, prompt in pairs(target:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") then
            promptFound = true
            prompt.HoldDuration = 0
            prompt.MaxActivationDistance = 9999
            
            -- Disparar múltiples veces para simular la interacción real
            task.spawn(function()
                for i = 1, 3 do
                    fireproximityprompt(prompt)
                    task.wait(0.1)
                end
            end)
            print("Prompt forzado en:", target.Name)
        end
    end

    if not promptFound then
        -- Buscar prompts cercanos en todo el Workspace si la máquina no tiene uno directo
        for _, prompt in pairs(Workspace:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") and HumanoidRootPart then
                if (prompt.Parent and prompt.Parent:IsA("BasePart") and (prompt.Parent.Position - HumanoidRootPart.Position).Magnitude < 15) then
                    prompt.HoldDuration = 0
                    fireproximityprompt(prompt)
                    print("Prompt cercano forzado.")
                end
            end
        end
    end
end)

-- 3. DISPARAR REMOTES DE INSERCIÓN CON EL BRAINROT
AddButton("🚀 Fire Insertion Remotes (Bypass Server Check)", function()
    local carriedItem = GetCarriedBrainrot()
    local targetName = _G_Settings.SelectedMachine or "Unknown"
    
    print("Objeto en manos detectado:", carriedItem and carriedItem.Name or "Ninguno / Ninguna Tool equipada")

    local firedCount = 0
    for _, remote in pairs(ReplicatedStorage:GetDescendants()) do
        if remote:IsA("RemoteEvent") then
            local rName = remote.Name:lower()
            -- Filtrar remotes relacionados con depositar, fusionar o interactuar
            if rName:find("deposit") or rName:find("insert") or rName:find("fuse") or rName:find("brainrot") or rName:find("interact") or rName:find("give") then
                pcall(function()
                    -- Intentar diferentes combinaciones de argumentos que el servidor podría requerir
                    if carriedItem then
                        remote:FireServer(carriedItem, _G_Settings.SelectedMachineObj)
                        remote:FireServer(carriedItem.Name, targetName)
                    end
                    remote:FireServer("Insert", targetName)
                    remote:FireServer(_G_Settings.SelectedMachineObj)
                    remote:FireServer()
                    firedCount = firedCount + 1
                end)
            end
        end
    end
    print("Remotes disparados con intentos de inserción:", firedCount)
end)

-- 4. ACTIVAR LOOP DE PROMPTS RÁPIDOS
AddButton("🔄 Toggle Fast/Instant Prompts (ON/OFF)", function()
    _G_Settings.FastPrompt = not _G_Settings.FastPrompt
    print("FastPrompt estado:", _G_Settings.FastPrompt)
    
    task.spawn(function()
        while _G_Settings.FastPrompt do
            task.wait(0.3)
            for _, p in pairs(Workspace:GetDescendants()) do
                if p:IsA("ProximityPrompt") then
                    p.HoldDuration = 0
                end
            end
        end
    end)
end)

print("SAB Force Inserter v3.1 Loaded!")

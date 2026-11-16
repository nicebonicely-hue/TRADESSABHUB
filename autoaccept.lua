--[[ SAB AutoTrade v4 — Limpio, sin hooks de red y sin bloqueo de UI ]]
local Players = game:GetService("Players")
local LP      = Players.LocalPlayer
local PG      = LP:WaitForChild("PlayerGui")

local ON = true
local lastFire = 0

local function fireImageButton(btn)
    if not btn or not btn:IsA("ImageButton") or not btn.Visible then return end
    
    -- Verificar que todos los contenedores padres estén visibles
    local p = btn.Parent
    while p and p ~= PG do
        if p:IsA("GuiObject") and not p.Visible then return end
        p = p.Parent
    end

    local now = os.clock()
    if now - lastFire < 0.35 then return end
    lastFire = now

    if getconnections then
        for _, sigName in ipairs({"Activated", "MouseButton1Click"}) do
            for _, conn in ipairs(getconnections(btn[sigName])) do
                pcall(function() conn:Fire() end)
            end
        end
    end
end

-- Bucle principal ligero (solo lee propiedades de UI, cero hooks)
task.spawn(function()
    while task.wait(0.2) do
        if not ON then continue end

        -- 1. Aceptar invitación de trade (DuelsMachinePrompt)
        local duelGui = PG:FindFirstChild("DuelsMachinePrompt")
        if duelGui then
            local prompt = duelGui:FindFirstChild("DuelsMachinePrompt")
            prompt = prompt and prompt:FindFirstChild("Prompt")
            local yesBtn = prompt and prompt:FindFirstChild("Yes")
            if yesBtn then
                fireImageButton(yesBtn)
            end
        end

        -- 2. Darle a READY y luego a ACCEPT en TradeLiveTrade
        local tradeGui = PG:FindFirstChild("TradeLiveTrade")
        if tradeGui then
            local main = tradeGui:FindFirstChild("TradeLiveTrade")
            local other = main and main:FindFirstChild("Other")
            local readyBtn = other and other:FindFirstChild("ReadyButton")
            local txtObj = readyBtn and readyBtn:FindFirstChild("Txt")

            if readyBtn and txtObj and txtObj:IsA("TextLabel") then
                local label = string.upper(txtObj.Text or "")
                -- Solo presionar si dice exactamente READY o ACCEPT (ignora contadores o "WAITING")
                if label == "READY" or label == "ACCEPT" then
                    fireImageButton(readyBtn)
                end
            end
        end
    end
end)

-- Panel mínimo de control
local gui = Instance.new("ScreenGui")
gui.Name = "SAB_AutoTrade_v4"
gui.ResetOnSpawn = false
gui.Parent = PG

local f = Instance.new("Frame")
f.Size = UDim2.fromOffset(145, 52)
f.Position = UDim2.new(0, 12, 0.5, -26)
f.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
f.BorderSizePixel = 0
f.Active = true
f.Parent = gui
Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)

local lbl = Instance.new("TextLabel")
lbl.Size = UDim2.new(1, -12, 0, 18)
lbl.Position = UDim2.new(0, 6, 0, 4)
lbl.BackgroundTransparency = 1
lbl.Font = Enum.Font.GothamBold
lbl.TextSize = 11
lbl.TextColor3 = Color3.fromRGB(120, 235, 150)
lbl.TextXAlignment = Enum.TextXAlignment.Left
lbl.Text = "AUTOTRADE: ON"
lbl.Parent = f

local btn = Instance.new("TextButton")
btn.Size = UDim2.new(1, -12, 0, 20)
btn.Position = UDim2.new(0, 6, 1, -24)
btn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
btn.BorderSizePixel = 0
btn.Font = Enum.Font.GothamBold
btn.TextSize = 11
btn.TextColor3 = Color3.fromRGB(240, 240, 240)
btn.Text = "APAGAR"
btn.Parent = f
Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

btn.MouseButton1Click:Connect(function()
    ON = not ON
    lbl.Text = ON and "AUTOTRADE: ON" or "AUTOTRADE: OFF"
    lbl.TextColor3 = ON and Color3.fromRGB(120, 235, 150) or Color3.fromRGB(235, 120, 120)
    btn.Text = ON and "APAGAR" or "PRENDER"
end)

-- Arrastrar panel
local drag, start, pos0
f.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        drag, start, pos0 = true, i.Position, f.Position
    end
end)
f.InputChanged:Connect(function(i)
    if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
        local d = i.Position - start
        f.Position = UDim2.new(pos0.X.Scale, pos0.X.Offset + d.X, pos0.Y.Scale, pos0.Y.Offset + d.Y)
    end
end)
f.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        drag = false
    end
end)

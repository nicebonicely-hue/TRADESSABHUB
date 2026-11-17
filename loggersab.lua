--[[ SAB Test SendTrade v1 — Basado en AutoTrade v4 (Sin VIM) ]]
local Players = game:GetService("Players")
local LP      = Players.LocalPlayer
local PG      = LP:WaitForChild("PlayerGui")

local TARGET    = "KIMILOSP"
local TARGET_ID = "9555775328"
local ON        = true
local lastFire  = 0

-- Panel visual de diagnóstico
local gui = Instance.new("ScreenGui")
gui.Name = "SAB_TestSend_v1"
gui.ResetOnSpawn = false
gui.Parent = PG

local f = Instance.new("Frame")
f.Size = UDim2.fromOffset(195, 68)
f.Position = UDim2.new(0, 12, 0.5, -34)
f.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
f.BorderSizePixel = 0
f.Active = true
f.Parent = gui
Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)

local lbl = Instance.new("TextLabel")
lbl.Size = UDim2.new(1, -12, 0, 34)
lbl.Position = UDim2.new(0, 6, 0, 4)
lbl.BackgroundTransparency = 1
lbl.Font = Enum.Font.GothamBold
lbl.TextSize = 10
lbl.TextColor3 = Color3.fromRGB(120, 235, 150)
lbl.TextXAlignment = Enum.TextXAlignment.Left
lbl.TextYAlignment = Enum.TextYAlignment.Top
lbl.TextWrapped = true
lbl.Text = "ESTADO: Iniciando..."
lbl.Parent = f

local btn = Instance.new("TextButton")
btn.Size = UDim2.new(1, -12, 0, 20)
btn.Position = UDim2.new(0, 6, 1, -24)
btn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
btn.BorderSizePixel = 0
btn.Font = Enum.Font.GothamBold
btn.TextSize = 11
btn.TextColor3 = Color3.fromRGB(240, 240, 240)
btn.Text = "DETENER"
btn.Parent = f
Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

btn.MouseButton1Click:Connect(function()
    ON = not ON
    btn.Text = ON and "DETENER" or "REANUDAR"
    lbl.TextColor3 = ON and Color3.fromRGB(120, 235, 150) or Color3.fromRGB(235, 120, 120)
end)

local function setStatus(t)
    lbl.Text = "ESTADO: " .. t
end

-- Función exacta del AutoTrade v4 (adaptada a TextButton e ImageButton)
local function fireButton(b)
    if not b or not (b:IsA("ImageButton") or b:IsA("TextButton")) or not b.Visible then return false end
    
    local p = b.Parent
    while p and p ~= PG do
        if p:IsA("GuiObject") and not p.Visible then return false end
        p = p.Parent
    end

    local now = os.clock()
    if now - lastFire < 0.25 then task.wait(0.25) end
    lastFire = os.clock()

    local fired = false
    if getconnections then
        for _, sigName in ipairs({"Activated", "MouseButton1Click", "MouseButton1Down"}) do
            local sig = b[sigName]
            if sig then
                for _, conn in ipairs(getconnections(sig)) do
                    pcall(function() conn:Fire() end)
                    fired = true
                end
            end
        end
    end
    if not fired then
        pcall(function() b:Activate() end)
    end
    return true
end

-- 1. Buscar el botón "Intercambio" / "Trade" en el HUD del jugador
local function clickIntercambioHUD()
    for _, o in ipairs(PG:GetDescendants()) do
        if (o:IsA("ImageButton") or o:IsA("TextButton")) and o.Visible then
            -- Ignorar botones que ya estén dentro de las ventanas de trade
            if not o:FindFirstAncestor("TradePlayerList") and not o:FindFirstAncestor("TradeLiveTrade") then
                local txt = (o:IsA("TextButton") and o.Text or ""):lower()
                local nm  = o.Name:lower()
                for _, d in ipairs(o:GetDescendants()) do
                    if d:IsA("TextLabel") then
                        txt = txt .. " " .. (d.Text or ""):lower()
                    end
                end
                if txt:find("intercamb") or txt:find("trade") or nm:find("trade") or nm:find("intercamb") then
                    if fireButton(o) then
                        return true
                    end
                end
            end
        end
    end
    return false
end

-- 2. Escribir KIMILOSP y disparar los eventos de filtrado del TextBox
local function escribirBusqueda(box, texto)
    pcall(function() box:CaptureFocus() end)
    task.wait(0.1)
    box.Text = texto
    task.wait(0.1)
    if getconnections then
        -- Disparar señales de cambio de texto por si filtra en vivo
        pcall(function()
            for _, conn in ipairs(getconnections(box:GetPropertyChangedSignal("Text"))) do
                conn:Fire()
            end
        end)
        -- Disparar FocusLost (Enter)
        pcall(function()
            for _, conn in ipairs(getconnections(box.FocusLost)) do
                conn:Fire(true)
            end
        end)
    end
    pcall(function() box:ReleaseFocus() end)
end

-- Bucle de prueba
task.spawn(function()
    while task.wait(0.5) do
        if not ON then continue end

        -- Si ya se abrió el trade, avisar y detener prueba
        local liveGui = PG:FindFirstChild("TradeLiveTrade")
        if liveGui and liveGui:FindFirstChild("TradeLiveTrade") and liveGui.TradeLiveTrade.Visible then
            setStatus("¡TRADE ABIERTO CON ÉXITO!")
            continue
        end

        local listGui = PG:FindFirstChild("TradePlayerList")
        local root = listGui and listGui:FindFirstChild("TradePlayerList")

        -- PASO 1: Abrir ventana de Intercambio si no está visible
        if not root or not root.Visible then
            setStatus("1. Buscando botón Intercambio...")
            clickIntercambioHUD()
            task.wait(0.8)
            continue
        end

        -- PASO 2: Asegurar pestaña "Jugadores" (Players)
        local sections = root:FindFirstChild("Sections")
        local playersSec = sections and sections:FindFirstChild("Players")
        if playersSec and not playersSec.Visible then
            setStatus("2. Abriendo pestaña Jugadores...")
            for _, b in ipairs(root:GetDescendants()) do
                if (b:IsA("TextButton") or b:IsA("ImageButton")) and b.Visible then
                    local t = (b:IsA("TextButton") and b.Text or b.Name):lower()
                    if t:find("jugador") or t:find("player") then
                        fireButton(b)
                        break
                    end
                end
            end
            task.wait(0.5)
        end

        -- PASO 3: Escribir en la barra de búsqueda
        local searchFrame = playersSec and playersSec:FindFirstChild("SearchFrame")
        local searchBox = searchFrame and searchFrame:FindFirstChild("SearchBox")
        if searchBox and searchBox:IsA("TextBox") and searchBox.Text ~= TARGET then
            setStatus("3. Escribiendo " .. TARGET .. "...")
            escribirBusqueda(searchBox, TARGET)
            task.wait(0.6)
        end

        -- PASO 4: Buscar a KIMILOSP en toda la lista (por Name o TextLabel interno) y darle a Enviar
        local listScroll = playersSec and playersSec:FindFirstChild("List")
        if listScroll then
            setStatus("4. Buscando fila de " .. TARGET .. "...")
            local encontrado = false

            for _, item in ipairs(listScroll:GetDescendants()) do
                local match = false
                if item.Name:lower():find(TARGET:lower(), 1, true) or item.Name:find(TARGET_ID, 1, true) then
                    match = true
                elseif item:IsA("TextLabel") and item.Text:lower():find(TARGET:lower(), 1, true) then
                    match = true
                end

                if match then
                    -- Subir hasta el contenedor de la fila para encontrar el botón Send / Enviar
                    local row = item
                    while row and row.Parent ~= listScroll do
                        row = row.Parent
                    end
                    if row then
                        local fill = row:FindFirstChild("Fill")
                        local sendBtn = (fill and fill:FindFirstChild("Send")) or row:FindFirstChild("Send", true)
                        
                        -- Respaldo por si el botón se llama distinto (ej. SendButton o dice Enviar)
                        if not sendBtn then
                            for _, b in ipairs(row:GetDescendants()) do
                                if (b:IsA("ImageButton") or b:IsA("TextButton")) and b.Visible then
                                    sendBtn = b
                                    break
                                end
                            end
                        end

                        if sendBtn then
                            setStatus("5. ¡Enviando trade a " .. TARGET .. "!")
                            fireButton(sendBtn)
                            encontrado = true
                            task.wait(2)
                            break
                        end
                    end
                end
            end

            if not encontrado then
                setStatus("4. No aparece " .. TARGET .. " en la lista")
            end
        else
            setStatus("Error: No existe Sections.Players.List")
        end
    end
end)

--[[ 
    SAB | Script Behavior Logger & Anti-Stealer Shield
    Ejecuta esto ANTES de correr cualquier script ofuscado (Luraph, MoonSec, etc.)
    Intercepta y muestra: Remotes, HTTP/Webhooks, Botones GUI, Teletransportes y Prompts.
]]

if _G.ScriptLoggerGUI then
    pcall(function() _G.ScriptLoggerGUI:Destroy() end)
end

local Players = game:GetService("Players")
local lp = Players.LocalPlayer

local CFG = {
    capturing = true,
    blockHttp = true,        -- Bloquea Webhooks de Discord / Robo de datos por defecto
    blockSusRemotes = true,  -- Bloquea Remotes sospechosos (Trade, Gift, Sell, Delete)
    logGui = true,
    logRemotes = true,
    logPrompts = true,
}

local logs = {}
local maxLogs = 250

-- Palabras clave tipicas de scripts "Stealers" que vacian tu inventario
local SUSPICIOUS_WORDS = {
    "trade", "gift", "send", "mail", "post", "transfer", 
    "give", "drop", "delete", "destroy", "sell", "webhook"
}

local function isSuspicious(text)
    local lower = tostring(text or ""):lower()
    for _, word in ipairs(SUSPICIOUS_WORDS) do
        if lower:find(word, 1, true) then
            return true, word
        end
    end
    return false, nil
end

local function serializeArgs(...)
    local args = {...}
    local parts = {}
    for i = 1, select("#", ...) do
        local v = args[i]
        local t = typeof(v)
        if t == "string" then
            parts[#parts + 1] = string.format("%q", v)
        elseif t == "Instance" then
            parts[#parts + 1] = v:GetFullName()
        elseif t == "Vector3" or t == "CFrame" then
            parts[#parts + 1] = t .. "(" .. tostring(v) .. ")"
        elseif t == "table" then
            local sub = {}
            local count = 0
            for k, val in pairs(v) do
                count = count + 1
                if count <= 5 then
                    sub[#sub + 1] = tostring(k) .. "=" .. tostring(val)
                end
            end
            parts[#parts + 1] = "{" .. table.concat(sub, ", ") .. (count > 5 and ", ..." or "") .. "}"
        else
            parts[#parts + 1] = tostring(v)
        end
    end
    return table.concat(parts, ", ")
end

-- =========================================
-- INTERFAZ GRAFICA DEL LOGGER
-- =========================================

local parent = (type(gethui) == "function" and select(2, pcall(gethui))) or game:GetService("CoreGui")
local gui = Instance.new("ScreenGui")
gui.Name = "SAB_ScriptLogger"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = parent
_G.ScriptLoggerGUI = gui

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 420, 0, 340)
main.Position = UDim2.new(0.5, -210, 0, 50)
main.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 8)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 28)
title.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
title.BorderSizePixel = 0
title.Text = "  🕵️ Script Logger & Anti-Stealer (Activo)"
title.TextColor3 = Color3.fromRGB(240, 240, 250)
title.Font = Enum.Font.GothamBold
title.TextSize = 12
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = main
Instance.new("UICorner", title).CornerRadius = UDim.new(0, 8)

local close = Instance.new("TextButton")
close.Size = UDim2.new(0, 28, 0, 28)
close.Position = UDim2.new(1, -30, 0, 0)
close.BackgroundTransparency = 1
close.Text = "X"
close.TextColor3 = Color3.fromRGB(255, 90, 90)
close.Font = Enum.Font.GothamBold
close.TextSize = 14
close.Parent = main

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -16, 1, -76)
scroll.Position = UDim2.new(0, 8, 0, 68)
scroll.BackgroundColor3 = Color3.fromRGB(10, 10, 14)
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 4
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.Parent = main
Instance.new("UICorner", scroll).CornerRadius = UDim.new(0, 6)

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 2)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = scroll

layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 6)
    scroll.CanvasPosition = Vector2.new(0, math.max(0, layout.AbsoluteContentSize.Y - scroll.AbsoluteSize.Y))
end)

local COLORS = {
    REMOTE = Color3.fromRGB(130, 200, 255),
    BLOCKED = Color3.fromRGB(255, 95, 95),
    HTTP = Color3.fromRGB(255, 180, 100),
    GUI = Color3.fromRGB(160, 235, 160),
    PROMPT = Color3.fromRGB(215, 160, 255),
    LOADSTRING = Color3.fromRGB(255, 235, 120),
}

local function pushLog(tag, text)
    if not CFG.capturing or not gui.Parent then return end
    local entry = string.format("[%s] [%s] %s", os.date("%H:%M:%S"), tag, text)
    logs[#logs + 1] = entry
    if #logs > maxLogs then
        table.remove(logs, 1)
        local first = scroll:FindFirstChildOfClass("TextLabel")
        if first then first:Destroy() end
    end

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -8, 0, 18)
    lbl.BackgroundTransparency = 1
    lbl.Text = " " .. entry
    lbl.TextColor3 = COLORS[tag] or Color3.fromRGB(210, 210, 220)
    lbl.Font = Enum.Font.Code
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextTruncate = Enum.TextTruncate.AtEnd
    lbl.LayoutOrder = #logs
    lbl.Parent = scroll

    print(entry)
end

local function mkTopBtn(txt, xScale, widthScale, color, cb)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(widthScale, -6, 0, 26)
    b.Position = UDim2.new(xScale, 4, 0, 34)
    b.BackgroundColor3 = color
    b.BorderSizePixel = 0
    b.Text = txt
    b.TextColor3 = Color3.fromRGB(240, 240, 245)
    b.Font = Enum.Font.GothamSemibold
    b.TextSize = 10
    b.Parent = main
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)
    b.MouseButton1Click:Connect(function() cb(b) end)
    return b
end

mkTopBtn("Escudo Anti-Steal: ON", 0, 0.35, Color3.fromRGB(35, 125, 70), function(b)
    CFG.blockSusRemotes = not CFG.blockSusRemotes
    CFG.blockHttp = CFG.blockSusRemotes
    b.Text = "Escudo Anti-Steal: " .. (CFG.blockSusRemotes and "ON" or "OFF")
    b.BackgroundColor3 = CFG.blockSusRemotes and Color3.fromRGB(35, 125, 70) or Color3.fromRGB(140, 50, 50)
end)

mkTopBtn("Copiar Todo", 0.35, 0.25, Color3.fromRGB(60, 80, 130), function(b)
    if type(setclipboard) == "function" then
        setclipboard(table.concat(logs, "\n"))
        b.Text = "¡Copiado!"
        task.wait(1)
        b.Text = "Copiar Todo"
    else
        pushLog("INFO", "Tu ejecutor no soporta setclipboard, revisa la consola F9")
    end
end)

mkTopBtn("Pausar", 0.60, 0.20, Color3.fromRGB(70, 70, 85), function(b)
    CFG.capturing = not CFG.capturing
    b.Text = CFG.capturing and "Pausar" or "Reanudar"
end)

mkTopBtn("Limpiar", 0.80, 0.20, Color3.fromRGB(90, 50, 50), function()
    table.clear(logs)
    for _, c in ipairs(scroll:GetChildren()) do
        if c:IsA("TextLabel") then c:Destroy() end
    end
end)

close.MouseButton1Click:Connect(function()
    CFG.capturing = false
    gui:Destroy()
end)

-- =========================================
-- GANCHOS DE INTERCEPCION (HOOKS)
-- =========================================

-- 1. Interceptar Remotes (FireServer / InvokeServer) y HttpGet
if hookmetamethod and getnamecallmethod then
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local method = getnamecallmethod()

        if CFG.capturing and not checkcaller or (checkcaller and checkcaller()) then
            if method == "FireServer" or method == "InvokeServer" then
                local fullName = tostring(self:GetFullName())
                local argsTxt = serializeArgs(...)
                local sus, word = isSuspicious(fullName .. " " .. argsTxt)

                if sus and CFG.blockSusRemotes then
                    pushLog("BLOCKED", string.format("Remote bloqueado (%s): %s(%s)", word, fullName, argsTxt))
                    return nil
                end

                pushLog("REMOTE", string.format("%s:%s(%s)", fullName, method, argsTxt))

            elseif method == "HttpGet" or method == "HttpGetAsync" or method == "HttpPost" then
                local url = serializeArgs(...)
                if CFG.blockHttp then
                    pushLog("BLOCKED", "Conexion HTTP bloqueada -> " .. url)
                    return ""
                end
                pushLog("HTTP", method .. " -> " .. url)
            end
        end

        return oldNamecall(self, ...)
    end))
end

-- 2. Interceptar peticiones HTTP directas del ejecutor (Webhooks de Discord, etc.)
local reqFunc = request or http_request or (syn and syn.request) or (http and http.request)
if reqFunc and hookfunction then
    local oldReq
    oldReq = hookfunction(reqFunc, newcclosure(function(options)
        local url = type(options) == "table" and tostring(options.Url) or tostring(options)
        local method = type(options) == "table" and tostring(options.Method or "GET") or "GET"

        if CFG.capturing then
            if CFG.blockHttp then
                pushLog("BLOCKED", string.format("Webhook/HTTP bloqueado [%s]: %s", method, url))
                return { StatusCode = 200, Body = "{}" }
            else
                pushLog("HTTP", string.format("[%s] %s", method, url))
            end
        end
        return oldReq(options)
    end))
end

-- 3. Interceptar ProximityPrompts disparados por el script
if fireproximityprompt and hookfunction then
    local oldPrompt
    oldPrompt = hookfunction(fireproximityprompt, newcclosure(function(prompt, ...)
        if CFG.capturing and prompt then
            pcall(function()
                pushLog("PROMPT", string.format("%s (Action: %s | Object: %s)", prompt:GetFullName(), tostring(prompt.ActionText), tostring(prompt.ObjectText)))
            end)
        end
        return oldPrompt(prompt, ...)
    end))
end

-- 4. Detectar todas las ventanas y botones que el script ofuscado cree
local function watchGuiElement(inst)
    if not CFG.capturing or inst:IsDescendantOf(gui) then return end
    if inst:IsA("ScreenGui") then
        pushLog("GUI", "ScreenGui creada: " .. inst.Name)
    elseif inst:IsA("TextButton") or inst:IsA("TextLabel") then
        task.delay(0.15, function()
            pcall(function()
                if inst.Text and #inst.Text > 1 then
                    pushLog("GUI", string.format("[%s] Texto: %q", inst.ClassName, inst.Text))
                end
            end)
        end)
    end
end

parent.DescendantAdded:Connect(watchGuiElement)
if lp:FindFirstChild("PlayerGui") then
    lp.PlayerGui.DescendantAdded:Connect(watchGuiElement)
end

pushLog("LOADSTRING", "Logger listo. Ejecuta ahora el script de Luraph para espiarlo.")

--[[
    AUTO CODES SAB - INSTANT ATTEMPT / SIN ESPERA ARTIFICIAL
    Compatibilidad objetivo: Delta Executor / Roblox Luau

    FUNCIONES
    - Panel compacto para m贸vil y PC.
    - Detecci贸n de anuncios desde el RemoteEvent de notificaciones localizado
      mediante NotificationController (sin conectarse a todos los remotos).
    - Detector auxiliar de textos nuevos en PlayerGui.
    - Extracci贸n de c贸digos despu茅s de frases como "code is", "redeem",
      "use this code", etc.
    - Auto Listen, Auto Type y Auto Redeem configurables.
    - Canje sin retraso artificial al detectar un c贸digo.
    - Resolvedor de acertijos Gemini opcional; al recibir la respuesta,
      la muestra, la escribe y lanza el canje sin espera artificial.
    - Entrada manual, copiar, limpiar y registro de detecciones.

    IMPORTANTE
    - Define tu clave privada ANTES de ejecutar:
      getgenv().SAB_GEMINI_API_KEY = "AQ.Ab8RN6JCQzky0ioTPoLQiXXr10fSGUwe4r0mYEJQ--9UF0FKcw"
    - No compartas una clave API dentro de scripts p煤blicos.
    - El script solo escribe y pulsa controles de la interfaz del juego.
      No falsifica respuestas del servidor ni invoca remotos de canje.
    - No existe garant铆a de respuesta Gemini en 1 ms: requiere una petici贸n
      de red y el tiempo depende de conexi贸n, API y latencia.
    - Las respuestas ya guardadas en cach茅 s铆 pueden mostrarse casi al instante.
    - "Enviado" significa que se activ贸 el control de la interfaz; no garantiza
      que el servidor haya aceptado el c贸digo ni verifica por s铆 solo el acertijo.
    - La estructura de la interfaz y los eventos del juego pueden cambiar.
]]

--==============================================================
-- 1. SERVICIOS Y COMPATIBILIDAD
--==============================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Env = (getgenv and getgenv()) or _G
local API_KEY = tostring(Env.SAB_GEMINI_API_KEY or "")
local HttpRequest = request or http_request or (syn and syn.request) or (http and http.request)
local GetConnections = getconnections or (debug and debug.getconnections)
local SetClipboard = setclipboard or toclipboard or (syn and syn.write_clipboard)

local function safeCall(fn, ...)
    if type(fn) ~= "function" then return false end
    return pcall(fn, ...)
end

local function trim(value)
    return tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function stripRichText(value)
    return tostring(value or ""):gsub("<[^>]->", "")
end

local function isTextObject(obj)
    return obj and (obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox"))
end

--==============================================================
-- 2. CONFIGURACI脫N
--==============================================================
local Config = {
    AutoListen = true,
    AutoType = true,
    AutoRedeem = true,
    AutoRiddleAI = true,
    IgnoreSystem = true,
    ListenKey = Enum.KeyCode.F,
    RedeemKey = Enum.KeyCode.G,
    MaxFeed = 7,
}

local State = {
    Listening = false,
    Busy = false,
    LastCode = "",
    LastMessage = "",
    LastMessageAt = 0,
    RemoteConnected = false,
    GuiObserverCount = 0,
    Connections = {},
    RiddleCache = {},
    FeedCount = 0,
    Rebinding = nil,
}

--==============================================================
-- 3. INTERFAZ
--==============================================================
local old = PlayerGui:FindFirstChild("SABAutoCodesRebuilt")
if old then old:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SABAutoCodesRebuilt"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

local Theme = {
    Background = Color3.fromRGB(13, 15, 21),
    Panel = Color3.fromRGB(22, 25, 34),
    Input = Color3.fromRGB(30, 34, 45),
    Line = Color3.fromRGB(54, 61, 76),
    Text = Color3.fromRGB(240, 243, 250),
    Muted = Color3.fromRGB(151, 160, 178),
    Accent = Color3.fromRGB(95, 145, 255),
    Green = Color3.fromRGB(72, 202, 138),
    Red = Color3.fromRGB(240, 91, 102),
    Yellow = Color3.fromRGB(245, 190, 82),
}

local function make(className, props, parent)
    local obj = Instance.new(className)
    for key, value in pairs(props or {}) do
        obj[key] = value
    end
    obj.Parent = parent
    return obj
end

local function corner(obj, radius)
    make("UICorner", {CornerRadius = UDim.new(0, radius or 8)}, obj)
end

local function stroke(obj, color, transparency)
    make("UIStroke", {Color = color or Theme.Line, Thickness = 1, Transparency = transparency or 0.15}, obj)
end

local Main = make("Frame", {
    Name = "Main",
    Size = UDim2.fromOffset(300, 354),
    Position = UDim2.new(0.5, -150, 0.5, -177),
    BackgroundColor3 = Theme.Background,
    BorderSizePixel = 0,
}, ScreenGui)
corner(Main, 12)
stroke(Main, Theme.Line, 0.05)

local Scale = make("UIScale", {Scale = 1}, Main)
local function updateScale()
    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(800, 600)
    if UserInputService.TouchEnabled then
        Scale.Scale = math.clamp(math.min(viewport.X / 390, viewport.Y / 470), 0.72, 0.96)
    else
        Scale.Scale = 1
    end
end
updateScale()
if workspace.CurrentCamera then
    table.insert(State.Connections, workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale))
end

local Header = make("Frame", {
    Size = UDim2.new(1, 0, 0, 40),
    BackgroundColor3 = Theme.Panel,
    BorderSizePixel = 0,
}, Main)
corner(Header, 12)
make("Frame", {Size = UDim2.new(1, 0, 0, 12), Position = UDim2.new(0, 0, 1, -12), BackgroundColor3 = Theme.Panel, BorderSizePixel = 0}, Header)

local Title = make("TextLabel", {
    Size = UDim2.new(1, -82, 1, 0), Position = UDim2.fromOffset(12, 0),
    BackgroundTransparency = 1, Text = "SAB  /  AUTO CODES", TextColor3 = Theme.Text,
    Font = Enum.Font.GothamBold, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
}, Header)

local Minimize = make("TextButton", {
    Size = UDim2.fromOffset(28, 26), Position = UDim2.new(1, -64, 0, 7),
    BackgroundColor3 = Theme.Input, Text = "鈥�", TextColor3 = Theme.Text,
    Font = Enum.Font.GothamBold, TextSize = 15, BorderSizePixel = 0,
}, Header)
corner(Minimize, 6)
local Close = make("TextButton", {
    Size = UDim2.fromOffset(28, 26), Position = UDim2.new(1, -32, 0, 7),
    BackgroundColor3 = Color3.fromRGB(75, 37, 45), Text = "脳", TextColor3 = Theme.Text,
    Font = Enum.Font.GothamBold, TextSize = 17, BorderSizePixel = 0,
}, Header)
corner(Close, 6)

local Body = make("Frame", {
    Size = UDim2.new(1, -20, 1, -52), Position = UDim2.fromOffset(10, 46),
    BackgroundTransparency = 1,
}, Main)

local Status = make("TextLabel", {
    Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1,
    Text = "Iniciando detector...", TextColor3 = Theme.Yellow,
    Font = Enum.Font.Gotham, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left,
}, Body)

local CodeBox = make("TextBox", {
    Size = UDim2.new(1, 0, 0, 36), Position = UDim2.fromOffset(0, 27),
    BackgroundColor3 = Theme.Input, BorderSizePixel = 0,
    Text = "", PlaceholderText = "C贸digo o respuesta...", PlaceholderColor3 = Theme.Muted,
    TextColor3 = Theme.Text, Font = Enum.Font.GothamSemibold, TextSize = 13,
    ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left,
}, Body)
corner(CodeBox, 7)
make("UIPadding", {PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 8)}, CodeBox)

local function createButton(text, x, y, width, color)
    local button = make("TextButton", {
        Size = UDim2.new(width, -4, 0, 31), Position = UDim2.new(x, x == 0 and 0 or 4, 0, y),
        BackgroundColor3 = color or Theme.Input, BorderSizePixel = 0,
        Text = text, TextColor3 = Theme.Text, Font = Enum.Font.GothamBold, TextSize = 11,
        AutoButtonColor = true,
    }, Body)
    corner(button, 7)
    return button
end

local ListenButton = createButton("LISTEN: OFF", 0, 72, 0.5, Theme.Input)
local RedeemButton = createButton("REDEEM", 0.5, 72, 0.5, Theme.Accent)
local TypeButton = createButton("AUTO TYPE: ON", 0, 109, 0.5, Theme.Input)
local AutoRedeemButton = createButton("AUTO REDEEM: ON", 0.5, 109, 0.5, Theme.Input)
local AIButton = createButton("GEMINI AI: ON", 0, 146, 0.5, Theme.Input)
local ClearButton = createButton("CLEAR", 0.5, 146, 0.5, Theme.Input)

local FeedTitle = make("TextLabel", {
    Size = UDim2.new(1, 0, 0, 20), Position = UDim2.fromOffset(0, 184),
    BackgroundTransparency = 1, Text = "DETECCIONES RECIENTES", TextColor3 = Theme.Muted,
    Font = Enum.Font.GothamBold, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left,
}, Body)
local Feed = make("Frame", {
    Size = UDim2.new(1, 0, 0, 68), Position = UDim2.fromOffset(0, 207),
    BackgroundColor3 = Theme.Panel, BorderSizePixel = 0,
}, Body)
corner(Feed, 7)
local FeedText = make("TextLabel", {
    Size = UDim2.new(1, -14, 1, -10), Position = UDim2.fromOffset(7, 5),
    BackgroundTransparency = 1, Text = "Esperando anuncios...", TextColor3 = Theme.Muted,
    Font = Enum.Font.Gotham, TextSize = 10, TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
}, Feed)

local Bottom = make("TextLabel", {
    Size = UDim2.new(1, 0, 0, 28), Position = UDim2.fromOffset(0, 282),
    BackgroundTransparency = 1, Text = "F: escuchar  鈥�  G: canjear  鈥�  arrastra para mover",
    TextColor3 = Theme.Muted, Font = Enum.Font.Gotham, TextSize = 9,
    TextWrapped = true,
}, Body)

local function setStatus(message, kind)
    Status.Text = tostring(message)
    local colors = {ok = Theme.Green, error = Theme.Red, wait = Theme.Yellow, info = Theme.Muted, busy = Theme.Accent}
    Status.TextColor3 = colors[kind or "info"] or Theme.Muted
end

local function addFeed(message, result)
    State.FeedCount += 1
    local line = "鈥� " .. trim(message):sub(1, 85)
    if result and result ~= "" then line ..= "  鈫�  " .. trim(result):sub(1, 35) end
    local lines = {}
    for oldLine in FeedText.Text:gmatch("[^\n]+") do
        if oldLine ~= "Esperando anuncios..." then lines[#lines + 1] = oldLine end
    end
    table.insert(lines, 1, line)
    while #lines > Config.MaxFeed do table.remove(lines) end
    FeedText.Text = table.concat(lines, "\n")
end

-- Arrastrar panel desde la barra superior.
do
    local dragging, dragInput, dragStart, startPos
    Header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = Main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    Header.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input == dragInput then
            local delta = input.Position - dragStart
            Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

local minimized = false
Minimize.MouseButton1Click:Connect(function()
    minimized = not minimized
    Body.Visible = not minimized
    Main.Size = minimized and UDim2.fromOffset(300, 40) or UDim2.fromOffset(300, 354)
    Minimize.Text = minimized and "+" or "鈥�"
end)
Close.MouseButton1Click:Connect(function()
    for _, connection in ipairs(State.Connections) do pcall(function() connection:Disconnect() end) end
    ScreenGui:Destroy()
end)

--==============================================================
-- 4. INTERACCI脫N CON LA VENTANA DE C脫DIGOS DEL JUEGO
--==============================================================
local function getCodesRoot()
    return PlayerGui:FindFirstChild("Codes")
end

local function findCodeBox()
    local root = getCodesRoot()
    if not root then return nil end
    local codes = root:FindFirstChild("Codes") or root
    local main = codes:FindFirstChild("Main")
    local direct = main and main:FindFirstChild("TextBox")
    if direct and direct:IsA("TextBox") then return direct end
    for _, obj in ipairs(root:GetDescendants()) do
        if obj:IsA("TextBox") then return obj end
    end
    return nil
end

local function findSubmitButton()
    local root = getCodesRoot()
    if not root then return nil end
    local codes = root:FindFirstChild("Codes") or root
    local main = codes:FindFirstChild("Main")
    local direct = main and main:FindFirstChild("Confirm")
    if direct and (direct:IsA("TextButton") or direct:IsA("ImageButton")) then return direct end
    for _, obj in ipairs(root:GetDescendants()) do
        if obj:IsA("TextButton") or obj:IsA("ImageButton") then
            local name = obj.Name:lower()
            if name:find("confirm", 1, true) or name:find("submit", 1, true)
                or name:find("redeem", 1, true) or name:find("enter", 1, true) then
                return obj
            end
        end
    end
    return nil
end

local function fireGuiSignal(signal)
    if not GetConnections then return false end
    local ok, connections = pcall(GetConnections, signal)
    if not ok or type(connections) ~= "table" then return false end
    for _, connection in ipairs(connections) do
        if connection.Enabled ~= false then
            local fn
            pcall(function() fn = connection.Function end)
            if type(fn) == "function" then
                local fired = pcall(task.spawn, fn)
                if fired then return true end
            elseif type(connection.Fire) == "function" then
                if pcall(function() connection:Fire() end) then return true end
            end
        end
    end
    return false
end

local function submitCode(code)
    code = trim(code)
    if code == "" then return false, "C贸digo vac铆o" end
    local box = findCodeBox()
    if not box then return false, "Abre la ventana Codes del juego" end

    local wrote = pcall(function() box.Text = code end)
    if not wrote then return false, "No se pudo escribir en el campo" end

    local button = findSubmitButton()
    if button and fireGuiSignal(button.Activated) then
        return true, "Control de canje activado"
    end
    if button and fireGuiSignal(button.MouseButton1Click) then
        return true, "Control de canje activado"
    end
    if fireGuiSignal(box.FocusLost) then
        return true, "Campo enviado mediante FocusLost"
    end

    -- Fallback compatible: deja el c贸digo escrito para que el usuario pulse el bot贸n.
    return false, "C贸digo escrito; pulsa Confirm manualmente"
end

local function redeem(code, source)
    local clean = trim(code)
    if clean == "" then setStatus("No hay c贸digo para canjear", "error") return false end
    if clean == State.LastCode and os.clock() - (State.LastCodeAt or 0) < 2 then
        setStatus("C贸digo repetido ignorado", "info")
        return false
    end
    State.LastCode = clean
    State.LastCodeAt = os.clock()
    CodeBox.Text = clean
    setStatus("Procesando: " .. clean, "busy")
    local ok, message = submitCode(clean)
    if ok then
        setStatus((source and source .. ": " or "") .. "Enviado a la interfaz", "ok")
    else
        setStatus(message, "wait")
    end
    return ok
end

RedeemButton.MouseButton1Click:Connect(function()
    redeem(CodeBox.Text, "Manual")
end)
ClearButton.MouseButton1Click:Connect(function()
    CodeBox.Text = ""
    State.LastCode = ""
    setStatus("Campo limpiado", "info")
end)

--==============================================================
-- 5. DETECCI脫N Y EXTRACCI脫N DE C脫DIGOS
--==============================================================
local function tokenize(text)
    local tokens = {}
    for token in tostring(text or ""):gmatch("[%w_%-]+") do
        tokens[#tokens + 1] = token
    end
    return tokens
end

local function looksLikeCode(token)
    if not token or #token < 4 or #token > 40 then return false end
    if not token:match("%a") then return false end
    if token:match("^%d+$") then return false end
    return token:match("^[%w_%-]+$") ~= nil
end

local function extractCode(message)
    local text = stripRichText(message)
    local lower = text:lower()
    -- Lua patterns no admiten grupos opcionales estilo regex (?:...).
    -- Por eso cada variante se declara por separado.
    local patterns = {
        "code%s+is%s+([%w_%-]+)",
        "code%s*:%s*([%w_%-]+)",
        "code%s*%-%s*([%w_%-]+)",
        "redeem%s+([%w_%-]+)",
        "use%s+the%s+code%s+([%w_%-]+)",
        "use%s+code%s+([%w_%-]+)",
        "enter%s+the%s+code%s+([%w_%-]+)",
        "enter%s+code%s+([%w_%-]+)",
        "claim%s+with%s+([%w_%-]+)",
        "claim%s+([%w_%-]+)",
    }
    for _, pattern in ipairs(patterns) do
        local candidate = lower:match(pattern)
        if candidate and looksLikeCode(candidate) then
            for original in text:gmatch("[%w_%-]+") do
                if original:lower() == candidate then return original end
            end
            return candidate
        end
    end

    local tokens = tokenize(text)
    local candidates = {}
    for _, token in ipairs(tokens) do
        if looksLikeCode(token) then candidates[#candidates + 1] = token end
    end
    if #candidates == 1 and (#tokens <= 5 or lower:find("sammy", 1, true)) then
        return candidates[1]
    end
    return nil
end

local function isRiddle(message)
    local lower = tostring(message or ""):lower()
    if lower:find("?", 1, true) then return true end
    local hints = {"what", "who", "where", "when", "which", "guess", "riddle", "how many", "how much", "solve", "plus", "minus"}
    for _, word in ipairs(hints) do
        if lower:find(word, 1, true) then return true end
    end
    return false
end

local function isSystemMessage(message)
    if not Config.IgnoreSystem then return false end
    local lower = tostring(message or ""):lower()
    local ignored = {
        "coins shop", "robux shop", "trade plaza", "spin wheel",
        "your base is full", "your base is already locked", "trade has been completed",
        "someone is stealing", "event has started", "brainrot trader",
    }
    for _, phrase in ipairs(ignored) do
        if lower:find(phrase, 1, true) then return true end
    end
    return false
end

--==============================================================
-- 6. GEMINI AI PARA ACERTIJOS
--==============================================================
local function solveRiddle(question, callback)
      question = trim(question)
    if question == "" then callback(nil, "Pregunta vac铆a") return end
    if State.RiddleCache[question] then callback(State.RiddleCache[question], nil, true) return end
    if API_KEY == "" then callback(nil, "Configura SAB_GEMINI_API_KEY") return end
    if not HttpRequest then callback(nil, "Este executor no tiene request HTTP") return end

    task.spawn(function()
        local endpoint = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=" .. API_KEY
        local body = HttpService:JSONEncode({
            contents = {{parts = {{text = "Resuelve el acertijo y revisa internamente que tu respuesta encaje con todas las pistas antes de responder. Devuelve 煤nicamente la respuesta final exacta, sin explicaci贸n, etiquetas ni comillas. Conserva los espacios entre palabras y la ortograf铆a normal. Si no puedes determinarla con suficiente confianza, responde UNKNOWN. Acertijo: " .. question}}}},
            generationConfig = {temperature = 0, maxOutputTokens = 40},
        })
        local ok, response = pcall(function()
            return HttpRequest({
                Url = endpoint,
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = body,
            })
        end)
        if not ok or not response or type(response.Body) ~= "string" then
            callback(nil, "No se pudo conectar con Gemini")
            return
        end
        if response.StatusCode and (response.StatusCode < 200 or response.StatusCode >= 300) then
            callback(nil, "Gemini HTTP " .. tostring(response.StatusCode) .. ": " .. tostring(response.Body):sub(1, 180))
            return
        end
        local parsed, data = pcall(function() return HttpService:JSONDecode(response.Body) end)
        if not parsed then callback(nil, "Respuesta JSON inv谩lida de Gemini") return end
        local answer = data.candidates and data.candidates[1]
            and data.candidates[1].content and data.candidates[1].content.parts
            and data.candidates[1].content.parts[1] and data.candidates[1].content.parts[1].text
        answer = trim(answer)
        answer = answer:gsub("^[\"'`]+", ""):gsub("[\"'`]+$", "")
        answer = answer:gsub("^[*%s]+", ""):gsub("[*%s]+$", "")
        if answer == "" or answer:upper() == "UNKNOWN" then
            callback(nil, "Gemini no encontr贸 una respuesta fiable")
            return
        end
        State.RiddleCache[question] = answer
        callback(answer, nil, false)
    end)
end

--==============================================================
-- 7. PROCESADOR CENTRAL DE ANUNCIOS
--==============================================================
local function handleAnnouncement(rawMessage)
    local message = trim(stripRichText(rawMessage))
    if message == "" then return end
    if #message > 500 then return end

    local now = os.clock()
    if message == State.LastMessage and now - State.LastMessageAt < 0.6 then return end
    State.LastMessage = message
    State.LastMessageAt = now

    if isSystemMessage(message) then return end
    addFeed(message)

    if isRiddle(message) and Config.AutoRiddleAI then
        setStatus("Acertijo detectado; consultando Gemini...", "busy")
        solveRiddle(message, function(answer, err, fromCache)
            if answer then
                CodeBox.Text = answer
                addFeed("Respuesta IA", answer)
                setStatus((fromCache and "Respuesta en cach茅: " or "Gemini respondi贸: ") .. answer, "ok")
                if Config.AutoType then
                    local box = findCodeBox()
                    if box then pcall(function() box.Text = answer end) end
                end
                if Config.AutoRedeem then redeem(answer, "IA") end
            else
                setStatus("IA: " .. tostring(err), "error")
            end
        end)
        return
    end

    local code = extractCode(message)
    if not code then
        if State.Listening then setStatus("Escuchando; no se detect贸 un c贸digo claro", "wait") end
        return
    end

    if Config.AutoListen and not State.Listening then
        State.Listening = true
        ListenButton.Text = "LISTEN: ON"
        ListenButton.BackgroundColor3 = Theme.Green
    end

    if State.Listening or Config.AutoListen then
        CodeBox.Text = code
        if Config.AutoType then
            local box = findCodeBox()
            if box then pcall(function() box.Text = code end) end
        end
        addFeed("C贸digo detectado", code)
        if Config.AutoRedeem then
            -- Sin espera artificial: inicia el canje en cuanto se detecta el c贸digo.
            task.spawn(function() redeem(code, "AUTO") end)
        else
            setStatus("C贸digo detectado: " .. code, "ok")
        end
    end
end

--==============================================================
-- 8. DETECTOR DE EVENTO DE NOTIFICACI脫N ESPEC脥FICO
--==============================================================
local function findNotificationRemote()
    -- Solo inspecciona el controlador de notificaciones conocido.
    -- No se conecta indiscriminadamente a todos los RemoteEvents.
    local controllers = ReplicatedStorage:FindFirstChild("Controllers")
    if not controllers then return nil end
    local module = controllers:FindFirstChild("NotificationController", true)
    if not module or not module:IsA("ModuleScript") then return nil end
    if not (debug and debug.getupvalues) and not getupvalues then return nil end

    local getUps = (debug and debug.getupvalues) or getupvalues
    local ok, controller = pcall(require, module)
    if not ok or type(controller) ~= "table" or type(controller.Start) ~= "function" then return nil end
    local got, upvalues = pcall(getUps, controller.Start)
    if not got or type(upvalues) ~= "table" then return nil end

    for _, value in pairs(upvalues) do
        if typeof(value) == "Instance" and (value:IsA("RemoteEvent") or value:IsA("UnreliableRemoteEvent")) then
            return value
        end
    end
    return nil
end

local function onNotification(...)
    local args = table.pack(...)
    -- En este juego el texto del anuncio llega en el primer argumento.
    -- No se procesan los metadatos (posici贸n, sonido, etc.) como mensajes.
    if type(args[1]) ~= "string" then return end
    local value = stripRichText(args[1])
    if #value >= 4 and #value <= 500 then
        handleAnnouncement(value)
    end
end

local remote = findNotificationRemote()
if remote then
    local ok, connection = pcall(function()
        return remote.OnClientEvent:Connect(onNotification)
    end)
    if ok and connection then
        State.RemoteConnected = true
        table.insert(State.Connections, connection)
    end
end

--==============================================================
-- 9. DETECTOR AUXILIAR DE TEXTO EN LA INTERFAZ
--==============================================================
local function watchTextObject(obj)
    if not isTextObject(obj) then return end
    local name = obj.Name:lower()
    if name:find("input", 1, true) or name:find("textbox", 1, true) then return end
    local lastText = obj.Text
    local connection = obj:GetPropertyChangedSignal("Text"):Connect(function()
        local current = obj.Text
        if current ~= lastText then
            lastText = current
            local clean = stripRichText(current)
            if #clean >= 5 and #clean <= 500 then handleAnnouncement(clean) end
        end
    end)
    table.insert(State.Connections, connection)
    State.GuiObserverCount += 1
end

for _, obj in ipairs(PlayerGui:GetDescendants()) do
    watchTextObject(obj)
end

table.insert(State.Connections, PlayerGui.DescendantAdded:Connect(function(obj)
    task.defer(watchTextObject, obj)
end))

--==============================================================
-- 10. CONTROLES Y ATAJOS
--==============================================================
local function refreshButtons()
    ListenButton.Text = State.Listening and "LISTEN: ON" or "LISTEN: OFF"
    ListenButton.BackgroundColor3 = State.Listening and Theme.Green or Theme.Input
    TypeButton.Text = "AUTO TYPE: " .. (Config.AutoType and "ON" or "OFF")
    TypeButton.BackgroundColor3 = Config.AutoType and Theme.Panel or Theme.Input
    AutoRedeemButton.Text = "AUTO REDEEM: " .. (Config.AutoRedeem and "ON" or "OFF")
    AutoRedeemButton.BackgroundColor3 = Config.AutoRedeem and Theme.Panel or Theme.Input
    AIButton.Text = "GEMINI AI: " .. (Config.AutoRiddleAI and "ON" or "OFF")
    AIButton.BackgroundColor3 = Config.AutoRiddleAI and Theme.Panel or Theme.Input
end

ListenButton.MouseButton1Click:Connect(function()
    State.Listening = not State.Listening
    refreshButtons()
    setStatus(State.Listening and "Escuchando anuncios..." or "Escucha pausada", State.Listening and "wait" or "info")
end)
TypeButton.MouseButton1Click:Connect(function()
    Config.AutoType = not Config.AutoType
    refreshButtons()
end)
AutoRedeemButton.MouseButton1Click:Connect(function()
    Config.AutoRedeem = not Config.AutoRedeem
    refreshButtons()
end)
AIButton.MouseButton1Click:Connect(function()
    Config.AutoRiddleAI = not Config.AutoRiddleAI
    refreshButtons()
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if State.Rebinding then
        if input.UserInputType == Enum.UserInputType.Keyboard then
            if input.KeyCode ~= Enum.KeyCode.Escape then
                Config[State.Rebinding] = input.KeyCode
            end
            State.Rebinding = nil
        end
        return
    end
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.Keyboard then
        if input.KeyCode == Config.ListenKey then
            State.Listening = not State.Listening
            refreshButtons()
            setStatus(State.Listening and "Escuchando anuncios..." or "Escucha pausada", State.Listening and "wait" or "info")
        elseif input.KeyCode == Config.RedeemKey then
            redeem(CodeBox.Text, "Manual")
        end
    end
end)

-- Cambiar opciones al pulsar el texto inferior con el bot贸n derecho no es
-- necesario: las teclas por defecto son F (escuchar) y G (canjear).

--==============================================================
-- 11. ESTADO INICIAL
--==============================================================
refreshButtons()
if State.RemoteConnected then
    setStatus("Detector conectado al evento de anuncios", "ok")
elseif State.GuiObserverCount > 0 then
    setStatus("Detector visual activo; remoto no localizado", "wait")
else
    setStatus("Abre el juego y la ventana Codes", "wait")
end

if Config.AutoListen then
    State.Listening = true
    refreshButtons()
end

print("[SAB Auto Codes] Reconstruido correctamente. Remote:", State.RemoteConnected, "GUI observers:", State.GuiObserverCount)

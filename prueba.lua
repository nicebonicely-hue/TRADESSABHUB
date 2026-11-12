--[[
    AUTOCODESAB ULTIMATE (TRACED HUB) - OPTIMIZED FOR DELTA EXECUTOR
    Features:
    - Auto Listen & Dynamic Word Length Detection (AUTO / 1 / 2 / 3 / 4)
    - Instant Auto Redeem & Auto Type
    - Gemini AI Auto Riddle Solver (Integrated API Key)
    - Anti-Ragdoll, Auto Buy & Event Blocker
    - Mobile Touch Scaling (WinScale)
]]

local cloneref_ = cloneref or function(obj) return obj end
local Players = cloneref_(game:GetService("Players"))
local ReplicatedStorage = cloneref_(game:GetService("ReplicatedStorage"))
local UserInputService = cloneref_(game:GetService("UserInputService"))
local TweenService = cloneref_(game:GetService("TweenService"))
local RunService = cloneref_(game:GetService("RunService"))
local HttpService = cloneref_(game:GetService("HttpService"))

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Net = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Net")

local getupvalues_ = debug and debug.getupvalues or getupvalues
local getconnections_ = getconnections or (debug and debug.getconnections)
local writeClipboard = setclipboard or toclipboard or (syn and syn.write_clipboard)
local httpRequest = request or http_request or (syn and syn.request) or (http and http.request)

-- Gemini AI Configuration
local GEMINI_API_KEY = "AQ.Ab8RN6JCQzky0ioTPoLQiXXr10fSGUwe4r0mYEJQ--9UF0FKcw"

-- Mobile / Touch Detection & Scaling
local KeyboardEnabled = UserInputService.KeyboardEnabled
local IsMobile = UserInputService.TouchEnabled and not KeyboardEnabled

-- Persistent Settings
local ConfigCache = {}
if readfile and isfile then
    local ok, data = pcall(function()
        if isfile("redeemer_settings.txt") then
            return readfile("redeemer_settings.txt")
        end
    end)
    if ok and type(data) == "string" then
        for line in data:gmatch("[^\n]+") do
            local k, v = line:match("^(%w+)=(.*)$")
            if k then ConfigCache[k] = v end
        end
    end
end

_G.__RdmCfgBool = function(k, def)
    local v = ConfigCache[k]
    if v == "1" then return true end
    if v == "0" then return false end
    return def
end

_G.__RdmCfgStr = function(k, def)
    local v = ConfigCache[k]
    return type(v) == "string" and v ~= "" and v or def
end

_G.__RdmCfgSet = function(k, v)
    ConfigCache[k] = type(v) == "boolean" and (v and "1" or "0") or tostring(v)
    if not writefile then return end
    local lines = {}
    for key, val in pairs(ConfigCache) do
        lines[#lines + 1] = key .. "=" .. tostring(val)
    end
    table.sort(lines)
    pcall(writefile, "redeemer_settings.txt", table.concat(lines, "\n"))
end

local function GetMobileScale()
    if not IsMobile then return 1 end
    local cam = workspace.CurrentCamera
    local vy = cam and cam.ViewportSize.Y or 600
    local uiSize = _G.__RdmCfgStr("uiSize", "MEDIUM")
    local mult = uiSize == "BIG" and 1.15 or uiSize == "SMALL" and 0.8 or 1
    return math.clamp(vy * 0.88 / 548, 0.5, 1.3) * mult
end

local CurrentScale = GetMobileScale()

-- State Variables
local Config = {
    listenKey = Enum.KeyCode.F,
    maxFeed = 36,
    positions = {
        Top = true, Bottom = true, Center = true, Middle = true,
        Left = true, Right = true, TopRight = true, TopLeft = true,
        BottomRight = true, BottomLeft = true,
    }
}

local SpeedTable = { MAX = 0.22 }
local SpamDelay = SpeedTable[_G.__RdmCfgStr("speed", "MAX")] or SpeedTable.MAX
local WordSpamMode = _G.__RdmCfgBool("wordMode", false)
local IsListening = false
local AutoRedeem = _G.__RdmCfgBool("autoRedeem", true)
local AutoType = _G.__RdmCfgBool("autoType", true)
local ManualMode = _G.__RdmCfgBool("manual", false)
local AutoRiddleAI = _G.__RdmCfgBool("autoRiddleAI", true)
local IsSpamming = false
local SpamCount = 0
local WordModeSetting = _G.__RdmCfgStr("wordCount", "AUTO") -- "AUTO", "1", "2", "3", "4"
local TargetWordCount = tonumber(WordModeSetting) or 0
local ListenKey = Config.listenKey
local RedeemKey = Enum.KeyCode.G
local RebindingTarget = nil
local CapturedTokens = {}
local LastTypedCode = nil
local NotifyRemote = nil
local FallbackListening = false
local AutoListen = _G.__RdmCfgBool("autoListen", true)
local SpamOnListen = _G.__RdmCfgBool("spamOnListen", true)
local ShowKeybinds = _G.__RdmCfgBool("showKeybinds", KeyboardEnabled)
local IgnoreSystem = _G.__RdmCfgBool("ignoreSystem", true)
_G.__RdmDuo = _G.__RdmCfgBool("duo", false)

-- Utility Functions
local function StripRichText(str)
    if type(str) ~= "string" then return tostring(str) end
    return (str:gsub("<[^>]->", ""))
end

local function Trim(str)
    return (str or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function CopyToClipboard(str)
    if not writeClipboard then return false end
    return (pcall(writeClipboard, str))
end

local function Tokenize(str)
    local tokens = {}
    for w in str:gmatch("[%w_]+") do
        tokens[#tokens + 1] = w
    end
    return tokens
end

local function ExtractBestCandidate(str)
    local best = nil
    for w in str:gmatch("[%w_]+") do
        if #w >= 4 and w:match("%a") and (w:match("%u") or w:match("%d")) then
            best = w
        end
    end
    if best then return best end
    for w in str:gmatch("[%w_]+") do
        if #w >= 4 then return w end
    end
end

-- Drop Classifier (Code vs Riddle)
_G.__SabClassifyDrop = function(rawText)
    local str = tostring(rawText or "")
    local lower = str:lower()
    local words = {}
    for w in str:gmatch("[%w']+") do
        words[#words + 1] = w
    end
    local count = #words
    if count == 0 then return nil end

    local padded = " " .. lower:gsub("[^%w]", " ") .. " "
    if lower:find("?", 1, true) then return "riddle" end

    for _, kw in ipairs({
        " what ", " how ", " which ", " whose ", " when ", " who ",
        " whats ", " where ", " why ", " guess ", " riddle ", " answer ", " my "
    }) do
        if padded:find(kw, 1, true) then return "riddle" end
    end

    if count >= 2 and (padded:find(" plus ", 1, true) or lower:find("+", 1, true)) then
        return "riddle"
    end
    if count >= 4 and padded:find(" and ", 1, true) then
        return "riddle"
    end
    if lower:find("code", 1, true) then return "code" end
    for _, kw in ipairs({ " redeem ", " type ", " enter ", " claim " }) do
        if padded:find(kw, 1, true) then return "code" end
    end
    if count >= 7 then return "riddle" end
    if count == 1 then return "code" end
    if count <= 4 then
        local valid = 0
        for _, w in ipairs(words) do
            if #w >= 3 and ((w == w:upper() and w:match("%a")) or w:match("%d")) then
                valid += 1
            end
        end
        if valid == count then return "code" end
    end
    return nil
end

-- Trigger Phrase Parser
local TriggerMatcher = {
    leads = {
        "use", "using", "redeem", "type", "enter", "claim", "with",
        "grab", "got", "here is", "heres", "here's", "there is", "theres", "there's"
    },
    articles = { "", "the%s+", "a%s+", "an%s+", "this%s+", "your%s+", "new%s+" },
    patterns = {
        "code%s+is", "codes?%s+are", "code%s+for", "code%s+to%s+use",
        "code%s*[:%-]", "new%s+code", "free%s+code", "secret%s+code",
        "working%s+code", "another%s+code"
    },
    names = { "sammy" }
}
for _, lead in ipairs(TriggerMatcher.leads) do
    local l = lead:gsub("%s+", "%%s+")
    for _, art in ipairs(TriggerMatcher.articles) do
        TriggerMatcher.patterns[#TriggerMatcher.patterns + 1] = l .. "%s+" .. art .. "code"
    end
end

local function FindCodeSubstring(str)
    for pos, tok in str:gmatch("()([%w_]+)") do
        if #tok >= 4 and tok:match("%a") and (tok:match("%u") or tok:match("%d")) then
            return str:sub(pos)
        end
    end
end

local function ExtractTriggerPayload(str)
    local lower = str:lower()
    local lastEnd = nil
    local fromName = nil

    local function scan(pat, plain, isName)
        local idx = 1
        while true do
            local ok, s, e = pcall(string.find, lower, pat, idx, plain)
            if ok and s then
                if not lastEnd or e > lastEnd then
                    lastEnd = e
                    fromName = isName
                end
                idx = e + 1
            else
                break
            end
        end
    end

    for _, pat in ipairs(TriggerMatcher.patterns) do
        scan(pat, false, false)
    end
    if lower:find("code") then
        for _, nm in ipairs(TriggerMatcher.names) do
            scan(nm:lower(), true, true)
        end
    end
    if not lastEnd then return nil end
    local tail = str:sub(lastEnd + 1)
    local sub = FindCodeSubstring(tail)
    if fromName then return sub end
    return sub or ""
end

-- Gemini AI Riddle Solver
local RiddleCache = {}
local function SolveRiddleWithGemini(question, callback)
    local cleanQ = Trim(question)
    if cleanQ == "" then return end

    if RiddleCache[cleanQ] then
        callback(RiddleCache[cleanQ], true)
        return
    end

    if not httpRequest then
        callback(nil, false, "executor lacks http request")
        return
    end

    task.spawn(function()
        local url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=" .. GEMINI_API_KEY
        local payload = HttpService:JSONEncode({
            contents = {{
                parts = {{
                    text = "You are solving a fast riddle or trivia question inside the Roblox game 'Steal a Brainrot' to get a redeemable code. Reply with ONLY the exact answer (usually 1 to 3 words or a number, no punctuation, no markdown, no explanation). Question: " .. cleanQ
                }}
            }},
            generationConfig = {
                temperature = 0.1,
                maxOutputTokens = 25
            }
        })

        local ok, res = pcall(function()
            return httpRequest({
                Url = url,
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = payload
            })
        end)

        if ok and res and res.Body then
            local parseOk, decoded = pcall(function()
                return HttpService:JSONDecode(res.Body)
            end)
            if parseOk and decoded and decoded.candidates and decoded.candidates[1] then
                local content = decoded.candidates[1].content
                if content and content.parts and content.parts[1] and content.parts[1].text then
                    local answer = Trim(content.parts[1].text)
                    answer = answer:gsub("[\r\n\"'%.!%?]", "")
                    answer = answer:gsub("%s+", "")
                    if answer ~= "" then
                        RiddleCache[cleanQ] = answer
                        callback(answer, false)
                        return
                    end
                end
            end
        end
        callback(nil, false, "gemini api error")
    end)
end

-- Code UI Interactor
local function GetGameCodeBox()
    local codes = PlayerGui:FindFirstChild("Codes")
    if not codes then return nil end
    local main = (codes:FindFirstChild("Codes") or codes):FindFirstChild("Main")
    local box = main and main:FindFirstChild("TextBox")
    if box and box:IsA("TextBox") then return box end
    for _, d in ipairs(codes:GetDescendants()) do
        if d:IsA("TextBox") then return d end
    end
end

local function GetGameSubmitButton()
    local codes = PlayerGui:FindFirstChild("Codes")
    if not codes then return nil end
    local inner = codes:FindFirstChild("Codes") or codes
    local confirm = (inner:FindFirstChild("Main") or inner):FindFirstChild("Confirm")
    if confirm and (confirm:IsA("ImageButton") or confirm:IsA("TextButton")) then
        return confirm
    end
    local fallback = nil
    for _, d in ipairs(codes:GetDescendants()) do
        if d:IsA("ImageButton") or d:IsA("TextButton") then
            local n = d.Name:lower()
            if n:find("confirm") or n:find("submit") or n:find("redeem") or n:find("enter") then
                return d
            end
            fallback = fallback or d
        end
    end
    return fallback
end

local function FireSignalConnections(sig, ...)
    if not getconnections_ then return false end
    local ok, conns = pcall(getconnections_, sig)
    if not ok or type(conns) ~= "table" or #conns == 0 then return false end
    local args = table.pack(...)
    local fired = false
    for _, c in ipairs(conns) do
        if c.Enabled ~= false then
            local fn = nil
            pcall(function() fn = c.Function end)
            local stepOk
            if fn then
                stepOk = pcall(task.spawn, fn, table.unpack(args, 1, args.n))
            else
                stepOk = pcall(function() c:Fire(table.unpack(args, 1, args.n)) end)
            end
            fired = fired or stepOk
        end
    end
    return fired
end

local function SyncGameTextBox(text)
    if type(text) ~= "string" or text == "" then return end
    local box = GetGameCodeBox()
    if box then
        pcall(function()
            if box.Text ~= text then box.Text = text end
        end)
    end
end

local function SubmitCodeToGame(text)
    local box = GetGameCodeBox()
    if not box then return false, "code box not found" end

    if getconnections_ then
        pcall(function()
            box.Text = text
            box.Active = true
            box.Selectable = true
        end)
        local btn = GetGameSubmitButton()
        local fired = false
        if btn then
            fired = FireSignalConnections(btn.Activated)
            if not fired then
                fired = FireSignalConnections(btn.MouseButton1Click)
            end
        end
        if not fired then
            fired = FireSignalConnections(box.FocusLost, true)
        end
        if fired then return true, "submitted" end
    end

    if not pcall(function()
        box.Text = text
        box:CaptureFocus()
    end) then
        return false, "focus failed"
    end
    task.wait()
    local ok = pcall(function()
        box:ReleaseFocus(true)
    end)
    return ok, ok and "submitted" or "release failed"
end

-- Remote Finder
local function FindNotificationRemote()
    local ok, ctrl = pcall(function()
        return require(ReplicatedStorage.Controllers:FindFirstChild("NotificationController", true))
    end)
    if ok and type(ctrl) == "table" and type(ctrl.Start) == "function" and getupvalues_ then
        local uOk, ups = pcall(getupvalues_, ctrl.Start)
        if uOk and ups then
            for _, v in pairs(ups) do
                if typeof(v) == "Instance" and (v:IsA("RemoteEvent") or v:IsA("UnreliableRemoteEvent")) and v.Parent == Net then
                    return v
                end
            end
        end
    end
end

-- UI Theme & Builders (Original Traced Hub Aesthetic)
local Theme = {
    bg = Color3.fromRGB(6, 6, 10),
    panel = Color3.fromRGB(16, 15, 21),
    panel2 = Color3.fromRGB(32, 28, 42),
    line = Color3.fromRGB(42, 35, 52),
    acc = Color3.fromRGB(235, 90, 175),
    acc2 = Color3.fromRGB(160, 50, 110),
    accHi = Color3.fromRGB(255, 130, 210),
    txt = Color3.fromRGB(240, 240, 255),
    sub = Color3.fromRGB(160, 175, 195),
    ok = Color3.fromRGB(55, 195, 105),
    err = Color3.fromRGB(205, 50, 50),
    warn = Color3.fromRGB(255, 215, 0),
    input = Color3.fromRGB(11, 10, 15),
}

local FontMed = Enum.Font.GothamMedium
local FontBold = Enum.Font.GothamBold
local FontBlack = Enum.Font.GothamBlack

local function New(cls, props, parent)
    local inst = Instance.new(cls)
    for k, v in pairs(props or {}) do inst[k] = v end
    if parent then inst.Parent = parent end
    return inst
end

local function Corner(p, r) New("UICorner", { CornerRadius = UDim.new(0, r or 8) }, p) end
local function Stroke(p, c, t, tr) return New("UIStroke", { Color = c or Theme.line, Thickness = t or 1, Transparency = tr or 0 }, p) end
local function Tween(obj, dur, props, style) TweenService:Create(obj, TweenInfo.new(dur, style or Enum.EasingStyle.Quad), props):Play() end
local function Grad(p, c1, c2, rot) return New("UIGradient", { Color = ColorSequence.new(c1, c2), Rotation = rot or 90 }, p) end

local function Label(txt, sz, col, fnt, align, parent)
    return New("TextLabel", {
        BackgroundTransparency = 1,
        Text = txt,
        Font = fnt or FontMed,
        TextSize = sz or 12,
        TextColor3 = col or Theme.txt,
        TextXAlignment = align or Enum.TextXAlignment.Left,
    }, parent)
end

local function MakeDraggable(handle, target)
    local dragging, startPos, startInput
    handle.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            startInput = inp.Position
            startPos = target.Position
            inp.Changed:Connect(function()
                if inp.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
                end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
            local d = inp.Position - startInput
            target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
end

local function CreateWindow(name, w, h, titleText)
    local win = New("Frame", {
        Name = name,
        Size = UDim2.fromOffset(w, h),
        BackgroundColor3 = Theme.bg,
        BorderSizePixel = 0,
        Active = true,
        ClipsDescendants = true,
    })
    Corner(win, 14)
    Grad(win, Color3.fromRGB(20, 15, 21), Color3.fromRGB(6, 6, 10), 90)
    Stroke(win, Theme.acc, 1.5, 0.45)
    if IsMobile then
        New("UIScale", { Name = "WinScale", Scale = CurrentScale }, win)
    end

    local top = New("Frame", { Size = UDim2.new(1, 0, 0, 44), BackgroundColor3 = Theme.panel, BorderSizePixel = 0 }, win)
    Corner(top, 14)
    New("Frame", { Size = UDim2.new(1, 0, 0, 14), Position = UDim2.new(0, 0, 1, -14), BackgroundColor3 = Theme.panel, BorderSizePixel = 0 }, top)

    local icon = New("ImageLabel", {
        Size = UDim2.fromOffset(24, 24),
        Position = UDim2.new(0, 12, 0.5, -12),
        BackgroundColor3 = Theme.panel2,
        BorderSizePixel = 0,
        Image = "rbxthumb://type=Asset&id=124491981850461&w=150&h=150",
    }, top)
    Corner(icon, 12)
    Stroke(icon, Theme.acc, 1.5, 0.2)

    local ttl = Label(titleText, 14, Theme.txt, FontBlack, Enum.TextXAlignment.Left, top)
    ttl.Size = UDim2.new(1, -80, 1, 0)
    ttl.Position = UDim2.fromOffset(44, 0)

    MakeDraggable(top, win)
    return win, top, icon, ttl
end

local function Btn(txt, parent)
    local b = New("TextButton", {
        BackgroundColor3 = Theme.panel2,
        Text = txt,
        Font = FontBold,
        TextSize = 12,
        TextColor3 = Theme.txt,
        AutoButtonColor = false,
        BorderSizePixel = 0,
    }, parent)
    Corner(b, 8)
    local s = Stroke(b, Theme.line, 1, 0.2)
    b.MouseEnter:Connect(function()
        Tween(b, 0.12, { BackgroundColor3 = Theme.panel })
        Tween(s, 0.12, { Color = Theme.acc, Transparency = 0 })
    end)
    b.MouseLeave:Connect(function()
        Tween(b, 0.12, { BackgroundColor3 = Theme.panel2 })
        Tween(s, 0.12, { Color = Theme.line, Transparency = 0.2 })
    end)
    return b
end

local function PrimaryBtn(txt, parent)
    local b = New("TextButton", {
        BackgroundColor3 = Theme.acc,
        Text = txt,
        Font = FontBlack,
        TextSize = 13,
        TextColor3 = Color3.new(1, 1, 1),
        AutoButtonColor = false,
        BorderSizePixel = 0,
    }, parent)
    Corner(b, 8)
    Grad(b, Theme.acc, Theme.acc2, 90)
    b.MouseEnter:Connect(function() Tween(b, 0.12, { BackgroundColor3 = Theme.accHi }) end)
    b.MouseLeave:Connect(function() Tween(b, 0.12, { BackgroundColor3 = Theme.acc }) end)
    return b
end

-- ScreenGui Mounting
local GuiParent = gethui and gethui() or PlayerGui
local Existing = GuiParent:FindFirstChild("Traced")
if Existing then Existing:Destroy() end

local ScreenGui = New("ScreenGui", {
    Name = "Traced",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 250,
}, GuiParent)

local BaseHeight = 584
local Main, TopBar, _, TitleLbl = CreateWindow("Main", 316, BaseHeight, "TRACED")
Main.Position = IsMobile
    and UDim2.new(1, -math.floor(316 * CurrentScale) - 8, 0.5, -math.floor(BaseHeight * CurrentScale / 2))
    or UDim2.new(1, -340, 0.5, -math.floor(BaseHeight / 2))
Main.Parent = ScreenGui
TitleLbl.Size = UDim2.new(1, -262, 1, 0)

-- Background Aesthetic
local CityBg = New("ImageLabel", {
    Name = "CityBg",
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ZIndex = 0,
    Image = "rbxthumb://type=Asset&id=96519310989847&w=420&h=420",
    ImageTransparency = 0.5,
    ImageColor3 = Color3.fromRGB(200, 160, 180),
    ScaleType = Enum.ScaleType.Crop,
}, Main)
Corner(CityBg, 14)

-- TopBar Controls
local ConnDot = New("Frame", {
    Size = UDim2.fromOffset(8, 8),
    Position = UDim2.new(1, -212, 0.5, -4),
    BackgroundColor3 = Theme.sub,
    BorderSizePixel = 0,
    Visible = false,
}, TopBar)
Corner(ConnDot, 4)

local RagBtn = Btn("Rag", TopBar)
RagBtn.Size = UDim2.fromOffset(38, 22)
RagBtn.Position = UDim2.new(1, -200, 0.5, -11)
RagBtn.TextSize = 10

local TestBtn = Btn("Test", TopBar)
TestBtn.Size = UDim2.fromOffset(38, 22)
TestBtn.Position = UDim2.new(1, -157, 0.5, -11)
TestBtn.TextSize = 10

local FeedBtn = Btn("FEED", TopBar)
FeedBtn.Size = UDim2.fromOffset(38, 22)
FeedBtn.Position = UDim2.new(1, -114, 0.5, -11)
FeedBtn.TextSize = 10

local SettingsBtn = Btn("Settings", TopBar)
SettingsBtn.Size = UDim2.fromOffset(38, 22)
SettingsBtn.Position = UDim2.new(1, -71, 0.5, -11)
SettingsBtn.TextSize = 8

local MinBtn = Btn("", TopBar)
MinBtn.Size = UDim2.fromOffset(22, 22)
MinBtn.Position = UDim2.new(1, -28, 0.5, -11)
Corner(New("Frame", { Size = UDim2.fromOffset(10, 2), Position = UDim2.new(0.5, -5, 0.5, -1), BackgroundColor3 = Theme.txt, BorderSizePixel = 0 }, MinBtn), 1)
local MinPlus = New("Frame", { Size = UDim2.fromOffset(2, 10), Position = UDim2.new(0.5, -1, 0.5, -5), BackgroundColor3 = Theme.txt, BorderSizePixel = 0, Visible = false }, MinBtn)
Corner(MinPlus, 1)

local Minimized = false
local CurrentMainHeight = BaseHeight
MinBtn.MouseButton1Click:Connect(function()
    Minimized = not Minimized
    MinPlus.Visible = Minimized
    Tween(Main, 0.25, { Size = UDim2.fromOffset(316, Minimized and 179 or CurrentMainHeight) })
end)

-- Body Layout
local Body = New("Frame", {
    Size = UDim2.new(1, -20, 1, -54),
    Position = UDim2.fromOffset(10, 48),
    BackgroundTransparency = 1,
}, Main)
New("UIListLayout", { Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder }, Body)

-- Status Bar
local StatusCard = New("Frame", { Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = Theme.panel, BorderSizePixel = 0, LayoutOrder = 1 }, Body)
Corner(StatusCard, 9)
Stroke(StatusCard, Theme.line, 1, 0.3)
local StatusDot = New("Frame", { Size = UDim2.fromOffset(8, 8), Position = UDim2.new(0, 12, 0.5, -4), BackgroundColor3 = Theme.sub, BorderSizePixel = 0 }, StatusCard)
Corner(StatusDot, 4)
local StatusText = Label("starting...", 12, Theme.txt, FontBold, Enum.TextXAlignment.Left, StatusCard)
StatusText.Size = UDim2.new(1, -32, 1, 0)
StatusText.Position = UDim2.fromOffset(28, 0)
StatusText.TextTruncate = Enum.TextTruncate.AtEnd

local function SetStatus(txt, mode)
    StatusText.Text = txt
    local c = mode == "ok" and Theme.ok or mode == "err" and Theme.err or mode == "busy" and Theme.acc or mode == "wait" and Theme.warn or Theme.txt
    StatusText.TextColor3 = c
    StatusDot.BackgroundColor3 = c
end

-- Code Box
local CodeCard = New("Frame", { Size = UDim2.new(1, 0, 0, 50), BackgroundColor3 = Theme.panel, BorderSizePixel = 0, LayoutOrder = 2 }, Body)
Corner(CodeCard, 9)
Stroke(CodeCard, Theme.line, 1, 0.3)
local CodeHdr = Label("CODE", 9, Theme.acc, FontBlack, Enum.TextXAlignment.Left, CodeCard)
CodeHdr.Size = UDim2.new(1, -16, 0, 11)
CodeHdr.Position = UDim2.fromOffset(11, 5)

local CodeInput = New("TextBox", {
    Size = UDim2.new(1, -18, 0, 26),
    Position = UDim2.fromOffset(9, 18),
    BackgroundColor3 = Theme.input,
    Text = "",
    PlaceholderText = "type or snipe a code...",
    PlaceholderColor3 = Theme.sub,
    Font = FontBlack,
    TextSize = 14,
    TextColor3 = Theme.txt,
    ClearTextOnFocus = false,
    BorderSizePixel = 0,
    TextXAlignment = Enum.TextXAlignment.Left,
}, CodeCard)
Corner(CodeInput, 7)
local InputStroke = Stroke(CodeInput, Theme.line, 1.2, 0.25)
New("UIPadding", { PaddingLeft = UDim.new(0, 9), PaddingRight = UDim.new(0, 9) }, CodeInput)
CodeInput.Focused:Connect(function() Tween(InputStroke, 0.12, { Color = Theme.acc, Transparency = 0 }) end)
CodeInput.FocusLost:Connect(function() Tween(InputStroke, 0.12, { Color = Theme.line, Transparency = 0.25 }) end)

-- Action Buttons
local ActionRow = New("Frame", { Size = UDim2.new(1, 0, 0, 33), BackgroundTransparency = 1, LayoutOrder = 3 }, Body)
New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, ActionRow)

local CopyBtn = Btn("COPY", ActionRow)
CopyBtn.Size = UDim2.new(0.3333, -4, 1, 0)
CopyBtn.LayoutOrder = 1

local ClearBtn = Btn("CLEAR", ActionRow)
ClearBtn.Size = UDim2.new(0.3333, -4, 1, 0)
ClearBtn.LayoutOrder = 2

local RedeemBtn = PrimaryBtn("REDEEM", ActionRow)
RedeemBtn.Size = UDim2.new(0.3333, -4, 1, 0)
RedeemBtn.LayoutOrder = 3
RedeemBtn.TextColor3 = Color3.new(0, 0, 0)

-- Toggle Factory
local function CreateToggleRow(parent, order, title, defaultVal, onChange)
    local row = New("Frame", { Size = UDim2.new(1, 0, 0, 31), BackgroundColor3 = Theme.panel, BorderSizePixel = 0, LayoutOrder = order }, parent)
    Corner(row, 8)
    Stroke(row, Theme.line, 1, 0.3)
    local lbl = Label(title, 11, Theme.sub, FontBold, Enum.TextXAlignment.Left, row)
    lbl.Size = UDim2.new(1, -56, 1, 0)
    lbl.Position = UDim2.fromOffset(12, 0)
    lbl.TextTruncate = Enum.TextTruncate.AtEnd

    local pill = New("Frame", { Size = UDim2.fromOffset(36, 18), Position = UDim2.new(1, -44, 0.5, -9), BackgroundColor3 = Theme.line, BorderSizePixel = 0 }, row)
    Corner(pill, 9)
    local knob = New("Frame", { Size = UDim2.fromOffset(14, 14), Position = UDim2.new(0, 2, 0.5, -7), BackgroundColor3 = Theme.txt, BorderSizePixel = 0 }, pill)
    Corner(knob, 7)

    local hit = New("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "" }, row)
    local val = defaultVal
    local function refresh()
        Tween(pill, 0.16, { BackgroundColor3 = val and Theme.acc or Theme.line })
        Tween(knob, 0.16, { Position = UDim2.new(0, val and 20 or 2, 0.5, -7) }, Enum.EasingStyle.Back)
        Tween(lbl, 0.16, { TextColor3 = val and Theme.txt or Theme.sub })
    end
    refresh()
    hit.MouseButton1Click:Connect(function()
        val = not val
        refresh()
        if onChange then onChange(val) end
    end)
    return row
end

-- Listen Toggle
local ListenRow = New("Frame", { Size = UDim2.new(1, 0, 0, 31), BackgroundColor3 = Theme.panel, BorderSizePixel = 0, LayoutOrder = 4 }, Body)
Corner(ListenRow, 8)
Stroke(ListenRow, Theme.line, 1, 0.3)
local ListenLbl = Label("LISTEN", 11, Theme.sub, FontBold, Enum.TextXAlignment.Left, ListenRow)
ListenLbl.Size = UDim2.new(1, -56, 1, 0)
ListenLbl.Position = UDim2.fromOffset(12, 0)
local ListenPill = New("Frame", { Size = UDim2.fromOffset(36, 18), Position = UDim2.new(1, -44, 0.5, -9), BackgroundColor3 = Theme.line, BorderSizePixel = 0 }, ListenRow)
Corner(ListenPill, 9)
local ListenKnob = New("Frame", { Size = UDim2.fromOffset(14, 14), Position = UDim2.new(0, 2, 0.5, -7), BackgroundColor3 = Theme.txt, BorderSizePixel = 0 }, ListenPill)
Corner(ListenKnob, 7)
local ListenHit = New("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "" }, ListenRow)

-- Keybind Rows
local ListenKeyRow = New("Frame", { Size = UDim2.new(1, 0, 0, 31), BackgroundColor3 = Theme.panel, BorderSizePixel = 0, LayoutOrder = 5 }, Body)
Corner(ListenKeyRow, 8)
Stroke(ListenKeyRow, Theme.line, 1, 0.3)
local LKeyLbl = Label("LISTEN KEY", 11, Theme.sub, FontBold, Enum.TextXAlignment.Left, ListenKeyRow)
LKeyLbl.Size = UDim2.new(1, -100, 1, 0)
LKeyLbl.Position = UDim2.fromOffset(12, 0)
local LKeyBtn = Btn(ListenKey and ListenKey.Name or "-", ListenKeyRow)
LKeyBtn.Size = UDim2.fromOffset(46, 24)
LKeyBtn.Position = UDim2.new(1, -84, 0.5, -12)
LKeyBtn.TextSize = 11
local LKeyClear = Btn("X", ListenKeyRow)
LKeyClear.Size = UDim2.fromOffset(24, 24)
LKeyClear.Position = UDim2.new(1, -32, 0.5, -12)
LKeyClear.TextSize = 12

local RedeemKeyRow = New("Frame", { Size = UDim2.new(1, 0, 0, 31), BackgroundColor3 = Theme.panel, BorderSizePixel = 0, LayoutOrder = 6 }, Body)
Corner(RedeemKeyRow, 8)
Stroke(RedeemKeyRow, Theme.line, 1, 0.3)
local RKeyLbl = Label("REDEEM KEY", 11, Theme.sub, FontBold, Enum.TextXAlignment.Left, RedeemKeyRow)
RKeyLbl.Size = UDim2.new(1, -100, 1, 0)
RKeyLbl.Position = UDim2.fromOffset(12, 0)
local RKeyBtn = Btn(RedeemKey and RedeemKey.Name or "-", RedeemKeyRow)
RKeyBtn.Size = UDim2.fromOffset(46, 24)
RKeyBtn.Position = UDim2.new(1, -84, 0.5, -12)
RKeyBtn.TextSize = 11
local RKeyClear = Btn("X", RedeemKeyRow)
RKeyClear.Size = UDim2.fromOffset(24, 24)
RKeyClear.Position = UDim2.new(1, -32, 0.5, -12)
RKeyClear.TextSize = 12

-- Core Feature Toggles
CreateToggleRow(Body, 7, "AUTO REDEEM", AutoRedeem, function(v)
    AutoRedeem = v
    _G.__RdmCfgSet("autoRedeem", v)
end)

CreateToggleRow(Body, 8, "AUTO RIDDLE (GEMINI AI)", AutoRiddleAI, function(v)
    AutoRiddleAI = v
    _G.__RdmCfgSet("autoRiddleAI", v)
end)

CreateToggleRow(Body, 9, "AUTO TYPE", AutoType, function(v)
    AutoType = v
    _G.__RdmCfgSet("autoType", v)
end)

local UpdateWordsVisibility
CreateToggleRow(Body, 10, "MANUAL", ManualMode, function(v)
    ManualMode = v
    CapturedTokens = {}
    UpdateWordsVisibility()
end)

-- Multi-Option Selector Helper
local function CreateSelectorRow(order, title, options, defaultOpt, onSelect)
    local row = New("Frame", { Size = UDim2.new(1, 0, 0, 31), BackgroundColor3 = Theme.panel, BorderSizePixel = 0, LayoutOrder = order }, Body)
    Corner(row, 8)
    Stroke(row, Theme.line, 1, 0.3)
    local lbl = Label(title, 11, Theme.sub, FontBold, Enum.TextXAlignment.Left, row)
    lbl.Size = UDim2.fromOffset(56, 31)
    lbl.Position = UDim2.fromOffset(11, 0)

    local box = New("Frame", { Size = UDim2.fromOffset(168, 23), Position = UDim2.new(1, -177, 0.5, -11.5), BackgroundColor3 = Theme.input, BorderSizePixel = 0 }, row)
    Corner(box, 7)

    local btns = {}
    local function pick(opt)
        for k, b in pairs(btns) do
            local active = k == opt
            Tween(b, 0.12, { BackgroundColor3 = active and Theme.acc or Theme.input })
            b.TextColor3 = active and Color3.new(1, 1, 1) or Theme.sub
        end
        if onSelect then onSelect(opt) end
    end

    for i, item in ipairs(options) do
        local key = type(item) == "table" and item[1] or item
        local text = type(item) == "table" and item[2] or item
        local b = New("TextButton", {
            Size = UDim2.new(1 / #options, -2, 1, -2),
            Position = UDim2.new((i - 1) / #options, 1, 0, 1),
            BackgroundColor3 = Theme.input,
            Text = text,
            Font = FontBold,
            TextSize = text:find("\n") and 8 or 9,
            TextColor3 = Theme.sub,
            AutoButtonColor = false,
            BorderSizePixel = 0,
        }, box)
        Corner(b, 6)
        btns[key] = b
        b.MouseButton1Click:Connect(function() pick(key) end)
    end
    pick(defaultOpt)
    return row
end

-- Dynamic Length Selector (AUTO + 1, 2, 3, 4)
local WordsRow = CreateSelectorRow(11, "WORDS", { "AUTO", "1", "2", "3", "4" }, WordModeSetting, function(v)
    WordModeSetting = v
    TargetWordCount = tonumber(v) or 0 -- 0 means AUTO dynamic length
    _G.__RdmCfgSet("wordCount", v)
    CapturedTokens = {}
    if IsListening and not ManualMode then
        SetStatus(TargetWordCount == 0 and "listening... (AUTO length)" or ("listening... 0/%d"):format(TargetWordCount), "wait")
    end
end)

-- Spam Row
local SpamRow = New("Frame", { Size = UDim2.new(1, 0, 0, 31), BackgroundColor3 = Theme.panel, BorderSizePixel = 0, LayoutOrder = 12 }, Body)
Corner(SpamRow, 8)
local SpamStroke = Stroke(SpamRow, Theme.line, 1, 0.3)
local SpamLbl = Label("SPAM", 11, Theme.sub, FontBold, Enum.TextXAlignment.Left, SpamRow)
SpamLbl.Size = UDim2.new(1, -94, 1, 0)
SpamLbl.Position = UDim2.fromOffset(11, 0)
local SpamStartBtn = Btn("START", SpamRow)
SpamStartBtn.Size = UDim2.fromOffset(70, 24)
SpamStartBtn.Position = UDim2.new(1, -78, 0.5, -12)
SpamStartBtn.TextSize = 11
local SpamDot = New("Frame", { Size = UDim2.fromOffset(7, 7), Position = UDim2.new(0, 9, 0.5, -3.5), BackgroundColor3 = Theme.line, BorderSizePixel = 0 }, SpamStartBtn)
Corner(SpamDot, 4)

CreateSelectorRow(13, "SPEED", { "MAX", { "WORD", "EVERY\nWORD" } }, WordSpamMode and "WORD" or "MAX", function(v)
    WordSpamMode = v == "WORD"
    if not WordSpamMode then
        SpamDelay = SpeedTable[v] or SpeedTable.MAX
    end
    _G.__RdmCfgSet("speed", v)
    _G.__RdmCfgSet("wordMode", WordSpamMode)
end)

-- Dynamic Row Collapsing
local CollapsedState = {}
local CollapsedCount = 0
local function SetRowVisible(row, show, instant)
    local cur = CollapsedState[row]
    if cur == nil then cur = true end
    if cur == show then return end
    CollapsedState[row] = show
    CollapsedCount = math.max(0, CollapsedCount + (show and -1 or 1))
    CurrentMainHeight = BaseHeight - CollapsedCount * 36
    if not Minimized then
        if instant then
            Main.Size = UDim2.fromOffset(316, CurrentMainHeight)
        else
            Tween(Main, 0.2, { Size = UDim2.fromOffset(316, CurrentMainHeight) }, Enum.EasingStyle.Quart)
        end
    end
    row.ClipsDescendants = true
    if show then
        row.Visible = true
        row.Size = UDim2.new(1, 0, 0, 31)
        row.ClipsDescendants = false
    else
        row.Size = UDim2.new(1, 0, 0, 0)
        row.Visible = false
    end
end

UpdateWordsVisibility = function(instant)
    SetRowVisible(WordsRow, not ManualMode, instant)
end
local function UpdateKeybindsVisibility(instant)
    SetRowVisible(ListenKeyRow, ShowKeybinds, instant)
    SetRowVisible(RedeemKeyRow, ShowKeybinds, instant)
end

-- Secondary Windows (Settings, Live Feed, Fake Notify, Anti-Ragdoll)
local SettingsWin, SettingsTop = CreateWindow("Settings", 300, IsMobile and 280 or 244, "SETTINGS")
SettingsWin.Visible = false
SettingsWin.Parent = ScreenGui
local SetClose = Btn("X", SettingsTop)
SetClose.Size = UDim2.fromOffset(22, 22)
SetClose.Position = UDim2.new(1, -28, 0.5, -11)
SetClose.TextSize = 12
SetClose.MouseButton1Click:Connect(function() SettingsWin.Visible = false end)

local SetBody = New("Frame", { Size = UDim2.new(1, -20, 1, -60), Position = UDim2.fromOffset(10, 50), BackgroundTransparency = 1 }, SettingsWin)
New("UIListLayout", { Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder }, SetBody)

CreateToggleRow(SetBody, 1, "AUTO LISTEN", AutoListen, function(v) AutoListen = v; _G.__RdmCfgSet("autoListen", v) end)
CreateToggleRow(SetBody, 2, "SPAM ON LISTEN", SpamOnListen, function(v) SpamOnListen = v; _G.__RdmCfgSet("spamOnListen", v) end)
CreateToggleRow(SetBody, 3, "SHOW KEYBINDS", ShowKeybinds, function(v) ShowKeybinds = v; UpdateKeybindsVisibility(); _G.__RdmCfgSet("showKeybinds", v) end)
CreateToggleRow(SetBody, 4, "IGNORE SYSTEM PHRASES", IgnoreSystem, function(v) IgnoreSystem = v; _G.__RdmCfgSet("ignoreSystem", v) end)

SettingsBtn.MouseButton1Click:Connect(function()
    if SettingsWin.Visible then SettingsWin.Visible = false return end
    if IsMobile then
        SettingsWin.Position = UDim2.new(0.5, -math.floor(SettingsWin.AbsoluteSize.X / 2), 0.5, -math.floor(SettingsWin.AbsoluteSize.Y / 2))
    else
        SettingsWin.Position = UDim2.new(Main.Position.X.Scale, Main.Position.X.Offset - SettingsWin.AbsoluteSize.X - 10, Main.Position.Y.Scale, Main.Position.Y.Offset)
    end
    SettingsWin.Visible = true
end)

-- Live Feed Window
local FeedWin, FeedTop = CreateWindow("Feed", 300, 320, "LIVE FEED")
FeedWin.Visible = false
FeedWin.Parent = ScreenGui
local FeedDot = New("Frame", { Size = UDim2.fromOffset(8, 8), Position = UDim2.new(1, -176, 0.5, -4), BackgroundColor3 = Theme.sub, BorderSizePixel = 0 }, FeedTop)
Corner(FeedDot, 4)
local FeedCountLbl = Label("0 caught", 10, Theme.sub, FontBold, Enum.TextXAlignment.Right, FeedTop)
FeedCountLbl.Size = UDim2.fromOffset(80, 44)
FeedCountLbl.Position = UDim2.new(1, -166, 0, 0)
local FeedClearBtn = Btn("CLEAR", FeedTop)
FeedClearBtn.Size = UDim2.fromOffset(40, 22)
FeedClearBtn.Position = UDim2.new(1, -82, 0.5, -11)
FeedClearBtn.TextSize = 10
local FeedCloseBtn = Btn("X", FeedTop)
FeedCloseBtn.Size = UDim2.fromOffset(22, 22)
FeedCloseBtn.Position = UDim2.new(1, -32, 0.5, -11)
FeedCloseBtn.TextSize = 12
FeedCloseBtn.MouseButton1Click:Connect(function() FeedWin.Visible = false end)

local FeedScroll = New("ScrollingFrame", {
    Size = UDim2.new(1, -18, 1, -56),
    Position = UDim2.fromOffset(11, 50),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 3,
    ScrollBarImageColor3 = Theme.acc,
    CanvasSize = UDim2.new(),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, FeedWin)
New("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, FeedScroll)

local FeedItems = {}
local FeedCounter = 0
local RedeemCodeNow -- forward declaration

local function AddFeedEntry(rawMsg, detectedCode)
    FeedCounter += 1
    FeedCountLbl.Text = FeedCounter .. " caught"
    local card = New("Frame", {
        Size = UDim2.new(1, -4, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Theme.panel,
        BorderSizePixel = 0,
        LayoutOrder = -FeedCounter,
    }, FeedScroll)
    Corner(card, 9)
    Stroke(card, detectedCode and Theme.acc or Theme.line, 1, detectedCode and 0.3 or 0.5)
    New("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }, card)
    New("UIListLayout", { Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder }, card)

    local msgLbl = Label(rawMsg, 10, Theme.txt, FontMed, Enum.TextXAlignment.Left, card)
    msgLbl.Size = UDim2.new(1, 0, 0, 0)
    msgLbl.AutomaticSize = Enum.AutomaticSize.Y
    msgLbl.TextWrapped = true
    msgLbl.LayoutOrder = 1

    if detectedCode then
        local bar = New("Frame", { Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, LayoutOrder = 2 }, card)
        local cLbl = New("TextLabel", {
            Size = UDim2.new(0.5, -3, 1, 0),
            BackgroundColor3 = Theme.input,
            Text = detectedCode,
            Font = FontBlack,
            TextSize = 11,
            TextColor3 = Theme.acc,
            BorderSizePixel = 0,
        }, bar)
        Corner(cLbl, 6)
        local cp = Btn("COPY", bar)
        cp.Size = UDim2.new(0.22, -3, 1, 0)
        cp.Position = UDim2.new(0.52, 3, 0, 0)
        cp.TextSize = 9
        cp.MouseButton1Click:Connect(function() CopyToClipboard(detectedCode) end)

        local use = PrimaryBtn("USE", bar)
        use.Size = UDim2.new(0.26, -3, 1, 0)
        use.Position = UDim2.new(0.74, 3, 0, 0)
        use.TextSize = 10
        use.MouseButton1Click:Connect(function()
            CodeInput.Text = detectedCode
            RedeemCodeNow(detectedCode)
        end)
    end

    table.insert(FeedItems, card)
    if #FeedItems > Config.maxFeed then
        local old = table.remove(FeedItems, 1)
        if old then old:Destroy() end
    end
end

FeedClearBtn.MouseButton1Click:Connect(function()
    for _, c in ipairs(FeedItems) do c:Destroy() end
    FeedItems = {}
    FeedCounter = 0
    FeedCountLbl.Text = "0 caught"
end)

FeedBtn.MouseButton1Click:Connect(function()
    if FeedWin.Visible then FeedWin.Visible = false return end
    if IsMobile then
        FeedWin.Position = UDim2.new(0.5, -math.floor(FeedWin.AbsoluteSize.X / 2), 0.5, -math.floor(FeedWin.AbsoluteSize.Y / 2))
    else
        FeedWin.Position = UDim2.new(Main.Position.X.Scale, Main.Position.X.Offset - FeedWin.AbsoluteSize.X - 10, Main.Position.Y.Scale, Main.Position.Y.Offset)
    end
    FeedWin.Visible = true
end)

-- Anti-Ragdoll Module (Continuous Movement Restoration)
local AntiRagdollEnabled = false
local AntiRagdollConn = nil

local function ToggleAntiRagdoll(state)
    AntiRagdollEnabled = state
    RagBtn.TextColor3 = state and Theme.acc or Theme.txt
    if state and not AntiRagdollConn then
        AntiRagdollConn = RunService.Heartbeat:Connect(function()
            if not AntiRagdollEnabled then return end
            local char = LocalPlayer.Character
            if not char then return end
            local hum = char:FindFirstChildOfClass("Humanoid")
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hum or not hrp or hum.Health <= 0 then return end

            local st = hum:GetState()
            if st == Enum.HumanoidStateType.Physics or st == Enum.HumanoidStateType.Ragdoll or st == Enum.HumanoidStateType.FallingDown or st == Enum.HumanoidStateType.PlatformStanding then
                pcall(function()
                    hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                    hrp.Velocity = Vector3.zero
                    hrp.RotVelocity = Vector3.zero
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                    for _, d in ipairs(char:GetDescendants()) do
                        if d:IsA("Motor6D") or d:IsA("Weld") then d.Enabled = true end
                    end
                    local pm = LocalPlayer.PlayerScripts:FindFirstChild("PlayerModule")
                    if pm then
                        local ctrl = require(pm):GetControls()
                        if ctrl and ctrl.Enable then ctrl:Enable() end
                    end
                    hum.AutoRotate = true
                    hum.PlatformStand = false
                    hum.Sit = false
                end)
            end
        end)
    elseif not state and AntiRagdollConn then
        AntiRagdollConn:Disconnect()
        AntiRagdollConn = nil
    end
end

RagBtn.MouseButton1Click:Connect(function()
    ToggleAntiRagdoll(not AntiRagdollEnabled)
    SetStatus(AntiRagdollEnabled and "Anti-Ragdoll: ON" or "Anti-Ragdoll: OFF", AntiRagdollEnabled and "ok" or "idle")
end)

-- Core Redemption & Listening Logic
RedeemCodeNow = function(rawCode, tag)
    local clean = Trim(rawCode)
    if clean == "" then
        SetStatus("nothing to redeem", "err")
        return false
    end
    tag = tag and (tag .. " ") or ""
    SetStatus(("%sredeeming: %s"):format(tag, clean), "busy")
    local ok, msg = SubmitCodeToGame(clean)
    if ok then
        SetStatus(("%ssent: %s"):format(tag, clean), "ok")
    else
        SetStatus(("%sfailed: %s"):format(tag, msg or clean), "err")
    end
    return ok
end

local function SetCodeBox(txt)
    LastTypedCode = txt
    CodeInput.Text = txt
end

local function ToggleSpam(state)
    if state and not IsListening then
        SetStatus("turn LISTEN on first", "err")
        return
    end
    if state == IsSpamming then return end
    IsSpamming = state
    SpamStartBtn.Text = state and "STOP" or "START"
    SpamStartBtn.TextColor3 = state and Theme.acc or Theme.txt
    Tween(SpamDot, 0.16, { BackgroundColor3 = state and Theme.acc or Theme.line })
    Tween(SpamLbl, 0.16, { TextColor3 = state and Theme.txt or Theme.sub })
    Tween(SpamStroke, 0.16, { Color = state and Theme.acc or Theme.line, Transparency = state and 0.15 or 0.3 })

    if state then
        SpamCount = 0
        task.spawn(function()
            while IsSpamming and IsListening do
                if WordSpamMode then
                    task.wait(0.1)
                else
                    local current = Trim(CodeInput.Text)
                    if current ~= "" then
                        SpamCount += 1
                        RedeemCodeNow(current, ("spam %d"):format(SpamCount))
                    end
                    task.wait(SpamDelay + math.random() * 0.1)
                end
            end
        end)
    end
end

local function SetListening(state)
    IsListening = state
    if not state and IsSpamming then ToggleSpam(false) end
    Tween(ListenPill, 0.16, { BackgroundColor3 = state and Theme.acc or Theme.line })
    Tween(ListenKnob, 0.16, { Position = UDim2.new(0, state and 20 or 2, 0.5, -7) }, Enum.EasingStyle.Back)
    Tween(ListenLbl, 0.16, { TextColor3 = state and Theme.txt or Theme.sub })

    if state then
        CapturedTokens = {}
        if SpamOnListen and not IsSpamming then
            if LastTypedCode and CodeInput.Text == LastTypedCode then SetCodeBox("") end
            ToggleSpam(true)
        end
        if ManualMode then
            SetStatus("listening... (MANUAL)", "wait")
        else
            SetStatus(TargetWordCount == 0 and "listening... (AUTO length)" or ("listening... 0/%d"):format(TargetWordCount), "wait")
        end
    else
        SetStatus(KeyboardEnabled and ("ready - press " .. ListenKey.Name .. " to listen") or "ready - tap LISTEN to start", "idle")
    end
end

ListenHit.MouseButton1Click:Connect(function()
    if IsListening and ManualMode then
        local final = table.concat(CapturedTokens)
        SetListening(false)
        if final ~= "" then
            if AutoType then SetCodeBox(final) end
            if AutoRedeem then RedeemCodeNow(final, "[MANUAL]") end
        end
    else
        SetListening(not IsListening)
    end
end)

SpamStartBtn.MouseButton1Click:Connect(function() ToggleSpam(not IsSpamming) end)
RedeemBtn.MouseButton1Click:Connect(function() RedeemCodeNow(CodeInput.Text) end)
CopyBtn.MouseButton1Click:Connect(function()
    local c = Trim(CodeInput.Text)
    if c ~= "" and CopyToClipboard(c) then SetStatus("copied: " .. c, "ok") end
end)
ClearBtn.MouseButton1Click:Connect(function()
    CodeInput.Text = ""
    LastTypedCode = nil
    CapturedTokens = {}
    SetStatus("cleared", "idle")
end)

-- Announcement Processor
local SystemIgnoreList = {
    "sammy has activated bubblegum machine", "sammy activated", "coins shop",
    "brainrot trader", "robux shop", "spin wheel", "trade plaza",
    "event has started", "your base is already locked", "your base is full",
    "you locked your base", "broke into your base", "someone is stealing",
    "trade has been completed", "brainrot express"
}

local function ShouldIgnorePhrase(msg)
    if not IgnoreSystem or not IsListening then return false end
    local lower = StripRichText(tostring(msg or "")):lower()
    local cand = ExtractTriggerPayload(lower)
    if cand and cand ~= "" then return false end
    for _, phrase in ipairs(SystemIgnoreList) do
        if lower:find(phrase, 1, true) then return true end
    end
    return false
end

local function HandleAnnouncement(...)
    local args = table.pack(...)
    if args.n == 0 or typeof(args[1]) ~= "string" then return end

    local validPos = false
    if IgnoreSystem then
        validPos = args[4] == "Top"
    else
        for i = 2, args.n do
            local v = args[i]
            if typeof(v) == "string" and (v:find("Sounds%.") or v:find("rbxassetid") or Config.positions[v]) then
                validPos = true
                break
            end
        end
    end
    if not validPos then return end

    local cleanMsg = StripRichText(tostring(args[1] or ""))
    if cleanMsg == "" or ShouldIgnorePhrase(cleanMsg) then return end

    -- 1. Check if it's a Riddle & Solve with Gemini AI
    local dropType = _G.__SabClassifyDrop(cleanMsg)
    if dropType == "riddle" and AutoRiddleAI then
        SetStatus("riddle detected! asking Gemini AI...", "busy")
        AddFeedEntry(cleanMsg, nil)
        SolveRiddleWithGemini(cleanMsg, function(answer, fromCache, err)
            if answer then
                SetStatus((fromCache and "[AI-CACHE] " or "[GEMINI AI] ") .. answer, "ok")
                if AutoType then SetCodeBox(answer) end
                SyncGameTextBox(answer)
                if AutoRedeem then
                    RedeemCodeNow(answer, "[AI]")
                end
                AddFeedEntry("AI Solved: " .. cleanMsg, answer)
            else
                SetStatus("AI failed: " .. tostring(err), "err")
            end
        end)
        return
    end

    -- 2. Otherwise process as Code Drop
    local bestCand = ExtractBestCandidate(cleanMsg)
    local payload = cleanMsg

    if AutoListen and not IsListening then
        local extracted = ExtractTriggerPayload(cleanMsg)
        if extracted then
            SetListening(true)
            if extracted == "" then
                SetStatus("trigger heard - waiting for code...", "busy")
                AddFeedEntry(cleanMsg, bestCand)
                return
            end
            payload = extracted
        end
    end

    if IsListening then
        local tokens = Tokenize(payload)
        for _, tok in ipairs(tokens) do
            CapturedTokens[#CapturedTokens + 1] = tok
            if WordSpamMode and IsSpamming then
                RedeemCodeNow(table.concat(CapturedTokens), "word-spam")
            end
        end

        if ManualMode then
            local combined = table.concat(CapturedTokens)
            SetCodeBox(combined)
            SyncGameTextBox(combined)
            SetStatus(("listening... %d words"):format(#CapturedTokens), "wait")
        elseif TargetWordCount == 0 then
            -- AUTO Dynamic Length Detection: instantly process the exact tokens captured in this drop
            local combined = table.concat(CapturedTokens)
            if combined ~= "" then
                CapturedTokens = {}
                SetListening(false)
                if AutoType then SetCodeBox(combined) end
                SyncGameTextBox(combined)
                if AutoRedeem then
                    RedeemCodeNow(combined, "[AUTO]")
                else
                    SetStatus("captured: " .. combined, "ok")
                end
                bestCand = combined
            end
        else
            -- Fixed word count (1, 2, 3, or 4)
            local slice = {}
            for i = 1, math.min(#CapturedTokens, TargetWordCount) do
                slice[i] = CapturedTokens[i]
            end
            local combined = table.concat(slice)
            SetCodeBox(combined)
            SyncGameTextBox(combined)

            if #CapturedTokens >= TargetWordCount then
                CapturedTokens = {}
                SetListening(false)
                if AutoRedeem then
                    RedeemCodeNow(combined, "[FULL]")
                else
                    SetStatus("captured: " .. combined, "ok")
                end
                bestCand = combined
            else
                SetStatus(("listening... %d/%d"):format(#CapturedTokens, TargetWordCount), "wait")
            end
        end
    end

    AddFeedEntry(cleanMsg, bestCand)
end

-- Fake Notify Test Window
local TestWin, TestTop = CreateWindow("Test", 300, 178, "FAKE NOTIFY (TEST AI & CODES)")
TestWin.Visible = false
TestWin.Parent = ScreenGui
local TestClose = Btn("X", TestTop)
TestClose.Size = UDim2.fromOffset(22, 22)
TestClose.Position = UDim2.new(1, -28, 0.5, -11)
TestClose.TextSize = 12
TestClose.MouseButton1Click:Connect(function() TestWin.Visible = false end)

local TestBody = New("Frame", { Size = UDim2.new(1, -24, 1, -58), Position = UDim2.fromOffset(12, 50), BackgroundTransparency = 1 }, TestWin)
New("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, TestBody)

local TestInput = New("TextBox", {
    Size = UDim2.new(1, 0, 0, 36),
    BackgroundColor3 = Theme.input,
    Text = "",
    PlaceholderText = "type a fake code or riddle...",
    PlaceholderColor3 = Theme.sub,
    Font = FontBold,
    TextSize = 12,
    TextColor3 = Theme.txt,
    ClearTextOnFocus = false,
    BorderSizePixel = 0,
    LayoutOrder = 1,
}, TestBody)
Corner(TestInput, 7)

local TestRow = New("Frame", { Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1, LayoutOrder = 2 }, TestBody)
local TestRiddleBtn = Btn("TEST AI RIDDLE", TestRow)
TestRiddleBtn.Size = UDim2.new(0.48, -3, 1, 0)
local TestSendBtn = PrimaryBtn("SEND", TestRow)
TestSendBtn.Size = UDim2.new(0.52, -3, 1, 0)
TestSendBtn.Position = UDim2.new(0.48, 3, 0, 0)

TestSendBtn.MouseButton1Click:Connect(function()
    local msg = Trim(TestInput.Text)
    if msg ~= "" then
        HandleAnnouncement(msg, nil, nil, "Top", 2678001507)
        TestInput.Text = ""
    end
end)

TestRiddleBtn.MouseButton1Click:Connect(function()
    HandleAnnouncement("What is 15 + 27?", nil, nil, "Top", 2678001507)
end)

TestBtn.MouseButton1Click:Connect(function()
    if TestWin.Visible then TestWin.Visible = false return end
    if IsMobile then
        TestWin.Position = UDim2.new(0.5, -math.floor(TestWin.AbsoluteSize.X / 2), 0.5, -math.floor(TestWin.AbsoluteSize.Y / 2))
    else
        TestWin.Position = UDim2.new(Main.Position.X.Scale, Main.Position.X.Offset - TestWin.AbsoluteSize.X - 10, Main.Position.Y.Scale, Main.Position.Y.Offset + 120)
    end
    TestWin.Visible = true
end)

-- Remote Listener Setup
local Connections = {}
local LastPacketKey = nil
local LastPacketTime = 0

local function OnRemoteFired(...)
    local args = table.pack(...)
    local parts = table.create(args.n)
    for i = 1, args.n do parts[i] = tostring(args[i]) end
    local key = table.concat(parts, "\31")
    local now = os.clock()
    if key == LastPacketKey and (now - LastPacketTime) < 0.25 then return end
    LastPacketKey = key
    LastPacketTime = now
    pcall(HandleAnnouncement, table.unpack(args, 1, args.n))
end

NotifyRemote = FindNotificationRemote()
if NotifyRemote then
    ConnDot.BackgroundColor3 = Theme.ok
    FeedDot.BackgroundColor3 = Theme.ok
    Connections[#Connections + 1] = NotifyRemote.OnClientEvent:Connect(OnRemoteFired)
else
    local count = 0
    for _, child in ipairs(Net:GetChildren()) do
        if child:IsA("RemoteEvent") or child:IsA("UnreliableRemoteEvent") then
            count += 1
            Connections[#Connections + 1] = child.OnClientEvent:Connect(OnRemoteFired)
            if count >= 60 then break end
        end
    end
    FallbackListening = count > 0
    local c = FallbackListening and Theme.warn or Theme.err
    ConnDot.BackgroundColor3 = c
    FeedDot.BackgroundColor3 = c
end

-- Keybinds
LKeyBtn.MouseButton1Click:Connect(function() RebindingTarget = "listen"; LKeyBtn.Text = "..." end)
LKeyClear.MouseButton1Click:Connect(function() ListenKey = nil; LKeyBtn.Text = "-" end)
RKeyBtn.MouseButton1Click:Connect(function() RebindingTarget = "redeem"; RKeyBtn.Text = "..." end)
RKeyClear.MouseButton1Click:Connect(function() RedeemKey = nil; RKeyBtn.Text = "-" end)

UserInputService.InputBegan:Connect(function(inp, gp)
    if RebindingTarget then
        if inp.UserInputType == Enum.UserInputType.Keyboard then
            if RebindingTarget == "listen" then
                if inp.KeyCode ~= Enum.KeyCode.Escape then ListenKey = inp.KeyCode end
                LKeyBtn.Text = ListenKey and ListenKey.Name or "-"
            else
                if inp.KeyCode ~= Enum.KeyCode.Escape then RedeemKey = inp.KeyCode end
                RKeyBtn.Text = RedeemKey and RedeemKey.Name or "-"
            end
            RebindingTarget = nil
        end
        return
    end
    if gp then return end
    if ListenKey and inp.KeyCode == ListenKey then SetListening(not IsListening) end
    if RedeemKey and inp.KeyCode == RedeemKey then RedeemCodeNow(CodeInput.Text) end
end)

UpdateWordsVisibility(true)
UpdateKeybindsVisibility(true)
SetListening(false)

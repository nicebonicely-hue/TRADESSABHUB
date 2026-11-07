
--[[
    SAB FULL LOGGER v2
    Client-visible data collector
    Delta / Roblox
    SCAN + LIVE LOGGER + EXPORT
]]

if _G.SABFullLogger and _G.SABFullLogger.Destroy then
    pcall(_G.SABFullLogger.Destroy)
end

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer

local State = {
    Logs = {},
    Connections = {},
    Live = false,
    Destroyed = false,
    MaxLogs = 2500,
    Scale = 0.85,
    Report = ""
}

local function log(category, message)
    if #State.Logs >= State.MaxLogs then
        table.remove(State.Logs, 1)
    end

    local line = string.format(
        "[%s] [%s] %s",
        os.date("%H:%M:%S"),
        tostring(category),
        tostring(message)
    )

    table.insert(State.Logs, line)
end

local function connect(signal, callback)
    local ok, connection = pcall(function()
        return signal:Connect(callback)
    end)

    if ok and connection then
        table.insert(State.Connections, connection)
        return connection
    end
end

local function safePath(obj)
    local ok, result = pcall(function()
        return obj:GetFullName()
    end)

    return ok and result or obj.Name
end

local function safePosition(obj)
    local ok, result = pcall(function()
        if obj:IsA("BasePart") then
            return tostring(obj.Position)
        elseif obj:IsA("Model") then
            return tostring(obj:GetPivot().Position)
        end
    end)

    return ok and result or "N/A"
end

local function captureAttributes(obj)
    local ok, attributes = pcall(function()
        return obj:GetAttributes()
    end)

    if not ok then return end

    for name, value in pairs(attributes) do
        log("ATTRIBUTE", safePath(obj) ..
            " | " .. name .. " = " .. tostring(value))
    end
end

-- GUI

local gui = Instance.new("ScreenGui")
gui.Name = "SABFullLoggerV2"
gui.ResetOnSpawn = false

pcall(function()
    gui.Parent = gethui()
end)

if not gui.Parent then
    gui.Parent = game:GetService("CoreGui")
end

local main = Instance.new("Frame")
main.Size = UDim2.fromOffset(370, 470)
main.Position = UDim2.new(0.5, -185, 0.5, -235)
main.BackgroundColor3 = Color3.fromRGB(17, 20, 29)
main.BorderSizePixel = 0
main.Parent = gui

local scaler = Instance.new("UIScale")
scaler.Scale = State.Scale
scaler.Parent = main

local function corner(obj, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 7)
    c.Parent = obj
end

corner(main, 12)

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(70, 110, 190)
stroke.Thickness = 1.5
stroke.Parent = main

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 43)
header.BackgroundColor3 = Color3.fromRGB(29, 39, 60)
header.BorderSizePixel = 0
header.Parent = main

corner(header, 10)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -75, 1, 0)
title.Position = UDim2.fromOffset(12, 0)
title.BackgroundTransparency = 1
title.Text = "SAB | FULL LOGGER v2"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextSize = 14
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(30, 29)
close.Position = UDim2.new(1, -37, 0, 7)
close.BackgroundColor3 = Color3.fromRGB(165, 55, 65)
close.Text = "X"
close.TextColor3 = Color3.new(1, 1, 1)
close.Font = Enum.Font.GothamBold
close.Parent = header
corner(close)

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -20, 0, 25)
status.Position = UDim2.fromOffset(10, 47)
status.BackgroundTransparency = 1
status.Text = "Status: Ready"
status.TextColor3 = Color3.fromRGB(130, 220, 170)
status.TextSize = 12
status.Font = Enum.Font.Gotham
status.TextXAlignment = Enum.TextXAlignment.Left
status.Parent = main

local reportBox = Instance.new("TextBox")
reportBox.Size = UDim2.new(1, -20, 1, -165)
reportBox.Position = UDim2.fromOffset(10, 75)
reportBox.BackgroundColor3 = Color3.fromRGB(26, 31, 44)
reportBox.TextColor3 = Color3.fromRGB(210, 225, 250)
reportBox.PlaceholderText = "Captured information..."
reportBox.PlaceholderColor3 = Color3.fromRGB(120, 130, 150)
reportBox.Text = ""
reportBox.TextSize = 10
reportBox.Font = Enum.Font.Code
reportBox.TextXAlignment = Enum.TextXAlignment.Left
reportBox.TextYAlignment = Enum.TextYAlignment.Top
reportBox.TextWrapped = false
reportBox.MultiLine = true
reportBox.ClearTextOnFocus = false
reportBox.Parent = main
corner(reportBox)

local function setStatus(text)
    status.Text = "Status: " .. text
end

-- DRAG

local dragging = false
local dragStart
local startPosition

header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPosition = main.Position
    end
end)

connect(UIS.InputChanged, function(input)
    if dragging and (
        input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
    ) then
        local delta = input.Position - dragStart

        main.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end
end)

connect(UIS.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- BUTTON HELPER

local function button(text, x, y, w, callback, color)
    local b = Instance.new("TextButton")
    b.Size = UDim2.fromOffset(w, 32)
    b.Position = UDim2.new(x, 0, 1, y)
    b.AnchorPoint = Vector2.new(0, 0)
    b.BackgroundColor3 = color or Color3.fromRGB(48, 75, 125)
    b.Text = text
    b.TextColor3 = Color3.new(1, 1, 1)
    b.TextSize = 11
    b.Font = Enum.Font.GothamBold
    b.Parent = main

    corner(b, 6)
    b.MouseButton1Click:Connect(callback)

    return b
end

-- FULL SCAN

local function scan()
    log("SCAN", "========== NEW SCAN ==========")

    log("EXPERIENCE", "PlaceId: " .. game.PlaceId)
    log("EXPERIENCE", "UniverseId: " .. game.GameId)
    log("EXPERIENCE", "JobId: " .. game.JobId)
    log("EXPERIENCE", "Version: " .. game.PlaceVersion)

    log("PLAYER", "Username: " .. Player.Name)
    log("PLAYER", "DisplayName: " .. Player.DisplayName)
    log("PLAYER", "UserId: " .. Player.UserId)
    log("PLAYER", "AccountAge: " .. Player.AccountAge)

    local character = Player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")

    if root then
        log("PLAYER", "Position: " .. tostring(root.Position))
        log("PLAYER", "Velocity: " .. tostring(root.AssemblyLinearVelocity))
    end

    if humanoid then
        log("PLAYER", "Health: " .. humanoid.Health)
        log("PLAYER", "MaxHealth: " .. humanoid.MaxHealth)
        log("PLAYER", "WalkSpeed: " .. humanoid.WalkSpeed)
        log("PLAYER", "JumpPower: " .. humanoid.JumpPower)
        log("PLAYER", "State: " .. tostring(humanoid:GetState()))
    end

    log("PLAYERS", "Total: " .. #Players:GetPlayers())

    for _, plr in ipairs(Players:GetPlayers()) do
        log("PLAYER", plr.Name .. " | " ..
            plr.DisplayName .. " | " .. plr.UserId)

        local char = plr.Character
        local otherRoot = char and char:FindFirstChild("HumanoidRootPart")
        local otherHumanoid = char and char:FindFirstChildOfClass("Humanoid")

        if otherRoot then
            log("PLAYER", "Position: " .. tostring(otherRoot.Position))
        end

        if otherHumanoid then
            log("PLAYER", "Health: " .. otherHumanoid.Health)
        end
    end

    log("INVENTORY", "Backpack scan")

    local backpack = Player:FindFirstChildOfClass("Backpack")

    if backpack then
        for _, item in ipairs(backpack:GetChildren()) do
            log("INVENTORY", item.Name .. " | " .. item.ClassName)
        end
    end

    if character then
        for _, item in ipairs(character:GetChildren()) do
            if item:IsA("Tool") then
                log("INVENTORY", "Equipped: " .. item.Name)
            end
        end
    end

    log("REMOTES", "Visible Remote inventory")

    local function inspectRemotes(container)
        for _, obj in ipairs(container:GetDescendants()) do
            if obj:IsA("RemoteEvent")
            or obj:IsA("RemoteFunction")
            or obj:IsA("UnreliableRemoteEvent") then
                log("REMOTE", obj.ClassName .. " | " .. safePath(obj))
            end
        end
    end

    inspectRemotes(ReplicatedStorage)

    log("WORKSPACE", "Scanning descendants")

    local counts = {}
    local total = 0
    local models = 0
    local parts = 0
    local prompts = 0

    for _, obj in ipairs(Workspace:GetDescendants()) do
        total += 1
        counts[obj.ClassName] = (counts[obj.ClassName] or 0) + 1

        if obj:IsA("Model") then models += 1 end
        if obj:IsA("BasePart") then parts += 1 end
        if obj:IsA("ProximityPrompt") then prompts += 1 end
    end

    log("WORKSPACE", "Total: " .. total)
    log("WORKSPACE", "Models: " .. models)
    log("WORKSPACE", "Parts: " .. parts)
    log("WORKSPACE", "Prompts: " .. prompts)

    for class, count in pairs(counts) do
        log("CLASS", class .. ": " .. count)
    end

    log("SCAN", "========== SCAN COMPLETE ==========")

    setStatus("Scan complete | " .. #State.Logs .. " logs")
end

-- LIVE LOGGER

local function startLive()
    if State.Live then return end

    State.Live = true

    log("LIVE", "Live logging started")

    connect(Workspace.DescendantAdded, function(obj)
        log("ADDED", obj.ClassName .. " | " .. safePath(obj))

        if obj:IsA("RemoteEvent")
        or obj:IsA("RemoteFunction")
        or obj:IsA("UnreliableRemoteEvent") then
            log("REMOTE", "New remote visible: " .. safePath(obj))
        end
    end)

    connect(Workspace.DescendantRemoving, function(obj)
        log("REMOVED", obj.ClassName .. " | " .. safePath(obj))
    end)

    connect(ReplicatedStorage.DescendantAdded, function(obj)
        log("REPLICATED ADDED", obj.ClassName .. " | " .. safePath(obj))

        if obj:IsA("RemoteEvent")
        or obj:IsA("RemoteFunction")
        or obj:IsA("UnreliableRemoteEvent") then
            log("REMOTE", "New remote: " .. safePath(obj))
        end
    end)

    connect(ReplicatedStorage.DescendantRemoving, function(obj)
        log("REPLICATED REMOVED", obj.ClassName .. " | " .. safePath(obj))
    end)

    connect(Players.PlayerAdded, function(plr)
        log("PLAYER JOIN", plr.Name .. " | " .. plr.UserId)
    end)

    connect(Players.PlayerRemoving, function(plr)
        log("PLAYER LEFT", plr.Name .. " | " .. plr.UserId)
    end)

    connect(Player.CharacterAdded, function(char)
        log("CHARACTER", "Character added: " .. char.Name)
    end)

    connect(Player.CharacterRemoving, function(char)
        log("CHARACTER", "Character removing: " .. char.Name)
    end)

    setStatus("LIVE ON")
end

local function stopLive()
    State.Live = false

    for _, connection in ipairs(State.Connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    table.clear(State.Connections)

    log("LIVE", "Live logging stopped")
    setStatus("LIVE OFF")
end

-- REPORT

local function generateReport()
    local headerText = {
        "======================================",
        "SAB FULL LOGGER v2 - CLIENT REPORT",
        "======================================",
        "Generated: " .. os.date("%Y-%m-%d %H:%M:%S"),
        "Place ID: " .. tostring(game.PlaceId),
        "Universe ID: " .. tostring(game.GameId),
        "Job ID: " .. tostring(game.JobId),
        "Total log entries: " .. #State.Logs,
        "======================================",
        ""
    }

    local all = {}

    for _, line in ipairs(headerText) do
        table.insert(all, line)
    end

    for _, line in ipairs(State.Logs) do
        table.insert(all, line)
    end

    State.Report = table.concat(all, "\n")
    reportBox.Text = State.Report

    return State.Report
end

local function copyReport()
    local report = generateReport()

    local clipboard = setclipboard or toclipboard

    if type(clipboard) == "function" then
        local ok, err = pcall(clipboard, report)

        if ok then
            setStatus("Copied " .. #report .. " characters")
        else
            setStatus("Clipboard error: " .. tostring(err))
        end
    else
        setStatus("Clipboard unavailable")
    end
end

-- BUTTONS

button("SCAN", 10, -115, 105, function()
    scan()
    generateReport()
end, Color3.fromRGB(45, 105, 85))

button("LIVE ON", 123, -115, 105, startLive,
    Color3.fromRGB(45, 95, 145))

button("LIVE OFF", 236, -115, 105, stopLive,
    Color3.fromRGB(135, 75, 65))

button("COPY ALL", 10, -76, 160, copyReport,
    Color3.fromRGB(50, 100, 165))

button("REFRESH", 180, -76, 161, function()
    generateReport()
    setStatus("Report refreshed")
end)

button("A-", 10, -37, 45, function()
    State.Scale = math.max(0.60, State.Scale - 0.05)
    scaler.Scale = State.Scale
end)

button("A+", 65, -37, 45, function()
    State.Scale = math.min(1.20, State.Scale + 0.05)
    scaler.Scale = State.Scale
end)

button("CLEAR", 180, -37, 161, function()
    table.clear(State.Logs)
    State.Report = ""
    reportBox.Text = ""
    setStatus("Logs cleared")
end, Color3.fromRGB(110, 65, 65))

-- CLEANUP

local function destroy()
    if State.Destroyed then return end

    State.Destroyed = true
    stopLive()

    for _, connection in ipairs(State.Connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    gui:Destroy()
    _G.SABFullLogger = nil
end

close.MouseButton1Click:Connect(destroy)

_G.SABFullLogger = {
    Destroy = destroy,
    Scan = scan,
    Start = startLive,
    Stop = stopLive,
    Export = copyReport,
    GetReport = generateReport
}

scan()
generateReport()

setStatus("Ready | " .. #State.Logs .. " entries")

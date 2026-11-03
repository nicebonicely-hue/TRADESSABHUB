--[[ Steal a Brainrot | AutoBuy + Freeze | Delta ]]
-- Auto compra los brainrots que marques en la lista + freeze/inmortalidad
if _G.SAB then pcall(function() _G.SAB:Destroy() end) end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local lp = Players.LocalPlayer

local CFG = {
    delay     = 0.25,   -- pausa entre intentos de compra
    teleport  = true,   -- ir al pedestal y volver (recomendado)
    buyAll    = false,
    autoBuy   = false,
    freeze    = false,
    lockHP    = true,
    selected  = {},
}
local fired = {}
local baseCF = nil

-- ===== utilidades =====
local GENERIC = {
    Part=true, Model=true, Stand=true, Pedestal=true, Base=true,
    Prompt=true, ProximityPrompt=true, Buy=true, Spawn=true, Hitbox=true,
}

local function ancestorName(prompt)
    local part = prompt.Parent
    if not part then return nil end
    -- atributos de texto (algunos stands guardan el nombre ahí)
    for k, v in pairs(part:GetAttributes()) do
        if type(v) == "string" and #v > 2 and not GENERIC[v] then return v end
    end
    local ot = prompt.ObjectText
    if ot and #ot > 2 and not ot:match("^%$?%d") and not GENERIC[ot] then return ot end
    local node = part
    for _ = 1, 4 do
        if not node then break end
        if not GENERIC[node.Name] and #node.Name > 2 and not node.Name:match("^%$") then
            return node.Name
        end
        node = node.Parent
    end
    return part.Name
end

local function isBuyPrompt(p)
    local t = (p.ActionText .. " " .. p.ObjectText):lower()
    return t:find("buy") or t:find("comprar") or t:find("purchase")
end

local function scanPrompts()
    local out = {}
    for _, d in ipairs(workspace:GetDescendants()) do
        if d:IsA("ProximityPrompt") and isBuyPrompt(d) then
            local name = ancestorName(d)
            if name then out[#out + 1] = {prompt = d, name = name} end
        end
    end
    return out
end

local function toast(txt)
    if st then st.Text = txt end
    print("[SAB] " .. txt)
end

-- ===== freeze =====
local function applyFreeze()
    local char = lp.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hum then
        hum.WalkSpeed = 0
        hum.JumpPower = 0
        hum.JumpHeight = 0
        hum.AutoRotate = false
        hum.PlatformStand = true
        if CFG.lockHP then
            hum.MaxHealth = math.huge
            hum.Health = hum.MaxHealth
        end
    end
    if hrp and not hrp.Anchored then
        baseCF = hrp.CFrame
        hrp.Anchored = true
    end
end

local function clearFreeze()
    local char = lp.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then hrp.Anchored = false end
    if hum then
        hum.WalkSpeed = 16
        hum.JumpPower = 50
        hum.JumpHeight = 7.2
        hum.AutoRotate = true
        hum.PlatformStand = false
        hum.MaxHealth = 100
        hum.Health = 100
    end
end

lp.CharacterAdded:Connect(function()
    task.wait(1)
    if CFG.freeze then applyFreeze() end
end)

-- ===== compra =====
local function tryBuy(entry)
    local prompt = entry.prompt
    if not prompt or not prompt.Parent then return false end
    local now = os.clock()
    if fired[prompt] and now - fired[prompt] < 0.7 then return false end
    fired[prompt] = now

    pcall(function() prompt.HoldDuration = 0 end)
    local char = lp.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    if CFG.teleport then
        local tgt = prompt.Parent
        local pos = tgt.Position or (tgt.GetPivot and tgt:GetPivot().Position)
        if not pos then return false end
        local saved = hrp.CFrame
        hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
        task.wait(0.12)
        pcall(fireproximityprompt, prompt)
        task.wait(0.07)
        hrp.CFrame = saved
    else
        pcall(fireproximityprompt, prompt)
    end
    return true
end

-- ===== GUI =====
local parent = (gethui and gethui()) or game:GetService("CoreGui")
local gui = Instance.new("ScreenGui")
gui.Name = "SAB_Hub"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = parent
_G.SAB = gui

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 260, 0, 400)
main.Position = UDim2.new(0, 20, 0, 80)
main.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 8)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
title.BorderSizePixel = 0
title.Text = "SAB | AutoBuy + Freeze"
title.TextColor3 = Color3.fromRGB(235, 235, 245)
title.Font = Enum.Font.GothamBold
title.TextSize = 13
title.Parent = main
Instance.new("UICorner", title).CornerRadius = UDim.new(0, 8)

local close = Instance.new("TextButton")
close.Size = UDim2.new(0, 30, 0, 30)
close.Position = UDim2.new(1, -32, 0, 0)
close.BackgroundTransparency = 1
close.Text = "X"
close.TextColor3 = Color3.fromRGB(255, 90, 90)
close.Font = Enum.Font.GothamBold
close.TextSize = 14
close.Parent = main
close.MouseButton1Click:Connect(function() gui:Destroy() end)

local function mkButton(txt, y, color, cb)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -20, 0, 28)
    b.Position = UDim2.new(0, 10, 0, y)
    b.BackgroundColor3 = color
    b.BorderSizePixel = 0
    b.Text = txt
    b.TextColor3 = Color3.fromRGB(240, 240, 245)
    b.Font = Enum.Font.GothamSemibold
    b.TextSize = 12
    b.Parent = main
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    b.MouseButton1Click:Connect(cb)
    return b
end

local st = Instance.new("TextLabel")
st.Size = UDim2.new(1, -20, 0, 16)
st.Position = UDim2.new(0, 10, 0, 34)
st.BackgroundTransparency = 1
st.Text = "listo"
st.TextColor3 = Color3.fromRGB(140, 200, 140)
st.Font = Enum.Font.Gotham
st.TextSize = 11
st.TextXAlignment = Enum.TextXAlignment.Left
st.Parent = main

local btnBuy = mkButton("AutoBuy: OFF", 54, Color3.fromRGB(60, 60, 70), function()
    CFG.autoBuy = not CFG.autoBuy
    btnBuy.Text = "AutoBuy: " .. (CFG.autoBuy and "ON" or "OFF")
    btnBuy.BackgroundColor3 = CFG.autoBuy and Color3.fromRGB(35, 130, 70) or Color3.fromRGB(60, 60, 70)
    toast(CFG.autoBuy and "AutoBuy activado" or "AutoBuy apagado")
end)

local btnFreeze = mkButton("Freeze: OFF", 88, Color3.fromRGB(60, 60, 70), function()
    CFG.freeze = not CFG.freeze
    btnFreeze.Text = "Freeze: " .. (CFG.freeze and "ON" or "OFF")
    btnFreeze.BackgroundColor3 = CFG.freeze and Color3.fromRGB(35, 110, 150) or Color3.fromRGB(60, 60, 70)
    if CFG.freeze then applyFreeze() else clearFreeze() end
    toast(CFG.freeze and "Personaje congelado" or "Personaje liberado")
end)

local btnTp = mkButton("Teletransporte al comprar: ON", 122, Color3.fromRGB(60, 60, 70), function()
    CFG.teleport = not CFG.teleport
    btnTp.Text = "Teletransporte al comprar: " .. (CFG.teleport and "ON" or "OFF")
    toast("teletransporte " .. (CFG.teleport and "activado" or "desactivado"))
end)

local btnAll = mkButton("Comprar TODO (ignorar lista): OFF", 156, Color3.fromRGB(60, 60, 70), function()
    CFG.buyAll = not CFG.buyAll
    btnAll.Text = "Comprar TODO (ignorar lista): " .. (CFG.buyAll and "ON" or "OFF")
end)

local search = Instance.new("TextBox")
search.Size = UDim2.new(1, -20, 0, 26)
search.Position = UDim2.new(0, 10, 0, 190)
search.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
search.BorderSizePixel = 0
search.PlaceholderText = "buscar brainrot..."
search.Text = ""
search.TextColor3 = Color3.fromRGB(230, 230, 235)
search.Font = Enum.Font.Gotham
search.TextSize = 12
search.Parent = main
Instance.new("UICorner", search).CornerRadius = UDim.new(0, 6)

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -20, 1, -226)
scroll.Position = UDim2.new(0, 10, 0, 220)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 4
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.Parent = main

local list = Instance.new("UIListLayout")
list.Padding = UDim.new(0, 3)
list.SortOrder = Enum.SortOrder.LayoutOrder
list.Parent = scroll

local function refreshList()
    for _, c in ipairs(scroll:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end
    local seen, y = {}, 0
    local q = search.Text:lower()
    for _, e in ipairs(scanPrompts()) do
        if not seen[e.name] and (q == "" or e.name:lower():find(q, 1, true)) then
            seen[e.name] = true
            local b = Instance.new("TextButton")
            b.Size = UDim2.new(1, 0, 0, 26)
            b.BackgroundColor3 = CFG.selected[e.name] and Color3.fromRGB(35, 110, 70) or Color3.fromRGB(32, 32, 40)
            b.BorderSizePixel = 0
            b.Text = (CFG.selected[e.name] and "[x] " or "[ ] ") .. e.name
            b.TextColor3 = Color3.fromRGB(225, 225, 235)
            b.Font = Enum.Font.Gotham
            b.TextSize = 11
            b.TextXAlignment = Enum.TextXAlignment.Left
            b.LayoutOrder = y
            b.Parent = scroll
            Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)
            b.MouseButton1Click:Connect(function()
                CFG.selected[e.name] = not CFG.selected[e.name]
                if not CFG.selected[e.name] then CFG.selected[e.name] = nil end
                refreshList()
            end)
            y = y + 1
        end
    end
    scroll.CanvasSize = UDim2.new(0, 0, 0, y * 29)
end

search:GetPropertyChangedSignal("Text"):Connect(refreshList)
task.spawn(function()
    while gui.Parent do
        task.wait(1.2)
        pcall(refreshList)
    end
end)

-- ===== loops =====
task.spawn(function()
    while gui.Parent do
        task.wait(CFG.delay)
        if CFG.autoBuy then
            for _, e in ipairs(scanPrompts()) do
                if CFG.buyAll or CFG.selected[e.name] then
                    if tryBuy(e) then break end
                end
            end
        end
    end
end)

task.spawn(function()
    while gui.Parent do
        task.wait(0.15)
        if CFG.freeze then pcall(applyFreeze) end
    end
end)

pcall(refreshList)
toast("cargado - marca brainrots en la lista")

--[[
===============================================================================
  SAB MACHINE INSERTER 路 v2  路  Delta / Luau
  Fusi贸n de: openoldmachinessab (detecci贸n de m谩quinas + disparo de prompts)
             teleportsabxyz (detecci贸n de zonas de recolecci贸n)
  A帽ade: insertar el brainrot en manos en la m谩quina que elijas.
===============================================================================
]]
if _G.SAB_MI then pcall(function() _G.SAB_MI.Cleanup() end) end

local Players, Workspace = game:GetService("Players"), game:GetService("Workspace")
local RS, CoreGui = game:GetService("ReplicatedStorage"), game:GetService("CoreGui")
local UIS = game:GetService("UserInputService")

local LP = Players.LocalPlayer
while not LP do task.wait(0.1); LP = Players.LocalPlayer end
local PG = LP:WaitForChild("PlayerGui", 15)
local HUI = (gethui and gethui()) or CoreGui or PG

local F = {}                       -- declarado PRIMERO
local alive = true
local C = {}
local function T(c) C[#C+1] = c; return c end

local function Log(t, c)
    if not F.log then return end
    local l = Instance.new("TextLabel")
    l.Parent = F.log
    l.BackgroundTransparency = 1
    l.Size = UDim2.new(1, 0, 0, 13)
    l.Font = Enum.Font.Code
    l.TextSize = 8
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextTruncated = true
    l.Text = t
    l.TextColor3 = c or Color3.fromRGB(190, 180, 220)
end
local function OK(t) Log("鉁� " .. t, Color3.fromRGB(90, 210, 140)) end
local function BAD(t) Log("脳 " .. t, Color3.fromRGB(235, 120, 120)) end
local function INFO(t) Log("路 " .. t, Color3.fromRGB(150, 180, 240)) end

--==============================================================================
-- LISTAS (de teleportsabxyz)
--==============================================================================
local POS = {"collect","collection","pickup","pick up","craftpad","craft pad","output","claim",
             "recoger","recoleccion","recolecci贸n","ingredient","submit","dropoff","drop off","zone","zona"}
local NEG = {"open","abrir","buy","comprar","interact","trade","duel"}

local function has(t, list)
    t = string.lower(tostring(t or ""))
    for _, w in ipairs(list) do if string.find(t, w, 1, true) then return true end end
    return false
end

--==============================================================================
-- CAT脕LOGO (de openoldmachines)
--==============================================================================
local CATALOG = {
    {"Fusi贸n / Bruja", "Witch / Haunted Fuse", {"witchcauldron","hauntedfuse","witchmachine","cauldron","spookyfuse","witch","bruja","caldera"}},
    {"Fusi贸n",         "Fuse Machine",        {"fusemachine","fusionmachine","fusestation","merger","combinemachine","fuse","fusion"}},
    {"Fabricaci贸n",    "Craft Machine",       {"craftingmachine","craftmachine","crafter","craftstation","recipemachine","workbench","crafting","fabricacion"}},
    {"Mutaci贸n",       "Rainbow Machine",     {"rainbowmachine","rainbowstation","rainbowizer","rainbowmaker"}},
    {"Mutaci贸n",       "Mutation / Trait",    {"mutationmachine","mutator","traitmachine","rerollmachine","upgrademachine"}},
    {"Evento",         "Event Station",       {"eclipsemachine","crystalmachine","cybermachine","candymachine","galaxymachine","lavamachine","bloodrotmachine","divinemachine","cursedmachine","phantommachine","yinyangmachine"}},
    {"Especial",       "Bubblegum / Gacha",   {"bubblegummachine","bubblegum","gumballmachine","gachamachine","vendingmachine","dispenser","clawmachine"}},
    {"Evento",         "Lucky / Wheel / Altar",{"luckyblockmachine","skullmachine","spinwheel","eventwheel","altar","shrine","ritualmachine","gravehunt","timemachine","portalmachine"}},
}
local TOKENS = {"machine","maquina","cauldron","crafter","station","altar","dispenser","incubator","reactor",
                "fuse","fusion","craft","rainbow","bubblegum","shovel","grave","skull","rng","duel","trade"}
local EXCL = {baseplate=true, terrain=true, camera=true, humanoidrootpart=true, head=true, torso=true}
local GENERIC = {map=true, machines=true, models=true, assets=true, events=true, world=true, workspace=true}

local function norm(s) return tostring(s or ""):lower():gsub("[%s_%-%p]+", "") end

--==============================================================================
-- UTILIDADES
--==============================================================================
local function HRP() local ch = LP.Character; return ch and ch:FindFirstChild("HumanoidRootPart") end
local function PartOf(o)
    if not o then return nil end
    if o:IsA("BasePart") then return o end
    return o:FindFirstChildWhichIsA("BasePart", true)
end
local function PosOf(o)
    if not o then return nil end
    if o:IsA("BasePart") then return o.Position end
    if o:IsA("Attachment") then return o.WorldPosition end
    if o:IsA("Model") then
        local ok, p = pcall(function() return o:GetPivot().Position end)
        if ok and p then return p end
    end
    return nil
end
local function Dist(p)
    local h = HRP()
    if not h or not p then return math.huge end
    return (h.Position - p).Magnitude
end
local function Live(r) return r and r.obj and r.obj.Parent end

local function Carried()
    local ch = LP.Character
    if not ch then return nil end
    for _, v in ipairs(ch:GetChildren()) do
        if v:IsA("Tool") then return v end
        if v:IsA("Model") and v ~= ch and v:FindFirstChildWhichIsA("BasePart", true) then return v end
    end
    for _, d in ipairs(ch:GetDescendants()) do
        if d:IsA("Weld") or d:IsA("Motor6D") then
            local p = d.Part1
            if p then
                local m = p:FindFirstAncestorWhichIsA("Model")
                if m and m ~= ch then return m end
            end
        end
    end
    return nil
end

local function RootOf(i)
    local cur, best = i, i
    for _ = 1, 6 do
        if not cur or cur == Workspace or cur == RS then break end
        if (cur:IsA("Model") or cur:IsA("Folder")) and not GENERIC[cur.Name:lower()] then best = cur end
        cur = cur.Parent
    end
    return best
end

--==============================================================================
-- DISPAROS
--==============================================================================
local function Touch(a, b)
    if not firetouchinterest or not a or not b then return false end
    pcall(function() firetouchinterest(a, b, 0) end)
    task.wait(0.12)
    pcall(function() firetouchinterest(a, b, 1) end)
    return true
end

local function FirePrompt(obj)
    local p = obj
    if p and not p:IsA("ProximityPrompt") then
        p = p:FindFirstChildWhichIsA("ProximityPrompt", true)
    end
    if not p or not p:IsA("ProximityPrompt") then return false end
    pcall(function()
        if not p.Enabled then p.Enabled = true end
        p.HoldDuration = 0
        p.MaxActivationDistance = 200
    end)
    local ok = pcall(function() fireproximityprompt(p, 0) end)
    if not ok then ok = pcall(function() fireproximityprompt(p) end) end
    return ok
end

local function FireClick(obj)
    local cd = obj
    if cd and not cd:IsA("ClickDetector") then cd = obj:FindFirstChildWhichIsA("ClickDetector", true) end
    if not cd or not cd:IsA("ClickDetector") or not fireclickdetector then return false end
    return pcall(function() fireclickdetector(cd) end)
end

local DEP_V = {"deposit","insert","place","submit","collect","add","put","dropoff"}
local CONF_V = {"confirm","cash","pay","fuse","start","open"}
local GRAB_V = {"grab","pick","pickup","carry","hold","equip","take"}

local function Remotes(vlist)
    local out = {}
    local ok, list = pcall(function() return RS:GetDescendants() end)
    if not ok then return out end
    for _, v in ipairs(list) do
        if v:IsA("RemoteEvent") then
            local n = v.Name:lower()
            for _, w in ipairs(vlist) do
                if n:find(w, 1, true) then out[#out+1] = v; break end
            end
        end
    end
    return out
end
local function FireRemotes(vlist, args, label)
    local rems = Remotes(vlist)
    if #rems == 0 then return end
    INFO(#rems .. " remotes " .. label)
    for _, r in ipairs(rems) do
        if not alive then break end
        for _, a in ipairs(args) do pcall(function() r:FireServer(a) end) end
        task.wait(0.04)
    end
end

--==============================================================================
-- UI
--==============================================================================
local function Btn(p, t, col, cb)
    local b = Instance.new("TextButton")
    b.Parent = p; b.BackgroundColor3 = col; b.BorderSizePixel = 0
    b.Font = Enum.Font.GothamBold; b.Text = t; b.TextColor3 = Color3.new(1,1,1); b.TextSize = 8
    local k = Instance.new("UICorner"); k.CornerRadius = UDim.new(0, 4); k.Parent = b
    if cb then T(b.MouseButton1Click:Connect(cb)) end
    return b
end
local function Lbl(p, t, sz, col, bold)
    local l = Instance.new("TextLabel")
    l.Parent = p; l.BackgroundTransparency = 1; l.Size = sz
    l.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
    l.Text = t; l.TextColor3 = col or Color3.fromRGB(190,175,225); l.TextSize = 9
    l.TextXAlignment = Enum.TextXAlignment.Left
    return l
end

if HUI:FindFirstChild("SAB_MI") then HUI.SAB_MI:Destroy() end
local Root = Instance.new("ScreenGui")
Root.Name = "SAB_MI"; Root.ResetOnSpawn = false; Root.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
local okp = pcall(function() Root.Parent = HUI end); if not okp then Root.Parent = PG end
F.root = Root

local Main = Instance.new("Frame")
Main.Parent = Root; Main.BackgroundColor3 = Color3.fromRGB(15,12,25)
Main.BorderColor3 = Color3.fromRGB(115,60,210); Main.BorderSizePixel = 1
Main.AnchorPoint = Vector2.new(0.5,0.5); Main.Position = UDim2.new(0.5,0,0.5,0)
Main.Size = UDim2.new(0,460,0,392); Main.ClipsDescendants = true
local mk = Instance.new("UICorner"); mk.CornerRadius = UDim.new(0,8); mk.Parent = Main

local Head = Instance.new("Frame")
Head.Parent = Main; Head.BackgroundColor3 = Color3.fromRGB(25,19,42); Head.BorderSizePixel = 0
Head.Size = UDim2.new(1,0,0,26)
local hk = Instance.new("UICorner"); hk.CornerRadius = UDim.new(0,8); hk.Parent = Head
local Ttl = Lbl(Head, "SAB MACHINE INSERTER", UDim2.new(0,300,1,0), Color3.fromRGB(215,175,255), true)
Ttl.Position = UDim2.new(0,10,0,0); Ttl.TextSize = 10
local ClsB = Btn(Head, "X", Color3.fromRGB(190,50,50), nil)
ClsB.Position = UDim2.new(1,-24,0,4); ClsB.Size = UDim2.new(0,17,0,17)

local Tabs = Instance.new("Frame")
Tabs.Parent = Main; Tabs.BackgroundColor3 = Color3.fromRGB(20,15,34); Tabs.BorderSizePixel = 0
Tabs.Position = UDim2.new(0,0,0,26); Tabs.Size = UDim2.new(1,0,0,20)
local tl = Instance.new("UIListLayout"); tl.Parent = Tabs; tl.FillDirection = Enum.FillDirection.Horizontal

local Views = Instance.new("Frame")
Views.Parent = Main; Views.BackgroundTransparency = 1
Views.Position = UDim2.new(0,0,0,46); Views.Size = UDim2.new(1,0,1,-72)

local Foot = Instance.new("Frame")
Foot.Parent = Main; Foot.BackgroundColor3 = Color3.fromRGB(20,15,32); Foot.BorderSizePixel = 0
Foot.Position = UDim2.new(0,0,1,-26); Foot.Size = UDim2.new(1,0,0,26)
local Hnd = Lbl(Foot, "en manos: nada", UDim2.new(0,300,1,0), Color3.fromRGB(235,140,140), true)
Hnd.Position = UDim2.new(0,8,0,0)

local function View()
    local v = Instance.new("ScrollingFrame")
    v.Parent = Views; v.BackgroundTransparency = 1; v.Size = UDim2.new(1,0,1,0)
    v.BorderSizePixel = 0; v.ScrollBarThickness = 4; v.CanvasSize = UDim2.new(0,0,0,0); v.Visible = false
    local l = Instance.new("UIListLayout"); l.Parent = v; l.Padding = UDim.new(0,3)
    local p = Instance.new("UIPadding"); p.Parent = v
    p.PaddingTop = UDim.new(0,5); p.PaddingLeft = UDim.new(0,6); p.PaddingRight = UDim.new(0,6)
    return v
end
local VM, VZ, VLog = View(), View(), View()

local tb = {}
local function Tab(txt, v)
    local b = Btn(Tabs, txt, Color3.fromRGB(20,15,34), function()
        for _, x in ipairs({VM,VZ,VLog}) do x.Visible = false end
        v.Visible = true
        for _, o in ipairs(tb) do o.BackgroundColor3 = Color3.fromRGB(20,15,34); o.TextColor3 = Color3.fromRGB(175,155,215) end
        b.BackgroundColor3 = Color3.fromRGB(85,45,165); b.TextColor3 = Color3.new(1,1,1)
    end)
    b.Size = UDim2.new(0,110,1,0); b.TextColor3 = Color3.fromRGB(175,155,215)
    tb[#tb+1] = b
end
Tab("M脕QUINAS", VM); Tab("ZONAS", VZ); Tab("LOG", VLog)
VM.Visible = true; tb[1].BackgroundColor3 = Color3.fromRGB(85,45,165); tb[1].TextColor3 = Color3.new(1,1,1)

-- barra de acciones
local Bar = Instance.new("Frame")
Bar.Parent = Views; Bar.BackgroundTransparency = 1
Bar.Position = UDim2.new(0,0,1,-26); Bar.Size = UDim2.new(1,0,0,24)
local bl = Instance.new("UIListLayout"); bl.Parent = Bar
bl.FillDirection = Enum.FillDirection.Horizontal; bl.Padding = UDim.new(0,4)
local bp = Instance.new("UIPadding"); bp.Parent = Bar
bp.PaddingLeft = UDim.new(0,6); bp.PaddingRight = UDim.new(0,6)

Views.Size = UDim2.new(1,0,1,-98)
Bar.Position = UDim2.new(0,0,0,0)
Views.Position = UDim2.new(0,0,0,46)
Views.Size = UDim2.new(1,0,1,-98)

-- log
F.log = Instance.new("ScrollingFrame")
F.log.Parent = VLog; F.log.BackgroundTransparency = 1
F.log.Size = UDim2.new(1,0,1,0); F.log.BorderSizePixel = 0
F.log.ScrollBarThickness = 3; F.log.CanvasSize = UDim2.new(0,0,0,0)
local lgl = Instance.new("UIListLayout"); lgl.Parent = F.log; lgl.Padding = UDim.new(0,1)
local lgp = Instance.new("UIPadding"); lgp.Parent = F.log
lgp.PaddingLeft = UDim.new(0,4)
T(lgl:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    F.log.CanvasSize = UDim2.new(0,0,0, lgl.AbsoluteContentSize.Y + 6)
end))

-- reubicar barra dentro de Views
local Bar2 = Instance.new("Frame")
Bar2.Parent = Views; Bar2.BackgroundTransparency = 1
Bar2.Position = UDim2.new(0,0,0,0); Bar2.Size = UDim2.new(1,0,0,22)
local b2l = Instance.new("UIListLayout"); b2l.Parent = Bar2
b2l.FillDirection = Enum.FillDirection.Horizontal; b2l.Padding = UDim.new(0,4)
local b2p = Instance.new("UIPadding"); b2p.Parent = Bar2
b2p.PaddingLeft = UDim.new(0,6); b2p.PaddingRight = UDim.new(0,6)

local function ToolBtn(t, col, cb, w)
    local b = Btn(Bar2, t, col, cb)
    b.Size = UDim2.new(w or 0.24, -3, 1, 0)
    return b
end

--==============================================================================
-- L脫GICA
--==============================================================================
local machines, zones = {}, {}
local selMachine = nil
local origin = nil
local useRemotes = false

local RefreshMachines, RefreshZones, ScanMachines, ScanZones, InsertInto, GoTo

local function ZonesOf(root)
    local out = {}
    local ok, list = pcall(function() return root:GetDescendants() end)
    if ok then
        for _, d in ipairs(list) do
            if d:IsA("BasePart") and has(d.Name, POS) then out[#out+1] = d end
        end
    end
    if #out == 0 then
        local p = root:IsA("BasePart") and root or root:FindFirstChildWhichIsA("BasePart", true)
        if p then out[1] = p end
    end
    return out
end

InsertInto = function(rec, teleport)
    local br = Carried()
    if not br then BAD("no llevas brainrot"); return end
    local bpart = PartOf(br)
    if not bpart then BAD("brainrot sin parte"); return end
    local target = rec.obj
    if not target or not target.Parent then BAD("objeto ya no existe"); return end

    INFO("brainrot: " .. br.Name)
    local zs = ZonesOf(target)
    INFO("zonas derivadas: " .. #zs)

    if teleport then
        local h = HRP()
        local p = PosOf(zs[1] or target)
        if h and p then
            if not origin then origin = h.CFrame end
            h.CFrame = CFrame.new(p + Vector3.new(0, 2, 0))
            h.AssemblyLinearVelocity = Vector3.zero
            task.wait(0.07)
        end
    end

    for _, z in ipairs(zs) do
        if Touch(bpart, z) then OK("contacto en " .. z.Name) end
        if FirePrompt(z) then OK("prompt en " .. z.Name) end
        if FireClick(z) then OK("clickdetector en " .. z.Name) end
        task.wait(0.08)
    end
    if FirePrompt(target) then OK("prompt en la m谩quina") end
    if FireClick(target) then OK("clickdetector en la m谩quina") end

    if useRemotes then
        task.wait(0.1)
        FireRemotes(DEP_V, {br, br.Name, bpart}, "dep贸sito")
        task.wait(0.1)
        FireRemotes(CONF_V, {br, br.Name}, "confirmaci贸n")
    end

    if teleport and not Carried() then
        BAD("carry roto, reintentando grab")
        FireRemotes(GRAB_V, {br, br.Name}, "grab")
    end
end

local function Row(parent, rec, isZone)
    local f = Instance.new("Frame")
    f.Parent = parent; f.BackgroundColor3 = Color3.fromRGB(22,18,37)
    f.BorderColor3 = Color3.fromRGB(58,38,96); f.BorderSizePixel = 1; f.Size = UDim2.new(1,0,0,30)
    local k = Instance.new("UICorner"); k.CornerRadius = UDim.new(0,4); k.Parent = f

    local d = Dist(rec.pos)
    local sub = isZone and "zona" or (rec.cat or "m谩quina")
    local n = Lbl(f, rec.name, UDim2.new(1,-134,0,14), Color3.fromRGB(235,225,255), true)
    n.Position = UDim2.new(0,6,0,3); n.TextTruncate = Enum.TextTruncate.AtEnd
    local m = Lbl(f, string.format("%s 路 %s", sub, d == math.huge and "鈥�" or string.format("%.0fm", d)),
        UDim2.new(1,-134,0,12), Color3.fromRGB(150,140,190))
    m.Position = UDim2.new(0,6,0,16); m.TextSize = 8

    local g = Btn(f, "IR", Color3.fromRGB(85,45,165), function()
        if not rec.obj or not rec.obj.Parent then BAD("ya no existe"); return end
        local h = HRP(); local p = rec.pos
        if h and p then
            if not origin then origin = h.CFrame end
            h.CFrame = CFrame.new(p + Vector3.new(0, 3, 3))
            INFO("TP a " .. rec.name)
        end
    end)
    g.Position = UDim2.new(1,-128,0,5); g.Size = UDim2.new(0,36,0,20)

    local i = Btn(f, "TOUCH", Color3.fromRGB(40,130,85), function() InsertInto(rec, false) end)
    i.Position = UDim2.new(1,-90,0,5); i.Size = UDim2.new(0,44,0,20)

    local t = Btn(f, "TP+", Color3.fromRGB(40,110,160), function() InsertInto(rec, true) end)
    t.Position = UDim2.new(1,-44,0,5); t.Size = UDim2.new(0,38,0,20)
    return f
end

local function Fill(view, list, emptyTxt)
    for _, ch in ipairs(view:GetChildren()) do
         if ch:IsA("Frame") or ch:IsA("TextLabel") then ch:Destroy() end
    end
    local n = 0
    for _, rec in ipairs(list) do
        if n >= 200 then break end
        if rec.obj and rec.obj.Parent then
            Row(view, rec, rec.isZone)
            n = n + 1
        end
    end
    if n == 0 then
        Lbl(view, emptyTxt, UDim2.new(1,0,0,26), Color3.fromRGB(235,140,140)).TextWrapped = true
    end
    local y = 0
    for _, ch in ipairs(view:GetChildren()) do
        if ch:IsA("Frame") or ch:IsA("TextLabel") then y = y + ch.Size.Y.Offset + 3 end
    end
    view.CanvasSize = UDim2.new(0,0,0,y+8)
end

RefreshMachines = function() Fill(VM, machines, "Sin m谩quinas. Pulsa ESCANEAR.") end
RefreshZones = function() Fill(VZ, zones, "Sin zonas. Ac茅rcate a la m谩quina y pulsa ESCANEAR.") end

ScanMachines = function()
    BAD("escaneando m谩quinas鈥�")
    task.spawn(function()
        local out, seen = {}, {}
        local ok, list = pcall(function() return Workspace:GetDescendants() end)
        if not ok then return end
        local i = 1
        while i <= #list do
            if not alive then return end
            local stop = math.min(i + 400, #list)
            for j = i, stop do
                local o = list[j]
                local nm = norm(o.Name)
                local hit = false
                for _, cat in ipairs(CATALOG) do
                    for _, kw in ipairs(cat[3]) do
                        if nm:find(kw, 1, true) then hit = true; break end
                    end
                    if hit then break end
                end
                if not hit then
                    for _, tk in ipairs(TOKENS) do
                        if nm:find(tk, 1, true) then hit = true; break end
                    end
                end
                if hit and not EXCL[o.Name:lower()] then
                    local r = RootOf(o)
                    if r and not seen[r] then
                        seen[r] = true
                        local p = PosOf(r)
                        if p then
                            out[#out+1] = { obj = r, pos = p, name = r.Name, cat = "m谩quina" }
                        end
                    end
                end
            end
            i = stop + 1
            task.wait()
        end
        table.sort(out, function(a, b) return Dist(a.pos) < Dist(b.pos) end)
        machines = out
        OK(#out .. " m谩quinas")
        RefreshMachines()
    end)
end

ScanZones = function()
    INFO("escaneando zonas鈥�")
    task.spawn(function()
        local out = {}
        local ok, list = pcall(function() return Workspace:GetDescendants() end)
        if not ok then return end
        local i = 1
        while i <= #list do
            if not alive then return end
            local stop = math.min(i + 400, #list)
            for j = i, stop do
                local o = list[j]
                local txt, p
                if o:IsA("BasePart") or o:IsA("Attachment") then
                    txt = o.Name
                    p = PosOf(o)
                elseif o:IsA("ProximityPrompt") then
                    txt = o.Name .. " " .. (o.ActionText or "") .. " " .. (o.ObjectText or "")
                    p = PosOf(o.Parent)
                end
                if txt and p and has(txt, POS) and not has(txt, NEG) then
                    out[#out+1] = { obj = o, pos = p, name = o.Name, isZone = true }
                end
            end
            i = stop + 1
            task.wait()
        end
        table.sort(out, function(a, b) return Dist(a.pos) < Dist(b.pos) end)
        zones = out
        OK(#out .. " zonas")
        RefreshZones()
    end)
end

--==============================================================================
-- BARRA Y WIRING
--==============================================================================
ToolBtn("ESCANEAR", Color3.fromRGB(85,45,165), function()
    ScanMachines(); task.wait(0.2); ScanZones()
end, 0.24)

ToolBtn("MANOS", Color3.fromRGB(55,55,90), function()
    local br = Carried()
    if br then
        Hnd.Text = "en manos: " .. br.Name
        Hnd.TextColor3 = Color3.fromRGB(90,210,140)
        OK("llevas: " .. br.Name)
    else
        Hnd.Text = "en manos: nada"
        Hnd.TextColor3 = Color3.fromRGB(235,140,140)
        BAD("no llevas nada")
    end
end, 0.18)

ToolBtn("REGRESAR", Color3.fromRGB(120,70,70), function()
    local h = HRP()
    if h and origin then
        h.CFrame = origin; origin = nil; OK("regresado")
    else BAD("sin origen guardado") end
end, 0.2)

local RemB = ToolBtn("REM OFF", Color3.fromRGB(70,50,130), function()
    useRemotes = not useRemotes
    RemB.Text = useRemotes and "REM ON" or "REM OFF"
    RemB.BackgroundColor3 = useRemotes and Color3.fromRGB(70,50,130) or Color3.fromRGB(45,45,75)
end, 0.18)

ToolBtn("LIMPIAR", Color3.fromRGB(60,60,95), function()
    machines = {}; zones = {}; RefreshMachines(); RefreshZones(); OK("listas limpias")
end, 0.18)

-- rat贸n
local drag, ds, sp0
T(Head.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        drag = true; ds = i.Position; sp0 = Main.Position
    end
end))
T(UIS.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag = false end
end))
T(UIS.InputChanged:Connect(function(i)
    if not drag then return end
    if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
        local d = i.Position - ds
        Main.Position = UDim2.new(sp0.X.Scale, sp0.X.Offset + d.X, sp0.Y.Scale, sp0.Y.Offset + d.Y)
    end
end))

F.Cleanup = function()
    alive = false
    for _, c in ipairs(C) do pcall(function() c:Disconnect() end) end
    C = {}
    if Root and Root.Parent then Root:Destroy() end
    if _G.SAB_MI then _G.SAB_MI = nil end
    if getgenv then getgenv().SAB_MI = nil end
end
T(ClsB.MouseButton1Click:Connect(F.Cleanup))

_G.SAB_MI = { Cleanup = F.Cleanup, ScanMachines = ScanMachines, ScanZones = ScanZones,
              Insert = InsertInto, Carried = Carried, Machines = function() return machines end,
              Zones = function() return zones end }
if getgenv then getgenv().SAB_MI = _G.SAB_MI end

INFO("listo. Coge un brainrot y pulsa ESCANEAR.")
INFO("Pesta帽a M脕QUINAS 鈫� TOUCH en la que quieras.")

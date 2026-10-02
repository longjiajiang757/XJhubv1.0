-- ============================================================
-- XJ Hub 1.0 beta  |  作者: 嘉酱  |  图标: XJ
-- 自包含单文件，一次粘贴即运行
-- ============================================================

local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local RunSvc  = game:GetService("RunService")
local UIS     = game:GetService("UserInputService")
local Tween   = game:GetService("TweenService")
local WS      = game:GetService("Workspace")
local LP      = Players.LocalPlayer

local function L(s, m) print(("[XJ] %s %s"):format(s, m)) end
local function ok(m)  L("✅", m) end
local function no(m)  L("❌", m) end
local function inf(m) L("ℹ️", m) end

inf("XJ Hub 1.0 beta 开始加载")
inf("执行器: " .. ((identifyexecutor and identifyexecutor()) or "unknown"))

local env = {
    ["loadstring"] = type(loadstring) == "function",
    ["getgenv"] = type(getgenv) == "function",
    ["HttpGet"] = type(game.HttpGet) == "function",
    ["getgc"] = type(getgc) == "function",
    ["hookmetamethod"] = type(hookmetamethod) == "function",
    ["newcclosure"] = type(newcclosure) == "function",
    ["fireproximityprompt"] = type(fireproximityprompt) == "function",
    ["Drawing"] = type(Drawing) ~= "nil",
}
for k, v in pairs(env) do
    if v then ok("环境: " .. k) else no("缺失: " .. k) end
end

local remote = RS:WaitForChild("Remote", 10)
local playerEvent = remote and remote:WaitForChild("PlayerEvent", 10)
local playerFunc = remote and remote:WaitForChild("PlayerFunc", 10)
if playerEvent then ok("获取 PlayerEvent") else no("未找到 PlayerEvent") end
if playerFunc  then ok("获取 PlayerFunc")  else no("未找到 PlayerFunc")  end

local Core, Character
pcall(function()
    local fw = LP:WaitForChild("PlayerScripts", 10):WaitForChild("Framework", 10)
    Core = require(fw:WaitForChild("Core", 10))
    Character = require(fw:WaitForChild("Character", 10))
end)
if Core then ok("加载 Core") else no("加载 Core") end
if Character then ok("加载 Character") else no("加载 Character") end

local function getChar(p)
    p = p or LP
    local c = p.Character
    if not c then return end
    local h = c:FindFirstChildOfClass("Humanoid")
    local r = c:FindFirstChild("HumanoidRootPart")
        or c:FindFirstChild("Torso")
        or c:FindFirstChild("UpperTorso")
    return c, h, r
end

local S = {
    stamina = false, food = false, noRagdoll = false,
    noFallDamage = false, infiniteJump = false,
    infiniteAmmo = false, rapidFire = false, autoMoney = false,
    auraEnabled = false, auraRange = 50, auraDamage = 5,
    espEnabled = false, espDistance = true, espHealth = true,
    aimbotEnabled = false, aimbotFov = 100,
}

RunSvc.Heartbeat:Connect(function()
    if Core then
        if S.stamina then pcall(function() Core.stamina = 100 end) end
        if S.food    then pcall(function() Core.food = 100 end) end
        if S.rapidFire and getgc then
            for _, v in pairs(getgc(true)) do
                if type(v) == "table" then
                    if rawget(v, "SHOOT_MODE") ~= nil then rawset(v, "SHOOT_MODE", 2) end
                    if rawget(v, "RPM") ~= nil then rawset(v, "RPM", math.huge) end
                end
            end
        end
    end
    if S.infiniteAmmo then
        local cf = WS:FindFirstChild("Characters")
        local ch = cf and cf:FindFirstChild(LP.Name)
        if ch then
            for _, child in ipairs(ch:GetChildren()) do
                local cfg = child:FindFirstChild("Config")
                if cfg then
                    local ammo = cfg:FindFirstChild("Ammo")
                    local total = cfg:FindFirstChild("TotalAmmo")
                    if ammo then ammo.Value = math.huge end
                    if total then total.Value = math.huge end
                end
            end
        end
    end
end)
ok("心跳循环已启动")

if hookmetamethod and newcclosure then
    pcall(function()
        local mt = getrawmetatable(game)
        local orig = mt.__namecall
        setreadonly(mt, false)
        mt.__namecall = newcclosure(function(self, ...)
            local args = {...}
            local method = getnamecallmethod()
            if S.noFallDamage and method == "FireServer"
                and tostring(self) == "PlayerEvent" and args[1] == "takeDamage" then
                return nil
            end
            return orig(self, ...)
        end)
        setreadonly(mt, true)
        ok("防摔伤 hook 已装载")
    end)
end

pcall(function()
    local Ragdoll = require(RS.Modules.Ragdoll)
    local a, b = Ragdoll.activate, Ragdoll.activateServer
    Ragdoll.activate = function(self, cond, ...)
        if S.noRagdoll and cond then return end
        return a(self, cond, ...)
    end
    if b then
        Ragdoll.activateServer = function(self, cond, ...)
            if S.noRagdoll and cond then return end
            return b(self, cond, ...)
        end
    end
    ok("防布娃娃 hook 已装载")
end)

UIS.JumpRequest:Connect(function()
    if not S.infiniteJump then return end
    local _, h, r = getChar()
    if h and r and h.Health > 0 then
        r.CFrame = r.CFrame + Vector3.new(0, 5, 0)
    end
end)
ok("无限跳跃已就绪")

local auraLast = 0
RunSvc.Heartbeat:Connect(function()
    if not S.auraEnabled or not playerEvent then return end
    if tick() - auraLast < 0.05 then return end
    local _, _, r = getChar()
    if not r then return end
    local tgt, bd = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then
            local _, ph, pr = getChar(p)
            if ph and pr and ph.Health > 0 then
                local d = (pr.Position - r.Position).Magnitude
                if d <= S.auraRange and d < bd then tgt, bd = p, d end
            end
        end
    end
    if tgt then
        local _, _, pr = getChar(tgt)
        pcall(function()
            playerEvent:FireServer("damage", {
                bodyParts = {{"Head", 1}},
                shotCode = { r.Position, (pr.Position - r.Position).Unit },
                pos = pr.Position, target = tgt,
                damageFactor = S.auraDamage, bulletProofTool = false,
            })
        end)
        auraLast = tick()
    end
end)
ok("杀戮光环已就绪")

task.spawn(function()
    while true do
        if S.autoMoney and fireproximityprompt then
            local _, _, r = getChar()
            if r then
                local best, bd = nil, math.huge
                for _, d in ipairs(WS:GetDescendants()) do
                    if d:IsA("ProximityPrompt") then
                        local n = tostring(d.Name):lower()
                        local hit = n:find("cash") or n:find("money") or n:find("pick") or n:find("getitem")
                        if hit then
                            local parent = d.Parent
                            local pos = parent and parent:IsA("BasePart") and parent.Position or nil
                            if pos then
                                local dist = (r.Position - pos).Magnitude
                                if dist < bd and dist < 100 then best, bd = d, dist end
                            end
                        end
                    end
                end
                if best then pcall(fireproximityprompt, best, 0) end
            end
        end
        task.wait(0.3)
    end
end)
ok("自动捡钱已就绪")

RunSvc.RenderStepped:Connect(function()
    if not S.aimbotEnabled then return end
    local cam = WS.CurrentCamera
    if not cam then return end
    local center = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y/2)
    local tgt, bd = nil, S.aimbotFov
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then
            local c, h = getChar(p)
            if c and h and h.Health > 0 then
                local part = c:FindFirstChild("Head") or c:FindFirstChild("HumanoidRootPart")
                if part then
                    local sp, on = cam:WorldToViewportPoint(part.Position)
                    if on then
                        local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                        if d < bd then tgt, bd = part, d end
                    end
                end
            end
        end
    end
    if tgt then cam.CFrame = CFrame.new(cam.CFrame.Position, tgt.Position) end
end)
ok("自瞄已就绪")

local espParent = (gethui and gethui()) or game:GetService("CoreGui")
local espFolder = Instance.new("Folder")
espFolder.Name = "XJ_ESP"
espFolder.Parent = espParent
local espCache = {}
RunSvc.Heartbeat:Connect(function()
    if not S.espEnabled then
        for p, obj in pairs(espCache) do obj:Destroy(); espCache[p] = nil end
        return
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then
            local c, h, r = getChar(p)
            if c and h and r and h.Health > 0 then
                if not espCache[p] then
                    local bb = Instance.new("BillboardGui")
                    bb.Name = "esp_" .. p.Name
                    bb.AlwaysOnTop = true
                    bb.Size = UDim2.new(0, 200, 0, 40)
                    bb.StudsOffset = Vector3.new(0, 3, 0)
                    bb.Adornee = r
                    bb.Parent = espFolder
                    local lbl = Instance.new("TextLabel")
                    lbl.Size = UDim2.new(1, 0, 1, 0)
                    lbl.BackgroundTransparency = 1
                    lbl.TextColor3 = Color3.fromRGB(0, 255, 0)
                    lbl.TextStrokeTransparency = 0
                    lbl.Font = Enum.Font.GothamBold
                    lbl.TextSize = 14
                    lbl.Parent = bb
                    espCache[p] = bb
                end
                local bb = espCache[p]
                bb.Adornee = r
                local lbl = bb:FindFirstChildOfClass("TextLabel")
                if lbl then
                    local parts = { p.Name }
                    if S.espDistance then
                        local _, _, mr = getChar()
                        if mr then table.insert(parts, "[" .. math.floor((mr.Position - r.Position).Magnitude) .. "m]") end
                    end
                    if S.espHealth then table.insert(parts, "[" .. math.floor(h.Health) .. "]") end
                    lbl.Text = table.concat(parts, " ")
                end
            else
                if espCache[p] then espCache[p]:Destroy(); espCache[p] = nil end
            end
        end
    end
end)
ok("ESP 已就绪")

local uiParent = (gethui and gethui()) or game:GetService("CoreGui")
local screen = Instance.new("ScreenGui")
screen.Name = "XJHubUI"
screen.ResetOnSpawn = false
screen.IgnoreGuiInset = true
screen.Parent = uiParent

local main = Instance.new("Frame", screen)
main.Size = UDim2.new(0, 480, 0, 360)
main.Position = UDim2.new(0.5, -240, 0.5, -180)
main.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
main.BorderSizePixel = 0
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 14)
local s1 = Instance.new("UIStroke", main)
s1.Color = Color3.fromRGB(168, 85, 247)
s1.Thickness = 2

local tb = Instance.new("Frame", main)
tb.Size = UDim2.new(1, 0, 0, 56)
tb.BackgroundColor3 = Color3.fromRGB(28, 28, 40)
tb.BorderSizePixel = 0
Instance.new("UICorner", tb).CornerRadius = UDim.new(0, 14)

local ico = Instance.new("Frame", tb)
ico.Size = UDim2.new(0, 40, 0, 40)
ico.Position = UDim2.new(0, 12, 0.5, -20)
ico.BackgroundColor3 = Color3.fromRGB(168, 85, 247)
ico.BorderSizePixel = 0
Instance.new("UICorner", ico).CornerRadius = UDim.new(0, 10)
local il = Instance.new("TextLabel", ico)
il.Size = UDim2.new(1, 0, 1, 0)
il.BackgroundTransparency = 1
il.Text = "XJ"
il.TextColor3 = Color3.new(1, 1, 1)
il.Font = Enum.Font.GothamBlack
il.TextSize = 18

local tl = Instance.new("TextLabel", tb)
tl.Size = UDim2.new(1, -200, 0, 20)
tl.Position = UDim2.new(0, 62, 0, 8)
tl.BackgroundTransparency = 1
tl.Text = "XJ HUB 1.0 beta"
tl.TextColor3 = Color3.new(1, 1, 1)
tl.Font = Enum.Font.GothamBold
tl.TextSize = 16
tl.TextXAlignment = Enum.TextXAlignment.Left

local sl = Instance.new("TextLabel", tb)
sl.Size = UDim2.new(1, -200, 0, 14)
sl.Position = UDim2.new(0, 62, 0, 28)
sl.BackgroundTransparency = 1
sl.Text = "作者: 嘉酱"
sl.TextColor3 = Color3.fromRGB(180, 180, 200)
sl.Font = Enum.Font.Gotham
sl.TextSize = 12
sl.TextXAlignment = Enum.TextXAlignment.Left

local cb = Instance.new("TextButton", tb)
cb.Size = UDim2.new(0, 32, 0, 32)
cb.Position = UDim2.new(1, -44, 0.5, -16)
cb.BackgroundColor3 = Color3.fromRGB(239, 68, 68)
cb.Text = "×"
cb.TextColor3 = Color3.new(1, 1, 1)
cb.Font = Enum.Font.GothamBold
cb.TextSize = 20
cb.BorderSizePixel = 0
Instance.new("UICorner", cb).CornerRadius = UDim.new(0, 8)
cb.MouseButton1Click:Connect(function() screen:Destroy() end)

local drag, ds, sp = false, nil, nil
tb.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        drag = true; ds = i.Position; sp = main.Position
    end
end)
UIS.InputChanged:Connect(function(i)
    if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
        local d = i.Position - ds
        main.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
    end
end)
UIS.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag = false end
end)

local content = Instance.new("ScrollingFrame", main)
content.Size = UDim2.new(1, -20, 1, -80)
content.Position = UDim2.new(0, 10, 0, 66)
content.BackgroundTransparency = 1
content.BorderSizePixel = 0
content.ScrollBarThickness = 4
content.ScrollBarImageColor3 = Color3.fromRGB(168, 85, 247)
content.AutomaticCanvasSize = Enum.AutomaticSize.Y

local ll = Instance.new("UIListLayout", content)
ll.Padding = UDim.new(0, 6)
ll.SortOrder = Enum.SortOrder.LayoutOrder

local order = 0
local function addToggle(name, cb_, def)
    order = order + 1
    local btn = Instance.new("TextButton", content)
    btn.Size = UDim2.new(1, 0, 0, 42)
    btn.BackgroundColor3 = Color3.fromRGB(32, 32, 44)
    btn.Text = ""
    btn.BorderSizePixel = 0
    btn.LayoutOrder = order
    btn.AutoButtonColor = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    local lbl = Instance.new("TextLabel", btn)
    lbl.Size = UDim2.new(1, -80, 1, 0)
    lbl.Position = UDim2.new(0, 14, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = name
    lbl.TextColor3 = Color3.fromRGB(230, 230, 240)
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 14
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local ind = Instance.new("Frame", btn)
    ind.Size = UDim2.new(0, 42, 0, 22)
    ind.Position = UDim2.new(1, -54, 0.5, -11)
    ind.BackgroundColor3 = Color3.fromRGB(55, 55, 70)
    ind.BorderSizePixel = 0
    Instance.new("UICorner", ind).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame", ind)
    knob.Size = UDim2.new(0, 18, 0, 18)
    knob.Position = UDim2.new(0, 2, 0.5, -9)
    knob.BackgroundColor3 = Color3.new(1, 1, 1)
    knob.BorderSizePixel = 0
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local state = def or false
    local function refresh()
        Tween:Create(knob, TweenInfo.new(0.15), {
            Position = state and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
        }):Play()
        Tween:Create(ind, TweenInfo.new(0.15), {
            BackgroundColor3 = state and Color3.fromRGB(168, 85, 247) or Color3.fromRGB(55, 55, 70)
        }):Play()
    end
    refresh()

    btn.MouseButton1Click:Connect(function()
        state = not state
        refresh()
        ok(("%s → %s"):format(name, tostring(state)))
        if cb_ then pcall(cb_, state) end
    end)
end

addToggle("无限体力",  function(v) S.stamina = v end)
addToggle("无限饥饿",  function(v) S.food = v end)
addToggle("防布娃娃",  function(v) S.noRagdoll = v end)
addToggle("防摔伤",    function(v) S.noFallDamage = v end)
addToggle("无限子弹",  function(v) S.infiniteAmmo = v end)
addToggle("快速射击",  function(v) S.rapidFire = v end)
addToggle("无限跳跃",  function(v) S.infiniteJump = v end)
addToggle("自动捡钱",  function(v) S.autoMoney = v end)
addToggle("杀戮光环",  function(v) S.auraEnabled = v end)
addToggle("ESP 透视",  function(v) S.espEnabled = v end)
addToggle("自瞄",      function(v) S.aimbotEnabled = v end)

ok("UI 构建完成")
inf("=========================================")
inf("XJ Hub 1.0 beta 加载完成！")
inf("所有 [XJ] 输出可在控制台查看")
inf("=========================================")
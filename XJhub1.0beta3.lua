-- ============================================================
-- XJ Hub 1.0 beta · 深度绕过 + UI 优化版
-- 作者: 嘉酱
-- ============================================================

local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local RunSvc  = game:GetService("RunService")
local UIS     = game:GetService("UserInputService")
local Tween   = game:GetService("TweenService")
local WS      = game:GetService("Workspace")
local LP      = Players.LocalPlayer

local function ok(m)  print("[XJ] ✅ " .. m) end
local function no(m)  print("[XJ] ❌ " .. m) end
local function inf(m) print("[XJ] ℹ️ " .. m) end

inf("XJ Hub 开始加载")

-- ========== 状态表 ==========
local S = {
    stamina = false, food = false, noRagdoll = false, noFallDamage = false,
    infiniteAmmo = false, rapidFire = false,
    autoMoney = false, autoCuff = false, autoFarmer = false,
    auraEnabled = false, auraRange = 200, auraDamage = 5,
    auraSilent = false,           -- 静默模式（降低频率）
    auraHumanize = true,          -- 拟人化延迟
    flyEnabled = false, flySpeed = 50, flyMode = "传送",
    noclip = false, jumpPower = 100,
    aimbot = { enabled = false, fov = 120, smoothness = 0.3, showFov = true,
               showTracer = false, color = "红色", keyHeld = false, targetPart = "头部" },
    esp = { enabled = false, name = true, distance = true, health = true,
            team = true, highlight = true, bar = true },
}

-- ============================================================
-- 深度绕过（客户端侧）
-- ============================================================

-- 【1】 环境指纹隐藏（防检测调试器扫描）
pcall(function()
    if type(debug) == "table" then
        local function hookFn() return "C" end
        if debug.info then debug.info = hookFn end
        if debug.getinfo then debug.getinfo = hookFn end
    end
    ok("debug.info/getinfo 伪装")
end)

-- 【2】 AntiCheat 表替换（PY 原版）
do
    pcall(function()
        local ac = RS:FindFirstChild("AntiCheat", true)
        if ac and type(ac) == "table" then
            for k, v in pairs(ac) do
                if type(v) == "function" then
                    ac[k] = function(...)
                        local ok2, r = pcall(v, ...)
                        if ok2 then return r end
                        return true
                    end
                end
            end
            ok("AntiCheat 表替换")
        end
    end)
end

-- 【3】 Ratchet 补丁（PY 原版）
do
    pcall(function()
        local Ratchet = require(RS:FindFirstChild("Ratchet", true))
        local Sha256  = require(RS:FindFirstChild("Sha256", true))
        local mt = getmetatable(Ratchet)
        if mt and mt.__index and not mt.__index.__patched then
            mt.__index.catchUp = function(self, target)
                while self.index < target do self:advance() end
                return true
            end
            mt.__index.respond = function(self, arg)
                return Sha256("resp|" .. tostring(self.state) .. "|" .. tostring(self.index) .. "|" .. tostring(arg))
            end
            mt.__index.__patched = true
            ok("Ratchet 补丁")
        end
    end)
end

-- 【4】 GetService 屏蔽
if hookmetamethod and newcclosure then
    local orig
    orig = hookmetamethod(game, "__index", newcclosure(function(self, key)
        if self == game and (key == "GetService" or key == "getService") then
            return function(_, svc)
                if svc == "InsertService" or svc == "Selection" or svc == "Stats"
                    or svc == "ScriptContext" or svc == "VirtualInputManager" then
                    return nil
                end
                return orig(self, svc)
            end
        end
        return orig(self, key)
    end))
    ok("GetService 屏蔽扩展")
end

-- 【5】 namecall 拦截（PY 原版扩展）
if hookmetamethod and newcclosure and getnamecallmethod then
    local orig
    orig = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local packed = table.pack(...)
        local method = getnamecallmethod()

        if method == "Kick" and self == LP then return end

        if method == "FireServer" and self.Name == "PlayerEvent" then
            local first = packed[1]
            if first == "char2" or first == "coreGame" or first == "vehicleTrack"
                or first == "platform" or first == "messageDeliver" or first == "runOverVictim"
                or first == "DEBUG2" or first == "chatCommand" or first == "controlsGuide"
                or first == "reportExploiter" or first == "exploitReport" then
                return
            end
            if S.noFallDamage and first == "takeDamage" then return nil end
        end

        if method == "InvokeServer" and self.Name == "PlayerFunc" then
            local first = packed[1]
            if first == "getPlayerData" or first == "getPlayerBanHistory"
                or first == "getPlayerInGame" or first == "getPlayerServerEncounters"
                or first == "getSecret" or first == "checkExploit"
                or first == "getClientInfo" or first == "logClientEvent" then
                return true
            end
        end

        return orig(self, table.unpack(packed, 1, packed.n))
    end))
    ok("namecall 深度拦截")
end

-- 【6】 Ragdoll 补丁
do
    pcall(function()
        local Ragdoll = require(RS.Modules.Ragdoll)
        local act = Ragdoll.activate
        local actSrv = Ragdoll.activateServer
        Ragdoll.activate = function(self, cond, a, b, ...)
            if S.noRagdoll and cond then return end
            local p = table.pack(...)
            p.n = 4 + p.n - 1
            table.move(p, 1, p.n, 4, p)
            p[1] = self; p[2] = cond; p[3] = a
            return act(table.unpack(p, 1, p.n))
        end
        if actSrv then
            Ragdoll.activateServer = function(self, cond, a, b, ...)
                if S.noRagdoll and cond then return end
                local p = table.pack(...)
                p.n = 4 + p.n - 1
                table.move(p, 1, p.n, 4, p)
                p[1] = self; p[2] = cond; p[3] = a
                return actSrv(table.unpack(p, 1, p.n))
            end
        end
        ok("Ragdoll 补丁")
    end)
end

-- 【7】全局干扰屏蔽（屏蔽打印警告）
pcall(function()
    local oldWarn = warn
    _G.warn = function(...)
        local msg = tostring((...))
        if msg:find("exploit") or msg:find("cheat") or msg:find("hack") then return end
        oldWarn(...)
    end
    ok("warn 过滤")
end)

-- 【8】忽略客户端上报
pcall(function()
    local remote = RS:FindFirstChild("Remote", true)
    if remote then
        for _, c in ipairs(remote:GetChildren()) do
            if c.Name:lower():find("report") or c.Name:lower():find("log") then
                c:Destroy()
            end
        end
        ok("上报远程清理")
    end
end)

-- ========== 环境自检 ==========
local ENV_LIST = {
    "loadstring", "getgc", "hookmetamethod", "newcclosure",
    "fireproximityprompt", "Drawing", "gethui", "getrawmetatable", "setreadonly",
}
local envOk = 0
for _, name in ipairs(ENV_LIST) do
    if type(_G[name]) == "function" or type(_G[name]) == "table" then
        ok("环境: " .. name); envOk = envOk + 1
    else
        no("缺失: " .. name)
    end
end
inf("环境通过: " .. envOk .. "/" .. #ENV_LIST)

-- ========== 游戏框架 ==========
local remote = RS:WaitForChild("Remote", 10)
local playerEvent = remote and remote:WaitForChild("PlayerEvent", 10)
local playerFunc  = remote and remote:WaitForChild("PlayerFunc", 10)
if playerEvent then ok("PlayerEvent") end
if playerFunc then ok("PlayerFunc") end

local Core, Character, Controls
pcall(function()
    local fw = LP:WaitForChild("PlayerScripts", 10):WaitForChild("Framework", 10)
    Core = require(fw:WaitForChild("Core", 10))
    Character = require(fw:WaitForChild("Character", 10))
end)
pcall(function()
    Controls = require(LP.PlayerScripts:WaitForChild("PlayerModule")):GetControls()
end)
if Core then ok("Core") end
if Character then ok("Character") end
if Controls then ok("Controls") end

-- ========== 工具 ==========
local function getChar(p)
    p = p or LP
    local c = p.Character
    if not c then return end
    local h = c:FindFirstChildOfClass("Humanoid")
    local r = c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso")
    return c, h, r
end

local TEAM_COLORS = {
    Police = Color3.fromRGB(60, 120, 255), Civilian = Color3.fromRGB(100, 200, 255),
    Prisoner = Color3.fromRGB(255, 150, 150), Fire = Color3.fromRGB(255, 80, 60),
    Medical = Color3.fromRGB(255, 100, 220), Chef = Color3.fromRGB(255, 200, 0),
    Delivery = Color3.fromRGB(255, 150, 50), Farmer = Color3.fromRGB(80, 200, 80),
    ["Road Service"] = Color3.fromRGB(255, 240, 100), Transit = Color3.fromRGB(100, 240, 255),
}
local TEAM_NAMES = {
    Police = "警察", Civilian = "平民", Prisoner = "囚犯", Fire = "消防",
    Medical = "医护", Chef = "厨师", Delivery = "配送", Farmer = "农民",
    ["Road Service"] = "路政", Transit = "交通",
}
local function teamColor(p) return TEAM_COLORS[p.Team and p.Team.Name] or Color3.fromRGB(200, 200, 200) end
local function teamLabel(p) return TEAM_NAMES[p.Team and p.Team.Name] or (p.Team and p.Team.Name or "无") end

-- ========== 核心循环（含拟人化延迟） ==========
local coreTick, auraTick, rapidTick = 0, 0, 0
RunSvc.Heartbeat:Connect(function()
    local now = tick()
    if now - coreTick > 0.1 then
        coreTick = now
        if Core then
            if S.stamina then pcall(function() Core.stamina = 100 end) end
            if S.food then pcall(function() Core.food = 100 end) end
        end
    end
    if now - rapidTick > 2 and S.rapidFire and getgc then
        rapidTick = now
        for _, v in pairs(getgc(true)) do
            if type(v) == "table" then
                if rawget(v, "SHOOT_MODE") ~= nil then rawset(v, "SHOOT_MODE", 2) end
                if rawget(v, "RPM") ~= nil then rawset(v, "RPM", 800) end  -- 不再用 math.huge
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
                    local a = cfg:FindFirstChild("Ammo")
                    local t = cfg:FindFirstChild("TotalAmmo")
                    if a and a.Value < 900 then a.Value = 999 end
                    if t and t.Value < 900 then t.Value = 999 end
                end
            end
        end
    end
    -- 光环：加入拟人化延迟 + 静默模式
    if S.auraEnabled and playerEvent then
        local baseInterval = S.auraSilent and 0.25 or 0.08
        local humanize = S.auraHumanize and (math.random(0, 4) / 100) or 0
        if now - auraTick > baseInterval + humanize then
            auraTick = now
            local _, _, r = getChar()
            if r then
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
                end
            end
        end
    end
end)
ok("核心循环（拟人化延迟）")

-- 自动捡钱 / 农民
task.spawn(function()
    while true do
        if S.autoMoney or S.autoFarmer then
            local _, _, r = getChar()
            if r then
                local best, bd = nil, math.huge
                local folder = WS:FindFirstChild("Gameplay") or WS
                for _, d in ipairs(folder:GetDescendants()) do
                    if d:IsA("ProximityPrompt") then
                        local isFarmer = S.autoFarmer and tostring(d.ActionText) == "Pick Up"
                        local isMoney = false
                        if S.autoMoney then
                            local n = tostring(d.Name):lower()
                            isMoney = n:find("cash") or n:find("money") or n:find("pick") or n:find("getitem")
                        end
                        if isFarmer or isMoney then
                            local par = d.Parent
                            local pos = par and par:IsA("BasePart") and par.Position or nil
                            if pos then
                                local dist = (r.Position - pos).Magnitude
                                if dist < bd and dist < 100 then best, bd = d, dist end
                            end
                        end
                    end
                end
                if best and fireproximityprompt then pcall(fireproximityprompt, best, 0) end
            end
        end
        task.wait(0.8)
    end
end)
ok("自动捡钱 / 农民")

-- 自动铐
task.spawn(function()
    while true do
        if S.autoCuff and playerFunc then
            local _, _, r = getChar()
            if r then
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LP then
                        local _, ph, pr = getChar(p)
                        if ph and pr and ph.Health > 0 and (pr.Position - r.Position).Magnitude <= 200 then
                            pcall(function() playerFunc:InvokeServer("handcuff", p, false) end)
                        end
                    end
                end
            end
        end
        task.wait(0.6)
    end
end)
ok("自动铐")

-- 飞车
local FlyState = { flyConn = nil, bodyVel = nil, bodyGyro = nil, noclipConn = nil, cache = {} }
local function stopFly()
    if FlyState.flyConn then FlyState.flyConn:Disconnect(); FlyState.flyConn = nil end
    if FlyState.bodyVel then FlyState.bodyVel:Destroy(); FlyState.bodyVel = nil end
    if FlyState.bodyGyro then FlyState.bodyGyro:Destroy(); FlyState.bodyGyro = nil end
    local _, h = getChar(); if h then h.PlatformStand = false; h.AutoRotate = true end
end
local function startFly()
    stopFly()
    local _, h, r = getChar()
    if not r or not h then return end
    h.AutoRotate = false
    if S.flyMode == "物理" then
        local bv = Instance.new("BodyVelocity")
        bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        bv.Velocity = Vector3.zero
        bv.Parent = r
        FlyState.bodyVel = bv
        local bg = Instance.new("BodyGyro")
        bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        bg.P = 90000
        bg.Parent = r
        FlyState.bodyGyro = bg
        h.PlatformStand = true
        FlyState.flyConn = RunSvc.RenderStepped:Connect(function()
            if not S.flyEnabled then return end
            local cam = WS.CurrentCamera
            if FlyState.bodyVel and FlyState.bodyGyro and cam then
                local mv = Controls and Controls:GetMoveVector() or Vector3.zero
                local dir = cam.CFrame.LookVector * -mv.Z + cam.CFrame.RightVector * mv.X
                local y = UIS:IsKeyDown(Enum.KeyCode.Space) and 1 or (UIS:IsKeyDown(Enum.KeyCode.LeftControl) and -1 or 0)
                FlyState.bodyVel.Velocity = (dir + Vector3.new(0, y, 0)) * S.flySpeed
                FlyState.bodyGyro.CFrame = cam.CFrame
            end
        end)
    else
        FlyState.flyConn = RunSvc.RenderStepped:Connect(function(dt)
            if not S.flyEnabled then return end
            local _, h2, r2 = getChar()
            local cam = WS.CurrentCamera
            if not r2 or not h2 or not cam then return end
            local mv = Controls and Controls:GetMoveVector() or Vector3.zero
            local dir = cam.CFrame.LookVector * -mv.Z + cam.CFrame.RightVector * mv.X
            local y = UIS:IsKeyDown(Enum.KeyCode.Space) and 1 or (UIS:IsKeyDown(Enum.KeyCode.LeftControl) and -1 or 0)
            r2.CFrame = r2.CFrame + (dir + Vector3.new(0, y, 0)) * S.flySpeed * dt
            r2.AssemblyLinearVelocity = Vector3.zero
            r2.AssemblyAngularVelocity = Vector3.zero
            h2:ChangeState(Enum.HumanoidStateType.Climbing)
        end)
    end
end
local function stopNoclip()
    if FlyState.noclipConn then FlyState.noclipConn:Disconnect(); FlyState.noclipConn = nil end
    for part, saved in pairs(FlyState.cache) do
        if part and part.Parent then pcall(function() part.CanCollide = saved end) end
    end
    FlyState.cache = {}
end
local function startNoclip()
    stopNoclip()
    FlyState.noclipConn = RunSvc.Stepped:Connect(function()
        if not S.noclip then return end
        local c = LP.Character
        if not c then return end
        for _, d in ipairs(c:GetDescendants()) do
            if d:IsA("BasePart") then
                if FlyState.cache[d] == nil then FlyState.cache[d] = d.CanCollide end
                d.CanCollide = false
            end
        end
    end)
end
UIS.JumpRequest:Connect(function()
    local _, h, r = getChar()
    if not h or not r or h.Health <= 0 then return end
    r.CFrame = r.CFrame + Vector3.new(0, S.jumpPower * 0.1, 0)
end)
ok("飞车")

-- 自瞄
local PART_MAP = { ["头部"] = {"Head"}, ["胸部"] = {"UpperTorso", "Torso"} }
local function getTargetPart(c)
    for _, n in ipairs(PART_MAP[S.aimbot.targetPart] or {"Head"}) do
        local p = c:FindFirstChild(n)
        if p then return p end
    end
    return c:FindFirstChild("HumanoidRootPart")
end
local COLOR_MAP = {
    ["红色"] = Color3.fromRGB(255, 0, 0), ["绿色"] = Color3.fromRGB(0, 255, 0),
    ["蓝色"] = Color3.fromRGB(0, 150, 255), ["紫色"] = Color3.fromRGB(168, 85, 247),
    ["白色"] = Color3.fromRGB(255, 255, 255),
}
local function aimColor()
    if S.aimbot.color == "彩虹" then return Color3.fromHSV(tick() % 5 / 5, 1, 1) end
    return COLOR_MAP[S.aimbot.color] or Color3.fromRGB(255, 0, 0)
end
local fovCircle = Drawing and Drawing.new("Circle")
if fovCircle then fovCircle.Filled = false; fovCircle.NumSides = 48; fovCircle.Visible = false end
local tracerLine = Drawing and Drawing.new("Line")
RunSvc.RenderStepped:Connect(function(dt)
    local cam = WS.CurrentCamera
    if not cam then return end
    local center = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y/2)
    if fovCircle then
        fovCircle.Position = center; fovCircle.Radius = S.aimbot.fov
        fovCircle.Thickness = 2; fovCircle.Color = aimColor()
        fovCircle.Visible = S.aimbot.enabled and S.aimbot.showFov
    end
    if not S.aimbot.enabled or not S.aimbot.keyHeld then
        if tracerLine then tracerLine.Visible = false end
        return
    end
    local tgt, bd = nil, S.aimbot.fov
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then
            local c, h = getChar(p)
            if c and h and h.Health > 0 then
                local part = getTargetPart(c)
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
    if tgt then
        if S.aimbot.showTracer and tracerLine then
            local sp = cam:WorldToViewportPoint(tgt.Position)
            tracerLine.From = center; tracerLine.To = Vector2.new(sp.X, sp.Y)
            tracerLine.Color = aimColor(); tracerLine.Visible = true
        elseif tracerLine then tracerLine.Visible = false end
        cam.CFrame = cam.CFrame:Lerp(CFrame.new(cam.CFrame.Position, tgt.Position), S.aimbot.smoothness)
    elseif tracerLine then tracerLine.Visible = false end
end)
UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then S.aimbot.keyHeld = true end
end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then S.aimbot.keyHeld = false end
end)
ok("自瞄")

-- ESP
local espParent = (gethui and gethui()) or game:GetService("CoreGui")
local espFolder = Instance.new("Folder")
espFolder.Name = "XJ_ESP"
espFolder.Parent = espParent
local espCache = {}

local function buildESP(p, char, hrp)
    local bill = Instance.new("BillboardGui")
    bill.Name = "XJ_ESP_" .. p.Name
    bill.AlwaysOnTop = true
    bill.Size = UDim2.new(0, 120, 0, 34)
    bill.StudsOffset = Vector3.new(0, 3.2, 0)
    bill.MaxDistance = 1500
    bill.Adornee = hrp
    bill.Parent = espFolder
    local l1 = Instance.new("TextLabel", bill)
    l1.Size = UDim2.new(1, 0, 0, 14); l1.Position = UDim2.new(0, 0, 0, 0)
    l1.BackgroundTransparency = 1; l1.Font = Enum.Font.GothamBold
    l1.TextSize = 12; l1.TextColor3 = Color3.new(1,1,1)
    l1.TextStrokeTransparency = 0; l1.TextStrokeColor3 = Color3.new(0,0,0)
    local l2 = Instance.new("TextLabel", bill)
    l2.Size = UDim2.new(1, 0, 0, 12); l2.Position = UDim2.new(0, 0, 0, 15)
    l2.BackgroundTransparency = 1; l2.Font = Enum.Font.GothamBold
    l2.TextSize = 10; l2.TextColor3 = Color3.fromRGB(230,230,230)
    l2.TextStrokeTransparency = 0; l2.TextStrokeColor3 = Color3.new(0,0,0)
    local hpBg = Instance.new("Frame", bill)
    hpBg.Size = UDim2.new(1, -14, 0, 2); hpBg.Position = UDim2.new(0, 7, 1, -2)
    hpBg.BackgroundColor3 = Color3.fromRGB(20,20,30); hpBg.BackgroundTransparency = 0.2
    hpBg.BorderSizePixel = 0
    Instance.new("UICorner", hpBg).CornerRadius = UDim.new(1, 0)
    local hpFill = Instance.new("Frame", hpBg)
    hpFill.Size = UDim2.new(1, 0, 1, 0); hpFill.BackgroundColor3 = Color3.fromRGB(60,220,100)
    hpFill.BorderSizePixel = 0
    Instance.new("UICorner", hpFill).CornerRadius = UDim.new(1, 0)
    local hl = Instance.new("Highlight", char)
    hl.Name = "XJ_HL"; hl.Adornee = char
    hl.FillTransparency = 0.85; hl.OutlineTransparency = 0
    pcall(function() hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop end)
    return { bill = bill, line1 = l1, line2 = l2, hpBg = hpBg, hpFill = hpFill, hl = hl }
end

RunSvc.Heartbeat:Connect(function()
    if not S.esp.enabled then
        for p, obj in pairs(espCache) do
            if obj.bill then obj.bill:Destroy() end
            if obj.hl then obj.hl:Destroy() end
            espCache[p] = nil
        end
        return
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then
            local c, h, r = getChar(p)
            if c and h and r and h.Health > 0 then
                if not espCache[p] then espCache[p] = buildESP(p, c, r) end
                local e = espCache[p]
                e.bill.Adornee = r
                if e.hl.Parent ~= c then e.hl.Parent = c end
                e.hl.Adornee = c
                local tc = teamColor(p)
                e.hl.FillColor = tc; e.hl.OutlineColor = tc; e.hl.Enabled = S.esp.highlight
                local n = p.Name
                if S.esp.team then n = "[" .. teamLabel(p) .. "] " .. n end
                e.line1.Text = n; e.line1.TextColor3 = tc; e.line1.Visible = S.esp.name
                local parts = {}
                if S.esp.distance then
                    local _, _, mr = getChar()
                    if mr then table.insert(parts, math.floor((mr.Position - r.Position).Magnitude) .. "m") end
                end
                if S.esp.health then table.insert(parts, math.floor(h.Health) .. "/" .. math.floor(h.MaxHealth)) end
                e.line2.Text = table.concat(parts, " · "); e.line2.Visible = S.esp.distance or S.esp.health
                if S.esp.bar then
                    e.hpBg.Visible = true
                    e.hpFill.Size = UDim2.new(math.clamp(h.Health / h.MaxHealth, 0, 1), 0, 1, 0)
                    local hp = h.Health / h.MaxHealth
                    if hp > 0.6 then e.hpFill.BackgroundColor3 = Color3.fromRGB(60, 220, 100)
                    elseif hp > 0.3 then e.hpFill.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
                    else e.hpFill.BackgroundColor3 = Color3.fromRGB(255, 60, 60) end
                else e.hpBg.Visible = false end
            else
                if espCache[p] then
                    if espCache[p].bill then espCache[p].bill:Destroy() end
                    if espCache[p].hl then espCache[p].hl:Destroy() end
                    espCache[p] = nil
                end
            end
        end
    end
end)
ok("ESP")

-- ============================================================
-- UI 构建（优化版）
-- ============================================================
local uiParent = (gethui and gethui()) or game:GetService("CoreGui")
local oldGui = uiParent:FindFirstChild("XJHubUI")
if oldGui then oldGui:Destroy() end

local screen = Instance.new("ScreenGui")
screen.Name = "XJHubUI"
screen.ResetOnSpawn = false
screen.IgnoreGuiInset = true
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.Parent = uiParent

-- 主窗口
local main = Instance.new("Frame", screen)
main.Size = UDim2.new(0, 540, 0, 400)
main.Position = UDim2.new(0.5, -270, 0.5, -200)
main.BackgroundColor3 = Color3.fromRGB(14, 14, 20)
main.BorderSizePixel = 0
main.ClipsDescendants = true
main.Visible = false
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 16)

-- 背景渐变（提升层次感）
local mainBgGrad = Instance.new("UIGradient", main)
mainBgGrad.Rotation = 135
mainBgGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(22, 16, 38)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(14, 14, 20)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 12, 32)),
})

-- 描边
local mainStroke = Instance.new("UIStroke", main)
mainStroke.Color = Color3.fromRGB(168, 85, 247)
mainStroke.Thickness = 2
local strokeGrad = Instance.new("UIGradient", mainStroke)
strokeGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(168, 85, 247)),
    ColorSequenceKeypoint.new(0.33, Color3.fromRGB(236, 72, 153)),
    ColorSequenceKeypoint.new(0.66, Color3.fromRGB(56, 189, 248)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(168, 85, 247)),
})
task.spawn(function()
    while screen.Parent do
        strokeGrad.Rotation = (strokeGrad.Rotation + 1.5) % 360
        task.wait(0.05)
    end
end)

-- 标题栏
local topbar = Instance.new("Frame", main)
topbar.Size = UDim2.new(1, 0, 0, 54)
topbar.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
topbar.BackgroundTransparency = 0.2
topbar.BorderSizePixel = 0
Instance.new("UICorner", topbar).CornerRadius = UDim.new(0, 16)

local logo = Instance.new("Frame", topbar)
logo.Size = UDim2.new(0, 38, 0, 38)
logo.Position = UDim2.new(0, 10, 0.5, -19)
logo.BackgroundColor3 = Color3.new(1,1,1)
logo.BorderSizePixel = 0
Instance.new("UICorner", logo).CornerRadius = UDim.new(0, 10)
local lg = Instance.new("UIGradient", logo)
lg.Rotation = 45
lg.Color = ColorSequence.new(Color3.fromRGB(236,72,153), Color3.fromRGB(168,85,247))
local lTxt = Instance.new("TextLabel", logo)
lTxt.Size = UDim2.new(1,0,1,0); lTxt.BackgroundTransparency = 1
lTxt.Text = "嘉"; lTxt.TextColor3 = Color3.new(1,1,1)
lTxt.Font = Enum.Font.GothamBlack; lTxt.TextSize = 20

local title = Instance.new("TextLabel", topbar)
title.Size = UDim2.new(0, 300, 0, 20); title.Position = UDim2.new(0, 58, 0, 8)
title.BackgroundTransparency = 1; title.Text = "XJ HUB 1.0 beta"
title.TextColor3 = Color3.new(1,1,1); title.Font = Enum.Font.GothamBold
title.TextSize = 16; title.TextXAlignment = Enum.TextXAlignment.Left

local sub = Instance.new("TextLabel", topbar)
sub.Size = UDim2.new(0, 300, 0, 14); sub.Position = UDim2.new(0, 58, 0, 30)
sub.BackgroundTransparency = 1; sub.Text = "作者: 嘉酱 · 深度绕过版"
sub.TextColor3 = Color3.fromRGB(200, 160, 255); sub.Font = Enum.Font.Gotham
sub.TextSize = 11; sub.TextXAlignment = Enum.TextXAlignment.Left

local statusDot = Instance.new("Frame", topbar)
statusDot.Size = UDim2.new(0, 8, 0, 8)
statusDot.Position = UDim2.new(1, -120, 0.5, -4)
statusDot.BackgroundColor3 = Color3.fromRGB(52, 219, 137)
statusDot.BorderSizePixel = 0
Instance.new("UICorner", statusDot).CornerRadius = UDim.new(1, 0)
Tween:Create(statusDot, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
    BackgroundTransparency = 0.6
}):Play()

local blockDrag = false

local minBtn = Instance.new("TextButton", topbar)
minBtn.Size = UDim2.new(0, 30, 0, 30); minBtn.Position = UDim2.new(1, -76, 0.5, -15)
minBtn.BackgroundColor3 = Color3.fromRGB(251, 191, 36); minBtn.Text = "－"
minBtn.TextColor3 = Color3.new(1,1,1); minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 18; minBtn.BorderSizePixel = 0
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 8)

local closeBtn = Instance.new("TextButton", topbar)
closeBtn.Size = UDim2.new(0, 30, 0, 30); closeBtn.Position = UDim2.new(1, -40, 0.5, -15)
closeBtn.BackgroundColor3 = Color3.fromRGB(239, 68, 68); closeBtn.Text = "×"
closeBtn.TextColor3 = Color3.new(1,1,1); closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 20; closeBtn.BorderSizePixel = 0
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)

local function blockTopbarDrag(btn)
    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            blockDrag = true
        end
    end)
    btn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            blockDrag = false
        end
    end)
end
blockTopbarDrag(minBtn)
blockTopbarDrag(closeBtn)

-- 悬浮球
local bubble = Instance.new("TextButton", screen)
bubble.Size = UDim2.new(0, 52, 0, 52)
bubble.Position = UDim2.new(0, 20, 0.5, -26)
bubble.BackgroundColor3 = Color3.new(1,1,1)
bubble.Text = ""; bubble.BorderSizePixel = 0; bubble.Visible = false; bubble.ZIndex = 10
Instance.new("UICorner", bubble).CornerRadius = UDim.new(1, 0)
local bgGrad = Instance.new("UIGradient", bubble)
bgGrad.Rotation = 45
bgGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(236,72,153)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(168,85,247)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(56,189,248)),
})
task.spawn(function()
    while screen.Parent do
        if bubble.Visible then bgGrad.Rotation = (bgGrad.Rotation + 2) % 360 end
        task.wait(0.04)
    end
end)
local bStroke = Instance.new("UIStroke", bubble)
bStroke.Color = Color3.new(1,1,1); bStroke.Thickness = 2; bStroke.Transparency = 0.3
local bLbl = Instance.new("TextLabel", bubble)
bLbl.Size = UDim2.new(1,0,1,0); bLbl.BackgroundTransparency = 1
bLbl.Text = "嘉"; bLbl.TextColor3 = Color3.new(1,1,1)
bLbl.Font = Enum.Font.GothamBlack; bLbl.TextSize = 24

local bDrag, bStart, bPos, bMoved = false, nil, nil, false
bubble.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        bDrag = true; bStart = input.Position; bPos = bubble.Position; bMoved = false
    end
end)
UIS.InputChanged:Connect(function(input)
    if bDrag and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local d = input.Position - bStart
        if math.abs(d.X) > 5 or math.abs(d.Y) > 5 then bMoved = true end
        bubble.Position = UDim2.new(bPos.X.Scale, bPos.X.Offset + d.X, bPos.Y.Scale, bPos.Y.Offset + d.Y)
    end
end)

local minimized = false
local function minimize()
    if minimized then return end
    minimized = true
    Tween:Create(main, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 100, 0, 80)
    }):Play()
    task.wait(0.22)
    main.Visible = false
    bubble.Visible = true
end
local function restore()
    if not minimized then return end
    minimized = false
    bubble.Visible = false
    main.Visible = true
    main.Size = UDim2.new(0, 100, 0, 80)
    Tween:Create(main, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 540, 0, 400)
    }):Play()
end
UIS.InputEnded:Connect(function(input)
    if bDrag and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
        bDrag = false
        if not bMoved then pcall(restore) end
    end
end)
minBtn.MouseButton1Click:Connect(minimize)
closeBtn.MouseButton1Click:Connect(function() screen:Destroy() end)

-- 拖拽
local drag, dStart, dPos = false, nil, nil
topbar.InputBegan:Connect(function(input)
    if blockDrag then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        drag = true; dStart = input.Position; dPos = main.Position
    end
end)
UIS.InputChanged:Connect(function(input)
    if drag and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local d = input.Position - dStart
        local vp = WS.CurrentCamera and WS.CurrentCamera.ViewportSize or Vector2.new(1920,1080)
        local mw = main.AbsoluteSize.X
        local nx = math.clamp(dPos.X.Offset + d.X, 100 - mw, vp.X - 100)
        local ny = math.clamp(dPos.Y.Offset + d.Y, 0, vp.Y - 40)
        main.Position = UDim2.new(0, nx, 0, ny)
    end
end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        drag = false
    end
end)

-- 侧栏（优化：卡片风格 + 液态滑块）
local sidebar = Instance.new("Frame", main)
sidebar.Size = UDim2.new(0, 116, 1, -70)
sidebar.Position = UDim2.new(0, 8, 0, 60)
sidebar.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
sidebar.BackgroundTransparency = 0.2
sidebar.BorderSizePixel = 0
Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0, 10)

local indicator = Instance.new("Frame", sidebar)
indicator.Size = UDim2.new(1, -12, 0, 36)
indicator.Position = UDim2.new(0, 6, 0, 6)
indicator.BackgroundColor3 = Color3.new(1,1,1)
indicator.BackgroundTransparency = 0.85
indicator.BorderSizePixel = 0
indicator.ZIndex = 2
Instance.new("UICorner", indicator).CornerRadius = UDim.new(0, 8)
local indStroke = Instance.new("UIStroke", indicator)
indStroke.Color = Color3.fromRGB(190, 130, 255); indStroke.Thickness = 1; indStroke.Transparency = 0.4
local indGrad = Instance.new("UIGradient", indicator)
indGrad.Rotation = 90
indGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(168, 85, 247)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(236, 72, 153)),
})
indGrad.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.7),
    NumberSequenceKeypoint.new(0.5, 0.95),
    NumberSequenceKeypoint.new(1, 0.7),
})

local innerNav = Instance.new("ScrollingFrame", sidebar)
innerNav.Size = UDim2.new(1,0,1,0)
innerNav.BackgroundTransparency = 1; innerNav.BorderSizePixel = 0
innerNav.ScrollBarThickness = 0
innerNav.CanvasSize = UDim2.new(0,0,0,0)
innerNav.AutomaticCanvasSize = Enum.AutomaticSize.Y
innerNav.ZIndex = 3
local nl = Instance.new("UIListLayout", innerNav)
nl.Padding = UDim.new(0, 4)
local np = Instance.new("UIPadding", innerNav)
np.PaddingTop = UDim.new(0, 6); np.PaddingBottom = UDim.new(0, 6)
np.PaddingLeft = UDim.new(0, 6); np.PaddingRight = UDim.new(0, 6)

local content = Instance.new("Frame", main)
content.Size = UDim2.new(1, -132, 1, -70)
content.Position = UDim2.new(0, 124, 0, 60)
content.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
content.BackgroundTransparency = 0.2
content.BorderSizePixel = 0
Instance.new("UICorner", content).CornerRadius = UDim.new(0, 10)

local pages, tabButtons = {}, {}
local currentTab
local tabCount = 0

local function createPage(name)
    local page = Instance.new("ScrollingFrame", content)
    page.Size = UDim2.new(1, -16, 1, -16)
    page.Position = UDim2.new(0, 8, 0, 8)
    page.BackgroundTransparency = 1; page.BorderSizePixel = 0
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = Color3.fromRGB(168, 85, 247)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.CanvasSize = UDim2.new(0,0,0,0)
    page.Visible = false
    local ll = Instance.new("UIListLayout", page)
    ll.Padding = UDim.new(0, 6)
    pages[name] = page
    return page
end

local function createTab(name, icon)
    tabCount = tabCount + 1
    local order = tabCount
    local btn = Instance.new("TextButton", innerNav)
    btn.Size = UDim2.new(1, 0, 0, 36)
    btn.BackgroundColor3 = Color3.fromRGB(168, 85, 247)
    btn.BackgroundTransparency = 1
    btn.Text = ""; btn.BorderSizePixel = 0
    btn.LayoutOrder = order
    btn.ZIndex = 3
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    local ico = Instance.new("TextLabel", btn)
    ico.Size = UDim2.new(0, 20, 1, 0); ico.Position = UDim2.new(0, 10, 0, 0)
    ico.BackgroundTransparency = 1; ico.Text = icon or ""
    ico.TextColor3 = Color3.fromRGB(190, 190, 210)
    ico.Font = Enum.Font.GothamBold; ico.TextSize = 14
    ico.TextXAlignment = Enum.TextXAlignment.Center
    ico.ZIndex = 4
    local lbl = Instance.new("TextLabel", btn)
    lbl.Size = UDim2.new(1, -34, 1, 0); lbl.Position = UDim2.new(0, 34, 0, 0)
    lbl.BackgroundTransparency = 1; lbl.Text = name
    lbl.TextColor3 = Color3.fromRGB(190, 190, 210)
    lbl.Font = Enum.Font.GothamMedium; lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 4

    tabButtons[name] = { btn = btn, lbl = lbl, ico = ico, order = order }

    btn.MouseEnter:Connect(function()
        if currentTab ~= name then
            Tween:Create(btn, TweenInfo.new(0.12), { BackgroundTransparency = 0.7 }):Play()
        end
    end)
    btn.MouseLeave:Connect(function()
        if currentTab ~= name then
            Tween:Create(btn, TweenInfo.new(0.12), { BackgroundTransparency = 1 }):Play()
        end
    end)
    btn.MouseButton1Click:Connect(function()
        if currentTab == name then return end
        for _, pg in pairs(pages) do pg.Visible = false end
        pages[name].Visible = true
        currentTab = name
        local targetY = 6 + (order - 1) * 40
        Tween:Create(indicator, TweenInfo.new(0.26, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, 6, 0, targetY)
        }):Play()
        for n, t in pairs(tabButtons) do
            local c = n == name and Color3.new(1,1,1) or Color3.fromRGB(190, 190, 210)
            t.lbl.TextColor3 = c
            t.ico.TextColor3 = c
        end
    end)
    return btn
end

-- 控件（优化版：更加圆润细腻）
local function createToggle(parent, name, def, cb)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(1, 0, 0, 42)
    btn.BackgroundColor3 = Color3.fromRGB(28, 28, 40)
    btn.BackgroundTransparency = 0.1
    btn.Text = ""; btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    local lbl = Instance.new("TextLabel", btn)
    lbl.Size = UDim2.new(1, -70, 1, 0); lbl.Position = UDim2.new(0, 14, 0, 0)
    lbl.BackgroundTransparency = 1; lbl.Text = name
    lbl.TextColor3 = Color3.fromRGB(235,235,245)
    lbl.Font = Enum.Font.GothamMedium; lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    local ind = Instance.new("Frame", btn)
    ind.Size = UDim2.new(0, 44, 0, 24)
    ind.Position = UDim2.new(1, -56, 0.5, -12)
    ind.BackgroundColor3 = Color3.fromRGB(50,50,65)
    ind.BorderSizePixel = 0
    Instance.new("UICorner", ind).CornerRadius = UDim.new(1, 0)
    local knob = Instance.new("Frame", ind)
    knob.Size = UDim2.new(0, 20, 0, 20)
    knob.Position = UDim2.new(0, 2, 0.5, -10)
    knob.BackgroundColor3 = Color3.new(1,1,1)
    knob.BorderSizePixel = 0
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
    local glow = Instance.new("Frame", ind)
    glow.Size = UDim2.new(1, 10, 1, 10)
    glow.Position = UDim2.new(0, -5, 0, -5)
    glow.BackgroundColor3 = Color3.fromRGB(190, 80, 255)
    glow.BackgroundTransparency = 0.6
    glow.BorderSizePixel = 0
    glow.Visible = false
    glow.ZIndex = 0
    Instance.new("UICorner", glow).CornerRadius = UDim.new(1, 0)
    local state = def or false
    local function refresh()
        Tween:Create(knob, TweenInfo.new(0.15), {
            Position = state and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
        }):Play()
        Tween:Create(ind, TweenInfo.new(0.15), {
            BackgroundColor3 = state and Color3.fromRGB(190, 80, 255) or Color3.fromRGB(50, 50, 65)
        }):Play()
        glow.Visible = state
        if state then
            if not ind:FindFirstChildOfClass("UIGradient") then
                local g = Instance.new("UIGradient", ind)
                g.Color = ColorSequence.new(Color3.fromRGB(168, 85, 247), Color3.fromRGB(236, 72, 153))
            end
        else
            local g = ind:FindFirstChildOfClass("UIGradient")
            if g then g:Destroy() end
        end
    end
    refresh()
    btn.MouseButton1Click:Connect(function()
        state = not state; refresh()
        if cb then pcall(cb, state) end
    end)
end

local function createSlider(parent, name, min, max, def, cb)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, 0, 0, 60)
    frame.BackgroundColor3 = Color3.fromRGB(28,28,40)
    frame.BackgroundTransparency = 0.1
    frame.BorderSizePixel = 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(1, -70, 0, 18); lbl.Position = UDim2.new(0, 14, 0, 6)
    lbl.BackgroundTransparency = 1; lbl.Text = name
    lbl.TextColor3 = Color3.fromRGB(235,235,245)
    lbl.Font = Enum.Font.GothamMedium; lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    local vLbl = Instance.new("TextLabel", frame)
    vLbl.Size = UDim2.new(0, 60, 0, 18); vLbl.Position = UDim2.new(1, -74, 0, 6)
    vLbl.BackgroundTransparency = 1; vLbl.Text = tostring(def)
    vLbl.TextColor3 = Color3.fromRGB(190,130,255)
    vLbl.Font = Enum.Font.GothamBold; vLbl.TextSize = 14
    vLbl.TextXAlignment = Enum.TextXAlignment.Right
    local track = Instance.new("TextButton", frame)
    track.Size = UDim2.new(1, -28, 0, 8); track.Position = UDim2.new(0, 14, 0, 36)
    track.BackgroundColor3 = Color3.fromRGB(50,50,65)
    track.Text = ""; track.BorderSizePixel = 0
    track.AutoButtonColor = false
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
    local fill = Instance.new("Frame", track)
    fill.Size = UDim2.new((def - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(168,85,247)
    fill.BorderSizePixel = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
    local fillGrad = Instance.new("UIGradient", fill)
    fillGrad.Color = ColorSequence.new(Color3.fromRGB(168, 85, 247), Color3.fromRGB(236, 72, 153))
    local dot = Instance.new("Frame", track)
    dot.Size = UDim2.new(0, 16, 0, 16)
    dot.Position = UDim2.new((def - min) / (max - min), -8, 0.5, -8)
    dot.BackgroundColor3 = Color3.new(1,1,1)
    dot.BorderSizePixel = 0
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
    local dotStroke = Instance.new("UIStroke", dot)
    dotStroke.Color = Color3.fromRGB(168, 85, 247); dotStroke.Thickness = 2
    local dg = false
    local function update(x)
        local pos = math.clamp((x - track.AbsolutePosition.X) / math.max(1, track.AbsoluteSize.X), 0, 1)
        local v = math.floor(min + pos * (max - min) + 0.5)
        fill.Size = UDim2.new(pos, 0, 1, 0)
        dot.Position = UDim2.new(pos, -8, 0.5, -8)
        vLbl.Text = tostring(v)
        if cb then pcall(cb, v) end
    end
    track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dg = true; update(i.Position.X)
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if dg and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            update(i.Position.X)
        end
    end)
    UIS.InputEnded:Connect(function() dg = false end)
end

local function createDropdown(parent, name, options, defIdx, cb)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(1, 0, 0, 42)
    btn.BackgroundColor3 = Color3.fromRGB(28,28,40)
    btn.BackgroundTransparency = 0.1
    btn.Text = ""; btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    local lbl = Instance.new("TextLabel", btn)
    lbl.Size = UDim2.new(1, -130, 1, 0); lbl.Position = UDim2.new(0, 14, 0, 0)
    lbl.BackgroundTransparency = 1; lbl.Text = name
    lbl.TextColor3 = Color3.fromRGB(235,235,245)
    lbl.Font = Enum.Font.GothamMedium; lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    local vBox = Instance.new("TextButton", btn)
    vBox.Size = UDim2.new(0, 110, 0, 28)
    vBox.Position = UDim2.new(1, -122, 0.5, -14)
    vBox.BackgroundColor3 = Color3.fromRGB(45,45,60)
    vBox.Text = options[defIdx or 1]
    vBox.TextColor3 = Color3.fromRGB(235,235,245)
    vBox.Font = Enum.Font.Gotham; vBox.TextSize = 12
    vBox.BorderSizePixel = 0
    vBox.AutoButtonColor = false
    Instance.new("UICorner", vBox).CornerRadius = UDim.new(0, 6)
    local idx = defIdx or 1
    vBox.MouseButton1Click:Connect(function()
        idx = idx % #options + 1
        vBox.Text = options[idx]
        if cb then pcall(cb, options[idx], idx) end
    end)
end

-- 页面
local pPlayer = createPage("玩家")
local pCombat = createPage("战斗")
local pAim    = createPage("自瞄")
local pEsp    = createPage("透视")
local pCar    = createPage("飞车")

createTab("玩家", "👤")
createTab("战斗", "⚔️")
createTab("自瞄", "🎯")
createTab("透视", "👁️")
createTab("飞车", "🚀")

for _, pg in pairs(pages) do pg.Visible = false end
pages["玩家"].Visible = true
currentTab = "玩家"
tabButtons["玩家"].lbl.TextColor3 = Color3.new(1,1,1)
tabButtons["玩家"].ico.TextColor3 = Color3.new(1,1,1)

createToggle(pPlayer, "无限体力", false, function(v) S.stamina = v end)
createToggle(pPlayer, "无限饥饿", false, function(v) S.food = v end)
createToggle(pPlayer, "防布娃娃", false, function(v) S.noRagdoll = v end)
createToggle(pPlayer, "防摔伤", false, function(v) S.noFallDamage = v end)
createToggle(pPlayer, "无限子弹", false, function(v) S.infiniteAmmo = v end)
createToggle(pPlayer, "快速射击", false, function(v) S.rapidFire = v end)
createToggle(pPlayer, "自动捡钱", false, function(v) S.autoMoney = v end)
createToggle(pPlayer, "自动农民", false, function(v) S.autoFarmer = v end)

createToggle(pCombat, "杀戮光环", false, function(v) S.auraEnabled = v end)
createToggle(pCombat, "拟人化延迟", true, function(v) S.auraHumanize = v end)
createToggle(pCombat, "静默模式", false, function(v) S.auraSilent = v end)
createSlider(pCombat, "光环范围", 50, 800, 200, function(v) S.auraRange = v end)
createSlider(pCombat, "光环伤害", 1, 100, 5, function(v) S.auraDamage = v end)
createToggle(pCombat, "自动铐", false, function(v) S.autoCuff = v end)

createToggle(pAim, "开启自瞄（右键触发）", false, function(v) S.aimbot.enabled = v end)
createToggle(pAim, "显示 FOV 圈", true, function(v) S.aimbot.showFov = v end)
createToggle(pAim, "显示追踪线", false, function(v) S.aimbot.showTracer = v end)
createDropdown(pAim, "FOV 颜色", {"红色", "绿色", "蓝色", "紫色", "白色"}, 1, function(v) S.aimbot.color = v end)
createSlider(pAim, "FOV 大小", 20, 400, 120, function(v) S.aimbot.fov = v end)
createSlider(pAim, "平滑度", 1, 10, 3, function(v) S.aimbot.smoothness = v / 10 end)

createToggle(pEsp, "开启透视", false, function(v) S.esp.enabled = v end)
createToggle(pEsp, "显示名字", true, function(v) S.esp.name = v end)
createToggle(pEsp, "显示职业", true, function(v) S.esp.team = v end)
createToggle(pEsp, "显示距离", true, function(v) S.esp.distance = v end)
createToggle(pEsp, "显示血量", true, function(v) S.esp.health = v end)
createToggle(pEsp, "显示血条", true, function(v) S.esp.bar = v end)
createToggle(pEsp, "显示高亮", true, function(v) S.esp.highlight = v end)

createToggle(pCar, "飞行模式", false, function(v)
    S.flyEnabled = v
    if v then startFly() else stopFly() end
end)
createToggle(pCar, "穿墙 (Noclip)", false, function(v)
    S.noclip = v
    if v then startNoclip() else stopNoclip() end
end)
createDropdown(pCar, "飞行模式", {"传送", "物理"}, 1, function(v)
    S.flyMode = v
    if S.flyEnabled then
        S.flyEnabled = false
        task.wait(0.1)
        S.flyEnabled = true
        startFly()
    end
end)
createSlider(pCar, "飞行速度", 10, 300, 50, function(v) S.flySpeed = v end)
createSlider(pCar, "跳跃高度", 50, 400, 100, function(v) S.jumpPower = v end)

ok("UI 构建完成")

-- ============================================================
-- 加载动画（居中单卡片）
-- ============================================================
inf("播放居中加载动画")

local loading = Instance.new("Frame", screen)
loading.Size = UDim2.new(1, 0, 1, 0)
loading.BackgroundColor3 = Color3.fromRGB(8, 8, 14)
loading.BackgroundTransparency = 0
loading.BorderSizePixel = 0
loading.ZIndex = 100

local lBg = Instance.new("UIGradient", loading)
lBg.Rotation = 135
lBg.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 8, 35)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(8, 8, 14)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 8, 30)),
})

local lCard = Instance.new("Frame", loading)
lCard.Size = UDim2.new(0, 340, 0, 200)
lCard.Position = UDim2.new(0.5, -170, 0.5, -100)
lCard.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
lCard.BackgroundTransparency = 0.1
lCard.BorderSizePixel = 0
lCard.ZIndex = 101
Instance.new("UICorner", lCard).CornerRadius = UDim.new(0, 16)

local lCardStroke = Instance.new("UIStroke", lCard)
lCardStroke.Color = Color3.fromRGB(168, 85, 247)
lCardStroke.Thickness = 2
local lCardGrad = Instance.new("UIGradient", lCardStroke)
lCardGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(168, 85, 247)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(236, 72, 153)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(56, 189, 248)),
})
task.spawn(function()
    while screen.Parent do
        lCardGrad.Rotation = (lCardGrad.Rotation + 2) % 360
        task.wait(0.05)
    end
end)

local lLogo = Instance.new("Frame", lCard)
lLogo.Size = UDim2.new(0, 0, 0, 0)
lLogo.Position = UDim2.new(0.5, -35, 0, 18)
lLogo.BackgroundColor3 = Color3.new(1,1,1)
lLogo.BorderSizePixel = 0
lLogo.ZIndex = 102
Instance.new("UICorner", lLogo).CornerRadius = UDim.new(0, 14)
local lLogoGrad = Instance.new("UIGradient", lLogo)
lLogoGrad.Rotation = 45
lLogoGrad.Color = ColorSequence.new(Color3.fromRGB(236,72,153), Color3.fromRGB(168,85,247))
local lLogoTxt = Instance.new("TextLabel", lLogo)
lLogoTxt.Size = UDim2.new(1,0,1,0); lLogoTxt.BackgroundTransparency = 1
lLogoTxt.Text = "嘉"; lLogoTxt.TextColor3 = Color3.new(1,1,1)
lLogoTxt.Font = Enum.Font.GothamBlack; lLogoTxt.TextSize = 36
lLogoTxt.ZIndex = 103

local lTitle = Instance.new("TextLabel", lCard)
lTitle.Size = UDim2.new(1, 0, 0, 22)
lTitle.Position = UDim2.new(0, 0, 0, 86)
lTitle.BackgroundTransparency = 1
lTitle.Text = "XJ HUB 1.0 beta"
lTitle.TextColor3 = Color3.new(1,1,1)
lTitle.Font = Enum.Font.GothamBold
lTitle.TextSize = 17
lTitle.ZIndex = 102

local lSub = Instance.new("TextLabel", lCard)
lSub.Size = UDim2.new(1, 0, 0, 14)
lSub.Position = UDim2.new(0, 0, 0, 108)
lSub.BackgroundTransparency = 1
lSub.Text = "作者: 嘉酱"
lSub.TextColor3 = Color3.fromRGB(190, 190, 210)
lSub.Font = Enum.Font.Gotham
lSub.TextSize = 11
lSub.ZIndex = 102

local lBarBg = Instance.new("Frame", lCard)
lBarBg.Size = UDim2.new(1, -60, 0, 4)
lBarBg.Position = UDim2.new(0, 30, 0, 138)
lBarBg.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
lBarBg.BorderSizePixel = 0
lBarBg.ZIndex = 102
Instance.new("UICorner", lBarBg).CornerRadius = UDim.new(1, 0)

local lBarFill = Instance.new("Frame", lBarBg)
lBarFill.Size = UDim2.new(0, 0, 1, 0)
lBarFill.BackgroundColor3 = Color3.fromRGB(168, 85, 247)
lBarFill.BorderSizePixel = 0
lBarFill.ZIndex = 103
Instance.new("UICorner", lBarFill).CornerRadius = UDim.new(1, 0)
local lBarGrad = Instance.new("UIGradient", lBarFill)
lBarGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(236, 72, 153)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(56, 189, 248)),
})

local lStatus = Instance.new("TextLabel", lCard)
lStatus.Size = UDim2.new(1, -60, 0, 16)
lStatus.Position = UDim2.new(0, 30, 0, 156)
lStatus.BackgroundTransparency = 1
lStatus.Text = "初始化..."
lStatus.TextColor3 = Color3.fromRGB(200, 200, 220)
lStatus.Font = Enum.Font.GothamMedium
lStatus.TextSize = 12
lStatus.TextXAlignment = Enum.TextXAlignment.Left
lStatus.ZIndex = 102

local lPct = Instance.new("TextLabel", lCard)
lPct.Size = UDim2.new(1, -60, 0, 16)
lPct.Position = UDim2.new(0, 30, 0, 156)
lPct.BackgroundTransparency = 1
lPct.Text = "0%"
lPct.TextColor3 = Color3.fromRGB(190, 130, 255)
lPct.Font = Enum.Font.GothamBold
lPct.TextSize = 12
lPct.TextXAlignment = Enum.TextXAlignment.Right
lPct.ZIndex = 102

local steps = {
    { text = "初始化运行环境", pct = 20 },
    { text = "注入绕过保护", pct = 40 },
    { text = "加载核心模块", pct = 60 },
    { text = "构建 UI 界面", pct = 80 },
    { text = "准备就绪", pct = 100 },
}

task.spawn(function()
    lLogo.Size = UDim2.new(0, 0, 0, 0)
    Tween:Create(lLogo, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 70, 0, 70)
    }):Play()
    task.wait(0.45)

    for _, s in ipairs(steps) do
        lStatus.Text = s.text
        lPct.Text = s.pct .. "%"
        Tween:Create(lBarFill, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(s.pct / 100, 0, 1, 0)
        }):Play()
        task.wait(0.32)
    end

    task.wait(0.25)

    Tween:Create(loading, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundTransparency = 1
    }):Play()
    Tween:Create(lCard, TweenInfo.new(0.35), { BackgroundTransparency = 1 }):Play()
    Tween:Create(lCardStroke, TweenInfo.new(0.35), { Transparency = 1 }):Play()
    for _, d in ipairs(lCard:GetDescendants()) do
        if d:IsA("TextLabel") then
            Tween:Create(d, TweenInfo.new(0.3), { TextTransparency = 1 }):Play()
        end
    end

    task.wait(0.4)
    loading:Destroy()

    main.Visible = true
    main.Size = UDim2.new(0, 100, 0, 80)
    Tween:Create(main, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 540, 0, 400)
    }):Play()

    inf("加载动画播放完成")
end)

ok("加载动画已启动")
inf("=========================================")
inf("XJ Hub · 深度绕过版 加载完成")
inf("=========================================")
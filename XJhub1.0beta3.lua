-- ============================================================
-- XJ Hub 1.0 beta  |  作者: 嘉酱  |  图标: 嘉
-- 小尺寸 · 流畅优化 · 8大分类 · 自检全覆盖
-- ============================================================

local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local RunSvc  = game:GetService("RunService")
local UIS     = game:GetService("UserInputService")
local Tween   = game:GetService("TweenService")
local WS      = game:GetService("Workspace")
local HTTP    = game:GetService("HttpService")
local LP      = Players.LocalPlayer

local function L(s, m) print(("[XJ] %s %s"):format(s, m)) end
local function ok(m) L("✅", m) end
local function no(m) L("❌", m) end
local function inf(m) L("ℹ️", m) end

inf("XJ Hub 1.0 beta 开始加载")
inf("执行器: " .. ((identifyexecutor and identifyexecutor()) or "unknown"))

-- ============== 状态表 ==============
local S = {
    stamina = false, food = false, noRagdoll = false, noFallDamage = false,
    infiniteAmmo = false, rapidFire = false,
    autoMoney = false, autoFarmer = false, autoMission = false,
    auraEnabled = false, auraRange = 200, auraDamage = 5,
    speedEnabled = false, speedValue = 100,
    jumpEnabled = false, jumpPower = 100, infiniteJump = false,
    flyEnabled = false, flySpeed = 50, flyMode = "传送",
    noclip = false,
    aimbot = {
        enabled = false, fov = 120, smoothness = 0.3, targetPart = "头部",
        wallCheck = false, friendCheck = false, teamCheck = false,
        filter = "全部", prediction = false,
        showFov = true, showTracer = false, color = "红色",
    },
    esp = {
        enabled = false, name = true, distance = true, health = true,
        team = true, highlight = true, colorByTeam = true, bar = true,
    },
}

-- ============== 反作弊绕过 ==============
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
                or first == "DEBUG2" or first == "chatCommand" or first == "controlsGuide" then
                return
            end
            if S.noFallDamage and first == "takeDamage" then return nil end
        end
        if method == "InvokeServer" and self.Name == "PlayerFunc" then
            local first = packed[1]
            if first == "getPlayerData" or first == "getPlayerBanHistory"
                or first == "getPlayerInGame" or first == "getPlayerServerEncounters"
                or first == "getSecret" then
                return true
            end
        end
        return orig(self, table.unpack(packed, 1, packed.n))
    end))
    ok("远程拦截 + 防摔伤 hook")
end

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
        ok("AntiCheat 包裹")
    end
end)

pcall(function()
    local Ratchet = require(RS:FindFirstChild("Ratchet", true))
    local Sha256  = require(RS:FindFirstChild("Sha256", true))
    local mt = getmetatable(Ratchet)
    if mt and mt.__index and not mt.__index.__xj_patched then
        mt.__index.catchUp = function(self, target)
            while self.index < target do self:advance() end
            return true
        end
        mt.__index.respond = function(self, arg)
            return Sha256("resp|" .. tostring(self.state) .. "|" .. tostring(self.index) .. "|" .. tostring(arg))
        end
        mt.__index.__xj_patched = true
    end
    ok("Ratchet 补丁")
end)

-- ============== 环境自检 ==============
local ENV = {
    loadstring = type(loadstring) == "function",
    getgc = type(getgc) == "function",
    hookmetamethod = type(hookmetamethod) == "function",
    newcclosure = type(newcclosure) == "function",
    fireproximityprompt = type(fireproximityprompt) == "function",
    Drawing = type(Drawing) ~= "nil",
    writefile = type(writefile) == "function",
    getcustomasset = type(getcustomasset) == "function",
}
for k, v in pairs(ENV) do
    if v then ok("环境: " .. k) else no("缺失: " .. k) end
end

local remote = RS:WaitForChild("Remote", 10)
local playerEvent = remote and remote:WaitForChild("PlayerEvent", 10)
local playerFunc  = remote and remote:WaitForChild("PlayerFunc", 10)
if playerEvent then ok("PlayerEvent") else no("PlayerEvent") end
if playerFunc  then ok("PlayerFunc")  else no("PlayerFunc")  end

local Core, Character, Controls
pcall(function()
    local fw = LP:WaitForChild("PlayerScripts", 10):WaitForChild("Framework", 10)
    Core = require(fw:WaitForChild("Core", 10))
    Character = require(fw:WaitForChild("Character", 10))
end)
pcall(function()
    Controls = require(LP.PlayerScripts:WaitForChild("PlayerModule")):GetControls()
end)
if Core then ok("Core") else no("Core") end
if Character then ok("Character") else no("Character") end
if Controls then ok("Controls") else no("Controls") end

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
local function teamColor(p)
    local n = p.Team and p.Team.Name
    return (n and TEAM_COLORS[n]) or Color3.fromRGB(200, 200, 200)
end
local function teamLabel(p)
    local n = p.Team and p.Team.Name
    return (n and TEAM_NAMES[n]) or (n or "无")
end

-- ============== 核心循环（合并到一个 Heartbeat，减少开销） ==============
local coreTick = 0
local auraTick = 0
RunSvc.Heartbeat:Connect(function(dt)
    -- 体力/饥饿/子弹（每 0.1 秒检测一次）
    if tick() - coreTick > 0.1 then
        coreTick = tick()
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
                        local a = cfg:FindFirstChild("Ammo")
                        local t = cfg:FindFirstChild("TotalAmmo")
                        if a then a.Value = math.huge end
                        if t then t.Value = math.huge end
                    end
                end
            end
        end
    end

    -- 行走速度（每 0.2 秒）
    if S.speedEnabled then
        local _, h = getChar()
        if h then h.WalkSpeed = S.speedValue end
    end

    -- 杀戮光环（每 0.05 秒）
    if S.auraEnabled and playerEvent and tick() - auraTick > 0.05 then
        auraTick = tick()
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
end)
ok("核心循环（合并优化）")

-- ============== 防布娃娃 ==============
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
    ok("防布娃娃 hook")
end)

-- ============== 自动捡钱 / 农民（合并为一个循环） ==============
task.spawn(function()
    while screen == nil or screen.Parent do
        if (S.autoMoney or S.autoFarmer) and fireproximityprompt then
            local _, _, r = getChar()
            if r then
                local best, bd = nil, math.huge
                for _, d in ipairs(WS:GetDescendants()) do
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
                if best then pcall(fireproximityprompt, best, 0) end
            end
        end
        task.wait(0.5)
    end
end)
ok("自动捡钱 / 农民")

-- ============== 自瞄（只在开启时运行） ==============
local PART_MAP = {
    ["头部"] = {"Head"}, ["胸部"] = {"UpperTorso", "Torso"},
    ["左手"] = {"LeftHand", "Left Arm"}, ["右手"] = {"RightHand", "Right Arm"},
    ["左腿"] = {"LeftFoot", "Left Leg"}, ["右腿"] = {"RightFoot", "Right Leg"},
}
local function getTargetPart(char)
    local list = PART_MAP[S.aimbot.targetPart] or {"Head"}
    for _, n in ipairs(list) do
        local p = char:FindFirstChild(n)
        if p then return p end
    end
    return char:FindFirstChild("HumanoidRootPart")
end
local function filterMatch(p)
    if S.aimbot.filter == "全部" then return true end
    local t = (p.Team and p.Team.Name) or ""
    if S.aimbot.filter == "只警察" then return t == "Police" end
    if S.aimbot.filter == "只平民" then return t == "Civilian" end
    if S.aimbot.filter == "只船员" then return t == "Civilian" or t == "Delivery" or t == "Transit" end
    if S.aimbot.filter == "只囚犯" then return t == "Prisoner" end
    return true
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
if fovCircle then
    fovCircle.Filled = false; fovCircle.NumSides = 48; fovCircle.Visible = false
end
local tracerLine = Drawing and Drawing.new("Line")

local function hasWall(targetPart, targetChar)
    if not S.aimbot.wallCheck then return true end
    local cam = WS.CurrentCamera
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = { LP.Character, cam }
    params.FilterType = Enum.RaycastFilterType.Exclude
    local hit = WS:Raycast(cam.CFrame.Position, targetPart.Position - cam.CFrame.Position, params)
    return not hit or hit.Instance:IsDescendantOf(targetChar)
end

RunSvc.RenderStepped:Connect(function(dt)
    if not S.aimbot.enabled and not S.aimbot.showFov then
        if fovCircle then fovCircle.Visible = false end
        if tracerLine then tracerLine.Visible = false end
        return
    end
    local cam = WS.CurrentCamera
    if not cam then return end
    local center = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y/2)
    if fovCircle then
        fovCircle.Position = center
        fovCircle.Radius = S.aimbot.fov
        fovCircle.Thickness = 2
        fovCircle.Color = aimColor()
        fovCircle.Visible = S.aimbot.enabled and S.aimbot.showFov
    end
    if not S.aimbot.enabled then
        if tracerLine then tracerLine.Visible = false end
        return
    end
    local tgt, bd = nil, S.aimbot.fov
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and filterMatch(p) then
            if not (S.aimbot.teamCheck and LP.Team and p.Team == LP.Team) then
                local skip = false
                if S.aimbot.friendCheck then
                    local ok2, r = pcall(function() return LP:IsFriendsWith(p.UserId) end)
                    if ok2 and r then skip = true end
                end
                if not skip then
                    local c, h = getChar(p)
                    if c and h and h.Health > 0 then
                        local part = getTargetPart(c)
                        if part and hasWall(part, c) then
                            local sp, on = cam:WorldToViewportPoint(part.Position)
                            if on then
                                local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                                if d < bd then tgt, bd = part, d end
                            end
                        end
                    end
                end
            end
        end
    end
    if tgt then
        if S.aimbot.showTracer and tracerLine then
            local sp = cam:WorldToViewportPoint(tgt.Position)
            tracerLine.From = center
            tracerLine.To = Vector2.new(sp.X, sp.Y)
            tracerLine.Color = aimColor()
            tracerLine.Thickness = 2
            tracerLine.Transparency = 0.5
            tracerLine.Visible = true
        elseif tracerLine then
            tracerLine.Visible = false
        end
        local pos = tgt.Position
        if S.aimbot.prediction then pos = pos + tgt.AssemblyLinearVelocity * dt * 1.5 end
        local goal = CFrame.new(cam.CFrame.Position, pos)
        cam.CFrame = S.aimbot.smoothness >= 1 and goal or cam.CFrame:Lerp(goal, S.aimbot.smoothness)
    else
        if tracerLine then tracerLine.Visible = false end
    end
end)
ok("自瞄")

-- ============== 飞车 ==============
local FlyState = {
    flyConn = nil, bodyVel = nil, bodyGyro = nil,
    noclipConn = nil, collisionCache = {},
}

local function stopFly()
    if FlyState.flyConn then FlyState.flyConn:Disconnect(); FlyState.flyConn = nil end
    if FlyState.bodyVel then FlyState.bodyVel:Destroy(); FlyState.bodyVel = nil end
    if FlyState.bodyGyro then FlyState.bodyGyro:Destroy(); FlyState.bodyGyro = nil end
    local _, h = getChar()
    if h then h.PlatformStand = false; h.AutoRotate = true end
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
            if not S.flyEnabled or S.flyMode ~= "物理" then return end
            local _, h2, r2 = getChar()
            local cam = WS.CurrentCamera
            if not r2 or not h2 or not cam then return end
            if FlyState.bodyVel and FlyState.bodyGyro then
                local mv = Controls and Controls:GetMoveVector() or Vector3.zero
                local dir = cam.CFrame.LookVector * -mv.Z + cam.CFrame.RightVector * mv.X
                local y = UIS:IsKeyDown(Enum.KeyCode.Space) and 1
                    or (UIS:IsKeyDown(Enum.KeyCode.LeftControl) and -1 or 0)
                FlyState.bodyVel.Velocity = (dir + Vector3.new(0, y, 0)) * S.flySpeed
                FlyState.bodyGyro.CFrame = cam.CFrame
            end
        end)
    else
        FlyState.flyConn = RunSvc.RenderStepped:Connect(function(dt)
            if not S.flyEnabled or S.flyMode ~= "传送" then return end
            local _, h2, r2 = getChar()
            local cam = WS.CurrentCamera
            if not r2 or not h2 or not cam then return end
            local mv = Controls and Controls:GetMoveVector() or Vector3.zero
            local dir = cam.CFrame.LookVector * -mv.Z + cam.CFrame.RightVector * mv.X
            local y = UIS:IsKeyDown(Enum.KeyCode.Space) and 1
                or (UIS:IsKeyDown(Enum.KeyCode.LeftControl) and -1 or 0)
            r2.CFrame = r2.CFrame + (dir + Vector3.new(0, y, 0)) * S.flySpeed * dt
            r2.AssemblyLinearVelocity = Vector3.zero
            r2.AssemblyAngularVelocity = Vector3.zero
            h2:ChangeState(Enum.HumanoidStateType.Climbing)
        end)
    end
end

local function stopNoclip()
    if FlyState.noclipConn then FlyState.noclipConn:Disconnect(); FlyState.noclipConn = nil end
    for part, saved in pairs(FlyState.collisionCache) do
        if part and part.Parent then pcall(function() part.CanCollide = saved end) end
    end
    FlyState.collisionCache = {}
end

local function startNoclip()
    stopNoclip()
    FlyState.noclipConn = RunSvc.Stepped:Connect(function()
        if not S.noclip then return end
        local c = LP.Character
        if not c then return end
        for _, d in ipairs(c:GetDescendants()) do
            if d:IsA("BasePart") then
                if FlyState.collisionCache[d] == nil then FlyState.collisionCache[d] = d.CanCollide end
                d.CanCollide = false
            end
        end
    end)
end

UIS.JumpRequest:Connect(function()
    if not S.jumpEnabled then return end
    local _, h, r = getChar()
    if not h or not r or h.Health <= 0 then return end
    local st = h:GetState()
    local onGround = st == Enum.HumanoidStateType.Landed
        or st == Enum.HumanoidStateType.Running
        or st == Enum.HumanoidStateType.RunningNoPhysics
    if not S.infiniteJump and not onGround then return end
    r.CFrame = r.CFrame + Vector3.new(0, S.jumpPower * 0.1, 0)
end)

LP.CharacterAdded:Connect(function()
    task.wait(0.5)
    FlyState.collisionCache = {}
    if S.noclip then startNoclip() end
    if S.flyEnabled then
        local m = S.flyMode
        S.flyEnabled = false
        task.wait(0.2)
        S.flyMode = m
        S.flyEnabled = true
        startFly()
    end
end)
ok("飞车模块")

-- ============== ESP（0.1s 循环优化） ==============
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

    local line1 = Instance.new("TextLabel")
    line1.Size = UDim2.new(1, 0, 0, 14)
    line1.Position = UDim2.new(0, 0, 0, 0)
    line1.BackgroundTransparency = 1
    line1.Font = Enum.Font.GothamBold
    line1.TextSize = 12
    line1.TextColor3 = Color3.fromRGB(255, 255, 255)
    line1.TextStrokeTransparency = 0
    line1.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    line1.Parent = bill

    local line2 = Instance.new("TextLabel")
    line2.Size = UDim2.new(1, 0, 0, 12)
    line2.Position = UDim2.new(0, 0, 0, 15)
    line2.BackgroundTransparency = 1
    line2.Font = Enum.Font.GothamBold
    line2.TextSize = 10
    line2.TextColor3 = Color3.fromRGB(230, 230, 230)
    line2.TextStrokeTransparency = 0
    line2.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    line2.Parent = bill

    local hpBg = Instance.new("Frame")
    hpBg.Size = UDim2.new(1, -14, 0, 2)
    hpBg.Position = UDim2.new(0, 7, 1, -2)
    hpBg.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    hpBg.BackgroundTransparency = 0.2
    hpBg.BorderSizePixel = 0
    hpBg.Parent = bill
    Instance.new("UICorner", hpBg).CornerRadius = UDim.new(1, 0)

    local hpFill = Instance.new("Frame")
    hpFill.Size = UDim2.new(1, 0, 1, 0)
    hpFill.BackgroundColor3 = Color3.fromRGB(60, 220, 100)
    hpFill.BorderSizePixel = 0
    hpFill.Parent = hpBg
    Instance.new("UICorner", hpFill).CornerRadius = UDim.new(1, 0)

    local hl = Instance.new("Highlight")
    hl.Name = "XJ_ESP_HL"
    hl.Adornee = char
    hl.FillTransparency = 0.85
    hl.OutlineTransparency = 0
    pcall(function() hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop end)
    hl.Parent = char

    return { bill = bill, line1 = line1, line2 = line2, hpBg = hpBg, hpFill = hpFill, hl = hl }
end

task.spawn(function()
    while screen == nil or screen.Parent do
        if S.esp.enabled then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LP then
                    local c, h, r = getChar(p)
                    if c and h and r and h.Health > 0 then
                        if not espCache[p] then espCache[p] = buildESP(p, c, r) end
                        local e = espCache[p]
                        e.bill.Adornee = r
                        if e.hl.Parent ~= c then e.hl.Parent = c end
                        e.hl.Adornee = c
                        local tc = S.esp.colorByTeam and teamColor(p) or Color3.fromRGB(168, 85, 247)
                        e.hl.FillColor = tc
                        e.hl.OutlineColor = tc
                        e.hl.Enabled = S.esp.highlight
                        local n = p.Name
                        if S.esp.team then n = "[" .. teamLabel(p) .. "] " .. n end
                        e.line1.Text = n
                        e.line1.TextColor3 = tc
                        e.line1.Visible = S.esp.name
                        local parts = {}
                        if S.esp.distance then
                            local _, _, mr = getChar()
                            if mr then table.insert(parts, math.floor((mr.Position - r.Position).Magnitude) .. "m") end
                        end
                        if S.esp.health then table.insert(parts, math.floor(h.Health) .. "/" .. math.floor(h.MaxHealth)) end
                        e.line2.Text = table.concat(parts, " · ")
                        e.line2.Visible = S.esp.distance or S.esp.health
                        if S.esp.bar then
                            e.hpBg.Visible = true
                            e.hpFill.Size = UDim2.new(math.clamp(h.Health / h.MaxHealth, 0, 1), 0, 1, 0)
                            local hp = h.Health / h.MaxHealth
                            if hp > 0.6 then e.hpFill.BackgroundColor3 = Color3.fromRGB(60, 220, 100)
                            elseif hp > 0.3 then e.hpFill.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
                            else e.hpFill.BackgroundColor3 = Color3.fromRGB(255, 60, 60) end
                        else
                            e.hpBg.Visible = false
                        end
                    else
                        if espCache[p] then
                            if espCache[p].bill then espCache[p].bill:Destroy() end
                            if espCache[p].hl then espCache[p].hl:Destroy() end
                            espCache[p] = nil
                        end
                    end
                end
            end
        else
            if next(espCache) then
                for p, obj in pairs(espCache) do
                    if obj.bill then obj.bill:Destroy() end
                    if obj.hl then obj.hl:Destroy() end
                    espCache[p] = nil
                end
            end
        end
        task.wait(0.1)
    end
end)
ok("ESP（0.1s 循环）")

-- ============================================================
-- UI 构建（小尺寸版）
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

-- 主窗口：520×380（小屏适配）
local main = Instance.new("Frame")
main.Size = UDim2.new(0, 520, 0, 380)
main.Position = UDim2.new(0.5, -260, 0.5, -190)
main.BackgroundColor3 = Color3.fromRGB(16, 16, 22)
main.BorderSizePixel = 0
main.ClipsDescendants = true
main.Parent = screen
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 14)

local mainStroke = Instance.new("UIStroke", main)
mainStroke.Color = Color3.fromRGB(168, 85, 247)
mainStroke.Thickness = 2
mainStroke.Transparency = 0
local strokeGrad = Instance.new("UIGradient", mainStroke)
strokeGrad.Rotation = 0
strokeGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(168, 85, 247)),
    ColorSequenceKeypoint.new(0.33, Color3.fromRGB(236, 72, 153)),
    ColorSequenceKeypoint.new(0.66, Color3.fromRGB(56, 189, 248)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(168, 85, 247)),
})
task.spawn(function()
    while screen.Parent do
        strokeGrad.Rotation = (strokeGrad.Rotation + 1.2) % 360
        task.wait(0.05)
    end
end)
ok("流光描边")

-- 随机动漫背景
local bgImage = Instance.new("ImageLabel")
bgImage.Size = UDim2.new(1, 0, 1, 0)
bgImage.BackgroundTransparency = 1
bgImage.ImageTransparency = 0.45
bgImage.ScaleType = Enum.ScaleType.Crop
bgImage.ZIndex = 0
bgImage.Parent = main

local darkOverlay = Instance.new("Frame")
darkOverlay.Size = UDim2.new(1, 0, 1, 0)
darkOverlay.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
darkOverlay.BackgroundTransparency = 0.4
darkOverlay.BorderSizePixel = 0
darkOverlay.ZIndex = 1
darkOverlay.Parent = main

local function tryLoadAnimeBg()
    if not (game.HttpGet and writefile and getcustomasset) then return false end
    local apis = {
        { url = "https://api.waifu.pics/sfw/waifu", key = function(d) return d.url end },
        { url = "https://nekos.best/api/v2/neko", key = function(d) return d.results and d.results[1] and d.results[1].url end },
    }
    for _, api in ipairs(apis) do
        local okReq, res = pcall(game.HttpGet, game, api.url)
        if okReq and res and #res > 10 then
            local okDec, data = pcall(HTTP.JSONDecode, HTTP, res)
            if okDec and data then
                local url = api.key(data)
                if url and type(url) == "string" then
                    local okImg, imgData = pcall(game.HttpGet, game, url)
                    if okImg and imgData and #imgData > 1000 then
                        local ext = url:match("%.(%w+)$") or "png"
                        local fn = "xj_bg_" .. tostring(os.time()) .. "_" .. tostring(math.random(1, 99999)) .. "." .. ext
                        pcall(writefile, fn, imgData)
                        local okA, asset = pcall(getcustomasset, fn)
                        if okA and asset then
                            bgImage.Image = asset
                            return true
                        end
                    end
                end
            end
        end
    end
    return false
end

task.spawn(function()
    local loaded = tryLoadAnimeBg()
    if loaded then
        ok("随机动漫背景")
    else
        inf("背景使用渐变")
        bgImage:Destroy()
        darkOverlay:Destroy()
        main.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
        local grad = Instance.new("UIGradient")
        grad.Rotation = 45
        grad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(45, 25, 75)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(18, 18, 28)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(60, 30, 90)),
        })
        grad.Parent = main
    end
end)

-- ============== 标题栏 ==============
local topbar = Instance.new("Frame")
topbar.Size = UDim2.new(1, 0, 0, 52)
topbar.BackgroundColor3 = Color3.fromRGB(24, 24, 34)
topbar.BackgroundTransparency = 0.15
topbar.BorderSizePixel = 0
topbar.ZIndex = 2
topbar.Parent = main
Instance.new("UICorner", topbar).CornerRadius = UDim.new(0, 14)

local logo = Instance.new("Frame")
logo.Size = UDim2.new(0, 36, 0, 36)
logo.Position = UDim2.new(0, 10, 0.5, -18)
logo.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
logo.BorderSizePixel = 0
logo.ZIndex = 3
logo.Parent = topbar
Instance.new("UICorner", logo).CornerRadius = UDim.new(0, 9)
local logoGrad = Instance.new("UIGradient", logo)
logoGrad.Rotation = 45
logoGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(236, 72, 153)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(168, 85, 247)),
})
local logoLbl = Instance.new("TextLabel")
logoLbl.Size = UDim2.new(1, 0, 1, 0)
logoLbl.BackgroundTransparency = 1
logoLbl.Text = "嘉"
logoLbl.TextColor3 = Color3.new(1, 1, 1)
logoLbl.Font = Enum.Font.GothamBlack
logoLbl.TextSize = 19
logoLbl.ZIndex = 4
logoLbl.Parent = logo

local title = Instance.new("TextLabel")
title.Size = UDim2.new(0, 300, 0, 20)
title.Position = UDim2.new(0, 56, 0, 8)
title.BackgroundTransparency = 1
title.Text = "XJ HUB 1.0 beta"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 3
title.Parent = topbar

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(0, 300, 0, 14)
subtitle.Position = UDim2.new(0, 56, 0, 28)
subtitle.BackgroundTransparency = 1
subtitle.Text = "作者: 嘉酱"
subtitle.TextColor3 = Color3.fromRGB(190, 190, 210)
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = 11
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.ZIndex = 3
subtitle.Parent = topbar

task.spawn(function()
    local hue = 0
    while screen.Parent do
        hue = (hue + 0.005) % 1
        title.TextColor3 = Color3.fromHSV(hue, 0.7, 1)
        task.wait(0.05)
    end
end)

local blockDrag = false

local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 28, 0, 28)
minBtn.Position = UDim2.new(1, -70, 0.5, -14)
minBtn.BackgroundColor3 = Color3.fromRGB(251, 191, 36)
minBtn.Text = "－"
minBtn.TextColor3 = Color3.new(1, 1, 1)
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 18
minBtn.BorderSizePixel = 0
minBtn.AutoButtonColor = false
minBtn.ZIndex = 3
minBtn.Parent = topbar
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 7)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 28, 0, 28)
closeBtn.Position = UDim2.new(1, -38, 0.5, -14)
closeBtn.BackgroundColor3 = Color3.fromRGB(239, 68, 68)
closeBtn.Text = "×"
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 20
closeBtn.BorderSizePixel = 0
closeBtn.AutoButtonColor = false
closeBtn.ZIndex = 3
closeBtn.Parent = topbar
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 7)

local function blockTopbarDrag(btn)
    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            blockDrag = true
        end
    end)
    btn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            blockDrag = false
        end
    end)
end
blockTopbarDrag(minBtn)
blockTopbarDrag(closeBtn)

-- ============== 悬浮球 ==============
local bubble = Instance.new("TextButton")
bubble.Size = UDim2.new(0, 50, 0, 50)
bubble.Position = UDim2.new(0, 20, 0.5, -25)
bubble.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
bubble.Text = ""
bubble.BorderSizePixel = 0
bubble.AutoButtonColor = false
bubble.Visible = false
bubble.ZIndex = 10
bubble.Parent = screen
Instance.new("UICorner", bubble).CornerRadius = UDim.new(1, 0)
local bubbleGrad = Instance.new("UIGradient", bubble)
bubbleGrad.Rotation = 45
bubbleGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(236, 72, 153)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(168, 85, 247)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(56, 189, 248)),
})
task.spawn(function()
    while screen.Parent do
        if bubble.Visible then
            bubbleGrad.Rotation = (bubbleGrad.Rotation + 1.5) % 360
        end
        task.wait(0.05)
    end
end)
local bubbleStroke = Instance.new("UIStroke", bubble)
bubbleStroke.Color = Color3.fromRGB(255, 255, 255)
bubbleStroke.Thickness = 2
bubbleStroke.Transparency = 0.3
local bubbleLbl = Instance.new("TextLabel", bubble)
bubbleLbl.Size = UDim2.new(1, 0, 1, 0)
bubbleLbl.BackgroundTransparency = 1
bubbleLbl.Text = "嘉"
bubbleLbl.TextColor3 = Color3.new(1, 1, 1)
bubbleLbl.Font = Enum.Font.GothamBlack
bubbleLbl.TextSize = 24
bubbleLbl.ZIndex = 11

local bDragging, bDragStart, bStartPos = false, nil, nil
local bHasMoved = false

bubble.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        bDragging = true
        bDragStart = input.Position
        bStartPos = bubble.Position
        bHasMoved = false
    end
end)
UIS.InputChanged:Connect(function(input)
    if bDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local d = input.Position - bDragStart
        if math.abs(d.X) > 5 or math.abs(d.Y) > 5 then bHasMoved = true end
        bubble.Position = UDim2.new(bStartPos.X.Scale, bStartPos.X.Offset + d.X, bStartPos.Y.Scale, bStartPos.Y.Offset + d.Y)
    end
end)

local minimized = false
local savedPos = nil

local function minimize()
    if minimized then return end
    minimized = true
    savedPos = main.Position
    Tween:Create(main, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 80, 0, 60),
    }):Play()
    task.wait(0.2)
    main.Visible = false
    bubble.Visible = true
    inf("已最小化")
end

local function restore()
    if not minimized then return end
    minimized = false
    bubble.Visible = false
    main.Visible = true
    if savedPos then main.Position = savedPos end
    main.Size = UDim2.new(0, 80, 0, 60)
    Tween:Create(main, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 520, 0, 380),
    }):Play()
    inf("已恢复")
end

UIS.InputEnded:Connect(function(input)
    if bDragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
        bDragging = false
        if not bHasMoved then pcall(restore) end
    end
end)

minBtn.MouseButton1Click:Connect(minimize)
closeBtn.MouseButton1Click:Connect(function() screen:Destroy() end)
ok("最小化 / 恢复")

-- ============== 拖拽 ==============
local dragging, dragStart, startPos = false, nil, nil
topbar.InputBegan:Connect(function(input)
    if blockDrag then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = main.Position
    end
end)
UIS.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local d = input.Position - dragStart
        local vp = WS.CurrentCamera and WS.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
        local mw = main.AbsoluteSize.X
        local newX = math.clamp(startPos.X.Offset + d.X, 100 - mw, vp.X - 100)
        local newY = math.clamp(startPos.Y.Offset + d.Y, 0, vp.Y - 40)
        main.Position = UDim2.new(0, newX, 0, newY)
    end
end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- ============== 左侧栏（缩小版）==============
local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0, 108, 1, -66)
sidebar.Position = UDim2.new(0, 8, 0, 58)
sidebar.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
sidebar.BackgroundTransparency = 0.15
sidebar.BorderSizePixel = 0
sidebar.ZIndex = 2
sidebar.Parent = main
Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0, 9)

local innerNav = Instance.new("ScrollingFrame")
innerNav.Size = UDim2.new(1, 0, 1, 0)
innerNav.BackgroundTransparency = 1
innerNav.BorderSizePixel = 0
innerNav.ScrollBarThickness = 0
innerNav.CanvasSize = UDim2.new(0, 0, 0, 0)
innerNav.AutomaticCanvasSize = Enum.AutomaticSize.Y
innerNav.ZIndex = 3
innerNav.Parent = sidebar

local sbLayout = Instance.new("UIListLayout", innerNav)
sbLayout.Padding = UDim.new(0, 3)
sbLayout.SortOrder = Enum.SortOrder.LayoutOrder
local sbPad = Instance.new("UIPadding", innerNav)
sbPad.PaddingTop = UDim.new(0, 6); sbPad.PaddingBottom = UDim.new(0, 6)
sbPad.PaddingLeft = UDim.new(0, 6); sbPad.PaddingRight = UDim.new(0, 6)

local indicator = Instance.new("Frame")
indicator.Size = UDim2.new(1, -12, 0, 32)
indicator.Position = UDim2.new(0, 6, 0, 6)
indicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
indicator.BackgroundTransparency = 0.82
indicator.BorderSizePixel = 0
indicator.ZIndex = 2
indicator.Parent = sidebar
Instance.new("UICorner", indicator).CornerRadius = UDim.new(0, 7)

local content = Instance.new("Frame")
content.Size = UDim2.new(1, -124, 1, -66)
content.Position = UDim2.new(0, 116, 0, 58)
content.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
content.BackgroundTransparency = 0.15
content.BorderSizePixel = 0
content.ZIndex = 2
content.Parent = main
Instance.new("UICorner", content).CornerRadius = UDim.new(0, 9)

local pages = {}
local currentTab = nil
local tabButtons = {}
local tabCount = 0

local function createPage(name)
    local page = Instance.new("ScrollingFrame")
    page.Size = UDim2.new(1, -16, 1, -16)
    page.Position = UDim2.new(0, 8, 0, 8)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = Color3.fromRGB(168, 85, 247)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.Visible = false
    page.ZIndex = 3
    page.Parent = content
    local ll = Instance.new("UIListLayout", page)
    ll.Padding = UDim.new(0, 5)
    ll.SortOrder = Enum.SortOrder.LayoutOrder
    pages[name] = page
    return page
end

local function createTab(name)
    tabCount = tabCount + 1
    local order = tabCount
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 32)
    btn.BackgroundColor3 = Color3.fromRGB(168, 85, 247)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.LayoutOrder = order
    btn.ZIndex = 3
    btn.Parent = innerNav
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)
    local lbl = Instance.new("TextLabel", btn)
    lbl.Size = UDim2.new(1, -14, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = name
    lbl.TextColor3 = Color3.fromRGB(185, 185, 205)
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 4
    lbl.Parent = btn

    tabButtons[name] = { btn = btn, lbl = lbl, order = order }

    btn.MouseEnter:Connect(function()
        if currentTab ~= name then
            Tween:Create(btn, TweenInfo.new(0.12), { BackgroundTransparency = 0.75 }):Play()
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
        local targetY = 6 + (order - 1) * 35
        Tween:Create(indicator, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, 6, 0, targetY),
        }):Play()
        for n, t in pairs(tabButtons) do
            if n == name then
                t.lbl.TextColor3 = Color3.new(1, 1, 1)
            else
                t.lbl.TextColor3 = Color3.fromRGB(185, 185, 205)
            end
        end
    end)
    return btn
end

-- ============== 控件工厂（小尺寸版）==============
local function createToggle(parent, name, def, cb)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 38)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
    btn.BackgroundTransparency = 0.1
    btn.Text = ""
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.ZIndex = 3
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)
    local lbl = Instance.new("TextLabel", btn)
    lbl.Size = UDim2.new(1, -70, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = name
    lbl.TextColor3 = Color3.fromRGB(235, 235, 245)
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 4
    lbl.Parent = btn
    local ind = Instance.new("Frame", btn)
    ind.Size = UDim2.new(0, 40, 0, 20)
    ind.Position = UDim2.new(1, -52, 0.5, -10)
    ind.BackgroundColor3 = Color3.fromRGB(55, 55, 70)
    ind.BorderSizePixel = 0
    ind.ZIndex = 4
    Instance.new("UICorner", ind).CornerRadius = UDim.new(1, 0)
    local knob = Instance.new("Frame", ind)
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = UDim2.new(0, 2, 0.5, -8)
    knob.BackgroundColor3 = Color3.new(1, 1, 1)
    knob.BorderSizePixel = 0
    knob.ZIndex = 5
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
    local state = def or false
    local function refresh()
        Tween:Create(knob, TweenInfo.new(0.12), {
            Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
        }):Play()
        Tween:Create(ind, TweenInfo.new(0.12), {
            BackgroundColor3 = state and Color3.fromRGB(190, 80, 255) or Color3.fromRGB(55, 55, 70)
        }):Play()
        if state then
            if not ind:FindFirstChildOfClass("UIGradient") then
                local g = Instance.new("UIGradient", ind)
                g.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(168, 85, 247)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(236, 72, 153)),
                })
            end
        else
            local g = ind:FindFirstChildOfClass("UIGradient")
            if g then g:Destroy() end
        end
    end
    refresh()
    btn.MouseButton1Click:Connect(function()
        state = not state
        refresh()
        ok(("%s → %s"):format(name, tostring(state)))
        if cb then pcall(cb, state) end
    end)
    return { set = function(v) state = v; refresh() end }
end

local function createSlider(parent, name, min, max, def, cb)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 56)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
    frame.BackgroundTransparency = 0.1
    frame.BorderSizePixel = 0
    frame.ZIndex = 3
    frame.Parent = parent
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 7)
    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(1, -70, 0, 18)
    lbl.Position = UDim2.new(0, 12, 0, 5)
    lbl.BackgroundTransparency = 1
    lbl.Text = name
    lbl.TextColor3 = Color3.fromRGB(235, 235, 245)
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 4
    lbl.Parent = frame
    local vLbl = Instance.new("TextLabel", frame)
    vLbl.Size = UDim2.new(0, 60, 0, 18)
    vLbl.Position = UDim2.new(1, -72, 0, 5)
    vLbl.BackgroundTransparency = 1
    vLbl.Text = tostring(def)
    vLbl.TextColor3 = Color3.fromRGB(190, 130, 255)
    vLbl.Font = Enum.Font.GothamBold
    vLbl.TextSize = 14
    vLbl.TextXAlignment = Enum.TextXAlignment.Right
    vLbl.ZIndex = 4
    vLbl.Parent = frame
    local track = Instance.new("TextButton", frame)
    track.Size = UDim2.new(1, -24, 0, 7)
    track.Position = UDim2.new(0, 12, 0, 32)
    track.BackgroundColor3 = Color3.fromRGB(55, 55, 70)
    track.Text = ""
    track.BorderSizePixel = 0
    track.AutoButtonColor = false
    track.ZIndex = 4
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
    local fill = Instance.new("Frame", track)
    fill.Size = UDim2.new((def - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(168, 85, 247)
    fill.BorderSizePixel = 0
    fill.ZIndex = 5
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
    local val = def
    local dg = false
    local function update(x)
        local pos = math.clamp((x - track.AbsolutePosition.X) / math.max(1, track.AbsoluteSize.X), 0, 1)
        val = math.floor(min + pos * (max - min) + 0.5)
        fill.Size = UDim2.new(pos, 0, 1, 0)
        vLbl.Text = tostring(val)
        if cb then pcall(cb, val) end
    end
    track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dg = true
            update(i.Position.X)
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if dg and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then update(i.Position.X) end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch
            or i.UserInputType == Enum.UserInputType.Focus then
            dg = false
        end
    end)
    return { set = function(v)
        val = math.clamp(v, min, max)
        local pos = (val - min) / (max - min)
        fill.Size = UDim2.new(pos, 0, 1, 0)
        vLbl.Text = tostring(val)
        if cb then pcall(cb, val) end
    end }
end

local function createDropdown(parent, name, options, defIdx, cb)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 38)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
    btn.BackgroundTransparency = 0.1
    btn.Text = ""
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.ZIndex = 3
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)
    local lbl = Instance.new("TextLabel", btn)
    lbl.Size = UDim2.new(1, -130, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = name
    lbl.TextColor3 = Color3.fromRGB(235, 235, 245)
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 4
    lbl.Parent = btn
    local vBox = Instance.new("TextButton", btn)
    vBox.Size = UDim2.new(0, 110, 0, 26)
    vBox.Position = UDim2.new(1, -122, 0.5, -13)
    vBox.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    vBox.Text = options[defIdx or 1]
    vBox.TextColor3 = Color3.fromRGB(235, 235, 245)
    vBox.Font = Enum.Font.Gotham
    vBox.TextSize = 12
    vBox.BorderSizePixel = 0
    vBox.AutoButtonColor = false
    vBox.ZIndex = 4
    Instance.new("UICorner", vBox).CornerRadius = UDim.new(0, 6)
    local idx = defIdx or 1
    vBox.MouseButton1Click:Connect(function()
        idx = idx % #options + 1
        vBox.Text = options[idx]
        if cb then pcall(cb, options[idx], idx) end
    end)
    return { get = function() return idx, options[idx] end }
end

-- ============== 建页面 ==============
local homePage   = createPage("主页")
local playerPage = createPage("玩家")
local combatPage = createPage("战斗")
local aimPage    = createPage("自瞄")
local espPage    = createPage("透视")
local moneyPage  = createPage("刷钱")
local carPage    = createPage("飞车")
local autoPage   = createPage("自动化")

createTab("主页")
createTab("玩家")
createTab("战斗")
createTab("自瞄")
createTab("透视")
createTab("刷钱")
createTab("飞车")
createTab("自动化")

for _, pg in pairs(pages) do pg.Visible = false end
pages["主页"].Visible = true
currentTab = "主页"
tabButtons["主页"].lbl.TextColor3 = Color3.new(1, 1, 1)

local function infoCard(parent, text, color)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 36)
    f.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
    f.BackgroundTransparency = 0.1
    f.BorderSizePixel = 0
    f.ZIndex = 3
    f.Parent = parent
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 7)
    local l = Instance.new("TextLabel", f)
    l.Size = UDim2.new(1, -20, 1, 0)
    l.Position = UDim2.new(0, 12, 0, 0)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = color or Color3.fromRGB(235, 235, 245)
    l.Font = Enum.Font.Gotham
    l.TextSize = 13
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.ZIndex = 4
    l.Parent = f
    return f
end
infoCard(homePage, "XJ Hub 1.0 beta  |  作者: 嘉酱", Color3.fromRGB(190, 130, 255))
infoCard(homePage, "服务器: " .. tostring(game.PlaceId))
infoCard(homePage, "玩家: " .. #Players:GetPlayers() .. " / " .. Players.MaxPlayers)
infoCard(homePage, "队伍: " .. teamLabel(LP))
infoCard(homePage, "执行器: " .. ((identifyexecutor and identifyexecutor()) or "unknown"))
infoCard(homePage, "点 － 最小化 / 点悬浮球恢复", Color3.fromRGB(150, 220, 150))

createToggle(playerPage, "无限体力", false, function(v) S.stamina = v end)
createToggle(playerPage, "无限饥饿", false, function(v) S.food = v end)
createToggle(playerPage, "防布娃娃", false, function(v) S.noRagdoll = v end)
createToggle(playerPage, "防摔伤", false, function(v) S.noFallDamage = v end)
createToggle(playerPage, "无限子弹", false, function(v) S.infiniteAmmo = v end)
createToggle(playerPage, "快速射击", false, function(v) S.rapidFire = v end)

createToggle(combatPage, "杀戮光环", false, function(v) S.auraEnabled = v end)
createSlider(combatPage, "光环范围", 50, 800, 200, function(v) S.auraRange = v end)
createSlider(combatPage, "光环伤害", 1, 100, 5, function(v) S.auraDamage = v end)

createToggle(aimPage, "开启自瞄", false, function(v) S.aimbot.enabled = v end)
createToggle(aimPage, "显示 FOV 圈", true, function(v) S.aimbot.showFov = v end)
createToggle(aimPage, "显示追踪线", false, function(v) S.aimbot.showTracer = v end)
createToggle(aimPage, "墙壁检测", false, function(v) S.aimbot.wallCheck = v end)
createToggle(aimPage, "好友检测", false, function(v) S.aimbot.friendCheck = v end)
createToggle(aimPage, "队伍检测", false, function(v) S.aimbot.teamCheck = v end)
createToggle(aimPage, "预判瞄准", false, function(v) S.aimbot.prediction = v end)
createDropdown(aimPage, "职业筛选", {"全部", "只警察", "只平民", "只船员", "只囚犯"}, 1, function(v) S.aimbot.filter = v end)
createDropdown(aimPage, "瞄准部位", {"头部", "胸部", "左手", "右手", "左腿", "右腿"}, 1, function(v) S.aimbot.targetPart = v end)
createDropdown(aimPage, "FOV 颜色", {"红色", "绿色", "蓝色", "紫色", "白色", "彩虹"}, 1, function(v) S.aimbot.color = v end)
createSlider(aimPage, "FOV 圈大小", 20, 400, 120, function(v) S.aimbot.fov = v end)
createSlider(aimPage, "自瞄平滑度", 1, 10, 3, function(v) S.aimbot.smoothness = v / 10 end)

createToggle(espPage, "开启透视", false, function(v) S.esp.enabled = v end)
createToggle(espPage, "显示名字", true, function(v) S.esp.name = v end)
createToggle(espPage, "显示职业", true, function(v) S.esp.team = v end)
createToggle(espPage, "显示距离", true, function(v) S.esp.distance = v end)
createToggle(espPage, "显示血量", true, function(v) S.esp.health = v end)
createToggle(espPage, "显示血条", true, function(v) S.esp.bar = v end)
createToggle(espPage, "显示高亮", true, function(v) S.esp.highlight = v end)
createToggle(espPage, "队伍着色", true, function(v) S.esp.colorByTeam = v end)

createToggle(moneyPage, "自动捡钱", false, function(v) S.autoMoney = v end)
createToggle(moneyPage, "自动农民", false, function(v) S.autoFarmer = v end)
createToggle(moneyPage, "自动接任务", false, function(v) S.autoMission = v end)

createToggle(carPage, "飞行模式", false, function(v)
    S.flyEnabled = v
    if v then startFly() else stopFly() end
end)
createToggle(carPage, "穿墙 (Noclip)", false, function(v)
    S.noclip = v
    if v then startNoclip() else stopNoclip() end
end)
createToggle(carPage, "无限跳跃", false, function(v) S.infiniteJump = v end)
createToggle(carPage, "开启跳跃修改", false, function(v) S.jumpEnabled = v end)
createToggle(carPage, "修改行走速度", false, function(v) S.speedEnabled = v end)
createDropdown(carPage, "飞行模式", {"传送", "物理"}, 1, function(v)
    S.flyMode = v
    if S.flyEnabled then
        S.flyEnabled = false
        task.wait(0.1)
        S.flyEnabled = true
        startFly()
    end
end)
createSlider(carPage, "行走速度", 16, 500, 100, function(v) S.speedValue = v end)
createSlider(carPage, "跳跃高度", 50, 400, 100, function(v) S.jumpPower = v end)
createSlider(carPage, "飞行速度", 10, 300, 50, function(v) S.flySpeed = v end)

createToggle(autoPage, "自动捡钱", false, function(v) S.autoMoney = v end)

ok("UI 构建完成")
inf("=========================================")
inf("XJ Hub 1.0 beta 加载完成")
inf("窗口: 520×380（小屏适配）")
inf("分类: 主页/玩家/战斗/自瞄/透视/刷钱/飞车/自动化")
inf("=========================================")
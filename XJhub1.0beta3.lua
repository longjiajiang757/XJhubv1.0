-- ============================================================
-- XJ Hub v1.4 · 全网反作弊绕过优化版
-- 整合: 通用绕过方案 / 精准属性欺骗 / 有效连接清理 / 远程节流
-- ============================================================

local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local RunSvc  = game:GetService("RunService")
local UIS     = game:GetService("UserInputService")
local Tween   = game:GetService("TweenService")
local WS      = game:GetService("Workspace")
local LP      = Players.LocalPlayer

local function ok(m)  print("[XJ] ✅ "..m) end
local function no(m)  print("[XJ] ❌ "..m) end
local function inf(m) print("[XJ] ℹ️ "..m) end
inf("XJ Hub v1.4 加载中")

-- ========== 能力检测 ==========
local CAP = {}
local function cap(n, f) local v=false; pcall(function() v=f() end); CAP[n]=v; return v end
cap("hookmm",   function() return type(hookmetamethod)=="function" end)
cap("newcc",    function() return type(newcclosure)=="function" end)
cap("checkcl",  function() return type(checkcaller)=="function" end)
cap("getgc",    function() return type(getgc)=="function" end)
cap("gethui",   function() return type(gethui)=="function" end)
cap("drawing",  function() return type(Drawing)=="table" and type(Drawing.new)=="function" end)
cap("firepp",   function() return type(fireproximityprompt)=="function" end)
cap("getrawmt", function() return type(getrawmetatable)=="function" end)
cap("setro",    function() return type(setreadonly)=="function" end)
cap("getconn",  function() return type(getconnections)=="function" end)
cap("getcall",  function() return type(getcallingscript)=="function" end)
inf("能力: hookmm="..tostring(CAP.hookmm).." getcall="..tostring(CAP.getcall).." drawing="..tostring(CAP.drawing))

-- ========== UI 根 ==========
local uiParent = (CAP.gethui and gethui()) or game:GetService("CoreGui")
local old = uiParent:FindFirstChild("XJHubUI"); if old then old:Destroy() end
local screen = Instance.new("ScreenGui")
screen.Name = "RBX_" .. tostring(math.random(100000, 999999))
screen.ResetOnSpawn = false
screen.IgnoreGuiInset = true
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.Parent = uiParent
ok("ScreenGui")

-- ============================================================
-- 属性欺骗层 (精准化: 仅欺骗反作弊模块)
-- ============================================================
local SPOOF = { walkSpeed=16, jumpPower=50, floorMat=Enum.Material.Plastic, installed=false, count=0 }
if CAP.hookmm and CAP.getrawmt and CAP.setro then
    local mt = getrawmetatable(game)
    local oldIdx = mt.__index
    setreadonly(mt, false)
    mt.__index = newcclosure(function(self, key)
        if not checkcaller() then
            local okk, cls = pcall(function() return self.ClassName end)
            if okk and cls == "Humanoid" then
                -- 通过 traceback 判断调用来源，只欺骗反作弊模块
                local tb = debug.traceback("", 2)
                local isAnti = tb:find("Anti") or tb:find("anti") or tb:find("Detect")
                    or tb:find("Security") or tb:find("Check")
                if isAnti then
                    if key == "WalkSpeed" then
                        SPOOF.count = SPOOF.count + 1
                        return SPOOF.walkSpeed
                    end
                    if key == "JumpPower" then return SPOOF.jumpPower end
                    if key == "FloorMaterial" then return SPOOF.floorMat end
                end
            end
        end
        return oldIdx(self, key)
    end)
    setreadonly(mt, true)
    SPOOF.installed = true
    ok("属性欺骗已装 (精准模式)")
end

-- ============================================================
-- 远程拦截 (精确匹配, 防止误杀)
-- ============================================================
local BLOCK_PAT = {
    "^detect", "^report", "^flag", "^ban$", "^kick$", "^warn$",
    "^cheat", "^suspicious", "^getPlayerData$", "^getSecret$",
    "^getPlayerBanHistory$", "^getPlayerInGame$", "^getPlayerServerEncounters$",
}
local BLOCKED = 0
if CAP.hookmm and CAP.getrawmt and CAP.setro then
    local mt = getrawmetatable(game)
    local oldNC = mt.__namecall
    setreadonly(mt, false)
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        if not checkcaller() then
            if method == "Kick" and self == LP then return end
            if (method == "FireServer" or method == "InvokeServer") then
                local nm = self.Name
                if nm then
                    local low = nm:lower()
                    for _, p in ipairs(BLOCK_PAT) do
                        if low:match(p) then
                            BLOCKED = BLOCKED + 1
                            return true
                        end
                    end
                end
            end
        end
        return oldNC(self, ...)
    end)
    setreadonly(mt, true)
    ok("远程拦截已装 (精确匹配)")
end

-- ============================================================
-- 连接清理 (使用 getcallingscript 有效识别)
-- ============================================================
local CLEANED = 0
if CAP.getconn then
    task.spawn(function()
        task.wait(3)
        pcall(function()
            local conns = getconnections(RunSvc.Heartbeat)
            for _, conn in ipairs(conns) do
                local src = nil
                pcall(function()
                    if CAP.getcall then
                        local s = getcallingscript(conn.Function)
                        if s then src = s.Name end
                    end
                    if not src and debug and debug.info then
                        src = debug.info(conn.Function, "s")
                    end
                end)
                if src and (src:find("Anti") or src:find("Detect") or src:find("Security")) then
                    pcall(function() conn:Disconnect() end)
                    CLEANED = CLEANED + 1
                end
            end
        end)
        if CLEANED > 0 then ok("清理 "..CLEANED.." 个反作弊连接") end
    end)
end

-- ============================================================
-- 远程节流系统 (防服务端频率检测)
-- ============================================================
local Throttle = {}
local function throttledFire(remote, minGap, ...)
    local key = tostring(remote)
    local now = tick()
    local last = Throttle[key] or 0
    local gap = minGap + math.random() * minGap * 0.5
    if now - last < gap then return end
    Throttle[key] = now
    return remote:FireServer(...)
end
local function throttledInvoke(remote, minGap, ...)
    local key = tostring(remote) .. ":" .. tostring(({...})[1])
    local now = tick()
    local last = Throttle[key] or 0
    local gap = minGap + math.random() * minGap * 0.5
    if now - last < gap then return end
    Throttle[key] = now
    return remote:InvokeServer(...)
end
ok("远程节流系统")

-- ========== 游戏框架 ==========
local remote      = RS:WaitForChild("Remote", 10)
local playerEvent = remote and remote:WaitForChild("PlayerEvent", 10)
local playerFunc  = remote and remote:WaitForChild("PlayerFunc", 10)
local Core, Character, Controls
pcall(function()
    local fw = LP:WaitForChild("PlayerScripts", 10):WaitForChild("Framework", 10)
    Core = require(fw:WaitForChild("Core", 10))
    Character = require(fw:WaitForChild("Character", 10))
end)
pcall(function()
    Controls = require(LP.PlayerScripts:WaitForChild("PlayerModule")):GetControls()
end)

-- ========== 工具 ==========
local function getChar(p)
    p = p or LP
    local c = p.Character; if not c then return end
    return c, c:FindFirstChildOfClass("Humanoid"),
        c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso")
end
local function isOnGround(h)
    if not h then return false end
    local s = h:GetState()
    return s == Enum.HumanoidStateType.Landed or s == Enum.HumanoidStateType.Running or s == Enum.HumanoidStateType.RunningNoPhysics
end

-- ========== 状态 ==========
local S = {
    stamina=false, food=false, infiniteAmmo=false, rapidFire=false,
    speedEnabled=false, speedValue=100,
    jumpEnabled=false, jumpPower=50, infiniteJump=false,
    auraEnabled=false, auraRange=200, auraDamage=5, auraHumanize=true, auraStealth=true,
    autoCuff=false,
    aimbot={enabled=false,fov=120,smoothness=0.3,showFov=true,showTracer=false,
            color="红色",keyHeld=false,targetPart="头部",
            friendCheck=false,wallCheck=false,teamCheck=false,crewCheck=false},
    esp={enabled=false,name=true,distance=true,health=true,team=true,highlight=true,bar=true,colorByTeam=true},
    autoMoney=false, autoFarmer=false, autoMission=false, autoHack=false,
    autoTaxi=false, taxiSafe=false, taxiDelayMode="随机时间",
    autoGolf=false,
    flyEnabled=false, flySpeed=50, noclip=false,
    ghost=false, noRagdoll=false,
}

-- ========== 队伍 ==========
local TEAM_COLORS = {
    Police=Color3.fromRGB(60,120,255),Civilian=Color3.fromRGB(100,200,255),
    Prisoner=Color3.fromRGB(255,150,150),Fire=Color3.fromRGB(255,80,60),
    Medical=Color3.fromRGB(255,100,220),Chef=Color3.fromRGB(255,200,0),
    Delivery=Color3.fromRGB(255,150,50),Farmer=Color3.fromRGB(80,200,80),
    ["Road Service"]=Color3.fromRGB(255,240,100),Transit=Color3.fromRGB(100,240,255),
}
local TEAM_NAMES = {Police="警察",Civilian="平民",Prisoner="囚犯",Fire="消防",Medical="医护",
    Chef="厨师",Delivery="配送",Farmer="农民",["Road Service"]="路政",Transit="交通"}
local function teamColor(p) return TEAM_COLORS[p.Team and p.Team.Name] or Color3.fromRGB(200,200,200) end
local function teamLabel(p) return TEAM_NAMES[p.Team and p.Team.Name] or (p.Team and p.Team.Name or "无") end
local CREW = { Civilian=true, Delivery=true, Transit=true }

-- ========== 好友 ==========
local friendSet = {}
task.spawn(function()
    pcall(function()
        local cursor, n = "", 0
        repeat
            n = n + 1; if n > 20 then break end
            local page = LP:GetFriendsAsync(cursor); if not page then break end
            for _, f in ipairs(page:GetCurrentPage()) do friendSet[f.Id] = true end
            cursor = page.Cursor
        until not cursor or cursor == ""
    end)
end)
local function isFriend(p) return friendSet[p.UserId] == true end

-- ========== 性能 ==========
local stats = { fps=0, frames=0, lastTick=tick(), ping=0, espAvg=0 }
task.spawn(function()
    while screen.Parent do
        pcall(function() stats.ping = math.floor((LP:GetNetworkPing() or 0) * 1000) end)
        task.wait(1)
    end
end)

local userInfo = {
    name=LP.Name, displayName=LP.DisplayName or LP.Name,
    userId=LP.UserId, accountAge=LP.AccountAge or 0,
    membership=tostring(LP.MembershipType):gsub("Enum.MembershipType%.", ""),
    thumb="rbxthumb://type=AvatarHeadShot&id="..LP.UserId.."&w=150&h=150",
}

-- ============================================================
-- 通知弹窗系统
-- ============================================================
local notifyHolder = Instance.new("Frame", screen)
notifyHolder.Name = "NotifyHolder"
notifyHolder.Size = UDim2.new(0, 280, 1, -30)
notifyHolder.Position = UDim2.new(1, -290, 0, 15)
notifyHolder.BackgroundTransparency = 1
notifyHolder.ZIndex = 200
local notifyLayout = Instance.new("UIListLayout", notifyHolder)
notifyLayout.Padding = UDim.new(0, 8)
notifyLayout.SortOrder = Enum.SortOrder.LayoutOrder
notifyLayout.VerticalAlignment = Enum.VerticalAlignment.Top
local notifyOrder = 0

local function notify(title, desc, kind, duration)
    kind = kind or "info"; duration = duration or 2.5
    notifyOrder = notifyOrder + 1
    local color
    if kind == "success" then color = Color3.fromRGB(60, 220, 100)
    elseif kind == "warn" then color = Color3.fromRGB(255, 200, 60)
    elseif kind == "error" then color = Color3.fromRGB(255, 80, 80)
    else color = Color3.fromRGB(100, 180, 255) end
    local card = Instance.new("Frame", notifyHolder)
    card.Size = UDim2.new(1, 0, 0, 52)
    card.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
    card.BackgroundTransparency = 0.1
    card.BorderSizePixel = 0
    card.LayoutOrder = notifyOrder
    card.ZIndex = 201
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke", card)
    stroke.Color = color; stroke.Thickness = 1.5
    local accent = Instance.new("Frame", card)
    accent.Size = UDim2.new(0, 4, 0, 40)
    accent.Position = UDim2.new(0, 6, 0.5, -20)
    accent.BackgroundColor3 = color
    accent.BorderSizePixel = 0
    Instance.new("UICorner", accent).CornerRadius = UDim.new(1, 0)
    local titleLbl = Instance.new("TextLabel", card)
    titleLbl.Size = UDim2.new(1, -30, 0, 16); titleLbl.Position = UDim2.new(0, 20, 0, 8)
    titleLbl.BackgroundTransparency = 1; titleLbl.Text = title
    titleLbl.TextColor3 = color; titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextSize = 12; titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    local descLbl = Instance.new("TextLabel", card)
    descLbl.Size = UDim2.new(1, -30, 0, 18); descLbl.Position = UDim2.new(0, 20, 0, 26)
    descLbl.BackgroundTransparency = 1; descLbl.Text = desc
    descLbl.TextColor3 = Color3.fromRGB(210, 210, 225)
    descLbl.Font = Enum.Font.Gotham; descLbl.TextSize = 10
    descLbl.TextXAlignment = Enum.TextXAlignment.Left
    card.Position = UDim2.new(1, 40, 0, 0)
    Tween:Create(card, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, 0, 0, 0)
    }):Play()
    task.spawn(function()
        task.wait(duration)
        pcall(function()
            Tween:Create(card, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Position = UDim2.new(1, 40, 0, 0), BackgroundTransparency = 1
            }):Play()
            Tween:Create(stroke, TweenInfo.new(0.25), { Transparency = 1 }):Play()
            Tween:Create(titleLbl, TweenInfo.new(0.2), { TextTransparency = 1 }):Play()
            Tween:Create(descLbl, TweenInfo.new(0.2), { TextTransparency = 1 }):Play()
            task.wait(0.3)
            card:Destroy()
        end)
    end)
end

-- ============================================================
-- 安全移动 (BodyVelocity + 属性欺骗)
-- ============================================================
local speedBV = nil
local function refreshSpeed()
    local _, h, r = getChar(); if not h or not r then return end
    if S.speedEnabled and S.speedValue > 16 then
        if not speedBV or speedBV.Parent ~= r then
            if speedBV then speedBV:Destroy() end
            speedBV = Instance.new("BodyVelocity")
            speedBV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            speedBV.P = 1250; speedBV.Parent = r
        end
        local mv = h.MoveDirection
        speedBV.Velocity = mv.Magnitude > 0.01 and (mv.Unit * S.speedValue) or Vector3.zero
        if h.WalkSpeed ~= SPOOF.walkSpeed then h.WalkSpeed = SPOOF.walkSpeed end
    else
        if speedBV then speedBV:Destroy(); speedBV = nil end
        h.WalkSpeed = S.speedValue
    end
end

-- ============================================================
-- 飞行 (AlignPosition + BodyVelocity + BodyGyro)
-- ============================================================
local Fly = { align=nil, att=nil, conn=nil, bv=nil, bg=nil }
local function stopFly()
    if Fly.conn then Fly.conn:Disconnect(); Fly.conn=nil end
    if Fly.align then Fly.align:Destroy(); Fly.align=nil end
    if Fly.att then Fly.att:Destroy(); Fly.att=nil end
    if Fly.bv then Fly.bv:Destroy(); Fly.bv=nil end
    if Fly.bg then Fly.bg:Destroy(); Fly.bg=nil end
    local _, h = getChar()
    if h then h.PlatformStand=false; h.AutoRotate=true end
end
local function startFly()
    stopFly()
    local _, h, r = getChar(); if not r or not h then return end
    h.AutoRotate = false; h.PlatformStand = true
    Fly.att = Instance.new("Attachment", r)
    Fly.align = Instance.new("AlignPosition", r)
    Fly.align.Attachment0 = Fly.att
    Fly.align.Mode = Enum.PositionAlignmentMode.OneAttachment
    Fly.align.MaxForce = 5e4; Fly.align.Responsiveness = 25
    Fly.align.Position = r.Position
    Fly.bv = Instance.new("BodyVelocity")
    Fly.bv.MaxForce = Vector3.new(9e9,9e9,9e9); Fly.bv.P = 1250; Fly.bv.Parent = r
    Fly.bg = Instance.new("BodyGyro")
    Fly.bg.MaxTorque = Vector3.new(9e9,9e9,9e9); Fly.bg.P = 90000; Fly.bg.Parent = r
    Fly.conn = RunSvc.RenderStepped:Connect(function()
        if not S.flyEnabled or not Fly.align then return end
        local cam = WS.CurrentCamera; if not cam then return end
        local mv = Controls and Controls:GetMoveVector() or Vector3.zero
        local y = UIS:IsKeyDown(Enum.KeyCode.Space) and 1 or (UIS:IsKeyDown(Enum.KeyCode.LeftControl) and -1 or 0)
        local dir = cam.CFrame.LookVector * -mv.Z + cam.CFrame.RightVector * mv.X
        local moveVec = (dir + Vector3.new(0, y, 0)) * S.flySpeed
        Fly.align.Position = Fly.align.Position + moveVec * 0.05
        if Fly.bv then Fly.bv.Velocity = moveVec end
        if Fly.bg then Fly.bg.CFrame = cam.CFrame end
    end)
end

-- ============================================================
-- Noclip (性能优化: 缓存部件列表)
-- ============================================================
local Noclip = { conn=nil, cache={}, parts={} }
local function rebuildNoclipParts()
    Noclip.parts = {}
    local c = LP.Character
    if not c then return end
    for _, d in ipairs(c:GetDescendants()) do
        if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then
            table.insert(Noclip.parts, d)
        end
    end
end
LP.CharacterAdded:Connect(function()
    task.wait(0.5)
    rebuildNoclipParts()
end)
task.spawn(function() task.wait(1); rebuildNoclipParts() end)

local function stopNoclip()
    if Noclip.conn then Noclip.conn:Disconnect(); Noclip.conn=nil end
    for part, saved in pairs(Noclip.cache) do
        if part and part.Parent then pcall(function() part.CanCollide = saved end) end
    end
    Noclip.cache = {}
end
local function startNoclip()
    stopNoclip()
    Noclip.conn = RunSvc.Stepped:Connect(function()
        if not S.noclip then return end
        local _, _, r = getChar(); if not r then return end
        local cam = WS.CurrentCamera; if not cam then return end
        local params = RaycastParams.new()
        params.FilterDescendantsInstances = { LP.Character }
        params.FilterType = Enum.RaycastFilterType.Exclude
        local hit = WS:Raycast(r.Position, cam.CFrame.LookVector * 4, params)
        for _, d in ipairs(Noclip.parts) do
            if d.Parent then
                if Noclip.cache[d] == nil then Noclip.cache[d] = d.CanCollide end
                d.CanCollide = not (hit and hit.Instance == d)
            end
        end
    end)
end

-- ============================================================
-- 自瞄
-- ============================================================
local PART_MAP = { ["头部"]={"Head"}, ["胸部"]={"UpperTorso","Torso"} }
local function getTargetPart(c)
    for _, n in ipairs(PART_MAP[S.aimbot.targetPart] or {"Head"}) do
        local p = c:FindFirstChild(n); if p then return p end
    end
    return c:FindFirstChild("HumanoidRootPart")
end
local COLOR_MAP = {
    ["红色"]=Color3.fromRGB(255,0,0),["绿色"]=Color3.fromRGB(0,255,0),
    ["蓝色"]=Color3.fromRGB(0,150,255),["紫色"]=Color3.fromRGB(168,85,247),
    ["白色"]=Color3.fromRGB(255,255,255),
}
local function aimColor()
    if S.aimbot.color == "彩虹" then return Color3.fromHSV(tick()%5/5,1,1) end
    return COLOR_MAP[S.aimbot.color] or Color3.fromRGB(255,0,0)
end
local function isSameTeam(p) return LP.Team and p.Team and LP.Team == p.Team end
local function isCrew(p) return p.Team and p.Team.Name and CREW[p.Team.Name] end
local function hasWall(tPart, tChar)
    local cam = WS.CurrentCamera; if not cam then return false end
    local filter = { cam }; if LP.Character then table.insert(filter, LP.Character) end
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = filter
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.IgnoreWater = true
    local hit = WS:Raycast(cam.CFrame.Position, tPart.Position - cam.CFrame.Position, params)
    return not hit or hit.Instance:IsDescendantOf(tChar)
end
local fovCircle, tracerLine
if CAP.drawing then
    fovCircle = Drawing.new("Circle"); fovCircle.Filled=false; fovCircle.NumSides=48; fovCircle.Visible=false
    tracerLine = Drawing.new("Line"); tracerLine.Visible = false
end

RunSvc.RenderStepped:Connect(function()
    stats.frames = stats.frames + 1
    if tick() - stats.lastTick >= 1 then
        stats.fps = stats.frames; stats.frames = 0; stats.lastTick = tick()
    end
    if S.speedEnabled then refreshSpeed() end
    local cam = WS.CurrentCamera; if not cam then return end
    local center = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y/2)
    if fovCircle then
        fovCircle.Position = center; fovCircle.Radius = S.aimbot.fov
        fovCircle.Thickness = 2; fovCircle.Color = aimColor()
        fovCircle.Visible = S.aimbot.enabled and S.aimbot.showFov
    end
    if not (S.aimbot.enabled and S.aimbot.keyHeld) then
        if tracerLine then tracerLine.Visible = false end
        return
    end
    local tgt, bd = nil, S.aimbot.fov
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then
            local skip = false
            if S.aimbot.friendCheck and isFriend(p) then skip = true end
            if not skip and S.aimbot.teamCheck and isSameTeam(p) then skip = true end
            if not skip and S.aimbot.crewCheck and isCrew(p) then skip = true end
            if not skip then
                local c, h = getChar(p)
                if c and h and h.Health > 0 then
                    local part = getTargetPart(c)
                    if part then
                        local sp, on = cam:WorldToViewportPoint(part.Position)
                        if on then
                            local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                            if d < bd and (not S.aimbot.wallCheck or hasWall(part, c)) then
                                tgt, bd = part, d
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
            tracerLine.From = center; tracerLine.To = Vector2.new(sp.X, sp.Y)
            tracerLine.Color = aimColor(); tracerLine.Visible = true
        elseif tracerLine then tracerLine.Visible = false end
        cam.CFrame = cam.CFrame:Lerp(CFrame.new(cam.CFrame.Position, tgt.Position), S.aimbot.smoothness)
    elseif tracerLine then
        tracerLine.Visible = false
    end
end)

-- ============================================================
-- 核心循环
-- ============================================================
task.spawn(function()
    while screen.Parent do
        pcall(function()
            if Core then
                if S.stamina then Core.stamina = 100 end
                if S.food then Core.food = 100 end
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
        end)
        task.wait(0.3)
    end
end)

-- ========== 快速射击 ==========
task.spawn(function()
    while screen.Parent do
        if S.rapidFire and CAP.getgc then
            pcall(function()
                for _, v in pairs(getgc(true)) do
                    if type(v) == "table" then
                        if rawget(v, "SHOOT_MODE") ~= nil then rawset(v, "SHOOT_MODE", 2) end
                        if rawget(v, "RPM") ~= nil then rawset(v, "RPM", 600) end
                    end
                end
            end)
        end
        task.wait(3)
    end
end)

-- ========== 杀戮光环 (使用节流系统) ==========
task.spawn(function()
    while screen.Parent do
        if S.auraEnabled and playerEvent then
            pcall(function()
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
                        throttledFire(playerEvent, 0.5, "damage", {
                            bodyParts = {{"Head", 1}},
                            shotCode = { r.Position, (pr.Position - r.Position).Unit },
                            pos = pr.Position, target = tgt,
                            damageFactor = S.auraDamage, bulletProofTool = false,
                        })
                    end
                end
            end)
        end
        local w
        if S.auraStealth then w = 0.4 + math.random() * 0.2
        elseif S.auraHumanize then w = 0.15 + math.random() * 0.1
        else w = 0.1 end
        task.wait(w)
    end
end)

-- ========== 自动铐 (使用节流系统) ==========
local cuffCache = {}
task.spawn(function()
    while screen.Parent do
        if S.autoCuff and playerFunc then
            pcall(function()
                local _, _, r = getChar()
                if r then
                    for _, p in ipairs(Players:GetPlayers()) do
                        if p ~= LP and not cuffCache[p.UserId] then
                            local _, ph, pr = getChar(p)
                            if ph and pr and ph.Health > 0 and (pr.Position - r.Position).Magnitude <= 200 then
                                throttledInvoke(playerFunc, 2.5, "handcuff", p, false)
                                cuffCache[p.UserId] = tick()
                            end
                        end
                    end
                end
                for uid, t in pairs(cuffCache) do
                    if tick() - t > 10 then cuffCache[uid] = nil end
                end
            end)
        end
        task.wait(2.5 + math.random() * 2)
    end
end)

-- ========== 自动捡钱/农民 ==========
task.spawn(function()
    while screen.Parent do
        if S.autoMoney or S.autoFarmer then
            pcall(function()
                local _, _, r = getChar(); if not r then return end
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
                            local pos = par and par:IsA("BasePart") and par.Position
                            if pos then
                                local dist = (r.Position - pos).Magnitude
                                if dist < bd and dist < 100 then best, bd = d, dist end
                            end
                        end
                    end
                end
                if best and CAP.firepp then pcall(fireproximityprompt, best, 0) end
            end)
        end
        task.wait(1.5)
    end
end)

-- ========== 自动接任务 ==========
task.spawn(function()
    while screen.Parent do
        if S.autoMission and playerFunc and CAP.getgc then
            pcall(function()
                if not LP:GetAttribute("Mission") then
                    for _, v in pairs(getgc(true)) do
                        if type(v) == "table" and rawget(v, "teamJobs") then
                            for k, j in pairs(v.teamJobs) do
                                if not j.joined then
                                    throttledInvoke(playerFunc, 3, "talkToMission", tostring(k) .. "join")
                                    break
                                end
                            end
                            break
                        end
                    end
                end
            end)
        end
        task.wait(3)
    end
end)

-- ========== 自动黑客 ==========
task.spawn(function()
    while screen.Parent do
        if S.autoHack then
            pcall(function()
                local fw = LP.PlayerScripts:FindFirstChild("Framework")
                local cm = fw and require(fw:FindFirstChild("Character"))
                if cm then
                    cm.hackingMinigame = function() return true end
                    cm.startMinigame = function() return true end
                end
            end)
        end
        task.wait(3)
    end
end)

-- ============================================================
-- 自动出租车 (修复原点累积 + 节流)
-- ============================================================
local Taxi = { thread=nil, origin=nil, lastTarget=nil }
local function findTaxiTarget()
    local _, _, hrp = getChar(); if not hrp then return nil end
    local gp = WS:FindFirstChild("Gameplay")
    local ents = gp and gp:FindFirstChild("Entities")
    local cc = ents and ents:FindFirstChild("ClientContent")
    if not cc then return nil end
    for _, child in ipairs(cc:GetChildren()) do
        if child:IsA("Model") then
            local name = string.lower(child.Name)
            if name:find("taxi") or name:find("vehicle") or name:find("car") then
                local p = child.PrimaryPart or child:FindFirstChildWhichIsA("BasePart")
                if p then return p.Position end
            end
        end
    end
    return nil
end
local function safeTeleport(targetPos)
    local _, hum, hrp = getChar()
    if not hrp or not hum then return end
    if not Taxi.origin then Taxi.origin = hrp.Position end
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
    pcall(function() hum:ChangeState(Enum.HumanoidStateType.Physics) end)
    hrp.CFrame = CFrame.new(targetPos + Vector3.new(0, 3, 0))
    task.wait(0.1)
    pcall(function() hum:ChangeState(Enum.HumanoidStateType.Running) end)
end
local function getSafeWait(distance)
    if S.taxiDelayMode == "距离测算" then
        local d = math.clamp(distance, 2000, 6000)
        return math.clamp(15 + (d - 2000) / 4000 * 30 + math.random() * 2 - 1, 15, 45)
    else
        return distance > 2000 and math.random(15, 45) or 15
    end
end
local function startTaxi()
    if Taxi.thread then return end
    -- 修复: 启动时重置原点
    local _, _, hrp0 = getChar()
    if hrp0 then Taxi.origin = hrp0.Position end
    Taxi.thread = task.spawn(function()
        while S.autoTaxi do
            pcall(function()
                local char, hum, hrp = getChar()
                local teamName = LP.Team and LP.Team.Name
                local isCivilian = (teamName == "Civilian" or teamName == "Visitor" or teamName == nil)
                if char and hum and hrp and isCivilian and hum.Health > 0 then
                    local targetPos = findTaxiTarget()
                    if targetPos then
                        local distance = (hrp.Position - targetPos).Magnitude
                        if distance > 10 then
                            if S.taxiSafe then
                                if not Taxi.origin then Taxi.origin = hrp.Position end
                                safeTeleport(Taxi.origin)
                                local wt = getSafeWait(distance)
                                local start = tick()
                                while S.autoTaxi and (tick() - start < wt) do
                                    task.wait(1)
                                    local _, h2 = getChar()
                                    if not h2 or h2.Health <= 0 then
                                        Taxi.origin = nil
                                        return
                                    end
                                end
                            end
                            safeTeleport(targetPos)
                        end
                        Taxi.lastTarget = targetPos
                    end
                end
            end)
            task.wait(0.5)
        end
        Taxi.thread = nil
    end)
end
local function stopTaxi()
    S.autoTaxi = false
    Taxi.origin = nil
    if Taxi.thread and coroutine.status(Taxi.thread) ~= "dead" then
        pcall(function() task.cancel(Taxi.thread) end)
    end
    Taxi.thread = nil
end

-- ============================================================
-- 自动高尔夫 (移除卡密, 使用节流)
-- ============================================================
local Golf = { thread=nil }
local function startGolf()
    if Golf.thread then return end
    Golf.thread = task.spawn(function()
        while S.autoGolf do
            pcall(function()
                if playerFunc then
                    throttledInvoke(playerFunc, 0.5, "miniGolf", "createLobby")
                    task.wait(0.1)
                    throttledInvoke(playerFunc, 0.5, "miniGolf", "setLobbyBid", { bid = 500 })
                    task.wait(0.1)
                    throttledInvoke(playerFunc, 0.5, "miniGolf", "setLobbyReady")
                    task.wait(4)
                    throttledInvoke(playerFunc, 0.5, "miniGolf", "shot")
                end
            end)
            task.wait(5)
        end
        Golf.thread = nil
    end)
end
local function stopGolf()
    S.autoGolf = false
    if Golf.thread and coroutine.status(Golf.thread) ~= "dead" then
        pcall(function() task.cancel(Golf.thread) end)
    end
    Golf.thread = nil
end

-- ========== 隐身 ==========
task.spawn(function()
    while screen.Parent do
        if S.ghost and playerFunc then
            pcall(function()
                local stuff = RS:FindFirstChild("Stuff")
                local loc = stuff and stuff:FindFirstChild("Locations")
                loc = loc and loc:GetChildren()[1] or nil
                playerFunc:InvokeServer("hideCharacterLocation", loc)
            end)
        end
        task.wait(4)
    end
end)

-- ========== 无限跳 ==========
local lastJump = 0
UIS.JumpRequest:Connect(function()
    if not S.jumpEnabled and not S.infiniteJump then return end
    if tick() - lastJump < 0.25 then return end
    lastJump = tick()
    local _, h, r = getChar(); if not h or not r or h.Health <= 0 then return end
    if not S.infiniteJump and not isOnGround(h) then return end
    r.CFrame = r.CFrame + Vector3.new(0, S.jumpPower * 0.05, 0)
end)

-- ========== Ragdoll 补丁 ==========
pcall(function()
    local Ragdoll = require(RS.Modules.Ragdoll)
    local orig = Ragdoll.activate
    Ragdoll.activate = function(self, cond, x, y, ...)
        if S.noRagdoll and cond then return end
        return orig(self, cond, x, y, ...)
    end
end)

-- ============================================================
-- ESP (Drawing 优先)
-- ============================================================
local espCache = {}
local function buildESPDraw(p, char, hrp)
    local e = { mode="draw", hl=Instance.new("Highlight", char) }
    e.hl.Name = "XJ_HL"; e.hl.Adornee = char
    e.hl.FillTransparency = 0.85; e.hl.OutlineTransparency = 0
    pcall(function() e.hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop end)
    e.name = Drawing.new("Text"); e.name.Size=13; e.name.Font=2; e.name.Center=true
    e.name.Outline=true; e.name.OutlineColor=Color3.new(0,0,0)
    e.dist = Drawing.new("Text"); e.dist.Size=11; e.dist.Font=2; e.dist.Center=true
    e.dist.Outline=true; e.dist.OutlineColor=Color3.new(0,0,0)
    e.hpBg = Drawing.new("Line"); e.hpBg.Thickness=3
    e.hpFill = Drawing.new("Line"); e.hpFill.Thickness=3
    return e
end
local function destroyESP(e)
    pcall(function()
        if e.bill then e.bill:Destroy() end
        if e.hl then e.hl:Destroy() end
        if e.mode == "draw" then
            for _, k in ipairs({"name","dist","hpBg","hpFill"}) do
                if e[k] then e[k]:Remove() end
            end
        end
    end)
end
task.spawn(function()
    while screen.Parent do
        local t0 = tick()
        if S.esp.enabled and CAP.drawing then
            pcall(function()
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LP then
                        local c, h, r = getChar(p)
                        if c and h and r and h.Health > 0 then
                            if not espCache[p] then espCache[p] = buildESPDraw(p, c, r) end
                            local e = espCache[p]
                            local tc = S.esp.colorByTeam and teamColor(p) or Color3.fromRGB(168,85,247)
                            local n = p.Name
                            if S.esp.team then n = "[" .. teamLabel(p) .. "] " .. n end
                            local _, _, mr = getChar()
                            local dist = mr and math.floor((mr.Position - r.Position).Magnitude) or 0
                            local hpTxt = math.floor(h.Health) .. "/" .. math.floor(h.MaxHealth)
                            local pos, on = WS.CurrentCamera:WorldToViewportPoint(r.Position + Vector3.new(0, 3.2, 0))
                            if on then
                                e.name.Visible = S.esp.name
                                e.name.Text = n; e.name.Color = tc
                                e.name.Position = Vector2.new(pos.X, pos.Y - 22)
                                local txt = ""
                                if S.esp.distance then txt = dist .. "m" end
                                if S.esp.health then txt = txt .. (txt~="" and " · " or "") .. hpTxt end
                                e.dist.Visible = (S.esp.distance or S.esp.health) and txt ~= ""
                                e.dist.Text = txt; e.dist.Color = Color3.new(0.9,0.9,0.9)
                                e.dist.Position = Vector2.new(pos.X, pos.Y - 8)
                                if S.esp.bar then
                                    local w = 40
                                    local x1, x2 = pos.X - w/2, pos.X + w/2
                                    local y = pos.Y + 8
                                    e.hpBg.Visible = true; e.hpFill.Visible = true
                                    e.hpBg.From = Vector2.new(x1, y); e.hpBg.To = Vector2.new(x2, y)
                                    e.hpBg.Color = Color3.fromRGB(20,20,30)
                                    local ratio = math.clamp(h.Health / h.MaxHealth, 0, 1)
                                    e.hpFill.From = Vector2.new(x1, y)
                                    e.hpFill.To = Vector2.new(x1 + w*ratio, y)
                                    e.hpFill.Color = ratio > 0.6 and Color3.fromRGB(60,220,100)
                                        or ratio > 0.3 and Color3.fromRGB(255,200,0)
                                        or Color3.fromRGB(255,60,60)
                                else
                                    e.hpBg.Visible = false; e.hpFill.Visible = false
                                end
                            else
                                e.name.Visible = false; e.dist.Visible = false
                                e.hpBg.Visible = false; e.hpFill.Visible = false
                            end
                            if e.hl then
                                if e.hl.Parent ~= c then e.hl.Parent = c end
                                e.hl.Adornee = c
                                e.hl.FillColor = tc; e.hl.OutlineColor = tc
                                e.hl.Enabled = S.esp.highlight
                            end
                        else
                            if espCache[p] then destroyESP(espCache[p]); espCache[p] = nil end
                        end
                    end
                end
            end)
        else
            for p, e in pairs(espCache) do destroyESP(e); espCache[p] = nil end
        end
        stats.espAvg = stats.espAvg * 0.9 + (tick() - t0) * 0.1
        task.wait(0.15)
    end
end)

-- ============================================================
-- UI 构建
-- ============================================================
local cam0 = WS.CurrentCamera
local vp = cam0 and cam0.ViewportSize or Vector2.new(1920, 1080)
local isTouch = UIS.TouchEnabled and not UIS.MouseEnabled
local uiScale = 1
if isTouch or vp.X < 800 then
    uiScale = math.clamp(math.min((vp.X - 40) / 460, (vp.Y - 80) / 340), 0.6, 1)
end

local main = Instance.new("Frame", screen)
main.Size = UDim2.new(0, 460, 0, 340)
main.Position = UDim2.new(0.5, -230 * uiScale, 0.5, -170 * uiScale)
main.BackgroundColor3 = Color3.fromRGB(14, 14, 20)
main.BackgroundTransparency = 0.15
main.BorderSizePixel = 0
main.ClipsDescendants = true
main.Visible = false
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 14)
Instance.new("UIScale", main).Scale = uiScale
local mbg = Instance.new("UIGradient", main)
mbg.Rotation = 135
mbg.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(22, 16, 38)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(14, 14, 20)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 12, 32)),
})
local mstr = Instance.new("UIStroke", main)
mstr.Color = Color3.fromRGB(168, 85, 247); mstr.Thickness = 1.5

local topbar = Instance.new("Frame", main)
topbar.Size = UDim2.new(1, 0, 0, 42)
topbar.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
topbar.BackgroundTransparency = 0.2
topbar.BorderSizePixel = 0
Instance.new("UICorner", topbar).CornerRadius = UDim.new(0, 14)

local logo = Instance.new("Frame", topbar)
logo.Size = UDim2.new(0, 28, 0, 28)
logo.Position = UDim2.new(0, 8, 0.5, -14)
logo.BackgroundColor3 = Color3.new(1,1,1)
logo.BorderSizePixel = 0
Instance.new("UICorner", logo).CornerRadius = UDim.new(0, 7)
local lg = Instance.new("UIGradient", logo)
lg.Rotation = 45
lg.Color = ColorSequence.new(Color3.fromRGB(236,72,153), Color3.fromRGB(168,85,247))
local lTxt = Instance.new("TextLabel", logo)
lTxt.Size = UDim2.new(1,0,1,0); lTxt.BackgroundTransparency = 1
lTxt.Text = "嘉"; lTxt.TextColor3 = Color3.new(1,1,1)
lTxt.Font = Enum.Font.GothamBlack; lTxt.TextSize = 15

local title = Instance.new("TextLabel", topbar)
title.Size = UDim2.new(0, 200, 0, 16); title.Position = UDim2.new(0, 42, 0, 5)
title.BackgroundTransparency = 1; title.Text = "XJ HUB 1.4"
title.TextColor3 = Color3.new(1,1,1); title.Font = Enum.Font.GothamBold
title.TextSize = 13; title.TextXAlignment = Enum.TextXAlignment.Left

local sub = Instance.new("TextLabel", topbar)
sub.Size = UDim2.new(0, 250, 0, 12); sub.Position = UDim2.new(0, 42, 0, 22)
sub.BackgroundTransparency = 1
sub.Text = "🟢安全 · 🟡中 · 🔴危险 · 拦截 " .. BLOCKED .. " · 清理 " .. CLEANED
sub.TextColor3 = Color3.fromRGB(120, 230, 150)
sub.Font = Enum.Font.Gotham; sub.TextSize = 9
sub.TextXAlignment = Enum.TextXAlignment.Left

local minBtn = Instance.new("TextButton", topbar)
minBtn.Size = UDim2.new(0, 24, 0, 24); minBtn.Position = UDim2.new(1, -60, 0.5, -12)
minBtn.BackgroundColor3 = Color3.fromRGB(251, 191, 36); minBtn.Text = "－"
minBtn.TextColor3 = Color3.new(1,1,1); minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 15; minBtn.BorderSizePixel = 0
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 6)

local closeBtn = Instance.new("TextButton", topbar)
closeBtn.Size = UDim2.new(0, 24, 0, 24); closeBtn.Position = UDim2.new(1, -30, 0.5, -12)
closeBtn.BackgroundColor3 = Color3.fromRGB(239, 68, 68); closeBtn.Text = "×"
closeBtn.TextColor3 = Color3.new(1,1,1); closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 17; closeBtn.BorderSizePixel = 0
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

-- 拖拽
local drag, dStart, dPos = false, nil, nil
topbar.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        drag = true; dStart = i.Position; dPos = main.Position
    end
end)
UIS.InputChanged:Connect(function(i)
    if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
        local d = i.Position - dStart
        local vp2 = WS.CurrentCamera and WS.CurrentCamera.ViewportSize or Vector2.new(1920,1080)
        local nx = math.clamp(dPos.X.Offset + d.X, 100 - main.AbsoluteSize.X, vp2.X - 100)
        local ny = math.clamp(dPos.Y.Offset + d.Y, 0, vp2.Y - 40)
        main.Position = UDim2.new(0, nx, 0, ny)
    end
end)
UIS.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        drag = false
    end
end)

-- ========== 灵动岛 ==========
local island = Instance.new("TextButton", screen)
island.Size = UDim2.new(0, 160, 0, 38)
island.Position = UDim2.new(0.5, -80 * uiScale, 0, 12)
island.BackgroundColor3 = Color3.fromRGB(10, 10, 16)
island.BackgroundTransparency = 0.05
island.Text = ""; island.BorderSizePixel = 0
island.AutoButtonColor = false
island.Visible = false
island.ZIndex = 50
Instance.new("UICorner", island).CornerRadius = UDim.new(1, 0)
Instance.new("UIScale", island).Scale = uiScale
local isStroke = Instance.new("UIStroke", island)
isStroke.Color = Color3.fromRGB(168, 85, 247); isStroke.Thickness = 1.4
local isAvatar = Instance.new("ImageLabel", island)
isAvatar.Size = UDim2.new(0, 28, 0, 28); isAvatar.Position = UDim2.new(0, 5, 0.5, -14)
isAvatar.BackgroundColor3 = Color3.fromRGB(40, 40, 55); isAvatar.BorderSizePixel = 0
isAvatar.Image = userInfo.thumb
Instance.new("UICorner", isAvatar).CornerRadius = UDim.new(1, 0)
local isTitle = Instance.new("TextLabel", island)
isTitle.Size = UDim2.new(1, -95, 0, 12); isTitle.Position = UDim2.new(0, 38, 0, 5)
isTitle.BackgroundTransparency = 1; isTitle.Text = "XJ Hub v1.4"
isTitle.TextColor3 = Color3.new(1, 1, 1); isTitle.Font = Enum.Font.GothamBold
isTitle.TextSize = 11; isTitle.TextXAlignment = Enum.TextXAlignment.Left
local isInfo = Instance.new("TextLabel", island)
isInfo.Size = UDim2.new(1, -95, 0, 10); isInfo.Position = UDim2.new(0, 38, 0, 21)
isInfo.BackgroundTransparency = 1; isInfo.Text = "FPS 0 · Ping 0ms"
isInfo.TextColor3 = Color3.fromRGB(160, 160, 180); isInfo.Font = Enum.Font.Gotham
isInfo.TextSize = 9; isInfo.TextXAlignment = Enum.TextXAlignment.Left
local isDot = Instance.new("Frame", island)
isDot.Size = UDim2.new(0, 8, 0, 8); isDot.Position = UDim2.new(1, -18, 0.5, -4)
isDot.BackgroundColor3 = Color3.fromRGB(52, 219, 137); isDot.BorderSizePixel = 0
Instance.new("UICorner", isDot).CornerRadius = UDim.new(1, 0)
Tween:Create(isDot, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
    BackgroundTransparency = 0.6,
}):Play()
task.spawn(function()
    while screen.Parent do
        pcall(function()
            isInfo.Text = string.format("FPS %d · Ping %dms · 拦截 %d", stats.fps, stats.ping, BLOCKED)
        end)
        task.wait(0.5)
    end
end)

local iDrag, iStart, iPos, iMoved = false, nil, nil, false
island.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        iDrag = true; iStart = i.Position; iPos = island.Position; iMoved = false
    end
end)
UIS.InputChanged:Connect(function(i)
    if iDrag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
        local d = i.Position - iStart
        if math.abs(d.X) > 5 or math.abs(d.Y) > 5 then iMoved = true end
        island.Position = UDim2.new(iPos.X.Scale, iPos.X.Offset + d.X, iPos.Y.Scale, iPos.Y.Offset + d.Y)
    end
end)

local minimized = false
local function minimize()
    if minimized then return end
    minimized = true
    Tween:Create(main, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 100, 0, 60),
    }):Play()
    task.wait(0.28)
    main.Visible = false
    island.Visible = true
    island.Size = UDim2.new(0, 0, 0, 38)
    Tween:Create(island, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 160, 0, 38),
    }):Play()
end
local function restore()
    if not minimized then return end
    minimized = false
    Tween:Create(island, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 0, 0, 38),
    }):Play()
    task.wait(0.22)
    island.Visible = false
    main.Visible = true
    main.Size = UDim2.new(0, 100, 0, 60)
    Tween:Create(main, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 460, 0, 340),
    }):Play()
end
UIS.InputEnded:Connect(function(i)
    if iDrag and (i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch) then
        iDrag = false
        if not iMoved then pcall(restore) end
    end
end)
minBtn.MouseButton1Click:Connect(minimize)
closeBtn.MouseButton1Click:Connect(function()
    for _, child in ipairs(notifyHolder:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    screen:Destroy()
end)

-- 侧栏
local sidebar = Instance.new("Frame", main)
sidebar.Size = UDim2.new(0, 90, 1, -54)
sidebar.Position = UDim2.new(0, 6, 0, 48)
sidebar.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
sidebar.BackgroundTransparency = 0.2
sidebar.BorderSizePixel = 0
Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0, 8)
local innerNav = Instance.new("ScrollingFrame", sidebar)
innerNav.Size = UDim2.new(1, 0, 1, 0)
innerNav.BackgroundTransparency = 1; innerNav.BorderSizePixel = 0
innerNav.ScrollBarThickness = 0
innerNav.CanvasSize = UDim2.new(0, 0, 0, 0)
innerNav.AutomaticCanvasSize = Enum.AutomaticSize.Y
local nl = Instance.new("UIListLayout", innerNav); nl.Padding = UDim.new(0, 2)
local np = Instance.new("UIPadding", innerNav)
np.PaddingTop = UDim.new(0, 4); np.PaddingBottom = UDim.new(0, 4)
np.PaddingLeft = UDim.new(0, 4); np.PaddingRight = UDim.new(0, 4)

local content = Instance.new("Frame", main)
content.Size = UDim2.new(1, -104, 1, -54)
content.Position = UDim2.new(0, 98, 0, 48)
content.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
content.BackgroundTransparency = 0.2
content.BorderSizePixel = 0
Instance.new("UICorner", content).CornerRadius = UDim.new(0, 8)

local pages, tabButtons = {}, {}
local currentTab

local function createPage(name)
    local page = Instance.new("ScrollingFrame", content)
    page.Size = UDim2.new(1, -10, 1, -10)
    page.Position = UDim2.new(0, 5, 0, 5)
    page.BackgroundTransparency = 1; page.BorderSizePixel = 0
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = Color3.fromRGB(168, 85, 247)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.Visible = false
    local ll = Instance.new("UIListLayout", page); ll.Padding = UDim.new(0, 4)
    pages[name] = page
end

local tabCount = 0
local function createTab(name, icon)
    tabCount = tabCount + 1
    local btn = Instance.new("TextButton", innerNav)
    btn.Size = UDim2.new(1, 0, 0, 28)
    btn.BackgroundColor3 = Color3.fromRGB(168, 85, 247)
    btn.BackgroundTransparency = 1
    btn.Text = ""; btn.BorderSizePixel = 0
    btn.LayoutOrder = tabCount; btn.AutoButtonColor = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    local ico = Instance.new("TextLabel", btn)
    ico.Size = UDim2.new(0, 16, 1, 0); ico.Position = UDim2.new(0, 6, 0, 0)
    ico.BackgroundTransparency = 1; ico.Text = icon or ""
    ico.TextColor3 = Color3.fromRGB(190, 190, 210)
    ico.Font = Enum.Font.GothamBold; ico.TextSize = 11
    local lbl = Instance.new("TextLabel", btn)
    lbl.Size = UDim2.new(1, -24, 1, 0); lbl.Position = UDim2.new(0, 24, 0, 0)
    lbl.BackgroundTransparency = 1; lbl.Text = name
    lbl.TextColor3 = Color3.fromRGB(190, 190, 210)
    lbl.Font = Enum.Font.GothamMedium; lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    tabButtons[name] = { btn=btn, lbl=lbl, ico=ico }
    btn.MouseButton1Click:Connect(function()
        if currentTab == name then return end
        for _, pg in pairs(pages) do pg.Visible = false end
        pages[name].Visible = true
        currentTab = name
        for n, t in pairs(tabButtons) do
            local c = n == name and Color3.new(1,1,1) or Color3.fromRGB(190,190,210)
            t.lbl.TextColor3 = c; t.ico.TextColor3 = c
            t.btn.BackgroundTransparency = n == name and 0.75 or 1
        end
    end)
end

local function riskPrefix(r)
    return r=="safe" and "🟢 " or r=="mid" and "🟡 " or r=="risk" and "🔴 " or ""
end
local function riskBg(r)
    return r=="safe" and Color3.fromRGB(24,36,28)
        or r=="mid"  and Color3.fromRGB(38,34,22)
        or r=="risk" and Color3.fromRGB(42,20,24)
        or Color3.fromRGB(28,28,40)
end
local function riskTextColor(r)
    return r=="safe" and Color3.fromRGB(150,240,170)
        or r=="mid"  and Color3.fromRGB(255,220,130)
        or r=="risk" and Color3.fromRGB(255,150,150)
        or Color3.fromRGB(235,235,245)
end

local function createToggle(parent, name, def, cb, risk)
    risk = risk or "safe"
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(1, 0, 0, 32)
    btn.BackgroundColor3 = riskBg(risk)
    btn.BackgroundTransparency = 0.1
    btn.Text = ""; btn.BorderSizePixel = 0; btn.AutoButtonColor = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    local lbl = Instance.new("TextLabel", btn)
    lbl.Size = UDim2.new(1, -56, 1, 0); lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = riskPrefix(risk) .. name
    lbl.TextColor3 = riskTextColor(risk)
    lbl.Font = Enum.Font.GothamMedium; lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    local ind = Instance.new("Frame", btn)
    ind.Size = UDim2.new(0, 36, 0, 18); ind.Position = UDim2.new(1, -44, 0.5, -9)
    ind.BackgroundColor3 = Color3.fromRGB(50,50,65); ind.BorderSizePixel = 0
    Instance.new("UICorner", ind).CornerRadius = UDim.new(1, 0)
    local knob = Instance.new("Frame", ind)
    knob.Size = UDim2.new(0, 14, 0, 14); knob.Position = UDim2.new(0, 2, 0.5, -7)
    knob.BackgroundColor3 = Color3.new(1,1,1); knob.BorderSizePixel = 0
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
    local state = def or false
    local function refresh()
        Tween:Create(knob, TweenInfo.new(0.12), {
            Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
        }):Play()
        Tween:Create(ind, TweenInfo.new(0.12), {
            BackgroundColor3 = state and Color3.fromRGB(190, 80, 255) or Color3.fromRGB(50, 50, 65)
        }):Play()
    end
    refresh()
    btn.MouseButton1Click:Connect(function()
        state = not state; refresh()
        if cb then pcall(cb, state) end
        if state then notify(name, "功能已开启", "success", 2)
        else notify(name, "功能已关闭", "warn", 2) end
    end)
end

local function createSlider(parent, name, min, max, def, cb, risk)
    risk = risk or "safe"
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, 0, 0, 46)
    frame.BackgroundColor3 = riskBg(risk)
    frame.BackgroundTransparency = 0.1; frame.BorderSizePixel = 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)
    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(1, -56, 0, 14); lbl.Position = UDim2.new(0, 10, 0, 4)
    lbl.BackgroundTransparency = 1
    lbl.Text = riskPrefix(risk) .. name
    lbl.TextColor3 = riskTextColor(risk)
    lbl.Font = Enum.Font.GothamMedium; lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    local vLbl = Instance.new("TextLabel", frame)
    vLbl.Size = UDim2.new(0, 46, 0, 14); vLbl.Position = UDim2.new(1, -56, 0, 4)
    vLbl.BackgroundTransparency = 1; vLbl.Text = tostring(def)
    vLbl.TextColor3 = Color3.fromRGB(190,130,255)
    vLbl.Font = Enum.Font.GothamBold; vLbl.TextSize = 12
    vLbl.TextXAlignment = Enum.TextXAlignment.Right
    local track = Instance.new("TextButton", frame)
    track.Size = UDim2.new(1, -20, 0, 6); track.Position = UDim2.new(0, 10, 0, 28)
    track.BackgroundColor3 = Color3.fromRGB(50,50,65)
    track.Text = ""; track.BorderSizePixel = 0; track.AutoButtonColor = false
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
    local fill = Instance.new("Frame", track)
    fill.Size = UDim2.new((def - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(168,85,247); fill.BorderSizePixel = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
    local dot = Instance.new("Frame", track)
    dot.Size = UDim2.new(0, 12, 0, 12); dot.Position = UDim2.new((def - min) / (max - min), -6, 0.5, -6)
    dot.BackgroundColor3 = Color3.new(1,1,1); dot.BorderSizePixel = 0
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
    Instance.new("UIStroke", dot).Color = Color3.fromRGB(168,85,247)
    local dg = false
    local function update(x)
        local pos = math.clamp((x - track.AbsolutePosition.X) / math.max(1, track.AbsoluteSize.X), 0, 1)
        local v = math.floor(min + pos * (max - min) + 0.5)
        fill.Size = UDim2.new(pos, 0, 1, 0)
        dot.Position = UDim2.new(pos, -6, 0.5, -6)
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

local function createDropdown(parent, name, options, defIdx, cb, risk)
    risk = risk or "safe"
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(1, 0, 0, 32)
    btn.BackgroundColor3 = riskBg(risk)
    btn.BackgroundTransparency = 0.1
    btn.Text = ""; btn.BorderSizePixel = 0; btn.AutoButtonColor = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    local lbl = Instance.new("TextLabel", btn)
    lbl.Size = UDim2.new(1, -100, 1, 0); lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = riskPrefix(risk) .. name
    lbl.TextColor3 = riskTextColor(risk)
    lbl.Font = Enum.Font.GothamMedium; lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    local vBox = Instance.new("TextButton", btn)
    vBox.Size = UDim2.new(0, 84, 0, 22); vBox.Position = UDim2.new(1, -92, 0.5, -11)
    vBox.BackgroundColor3 = Color3.fromRGB(45,45,60)
    vBox.Text = options[defIdx or 1]
    vBox.TextColor3 = Color3.fromRGB(235,235,245)
    vBox.Font = Enum.Font.Gotham; vBox.TextSize = 10
    vBox.BorderSizePixel = 0; vBox.AutoButtonColor = false
    Instance.new("UICorner", vBox).CornerRadius = UDim.new(0, 5)
    local idx = defIdx or 1
    vBox.MouseButton1Click:Connect(function()
        idx = idx % #options + 1
        vBox.Text = options[idx]
        if cb then pcall(cb, options[idx], idx) end
    end)
end

-- 页面
createPage("主页"); createPage("玩家"); createPage("战斗"); createPage("自瞄")
createPage("透视"); createPage("刷钱"); createPage("飞车"); createPage("杂项"); createPage("自检")

createTab("主页", "🏠"); createTab("玩家", "👤"); createTab("战斗", "⚔️")
createTab("自瞄", "🎯"); createTab("透视", "👁️"); createTab("刷钱", "💰")
createTab("飞车", "🚗"); createTab("杂项", "⚡"); createTab("自检", "🧪")

pages["主页"].Visible = true; currentTab = "主页"
tabButtons["主页"].lbl.TextColor3 = Color3.new(1,1,1)
tabButtons["主页"].ico.TextColor3 = Color3.new(1,1,1)
tabButtons["主页"].btn.BackgroundTransparency = 0.75

-- 主页卡片
local userCard = Instance.new("Frame", pages["主页"])
userCard.Size = UDim2.new(1, 0, 0, 70)
userCard.BackgroundColor3 = Color3.fromRGB(28,28,40)
userCard.BackgroundTransparency = 0.1; userCard.BorderSizePixel = 0
Instance.new("UICorner", userCard).CornerRadius = UDim.new(0, 7)
local avatar = Instance.new("ImageLabel", userCard)
avatar.Size = UDim2.new(0, 55, 0, 55); avatar.Position = UDim2.new(0, 8, 0.5, -27)
avatar.BackgroundColor3 = Color3.fromRGB(40,40,55); avatar.BorderSizePixel = 0
avatar.Image = userInfo.thumb
Instance.new("UICorner", avatar).CornerRadius = UDim.new(0, 27)
Instance.new("UIStroke", avatar).Color = Color3.fromRGB(168,85,247)
local nameLbl = Instance.new("TextLabel", userCard)
nameLbl.Size = UDim2.new(1, -74, 0, 16); nameLbl.Position = UDim2.new(0, 70, 0, 8)
nameLbl.BackgroundTransparency = 1; nameLbl.Text = userInfo.name
nameLbl.TextColor3 = Color3.new(1,1,1); nameLbl.Font = Enum.Font.GothamBold
nameLbl.TextSize = 13; nameLbl.TextXAlignment = Enum.TextXAlignment.Left
local infoLbl = Instance.new("TextLabel", userCard)
infoLbl.Size = UDim2.new(1, -74, 0, 12); infoLbl.Position = UDim2.new(0, 70, 0, 26)
infoLbl.BackgroundTransparency = 1
infoLbl.Text = "@" .. userInfo.displayName .. " · " .. userInfo.membership
infoLbl.TextColor3 = Color3.fromRGB(180,180,200); infoLbl.Font = Enum.Font.Gotham
infoLbl.TextSize = 10; infoLbl.TextXAlignment = Enum.TextXAlignment.Left
local idLbl = Instance.new("TextLabel", userCard)
idLbl.Size = UDim2.new(1, -74, 0, 12); idLbl.Position = UDim2.new(0, 70, 0, 40)
idLbl.BackgroundTransparency = 1
idLbl.Text = "ID: " .. userInfo.userId .. " · 账号 " .. userInfo.accountAge .. " 天"
idLbl.TextColor3 = Color3.fromRGB(180,180,200); idLbl.Font = Enum.Font.Gotham
idLbl.TextSize = 10; idLbl.TextXAlignment = Enum.TextXAlignment.Left

local statsCard = Instance.new("Frame", pages["主页"])
statsCard.Size = UDim2.new(1, 0, 0, 60)
statsCard.BackgroundColor3 = Color3.fromRGB(28,28,40)
statsCard.BackgroundTransparency = 0.1; statsCard.BorderSizePixel = 0
Instance.new("UICorner", statsCard).CornerRadius = UDim.new(0, 7)
local statsTitle = Instance.new("TextLabel", statsCard)
statsTitle.Size = UDim2.new(1, -20, 0, 16); statsTitle.Position = UDim2.new(0, 10, 0, 5)
statsTitle.BackgroundTransparency = 1; statsTitle.Text = "📊 实时数据"
statsTitle.TextColor3 = Color3.fromRGB(150,200,255); statsTitle.Font = Enum.Font.GothamBold
statsTitle.TextSize = 11; statsTitle.TextXAlignment = Enum.TextXAlignment.Left
local statsRow = Instance.new("Frame", statsCard)
statsRow.Size = UDim2.new(1, -20, 0, 32); statsRow.Position = UDim2.new(0, 10, 0, 22)
statsRow.BackgroundTransparency = 1
local srl = Instance.new("UIListLayout", statsRow)
srl.FillDirection = Enum.FillDirection.Horizontal; srl.Padding = UDim.new(0, 5)
local function makeCell(parent, label, color)
    local cell = Instance.new("Frame", parent)
    cell.Size = UDim2.new(1/3, -4, 1, 0)
    cell.BackgroundColor3 = Color3.fromRGB(22,22,32); cell.BorderSizePixel = 0
    Instance.new("UICorner", cell).CornerRadius = UDim.new(0, 5)
    local t = Instance.new("TextLabel", cell)
    t.Size = UDim2.new(1, 0, 0, 10); t.Position = UDim2.new(0, 0, 0, 2)
    t.BackgroundTransparency = 1; t.Text = label
    t.TextColor3 = Color3.fromRGB(150,150,180)
    t.Font = Enum.Font.Gotham; t.TextSize = 8
    local v = Instance.new("TextLabel", cell)
    v.Size = UDim2.new(1, 0, 0, 16); v.Position = UDim2.new(0, 0, 0, 12)
    v.BackgroundTransparency = 1; v.Text = "0"
    v.TextColor3 = color; v.Font = Enum.Font.GothamBold; v.TextSize = 12
    return v
end
local fpsValue = makeCell(statsRow, "FPS", Color3.fromRGB(80,220,100))
local pingValue = makeCell(statsRow, "PING", Color3.fromRGB(255,200,100))
local espValueCell = makeCell(statsRow, "ESP", Color3.fromRGB(180,130,255))

task.spawn(function()
    while screen.Parent do
        pcall(function()
            fpsValue.Text = tostring(stats.fps)
            pingValue.Text = stats.ping .. "ms"
            pingValue.TextColor3 = stats.ping > 200 and Color3.fromRGB(255,80,60)
                or stats.ping > 100 and Color3.fromRGB(255,200,100)
                or Color3.fromRGB(80,220,100)
            espValueCell.Text = string.format("%.1fms", stats.espAvg * 1000)
        end)
        task.wait(0.5)
    end
end)

-- 功能页
createToggle(pages["玩家"], "无限体力", false, function(v) S.stamina=v end, "mid")
createToggle(pages["玩家"], "无限饥饿", false, function(v) S.food=v end, "mid")
createToggle(pages["玩家"], "无限子弹", false, function(v) S.infiniteAmmo=v end, "mid")
createToggle(pages["玩家"], "快速射击", false, function(v) S.rapidFire=v end, "mid")
createToggle(pages["玩家"], "修改行走速度", false, function(v)
    S.speedEnabled=v
    if not v and speedBV then speedBV:Destroy(); speedBV=nil end
end, "risk")
createSlider(pages["玩家"], "行走速度", 16, 500, 100, function(v) S.speedValue=v end, "risk")
createToggle(pages["玩家"], "跳跃修改", false, function(v) S.jumpEnabled=v end, "risk")
createSlider(pages["玩家"], "跳跃高度", 10, 200, 50, function(v) S.jumpPower=v end, "risk")
createToggle(pages["玩家"], "无限跳跃", false, function(v) S.infiniteJump=v end, "risk")

createToggle(pages["战斗"], "杀戮光环", false, function(v) S.auraEnabled=v end, "mid")
createSlider(pages["战斗"], "光环范围", 50, 800, 200, function(v) S.auraRange=v end, "mid")
createSlider(pages["战斗"], "光环伤害", 1, 100, 5, function(v) S.auraDamage=v end, "mid")
createToggle(pages["战斗"], "拟人化延迟", true, function(v) S.auraHumanize=v end, "safe")
createToggle(pages["战斗"], "隐蔽模式 (0.4~0.6s)", true, function(v) S.auraStealth=v end, "safe")
createToggle(pages["战斗"], "自动铐 (节流)", false, function(v) S.autoCuff=v end, "mid")

createToggle(pages["自瞄"], "开启自瞄 (右键触发)", false, function(v) S.aimbot.enabled=v end, "safe")
createToggle(pages["自瞄"], "显示 FOV 圈", true, function(v) S.aimbot.showFov=v end, "safe")
createToggle(pages["自瞄"], "显示追踪线", false, function(v) S.aimbot.showTracer=v end, "safe")
createToggle(pages["自瞄"], "好友检测", false, function(v) S.aimbot.friendCheck=v end, "safe")
createToggle(pages["自瞄"], "墙壁检测", false, function(v) S.aimbot.wallCheck=v end, "safe")
createToggle(pages["自瞄"], "队伍检测", false, function(v) S.aimbot.teamCheck=v end, "safe")
createToggle(pages["自瞄"], "船员检测", false, function(v) S.aimbot.crewCheck=v end, "safe")
createDropdown(pages["自瞄"], "FOV 颜色", {"红色","绿色","蓝色","紫色","白色","彩虹"}, 1, function(v) S.aimbot.color=v end, "safe")
createDropdown(pages["自瞄"], "瞄准部位", {"头部","胸部"}, 1, function(v) S.aimbot.targetPart=v end, "safe")
createSlider(pages["自瞄"], "FOV 大小", 20, 400, 120, function(v) S.aimbot.fov=v end, "safe")
createSlider(pages["自瞄"], "平滑度", 1, 10, 3, function(v) S.aimbot.smoothness=v/10 end, "safe")

createToggle(pages["透视"], "开启透视", false, function(v) S.esp.enabled=v end, "safe")
createToggle(pages["透视"], "显示名字", true, function(v) S.esp.name=v end, "safe")
createToggle(pages["透视"], "显示职业", true, function(v) S.esp.team=v end, "safe")
createToggle(pages["透视"], "显示距离", true, function(v) S.esp.distance=v end, "safe")
createToggle(pages["透视"], "显示血量", true, function(v) S.esp.health=v end, "safe")
createToggle(pages["透视"], "显示血条", true, function(v) S.esp.bar=v end, "safe")
createToggle(pages["透视"], "显示高亮", true, function(v) S.esp.highlight=v end, "safe")
createToggle(pages["透视"], "队伍着色", true, function(v) S.esp.colorByTeam=v end, "safe")

-- 刷钱页
createToggle(pages["刷钱"], "自动捡钱", false, function(v) S.autoMoney=v end, "safe")
createToggle(pages["刷钱"], "自动农民", false, function(v) S.autoFarmer=v end, "safe")
createToggle(pages["刷钱"], "自动接任务", false, function(v) S.autoMission=v end, "mid")
createToggle(pages["刷钱"], "自动黑客小游戏", false, function(v) S.autoHack=v end, "mid")
createToggle(pages["刷钱"], "自动出租车", false, function(v)
    if v then S.autoTaxi = true; startTaxi() else stopTaxi() end
end, "mid")
createToggle(pages["刷钱"], "出租车安全模式", false, function(v) S.taxiSafe=v end, "safe")
createDropdown(pages["刷钱"], "出租车延迟模式", {"随机时间", "距离测算"}, 1, function(v) S.taxiDelayMode=v end, "safe")
createToggle(pages["刷钱"], "自动高尔夫", false, function(v)
    if v then S.autoGolf = true; startGolf() else stopGolf() end
end, "mid")

createToggle(pages["飞车"], "飞行模式 (物理)", false, function(v)
    S.flyEnabled=v; if v then startFly() else stopFly() end
end, "risk")
createToggle(pages["飞车"], "穿墙 Noclip (定向)", false, function(v)
    S.noclip=v; if v then startNoclip() else stopNoclip() end
end, "risk")
createSlider(pages["飞车"], "飞行速度", 10, 300, 50, function(v) S.flySpeed=v end, "risk")

createToggle(pages["杂项"], "隐身", false, function(v) S.ghost=v end, "safe")
createToggle(pages["杂项"], "防布娃娃", false, function(v) S.noRagdoll=v end, "safe")

-- 自检页
local selfCard = Instance.new("Frame", pages["自检"])
selfCard.Size = UDim2.new(1, 0, 0, 260)
selfCard.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
selfCard.BackgroundTransparency = 0.1; selfCard.BorderSizePixel = 0
Instance.new("UICorner", selfCard).CornerRadius = UDim.new(0, 7)
local selfTitle = Instance.new("TextLabel", selfCard)
selfTitle.Size = UDim2.new(1, -20, 0, 16); selfTitle.Position = UDim2.new(0, 10, 0, 6)
selfTitle.BackgroundTransparency = 1; selfTitle.Text = "🧪 虚拟测试面板 v1.4"
selfTitle.TextColor3 = Color3.fromRGB(150,200,255); selfTitle.Font = Enum.Font.GothamBold
selfTitle.TextSize = 11; selfTitle.TextXAlignment = Enum.TextXAlignment.Left
local selfOut = Instance.new("TextLabel", selfCard)
selfOut.Size = UDim2.new(1, -20, 1, -40); selfOut.Position = UDim2.new(0, 10, 0, 24)
selfOut.BackgroundTransparency = 1
selfOut.Text = "点击下方按钮开始自检"
selfOut.TextColor3 = Color3.fromRGB(220, 220, 235)
selfOut.Font = Enum.Font.Code; selfOut.TextSize = 10
selfOut.TextXAlignment = Enum.TextXAlignment.Left
selfOut.TextYAlignment = Enum.TextYAlignment.Top
selfOut.TextWrapped = true
local runTestBtn = Instance.new("TextButton", selfCard)
runTestBtn.Size = UDim2.new(1, -20, 0, 26); runTestBtn.Position = UDim2.new(0, 10, 1, -34)
runTestBtn.BackgroundColor3 = Color3.fromRGB(168, 85, 247)
runTestBtn.Text = "▶ 运行全部自检"
runTestBtn.TextColor3 = Color3.new(1,1,1)
runTestBtn.Font = Enum.Font.GothamBold; runTestBtn.TextSize = 11
runTestBtn.BorderSizePixel = 0
Instance.new("UICorner", runTestBtn).CornerRadius = UDim.new(0, 6)

local function runTests()
    local lines = {}; local pass, fail = 0, 0
    local function T(name, fn)
        local okk, res = pcall(fn)
        if okk and res then lines[#lines+1] = "✅ " .. name; pass = pass + 1
        else lines[#lines+1] = "❌ " .. name .. (type(res)=="string" and (": "..res) or ""); fail = fail + 1 end
    end
    T("属性欺骗已装 (精准)", function() return SPOOF.installed end)
    T("属性欺骗计数 > 0", function() return SPOOF.count > 0 end)
    T("远程拦截已装 (精确)", function() return CAP.hookmm end)
    T("远程节流系统", function() return type(throttledFire) == "function" end)
    T("连接清理 (getcallingscript)", function() return CAP.getcall end)
    T("Drawing API", function() return CAP.drawing end)
    T("getgc 可用", function() return CAP.getgc end)
    T("gethui 可用", function() return CAP.gethui end)
    T("fireproximityprompt", function() return CAP.firepp end)
    T("getconnections", function() return CAP.getconn end)
    T("Remote 已获取", function() return playerEvent ~= nil end)
    T("PlayerFunc 已获取", function() return playerFunc ~= nil end)
    T("本地角色存在", function() local c, h = getChar(); return c ~= nil and h ~= nil end)
    T("通知系统", function() notify("自检", "通知系统工作正常", "success", 1.5); return true end)
    T("行走速度物理层", function()
        S.speedEnabled = true; S.speedValue = 60; refreshSpeed(); task.wait(0.1)
        local _, h = getChar()
        local okv = speedBV ~= nil and h and h.WalkSpeed == SPOOF.walkSpeed
        S.speedEnabled = false; if speedBV then speedBV:Destroy(); speedBV = nil end
        return okv
    end)
    T("飞行物理层", function()
        S.flyEnabled = true; startFly(); task.wait(0.1)
        local okv = Fly.align ~= nil and Fly.bv ~= nil
        S.flyEnabled = false; stopFly()
        return okv
    end)
    T("Noclip 缓存优化", function()
        S.noclip = true; startNoclip(); task.wait(0.1)
        local okv = Noclip.conn ~= nil and #Noclip.parts > 0
        S.noclip = false; stopNoclip()
        return okv
    end)
    T("出租车目标查找", function() return type(findTaxiTarget) == "function" end)
    T("自瞄 FOV 绘制", function() return CAP.drawing and fovCircle ~= nil end)
    T("玩家数量可读", function() return #Players:GetPlayers() >= 1 end)

    lines[#lines+1] = ""
    lines[#lines+1] = string.format("结果: %d 通过 / %d 失败 / %d 总数", pass, fail, pass + fail)
    lines[#lines+1] = "拦截: " .. BLOCKED .. " | 欺骗: " .. SPOOF.count .. " | 清理: " .. CLEANED
    selfOut.Text = table.concat(lines, "\n")
    notify("自检完成", string.format("%d 通过 / %d 失败", pass, fail), fail == 0 and "success" or "warn", 3)
    return pass, fail
end
runTestBtn.MouseButton1Click:Connect(runTests)

-- 右键自瞄
UIS.InputBegan:Connect(function(i, g)
    if g then return end
    if i.UserInputType == Enum.UserInputType.MouseButton2 then S.aimbot.keyHeld = true end
end)
UIS.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton2 then S.aimbot.keyHeld = false end
end)

-- ========== 加载动画 ==========
local loading = Instance.new("Frame", screen)
loading.Size = UDim2.new(1, 0, 1, 0)
loading.BackgroundColor3 = Color3.fromRGB(0,0,0)
loading.BackgroundTransparency = 0.4
loading.BorderSizePixel = 0; loading.ZIndex = 100
local lCard = Instance.new("Frame", loading)
lCard.Size = UDim2.new(0, 250, 0, 130)
lCard.Position = UDim2.new(0.5, -125 * uiScale, 0.5, -65 * uiScale)
lCard.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
lCard.BackgroundTransparency = 0.05
lCard.BorderSizePixel = 0; lCard.ZIndex = 101
Instance.new("UICorner", lCard).CornerRadius = UDim.new(0, 12)
Instance.new("UIScale", lCard).Scale = uiScale
Instance.new("UIStroke", lCard).Color = Color3.fromRGB(168, 85, 247)
local lLogo = Instance.new("Frame", lCard)
lLogo.Size = UDim2.new(0, 44, 0, 44); lLogo.Position = UDim2.new(0.5, -22, 0, 12)
lLogo.BackgroundColor3 = Color3.fromRGB(168, 85, 247)
lLogo.BorderSizePixel = 0; lLogo.ZIndex = 102
Instance.new("UICorner", lLogo).CornerRadius = UDim.new(0, 11)
local lLT = Instance.new("TextLabel", lLogo)
lLT.Size = UDim2.new(1,0,1,0); lLT.BackgroundTransparency = 1
lLT.Text = "嘉"; lLT.TextColor3 = Color3.new(1,1,1)
lLT.Font = Enum.Font.GothamBlack; lLT.TextSize = 22; lLT.ZIndex = 103
local lTitle = Instance.new("TextLabel", lCard)
lTitle.Size = UDim2.new(1, 0, 0, 14); lTitle.Position = UDim2.new(0, 0, 0, 62)
lTitle.BackgroundTransparency = 1; lTitle.Text = "XJ HUB 1.4"
lTitle.TextColor3 = Color3.new(1,1,1); lTitle.Font = Enum.Font.GothamBold
lTitle.TextSize = 12; lTitle.ZIndex = 102
local lBarBg = Instance.new("Frame", lCard)
lBarBg.Size = UDim2.new(1, -36, 0, 4); lBarBg.Position = UDim2.new(0, 18, 0, 86)
lBarBg.BackgroundColor3 = Color3.fromRGB(40,40,55)
lBarBg.BorderSizePixel = 0; lBarBg.ZIndex = 102
Instance.new("UICorner", lBarBg).CornerRadius = UDim.new(1, 0)
local lBarFill = Instance.new("Frame", lBarBg)
lBarFill.Size = UDim2.new(0, 0, 1, 0)
lBarFill.BackgroundColor3 = Color3.fromRGB(168, 85, 247)
lBarFill.BorderSizePixel = 0; lBarFill.ZIndex = 103
Instance.new("UICorner", lBarFill).CornerRadius = UDim.new(1, 0)
local lStatus = Instance.new("TextLabel", lCard)
lStatus.Size = UDim2.new(1, -36, 0, 14); lStatus.Position = UDim2.new(0, 18, 0, 98)
lStatus.BackgroundTransparency = 1; lStatus.Text = "初始化..."
lStatus.TextColor3 = Color3.fromRGB(200,200,220)
lStatus.Font = Enum.Font.GothamMedium; lStatus.TextSize = 9
lStatus.TextXAlignment = Enum.TextXAlignment.Left; lStatus.ZIndex = 102

task.spawn(function()
    lStatus.Text = "挂载绕过层..."
    Tween:Create(lBarFill, TweenInfo.new(0.4, Enum.EasingStyle.Quint), { Size = UDim2.new(0.4, 0, 1, 0) }):Play()
    task.wait(0.4)
    lStatus.Text = "加载模块..."
    Tween:Create(lBarFill, TweenInfo.new(0.4, Enum.EasingStyle.Quint), { Size = UDim2.new(0.8, 0, 1, 0) }):Play()
    task.wait(0.35)
    lStatus.Text = "启动完成"
    Tween:Create(lBarFill, TweenInfo.new(0.3, Enum.EasingStyle.Quint), { Size = UDim2.new(1, 0, 1, 0) }):Play()
    task.wait(0.3)
    Tween:Create(loading, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
    Tween:Create(lCard, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
    for _, d in ipairs(lCard:GetDescendants()) do
        if d:IsA("TextLabel") then
            Tween:Create(d, TweenInfo.new(0.25), { TextTransparency = 1 }):Play()
        end
    end
    task.wait(0.35)
    loading:Destroy()
    main.Visible = true
    main.Size = UDim2.new(0, 80, 0, 60)
    Tween:Create(main, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 460, 0, 340),
    }):Play()
    task.wait(0.6)
    notify("XJ Hub", "v1.4 加载完成 · 拦截 " .. BLOCKED .. " · 清理 " .. CLEANED, "success", 3)
    pcall(runTests)
end)

ok("UI 构建完成")
inf("========== XJ Hub v1.4 启动完毕 ==========")
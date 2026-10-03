-- ============================================================
-- XJ Hub v1.6 · 移动端安全版 (iOS/Android 全适配)
-- 关键: iOS Delta 禁用 Hook, 保留全部 UI 功能
-- ============================================================

local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local RunSvc  = game:GetService("RunService")
local UIS     = game:GetService("UserInputService")
local Tween   = game:GetService("TweenService")
local WS      = game:GetService("Workspace")
local LP      = Players.LocalPlayer

local function log(m) pcall(function() print("[XJ] "..m) end) end
log("v1.6 启动")

-- ============================================================
-- 第一步: 设备 + 执行器检测 (最关键)
-- ============================================================
local Exec = { name="未知", isMobile=false, isIOS=false, isAndroid=false,
               isDelta=false, isCodex=false, isArceus=false,
               hasHook=false, hasDrawing=false, hasGetGC=false,
               hasFirePP=false, hasHui=false, hasGetConn=false }

-- 设备判断
Exec.isMobile = UIS.TouchEnabled and not UIS.MouseEnabled
local cam0 = WS.CurrentCamera
local vp = cam0 and cam0.ViewportSize or Vector2.new(1280, 720)

-- 执行器名称
pcall(function()
    if type(identifyexecutor) == "function" then
        Exec.name = tostring(identifyexecutor()) or "未知"
    end
end)

-- 系统判断 (通过执行器名 + UserInputService)
local uname = Exec.name:lower()
Exec.isDelta   = uname:find("delta") ~= nil
Exec.isCodex   = uname:find("codex") ~= nil
Exec.isArceus  = uname:find("arceus") ~= nil
Exec.isIOS     = Exec.isDelta or Exec.isCodex or uname:find("ios") ~= nil
    or (Exec.isMobile and uname:find("mac") ~= nil)
Exec.isAndroid = Exec.isMobile and not Exec.isIOS

-- 能力检测 (全部 pcall 包裹)
local function tryCap(f) local v=false; pcall(function() v=f() end); return v end
Exec.hasHook     = tryCap(function() return type(hookmetamethod)=="function" and type(newcclosure)=="function" end)
Exec.hasDrawing  = tryCap(function() return type(Drawing)=="table" and type(Drawing.new)=="function" end)
Exec.hasGetGC    = tryCap(function() return type(getgc)=="function" end)
Exec.hasFirePP   = tryCap(function() return type(fireproximityprompt)=="function" end)
Exec.hasHui      = tryCap(function() return type(gethui)=="function" end)
Exec.hasGetConn  = tryCap(function() return type(getconnections)=="function" end)

-- 关键规则: iOS 上强制禁用 Hook
if Exec.isIOS then
    Exec.hasHook = false
    log("iOS 检测: Hook 层已强制禁用")
end

-- 关键规则: 手机端禁用 Drawing (用 BillboardGui 替代)
if Exec.isMobile then
    Exec.hasDrawing = false
    log("移动端: Drawing 已禁用")
end

log(string.format("设备: %s | 执行器: %s | Hook: %s | Drawing: %s",
    Exec.isMobile and (Exec.isIOS and "iOS" or "Android") or "桌面",
    Exec.name, tostring(Exec.hasHook), tostring(Exec.hasDrawing)))

-- ============================================================
-- 第二步: ScreenGui 创建 (多路径容错)
-- ============================================================
local uiParent
if Exec.hasHui then pcall(function() uiParent = gethui() end) end
if not uiParent then pcall(function() uiParent = game:GetService("CoreGui") end) end
if not uiParent then pcall(function() uiParent = LP:WaitForChild("PlayerGui", 5) end) end
if not uiParent then uiParent = game:GetService("CoreGui") end

local oldGui = uiParent:FindFirstChild("XJHubUI")
if oldGui then pcall(function() oldGui:Destroy() end) end

local screen = Instance.new("ScreenGui")
screen.Name = "XJHubUI"
screen.ResetOnSpawn = false
pcall(function() screen.IgnoreGuiInset = true end)
pcall(function() screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling end)
screen.Parent = uiParent
log("ScreenGui 已创建")

-- ============================================================
-- 第三步: 工具函数
-- ============================================================
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

-- ============================================================
-- 第四步: 游戏框架 (全 pcall)
-- ============================================================
local remote, playerEvent, playerFunc
pcall(function() remote = RS:WaitForChild("Remote", 8) end)
if remote then
    pcall(function() playerEvent = remote:WaitForChild("PlayerEvent", 8) end)
    pcall(function() playerFunc = remote:WaitForChild("PlayerFunc", 8) end)
end

local Core, Character, Controls
pcall(function()
    local fw = LP:WaitForChild("PlayerScripts", 8):WaitForChild("Framework", 8)
    Core = require(fw:WaitForChild("Core", 8))
    Character = require(fw:WaitForChild("Character", 8))
end)
pcall(function()
    Controls = require(LP.PlayerScripts:WaitForChild("PlayerModule")):GetControls()
end)

-- ============================================================
-- 第五步: 状态表
-- ============================================================
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
    autoTaxi=false, taxiSafe=false,
    autoGolf=false,
    flyEnabled=false, flySpeed=50, noclip=false,
    ghost=false, noRagdoll=false,
}

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

-- 好友
local friendSet = {}
task.spawn(function()
    pcall(function()
        local cursor, n = "", 0
        repeat
            n = n + 1; if n > 15 then break end
            local page = LP:GetFriendsAsync(cursor); if not page then break end
            for _, f in ipairs(page:GetCurrentPage()) do friendSet[f.Id] = true end
            cursor = page.Cursor
        until not cursor or cursor == ""
    end)
end)
local function isFriend(p) return friendSet[p.UserId] == true end

-- 性能
local stats = { fps=0, frames=0, lastTick=tick(), ping=0, espAvg=0 }
task.spawn(function()
    while screen.Parent do
        pcall(function() stats.ping = math.floor((LP:GetNetworkPing() or 0) * 1000) end)
        task.wait(1.5)
    end
end)

local userInfo = {
    name=LP.Name, displayName=LP.DisplayName or LP.Name,
    userId=LP.UserId, accountAge=LP.AccountAge or 0,
    membership=tostring(LP.MembershipType):gsub("Enum.MembershipType%.", ""),
    thumb="rbxthumb://type=AvatarHeadShot&id="..LP.UserId.."&w=150&h=150",
}

-- ============================================================
-- 第六步: 通知 (移动端轻量)
-- ============================================================
local notifyHolder = Instance.new("Frame", screen)
notifyHolder.Size = UDim2.new(0, 220, 1, -20)
notifyHolder.Position = UDim2.new(1, -230, 0, 10)
notifyHolder.BackgroundTransparency = 1
notifyHolder.ZIndex = 200
local nLayout = Instance.new("UIListLayout", notifyHolder)
nLayout.Padding = UDim.new(0, 5)
nLayout.SortOrder = Enum.SortOrder.LayoutOrder
local notifyOrder = 0

local function notify(title, desc, kind, duration)
    if not screen or not screen.Parent then return end
    kind = kind or "info"; duration = duration or 2
    notifyOrder = notifyOrder + 1
    local color = kind=="success" and Color3.fromRGB(60,220,100)
        or kind=="warn" and Color3.fromRGB(255,200,60)
        or kind=="error" and Color3.fromRGB(255,80,80)
        or Color3.fromRGB(100,180,255)
    local card = Instance.new("Frame", notifyHolder)
    card.Size = UDim2.new(1, 0, 0, 42)
    card.BackgroundColor3 = Color3.fromRGB(18,18,26)
    card.BackgroundTransparency = 0.1
    card.BorderSizePixel = 0
    card.LayoutOrder = notifyOrder
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke", card)
    stroke.Color = color; stroke.Thickness = 1.5
    local tLbl = Instance.new("TextLabel", card)
    tLbl.Size = UDim2.new(1, -20, 0, 14); tLbl.Position = UDim2.new(0, 10, 0, 5)
    tLbl.BackgroundTransparency = 1; tLbl.Text = title
    tLbl.TextColor3 = color; tLbl.Font = Enum.Font.GothamBold
    tLbl.TextSize = 11; tLbl.TextXAlignment = Enum.TextXAlignment.Left
    local dLbl = Instance.new("TextLabel", card)
    dLbl.Size = UDim2.new(1, -20, 0, 16); dLbl.Position = UDim2.new(0, 10, 0, 20)
    dLbl.BackgroundTransparency = 1; dLbl.Text = desc
    dLbl.TextColor3 = Color3.fromRGB(210,210,225)
    dLbl.Font = Enum.Font.Gotham; dLbl.TextSize = 10
    dLbl.TextXAlignment = Enum.TextXAlignment.Left
    card.Position = UDim2.new(1, 40, 0, 0)
    Tween:Create(card, TweenInfo.new(0.25), { Position = UDim2.new(0, 0, 0, 0) }):Play()
    task.spawn(function()
        task.wait(duration)
        pcall(function()
            if not card or not card.Parent then return end
            Tween:Create(card, TweenInfo.new(0.2), { Position = UDim2.new(1, 40, 0, 0), BackgroundTransparency = 1 }):Play()
            Tween:Create(stroke, TweenInfo.new(0.2), { Transparency = 1 }):Play()
            Tween:Create(tLbl, TweenInfo.new(0.2), { TextTransparency = 1 }):Play()
            Tween:Create(dLbl, TweenInfo.new(0.2), { TextTransparency = 1 }):Play()
            task.wait(0.25)
            if card then card:Destroy() end
        end)
    end)
end

-- ============================================================
-- 第七步: 物理功能模块
-- ============================================================

-- 速度 (BodyVelocity)
local speedBV = nil
local function refreshSpeed()
    local _, h, r = getChar(); if not h or not r then return end
    if S.speedEnabled and S.speedValue > 16 then
        if not speedBV or speedBV.Parent ~= r then
            if speedBV then pcall(function() speedBV:Destroy() end) end
            speedBV = Instance.new("BodyVelocity")
            speedBV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            speedBV.P = 1250; speedBV.Parent = r
        end
        local mv = h.MoveDirection
        speedBV.Velocity = mv.Magnitude > 0.01 and (mv.Unit * S.speedValue) or Vector3.zero
        if h.WalkSpeed ~= 16 then h.WalkSpeed = 16 end
    else
        if speedBV then pcall(function() speedBV:Destroy() end); speedBV = nil end
        h.WalkSpeed = S.speedValue
    end
end

-- 飞行
local Fly = {}
local function stopFly()
    pcall(function()
        if Fly.conn then Fly.conn:Disconnect() end
        if Fly.align then Fly.align:Destroy() end
        if Fly.att then Fly.att:Destroy() end
        if Fly.bv then Fly.bv:Destroy() end
        if Fly.bg then Fly.bg:Destroy() end
    end)
    Fly = {}
    local _, h = getChar()
    if h then h.PlatformStand=false; h.AutoRotate=true end
end
local function startFly()
    stopFly()
    local _, h, r = getChar(); if not r or not h then return end
    h.AutoRotate = false; h.PlatformStand = true
    pcall(function()
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
    end)
    Fly.conn = RunSvc.RenderStepped:Connect(function()
        if not S.flyEnabled or not Fly.align then return end
        local cam = WS.CurrentCamera; if not cam then return end
        local mv = Controls and Controls:GetMoveVector() or Vector3.zero
        local y = UIS:IsKeyDown(Enum.KeyCode.Space) and 1 or (UIS:IsKeyDown(Enum.KeyCode.LeftControl) and -1 or 0)
        local dir = cam.CFrame.LookVector * -mv.Z + cam.CFrame.RightVector * mv.X
        local moveVec = (dir + Vector3.new(0, y, 0)) * S.flySpeed
        pcall(function()
            Fly.align.Position = Fly.align.Position + moveVec * 0.05
            if Fly.bv then Fly.bv.Velocity = moveVec end
            if Fly.bg then Fly.bg.CFrame = cam.CFrame end
        end)
    end)
end

-- Noclip
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
    task.wait(0.5); rebuildNoclipParts()
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
-- 第八步: 自瞄
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

-- 自瞄准星 (用 UI 而不是 Drawing, 因为移动端 Drawing 禁用了)
local aimCrosshair = Instance.new("Frame", screen)
aimCrosshair.Size = UDim2.new(0, 4, 0, 4)
aimCrosshair.Position = UDim2.new(0.5, -2, 0.5, -2)
aimCrosshair.BackgroundColor3 = Color3.fromRGB(255,0,0)
aimCrosshair.BorderSizePixel = 0
aimCrosshair.Visible = false
aimCrosshair.ZIndex = 30
Instance.new("UICorner", aimCrosshair).CornerRadius = UDim.new(1, 0)

RunSvc.RenderStepped:Connect(function()
    stats.frames = stats.frames + 1
    if tick() - stats.lastTick >= 1 then
        stats.fps = stats.frames; stats.frames = 0; stats.lastTick = tick()
    end
    if S.speedEnabled then pcall(refreshSpeed) end
    local cam = WS.CurrentCamera; if not cam then return end
    local center = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y/2)
    pcall(function()
        aimCrosshair.Position = UDim2.new(0.5, -2, 0.5, -2)
        aimCrosshair.BackgroundColor3 = aimColor()
        aimCrosshair.Visible = S.aimbot.enabled and S.aimbot.showFov
    end)
    if not (S.aimbot.enabled and S.aimbot.keyHeld) then return end
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
        cam.CFrame = cam.CFrame:Lerp(CFrame.new(cam.CFrame.Position, tgt.Position), S.aimbot.smoothness)
    end
end)

-- ============================================================
-- 第九步: 核心循环
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
        task.wait(0.5)
    end
end)

task.spawn(function()
    while screen.Parent do
        if S.rapidFire and Exec.hasGetGC then
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

-- 杀戮光环
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
                        playerEvent:FireServer("damage", {
                            bodyParts = {{"Head", 1}},
                            shotCode = { r.Position, (pr.Position - r.Position).Unit },
                            pos = pr.Position, target = tgt,
                            damageFactor = S.auraDamage, bulletProofTool = false,
                        })
                    end
                end
            end)
        end
        local w = S.auraStealth and (0.4 + math.random() * 0.2)
            or S.auraHumanize and (0.15 + math.random() * 0.1) or 0.1
        task.wait(w)
    end
end)

-- 自动铐
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
                                playerFunc:InvokeServer("handcuff", p, false)
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

-- 自动捡钱/农民
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
                if best and Exec.hasFirePP then pcall(fireproximityprompt, best, 0) end
            end)
        end
        task.wait(1.5)
    end
end)

-- 自动接任务
task.spawn(function()
    while screen.Parent do
        if S.autoMission and playerFunc and Exec.hasGetGC then
            pcall(function()
                if not LP:GetAttribute("Mission") then
                    for _, v in pairs(getgc(true)) do
                        if type(v) == "table" and rawget(v, "teamJobs") then
                            for k, j in pairs(v.teamJobs) do
                                if not j.joined then
                                    playerFunc:InvokeServer("talkToMission", tostring(k).."join")
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

-- 自动黑客
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

-- 隐身
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

-- 出租车
local Taxi = { thread=nil, origin=nil }
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
local function startTaxi()
    if Taxi.thread then return end
    local _, _, hrp0 = getChar()
    if hrp0 then Taxi.origin = hrp0.Position end
    Taxi.thread = task.spawn(function()
        while S.autoTaxi do
            pcall(function()
                local char, hum, hrp = getChar()
                local teamName = LP.Team and LP.Team.Name
                local isCiv = (teamName == "Civilian" or teamName == "Visitor" or teamName == nil)
                if char and hum and hrp and isCiv and hum.Health > 0 then
                    local targetPos = findTaxiTarget()
                    if targetPos then
                        local distance = (hrp.Position - targetPos).Magnitude
                        if distance > 10 then
                            if S.taxiSafe then
                                if not Taxi.origin then Taxi.origin = hrp.Position end
                                safeTeleport(Taxi.origin)
                                local wt = distance > 2000 and math.random(15, 45) or 15
                                local start = tick()
                                while S.autoTaxi and (tick() - start < wt) do
                                    task.wait(1)
                                    local _, h2 = getChar()
                                    if not h2 or h2.Health <= 0 then Taxi.origin = nil; return end
                                end
                            end
                            safeTeleport(targetPos)
                        end
                    end
                end
            end)
            task.wait(0.5)
        end
        Taxi.thread = nil
    end)
end
local function stopTaxi()
    S.autoTaxi = false; Taxi.origin = nil
    if Taxi.thread then pcall(function() task.cancel(Taxi.thread) end) end
    Taxi.thread = nil
end

-- 高尔夫
local Golf = { thread=nil }
local function startGolf()
    if Golf.thread then return end
    Golf.thread = task.spawn(function()
        while S.autoGolf do
            pcall(function()
                if playerFunc then
                    playerFunc:InvokeServer("miniGolf", "createLobby")
                    task.wait(0.1)
                    playerFunc:InvokeServer("miniGolf", "setLobbyBid", { bid = 500 })
                    task.wait(0.1)
                    playerFunc:InvokeServer("miniGolf", "setLobbyReady")
                    task.wait(4)
                    playerFunc:InvokeServer("miniGolf", "shot")
                end
            end)
            task.wait(5)
        end
        Golf.thread = nil
    end)
end
local function stopGolf()
    S.autoGolf = false
    if Golf.thread then pcall(function() task.cancel(Golf.thread) end) end
    Golf.thread = nil
end

-- 无限跳
local lastJump = 0
UIS.JumpRequest:Connect(function()
    if not S.jumpEnabled and not S.infiniteJump then return end
    if tick() - lastJump < 0.25 then return end
    lastJump = tick()
    local _, h, r = getChar(); if not h or not r or h.Health <= 0 then return end
    if not S.infiniteJump and not isOnGround(h) then return end
    r.CFrame = r.CFrame + Vector3.new(0, S.jumpPower * 0.05, 0)
end)

-- Ragdoll 补丁
pcall(function()
    local Ragdoll = require(RS.Modules.Ragdoll)
    local orig = Ragdoll.activate
    Ragdoll.activate = function(self, cond, x, y, ...)
        if S.noRagdoll and cond then return end
        return orig(self, cond, x, y, ...)
    end
end)

-- ============================================================
-- 第十步: ESP (BillboardGui 移动端稳定方案)
-- ============================================================
local espCache = {}
local function buildESP(p, char, hrp)
    local bill = Instance.new("BillboardGui")
    bill.Name = "XJ_ESP_"..p.Name
    bill.AlwaysOnTop = true
    bill.Size = UDim2.new(0, 120, 0, 34)
    bill.StudsOffset = Vector3.new(0, 3.2, 0)
    bill.MaxDistance = 400
    bill.Adornee = hrp
    bill.Parent = screen

    local l1 = Instance.new("TextLabel", bill)
    l1.Size = UDim2.new(1,0,0,14); l1.BackgroundTransparency = 1
    l1.Font = Enum.Font.GothamBold; l1.TextSize = 12
    l1.TextColor3 = Color3.new(1,1,1)
    l1.TextStrokeTransparency = 0; l1.TextStrokeColor3 = Color3.new(0,0,0)

    local l2 = Instance.new("TextLabel", bill)
    l2.Size = UDim2.new(1,0,0,12); l2.Position = UDim2.new(0,0,0,15)
    l2.BackgroundTransparency = 1; l2.Font = Enum.Font.GothamBold
    l2.TextSize = 10; l2.TextColor3 = Color3.fromRGB(230,230,230)
    l2.TextStrokeTransparency = 0; l2.TextStrokeColor3 = Color3.new(0,0,0)

    local hpBg = Instance.new("Frame", bill)
    hpBg.Size = UDim2.new(1,-14,0,2); hpBg.Position = UDim2.new(0,7,1,-2)
    hpBg.BackgroundColor3 = Color3.fromRGB(20,20,30); hpBg.BorderSizePixel = 0
    Instance.new("UICorner", hpBg).CornerRadius = UDim.new(1, 0)

    local hpFill = Instance.new("Frame", hpBg)
    hpFill.Size = UDim2.new(1,0,1,0); hpFill.BackgroundColor3 = Color3.fromRGB(60,220,100)
    hpFill.BorderSizePixel = 0
    Instance.new("UICorner", hpFill).CornerRadius = UDim.new(1, 0)

    local hl = Instance.new("Highlight", char)
    hl.Name = "XJ_HL"; hl.Adornee = char
    hl.FillTransparency = 0.85; hl.OutlineTransparency = 0
    pcall(function() hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop end)

    return { bill=bill, line1=l1, line2=l2, hpBg=hpBg, hpFill=hpFill, hl=hl }
end

local function destroyESP(e)
    pcall(function()
        if e.bill then e.bill:Destroy() end
        if e.hl then e.hl:Destroy() end
    end)
end

task.spawn(function()
    while screen.Parent do
        local t0 = tick()
        if S.esp.enabled then
            pcall(function()
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LP then
                        local c, h, r = getChar(p)
                        if c and h and r and h.Health > 0 then
                            if not espCache[p] then espCache[p] = buildESP(p, c, r) end
                            local e = espCache[p]
                            if e and e.bill then
                                e.bill.Adornee = r
                                local tc = S.esp.colorByTeam and teamColor(p) or Color3.fromRGB(168,85,247)
                                local n = p.Name
                                if S.esp.team then n = "["..teamLabel(p).."] "..n end
                                e.line1.Text = n; e.line1.TextColor3 = tc; e.line1.Visible = S.esp.name
                                local parts = {}
                                if S.esp.distance then
                                    local _, _, mr = getChar()
                                    if mr then parts[#parts+1] = math.floor((mr.Position - r.Position).Magnitude).."m" end
                                end
                                if S.esp.health then parts[#parts+1] = math.floor(h.Health).."/"..math.floor(h.MaxHealth) end
                                e.line2.Text = table.concat(parts, " · ")
                                e.line2.Visible = S.esp.distance or S.esp.health
                                if S.esp.bar then
                                    e.hpBg.Visible = true
                                    e.hpFill.Size = UDim2.new(math.clamp(h.Health/h.MaxHealth,0,1),0,1,0)
                                    local rt = h.Health/h.MaxHealth
                                    e.hpFill.BackgroundColor3 = rt>0.6 and Color3.fromRGB(60,220,100)
                                        or rt>0.3 and Color3.fromRGB(255,200,0)
                                        or Color3.fromRGB(255,60,60)
                                else e.hpBg.Visible = false end
                                if e.hl then
                                    if e.hl.Parent ~= c then e.hl.Parent = c end
                                    e.hl.Adornee = c
                                    e.hl.FillColor = tc; e.hl.OutlineColor = tc
                                    e.hl.Enabled = S.esp.highlight
                                end
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
        task.wait(Exec.isMobile and 0.3 or 0.15)
    end
end)

-- ============================================================
-- 第十一步: UI 构建 (移动端适配)
-- ============================================================
local W, H, uiScale
if Exec.isMobile then
    if vp.X >= 800 then  -- 平板
        W, H = 400, 300
        uiScale = math.clamp(math.min(vp.X/650, vp.Y/500), 0.7, 0.95)
    else  -- 手机
        W, H = 380, 280
        uiScale = math.clamp(math.min((vp.X-20)/420, (vp.Y-20)/320), 0.55, 0.9)
    end
else
    W, H = 460, 340
    uiScale = math.clamp(math.min((vp.X-40)/500, (vp.Y-80)/380), 0.75, 1)
end

local main = Instance.new("Frame", screen)
main.Size = UDim2.new(0, W, 0, H)
main.Position = UDim2.new(0.5, -W*uiScale/2, 0.5, -H*uiScale/2)
main.BackgroundColor3 = Color3.fromRGB(14,14,20)
main.BackgroundTransparency = 0.15
main.BorderSizePixel = 0
main.ClipsDescendants = true
main.Visible = false
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 14)
Instance.new("UIScale", main).Scale = uiScale

local mstr = Instance.new("UIStroke", main)
mstr.Color = Color3.fromRGB(168,85,247); mstr.Thickness = 1.5

local TOP_H = Exec.isMobile and 36 or 42
local topbar = Instance.new("Frame", main)
topbar.Size = UDim2.new(1, 0, 0, TOP_H)
topbar.BackgroundColor3 = Color3.fromRGB(22,22,32)
topbar.BackgroundTransparency = 0.2
topbar.BorderSizePixel = 0
Instance.new("UICorner", topbar).CornerRadius = UDim.new(0, 14)

local logo = Instance.new("Frame", topbar)
logo.Size = UDim2.new(0, 24, 0, 24); logo.Position = UDim2.new(0, 6, 0.5, -12)
logo.BackgroundColor3 = Color3.fromRGB(168,85,247)
logo.BorderSizePixel = 0
Instance.new("UICorner", logo).CornerRadius = UDim.new(0, 6)
local lTxt = Instance.new("TextLabel", logo)
lTxt.Size = UDim2.new(1,0,1,0); lTxt.BackgroundTransparency = 1
lTxt.Text = "嘉"; lTxt.TextColor3 = Color3.new(1,1,1)
lTxt.Font = Enum.Font.GothamBlack; lTxt.TextSize = 13

local title = Instance.new("TextLabel", topbar)
title.Size = UDim2.new(0, 200, 0, 14); title.Position = UDim2.new(0, 34, 0, 3)
title.BackgroundTransparency = 1; title.Text = "XJ HUB 1.6"
title.TextColor3 = Color3.new(1,1,1); title.Font = Enum.Font.GothamBold
title.TextSize = 12; title.TextXAlignment = Enum.TextXAlignment.Left

local sub = Instance.new("TextLabel", topbar)
sub.Size = UDim2.new(0, 220, 0, 10); sub.Position = UDim2.new(0, 34, 0, 19)
sub.BackgroundTransparency = 1
sub.Text = Exec.name.." · "..(Exec.hasHook and "Hook" or "无Hook")
sub.TextColor3 = Color3.fromRGB(120,230,150)
sub.Font = Enum.Font.Gotham; sub.TextSize = 8
sub.TextXAlignment = Enum.TextXAlignment.Left

local BTN = Exec.isMobile and 30 or 26
local minBtn = Instance.new("TextButton", topbar)
minBtn.Size = UDim2.new(0, BTN, 0, BTN)
minBtn.Position = UDim2.new(1, -(BTN*2+6), 0.5, -BTN/2)
minBtn.BackgroundColor3 = Color3.fromRGB(251,191,36); minBtn.Text = "－"
minBtn.TextColor3 = Color3.new(1,1,1); minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 15; minBtn.BorderSizePixel = 0
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 6)

local closeBtn = Instance.new("TextButton", topbar)
closeBtn.Size = UDim2.new(0, BTN, 0, BTN)
closeBtn.Position = UDim2.new(1, -(BTN+3), 0.5, -BTN/2)
closeBtn.BackgroundColor3 = Color3.fromRGB(239,68,68); closeBtn.Text = "×"
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
        local vp2 = WS.CurrentCamera and WS.CurrentCamera.ViewportSize or Vector2.new(1280,720)
        main.Position = UDim2.new(0,
            math.clamp(dPos.X.Offset + d.X, 100 - main.AbsoluteSize.X, vp2.X - 100),
            0,
            math.clamp(dPos.Y.Offset + d.Y, 0, vp2.Y - 40))
    end
end)
UIS.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        drag = false
    end
end)

-- 灵动岛
local iW, iH = Exec.isMobile and 140 or 160, Exec.isMobile and 34 or 38
local island = Instance.new("TextButton", screen)
island.Size = UDim2.new(0, iW, 0, iH)
island.Position = UDim2.new(0.5, -iW*uiScale/2, 0, 10)
island.BackgroundColor3 = Color3.fromRGB(10,10,16)
island.BackgroundTransparency = 0.05
island.Text = ""; island.BorderSizePixel = 0
island.AutoButtonColor = false; island.Visible = false; island.ZIndex = 50
Instance.new("UICorner", island).CornerRadius = UDim.new(1, 0)
Instance.new("UIScale", island).Scale = uiScale
local isStroke = Instance.new("UIStroke", island)
isStroke.Color = Color3.fromRGB(168,85,247); isStroke.Thickness = 1.4

local isAvatar = Instance.new("ImageLabel", island)
isAvatar.Size = UDim2.new(0, 24, 0, 24); isAvatar.Position = UDim2.new(0, 5, 0.5, -12)
isAvatar.BackgroundColor3 = Color3.fromRGB(40,40,55); isAvatar.BorderSizePixel = 0
isAvatar.Image = userInfo.thumb
Instance.new("UICorner", isAvatar).CornerRadius = UDim.new(1, 0)

local isTitle = Instance.new("TextLabel", island)
isTitle.Size = UDim2.new(1, -80, 0, 12); isTitle.Position = UDim2.new(0, 34, 0, 3)
isTitle.BackgroundTransparency = 1; isTitle.Text = "XJ Hub v1.6"
isTitle.TextColor3 = Color3.new(1,1,1); isTitle.Font = Enum.Font.GothamBold
isTitle.TextSize = 10; isTitle.TextXAlignment = Enum.TextXAlignment.Left

local isInfo = Instance.new("TextLabel", island)
isInfo.Size = UDim2.new(1, -80, 0, 10); isInfo.Position = UDim2.new(0, 34, 0, 18)
isInfo.BackgroundTransparency = 1; isInfo.Text = "FPS 0 · Ping 0"
isInfo.TextColor3 = Color3.fromRGB(160,160,180); isInfo.Font = Enum.Font.Gotham
isInfo.TextSize = 9; isInfo.TextXAlignment = Enum.TextXAlignment.Left

task.spawn(function()
    while screen.Parent do
        pcall(function()
            isInfo.Text = string.format("FPS %d · Ping %d", stats.fps, stats.ping)
        end)
        task.wait(0.8)
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
        if math.abs(d.X) > 8 or math.abs(d.Y) > 8 then iMoved = true end
        island.Position = UDim2.new(iPos.X.Scale, iPos.X.Offset + d.X, iPos.Y.Scale, iPos.Y.Offset + d.Y)
    end
end)

local minimized = false
local function minimize()
    if minimized then return end
    minimized = true
    main.Visible = false
    island.Visible = true
    island.Size = UDim2.new(0, iW, 0, iH)
end
local function restore()
    if not minimized then return end
    minimized = false
    island.Visible = false
    main.Visible = true
    main.Size = UDim2.new(0, W, 0, H)
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
local sidebarW = Exec.isMobile and 68 or 90
local sidebar = Instance.new("Frame", main)
sidebar.Size = UDim2.new(0, sidebarW, 1, -(TOP_H+10))
sidebar.Position = UDim2.new(0, 5, 0, TOP_H+6)
sidebar.BackgroundColor3 = Color3.fromRGB(20,20,28)
sidebar.BackgroundTransparency = 0.2; sidebar.BorderSizePixel = 0
Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0, 8)

local innerNav = Instance.new("ScrollingFrame", sidebar)
innerNav.Size = UDim2.new(1, 0, 1, 0)
innerNav.BackgroundTransparency = 1; innerNav.BorderSizePixel = 0
innerNav.ScrollBarThickness = 0
innerNav.CanvasSize = UDim2.new(0,0,0,0)
innerNav.AutomaticCanvasSize = Enum.AutomaticSize.Y
local nl = Instance.new("UIListLayout", innerNav); nl.Padding = UDim.new(0, 2)
local np = Instance.new("UIPadding", innerNav)
np.PaddingTop = UDim.new(0, 3); np.PaddingBottom = UDim.new(0, 3)
np.PaddingLeft = UDim.new(0, 3); np.PaddingRight = UDim.new(0, 3)

local content = Instance.new("Frame", main)
content.Size = UDim2.new(1, -(sidebarW+12), 1, -(TOP_H+10))
content.Position = UDim2.new(0, sidebarW+7, 0, TOP_H+6)
content.BackgroundColor3 = Color3.fromRGB(18,18,26)
content.BackgroundTransparency = 0.2; content.BorderSizePixel = 0
Instance.new("UICorner", content).CornerRadius = UDim.new(0, 8)

local pages, tabButtons = {}, {}
local currentTab
local function createPage(name)
    local page = Instance.new("ScrollingFrame", content)
    page.Size = UDim2.new(1, -8, 1, -8)
    page.Position = UDim2.new(0, 4, 0, 4)
    page.BackgroundTransparency = 1; page.BorderSizePixel = 0
    page.ScrollBarThickness = 2
    page.ScrollBarImageColor3 = Color3.fromRGB(168,85,247)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.CanvasSize = UDim2.new(0,0,0,0)
    page.Visible = false
    local ll = Instance.new("UIListLayout", page); ll.Padding = UDim.new(0, 4)
    pages[name] = page
end

local tabCount = 0
local TAB_H = Exec.isMobile and 30 or 28
local function createTab(name, icon)
    tabCount = tabCount + 1
    local btn = Instance.new("TextButton", innerNav)
    btn.Size = UDim2.new(1, 0, 0, TAB_H)
    btn.BackgroundColor3 = Color3.fromRGB(168,85,247)
    btn.BackgroundTransparency = 1
    btn.Text = ""; btn.BorderSizePixel = 0
    btn.LayoutOrder = tabCount; btn.AutoButtonColor = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)

    local ico = Instance.new("TextLabel", btn)
    ico.Size = UDim2.new(0, 14, 1, 0); ico.Position = UDim2.new(0, 2, 0, 0)
    ico.BackgroundTransparency = 1; ico.Text = icon or ""
    ico.TextColor3 = Color3.fromRGB(190,190,210)
    ico.Font = Enum.Font.GothamBold; ico.TextSize = 10

    local lbl = Instance.new("TextLabel", btn)
    lbl.Size = UDim2.new(1, -18, 1, 0); lbl.Position = UDim2.new(0, 18, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = Exec.isMobile and name:sub(1,2) or name
    lbl.TextColor3 = Color3.fromRGB(190,190,210)
    lbl.Font = Enum.Font.GothamMedium; lbl.TextSize = Exec.isMobile and 9 or 11
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
            t.btn.BackgroundTransparency = n == name and 0.7 or 1
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

local TG_H = Exec.isMobile and 36 or 32
local function createToggle(parent, name, def, cb, risk)
    risk = risk or "safe"
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(1, 0, 0, TG_H)
    btn.BackgroundColor3 = riskBg(risk)
    btn.BackgroundTransparency = 0.1
    btn.Text = ""; btn.BorderSizePixel = 0; btn.AutoButtonColor = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    local lbl = Instance.new("TextLabel", btn)
    lbl.Size = UDim2.new(1, -56, 1, 0); lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = riskPrefix(risk)..name
    lbl.TextColor3 = riskTextColor(risk)
    lbl.Font = Enum.Font.GothamMedium; lbl.TextSize = Exec.isMobile and 11 or 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local indW = Exec.isMobile and 40 or 36
    local indH = Exec.isMobile and 20 or 18
    local ind = Instance.new("Frame", btn)
    ind.Size = UDim2.new(0, indW, 0, indH)
    ind.Position = UDim2.new(1, -(indW+8), 0.5, -indH/2)
    ind.BackgroundColor3 = Color3.fromRGB(50,50,65); ind.BorderSizePixel = 0
    Instance.new("UICorner", ind).CornerRadius = UDim.new(1, 0)

    local knobW = Exec.isMobile and 16 or 14
    local knob = Instance.new("Frame", ind)
    knob.Size = UDim2.new(0, knobW, 0, knobW)
    knob.Position = UDim2.new(0, 2, 0.5, -knobW/2)
    knob.BackgroundColor3 = Color3.new(1,1,1); knob.BorderSizePixel = 0
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local state = def or false
    local function refresh()
        Tween:Create(knob, TweenInfo.new(0.12), {
            Position = state and UDim2.new(1, -(knobW+2), 0.5, -knobW/2) or UDim2.new(0, 2, 0.5, -knobW/2)
        }):Play()
        Tween:Create(ind, TweenInfo.new(0.12), {
            BackgroundColor3 = state and Color3.fromRGB(190,80,255) or Color3.fromRGB(50,50,65)
        }):Play()
    end
    refresh()
    btn.MouseButton1Click:Connect(function()
        state = not state; refresh()
        if cb then pcall(cb, state) end
        if state then notify(name, "已开启", "success", 1.5)
        else notify(name, "已关闭", "warn", 1.5) end
    end)
end

local function createSlider(parent, name, min, max, def, cb, risk)
    risk = risk or "safe"
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, 0, 0, Exec.isMobile and 50 or 46)
    frame.BackgroundColor3 = riskBg(risk)
    frame.BackgroundTransparency = 0.1; frame.BorderSizePixel = 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)

    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(1, -56, 0, 14); lbl.Position = UDim2.new(0, 10, 0, 4)
    lbl.BackgroundTransparency = 1; lbl.Text = riskPrefix(risk)..name
    lbl.TextColor3 = riskTextColor(risk)
    lbl.Font = Enum.Font.GothamMedium; lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local vLbl = Instance.new("TextLabel", frame)
    vLbl.Size = UDim2.new(0, 46, 0, 14); vLbl.Position = UDim2.new(1, -56, 0, 4)
    vLbl.BackgroundTransparency = 1; vLbl.Text = tostring(def)
    vLbl.TextColor3 = Color3.fromRGB(190,130,255)
    vLbl.Font = Enum.Font.GothamBold; vLbl.TextSize = 12
    vLbl.TextXAlignment = Enum.TextXAlignment.Right

    local trackH = Exec.isMobile and 10 or 6
    local track = Instance.new("TextButton", frame)
    track.Size = UDim2.new(1, -20, 0, trackH)
    track.Position = UDim2.new(0, 10, 0, Exec.isMobile and 32 or 28)
    track.BackgroundColor3 = Color3.fromRGB(50,50,65)
    track.Text = ""; track.BorderSizePixel = 0; track.AutoButtonColor = false
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame", track)
    fill.Size = UDim2.new((def-min)/(max-min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(168,85,247); fill.BorderSizePixel = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local dotW = Exec.isMobile and 18 or 12
    local dot = Instance.new("Frame", track)
    dot.Size = UDim2.new(0, dotW, 0, dotW)
    dot.Position = UDim2.new((def-min)/(max-min), -dotW/2, 0.5, -dotW/2)
    dot.BackgroundColor3 = Color3.new(1,1,1); dot.BorderSizePixel = 0
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

    local dg = false
    local function update(x)
        local pos = math.clamp((x - track.AbsolutePosition.X) / math.max(1, track.AbsoluteSize.X), 0, 1)
        local v = math.floor(min + pos * (max - min) + 0.5)
        fill.Size = UDim2.new(pos, 0, 1, 0)
        dot.Position = UDim2.new(pos, -dotW/2, 0.5, -dotW/2)
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
    btn.Size = UDim2.new(1, 0, 0, Exec.isMobile and 36 or 32)
    btn.BackgroundColor3 = riskBg(risk)
    btn.BackgroundTransparency = 0.1
    btn.Text = ""; btn.BorderSizePixel = 0; btn.AutoButtonColor = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    local lbl = Instance.new("TextLabel", btn)
    lbl.Size = UDim2.new(1, -100, 1, 0); lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1; lbl.Text = riskPrefix(risk)..name
    lbl.TextColor3 = riskTextColor(risk)
    lbl.Font = Enum.Font.GothamMedium; lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local vBox = Instance.new("TextButton", btn)
    vBox.Size = UDim2.new(0, 80, 0, 22)
    vBox.Position = UDim2.new(1, -88, 0.5, -11)
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

-- 创建所有页面
createPage("主页"); createPage("玩家"); createPage("战斗"); createPage("自瞄")
createPage("透视"); createPage("刷钱"); createPage("飞车"); createPage("杂项"); createPage("自检")

createTab("主页", "🏠"); createTab("玩家", "👤"); createTab("战斗", "⚔️")
createTab("自瞄", "🎯"); createTab("透视", "👁️"); createTab("刷钱", "💰")
createTab("飞车", "🚗"); createTab("杂项", "⚡"); createTab("自检", "🧪")

pages["主页"].Visible = true; currentTab = "主页"
tabButtons["主页"].lbl.TextColor3 = Color3.new(1,1,1)
tabButtons["主页"].ico.TextColor3 = Color3.new(1,1,1)
tabButtons["主页"].btn.BackgroundTransparency = 0.7

-- 主页
local userCard = Instance.new("Frame", pages["主页"])
userCard.Size = UDim2.new(1, 0, 0, 66)
userCard.BackgroundColor3 = Color3.fromRGB(28,28,40)
userCard.BackgroundTransparency = 0.1; userCard.BorderSizePixel = 0
Instance.new("UICorner", userCard).CornerRadius = UDim.new(0, 7)

local avatar = Instance.new("ImageLabel", userCard)
avatar.Size = UDim2.new(0, 50, 0, 50); avatar.Position = UDim2.new(0, 8, 0.5, -25)
avatar.BackgroundColor3 = Color3.fromRGB(40,40,55); avatar.BorderSizePixel = 0
avatar.Image = userInfo.thumb
Instance.new("UICorner", avatar).CornerRadius = UDim.new(0, 25)
Instance.new("UIStroke", avatar).Color = Color3.fromRGB(168,85,247)

local nameLbl = Instance.new("TextLabel", userCard)
nameLbl.Size = UDim2.new(1, -68, 0, 14); nameLbl.Position = UDim2.new(0, 64, 0, 6)
nameLbl.BackgroundTransparency = 1; nameLbl.Text = userInfo.name
nameLbl.TextColor3 = Color3.new(1,1,1); nameLbl.Font = Enum.Font.GothamBold
nameLbl.TextSize = 12; nameLbl.TextXAlignment = Enum.TextXAlignment.Left

local infoLbl = Instance.new("TextLabel", userCard)
infoLbl.Size = UDim2.new(1, -68, 0, 12); infoLbl.Position = UDim2.new(0, 64, 0, 22)
infoLbl.BackgroundTransparency = 1
infoLbl.Text = "@"..userInfo.displayName.." · "..userInfo.membership
infoLbl.TextColor3 = Color3.fromRGB(180,180,200); infoLbl.Font = Enum.Font.Gotham
infoLbl.TextSize = 10; infoLbl.TextXAlignment = Enum.TextXAlignment.Left

local devLbl = Instance.new("TextLabel", userCard)
devLbl.Size = UDim2.new(1, -68, 0, 12); devLbl.Position = UDim2.new(0, 64, 0, 36)
devLbl.BackgroundTransparency = 1
devLbl.Text = Exec.name.." · "..math.floor(vp.X).."x"..math.floor(vp.Y)
devLbl.TextColor3 = Color3.fromRGB(190,130,255); devLbl.Font = Enum.Font.Gotham
devLbl.TextSize = 10; devLbl.TextXAlignment = Enum.TextXAlignment.Left

-- 数据卡
local statsCard = Instance.new("Frame", pages["主页"])
statsCard.Size = UDim2.new(1, 0, 0, 55)
statsCard.BackgroundColor3 = Color3.fromRGB(28,28,40)
statsCard.BackgroundTransparency = 0.1; statsCard.BorderSizePixel = 0
Instance.new("UICorner", statsCard).CornerRadius = UDim.new(0, 7)

local statsTitle = Instance.new("TextLabel", statsCard)
statsTitle.Size = UDim2.new(1, -20, 0, 14); statsTitle.Position = UDim2.new(0, 10, 0, 4)
statsTitle.BackgroundTransparency = 1; statsTitle.Text = "📊 实时数据"
statsTitle.TextColor3 = Color3.fromRGB(150,200,255); statsTitle.Font = Enum.Font.GothamBold
statsTitle.TextSize = 10; statsTitle.TextXAlignment = Enum.TextXAlignment.Left

local statsRow = Instance.new("Frame", statsCard)
statsRow.Size = UDim2.new(1, -20, 0, 30); statsRow.Position = UDim2.new(0, 10, 0, 20)
statsRow.BackgroundTransparency = 1
local srl = Instance.new("UIListLayout", statsRow)
srl.FillDirection = Enum.FillDirection.Horizontal; srl.Padding = UDim.new(0, 5)

local function makeCell(parent, label, color)
    local cell = Instance.new("Frame", parent)
    cell.Size = UDim2.new(1/3, -4, 1, 0)
    cell.BackgroundColor3 = Color3.fromRGB(22,22,32); cell.BorderSizePixel = 0
    Instance.new("UICorner", cell).CornerRadius = UDim.new(0, 5)
    local t = Instance.new("TextLabel", cell)
    t.Size = UDim2.new(1, 0, 0, 10); t.Position = UDim2.new(0, 0, 0, 1)
    t.BackgroundTransparency = 1; t.Text = label
    t.TextColor3 = Color3.fromRGB(150,150,180)
    t.Font = Enum.Font.Gotham; t.TextSize = 8
    local v = Instance.new("TextLabel", cell)
    v.Size = UDim2.new(1, 0, 0, 16); v.Position = UDim2.new(0, 0, 0, 11)
    v.BackgroundTransparency = 1; v.Text = "0"
    v.TextColor3 = color; v.Font = Enum.Font.GothamBold; v.TextSize = 11
    return v
end
local fpsValue = makeCell(statsRow, "FPS", Color3.fromRGB(80,220,100))
local pingValue = makeCell(statsRow, "PING", Color3.fromRGB(255,200,100))
local espValueCell = makeCell(statsRow, "ESP", Color3.fromRGB(180,130,255))

task.spawn(function()
    while screen.Parent do
        pcall(function()
            fpsValue.Text = tostring(stats.fps)
            pingValue.Text = stats.ping.."ms"
            pingValue.TextColor3 = stats.ping>200 and Color3.fromRGB(255,80,60)
                or stats.ping>100 and Color3.fromRGB(255,200,100)
                or Color3.fromRGB(80,220,100)
            espValueCell.Text = string.format("%.1fms", stats.espAvg*1000)
        end)
        task.wait(0.7)
    end
end)

-- 功能开关
createToggle(pages["玩家"], "无限体力", false, function(v) S.stamina=v end, "mid")
createToggle(pages["玩家"], "无限饥饿", false, function(v) S.food=v end, "mid")
createToggle(pages["玩家"], "无限子弹", false, function(v) S.infiniteAmmo=v end, "mid")
createToggle(pages["玩家"], "快速射击", false, function(v) S.rapidFire=v end, "mid")
createToggle(pages["玩家"], "修改行走速度", false, function(v)
    S.speedEnabled=v
    if not v and speedBV then pcall(function() speedBV:Destroy() end); speedBV=nil end
end, "risk")
createSlider(pages["玩家"], "行走速度", 16, 500, 100, function(v) S.speedValue=v end, "risk")
createToggle(pages["玩家"], "跳跃修改", false, function(v) S.jumpEnabled=v end, "risk")
createSlider(pages["玩家"], "跳跃高度", 10, 200, 50, function(v) S.jumpPower=v end, "risk")
createToggle(pages["玩家"], "无限跳跃", false, function(v) S.infiniteJump=v end, "risk")

createToggle(pages["战斗"], "杀戮光环", false, function(v) S.auraEnabled=v end, "mid")
createSlider(pages["战斗"], "光环范围", 50, 800, 200, function(v) S.auraRange=v end, "mid")
createSlider(pages["战斗"], "光环伤害", 1, 100, 5, function(v) S.auraDamage=v end, "mid")
createToggle(pages["战斗"], "拟人化延迟", true, function(v) S.auraHumanize=v end, "safe")
createToggle(pages["战斗"], "隐蔽模式", true, function(v) S.auraStealth=v end, "safe")
createToggle(pages["战斗"], "自动铐", false, function(v) S.autoCuff=v end, "mid")

createToggle(pages["自瞄"], "开启自瞄", false, function(v) S.aimbot.enabled=v end, "safe")
createToggle(pages["自瞄"], "显示准星", true, function(v) S.aimbot.showFov=v end, "safe")
createToggle(pages["自瞄"], "好友检测", false, function(v) S.aimbot.friendCheck=v end, "safe")
createToggle(pages["自瞄"], "墙壁检测", false, function(v) S.aimbot.wallCheck=v end, "safe")
createToggle(pages["自瞄"], "队伍检测", false, function(v) S.aimbot.teamCheck=v end, "safe")
createToggle(pages["自瞄"], "船员检测", false, function(v) S.aimbot.crewCheck=v end, "safe")
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

createToggle(pages["刷钱"], "自动捡钱", false, function(v) S.autoMoney=v end, "safe")
createToggle(pages["刷钱"], "自动农民", false, function(v) S.autoFarmer=v end, "safe")
createToggle(pages["刷钱"], "自动接任务", false, function(v) S.autoMission=v end, "mid")
createToggle(pages["刷钱"], "自动黑客", false, function(v) S.autoHack=v end, "mid")
createToggle(pages["刷钱"], "自动出租车", false, function(v)
    if v then S.autoTaxi=true; startTaxi() else stopTaxi() end
end, "mid")
createToggle(pages["刷钱"], "出租车安全模式", false, function(v) S.taxiSafe=v end, "safe")
createToggle(pages["刷钱"], "自动高尔夫", false, function(v)
    if v then S.autoGolf=true; startGolf() else stopGolf() end
end, "mid")

createToggle(pages["飞车"], "飞行模式", false, function(v)
    S.flyEnabled=v; if v then startFly() else stopFly() end
end, "risk")
createToggle(pages["飞车"], "穿墙 Noclip", false, function(v)
    S.noclip=v; if v then startNoclip() else stopNoclip() end
end, "risk")
createSlider(pages["飞车"], "飞行速度", 10, 300, 50, function(v) S.flySpeed=v end, "risk")

createToggle(pages["杂项"], "隐身", false, function(v) S.ghost=v end, "safe")
createToggle(pages["杂项"], "防布娃娃", false, function(v) S.noRagdoll=v end, "safe")

-- 自检页
local selfCard = Instance.new("Frame", pages["自检"])
selfCard.Size = UDim2.new(1, 0, 0, 240)
selfCard.BackgroundColor3 = Color3.fromRGB(20,20,30)
selfCard.BackgroundTransparency = 0.1; selfCard.BorderSizePixel = 0
Instance.new("UICorner", selfCard).CornerRadius = UDim.new(0, 7)

local selfTitle = Instance.new("TextLabel", selfCard)
selfTitle.Size = UDim2.new(1, -20, 0, 16); selfTitle.Position = UDim2.new(0, 10, 0, 6)
selfTitle.BackgroundTransparency = 1; selfTitle.Text = "🧪 自检 · "..Exec.name
selfTitle.TextColor3 = Color3.fromRGB(150,200,255); selfTitle.Font = Enum.Font.GothamBold
selfTitle.TextSize = 11; selfTitle.TextXAlignment = Enum.TextXAlignment.Left

local selfOut = Instance.new("TextLabel", selfCard)
selfOut.Size = UDim2.new(1, -20, 1, -44); selfOut.Position = UDim2.new(0, 10, 0, 24)
selfOut.BackgroundTransparency = 1
selfOut.Text = "点击下方按钮开始自检"
selfOut.TextColor3 = Color3.fromRGB(220,220,235)
selfOut.Font = Enum.Font.Code; selfOut.TextSize = 10
selfOut.TextXAlignment = Enum.TextXAlignment.Left
selfOut.TextYAlignment = Enum.TextYAlignment.Top
selfOut.TextWrapped = true

local runTestBtn = Instance.new("TextButton", selfCard)
runTestBtn.Size = UDim2.new(1, -20, 0, Exec.isMobile and 32 or 26)
runTestBtn.Position = UDim2.new(0, 10, 1, -38)
runTestBtn.BackgroundColor3 = Color3.fromRGB(168,85,247)
runTestBtn.Text = "▶ 运行自检"
runTestBtn.TextColor3 = Color3.new(1,1,1)
runTestBtn.Font = Enum.Font.GothamBold; runTestBtn.TextSize = 11
runTestBtn.BorderSizePixel = 0
Instance.new("UICorner", runTestBtn).CornerRadius = UDim.new(0, 6)

local function runTests()
    local lines = {}; local pass, fail = 0, 0
    local function T(name, fn)
        local okk, res = pcall(fn)
        if okk and res then lines[#lines+1] = "✅ "..name; pass = pass + 1
        else lines[#lines+1] = "❌ "..name; fail = fail + 1 end
    end
    T("执行器: "..Exec.name, function() return Exec.name ~= "未知" end)
    T("Hook 能力", function() return Exec.hasHook end)
    T("Drawing 能力", function() return Exec.hasDrawing end)
    T("getgc", function() return Exec.hasGetGC end)
    T("gethui", function() return Exec.hasHui end)
    T("fireproximityprompt", function() return Exec.hasFirePP end)
    T("Remote 已获取", function() return remote ~= nil end)
    T("PlayerEvent", function() return playerEvent ~= nil end)
    T("PlayerFunc", function() return playerFunc ~= nil end)
    T("本地角色", function() local c,h = getChar(); return c~=nil and h~=nil end)
    T("通知系统", function() notify("自检","测试","success",1); return true end)
    T("物理飞行", function()
        S.flyEnabled=true; startFly(); task.wait(0.1)
        local okv = Fly.align~=nil
        S.flyEnabled=false; stopFly()
        return okv
    end)
    T("玩家数量", function() return #Players:GetPlayers() >= 1 end)

    lines[#lines+1] = ""
    lines[#lines+1] = string.format("结果: %d / %d", pass, pass+fail)
    lines[#lines+1] = "设备: "..(Exec.isIOS and "iOS" or Exec.isAndroid and "Android" or "桌面")
    lines[#lines+1] = "Hook: "..tostring(Exec.hasHook).." | Drawing: "..tostring(Exec.hasDrawing)
    selfOut.Text = table.concat(lines, "\n")
    notify("自检完成", string.format("%d 通过 / %d 失败", pass, fail), fail==0 and "success" or "warn", 2)
end
runTestBtn.MouseButton1Click:Connect(runTests)

-- 右键自瞄 (桌面) + 触控
UIS.InputBegan:Connect(function(i, g)
    if g then return end
    if i.UserInputType == Enum.UserInputType.MouseButton2 then S.aimbot.keyHeld = true end
end)
UIS.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton2 then S.aimbot.keyHeld = false end
end)

-- 移动端瞄准按钮
if Exec.isMobile then
    local aimBtn = Instance.new("TextButton", screen)
    aimBtn.Size = UDim2.new(0, 70, 0, 70)
    aimBtn.Position = UDim2.new(1, -85, 0.5, -35)
    aimBtn.BackgroundColor3 = Color3.fromRGB(168,85,247)
    aimBtn.BackgroundTransparency = 0.6
    aimBtn.Text = "瞄准"
    aimBtn.TextColor3 = Color3.new(1,1,1)
    aimBtn.Font = Enum.Font.GothamBold; aimBtn.TextSize = 13
    aimBtn.BorderSizePixel = 0
    aimBtn.ZIndex = 40
    aimBtn.Visible = false  -- 默认隐藏, 用户开启自瞄后显示
    Instance.new("UICorner", aimBtn).CornerRadius = UDim.new(1, 0)

    -- 当自瞄开启时显示按钮
    task.spawn(function()
        while screen.Parent do
            pcall(function() aimBtn.Visible = S.aimbot.enabled end)
            task.wait(0.5)
        end
    end)

    aimBtn.MouseButton1Down:Connect(function() S.aimbot.keyHeld = true end)
    aimBtn.MouseButton1Up:Connect(function() S.aimbot.keyHeld = false end)
    aimBtn.TouchLongPress:Connect(function() S.aimbot.keyHeld = true end)
    aimBtn.TouchEnded:Connect(function() S.aimbot.keyHeld = false end)
end

-- ============================================================
-- 加载动画 (简化)
-- ============================================================
local loading = Instance.new("Frame", screen)
loading.Size = UDim2.new(1, 0, 1, 0)
loading.BackgroundColor3 = Color3.fromRGB(0,0,0)
loading.BackgroundTransparency = 0.4
loading.BorderSizePixel = 0; loading.ZIndex = 100

local lCard = Instance.new("Frame", loading)
lCard.Size = UDim2.new(0, 220, 0, 110)
lCard.Position = UDim2.new(0.5, -110*uiScale, 0.5, -55*uiScale)
lCard.BackgroundColor3 = Color3.fromRGB(18,18,26)
lCard.BackgroundTransparency = 0.05; lCard.BorderSizePixel = 0; lCard.ZIndex = 101
Instance.new("UICorner", lCard).CornerRadius = UDim.new(0, 12)
Instance.new("UIScale", lCard).Scale = uiScale
Instance.new("UIStroke", lCard).Color = Color3.fromRGB(168,85,247)

local lLogo = Instance.new("Frame", lCard)
lLogo.Size = UDim2.new(0, 40, 0, 40); lLogo.Position = UDim2.new(0.5, -20, 0, 10)
lLogo.BackgroundColor3 = Color3.fromRGB(168,85,247)
lLogo.BorderSizePixel = 0; lLogo.ZIndex = 102
Instance.new("UICorner", lLogo).CornerRadius = UDim.new(0, 10)
local lLT = Instance.new("TextLabel", lLogo)
lLT.Size = UDim2.new(1,0,1,0); lLT.BackgroundTransparency = 1
lLT.Text = "嘉"; lLT.TextColor3 = Color3.new(1,1,1)
lLT.Font = Enum.Font.GothamBlack; lLT.TextSize = 20; lLT.ZIndex = 103

local lTitle = Instance.new("TextLabel", lCard)
lTitle.Size = UDim2.new(1, 0, 0, 14); lTitle.Position = UDim2.new(0, 0, 0, 56)
lTitle.BackgroundTransparency = 1; lTitle.Text = "XJ HUB 1.6"
lTitle.TextColor3 = Color3.new(1,1,1); lTitle.Font = Enum.Font.GothamBold
lTitle.TextSize = 12; lTitle.ZIndex = 102

local lBarBg = Instance.new("Frame", lCard)
lBarBg.Size = UDim2.new(1, -30, 0, 4); lBarBg.Position = UDim2.new(0, 15, 0, 76)
lBarBg.BackgroundColor3 = Color3.fromRGB(40,40,55); lBarBg.BorderSizePixel = 0; lBarBg.ZIndex = 102
Instance.new("UICorner", lBarBg).CornerRadius = UDim.new(1, 0)

local lBarFill = Instance.new("Frame", lBarBg)
lBarFill.Size = UDim2.new(0, 0, 1, 0)
lBarFill.BackgroundColor3 = Color3.fromRGB(168,85,247)
lBarFill.BorderSizePixel = 0; lBarFill.ZIndex = 103
Instance.new("UICorner", lBarFill).CornerRadius = UDim.new(1, 0)

local lStatus = Instance.new("TextLabel", lCard)
lStatus.Size = UDim2.new(1, -30, 0, 12); lStatus.Position = UDim2.new(0, 15, 0, 88)
lStatus.BackgroundTransparency = 1; lStatus.Text = "初始化..."
lStatus.TextColor3 = Color3.fromRGB(200,200,220)
lStatus.Font = Enum.Font.GothamMedium; lStatus.TextSize = 9
lStatus.TextXAlignment = Enum.TextXAlignment.Left; lStatus.ZIndex = 102

task.spawn(function()
    pcall(function()
        lStatus.Text = "适配 "..Exec.name.."..."
        Tween:Create(lBarFill, TweenInfo.new(0.4, Enum.EasingStyle.Quint), { Size = UDim2.new(0.5,0,1,0) }):Play()
        task.wait(0.4)
        lStatus.Text = "加载模块..."
        Tween:Create(lBarFill, TweenInfo.new(0.4, Enum.EasingStyle.Quint), { Size = UDim2.new(1,0,1,0) }):Play()
        task.wait(0.4)
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
    end)
    task.wait(0.5)
    notify("XJ Hub", "v1.6 加载完成", "success", 2.5)
    pcall(runTests)
end)

log("v1.6 启动完成")
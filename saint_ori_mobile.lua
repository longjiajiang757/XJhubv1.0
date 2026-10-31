--[[
    ╔══════════════════════════════════════════════════════════════════════╗
    ║             S A I N T   O R I   M O B I L E   H U B                  ║
    ║        罗布乐思手机端多功能脚本 · v3.0 · 防护绕过版                   ║
    ║  角色 · 战斗 · 经济 · 执法 · 自动化 · 防护 · 设置                     ║
    ╚══════════════════════════════════════════════════════════════════════╝

    本版针对移动端(Delta / Fluxus / Arceus X / Codex / Vega X / Hydrogen)优化：
      · 触屏友好 UI：横向页签、大号开关、可拖动悬浮球
      · 降低绘制压力：大部分逻辑走 Heartbeat 分帧调度，只把瞄准留在 RenderStepped
      · 执行器能力自适应：缺失的 API 自动降级，不报错
      · 防护模块：安全限速 / 分步位移 / 远程节流抖动 / 客户端反作弊中和

    热键：无键盘设备点左上角悬浮球开合面板
]]

--//═══════════════════════════ 服务 ═══════════════════════════//--
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")
local StarterGui        = game:GetService("StarterGui")
local StarterPlayer     = game:GetService("StarterPlayer")
local ReplicatedFirst   = game:GetService("ReplicatedFirst")
local Teams             = game:GetService("Teams")
local VirtualUser       = game:GetService("VirtualUser")

local LP = Players.LocalPlayer
local unpack = table.unpack

--//═══════════════════════════ 兼容层 ═══════════════════════════//--
local Compat = {
	isTouch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled,
	firetouchinterest = (typeof(firetouchinterest) == "function") and firetouchinterest or nil,
	fireproximityprompt = (typeof(fireproximityprompt) == "function") and fireproximityprompt or nil,
	mouse1click = (typeof(mouse1click) == "function") and mouse1click or nil,
	gethui = (typeof(gethui) == "function") and gethui or nil,
	protectGui = (typeof(protect_gui) == "function") and protect_gui or nil,
	getgenvTable = (typeof(getgenv) == "function") and getgenv or nil,
	queueOnTeleport = (typeof(queue_on_teleport) == "function") and queue_on_teleport or nil,
}

--//═══════════════════════════ 调色板 ═══════════════════════════//--
local PALETTE = {
	bg      = Color3.fromRGB(11, 11, 17),
	sidebar = Color3.fromRGB(15, 15, 23),
	card    = Color3.fromRGB(23, 23, 34),
	cardHi  = Color3.fromRGB(32, 32, 47),
	stroke  = Color3.fromRGB(47, 47, 67),
	text    = Color3.fromRGB(233, 233, 245),
	sub     = Color3.fromRGB(124, 124, 152),
	accent  = Color3.fromRGB(168, 85, 247),
	accent2 = Color3.fromRGB(236, 72, 153),
	green   = Color3.fromRGB(74, 222, 128),
	red     = Color3.fromRGB(251, 113, 133),
	yellow  = Color3.fromRGB(250, 204, 21),
	white   = Color3.fromRGB(255, 255, 255),
}

--//═══════════════════════════ 配置 ═══════════════════════════//--
local DEFAULT_CONFIG = {
	-- 角色
	Fly           = false,
	FlySpeed      = 55,
	Noclip        = false,
	Speed         = false,
	SpeedValue    = 45,
	InfiniteJump  = false,
	AngryRobot    = false,
	RobotScale    = 1,
	-- 战斗
	Aimbot        = false,
	AimbotFOV     = 420,
	AimbotSmooth  = 0.35,
	AimPart       = "Head",
	TeamCheck     = true,
	AutoFire      = false,
	FireRate      = 0.1,
	BulletTrack   = false,
	BulletSpeed   = 900,
	Prediction    = 1,
	Range         = false,
	RangeValue    = 40,
	-- 经济
	AutoFarm      = false,
	FarmDelay     = 0.3,
	AutoClaim     = false,
	ClaimDelay    = 2,
	-- 执法
	AutoArrest    = false,
	ArrestRange   = 16,
	-- 自动化
	AutoHack      = false,
	HackDelay     = 0.5,
	AutoInteract  = false,
	-- 性能
	LiteMode      = false,
	-- 防护（与 Guard 表同步）
	GuardEnabled     = true,
	GuardMaxSpeed    = 32,
	GuardSplit       = true,
	GuardStep        = 7,
	GuardStepDelay   = 0.07,
	GuardSafeFly     = true,
	GuardFlyMax      = 45,
	GuardSmoothFly   = true,
	GuardThrottle    = true,
	GuardCooldown    = 0.12,
	GuardJitter      = 0.12,
}

local Config = {}
for key, value in pairs(DEFAULT_CONFIG) do
	Config[key] = value
end

-- 防护参数
local Guard = {
	Enabled          = Config.GuardEnabled,
	MaxWalkSpeed     = Config.GuardMaxSpeed,
	SplitTeleport    = Config.GuardSplit,
	TeleportStep     = Config.GuardStep,
	TeleportDelay    = Config.GuardStepDelay,
	ThrottleRemotes  = Config.GuardThrottle,
	RemoteCooldown   = Config.GuardCooldown,
	RemoteJitter     = Config.GuardJitter,
	SafeFly          = Config.GuardSafeFly,
	FlyMaxSpeed      = Config.GuardFlyMax,
	SmoothFly        = Config.GuardSmoothFly,
	KillClientGuard  = false,
}

--//═══════════════════════════ 工具函数 ═══════════════════════════//--
local function getCamera()
	return Workspace.CurrentCamera
end

local function getCharacter()
	return LP.Character
end

local function getHRP()
	local char = LP.Character
	if not char then return nil end
	return char:FindFirstChild("HumanoidRootPart")
		or char:FindFirstChild("Torso")
		or char:FindFirstChild("UpperTorso")
end

local function getHum()
	local char = LP.Character
	if not char then return nil end
	return char:FindFirstChildOfClass("Humanoid")
end

local function notify(text)
	pcall(function()
		StarterGui:SetCore("SendNotification", {
			Title = "SAINT ORI M",
			Text = tostring(text),
			Duration = 3,
		})
	end)
end

local function fmt(number)
	if type(number) ~= "number" then return tostring(number) end
	if number % 1 == 0 then return tostring(number) end
	local text = string.format("%.2f", number)
	text = string.gsub(text, "%.?0+$", "")
	return text
end

--//═════════════════════ Remote 缓存与安全队列 ══════════════════════//--
local RemoteCache = { list = {}, stamp = -999 }
local RemoteStamps = {}

local function refreshRemotes(force)
	if not force and (os.clock() - RemoteCache.stamp) < 6 then
		return RemoteCache.list
	end
	local list = {}

	local function scan(root)
		local ok, descendants = pcall(function() return root:GetDescendants() end)
		if not ok then return end
		for _, obj in ipairs(descendants) do
			if obj:IsA("RemoteEvent")
				or obj:IsA("RemoteFunction")
				or obj:IsA("UnreliableRemoteEvent") then
				list[#list + 1] = obj
			end
		end
	end

	scan(ReplicatedStorage)
	scan(Workspace)

	RemoteCache.list = list
	RemoteCache.stamp = os.clock()
	return list
end

local function matchRemotes(...)
	local keywords = { ... }
	local result = {}
	for _, remote in ipairs(refreshRemotes(false)) do
		local name = string.lower(remote.Name)
		for _, keyword in ipairs(keywords) do
			if string.find(name, string.lower(keyword), 1, true) then
				result[#result + 1] = remote
				break
			end
		end
	end
	return result
end

-- 带节流、抖动、存活检查的安全调用
local function fireSafe(remote, ...)
	if not remote or not remote.Parent then return false end

	if Guard.Enabled and Guard.ThrottleRemotes then
		local now = os.clock()
		local last = RemoteStamps[remote]
		if last and (now - last) < Guard.RemoteCooldown then
			return false
		end
		RemoteStamps[remote] = now
	end

	local args = { ... }

	local function execute()
		if not remote.Parent then return end
		pcall(function()
			if remote:IsA("RemoteFunction") then
				remote:InvokeServer(unpack(args))
			else
				remote:FireServer(unpack(args))
			end
		end)
	end

	local delay = 0
	if Guard.Enabled and Guard.RemoteJitter > 0 then
		delay = Guard.RemoteJitter * math.random()
	end

	if delay > 0.005 then
		task.delay(delay, execute)
	else
		execute()
	end
	return true
end

local function fireAll(list, ...)
	local sent = 0
	for _, remote in ipairs(list) do
		if fireSafe(remote, ...) then
			sent = sent + 1
		end
	end
	return sent
end

--//═══════════════════════════ 防护模块 ═══════════════════════════//--
local GuardLog = { lastMoveSpeed = 0, blockedSpeed = 0, blockedRemotes = 0 }

-- 分步位移：把一次大跨度移动拆成多个小步，避免单帧位移超阈值
local function safeTeleport(targetCFrame)
	local hrp = getHRP()
	if not hrp then return end

	if not (Guard.Enabled and Guard.SplitTeleport) then
		hrp.CFrame = targetCFrame
		return
	end

	local start = hrp.Position
	local target = targetCFrame.Position
	local distance = (target - start).Magnitude

	if distance < 2 then
		hrp.CFrame = targetCFrame
		return
	end

	local steps = math.clamp(math.ceil(distance / Guard.TeleportStep), 1, 60)

	task.spawn(function()
		for index = 1, steps do
			local current = getHRP()
			if not current then return end
			local alpha = index / steps
			local point = start:Lerp(target, alpha)
			local lift = math.sin(alpha * math.pi) * 0.8
			pcall(function()
				current.CFrame = CFrame.new(point + Vector3.new(0, lift, 0))
			end)
			task.wait(Guard.TeleportDelay * (0.75 + math.random() * 0.5))
		end
		local final = getHRP()
		if final then
			pcall(function() final.CFrame = targetCFrame end)
		end
	end)
end

-- 安全行走速度：超过阈值时压回上限
local defaultWalkSpeed = 16
local speedApplied = false

local function captureDefaultSpeed()
	local hum = getHum()
	if hum and hum.WalkSpeed > 0 and hum.WalkSpeed < 100 then
		defaultWalkSpeed = hum.WalkSpeed
	end
end

local function applySafeWalkSpeed()
	local hum = getHum()
	if not hum then return end

	if not Config.Speed then
		if speedApplied then
			hum.WalkSpeed = defaultWalkSpeed
			speedApplied = false
		end
		return
	end

	local target = Config.SpeedValue

	if Guard.Enabled then
		local limit = Guard.MaxWalkSpeed
		if target > limit then
			GuardLog.blockedSpeed = GuardLog.blockedSpeed + 1
			target = limit
		end
	end

	if hum.WalkSpeed ~= target then
		hum.WalkSpeed = target
	end
	speedApplied = true
	GuardLog.lastMoveSpeed = target
end

-- 客户端反作弊脚本中和（只禁用，不破坏游戏主体）
local ANTI_CHEAT_HINTS = {
	"anticheat", "anti_cheat", "anti-cheat", "anti cheat",
	"cheatguard", "cheat_guard", "cheatdetect",
	"watchdog", "sentinel", "detector",
	"hackdetect", "hack_detect", "exploit", "security",
}

local function neutralizeGuards()
	local killed = {}

	local function scan(root)
		local ok, descendants = pcall(function() return root:GetDescendants() end)
		if not ok then return end
		for _, obj in ipairs(descendants) do
			if obj:IsA("LocalScript") and obj ~= script then
				local name = string.lower(obj.Name)
				for _, hint in ipairs(ANTI_CHEAT_HINTS) do
					if string.find(name, hint, 1, true) then
						local ok2 = pcall(function() obj.Disabled = true end)
						if ok2 then
							killed[#killed + 1] = obj:GetFullName()
						end
						break
					end
				end
			end
		end
	end

	scan(StarterPlayer)
	scan(ReplicatedFirst)
	scan(Workspace)
	scan(ReplicatedStorage)

	return killed
end

-- 清理可能被扫描到的全局痕迹
local function cleanTraces()
	local removed = 0
	pcall(function()
		local env = Compat.getgenvTable and Compat.getgenvTable() or _G
		for key in pairs(env) do
			if type(key) == "string" then
				local lower = string.lower(key)
				if string.find(lower, "saint", 1, true)
					or string.find(lower, "ori_hub", 1, true) then
					pcall(function() env[key] = nil end)
					removed = removed + 1
				end
			end
		end
	end)
	return removed
end

-- 防护自检报告
local function guardReport()
	local lines = {}
	lines[#lines + 1] = "防护: " .. (Guard.Enabled and "开启" or "关闭")
	lines[#lines + 1] = "限速: " .. tostring(Guard.MaxWalkSpeed)
	lines[#lines + 1] = "分步位移: " .. (Guard.SplitTeleport and ("每步 " .. Guard.TeleportStep .. " 格") or "关闭")
	lines[#lines + 1] = "远程节流: " .. (Guard.ThrottleRemotes and ("冷却 " .. Guard.RemoteCooldown .. "s") or "关闭")
	lines[#lines + 1] = "拦截超速: " .. tostring(GuardLog.blockedSpeed)
	lines[#lines + 1] = "执行器: " .. (Compat.isTouch and "移动端" or "桌面端")
	lines[#lines + 1] = "移触 API: " .. (Compat.firetouchinterest and "可用" or "缺失")
	lines[#lines + 1] = "提示 API: " .. (Compat.fireproximityprompt and "可用" or "缺失")
	return table.concat(lines, "  |  ")
end

--//═══════════════════════════ 角色功能 ═══════════════════════════//--
local flyState = { bv = nil, bg = nil, velocity = Vector3.zero }
local flyInput = { forward = false, back = false, left = false, right = false, up = false, down = false }
local noclipBackup = {}

local function destroyFly()
	if flyState.bv then
		pcall(function() flyState.bv:Destroy() end)
		flyState.bv = nil
	end
	if flyState.bg then
		pcall(function() flyState.bg:Destroy() end)
		flyState.bg = nil
	end
	flyState.velocity = Vector3.zero
	local hum = getHum()
	if hum then
		hum.PlatformStand = false
	end
end

local function ensureFly()
	local hrp = getHRP()
	local hum = getHum()
	if not hrp or not hum then return false end

	if flyState.bv and flyState.bv.Parent == hrp then
		return true
	end

	destroyFly()

	flyState.bv = Instance.new("BodyVelocity")
	flyState.bv.Name = "SaintFlyVelocity"
	flyState.bv.MaxForce = Vector3.new(8e4, 8e4, 8e4)
	flyState.bv.Velocity = Vector3.zero
	flyState.bv.Parent = hrp

	flyState.bg = Instance.new("BodyGyro")
	flyState.bg.Name = "SaintFlyGyro"
	flyState.bg.MaxTorque = Vector3.new(8e4, 8e4, 8e4)
	flyState.bg.P = 1000
	flyState.bg.D = 70
	flyState.bg.Parent = hrp

	hum.PlatformStand = true
	return true
end

local function flyStep()
	if not ensureFly() then return end
	local cam = getCamera()
	if not cam then return end

	local move = Vector3.zero

	if UserInputService:IsKeyDown(Enum.KeyCode.W) or flyInput.forward then
		move = move + cam.CFrame.LookVector
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.S) or flyInput.back then
		move = move - cam.CFrame.LookVector
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.A) or flyInput.left then
		move = move - cam.CFrame.RightVector
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.D) or flyInput.right then
		move = move + cam.CFrame.RightVector
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.Space) or flyInput.up then
		move = move + Vector3.new(0, 1, 0)
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or flyInput.down then
		move = move - Vector3.new(0, 1, 0)
	end

	if move.Magnitude > 0 then
		move = move.Unit
	end

	local speed = Config.FlySpeed
	if Guard.Enabled and Guard.SafeFly then
		speed = math.min(speed, Guard.FlyMaxSpeed)
	end

	local desired = move * speed
	if Guard.Enabled and Guard.SmoothFly then
		flyState.velocity = flyState.velocity:Lerp(desired, 0.35)
	else
		flyState.velocity = desired
	end

	if flyState.bv then
		flyState.bv.Velocity = flyState.velocity
	end
	if flyState.bg and flyState.bg.Parent then
		local origin = flyState.bg.Parent.Position
		flyState.bg.CFrame = CFrame.lookAt(origin, origin + cam.CFrame.LookVector)
	end
end

local function noclipStep()
	local char = getCharacter()
	if not char then return end
	for _, part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") and part.CanCollide then
			noclipBackup[part] = true
			part.CanCollide = false
		end
	end
end

local function restoreNoclip()
	for part in pairs(noclipBackup) do
		if part and part.Parent then
			part.CanCollide = true
		end
	end
	noclipBackup = {}
end

--//══════════════════════ 愤怒机器人（本地） ══════════════════════//--
local robotState = { model = nil, conn = nil }

local function destroyRobot()
	if robotState.conn then
		pcall(function() robotState.conn:Disconnect() end)
		robotState.conn = nil
	end
	if robotState.model then
		pcall(function() robotState.model:Destroy() end)
		robotState.model = nil
	end
end

local function spawnAngryRobot()
	destroyRobot()

	local hrp = getHRP()
	if not hrp then return false end

	local model = Instance.new("Model")
	model.Name = "SaintAngryRobot"

	local bones = {}
	local function makePart(name, size, color, material)
		local part = Instance.new("Part")
		part.Name = name
		part.Size = size * Config.RobotScale
		part.Color = color
		part.Material = material or Enum.Material.Metal
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CastShadow = false
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Smooth
		part.Parent = model
		bones[#bones + 1] = part
		return part
	end

	local body = makePart("Body", Vector3.new(2.6, 3, 1.8), Color3.fromRGB(52, 12, 78))
	local head = makePart("Head", Vector3.new(1.8, 1.8, 1.8), Color3.fromRGB(36, 8, 56))
	local eyeL = makePart("EyeL", Vector3.new(0.42, 0.2, 0.12), Color3.fromRGB(255, 55, 55), Enum.Material.Neon)
	local eyeR = makePart("EyeR", Vector3.new(0.42, 0.2, 0.12), Color3.fromRGB(255, 55, 55), Enum.Material.Neon)
	makePart("ArmL", Vector3.new(0.7, 2.4, 0.7), Color3.fromRGB(46, 10, 70))
	makePart("ArmR", Vector3.new(0.7, 2.4, 0.7), Color3.fromRGB(46, 10, 70))
	local core = makePart("Core", Vector3.new(0.9, 0.9, 0.25), Color3.fromRGB(236, 72, 153), Enum.Material.Neon)

	body.CFrame = hrp.CFrame * CFrame.new(0, 1, -3)
	head.CFrame = body.CFrame * CFrame.new(0, 2.4, 0)
	eyeL.CFrame = head.CFrame * CFrame.new(-0.42, 0.25, -0.9)
	eyeR.CFrame = head.CFrame * CFrame.new(0.42, 0.25, -0.9)
	core.CFrame = body.CFrame * CFrame.new(0, 0.2, -0.95)

	model.PrimaryPart = body
	model.Parent = Workspace
	robotState.model = model

	local glow = Instance.new("PointLight")
	glow.Color = Color3.fromRGB(180, 60, 255)
	glow.Range = 12
	glow.Brightness = 1.6
	glow.Parent = core

	local clock = 0
	local interval = Config.LiteMode and 0.08 or 0.02
	local accumulator = 0

	robotState.conn = RunService.Heartbeat:Connect(function(dt)
		if Config.LiteMode then
			accumulator = accumulator + dt
			if accumulator < interval then return end
			accumulator = 0
		end

		clock = clock + dt
		local me = getHRP()
		if not me or not model.Parent then return end

		local hover = math.sin(clock * 3) * 0.25
		local base = me.CFrame * CFrame.new(0, 1 + hover, -3.4)
		model:PivotTo(base)

		local nearest, nearestDistance = nil, 100
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= LP and plr.Character then
				local humanoid = plr.Character:FindFirstChildOfClass("Humanoid")
				local root = plr.Character:FindFirstChild("HumanoidRootPart")
				if humanoid and humanoid.Health > 0 and root then
					local distance = (root.Position - me.Position).Magnitude
					if distance < nearestDistance then
						nearest, nearestDistance = root, distance
					end
				end
			end
		end

		if nearest then
			local look = base.Position + (nearest.Position - base.Position).Unit * 10
			model:PivotTo(CFrame.lookAt(base.Position, look))
			local flicker = 0.6 + math.abs(math.sin(clock * 12)) * 0.4
			eyeL.Color = Color3.fromRGB(255, 40 * flicker, 40 * flicker)
			eyeR.Color = Color3.fromRGB(255, 40 * flicker, 40 * flicker)
		end
	end)

	return true
end

local function triggerRobotSpawn()
	refreshRemotes(true)
	local remotes = matchRemotes("robot", "bot", "mech", "angry", "summon", "pet")
	local sent = fireAll(remotes) + fireAll(remotes, "AngryRobot")
	return sent
end

--//═══════════════════════════ 战斗功能 ═══════════════════════════//--
local function isValidEnemy(plr)
	if plr == LP then return false end
	local char = plr.Character
	if not char then return false end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return false end
	if Config.TeamCheck and LP.Team and plr.Team and LP.Team == plr.Team then
		return false
	end
	return true
end

local function getPartOf(plr)
	local char = plr.Character
	if not char then return nil end
	local part = char:FindFirstChild(Config.AimPart)
	if part and part:IsA("BasePart") then
		return part
	end
	return char:FindFirstChild("HumanoidRootPart")
		or char:FindFirstChild("UpperTorso")
		or char:FindFirstChild("Torso")
end

local function findClosestTarget()
	local cam = getCamera()
	if not cam then return nil end
	local center = Vector2.new(cam.ViewportSize.X * 0.5, cam.ViewportSize.Y * 0.5)
	local bestPart, bestDistance = nil, Config.AimbotFOV

	for _, plr in ipairs(Players:GetPlayers()) do
		if isValidEnemy(plr) then
			local part = getPartOf(plr)
			if part then
				local screen, onScreen = cam:WorldToViewportPoint(part.Position)
				if onScreen then
					local distance = (Vector2.new(screen.X, screen.Y) - center).Magnitude
					if distance < bestDistance then
						bestPart, bestDistance = part, distance
					end
				end
			end
		end
	end

	return bestPart
end

local function aimStep()
	if not Config.Aimbot and not Config.BulletTrack then return end
	local cam = getCamera()
	if not cam then return end

	local target = findClosestTarget()
	if not target then return end

	local aimAt = target.Position
	if Config.BulletTrack then
		local velocity = target.AssemblyLinearVelocity
		local distance = (aimAt - cam.CFrame.Position).Magnitude
		local travel = (distance / math.max(Config.BulletSpeed, 1)) * Config.Prediction
		aimAt = aimAt + velocity * travel
	end

	if (aimAt - cam.CFrame.Position).Magnitude < 0.1 then return end

	local goal = CFrame.lookAt(cam.CFrame.Position, aimAt)
	local smooth = math.clamp(Config.AimbotSmooth, 0.02, 1)
	cam.CFrame = cam.CFrame:Lerp(goal, smooth)
end

local function doAttack()
	local char = getCharacter()
	if not char then return false end

	local tool = char:FindFirstChildOfClass("Tool")
	if tool then
		return pcall(function() tool:Activate() end)
	end

	if Compat.mouse1click then
		return pcall(Compat.mouse1click)
	end

	local cam = getCamera()
	local ok = pcall(function()
		VirtualUser:ClickButton1(Vector2.new(cam.ViewportSize.X * 0.5, cam.ViewportSize.Y * 0.5))
	end)
	return ok
end

local fireAccumulator = 0
local function autoFireStep(dt)
	if not Config.AutoFire then return end
	fireAccumulator = fireAccumulator + dt
	if fireAccumulator < Config.FireRate then return end
	fireAccumulator = 0
	if not findClosestTarget() then return end
	doAttack()
end

local function touchPart(part)
	local hrp = getHRP()
	if not hrp or not part then return end
	if Compat.firetouchinterest then
		pcall(Compat.firetouchinterest, hrp, part, 0)
		pcall(Compat.firetouchinterest, hrp, part, 1)
	end
end

local function attackRemotes()
	return matchRemotes(
		"damage", "hit", "attack", "punch", "slash", "shoot",
		"fire", "kill", "hurt", "combat", "swing", "melee", "weapon"
	)
end

local rangeAccumulator = 0
local function rangeStep(dt)
	if not Config.Range then return end
	rangeAccumulator = rangeAccumulator + dt
	if rangeAccumulator < 0.25 then return end
	rangeAccumulator = 0

	local hrp = getHRP()
	if not hrp then return end

	local remotes = attackRemotes()
	for _, plr in ipairs(Players:GetPlayers()) do
		if isValidEnemy(plr) then
			local part = getPartOf(plr)
			if part and (part.Position - hrp.Position).Magnitude <= Config.RangeValue then
				fireAll(remotes, plr.Character, plr, part)
				touchPart(part)
			end
		end
	end
end

--//═══════════════════════════ 经济功能 ═══════════════════════════//--
local MONEY_KEYWORDS = {
	"coin", "cash", "money", "gem", "diamond", "gold",
	"drop", "loot", "pickup", "reward", "bank", "wallet", "bounty", "price",
}

local function looksLikeMoney(name)
	local lower = string.lower(name)
	for _, keyword in ipairs(MONEY_KEYWORDS) do
		if string.find(lower, keyword, 1, true) then
			return true
		end
	end
	return false
end

local farmCache = { stamp = -999, list = {} }

local function farmTargets()
	if os.clock() - farmCache.stamp < 2 then
		return farmCache.list
	end
	local list = {}
	local ok, descendants = pcall(function() return Workspace:GetDescendants() end)
	if ok then
		for _, obj in ipairs(descendants) do
			if obj:IsA("BasePart") and looksLikeMoney(obj.Name) then
				list[#list + 1] = obj
			end
		end
	end
	farmCache.list = list
	farmCache.stamp = os.clock()
	return list
end

local farmAccumulator = 0
local function farmStep(dt)
	if not Config.AutoFarm then return end
	farmAccumulator = farmAccumulator + dt
	if farmAccumulator < Config.FarmDelay then return end
	farmAccumulator = 0

	local hrp = getHRP()
	if not hrp then return end

	local bestPart, bestDistance = nil, 400
	for _, part in ipairs(farmTargets()) do
		if part.Parent then
			local distance = (part.Position - hrp.Position).Magnitude
			if distance < bestDistance then
				bestPart, bestDistance = part, distance
			end
		end
	end

	if bestPart then
		safeTeleport(CFrame.new(bestPart.Position + Vector3.new(0, 4, 0)))
		touchPart(bestPart)
	end
end

local claimAccumulator = 0
local function claimStep(dt)
	if not Config.AutoClaim then return end
	claimAccumulator = claimAccumulator + dt
	if claimAccumulator < Config.ClaimDelay then return end
	claimAccumulator = 0

	local remotes = matchRemotes(
		"claim", "reward", "daily", "bonus", "collect", "spin", "free", "gift", "code"
	)
	fireAll(remotes)
end

local function tryMoneyRemotes()
	refreshRemotes(true)
	local remotes = matchRemotes(
		"cash", "money", "coin", "reward", "bank", "wallet",
		"balance", "grant", "give", "add", "withdraw", "deposit"
	)
	if #remotes == 0 then
		return false, "没有找到金额类远程"
	end

	local amount = 100000
	local sent = 0
	for _, remote in ipairs(remotes) do
		if fireSafe(remote, amount) then sent = sent + 1 end
		if fireSafe(remote, LP, amount) then sent = sent + 1 end
		if fireSafe(remote, "Cash", amount) then sent = sent + 1 end
	end
	return true, ("已向 %d 个远程投递金额参数"):format(sent)
end

--//═══════════════════════════ 执法功能 ═══════════════════════════//--
local function arrestRemotes()
	return matchRemotes(
		"arrest", "cuff", "handcuff", "jail", "detain",
		"taser", "baton", "wanted", "bounty", "suspect", "cop"
	)
end

local arrestAccumulator = 0
local function arrestStep(dt)
	if not Config.AutoArrest then return end
	arrestAccumulator = arrestAccumulator + dt
	if arrestAccumulator < 0.35 then return end
	arrestAccumulator = 0

	local hrp = getHRP()
	if not hrp then return end

	local remotes = arrestRemotes()
	if #remotes == 0 then return end

	for _, plr in ipairs(Players:GetPlayers()) do
		if isValidEnemy(plr) then
			local part = getPartOf(plr)
			if part and (part.Position - hrp.Position).Magnitude <= Config.ArrestRange then
				fireAll(remotes, plr.Character, plr)
				fireAll(remotes, plr)
				touchPart(part)
			end
		end
	end
end

local function joinPoliceTeam()
	refreshRemotes(true)

	local targetTeam = nil
	for _, team in ipairs(Teams:GetChildren()) do
		local lower = string.lower(team.Name)
		if string.find(lower, "police", 1, true)
			or string.find(lower, "cop", 1, true)
			or string.find(lower, "sheriff", 1, true)
			or string.find(lower, "law", 1, true)
			or string.find(team.Name, "警", 1, true) then
			targetTeam = team
			break
		end
	end

	local remotes = matchRemotes("team", "join", "police", "cop", "job", "role", "change", "select")
	local sent = 0
	for _, remote in ipairs(remotes) do
		if targetTeam then
			if fireSafe(remote, targetTeam) then sent = sent + 1 end
			if fireSafe(remote, targetTeam.Name) then sent = sent + 1 end
		end
		if fireSafe(remote, "Police") then sent = sent + 1 end
	end

	if targetTeam then
		pcall(function() LP.Team = targetTeam end)
		return true, ("尝试加入「%s」，触发 %d 次"):format(targetTeam.Name, sent)
	end
	return false, "没有找到警察队伍或相关远程"
end

local function clearWanted()
	local remotes = matchRemotes("wanted", "bounty", "clear", "bail", "release", "report", "escape")
	local sent = fireAll(remotes, true)
	sent = sent + fireAll(remotes)
	return sent
end

--//═══════════════════════════ 自动化功能 ═══════════════════════════//--
local function autoInteractOnce(rangeLimit)
	local hrp = getHRP()
	if not hrp then return 0 end

	local count = 0
	local ok, descendants = pcall(function() return Workspace:GetDescendants() end)
	if not ok then return 0 end

	for _, obj in ipairs(descendants) do
		if obj:IsA("ProximityPrompt") and obj.Enabled then
			local parent = obj.Parent
			if parent and parent:IsA("BasePart") and (parent.Position - hrp.Position).Magnitude <= (rangeLimit or 15) then
				local fired = false
				if Compat.fireproximityprompt then
					fired = pcall(Compat.fireproximityprompt, obj)
				else
					fired = pcall(function()
						obj:InputHoldBegin()
						task.wait(0.1)
						obj:InputHoldEnd()
					end)
				end
				if fired then
					count = count + 1
				end
			end
		end
	end
	return count
end

local hackAccumulator = 0
local function hackStep(dt)
	if not Config.AutoHack then return end
	hackAccumulator = hackAccumulator + dt
	if hackAccumulator < Config.HackDelay then return end
	hackAccumulator = 0

	autoInteractOnce(20)

	local remotes = matchRemotes(
		"hack", "terminal", "console", "panel", "decrypt", "bypass",
		"upload", "download", "secur", "keypad", "code", "password",
		"unlock", "open", "access"
	)
	fireAll(remotes)
end

local interactAccumulator = 0
local function interactStep(dt)
	if not Config.AutoInteract then return end
	interactAccumulator = interactAccumulator + dt
	if interactAccumulator < 0.6 then return end
	interactAccumulator = 0
	autoInteractOnce(15)
end

--//═══════════════════════════ UI 构建 ═══════════════════════════//--
local function getGuiParent()
	local ok, result = pcall(function()
		if Compat.gethui then return Compat.gethui() end
		return game:GetService("CoreGui")
	end)
	if ok and result then return result end
	return LP:WaitForChild("PlayerGui")
end

local function create(className, props)
	local inst = Instance.new(className)
	for key, value in pairs(props or {}) do
		if key ~= "Parent" then
			pcall(function() inst[key] = value end)
		end
	end
	if props and props.Parent then
		inst.Parent = props.Parent
	end
	return inst
end

local GUI_NAME = "SaintOriMobile"
pcall(function()
	local existing = getGuiParent():FindFirstChild(GUI_NAME)
	if existing then
		existing:Destroy()
	end
end)

local gui = create("ScreenGui", {
	Name = GUI_NAME,
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	DisplayOrder = 999999,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})

if syn and syn.protect_gui then
	pcall(function() syn.protect_gui(gui) end)
elseif Compat.protectGui then
	pcall(Compat.protectGui, gui)
end
gui.Parent = getGuiParent()

-- 自动缩放：适配手机小屏和桌面大屏
local function computeScale()
	local cam = getCamera()
	if not cam then return 1 end
	local vp = cam.ViewportSize
	local factor = math.min(vp.X / 980, vp.Y / 560)
	return math.clamp(factor, 0.62, 1.18)
end

local window = create("Frame", {
	Name = "Window",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(760, 500),
	BackgroundColor3 = PALETTE.bg,
	BorderSizePixel = 0,
	ClipsDescendants = true,
	Parent = gui,
})
create("UICorner", { CornerRadius = UDim.new(0, 14), Parent = window })
create("UIStroke", { Color = PALETTE.stroke, Thickness = 1, Parent = window })

local uiScale = create("UIScale", { Scale = computeScale(), Parent = window })

local function refreshScale()
	uiScale.Scale = computeScale()
end

-- 顶部渐变条
local ribbon = create("Frame", {
	Size = UDim2.new(1, 0, 0, 3),
	BackgroundColor3 = PALETTE.white,
	BorderSizePixel = 0,
	ZIndex = 5,
	Parent = window,
})
create("UIGradient", {
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, PALETTE.accent2),
		ColorSequenceKeypoint.new(0.5, PALETTE.accent),
		ColorSequenceKeypoint.new(1, PALETTE.accent2),
	}),
	Parent = ribbon,
})

-- 标题栏（可拖动）
local topbar = create("Frame", {
	Position = UDim2.fromOffset(0, 3),
	Size = UDim2.new(1, 0, 0, 50),
	BackgroundColor3 = PALETTE.sidebar,
	BorderSizePixel = 0,
	Parent = window,
})

create("TextLabel", {
	Text = "SAINT ORI · MOBILE",
	Font = Enum.Font.GothamBold,
	TextSize = 16,
	TextColor3 = PALETTE.text,
	TextXAlignment = Enum.TextXAlignment.Left,
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(16, 9),
	Size = UDim2.fromOffset(260, 20),
	Parent = topbar,
})

create("TextLabel", {
	Text = "触屏优化 · 防护绕过 v3.0",
	Font = Enum.Font.Gotham,
	TextSize = 10,
	TextColor3 = PALETTE.sub,
	TextXAlignment = Enum.TextXAlignment.Left,
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(16, 29),
	Size = UDim2.fromOffset(260, 14),
	Parent = topbar,
})

local badge = create("Frame", {
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -56, 0.5, 0),
	Size = UDim2.fromOffset(92, 24),
	BackgroundColor3 = PALETTE.card,
	BorderSizePixel = 0,
	Parent = topbar,
})
create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = badge })
create("UIStroke", { Color = PALETTE.stroke, Thickness = 1, Transparency = 0.4, Parent = badge })

local badgeDot = create("Frame", {
	Position = UDim2.fromOffset(10, 9),
	Size = UDim2.fromOffset(6, 6),
	BackgroundColor3 = PALETTE.green,
	BorderSizePixel = 0,
	Parent = badge,
})
create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = badgeDot })

local badgeLabel = create("TextLabel", {
	Text = Guard.Enabled and "防护开启" or "防护关闭",
	Font = Enum.Font.GothamMedium,
	TextSize = 10,
	TextColor3 = Guard.Enabled and PALETTE.green or PALETTE.red,
	TextXAlignment = Enum.TextXAlignment.Left,
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(22, 0),
	Size = UDim2.new(1, -24, 1, 0),
	Parent = badge,
})

local hideBtn = create("TextButton", {
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -13, 0.5, 0),
	Size = UDim2.fromOffset(32, 32),
	BackgroundColor3 = PALETTE.card,
	Text = "",
	AutoButtonColor = false,
	BorderSizePixel = 0,
	Parent = topbar,
})
create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = hideBtn })

local hideLabel = create("TextLabel", {
	Text = "×",
	Font = Enum.Font.GothamBold,
	TextSize = 18,
	TextColor3 = PALETTE.sub,
	BackgroundTransparency = 1,
	Size = UDim2.fromScale(1, 1),
	Parent = hideBtn,
})
hideBtn.MouseEnter:Connect(function() hideLabel.TextColor3 = PALETTE.red end)
hideBtn.MouseLeave:Connect(function() hideLabel.TextColor3 = PALETTE.sub end)
hideBtn.MouseButton1Click:Connect(function() window.Visible = false end)

-- 横向页签栏
local tabScroll = create("ScrollingFrame", {
	Position = UDim2.fromOffset(0, 53),
	Size = UDim2.new(1, 0, 0, 48),
	BackgroundColor3 = PALETTE.sidebar,
	BorderSizePixel = 0,
	ScrollBarThickness = 0,
	CanvasSize = UDim2.new(0, 0, 0, 0),
	AutomaticCanvasSize = Enum.AutomaticSize.X,
	ScrollingDirection = Enum.ScrollingDirection.X,
	Parent = window,
})

local tabList = create("Frame", {
	Size = UDim2.new(0, 0, 1, 0),
	AutomaticSize = Enum.AutomaticSize.X,
	BackgroundTransparency = 1,
	Parent = tabScroll,
})
create("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	Padding = UDim.new(0, 6),
	VerticalAlignment = Enum.VerticalAlignment.Center,
	SortOrder = Enum.SortOrder.LayoutOrder,
	Parent = tabList,
})
create("UIPadding", {
	PaddingLeft = UDim.new(0, 12),
	PaddingRight = UDim.new(0, 12),
	Parent = tabList,
})

-- 内容区
local contentArea = create("Frame", {
	Position = UDim2.fromOffset(0, 101),
	Size = UDim2.new(1, 0, 1, -101),
	BackgroundTransparency = 1,
	ClipsDescendants = true,
	Parent = window,
})

local TAB_DEFS = {
	{ id = "character",  label = "角色",   glyph = "◆" },
	{ id = "combat",     label = "战斗",   glyph = "✦" },
	{ id = "economy",    label = "经济",   glyph = "◇" },
	{ id = "police",     label = "执法",   glyph = "⬟" },
	{ id = "automation", label = "自动化", glyph = "⟳" },
	{ id = "guard",      label = "防护",   glyph = "❖" },
	{ id = "settings",   label = "设置",   glyph = "⚙" },
}

local pages = {}
local tabButtons = {}
local activeTab = nil
local ORDER = 0

local function pushOrder()
	ORDER = ORDER + 1
	return ORDER
end

local function createPage(id)
	local page = create("ScrollingFrame", {
		Name = id,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = PALETTE.accent,
		ScrollBarImageTransparency = 0.3,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Visible = false,
		Parent = contentArea,
	})

	create("UIPadding", {
		PaddingLeft = UDim.new(0, 14),
		PaddingRight = UDim.new(0, 14),
		PaddingTop = UDim.new(0, 12),
		PaddingBottom = UDim.new(0, 16),
		Parent = page,
	})

	local list = create("Frame", {
		Size = UDim2.new(1, -30, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = page,
	})
	create("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = list,
	})

	pages[id] = page
	return list
end

local function selectTab(id)
	if activeTab == id then return end
	activeTab = id

	for tabId, data in pairs(tabButtons) do
		data.setActive(tabId == id)
	end

	for pageId, page in pairs(pages) do
		page.Visible = pageId == id
	end
end

--//═════════════════════════ 控件工厂 ══════════════════════════//--
local function addSection(parent, title)
	local row = create("Frame", {
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundTransparency = 1,
		LayoutOrder = pushOrder(),
		Parent = parent,
	})

	local bar = create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.fromOffset(3, 14),
		BackgroundColor3 = PALETTE.accent,
		BorderSizePixel = 0,
		Parent = row,
	})
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = bar })
	create("UIGradient", {
		Color = ColorSequence.new(PALETTE.accent2, PALETTE.accent),
		Rotation = 90,
		Parent = bar,
	})

	create("TextLabel", {
		Text = title,
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextColor3 = PALETTE.text,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(1, -12, 1, 0),
		Parent = row,
	})

	return row
end

local function addToggle(parent, title, desc, key, onChanged)
	local height = desc and 54 or 48
	local row = create("Frame", {
		Size = UDim2.new(1, 0, 0, height),
		BackgroundColor3 = PALETTE.card,
		BorderSizePixel = 0,
		LayoutOrder = pushOrder(),
		Parent = parent,
	})
	create("UICorner", { CornerRadius = UDim.new(0, 9), Parent = row })
	local stroke = create("UIStroke", {
		Color = PALETTE.stroke,
		Thickness = 1,
		Transparency = 0.55,
		Parent = row,
	})

	create("TextLabel", {
		Text = title,
		Font = Enum.Font.GothamMedium,
		TextSize = 14,
		TextColor3 = PALETTE.text,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(14, desc and 9 or 0),
		Size = desc and UDim2.new(1, -90, 0, 18) or UDim2.new(1, -90, 1, 0),
		Parent = row,
	})

	if desc then
		create("TextLabel", {
			Text = desc,
			Font = Enum.Font.Gotham,
			TextSize = 10,
			TextColor3 = PALETTE.sub,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(14, 29),
			Size = UDim2.new(1, -90, 0, 14),
			Parent = row,
		})
	end

	local track = create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.fromOffset(46, 24),
		BackgroundColor3 = PALETTE.stroke,
		BorderSizePixel = 0,
		Parent = row,
	})
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = track })

	local knob = create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 3, 0.5, 0),
		Size = UDim2.fromOffset(18, 18),
		BackgroundColor3 = PALETTE.sub,
		BorderSizePixel = 0,
		Parent = track,
	})
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = knob })

	local click = create("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		Parent = row,
	})

	local function paint()
		local on = Config[key] == true
		local info = TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(track, info, {
			BackgroundColor3 = on and PALETTE.accent or PALETTE.stroke,
		}):Play()
		TweenService:Create(knob, info, {
			Position = on and UDim2.new(0, 25, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
			BackgroundColor3 = on and PALETTE.white or PALETTE.sub,
		}):Play()
	end

	paint()

	click.MouseEnter:Connect(function()
		TweenService:Create(stroke, TweenInfo.new(0.12), {
			Color = PALETTE.accent,
			Transparency = 0.3,
		}):Play()
	end)
	click.MouseLeave:Connect(function()
		TweenService:Create(stroke, TweenInfo.new(0.12), {
			Color = PALETTE.stroke,
			Transparency = 0.55,
		}):Play()
	end)

	click.MouseButton1Click:Connect(function()
		Config[key] = not Config[key]
		paint()
		if onChanged then
			task.spawn(function()
				local ok, err = pcall(onChanged, Config[key])
				if not ok then warn("[SaintOriM] " .. tostring(err)) end
			end)
		end
	end)

	return {
		row = row,
		paint = paint,
		set = function(value, silent)
			Config[key] = value
			paint()
			if onChanged and not silent then
				task.spawn(onChanged, value)
			end
		end,
	}
end

local function addSlider(parent, title, key, min, max, step, suffix, onChanged)
	local row = create("Frame", {
		Size = UDim2.new(1, 0, 0, 68),
		BackgroundColor3 = PALETTE.card,
		BorderSizePixel = 0,
		LayoutOrder = pushOrder(),
		Parent = parent,
	})
	create("UICorner", { CornerRadius = UDim.new(0, 9), Parent = row })
	local stroke = create("UIStroke", {
		Color = PALETTE.stroke,
		Thickness = 1,
		Transparency = 0.55,
		Parent = row,
	})

	create("TextLabel", {
		Text = title,
		Font = Enum.Font.GothamMedium,
		TextSize = 14,
		TextColor3 = PALETTE.text,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(14, 10),
		Size = UDim2.new(1, -120, 0, 18),
		Parent = row,
	})

	local valueLabel = create("TextLabel", {
		Text = fmt(Config[key]) .. (suffix or ""),
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextColor3 = PALETTE.accent,
		TextXAlignment = Enum.TextXAlignment.Right,
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -110, 0, 10),
		Size = UDim2.fromOffset(96, 18),
		Parent = row,
	})

	local track = create("Frame", {
		Position = UDim2.fromOffset(14, 48),
		Size = UDim2.new(1, -28, 0, 8),
		BackgroundColor3 = PALETTE.stroke,
		BorderSizePixel = 0,
		Parent = row,
	})
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = track })

	local fill = create("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = PALETTE.accent,
		BorderSizePixel = 0,
		Parent = track,
	})
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = fill })
	create("UIGradient", {
		Color = ColorSequence.new(PALETTE.accent, PALETTE.accent2),
		Parent = fill,
	})

	local knob = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.fromOffset(18, 18),
		BackgroundColor3 = PALETTE.white,
		BorderSizePixel = 0,
		ZIndex = 2,
		Parent = track,
	})
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = knob })

	local hitbox = create("TextButton", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.new(1, 0, 0, 28),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 3,
		Parent = track,
	})

	local dragging = false

	local function syncVisual()
		local ratio = 0
		if max > min then
			ratio = math.clamp((Config[key] - min) / (max - min), 0, 1)
		end
		fill.Size = UDim2.fromScale(ratio, 1)
		knob.Position = UDim2.new(ratio, 0, 0.5, 0)
		valueLabel.Text = fmt(Config[key]) .. (suffix or "")
	end

	local function applyFromX(x)
		local origin = track.AbsolutePosition.X
		local width = math.max(track.AbsoluteSize.X, 1)
		local ratio = math.clamp((x - origin) / width, 0, 1)
		local raw = min + (max - min) * ratio
		if step and step > 0 then
			raw = math.floor(raw / step + 0.5) * step
		end
		raw = math.clamp(raw, min, max)
		if raw % 1 ~= 0 then
			raw = math.floor(raw * 100 + 0.5) / 100
		end
		Config[key] = raw
		syncVisual()
		if onChanged then
			local ok, err = pcall(onChanged, raw)
			if not ok then warn("[SaintOriM] " .. tostring(err)) end
		end
	end

	hitbox.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			applyFromX(input.Position.X)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if not dragging then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then
			applyFromX(input.Position.X)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	hitbox.MouseEnter:Connect(function()
		TweenService:Create(stroke, TweenInfo.new(0.12), {
			Color = PALETTE.accent,
			Transparency = 0.3,
		}):Play()
	end)
	hitbox.MouseLeave:Connect(function()
		TweenService:Create(stroke, TweenInfo.new(0.12), {
			Color = PALETTE.stroke,
			Transparency = 0.55,
		}):Play()
	end)

	syncVisual()

	return {
		row = row,
		sync = syncVisual,
		set = function(value)
			Config[key] = value
			syncVisual()
		end,
	}
end

local function addButton(parent, text, color, callback)
	local baseColor = color or PALETTE.card
	local button = create("TextButton", {
		Size = UDim2.new(1, 0, 0, 48),
		BackgroundColor3 = baseColor,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		LayoutOrder = pushOrder(),
		Parent = parent,
	})
	create("UICorner", { CornerRadius = UDim.new(0, 9), Parent = button })
	local stroke = create("UIStroke", {
		Color = PALETTE.stroke,
		Thickness = 1,
		Transparency = 0.55,
		Parent = button,
	})

	local label = create("TextLabel", {
		Text = text,
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
		TextColor3 = PALETTE.text,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Parent = button,
	})

	button.MouseEnter:Connect(function()
		TweenService:Create(stroke, TweenInfo.new(0.12), {
			Color = PALETTE.accent,
			Transparency = 0.25,
		}):Play()
		TweenService:Create(button, TweenInfo.new(0.12), {
			BackgroundColor3 = PALETTE.cardHi,
		}):Play()
	end)
	button.MouseLeave:Connect(function()
		TweenService:Create(stroke, TweenInfo.new(0.12), {
			Color = PALETTE.stroke,
			Transparency = 0.55,
		}):Play()
		TweenService:Create(button, TweenInfo.new(0.12), {
			BackgroundColor3 = baseColor,
		}):Play()
	end)

	button.MouseButton1Click:Connect(function()
		if not callback then return end
		task.spawn(function()
			local ok, err = pcall(callback)
			if not ok then
				notify("执行失败: " .. tostring(err))
				warn("[SaintOriM] " .. tostring(err))
			end
		end)
	end)

	return { button = button, label = label }
end

local function addInfo(parent, text)
	local row = create("Frame", {
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundColor3 = PALETTE.card,
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		LayoutOrder = pushOrder(),
		Parent = parent,
	})
	create("UICorner", { CornerRadius = UDim.new(0, 9), Parent = row })
	create("UIStroke", {
		Color = PALETTE.stroke,
		Thickness = 1,
		Transparency = 0.7,
		Parent = row,
	})

	local label = create("TextLabel", {
		Text = text,
		Font = Enum.Font.Gotham,
		TextSize = 10,
		TextColor3 = PALETTE.sub,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(14, 0),
		Size = UDim2.new(1, -28, 1, 0),
		Parent = row,
	})

	return { row = row, label = label }
end

-- 飞行方向虚拟按键（手机没有 WASD）
local function addFlyPad(parent)
	local holder = create("Frame", {
		Size = UDim2.new(1, 0, 0, 150),
		BackgroundColor3 = PALETTE.card,
		BorderSizePixel = 0,
		LayoutOrder = pushOrder(),
		Parent = parent,
	})
	create("UICorner", { CornerRadius = UDim.new(0, 9), Parent = holder })
	create("UIStroke", {
		Color = PALETTE.stroke,
		Thickness = 1,
		Transparency = 0.55,
		Parent = holder,
	})

	create("TextLabel", {
		Text = "飞行方向（按住生效）",
		Font = Enum.Font.Gotham,
		TextSize = 10,
		TextColor3 = PALETTE.sub,
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(12, 8),
		Size = UDim2.new(1, -24, 0, 14),
		Parent = holder,
	})

	local layout = create("Frame", {
		Position = UDim2.fromOffset(10, 28),
		Size = UDim2.new(1, -20, 0, 112),
		BackgroundTransparency = 1,
		Parent = holder,
	})
	create("UIGridLayout", {
		CellSize = UDim2.new(0.3, -6, 0, 32),
		CellPadding = UDim2.new(0, 6, 0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = layout,
	})

	local function buildPad(text, key, order)
		local btn = create("TextButton", {
			Text = "",
			BackgroundColor3 = PALETTE.cardHi,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			LayoutOrder = order,
			Parent = layout,
		})
		create("UICorner", { CornerRadius = UDim.new(0, 7), Parent = btn })
		local stroke = create("UIStroke", {
			Color = PALETTE.stroke,
			Thickness = 1,
			Transparency = 0.4,
			Parent = btn,
		})
		local label = create("TextLabel", {
			Text = text,
			Font = Enum.Font.GothamMedium,
			TextSize = 12,
			TextColor3 = PALETTE.text,
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Parent = btn,
		})

		local function press()
			flyInput[key] = true
			TweenService:Create(btn, TweenInfo.new(0.1), {
				BackgroundColor3 = PALETTE.accent,
			}):Play()
			label.TextColor3 = PALETTE.white
		end
		local function release()
			flyInput[key] = false
			TweenService:Create(btn, TweenInfo.new(0.1), {
				BackgroundColor3 = PALETTE.cardHi,
			}):Play()
			label.TextColor3 = PALETTE.text
		end

		btn.MouseButton1Down:Connect(press)
		btn.MouseButton1Up:Connect(release)
		btn.MouseLeave:Connect(release)
		btn.TouchTap:Connect(function()
			press()
			task.delay(0.35, release)
		end)

		return btn
	end

	buildPad("上升", "up", 1)
	buildPad("前进", "forward", 2)
	buildPad("下降", "down", 3)
	buildPad("左移", "left", 4)
	buildPad("后退", "back", 5)
	buildPad("右移", "right", 6)

	return holder
end

--//═════════════════════════ 页面内容 ══════════════════════════//--
-- 角色页
local pageCharacter = createPage("character")

addSection(pageCharacter, "移动模块")
addToggle(pageCharacter, "飞天", "WASD / 下方按键控制方向", "Fly")
addSlider(pageCharacter, "飞行速度", "FlySpeed", 20, 300, 5, " 格")
addToggle(pageCharacter, "穿墙", "关闭角色全部碰撞体", "Noclip")
addToggle(pageCharacter, "加速", "受防护限速约束", "Speed", function(on)
	applySafeWalkSpeed()
end)
addSlider(pageCharacter, "行走速度", "SpeedValue", 16, 200, 1, "", function()
	applySafeWalkSpeed()
end)
addToggle(pageCharacter, "无限跳跃", "空中重复跳跃", "InfiniteJump")
addFlyPad(pageCharacter)

addSection(pageCharacter, "愤怒机器人")
local robotToggle
robotToggle = addToggle(pageCharacter, "召唤愤怒机器人", "本地悬浮战斗机器人", "AngryRobot", function(on)
	if on then
		local ok = spawnAngryRobot()
		if not ok then
			robotToggle.set(false, true)
			notify("需要先有角色才能召唤机器人")
		end
	else
		destroyRobot()
	end
end)
addSlider(pageCharacter, "机器人尺寸", "RobotScale", 0.5, 3, 0.1, "x", function()
	if Config.AngryRobot then
		spawnAngryRobot()
	end
end)
addButton(pageCharacter, "触发生成类远程", PALETTE.card, function()
	local sent = triggerRobotSpawn()
	notify(("已投递 %d 次生成请求"):format(sent))
end)

addSection(pageCharacter, "便利功能")
addButton(pageCharacter, "重置角色", PALETTE.card, function()
	local hum = getHum()
	if hum then hum.Health = 0 end
end)
addButton(pageCharacter, "临时疾跑 300", PALETTE.card, function()
	local hum = getHum()
	if hum then
		hum.WalkSpeed = 300
		task.delay(3, applySafeWalkSpeed)
	end
end)

-- 战斗页
local pageCombat = createPage("combat")

addSection(pageCombat, "自瞄模块")
addToggle(pageCombat, "自瞄", "锁定视野内最近敌人", "Aimbot")
addSlider(pageCombat, "视野范围 FOV", "AimbotFOV", 50, 1200, 10, " px")
addSlider(pageCombat, "平滑度", "AimbotSmooth", 0.05, 1, 0.05, "")
addToggle(pageCombat, "队伍检测", "忽略队友", "TeamCheck")
local aimPartButton = addButton(pageCombat, "瞄准部位：Head", PALETTE.card, function()
	Config.AimPart = (Config.AimPart == "Head") and "HumanoidRootPart" or "Head"
	aimPartButton.label.Text = "瞄准部位：" .. Config.AimPart
end)

addSection(pageCombat, "开火模块")
addToggle(pageCombat, "自动开火", "锁定目标后自动攻击", "AutoFire")
addSlider(pageCombat, "射速间隔", "FireRate", 0.02, 1, 0.01, " s")

addSection(pageCombat, "子弹追踪")
addToggle(pageCombat, "子弹追踪", "按速度计算提前量锁定", "BulletTrack")
addSlider(pageCombat, "弹速", "BulletSpeed", 100, 3000, 50, " m/s")
addSlider(pageCombat, "预判系数", "Prediction", 0, 3, 0.05, "x")

addSection(pageCombat, "范围模块")
addToggle(pageCombat, "范围攻击", "对半径内全部目标批量触发", "Range")
addSlider(pageCombat, "范围半径", "RangeValue", 5, 250, 1, " 格")
addInfo(pageCombat, "手机端自动开火优先调用工具 Activate，没有工具时回退到触屏点击。")

-- 经济页
local pageEconomy = createPage("economy")

addSection(pageEconomy, "自动获取")
addToggle(pageEconomy, "自动拾取", "分步位移靠近钱币与掉落物", "AutoFarm")
addSlider(pageEconomy, "拾取间隔", "FarmDelay", 0.1, 2, 0.05, " s")
addToggle(pageEconomy, "自动领取", "循环触发 reward / claim 类远程", "AutoClaim")
addSlider(pageEconomy, "领取间隔", "ClaimDelay", 0.5, 10, 0.5, " s")

addSection(pageEconomy, "远程注入")
addButton(pageEconomy, "尝试刷钱", PALETTE.accent, function()
	local ok, message = tryMoneyRemotes()
	notify(message)
	if ok then print("[SaintOriM] " .. message) end
end)
addButton(pageEconomy, "列出金额类远程", PALETTE.card, function()
	local remotes = matchRemotes(
		"cash", "money", "coin", "reward", "bank", "wallet", "grant", "give", "add"
	)
	print("[SaintOriM] 金额类远程 " .. #remotes .. " 个：")
	for _, remote in ipairs(remotes) do
		print("  " .. remote:GetFullName() .. "  [" .. remote.ClassName .. "]")
	end
	notify(("共 %d 个金额类远程"):format(#remotes))
end)
addInfo(pageEconomy, "所有远程调用都经过节流与抖动，降低被频率检测捕捉的概率。")

-- 执法页
local pagePolice = createPage("police")

addSection(pagePolice, "执法模块")
addToggle(pagePolice, "自动拷", "附近嫌疑人自动逮捕 / 手铐", "AutoArrest")
addSlider(pagePolice, "拷人距离", "ArrestRange", 3, 80, 1, " 格")

addSection(pagePolice, "身份操作")
addButton(pagePolice, "加入警察队伍", PALETTE.card, function()
	local ok, message = joinPoliceTeam()
	notify(message)
	print("[SaintOriM] " .. message)
end)
addButton(pagePolice, "清除通缉 / 保释", PALETTE.card, function()
	local sent = clearWanted()
	notify(("已投递 %d 次通缉类请求"):format(sent))
end)
addButton(pagePolice, "列出执法类远程", PALETTE.card, function()
	local remotes = arrestRemotes()
	print("[SaintOriM] 执法类远程 " .. #remotes .. " 个：")
	for _, remote in ipairs(remotes) do
		print("  " .. remote:GetFullName() .. "  [" .. remote.ClassName .. "]")
	end
	notify(("共 %d 个执法类远程"):format(#remotes))
end)
addInfo(pagePolice, "服务端只受理具备执法权限的逮捕请求，先加入警察队伍再开自动拷。")

-- 自动化页
local pageAutomation = createPage("automation")

addSection(pageAutomation, "自动执行")
addToggle(pageAutomation, "自动黑客", "自动触发黑客远程与终端交互", "AutoHack")
addSlider(pageAutomation, "黑客间隔", "HackDelay", 0.1, 3, 0.1, " s")
addToggle(pageAutomation, "自动交互", "自动触发附近 ProximityPrompt", "AutoInteract")

addSection(pageAutomation, "快速操作")
addButton(pageAutomation, "立即执行一轮自动化", PALETTE.accent, function()
	local prompts = autoInteractOnce(30)
	local remotes = matchRemotes(
		"hack", "terminal", "console", "panel", "decrypt", "bypass", "secur", "keypad", "unlock"
	)
	local sent = fireAll(remotes)
	notify(("交互 %d 个 · 远程 %d 次"):format(prompts, sent))
end)
addButton(pageAutomation, "重新扫描远程", PALETTE.card, function()
	local list = refreshRemotes(true)
	notify(("已重新扫描，共 %d 个远程"):format(#list))
end)

-- 防护页
local pageGuard = createPage("guard")

addSection(pageGuard, "防护总控")
local guardToggle
guardToggle = addToggle(pageGuard, "防护绕过", "总开关：限速 / 分步 / 节流", "GuardEnabled", function(on)
	Guard.Enabled = on
	badgeLabel.Text = on and "防护开启" or "防护关闭"
	badgeLabel.TextColor3 = on and PALETTE.green or PALETTE.red
	applySafeWalkSpeed()
end)
guardToggle.set(Guard.Enabled, true)

addSection(pageGuard, "移动防护")
addSlider(pageGuard, "安全速度上限", "GuardMaxSpeed", 16, 100, 1, " 格", function(value)
	Guard.MaxWalkSpeed = value
	applySafeWalkSpeed()
end)
addToggle(pageGuard, "位移分步", "把大跨度移动拆成多小步", "GuardSplit", function(on)
	Guard.SplitTeleport = on
end)
addSlider(pageGuard, "每步格数", "GuardStep", 2, 25, 1, " 格", function(value)
	Guard.TeleportStep = value
end)
addSlider(pageGuard, "步间隔", "GuardStepDelay", 0.02, 0.3, 0.01, " s", function(value)
	Guard.TeleportDelay = value
end)
addToggle(pageGuard, "飞行限速", "限制飞行速度上限", "GuardSafeFly", function(on)
	Guard.SafeFly = on
end)
addSlider(pageGuard, "飞行速度上限", "GuardFlyMax", 20, 120, 5, " 格", function(value)
	Guard.FlyMaxSpeed = value
end)
addToggle(pageGuard, "平滑加速", "速度渐变代替瞬间加速", "GuardSmoothFly", function(on)
	Guard.SmoothFly = on
end)

addSection(pageGuard, "网络防护")
addToggle(pageGuard, "远程节流", "限制单个远程的调用频率", "GuardThrottle", function(on)
	Guard.ThrottleRemotes = on
end)
addSlider(pageGuard, "远程冷却", "GuardCooldown", 0.02, 1, 0.01, " s", function(value)
	Guard.RemoteCooldown = value
end)
addSlider(pageGuard, "调用抖动", "GuardJitter", 0, 0.5, 0.01, " s", function(value)
	Guard.RemoteJitter = value
end)

addSection(pageGuard, "环境防护")
addButton(pageGuard, "中和客户端反作弊脚本", PALETTE.card, function()
	local killed = neutralizeGuards()
	if #killed == 0 then
		notify("没有发现名称匹配的客户端反作弊脚本")
	else
		print("[SaintOriM] 已禁用 " .. #killed .. " 个脚本：")
		for _, name in ipairs(killed) do
			print("  " .. name)
		end
		notify(("已禁用 %d 个客户端检测脚本"):format(#killed))
	end
end)
addButton(pageGuard, "清理全局痕迹", PALETTE.card, function()
	local removed = cleanTraces()
	notify(("已清理 %d 处全局痕迹"):format(removed))
end)
addButton(pageGuard, "输出防护报告", PALETTE.card, function()
	local report = guardReport()
	print("[SaintOriM] " .. report)
	notify(report)
end)
addInfo(pageGuard, "手机端没有 PC 的内核级保护，但服务器仍在看你的位移、速度与远程频率。把安全速度压在 32~45，瞬移走分步，远程开节流，是存活率最高的组合。")

-- 设置页
local pageSettings = createPage("settings")

addSection(pageSettings, "界面与性能")
addToggle(pageSettings, "低配模式", "降低机器人刷新与扫描频率", "LiteMode")
addButton(pageSettings, "切换界面显示", PALETTE.card, function()
	window.Visible = not window.Visible
end)
addInfo(pageSettings, "左上角悬浮球：单击开合面板，长按拖动位置。")

addSection(pageSettings, "诊断")
addButton(pageSettings, "输出全部远程到控制台", PALETTE.card, function()
	local list = refreshRemotes(true)
	print("[SaintOriM] 共 " .. #list .. " 个远程对象：")
	for _, remote in ipairs(list) do
		print("  " .. remote:GetFullName() .. "  [" .. remote.ClassName .. "]")
	end
	notify(("共 %d 个远程"):format(#list))
end)
addButton(pageSettings, "打印环境信息", PALETTE.card, function()
	print("[SaintOriM] PlaceId = " .. tostring(game.PlaceId))
	print("[SaintOriM] JobId = " .. tostring(game.JobId))
	print("[SaintOriM] 触摸设备 = " .. tostring(Compat.isTouch))
	print("[SaintOriM] 视口 = " .. tostring(getCamera().ViewportSize))
	notify("环境信息已输出")
end)

addSection(pageSettings, "恢复与卸载")
addButton(pageSettings, "恢复默认设置", PALETTE.card, function()
	for key, value in pairs(DEFAULT_CONFIG) do
		Config[key] = value
	end
	Guard.Enabled = true
	Guard.MaxWalkSpeed = 32
	Guard.SplitTeleport = true
	Guard.TeleportStep = 7
	Guard.TeleportDelay = 0.07
	Guard.ThrottleRemotes = true
	Guard.RemoteCooldown = 0.12
	Guard.RemoteJitter = 0.12
	destroyFly()
	restoreNoclip()
	destroyRobot()
	applySafeWalkSpeed()
	guardToggle.set(true, true)
	notify("已恢复默认设置")
end)
addButton(pageSettings, "卸载脚本", PALETTE.red, function()
	destroyFly()
	restoreNoclip()
	destroyRobot()
	pcall(function() RunService:UnbindFromRenderStep("SaintOriMobileAim") end)
	gui:Destroy()
end)

--//═════════════════════════ 页签按钮 ══════════════════════════//--
for index, def in ipairs(TAB_DEFS) do
	local button = create("TextButton", {
		Name = def.id,
		Size = UDim2.fromOffset(96, 34),
		BackgroundColor3 = PALETTE.card,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		LayoutOrder = index,
		Parent = tabList,
	})
	create("UICorner", { CornerRadius = UDim.new(0, 7), Parent = button })

	local label = create("TextLabel", {
		Text = def.glyph .. "  " .. def.label,
		Font = Enum.Font.GothamMedium,
		TextSize = 12,
		TextColor3 = PALETTE.sub,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Parent = button,
	})

	local function setActive(active)
		local info = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(button, info, {
			BackgroundTransparency = active and 0 or 1,
			BackgroundColor3 = PALETTE.card,
		}):Play()
		TweenService:Create(label, info, {
			TextColor3 = active and PALETTE.text or PALETTE.sub,
		}):Play()
	end

	button.MouseButton1Click:Connect(function()
		selectTab(def.id)
	end)

	tabButtons[def.id] = { button = button, setActive = setActive }
end

selectTab("character")

--//═════════════════════════ 悬浮球 ══════════════════════════//--
local fab = create("TextButton", {
	Name = "SaintOriFab",
	Size = UDim2.fromOffset(50, 50),
	Position = UDim2.new(0, 14, 0, 96),
	BackgroundColor3 = PALETTE.accent,
	BorderSizePixel = 0,
	Text = "",
	AutoButtonColor = false,
	Parent = gui,
})
create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = fab })
create("UIStroke", { Color = PALETTE.accent2, Thickness = 2, Parent = fab })

local fabLabel = create("TextLabel", {
	Text = "圣",
	Font = Enum.Font.GothamBold,
	TextSize = 20,
	TextColor3 = PALETTE.white,
	BackgroundTransparency = 1,
	Size = UDim2.fromScale(1, 1),
	Parent = fab,
})

local fabDragging = false
local fabMoved = false
local fabStart = nil
local fabOrigin = nil

fab.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
		fabDragging = true
		fabMoved = false
		fabStart = input.Position
		fabOrigin = fab.Position
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if not fabDragging then return end
	if input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch then
		local delta = input.Position - fabStart
		if math.abs(delta.X) > 6 or math.abs(delta.Y) > 6 then
			fabMoved = true
		end
		fab.Position = UDim2.new(
			fabOrigin.X.Scale,
			fabOrigin.X.Offset + delta.X,
			fabOrigin.Y.Scale,
			fabOrigin.Y.Offset + delta.Y
		)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
		if fabDragging and not fabMoved then
			window.Visible = not window.Visible
		end
		fabDragging = false
	end
end)

--//═════════════════════════ 窗口拖动 ══════════════════════════//--
local draggingWindow = false
local dragStart = nil
local dragOrigin = nil

topbar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
		draggingWindow = true
		dragStart = input.Position
		dragOrigin = window.Position
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if not draggingWindow then return end
	if input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch then
		local delta = input.Position - dragStart
		window.Position = UDim2.new(
			dragOrigin.X.Scale,
			dragOrigin.X.Offset + delta.X,
			dragOrigin.Y.Scale,
			dragOrigin.Y.Offset + delta.Y
		)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
		draggingWindow = false
	end
end)

--//═════════════════════════ 热键与事件 ══════════════════════════//--
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.RightShift then
		gui.Enabled = not gui.Enabled
	end
end)

UserInputService.JumpRequest:Connect(function()
	if not Config.InfiniteJump then return end
	local hum = getHum()
	if hum then
		hum:ChangeState(Enum.HumanoidStateType.Jumping)
	end
end)

LP.CharacterAdded:Connect(function()
	noclipBackup = {}
	destroyFly()
	captureDefaultSpeed()
	if Config.AngryRobot then
		task.delay(0.6, spawnAngryRobot)
	end
	task.delay(0.6, applySafeWalkSpeed)
end)

getCamera():GetPropertyChangedSignal("ViewportSize"):Connect(refreshScale)

--//═════════════════════════ 调度器 ══════════════════════════//--
local Scheduler = { entries = {} }

local function addTask(name, interval, fn)
	Scheduler.entries[name] = { interval = interval, last = 0, fn = fn }
end

-- 逻辑功能统一走 Heartbeat，降低手机端绘制压力
addTask("noclip", 0.1, function()
	if Config.Noclip then
		noclipStep()
	elseif next(noclipBackup) ~= nil then
		restoreNoclip()
	end
end)

addTask("speed", 0.2, function()
	if Config.Speed then applySafeWalkSpeed() end
end)

-- 下面这些功能自己带累积节流，调度器只负责定频驱动
addTask("range", 0.05, rangeStep)
addTask("farm", 0.05, farmStep)
addTask("claim", 0.1, claimStep)
addTask("arrest", 0.05, arrestStep)
addTask("hack", 0.05, hackStep)
addTask("interact", 0.1, interactStep)

RunService.Heartbeat:Connect(function(dt)
	for _, entry in pairs(Scheduler.entries) do
		if entry.interval and entry.fn then
			entry.last = entry.last + dt
			if entry.last >= entry.interval then
				entry.last = 0
				pcall(entry.fn, dt)
			end
		end
	end
end)

-- 瞄准留在 RenderStepped，写入相机必须在相机更新之后
RunService:BindToRenderStep("SaintOriMobileAim", Enum.RenderPriority.Camera.Value + 1, function(dt)
	if Config.Fly then
		pcall(flyStep)
	elseif flyState.bv then
		destroyFly()
	end

	if Config.Aimbot or Config.BulletTrack then
		pcall(aimStep)
	end

	if Config.AutoFire then
		pcall(autoFireStep, dt)
	end
end)

-- 低配模式下降频机器人刷新
do
	local lastScale = Config.LiteMode
	RunService.Heartbeat:Connect(function()
		if Config.LiteMode ~= lastScale then
			lastScale = Config.LiteMode
			if robotState.model then
				spawnAngryRobot()
			end
		end
	end)
end

--//═════════════════════════ 启动提示 ══════════════════════════//--
task.defer(function()
	captureDefaultSpeed()
end)

task.delay(0.6, function()
	if Compat.isTouch then
		notify("手机端模式已启用 · 点左上角「圣」开合面板")
	else
		notify("SAINT ORI MOBILE 已加载 · RightShift 隐藏")
	end
end)

print("[SaintOriM] 加载完成 | PlaceId = " .. tostring(game.PlaceId))

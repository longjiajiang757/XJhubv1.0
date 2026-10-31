--[[
    ╔══════════════════════════════════════════════════════════════════════╗
    ║          S A I N T   O R I   M O B I L E   H U B   v 4 . 0           ║
    ║       罗布乐思手机端多功能脚本 · 抓包自学习 · 动画 UI                 ║
    ║  角色 · 战斗 · 经济 · 执法 · 自动化 · 学习 · 诊断 · 设置              ║
    ╚══════════════════════════════════════════════════════════════════════╝

    v4 修掉的老问题：
      · 恢复默认后开关/滑块显示与实际值不同步
      · 刷钱只发出去一组参数（被节流吃掉后两组）
      · 自动黑客/自动交互每次全图遍历，手机端卡顿
      · 多个滑块重复注册全局输入监听
      · 相机状态异常时脚本直接报错中断
      · 角色重生后部分状态丢失
      · 关闭加速后把 WalkSpeed 写死成 16

    v4 新增：
      · 抓包学习：hook __namecall，把游戏真实调用的 Remote 全部记下来并自动分类
      · 功能自动换源：学习到的 Remote 优先生效，不用再手改关键字
      · 诊断面板：每个 API、每个功能是否就绪一目了然
      · 全套动画：窗口弹出、页签滑入、弹簧开关、按钮回弹、悬浮球呼吸

    用法：执行器里直接运行。开局点「学习 → 开始抓包」，正常玩 30 秒再开功能。
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
	hookmetamethod = (typeof(hookmetamethod) == "function") and hookmetamethod or nil,
	getrawmetatable = (typeof(getrawmetatable) == "function") and getrawmetatable or nil,
	setreadonly = (typeof(setreadonly) == "function") and setreadonly or nil,
	newcclosure = (typeof(newcclosure) == "function") and newcclosure or nil,
	getnamecallmethod = (typeof(getnamecallmethod) == "function") and getnamecallmethod or nil,
	hookfunction = (typeof(hookfunction) == "function") and hookfunction or nil,
}

--//═══════════════════════════ 调色板 ═══════════════════════════//--
local PALETTE = {
	bg      = Color3.fromRGB(11, 11, 17),
	sidebar = Color3.fromRGB(15, 15, 23),
	card    = Color3.fromRGB(23, 23, 34),
	cardHi  = Color3.fromRGB(33, 33, 48),
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
	-- 学习
	SpyEnabled    = false,
	-- 性能
	LiteMode      = false,
	-- 防护
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

local function fmt(number)
	if type(number) ~= "number" then return tostring(number) end
	if number % 1 == 0 then return tostring(number) end
	local text = string.format("%.2f", number)
	text = string.gsub(text, "%.?0+$", "")
	return text
end

--//═══════════════════════════ 分类规则 ═══════════════════════════//--
local CLASSIFY_RULES = {
	money  = {
		"cash", "money", "coin", "gem", "diamond", "gold", "bank", "wallet",
		"balance", "reward", "claim", "collect", "pickup", "loot", "bounty",
		"pay", "salary", "income", "rob", "heist", "steal", "vaultcash", "deposit",
	},
	damage = {
		"damage", "hit", "attack", "punch", "slash", "shoot", "fire", "kill",
		"hurt", "combat", "swing", "melee", "weapon", "shot", "bullet", "stab",
		"taze", "taser", "baton", "punch", "kick",
	},
	arrest = {
		"arrest", "cuff", "handcuff", "jail", "detain", "wanted", "suspect",
		"cop", "police", "prison", "cell", "trial", "sentence", "bail", "escape",
	},
	hack   = {
		"hack", "terminal", "console", "panel", "decrypt", "bypass", "upload",
		"secur", "keypad", "code", "password", "unlock", "access", "laser",
		"alarm", "vault", "safe", "wire", "hackpanel",
	},
	spawn  = {
		"spawn", "summon", "robot", "bot", "mech", "pet", "vehicle", "car",
		"angry", "deploy",
	},
}

local REMOTE_CATEGORIES = { "money", "damage", "arrest", "hack", "spawn" }

local function classifyName(name)
	local lower = string.lower(name)
	local hits = {}
	for _, category in ipairs(REMOTE_CATEGORIES) do
		for _, keyword in ipairs(CLASSIFY_RULES[category]) do
			if string.find(lower, keyword, 1, true) then
				hits[#hits + 1] = category
				break
			end
		end
	end
	return hits
end

--//═══════════════════════════ 远程数据库 ═══════════════════════════//--
local RemoteDB = {
	learned = {},          -- [Instance] = { name = string, categories = {}, hits = number, lastArgs = string }
	byCategory = {
		money = {}, damage = {}, arrest = {}, hack = {}, spawn = {},
	},
	scanCache = { list = {}, stamp = -999 },
	spyInstalled = false,
	spyCount = 0,
}

local categoryCache = { stamp = -999, map = {} }

local function invalidateCategoryCache()
	categoryCache.stamp = -999
end

local function dedupe(list)
	local seen = {}
	local out = {}
	for _, item in ipairs(list) do
		if item and item.Parent and not seen[item] then
			seen[item] = true
			out[#out + 1] = item
		end
	end
	return out
end

-- 全图静态扫描（带缓存）
local function scanRemotes(force)
	if not force and (os.clock() - RemoteDB.scanCache.stamp) < 6 then
		return RemoteDB.scanCache.list
	end

	local list = {}
	local roots = {
		ReplicatedStorage,
		Workspace,
		ReplicatedFirst,
		LP,
	}

	for _, root in ipairs(roots) do
		local ok, descendants = pcall(function() return root:GetDescendants() end)
		if ok then
			for _, obj in ipairs(descendants) do
				if obj:IsA("RemoteEvent")
					or obj:IsA("RemoteFunction")
					or obj:IsA("UnreliableRemoteEvent") then
					list[#list + 1] = obj
				end
			end
		end
	end

	RemoteDB.scanCache.list = dedupe(list)
	RemoteDB.scanCache.stamp = os.clock()
	return RemoteDB.scanCache.list
end

-- 学习到的远程写入分类
local function registerLearned(remote, args)
	local entry = RemoteDB.learned[remote]
	if not entry then
		entry = {
			name = remote.Name,
			fullName = remote:GetFullName(),
			categories = {},
			hits = 0,
			lastArgs = "",
		}
		RemoteDB.learned[remote] = entry
	end

	entry.hits = entry.hits + 1
	RemoteDB.spyCount = RemoteDB.spyCount + 1

	if args then
		local parts = {}
		for index = 1, math.min(#args, 3) do
			parts[#parts + 1] = tostring(args[index])
		end
		entry.lastArgs = table.concat(parts, ", ")
	end

	local categories = classifyName(remote.Name)
	entry.categories = categories

	for _, category in ipairs(categories) do
		local bucket = RemoteDB.byCategory[category]
		if bucket and not table.find(bucket, remote) then
			bucket[#bucket + 1] = remote
		end
	end

	if #categories > 0 then
		invalidateCategoryCache()
	end
end

-- 按分类取远程：学习结果优先，静态扫描补齐
local function remotesFor(category)
	if os.clock() - categoryCache.stamp > 6 then
		categoryCache.map = {}
		categoryCache.stamp = os.clock()
	end
	if categoryCache.map[category] then
		return categoryCache.map[category]
	end

	local list = {}

	local learned = RemoteDB.byCategory[category]
	if learned then
		for _, remote in ipairs(learned) do
			list[#list + 1] = remote
		end
	end

	local keywords = CLASSIFY_RULES[category]
	if keywords then
		for _, remote in ipairs(scanRemotes(false)) do
			local lower = string.lower(remote.Name)
			for _, keyword in ipairs(keywords) do
				if string.find(lower, keyword, 1, true) then
					list[#list + 1] = remote
					break
				end
			end
		end
	end

	local final = dedupe(list)
	categoryCache.map[category] = final
	return final
end

-- 抓包
local spyConsole = {}

local function entryArgPreview(args)
	local parts = {}
	for index = 1, math.min(#args, 3) do
		local text = tostring(args[index])
		if #text > 40 then
			text = string.sub(text, 1, 40) .. "..."
		end
		parts[#parts + 1] = text
	end
	return "(" .. table.concat(parts, ", ") .. ")"
end

local function installSpy()
	if RemoteDB.spyInstalled then return true end
	if not (Compat.hookmetamethod and Compat.getnamecallmethod) then
		return false
	end

	local ok = pcall(function()
		local mt = Compat.getrawmetatable and Compat.getrawmetatable(game) or getmetatable(game)
		local oldNamecall = mt.__namecall

		local hook = function(self, ...)
			local method = Compat.getnamecallmethod()
			if Config.SpyEnabled and (method == "FireServer" or method == "InvokeServer") then
				local okRemote, isRemote = pcall(function()
					return typeof(self) == "Instance"
						and (self:IsA("RemoteEvent")
							or self:IsA("RemoteFunction")
							or self:IsA("UnreliableRemoteEvent"))
				end)
				if okRemote and isRemote then
					pcall(function()
						registerLearned(self, { ... })
						table.insert(spyConsole, 1, string.format(
							"[%s] %s -> %s",
							Compat.getnamecallmethod(),
							self:GetFullName(),
							entryArgPreview({ ... })
						))
						if #spyConsole > 60 then
							table.remove(spyConsole)
						end
					end)
				end
			end
			return oldNamecall(self, ...)
		end

		if Compat.newcclosure then
			hook = Compat.newcclosure(hook)
		end

		if Compat.setreadonly then
			Compat.setreadonly(mt, false)
			mt.__namecall = hook
			Compat.setreadonly(mt, true)
		else
			mt.__namecall = hook
		end
	end)

	if ok then
		RemoteDB.spyInstalled = true
		return true
	end
	return false
end

--//═══════════════════════════ 通知与报告 ═══════════════════════════//--
local function setCoreNotify(text)
	pcall(function()
		StarterGui:SetCore("SendNotification", {
			Title = "SAINT ORI",
			Text = tostring(text),
			Duration = 3,
		})
	end)
end

local GuardLog = { blockedSpeed = 0, blockedRemotes = 0 }

local function guardReport()
	local lines = {}
	lines[#lines + 1] = "防护 " .. (Guard.Enabled and "开启" or "关闭")
	lines[#lines + 1] = "限速 " .. tostring(Guard.MaxWalkSpeed)
	lines[#lines + 1] = "步长 " .. tostring(Guard.TeleportStep)
	lines[#lines + 1] = "远程冷却 " .. tostring(Guard.RemoteCooldown)
	lines[#lines + 1] = "拦截超速 " .. tostring(GuardLog.blockedSpeed)
	return table.concat(lines, " · ")
end

--//═════════════════════ 远程安全调用（带节流） ══════════════════════//--
local RemoteStamps = setmetatable({}, { __mode = "k" })

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

-- 绕过节流的多参数投递：错开时间，确保每组参数都发出去
local function fireVariants(remote, variants, spacing, baseDelay)
	if not remote or not remote.Parent then return 0 end
	local sent = 0
	for index, args in ipairs(variants) do
		local delay = (baseDelay or 0) + (index - 1) * (spacing or 0.18)
		task.delay(delay, function()
			if not remote.Parent then return end
			pcall(function()
				if remote:IsA("RemoteFunction") then
					remote:InvokeServer(unpack(args))
				else
					remote:FireServer(unpack(args))
				end
			end)
		end)
		sent = sent + 1
	end
	return sent
end

--//═══════════════════════════ 防护模块 ═══════════════════════════//--
local function safeTeleport(targetCFrame)
	local hrp = getHRP()
	if not hrp then return end

	if not (Guard.Enabled and Guard.SplitTeleport) then
		pcall(function() hrp.CFrame = targetCFrame end)
		return
	end

	local start = hrp.Position
	local target = targetCFrame.Position
	local distance = (target - start).Magnitude

	if distance < 2 then
		pcall(function() hrp.CFrame = targetCFrame end)
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
	if Guard.Enabled and target > Guard.MaxWalkSpeed then
		GuardLog.blockedSpeed = GuardLog.blockedSpeed + 1
		target = Guard.MaxWalkSpeed
	end

	if hum.WalkSpeed ~= target then
		hum.WalkSpeed = target
	end
	speedApplied = true
end

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
			if obj:IsA("LocalScript") then
				local lower = string.lower(obj.Name)
				for _, hint in ipairs(ANTI_CHEAT_HINTS) do
					if string.find(lower, hint, 1, true) then
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
	local accumulator = 0

	robotState.conn = RunService.Heartbeat:Connect(function(dt)
		if Config.LiteMode then
			accumulator = accumulator + dt
			if accumulator < 0.08 then return end
			accumulator = 0
		end

		clock = clock + dt
		if not model.Parent then return end
		local me = getHRP()
		if not me then return end

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
	local remotes = remotesFor("spawn")
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
	pcall(function()
		cam.CFrame = cam.CFrame:Lerp(goal, smooth)
	end)
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
	if not cam then return false end
	return pcall(function()
		VirtualUser:ClickButton1(Vector2.new(cam.ViewportSize.X * 0.5, cam.ViewportSize.Y * 0.5))
	end)
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

local rangeAccumulator = 0
local function rangeStep(dt)
	if not Config.Range then return end
	rangeAccumulator = rangeAccumulator + dt
	if rangeAccumulator < 0.25 then return end
	rangeAccumulator = 0

	local hrp = getHRP()
	if not hrp then return end

	local remotes = remotesFor("damage")
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
local MONEY_KEYWORDS = CLASSIFY_RULES.money

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
	if os.clock() - farmCache.stamp < 3 then
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
	fireAll(remotesFor("money"))
end

local function tryMoneyRemotes()
	local remotes = remotesFor("money")
	if #remotes == 0 then
		return false, "没有找到金额类远程，先去「学习」页开抓包"
	end

	local amount = 100000
	local sent = 0
	for index, remote in ipairs(remotes) do
		sent = sent + fireVariants(remote, {
			{ amount },
			{ LP, amount },
			{ "Cash", amount },
			{ amount, "Cash" },
		}, 0.16, (index - 1) * 0.22)
	end
	return true, ("已向 %d 个远程投递 %d 组参数"):format(#remotes, sent)
end

--//═══════════════════════════ 执法功能 ═══════════════════════════//--
local arrestAccumulator = 0
local function arrestStep(dt)
	if not Config.AutoArrest then return end
	arrestAccumulator = arrestAccumulator + dt
	if arrestAccumulator < 0.35 then return end
	arrestAccumulator = 0

	local hrp = getHRP()
	if not hrp then return end

	local remotes = remotesFor("arrest")
	if #remotes == 0 then return end

	for _, plr in ipairs(Players:GetPlayers()) do
		if isValidEnemy(plr) then
			local part = getPartOf(plr)
			if part and (part.Position - hrp.Position).Magnitude <= Config.ArrestRange then
				fireAll(remotes, plr.Character, plr)
				touchPart(part)
			end
		end
	end
end

local function joinPoliceTeam()
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

	local teamRemotes = {}
	for _, remote in ipairs(scanRemotes(false)) do
		local lower = string.lower(remote.Name)
		if string.find(lower, "team", 1, true)
			or string.find(lower, "join", 1, true)
			or string.find(lower, "job", 1, true)
			or string.find(lower, "role", 1, true) then
			teamRemotes[#teamRemotes + 1] = remote
		end
	end

	local sent = 0
	for _, remote in ipairs(teamRemotes) do
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
	return false, "没有找到警察队伍"
end

local function clearWanted()
	local remotes = remotesFor("arrest")
	local sent = fireAll(remotes, true) + fireAll(remotes)
	return sent
end

--//═══════════════════════════ 自动化功能 ═══════════════════════════//--
local promptCache = { stamp = -999, list = {} }

local function getPrompts()
	if os.clock() - promptCache.stamp < 2 then
		return promptCache.list
	end
	local list = {}
	local ok, descendants = pcall(function() return Workspace:GetDescendants() end)
	if ok then
		for _, obj in ipairs(descendants) do
			if obj:IsA("ProximityPrompt") then
				list[#list + 1] = obj
			end
		end
	end
	promptCache.list = list
	promptCache.stamp = os.clock()
	return list
end

local function autoInteractOnce(rangeLimit)
	local hrp = getHRP()
	if not hrp then return 0 end

	local count = 0
	for _, obj in ipairs(getPrompts()) do
		if obj.Enabled and obj.Parent and obj.Parent:IsA("BasePart") then
			if (obj.Parent.Position - hrp.Position).Magnitude <= (rangeLimit or 15) then
				local fired = false
				if Compat.fireproximityprompt then
					fired = pcall(Compat.fireproximityprompt, obj)
				else
					fired = pcall(function()
						obj:InputHoldBegin()
						task.wait(0.08)
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
	fireAll(remotesFor("hack"))
end

local interactAccumulator = 0
local function interactStep(dt)
	if not Config.AutoInteract then return end
	interactAccumulator = interactAccumulator + dt
	if interactAccumulator < 0.6 then return end
	interactAccumulator = 0
	autoInteractOnce(15)
end

--//═══════════════════════════ UI 基础 ═══════════════════════════//--
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

-- 自定义 toast（比 SetCore 可控，带动画）
local toastHolder = create("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 12),
	Size = UDim2.fromOffset(340, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundTransparency = 1,
	ZIndex = 20,
	Parent = gui,
})

local activeToast = nil

local function toast(text, color)
	if activeToast then
		pcall(function() activeToast:Destroy() end)
		activeToast = nil
	end

	local frame = create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = PALETTE.card,
		BorderSizePixel = 0,
		ZIndex = 20,
		Parent = toastHolder,
	})
	create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = frame })
	create("UIStroke", {
		Color = color or PALETTE.accent,
		Thickness = 1,
		Transparency = 0.3,
		Parent = frame,
	})

	local bar = create("Frame", {
		Size = UDim2.new(0, 3, 1, -14),
		Position = UDim2.fromOffset(0, 7),
		BackgroundColor3 = color or PALETTE.accent,
		BorderSizePixel = 0,
		ZIndex = 21,
		Parent = frame,
	})
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = bar })
	create("UIGradient", {
		Color = ColorSequence.new(PALETTE.accent2, PALETTE.accent),
		Rotation = 90,
		Parent = bar,
	})

	local label = create("TextLabel", {
		Text = tostring(text),
		Font = Enum.Font.GothamMedium,
		TextSize = 12,
		TextColor3 = PALETTE.text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(14, 0),
		Size = UDim2.new(1, -24, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		ZIndex = 21,
		Parent = frame,
	})
	create("UIPadding", {
		PaddingTop = UDim.new(0, 10),
		PaddingBottom = UDim.new(0, 10),
		Parent = label,
	})

	activeToast = frame

	frame.Position = UDim2.fromOffset(0, -16)
	local show = TweenService:Create(frame, TweenInfo.new(0.26, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.fromOffset(0, 0),
	})
	show:Play()

	task.delay(2.4, function()
		if frame and frame.Parent then
			local hide = TweenService:Create(frame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Position = UDim2.fromOffset(0, -16),
			})
			hide:Play()
			hide.Completed:Connect(function()
				if frame then frame:Destroy() end
			end)
		end
	end)
end

--//═══════════════════════════ 窗口骨架 ═══════════════════════════//--
local canvas = create("CanvasGroup", {
	Name = "Canvas",
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	GroupTransparency = 0,
	Parent = gui,
})

local window = create("Frame", {
	Name = "Window",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(760, 500),
	BackgroundColor3 = PALETTE.bg,
	BorderSizePixel = 0,
	ClipsDescendants = true,
	Parent = canvas,
})
create("UICorner", { CornerRadius = UDim.new(0, 14), Parent = window })
create("UIStroke", { Color = PALETTE.stroke, Thickness = 1, Parent = window })

local function computeScale()
	local cam = getCamera()
	if not cam then return 1 end
	local vp = cam.ViewportSize
	local factor = math.min(vp.X / 980, vp.Y / 560)
	return math.clamp(factor, 0.62, 1.18)
end

local baseScale = computeScale()
local uiScale = create("UIScale", { Scale = baseScale, Parent = window })

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

local ribbonGradient = ribbon:FindFirstChildOfClass("UIGradient")

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
	Size = UDim2.fromOffset(280, 20),
	Parent = topbar,
})

create("TextLabel", {
	Text = "抓包自学习 · 动画 UI · v4.0",
	Font = Enum.Font.Gotham,
	TextSize = 10,
	TextColor3 = PALETTE.sub,
	TextXAlignment = Enum.TextXAlignment.Left,
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(16, 29),
	Size = UDim2.fromOffset(280, 14),
	Parent = topbar,
})

local badge = create("Frame", {
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -58, 0.5, 0),
	Size = UDim2.fromOffset(96, 24),
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
	Text = "就绪",
	Font = Enum.Font.GothamMedium,
	TextSize = 10,
	TextColor3 = PALETTE.green,
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

-- 横向页签
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

local contentArea = create("Frame", {
	Position = UDim2.fromOffset(0, 101),
	Size = UDim2.new(1, 0, 1, -101),
	BackgroundTransparency = 1,
	ClipsDescendants = true,
	Parent = window,
})

local showWindow
local hideWindow

--//═══════════════════════════ 分页 ═══════════════════════════//--
local TAB_DEFS = {
	{ id = "character",  label = "角色",   glyph = "◆" },
	{ id = "combat",     label = "战斗",   glyph = "✦" },
	{ id = "economy",    label = "经济",   glyph = "◇" },
	{ id = "police",     label = "执法",   glyph = "⬟" },
	{ id = "automation", label = "自动化", glyph = "⟳" },
	{ id = "learning",   label = "学习",   glyph = "◎" },
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
		Position = UDim2.fromOffset(0, 0),
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

local function animatePage(page)
	page.Position = UDim2.fromOffset(26, 0)
	page.CanvasPosition = Vector2.new(0, 0)
	local tween = TweenService:Create(page, TweenInfo.new(0.24, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Position = UDim2.fromOffset(0, 0),
	})
	tween:Play()
end

local function selectTab(id)
	if activeTab == id then return end
	activeTab = id

	for tabId, data in pairs(tabButtons) do
		data.setActive(tabId == id)
	end

	for pageId, page in pairs(pages) do
		local active = pageId == id
		page.Visible = active
		if active then
			animatePage(page)
		end
	end
end

--//═════════════════════════ 控件工厂 ══════════════════════════//--
local Controls = { toggles = {}, sliders = {} }

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
	if Config[key] == nil then
		Config[key] = false
	end

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

	local function paint(animate)
		local on = Config[key] == true
		local style = (animate == nil or animate) and Enum.EasingStyle.Back or Enum.EasingStyle.Quad
		local info = TweenInfo.new(0.26, style, Enum.EasingDirection.Out)
		TweenService:Create(track, info, {
			BackgroundColor3 = on and PALETTE.accent or PALETTE.stroke,
		}):Play()
		TweenService:Create(knob, info, {
			Position = on and UDim2.new(0, 25, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
			BackgroundColor3 = on and PALETTE.white or PALETTE.sub,
		}):Play()
	end

	paint(false)
	Controls.toggles[key] = { paint = paint }

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
		paint(true)
		if onChanged then
			task.spawn(function()
				local ok, err = pcall(onChanged, Config[key])
				if not ok then warn("[SaintOri] " .. tostring(err)) end
			end)
		end
	end)

	return {
		row = row,
		paint = paint,
		set = function(value, silent)
			Config[key] = value
			paint(true)
			if onChanged and not silent then
				task.spawn(onChanged, value)
			end
		end,
	}
end

local activeSlider = nil

UserInputService.InputChanged:Connect(function(input)
	if not activeSlider then return end
	if input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch then
		activeSlider.apply(input.Position.X)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
		if activeSlider then
			activeSlider.finish()
		end
		activeSlider = nil
	end
end)

local function addSlider(parent, title, key, min, max, step, suffix, onChanged)
	if Config[key] == nil then
		Config[key] = min
	end

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
			if not ok then warn("[SaintOri] " .. tostring(err)) end
		end
	end

	hitbox.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			activeSlider = {
				apply = applyFromX,
				finish = function()
					TweenService:Create(knob, TweenInfo.new(0.18, Enum.EasingStyle.Back), {
						Size = UDim2.fromOffset(18, 18),
					}):Play()
				end,
			}
			TweenService:Create(knob, TweenInfo.new(0.16, Enum.EasingStyle.Back), {
				Size = UDim2.fromOffset(24, 24),
			}):Play()
			applyFromX(input.Position.X)
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
	Controls.sliders[key] = { sync = syncVisual }

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
	local baseHeight = 48

	local button = create("TextButton", {
		Size = UDim2.new(1, 0, 0, baseHeight),
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

	local buttonScale = create("UIScale", { Scale = 1, Parent = button })

	button.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			TweenService:Create(buttonScale, TweenInfo.new(0.08, Enum.EasingStyle.Quad), {
				Scale = 0.97,
			}):Play()
		end
	end)

	button.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			TweenService:Create(buttonScale, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Scale = 1,
			}):Play()
		end
	end)

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
				toast("执行失败: " .. tostring(err), PALETTE.red)
				warn("[SaintOri] " .. tostring(err))
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
			TweenService:Create(stroke, TweenInfo.new(0.1), {
				Color = PALETTE.accent2,
				Transparency = 0.2,
			}):Play()
			label.TextColor3 = PALETTE.white
		end

		local function release()
			flyInput[key] = false
			TweenService:Create(btn, TweenInfo.new(0.16, Enum.EasingStyle.Back), {
				BackgroundColor3 = PALETTE.cardHi,
			}):Play()
			TweenService:Create(stroke, TweenInfo.new(0.16), {
				Color = PALETTE.stroke,
				Transparency = 0.4,
			}):Play()
			label.TextColor3 = PALETTE.text
		end

		btn.MouseButton1Down:Connect(press)
		btn.MouseButton1Up:Connect(release)
		btn.MouseLeave:Connect(release)
		btn.TouchTap:Connect(function()
			press()
			task.delay(0.3, release)
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
local pageCharacter = createPage("character")

addSection(pageCharacter, "移动模块")
addToggle(pageCharacter, "飞天", "WASD / 下方按键控制方向", "Fly")
addSlider(pageCharacter, "飞行速度", "FlySpeed", 20, 300, 5, " 格")
addToggle(pageCharacter, "穿墙", "关闭角色全部碰撞体", "Noclip")
addToggle(pageCharacter, "加速", "受防护限速约束", "Speed", function()
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
			toast("需要先有角色才能召唤机器人", PALETTE.red)
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
	toast(("已投递 %d 次生成请求"):format(sent))
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

-- 战斗
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
addInfo(pageCombat, "伤害远程来自「学习」页的抓包结果，抓包前该功能可能找不到目标远程。")

-- 经济
local pageEconomy = createPage("economy")

addSection(pageEconomy, "自动获取")
addToggle(pageEconomy, "自动拾取", "分步位移靠近钱币与掉落物", "AutoFarm")
addSlider(pageEconomy, "拾取间隔", "FarmDelay", 0.1, 2, 0.05, " s")
addToggle(pageEconomy, "自动领取", "循环触发金额类远程", "AutoClaim")
addSlider(pageEconomy, "领取间隔", "ClaimDelay", 0.5, 10, 0.5, " s")

addSection(pageEconomy, "远程注入")
addButton(pageEconomy, "尝试刷钱", PALETTE.accent, function()
	local ok, message = tryMoneyRemotes()
	toast(message, ok and PALETTE.green or PALETTE.red)
	if ok then print("[SaintOri] " .. message) end
end)
addButton(pageEconomy, "列出金额类远程", PALETTE.card, function()
	local remotes = remotesFor("money")
	print("[SaintOri] 金额类远程 " .. #remotes .. " 个：")
	for _, remote in ipairs(remotes) do
		print("  " .. remote:GetFullName())
	end
	toast(("共 %d 个金额类远程"):format(#remotes))
end)
addInfo(pageEconomy, "金额远程若抓包已学会会优先使用学习结果，静态扫描只作为补充。")

-- 执法
local pagePolice = createPage("police")

addSection(pagePolice, "执法模块")
addToggle(pagePolice, "自动拷", "附近嫌疑人自动逮捕 / 手铐", "AutoArrest")
addSlider(pagePolice, "拷人距离", "ArrestRange", 3, 80, 1, " 格")

addSection(pagePolice, "身份操作")
addButton(pagePolice, "加入警察队伍", PALETTE.card, function()
	local ok, message = joinPoliceTeam()
	toast(message, ok and PALETTE.green or PALETTE.red)
	print("[SaintOri] " .. message)
end)
addButton(pagePolice, "清除通缉 / 保释", PALETTE.card, function()
	local sent = clearWanted()
	toast(("已投递 %d 次通缉类请求"):format(sent))
end)
addButton(pagePolice, "列出执法类远程", PALETTE.card, function()
	local remotes = remotesFor("arrest")
	print("[SaintOri] 执法类远程 " .. #remotes .. " 个：")
	for _, remote in ipairs(remotes) do
		print("  " .. remote:GetFullName())
	end
	toast(("共 %d 个执法类远程"):format(#remotes))
end)
addInfo(pagePolice, "服务端只受理有执法权限的逮捕请求，先加入警察队伍再开自动拷。")

-- 自动化
local pageAutomation = createPage("automation")

addSection(pageAutomation, "自动执行")
addToggle(pageAutomation, "自动黑客", "自动触发黑客远程与终端交互", "AutoHack")
addSlider(pageAutomation, "黑客间隔", "HackDelay", 0.1, 3, 0.1, " s")
addToggle(pageAutomation, "自动交互", "自动触发附近 ProximityPrompt", "AutoInteract")

addSection(pageAutomation, "快速操作")
addButton(pageAutomation, "立即执行一轮自动化", PALETTE.accent, function()
	local prompts = autoInteractOnce(30)
	local sent = fireAll(remotesFor("hack"))
	toast(("交互 %d 个 · 远程 %d 次"):format(prompts, sent))
end)
addButton(pageAutomation, "重新扫描远程", PALETTE.card, function()
	local list = scanRemotes(true)
	toast(("已重新扫描，共 %d 个远程"):format(#list))
end)

-- 学习
local pageLearning = createPage("learning")

addSection(pageLearning, "抓包学习")
local spyToggle
spyToggle = addToggle(pageLearning, "开始抓包", "记录游戏真实调用的 Remote", "SpyEnabled", function(on)
	if not on then
		badgeLabel.Text = "就绪"
		return
	end
	if installSpy() then
		badgeLabel.Text = "抓包中"
		toast("抓包已开启，正常玩 30 秒再回来", PALETTE.green)
	else
		spyToggle.set(false, true)
		toast("当前执行器缺少 hook 能力，改用快照扫描", PALETTE.yellow)
	end
end)

local spyStatus = addInfo(pageLearning, "状态：未开始")
local function refreshSpyStatus()
	local total = 0
	for _ in pairs(RemoteDB.learned) do
		total = total + 1
	end
	spyStatus.label.Text = ("已学会 %d 个远程 · 调用 %d 次"):format(total, RemoteDB.spyCount)
end

addButton(pageLearning, "输出抓包控制台", PALETTE.card, function()
	if #spyConsole == 0 then
		toast("还没有抓到东西，先开抓包再玩一会")
		return
	end
	print("[SaintOri] ===== 抓包记录 =====")
	for _, line in ipairs(spyConsole) do
		print(line)
	end
	toast(("共 %d 条记录，已输出到控制台"):format(#spyConsole))
end)
addButton(pageLearning, "按分类输出", PALETTE.card, function()
	print("[SaintOri] ===== 分类结果 =====")
	for _, category in ipairs(REMOTE_CATEGORIES) do
		local list = remotesFor(category)
		print(("[%s] %d 个"):format(category, #list))
		for _, remote in ipairs(list) do
			print("  " .. remote:GetFullName())
		end
	end
	toast("分类结果已输出到控制台")
end)
addButton(pageLearning, "清空学习记录", PALETTE.card, function()
	RemoteDB.learned = {}
	RemoteDB.byCategory = { money = {}, damage = {}, arrest = {}, hack = {}, spawn = {} }
	spyConsole = {}
	RemoteDB.spyCount = 0
	refreshSpyStatus()
	toast("学习记录已清空")
end)
addButton(pageLearning, "刷新分类状态", PALETTE.card, function()
	refreshSpyStatus()
	toast(guardReport())
end)

addSection(pageLearning, "扫描结果")
addButton(pageLearning, "输出全部远程到控制台", PALETTE.card, function()
	local list = scanRemotes(true)
	print("[SaintOri] 共 " .. #list .. " 个远程对象：")
	for _, remote in ipairs(list) do
		print("  " .. remote:GetFullName() .. "  [" .. remote.ClassName .. "]")
	end
	toast(("共 %d 个远程"):format(#list))
end)
addButton(pageLearning, "统计各分类数量", PALETTE.card, function()
	local parts = {}
	for _, category in ipairs(REMOTE_CATEGORIES) do
		parts[#parts + 1] = ("%s %d"):format(category, #remotesFor(category))
	end
	local text = table.concat(parts, " · ")
	print("[SaintOri] " .. text)
	toast(text)
end)
addInfo(pageLearning, "抓包用的是 hook __namecall，只记录 FireServer / InvokeServer。部分手机执行器没有这个能力，此时只能用静态扫描。")

-- 防护
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
		toast("没有发现名称匹配的客户端反作弊脚本")
	else
		print("[SaintOri] 已禁用 " .. #killed .. " 个脚本：")
		for _, name in ipairs(killed) do
			print("  " .. name)
		end
		toast(("已禁用 %d 个客户端检测脚本"):format(#killed))
	end
end)
addButton(pageGuard, "清理全局痕迹", PALETTE.card, function()
	local removed = cleanTraces()
	toast(("已清理 %d 处全局痕迹"):format(removed))
end)
addButton(pageGuard, "输出防护报告", PALETTE.card, function()
	local report = guardReport()
	print("[SaintOri] " .. report)
	toast(report)
end)
addInfo(pageGuard, "手机端没有 PC 的内核保护，但服务器仍在看位移、速度与远程频率。安全速度 32~45、分步位移、远程节流是最稳的组合。")

-- 设置
local pageSettings = createPage("settings")

addSection(pageSettings, "界面与性能")
addToggle(pageSettings, "低配模式", "降低机器人刷新与扫描频率", "LiteMode")
addButton(pageSettings, "切换界面显示", PALETTE.card, function()
	if canvas.Visible then
		hideWindow()
	else
		showWindow()
	end
end)
addInfo(pageSettings, "左上角悬浮球：单击开合面板，按住拖动位置。")

addSection(pageSettings, "诊断")
local diagLabel = addInfo(pageSettings, "点下方按钮生成诊断报告")
addButton(pageSettings, "运行完整诊断", PALETTE.accent, function()
	local lines = {}

	lines[#lines + 1] = ("执行器：%s"):format(Compat.isTouch and "移动端" or "桌面端")
	lines[#lines + 1] = ("hook：%s"):format(RemoteDB.spyInstalled and "已装" or "未装")
	lines[#lines + 1] = ("移触API：%s"):format(Compat.firetouchinterest and "有" or "无")
	lines[#lines + 1] = ("提示API：%s"):format(Compat.fireproximityprompt and "有" or "无")
	lines[#lines + 1] = ("点击API：%s"):format(Compat.mouse1click and "有" or "无")

	for _, category in ipairs(REMOTE_CATEGORIES) do
		lines[#lines + 1] = ("%s远程：%d"):format(category, #remotesFor(category))
	end

	local enemies = 0
	for _, plr in ipairs(Players:GetPlayers()) do
		if isValidEnemy(plr) then
			enemies = enemies + 1
		end
	end
	lines[#lines + 1] = ("可锁定敌人：%d"):format(enemies)

	local line = table.concat(lines, "  |  ")
	diagLabel.label.Text = line
	print("[SaintOri]  诊断：" .. line)
	toast("诊断已输出到控制台")
end)
addButton(pageSettings, "打印环境信息", PALETTE.card, function()
	print("[SaintOri] PlaceId = " .. tostring(game.PlaceId))
	print("[SaintOri] JobId = " .. tostring(game.JobId))
	print("[SaintOri] 触摸设备 = " .. tostring(Compat.isTouch))
	print("[SaintOri] 视口 = " .. tostring(getCamera().ViewportSize))
	toast("环境信息已输出")
end)

addSection(pageSettings, "恢复与卸载")
addButton(pageSettings, "恢复默认设置", PALETTE.card, function()
	for key, value in pairs(DEFAULT_CONFIG) do
		Config[key] = value
	end
	Guard.Enabled = Config.GuardEnabled
	Guard.MaxWalkSpeed = Config.GuardMaxSpeed
	Guard.SplitTeleport = Config.GuardSplit
	Guard.TeleportStep = Config.GuardStep
	Guard.TeleportDelay = Config.GuardStepDelay
	Guard.ThrottleRemotes = Config.GuardThrottle
	Guard.RemoteCooldown = Config.GuardCooldown
	Guard.RemoteJitter = Config.GuardJitter
	Guard.SafeFly = Config.GuardSafeFly
	Guard.FlyMaxSpeed = Config.GuardFlyMax
	Guard.SmoothFly = Config.GuardSmoothFly

	destroyFly()
	restoreNoclip()
	destroyRobot()
	applySafeWalkSpeed()

	for _, control in pairs(Controls.toggles) do
		pcall(control.paint, false)
	end
	for _, control in pairs(Controls.sliders) do
		pcall(control.sync)
	end

	badgeLabel.Text = "就绪"
	badgeLabel.TextColor3 = PALETTE.green
	toast("已恢复默认设置")
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
		Size = UDim2.fromOffset(92, 34),
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

	local underline = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -3),
		Size = UDim2.new(0, 0, 0, 2),
		BackgroundColor3 = PALETTE.accent,
		BorderSizePixel = 0,
		Parent = button,
	})
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = underline })
	create("UIGradient", {
		Color = ColorSequence.new(PALETTE.accent2, PALETTE.accent),
		Parent = underline,
	})

	local function setActive(active)
		local info = TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
		TweenService:Create(button, info, {
			BackgroundTransparency = active and 0 or 1,
			BackgroundColor3 = PALETTE.card,
		}):Play()
		TweenService:Create(label, info, {
			TextColor3 = active and PALETTE.text or PALETTE.sub,
		}):Play()
		TweenService:Create(underline, info, {
			Size = active and UDim2.new(0.5, 0, 0, 2) or UDim2.new(0, 0, 0, 2),
			BackgroundTransparency = active and 0 or 1,
		}):Play()
	end

	button.MouseButton1Click:Connect(function()
		selectTab(def.id)
	end)

	tabButtons[def.id] = { button = button, setActive = setActive }
end

selectTab("character")

--//═════════════════════════ 窗口显隐动画 ══════════════════════════//--
showWindow = function(animate)
	canvas.Visible = true
	if animate == false then
		canvas.GroupTransparency = 0
		uiScale.Scale = baseScale
		return
	end
	canvas.GroupTransparency = 1
	uiScale.Scale = baseScale * 0.94
	TweenService:Create(canvas, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
		GroupTransparency = 0,
	}):Play()
	TweenService:Create(uiScale, TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Scale = baseScale,
	}):Play()
end

hideWindow = function(animate)
	if animate == false then
		canvas.Visible = false
		return
	end
	local fade = TweenService:Create(canvas, TweenInfo.new(0.16, Enum.EasingStyle.Quad), {
		GroupTransparency = 1,
	})
	fade:Play()
	fade.Completed:Connect(function()
		if canvas.GroupTransparency >= 0.99 then
			canvas.Visible = false
		end
	end)
	TweenService:Create(uiScale, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
		Scale = baseScale * 0.94,
	}):Play()
end

hideBtn.MouseButton1Click:Connect(function()
	hideWindow()
end)

-- 悬浮球
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

local fabScale = create("UIScale", { Scale = 1, Parent = fab })

local fabLabel = create("TextLabel", {
	Text = "圣",
	Font = Enum.Font.GothamBold,
	TextSize = 20,
	TextColor3 = PALETTE.white,
	BackgroundTransparency = 1,
	Size = UDim2.fromScale(1, 1),
	Parent = fab,
})

-- 呼吸动画（缩放整球，不占用布局）
do
	local breath = TweenService:Create(
		fabScale,
		TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ Scale = 1.12 }
	)
	breath:Play()
end

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
			if canvas.Visible then
				hideWindow()
			else
				showWindow()
			end
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
		if canvas.Visible then
			hideWindow()
		else
			showWindow()
		end
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

do
	local cam = getCamera()
	if cam then
		pcall(function()
			cam:GetPropertyChangedSignal("ViewportSize"):Connect(function()
				baseScale = computeScale()
				if canvas.Visible then
					uiScale.Scale = baseScale
				end
			end)
		end)
	end
end

--//═════════════════════════ 调度器 ══════════════════════════//--
local Scheduler = { entries = {} }

local function addTask(name, interval, fn)
	Scheduler.entries[name] = { interval = interval, last = 0, fn = fn }
end

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

addTask("range", 0.05, rangeStep)
addTask("farm", 0.05, farmStep)
addTask("claim", 0.1, claimStep)
addTask("arrest", 0.05, arrestStep)
addTask("hack", 0.05, hackStep)
addTask("interact", 0.1, interactStep)
addTask("spyStatus", 0.5, function()
	if Config.SpyEnabled then
		refreshSpyStatus()
	end
end)

RunService.Heartbeat:Connect(function(dt)
	for _, entry in pairs(Scheduler.entries) do
		if entry.fn then
			entry.last = entry.last + dt
			if entry.last >= entry.interval then
				entry.last = 0
				pcall(entry.fn, dt)
			end
		end
	end
end)

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

-- 顶部渐变条流动动画
do
	local angle = 0
	RunService.Heartbeat:Connect(function(dt)
		if not canvas.Visible or Config.LiteMode then return end
		angle = (angle + dt * 40) % 360
		if ribbonGradient then
			ribbonGradient.Rotation = angle
		end
	end)
end

--//═════════════════════════ 启动 ══════════════════════════//--
task.defer(captureDefaultSpeed)

showWindow(true)
refreshSpyStatus()

task.delay(0.8, function()
	toast(Compat.isTouch and "手机端模式 · 点「圣」开合面板" or "已加载 · RightShift 隐藏", PALETTE.accent)
end)

print("[SaintOri] v4.0 加载完成 | PlaceId = " .. tostring(game.PlaceId))

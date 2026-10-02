--=========== UI 构建 ============
local lib = UILib.new({
    title = "XJ Hub",
    subtitle = "圣奥里",
    size = Vector2.new(640, 460),
    version = "v0.1",
})

local function notify(title, desc, duration)
    pcall(function() lib:notify(title, "accent", desc, duration or 4) end)
end

--=========== 主页 ============
local homeTab = lib:tab("主页", "home")
homeTab:label("XJ Hub — 圣奥里付费版", "accent2")
homeTab:label("当前服务器 ID: " .. tostring(game.PlaceId), "sub")
homeTab:label("开源人：嘉酱  |  移植：XJ Hub", "sub")
--=========== 主要功能 ============
local mainTab = lib:tab("主要功能", "sliders-h")

mainTab:toggle({ name = "无限体力", default = false,
    onChange = function(v) Settings.stamina = v end })
mainTab:toggle({ name = "无限饥饿", default = false,
    onChange = function(v) Settings.food = v end })
mainTab:toggle({ name = "战斗拦截", default = false,
    onChange = function(v) setCombatBlock(v) end })
mainTab:toggle({ name = "隐身", default = false,
    onChange = function(v) setGhost(v) end })
mainTab:toggle({ name = "防布娃娃", default = false,
    onChange = function(v) Settings.noRagdoll = v end })
mainTab:toggle({ name = "防摔伤", default = false,
    onChange = function(v) Settings.noFallDamage = v end })
mainTab:toggle({ name = "防越狱拉回", default = false,
    onChange = function(v) setAntiPrisonPull(v) end })
mainTab:toggle({ name = "自动捡钱", default = false,
    onChange = function(v) Settings.autoMoney = v end })
mainTab:toggle({ name = "无限子弹", default = false,
    onChange = function(v) Settings.infiniteAmmo = v end })
mainTab:toggle({ name = "快速射击", default = false,
    onChange = function(v) Settings.rapidFire = v end })
    --=========== 刷钱 ============
local farmTab = lib:tab("刷钱", "money-bill-wave")

farmTab:toggle({ name = "自动接取任务", default = false,
    onChange = function(v) Settings.autoMission = v end })
farmTab:toggle({ name = "优先高收益任务", default = false,
    onChange = function(v) FarmSettings.priorityHighReward = v end })

farmTab:input({
    name = "接取间隔 (秒)",
    default = "2",
    placeholder = "输入秒数",
    onCommit = function(txt)
        local n = tonumber(txt)
        if n and n > 0 then FarmSettings.missionInterval = n end
    end,
})

farmTab:toggle({ name = "安全模式 (出租车)", default = false,
    onChange = function(v)
        FarmSettings.taxiSafe = v
        if v then
            local _, _, hrp = getCharacter(localPlayer)
            if hrp then FarmSettings.taxiOrigin = hrp.Position end
        end
    end })

farmTab:dropdown({
    name = "出租车延迟模式",
    options = { "随机时间", "距离测算" },
    default = 1,
    onChange = function(_, val) FarmSettings.taxiDelayMode = val end,
})

farmTab:toggle({ name = "出租车刷钱", default = false,
    onChange = function(v) Settings.taxi = v end })
farmTab:toggle({ name = "公交车刷钱", default = false,
    onChange = function(v) Settings.bus = v end })
farmTab:toggle({ name = "农民刷钱", default = false,
    onChange = function(v) Settings.farmer = v end })
farmTab:toggle({ name = "自动黑客小游戏", default = false,
    onChange = function(v) setAutoHack(v) end })
farmTab:toggle({ name = "高尔夫刷钱", default = false,
    onChange = function(v) Settings.golf = v end })
    --=========== 战斗 ============
local combatTab = lib:tab("战斗", "crosshairs")

combatTab:toggle({ name = "杀戮光环", default = false,
    onChange = function(v) AuraSettings.enabled = v end })
combatTab:toggle({ name = "只攻击警察", default = false,
    onChange = function(v)
        AuraSettings.onlyPolice = v
        if v then AuraSettings.onlyCivilian = false end
    end })
combatTab:toggle({ name = "只攻击平民", default = false,
    onChange = function(v)
        AuraSettings.onlyCivilian = v
        if v then AuraSettings.onlyPolice = false end
    end })
combatTab:toggle({ name = "战斗检测", default = false,
    onChange = function(v) AuraSettings.combatCheck = v end })

combatTab:slider({ name = "攻击范围", min = 10, max = 500, default = 50,
    onChange = function(v) AuraSettings.range = v end })
combatTab:slider({ name = "伤害倍率", min = 1, max = 100, default = 5,
    onChange = function(v) AuraSettings.damage = v end })

--=========== 自瞄 ============
local aimTab = lib:tab("自瞄", "crosshairs")

aimTab:toggle({ name = "开启自瞄", default = false,
    onChange = function(v) AimbotSettings.enabled = v end })
aimTab:toggle({ name = "显示 FOV 圈", default = false,
    onChange = function(v) AimbotSettings.showFov = v end })
aimTab:toggle({ name = "显示准心", default = false,
    onChange = function(v) AimbotSettings.showCrosshair = v end })
aimTab:toggle({ name = "显示追踪线", default = false,
    onChange = function(v) AimbotSettings.showTracer = v end })
aimTab:toggle({ name = "队伍检测", default = false,
    onChange = function(v) AimbotSettings.teamCheck = v end })
aimTab:toggle({ name = "好友检测", default = false,
    onChange = function(v) AimbotSettings.friendCheck = v end })
aimTab:toggle({ name = "墙壁检测", default = false,
    onChange = function(v) AimbotSettings.wallCheck = v end })
aimTab:toggle({ name = "预判自瞄", default = false,
    onChange = function(v) AimbotSettings.prediction = v end })
aimTab:toggle({ name = "只自瞄警察", default = false,
    onChange = function(v)
        AimbotSettings.onlyPolice = v
        if v then AimbotSettings.onlyCivilian = false end
    end })
aimTab:toggle({ name = "只自瞄平民", default = false,
    onChange = function(v)
        AimbotSettings.onlyCivilian = v
        if v then AimbotSettings.onlyPolice = false end
    end })
aimTab:toggle({ name = "战斗检测", default = false,
    onChange = function(v) AimbotSettings.combatCheck = v end })

aimTab:dropdown({
    name = "优先锁定模式",
    options = { "准心最近", "距离最近", "血量最低" },
    default = 1,
    onChange = function(_, val) AimbotSettings.targetMode = val end,
})
aimTab:dropdown({
    name = "瞄准部位",
    options = { "头", "胸", "左手", "右手", "左腿", "右腿" },
    default = 1,
    onChange = function(_, val) AimbotSettings.targetPart = val end,
})
aimTab:dropdown({
    name = "颜色选择",
    options = { "红色", "黄色", "绿色", "蓝色", "紫色", "白色", "黑色", "彩虹色" },
    default = 1,
    onChange = function(_, val) AimbotSettings.color = val end,
})

aimTab:slider({ name = "FOV 圈大小", min = 1, max = 500, default = 50,
    onChange = function(v) AimbotSettings.fov = v end })
aimTab:slider({ name = "自瞄平滑度", min = 1, max = 10, default = 10,
    onChange = function(v) AimbotSettings.smoothness = v / 10 end })
aimTab:slider({ name = "FOV 圈厚度", min = 1, max = 5, default = 2,
    onChange = function(v) AimbotSettings.fovThickness = v end })
    --=========== Ragebot ============
local rageTab = lib:tab("Ragebot", "bot")

rageTab:toggle({ name = "Ragebot", default = false,
    onChange = function(v) RageSettings.enabled = v end })
rageTab:toggle({ name = "职业检测", default = false,
    onChange = function(v) RageSettings.jobCheck = v end })
rageTab:toggle({ name = "墙壁检测", default = false,
    onChange = function(v) RageSettings.wallCheck = v end })
rageTab:toggle({ name = "活体检测", default = false,
    onChange = function(v) RageSettings.aliveCheck = v end })
rageTab:toggle({ name = "战斗状态检测", default = false,
    onChange = function(v) RageSettings.combatCheck = v end })
rageTab:toggle({ name = "锁定警察", default = false,
    onChange = function(v)
        RageSettings.policeLock = v
        if v then RageSettings.civilianLock = false end
    end })
rageTab:toggle({ name = "锁定平民", default = false,
    onChange = function(v)
        RageSettings.civilianLock = v
        if v then RageSettings.policeLock = false end
    end })
rageTab:toggle({ name = "弹道显示", default = false,
    onChange = function(v) RageSettings.beam = v end })

rageTab:dropdown({
    name = "攻击部位",
    options = { "头部", "躯干", "左臂", "右臂", "左腿", "右腿" },
    default = 1,
    onChange = function(_, val) RageSettings.bodyPart = rageBodyMap[val] or "Head" end,
})

rageTab:slider({ name = "攻击距离", min = 10, max = 500, default = 150,
    onChange = function(v) RageSettings.range = v end })
rageTab:slider({ name = "攻击间隔", min = 0.01, max = 1, default = 0.05,
    format = function(v) return string.format("%.2f", v) end,
    onChange = function(v) RageSettings.interval = v end })

--=========== 范围 Hitbox ============
local hbTab = lib:tab("范围", "bullseye")

hbTab:toggle({ name = "开启范围", default = false,
    onChange = function(v)
        HitboxSettings.active = v
        if not v then
            for _, p in ipairs(Players:GetPlayers()) do
                if p.Character then restoreHitbox(p.Character) end
            end
        end
    end })
hbTab:toggle({ name = "NPC 范围", default = false,
    onChange = function(v) HitboxSettings.affectNPC = v end })
hbTab:toggle({ name = "队伍检测", default = false,
    onChange = function(v) HitboxSettings.teamCheck = v end })
hbTab:toggle({ name = "活体检测", default = false,
    onChange = function(v) HitboxSettings.checkCorpses = v end })
hbTab:toggle({ name = "显示轮廓", default = false,
    onChange = function(v) HitboxSettings.outline = v end })
hbTab:toggle({ name = "启用碰撞", default = false,
    onChange = function(v) HitboxSettings.collision = v end })
hbTab:toggle({ name = "发光效果", default = false,
    onChange = function(v) HitboxSettings.glow = v end })
hbTab:toggle({ name = "脉动效果", default = false,
    onChange = function(v) HitboxSettings.pulse = v end })

hbTab:dropdown({
    name = "范围颜色",
    options = { "红色", "蓝色", "黄色", "绿色", "青色", "橙色", "紫色", "白色", "黑色", "彩虹色" },
    default = 1,
    onChange = function(_, val)
        HitboxSettings.color = val
        HitboxSettings.rainbow = val == "彩虹色"
    end,
})
hbTab:dropdown({
    name = "范围材质",
    options = { "Neon", "Plastic", "Wood", "Slate", "Concrete", "Metal", "SmoothPlastic" },
    default = 1,
    onChange = function(_, val) HitboxSettings.material = val end,
})

hbTab:input({
    name = "范围大小",
    default = "10",
    onCommit = function(txt)
        local n = tonumber(txt)
        if n and n > 0 then HitboxSettings.size = n end
    end,
})
hbTab:input({
    name = "透明度 (0-1)",
    default = "0.7",
    onCommit = function(txt)
        local n = tonumber(txt)
        if n and n >= 0 and n <= 1 then HitboxSettings.transparency = n end
    end,
})
--=========== 玩家 ============
local playerTab = lib:tab("玩家", "user")

playerTab:toggle({ name = "启用跳跃修改", default = false,
    onChange = function(v)
        PlayerSettings.jumpEnabled = v
        if v then startJump() else stopJump() end
    end })
playerTab:toggle({ name = "无限跳跃", default = false,
    onChange = function(v) PlayerSettings.infiniteJump = v end })
playerTab:toggle({ name = "飞行", default = false,
    onChange = function(v)
        PlayerSettings.flyEnabled = v
        if v then startFly() else stopFly() end
    end })
playerTab:toggle({ name = "穿墙 (Noclip)", default = false,
    onChange = function(v)
        PlayerSettings.noclip = v
        if v then startNoclip() else stopNoclip() end
    end })
playerTab:toggle({ name = "修改行走速度", default = false,
    onChange = function(v)
        PlayerSettings.walkEnabled = v
        if v then startWalk() else stopWalk() end
    end })

playerTab:slider({ name = "行走速度", min = 16, max = 500, default = 200,
    onChange = function(v) PlayerSettings.walkSpeed = v end })
playerTab:slider({ name = "跳跃高度", min = 50, max = 400, default = 50,
    onChange = function(v) PlayerSettings.jumpPower = v end })
playerTab:slider({ name = "跳跃倍数", min = 1, max = 10, default = 1,
    onChange = function(v) PlayerSettings.jumpMultiplier = v end })
playerTab:slider({ name = "飞行速度", min = 10, max = 300, default = 30,
    onChange = function(v) PlayerSettings.flySpeed = v end })

playerTab:dropdown({
    name = "飞行模式",
    options = { "传送", "物理" },
    default = 1,
    onChange = function(_, val)
        PlayerSettings.flyMode = val
        if PlayerSettings.flyEnabled then
            PlayerSettings.flyEnabled = false
            task.wait(0.1)
            PlayerSettings.flyEnabled = true
            startFly()
        end
    end,
})

--=========== 警察功能 ============
local policeTab = lib:tab("警察功能", "handcuffs")

policeTab:toggle({ name = "自动铐", default = false,
    onChange = function(v)
        Settings.autoCuff = v
        if v then initAutoCuff() end
    end })
policeTab:toggle({ name = "自动传送", default = false,
    onChange = function(v) PoliceSettings.teleport = v end })
policeTab:toggle({ name = "战斗检测", default = false,
    onChange = function(v) PoliceSettings.combatCheck = v end })

policeTab:slider({ name = "范围", min = 10, max = 500, default = 200,
    onChange = function(v) PoliceSettings.range = v end })
policeTab:slider({ name = "间隔", min = 0.1, max = 3, default = 0.5,
    format = function(v) return string.format("%.1f", v) end,
    onChange = function(v) PoliceSettings.delay = v end })
    --=========== ESP ============
local espTab = lib:tab("ESP", "eye")

espTab:toggle({ name = "ESP 总开关", default = false,
    onChange = function(v)
        EspSettings.enabled = v and true or false
        if not EspSettings.enabled then
            for p in pairs(EspSettings.trackers) do removeTracker(p) end
        else
            pcall(refreshEsp)
        end
    end })
espTab:toggle({ name = "显示名字", default = true,
    onChange = function(v) EspSettings.name = v end })
espTab:toggle({ name = "显示距离", default = true,
    onChange = function(v) EspSettings.distance = v end })
espTab:toggle({ name = "显示血量", default = true,
    onChange = function(v) EspSettings.health = v end })
espTab:toggle({ name = "显示高亮", default = true,
    onChange = function(v) EspSettings.highlight = v end })
espTab:toggle({ name = "显示追踪线", default = false,
    onChange = function(v) EspSettings.tracer = v end })

espTab:dropdown({
    name = "追踪线起点",
    options = { "屏幕底部", "屏幕中心", "屏幕顶部" },
    default = 1,
    onChange = function(_, val) EspSettings.tracerOrigin = val end,
})

espTab:section("队伍筛选")

local espTeams = {
    { key = "Police",    label = "警察" },
    { key = "Civilian",  label = "平民" },
    { key = "Farmer",    label = "农民" },
    { key = "Chef",      label = "厨师" },
    { key = "Delivery",  label = "配送员" },
    { key = "Fire",      label = "消防员" },
    { key = "Medical",   label = "医护人员" },
    { key = "Prisoner",  label = "囚犯" },
    { key = "Transit",   label = "交通" },
    { key = "Road Service", label = "道路服务" },
}
for _, t in ipairs(espTeams) do
    espTab:toggle({
        name = t.label,
        default = true,
        onChange = function(v) EspSettings.selectedTeams[t.key] = v end,
    })
end
espTab:toggle({ name = "显示逃犯", default = true,
    onChange = function(v) EspSettings.showFugitive = v end })

--=========== 启动后台逻辑 ============
initHeartbeat()
initAutoMoney()
initAutoMission()
initFarmer()
initTaxi()
initBus()
initGolf()
initAura()
initAimbotRender()
initRagebot()
initHitbox()
initEsp()

notify("XJ Hub 已加载", "所有功能已就绪", 4)

_G.XJHub = {
    Settings = Settings, FarmSettings = FarmSettings, AuraSettings = AuraSettings,
    AimbotSettings = AimbotSettings, RageSettings = RageSettings, HitboxSettings = HitboxSettings,
    PlayerSettings = PlayerSettings, PoliceSettings = PoliceSettings, EspSettings = EspSettings,
    lib = lib,
}

return _G.XJHub
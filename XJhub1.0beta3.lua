-- ============================================================
-- XJ Hub 1.0 beta · 卡密验证完整整合版
-- 作者: 嘉酱 · 卡密模块: 卡密通 MD5 协议
-- ============================================================

local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local RunSvc  = game:GetService("RunService")
local UIS     = game:GetService("UserInputService")
local Tween   = game:GetService("TweenService")
local WS      = game:GetService("Workspace")
local LP      = Players.LocalPlayer

-- ============================================================
-- 【0】卡密验证 · 卡密通 MD5 协议
-- ============================================================
-- ⚠️ 唯一需要修改的地方 ↓↓↓
local CFG = {
    USER_ID     = "jiajiangovo0829",
    APP_NAME    = "a",
    SIGN_KEY    = "3d881bede8893291935c0e61fc3ad633",   -- ⚠️ 必须改！从卡密通后台复制
    
    API_BASE    = "https://www.keyt.cn/kami/jiajiangovo0829/check.php",
    TS_DIFF     = 120,
    HB_INIT     = 55,
    HB_GAP      = 50,
    HB_FAIL     = 5,
    LOAD_TIMEOUT = 12,
}

local function ok(m)  print("[XJ] ✅ " .. m) end
local function no(m)  print("[XJ] ❌ " .. m) end
local function inf(m) print("[XJ] ℹ️ " .. m) end
inf("XJ Hub 开始加载")

-- ========== HTTP ==========
local HttpReq = (syn and syn.request) or (http and http.request)
    or http_request or request or (fluxus and fluxus.request)
if not HttpReq then
    warn("[XJ] ❌ 当前执行器不支持 HTTP 请求")
    return
end
local HS = game:GetService("HttpService")

-- ========== MD5（bit32 实现） ==========
local md5 = (function()
    local K = {
        0xd76aa478,0xe8c7b756,0x242070db,0xc1bdceee,
        0xf57c0faf,0x4787c62a,0xa8304613,0xfd469501,
        0x698098d8,0x8b44f7af,0xffff5bb1,0x895cd7be,
        0x6b901122,0xfd987193,0xa679438e,0x49b40821,
        0xf61e2562,0xc040b340,0x265e5a51,0xe9b6c7aa,
        0xd62f105d,0x02441453,0xd8a1e681,0xe7d3fbc8,
        0x21e1cde6,0xc33707d6,0xf4d50d87,0x455a14ed,
        0xa9e3e905,0xfcefa3f8,0x676f02d9,0x8d2a4c8a,
        0xfffa3942,0x8771f681,0x6d9d6122,0xfde5380c,
        0xa4beea44,0x4bdecfa9,0xf6bb4b60,0xbebfbc70,
        0x289b7ec6,0xeaa127fa,0xd4ef3085,0x04881d05,
        0xd9d4d039,0xe6db99e5,0x1fa27cf8,0xc4ac5665,
        0xf4292244,0x432aff97,0xab9423a7,0xfc93a039,
        0x655b59c3,0x8f0ccc92,0xffeff47d,0x85845dd1,
        0x6fa87e4f,0xfe2ce6e0,0xa3014314,0x4e0811a1,
        0xf7537e82,0xbd3af235,0x2ad7d2bb,0xeb86d391,
    }
    local S = {
        7,12,17,22, 7,12,17,22, 7,12,17,22, 7,12,17,22,
        5, 9,14,20, 5, 9,14,20, 5, 9,14,20, 5, 9,14,20,
        4,11,16,23, 4,11,16,23, 4,11,16,23, 4,11,16,23,
        6,10,15,21, 6,10,15,21, 6,10,15,21, 6,10,15,21,
    }
    local bnot, band, bor, bxor, lrot =
        bit32.bnot, bit32.band, bit32.bor, bit32.bxor, bit32.lrotate
    local MOD = 4294967296

    return function(msg)
        local a0, b0, c0, d0 = 0x67452301, 0xefcdab89, 0x98badcfe, 0x10325476
        local ml = #msg
        msg = msg .. "\128" .. string.rep("\0", (55 - ml) % 64)
        local bits = ml * 8
        for _ = 1, 8 do
            msg = msg .. string.char(bits % 256)
            bits = math.floor(bits / 256)
        end
        for chunk = 0, #msg - 1, 64 do
            local M = {}
            for i = 0, 15 do
                local o = chunk + i * 4
                M[i] = msg:byte(o+1) + msg:byte(o+2)*256
                     + msg:byte(o+3)*65536 + msg:byte(o+4)*16777216
            end
            local A, B, C, D = a0, b0, c0, d0
            for i = 0, 63 do
                local F, g
                if i < 16 then
                    F = bor(band(B, C), band(bnot(B), D)); g = i
                elseif i < 32 then
                    F = bor(band(D, B), band(bnot(D), C)); g = (5*i+1) % 16
                elseif i < 48 then
                    F = bxor(bxor(B, C), D); g = (3*i+5) % 16
                else
                    F = bxor(C, bor(B, bnot(D))); g = (7*i) % 16
                end
                F = (F + A + K[i+1] + M[g]) % MOD
                A, D, C = D, C, B
                B = (B + lrot(F, S[i+1])) % MOD
            end
            a0 = (a0 + A) % MOD
            b0 = (b0 + B) % MOD
            c0 = (c0 + C) % MOD
            d0 = (d0 + D) % MOD
        end
        local out = ""
        for _, x in ipairs({a0, b0, c0, d0}) do
            out = out .. string.char(
                x % 256,
                math.floor(x / 256) % 256,
                math.floor(x / 65536) % 256,
                math.floor(x / 16777216) % 256
            )
        end
        return (out:gsub(".", function(c) return string.format("%02x", c:byte()) end))
    end
end)()

-- ========== 机器码 ==========
local function getMachineCode()
    local FILE = "xjhub_machine.txt"
    if isfile and readfile then
        local ok1, exists = pcall(isfile, FILE)
        if ok1 and exists then
            local ok2, s = pcall(readfile, FILE)
            if ok2 and type(s) == "string" and #s > 0 and #s < 128 then
                return s
            end
        end
    end
    local mac = tostring(LP.UserId) .. "-" .. tostring(math.random(100000, 999999)) .. "MAC"
    if writefile then pcall(writefile, FILE, mac) end
    return mac
end
local MACHINE_CODE = getMachineCode()

-- ========== 请求 ==========
local function httpGet(url)
    local ok1, res = pcall(function()
        return HttpReq({
            Url = url,
            Method = "GET",
            Headers = {
                ["User-Agent"]    = "Mozilla/5.0 (Linux; Android 10)",
                ["Cache-Control"] = "no-cache",
            },
        })
    end)
    if ok1 and res and res.Body then return res.Body end
    return nil
end

-- ========== 验签 ==========
local function verifyResponse(raw)
    if not raw or raw == "" then return nil, "空响应" end
    local signIdx = raw:find("|sign=", 1, true)
    if not signIdx then return nil, "未找到签名" end
    local body = raw:sub(1, signIdx - 1)
    local sign = raw:sub(signIdx + 6):match("^[0-9a-fA-F]+") or ""
    local localSign = md5(body .. CFG.SIGN_KEY)
    if localSign ~= sign then return nil, "签名校验失败" end
    local lastPipe = body:reverse():find("|", 1, true)
    if not lastPipe then return nil, "未找到时间戳" end
    local tsPos = #body - lastPipe + 1
    local tsStr = body:sub(tsPos + 1)
    local serverTs = tonumber(tsStr)
    if not serverTs then return nil, "时间戳格式错误" end
    local diff = math.abs(os.time() - serverTs)
    if diff > CFG.TS_DIFF then return nil, "时间戳过期 (" .. diff .. "s)" end
    return body:sub(1, tsPos - 1)
end

-- ========== 业务 API ==========
local function apiGetSwitch()
    for _ = 1, 3 do
        local url = CFG.API_BASE .. "?act=get_switch&app=" .. CFG.APP_NAME .. "&t=" .. os.time()
        local body = httpGet(url)
        if body then
            local biz = verifyResponse(body)
            if biz then
                if biz:find("CARD_ON", 1, true)  then return "CARD_ON"  end
                if biz:find("CARD_OFF", 1, true) then return "CARD_OFF" end
            end
        end
        task.wait(0.5)
    end
    return "CARD_ON"
end

local function apiGetNotice()
    local url = CFG.API_BASE .. "?act=get_notice&app=" .. CFG.APP_NAME .. "&_t=" .. os.time()
    local body = httpGet(url)
    if body and #body > 0 then
        local biz = verifyResponse(body)
        return (biz or body):sub(1, 400)
    end
    return nil
end

local function apiVerify(card)
    local url = CFG.API_BASE .. "?card=" .. HS:UrlEncode(card)
        .. "&mac=" .. HS:UrlEncode(MACHINE_CODE)
        .. "&app=" .. HS:UrlEncode(CFG.APP_NAME)
        .. "&heart=1&t=" .. os.time()
    local body = httpGet(url)
    if not body then return { success = false, message = "网络请求失败" } end
    local biz, err = verifyResponse(body)
    if not biz then return { success = false, message = err or "验签失败" } end
    if biz:sub(1, 3) == "ok|" or biz:find("bypass", 1, true) then
        return { success = true, message = "验证成功", biz = biz, card = card }
    end
    if biz:find("error|", 1, true) then
        local code = biz:match("error|([^|]+)") or ""
        local map = {
            invalid_card         = "卡密无效",
            expired              = "卡密已过期",
            banned               = "卡密已被禁用",
            already_online       = "卡密已在线",
            device_mismatch      = "设备不匹配",
            online_limit_reached = "在线设备数已满",
            too_frequent         = "验证过于频繁",
            system_locked        = "系统已被锁死",
        }
        return { success = false, message = map[code] or code }
    end
    return { success = false, message = biz }
end

local function parseRemaining(biz)
    if not biz then return nil end
    local parts = {}
    for p in biz:gmatch("[^|]+") do parts[#parts + 1] = p end
    if parts[2] == "permanent" or parts[3] == "permanent" then return "永久有效" end
    local d = tonumber(parts[3]) or 0
    local m = tonumber(parts[4]) or 0
    if d > 0 then return "剩余 " .. d .. " 天" .. (m > 0 and (" " .. m .. " 分钟") or "")
    elseif m > 0 then return "剩余 " .. m .. " 分钟" end
    return nil
end

-- ========== 心跳 ==========
local function startHeartbeat(card, onFail)
    task.spawn(function()
        task.wait(CFG.HB_INIT)
        local fails = 0
        while true do
            local r = apiVerify(card)
            if r.success then fails = 0
            else
                fails = fails + 1
                if fails >= CFG.HB_FAIL then
                    if onFail then pcall(onFail, r.message) end
                    return
                end
            end
            task.wait(CFG.HB_GAP)
        end
    end)
end

-- ============================================================
-- 验证 UI
-- ============================================================
local uiParent = (gethui and gethui()) or game:GetService("CoreGui")
local oldLogin = uiParent:FindFirstChild("XJHubLoginUI")
if oldLogin then oldLogin:Destroy() end

local loginGui = Instance.new("ScreenGui")
loginGui.Name = "XJHubLoginUI"
loginGui.ResetOnSpawn = false
loginGui.IgnoreGuiInset = true
loginGui.DisplayOrder = 9999
loginGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
loginGui.Parent = uiParent

local cam0 = WS.CurrentCamera
local vp0 = cam0 and cam0.ViewportSize or Vector2.new(1920, 1080)
local isTouch0 = UIS.TouchEnabled and not UIS.MouseEnabled
local uiScale0 = 1
if isTouch0 or vp0.X < 800 then
    uiScale0 = math.clamp(math.min((vp0.X - 40) / 400, (vp0.Y - 80) / 460), 0.65, 1)
end

local frame = Instance.new("Frame", loginGui)
frame.Name = "LoginFrame"
frame.Size = UDim2.new(0, 400, 0, 460)
frame.Position = UDim2.new(0.5, -200 * uiScale0, 0.5, -230 * uiScale0)
frame.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
frame.BorderSizePixel = 0
frame.Active = true
frame.ClipsDescendants = true
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 14)
Instance.new("UIScale", frame).Scale = uiScale0

local bgGrad = Instance.new("UIGradient", frame)
bgGrad.Rotation = 135
bgGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(28, 20, 45)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(18, 18, 26)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(24, 16, 38)),
})

local frStroke = Instance.new("UIStroke", frame)
frStroke.Color = Color3.fromRGB(168, 85, 247)
frStroke.Thickness = 1.5

-- 拖动条
local titleBar = Instance.new("Frame", frame)
titleBar.Size = UDim2.new(1, 0, 0, 36)
titleBar.BackgroundTransparency = 1
titleBar.ZIndex = 5
titleBar.Active = true

local dragging, dragStart, startPos = false, nil, nil
titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true; dragStart = input.Position; startPos = frame.Position
    end
end)
UIS.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
        local d = input.Position - dragStart
        local vp2 = WS.CurrentCamera.ViewportSize
        local nx = math.clamp(startPos.X.Offset + d.X, -frame.AbsoluteSize.X + 60, vp2.X - 60)
        local ny = math.clamp(startPos.Y.Offset + d.Y, 0, vp2.Y - 40)
        frame.Position = UDim2.new(0, nx, 0, ny)
    end
end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- 加载界面
local loading = Instance.new("Frame", frame)
loading.Size = UDim2.new(1, 0, 1, 0)
loading.BackgroundTransparency = 1

local lIcon = Instance.new("TextLabel", loading)
lIcon.Size = UDim2.new(1, 0, 0, 64)
lIcon.Position = UDim2.new(0, 0, 0, 100)
lIcon.BackgroundTransparency = 1
lIcon.Text = "🔐"
lIcon.TextSize = 52
lIcon.Font = Enum.Font.GothamBold

local lTitle = Instance.new("TextLabel", loading)
lTitle.Size = UDim2.new(1, 0, 0, 26)
lTitle.Position = UDim2.new(0, 0, 0, 176)
lTitle.BackgroundTransparency = 1
lTitle.Text = "XJ Hub · 卡密验证"
lTitle.TextColor3 = Color3.fromRGB(168, 85, 247)
lTitle.TextSize = 20
lTitle.Font = Enum.Font.GothamBold

local lStatus = Instance.new("TextLabel", loading)
lStatus.Size = UDim2.new(1, -40, 0, 16)
lStatus.Position = UDim2.new(0, 20, 0, 226)
lStatus.BackgroundTransparency = 1
lStatus.Text = "🌐 正在连接服务器..."
lStatus.TextColor3 = Color3.fromRGB(160, 160, 180)
lStatus.TextSize = 12
lStatus.Font = Enum.Font.Gotham

local lBarBg = Instance.new("Frame", loading)
lBarBg.Size = UDim2.new(0, 280, 0, 6)
lBarBg.Position = UDim2.new(0.5, -140, 0, 270)
lBarBg.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
lBarBg.BorderSizePixel = 0
Instance.new("UICorner", lBarBg).CornerRadius = UDim.new(1, 0)

local lBarFill = Instance.new("Frame", lBarBg)
lBarFill.Size = UDim2.new(0, 0, 1, 0)
lBarFill.BackgroundColor3 = Color3.fromRGB(168, 85, 247)
lBarFill.BorderSizePixel = 0
Instance.new("UICorner", lBarFill).CornerRadius = UDim.new(1, 0)

local function setProgress(p)
    Tween:Create(lBarFill, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(p, 0, 1, 0),
    }):Play()
end
setProgress(0.3)

-- 主界面
local mainUI = Instance.new("Frame", frame)
mainUI.Size = UDim2.new(1, 0, 1, 0)
mainUI.BackgroundTransparency = 1
mainUI.Visible = false

local mHeader = Instance.new("Frame", mainUI)
mHeader.Size = UDim2.new(1, 0, 0, 44)
mHeader.BackgroundTransparency = 1

local mTitle = Instance.new("TextLabel", mHeader)
mTitle.Size = UDim2.new(1, -60, 1, 0)
mTitle.Position = UDim2.new(0, 20, 0, 0)
mTitle.BackgroundTransparency = 1
mTitle.Text = "🔐 软件验证"
mTitle.TextColor3 = Color3.fromRGB(220, 200, 255)
mTitle.TextSize = 17
mTitle.Font = Enum.Font.GothamBold
mTitle.TextXAlignment = Enum.TextXAlignment.Left

local closeBtn = Instance.new("TextButton", mHeader)
closeBtn.Size = UDim2.new(0, 28, 0, 28)
closeBtn.Position = UDim2.new(1, -38, 0.5, -14)
closeBtn.BackgroundColor3 = Color3.fromRGB(60, 30, 40)
closeBtn.Text = "×"
closeBtn.TextColor3 = Color3.fromRGB(255, 180, 180)
closeBtn.TextSize = 18
closeBtn.Font = Enum.Font.GothamBold
closeBtn.BorderSizePixel = 0
closeBtn.AutoButtonColor = false
closeBtn.ZIndex = 6
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)

-- 公告框
local noticeFrame = Instance.new("Frame", mainUI)
noticeFrame.Size = UDim2.new(1, -40, 0, 96)
noticeFrame.Position = UDim2.new(0, 20, 0, 50)
noticeFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 36)
noticeFrame.BorderSizePixel = 0
Instance.new("UICorner", noticeFrame).CornerRadius = UDim.new(0, 8)
local ntStroke = Instance.new("UIStroke", noticeFrame)
ntStroke.Color = Color3.fromRGB(60, 80, 130)
ntStroke.Transparency = 0.5
ntStroke.Thickness = 1

local ntTitle = Instance.new("TextLabel", noticeFrame)
ntTitle.Size = UDim2.new(1, -20, 0, 18)
ntTitle.Position = UDim2.new(0, 10, 0, 6)
ntTitle.BackgroundTransparency = 1
ntTitle.Text = "📢 系统公告"
ntTitle.TextColor3 = Color3.fromRGB(150, 200, 255)
ntTitle.TextSize = 11
ntTitle.Font = Enum.Font.GothamBold
ntTitle.TextXAlignment = Enum.TextXAlignment.Left

local ntDivider = Instance.new("Frame", noticeFrame)
ntDivider.Size = UDim2.new(1, -20, 0, 1)
ntDivider.Position = UDim2.new(0, 10, 0, 26)
ntDivider.BackgroundColor3 = Color3.fromRGB(50, 60, 90)
ntDivider.BorderSizePixel = 0
ntDivider.BackgroundTransparency = 0.5

local ntBody = Instance.new("TextLabel", noticeFrame)
ntBody.Size = UDim2.new(1, -20, 1, -36)
ntBody.Position = UDim2.new(0, 10, 0, 32)
ntBody.BackgroundTransparency = 1
ntBody.Text = "请输入卡密进行验证"
ntBody.TextColor3 = Color3.fromRGB(200, 200, 210)
ntBody.TextSize = 10
ntBody.Font = Enum.Font.Gotham
ntBody.TextWrapped = true
ntBody.TextXAlignment = Enum.TextXAlignment.Left
ntBody.TextYAlignment = Enum.TextYAlignment.Top

-- 剩余时间
local timeFrame = Instance.new("Frame", mainUI)
timeFrame.Size = UDim2.new(1, -40, 0, 28)
timeFrame.Position = UDim2.new(0, 20, 0, 154)
timeFrame.BackgroundColor3 = Color3.fromRGB(28, 60, 40)
timeFrame.BorderSizePixel = 0
timeFrame.Visible = false
Instance.new("UICorner", timeFrame).CornerRadius = UDim.new(0, 7)
local timeStroke = Instance.new("UIStroke", timeFrame)
timeStroke.Color = Color3.fromRGB(80, 220, 130)
timeStroke.Transparency = 0.6
timeStroke.Thickness = 1

local timeLbl = Instance.new("TextLabel", timeFrame)
timeLbl.Size = UDim2.new(1, -20, 1, 0)
timeLbl.Position = UDim2.new(0, 10, 0, 0)
timeLbl.BackgroundTransparency = 1
timeLbl.TextColor3 = Color3.fromRGB(130, 235, 160)
timeLbl.TextSize = 12
timeLbl.Font = Enum.Font.GothamBold
timeLbl.TextXAlignment = Enum.TextXAlignment.Left

-- 输入
local inputLbl = Instance.new("TextLabel", mainUI)
inputLbl.Size = UDim2.new(1, -40, 0, 16)
inputLbl.Position = UDim2.new(0, 20, 0, 192)
inputLbl.BackgroundTransparency = 1
inputLbl.Text = "🔑 请输入卡密"
inputLbl.TextColor3 = Color3.fromRGB(200, 200, 210)
inputLbl.TextSize = 12
inputLbl.Font = Enum.Font.GothamBold
inputLbl.TextXAlignment = Enum.TextXAlignment.Left

local inputBox = Instance.new("TextBox", mainUI)
inputBox.Size = UDim2.new(1, -40, 0, 42)
inputBox.Position = UDim2.new(0, 20, 0, 212)
inputBox.BackgroundColor3 = Color3.fromRGB(28, 28, 40)
inputBox.BorderSizePixel = 0
inputBox.Text = ""
inputBox.PlaceholderText = "输入或粘贴卡密"
inputBox.TextColor3 = Color3.new(1, 1, 1)
inputBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 145)
inputBox.Font = Enum.Font.GothamMedium
inputBox.TextSize = 13
inputBox.ClearTextOnFocus = false
inputBox.TextXAlignment = Enum.TextXAlignment.Left
Instance.new("UICorner", inputBox).CornerRadius = UDim.new(0, 8)
local inputStroke = Instance.new("UIStroke", inputBox)
inputStroke.Color = Color3.fromRGB(70, 70, 90)
inputStroke.Thickness = 1

-- 按钮
local verifyBtn = Instance.new("TextButton", mainUI)
verifyBtn.Size = UDim2.new(1, -40, 0, 44)
verifyBtn.Position = UDim2.new(0, 20, 0, 268)
verifyBtn.BackgroundColor3 = Color3.fromRGB(168, 85, 247)
verifyBtn.Text = "🔑 验证卡密"
verifyBtn.TextColor3 = Color3.new(1, 1, 1)
verifyBtn.Font = Enum.Font.GothamBold
verifyBtn.TextSize = 14
verifyBtn.BorderSizePixel = 0
verifyBtn.AutoButtonColor = false
Instance.new("UICorner", verifyBtn).CornerRadius = UDim.new(0, 8)

local statusLbl = Instance.new("TextLabel", mainUI)
statusLbl.Size = UDim2.new(1, -40, 0, 16)
statusLbl.Position = UDim2.new(0, 20, 0, 322)
statusLbl.BackgroundTransparency = 1
statusLbl.Text = "准备就绪"
statusLbl.TextColor3 = Color3.fromRGB(160, 160, 180)
statusLbl.TextSize = 10
statusLbl.Font = Enum.Font.Gotham
statusLbl.TextWrapped = true

local devLbl = Instance.new("TextLabel", mainUI)
devLbl.Size = UDim2.new(1, -40, 0, 14)
devLbl.Position = UDim2.new(0, 20, 0, 348)
devLbl.BackgroundTransparency = 1
devLbl.Text = "设备码: " .. MACHINE_CODE:sub(1, 30)
devLbl.TextColor3 = Color3.fromRGB(110, 110, 130)
devLbl.TextSize = 9
devLbl.Font = Enum.Font.Gotham
devLbl.TextXAlignment = Enum.TextXAlignment.Left

-- ========== 验证逻辑 ==========
local verified, verifiedCard, verifying, switchOff, closing =
    false, nil, false, false, false

closeBtn.MouseButton1Click:Connect(function()
    if verified then loginGui:Destroy()
    else
        statusLbl.Text = "⚠️ 未验证通过，无法关闭"
        statusLbl.TextColor3 = Color3.fromRGB(255, 150, 150)
    end
end)

local function enterProgram(card)
    if closing then return end
    closing = true
    verified = true
    verifiedCard = card
    if card and not switchOff then
        startHeartbeat(card, function(msg)
            statusLbl.Text = "⚠️ 心跳失败: " .. msg
            statusLbl.TextColor3 = Color3.fromRGB(255, 100, 100)
        end)
    end
    setProgress(1)
    task.wait(0.35)
    loginGui:Destroy()
end

task.spawn(function()
    local sw = apiGetSwitch()
    switchOff = (sw == "CARD_OFF")
    setProgress(0.7)
    loading.Visible = false
    mainUI.Visible = true
    if switchOff then
        statusLbl.Text = "✅ 验证已关闭，可直接使用"
        statusLbl.TextColor3 = Color3.fromRGB(100, 220, 130)
        verifyBtn.Text = "🚀 直接进入"
        verifyBtn.BackgroundColor3 = Color3.fromRGB(60, 180, 100)
    else
        statusLbl.Text = "请输入卡密后点击验证"
        task.spawn(function()
            local notice = apiGetNotice()
            if notice then ntBody.Text = notice end
        end)
    end
end)

local function doVerify()
    if verifying or closing then return end
    if switchOff then enterProgram(nil); return end
    local card = inputBox.Text:gsub("%s+", "")
    if #card < 4 then
        statusLbl.Text = "❌ 卡密太短"
        statusLbl.TextColor3 = Color3.fromRGB(255, 100, 100)
        return
    end
    verifying = true
    verifyBtn.Text = "验证中..."
    verifyBtn.BackgroundColor3 = Color3.fromRGB(120, 60, 180)
    statusLbl.Text = "正在请求服务器..."
    statusLbl.TextColor3 = Color3.fromRGB(255, 200, 100)
    task.spawn(function()
        local r = apiVerify(card)
        verifying = false
        if r.success then
            local rem = parseRemaining(r.biz)
            statusLbl.Text = "✅ 验证成功"
            statusLbl.TextColor3 = Color3.fromRGB(100, 220, 130)
            if rem then timeLbl.Text = "⏱️ " .. rem; timeFrame.Visible = true end
            verifyBtn.Text = "🚀 进入程序"
            verifyBtn.BackgroundColor3 = Color3.fromRGB(60, 180, 100)
            task.wait(0.6)
            enterProgram(card)
        else
            verifyBtn.Text = "🔑 验证卡密"
            verifyBtn.BackgroundColor3 = Color3.fromRGB(168, 85, 247)
            statusLbl.Text = "❌ " .. r.message
            statusLbl.TextColor3 = Color3.fromRGB(255, 100, 100)
        end
    end)
end

verifyBtn.MouseButton1Click:Connect(doVerify)
inputBox.FocusLost:Connect(function(e) if e then doVerify() end end)

repeat task.wait(0.1) until verified
inf("✅ 卡密验证通过，继续加载 XJ Hub...")

-- ============================================================
-- 【1】XJ Hub 主脚本开始
-- ============================================================

-- ========== 1. ScreenGui ==========
local uiParent2 = (gethui and gethui()) or game:GetService("CoreGui")
local oldGui = uiParent2:FindFirstChild("XJHubUI")
if oldGui then oldGui:Destroy() end
local screen = Instance.new("ScreenGui")
screen.Name = "XJHubUI"
screen.ResetOnSpawn = false
screen.IgnoreGuiInset = true
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.Parent = uiParent2
ok("ScreenGui")

-- ========== 2. 自适应缩放 ==========
local cam0b = WS.CurrentCamera
local vp = cam0b and cam0b.ViewportSize or Vector2.new(1920, 1080)
local isTouch = UIS.TouchEnabled and not UIS.MouseEnabled
local uiScale = 1
if isTouch or vp.X < 800 then
    uiScale = math.clamp(math.min((vp.X - 40) / 460, (vp.Y - 80) / 340), 0.6, 1)
end
inf("屏幕 " .. math.floor(vp.X) .. "×" .. math.floor(vp.Y) .. " · UI 缩放 " .. string.format("%.2f", uiScale))

-- ========== 3. 状态表 ==========
local S = {
    stamina=false, food=false, infiniteAmmo=false, rapidFire=false,
    speedEnabled=false, speedValue=100,
    jumpEnabled=false, jumpPower=50, infiniteJump=false,
    auraEnabled=false, auraRange=200, auraDamage=5, auraHumanize=true, auraStealth=true,
    autoCuff=false,
    aimbot={enabled=false, fov=120, smoothness=0.3, showFov=true, showTracer=false,
            color="红色", keyHeld=false, targetPart="头部",
            friendCheck=false, wallCheck=false, teamCheck=false, crewCheck=false},
    esp={enabled=false, name=true, distance=true, health=true, team=true,
         highlight=true, bar=true, colorByTeam=true},
    autoMoney=false, autoFarmer=false, autoMission=false, autoHack=false,
    flyEnabled=false, flySpeed=50, noclip=false,
    ghost=false, noRagdoll=false,
}

-- ========== 4. 绕过自检 ==========
inf("========== 绕过自检 ==========")
local selfCheck = { env={score=0,total=0}, bypass={score=0,total=0} }
local function checkEnv(name, fn)
    selfCheck.env.total = selfCheck.env.total + 1
    local ok2, err = pcall(fn)
    if ok2 then selfCheck.env.score = selfCheck.env.score + 1; ok("[环境] "..name)
    else no("[环境] "..name.." : "..tostring(err)) end
end
local function checkBypass(name, fn)
    selfCheck.bypass.total = selfCheck.bypass.total + 1
    local ok2, err = pcall(fn)
    if ok2 then selfCheck.bypass.score = selfCheck.bypass.score + 1; ok("[绕过] "..name)
    else no("[绕过] "..name.." : "..tostring(err)) end
end

checkEnv("loadstring", function() if not loadstring then error() end end)
checkEnv("getgc", function() if not getgc then error() end end)
checkEnv("fireproximityprompt", function() if not fireproximityprompt then error() end end)
checkEnv("Drawing", function() if not Drawing or not Drawing.new then error() end end)
checkEnv("gethui", function() if not gethui then error() end end)
checkEnv("writefile", function() if not writefile then error() end end)

checkBypass("AntiCheat 表替换", function()
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
    end
end)

checkBypass("Ratchet 补丁", function()
    local Ratchet = require(RS:FindFirstChild("Ratchet", true))
    local Sha256  = require(RS:FindFirstChild("Sha256", true))
    local mt = getmetatable(Ratchet)
    if mt and mt.__index and not mt.__index.__patched then
        mt.__index.catchUp = function() return true end
        mt.__index.respond = function(self, arg)
            return Sha256("resp|"..tostring(self.state).."|"..tostring(self.index).."|"..tostring(arg))
        end
        mt.__index.__patched = true
    end
end)

checkBypass("Ragdoll 补丁", function()
    local Ragdoll = require(RS.Modules.Ragdoll)
    local a = Ragdoll.activate
    Ragdoll.activate = function(self, cond, x, y, ...)
        if S.noRagdoll and cond then return end
        return a(self, cond, x, y, ...)
    end
end)

inf("环境: "..selfCheck.env.score.."/"..selfCheck.env.total.." · 绕过: "..selfCheck.bypass.score.."/"..selfCheck.bypass.total)

-- ========== 5. 游戏框架 ==========
local remote = RS:WaitForChild("Remote", 10)
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

-- ========== 6. 工具 ==========
local function getChar(p)
    p = p or LP
    local c = p.Character
    if not c then return end
    local h = c:FindFirstChildOfClass("Humanoid")
    local r = c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso")
    return c, h, r
end

local function isOnGround(h)
    if not h then return false end
    local st = h:GetState()
    return st == Enum.HumanoidStateType.Landed or st == Enum.HumanoidStateType.Running
        or st == Enum.HumanoidStateType.RunningNoPhysics
end

local TEAM_COLORS = {
    Police=Color3.fromRGB(60,120,255), Civilian=Color3.fromRGB(100,200,255),
    Prisoner=Color3.fromRGB(255,150,150), Fire=Color3.fromRGB(255,80,60),
    Medical=Color3.fromRGB(255,100,220), Chef=Color3.fromRGB(255,200,0),
    Delivery=Color3.fromRGB(255,150,50), Farmer=Color3.fromRGB(80,200,80),
    ["Road Service"]=Color3.fromRGB(255,240,100), Transit=Color3.fromRGB(100,240,255),
}
local TEAM_NAMES = {
    Police="警察", Civilian="平民", Prisoner="囚犯", Fire="消防", Medical="医护",
    Chef="厨师", Delivery="配送", Farmer="农民", ["Road Service"]="路政", Transit="交通",
}
local function teamColor(p) return TEAM_COLORS[p.Team and p.Team.Name] or Color3.fromRGB(200,200,200) end
local function teamLabel(p) return TEAM_NAMES[p.Team and p.Team.Name] or (p.Team and p.Team.Name or "无") end
local CREW_TEAMS = { Civilian=true, Delivery=true, Transit=true }

-- ========== 7. 好友预加载 ==========
local friendSet = {}
task.spawn(function()
    pcall(function()
        local page = LP:GetFriendsOnline(200)
        if page then for _, f in ipairs(page) do friendSet[f.VisitorId] = true end end
    end)
    pcall(function()
        local cursor = ""
        local safety = 0
        repeat
            safety = safety + 1
            if safety > 20 then break end
            local p2 = LP:GetFriendsAsync(cursor)
            if p2 then
                for _, f in ipairs(p2:GetCurrentPage()) do friendSet[f.Id] = true end
                cursor = p2.Cursor
            else break end
        until not cursor or cursor == ""
    end)
    local n = 0
    for _ in pairs(friendSet) do n = n + 1 end
    ok("[好友] 预加载 "..n.." 人")
end)
local function isFriend(p) return friendSet[p.UserId] == true end

-- ========== 8. 性能统计 ==========
local stats = { fps=0, frames=0, lastTick=tick(), ping=0, espCycles=0, espAvgTime=0 }
task.spawn(function()
    while screen.Parent do
        pcall(function() stats.ping = math.floor((LP:GetNetworkPing() or 0) * 1000) end)
        task.wait(1)
    end
end)
ok("性能统计")

-- ========== 9. 玩家信息 ==========
local userInfo = {
    name=LP.Name,
    displayName=LP.DisplayName or LP.Name,
    userId=LP.UserId,
    accountAge=LP.AccountAge or 0,
    membership=tostring(LP.MembershipType):gsub("Enum.MembershipType%.", ""),
    thumb="rbxthumb://type=AvatarHeadShot&id="..LP.UserId.."&w=150&h=150",
}

-- ========== 10. 自瞄 ==========
local PART_MAP = { ["头部"]={"Head"}, ["胸部"]={"UpperTorso","Torso"} }
local function getTargetPart(c)
    for _, n in ipairs(PART_MAP[S.aimbot.targetPart] or {"Head"}) do
        local p = c:FindFirstChild(n)
        if p then return p end
    end
    return c:FindFirstChild("HumanoidRootPart")
end
local COLOR_MAP = {
    ["红色"]=Color3.fromRGB(255,0,0), ["绿色"]=Color3.fromRGB(0,255,0),
    ["蓝色"]=Color3.fromRGB(0,150,255), ["紫色"]=Color3.fromRGB(168,85,247),
    ["白色"]=Color3.fromRGB(255,255,255),
}
local function aimColor()
    if S.aimbot.color == "彩虹" then return Color3.fromHSV(tick()%5/5,1,1) end
    return COLOR_MAP[S.aimbot.color] or Color3.fromRGB(255,0,0)
end
local function isSameTeam(p) return LP.Team and p.Team and LP.Team == p.Team end
local function isCrew(p) return p.Team and p.Team.Name and CREW_TEAMS[p.Team.Name] end

local function hasWallCheck(tPart, tChar)
    local cam = WS.CurrentCamera
    if not cam then return false end
    local filter = { cam }
    if LP.Character then table.insert(filter, LP.Character) end
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = filter
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.IgnoreWater = true
    local hit = WS:Raycast(cam.CFrame.Position, tPart.Position - cam.CFrame.Position, params)
    return not hit or hit.Instance:IsDescendantOf(tChar)
end

local fovCircle = Drawing and Drawing.new("Circle")
if fovCircle then fovCircle.Filled=false; fovCircle.NumSides=48; fovCircle.Visible=false end
local tracerLine = Drawing and Drawing.new("Line")

RunSvc.RenderStepped:Connect(function(dt)
    stats.frames = stats.frames + 1
    if tick() - stats.lastTick >= 1 then
        stats.fps = stats.frames; stats.frames = 0; stats.lastTick = tick()
    end

    if S.speedEnabled then
        local _, h = getChar()
        if h then h.WalkSpeed = S.speedValue end
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
                            if d < bd then
                                if not S.aimbot.wallCheck or hasWallCheck(part, c) then
                                    tgt, bd = part, d
                                end
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
            tracerLine.Visible = true
        elseif tracerLine then tracerLine.Visible = false end
        cam.CFrame = cam.CFrame:Lerp(CFrame.new(cam.CFrame.Position, tgt.Position), S.aimbot.smoothness)
    elseif tracerLine then
        tracerLine.Visible = false
    end
end)
ok("自瞄")

-- ========== 11. 核心循环 ==========
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
ok("核心循环")

task.spawn(function()
    while screen.Parent do
        if S.rapidFire and getgc then
            pcall(function()
                for _, v in pairs(getgc(true)) do
                    if type(v) == "table" then
                        if rawget(v,"SHOOT_MODE") ~= nil then rawset(v,"SHOOT_MODE",2) end
                        if rawget(v,"RPM") ~= nil then rawset(v,"RPM",600) end
                    end
                end
            end)
        end
        task.wait(3)
    end
end)
ok("快速射击")

-- ========== 12. 杀戮光环 ==========
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
        local w
        if S.auraStealth then w = 0.4 + math.random() * 0.2
        elseif S.auraHumanize then w = 0.15 + math.random() * 0.1
        else w = 0.1 end
        task.wait(w)
    end
end)
ok("杀戮光环")

-- ========== 13. 自动铐 ==========
task.spawn(function()
    while screen.Parent do
        if S.autoCuff and playerFunc then
            pcall(function()
                local _, _, r = getChar()
                if r then
                    for _, p in ipairs(Players:GetPlayers()) do
                        if p ~= LP then
                            local _, ph, pr = getChar(p)
                            if ph and pr and ph.Health > 0 and (pr.Position - r.Position).Magnitude <= 200 then
                                playerFunc:InvokeServer("handcuff", p, false)
                            end
                        end
                    end
                end
            end)
        end
        task.wait(1.2)
    end
end)
ok("自动铐")

-- ========== 14. 自动捡钱/农民 ==========
task.spawn(function()
    while screen.Parent do
        if S.autoMoney or S.autoFarmer then
            pcall(function()
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
                    if best then pcall(fireproximityprompt, best, 0) end
                end
            end)
        end
        task.wait(1.5)
    end
end)
ok("自动捡钱/农民")

-- ========== 15. 自动接任务 ==========
task.spawn(function()
    while screen.Parent do
        if S.autoMission and playerFunc then
            pcall(function()
                if not LP:GetAttribute("Mission") and getgc then
                    for _, v in pairs(getgc(true)) do
                        if type(v) == "table" and rawget(v,"teamJobs") then
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
ok("自动接任务")

-- ========== 16. 自动黑客 ==========
task.spawn(function()
    while screen.Parent do
        if S.autoHack then
            pcall(function()
                local fw = LP.PlayerScripts:FindFirstChild("Framework")
                local charMod = fw and require(fw:FindFirstChild("Character"))
                if charMod then
                    charMod.hackingMinigame = function() return true end
                    charMod.startMinigame = function() return true end
                end
            end)
        end
        task.wait(3)
    end
end)
ok("自动黑客")

-- ========== 17. 隐身 ==========
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
ok("隐身")

-- ========== 18. 飞行/穿墙 ==========
local FlyState = { flyConn=nil, noclipConn=nil, cache={} }
local function stopFly()
    if FlyState.flyConn then FlyState.flyConn:Disconnect(); FlyState.flyConn=nil end
    local _, h = getChar(); if h then h.PlatformStand=false; h.AutoRotate=true end
end
local function startFly()
    stopFly()
    local _, h, r = getChar()
    if not r or not h then return end
    h.AutoRotate = false
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
local function stopNoclip()
    if FlyState.noclipConn then FlyState.noclipConn:Disconnect(); FlyState.noclipConn=nil end
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

local lastJumpTick = 0
UIS.JumpRequest:Connect(function()
    if not S.jumpEnabled and not S.infiniteJump then return end
    if tick() - lastJumpTick < 0.25 then return end
    lastJumpTick = tick()
    local _, h, r = getChar()
    if not h or not r or h.Health <= 0 then return end
    if not S.infiniteJump and not isOnGround(h) then return end
    r.CFrame = r.CFrame + Vector3.new(0, S.jumpPower * 0.05, 0)
end)
ok("飞行/穿墙")

-- ========== 19. ESP ==========
local espCache = {}
local function buildESP(p, char, hrp)
    local bill = Instance.new("BillboardGui")
    bill.Name = "XJ_ESP_" .. p.Name
    bill.AlwaysOnTop = true
    bill.Size = UDim2.new(0, 120, 0, 34)
    bill.StudsOffset = Vector3.new(0, 3.2, 0)
    bill.MaxDistance = 1500
    bill.Adornee = hrp
    bill.Parent = screen

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

local function destroyESPEntry(obj)
    pcall(function()
        if obj.bill then obj.bill:Destroy() end
        if obj.hl then obj.hl:Destroy() end
    end)
end

task.spawn(function()
    while screen.Parent do
        local startTime = tick()
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
                                local tc = S.esp.colorByTeam and teamColor(p) or Color3.fromRGB(168, 85, 247)
                                local n = p.Name
                                if S.esp.team then n = "[" .. teamLabel(p) .. "] " .. n end
                                e.line1.Text = n; e.line1.TextColor3 = tc; e.line1.Visible = S.esp.name
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
                                else e.hpBg.Visible = false end
                                if e.hl then
                                    if e.hl.Parent ~= c then e.hl.Parent = c end
                                    e.hl.Adornee = c
                                    e.hl.FillColor = tc
                                    e.hl.OutlineColor = tc
                                    e.hl.Enabled = S.esp.highlight
                                end
                            end
                        else
                            if espCache[p] then
                                destroyESPEntry(espCache[p])
                                espCache[p] = nil
                            end
                        end
                    end
                end
            end)
        else
            if next(espCache) then
                local keys = {}
                for p in pairs(espCache) do table.insert(keys, p) end
                for _, p in ipairs(keys) do
                    destroyESPEntry(espCache[p])
                    espCache[p] = nil
                end
            end
        end
        stats.espCycles = stats.espCycles + 1
        local elapsed = tick() - startTime
        stats.espAvgTime = (stats.espAvgTime * 0.9) + (elapsed * 0.1)
        task.wait(0.15)
    end
end)
ok("ESP")

-- ========== 20. UI 主窗口 ==========
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

local mainBgGrad = Instance.new("UIGradient", main)
mainBgGrad.Rotation = 135
mainBgGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(22, 16, 38)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(14, 14, 20)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 12, 32)),
})

local mainStroke = Instance.new("UIStroke", main)
mainStroke.Color = Color3.fromRGB(168, 85, 247)
mainStroke.Thickness = 1.5

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
title.BackgroundTransparency = 1; title.Text = "XJ HUB 1.0"
title.TextColor3 = Color3.new(1,1,1); title.Font = Enum.Font.GothamBold
title.TextSize = 13; title.TextXAlignment = Enum.TextXAlignment.Left

local sub = Instance.new("TextLabel", topbar)
sub.Size = UDim2.new(0, 200, 0, 12); sub.Position = UDim2.new(0, 42, 0, 22)
sub.BackgroundTransparency = 1
sub.Text = "绕过 "..selfCheck.bypass.score.."/"..selfCheck.bypass.total.." · "..math.floor(vp.X).."×"..math.floor(vp.Y)
sub.TextColor3 = Color3.fromRGB(120, 230, 150)
sub.Font = Enum.Font.Gotham; sub.TextSize = 9
sub.TextXAlignment = Enum.TextXAlignment.Left

local blockDrag = false
local minBtn = Instance.new("TextButton", topbar)
minBtn.Size = UDim2.new(0, 24, 0, 24); minBtn.Position = UDim2.new(1, -60, 0.5, -12)
minBtn.BackgroundColor3 = Color3.fromRGB(251, 191, 36); minBtn.Text = "－"
minBtn.TextColor3 = Color3.new(1,1,1); minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 15; minBtn.BorderSizePixel = 0
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 6)

local closeBtn2 = Instance.new("TextButton", topbar)
closeBtn2.Size = UDim2.new(0, 24, 0, 24); closeBtn2.Position = UDim2.new(1, -30, 0.5, -12)
closeBtn2.BackgroundColor3 = Color3.fromRGB(239, 68, 68); closeBtn2.Text = "×"
closeBtn2.TextColor3 = Color3.new(1,1,1); closeBtn2.Font = Enum.Font.GothamBold
closeBtn2.TextSize = 17; closeBtn2.BorderSizePixel = 0
Instance.new("UICorner", closeBtn2).CornerRadius = UDim.new(0, 6)

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
blockTopbarDrag(closeBtn2)

-- 灵动岛
local island = Instance.new("TextButton", screen)
island.Name = "XJ_Island"
island.Size = UDim2.new(0, 140, 0, 34)
island.Position = UDim2.new(0.5, -70 * uiScale, 0, 12)
island.BackgroundColor3 = Color3.fromRGB(10, 10, 16)
island.BackgroundTransparency = 0.05
island.Text = ""
island.BorderSizePixel = 0
island.AutoButtonColor = false
island.Visible = false
island.ZIndex = 50
Instance.new("UICorner", island).CornerRadius = UDim.new(1, 0)
Instance.new("UIScale", island).Scale = uiScale
local isStroke = Instance.new("UIStroke", island)
isStroke.Color = Color3.fromRGB(168, 85, 247)
isStroke.Thickness = 1.4
isStroke.Transparency = 0.2

local isAvatar = Instance.new("ImageLabel", island)
isAvatar.Size = UDim2.new(0, 24, 0, 24)
isAvatar.Position = UDim2.new(0, 5, 0.5, -12)
isAvatar.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
isAvatar.BorderSizePixel = 0
isAvatar.Image = userInfo.thumb
Instance.new("UICorner", isAvatar).CornerRadius = UDim.new(1, 0)

local isTitle = Instance.new("TextLabel", island)
isTitle.Size = UDim2.new(1, -80, 0, 12); isTitle.Position = UDim2.new(0, 34, 0, 4)
isTitle.BackgroundTransparency = 1; isTitle.Text = "XJ Hub"
isTitle.TextColor3 = Color3.new(1, 1, 1); isTitle.Font = Enum.Font.GothamBold
isTitle.TextSize = 11; isTitle.TextXAlignment = Enum.TextXAlignment.Left

local isInfo = Instance.new("TextLabel", island)
isInfo.Size = UDim2.new(1, -80, 0, 10); isInfo.Position = UDim2.new(0, 34, 0, 18)
isInfo.BackgroundTransparency = 1; isInfo.Text = "点击展开"
isInfo.TextColor3 = Color3.fromRGB(160, 160, 180); isInfo.Font = Enum.Font.Gotham
isInfo.TextSize = 9; isInfo.TextXAlignment = Enum.TextXAlignment.Left

local isDot = Instance.new("Frame", island)
isDot.Size = UDim2.new(0, 6, 0, 6); isDot.Position = UDim2.new(1, -14, 0.5, -3)
isDot.BackgroundColor3 = Color3.fromRGB(52, 219, 137); isDot.BorderSizePixel = 0
Instance.new("UICorner", isDot).CornerRadius = UDim.new(1, 0)
Tween:Create(isDot, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
    BackgroundTransparency = 0.6,
}):Play()

local iDrag, iStart, iPos, iMoved = false, nil, nil, false
island.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        iDrag = true; iStart = input.Position; iPos = island.Position; iMoved = false
    end
end)
UIS.InputChanged:Connect(function(input)
    if iDrag and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local d = input.Position - iStart
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
    island.Size = UDim2.new(0, 0, 0, 34)
    Tween:Create(island, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 140, 0, 34),
    }):Play()
end

local function restore()
    if not minimized then return end
    minimized = false
    Tween:Create(island, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 0, 0, 34),
    }):Play()
    task.wait(0.22)
    island.Visible = false
    main.Visible = true
    main.Size = UDim2.new(0, 100, 0, 60)
    Tween:Create(main, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 460, 0, 340),
    }):Play()
end

UIS.InputEnded:Connect(function(input)
    if iDrag and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
        iDrag = false
        if not iMoved then pcall(restore) end
    end
end)
minBtn.MouseButton1Click:Connect(minimize)
closeBtn2.MouseButton1Click:Connect(function() screen:Destroy() end)

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
        local vp2 = WS.CurrentCamera and WS.CurrentCamera.ViewportSize or Vector2.new(1920,1080)
        local mw = main.AbsoluteSize.X
        local nx = math.clamp(dPos.X.Offset + d.X, 100 - mw, vp2.X - 100)
        local ny = math.clamp(dPos.Y.Offset + d.Y, 0, vp2.Y - 40)
        main.Position = UDim2.new(0, nx, 0, ny)
    end
end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        drag = false
    end
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
local nl = Instance.new("UIListLayout", innerNav)
nl.Padding = UDim.new(0, 2)
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
local tabCount = 0

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
    local ll = Instance.new("UIListLayout", page)
    ll.Padding = UDim.new(0, 4)
    pages[name] = page
    return page
end

local function createTab(name, icon)
    tabCount = tabCount + 1
    local order = tabCount
    local btn = Instance.new("TextButton", innerNav)
    btn.Size = UDim2.new(1, 0, 0, 28)
    btn.BackgroundColor3 = Color3.fromRGB(168, 85, 247)
    btn.BackgroundTransparency = 1
    btn.Text = ""; btn.BorderSizePixel = 0
    btn.LayoutOrder = order
    btn.AutoButtonColor = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    local ico = Instance.new("TextLabel", btn)
    ico.Size = UDim2.new(0, 16, 1, 0); ico.Position = UDim2.new(0, 6, 0, 0)
    ico.BackgroundTransparency = 1; ico.Text = icon or ""
    ico.TextColor3 = Color3.fromRGB(190, 190, 210)
    ico.Font = Enum.Font.GothamBold; ico.TextSize = 11
    ico.TextXAlignment = Enum.TextXAlignment.Center
    local lbl = Instance.new("TextLabel", btn)
    lbl.Size = UDim2.new(1, -24, 1, 0); lbl.Position = UDim2.new(0, 24, 0, 0)
    lbl.BackgroundTransparency = 1; lbl.Text = name
    lbl.TextColor3 = Color3.fromRGB(190, 190, 210)
    lbl.Font = Enum.Font.GothamMedium; lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    tabButtons[name] = { btn = btn, lbl = lbl, ico = ico, order = order }

    btn.MouseButton1Click:Connect(function()
        if currentTab == name then return end
        for _, pg in pairs(pages) do pg.Visible = false end
        pages[name].Visible = true
        currentTab = name
        for n, t in pairs(tabButtons) do
            local c = n == name and Color3.new(1,1,1) or Color3.fromRGB(190, 190, 210)
            t.lbl.TextColor3 = c
            t.ico.TextColor3 = c
            t.btn.BackgroundTransparency = n == name and 0.75 or 1
        end
    end)
    return btn
end

local function createToggle(parent, name, def, cb)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(1, 0, 0, 32)
    btn.BackgroundColor3 = Color3.fromRGB(28, 28, 40)
    btn.BackgroundTransparency = 0.1
    btn.Text = ""; btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    local lbl = Instance.new("TextLabel", btn)
    lbl.Size = UDim2.new(1, -56, 1, 0); lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1; lbl.Text = name
    lbl.TextColor3 = Color3.fromRGB(235, 235, 245)
    lbl.Font = Enum.Font.GothamMedium; lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    local ind = Instance.new("Frame", btn)
    ind.Size = UDim2.new(0, 36, 0, 18); ind.Position = UDim2.new(1, -44, 0.5, -9)
    ind.BackgroundColor3 = Color3.fromRGB(50, 50, 65); ind.BorderSizePixel = 0
    Instance.new("UICorner", ind).CornerRadius = UDim.new(1, 0)
    local knob = Instance.new("Frame", ind)
    knob.Size = UDim2.new(0, 14, 0, 14); knob.Position = UDim2.new(0, 2, 0.5, -7)
    knob.BackgroundColor3 = Color3.new(1, 1, 1); knob.BorderSizePixel = 0
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
    end)
end

local function createSlider(parent, name, min, max, def, cb)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, 0, 0, 46)
    frame.BackgroundColor3 = Color3.fromRGB(28, 28, 40)
    frame.BackgroundTransparency = 0.1
    frame.BorderSizePixel = 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)
    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(1, -56, 0, 14); lbl.Position = UDim2.new(0, 10, 0, 4)
    lbl.BackgroundTransparency = 1; lbl.Text = name
    lbl.TextColor3 = Color3.fromRGB(235, 235, 245)
    lbl.Font = Enum.Font.GothamMedium; lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    local vLbl = Instance.new("TextLabel", frame)
    vLbl.Size = UDim2.new(0, 46, 0, 14); vLbl.Position = UDim2.new(1, -56, 0, 4)
    vLbl.BackgroundTransparency = 1; vLbl.Text = tostring(def)
    vLbl.TextColor3 = Color3.fromRGB(190, 130, 255)
    vLbl.Font = Enum.Font.GothamBold; vLbl.TextSize = 12
    vLbl.TextXAlignment = Enum.TextXAlignment.Right
    local track = Instance.new("TextButton", frame)
    track.Size = UDim2.new(1, -20, 0, 6); track.Position = UDim2.new(0, 10, 0, 28)
    track.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
    track.Text = ""; track.BorderSizePixel = 0
    track.AutoButtonColor = false
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
    local fill = Instance.new("Frame", track)
    fill.Size = UDim2.new((def - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(168, 85, 247)
    fill.BorderSizePixel = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
    local dot = Instance.new("Frame", track)
    dot.Size = UDim2.new(0, 12, 0, 12); dot.Position = UDim2.new((def - min) / (max - min), -6, 0.5, -6)
    dot.BackgroundColor3 = Color3.new(1, 1, 1); dot.BorderSizePixel = 0
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
    Instance.new("UIStroke", dot).Color = Color3.fromRGB(168, 85, 247)
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

local function createDropdown(parent, name, options, defIdx, cb)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(1, 0, 0, 32)
    btn.BackgroundColor3 = Color3.fromRGB(28, 28, 40)
    btn.BackgroundTransparency = 0.1
    btn.Text = ""; btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    local lbl = Instance.new("TextLabel", btn)
    lbl.Size = UDim2.new(1, -100, 1, 0); lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1; lbl.Text = name
    lbl.TextColor3 = Color3.fromRGB(235, 235, 245)
    lbl.Font = Enum.Font.GothamMedium; lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    local vBox = Instance.new("TextButton", btn)
    vBox.Size = UDim2.new(0, 84, 0, 22); vBox.Position = UDim2.new(1, -92, 0.5, -11)
    vBox.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    vBox.Text = options[defIdx or 1]
    vBox.TextColor3 = Color3.fromRGB(235, 235, 245)
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

-- 8 分类
local pHome = createPage("傻逼")
local pPlayer = createPage("傻逼")
local pCombat = createPage("傻逼")
local pAim = createPage("傻逼")
local pEsp = createPage("傻逼")
local pMoney = createPage("傻逼")
local pCar = createPage("傻逼")
local pMisc = createPage("傻逼")

createTab("傻逼", "🏠")
createTab("傻逼", "👤")
createTab("傻逼", "⚔️")
createTab("傻逼", "🎯")
createTab("傻逼", "👁️")
createTab("傻逼", "💰")
createTab("傻逼", "🚗")
createTab("傻逼", "⚡")

for _, pg in pairs(pages) do pg.Visible = false end
pages["主页"].Visible = true
currentTab = "主页"
tabButtons["主页"].lbl.TextColor3 = Color3.new(1, 1, 1)
tabButtons["主页"].ico.TextColor3 = Color3.new(1, 1, 1)
tabButtons["主页"].btn.BackgroundTransparency = 0.75

-- 主页
local userCard = Instance.new("Frame", pHome)
userCard.Size = UDim2.new(1, 0, 0, 70)
userCard.BackgroundColor3 = Color3.fromRGB(28, 28, 40)
userCard.BackgroundTransparency = 0.1
userCard.BorderSizePixel = 0
Instance.new("UICorner", userCard).CornerRadius = UDim.new(0, 7)

local avatar = Instance.new("ImageLabel", userCard)
avatar.Size = UDim2.new(0, 55, 0, 55)
avatar.Position = UDim2.new(0, 8, 0.5, -27)
avatar.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
avatar.BorderSizePixel = 0
avatar.Image = userInfo.thumb
Instance.new("UICorner", avatar).CornerRadius = UDim.new(0, 27)
local avStroke = Instance.new("UIStroke", avatar)
avStroke.Color = Color3.fromRGB(168, 85, 247)
avStroke.Thickness = 2

local nameLbl = Instance.new("TextLabel", userCard)
nameLbl.Size = UDim2.new(1, -74, 0, 16); nameLbl.Position = UDim2.new(0, 70, 0, 8)
nameLbl.BackgroundTransparency = 1; nameLbl.Text = userInfo.name
nameLbl.TextColor3 = Color3.new(1, 1, 1); nameLbl.Font = Enum.Font.GothamBold
nameLbl.TextSize = 13; nameLbl.TextXAlignment = Enum.TextXAlignment.Left

local infoLbl = Instance.new("TextLabel", userCard)
infoLbl.Size = UDim2.new(1, -74, 0, 12); infoLbl.Position = UDim2.new(0, 70, 0, 26)
infoLbl.BackgroundTransparency = 1
infoLbl.Text = "@" .. userInfo.displayName .. " · " .. userInfo.membership
infoLbl.TextColor3 = Color3.fromRGB(180, 180, 200); infoLbl.Font = Enum.Font.Gotham
infoLbl.TextSize = 10; infoLbl.TextXAlignment = Enum.TextXAlignment.Left

local memberLbl = Instance.new("TextLabel", userCard)
memberLbl.Size = UDim2.new(1, -74, 0, 12); memberLbl.Position = UDim2.new(0, 70, 0, 40)
memberLbl.BackgroundTransparency = 1
memberLbl.Text = "ID: " .. userInfo.userId .. " · 账号 " .. userInfo.accountAge .. " 天"
memberLbl.TextColor3 = Color3.fromRGB(180, 180, 200); memberLbl.Font = Enum.Font.Gotham
memberLbl.TextSize = 10; memberLbl.TextXAlignment = Enum.TextXAlignment.Left

local memberLbl2 = Instance.new("TextLabel", userCard)
memberLbl2.Size = UDim2.new(1, -74, 0, 12); memberLbl2.Position = UDim2.new(0, 70, 0, 54)
memberLbl2.BackgroundTransparency = 1
memberLbl2.Text = "队伍: " .. teamLabel(LP) .. " · 玩家 " .. #Players:GetPlayers() .. "/" .. Players.MaxPlayers
memberLbl2.TextColor3 = Color3.fromRGB(190, 130, 255); memberLbl2.Font = Enum.Font.Gotham
memberLbl2.TextSize = 10; memberLbl2.TextXAlignment = Enum.TextXAlignment.Left

-- 数据卡
local statsCard = Instance.new("Frame", pHome)
statsCard.Size = UDim2.new(1, 0, 0, 60)
statsCard.BackgroundColor3 = Color3.fromRGB(28, 28, 40)
statsCard.BackgroundTransparency = 0.1
statsCard.BorderSizePixel = 0
Instance.new("UICorner", statsCard).CornerRadius = UDim.new(0, 7)

local statsTitle = Instance.new("TextLabel", statsCard)
statsTitle.Size = UDim2.new(1, -20, 0, 16); statsTitle.Position = UDim2.new(0, 10, 0, 5)
statsTitle.BackgroundTransparency = 1; statsTitle.Text = "📊 实时数据"
statsTitle.TextColor3 = Color3.fromRGB(150, 200, 255); statsTitle.Font = Enum.Font.GothamBold
statsTitle.TextSize = 11; statsTitle.TextXAlignment = Enum.TextXAlignment.Left

local statsRow = Instance.new("Frame", statsCard)
statsRow.Size = UDim2.new(1, -20, 0, 32); statsRow.Position = UDim2.new(0, 10, 0, 22)
statsRow.BackgroundTransparency = 1
local srl = Instance.new("UIListLayout", statsRow)
srl.FillDirection = Enum.FillDirection.Horizontal
srl.Padding = UDim.new(0, 5)

local function makeStatCell(parent, label, color)
    local cell = Instance.new("Frame", parent)
    cell.Size = UDim2.new(1/3, -4, 1, 0)
    cell.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
    cell.BorderSizePixel = 0
    Instance.new("UICorner", cell).CornerRadius = UDim.new(0, 5)
    local t = Instance.new("TextLabel", cell)
    t.Size = UDim2.new(1, 0, 0, 10); t.Position = UDim2.new(0, 0, 0, 2)
    t.BackgroundTransparency = 1; t.Text = label
    t.TextColor3 = Color3.fromRGB(150, 150, 180)
    t.Font = Enum.Font.Gotham; t.TextSize = 8
    local v = Instance.new("TextLabel", cell)
    v.Size = UDim2.new(1, 0, 0, 16); v.Position = UDim2.new(0, 0, 0, 12)
    v.BackgroundTransparency = 1; v.Text = "0"
    v.TextColor3 = color
    v.Font = Enum.Font.GothamBold; v.TextSize = 12
    return v
end

local fpsValue = makeStatCell(statsRow, "FPS", Color3.fromRGB(80, 220, 100))
local pingValue = makeStatCell(statsRow, "PING", Color3.fromRGB(255, 200, 100))
local espValueCell = makeStatCell(statsRow, "ESP", Color3.fromRGB(180, 130, 255))

task.spawn(function()
    while screen.Parent do
        pcall(function()
            fpsValue.Text = tostring(stats.fps)
            pingValue.Text = stats.ping .. "ms"
            if stats.ping > 200 then pingValue.TextColor3 = Color3.fromRGB(255, 80, 60)
            elseif stats.ping > 100 then pingValue.TextColor3 = Color3.fromRGB(255, 200, 100)
            else pingValue.TextColor3 = Color3.fromRGB(80, 220, 100) end
            espValueCell.Text = string.format("%.1fms", stats.espAvgTime * 1000)
        end)
        task.wait(0.5)
    end
end)

-- 功能页
createToggle(pPlayer, "无限体力", false, function(v) S.stamina = v end)
createToggle(pPlayer, "无限饥饿", false, function(v) S.food = v end)
createToggle(pPlayer, "无限子弹", false, function(v) S.infiniteAmmo = v end)
createToggle(pPlayer, "快速射击", false, function(v) S.rapidFire = v end)
createToggle(pPlayer, "修改行走速度", false, function(v) S.speedEnabled = v end)
createSlider(pPlayer, "行走速度", 16, 500, 100, function(v) S.speedValue = v end)
createToggle(pPlayer, "跳跃修改", false, function(v) S.jumpEnabled = v end)
createSlider(pPlayer, "跳跃高度", 10, 200, 50, function(v) S.jumpPower = v end)
createToggle(pPlayer, "无限跳跃", false, function(v) S.infiniteJump = v end)

createToggle(pCombat, "杀戮光环", false, function(v) S.auraEnabled = v end)
createSlider(pCombat, "光环范围", 50, 800, 200, function(v) S.auraRange = v end)
createSlider(pCombat, "光环伤害", 1, 100, 5, function(v) S.auraDamage = v end)
createToggle(pCombat, "拟人化延迟", true, function(v) S.auraHumanize = v end)
createToggle(pCombat, "隐蔽模式（0.4~0.6s）", true, function(v) S.auraStealth = v end)
createToggle(pCombat, "自动铐", false, function(v) S.autoCuff = v end)

createToggle(pAim, "开启自瞄（右键触发）", false, function(v) S.aimbot.enabled = v end)
createToggle(pAim, "显示 FOV 圈", true, function(v) S.aimbot.showFov = v end)
createToggle(pAim, "显示追踪线", false, function(v) S.aimbot.showTracer = v end)
createToggle(pAim, "好友检测", false, function(v) S.aimbot.friendCheck = v end)
createToggle(pAim, "墙壁检测", false, function(v) S.aimbot.wallCheck = v end)
createToggle(pAim, "队伍检测", false, function(v) S.aimbot.teamCheck = v end)
createToggle(pAim, "船员检测", false, function(v) S.aimbot.crewCheck = v end)
createDropdown(pAim, "FOV 颜色", {"红色", "绿色", "蓝色", "紫色", "白色"}, 1, function(v) S.aimbot.color = v end)
createDropdown(pAim, "瞄准部位", {"头部", "胸部"}, 1, function(v) S.aimbot.targetPart = v end)
createSlider(pAim, "FOV 大小", 20, 400, 120, function(v) S.aimbot.fov = v end)
createSlider(pAim, "平滑度", 1, 10, 3, function(v) S.aimbot.smoothness = v / 10 end)

createToggle(pEsp, "开启透视", false, function(v) S.esp.enabled = v end)
createToggle(pEsp, "显示名字", true, function(v) S.esp.name = v end)
createToggle(pEsp, "显示职业", true, function(v) S.esp.team = v end)
createToggle(pEsp, "显示距离", true, function(v) S.esp.distance = v end)
createToggle(pEsp, "显示血量", true, function(v) S.esp.health = v end)
createToggle(pEsp, "显示血条", true, function(v) S.esp.bar = v end)
createToggle(pEsp, "显示高亮", true, function(v) S.esp.highlight = v end)
createToggle(pEsp, "队伍着色", true, function(v) S.esp.colorByTeam = v end)

createToggle(pMoney, "自动捡钱", false, function(v) S.autoMoney = v end)
createToggle(pMoney, "自动农民", false, function(v) S.autoFarmer = v end)
createToggle(pMoney, "自动接任务", false, function(v) S.autoMission = v end)
createToggle(pMoney, "自动黑客小游戏", false, function(v) S.autoHack = v end)

createToggle(pCar, "飞行模式", false, function(v)
    S.flyEnabled = v
    if v then startFly() else stopFly() end
end)
createToggle(pCar, "穿墙 (Noclip)", false, function(v)
    S.noclip = v
    if v then startNoclip() else stopNoclip() end
end)
createSlider(pCar, "飞行速度", 10, 300, 50, function(v) S.flySpeed = v end)

createToggle(pMisc, "隐身", false, function(v) S.ghost = v end)
createToggle(pMisc, "防布娃娃", false, function(v) S.noRagdoll = v end)

ok("UI 构建完成")

-- ========== 21. 加载动画 ==========
local loading2 = Instance.new("Frame", screen)
loading2.Size = UDim2.new(1, 0, 1, 0)
loading2.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
loading2.BackgroundTransparency = 0.4
loading2.BorderSizePixel = 0
loading2.ZIndex = 100

local lCard = Instance.new("Frame", loading2)
lCard.Size = UDim2.new(0, 250, 0, 130)
lCard.Position = UDim2.new(0.5, -125 * uiScale, 0.5, -65 * uiScale)
lCard.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
lCard.BackgroundTransparency = 0.05
lCard.BorderSizePixel = 0
lCard.ZIndex = 101
Instance.new("UICorner", lCard).CornerRadius = UDim.new(0, 12)
Instance.new("UIScale", lCard).Scale = uiScale
local lCardStroke = Instance.new("UIStroke", lCard)
lCardStroke.Color = Color3.fromRGB(168, 85, 247)
lCardStroke.Thickness = 2

local lLogo = Instance.new("Frame", lCard)
lLogo.Size = UDim2.new(0, 44, 0, 44)
lLogo.Position = UDim2.new(0.5, -22, 0, 12)
lLogo.BackgroundColor3 = Color3.fromRGB(168, 85, 247)
lLogo.BorderSizePixel = 0
lLogo.ZIndex = 102
Instance.new("UICorner", lLogo).CornerRadius = UDim.new(0, 11)
local lLogoTxt = Instance.new("TextLabel", lLogo)
lLogoTxt.Size = UDim2.new(1, 0, 1, 0); lLogoTxt.BackgroundTransparency = 1
lLogoTxt.Text = "嘉"; lLogoTxt.TextColor3 = Color3.new(1, 1, 1)
lLogoTxt.Font = Enum.Font.GothamBlack; lLogoTxt.TextSize = 22
lLogoTxt.ZIndex = 103

local lTitle2 = Instance.new("TextLabel", lCard)
lTitle2.Size = UDim2.new(1, 0, 0, 14); lTitle2.Position = UDim2.new(0, 0, 0, 62)
lTitle2.BackgroundTransparency = 1; lTitle2.Text = "XJ HUB 1.0 beta"
lTitle2.TextColor3 = Color3.new(1, 1, 1); lTitle2.Font = Enum.Font.GothamBold
lTitle2.TextSize = 12; lTitle2.ZIndex = 102

local lBarBg2 = Instance.new("Frame", lCard)
lBarBg2.Size = UDim2.new(1, -36, 0, 4); lBarBg2.Position = UDim2.new(0, 18, 0, 86)
lBarBg2.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
lBarBg2.BorderSizePixel = 0; lBarBg2.ZIndex = 102
Instance.new("UICorner", lBarBg2).CornerRadius = UDim.new(1, 0)

local lBarFill2 = Instance.new("Frame", lBarBg2)
lBarFill2.Size = UDim2.new(0, 0, 1, 0)
lBarFill2.BackgroundColor3 = Color3.fromRGB(168, 85, 247)
lBarFill2.BorderSizePixel = 0; lBarFill2.ZIndex = 103
Instance.new("UICorner", lBarFill2).CornerRadius = UDim.new(1, 0)

local lStatus2 = Instance.new("TextLabel", lCard)
lStatus2.Size = UDim2.new(1, -36, 0, 14); lStatus2.Position = UDim2.new(0, 18, 0, 98)
lStatus2.BackgroundTransparency = 1; lStatus2.Text = "初始化..."
lStatus2.TextColor3 = Color3.fromRGB(200, 200, 220)
lStatus2.Font = Enum.Font.GothamMedium; lStatus2.TextSize = 9
lStatus2.TextXAlignment = Enum.TextXAlignment.Left; lStatus2.ZIndex = 102

task.spawn(function()
    lStatus2.Text = "初始化..."
    Tween:Create(lBarFill2, TweenInfo.new(0.3), { Size = UDim2.new(0.5, 0, 1, 0) }):Play()
    task.wait(0.3)
    lStatus2.Text = "加载模块..."
    Tween:Create(lBarFill2, TweenInfo.new(0.3), { Size = UDim2.new(1, 0, 1, 0) }):Play()
    task.wait(0.3)

    Tween:Create(loading2, TweenInfo.new(0.25), { BackgroundTransparency = 1 }):Play()
    Tween:Create(lCard, TweenInfo.new(0.25), { BackgroundTransparency = 1 }):Play()
    Tween:Create(lCardStroke, TweenInfo.new(0.25), { Transparency = 1 }):Play()
    for _, d in ipairs(lCard:GetDescendants()) do
        if d:IsA("TextLabel") then
            Tween:Create(d, TweenInfo.new(0.2), { TextTransparency = 1 }):Play()
        end
    end

    task.wait(0.3)
    loading2:Destroy()

    main.Visible = true
    main.Size = UDim2.new(0, 80, 0, 60)
    Tween:Create(main, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 460, 0, 340),
    }):Play()
end)

ok("加载完成")
inf("========== XJ Hub 启动完毕 ==========")
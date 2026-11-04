-- 嘉酱 · 自瞄 & ESP
-- 不飞天，不传送，不碰 Beat/CamShare 协议

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LP = Players.LocalPlayer

-- ==================== 配置 ====================
local Config = {
    Aimbot = {
        Enabled = false,
        Key = Enum.KeyCode.E,
        FOV = 120,
        Smooth = 0.18,
        Part = "Head",
        WallCheck = true,
        TeamCheck = false,
        Visible = true,
    },
    ESP = {
        Enabled = true,
        Color = Color3.fromRGB(255, 60, 60),
        Name = true,
        Distance = true,
        Health = true,
    },
    Misc = {
        NoJumpCooldown = false,
    }
}

-- ==================== 嘉酱 UI ====================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "JiaJiang_UI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LP:WaitForChild("PlayerGui")

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 240, 0, 320)
Main.Position = UDim2.new(0, 20, 0, 100)
Main.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = ScreenGui

Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", Main).Color = Color3.fromRGB(255, 60, 60)
Instance.new("UIStroke", Main).Thickness = 1

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 36)
Title.BackgroundTransparency = 1
Title.Text = "嘉酱"
Title.TextColor3 = Color3.fromRGB(255, 60, 60)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 18
Title.Parent = Main

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0, 100, 0, 28)
ToggleBtn.Position = UDim2.new(0, 12, 0, 48)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
ToggleBtn.Text = "自瞄: 关"
ToggleBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
ToggleBtn.Font = Enum.Font.Gotham
ToggleBtn.TextSize = 12
ToggleBtn.Parent = Main
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 6)

local EspBtn = Instance.new("TextButton")
EspBtn.Size = UDim2.new(0, 100, 0, 28)
EspBtn.Position = UDim2.new(0, 124, 0, 48)
EspBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
EspBtn.Text = "透视: 开"
EspBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
EspBtn.Font = Enum.Font.Gotham
EspBtn.TextSize = 12
EspBtn.Parent = Main
Instance.new("UICorner", EspBtn).CornerRadius = UDim.new(0, 6)

local WallBtn = Instance.new("TextButton")
WallBtn.Size = UDim2.new(0, 212, 0, 28)
WallBtn.Position = UDim2.new(0, 12, 0, 84)
WallBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
WallBtn.Text = "隔墙检测: 开"
WallBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
WallBtn.Font = Enum.Font.Gotham
WallBtn.TextSize = 12
WallBtn.Parent = Main
Instance.new("UICorner", WallBtn).CornerRadius = UDim.new(0, 6)

local SmoothLabel = Instance.new("TextLabel")
SmoothLabel.Size = UDim2.new(1, -24, 0, 20)
SmoothLabel.Position = UDim2.new(0, 12, 0, 124)
SmoothLabel.BackgroundTransparency = 1
SmoothLabel.Text = "平滑度: 0.18"
SmoothLabel.TextColor3 = Color3.fromRGB(160, 160, 160)
SmoothLabel.Font = Enum.Font.Gotham
SmoothLabel.TextSize = 11
SmoothLabel.TextXAlignment = Enum.TextXAlignment.Left
SmoothLabel.Parent = Main

local SmoothSlider = Instance.new("TextButton")
SmoothSlider.Size = UDim2.new(0, 212, 0, 6)
SmoothSlider.Position = UDim2.new(0, 12, 0, 150)
SmoothSlider.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
SmoothSlider.Text = ""
SmoothSlider.Parent = Main
Instance.new("UICorner", SmoothSlider).CornerRadius = UDim.new(0, 3)

local FovLabel = Instance.new("TextLabel")
FovLabel.Size = UDim2.new(1, -24, 0, 20)
FovLabel.Position = UDim2.new(0, 12, 0, 170)
FovLabel.BackgroundTransparency = 1
FovLabel.Text = "FOV: 120"
FovLabel.TextColor3 = Color3.fromRGB(160, 160, 160)
FovLabel.Font = Enum.Font.Gotham
FovLabel.TextSize = 11
FovLabel.TextXAlignment = Enum.TextXAlignment.Left
FovLabel.Parent = Main

local FovSlider = Instance.new("TextButton")
FovSlider.Size = UDim2.new(0, 212, 0, 6)
FovSlider.Position = UDim2.new(0, 12, 0, 196)
FovSlider.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
FovSlider.Text = ""
FovSlider.Parent = Main
Instance.new("UICorner", FovSlider).CornerRadius = UDim.new(0, 3)

local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1, -24, 0, 40)
Status.Position = UDim2.new(0, 12, 0, 216)
Status.BackgroundTransparency = 1
Status.Text = "按住 E 自瞄"
Status.TextColor3 = Color3.fromRGB(100, 100, 100)
Status.Font = Enum.Font.Gotham
Status.TextSize = 11
Status.TextWrapped = true
Status.TextXAlignment = Enum.TextXAlignment.Left
Status.Parent = Main

-- ==================== 自瞄逻辑 ====================
local aiming = false
local currentTarget = nil

local function hasLOS(target)
    if not Config.Aimbot.WallCheck then return true end
    local part = target.Character and target.Character:FindFirstChild(Config.Aimbot.Part)
    if not part then return false end
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = { LP.Character }
    params.FilterType = Enum.RaycastFilterType.Blacklist
    local result = workspace:Raycast(Camera.CFrame.Position, part.Position - Camera.CFrame.Position, params)
    return result == nil or result.Instance:IsDescendantOf(target.Character)
end

local function validTarget(plr)
    if plr == LP then return false end
    local char = plr.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local part = char:FindFirstChild(Config.Aimbot.Part)
    if not hum or not part or hum.Health <= 0 then return false end
    if Config.Aimbot.TeamCheck and plr.Team == LP.Team then return false end
    return true
end

local function getBest()
    local best, bestDist = nil, math.huge
    local mouse = UserInputService:GetMouseLocation()
    for _, plr in ipairs(Players:GetPlayers()) do
        if validTarget(plr) and hasLOS(plr) then
            local part = plr.Character[Config.Aimbot.Part]
            local screen, onScreen = Camera:WorldToViewportPoint(part.Position)
            if onScreen then
                local dist = (Vector2.new(screen.X, screen.Y) - mouse).Magnitude
                if dist < Config.Aimbot.FOV and dist < bestDist then
                    bestDist = dist
                    best = plr
                end
            end
        end
    end
    return best
end

RunService.RenderStepped:Connect(function()
    if not Config.Aimbot.Enabled or not aiming then
        currentTarget = nil
        return
    end
    if not currentTarget or not validTarget(currentTarget) then
        currentTarget = getBest()
    end
    if currentTarget and currentTarget.Character then
        local part = currentTarget.Character:FindFirstChild(Config.Aimbot.Part)
        if part then
            local goal = CFrame.new(Camera.CFrame.Position, part.Position)
            Camera.CFrame = Camera.CFrame:Lerp(goal, Config.Aimbot.Smooth)
        end
    end
end)

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Config.Aimbot.Key then
        aiming = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Config.Aimbot.Key then
        aiming = false
        currentTarget = nil
    end
end)

-- ==================== ESP ====================
local espCache = {}

local function clearESP(plr)
    local data = espCache[plr]
    if data then
        if data.highlight then data.highlight:Destroy() end
        if data.billboard then data.billboard:Destroy() end
        espCache[plr] = nil
    end
end

local function buildESP(plr)
    if plr == LP then return end
    clearESP(plr)
    local char = plr.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not head or not hum then return end

    local hl = Instance.new("Highlight")
    hl.Name = "JiaJiang_ESP"
    hl.FillColor = Config.ESP.Color
    hl.FillTransparency = 0.5
    hl.OutlineColor = Config.ESP.Color
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Enabled = Config.ESP.Enabled
    hl.Parent = char

    local bb = Instance.new("BillboardGui")
    bb.Name = "JiaJiang_BB"
    bb.Adornee = head
    bb.Size = UDim2.new(0, 160, 0, 50)
    bb.StudsOffset = Vector3.new(0, 2.5, 0)
    bb.AlwaysOnTop = true
    bb.Enabled = Config.ESP.Enabled
    bb.Parent = head

    local nameTxt = Instance.new("TextLabel")
    nameTxt.Size = UDim2.new(1, 0, 0.5, 0)
    nameTxt.BackgroundTransparency = 1
    nameTxt.Text = plr.Name
    nameTxt.TextColor3 = Config.ESP.Color
    nameTxt.TextStrokeTransparency = 0
    nameTxt.TextScaled = true
    nameTxt.Font = Enum.Font.GothamBold
    nameTxt.Parent = bb

    local distTxt = Instance.new("TextLabel")
    distTxt.Size = UDim2.new(1, 0, 0.5, 0)
    distTxt.Position = UDim2.new(0, 0, 0.5, 0)
    distTxt.BackgroundTransparency = 1
    distTxt.TextColor3 = Color3.fromRGB(200, 200, 200)
    distTxt.TextStrokeTransparency = 0
    distTxt.TextScaled = true
    distTxt.Font = Enum.Font.Gotham
    distTxt.Parent = bb

    espCache[plr] = { highlight = hl, billboard = bb, nameTxt = nameTxt, distTxt = distTxt }
end

RunService.RenderStepped:Connect(function()
    for plr, data in pairs(espCache) do
        if not Config.ESP.Enabled then
            if data.highlight then data.highlight.Enabled = false end
            if data.billboard then data.billboard.Enabled = false end
        else
            if data.highlight then data.highlight.Enabled = true end
            if data.billboard then data.billboard.Enabled = true end
            if data.distTxt and plr.Character and plr.Character:FindFirstChild("Head") and LP.Character and LP.Character:FindFirstChild("Head") then
                local d = (plr.Character.Head.Position - LP.Character.Head.Position).Magnitude
                data.distTxt.Text = string.format("[%d]", math.floor(d))
            end
        end
    end
end)

Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function()
        task.wait(0.5)
        if Config.ESP.Enabled then buildESP(plr) end
    end)
end)

Players.PlayerRemoving:Connect(clearESP)

task.spawn(function()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP then
            if plr.Character then buildESP(plr) end
            plr.CharacterAdded:Connect(function()
                task.wait(0.5)
                if Config.ESP.Enabled then buildESP(plr) end
            end)
        end
    end
end)

-- ==================== UI 交互 ====================
ToggleBtn.MouseButton1Click:Connect(function()
    Config.Aimbot.Enabled = not Config.Aimbot.Enabled
    ToggleBtn.Text = "自瞄: " .. (Config.Aimbot.Enabled and "开" or "关")
    ToggleBtn.BackgroundColor3 = Config.Aimbot.Enabled and Color3.fromRGB(255, 60, 60) or Color3.fromRGB(40, 40, 48)
end)

EspBtn.MouseButton1Click:Connect(function()
    Config.ESP.Enabled = not Config.ESP.Enabled
    EspBtn.Text = "透视: " .. (Config.ESP.Enabled and "开" or "关")
    EspBtn.BackgroundColor3 = Config.ESP.Enabled and Color3.fromRGB(255, 60, 60) or Color3.fromRGB(40, 40, 48)
    if Config.ESP.Enabled then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LP and plr.Character then buildESP(plr) end
        end
    end
end)

WallBtn.MouseButton1Click:Connect(function()
    Config.Aimbot.WallCheck = not Config.Aimbot.WallCheck
    WallBtn.Text = "隔墙检测: " .. (Config.Aimbot.WallCheck and "开" or "关")
end)

-- 简单拖拽调平滑/FOV
local draggingSmooth, draggingFov = false, false

SmoothSlider.MouseButton1Down:Connect(function() draggingSmooth = true end)
FovSlider.MouseButton1Down:Connect(function() draggingFov = true end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingSmooth = false
        draggingFov = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
    if draggingSmooth then
        local rel = math.clamp((input.Position.X - SmoothSlider.AbsolutePosition.X) / SmoothSlider.AbsoluteSize.X, 0, 1)
        Config.Aimbot.Smooth = 0.05 + rel * 0.5
        SmoothLabel.Text = string.format("平滑度: %.2f", Config.Aimbot.Smooth)
        SmoothSlider.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
    elseif draggingFov then
        local rel = math.clamp((input.Position.X - FovSlider.AbsolutePosition.X) / FovSlider.AbsoluteSize.X, 0, 1)
        Config.Aimbot.FOV = math.floor(30 + rel * 270)
        FovLabel.Text = "FOV: " .. Config.Aimbot.FOV
        FovSlider.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
    end
end)

-- 初始化颜色
ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
EspBtn.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
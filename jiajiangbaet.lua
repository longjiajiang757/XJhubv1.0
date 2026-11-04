-- ==================== 液态玻璃 UI（可缩小） ====================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "JiaJiang_UI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = LP:WaitForChild("PlayerGui")

local function makeGlass(parent, size, pos, radius)
    local f = Instance.new("Frame")
    f.Size = size
    f.Position = pos
    f.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    f.BackgroundTransparency = 0.82
    f.BorderSizePixel = 0
    f.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 18)
    corner.Parent = f

    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200, 200, 220)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 150, 180)),
    })
    grad.Rotation = 135
    grad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.55),
        NumberSequenceKeypoint.new(0.5, 0.85),
        NumberSequenceKeypoint.new(1, 0.7),
    })
    grad.Parent = f

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Transparency = 0.75
    stroke.Thickness = 1
    stroke.Parent = f

    return f
end

-- 主面板
local Main = makeGlass(ScreenGui, UDim2.new(0, 210, 0, 0), UDim2.new(1, -230, 0, 90), 20)
Main.AutomaticSize = Enum.AutomaticSize.Y
Main.Active = true
Main.Draggable = true
Main.Visible = false  -- 默认收起

local list = Instance.new("UIListLayout")
list.Padding = UDim.new(0, 8)
list.SortOrder = Enum.SortOrder.LayoutOrder
list.Parent = Main

local pad = Instance.new("UIPadding")
pad.PaddingTop = UDim.new(0, 10)
pad.PaddingBottom = UDim.new(0, 10)
pad.PaddingLeft = UDim.new(0, 10)
pad.PaddingRight = UDim.new(0, 10)
pad.Parent = Main

-- 标题行（标题 + 收起按钮）
local titleRow = Instance.new("Frame")
titleRow.Size = UDim2.new(1, 0, 0, 24)
titleRow.BackgroundTransparency = 1
titleRow.LayoutOrder = 1
titleRow.Parent = Main

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -30, 1, 0)
Title.BackgroundTransparency = 1
Title.Text = "嘉酱"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextStrokeTransparency = 0.6
Title.Font = Enum.Font.GothamBold
Title.TextSize = 17
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = titleRow

local collapseBtn = Instance.new("TextButton")
collapseBtn.Size = UDim2.new(0, 24, 0, 24)
collapseBtn.Position = UDim2.new(1, -24, 0, 0)
collapseBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
collapseBtn.BackgroundTransparency = 0.85
collapseBtn.BorderSizePixel = 0
collapseBtn.Text = "—"
collapseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
collapseBtn.Font = Enum.Font.GothamBold
collapseBtn.TextSize = 14
collapseBtn.Parent = titleRow
Instance.new("UICorner", collapseBtn).CornerRadius = UDim.new(1, 0)

local function glassButton(text, order, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 32)
    btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    btn.BackgroundTransparency = 0.88
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(240, 240, 255)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 12
    btn.AutoButtonColor = false
    btn.LayoutOrder = order
    btn.Parent = Main

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 10)
    c.Parent = btn

    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(170, 170, 210)),
    })
    g.Rotation = 120
    g.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.7),
        NumberSequenceKeypoint.new(1, 0.9),
    })
    g.Parent = btn

    local s = Instance.new("UIStroke")
    s.Color = Color3.fromRGB(255, 255, 255)
    s.Transparency = 0.7
    s.Thickness = 1
    s.Parent = btn

    btn.MouseButton1Click:Connect(callback)
    return btn
end

local toggleBtn = glassButton("自瞄: 关", 2, function() end)
local espBtn = glassButton("透视: 开", 3, function() end)
local wallBtn = glassButton("隔墙: 开", 4, function() end)

-- 浮动小圆球（收起状态）
local orb = Instance.new("TextButton")
orb.Size = UDim2.new(0, 44, 0, 44)
orb.Position = UDim2.new(1, -60, 1, -180)
orb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
orb.BackgroundTransparency = 0.75
orb.BorderSizePixel = 0
orb.Text = "嘉"
orb.TextColor3 = Color3.fromRGB(255, 90, 110)
orb.Font = Enum.Font.GothamBold
orb.TextSize = 18
orb.AutoButtonColor = false
orb.Active = true
orb.Draggable = true
orb.Parent = ScreenGui

local oc = Instance.new("UICorner")
oc.CornerRadius = UDim.new(1, 0)
oc.Parent = orb

local og = Instance.new("UIGradient")
og.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 180, 220)),
})
og.Rotation = 135
og.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.55),
    NumberSequenceKeypoint.new(1, 0.85),
})
og.Parent = orb

local os = Instance.new("UIStroke")
os.Color = Color3.fromRGB(255, 90, 110)
os.Transparency = 0.5
os.Thickness = 1
os.Parent = orb

-- 展开 / 收起
local function expand()
    Main.Visible = true
    orb.Visible = false
    -- 面板出现在小球附近
    Main.Position = UDim2.new(1, -230, 1, -380)
end

local function collapse()
    Main.Visible = false
    orb.Visible = true
    -- 小球回到面板左下角附近
    orb.Position = UDim2.new(1, -60, 1, -180)
end

collapseBtn.MouseButton1Click:Connect(collapse)
orb.MouseButton1Click:Connect(expand)

-- 自瞄触发按钮（收起时也在）
local fireBtn = Instance.new("TextButton")
fireBtn.Size = UDim2.new(0, 60, 0, 60)
fireBtn.Position = UDim2.new(1, -86, 1, -110)
fireBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
fireBtn.BackgroundTransparency = 0.8
fireBtn.BorderSizePixel = 0
fireBtn.Text = "瞄"
fireBtn.TextColor3 = Color3.fromRGB(255, 90, 110)
fireBtn.Font = Enum.Font.GothamBold
fireBtn.TextSize = 18
fireBtn.AutoButtonColor = false
fireBtn.Parent = ScreenGui

local fc = Instance.new("UICorner")
fc.CornerRadius = UDim.new(1, 0)
fc.Parent = fireBtn

local fg = Instance.new("UIGradient")
fg.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 200, 230)),
})
fg.Rotation = 120
fg.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.6),
    NumberSequenceKeypoint.new(1, 0.9),
})
fg.Parent = fireBtn

local fs = Instance.new("UIStroke")
fs.Color = Color3.fromRGB(255, 255, 255)
fs.Transparency = 0.6
fs.Thickness = 1
fs.Parent = fireBtn
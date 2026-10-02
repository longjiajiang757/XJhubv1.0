-- Why do i love gpt 5.6 sol high the reason is below.
-- dsc.gg/oxyenv 

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local LocalizationService = game:GetService("LocalizationService")
local localPlayer = Players.LocalPlayer
local hui = gethui and gethui() or nil

local function fn()
	return hui or game:GetService("CoreGui")
end

local function fn2(arg)
	return function(...)
		local ok, result = pcall(arg, ...)

		if not ok then
			pcall(function()
				if API and API.log then
					API.log("[ui] " .. tostring(result), "error")
				end
			end)
		end
	end
end

local function fn3(arg, ...)
	local spawn = task.spawn
	local v = fn2(arg)
	local v2 = table.pack(...)
	return spawn(v, table.unpack(v2, 1, v2.n))
end

local function fn4(arg, ...)
	return task.defer(fn2(arg), ...)
end

local function fn5(arg, arg2, ...)
	local delay = task.delay
	local v = fn2(arg2)
	local v2 = table.pack(...)
	v2.n = 3 + v2.n - 1
	table.move(v2, 1, v2.n, 3, v2)
	v2[1] = arg
	v2[2] = v
	return delay(table.unpack(v2, 1, v2.n))
end

local index = { icons = {} }
index.__index = index

index.setIcon = function(arg, arg2)
	index.icons[arg] = arg2
end

index.preloadIcons = function()
	if index._preloading then
		return
	end
	index._preloading = true

	fn3(function()
		local now = os.clock()
		local tbl = {}
		local tbl2 = {}

		for _, icon in pairs(index.icons) do
			if type(icon) == "string" and string.find(icon, "rbxassetid", 1, true) then
				tbl[#tbl + 1] = icon
				local imageLabel = Instance.new("ImageLabel")
				imageLabel.Image = icon
				tbl2[#tbl2 + 1] = imageLabel
			end
		end

		if #tbl == 0 then
			index._preloading = false
			return
		end
		local ContentProvider = game:GetService("ContentProvider")
		local n = 0
		local n2 = 0

		local ok = pcall(function()
			ContentProvider:PreloadAsync(tbl2, function(arg, arg2)
				n += 1

				if arg2 ~= Enum.AssetFetchStatus.Success then
					n2 += 1
				end
			end)
		end)

		if not ok then
			ok = pcall(function()
				ContentProvider:PreloadAsync(tbl)
			end)

			n = ok and #tbl or 0
		end

		for _, v in ipairs(tbl2) do
			pcall(function()
				v:Destroy()
			end)
		end

		index.preloadStat = { total = #tbl, loaded = n, failed = n2, ok = ok, secs = os.clock() - now }
		index._preloading = false
	end)
end

local theme = {
	accent = Color3.fromRGB(168, 85, 247),
	accent2 = Color3.fromRGB(192, 132, 252),
	cyan = Color3.fromRGB(34, 211, 238),
	cyan2 = Color3.fromRGB(103, 232, 249),
	gold = Color3.fromRGB(251, 191, 36),
	gold2 = Color3.fromRGB(252, 211, 77),
	bg = Color3.fromRGB(8, 8, 13),
	bg2 = Color3.fromRGB(11, 11, 19),
	winTop = Color3.fromRGB(18, 18, 28),
	winBot = Color3.fromRGB(11, 11, 18),
	bar = Color3.fromRGB(26, 26, 36),
	side = Color3.fromRGB(13, 13, 21),
	panel = Color3.fromRGB(16, 16, 25),
	border = Color3.fromRGB(255, 255, 255),
	green = Color3.fromRGB(55, 243, 154),
	red = Color3.fromRGB(239, 68, 68),
	red2 = Color3.fromRGB(248, 113, 113),
	discord = Color3.fromRGB(88, 101, 242),
	txt = Color3.fromRGB(238, 240, 246),
	soft = Color3.fromRGB(182, 186, 208),
	sub = Color3.fromRGB(124, 128, 153),
	dim = Color3.fromRGB(86, 90, 110),
	off = Color3.fromRGB(255, 255, 255),
	well = Color3.fromRGB(24, 22, 38),
	amber = Color3.fromRGB(251, 191, 36),
	surface = Color3.fromRGB(255, 255, 255),
}

index.theme = theme

local tbl = {
	disp = Enum.Font.Michroma,
	head = Enum.Font.GothamBold,
	med = Enum.Font.GothamMedium,
	body = Enum.Font.Gotham,
	mono = Enum.Font.Code,
}

local function fn6(arg)
	if typeof(arg) == "Color3" then
		return arg
	end
	return theme[arg] or theme.accent
end

local function fn7(arg, arg2, parent)
	local instance = Instance.new(arg)

	for k, v in pairs(arg2) do
		instance[k] = v
	end

	if parent then
		instance.Parent = parent
	end

	return instance
end

local function fn8(arg, arg2)
	fn7("UICorner", { CornerRadius = UDim.new(0, arg2 or 10) }, arg)
end

local function fn9(arg, arg2, arg3, arg4)
	local UIStroke = fn7("UIStroke", {
		Color = fn6(arg2 or "border"),
		Thickness = arg4 or 1,
		Transparency = arg3 or 0.9,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, arg)

	if arg2 == "accent" or arg2 == "accent2" then
		UIStroke:SetAttribute("vxCol", arg2)
	end

	return UIStroke
end

local function fn10(arg, arg2, arg3, arg4)
	local UIGradient = fn7("UIGradient", { Rotation = arg2 or 0, Color = ColorSequence.new(fn6(arg3 or "accent"), fn6(arg4 or "accent2")) }, arg)
	arg3 = arg3 or "accent"
	arg4 = arg4 or "accent2"

	if type(arg3) == "string" and type(arg4) == "string" then
		UIGradient:SetAttribute("vxC1", arg3)
		UIGradient:SetAttribute("vxC2", arg4)
	end

	return UIGradient
end

local function fn11(arg, arg2, arg3, arg4, arg5)
	return fn7("UIPadding", {
		PaddingLeft = UDim.new(0, arg2),
		PaddingRight = UDim.new(0, arg4 or arg2),
		PaddingTop = UDim.new(0, arg3 or arg2),
		PaddingBottom = UDim.new(0, arg5 or arg3 or arg2),
	}, arg)
end

local function fn12(arg, arg2, arg3, arg4)
	local str = arg2 and (index.icons[arg2] or arg2) or nil

	if typeof(str) == "number" then
		str = "rbxassetid://" .. str
	end

	if typeof(str) == "string" and str:match("rbxassetid") then
		local ImageLabel = fn7("ImageLabel", {
			Size = UDim2.fromOffset(arg4, arg4),
			BackgroundTransparency = 1,
			Image = str,
			ImageColor3 = fn6(arg3 or "accent2"),
			ScaleType = Enum.ScaleType.Fit,
		}, arg)

		if arg3 == "accent" or arg3 == "accent2" or arg3 == nil then
			local v = ImageLabel
			local setAttribute = v.SetAttribute
			arg3 = arg3 or "accent2"
			setAttribute(v, "vxImg", arg3)
		end

		return ImageLabel
	end

	local Frame = fn7("Frame", {
		Size = UDim2.fromOffset(arg4, arg4),
		BackgroundColor3 = fn6(arg3 or "accent"),
		BorderSizePixel = 0,
		BackgroundTransparency = 0.5,
	}, arg)

	fn8(Frame, math.floor(arg4 / 4))
	fn10(Frame, 45, "accent", "cyan")
	return Frame
end

local function fn13(arg, arg2, arg3, arg4)
	local tween = TweenService:Create(arg, TweenInfo.new(arg2 or 0.15, arg4 or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), arg3)
	tween:Play()
	return tween
end

local function fn14(arg)
	arg.MouseEnter:Connect(fn2(function()
		UserInputService.MouseIcon = "rbxasset://SystemCursors/PointingHand"
	end))

	arg.MouseLeave:Connect(fn2(function()
		UserInputService.MouseIcon = ""
	end))
end

local function scrollbar(arg, arg2, arg3, arg4)
	local tbl2 = arg4 or {}
	arg.ScrollBarThickness = 0
	local width = tbl2.width or 4
	local inset = tbl2.inset or 10
	local right = tbl2.right or 5
	local yOff = tbl2.yOff or 0
	local n = 0.62
	local n2 = 0.32
	local v = fn7

	local Frame = v("Frame", {
		Name = "_Thumb",
		AnchorPoint = Vector2.new(1, 0),
		BackgroundColor3 = theme.soft,
		BackgroundTransparency = n,
		BorderSizePixel = 0,
		ZIndex = tbl2.z or 8,
		Visible = false,
		Active = true,
		Size = UDim2.fromOffset(width, 30),
	}, arg2)

	fn7("UICorner", { CornerRadius = UDim.new(1, 0) }, Frame)
	local flag = false
	local flag2 = false
	local n3 = 0

	local function fn15()
		local y = arg.AbsoluteSize.Y
		local y2 = arg.AbsoluteCanvasSize.Y
		return y, y2, y - inset * 2, y2 - y
	end

	local function fn16()
		return flag and 0.18 or flag2 and 0.32 or 0.62
	end

	local function fn17()
		n3 += 1
		local v2 = n3

		fn5(1.5, function()
			if n3 == v2 and not flag2 and not flag and Frame.Visible then
				fn13(Frame, 1, { BackgroundTransparency = 1 }, Enum.EasingStyle.Sine)
			end
		end)
	end

	local function fn18()
		if Frame.Visible then
			fn13(Frame, 0.12, { BackgroundTransparency = fn16() })
			fn17()
		end
	end

	local function fn19()
		if not arg.Visible then
			Frame.Visible = false
			return
		end
		local v2, v3, v4, v5 = fn15()
		if v3 <= v2 + 2 or v4 < 26 then
			Frame.Visible = false
			return
		end
		local n4 = math.clamp(v4 * v2 / v3, 26, v4)
		local n5 = v5 > 0 and arg.CanvasPosition.Y / v5 or 0
		Frame.Size = UDim2.fromOffset(width, n4)
		Frame.Position = UDim2.new(1, -right, 0, yOff + inset + n5 * (v4 - n4))
		Frame.Visible = true
	end

	arg:GetPropertyChangedSignal("CanvasPosition"):Connect(fn2(function()
		pcall(fn19)
		fn18()
	end))

	for _, v2 in ipairs({ "AbsoluteCanvasSize", "AbsoluteSize", "Visible" }) do
		arg:GetPropertyChangedSignal(v2):Connect(fn2(function()
			pcall(fn19)
		end))
	end

	Frame.MouseEnter:Connect(fn2(function()
		flag2 = true

		if Frame.Visible then
			fn13(Frame, 0.12, { BackgroundTransparency = n2 })
		end
	end))

	Frame.MouseLeave:Connect(fn2(function()
		flag2 = false

		if not flag then
			fn13(Frame, 0.12, { BackgroundTransparency = n })
			fn17()
		end
	end))

	Frame.InputBegan:Connect(fn2(--[[ VM helper function (reads VM upvalues, emitted verbatim) ]]
	function(H)if H.UserInputType==Enum.UserInputType.MouseButton1 or H.UserInputType==Enum.UserInputType.Touch then f[1][3][f[1][5]]=true;f[2][3][f[2][5]]=H.Position.Y;f[3][3][f[3][5]](f[4],0.1,{BackgroundTransparency=0.18});end;end))

	arg3[#arg3 + 1] = UserInputService.InputChanged:Connect(fn2(--[[ VM helper function (reads VM upvalues, emitted verbatim) ]]
	function(H)if f[1][3][f[1][5]]and(H.UserInputType==Enum.UserInputType.MouseMovement or H.UserInputType==Enum.UserInputType.Touch)then local h,h,h,c=f[2][3][f[2][5]]();local Y=h-f[3].AbsoluteSize.Y;h=H.Position.Y-f[4][3][f[4][5]];f[4][3][f[4][5]]=H.Position.Y;if Y>0 and c>0 then f[5].CanvasPosition=Vector2.new(0,math.clamp(f[5].CanvasPosition.Y+h*(c/Y),0,c));end;end;end))

	arg3[#arg3 + 1] = UserInputService.InputEnded:Connect(fn2(--[[ VM helper function (reads VM upvalues, emitted verbatim) ]]
	function(H)if(H.UserInputType==Enum.UserInputType.MouseButton1 or H.UserInputType==Enum.UserInputType.Touch)and f[1][3][f[1][5]]then f[1][3][f[1][5]]=false;f[2][3][f[2][5]](f[3],0.12,{BackgroundTransparency=f[4][3][f[4][5]]()});f[5][3][f[5][5]]();end;end))

	fn14(Frame)

	fn4(function()
		fn19()
		fn18()
	end)

	return Frame
end

index.scrollbar = scrollbar

local function fn15(arg)
	local currentCamera = workspace.CurrentCamera
	if not currentCamera then
		return
	end
	local viewportSize = currentCamera.ViewportSize
	local absolutePosition = arg.AbsolutePosition
	local absoluteSize = arg.AbsoluteSize
	local n = math.clamp(absolutePosition.X, 2, math.max(2, viewportSize.X - absoluteSize.X - 2))
	local n2 = math.clamp(absolutePosition.Y, 2, math.max(2, viewportSize.Y - absoluteSize.Y - 2))

	if n ~= absolutePosition.X or n2 ~= absolutePosition.Y then
		local position = arg.Position
		arg.Position = UDim2.new(position.X.Scale, position.X.Offset + n - absolutePosition.X, position.Y.Scale, position.Y.Offset + n2 - absolutePosition.Y)
	end
end

local function fn16(arg)
	arg.InputBegan:Connect(fn2(--[[ VM helper function (reads VM upvalues, emitted verbatim) ]]
	function(H)if H.UserInputType==Enum.UserInputType.MouseButton1 or H.UserInputType==Enum.UserInputType.Touch then f[1][3][f[1][5]]=true;f[3][3][f[3][5]]=H.Position.X;f[4][3][f[4][5]]=H.Position.Y;f[5][3][f[5][5]]=f[2].Position;end;end))

	local inputEnded = UserInputService.InputEnded

	return UserInputService.InputChanged:Connect(fn2(--[[ VM helper function (reads VM upvalues, emitted verbatim) ]]
	function(H)if f[1][3][f[1][5]]and(H.UserInputType==Enum.UserInputType.MouseMovement or H.UserInputType==Enum.UserInputType.Touch)then f[2].Position=UDim2.new(f[3][3][f[3][5]].X.Scale,f[3][3][f[3][5]].X.Offset+(H.Position.X-f[4][3][f[4][5]]),f[3][3][f[3][5]].Y.Scale,f[3][3][f[3][5]].Y.Offset+(H.Position.Y-f[5][3][f[5][5]]));f[6][3][f[6][5]](f[2]);end;end)), (inputEnded:Connect(fn2(--[[ VM helper function (reads VM upvalues, emitted verbatim) ]]
	function(H)if H.UserInputType==Enum.UserInputType.MouseButton1 or H.UserInputType==Enum.UserInputType.Touch then if f[1][3][f[1][5]]then f[2][3][f[2][5]](f[3]);end;f[1][3][f[1][5]]=false;end;end)))
end

index.new = function(arg)
	local tbl2 = arg or {}

	local obj = setmetatable({
		tabs = {},
		_q = {},
		_order = 0,
		_compact = false,
		_state = "normal",
		_conns = {},
		_onClose = {},
		_controls = {},
	}, index)

	index.preloadIcons()

	local function fn17(...)
		local v = table.pack(...)

		for _, v2 in ipairs({ ... }) do
			obj._conns[#obj._conns + 1] = v2
		end

		return table.unpack(v, 1, v.n)
	end

	local str = "UILib_" .. tostring(tbl2.title or "Kit"):gsub("%W", "")
	local v = fn():FindFirstChild(str)

	if v then
		v:Destroy()
	end

	local ScreenGui = fn7("ScreenGui", {
		Name = str,
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 9999,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, fn())

	obj.gui = ScreenGui
	local size = tbl2.size or Vector2.new(620, 460)
	local viewportSize = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
	local flag = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
	local fit = 1

	if flag or viewportSize.X < 820 then
		fit = math.clamp(math.min((viewportSize.X - 36) / size.X, (viewportSize.Y - 90) / size.Y), 0.5, 1)
	end

	local Frame = fn7("Frame", {
		Name = "Main",
		Size = UDim2.fromOffset(size.X, size.Y),
		Position = tbl2.position or UDim2.new(0.5, -fit * size.X / 2, 0.5, -fit * size.Y / 2),
		BackgroundColor3 = theme.winBot,
		BorderSizePixel = 0,
		ClipsDescendants = true,
	}, ScreenGui)

	obj._fit = fit
	fn8(Frame, 16)
	local color = Color3.fromRGB(216, 100, 245)
	local color2 = Color3.fromRGB(196, 178, 224)

	local UIStroke = fn7("UIStroke", {
		Thickness = 1.6,
		Transparency = 0,
		Color = Color3.fromRGB(255, 255, 255),
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, Frame)

	local numberSequence = NumberSequence.new
	local tbl3 = {}
	local v2 = NumberSequenceKeypoint.new(0, 0.66)
	local v3 = NumberSequenceKeypoint.new(0.15, 0.58)
	local v4 = NumberSequenceKeypoint.new(0.5, 0.18)
	local v5 = NumberSequenceKeypoint.new(0.85, 0.58)
	local new = NumberSequenceKeypoint.new
	tbl3[1] = v2
	tbl3[2] = v3
	tbl3[3] = v4
	tbl3[4] = v5

	do
		local values = table.pack(new(1, 0.66))
		table.move(values, 1, values.n, 5, tbl3)
	end

	local v6 = numberSequence(tbl3)
	local v7 = fn7
	local tbl4 = { Rotation = 0 }
	local colorSequence = ColorSequence.new
	local tbl5 = {}
	local v8 = ColorSequenceKeypoint.new(0, color2)
	local v9 = ColorSequenceKeypoint.new(0.15, color2)
	local v10 = ColorSequenceKeypoint.new(0.5, theme.accent)
	local v11 = ColorSequenceKeypoint.new(0.85, color2)
	local new2 = ColorSequenceKeypoint.new
	tbl5[1] = v8
	tbl5[2] = v9
	tbl5[3] = v10
	tbl5[4] = v11

	do
		local values = table.pack(new2(1, color2))
		table.move(values, 1, values.n, 5, tbl5)
	end

	tbl4.Color = colorSequence(tbl5)
	tbl4.Transparency = v6
	local UIGradient = v7("UIGradient", tbl4, UIStroke)
	obj._glow = { grad = UIGradient, base = color2, transp = v6 }

	fn3(function()
		local n = 0

		while obj.gui and obj.gui.Parent do
			if obj._glowOn == false or not Frame.Visible then
				task.wait(0.15)
			else
				n += 0.02
				UIGradient.Rotation = (UIGradient.Rotation + 0.9) % 360
				local v12 = UIGradient
				local colorSequence2 = ColorSequence.new
				local tbl6 = {}
				local v13 = ColorSequenceKeypoint.new(0, color2)
				local v14 = ColorSequenceKeypoint.new(0.15, color2)
				local v15 = ColorSequenceKeypoint.new(0.5, theme.accent:Lerp(color, 0.3 + 0.3 * math.sin(n)))
				local v16 = ColorSequenceKeypoint.new(0.85, color2)
				local new3 = ColorSequenceKeypoint.new
				tbl6[1] = v13
				tbl6[2] = v14
				tbl6[3] = v15
				tbl6[4] = v16

				do
					local values = table.pack(new3(1, color2))
					table.move(values, 1, values.n, 5, tbl6)
				end

				v12.Color = colorSequence2(tbl6)
				task.wait(0.03)
			end
		end
	end)

	obj._bodyGrad = fn7("UIGradient", { Rotation = 125, Color = ColorSequence.new(theme.winTop, theme.winBot) }, Frame)
	obj.main = Frame
	obj._normalSize = Frame.Size
	local Frame2 = fn7("Frame", { Size = UDim2.new(1, 0, 0, 56), BackgroundColor3 = theme.bar, BorderSizePixel = 0 }, Frame)
	obj._hdr = Frame2
	fn8(Frame2, 16)

	obj._hdrFill = fn7("Frame", {
		Size = UDim2.new(1, 0, 0, 18),
		Position = UDim2.new(0, 0, 1, -18),
		BackgroundColor3 = theme.bar,
		BorderSizePixel = 0,
	}, Frame2)

	fn10(fn7("Frame", {
		Size = UDim2.new(1, 0, 0, 1.5),
		Position = UDim2.new(0, 0, 1, -1.5),
		BackgroundColor3 = theme.accent,
		BackgroundTransparency = 0.13,
		BorderSizePixel = 0,
	}, Frame2), 0, "accent", "cyan")

	local logo = tbl2.logo or index.icons.logo

	if typeof(logo) == "string" and logo:match("rbxassetid") then
		fn7("ImageLabel", {
			Size = UDim2.fromOffset(130, 36),
			Position = UDim2.fromOffset(6, 10),
			BackgroundTransparency = 1,
			Image = logo,
			ScaleType = Enum.ScaleType.Fit,
		}, Frame2)
	else
		local Frame3 = fn7("Frame", {
			Size = UDim2.fromOffset(36, 36),
			Position = UDim2.fromOffset(13, 10),
			BackgroundColor3 = theme.accent,
			BorderSizePixel = 0,
		}, Frame2)

		fn8(Frame3, 11)
		fn10(Frame3, 135, "accent", Color3.fromRGB(109, 40, 217))

		fn7("TextLabel", {
			Size = UDim2.new(1, 0, 1, -1),
			BackgroundTransparency = 1,
			Text = "Vx",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			Font = tbl.disp,
			TextSize = 15,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
		}, Frame3)

		fn7("TextLabel", {
			Size = UDim2.fromOffset(140, 18),
			Position = UDim2.fromOffset(59, 10),
			BackgroundTransparency = 1,
			Text = tbl2.title or "VxSans",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			Font = tbl.disp,
			TextSize = 15,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, Frame2)

		fn7("TextLabel", {
			Size = UDim2.fromOffset(200, 14),
			Position = UDim2.fromOffset(60, 30),
			BackgroundTransparency = 1,
			Text = tbl2.subtitle or "",
			TextColor3 = theme.sub,
			Font = tbl.med,
			TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, Frame2)
	end

	local function fn18(arg2, arg3, arg4)
		local TextButton = fn7("TextButton", {
			Size = UDim2.fromOffset(28, 28),
			Position = UDim2.new(1, arg2, 0.5, -14),
			BackgroundColor3 = arg4 and theme.red or theme.surface,
			BackgroundTransparency = 1,
			Text = "",
			TextColor3 = theme.soft,
			Font = Enum.Font.GothamBold,
			TextSize = 20,
			AutoButtonColor = false,
		}, Frame2)

		fn8(TextButton, 8)
		local v12 = fn12(TextButton, arg3, theme.soft, 14)

		if v12 then
			v12.Position = UDim2.fromOffset(7, 7)
		end

		TextButton.MouseEnter:Connect(fn2(function()
			fn13(TextButton, 0.12, { BackgroundTransparency = arg4 and 0.2 or 0.85 })

			if v12 and v12:IsA("ImageLabel") then
				v12.ImageColor3 = Color3.new(1, 1, 1)
			end
		end))

		TextButton.MouseLeave:Connect(fn2(function()
			fn13(TextButton, 0.12, { BackgroundTransparency = 1 })

			if v12 and v12:IsA("ImageLabel") then
				v12.ImageColor3 = theme.soft
			end
		end))

		fn14(TextButton)
		return TextButton
	end

	local v12 = fn18(-36, "x", true)
	local v13 = fn18(-70, "maximize")
	local v14 = fn18(-104, "minus")

	local TextButton = fn7("TextButton", {
		Size = UDim2.fromOffset(87, 28),
		Position = UDim2.new(1, -204, 0.5, -14),
		BackgroundColor3 = theme.discord,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
	}, Frame2)

	fn8(TextButton, 14)
	obj._disc = TextButton
	local v15 = fn12(TextButton, "discord", Color3.new(1, 1, 1), 15)
	v15.Position = UDim2.fromOffset(11, 6)
	obj._discIco = v15

	local TextLabel = fn7("TextLabel", {
		Size = UDim2.new(1, -40, 1, 0),
		Position = UDim2.fromOffset(31, 0),
		BackgroundTransparency = 1,
		Text = "Discord",
		TextColor3 = Color3.new(1, 1, 1),
		Font = tbl.head,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
	}, TextButton)

	obj._discTexts = { TextLabel }

	TextButton.MouseEnter:Connect(fn2(function()
		fn13(TextButton, 0.12, { BackgroundColor3 = theme.discord:Lerp(Color3.new(1, 1, 1), 0.14) })
	end))

	TextButton.MouseLeave:Connect(fn2(function()
		fn13(TextButton, 0.12, { BackgroundColor3 = theme.discord })
	end))

	TextButton.MouseButton1Click:Connect(fn2(function()
		local discord = tbl2.discord
		if not discord then
			return
		end
		local setclipboard_ = setclipboard or toclipboard or set_clipboard or syn and syn.setclipboard or writeclipboard

		if setclipboard_ then
			pcall(setclipboard_, discord)
			obj:notify("Discord invite copied", "discord", discord)
		else
			obj:notify("Join our Discord", "discord", discord)
		end
	end))

	fn14(TextButton)
	local Frame3 = fn7("Frame", { Size = UDim2.new(1, 0, 1, -84), Position = UDim2.fromOffset(0, 56), BackgroundTransparency = 1 }, Frame)
	obj._body = Frame3

	local Frame4 = fn7("Frame", {
		Size = UDim2.new(0, 162, 1, 0),
		BackgroundColor3 = theme.side,
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
	}, Frame3)

	fn7("Frame", {
		Size = UDim2.new(0, 1, 1, 0),
		Position = UDim2.new(1, -1, 0, 0),
		BackgroundColor3 = theme.border,
		BackgroundTransparency = 0.92,
		BorderSizePixel = 0,
	}, Frame4)

	obj._side = Frame4

	local ScrollingFrame = fn7("ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, -6),
		Position = UDim2.fromOffset(0, 6),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		ScrollBarImageTransparency = 1,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
	}, Frame4)

	fn7("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, ScrollingFrame)
	fn11(ScrollingFrame, 10, 10, 10, 10)
	obj._nav = ScrollingFrame
	scrollbar(ScrollingFrame, Frame4, obj._conns, { inset = 8, right = 4 })

	local Frame5 = fn7("Frame", {
		Size = UDim2.new(1, -162, 1, 0),
		Position = UDim2.fromOffset(162, 0),
		BackgroundColor3 = theme.panel,
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
	}, Frame3)

	obj._content = Frame5

	local Frame6 = fn7("Frame", {
		Size = UDim2.new(1, 0, 0, 28),
		Position = UDim2.new(0, 0, 1, -28),
		BackgroundColor3 = theme.side,
		BorderSizePixel = 0,
	}, Frame)

	fn8(Frame6, 16)

	obj._footFill = fn7("Frame", {
		Size = UDim2.new(1, 0, 0, 16),
		Position = UDim2.new(0, 0, 0, 0),
		BackgroundColor3 = theme.side,
		BorderSizePixel = 0,
	}, Frame6)

	fn7("Frame", {
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = theme.border,
		BackgroundTransparency = 0.92,
		BorderSizePixel = 0,
	}, Frame6)

	obj._foot = Frame6
	local color3 = Color3.fromRGB(52, 219, 137)

	local function fn19(arg2, arg3)
		local Frame7 = fn7("Frame", {
			Size = UDim2.fromOffset(arg2, arg2),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0, 18, 0, 15),
			BackgroundColor3 = color3,
			BackgroundTransparency = arg3,
			BorderSizePixel = 0,
			ZIndex = 1,
		}, Frame6)

		fn8(Frame7, math.floor(arg2 / 2))
		return Frame7
	end

	local v16 = fn19(12, 0.96)
	local v17 = fn19(9, 0.9)

	local Frame7 = fn7("Frame", {
		Size = UDim2.fromOffset(6, 6),
		Position = UDim2.new(0, 15, 0.5, -2),
		BackgroundColor3 = color3,
		BorderSizePixel = 0,
		ZIndex = 2,
	}, Frame6)

	fn8(Frame7, 3)
	obj._statusDot = Frame7
	local tweenInfo = TweenInfo.new(2.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
	TweenService:Create(v16, tweenInfo, { BackgroundTransparency = 0.88 }):Play()
	TweenService:Create(v17, tweenInfo, { BackgroundTransparency = 0.78 }):Play()
	TweenService:Create(Frame7, tweenInfo, { BackgroundColor3 = color3:Lerp(Color3.new(1, 1, 1), 0.1) }):Play()

	local TextLabel2 = fn7("TextLabel", {
		Size = UDim2.new(1, -39, 1, 0),
		Position = UDim2.fromOffset(28, 0),
		BackgroundTransparency = 1,
		Text = "",
		TextColor3 = theme.sub,
		Font = tbl.mono,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		RichText = true,
	}, Frame6)

	obj._region = "…"

	fn3(function()
		local ok, result = pcall(function()
			return LocalizationService:GetCountryRegionForPlayerAsync(localPlayer)
		end)

		if ok and result then
			obj._region = tostring(result)
		end
	end)

	fn3(function()
		fn17(RunService.RenderStepped:Connect(fn2(--[[ VM helper function (reads VM upvalues, emitted verbatim) ]]
		function(H)f[1][3][f[1][5]]+=H;f[2][3][f[2][5]]+=1;if f[1][3][f[1][5]]>=0.5 then f[3][3][f[3][5]],f[1][3][f[1][5]],f[2][3][f[2][5]]=math.floor(f[2][3][f[2][5]]/f[1][3][f[1][5]]+0.5),0,0;end;f[4]._fps=f[3][3][f[3][5]];end)))

		while obj.gui and obj.gui.Parent do
			local n = math.floor((pcall(function()
				return localPlayer:GetNetworkPing()
			end) and localPlayer:GetNetworkPing() or 0) * 1000)

			TextLabel2.Text = ("%s  ·  <b>%d</b>/%d plrs  ·  <b>%d</b> FPS  ·  <b>%d</b>ms  ·  %s  ·  %s"):format(tbl2.subtitle or "Connected", #Players:GetPlayers(), Players.MaxPlayers, obj._fps or 60, n, obj._region, tbl2.version or "v1")
			task.wait(1)
		end
	end)

	local TextButton2 = fn7("TextButton", {
		Size = UDim2.fromOffset(28, 28),
		Position = UDim2.new(1, -26, 1, -26),
		BackgroundTransparency = 1,
		Text = "◢",
		TextColor3 = theme.dim,
		Font = tbl.head,
		TextSize = 13,
		AutoButtonColor = false,
		ZIndex = 6,
	}, Frame)

	obj._grip = TextButton2

	TextButton2.InputBegan:Connect(fn2(--[[ VM helper function (reads VM upvalues, emitted verbatim) ]]
	function(H)if H.UserInputType==Enum.UserInputType.MouseButton1 or H.UserInputType==Enum.UserInputType.Touch then f[1][3][f[1][5]]=true;f[2][3][f[2][5]]=Vector2.new(H.Position.X,H.Position.Y);f[4][3][f[4][5]]=Vector2.new(f[3].Size.X.Offset,f[3].Size.Y.Offset);end;end))

	fn17(UserInputService.InputChanged:Connect(fn2(--[[ VM helper function (reads VM upvalues, emitted verbatim) ]]
	function(H)if f[1][3][f[1][5]]and(H.UserInputType==Enum.UserInputType.MouseMovement or H.UserInputType==Enum.UserInputType.Touch)then local h=(Vector2.new(H.Position.X,H.Position.Y)-f[2][3][f[2][5]])/f[3][3][f[3][5]];f[4].Size=UDim2.fromOffset(math.max(500,f[5][3][f[5][5]].X+h.X),math.max(370,f[5][3][f[5][5]].Y+h.Y));if f[6]._state=="normal"then f[6]._normalSize=f[4].Size;end;end;end)))

	fn17(UserInputService.InputEnded:Connect(fn2(--[[ VM helper function (reads VM upvalues, emitted verbatim) ]]
	function(H)local h=H.UserInputType==Enum.UserInputType.MouseButton1 or H.UserInputType==Enum.UserInputType.Touch;if h then f[1][3][f[1][5]]=false;end;end)))

	obj._collapsed = false

	local function applyTabCollapse(arg2, arg3)
		arg2._lbl.Visible = not arg3
		arg2._ico.Position = arg3 and UDim2.fromOffset(9, 10) or UDim2.fromOffset(12, 10)
	end

	obj._applyTabCollapse = applyTabCollapse

	local function fn20(arg2)
		local collapsed = (arg2 or Frame.AbsoluteSize.X) < 560
		if collapsed == obj._collapsed then
			return
		end
		obj._collapsed = collapsed
		local n = collapsed and 56 or 162
		Frame4.Size = UDim2.new(0, n, 1, 0)
		Frame5.Size = UDim2.new(1, -n, 1, 0)
		Frame5.Position = UDim2.fromOffset(n, 0)

		for _, tab in ipairs(obj.tabs) do
			applyTabCollapse(tab, collapsed)
		end
	end

	Frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(fn2(function()
		fn20()
	end))

	fn20(size.X * fit)

	local Frame8 = fn7("Frame", {
		Name = "Dock",
		Size = UDim2.fromOffset(158, 44),
		Position = Frame.Position,
		BackgroundColor3 = theme.winTop,
		BorderSizePixel = 0,
		Visible = false,
	}, ScreenGui)

	fn8(Frame8, 22)
	fn9(Frame8, "accent", 0.55, 1)

	if typeof(logo) == "string" and logo:match("rbxassetid") then
		fn7("ImageLabel", {
			Size = UDim2.fromOffset(104, 30),
			Position = UDim2.fromOffset(14, 7),
			BackgroundTransparency = 1,
			Image = logo,
			ScaleType = Enum.ScaleType.Fit,
		}, Frame8)
	else
		local Frame9 = fn7("Frame", {
			Size = UDim2.fromOffset(28, 28),
			Position = UDim2.fromOffset(9, 8),
			BackgroundColor3 = theme.accent,
			BorderSizePixel = 0,
		}, Frame8)

		fn8(Frame9, 9)
		fn10(Frame9, 135)

		fn7("TextLabel", {
			Size = UDim2.new(1, 0, 1, -1),
			BackgroundTransparency = 1,
			Text = "Vx",
			TextColor3 = Color3.new(1, 1, 1),
			Font = tbl.disp,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
		}, Frame9)

		fn7("TextLabel", {
			Size = UDim2.fromOffset(78, 44),
			Position = UDim2.fromOffset(44, 0),
			BackgroundTransparency = 1,
			Text = tbl2.title or "VxSans",
			TextColor3 = theme.txt,
			Font = tbl.disp,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, Frame8)
	end

	local TextButton3 = fn7("TextButton", {
		Size = UDim2.fromOffset(28, 28),
		Position = UDim2.new(1, -34, 0.5, -14),
		BackgroundColor3 = theme.surface,
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
	}, Frame8)

	fn8(TextButton3, 8)
	local v18 = fn12(TextButton3, "maximize", theme.soft, 14)
	v18.Position = UDim2.fromOffset(7, 7)

	TextButton3.MouseEnter:Connect(fn2(function()
		fn13(TextButton3, 0.12, { BackgroundTransparency = 0.85 })

		if v18:IsA("ImageLabel") then
			v18.ImageColor3 = Color3.new(1, 1, 1)
		end
	end))

	TextButton3.MouseLeave:Connect(fn2(function()
		fn13(TextButton3, 0.12, { BackgroundTransparency = 1 })

		if v18:IsA("ImageLabel") then
			v18.ImageColor3 = theme.soft
		end
	end))

	fn14(TextButton3)
	fn17(fn16(Frame8, Frame8))
	obj._dock = Frame8
	fn17(fn16(Frame2, Frame))
	local UIScale = fn7("UIScale", { Scale = fit }, Frame)
	obj._mainScale = UIScale
	local UIScale2 = fn7("UIScale", {}, Frame8)
	obj._dockScale = UIScale2
	local dockPos = tbl2.dockPos or UDim2.new(0.5, -79, 1, -60)

	local function fn21(state)
		local state2 = obj._state
		obj._state = state

		if state == "min" then
			obj._preMinPos = Frame.Position
			local tbl6 = { Scale = fit * 0.12 }
			TweenService:Create(UIScale, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.In), tbl6):Play()
			Frame:TweenPosition(dockPos, Enum.EasingDirection.In, Enum.EasingStyle.Quint, 0.28, true)

			fn5(0.28, function()
				if obj._state ~= "min" then
					return
				end
				Frame.Visible = false
				UIScale.Scale = fit
				Frame.Position = obj._preMinPos
				Frame8.Position = dockPos
				UIScale2.Scale = 1
				Frame8.Visible = true
			end)
		elseif state == "max" then
			Frame8.Visible = false
			Frame.Visible = true
			local viewportSize2 = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
			Frame.Size = UDim2.fromOffset(math.min(900, viewportSize2.X - 80), math.min(640, viewportSize2.Y - 80))
			UIScale.Scale = fit * 0.96
			fn13(UIScale, 0.18, { Scale = fit })
		elseif state2 == "min" then
			Frame8.Visible = false
			UIScale2.Scale = 1
			Frame.Size = obj._normalSize
			Frame.Position = dockPos
			UIScale.Scale = fit * 0.12
			Frame.Visible = true
			Frame:TweenPosition(obj._preMinPos or Frame.Position, Enum.EasingDirection.Out, Enum.EasingStyle.Quint, 0.28, true)
			local tbl6 = { Scale = fit }
			TweenService:Create(UIScale, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), tbl6):Play()
		else
			Frame8.Visible = false
			Frame.Visible = true
			Frame.Size = obj._normalSize
			UIScale.Scale = fit * 0.96
			fn13(UIScale, 0.18, { Scale = fit })
		end
	end

	v14.MouseButton1Click:Connect(fn2(function()
		fn21("min")
	end))

	TextButton3.MouseButton1Click:Connect(fn2(function()
		fn21("normal")
	end))

	v13.MouseButton1Click:Connect(fn2(function()
		fn21(obj._state == "max" and "normal" or "max")
	end))

	v12.MouseButton1Click:Connect(fn2(function()
		obj:destroy()
	end))

	obj._toast = fn7("Frame", {
		Size = UDim2.fromOffset(272, 0),
		Position = UDim2.new(0, 14, 1, -14),
		AnchorPoint = Vector2.new(0, 1),
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
	}, ScreenGui)

	fn7("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
	}, obj._toast)

	fn3(function()
		while obj.gui and obj.gui.Parent do
			local q = obj._q

			while #q > 0 do
				pcall(table.remove(q, 1))
			end

			task.wait(0.08)
		end
	end)

	local function fn22()
		UIScale.Scale = fit * 0.95
		fn13(UIScale, 0.22, { Scale = fit }, Enum.EasingStyle.Back)
	end

	obj.reveal = function()
		ScreenGui.Enabled = true
		fn22()

		fn4(function()
			task.wait()
			local v19 = ipairs
			local tabs = obj.tabs or {}

			for _, tab in v19(tabs) do
				local page = tab._page

				if page and page.Parent and page.Visible then
					page.Visible = false
					RunService.Heartbeat:Wait()

					if page.Parent then
						page.Visible = true
					end
				end
			end
		end)
	end

	local genv = getgenv and getgenv() or _G

	if genv.VXSANS_BOOTING then
		ScreenGui.Enabled = false
		genv.VXSANS_REVEAL = obj.reveal
	else
		fn22()
	end

	return obj
end

index.setHidden = function(arg, arg2)
	local hidden = arg2 and true or false
	if arg._hidden == hidden then
		return
	end
	arg._hidden = hidden
	local flag = arg._state == "min"
	local dock = flag and arg._dock or arg.main
	local dockScale = flag and arg._dockScale or arg._mainScale
	flag = flag and 1 or arg._fit or 1
	if not dock then
		return
	end

	if hidden then
		arg._savedScroll = {}
		local v = ipairs
		local tabs = arg.tabs or {}

		for _, tab in v(tabs) do
			if tab._page then
				arg._savedScroll[tab._page] = tab._page.CanvasPosition
			end
		end

		if dockScale then
			TweenService:Create(dockScale, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = flag * 0.1 }):Play()
		end

		fn5(0.22, function()
			if arg._hidden then
				dock.Visible = false
			end
		end)
	else
		if dockScale then
			dockScale.Scale = flag * 0.1
		end

		dock.Visible = true
		local tween = dockScale and TweenService:Create(dockScale, TweenInfo.new(0.24, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = flag }) or nil

		if tween then
			tween:Play()
		end

		local savedScroll = arg._savedScroll

		local function fn17()
			pcall(function()
				if not savedScroll then
					return
				end

				for k, v in pairs(savedScroll) do
					if k and k.Parent then
						k.CanvasPosition = v
					end
				end
			end)
		end

		if tween then
			tween.Completed:Connect(fn2(fn17))
		end

		fn5(0.28, fn17)
	end
end

index.setAccent = function(arg, accent)
	if typeof(accent) ~= "Color3" then
		return
	end
	theme.accent = accent
	theme.accent2 = accent:Lerp(Color3.new(1, 1, 1), 0.32)
	if not arg.gui then
		return
	end

	for _, descendant in ipairs(arg.gui:GetDescendants()) do
		if descendant:IsA("UIGradient") then
			local attribute = descendant:GetAttribute("vxC1")

			if attribute then
				descendant.Color = ColorSequence.new(fn6(attribute), fn6(descendant:GetAttribute("vxC2") or "accent2"))
			end
		elseif descendant:IsA("UIStroke") then
			local attribute = descendant:GetAttribute("vxCol")

			if attribute then
				descendant.Color = fn6(attribute)
			end
		elseif descendant:IsA("ImageLabel") then
			local attribute = descendant:GetAttribute("vxImg")

			if attribute then
				descendant.ImageColor3 = fn6(attribute)
			end
		elseif descendant:IsA("ScrollingFrame") then
			descendant.ScrollBarImageColor3 = theme.accent
		else
			local attribute = descendant:GetAttribute("vxBg")

			if attribute then
				descendant.BackgroundColor3 = fn6(attribute)
			end
		end

		local attribute = descendant:GetAttribute("vxTxt")

		if attribute and (descendant:IsA("TextLabel") or descendant:IsA("TextButton") or descendant:IsA("TextBox")) then
			descendant.TextColor3 = fn6(attribute)
		end
	end

	if arg._bodyGrad and not arg._bg then
		arg._bodyGrad.Color = ColorSequence.new(theme.winTop:Lerp(accent, 0.05), theme.winBot:Lerp(accent, 0.08))
	end

	if arg._accentCbs then
		for _, accentCb in ipairs(arg._accentCbs) do
			pcall(accentCb, theme.accent, theme.accent2)
		end
	end
end

index.onAccent = function(arg, arg2)
	arg._accentCbs = arg._accentCbs or {}
	table.insert(arg._accentCbs, arg2)
	return arg2
end

local tbl2 = { glass = 0.028, surface = 0.055, surface2 = 0.092, border = 0.16 }

local function fn17(arg, arg2)
	return arg:Lerp(Color3.new(1, 1, 1), tbl2[arg2] or 0.05)
end

index.onBg = function(arg, arg2)
	arg._bgCbs = arg._bgCbs or {}
	table.insert(arg._bgCbs, arg2)
	return arg2
end

index.setBg = function(arg, arg2)
	if typeof(arg2) ~= "Color3" then
		return
	end
	local color = Color3.new(1, 1, 1)
	local color2 = Color3.new(0, 0, 0)
	local v = arg2:Lerp(color2, 0.86)
	arg._bg = v
	local v2 = v:Lerp(color, 0.08)
	local v3 = v:Lerp(color2, 0.25)

	if arg.main then
		arg.main.BackgroundColor3 = v
	end

	if arg._bodyGrad then
		arg._bodyGrad.Color = ColorSequence.new(v:Lerp(color, 0.05), v)
	end

	if arg._hdr then
		arg._hdr.BackgroundColor3 = v2
	end

	if arg._hdrFill then
		arg._hdrFill.BackgroundColor3 = v2
	end

	if arg._side then
		arg._side.BackgroundColor3 = v3
	end

	if arg._content then
		arg._content.BackgroundColor3 = v:Lerp(color, 0.03)
	end

	if arg._foot then
		arg._foot.BackgroundColor3 = v3
	end

	if arg._footFill then
		arg._footFill.BackgroundColor3 = v3
	end

	local tbl3 = {
		surface = fn17(v, "surface"),
		surface2 = fn17(v, "surface2"),
		glass = fn17(v, "glass"),
		border = fn17(v, "border"),
	}

	if arg.gui then
		for _, descendant in ipairs(arg.gui:GetDescendants()) do
			local attribute = descendant:GetAttribute("vxSurf")

			if attribute and tbl3[attribute] and descendant:IsA("GuiObject") then
				descendant.BackgroundColor3 = tbl3[attribute]
			end
		end
	end

	if arg._bgCbs then
		for _, bgCb in ipairs(arg._bgCbs) do
			pcall(bgCb, tbl3)
		end
	end
end

index.resetBg = function(arg)
	arg._bg = nil

	if arg.main then
		arg.main.BackgroundColor3 = theme.winBot
	end

	if arg._bodyGrad then
		arg._bodyGrad.Color = ColorSequence.new(theme.winTop, theme.winBot)
	end

	if arg._hdr then
		arg._hdr.BackgroundColor3 = theme.bar
	end

	if arg._hdrFill then
		arg._hdrFill.BackgroundColor3 = theme.bar
	end

	if arg._side then
		arg._side.BackgroundColor3 = theme.side
	end

	if arg._content then
		arg._content.BackgroundColor3 = theme.panel
	end

	if arg._foot then
		arg._foot.BackgroundColor3 = theme.side
	end

	if arg._footFill then
		arg._footFill.BackgroundColor3 = theme.side
	end

	if arg.gui then
		for _, descendant in ipairs(arg.gui:GetDescendants()) do
			if descendant:GetAttribute("vxSurf") then
				local attribute = descendant:GetAttribute("vxSurf0")

				if typeof(attribute) == "Color3" then
					descendant.BackgroundColor3 = attribute
				end
			end
		end
	end

	if arg._bgCbs then
		for _, bgCb in ipairs(arg._bgCbs) do
			pcall(bgCb, nil)
		end
	end
end

index.setGlow = function(arg, arg2)
	arg._glowOn = arg2 and true or false
	local glow = arg._glow
	if not glow then
		return
	end

	if arg2 then
		glow.grad.Transparency = glow.transp
	else
		glow.grad.Rotation = 0
		glow.grad.Color = ColorSequence.new(glow.base)
		glow.grad.Transparency = NumberSequence.new(0.62)
	end
end

index.resetControls = function(arg)
	for _, control in ipairs(arg._controls) do
		pcall(control)
	end
end

index.onClose = function(arg, arg2)
	if type(arg2) == "function" then
		arg._onClose[#arg._onClose + 1] = arg2
	end
end

index.destroy = function(arg)
	if arg._destroyed then
		return
	end
	arg._destroyed = true
	local gui = arg.gui

	if gui then
		pcall(function()
			local vxNukeQ = getgenv and getgenv().__vxNukeQ

			if vxNukeQ then
				table.insert(vxNukeQ, gui)
			end
		end)

		pcall(function()
			gui.Enabled = false
		end)

		pcall(function()
			gui:Destroy()
		end)

		local flag = true

		pcall(function()
			flag = gui.Parent ~= nil
		end)

		if flag then
			pcall(function()
				gui.Parent = nil
			end)
		end
	end

	for _, v in ipairs(arg._onClose) do
		pcall(v)
	end

	for _, conn in ipairs(arg._conns) do
		pcall(function()
			conn:Disconnect()
		end)
	end

	arg._conns = {}

	pcall(function()
		UserInputService.MouseIcon = ""
	end)

	if arg.gui then
		local gui2 = arg.gui

		pcall(function()
			local vxNukeQ = getgenv and getgenv().__vxNukeQ

			if vxNukeQ then
				table.insert(vxNukeQ, gui2)
			end
		end)

		pcall(function()
			gui2.Enabled = false
		end)

		pcall(function()
			gui2:Destroy()
		end)

		local flag = true

		pcall(function()
			flag = gui2.Parent ~= nil
		end)

		if flag then
			pcall(function()
				gui2.Parent = nil
			end)
		end

		arg.gui = nil
	end
end

index.setCompact = function(arg, arg2)
	arg._compact = arg2 and true or false

	for _, tab in ipairs(arg.tabs) do
		for _, desc in ipairs(tab._descs) do
			desc.Visible = not arg._compact
		end
	end
end

index.tab = function(arg, arg2, arg3)
	arg._order = arg._order + 1

	local TextButton = fn7("TextButton", {
		Size = UDim2.new(1, 0, 0, 38),
		BackgroundColor3 = theme.accent,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		LayoutOrder = arg._order,
	}, arg._nav)

	fn8(TextButton, 10)

	local Frame = fn7("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = theme.surface,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 0,
	}, TextButton)

	fn8(Frame, 10)
	local v = fn12(TextButton, arg3, theme.sub, 18)
	v.Position = UDim2.fromOffset(12, 10)
	v.ZIndex = 2

	local TextLabel = fn7("TextLabel", {
		Size = UDim2.new(1, -42, 1, 0),
		Position = UDim2.fromOffset(40, 0),
		BackgroundTransparency = 1,
		Text = arg2,
		TextColor3 = theme.soft,
		Font = tbl.med,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 2,
	}, TextButton)

	local ScrollingFrame = fn7("ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		ScrollBarImageTransparency = 1,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Visible = false,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ElasticBehavior = Enum.ElasticBehavior.Never,
	}, arg._content)

	fn7("UIListLayout", { Padding = UDim.new(0, 16), SortOrder = Enum.SortOrder.LayoutOrder }, ScrollingFrame)
	fn11(ScrollingFrame, 14, 14, 14, 12)
	scrollbar(ScrollingFrame, arg._content, arg._conns, { inset = 12, right = 5 })

	local tbl3 = {
		_page = ScrollingFrame,
		_btn = TextButton,
		_lbl = TextLabel,
		_ico = v,
		_sel = Frame,
		_order = 0,
		_descs = {},
		_lib = arg,
		_body = nil,
	}

	local function fn18()
		for _, tab in ipairs(arg.tabs) do
			tab._page.Visible = false
			tab._sel.BackgroundTransparency = 1
			tab._lbl.TextColor3 = theme.soft

			if tab._ico:IsA("ImageLabel") then
				tab._ico.ImageColor3 = theme.sub
			end
		end

		ScrollingFrame.Visible = true
		Frame.BackgroundTransparency = 0.9
		TextLabel.TextColor3 = Color3.new(1, 1, 1)

		if v:IsA("ImageLabel") then
			v.ImageColor3 = Color3.new(1, 1, 1)
		end

		ScrollingFrame.Position = UDim2.fromOffset(0, 10)
		local out = Enum.EasingDirection.Out
		local quad = Enum.EasingStyle.Quad
		ScrollingFrame:TweenPosition(UDim2.new(0, 0, 0, 0), out, quad, 0.17, true)
	end

	TextButton.MouseButton1Click:Connect(fn2(fn18))

	TextButton.MouseEnter:Connect(fn2(function()
		if not ScrollingFrame.Visible then
			TextLabel.TextColor3 = theme.txt
			fn13(Frame, 0.14, { BackgroundTransparency = 0.955 })
		end
	end))

	TextButton.MouseLeave:Connect(fn2(function()
		if not ScrollingFrame.Visible then
			TextLabel.TextColor3 = theme.soft
			fn13(Frame, 0.14, { BackgroundTransparency = 1 })
		end
	end))

	fn14(TextButton)
	table.insert(arg.tabs, tbl3)

	if arg._applyTabCollapse then
		arg._applyTabCollapse(tbl3, arg._collapsed)
	end

	if #arg.tabs == 1 then
		fn18()
	end

	local function fn19()
		return tbl3._body or ScrollingFrame
	end

	local function fn20()
		local forceOrder = tbl3._forceOrder
		tbl3._forceOrder = nil
		if forceOrder ~= nil then
			return forceOrder
		end
		tbl3._order = tbl3._order + 1
		return tbl3._order
	end

	local function fn21(arg4)
		local Frame2 = fn7("Frame", {
			Size = UDim2.new(1, 0, 0, arg4 or 48),
			BackgroundColor3 = theme.surface,
			BackgroundTransparency = 0.94,
			BorderSizePixel = 0,
			LayoutOrder = fn20(),
		}, fn19())

		fn8(Frame2, 12)
		fn9(Frame2, "border", 0.9)

		local Frame3 = fn7("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = theme.surface,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 0,
		}, Frame2)

		fn8(Frame3, 12)

		Frame2.MouseEnter:Connect(fn2(function()
			fn13(Frame3, 0.14, { BackgroundTransparency = 0.955 })
		end))

		Frame2.MouseLeave:Connect(fn2(function()
			fn13(Frame3, 0.14, { BackgroundTransparency = 1 })
		end))

		return Frame2
	end

	local function fn22(arg4, arg5, arg6)
		local n = arg6 or 62
		local n2 = 12
		local Frame2 = nil

		if arg5.icon ~= false then
			Frame2 = fn7("Frame", {
				Size = UDim2.fromOffset(32, 32),
				Position = UDim2.new(0, 12, 0.5, -16),
				BackgroundColor3 = fn6(arg5.iconBg or "accent"),
				BackgroundTransparency = 0.85,
				BorderSizePixel = 0,
			}, arg4)

			if (arg5.iconBg or "accent") == "accent" then
				Frame2:SetAttribute("vxBg", "accent")
			end

			fn8(Frame2, 9)
			fn9(Frame2, arg5.iconBg or "accent", 0.78)
			fn12(Frame2, arg5.icon, arg5.iconBg or "accent2", 18).Position = UDim2.fromOffset(7, 7)

			if arg5.premium then
				local Frame3 = fn7("Frame", {
					Size = UDim2.fromOffset(17, 17),
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.new(1, -3, 0, 3),
					BackgroundColor3 = theme.bar,
					BorderSizePixel = 0,
					ZIndex = 6,
				}, Frame2)

				fn8(Frame3, 9)
				fn9(Frame3, "gold", 0.35)
				local v2 = fn12(Frame3, "crown", "gold", 11)
				v2.Position = UDim2.fromOffset(3, 3)
				v2.ZIndex = 7
			end

			n2 = 54
		end

		fn7("TextLabel", {
			Size = UDim2.new(1, -(n2 + n), 0, arg5.desc and 16 or 32),
			Position = UDim2.fromOffset(n2, arg5.desc and 7 or 0),
			BackgroundTransparency = 1,
			Text = arg5.name,
			TextColor3 = theme.txt,
			Font = tbl.head,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
		}, arg4)

		if arg5.desc then
			local TextLabel2 = fn7("TextLabel", {
				Size = UDim2.new(1, -(n2 + n), 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				Position = UDim2.fromOffset(n2, 25),
				BackgroundTransparency = 1,
				Text = arg5.desc,
				TextColor3 = theme.sub,
				Font = tbl.med,
				TextSize = 11,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
				TextWrapped = true,
			}, arg4)

			TextLabel2.Visible = not arg._compact
			table.insert(tbl3._descs, TextLabel2)
			arg4.AutomaticSize = Enum.AutomaticSize.Y
			fn7("UISizeConstraint", { MinSize = Vector2.new(0, 48) }, arg4)
		end

		return Frame2
	end

	tbl3.section = function(arg4, arg5)
		local Frame2 = fn7("Frame", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			LayoutOrder = fn20(),
		}, ScrollingFrame)

		fn7("UIListLayout", { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder }, Frame2)

		local TextButton2 = fn7("TextButton", {
			Size = UDim2.new(1, 0, 0, 20),
			BackgroundTransparency = 1,
			Text = "",
			AutoButtonColor = false,
			LayoutOrder = 0,
		}, Frame2)

		fn7("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 9),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, TextButton2)

		fn7("TextLabel", {
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.new(0, 0, 1, 0),
			BackgroundTransparency = 1,
			Text = tostring(arg5):upper(),
			TextColor3 = theme.dim,
			Font = tbl.mono,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			LayoutOrder = 0,
		}, TextButton2)

		local Frame3 = fn7("Frame", {
			Size = UDim2.new(0, 0, 0, 1),
			BackgroundColor3 = theme.border,
			BackgroundTransparency = 0.8,
			BorderSizePixel = 0,
			LayoutOrder = 1,
		}, TextButton2)

		fn7("UIFlexItem", { FlexMode = Enum.UIFlexMode.Fill }, Frame3)
		local new = NumberSequenceKeypoint.new
		fn7("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), new(1, 0.6) }) }, Frame3)

		local TextLabel2 = fn7("TextLabel", {
			Size = UDim2.fromOffset(16, 16),
			BackgroundTransparency = 1,
			Text = "▼",
			TextColor3 = theme.sub,
			Font = tbl.head,
			TextSize = 12,
			LayoutOrder = 2,
		}, TextButton2)

		local Frame4 = fn7("Frame", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			LayoutOrder = 1,
		}, Frame2)

		fn7("UIListLayout", { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder }, Frame4)
		local visible = true

		TextButton2.MouseButton1Click:Connect(fn2(function()
			visible = not visible
			Frame4.Visible = visible
			TextLabel2.Text = visible and "▼" or "▶"
		end))

		tbl3._body = Frame4

		return { collapse = function()
			visible = false
			Frame4.Visible = false
			TextLabel2.Text = "▶"
		end }
	end

	tbl3.subtabs = function(arg4, arg5)
		local names = arg5.names or arg5
		local onChange = arg5.onChange

		local Frame2 = fn7("Frame", {
			Size = UDim2.new(1, 0, 0, 34),
			BackgroundColor3 = theme.surface,
			BackgroundTransparency = 0.965,
			BorderSizePixel = 0,
			LayoutOrder = fn20(),
		}, fn19())

		fn8(Frame2, 10)
		fn9(Frame2, "border", 0.92)
		fn11(Frame2, 4, 4, 4, 4)

		fn7("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 4),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, Frame2)

		local tbl4 = {}
		local n = 1

		local function fn23()
			for i, v2 in ipairs(tbl4) do
				v2.BackgroundTransparency = i == n and 0.15 or 1
				v2.TextColor3 = i == n and Color3.new(1, 1, 1) or theme.sub
			end
		end

		for i, name in ipairs(names) do
			local TextButton2 = fn7("TextButton", {
				Size = UDim2.new(1 / #names, -4 * (#names - 1) / #names, 1, 0),
				BackgroundColor3 = theme.accent,
				BackgroundTransparency = 1,
				Text = name,
				TextColor3 = theme.sub,
				Font = tbl.med,
				TextSize = 12.5,
				AutoButtonColor = false,
				LayoutOrder = i,
			}, Frame2)

			fn8(TextButton2, 8)
			fn10(TextButton2, 90)

			TextButton2.MouseButton1Click:Connect(fn2(function()
				n = i
				fn23()

				if onChange then
					pcall(onChange, i, name)
				end
			end))

			tbl4[i] = TextButton2
		end

		fn23()

		return {
			set = function(arg6)
				n = math.clamp(arg6, 1, #tbl4)
				fn23()

				if onChange then
					pcall(onChange, n, names[n])
				end
			end,
			get = function()
				return n
			end,
		}
	end

	tbl3.label = function(arg4, arg5, arg6)
		return fn7("TextLabel", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Text = arg5,
			TextColor3 = fn6(arg6 or "sub"),
			Font = tbl.body,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			LayoutOrder = fn20(),
		}, fn19())
	end

	tbl3.swatches = function(arg4, arg5)
		if arg5.locked then
			local v2 = fn21()
			fn22(v2, arg5, 118)

			local TextButton2 = fn7("TextButton", {
				Size = UDim2.fromOffset(96, 30),
				Position = UDim2.new(1, -108, 0.5, -15),
				BackgroundColor3 = theme.well,
				BackgroundTransparency = 0.25,
				Text = "Premium",
				TextColor3 = theme.gold,
				Font = tbl.head,
				TextSize = 12,
				BorderSizePixel = 0,
				AutoButtonColor = false,
			}, v2)

			fn8(TextButton2, 8)
			fn9(TextButton2, "gold", 0.5)

			TextButton2.MouseButton1Click:Connect(fn2(function()
				if arg5.onLocked then
					pcall(arg5.onLocked)
				end
			end))

			fn14(TextButton2)
			return {}
		end

		local v2 = fn21(48)
		local v3 = fn22(v2, arg5, 8)

		if v3 then
			v3.Position = UDim2.fromOffset(12, 8)
		end

		local Frame2 = fn7("Frame", {
			Size = UDim2.new(1, -24, 0, 0),
			Position = UDim2.fromOffset(12, 50),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
		}, v2)

		local fit = arg4._fit or 1

		Frame2:GetPropertyChangedSignal("AbsoluteSize"):Connect(fn2(function()
			v2.Size = UDim2.new(1, 0, 0, 50 + Frame2.AbsoluteSize.Y / fit + 12)
		end))

		fn7("UIGridLayout", {
			CellSize = UDim2.fromOffset(26, 26),
			CellPadding = UDim2.fromOffset(9, 9),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, Frame2)

		local tbl4 = {}
		local v4 = nil

		local function fn23(arg6)
			v4 = arg6

			for i, v5 in ipairs(tbl4) do
				local flag = i == arg6
				local uiStroke = v5:FindFirstChildOfClass("UIStroke")

				if uiStroke then
					uiStroke.Transparency = flag and 0 or 1
				end

				local uiScale = v5:FindFirstChildOfClass("UIScale")

				if uiScale then
					fn13(uiScale, 0.12, { Scale = flag and 1.14 or 1 })
				end
			end
		end

		local v5 = ipairs
		local colors = arg5.colors or {}

		for k, color in v5(colors) do
			local TextButton2 = fn7("TextButton", {
				BackgroundColor3 = color,
				Text = "",
				AutoButtonColor = false,
				BorderSizePixel = 0,
				LayoutOrder = k,
			}, Frame2)

			fn8(TextButton2, 13)
			local UIScale = fn7("UIScale", { Parent = TextButton2 })
			fn7("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 3, Transparency = 1 }, TextButton2)

			TextButton2.MouseButton1Click:Connect(fn2(function()
				fn23(k)

				if arg5.onPick then
					pcall(arg5.onPick, color, k)
				end
			end))

			TextButton2.MouseEnter:Connect(fn2(function()
				if v4 ~= k then
					fn13(UIScale, 0.1, { Scale = 1.22 })
				end
			end))

			TextButton2.MouseLeave:Connect(fn2(function()
				if v4 ~= k then
					fn13(UIScale, 0.1, { Scale = 1 })
				end
			end))

			fn14(TextButton2)
			tbl4[k] = TextButton2
		end

		if arg5.default and tbl4[arg5.default] then
			fn23(arg5.default)
		end

		return { set = function(arg6)
			fn23(arg6)
		end }
	end

	tbl3.toggle = function(arg4, arg5)
		local enabled = arg5.default and true or false
		local v2 = fn21()
		local v3 = fn22(v2, arg5)
		local uiStroke = v2:FindFirstChildOfClass("UIStroke")
		local uiStroke2 = v3 and v3:FindFirstChildOfClass("UIStroke")

		local TextButton2 = fn7("TextButton", {
			Size = UDim2.fromOffset(46, 25),
			Position = UDim2.new(1, -58, 0.5, -12.5),
			BackgroundColor3 = theme.surface,
			BackgroundTransparency = enabled and 0 or 0.88,
			Text = "",
			BorderSizePixel = 0,
			AutoButtonColor = false,
		}, v2)

		fn8(TextButton2, 13)
		local v4 = fn10(TextButton2, 0)
		v4.Enabled = enabled
		local v5 = fn9(TextButton2, "accent", 0.4)
		v5.Enabled = enabled

		local Frame2 = fn7("Frame", {
			Size = UDim2.fromOffset(19, 19),
			Position = enabled and UDim2.fromOffset(24, 3) or UDim2.fromOffset(3, 3),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BorderSizePixel = 0,
		}, TextButton2)

		fn8(Frame2, 10)

		TextButton2.MouseEnter:Connect(fn2(function()
			if enabled then
				fn13(v5, 0.12, { Transparency = 0.05 })
			else
				fn13(TextButton2, 0.12, { BackgroundTransparency = 0.76 })
			end
		end))

		TextButton2.MouseLeave:Connect(fn2(function()
			if enabled then
				fn13(v5, 0.12, { Transparency = 0.4 })
			else
				fn13(TextButton2, 0.12, { BackgroundTransparency = 0.88 })
			end
		end))

		local Frame3 = nil

		if arg5.sub then
			v2.AutomaticSize = Enum.AutomaticSize.Y

			if v3 then
				v3.Position = UDim2.fromOffset(12, 8)
			end

			TextButton2.Position = UDim2.new(1, -58, 0, 11.5)

			Frame3 = fn7("Frame", {
				Size = UDim2.new(1, -20, 0, 0),
				Position = UDim2.fromOffset(10, 50),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				Visible = enabled,
			}, v2)

			fn7("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, Frame3)
			fn7("UIPadding", { PaddingBottom = UDim.new(0, 10) }, Frame3)
			local body = tbl3._body
			tbl3._body = Frame3
			pcall(arg5.sub, tbl3)
			tbl3._body = body

			for _, child in ipairs(Frame3:GetChildren()) do
				if child:IsA("Frame") or child:IsA("TextButton") then
					child.BackgroundColor3 = theme.well
					child.BackgroundTransparency = 0.35
					local uiStroke3 = child:FindFirstChildOfClass("UIStroke")

					if uiStroke3 then
						uiStroke3.Transparency = 0.93
					end
				end
			end
		end

		local function fn23()
			v4.Enabled = enabled
			v5.Enabled = enabled
			fn13(TextButton2, 0.14, { BackgroundTransparency = enabled and 0 or 0.88 })
			Frame2:TweenPosition(enabled and UDim2.fromOffset(24, 3) or UDim2.fromOffset(3, 3), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.14, true)

			if uiStroke then
				uiStroke:SetAttribute("vxCol", enabled and "accent" or nil)
				fn13(uiStroke, 0.18, { Color = enabled and fn6("accent") or theme.border, Transparency = enabled and 0.4 or 0.9 })
			end

			v2:SetAttribute("vxBg", enabled and "accent" or nil)

			fn13(v2, 0.18, {
				BackgroundColor3 = enabled and fn6("accent") or theme.surface,
				BackgroundTransparency = enabled and 0.9 or 0.94,
			})

			if v3 then
				fn13(v3, 0.18, { BackgroundTransparency = enabled and 0.72 or 0.85 })
			end

			if uiStroke2 then
				fn13(uiStroke2, 0.18, { Transparency = enabled and 0.45 or 0.78 })
			end

			if Frame3 then
				Frame3.Visible = enabled
			end
		end

		fn23()

		arg4._lib:onAccent(function()
			pcall(fn23)
		end)

		TextButton2.MouseButton1Click:Connect(fn2(function()
			enabled = not enabled
			fn23()

			if arg5.onChange then
				pcall(arg5.onChange, enabled)
			end
		end))

		fn14(TextButton2)

		local tbl4 = {
			get = function()
				return enabled
			end,
			set = function(arg6)
				local flag = arg6 and true or false

				if flag ~= enabled then
					enabled = flag
					fn23()
				end
			end,
		}

		tbl3._lib._controls[#tbl3._lib._controls + 1] = function()
			local flag = (arg5.reset ~= nil and arg5.reset or arg5.default) and true or false
			tbl4.set(flag)

			if arg5.onChange then
				pcall(arg5.onChange, flag)
			end
		end

		return tbl4
	end

	tbl3.button = function(arg4, arg5)
		local v2 = fn21()
		fn22(v2, arg5, 88)
		local v3 = fn6(arg5.color or "accent")

		local TextButton2 = fn7("TextButton", {
			Size = UDim2.fromOffset(66, 30),
			Position = UDim2.new(1, -78, 0.5, -15),
			BackgroundColor3 = v3,
			Text = arg5.action or "Go",
			TextColor3 = Color3.new(1, 1, 1),
			Font = tbl.head,
			TextSize = 12.5,
			BorderSizePixel = 0,
			AutoButtonColor = false,
		}, v2)

		fn8(TextButton2, 9)

		if (arg5.color or "accent") == "accent" then
			TextButton2:SetAttribute("vxBg", "accent")
		end

		TextButton2.MouseEnter:Connect(fn2(function()
			local v4 = TextButton2
			local v5 = theme[(arg5.color or "accent") .. "2"]

			if not v5 then
				v5 = fn6(arg5.color or "accent"):Lerp(Color3.new(1, 1, 1), 0.14)
			end

			v4.BackgroundColor3 = v5
		end))

		TextButton2.MouseLeave:Connect(fn2(function()
			TextButton2.BackgroundColor3 = fn6(arg5.color or "accent")
		end))

		TextButton2.MouseButton1Click:Connect(fn2(function()
			if arg5.onClick then
				pcall(arg5.onClick)
			end
		end))

		fn14(TextButton2)
		return TextButton2
	end

	tbl3.input = function(arg4, arg5)
		local v2 = fn21()
		fn22(v2, arg5, 96)

		local TextBox = fn7("TextBox", {
			Size = UDim2.fromOffset(74, 30),
			Position = UDim2.new(1, -86, 0.5, -15),
			BackgroundColor3 = theme.well,
			BackgroundTransparency = 0.25,
			Text = tostring(arg5.default or ""),
			PlaceholderText = arg5.placeholder or "…",
			PlaceholderColor3 = theme.dim,
			TextColor3 = theme.txt,
			Font = tbl.head,
			TextSize = 12.5,
			ClearTextOnFocus = false,
			BorderSizePixel = 0,
		}, v2)

		fn8(TextBox, 8)
		local v3 = fn9(TextBox, "border", 0.9)

		TextBox.Focused:Connect(fn2(function()
			v3.Color = theme.accent
			v3.Transparency = 0.4
		end))

		TextBox.FocusLost:Connect(fn2(function()
			v3.Color = theme.border
			v3.Transparency = 0.9

			if arg5.onCommit then
				pcall(arg5.onCommit, TextBox.Text)
			end
		end))

		local tbl4 = {
			get = function()
				return TextBox.Text
			end,
			set = function(arg6)
				TextBox.Text = tostring(arg6)
			end,
		}

		tbl3._lib._controls[#tbl3._lib._controls + 1] = function()
			local str = tostring(arg5.reset ~= nil and arg5.reset or arg5.default or "")
			tbl4.set(str)

			if arg5.onCommit then
				pcall(arg5.onCommit, str)
			end
		end

		return tbl4
	end

	tbl3.dropdown = function(arg4, arg5)
		local options = arg5.options or {}
		local n = math.clamp(arg5.default or 1, 1, math.max(1, #options))
		local v2 = fn21()
		fn22(v2, arg5, 152)

		local TextButton2 = fn7("TextButton", {
			Size = UDim2.fromOffset(132, 30),
			Position = UDim2.new(1, -144, 0.5, -15),
			BackgroundColor3 = theme.well,
			BackgroundTransparency = 0.25,
			Text = "  " .. tostring(options[n] or "—"),
			TextColor3 = theme.txt,
			Font = tbl.head,
			TextSize = 12.5,
			BorderSizePixel = 0,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			AutoButtonColor = false,
		}, v2)

		fn8(TextButton2, 8)
		fn9(TextButton2, "border", 0.9)

		fn7("TextLabel", {
			Size = UDim2.fromOffset(16, 16),
			Position = UDim2.new(1, -14, 0.5, -8),
			BackgroundTransparency = 1,
			Text = "▼",
			TextColor3 = theme.soft,
			Font = tbl.head,
			TextSize = 12,
		}, TextButton2)

		local function fn23()
			TextButton2.Text = "  " .. tostring(options[n] or "—")

			if arg5.onChange then
				pcall(arg5.onChange, n, options[n])
			end
		end

		TextButton2.MouseButton1Click:Connect(fn2(function()
			if #options > 0 then
				n = n % #options + 1
				fn23()
			end
		end))

		fn14(TextButton2)

		local tbl4 = {
			get = function()
				return n, options[n]
			end,
			set = function(arg6)
				n = math.clamp(arg6, 1, math.max(1, #options))
				fn23()
			end,
			setOptions = function(arg6)
				options = arg6 or {}
				n = math.clamp(n, 1, math.max(1, #options))
				fn23()
			end,
		}

		tbl3._lib._controls[#tbl3._lib._controls + 1] = function()
			tbl4.set(arg5.reset ~= nil and arg5.reset or arg5.default or 1)
		end

		return tbl4
	end

	tbl3.slider = function(arg4, arg5)
		local min = arg5.min or 0
		local max = arg5.max or 100
		local n = math.clamp(arg5.default or min, min, max)

		local function fn23(arg6)
			return (arg5.format and tostring(arg5.format(arg6)) or tostring(arg6)) .. (arg5.suffix or "")
		end

		local v2 = fn21(46)

		fn7("TextLabel", {
			Size = UDim2.new(1, -70, 0, 18),
			Position = UDim2.fromOffset(12, 6),
			BackgroundTransparency = 1,
			Text = arg5.name,
			TextColor3 = theme.txt,
			Font = tbl.head,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, v2)

		local TextLabel2 = fn7("TextLabel", {
			Size = UDim2.fromOffset(54, 18),
			Position = UDim2.new(1, -62, 0, 6),
			BackgroundTransparency = 1,
			Text = fn23(n),
			TextColor3 = theme.accent2,
			Font = tbl.head,
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Right,
		}, v2)

		TextLabel2:SetAttribute("vxTxt", "accent2")

		local TextButton2 = fn7("TextButton", {
			Size = UDim2.new(1, -24, 0, 8),
			Position = UDim2.fromOffset(12, 30),
			BackgroundColor3 = theme.surface,
			BackgroundTransparency = 0.86,
			Text = "",
			AutoButtonColor = false,
			BorderSizePixel = 0,
		}, v2)

		fn8(TextButton2, 4)

		local Frame2 = fn7("Frame", {
			Size = UDim2.fromScale((n - min) / (max - min), 1),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
		}, TextButton2)

		fn8(Frame2, 4)
		fn10(Frame2, 0, "accent", "accent2")

		local function fn24()
			return max > min and (n - min) / (max - min) or 0
		end

		local n2 = 16

		local function fn25(arg6)
			return UDim2.new(arg6, math.floor((0.5 - arg6) * n2 + 0.5), 0.5, 0)
		end

		local v3 = fn7
		local tbl4 = { Size = UDim2.fromOffset(16, 16), AnchorPoint = Vector2.new(0.5, 0.5) }
		local v4 = fn24()
		tbl4.Position = fn25(v4)
		tbl4.BackgroundColor3 = Color3.new(1, 1, 1)
		tbl4.BorderSizePixel = 0
		tbl4.ZIndex = 3
		local Frame3 = v3("Frame", tbl4, TextButton2)
		fn8(Frame3, 8)
		local v5 = fn9(Frame3, "accent", 1, 2)

		local function fn26(arg6)
			local n3 = math.clamp((arg6 - TextButton2.AbsolutePosition.X) / math.max(1, TextButton2.AbsoluteSize.X), 0, 1)
			Frame2.Size = UDim2.fromScale(n3, 1)
			Frame3.Position = fn25(n3)
			local n4 = math.floor(min + n3 * (max - min) + 0.5)

			if n4 ~= n then
				n = n4
				TextLabel2.Text = fn23(n)

				if arg5.onChange then
					pcall(arg5.onChange, n)
				end
			end
		end

		local function fn27()
			fn13(Frame2, 0.14, { Size = UDim2.fromScale(fn24(), 1) })
			fn13(Frame3, 0.14, { Position = fn25(fn24()) })
		end

		local v6 = nil

		TextButton2.MouseEnter:Connect(fn2(function()
			fn13(Frame3, 0.12, { Size = UDim2.fromOffset(18, 18) })
			v5.Transparency = 0.35
			UserInputService.MouseIcon = "rbxasset://SystemCursors/PointingHand"
		end))

		TextButton2.MouseLeave:Connect(fn2(function()
			UserInputService.MouseIcon = ""

			if not v6 then
				fn13(Frame3, 0.12, { Size = UDim2.fromOffset(16, 16) })
				v5.Transparency = 1
			end
		end))

		TextButton2.InputBegan:Connect(fn2(--[[ VM helper function (reads VM upvalues, emitted verbatim) ]]
		function(H)if H.UserInputType==Enum.UserInputType.MouseButton1 or H.UserInputType==Enum.UserInputType.Touch then f[1][3][f[1][5]]=true;f[2].Transparency=0.1;f[3][3][f[3][5]](f[4],0.1,{Size=UDim2.fromOffset(19,19)});f[5][3][f[5][5]](H.Position.X);end;end))

		local connection = UserInputService.InputChanged:Connect(fn2(--[[ VM helper function (reads VM upvalues, emitted verbatim) ]]
		function(H)if f[1][3][f[1][5]]and(H.UserInputType==Enum.UserInputType.MouseMovement or H.UserInputType==Enum.UserInputType.Touch)then f[2][3][f[2][5]](H.Position.X);end;end))

		local connection2 = UserInputService.InputEnded:Connect(fn2(--[[ VM helper function (reads VM upvalues, emitted verbatim) ]]
		function(H)if f[1][3][f[1][5]]and(H.UserInputType==Enum.UserInputType.MouseButton1 or H.UserInputType==Enum.UserInputType.Touch)then f[1][3][f[1][5]]=false;f[2][3][f[2][5]](f[3],0.12,{Size=UDim2.fromOffset(16,16)});f[4].Transparency=1;f[5][3][f[5][5]]();end;end))

		local lib = tbl3._lib

		if lib and lib._conns then
			lib._conns[#lib._conns + 1] = connection
			lib._conns[#lib._conns + 1] = connection2
		end

		local tbl5 = {
			get = function()
				return n
			end,
			set = function(arg6)
				n = math.clamp(arg6, min, max)
				fn27()
				TextLabel2.Text = fn23(n)
			end,
		}

		tbl3._lib._controls[#tbl3._lib._controls + 1] = function()
			local n3 = math.clamp(arg5.reset ~= nil and arg5.reset or arg5.default or min, min, max)
			tbl5.set(n3)

			if arg5.onChange then
				pcall(arg5.onChange, n3)
			end
		end

		return tbl5
	end

	tbl3.keybind = function(arg4, arg5)
		local default = arg5.default
		local v2 = fn21()
		fn22(v2, arg5, 118)

		local TextButton2 = fn7("TextButton", {
			Size = UDim2.fromOffset(96, 30),
			Position = UDim2.new(1, -108, 0.5, -15),
			BackgroundColor3 = theme.well,
			BackgroundTransparency = 0.25,
			Text = default and tostring(default) or "None",
			TextColor3 = theme.soft,
			Font = tbl.head,
			TextSize = 12,
			BorderSizePixel = 0,
			AutoButtonColor = false,
		}, v2)

		fn8(TextButton2, 8)
		local v3 = fn9(TextButton2, "border", 0.9)
		local lib = tbl3._lib
		local flag = nil

		TextButton2.MouseButton1Click:Connect(fn2(function()
			if flag then
				return
			end
			flag = true
			TextButton2.Text = "Press a key…"
			v3.Color = theme.accent
			v3.Transparency = 0.35

			if lib then
				lib._capturingKey = true
			end

			if lib and lib.notify then
				lib:notify("Press a key", "accent", "Press any key to bind it — Esc to cancel", nil, "rebind")
			end

			UserInputService.InputBegan:Connect(fn2(--[[ VM helper function (reads VM upvalues, emitted verbatim) ]]
			function(H,h)if H.UserInputType~=Enum.UserInputType.Keyboard then return;end;f[1][3][f[1][5]]=false;f[2][3][f[2][5]]:Disconnect();if f[3]and f[3].dismissTag then f[3]:dismissTag("rebind");end;if H.KeyCode~=Enum.KeyCode.Escape then f[4][3][f[4][5]]=H.KeyCode.Name;if f[5].onChange then pcall(f[5].onChange,f[4][3][f[4][5]]);end;end;f[6].Text=f[4][3][f[4][5]]and(tostring(f[4][3][f[4][5]]))or"None";f[7].Color=f[8].border;f[7].Transparency=0.9;if f[3]then f[9][3][f[9][5]](function()f[3]._capturingKey=false;end);end;end))
		end))

		fn14(TextButton2)

		local tbl4 = {
			get = function()
				return default
			end,
			set = function(arg6)
				default = arg6
				TextButton2.Text = arg6 and tostring(arg6) or "None"
			end,
		}

		tbl3._lib._controls[#tbl3._lib._controls + 1] = function()
			local reset = arg5.reset ~= nil and arg5.reset or arg5.default
			tbl4.set(reset)

			if arg5.onChange then
				pcall(arg5.onChange, reset)
			end
		end

		return tbl4
	end

	tbl3.stats = function(arg4, arg5)
		local Frame2 = fn7("Frame", { Size = UDim2.new(1, 0, 0, 68), BackgroundTransparency = 1, LayoutOrder = fn20() }, fn19())

		fn7("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 9),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, Frame2)

		local tbl4 = {}

		for i, v2 in ipairs(arg5) do
			local Frame3 = fn7("Frame", {
				Size = UDim2.new(1 / #arg5, -9 * (#arg5 - 1) / #arg5, 1, 0),
				BackgroundColor3 = theme.surface,
				BackgroundTransparency = 0.965,
				BorderSizePixel = 0,
				LayoutOrder = i,
			}, Frame2)

			fn8(Frame3, 12)
			fn9(Frame3, "border", 0.92)

			local TextLabel2 = fn7("TextLabel", {
				Size = UDim2.new(1, -20, 0, 26),
				Position = UDim2.fromOffset(12, 11),
				BackgroundTransparency = 1,
				Text = tostring(v2.value),
				TextColor3 = theme.txt,
				Font = tbl.head,
				TextSize = 22,
				TextXAlignment = Enum.TextXAlignment.Left,
			}, Frame3)

			fn12(Frame3, v2.icon, "accent2", 13).Position = UDim2.fromOffset(12, 45)

			fn7("TextLabel", {
				Size = UDim2.new(1, -34, 0, 14),
				Position = UDim2.fromOffset(30, 44),
				BackgroundTransparency = 1,
				Text = v2.label,
				TextColor3 = theme.sub,
				Font = tbl.med,
				TextSize = 11,
				TextXAlignment = Enum.TextXAlignment.Left,
			}, Frame3)

			tbl4[i] = { set = function(arg6)
				TextLabel2.Text = tostring(arg6)
			end }
		end

		return tbl4
	end

	return tbl3
end

index.console = function(arg)
	if arg._consoleTab then
		return arg._consoleTab
	end
	local Console = arg:tab("Console", "terminal")
	local page = Console._page
	page.AutomaticCanvasSize = Enum.AutomaticSize.None
	page.CanvasSize = UDim2.new(0, 0, 0, 0)
	page.ScrollingEnabled = false
	local uiListLayout = page:FindFirstChildOfClass("UIListLayout")

	if uiListLayout then
		uiListLayout:Destroy()
	end

	local uiPadding = page:FindFirstChildOfClass("UIPadding")

	if uiPadding then
		uiPadding:Destroy()
	end

	local ScrollingFrame = fn7("ScrollingFrame", {
		Size = UDim2.new(1, -20, 1, -20),
		Position = UDim2.fromOffset(10, 10),
		BackgroundColor3 = theme.well,
		BackgroundTransparency = 0.25,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ElasticBehavior = Enum.ElasticBehavior.Never,
	}, page)

	fn8(ScrollingFrame, 12)
	fn9(ScrollingFrame, "border", 0.9)
	fn7("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }, ScrollingFrame)
	fn11(ScrollingFrame, 14, 12, 14, 12)
	scrollbar(ScrollingFrame, page, arg._conns, { inset = 14, right = 14, yOff = 10 })

	arg._logEmpty = fn7("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(220, 20),
		BackgroundTransparency = 1,
		Text = "No output yet",
		TextColor3 = theme.dim,
		Font = tbl.mono,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 3,
	}, page)

	arg._log = ScrollingFrame
	arg._logRows = {}
	arg._logSeq = 0
	arg._consoleTab = Console
	return Console
end

index.log = function(arg, arg2, arg3)
	table.insert(arg._q, function()
		if not arg._log then
			arg:console()
		end

		if arg._logEmpty then
			arg._logEmpty.Visible = false
		end

		arg._logSeq = arg._logSeq + 1

		arg._logRows[#arg._logRows + 1] = fn7("TextLabel", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Text = tostring(arg2),
			TextColor3 = fn6(arg3 or "soft"),
			Font = tbl.mono,
			TextSize = 12,
			LineHeight = 1.12,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			LayoutOrder = arg._logSeq,
		}, arg._log)

		if #arg._logRows > 90 then
			local v = table.remove(arg._logRows, 1)

			if v then
				v:Destroy()
			end
		end

		fn4(function()
			if arg._log then
				arg._log.CanvasPosition = Vector2.new(0, arg._log.AbsoluteCanvasSize.Y)
			end
		end)
	end)
end

index.notify = function(arg, arg2, arg3, arg4, arg5, arg6)
	table.insert(arg._q, function()
		local n = type(arg5) == "table" and tonumber(arg5.duration) or arg5 and 7 or 3.8

		local Frame = fn7("Frame", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundColor3 = theme.bar,
			BorderSizePixel = 0,
			ClipsDescendants = true,
		}, arg._toast)

		if arg6 then
			arg._tags = arg._tags or {}

			if arg._tags[arg6] then
				pcall(function()
					arg._tags[arg6]:Destroy()
				end)
			end

			arg._tags[arg6] = Frame
		end

		fn8(Frame, 12)
		fn9(Frame, arg3 or "accent", 0.62)
		fn13(fn7("UIScale", { Scale = 0.94 }, Frame), 0.22, { Scale = 1 })
		local Frame2 = fn7("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 }, Frame)
		fn7("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, Frame2)

		fn7("UIPadding", {
			PaddingTop = UDim.new(0, 11),
			PaddingBottom = UDim.new(0, 18),
			PaddingLeft = UDim.new(0, 12),
			PaddingRight = UDim.new(0, 12),
		}, Frame2)

		fn7("TextLabel", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Text = tostring(arg2),
			TextColor3 = theme.txt,
			Font = tbl.head,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			LayoutOrder = 1,
		}, Frame2)

		if arg4 then
			fn7("TextLabel", {
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				Text = tostring(arg4),
				TextColor3 = theme.sub,
				Font = tbl.med,
				TextSize = 11.5,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextWrapped = true,
				LayoutOrder = 2,
			}, Frame2)
		end

		if type(arg5) == "table" and arg5.onClick then
			local TextButton = fn7("TextButton", {
				Size = UDim2.new(1, 0, 0, 32),
				BackgroundColor3 = theme.accent,
				Text = arg5.text or "Go",
				TextColor3 = Color3.new(1, 1, 1),
				Font = tbl.head,
				TextSize = 12.5,
				BorderSizePixel = 0,
				AutoButtonColor = false,
				LayoutOrder = 3,
			}, Frame2)

			fn8(TextButton, 9)

			TextButton.MouseEnter:Connect(fn2(function()
				TextButton.BackgroundColor3 = theme.accent2
			end))

			TextButton.MouseLeave:Connect(fn2(function()
				TextButton.BackgroundColor3 = theme.accent
			end))

			TextButton.MouseButton1Click:Connect(fn2(function()
				pcall(arg5.onClick)

				if Frame then
					Frame:Destroy()
				end
			end))
		end

		local Frame3 = fn7("Frame", {
			Size = UDim2.new(1, -28, 0, 3),
			Position = UDim2.new(0, 14, 1, -9),
			AnchorPoint = Vector2.new(0, 1),
			BackgroundColor3 = theme.surface,
			BackgroundTransparency = 0.9,
			BorderSizePixel = 0,
			ZIndex = 3,
		}, Frame)

		fn8(Frame3, 2)

		local Frame4 = fn7("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = fn6(arg3 or "accent"),
			BorderSizePixel = 0,
			ZIndex = 4,
		}, Frame3)

		fn8(Frame4, 2)
		fn10(Frame4, 0, arg3 or "accent", arg3 == "amber" and "gold2" or "cyan")
		local out = Enum.EasingDirection.Out
		local linear = Enum.EasingStyle.Linear
		Frame4:TweenSize(UDim2.new(0, 0, 1, 0), out, linear, n, true)

		fn5(n, function()
			if Frame then
				Frame:Destroy()
			end

			if arg6 and arg._tags then
				arg._tags[arg6] = nil
			end
		end)
	end)
end

index.dismissTag = function(arg, arg2)
	if arg._tags and arg._tags[arg2] then
		pcall(function()
			arg._tags[arg2]:Destroy()
		end)

		arg._tags[arg2] = nil
	end
end
;(getgenv and getgenv() or _G).UILib = index
-- return index

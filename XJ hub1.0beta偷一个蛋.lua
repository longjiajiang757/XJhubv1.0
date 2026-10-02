-- ============================================================
-- XJ HUB 1.0 beta · 偷蛋定制最终整合版
-- 作者: 嘉酱
-- 卡密验证: BloxyBin Key System
-- ============================================================

-- ============================================================
-- 第一部分：卡密验证（BloxyBin Key System）
-- ============================================================
        -- ============================================================
        -- 第二部分：主脚本（验证通过后执行）
        -- ============================================================
        local Players = game:GetService("Players")
        local RS      = game:GetService("ReplicatedStorage")
        local RunSvc  = game:GetService("RunService")
        local UIS     = game:GetService("UserInputService")
        local Tween   = game:GetService("TweenService")
        local WS      = game:GetService("Workspace")
        local LP      = Players.LocalPlayer

        local function ok(m)  print("[XJ] ✅ " .. m) end
        local function no(m)  print("[XJ] ❌ " .. m) end
        local function inf(m) print("[XJ] ℹ️ " .. m) end
        inf("卡密验证通过，XJ HUB 1.0 beta 开始加载")

        -- ========== ScreenGui ==========
        local uiParent = (gethui and gethui()) or game:GetService("CoreGui")
        local oldGui = uiParent:FindFirstChild("XJHubUI")
        if oldGui then oldGui:Destroy() end
        local screen = Instance.new("ScreenGui")
        screen.Name = "XJHubUI"
        screen.ResetOnSpawn = false
        screen.IgnoreGuiInset = true
        screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        screen.Parent = uiParent
        ok("ScreenGui")

        -- ========== 自适应缩放 ==========
        local cam0 = WS.CurrentCamera
        local vp = cam0 and cam0.ViewportSize or Vector2.new(1920, 1080)
        local isTouch = UIS.TouchEnabled and not UIS.MouseEnabled
        local uiScale = 1
        if isTouch or vp.X < 800 then
            uiScale = math.clamp(math.min((vp.X - 40) / 460, (vp.Y - 80) / 340), 0.6, 1)
        end

        -- ========== 状态表 ==========
        local S = {
            speedEnabled=false, speedValue=100,
            jumpEnabled=false, jumpPower=50,
            flyEnabled=false, flySpeed=50,
            autoSteal=false,
        }

        -- ========== 绕过自检 ==========
        local TARGET_UPVALUE_COUNT = 19
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
        checkEnv("gethui", function() if not gethui then error() end end)

        checkBypass("偷蛋反作弊 Hook", function()
            local successScan = false
            pcall(function()
                for _, f in next, filtergc("function", {}) do
                    local success, isMatch = pcall(function()
                        return islclosure(f) and #debug.getupvalues(f) == TARGET_UPVALUE_COUNT
                    end)
                    if success and isMatch then
                        local target = debug.getupvalue(f, 2)
                        if typeof(target) == "function" then
                            local old
                            old = hookfunction(target, newcclosure(function(...)
                                local b = select(2, ...)
                                if typeof(b) == "table" and getmetatable(b) then
                                    setmetatable(b, nil)
                                end
                                return old(...)
                            end))
                            successScan = true
                            break
                        end
                    end
                end
            end)
            if not successScan then error("未找到特征") end
        end)

        inf("环境: "..selfCheck.env.score.."/"..selfCheck.env.total.." · 绕过: "..selfCheck.bypass.score.."/"..selfCheck.bypass.total)

        -- ========== 工具 ==========
        local function getChar(p)
            p = p or LP
            local c = p.Character
            if not c then return end
            local h = c:FindFirstChildOfClass("Humanoid")
            local r = c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso")
            return c, h, r
        end

        -- ========== 性能统计 ==========
        local stats = { fps=0, frames=0, lastTick=tick(), ping=0 }
        task.spawn(function()
            while screen.Parent do
                pcall(function() stats.ping = math.floor((LP:GetNetworkPing() or 0) * 1000) end)
                task.wait(1)
            end
        end)

        -- ========== 玩家信息 ==========
        local userInfo = {
            name=LP.Name,
            displayName=LP.DisplayName or LP.Name,
            userId=LP.UserId,
            accountAge=LP.AccountAge or 0,
            membership=tostring(LP.MembershipType):gsub("Enum.MembershipType%.", ""),
            thumb="rbxthumb://type=AvatarHeadShot&id="..LP.UserId.."&w=150&h=150",
        }

        -- ========== 飞行逻辑 ==========
        local FlyState = { flyConn=nil }
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
                local mv = Vector3.zero
                if UIS:IsKeyDown(Enum.KeyCode.W) then mv = mv + Vector3.new(0,0,-1) end
                if UIS:IsKeyDown(Enum.KeyCode.S) then mv = mv + Vector3.new(0,0,1) end
                if UIS:IsKeyDown(Enum.KeyCode.A) then mv = mv + Vector3.new(-1,0,0) end
                if UIS:IsKeyDown(Enum.KeyCode.D) then mv = mv + Vector3.new(1,0,0) end
                
                local dir = cam.CFrame.LookVector * -mv.Z + cam.CFrame.RightVector * mv.X
                local y = UIS:IsKeyDown(Enum.KeyCode.Space) and 1 or (UIS:IsKeyDown(Enum.KeyCode.LeftControl) and -1 or 0)
                
                r2.CFrame = r2.CFrame + (dir + Vector3.new(0, y, 0)) * S.flySpeed * dt
                r2.AssemblyLinearVelocity = Vector3.zero
                r2.AssemblyAngularVelocity = Vector3.zero
                h2:ChangeState(Enum.HumanoidStateType.Climbing)
            end)
        end

        -- ========== 自动偷蛋逻辑 ==========
        local autoStealConn = nil
        local function handleEgg(obj)
            if not S.autoSteal then return end
            if obj:IsA("Model") and (obj.Name:lower():find("egg") or obj.Name:lower():find("brainrot")) then
                local prompt = obj:FindFirstChildOfClass("ProximityPrompt", true)
                if prompt then
                    pcall(function() fireproximityprompt(prompt) end)
                end
            end
        end
        local function startAutoSteal()
            for _, obj in pairs(WS:GetChildren()) do handleEgg(obj) end
            autoStealConn = WS.ChildAdded:Connect(handleEgg)
        end
        local function stopAutoSteal()
            if autoStealConn then autoStealConn:Disconnect(); autoStealConn = nil end
        end

        -- ========== UI 主窗口 ==========
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

        -- 标题栏
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
        title.BackgroundTransparency = 1; title.Text = "XJ HUB 1.0 beta"
        title.TextColor3 = Color3.new(1,1,1); title.Font = Enum.Font.GothamBold
        title.TextSize = 13; title.TextXAlignment = Enum.TextXAlignment.Left

        local sub = Instance.new("TextLabel", topbar)
        sub.Size = UDim2.new(0, 200, 0, 12); sub.Position = UDim2.new(0, 42, 0, 22)
        sub.BackgroundTransparency = 1
        sub.Text = "作者：嘉酱 · 🟢安全 🟡中 🔴危险"
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

        local closeBtn = Instance.new("TextButton", topbar)
        closeBtn.Size = UDim2.new(0, 24, 0, 24); closeBtn.Position = UDim2.new(1, -30, 0.5, -12)
        closeBtn.BackgroundColor3 = Color3.fromRGB(239, 68, 68); closeBtn.Text = "×"
        closeBtn.TextColor3 = Color3.new(1,1,1); closeBtn.Font = Enum.Font.GothamBold
        closeBtn.TextSize = 17; closeBtn.BorderSizePixel = 0
        Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

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
        blockTopbarDrag(closeBtn)

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
        isTitle.BackgroundTransparency = 1; isTitle.Text = "XJ HUB 1.0 beta"
        isTitle.TextColor3 = Color3.new(1, 1, 1); isTitle.Font = Enum.Font.GothamBold
        isTitle.TextSize = 10; isTitle.TextXAlignment = Enum.TextXAlignment.Left

        local isInfo = Instance.new("TextLabel", island)
        isInfo.Size = UDim2.new(1, -80, 0, 10); isInfo.Position = UDim2.new(0, 34, 0, 18)
        isInfo.BackgroundTransparency = 1; isInfo.Text = "作者：嘉酱"
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
        closeBtn.MouseButton1Click:Connect(function() screen:Destroy() end)

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

        local function riskPrefix(risk)
            if risk == "safe" then return "🟢 "
            elseif risk == "mid" then return "🟡 "
            elseif risk == "risk" then return "🔴 "
            end
            return ""
        end

        local function riskBg(risk)
            if risk == "safe" then return Color3.fromRGB(24, 36, 28)
            elseif risk == "mid" then return Color3.fromRGB(38, 34, 22)
            elseif risk == "risk" then return Color3.fromRGB(42, 20, 24)
            end
            return Color3.fromRGB(28, 28, 40)
        end

        local function riskTextColor(risk)
            if risk == "safe" then return Color3.fromRGB(150, 240, 170)
            elseif risk == "mid" then return Color3.fromRGB(255, 220, 130)
            elseif risk == "risk" then return Color3.fromRGB(255, 150, 150)
            end
            return Color3.fromRGB(235, 235, 245)
        end

        local function createToggle(parent, name, def, cb, risk)
            risk = risk or "safe"
            local btn = Instance.new("TextButton", parent)
            btn.Size = UDim2.new(1, 0, 0, 32)
            btn.BackgroundColor3 = riskBg(risk)
            btn.BackgroundTransparency = 0.1
            btn.Text = ""; btn.BorderSizePixel = 0
            btn.AutoButtonColor = false
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

        local function createSlider(parent, name, min, max, def, cb, risk)
            risk = risk or "safe"
            local frame = Instance.new("Frame", parent)
            frame.Size = UDim2.new(1, 0, 0, 46)
            frame.BackgroundColor3 = riskBg(risk)
            frame.BackgroundTransparency = 0.1
            frame.BorderSizePixel = 0
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

        -- 3 分类
        local pHome = createPage("主页")
        local pFly = createPage("加速飞行")
        local pAuto = createPage("自动")

        createTab("主页", "🏠")
        createTab("加速飞行", "🚀")
        createTab("自动", "⚡")

        for _, pg in pairs(pages) do pg.Visible = false end
        pages["主页"].Visible = true
        currentTab = "主页"
        tabButtons["主页"].lbl.TextColor3 = Color3.new(1, 1, 1)
        tabButtons["主页"].ico.TextColor3 = Color3.new(1, 1, 1)
        tabButtons["主页"].btn.BackgroundTransparency = 0.75

        -- ========================
        -- 主页
        -- ========================
        local legendCard = Instance.new("Frame", pHome)
        legendCard.Size = UDim2.new(1, 0, 0, 60)
        legendCard.BackgroundColor3 = Color3.fromRGB(28, 28, 40)
        legendCard.BackgroundTransparency = 0.1
        legendCard.BorderSizePixel = 0
        Instance.new("UICorner", legendCard).CornerRadius = UDim.new(0, 7)

        local legendTitle = Instance.new("TextLabel", legendCard)
        legendTitle.Size = UDim2.new(1, -20, 0, 14); legendTitle.Position = UDim2.new(0, 10, 0, 4)
        legendTitle.BackgroundTransparency = 1
        legendTitle.Text = "📖 风险图例"
        legendTitle.TextColor3 = Color3.fromRGB(150, 200, 255); legendTitle.Font = Enum.Font.GothamBold
        legendTitle.TextSize = 11; legendTitle.TextXAlignment = Enum.TextXAlignment.Left

        local legendText = Instance.new("TextLabel", legendCard)
        legendText.Size = UDim2.new(1, -20, 0, 42); legendText.Position = UDim2.new(0, 10, 0, 20)
        legendText.BackgroundTransparency = 1
        legendText.Text = "🟢 安全 — 服务端看不到，随便用\n🟡 中等 — 服务端可检测，低频率不易察觉\n🔴 危险 — 服务端一定看到异常，慎用"
        legendText.TextColor3 = Color3.fromRGB(200, 200, 220)
        legendText.Font = Enum.Font.Gotham; legendText.TextSize = 10
        legendText.TextXAlignment = Enum.TextXAlignment.Left
        legendText.TextYAlignment = Enum.TextYAlignment.Top

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
        local bypassValue = makeStatCell(statsRow, "绕过", Color3.fromRGB(180, 130, 255))

        task.spawn(function()
            while screen.Parent do
                pcall(function()
                    fpsValue.Text = tostring(stats.fps)
                    pingValue.Text = stats.ping .. "ms"
                    if stats.ping > 200 then pingValue.TextColor3 = Color3.fromRGB(255, 80, 60)
                    elseif stats.ping > 100 then pingValue.TextColor3 = Color3.fromRGB(255, 200, 100)
                    else pingValue.TextColor3 = Color3.fromRGB(80, 220, 100) end
                    bypassValue.Text = selfCheck.bypass.score .. "/" .. selfCheck.bypass.total
                end)
                task.wait(0.5)
            end
        end)

        -- ========================
        -- 加速飞行页
        -- ========================
        createSlider(pFly, "行走速度", 16, 500, 100, function(v) S.speedValue = v end, "risk")
        createToggle(pFly, "修改行走速度", false, function(v) S.speedEnabled = v end, "risk")
        createSlider(pFly, "跳跃高度", 10, 200, 50, function(v) S.jumpPower = v end, "risk")
        createToggle(pFly, "跳跃修改", false, function(v) S.jumpEnabled = v end, "risk")
        createToggle(pFly, "飞行模式 (WASD+空格)", false, function(v)
            S.flyEnabled = v
            if v then startFly() else stopFly() end
        end, "risk")
        createSlider(pFly, "飞行速度", 10, 300, 50, function(v) S.flySpeed = v end, "risk")

        -- ========================
        -- 自动页
        -- ========================
        createToggle(pAuto, "自动偷蛋", false, function(v)
            S.autoSteal = v
            if v then startAutoSteal() else stopAutoSteal() end
        end, "mid")

        -- 角色重生恢复
        LP.CharacterAdded:Connect(function(char)
            local h = char:WaitForChild("Humanoid", 5)
            if h then
                if S.speedEnabled then h.WalkSpeed = S.speedValue end
                if S.jumpEnabled then
                    h.UseJumpPower = true
                    h.JumpPower = S.jumpPower
                end
                if S.flyEnabled then
                    task.wait(0.5)
                    startFly()
                end
            end
        end)

        ok("UI 构建完成")

        -- ========== 加载动画 ==========
        local loading = Instance.new("Frame", screen)
        loading.Size = UDim2.new(1, 0, 1, 0)
        loading.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        loading.BackgroundTransparency = 0.4
        loading.BorderSizePixel = 0
        loading.ZIndex = 100

        local lCard = Instance.new("Frame", loading)
        lCard.Size = UDim2.new(0, 250, 0, 140)
        lCard.Position = UDim2.new(0.5, -125 * uiScale, 0.5, -70 * uiScale)
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

        local lTitle = Instance.new("TextLabel", lCard)
        lTitle.Size = UDim2.new(1, 0, 0, 14); lTitle.Position = UDim2.new(0, 0, 0, 62)
        lTitle.BackgroundTransparency = 1; lTitle.Text = "XJ HUB 1.0 beta"
        lTitle.TextColor3 = Color3.new(1, 1, 1); lTitle.Font = Enum.Font.GothamBold
        lTitle.TextSize = 12; lTitle.ZIndex = 102

        local lAuthor = Instance.new("TextLabel", lCard)
        lAuthor.Size = UDim2.new(1, 0, 0, 12); lAuthor.Position = UDim2.new(0, 0, 0, 78)
        lAuthor.BackgroundTransparency = 1; lAuthor.Text = "作者：嘉酱"
        lAuthor.TextColor3 = Color3.fromRGB(168, 85, 247); lAuthor.Font = Enum.Font.Gotham
        lAuthor.TextSize = 10; lAuthor.ZIndex = 102

        local lBarBg = Instance.new("Frame", lCard)
        lBarBg.Size = UDim2.new(1, -36, 0, 4); lBarBg.Position = UDim2.new(0, 18, 0, 100)
        lBarBg.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
        lBarBg.BorderSizePixel = 0; lBarBg.ZIndex = 102
        Instance.new("UICorner", lBarBg).CornerRadius = UDim.new(1, 0)

        local lBarFill = Instance.new("Frame", lBarBg)
        lBarFill.Size = UDim2.new(0, 0, 1, 0)
        lBarFill.BackgroundColor3 = Color3.fromRGB(168, 85, 247)
        lBarFill.BorderSizePixel = 0; lBarFill.ZIndex = 103
        Instance.new("UICorner", lBarFill).CornerRadius = UDim.new(1, 0)

        local lStatus = Instance.new("TextLabel", lCard)
        lStatus.Size = UDim2.new(1, -36, 0, 14); lStatus.Position = UDim2.new(0, 18, 0, 112)
        lStatus.BackgroundTransparency = 1; lStatus.Text = "初始化..."
        lStatus.TextColor3 = Color3.fromRGB(200, 200, 220)
        lStatus.Font = Enum.Font.GothamMedium; lStatus.TextSize = 9
        lStatus.TextXAlignment = Enum.TextXAlignment.Left; lStatus.ZIndex = 102

        task.spawn(function()
            lStatus.Text = "初始化..."
            Tween:Create(lBarFill, TweenInfo.new(0.3), { Size = UDim2.new(0.5, 0, 1, 0) }):Play()
            task.wait(0.3)
            lStatus.Text = "加载模块..."
            Tween:Create(lBarFill, TweenInfo.new(0.3), { Size = UDim2.new(1, 0, 1, 0) }):Play()
            task.wait(0.3)

            Tween:Create(loading, TweenInfo.new(0.25), { BackgroundTransparency = 1 }):Play()
            Tween:Create(lCard, TweenInfo.new(0.25), { BackgroundTransparency = 1 }):Play()
            Tween:Create(lCardStroke, TweenInfo.new(0.25), { Transparency = 1 }):Play()
            for _, d in ipairs(lCard:GetDescendants()) do
                if d:IsA("TextLabel") then
                    Tween:Create(d, TweenInfo.new(0.2), { TextTransparency = 1 }):Play()
                end
            end

            task.wait(0.3)
            loading:Destroy()

            main.Visible = true
            main.Size = UDim2.new(0, 80, 0, 60)
            Tween:Create(main, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 460, 0, 340),
            }):Play()
        end)

        -- FPS统计循环
        RunSvc.RenderStepped:Connect(function()
            stats.frames = stats.frames + 1
            if tick() - stats.lastTick >= 1 then
                stats.fps = stats.frames; stats.frames = 0; stats.lastTick = tick()
            end
        end)

        ok("加载完成")
        inf("========== XJ HUB 1.0 beta 启动完毕 | 作者：嘉酱 ==========")
    end
})

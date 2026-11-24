--// ============================================================
--// RACKET RIVALS - KHUY AI FULL - KHONG API
--// Key: khuy
--// Mới lên menu: TAT CA CHUC NANG DEU TAT SAN
--// Auto KHONG lam gian doan di chuyen: chi dung Humanoid:MoveTo, khong Anchored, khong CFrame, khong Tween giu nguoi
--// Tat auto -> di chuyen binh thuong 100%, khong con task nao dong vao nhan vat
--// AI khong API: tu quan sat bong, khong danh ra ngoai san, khong dung sat luoi, danh 1 qua roi ve giua san doi
--// Co nut KHUY an/hien menu, menu keo duoc o TopBar
--// ============================================================
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local VIM = game:GetService("VirtualInputManager")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")
local VirtualUser = game:GetService("VirtualUser")

local KEY = "khuy"
print("[KHUY-AI] Load xong, tat ca chuc nang DANG TAT")

--// ============ STATE - TAT CA TAT SAN ============
local AutoFarmAI = false -- AI chinh: tu chay + danh
local AutoHit = false -- chi auto danh, khong tu chay
local AutoReturn = true -- tu ve giua san sau khi danh (bat san nhung chi chay khi AutoFarmAI/AutoHit bat)
local ShowDebug = true

local AIState = "CHO" -- CHO / VE_GIUA / THEO_BONG / DANH / DOI
local LastHitTime = 0
local HitCooldown = 1.2
local HasHitThisRally = false
local LastBallSide = "DOI_PHUONG" -- de biet khi nao bong qua san minh
local PlayerManualMoveUntil = 0 -- neu nguoi choi dang keo joystick thi AI nghi 0.5s

--// ============ HELPER NHAN VAT - KHONG PHA DI CHUYEN ============
local function GetChar() return LocalPlayer.Character end
local function GetHRP() local c = GetChar() return c and c:FindFirstChild("HumanoidRootPart") end
local function GetHum() local c = GetChar() return c and c:FindFirstChildOfClass("Humanoid") end
local function IsPlayerMovingManually()
    local hum = GetHum()
    if not hum then return false end
    -- Neu nguoi choi dang keo joystick / phim -> MoveDirection > 0.2
    return hum.MoveDirection.Magnitude > 0.2
end
local function RestoreMovement()
    -- Chi goi khi TAT auto: tra lai trang thai binh thuong, khong de lai di chung
    local hrp, hum = GetHRP(), GetHum()
    if not hrp or not hum then return end
    pcall(function()
        if hrp.Anchored then hrp.Anchored = false end
        if hum.PlatformStand then hum.PlatformStand = false end
        hum.Sit = false
        if hum.WalkSpeed ~= 16 then hum.WalkSpeed = 16 end
    end)
end

--// ============ TIM SAN / LUOI / GIUA SAN - TU DONG, KHONG CAN TOA DO CUNG ============
local CourtInfo = { NetPos = nil, CenterPos = nil, CourtSize = Vector3.new(40, 0, 20), OwnSide = 1 }
local function FindCourt()
    -- Tim luoi: ten co "Net"
    local net = nil
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name:lower():find("net") then net = obj break end
    end
    -- Tim san: ten co "court"
    local court = nil
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name:lower():find("court") then court = obj break end
    end
    local hrp = GetHRP()
    if net then CourtInfo.NetPos = net.Position end
    if court then
        CourtInfo.CenterPos = court.Position
        CourtInfo.CourtSize = court.Size
    elseif net and hrp then
        -- Neu khong co Court, lay giua san = vi tri spawn / vi tri nguoi choi luc dau + huong ve luoi
        CourtInfo.CenterPos = hrp.Position
    elseif hrp and not CourtInfo.CenterPos then
        CourtInfo.CenterPos = hrp.Position
    end
    -- Xac dinh phia cua minh: nguoi choi dang o phia nao cua luoi
    if net and hrp then
        -- Dung truc X neu san nam ngang X, neu khong dung Z. Chon truc co chenh lech lon nhat
        local dx = hrp.Position.X - net.Position.X
        local dz = hrp.Position.Z - net.Position.Z
        if math.abs(dx) > math.abs(dz) then CourtInfo.OwnSide = (dx > 0) and 1 or -1
        else CourtInfo.OwnSide = (dz > 0) and 1 or -1 end
        CourtInfo.Axis = (math.abs(dx) > math.abs(dz)) and "X" or "Z"
    end
    return CourtInfo
end
local function GetCenterPos()
    FindCourt()
    local hrp = GetHRP()
    local netPos = CourtInfo.NetPos
    local center = CourtInfo.CenterPos
    if not netPos or not center or not hrp then return hrp and hrp.Position or Vector3.new(0,0,0) end
    -- Giua san cua MINH = diem giua giua luoi va baseline phia minh
    -- Baseline phia minh = Center + huong ve minh * (CourtSize/2)
    local axis = CourtInfo.Axis or "X"
    local half = 0
    if axis == "X" then half = CourtInfo.CourtSize.X / 2 else half = CourtInfo.CourtSize.Z / 2 end
    -- Neu khong biet CourtSize thi lay 12 studs tu luoi ve phia minh
    if half < 5 then half = 12 end
    local ownCenter = nil
    if axis == "X" then
        ownCenter = Vector3.new(netPos.X + CourtInfo.OwnSide * (half * 0.55), netPos.Y, netPos.Z)
        -- Giu Z theo center san neu co
        if center then ownCenter = Vector3.new(ownCenter.X, ownCenter.Y, center.Z) end
    else
        ownCenter = Vector3.new(netPos.X, netPos.Y, netPos.Z + CourtInfo.OwnSide * (half * 0.55))
        if center then ownCenter = Vector3.new(center.X, ownCenter.Y, ownCenter.Z) end
    end
    -- Y = Y cua HRP de khong bay
    ownCenter = Vector3.new(ownCenter.X, hrp.Position.Y, ownCenter.Z)
    return ownCenter
end
local function GetNetPos() FindCourt() return CourtInfo.NetPos end
local function IsBallOnMySide(ballPos)
    local netPos = GetNetPos()
    local hrp = GetHRP()
    if not netPos or not hrp then return true end
    local axis = CourtInfo.Axis or "X"
    if axis == "X" then
        -- Bong va nguoi choi cung phia so voi luoi ?
        return (ballPos.X - netPos.X) * CourtInfo.OwnSide > 0
    else
        return (ballPos.Z - netPos.Z) * CourtInfo.OwnSide > 0
    end
end
local function DistanceToNet(pos)
    local netPos = GetNetPos()
    if not netPos then return 999 end
    return (Vector3.new(pos.X, 0, pos.Z) - Vector3.new(netPos.X, 0, netPos.Z)).Magnitude
end
local function ClampAwayFromNet(targetPos)
    -- KHONG DUNG SAT LUOI: giu cach luoi it nhat 4 studs
    local netPos = GetNetPos()
    if not netPos then return targetPos end
    local minDist = 4
    local flatTarget = Vector3.new(targetPos.X, 0, targetPos.Z)
    local flatNet = Vector3.new(netPos.X, 0, netPos.Z)
    local d = (flatTarget - flatNet).Magnitude
    if d < minDist then
        local dir = (flatTarget - flatNet)
        if dir.Magnitude < 0.1 then
            -- Neu trung luoi, day ve phia minh
            if CourtInfo.Axis == "X" then dir = Vector3.new(CourtInfo.OwnSide, 0, 0) else dir = Vector3.new(0, 0, CourtInfo.OwnSide) end
        else dir = dir.Unit end
        flatTarget = flatNet + dir * minDist
        return Vector3.new(flatTarget.X, targetPos.Y, flatTarget.Z)
    end
    return targetPos
end
local function IsBallOutOfCourt(ballPos)
    -- KHONG DANH RA NGOAI SAN: neu bong nam ngoai bien san + 2 studs thi khong danh
    local center = CourtInfo.CenterPos
    if not center then return false end
    local halfX = CourtInfo.CourtSize.X / 2 + 2
    local halfZ = CourtInfo.CourtSize.Z / 2 + 2
    if halfX < 8 then halfX = 22 end
    if halfZ < 8 then halfZ = 12 end
    local dx = math.abs(ballPos.X - center.X)
    local dz = math.abs(ballPos.Z - center.Z)
    return dx > halfX or dz > halfZ
end
local function FindBall()
    local best, bestDist = nil, 9999
    local hrp = GetHRP()
    if not hrp then return nil, 9999 end
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name:lower():find("ball") then
            local d = (obj.Position - hrp.Position).Magnitude
            if d < bestDist then bestDist = d best = obj end
        end
    end
    return best, bestDist
end

--// ============ DI CHUYEN AI - KHONG GIAT, KHONG CUOP JOYSTICK ============
local function AIMoveTo(targetPos)
    local hum, hrp = GetHum(), GetHRP()
    if not hum or not hrp then return end
    -- Neu nguoi choi dang tu di chuyen -> AI DUNG LAI, de nguoi choi di, khong tranh joystick
    if IsPlayerMovingManually() then
        PlayerManualMoveUntil = tick() + 0.5
        return
    end
    if tick() < PlayerManualMoveUntil then return end
    -- Khong dung sat luoi
    targetPos = ClampAwayFromNet(targetPos)
    -- Chi MoveTo khi cach > 1.5 studs, tranh spam MoveTo gay giat
    if (Vector3.new(hrp.Position.X,0,hrp.Position.Z) - Vector3.new(targetPos.X,0,targetPos.Z)).Magnitude < 1.5 then return end
    -- Dung Humanoid:MoveTo - cach di chuyen tu nhien cua Roblox, khong Tween, khong CFrame
    pcall(function() hum:MoveTo(Vector3.new(targetPos.X, hrp.Position.Y, targetPos.Z)) end)
end

--// ============ DANH CAU - CHI DANH KHI DU DIEU KIEN ============
local function TryHit(ball)
    if not ball then return false end
    local hrp = GetHRP()
    if not hrp then return false end
    local now = tick()
    if now - LastHitTime < HitCooldown then return false end
    if HasHitThisRally then return false end -- Da danh 1 qua roi, phai ve giua doi qua moi
    local ballPos = ball.Position
    -- 1. Bong phai o san minh moi danh
    if not IsBallOnMySide(ballPos) then AIState = "DOI" return false end
    -- 2. Bong khong duoc ngoai san
    if IsBallOutOfCourt(ballPos) then return false end
    -- 3. Bong phai gan nguoi (trong tam danh)
    local dist = (ballPos - hrp.Position).Magnitude
    if dist > 9 then return false end
    if ballPos.Y > hrp.Position.Y + 8 then return false end -- Bong qua cao, doi roi xuong
    -- 4. Khong danh khi dang dung sat luoi qua (da clamp o MoveTo, nhung check them)
    if DistanceToNet(hrp.Position) < 2.5 then return false end
    -- DANH: bam chuot + E, huong ve giua san doi phuong (de khong ra ngoai)
    pcall(function() VIM:SendMouseButtonEvent(0,0,0,true,game,0) task.wait(0.05) VIM:SendMouseButtonEvent(0,0,0,false,game,0) end)
    pcall(function() VIM:SendKeyEvent(true, Enum.KeyCode.E, false, game) task.wait(0.05) VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game) end)
    LastHitTime = now
    HasHitThisRally = true
    AIState = "VE_GIUA"
    return true
end

--// ============ GUI ============
local Gui = Instance.new("ScreenGui") Gui.Name = "KHUY_AI" Gui.ResetOnSpawn = false Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() Gui.Parent = CoreGui end)
if not Gui.Parent then Gui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local function Corner(o, r) local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, r or 10) c.Parent = o end

--// --- Key GUI ---
local KeyGui = Instance.new("ScreenGui") KeyGui.Name = "KHUY_Key" KeyGui.ResetOnSpawn = false KeyGui.Parent = Gui
local KeyFrame = Instance.new("Frame") KeyFrame.Size = UDim2.new(0, 320, 0, 200) KeyFrame.Position = UDim2.new(0.5, -160, 0.5, -100) KeyFrame.BackgroundColor3 = Color3.fromRGB(18,18,24) KeyFrame.Parent = KeyGui Corner(KeyFrame, 12)
local KeyTitle = Instance.new("TextLabel") KeyTitle.Size = UDim2.new(1,0,0,40) KeyTitle.Text = "RACKET RIVALS - KHUY AI" KeyTitle.TextColor3 = Color3.new(1,1,1) KeyTitle.Font = Enum.Font.GothamBold KeyTitle.TextScaled = true KeyTitle.BackgroundTransparency = 1 KeyTitle.Parent = KeyFrame
local KeyBox = Instance.new("TextBox") KeyBox.Size = UDim2.new(0, 260, 0, 44) KeyBox.Position = UDim2.new(0.5, -130, 0, 60) KeyBox.PlaceholderText = "Nhap key: khuy" KeyBox.Text = "" KeyBox.BackgroundColor3 = Color3.fromRGB(30,30,38) KeyBox.TextColor3 = Color3.new(1,1,1) KeyBox.Font = Enum.Font.Gotham KeyBox.TextScaled = true KeyBox.Parent = KeyFrame Corner(KeyBox, 8)
local KeyBtn = Instance.new("TextButton") KeyBtn.Size = UDim2.new(0, 260, 0, 44) KeyBtn.Position = UDim2.new(0.5, -130, 0, 120) KeyBtn.Text = "XAC NHAN" KeyBtn.BackgroundColor3 = Color3.fromRGB(255,85,85) KeyBtn.TextColor3 = Color3.new(1,1,1) KeyBtn.Font = Enum.Font.GothamBold KeyBtn.TextScaled = true KeyBtn.Parent = KeyFrame Corner(KeyBtn, 8)
local KeyMsg = Instance.new("TextLabel") KeyMsg.Size = UDim2.new(1,0,0,24) KeyMsg.Position = UDim2.new(0,0,0,170) KeyMsg.Text = "Key: khuy" KeyMsg.TextColor3 = Color3.fromRGB(140,255,150) KeyMsg.Font = Enum.Font.Gotham KeyMsg.TextScaled = true KeyMsg.BackgroundTransparency = 1 KeyMsg.Parent = KeyFrame

--// --- Main Menu - TAT CA TAT SAN ---
local MainFrame = Instance.new("Frame") MainFrame.Name = "MainFrame" MainFrame.Size = UDim2.new(0, 340, 0, 460) MainFrame.Position = UDim2.new(0.5, -170, 0.5, -230) MainFrame.BackgroundColor3 = Color3.fromRGB(20,20,26) MainFrame.Visible = false MainFrame.Active = false MainFrame.Parent = Gui Corner(MainFrame, 12)
local TopBar = Instance.new("Frame") TopBar.Size = UDim2.new(1,0,0,38) TopBar.BackgroundColor3 = Color3.fromRGB(255,85,85) TopBar.Active = true TopBar.Parent = MainFrame Corner(TopBar, 12)
local TopLabel = Instance.new("TextLabel") TopLabel.Size = UDim2.new(1,0,1,0) TopLabel.Text = "KHUY AI - KEO O DAY" TopLabel.TextColor3 = Color3.new(1,1,1) TopLabel.Font = Enum.Font.GothamBold TopLabel.TextScaled = true TopLabel.BackgroundTransparency = 1 TopLabel.Parent = TopBar
local StatusLabel = Instance.new("TextLabel") StatusLabel.Size = UDim2.new(0, 300, 0, 30) StatusLabel.Position = UDim2.new(0.5, -150, 0, 48) StatusLabel.Text = "Trang thai: TAT CA DANG TAT" StatusLabel.TextColor3 = Color3.fromRGB(255,255,120) StatusLabel.Font = Enum.Font.GothamBold StatusLabel.TextScaled = true StatusLabel.BackgroundTransparency = 1 StatusLabel.Parent = MainFrame
local AILabel = Instance.new("TextLabel") AILabel.Size = UDim2.new(0, 300, 0, 30) AILabel.Position = UDim2.new(0.5, -150, 0, 78) AILabel.Text = "AI: CHO - Dang o giua san" AILabel.TextColor3 = Color3.fromRGB(140,220,255) AILabel.Font = Enum.Font.Gotham AILabel.TextScaled = true AILabel.BackgroundTransparency = 1 AILabel.Parent = MainFrame

local function MakeToggle(name, y, initial, callback)
    local btn = Instance.new("TextButton") btn.Size = UDim2.new(0, 300, 0, 44) btn.Position = UDim2.new(0.5, -150, 0, y) btn.Text = name .. ": OFF" btn.BackgroundColor3 = Color3.fromRGB(45,45,55) btn.TextColor3 = Color3.new(1,1,1) btn.Font = Enum.Font.GothamBold btn.TextScaled = true btn.Parent = MainFrame Corner(btn, 8)
    local on = initial
    local function refresh()
        btn.Text = name .. (on and ": ON" or ": OFF")
        btn.BackgroundColor3 = on and Color3.fromRGB(40,180,90) or Color3.fromRGB(45,45,55)
    end
    refresh()
    btn.MouseButton1Click:Connect(function()
        on = not on refresh() callback(on)
    end)
    return btn, function() return on end
end

local FarmBtn, GetFarm = MakeToggle("AI Auto Farm (Tu chay + Danh)", 118, false, function(v)
    AutoFarmAI = v
    if not v then AIState = "CHO" RestoreMovement() end
    print("[KHUY-AI] AutoFarmAI:", v)
end)
local HitBtn, GetHit = MakeToggle("Auto Hit (Chi danh, khong chay)", 168, false, function(v)
    AutoHit = v
    if not v then RestoreMovement() end
end)
local ReturnBtn, GetReturn = MakeToggle("Tu ve giua san sau khi danh", 218, true, function(v) AutoReturn = v end)
-- Return mac dinh true nhung chi co tac dung khi AutoFarm/AutoHit bat, khi tat het thi khong dong vao nguoi

local InfoLabel = Instance.new("TextLabel") InfoLabel.Size = UDim2.new(0, 300, 0, 80) InfoLabel.Position = UDim2.new(0.5, -150, 0, 278) InfoLabel.Text = "AI: Danh 1 qua -> Ve giua san\nKhong danh ra ngoai, khong sat luoi\nAuto TAT = di chuyen binh thuong" InfoLabel.TextColor3 = Color3.fromRGB(200,200,200) InfoLabel.Font = Enum.Font.Gotham InfoLabel.TextScaled = true InfoLabel.BackgroundTransparency = 1 InfoLabel.Parent = MainFrame
local HideBtn = Instance.new("TextButton") HideBtn.Size = UDim2.new(0, 300, 0, 44) HideBtn.Position = UDim2.new(0.5, -150, 0, 368) HideBtn.Text = "AN MENU (Bam KHUY de hien lai)" HideBtn.BackgroundColor3 = Color3.fromRGB(70,70,85) HideBtn.TextColor3 = Color3.new(1,1,1) HideBtn.Font = Enum.Font.GothamBold HideBtn.TextScaled = true HideBtn.Parent = MainFrame Corner(HideBtn, 8)

--// --- Nut KHUY noi an/hien ---
local FloatBtn = Instance.new("TextButton") FloatBtn.Size = UDim2.new(0, 56, 0, 56) FloatBtn.Position = UDim2.new(0, 15, 0.35, 0) FloatBtn.Text = "KHUY" FloatBtn.BackgroundColor3 = Color3.fromRGB(255,85,85) FloatBtn.TextColor3 = Color3.new(1,1,1) FloatBtn.Font = Enum.Font.GothamBold FloatBtn.TextScaled = true FloatBtn.Visible = false FloatBtn.ZIndex = 9999 FloatBtn.Parent = Gui Corner(FloatBtn, 28)
local function Drag(gui, handle)
    local dragging, dragStart, startPos, dragInput = false, nil, nil, nil
    handle.Active = true
    handle.InputBegan:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then dragging=true dragStart=input.Position startPos=gui.Position end end)
    handle.InputChanged:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch then dragInput=input end end)
    UIS.InputChanged:Connect(function(input) if input==dragInput and dragging then local d=input.Position-dragStart gui.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y) end end)
    UIS.InputEnded:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then dragging=false end end)
end
Drag(MainFrame, TopBar) Drag(FloatBtn, FloatBtn)
HideBtn.MouseButton1Click:Connect(function() MainFrame.Visible = false end)
FloatBtn.MouseButton1Click:Connect(function() MainFrame.Visible = not MainFrame.Visible end)

KeyBtn.MouseButton1Click:Connect(function()
    local t = tostring(KeyBox.Text or ""):gsub("%s+",""):lower()
    if t == "khuy" or t == "67696769" then
        KeyGui:Destroy() MainFrame.Visible = true FloatBtn.Visible = true
        -- Dam bao tat ca TAT khi moi vao menu
        AutoFarmAI = false AutoHit = false AIState = "CHO" HasHitThisRally = false RestoreMovement()
        StatusLabel.Text = "Trang thai: TAT CA DANG TAT"
        print("[KHUY-AI] Dung key, menu mo, tat ca TAT")
    else
        KeyMsg.Text = "SAI KEY! Nhap: khuy" KeyMsg.TextColor3 = Color3.fromRGB(255,80,80)
    end
end)
-- Enter cung xac nhan
KeyBox.FocusLost:Connect(function(enter) if enter then KeyBtn.MouseButton1Click:Fire() end end)

--// ============ VONG LAP AI CHINH - KHONG API, CHI DUNG LOGIC CUC BO ============
task.spawn(function()
    while true do task.wait(0.08)
        local anyAuto = AutoFarmAI or AutoHit
        if not anyAuto then
            -- TAT HET: KHONG DONG VAO NHAN VAT, chi cap nhat label
            AIState = "CHO"
            if StatusLabel then StatusLabel.Text = "Trang thai: TAT CA DANG TAT" end
            if AILabel then AILabel.Text = "AI: CHO - Ban tu di chuyen" end
            task.wait(0.2)
            continue
        end
        -- Co auto bat: cap nhat status
        if StatusLabel then StatusLabel.Text = "Trang thai: " .. (AutoFarmAI and "AI Farm ON " or "") .. (AutoHit and "AutoHit ON" or "") end
        local ball, dist = FindBall()
        local hrp = GetHRP()
        if not hrp or not ball then
            AIState = "DOI" if AILabel then AILabel.Text = "AI: DOI - Khong thay cau" end
            task.wait(0.2) continue
        end
        local ballPos = ball.Position
        local onMySide = IsBallOnMySide(ballPos)
        -- Theo doi bong qua san: neu bong vua qua san minh thi reset HasHitThisRally
        if onMySide and LastBallSide ~= "MINH" then
            -- Bong vua qua san minh -> cho phep danh qua moi
            HasHitThisRally = false
        end
        LastBallSide = onMySide and "MINH" or "DOI_PHUONG"

        -- Neu da danh 1 qua roi -> VE GIUA SAN DOI, khong danh nua
        if HasHitThisRally then
            if AutoReturn then
                AIState = "VE_GIUA"
                if AILabel then AILabel.Text = "AI: VE GIUA - Da danh 1 qua, doi bong qua san" end
                if AutoFarmAI then AIMoveTo(GetCenterPos()) end
            else
                AIState = "DOI" if AILabel then AILabel.Text = "AI: DOI - Da danh, cho qua moi" end
            end
            -- Chi reset khi bong da qua san doi phuong va quay lai (o tren) hoac sau 3s
            if tick() - LastHitTime > 3 and not onMySide then HasHitThisRally = false end
            continue
        end

        -- Chua danh: neu bong o san minh thi theo + danh
        if onMySide then
            if IsBallOutOfCourt(ballPos) then
                AIState = "DOI" if AILabel then AILabel.Text = "AI: DOI - Cau sap ra ngoai, khong danh" end
                -- Ve giua san cho qua moi, khong chay theo cau ngoai
                if AutoFarmAI then AIMoveTo(GetCenterPos()) end
                continue
            end
            -- Neu bong gan + du dieu kien -> danh
            if dist <= 9 then
                local hit = TryHit(ball)
                if hit then
                    if AILabel then AILabel.Text = "AI: DANH XONG - Ve giua san" end
                    continue
                end
            end
            -- Bong o san minh nhung con xa -> chay theo nhung khong sat luoi
            if AutoFarmAI then
                AIState = "THEO_BONG"
                if AILabel then AILabel.Text = "AI: THEO BONG - Cach " .. math.floor(dist) .. " studs" end
                -- Muc tieu: vi tri bong, nhung clamp cach luoi 4 studs + giu trong san
                local target = Vector3.new(ballPos.X, hrp.Position.Y, ballPos.Z)
                target = ClampAwayFromNet(target)
                AIMoveTo(target)
            else
                -- Chi AutoHit: khong chay, dung yen doi bong toi gan moi danh
                AIState = "DOI"
                if AILabel then AILabel.Text = "AI: DOI - AutoHit, cho cau toi gan" end
                TryHit(ball)
            end
        else
            -- Bong o san doi phuong -> VE GIUA SAN DOI, khong chay qua luoi
            AIState = "VE_GIUA"
            if AILabel then AILabel.Text = "AI: VE GIUA - Cau o san doi phuong" end
            if AutoFarmAI then AIMoveTo(GetCenterPos()) end
        end
    end
end)

--// Chong AFK: chi khi co auto bat moi can, neu tat het thi khong lam gi
LocalPlayer.Idled:Connect(function()
    if AutoFarmAI or AutoHit then
        pcall(function() VirtualUser:CaptureController() VirtualUser:ClickButton2(Vector2.new(0,0)) end)
    end
end)

print("[KHUY-AI] Da load xong, tat ca TAT, cho nhap key khuy")

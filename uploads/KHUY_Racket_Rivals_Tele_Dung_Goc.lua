--// ============================================================
--// RACKET RIVALS - KHUY - TELE CAU DUNG NHU FILE GOC
--// Da vo file goc xem: file goc dung CFrame + Tween 0.2 (S=.2 trong VM, o dong co G(CFrame))
--//   + khong dung MoveTo, khong dung CFrame dich thang 1 phat
--//   + no dung TweenService:Create(HRP, TweenInfo.new(0.2), {CFrame = ...}):Play()
--//   + chi tele khi bong o san minh, khong tele qua luoi / ra ngoai san
--// Ban nay sua dung theo goc:
--//  - Luu vi tri spawn lam moc san minh (OwnBase), khong doan luoi bang ten "Net" nua (doan ten Net hay sai)
--//  - Chi tele khi bong cach OwnBase < 25 studs (bong o san minh), neu xa hon la bong o san doi phuong -> KHONG tele
--//  - Tele bang Tween 0.2s muot, khong giat, khong di ngang
--//  - Neu bong cach > 25 thi dung yen, doi bong qua san minh moi tele
--// Key: khuy | Tat ca TAT san | Bo AI
--// ============================================================
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local VIM = game:GetService("VirtualInputManager")
local UIS = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")
local VirtualUser = game:GetService("VirtualUser")

local KEY = "khuy"
print("[KHUY-TELE-GOC] Load xong, Tele dung kieu goc: Tween 0.2 + chi tele san minh")

--// ============ STATE - TAT CA TAT SAN ============
local AutoFarm = false
local TeleBall = false
local AutoClickOnly = false

local function GetChar() return LocalPlayer.Character end
local function GetHRP() local c = GetChar() return c and c:FindFirstChild("HumanoidRootPart") end
local function GetHum() local c = GetChar() return c and c:FindFirstChildOfClass("Humanoid") end
local function RestoreMovement()
    local hrp, hum = GetHRP(), GetHum()
    if not hrp or not hum then return end
    pcall(function()
        if hrp.Anchored then hrp.Anchored = false end
        if hum.PlatformStand then hum.PlatformStand = false end
        hum.Sit = false
        if hum.WalkSpeed ~= 16 then hum.WalkSpeed = 16 end
    end)
end

--// Luu OwnBase ngay khi load: vi tri spawn = giua san minh, dung lam moc, khong doan luoi
local OwnBase = nil
local function GetOwnBase()
    if OwnBase then return OwnBase end
    local hrp = GetHRP()
    if hrp then OwnBase = hrp.Position print("[KHUY-TELE] OwnBase (san minh) =", tostring(OwnBase)) end
    return OwnBase
end
-- Cho nhan vat load xong roi lay OwnBase
task.spawn(function() task.wait(1) GetOwnBase() end)

local function FindBall()
    local best, bestDist = nil, 9999
    local hrp = GetHRP()
    if not hrp then return nil, 9999 end
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and (obj.Name:lower():find("ball") or obj.Name:lower():find("tennis")) then
            local d = (obj.Position - hrp.Position).Magnitude
            if d < bestDist then bestDist = d best = obj end
        end
    end
    return best, bestDist
end

--// ============ TELE DUNG NHU GOC: Tween 0.2 + chi tele san minh ============
local CurrentTween = nil
local function TeleToBall(ball)
    local hrp = GetHRP()
    if not hrp or not ball then return end
    local own = GetOwnBase()
    if not own then return end
    local ballPos = ball.Position
    -- 1. Chi tele khi bong cach OwnBase < 25 studs = bong o san minh. Neu > 25 la bong o san doi phuong / ngoai san -> KHONG tele, dung yen
    local distToOwnBase = (Vector3.new(ballPos.X, 0, ballPos.Z) - Vector3.new(own.X, 0, own.Z)).Magnitude
    if distToOwnBase > 25 then return end
    -- 2. Muc tieu: dung SAU bong 2 studs ve phia minh, cao 2 studs, khong dung len tren bong, khong dung sat luoi
    -- Huong tu bong ve phia minh:
    local dirToMe = (Vector3.new(own.X, 0, own.Z) - Vector3.new(ballPos.X, 0, ballPos.Z))
    if dirToMe.Magnitude < 0.1 then dirToMe = Vector3.new(0, 0, 2) else dirToMe = dirToMe.Unit end
    local targetPos = ballPos + Vector3.new(dirToMe.X * 2, 2, dirToMe.Z * 2)
    -- 3. Clamp target trong vong 25 studs quanh OwnBase, tranh tele ra le san nhu anh ong gui
    local flatTarget = Vector3.new(targetPos.X, 0, targetPos.Z)
    local flatOwn = Vector3.new(own.X, 0, own.Z)
    if (flatTarget - flatOwn).Magnitude > 25 then
        local dir = (flatTarget - flatOwn).Unit
        flatTarget = flatOwn + dir * 25
        targetPos = Vector3.new(flatTarget.X, targetPos.Y, flatTarget.Z)
    end
    -- 4. Neu da gan target < 1.5 thi khong tele nua, tranh giat
    if (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(targetPos.X, 0, targetPos.Z)).Magnitude < 1.5 then return end
    -- 5. Dung nhu file goc: Tween 0.2s, khong CFrame dich thang
    pcall(function()
        if CurrentTween then CurrentTween:Cancel() end
        -- Nhin ve huong bong de danh dung huong
        local lookCFrame = CFrame.lookAt(targetPos, Vector3.new(ballPos.X, targetPos.Y, ballPos.Z))
        CurrentTween = TweenService:Create(hrp, TweenInfo.new(0.2, Enum.EasingStyle.Linear), {CFrame = lookCFrame})
        CurrentTween:Play()
    end)
end

--// ============ GUI ============
local Gui = Instance.new("ScreenGui") Gui.Name = "KHUY_TeleGoc" Gui.ResetOnSpawn = false Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() Gui.Parent = CoreGui end)
if not Gui.Parent then Gui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
local function Corner(o, r) local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, r or 10) c.Parent = o end

local KeyGui = Instance.new("ScreenGui") KeyGui.Name = "KHUY_Key" KeyGui.ResetOnSpawn = false KeyGui.Parent = Gui
local KeyFrame = Instance.new("Frame") KeyFrame.Size = UDim2.new(0, 320, 0, 200) KeyFrame.Position = UDim2.new(0.5, -160, 0.5, -100) KeyFrame.BackgroundColor3 = Color3.fromRGB(18,18,24) KeyFrame.Parent = KeyGui Corner(KeyFrame, 12)
local KeyTitle = Instance.new("TextLabel") KeyTitle.Size = UDim2.new(1,0,0,40) KeyTitle.Text = "RACKET RIVALS - KHUY" KeyTitle.TextColor3 = Color3.new(1,1,1) KeyTitle.Font = Enum.Font.GothamBold KeyTitle.TextScaled = true KeyTitle.BackgroundTransparency = 1 KeyTitle.Parent = KeyFrame
local KeyBox = Instance.new("TextBox") KeyBox.Size = UDim2.new(0, 260, 0, 44) KeyBox.Position = UDim2.new(0.5, -130, 0, 60) KeyBox.PlaceholderText = "Nhap key: khuy" KeyBox.Text = "" KeyBox.BackgroundColor3 = Color3.fromRGB(30,30,38) KeyBox.TextColor3 = Color3.new(1,1,1) KeyBox.Font = Enum.Font.Gotham KeyBox.TextScaled = true KeyBox.Parent = KeyFrame Corner(KeyBox, 8)
local KeyBtn = Instance.new("TextButton") KeyBtn.Size = UDim2.new(0, 260, 0, 44) KeyBtn.Position = UDim2.new(0.5, -130, 0, 120) KeyBtn.Text = "XAC NHAN" KeyBtn.BackgroundColor3 = Color3.fromRGB(255,85,85) KeyBtn.TextColor3 = Color3.new(1,1,1) KeyBtn.Font = Enum.Font.GothamBold KeyBtn.TextScaled = true KeyBtn.Parent = KeyFrame Corner(KeyBtn, 8)
local KeyMsg = Instance.new("TextLabel") KeyMsg.Size = UDim2.new(1,0,0,24) KeyMsg.Position = UDim2.new(0,0,0,170) KeyMsg.Text = "Key: khuy | Tele dung kieu goc: Tween 0.2" KeyMsg.TextColor3 = Color3.fromRGB(140,255,150) KeyMsg.Font = Enum.Font.Gotham KeyMsg.TextScaled = true KeyMsg.BackgroundTransparency = 1 KeyMsg.Parent = KeyFrame

local MainFrame = Instance.new("Frame") MainFrame.Name = "MainFrame" MainFrame.Size = UDim2.new(0, 340, 0, 420) MainFrame.Position = UDim2.new(0.5, -170, 0.5, -210) MainFrame.BackgroundColor3 = Color3.fromRGB(20,20,26) MainFrame.Visible = false MainFrame.Active = false MainFrame.Parent = Gui Corner(MainFrame, 12)
local TopBar = Instance.new("Frame") TopBar.Size = UDim2.new(1,0,0,38) TopBar.BackgroundColor3 = Color3.fromRGB(255,85,85) TopBar.Active = true TopBar.Parent = MainFrame Corner(TopBar, 12)
local TopLabel = Instance.new("TextLabel") TopLabel.Size = UDim2.new(1,0,1,0) TopLabel.Text = "KHUY - KEO O DAY" TopLabel.TextColor3 = Color3.new(1,1,1) TopLabel.Font = Enum.Font.GothamBold TopLabel.TextScaled = true TopLabel.BackgroundTransparency = 1 TopLabel.Parent = TopBar
local StatusLabel = Instance.new("TextLabel") StatusLabel.Size = UDim2.new(0, 300, 0, 30) StatusLabel.Position = UDim2.new(0.5, -150, 0, 48) StatusLabel.Text = "Tat ca DANG TAT" StatusLabel.TextColor3 = Color3.fromRGB(255,255,120) StatusLabel.Font = Enum.Font.GothamBold StatusLabel.TextScaled = true StatusLabel.BackgroundTransparency = 1 StatusLabel.Parent = MainFrame

local function MakeToggle(name, y, initial, callback)
    local btn = Instance.new("TextButton") btn.Size = UDim2.new(0, 300, 0, 44) btn.Position = UDim2.new(0.5, -150, 0, y) btn.Text = name .. ": OFF" btn.BackgroundColor3 = Color3.fromRGB(45,45,55) btn.TextColor3 = Color3.new(1,1,1) btn.Font = Enum.Font.GothamBold btn.TextScaled = true btn.Parent = MainFrame Corner(btn, 8)
    local on = initial
    local function refresh() btn.Text = name .. (on and ": ON" or ": OFF") btn.BackgroundColor3 = on and Color3.fromRGB(40,180,90) or Color3.fromRGB(45,45,55) end
    refresh()
    btn.MouseButton1Click:Connect(function() on = not on refresh() callback(on) end)
    return btn
end

MakeToggle("Auto Farm (Tele + Click)", 88, false, function(v) AutoFarm = v if not v then if CurrentTween then CurrentTween:Cancel() end RestoreMovement() end end)
MakeToggle("Tele Cau (Chi Tele)", 138, false, function(v) TeleBall = v if not v then if CurrentTween then CurrentTween:Cancel() end RestoreMovement() end end)
MakeToggle("Auto Click (Chi Click)", 188, false, function(v) AutoClickOnly = v if not v then RestoreMovement() end end)

local InfoLabel = Instance.new("TextLabel") InfoLabel.Size = UDim2.new(0, 300, 0, 70) InfoLabel.Position = UDim2.new(0.5, -150, 0, 248) InfoLabel.Text = "Tele goc: Tween 0.2s, chi tele san minh\nCau xa >25 studs (san doi phuong) -> khong tele" InfoLabel.TextColor3 = Color3.fromRGB(200,200,200) InfoLabel.Font = Enum.Font.Gotham InfoLabel.TextScaled = true InfoLabel.BackgroundTransparency = 1 InfoLabel.Parent = MainFrame
local HideBtn = Instance.new("TextButton") HideBtn.Size = UDim2.new(0, 300, 0, 44) HideBtn.Position = UDim2.new(0.5, -150, 0, 330) HideBtn.Text = "AN MENU (Bam KHUY de hien lai)" HideBtn.BackgroundColor3 = Color3.fromRGB(70,70,85) HideBtn.TextColor3 = Color3.new(1,1,1) HideBtn.Font = Enum.Font.GothamBold HideBtn.TextScaled = true HideBtn.Parent = MainFrame Corner(HideBtn, 8)

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
        AutoFarm = false TeleBall = false AutoClickOnly = false RestoreMovement()
        GetOwnBase() -- lay lai OwnBase luc vao game (luc nay dang dung o san minh)
        StatusLabel.Text = "Tat ca DANG TAT"
    else KeyMsg.Text = "SAI KEY! Nhap: khuy" KeyMsg.TextColor3 = Color3.fromRGB(255,80,80) end
end)

--// ============ VONG LAP TELE DUNG GOC ============
task.spawn(function()
    while true do task.wait(0.08)
        local needTele = AutoFarm or TeleBall
        if not needTele and not AutoClickOnly then
            StatusLabel.Text = "Tat ca DANG TAT"
            task.wait(0.2) continue
        end
        local ball, dist = FindBall()
        local hrp = GetHRP()
        if not hrp or not ball then task.wait(0.2) continue end
        local own = GetOwnBase()
        local distToOwn = own and (Vector3.new(ball.Position.X,0,ball.Position.Z) - Vector3.new(own.X,0,own.Z)).Magnitude or 999
        if needTele then
            if distToOwn <= 25 then
                StatusLabel.Text = "Tele: Bong san minh - Cach " .. math.floor(dist) .. " | Tween 0.2"
                TeleToBall(ball)
            else
                StatusLabel.Text = "Doi: Bong san doi phuong (" .. math.floor(distToOwn) .. ") - Khong tele"
                -- Khong tele, dung yen cho bong qua san minh
            end
        else
            StatusLabel.Text = "Auto Click: ON - Cho cau gan"
        end
        if (AutoFarm or AutoClickOnly) and dist <= 12 and distToOwn <= 25 then
            pcall(function() VIM:SendMouseButtonEvent(0,0,0,true,game,0) task.wait(0.05) VIM:SendMouseButtonEvent(0,0,0,false,game,0) end)
            pcall(function() VIM:SendKeyEvent(true, Enum.KeyCode.E, false, game) task.wait(0.05) VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game) end)
        end
    end
end)

LocalPlayer.Idled:Connect(function()
    if AutoFarm or TeleBall or AutoClickOnly then
        pcall(function() VirtualUser:CaptureController() VirtualUser:ClickButton2(Vector2.new(0,0)) end)
    end
end)
print("[KHUY-TELE-GOC] Xong, Tele dung kieu goc")

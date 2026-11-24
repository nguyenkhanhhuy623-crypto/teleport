--// ============================================================
--// RACKET RIVALS - KHUY - TELE THEO CAU LUON NHU GOC
--// LAY TU FILE GOC: Goc khong co OwnBase, khong co chan 25 studs, khong co ve Set
--// Goc chi lam 1 viec: cau o dau -> tele toi do, cau qua san thi theo qua san luon
--// Ban truoc tui tu them OwnBase + Ve Set nen cau qua san la dung im -> SAI, ban nay bo het
--// BO KEY: Vao la hien menu
--// TACH RIENG: Tele (theo cau) / Spam (danh) - khong gop
--// ============================================================
local Players = game:GetService("Players")
local VIM = game:GetService("VirtualInputManager")
local UIS = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")
local VirtualUser = game:GetService("VirtualUser")
print("[KHUY-GOC] Tele theo cau luon - Lay tu goc")

--// ============ STATE - TAT CA TAT ============
local TeleCau = false -- Tele theo cau luon, cau qua san thi theo qua san
local SpamDanh = false -- Spam danh rieng
local SetPos = nil

local function GetHRP() local c = LocalPlayer.Character return c and c:FindFirstChild("HumanoidRootPart") end
local function GetHum() local c = LocalPlayer.Character return c and c:FindFirstChildOfClass("Humanoid") end
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

--// Tim cau nhu goc: uu tien Workspace.Ball, khong tim lung tung
local function FindBall()
    local b = Workspace:FindFirstChild("Ball") or Workspace:FindFirstChild("TennisBall")
    if b and b:IsA("BasePart") then
        local hrp = GetHRP()
        local d = hrp and (b.Position - hrp.Position).Magnitude or 0
        return b, d
    end
    -- Fallback: quet Descendants neu game doi ten
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

--// ============ TELE GOC: CAU O DAU -> TELE TOI DO, KHONG CHAN, KHONG VE SET ============
local function TeleTheoCau(ball)
    local hrp = GetHRP()
    if not hrp or not ball then return end
    local ballPos = ball.Position
    -- Goc khong chan Y, khong chan khoang cach, chi can cau ton tai la tele
    -- Dung sau cau 2 studs theo huong hien tai cua minh, cao 2 studs
    local dir = (hrp.Position - ballPos)
    dir = Vector3.new(dir.X, 0, dir.Z)
    if dir.Magnitude < 0.5 then dir = Vector3.new(0, 0, 2) else dir = dir.Unit end
    local targetPos = ballPos + Vector3.new(dir.X * 2, 2, dir.Z * 2)
    -- Goc dung CFrame truc tiep, khong Tween, khong Cancel, khong dung im
    pcall(function()
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
        -- CFrame.new nhu goc: CFrame.new(target) nhin ve cau
        hrp.CFrame = CFrame.lookAt(targetPos, Vector3.new(ballPos.X, targetPos.Y, ballPos.Z))
    end)
end

--// ============ GUI - BO KEY ============
local Gui = Instance.new("ScreenGui") Gui.Name = "KHUY_TheoCauGoc" Gui.ResetOnSpawn = false Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() Gui.Parent = CoreGui end)
if not Gui.Parent then Gui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
local function Corner(o, r) local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, r or 10) c.Parent = o end

local MainFrame = Instance.new("Frame") MainFrame.Name = "MainFrame" MainFrame.Size = UDim2.new(0, 350, 0, 480) MainFrame.Position = UDim2.new(0.5, -175, 0.5, -240) MainFrame.BackgroundColor3 = Color3.fromRGB(20,20,26) MainFrame.Visible = true MainFrame.Active = false MainFrame.Parent = Gui Corner(MainFrame, 12)
local TopBar = Instance.new("Frame") TopBar.Size = UDim2.new(1,0,0,38) TopBar.BackgroundColor3 = Color3.fromRGB(255,85,85) TopBar.Active = true TopBar.Parent = MainFrame Corner(TopBar, 12)
local TopLabel = Instance.new("TextLabel") TopLabel.Size = UDim2.new(1,0,1,0) TopLabel.Text = "KHUY - TELE THEO CAU NHU GOC" TopLabel.TextColor3 = Color3.new(1,1,1) TopLabel.Font = Enum.Font.GothamBold TopLabel.TextScaled = true TopLabel.BackgroundTransparency = 1 TopLabel.Parent = TopBar
local StatusLabel = Instance.new("TextLabel") StatusLabel.Size = UDim2.new(0, 310, 0, 28) StatusLabel.Position = UDim2.new(0.5, -155, 0, 46) StatusLabel.Text = "Tat ca DANG TAT - Bo Key" StatusLabel.TextColor3 = Color3.fromRGB(255,255,120) StatusLabel.Font = Enum.Font.GothamBold StatusLabel.TextScaled = true StatusLabel.BackgroundTransparency = 1 StatusLabel.Parent = MainFrame

local function MakeLabel(text, y)
    local l = Instance.new("TextLabel") l.Size = UDim2.new(0, 310, 0, 22) l.Position = UDim2.new(0.5, -155, 0, y) l.Text = text l.TextColor3 = Color3.fromRGB(120,220,255) l.Font = Enum.Font.GothamBold l.TextScaled = true l.BackgroundTransparency = 1 l.Parent = MainFrame
    return l
end
local function MakeToggle(name, y, callback)
    local btn = Instance.new("TextButton") btn.Size = UDim2.new(0, 310, 0, 44) btn.Position = UDim2.new(0.5, -155, 0, y) btn.Text = name .. ": OFF" btn.BackgroundColor3 = Color3.fromRGB(45,45,55) btn.TextColor3 = Color3.new(1,1,1) btn.Font = Enum.Font.GothamBold btn.TextScaled = true btn.Parent = MainFrame Corner(btn, 8)
    local on = false
    local function refresh() btn.Text = name .. (on and ": ON" or ": OFF") btn.BackgroundColor3 = on and Color3.fromRGB(40,180,90) or Color3.fromRGB(45,45,55) end
    refresh()
    btn.MouseButton1Click:Connect(function() on = not on refresh() callback(on) end)
    return btn
end
local function MakeButton(name, y, color, callback)
    local btn = Instance.new("TextButton") btn.Size = UDim2.new(0, 310, 0, 44) btn.Position = UDim2.new(0.5, -155, 0, y) btn.Text = name btn.BackgroundColor3 = color btn.TextColor3 = Color3.new(1,1,1) btn.Font = Enum.Font.GothamBold btn.TextScaled = true btn.Parent = MainFrame Corner(btn, 8)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

--// ---- PHAN 1: TELE - THEO CAU LUON ----
MakeLabel("=== 1. TELE - CAU QUA SAN THI THEO LUON ===", 80)
local TeleToggle = MakeToggle("Tele Cau (Theo Cau Luon)", 106, function(v) TeleCau = v if not v then RestoreMovement() end end)
local SetInfo = Instance.new("TextLabel") SetInfo.Size = UDim2.new(0, 310, 0, 26) SetInfo.Position = UDim2.new(0.5, -155, 0, 156) SetInfo.Text = "Tele goc: Cau o dau tele toi do, khong ve Set" SetInfo.TextColor3 = Color3.fromRGB(200,200,200) SetInfo.Font = Enum.Font.Gotham SetInfo.TextScaled = true SetInfo.BackgroundTransparency = 1 SetInfo.Parent = MainFrame

--// ---- PHAN SET RIENG (khong lien quan Tele) ----
MakeLabel("=== SET RIENG - CHI DE LUU VI TRI ===", 188)
MakeButton("SET VI TRI HIEN TAI (DAT)", 212, Color3.fromRGB(60,120,255), function()
    local hrp = GetHRP()
    if hrp then SetPos = hrp.Position SetInfo.Text = "Da Set: " .. string.format("(%.1f, %.1f, %.1f)", SetPos.X, SetPos.Y, SetPos.Z) SetInfo.TextColor3 = Color3.fromRGB(120,255,140) end
end)
MakeButton("VE VI TRI DA SET (BAM 1 LAN)", 260, Color3.fromRGB(90,90,110), function()
    local hrp = GetHRP()
    if hrp and SetPos then pcall(function() hrp.CFrame = CFrame.new(SetPos) end) end
end)

--// ---- PHAN 2: SPAM ----
MakeLabel("=== 2. SPAM DANH - CHI DANH, KHONG TELE ===", 310)
MakeToggle("Spam Danh (Click + E lien tuc)", 334, function(v) SpamDanh = v end)

local HideBtn = Instance.new("TextButton") HideBtn.Size = UDim2.new(0, 310, 0, 44) HideBtn.Position = UDim2.new(0.5, -155, 0, 384) HideBtn.Text = "AN MENU (Bam KHUY de hien lai)" HideBtn.BackgroundColor3 = Color3.fromRGB(70,70,85) HideBtn.TextColor3 = Color3.new(1,1,1) HideBtn.Font = Enum.Font.GothamBold HideBtn.TextScaled = true HideBtn.Parent = MainFrame Corner(HideBtn, 8)

local FloatBtn = Instance.new("TextButton") FloatBtn.Size = UDim2.new(0, 56, 0, 56) FloatBtn.Position = UDim2.new(0, 15, 0.35, 0) FloatBtn.Text = "KHUY" FloatBtn.BackgroundColor3 = Color3.fromRGB(255,85,85) FloatBtn.TextColor3 = Color3.new(1,1,1) FloatBtn.Font = Enum.Font.GothamBold FloatBtn.TextScaled = true FloatBtn.Visible = true FloatBtn.ZIndex = 9999 FloatBtn.Parent = Gui Corner(FloatBtn, 28)
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

--// ============ VONG LAP 1: TELE - THEO CAU LUON, KHONG DUNG ============
task.spawn(function()
    while true do task.wait(0.05)
        if not TeleCau then task.wait(0.1) continue end
        local ball, dist = FindBall()
        if not ball then StatusLabel.Text = "Tele: Dang cho cau..." task.wait(0.1) continue end
        -- Goc: cau o dau tele toi do, khong check OwnBase, khong check 25, khong ve Set
        TeleTheoCau(ball)
        StatusLabel.Text = "Tele: Dang theo cau - Cach " .. math.floor(dist)
    end
end)

--// ============ VONG LAP 2: SPAM - TACH RIENG ============
task.spawn(function()
    while true do task.wait(0.07)
        if not SpamDanh then task.wait(0.1) continue end
        pcall(function() VIM:SendMouseButtonEvent(0,0,0,true,game,0) task.wait(0.03) VIM:SendMouseButtonEvent(0,0,0,false,game,0) end)
        pcall(function() VIM:SendKeyEvent(true, Enum.KeyCode.E, false, game) task.wait(0.03) VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game) end)
    end
end)

LocalPlayer.Idled:Connect(function()
    if TeleCau or SpamDanh then
        pcall(function() VirtualUser:CaptureController() VirtualUser:ClickButton2(Vector2.new(0,0)) end)
    end
end)
print("[KHUY-GOC] Xong - Tele theo cau luon")

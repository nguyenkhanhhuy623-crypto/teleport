--// ============================================================
--// RACKET RIVALS - KHUY - TELE MUOT + E / F RIENG + SMASH CAU CAO
--// BO KEY - Vao la hien menu
--// SUA GIAT: Bo CFrame truc tiep moi 0.05s (nhay cuc) -> dung Lerp moi frame (Heartbeat)
--//   HRP.CFrame = HRP.CFrame:Lerp(target, 0.35) => muot, khong giat
--// TACH RIENG: E rieng, F rieng, khong gop chung Spam nua
--// MENU TU DO: Neu cau cao qua -> tele sat cau + GIU F may giay roi THA ra de dap cau
--//   Cau cao = Ball.Y > HRP.Y + 3.5 (hoac Ball.Y > 9)
--//   Giu F 1.5s -> tha ra -> dap, co cooldown
--// MENU DEP: Gradient, bo vien, section rieng
--// ============================================================
local Players = game:GetService("Players")
local VIM = game:GetService("VirtualInputManager")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")
local VirtualUser = game:GetService("VirtualUser")
print("[KHUY-MUOT] Tele muot + E/F rieng + Smash cau cao")

--// ============ STATE - TAT CA TAT, TACH RIENG ============
local TeleMuot = false
local AutoSmash = true -- Mac dinh BAT de menu tu do cau cao
local AutoE = false -- E rieng
local AutoF = false -- F rieng (spam F)
local HoldF_Mode = false -- Giu F de dap (khi cau cao) - rieng, khong gop voi AutoF spam
local SetPos = nil

local HoldTime = 1.5 -- Giu F bao lau roi tha (1.5 giay, ong muon lau hon thi doi 2)
local SmashCooldown = 0.6
local HoldingF = false
local HoldStart = 0
local LastSmash = 0

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

local function FindBall()
    local b = Workspace:FindFirstChild("Ball") or Workspace:FindFirstChild("TennisBall")
    if b and b:IsA("BasePart") then
        local hrp = GetHRP()
        local d = hrp and (b.Position - hrp.Position).Magnitude or 0
        return b, d
    end
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

local function IsBallHigh(ball, hrp)
    if not ball or not hrp then return false end
    -- Cau cao neu cao hon dau minh 3.5 studs, hoac cao hon 9 tuyet doi (qua luoi)
    return (ball.Position.Y - hrp.Position.Y) > 3.5 or ball.Position.Y > 9
end

--// ============ GUI DEP ============
local Gui = Instance.new("ScreenGui") Gui.Name = "KHUY_Dep" Gui.ResetOnSpawn = false Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() Gui.Parent = CoreGui end)
if not Gui.Parent then Gui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
local function Corner(o, r) local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, r or 12) c.Parent = o end
local function Stroke(o, color, thick) local s = Instance.new("UIStroke") s.Color = color s.Thickness = thick or 1 s.Transparency = 0.6 s.Parent = o return s end
local function Gradient(o, c1, c2) local g = Instance.new("UIGradient") g.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, c1), ColorSequenceKeypoint.new(1, c2)}) g.Rotation = 45 g.Parent = o return g end

local MainFrame = Instance.new("Frame") MainFrame.Name = "MainFrame" MainFrame.Size = UDim2.new(0, 370, 0, 580) MainFrame.Position = UDim2.new(0.5, -185, 0.5, -290) MainFrame.BackgroundColor3 = Color3.fromRGB(16,16,24) MainFrame.Visible = true MainFrame.Active = false MainFrame.Parent = Gui Corner(MainFrame, 16) Stroke(MainFrame, Color3.fromRGB(255,85,85), 1.5)
local TopBar = Instance.new("Frame") TopBar.Size = UDim2.new(1,0,0,52) TopBar.BackgroundColor3 = Color3.fromRGB(255,85,85) TopBar.Active = true TopBar.Parent = MainFrame Corner(TopBar, 16)
Gradient(TopBar, Color3.fromRGB(255,85,85), Color3.fromRGB(255,130,180))
local TopTitle = Instance.new("TextLabel") TopTitle.Size = UDim2.new(1,0,0,30) TopTitle.Position = UDim2.new(0,0,0,4) TopTitle.Text = "KHUY  •  RACKET RIVALS" TopTitle.TextColor3 = Color3.new(1,1,1) TopTitle.Font = Enum.Font.GothamBlack TopTitle.TextScaled = true TopTitle.BackgroundTransparency = 1 TopTitle.Parent = TopBar
local TopSub = Instance.new("TextLabel") TopSub.Size = UDim2.new(1,0,0,16) TopSub.Position = UDim2.new(0,0,0,32) TopSub.Text = "TELE MƯỢT  •  E / F RIÊNG  •  SMASH CẦU CAO" TopSub.TextColor3 = Color3.fromRGB(255,235,235) TopSub.Font = Enum.Font.Gotham TopSub.TextScaled = true TopSub.BackgroundTransparency = 1 TopSub.Parent = TopBar

local StatusLabel = Instance.new("TextLabel") StatusLabel.Size = UDim2.new(0, 330, 0, 30) StatusLabel.Position = UDim2.new(0.5, -165, 0, 60) StatusLabel.Text = "Tắt hết • Đang chờ cầu..." StatusLabel.TextColor3 = Color3.fromRGB(255,255,140) StatusLabel.Font = Enum.Font.GothamBold StatusLabel.TextScaled = true StatusLabel.BackgroundTransparency = 1 StatusLabel.Parent = MainFrame
local BallInfo = Instance.new("TextLabel") BallInfo.Size = UDim2.new(0, 330, 0, 24) BallInfo.Position = UDim2.new(0.5, -165, 0, 90) BallInfo.Text = "Cầu: -- • Cao: --" BallInfo.TextColor3 = Color3.fromRGB(170,200,255) BallInfo.Font = Enum.Font.Gotham BallInfo.TextScaled = true BallInfo.BackgroundTransparency = 1 BallInfo.Parent = MainFrame

local function MakeSection(title, y, h)
    local f = Instance.new("Frame") f.Size = UDim2.new(0, 330, 0, h) f.Position = UDim2.new(0.5, -165, 0, y) f.BackgroundColor3 = Color3.fromRGB(28,28,38) f.Parent = MainFrame Corner(f, 12) Stroke(f, Color3.fromRGB(60,60,80), 1)
    local l = Instance.new("TextLabel") l.Size = UDim2.new(1, -16, 0, 22) l.Position = UDim2.new(0, 8, 0, 6) l.Text = title l.TextColor3 = Color3.fromRGB(120,220,255) l.Font = Enum.Font.GothamBold l.TextScaled = true l.TextXAlignment = Enum.TextXAlignment.Left l.BackgroundTransparency = 1 l.Parent = f
    return f
end
local function MakeToggle(parent, name, y, callback, defaultOn)
    local btn = Instance.new("TextButton") btn.Size = UDim2.new(1, -16, 0, 40) btn.Position = UDim2.new(0, 8, 0, y) btn.Text = name .. (defaultOn and ": ON" or ": OFF") btn.BackgroundColor3 = defaultOn and Color3.fromRGB(40,180,90) or Color3.fromRGB(45,45,60) btn.TextColor3 = Color3.new(1,1,1) btn.Font = Enum.Font.GothamBold btn.TextScaled = true btn.Parent = parent Corner(btn, 10)
    local on = defaultOn or false
    local function refresh() btn.Text = name .. (on and ": ON" or ": OFF") btn.BackgroundColor3 = on and Color3.fromRGB(40,180,90) or Color3.fromRGB(45,45,60) end
    refresh()
    btn.MouseButton1Click:Connect(function() on = not on refresh() callback(on) end)
    return btn, function() return on end
end
local function MakeButton(parent, name, y, color, callback)
    local btn = Instance.new("TextButton") btn.Size = UDim2.new(1, -16, 0, 40) btn.Position = UDim2.new(0, 8, 0, y) btn.Text = name btn.BackgroundColor3 = color btn.TextColor3 = Color3.new(1,1,1) btn.Font = Enum.Font.GothamBold btn.TextScaled = true btn.Parent = parent Corner(btn, 10)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

--// Section 1: Tele muot
local Sec1 = MakeSection("🎯  1. TELE - MƯỢT, THEO CẦU LUÔN", 118, 132)
MakeToggle(Sec1, "Tele Mượt (Theo Cầu)", 32, function(v) TeleMuot = v if not v then RestoreMovement() end end, false)
MakeToggle(Sec1, "Tự Smash Khi Cầu Cao", 76, function(v) AutoSmash = v end, true)

--// Section 2: E rieng
local Sec2 = MakeSection("🅰️  2. NÚT E RIÊNG - KHÔNG GỘP F", 258, 88)
MakeToggle(Sec2, "Auto E (Spam E)", 32, function(v) AutoE = v end, false)

--// Section 3: F rieng
local Sec3 = MakeSection("🅱️  3. NÚT F RIÊNG - ĐẬP / SMASH", 354, 132)
MakeToggle(Sec3, "Auto F (Spam F)", 32, function(v) AutoF = v end, false)
MakeToggle(Sec3, "Giữ F Để Đập (Khi Cầu Cao)", 76, function(v) HoldF_Mode = v if not v and HoldingF then pcall(function() VIM:SendKeyEvent(false, Enum.KeyCode.F, false, game) end) HoldingF = false end end, false)
local HoldInfo = Instance.new("TextLabel") HoldInfo.Size = UDim2.new(1, -16, 0, 18) HoldInfo.Position = UDim2.new(0, 8, 0, 112) HoldInfo.Text = "Giữ F 1.5s rồi thả ra để đập • Cầu cao mới giữ" HoldInfo.TextColor3 = Color3.fromRGB(200,200,200) HoldInfo.Font = Enum.Font.Gotham HoldInfo.TextScaled = true HoldInfo.BackgroundTransparency = 1 HoldInfo.Parent = Sec3

--// Section Set rieng
local SecSet = MakeSection("📍  SET - LƯU VỊ TRÍ", 494, 52)
local SetBtn = MakeButton(SecSet, "SET VỊ TRÍ HIỆN TẠI", 6, Color3.fromRGB(60,120,255), function() local hrp = GetHRP() if hrp then SetPos = hrp.Position StatusLabel.Text = "Đã Set: " .. string.format("(%.1f, %.1f, %.1f)", SetPos.X, SetPos.Y, SetPos.Z) end end)
SetBtn.Size = UDim2.new(0.48, -8, 0, 40) SetBtn.Position = UDim2.new(0, 8, 0, 6)
local GoBtn = MakeButton(SecSet, "VỀ CHỖ ĐÃ SET", 6, Color3.fromRGB(90,90,110), function() local hrp = GetHRP() if hrp and SetPos then pcall(function() hrp.CFrame = CFrame.new(SetPos) end) end end)
GoBtn.Size = UDim2.new(0.48, -8, 0, 40) GoBtn.Position = UDim2.new(0.52, 0, 0, 6)

local HideBtn = Instance.new("TextButton") HideBtn.Size = UDim2.new(0, 330, 0, 36) HideBtn.Position = UDim2.new(0.5, -165, 0, 552) HideBtn.Text = "ẨN MENU  •  Bấm KHUY để hiện lại" HideBtn.BackgroundColor3 = Color3.fromRGB(70,70,85) HideBtn.TextColor3 = Color3.new(1,1,1) HideBtn.Font = Enum.Font.GothamBold HideBtn.TextScaled = true HideBtn.Parent = MainFrame Corner(HideBtn, 10)

local FloatBtn = Instance.new("TextButton") FloatBtn.Size = UDim2.new(0, 58, 0, 58) FloatBtn.Position = UDim2.new(0, 15, 0.35, 0) FloatBtn.Text = "KHUY" FloatBtn.BackgroundColor3 = Color3.fromRGB(255,85,85) FloatBtn.TextColor3 = Color3.new(1,1,1) FloatBtn.Font = Enum.Font.GothamBlack FloatBtn.TextScaled = true FloatBtn.Visible = true FloatBtn.ZIndex = 9999 FloatBtn.Parent = Gui Corner(FloatBtn, 29) Stroke(FloatBtn, Color3.new(1,1,1), 1)
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

--// ============ TELE MUOT: Lerp moi frame, khong giat ============
RS.Heartbeat:Connect(function()
    local ball, dist = FindBall()
    local hrp = GetHRP()
    if not hrp then return end
    if ball then
        local high = IsBallHigh(ball, hrp)
        BallInfo.Text = string.format("Cầu: %.1f studs • Cao: %.1f • %s", dist, ball.Position.Y, high and "CẦU CAO - SẮP SMASH" or "Cầu thấp")
        if TeleMuot then
            -- Neu cau cao + AutoSmash: tele SAT cau (0.8 studs), de dap
            -- Neu cau thap: tele sau cau 2 studs nhu binh thuong
            local dir = (hrp.Position - ball.Position)
            dir = Vector3.new(dir.X, 0, dir.Z)
            if dir.Magnitude < 0.5 then dir = Vector3.new(0, 0, 2) else dir = dir.Unit end
            local offsetDist = 2
            local offsetY = 2
            if high and AutoSmash then offsetDist = 0.8 offsetY = 0.6 end
            local targetPos = ball.Position + Vector3.new(dir.X * offsetDist, offsetY, dir.Z * offsetDist)
            local targetCF = CFrame.lookAt(targetPos, Vector3.new(ball.Position.X, targetPos.Y, ball.Position.Z))
            -- MUOT: Lerp 0.35, khong set thang => khong giat
            local cur = hrp.CFrame
            if (cur.Position - targetPos).Magnitude > 0.3 then
                hrp.CFrame = cur:Lerp(targetCF, 0.35)
            end
            StatusLabel.Text = high and "Tele Mượt: Cầu cao - Tele sát để Smash" or "Tele Mượt: Đang theo cầu"
        else
            if not AutoE and not AutoF then StatusLabel.Text = "Tắt hết • Đang chờ cầu..." end
        end
        --// GIU F KHI CAU CAO: Giu may giay roi tha de dap
        if HoldF_Mode and high and TeleMuot and (tick() - LastSmash > SmashCooldown) then
            if not HoldingF then
                pcall(function() VIM:SendKeyEvent(true, Enum.KeyCode.F, false, game) end)
                HoldingF = true HoldStart = tick()
                StatusLabel.Text = "Đang GIỮ F để đập... (1.5s)"
            elseif tick() - HoldStart >= HoldTime then
                pcall(function() VIM:SendKeyEvent(false, Enum.KeyCode.F, false, game) end)
                HoldingF = false LastSmash = tick()
                StatusLabel.Text = "Đã THẢ F - Đập cầu!"
            end
        else
            -- Khong phai luc smash thi tha F ra neu dang giu
            if HoldingF and not (high and HoldF_Mode) then
                pcall(function() VIM:SendKeyEvent(false, Enum.KeyCode.F, false, game) end)
                HoldingF = false
            end
        end
    else
        BallInfo.Text = "Cầu: -- • Đang chờ cầu..."
    end
end)

--// ============ E RIENG - Vong lap rieng ============
task.spawn(function()
    while true do task.wait(0.16)
        if not AutoE then task.wait(0.1) continue end
        pcall(function() VIM:SendKeyEvent(true, Enum.KeyCode.E, false, game) task.wait(0.05) VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game) end)
    end
end)

--// ============ F RIENG - Vong lap rieng, khong gop E ============
task.spawn(function()
    while true do task.wait(0.18)
        if not AutoF then task.wait(0.1) continue end
        -- Neu dang giu F de smash thi khong spam F nua, tranh xung dot
        if HoldingF then task.wait(0.1) continue end
        pcall(function() VIM:SendKeyEvent(true, Enum.KeyCode.F, false, game) task.wait(0.05) VIM:SendKeyEvent(false, Enum.KeyCode.F, false, game) end)
    end
end)

LocalPlayer.Idled:Connect(function()
    if TeleMuot or AutoE or AutoF or HoldF_Mode then
        pcall(function() VirtualUser:CaptureController() VirtualUser:ClickButton2(Vector2.new(0,0)) end)
    end
end)
print("[KHUY-MUOT] Xong - Tele Lerp muot + E/F rieng + Giu F dap cau cao")

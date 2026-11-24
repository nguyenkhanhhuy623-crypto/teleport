--// ============================================================
--// RACKET RIVALS - KHUY - FIX DINH LUOI + TELE SAT CAU + DAP KEO XUONG
--// LOI CU: Tele 2 studs + sau khi dap van bay theo cau -> lao vao luoi -> bi dap dinh luoi vang ra sau
--// FIX:
--//  1. Tele SAT cau: 0.5 studs (truoc la 2), cao 0.5, dinh sat cau luon
--//  2. Chong dinh luoi: Tim Net, neu target qua luoi thi day lui ve san minh 4 studs, khong cho tele dinh luoi
--//  3. Dap xong KHONG duoi theo cau: Cooldown 2.5s, tele dung, ve cho an toan, tranh bi dap vang
--//  4. Dap: Giu F NGAN 0.7s (truoc 1.5s dai qua) + KEO XUONG (giu S + nhin xuong) roi tha ra
--// BO KEY - E / F rieng - Tele muot Lerp
--// ============================================================
local Players = game:GetService("Players")
local VIM = game:GetService("VirtualInputManager")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")
local VirtualUser = game:GetService("VirtualUser")
print("[KHUY-FIX-LUOI] Tele sat cau + Chong dinh luoi + Dap keo xuong")

--// ============ STATE ============
local TeleMuot = false
local AutoSmash = true
local AutoE = false
local AutoF = false
local HoldF_Mode = false
local SetPos = nil
local OwnBase = nil

local HoldTime = 0.7 -- Giu F ngan thoi, 0.7s, truoc 1.5s dai qua nen bi dinh luoi
local AfterSmashWait = 2.5 -- Dap xong nghi 2.5s, khong duoi theo cau, ve cho an toan
local HoldingF = false
local HoldStart = 0
local LastSmash = -10
local TelePausedUntil = 0

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
task.spawn(function() task.wait(1) local hrp = GetHRP() if hrp then OwnBase = hrp.Position end end)

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

--// Tim luoi de chong dinh luoi
local NetPos = nil
local NetAxis = "Z" -- Luoi chay doc X thi net line la Z, chay doc Z thi line la X
local function FindNet()
    if NetPos then return NetPos, NetAxis end
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name:lower():find("net") then
            NetPos = obj.Position
            -- Neu Size.X > Size.Z thi luoi chay doc X, line la Z
            if obj.Size.X > obj.Size.Z then NetAxis = "Z" else NetAxis = "X" end
            return NetPos, NetAxis
        end
    end
    return nil, NetAxis
end
local function IsAcrossNet(pos)
    local net, axis = FindNet()
    if not net or not OwnBase then return false end
    if axis == "Z" then
        -- OwnBase va pos o 2 ben cua net (Z)
        return (pos.Z - net.Z) * (OwnBase.Z - net.Z) < 0
    else
        return (pos.X - net.X) * (OwnBase.X - net.X) < 0
    end
end
local function PushBackFromNet(pos)
    local net, axis = FindNet()
    if not net or not OwnBase then return pos end
    -- Day target lui ve san minh 4 studs, cach luoi 4 studs de khong dinh luoi
    if axis == "Z" then
        local dir = OwnBase.Z > net.Z and 1 or -1
        return Vector3.new(pos.X, pos.Y, net.Z + dir * 4)
    else
        local dir = OwnBase.X > net.X and 1 or -1
        return Vector3.new(net.X + dir * 4, pos.Y, pos.Z)
    end
end
local function IsBallHigh(ball, hrp)
    if not ball or not hrp then return false end
    return (ball.Position.Y - hrp.Position.Y) > 3.5 or ball.Position.Y > 9
end

--// ============ GUI DEP - BO KEY ============
local Gui = Instance.new("ScreenGui") Gui.Name = "KHUY_FixLuoi" Gui.ResetOnSpawn = false Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() Gui.Parent = CoreGui end)
if not Gui.Parent then Gui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
local function Corner(o, r) local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, r or 12) c.Parent = o end
local function Stroke(o, color, thick) local s = Instance.new("UIStroke") s.Color = color s.Thickness = thick or 1 s.Transparency = 0.6 s.Parent = o return s end
local function Gradient(o, c1, c2) local g = Instance.new("UIGradient") g.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, c1), ColorSequenceKeypoint.new(1, c2)}) g.Rotation = 45 g.Parent = o return g end

local MainFrame = Instance.new("Frame") MainFrame.Name = "MainFrame" MainFrame.Size = UDim2.new(0, 370, 0, 580) MainFrame.Position = UDim2.new(0.5, -185, 0.5, -290) MainFrame.BackgroundColor3 = Color3.fromRGB(16,16,24) MainFrame.Visible = true MainFrame.Active = false MainFrame.Parent = Gui Corner(MainFrame, 16) Stroke(MainFrame, Color3.fromRGB(255,85,85), 1.5)
local TopBar = Instance.new("Frame") TopBar.Size = UDim2.new(1,0,0,52) TopBar.BackgroundColor3 = Color3.fromRGB(255,85,85) TopBar.Active = true TopBar.Parent = MainFrame Corner(TopBar, 16)
Gradient(TopBar, Color3.fromRGB(255,85,85), Color3.fromRGB(255,130,180))
local TopTitle = Instance.new("TextLabel") TopTitle.Size = UDim2.new(1,0,0,30) TopTitle.Position = UDim2.new(0,0,0,4) TopTitle.Text = "KHUY  •  FIX DÍNH LƯỚI" TopTitle.TextColor3 = Color3.new(1,1,1) TopTitle.Font = Enum.Font.GothamBlack TopTitle.TextScaled = true TopTitle.BackgroundTransparency = 1 TopTitle.Parent = TopBar
local TopSub = Instance.new("TextLabel") TopSub.Size = UDim2.new(1,0,0,16) TopSub.Position = UDim2.new(0,0,0,32) TopSub.Text = "TELE SÁT CẦU 0.5  •  ĐẬP KÉO XUỐNG  •  CHỐNG LƯỚI" TopSub.TextColor3 = Color3.fromRGB(255,235,235) TopSub.Font = Enum.Font.Gotham TopSub.TextScaled = true TopSub.BackgroundTransparency = 1 TopSub.Parent = TopBar

local StatusLabel = Instance.new("TextLabel") StatusLabel.Size = UDim2.new(0, 330, 0, 30) StatusLabel.Position = UDim2.new(0.5, -165, 0, 60) StatusLabel.Text = "Tắt hết • Đang chờ cầu..." StatusLabel.TextColor3 = Color3.fromRGB(255,255,140) StatusLabel.Font = Enum.Font.GothamBold StatusLabel.TextScaled = true StatusLabel.BackgroundTransparency = 1 StatusLabel.Parent = MainFrame
local BallInfo = Instance.new("TextLabel") BallInfo.Size = UDim2.new(0, 330, 0, 24) BallInfo.Position = UDim2.new(0.5, -165, 0, 90) BallInfo.Text = "Cầu: -- • Lưới: --" BallInfo.TextColor3 = Color3.fromRGB(170,200,255) BallInfo.Font = Enum.Font.Gotham BallInfo.TextScaled = true BallInfo.BackgroundTransparency = 1 BallInfo.Parent = MainFrame

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
    return btn
end
local function MakeButton(parent, name, y, color, callback, w)
    local btn = Instance.new("TextButton") btn.Size = UDim2.new(w or 1, -16, 0, 40) btn.Position = UDim2.new(0, 8, 0, y) btn.Text = name btn.BackgroundColor3 = color btn.TextColor3 = Color3.new(1,1,1) btn.Font = Enum.Font.GothamBold btn.TextScaled = true btn.Parent = parent Corner(btn, 10)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

local Sec1 = MakeSection("🎯  1. TELE - SÁT CẦU, CHỐNG LƯỚI", 118, 132)
MakeToggle(Sec1, "Tele Mượt (Sát Cầu 0.5)", 32, function(v) TeleMuot = v if not v then RestoreMovement() end end, false)
MakeToggle(Sec1, "Tự Smash Khi Cầu Cao", 76, function(v) AutoSmash = v end, true)

local Sec2 = MakeSection("🅰️  2. NÚT E RIÊNG", 258, 88)
MakeToggle(Sec2, "Auto E (Spam E)", 32, function(v) AutoE = v end, false)

local Sec3 = MakeSection("🅱️  3. NÚT F RIÊNG - ĐẬP KÉO XUỐNG", 354, 132)
MakeToggle(Sec3, "Auto F (Spam F)", 32, function(v) AutoF = v end, false)
MakeToggle(Sec3, "Giữ F + Kéo Xuống Để Đập (0.7s)", 76, function(v) HoldF_Mode = v if not v and HoldingF then pcall(function() VIM:SendKeyEvent(false, Enum.KeyCode.F, false, game) VIM:SendKeyEvent(false, Enum.KeyCode.S, false, game) end) HoldingF = false end end, false)
local HoldInfo = Instance.new("TextLabel") HoldInfo.Size = UDim2.new(1, -16, 0, 18) HoldInfo.Position = UDim2.new(0, 8, 0, 112) HoldInfo.Text = "Đập: Giữ F 0.7s + kéo xuống rồi thả • Dập xong nghỉ 2.5s" HoldInfo.TextColor3 = Color3.fromRGB(200,200,200) HoldInfo.Font = Enum.Font.Gotham HoldInfo.TextScaled = true HoldInfo.BackgroundTransparency = 1 HoldInfo.Parent = Sec3

local SecSet = MakeSection("📍  SET - LƯU VỊ TRÍ AN TOÀN", 494, 52)
local SetBtn = MakeButton(SecSet, "SET VỊ TRÍ", 6, Color3.fromRGB(60,120,255), function() local hrp = GetHRP() if hrp then SetPos = hrp.Position OwnBase = hrp.Position StatusLabel.Text = "Đã Set chỗ an toàn" end end, 0.48)
SetBtn.Size = UDim2.new(0.48, -8, 0, 40) SetBtn.Position = UDim2.new(0, 8, 0, 6)
local GoBtn = MakeButton(SecSet, "VỀ CHỖ AN TOÀN", 6, Color3.fromRGB(90,90,110), function() local hrp = GetHRP() if hrp and SetPos then pcall(function() hrp.CFrame = CFrame.new(SetPos) end) end end, 0.48)
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

--// ============ TELE MUOT + CHONG LUOI + DAP XONG NGHI ============
RS.Heartbeat:Connect(function()
    local ball, dist = FindBall()
    local hrp = GetHRP()
    if not hrp then return end
    if not OwnBase then OwnBase = hrp.Position end
    if ball then
        local high = IsBallHigh(ball, hrp)
        local net, _ = FindNet()
        BallInfo.Text = string.format("Cầu: %.1f • Cao: %.1f • Lưới: %s • %s", dist, ball.Position.Y, net and "Tìm thấy" or "Chưa thấy", high and "CẦU CAO" or "Cầu thấp")
        -- Neu vua dap xong, trong 2.5s: KHONG duoi theo cau, ve cho an toan
        if tick() < TelePausedUntil then
            local safePos = SetPos or OwnBase
            local targetCF = CFrame.new(safePos)
            if (hrp.CFrame.Position - safePos).Magnitude > 0.5 then
                hrp.CFrame = hrp.CFrame:Lerp(targetCF, 0.25)
            end
            StatusLabel.Text = string.format("Vừa đập xong - Nghỉ %.1fs, không đuổi cầu", TelePausedUntil - tick())
            return
        end
        if TeleMuot then
            -- Tele SAT cau: 0.5 studs, khong phai 2 nua
            local dir = (hrp.Position - ball.Position)
            dir = Vector3.new(dir.X, 0, dir.Z)
            if dir.Magnitude < 0.5 then dir = Vector3.new(0, 0, 2) else dir = dir.Unit end
            local offsetDist = 0.5
            local offsetY = 0.5
            if high and AutoSmash then offsetDist = 0.5 offsetY = 0.4 end -- Cau cao cung sat luon
            local targetPos = ball.Position + Vector3.new(dir.X * offsetDist, offsetY, dir.Z * offsetDist)
            -- CHONG DINH LUOI: Neu target qua luoi thi day lui ve san minh 4 studs
            if IsAcrossNet(targetPos) then
                targetPos = PushBackFromNet(targetPos)
                StatusLabel.Text = "Chặn lưới: Đẩy về sân mình, không tele dính lưới"
            else
                StatusLabel.Text = high and "Tele Sát: Cầu cao - Sát cầu để đập" or "Tele Sát: Đang theo cầu 0.5"
            end
            -- Neu dang giu F de dap thi nhin XUONG de keo xuong, khong nhin ngang
            local lookTarget
            if HoldingF then
                lookTarget = Vector3.new(ball.Position.X, targetPos.Y - 4, ball.Position.Z + 2) -- Nhin chech xuong de dap xuong
            else
                lookTarget = Vector3.new(ball.Position.X, targetPos.Y, ball.Position.Z)
            end
            local targetCF = CFrame.lookAt(targetPos, lookTarget)
            if (hrp.CFrame.Position - targetPos).Magnitude > 0.2 then
                hrp.CFrame = hrp.CFrame:Lerp(targetCF, 0.38)
            end
        end
        --// DAP: Giu F 0.7s + KEO XUONG (giu S) roi tha
        if HoldF_Mode and high and TeleMuot and (tick() - LastSmash > 1) then
            if not HoldingF then
                pcall(function()
                    VIM:SendKeyEvent(true, Enum.KeyCode.F, false, game)
                    VIM:SendKeyEvent(true, Enum.KeyCode.S, false, game) -- Keo xuong = giu S (lui xuong)
                end)
                HoldingF = true HoldStart = tick()
                StatusLabel.Text = "Đang GIỮ F + KÉO XUỐNG (0.7s)..."
            elseif tick() - HoldStart >= HoldTime then
                pcall(function()
                    VIM:SendKeyEvent(false, Enum.KeyCode.F, false, game)
                    VIM:SendKeyEvent(false, Enum.KeyCode.S, false, game)
                end)
                HoldingF = false LastSmash = tick()
                TelePausedUntil = tick() + AfterSmashWait -- Dap xong nghi, khong duoi theo cau
                StatusLabel.Text = "Đã THẢ F - Đập xuống! Nghỉ 2.5s"
            end
        else
            if HoldingF and not (high and HoldF_Mode) then
                pcall(function() VIM:SendKeyEvent(false, Enum.KeyCode.F, false, game) VIM:SendKeyEvent(false, Enum.KeyCode.S, false, game) end)
                HoldingF = false
            end
        end
    else
        BallInfo.Text = "Cầu: -- • Đang chờ cầu..."
    end
end)

--// E rieng
task.spawn(function()
    while true do task.wait(0.16)
        if not AutoE then task.wait(0.1) continue end
        pcall(function() VIM:SendKeyEvent(true, Enum.KeyCode.E, false, game) task.wait(0.05) VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game) end)
    end
end)
--// F rieng (spam), khong xung dot voi giu F dap
task.spawn(function()
    while true do task.wait(0.18)
        if not AutoF then task.wait(0.1) continue end
        if HoldingF then task.wait(0.1) continue end
        if tick() < TelePausedUntil then task.wait(0.1) continue end
        pcall(function() VIM:SendKeyEvent(true, Enum.KeyCode.F, false, game) task.wait(0.05) VIM:SendKeyEvent(false, Enum.KeyCode.F, false, game) end)
    end
end)

LocalPlayer.Idled:Connect(function()
    if TeleMuot or AutoE or AutoF or HoldF_Mode then
        pcall(function() VirtualUser:CaptureController() VirtualUser:ClickButton2(Vector2.new(0,0)) end)
    end
end)
print("[KHUY-FIX-LUOI] Xong - Sat cau 0.5 + Chong luoi + Dap keo xuong 0.7s")

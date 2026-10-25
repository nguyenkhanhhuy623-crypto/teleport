--[[
    ═══════════════════════════════════════════════════════════
      TELEPORT WAYPOINT PRO  •  Universal Script
      Key: .
      Features: Beautiful GUI • Avatar • FPS • Ping • Smooth Anim
    ═══════════════════════════════════════════════════════════
]]

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local Stats             = game:GetService("Stats")
local CoreGui           = game:GetService("CoreGui")
local Lighting          = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

-- Cleanup old
pcall(function()
    if CoreGui:FindFirstChild("TPWaypointPro") then CoreGui.TPWaypointPro:Destroy() end
    if PlayerGui:FindFirstChild("TPWaypointPro") then PlayerGui.TPWaypointPro:Destroy() end
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TPWaypointPro"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = CoreGui

--// ==================== UTILS ====================
local function Create(class, props)
    local obj = Instance.new(class)
    for k, v in pairs(props) do
        if k ~= "Parent" then
            obj[k] = v
        end
    end
    if props.Parent then obj.Parent = props.Parent end
    return obj
end

local function Tween(obj, time, props, style, dir)
    local t = TweenService:Create(obj, TweenInfo.new(time, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props)
    t:Play()
    return t
end

local function Round(n) return math.floor(n + 0.5) end

--// ==================== KEY SYSTEM ====================
local KEY = "."

local KeyFrame = Create("Frame", {
    Name = "KeyFrame",
    Size = UDim2.new(0, 380, 0, 260),
    Position = UDim2.new(0.5, -190, 0.5, -130),
    BackgroundColor3 = Color3.fromRGB(16, 16, 22),
    BorderSizePixel = 0,
    Parent = ScreenGui,
    ClipsDescendants = true
})

Create("UICorner", {CornerRadius = UDim.new(0, 16), Parent = KeyFrame})
Create("UIStroke", {
    Color = Color3.fromRGB(90, 70, 255),
    Thickness = 1.8,
    Transparency = 0.3,
    Parent = KeyFrame
})

-- Gradient glow
local KeyGrad = Create("UIGradient", {
    Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 30, 80)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(20, 18, 35)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 25, 60))
    },
    Rotation = 45,
    Parent = KeyFrame
})

-- Accent line top
local Accent = Create("Frame", {
    Size = UDim2.new(1, 0, 0, 3),
    Position = UDim2.new(0, 0, 0, 0),
    BackgroundColor3 = Color3.fromRGB(130, 90, 255),
    BorderSizePixel = 0,
    Parent = KeyFrame
})
Create("UIGradient", {
    Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(90, 50, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(180, 100, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(90, 50, 255))
    },
    Parent = Accent
})

local KeyTitle = Create("TextLabel", {
    Size = UDim2.new(1, 0, 0, 40),
    Position = UDim2.new(0, 0, 0, 25),
    BackgroundTransparency = 1,
    Text = "🔐  TELEPORT WAYPOINT PRO",
    TextColor3 = Color3.fromRGB(240, 240, 255),
    Font = Enum.Font.GothamBold,
    TextSize = 20,
    Parent = KeyFrame
})

local KeySub = Create("TextLabel", {
    Size = UDim2.new(1, -40, 0, 22),
    Position = UDim2.new(0, 20, 0, 68),
    BackgroundTransparency = 1,
    Text = "Enter the key to unlock",
    TextColor3 = Color3.fromRGB(150, 150, 180),
    Font = Enum.Font.Gotham,
    TextSize = 14,
    Parent = KeyFrame
})

local KeyBox = Create("TextBox", {
    Size = UDim2.new(1, -60, 0, 44),
    Position = UDim2.new(0, 30, 0, 110),
    BackgroundColor3 = Color3.fromRGB(28, 28, 40),
    Text = "",
    PlaceholderText = "Key...",
    PlaceholderColor3 = Color3.fromRGB(100, 100, 130),
    TextColor3 = Color3.fromRGB(255, 255, 255),
    Font = Enum.Font.GothamSemibold,
    TextSize = 16,
    TextXAlignment = Enum.TextXAlignment.Center,
    ClearTextOnFocus = false,
    Parent = KeyFrame
})
Create("UICorner", {CornerRadius = UDim.new(0, 10), Parent = KeyBox})
Create("UIStroke", {
    Color = Color3.fromRGB(80, 60, 180),
    Thickness = 1.2,
    Transparency = 0.5,
    Parent = KeyBox
})

local UnlockBtn = Create("TextButton", {
    Size = UDim2.new(1, -60, 0, 44),
    Position = UDim2.new(0, 30, 0, 170),
    BackgroundColor3 = Color3.fromRGB(100, 60, 255),
    Text = "UNLOCK",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    Font = Enum.Font.GothamBold,
    TextSize = 16,
    AutoButtonColor = false,
    Parent = KeyFrame
})
Create("UICorner", {CornerRadius = UDim.new(0, 10), Parent = UnlockBtn})

local KeyStatus = Create("TextLabel", {
    Size = UDim2.new(1, 0, 0, 20),
    Position = UDim2.new(0, 0, 1, -28),
    BackgroundTransparency = 1,
    Text = "",
    TextColor3 = Color3.fromRGB(255, 90, 90),
    Font = Enum.Font.Gotham,
    TextSize = 13,
    Parent = KeyFrame
})

-- Hover effect for Unlock
UnlockBtn.MouseEnter:Connect(function()
    Tween(UnlockBtn, 0.2, {BackgroundColor3 = Color3.fromRGB(130, 90, 255)})
end)
UnlockBtn.MouseLeave:Connect(function()
    Tween(UnlockBtn, 0.2, {BackgroundColor3 = Color3.fromRGB(100, 60, 255)})
end)

--// ==================== MAIN GUI ====================
local Main = Create("Frame", {
    Name = "Main",
    Size = UDim2.new(0, 0, 0, 0),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    BackgroundColor3 = Color3.fromRGB(14, 14, 20),
    BorderSizePixel = 0,
    Visible = false,
    ClipsDescendants = true,
    Parent = ScreenGui
})
Create("UICorner", {CornerRadius = UDim.new(0, 16), Parent = Main})
Create("UIStroke", {
    Color = Color3.fromRGB(70, 50, 200),
    Thickness = 1.6,
    Transparency = 0.35,
    Parent = Main
})

local MainGrad = Create("UIGradient", {
    Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(22, 18, 40)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(14, 14, 22))
    },
    Rotation = 90,
    Parent = Main
})

-- Top bar
local TopBar = Create("Frame", {
    Size = UDim2.new(1, 0, 0, 58),
    BackgroundColor3 = Color3.fromRGB(20, 18, 32),
    BorderSizePixel = 0,
    Parent = Main
})
Create("UICorner", {CornerRadius = UDim.new(0, 16), Parent = TopBar})
-- Fix bottom corners of topbar
Create("Frame", {
    Size = UDim2.new(1, 0, 0, 20),
    Position = UDim2.new(0, 0, 1, -20),
    BackgroundColor3 = Color3.fromRGB(20, 18, 32),
    BorderSizePixel = 0,
    Parent = TopBar
})

-- Avatar
local AvatarFrame = Create("Frame", {
    Size = UDim2.new(0, 40, 0, 40),
    Position = UDim2.new(0, 12, 0, 9),
    BackgroundColor3 = Color3.fromRGB(40, 35, 70),
    BorderSizePixel = 0,
    Parent = TopBar
})
Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = AvatarFrame})
Create("UIStroke", {
    Color = Color3.fromRGB(130, 90, 255),
    Thickness = 1.5,
    Parent = AvatarFrame
})

local AvatarImg = Create("ImageLabel", {
    Size = UDim2.new(1, -4, 1, -4),
    Position = UDim2.new(0, 2, 0, 2),
    BackgroundTransparency = 1,
    Image = "",
    Parent = AvatarFrame
})
Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = AvatarImg})

-- Load avatar
task.spawn(function()
    local ok, content = pcall(function()
        return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
    end)
    if ok and content then
        AvatarImg.Image = content
    end
end)

local UserNameLabel = Create("TextLabel", {
    Size = UDim2.new(0, 180, 0, 20),
    Position = UDim2.new(0, 62, 0, 10),
    BackgroundTransparency = 1,
    Text = LocalPlayer.DisplayName,
    TextColor3 = Color3.fromRGB(255, 255, 255),
    Font = Enum.Font.GothamBold,
    TextSize = 15,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = TopBar
})

local UserTagLabel = Create("TextLabel", {
    Size = UDim2.new(0, 180, 0, 16),
    Position = UDim2.new(0, 62, 0, 30),
    BackgroundTransparency = 1,
    Text = "@" .. LocalPlayer.Name,
    TextColor3 = Color3.fromRGB(140, 140, 170),
    Font = Enum.Font.Gotham,
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = TopBar
})

-- FPS & Ping
local StatsFrame = Create("Frame", {
    Size = UDim2.new(0, 110, 0, 40),
    Position = UDim2.new(1, -160, 0, 9),
    BackgroundTransparency = 1,
    Parent = TopBar
})

local FPSLabel = Create("TextLabel", {
    Size = UDim2.new(1, 0, 0, 18),
    BackgroundTransparency = 1,
    Text = "FPS: --",
    TextColor3 = Color3.fromRGB(100, 255, 160),
    Font = Enum.Font.GothamSemibold,
    TextSize = 13,
    TextXAlignment = Enum.TextXAlignment.Right,
    Parent = StatsFrame
})

local PingLabel = Create("TextLabel", {
    Size = UDim2.new(1, 0, 0, 18),
    Position = UDim2.new(0, 0, 0, 18),
    BackgroundTransparency = 1,
    Text = "PING: --",
    TextColor3 = Color3.fromRGB(100, 200, 255),
    Font = Enum.Font.GothamSemibold,
    TextSize = 13,
    TextXAlignment = Enum.TextXAlignment.Right,
    Parent = StatsFrame
})

-- Close button
local CloseBtn = Create("TextButton", {
    Size = UDim2.new(0, 32, 0, 32),
    Position = UDim2.new(1, -42, 0, 13),
    BackgroundColor3 = Color3.fromRGB(40, 30, 55),
    Text = "×",
    TextColor3 = Color3.fromRGB(255, 110, 110),
    Font = Enum.Font.GothamBold,
    TextSize = 20,
    AutoButtonColor = false,
    Parent = TopBar
})
Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = CloseBtn})

-- Content area
local Content = Create("Frame", {
    Size = UDim2.new(1, -24, 1, -78),
    Position = UDim2.new(0, 12, 0, 66),
    BackgroundTransparency = 1,
    Parent = Main
})

-- Name input
local NameBox = Create("TextBox", {
    Size = UDim2.new(1, 0, 0, 40),
    BackgroundColor3 = Color3.fromRGB(26, 24, 40),
    Text = "",
    PlaceholderText = "Nhập tên chỗ muốn lưu...",
    PlaceholderColor3 = Color3.fromRGB(110, 110, 140),
    TextColor3 = Color3.fromRGB(255, 255, 255),
    Font = Enum.Font.Gotham,
    TextSize = 14,
    ClearTextOnFocus = false,
    Parent = Content
})
Create("UICorner", {CornerRadius = UDim.new(0, 10), Parent = NameBox})
Create("UIStroke", {
    Color = Color3.fromRGB(70, 55, 140),
    Thickness = 1,
    Transparency = 0.5,
    Parent = NameBox
})
Create("UIPadding", {
    PaddingLeft = UDim.new(0, 12),
    Parent = NameBox
})

-- Set Button
local SetBtn = Create("TextButton", {
    Size = UDim2.new(1, 0, 0, 42),
    Position = UDim2.new(0, 0, 0, 50),
    BackgroundColor3 = Color3.fromRGB(90, 50, 255),
    Text = "✦  SET VỊ TRÍ HIỆN TẠI",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    Font = Enum.Font.GothamBold,
    TextSize = 15,
    AutoButtonColor = false,
    Parent = Content
})
Create("UICorner", {CornerRadius = UDim.new(0, 10), Parent = SetBtn})

-- List
local ListFrame = Create("ScrollingFrame", {
    Size = UDim2.new(1, 0, 1, -110),
    Position = UDim2.new(0, 0, 0, 105),
    BackgroundColor3 = Color3.fromRGB(20, 18, 32),
    BorderSizePixel = 0,
    ScrollBarThickness = 3,
    ScrollBarImageColor3 = Color3.fromRGB(120, 90, 255),
    CanvasSize = UDim2.new(0, 0, 0, 0),
    Parent = Content
})
Create("UICorner", {CornerRadius = UDim.new(0, 10), Parent = ListFrame})

local ListLayout = Create("UIListLayout", {
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 7),
    Parent = ListFrame
})
Create("UIPadding", {
    PaddingTop = UDim.new(0, 8),
    PaddingBottom = UDim.new(0, 8),
    PaddingLeft = UDim.new(0, 8),
    PaddingRight = UDim.new(0, 8),
    Parent = ListFrame
})

--// ==================== LOGIC ====================
local Waypoints = {}
local isOpen = false
local isUnlocked = false

local function UpdateList()
    for _, child in ipairs(ListFrame:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    for i, data in ipairs(Waypoints) do
        local Item = Create("Frame", {
            Size = UDim2.new(1, -6, 0, 50),
            BackgroundColor3 = Color3.fromRGB(30, 28, 48),
            LayoutOrder = i,
            Parent = ListFrame
        })
        Create("UICorner", {CornerRadius = UDim.new(0, 9), Parent = Item})

        local NameLbl = Create("TextLabel", {
            Size = UDim2.new(1, -115, 1, 0),
            Position = UDim2.new(0, 12, 0, 0),
            BackgroundTransparency = 1,
            Text = data.Name,
            TextColor3 = Color3.fromRGB(240, 240, 255),
            Font = Enum.Font.GothamSemibold,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = Item
        })

        local TeleBtn = Create("TextButton", {
            Size = UDim2.new(0, 58, 0, 30),
            Position = UDim2.new(1, -105, 0.5, -15),
            BackgroundColor3 = Color3.fromRGB(0, 150, 255),
            Text = "TELE",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            Font = Enum.Font.GothamBold,
            TextSize = 12,
            AutoButtonColor = false,
            Parent = Item
        })
        Create("UICorner", {CornerRadius = UDim.new(0, 7), Parent = TeleBtn})

        TeleBtn.MouseEnter:Connect(function()
            Tween(TeleBtn, 0.15, {BackgroundColor3 = Color3.fromRGB(40, 180, 255)})
        end)
        TeleBtn.MouseLeave:Connect(function()
            Tween(TeleBtn, 0.15, {BackgroundColor3 = Color3.fromRGB(0, 150, 255)})
        end)

        TeleBtn.MouseButton1Click:Connect(function()
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                char.HumanoidRootPart.CFrame = data.CFrame
            end
        end)

        local DelBtn = Create("TextButton", {
            Size = UDim2.new(0, 30, 0, 30),
            Position = UDim2.new(1, -40, 0.5, -15),
            BackgroundColor3 = Color3.fromRGB(200, 55, 70),
            Text = "✕",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            Font = Enum.Font.GothamBold,
            TextSize = 13,
            AutoButtonColor = false,
            Parent = Item
        })
        Create("UICorner", {CornerRadius = UDim.new(0, 7), Parent = DelBtn})

        DelBtn.MouseEnter:Connect(function()
            Tween(DelBtn, 0.15, {BackgroundColor3 = Color3.fromRGB(230, 70, 85)})
        end)
        DelBtn.MouseLeave:Connect(function()
            Tween(DelBtn, 0.15, {BackgroundColor3 = Color3.fromRGB(200, 55, 70)})
        end)

        DelBtn.MouseButton1Click:Connect(function()
            table.remove(Waypoints, i)
            UpdateList()
        end)
    end

    ListFrame.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y + 16)
end

ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    ListFrame.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y + 16)
end)

SetBtn.MouseEnter:Connect(function()
    Tween(SetBtn, 0.18, {BackgroundColor3 = Color3.fromRGB(120, 80, 255)})
end)
SetBtn.MouseLeave:Connect(function()
    Tween(SetBtn, 0.18, {BackgroundColor3 = Color3.fromRGB(90, 50, 255)})
end)

SetBtn.MouseButton1Click:Connect(function()
    local name = NameBox.Text
    if name == "" or name:match("^%s*$") then
        name = "Chỗ " .. (#Waypoints + 1)
    end
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        table.insert(Waypoints, {
            Name = name,
            CFrame = char.HumanoidRootPart.CFrame
        })
        NameBox.Text = ""
        UpdateList()
    end
end)

--// ==================== OPEN / CLOSE ANIM ====================
local function OpenMain()
    if isOpen then return end
    isOpen = true
    Main.Visible = true
    Main.Size = UDim2.new(0, 0, 0, 0)
    Main.Position = UDim2.new(0.5, 0, 0.5, 0)

    Tween(Main, 0.45, {
        Size = UDim2.new(0, 360, 0, 480),
        Position = UDim2.new(0.5, -180, 0.5, -240)
    }, Enum.EasingStyle.Back)
end

local function CloseMain()
    if not isOpen then return end
    isOpen = false
    local t = Tween(Main, 0.35, {
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0)
    }, Enum.EasingStyle.Quint)
    t.Completed:Connect(function()
        Main.Visible = false
    end)
end

CloseBtn.MouseEnter:Connect(function()
    Tween(CloseBtn, 0.15, {BackgroundColor3 = Color3.fromRGB(60, 40, 70)})
end)
CloseBtn.MouseLeave:Connect(function()
    Tween(CloseBtn, 0.15, {BackgroundColor3 = Color3.fromRGB(40, 30, 55)})
end)

CloseBtn.MouseButton1Click:Connect(function()
    CloseMain()
end)

--// ==================== KEY LOGIC ====================
local function TryUnlock()
    if KeyBox.Text == KEY then
        KeyStatus.TextColor3 = Color3.fromRGB(100, 255, 140)
        KeyStatus.Text = "✓  Key correct!"
        isUnlocked = true

        -- Beautiful fade out
        Tween(KeyFrame, 0.4, {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            BackgroundTransparency = 1
        }, Enum.EasingStyle.Quint)

        task.delay(0.4, function()
            KeyFrame.Visible = false
            OpenMain()
        end)
    else
        KeyStatus.TextColor3 = Color3.fromRGB(255, 90, 90)
        KeyStatus.Text = "✗  Wrong key"
        Tween(KeyBox, 0.08, {Position = UDim2.new(0, 38, 0, 110)})
        task.wait(0.08)
        Tween(KeyBox, 0.08, {Position = UDim2.new(0, 22, 0, 110)})
        task.wait(0.08)
        Tween(KeyBox, 0.08, {Position = UDim2.new(0, 30, 0, 110)})
        KeyBox.Text = ""
    end
end

UnlockBtn.MouseButton1Click:Connect(TryUnlock)
KeyBox.FocusLost:Connect(function(enter)
    if enter then TryUnlock() end
end)

--// ==================== TOGGLE (RightShift) ====================
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        if not isUnlocked then return end
        if isOpen then
            CloseMain()
        else
            OpenMain()
        end
    end
end)

--// ==================== FPS + PING ====================
local fpsValue = 60
RunService.RenderStepped:Connect(function(dt)
    fpsValue = math.clamp(Round(1 / math.max(dt, 0.001)), 1, 999)
end)

task.spawn(function()
    while true do
        FPSLabel.Text = "FPS: " .. tostring(fpsValue)

        local ping = 0
        pcall(function()
            ping = Round(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
        end)
        PingLabel.Text = "PING: " .. tostring(ping) .. "ms"

        -- Color FPS
        if fpsValue >= 50 then
            FPSLabel.TextColor3 = Color3.fromRGB(100, 255, 160)
        elseif fpsValue >= 30 then
            FPSLabel.TextColor3 = Color3.fromRGB(255, 220, 80)
        else
            FPSLabel.TextColor3 = Color3.fromRGB(255, 90, 90)
        end

        task.wait(0.4)
    end
end)

-- Entrance animation for KeyFrame
KeyFrame.Size = UDim2.new(0, 0, 0, 0)
KeyFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
Tween(KeyFrame, 0.55, {
    Size = UDim2.new(0, 380, 0, 260),
    Position = UDim2.new(0.5, -190, 0.5, -130)
}, Enum.EasingStyle.Back)

print("✅ Teleport Waypoint Pro loaded | Key: . | RightShift = Toggle")

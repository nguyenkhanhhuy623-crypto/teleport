--[[
    ═══════════════════════════════════════════════════════════
      TELEPORT WAYPOINT PRO
      Key: .
      Style: Compact Modern Dark
    ═══════════════════════════════════════════════════════════
]]

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local Stats            = game:GetService("Stats")
local CoreGui          = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

pcall(function()
    if CoreGui:FindFirstChild("TPWaypointPro") then
        CoreGui.TPWaypointPro:Destroy()
    end
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TPWaypointPro"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = CoreGui

local function Create(class, props)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do
        if k ~= "Parent" then obj[k] = v end
    end
    if props and props.Parent then obj.Parent = props.Parent end
    return obj
end

local function Tween(obj, time, goal, style, dir)
    local t = TweenService:Create(obj, TweenInfo.new(time or 0.35, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), goal)
    t:Play()
    return t
end

local function Round(n)
    return math.floor(n + 0.5)
end

--// ====================== KEY SYSTEM ======================
local KEY = "."

local KeyFrame = Create("Frame", {
    Name = "KeyFrame",
    Size = UDim2.new(0, 0, 0, 0),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    BackgroundColor3 = Color3.fromRGB(18, 18, 24),
    BorderSizePixel = 0,
    ClipsDescendants = true,
    Parent = ScreenGui
})
Create("UICorner", {CornerRadius = UDim.new(0, 12), Parent = KeyFrame})
Create("UIStroke", {
    Color = Color3.fromRGB(70, 70, 95),
    Thickness = 1,
    Transparency = 0.4,
    Parent = KeyFrame
})

Create("Frame", {
    Size = UDim2.new(1, 0, 0, 2),
    BackgroundColor3 = Color3.fromRGB(100, 80, 255),
    BorderSizePixel = 0,
    Parent = KeyFrame
})

Create("TextLabel", {
    Size = UDim2.new(1, 0, 0, 28),
    Position = UDim2.new(0, 0, 0, 16),
    BackgroundTransparency = 1,
    Text = "Teleport Waypoint Pro",
    TextColor3 = Color3.fromRGB(245, 245, 255),
    Font = Enum.Font.GothamBold,
    TextSize = 16,
    Parent = KeyFrame
})

Create("TextLabel", {
    Size = UDim2.new(1, 0, 0, 18),
    Position = UDim2.new(0, 0, 0, 44),
    BackgroundTransparency = 1,
    Text = "Enter key to continue",
    TextColor3 = Color3.fromRGB(140, 140, 165),
    Font = Enum.Font.Gotham,
    TextSize = 12,
    Parent = KeyFrame
})

local KeyBox = Create("TextBox", {
    Size = UDim2.new(1, -40, 0, 36),
    Position = UDim2.new(0, 20, 0, 75),
    BackgroundColor3 = Color3.fromRGB(28, 28, 38),
    Text = "",
    PlaceholderText = "Key",
    PlaceholderColor3 = Color3.fromRGB(100, 100, 125),
    TextColor3 = Color3.fromRGB(255, 255, 255),
    Font = Enum.Font.GothamMedium,
    TextSize = 14,
    TextXAlignment = Enum.TextXAlignment.Center,
    ClearTextOnFocus = false,
    Parent = KeyFrame
})
Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = KeyBox})

local UnlockBtn = Create("TextButton", {
    Size = UDim2.new(1, -40, 0, 36),
    Position = UDim2.new(0, 20, 0, 122),
    BackgroundColor3 = Color3.fromRGB(95, 70, 255),
    Text = "Unlock",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    AutoButtonColor = false,
    Parent = KeyFrame
})
Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = UnlockBtn})

local KeyStatus = Create("TextLabel", {
    Size = UDim2.new(1, 0, 0, 16),
    Position = UDim2.new(0, 0, 1, -26),
    BackgroundTransparency = 1,
    Text = "",
    Font = Enum.Font.Gotham,
    TextSize = 11,
    Parent = KeyFrame
})

UnlockBtn.MouseEnter:Connect(function()
    Tween(UnlockBtn, 0.18, {BackgroundColor3 = Color3.fromRGB(115, 90, 255)})
end)
UnlockBtn.MouseLeave:Connect(function()
    Tween(UnlockBtn, 0.18, {BackgroundColor3 = Color3.fromRGB(95, 70, 255)})
end)

--// ====================== TOGGLE BUTTON ======================
local ToggleBtn = Create("TextButton", {
    Name = "ToggleBtn",
    Size = UDim2.new(0, 42, 0, 42),
    Position = UDim2.new(0, 16, 0.5, -21),
    BackgroundColor3 = Color3.fromRGB(95, 70, 255),
    Text = "📍",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    Font = Enum.Font.GothamBold,
    TextSize = 18,
    AutoButtonColor = false,
    Visible = false,
    Parent = ScreenGui
})
Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = ToggleBtn})
Create("UIStroke", {
    Color = Color3.fromRGB(140, 120, 255),
    Thickness = 1.5,
    Transparency = 0.3,
    Parent = ToggleBtn
})

local dragging, dragStart, startPos = false, nil, nil

ToggleBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = ToggleBtn.Position
    end
end)

ToggleBtn.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        ToggleBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

ToggleBtn.MouseEnter:Connect(function()
    Tween(ToggleBtn, 0.15, {BackgroundColor3 = Color3.fromRGB(120, 95, 255)})
end)
ToggleBtn.MouseLeave:Connect(function()
    Tween(ToggleBtn, 0.15, {BackgroundColor3 = Color3.fromRGB(95, 70, 255)})
end)

--// ====================== MAIN GUI (COMPACT) ======================
local Main = Create("Frame", {
    Name = "Main",
    Size = UDim2.new(0, 0, 0, 0),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    BackgroundColor3 = Color3.fromRGB(16, 16, 22),
    BorderSizePixel = 0,
    Visible = false,
    ClipsDescendants = true,
    Parent = ScreenGui
})
Create("UICorner", {CornerRadius = UDim.new(0, 12), Parent = Main})
Create("UIStroke", {
    Color = Color3.fromRGB(55, 55, 75),
    Thickness = 1,
    Transparency = 0.35,
    Parent = Main
})

-- Header
local Header = Create("Frame", {
    Size = UDim2.new(1, 0, 0, 40),
    BackgroundColor3 = Color3.fromRGB(20, 20, 28),
    BorderSizePixel = 0,
    Parent = Main
})
Create("UICorner", {CornerRadius = UDim.new(0, 12), Parent = Header})
Create("Frame", {
    Size = UDim2.new(1, 0, 0, 12),
    Position = UDim2.new(0, 0, 1, -12),
    BackgroundColor3 = Color3.fromRGB(20, 20, 28),
    BorderSizePixel = 0,
    Parent = Header
})

Create("TextLabel", {
    Size = UDim2.new(0, 180, 1, 0),
    Position = UDim2.new(0, 12, 0, 0),
    BackgroundTransparency = 1,
    Text = "Teleport Waypoint",
    TextColor3 = Color3.fromRGB(245, 245, 255),
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = Header
})

local CloseBtn = Create("TextButton", {
    Size = UDim2.new(0, 26, 0, 26),
    Position = UDim2.new(1, -34, 0.5, -13),
    BackgroundColor3 = Color3.fromRGB(35, 35, 48),
    Text = "×",
    TextColor3 = Color3.fromRGB(220, 90, 90),
    Font = Enum.Font.GothamBold,
    TextSize = 16,
    AutoButtonColor = false,
    Parent = Header
})
Create("UICorner", {CornerRadius = UDim.new(0, 7), Parent = CloseBtn})

-- User Card (compact)
local UserCard = Create("Frame", {
    Size = UDim2.new(1, -20, 0, 48),
    Position = UDim2.new(0, 10, 0, 48),
    BackgroundColor3 = Color3.fromRGB(24, 24, 34),
    BorderSizePixel = 0,
    Parent = Main
})
Create("UICorner", {CornerRadius = UDim.new(0, 9), Parent = UserCard})

local AvatarHolder = Create("Frame", {
    Size = UDim2.new(0, 34, 0, 34),
    Position = UDim2.new(0, 8, 0.5, -17),
    BackgroundColor3 = Color3.fromRGB(40, 40, 55),
    BorderSizePixel = 0,
    Parent = UserCard
})
Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = AvatarHolder})
Create("UIStroke", {
    Color = Color3.fromRGB(100, 80, 255),
    Thickness = 1.2,
    Parent = AvatarHolder
})

local Avatar = Create("ImageLabel", {
    Size = UDim2.new(1, -3, 1, -3),
    Position = UDim2.new(0, 1.5, 0, 1.5),
    BackgroundTransparency = 1,
    Image = "",
    Parent = AvatarHolder
})
Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = Avatar})

task.spawn(function()
    local ok, img = pcall(function()
        return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
    end)
    if ok and img then Avatar.Image = img end
end)

Create("TextLabel", {
    Size = UDim2.new(0, 150, 0, 16),
    Position = UDim2.new(0, 50, 0, 8),
    BackgroundTransparency = 1,
    Text = LocalPlayer.DisplayName,
    TextColor3 = Color3.fromRGB(255, 255, 255),
    Font = Enum.Font.GothamBold,
    TextSize = 13,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = UserCard
})

Create("TextLabel", {
    Size = UDim2.new(0, 150, 0, 14),
    Position = UDim2.new(0, 50, 0, 25),
    BackgroundTransparency = 1,
    Text = "@" .. LocalPlayer.Name,
    TextColor3 = Color3.fromRGB(140, 140, 165),
    Font = Enum.Font.Gotham,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = UserCard
})

-- Stats (compact)
local StatsCard = Create("Frame", {
    Size = UDim2.new(1, -20, 0, 32),
    Position = UDim2.new(0, 10, 0, 104),
    BackgroundColor3 = Color3.fromRGB(24, 24, 34),
    BorderSizePixel = 0,
    Parent = Main
})
Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = StatsCard})

local FPSLabel = Create("TextLabel", {
    Size = UDim2.new(0.5, -6, 1, 0),
    Position = UDim2.new(0, 10, 0, 0),
    BackgroundTransparency = 1,
    Text = "FPS  --",
    TextColor3 = Color3.fromRGB(100, 220, 150),
    Font = Enum.Font.GothamSemibold,
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = StatsCard
})

local PingLabel = Create("TextLabel", {
    Size = UDim2.new(0.5, -6, 1, 0),
    Position = UDim2.new(0.5, 0, 0, 0),
    BackgroundTransparency = 1,
    Text = "PING  --ms",
    TextColor3 = Color3.fromRGB(100, 180, 255),
    Font = Enum.Font.GothamSemibold,
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = StatsCard
})

-- Name Input
local NameBox = Create("TextBox", {
    Size = UDim2.new(1, -20, 0, 34),
    Position = UDim2.new(0, 10, 0, 144),
    BackgroundColor3 = Color3.fromRGB(28, 28, 38),
    Text = "",
    PlaceholderText = "Nhập tên chỗ muốn lưu...",
    PlaceholderColor3 = Color3.fromRGB(110, 110, 135),
    TextColor3 = Color3.fromRGB(255, 255, 255),
    Font = Enum.Font.Gotham,
    TextSize = 13,
    ClearTextOnFocus = false,
    Parent = Main
})
Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = NameBox})
Create("UIPadding", {PaddingLeft = UDim.new(0, 10), Parent = NameBox})

-- Set Button
local SetBtn = Create("TextButton", {
    Size = UDim2.new(1, -20, 0, 36),
    Position = UDim2.new(0, 10, 0, 186),
    BackgroundColor3 = Color3.fromRGB(95, 70, 255),
    Text = "SET VỊ TRÍ HIỆN TẠI",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    Font = Enum.Font.GothamBold,
    TextSize = 13,
    AutoButtonColor = false,
    Parent = Main
})
Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = SetBtn})

-- List (smaller)
local ListFrame = Create("ScrollingFrame", {
    Size = UDim2.new(1, -20, 0, 140),
    Position = UDim2.new(0, 10, 0, 230),
    BackgroundColor3 = Color3.fromRGB(22, 22, 30),
    BorderSizePixel = 0,
    ScrollBarThickness = 3,
    ScrollBarImageColor3 = Color3.fromRGB(100, 80, 255),
    CanvasSize = UDim2.new(0, 0, 0, 0),
    Parent = Main
})
Create("UICorner", {CornerRadius = UDim.new(0, 9), Parent = ListFrame})

local ListLayout = Create("UIListLayout", {
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 5),
    Parent = ListFrame
})
Create("UIPadding", {
    PaddingTop = UDim.new(0, 6),
    PaddingBottom = UDim.new(0, 6),
    PaddingLeft = UDim.new(0, 6),
    PaddingRight = UDim.new(0, 6),
    Parent = ListFrame
})

--// Logic
local Waypoints = {}
local isOpen = false
local isUnlocked = false

local function UpdateList()
    for _, c in ipairs(ListFrame:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end

    for i, data in ipairs(Waypoints) do
        local Item = Create("Frame", {
            Size = UDim2.new(1, -4, 0, 38),
            BackgroundColor3 = Color3.fromRGB(30, 30, 42),
            LayoutOrder = i,
            Parent = ListFrame
        })
        Create("UICorner", {CornerRadius = UDim.new(0, 7), Parent = Item})

        Create("TextLabel", {
            Size = UDim2.new(1, -95, 1, 0),
            Position = UDim2.new(0, 10, 0, 0),
            BackgroundTransparency = 1,
            Text = data.Name,
            TextColor3 = Color3.fromRGB(235, 235, 250),
            Font = Enum.Font.GothamMedium,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = Item
        })

        local TeleBtn = Create("TextButton", {
            Size = UDim2.new(0, 46, 0, 24),
            Position = UDim2.new(1, -84, 0.5, -12),
            BackgroundColor3 = Color3.fromRGB(0, 145, 255),
            Text = "TELE",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            Font = Enum.Font.GothamBold,
            TextSize = 11,
            AutoButtonColor = false,
            Parent = Item
        })
        Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = TeleBtn})

        TeleBtn.MouseEnter:Connect(function()
            Tween(TeleBtn, 0.15, {BackgroundColor3 = Color3.fromRGB(40, 170, 255)})
        end)
        TeleBtn.MouseLeave:Connect(function()
            Tween(TeleBtn, 0.15, {BackgroundColor3 = Color3.fromRGB(0, 145, 255)})
        end)

        TeleBtn.MouseButton1Click:Connect(function()
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                char.HumanoidRootPart.CFrame = data.CFrame
            end
        end)

        local DelBtn = Create("TextButton", {
            Size = UDim2.new(0, 24, 0, 24),
            Position = UDim2.new(1, -32, 0.5, -12),
            BackgroundColor3 = Color3.fromRGB(200, 55, 70),
            Text = "×",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            Font = Enum.Font.GothamBold,
            TextSize = 13,
            AutoButtonColor = false,
            Parent = Item
        })
        Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = DelBtn})

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

    ListFrame.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y + 12)
end

ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    ListFrame.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y + 12)
end)

SetBtn.MouseEnter:Connect(function()
    Tween(SetBtn, 0.18, {BackgroundColor3 = Color3.fromRGB(115, 90, 255)})
end)
SetBtn.MouseLeave:Connect(function()
    Tween(SetBtn, 0.18, {BackgroundColor3 = Color3.fromRGB(95, 70, 255)})
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

local function OpenMain()
    if isOpen then return end
    isOpen = true
    Main.Visible = true
    Main.Size = UDim2.new(0, 0, 0, 0)
    Main.Position = UDim2.new(0.5, 0, 0.5, 0)

    Tween(Main, 0.35, {
        Size = UDim2.new(0, 280, 0, 385),
        Position = UDim2.new(0.5, -140, 0.5, -192)
    }, Enum.EasingStyle.Back)
end

local function CloseMain()
    if not isOpen then return end
    isOpen = false
    local t = Tween(Main, 0.28, {
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0)
    }, Enum.EasingStyle.Quint)
    t.Completed:Connect(function()
        Main.Visible = false
    end)
end

local function ToggleMain()
    if isOpen then CloseMain() else OpenMain() end
end

CloseBtn.MouseEnter:Connect(function()
    Tween(CloseBtn, 0.15, {BackgroundColor3 = Color3.fromRGB(50, 40, 60)})
end)
CloseBtn.MouseLeave:Connect(function()
    Tween(CloseBtn, 0.15, {BackgroundColor3 = Color3.fromRGB(35, 35, 48)})
end)

CloseBtn.MouseButton1Click:Connect(CloseMain)

ToggleBtn.MouseButton1Click:Connect(function()
    if isUnlocked then ToggleMain() end
end)

local function TryUnlock()
    if KeyBox.Text == KEY then
        KeyStatus.TextColor3 = Color3.fromRGB(100, 230, 140)
        KeyStatus.Text = "Correct key"
        isUnlocked = true

        Tween(KeyFrame, 0.3, {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0)
        }, Enum.EasingStyle.Quint)

        task.delay(0.3, function()
            KeyFrame.Visible = false
            ToggleBtn.Visible = true
            OpenMain()
        end)
    else
        KeyStatus.TextColor3 = Color3.fromRGB(255, 90, 90)
        KeyStatus.Text = "Wrong key"
        KeyBox.Text = ""
    end
end

UnlockBtn.MouseButton1Click:Connect(TryUnlock)
KeyBox.FocusLost:Connect(function(enter)
    if enter then TryUnlock() end
end)

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        if not isUnlocked then return end
        ToggleMain()
    end
end)

local fps = 60
RunService.RenderStepped:Connect(function(dt)
    fps = math.clamp(Round(1 / math.max(dt, 0.001)), 1, 999)
end)

task.spawn(function()
    while true do
        FPSLabel.Text = "FPS  " .. fps
        if fps >= 50 then
            FPSLabel.TextColor3 = Color3.fromRGB(100, 220, 150)
        elseif fps >= 30 then
            FPSLabel.TextColor3 = Color3.fromRGB(255, 210, 80)
        else
            FPSLabel.TextColor3 = Color3.fromRGB(255, 90, 90)
        end

        local ping = 0
        pcall(function()
            ping = Round(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
        end)
        PingLabel.Text = "PING  " .. ping .. "ms"

        task.wait(0.35)
    end
end)

Tween(KeyFrame, 0.45, {
    Size = UDim2.new(0, 280, 0, 195),
    Position = UDim2.new(0.5, -140, 0.5, -97)
}, Enum.EasingStyle.Back)

print("Teleport Waypoint Pro loaded | Key: . | Compact UI")

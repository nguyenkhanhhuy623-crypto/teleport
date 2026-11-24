--[[
    Racket Rivals - AUTO FARM / BOT  (bản viết lại, key: khuy)

    Tính năng:
      + Auto Swing  - spam đánh vào đối thủ
      + Auto Hit    - tự bấm trúng bóng khi bóng tới gần
      + Teleport to Ball - đưa nhân vật tới bóng (KHÔNG chặn di chuyển)
      + Fast Awakening - tự bấm phím kỹ năng
      + Menu kéo đi được, có nút ẩn / hiện
      + Key: khuy

    Fix lỗi "bật lên đứng im / không di chuyển được":
      - KHÔNG dùng Humanoid:MoveTo
      - KHÔNG đụng WalkSpeed / AutoRotate / PlatformStand / JumpPower
      - KHÔNG khóa chuột (không set MouseBehavior = LockCenter)
      - Teleport chỉ chạy khi người chơi KHÔNG giữ phím di chuyển,
        và sau khi teleport sẽ trả lại AutoRotate / PlatformStand về mặc định
      - Auto bấm dùng SendMouseButtonEvent đúng toạ độ mục tiêu,
        không "nuốt" input chuột nên WASD vẫn dùng được
]]

--------------------------------------------------------------
--  CẤU HÌNH
--------------------------------------------------------------
local CONFIG = {
    KEY             = "khuy",   -- key vào script (không phân biệt hoa thường)
    TITLE           = "RR AUTO FARM",

    HIT_RADIUS      = 18,       -- studs: bóng tới gần bao nhiêu thì auto bấm
    AWAKEN_DELAY    = 900,      -- ms giữa 2 lần bấm kỹ năng
    ONLY_OPPONENT   = false,    -- chỉ đánh người khác đội (nếu trận có đội)

    -- trạng thái bật sẵn khi vào game
    AUTO_SWING      = true,
    AUTO_HIT        = true,
    TELEPORT_BALL   = false,
    FAST_AWAKEN     = false,

    SWING_DELAY     = 90,       -- ms giữa 2 lần spam đánh
    TELEPORT_RADIUS = 12,       -- studs: bóng cách bao nhiêu thì mới dịch
    TELEPORT_COOLDOWN = 0.2,    -- giây giữa 2 lần teleport (tránh giật)
    AWAKEN_KEY      = "E",      -- phím kỹ năng / awakening
}

--------------------------------------------------------------
--  SERVICES
--------------------------------------------------------------
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local Workspace         = game:GetService("Workspace")
local CoreGui           = game:GetService("CoreGui")

local player = Players.LocalPlayer
local mouse  = player:FindFirstChildOfClass("PlayerMouse")
local camera = Workspace.CurrentCamera

--------------------------------------------------------------
--  TIỆN ÍCH
--------------------------------------------------------------
local function make(class, props, parent)
    local o = Instance.new(class)
    if props then
        for k, v in pairs(props) do o[k] = v end
    end
    o.Parent = parent
    return o
end

local function round(obj, radius)
    make("UICorner", { CornerRadius = UDim.new(0, radius or 8) }, obj)
end

local function stroke(obj, color, thickness)
    make("UIStroke", {
        Color = color,
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, obj)
end

-- Màu
local C_BG     = Color3.fromRGB(16, 17, 22)
local C_CARD   = Color3.fromRGB(28, 30, 38)
local C_CARD2  = Color3.fromRGB(40, 43, 55)
local C_TEXT   = Color3.fromRGB(235, 238, 245)
local C_DIM    = Color3.fromRGB(140, 148, 165)
local C_ACCENT = Color3.fromRGB(52, 211, 153)
local C_OFF    = Color3.fromRGB(62, 66, 80)
local C_RED    = Color3.fromRGB(239, 68, 68)
local C_BLUE   = Color3.fromRGB(96, 165, 250)

--------------------------------------------------------------
--  CHUỘT / BẤM / PHÍM
--------------------------------------------------------------
-- toạ độ màn hình thật (khớp GetMouseLocation và WorldToScreenPoint)
local function screenMouse()
    if type(GetMouseLocation) == "function" then
        local ok, x, y = pcall(GetMouseLocation)
        if ok and type(x) == "number" and type(y) == "number" then
            return x, y
        end
    end
    if UserInputService and UserInputService.GetMouseLocation then
        local ok, x, y = pcall(function() return UserInputService:GetMouseLocation() end)
        if ok and type(x) == "number" and type(y) == "number" then
            return x, y
        end
    end
    if mouse then
        local ok, x, y = pcall(function() return mouse.X, mouse.Y end)
        if ok and type(x) == "number" then return x, y end
    end
    return nil, nil
end

local function clickAt(x, y)
    if not x or not y then return false end
    if type(SendMouseButtonEvent) == "function" then
        local ok = pcall(SendMouseButtonEvent, x, y, 0, true,  game, 1)
        pcall(SendMouseButtonEvent, x, y, 0, false, game, 1)
        return ok
    end
    return false
end

local function pressKey(key)
    if type(SendKeyEvent) == "function" and key and key ~= "" then
        pcall(SendKeyEvent, true,  key, 0)
        pcall(SendKeyEvent, false, key, 0)
        return true
    end
    return false
end

-- người chơi có đang giữ phím di chuyển không
local MOVE_KEYS = { "W", "A", "S", "D" }
local function playerHoldingMove()
    if not (UserInputService and UserInputService.IsKeyDown) then return false end
    for _, k in ipairs(MOVE_KEYS) do
        local code = Enum.KeyCode[k]
        if code then
            local ok, down = pcall(function() return UserInputService:IsKeyDown(code) end)
            if ok and down then return true end
        end
    end
    return false
end

--------------------------------------------------------------
--  TÌM ĐỐI THỦ / BÓNG
--------------------------------------------------------------
local function alive(plr)
    local c = plr and plr.Character
    if not c then return false end
    local h = c:FindFirstChildOfClass("Humanoid")
    if h and h.Health <= 0 then return false end
    return true
end

local function rootOf(plr)
    local c = plr and plr.Character
    if not c then return nil end
    return c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Head") or c:FindFirstChild("Torso")
end

-- điểm ngắm: ưu tiên đầu (dễ bấm trúng trên màn hình)
local function aimPoint(plr)
    local c = plr and plr.Character
    if not c then return nil end
    return c:FindFirstChild("Head") or c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso")
end

local function myRoot()
    local c = player and player.Character
    if not c then return nil end
    return c:FindFirstChild("HumanoidRootPart")
end

local function sameTeam(a, b)
    if not (a and b) then return false end
    if not (a.Team and b.Team) then return false end
    if a.Team == b.Team then return true end
    if a.Neutral and b.Neutral then return true end
    return false
end

local function findOpponent()
    local mine = myRoot()
    if not mine then return nil end
    local myPos = mine.Position
    local best, bestDist = nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player and alive(plr) then
            if not (CONFIG.ONLY_OPPONENT and sameTeam(plr, player)) then
                local r = rootOf(plr)
                if r then
                    local d = (r.Position - myPos).Magnitude
                    if d < bestDist then best, bestDist = plr, d end
                end
            end
        end
    end
    return best
end

-- Quét tìm quả bóng (cache ~1.5s cho nhẹ)
local BALL_KEYS = { "ball", "tennisball", "racketball", "tennis" }
local ballCache, ballCacheAt = nil, -99

local function looksLikeBall(obj)
    if not obj or not obj:IsA("BasePart") then return false end
    local n = string.lower(obj.Name or "")
    for _, key in ipairs(BALL_KEYS) do
        if string.find(n, key, 1, true) then return true end
    end
    return false
end

local function findBall()
    local now = os.clock()
    if ballCache and ballCache.Parent and (now - ballCacheAt) < 1.5 then
        return ballCache
    end
    ballCache, ballCacheAt = nil, now
    local mine = myRoot()
    local best, bestDist = nil, math.huge
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if looksLikeBall(obj) then
            local d = 0
            if mine then d = (obj.Position - mine.Position).Magnitude end
            if d < bestDist then best, bestDist = obj, d end
        end
    end
    ballCache = best
    return best
end

-- thế giới -> màn hình
local function worldToScreen(pos)
    if not camera then camera = Workspace.CurrentCamera end
    if not camera then return nil end
    local ok, sp = pcall(function() return camera:WorldToScreenPoint(pos) end)
    if ok and sp then return sp end
    return nil
end

--------------------------------------------------------------
--  TRẠNG THÁI
--------------------------------------------------------------
local State = {
    swing      = CONFIG.AUTO_SWING,
    hit        = CONFIG.AUTO_HIT,
    teleport   = CONFIG.TELEPORT_BALL,
    awaken     = CONFIG.FAST_AWAKEN,
    swingRate  = CONFIG.SWING_DELAY,
    tpRadius   = CONFIG.TELEPORT_RADIUS,
    awakenKey  = CONFIG.AWAKEN_KEY,
    clicks     = 0,
    lastSwing  = 0,
    lastHit    = 0,
    lastAwaken = 0,
    lastTeleport = -99,
    oppName    = "-",
    ballSeen   = false,
}

--------------------------------------------------------------
--  KÉO THẢ (MENU DI CHUYỂN ĐƯỢC)
--------------------------------------------------------------
local drag = { active = false, target = nil, grabX = 0, grabY = 0 }

local function stopDrag()
    drag.active = false
    drag.target = nil
end

local function setupDrag(target, handle)
    handle.InputBegan:Connect(function(input)
        local t = input and input.UserInputType
        if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
            local x, y = screenMouse()
            if not x and input.Position then
                x, y = input.Position.X, input.Position.Y
            end
            if x then
                drag.active = true
                drag.target = target
                drag.grabX = x - target.Position.X.Offset
                drag.grabY = y - target.Position.Y.Offset
            end
        end
    end)

    handle.InputEnded:Connect(function(input)
        local t = input and input.UserInputType
        if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
            stopDrag()
        end
    end)
end

--------------------------------------------------------------
--  DỰNG GIAO DIỆN
--------------------------------------------------------------
local Gui, Main, TitleBar, Body, ShowBtn, StatusLabel, KeyFrame

local function buildShell()
    local host
    if type(gethui) == "function" then
        host = gethui()
    elseif player and player:FindFirstChildOfClass("PlayerGui") then
        host = player:FindFirstChildOfClass("PlayerGui")
    else
        host = CoreGui
    end

    Gui = make("ScreenGui", {
        Name           = "RRAutoFarmGui",
        ResetOnSpawn   = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    }, host)
    make("UITextureTransparencyService", { Name = "UITTS" }, Gui)

    -- nút gọi lại menu (nằm NGOÀI Main nên luôn bấm được, kể cả khi menu đã ẩn)
    ShowBtn = make("TextButton", {
        Name       = "ShowBtn",
        Text       = "☰",
        Size       = UDim2.fromOffset(44, 44),
        Position   = UDim2.fromOffset(14, 14),
        BackgroundColor3 = C_CARD,
        TextColor3 = C_TEXT,
        TextSize   = 20,
        Font       = Enum.Font.GothamBold,
        Active     = true,
        ZIndex     = 20,
    }, Gui)
    round(ShowBtn, 12); stroke(ShowBtn, C_ACCENT, 1.5)
    ShowBtn.Visible = false

    -- khung chính
    Main = make("Frame", {
        Name     = "Main",
        Size     = UDim2.fromOffset(300, 404),
        Position = UDim2.fromOffset(40, 90),
        BackgroundColor3 = C_BG,
        Active   = true,
        ZIndex   = 10,
    }, Gui)
    round(Main, 14); stroke(Main, C_OFF, 1)

    -- thanh tiêu đề (kéo được)
    TitleBar = make("Frame", {
        Name     = "TitleBar",
        Size     = UDim2.new(1, -16, 0, 36),
        Position = UDim2.fromOffset(8, 8),
        BackgroundColor3 = C_CARD,
        ZIndex   = 11,
    }, Main)
    round(TitleBar, 10)

    make("TextLabel", {
        Text              = CONFIG.TITLE,
        Size              = UDim2.new(1, -80, 1, 0),
        Position          = UDim2.fromOffset(12, 0),
        BackgroundTransparency = 1,
        TextColor3        = C_TEXT,
        TextSize          = 15,
        Font              = Enum.Font.GothamBold,
        TextXAlignment    = Enum.TextXAlignment.Left,
        ZIndex            = 12,
    }, TitleBar)

    local btnHide = make("TextButton", {
        Text       = "–",
        Size       = UDim2.fromOffset(26, 26),
        Position   = UDim2.new(1, -64, 0.5, -13),
        BackgroundColor3 = C_CARD2,
        TextColor3 = C_TEXT,
        TextSize   = 16,
        Font       = Enum.Font.GothamBold,
        ZIndex     = 12,
    }, TitleBar)
    round(btnHide, 7)

    local btnClose = make("TextButton", {
        Text       = "✕",
        Size       = UDim2.fromOffset(26, 26),
        Position   = UDim2.new(1, -32, 0.5, -13),
        BackgroundColor3 = C_CARD2,
        TextColor3 = C_RED,
        TextSize   = 13,
        Font       = Enum.Font.GothamBold,
        ZIndex     = 12,
    }, TitleBar)
    round(btnClose, 7)

    -- thân menu
    Body = make("ScrollingFrame", {
        Name                  = "Body",
        Size                  = UDim2.new(1, -16, 1, -56),
        Position              = UDim2.fromOffset(8, 50),
        BackgroundTransparency = 1,
        ScrollBarThickness    = 4,
        ScrollBarImageColor3  = C_OFF,
        AutomaticCanvasSize   = Enum.AutomaticSize.Y,
        CanvasSize            = UDim2.new(),
        ScrollingDirection    = Enum.ScrollingDirection.Y,
        ZIndex                = 11,
    }, Main)
    make("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding   = UDim.new(0, 7),
    }, Body)
    make("UIPadding", { PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 8) }, Body)

    return btnHide, btnClose
end

-- hàng trong thân menu
local function addRow(order, height)
    local row = make("Frame", {
        Size              = UDim2.new(1, -10, 0, height or 34),
        BackgroundColor3  = C_CARD,
        LayoutOrder       = order,
        ZIndex            = 11,
    }, Body)
    round(row, 9)
    return row
end

-- nút bật/tắt
local function addToggle(order, text, default, onChange)
    local row = addRow(order, 34)

    make("TextLabel", {
        Text              = text,
        Size              = UDim2.new(1, -70, 1, 0),
        Position          = UDim2.fromOffset(12, 0),
        BackgroundTransparency = 1,
        TextColor3        = C_TEXT,
        TextSize          = 14,
        Font              = Enum.Font.Gotham,
        TextXAlignment    = Enum.TextXAlignment.Left,
        ZIndex            = 12,
    }, row)

    local knob = make("Frame", {
        Size              = UDim2.fromOffset(40, 22),
        Position          = UDim2.new(1, -52, 0.5, -11),
        BackgroundColor3  = default and C_ACCENT or C_OFF,
        ZIndex            = 12,
    }, row)
    round(knob, 11)

    local circle = make("Frame", {
        Size             = UDim2.fromOffset(16, 16),
        Position         = UDim2.new(0, 2, 0.5, -8),
        BackgroundColor3 = Color3.fromRGB(245, 247, 252),
        ZIndex           = 13,
    }, knob)
    round(circle, 8)

    local st = { on = default }

    local function refresh()
        knob.BackgroundColor3 = st.on and C_ACCENT or C_OFF
        circle.Position = st.on and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
    end

    local btn = make("TextButton", {
        Size              = UDim2.fromOffset(56, 26),
        Position          = UDim2.new(1, -58, 0.5, -13),
        BackgroundTransparency = 1,
        Text              = "",
        ZIndex            = 14,
    }, row)

    btn.MouseButton1Click:Connect(function()
        st.on = not st.on
        refresh()
        if onChange then onChange(st.on) end
    end)

    refresh()
    return st
end

-- thanh trượt
local function addSlider(order, text, min, max, default, step, onChange)
    local row = addRow(order, 52)

    local valLabel = make("TextLabel", {
        Text              = text .. ": " .. tostring(default),
        Size              = UDim2.new(1, -20, 0, 20),
        Position          = UDim2.fromOffset(12, 2),
        BackgroundTransparency = 1,
        TextColor3        = C_TEXT,
        TextSize          = 13,
        Font              = Enum.Font.Gotham,
        TextXAlignment    = Enum.TextXAlignment.Left,
        ZIndex            = 12,
    }, row)

    local track = make("Frame", {
        Size             = UDim2.new(1, -24, 0, 6),
        Position         = UDim2.fromOffset(12, 28),
        BackgroundColor3 = C_OFF,
        ZIndex           = 12,
    }, row)
    round(track, 3)

    local fill = make("Frame", {
        Size             = UDim2.fromScale((default - min) / (max - min), 1),
        BackgroundColor3 = C_ACCENT,
        ZIndex           = 13,
    }, track)
    round(fill, 3)

    local knob = make("TextButton", {
        Text             = "",
        Size             = UDim2.fromOffset(16, 16),
        Position         = UDim2.new((default - min) / (max - min), 0.5, 0.5, 0),
        AnchorPoint      = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(245, 247, 252),
        ZIndex           = 14,
    }, track)
    round(knob, 8)

    local value  = default
    local dragging = false

    local function apply()
        local ratio = math.clamp((value - min) / (max - min), 0, 1)
        fill.Size   = UDim2.fromScale(ratio, 1)
        knob.Position = UDim2.new(ratio, 0.5, 0.5, 0)
        valLabel.Text = text .. ": " .. tostring(value)
        if onChange then onChange(value) end
    end

    local function setFromMouse()
        local x = screenMouse()
        if not x then return end
        local a = track.AbsolutePosition.X
        local w = track.AbsoluteSize.X
        if w <= 0 then return end
        local ratio = math.clamp((x - a) / w, 0, 1)
        local v = min + ratio * (max - min)
        v = math.floor(v / step + 0.5) * step
        value = math.clamp(v, min, max)
        apply()
    end

    knob.MouseButton1Down:Connect(function() dragging = true; setFromMouse() end)
    knob.MouseButton1Up:Connect(function() dragging = false end)
    knob.InputBegan:Connect(function() dragging = true end)
    knob.InputEnded:Connect(function() dragging = false end)

    RunService.RenderStepped:Connect(function()
        if dragging then setFromMouse() end
    end)

    apply()
    return { setValue = function(v) value = v; apply() end }
end

--------------------------------------------------------------
--  ẨN / HIỆN MENU
--------------------------------------------------------------
local function setMenuVisible(v)
    if not Main then return end
    Main.Visible = v
    if ShowBtn then ShowBtn.Visible = not v end
    if v then stopDrag() end
end

--------------------------------------------------------------
--  CỔNG KEY
--------------------------------------------------------------
local function buildKeyGate(onAccept)
    KeyFrame = make("Frame", {
        Size             = UDim2.fromOffset(300, 170),
        Position         = UDim2.new(0.5, -150, 0.5, -85),
        BackgroundColor3 = C_BG,
        Active           = true,
        ZIndex           = 30,
    }, Gui)
    round(KeyFrame, 14); stroke(KeyFrame, C_ACCENT, 1.5)

    make("TextLabel", {
        Text              = CONFIG.TITLE,
        Size              = UDim2.new(1, -20, 0, 28),
        Position          = UDim2.fromOffset(10, 10),
        BackgroundTransparency = 1,
        TextColor3        = C_TEXT,
        TextSize          = 17,
        Font              = Enum.Font.GothamBold,
        ZIndex            = 31,
    }, KeyFrame)

    make("TextLabel", {
        Text              = "Nhập key để vào script:",
        Size              = UDim2.new(1, -20, 0, 20),
        Position          = UDim2.fromOffset(10, 40),
        BackgroundTransparency = 1,
        TextColor3        = C_DIM,
        TextSize          = 13,
        Font              = Enum.Font.Gotham,
        TextXAlignment    = Enum.TextXAlignment.Left,
        ZIndex            = 31,
    }, KeyFrame)

    local box = make("TextBox", {
        Text                  = "",
        PlaceholderText       = "key...",
        Size                  = UDim2.new(1, -20, 0, 32),
        Position              = UDim2.fromOffset(10, 64),
        BackgroundColor3      = C_CARD,
        TextColor3            = C_TEXT,
        PlaceholderColor3     = C_DIM,
        TextSize              = 14,
        Font                  = Enum.Font.Gotham,
        ClearTextOnFocus      = false,
        ZIndex                = 31,
    }, KeyFrame)
    round(box, 8); stroke(box, C_OFF, 1)

    local msg = make("TextLabel", {
        Text              = "",
        Size              = UDim2.new(1, -20, 0, 18),
        Position          = UDim2.fromOffset(10, 100),
        BackgroundTransparency = 1,
        TextColor3        = C_RED,
        TextSize          = 12,
        Font              = Enum.Font.Gotham,
        TextXAlignment    = Enum.TextXAlignment.Left,
        ZIndex            = 31,
    }, KeyFrame)

    local btn = make("TextButton", {
        Text              = "VÀO",
        Size              = UDim2.new(1, -20, 0, 32),
        Position          = UDim2.fromOffset(10, 122),
        BackgroundColor3 = C_ACCENT,
        TextColor3        = Color3.fromRGB(12, 22, 18),
        TextSize          = 14,
        Font              = Enum.Font.GothamBold,
        ZIndex            = 31,
    }, KeyFrame)
    round(btn, 8)

    local function tryAccept()
        local v = string.lower(box.Text or "")
        v = string.gsub(v, "%s", "")
        v = string.gsub(v, "^:", "")
        v = string.gsub(v, ":$", "")
        if v == string.lower(CONFIG.KEY) then
            onAccept()
        else
            msg.Text = "Sai key rồi bro"
            box.Text = ""
        end
    end

    btn.MouseButton1Click:Connect(tryAccept)
    box.FocusLost:Connect(function(enterPressed)
        if enterPressed then tryAccept() end
    end)
end

--------------------------------------------------------------
--  THÂN MENU
--------------------------------------------------------------
local function buildBody(btnHide, btnClose)
    addToggle(1, "Auto Swing (spam đánh)", State.swing, function(v)
        State.swing = v
    end)

    addToggle(2, "Auto Hit (tự trúng bóng)", State.hit, function(v)
        State.hit = v
    end)

    addToggle(3, "Teleport tới bóng", State.teleport, function(v)
        State.teleport = v
    end)

    addToggle(4, "Fast Awakening", State.awaken, function(v)
        State.awaken = v
    end)

    addSlider(5, "Tốc độ đánh (ms)", 40, 400, State.swingRate, 10, function(v)
        State.swingRate = v
    end)

    addSlider(6, "Bán kính teleport", 3, 30, State.tpRadius, 1, function(v)
        State.tpRadius = v
    end)

    -- ô phím kỹ năng
    local row = addRow(7, 34)
    make("TextLabel", {
        Text              = "Phím kỹ năng:",
        Size              = UDim2.new(0, 110, 1, 0),
        Position          = UDim2.fromOffset(12, 0),
        BackgroundTransparency = 1,
        TextColor3        = C_TEXT,
        TextSize          = 13,
        Font              = Enum.Font.Gotham,
        TextXAlignment    = Enum.TextXAlignment.Left,
        ZIndex            = 12,
    }, row)
    local keyBox = make("TextBox", {
        Text              = State.awakenKey,
        Size              = UDim2.fromOffset(70, 24),
        Position          = UDim2.new(1, -82, 0.5, -12),
        BackgroundColor3  = C_CARD2,
        TextColor3        = C_TEXT,
        TextSize          = 13,
        Font              = Enum.Font.GothamBold,
        ClearTextOnFocus  = false,
        ZIndex            = 12,
    }, row)
    round(keyBox, 7)
    keyBox:GetPropertyChangedSignal("Text"):Connect(function()
        State.awakenKey = keyBox.Text
    end)

    -- trạng thái
    local srow = addRow(8, 44)
    StatusLabel = make("TextLabel", {
        Text              = "Trạng thái: đang chờ vào trận",
        Size              = UDim2.new(1, -24, 1, 0),
        Position          = UDim2.fromOffset(12, 0),
        BackgroundTransparency = 1,
        TextColor3        = C_DIM,
        TextSize          = 12,
        Font              = Enum.Font.Gotham,
        TextXAlignment    = Enum.TextXAlignment.Left,
        TextYAlignment    = Enum.TextYAlignment.Top,
        ZIndex            = 12,
    }, srow)

    -- ghi chú
    local note = addRow(9, 40)
    make("TextLabel", {
        Text              = "Bạn vẫn đi bình thường được: teleport không khóa chuột và bỏ qua khi bạn đang giữ W/A/S/D.",
        Size              = UDim2.new(1, -24, 1, 0),
        Position          = UDim2.fromOffset(12, 0),
        BackgroundTransparency = 1,
        TextColor3        = C_BLUE,
        TextSize          = 11,
        Font              = Enum.Font.Gotham,
        TextWrapped       = true,
        TextXAlignment    = Enum.TextXAlignment.Left,
        TextYAlignment    = Enum.TextYAlignment.Top,
        ZIndex            = 12,
    }, note)

    -- nút ẩn / hiện
    btnHide.MouseButton1Click:Connect(function()
        if Body.Visible then
            Body.Visible = false
            Main.Size = UDim2.fromOffset(300, 52)
            btnHide.Text = "▢"
        else
            Body.Visible = true
            Main.Size = UDim2.fromOffset(300, 404)
            btnHide.Text = "–"
        end
    end)

    btnClose.MouseButton1Click:Connect(function()
        stopDrag()
        setMenuVisible(false)
    end)

    ShowBtn.MouseButton1Click:Connect(function()
        setMenuVisible(true)
    end)
end

--------------------------------------------------------------
--  VÒNG LẶP GAME
--------------------------------------------------------------
local function teleportToBall(ball, mine, now)
    -- không teleport khi người chơi đang giữ phím di chuyển -> luôn đi được
    if playerHoldingMove() then return false end
    -- cooldown để không giật
    if (now - State.lastTeleport) < CONFIG.TELEPORT_COOLDOWN then return false end

    local dist = (ball.Position - mine.Position).Magnitude
    if dist <= State.tpRadius then return false end

    mine.CFrame = CFrame.new(ball.Position + Vector3.new(0, 0, -3))
    State.lastTeleport = now

    -- trả lại trạng thái di chuyển về bình thường ngay lập tức
    local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.AutoRotate   = true
        hum.PlatformStand = false
    end
    return true
end

local function step()
    -- kéo menu
    if drag.active and drag.target then
        local x, y = screenMouse()
        if x then
            drag.target.Position = UDim2.fromOffset(x - drag.grabX, y - drag.grabY)
        end
    end

    local mine = myRoot()
    if not mine then
        if StatusLabel then StatusLabel.Text = "Trạng thái: đang chờ vào trận" end
        return
    end

    local now = os.clock()

    local opp = findOpponent()
    State.oppName = opp and opp.Name or "-"

    local ball = findBall()
    State.ballSeen = ball ~= nil

    -- 1) TELEPORT TỚI BÓNG
    if State.teleport and ball then
        teleportToBall(ball, mine, now)
    end

    -- 2) AUTO HIT: bấm vào bóng khi bóng tới gần
    if State.hit and ball and (now - State.lastHit) >= 0.08 then
        local dist = (ball.Position - mine.Position).Magnitude
        if dist <= CONFIG.HIT_RADIUS then
            local sp = worldToScreen(ball.Position)
            if sp then
                clickAt(sp.X, sp.Y)
                State.clicks = State.clicks + 1
            end
        end
        State.lastHit = now
    end

    -- 3) SPAM SWING: bấm liên tục vào đối thủ
    if State.swing and opp and (now - State.lastSwing) >= (State.swingRate / 1000) then
        local r = aimPoint(opp)
        if r then
            local sp = worldToScreen(r.Position)
            if sp then
                clickAt(sp.X, sp.Y)
                State.clicks = State.clicks + 1
            end
        end
        State.lastSwing = now
    end

    -- 4) FAST AWAKENING
    if State.awaken and (now - State.lastAwaken) >= (CONFIG.AWAKEN_DELAY / 1000) then
        pressKey(State.awakenKey)
        State.lastAwaken = now
    end

    -- dòng trạng thái
    if StatusLabel then
        local parts = {}
        if State.swing    then parts[#parts + 1] = "swing" end
        if State.hit      then parts[#parts + 1] = "hit" end
        if State.teleport then parts[#parts + 1] = "tp" end
        if State.awaken   then parts[#parts + 1] = "awaken" end
        local mode = #parts > 0 and table.concat(parts, " + ") or "off"
        StatusLabel.Text = string.format(
            "Trạng thái: %s\nĐối thủ: %s | Bóng: %s | Đã bấm: %d",
            mode, State.oppName, State.ballSeen and "có" or "chưa thấy", State.clicks)
    end
end

--------------------------------------------------------------
--  KHỞI ĐỘNG
--------------------------------------------------------------
local function startLoop()
    local rs = RunService.RenderStepped or RunService.Heartbeat
    rs:Connect(step)
end

local function main()
    if getgenv then
        if getgenv().__RR_AUTO_FARM then
            print("[RR AutoFarm] Script đã chạy rồi")
            return
        end
        getgenv().__RR_AUTO_FARM = true
    end

    local old = CoreGui:FindFirstChild("RRAutoFarmGui")
    if old then old:Destroy() end

    local btnHide, btnClose = buildShell()
    setupDrag(Main, TitleBar)

    buildKeyGate(function()
        if KeyFrame then KeyFrame:Destroy(); KeyFrame = nil end
        buildBody(btnHide, btnClose)
        setMenuVisible(true)
        startLoop()
        print("[RR AutoFarm] Đăng nhập thành công (key: " .. CONFIG.KEY .. ")")
    end)
end

player.CharacterAdded:Connect(function()
    task.wait(0.5)
    camera = Workspace.CurrentCamera
end)

main()

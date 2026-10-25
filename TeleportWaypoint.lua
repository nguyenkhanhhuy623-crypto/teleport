-- ══════════════════════════════════════════════════════════════
--  TELEPORT WAYPOINT SYSTEM
--  Platform : Roblox, Lua 5.1, Universal (all games)
--  Inject via any executor (Synapse, KRNL, Fluxus, etc.)
-- ══════════════════════════════════════════════════════════════

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ── State ──────────────────────────────────────────────────────
local waypoints  = {}   -- { name=string, pos=Vector3 }
local guiVisible = true

-- ══════════════════════════════════════════════════════════════
--  THEME
-- ══════════════════════════════════════════════════════════════
local T = {
    bg        = Color3.fromRGB(15,  15,  20),
    panel     = Color3.fromRGB(22,  22,  30),
    card      = Color3.fromRGB(30,  30,  42),
    accent    = Color3.fromRGB(120, 80, 255),
    accentDim = Color3.fromRGB(70,  45, 160),
    success   = Color3.fromRGB(50,  200, 120),
    danger    = Color3.fromRGB(220, 70,  70),
    text      = Color3.fromRGB(230, 230, 240),
    subtext   = Color3.fromRGB(140, 140, 160),
    white     = Color3.fromRGB(255, 255, 255),
}

-- ══════════════════════════════════════════════════════════════
--  HELPERS
-- ══════════════════════════════════════════════════════════════
local function newInstance(cls, props)
    local obj = Instance.new(cls)
    for k, v in pairs(props) do
        obj[k] = v
    end
    return obj
end

local function tween(obj, props, dur, style, dir)
    style = style or Enum.EasingStyle.Quad
    dir   = dir   or Enum.EasingDirection.Out
    TweenService:Create(obj, TweenInfo.new(dur, style, dir), props):Play()
end

local function getRootPart()
    local char = player.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

local function truncate(str, max)
    if #str > max then return str:sub(1, max - 1) .. "…" end
    return str
end

-- ══════════════════════════════════════════════════════════════
--  SCREEN GUI ROOT
-- ══════════════════════════════════════════════════════════════
-- Remove existing instance if re-injected
if playerGui:FindFirstChild("VantaTeleport") then
    playerGui:FindFirstChild("VantaTeleport"):Destroy()
end

local screenGui = newInstance("ScreenGui", {
    Name              = "VantaTeleport",
    Parent            = playerGui,
    ResetOnSpawn      = false,
    ZIndexBehavior    = Enum.ZIndexBehavior.Sibling,
    IgnoreGuiInset    = true,
})

-- ══════════════════════════════════════════════════════════════
--  MAIN WINDOW  (draggable)
-- ══════════════════════════════════════════════════════════════
local window = newInstance("Frame", {
    Name            = "Window",
    Parent          = screenGui,
    Size            = UDim2.new(0, 320, 0, 460),
    Position        = UDim2.new(0.5, -160, 0.5, -230),
    BackgroundColor3 = T.bg,
    BorderSizePixel = 0,
    ClipsDescendants = false,
})
newInstance("UICorner",  { CornerRadius = UDim.new(0, 12), Parent = window })
newInstance("UIStroke",  { Color = T.accent, Thickness = 1.2, Transparency = 0.5, Parent = window })

-- drop shadow (decorative frame behind)
local shadow = newInstance("ImageLabel", {
    Name            = "Shadow",
    Parent          = window,
    Size            = UDim2.new(1, 30, 1, 30),
    Position        = UDim2.new(0, -15, 0, 10),
    BackgroundTransparency = 1,
    Image           = "rbxassetid://6015897843",
    ImageColor3     = Color3.fromRGB(0, 0, 0),
    ImageTransparency = 0.55,
    ScaleType       = Enum.ScaleType.Slice,
    SliceCenter     = Rect.new(49, 49, 450, 450),
    ZIndex          = -1,
})

-- ── Title bar ─────────────────────────────────────────────────
local titleBar = newInstance("Frame", {
    Name            = "TitleBar",
    Parent          = window,
    Size            = UDim2.new(1, 0, 0, 44),
    BackgroundColor3 = T.panel,
    BorderSizePixel = 0,
    ZIndex          = 2,
})
newInstance("UICorner", { CornerRadius = UDim.new(0, 12), Parent = titleBar })

-- patch bottom corners of titlebar
newInstance("Frame", {
    Parent          = titleBar,
    Size            = UDim2.new(1, 0, 0, 12),
    Position        = UDim2.new(0, 0, 1, -12),
    BackgroundColor3 = T.panel,
    BorderSizePixel = 0,
    ZIndex          = 2,
})

local titleIcon = newInstance("TextLabel", {
    Parent          = titleBar,
    Size            = UDim2.new(0, 30, 1, 0),
    Position        = UDim2.new(0, 12, 0, 0),
    BackgroundTransparency = 1,
    Text            = "⬡",
    TextColor3      = T.accent,
    Font            = Enum.Font.GothamBold,
    TextSize        = 18,
    ZIndex          = 3,
})

local titleLabel = newInstance("TextLabel", {
    Parent          = titleBar,
    Size            = UDim2.new(1, -80, 1, 0),
    Position        = UDim2.new(0, 42, 0, 0),
    BackgroundTransparency = 1,
    Text            = "WAYPOINT TELEPORT",
    TextColor3      = T.text,
    Font            = Enum.Font.GothamBold,
    TextSize        = 13,
    TextXAlignment  = Enum.TextXAlignment.Left,
    ZIndex          = 3,
})

local closeBtn = newInstance("TextButton", {
    Parent          = titleBar,
    Size            = UDim2.new(0, 28, 0, 28),
    Position        = UDim2.new(1, -36, 0.5, -14),
    BackgroundColor3 = T.danger,
    Text            = "✕",
    TextColor3      = T.white,
    Font            = Enum.Font.GothamBold,
    TextSize        = 12,
    BorderSizePixel = 0,
    ZIndex          = 4,
})
newInstance("UICorner", { CornerRadius = UDim.new(1, 0), Parent = closeBtn })

-- ── Dragging logic ────────────────────────────────────────────
local dragging, dragStart, startPos = false, nil, nil
titleBar.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 or
       inp.UserInputType == Enum.UserInputType.Touch then
        dragging  = true
        dragStart = inp.Position
        startPos  = window.Position
    end
end)
UserInputService.InputChanged:Connect(function(inp)
    if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or
                     inp.UserInputType == Enum.UserInputType.Touch) then
        local delta = inp.Position - dragStart
        window.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)
UserInputService.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 or
       inp.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- ── Close / toggle ────────────────────────────────────────────
closeBtn.MouseButton1Click:Connect(function()
    tween(window, { Size = UDim2.new(0, 320, 0, 0) }, 0.25)
    task.delay(0.26, function() screenGui:Destroy() end)
end)

-- ══════════════════════════════════════════════════════════════
--  ADD WAYPOINT SECTION
-- ══════════════════════════════════════════════════════════════
local addSection = newInstance("Frame", {
    Parent          = window,
    Size            = UDim2.new(1, -24, 0, 80),
    Position        = UDim2.new(0, 12, 0, 52),
    BackgroundColor3 = T.panel,
    BorderSizePixel = 0,
})
newInstance("UICorner", { CornerRadius = UDim.new(0, 8), Parent = addSection })

local nameInput = newInstance("TextBox", {
    Parent          = addSection,
    Size            = UDim2.new(1, -100, 0, 34),
    Position        = UDim2.new(0, 10, 0, 10),
    BackgroundColor3 = T.card,
    Text            = "",
    PlaceholderText = "Tên waypoint...",
    TextColor3      = T.text,
    PlaceholderColor3 = T.subtext,
    Font            = Enum.Font.Gotham,
    TextSize        = 13,
    BorderSizePixel = 0,
    ClearTextOnFocus = false,
    TextXAlignment  = Enum.TextXAlignment.Left,
})
newInstance("UICorner",   { CornerRadius = UDim.new(0, 6), Parent = nameInput })
newInstance("UIPadding",  { PaddingLeft = UDim.new(0, 10), Parent = nameInput })

local setBtn = newInstance("TextButton", {
    Parent          = addSection,
    Size            = UDim2.new(0, 80, 0, 34),
    Position        = UDim2.new(1, -88, 0, 10),
    BackgroundColor3 = T.accent,
    Text            = "+ SET",
    TextColor3      = T.white,
    Font            = Enum.Font.GothamBold,
    TextSize        = 12,
    BorderSizePixel = 0,
})
newInstance("UICorner", { CornerRadius = UDim.new(0, 6), Parent = setBtn })

local statusLabel = newInstance("TextLabel", {
    Parent          = addSection,
    Size            = UDim2.new(1, -20, 0, 20),
    Position        = UDim2.new(0, 10, 0, 50),
    BackgroundTransparency = 1,
    Text            = "Nhập tên → bấm SET để lưu vị trí hiện tại",
    TextColor3      = T.subtext,
    Font            = Enum.Font.Gotham,
    TextSize        = 11,
    TextXAlignment  = Enum.TextXAlignment.Left,
})

-- ── Hover effect on setBtn ────────────────────────────────────
setBtn.MouseEnter:Connect(function()
    tween(setBtn, { BackgroundColor3 = T.accentDim }, 0.15)
end)
setBtn.MouseLeave:Connect(function()
    tween(setBtn, { BackgroundColor3 = T.accent }, 0.15)
end)

-- ══════════════════════════════════════════════════════════════
--  DIVIDER + LIST HEADER
-- ══════════════════════════════════════════════════════════════
newInstance("Frame", {
    Parent          = window,
    Size            = UDim2.new(1, -24, 0, 1),
    Position        = UDim2.new(0, 12, 0, 142),
    BackgroundColor3 = T.accentDim,
    BorderSizePixel = 0,
})

local listHeader = newInstance("TextLabel", {
    Parent          = window,
    Size            = UDim2.new(1, -24, 0, 22),
    Position        = UDim2.new(0, 14, 0, 150),
    BackgroundTransparency = 1,
    Text            = "WAYPOINTS (0)",
    TextColor3      = T.subtext,
    Font            = Enum.Font.GothamBold,
    TextSize        = 11,
    TextXAlignment  = Enum.TextXAlignment.Left,
})

-- ══════════════════════════════════════════════════════════════
--  SCROLLING LIST
-- ══════════════════════════════════════════════════════════════
local scrollFrame = newInstance("ScrollingFrame", {
    Parent               = window,
    Size                 = UDim2.new(1, -24, 1, -182),
    Position             = UDim2.new(0, 12, 0, 176),
    BackgroundTransparency = 1,
    BorderSizePixel      = 0,
    ScrollBarThickness   = 3,
    ScrollBarImageColor3 = T.accent,
    CanvasSize           = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize  = Enum.AutomaticSize.Y,
    ClipsDescendants     = true,
})
newInstance("UIListLayout", {
    Parent          = scrollFrame,
    Padding         = UDim.new(0, 6),
    FillDirection   = Enum.FillDirection.Vertical,
    SortOrder       = Enum.SortOrder.LayoutOrder,
})
newInstance("UIPadding", {
    Parent      = scrollFrame,
    PaddingTop  = UDim.new(0, 2),
    PaddingBottom = UDim.new(0, 6),
})

-- ══════════════════════════════════════════════════════════════
--  EMPTY STATE LABEL
-- ══════════════════════════════════════════════════════════════
local emptyLabel = newInstance("TextLabel", {
    Parent          = scrollFrame,
    Size            = UDim2.new(1, 0, 0, 60),
    BackgroundTransparency = 1,
    Text            = "Chưa có waypoint nào.\nNhập tên và bấm SET để bắt đầu.",
    TextColor3      = T.subtext,
    Font            = Enum.Font.Gotham,
    TextSize        = 12,
    TextWrapped     = true,
    RichText        = false,
    Name            = "EmptyLabel",
})

-- ══════════════════════════════════════════════════════════════
--  WAYPOINT CARD BUILDER
-- ══════════════════════════════════════════════════════════════
local function rebuildList()
    -- clear existing cards (keep EmptyLabel)
    for _, child in ipairs(scrollFrame:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    listHeader.Text = ("WAYPOINTS (%d)"):format(#waypoints)

    if #waypoints == 0 then
        emptyLabel.Visible = true
        return
    end
    emptyLabel.Visible = false

    for idx, wp in ipairs(waypoints) do
        local card = newInstance("Frame", {
            Parent          = scrollFrame,
            Size            = UDim2.new(1, 0, 0, 56),
            BackgroundColor3 = T.card,
            BorderSizePixel = 0,
            LayoutOrder     = idx,
            Name            = "Card_" .. idx,
        })
        newInstance("UICorner", { CornerRadius = UDim.new(0, 8), Parent = card })

        -- accent left bar
        local bar = newInstance("Frame", {
            Parent          = card,
            Size            = UDim2.new(0, 3, 0.7, 0),
            Position        = UDim2.new(0, 0, 0.15, 0),
            BackgroundColor3 = T.accent,
            BorderSizePixel = 0,
        })
        newInstance("UICorner", { CornerRadius = UDim.new(1, 0), Parent = bar })

        -- index badge
        newInstance("TextLabel", {
            Parent          = card,
            Size            = UDim2.new(0, 22, 0, 22),
            Position        = UDim2.new(0, 10, 0.5, -11),
            BackgroundColor3 = T.accentDim,
            Text            = tostring(idx),
            TextColor3      = T.white,
            Font            = Enum.Font.GothamBold,
            TextSize        = 11,
            BorderSizePixel = 0,
        }):FindFirstChildOfClass("UICorner") or
        newInstance("UICorner", { CornerRadius = UDim.new(1, 0),
            Parent = card:FindFirstChild("TextLabel") or card })

        -- fix: add UICorner to badge separately
        local badge = card:FindFirstChildWhichIsA("TextLabel")
        if badge then
            newInstance("UICorner", { CornerRadius = UDim.new(1, 0), Parent = badge })
        end

        -- name label
        local nameLabel = newInstance("TextLabel", {
            Parent          = card,
            Size            = UDim2.new(1, -120, 0, 20),
            Position        = UDim2.new(0, 40, 0, 8),
            BackgroundTransparency = 1,
            Text            = truncate(wp.name, 22),
            TextColor3      = T.text,
            Font            = Enum.Font.GothamBold,
            TextSize        = 13,
            TextXAlignment  = Enum.TextXAlignment.Left,
        })

        -- coords label
        local coordLabel = newInstance("TextLabel", {
            Parent          = card,
            Size            = UDim2.new(1, -120, 0, 16),
            Position        = UDim2.new(0, 40, 0, 30),
            BackgroundTransparency = 1,
            Text            = ("X:%.0f  Y:%.0f  Z:%.0f"):format(
                                wp.pos.X, wp.pos.Y, wp.pos.Z),
            TextColor3      = T.subtext,
            Font            = Enum.Font.Code,
            TextSize        = 10,
            TextXAlignment  = Enum.TextXAlignment.Left,
        })

        -- teleport button
        local tpBtn = newInstance("TextButton", {
            Parent          = card,
            Size            = UDim2.new(0, 58, 0, 30),
            Position        = UDim2.new(1, -130, 0.5, -15),
            BackgroundColor3 = T.success,
            Text            = "⟶ TP",
            TextColor3      = T.white,
            Font            = Enum.Font.GothamBold,
            TextSize        = 11,
            BorderSizePixel = 0,
        })
        newInstance("UICorner", { CornerRadius = UDim.new(0, 6), Parent = tpBtn })

        -- delete button
        local delBtn = newInstance("TextButton", {
            Parent          = card,
            Size            = UDim2.new(0, 30, 0, 30),
            Position        = UDim2.new(1, -62, 0.5, -15),
            BackgroundColor3 = T.danger,
            Text            = "✕",
            TextColor3      = T.white,
            Font            = Enum.Font.GothamBold,
            TextSize        = 11,
            BorderSizePixel = 0,
        })
        newInstance("UICorner", { CornerRadius = UDim.new(0, 6), Parent = delBtn })

        -- ── Teleport action ───────────────────────────────────
        local capturedWp = wp
        tpBtn.MouseButton1Click:Connect(function()
            local root = getRootPart()
            if not root then return end
            root.CFrame = CFrame.new(capturedWp.pos + Vector3.new(0, 3, 0))
            -- flash feedback
            tween(tpBtn, { BackgroundColor3 = T.accent }, 0.1)
            task.delay(0.4, function()
                if tpBtn and tpBtn.Parent then
                    tween(tpBtn, { BackgroundColor3 = T.success }, 0.2)
                end
            end)
            -- status update
            statusLabel.TextColor3 = T.success
            statusLabel.Text = ("✓ Teleport → %s"):format(truncate(capturedWp.name, 18))
            task.delay(2, function()
                if statusLabel and statusLabel.Parent then
                    statusLabel.TextColor3 = T.subtext
                    statusLabel.Text = "Nhập tên → bấm SET để lưu vị trí hiện tại"
                end
            end)
        end)

        tpBtn.MouseEnter:Connect(function()
            tween(tpBtn, { BackgroundColor3 = Color3.fromRGB(30, 170, 95) }, 0.12)
        end)
        tpBtn.MouseLeave:Connect(function()
            tween(tpBtn, { BackgroundColor3 = T.success }, 0.12)
        end)

        -- ── Delete action ─────────────────────────────────────
        local capturedIdx = idx
        delBtn.MouseButton1Click:Connect(function()
            table.remove(waypoints, capturedIdx)
            rebuildList()
        end)

        delBtn.MouseEnter:Connect(function()
            tween(delBtn, { BackgroundColor3 = Color3.fromRGB(190, 50, 50) }, 0.12)
        end)
        delBtn.MouseLeave:Connect(function()
            tween(delBtn, { BackgroundColor3 = T.danger }, 0.12)
        end)
    end
end

-- initial render
rebuildList()

-- ══════════════════════════════════════════════════════════════
--  SET BUTTON LOGIC
-- ══════════════════════════════════════════════════════════════
setBtn.MouseButton1Click:Connect(function()
    local root = getRootPart()
    if not root then
        statusLabel.TextColor3 = T.danger
        statusLabel.Text = "✗ Không tìm thấy character"
        return
    end

    local rawName = nameInput.Text:match("^%s*(.-)%s*$")  -- trim
    if rawName == "" then
        rawName = "Waypoint " .. (#waypoints + 1)
    end

    -- check duplicate name, append number if needed
    local baseName, count = rawName, 1
    local function nameExists(n)
        for _, wp in ipairs(waypoints) do
            if wp.name == n then return true end
        end
        return false
    end
    while nameExists(rawName) do
        count = count + 1
        rawName = baseName .. " (" .. count .. ")"
    end

    table.insert(waypoints, {
        name = rawName,
        pos  = root.Position,
    })

    nameInput.Text = ""
    rebuildList()

    statusLabel.TextColor3 = T.success
    statusLabel.Text = ("✓ Đã lưu: %s"):format(truncate(rawName, 20))
    task.delay(2.5, function()
        if statusLabel and statusLabel.Parent then
            statusLabel.TextColor3 = T.subtext
            statusLabel.Text = "Nhập tên → bấm SET để lưu vị trí hiện tại"
        end
    end)

    -- pulse effect on setBtn
    tween(setBtn, { BackgroundColor3 = T.success }, 0.15)
    task.delay(0.4, function()
        if setBtn and setBtn.Parent then
            tween(setBtn, { BackgroundColor3 = T.accent }, 0.2)
        end
    end)
end)

-- ══════════════════════════════════════════════════════════════
--  KEYBIND: RightControl = toggle visibility
-- ══════════════════════════════════════════════════════════════
UserInputService.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if inp.KeyCode == Enum.KeyCode.RightControl then
        guiVisible = not guiVisible
        tween(window, { GroupTransparency = guiVisible and 0 or 1 }, 0.2)
        window.Active = guiVisible
    end
end)

-- ══════════════════════════════════════════════════════════════
--  SPAWN ANIMATION
-- ══════════════════════════════════════════════════════════════
window.GroupTransparency = 1
window.Size = UDim2.new(0, 320, 0, 420)
task.delay(0.05, function()
    tween(window, { GroupTransparency = 0, Size = UDim2.new(0, 320, 0, 460) }, 0.35,
        Enum.EasingStyle.Back, Enum.EasingDirection.Out)
end)

-- ── done ──────────────────────────────────────────────────────
print("[VantaTeleport] Loaded. RightCtrl = ẩn/hiện menu.")

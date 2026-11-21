--[[
  FLUYEN HUD MENU - v6.0 PREMIUM REBUILD
  Delta executor (Android / Mobile first) | PC compatible
  - Responsive UI, modern glass design, search, quick bar
  - Gesture v2: 3-finger Tap / Hold / Swipe / Tap x3 (chon trong Settings)
  - 1 master loop (thay cho ~20 loop rieng) + tracer pooling -> het lag
  - Fly / Freecam co joystick tren mobile
  - Key + Settings + Version qua Supabase, fallback offline
  - Panic button, Unload, Update check trong menu
]]
local _taskOk = false
pcall(function() local _ = task _taskOk = true end)
local function _wait(t) t = t or 0
  local ok = pcall(function() wait(t) end) if ok then return end
  if _taskOk then ok = pcall(function() task.wait(t) end) if ok then return end end
  local t0 = tick() while tick() - t0 < t do end
end
local function _spawn(f)
  local ok = pcall(function() spawn(f) end) if ok then return end
  if _taskOk then ok = pcall(function() task.spawn(f) end) if ok then return end end
  pcall(function() coroutine.wrap(f)() end)
end
local function _delay(t, f) t = t or 0
  local ok = pcall(function() delay(t, f) end) if ok then return end
  if _taskOk then ok = pcall(function() task.delay(t, f) end) if ok then return end end
  _spawn(function() _wait(t) f() end)
end
local _ok, _err = pcall(function()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = Workspace.CurrentCamera
pcall(function()
  if getconnections then
    for _, conn in pairs(getconnections(game:GetService("ScriptContext").Error)) do
      if conn.Disable then conn:Disable() end
    end
  end
end)
-- ============ CONFIG / SUPABASE ============
local SCRIPT_NAME = "FLUYEN"
local SCRIPT_VERSION = "v6.0"
local SUPABASE_URL = "https://jvaikkfmmxvvrwxkzxui.supabase.co"
local SUPABASE_KEY = "sb_publishable_zLIpbNfh_AKyWH3dADe_CA_2Ld4OgJb"
local LOCAL_KEY = "huyandkhang"
local keyAuthenticated = false
pcall(function()
  local saved = readfile("FLUYEN_key.txt")
  if saved == LOCAL_KEY then keyAuthenticated = true end
end)
-- ============ STATES / VALUES ============
local States = {
  ESP=false, BoxESP=false, NameESP=false, HealthESP=false, DistanceESP=false,
  Tracers=false, Chams=false, FullBright=false, NightVision=false, Xray=false,
  Aim=false, SilentAim=false, AimFOV=false, AimPrediction=false, TriggerBot=false, HitboxExpander=false,
  Speed=false, Fly=false, Noclip=false, JumpPower=false, InfiniteJump=false, ClickTeleport=false, Sprint=false, AntiVoid=false,
  AntiAFK=true, FreezeTime=false, FPSBoost=false, AntiBlind=false, AntiSlow=false, AntiRagdoll=false, AntiGrab=false,
  Spin=false, Float=false, Bang=false, Fling=false, Invisible=false, OrbitActive=false, LowGravity=false, Freecam=false,
  AutoLoadSettings=true, MinimizeButton=true, DraggableGUI=true, Notifications=true,
  QuickBar=true, GestureEnabled=true, ShowFPS=true, ShowPing=true, ShowPlayers=true, Haptic=true,
}
local Values = {
  SpeedValue=16, FlySpeed=50, JumpPowerValue=50, SprintSpeed=24, SpinSpeed=10,
  AimFOVValue=90, AimSmoothness=5, HitboxSize=10, OrbitRadius=5, OrbitSpeed=1,
  FlingPower=500, FieldOfView=70, LowGravityValue=50,
  GestureMode="Tap1", Accent="Orange", MenuOpacity=0.98,
}
local Conns = {}
local function killConn(n) if Conns[n] then pcall(function() Conns[n]:Disconnect() end) Conns[n]=nil end end
local function setConn(n, c) killConn(n) Conns[n]=c end
local FeatureCB = {} -- stateKey -> callback, de QuickBar / Panic goi lai
local RowRegistry = {} -- {row, page, text} de Search loc
local function clamp(v,a,b) return math.max(a, math.min(b, v)) end
-- ============ THEME ============
local currentTheme = "Dark"
local Themes = {
  Dark = { bg=Color3.fromRGB(18,18,24), sidebar=Color3.fromRGB(14,14,20), card=Color3.fromRGB(26,26,34), tabActive=Color3.fromRGB(38,38,50), tabInactive=Color3.fromRGB(14,14,20), accent=Color3.fromRGB(255,107,53), accent2=Color3.fromRGB(255,180,100), text=Color3.fromRGB(245,245,250), textDim=Color3.fromRGB(150,150,165), checkBg=Color3.fromRGB(48,48,60), checkOn=Color3.fromRGB(255,107,53), track=Color3.fromRGB(52,52,66), fill=Color3.fromRGB(255,107,53), btnBg=Color3.fromRGB(38,38,50), btnHover=Color3.fromRGB(55,55,70), dropBg=Color3.fromRGB(32,32,42), border=Color3.fromRGB(55,55,70) },
  Light = { bg=Color3.fromRGB(246,246,250), sidebar=Color3.fromRGB(232,232,238), card=Color3.fromRGB(255,255,255), tabActive=Color3.fromRGB(255,255,255), tabInactive=Color3.fromRGB(232,232,238), accent=Color3.fromRGB(255,107,53), accent2=Color3.fromRGB(255,150,80), text=Color3.fromRGB(28,28,34), textDim=Color3.fromRGB(105,105,120), checkBg=Color3.fromRGB(215,215,225), checkOn=Color3.fromRGB(255,107,53), track=Color3.fromRGB(210,210,220), fill=Color3.fromRGB(255,107,53), btnBg=Color3.fromRGB(232,232,238), btnHover=Color3.fromRGB(242,242,248), dropBg=Color3.fromRGB(228,228,235), border=Color3.fromRGB(200,200,212) },
  SkyBlue = { bg=Color3.fromRGB(16,22,36), sidebar=Color3.fromRGB(12,17,30), card=Color3.fromRGB(24,32,52), tabActive=Color3.fromRGB(34,46,72), tabInactive=Color3.fromRGB(12,17,30), accent=Color3.fromRGB(80,180,255), accent2=Color3.fromRGB(140,220,255), text=Color3.fromRGB(232,242,255), textDim=Color3.fromRGB(125,145,175), checkBg=Color3.fromRGB(38,50,72), checkOn=Color3.fromRGB(80,180,255), track=Color3.fromRGB(42,54,78), fill=Color3.fromRGB(80,180,255), btnBg=Color3.fromRGB(32,44,68), btnHover=Color3.fromRGB(44,58,86), dropBg=Color3.fromRGB(26,36,58), border=Color3.fromRGB(44,60,88) },
  Galaxy = { bg=Color3.fromRGB(14,10,28), sidebar=Color3.fromRGB(10,8,24), card=Color3.fromRGB(24,18,46), tabActive=Color3.fromRGB(34,24,62), tabInactive=Color3.fromRGB(10,8,24), accent=Color3.fromRGB(180,100,255), accent2=Color3.fromRGB(255,120,220), text=Color3.fromRGB(234,224,255), textDim=Color3.fromRGB(125,115,155), checkBg=Color3.fromRGB(38,28,60), checkOn=Color3.fromRGB(180,100,255), track=Color3.fromRGB(42,32,66), fill=Color3.fromRGB(180,100,255), btnBg=Color3.fromRGB(32,22,56), btnHover=Color3.fromRGB(44,32,72), dropBg=Color3.fromRGB(26,19,48), border=Color3.fromRGB(54,38,86) },
  Neon = { bg=Color3.fromRGB(10,14,12), sidebar=Color3.fromRGB(8,10,9), card=Color3.fromRGB(18,24,20), tabActive=Color3.fromRGB(28,38,30), tabInactive=Color3.fromRGB(8,10,9), accent=Color3.fromRGB(0,255,170), accent2=Color3.fromRGB(150,255,220), text=Color3.fromRGB(235,255,245), textDim=Color3.fromRGB(120,160,140), checkBg=Color3.fromRGB(32,44,38), checkOn=Color3.fromRGB(0,255,170), track=Color3.fromRGB(36,50,42), fill=Color3.fromRGB(0,255,170), btnBg=Color3.fromRGB(26,36,30), btnHover=Color3.fromRGB(38,50,42), dropBg=Color3.fromRGB(20,28,24), border=Color3.fromRGB(44,60,52) },
  Midnight = { bg=Color3.fromRGB(12,14,22), sidebar=Color3.fromRGB(9,11,18), card=Color3.fromRGB(20,24,36), tabActive=Color3.fromRGB(30,36,54), tabInactive=Color3.fromRGB(9,11,18), accent=Color3.fromRGB(255,70,120), accent2=Color3.fromRGB(255,140,170), text=Color3.fromRGB(240,240,250), textDim=Color3.fromRGB(130,135,160), checkBg=Color3.fromRGB(36,40,58), checkOn=Color3.fromRGB(255,70,120), track=Color3.fromRGB(40,46,64), fill=Color3.fromRGB(255,70,120), btnBg=Color3.fromRGB(28,32,50), btnHover=Color3.fromRGB(40,46,66), dropBg=Color3.fromRGB(22,26,40), border=Color3.fromRGB(48,54,76) },
}
local function getTheme() return Themes[currentTheme] or Themes.Dark end
-- ============ LANGUAGE ============
local currentLang = "VI"
local Langs = {}
Langs.EN = { Home="Home", Visual="Visual", Combat="Combat", Movement="Movement", Utility="Utility", Server="Server", Fun="Fun", Settings="Settings", ScriptName="Script Name", Version="Version", Username="Username", Executor="Executor", Credits="Credits", Changelog="Changelog", ESP="ESP", BoxESP="Box ESP", NameESP="Name ESP", HealthESP="Health ESP", DistanceESP="Distance ESP", Tracers="Tracer Lines", Chams="Chams", FullBright="Full Bright", NightVision="Night Vision", Xray="X-Ray", Aim="Aimbot", SilentAim="Silent Aim", AimFOV="Aim FOV Circle", AimPrediction="Aim Prediction", TriggerBot="Trigger Bot", HitboxExpander="Hitbox Expander", AimFOVValue="Aim FOV", AimSmoothness="Aim Smoothness", HitboxSize="Hitbox Size", Speed="Speed Hack", Fly="Fly", Noclip="Noclip", JumpPower="Jump Power", InfiniteJump="Infinite Jump", Teleport="Teleport to Cursor", ClickTeleport="Click Teleport", Sprint="Sprint", AntiVoid="Anti Void", SpeedValue="Speed", FlySpeed="Fly Speed", JumpPowerValue="Jump Power", SprintSpeed="Sprint Speed", AntiAFK="Anti AFK", FreezeTime="Freeze Time", FPSBoost="FPS Booster", AntiBlind="Anti Blind", AntiSlow="Anti Slow", AntiRagdoll="Anti Ragdoll", AntiGrab="Anti Grab", RejoinServer="Rejoin Server", ServerHop="Server Hop", JoinSmallServer="Join Small Server", PlayerList="Player List", SpectatePlayer="Spectate Player", Spin="Spin", Float="Float", Bang="Bang", Fling="Fling", OrbitPlayer="Orbit Player", Invisible="Invisible", LowGravity="Low Gravity", LowGravityValue="Gravity Level", Freecam="Freecam", Respawn="Respawn", TeleportToSpawn="Teleport to Spawn", SpinSpeed="Spin Speed", OrbitRadius="Orbit Radius", OrbitSpeed="Orbit Speed", FlingPower="Fling Power", Theme="Theme", Language="Language", GUI="GUI Settings", SaveSettings="Save Settings", AutoLoadSettings="Auto Load", ResetSettings="Reset All", MinimizeButton="Minimize Button", DraggableGUI="Draggable GUI", ToggleKeybind="Toggle Keybind", Notifications="Notifications", Dark="Dark", Light="Light", SkyBlue="Sky Blue", Galaxy="Galaxy", English="English", Vietnamese="Tieng Viet", Spanish="Espanol", Portuguese="Portugues", Russian="Russkiy", Enabled="Enabled", Disabled="Disabled", Loaded="loaded! 3-finger tap to open", KeySystem="Key System", EnterKey="Enter Key", SubmitKey="Submit", KeyStatus="Key Status", KeyRequired="Key required", KeyAccepted="Key accepted!", KeyWrong="Wrong key!", FieldOfView="Field of View", PlayersOnline="Players Online", StopSpectate="Stop Spectate", OrbitActive="Orbit Active", FOVCircle="FOV Circle", Search="Search features...", QuickToggles="Quick Toggles", Favorites="Favorites", Gesture="Gesture (3 fingers)", GestureMode="Gesture Mode", GestureTest="Test gesture", GestureOn="Gesture ON", GestureOff="Gesture OFF", Panic="PANIC - Turn off all", Unload="Unload Menu", CheckUpdate="Check Update", UpdateAvailable="Update available!", UpToDate="Up to date", CopyID="Copy UserId", QuickBar="Quick Bar", ShowFPS="Show FPS", ShowPing="Show Ping", Haptic="Vibration", FlyJoystick="Fly Joystick", RefreshPlayers="Refresh Players", Tap1="1 tap (3 fingers)", Tap3="3 taps (3 fingers)", Hold="Hold 3 fingers 0.5s", Swipe="Swipe down 3 fingers", GestureHint="3-finger: tap to open / close", GestureDetected="3 fingers detected!", AllOff="All features OFF", SavedCloud="Saved to cloud", SavedLocal="Saved locally", }
Langs.VI = { Home="Trang Chu", Visual="Hinh Anh", Combat="Chien Dau", Movement="Di Chuyen", Utility="Tien Ich", Server="May Chu", Fun="Giai Tri", Settings="Cai Dat", ScriptName="Ten Script", Version="Phien Ban", Username="Nguoi Dung", Executor="Trinh Thuc Thi", Credits="Tac Gia", Changelog="Nhat Ky", ESP="ESP", BoxESP="Hop ESP", NameESP="Ten ESP", HealthESP="Mau ESP", DistanceESP="Khoang Cach ESP", Tracers="Duong Ke ESP", Chams="Chams", FullBright="Sang Toan Bo", NightVision="Nhin Dem", Xray="X-Ray", Aim="Aimbot", SilentAim="Ngam Am", AimFOV="Vong Ngam", AimPrediction="Du Doan", TriggerBot="Bot Ban", HitboxExpander="Mo Rong Hitbox", AimFOVValue="Vong Ngam", AimSmoothness="Do Muot", HitboxSize="Co Hitbox", Speed="Tang Toc", Fly="Bay", Noclip="Xuyen Tuong", JumpPower="Luc Nhay", InfiniteJump="Nhay Vo Han", Teleport="Dich Den Con Tro", ClickTeleport="Click Dich Chuyen", Sprint="Chay Nhanh", AntiVoid="Chong Rot", SpeedValue="Toc Do", FlySpeed="Toc Do Bay", JumpPowerValue="Luc Nhay", SprintSpeed="Toc Do Chay", AntiAFK="Chong AFK", FreezeTime="Dong Thoi Gian", FPSBoost="Tang FPS", AntiBlind="Chong Mu", AntiSlow="Chong Cham", AntiRagdoll="Chong Nga", AntiGrab="Chong Keo", RejoinServer="Vao Lai Server", ServerHop="Doi Server", JoinSmallServer="Server It Nguoi", PlayerList="Danh Sach", SpectatePlayer="Theo Doi", Spin="Xoay", Float="Bay Lang", Bang="Nhun", Fling="Nem", OrbitPlayer="Quay Quanh", Invisible="Vo Hinh", LowGravity="Trong Luc Thap", LowGravityValue="Muc Trong Luc", Freecam="Cam Tu Do", Respawn="Hoi Sinh", TeleportToSpawn="Ve Diem Hoi Sinh", SpinSpeed="Toc Do Xoay", OrbitRadius="Ban Kinh Quay", OrbitSpeed="Toc Do Quay", FlingPower="Luc Nem", Theme="Giao Dien", Language="Ngon Ngu", GUI="Cai Dat GUI", SaveSettings="Luu Cai Dat", AutoLoadSettings="Tu Dong Tai", ResetSettings="Dat Lai Tat Ca", MinimizeButton="Nut Thu Nho", DraggableGUI="Keo Duoc Menu", ToggleKeybind="Phim Tat", Notifications="Thong Bao", Dark="Toi", Light="Sang", SkyBlue="Xanh Troi", Galaxy="Thien Ha", English="English", Vietnamese="Tieng Viet", Spanish="Espanol", Portuguese="Portugues", Russian="Russkiy", Enabled="Bat", Disabled="Tat", Loaded="da tai! Cham 3 ngon de mo menu", KeySystem="He Thong Key", EnterKey="Nhap Key", SubmitKey="Xac Nhan", KeyStatus="Trang Thai Key", KeyRequired="Can key de dung", KeyAccepted="Key dung! Da mo khoa", KeyWrong="Key sai! Thu lai", FieldOfView="Goc Nhin", PlayersOnline="Nguoi Choi", StopSpectate="Dung Theo Doi", OrbitActive="Dang Quay", FOVCircle="Vong FOV", Search="Tim tinh nang...", QuickToggles="Bat Nhanh", Favorites="Yeu Thich", Gesture="Cu Chi 3 Ngon", GestureMode="Kieu Cham 3 Ngon", GestureTest="Test cham 3 ngon", GestureOn="Da bat cu chi", GestureOff="Da tat cu chi", Panic="PANIC - Tat het", Unload="Go Menu", CheckUpdate="Kiem Tra Update", UpdateAvailable="Co ban moi!", UpToDate="Da la ban moi nhat", CopyID="Copy UserId", QuickBar="Thanh Nhanh", ShowFPS="Hien FPS", ShowPing="Hien Ping", Haptic="Rung", FlyJoystick="Joystick Bay", RefreshPlayers="Lam Moi Nguoi Choi", Tap1="Cham 1 lan (3 ngon)", Tap3="Cham 3 lan (3 ngon)", Hold="Giu 3 ngon 0.5s", Swipe="Vuot xuong 3 ngon", GestureHint="Cham 3 ngon: mo / dong menu", GestureDetected="Da nhan 3 ngon!", AllOff="Da tat het tinh nang", SavedCloud="Da luu len cloud", SavedLocal="Da luu may", }
Langs.ES = { Home="Inicio", Visual="Visual", Combat="Combate", Movement="Movimiento", Utility="Utilidad", Server="Servidor", Fun="Diversion", Settings="Ajustes", ESP="ESP", Aim="Aimbot", Fly="Volar", Speed="Velocidad", Theme="Tema", Language="Idioma", KeySystem="Sistema Key", Search="Buscar...", QuickToggles="Rapido", Gesture="Gesto 3 dedos", Panic="PANIC - Apagar todo", CheckUpdate="Buscar update", }
Langs.PT = { Home="Inicio", Visual="Visual", Combat="Combate", Movement="Movimento", Utility="Utilidade", Server="Servidor", Fun="Diversao", Settings="Config", ESP="ESP", Aim="Aimbot", Fly="Voar", Speed="Velocidade", Theme="Tema", Language="Idioma", KeySystem="Sistema Key", Search="Buscar...", QuickToggles="Rapido", Gesture="Gesto 3 dedos", Panic="PANIC - Desligar tudo", CheckUpdate="Buscar update", }
Langs.RU = { Home="Glavnaya", Visual="Vizual", Combat="Boi", Movement="Dvizhenie", Utility="Utilita", Server="Server", Fun="Razvlechenie", Settings="Nastroyki", ESP="ESP", Aim="Aimbot", Fly="Polet", Speed="Skorost", Theme="Tema", Language="Yazik", KeySystem="Sistema Key", Search="Poisk...", QuickToggles="Bistro", Gesture="Zhest 3 palca", Panic="PANIC - Vse viklyuchit", CheckUpdate="Proverit update", }
local function T(k) local l = Langs[currentLang] or Langs.EN return l[k] or (Langs.EN[k] or k) end
local allUILabels = {}
local allUIThemed = {}
local function trackLabel(o,k) table.insert(allUILabels, {obj=o, key=k}) end
local function trackThemed(o,p,k) table.insert(allUIThemed, {obj=o, prop=p, themeKey=k}) end
-- ============ NOTIFY (stacked, khong de chong) ============
local notifStack = {}
local function notify(title, content, duration)
  duration = duration or 3
  if not States.Notifications then return end
  _spawn(function() pcall(function()
    local theme = getTheme()
    local g = playerGui:FindFirstChild("FLUYEN_Noti_Gui")
    if not g then g = Instance.new("ScreenGui") g.Name = "FLUYEN_Noti_Gui" g.ResetOnSpawn = false g.IgnoreGuiInset = true g.DisplayOrder = 200 g.Parent = playerGui end
    local idx = #notifStack + 1
    local fr = Instance.new("Frame") fr.Name = "Notif" fr.Size = UDim2.new(0, 280, 0, 62) fr.Position = UDim2.new(1, 300, 0, 10 + (idx-1)*72) fr.BackgroundColor3 = theme.card fr.BorderSizePixel = 0 fr.ZIndex = 200 fr.Parent = g
    Instance.new("UICorner", fr).CornerRadius = UDim.new(0, 12)
    local st = Instance.new("UIStroke") st.Color = theme.border st.Thickness = 1 st.Parent = fr
    local bar = Instance.new("Frame") bar.Size = UDim2.new(0, 4, 1, 0) bar.BackgroundColor3 = theme.accent bar.BorderSizePixel = 0 bar.ZIndex = 201 bar.Parent = fr
    Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 2)
    local t1 = Instance.new("TextLabel") t1.Size = UDim2.new(1, -18, 0, 22) t1.Position = UDim2.new(0, 14, 0, 6) t1.BackgroundTransparency = 1 t1.Text = tostring(title) t1.TextColor3 = theme.text t1.Font = Enum.Font.GothamBold t1.TextSize = 13 t1.TextXAlignment = Enum.TextXAlignment.Left t1.ZIndex = 201 t1.Parent = fr
    local t2 = Instance.new("TextLabel") t2.Size = UDim2.new(1, -18, 0, 26) t2.Position = UDim2.new(0, 14, 0, 30) t2.BackgroundTransparency = 1 t2.Text = tostring(content) t2.TextColor3 = theme.textDim t2.Font = Enum.Font.Gotham t2.TextSize = 11 t2.TextXAlignment = Enum.TextXAlignment.Left t2.TextWrapped = true t2.ZIndex = 201 t2.Parent = fr
    table.insert(notifStack, fr)
    TweenService:Create(fr, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(1, -296, 0, 10 + (idx-1)*72)}):Play()
    _wait(duration)
    TweenService:Create(fr, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = UDim2.new(1, 300, 0, fr.Position.Y.Offset)}):Play()
    _wait(0.35) pcall(function() fr:Destroy() end)
    for i, v in ipairs(notifStack) do if v == fr then table.remove(notifStack, i) break end end
    for i, v in ipairs(notifStack) do pcall(function() TweenService:Create(v, TweenInfo.new(0.25), {Position = UDim2.new(1, -296, 0, 10 + (i-1)*72)}):Play() end) end
  end) end)
end
-- ============ SUPABASE ============
local function httpReq(method, path, bodyTable)
  local url = SUPABASE_URL .. path
  local body = bodyTable and HttpService:JSONEncode(bodyTable) or nil
  local headers = { ["apikey"] = SUPABASE_KEY, ["Authorization"] = "Bearer " .. SUPABASE_KEY, ["Content-Type"] = "application/json", ["Prefer"] = "return=representation, resolution=merge-duplicates" }
  local reqFn = (typeof(http_request) == "function" and http_request) or (typeof(request) == "function" and request) or (typeof(syn) == "table" and syn.request) or nil
  if reqFn then
    local ok, res = pcall(function() return reqFn({ Url = url, Method = method, Headers = headers, Body = body }) end)
    if ok and res then
      local txt = res.Body or res.body or ""
      if type(txt) == "table" then txt = HttpService:JSONEncode(txt) end
      return true, tostring(txt), res.StatusCode or res.statusCode or 200
    end
    return false, "request failed", 0
  end
  local ok, res = pcall(function() return HttpService:RequestAsync({ Url = url, Method = method, Headers = headers, Body = body }) end)
  if ok and res and res.Success then return true, res.Body or "", res.StatusCode or 200 end
  return false, (res and res.Body) or "no http", 0
end
local function supaCheckKey(key)
  if key == LOCAL_KEY then return true, "local" end
  local ok, txt = httpReq("GET", "/rest/v1/fluyen_keys?key=eq." .. HttpService:UrlEncode(key) .. "&select=key,is_active,expires_at")
  if not ok then return false, "offline" end
  local ok2, arr = pcall(function() return HttpService:JSONDecode(txt) end)
  if ok2 and type(arr) == "table" and #arr > 0 then
    local row = arr[1]
    if row.is_active == false then return false, "inactive" end
    if row.expires_at and row.expires_at ~= "" then
      -- het han thi van cho dung neu khong parse duoc (tranh khoa nham), chi log
    end
    return true, "supabase"
  end
  return false, "not_found"
end
local function supaFetchVersion()
  local ok, txt = httpReq("GET", "/rest/v1/fluyen_versions?is_latest=eq.true&order=created_at.desc&limit=1&select=version,changelog,lua_url")
  if not ok then return nil end
  local ok2, arr = pcall(function() return HttpService:JSONDecode(txt) end)
  if ok2 and type(arr) == "table" and #arr > 0 then return arr[1] end
  return nil
end
local function supaSaveSettings()
  if not keyAuthenticated then return false end
  local data = { theme = currentTheme, language = currentLang, states = States, values = Values, gestureMode = Values.GestureMode }
  local payload = { user_id = tostring(player.UserId), username = player.Name, settings = data }
  local ok, _ = httpReq("POST", "/rest/v1/fluyen_settings?on_conflict=user_id", payload)
  -- PostgREST upsert can can Prefer merge-duplicates, neu POST loi thi thu PATCH
  if not ok then httpReq("PATCH", "/rest/v1/fluyen_settings?user_id=eq." .. tostring(player.UserId), { username = player.Name, settings = data }) end
  return ok
end
local function supaLoadSettings()
  local ok, txt = httpReq("GET", "/rest/v1/fluyen_settings?user_id=eq." .. tostring(player.UserId) .. "&select=settings&limit=1")
  if not ok then return nil end
  local ok2, arr = pcall(function() return HttpService:JSONDecode(txt) end)
  if ok2 and type(arr) == "table" and #arr > 0 and arr[1].settings then return arr[1].settings end
  return nil
end
local function applySettingsTable(s)
  if type(s) ~= "table" then return end
  if s.theme and Themes[s.theme] then currentTheme = s.theme end
  if s.language and Langs[s.language] then currentLang = s.language end
  if s.gestureMode then Values.GestureMode = s.gestureMode end
  if type(s.values) == "table" then for k, v in pairs(s.values) do Values[k] = v end end
  if type(s.states) == "table" then for k, v in pairs(s.states) do if States[k] ~= nil then States[k] = v end end end
end
-- ============ OVERLAY GUI ============
local espGui = Instance.new("ScreenGui") espGui.Name = "FLUYEN_ESP_Overlay" espGui.ResetOnSpawn = false espGui.IgnoreGuiInset = true espGui.DisplayOrder = 99 espGui.Parent = playerGui
local fovCircle = Instance.new("Frame") fovCircle.Name = "FOVCircle" fovCircle.Size = UDim2.new(0, Values.AimFOVValue*2, 0, Values.AimFOVValue*2) fovCircle.Position = UDim2.new(0.5, -Values.AimFOVValue, 0.5, -Values.AimFOVValue) fovCircle.BackgroundTransparency = 1 fovCircle.BorderSizePixel = 0 fovCircle.Visible = false fovCircle.ZIndex = 50 fovCircle.Parent = espGui
Instance.new("UICorner", fovCircle).CornerRadius = UDim.new(1, 0)
local fovStroke = Instance.new("UIStroke") fovStroke.Color = getTheme().accent fovStroke.Thickness = 1.5 fovStroke.Transparency = 0.3 fovStroke.Parent = fovCircle
local playerCountLabel = Instance.new("TextLabel") playerCountLabel.Name = "PlayerCount" playerCountLabel.Size = UDim2.new(0, 150, 0, 24) playerCountLabel.Position = UDim2.new(0, 10, 0, 10) playerCountLabel.BackgroundColor3 = Color3.fromRGB(0,0,0) playerCountLabel.BackgroundTransparency = 0.45 playerCountLabel.Text = "Players: 0" playerCountLabel.TextColor3 = Color3.fromRGB(255,255,255) playerCountLabel.Font = Enum.Font.GothamBold playerCountLabel.TextSize = 12 playerCountLabel.ZIndex = 50 playerCountLabel.Parent = espGui
Instance.new("UICorner", playerCountLabel).CornerRadius = UDim.new(0, 8)
local fpsLabel = Instance.new("TextLabel") fpsLabel.Name = "FPS" fpsLabel.Size = UDim2.new(0, 90, 0, 24) fpsLabel.Position = UDim2.new(0, 10, 0, 38) fpsLabel.BackgroundColor3 = Color3.fromRGB(0,0,0) fpsLabel.BackgroundTransparency = 0.45 fpsLabel.Text = "FPS: 60" fpsLabel.TextColor3 = Color3.fromRGB(0,255,100) fpsLabel.Font = Enum.Font.GothamBold fpsLabel.TextSize = 11 fpsLabel.ZIndex = 50 fpsLabel.Parent = espGui
Instance.new("UICorner", fpsLabel).CornerRadius = UDim.new(0, 8)
local pingLabel = Instance.new("TextLabel") pingLabel.Name = "Ping" pingLabel.Size = UDim2.new(0, 90, 0, 24) pingLabel.Position = UDim2.new(0, 10, 0, 66) pingLabel.BackgroundColor3 = Color3.fromRGB(0,0,0) pingLabel.BackgroundTransparency = 0.45 pingLabel.Text = "Ping: --" pingLabel.TextColor3 = Color3.fromRGB(255,255,255) pingLabel.Font = Enum.Font.GothamBold pingLabel.TextSize = 11 pingLabel.ZIndex = 50 pingLabel.Parent = espGui
Instance.new("UICorner", pingLabel).CornerRadius = UDim.new(0, 8)
local tracerContainer = Instance.new("Frame") tracerContainer.Name = "Tracers" tracerContainer.Size = UDim2.new(1,0,1,0) tracerContainer.BackgroundTransparency = 1 tracerContainer.ZIndex = 48 tracerContainer.Parent = espGui
local tracerDot = Instance.new("Frame") tracerDot.Name = "TracerDot" tracerDot.Size = UDim2.new(0, 8, 0, 8) tracerDot.Position = UDim2.new(0.5, -4, 0, -2) tracerDot.BackgroundColor3 = getTheme().accent tracerDot.BorderSizePixel = 0 tracerDot.BackgroundTransparency = 0.2 tracerDot.ZIndex = 50 tracerDot.Visible = false tracerDot.Parent = espGui
Instance.new("UICorner", tracerDot).CornerRadius = UDim.new(0, 4)
local keyStatusLabel = Instance.new("TextLabel") keyStatusLabel.Name = "KeyStatus" keyStatusLabel.Size = UDim2.new(0, 230, 0, 26) keyStatusLabel.Position = UDim2.new(0.5, -115, 1, -36) keyStatusLabel.BackgroundColor3 = Color3.fromRGB(200,50,50) keyStatusLabel.BackgroundTransparency = 0.25 keyStatusLabel.Text = "KEY REQUIRED - Nhap key o Settings" keyStatusLabel.TextColor3 = Color3.fromRGB(255,255,255) keyStatusLabel.Font = Enum.Font.GothamBold keyStatusLabel.TextSize = 11 keyStatusLabel.ZIndex = 100 keyStatusLabel.Visible = not keyAuthenticated keyStatusLabel.Parent = espGui
Instance.new("UICorner", keyStatusLabel).CornerRadius = UDim.new(0, 8)
-- Gesture hint (hien so ngon dang cham + trang thai)
local gestureHint = Instance.new("TextLabel") gestureHint.Name = "GestureHint" gestureHint.Size = UDim2.new(0, 220, 0, 28) gestureHint.Position = UDim2.new(0.5, -110, 0, 10) gestureHint.BackgroundColor3 = Color3.fromRGB(0,0,0) gestureHint.BackgroundTransparency = 0.35 gestureHint.Text = "👆 " .. T("GestureHint") gestureHint.TextColor3 = Color3.fromRGB(255,255,255) gestureHint.Font = Enum.Font.GothamBold gestureHint.TextSize = 11 gestureHint.ZIndex = 100 gestureHint.Visible = false gestureHint.Parent = espGui
Instance.new("UICorner", gestureHint).CornerRadius = UDim.new(0, 14)
-- ============ MAIN GUI (responsive) ============
local screenGui = Instance.new("ScreenGui") screenGui.Name = "FLUYEN_Menu_v6" screenGui.ResetOnSpawn = false screenGui.IgnoreGuiInset = true screenGui.DisplayOrder = 100 screenGui.Parent = playerGui
local backdrop = Instance.new("Frame") backdrop.Size = UDim2.new(1,0,1,0) backdrop.BackgroundColor3 = Color3.fromRGB(0,0,0) backdrop.BackgroundTransparency = 1 backdrop.BorderSizePixel = 0 backdrop.Visible = false backdrop.ZIndex = 1 backdrop.Parent = screenGui
local backdropClose = Instance.new("TextButton") backdropClose.Size = UDim2.new(1,0,1,0) backdropClose.BackgroundTransparency = 1 backdropClose.Text = "" backdropClose.ZIndex = 1 backdropClose.Parent = backdrop
local mainFrame = Instance.new("Frame") mainFrame.Size = UDim2.new(0, 560, 0, 440) mainFrame.AnchorPoint = Vector2.new(0.5,0.5) mainFrame.Position = UDim2.new(0.5,0,0.5,0) mainFrame.BackgroundColor3 = getTheme().bg mainFrame.BackgroundTransparency = 1 - Values.MenuOpacity mainFrame.BorderSizePixel = 0 mainFrame.Visible = false mainFrame.ZIndex = 2 mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 16)
local mainStroke = Instance.new("UIStroke") mainStroke.Color = getTheme().border mainStroke.Thickness = 1 mainStroke.Transparency = 0.4 mainStroke.Parent = mainFrame
local mainShadow = Instance.new("Frame") mainShadow.Size = UDim2.new(1,0,1,0) mainShadow.BackgroundTransparency = 1 mainShadow.ZIndex = 1 mainShadow.Parent = mainFrame
local uiScale = Instance.new("UIScale") uiScale.Scale = 1 uiScale.Parent = mainFrame
local titleBar = Instance.new("Frame") titleBar.Size = UDim2.new(1,0,0,56) titleBar.BackgroundTransparency = 1 titleBar.BorderSizePixel = 0 titleBar.ZIndex = 10 titleBar.Parent = mainFrame
local titleGradient = Instance.new("UIGradient") titleGradient.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, getTheme().accent), ColorSequenceKeypoint.new(1, getTheme().accent2) }) titleGradient.Parent = titleBar
local titleLabel = Instance.new("TextLabel") titleLabel.Size = UDim2.new(1,-110,0,26) titleLabel.Position = UDim2.new(0,14,0,4) titleLabel.BackgroundTransparency = 1 titleLabel.Text = "FLUYEN  " .. SCRIPT_VERSION .. "  •  PREMIUM" titleLabel.TextColor3 = getTheme().accent titleLabel.Font = Enum.Font.GothamBold titleLabel.TextSize = 15 titleLabel.TextXAlignment = Enum.TextXAlignment.Left titleLabel.ZIndex = 11 titleLabel.Parent = titleBar
trackThemed(titleLabel, "TextColor3", "accent")
local subLabel = Instance.new("TextLabel") subLabel.Size = UDim2.new(1,-110,0,16) subLabel.Position = UDim2.new(0,14,0,28) subLabel.BackgroundTransparency = 1 subLabel.Text = player.Name .. "  •  Delta  •  Cham 3 ngon de mo / dong" subLabel.TextColor3 = getTheme().textDim subLabel.Font = Enum.Font.Gotham subLabel.TextSize = 10 subLabel.TextXAlignment = Enum.TextXAlignment.Left subLabel.ZIndex = 11 subLabel.Parent = titleBar
trackThemed(subLabel, "TextColor3", "textDim")
local closeBtn = Instance.new("TextButton") closeBtn.Size = UDim2.new(0,36,0,36) closeBtn.Position = UDim2.new(1,-42,0,8) closeBtn.BackgroundColor3 = getTheme().card closeBtn.Text = "✕" closeBtn.TextColor3 = getTheme().text closeBtn.Font = Enum.Font.GothamBold closeBtn.TextSize = 14 closeBtn.ZIndex = 11 closeBtn.Parent = titleBar
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 10)
trackThemed(closeBtn, "BackgroundColor3", "card")
local searchBox = Instance.new("TextBox") searchBox.Size = UDim2.new(1,-24,0,30) searchBox.Position = UDim2.new(0,12,0,56) searchBox.BackgroundColor3 = getTheme().card searchBox.BorderSizePixel = 0 searchBox.PlaceholderText = T("Search") searchBox.Text = "" searchBox.TextColor3 = getTheme().text searchBox.PlaceholderColor3 = getTheme().textDim searchBox.Font = Enum.Font.Gotham searchBox.TextSize = 12 searchBox.ClearTextOnFocus = false searchBox.ZIndex = 11 searchBox.Parent = mainFrame
Instance.new("UICorner", searchBox).CornerRadius = UDim.new(0, 10)
trackThemed(searchBox, "BackgroundColor3", "card")
local SIDEBAR_W = 118
local sidebar = Instance.new("Frame") sidebar.Size = UDim2.new(0, SIDEBAR_W, 1, -96) sidebar.Position = UDim2.new(0, 6, 0, 92) sidebar.BackgroundColor3 = getTheme().sidebar sidebar.BorderSizePixel = 0 sidebar.ZIndex = 5 sidebar.Parent = mainFrame
trackThemed(sidebar, "BackgroundColor3", "sidebar")
Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0, 12)
local sidebarLayout = Instance.new("UIListLayout") sidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder sidebarLayout.Padding = UDim.new(0, 4) sidebarLayout.Parent = sidebar
local sidebarPad = Instance.new("UIPadding") sidebarPad.PaddingTop = UDim.new(0, 6) sidebarPad.PaddingLeft = UDim.new(0, 6) sidebarPad.PaddingRight = UDim.new(0, 6) sidebarPad.PaddingBottom = UDim.new(0, 6) sidebarPad.Parent = sidebar
local contentArea = Instance.new("Frame") contentArea.Size = UDim2.new(1, -SIDEBAR_W - 18, 1, -96) contentArea.Position = UDim2.new(0, SIDEBAR_W + 12, 0, 92) contentArea.BackgroundTransparency = 1 contentArea.ClipsDescendants = true contentArea.ZIndex = 5 contentArea.Parent = mainFrame
local function layoutMenu()
  local vs = camera.ViewportSize
  local w, h = vs.X, vs.Y
  local mw, mh, sbw
  if w < 640 then mw = math.floor(w * 0.94) mh = math.floor(h * 0.84) sbw = 92
  elseif w < 900 then mw = math.floor(w * 0.82) mh = math.floor(h * 0.82) sbw = 104
  else mw = 580 mh = 460 sbw = 118 end
  SIDEBAR_W = sbw
  mainFrame.Size = UDim2.new(0, mw, 0, mh)
  sidebar.Size = UDim2.new(0, sbw, 1, -96) sidebar.Position = UDim2.new(0, 6, 0, 92)
  contentArea.Size = UDim2.new(1, -sbw - 18, 1, -96) contentArea.Position = UDim2.new(0, sbw + 12, 0, 92)
end
layoutMenu()
camera:GetPropertyChangedSignal("ViewportSize"):Connect(function() pcall(layoutMenu) end)
-- Draggable helper (keo bang touch + chuot, gioi han trong man hinh)
local function makeDraggable(frame, handle)
  handle = handle or frame
  local dragging, dragInput, dragStart, startPos = false, nil, nil, nil
  handle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
      dragging = true dragStart = input.Position startPos = frame.Position
      input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
    end
  end)
  handle.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
  end)
  UserInputService.InputChanged:Connect(function(input)
    if dragging and input == dragInput then
      local delta = input.Position - dragStart
      if delta.Magnitude > 12 then pcall(function() frame:SetAttribute("FLUYEN_Dragged", tick()) end) end
      local nx = startPos.X.Offset + delta.X
      local ny = startPos.Y.Offset + delta.Y
      local vs = camera.ViewportSize
      local sz = frame.AbsoluteSize
      nx = clamp(nx, -sz.X * 0.5 + 40, vs.X - 40 - sz.X * 0.5)
      ny = clamp(ny, -sz.Y * 0.5 + 20, vs.Y - 20 - sz.Y * 0.5)
      frame.Position = UDim2.new(startPos.X.Scale, nx, startPos.Y.Scale, ny)
    end
  end)
  UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
  end)
end
makeDraggable(mainFrame, titleBar)
-- Mini button (F) - keo duoc, bam de mo menu
local miniBtn = Instance.new("TextButton") miniBtn.Size = UDim2.new(0, 52, 0, 52) miniBtn.Position = UDim2.new(0, 12, 0.5, -26) miniBtn.BackgroundColor3 = getTheme().accent miniBtn.Text = "F" miniBtn.TextColor3 = Color3.fromRGB(255,255,255) miniBtn.Font = Enum.Font.GothamBold miniBtn.TextSize = 20 miniBtn.ZIndex = 120 miniBtn.Visible = false miniBtn.Parent = screenGui
Instance.new("UICorner", miniBtn).CornerRadius = UDim.new(0, 26)
trackThemed(miniBtn, "BackgroundColor3", "accent")
local miniDot = Instance.new("Frame") miniDot.Size = UDim2.new(0, 12, 0, 12) miniDot.Position = UDim2.new(1, -14, 0, 2) miniDot.BackgroundColor3 = Color3.fromRGB(0,255,100) miniDot.BorderSizePixel = 0 miniDot.Visible = false miniDot.ZIndex = 121 miniDot.Parent = miniBtn
Instance.new("UICorner", miniDot).CornerRadius = UDim.new(0, 6)
makeDraggable(miniBtn, miniBtn)
-- ============ FEATURE SETTER (1 cho duy nhat) ============
local ToggleUIs = {}
local function refreshToggleUI(key)
  local u = ToggleUIs[key] if not u then return end
  local on = States[key] == true
  local theme = getTheme()
  pcall(function()
    u.pill.BackgroundColor3 = on and theme.checkOn or theme.checkBg
    TweenService:Create(u.knob, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = on and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10) }):Play()
    u.knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
  end)
end
local function refreshAllToggles() for k, _ in pairs(ToggleUIs) do refreshToggleUI(k) end end
local function setFeature(key, value, fromUI)
  if States[key] == nil then return end
  local noKey = { QuickBar=true, GestureEnabled=true, Notifications=true, MinimizeButton=true, DraggableGUI=true, AutoLoadSettings=true, ShowFPS=true, ShowPing=true, ShowPlayers=true, Haptic=true }
  if not keyAuthenticated and not noKey[key] then notify(T("KeySystem"), T("KeyRequired"), 2) return end
  States[key] = value
  refreshToggleUI(key)
  local cb = FeatureCB[key]
  if cb then pcall(function() cb(value) end) end
  -- dot tren nut F: sang neu co tinh nang dang bat
  local anyOn = false
  for _, k in ipairs({"ESP","Aim","Fly","Speed","Noclip","Invisible","Spin"}) do if States[k] then anyOn = true break end end
  miniDot.Visible = anyOn
  if quickBarButtons then for _, b in pairs(quickBarButtons) do pcall(function() b:update() end) end end
end
-- QuickBar (thanh nhanh ben phai, bat/tat khong can mo menu)
local quickBar = Instance.new("Frame") quickBar.Name = "QuickBar" quickBar.Size = UDim2.new(0, 48, 0, 210) quickBar.Position = UDim2.new(1, -58, 0.5, -105) quickBar.BackgroundColor3 = getTheme().card quickBar.BackgroundTransparency = 0.12 quickBar.BorderSizePixel = 0 quickBar.ZIndex = 110 quickBar.Visible = States.QuickBar quickBar.Parent = screenGui
Instance.new("UICorner", quickBar).CornerRadius = UDim.new(0, 24)
local quickBarLayout = Instance.new("UIListLayout") quickBarLayout.SortOrder = Enum.SortOrder.LayoutOrder quickBarLayout.Padding = UDim.new(0, 6) quickBarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center quickBarLayout.VerticalAlignment = Enum.VerticalAlignment.Center quickBarLayout.Parent = quickBar
quickBarButtons = {}
local function makeQuickBtn(key, emoji)
  local b = Instance.new("TextButton") b.Size = UDim2.new(0, 36, 0, 36) b.BackgroundColor3 = getTheme().card b.Text = emoji b.TextColor3 = getTheme().text b.Font = Enum.Font.GothamBold b.TextSize = 16 b.ZIndex = 111 b.Parent = quickBar
  Instance.new("UICorner", b).CornerRadius = UDim.new(0, 18)
  local rec = {}
  function rec:update() local on = States[key] == true local th = getTheme() b.BackgroundColor3 = on and th.accent or th.card b.TextColor3 = on and Color3.fromRGB(255,255,255) or th.text end
  b.MouseButton1Click:Connect(function() setFeature(key, not States[key]) rec:update() end)
  rec:update() quickBarButtons[key] = rec return rec
end
makeQuickBtn("ESP", "👁") makeQuickBtn("Fly", "🕊") makeQuickBtn("Speed", "⚡") makeQuickBtn("Aim", "🎯")
local panicBtn = Instance.new("TextButton") panicBtn.Size = UDim2.new(0, 36, 0, 36) panicBtn.BackgroundColor3 = Color3.fromRGB(220,40,60) panicBtn.Text = "🚨" panicBtn.Font = Enum.Font.GothamBold panicBtn.TextSize = 16 panicBtn.ZIndex = 111 panicBtn.Parent = quickBar
Instance.new("UICorner", panicBtn).CornerRadius = UDim.new(0, 18)
panicBtn.MouseButton1Click:Connect(function()
  for k, v in pairs(States) do if type(v) == "boolean" and k ~= "AntiAFK" and k ~= "MinimizeButton" and k ~= "DraggableGUI" and k ~= "Notifications" and k ~= "QuickBar" and k ~= "GestureEnabled" and k ~= "AutoLoadSettings" then if v == true then setFeature(k, false) end end end
  refreshAllToggles() notify("PANIC", T("AllOff"), 2)
end)
makeDraggable(quickBar, quickBar)
-- ============ TABS / PAGES ============
local TabDefs = {
  {name="Home", icon="🏠", order=1}, {name="Visual", icon="👁", order=2}, {name="Combat", icon="⚔", order=3}, {name="Movement", icon="🏃", order=4},
  {name="Utility", icon="🛠", order=5}, {name="Server", icon="🌐", order=6}, {name="Fun", icon="🎮", order=7}, {name="Settings", icon="⚙", order=8},
}
local pages = {} local tabButtons = {} local currentTab = "Home"
for _, td in ipairs(TabDefs) do
  local name = td.name
  local page = Instance.new("ScrollingFrame") page.Name = "Page_" .. name page.Size = UDim2.new(1,0,1,0) page.BackgroundTransparency = 1 page.BorderSizePixel = 0 page.ScrollBarThickness = 4 page.ScrollBarImageColor3 = getTheme().accent page.CanvasSize = UDim2.new(0,0,0,0) page.Visible = (name == "Home") page.ZIndex = 6 page.Active = true page.Parent = contentArea
  pcall(function() page.ScrollingDirection = Enum.ScrollingDirection.Y end)
  local layout = Instance.new("UIListLayout") layout.SortOrder = Enum.SortOrder.LayoutOrder layout.Padding = UDim.new(0, 6) layout.Parent = page
  local pad = Instance.new("UIPadding") pad.PaddingTop = UDim.new(0, 4) pad.PaddingLeft = UDim.new(0, 4) pad.PaddingRight = UDim.new(0, 4) pad.PaddingBottom = UDim.new(0, 12) pad.Parent = page
  pages[name] = page
  local btn = Instance.new("TextButton") btn.Name = "Tab_" .. name btn.Size = UDim2.new(1,0,0,40) btn.BackgroundColor3 = (name == "Home") and getTheme().tabActive or getTheme().tabInactive btn.BorderSizePixel = 0 btn.Text = td.icon .. "  " .. T(name) btn.TextColor3 = (name == "Home") and getTheme().text or getTheme().textDim btn.Font = Enum.Font.GothamBold btn.TextSize = 11 btn.LayoutOrder = td.order btn.ZIndex = 6 btn.Parent = sidebar
  Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
  trackThemed(btn, "BackgroundColor3", (name == "Home") and "tabActive" or "tabInactive")
  trackLabel(btn, name)
  local border = Instance.new("Frame") border.Name = "ActiveBorder" border.Size = UDim2.new(0, 3, 0, 20) border.Position = UDim2.new(0, 0, 0.5, -10) border.BackgroundColor3 = getTheme().accent border.BorderSizePixel = 0 border.Visible = (name == "Home") border.ZIndex = 7 border.Parent = btn
  Instance.new("UICorner", border).CornerRadius = UDim.new(0, 2)
  trackThemed(border, "BackgroundColor3", "accent")
  tabButtons[name] = btn
end
local function recalcPage(page)
  pcall(function()
    if not page or not page:IsA("ScrollingFrame") then return end
    local layout = page:FindFirstChild("UIListLayout")
    local h = layout and layout.AbsoluteContentSize.Y or 0
    local total = math.max(h + 20, page.AbsoluteSize.Y + 1)
    page.CanvasSize = UDim2.new(0, 0, 0, total)
  end)
end
local function recalcCurrentPage() recalcPage(pages[currentTab]) end
for _, pg in pairs(pages) do
  local layout = pg:FindFirstChild("UIListLayout")
  if layout then layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() _delay(0.05, function() recalcPage(pg) end) end) end
end
local function selectTab(name)
  currentTab = name
  for pn, pg in pairs(pages) do pg.Visible = (pn == name) if pn == name then pcall(function() pg.CanvasPosition = Vector2.new(0,0) end) end end
  for bn, btn in pairs(tabButtons) do
    local active = (bn == name) local th = getTheme()
    TweenService:Create(btn, TweenInfo.new(0.18), { BackgroundColor3 = active and th.tabActive or th.tabInactive }):Play()
    btn.TextColor3 = active and th.text or th.textDim
    local b = btn:FindFirstChild("ActiveBorder") if b then b.Visible = active end
    local icon = "" for _, td in ipairs(TabDefs) do if td.name == bn then icon = td.icon .. "  " break end end
    btn.Text = icon .. T(bn)
  end
  _spawn(function() _wait(0.03) recalcCurrentPage() end)
end
for bn, btn in pairs(tabButtons) do btn.MouseButton1Click:Connect(function() selectTab(bn) end) end
-- ============ BUILDERS ============
local function registerRow(page, row, searchText)
  table.insert(RowRegistry, { row = row, page = page, text = string.lower(searchText or "") })
  return row
end
local function applySearch(q)
  q = string.lower(string.gsub(q or "", "%s+", " "))
  for _, r in ipairs(RowRegistry) do
    local show = (q == "" or q == " ") or (string.find(r.text, q, 1, true) ~= nil)
    pcall(function() r.row.Visible = show end)
  end
  recalcCurrentPage()
end
searchBox:GetPropertyChangedSignal("Text"):Connect(function() applySearch(searchBox.Text) end)
searchBox.FocusLost:Connect(function(enter) if enter then applySearch(searchBox.Text) end end)
local function cardRow(page, h)
  local row = Instance.new("Frame") row.Size = UDim2.new(1, 0, 0, h or 44) row.BackgroundColor3 = getTheme().card row.BorderSizePixel = 0 row.ZIndex = 7 row.Parent = page
  Instance.new("UICorner", row).CornerRadius = UDim.new(0, 12)
  trackThemed(row, "BackgroundColor3", "card")
  return row
end
local function addSection(page, text, langKey)
  local lb = Instance.new("TextLabel") lb.Size = UDim2.new(1, 0, 0, 24) lb.BackgroundTransparency = 1 lb.Text = "  " .. text lb.TextColor3 = getTheme().accent lb.Font = Enum.Font.GothamBold lb.TextSize = 12 lb.TextXAlignment = Enum.TextXAlignment.Left lb.ZIndex = 7 lb.Parent = page
  trackThemed(lb, "TextColor3", "accent")
  if langKey then trackLabel(lb, langKey) end
  return lb
end
local function addToggle(page, text, stateKey, callback, langKey)
  FeatureCB[stateKey] = callback
  local row = cardRow(page, 44)
  local label = Instance.new("TextLabel") label.Size = UDim2.new(1, -64, 1, 0) label.Position = UDim2.new(0, 12, 0, 0) label.BackgroundTransparency = 1 label.Text = text label.TextColor3 = getTheme().text label.Font = Enum.Font.Gotham label.TextSize = 12 label.TextXAlignment = Enum.TextXAlignment.Left label.ZIndex = 8 label.Parent = row
  trackThemed(label, "TextColor3", "text")
  if langKey then trackLabel(label, langKey) end
  local pill = Instance.new("Frame") pill.Size = UDim2.new(0, 44, 0, 24) pill.Position = UDim2.new(1, -54, 0.5, -12) pill.BackgroundColor3 = getTheme().checkBg pill.BorderSizePixel = 0 pill.ZIndex = 8 pill.Parent = row
  Instance.new("UICorner", pill).CornerRadius = UDim.new(0, 12)
  trackThemed(pill, "BackgroundColor3", "checkBg")
  local knob = Instance.new("Frame") knob.Size = UDim2.new(0, 20, 0, 20) knob.Position = UDim2.new(0, 2, 0.5, -10) knob.BackgroundColor3 = Color3.fromRGB(255,255,255) knob.BorderSizePixel = 0 knob.ZIndex = 9 knob.Parent = pill
  Instance.new("UICorner", knob).CornerRadius = UDim.new(0, 10)
  ToggleUIs[stateKey] = { pill = pill, knob = knob }
  refreshToggleUI(stateKey)
  local btn = Instance.new("TextButton") btn.Size = UDim2.new(1,0,1,0) btn.BackgroundTransparency = 1 btn.Text = "" btn.ZIndex = 10 btn.Parent = row
  btn.MouseButton1Click:Connect(function() setFeature(stateKey, not States[stateKey]) end)
  registerRow(page, row, text .. " " .. (langKey or "") .. " " .. stateKey)
  return row
end
local function addSlider(page, text, valueKey, min, max, isFloat, callback, langKey)
  local row = cardRow(page, 54)
  local label = Instance.new("TextLabel") label.Size = UDim2.new(1, -12, 0, 20) label.Position = UDim2.new(0, 12, 0, 4) label.BackgroundTransparency = 1 label.Text = text .. ": " .. tostring(Values[valueKey] or min) label.TextColor3 = getTheme().text label.Font = Enum.Font.Gotham label.TextSize = 12 label.TextXAlignment = Enum.TextXAlignment.Left label.ZIndex = 8 label.Parent = row
  trackThemed(label, "TextColor3", "text")
  local track = Instance.new("Frame") track.Size = UDim2.new(1, -24, 0, 10) track.Position = UDim2.new(0, 12, 0, 32) track.BackgroundColor3 = getTheme().track track.BorderSizePixel = 0 track.ZIndex = 8 track.Parent = row
  Instance.new("UICorner", track).CornerRadius = UDim.new(0, 5)
  trackThemed(track, "BackgroundColor3", "track")
  local pct = clamp((Values[valueKey] - min) / math.max(max - min, 0.01), 0, 1)
  local fill = Instance.new("Frame") fill.Size = UDim2.new(pct, 0, 1, 0) fill.BackgroundColor3 = getTheme().fill fill.BorderSizePixel = 0 fill.ZIndex = 9 fill.Parent = track
  Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 5)
  trackThemed(fill, "BackgroundColor3", "fill")
  local knob = Instance.new("Frame") knob.Size = UDim2.new(0, 18, 0, 18) knob.Position = UDim2.new(pct, -9, 0.5, -9) knob.BackgroundColor3 = Color3.fromRGB(255,255,255) knob.BorderSizePixel = 0 knob.ZIndex = 10 knob.Parent = track
  Instance.new("UICorner", knob).CornerRadius = UDim.new(0, 9)
  local hit = Instance.new("TextButton") hit.Size = UDim2.new(1, 0, 0, 34) hit.Position = UDim2.new(0, 0, 0, 20) hit.BackgroundTransparency = 1 hit.Text = "" hit.ZIndex = 11 hit.Parent = row
  local activeInput = nil
  local function updateFromPos(pos)
    local rel = clamp((pos.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
    local val = min + rel * (max - min) if not isFloat then val = math.floor(val + 0.5) end
    Values[valueKey] = val fill.Size = UDim2.new(rel, 0, 1, 0) knob.Position = UDim2.new(rel, -9, 0.5, -9)
    label.Text = text .. ": " .. (isFloat and string.format("%.1f", val) or tostring(math.floor(val)))
    if callback then pcall(function() callback(val) end) end
  end
  hit.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then activeInput = input updateFromPos(input.Position) end
  end)
  UserInputService.InputChanged:Connect(function(input) if activeInput and input == activeInput then updateFromPos(input.Position) end end)
  UserInputService.InputEnded:Connect(function(input) if activeInput and input == activeInput then activeInput = nil end end)
  registerRow(page, row, text .. " " .. valueKey)
  return row
end
local function addButton(page, text, callback, langKey)
  local btn = Instance.new("TextButton") btn.Size = UDim2.new(1, 0, 0, 42) btn.BackgroundColor3 = getTheme().btnBg btn.BorderSizePixel = 0 btn.Text = text btn.TextColor3 = getTheme().text btn.Font = Enum.Font.GothamBold btn.TextSize = 12 btn.ZIndex = 8 btn.Parent = page
  Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 12)
  trackThemed(btn, "BackgroundColor3", "btnBg") trackThemed(btn, "TextColor3", "text")
  if langKey then trackLabel(btn, langKey) end
  btn.MouseButton1Click:Connect(function() if callback then pcall(function() callback() end) end end)
  btn.MouseEnter:Connect(function() TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = getTheme().btnHover }):Play() end)
  btn.MouseLeave:Connect(function() TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = getTheme().btnBg }):Play() end)
  registerRow(page, btn, text .. " " .. (langKey or ""))
  return btn
end
local function addInfoRow(page, labelText, valueText, langKey)
  local row = cardRow(page, 38)
  local lbl = Instance.new("TextLabel") lbl.Size = UDim2.new(0.5, 0, 1, 0) lbl.Position = UDim2.new(0, 12, 0, 0) lbl.BackgroundTransparency = 1 lbl.Text = labelText lbl.TextColor3 = getTheme().textDim lbl.Font = Enum.Font.Gotham lbl.TextSize = 11 lbl.TextXAlignment = Enum.TextXAlignment.Left lbl.ZIndex = 8 lbl.Parent = row
  trackThemed(lbl, "TextColor3", "textDim")
  if langKey then trackLabel(lbl, langKey) end
  local val = Instance.new("TextLabel") val.Size = UDim2.new(0.5, -12, 1, 0) val.Position = UDim2.new(0.5, 0, 0, 0) val.BackgroundTransparency = 1 val.Text = valueText or "N/A" val.TextColor3 = getTheme().text val.Font = Enum.Font.GothamBold val.TextSize = 11 val.TextXAlignment = Enum.TextXAlignment.Right val.ZIndex = 8 val.Parent = row
  trackThemed(val, "TextColor3", "text")
  registerRow(page, row, labelText .. " " .. tostring(valueText))
  return row, val
end
local function addDropdown(page, text, options, onSelect, langKey)
  local row = cardRow(page, 44)
  local label = Instance.new("TextLabel") label.Size = UDim2.new(0.45, 0, 1, 0) label.Position = UDim2.new(0, 12, 0, 0) label.BackgroundTransparency = 1 label.Text = text label.TextColor3 = getTheme().text label.Font = Enum.Font.Gotham label.TextSize = 12 label.TextXAlignment = Enum.TextXAlignment.Left label.ZIndex = 8 label.Parent = row
  trackThemed(label, "TextColor3", "text")
  local dropBtn = Instance.new("TextButton") dropBtn.Size = UDim2.new(0.5, -12, 0, 28) dropBtn.Position = UDim2.new(0.5, 0, 0.5, -14) dropBtn.BackgroundColor3 = getTheme().dropBg dropBtn.BorderSizePixel = 0 dropBtn.Text = options[1] or "Select" dropBtn.TextColor3 = getTheme().text dropBtn.Font = Enum.Font.Gotham dropBtn.TextSize = 11 dropBtn.ZIndex = 8 dropBtn.Parent = row
  Instance.new("UICorner", dropBtn).CornerRadius = UDim.new(0, 8)
  trackThemed(dropBtn, "BackgroundColor3", "dropBg")
  local listFrame = nil
  local function closeList() if listFrame then pcall(function() listFrame:Destroy() end) listFrame = nil end end
  dropBtn.MouseButton1Click:Connect(function()
    if listFrame then closeList() return end
    local th = getTheme()
    listFrame = Instance.new("ScrollingFrame") listFrame.Size = UDim2.new(0, dropBtn.AbsoluteSize.X, 0, math.min(#options * 32, 160)) listFrame.Position = UDim2.new(0, dropBtn.AbsolutePosition.X, 0, dropBtn.AbsolutePosition.Y + 32) listFrame.BackgroundColor3 = th.dropBg listFrame.BorderSizePixel = 0 listFrame.ScrollBarThickness = 4 listFrame.CanvasSize = UDim2.new(0,0,0, #options * 32) listFrame.ZIndex = 300 listFrame.Parent = screenGui
    Instance.new("UICorner", listFrame).CornerRadius = UDim.new(0, 10)
    local ll = Instance.new("UIListLayout") ll.SortOrder = Enum.SortOrder.LayoutOrder ll.Parent = listFrame
    for i, opt in ipairs(options) do
      local ob = Instance.new("TextButton") ob.Size = UDim2.new(1, 0, 0, 32) ob.BackgroundTransparency = 1 ob.Text = "  " .. opt ob.TextColor3 = th.text ob.Font = Enum.Font.Gotham ob.TextSize = 12 ob.TextXAlignment = Enum.TextXAlignment.Left ob.LayoutOrder = i ob.ZIndex = 301 ob.Parent = listFrame
      ob.MouseButton1Click:Connect(function() dropBtn.Text = opt closeList() if onSelect then pcall(function() onSelect(opt, i) end) end end)
    end
    _delay(0.01, function() if listFrame then local c = UserInputService.InputBegan:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1 then local pos = inp.Position local ap = listFrame.AbsolutePosition local asz = listFrame.AbsoluteSize if pos.X < ap.X or pos.X > ap.X + asz.X or pos.Y < ap.Y or pos.Y > ap.Y + asz.Y then if inp.Position ~= dropBtn.AbsolutePosition then closeList() end end end end) end end)
  end)
  registerRow(page, row, text .. " " .. table.concat(options, " "))
  return row, dropBtn
end
local function addKeyInput(page)
  local row = cardRow(page, 72)
  local box = Instance.new("TextBox") box.Size = UDim2.new(0.58, 0, 0, 30) box.Position = UDim2.new(0, 12, 0, 8) box.BackgroundColor3 = getTheme().dropBg box.BorderSizePixel = 0 box.PlaceholderText = T("EnterKey") box.Text = "" box.TextColor3 = getTheme().text box.PlaceholderColor3 = getTheme().textDim box.Font = Enum.Font.Gotham box.TextSize = 12 box.ClearTextOnFocus = false box.ZIndex = 8 box.Parent = row
  Instance.new("UICorner", box).CornerRadius = UDim.new(0, 8)
  trackThemed(box, "BackgroundColor3", "dropBg")
  local submit = Instance.new("TextButton") submit.Size = UDim2.new(0.36, -12, 0, 30) submit.Position = UDim2.new(0.62, 0, 0, 8) submit.BackgroundColor3 = getTheme().accent submit.BorderSizePixel = 0 submit.Text = T("SubmitKey") submit.TextColor3 = Color3.fromRGB(255,255,255) submit.Font = Enum.Font.GothamBold submit.TextSize = 12 submit.ZIndex = 8 submit.Parent = row
  Instance.new("UICorner", submit).CornerRadius = UDim.new(0, 8)
  trackThemed(submit, "BackgroundColor3", "accent")
  local status = Instance.new("TextLabel") status.Size = UDim2.new(1, -24, 0, 18) status.Position = UDim2.new(0, 12, 0, 46) status.BackgroundTransparency = 1 status.Text = keyAuthenticated and "✓ Key Accepted" or "✗ Key Required" status.TextColor3 = keyAuthenticated and Color3.fromRGB(0,255,100) or Color3.fromRGB(255,60,60) status.Font = Enum.Font.GothamBold status.TextSize = 11 status.TextXAlignment = Enum.TextXAlignment.Left status.ZIndex = 8 status.Parent = row
  submit.MouseButton1Click:Connect(function()
    local input = box.Text
    if input == "" then notify(T("KeySystem"), T("EnterKey"), 2) return end
    submit.Text = "..." 
    _spawn(function()
      local ok, src = supaCheckKey(input)
      submit.Text = T("SubmitKey")
      if ok then
        keyAuthenticated = true pcall(function() writefile("FLUYEN_key.txt", input) end)
        status.Text = "✓ Key Accepted (" .. tostring(src) .. ")" status.TextColor3 = Color3.fromRGB(0,255,100)
        keyStatusLabel.Visible = false notify(T("KeySystem"), T("KeyAccepted"), 3)
      else
        status.Text = "✗ Wrong Key! (" .. tostring(src) .. ")" status.TextColor3 = Color3.fromRGB(255,60,60)
        notify(T("KeySystem"), T("KeyWrong"), 2)
      end
    end)
  end)
  registerRow(page, row, "key")
  return row, box
end
-- ============ THEME / LANGUAGE UPDATE ============
local function updateAllLanguages()
  for _, e in ipairs(allUILabels) do pcall(function() if e.obj and e.obj.Parent then local isTab = false for n, b in pairs(tabButtons) do if b == e.obj then isTab = true local ic = "" for _, td in ipairs(TabDefs) do if td.name == n then ic = td.icon .. "  " break end end e.obj.Text = ic .. T(e.key) break end end if not isTab then e.obj.Text = T(e.key) end end end) end
  searchBox.PlaceholderText = T("Search")
  subLabel.Text = player.Name .. "  •  Delta  •  " .. T("GestureHint")
end
local function updateAllThemes()
  local th = getTheme()
  pcall(function() mainFrame.BackgroundColor3 = th.bg mainStroke.Color = th.border sidebar.BackgroundColor3 = th.sidebar titleLabel.TextColor3 = th.accent titleGradient.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, th.accent), ColorSequenceKeypoint.new(1, th.accent2) }) miniBtn.BackgroundColor3 = th.accent quickBar.BackgroundColor3 = th.card searchBox.BackgroundColor3 = th.card fovStroke.Color = th.accent tracerDot.BackgroundColor3 = th.accent for _, pg in pairs(pages) do pg.ScrollBarImageColor3 = th.accent end end)
  for _, e in ipairs(allUIThemed) do pcall(function() if e.obj and e.obj.Parent then local v = th[e.themeKey] if v then e.obj[e.prop] = v end end end) end
  for bn, btn in pairs(tabButtons) do local a = (bn == currentTab) btn.BackgroundColor3 = a and th.tabActive or th.tabInactive btn.TextColor3 = a and th.text or th.textDim local b = btn:FindFirstChild("ActiveBorder") if b then b.BackgroundColor3 = th.accent end end
  for k, _ in pairs(ToggleUIs) do refreshToggleUI(k) end
  if quickBarButtons then for _, b in pairs(quickBarButtons) do pcall(function() b:update() end) end end
end
-- ============ MENU OPEN / CLOSE ============
local isOpen = false local isAnimating = false
local OPEN_TWEEN = TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local CLOSE_TWEEN = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local function openMenu()
  if isOpen or isAnimating then return end
  isAnimating = true isOpen = true mainFrame.Visible = true backdrop.Visible = true backdrop.BackgroundTransparency = 1
  if uiScale then uiScale.Scale = 0.85 TweenService:Create(uiScale, OPEN_TWEEN, { Scale = 1 }):Play() end
  TweenService:Create(backdrop, TweenInfo.new(0.2), { BackgroundTransparency = 0.55 }):Play()
  miniBtn.Visible = false quickBar.Visible = false
  _delay(0.32, function() if uiScale then uiScale.Scale = 1 end isAnimating = false recalcCurrentPage() end)
end
local function closeMenu()
  if not isOpen or isAnimating then return end
  isAnimating = true isOpen = false
  if uiScale then local tw = TweenService:Create(uiScale, CLOSE_TWEEN, { Scale = 0.85 }) TweenService:Create(backdrop, CLOSE_TWEEN, { BackgroundTransparency = 1 }):Play() tw:Play() tw.Completed:Connect(function() pcall(function() uiScale.Scale = 1 end) mainFrame.Visible = false backdrop.Visible = false isAnimating = false if States.MinimizeButton then miniBtn.Visible = true end if States.QuickBar then quickBar.Visible = true end end) else mainFrame.Visible = false backdrop.Visible = false isAnimating = false if States.MinimizeButton then miniBtn.Visible = true end if States.QuickBar then quickBar.Visible = true end end
end
local function toggleMenu() if isOpen then closeMenu() else openMenu() end end
miniBtn.MouseButton1Click:Connect(function()
  local d = miniBtn:GetAttribute("FLUYEN_Dragged")
  if d and tick() - d < 0.3 then miniBtn:SetAttribute("FLUYEN_Dragged", 0) return end
  toggleMenu()
end)
backdropClose.MouseButton1Click:Connect(closeMenu)
closeBtn.MouseButton1Click:Connect(closeMenu)
-- ============ FLY / FREECAM JOYSTICK (mobile) ============
local flyJoyVec = Vector2.new(0, 0) local flyUpHeld = false local flyDownHeld = false local flyJoyActive = nil
local flyJoyBase = Instance.new("Frame") flyJoyBase.Size = UDim2.new(0, 120, 0, 120) flyJoyBase.Position = UDim2.new(0, 20, 1, -150) flyJoyBase.BackgroundColor3 = Color3.fromRGB(0,0,0) flyJoyBase.BackgroundTransparency = 0.45 flyJoyBase.BorderSizePixel = 0 flyJoyBase.ZIndex = 105 flyJoyBase.Visible = false flyJoyBase.Parent = screenGui
Instance.new("UICorner", flyJoyBase).CornerRadius = UDim.new(0, 60)
local flyKnob = Instance.new("Frame") flyKnob.Size = UDim2.new(0, 50, 0, 50) flyKnob.Position = UDim2.new(0.5, -25, 0.5, -25) flyKnob.BackgroundColor3 = getTheme().accent flyKnob.BorderSizePixel = 0 flyKnob.ZIndex = 106 flyKnob.Parent = flyJoyBase
Instance.new("UICorner", flyKnob).CornerRadius = UDim.new(0, 25)
local flyUpBtn = Instance.new("TextButton") flyUpBtn.Size = UDim2.new(0, 56, 0, 56) flyUpBtn.Position = UDim2.new(1, -128, 1, -150) flyUpBtn.BackgroundColor3 = getTheme().accent flyUpBtn.Text = "⬆" flyUpBtn.TextColor3 = Color3.fromRGB(255,255,255) flyUpBtn.Font = Enum.Font.GothamBold flyUpBtn.TextSize = 20 flyUpBtn.ZIndex = 105 flyUpBtn.Visible = false flyUpBtn.Parent = screenGui
Instance.new("UICorner", flyUpBtn).CornerRadius = UDim.new(0, 28)
local flyDownBtn = Instance.new("TextButton") flyDownBtn.Size = UDim2.new(0, 56, 0, 56) flyDownBtn.Position = UDim2.new(1, -64, 1, -150) flyDownBtn.BackgroundColor3 = getTheme().card flyDownBtn.Text = "⬇" flyDownBtn.TextColor3 = getTheme().text flyDownBtn.Font = Enum.Font.GothamBold flyDownBtn.TextSize = 20 flyDownBtn.ZIndex = 105 flyDownBtn.Visible = false flyDownBtn.Parent = screenGui
Instance.new("UICorner", flyDownBtn).CornerRadius = UDim.new(0, 28)
local function updateFlyUI()
  local show = States.Fly or States.Freecam
  flyJoyBase.Visible = show flyUpBtn.Visible = show flyDownBtn.Visible = show
end
flyJoyBase.InputBegan:Connect(function(input)
  if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then flyJoyActive = input end
end)
UserInputService.InputChanged:Connect(function(input)
  if flyJoyActive and input == flyJoyActive then
    local center = flyJoyBase.AbsolutePosition + flyJoyBase.AbsoluteSize / 2
    local d = Vector2.new(input.Position.X, input.Position.Y) - center
    if d.Magnitude > 45 then d = d.Unit * 45 end
    flyJoyVec = d / 45
    flyKnob.Position = UDim2.new(0.5, -25 + d.X, 0.5, -25 + d.Y)
  end
end)
UserInputService.InputEnded:Connect(function(input)
  if flyJoyActive and input == flyJoyActive then flyJoyActive = nil flyJoyVec = Vector2.new(0,0) flyKnob.Position = UDim2.new(0.5, -25, 0.5, -25) end
end)
flyUpBtn.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then flyUpHeld = true end end)
flyUpBtn.InputEnded:Connect(function(i) flyUpHeld = false end)
flyDownBtn.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then flyDownHeld = true end end)
flyDownBtn.InputEnded:Connect(function(i) flyDownHeld = false end)
-- ============ GESTURE v2 : 3 NGON ============
local gestureTestLabel = nil
local lastGestureFire = 0 local gestureTapCount = 0 local gestureLastTap = 0
local activeTouches = {} -- touch -> {t0,x,y,maxMove}
local pendingGroup = nil -- {touches={}, start, ended, valid}
local function insideMainFrame(pos)
  if not isOpen then return false end
  local ap = mainFrame.AbsolutePosition local asz = mainFrame.AbsoluteSize
  return pos.X >= ap.X and pos.X <= ap.X + asz.X and pos.Y >= ap.Y and pos.Y <= ap.Y + asz.Y
end
local function insideAnyUI(pos)
  if insideMainFrame(pos) then return true end
  local function inside(f) if not f or not f.Visible then return false end local ap = f.AbsolutePosition local asz = f.AbsoluteSize return pos.X >= ap.X and pos.X <= ap.X + asz.X and pos.Y >= ap.Y and pos.Y <= ap.Y + asz.Y end
  if inside(miniBtn) or inside(quickBar) or inside(flyJoyBase) or inside(flyUpBtn) or inside(flyDownBtn) then return true end
  return false
end
local function showGestureHint(txt, ok)
  gestureHint.Visible = true gestureHint.Text = txt
  gestureHint.BackgroundColor3 = ok and Color3.fromRGB(0,180,100) or Color3.fromRGB(0,0,0)
  if gestureTestLabel then pcall(function() gestureTestLabel.Text = txt end) end
  _delay(1.2, function() if tick() - lastGestureFire > 1.1 then gestureHint.Visible = false end end)
end
local function fireGesture(reason)
  if tick() - lastGestureFire < 0.6 then return end
  lastGestureFire = tick()
  showGestureHint("✅ " .. T("GestureDetected") .. " (" .. reason .. ")", true)
  toggleMenu()
end
local function onGroupTap()
  if Values.GestureMode == "Tap1" then fireGesture("tap")
  elseif Values.GestureMode == "Tap3" then
    if tick() - gestureLastTap > 1.5 then gestureTapCount = 0 end
    gestureTapCount = gestureTapCount + 1 gestureLastTap = tick()
    if gestureTapCount >= 3 then gestureTapCount = 0 fireGesture("tap x3")
    else showGestureHint("👆 " .. gestureTapCount .. "/3 - cham them " .. (3 - gestureTapCount) .. " lan nua", false) end
  else
    -- Hold / Swipe: tap nhanh khong tinh, tranh mo nham khi choi game
  end
end
local function countActive()
  local n = 0 for _, _ in pairs(activeTouches) do n = n + 1 end return n
end
UserInputService.TouchStarted:Connect(function(touch, gpe)
  if not States.GestureEnabled then return end
  local pos = touch.Position
  if insideAnyUI(pos) then return end
  if activeTouches[touch] then return end
  activeTouches[touch] = { t0 = tick(), x = pos.X, y = pos.Y, maxMove = 0 }
  local n = countActive()
  if n >= 2 then gestureHint.Visible = true gestureHint.Text = "👆 " .. n .. " ngon..." gestureHint.BackgroundColor3 = Color3.fromRGB(0,0,0) end
  if n == 3 then
    local set = {}
    for t, _ in pairs(activeTouches) do set[t] = true end
    pendingGroup = { touches = set, start = tick(), ended = 0, valid = true, holdFired = false, swipeFired = false }
    -- Hold mode: sau 0.5s neu van giu 3 ngon va it di chuyen -> mo menu
    _spawn(function()
      local grp = pendingGroup _wait(0.5)
      if grp and pendingGroup == grp and Values.GestureMode == "Hold" and countActive() >= 3 then
        local okMove = true for t, e in pairs(activeTouches) do if e.maxMove > 35 then okMove = false end end
        if okMove then pendingGroup.holdFired = true fireGesture("hold") pendingGroup = nil end
      end
    end)
  end
end)
UserInputService.TouchEnded:Connect(function(touch, gpe)
  local e = activeTouches[touch]
  if not e then return end
  local pos = touch.Position
  local dur = tick() - e.t0
  local move = math.sqrt((pos.X - e.x)^2 + (pos.Y - e.y)^2)
  if move > e.maxMove then e.maxMove = move end
  activeTouches[touch] = nil
  if pendingGroup and pendingGroup.touches[touch] then
    pendingGroup.ended = pendingGroup.ended + 1
    if dur > 0.45 or e.maxMove > 40 then pendingGroup.valid = false end
    if pendingGroup.ended >= 3 then
      local g = pendingGroup pendingGroup = nil
      if g.valid and not g.holdFired and not g.swipeFired then onGroupTap() end
    end
  end
  if countActive() == 0 then _delay(0.6, function() if countActive() == 0 then gestureHint.Visible = false end end) end
end)
UserInputService.InputChanged:Connect(function(input)
  if input.UserInputType ~= Enum.UserInputType.Touch then return end
  -- cap nhat maxMove + phat hien Swipe xuong 3 ngon
  for t, e in pairs(activeTouches) do
    -- Touch object khong so sanh truc tiep duoc voi InputObject trong 1 so executor, nen dung khoang cach gan dung: neu input nam gan touch cu thi cap nhat
    -- Cach an toan: cap nhat tat ca touch dang active neu pendingGroup co 3 ngon va input di xuong
    if pendingGroup and Values.GestureMode == "Swipe" and not pendingGroup.swipeFired then
      local dy = input.Position.Y - e.y
      if dy > 80 and math.abs(input.Position.X - e.x) < 60 then
        pendingGroup.swipeFired = true fireGesture("swipe") pendingGroup = nil break
      end
    end
  end
end)
UserInputService.InputBegan:Connect(function(input, gpe)
  if input.KeyCode == Enum.KeyCode.Insert then toggleMenu() return end
  -- Fallback: 1 so executor khong goi TouchStarted ma goi InputBegan Touch - neu da co TouchStarted thi TouchEnded se xu ly, tranh double
end)
-- ============ TRACER POOL (khong tao/xoa moi frame) ============
local TRACER_MAX = 32 local tracerPool = {}
for i = 1, TRACER_MAX do
  local ln = Instance.new("Frame") ln.Size = UDim2.new(0, 10, 0, 1.5) ln.BackgroundColor3 = getTheme().accent ln.BorderSizePixel = 0 ln.BackgroundTransparency = 0.3 ln.ZIndex = 49 ln.Visible = false ln.Parent = tracerContainer
  tracerPool[i] = ln
end
local function setTracer(i, x1, y1, x2, y2)
  local ln = tracerPool[i] if not ln then return end
  local dx, dy = x2 - x1, y2 - y1 local len = math.sqrt(dx*dx + dy*dy) if len < 1 then ln.Visible = false return end
  ln.Visible = true ln.Size = UDim2.new(0, len, 0, 1.5) ln.Position = UDim2.new(0, x1, 0, y1) ln.Rotation = math.deg(math.atan2(dy, dx))
end
-- ============ HELPERS CHAR ============
local function getChar() return player.Character end
local function getHum() local c = getChar() return c and c:FindFirstChild("Humanoid") or nil end
local function getHRP() local c = getChar() return c and c:FindFirstChild("HumanoidRootPart") or nil end
local spectateTarget = nil local orbitTarget = nil
local function ensureHighlight(char, name, fill, fillTrans, outline)
  local hl = char:FindFirstChild(name)
  if not hl then hl = Instance.new("Highlight") hl.Name = name hl.FillTransparency = fillTrans or 0.5 hl.OutlineTransparency = 0 hl.FillColor = fill hl.OutlineColor = outline or fill hl.Parent = char end
  return hl
end
local function removeFromAll(name)
  for _, tgt in ipairs(Players:GetPlayers()) do pcall(function() if tgt.Character then local o = tgt.Character:FindFirstChild(name) if o then o:Destroy() end end end) end
end
local function ensureBillboard(head, name, size, offset)
  local g = head:FindFirstChild(name)
  if not g then g = Instance.new("BillboardGui") g.Name = name g.Size = UDim2.new(0, size.X, 0, size.Y) g.StudsOffset = offset g.AlwaysOnTop = true g.Parent = head end
  return g
end
-- ============ MASTER LOOP (1 loop duy nhat) ============
local _lastTick = 0 local _fpsA, _fpsT, _curFps = 0, 0, 60
local _slowAcc, _xrayAcc, _trigAcc = 0, 0, 0
local _lastPing = "--"
setConn("Master", RunService.RenderStepped:Connect(function(dt)
  pcall(function()
    dt = dt or 0.016
    -- FPS + counts
    local now = tick()
    if _lastTick > 0 then local d = now - _lastTick if d > 0 then _fpsA = _fpsA + 1 _fpsT = _fpsT + d if _fpsT >= 0.5 then _curFps = math.floor(_fpsA / _fpsT) _fpsA = 0 _fpsT = 0 end end end
    _lastTick = now
    if States.ShowFPS then fpsLabel.Visible = true fpsLabel.Text = "FPS: " .. _curFps fpsLabel.TextColor3 = _curFps >= 50 and Color3.fromRGB(0,255,100) or (_curFps >= 30 and Color3.fromRGB(255,200,0) or Color3.fromRGB(255,60,60)) else fpsLabel.Visible = false end
    if States.ShowPlayers then playerCountLabel.Visible = true playerCountLabel.Text = T("PlayersOnline") .. ": " .. #Players:GetPlayers() else playerCountLabel.Visible = false end
    if States.ShowPing then pingLabel.Visible = true pcall(function() local st = game:GetService("Stats") local ni = st and st.Network and st.Network.ServerStatsItem and st.Network.ServerStatsItem["Data Ping"] if ni then _lastPing = tostring(math.floor(ni:GetValue())) end end) pingLabel.Text = "Ping: " .. _lastPing else pingLabel.Visible = false end
    -- FOV
    fovCircle.Visible = States.AimFOV
    if States.AimFOV then local s = Values.AimFOVValue * 2 fovCircle.Size = UDim2.new(0, s, 0, s) fovCircle.Position = UDim2.new(0.5, -Values.AimFOVValue, 0.5, -Values.AimFOVValue) end
    if States.Aim or States.SilentAim then camera.FieldOfView = Values.FieldOfView end
    -- Tracers (pool)
    tracerDot.Visible = States.Tracers
    if States.Tracers then
      local idx = 0 local sw = camera.ViewportSize.X
      for _, tgt in ipairs(Players:GetPlayers()) do
        if tgt ~= player and tgt.Character and tgt.Character:FindFirstChild("Head") then
          local hp, on = camera:WorldToViewportPoint(tgt.Character.Head.Position)
          if on and idx < TRACER_MAX then idx = idx + 1 setTracer(idx, sw/2, 0, hp.X, hp.Y) end
        end
      end
      for i = idx + 1, TRACER_MAX do tracerPool[i].Visible = false end
    else for i = 1, TRACER_MAX do tracerPool[i].Visible = false end end
    -- ESP / Chams / Box (reuse Highlight, khong tao moi)
    for _, tgt in ipairs(Players:GetPlayers()) do
      if tgt ~= player and tgt.Character then
        local ch = tgt.Character
        if States.ESP then ensureHighlight(ch, "FLUYEN_ESP", getTheme().accent, 0.5) else local o = ch:FindFirstChild("FLUYEN_ESP") if o then o:Destroy() end end
        if States.Chams then ensureHighlight(ch, "FLUYEN_Cham", Color3.fromRGB(255,0,0), 0.3, Color3.fromRGB(255,255,255)) else local o = ch:FindFirstChild("FLUYEN_Cham") if o then o:Destroy() end end
        if States.BoxESP then
          local b = ch:FindFirstChild("FLUYEN_Box")
          if not b then b = Instance.new("BoxHandleAdornment") b.Name = "FLUYEN_Box" b.Color3 = getTheme().accent b.Transparency = 0.7 b.Size = Vector3.new(4,5,1) b.Adornee = ch b.AlwaysOnTop = true b.ZIndex = 5 b.Parent = ch end
        else local o = ch:FindFirstChild("FLUYEN_Box") if o then o:Destroy() end end
        -- Hitbox
        if States.HitboxExpander and ch:FindFirstChild("HumanoidRootPart") then local hrp = ch.HumanoidRootPart hrp.Size = Vector3.new(Values.HitboxSize, Values.HitboxSize, Values.HitboxSize) hrp.Transparency = 0.5 end
      end
    end
    -- Aimbot
    if States.Aim then
      local closest, minD = nil, Values.AimFOVValue
      for _, tgt in ipairs(Players:GetPlayers()) do
        if tgt ~= player and tgt.Character and tgt.Character:FindFirstChild("Head") then
          local hp, on = camera:WorldToViewportPoint(tgt.Character.Head.Position)
          if on then local d = (Vector2.new(hp.X, hp.Y) - Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)).Magnitude if d < minD then minD = d closest = tgt.Character.Head end end
        end
      end
      if closest then local sm = math.max(1, Values.AimSmoothness) local cf = camera.CFrame camera.CFrame = cf:Lerp(CFrame.new(cf.Position, closest.Position + (States.AimPrediction and closest.AssemblyLinearVelocity * 0.1 or Vector3.new(0,0,0))), 1/sm) end
    end
    -- Spectate
    if spectateTarget and spectateTarget.Character and spectateTarget.Character:FindFirstChild("Humanoid") then camera.CameraSubject = spectateTarget.Character.Humanoid end
    -- Movement: Speed / Fly / Freecam / Noclip / Jump / Sprint / AntiVoid / Spin / Float / Bang / Orbit
    local hum = getHum() local hrp = getHRP()
    if hum and hrp then
      if States.Noclip then for _, part in ipairs(getChar():GetDescendants()) do if part:IsA("BasePart") then part.CanCollide = false end end end
      if States.JumpPower then hum.JumpPower = Values.JumpPowerValue end
      if States.Speed then
        hum.WalkSpeed = Values.SpeedValue
        if hum.MoveDirection.Magnitude > 0 then local boost = (Values.SpeedValue - 16) * 0.015 if boost > 0 then hrp.CFrame = hrp.CFrame + hum.MoveDirection.Unit * boost end end
      elseif States.Sprint then
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or flyJoyVec.Magnitude > 0.9 then hum.WalkSpeed = Values.SprintSpeed else hum.WalkSpeed = 16 end
      end
      if States.AntiSlow then hum.WalkSpeed = math.max(hum.WalkSpeed, 16) end
      if States.AntiVoid and hrp.Position.Y < -10 then hrp.CFrame = CFrame.new(hrp.Position.X, 10, hrp.Position.Z) end
      if States.Fly then
        pcall(function() hum.PlatformStand = true end)
        local mv = Vector3.new(0,0,0)
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then mv = mv + camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then mv = mv - camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then mv = mv - camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then mv = mv + camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) or flyUpHeld then mv = mv + Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or flyDownHeld then mv = mv - Vector3.new(0,1,0) end
        if flyJoyVec.Magnitude > 0.1 then mv = mv + camera.CFrame.LookVector * (-flyJoyVec.Y) + camera.CFrame.RightVector * flyJoyVec.X end
        if mv.Magnitude > 0 then local np = hrp.CFrame.Position + mv.Unit * (Values.FlySpeed * dt * 2.2) hrp.CFrame = CFrame.new(np, np + camera.CFrame.LookVector) end
        pcall(function() hrp.AssemblyLinearVelocity = Vector3.new(0,0,0) hrp.Velocity = Vector3.new(0,0,0) end)
      end
      if States.Freecam then
        pcall(function() camera.CameraType = Enum.CameraType.Scriptable end)
        local mv = Vector3.new(0,0,0)
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then mv = mv + camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then mv = mv - camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then mv = mv - camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then mv = mv + camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) or flyUpHeld then mv = mv + Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or flyDownHeld then mv = mv - Vector3.new(0,1,0) end
        if flyJoyVec.Magnitude > 0.1 then mv = mv + camera.CFrame.LookVector * (-flyJoyVec.Y) + camera.CFrame.RightVector * flyJoyVec.X end
        if mv.Magnitude > 0 then camera.CFrame = camera.CFrame + mv.Unit * 1.1 end
      end
      if States.Spin then hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(Values.SpinSpeed), 0) end
      if States.Float then local fy = math.sin(tick()*2)*5 pcall(function() hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, fy, hrp.AssemblyLinearVelocity.Z) end) local bv = hrp:FindFirstChild("FLUYEN_FloatBV") if not bv then bv = Instance.new("BodyVelocity") bv.Name = "FLUYEN_FloatBV" bv.MaxForce = Vector3.new(0, math.huge, 0) bv.Velocity = Vector3.new(0,0,0) bv.Parent = hrp end bv.Velocity = Vector3.new(0, fy, 0) end
      if States.Bang then hrp.CFrame = hrp.CFrame * CFrame.new(0, math.sin(tick()*10)*0.3, 0) end
      if States.OrbitActive and orbitTarget and orbitTarget.Character and orbitTarget.Character:FindFirstChild("HumanoidRootPart") then local ang = CFrame.Angles(0, math.rad(tick()*Values.OrbitSpeed*50 % 360), 0) hrp.CFrame = orbitTarget.Character.HumanoidRootPart.CFrame * ang * CFrame.new(Values.OrbitRadius, 0, 0) end
      if States.LowGravity then workspace.Gravity = Values.LowGravityValue end
    end
    -- Utility per-frame
    if States.FreezeTime then Lighting.ClockTime = 14 end
    if States.FullBright then Lighting.Brightness = 2 Lighting.ClockTime = 14 Lighting.FogEnd = 100000 Lighting.Ambient = Color3.fromRGB(178,178,178) end
    if States.NightVision then Lighting.Brightness = 3 Lighting.ClockTime = 14 Lighting.FogEnd = 100000 Lighting.Ambient = Color3.fromRGB(100,255,100) Lighting.OutdoorAmbient = Color3.fromRGB(100,255,100) end
    if States.AntiBlind then Lighting.Brightness = math.max(Lighting.Brightness, 1) Lighting.FogEnd = math.max(Lighting.FogEnd, 10000) end
    -- Slow section (0.15s)
    _slowAcc = _slowAcc + dt
    if _slowAcc >= 0.15 then
      _slowAcc = 0
      -- Name / Health / Distance
      for _, tgt in ipairs(Players:GetPlayers()) do
        if tgt ~= player and tgt.Character and tgt.Character:FindFirstChild("Head") then
          local head = tgt.Character.Head
          if States.NameESP then local g = ensureBillboard(head, "FLUYEN_Name", Vector2.new(100,20), Vector3.new(0,3,0)) local tx = g:FindFirstChild("NameText") if not tx then tx = Instance.new("TextLabel") tx.Name = "NameText" tx.Size = UDim2.new(1,0,1,0) tx.BackgroundTransparency = 1 tx.TextColor3 = Color3.fromRGB(255,255,255) tx.Font = Enum.Font.GothamBold tx.TextSize = 13 tx.Parent = g end tx.Text = tgt.Name else local g = head:FindFirstChild("FLUYEN_Name") if g then g:Destroy() end end
          if States.HealthESP and tgt.Character:FindFirstChild("Humanoid") then local hum2 = tgt.Character.Humanoid local g = ensureBillboard(head, "FLUYEN_Health", Vector2.new(100,14), Vector3.new(0,4.5,0)) local bg = g:FindFirstChild("HPBg") if not bg then bg = Instance.new("Frame") bg.Name = "HPBg" bg.Size = UDim2.new(1,0,1,0) bg.BackgroundColor3 = Color3.fromRGB(60,60,60) bg.BorderSizePixel = 0 bg.Parent = g Instance.new("UICorner", bg).CornerRadius = UDim.new(0,3) local fl = Instance.new("Frame") fl.Name = "HPFill" fl.Size = UDim2.new(1,0,1,0) fl.BackgroundColor3 = Color3.fromRGB(0,255,0) fl.BorderSizePixel = 0 fl.Parent = g Instance.new("UICorner", fl).CornerRadius = UDim.new(0,3) end local fl = g:FindFirstChild("HPFill") if fl then local hp = clamp(hum2.Health / math.max(hum2.MaxHealth,1), 0, 1) fl.Size = UDim2.new(hp,0,1,0) fl.BackgroundColor3 = Color3.new(1-hp, hp, 0) end else local g = head:FindFirstChild("FLUYEN_Health") if g then g:Destroy() end end
          if States.DistanceESP and getHRP() and tgt.Character:FindFirstChild("HumanoidRootPart") then local dist = (tgt.Character.HumanoidRootPart.Position - getHRP().Position).Magnitude local g = ensureBillboard(head, "FLUYEN_Dist", Vector2.new(100,16), Vector3.new(0,2,0)) local tx = g:FindFirstChild("DistText") if not tx then tx = Instance.new("TextLabel") tx.Name = "DistText" tx.Size = UDim2.new(1,0,1,0) tx.BackgroundTransparency = 1 tx.TextColor3 = Color3.fromRGB(255,200,50) tx.Font = Enum.Font.Gotham tx.TextSize = 11 tx.Parent = g end tx.Text = math.floor(dist) .. "m" else local g = head:FindFirstChild("FLUYEN_Dist") if g then g:Destroy() end end
        end
      end
      -- TriggerBot (0.15s, khong spam moi frame)
      if States.TriggerBot then pcall(function() local m = player:GetMouse() if m.Target and m.Target.Parent then local tp = Players:GetPlayerFromCharacter(m.Target.Parent) if tp and tp ~= player then pcall(function() mouse1click() end) end end end) end
      -- AntiRagdoll / AntiGrab (slow)
      if States.AntiRagdoll and getHum() then pcall(function() getHum():ChangeState(Enum.HumanoidStateType.GettingUp) end) end
      if States.AntiGrab and getHRP() then pcall(function() for _, ch in ipairs(getHRP():GetChildren()) do if (ch:IsA("Weld") or ch:IsA("WeldConstraint") or ch:IsA("Motor6D")) and (string.find(ch.Name, "Grab") or string.find(ch.Name, "grab") or string.find(ch.Name, "Carry")) then ch:Destroy() end end end) end
    end
    -- Xray (0.5s, khong quet moi frame)
    _xrayAcc = _xrayAcc + dt
    if States.Xray and _xrayAcc >= 0.5 then _xrayAcc = 0 pcall(function() for _, o in ipairs(Workspace:GetDescendants()) do if o:IsA("BasePart") and not o.Parent:FindFirstChild("Humanoid") then o.LocalTransparencyModifier = 0.6 end end end) end
    if not States.Xray and _xrayAcc >= 0.5 then _xrayAcc = 0 end
  end)
end))
-- InfiniteJump + ClickTeleport (event rieng, khong phai loop)
setConn("InfJump", UserInputService.JumpRequest:Connect(function() if States.InfiniteJump and getHum() then pcall(function() getHum():ChangeState(Enum.HumanoidStateType.Jumping) end) end end))
setConn("ClickTP", UserInputService.InputBegan:Connect(function(input, gpe)
  if gpe then return end
  if States.ClickTeleport and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
    -- khong teleport khi bam vao menu / quickbar
    if insideMainFrame(input.Position) or insideAnyUI(input.Position) then return end
    if input.UserInputType == Enum.UserInputType.Touch then
      pcall(function() local ray = camera:ScreenPointToRay(input.Position.X, input.Position.Y) local res = Workspace:Raycast(ray.Origin, ray.Direction * 500) if res and getHRP() then getHRP().CFrame = CFrame.new(res.Position + Vector3.new(0,3,0)) end end)
    else
      pcall(function() local m = player:GetMouse() if m.Hit and getHRP() then getHRP().CFrame = m.Hit + Vector3.new(0,3,0) end end)
    end
  end
end))
player.CharacterAdded:Connect(function()
  _wait(0.5)
  if States.Fly and getHum() then pcall(function() getHum().PlatformStand = true end) end
  if States.Invisible then _spawn(function() _wait(0.3) pcall(function() for _, part in ipairs(getChar():GetDescendants()) do if part:IsA("BasePart") then part.Transparency = 1 end if part:IsA("Decal") or part:IsA("Texture") then part.Transparency = 1 end end end) end) end
  updateFlyUI()
end)
-- ============ SAVE / RESET / UPDATE / UNLOAD ============
local function saveSettings()
  pcall(function()
    local data = { theme = currentTheme, language = currentLang, states = States, values = Values, gestureMode = Values.GestureMode }
    writefile("FLUYEN_settings.json", HttpService:JSONEncode(data))
    notify(T("SaveSettings"), T("SavedLocal"), 2)
  end)
  _spawn(function() local ok = supaSaveSettings() if ok then notify(T("SaveSettings"), T("SavedCloud"), 2) end end)
end
local function resetSettings()
  for k, v in pairs(States) do if type(v) == "boolean" then States[k] = false end end
  States.AntiAFK = true States.MinimizeButton = true States.DraggableGUI = true States.Notifications = true States.QuickBar = true States.GestureEnabled = true States.AutoLoadSettings = true States.ShowFPS = true States.ShowPing = true States.ShowPlayers = true
  Values.SpeedValue = 16 Values.FlySpeed = 50 Values.JumpPowerValue = 50 Values.SprintSpeed = 24 Values.SpinSpeed = 10 Values.AimFOVValue = 90 Values.AimSmoothness = 5 Values.HitboxSize = 10 Values.OrbitRadius = 5 Values.OrbitSpeed = 1 Values.FlingPower = 500 Values.FieldOfView = 70 Values.LowGravityValue = 50 Values.GestureMode = "Tap1"
  currentTheme = "Dark" currentLang = "VI"
  pcall(function() workspace.Gravity = 196.2 camera.CameraType = Enum.CameraType.Custom camera.FieldOfView = 70 Lighting.Brightness = 1 Lighting.FogEnd = 1000 Lighting.Ambient = Color3.fromRGB(0,0,0) Lighting.OutdoorAmbient = Color3.fromRGB(0,0,0) Lighting.ClockTime = 14 end)
  pcall(function() if getHum() then getHum().PlatformStand = false getHum().WalkSpeed = 16 getHum().JumpPower = 50 end end)
  removeFromAll("FLUYEN_ESP") removeFromAll("FLUYEN_Cham") removeFromAll("FLUYEN_Box")
  for _, tgt in ipairs(Players:GetPlayers()) do pcall(function() if tgt.Character and tgt.Character:FindFirstChild("Head") then for _, n in ipairs({"FLUYEN_Name","FLUYEN_Health","FLUYEN_Dist"}) do local g = tgt.Character.Head:FindFirstChild(n) if g then g:Destroy() end end end end) end
  updateAllThemes() updateAllLanguages() refreshAllToggles() updateFlyUI() miniBtn.Visible = true quickBar.Visible = true
  notify(T("ResetSettings"), T("AllOff"), 2)
end
local function checkUpdate()
  notify(T("CheckUpdate"), "Dang kiem tra...", 2)
  _spawn(function()
    local v = supaFetchVersion()
    if not v then notify(T("CheckUpdate"), "Khong ket noi duoc Supabase - giu ban hien tai", 3) return end
    if v.version and v.version ~= SCRIPT_VERSION then
      notify("🎉 " .. T("UpdateAvailable"), (v.version or "") .. " - " .. (v.changelog or ""), 5)
      if v.lua_url and v.lua_url ~= "" then
        local ok, code = pcall(function() return game:HttpGet(v.lua_url) end)
        if ok and code and #code > 1000 then pcall(function() writefile("FLUYEN_v6_new.lua", code) end) notify(T("CheckUpdate"), "Da tai ban moi -> FLUYEN_v6_new.lua (chay lai script)", 4) end
      end
    else notify(T("CheckUpdate"), T("UpToDate") .. " (" .. SCRIPT_VERSION .. ")", 2) end
  end)
end
local function unloadMenu()
  for k, _ in pairs(States) do if type(States[k]) == "boolean" then local keep = (k == "MinimizeButton" or k == "DraggableGUI" or k == "Notifications") if not keep then pcall(function() setFeature(k, false) end) end end end
  pcall(function() workspace.Gravity = 196.2 camera.CameraType = Enum.CameraType.Custom camera.FieldOfView = 70 Lighting.Brightness = 1 Lighting.FogEnd = 1000 Lighting.Ambient = Color3.fromRGB(0,0,0) Lighting.OutdoorAmbient = Color3.fromRGB(0,0,0) end)
  removeFromAll("FLUYEN_ESP") removeFromAll("FLUYEN_Cham") removeFromAll("FLUYEN_Box")
  for n, c in pairs(Conns) do pcall(function() c:Disconnect() end) end
  _wait(0.2)
  pcall(function() screenGui:Destroy() espGui:Destroy() local g = playerGui:FindFirstChild("FLUYEN_Noti_Gui") if g then g:Destroy() end end)
  print("[FLUYEN] Unloaded v6.0")
end
-- ============ POPULATE TABS ============
do local p = pages["Home"]
  addSection(p, T("ScriptName"), "ScriptName")
  addInfoRow(p, T("ScriptName"), SCRIPT_NAME, "ScriptName")
  addInfoRow(p, T("Version"), SCRIPT_VERSION, "Version")
  addInfoRow(p, T("Username"), player.Name, "Username")
  addInfoRow(p, T("Executor"), "Delta", "Executor")
  addInfoRow(p, T("Credits"), "FLUYEN Team", "Credits")
  addSection(p, T("QuickToggles"), "QuickToggles")
  addButton(p, "👁  ESP - Bat / Tat", function() setFeature("ESP", not States.ESP) end)
  addButton(p, "🕊  Fly - Bat / Tat", function() setFeature("Fly", not States.Fly) end)
  addButton(p, "⚡  Speed - Bat / Tat", function() setFeature("Speed", not States.Speed) end)
  addButton(p, "🎯  Aimbot - Bat / Tat", function() setFeature("Aim", not States.Aim) end)
  addButton(p, "🚨  " .. T("Panic"), function() for k, v in pairs(States) do if type(v) == "boolean" and k ~= "AntiAFK" and k ~= "MinimizeButton" and k ~= "DraggableGUI" and k ~= "Notifications" and k ~= "QuickBar" and k ~= "GestureEnabled" and k ~= "AutoLoadSettings" then if v == true then setFeature(k, false) end end end refreshAllToggles() notify("PANIC", T("AllOff"), 2) end)
  addButton(p, "🔄  " .. T("CheckUpdate"), function() checkUpdate() end)
  addSection(p, T("PlayersOnline"), "PlayersOnline")
  addInfoRow(p, T("PlayersOnline"), tostring(#Players:GetPlayers()), "PlayersOnline")
  addSection(p, T("Changelog"), "Changelog")
  addInfoRow(p, "v6.0", "UI moi, Gesture v2, 1 loop, Joystick, Supabase")
  addInfoRow(p, "v5.1", "Key system, ESP Lines, FOV Circle")
  addInfoRow(p, "v4.0", "Full Delta rewrite")
end
do local p = pages["Visual"]
  addSection(p, T("ESP"), "ESP")
  addToggle(p, T("ESP"), "ESP", nil, "ESP")
  addToggle(p, T("BoxESP"), "BoxESP", nil, "BoxESP")
  addToggle(p, T("NameESP"), "NameESP", nil, "NameESP")
  addToggle(p, T("HealthESP"), "HealthESP", nil, "HealthESP")
  addToggle(p, T("DistanceESP"), "DistanceESP", nil, "DistanceESP")
  addToggle(p, T("Tracers"), "Tracers", nil, "Tracers")
  addToggle(p, T("Chams"), "Chams", nil, "Chams")
  addSection(p, T("FullBright"), "FullBright")
  addToggle(p, T("FullBright"), "FullBright", function(v) if not v then pcall(function() Lighting.Brightness = 1 Lighting.FogEnd = 1000 Lighting.Ambient = Color3.fromRGB(0,0,0) end) end end, "FullBright")
  addToggle(p, T("NightVision"), "NightVision", function(v) if not v then pcall(function() Lighting.Brightness = 1 Lighting.Ambient = Color3.fromRGB(0,0,0) Lighting.OutdoorAmbient = Color3.fromRGB(0,0,0) end) end end, "NightVision")
  addToggle(p, T("Xray"), "Xray", function(v) if not v then pcall(function() for _, o in ipairs(Workspace:GetDescendants()) do if o:IsA("BasePart") then o.LocalTransparencyModifier = 0 end end end) end end, "Xray")
end
do local p = pages["Combat"]
  addSection(p, T("Aim"), "Aim")
  addToggle(p, T("Aim"), "Aim", nil, "Aim")
  addToggle(p, T("SilentAim"), "SilentAim", function(v) notify(T("SilentAim"), v and T("Enabled") or T("Disabled"), 2) end, "SilentAim")
  addToggle(p, T("AimFOV"), "AimFOV", nil, "AimFOV")
  addToggle(p, T("AimPrediction"), "AimPrediction", function(v) notify(T("AimPrediction"), v and T("Enabled") or T("Disabled"), 2) end, "AimPrediction")
  addToggle(p, T("TriggerBot"), "TriggerBot", nil, "TriggerBot")
  addToggle(p, T("HitboxExpander"), "HitboxExpander", function(v) if not v then pcall(function() for _, tgt in ipairs(Players:GetPlayers()) do if tgt ~= player and tgt.Character and tgt.Character:FindFirstChild("HumanoidRootPart") then tgt.Character.HumanoidRootPart.Size = Vector3.new(2,2,1) tgt.Character.HumanoidRootPart.Transparency = 0 end end end) end end, "HitboxExpander")
  addSection(p, T("AimFOVValue"), "AimFOVValue")
  addSlider(p, T("AimFOVValue"), "AimFOVValue", 30, 360, false, nil, "AimFOVValue")
  addSlider(p, T("AimSmoothness"), "AimSmoothness", 1, 100, false, nil, "AimSmoothness")
  addSlider(p, T("HitboxSize"), "HitboxSize", 2, 50, false, nil, "HitboxSize")
  addSection(p, T("FieldOfView"), "FieldOfView")
  addSlider(p, T("FieldOfView"), "FieldOfView", 30, 120, false, function(val) camera.FieldOfView = val end, "FieldOfView")
end
do local p = pages["Movement"]
  addSection(p, T("Speed"), "Speed")
  addToggle(p, T("Speed"), "Speed", nil, "Speed")
  addSlider(p, T("SpeedValue"), "SpeedValue", 16, 200, false, nil, "SpeedValue")
  addSection(p, T("Fly"), "Fly")
  addToggle(p, T("Fly"), "Fly", function(v) updateFlyUI() if v then pcall(function() if getHum() then getHum().PlatformStand = true end end) else pcall(function() if getHum() then getHum().PlatformStand = false end end) end end, "Fly")
  addSlider(p, T("FlySpeed"), "FlySpeed", 10, 200, false, nil, "FlySpeed")
  addSection(p, T("LowGravity"), "LowGravity")
  addToggle(p, T("LowGravity"), "LowGravity", function(v) if not v then pcall(function() workspace.Gravity = 196.2 if getHum() then getHum().JumpPower = 50 end end) end end, "LowGravity")
  addSlider(p, T("LowGravityValue"), "LowGravityValue", 10, 200, false, function(val) if States.LowGravity then pcall(function() workspace.Gravity = val if getHum() then getHum().JumpPower = val * 2 end end) end end, "LowGravityValue")
  addSection(p, T("Freecam"), "Freecam")
  addToggle(p, T("Freecam"), "Freecam", function(v) updateFlyUI() if v then pcall(function() camera.CameraType = Enum.CameraType.Scriptable end) else pcall(function() camera.CameraType = Enum.CameraType.Custom end) end end, "Freecam")
  addSection(p, T("Noclip"), "Noclip")
  addToggle(p, T("Noclip"), "Noclip", function(v) if not v then pcall(function() if getChar() then for _, part in ipairs(getChar():GetDescendants()) do if part:IsA("BasePart") then part.CanCollide = true end end end end) end end, "Noclip")
  addSection(p, T("JumpPower"), "JumpPower")
  addToggle(p, T("JumpPower"), "JumpPower", function(v) if not v then pcall(function() if getHum() then getHum().JumpPower = 50 end end) end end, "JumpPower")
  addSlider(p, T("JumpPowerValue"), "JumpPowerValue", 50, 500, false, nil, "JumpPowerValue")
  addSection(p, T("InfiniteJump"), "InfiniteJump")
  addToggle(p, T("InfiniteJump"), "InfiniteJump", nil, "InfiniteJump")
  addSection(p, T("Teleport"), "Teleport")
  addButton(p, T("Teleport"), function() pcall(function() local m = player:GetMouse() if m.Hit and getHRP() then getHRP().CFrame = m.Hit + Vector3.new(0,3,0) end end) end, "Teleport")
  addToggle(p, T("ClickTeleport"), "ClickTeleport", nil, "ClickTeleport")
  addSection(p, T("Sprint"), "Sprint")
  addToggle(p, T("Sprint"), "Sprint", function(v) if not v then pcall(function() if getHum() then getHum().WalkSpeed = 16 end end) end end, "Sprint")
  addSlider(p, T("SprintSpeed"), "SprintSpeed", 20, 100, false, nil, "SprintSpeed")
  addSection(p, T("AntiVoid"), "AntiVoid")
  addToggle(p, T("AntiVoid"), "AntiVoid", nil, "AntiVoid")
end
do local p = pages["Utility"]
  addSection(p, T("AntiAFK"), "AntiAFK")
  addToggle(p, T("AntiAFK"), "AntiAFK", nil, "AntiAFK")
  addSection(p, T("FreezeTime"), "FreezeTime")
  addToggle(p, T("FreezeTime"), "FreezeTime", nil, "FreezeTime")
  addSection(p, T("FPSBoost"), "FPSBoost")
  addToggle(p, T("FPSBoost"), "FPSBoost", function(v) if v then pcall(function() settings().Rendering.QualityLevel = 1 for _, o in ipairs(Workspace:GetDescendants()) do if o:IsA("Texture") or o:IsA("Decal") then o.Transparency = 1 end if o:IsA("ParticleEmitter") or o:IsA("Trail") then o.Enabled = false end end end) notify(T("FPSBoost"), T("Enabled"), 2) else pcall(function() settings().Rendering.QualityLevel = 3 end) notify(T("FPSBoost"), T("Disabled"), 2) end end, "FPSBoost")
  addSection(p, T("AntiBlind"), "AntiBlind")
  addToggle(p, T("AntiBlind"), "AntiBlind", nil, "AntiBlind")
  addToggle(p, T("AntiSlow"), "AntiSlow", nil, "AntiSlow")
  addToggle(p, T("AntiRagdoll"), "AntiRagdoll", nil, "AntiRagdoll")
  addToggle(p, T("AntiGrab"), "AntiGrab", nil, "AntiGrab")
end
do local p = pages["Server"]
  addSection(p, T("RejoinServer"), "RejoinServer")
  addButton(p, T("RejoinServer"), function() notify(T("RejoinServer"), "Rejoining...", 2) pcall(function() TeleportService:Teleport(game.PlaceId, player) end) end, "RejoinServer")
  addButton(p, T("ServerHop"), function()
    notify(T("ServerHop"), "Finding server...", 2)
    pcall(function()
      local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
      local resp = game:HttpGet(url) local servers = HttpService:JSONDecode(resp)
      if servers and servers.data then for _, s in ipairs(servers.data) do if s.id ~= game.JobId and s.playing < s.maxPlayers then TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, player) return end end end
    end)
    notify(T("ServerHop"), "Failed - try again", 3)
  end, "ServerHop")
  addButton(p, T("JoinSmallServer"), function()
    notify(T("JoinSmallServer"), "Finding small server...", 2)
    pcall(function()
      local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
      local resp = game:HttpGet(url) local servers = HttpService:JSONDecode(resp)
      if servers and servers.data then local smallest = nil for _, s in ipairs(servers.data) do if s.id ~= game.JobId then if not smallest or s.playing < smallest.playing then smallest = s end end end if smallest then TeleportService:TeleportToPlaceInstance(game.PlaceId, smallest.id, player) end end
    end)
    notify(T("JoinSmallServer"), "Failed - try again", 3)
  end, "JoinSmallServer")
  addSection(p, T("Respawn"), "Respawn")
  addButton(p, T("Respawn"), function() pcall(function() if getHum() then getHum().Health = 0 notify(T("Respawn"), T("Enabled"), 2) end end) end, "Respawn")
  addButton(p, T("TeleportToSpawn"), function() pcall(function() local spawn = nil for _, o in ipairs(Workspace:GetChildren()) do if o:IsA("SpawnLocation") then spawn = o break end end if not spawn then spawn = Workspace:FindFirstChild("SpawnLocation") end if spawn and getHRP() then getHRP().CFrame = spawn.CFrame + Vector3.new(0,3,0) notify(T("TeleportToSpawn"), "Teleported!", 2) else notify(T("TeleportToSpawn"), "No spawn found!", 2) end end) end, "TeleportToSpawn")
  addSection(p, T("PlayerList"), "PlayerList")
  local spectateRow = nil
  local function buildSpectate()
    if spectateRow then pcall(function() spectateRow:Destroy() end) end
    local names = {} for _, pl in ipairs(Players:GetPlayers()) do if pl ~= player then table.insert(names, pl.Name) end end
    if #names == 0 then names = {"(No other players)"} end
    local row, _ = addDropdown(p, T("SpectatePlayer"), names, function(sel)
      local tgt = Players:FindFirstChild(sel)
      if tgt and tgt.Character and tgt.Character:FindFirstChild("Humanoid") then spectateTarget = tgt notify(T("SpectatePlayer"), sel, 2) end
    end, "SpectatePlayer")
    spectateRow = row
  end
  buildSpectate()
  addButton(p, T("RefreshPlayers"), function() buildSpectate() notify(T("RefreshPlayers"), tostring(#Players:GetPlayers()) .. " players", 2) end, "RefreshPlayers")
  addButton(p, T("StopSpectate"), function() spectateTarget = nil pcall(function() if getHum() then camera.CameraSubject = getHum() end end) notify(T("SpectatePlayer"), "Stopped", 2) end, "StopSpectate")
end
do local p = pages["Fun"]
  addSection(p, T("Spin"), "Spin")
  addToggle(p, T("Spin"), "Spin", nil, "Spin")
  addSlider(p, T("SpinSpeed"), "SpinSpeed", 1, 100, false, nil, "SpinSpeed")
  addSection(p, T("Float"), "Float")
  addToggle(p, T("Float"), "Float", function(v) if not v then pcall(function() if getHRP() then local bv = getHRP():FindFirstChild("FLUYEN_FloatBV") if bv then bv:Destroy() end end end) end end, "Float")
  addSection(p, T("Bang"), "Bang")
  addToggle(p, T("Bang"), "Bang", nil, "Bang")
  addSection(p, T("Fling"), "Fling")
  addButton(p, T("Fling"), function() pcall(function() if getHRP() then local fv = Vector3.new(math.random(-Values.FlingPower, Values.FlingPower), math.random(200, Values.FlingPower), math.random(-Values.FlingPower, Values.FlingPower)) pcall(function() getHRP().AssemblyLinearVelocity = fv end) pcall(function() getHRP().Velocity = fv end) end end) end, "Fling")
  addSlider(p, T("FlingPower"), "FlingPower", 100, 2000, false, nil, "FlingPower")
  addSection(p, T("OrbitPlayer"), "OrbitPlayer")
  local orbitRow = nil
  local function buildOrbit()
    if orbitRow then pcall(function() orbitRow:Destroy() end) end
    local names = {} for _, pl in ipairs(Players:GetPlayers()) do if pl ~= player then table.insert(names, pl.Name) end end
    if #names == 0 then names = {"(No other players)"} end
    local row, _ = addDropdown(p, T("OrbitPlayer"), names, function(sel) orbitTarget = Players:FindFirstChild(sel) notify(T("OrbitPlayer"), sel, 2) end, "OrbitPlayer")
    orbitRow = row
  end
  buildOrbit()
  addToggle(p, T("OrbitActive"), "OrbitActive", nil, "OrbitActive")
  addSlider(p, T("OrbitRadius"), "OrbitRadius", 1, 20, false, nil, "OrbitRadius")
  addSlider(p, T("OrbitSpeed"), "OrbitSpeed", 1, 20, false, nil, "OrbitSpeed")
  addSection(p, T("Invisible"), "Invisible")
  addToggle(p, T("Invisible"), "Invisible", function(v) pcall(function() if getChar() then for _, part in ipairs(getChar():GetDescendants()) do if part:IsA("BasePart") then part.Transparency = v and 1 or 0 end if part:IsA("Decal") or part:IsA("Texture") then part.Transparency = v and 1 or 0 end end if getChar():FindFirstChild("Head") then local f = getChar().Head:FindFirstChild("face") if f then f.Transparency = v and 1 or 0 end end end end) end, "Invisible")
end
do local p = pages["Settings"]
  addSection(p, T("KeySystem"), "KeySystem")
  addKeyInput(p)
  addSection(p, T("Theme"), "Theme")
  addDropdown(p, T("Theme"), {"Dark", "Light", "Sky Blue", "Galaxy", "Neon", "Midnight"}, function(sel)
    local m = { Dark="Dark", Light="Light", ["Sky Blue"]="SkyBlue", Galaxy="Galaxy", Neon="Neon", Midnight="Midnight" }
    currentTheme = m[sel] or "Dark" updateAllThemes() notify(T("Theme"), sel, 2)
  end, "Theme")
  addSection(p, T("Language"), "Language")
  addDropdown(p, T("Language"), {"English", "Tieng Viet", "Espanol", "Portugues", "Russkiy"}, function(sel)
    local m = { English="EN", ["Tieng Viet"]="VI", Espanol="ES", Portugues="PT", Russkiy="RU" }
    currentLang = m[sel] or "EN" updateAllLanguages() notify(T("Language"), sel, 2)
  end, "Language")
  addSection(p, T("Gesture"), "Gesture")
  addToggle(p, T("Gesture"), "GestureEnabled", function(v) notify(T("Gesture"), v and T("GestureOn") or T("GestureOff"), 2) if not v then gestureHint.Visible = false end end, "Gesture")
  local gestureModes = { T("Tap1"), T("Tap3"), T("Hold"), T("Swipe") }
  addDropdown(p, T("GestureMode"), gestureModes, function(sel, idx)
    local modes = { "Tap1", "Tap3", "Hold", "Swipe" }
    Values.GestureMode = modes[idx] or "Tap1" notify(T("GestureMode"), sel, 2)
  end, "GestureMode")
  local _, gVal = addInfoRow(p, T("GestureTest"), "Chua test - hay cham 3 ngon vao man hinh", "GestureTest")
  gestureTestLabel = gVal
  addButton(p, "👆 " .. T("GestureTest"), function() showGestureHint("👆 " .. T("GestureHint"), false) notify(T("GestureTest"), T("GestureHint"), 3) end, "GestureTest")
  addSection(p, T("GUI"), "GUI")
  addToggle(p, T("AutoLoadSettings"), "AutoLoadSettings", nil, "AutoLoadSettings")
  addToggle(p, T("MinimizeButton"), "MinimizeButton", function(v) miniBtn.Visible = v and not isOpen end, "MinimizeButton")
  addToggle(p, T("DraggableGUI"), "DraggableGUI", nil, "DraggableGUI")
  addToggle(p, T("Notifications"), "Notifications", nil, "Notifications")
  addToggle(p, T("QuickBar"), "QuickBar", function(v) quickBar.Visible = v end, "QuickBar")
  addToggle(p, T("ShowFPS"), "ShowFPS", nil, "ShowFPS")
  addToggle(p, T("ShowPing"), "ShowPing", nil, "ShowPing")
  addSection(p, T("SaveSettings"), "SaveSettings")
  addButton(p, T("SaveSettings"), function() saveSettings() end, "SaveSettings")
  addButton(p, T("ResetSettings"), function() resetSettings() end, "ResetSettings")
  addButton(p, T("CheckUpdate"), function() checkUpdate() end, "CheckUpdate")
  addButton(p, T("CopyID"), function() pcall(function() if setclipboard then setclipboard(tostring(player.UserId)) notify(T("CopyID"), tostring(player.UserId), 2) else notify(T("CopyID"), tostring(player.UserId), 2) end end) end, "CopyID")
  addButton(p, "🚨  " .. T("Panic"), function() for k, v in pairs(States) do if type(v) == "boolean" and k ~= "AntiAFK" and k ~= "MinimizeButton" and k ~= "DraggableGUI" and k ~= "Notifications" and k ~= "QuickBar" and k ~= "GestureEnabled" and k ~= "AutoLoadSettings" then if v == true then setFeature(k, false) end end end refreshAllToggles() notify("PANIC", T("AllOff"), 2) end)
  addButton(p, "❌ " .. T("Unload"), function() unloadMenu() end, "Unload")
  addSection(p, T("ToggleKeybind"), "ToggleKeybind")
  addInfoRow(p, T("ToggleKeybind"), "3 ngon (chon kieu o tren) / Insert / Nut F", "ToggleKeybind")
end
-- ============ INIT ============
recalcCurrentPage()
_delay(1, function() for _, pg in pairs(pages) do recalcPage(pg) end end)
_delay(3, function() for _, pg in pairs(pages) do recalcPage(pg) end end)
_delay(0.5, function() if States.MinimizeButton then miniBtn.Visible = true end if States.QuickBar then quickBar.Visible = true end end)
updateAllThemes() updateAllLanguages() refreshAllToggles() updateFlyUI()
-- Auto-load local
_spawn(function()
  _wait(0.5)
  local ok, data = pcall(function() return readfile("FLUYEN_settings.json") end)
  if ok and data then pcall(function() local s = HttpService:JSONDecode(data) applySettingsTable(s) updateAllThemes() updateAllLanguages() refreshAllToggles() end) end
  if keyAuthenticated then
    _wait(1)
    local cloud = supaLoadSettings()
    if cloud then pcall(function() applySettingsTable(cloud) updateAllThemes() updateAllLanguages() refreshAllToggles() notify("Cloud", T("SavedCloud"), 2) end) end
  end
end)
-- Anti-AFK luon bat neu States.AntiAFK
player.Idled:Connect(function() if States.AntiAFK then pcall(function() VirtualUser:CaptureController() VirtualUser:ClickButton2(Vector2.new(0,0)) end) end end)
-- Check update nhe (khong chan load)
_spawn(function() _wait(4) pcall(function() local v = supaFetchVersion() if v and v.version and v.version ~= SCRIPT_VERSION then notify("🎉 " .. T("UpdateAvailable"), tostring(v.version) .. " - vao Settings > Check Update", 5) end end) end)
_spawn(function() _wait(1) notify(SCRIPT_NAME, SCRIPT_VERSION .. " " .. T("Loaded"), 4) end)
end)
if not _ok then
  warn("[FLUYEN] Script error: " .. tostring(_err))
  pcall(function()
    local pg = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
    if pg then local sg = Instance.new("ScreenGui") sg.Name = "FLUYEN_Error" sg.ResetOnSpawn = false sg.Parent = pg local tl = Instance.new("TextLabel") tl.Size = UDim2.new(0.8, 0, 0, 60) tl.Position = UDim2.new(0.1, 0, 0.1, 0) tl.BackgroundColor3 = Color3.fromRGB(200,50,50) tl.TextColor3 = Color3.fromRGB(255,255,255) tl.Font = Enum.Font.GothamBold tl.TextSize = 12 tl.TextWrapped = true tl.Text = "[FLUYEN Error] " .. tostring(_err) tl.Parent = sg local cn = Instance.new("UICorner") cn.CornerRadius = UDim.new(0, 6) cn.Parent = tl end
  end)
else
  print("[FLUYEN] Script loaded successfully! v6.0")
end

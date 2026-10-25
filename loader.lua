--[[
    TELEPORT WAYPOINT PRO - LOADER
]]

local scriptURL = "https://raw.githubusercontent.com/nguyenkhanhhuy623-crypto/teleport/refs/heads/main/Teleport_Waypoint_Pro.lua"

local success, err = pcall(function()
    loadstring(game:HttpGet(scriptURL))()
end)

if not success then
    warn("[Teleport Waypoint Pro] Failed to load script:")
    warn(err)
end

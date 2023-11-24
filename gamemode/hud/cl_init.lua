-- Draw all the custom HUD elements
if not Config.UseBuiltinHUDRendering then
    print("B2CTF Builtin HUD rendering is disabled")
    return
end

local timerHUD = include("modules/timer_hud.lua")
local homeIndicator = include("modules/home_indicator.lua")
local entityCreator = include("modules/entity_creator.lua")

-- Init stuff
timerHUD:Init()

-- Hack: it is possible that a client might miss the initial phase transition because of how files loaded in order
local currentPhaseInfo = Phaser:CurrentPhaseInfo()
if currentPhaseInfo then
    timerHUD:UpdateInfo(currentPhaseInfo.name, Phaser:CurrentPhaseStart(), Phaser:CurrentPhaseEnd(), currentPhaseInfo.warnTime)
end

homeIndicator:Init()
entityCreator:Init()

-- Setup hooks
local function DrawB2CTFHUD()
    if hook.Run("HUDShouldDraw", GAMEMODE, "B2CTFTimer") then
        timerHUD:Draw()
    end
    if hook.Run("HUDShouldDraw", GAMEMODE, "B2CTFHomeIndicator") then
        homeIndicator:Draw()
    end
    if hook.Run("HUDShouldDraw", GAMEMODE, "B2CTFEntityCreator") then
        entityCreator:Draw()
    end

end
hook.Add("HUDPaint", "B2CTF_HUD", DrawB2CTFHUD)

hook.Add("B2CTF_PhaseChanged", "UpdateHudValues", function(newPhaseID, newPhaseInfo, oldPhaseID, oldPhaseInfo, startTime, endTime)
    timerHUD:UpdateInfo(newPhaseInfo.name, startTime, endTime, newPhaseInfo.warnTime)
end )

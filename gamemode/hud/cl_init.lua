-- Draw all the custom HUD elements
if not Config.UseBuiltinHUDRendering then
    print("B2CTF Builtin HUD rendering is disabled")
    return
end

-- Create the hudManager singleton
local hudManager = include("cl_hud_manager.lua")

-- register elements
hudManager:RegisterElement("B2CTFTimerHUD", include("modules/timer_hud.lua"))
hudManager:RegisterElement("B2CTFHomeIndicator", include("modules/home_indicator.lua"))
hudManager:RegisterElement("B2CTFFlagsIndicator", include("modules/flags_indicator.lua"))
hudManager:RegisterElement("B2CTFEntityCreator", include("modules/entity_creator.lua"))

-- Hook up the hud manager...
hook.Add("InitPostEntity", "B2CTF_InitHUDManager", function()
    hudManager:Init()
end )

hook.Add("OnReloaded", "B2CTF_ReinitHUDManager", function()
    hudManager:Init()
end )

hook.Add("HUDPaint", "B2CTF_HUDDraw", function()
    hudManager:Draw()
end )

hook.Add("B2CTF_PhaseChanged", "UpdateHudValues", function(newPhaseID, newPhaseInfo, oldPhaseID, oldPhaseInfo, startTime, endTime)
    hudManager:OnPhaseChanged(newPhaseID, newPhaseInfo, oldPhaseID, oldPhaseInfo, startTime, endTime)
end )

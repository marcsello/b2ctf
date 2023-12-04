-- this is just to add the lua files
if not Config.UseBuiltinHUDRendering then
    print("B2CTF Builtin HUD rendering is disabled")
    return
end

AddCSLuaFile("cl_hud_manager.lua")

-- include the modules
AddCSLuaFile("modules/entity_creator.lua")
AddCSLuaFile("modules/home_indicator.lua")
AddCSLuaFile("modules/flags_indicator.lua")
AddCSLuaFile("modules/timer_hud.lua")

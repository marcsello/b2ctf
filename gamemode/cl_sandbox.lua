-- Client-side overrides for the sandbox gamemode

local function preventWhenNotBuilding(...)
    if not (LocalPlayer() and IsValid(LocalPlayer())) then return end

    if not LocalPlayer():CurrentlyBuilding() then
        return false
    end
end

hook.Add("SpawnMenuOpen", "B2CTF_SpawnMenuCheck", preventWhenNotBuilding)
hook.Add("CanDrive", "B2CTF_DriveCheck", preventWhenNotBuilding)
hook.Add("CanTool", "B2CTF_ToolCheck", preventWhenNotBuilding)
hook.Add("CanProperty", "B2CTF_PropertyCheck", preventWhenNotBuilding)
hook.Add("CanArmDupe", "B2CTF_DupeCheck", preventWhenNotBuilding)

hook.Add( "PlayerBindPress", "B2CTF_CanUndo", function( ply, bind )
    if not (LocalPlayer() and IsValid(LocalPlayer())) then return end

    if ply == LocalPlayer() and bind == "gmod_undo" then
        if not ply:CurrentlyBuilding() then
            return true -- true to prevent
        end
    end
end )

hook.Add("B2CTF_PhaseChanged", "CloseSandboxMenus", function(newPhase, info, start_time, end_time)
    if not info.buildAllowed then
        -- hide menu if building is not allowed in the new phase
        RunConsoleCommand("-menu")
    end
end)

include("sh_sandbox.lua")

-- Server-side overrides for the sandbox gamemode

local function denyWhenNotBuilding(ply, ...)
    if not ply:CurrentlyBuilding() then
        return false
    end
end


hook.Add("PlayerSpawnEffect", "B2CTF_SpawnObjectCheck", denyWhenNotBuilding)
hook.Add("PlayerSpawnNPC", "B2CTF_SpawnObjectCheck", denyWhenNotBuilding)
hook.Add("PlayerSpawnObject", "B2CTF_SpawnObjectCheck", denyWhenNotBuilding)
hook.Add("PlayerSpawnProp", "B2CTF_SpawnPropCheck", denyWhenNotBuilding)
hook.Add("PlayerSpawnRagdoll", "B2CTF_SpawnPropCheck", denyWhenNotBuilding)
hook.Add("PlayerSpawnSENT", "B2CTF_SpawnPropCheck", denyWhenNotBuilding)
hook.Add("PlayerSpawnSWEP", "B2CTF_SpawnPropCheck", denyWhenNotBuilding)
hook.Add("PlayerSpawnVehicle", "B2CTF_SpawnPropCheck", denyWhenNotBuilding)
hook.Add("CanArmDupe", "B2CTF_DupeCheck", denyWhenNotBuilding)
hook.Add("CanDrive", "B2CTF_DriveCheck", denyWhenNotBuilding)
hook.Add("CanProperty", "B2CTF_PropertyCheck", denyWhenNotBuilding)
hook.Add("CanTool", "B2CTF_ToolCheck", denyWhenNotBuilding)
hook.Add("CanUndo", "B2CTF_UndoCheck", denyWhenNotBuilding)

hook.Add("B2CTF_PhaseChanged", "AddOrRemoveSandboxWeapons", function(newPhase, info, start_time, end_time)
    if info.buildAllowed then
        for _, v in ipairs( player.GetAll() ) do
            v:Give("gmod_tool")
            v:Give("weapon_physgun")
        end
    else
        for _, v in ipairs( player.GetAll() ) do
            v:StripWeapon("gmod_tool")
            v:StripWeapon("weapon_physgun")
        end
    end
end)

function GM:PlayerLoadout( ply )
    ply:Give( "weapon_pistol" )
    ply:Give( "weapon_crowbar" )
    ply:Give( "weapon_shotgun" )
    ply:Give( "weapon_smg1" )
    ply:Give( "weapon_medkit" )
    ply:Give( "weapon_physcannon" )

    if Phaser:CurrentPhaseInfo().buildAllowed then
        -- give toolgun and physgun only when build is allowed
        ply:Give("gmod_tool")
        ply:Give("weapon_physgun")
    end

    -- Prevent default Loadout.
    return true
end

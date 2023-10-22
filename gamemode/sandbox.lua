-- Server-side overrides for the sandbox gamemode

-- Deny sandbox functions when not building
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

-- Weapon magic

hook.Add("B2CTF_PhaseChanged", "AddOrRemoveSandboxWeapons", function(newPhase, info, start_time, end_time)
    for _, v in ipairs( player.GetAll() ) do
        if (not IsValid(v)) or (not v:TeamValid()) or (not v:Alive()) then return end -- don't give weapons to invalid, spectator or dead players

        if info.buildAllowed then
            v:Give("gmod_tool")
            v:Give("weapon_physgun")
            v:StripWeapon("b2ctf_unfreezer")
        else
            v:StripWeapon("gmod_tool")
            v:StripWeapon("weapon_physgun")
            v:Give("b2ctf_unfreezer")
        end
    end
end)

function GM:PlayerLoadout( ply )
    if not ply:TeamValid() then return true end -- spectators don't have a loadout

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
    else
        ply:Give("b2ctf_unfreezer")
    end

    -- Prevent default Loadout.
    return true
end


hook.Add( "PlayerCanPickupWeapon", "B2CTF_CheckPickup", function( ply, weapon )
    local c = weapon:GetClass()
    if (c == "weapon_physgun") or (c == "gmod_tool") then
        if not Phaser:CurrentPhaseInfo().buildAllowed then
            return false -- dont let them pick up these forbidden weapons
        end
    end
end )

-- physgun magic

-- This is needed to set the creator, as it is only set for SENTs by sandbox
local function storeCreator3(ply, _, ent)
    ent:B2CTFSetCreator(ply)
end
local function storeCreator2(ply, ent)
    ent:B2CTFSetCreator(ply)
end

hook.Add( "PlayerSpawnedEffect", "B2CTF_StoreEffectCreator", storeCreator3)
hook.Add( "PlayerSpawnedNPC", "B2CTF_StoreNPCCreator", storeCreator2)
hook.Add( "PlayerSpawnedProp", "B2CTF_StorePropCreator", storeCreator3)
hook.Add( "PlayerSpawnedRagdoll", "B2CTF_StoreRagdollCreator", storeCreator3)
hook.Add( "PlayerSpawnedSWEP", "B2CTF_StoreSWEPCreator", storeCreator2)
hook.Add( "PlayerSpawnedSENT", "B2CTF_StoreSENTCreator", storeCreator2)
hook.Add( "PlayerSpawnedVehicle", "B2CTF_StoreVehicleCreator", storeCreator2)


include("sh_sandbox.lua")

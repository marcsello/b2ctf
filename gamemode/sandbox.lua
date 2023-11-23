-- Server-side overrides for the sandbox gamemode

-- Deny sandbox functions when not building
-- This function is copied to the shared file
local function denyWhenNotBuilding(ply, ...)
    if (not IsValid(ply)) or (not ply:TeamValid()) then return false end
    if not ply:CurrentlyBuilding() then
        return false
    end
end

hook.Add("PlayerSpawnEffect", "B2CTF_DenySpawnWhenNotBuilding", denyWhenNotBuilding)
hook.Add("PlayerSpawnNPC", "B2CTF_DenySpawnWhenNotBuilding", denyWhenNotBuilding)
hook.Add("PlayerSpawnObject", "B2CTF_DenySpawnWhenNotBuilding", denyWhenNotBuilding)
hook.Add("PlayerSpawnProp", "B2CTF_DenySpawnWhenNotBuilding", denyWhenNotBuilding)
hook.Add("PlayerSpawnRagdoll", "B2CTF_DenySpawnWhenNotBuilding", denyWhenNotBuilding)
hook.Add("PlayerSpawnSENT", "B2CTF_DenySpawnWhenNotBuilding", denyWhenNotBuilding)
hook.Add("PlayerSpawnSWEP", "B2CTF_DenySpawnWhenNotBuilding", denyWhenNotBuilding)
hook.Add("PlayerSpawnVehicle", "B2CTF_DenySpawnWhenNotBuilding", denyWhenNotBuilding)
hook.Add("CanArmDupe", "B2CTF_DupeCheckWhenNotBuilding", denyWhenNotBuilding)
hook.Add("CanUndo", "B2CTF_UndoCheckWhenNotBuilding", denyWhenNotBuilding)
hook.Add("CanEditVariable", "B2CTF_EditVarCheckWhenNotBuilding", function( ent, ply, key, val, editor )
    return denyWhenNotBuilding(ply)
end )
hook.Add("OnPhysgunReload", "B2CTF_PhysgunReloadCheckWhenNotBuilding", function( physgun, ply )
    -- this hook is not called by the battle unfreezer
    return denyWhenNotBuilding(ply)
end )

include("sh_sandbox.lua")

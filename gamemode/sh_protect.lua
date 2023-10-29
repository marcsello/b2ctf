-- homebrew "prop protection"

local useBuiltinProtectionConvar = CreateConVar("b2ctf_use_builtin_protection", "1", FCVAR_REPLICATED + FCVAR_NOT_CONNECTED, "Use builtin protection")

if not useBuiltinProtectionConvar:GetBool() then
    print("B2CTF Builtin prop protection is disabled")
    return
end

-- Since this is a pretty offensive gamemod, we only limit a few things, like using physgun on other teams props
-- But damage, use, etc. is allowed

local function checkTeamAllowed(ply, ent) -- check if entity is created by the player's team
    if (not IsValid(ply)) or (not IsValid(ent)) or (not ply:TeamValid()) then return false end -- don't allow if we don't know the players team

    local entCreator = ent:B2CTFGetCreator()
    if not (entCreator and IsValid(entCreator) and entCreator:IsPlayer() and entCreator:TeamValid()) then return false end -- only allow touching stuffs spawned by valid players in valid teams

    return entCreator:Team() == ply:Team()
end


hook.Add( "PhysgunPickup", "B2CTF_ProtectPhysPickup", function( ply, ent )
    -- allow touching team stuff only
    if not checkTeamAllowed(ply, ent) then
        return false
    end
end )

hook.Add("CanProperty", "B2CTF_ProtectProperty", function( ply, property, ent )
    -- allow property stuff team stuff only
    if not checkTeamAllowed(ply, ent) then
        return false
    end
end )


hook.Add("CanTool", "B2CTF_ProtectTool", function( ply, tr, toolname, tool, button )
    if not IsValid( tr.Entity ) then return end
    -- allow tool meming team stuff only
    if not checkTeamAllowed(ply, tr.Entity) then
        return false
    end
end )

if SERVER then

    hook.Add("OnPhysgunFreeze", "B2CTF_ProtectFreeze", function( weapon, phys, ent, ply )
        if not checkTeamAllowed(ply, ent) then
            return false
        end
    end )

    hook.Add("CanPlayerUnfreeze", "B2CTF_ProtectUnFreeze", function( ply, ent, phys )
        if not checkTeamAllowed(ply, ent) then
            return false
        end
    end )

end

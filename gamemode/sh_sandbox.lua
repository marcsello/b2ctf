-- Shared stuff for sandbox restrictions. Included at the end of sandbox.lua and cl_sandbox.lua NOT shared.lua

hook.Add( "PhysgunPickup", "B2CTF_PickupCheck", function( ply, ent )
    print(ent)
    if (not IsValid(ply)) or (not IsValid(ent)) or (not ply:TeamValid()) then return false end -- don't allow if we don't know the players team
    if not Phaser:CurrentPhaseInfo().buildAllowed then return false end -- don't allow physgun during war
    local entCreator = ent:B2CTFGetCreator()
    print(entCreator)
    if (not IsValid(entCreator)) or (not entCreator:IsPlayer()) or (not entCreator:TeamValid()) then return false end -- only allow touching stuffs spawned by players

    -- allow touching team stuff only
    if entCreator:Team() != ply:Team() then
        return false
    end

end )

-- Loadout stuff

local DEFAULT_WEAPONS = { -- everything except toolgun, physugn and the battle unfreezer
   "weapon_crowbar",
   "weapon_pistol",
   "weapon_357",
   "weapon_shotgun",
   "weapon_smg1",
   "weapon_medkit",
   "weapon_physcannon",
}

local DEFAULT_AMMO = {
    ["Pistol"] = 25, -- pistol ammo
    ["357"] = 21, -- revolver ammo
    ["Buckshot"] = 16, -- shotgun ammo
    ["SMG1"] = 90,  -- smg1 ammo
}

local function plySetTools(ply, buildAllowed)
    if buildAllowed then
        -- give toolgun and physgun only when build is allowed
        ply:Give("gmod_tool")
        ply:Give("weapon_physgun")
        ply:StripWeapon("b2ctf_unfreezer")
    else
        ply:StripWeapon("gmod_tool")
        ply:StripWeapon("weapon_physgun")
        ply:Give("b2ctf_unfreezer")
    end
end

hook.Add("B2CTF_PhaseChanged", "AddOrRemoveSandboxWeapons", function(newPhaseID, newPhaseInfo, oldPhaseID, oldPhaseInfo, startTime, endTime)
    for _, v in ipairs( player.GetAll() ) do
        if (not IsValid(v)) or (not v:TeamValid()) or (not v:Alive()) then return end -- don't give weapons to invalid, spectator or dead players
        plySetTools(v, newPhaseInfo.buildAllowed)
    end
end)

function GM:PlayerLoadout( ply )
    -- Called after PlayerSpawn hook
    if not ply:TeamValid() then return true end -- spectators don't have a loadout

    local buildAllowed = Phaser:CurrentPhaseInfo().buildAllowed

    local overriden = hook.Run("B2CTF_PlayerLoadout", ply, buildAllowed) -- this is similar to PlayerLoadout hook except the toolgun/physgun/unfreezer are not should be added here

    if overriden == nil then
        -- no override: give "default" loadout
        for _, wep in ipairs(DEFAULT_WEAPONS) do
            -- only give weapon if the player is not already having it
            if not ply:HasWeapon(wep) then
                ply:Give(wep)
            end
        end
        for ammoType, ammoAmount in pairs(DEFAULT_AMMO) do
            -- only "refill" ammo if the player have less than expected
            if ply:GetAmmoCount(ammoType) < ammoAmount then
                ply:SetAmmo(ammoAmount, ammoType)
            end
        end
    end

    plySetTools(ply, buildAllowed)

    -- Prevent default Loadout.
    return true
end

hook.Add( "PlayerCanPickupWeapon", "B2CTF_CheckPickup", function( ply, weapon )
    local c = weapon:GetClass()
    if (c == "weapon_physgun") or (c == "gmod_tool") then
        if not ply:CurrentlyBuilding() then
            return false -- dont let them pick up these forbidden weapons
        end
    end
end )

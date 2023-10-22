if CLIENT then return end

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
AddCSLuaFile("sh_player.lua")
AddCSLuaFile("cl_sandbox.lua")
AddCSLuaFile("sh_phaser.lua")
AddCSLuaFile("cl_hud.lua")
AddCSLuaFile("cl_boundaries.lua")
AddCSLuaFile("sh_entity.lua")
AddCSLuaFile("sh_protect.lua")
AddCSLuaFile("sh_sandbox.lua") -- Included by sandbox.lua and cl_sandbox.lua


-- If there is a mapfile send it to the client (we define b2ctf specific settings here)
if file.Exists("b2ctf/gamemode/maps/" .. game.GetMap() .. ".lua", "LUA") then 
	AddCSLuaFile("maps/" .. game.GetMap() .. ".lua")
end

-- Run other server-side scripts
include("shared.lua")
include("sandbox.lua")
include("team_spawn.lua")
include("boundaries.lua")
include("entity.lua")


-- Everyone should spawn as spectator, and have to use the join menu to join a team
function GM:PlayerInitialSpawn(ply)
	if ply:Team() == TEAM_UNASSIGNED or ply:Team() == TEAM_CONNECTING then
		ply:SetTeam(TEAM_SPECTATOR)
		GAMEMODE:PlayerSpawnAsSpectator(ply)
	end
end

-- Still creator stuff, what to do when user leaves
local function reassignStuff(ply, teamID)
	local playersLeftInTeam = team.GetPlayers(teamID)
	local teamName = team.GetName(teamID)
	local newPly = nil

	if playersLeftInTeam and #playersLeftInTeam > 0 then
		for _, p in ipairs(playersLeftInTeam) do
			-- This hook is called before the actual team change, so it is possible, that the player is still assigned to their old team
			if p ~= ply then
				newPly = p -- TODO: Randomize?
			end
		end
	end

	local msg = nil
	if newPly then
		-- found someone to have stuff reassigned to
		local anythingReassigned = false
		for _, v in ipairs(ents.GetAll()) do
			if v:B2CTFGetCreator() == ply then
				v:B2CTFSetCreator(newPly)

				if v.GetCreator and v:GetCreator() then
					-- Support changing gmod side stuff as well
					v.SetCreator(newPly)
				end

				anythingReassigned = true
			end
		end

		if anythingReassigned then msg = ply:Nick() .. " has left team " .. teamName .. ". Their stuff is reassigned to " .. newPly:Nick() end
	else
		-- no players left in team, remove player's stuff
		local anythingRemoved = false
		for _, v in ipairs(ents.GetAll()) do
			if v:B2CTFGetCreator() == ply then
				v:Remove()
				anythingRemoved = true
			end
		end

		if anythingRemoved then msg = ply:Nick() .. " was the last player in team " .. teamName .. ". Removed all their stuff!" end
	end

	if msg then
		PrintMessage(HUD_PRINTTALK, msg)
		print(msg) -- server console too
	end
end

hook.Add("PlayerChangedTeam", "B2CTF_ReassignCreatedEntsOnTeamChange", function(ply, oldTeam, newTeam)
		if not (ply and IsValid(ply) and ply:TeamValid()) then return end
		if oldTeam < 1 or oldTeam > 1000 or (not team.Valid(oldTeam)) then return end
		reassignStuff(ply, oldTeam)
end )

hook.Add("PlayerDisconnected", "B2CTF_ReassignCreatedEntsOnLeave", function(ply)
		if not (ply and IsValid(ply) and ply:TeamValid()) then return end
		reassignStuff(ply, ply:Team())
end )


-- Loadout stuff

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
        if not ply:CurrentlyBuilding() then
            return false -- dont let them pick up these forbidden weapons
        end
    end
end )

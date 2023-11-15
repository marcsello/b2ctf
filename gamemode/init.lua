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
AddCSLuaFile("sh_flag.lua")
AddCSLuaFile("cl_flag.lua")
AddCSLuaFile("cl_limits.lua")
AddCSLuaFile("sh_flag_protect.lua")
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
include("cc.lua")
include("limits.lua")

function GM:ResetGame()
    -- Reset business logic
    Phaser:Reset()
    FlagManager:Reset()

    -- Reset team scores
    for i, v in pairs(team.GetAllTeams()) do  -- teams aren't a continous array, so we need pairs instead of ipairs
        team.SetScore( i, 0 ) -- yes, this resets spectators, connecting etc. scores too
    end

    -- TODO: Reset player stats? and unassign them from their teams?

    -- Cleanup things (copied from here: https://github.com/Facepunch/garrysmod/blob/e189f14c088298ca800136fcfcfaf5d8535b6648/garrysmod/lua/includes/modules/cleanup.lua#L148)
    for key, ply in pairs( cleanup.GetList() ) do
        for _, t in pairs( ply ) do
            for __, ent in pairs( t ) do
                if ( IsValid( ent ) ) then ent:Remove() end
            end
            table.Empty( t )
        end
    end
    game.CleanUpMap()

    PrintMessage(HUD_PRINTTALK, "The game has been reset")
end

-- What to do when user leaves
local function reassignStuff(ply, teamID, isPlyLeftTheGame)
	local playersLeftInTeam = team.GetPlayers(teamID)
	local teamName = team.GetName(teamID)
	local newPly = nil

	if playersLeftInTeam and #playersLeftInTeam > 0 then
		for _, p in ipairs(playersLeftInTeam) do
			-- This hook is called before the actual team change, so it is possible, that the player is still assigned to their old team
			if p ~= ply then -- ignore self
				newPly = p -- TODO: Randomize?
			end
		end
	end

	local msg = nil
	if newPly and IsValid(newPly) then
		-- found someone to have stuff reassigned to
		local anythingReassigned = false
		for _, v in ipairs(ents.GetAll()) do -- TODO: Replace with ents.Iterator() when released
			if v:B2CTFGetCreator() == ply then
				v:B2CTFSetCreator(newPly)

				if v.GetCreator and v:GetCreator() then
					-- Support changing gmod side stuff as well
					v.SetCreator(newPly)
				end

				anythingReassigned = true
			end
		end

        -- clean player's undo list if they changed teams, and their stuff got re-assigned
        -- If their stuff is not getting re-assigned then it is going to be deleted anyway 
        -- so we don't care about the undo list in that case
        local plyUID = ply:UniqueID() -- the id if the player who left the team
        if not isPlyLeftTheGame then
            undo.GetTable()[plyUID] = {}
            -- There isn't really a nice way to do this, and I'm lazy to setup a network thingy for that
            -- And Gmod source uses this pretty often
            ply:SendLua("table.Empty(undo.GetTable()) undo.MakeUIDirty()")
        end

        -- copy items from the players cleanup list to the new players cleanup list
        -- so when they press clean up everything, their newly assigned props will be cleaned up as well
        local cleanupListToBeReassigned = cleanup.GetList()[plyUID]
        local newPlyUID = newPly:UniqueID()
        if not cleanup.GetList()[newPlyUID] then
            cleanup.GetList()[newPlyUID] = {}
        end
        for undoType, undoList in pairs(cleanupListToBeReassigned) do
            if not cleanup.GetList()[newPlyUID][undoType] then
                cleanup.GetList()[newPlyUID][undoType] = {}
            end
            for _, undoItem in ipairs(undoList) do
                if IsValid(undoItem) then -- sometimes when the entites are removed they are not cleaned up from the cleanup list, prevent cluttering the new player's cleanup list with those
                    table.insert(cleanup.GetList()[newPlyUID][undoType], undoItem)
                end
            end
        end
        cleanup.GetList()[plyUID] = {} -- clean old list

		if anythingReassigned then msg = ply:Nick() .. " has left team " .. teamName .. ". Their stuff is reassigned to " .. newPly:Nick() end
	else
		-- no players left in team, remove player's stuff
		local anythingRemoved = false
		for _, v in ipairs(ents.GetAll()) do -- TODO: Replace with ents.Iterator() when released
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

local function resetTeamScoreIfThisWasTheLastPlayer(ply, teamID)
    if not (teamID ~= nil and teamID > 0 and teamID < 1000 and team.Valid(teamID)) then return end -- it is possible that the team info lost when the player disconnects

    local players = team.GetPlayers(teamID)
    local cnt = #players
    if table.HasValue(players, ply) then
        cnt = cnt -1
    end

    if cnt <= 0 and team.GetScore(teamID) ~= 0 then
        local msg = ply:Nick() .. " was the last member of " .. team.GetName(teamID) .. " team. Resetting team score."
        print(msg)
        PrintMessage(HUD_PRINTTALK, msg)
        team.SetScore(teamID, 0)
    end

end

hook.Add("PlayerChangedTeam", "B2CTF_ReassignCreatedEntsOnTeamChange", function(ply, oldTeam, newTeam)
        if not (ply and IsValid(ply) and ply:TeamValid()) then return end
        if oldTeam < 1 or oldTeam > 1000 or (not team.Valid(oldTeam)) then return end
        reassignStuff(ply, oldTeam, false)
        resetTeamScoreIfThisWasTheLastPlayer(ply, oldTeam)
end )

hook.Add("PlayerDisconnected", "B2CTF_ReassignCreatedEntsOnLeaveOrCleanup", function(ply)
        if not (ply and IsValid(ply) and ply:TeamValid()) then return end
        if player.GetCount() <= 1 then
            -- This was the last online player, reset the game
            print("Last player disconnected, resetting game...")
            GAMEMODE:ResetGame()
        else
            reassignStuff(ply, ply:Team(), true)
            resetTeamScoreIfThisWasTheLastPlayer(ply, ply:Team())
        end
end )


-- Loadout stuff

hook.Add("B2CTF_PhaseChanged", "AddOrRemoveSandboxWeapons", function(newPhaseID, newPhaseInfo, oldPhaseID, oldPhaseInfo, startTime, endTime)
    for _, v in ipairs( player.GetAll() ) do
        if (not IsValid(v)) or (not v:TeamValid()) or (not v:Alive()) then return end -- don't give weapons to invalid, spectator or dead players

        if newPhaseInfo.buildAllowed then
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
    -- Called after PlayerSpawn hook
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

-- Controlling damage stuff

hook.Add( "PlayerShouldTakeDamage", "B2CTF_BuildersShouldNotFight", function( ply, attacker )
    if not (ply and IsValid(ply) and ply:IsPlayer()) then return end -- only check if the player is a valid player

    if not ply:TeamValid() then
        -- Block damage if the player does not have a valid team
        return false
    end

    if not (attacker and IsValid(attacker) and attacker:IsPlayer()) then return end -- only check the remaining when the attacker is a player

    if ply == attacker then
        -- Can't do much about people hurting themselves.
        -- self-damage is also used by some scripted hurt triggers, so we should allow those
        return
    end

    if not attacker:TeamValid() then
        -- Block damage if the attacker does not have a valid team
        return false
    end

    -- The following might seem unneeded as CurrentlyBuilding() check already covers it
    -- But pre- and post-war the players arent building, but should not be hurt either

    if not Phaser:CurrentPhaseInfo().fightAllowed then
        -- Block damage if fight is disallowed in the current phase
        return false
    end

    if ply:CurrentlyBuilding() or attacker:CurrentlyBuilding() then
        -- Also, block damage, if either the attacker or the victim is currently building
        return false
    end

end )

hook.Add( "CanPlayerSuicide", "B2CTF_SpectatorsShouldntSuicide", function( ply )
    if not (ply and IsValid(ply) and ply:TeamValid()) then return false end -- players without a valid team should not be able to suicide
end )

-- TODO: Put this somewhere else!
-- Used by cl_flags
util.PrecacheModel("models/props_canal/canal_cap001.mdl")
util.PrecacheModel("models/props_c17/statue_horse.mdl")

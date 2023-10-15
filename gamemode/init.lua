AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "sh_player.lua" )
AddCSLuaFile( "cl_sandbox.lua" )
AddCSLuaFile( "sh_phaser.lua" )

-- If there is a mapfile send it to the client (we define b2ctf specific settings here)
if file.Exists("b2ctf/gamemode/maps/" .. game.GetMap() .. ".lua", "LUA") then
	AddCSLuaFile("maps/" .. game.GetMap() .. ".lua")
end


include("shared.lua")
include("sandbox.lua")
include("team_spawn.lua")
include("team_site.lua")


-- Everyone should spawn as spectator, and have to use the join menu to join a team
function GM:PlayerInitialSpawn( ply )
	if ply:Team() == TEAM_UNASSIGNED or ply:Team() == TEAM_CONNECTING then
		ply:SetTeam(TEAM_SPECTATOR)
		GAMEMODE:PlayerSpawnAsSpectator( ply )
	end
end



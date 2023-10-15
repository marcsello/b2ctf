-- Copied from here: https://github.com/CFC-Servers/cfc_random_spawn/blob/eb62a6565fd975d16f086ce5d3f0cedc96137113/lua/cfc_random_spawn/module/sv_player_spawning.lua#L133
local function findFreeSpawnPoints( spawns )
	local CLOSENESS_LIMIT = 30 -- we only need to check for the size of a player, there are possibly teammates around
	local trimmedSpawns = {}

	for _, spawnPos in ipairs( spawns ) do
		local plyTooClose = false

		for _, ply in ipairs( player.GetAll() ) do
			if not (IsValid(ply) and ply:Alive()) then continue end

			if ply:GetPos():DistToSqr( spawnPos ) < CLOSENESS_LIMIT then
				plyTooClose = true
				break
			end
		end

		if not plyTooClose then
			table.insert( trimmedSpawns, spawn )
		end
	end

	if #trimmedSpawns == 0 then return spawns end -- If all spawnpoints are full, just return all of them. Super rare case.

	return trimmedSpawns
end

hook.Add("PlayerSpawn", "B2CTF_SpawnAtTeamSite", function(ply)
	if not ( ply and IsValid( ply ) ) then return end
	if ply:Team() == 0 or ply:Team() > 1000 then return end

	local teamInfo = B2CTF_MAP.teams[ply:Team()]
	if not teamInfo then return end

	local freeSpawns = findFreeSpawnPoints(teamInfo.spawnPoints)
	local newSpawn = freeSpawns[math.random( 1, #freeSpawns )]
	ply:SetPos( newSpawn )
end)

-- Setup the gamemode
GM.Name = "Build2CTF"
GM.Author = "Marcsello"
GM.Email = "marcsello@derpymail.org"
GM.Website = "marcsello.com"
GM.TeamBased = true -- This seems to be a gmod base config, but can't find much documentation on it
GM.CanOnlySpectateOwnTeam = true
GM.ValidSpectatorModes = {OBS_MODE_CHASE, OBS_MODE_IN_EYE}

DeriveGamemode("sandbox")

-- Start loading shared scripts
include("sh_config.lua") -- very important, global var holds all config

include("sh_phaser.lua") -- this is used by utils, so it must preceed it

-- These two add new functions 
include("sh_player.lua")
include("sh_entity.lua")

-- Include the configuration for this map, as the B2CTF_MAP variable is used at many places
-- TODO: Allow loading third-party configs
if file.Exists("b2ctf/gamemode/maps/" .. game.GetMap() .. ".lua", "LUA") or file.Exists("../lua_temp/b2ctf/gamemode/maps/" .. game.GetMap() .. ".lua", "LUA") then
    include("maps/" .. game.GetMap() .. ".lua")
else
    print("WARNING! Map " .. game.GetMap() .. " does not seem to have b2ctf config")
end

-- Calculate pre-calculated stuff
-- TODO: Move this somewhere else?
for i, teamData in ipairs(B2CTF_MAP.teams) do
    local centerX = math.min(teamData.boundaries[1].x, teamData.boundaries[2].x) + math.abs(teamData.boundaries[1].x - teamData.boundaries[2].x) / 2
    local centerY = math.min(teamData.boundaries[1].y, teamData.boundaries[2].y) + math.abs(teamData.boundaries[1].y - teamData.boundaries[2].y) / 2
    local centerZ = math.min(teamData.boundaries[1].z, teamData.boundaries[2].z) + math.abs(teamData.boundaries[1].z - teamData.boundaries[2].z) / 2
    local size = teamData.boundaries[1]:Distance( teamData.boundaries[2] )

    -- make sure you never use pairs() on boundaries lol
    B2CTF_MAP.teams[i].boundaries._center = Vector(centerX, centerY, centerZ)
    B2CTF_MAP.teams[i].boundaries._size = size
    B2CTF_MAP.teams[i].boundaries._sizeSqr = size^2
end

-- Include the remaining shared scripts
include("sh_protect.lua")
include("sh_flag.lua")
include("sh_flag_protect.lua")



-- Called on gamemdoe initialization to create teams
function GM:CreateTeams()
    if not B2CTF_MAP then return end
    print(" == Teams == ")
    for i, v in ipairs(B2CTF_MAP.teams) do
        print(i .. ": " .. v.name)
        team.SetUp(i, v.name, v.color, true)
    end
end

function GM:Initialize()
    if not B2CTF_MAP then
        error("This map is not set up for B2CTF!")
        return
    end
end

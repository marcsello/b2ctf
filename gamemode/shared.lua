-- Setup the gamemode
GM.Name = "Build2CTF"
GM.Author = "Marcsello"
GM.Email = "marcsello@derpymail.org"
GM.Website = "marcsello.com"
GM.TeamBased = true -- This seems to be a gmod base config, but can't find much documentation on it
GM.SecondsBetweenTeamSwitches = 240 -- 4 minutes; TODO: make configurable
GM.CanOnlySpectateOwnTeam = true
GM.ValidSpectatorModes = {OBS_MODE_CHASE, OBS_MODE_IN_EYE}

DeriveGamemode("sandbox")

-- Start loading shared scripts
include("sh_config.lua") -- very important, global var holds all config
include("sh_map_config.lua") -- This is the most important! because it sets up B2CTF_MAP on which everything depends. (may use config tho)

include("sh_phaser.lua") -- this is used by utils, so it must preceed it

-- These two add new functions
include("sh_player.lua")
include("sh_entity.lua")

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
    end
end

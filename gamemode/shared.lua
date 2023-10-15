include("sh_phaser.lua") -- this is used by utils, so it must preceed it

-- Run other shared scripts
include("sh_player.lua")

-- Setup the gamemode
GM.Name = "Build2CTF"
GM.Author = "Marcsello"
GM.Email = "marcsello@derpymail.org"
GM.Website = "marcsello.com"
GM.TeamBased = true -- This seems to be a gmod base config, but can't find much documentation on it
GM.CanOnlySpectateOwnTeam = true
GM.ValidSpectatorModes = {OBS_MODE_CHASE, OBS_MODE_IN_EYE}

DeriveGamemode("sandbox")

-- Include the configuration for this map
-- TODO: Allow loading third-party configs
if file.Exists("b2ctf/gamemode/maps/" .. game.GetMap() .. ".lua", "LUA") or file.Exists("../lua_temp/b2ctf/gamemode/maps/" .. game.GetMap() .. ".lua", "LUA") then
    include("maps/" .. game.GetMap() .. ".lua")
else
    print("WARNING! Map " .. game.GetMap() .. " does not seem to have b2ctf config")
end

-- Called on gamemdoe initialization to create teams
function GM:CreateTeams()
    if not GAMEMODE.TeamBased then return end
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

-- Load the map config
-- This is where B2CTF_MAP gets set up. It's one of the most important global vars. Almost everything in this gamemode depends on it.

-- Expected filename of the map config
local mapConfigFilename = game.GetMap() .. ".lua"

-- Paths to be checked
local thirdpartyConfigPath = "b2ctf/maps/" .. mapConfigFilename
local shippedConfigPath = "b2ctf/gamemode/maps/" .. mapConfigFilename
local altShippedConfigPath = "../lua_temp/b2ctf/gamemode/maps/" .. mapConfigFilename -- honestly, no idea why this is needed...

if SERVER then
    -- If there is a mapfile shipped by the gamemode, always send it to the client (we define b2ctf specific settings here)
    -- The client will decide which one to load using the same logic as the server (hopefully)
    if file.Exists(shippedConfigPath, "LUA") then
        AddCSLuaFile("maps/" .. mapConfigFilename)
    end
end

if file.Exists(thirdpartyConfigPath, "LUA") then -- first check thirdparty
    print("Loading B2CTF map configuration from " .. thirdpartyConfigPath .. " (3rd party) ...")
    B2CTF_MAP = include(thirdpartyConfigPath)
elseif file.Exists(shippedConfigPath, "LUA") or file.Exists(altShippedConfigPath, "LUA") then -- then bundled
    -- we ship a default config for that map, load that
    local relpath = "maps/" .. mapConfigFilename -- this works most of the time
    print("Loading B2CTF map configuration from " .. relpath .. " (shipped with gamemode) ...")
    B2CTF_MAP = include(relpath)
else -- nowhere to be found
    error("Could not load any B2CTF map configuration!")
end

-- Do some basic validation
if type(B2CTF_MAP) != "table" then
    error("B2CTF_MAP is undefined or not a table!")
end

if type(B2CTF_MAP.teams) != "table" then
    error("B2CTF_MAP.teams is undefined or not a table!")
end

if #B2CTF_MAP.teams < 2 then
    error("B2CTF_MAP.teams has to contain at least 2 teams!")
end

-- Calculate pre-calculated stuff
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

-- Stuff to print all sorts of internal state as debug info

local function printPhaseInfo(phaseInfo)
    print("    Length: " .. phaseInfo.time .. "s")
    print("    Name: " .. phaseInfo.name)
    print("    Warn time: " .. phaseInfo.warnTime .. "s")
    print("    Build allowed: " .. tostring(phaseInfo.buildAllowed))
    print("    Fight allowed: " .. tostring(phaseInfo.fightAllowed))
    print("    Home sickness: " .. tostring(phaseInfo.homeSickness))
    print("    Ready skippable: " .. tostring(phaseInfo.rdySkippable))
end

local function listToStr(list)
    local str = "(" .. #list .. ")["
    for _, v in ipairs(list) do
        str = str .. tostring(v) .. ", "
    end
    str = str .. "]"
    return str
end

local function printTeamInfo(teamID, teamInfo)
    print("  Team: " .. teamInfo.name)
    print("    TeamID: " .. teamID)
    print("    Description: " .. teamInfo.description)
    print("    Color: " .. tostring(teamInfo.color))
    print("    Bounds: " .. listToStr(teamInfo.boundaries))
    print("    Spawn Points: " .. listToStr(teamInfo.spawnPoints))
    print("    FlagPos: " .. tostring(teamInfo.flagPos))
    print("    Num Players: " .. team.NumPlayers(teamID))
    print("    Players:")
    for _, p in pairs(team.GetPlayers(teamID)) do
        print("    - " .. p:Nick())
    end
    print("    Score: " .. team.GetScore(teamID))
    print("    Total Deaths: " .. team.TotalDeaths(teamID))
    print("    Total Frags: " .. team.TotalFrags(teamID))
    print("    Flag ID valid: " .. tostring(FlagManager:FlagIDValid(teamID)))
    print("    Grabbed flag IDs: " .. listToStr(FlagManager:GetFlagIDsGrabbedByTeam(teamID)))
end

local function printFlagInfo(teamID, flagInfo)
    print("  Flag: " .. teamID)
    print("    Belongs to TeamID: " .. flagInfo.belongsToTeam)
    print("    Belongs to Team: " .. team.GetName(flagInfo.belongsToTeam))
    print("    Home Pos: " .. tostring(flagInfo.homePos))
    print("    Dropped Pos: " .. tostring(flagInfo.droppedPos))
    print("    Dropped Ts: " .. tostring(flagInfo.droppedTs))
    print("    GrabbedBy: " .. tostring(flagInfo.grabbedBy and flagInfo.grabbedBy:Nick()))
end

local function printPlayerInfo(ply)
    print("  Player: " .. ply:Nick())
    print("    Alive: " .. tostring(ply:Alive()))
    print("    Is Ready: " .. tostring(ply:IsReady()))
    print("    Team Valid: " .. tostring(ply:TeamValid()))
    print("    Team ID: " .. ply:Team())
    print("    Team: " .. team.GetName(ply:Team()))
    print("    Currently building: " .. tostring(ply:CurrentlyBuilding()))
    print("    At home: " .. tostring(ply:AtHome()))
    print("    Grabbed flag: " .. tostring(FlagManager:GetFlagIDGrabbedByPlayer(ply)))
end

return function()
    print("Build2CTF status:")

    -- phase
    print("Phase:")
    print("  Current time: " .. CurTime())
    print("  Current Phase:")
    printPhaseInfo(Phaser:CurrentPhaseInfo())
    print("  Next Phase:")
    printPhaseInfo(Phaser:NextPhaseInfo())
    print("  Start: " .. Phaser:CurrentPhaseStart())
    print("  End: " .. Phaser:CurrentPhaseEnd())
    print("  TimeLeft: " .. Phaser:CurrentPhaseTimeLeft() .. "s")

    -- config
    print("Config:")
    local cfgStr = tostring(Config)
    print("  " .. string.gsub(cfgStr, "\n", "\n  "))

    -- teams
    print("Teams:")
    for teamID, teamInfo in pairs(B2CTF_MAP.teams) do
        printTeamInfo(teamID, teamInfo)
    end

    -- flags
    local flagManagerConfigured = FlagManager:Configured()
    print("FlagManager configured: " .. tostring(flagManagerConfigured))
    if flagManagerConfigured then
        print("Flags:")
        for teamID, flagInfo in FlagManager:IterFlags() do
            printFlagInfo(teamID, flagInfo)
        end
    end

    -- players
    print("Num Players: " .. player.GetCount())
    print("Players:")
    for _, p in ipairs(player.GetAll()) do
        printPlayerInfo(p)
    end
end

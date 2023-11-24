-- Console commands

local function resetGame( ply )
    if not ((not ply:IsValid()) or (ply:IsAdmin())) then return end
    print("Resetting game...")
    GAMEMODE:ResetGame()
end
concommand.Add("b2ctf_reset_game", resetGame, nil, "Clanup map, reset phase and force all players to choose team again", 0)

local function forceNextPhase( ply )
    if not ((not ply:IsValid()) or (ply:IsAdmin())) then return end
    print("Manually advancing phase")
    Phaser:ForceNext()
end

concommand.Add("b2ctf_force_next_phase", forceNextPhase, nil, "Force changing to the next phase", 0)

local function forcePlayerInTeam(ply, cmd, args) -- there may be admin addons that implement this already, but I needed this for debugging
    if not ((not ply:IsValid()) or (ply:IsAdmin())) then return end

    if args[1] == nil or args[2] == nil then
        print("Usage: b2ctf_force_player_in_team <player> <team>")
        return
    end

    -- find player
    local targetPly = nil
    for _, p in ipairs(player.GetAll()) do
        if IsValid(p) and string.StartsWith(p:Nick(), args[1]) then
            if not targetPly then
                targetPly = p
            else
                print("Ambigous player name")
                return
            end
        end
    end
    if not targetPly then
        print("Could not find player")
        return
    end

    -- find team
    local targetTeamID = nil
    for i, t in pairs(team.GetAllTeams()) do
        if string.StartsWith(t.Name, args[2]) then
            if not targetTeamID then
                targetTeamID = i
            else
                print("Ambigous team")
                return
            end
        end
    end
    if not targetTeamID then
        print("Could not identify team")
        return
    end

    targetPly:SetTeam(targetTeamID)
    targetPly:Spawn()

    local msg = targetPly:Nick() .. " were forced to join " .. team.GetName(targetTeamID)
    print(msg)
    PrintMessage(HUD_PRINTTALK, msg)
end

concommand.Add("b2ctf_force_player_in_team", forcePlayerInTeam, nil, "Force team change of a given player", 0)

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
    print("    Grabbed flag ID: " .. tostring(FlagManager:GetFlagIDGrabbedByTeam(teamID)))
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

local function status(ply, cmd, args)
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

concommand.Add("b2ctf_debug_status", status, nil, "Get game status info", 0)

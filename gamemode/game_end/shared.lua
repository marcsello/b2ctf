local function calcEndGameStats()

    -- Find winner team(s)
    local teamsByScores = {}
    for teamID, _ in pairs(team.GetAllTeams()) do
        if (teamID > 0) and (teamID < 1000) and team.Valid(teamID) and (team.NumPlayers(teamID) > 0) then
            local s = team.GetScore(teamID) -- for some weird reason the "Score" field for the value is always zero...
            if teamsByScores[s] then
                table.insert(teamsByScores[s], teamID)
            else
                teamsByScores[s] = {teamID}
            end
        end
    end

    local finalOrder = {}
    local scores = table.GetKeys(teamsByScores)
    table.SortDesc(scores)
    for i, score in ipairs(scores) do
        finalOrder[i] = {
            teams = teamsByScores[score],
            score = score
        }
    end

    -- return with the end-game stats
    return {
        finalOrder = finalOrder
    }
end

local function printEndGameStats(stats)
    print("----- The war is over -----")
    for place, placeInfo in ipairs(stats.finalOrder) do
        local teamNames = {}
        for i, teamID in ipairs(placeInfo.teams) do
            teamNames[i] = team.GetName(teamID)
        end
        print(place .. ". place: " .. table.concat(teamNames, ", "))
        print("  score: " .. placeInfo.score)
    end
    print("---------------------------")
end

hook.Add("B2CTF_PhaseChanged", "EndWarThings", function(newPhaseID, newPhaseInfo, oldPhaseID, oldPhaseInfo, start_time, end_time)
    if not oldPhaseID then return end -- this was caused by a reset, do nothing
    if newPhaseID == GAME_PHASE_PREBUILD and oldPhaseID == GAME_PHASE_WAR then
        -- The game just ended, call end game hooks
        local endGameStats = calcEndGameStats()
        printEndGameStats(endGameStats)
        hook.Run("B2CTF_WarEnded", endGameStats)
    end
    if newPhaseID == GAME_PHASE_BUILD and oldPhaseID == GAME_PHASE_PREBUILD then
        -- the post-war phase is complete, so we are on to a new building phase
        hook.Run("B2CTF_NewRoundBegin")
    end
end )

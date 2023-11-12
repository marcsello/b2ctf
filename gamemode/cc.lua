-- Console commands

local function resetGame()
    print("Resetting game...")
    GAMEMODE:ResetGame()
end
concommand.Add("b2ctf_reset_game", resetGame, nil, "Clanup map, reset phase and force all players to choose team again", 0)

local function forceNextPhase()
    print("Manually advancing phase")
    Phaser:ForceNext()
end

concommand.Add("b2ctf_force_next_phase", forceNextPhase, nil, "Force changing to the next phase", 0)

local function forcePlayerInTeam(ply, cmd, args) -- there may be admin addons that implement this already, but I needed this for debugging
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

concommand.Add("b2ctf_force_player_in_team", forcePlayerInTeam, nil, "Force team change of a given player ", 0)

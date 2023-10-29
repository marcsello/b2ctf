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

AddCSLuaFile("shared.lua")
AddCSLuaFile("modules/game_end_popup.lua")
AddCSLuaFile("modules/header.lua")
AddCSLuaFile("modules/middle.lua")
AddCSLuaFile("modules/footer.lua")

include("shared.lua")

function GM:B2CTF_WarEnded(stats)
    -- Nothing yet... 
end

function GM:B2CTF_NewRoundBegin()
    -- Reset team scores
    for i, _ in pairs(team.GetAllTeams()) do  -- teams aren't a continous array, so we need pairs instead of ipairs
        team.SetScore( i, 0 ) -- yes, this resets spectators, connecting etc. scores too
    end

    -- Reset player scores
    for _, ply in ipairs(player.GetAll()) do
        ply:SetFrags(0)
        ply:SetDeaths(0)
    end

    print("A new round begin, scores were reset")
end

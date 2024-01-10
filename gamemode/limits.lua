hook.Add("PlayerCheckLimit", "B2CTF_TeamLimits", function(ply, limitName, current, defaultMax)
    if not (ply and IsValid(ply) and ply:TeamValid()) then return false end -- players in invalid teams should not be able to build anyways

    local teamID = ply:Team()

    -- Count the total items in the team instead of individual player limit
    local teamSum = 0
    for _, p in ipairs(team.GetPlayers(teamID)) do
        teamSum = teamSum + p:GetCount(limitName) -- GetCount comes from g_SBoxObjects
    end

    -- this should be the same as the default handler:
    -- https://github.com/Facepunch/garrysmod/blob/9bbd7c8af0dda5bed88e3f09fbdf5d4be7e012f2/garrysmod/gamemodes/sandbox/gamemode/player_extension.lua#L25C7-L25C20
    return teamSum < defaultMax
end )

-- This is the business logic for the very basic ready system
-- It can be disabled to use a 3rd pary solution, or not use ready stuff at all

if not (Config.EnablePlayerReadyShort or Config.EnablePlayerReadyBuild) then
    return
end
print("Phase skipping by ready is enabled")

local helpText = "Type !ready in chat "
if Config.EnablePlayerReadyBySpare2 then
    helpText = helpText .. "or press F4 "
end
helpText = helpText .. "to toggle your ready state."


hook.Add("B2CTF_PlayerChangedReadyState", "PlayerReadinessCheckIfAllPlayersReady", function(ply, oldState, rdy)
    if not Phaser:CurrentPhaseInfo().rdySkippable then return end -- if current phase is not skippable then don't care
    -- check if all players ready, if so, skip the current phase
    local readyCnt = 0
    local validCnt = 0 -- we only should consider votes from players in valid teams
    for _, p in ipairs(player.GetAll()) do
        if not IsValid(p) then continue end
        if p:IsReady() then
            readyCnt = readyCnt + 1
        end
        if p:TeamValid() then
            validCnt = validCnt + 1
        end
    end

    print("Player " .. ply:Nick() .. " set their ready state to " .. tostring(rdy) .. ". Current status: " .. readyCnt .. "/" .. validCnt)
    if rdy then
        ply:PrintMessage(HUD_PRINTTALK, "You become ready!")
    else
        ply:PrintMessage(HUD_PRINTTALK, "You become un-ready!")
    end

    local msg = nil
    if readyCnt == validCnt then
        msg = "All players are ready! Entering " .. Phaser:NextPhaseInfo().name .. " phase!"
        Phaser:ForceNext()
    else
        msg = readyCnt .. " players ready out of " .. validCnt .. ". " .. helpText
    end

    PrintMessage(HUD_PRINTTALK, msg)
    print(msg) -- server console too
end )


hook.Add("B2CTF_PlayerCanChangeReadyState", "PlayerReadinessCheckIfAllowedToReady", function(ply, oldState, rdy)
    if not (IsValid(ply) and ply:TeamValid()) then return false end -- prevent spectators

    if not Phaser:CurrentPhaseInfo().rdySkippable then
        -- if current phase is not skippable then prevent player readying
        ply:PrintMessage(HUD_PRINTTALK, "The current phase can not be skipped...")
        return false
    end
end )


hook.Add("B2CTF_PhaseChanged", "PlayerReadinessPhaseChange", function(newPhaseID, newPhaseInfo, oldPhaseID, oldPhaseInfo, startTime, endTime)
    -- we don't really care what phase is this, we reset all readiness
    for _, ply in ipairs(player.GetAll()) do
        ply:ClearReady() -- does not call CanChange and Changed hooks
    end

    -- if this new phase is skippable, print a message
    if newPhaseInfo.rdySkippable then
        local msg = "The current phase can be skipped when all players ready. " .. helpText
        PrintMessage(HUD_PRINTTALK, msg)
    end
end )


local function playerReadyToggle(ply)
    -- we don't check if stuff is allowed here, because that's done in the B2CTF_PlayerCanChangeReadyState hook
    ply:SetReady(not ply:IsReady())
end

-- register chat hook
hook.Add( "PlayerSay", "B2CTF_PlayerReadyByChat", function( ply, text )
    if string.Trim(text) == "!ready" then
        playerReadyToggle(ply)
    end
end )

-- register Spare2 hook
if Config.EnablePlayerReadyBySpare2 then
    hook.Add("ShowSpare2", "B2CTF_PlayerReadyBySpare2", function(ply)
        playerReadyToggle(ply)
    end )
end

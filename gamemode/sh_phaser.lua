-- Control/sync the current game phase
if SERVER then
    util.AddNetworkString("B2CTF_PhaseUpdate") -- sent by the server to update player's state
    util.AddNetworkString("B2CTF_PhaseRequestUpdate") -- sent by the client to request a sync
end

-- Setup some global vars, functions
GAME_PHASE_PREBUILD = 1
GAME_PHASE_BUILD = 2
GAME_PHASE_PREWAR = 3
GAME_PHASE_WAR = 4
-- don't forget to update network bytes when adding more than 4

GAME_PHASE_INFO = {
    [GAME_PHASE_PREBUILD] = {
        time = Config.PreBuildTime,
        name = "Intermezzo",
        warnTime = 5,
        buildAllowed = false, -- Spawn menu works, players have toolgun and physgun
        fightAllowed = false, -- 
        homeSickness = false, -- Players hurt when leaving the site, also brought back on phase change, props also break that wander around
        rdySkippable = Config.EnablePlayerReadyShort, -- Allows the pahse to be skipped by all players being ready
    },
    [GAME_PHASE_BUILD] = {
        time = Config.BuildTime,
        name = "Building",
        warnTime = 60,
        buildAllowed = true,
        fightAllowed = false,
        homeSickness = true,
        rdySkippable = Config.EnablePlayerReadyBuild,
    },
    [GAME_PHASE_PREWAR] = {
        time = Config.PreWarTime,
        name = "Prepare for war",
        warnTime = 5,
        buildAllowed = false,
        fightAllowed = false,
        homeSickness = true,
        rdySkippable = Config.EnablePlayerReadyShort,
    },
    [GAME_PHASE_WAR] = {
        time = Config.WarTime,
        name = "War",
        warnTime = 30,
        buildAllowed = false,
        fightAllowed = true,
        homeSickness = false,
        rdySkippable = false,
    }
}

Phaser = Phaser or {
    current_phase_id = 0,
    next_phase_id = 0,
    start_time = 0,
    end_time = 0
}

function Phaser:CurrentPhaseID()
    return self.current_phase_id
end

function Phaser:CurrentPhaseInfo()
    return GAME_PHASE_INFO[self.current_phase_id]
end

function Phaser:CurrentPhaseEnd()
    return self.end_time
end

function Phaser:CurrentPhaseStart()
    return self.start_time
end

function Phaser:CurrentPhaseTimeLeft()
    local timeLeft = self.end_time - CurTime()
    if timeLeft < 0 then
        timeLeft = 0
    end
    return timeLeft
end

function Phaser:NextPhaseID()
    return self.next_phase_id
end

function Phaser:NextPhaseInfo()
    return GAME_PHASE_INFO[self.next_phase_id]
end

function Phaser:ForceNext()
    local startTime = CurTime()
    -- update the current phase to be the next phase, sync, call hooks, etc.
    self:_update(self.next_phase_id, startTime, startTime + GAME_PHASE_INFO[self.next_phase_id].time, false)
end

function Phaser:_think()
    if CLIENT then return end -- this should be server side only
    if self.end_time < CurTime() then
        -- advance to the next phase
        self:ForceNext()
    end
end

function Phaser:_update(newPhaseID, startTime, endTime, isReset)
    local oldPhaseId = self.current_phase_id
    local changed = oldPhaseId ~= newPhaseID

    self.current_phase_id = newPhaseID
    self.start_time = startTime
    self.end_time = endTime

    self.next_phase_id = self.current_phase_id + 1
    if self.next_phase_id > #GAME_PHASE_INFO then self.next_phase_id = 1 end

    if SERVER then
        self:_broadcastPhase(isReset)
    end

    if changed then -- Update may be called just to update times, in that case we don't want to fire a phase change hook
        if isReset then
            self:_runHooks(nil)
        else
            self:_runHooks(oldPhaseId)
        end
    end

end

function Phaser:_prepareUpdateMessage(isReset)
    net.Start("B2CTF_PhaseUpdate")
    net.WriteUInt(self.current_phase_id-1, 2)  -- 1-4 -> 1-3 only requires 2 bits
    net.WriteBool(isReset)
    net.WriteDouble(self.start_time)
    net.WriteDouble(self.end_time)
end

function Phaser:_sendPhaseToPlayer(ply)
    if CLIENT then return end
    self:_prepareUpdateMessage(false) -- probably not a reset
    net.Send(ply)
end


function Phaser:_broadcastPhase(isReset)
    if CLIENT then return end
    self:_prepareUpdateMessage(isReset)
    net.Broadcast()
end

function Phaser:_runHooks(oldPhaseID)
    local info = GAME_PHASE_INFO[self.current_phase_id]
    local oldPhaseInfo = nil
    if oldPhaseID then -- oldPhaseID is nil on reset (and probably on jump too if ever needed)
        oldPhaseInfo = GAME_PHASE_INFO[oldPhaseID]
    end

    print("New phase: " .. info.name .. " for " .. info.time .. " seconds")
    hook.Run("B2CTF_PhaseChanged", self.current_phase_id, info, oldPhaseID, oldPhaseInfo, self.start_time, self.end_time)
end

if CLIENT then -- setup listener for client only
    net.Receive("B2CTF_PhaseUpdate", function( len, ply )
        if ( IsValid( ply ) and ply:IsPlayer() ) then return end -- disallow these messages from players
        local newPhaseID = net.ReadUInt(2) + 1
        local isReset = net.ReadBool()
        local startTime = net.ReadDouble()
        local endTime = net.ReadDouble()
        Phaser:_update(newPhaseID, startTime, endTime, isReset)
    end)

    hook.Add("OnReloaded", "B2CTF_PhaseRequestUpdate", function()
        net.Start("B2CTF_PhaseRequestUpdate")
        net.SendToServer()
    end )

elseif SERVER then
    timer.Create("B2CTF_PhaserSlowThink", 0.2, 0, function() Phaser:_think() end)
    hook.Add("PlayerInitialSpawn", "B2CTF_SendInitialPhase", function(ply) Phaser:_sendPhaseToPlayer(ply) end )

    net.Receive("B2CTF_PhaseRequestUpdate", function( len, ply )
        if ply and IsValid(ply) then
            -- TODO: Maybe implement a timeout, to prevent self-dos-amplification
            Phaser:_sendPhaseToPlayer(ply)
        end
    end )

end


function Phaser:Reset()
    local newPhaseID = GAME_PHASE_PREBUILD
    local startTime = CurTime()
    local endTime = startTime + GAME_PHASE_INFO[newPhaseID].time
    Phaser:_update(newPhaseID, startTime, endTime, true) -- Update runs hooks, and syncs stuff
    print("Phase reset to " .. GAME_PHASE_INFO[self.current_phase_id].name)
end

Phaser:Reset() -- intialize phaser

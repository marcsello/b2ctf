if SERVER then
    util.AddNetworkString("B2CTF_PhaseUpdate")
end

-- Setup some global vars, functions
GAME_PHASE_PREBUILD = 1
GAME_PHASE_BUILD = 2
GAME_PHASE_PREWAR = 3
GAME_PHASE_WAR = 4
-- don't forget to update network bytes when adding more than 7

GAME_PHASE_INFO = {
    [GAME_PHASE_PREBUILD] = {
        time = 5, -- 30 sec
        name = "Coffee break",
        buildAllowed = false, -- Spawn menu works, players have toolgun and physgun
        fightAllowed = false, -- 
        homeSickness = false, -- Players hurt when leaving the site, also brought back on phase change
    },
    [GAME_PHASE_BUILD] = {
        time = 120, -- 1h
        name = "Building",
        buildAllowed = true,
        fightAllowed = false,
        homeSickness = true,
    },
    [GAME_PHASE_PREWAR] = {
        time = 30, -- 1m
        name = "Prepare for war",
        buildAllowed = false,
        fightAllowed = false,
        homeSickness = true,
    },
    [GAME_PHASE_WAR] = {
        time = 60, -- 25m
        name = "War",
        buildAllowed = false,
        fightAllowed = true,
        homeSickness = false,
    }
}

local st = CurTime()
Phaser = {
    current = GAME_PHASE_PREBUILD,
    start_time = st,
    end_time = st + GAME_PHASE_INFO[GAME_PHASE_PREBUILD].time
}

function Phaser:CurrentPhaseID()
    return self.current
end

function Phaser:CurrentPhaseInfo()
    return GAME_PHASE_INFO[self.current]
end

function Phaser:CurrentPhaseEnd()
    return self.end_time
end

function Phaser:CurrentPhaseEnd()
    return self.start_time
end

function Phaser:CurrentPhaseTimeLeft()
    return self.end_time - self.start_time
end

function Phaser:_think()
    if CLIENT then return end -- this should be server side only
    if self.end_time < CurTime() then
        -- advance to the next phase
        local nextPhase = self.current + 1
        if nextPhase > GAME_PHASE_WAR then nextPhase = GAME_PHASE_PREBUILD end
        local startTime = CurTime()
        -- update the current phase to be the next phase, sync, call hooks, etc.
        self:Update(nextPhase, startTime, startTime + GAME_PHASE_INFO[nextPhase].time)
    end
end

function Phaser:_prepareUpdateMessage()
    net.Start("B2CTF_PhaseUpdate")
    net.WriteUInt(self.current, 3)
    net.WriteDouble(self.start_time)
    net.WriteDouble(self.end_time)
end

function Phaser:Update(newPhase, startTime, endTime)
    local changed = self.current != newPhase
    self.current = newPhase
    self.start_time = startTime
    self.end_time = endTime
    if SERVER then
        self:_broadcastPhase()
    end

    if changed then -- Update may be called just to update times, in that case we don't want to fire a phase change hook
        local newInfo = GAME_PHASE_INFO[newPhase]
        print("New phase: " .. newInfo.name)
        hook.Run("B2CTF_PhaseChanged", self.current, newInfo, self.start_time, self.end_time)
    end

end

function Phaser:_sendPhaseToPlayer(ply)
    if CLIENT then return false end
    self:_prepareUpdateMessage()
    net.Send(ply)
end


function Phaser:_broadcastPhase()
    if CLIENT then return false end
    self:_prepareUpdateMessage()
    net.Broadcast()
end

if CLIENT then -- setup listener for client only
    net.Receive( "B2CTF_PhaseUpdate", function( len, ply )
        if ( IsValid( ply ) and ply:IsPlayer() ) then return end -- disallow these messages from players
        local newPhase = net.ReadUInt(3)
        local startTime = net.ReadDouble()
        local endTime = net.ReadDouble()
        Phaser:Update(newPhase, startTime, endTime)
    end)
elseif SERVER then
    timer.Create("B2CTF_PhaserSlowThink", 0.5, 0, function() Phaser:_think() end)
    hook.Add("PlayerInitialSpawn", "B2CTF_SendInitialPhase", function(ply) Phaser:_sendPhaseToPlayer(ply) end )
    hook.Add("OnReloaded", "B2CTF_UpdatePhaseOnReload", function()
        print("Reload caused phase reset to " .. Phaser:CurrentPhaseInfo().name)
        Phaser:_broadcastPhase()
    end)
end
-- Flag related stuff, this only manages the business logic, rendering is in cl_flag.lua
if not B2CTF_MAP then return end -- flags rely heavily on map data. If map data is missing the game would be broken anyways

if SERVER then
    util.AddNetworkString("B2CTF_FlagEventUpdate") -- Sent by the server on events
    util.AddNetworkString("B2CTF_FlagFullSync") -- Sent by the server if a full synchronization is needed
    util.AddNetworkString("B2CTF_FlagRequestSync") -- Send by the client when it thinks it needs a full synchronization
end

local FLAG_EVENT_DROP = 0
local FLAG_EVENT_RETURN = 1
local FLAG_EVENT_GRAB = 2
local FLAG_EVENT_CAPTURE = 3

local NET_EVENT_LEN = 2 -- in bits
local NET_FLAG_ID_LEN = 4 -- More than 15 teams will break this

local FLAG_RETURN_TIME = 30 -- TODO: make it a convar
local FLAG_GRAB_DISTANCE = 2300

FlagManager = FlagManager or { -- prevent re-creating the whole object on
    flags = {}
}

function FlagManager:Reset() -- Reset is not synced manually, make sure that all hooks that call it are called on both client and server side
    if self.flags then
        hook.Run("B2CTF_FlagManagerPreReset", self.flags)
    end

    -- Re-create common flag data
    self.flags = {}
    for i, v in ipairs(B2CTF_MAP.teams) do
        self.flags[i] = {
            homePos = v.flagPos,
            belongsToTeam = i, -- TeamID
            droppedPos = nil,
            droppedTs = nil,
            grabbedBy = nil -- When grabbed, render it attached to that player
        }
    end

    hook.Run("B2CTF_FlagManagerInitialized", self.flags)
end

function FlagManager:FlagIDValid(flagID)
    return self.flags[flagID] != nil
end

function FlagManager:IterFlags()
    return ipairs(self.flags)
end

function FlagManager:Configured()
    return #self.flags == #B2CTF_MAP.teams
end

function FlagManager:GetFlagIDGrabbedByPlayer(ply)
    if not (ply and IsValid(ply)) then return end
    for i, v in ipairs(self.flags) do
        if v.grabbedBy == ply then return i end
    end
    -- default return nil
end

function FlagManager:GetFlagInfoGrabbedByPlayer(ply)
    local flagID = self:GetFlagIDGrabbedByPlayer(ply)
    if flagID then
        return self.flags[flagID]
    end
end

function FlagManager:GetFlagIDGrabbedByTeam(teamID)
    -- Checks if the given team has grabbed any flag
    for i, flag in ipairs(self.flags) do
        if flag.grabbedBy and flag.grabbedBy:Team() == teamID then return i end
    end
    -- default: return nil
end

function FlagManager:DropFlag(flagID, droppedPos, droppedTs)
    assert(self:FlagIDValid(flagID), "invalid flag id")

    self.flags[flagID].grabbedBy = nil
    self.flags[flagID].droppedPos = droppedPos
    self.flags[flagID].droppedTs = droppedTs

    local teamName = team.GetName(flagID)
    print("The flag of " .. teamName .. " has been dropped")

    hook.Run("B2CTF_FlagDropped", flagID, droppedPos, droppedTs, droppedTs + FLAG_RETURN_TIME) -- teamID, dropPos, dropTime, autoReturnTime

    -- Sync
    if SERVER then
        net.Start("B2CTF_FlagEventUpdate")
        net.WriteUInt(FLAG_EVENT_DROP, NET_EVENT_LEN)
        net.WriteUInt(flagID, NET_FLAG_ID_LEN)
        net.WriteVector(droppedPos)
        net.WriteDouble(droppedTs)
        net.Broadcast()
    end
end

function FlagManager:ReturnFlag(flagID, ply)
    assert(self:FlagIDValid(flagID), "invalid flag id")

    self.flags[flagID].grabbedBy = nil
    self.flags[flagID].droppedPos = nil
    self.flags[flagID].droppedTs = nil

    local autoReturn = ply == nil -- no player = auto-return

    local teamName = team.GetName(flagID) -- flagID == teamID
    if autoReturn then
        print("The flag of " .. teamName .. " has been returned (auto return)")
    else
        print("The flag of " .. teamName .. " has been returned by " .. ply:Nick())
    end

    hook.Run("B2CTF_FlagReturned", flagID, self.flags[flagID].homePos, autoReturn, ply) -- teamID, homePos, autoReturn, returner

    -- Sync
    if SERVER then
        net.Start("B2CTF_FlagEventUpdate")
        net.WriteUInt(FLAG_EVENT_RETURN, NET_EVENT_LEN)
        net.WriteUInt(flagID, NET_FLAG_ID_LEN)
        net.WriteBool(autoReturn)
        if not autoReturn then
            net.WriteEntity(ply)
        end
        net.Broadcast()
    end
end

function FlagManager:GrabFlag(flagID, ply, flagWasDropped)
    assert(self:FlagIDValid(flagID), "invalid flag id")
    if not (ply and IsValid(ply)) then return end

    self.flags[flagID].grabbedBy = ply
    self.flags[flagID].droppedPos = nil
    self.flags[flagID].droppedTs = nil

    local teamName = team.GetName(flagID)
    local grabberTeamID = ply:Team()
    local grabberTeamName = team.GetName(grabberTeamID)
    if flagWasDropped then
        print("The flag of " .. teamName .. " is grabbed by " .. ply:Nick() .. " from " ..  grabberTeamName .. " (from ground)")
    else
        print("The flag of " .. teamName .. " is grabbed by " .. ply:Nick() .. " from " ..  grabberTeamName .. " (from base)")
    end

    hook.Run("B2CTF_FlagGrabbed", flagID, grabberTeamID, ply, flagWasDropped) -- teamID, player

    -- Sync
    if SERVER then
        net.Start("B2CTF_FlagEventUpdate")
        net.WriteUInt(FLAG_EVENT_GRAB, NET_EVENT_LEN)
        net.WriteUInt(flagID, NET_FLAG_ID_LEN)
        net.WriteEntity(ply)
        net.WriteBool(flagWasDropped)
        net.Broadcast()
    end
end

function FlagManager:CaptureFlag(flagID, capturedBy) -- flagID is the ID of the flag that is captured by capturedBy
    assert(self:FlagIDValid(flagID), "invalid flag id")
    if not (capturedBy and IsValid(capturedBy)) then return end

    self.flags[flagID].grabbedBy = nil
    self.flags[flagID].droppedPos = nil
    self.flags[flagID].droppedTs = nil

    local teamName = team.GetName(flagID)
    local capturerTeamID = capturedBy:Team()
    local capturerTeamName = team.GetName(capturerTeamID)
    print("The flag of " .. teamName .. " is was captured by " .. capturedBy:Nick() .. " (score to team " .. capturerTeamName .. ")")
    team.AddScore(capturerTeamID, 1)

    hook.Run("B2CTF_FlagCaptured", flagID, capturerTeamID, capturedBy) -- flagID / flag's teamID, capturing team's teamID, capturer

    -- Sync
    if SERVER then
        net.Start("B2CTF_FlagEventUpdate")
        net.WriteUInt(FLAG_EVENT_CAPTURE, NET_EVENT_LEN)
        net.WriteUInt(flagID, NET_FLAG_ID_LEN)
        net.WriteEntity(capturedBy)
        net.Broadcast()
    end
end


-- The basic structure of FlagManager is ready

if CLIENT then
    include("cl_flag.lua") -- Include cl_flag.lua here, so we can catch the first InitComplete hook
end

FlagManager:Reset() -- initial setup (This tirggers InitComplete hook)

-- And now, do stuff from server side to make things tick

if SERVER then

    -- Define some "hidden" functions

    function FlagManager:_sendFullSyncToPlayer(ply)
        -- The number of flags, their default positions etc, should be infered from the B2CTF_MAP variable
        -- So we only need to send the three important fields for each flag
        net.Start("B2CTF_FlagFullSync")
        for i, v in ipairs(self.flags) do
            local grabbedBySet = v.grabbedBy != nil
            local droppedPosSet = v.droppedPos != nil
            local droppedTsSet = v.droppedTs != nil
            -- first, send what's set
            net.WriteBool(grabbedBySet)
            net.WriteBool(droppedPosSet)
            net.WriteBool(droppedTsSet)

            -- then send the value if needed
            if grabbedBySet then
                net.WriteEntity(v.grabbedBy)
            end
            if droppedPosSet then
                net.WriteVector(v.droppedPos)
            end
            if droppedTsSet then
                net.WriteDouble(v.droppedTs)
            end
        end
        net.Send(ply)

    end

    function FlagManager:_playerThink(ply)
        -- The main business logic
        local interactionFlagID = nil
        local playerCarryingFlagID = nil
        local interactionFlagDropped = false
        for i, flag in self:IterFlags() do -- Normally I would write two for loops, but this feels a little more optimized

            if flag.grabbedBy == ply then
                 -- this player is carrying this flag. (so the player is carrying a flag)
                playerCarryingFlagID = i
                continue -- don't process this flag further (it's position is irrelevant)
            end

            if flag.grabbedBy then continue end -- this flag is grabbed by someone, ignore it

            local checkPos = flag.homePos
            local dropped = false
            if flag.droppedPos then
                local dropTime = CurTime() - flag.droppedTs
                if dropTime < FLAG_RETURN_TIME then  -- ignore flag if it's auto return time already spent, to avoid undefined states
                    checkPos = flag.droppedPos
                    dropped = true
                end
            end

            if ply:GetPos():DistToSqr(checkPos) < FLAG_GRAB_DISTANCE then
                interactionFlagID = i
                interactionFlagDropped = dropped
            end

        end

        if interactionFlagID then -- the player is interacting with a flag

            if (not playerCarryingFlagID) and (interactionFlagID != ply:Team()) then
                -- the player not carrying flag, and this is not own flag... possibly taking a flag
                self:GrabFlag(interactionFlagID, ply, interactionFlagDropped)
                return -- only handle one action per tick, so that handles can correctly process
            end

            if (interactionFlagID == ply:Team()) then
                if interactionFlagDropped then
                    -- this is their own flag, and it is dropped... return it
                    self:ReturnFlag(interactionFlagID, ply)
                    return -- only handle one action per tick, so that handles can correctly process
                elseif playerCarryingFlagID then
                    -- the flag is their own, not dropped and the player is carrying a flag... this is a capture
                    self:CaptureFlag(playerCarryingFlagID, ply)
                    return -- only handle one action per tick, so that handles can correctly process
                end
            end
        end

    end

    function FlagManager:_checkAndDropFlagOnDeath(ply)
        local flagID = self:GetFlagIDGrabbedByPlayer(ply)
        if not flagID then return end -- player wasn't holding any of the flags
        -- Run a trace bellow the player to find the ground, so flags won't be dropped mid-air
        local dropPos = ply:GetPos()
        local tr = util.TraceLine({
            start = dropPos + Vector(0,0,10), -- Start a few units above
            endpos = dropPos - Vector(0,0,10000), -- End a lot more units bellow
            mask = MASK_PLAYERSOLID,
        })
        if tr.Hit then -- ground found
            dropPos = tr.HitPos
        end

        self:DropFlag(flagID, dropPos, CurTime())
    end

    function FlagManager:_svThink()
        for i, flag in self:IterFlags() do
            if flag.droppedTs and flag.droppedPos and (not flag.grabbedBy) then
                local dropTime = CurTime() - flag.droppedTs
                if dropTime >= FLAG_RETURN_TIME then
                    self:ReturnFlag(i, nil) -- nil ply = autoReturn
                end
            end
        end
    end

    -- then call them when appropriate

    hook.Add("PlayerTick", "B2CTF_FlagManagerPlayerThink", function(ply) -- WARNING: Does not run when in vehicle! (but that's fine)
        if not Phaser:CurrentPhaseInfo().fightAllowed then return end -- do nothing, when we are not fighting
        if IsValid(ply) and ply:IsPlayer() and ply:TeamValid() and ply:Alive() then -- only work for players who are in valid team, and alive
            FlagManager:_playerThink(ply)
        end
    end)

    hook.Add("PlayerDeath", "B2CTF_DropFlag", function( victim, inflictor, attacker )
        if not Phaser:CurrentPhaseInfo().fightAllowed then return end -- do nothing, when we are not fighting
        if IsValid(victim) and victim:IsPlayer() and victim:TeamValid() then
            FlagManager:_checkAndDropFlagOnDeath(victim)
        end
    end )

    hook.Add("Think", "B2CTF_FlagThink", function()
        if not Phaser:CurrentPhaseInfo().fightAllowed then return end -- do nothing, when we are not fighting
        FlagManager:_svThink()
     end)

    hook.Add("PlayerInitialSpawn", "B2CTF_SendInitialFlagsState", function(ply) FlagManager:_sendFullSyncToPlayer(ply) end )

    net.Receive("B2CTF_FlagRequestSync", function( len, ply )
        if ply and IsValid(ply) then
            FlagManager:_sendFullSyncToPlayer(ply)
        end
    end )

end

-- Shared

hook.Add("B2CTF_PhaseChanged", "ResetFlagsAtTheEndOfWar", function(newPhaseID, newPhaseInfo, oldPhaseID, oldPhaseInfo, startTime, endTime)
    if (not oldPhaseID) or (oldPhaseInfo.fightAllowed and (not newPhaseInfo.fightAllowed)) then -- When we don't know the previous phase, it's safer to just reset
        FlagManager:Reset()
    end
end)


if CLIENT then -- sync recv
    net.Receive( "B2CTF_FlagEventUpdate", function( len, ply ) -- sync client
        if ( IsValid( ply ) and ply:IsPlayer() ) then return end -- disallow these messages from players

        local event = net.ReadUInt(NET_EVENT_LEN)

        if event == FLAG_EVENT_DROP then
            local flagID = net.ReadUInt(NET_FLAG_ID_LEN)
            local droppedPos = net.ReadVector()
            local droppedTs = net.ReadDouble()
            FlagManager:DropFlag(flagID, droppedPos, droppedTs)
        end

        if event == FLAG_EVENT_RETURN then
            local flagID = net.ReadUInt(NET_FLAG_ID_LEN)
            local autoReturn = net.ReadBool()
            local returner = nil
            if not autoReturn then
                returner = net.ReadEntity()
            end
            FlagManager:ReturnFlag(flagID, returner)
        end

        if event == FLAG_EVENT_GRAB then
            local flagID = net.ReadUInt(NET_FLAG_ID_LEN)
            local grabber = net.ReadEntity()
            local flagWasDropped = net.ReadBool()
            FlagManager:GrabFlag(flagID, grabber, flagWasDropped)
        end

        if event == FLAG_EVENT_CAPTURE then
            local flagID = net.ReadUInt(NET_FLAG_ID_LEN)
            local capturedBy = net.ReadEntity()
            FlagManager:CaptureFlag(flagID, capturedBy)
        end

    end)

    net.Receive( "B2CTF_FlagFullSync", function( len, ply )
        for _, v in FlagManager:IterFlags() do
            local grabbedBySet = net.ReadBool()
            local droppedPosSet = net.ReadBool()
            local droppedTsSet = net.ReadBool()

            -- this is needed, because we need to "nil-out" a field when it's unset on the server
            local grabbedBy = nil
            local droppedPos = nil
            local droppedTs = nil

            if grabbedBySet then
                grabbedBy = net.ReadEntity()
            end
            if droppedPosSet then
                droppedPos = net.ReadVector()
            end
            if droppedTsSet then
                droppedTs = net.ReadDouble()
            end

            v.grabbedBy = grabbedBy
            v.droppedPos = droppedPos
            v.droppedTs = droppedTs
        end
    end)

    hook.Add("OnReloaded", "B2CTF_FlagRequestSync", function()
        net.Start("B2CTF_FlagRequestSync")
        net.SendToServer()
    end )

end

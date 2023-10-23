-- Flag related stuff, this only manages the business logic, rendering is in cl_flag.lua
if not B2CTF_MAP then return end -- flags rely heavily on map data. If map data is missing the game would be broken anyways

if SERVER then
    util.AddNetworkString("B2CTF_FlagEventUpdate")
    util.AddNetworkString("B2CTF_FlagFullSync")
end

local FLAG_EVENT_DROP = 0
local FLAG_EVENT_RETURN = 1
local FLAG_EVENT_GRAB = 2
local FLAG_EVENT_CAPTURE = 3

local NET_EVENT_LEN = 2 -- in bits
local NET_FLAG_ID_LEN = 4 -- More than 15 teams will break this

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

function FlagManager:DropFlag(flagID, droppedPos, droppedTs)
    if not self:FlagIDValid(flagID) then return end

    self.flags[flagID].grabbedBy = nil
    self.flags[flagID].droppedPos = dropPos
    self.flags[flagID].droppedTs = droppedTs

    local teamName = team.GetName(self.flags[flagID].belongsToTeam)
    print("The flag of " .. teamName .. " has been dropped")

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

function FlagManager:ReturnFlag(flagID)
    if not self:FlagIDValid(flagID) then return end

    self.flags[flagID].grabbedBy = nil
    self.flags[flagID].droppedPos = nil
    self.flags[flagID].droppedTs = nil

    local teamName = team.GetName(self.flags[flagID].belongsToTeam)
    print("The flag of " .. teamName .. " has been returned")

    -- Sync
    if SERVER then
        net.Start("B2CTF_FlagEventUpdate")
        net.WriteUInt(FLAG_EVENT_RETURN, NET_EVENT_LEN)
        net.WriteUInt(flagID, NET_FLAG_ID_LEN)
        net.Broadcast()
    end
end

function FlagManager:GrabFlag(flagID, ply)
    if not (ply and IsValid(ply) and self:FlagIDValid(flagID)) then return end

    self.flags[flagID].grabbedBy = ply
    self.flags[flagID].droppedPos = nil
    self.flags[flagID].droppedTs = nil

    local teamName = team.GetName(self.flags[flagID].belongsToTeam)
    print("The flag of " .. teamName .. " is grabbed by " .. ply:Nick())

    -- Sync
    if SERVER then
        net.Start("B2CTF_FlagEventUpdate")
        net.WriteUInt(FLAG_EVENT_GRAB, NET_EVENT_LEN)
        net.WriteUInt(flagID, NET_FLAG_ID_LEN)
        net.WriteEntity(ply)
        net.Broadcast()
    end
end

function FlagManager:CaptureFlag(flagID, asd) -- TODO
    -- TODO: Validate params

    self.flags[flagID].grabbedBy = nil
    self.flags[flagID].droppedPos = nil
    self.flags[flagID].droppedTs = nil

    -- Sync
    if SERVER then
        net.Start("B2CTF_FlagEventUpdate")
        net.WriteUInt(FLAG_EVENT_CAPTURE, NET_EVENT_LEN)
        net.WriteUInt(flagID, NET_FLAG_ID_LEN)
        net.Broadcast()
    end
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

-- The basic structure of FlagManager is ready

if CLIENT then
    include("cl_flag.lua") -- Include cl_flag.lua here, so we can catch the first InitComplete hook
end

FlagManager:Reset() -- initial setup

-- And now, do stuff from server side to make things tick

if SERVER then

    function FlagManager:_checkCapture(ply)
        local potentialCapture = nil
        for i, v in ipairs(self.flags) do -- Normally I would write two for loops, but this feels a little more optimized

            if v.grabbedBy == ply then return end -- the player is already holding a flag

            if v.grabbedBy then continue end -- ignore grabbed flags
            if v.belongsToTeam == ply:Team() then continue end -- ignore own flags
            if ply:GetPos():DistToSqr(v.homePos) < 2100 then
                potentialCapture = i
            end
        end
        if potentialCapture then
            self:GrabFlag(potentialCapture, ply)
        end
    end
    hook.Add("PlayerTick", "B2CTF_CheckFlagCapture", function(ply) -- WARNING: Does not run when in vehicle!
        if not Phaser:CurrentPhaseInfo().fightAllowed then return end -- do nothing, when we are not fighting
        if IsValid(ply) and ply:IsPlayer() and ply:TeamValid() and ply:Alive() then -- only work for players who are in valid team, and alive
            FlagManager:_checkCapture(ply)
        end
    end)

    function FlagManager:_checkAndDropFlag(ply)
        for i, v in ipairs(self.flags) do
            if v.grabbedBy == ply then
                self:DropFlag(i, ply:GetPos(), CurTime())
            end
        end
    end
    hook.Add( "PlayerDeath", "B2CTF_DropFlag", function( victim, inflictor, attacker )
        if IsValid(victim) and victim:IsPlayer() and victim:TeamValid() then
            FlagManager:_checkAndDropFlag(victim)
        end
    end )

end

hook.Add("B2CTF_PhaseChanged", "ResetFlagsAtTheEndOfWar", function(newPhaseID, newPhaseInfo, oldPhaseID, oldPhaseInfo, startTime, endTime)
    if (not oldPhaseID) or (oldPhaseInfo.fightAllowed and (not newPhaseInfo.fightAllowed)) then -- When we don't know the previous phase, it's safer to just reset
        FlagManager:Reset()
    end
end)


if CLIENT then -- sync recv
    net.Receive( "B2CTF_FlagEventUpdate", function( len, ply )
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
            FlagManager:ReturnFlag(flagID)
        end

        if event == FLAG_EVENT_GRAB then
            local flagID = net.ReadUInt(NET_FLAG_ID_LEN)
            local grabber = net.ReadEntity()
            FlagManager:GrabFlag(flagID, grabber)
        end

        if event == FLAG_EVENT_CAPTURE then
            local flagID = net.ReadUInt(NET_FLAG_ID_LEN)
            FlagManager:CaptureFlag(flagID, nil) -- TODO
        end

    end)

    net.Receive( "B2CTF_FlagFullSync", function( len, ply )
        -- TODO

    end)

end

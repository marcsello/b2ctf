local meta = FindMetaTable("Player")
if not meta then return end

function meta:TeamValid()
    local teamID = self:Team()
    return teamID > 0 and teamID < 1000 and team.Valid(teamID)
end

function meta:CurrentlyBuilding()
    if not IsValid( self ) then return false end

    if not self:TeamValid() then
        -- not in team
        return false
    end

    if not Phaser:CurrentPhaseInfo().buildAllowed then
        -- the current phase does not allow building
        return false
    end

    if not self:AtHome() then
        -- not at home site
        return false
    end

    return true

end

-- A very basic ready system's data layer
-- It works only on server side

local nw2PlayerReadyKey = "b2ctf_isReady"
function meta:IsReady()
    return self:GetNW2Bool( nw2PlayerReadyKey, false )
end

if SERVER then
    -- Setters are available server-side only

    function meta:SetReady(rdy)
        -- currently we only allow changing ready state from the server.
        -- This might be a changed later so that the code be extended by 3rd party addons to toggle ready state from client Lua

        local oldState = self:IsReady()
        if rdy == oldState then return end -- do nothing if it's not an actual change

        local changeAllowed = hook.Run("B2CTF_PlayerCanChangeReadyState", self, oldState, rdy) -- called server side only
        if changeAllowed == false then -- nil = don't care
            -- do nothing if we are not allowed to do anything
            return
        end

        self:SetNW2Bool( nw2PlayerReadyKey, rdy )

        hook.Run("B2CTF_PlayerChangedReadyState", self, oldState, rdy) -- called on server side only
    end

    function meta:ClearReady()
        -- this is a bit hacky solution... it does not call any handlers
        -- used to reset the ready state on phase change
        self:SetNW2Bool( nw2PlayerReadyKey, false )
    end

end

-- We would like to cache AtHome, because it's slow to calculate and may be used multiple times per tick
-- it also does not have to be that precise

function meta:AtHome()
    return self._b2ctf_atHome
end

function meta:_setAtHome(atHome)
    self._b2ctf_atHome = atHome
end

local function updateAtHome(ply)
    if not (ply and IsValid(ply)) then return end
    if not ply:TeamValid() then return end -- only check if player valid
    local teamInfo = B2CTF_MAP.teams[ply:Team()]
    assert(teamInfo, "failed to get team info") -- this must be an error
    ply:_setAtHome(
        ply:GetPos():WithinAABox(teamInfo.boundaries[1], teamInfo.boundaries[2]) -- <- heavy stuff
    )
end


timer.Create("B2CTF_SlowUpdateAtHome", 0.25, 0, function()
    if not B2CTF_MAP then return end

    for _, ply in ipairs( player.GetAll() ) do
        if CLIENT and ply == LocalPlayer() then continue end -- ignore local player on client side, we use PreciseUpdate for that
        updateAtHome(ply)
    end

end)

if CLIENT then
    -- Setup PreciseUpdate for the local player on client side, for better UX
    hook.Add("Think", "B2CTF_PreciseUpdateLocalAtHome", function()
        if not B2CTF_MAP then return end
        updateAtHome(LocalPlayer())
    end )
end

hook.Add( "PlayerSpawn", "B2CTF_UpdateAtHomeOnSpawn", function(ply)
    -- This is required because some hooks that run after spwan (Loadout for example)
    -- would wrongly assume that the player is not at home, because the slow update timer haven't ran yet
    -- PlayerSpawn hook is called before the Loadout hook,
    ply:_setAtHome(true) -- They usually spawn at home
end )

-- Override Add count, used for entity owner tracking
-- inspiration taken from https://github.com/FPtje/Falcos-Prop-protection/blob/master/lua/fpp/server/core.lua
if meta.AddCount then
    origAddCount = meta.AddCount
    function meta:AddCount(Type, ent)
        if not IsValid(self) or not IsValid(ent) then return origAddCount(self, Type, ent) end
        ent:B2CTFSetCreator(self)
        return origAddCount(self, Type, ent)
    end
end

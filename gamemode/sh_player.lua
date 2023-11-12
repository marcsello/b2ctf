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

-- We would like to cache AtHome, because it's slow to calculate and may be used multiple times per tick
-- it also does not have to be that precise

function meta:AtHome()
    return self._b2ctf_atHome
end

function meta:_setAtHome( atHome )
    self._b2ctf_atHome = atHome
end


timer.Create("B2CTF_SlowUpdateAtHome", 0.25, 0, function()
    if not B2CTF_MAP then return end

    for _, ply in ipairs( player.GetAll() ) do
        if not ( ply and IsValid( ply ) ) then continue end -- glua implements continue lol
        if not ply:TeamValid() then continue end -- ignores connecting, spectator etc.
        local teamInfo = B2CTF_MAP.teams[ply:Team()]
        assert(teamInfo, "failed to get team info") -- this must be an error

        ply:_setAtHome(
            ply:GetPos():WithinAABox(teamInfo.boundaries[1], teamInfo.boundaries[2]) -- <- the heavy stuff
        )

    end

end)

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

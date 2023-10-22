local meta = FindMetaTable("Player")
if not meta then return end

function meta:TeamValid()
    return self:Team() > 0 and self:Team() < 1000
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

function meta:AtHome()
    if not ( self and IsValid( self ) ) then return end
    if not self:TeamValid() then return end

    local teamInfo = B2CTF_MAP.teams[self:Team()]
    if not teamInfo then return end

    return self:GetPos():WithinAABox(teamInfo.boundaries[1], teamInfo.boundaries[2])
end

-- Override Add count, used for entity owner tracking
-- inspiration taken from https://github.com/FPtje/Falcos-Prop-protection/blob/master/lua/fpp/server/core.lua
if meta.AddCount then
    origAddCount = meta.AddCount
    function meta:AddCount(Type, ent)
        if not IsValid(self) or not IsValid(ent) then return origAddCount(self, Type, ent) end
        print(ent)
        ent:B2CTFSetCreator(self)
        return origAddCount(self, Type, ent)
    end
end

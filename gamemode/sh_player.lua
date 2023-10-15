local meta = FindMetaTable("Player")
if not meta then return end

function meta:CurrentlyBuilding()
    if not IsValid( self ) then return false end

    if self:Team() == 0 or self:Team() > 1000 then
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
    if self:Team() == 0 or self:Team() > 1000 then return end

    local teamInfo = B2CTF_MAP.teams[self:Team()]
    if not teamInfo then return end

    return self:GetPos():WithinAABox(teamInfo.boundaries[1], teamInfo.boundaries[2])
end

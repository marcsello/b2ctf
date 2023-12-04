-- Entity owner
local entityCreator = {
    lastLookedEntity = nil,

    -- cached stuff
    shouldDraw = false,
    creatorTeamColor = nil,
    creatorTeamName = nil,
    creatorNick = nil,
    nameX = nil,
    nameY = nil,
    teamX = nil,
    teamY = nil,
    boxX = nil,
    boxY = nil,
    boxW = nil,
    boxH = nil,
}

function entityCreator:Draw()
    -- calculate stuff
    local recalculateStuff = false
    local lEnt = LocalPlayer():GetEyeTrace().Entity -- get the looked at entity
    if self.lastLookedEntity ~= lEnt then -- if it's changed, then update the cached vars
        local lEntCreator = lEnt:B2CTFGetCreator()
        if lEntCreator and IsValid (lEntCreator) and lEntCreator:TeamValid() then
            self.creatorTeamColor = team.GetColor(lEntCreator:Team())
            self.creatorTeamName = team.GetName(lEntCreator:Team())
            self.creatorNick = lEntCreator:Nick()
            self.shouldDraw = true
            recalculateStuff = true
        else
            self.creatorTeamColor = nil
            self.creatorTeamName = nil
            self.creatorNick = nil
            self.shouldDraw = false
        end
    end

    if not self.shouldDraw then return end -- nothing to draw here

    -- draw
    surface.SetFont("DermaDefault")

    if recalculateStuff then
        -- just kidding calculate some more...
        local nameW, nameH = surface.GetTextSize( self.creatorNick )
        local teamW, teamH = surface.GetTextSize( self.creatorTeamName )

        self.boxW = math.max(nameW, teamW) + 15 -- 5 left, 10 right
        self.boxH = nameH + teamH + 10 -- 5 above, 5 bellow
        self.boxX = ScrW() - self.boxW
        self.boxY = ScrH() * 0.4

        self.nameX = ScrW() - nameW - 10
        self.nameY = ScrH() * 0.4 + 5

        self.teamX = ScrW() - math.max(teamW, nameW) - 10
        self.teamY = ScrH() * 0.4 + 5 + teamH
    end

    -- now we are drawing

    -- box
    surface.SetDrawColor(0,0,0,128)
    surface.DrawRect(self.boxX, self.boxY, self.boxW, self.boxH)

    -- Owner
    surface.SetTextColor(0, 0, 0, 255)
    surface.SetTextPos(self.nameX + 1, self.nameY + 1)
    surface.DrawText(self.creatorNick, false)

    surface.SetTextColor(255, 255, 255, 255)
    surface.SetTextPos(self.nameX, self.nameY)
    surface.DrawText(self.creatorNick, false)

    -- Team
    surface.SetTextPos(self.teamX + 1, self.teamY + 1)
    surface.DrawText(self.creatorTeamName, false)

    surface.SetTextColor(self.creatorTeamColor:Unpack())
    surface.SetTextPos(self.teamX, self.teamY)
    surface.DrawText(self.creatorTeamName, false)


end

return entityCreator

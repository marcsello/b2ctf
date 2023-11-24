-- Entity owner
local entityCreator = {
    lastLookedEntity = nil,

    -- cached stuff
    shouldDraw = false,
    creatorTeamColor = nil,
    creatorTeamName = nil,
    creatorNick = nil,
}

function entityCreator:Draw()
    -- calculate stuff
    local lEnt = LocalPlayer():GetEyeTrace().Entity -- get the looked at entity
    if self.lastLookedEntity ~= lEnt then -- if it's changed, then update the cached vars
        local lEntCreator = lEnt:B2CTFGetCreator()
        if lEntCreator and IsValid (lEntCreator) and lEntCreator:TeamValid() then
            self.creatorTeamColor = team.GetColor(lEntCreator:Team())
            self.creatorTeamName = team.GetName(lEntCreator:Team())
            self.creatorNick = lEntCreator:Nick()
            self.shouldDraw = true
        else
            self.creatorTeamColor = nil
            self.creatorTeamName = nil
            self.creatorNick = nil
            self.shouldDraw = false
        end
    end

    if not self.shouldDraw then return end -- nothing to draw here

    -- draw
    -- just kidding calculate some more...
    surface.SetFont("DermaDefault")
    local nameW, nameH = surface.GetTextSize( self.creatorNick )
    local teamW, teamH = surface.GetTextSize( self.creatorTeamName )

    local boxW = math.max(nameW, teamW) + 15 -- 5 left, 10 right
    local boxH = nameH + teamH + 10 -- 5 above, 5 bellow
    local boxX = ScrW() - boxW
    local boxY = ScrH() * 0.4

    surface.SetDrawColor(0,0,0,128)
    surface.DrawRect(boxX, boxY, boxW, boxH)

    local nameX = ScrW() - nameW - 10
    local nameY = ScrH() * 0.4 + 5

    local teamX = ScrW() - math.max(teamW, nameW) - 10
    local teamY = ScrH() * 0.4 + 5 + teamH

    -- now we are drawing
    -- Owner
    surface.SetTextColor(0, 0, 0, 255)
    surface.SetTextPos(nameX + 1, nameY + 1)
    surface.DrawText(self.creatorNick, false)

    surface.SetTextColor(255, 255, 255, 255)
    surface.SetTextPos(nameX, nameY)
    surface.DrawText(self.creatorNick, false)

    -- Team
    surface.SetTextPos(teamX + 1, teamY + 1)
    surface.DrawText(self.creatorTeamName, false)

    surface.SetTextColor(self.creatorTeamColor:Unpack())
    surface.SetTextPos(teamX, teamY)
    surface.DrawText(self.creatorTeamName, false)


end

function entityCreator:Init()


end


return entityCreator

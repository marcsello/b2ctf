
surface.CreateFont( "B2CTF_GameEndPopup_Header", {
    font = "Arial",
    size = 52,
} )

local headerTable = {
    Init = function(self)

        self.bigText = vgui.Create("DLabel", self)
        self.bigText:SetFont("B2CTF_GameEndPopup_Header")
        self.bigText:SetAutoStretchVertical(true)
        self.bigText:Dock(TOP)
        self.bigText:SetContentAlignment( 5 )
        self.bigText:SetColor(text_white)
        self.bigText:SetText("Szia anyu!")

    end,
    GetContentSize = function(self)
        return self.bigText:GetSize()
    end,
    PerformLayout = function(self)
        self:SizeToContentsY()
    end,
    Update = function(self, teamID)
        local lText = "Draw!"
        local lColor = color_black
        if teamID then
            lText = team.GetName(teamID) .. " team won!"
            lColor = team.GetColor(teamID)
        end

        self.bigText:SetText(lText)
        self.bigText:SetExpensiveShadow( 2, lColor )
        self:InvalidateLayout()
    end,
    Paint = function(self, w, h)
        draw.NoTexture()
        surface.SetDrawColor(0, 0, 0, 192)
        surface.DrawRect(0, 0, w, h)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
    end,
}


return vgui.RegisterTable(headerTable, "EditablePanel")

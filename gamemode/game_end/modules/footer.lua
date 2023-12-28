local footerTable = {
    Init = function(self)

        self:SetTall(32 + 2 * 2)

        self.closeButton = vgui.Create("DButton", self, "closeBtn")
        self.closeButton:SetText("Close")
        self.closeButton:SetTall(32)
        self.closeButton:Dock(FILL)

        self.closeButton.DoClick = function()
            self:GetParent():Hide() -- should be the popup itself
        end

    end,
    PerformLayout = function(self)
        local closeButtonW = 100
        local closeButtonMarginW = self:GetWide() / 2 - closeButtonW / 2
        self.closeButton:DockMargin(closeButtonMarginW, 2, closeButtonMarginW, 2)
    end,
    Update = function(self)

    end,
    Paint = function(self, w, h)
        draw.NoTexture()
        surface.SetDrawColor(0, 0, 0, 192)
        surface.DrawRect(0, 0, w, h)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
    end,
    Think = function(self, w, h)

    end,

}


return vgui.RegisterTable(footerTable, "EditablePanel")

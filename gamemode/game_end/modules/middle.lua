local middleTable = {
    Init = function(self)

        -- self:SetTall(320) using FILL


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


return vgui.RegisterTable(middleTable, "EditablePanel")

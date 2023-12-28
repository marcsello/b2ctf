
local headerTable = include("header.lua")
local middleTable = include("middle.lua")
local footerTable = include("footer.lua")

local gameEndPopupTable = {
    Init = function(self)

        self.header = vgui.CreateFromTable(headerTable, self, "header")
        self.header:DockMargin(0, 0, 0, 2)
        self.header:Dock(TOP)

        self.middle = vgui.CreateFromTable(middleTable, self, "middle")
        self.middle:DockMargin(0, 2, 0, 2)
        self.middle:Dock(FILL)

        self.footer = vgui.CreateFromTable(footerTable, self, "footer")
        self.footer:DockMargin(0, 2, 0, 0)
        self.footer:Dock(BOTTOM)

    end,
    Update = function(self, stats)

        local winningTeamID = nil

        if #stats.finalOrder > 0 and #stats.finalOrder[1].teams == 1 then
            winningTeamID = stats.finalOrder[1].teams[1]
        end

        self.header:Update(winningTeamID)
        self.middle:Update()
        self.footer:Update()

    end,
    PerformLayout = function(self)
        self:SetSize(1200, ScrH() - 400)
        self:SetPos(ScrW() / 2 - (1200 / 2), 200)
    end,
    Paint = function(self, w, h)
        -- don't draw it
    end,
}

return vgui.RegisterTable(gameEndPopupTable, "EditablePanel")

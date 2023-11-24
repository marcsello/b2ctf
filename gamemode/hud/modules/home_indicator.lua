-- Home indicator
local homeIndicator = {
    x = ScrW() - 32 - 16,
    y = ScrH() * 0.8,
    iconSize = 32,

    homeSymbol = nil,
    homeSymbolAway = nil
}

function homeIndicator:Draw()
    surface.SetDrawColor(255, 255, 255, 255)
    if LocalPlayer():AtHome() then -- AtHome is quick to read
        surface.SetMaterial(self.homeSymbol)
    else
        surface.SetMaterial(self.homeSymbolAway)
    end
    surface.DrawTexturedRect(self.x, self.y, self.iconSize, self.iconSize)
end

function homeIndicator:Init()
    self.homeSymbol = Material("icon16/house.png")
    self.homeSymbolAway = Material("icon16/house_go.png")
end

return homeIndicator

-- Draw all the custom HUD elements

if not Config.UseBuiltinHUDRendering then
    print("B2CTF Builtin HUD rendering is disabled")
    return
end

-- some utility functions to work with polygons
local function transformPoly(poly, transformX, transformY)
    local newPoly = {}
    for i,v in ipairs(poly) do
        newPoly[i] = {
            x = v.x + transformX,
            y = v.y + transformY
        }
    end
    return newPoly
end

-- The timer

local timerHUD = {
    -- settings
    w = 300,
    h = 40,
    slopeSize = 35,
    border = 4,

    -- placeholders
    phaseName = "",
    startTime = 0,
    endTime = 0,
    warnTime = 0,
}

function timerHUD:Init()
    local basePoly = {
        {x = -self.border,            y = 0     },
        {x = self.w + self.border,    y = 0     },
        {x = self.w - self.slopeSize + self.border/2, y = self.h + self.border},
        {x = self.slopeSize - self.border/2,          y = self.h + self.border},
    }

    -- put it to the top center of the screen
    self.basePoly = transformPoly(basePoly, ScrW() / 2 - self.w / 2, 0)

    surface.CreateFont( "B2CTF_HUD_Timer_Phase", {
        font = "Arial", --  Use the font-name which is shown to you by your operating system Font Viewer, not the file name
        size = self.h * 0.6,
    } )

    surface.CreateFont( "B2CTF_HUD_Timer_Time", {
        font = "RobotoBold", --  Use the font-name which is shown to you by your operating system Font Viewer, not the file name
        size = self.h * 0.4,
    } )


end

function timerHUD:_yFunc(x)
    if x > self.slopeSize and (x < self.w - self.slopeSize) then
        return self.h
    elseif x <= self.slopeSize then
        return self.h * (x / self.slopeSize)
    else  -- possibly x > self.w - self.slopeSize
        local scaledX = x - (self.w - self.slopeSize)
        return self.h - self.h * (scaledX / self.slopeSize)
    end
end

function timerHUD:_calcFillPoly(length)
    local fillPoly = {
        {x = 0,      y = 0},
        {x = length, y = 0},
    }
    if length > (self.w-self.slopeSize) then
        -- over both points
        fillPoly[3] = {x = length, y = self:_yFunc(length)}
        fillPoly[4] = {x = self.w - self.slopeSize, y = self.h}
        fillPoly[5] = {x = self.slopeSize, y = self.h}
    elseif length < self.slopeSize then
        -- no points
        fillPoly[3] = {x = length, y = self:_yFunc(length)}
    else
        -- over the first point only
        fillPoly[3] = {x = length, y = self.h}
        fillPoly[4] = {x = self.slopeSize, y = self.h}
    end

    return transformPoly(fillPoly, ScrW() / 2 - self.w / 2, 0)
end

function timerHUD:Draw()
    -- calculate stuff
    local timeLeft = self.endTime - CurTime()
    if timeLeft < 0 then
        timeLeft = 0
    end
    local phaseTime = self.endTime - self.startTime
    local length = self.w * (timeLeft / phaseTime)
    local fillPoly = self:_calcFillPoly(length) -- this might be a little costy, but there is not real benefit to move it out
    local minutesLeft = math.floor(timeLeft / 60)
    local secondsLeft = math.floor(timeLeft % 60)
    local timeLeftText = string.format("%02d:%02d", minutesLeft, secondsLeft)
    local blink = (timeLeft < self.warnTime) and (CurTime() - math.floor(CurTime()) > 0.5)

    -- draw stuff
    draw.NoTexture()
    surface.SetDrawColor(0,0,0,128)
    surface.DrawPoly(self.basePoly)
    surface.SetDrawColor(255,255,255,128)
    surface.DrawPoly(fillPoly)
    surface.SetTextColor(255, 120, 0, 255)


    surface.SetFont("B2CTF_HUD_Timer_Phase")
    local textW, textH = surface.GetTextSize(self.phaseName)
    surface.SetTextPos(ScrW() / 2 - textW / 2, 0)
    surface.DrawText(self.phaseName, false)

    if blink then
        surface.SetTextColor(255, 0, 0, 255)
    end

    surface.SetFont("B2CTF_HUD_Timer_Time")
    local textW = surface.GetTextSize(timeLeftText)
    surface.SetTextPos(ScrW() / 2 - textW / 2, textH)
    surface.DrawText(timeLeftText, false)

end

function timerHUD:UpdateInfo(phaseName, startTime, endTime, warnTime)
    self.phaseName = phaseName
    self.startTime = startTime
    self.endTime = endTime
    self.warnTime = warnTime
end

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

-- Init stuff

timerHUD:Init()
homeIndicator:Init()
entityCreator:Init()

-- Call hooks
local function DrawB2CTFHUD()
    if hook.Run("HUDShouldDraw", GAMEMODE, "B2CTFTimer") then
        timerHUD:Draw()
    end
    if hook.Run("HUDShouldDraw", GAMEMODE, "B2CTFHomeIndicator") then
        homeIndicator:Draw()
    end
    if hook.Run("HUDShouldDraw", GAMEMODE, "B2CTFEntityCreator") then
        entityCreator:Draw()
    end

end
hook.Add("HUDPaint", "B2CTF_HUD", DrawB2CTFHUD)

hook.Add("B2CTF_PhaseChanged", "UpdateHudValues", function(newPhaseID, newPhaseInfo, oldPhaseID, oldPhaseInfo, startTime, endTime)
    timerHUD:UpdateInfo(newPhaseInfo.name, startTime, endTime, newPhaseInfo.warnTime)
end )

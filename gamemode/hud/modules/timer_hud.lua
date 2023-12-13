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
        font = "Arial",
        size = self.h * 0.6,
    } )

    surface.CreateFont( "B2CTF_HUD_Timer_Time", {
        font = "RobotoBold",
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
    -- Get data
    local phaseInfo = Phaser:CurrentPhaseInfo()
    -- calculate stuff
    local timeLeft = Phaser:CurrentPhaseTimeLeft()
    if timeLeft < 0 then
        timeLeft = 0
    end
    local length = self.w * (timeLeft / phaseInfo.time)
    local fillPoly = self:_calcFillPoly(length) -- this might be a little costy, but there is not real benefit to move it out
    local minutesLeft = math.floor(timeLeft / 60)
    local secondsLeft = math.floor(timeLeft % 60)
    local timeLeftText = string.format("%02d:%02d", minutesLeft, secondsLeft)
    local blink = (timeLeft < phaseInfo.warnTime) and (CurTime() - math.floor(CurTime()) > 0.5)

    -- draw stuff
    draw.NoTexture()
    surface.SetDrawColor(0,0,0,128)
    surface.DrawPoly(self.basePoly)
    surface.SetDrawColor(255,255,255,128)
    surface.DrawPoly(fillPoly)
    surface.SetTextColor(255, 120, 0, 255)


    surface.SetFont("B2CTF_HUD_Timer_Phase")
    local textW, textH = surface.GetTextSize(phaseInfo.name)
    surface.SetTextPos(ScrW() / 2 - textW / 2, 0)
    surface.DrawText(phaseInfo.name, false)

    if blink then
        surface.SetTextColor(255, 0, 0, 255)
    end

    surface.SetFont("B2CTF_HUD_Timer_Time")
    local textW = surface.GetTextSize(timeLeftText)
    surface.SetTextPos(ScrW() / 2 - textW / 2, textH)
    surface.DrawText(timeLeftText, false)

end


return timerHUD

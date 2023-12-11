-- Home indicator

local CHANGE_INDICATION_TIME = 1.8 -- sec

local _cardW = 32 * 2 + 48
local _border = 6
local flagsIndicator = {
    homeTeamIconX = ScrW() - 32 - 16,
    homeTeamIconY = ScrH() * 0.8 - 48, -- draw it above the home indicator
    iconSize = 32,
    border = _border,

    -- used as a baseline without border
    battleIndicatorsStartY = ScrH() * 0.8 - 48 - _border,
    battleIndicatorsX = ScrW() - _cardW - 16, -- leave a bit bigger space for the score
    battleIndicatorCardW = _cardW,
    battleIndicatorCardH = 32,

    -- assets
    iconTaken = nil,
    iconDropped = nil,
    iconReturned = nil,

    -- values updated externally
    isBuildingPhase = false,
    flagsReturnedRecently = {},
    teamsScoredRecently = {}
}

function flagsIndicator:_isFlagReturnedRecently(flagID)
    if self.flagsReturnedRecently[flagID] != nil then
        local drawUntil = self.flagsReturnedRecently[flagID]
        if drawUntil > CurTime() then
            return true
        else
            self.flagsReturnedRecently[flagID] = nil
        end
    end
    return false
end

function flagsIndicator:_isTeamsScoredRecently(teamID)
    if self.teamsScoredRecently[teamID] != nil then
        local drawUntil = self.teamsScoredRecently[teamID]
        if drawUntil > CurTime() then
            return true
        else
            self.teamsScoredRecently[teamID] = nil
        end
    end
    return false
end

function flagsIndicator:_drawSmall(ply)
    surface.SetDrawColor(255, 255, 255, 255)
    surface.SetMaterial(B2CTF_MAP.teams[ply:Team()]._iconMat)
    surface.DrawTexturedRect(self.homeTeamIconX, self.homeTeamIconY, self.iconSize, self.iconSize)
end

function flagsIndicator:_drawBig(ply)

    surface.SetFont("B2CTF_HUD_FlagsIndicator_Score")
    local shiftUp = 0
    for teamID, flagData in FlagManager:IterFlags() do
        if team.NumPlayers(teamID) == 0 then continue end -- don't draw for empty teams
        local teamData = B2CTF_MAP.teams[teamID]
        local teamScore = team.GetScore(teamID)

        -- Draw base card
        surface.SetDrawColor(0,0,0,128)
        local boxX = self.battleIndicatorsX - self.border
        local boxY = self.battleIndicatorsStartY - shiftUp - self.border
        local boxW = self.battleIndicatorCardW + self.border * 2
        local boxH = self.battleIndicatorCardH + self.border * 2
        surface.DrawRect(boxX, boxY, boxW, boxH)

        -- Indicate somehow the home team... TODO: This is super-ugly
        if teamID == ply:Team() then
            surface.SetDrawColor(teamData.color.r, teamData.color.g, teamData.color.b, 192)
            surface.DrawOutlinedRect(boxX, boxY, boxW, boxH, 1)
        end

        -- Draw card contents
        surface.SetDrawColor(255,255,255,255)

        -- the flag icon itself
        surface.SetMaterial(B2CTF_MAP.teams[teamID]._iconMat)
        surface.DrawTexturedRect(self.battleIndicatorsX, self.battleIndicatorsStartY - shiftUp, self.iconSize, self.iconSize)

        -- Status icon
        local drawSecondIcon = false
        if flagData.grabbedBy != nil then
            surface.SetMaterial(self.iconTaken)
            drawSecondIcon = true
        elseif flagData.droppedPos != nil then
            surface.SetMaterial(self.iconDropped)
            drawSecondIcon = true
        elseif self:_isFlagReturnedRecently(teamID) then
            surface.SetMaterial(self.iconReturned)
            drawSecondIcon = true
        end
        if drawSecondIcon then
            surface.DrawTexturedRect(self.battleIndicatorsX + self.iconSize + 4, self.battleIndicatorsStartY - shiftUp, self.iconSize, self.iconSize)
        end

        -- team score
        local textW = surface.GetTextSize(teamScore)

        local textX = self.battleIndicatorsX + self.battleIndicatorCardW - textW
        local textY = self.battleIndicatorsStartY - shiftUp

        local shiftB = 1
        local shiftF = 0
        if self:_isTeamsScoredRecently(teamID) then
            -- Shift the front and the back further away on team score
            shiftB = 2
            shiftF = -2
        end
        surface.SetTextColor(teamData.color:Unpack())
        surface.SetTextPos(textX + shiftB, textY + shiftB)
        surface.DrawText(teamScore, false)

        surface.SetTextColor(255, 255, 255, 255)
        surface.SetTextPos(textX + shiftF, textY + shiftF)
        surface.DrawText(teamScore, false)

        -- shift up the next card
        shiftUp = shiftUp + self.iconSize + 16
    end

end

function flagsIndicator:Draw()
    local ply = LocalPlayer()
    if not (IsValid(ply) and ply:TeamValid()) then return end

    if self.isBuildingPhase then
        -- In building phase, just draw a small team icon
        flagsIndicator:_drawSmall(ply)
    else
        -- During battle, draw everything
        flagsIndicator:_drawBig(ply)
    end
end

function flagsIndicator:Init()
    self.iconTaken = Material("icon16/arrow_turn_right.png")
    self.iconDropped = Material("icon16/arrow_down.png")
    self.iconReturned = Material("icon16/arrow_undo.png")

    surface.CreateFont( "B2CTF_HUD_FlagsIndicator_Score", {
        font = "Arial",
        size = 32,
    } )
end

function flagsIndicator:OnPhaseChanged(newPhaseID, newPhaseInfo, oldPhaseID, oldPhaseInfo, startTime, endTime)
    self.isBuildingPhase = newPhaseInfo.buildAllowed
end

function flagsIndicator:_indicateReturn(flagID)
    self.flagsReturnedRecently[flagID] = CurTime() + CHANGE_INDICATION_TIME
end

function flagsIndicator:_indicateTeamScored(teamID)
    self.teamsScoredRecently[teamID] = CurTime() + CHANGE_INDICATION_TIME
end

-- only the OnPhaseChanged should be defined as a class method, and invoked by the hud mangager, because it is hacked-around
hook.Add("B2CTF_FlagReturned", "HudFlagsIndicatorReturned", function(flagID, homePos, autoReturn, ply)
    flagsIndicator:_indicateReturn(flagID)
end )

hook.Add("B2CTF_FlagCaptured", "HudFlagsIndicatorScore", function(flagID, capturerTeamID, capturedBy)
    flagsIndicator:_indicateTeamScored(capturerTeamID)
end )

return flagsIndicator

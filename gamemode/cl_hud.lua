-- Draw all the custom HUD elements

local teamID = -1
local teamIDValid = false
local grabbedAnyFlag = false
local iconSize = 32

local homeSymbol = Material("models/wireframe")

local lookingAtOwnerNick = nil
local lookingAtOwnerTeamColor = nil
local lookingAtOwnerTeamName = nil

local background = Color(0, 0, 0, 128)

timer.Create("B2CTF_SlowUpdateHUDValues", 0.2, 0, function()
    -- Update these values less frequently, as they are costly to caluclate
    if not IsValid(LocalPlayer()) then return end
    teamID = LocalPlayer():Team() -- this is actually quick to read, but we want it to be consistent with other slow things
    teamIDValid = LocalPlayer():TeamValid() and FlagManager:FlagIDValid(teamID)
    grabbedAnyFlag = FlagManager:GetFlagIDGrabbedByTeam(teamID) ~= nil

    local lEnt = LocalPlayer():GetEyeTrace().Entity
    local lo = nil
    if lEnt then
        lo = lEnt:B2CTFGetCreator()
    end

    if lo and IsValid ( lo ) and lo:TeamValid() then
        lookingAtOwnerNick = lo:Nick()
        lookingAtOwnerTeamColor = team.GetColor(lo:Team())
        lookingAtOwnerTeamName = team.GetName(lo:Team())
    else
        lookingAtOwnerNick = nil
        lookingAtOwnerTeamColor = nil
        lookingAtOwnerTeamName = nil
    end

end)

local function drawOwnerInfo() -- TODO: Optimize this
    -- Draw entity creator currently looking at
    if lookingAtOwnerNick then
        surface.SetFont("DermaDefault")
        local nameW, nameH = surface.GetTextSize( lookingAtOwnerNick )
        local teamW, teamH = surface.GetTextSize( lookingAtOwnerTeamName )

        local boxW = math.max(nameW, teamW) + 15 -- 5 left, 10 right
        local boxH = nameH + teamH + 10 -- 5 above, 5 bellow
        local boxX = ScrW() - boxW
        local boxY = ScrH() * 0.4

        surface.SetDrawColor(background)
        surface.DrawRect(boxX, boxY, boxW, boxH)

        local nameX = ScrW() - nameW - 10
        local nameY = ScrH() * 0.4 + 5

        local teamX = ScrW() - math.max(teamW, nameW) - 10
        local teamY = ScrH() * 0.4 + 5 + teamH

        -- Owner
        surface.SetTextColor(0, 0, 0, 255)
        surface.SetTextPos(nameX + 1, nameY + 1)
        surface.DrawText(lookingAtOwnerNick, false)

        surface.SetTextColor(255, 255, 255, 255)
        surface.SetTextPos(nameX, nameY)
        surface.DrawText(lookingAtOwnerNick, false)

        -- Team
        surface.SetTextPos(teamX + 1, teamY + 1)
        surface.DrawText(lookingAtOwnerTeamName, false)

        surface.SetTextColor(lookingAtOwnerTeamColor:Unpack())
        surface.SetTextPos(teamX, teamY)
        surface.DrawText(lookingAtOwnerTeamName, false)
    end
end


local function DrawCustomHUD()
    surface.SetDrawColor(background)
    surface.DrawRect(0, 0, 300, 225)

    if LocalPlayer():AtHome() then -- AtHome is quick to read
        surface.SetDrawColor(255, 255, 255, 255)
        surface.SetMaterial(homeSymbol)
        surface.DrawTexturedRect(10, 10, iconSize, iconSize)
    end
    if teamIDValid then
        if FlagManager.flags[teamID].grabbedBy or FlagManager.flags[teamID].droppedPos then
            -- own flag taken by enemy
            surface.SetDrawColor(B2CTF_MAP.teams[teamID].color)
            surface.SetMaterial(homeSymbol)
            surface.DrawTexturedRect(10, 10 + (iconSize + 2) * 2, iconSize, iconSize)
        end
        if grabbedAnyFlag then
            -- took someone's flag
            surface.SetDrawColor(B2CTF_MAP.teams[teamID].color)
            surface.SetMaterial(homeSymbol)
            surface.DrawTexturedRect(10, 10 + (iconSize + 2) * 3, iconSize, iconSize)
        end
    end

    local timeLeft = Phaser:CurrentPhaseTimeLeft()
    local phaseTime = Phaser:CurrentPhaseInfo().time

    -- Draw current phase name
    draw.SimpleText("Current Phase: " .. Phaser:CurrentPhaseInfo().name, "HudHintTextLarge", 50, 50, color_white, TEXT_ALIGN_LEFT)

    -- Draw next phase name
    draw.SimpleText("Next Phase: " .. Phaser:NextPhaseInfo().name, "HudHintTextLarge", 50, 75, color_white, TEXT_ALIGN_LEFT)

    -- Draw time left in human-readable format
    local minutesLeft = math.floor(timeLeft / 60)
    local secondsLeft = math.floor(timeLeft % 60)
    local timeLeftText = string.format("Time Left: %02d:%02d", minutesLeft, secondsLeft)
    draw.SimpleText(timeLeftText, "HudHintTextLarge", 50, 100, color_white, TEXT_ALIGN_LEFT)

    -- Draw a progress bar
    local progress = 1 - (timeLeft / phaseTime)
    local barWidth = 200
    local barHeight = 20
    surface.SetDrawColor(255, 255, 255, 255)
    surface.DrawRect(50, 125, barWidth, barHeight)
    surface.SetDrawColor(0, 128, 255, 255) -- Adjust the color as needed
    surface.DrawRect(50, 125, barWidth * progress, barHeight)

    for i, t in ipairs(B2CTF_MAP.teams) do
        draw.SimpleText(t.name .. " " .. team.GetScore(i), "HudHintTextLarge", 50, 150 + 15 * i, color_white, TEXT_ALIGN_LEFT)
    end

    drawOwnerInfo()

end

hook.Add("HUDPaint", "B2CTF_HUD", DrawCustomHUD)

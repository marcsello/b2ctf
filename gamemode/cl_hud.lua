-- Draw all the custom HUD elements

local atHome = false
local homeSymbol = Material("phoenix_storms/stripes")

timer.Create("B2CTF_SlowUpdateHUDValues", 0.2, 0, function()
    -- Update these values less frequently, as they are costly to caluclate
    if not IsValid(LocalPlayer()) then return end
    atHome = LocalPlayer():AtHome()
end)



local function DrawCustomHUD()
    if atHome then
        local iconSize = 32
        surface.SetMaterial(homeSymbol)
        surface.SetDrawColor(255, 255, 255, 255) -- Adjust the color as needed
        surface.DrawTexturedRect(10, 10, iconSize, iconSize) -- Adjust the position as needed
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

end

hook.Add("HUDPaint", "B2CTF_HUD", DrawCustomHUD)

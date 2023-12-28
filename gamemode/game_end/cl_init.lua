include("shared.lua")

local GameEndPopupTable = include("modules/game_end_popup.lua")
local gameEndPopup = nil -- don't create it just yet, because it will pop up for no reason

function GM:B2CTF_WarEnded(stats)
    if not IsValid(gameEndPopup) then
        -- re-create it if it got deleted accidentally
        gameEndPopup = vgui.CreateFromTable(GameEndPopupTable)
    end
    gameEndPopup:Update(stats)
    gameEndPopup:Show()
    gameEndPopup:MakePopup()
    gameEndPopup:SetKeyboardInputEnabled(true) -- needed so we can close the thing
end


function GM:B2CTF_NewRoundBegin()
    if IsValid( gameEndPopup ) then
        gameEndPopup:Hide()
    end
end

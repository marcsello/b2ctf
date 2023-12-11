-- Customized scoreboard for B2CTF
-- Pretty much just copied code from https://github.com/Facepunch/garrysmod/blob/master/garrysmod/gamemodes/base/gamemode/cl_scoreboard.lua

local scoreboard = include("modules/scoreboard.lua")

local b2ctf_scoreboard = nil
function GM:ScoreboardShow()

    if not IsValid( b2ctf_scoreboard ) then
        b2ctf_scoreboard = vgui.CreateFromTable( scoreboard )
    end

    if IsValid( b2ctf_scoreboard ) then
        b2ctf_scoreboard:Show()
        b2ctf_scoreboard:MakePopup()
        b2ctf_scoreboard:SetKeyboardInputEnabled( false )
    end

end

function GM:ScoreboardHide()

    if IsValid( b2ctf_scoreboard ) then
        b2ctf_scoreboard:Hide()
    end

end

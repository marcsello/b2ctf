-- Customized scoreboard for B2CTF
-- Pretty much just copied code from https://github.com/Facepunch/garrysmod/blob/master/garrysmod/gamemodes/base/gamemode/cl_scoreboard.lua


local function calcContentSizeByHeight(addH)
    return function(self)
        local height = addH
        for _, elm in ipairs(self:GetChildren()) do
            if not elm:IsMarkedForDeletion() then
                local _, top, _, bottom = elm:GetDockMargin()
                height = height + elm:GetTall() + top + bottom
            end
        end
        return self:GetWide(), height
    end
end

local PLAYER_ROW = {
    Init = function( self )

        self.AvatarButton = self:Add( "DButton" )
        self.AvatarButton:Dock( LEFT )
        self.AvatarButton:SetSize( 32, 32 )
        self.AvatarButton.DoClick = function() self.Player:ShowProfile() end

        self.Avatar = vgui.Create( "AvatarImage", self.AvatarButton )
        self.Avatar:SetSize( 32, 32 )
        self.Avatar:SetMouseInputEnabled( false )

        self.Name = self:Add( "DLabel" )
        self.Name:Dock( FILL )
        self.Name:SetFont( "DermaDefaultBold" )
        self.Name:SetTextColor( color_white )
        self.Name:DockMargin( 8, 0, 0, 0 )
        self.Name:SetExpensiveShadow( 2, Color( 0, 0, 0, 200 ) )
        self.Name:SetText("?")

        self.Mute = self:Add( "DImageButton" )
        self.Mute:SetSize( 32, 32 )
        self.Mute:Dock( RIGHT )

        self.Ping = self:Add( "DLabel" )
        self.Ping:Dock( RIGHT )
        self.Ping:SetWidth( 50 )
        self.Ping:SetFont( "DermaDefaultBold" )
        self.Ping:SetTextColor( color_white )
        self.Ping:SetContentAlignment( 5 )
        self.Ping:SetExpensiveShadow( 2, Color( 0, 0, 0, 200 ) )
        self.Ping:SetText("?")

        self.Deaths = self:Add( "DLabel" )
        self.Deaths:Dock( RIGHT )
        self.Deaths:SetWidth( 50 )
        self.Deaths:SetFont( "DermaDefaultBold" )
        self.Deaths:SetTextColor( color_white )
        self.Deaths:SetContentAlignment( 5 )
        self.Deaths:SetExpensiveShadow( 2, Color( 0, 0, 0, 200 ) )
        self.Deaths:SetText("?")

        self.Kills = self:Add( "DLabel" )
        self.Kills:Dock( RIGHT )
        self.Kills:SetWidth( 50 )
        self.Kills:SetFont( "DermaDefaultBold" )
        self.Kills:SetTextColor( color_white )
        self.Kills:SetContentAlignment( 5 )
        self.Kills:SetExpensiveShadow( 2, Color( 0, 0, 0, 200 ) )
        self.Kills:SetText("?")

        self:Dock( TOP )
        self:DockPadding( 3, 3, 3, 3 )
        self:SetHeight( 32 + 3 * 2 )
        self:DockMargin( 1, 1, 1, 0 )

    end,

    Setup = function(self, ply, teamID)
        print(teamID)

        self.Player = ply
        self.TeamID = teamID

        if not self.TeamID then
            -- should never display score and deaths
            self.Kills:SetText("")
            self.Deaths:SetText("")
        end

        self.Avatar:SetPlayer(ply)

        self:Think(self)

    end,

    Think = function( self )

        if not IsValid( self.Player )  then
            self:SetZPos( 9999 ) -- Causes a rebuild
            self:Remove()
            return
        end

        if ( self.PName == nil || self.PName ~= self.Player:Nick() ) then
            self.PName = self.Player:Nick()
            self.Name:SetText( self.PName )
        end

        if self.TeamID then -- nil on the "spectator" section

            if ( self.NumKills == nil || self.NumKills ~= self.Player:Frags() ) then
                self.NumKills = self.Player:Frags()
                self.Kills:SetText( self.NumKills )
            end

            if ( self.NumDeaths == nil || self.NumDeaths ~= self.Player:Deaths() ) then
                self.NumDeaths = self.Player:Deaths()
                self.Deaths:SetText( self.NumDeaths )
            end

        end

        if ( self.NumPing == nil || self.NumPing ~= self.Player:Ping() ) then
            self.NumPing = self.Player:Ping()
            self.Ping:SetText( self.NumPing )
        end

        --
        -- Change the icon of the mute button based on state
        --
        if ( self.Muted == nil || self.Muted ~= self.Player:IsMuted() ) then

            self.Muted = self.Player:IsMuted()
            if ( self.Muted ) then
                self.Mute:SetImage( "icon32/muted.png" )
            else
                self.Mute:SetImage( "icon32/unmuted.png" )
            end

            self.Mute.DoClick = function( s ) self.Player:SetMuted( !self.Muted ) end
            self.Mute.OnMouseWheeled = function( s, delta )
                self.Player:SetVoiceVolumeScale( self.Player:GetVoiceVolumeScale() + ( delta / 100 * 5 ) )
                s.LastTick = CurTime()
            end

            self.Mute.PaintOver = function( s, w, h )
                if ( !IsValid( self.Player ) ) then return end

                local a = 255 - math.Clamp( CurTime() - ( s.LastTick or 0 ), 0, 3 ) * 255
                if ( a <= 0 ) then return end

                draw.RoundedBox( 4, 0, 0, w, h, Color( 0, 0, 0, a * 0.75 ) )
                draw.SimpleText( math.ceil( self.Player:GetVoiceVolumeScale() * 100 ) .. "%", "DermaDefaultBold", w / 2, h / 2, Color( 255, 255, 255, a ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
            end

        end

        if self.TeamID then
            self:SetZPos( ( self.NumKills * -50 ) + self.NumDeaths + self.Player:EntIndex() )
        end

    end,

    Paint = function( self, w, h )

        if not IsValid( self.Player ) then
            return
        end

        draw.NoTexture()
        surface.SetDrawColor(255,255,255,2)
        surface.DrawRect( 0, 0, w, h)
    end
}

PLAYER_ROW = vgui.RegisterTable( PLAYER_ROW, "DPanel" )


local TEAM_CONTAINER = {

    Init = function(self)

        self:DockMargin( 1, 1, 1, 1 )
        self:Dock(TOP)

        self.Header = self:Add("DPanel")
        self.Header:Dock( TOP )
        self.Header:SetHeight( 32 )
        self.Header.color = color_white
        self.Header.Paint = function(self, w, h)
            draw.NoTexture()
            surface.SetDrawColor(self.color.r, self.color.g, self.color.b, 32)
            surface.DrawRect( 0, 0, w, h)
        end

        self.TeamName = self.Header:Add("DLabel")
        self.TeamName:Dock( LEFT )
        self.TeamName:SetWide(120)
        self.TeamName:SetFont( "DermaLarge" )
        self.TeamName:SetTextColor( color_white )
        self.TeamName:SetContentAlignment( 4 )
        self.TeamName:SetExpensiveShadow( 2, Color( 0, 0, 0, 200 ) )
        self.TeamName:DockMargin( 3, 3, 0, 3 )

        self.TeamPlayers = self.Header:Add("DLabel")
        self.TeamPlayers:Dock( LEFT )
        self.TeamPlayers:SetWide(120)
        self.TeamPlayers:SetFont( "DermaDefaultBold" )
        self.TeamPlayers:SetTextColor( color_white )
        self.TeamPlayers:SetContentAlignment( 4 )
        self.TeamPlayers:SetExpensiveShadow( 2, Color( 0, 0, 0, 200 ) )
        self.TeamPlayers:SetText("? Players")

        self.TeamScore = self.Header:Add("DLabel")
        self.TeamScore:Dock( RIGHT )
        self.TeamScore:SetWide( 50 )
        self.TeamScore:SetFont( "DermaDefaultBold" )
        self.TeamScore:SetTextColor( color_white )
        self.TeamScore:SetContentAlignment(5)
        self.TeamScore:SetExpensiveShadow( 2, Color( 0, 0, 0, 200 ) )
        self.TeamScore:SetText("")
        self.TeamScore:DockMargin( 0, 0, 136, 0 )

        self.Scores = self:Add("DListLayout")
        self.Scores:Dock( TOP )
        self.Scores.GetContentSize = calcContentSizeByHeight(0)

        -- force an instant update with these defaults
        self.PlayerCount = -1
        self.LastScore = -1000
    end,

    Setup = function(self, teamID, persistent)
        self.teamID = teamID
        self.Persistent = persistent
        if self.teamID then
            self.TeamName:SetText(team.GetName(teamID))
            self.color = team.GetColor(teamID)
        else
            self.TeamName:SetText("Spectator")
            self.color = Color(255,255,255,255)
            self:SetZPos(2000) -- "spectators" should show up at the bottom
        end
        self.Header.color = self.color

        self:Think(self)
    end,

    GetContentSize = calcContentSizeByHeight(1), -- we add an extra pixel, so the bottom border won't go bellow the content

    Paint = function(self, w, h)
        draw.NoTexture()
        surface.SetDrawColor(self.color.r, self.color.g, self.color.b, 192)
        surface.DrawOutlinedRect( 0, 0, w, h, 1)
    end,

    GetAssignedPlayers = function(self)
        if self.teamID then -- 0 is truthy in Lua
            return team.GetPlayers(self.teamID)
        else
            -- Gather the players in "invalid" teams
            local players = {}
            for _, ply in ipairs(player.GetAll()) do
                if not ply:TeamValid() then
                    table.insert(players, ply)
                end
            end
            return players
        end

    end,

    Think = function(self)

        -- self destruct when it becomes empty
        if (not self.Persistent) and (self.teamID ~= nil and team.NumPlayers(self.teamID) == 0) then
            self:SetZPos( 9999 ) -- Causes a rebuild
            self:Remove()
            return
        end

        local players = self:GetAssignedPlayers()

        for _, ply in ipairs(players) do

            if IsValid(ply.ScoreBoardEntry) then
                if ply.ScoreBoardEntry.TeamID == self.teamID then
                    -- still in the seam team, and still have a valid entry
                    continue
                else
                    -- the player have an entry, but changed team... let's re-create their entry
                    ply.ScoreBoardEntry:SetZPos(9999)
                    ply.ScoreBoardEntry:Remove()
                end
            end

            ply.ScoreBoardEntry = vgui.CreateFromTable( PLAYER_ROW, ply.ScoreBoardEntry )
            ply.ScoreBoardEntry:Setup(ply, self.teamID)

            self.Scores:Add(ply.ScoreBoardEntry)
        end

        if self.PlayerCount ~= #players then
            self.TeamPlayers:SetText(#players .. " Players")
            self.Scores:SizeToContentsY()
            self:SizeToContentsY()
            self.PlayerCount = #players
        end

        if self.teamID then
            -- Team with higher score should be upper
            self:SetZPos(team.GetScore(self.teamID) * -50 + self.teamID)


            local score = team.GetScore(self.teamID)
            if self.LastScore ~= score then
                self.TeamScore:SetText(score .. "")
                self.LastScore = score
            end
        end

    end

}

TEAM_CONTAINER = vgui.RegisterTable( TEAM_CONTAINER, "DPanel" )

local B2CTF_SCORE_BOARD = {
    Init = function( self )

        --self:SetDraggable(false)

        self.Header = self:Add("Panel")
        self.Header:Dock( TOP )
        self.Header:SetHeight( 32 + 18 )
        self.Header:DockMargin( 5, 5, 5, 5 )

        self.Name = self.Header:Add("DLabel")
        self.Name:SetFont( "DermaLarge" )
        self.Name:SetTextColor( color_white )
        self.Name:Dock( TOP )
        self.Name:SetHeight( 32 )
        self.Name:SetContentAlignment( 7 )
        self.Name:SetExpensiveShadow( 2, Color( 0, 0, 0, 200 ) )

        self.SubHeader = self.Header:Add("Panel")
        self.SubHeader:Dock( TOP )
        self.SubHeader:SetHeight( 18 )

        self.Subtitle = self.SubHeader:Add("DLabel")
        self.Subtitle:SetFont( "DermaDefaultBold" )
        self.Subtitle:SetTextColor( color_white )
        self.Subtitle:Dock( LEFT )
        self.Subtitle:SetWide( 250 )
        self.Subtitle:SetContentAlignment( 7 )
        self.Subtitle:SetExpensiveShadow( 2, Color( 0, 0, 0, 200 ) )

        -- Put up labels

        self.MuteLabel = self.SubHeader:Add( "DLabel" )
        self.MuteLabel:Dock( RIGHT )
        self.MuteLabel:SetWidth( 32 )
        self.MuteLabel:SetFont( "DermaDefaultBold" )
        self.MuteLabel:SetTextColor( color_white )
        self.MuteLabel:SetContentAlignment( 5 )
        self.MuteLabel:SetText("Mute")
        self.MuteLabel:SetExpensiveShadow( 2, Color( 0, 0, 0, 200 ) )

        self.PingLabel = self.SubHeader:Add( "DLabel" )
        self.PingLabel:Dock( RIGHT )
        self.PingLabel:SetWidth( 50 )
        self.PingLabel:SetFont( "DermaDefaultBold" )
        self.PingLabel:SetTextColor( color_white )
        self.PingLabel:SetContentAlignment( 5 )
        self.PingLabel:SetText("Ping")
        self.PingLabel:SetExpensiveShadow( 2, Color( 0, 0, 0, 200 ) )

        self.DeathsLabel = self.SubHeader:Add( "DLabel" )
        self.DeathsLabel:Dock( RIGHT )
        self.DeathsLabel:SetWidth( 50 )
        self.DeathsLabel:SetFont( "DermaDefaultBold" )
        self.DeathsLabel:SetTextColor( color_white )
        self.DeathsLabel:SetContentAlignment( 5 )
        self.DeathsLabel:SetText("Deaths")
        self.DeathsLabel:SetExpensiveShadow( 2, Color( 0, 0, 0, 200 ) )

        self.KillsLabel = self.SubHeader:Add( "DLabel" )
        self.KillsLabel:Dock( RIGHT )
        self.KillsLabel:SetWidth( 50 )
        self.KillsLabel:SetFont( "DermaDefaultBold" )
        self.KillsLabel:SetTextColor( color_white )
        self.KillsLabel:SetContentAlignment( 5 )
        self.KillsLabel:SetText("Score")
        self.KillsLabel:SetExpensiveShadow( 2, Color( 0, 0, 0, 200 ) )

        self.TeamsPanel = self:Add( "DScrollPanel" )
        self.TeamsPanel:Dock( FILL )

        self.Teams = {}

        -- Set up the persistent "everything else" team, other teams will be created on demand
        self.Teams[-1] = vgui.CreateFromTable(TEAM_CONTAINER, self.TeamsPanel, "everyone else")
        self.Teams[-1]:Setup(nil, true)
        self.TeamsPanel:AddItem(self.Teams[-1])

    end,

    PerformLayout = function( self )

        self:SetSize( 900, ScrH() - 400 )
        self:SetPos( ScrW() / 2 - 450, 200 )

    end,

    Paint = function( self, w, h )

        draw.NoTexture()
        surface.SetDrawColor(0, 0, 0, 192)
        surface.DrawRect( 0, 0, w, h)
        surface.DrawOutlinedRect( 0, 0, w, h, 1)

    end,

    Think = function( self, w, h )

        self.Name:SetText( GetHostName() )
        if self.LastPlayerCount == nil or self.LastPlayerCount ~= player.GetCount() then
            self.Subtitle:SetText( "Map: " .. game.GetMap() .. " | Players: " .. player.GetCount() .. "/" .. game.MaxPlayers()  )
        end

        for teamID, teamInfo in pairs(team.GetAllTeams()) do
            if (teamID > 0) and (teamID < 1000) and team.Valid(teamID) then -- we cheat here
                if (team.NumPlayers(teamID) > 0) then
                    if not IsValid(self.Teams[teamID]) then
                        self.Teams[teamID] = vgui.CreateFromTable( TEAM_CONTAINER, self.TeamsPanel, teamInfo.Name)
                        self.Teams[teamID]:Setup(teamID, false)
                        self.TeamsPanel:AddItem(self.Teams[teamID])
                    end
                else
                    if self.Teams[teamID] and (not self.Teams[teamID].Persistent) then
                        self.Teams[teamID] = nil -- Team become empty, and it is not persistent, remove it from the list
                    end
                end
            end
        end

    end
}

B2CTF_SCORE_BOARD = vgui.RegisterTable( B2CTF_SCORE_BOARD, "EditablePanel" )

local b2ctf_scoreboard = nil
function GM:ScoreboardShow()

    if not IsValid( b2ctf_scoreboard ) then
        b2ctf_scoreboard = vgui.CreateFromTable( B2CTF_SCORE_BOARD )
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

hook.Add("OnReloaded", "B2CTF_ResetScoreboardOnReload", function()
    for id, ply in ipairs(player.GetAll()) do
        if IsValid(ply.ScoreBoardEntry) then
            ply.ScoreBoardEntry:Remove()
            ply.ScoreBoardEntry = nil
        end
    end
end)

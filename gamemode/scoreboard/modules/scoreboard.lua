
local teamContainer = include("team_container.lua")

local scoreBoardTable = {
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
        self.Teams[-1] = vgui.CreateFromTable(teamContainer, self.TeamsPanel, "everyone else")
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
                        self.Teams[teamID] = vgui.CreateFromTable( teamContainer, self.TeamsPanel, teamInfo.Name)
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

return vgui.RegisterTable( scoreBoardTable, "EditablePanel" )

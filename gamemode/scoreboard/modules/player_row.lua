
local playerRowTable = {
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

return vgui.RegisterTable( playerRowTable, "DPanel" )

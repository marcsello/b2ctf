
-- comparing ints is a lot faster than comparing strings
local STATUS_NONE = 1
local STATUS_CONNECTING = 2
local STATUS_DEAD = 3
local STATUS_READY = 4

local STATUS_TEXTS = {
    [STATUS_NONE] = "",
    [STATUS_CONNECTING] = "CONNECTING",
    [STATUS_DEAD] = "DEAD",
    [STATUS_READY] = "READY",
}

local flagIcons = {}
for i, v in ipairs(B2CTF_MAP.teams) do
    flagIcons[i] = Material(v.icon)
end

local playerRowTable = {
    Init = function( self )

        self.AvatarButton = self:Add( "DButton" )
        self.AvatarButton:Dock( LEFT )
        self.AvatarButton:SetSize( 32, 32 )
        self.AvatarButton.DoClick = function() self._player:ShowProfile() end

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

        self.Score = self:Add( "DLabel" )
        self.Score:Dock( RIGHT )
        self.Score:SetWidth( 50 )
        self.Score:SetFont( "DermaDefaultBold" )
        self.Score:SetTextColor( color_white )
        self.Score:SetContentAlignment( 5 )
        self.Score:SetExpensiveShadow( 2, Color( 0, 0, 0, 200 ) )
        self.Score:SetText("?")

        self.Status = self:Add( "DLabel" )
        self.Status:Dock( RIGHT )
        self.Status:SetWidth( 250 )
        self.Status:SetFont( "DermaDefaultBold" )
        self.Status:SetTextColor( color_white )
        self.Status:SetContentAlignment( 5 )
        self.Status:SetExpensiveShadow( 2, Color( 0, 0, 0, 200 ) )
        self.Status:SetText("?")

        self.Flag = self:Add( "DImage" )
        self.Flag:Dock(RIGHT)
        self.Flag:SetSize(32, 32)
        self.Flag:SetContentAlignment(5)
        self.Flag:Hide()

        self:Dock( TOP )
        self:DockPadding( 3, 3, 3, 3 )
        self:SetHeight( 32 + 3 * 2 )
        self:DockMargin( 1, 1, 1, 0 )

        -- those are absolutely unncessary
        self._player = nil
        self._teamID = nil
        self._nameVal = nil
        self._scoreVal = nil
        self._deathsVal = nil
        self._statusVal = nil
        self._flagIDVal = nil
    end,

    Setup = function(self, ply, teamID)
        self._player = ply
        self._teamID = teamID

        if not self._teamID then
            -- should never display score and deaths
            self.Kills:SetText("")
            self.Deaths:SetText("")
        end

        self.Avatar:SetPlayer(ply)

        self:Think(self)
    end,

    GetTeamID = function(self)
        return self._teamID
    end,

    GetStatus = function(self)
        if self._player:Team() == TEAM_CONNECTING then
            return STATUS_CONNECTING
        end

        if self._player:IsReady() then
            return STATUS_READY
        end

        -- It is perfectly possible for a player to be both ready and dead at the same time, for now, ready just takes precedence
        -- TODO: Make multiple states possible (bit masking maybe?)
        if not self._player:Alive() then
            return STATUS_DEAD
        end

        return STATUS_NONE

    end,

    Think = function(self)

        -- Self destruct if the player is no longer valid
        if not IsValid(self._player) then
            self:SetZPos(9999) -- Causes a rebuild
            self:Remove()
            return
        end

        local name = self._player:Nick()
        if self._nameVal == nil or self._nameVal ~= name then
            self.Name:SetText(name)
            self._nameVal = name
        end

        if self._teamID then -- nil on the "spectator" section

            local score = self._player:Frags()
            if self._scoreVal == nil or self._scoreVal ~= score then
                self.Score:SetText(score)
                self._scoreVal = score
            end

            local deaths = self._player:Deaths()
            if self._deathsVal == nil or self._deathsVal ~= deaths then
                self._deathsVal = deaths
                self.Deaths:SetText(deaths)
            end

            local flagID = FlagManager:GetFlagIDGrabbedByPlayer(self._player)
            if self._flagIDVal ~= flagID then
                if flagID then
                    self.Flag:SetMaterial(B2CTF_MAP.teams[flagID]._iconMat)
                    self.Flag:Show()
                else
                    self.Flag:Hide()
                end
                self._flagIDVal = flagID
            end

        end

        local ping = self._player:Ping()
        if self._pingVal == nil or self._pingVal ~= ping then
            self.Ping:SetText(ping)
            self._pingVal = ping
        end

        local status = self:GetStatus()
        if self._statusVal == nil or self._statusVal ~= status then
            self.Status:SetText(STATUS_TEXTS[status])
            self._statusVal = status
        end

        --
        -- Change the icon of the mute button based on state
        --
        if self.Muted == nil or self.Muted ~= self._player:IsMuted() then

            self.Muted = self._player:IsMuted()
            if ( self.Muted ) then
                self.Mute:SetImage( "icon32/muted.png" )
            else
                self.Mute:SetImage( "icon32/unmuted.png" )
            end

            self.Mute.DoClick = function( s ) self._player:SetMuted( not self.Muted ) end
            self.Mute.OnMouseWheeled = function( s, delta )
                self._player:SetVoiceVolumeScale( self._player:GetVoiceVolumeScale() + ( delta / 100 * 5 ) )
                s.LastTick = CurTime()
            end

            self.Mute.PaintOver = function( s, w, h )
                if not IsValid( self._player ) then return end

                local a = 255 - math.Clamp( CurTime() - ( s.LastTick or 0 ), 0, 3 ) * 255
                if ( a <= 0 ) then return end

                draw.RoundedBox(4, 0, 0, w, h, Color( 0, 0, 0, a * 0.75 ))
                draw.SimpleText(math.ceil( self._player:GetVoiceVolumeScale() * 100 ) .. "%", "DermaDefaultBold", w / 2, h / 2, Color( 255, 255, 255, a ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end

        end

        if self._teamID then
            -- order itself by score (only on valid teams)
            self:SetZPos(( self._scoreVal * -50 ) + self._deathsVal + self._player:EntIndex())
        end

    end,

    Paint = function( self, w, h )

        if not IsValid( self._player ) then
            return
        end

        draw.NoTexture()
        surface.SetDrawColor(255,255,255,2)
        surface.DrawRect( 0, 0, w, h)
    end
}

return vgui.RegisterTable( playerRowTable, "DPanel" )

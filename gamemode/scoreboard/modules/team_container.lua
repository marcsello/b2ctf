local playerRow = include("player_row.lua")

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

local teamContainerTable = {

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

            ply.ScoreBoardEntry = vgui.CreateFromTable( playerRow, ply.ScoreBoardEntry )
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

hook.Add("OnReloaded", "B2CTF_ResetScoreboardOnReload", function()
    for id, ply in ipairs(player.GetAll()) do
        if IsValid(ply.ScoreBoardEntry) then
            ply.ScoreBoardEntry:Remove()
            ply.ScoreBoardEntry = nil
        end
    end
end)

return vgui.RegisterTable( teamContainerTable, "DPanel" )

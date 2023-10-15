-- Team site related restrictions

hook.Add("B2CTF_PhaseChanged", "BringBackPlayersWhenHomeSick", function(newPhase, info, start_time, end_time)
    if info.homeSickness then
        for _, v in ipairs( player.GetAll() ) do
            if not v:AtHome() then
                v:Spawn() -- should bring them home
            end
        end
    end
end )

timer.Create("B2CTF_HomeSicknessHurts", 0.75, 0, function()
    if not Phaser:CurrentPhaseInfo().homeSickness then return end -- run only if current phase cause home-sickness

    for _, v in ipairs( player.GetAll() ) do
        if not (v and IsValid(v) and v:Alive()) then continue end
        if not v:AtHome() then
            local target = v
            local vehicle = v:GetVehicle()
            if vehicle and IsValid(vehicle) then
                target = vehicle
            end

            local d = DamageInfo()
            d:SetDamage( 15 )
            d:SetAttacker( v )
            d:SetDamageType( DMG_DISSOLVE )
            target:TakeDamageInfo( d ) -- Jajj úristen Trianon de kurvára fáj, jajj Jézusom
        end
    end
end )

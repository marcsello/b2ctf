-- Team site related restrictions

hook.Add("B2CTF_PhaseChanged", "BringBackPlayersWhenHomeSick", function(newPhase, info, start_time, end_time)
    if info.homeSickness then
        for _, v in ipairs( player.GetAll() ) do
            if not v:AtHome() then
                local vehicle = v:GetVehicle()
                if vehicle and IsValid(vehicle) then
                    v:ExitVehicle()
                end
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

local homeSickCheckEnts = nil
local homeSickCheckI = nil

local function findAllEntsPossiblyHomeSick()
    local e = ents.FindByClass("prop_*")
    e = table.Add( e, ents.FindByClass("sent_*") )
    e = table.Add( e, ents.FindByClass("wire_*") )
    e = table.Add( e, ents.FindByClass("gmod_*") )
    e = table.Add( e, ents.FindByClass("weapon_*") )
    e = table.Add( e, ents.FindByClass("item_*") )
    e = table.Add( e, ents.FindByClass("npc_*") ) -- SLAM thingies are considered NPC
    return e
end

local function homeSickProcessEnt(ent --[[=Entity ]])
    if not (ent and IsValid(ent)) then return end

    local entCreator = ent:B2CTFGetCreator()
    if (not entCreator) or (not IsValid(entCreator)) or (not entCreator:IsPlayer()) or (not entCreator:TeamValid()) then return end

    local t = B2CTF_MAP.teams[entCreator:Team()]
    if t == nil then return end

    if ent:GetPos():WithinAABox(t.boundaries[1], t.boundaries[2]) then
        -- inside base
        if ent._b2ctf_homesick_remove_at then
            ent:SetColor(ent._b2ctf_homesick_orig_color or Color(255, 255, 255))
            ent._b2ctf_homesick_remove_at = nil
            ent._b2ctf_homesick_orig_color = nil
        end
    else
        -- outside base
        if ent._b2ctf_homesick_remove_at then
            if (ent._b2ctf_homesick_remove_at < CurTime()) and (not ent._b2ctf_homesick_remove_started) then
                -- the point of no return
                ent._b2ctf_homesick_remove_started = true

                ent:SetColor(Color(0, 0, 0)) -- it's like burning, or something...

                constraint.RemoveAll( ent ) -- remove all constraints, like ropes and stuff

                -- "freeze" and "no-collide" the prop
                ent:SetNotSolid( true )
                ent:SetMoveType( MOVETYPE_NONE )

                -- show some effect
                local ed = EffectData()
                ed:SetEntity( ent )
                ed:SetOrigin(ent:GetPos())
                ed:SetScale(1.5)
                util.Effect( "entity_remove", ed, true, true )

                -- actually remove the entity later
                timer.Simple(0.3, function()
                    if IsValid(ent) then
                        ent:Remove()
                    end
                end)

            end
        else
            ent._b2ctf_homesick_remove_at = CurTime() + 3
            ent._b2ctf_homesick_orig_color = ent:GetColor()
            ent:SetColor(Color(255, 0, 0))
        end
    end
end

hook.Add( "Think", "B2CTF_EntsAreHomeSickToo", function() -- Check only one entity each tick
    if not Phaser:CurrentPhaseInfo().homeSickness then return end

    for _ = 1,5 do
        if (homeSickCheckI == nil) or (homeSickCheckEnts == nil) or (homeSickCheckI > #homeSickCheckEnts) then
            homeSickCheckEnts = findAllEntsPossiblyHomeSick()
            homeSickCheckI = 1
            return
        else
            local ent = homeSickCheckEnts[homeSickCheckI]
            homeSickProcessEnt(ent)
            homeSickCheckI = homeSickCheckI + 1
        end
    end

end )


hook.Add("B2CTF_PhaseChanged", "ResetHomeSickEntities", function(newPhase, info, start_time, end_time)
    if not info.homeSickness then
        homeSickCheckEnts = nil
        homeSickCheckI = nil
        for _, ent in ipairs(findAllEntsPossiblyHomeSick()) do
            if ent._b2ctf_homesick_remove_at then
                ent:SetColor(ent._b2ctf_homesick_orig_color or Color(255, 255, 255))
                ent._b2ctf_homesick_remove_at = nil
                ent._b2ctf_homesick_orig_color = nil
            end
        end
    end
end )

-- Team site related restrictions
local outOfBoundsWarningColor = Color(255, 0, 0)

local HOMESICK_ENTITY_REMOVE_TIMEOUT = 3 -- sec
local HOMESICK_ENTITY_INSTANT_DELETE_DISTANCE = 4000 -- sqr units, if an entity goes beyond this distance from the (base's center + base's diameter), it will be deleted immediately
local HOMESICK_ENTITY_PROCESS_BATCH_SIZE_PER_THINK = 5 -- run this many checks each think

hook.Add("B2CTF_PhaseChanged", "BringBackPlayersWhenHomeSick", function(newPhaseID, newPhaseInfo, oldPhaseID, oldPhaseInfo, startTime, endTime)
    if ((not oldPhaseID) or (not oldPhaseInfo.homeSickness)) and newPhaseInfo.homeSickness then -- Bring them home only if they were allowed to go out in the previous phase
        for _, v in ipairs( player.GetAll() ) do
            if v and IsValid(v) and v:TeamValid() and not v:AtHome() then
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
    if ent._b2ctf_homesick_remove_started then return end -- do not process if it's being removed due to homesicknss

    local entCreator = ent:B2CTFGetCreator()
    if (not entCreator) or (not IsValid(entCreator)) or (not entCreator:IsPlayer()) or (not entCreator:TeamValid()) then return end

    local t = B2CTF_MAP.teams[entCreator:Team()]
    if t == nil then return end

    local entPos = ent:GetPos()

    if entPos:WithinAABox(t.boundaries[1], t.boundaries[2]) then
        -- inside base
        if ent._b2ctf_homesick_remove_at then
            ent:SetColor(ent._b2ctf_homesick_orig_color or color_white)
            ent._b2ctf_homesick_remove_at = nil
            ent._b2ctf_homesick_orig_color = nil
        end
    else
        -- outside base
        if ent._b2ctf_homesick_remove_at then
            local entDistSqr = t.boundaries._center:DistToSqr( entPos )
            if (ent._b2ctf_homesick_remove_at < CurTime()) or (entDistSqr > (t.boundaries._sizeSqr + HOMESICK_ENTITY_INSTANT_DELETE_DISTANCE)) then
                -- the point of no return
                ent._b2ctf_homesick_remove_started = true
                ent:TheatralRemoval()
            end
        else
            -- just moved outside the base
            ent._b2ctf_homesick_remove_at = CurTime() + HOMESICK_ENTITY_REMOVE_TIMEOUT
            ent._b2ctf_homesick_orig_color = ent:GetColor()
            ent:SetColor(outOfBoundsWarningColor)
        end
    end
end

hook.Add( "Think", "B2CTF_EntsAreHomeSickToo", function() -- Check only one entity each tick
    if not Phaser:CurrentPhaseInfo().homeSickness then return end

    for _ = 1, HOMESICK_ENTITY_PROCESS_BATCH_SIZE_PER_THINK do
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


hook.Add("B2CTF_PhaseChanged", "ResetHomeSickEntities", function(newPhaseID, newPhaseInfo, oldPhaseID, oldPhaseInfo, startTime, endTime)
    if not newPhaseInfo.homeSickness then
        homeSickCheckEnts = nil
        homeSickCheckI = nil
        for _, ent in ipairs(findAllEntsPossiblyHomeSick()) do
            if ent._b2ctf_homesick_remove_at then
                ent:SetColor(ent._b2ctf_homesick_orig_color or color_white)
                ent._b2ctf_homesick_remove_at = nil
                ent._b2ctf_homesick_orig_color = nil
            end
        end
    end
end )

-- prevent spawning entities outside boundaries
local function denySpawningOutsideBoundaries(ply, ...)
    if (not IsValid(ply)) or (not ply:TeamValid()) then return end

    local teamInfo = B2CTF_MAP.teams[ply:Team()]
    assert(teamInfo, "failed to get team info") -- this must be an error

    -- This is the same code gmod uses to decide where to spawn
    -- https://github.com/Facepunch/garrysmod/blob/ae8febe129c3d417e002c0b969340e5a354e7c62/garrysmod/gamemodes/sandbox/gamemode/commands.lua#L291-L299
    local vStart = ply:GetShootPos()
    local vForward = ply:GetAimVector()

    local trace = {}
    trace.start = vStart
    trace.endpos = vStart + ( vForward * 2048 )
    trace.filter = ply

    local tr = util.TraceLine( trace )
    if not tr.HitPos:WithinAABox(teamInfo.boundaries[1], teamInfo.boundaries[2]) then
        return false
    end
end


hook.Add("PlayerSpawnEffect", "B2CTF_PreventSpawningOutOfBounds", denySpawningOutsideBoundaries)
hook.Add("PlayerSpawnNPC", "B2CTF_PreventSpawningOutOfBounds", denySpawningOutsideBoundaries)
hook.Add("PlayerSpawnObject", "B2CTF_PreventSpawningOutOfBounds", denySpawningOutsideBoundaries)
hook.Add("PlayerSpawnProp", "B2CTF_PreventSpawningOutOfBounds", denySpawningOutsideBoundaries)
hook.Add("PlayerSpawnRagdoll", "B2CTF_PreventSpawningOutOfBounds", denySpawningOutsideBoundaries)
hook.Add("PlayerSpawnSENT", "B2CTF_PreventSpawningOutOfBounds", denySpawningOutsideBoundaries)
hook.Add("PlayerSpawnSWEP", "B2CTF_PreventSpawningOutOfBounds", denySpawningOutsideBoundaries)
hook.Add("PlayerSpawnVehicle", "B2CTF_PreventSpawningOutOfBounds", denySpawningOutsideBoundaries)

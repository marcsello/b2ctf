-- Magic to push away props that get too close to the flags
if not B2CTF_MAP then return end -- kindof relies on map data

local FLAG_PROTECT_RADIUS = 350
local FLAG_PROTECT_PICKUP_AFTER_PROTECT_SEC = 0.5 -- when an object was moved too close by the physgun it is forcefully dropped, and the player must wait this many time to be able to pick it up again

local FLAG_PROTECT_REMOVE_AFTER = 7
local FLAG_PROTECT_RESET_TIMER_AFTER = 2

local protectRadiusSqr = FLAG_PROTECT_RADIUS^2

local protectPos = {} -- copy flag position for faster access
for i, v in ipairs(B2CTF_MAP.teams) do
    protectPos[i] = v.flagPos
end

function flagPushawayThink(flagID)
    local flagPos = protectPos[flagID]
    local violatingEnts = ents.FindInSphere( flagPos, FLAG_PROTECT_RADIUS ) -- fun fact: the actual radius will be little bigger than defined here
    for i, ent in ipairs(violatingEnts) do -- this is a lot of entities
        local creator = ent:B2CTFGetCreator() -- only apply on props that have a valid creator (could be a problem if players could manipulate world entities)
        if not creator then continue end
        if ent._b2ctf_flag_protect_remove_started then continue end -- don't care if it's already being removed

        if (not ent._b2ctf_last_too_close_to_a_flag) or ((CurTime() - ent._b2ctf_last_too_close_to_a_flag) > FLAG_PROTECT_RESET_TIMER_AFTER) then
            -- This is a pretty crude way to track how long an entitiy is too close to the flag
            -- This way we don't have to periodaically track and reset the timestamps
            ent._b2ctf_too_close_to_a_flag_since = CurTime()
        end

        ent._b2ctf_last_too_close_to_a_flag = CurTime()

        local shouldBeRemoved = (CurTime() - ent._b2ctf_too_close_to_a_flag_since) > FLAG_PROTECT_REMOVE_AFTER
        if shouldBeRemoved then
            ent._b2ctf_flag_protect_remove_started = true
        end

        -- On client side, we only track the times, for better physgun pickup prevention UX

        if SERVER then
            local phy = ent:GetPhysicsObject()
            -- unfreeze if frozen
            if IsValid(phy) and (not phy:IsMotionEnabled()) then
                -- I guess you can freeze non-valid phy stuff is, but whatever
                phy:EnableMotion(true)
            end

            -- drop if held by physgun
            -- otherwise the mass will be incorrect
            ent:ForcePlayerDrop()


            if shouldBeRemoved then
                -- It's annoying us for a while now... just remove it
                -- This will be called only once, because the next iteration will ignore this entity
                ent:TheatralRemoval()

            elseif IsValid(phy) then -- It's just recently got close and it's a physics object, gently push it away...

                -- Calculate stuff
                local entPos = ent:GetPos()
                local mass = phy:GetMass()
                local distMul = (protectRadiusSqr - flagPos:DistToSqr( entPos )) * 0.01
                if distMul < 100 then
                    distMul = 100
                end
                if distMul > 2000 then
                    distMul = 2000
                end
                local pushForce = (distMul * mass) + 100

                local pushDirection = (entPos - flagPos):GetNormalized()
                local pushForceVector = pushDirection * pushForce

                -- Apply force to push the entity away
                phy:ApplyForceCenter(pushForceVector)
            end
            -- TODO: do something if it wasn't a physics object?

        end

    end
end


local flagIterI = 1

hook.Add("Think", "B2CTF_FlagProtectorThink", function()
    if not FlagManager:Configured() then return end

    if team.NumPlayers(flagIterI) > 0 then -- only apply magic when the flag can be there
        flagPushawayThink(flagIterI)
    end

    flagIterI = flagIterI + 1
    if flagIterI > #protectPos then
        flagIterI = 1
    end
end )

-- shared, so that the physgun UX is better
hook.Add( "PhysgunPickup", "B2CTF_FlagProtectorDisallowPickingUpStuffTooCloseToFlag", function( ply, ent )
    if ent._b2ctf_flag_protect_remove_started then
        return false
    end
    local last_too_close = ent._b2ctf_last_too_close_to_a_flag
    if last_too_close and (CurTime() - last_too_close < FLAG_PROTECT_PICKUP_AFTER_PROTECT_SEC) then
        return false
    end
end )

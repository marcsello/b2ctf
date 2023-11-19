-- Flag rendering magic
if not B2CTF_MAP then return end -- flags rely heavily on map data. If map data is missing the game would be broken anyways

-- WARNING! This file is included IN sh_flag.lua, only the basic structure of FlagManager is present, but it is probably not filled with valid data
-- Do not do any initialization outside the hoooooks  

if not Config.UseBuiltinFlagRendering then
    print("B2CTF Builtin flag rendering is disabled")
    return
end

entsForFlag = entsForFlag or {} -- prevent losing references on reload (this is why it's global, so we won't loose reference to it)

local function initEnts(flags)
    -- Remove "old" flag entities
    for _, v in ipairs(entsForFlag) do
        if IsValid(v.baseEnt) then v.baseEnt:Remove() end
        if IsValid(v.flagEnt) then v.flagEnt:Remove() end
    end
    entsForFlag = {}

    -- Create csents
    for i, v in ipairs(flags) do
        local t = B2CTF_MAP.teams[v.belongsToTeam]
        -- Base
        local baseEnt = ClientsideModel("models/props_canal/canal_cap001.mdl", RENDERGROUP_OPAQUE)
        baseEnt:SetNoDraw(false) -- will make it render automatically, don't have to call it in a render hook (calling in render hook, makes it difficult to colorize)
        baseEnt:SetPos(v.homePos)
        baseEnt:SetAngles(Angle(270,0,0))
        baseEnt:SetColor(t.color)

        -- Flag
        local flagEnt = ClientsideModel("models/props_c17/statue_horse.mdl", RENDERGROUP_OPAQUE)
        flagEnt:SetNoDraw(false) -- will make it render automatically, don't have to call it in a render hook (calling in render hook, makes it difficult to colorize)
        -- Position will be set dynamicall by the animate hook
        flagEnt:SetColor(t.color)
        entsForFlag[i] = {
            baseEnt = baseEnt,
            flagEnt = flagEnt,
        }
    end
end

hook.Add("B2CTF_FlagManagerInitialized", "CreateFlagEntities", initEnts)

local function updateFlagEnts()
    if not (FlagManager and FlagManager:Configured()) then return end -- flag manager not yet initialized
    if not entsForFlag or #entsForFlag == 0 then return end -- ents not yet initialized

    for i, v in FlagManager:IterFlags() do

        -- If a team does not have members, then don't render their flag
        local teamHaveMembers = team.NumPlayers(i) ~= 0
        entsForFlag[i].flagEnt:SetNoDraw(not teamHaveMembers)
        if not teamHaveMembers then continue end

        -- check if grabbed, if so, then attach it to the player
        if v.grabbedBy then
            local ply = v.grabbedBy

            entsForFlag[i].flagEnt:SetPos(ply:GetPos())

            local vehicle = ply:GetVehicle()
            if vehicle and IsValid(vehicle) then
                local vehicleAngles = vehicle:GetAngles()
                vehicleAngles:RotateAroundAxis(vehicleAngles:Up(), 270) -- breaks for prisoner pod
                entsForFlag[i].flagEnt:SetAngles(vehicleAngles)
            else
                local eyes = ply:EyeAngles()
                entsForFlag[i].flagEnt:SetAngles(Angle(0, eyes.yaw + 180, 0))
            end
            continue
        end

        -- not grabbed, draw it somewhere in the world
        local pos = v.homePos
        local elevate = 30
        if v.droppedPos then
            pos = v.droppedPos
            elevate = 10
        end

        -- Spining and hovering animation is based on CurTime, so they are the same across all clients
        entsForFlag[i].flagEnt:SetAngles(Angle(0, CurTime() * 45, 0))
        entsForFlag[i].flagEnt:SetPos(Vector(pos.x, pos.y, pos.z + elevate + math.sin(CurTime()) * 10 ))
    end
end

-- Bit choppy but less resource heavy
-- timer.Create("B2CTF_FlagAnimations", .033, 0, updateFlagEnts) -- 30fps
-- smooth, but the high amount  of Vector() and Angle() operations makes it resource heavy 
hook.Add("Think", "B2CTF_FlagAnimations", updateFlagEnts)



-- Flag rendering magic
if not B2CTF_MAP then return end -- flags rely heavily on map data. If map data is missing the game would be broken anyways
entsForFlag = entsForFlag or {} -- prevent losing references on reload (this is why it's global, so we won't loose reference to it)

-- WARNING! This file is included IN sh_flag.lua, only the basic structure of FlagManager is present, but it is probably not filled with valid data
-- Do not do any initialization outside the hoooooks  

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
        flagEnt:SetPos(v.homePos + Vector(0, 0, 30))
        flagEnt:SetColor(t.color)
        entsForFlag[i] = {
            baseEnt = baseEnt,
            flagEnt = flagEnt,
        }
    end
end

hook.Add("B2CTF_FlagManagerInitialized", "CreateFlagEntities", initEnts)

local function spinFlags()
    if not (FlagManager and FlagManager.flags) then return end -- flags not yet initialized
    if not entsForFlag or #entsForFlag == 0 then return end -- ents not yet initialized

    for i, v in ipairs(FlagManager.flags) do
        if v.grabbedBy then continue end
        entsForFlag[i].flagEnt:SetAngles(Angle(0, CurTime() * 45, 0))
    end
end

-- Bit choppy but less resource heavy
timer.Create("B2CTF_FlagAnimations", .033, 0, spinFlags) -- 30fps
-- smooth, but calls Angle() way too many times 
-- hook.Add("Think", "B2CTF_FlagAnimations", function() FlagManager:_animateStep() end)



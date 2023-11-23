-- This library is created, so that convars can be referenced in only one place
-- This must be loaded super-early
local allowedTypes = {
    ["String"] = {
        typeValidator = function(val) return type(val) == "string" end,
        toString = function(val) return val end
    },
    ["Bool"] = {
        typeValidator = function(val) return type(val) == "boolean" end,
        toString = function(val) if val then return "1" else return "0" end end
    },
    ["Int"] = {
        typeValidator = function(val) return type(val) == "number" and math.floor(val) == val end, -- math.type is not a thing in glua
        toString = function(val) return tostring(val) end
    },
    ["Float"] = {
        typeValidator = function(val) return type(val) == "number" end,
        toString = function(val) return tostring(val) end
    }

}

-- This function will return closure functions to get the config options, but we'll do some metatable magic later, so they will be more like properties
local function createConvarField(typ, name, default, serverOnly, allowOnTheFly, helptext, validator)
    -- run some arg checking
    local typeConfig = allowedTypes[typ]
    assert(typeConfig, "This type is invalid")
    assert(typeConfig.typeValidator(default), "The default value have an invalid type")
    if validator then
        assert(validator(default), "The default value does not pass validation")
    end

    if CLIENT and serverOnly then return end -- don't actually create the function

    local flags = 0
    if not serverOnly then
        -- if not server only, then replicate
        flags = flags + FCVAR_REPLICATED
    end

    if not allowOnTheFly then
        -- We set it so that it can be used while we are connected. But it isn't really important as we will just freeze it's value
        flags = flags + FCVAR_NOT_CONNECTED
    end

    -- typed convars are buggy in gmod, so we don't set the type and do some woodoo
    local defaultStr = typeConfig.toString(default)
    local convar = CreateConVar(name, defaultStr, flags, helptext)

    local funcKey = "Get" .. typ -- ah yes, we do that...

    local magicGetter = function()
        local value = convar[funcKey](convar)
        -- type validator is currently only ran for the default value, because we have fancy getter functions for the others
        if validator then
            local valid = validator(value)
            if not valid then
                print("WARNING: Invalid value (" .. value .. ") for " .. name .. "! Using default!")
                return default
            end
        end
        -- should be valid
        return value
    end


    if allowOnTheFly then
        -- in case on the fly changes are allowed we put all getter logic in the closure
        return magicGetter
    else
        -- since this is not expected to change, we just "freeze" it
        local frozenVar = magicGetter()
        return function()
            return frozenVar
        end
    end

end

-- Now configure meta table, so we can access the config options as they were properties
local configMeta = {
    __index = function(table, key)
        local raws = rawget(table, "_raws")
        if not raws[key] then
            error("Accessing to undefined config option: " .. key)
        end
        return raws[key]() -- we store functions here, let's execute them, to get the value.
    end,
    __newindex = function(table, key, value)
        local raws = rawget(table, "_raws")
        if not raws[key] then
            raws[key] = value
        else
            error("This entry is already defined: " .. key)
        end
    end,
}

-- Setup global Config var to hold our config
Config = { -- we create a new one every time, because otherwise we would run into already defiend errors
    _raws = {}
}
setmetatable(Config, configMeta)


-- Define some validators, 
-- these should only validate the value not the type, types are checked automagically (or not lol)

local function validatorMinimum(min)
    return function(val)
        return val >= min
    end
end


-- and finally, define the config vars
Config.PreBuildTime =   createConvarField("Int", "b2ctf_phase_time_prebuild",   90,   false, false, "Pre-build phase time",  validatorMinimum(5))
Config.BuildTime =      createConvarField("Int", "b2ctf_phase_time_build",      3600, false, false, "Build phase time",      validatorMinimum(5))
Config.PreWarTime =     createConvarField("Int", "b2ctf_phase_time_prewar",     45,   false, false, "Pre-war phase time",    validatorMinimum(5))
Config.WarTime =        createConvarField("Int", "b2ctf_phase_time_war",        1800, false, false, "War phase time",        validatorMinimum(5))
Config.AutoReturnTime = createConvarField("Int", "b2ctf_flag_auto_return_time", 30,   false, true,  "Flag auto return time", validatorMinimum(1))

Config.UseBuiltinProtection =    createConvarField("Bool", "b2ctf_use_builtin_protection",     true, false, false, "Use builtin protection")
Config.UseBuiltinFlagRendering = createConvarField("Bool", "b2ctf_use_builtin_flag_rendering", true, false, false, "Use builtin flag rendering")
Config.UseBuiltinHUDRendering =  createConvarField("Bool", "b2ctf_use_builtin_hud_rendering",  true, false, false, "Use builtin HUD rendering")

Config.EnablePlayerReadyShort =    createConvarField("Bool", "b2ctf_enable_player_ready_short",     true,  false, false, "Allow players to skip short phases phase by stating that they are ready")
Config.EnablePlayerReadyBuild =    createConvarField("Bool", "b2ctf_enable_player_ready_build",     false, false, false, "Allow players to skip the build phase by stating that they are ready")
Config.EnablePlayerReadyBySpare2 = createConvarField("Bool", "b2ctf_enable_player_ready_by_spare2", true,  false, false, "Allow players to use Spare2 to toggle their ready state")

-- alright... I might have over-engineered this part...

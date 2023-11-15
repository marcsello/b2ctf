-- Shared stuff for sandbox restrictions. Included at the end of sandbox.lua and cl_sandbox.lua NOT shared.lua

-- Deny sandbox functions when not building
local function denyWhenNotBuilding(ply, ...)
    if (not IsValid(ply)) or (not ply:TeamValid()) then return false end
    if not ply:CurrentlyBuilding() then
        return false
    end
end

-- These three are shared because of prediction, so I've kinda duplicated the functionality from the server side script
hook.Add("PhysgunPickup", "B2CTF_PhysPickupCheck", denyWhenNotBuilding)
hook.Add("CanTool", "B2CTF_ToolCheck", denyWhenNotBuilding)

hook.Add("CanProperty", "B2CTF_PropertyCheck", function( ply, property, ent )
    if property == "drive" then return false end -- we just don't allow drive
    return denyWhenNotBuilding(ply)
end )

-- Some extra stuff

hook.Add( "CanTool", "B2CTF_DontRemoveDoors", function( ply, tr, toolname, tool, button )
    if toolname == "remover" and IsValid( tr.Entity ) and tr.Entity:GetClass() == "prop_door_rotating" then
       return false
    end
end )

hook.Add("CanDrive", "B2CTF_DriveCheck", function( ply, ent )
    -- we just don't allow drive
    return false
end )

local printDebugInfo = include("print_debug_info.lua")

function debugStatusClient(ply, cmd, args)
    if not IsValid(ply) then return end
    printDebugInfo()
end

concommand.Add("b2ctf_debug_status_cl", debugStatusClient, nil, "Get game status info", 0)

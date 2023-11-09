function GM:LimitHit( name ) -- Override message
    local translatedName = language.GetPhrase( name ) -- this is the friendly name, but it also get's translated

    local msg = "Your team has hit the " .. translatedName .. " limit!"

    -- copied from the original source
    -- https://github.com/Facepunch/garrysmod/blob/a570ab8ce8c25706617b0376aaaecf7b8f09a902/garrysmod/gamemodes/sandbox/gamemode/cl_init.lua#L32
    self:AddNotify( msg, NOTIFY_ERROR, 6 )
    surface.PlaySound( "buttons/button10.wav" )

    return false -- prevent default hook
end

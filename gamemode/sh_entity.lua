local meta = FindMetaTable("Entity")
if not meta then return end

local MAX_EDICT_BITS = 13 -- copied from gmod source

if SERVER then
    util.AddNetworkString("B2CTF_CreatorSync")
end

function meta:B2CTFSetCreator(ply --[[=Player]])
    self._b2ctf_creator = ply

    if SERVER then
        timer.Simple(0.2, function() -- when the entity is just created, it may not exist on the client side yet
            net.Start("B2CTF_CreatorSync")
                net.WriteUInt( self:EntIndex(), MAX_EDICT_BITS )
                net.WriteEntity(ply)
            net.Broadcast()
        end )
    end

end

function meta:B2CTFGetCreator()
    return self._b2ctf_creator
end

-- owerride the builtin SetCreator
local entSetCreator = meta.SetCreator
if entSetCreator then
    function meta:SetCreator(ply)
        self:B2CTFSetCreator(ply)
        entSetCreator(self, ply)
    end
end

if CLIENT then
    net.Receive( "B2CTF_CreatorSync", function( len, sender )
        if ( IsValid( sender ) and sender:IsPlayer() ) then return end -- disallow these messages from players
        local entID = net.ReadUInt( MAX_EDICT_BITS )
        local ply = net.ReadEntity()
        if entID <= 0 or (not IsValid(ply)) or (not ply:IsPlayer()) then return end

        timer.Simple(0.1, function() -- delay both client and server side, because I just have no better idea...
            local ent = Entity(entID)
            if IsValid(ent) and IsValid(ply) then
                ent:B2CTFSetCreator(ply)
            end
        end )

    end )
end

-- These are all the server-side stuff, that makes our custom creator tracking work (basically server-side of sh_entity.lua)

local function storeCreator3(ply, _, ent)
    ent:B2CTFSetCreator(ply)
end

local function storeCreator2(ply, ent)
    ent:B2CTFSetCreator(ply)
end

hook.Add( "PlayerSpawnedEffect", "B2CTF_StoreEffectCreator", storeCreator3)
hook.Add( "PlayerSpawnedNPC", "B2CTF_StoreNPCCreator", storeCreator2)
hook.Add( "PlayerSpawnedProp", "B2CTF_StorePropCreator", storeCreator3)
hook.Add( "PlayerSpawnedRagdoll", "B2CTF_StoreRagdollCreator", storeCreator3)
hook.Add( "PlayerSpawnedSWEP", "B2CTF_StoreSWEPCreator", storeCreator2)
hook.Add( "PlayerSpawnedSENT", "B2CTF_StoreSENTCreator", storeCreator2)
hook.Add( "PlayerSpawnedVehicle", "B2CTF_StoreVehicleCreator", storeCreator2)

-- Override cleanup func, to track player items
-- inspiration taken from https://github.com/FPtje/Falcos-Prop-protection/blob/master/lua/fpp/server/core.lua
if cleanup then
    local origCleanupAdd = cleanup.Add
    function cleanup.Add(ply, Type, ent)
        if not IsValid(ply) or not IsValid(ent) then return origCleanupAdd(ply, Type, ent) end
        ent:B2CTFSetCreator(ply)
        return origCleanupAdd(ply, Type, ent)
    end
end

-- Override undo func, to track player items
-- inspiration taken from https://github.com/FPtje/Falcos-Prop-protection/blob/master/lua/fpp/server/core.lua
if undo then
    local AddEntity, SetPlayer, Finish = undo.AddEntity, undo.SetPlayer, undo.Finish
    local Undo = {}
    local UndoPlayer
    function undo.AddEntity(ent, ...)
        if not isbool(ent) and IsValid(ent) then table.insert(Undo, ent) end
        AddEntity(ent, ...)
    end

    function undo.SetPlayer(ply, ...)
        UndoPlayer = ply
        SetPlayer(ply, ...)
    end

    function undo.Finish(...)
        if IsValid(UndoPlayer) then
            for _, v in pairs(Undo) do
                v:B2CTFSetCreator(UndoPlayer)
            end
        end
        Undo = {}
        UndoPlayer = nil

        Finish(...)
    end
end

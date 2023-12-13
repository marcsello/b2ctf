AddCSLuaFile() -- make this file available on client side

if CLIENT then
    SWEP.PrintName = "Battle unfreezer"
    SWEP.Slot = 0
    SWEP.SlotPos = 3
    SWEP.DrawAmmo = false
    SWEP.DrawCrosshair = true
end

if SERVER then
    util.AddNetworkString("B2CTF_SWEPBattleUnfreezer_Result")
end

SWEP.Author = "Marcsello"
SWEP.Instructions = "Left click to un-freeze"
SWEP.Contact = "marcsello@derpymail.org"
SWEP.Purpose = "Unfreeze frozen props during combat"

SWEP.ViewModelFOV = 62
SWEP.ViewModelFlip = false
SWEP.AnimPrefix = "stunstick"

SWEP.Spawnable = false
SWEP.AdminSpawnable = true

SWEP.ViewModel = Model("models/weapons/v_stunstick.mdl")
SWEP.WorldModel = Model("models/weapons/w_stunbaton.mdl")

SWEP.UnfreezeSound = Sound("npc/roller/mine/rmine_chirp_answer1.wav")
SWEP.ClickSound = Sound("buttons/lightswitch2.wav")
SWEP.CooldownSound = Sound("buttons/button2.wav")

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = 0
SWEP.Primary.Automatic = false --Automatic weapon?
SWEP.Primary.Ammo = ""

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = 0
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = ""

SWEP._cooldownEnd = 0
SWEP._nextStrike = 0

local function unfreezeResult(swepEnt, success) -- this is called both client and server side
    if success then
        swepEnt:SetWeaponHoldType("melee")
        timer.Simple(0.3, function(wep) if wep and IsValid( wep ) then wep:SetWeaponHoldType("normal") end end, swepEnt) -- something to do with quick weapon switching

        swepEnt:GetOwner():SetAnimation(PLAYER_ATTACK1)
        swepEnt:SendWeaponAnim(ACT_VM_MISSCENTER)
        swepEnt:EmitSound(swepEnt.UnfreezeSound)
        swepEnt._cooldownEnd = CurTime() + 1.75
    else
        swepEnt:EmitSound(swepEnt.ClickSound)
    end
end

local function PlayerUnfreezeObject( ply, ent, object )
    -- copied from here: https://github.com/Facepunch/garrysmod/blob/85792cf9515260b104ca0224755e2e75594936fa/garrysmod/gamemodes/base/gamemode/obj_player_extend.lua#L32C1-L51C4

    -- Not frozen!
    if ( object:IsMoveable() ) then return 0 end

    -- Unfreezable means it can't be frozen or unfrozen.
    -- This prevents the player unfreezing the gmod_anchor entity.
    if ( ent:GetUnFreezable() ) then return 0 end

    -- NOTE: IF YOU'RE MAKING SOME KIND OF PROP PROTECTOR THEN HOOK "CanPlayerUnfreeze"
    if not gamemode.Call( "CanPlayerUnfreeze", ply, ent, object ) then return 0 end

    object:EnableMotion(true)
    object:Wake()

    gamemode.Call( "PlayerUnfrozeObject", ply, ent, object )

    return 1

end


local function unfreezeEntityWithAllConstrained(ply, targetEnt)
    if not IsValid(targetEnt) then return 0 end
    -- copied from here: https://github.com/Facepunch/garrysmod/blob/85792cf9515260b104ca0224755e2e75594936fa/garrysmod/gamemodes/base/gamemode/obj_player_extend.lua#L71C3-L85C6

    local entitiesToUnfreeze = constraint.GetAllConstrainedEntities(targetEnt)
    local unfrozenObjects = 0

    for _, ent in pairs(entitiesToUnfreeze) do

        local objects = ent:GetPhysicsObjectCount()

        for i = 1, objects do

            local physobject = ent:GetPhysicsObjectNum( i - 1 )
            unfrozenObjects = unfrozenObjects + PlayerUnfreezeObject( ply, ent, physobject )

        end

    end

    return unfrozenObjects

end

function SWEP:Initialize()
    if SERVER then self:SetWeaponHoldType("normal") end
end

function SWEP:PrimaryAttack()
    if self._nextStrike > CurTime() then
        -- next strike time haven't passed yet
        return
    end
    self._nextStrike = CurTime() + 0.4


    local onCooldown = CurTime() < self._cooldownEnd
    if onCooldown then
        self:EmitSound(self.CooldownSound)
        return
    end

    local ply = self:GetOwner()

    if CLIENT then return end -- for some reason, PhysgunUnfreeze is completly broken on client side, so we do a little workaround here...
    -- we do everything server-side and report back to the client(s) later

    local tr = ply:GetEyeTrace()

    local success = false
    if tr.HitNonWorld and IsValid(tr.Entity) then
        local unfrozenObjects = unfreezeEntityWithAllConstrained(ply, tr.Entity)
        success = unfrozenObjects ~= 0
    end

    -- let clients know about this unfreeze event
    net.Start("B2CTF_SWEPBattleUnfreezer_Result")
        net.WriteEntity(self)
        net.WriteBool(success) -- indicate success
    net.Broadcast()

    unfreezeResult(self, success) -- call on server side
end

if CLIENT then
    net.Receive( "B2CTF_SWEPBattleUnfreezer_Result", function(len, ply)
        if IsValid(ply) then return end -- only accept from server
        local swepEnt = net.ReadEntity()
        local success = net.ReadBool()
        if IsValid(swepEnt) then
            unfreezeResult(swepEnt, success) -- call on client side
        end
    end )
end

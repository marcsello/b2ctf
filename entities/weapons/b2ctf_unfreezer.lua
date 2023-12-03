AddCSLuaFile() -- make this file available on client side

if CLIENT then
    SWEP.PrintName = "Battle unfreezer"
    SWEP.Slot = 0
    SWEP.SlotPos = 3
    SWEP.DrawAmmo = false
    SWEP.DrawCrosshair = true
end

if SERVER then
    util.AddNetworkString("B2CTF_SWEPBattleUnfreezer_Success")
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

SWEP.NextStrike = 0

SWEP.ViewModel = Model("models/weapons/v_stunstick.mdl")
SWEP.WorldModel = Model("models/weapons/w_stunbaton.mdl")

SWEP.Sound = Sound("npc/roller/mine/rmine_chirp_answer1.wav")

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = 0
SWEP.Primary.Automatic = false --Automatic weapon?
SWEP.Primary.Ammo = ""

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = 0
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = ""

function SWEP:Initialize()
    if SERVER then self:SetWeaponHoldType("normal") end
end

local function unfreezeSuccess(swepEnt)
    -- do stuff that must be done when anything was unfrozen
    swepEnt:SetWeaponHoldType("melee")
    timer.Simple(0.3, function(wep) if wep and IsValid( wep ) then wep:SetWeaponHoldType("normal") end end, swepEnt) -- something to do with quick weapon switching

    swepEnt:GetOwner():SetAnimation(PLAYER_ATTACK1)
    swepEnt:EmitSound(swepEnt.Sound)
    swepEnt:SendWeaponAnim(ACT_VM_MISSCENTER)
end

function SWEP:PrimaryAttack()
    if CurTime() < self.NextStrike then return end
    self.NextStrike = CurTime() + 1.5 -- this also prevents accidental unfreeze-all

    if CLIENT then return end -- for some reason, PhysgunUnfreeze is completly broken on client side, so we do a little workaround here...
    -- we do everything server-side and report back to the client(s) later

    local unfrozenObjects = self:GetOwner():PhysgunUnfreeze()
    if unfrozenObjects == 0 then return end -- nothing was unfrozen

    -- let clients know that this unfreeze was a success
    net.Start("B2CTF_SWEPBattleUnfreezer_Success")
        net.WriteEntity(self)
    net.Broadcast()

    unfreezeSuccess(self)
end

if CLIENT then
    net.Receive( "B2CTF_SWEPBattleUnfreezer_Success", function( len, ply )
        if IsValid(ply) then return end -- only accept from server
        swepEnt = net.ReadEntity()
        if IsValid(swepEnt) then unfreezeSuccess(swepEnt) end
    end )
end

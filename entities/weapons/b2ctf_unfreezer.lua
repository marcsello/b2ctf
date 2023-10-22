AddCSLuaFile() -- make this file available on client side

if CLIENT then
    SWEP.PrintName = "War unfreezer"
    SWEP.Slot = 0
    SWEP.SlotPos = 3
    SWEP.DrawAmmo = false
    SWEP.DrawCrosshair = true
end

SWEP.Author = "Marcsello"
SWEP.Instructions = "Left click to un-freeze"
SWEP.Contact = "marcsello@derpymail.org"
SWEP.Purpose = "Unfreeze frozen props during war"

SWEP.ViewModelFOV = 62
SWEP.ViewModelFlip = false
SWEP.AnimPrefix = "stunstick"

SWEP.Spawnable = false
SWEP.AdminSpawnable = true

SWEP.NextStrike = 0

SWEP.ViewModel = Model("models/weapons/v_stunstick.mdl")
SWEP.WorldModel = Model("models/weapons/w_stunbaton.mdl")

SWEP.Sound = Sound("weapons/stunstick/stunstick_swing1.wav")

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

function SWEP:PrimaryAttack()
    if CurTime() < self.NextStrike then return end
    self.NextStrike = CurTime() + 1.0 -- this also prevents accidental unfreeze-all

    local unfrozenObjects = self:GetOwner():PhysgunUnfreeze()
    if unfrozenObjects == 0 then return end

    if SERVER then
        self:SetWeaponHoldType("melee")
        timer.Simple(0.3, function(wep) if wep and IsValid( wep ) then wep:SetWeaponHoldType("normal") end end, self) -- something to do with quick weapon switching
    end
    self:GetOwner():SetAnimation(PLAYER_ATTACK1)
    self:EmitSound(self.Sound)
    self:SendWeaponAnim(ACT_VM_HITCENTER)

end
 
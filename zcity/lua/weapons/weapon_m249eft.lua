SWEP.Base = "homigrad_base"
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.PrintName = "M249 SAW 5.56x45"
SWEP.Author = "FN Herstal"
SWEP.Instructions = "Machine gun chambered in 5.56x45 mm\n\nRate of fire 775 rounds per minute"
SWEP.Category = "Weapons - Machineguns"
SWEP.Slot = 2
SWEP.SlotPos = 10
SWEP.ViewModel = ""
SWEP.WorldModel = "models/w_mach_ins2_m249.mdl"
SWEP.WorldModelFake = "models/weapons/arc9/zwei/c_m249.mdl"
SWEP.FakeAttachment = "1"
SWEP.FakeScale = 1
SWEP.FakePos = Vector(-15, 5.7, 9.45)
SWEP.FakeAng = Angle(0.19, 0.04, 0)
SWEP.AttachmentPos = Vector(-0,0.7,0.2)
SWEP.AttachmentAng = Angle(0,0,0)
SWEP.FakeBodyGroups = "112111111"
SWEP.FakeEjectBrassATT = "2"
//SWEP.MagIndex = 53
//MagazineSwap
--PrintBones(Entity(1):GetActiveWeapon():GetWM())
--PrintTable(Entity(1):GetActiveWeapon():GetWM():GetBodyGroups())
SWEP.FakeVPShouldUseHand = true
SWEP.AnimList = {
        ["primary_attack"] = "fire",
	["idle"] = "idle",
	["reload"] = "reload",
	["reload_empty"] = "reload_tactical",
}

SWEP.FakeViewBobBone = "ValveBiped.Bip01_R_Hand"
SWEP.FakeViewBobBaseBone = "ValveBiped.Bip01_R_UpperArm"
SWEP.ViewPunchDiv = 35

SWEP.FakeReloadSounds = {
	--[0.37] = "weapons/m4a1/m4a1_magrelease.wav",
	[0.25] = "weapons/m249/m249_coveropen.wav",
	[0.4] = "weapons/m249/m249_magout_full.wav",
	[0.63] = "weapons/m249/m249_shoulder.wav",
	[0.7] = "weapons/m249/m249_magin.wav",
	[0.75] = "weapons/m249/m249_beltpullout.wav",
	[0.77] = "weapons/m249/m249_fetchmag.wav",
	[0.94] = "weapons/m249/m249_coverclose.wav",
	[1.04] = "weapons/m249/m249_shoulder.wav"
}

SWEP.FakeEmptyReloadSounds = {
	[0.16] = "weapons/m249/m249_shoulder.wav",
	[0.25] = "weapons/m249/m249_boltback.wav",
	[0.28] = "weapons/m249/m249_boltrelease.wav",
	--[0.37] = "weapons/m4a1/m4a1_magrelease.wav",
	[0.45] = "weapons/m249/m249_coveropen.wav",
	[0.54] = "weapons/m249/m249_magout.wav",
	[0.73] = "weapons/m249/m249_shoulder.wav",
	[0.8] = "weapons/m249/m249_magin.wav",
	[0.83] = "weapons/m249/m249_beltpullout.wav",
	[0.85] = "weapons/m249/m249_fetchmag.wav",
	[1] = "weapons/m249/m249_coverclose.wav",
	[1.04] = "weapons/m249/m249_shoulder.wav"
}
SWEP.MagModel = "models/weapons/zcity/w_glockmag.mdl"
SWEP.FakeReloadEvents = {
	[0.73] = function( self ) 
		if CLIENT then
			--hg.CreateMag( self )
			--self:GetWM():SetBodygroup(1,16)
		end 
	end,
}

function SWEP:PostFireBullet(bullet)
	if CLIENT then
	--self:PlayAnim("base_fire_1",2,nil,false)
	end
	local owner = self:GetOwner()
	if ( SERVER or self:IsLocal2() ) and owner:OnGround() then
		if IsValid(owner) and owner:IsPlayer() then
			owner:SetVelocity(owner:GetVelocity() - owner:GetVelocity()/0.45)
		end
	end
	SlipWeapon(self, bullet)
end

SWEP.FakeMagDropBone = "magazine"

SWEP.WepSelectIcon2 = Material("entities/arc9_eft_m249.png")
SWEP.IconOverride = "entities/arc9_eft_m249.png"

--"models/weapons/v_m249.mdl"
SWEP.CustomShell = "556x45"
SWEP.CustomSecShell = "m249len"
--SWEP.EjectPos = Vector(0,-20,5)
--SWEP.EjectAng = Angle(0,90,0)

SWEP.CanSuicide = false

SWEP.ScrappersSlot = "Primary"

SWEP.weight = 5

SWEP.LocalMuzzlePos = Vector(23.632,0.400,5.860)
SWEP.LocalMuzzleAng = Angle(0.3,0.02,0)
SWEP.WeaponEyeAngles = Angle(0,0,0)

SWEP.ShockMultiplier = 3

SWEP.weaponInvCategory = 1
SWEP.Primary.ClipSize = 150
SWEP.Primary.DefaultClip = 150
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "5.56x45 mm"
SWEP.Primary.Cone = 0
SWEP.Primary.Damage = 49
SWEP.Primary.Spread = 0
SWEP.Primary.Force = 44
SWEP.Primary.Sound = {"weapons/zwei/m249/fire/m249_outdoor_close3.wav", 75, 90, 100}
SWEP.Primary.SoundEmpty = {"zcitysnd/sound/weapons/fnfal/handling/fnfal_empty.wav", 75, 100, 105, CHAN_WEAPON, 2}
SWEP.Primary.Wait = 0.08
SWEP.ReloadTime = 12.5
SWEP.ReloadSoundes = {
	"none",
	"none",
	"pwb/weapons/m249/coverup.wav",
	"none",
	"none",
	"pwb/weapons/m249/boxout.wav",
	"none",
	"pwb/weapons/m249/boxin.wav",
	"none",
	"none",
	"none",
	"none",
	"none",
	"none",
	"none"
}

SWEP.PPSMuzzleEffect = "muzzleflash_m14" -- shared in sh_effects.lua

SWEP.DeploySnd = {"homigrad/weapons/draw_hmg.mp3", 55, 100, 110}
SWEP.HolsterSnd = {"homigrad/weapons/hmg_holster.mp3", 55, 100, 110}
SWEP.HoldType = "rpg"
SWEP.ZoomPos = Vector(-9, 0.2, 7.35)
SWEP.RHandPos = Vector(-5, -2, 0)
SWEP.LHandPos = Vector(7, -2, -2)
--local to head
SWEP.RHPos = Vector(7,-7,5)
SWEP.RHAng = Angle(0,0,90)
--local to rh
SWEP.LHPos = Vector(8.5,-2,-6)
SWEP.LHAng = Angle(-20,0,-90)
SWEP.Spray = {}
for i = 1, 150 do
	SWEP.Spray[i] = Angle(-0.03 - math.cos(i) * 0.02, math.cos(i * i) * 0.04, 0) * 2
end

SWEP.Ergonomics = 0.75
SWEP.OpenBolt = true
SWEP.Penetration = 15
SWEP.WorldPos = Vector(4, -0.5, 0)
SWEP.WorldAng = Angle(0, 0, 0)
SWEP.UseCustomWorldModel = true
SWEP.attPos = Vector(0, -1, 0)
SWEP.attAng = Angle(0, -0.2, 0)
SWEP.AimHands = Vector(0, 1.65, -3.65)
SWEP.lengthSub = 15
SWEP.DistSound = "weapons/zwei/m249/fire/m249_indoor_close_tail.wav"
local vector_one = Vector(1,1,1)
local vector_zero = Vector(0,0,0)

function SWEP:DrawPost()
	local wep = self:GetWeaponEntity()
	self.vec = self.vec or Vector(0,0,0)
	local vec = self.vec
	if CLIENT and IsValid(wep) then
		self.shooanim = Lerp(FrameTime()*15,self.shooanim or 0,self.ReloadSlideOffset)
		vec[1] = 0*self.shooanim
		vec[2] = 1.5*self.shooanim
		vec[3] = 0*self.shooanim
		wep:ManipulateBonePosition(143,vec,false)
	end
end

SWEP.punchmul = 15
SWEP.punchspeed = 0.11
SWEP.podkid = 0.05

SWEP.RecoilMul = 0.1

SWEP.bipodAvailable = true
SWEP.bipodsub = 15

-- RELOAD ANIM AKM
SWEP.ReloadAnimLH = {
	Vector(0,0,0),
	Vector(-4,-6,1),
	Vector(0,-7,-5),
	Vector(0,-9,1),
	Vector(-4,-6,1),
	Vector(-4,2,2),
	Vector(-4,4,2),
	Vector(-4,15,-15),
	Vector(-4,4,2),
	Vector(-4,4,2),
	Vector(-4,2,2),
	Vector(0,-9,1),
	Vector(0,-7,-5),
	Vector(-4,-6,1),
	Vector(-2,-3,1),
	"reloadend",
	Vector(0,0,0),
}

SWEP.ReloadAnimRH = {
	Vector(0,0,0),
	Vector(0,0,0),
}

SWEP.ReloadAnimLHAng = {
	Angle(0,0,0),
	Angle(0,0,190),
	Angle(0,0,190),
	Angle(0,0,190),
	Angle(0,0,120),
	Angle(0,0,190),
	Angle(0,0,190),
	Angle(0,0,190),
	Angle(0,0,0),
}

SWEP.ReloadAnimRHAng = {
	Angle(0,0,0),
}

SWEP.ReloadAnimWepAng = {
	Angle(0,0,0),
	Angle(10,0,0),
	Angle(10,0,0),
	Angle(0,15,0),
	Angle(5,15,0),
	Angle(-15,15,0),
	Angle(-15,15,0),
	Angle(0,0,0),
}

-- Inspect Assault

SWEP.InspectAnimLH = {
	Vector(0,0,0)
}
SWEP.InspectAnimLHAng = {
	Angle(0,0,0)
}
SWEP.InspectAnimRH = {
	Vector(0,0,0)
}
SWEP.InspectAnimRHAng = {
	Angle(0,0,0)
}
SWEP.InspectAnimWepAng = {
	Angle(0,0,0),
	Angle(15,15,15),
	Angle(15,15,24),
	Angle(15,15,24),
	Angle(15,15,24),
	Angle(15,7,24),
	Angle(10,3,-5),
	Angle(2,3,-15),
	Angle(0,4,-22),
	Angle(0,3,-45),
	Angle(0,3,-45),
	Angle(0,-2,-2),
	Angle(0,0,0)
}
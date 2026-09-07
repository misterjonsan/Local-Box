do return end
SWEP.Base = "homigrad_base"
SWEP.Spawnable = false
SWEP.AdminOnly = false
SWEP.PrintName = "Steyr Aug"
SWEP.Author = "Steyr-Daimler-Puch"
SWEP.Instructions = "Steyr AUG (Armee Universal Gewehr — Army Universal Rifle) is a small arms system produced in 1977 by the Austrian company Steyr-Daimler-Puch (now Steyr Arms GmbH). In Australia, the rifle is produced under license as the F88. It features interchangeable barrels of different lengths, including a main barrel of 508 mm, as well as shorter barrels of 350 mm and 407 mm, and a heavy barrel of 621 mm. This weapon is chambered in 5.56x45 mm."
SWEP.Category = "Weapons - Assault Rifles"
SWEP.Slot = 2
SWEP.SlotPos = 10
SWEP.ViewModel = ""
SWEP.WorldModel = "models/weapons/zcity/w_asval.mdl"
SWEP.WorldModelFake = "models/weapons/arccw/fesiugmw2/c_steyr.mdl" -- Контент инсурги https://steamcommunity.com/sharedfiles/filedetails/?id=3437590840 
--uncomment for funny
--а еще надо настраивать заново zoompos
SWEP.FakePos = Vector(-10.5, 2.8, 8)
SWEP.FakeAng = Angle(0, 0, 0)
SWEP.AttachmentPos = Vector(-6,0,0)
SWEP.AttachmentAng = Angle(0,0,90)
//SWEP.MagIndex = 53
//MagazineSwap
SWEP.FakeAttachment = 1
--Entity(1):GetActiveWeapon():GetWM():SetSubMaterial(0,"NULL")
--PrintAnims(Entity(1):GetActiveWeapon():GetWM())
SWEP.FakeEjectBrassATT = "2"
SWEP.FakeReloadSounds = {
	[0.45] = "weapons/fesiugmw2/foley/wpfoly_styaug_reload_clipout_v1.wav",
	[0.8] = "weapons/fesiugmw2/foley/wpfoly_styaug_reload_clipin_v1.wav",
}
SWEP.DOZVUK = true

SWEP.FakeEmptyReloadSounds = {
	[0.42] = "weapons/fesiugmw2/foley/wpfoly_styaug_reload_clipout_v1.wav",
	[0.72] = "weapons/fesiugmw2/foley/wpfoly_styaug_reload_clipin_v1.wav",
	[0.92] = "weapons/ak47/ak47_boltback.wav",
	[0.97] = "weapons/ak47/ak47_boltrelease.wav"
}
SWEP.MagModel = "models/weapons/upgrades/w_magazine_galil_35.mdl"
local vector_full = Vector(1,1,1)
local vecPochtiZero = Vector(0.01,0.01,0.01)
if CLIENT then
	SWEP.FakeReloadEvents = {
		[0.15] = function( self, timeMul )
			self:GetWM():ManipulateBoneScale(48, vector_full)
			self:GetWM():ManipulateBoneScale(49, vector_full)
		end,
		[0.52] = function( self, timeMul )
			hg.CreateMag( self, Vector(0,0,-50) )
			self:GetWM():ManipulateBoneScale(48, vecPochtiZero)
			self:GetWM():ManipulateBoneScale(49, vecPochtiZero)
		end
	}
end

SWEP.GetDebug = false

SWEP.lmagpos = Vector(0,0,0)
SWEP.lmagang = Angle(0,0,0)
SWEP.lmagpos2 = Vector(0,2,-6)
SWEP.lmagang2 = Angle(0,0,-90)
SWEP.FakeBodyGroups = "101"
SWEP.FakeViewBobBone = "ValveBiped.Bip01_R_Hand"
SWEP.FakeViewBobBaseBone = "ValveBiped.Bip01_L_UpperArm"
SWEP.ViewPunchDiv = 70
SWEP.FakeMagDropBone = 48

SWEP.AnimList = {
	["idle"] = "idle",
	["reload"] = "reload",
	["reload_empty"] = "reload_empty_fgrip",
}


function SWEP:ModelCreated(model)
	self:GetWM():ManipulateBoneScale(48, vecPochtiZero)
	self:GetWM():ManipulateBoneScale(49, vecPochtiZero)
end

SWEP.WepSelectIcon2 = Material("entities/arc9_eft_aug.png")
SWEP.IconOverride = "entities/arc9_eft_aug.png"
SWEP.ScrappersSlot = "Primary"
SWEP.weaponInvCategory = 1
SWEP.dwr_customIsSuppressed = true
SWEP.Primary.ClipSize = 35
SWEP.Primary.DefaultClip = 35
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "5.56x45 mm"
SWEP.Primary.Cone = 0
SWEP.Primary.Damage = 41
SWEP.Primary.Spread = 0
SWEP.Primary.Force = 42
SWEP.Primary.Sound = {"weapons/fesiugmw2/fire/aug.wav", 65, 90, 100}
SWEP.SupressedSound = {"weapons/fesiugmw2/fire/acr_sil.wav", 65, 90, 100}
SWEP.Primary.Wait = 0.07
SWEP.ReloadTime = 5.5
SWEP.ReloadSoundes = {
	"none",
	"none",
	"none",
	"none",
	"weapons/tfa_ins2/ak103/ak103_magout.wav",
	"none",
	"none",
	"none",
	"weapons/tfa_ins2/akm_bw/magin.wav",
	"none",
	"weapons/tfa_inss/asval/slideback.wav",
	"weapons/tfa_inss/asval/slideforward.wav",
	"none",
	"none",
	"none",
	"none"
}

SWEP.LocalMuzzlePos = Vector(18,0,5)
SWEP.LocalMuzzleAng = Angle(0,0,0)
SWEP.WeaponEyeAngles = Angle(0,0,0)
SWEP.StartAtt = {"grip2"}
SWEP.PPSMuzzleEffectSuppress = "muzzleflash_suppressed"

SWEP.HoldType = "rpg"
SWEP.ZoomPos = Vector(0, -0.25, 7)
SWEP.RHandPos = Vector(-5, -1, 1)
SWEP.LHandPos = Vector(7, -2, -2)
SWEP.ShockMultiplier = 3
SWEP.CustomShell = "762x39"
--SWEP.EjectPos = Vector(-4,0,4)
--SWEP.EjectAng = Angle(0,0,-65)

SWEP.weight = 4

SWEP.Spray = {}
for i = 1, 20 do
	SWEP.Spray[i] = Angle(-0.01 - math.cos(i) * 0.01, math.cos(i * i) * 0.02, 0) * 1
end

SWEP.addSprayMul = 0.5

SWEP.Ergonomics = 0.9
SWEP.Penetration = 15
SWEP.WorldPos = Vector(3, -1, 1)
SWEP.WorldAng = Angle(0, 0, 0)
SWEP.UseCustomWorldModel = true
SWEP.attPos = Vector(0, 0, -0.5)
SWEP.attAng = Angle(-0, 0.05, 0)
SWEP.lengthSub = 15
SWEP.handsAng = Angle(0, 0, 0)
SWEP.Supressor = true
SWEP.SetSupressor = false
SWEP.availableAttachments = {
	sight = {
		["mountType"] = {"picatinny","ironsight"},
		["mount"] = {picatinny = Vector(-15.5, 2.3, 0), ironsight = Vector(-22, 2.3, 0),},
	},
barrel = {
		[1] = {"supressor2", Vector(-4.6,1,0.21),},
	},
	grip = {
		["mount"] = Vector(5.8, 1, 0),
		["mountType"] = "picatinny"
	},
}

--local to head
SWEP.RHPos = Vector(4,-5.5,3.5)
SWEP.RHAng = Angle(0,-15,90)
--local to rh
SWEP.LHPos = Vector(12,0.2,-3.5)
SWEP.LHAng = Angle(-110,-180,5)

SWEP.ShootAnimMul = 4

local lfang2 = Angle(0, -35, -15)
local lfang21 = Angle(0, 35, 25)
local lfang1 = Angle(-5, -5, -5)
local lfang0 = Angle(-15, -22, 15)
local vec_zero = Vector(0,0,0)
local ang_zero = Angle(0,0,0)
function SWEP:AnimHoldPost()

end

function SWEP:DrawPost()
	local wep = self:GetWeaponEntity()
	self.vec = self.vec or Vector(0,0,0)
	local vec = self.vec
	if CLIENT and IsValid(wep) then
		self.shooanim = LerpFT(0.4,self.shooanim or 0,self.ReloadSlideOffset)
		vec[1] = 0
		vec[2] = 1.2*self.shooanim
		vec[3] = 0*self.shooanim
		wep:ManipulateBonePosition(4,vec,false)
	end
end

-- RELOAD ANIM AKM
SWEP.ReloadAnimLH = {
	Vector(0,0,0),
	Vector(-0.5,1.5,-5),
	Vector(-0.5,1.5,-5),
	Vector(-0.5,1.5,-5),
	Vector(-6,7,-9),
	Vector(-15,7,-15),
	Vector(-15,6,-15),
	Vector(-13,5,-5),
	Vector(-0.5,1.5,-5),
	Vector(-0.5,1.5,-5),
	Vector(-0.5,1.5,-5),
	"fastreload",
	Vector(0,0,0),
	Vector(0,0,0),
	Vector(0,0,0),
	Vector(0,0,0),
}

SWEP.ReloadAnimRH = {
	Vector(0,0,0),
	Vector(0,0,0),
	Vector(0,0,0),
	Vector(0,0,0),
	Vector(0,0,0),
	Vector(0,0,0),
	Vector(0,0,0),
	Vector(0,0,0),
	Vector(0,0,0),
	Vector(0,0,0),
	Vector(0,0,0),
	Vector(0,0,0),
	Vector(0,0,0),
	Vector(0,0,0),
	Vector(0,0,0),
	Vector(0,0,0),
	Vector(0,0,0),
	Vector(0,0,0),
	Vector(0,0,0),
	Vector(0,0,0),
	Vector(0,0,0),
	Vector(0,0,0),
	Vector(0,0,0),
	Vector(0,0,0),
	Vector(0,0,0),
	Vector(0,0,0),
	Vector(0,0,0),
	Vector(0,0,1),
	Vector(8,1,2),
	Vector(6,4.5,-4),
	Vector(6,4.5,-4),
	Vector(6,4.5,-4),
	Vector(1,4.5,-3),
	Vector(1,4.5,-2),
	Vector(0,4,-2),
	Vector(0,5,0),
	"reloadend",
	Vector(-2,2,1),
	Vector(0,0,0),
}

SWEP.ReloadAnimLHAng = {
	Angle(0,0,0),
	Angle(-90,0,110),
	Angle(-90,0,110),
	Angle(-90,0,110),
	Angle(-70,0,110),
	Angle(-50,0,110),
	Angle(-90,0,110),
	Angle(-90,0,110),
	Angle(-90,0,110),
	Angle(-90,0,110),
	Angle(-90,0,110),
	Angle(-60,0,95),
	Angle(0,0,60),
	Angle(0,0,30),
	Angle(0,0,2),
	Angle(0,0,0),
}

SWEP.ReloadAnimRHAng = {
	Angle(0,0,0),
	Angle(0,0,0),
	Angle(0,0,0),
	Angle(0,0,0),
	Angle(0,0,0),
	Angle(0,0,0),
	Angle(0,0,0),
	Angle(0,0,0),
	Angle(0,0,0),
	Angle(20,0,-60),
	Angle(20,0,-60),
	Angle(20,0,-60),
	Angle(0,0,0),
}

SWEP.ReloadAnimWepAng = {
	Angle(0,0,0),
	Angle(-15,15,-17),
	Angle(-14,14,-22),
	Angle(-10,15,-24),
	Angle(12,14,-23),
	Angle(11,15,-20),
	Angle(12,14,-19),
	Angle(11,14,-20),
	Angle(7,17,-22),
	Angle(0,14,-21),
	Angle(0,15,-22),
	Angle(0,24,-23),
	Angle(0,25,-22),
	Angle(-15,24,-25),
	Angle(-15,25,-23),
	Angle(5,0,2),
	Angle(0,0,0),
}


SWEP.ReloadSlideAnim = {
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	4,
	4,
	0,
	0,
	0,
	0
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
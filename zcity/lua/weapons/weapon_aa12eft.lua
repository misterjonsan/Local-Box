SWEP.Base = "homigrad_base"
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.PrintName = "MPS Auto Assault-12 Gen 2"
SWEP.Author = "Izhevsk Machine-Building Plant"
SWEP.Instructions = "Semi-automatic shotgun chambered in 12/70"
SWEP.Category = "Weapons - Shotguns"
SWEP.Slot = 2
SWEP.SlotPos = 10
SWEP.ViewModel = ""
SWEP.WorldModel = "models/pwb/weapons/w_saiga_12.mdl"
--models/weapons/zcity/v_saiga_12k.mdl
SWEP.WorldModelFake = "models/weapons/arc9/darsu_eft/w_aa12.mdl" -- иба чотка ыыыыыы скырлы скырлы
--PrintAnims(Entity(1):GetActiveWeapon():GetWM())
--uncomment for funny
SWEP.FakePos = Vector(-22, 3.5, 10.6)
SWEP.FakeAng = Angle(0, 0.1, 0)
SWEP.FakeBodyGroups = "11102101"
SWEP.MagIndex = 41
SWEP.AttachmentPos = Vector(26,-2.5,2)
SWEP.AttachmentAng = Angle(0,0,0)
SWEP.FakeAttachment = "1"

SWEP.ZoomPos = Vector(-111, -15.2, 10)
//SWEP.MagIndex = 6
//MagazineSwap
--Entity(1):GetActiveWeapon():GetWM():AddLayeredSequence(Entity(1):GetActiveWeapon():GetWM():LookupSequence("delta_foregrip"),1)
SWEP.FakeViewBobBone = "CAM_Homefield"
SWEP.FakeReloadSounds = {
	[0.37] = "weapons/darsu_eft/aa12/aa12_mag_out_0.ogg",
	[0.87] = "weapons/darsu_eft/aa12/aa12_mag_in_0.ogg",
	[0.95] = "weapons/universal/uni_crawl_l_05.wav",
	--[0.95] = "weapons/ak74/ak74_boltback.wav"
}

SWEP.FakeEmptyReloadSounds = {
	--[0.22] = "weapons/ak74/ak74_magrelease.wav",
	[0.25] = "weapons/darsu_eft/aa12/aa12_mag_rail_down.ogg",
	[0.30] = "weapons/darsu_eft/aa12/aa12_mag_rail_up.ogg",
	[0.46] = "weapons/darsu_eft/aa12/aa12_mag_out_0.ogg",
	[0.75] = "weapons/universal/uni_crawl_l_05.wav",
	--[0.95] = "weapons/ak74/ak74_boltback.wav",
	[0.83] = "weapons/darsu_eft/aa12/aa12_mag_in_0.ogg",
	[1.] = "weapons/darsu_eft/ak/ak74_slider_down.ogg",
}
SWEP.MagModel = "models/weapons/arc9/darsu_eft/mods/mag_saiga12_drum.mdl"
SWEP.FakeReloadEvents = {
}

SWEP.FakeViewBobBone = "ValveBiped.Bip01_R_Hand"
SWEP.FakeViewBobBaseBone = "ValveBiped.Bip01_R_UpperArm"
SWEP.ViewPunchDiv = 40

SWEP.AnimList = {
	["idle"] = "idle",
	["reload"] = "reload0",
	["reload_empty"] = "reload_empty0_1",
}
--SWEP.ReloadHold = nil
SWEP.FakeVPShouldUseHand = false

SWEP.WepSelectIcon2 = Material("entities/arc9_eft_aa12.png")
SWEP.IconOverride = "entities/arc9_eft_aa12.png"

SWEP.addSprayMul = 1
SWEP.ScrappersSlot = "Primary"
SWEP.CustomShell = "12x70"
SWEP.weight = 4
SWEP.weaponInvCategory = 1
SWEP.Primary.ClipSize = 9
SWEP.Primary.DefaultClip = 9
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "12/70 gauge"
SWEP.Primary.Cone = 0
SWEP.Primary.Damage = 23
SWEP.Primary.Spread = Vector(0.01, 0.01, 0.01)
SWEP.Primary.Force = 24

SWEP.Primary.Sound = {"weapons/darsu_eft/aa12/aa12_indoor_close_loop1.wav", 85, 90, 100}
SWEP.Primary.SoundFP = {"weapons/darsu_eft/ak/fire_new/saiga12fa_outdoor_close_loop2.wav", 85, 90, 100}

SWEP.SupressedSound = {"arccw_uc/common/12ga/fire-sup-01.ogg", 65, 90, 100}
SWEP.SupressedSoundFP = {"arccw_uc/common/12ga/fire-sup-01.ogg", 65, 90, 100}

SWEP.Primary.Wait = 0.2
SWEP.NumBullet = 8
SWEP.AnimShootMul = 3
SWEP.AnimShootHandMul = 10
SWEP.ReloadTime = 6
SWEP.ReloadSoundes = {
	"none",
	"none",
	"weapons/tfa_ins2/ak103/ak103_magout.wav",
	"weapons/tfa_ins2/ak103/ak103_magoutrattle.wav",
	"weapons/tfa_ins2/ak103/ak103_magin.wav",
	"weapons/tfa_ins2/ak103/ak103_boltback.wav",
	"weapons/tfa_ins2/ak103/ak103_boltrelease.wav",
	"none",
	"none"
}

SWEP.PPSMuzzleEffect = "muzzleflash_M3" -- shared in sh_effects.lua

SWEP.DeploySnd = {"homigrad/weapons/draw_hmg.mp3", 55, 100, 110}
SWEP.HolsterSnd = {"homigrad/weapons/hmg_holster.mp3", 55, 100, 110}
SWEP.HoldType = "rpg"
SWEP.ZoomPos = Vector(-3, -0.77, 9.6)
SWEP.RHandPos = Vector(-15, -2, 4)
SWEP.LHandPos = Vector(7, -2, -2)
SWEP.ShellEject = "ShotgunShellEject"
SWEP.EjectPos = Vector(5,15,-2.5)
SWEP.EjectAng = Angle(0,-90,0)
SWEP.SprayRand = {Angle(-0.2, -0.4, 0), Angle(-0.4, 0.4, 0)}
SWEP.Ergonomics = 0.75
SWEP.Penetration = 7
SWEP.WorldPos = Vector(13, -1, 4)
SWEP.WorldAng = Angle(0, 0, 0)
SWEP.UseCustomWorldModel = true
SWEP.attPos = Vector(-30, -1.5, 0)
SWEP.attAng = Angle(0.05, -0.6, 0)
SWEP.lengthSub = 20
SWEP.DistSound = "weapons/darsu_eft/aa12/aa12_indoor_distant_loop1.wav"
SWEP.StartAtt = {"holo15"}

SWEP.holsteredBone = "ValveBiped.Bip01_Spine2"
SWEP.holsteredPos = Vector(3, 8, -12)
SWEP.holsteredAng = Angle(210, 0, 180)

SWEP.LocalMuzzlePos = Vector(17.928,0.001,6.743)
SWEP.LocalMuzzleAng = Angle(1,0.031,0)
SWEP.WeaponEyeAngles = Angle(-0.147,-0.055,-0.187)

SWEP.punchmul = 4
SWEP.punchspeed = 0.5

SWEP.availableAttachments = {
	sight = {
		["mountType"] = {"picatinny"},
		["mount"] = {["picatinny"] = Vector(-19.5, 5.7, -2)},
		["mountAngle"] = Angle(0,0,1),
	},
	barrel = {
		[1] = {"supressor5", Vector(0,0,0), {}},
		["mount"] = Vector(3,2.6,-2),
		["mountAngle"] = Angle(0,0,0)
	},
	grip = {
		[1] = {"grip5", Vector(0,0,0), {}},
		["mount"] = { ["picatinny"] = Vector(-01,5.3,-2.5) },
		["mountType"] = {"picatinny"}
	},
	underbarrel = {
		["mount"] = {["picatinny_small"] = Vector(7, 3, -1.7),["picatinny"] = Vector(11,3.2,-0.1)},
		["mountAngle"] = {["picatinny_small"] = Angle(0, 0, 40),["picatinny"] = Angle(0, 0, 90)},
		["mountType"] = {"picatinny_small","picatinny"},
		["removehuy"] = {
			["picatinny"] = {
			},
			["picatinny_small"] = {
			}
		}
	},
}

--local to head
SWEP.RHPos = Vector(3,-5.5,3.5)
SWEP.RHAng = Angle(0,-10,90)
--local to rh
SWEP.LHPos = Vector(16,-1,-3.5)
SWEP.LHAng = Angle(-110,-90,-90)
function SWEP:AnimationPost()
	self:BoneSet("l_finger0", Vector(0, 0, 0), Angle(10, -12, -25))
end
function SWEP:DrawPost()
	local wep = self:GetWeaponEntity()
	self.vec = self.vec or Vector(0,0,0)
	local vec = self.vec
	if CLIENT and IsValid(wep) then
		self.shooanim = Lerp(FrameTime()*15,self.shooanim or 0,self.ReloadSlideOffset)
		vec[1] = 0*self.shooanim
		vec[2] = 5*self.shooanim
		vec[3] = 0*self.shooanim
		wep:ManipulateBonePosition(120,vec,false)
	end
end

-- RELOAD ANIM AKM
SWEP.ReloadAnimLH = {
	Vector(0,0,0),
	Vector(0,2,-5),
	Vector(0,2,-6),
	Vector(0,8,-5),
	Vector(-6,7,-6),
	Vector(-15,7,-15),
	Vector(-15,6,-15),
	Vector(-13,5,-5),
	Vector(-2,3,-5),
	Vector(0,3,-5),
	Vector(0,3,-5),
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
	"fastreload",
	Vector(0,0,1),
	Vector(8,1,2),
	Vector(9,2,-1),
	Vector(9,2,-2),
	Vector(8,2,-2),
	Vector(-1,3,1),
	Vector(-2,3,1),
	Vector(-5,3,1),
	"reloadend",
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
	Angle(0,0,10),
	Angle(0,0,0),
}

SWEP.ReloadAnimRHAng = {
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
	Angle(7,17,-9),
	Angle(0,24,-21),
	Angle(0,25,-22),
	Angle(0,24,-23),
	Angle(0,25,-22),
	Angle(-15,24,-25),
	Angle(-15,25,-23),
	Angle(5,0,2),
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
	Angle(-15,15,5),
	Angle(-15,15,14),
	Angle(-15,14,16),
	Angle(-16,16,15),
	Angle(-15,14,16),
	Angle(-10,25,-15),
	Angle(-2,22,-15),
	Angle(0,25,-22),
	Angle(0,24,-45),
	Angle(0,22,-45),
	Angle(0,20,-35),
	Angle(0,0,0)
}
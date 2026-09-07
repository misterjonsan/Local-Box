SWEP.Base = "homigrad_base"
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.PrintName = "Desert Eagle L6 .50 AE"
SWEP.Author = "Magnum Research"
SWEP.Instructions = [[Desert Eagle (L6) - модификация спортивно-охотничьего пистолета калибра .50 Action Express. Этот пистолет очень большой, тяжелый и не самый удобный в эксплуатации, но в то же время абсолютно уникальный и ни на что не похожий образец короткоствольного оружия, который несомненно стал частым гостем в видеоиграх за свой брутальный внешний вид и внушительные размеры. Desert Eagle не снискал одобрения на военном поприще, но зато заслуженно стал одним из самых известных пистолетов мира. Производство Magnum Research.]]
SWEP.Category = "Weapons - Pistols"
SWEP.Slot = 2
SWEP.SlotPos = 10
SWEP.ViewModel = ""
SWEP.WorldModel = "models/weapons/zcity/w_pist_px4.mdl"
SWEP.WorldModelFake = "models/weapons/arc9/darsu_eft/c_deagle.mdl" --https://steamcommunity.com/sharedfiles/filedetails/?id=3544105055
//PrintBones(Entity(1):GetActiveWeapon():GetWM())
--uncomment for funny
SWEP.FakePos = Vector(-15, 4, 6.6)
SWEP.FakeAng = Angle(0, 0, 0)
SWEP.AttachmentPos = Vector(0,-1,0.03)
SWEP.AttachmentAng = Angle(0,0,0)
SWEP.FakeAttachment = "1"
SWEP.FakeEjectBrassATT = "2"
//SWEP.MagIndex = 6
//MagazineSwap
--Entity(1):GetActiveWeapon():GetWM():AddLayeredSequence(Entity(1):GetActiveWeapon():GetWM():LookupSequence("delta_foregrip"),1)
SWEP.FakeReloadSounds = {
	[0.2] = "weapons/darsu_eft/deagle/deagle_mag_out.ogg",
	[0.3] = "weapons/darsu_eft/deagle/deagle_mag_out_all.ogg",
	[0.8] = "weapons/darsu_eft/deagle/deagle_mag_in.ogg",
}

SWEP.FakeEmptyReloadSounds = {
	[0.1] = "weapons/darsu_eft/deagle/deagle_chamber_out.ogg",
	[0.2] = "weapons/darsu_eft/deagle/deagle_mag_out.ogg",
	[0.34] = "weapons/darsu_eft/deagle/deagle_mag_out_all.ogg",
	[0.8] = "weapons/darsu_eft/mp443/grach_mag_pullout.ogg",
	[0.6] = "weapons/darsu_eft/deagle/deagle_mag_in.ogg",
	[0.9] = "weapons/darsu_eft/deagle/deagle_chamber_in.ogg",
}
SWEP.MagModel = "models/weapons/zcity/w_glockmag.mdl"

SWEP.lmagpos = Vector(0,0,0)
SWEP.lmagang = Angle(0,0,0)
SWEP.lmagpos2 = Vector(-2,0,0)
SWEP.lmagang2 = Angle(0,0,-90)

SWEP.FakeMagDropBone = 50
local vector_full = Vector(1,1,1)

SWEP.FakeReloadEvents = {
	[0.15] = function( self, timeMul ) 
		if CLIENT then
			self:GetOwner():PullLHTowards("ValveBiped.Bip01_L_Thigh", 2.5 * timeMul)
			self:GetWM():ManipulateBoneScale(2, vector_full)
		end 
	end,
	[0.37] = function( self ) 
		if CLIENT and self:Clip1() < 1 then
			hg.CreateMag( self, Vector(-15,5,-15) )
			self:GetWM():ManipulateBoneScale(2, vector_origin)
		end 
	end,
	[0.55] = function( self ) 
		if CLIENT and self:Clip1() < 1 then
			self:GetWM():ManipulateBoneScale(2, vector_full)
		end 
	end,
}
SWEP.FakeBodyGroups = "131111111"
SWEP.AnimList = {
	["idle"] = "idle",
	["reload"] = "reload",
	["reload_empty"] = "reload_empty0",
}
--SWEP.ReloadHold = nil
SWEP.FakeVPShouldUseHand = false

SWEP.FakeViewBobBone = "ValveBiped.Bip01_R_Hand"
SWEP.FakeViewBobBaseBone = "ValveBiped.Bip01_R_Forearm"
SWEP.ViewPunchDiv = 50

SWEP.WepSelectIcon2 = Material("entities/arc9_eft_deagle_xix.png")
SWEP.IconOverride = "entities/arc9_eft_deagle_xix.png"

SWEP.CustomShell = "50ae"
SWEP.EjectPos = Vector(6,1,-20)
SWEP.EjectAng = Angle(-45,30,90)
SWEP.punchmul = 1.5
SWEP.punchspeed = 3
SWEP.weight = 2

SWEP.ScrappersSlot = "Secondary"

SWEP.weaponInvCategory = 2
SWEP.ShellEject = "EjectBrass_57"
SWEP.Primary.ClipSize = 8
SWEP.Primary.DefaultClip = 8
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = ".50 Action Express"
SWEP.Primary.Cone = 0
SWEP.Primary.Damage = 45
SWEP.Primary.Sound = {"weapons/darsu_eft/deagle/de357_indoor_close.wav", 75, 90, 100}
SWEP.SupressedSound = {"zcitysnd/sound/weapons/m45/m45_suppressed_fp.wav", 75, 90, 100}
SWEP.Primary.SoundEmpty = {"zcitysnd/sound/weapons/makarov/handling/makarov_empty.wav", 75, 100, 105, CHAN_WEAPON, 2}
SWEP.Primary.Force = 34
SWEP.Primary.Wait = PISTOLS_WAIT
SWEP.ReloadTime = 4.5
SWEP.ReloadSoundes = {
	"none",
	"weapons/tfa_ins2/usp_tactical/magout.wav",
	"weapons/tfa_ins2/browninghp/magin.wav",
	"pwb/weapons/fnp45/sliderelease.wav",
	"none",
	"none"
}
SWEP.DeploySnd = {"homigrad/weapons/draw_pistol.mp3", 55, 100, 110}
SWEP.HolsterSnd = {"homigrad/weapons/holster_pistol.mp3", 55, 100, 110}
SWEP.HoldType = "revolver"
SWEP.ZoomPos = Vector(-3, -0.3, 4.9)
SWEP.SprayRand = {Angle(-0.03, -0.03, 0), Angle(-0.05, 0.03, 0)}
SWEP.Ergonomics = 1.3
SWEP.Penetration = 7
SWEP.WorldPos = Vector(-0.1, -0.7, -0.5)
SWEP.WorldAng = Angle(0, 0, 0)

SWEP.LocalMuzzlePos = Vector(10.018,0.603,3.736)
SWEP.LocalMuzzleAng = Angle(0.2,0.0,0)
SWEP.WeaponEyeAngles = Angle(0,0,0)

SWEP.handsAng = Angle(-1, 10, 0)
SWEP.UseCustomWorldModel = true
SWEP.attPos = Vector(0, 0, 0)
SWEP.attAng = Angle(-0.125, -0.1, 0)
SWEP.lengthSub = 5
SWEP.DistSound = "weapons/darsu_eft/deagle/deagle_outdoor_close.wav"
SWEP.holsteredBone = "ValveBiped.Bip01_R_Thigh"
SWEP.holsteredPos = Vector(0, -2, -1)
SWEP.holsteredAng = Angle(0, 20, 30)
SWEP.shouldntDrawHolstered = true
SWEP.RHandPos = Vector(3, -1, 0)
SWEP.LHandPos = false
SWEP.availableAttachments = {
	barrel = {
		[1] = {"supressor4", Vector(0,0,0), {}},
		[2] = {"supressor6", Vector(4.2,0,0), {}},
		["mount"] = Vector(-0.2,1.1,0),
	},
    magwell = {
        [1] = {"mag1",Vector(-6.3,-2.2,0), {}},
		[2] = {"mag_glock",Vector(0,0,0), {}}
    },
	sight = {
		["mountType"] = {"picatinny","pistolmount"},
		["mount"] = {["picatinny"] = Vector(-3.1, 2.15, 0), ["pistolmount"] = Vector(-1, .5, 0.025)},
		["mountAngle"] = Angle(0,0,0),
	},
	underbarrel = {
		["mount"] = Vector(12, -0.35, -1),
		["mountAngle"] = Angle(0, -0.6, 90),
		["mountType"] = "picatinny_small"
	},
	mount = {
		["picatinny"] = {
			"mount4",
			Vector(-1.5, -.1, 0),
			{},
			["mountType"] = "picatinny",
		}
	},
	grip = {
		["mount"] = Vector(15, 1.2, 0.1), 
		["mountType"] = "picatinny"
	}
}
--local to head
SWEP.RHPos = Vector(10,-4.5,3)
SWEP.RHAng = Angle(0,-5,90)
--local to rh
SWEP.LHPos = Vector(-1.2,-1.4,-2.8)
SWEP.LHAng = Angle(5,9,-100)

local finger1 = Angle(-25,10,25)
local finger2 = Angle(0,25,0)
local finger3 = Angle(31,1,-25)
local finger4 = Angle(-10,-5,-5)
local finger5 = Angle(0,-65,-15)
local finger6 = Angle(15,-5,-15)

function SWEP:AnimHoldPost()
	--self:BoneSet("r_finger0", vector_zero, finger6)
	--self:BoneSet("l_finger0", vector_zero, finger1)
    --self:BoneSet("l_finger02", vector_zero, finger2)
	--self:BoneSet("l_finger1", vector_zero, finger3)
	--self:BoneSet("r_finger1", vector_zero, finger4)
	--self:BoneSet("r_finger11", vector_zero, finger5)
end
SWEP.ShootAnimMul = 4


function SWEP:DrawPost()
	local wep = self:GetWeaponEntity()
	if CLIENT and IsValid(wep) then
		self.shooanim = LerpFT(0.4,self.shooanim or 0,(self:Clip1() > 0 or self.reload) and 0 or 3)
		wep:ManipulateBonePosition(94,Vector(0 ,1*self.shooanim,0*self.shooanim ),false)
	end
end

--RELOAD ANIMS PISTOL

SWEP.ReloadAnimLH = {
	Vector(0,0,0),
	Vector(0,0,0),
	Vector(-3,-1,-5),
	Vector(-12,1,-22),
	Vector(-12,1,-22),
	Vector(-12,1,-22),
	Vector(-12,1,-22),
	Vector(-2,-1,-3),
	"fastreload",
	Vector(0,0,0),
	"reloadend",
	"reloadend",
}
SWEP.ReloadAnimLHAng = {
	Angle(0,0,0),
	Angle(0,0,0),
	Angle(30,-10,0),
	Angle(60,-20,0),
	Angle(70,-40,0),
	Angle(90,-30,0),
	Angle(40,-20,0),
	Angle(0,0,0),
	Angle(0,0,0),
	Angle(0,0,0),
	Angle(0,0,0),
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
	Vector(-2,0,0),
	Vector(-1,0,0),
	Vector(0,0,0)
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
	Angle(0,0,0),
	Angle(15,2,20),
	Angle(15,2,20),
	Angle(0,0,0)
}
SWEP.ReloadAnimWepAng = {
	Angle(0,0,0),
	Angle(5,15,15),
	Angle(-5,21,14),
	Angle(-5,21,14),
	Angle(5,20,13),
	Angle(5,22,13),
	Angle(1,22,13),
	Angle(1,21,13),
	Angle(2,22,12),
	Angle(-5,21,16),
	Angle(-5,22,14),
	Angle(-4,23,13),
	Angle(7,22,8),
	Angle(7,12,3),
	Angle(2,6,1),
	Angle(0,0,0)
}


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
	Angle(6,0,5),
	Angle(15,0,14),
	Angle(16,0,16),
	Angle(4,0,12),
	Angle(-6,0,-2),
	Angle(-15,7,-15),
	Angle(-16,18,-35),
	Angle(-17,17,-42),
	Angle(-18,16,-44),
	Angle(-14,10,-46),
	Angle(-2,2,-4),
	Angle(0,0,0)
}
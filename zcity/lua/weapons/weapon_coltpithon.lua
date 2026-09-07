SWEP.Base = "weapon_revolver2"
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.PrintName = "Colt Python"
SWEP.Author = "Colt's Manufacturing Co."
SWEP.Instructions = "Revolver chambered in .357 Magnum"
SWEP.Category = "Weapons - Pistols"
SWEP.Slot = 2
SWEP.SlotPos = 10
SWEP.ViewModel = ""
SWEP.WorldModel = "models/weapons/w_357.mdl"
SWEP.WorldModelFake = "models/weapons/arc9/python.mdl"
SWEP.FakePos = Vector(-18.0, 7.06, 6.0)
SWEP.FakeAng = Angle(-0.15, 0, 1)
SWEP.AttachmentPos = Vector(0,0,0)
SWEP.AttachmentAng = Angle(0,0,0)
SWEP.FakeAttachment = "1"

function SWEP:RevolverPostInit()
	self.FakeEmptyReloadSounds = {
		[0.16] = "weapons/universal/uni_crawl_l_03.wav",
		[0.25] = "weapons/arccw_ur/sw586/cylinder_out.ogg",
		[0.38] = "weapons/arccw_ur/dbs/mech-01.ogg",
		[0.39] = "weapons/arccw_ur/sw586/extractor1.ogg",
		[0.40] = "weapons/tfa_ins2/thanez_cobra/revolver_dump_rounds_01.wav",
		[0.52] = "weapons/universal/uni_crawl_l_01.wav",
		[0.70] = "weapons/arccw_ur/sw586/speedloader.ogg",
		[0.90] = "weapons/arccw_ur/sw586/cylinder_in.ogg"
	}
	self.FakeReloadSounds = {
		[0.16] = "weapons/universal/uni_crawl_l_03.wav",
		[0.25] = "weapons/arccw_ur/sw586/cylinder_out.ogg",
		[0.38] = "weapons/arccw_ur/dbs/mech-01.ogg",
		[0.39] = "weapons/arccw_ur/sw586/extractor1.ogg",
		[0.40] = "weapons/tfa_ins2/thanez_cobra/revolver_dump_rounds_01.wav",
		[0.52] = "weapons/universal/uni_crawl_l_01.wav",
		[0.70] = "weapons/arccw_ur/sw586/speedloader.ogg",
		[0.90] = "weapons/arccw_ur/sw586/cylinder_in.ogg"
	}

	function self:DrawPost()
		local wep = self:GetWM()
		self.vec = self.vec or Vector(0,0,0)
		local vec = self.vec
		if CLIENT and IsValid(wep) and not self:ShouldUseFakeModel() then
			self.DrumAng = LerpFT(0.05,self.DrumAng or 0,self:GetNWInt("drumroll",0))
			wep:ManipulateBoneAngles(88,Angle(-(360/6)*self.DrumAng,0,0))
		end
	end
end

SWEP.MagModel = "models/weapons/upgrades/w_magazine_m45_8.mdl"

function SWEP:OnCantReload()
	--inspect1
	--print("piska")
	if self.Inspecting and self.Inspecting > CurTime() then return end
	self.Inspecting = CurTime() + 3
	self:PlayAnim("enter_inspect",3,false,function(self)
		self:PlayAnim("idle",1)
		--self.Inspecting = false
	end,false,true)

end

SWEP.AnimsEvents = {
	["enter_inspect"] = {
		[0.05] = function(self)
			self:EmitSound("weapons/arccw_ur/sw586/cylinder_out.ogg",55)
		end,
		[0.45] = function(self)
			--self:EmitSound("weapons/kf2_winchester/leveropen.wav",55)
		end,
		[0.65] = function(self)
			self:EmitSound("weapons/arccw_ur/sw586/cylinder_in.ogg",55)
		end,
	},
}

if CLIENT then
	local vector_full = Vector(1, 1, 1)
	SWEP.FakeReloadEvents = {
		[0.2] = function( self, timeMul )
			self:GetWM():ManipulateBoneScale(90, vector_full)
		end,

		[0.40] = function( self, timeMul )
			if CLIENT then
				local owner = self:GetOwner()
				local drum = self:GetDrum()
				for i = 1, #drum do
					if self.CustomShell and drum[i] == -1 then
						local pos, ang = self:GetWM():GetBonePosition(90)
						self:MakeShell(self.CustomShell, pos, ang, Vector(0,0,0)) 
					end
				end
			end
			self:GetWM():ManipulateBoneScale(90, vector_origin)
		end,
		[0.55] = function( self ) 
			self:GetWM():ManipulateBoneScale(86, vector_full)
			self:GetWM():ManipulateBoneScale(90, vector_full)
		end,
		[0.5] = function( self ) 
			for i = 96, 108 do
				self:GetWM():ManipulateBoneScale(i, vector_full)
			end
			for i = 104, 108 do
				self:GetWM():ManipulateBoneScale(i, vector_full)
			end
		end,
		[0.9] = function( self ) 
			for i = 96, 108 do
				self:GetWM():ManipulateBoneScale(i, vector_full)
			end
			for i = 104, 108 do
				self:GetWM():ManipulateBoneScale(i, vector_full)
			end
		end,
		[0.85] = function( self ) 
			self:GetWM():ManipulateBoneScale(86, vector_origin)
		end,
	}

	function SWEP:ModelCreated(model)
			self:GetWM():ManipulateBoneScale(86, vector_origin)
	end
end
SWEP.AnimList = {
	["idle"] = "idle",
	["reload"] = "reload",
	["reload_empty"] = "reload",
}

SWEP.WepSelectIcon2 = Material("vgui/hud/m9k_coltpython")
SWEP.WepSelectIcon2box = true
SWEP.IconOverride = "vgui/entities/m9k_coltpython"

SWEP.PPSMuzzleEffect = "muzzleflash_pistol_rbull" -- shared in sh_effects.lua

SWEP.weight = 3

SWEP.ScrappersSlot = "Secondary"

SWEP.LocalMuzzlePos = Vector(3.737,0.7,3.465)
SWEP.LocalMuzzleAng = Angle(-0.3,-0.02,0)
SWEP.WeaponEyeAngles = Angle(0,0,0)

SWEP.weaponInvCategory = 2
SWEP.ShellEject2 = "EjectBrass_57"
SWEP.Primary.ClipSize = 6
SWEP.Primary.DefaultClip = 6
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = ".357 Magnum"
SWEP.Primary.Cone = 0
SWEP.Primary.Damage = 40
SWEP.Primary.Spread = 0
SWEP.Primary.Force = 30
SWEP.Primary.Sound = {"weapons/coltpython/python-1.wav", 75, 90, 100}
SWEP.SupressedSound = {"weapons/tfa_ins2/usp_tactical/fp_suppressed1.wav", 65, 90, 100}
SWEP.Primary.Wait = 0.2
SWEP.ReloadTime = 6
SWEP.ShellEject = false
SWEP.DeploySnd = {"homigrad/weapons/draw_pistol.mp3", 55, 100, 110}
SWEP.HolsterSnd = {"homigrad/weapons/holster_pistol.mp3", 55, 100, 110}
SWEP.HoldType = "revolver"
SWEP.AimHold = "revolver"
SWEP.ZoomPos = Vector(0, 0.6493, 4.1727)
SWEP.RHandPos = Vector(0, 0, 1)
SWEP.LHandPos = false
SWEP.SprayRand = {Angle(-0.1, -0.2, 0), Angle(-0.2, 0.2, 0)}
SWEP.AnimShootMul = 10
SWEP.AnimShootHandMul = 45
SWEP.Ergonomics = 0.9
SWEP.OpenBolt = true
SWEP.Penetration = 10

SWEP.CustomShell = "10mm"

function SWEP:PostFireBullet(bullet)
	SlipWeapon(self, bullet)
end

SWEP.punchmul = 15
SWEP.punchspeed = 0.5
SWEP.podkid = 3

SWEP.WorldPos = Vector(-4.5, -0.6, -1.5)
SWEP.WorldAng = Angle(0, 0, 0)
SWEP.UseCustomWorldModel = true
SWEP.attPos = Vector(0, 0, 0)
SWEP.attAng = Angle(0, 0, 90)
SWEP.lengthSub = 25
SWEP.DistSound = "m9/m9_dist.wav"
SWEP.holsteredBone = "ValveBiped.Bip01_R_Thigh"
SWEP.holsteredPos = Vector(0, -2, -1)
SWEP.holsteredAng = Angle(0, 20, 30)
SWEP.shouldntDrawHolstered = true

--local to head
SWEP.RHPos = Vector(12,-5,4)
SWEP.RHAng = Angle(5,-5,90)
--local to rh
SWEP.LHPos = Vector(-1.2,-1.4,-2.8)
SWEP.LHAng = Angle(5,9,-100)

SWEP.ReloadSoundes = {
	"none",
	"none",
	"weapons/tfa_ins2/swmodel10/revolver_open_chamber.wav",
	"none",
	"none",
	"weapons/tfa_ins2/thanez_cobra/revolver_dump_rounds_01.wav",
	"none",
	"none",
	"none",
	"weapons/tfa_ins2/thanez_cobra/revolver_speed_loader_insert_01.wav",
	"none",
	"weapons/tfa_ins2/thanez_cobra/revolver_close_chamber.wav",
	"none",
	"none",
	"none"
}

local finger1 = Angle(-15,25,0)
local finger2 = Angle(0,35,45)

function SWEP:DrawPost()
	local wep = self:GetWeaponEntity()
	self.vec = self.vec or Vector(0,0,0)
	local vec = self.vec
	if CLIENT and IsValid(wep) then
		self.DrumAng = LerpFT( 0.05, self.DrumAng or 0,self:GetNWInt("drumroll",0) )
		wep:ManipulateBoneAngles(88,Angle(-(360/6)*(self.reload and 0 or self.DrumAng),0,0))
	end
end

function SWEP:AnimHoldPost(model)
end


--RELOAD ANIMS PISTOL

SWEP.ReloadAnimLH = {
	Vector(0,0,0),
	Vector(4,1,2),
	Vector(3,0,1),
	Vector(-5,3,-4),
	Vector(-7,1,3),
	Vector(5,2,-2),
	Vector(0,0,0),
	"reloadend",
}
SWEP.ReloadAnimLHAng = {
	Angle(0,0,0),
	Angle(0,0,-40),
	Angle(0,0,-50),
	Angle(0,0,-30),
	Angle(-25,35,-20),
	Angle(-35,25,-10),
	Angle(0,0,0),
	Angle(0,0,0),
}

SWEP.ReloadSlideAnim = {
	0,
	1,
	1,
	1,
	1,
	1,
	1,
	1,
	1,
	1,
	1,
	1,
	1,
	0,
	0,
	0,
	0
}

SWEP.ReloadAnimRH = {
	Vector(0,0,0)
}
SWEP.ReloadAnimRHAng = {
	Angle(0,0,0)
}
SWEP.ReloadAnimWepAng = {
	Angle(0,0,0),
	Angle(-15,5,-25),
	Angle(-15,5,-15),
	Angle(-20,5,5),
	Angle(-12,0,-15),
	Angle(-5,0,-20),
	Angle(0,0,-25),
	Angle(0,0,-25),
	Angle(0,0,-25),
	Angle(0,0,-25),
	Angle(0,0,-25),
	Angle(-5,-5,65),
	Angle(0,0,15),
	Angle(0,0,0)
}

SWEP.InspectAnimWepAng = {
	Angle(0,0,0),
	Angle(4,4,15),
	Angle(10,15,25),
	Angle(10,15,25),
	Angle(10,15,25),
	Angle(-6,-15,-15),
	Angle(1,15,-45),
	Angle(15,25,-55),
	Angle(15,25,-55),
	Angle(15,25,-55),
	Angle(0,0,0),
	Angle(0,0,0)
}
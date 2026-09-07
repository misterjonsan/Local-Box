--ents.Reg(nil,"weapon_m4super")
SWEP.Base = "weapon_m4super"
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.PrintName = "ksg"
SWEP.Author = "Kel-Tec."
SWEP.Instructions = "Bullpub Pump-action shotgun chambered in 12/70 caliber"
SWEP.Category = "Weapons - Shotguns"
SWEP.Slot = 2
SWEP.SlotPos = 10
SWEP.ViewModel = ""
SWEP.WorldModel = "models/weapons/tfa_ins2/w_ksg.mdl"
SWEP.WorldModelFake = "models/weapons/tfa_ins2/c_ksg.mdl" --короче этот дробовик я ещё раньше хотел добавить но добавил сейчас...
//SWEP.FakeScale = 1.5
//PrintAnims(Entity(1):GetActiveWeapon():GetWM())
--PrintTable(Entity(1):GetActiveWeapon():GetWM():GetAttachments())
--uncomment for funny
SWEP.FakePos = Vector(-7, 3.6, 8.2)
SWEP.FakeAng = Angle(0, 0.1, 2)
//SWEP.MagIndex = 41
SWEP.FakeAttachment = "1"
SWEP.AttachmentPos = Vector(6.8,0.156,0.9)
SWEP.AttachmentAng = Angle(0,0.120,90)
SWEP.FakeBodyGroups = "000000002"

SWEP.FakeBodyGroupsPresets = {
	"000010302",
	"000000002",
}
//SWEP.MagIndex = 6
//MagazineSwap
--Entity(1):GetActiveWeapon():GetWM():AddLayeredSequence(Entity(1):GetActiveWeapon():GetWM():LookupSequence("delta_foregrip"),1)
SWEP.FakeViewBobBone = "CAM_Homefield"
SWEP.FakeReloadSounds = {
	[0.25] = "weapons/ak74/ak74_magout.wav",
	[0.34] = "weapons/ak74/ak74_magout_rattle.wav",
	[0.85] = "weapons/ak74/ak74_magin.wav",
	[0.95] = "weapons/universal/uni_crawl_l_05.wav",
	--[0.95] = "weapons/ak74/ak74_boltback.wav"
}

SWEP.FakeEmptyReloadSounds = {
	--[0.22] = "weapons/ak74/ak74_magrelease.wav",
	[0.25] = "weapons/ak74/ak74_magout.wav",
	[0.34] = "weapons/ak74/ak74_magout_rattle.wav",
	[0.65] = "weapons/ak74/ak74_magin.wav",
	[0.75] = "weapons/universal/uni_crawl_l_05.wav",
	--[0.95] = "weapons/ak74/ak74_boltback.wav",
	[0.91] = "weapons/ak74/ak74_boltback.wav",
	[0.96] = "weapons/ak74/ak74_boltrelease.wav",
}
SWEP.MagModel = "models/weapons/upgrades/w_magazine_m1a1_30.mdl"
SWEP.FakeReloadEvents = {
}

SWEP.FakeViewBobBone = "ValveBiped.Bip01_L_Hand"
SWEP.FakeViewBobBaseBone = "ValveBiped.Bip01_L_UpperArm"
SWEP.ViewPunchDiv = 30

--SWEP.ReloadHold = nil
SWEP.FakeVPShouldUseHand = false

SWEP.WepSelectIcon2 = Material("materials/entities/tfa_ins2_ksg.png")
SWEP.IconOverride = "materials/entities/tfa_ins2_ksg.png"

SWEP.LocalMuzzlePos = Vector(27.739,0.09,5.098)
SWEP.LocalMuzzleAng = Angle(0.2,-0.0,0)
SWEP.WeaponEyeAngles = Angle(-0.7,0.1,0)

SWEP.CustomShell = "12x70"
--SWEP.EjectPos = Vector(-0,8,4)
--SWEP.EjectAng = Angle(0,-90,0)
SWEP.ReloadSound = "weapons/remington_870/870_shell_in_1.wav"
SWEP.CockSound = "pwb2/weapons/ithaca37stakeout/pump.wav"
SWEP.weight = 4
SWEP.ScrappersSlot = "Primary"
SWEP.weaponInvCategory = 1
SWEP.ShellEject = "ShotgunShellEject"
SWEP.AutomaticDraw = false
SWEP.UseCustomWorldModel = false
SWEP.Primary.ClipSize = 14
SWEP.Primary.DefaultClip = 14
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "12/70 gauge"
SWEP.Primary.Cone = 0
SWEP.Primary.Spread = Vector(0.01, 0.01, 0.01)
SWEP.Primary.Sound = {"weapons/tfa_ins2/ksg/toz_fp.wav", 80, 90, 100}
SWEP.SupressedSound = {"toz_shotgun/toz_suppressed_fp.wav", 65, 90, 100}
SWEP.availableAttachments = {
	barrel = {
		[1] = {"supressor5", Vector(-6.5,-1,0), {}},
	},
	sight = {
		["mountType"] = "picatinny",
		["mount"] = Vector(-18, 0.50, 0),Angle(0, -0.0010, 90),
	},
}

--models/weapons/tfa_ins2/upgrades/att_suppressor_12ga.mdl
SWEP.Primary.Wait = 0.15
SWEP.NumBullet = 8
SWEP.AnimShootMul = 3
SWEP.AnimShootHandMul = 10
SWEP.DeploySnd = {"homigrad/weapons/draw_hmg.mp3", 55, 100, 110}
SWEP.HolsterSnd = {"homigrad/weapons/hmg_holster.mp3", 55, 100, 110}
SWEP.HoldType = "rpg"
SWEP.ZoomPos = Vector(0, 0.56, 6.6841)
SWEP.RHandPos = Vector(0, 0, -1)
SWEP.LHandPos = Vector(7, 0, -2)
SWEP.Ergonomics = 0.9
SWEP.Penetration = 7
SWEP.WorldPos = Vector(0.2, -0.2, 1.2)
SWEP.WorldAng = Angle(0.6, -0.7, -2)
SWEP.UseCustomWorldModel = true
SWEP.attPos = Vector(0.4, -0.15, 0)
SWEP.attAng = Angle(0, 0.2, 0)
SWEP.lengthSub = 20

SWEP.holsteredBone = "ValveBiped.Bip01_Spine2"
SWEP.holsteredPos = Vector(4, 8, -6)
SWEP.holsteredAng = Angle(210, 0, 180)

--local to head
--SWEP.RHPos = Vector(1,-5,3.4)
--SWEP.RHAng = Angle(0,-15,90)
----local to rh
--SWEP.LHPos = Vector(18,-0.8,-3.6)
--SWEP.LHAng = Angle(-100,-180,0)

SWEP.AnimList = {
	["idle"] = "base_idle",
	["reload"] = "base_reload",
	["reload_empty"] = "base_reload_end",
	["finish_empty"] = "base_reload_end_empty",
	["finish"] = "finish",
	["insert"] = "base_reload_insert",
	["start"] = "base_reload_start",
	["cycle"] = "base_pump_1",
}
SWEP.AnimsEvents = {
	["base_reload_insert"] = {
		[0.0] = function(self)
			self:EmitSound("weapons/arccw_ud/870/shell-insert-0"..math.random(1,3)..".ogg")
			--
			--self:GetWM():ManipulateBoneScale(47, vector_full)
		end,
		[0.8] = function(self)
			--self:GetWM():ManipulateBoneScale(47, vector_origin)
		end,
	},
	["base_pump_1"] = {
		[0.0] = function(self)
			self:EmitSound("weapons/arccw_ud/870/rack_1.ogg")
			--
			--self:GetWM():ManipulateBoneScale(47, vector_full)
		end,
		[0.1] = function(self)
			self:EmitSound("weapons/arccw_ud/870/eject.ogg")
			--
			--self:GetWM():ManipulateBoneScale(47, vector_full)
		end,
		[0.2] = function(self)
			self:EmitSound("weapons/arccw_ud/870/rack_2.ogg")
			--
			--self:GetWM():ManipulateBoneScale(47, vector_full)
		end
	},
	["base_reload_end_empty"] = {
		[0.0] = function(self)
			self:EmitSound("weapons/arccw_ud/870/rack_1.ogg")
			--
			--self:GetWM():ManipulateBoneScale(47, vector_full)
		end,
		[0.3] = function(self)
			self:EmitSound("weapons/arccw_ud/870/rack_2.ogg")
			--
			--self:GetWM():ManipulateBoneScale(47, vector_full)
		end
	}
}

SWEP.stupidgun = true

function SWEP:AnimHoldPost()
end

function SWEP:ModelCreated(model)
	model:ManipulateBoneScale(57, vector_origin)
	model:ManipulateBoneScale(58, vector_origin)
	model:SetBodyGroups(self:GetRandomBodygroups() or "0000000000200")
end

function SWEP:PostSetupDataTables()
	self:NetworkVar("String",0,"RandomBodygroups")
	if ( CLIENT ) then
		self:NetworkVarNotify( "RandomBodygroups", self.OnVarChanged )
	end
end

function SWEP:OnVarChanged( name, old, new )
	if !IsValid(self:GetWM()) then return end

	self:GetWM():SetBodyGroups(new)
end

function SWEP:InitializePost()
	self:SetRandomBodygroups(table.Random(self.FakeBodyGroupsPresets))
	self.AnimStart_Insert = 0
	self.AnimStart_Draw = 0
end

local ang1 = Angle(0, -10, 0)
local ang2 = Angle(0, -10, 0)

function SWEP:AnimationPost()
	local animpos = math.Clamp(self:GetAnimPos_Draw(CurTime()),0,1)
	local sin = 1 - animpos
	if sin >= 0.5 then
		sin = 1 - sin
	else
		sin = sin * 1
	end
	sin = sin * 2
	--sin = math.ease.InOutExpo(sin)
	sin = math.ease.InOutSine(sin)

	if sin > 0 then
		self.LHPos[1] = 18 - sin * 6
		self.RHPos[1] = 1 - sin * 4
		self.inanim = true
	else
		self.inanim = nil
	end

	local wep = self:GetWeaponEntity()
	if CLIENT and IsValid(wep) then
		wep:ManipulateBonePosition(4,Vector(0,0,sin * -3),false)
	end
end

function SWEP:GetAnimPos_Insert(time)
	return 0
end

function SWEP:GetAnimPos_Draw(time)
	return 0
end

local function cock(self,time)
	
	if SERVER then
		self:Draw(true)
	end

	if self:Clip1() == 0 then
		self.drawBullet = nil
	end

	if CLIENT and LocalPlayer() == self:GetOwner() then return end

	net.Start("hgwep draw")
		net.WriteEntity(self)
		net.WriteBool(self.drawBullet)
		net.WriteFloat(CurTime())
	net.Broadcast()
	
	self.Primary.Next = CurTime() + self.AnimDraw + self.Primary.Wait
	if CLIENT then self:PlaySnd(self.CockSound or "weapons/shotgun/shotgun_cock.wav",true,CHAN_AUTO) end

	local ply = self:GetOwner()

	self.reloadCoolDown = CurTime() + time
end


SWEP.GunCamPos = Vector(6,-12,-5)
SWEP.GunCamAng = Angle(190,-5,-95)

local vector_full = Vector(1,1,1)

local function reloadFunc(self)
	if not SERVER then return end
	if SERVER then self:SetNetVar("shootgunReload",CurTime() + 1.1) end
	if self.MagIndex then
		self:GetWM():ManipulateBoneScale(self.MagIndex, vector_full)
	end
	
	self:PlayAnim(self.AnimList["insert"] or "base_reload_insert", 1, false, function() 
		self:InsertAmmo(1)
		if self.MagIndex then
			self:GetWM():ManipulateBoneScale(self.MagIndex, vector_origin)
		end
		
		local key = hg.KeyDown(self:GetOwner(), IN_RELOAD)
		--print("reload",key)
		
		if key and self:CanReload() then
			reloadFunc(self)
			return
		end
		--self:GetOwner():ChatPrint(tostring(self.drawBullet))
		--self:PlaySnd(self.CockSound or "weapons/shotgun/shotgun_cock.wav",true,CHAN_AUTO)
		if !self.drawBullet then
			cock(self,1)
			self:PlayAnim(self.AnimList["finish_empty"] or "base_reload_end_empty", 1,false,function(self) self:SetNetVar("shootgunReload",0) end,false,true) 
		else
			self:PlayAnim(self.AnimList["finish"] or "finish", 1,false,function(self) self:SetNetVar("shootgunReload",0) end,false,true) 
		end
	end, false, true)
end

SWEP.FakeEjectBrassATT = "2"

function SWEP:Reload(time)
	--print(self:GetNetVar("shootgunReload",0))
	if self.AnimStart_Draw > CurTime() - 0.5 then return end
	if not self:CanUse() then return end
	if self.reloadCoolDown > CurTime() then return end
	if self.Primary.Next > CurTime() then return end
	if self:GetNetVar("shootgunReload",0) > CurTime() then return end

	if self.drawBullet == false and SERVER then
		cock(self,1)
		self:PlayAnim(self.AnimList["cycle"] or "base_pump_1", 0.5, false, nil, false, true)
		return
	end

	if not self:CanReload() then return end

	if SERVER then
		self:SetNetVar("shootgunReload",CurTime() + 1.1)
		self:PlayAnim(self.AnimList["start"] or "sgreload_start",1,false,function() 
			reloadFunc(self)
		end,
		false,true)
	end
end

function SWEP:CanPrimaryAttack()
	return not (self:GetNetVar("shootgunReload",0) > CurTime())
end


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
	Angle(-5,9,5),
	Angle(-5,9,14),
	Angle(-5,9,16),
	Angle(-6,10,15),
	Angle(-5,9,16),
	Angle(-10,15,-15),
	Angle(-2,22,-15),
	Angle(0,25,-32),
	Angle(0,24,-45),
	Angle(0,22,-55),
	Angle(0,20,-56),
	Angle(0,0,0)
}
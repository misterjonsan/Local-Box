--ents.Reg(nil,"weapon_m4super")
SWEP.Base = "weapon_m4super"
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.PrintName = "MR-155"
SWEP.Author = "Izhevsk Mechanical Plant"
SWEP.Instructions = "Russian-Semi-automatic shotgun chambered in 12/70"
SWEP.Category = "Weapons - Shotguns"
SWEP.Slot = 2
SWEP.SlotPos = 10
SWEP.ViewModel = ""
SWEP.WorldModel = "models/weapons/tfa_ins2/w_m1014.mdl"
SWEP.ReloadSound = "weapons/tfa_ins2/m1014/toz_shell_insert_2.wav"
SWEP.WepSelectIcon2 = Material("materials/entities/arccw_eft_mp155.png")
SWEP.IconOverride = "materials/entities/arccw_eft_mp155.png"
SWEP.WorldModelFake = "models/weapons/arccw/darsu_eft/c_mp153.mdl"
//SWEP.FakeScale = 1.5
--PrintAnims(Entity(1):GetActiveWeapon():GetWM())
--PrintTable(Entity(1):GetActiveWeapon():GetWM():GetAttachments())
--uncomment for funny
SWEP.FakePos = Vector(-10, 3.035, 3.45)
SWEP.FakeAng = Angle(0, 0, 1)
--SWEP.MagIndex = 47
SWEP.FakeAttachment = "1"
SWEP.AttachmentPos = Vector(-5,-0.15,0.7)
SWEP.AttachmentAng = Angle(0,0,-89.1)
SWEP.FakeBodyGroups = "00120030000"
SWEP.FakeBodyGroupsPresets = {
	"00120030000",
	"00020000000",
	"14272244110",
	"14272244100",
}

//SWEP.MagIndex = 6
//MagazineSwap
--Entity(1):GetActiveWeapon():GetWM():AddLayeredSequence(Entity(1):GetActiveWeapon():GetWM():LookupSequence("delta_foregrip"),1)
SWEP.FakeEjectBrassATT = "2"
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
SWEP.ViewPunchDiv = 10


SWEP.availableAttachments = {
	sight = {
		["mountType"] = "picatinny",
		["mount"] = Vector(-23, 1, 0.16),
		--[[["empty"] = {
			"empty",
			{
				[1] = "null",
				[2] = "null"
			},
		},]]--
	},
	barrel = {
		[1] = {"supressor5", Vector(-2.5,0,0.2), {}},
	}
}

SWEP.holsteredBone = "ValveBiped.Bip01_Spine2"
SWEP.holsteredPos = Vector(6, 9, -1)
SWEP.holsteredAng = Angle(210, 0, 180)

SWEP.LocalMuzzlePos = Vector(27.415,0.388,1.061)
SWEP.LocalMuzzleAng = Angle(0.1,-0.02,0)
SWEP.WeaponEyeAngles = Angle(0,0,0)

SWEP.weight = 4
SWEP.ScrappersSlot = "Primary"
SWEP.weaponInvCategory = 1
SWEP.CustomShell = "12x70"
--SWEP.EjectPos = Vector(-5,0,10)
--SWEP.EjectAng = Angle(-80,-90,0)
SWEP.UseCustomWorldModel = false
SWEP.Primary.ClipSize = 7
SWEP.Primary.DefaultClip = 7
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "12/70 gauge"
SWEP.Primary.Cone = 0
SWEP.Primary.Spread = Vector(0.01, 0.01, 0.01)
SWEP.NumBullet = 8

SWEP.Primary.Sound = {"weapons/darsu_eft/mp153/mr153_fire_close1.wav", 80, 70, 75}
SWEP.Primary.DistSound = {"weapons/darsu_eft/mp153/mr153_fire_distant1.wav", 80, 70, 75}
SWEP.Primary.Wait = 0.2
SWEP.NoWINCHESTERFIRE = true
SWEP.DeploySnd = {"homigrad/weapons/draw_hmg.mp3", 65, 100, 110}
SWEP.HolsterSnd = {"homigrad/weapons/hmg_holster.mp3", 65, 100, 110}
SWEP.HoldType = "rpg"
SWEP.ZoomPos = Vector(-3, -1.3125, 2.8564)
SWEP.RHandPos = Vector(-10, -2, 4)
SWEP.LHandPos = Vector(7, -2, 0)
SWEP.SprayRand = {Angle(-0.2, -0.4, 0), Angle(-0.4, 0.4, 0)}
SWEP.Ergonomics = 0.9
SWEP.Penetration = 7
SWEP.WorldPos = Vector(2, -0.5, -2.8)
SWEP.WorldAng = Angle(0, 0, -2)
SWEP.UseCustomWorldModel = true
SWEP.attPos = Vector(0, 0, 0)
SWEP.attAng = Angle(0, -0.1, 90)
SWEP.lengthSub = 18
SWEP.handsAng = Angle(0, -2, 0)
SWEP.ViewPunchDiv = 500

local finger1 = Angle(10, -12, -25)
local finger2 = Angle(-10,30,0)
local finger3 = Angle(0,-10,0)

function SWEP:AnimHoldPost(model)
	self:BoneSet("l_finger0", vector_zero, finger1)
end

function SWEP:GetAnimPos_Insert(time)
	return 0
end

function SWEP:GetAnimPos_Draw(time)
	return 0
end

SWEP.AnimList = {
	["idle"] = "idle",
	["reload"] = "reload_start",
	["reload_empty"] = "reload_start_empty",
	["finish_empty"] = "reload_end",
	["start_empty"] = "reload_start_empty",
	["finish"] = "reload_end",
	["insert"] = "reload_loop",
	["start"] = "reload_start",
	["cycle"] = "cycle",
}

function SWEP:AnimHoldPost()
end

function SWEP:ModelCreated(model)
	if CLIENT and self:GetWM() and not isbool(self:GetWM()) and isstring(self.FakeBodyGroups) then
		self:GetWM():ManipulateBoneScale(47, vector_origin)
		self:GetWM():SetBodyGroups(self.FakeBodyGroups)
		--local ent = self:GetWM()
		--ent:SetColor(Color(255,0,0))
	end
end


function SWEP:InitializePost()
	self.AnimStart_Insert = 0
	self.AnimStart_Draw = 0
end

function SWEP:AnimationPost()
end

local ang1 = Angle(0, -10, 0)
local ang2 = Angle(0, -10, 0)

function SWEP:DrawPost()
	local wep = self:GetWeaponEntity()
	self.vec = self.vec or Vector(0,0,0)
	local vec = self.vec
	if CLIENT and IsValid(wep) then
		self.shooanim = LerpFT(0.4,self.shooanim or 0,self:Clip1() > 0 and 0 or 0)
		vec[1] = 0
		vec[2] = 0
		vec[3] = -3*self.shooanim
		wep:ManipulateBonePosition(42,vec,false)
		--vec[1] = -1*self.ReloadSlideOffset
		--vec[2] = 0.09*self.ReloadSlideOffset
		--vec[3] = -0.06*self.ReloadSlideOffset
		--wep:ManipulateBonePosition(2,vec,false)
	end
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
	--self:PlaySnd(self.CockSound or "weapons/shotgun/shotgun_cock.wav",true,CHAN_AUTO)

	local ply = self:GetOwner()

	self.reloadCoolDown = CurTime() + time
end


SWEP.GunCamPos = Vector(6,-12,-5)
SWEP.GunCamAng = Angle(190,-5,-95)

local vector_full = Vector(1,1,1)

local function reloadFunc(self)
	if not SERVER then return end
	if SERVER then self:SetNetVar("shootgunReload",CurTime() + 1.1) end
	self:GetWM():ManipulateBoneScale(47, vector_full)
	--self:GetOwner():PullLHTowards("ValveBiped.Bip01_Spine2", 0.58)

	self:PlayAnim(self.AnimList["insert"] or "sgreload_insert", 1, false, function() 
		self:InsertAmmo(1) 
		self:GetWM():ManipulateBoneScale(47, vector_origin)
		
		local key = hg.KeyDown(self:GetOwner(), IN_RELOAD)
		--print("reload",key)
		
		if key and self:CanReload() then
			reloadFunc(self)
			return
		end
		--self:GetOwner():ChatPrint(tostring(self.drawBullet))
		--self:PlaySnd(self.CockSound or "weapons/shotgun/shotgun_cock.wav",true,CHAN_AUTO)

		self:PlayAnim(self.AnimList["finish"] or "sgreload_finish", 1,false,function(self) self:SetNetVar("shootgunReload",0) end,false,true) 
	end, false, true)
end

function SWEP:Reload(time)
	--print(self:GetNetVar("shootgunReload",0))
	if self.AnimStart_Draw > CurTime() - 0.5 then return end
	if not self:CanUse() then return end
	if self.reloadCoolDown > CurTime() then return end
	if self.Primary.Next > CurTime() then return end
	if self:GetNetVar("shootgunReload",0) > CurTime() then return end

	if self.drawBullet == false and SERVER then
		cock(self,1)
		self:PlayAnim(self.AnimList["cycle"] or "cycle", 1, false, nil, false, true)
		return
	end

	if not self:CanReload() then return end
	--self:GetWM():ManipulateBoneScale(47, vector_full)
	if SERVER then
		self:SetNetVar("shootgunReload",CurTime() + (self:Clip1() == 0 and 2.1 or 1.1))
		
		local anim = self:Clip1() == 0 and "start_empty" or "start"
		self:PlayAnim(self.AnimList[anim] or "sgreload_start",self:Clip1() == 0 and 2 or 1,false,function() 
			self:SetNetVar("shootgunReload",CurTime() + 1.1)
			if anim == "start_empty" then
				self:InsertAmmo(1) 
				cock(self,1)
			end
			reloadFunc(self)
		end,
		false,true)
	end
end

function SWEP:CanPrimaryAttack()
	return not (self:GetNetVar("shootgunReload",0) > CurTime())
end


SWEP.AnimsEvents = {
	["reload_start_empty"] = {
		[0.2] = function(self)
			self:EmitSound("weapons/darsu_eft/mp153/mr153_slider_up.wav")
			self:GetWM():ManipulateBoneScale(47, vector_full)
		end,
		[0.8] = function(self)
			self:EmitSound("weapons/darsu_eft/mp153/mr153_slider_down.wav")
		end,
		[0.9] = function(self)
			self:GetWM():ManipulateBoneScale(47, vector_origin)
		end,
	},
	["reload_loop"] = {
		[0.0] = function(self)
			self:EmitSound("weapons/darsu_eft/mp153/mr133_shell_in_mag2.wav")
			--
			self:GetWM():ManipulateBoneScale(47, vector_full)
		end,
		[0.8] = function(self)
			self:GetWM():ManipulateBoneScale(47, vector_origin)
		end,
	}
}

function SWEP:DrawPost()
	local wep = self:GetWeaponEntity()
	if CLIENT and IsValid(wep) then
		self.shooanim = LerpFT(0.4,self.shooanim or 0,((self:Clip1() > 0 or self.reload) and 0) or 1.8)
		wep:ManipulateBonePosition(48,Vector(0 ,0 ,-1*self.shooanim ),false)
		local mul = self:Clip1() > 0 and 1 or 0
		--wep:ManipulateBoneScale(12,Vector(mul,mul,mul),false)
	end
end
function SWEP:PostSetupDataTables()
	self:NetworkVar("Int",0,"GlockSkin")
	self:NetworkVar("String",1,"RandomBodygroups")
	if ( CLIENT ) then
		self:NetworkVarNotify( "GlockSkin", self.OnVarChanged2 )
		self:NetworkVarNotify( "RandomBodygroups", self.OnVarChanged )
	end
end

function SWEP:OnVarChanged( name, old, new )
	if !IsValid(self:GetWM()) then return end

	self:GetWM():SetBodyGroups(new)
end

function SWEP:OnVarChanged2( name, old, new )
	if !IsValid(self:GetWM()) then return end

	self:GetWM():SetSkin(new)
end

function SWEP:InitializePost()
	local Skin = math.random(0,2)
	if math.random(0,100) > 99 then
		Skin = 3
	end
	self:SetGlockSkin(Skin)
	self:SetRandomBodygroups(self.FakeBodyGroupsPresets[math.random(#self.FakeBodyGroupsPresets)] or "0000")
end

function SWEP:ModelCreated(model)
	model:ManipulateBoneScale(46, vector_origin)
	model:SetBodyGroups(self:GetRandomBodygroups() or "00000")
	model:SetSkin(self:GetGlockSkin())
end

--local common = ")/arccw_uc/common/"
--{s = {common .. "cloth_2.ogg", common .. "cloth_3.ogg", common .. "cloth_4.ogg", common .. "cloth_6.ogg", common .. "rattle.ogg"}, t = 0.05},

--local to head
SWEP.RHPos = Vector(1,-4.5,3)
SWEP.RHAng = Angle(0,-5,90)
--local to rh
SWEP.LHPos = Vector(15,-1,-3)
SWEP.LHAng = Angle(-110,-90,-90)


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
	Angle(-5,15,5),
	Angle(-6,15,14),
	Angle(-7,15,16),
	Angle(-8,16,15),
	Angle(-7,17,16),
	Angle(-10,15,-15),
	Angle(-2,22,-15),
	Angle(0,15,-32),
	Angle(0,14,-45),
	Angle(0,12,-55),
	Angle(0,10,-54),
	Angle(0,0,0)
}
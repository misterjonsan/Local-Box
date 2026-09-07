
if SERVER then AddCSLuaFile() end
SWEP.Base = "weapon_hg_slam2"
SWEP.PrintName = "Beartrap"
SWEP.Category = "ZCity Other"
SWEP.Instructions = "A heavy steel bear trap designed to immobilize targets on contact. Once triggered, it clamps down with strong force, restricting movement and dealing damage over time. Hold LMB to Deploy."
SWEP.Spawnable = true
SWEP.AdminOnly = true

SWEP.WorldModel = "models/stiffy360/beartrap.mdl"
SWEP.ViewModel = ""

if CLIENT then
    SWEP.WepSelectIcon = surface.GetTextureID( "vgui/wep_mann_hmcd_trap" )
    SWEP.IconOverride = "vgui/wep_mann_hmcd_trap"
    SWEP.BounceWeaponIcon = false
end

SWEP.offsetVec = Vector(5.7, -4, 0)
SWEP.offsetAng = Angle(0,45,180)

function SWEP:DrawWorldModel()
    self.model = IsValid(self.model) and self.model or ClientsideModel(self.WorldModel)
    local WorldModel = self.model
    local owner = self:GetOwner()

    if not IsValid(WorldModel) then return end

    WorldModel:SetNoDraw(true)
    WorldModel:SetModelScale(self.ModelScale or 1)
    WorldModel:SetModel(self:GetModel())
    if IsValid(owner) then
        local offsetVec = self.offsetVec
        local offsetAng = self.offsetAng
        local boneid = owner:LookupBone("ValveBiped.Bip01_R_Hand")
        if not boneid then return end
        local matrix = owner:GetBoneMatrix(boneid)
        if not matrix then return end
        local newPos, newAng = LocalToWorld(offsetVec, offsetAng, matrix:GetTranslation(), matrix:GetAngles())
        WorldModel:SetPos(newPos)
        WorldModel:SetAngles(newAng)
        WorldModel:SetupBones()
    else
        WorldModel:SetPos(self:GetPos())
        WorldModel:SetAngles(self:GetAngles())
    end

    WorldModel:SetSequence("closedidle")
    WorldModel:DrawModel()
end

function SWEP:PlaceSLAM(pos, ang, tr)
    ang:RotateAroundAxis(ang:Right(), -90)
    ang:RotateAroundAxis(ang:Up(), 0)

    local ent = ents.Create("beartrap")
    ent:SetAngles(ang)
    ent:SetPos(pos)
    ent:Spawn()

    constraint.Weld(ent, tr.Entity, 0, tr.PhysicsBone or 0, 9999, true, true)
    ent.owner = self:GetOwner()
    ent.poisoned2 = self.poisoned2

    self.Tries = self.Tries - 1
    self:SetNextPrimaryFire(CurTime()+0.5)
    self:SetHolding(0)
    if self.Tries <= 0 then
        self:Remove()
    end
end

function SWEP:Initialize()
    self:SetHoldType("slam")
    self.WorldModel = self.WorldModel
    self.Tries = 1
end

function SWEP:OnVarChanged(name, old, new)
    if not new then return end
    self.WorldModel = "models/stiffy360/beartrap.mdl"
    self.offsetVec = Vector(1.5, -12, -1)
    self.offsetAng = Angle(180, 80, 30)
end
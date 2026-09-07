local CLASS = player.RegClass("hidden")

local CONFIG = {
    Model = "models/player/hidden.mdl",
    Speed = 320,
    JumpPower = 250,
    PounceForce = 550,
    StaminaMax = 100,
    StaminaRegenTime = 7,
    PounceDelay = 1,
    PounceCost = 30,
    HangDrain = true,
    HangDrainSpeed = 2,
    AlphaBlend = 0.031,
}

local function initHiddenData(ply)
    ply.HiddenData = ply.HiddenData or {}
    local d = ply.HiddenData
    d.stamina = CONFIG.StaminaMax
    d.nextRegen = CurTime()
    d.pounceNext = 0
    d.hanging = 0
    d.hangNext = 0
end

function CLASS.Off(self)
    if CLIENT then return end
    self:SetNWString("PlayerRole", nil)
    self:DrawShadow(true)
    self:SetRenderMode(RENDERMODE_NORMAL)
    self:SetColor(Color(255,255,255,255))
    self:SetMaterial("")
end

function CLASS.On(self)
    if CLIENT then return end

    initHiddenData(self)

    self:SetModel(CONFIG.Model)
    self:SetPlayerColor(vector_origin)
    self:SetSubMaterial()
    self:DrawShadow(false)
    self:SetRenderMode(RENDERMODE_TRANSALPHA)
    self:SetColor(Color(255,255,255, math.floor(CONFIG.AlphaBlend * 255)))
    self:SetMaterial("")

    self:SetWalkSpeed(CONFIG.Speed)
    self:SetRunSpeed(CONFIG.Speed)
    self:SetJumpPower(CONFIG.JumpPower)
    self:SetMaxHealth(300)
    self:SetHealth(300)

    self:SetNWString("PlayerName", "")
    self.HiddenKillCount = 0
end

function CLASS.Guilt(self, Victim)
    return 0
end

local function doPounce(ply)
    local d = ply.HiddenData
    if not d then return end
    local org = ply.organism
    local cur = d.stamina
    if org and org.stamina then
        cur = org.stamina[1] or cur
    end
    if cur < CONFIG.PounceCost then return end
    if d.pounceNext > CurTime() then return end

    ply:SetPos(ply:GetPos() + Vector(0,0,1))
    local dir = ply:GetAimVector()
    ply:SetVelocity(dir * CONFIG.PounceForce + Vector(0,0,200))

    if org and org.stamina then
        org.stamina[1] = math.max(0, (org.stamina[1] or CONFIG.StaminaMax) - CONFIG.PounceCost)
    else
        d.stamina = math.max(0, d.stamina - CONFIG.PounceCost)
    end
    d.pounceNext = CurTime() + CONFIG.PounceDelay
    d.nextRegen = CurTime() + 0.8
end

hook.Add("KeyPress", "hidden_keypress", function(ply, key)
    if ply.PlayerClassName ~= "hidden" then return end
    local d = ply.HiddenData
    if not d then return end

    if key == IN_SPEED then
        if ply:IsOnGround() then
            doPounce(ply)
        elseif d.hanging == 1 then
            local tr = util.QuickTrace(ply:GetShootPos(), ply:GetAimVector() * 50, {ply, ply:GetActiveWeapon()})
            if not tr.HitWorld then
                d.hanging = 0
                ply:SetMoveType(MOVETYPE_WALK)
                doPounce(ply)
            end
        end
    elseif key == IN_JUMP then
        if d.hanging == 1 then
            d.hanging = 0
            ply:SetMoveType(MOVETYPE_WALK)
        end
    end
end)

hook.Add("Think", "hidden_stamina_think", function()
    for _, ply in ipairs(player.GetAll()) do
        if ply.PlayerClassName ~= "hidden" then continue end
        local d = ply.HiddenData
        if not d then continue end

        if d.hanging == 1 and CONFIG.HangDrain then
            if d.stamina <= 0 then
                d.hanging = 0
                if ply:GetMoveType() == MOVETYPE_NONE then
                    ply:SetMoveType(MOVETYPE_WALK)
                end
            else
                if d.hangNext < CurTime() then
                    local org = ply.organism
                    if org and org.stamina then
                        org.stamina[1] = math.max(0, (org.stamina[1] or CONFIG.StaminaMax) - CONFIG.HangDrainSpeed)
                    else
                        d.stamina = math.max(0, d.stamina - CONFIG.HangDrainSpeed)
                    end
                    d.hangNext = CurTime() + 3
                end
            end
        end

        if d.nextRegen < CurTime() and d.hanging == 0 then
            if d.stamina < CONFIG.StaminaMax then
                d.stamina = math.min(CONFIG.StaminaMax, d.stamina + (CONFIG.StaminaMax / CONFIG.StaminaRegenTime))
                d.nextRegen = CurTime() + 1
            end
        end
    end
end)

hook.Add("Move", "hidden_hang_check", function(ply, mv)
    if ply.PlayerClassName ~= "hidden" then return end
    local d = ply.HiddenData
    if not d then return end
    if not ply:KeyDown(IN_SPEED) then return end
    if d.hanging == 1 then return end
    local tr = util.QuickTrace(ply:GetShootPos(), ply:GetAimVector() * 35, {ply, ply:GetActiveWeapon()})
    if tr.HitWorld then
        local z = tr.HitNormal.z
        if (z < 0.3 and z > -0.3) or (z < -0.7) then
            d.hanging = 1
            ply:SetVelocity(-ply:GetVelocity())
            ply:SetMoveType(MOVETYPE_NONE)
        end
    end
end)

if SERVER then
    hg.__origFake = hg.__origFake or hg.Fake
    function hg.Fake(ply, a, b, c)
        if IsValid(ply) and ply:IsPlayer() and ply.PlayerClassName == "hidden" then return end
        return hg.__origFake(ply, a, b, c)
    end

    hook.Add("Think", "hidden_block_states", function()
        for _, ply in ipairs(player.GetAll()) do
            if ply.PlayerClassName ~= "hidden" then continue end
            local org = ply.organism
            if org then
                org.otrub = false
                if (org.incapacitated or org.dying) and ply:Alive() then
                    ply:Kill()
                end
                org.stun = 0
            end
            if IsValid(ply) then ply:RemoveAllDecals() end
            if IsValid(ply.FakeRagdoll) then ply.FakeRagdoll:RemoveAllDecals() end
            ply:SetNetVar("Accessories", "none")
        end
    end)

    if not _G.__hiddenPatchSprint then
        local PM = FindMetaTable("Player")
        if PM and not PM.__origIsSprinting then
            PM.__origIsSprinting = PM.IsSprinting
            function PM:IsSprinting()
                if self.PlayerClassName == "hidden" then return false end
                return PM.__origIsSprinting(self)
            end
        end
        _G.__hiddenPatchSprint = true
    end

    hook.Add("EntityTakeDamage", "hidden_melee_buff", function(victim, dmginfo)
        local attacker = dmginfo:GetAttacker()
        if not IsValid(attacker) or not attacker:IsPlayer() then return end
        if attacker.PlayerClassName ~= "hidden" then return end
        local wep = attacker:GetActiveWeapon()
        if IsValid(wep) and (wep.ismelee or wep.ismelee2) then
            dmginfo:ScaleDamage(2)
        end
    end)

    hook.Add("EntityTakeDamage", "hidden_pain_voice", function(victim, dmginfo)
        if not IsValid(victim) or not victim:IsPlayer() then return end
        if victim.PlayerClassName ~= "hidden" then return end
        victim.__nextPainVoice = victim.__nextPainVoice or 0
        if victim.__nextPainVoice > CurTime() then return end
        victim.__nextPainVoice = CurTime() + 5
        local idx = math.random(1, 6)
        victim:EmitSound("vocals_617/pain" .. idx .. ".wav", 70, 100, 0.9)
    end)
    hook.Add("EntityTakeDamage", "hidden_env_protection", function(victim, dmginfo)
        if not IsValid(victim) or not victim:IsPlayer() then return end
        if victim.PlayerClassName ~= "hidden" then return end
        local dt = dmginfo:GetDamageType()
        if bit.band(dt, DMG_FALL) ~= 0 or bit.band(dt, DMG_CRUSH) ~= 0 then
            dmginfo:SetDamage(0)
            return
        end
    end)
    hook.Add("PlayerNeckBroken", "hidden_neck_immunity", function(ply)
        if IsValid(ply) and ply:IsPlayer() and ply.PlayerClassName == "hidden" then return true end
    end)
end

if SERVER then
    hook.Add("PlayerDeath", "hidden_heal_on_kill", function(victim, inflictor, attacker)
        if not IsValid(attacker) or not attacker:IsPlayer() then return end
        if attacker.PlayerClassName ~= "hidden" then return end

        local wep = attacker:GetActiveWeapon()
        local is_melee = IsValid(wep) and wep.ismelee == true
        if not is_melee then return end

        attacker.HiddenKillCount = (attacker.HiddenKillCount or 0) + 1

        local org = attacker.organism
        attacker:SetHealth(math.min(attacker:GetMaxHealth(), attacker:Health() + 25))
        if org then
            org.wounds = org.wounds or {}
            if #org.wounds > 0 then
                table.sort(org.wounds, function(a, b) return a[1] > b[1] end)
                local biggest = org.wounds[1]
                if biggest and biggest[1] and biggest[1] > 0 then
                    biggest[1] = math.max(0, biggest[1] - 0.6)
                    if biggest[1] == 0 then table.remove(org.wounds, 1) end
                end
            end
            org.arterialwounds = org.arterialwounds or {}
            if #org.arterialwounds > 0 then
                table.remove(org.arterialwounds, 1)
            end
            attacker:SetNetVar("wounds", org.wounds)
            attacker:SetNetVar("arterialwounds", org.arterialwounds)
        end

        if attacker.HiddenKillCount >= 3 then
            attacker.HiddenKillCount = 0
            attacker:SetHealth(attacker:GetMaxHealth())
            if org then
                org.wounds = {}
                org.arterialwounds = {}
                attacker:SetNetVar("wounds", org.wounds)
                attacker:SetNetVar("arterialwounds", org.arterialwounds)
            end
        end
    end)
end

local matHeat = Material("sprites/heatwave")
function zb.PreDrawPlayer(ply, ent, draw)
    if ply.PlayerClassName == "hidden" then
        local vel = ply:GetVelocity():Length()
        local amount = math.Clamp(0.008 - vel / 15000, 0.0008, 0.008)
        render.UpdateRefractTexture()
        matHeat:SetFloat("$refractamount", amount)

        if ply ~= LocalPlayer() then
            render.MaterialOverride(matHeat)
        else
            render.MaterialOverride(nil)
        end
        ply:DrawShadow(false)
        ent:DrawShadow(false)
        ent:SetupBones()
        ent:DrawModel()
        DrawPlayerRagdoll(ent, ply)
        render.MaterialOverride(nil)

        return ply, ent, false
    end

    return ply, ent, true
end

hook.Add("EntityEmitSound", "hidden_ragdoll_silent", function(data)
    local ent = data.Entity
    if IsValid(ent) and ent:GetClass() == "prop_ragdoll" then
        local owner = ent:GetOwner()
        if IsValid(owner) and owner:IsPlayer() and owner.PlayerClassName == "hidden" then
            return false
        end
    end
end)

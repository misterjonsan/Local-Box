local MODE = MODE

util.AddNetworkString("hidden_start")
util.AddNetworkString("hidden_end")
util.AddNetworkString("hidden_voice")

local function eligiblePlayers()
    local t = {}
    for _, ply in ipairs(player.GetAll()) do
        if ply:Team() ~= TEAM_SPECTATOR then
            table.insert(t, ply)
        end
    end
    return t
end

function MODE:SelectHidden()
    local pool = eligiblePlayers()
    local chosen = table.Random(pool)
    self.HiddenPlayer = chosen
end

function MODE:Intermission()
    game.CleanUpMap()

    for _, ply in ipairs(player.GetAll()) do
        if ply:Team() ~= TEAM_SPECTATOR then
            ply:SetupTeam(0)
        end
        ply.isHidden = false
    end

    self.CTPoints = {}
    self.TPoints = {}
    table.CopyFromTo(zb.GetMapPoints("HMCD_TDM_CT"), self.CTPoints)
    table.CopyFromTo(zb.GetMapPoints("HMCD_TDM_T"), self.TPoints)

    self:SelectHidden()
    if IsValid(self.HiddenPlayer) then
        self.HiddenPlayer.isHidden = true
    end

    net.Start("hidden_start")
        net.WriteEntity(self.HiddenPlayer or NULL)
    net.Broadcast()
end

function MODE:GiveEquipment()
    for _, ply in ipairs(player.GetAll()) do
        if ply:Team() == TEAM_SPECTATOR then continue end
        if ply.isHidden then
            if not ply:HasWeapon("weapon_hands_sh") then ply:Give("weapon_hands_sh") end
            if not ply:HasWeapon("weapon_kabar") then ply:Give("weapon_kabar") end
        else
            if not ply:HasWeapon("weapon_hands_sh") then ply:Give("weapon_hands_sh") end
        end
    end
end

function MODE:RoundStart()
    for _, ply in ipairs(player.GetAll()) do
        if ply:Team() == TEAM_SPECTATOR then continue end
        ply:Spawn()
        if ply.isHidden then
            if self.TPoints and #self.TPoints > 0 then
                local pt = table.remove(self.TPoints) or self.TPoints[1]
                if pt and pt.pos then ply:SetPos(pt.pos) end
            else
                ply:GetRandomSpawn()
            end
        else
            if self.CTPoints and #self.CTPoints > 0 then
                local pt = table.remove(self.CTPoints) or self.CTPoints[1]
                if pt and pt.pos then ply:SetPos(pt.pos) end
            else
                ply:GetRandomSpawn()
            end
        end

        ply:SetSuppressPickupNotices(true)
        ply.noSound = true

        if ply.isHidden then
            ply:SetTeam(1)
            ply:SetPlayerClass("hidden")
            local hands = ply:Give("weapon_hands_sh")
            local kabar = ply:Give("weapon_kabar")
            ply:Give("weapon_hg_pipebomb_tpik")
            if IsValid(hands) then ply:SetActiveWeapon(hands) end
            timer.Simple(0, function()
                if IsValid(ply) and ply:IsPlayer() and ply.isHidden then
                    if not ply:HasWeapon("weapon_hands_sh") then ply:Give("weapon_hands_sh") end
                    if not ply:HasWeapon("weapon_kabar") then ply:Give("weapon_kabar") end
                    if not ply:HasWeapon("weapon_hg_pipebomb_tpik") then ply:Give("weapon_hg_pipebomb_tpik") end
                    if IsValid(ply.FakeRagdoll) then
                        if hg and hg.FakeUp then hg.FakeUp(ply) end
                        ply.FakeRagdoll = nil
                    end
                    if ply.GetNWEntity then
                        ply:SetNWEntity("FakeRagdoll", NULL)
                        ply:SetNWEntity("RagdollDeath", NULL)
                    end
                end
            end)
            zb.GGiveRole = zb.GGiveRole or zb.GiveRole
            zb.GGiveRole(ply, "Hidden", Color(255, 30, 120))
        else
            ply:SetTeam(0)
            ply:SetPlayerClass("nationalguard")
            local function safeGive(cls)
                if weapons.GetStored(cls) then return ply:Give(cls) end
            end
            local pools = {
                {primary = "weapon_m4a1", sidearm = "weapon_glock17", attachments = {"holo14"}},
                {primary = "weapon_mp5", sidearm = "weapon_px4beretta", attachments = {"holo14"}},
                {primary = "weapon_remington870", sidearm = "weapon_m9beretta", attachments = {}},
                {primary = "weapon_ar15", sidearm = "weapon_px4beretta", attachments = {"holo14"}},
            }
            local choice = pools[math.random(#pools)]
            local gun = safeGive(choice.primary) or safeGive("weapon_mp5") or safeGive("weapon_m4a1")
            if IsValid(gun) then
                ply:GiveAmmo(gun:GetMaxClip1() * 3, gun:GetPrimaryAmmoType(), true)
                if hg and hg.AddAttachmentForce and choice.attachments and #choice.attachments > 0 then
                    hg.AddAttachmentForce(ply, gun, choice.attachments)
                end
            end
            local pistol = safeGive(choice.sidearm) or safeGive("weapon_glock17")
            if IsValid(pistol) then
                ply:GiveAmmo(pistol:GetMaxClip1() * 2, pistol:GetPrimaryAmmoType(), true)
            end
            ply:Give("hg_flashlight")
            ply:Give("weapon_medkit_sh")
            ply:Give("weapon_bandage_sh")
            local inv = ply:GetNetVar("Inventory") or {}
            inv["Weapons"] = inv["Weapons"] or {}
            inv["Weapons"]["hg_sling"] = true
            ply:SetNetVar("Inventory", inv)
            zb.GiveRole(ply, "National Guard", Color(55, 85, 0))
        end

        if not ply.isHidden then
            local hands = ply:Give("weapon_hands_sh")
            ply:SetActiveWeapon(hands)
        end
        ply:SetSuppressPickupNotices(false)
    end
end

hook.Add("PlayerSpawn", "hidden_reclear_fake", function(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    if ply.PlayerClassName ~= "hidden" then return end
    timer.Simple(0, function()
        if not IsValid(ply) then return end
        if IsValid(ply.FakeRagdoll) then
            if hg and hg.FakeUp then hg.FakeUp(ply) end
            ply.FakeRagdoll = nil
        end
        ply:SetNWEntity("FakeRagdoll", NULL)
        ply:SetNWEntity("RagdollDeath", NULL)
    end)
end)

hook.Add("PlayerCanPickupWeapon", "hidden_block_pickups", function(ply, wep)
    if not IsValid(ply) or not IsValid(wep) then return end
    if ply.PlayerClassName == "hidden" then
        local cls = wep:GetClass()
        if cls == "weapon_kabar" or cls == "weapon_hands_sh" or cls == "weapon_hg_pipebomb_tpik" then return true end
        return false
    end
end)

local HiddenVoices = {
    behindyou = {
        "vocals_617/behindyou1.wav",
        "vocals_617/behindyou2.wav",
    },
    imhere = {
        "vocals_617/imhere1.wav","vocals_617/imhere2.wav","vocals_617/imhere3.wav","vocals_617/imhere4.wav","vocals_617/imhere5.wav",
    },
    iseeyou = {
        "vocals_617/iseeyou1.wav","vocals_617/iseeyou2.wav","vocals_617/iseeyou3.wav","vocals_617/iseeyou4.wav",
    },
    lookup = {
        "vocals_617/lookup1.wav","vocals_617/lookup2.wav","vocals_617/lookup3.wav",
    },
    overhere = {
        "vocals_617/overhere1.wav","vocals_617/overhere2.wav","vocals_617/overhere3.wav",
    },
    -- pain is reserved for automatic damage reactions
    freshmeat = {
        "vocals_617/taunt_freshmeat1.wav","vocals_617/taunt_freshmeat2.wav","vocals_617/taunt_freshmeat3.wav",
    },
    imcoming = {
        "vocals_617/taunt_imcoming1.wav","vocals_617/taunt_imcoming2.wav","vocals_617/taunt_imcoming3.wav",
    },
    youarenext = {
        "vocals_617/taunt_youarenext1.wav","vocals_617/taunt_youarenext2.wav",
    },
    turnaround = {
        "vocals_617/turnaround1.wav","vocals_617/turnaround2.wav",
    }
}

net.Receive("hidden_voice", function(_, ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    if ply.PlayerClassName ~= "hidden" then return end
    local category = net.ReadString() or "random"
    local index = net.ReadUInt(8) or 0

    local pool = {}
    if category == "random" then
        for key, list in pairs(HiddenVoices) do
            if key ~= "pain" and key ~= "powerstab" then
                for _, path in ipairs(list) do pool[#pool + 1] = path end
            end
        end
    else
        pool = HiddenVoices[category] or {}
    end

    if #pool == 0 then return end
    local path = index > 0 and pool[math.Clamp(index, 1, #pool)] or pool[math.random(#pool)]
    ply:EmitSound(path, 75, 100, 0.9)
end)

function MODE:CheckAlivePlayers()
    local AlivePlyTbl = {
        [1] = {}, -- hidden
        [0] = {}, -- humans
    }
    for _, ply in ipairs(player.GetAll()) do
        if not ply:Alive() then continue end
        if ply.organism and (ply.organism.incapacitated or ply.organism.dying) then continue end
        if ply.isHidden then
            table.insert(AlivePlyTbl[1], ply)
        else
            table.insert(AlivePlyTbl[0], ply)
        end
    end
    return AlivePlyTbl
end

function MODE:ShouldRoundEnd()
    local alive = self:CheckAlivePlayers()
    local endround, _ = zb:CheckWinner(alive)
    return endround or false
end

function MODE:EndRound()
    local alive = self:CheckAlivePlayers()
    local result = "iris" -- default: humans win
    if #alive[1] > 0 and #alive[0] == 0 then
        result = "hidden"
    elseif #alive[1] == 0 then
        result = "iris"
    end

    for _, ply in ipairs(player.GetAll()) do
        ply.isHidden = false
    end
    net.Start("hidden_end")
        net.WriteString(result)
    net.Broadcast()
end

function MODE:CanLaunch()
    return true
end

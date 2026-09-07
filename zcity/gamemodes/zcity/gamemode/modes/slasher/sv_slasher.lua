MODE.name = "slasher"
MODE.PrintName = "Slasher"

MODE.ForBigMaps = false
MODE.ROUND_TIME = 600

MODE.LootSpawn = true
MODE.Chance = 0

local SLASHER_GUNS = {
    ["weapon_mp-80"] = true,
    ["weapon_makarov"] = true,
    ["weapon_hk_usp"] = true,
    ["weapon_glock17"] = true,
    ["weapon_cz75"] = true,
    ["weapon_px4beretta"] = true,
    ["weapon_m9beretta"] = true,
    ["weapon_browninghp"] = true,
    ["weapon_fn45"] = true,
    ["weapon_pm9"] = true,
    ["weapon_tec9"] = true,
    ["weapon_revolver2"] = true,
    ["weapon_deagle"] = true,
    ["weapon_colt9mm"] = true,
    ["weapon_doublebarrel_short"] = true,
    ["weapon_doublebarrel"] = true,
    ["weapon_remington870"] = true,
    ["weapon_glock18c"] = true,
    ["weapon_skorpion"] = true,
    ["weapon_mac11"] = true,
    ["weapon_uzi"] = true,
    ["weapon_tmp"] = true,
    ["weapon_kar98"] = true,
    ["weapon_ar_pistol"] = true,
    ["weapon_draco"] = true,
    ["weapon_mp5"] = true,
    ["weapon_mp7"] = true,
    ["weapon_sks"] = true,
    ["weapon_ar15"] = true,
    ["weapon_vpo136"] = true,
    ["weapon_sr25"] = true,
    ["weapon_fury13"] = true,
    ["weapon_flintlock"] = true,
}

function MODE:GetLootTable()
    if self._SlasherLootTable then return self._SlasherLootTable end
    local hmcd = zb and zb.modes and zb.modes["hmcd"]
    local source = hmcd and (hmcd.LootTableStandard or hmcd.LootTable)
    if not source then return nil end
    local out = {}
    for i = 1, #source do
        local tier = source[i]
        local weight = tier[1]
        local items = tier[2]
        local filtered = {}
        for j = 1, #items do
            local w = items[j][1]
            local cls = items[j][2]
            if not (isstring(cls) and SLASHER_GUNS[cls]) then
                filtered[#filtered + 1] = { w, cls }
            end
        end
        if #filtered > 0 then
            out[#out + 1] = { weight, filtered }
        end
    end
    self._SlasherLootTable = out
    return out
end

local function shuffle(tbl)
    local len = #tbl
    for i = len, 2, -1 do
      local j = math.random(i)
      tbl[i], tbl[j] = tbl[j], tbl[i]
    end
end

function MODE:AssignTeams()
    local players = player.GetAll()
    local numPlayers = #players
    shuffle(players)
    if numPlayers == 0 then return end
    if IsValid(players[1]) then players[1]:SetTeam(2) end
    local traitorPicked = false
    for i = 2, numPlayers do
        local ply = players[i]
        if not IsValid(ply) then continue end
        ply:SetTeam(1)
        if not traitorPicked then
            self.Traitor = ply
            traitorPicked = true
        end
    end
end

util.AddNetworkString("slasher_start")
function MODE:Intermission()
    game.CleanUpMap()

    self:AssignTeams()
    hg.UpdateRoundTime(self.ROUND_TIME)

    for _, ply in ipairs(player.GetAll()) do
        if ply:Team() == TEAM_SPECTATOR or ply:Team() == 0 or ply:Team() == 2 then ply:KillSilent() continue end
        ply:SetupTeam(ply:Team())
    end

    net.Start("slasher_start")
    net.Broadcast()
end

function MODE:CheckAlivePlayers()
    local swatPlayers = {}
    local bystanders = {}
    local killers = {}

    for _, ply in ipairs(team.GetPlayers(0)) do
        if ply:Alive() and not ply:GetNetVar("handcuffed", false) then
            table.insert(swatPlayers, ply)
        end
    end

    for _, ply in ipairs(team.GetPlayers(1)) do
        if ply:Alive() and not ply:GetNetVar("handcuffed", false) then
            table.insert(bystanders, ply)
        end
    end

    for _, ply in ipairs(team.GetPlayers(2)) do
        if ply:Alive() and not ply:GetNetVar("handcuffed", false) then
            table.insert(killers, ply)
        end
    end

    return {swatPlayers, bystanders, killers}
end

function MODE:ShouldRoundEnd()
    if zb.ROUND_START + 61 > CurTime() then return false end
    local alive = self:CheckAlivePlayers()
    if CurTime() >= (zb.ROUND_START + 300) and table.Count(alive[3]) == 0 then
        return true
    end
    if table.Count(alive[2]) == 0 and table.Count(alive[3]) > 0 then
        return true
    end
    local endround = zb:CheckWinner(alive)
    return endround
end

function MODE:RoundStart()
end

local function giveWithReserve(ply, class)
    local wep = ply:Give(class)
    if IsValid(wep) and wep.GetMaxClip1 and wep.GetPrimaryAmmoType and wep:GetMaxClip1() > 0 then
        ply:GiveAmmo(wep:GetMaxClip1() * 2, wep:GetPrimaryAmmoType(), true)
    end
    return wep
end
-- SWAT equipment tables (copied from Crisis Response)
local tblweps = {
    [0] = {
        {"weapon_m4a1", {"holo15","grip3","laser4"}},
        {"weapon_hk416", {"holo15","grip3","laser4"}},
        {"weapon_p90", {}},
        {"weapon_mp7", {"holo14"}},
        {"weapon_m4a1", {"optic2","grip3","supressor7"}}
    }
}

local tblotheritems = {
    [0] = {
        "weapon_medkit_sh",
        "weapon_tourniquet",
        "weapon_walkie_talkie",
        "weapon_melee",
        "weapon_handcuffs",
        "weapon_hg_flashbang_tpik"
    }
}

local tblarmors = {
    [0] = {
        {"ent_armor_vest8","ent_armor_helmet6"}
    }
}

function MODE:CanLaunch()
    return true
end

function MODE:GiveEquipment()
    timer.Simple(0.5,function()
        self.SWATQueue = {}
        self.SWATQueueSet = {}

        for _, ply in ipairs(player.GetAll()) do
            if ply:Team() == TEAM_SPECTATOR then continue end

            if ply:Team() == 2 then
                timer.Create("KillerSpawn"..ply:EntIndex(), 60, 1, function()
                    if not IsValid(ply) then return end
                    ply:Spawn()
                    ply:SetSuppressPickupNotices(true)
                    ply.noSound = true

                    ply:SetupTeam(ply:Team())

                    local identity = {
                        Gender = 1,
                        Name = "Ghostface",
                        Model = "models/distac/player/ghostface.mdl",
                        Color = Color(255,0,0),
                        ClothesStyle = false,
                        Attachmets = {}
                    }

                    ply:SetPlayerClass()

                    ply.PlayerClassName = nil
                    if ApplyForceAppearance then
                        local attempts = 6
                        for i = 0, attempts - 1 do
                            timer.Simple(0.2 * i, function()
                                if IsValid(ply) then
                                    ApplyForceAppearance(ply, identity)
                                    ply.Appearance = table.Copy(identity)
                                    ply.CurAppearance = table.Copy(identity)
                                end
                            end)
                        end
                    end

                    zb.GiveRole(ply, "Killer", Color(190,0,0))

                    local inv = ply:GetNetVar("Inventory") or {}
                    inv["Weapons"] = inv["Weapons"] or {}
                    inv["Weapons"]["hg_sling"] = true
                    inv["Weapons"]["hg_melee_belt"] = true
                    ply:SetNetVar("Inventory", inv)

                    local derr = ply:Give("weapon_derringer")
                    if not IsValid(derr) then
                    end
                    local buck = ply:Give("weapon_buck200knife")
                    if not IsValid(buck) then
                        ply:Give("weapon_sogknife")
                    end
                    ply:Give("weapon_hg_chainsaw")
                    ply:Give("weapon_adrenaline")
                    ply:Give("weapon_bandage_sh")

                    ply:Give("weapon_hands_sh")

                    timer.Simple(0.2, function()
                        if IsValid(ply) then
                            ply:SelectWeapon("weapon_hg_chainsaw")
                        end
                    end)

                    ply:SetSuppressPickupNotices(false)
                    ply.noSound = false

                    if self.KillerSound and self.KillerSound.Stop then
                        self.KillerSound:Stop()
                        self.KillerSound = nil
                    end
                    if CreateSound then
                        self.KillerSound = CreateSound(ply, "mindmaze.mp3")
                        if self.KillerSound then
                            self.KillerSound:PlayEx(0.9, 100)
                        end
                    end
                end)
            else
                ply:SetSuppressPickupNotices(true)
                ply.noSound = true

                ply:SetPlayerClass()

                if self.Traitor == ply then
                    zb.GiveRole(ply, "Traitor", Color(120,0,120))
                else
                    zb.GiveRole(ply, "Bystander", Color(255,255,255))
                end

                ply:Give("weapon_hands_sh")

                ply:SetSuppressPickupNotices(false)
                ply.noSound = false
            end

            timer.Simple(0.5,function()
                if IsValid(ply) then ply.noSound = false end
            end)

            ply:SetSuppressPickupNotices(false)
        end

        timer.Create("SWATArrival", 300, 1, function()
            for _, bry in ipairs(self.SWATQueue or {}) do
                if IsValid(bry) then
                    self:SpawnSWAT(bry)
                end
            end
            self.SWATQueue = {}
            self.SWATQueueSet = {}
            timer.Create("SWATSpawn", 91, 1, function()
                local swats = team.GetPlayers(0)
                if #swats > 0 then
                    local ramPlayer = swats[math.random(#swats)]
                    if IsValid(ramPlayer) then
                        ramPlayer:Give("weapon_ram")
                    end
                end
            end)
        end)
    end)
end

function MODE:SpawnSWAT(ply)
    if not IsValid(ply) then return end
    ply:SetTeam(0)
    ply:Spawn()
    ply:SetSuppressPickupNotices(true)
    ply.noSound = true

    ply:SetupTeam(ply:Team())
    ply:SetPlayerClass("swat")

    local inv = ply:GetNetVar("Inventory") or {}
    inv["Weapons"] = inv["Weapons"] or {}
    inv["Weapons"]["hg_sling"] = true
    ply:SetNetVar("Inventory",inv)

    hg.AddArmor(ply, tblarmors[0][math.random(#tblarmors[0])])
    zb.GiveRole(ply, "SWAT", Color(0,0,190))

    local wep = tblweps[0][math.random(#tblweps[0])]
    local gun = ply:Give(wep[1])
    if IsValid(gun) and gun.GetMaxClip1 then
        if hg.AddAttachmentForce then hg.AddAttachmentForce(ply,gun,wep[2]) end
        ply:GiveAmmo(gun:GetMaxClip1() * 3,gun:GetPrimaryAmmoType(),true)
    end

    local pistol = ply:Give("weapon_glock17")
    if IsValid(pistol) and pistol.GetMaxClip1 then
        ply:GiveAmmo(pistol:GetMaxClip1() * 3,pistol:GetPrimaryAmmoType(),true)
    end

    for _, item in ipairs(tblotheritems[0]) do
        ply:Give(item)
    end

    ply:Give("weapon_hands_sh")
    ply:SetSuppressPickupNotices(false)
    ply.noSound = false
end

function MODE:RoundThink()
    self._adrenalineCount = self._adrenalineCount or {}
    self._adrenalineNext = self._adrenalineNext or {}
    local killers = team.GetPlayers(2)
    local killer = killers[1]
    if IsValid(killer) and killer:Alive() then
        for _, ply in ipairs(team.GetPlayers(1)) do
            if not IsValid(ply) or not ply:Alive() then continue end
            local org = ply.organism
            if not org then continue end
            local nxt = self._adrenalineNext[ply] or 0
            local cnt = self._adrenalineCount[ply] or 0
            if cnt >= 2 or nxt > CurTime() then continue end
            local tr = util.TraceLine({ start = ply:EyePos(), endpos = killer:EyePos(), filter = { ply, killer }, mask = MASK_VISIBLE_AND_NPCS })
            if not tr.Hit then
                org.adrenalineAdd = math.min((org.adrenalineAdd or 0) + 1, 2)
                self._adrenalineCount[ply] = cnt + 1
                self._adrenalineNext[ply] = CurTime() + 35
            end
        end
    end
end

function MODE:GetTeamSpawn()
    return {zb:GetRandomSpawn()}, {zb:GetRandomSpawn()}
end

function MODE:CanSpawn()
end

util.AddNetworkString("slasher_roundend")
util.AddNetworkString("slasher_killer_dead")
function MODE:EndRound()
    for _, ply in player.Iterator() do
        if timer.Exists("SWATSpawn"..ply:EntIndex()) then
            timer.Remove("SWATSpawn"..ply:EntIndex())
        end
        if timer.Exists("KillerSpawn"..ply:EntIndex()) then
            timer.Remove("KillerSpawn"..ply:EntIndex())
        end
    end
    if timer.Exists("SWATSpawn") then
        timer.Remove("SWATSpawn")
    end
    if timer.Exists("SWATArrival") then
        timer.Remove("SWATArrival")
    end
    self.SWATQueue = {}
    self.SWATQueueSet = {}

    if self.KillerSound and self.KillerSound.Stop then
        self.KillerSound:Stop()
        self.KillerSound = nil
    end

    local aliveTeams = self:CheckAlivePlayers()
    local endround, winner = zb:CheckWinner(aliveTeams)
    if CurTime() >= (zb.ROUND_START + 300) and table.Count(aliveTeams[3]) == 0 then
        endround = true
        winner = 0
    end
    if table.Count(aliveTeams[2]) == 0 and table.Count(aliveTeams[3]) > 0 then
        endround = true
        winner = 2
    end

    timer.Simple(2,function()
        net.Start("slasher_roundend")
            net.WriteBool(winner)
        net.Broadcast()
    end)

    for _, ply in player.Iterator() do
        if ply:Team() == winner then
            ply:GiveExp(math.random(15,30))
            ply:GiveSkill(math.Rand(0.1,0.15))
        else
            ply:GiveSkill(-math.Rand(0.05,0.1))
        end
    end
end

function MODE:PlayerDeath(_, ply)
    if not IsValid(ply) then return end
    if ply:Team() == 2 then
        if self.KillerSound and self.KillerSound.Stop then
            self.KillerSound:Stop()
            self.KillerSound = nil
        end
        net.Start("slasher_killer_dead")
        net.Broadcast()
        return
    end
    if ply:Team() ~= 1 then return end
    if CurTime() > (zb.ROUND_START + 300) then return end
    if self.SWATQueueSet and self.SWATQueueSet[ply] then return end
    self.SWATQueue = self.SWATQueue or {}
    self.SWATQueueSet = self.SWATQueueSet or {}
    table.insert(self.SWATQueue, ply)
    self.SWATQueueSet[ply] = true
    ply:SetTeam(0)
end

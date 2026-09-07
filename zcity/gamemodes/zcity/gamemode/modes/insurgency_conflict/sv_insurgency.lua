local MODE = MODE

MODE.name = "insurgency_conflict"
MODE.PrintName = "Insurgency Conflict (WIP DONT PLAY)"
MODE.Description = "Asymmetric government vs insurgents with attrition and commander oversight."

MODE.start_time = 20
MODE.ROUND_TIME = 1200

MODE.AttritionDelay = 120
MODE.BudgetPerKill = 1
MODE.OverrideSpawn = true

function MODE:CanLaunch()
    local pointsA = zb.GetMapPoints("HMCD_TDM_T")
    local pointsB = zb.GetMapPoints("HMCD_TDM_CT")
    local humans = #player.GetHumans()
    return (#pointsA > 0) and (#pointsB > 0) and (humans >= 8)
end

function MODE:OverrideBalance()
    return true
end

util.AddNetworkString("ic_update_life")
util.AddNetworkString("ic_attrition_active")
util.AddNetworkString("ic_update_budget")
util.AddNetworkString("ic_open_buymenu")
util.AddNetworkString("ic_buymenu_data")
util.AddNetworkString("ic_buy_perk")
util.AddNetworkString("ic_buy_equipment")
util.AddNetworkString("ic_respawn")
util.AddNetworkString("ic_roundtime")
util.AddNetworkString("ic_perkdefs")
util.AddNetworkString("ic_airstrike_begin")
util.AddNetworkString("ic_airstrike_execute")
util.AddNetworkString("ic_airstrike_cancel")
util.AddNetworkString("ic_uav_begin")
util.AddNetworkString("ic_uav_execute")
util.AddNetworkString("ic_uav_cancel")
util.AddNetworkString("ic_uav_marks")
util.AddNetworkString("ic_music_start")
util.AddNetworkString("ic_music_stop")
util.AddNetworkString("ic_round_end")
util.AddNetworkString("ic_clear_decals")

function MODE:Intermission()
    game.CleanUpMap()

    self.saved = self.saved or {}
    self.saved.life = {[0] = 40, [1] = 40}
    self.saved.attrition_active = false
    self.saved.commanders = {[0] = nil, [1] = nil}
    self.saved.forcedCommanders = self.saved.forcedCommanders or {[0] = nil, [1] = nil}
    self.saved.budget = {[0] = 0, [1] = 0}
    self.saved.equipment = {
        [0] = {secondary = "weapon_glock17", melee = "weapon_buck200knife", primary = nil, ammo = {}},
        [1] = {secondary = "weapon_hk_usp", melee = "weapon_bayonet", primary = nil, ammo = {}}
    }
    self.PerkDefs = {
        {id = "airstrike", name = "Call Airstrike", cost = 12500},
        {id = "uav", name = "Call UAV", cost = 4500},
        {id = "troop", name = "Call Troop", cost = 6500}
    }

    for _, ply in ipairs(player.GetAll()) do
        ply:SetNWBool("IC_IsCommander", false)
        ply:SetNWInt("IC_CommanderTeam", -1)
    end

    local active = {}
    for _, ply in ipairs(player.GetAll()) do
        if ply:Team() == TEAM_SPECTATOR then continue end
        table.insert(active, ply)
    end

    local cmd0, cmd1
    if IsValid(self.saved.commanders[0]) then cmd0 = self.saved.commanders[0] end
    if IsValid(self.saved.commanders[1]) then cmd1 = self.saved.commanders[1] end
    local f0 = self.saved.forcedCommanders[0]
    local f1 = self.saved.forcedCommanders[1]
    if not IsValid(cmd0) and f0 then
        for _, p in ipairs(player.GetAll()) do
            if p:SteamID() == f0 then cmd0 = p break end
        end
        if IsValid(cmd0) then table.RemoveByValue(active, cmd0) end
    end
    if not IsValid(cmd1) and f1 then
        for _, p in ipairs(player.GetAll()) do
            if p:SteamID() == f1 then cmd1 = p break end
        end
        if IsValid(cmd1) then table.RemoveByValue(active, cmd1) end
    end
    if not IsValid(cmd0) and #active >= 1 then
        cmd0 = active[math.random(#active)]
        table.RemoveByValue(active, cmd0)
    end
    if not IsValid(cmd1) and #active >= 1 then
        cmd1 = active[math.random(#active)]
        table.RemoveByValue(active, cmd1)
    end
    self.saved.commanders[0] = cmd0
    self.saved.commanders[1] = cmd1

    if IsValid(cmd0) then
        cmd0:SetTeam(0)
        cmd0:SetNWInt("IC_CommanderTeam", 0)
        cmd0:SetNWBool("IC_IsCommander", true)
        cmd0.viewmode = 3
        if cmd0:Alive() then cmd0:KillSilent() end
        cmd0:Spectate(OBS_MODE_ROAMING)
        zb.GiveRole(cmd0, "Insurgent Commander", Color(190,40,40))
    end
    if IsValid(cmd1) then
        cmd1:SetTeam(1)
        cmd1:SetNWInt("IC_CommanderTeam", 1)
        cmd1:SetNWBool("IC_IsCommander", true)
        cmd1.viewmode = 3
        if cmd1:Alive() then cmd1:KillSilent() end
        cmd1:Spectate(OBS_MODE_ROAMING)
        zb.GiveRole(cmd1, "Coalition Commander", Color(0,173,43))
    end

    for _, ply in ipairs(active) do
        local choice = zb:BalancedChoice(0, 1)
        ply:SetTeam(choice)
        ply:SetupTeam(choice)
        local roleName = (choice == 0 and "Insurgent") or "Coalition"
        local roleColor = (choice == 0 and Color(0,173,43)) or Color(30,110,200)
        zb.GiveRole(ply, roleName, roleColor)
    end

    net.Start("ic_update_life")
        net.WriteInt(self.saved.life[0], 16)
        net.WriteInt(self.saved.life[1], 16)
    net.Broadcast()

    net.Start("ic_update_budget")
        net.WriteInt(self.saved.budget[0], 16)
        net.WriteInt(self.saved.budget[1], 16)
    net.Broadcast()

    net.Start("ic_perkdefs")
        net.WriteTable(self.PerkDefs)
    net.Broadcast()
end

function MODE:RoundStart()
    timer.Remove("ic_attrition_timer")
    timer.Remove("ic_budget_tick")
    timer.Create("ic_attrition_timer", self.AttritionDelay, 1, function()
        if not self.saved then return end
        self.saved.attrition_active = true
        net.Start("ic_attrition_active")
        net.Broadcast()
    end)
    net.Start("ic_roundtime")
        net.WriteFloat((zb.ROUND_START or CurTime()) + (self.ROUND_TIME or 0))
    net.Broadcast()
    net.Start("ic_music_start")
    net.Broadcast()
    timer.Create("ic_budget_tick", 60, 0, function()
        if not self.saved or not self.saved.budget then return end
        self.saved.budget[0] = (self.saved.budget[0] or 0) + 500
        self.saved.budget[1] = (self.saved.budget[1] or 0) + 500
        net.Start("ic_update_budget")
            net.WriteInt(self.saved.budget[0] or 0, 16)
            net.WriteInt(self.saved.budget[1] or 0, 16)
        net.Broadcast()
    end)

    -- cleanup loop every 1 minute 15 seconds for corpses
    if timer.Exists("ic_cleanup_loop") then timer.Remove("ic_cleanup_loop") end
    timer.Create("ic_cleanup_loop", 75, 0, function()
        -- corpses and dropped guns fade out, then remove
        local toFade = {}
        for _, ent in ipairs(ents.GetAll()) do
            if not IsValid(ent) then continue end
            local cls = ent:GetClass()
            if cls == "prop_ragdoll" then
                -- Only cleanup corpses (dead player ragdolls), not alive ragdolls
                local isCorpse = ent:GetNWBool("IsCorpse", false) or ent:GetNWEntity("RagdollPlayer", NULL) ~= NULL
                if isCorpse then
                    toFade[#toFade + 1] = ent
                end
            elseif ent:IsWeapon() then
                local owner = ent:GetOwner()
                if not IsValid(owner) then
                    toFade[#toFade + 1] = ent
                end
            end
        end
        for _, e in ipairs(toFade) do
            local id = "IC_Fade_" .. e:EntIndex()
            if timer.Exists(id) then continue end
            local steps = 20
            local dur = 2.0
            local alpha = 255
            e:SetRenderMode(RENDERMODE_TRANSALPHA)
            timer.Create(id, dur / steps, steps, function()
                if not IsValid(e) then timer.Remove(id) return end
                alpha = math.max(0, alpha - math.floor(255 / steps))
                local c = e:GetColor()
                e:SetColor(Color(c.r, c.g, c.b, alpha))
                if alpha <= 0 then
                    -- Ensure complete removal
                    if IsValid(e) then 
                        e:Remove() 
                    end
                    timer.Remove(id)
                end
            end)
        end
        -- clear blood decals on clients
        net.Start("ic_clear_decals")
        net.Broadcast()
    end)
end

function MODE:GetTeamSpawn()
    local tSpawns = zb.TranslatePointsToVectors(zb.GetMapPoints("HMCD_TDM_T"))
    local ctSpawns = zb.TranslatePointsToVectors(zb.GetMapPoints("HMCD_TDM_CT"))
    return tSpawns, ctSpawns
end

function MODE:CheckAlivePlayers()
    return zb:CheckAliveTeams(true)
end

function MODE:ShouldRoundEnd()
    if (zb.ROUND_START + 5) > CurTime() then return false end
    if not self.saved or not self.saved.life then return false end
    local l0 = self.saved.life[0] or 0
    local l1 = self.saved.life[1] or 0
    if l0 <= 0 or l1 <= 0 then return true end
end

function MODE:PlayerDeath(_, ply, inflictor, attacker)
    if not self.saved then return end
    if not IsValid(ply) then return end

    -- Mark the player's ragdoll as a corpse for proper cleanup
    timer.Simple(0.1, function()
        if not IsValid(ply) then return end
        local ragdoll = ply:GetRagdollEntity()
        if IsValid(ragdoll) then
            ragdoll:SetNWBool("IsCorpse", true)
            ragdoll:SetNWEntity("RagdollPlayer", ply)
        end
    end)

    if self.saved.budget then
        local vicTeam = ply:Team()
        if vicTeam ~= TEAM_SPECTATOR then
            local other = (vicTeam == 0) and 1 or 0
            self.saved.budget[vicTeam] = math.max((self.saved.budget[vicTeam] or 0) + 1000, 0)
            self.saved.budget[other] = math.max((self.saved.budget[other] or 0) + 2500, 0)
            net.Start("ic_update_budget")
                net.WriteInt(self.saved.budget[0] or 0, 16)
                net.WriteInt(self.saved.budget[1] or 0, 16)
            net.Broadcast()
        end
    end

    if ply:Team() ~= TEAM_SPECTATOR and self.saved.attrition_active and self.saved.life then
        local teamIndex = ply:Team()
        local lifeTbl = self.saved.life
        lifeTbl[teamIndex] = math.max((lifeTbl[teamIndex] or 0) - 1, 0)

        net.Start("ic_update_life")
            net.WriteInt(lifeTbl[0] or 0, 16)
            net.WriteInt(lifeTbl[1] or 0, 16)
        net.Broadcast()

        if lifeTbl[teamIndex] <= 0 then
            zb:EndRound()
        end
    end

    if ply:GetNWBool("IC_IsCommander", false) then return end
    ply.icRespawnTime = CurTime() + 10
    net.Start("ic_respawn")
        net.WriteFloat(CurTime())
        net.WriteInt(10, 16)
    net.Send(ply)
end

function MODE:RoundThink()
    self._respawnCheck = self._respawnCheck or CurTime()
    if self._respawnCheck > CurTime() then return end
    self._respawnCheck = CurTime() + 1
    for _, ply in ipairs(player.GetAll()) do
        if not ply:Alive() and ply.icRespawnTime and (ply.icRespawnTime <= CurTime()) then
            ply.icRespawnTime = nil
            if not ply:GetNWBool("IC_IsCommander", false) then
                if ply:Team() == TEAM_SPECTATOR then continue end
                ply:Spawn()
            end
        end
    end
end

function MODE:DontKillPlayer(ply)
    return ply:GetNWBool("IC_IsCommander", false)
end

function MODE:EndRound()
    timer.Remove("ic_attrition_timer")
    timer.Remove("ic_budget_tick")
    timer.Remove("ic_cleanup_loop")
    if self.saved then
        self.saved.attrition_active = false
        local l0 = self.saved.life[0] or 0
        local l1 = self.saved.life[1] or 0
        local winner = -1
        local loser = -1
        local stalemate = false
        local reason = ""
        if l0 <= 0 and l1 > 0 then
            loser = 0
            winner = 1
            reason = "Life depleted"
        elseif l1 <= 0 and l0 > 0 then
            loser = 1
            winner = 0
            reason = "Life depleted"
        else
            if l0 == l1 then
                stalemate = true
                reason = "Time expired"
            elseif l0 < l1 then
                loser = 0
                winner = 1
                reason = "Time expired"
            else
                loser = 1
                winner = 0
                reason = "Time expired"
            end
        end
        net.Start("ic_music_stop")
            net.WriteFloat(2.5)
        net.Broadcast()
        net.Start("ic_round_end")
            net.WriteInt(winner, 8)
            net.WriteInt(loser, 8)
            net.WriteBool(stalemate)
            net.WriteString(reason)
        net.Broadcast()
    end
end

function MODE:GiveEquipment()
    timer.Simple(0.1, function()
        for _, ply in ipairs(player.GetAll()) do
            if not IsValid(ply) or not ply:Alive() then continue end
            if ply:GetNWBool("IC_IsCommander", false) then continue end
            if ply:Team() == TEAM_SPECTATOR then continue end
            if ply:Team() == 1 then
                ply:SetPlayerClass("nationalguard")
            else
                ply:SetPlayerClass("terrorist")
            end
            if not ply:HasWeapon("weapon_hands_sh") then ply:Give("weapon_hands_sh") end
            ply:SelectWeapon("weapon_hands_sh")
        end
    end)
end

function MODE:CanSpawn(ply)
    if ply:GetNWBool("IC_IsCommander", false) then return false end
    return true -- Allow regular players to spawn
end

function MODE:PlayerSpawn(_, ply)
    if not IsValid(ply) then return end
    if ply:GetNWBool("IC_IsCommander", false) then return end
    if ply:Team() == TEAM_SPECTATOR then return end
    if ply.PlayerClassName == "terrorist" then
        ply:PlayerClassEvent("On")
    end
    local spawnPos = zb:GetTeamSpawn(ply)
    if spawnPos then
        ply:SetPos(spawnPos)
    end
    if not ply:HasWeapon("weapon_hands_sh") then ply:Give("weapon_hands_sh") end
    ply:SelectWeapon("weapon_hands_sh")

    -- everyone gets a sling on insurgency
    local inv = ply:GetNetVar("Inventory") or {}
    inv["Weapons"] = inv["Weapons"] or {}
    inv["Weapons"]["hg_sling"] = true
    ply:SetNetVar("Inventory", inv)

    local mode = CurrentRound()
    if not mode or mode.name ~= "insurgency_conflict" then return end
    local teamIndex = ply:Team()
    local eq = mode.saved and mode.saved.equipment and mode.saved.equipment[teamIndex]
    if not eq then return end
    if eq.secondary then ply:Give(eq.secondary) end
    if eq.melee then ply:Give(eq.melee) end
    if eq.primary then ply:Give(eq.primary) end
    if eq.armors and hg and hg.GetArmorPlacement and hg.AddArmor then
        local current = ply:GetNetVar("Armor") or {}
        local give = {}
        for _, a in ipairs(eq.armors) do
            local base = string.Replace(tostring(a), "ent_armor_", "")
            local plc = hg.GetArmorPlacement(base)
            if plc and current[plc] ~= base then
                give[#give + 1] = a
            end
        end
        if #give > 0 then
            hg.AddArmor(ply, give)
        end
    end
    if eq.ammo then
        for ammoName, amt in pairs(eq.ammo) do
            local def = hg and hg.ammotypes and hg.ammotypes[ammoName]
            if def and def.name then
                local ammoType = game.GetAmmoID(def.name)
                if ammoType and ammoType ~= -1 then
                    ply:GiveAmmo(amt, ammoType, true)
                end
            end
        end
    end
end

COMMANDS.ic_setcommander = {
    function(ply, args)
        if not ply:IsAdmin() then ply:ChatPrint("Access denied") return end
        local targetPart = string.lower(args[1] or "")
        local teamIndex = tonumber(args[2] or "")
        if teamIndex ~= 0 and teamIndex ~= 1 then ply:ChatPrint("Team must be 0 or 1") return end

        local target
        for _, p in ipairs(player.GetAll()) do
            if string.find(string.lower(p:Nick()), targetPart, 1, true) then target = p break end
        end
        if not IsValid(target) then ply:ChatPrint("Player not found") return end

        MODE.saved = MODE.saved or {}
        MODE.saved.commanders = MODE.saved.commanders or {[0] = nil, [1] = nil}
    MODE.saved.commanders[teamIndex] = target

    target:SetNWInt("IC_CommanderTeam", teamIndex)
    target:SetNWBool("IC_IsCommander", true)
    target.viewmode = 3
    if target:Alive() then target:KillSilent() end
    target:Spectate(OBS_MODE_ROAMING)
    if teamIndex == 0 then
        zb.GiveRole(target, "Insurgent Commander", Color(190,40,40))
    else
        zb.GiveRole(target, "Coalition Commander", Color(0,173,43))
    end
    ply:ChatPrint("Commander set: " .. target:Nick() .. " for team " .. teamIndex)
    end,
    1,
    "<player> <team>"
}

concommand.Add("ic_force_commander_gov", function(ply, _, args)
    local targetPart = string.lower(args and args[1] or "")
    if IsValid(ply) and not ply:IsAdmin() then return end
    if targetPart == "" then if IsValid(ply) then ply:ChatPrint("specify player") else print("specify player") end return end
    local target
    for _, p in ipairs(player.GetAll()) do
        if string.find(string.lower(p:Nick()), targetPart, 1, true) then target = p break end
    end
    if not IsValid(target) then if IsValid(ply) then ply:ChatPrint("player not found") else print("player not found") end return end
    local mode = CurrentRound()
    if not mode or mode.name ~= "insurgency_conflict" then return end
    mode.saved = mode.saved or {}
    mode.saved.forcedCommanders = mode.saved.forcedCommanders or {[0] = nil, [1] = nil}
    mode.saved.forcedCommanders[1] = target:SteamID()
    if IsValid(ply) then ply:ChatPrint("queued government commander: " .. target:Nick()) else print("queued government commander: " .. target:Nick()) end
end)

concommand.Add("ic_force_commander_rebel", function(ply, _, args)
    local targetPart = string.lower(args and args[1] or "")
    if IsValid(ply) and not ply:IsAdmin() then return end
    if targetPart == "" then if IsValid(ply) then ply:ChatPrint("specify player") else print("specify player") end return end
    local target
    for _, p in ipairs(player.GetAll()) do
        if string.find(string.lower(p:Nick()), targetPart, 1, true) then target = p break end
    end
    if not IsValid(target) then if IsValid(ply) then ply:ChatPrint("player not found") else print("player not found") end return end
    local mode = CurrentRound()
    if not mode or mode.name ~= "insurgency_conflict" then return end
    mode.saved = mode.saved or {}
    mode.saved.forcedCommanders = mode.saved.forcedCommanders or {[0] = nil, [1] = nil}
    mode.saved.forcedCommanders[0] = target:SteamID()
    if IsValid(ply) then ply:ChatPrint("queued rebel commander: " .. target:Nick()) else print("queued rebel commander: " .. target:Nick()) end
end)

function MODE:ShowSpare1(_, ply)
    local teamIndex = ply:GetNWInt("IC_CommanderTeam", -1)
    if teamIndex < 0 then return end
    net.Start("ic_buymenu_data")
        net.WriteTable(zb.modes["tdm"] and zb.modes["tdm"].BuyItems or {})
    net.Send(ply)
    net.Start("ic_open_buymenu")
    net.Send(ply)
end

function MODE:ShowSpare2(_, ply)
    local teamIndex = ply:GetNWInt("IC_CommanderTeam", -1)
    if teamIndex < 0 then return end
    net.Start("ic_buymenu_data")
        net.WriteTable(zb.modes["tdm"] and zb.modes["tdm"].BuyItems or {})
    net.Send(ply)
    net.Start("ic_open_buymenu")
    net.Send(ply)
end

net.Receive("ic_buy_perk", function(len, ply)
    local teamIndex = ply:GetNWInt("IC_CommanderTeam", -1)
    if teamIndex < 0 then return end
    local perkId = net.ReadString()
    local cost = tonumber(net.ReadInt(16)) or 0
    local mode = CurrentRound()
    if not mode or mode.name ~= "insurgency_conflict" then return end
    local budget = mode.saved and mode.saved.budget and mode.saved.budget[teamIndex] or 0
    if budget < cost then return end
    if cost > 0 then
        mode.saved.budget[teamIndex] = budget - cost
        net.Start("ic_update_budget")
            net.WriteInt(mode.saved.budget[0] or 0, 16)
            net.WriteInt(mode.saved.budget[1] or 0, 16)
        net.Broadcast()
    end
    if perkId == "airstrike" then
        net.Start("ic_airstrike_begin")
        net.Send(ply)
    elseif perkId == "uav" then
        net.Start("ic_uav_begin")
        net.Send(ply)
    elseif perkId == "troop" then
        if not mode.saved or not mode.saved.life then return end
        local lifeTbl = mode.saved.life
        local cur = lifeTbl[teamIndex] or 0
        if cur >= 40 then return end
        lifeTbl[teamIndex] = math.min(cur + 1, 40)
        net.Start("ic_update_life")
            net.WriteInt(lifeTbl[0] or 0, 16)
            net.WriteInt(lifeTbl[1] or 0, 16)
        net.Broadcast()
    end
end)

net.Receive("ic_buy_equipment", function(len, ply)
    local teamIndex = ply:GetNWInt("IC_CommanderTeam", -1)
    if teamIndex < 0 then return end
    local mode = CurrentRound()
    if not mode or mode.name ~= "insurgency_conflict" then return end
    local tItem = net.ReadTable()
    if not istable(tItem) or not tItem[1] or not tItem[2] then return end
    local buyItems = zb.modes["tdm"] and zb.modes["tdm"].BuyItems or {}
    local cat = buyItems[tItem[1]]
    if not cat then return end
    local item = cat[tItem[2]]
    if not item then return end
    local cost = tonumber(item.Price) or 0
    local budget = mode.saved and mode.saved.budget and (mode.saved.budget[teamIndex] or 0) or 0
    if budget < cost then return end
    mode.saved.budget[teamIndex] = budget - cost
    net.Start("ic_update_budget")
        net.WriteInt(mode.saved.budget[0] or 0, 16)
        net.WriteInt(mode.saved.budget[1] or 0, 16)
    net.Broadcast()

    mode.saved.equipment = mode.saved.equipment or {}
    mode.saved.equipment[teamIndex] = mode.saved.equipment[teamIndex] or {secondary=nil, melee=nil, primary=nil, ammo={}, armors={}}

    local cname = tItem[1]
    if cname == "Pistols" then
        mode.saved.equipment[teamIndex].secondary = item.ItemClass
    elseif cname == "Assault" or cname == "Submachine" or cname == "Shotguns" or cname == "Heavy" or cname == "Marksman/Sniper" then
        mode.saved.equipment[teamIndex].primary = item.ItemClass
    elseif cname == "Ammo" then
        local cls = tostring(item.ItemClass or "")
        local ammoName = string.gsub(cls, "^ent_ammo_", "")
        local amount = tonumber(item.Amount) or 0
        if ammoName ~= "" and amount > 0 then
            local cur = mode.saved.equipment[teamIndex].ammo[ammoName] or 0
            mode.saved.equipment[teamIndex].ammo[ammoName] = cur + amount
        end
    elseif cname == "Equipment" and (item.Type == "Armor" or string.find(tostring(item.ItemClass or ""), "^ent_armor_")) then
        local cls = tostring(item.ItemClass or "")
        if cls ~= "" then
            mode.saved.equipment[teamIndex].armors = mode.saved.equipment[teamIndex].armors or {}
            table.insert(mode.saved.equipment[teamIndex].armors, cls)
        end
    end
end)

net.Receive("ic_uav_execute", function(len, ply)
    local teamIndex = ply:GetNWInt("IC_CommanderTeam", -1)
    if teamIndex < 0 then return end
    local mode = CurrentRound()
    if not mode or mode.name ~= "insurgency_conflict" then return end
    local pos = net.ReadVector()
    for _, p in ipairs(player.GetAll()) do
        if IsValid(p) then p:EmitSound("droneisabove.ogg", 80, 100, 1) end
    end
    timer.Simple(2, function()
        for _, p in ipairs(player.GetAll()) do
            if IsValid(p) then p:EmitSound("droneisabove.ogg", 80, 100, 1) end
        end
    end)
    local marks = {}
    local radius = 1600
    for _, target in ipairs(player.GetAll()) do
        if not IsValid(target) then continue end
        if not target:Alive() then continue end
        if target:Team() == TEAM_SPECTATOR then continue end
        if target:Team() == teamIndex then continue end
        local dxy = Vector(target:GetPos().x, target:GetPos().y, 0):Distance(Vector(pos.x, pos.y, 0))
        if dxy <= radius then table.insert(marks, target) end
    end
    if #marks > 0 then
        for _, friend in ipairs(player.GetAll()) do
            if IsValid(friend) and friend:Team() == teamIndex then
                net.Start("ic_uav_marks")
                    net.WriteUInt(#marks, 16)
                    for i = 1, #marks do
                        net.WriteEntity(marks[i])
                    end
                net.Send(friend)
                friend:EmitSound("rebelsfound.ogg", 80, 100, 1)
            end
        end
    end
end)

net.Receive("ic_uav_cancel", function(len, ply) end)

local function IC_GetPlaneHeightAt(pos)
    local tr = util.TraceLine({start = pos, endpos = pos + Vector(0,0,100000), mask = MASK_SOLID_BRUSHONLY})
    local worldTop = (tr.HitPos.z - 100)
    return math.min(worldTop, pos.z + 2200)
end

local function IC_SpawnAirstrikePlane(target)
    local delay = math.Rand(5, 7)
    timer.Simple(delay, function()
        local h = IC_GetPlaneHeightAt(target)
        local minB, maxB = game.GetWorld():GetModelBounds()
        local axis = math.random(1,2)
        local startPos, endPos
        if axis == 1 then
            startPos = Vector(minB.x - 3500, target.y, h)
            endPos = Vector(maxB.x + 3500, target.y, h)
        else
            startPos = Vector(target.x, minB.y - 3500, h)
            endPos = Vector(target.x, maxB.y + 3500, h)
        end
        local dirNorm = (endPos - startPos):GetNormalized()
        endPos = endPos + dirNorm * 2500
        local plane = ents.Create("prop_dynamic")
        if not IsValid(plane) then return end
        plane:SetModel("models/xqm/jetbody3_s3.mdl")
        plane:SetPos(startPos)
        local dir = endPos - startPos
        local ang = dir:Angle()
        ang:RotateAroundAxis(ang:Up(), 90)
        plane:SetAngles(ang)
        plane:Spawn()
        plane:Activate()
        util.ScreenShake(target, 1, 2, 6, 99999)
        local shakeTimer = "IC_JetShake_" .. plane:EntIndex()
        timer.Create(shakeTimer, 0.4, 0, function()
            if not IsValid(plane) then timer.Remove(shakeTimer) return end
            for _, e in ipairs(ents.GetAll()) do
                local phys = e:GetPhysicsObject()
                if IsValid(phys) and phys:IsMotionEnabled() then
                    phys:ApplyForceCenter(VectorRand() * 15)
                end
            end
        end)
        local speed = 800 * 12.0
        local dist = startPos:Distance(endPos)
        local dur = dist / speed
        local startTime = CurTime()
        local hn = "IC_AirstrikePlane_" .. plane:EntIndex()
        hook.Add("Think", hn, function()
            if not IsValid(plane) then hook.Remove("Think", hn) return end
            local tBase = (CurTime() - startTime) / dur
            local accelStart = 0.8
            local accelFactor = 1.7
            local t
            if tBase > accelStart then
                local tail = tBase - accelStart
                t = math.min(1, accelStart + tail * accelFactor)
            else
                t = tBase
            end
            if tBase >= 1 then plane:Remove() hook.Remove("Think", hn) timer.Remove(shakeTimer) return end
            local p = LerpVector(t, startPos, endPos)
            plane:SetPos(p)
        end)
        local dropT
        if axis == 1 then
            dropT = math.Clamp((target.x - startPos.x) / (endPos.x - startPos.x), 0, 1)
        else
            dropT = math.Clamp((target.y - startPos.y) / (endPos.y - startPos.y), 0, 1)
        end
        timer.Simple(dur * dropT, function()
            if not IsValid(plane) then return end
            for _, p in ipairs(player.GetAll()) do
                if IsValid(p) then p:EmitSound("jetflybyclose.ogg", 80, 100, 1) end
            end
            local bombClass = "ent_jack_gmod_ezbomb"
            if math.random() < 0.1 then
                bombClass = "ent_jack_gmod_ezbigbomb"
            end
            local bomb = ents.Create(bombClass)
            if not IsValid(bomb) then return end
            bomb:SetPos(plane:GetPos() + Vector(0,0,-60))
            bomb:Spawn()
            bomb:Activate()
            if bomb.Arm then
                bomb:Arm()
            elseif bomb.SetState then
                bomb:SetState(1)
            end
        end)
    end)
end

net.Receive("ic_airstrike_execute", function(len, ply)
    local teamIndex = ply:GetNWInt("IC_CommanderTeam", -1)
    if teamIndex < 0 then return end
    local mode = CurrentRound()
    if not mode or mode.name ~= "insurgency_conflict" then return end
    local pos = net.ReadVector()
    
    -- Play jet flyby sound for all players
    for _, p in ipairs(player.GetAll()) do
        if IsValid(p) then p:EmitSound("jetflybylong.wav", 80, 100, 1) end
    end
    
    -- Play airstrike call-in sound for teammates and commander
    for _, p in ipairs(player.GetAll()) do
        if IsValid(p) and (p == ply or p:Team() == teamIndex) then
            p:EmitSound("airstrikecallin.ogg", 75, 100, 0.8)
        end
    end
    
    IC_SpawnAirstrikePlane(pos)
end)

net.Receive("ic_airstrike_cancel", function(len, ply)
end)

function MODE:PlayerInitialSpawn(ply)
    if not IsValid(ply) or (not ply.IsPlayer or not ply:IsPlayer()) then return end
    
    -- Handle new players regardless of round state
    if ply:Team() == TEAM_SPECTATOR then return end
    
    -- Set up team and role for new players
    ply:SetTeam(zb:BalancedChoice(0, 1))
    local roleName = (ply:Team() == 0 and "Insurgent") or "Coalition"
    local roleColor = (ply:Team() == 0 and Color(0,173,43)) or Color(30,110,200)
    zb.GiveRole(ply, roleName, roleColor)
    
    -- Set player class based on team
    if ply:Team() == 1 then
        ply:SetPlayerClass("nationalguard")
    else
        ply:SetPlayerClass("terrorist")
    end
    
    -- Give basic equipment
    if not ply:HasWeapon("weapon_hands_sh") then ply:Give("weapon_hands_sh") end
    ply:SelectWeapon("weapon_hands_sh")
    
    -- Only spawn immediately if round is active, otherwise wait for next round
    if zb.ROUND_STATE == 1 then
        ply:Spawn()
    end
    
    -- Send round info to new player
    local mode = CurrentRound()
    if mode and mode.name == "insurgency_conflict" then
        net.Start("ic_roundtime")
            net.WriteFloat((zb.ROUND_START or CurTime()) + (mode.ROUND_TIME or 0))
        net.Send(ply)
        net.Start("ic_perkdefs")
            net.WriteTable(mode.PerkDefs or {})
        net.Send(ply)
    end
end

-- Handle players who joined during intermission when round starts
hook.Add("ZB_PreRoundStart", "IC_SpawnWaitingPlayers", function()
    local mode = CurrentRound()
    if not mode or mode.name ~= "insurgency_conflict" then return end
    
    -- Spawn any players who are waiting (joined during intermission)
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:Team() ~= TEAM_SPECTATOR and not ply:Alive() then
            ply:Spawn()
        end
    end
end)

    
hook.Add("PlayerSay", "IC_CommanderTeamChat", function(ply, text, teamOnly)
    local mode = CurrentRound()
    if not mode or mode.name ~= "insurgency_conflict" then return end
    if not IsValid(ply) then return end
    
    -- Handle commander to team communication (existing functionality)
    if ply:GetNWBool("IC_IsCommander", false) then
        local t = ply:GetNWInt("IC_CommanderTeam", -1)
        if t ~= 0 and t ~= 1 then return end
        local msg = "[COMMANDER]: " .. tostring(text or "")
        for _, p in ipairs(player.GetAll()) do
            if p:Team() == t then
                p:ChatPrint(msg)
            end
        end
        return ""
    end
    
    -- Check for commander message commands (!cmd or @cmd)
    local lowerText = string.lower(text or "")
    local isCommanderMessage = string.StartWith(lowerText, "!cmd ") or string.StartWith(lowerText, "@cmd ")
    
    -- Handle team to commander communication (new functionality)
    local playerTeam = ply:Team()
    if (playerTeam == 0 or playerTeam == 1) and (isCommanderMessage or teamOnly) then
        -- Find the commander for this team
        local commander = nil
        for _, p in ipairs(player.GetAll()) do
            if p:GetNWBool("IC_IsCommander", false) and p:GetNWInt("IC_CommanderTeam", -1) == playerTeam then
                commander = p
                break
            end
        end
        
        -- If commander exists, send message to commander only
        if IsValid(commander) then
            -- Remove the command prefix if present
            local cleanText = tostring(text or "")
            if isCommanderMessage then
                cleanText = string.sub(cleanText, 6) -- Remove "!cmd " or "@cmd "
            end
            
            local msg = "[TEAM]: " .. ply:Nick() .. ": " .. cleanText
            commander:ChatPrint(msg)
            
            -- Also show the message to the sender
            ply:ChatPrint("[TO COMMANDER]: " .. cleanText)
            
            -- Don't show this message to other players (suppress default chat)
            return ""
        else
            -- No commander available
            ply:ChatPrint("No commander available for your team!")
            return ""
        end
    end
end)

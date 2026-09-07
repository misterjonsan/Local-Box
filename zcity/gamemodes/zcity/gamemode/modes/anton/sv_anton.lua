MODE.name = "anton"
MODE.PrintName = "Anton Chigurh"

MODE.ForBigMaps = false
MODE.ROUND_TIME = 600
MODE.LootSpawn = true

MODE.Chance = 0

function MODE.GuiltCheck(Attacker, Victim, add, harm, amt)
	return 1, true
end

local function shuffle(tbl)
	local len = #tbl
	for i = len, 2, -1 do
	  local j = math.random(i)
	  tbl[i], tbl[j] = tbl[j], tbl[i]
	end
end

function MODE:AssignTeams()
    local players = {}
    for _, ply in ipairs(player.GetAll()) do
        if ply:Team() != TEAM_SPECTATOR then
            table.insert(players, ply)
        end
    end
    local numPlayers = #players

    shuffle(players)
    if numPlayers == 0 then return end

    local anton = players[1]
    anton:SetTeam(2)
    self.Anton = anton

    for i = 2, numPlayers do
        local ply = players[i]
        if not IsValid(ply) then continue end
        ply:SetTeam(1)
    end
end

util.AddNetworkString("anton_start")
function MODE:Intermission()
    game.CleanUpMap()
    if hg and hg.UpdateRoundTime then
        hg.UpdateRoundTime(self.ROUND_TIME)
    end
    self:AssignTeams()

    if IsValid(self.Anton) then
        self.Anton:Spawn()
        self.Anton:SetTeam(2)
    end
    
    -- Убиваем остальных (жертв и полицию) - они спавнятся в RoundStart
    for k, ply in ipairs(player.GetAll()) do
        if ply ~= self.Anton then 
            ply:KillSilent() 
        end
    end
    
    net.Start("anton_start")
    net.Broadcast()
end

function MODE:CheckAlivePlayers()
    local policePlayers = {}
    local victimPlayers = {}
    local antonPlayers = {}

    for _, ply in ipairs(team.GetPlayers(0)) do
        if ply:Alive() and not ply:GetNetVar("handcuffed", false) then
            table.insert(policePlayers, ply)
        end
    end

    for _, ply in ipairs(team.GetPlayers(1)) do
        if ply:Alive() and not ply:GetNetVar("handcuffed", false) then
            table.insert(victimPlayers, ply)
        end
    end

    for _, ply in ipairs(team.GetPlayers(2)) do
        if ply:Alive() and not ply:GetNetVar("handcuffed", false) then
            table.insert(antonPlayers, ply)
        end
    end

    return {policePlayers, victimPlayers, antonPlayers}
end

function MODE:ShouldRoundEnd()
    if not zb or not zb.ROUND_START then return false end
    if zb.ROUND_START + 30 > CurTime() then return false end

    local aliveTeams = self:CheckAlivePlayers()
    
    -- Anton (Team 2) is dead or arrested
    if #aliveTeams[3] == 0 then
        return true
    end

    -- Victims (Team 1) and Police (Team 0) are all dead/arrested
    if #aliveTeams[2] == 0 and #aliveTeams[1] == 0 then
        return true
    end

    if zb.CheckWinner then
        local endround = zb:CheckWinner(aliveTeams)
        return endround
    end
    return false
end

function MODE:RoundStart()
end

function MODE:CanLaunch()
    return true
end

function MODE:GiveEquipment()
    timer.Simple(0.5,function()
        self.PoliceQueue = {}
        self.PoliceQueueSet = {}

        for i, ply in ipairs(player.GetAll()) do
            if ply:Team() == TEAM_SPECTATOR then continue end

            if ply:Team() == 2 then
                timer.Create("AntonSpawn"..ply:EntIndex(), 20, 1, function()
                    if not IsValid(ply) then return end
                    ply:Spawn()
                    ply:SetSuppressPickupNotices(true)
                    ply.noSound = true
                    ply:SetModel("models/mug/ncfom/anton_chigurh.mdl")
                    ply:SetNetVar("CustomModel","models/mug/ncfom/anton_chigurh.mdl")
                    if ply.SetupTeam then ply:SetupTeam(ply:Team()) end
                    if ply.SetPlayerClass then ply:SetPlayerClass() end

                    if zb and zb.GiveRole then
                        zb.GiveRole(ply, "Anton Chigurh", Color(190,0,0))
                    end

                    local inv = ply:GetNetVar("Inventory") or {}
                    inv["Weapons"] = inv["Weapons"] or {}
                    inv["Weapons"]["hg_sling"] = true
                    inv["Weapons"]["hg_melee_belt"] = true
                    ply:SetNetVar("Inventory", inv)

                    local function giveWithReserve(class)
                        local wep = ply:Give(class)
                        if IsValid(wep) and wep.GetMaxClip1 and wep.GetPrimaryAmmoType and wep:GetMaxClip1() > 0 then
                            ply:GiveAmmo(wep:GetMaxClip1() * 2, wep:GetPrimaryAmmoType(), true)
                        end
                    end

                    giveWithReserve("weapon_anton")
                    ply:Give("weapon_hands_sh")

                    ply:SetSuppressPickupNotices(false)
                    ply.noSound = false
                end)
            else
                ply:SetSuppressPickupNotices(true)
                ply.noSound = true

                if ply.SetPlayerClass then ply:SetPlayerClass() end

                if zb and zb.GiveRole then
                    zb.GiveRole(ply, "Victim", Color(255,255,255))
                end

                ply:Give("weapon_hands_sh")

                ply:SetSuppressPickupNotices(false)
                ply.noSound = false
            end

			timer.Simple(0.5,function()
				if IsValid(ply) then ply.noSound = false end
			end)
		end

        timer.Create("PoliceArrival", 138, 1, function() -- 2.3 minutes = 138 seconds
            for _, ply in ipairs(self.PoliceQueue or {}) do
                if IsValid(ply) then
                    self:SpawnPolice(ply)
                end
            end
            self.PoliceQueue = {}
            self.PoliceQueueSet = {}
        end)
    end)
end

function MODE:SpawnPolice(ply)
    if not IsValid(ply) then return end
    ply:SetTeam(0)
    ply:Spawn()
    ply:SetSuppressPickupNotices(true)
    ply.noSound = true

    if ply.SetupTeam then ply:SetupTeam(ply:Team()) end
    if ply.SetPlayerClass then ply:SetPlayerClass("swat") end

    local inv = ply:GetNetVar("Inventory") or {}
    inv["Weapons"] = inv["Weapons"] or {}
    inv["Weapons"]["hg_sling"] = true
    ply:SetNetVar("Inventory",inv)

    if hg and hg.AddArmor then
        hg.AddArmor(ply, {"ent_armor_vest4","ent_armor_helmet2"})
    end
    
    if zb and zb.GiveRole then
        zb.GiveRole(ply, "Police", Color(0,0,190))
    end

    local gun = ply:Give("weapon_glock17")
    if IsValid(gun) and gun.GetMaxClip1 then
        ply:GiveAmmo(gun:GetMaxClip1() * 3,gun:GetPrimaryAmmoType(),true)
    end

    ply:Give("weapon_hands_sh")
    ply:SetSuppressPickupNotices(false)
    ply.noSound = false
end

function MODE:RoundThink()
end

function MODE:GetTeamSpawn()
    if zb and zb.GetRandomSpawn then
	    return {zb:GetRandomSpawn()}, {zb:GetRandomSpawn()}
    end
    return {}, {}
end

function MODE:CanSpawn()
end

util.AddNetworkString("anton_roundend")
function MODE:EndRound()
	for k,ply in player.Iterator() do
		if timer.Exists("PoliceSpawn"..ply:EntIndex()) then
			timer.Remove("PoliceSpawn"..ply:EntIndex())
		end
		if timer.Exists("AntonSpawn"..ply:EntIndex()) then
			timer.Remove("AntonSpawn"..ply:EntIndex())
		end
	end
	if timer.Exists("PoliceArrival") then
		timer.Remove("PoliceArrival")
	end
	self.PoliceQueue = {}
	self.PoliceQueueSet = {}

    local aliveTeams = self:CheckAlivePlayers()
    local winner = 1
    if zb and zb.CheckWinner then
        local endround, win = zb:CheckWinner(aliveTeams)
        winner = win
    end

	timer.Simple(2,function()
		net.Start("anton_roundend")
			net.WriteBool(winner == 2) -- Anton wins if winner is team 2
		net.Broadcast()
	end)

	for k,ply in player.Iterator() do
		if ply:Team() == winner then
			if ply.GiveExp then ply:GiveExp(math.random(15,30)) end
			if ply.GiveSkill then ply:GiveSkill(math.Rand(0.1,0.15)) end
		else
			if ply.GiveSkill then ply:GiveSkill(-math.Rand(0.05,0.1)) end
		end
	end
end

function MODE:PlayerDeath(_, ply)
    if not IsValid(ply) then return end
    if ply:Team() == 2 then return end
    if ply:Team() ~= 1 then return end
    if zb and zb.ROUND_START and CurTime() > (zb.ROUND_START + 138) then return end
    if self.PoliceQueueSet and self.PoliceQueueSet[ply] then return end
    self.PoliceQueue = self.PoliceQueue or {}
    self.PoliceQueueSet = self.PoliceQueueSet or {}
    table.insert(self.PoliceQueue, ply)
    self.PoliceQueueSet[ply] = true
    ply:SetTeam(0)
end

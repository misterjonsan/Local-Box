local MODE = MODE

MODE.name = "sc"
MODE.randomSpawns = true
MODE.buymenu = true
MODE.OverideSpawnPos = true
MODE.InfilEscaped = false

MODE.Chance = 0.02

function MODE.GuiltCheck(Attacker, Victim, add, harm, amt)
	return 0, false
end

function MODE:CanLaunch()
	local points, points2 = zb.GetMapPoints("SC_INTRUDER"), zb.GetMapPoints("SC_GUARD")
	local case, escape = zb.GetMapPoints("SC_CASE"), zb.GetMapPoints("SC_ESCAPE")

	local check = #points > 0 and #points2 > 0 and #case > 0 and #escape > 0
	return check and string.find(game.GetMap(), "night")
end

MODE.ForBigMaps = true

util.AddNetworkString("sc_start")

local veccase = Vector(0, 0, 10)
function MODE:Intermission()
	game.CleanUpMap()

	self.InfilEscaped = false

	self.CTPoints = {}
	self.TPoints = {}
	self.CasePoints = {}
	self.EscapePoints = {}
	table.CopyFromTo( zb.GetMapPoints("SC_INTRUDER"), self.TPoints)
	table.CopyFromTo( zb.GetMapPoints("SC_GUARD"), self.CTPoints)
	table.CopyFromTo( zb.GetMapPoints("SC_CASE"), self.CasePoints)
	table.CopyFromTo( zb.GetMapPoints("SC_ESCAPE"), self.EscapePoints)

	local choosenone
	for k, ply in RandomPairs(player.GetAll()) do
		if ply:Team() == TEAM_SPECTATOR then continue end
		ply:SetupTeam( ply:Team() )
		if not choosenone then
			choosenone = ply
			choosenone:SetTeam(0)
		else
			ply:SetTeam(1)
		end
	end

	if self.CasePoints and #self.CasePoints > 0 then
		for i = 1, #self.CasePoints do
			local case = ents.Create("ent_sc_case")
			case:SetPos(self.CasePoints[#self.CasePoints].pos + veccase)
			case:Spawn()
			if #self.CasePoints > 1 then 
				table.remove(self.CasePoints)
			end
		end
	end

	net.Start("sc_start")
	net.Broadcast()
end

function MODE:CheckAlivePlayers()
	return zb:CheckAliveTeams(true)
end

function MODE:ShouldRoundEnd()
	if self.EscapePoints and #self.EscapePoints > 0 then -- если код обновить то все сломается нужен рестарт раунда
		for i = 1, #self.EscapePoints do
			local escapepos = self.EscapePoints[#self.EscapePoints].pos
			for _, ent in ipairs(ents.FindInSphere(escapepos, 350)) do
				if not ent:IsPlayer() or (ent:IsPlayer() and ent:Team() ~= 0) or (ent:IsPlayer() and not ent:GetNWBool("sc-havecase")) then continue end
				print(ent)
				--self:EndRound()
				ent:GiveExp(math.random(15,30))
				ent:GiveSkill(math.Rand(0.1,0.15))
				ent:SetNWBool("sc-havecase", false)
				PrintMessage(HUD_PRINTTALK, "Infiltrator escaped with case.")
				self.InfilEscaped = true
				return true
			end
		end
	end

	local endround, winner = zb:CheckWinner(self:CheckAlivePlayers())
	return endround
end

function MODE:RoundStart()
	zb:Unfreeze()
end

function MODE:GetPlySpawn(ply)
	local plyTeam = ply:Team()

	if ply:Team() == 1 then
		if self.CTPoints and #self.CTPoints > 0 then
			ply:SetPos(self.CTPoints[#self.CTPoints].pos)
			if #self.CTPoints > 1 then 
				table.remove(self.CTPoints)
			end
		end
	else
		if self.TPoints and #self.TPoints > 0 then
			ply:SetPos(self.TPoints[#self.TPoints].pos)
			if #self.TPoints > 1 then 
				table.remove(self.TPoints)
			end
		end
	end
end

local function Loadout(ply, tbl, ammoamt)
	for _, wep in ipairs(tbl) do
		local gun = ply:Give(wep)
		--[[if IsValid(gun) and gun:GetMaxClip1() > 0 then
			ply:GiveAmmo(gun:GetMaxClip1() * ammoamt,gun:GetPrimaryAmmoType(),true)
		end]]
	end
end

function MODE:GiveEquipment()
	timer.Simple(0.1,function()
		for _, ply in ipairs(player.GetAll()) do
			if not ply:Alive() then continue end
			ply:SetNWString("PlayerRole", "")

			local inv = ply:GetNetVar("Inventory")
			inv["Weapons"]["hg_sling"] = true
			ply:SetNetVar("Inventory",inv)
			ply:SetNWBool("sc-canselect", true)
			ply:SetNWBool("sc-havecase", false)

			ply:SetSuppressPickupNotices(true)
			ply.noSound = true
			ply:DrawShadow(true)

			zb.SendSpecificPointsToPly(nil, "SC_ESCAPE", true)

			if ply:Team() == 1 then
				ply:SetPlayerClass("sc_guard")
				zb.GiveRole(ply, "Guard", Color(0,0,190))
				--hg.AddArmor(ply, {"vest4", "helmet1"})
				Loadout(ply, {
					"weapon_melee",
					--"weapon_bandage_sh",
					--"weapon_tourniquet",
				}, 1)
				ply.organism.recoilmul = 0.6

				local Radio = ply:Give("weapon_walkie_talkie")
				Radio.Frequency = 2

				local hands = ply:Give("weapon_hands_sh")
				ply:SelectWeapon(hands)
				timer.Simple(.1, function()
					if not IsValid(ply) then return end
					ply.organism.stamina.max = 230
				end)
			else
				ply:SetPlayerClass("sc_infiltrator")
				zb.GiveRole(ply, "Infiltrator", Color(190,0,0))
				-- weapons give
				Loadout(ply, {
					"weapon_tranquilizer",
					"weapon_sogknife",
					"weapon_hg_flashbang_tpik",
					"weapon_hg_emptymag",
					"weapon_hidebox"
				}, 1)
				ply.organism.superfighter = true
				ply:DrawShadow(false)

				local hands = ply:Give("weapon_hands_sh")
				timer.Simple(.1, function()
					if not IsValid(ply or hands) then return end
					hands.PrintName = "CQC"
					hands.WepSelectIcon = Material("vgui/inventory/perk_quick_reload")
					hands.ReachDistance = 72
					hands.ShockMultiplier = 1.5
					hands.PainMultiplier = 1.5
					hands.BreakBoneMul = 0.8
					hands.Penetration = 0.8
					hands.DamageMul = 1
					ply.organism.stamina.max = 500
				end)
				ply:SelectWeapon(hands)
			end

			timer.Simple(0.1,function()
				ply.noSound = false
			end)

			ply:SetSuppressPickupNotices(false)
		end
	end)
end

function MODE:RoundThink()
end

function MODE:GetTeamSpawn()
end

function MODE:CanSpawn()
end

util.AddNetworkString("sc_roundend")
function MODE:EndRound()
	timer.Simple(2,function()
		net.Start("sc_roundend")
		net.Broadcast()
	end)

	local team0alive, team1alive = 0, 0
	local endround, winner = zb:CheckWinner(self:CheckAlivePlayers())
	for k, ply in player.Iterator() do
		if ply:Team() == winner then
			ply:GiveExp(math.random(15,30))
			ply:GiveSkill(math.Rand(0.1,0.15))
			--print("give",ply)

			if ply:Alive() then
				if ply:Team() == 0 then
					team0alive = team0alive + 1
				else
					team1alive = team1alive + 1
				end
			end
		else
			--print("take",ply)
			ply:GiveSkill(-math.Rand(0.05,0.1))
		end
	end

	if not self.InfilEscaped then
		if winner == 0 then
			PrintMessage(HUD_PRINTTALK, (team1alive <= 0 and "Infiltrator neutralized all guardians."))
		elseif team0alive <= 0 and winner == 1 then
			PrintMessage(HUD_PRINTTALK, "Guards has neutralized the infiltrator.")
		elseif winner == 1 then
			PrintMessage(HUD_PRINTTALK, "The infiltrator has failed his task.")
		end
	end
end

function MODE:PlayerDeath(_,ply)
end
util.AddNetworkString( "sc_open_classmenu" )
function MODE:ShowSpare1( _,ply ) -- OpenMenu
	if not ply:Alive() or ply:Team() == 0 then return end
	net.Start( "sc_open_classmenu" )
	net.Send( ply )
end

util.AddNetworkString( "sc_buyitem" )

net.Receive("sc_buyitem",function(len,ply)
	if !CurrentRound().buymenu or ply:Team() == 0 or not ply:GetNWBool("sc-canselect", true) then
		return
	end
	if ((zb.ROUND_START or 0) + MODE.BuyTime < CurTime()) then
		ply:ChatPrint("Time's up!")
		return
	end

	local tItem = net.ReadTable()
	zb.GiveRole(ply, "Guard " .. tItem[2], Color(0,0,190))
	local item = tItem[1]
	for _, weps in ipairs(item) do
		if not weps then return end

		local ent = ply:Give(weps)
		if not IsValid(ent) then return end
		if ent.Use then
			ent:Use( ply )
		end

		if ent.GetPrimaryAmmoType then
			ply:GiveAmmo(ent:GetMaxClip1() * 1,ent:GetPrimaryAmmoType(),true)
		end

		ply:SelectWeapon("weapon_melee") -- Hurrep move
	end

	local tArmor = net.ReadTable()
	local armor = tArmor[1]
	for _, arm in ipairs(armor) do
		if not arm then return end

		hg.AddArmor(ply, arm)
	end

	ply:EmitSound("items/itempickup.wav")
	ply:SelectWeapon("weapon_melee")
	ply:SetNWBool("sc-canselect", false)
end)
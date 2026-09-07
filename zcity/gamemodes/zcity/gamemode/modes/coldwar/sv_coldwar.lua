MODE.name = "coldwar"
MODE.PrintName = "Operation Flashpoint"


MODE.LootSpawn = false


MODE.Chance = 0.05

function MODE:ClearPlayerRoles() -- Щпасибо деке!!
    for _, ply in player.Iterator() do
        ply:SetNWString("PlayerRole", "")
    end
end

function MODE.GuiltCheck(Attacker, Victim, add, harm, amt)
	return 1, true--returning true so guilt bans
end


util.AddNetworkString("coldwar_start")
function MODE:Intermission()
	game.CleanUpMap()

	self.CTPoints = {}
	self.TPoints = {}
	table.CopyFromTo( zb.GetMapPoints( "HMCD_TDM_T" ), self.TPoints)
	table.CopyFromTo( zb.GetMapPoints( "HMCD_TDM_CT" ), self.CTPoints)

	for i, ply in ipairs(player.GetAll()) do
		ply:SetupTeam(ply:Team())
	end

	net.Start("coldwar_start")
	net.Broadcast()
end


function MODE:CheckAlivePlayers()
	local tbl = {}

	for i, info in pairs(team_GetAllTeams()) do
		if i == TEAM_UNASSIGNED or i == TEAM_SPECTATOR then continue end
		tbl[i] = {}
	end

	for _, ply in ipairs(player_GetAll()) do
		if ply:Team() == TEAM_UNASSIGNED or ply:Team() == TEAM_SPECTATOR then continue end
		if not ply:Alive() and ply.Lives and ply.Lives < 1 then continue end
		if ply.organism and (ply.organism.incapacitated or ply.organism.dying) and ply.Lives and ply.Lives < 1 then continue end

		tbl[ply:Team() or 0] = tbl[ply:Team() or 0] or {}
		tbl[ply:Team()][(#tbl[ply:Team() or 0] or 0) + 1] = ply
	end

	return tbl
end

function MODE:ShouldRoundEnd()
	local endround, winner = zb:CheckWinner(self:CheckAlivePlayers())
	--print("ShouldRoundEnd", endround, winner)
	return endround
end


function MODE:RoundStart()
end

local RussiaEquipment = {
	["default"] = {
		Primary = "weapon_ak74",
		Secondary = "weapon_makarov",
		Other = {"weapon_hands_sh","weapon_melee","weapon_hg_rgd_tpik","weapon_bandage_sh","weapon_medkit_sh","weapon_tourniquet"},
		Ammo = {},
		Attachments = {
			Primary = {
				Allways = true,
			}
		},
		Armor = {"vest23","helmet7"}
	},
	["machinegunner"] = {
		Primary = "weapon_rpk",
		Secondary = "weapon_makarov",
		Other = {"weapon_hands_sh","weapon_melee","weapon_hg_rgd_tpik","weapon_bandage_sh","weapon_medkit_sh","weapon_tourniquet"},
		Ammo = {},
		Attachments = {
			Primary = {
				Allways = true,
			}
		}, 
		Armor = {"vest23","helmet7"}
	},
	["sniper1"] = {
		Primary = "weapon_svd",
		Secondary = "weapon_makarov",
		Other = {"weapon_hands_sh","weapon_melee","weapon_hg_rgd_tpik","weapon_bandage_sh","weapon_medkit_sh"},
		Ammo = {},
		Attachments = {
			Primary = {
				Allways = true,
				Scopes = {"optic11","optic3"}
			}
		},
		Armor = {"vest23","helmet7"}
	},
}

local NatoEquipment = {
	["default"] = {
		Primary = "weapon_m16a2",
		Secondary = "weapon_zb_1911",
		Other = {"weapon_hands_sh","weapon_sogknife","weapon_hg_grenade_tpik","weapon_bandage_sh","weapon_medkit_sh","weapon_tourniquet"},
		Ammo = {},
		Attachments = {
			Primary = {
			Allways = true,
		},
		Armor = {"vest1","helmet1"}
	},
	["machinegunner"] = {
		Primary = "weapon_m60",
		Secondary = "weapon_zb_1911",
		Other = {"weapon_hands_sh","weapon_sogknife","weapon_hg_grenade_tpik","weapon_bandage_sh","weapon_medkit_sh","weapon_tourniquet"},
		Ammo = {},
		Attachments = {
			Primary = {
				Allways = true,
		},
		Armor = {"vest1","helmet1")
	},
	["sniper1"] = {
		Primary = "weapon_g3sg1",
		Secondary = "weapon_zb_1911",
		Other = {"weapon_hands_sh","weapon_sogknife","weapon_medkit_sh"},
		Ammo = {},
		Attachments = {
			Primary = {
				Allways = true,
			}
		},
		Armor = {"vest3","helmet1"}
	}
}

local function GiveEquip(ply,team)
	local teamequip = (team == 1 and RussiaEquipment) or NatoEquipment
	local classequip = table.Random(teamequip)

	local inv = ply:GetNetVar("Inventory")
	inv["Weapons"]["hg_sling"] = true
	ply:SetNetVar("Inventory",inv)
	
	local Primary = ply:Give(classequip.Primary)
	ply:GiveAmmo(Primary:GetMaxClip1() * 4,Primary:GetPrimaryAmmoType(),true)
	local atts = {}

	local scopeorno = ( classequip.Attachments.Primary.Allways and 1 ) or (classequip.Attachments.Primary.Scopes and math.random(0,1)) or 0
	if scopeorno > 0 then
		hg.AddAttachmentForce(ply,Primary,classequip.Attachments.Primary.Scopes[math.random(#classequip.Attachments.Primary.Scopes)])		
	end

	local barrelorno = ( classequip.Attachments.Primary.Allways and 1 ) or (classequip.Attachments.Primary.Barell and math.random(0,1)) or 0
	if barrelorno > 0 and classequip.Attachments.Primary.Barell then
		hg.AddAttachmentForce(ply,Primary,classequip.Attachments.Primary.Barell[math.random(#classequip.Attachments.Primary.Barell)])		
	end


	local Secondary = ply:Give(classequip.Secondary)
	ply:GiveAmmo(Secondary:GetMaxClip1() * 4,Secondary:GetPrimaryAmmoType(),true)
			
	hg.AddArmor(ply, classequip.Armor)

	for k,v in ipairs(classequip.Other) do
		ply:Give(v)
	end

	local walkietalkie = ply:Give("weapon_walkie_talkie")
	walkietalkie.Frequency = (team == 1 and 1) or 5

	ply:Give("weapon_hands_sh")
	ply:SelectWeapon("weapon_hands_sh")
	
	timer.Simple(0.2,function()
		ply:SelectWeapon("weapon_hands_sh")
	end)
end

local function spawnswoplayer(ply)
	local WAGNERPoints = zb.GetMapPoints( "HMCD_SWO_WAGNER" )
	local AZOVPoints = zb.GetMapPoints( "HMCD_SWO_AZOV" )

	if not ply:Alive() then ply:Spawn() end

	ply:SetSuppressPickupNotices(true)
	ply.noSound = true

		if ply:Team() == 1 then
			ply:SetPlayerClass("russia")
			zb.GiveRole(ply, "USSR Armed Forces", Color(71,89,0))
		else
			ply:SetPlayerClass("nato")
			zb.GiveRole(ply, "NATO Armed Forces", Color(89,76,0))
		end

	GiveEquip( ply, ply:Team() )

	timer.Simple(0.1,function()
		ply.noSound = false
	end)

	ply:SetSuppressPickupNotices(false)
end

function MODE:GetPlySpawn(ply)
end

function MODE:GiveEquipment()
	self.WAGNERPoints = {}
	table.CopyFromTo(zb.GetMapPoints( "HMCD_SWO_WAGNER" ),self.WAGNERPoints)
	self.AZOVPoints = {}
	table.CopyFromTo(zb.GetMapPoints( "HMCD_SWO_AZOV" ),self.AZOVPoints)
	
	timer.Simple(0.1,function()

		for _, ply in ipairs(player.GetAll()) do
			if not ply:Alive() then continue end
			ply:SetSuppressPickupNotices(true)
			ply.noSound = true

			if ply:Team() == 1 then
				ply:SetPlayerClass("russia")
				zb.GiveRole(ply, "USSR Armed Forces", Color(71,89,0))
			else
				ply:SetPlayerClass("nato")
				zb.GiveRole(ply, "NATO Armed Forces", Color(89,76,0))
			end

			GiveEquip( ply, ply:Team() )

			timer.Simple(0.1,function()
				ply.noSound = false
			end)

			ply:SetSuppressPickupNotices(false)
		end
	end)
end




function MODE:GetTeamSpawn()
	return zb.TranslatePointsToVectors(zb.GetMapPoints( "HMCD_TDM_T" )), zb.TranslatePointsToVectors(zb.GetMapPoints( "HMCD_TDM_CT" ))
end

function MODE:CanSpawn()
end

util.AddNetworkString("coldwar_roundend")
function MODE:EndRound()
	timer.Simple(2,function()
		net.Start("coldwar_roundend")
		net.Broadcast()
	end)

	local endround, winner = zb:CheckWinner(self:CheckAlivePlayers())
	for k,ply in player.Iterator() do
		if ply:Team() == winner then
			ply:GiveExp(math.random(15,30))
			ply:GiveSkill(math.Rand(0.1,0.15))
			--print("give",ply)
		else
			--print("take",ply)
			ply:GiveSkill(-math.Rand(0.05,0.1))
		end
	end
end


local MODE = MODE
--[[
	Раздел идейки как всегда:
	1. Нету они у меня все в голове
]]

MODE.start_time = 10
MODE.BuyTime = 60
MODE.ROUND_TIME = 500

zb = zb or {}
zb.Points = zb.Points or {}

-- Spawn points
zb.Points.SC_GUARD = zb.Points.SC_GUARD or {}
zb.Points.SC_GUARD.Color = Color(35,150,196)
zb.Points.SC_GUARD.Name = "SC_GUARD"

zb.Points.SC_INTRUDER = zb.Points.SC_INTRUDER or {}
zb.Points.SC_INTRUDER.Color = Color(39,233,0)
zb.Points.SC_INTRUDER.Name = "SC_INTRUDER"

-- Objective points
zb.Points.SC_CASE = zb.Points.SC_CASE or {}
zb.Points.SC_CASE.Color = Color(131,255,106)
zb.Points.SC_CASE.Name = "SC_CASE"

zb.Points.SC_ESCAPE = zb.Points.SC_ESCAPE or {}
zb.Points.SC_ESCAPE.Color = Color(253,255,106)
zb.Points.SC_ESCAPE.Name = "SC_ESCAPE"

MODE.PrintName = "Sneaky Splinter"

MODE.BuySets = {}

local function AddSetToBUY(SetName, ItemTable, ArmorTable, AmmoAmt)
	MODE.BuySets[SetName] = {
		ItemTable = ItemTable,
		ArmorTable = ArmorTable,
		AmmoAmt = AmmoAmt,
	}
end
-- Sets
AddSetToBUY("Assault", {
	"weapon_hk416",
	"weapon_hk_usp",
	"weapon_hg_motiontracker",
	"weapon_hg_grenade_impact"
},
{
	"helmet1",
	"vest3"
}, 4)

--[[AddSetToBUY("Light", {
	"weapon_mp5",
	"weapon_glock18c",
	"weapon_hg_flashbang_tpik"
},
{}, 4)]]

--[[AddSetToBUY("Medic", {
	"weapon_remington870",
	"weapon_fn45",
	"weapon_hg_grenade_tpik",
	"weapon_bigbandage_sh",
	"weapon_medkit_sh",
	"weapon_tourniquet",
	"weapon_morphine"
},
{
	"helmet1",
	"vest4"
}, 3)]]

AddSetToBUY("Engineer", {
	"weapon_remington870",
	"weapon_revolver357",
	"weapon_hg_motiontracker",
	"weapon_hg_grenade_tpik",
	"weapon_claymore",
	"weapon_hg_slam"
},
{
	"nightvision1",
	"vest3",
	"helmet1"
}, 2)

AddSetToBUY("Support", {
	"weapon_saiga12", -- weapon_hk21
	"weapon_m9beretta",
	"weapon_hg_motiontracker",
	"weapon_hg_flashbang_tpik",
},
{
	"headphones1",
	"vest1",
	"helmet6"
}, 2)

function MODE:HG_MovementCalc_2( _, mul, ply, cmd )
	if (zb.ROUND_START or 0) + 20 > CurTime() and ply:Team() == 1 then
		cmd:RemoveKey(IN_ATTACK)
		cmd:RemoveKey(IN_FORWARD)
		cmd:RemoveKey(IN_BACK)
		cmd:RemoveKey(IN_MOVELEFT)
		cmd:RemoveKey(IN_MOVERIGHT)
		mul[1] = 0
	end
end
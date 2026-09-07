--[[
作者:白狼
2025 11 1
]]--

-- ==================== 高爬动作特效 ====================
local actionName = 'DParkour-HighClimb'

local function effectstart_default(self, ply, _)
    if SERVER then
    elseif CLIENT then
        VManip:PlayAnim(self.handanim)
        surface.PlaySound(self.sound)
    end
end

local effect, _ = UltiPar.RegisterEffect(
	actionName, 
	'default',
	{
		label = '#default',

		handanim = 'dp_catch_BaiLang',
		sound = 'dparkour/bailang/highclimb.mp3',
		angpunch_first = Angle(-20, 5, 0),
		angpunch_second = Angle(20, 0, 0),
		vecpunch = Vector(0, 0, 25)
	}
)
effect.start = effectstart_default
effect.clear = UltiPar.emptyfunc

local effect2 = table.Copy(effect)
effect2.label = '#dp.effect.SP_VManip_BaiLang'
UltiPar.RegisterEffect(
    actionName, 
    'SP-VManip-白狼', 
    effect2
)

actionName = nil
effect = nil
effectstart_default = nil
effect2 = nil

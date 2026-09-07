local actionName = 'DParkour-HighClimb'
local action, _ = UltiPar.Register(actionName)

local handanim = 'dp_catch_mtbNTB'
local leganim = 'dp_lazy_mtbNTB'
local vaultsound = 'dparkour/mtbntb/vault.mp3'
local climbsound = 'dparkour/mtbntb/highclimb.mp3'

local function effectfunc(ply, data)
    if data == nil then
        if SERVER then
        elseif CLIENT then
            VManip:PlayAnim(handanim)
            surface.PlaySound(climbsound)
        end
    else
		local pos, landpos, _, vaultpos, blockheightVault = unpack(data)
        if SERVER then
        elseif CLIENT then
            VManip:PlayAnim(handanim)
            surface.PlaySound(climbsound)

            if vaultpos and action.IsDoubleVault(ply, blockheightVault) then
                local middlepos = landpos
                middlepos[3] = vaultpos[3]
                local s, e = action:GetSpeed(ply, ply:GetVelocity())
                local duration = 2 * (middlepos:Distance(pos)) / (1.2 * ((s + e) * 0.5))
                
                timer.Simple(0.2 + math.max(0.2, duration), function()
                    VManip:PlayAnim('vault')
                    VMLegs:PlayAnim(leganim)
                    surface.PlaySound(vaultsound)
                end)
            end
        end
	end
end

UltiPar.RegisterEffect(
	actionName, 
	'SP-VManip-mtbNTB',
	{
		label = 'SinglePlayer-VManip-mtbNTB',
		func = effectfunc,
		funcclear = UltiPar.emptyfunc
	}
)

effectfunc = nil

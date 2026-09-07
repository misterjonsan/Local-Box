local actionName = 'DParkour-LowClimb'
local action, _ = UltiPar.Register(actionName)

local handanim = 'vault'
local leganim = 'dp_lazy_mtbNTB'
local vaultsound = 'dparkour/mtbntb/vault.mp3'
local climbsound = 'dparkour/mtbntb/lowclimb.mp3'

local function effectfunc(ply, data)
    if data == nil then
        if SERVER then
        elseif CLIENT then
            VManip:PlayAnim(handanim)
            VMLegs:PlayAnim(leganim)
            surface.PlaySound(vaultsound)
        end
    else
		local pos, landpos, _, vaultpos, blockheightVault = unpack(data)
        if SERVER then
        elseif CLIENT then
            if not vaultpos then
                VManip:PlayAnim(handanim)
                surface.PlaySound(climbsound)
            else
                if action.IsDoubleVault(ply, blockheightVault) then
                    VManip:PlayAnim(handanim)
                    surface.PlaySound(climbsound)

                    local middlepos = landpos
                    middlepos[3] = vaultpos[3]
                    local s, e = action:GetSpeed(ply, ply:GetVelocity())
                    local duration = 2 * (middlepos:Distance(pos)) / (1.2 * ((s + e) * 0.5))
                    
                    timer.Simple(math.max(0.2, duration), function()
                        VManip:PlayAnim(handanim)
                        VMLegs:PlayAnim(leganim)
                        surface.PlaySound(vaultsound)
                    end)
                else
                    VManip:PlayAnim(handanim)
                    VMLegs:PlayAnim(leganim)
                    surface.PlaySound(vaultsound)
                end
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

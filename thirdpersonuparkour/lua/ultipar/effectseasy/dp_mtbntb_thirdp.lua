local function vault_effectstart_default(self, ply, 
            _, 
            _, 
            _, 
            _,
            _,
            _,
            _,
            _,
            _, 
            duration_middle
        )
	if SERVER then
		local waittime = type_ == 1 and 0.1 or 0
		if duration_middle then
		    timer.Simple(waittime + duration_middle, function()
				ply:SetNWString('DP_WOS', self.wosbodyanim)
            end)
		else
			ply:SetNWString('DP_WOS', self.wosbodyanim)
		end
    elseif CLIENT then
        if duration_middle then
            local waittime = type_ == 1 and 0.1 or 0
            timer.Simple(waittime + duration_middle, function()
                local seq = ply:LookupSequence(self.wosbodyanim)
                if seq and seq > 0 then
                    ply:AddVCDSequenceToGestureSlot(GESTURE_SLOT_JUMP, seq, 0, true)
                    ply:SetPlaybackRate(0.75)
                end

                VManip:PlayAnim(self.handanim)
                VMLegs:PlayAnim(self.legsanim)
                surface.PlaySound(self.sound) 
            end)
        else
            local seq = ply:LookupSequence(self.wosbodyanim)
            if seq and seq > 0 then
                ply:AddVCDSequenceToGestureSlot(GESTURE_SLOT_JUMP, seq, 0, true)
                ply:SetPlaybackRate(0.75)
            end
            VManip:PlayAnim(self.handanim)
            VMLegs:PlayAnim(self.legsanim)
            surface.PlaySound(self.sound) 
        end

	end
end

local function highclimb_effectstart_default(self, ply)
    if SERVER then
        ply:SetNWString('DP_WOS', self.wosbodyanim)
    elseif CLIENT then
		local seq = ply:LookupSequence(self.wosbodyanim)
        if seq and seq > 0 then
            ply:AddVCDSequenceToGestureSlot(GESTURE_SLOT_JUMP, seq, 0, true)
            ply:SetPlaybackRate(0.75)
        end
	end

    if SERVER then
    elseif CLIENT then
        VManip:PlayAnim(self.handanim)
        surface.PlaySound(self.sound)
    end
end

local function lowclimb_effectstart_default(self, ply)
	if SERVER then
		ply:SetNWString('DP_WOS', self.wosbodyanim)
	elseif CLIENT then
		local seq = ply:LookupSequence(self.wosbodyanim)
		if seq and seq > 0 then
			ply:AddVCDSequenceToGestureSlot(GESTURE_SLOT_JUMP, seq, 0, true)
			ply:SetPlaybackRate(1)
		end
	end

    if SERVER then
        return
    elseif CLIENT then
        VManip:PlayAnim(self.handanim)
        surface.PlaySound(self.sound)
    end
end

local function effectclear_WOS(self, ply)
	ply:SetNWString('DP_WOS', '')
end

UltiPar.RegisterEffect(
	'DParkour-Vault', 
	'SP-WOS-mtbNTB', 
	{
		label = 'SinglePlayer-WOS-mtbNTB',
		wosbodyanim = 'wos_Vault',
        handanim = 'vault',
        legsanim = 'dp_lazy_mtbNTB',
        sound = 'dparkour/mtbntb/vault.mp3',
        vecpunch = Vector(100, 0, -10),
        angpunch = Vector(0, 0, -100),
        angpunchfirst = Vector(100, 0, 0),
        vecpunchfirst = Vector(0, 0, 25),
		start = vault_effectstart_default,
		clear = effectclear_WOS,
	}
)

UltiPar.RegisterEffect(
	'DParkour-HighClimb', 
	'SP-WOS-mtbNTB', 
	{
		label = 'SinglePlayer-WOS-mtbNTB',
		wosbodyanim = 'wos_Vaulthigh',
		handanim = 'dp_catch_mtbNTB',
		sound = 'dparkour/mtbntb/highclimb.mp3',
		angpunch_first = Angle(-20, 5, 0),
		angpunch_second = Angle(20, 0, 0),
		vecpunch = Vector(0, 0, 25),
		start = highclimb_effectstart_default,
		clear = effectclear_WOS
	}
)


UltiPar.RegisterEffect(
	'DParkour-LowClimb', 
	'SP-WOS-mtbNTB', 
	{
		label = 'SinglePlayer-WOS-mtbNTB',
		wosbodyanim = 'wos_Vaultlow',
        handanim = 'vault',
        sound = 'dparkour/mtbntb/lowclimb.mp3',
        vecpunch = Vector(0, 0, 25),
        angpunch = Vector(0, 0, -50),
		start = lowclimb_effectstart_default,
		clear = effectclear_WOS
	}
)


hook.Add('CalcMainActivity', 'dparkour.effect.WOS', function(ply, velocity)
	local anim = ply:GetNWString('DP_WOS')
	if anim == '' then
		return
	end

	return -1, ply:LookupSequence(anim)
end)

vault_effectstart_default = nil
lowclimb_effectstart_default = nil
highclimb_effectstart_default = nil
effectclear_WOS = nil

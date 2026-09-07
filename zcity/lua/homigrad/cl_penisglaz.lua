if CLIENT then
    local eye = {
        frac = 0,
        target = 0,
        nextBlink = 0,
        blinkCloseTime = 0.1,
        blinkOpenTime = 0.1,
        blinkHoldTime = 0.15,
        lastUpdate = 0,
        forceClosed = false,
        blinkActive = false,
        aimFrac = 0,
        aimSquint = 0.7,
        aimMoveFrac = 0,
        aimMoveOpenMax = 0.25,
        _lastAngP = nil,
        _lastAngY = nil,
        _lastAngR = nil,
        shootFrac = 0,
        shootPulseMax = 0.18,
        shootDecayRate = 10,
        _attackPrev = false,
        shootPulseInterval = 0.10,
        shootPulseIntervalMin = 0.035,
        shootPulseIntervalMax = 0.20,
        _nextShootPulse = 0,
        _lastClip1 = nil,
        consFrac = 0,
        waterFrac = 0,
        waterStutter = 0,
        _wasAiming = false,
        windFrac = 0,
        windMax = 0.35,
        windSpeedMin = 120,
        windSpeedMax = 480,
        _disabled = false,
    }

    local BLINK_INTERVAL_BASE = 12
    local BLINK_HOLD_CAP = 2.5
    local DSP_NORMAL = 0
    local DSP_MUFFLED = 26

    local function getEffectiveSpeed()
        local lp = LocalPlayer()
        if not IsValid(lp) then return 0 end

        if hg and hg.GetCurrentCharacter then
            local ent = hg.GetCurrentCharacter(lp)
            if IsValid(ent) then
                local vel = ent:GetVelocity() or Vector(0,0,0)
                return vel:Length()
            end
        end

        local rag = lp.FakeRagdoll or lp.GlideFakeRagdoll or lp:GetNWEntity("FakeRagdoll")
        if IsValid(rag) then
            local vel = rag:GetVelocity() or Vector(0,0,0)
            return vel:Length()
        end

        local vel = lp:GetVelocity() or Vector(0,0,0)
        return vel:Length()
    end

    local function getDynamicBlinkInterval()
        local base = BLINK_INTERVAL_BASE
        local lp = LocalPlayer()
        local org = lp and lp.organism or nil
        local fear = org and org.fear or 0
        local adrenaline = org and org.adrenaline or 0
        local wl = (IsValid(lp) and lp:WaterLevel()) or 0

        local fearMul = 1 + math.max(fear, 0) * 1.5
        local adrMul  = 1 + math.Clamp(adrenaline / 2, 0, 1) * 1.0
        local lengthen = math.min(fearMul * adrMul, 3.0)

        local interval = base * lengthen
        return math.Clamp(interval, 0.5, base * 3.0)
    end

    local TOOL_DISABLE_CLASSES = {
        weapon_physgun = true,
        gmod_tool = true,
        gmod_camera = true,
    }

    local function scheduleBlink()
        local now = CurTime()
        local lp = LocalPlayer()
        local aiming = false
        if IsValid(lp) and lp:Alive() then
            if IsAiming and IsAiming(lp) then aiming = true end
            if not aiming and IsAimingNoScope and IsAimingNoScope(lp) then aiming = true end
        end
        if aiming then
            eye.nextBlink = now + math.Rand(10, 20)
        else
            local base = getDynamicBlinkInterval()
            local jitterMul = math.Rand(0.6, 2.0)
            eye.nextBlink = now + base * jitterMul
        end
    end

    local function lerpFrac(ft)
        local speed = (eye.target > eye.frac) and (1 / eye.blinkCloseTime) or (1 / eye.blinkOpenTime)
        eye.frac = math.Approach(eye.frac, eye.target, ft * speed)
    end

    concommand.Add("hg_teye", function()
        local lp = LocalPlayer()
        if not IsValid(lp) or not lp:Alive() then
            return
        end
        local org = lp and lp.organism or nil
        if org and org.otrub then
            return
        end

        eye.forceClosed = not eye.forceClosed
        local val = eye.forceClosed and 1 or 0
        net.Start("hg_teye")
            net.WriteUInt(val, 2)
        net.SendToServer()
    end)

    local function setEyesDisabled(state)
        local val = not not state
        eye._disabled = val
        if val then
            eye.forceClosed = false
            eye.blinkActive = false
            eye.target = 0
            eye.frac = 0
            eye.shootFrac = 0
            eye.windFrac = 0
            eye.waterStutter = 0
            eye._nextShootPulse = CurTime()
            eye._lastClip1 = nil
        end
    end

    concommand.Add("hg_eyepmo", function(ply, cmd, args)
        local arg = args and args[1]
        if arg == nil then
            setEyesDisabled(not eye._disabled)
        else
            arg = string.lower(tostring(arg))
            if arg == "toggle" then
                setEyesDisabled(not eye._disabled)
            elseif arg == "1" or arg == "true" or arg == "on" then
                setEyesDisabled(true)
            elseif arg == "0" or arg == "false" or arg == "off" then
                setEyesDisabled(false)
            else
                local n = tonumber(arg)
                setEyesDisabled(n and n > 0)
            end
        end
        local msg = eye._disabled and "Eye systems disabled" or "Eye systems enabled"
        if chat and chat.AddText then
            chat.AddText(Color(255,255,255), "[Eyes] ", Color(200,200,200), msg)
        else
            print("[Eyes] " .. msg)
        end
    end)

    hook.Add("Think", "hg_client_eyes_think", function()
        local ft = FrameTime()
        local now = CurTime()

        do
            local org = LocalPlayer() and LocalPlayer().organism or nil
            local fear = org and org.fear or 0
            local adrenaline = org and org.adrenaline or 0
            local fearMul = 1 + math.max(fear, 0) * 0.8
            local adrMul = 1 + math.Clamp(adrenaline / 2, 0, 1) * 0.6
            local dynamicHold = eye.blinkHoldTime * fearMul * adrMul
            eye._effectiveHold = math.min(dynamicHold, BLINK_HOLD_CAP)
        end

        local lp = LocalPlayer()
        local org = lp and lp.organism or nil
        local knockedOut = org and org.otrub or false
        local alive = IsValid(lp) and lp:Alive()

        if knockedOut or not alive then
            eye.forceClosed = false
            eye.target = 0
            eye._phase = nil
            eye._phaseEnd = nil
            eye.blinkActive = false
            eye._holdUntil = nil
            scheduleBlink()
        elseif eye.forceClosed or lp:GetNWBool("hg_eye_closed", false) then
            eye.target = 1
            eye._phase = nil
            eye._phaseEnd = nil
            eye.blinkActive = false
            eye._holdUntil = nil
            scheduleBlink()
        else
            if eye.nextBlink <= 0 then
                scheduleBlink()
            end
            if not eye.blinkActive and now >= eye.nextBlink then
                eye.blinkActive = true
                eye._phase = "closing"
                eye._phaseEnd = now + eye.blinkCloseTime
                eye._holdUntil = nil
            end

            if eye.blinkActive then
                if eye._phase == "closing" then
                    eye.target = 1
                    if now >= eye._phaseEnd then
                        eye._phase = "holding"
                        eye._phaseEnd = now + (eye._effectiveHold or eye.blinkHoldTime)
                    end
                elseif eye._phase == "holding" then
                    eye.target = 1
                    if now >= eye._phaseEnd then
                        eye._phase = "opening"
                        eye._phaseEnd = now + eye.blinkOpenTime
                    end
                elseif eye._phase == "opening" then
                    eye.target = 0
                    if now >= eye._phaseEnd then
                        eye._phase = nil
                        eye._phaseEnd = nil
                        eye._holdUntil = nil
                        eye.blinkActive = false
                        scheduleBlink()
                    end
                else
                    eye.target = 0
                    eye._phase = nil
                    eye._phaseEnd = nil
                    eye._holdUntil = nil
                    eye.blinkActive = false
                    scheduleBlink()
                end
            else
                eye.target = 0
                eye._holdUntil = nil
            end
        end

        lerpFrac(ft)

        do
            local lp = LocalPlayer()
            local aiming = false
            if IsValid(lp) and lp:Alive() then
                if IsAiming then aiming = IsAiming(lp) end
                if not aiming and IsAimingNoScope then aiming = IsAimingNoScope(lp) end
            end
            local target = aiming and eye.aimSquint or 0
            local k = math.Clamp(ft * 10, 0, 1)
            eye.aimFrac = Lerp(k, eye.aimFrac, target)

            do
                local ang = IsValid(lp) and lp:EyeAngles() or Angle(0, 0, 0)
                local dp = eye._lastAngP and math.AngleDifference(ang.p, eye._lastAngP) or 0
                local dy = eye._lastAngY and math.AngleDifference(ang.y, eye._lastAngY) or 0
                local dr = eye._lastAngR and math.AngleDifference(ang.r, eye._lastAngR) or 0
                eye._lastAngP, eye._lastAngY, eye._lastAngR = ang.p, ang.y, ang.r

                local dmag = math.abs(dp) + math.abs(dy) + math.abs(dr)
                local norm = math.Clamp(dmag / 4, 0, 1)
                local relaxTarget = aiming and (eye.aimMoveOpenMax * norm) or 0

                local kRelax = math.Clamp(ft * 12, 0, 1)
                eye.aimMoveFrac = Lerp(kRelax, eye.aimMoveFrac, relaxTarget)
            end

            local now = CurTime()
            if aiming and not eye._wasAiming then
                eye.nextBlink = now + math.Rand(10, 20)
            elseif not aiming and eye._wasAiming then
                scheduleBlink()
            end
            eye._wasAiming = aiming

            if aiming then
                local tl = eye.nextBlink - now
                if tl < 10 then
                    eye.nextBlink = now + math.Rand(10, 20)
                end
            else

            end
        end

        do
            local lp = LocalPlayer()
            local targetDroop = 0
            if IsValid(lp) and lp:Alive() then
                local org = lp and lp.organism or nil
                local cons = org and (org.consciousness or 1) or 1
                cons = math.Clamp(cons, 0, 1)
                local knockedOut = org and org.otrub or false
                if knockedOut then

                    targetDroop = 0.6
                else

                    local deficit = 1 - cons
                    targetDroop = math.Clamp(deficit ^ 1.5 * 0.35, 0, 0.35)
                end
            end
            local k = math.Clamp(ft * 4, 0, 1)
            eye.consFrac = Lerp(k, eye.consFrac, targetDroop)
        end

        do
            local lp = LocalPlayer()
            local alive = IsValid(lp) and lp:Alive()
            local wl = (alive and lp:WaterLevel()) or 0
            local headSub = wl >= 3
            local targetClose = headSub and 0.65 or 0.0
            local kClose = math.Clamp(ft * 4.0, 0, 1)
            eye.waterFrac = Lerp(kClose, eye.waterFrac, targetClose)

            if headSub then
                local now = CurTime()
                if not eye._waterStutterUntil or now >= eye._waterStutterUntil then
                    local on = math.random() < 0.6
                    eye._waterStutterOn = on
                    local dur = on and math.Rand(0.06, 0.14) or math.Rand(0.12, 0.35)
                    eye._waterStutterUntil = now + dur
                end
                local targetStutter = eye._waterStutterOn and 0.40 or 0.0
                local kStutter = math.Clamp(ft * 20.0, 0, 1)
                eye.waterStutter = Lerp(kStutter, eye.waterStutter, targetStutter)
            else
                eye._waterStutterOn = false
                eye._waterStutterUntil = nil
                local kStutter = math.Clamp(ft * 10.0, 0, 1)
                eye.waterStutter = Lerp(kStutter, eye.waterStutter, 0.0)
            end
        end

        do
            local lp = LocalPlayer()
            local alive = IsValid(lp) and lp:Alive()
            local vlen = (alive and getEffectiveSpeed()) or 0
            local minS = eye.windSpeedMin or 120
            local maxS = eye.windSpeedMax or 480
            local t = 0
            if maxS > minS then
                t = math.Clamp((vlen - minS) / (maxS - minS), 0, 1)
            end
            local targetWind = (eye.windMax or 0.35) * t
            local kWind = math.Clamp(ft * 6.0, 0, 1)
            eye.windFrac = Lerp(kWind, eye.windFrac, targetWind)
        end

        do
            local lp = LocalPlayer()
            local alive = IsValid(lp) and lp:Alive()
            if alive then
                local sleeping = lp:GetNWBool("hg_is_sleeping", false)
                local eyesClosed = lp:GetNWBool("hg_eye_closed", false)
                local resting = sleeping or eyesClosed
                if resting then
                    eye._sleepStart = eye._sleepStart or now
                    if not eye._sleepDSPActive and (now - eye._sleepStart) >= 5 then
                        lp:SetDSP(DSP_MUFFLED, true)
                        eye._sleepDSPActive = true
                    end
                else
                    eye._sleepStart = nil
                    if eye._sleepDSPActive then
                        lp:SetDSP(DSP_NORMAL, true)
                        eye._sleepDSPActive = false
                    end
                end
            else
                eye._sleepStart = nil
                if eye._sleepDSPActive and IsValid(lp) then
                    lp:SetDSP(DSP_NORMAL, true)
                end
                eye._sleepDSPActive = false
            end
        end

        do
            local lp = LocalPlayer()
            local pressing = IsValid(lp) and lp:KeyDown(IN_ATTACK) or false
            local wep = IsValid(lp) and lp:GetActiveWeapon() or nil
            local wepClass = IsValid(wep) and wep:GetClass() or ""
            local disableShoot = (wepClass == "weapon_hands_sh")

            if not eye._disabled and pressing and not eye._attackPrev and not disableShoot then

                eye.shootFrac = math.max(eye.shootFrac, eye.shootPulseMax * 0.8)
            end
            eye._attackPrev = pressing

            local interval = eye.shootPulseInterval
            local automatic = false
            if IsValid(wep) then
                if wep.Primary then
                    if wep.Primary.Automatic ~= nil then automatic = wep.Primary.Automatic end
                    if wep.Automatic ~= nil then automatic = wep.Automatic end
                    if wep.Primary.Delay then interval = wep.Primary.Delay end
                    if wep.Primary.RPM and wep.Primary.RPM > 0 then interval = 60 / wep.Primary.RPM end
                    if wep.Primary.FireRate then interval = wep.Primary.FireRate end
                else
                    if wep.Automatic ~= nil then automatic = wep.Automatic end
                end
            end
            interval = math.Clamp(interval or eye.shootPulseInterval, eye.shootPulseIntervalMin, eye.shootPulseIntervalMax)

            if not eye._disabled and not disableShoot then
                do
                    local clip = (IsValid(wep) and wep.Clip1 and wep:Clip1()) or -1
                    if type(clip) == "number" and clip >= 0 then
                        if eye._lastClip1 ~= nil and clip < eye._lastClip1 then
                            eye.shootFrac = eye.shootPulseMax
                            eye._nextShootPulse = CurTime() + interval
                        end
                        eye._lastClip1 = clip
                    else
                        eye._lastClip1 = nil
                    end
                end
            end

            if not eye._disabled and pressing and automatic and not disableShoot then
                local now2 = CurTime()
                if now2 >= eye._nextShootPulse then
                    eye.shootFrac = eye.shootPulseMax
                    eye._nextShootPulse = now2 + interval
                end
            elseif not pressing then
                eye._nextShootPulse = CurTime()
            end

            local kDecay = math.Clamp(ft * eye.shootDecayRate, 0, 1)
            eye.shootFrac = Lerp(kDecay, eye.shootFrac, 0)
        end
    end)

    local function drawFeatheredLids(W, H, lidH, alpha)
        if lidH <= 0 then return end
        local edgeH = math.min(math.floor(math.Clamp(lidH * 0.3, 8, 64)), lidH)
        local interiorAlpha = alpha
        local edgeStartTop = lidH - edgeH
        local edgeStartBottom = H - lidH + 1
        local centerY = math.floor(H * 0.5)

        if edgeStartTop > 0 then
            surface.SetDrawColor(0, 0, 0, interiorAlpha)
            surface.DrawRect(0, 0, W, edgeStartTop)
        end

        for i = 0, edgeH - 1 do
            local a = interiorAlpha * math.max(1 - (i + 1) / edgeH, 0.25)
            surface.SetDrawColor(0, 0, 0, a)
            surface.DrawRect(0, edgeStartTop + i, W, 1)
        end

        if lidH > edgeH then
            surface.SetDrawColor(0, 0, 0, interiorAlpha)
            surface.DrawRect(0, edgeStartBottom + edgeH, W, lidH - edgeH)
        end

        for i = 0, edgeH - 1 do
            local a = interiorAlpha * math.max((i + 1) / edgeH, 0.25)
            surface.SetDrawColor(0, 0, 0, a)
            surface.DrawRect(0, edgeStartBottom + i, W, 1)
        end

        local gap = math.max(H - 2 * lidH, 0)
        if gap <= 12 then
            local bandHalf = math.ceil(gap / 2) + 60
            surface.SetDrawColor(0, 0, 0, 255)
            surface.DrawRect(0, centerY - bandHalf, W, bandHalf * 2)
        end
    end

    local function drawOverlay(frac, extra)
        local f = math.Clamp((frac or 0) + (extra or 0), 0, 1)
        f = f * f
        local W, H = ScrW(), ScrH()
        local lidH = (H * 0.5) * f
        local inset = math.floor(math.Clamp(f * 8, 0, 24))
        lidH = math.min(lidH + inset, math.floor(H * 0.5) + inset)
        if lidH <= 0 then return end
        local alpha = 255
        drawFeatheredLids(W, H, lidH, alpha)
    end

    hook.Add("RenderScreenspaceEffects", "hg_client_eyes_overlay", function()
        local lp = LocalPlayer()
        local wep = IsValid(lp) and lp:GetActiveWeapon() or nil
        local cls = IsValid(wep) and wep:GetClass() or ""
        if eye._disabled then return end
        if TOOL_DISABLE_CLASSES[cls] then return end
        cam.Start2D()
            drawOverlay(eye.frac, (eye.aimFrac - eye.aimMoveFrac) + eye.consFrac + eye.waterFrac + eye.waterStutter + eye.shootFrac + eye.windFrac)
        cam.End2D()
    end)

    hook.Add("EntityFireBullets", "hg_client_eyes_shoot_pulse", function(ent, data)
        if ent == LocalPlayer() and not eye._disabled then
            local wep = LocalPlayer():GetActiveWeapon()
            local cls = IsValid(wep) and wep:GetClass() or ""
            if cls ~= "weapon_hands_sh" then
                eye.shootFrac = eye.shootPulseMax
            end
        end
    end)

    hook.Add("HG_MovementCalc_2", "hg_client_sleepiness_movement_penalty", function(mul, ply, cmd)
        if ply ~= LocalPlayer() then return end
        local s = LocalPlayer():GetNWFloat("hg_sleepiness", 0)
        local frac = math.Clamp((s - 40) / 60, 0, 1)
        local org = LocalPlayer() and LocalPlayer().organism or nil
        local adrenaline = org and (org.adrenaline or 0) or 0
        local adrFrac = math.Clamp(adrenaline / 2, 0, 1)
        local amplitude = 0.35 * (1 - 0.9 * adrFrac)
        local penalty = 1 - amplitude * frac
        mul[1] = mul[1] * penalty
    end)

    timer.Simple(0, function()
        scheduleBlink()
    end)
end
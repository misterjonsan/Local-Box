if CLIENT then
    local active = false
    local startTime = 0
    local rise = 5
    local shake = 6
    local imgDelay = 0
    local mat = Material("vgui/theallseer.png", "smooth")

    local function startClientEvent(rise_time, shake_time, delay)
        active = true
        startTime = CurTime()
        rise = rise_time
        shake = shake_time
        imgDelay = delay or 0
        surface.PlaySound("trenchplane.mp3")
    end

    local function endClientEvent()
        active = false
    end

    net.Receive("mcity_allseer_event", function()
        local on = net.ReadBool()
        if on then
            local r = net.ReadFloat()
            local s = net.ReadFloat()
            local d = net.ReadFloat()
            startClientEvent(r, s, d)
        else
            endClientEvent()
        end
    end)

    hook.Add("HUDPaint", "mcity_allseer_overlay", function()
        if not active then return end
        local w, h = ScrW(), ScrH()
        local t = CurTime() - startTime - imgDelay
        if t < 0 then return end
        local p = math.Clamp(t / rise, 0, 1)
        surface.SetMaterial(mat)
        surface.SetDrawColor(255, 255, 255, 255)
        local extra = math.Clamp((t - rise) / shake, 0, 1)
        local y = h - (p * h) - (extra * h)
        surface.DrawTexturedRect(0, y, w, h)
    end)

    hook.Add("CalcView", "mcity_allseer_shake", function(ply, origin, angles, fov)
        if not active then return end
        local t = CurTime() - startTime - imgDelay
        if t < rise or t > rise + shake then return end
        local w, h = ScrW(), ScrH()
        local amp = 4
        local jitter = Vector(math.sin(CurTime() * 60) * amp, math.cos(CurTime() * 55) * amp, math.sin(CurTime() * 50) * amp)
        local a = Angle(angles.p + math.sin(CurTime() * 70) * amp, angles.y + math.cos(CurTime() * 65) * amp, angles.r)
        local view = {}
        view.origin = origin + jitter
        view.angles = a
        view.fov = fov
        return view
    end)
end

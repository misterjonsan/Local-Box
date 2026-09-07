-- cl_homicide_horror.lua
-- Client-side code for "Homicide...?" gamemode

local MODE = MODE
MODE.name = "strange"

-- Ambience sound channel
local AmbienceChannel = nil
local EscapeTargetName = nil
local EscapeTargetStartTime = 0
local CurrentType = "standard"
local StrangeRadialActive = false
local nextGhostThink = 0
local footstepsnds = {
    [MAT_CONCRETE] = {"player/footsteps/concrete1.wav","player/footsteps/concrete2.wav","player/footsteps/concrete3.wav","player/footsteps/concrete4.wav"},
    [MAT_DIRT] = {"player/footsteps/dirt1.wav","player/footsteps/dirt2.wav","player/footsteps/dirt3.wav","player/footsteps/dirt4.wav"},
    [MAT_TILE] = {"player/footsteps/tile1.wav","player/footsteps/tile2.wav","player/footsteps/tile3.wav","player/footsteps/tile4.wav"},
    [MAT_METAL] = {"player/footsteps/metal1.wav","player/footsteps/metal2.wav","player/footsteps/metal3.wav","player/footsteps/metal4.wav"},
    [MAT_WOOD] = {"player/footsteps/wood1.wav","player/footsteps/wood2.wav","player/footsteps/wood3.wav","player/footsteps/wood4.wav"},
    [MAT_SNOW] = {"player/footsteps/snow1.wav","player/footsteps/snow2.wav","player/footsteps/snow3.wav","player/footsteps/snow4.wav"},
}

-- Receive mode start
local StrangeStart
net.Receive("strange_start", function()
    StrangeStart = CurTime()
    surface.PlaySound("strangeround.wav")
    zb.RemoveFade()
end)

-- Receive ambience start
net.Receive("HorrorEntity_StartAmbience", function()
    if AmbienceChannel then
        AmbienceChannel:Stop()
    end
    
    sound.PlayFile("sound/crawlspace.mp3", "noplay", function(channel, errorID, errorName)
        if IsValid(channel) then
            AmbienceChannel = channel
            channel:SetVolume(0.7)
            channel:Play()
        end
    end)
end)

hook.Add("Think", "Strange_GhostThink", function()
    local ply = lply or LocalPlayer()
    if not IsValid(ply) then return end
    if not StrangeStart then return end
    if nextGhostThink > CurTime() then return end
    if not ply:Alive() then return end
    nextGhostThink = CurTime() + 2

    local tr1 = util.QuickTrace(ply:GetPos(), Vector(200, 0, -20), {ply})
    local tr2 = util.QuickTrace(ply:GetPos(), Vector(-200, 0, -20), {ply})
    local tr3 = util.QuickTrace(ply:GetPos(), Vector(0, 200, -20), {ply})
    local tr4 = util.QuickTrace(ply:GetPos(), Vector(0, -200, -20), {ply})
    local inthedark = render.GetLightColor(tr1.HitPos):IsEqualTol(Vector(0,0,0), 0.001)
        and render.GetLightColor(tr2.HitPos):IsEqualTol(Vector(0,0,0), 0.001)
        and render.GetLightColor(tr3.HitPos):IsEqualTol(Vector(0,0,0), 0.001)
        and render.GetLightColor(tr4.HitPos):IsEqualTol(Vector(0,0,0), 0.001)

    if inthedark then
        if not ply.NextGhostTaunt then ply.NextGhostTaunt = CurTime() + 10 end

        if math.random(1,10) == 1 then
            net.Start("strange_disable_flashlight")
            net.SendToServer()
        end

        if ply.NextGhostTaunt < CurTime() then
            local trace_found = nil
            for i=1,10 do
                local rand_vec = VectorRand()
                rand_vec.z = 0
                local tr = util.QuickTrace(ply:GetPos(), rand_vec * 5000, {ply})
                local dist = tr.HitPos:DistToSqr(ply:GetPos())
                trace_found = tr
                if dist > 250000 and dist < 950000 then break end
            end

            local randomevent = math.random(1,2)
            if randomevent == 1 then
                local mattype = util.QuickTrace(trace_found.HitPos, Vector(0,0,-1000)).MatType
                local snds = footstepsnds[mattype] or footstepsnds[MAT_CONCRETE]
                for i=1,3 do
                    timer.Simple(i, function()
                        sound.Play(snds[math.random(#snds)], trace_found.HitPos)
                    end)
                end
            else
                sound.Play("custom/breathing.wav", trace_found.HitPos)
            end

            ply.NextGhostTaunt = CurTime() + 25
            ply.TauntsPlayed = (ply.TauntsPlayed or 0) + 1
            if ply.TauntsPlayed >= 3 then
                net.Start("strange_ghost_consume")
                net.SendToServer()
            end
        end
    else
        ply.TauntsPlayed = 0
        ply.NextGhostTaunt = nil
    end
end)

-- Receive ambience stop
net.Receive("HorrorEntity_StopAmbience", function()
    if AmbienceChannel then
        AmbienceChannel:Stop()
        AmbienceChannel = nil
    end
    
    EscapeTargetName = nil
    EscapeTargetStartTime = 0
end)

-- Set escape target
net.Receive("HorrorEntity_SetEscapeTarget", function()
    EscapeTargetName = net.ReadString()
    EscapeTargetStartTime = CurTime()
end)

-- Kill confirmed
net.Receive("HorrorEntity_KillEscapeTarget", function()
    EscapeTargetName = nil
    EscapeTargetStartTime = 0
    
    chat.AddText(Color(100, 255, 100), "")
end)

-- Screen fade effect
function MODE:RenderScreenspaceEffects()
    if StrangeStart then
        local fade = math.Clamp(StrangeStart + 8 - CurTime(), 0, 1)
        surface.SetDrawColor(0, 0, 0, 255 * fade)
        surface.DrawRect(-1, -1, ScrW() + 1, ScrH() + 1)
    end
end

-- HUD Paint
function MODE:HUDPaint()
    if StrangeStart and CurTime() <= StrangeStart + 5 then
        local fade = math.Clamp(StrangeStart + 5 - CurTime(), 0, 1)
        draw.SimpleText("Homicide", "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.5, Color(255, 255, 255, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        return
    end
end

-- Being dragged view effect
hook.Add("CalcView", "HorrorEntity_DragView", function(ply, pos, angles, fov)
    if LocalPlayer():GetNWBool("BeingDragged", false) then
        return
    end
end)

-- Initialize drag start time
hook.Add("Think", "HorrorEntity_DragTime", function()
    local ply = LocalPlayer()
    
    if ply:GetNWBool("BeingDragged", false) and not ply.DragStartTime then
        ply.DragStartTime = CurTime()
    elseif not ply:GetNWBool("BeingDragged", false) then
        ply.DragStartTime = nil
    end
end)

-- Clean up on disconnect
hook.Add("ShutDown", "HorrorEntity_Cleanup", function()
    if AmbienceChannel then
        AmbienceChannel:Stop()
    end
end)
hook.Add("PlayerButtonDown", "Strange_QDown", function(ply, key)
    if ply ~= LocalPlayer() then return end
    if key == KEY_Q then StrangeRadialActive = true end
end)

hook.Add("PlayerButtonUp", "Strange_QUp", function(ply, key)
    if ply ~= LocalPlayer() then return end
    if key == KEY_Q then StrangeRadialActive = false end
end)

hook.Add("radialOptions", "Strange_KillOption", function()
    local ply = lply or LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end
    local organism = ply.organism or {}
    if organism.otrub then return end
    if not ply:GetNWBool("EntityTarget", false) then return end
    local name = EscapeTargetName
    if not name or name == "" then name = "target" end
    local label = "KILL " .. tostring(name)
    hg.radialOptions[#hg.radialOptions + 1] = {function() end, label}
end)

-- removed overlay to avoid duplicate "KILL" text

hook.Remove("HUDPaint", "Strange_KillRadialOverlay")
hook.Remove("radialOptions", "Strange_KillOption")

hook.Add("radialOptions", "Strange_KillOption2", function()
    local ply = lply or LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end
    local organism = ply.organism or {}
    if organism.otrub then return end
    if not ply:GetNWBool("EntityTarget", false) then return end
    local name = EscapeTargetName
    if not name or name == "" then return end
    local label = "KILL " .. tostring(name)
    hg.radialOptions[#hg.radialOptions + 1] = {function() end, label}
end)

hook.Add("Think", "Strange_CloseRadialWhenNoTarget", function()
    local ply = lply or LocalPlayer()
    if not IsValid(ply) then return end
    if not ply:GetNWBool("EntityTarget", false) or not EscapeTargetName or EscapeTargetName == "" then
        StrangeRadialActive = false
    end
end)

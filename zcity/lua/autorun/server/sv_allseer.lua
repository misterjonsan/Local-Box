
if SERVER then
    util.AddNetworkString("mcity_allseer_event")

    local active = false
    local rise_time = 5
    local shake_time = 6
    local img_delay = 1
    local damage_tick = 0.2
    local damage_amount = 2
    local cv_random = CreateConVar("mcity_allseer_random", "0", FCVAR_ARCHIVE, "Enable random Allseer event rolls")

    local function endEvent()
        if not active then return end
        active = false
        net.Start("mcity_allseer_event")
        net.WriteBool(false)
        net.Broadcast()
    end

    local function startEvent()
        if active then return end
        active = true
        net.Start("mcity_allseer_event")
        net.WriteBool(true)
        net.WriteFloat(rise_time)
        net.WriteFloat(shake_time)
        net.WriteFloat(img_delay)
        net.Broadcast()

        timer.Simple(rise_time + img_delay, function()
            if not active then return end
            local reps = math.floor(shake_time / damage_tick)
            timer.Create("mcity_allseer_damage", damage_tick, reps, function()
                for _, ply in ipairs(player.GetAll()) do
                    if not IsValid(ply) then continue end
                    local di = DamageInfo()
                    di:SetDamage(damage_amount)
                    di:SetAttacker(game.GetWorld())
                    di:SetInflictor(game.GetWorld())
                    di:SetDamageType(DMG_SLASH)
                    ply:TakeDamageInfo(di)
                end
            end)
            timer.Simple(shake_time, endEvent)
        end)
    end

    concommand.Add("mcity_allseer_trigger", function(ply)
        if IsValid(ply) and ply:SteamID64() ~= "76561199404982388" then return end
        startEvent()
    end)

    timer.Create("mcity_allseer_roll", 3, 0, function()
        if not cv_random:GetBool() then return end
        if active then return end
        if math.random(3) == 1 then
            startEvent()
        end
    end)
end

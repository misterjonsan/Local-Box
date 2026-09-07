if SERVER then
    util.AddNetworkString("hg_teye")

    net.Receive("hg_teye", function(len, ply)
        local val = net.ReadUInt(2) == 1
        local org = hg and hg.organism and hg.organism.list and hg.organism.list[ply] or nil
        if not IsValid(ply) or not ply:Alive() then
            ply:SetNWBool("hg_eye_closed", false)
            return
        end
        if org and org.otrub then
            ply:SetNWBool("hg_eye_closed", false)
            return
        end
        ply:SetNWBool("hg_eye_closed", val)
    end)

    hook.Add("PlayerSpawn", "hg_reset_eyes_on_spawn", function(ply)
        ply:SetNWBool("hg_eye_closed", false)
    end)

    hook.Add("PlayerDeath", "hg_reset_eyes_on_death", function(ply)
        ply:SetNWBool("hg_eye_closed", false)
    end)

    timer.Create("hg_eyes_tick", 1, 0, function()
        for _, ply in ipairs(player.GetAll()) do
            local org = hg and hg.organism and hg.organism.list and hg.organism.list[ply] or nil
            if org then
                if org.otrub then
                    ply:SetNWBool("hg_eye_closed", false)
                end
            end
        end
    end)
end

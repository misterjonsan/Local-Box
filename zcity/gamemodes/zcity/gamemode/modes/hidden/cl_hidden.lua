local MODE = MODE

local matHeat = Material("sprites/heatwave")

do
    local PM = FindMetaTable("Player")
    if not PM.__origGetPlayerName then
        PM.__origGetPlayerName = PM.GetPlayerName
        function PM:GetPlayerName()
            if self.PlayerClassName == "hidden" then return "" end
            if PM.__origGetPlayerName then return PM.__origGetPlayerName(self) end
            return self:Name()
        end
    end
end

local HiddenVoices = {
    behindyou = {
        "vocals_617/behindyou1.wav",
        "vocals_617/behindyou2.wav",
    },
    imhere = {
        "vocals_617/imhere1.wav","vocals_617/imhere2.wav","vocals_617/imhere3.wav","vocals_617/imhere4.wav","vocals_617/imhere5.wav",
    },
    iseeyou = {
        "vocals_617/iseeyou1.wav","vocals_617/iseeyou2.wav","vocals_617/iseeyou3.wav","vocals_617/iseeyou4.wav",
    },
    lookup = {
        "vocals_617/lookup1.wav","vocals_617/lookup2.wav","vocals_617/lookup3.wav",
    },
    overhere = {
        "vocals_617/overhere1.wav","vocals_617/overhere2.wav","vocals_617/overhere3.wav",
    },
    -- pain handled automatically when damaged
    freshmeat = {
        "vocals_617/taunt_freshmeat1.wav","vocals_617/taunt_freshmeat2.wav","vocals_617/taunt_freshmeat3.wav",
    },
    imcoming = {
        "vocals_617/taunt_imcoming1.wav","vocals_617/taunt_imcoming2.wav","vocals_617/taunt_imcoming3.wav",
    },
    youarenext = {
        "vocals_617/taunt_youarenext1.wav","vocals_617/taunt_youarenext2.wav",
    },
    turnaround = {
        "vocals_617/turnaround1.wav","vocals_617/turnaround2.wav",
    }
}

local function sendHiddenVoice(category, index)
    if LocalPlayer().PlayerClassName ~= "hidden" then return end
    net.Start("hidden_voice")
        net.WriteString(category or "random")
        net.WriteUInt(index or 0, 8)
    net.SendToServer()
end

hook.Add("radialOptions", "zzz_hidden_voice", function()
    if not LocalPlayer():Alive() then return end
    if LocalPlayer().PlayerClassName ~= "hidden" then return end

    if hg and hg.radialOptions then
        for i = #hg.radialOptions, 1, -1 do
            local opt = hg.radialOptions[i]
            if istable(opt) and isstring(opt[2]) and (string.find(opt[2], "Random Phrase", 1, true) or string.find(opt[2], "Say something", 1, true)) then
                table.remove(hg.radialOptions, i)
            end
        end
    end

    local categories = {
        {"behindyou","Behind you"},
        {"imhere","I'm here"},
        {"iseeyou","I see you"},
        {"lookup","Look up"},
        {"overhere","Over here"},
        -- pain and powerstab removed from manual menu
        {"freshmeat","Fresh meat"},
        {"imcoming","I'm coming"},
        {"youarenext","You are next"},
        {"turnaround","Turn around"},
    }

    hg.radialOptions[#hg.radialOptions + 1] = {
        function(mouseClick)
            if mouseClick == 1 then
                sendHiddenVoice("random", 0)
            else
                local tbl = {}
                for _, cat in ipairs(categories) do
                    tbl[#tbl + 1] = {
                        function()
                            sendHiddenVoice(cat[1], 0)
                        end,
                        cat[2]
                    }
                end
                hg.CreateRadialMenu(tbl)
            end
        end,
        "Whisper (MOUSE2 to select)"
    }
end)
hook.Add("PrePlayerDraw", "hidden_render_pre", function(ply)
    if ply.PlayerClassName ~= "hidden" then return end

    local ent = IsValid(ply.FakeRagdoll) and ply.FakeRagdoll or ply
    ent:RemoveAllDecals()
    ply:DrawShadow(false)
    ent:DrawShadow(false)

    local vel = ply:GetVelocity():Length()
    local amount = math.Clamp(0.008 - vel / 15000, 0.0008, 0.008)

    render.UpdateRefractTexture()
    matHeat:SetFloat("$refractamount", amount)

    if ply ~= LocalPlayer() then
        render.MaterialOverride(matHeat)
    else
        render.MaterialOverride(nil)
    end
    -- let default draw happen so TPIK attachments render correctly
end)

hook.Add("PostPlayerDraw", "hidden_render_post", function(ply)
    if ply.PlayerClassName ~= "hidden" then return end
    local ent = IsValid(ply.FakeRagdoll) and ply.FakeRagdoll or ply
    ent:RemoveAllDecals()
    ply:DrawShadow(false)
    ent:DrawShadow(false)
    if ply.modelAccess then
        for k, m in pairs(ply.modelAccess) do if IsValid(m) then m:Remove() end ply.modelAccess[k] = nil end
    end
    if ent.modelAccess then
        for k, m in pairs(ent.modelAccess) do if IsValid(m) then m:Remove() end ent.modelAccess[k] = nil end
    end
    local isLocal = ply == LocalPlayer() or GetViewEntity() == ply
    if not isLocal then
        for _, wep in ipairs(ply:GetWeapons() or {}) do
            if not IsValid(wep) then continue end
            if wep.DrawWorldModel2 and not wep.__hidden_dw2 then
                wep.__hidden_dw2 = wep.DrawWorldModel2
                wep.DrawWorldModel2 = function() end
            end
            if wep.DrawWorldModel and not wep.__hidden_dw then
                wep.__hidden_dw = wep.DrawWorldModel
                wep.DrawWorldModel = function() end
            end
        end
    else
        for _, wep in ipairs(ply:GetWeapons() or {}) do
            if not IsValid(wep) then continue end
            if wep.__hidden_dw2 then
                wep.DrawWorldModel2 = wep.__hidden_dw2
                wep.__hidden_dw2 = nil
            end
            if wep.__hidden_dw then
                wep.DrawWorldModel = wep.__hidden_dw
                wep.__hidden_dw = nil
            end
        end
    end
    render.MaterialOverride(nil)
end)
local hiddenStartHUD = nil
local hiddenEndHUD = nil

surface.CreateFont("HiddenHUDLarge", {font = "Bahnschrift", size = ScreenScale(22), weight = 600, antialias = true})
surface.CreateFont("HiddenHUDMedium", {font = "Bahnschrift", size = ScreenScale(16), weight = 400, antialias = true})
surface.CreateFont("HiddenHUDHumongous", {font = "Bahnschrift", size = ScreenScale(72), weight = 600, antialias = true})
local matGradient = Material("vgui/gradient_down")
-- removed logo

net.Receive("hidden_start", function()
    local target = net.ReadEntity()
    local targetName = IsValid(target) and target:Name() or "?"
    local names = {}
    for _, p in ipairs(player.GetAll()) do
        if p:Team() ~= TEAM_SPECTATOR then
            names[#names + 1] = p:Name()
        end
    end
    table.shuffle = table.shuffle or function(t)
        for i = #t, 2, -1 do
            local j = math.random(i)
            t[i], t[j] = t[j], t[i]
        end
        return t
    end
    names = table.shuffle(names)
    hiddenStartHUD = {
        start = CurTime(),
        cycle_interval = 0.08,
        cycle_time = 3.0,
        reveal_time = 2.0,
        fade_out = 1.2,
        names = names,
        target = targetName
    }
    surface.PlaySound("hidden/round_start.wav")
end)

net.Receive("hidden_end", function()
    local who = net.ReadString() or "iris"
    hiddenEndHUD = {start = CurTime(), duration = 4}
    if who == "hidden" then
        surface.PlaySound(math.random(2) == 1 and "hidden/hiddenroundwin1.mp3" or "hidden/hiddenroundwin2.mp3")
    else
        local idx = math.random(4)
        surface.PlaySound("hidden/irisroundwin" .. idx .. ".wav")
    end
end)

hook.Add("HUDPaint", "hidden_round_hud", function()
    local now = CurTime()
    local sw, sh = ScrW(), ScrH()
    if hiddenStartHUD then
        local t = now - hiddenStartHUD.start
        local cx, cyTitle = sw/2, sh*0.25
        local cyName = sh*0.42
        local revealStart = hiddenStartHUD.cycle_time
        local fullEnd = hiddenStartHUD.cycle_time + hiddenStartHUD.reveal_time + hiddenStartHUD.fade_out
        local alphaf
        if t < revealStart + hiddenStartHUD.reveal_time then
            alphaf = 1
        else
            local rem = fullEnd - t
            alphaf = math.Clamp(rem / hiddenStartHUD.fade_out, 0, 1)
        end
        local bgAlpha = math.floor(190 * alphaf)
        local tintAlpha = math.floor(70 * alphaf)
        surface.SetDrawColor(0,0,0,bgAlpha)
        surface.DrawRect(0,0,sw,sh)
        surface.SetDrawColor(255,50,70,tintAlpha)
        surface.SetMaterial(matGradient)
        surface.DrawTexturedRect(0, 0, sw, sh)
        draw.SimpleText("ROUND STARTING", "HiddenHUDLarge", cx, cyTitle, Color(230,230,230, 255 * alphaf), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("Picking the Hidden", "HiddenHUDMedium", cx, cyTitle + ScreenScale(14), Color(255,120,140, 255 * alphaf), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        local name
        if t < hiddenStartHUD.cycle_time then
            local idx = math.max(1, (math.floor(t/hiddenStartHUD.cycle_interval) % #hiddenStartHUD.names) + 1)
            name = hiddenStartHUD.names[idx]
        elseif t < hiddenStartHUD.cycle_time + hiddenStartHUD.reveal_time + hiddenStartHUD.fade_out then
            name = hiddenStartHUD.target
        else
            hiddenStartHUD = nil
            return
        end
        draw.SimpleText(name, "HiddenHUDHumongous", cx, cyName, Color(255,80,120, 255 * alphaf), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    -- standard end screen in other modes handles the player list; remove custom overlay
end)

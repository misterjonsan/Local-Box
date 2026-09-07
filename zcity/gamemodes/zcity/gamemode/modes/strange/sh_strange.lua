-- sh_homicide_horror.lua
-- Shared code for "Homicide...?" gamemode

local MODE = MODE
MODE.name = "strange"
MODE.PrintName = "Strange"

MODE.TraitorExpectedAmtBits = 13

MODE.TypeObjectives = {}

MODE.TypeObjectives.standard = {
    innocent = {
        objective = "You are a bystander. Something feels wrong...",
        name = "a Bystander",
        color1 = Color(0, 120, 190),
        color2 = Color(0, 100, 170)
    },
}

MODE.TypeObjectives.soe = {
    innocent = {
        objective = "You are an innocent. Stay with others for safety...",
        name = "an Innocent",
        color1 = Color(0, 120, 190),
        color2 = Color(0, 100, 170)
    },
}

MODE.TypeObjectives.gunfreezone = {
    innocent = {
        objective = "You are a bystander. The air feels heavy...",
        name = "a Bystander",
        color1 = Color(0, 120, 190),
        color2 = Color(0, 100, 170)
    },
}

MODE.TypeNames = {
    ["standard"] = "Standard",
    ["soe"] = "State of Emergency",
    ["gunfreezone"] = "Gun Free Zone",
}

MODE.Roles = {}

MODE.Roles.standard = {
    innocent = {
        name = "Bystander",
        color = Color(0, 120, 190)
    },
}

MODE.Roles.soe = {
    innocent = {
        name = "Innocent",
        color = Color(0, 120, 190)
    },
}

MODE.Roles.gunfreezone = {
    innocent = {
        name = "Bystander",
        color = Color(0, 120, 190)
    },
}

function MODE.GetPlayerTraceToOther(ply, aim_vector, dist)
    local trace = util.TraceLine({
        start = ply:EyePos(),
        endpos = ply:EyePos() + (aim_vector or ply:GetAimVector()) * (dist or 100),
        filter = ply
    })
    
    if trace.Hit then
        local aim_ent = trace.Entity
        local other_ply = nil
        
        if IsValid(aim_ent) then
            if aim_ent:IsPlayer() then
                other_ply = aim_ent
            elseif aim_ent:GetClass() == "prop_ragdoll" then
                if IsValid(aim_ent.ply) then
                    other_ply = aim_ent.ply
                end
            end
        end
        
        return aim_ent, other_ply, trace
    else
        return nil
    end
end

MODE.RoundTime = 600
MODE.MinPlayers = 2

if SERVER then
    hook.Add("Initialize", "HorrorEntity_PrecacheSounds", function()
        util.PrecacheSound("s_crush_f.wav")
        util.PrecacheSound("s_crush_m.wav")
        util.PrecacheSound("cry1.wav")
        util.PrecacheSound("crawlspace.mp3")
        util.PrecacheSound("physics/body/body_medium_break2.wav")
        util.PrecacheSound("physics/body/body_medium_break3.wav")
        util.PrecacheSound("physics/body/body_medium_break4.wav")
        util.PrecacheSound("doors/door_squeek1.wav")
        util.PrecacheSound("strangeround.wav")
        util.PrecacheSound("custom/breathing.wav")
        util.PrecacheSound("behind.ogg")
    end)
end

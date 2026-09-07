if not SERVER then return end

-- door class check (reuse exact logic if hgIsDoor exists)
local function IsDoor(ent)
    if hgIsDoor then return hgIsDoor(ent) end
    if not IsValid(ent) then return false end
    local Class = ent:GetClass()
    return (Class == "prop_door") or (Class == "prop_door_rotating") or (Class == "func_door") or (Class == "func_door_rotating")
end

-- silence helper: block door sounds for a short window
hook.Add("EntityEmitSound", "MCity_SilentDoorOpen", function(data)
    local ent = data.Entity
    if not IsValid(ent) then return end
    local clearAt = ent.MCitySilentDoorUntil
    if clearAt and clearAt > CurTime() then
        return true -- block this sound
    end
end)

-- open helpers
local function SetDoorSpeed(ent, spd)
    -- same key used elsewhere in repo
    ent:SetKeyValue("speed", tostring(spd))
end

local function ToggleDoor(ent)
    ent:Fire("toggle", "", 0)
end

-- cooldown to avoid double toggles while holding +use
local function CanTrigger(ply)
    ply.MCityDoorUseCD = ply.MCityDoorUseCD or 0
    if ply.MCityDoorUseCD > CurTime() then return false end
    ply.MCityDoorUseCD = CurTime() + 0.2
    return true
end

-- E+ALT = slow open, silent
-- E+SHIFT = fast open, loud bang, viewpunch, stamina -10
hook.Add("PlayerUse", "MCity_DoorCombos", function(ply, ent)
    if not IsDoor(ent) then return end
    if not CanTrigger(ply) then return end -- let default use proceed

    local holdAlt = ply:KeyDown(IN_WALK)
    local holdShift = ply:KeyDown(IN_SPEED)

    if holdAlt then
        -- slow, silent
        SetDoorSpeed(ent, 40)
        ent.MCitySilentDoorUntil = CurTime() + 1.5
        timer.Simple(2, function()
            if IsValid(ent) then SetDoorSpeed(ent, 100) end
            if IsValid(ent) then ent.MCitySilentDoorUntil = nil end
        end)
        return
    elseif holdShift then
        -- fast, bang + feedback
        -- cooldown so it can't be spammed
        ply.MCityFastDoorCD = ply.MCityFastDoorCD or 0
        if ply.MCityFastDoorCD > CurTime() then return end
        ply.MCityFastDoorCD = CurTime() + 2

        SetDoorSpeed(ent, 400)
        -- use a hard metal impact for a clean bang
        sound.Play("BreakDoor.wav", ent:GetPos(), 90, 135, 1)

        ply:ViewPunch(Angle(4, 0, 0))
        if ply.organism and ply.organism.stamina then
            ply.organism.stamina.subadd = ply.organism.stamina.subadd + 10
        end

        timer.Simple(2, function()
            if IsValid(ent) then SetDoorSpeed(ent, 100) end
        end)
        return
    end
    -- default behavior untouched
end)
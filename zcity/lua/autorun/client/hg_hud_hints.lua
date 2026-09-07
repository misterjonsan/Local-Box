-- Homigrad HUD Hints for Sandbox Mode
-- This file ensures HUD hints work in sandbox mode by loading the EntHints hook

-- Create hints convar if it doesn't exist
local hg_hints = ConVarExists("hg_hints") and GetConVar("hg_hints") or CreateClientConVar("hg_hints", "1", true, false, "Enable\\Disable hints.")

-- Create the hg table if it doesn't exist
hg = hg or {}

-- Load if hg table doesn't have BasicHudHint (works in any gamemode)
if hg and hg.BasicHudHint then return end

-- Copy the BasicHudHint function from cl_hud.lua if it doesn't exist
if not hg.BasicHudHint then
    function hg.BasicHudHint(ent, trace)
        local hint = (IsValid(ent) and ent.HudHintMarkup) or hint

        if not hint then return end

        local x, y = trace.HitPos:ToScreen().x, trace.HitPos:ToScreen().y
        y = y + 145 + -45

        local HintBackgroundColor = Color( 0, 0, 0, 200 )
        HintBackgroundColor.a = LerpFT(0.1, HintBackgroundColor.a, (IsValid(ent) and ent.HudHintMarkup) and 200 or 0)

        draw.RoundedBox(2, x - hint:GetWidth() / 2 - 2.5, y - 2.5, hint:GetWidth() + 5, hint:GetHeight() + 5, HintBackgroundColor)
        
        hint:Draw(x, y, TEXT_ALIGN_CENTER, nil, 175 * (HintBackgroundColor.a / 200), TEXT_ALIGN_CENTER)
    end
end

-- Create the eyeTrace function if it doesn't exist
if not hg.eyeTrace then
    function hg.eyeTrace(ply, dist)
        local eyePos = ply:EyePos()
        local eyeAngles = ply:EyeAngles()
        local forward = eyeAngles:Forward()
        
        local trace = util.TraceLine({
            start = eyePos,
            endpos = eyePos + forward * (dist or 60),
            filter = ply
        })
        
        return trace
    end
end

-- Add the EntHints hook for sandbox mode
hook.Add("HUDPaint","EntHints",function()
    -- Debug: Show hook is running
    print("[EntHints] HUDPaint hook running")
    
    local lply = LocalPlayer()
    if not IsValid(lply) then return end
    
    -- Check if hints are disabled
    if hg_hints and not hg_hints:GetBool() then return end
    
    -- Skip if player is dead or invalid state
    if not lply:Alive() then return end
    
    -- Use longer distance for weapon pickup hints (120 instead of default 60)
    local trace = hg.eyeTrace(lply, 120)
    
    if not trace then return end

    -- Check if we're looking at a weapon's world model and get the actual weapon entity
    local ent = trace.Entity
    if IsValid(ent) then
        -- Debug: Print what we're looking at
        print("[EntHints] Looking at:", ent:GetClass(), "Owner:", IsValid(ent:GetOwner()) and ent:GetOwner():GetClass() or "none")
        
        if ent:GetOwner() and ent:GetOwner():IsWeapon() and ent:GetOwner().HudHintMarkup then
            ent = ent:GetOwner()
            print("[EntHints] Found weapon world model, switching to weapon entity")
        end
    end

    -- Only show hint if entity has HudHintMarkup
    if ent.HudHintMarkup then
        print("[EntHints] Drawing HudHintMarkup for:", ent:GetClass(), "Hint:", ent.HudHintMarkup)
        hg.BasicHudHint(ent.HudHintMarkup)
    elseif ent.HowToUseInstructions then
        print("[EntHints] Drawing HowToUseInstructions for:", ent:GetClass(), "Hint:", ent.HowToUseInstructions)
        hg.BasicHudHint(ent.HowToUseInstructions)
    end
end)

print("[Homigrad] HUD hints loaded for sandbox mode")

-- Add a console command to test hints
concommand.Add("hg_test_hints", function()
    print("[Homigrad] Testing hints system...")
    local lply = LocalPlayer()
    if IsValid(lply) then
        local trace = hg.eyeTrace(lply, 120)
        if trace and IsValid(trace.Entity) then
            print("[Homigrad] Looking at:", trace.Entity:GetClass())
            if trace.Entity.HudHintMarkup then
                print("[Homigrad] Entity has HudHintMarkup!")
            else
                print("[Homigrad] Entity does not have HudHintMarkup")
            end
            
            -- Check if it's a world model
            if trace.Entity:GetOwner() and trace.Entity:GetOwner():IsWeapon() then
                print("[Homigrad] World model detected, owner weapon:", trace.Entity:GetOwner():GetClass())
                if trace.Entity:GetOwner().HudHintMarkup then
                    print("[Homigrad] Owner weapon has HudHintMarkup!")
                end
            end
        else
            print("[Homigrad] No valid entity in trace")
        end
    end
end)
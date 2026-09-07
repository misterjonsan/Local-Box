
local soundPath = "exhaustedLoop.ogg"
local exhaustionThreshold = 90
local maxVolume = 1.0 -- Adjust this if it's too loud/quiet

local exhaustionSound = nil
local lastStamina = 90
local isRecovering = false
local currentVolume = 0

hook.Add("Think", "ExhaustionSoundLogic", function()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then
        if exhaustionSound then 
            exhaustionSound:Stop() 
            currentVolume = 0
        end
        return
    end

    local organism = ply.organism
    if not organism or not organism.stamina then return end

    local stamina = organism.stamina[1]
    if not stamina then return end
    
    -- Detect change and direction
    -- We only update direction when the value actually changes (which happens on net update)
    if stamina ~= lastStamina then
        isRecovering = stamina > lastStamina
        lastStamina = stamina
    end

    if stamina < exhaustionThreshold then
        if not exhaustionSound then
            exhaustionSound = CreateSound(ply, soundPath)
        end
        
        if not exhaustionSound:IsPlaying() then
            exhaustionSound:Play()
            exhaustionSound:ChangeVolume(0, 0)
        end

        -- Calculate target volume based on how low stamina is
        -- At 75 stamina: factor is 0 -> volume 0
        -- At 0 stamina: factor is 1 -> volume maxVolume
        local exhaustionFactor = math.Clamp((exhaustionThreshold - stamina) / exhaustionThreshold, 0, 1)
        local targetVolume = exhaustionFactor * maxVolume

        -- "decrease in volume when the player's stamina is increasing"
        if isRecovering then
            targetVolume = targetVolume * 0.3 -- Reduce volume significantly when recovering
        end
        
        -- Smooth transition for volume to avoid abrupt changes on net updates
        currentVolume = math.Approach(currentVolume, targetVolume, FrameTime() * 2.0)
        exhaustionSound:ChangeVolume(currentVolume, 0)
    else
        if exhaustionSound and exhaustionSound:IsPlaying() then
            exhaustionSound:FadeOut(1)
            currentVolume = 0
        end
    end
end)

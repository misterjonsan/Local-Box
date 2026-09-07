net.Receive("AdminSetPlayerClass", function(len, ply)
    if not ply:IsAdmin() then return end
    
    local ent = net.ReadEntity()
    local class = net.ReadString()

    -- Логика из твоего предыдущего скрипта
    ent = hg.RagdollOwner(ent) or hg.GetCurrentCharacter(ent) or ent
    
    if IsValid(ent) and ent:IsPlayer() and player.classList[class] then
        ent:SetPlayerClass(class)
        -- Опционально: зареспавнить игрока или уведомить
        -- ent:Spawn() 
    end
end)
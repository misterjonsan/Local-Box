local ENT = FindMetaTable("Entity")


--[[
==================================================================================================
                    NPC SPAWNING
==================================================================================================
--]]

-- Spawn a NPC from the spawn menu
function conv.createSpawnMenuNPC( SpawnMenuClass, pos, wep, beforeSpawnFunc )
    -- Find NPC in spawn menu
    local SpawnMenuTable = ents._SpawnMenuNPCs[SpawnMenuClass]

    -- Check if zbase npc
    local isZBaseNPC = ZBaseInstalled && ZBaseNPCs[SpawnMenuClass]
    
    -- No such NPC
    if !SpawnMenuTable then
        ErrorNoHaltWithStack("No such NPC found: '", SpawnMenuClass, "'\n")
        return
    end

    -- Create NPC
    local NPC = ents.Create( isZBaseNPC && SpawnMenuClass or SpawnMenuTable.Class )

    -- No such NPC
    if !IsValid(NPC) then
        ErrorNoHaltWithStack("No such NPC found: '", SpawnMenuTable.Class, "'\n")
        return
    end

    -- Position
    if isvector(pos) then
        NPC:SetPos(pos)
    end

    -- Default weapons if none if provided
    wep = wep or (SpawnMenuTable.Weapons && table.Random(SpawnMenuTable.Weapons))
    if isstring(wep) then
        NPC:Give( wep )
    end

    -- Key values
    if SpawnMenuTable.KeyValues then
        for key, value in pairs(SpawnMenuTable.KeyValues) do
            NPC:SetKeyValue(key, value)
        end
    end

    -- Set stuff
    if SpawnMenuTable.Model then NPC:SetModel(SpawnMenuTable.Model) end
    if SpawnMenuTable.Skin then NPC:SetSkin(SpawnMenuTable.Skin) end
    if SpawnMenuTable.Health then NPC:SetMaxHealth(SpawnMenuTable.Health) NPC:SetHealth(SpawnMenuTable.Health) end
    if SpawnMenuTable.Material then NPC:SetMaterial(SpawnMenuTable.Material) end
    if SpawnMenuTable.SpawnFlags then NPC:SetKeyValue("spawnflags", SpawnMenuTable.SpawnFlags) end

    if isfunction(beforeSpawnFunc) then
        beforeSpawnFunc( NPC )
    end

    -- Spawn and Activate
    NPC:Spawn()
    NPC:Activate()

    return NPC
end


-- Spawns an entity for a short duration allowing you to obtain info about it
function conv.getEntInfo( cls, func )
    local ent = ents.Create(cls)
    if !IsValid(ent) then
        ErrorNoHaltWithStack("No such ENT found: '", cls, "'\n")
        return
    end

    ent:Spawn()
    ent:Activate()

    conv.callNextTick(function( Ent )
        func(Ent)
        Ent:Remove()
    end, ent)
end


--[[
==================================================================================================
                    NETWORKING
==================================================================================================
--]]


-- Needs to be tested, do not use.
function ENT:CONV_Broadcast( func )

    func()
    net.Broadcast()

    table.insert(conv._NetFuncsToSendJoiningPlayers, func)
    self:CallOnRemove("RemoveNetFunc: "..tostring(func), function()
        table.RemoveByValue(conv._NetFuncsToSendJoiningPlayers, func)
    end)

end


--[[
==================================================================================================
                    Spawnflags
==================================================================================================
--]]

function ENT:CONV_SetSpawnFlags(...)
    self:SetKeyValue("spawnflags", bit.bor(...))
end

function ENT:CONV_AddSpawnFlags(...)
    self:SetKeyValue("spawnflags", bit.bor(self:GetSpawnFlags(), ...))
end

function ENT:CONV_RemoveSpawnFlags(...)
    self:SetKeyValue("spawnflags", bit.band(self:GetSpawnFlags(), bit.bnot(...)))
end
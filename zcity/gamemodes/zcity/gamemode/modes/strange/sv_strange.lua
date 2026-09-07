-- sv_homicide_horror.lua
-- Server-side code for "Homicide...?" gamemode

local MODE = MODE
MODE.name = "strange"
MODE.PrintName = "Strange"

-- Standard gamemode settings
MODE.start_time = 1
MODE.end_time = 7
MODE.ROUND_TIME = 600
MODE.randomSpawns = true
MODE.shouldfreeze = false
MODE.PoliceAllowed = false
MODE.OverrideSpawn = false
MODE.LootSpawn = true
MODE.LootOnTime = true
MODE.LootDivTime = 200
MODE.GuiltDisabled = true
MODE.Chance = 0.00

MODE.BehindWindow = 4
MODE.BehindCheckInterval = 3
MODE.BehindChance = 0.12
MODE.BehindCooldown = 30
-- Configuration
MODE.EntityActivationTime = 20
MODE.EntityKillCooldown = 35
MODE.DoorCryChance = 0.015
MODE.DoorCryInterval = 8
MODE.GroupSize = 2
MODE.DuoDisappearChance = 0.8
MODE.LightFlickerChance = 0.05
MODE.DoorOpenChance = 0.02
MODE.EscapeTimeLimit = 25

-- State tracking
MODE.CurrentTarget = nil
MODE.EntityActive = false
MODE.LastKillTime = 0
MODE.LockedDoors = {}
MODE.FlickeringLights = {}
MODE.EscapeTargets = {}
MODE.Type = "standard"
MODE.ActiveDrags = {}
MODE.NoTargetUntil = {}

MODE.ValidTypes = {"standard", "soe", "gunfreezone"}

-- Network strings
util.AddNetworkString("HorrorEntity_StartAmbience")
util.AddNetworkString("HorrorEntity_StopAmbience")
util.AddNetworkString("HorrorEntity_SetEscapeTarget")
util.AddNetworkString("HorrorEntity_KillEscapeTarget")
util.AddNetworkString("strange_start")
util.AddNetworkString("strange_disable_flashlight")
util.AddNetworkString("strange_ghost_consume")

local function Strange_IsFemale(ply)
    if not IsValid(ply) then return false end
    if ply.CurAppearance and ply.CurAppearance.Female then return true end
    if istable(hg) and isfunction(ThatPlyIsFemale) then
        local ok = pcall(function() return ThatPlyIsFemale(ply) end)
        if ok then
            if ThatPlyIsFemale(ply) then return true end
        end
    end
    local mdl = string.lower(ply:GetModel() or "")
    if string.find(mdl, "female", 1, true) then return true end
    return false
end

-- Helper functions
local function DoorHasAlternativeEntrance(door)
    if not IsValid(door) then return false end
    
    local doorPos = door:GetPos()
    local nearbyDoors = ents.FindInSphere(doorPos, 600)
    local doorCount = 0
    
    for _, ent in ipairs(nearbyDoors) do
        if ent ~= door and (ent:GetClass() == "prop_door_rotating" or 
           ent:GetClass() == "func_door" or ent:GetClass() == "func_door_rotating") then
            doorCount = doorCount + 1
        end
    end
    
    return doorCount > 0
end

local function StartSmartPin(ply, keepAlive, force)
    if not IsValid(ply) then return end
    if ply.BeingKilled then return end
    ply.BeingKilled = true
    if ply.organism then
        ply.organism.needfake = true
        ply.organism.otrub = true
    end
    hg.Fake(ply, nil, true, true)
    ply:SetNWBool("PinnedToWall", true)
    timer.Simple(0.2, function()
        if not IsValid(ply) then return end
        local rag = ply:GetRagdollEntity()
        if not IsValid(rag) and force then
            hg.Fake(ply, nil, true, true)
            rag = ply:GetRagdollEntity()
        end
        if not IsValid(rag) then
            ply:SetNWBool("PinnedToWall", false)
            ply.BeingKilled = false
            return
        end
        local chestBone = rag:LookupBone("ValveBiped.Bip01_Spine2") or rag:LookupBone("ValveBiped.Bip01_Spine4") or rag:LookupBone("ValveBiped.Bip01_Pelvis") or rag:LookupBone("ValveBiped.Bip01_Spine1")
        if not chestBone then
            ply:SetNWBool("PinnedToWall", false)
            ply.BeingKilled = false
            return
        end
        local physBone = rag:TranslateBoneToPhysBone(chestBone)
        local chestPhys = rag:GetPhysicsObjectNum(physBone)
        if not IsValid(chestPhys) then
            ply:SetNWBool("PinnedToWall", false)
            ply.BeingKilled = false
            return
        end
        chestPhys:EnableMotion(true)
        chestPhys:Wake()
        if not rag:GetCustomCollisionCheck() then
            rag:SetCustomCollisionCheck(true)
            rag:CollisionRulesChanged()
        end
        local origin = chestPhys:GetPos()
        local bestTr = nil
        local upTr = util.TraceHull({start = origin, endpos = origin + vector_up * 900, mins = Vector(-8,-8,-8), maxs = Vector(8,8,8), filter = rag})
        if upTr.Hit then bestTr = upTr end
        if not bestTr then
            local ey = ply:EyeAngles()
            local dirs = {
                ey:Forward(), -ey:Forward(), ey:Right(), -ey:Right(), Vector(1,0,0), Vector(-1,0,0), Vector(0,1,0), Vector(0,-1,0)
            }
            for i=1,#dirs do
                local d = dirs[i]
                local tr = util.TraceHull({start = origin, endpos = origin + d * 900, mins = Vector(-8,-8,-8), maxs = Vector(8,8,8), filter = rag})
                if tr.Hit then
                    local isWall = (tr.HitNormal and math.abs(tr.HitNormal.z) < 0.4)
                    if not bestTr then
                        bestTr = tr
                    elseif isWall and (math.abs(tr.HitNormal.z) < math.abs((bestTr.HitNormal or vector_up).z)) then
                        bestTr = tr
                    end
                end
            end
        end
        if not bestTr or not bestTr.Hit or (bestTr.HitNormal and math.abs(bestTr.HitNormal.z) >= 0.6) then
            local bestLine = nil
            for i = 1, 16 do
                local yaw = (i - 1) * 22.5
                local d = Angle(0, yaw, 0):Forward()
                local tr2 = util.TraceLine({start = origin, endpos = origin + d * 1200, filter = rag})
                if tr2.Hit then
                    if not bestLine or math.abs(tr2.HitNormal.z) < math.abs((bestLine.HitNormal or vector_up).z) then
                        bestLine = tr2
                    end
                end
            end
            if bestLine then bestTr = bestLine end
        end
        if not bestTr or not bestTr.Hit then
            ply:SetNWBool("PinnedToWall", false)
            ply.BeingKilled = false
            return
        end
        local targetPos = bestTr.HitPos + ((bestTr.HitNormal and bestTr.HitNormal) or vector_up) * 12
        local carryPos = Vector(0,0,0)
        local pts = {}
        do
            local current = origin
            local maxSteps = 10
            local stepDist = 160
            for i = 1, maxSteps do
                local toGoal = (targetPos - current)
                if toGoal:Length() < stepDist then
                    pts[#pts + 1] = targetPos
                    break
                end
                local dir = toGoal:GetNormalized()
                local best2 = nil
                local angles = {0, 30, -30, 60, -60, 90, -90}
                for k = 1, #angles do
                    local a = Angle(0, angles[k], 0)
                    local d = (dir:Angle() + a):Forward()
                    local tr = util.TraceHull({start = current, endpos = current + d * stepDist, mins = Vector(-8,-8,-8), maxs = Vector(8,8,8), filter = rag})
                    if not best2 or tr.Fraction > (best2.Fraction or 0) then best2 = tr end
                    if tr.Fraction > 0.9 then break end
                end
                local nextPos = (best2 and best2.HitPos) or (current + dir * stepDist)
                pts[#pts + 1] = nextPos
                current = nextPos
                if current:DistToSqr(targetPos) < (stepDist * stepDist) then
                    pts[#pts + 1] = targetPos
                    break
                end
            end
        end
        MODE.ActiveDrags[ply] = {
            rag = rag,
            phys = chestPhys,
            pelvis = nil,
            carry = carryPos,
            target = targetPos,
            start = CurTime(),
            keep = keepAlive or false,
            path = pts,
            stuck = 0,
            expire = CurTime() + 30,
            mode = "pin",
            pinBone = physBone,
            pinEnt = bestTr.Entity,
            pinPhysBone = bestTr.PhysicsBone or 0
        }
        timer.Create("PinnedWall_" .. ply:EntIndex(), 0.1, 0, function()
            if not IsValid(ply) then
                timer.Remove("PinnedWall_" .. ply:EntIndex())
                return
            end
            local st = MODE.ActiveDrags[ply]
            if not st or st.mode ~= "pin" then return end
            local pos = LocalToWorld(st.carry, angle_zero, st.phys:GetPos(), st.phys:GetAngles())
            local vec = st.target - pos
            local dist = vec:Length()
            if dist < 22 then
                vec:Normalize()
                st.phys:SetVelocity(vec * 3600)
                st.phys:ApplyForceCenter(vec * 360000)
                local hitEnt = st.pinEnt or game.GetWorld()
                constraint.Weld(st.rag, IsValid(hitEnt) and hitEnt or game.GetWorld(), st.pinBone, st.pinPhysBone or 0, 0, false, false)
                MODE.ActiveDrags[ply] = nil
                ply:SetNWBool("PinnedToWall", false)
                if not st.keep then
                    local soundFile = Strange_IsFemale(ply) and "s_crush_f.wav" or "s_crush_m.wav"
                    ply:EmitSound(soundFile, 100, 100)
                    local stabs = math.random(20, 30)
                    StruggleAndSlash(ply, st.rag, nil, 100, stabs)
                    timer.Simple(stabs * 0.1 + 0.05, function()
                        if IsValid(ply) then
                            if ply:Alive() then ply:Kill() end
                            GibCorpseHeadOrRandomLimb(ply)
                        end
                    end)
                end
                ply.BeingKilled = false
                timer.Remove("PinnedWall_" .. ply:EntIndex())
            end
        end)
    end)
end

local function IsDoorInRoom(door)
    if not IsValid(door) then return false end
    local pos = door:GetPos()
    local enclosed = 0
    local dirs = {
        Vector(1, 0, 0), Vector(-1, 0, 0),
        Vector(0, 1, 0), Vector(0, -1, 0),
        Vector(1, 1, 0), Vector(-1, 1, 0), Vector(1, -1, 0), Vector(-1, -1, 0)
    }
    for i = 1, #dirs do
        local tr = util.TraceHull({
            start = pos,
            endpos = pos + dirs[i] * 300,
            mins = Vector(-6, -6, -6),
            maxs = Vector(6, 6, 6),
            filter = door
        })
        if tr.Hit then
            enclosed = enclosed + 1
        end
    end
    local up = util.TraceHull({
        start = pos,
        endpos = pos + Vector(0, 0, 150),
        mins = Vector(-6, -6, -6),
        maxs = Vector(6, 6, 6),
        filter = door
    })
    local down = util.TraceHull({
        start = pos,
        endpos = pos + Vector(0, 0, -150),
        mins = Vector(-6, -6, -6),
        maxs = Vector(6, 6, 6),
        filter = door
    })
    local vHits = (up.Hit and 1 or 0) + (down.Hit and 1 or 0)
    return enclosed >= 5 and vHits >= 1
end

local function CountNearbyPlayers(pos, exclude, radius)
    local count = 0
    for _, p in ipairs(player.GetAll()) do
        if p ~= exclude and p:Alive() and p:Team() ~= TEAM_SPECTATOR then
            if pos:Distance(p:GetPos()) < (radius or 800) then
                local tr = util.TraceLine({start = pos, endpos = p:GetPos() + Vector(0,0,64), filter = {exclude, p}})
                if not tr.Hit then
                    count = count + 1
                end
            end
        end
    end
    return count
end

local function FindLonelyDoorWithRoom(ply)
    local doors = ents.FindByClass("prop_door_rotating")
    table.Add(doors, ents.FindByClass("func_door"))
    table.Add(doors, ents.FindByClass("func_door_rotating"))
    local bestDoor = nil
    local bestScore = math.huge
    for _, door in ipairs(doors) do
        if IsValid(door) then
            local insidePos = door:GetPos() + door:GetForward() * 140
            local score = CountNearbyPlayers(insidePos, ply, 850)
            if score < bestScore then
                bestScore = score
                bestDoor = door
            end
        end
    end
    return bestDoor
end

local function CountNearbyLights(pos, radius)
    local lights = ents.FindByClass("light*")
    local r = radius or 600
    local c = 0
    for i=1,#lights do
        local l = lights[i]
        if IsValid(l) then
            if pos:Distance(l:GetPos()) < r then
                c = c + 1
            end
        end
    end
    return c
end

local function Strange_FindDarkSpot(basePos, rag)
    local best = nil
    for i = 1, 16 do
        local yaw = (i - 1) * 22.5
        local dir = Angle(0, yaw, 0):Forward()
        local candidate = basePos + dir * 600
        local enclosed = 0
        local dirs = {
            Vector(1,0,0), Vector(-1,0,0), Vector(0,1,0), Vector(0,-1,0),
            Vector(1,1,0), Vector(-1,1,0), Vector(1,-1,0), Vector(-1,-1,0)
        }
        for j = 1, #dirs do
            local tr = util.TraceHull({start = candidate, endpos = candidate + dirs[j] * 250, mins = Vector(-8,-8,-8), maxs = Vector(8,8,8), filter = rag})
            if tr.Hit then enclosed = enclosed + 1 end
        end
        local lights = CountNearbyLights(candidate, 600)
        local score = lights * 10 - enclosed * 3
        if not best or score < best.score then
            best = {pos = candidate, enclosed = enclosed, score = score}
        end
    end
    return (best and best.pos) or (basePos + VectorRand():GetNormalized() * 400)
end
local function GibCorpseHeadOrRandomLimb(ply)
    if not IsValid(ply) then return end
    timer.Simple(0.02, function()
        if not IsValid(ply) then return end
        local rag = ply:GetRagdollEntity()
        if not IsValid(rag) then return end
        local head = rag:LookupBone("ValveBiped.Bip01_Head1")
        if head then
            Gib_Input(rag, head, Vector(0,0,6000))
            return
        end
        local names = {
            "ValveBiped.Bip01_L_Forearm",
            "ValveBiped.Bip01_R_Forearm",
            "ValveBiped.Bip01_L_Calf",
            "ValveBiped.Bip01_R_Calf",
            "ValveBiped.Bip01_L_Hand",
            "ValveBiped.Bip01_R_Hand",
            "ValveBiped.Bip01_L_Foot",
            "ValveBiped.Bip01_R_Foot",
        }
        local pool = {}
        for i = 1, #names do
            local b = rag:LookupBone(names[i])
            if b then pool[#pool + 1] = b end
        end
        if #pool > 0 then
            Gib_Input(rag, pool[math.random(1, #pool)], Vector(0,0,5000))
        end
    end)
end
local function PinVictimToWall(ply)
    if not IsValid(ply) then return end
    if ply.BeingKilled then return end
    ply.BeingKilled = true
    if ply.organism then
        ply.organism.needfake = true
        if not keepAlive then ply.organism.otrub = true end
    end
    hg.Fake(ply, nil, true)
    ply:SetNWBool("PinnedToWall", true)
    timer.Simple(0.2, function()
        if not IsValid(ply) then return end
        local rag = ply:GetRagdollEntity()
        if not IsValid(rag) then
            ply:SetNWBool("PinnedToWall", false)
            ply.BeingKilled = false
            return
        end
        local chestBone = rag:LookupBone("ValveBiped.Bip01_Spine2") or rag:LookupBone("ValveBiped.Bip01_Spine4")
        if not chestBone then
            ply:SetNWBool("PinnedToWall", false)
            ply.BeingKilled = false
            return
        end
        local physBone = rag:TranslateBoneToPhysBone(chestBone)
        local chestPos = rag:GetPhysicsObjectNum(physBone):GetPos()
        local chestAng = rag:GetPhysicsObjectNum(physBone):GetAngles()
        local tr = util.TraceHull({
            start = chestPos,
            endpos = chestPos + chestAng:Forward() * 80,
            mins = Vector(-8, -8, -8),
            maxs = Vector(8, 8, 8),
            filter = rag
        })
        local hitEnt = tr.Entity or game.GetWorld()
        local cons = constraint.Weld(rag, IsValid(hitEnt) and hitEnt or game.GetWorld(), physBone, tr.PhysicsBone or 0, 0, false, false)
        if not IsValid(cons) then
            ply:SetNWBool("PinnedToWall", false)
            ply.BeingKilled = false
            return
        end
        timer.Create("PinnedWall_" .. ply:EntIndex(), 0.5, 0, function()
            if not IsValid(ply) then
                timer.Remove("PinnedWall_" .. ply:EntIndex())
                return
            end
            local st = MODE.ActiveDrags[ply]
            if st and st.mode == "pin" then
                local pos = LocalToWorld(st.carry, angle_zero, st.phys:GetPos(), st.phys:GetAngles())
                local vec = st.target - pos
                if vec:Length() < 18 then
                    local hitEnt = st.pinEnt or game.GetWorld()
                    local cons = constraint.Weld(st.rag, IsValid(hitEnt) and hitEnt or game.GetWorld(), st.pinBone, st.pinPhysBone or 0, 0, false, false)
                    MODE.ActiveDrags[ply] = nil
                end
            end
        end)
    end)
end

local function IsPlayerAlone(ply)
    if not IsValid(ply) or not ply:Alive() then return false end
    
    local nearbyPlayers = 0
    local pos = ply:GetPos()
    
    for _, otherPly in ipairs(player.GetAll()) do
        if otherPly ~= ply and otherPly:Alive() and otherPly:Team() ~= TEAM_SPECTATOR then
            local dist = pos:Distance(otherPly:GetPos())
            if dist < 500 then
                local tr = util.TraceLine({
                    start = pos + Vector(0, 0, 64),
                    endpos = otherPly:GetPos() + Vector(0, 0, 64),
                    filter = {ply, otherPly}
                })
                
                if not tr.Hit then
                    nearbyPlayers = nearbyPlayers + 1
                end
            end
        end
    end
    
    return nearbyPlayers == 0
end

local function IsPlayerUnobserved(ply)
    if not IsValid(ply) or not ply:Alive() then return false end
    local pos = ply:GetPos() + Vector(0, 0, 64)
    for _, otherPly in ipairs(player.GetAll()) do
        if otherPly ~= ply and otherPly:Alive() and otherPly:Team() ~= TEAM_SPECTATOR then
            local dist = pos:Distance(otherPly:GetPos())
            if dist < 1200 then
                local tr = util.TraceLine({
                    start = otherPly:GetPos() + Vector(0, 0, 64),
                    endpos = pos,
                    filter = {ply, otherPly}
                })
                if not tr.Hit then
                    return false
                end
            end
        end
    end
    return true
end

local function IsPlayerInGroup(ply)
    if not IsValid(ply) or not ply:Alive() then return false end
    
    local nearbyPlayers = 0
    local pos = ply:GetPos()
    
    for _, otherPly in ipairs(player.GetAll()) do
        if otherPly ~= ply and otherPly:Alive() and otherPly:Team() ~= TEAM_SPECTATOR then
            local dist = pos:Distance(otherPly:GetPos())
            if dist < 500 then
                local tr = util.TraceLine({
                    start = pos + Vector(0, 0, 64),
                    endpos = otherPly:GetPos() + Vector(0, 0, 64),
                    filter = {ply, otherPly}
                })
                
                if not tr.Hit then
                    nearbyPlayers = nearbyPlayers + 1
                end
            end
        end
    end
    
    return nearbyPlayers >= MODE.GroupSize
end

local function IsPlayerInDuo(ply)
    if not IsValid(ply) or not ply:Alive() then return false, nil end
    
    local nearbyPlayers = 0
    local pos = ply:GetPos()
    local duoPartner = nil
    
    for _, otherPly in ipairs(player.GetAll()) do
        if otherPly ~= ply and otherPly:Alive() and otherPly:Team() ~= TEAM_SPECTATOR then
            local dist = pos:Distance(otherPly:GetPos())
            if dist < 500 then
                local tr = util.TraceLine({
                    start = pos + Vector(0, 0, 64),
                    endpos = otherPly:GetPos() + Vector(0, 0, 64),
                    filter = {ply, otherPly}
                })
                
                if not tr.Hit then
                    nearbyPlayers = nearbyPlayers + 1
                    if nearbyPlayers == 1 then
                        duoPartner = otherPly
                    end
                end
            end
        end
    end
    
    return nearbyPlayers == 1, duoPartner
end

local function FindNearestRoomWithDoor(ply)
    if not IsValid(ply) then return nil end
    local doors = ents.FindByClass("prop_door_rotating")
    table.Add(doors, ents.FindByClass("func_door"))
    table.Add(doors, ents.FindByClass("func_door_rotating"))
    local nearestDoor = nil
    local nearestDist = math.huge
    for _, door in ipairs(doors) do
        if IsValid(door) then
            local dist = ply:GetPos():Distance(door:GetPos())
            if dist < 2500 and IsDoorInRoom(door) and dist < nearestDist then
                nearestDist = dist
                nearestDoor = door
            end
        end
    end
    if not IsValid(nearestDoor) then
        for _, door in ipairs(doors) do
            if IsValid(door) then
                local dist = ply:GetPos():Distance(door:GetPos())
                if dist < 2500 and dist < nearestDist then
                    nearestDist = dist
                    nearestDoor = door
                end
            end
        end
    end
    return nearestDoor
end

local function LockDoor(door)
    if not IsValid(door) then return end
    door:Fire("Lock", "", 0)
    door:Fire("Close", "", 0)
    MODE.LockedDoors[door] = true
end

local function UnlockDoor(door)
    if not IsValid(door) then return end
    door:Fire("Unlock", "", 0)
    MODE.LockedDoors[door] = nil
end

local function CloseDoor(door)
    if not IsValid(door) then return end
    door:Fire("Close", "", 0)
end

local function GibPlayerHead(ply)
    if not IsValid(ply) then return end
    
    local rag = ply:GetRagdollEntity()
    if IsValid(rag) then
        local headBone = rag:LookupBone("ValveBiped.Bip01_Head1")
        if headBone then
            local physBone = rag:TranslateBoneToPhysBone(headBone)
            if physBone then
                local phys = rag:GetPhysicsObjectNum(physBone)
                if IsValid(phys) then
                    phys:ApplyForceCenter(Vector(0, 0, 50000))
                end
            end
        end
    end
    
    if ply:Alive() then
        ply:Kill()
    end
end

local function BreakPlayerNeck(ply)
    if not IsValid(ply) or not ply:Alive() then return end
    
    if ply.organism then
        ply.organism.needfake = true
        ply.organism.otrub = true
        ply.organism.spine3 = 1
        ply.organism.spine2 = 1
        ply.organism.spine1 = 1
    end
    
    hg.Fake(ply, nil, true)
    
    timer.Simple(0.2, function()
        if not IsValid(ply) then return end
        
        local rag = ply:GetRagdollEntity()
        if IsValid(rag) then
            rag:EmitSound("physics/body/body_medium_break" .. math.random(2, 4) .. ".wav", 100)
        end
        
        timer.Simple(0.5, function()
            if IsValid(ply) and ply:Alive() then
                ply:Kill()
            end
        end)
    end)
end

-- brutal struggle before kill/consume
local function StruggleAndSlash(ply, rag, duration, damagePerTick, stabCount)
    if not IsValid(ply) then return end
    local R = IsValid(rag) and rag or ply:GetRagdollEntity()
    local dur = duration or 1.5
    local dmg = damagePerTick or 50
    local ticks = stabCount or math.random(20, 30)
    local id = "Strange_Struggle_" .. ply:EntIndex()
    timer.Create(id, 0.1, ticks, function()
        if not IsValid(ply) then
            timer.Remove(id)
            return
        end
        local rr = IsValid(R) and R or ply:GetRagdollEntity()
        if IsValid(rr) then
            for i = 0, rr:GetPhysicsObjectCount() - 1 do
                local po = rr:GetPhysicsObjectNum(i)
                if IsValid(po) then
                    local dir = VectorRand()
                    po:ApplyForceCenter(dir:GetNormalized() * math.random(2000, 4000))
                    po:AddAngleVelocity(VectorRand() * math.random(20, 50))
                end
            end
            local count = rr:GetPhysicsObjectCount()
            local idx = count > 0 and math.random(0, count - 1) or 0
            local po = rr:GetPhysicsObjectNum(idx)
            local hitPos = IsValid(po) and po:GetPos() or rr:GetPos()
            local hitNormal = VectorRand()
            util.Decal("Blood", hitPos + hitNormal * 15, hitPos - hitNormal * 15, rr)
            util.Decal("Blood", hitPos + hitNormal * 2, hitPos - hitNormal * 2, rr)
            local ed = EffectData()
            ed:SetOrigin(hitPos)
            util.Effect("BloodImpact", ed)
        end
        if ply:Alive() then
            local di = DamageInfo()
            di:SetAttacker(game.GetWorld())
            di:SetInflictor(game.GetWorld())
            di:SetDamageType(DMG_SLASH)
            di:SetDamage(dmg)
            di:SetDamagePosition(IsValid(rr) and rr:GetPos() or ply:GetPos())
            di:SetDamageForce(VectorRand() * dmg)
            ply:TakeDamageInfo(di)
            ply:EmitSound("snd_jack_hmcd_knifestab.wav", 60, 100)
        end
    end)
end

local function KillPlayerInRoom(ply, door)
    if not IsValid(ply) then return end
    if ply.BeingKilled then return end
    ply.BeingKilled = true
    
    local soundFile = Strange_IsFemale(ply) and "s_crush_f.wav" or "s_crush_m.wav"
    
    if ply.organism then
        ply.organism.needfake = true
        ply.organism.otrub = true
    end
    hg.Fake(ply, nil, true, true)

    if IsValid(door) then
        CloseDoor(door)
        LockDoor(door)
    end
    
    ply:EmitSound(soundFile, 100, 100)
    local stabs = math.random(20, 30)
    StruggleAndSlash(ply, nil, nil, 100, stabs)
    
    timer.Simple(stabs * 0.1 + 0.05, function()
        if IsValid(ply) then
            ply:Kill()
            GibCorpseHeadOrRandomLimb(ply)
            ply.BeingKilled = false
        end
        
        if IsValid(door) then
            timer.Simple(3, function()
                UnlockDoor(door)
            end)
        end
    end)
end

local function DragAndKillPlayer(ply, keepAlive)
    if not IsValid(ply) then return end
    if ply.BeingKilled then return end
    ply.BeingKilled = true
    
    if ply.organism then
        ply.organism.needfake = true
        ply.organism.otrub = true
    end
    hg.Fake(ply, nil, true)
    
    ply:SetNWBool("BeingDragged", true)
    
    local door = FindNearestRoomWithDoor(ply)
    
    timer.Simple(0.3, function()
        if not IsValid(ply) then return end
        
        local rag = ply:GetRagdollEntity()
        if not IsValid(rag) then
            if force then
                hg.Fake(ply, nil, true, true)
            end
            timer.Simple(0.1, function()
                if not IsValid(ply) then return end
                if MODE.ActiveDrags and MODE.ActiveDrags[ply] then return end
                StartSmartDrag(ply, keepAlive, dest, true)
            end)
            ply.BeingKilled = false
            ply:SetNWBool("BeingDragged", false)
            return
        end
        
        local legBone = rag:LookupBone("ValveBiped.Bip01_R_Calf")
        if not legBone then legBone = rag:LookupBone("ValveBiped.Bip01_L_Calf") end
        if not legBone then legBone = rag:LookupBone("ValveBiped.Bip01_R_Foot") end
        if not legBone then legBone = rag:LookupBone("ValveBiped.Bip01_L_Foot") end
        if not legBone then legBone = rag:LookupBone("ValveBiped.Bip01_R_Thigh") end
        if not legBone then legBone = rag:LookupBone("ValveBiped.Bip01_L_Thigh") end

        if legBone then
            local physBone = rag:TranslateBoneToPhysBone(legBone)
            local physObj = rag:GetPhysicsObjectNum(physBone)

            local pelvisBone = rag:LookupBone("ValveBiped.Bip01_Pelvis")
            local pelvisPhys = nil
            if pelvisBone then
                local pelvisPhysBone = rag:TranslateBoneToPhysBone(pelvisBone)
                pelvisPhys = rag:GetPhysicsObjectNum(pelvisPhysBone)
            end

            if IsValid(physObj) then
                physObj:EnableMotion(true)
                physObj:Wake()
                if IsValid(pelvisPhys) then
                    pelvisPhys:EnableMotion(true)
                    pelvisPhys:Wake()
                end
                local targetPos
                if IsValid(door) then
                    targetPos = door:GetPos() + door:GetForward() * 60
                else
                    local base = physObj:GetPos()
                    local dir = VectorRand()
                    dir.z = 0
                    dir:Normalize()
                    local tr = util.TraceLine({start = base, endpos = base + dir * 400, filter = rag})
                    targetPos = tr.HitPos
                end

                local dragTime = 8
                local startTime = CurTime()
                local prevPos = physObj:GetPos()
                local carryPos = WorldToLocal(physObj:GetPos(), angle_zero, physObj:GetPos(), physObj:GetAngles())
                if not rag:GetCustomCollisionCheck() then
                    rag:SetCustomCollisionCheck(true)
                    rag:CollisionRulesChanged()
                end

                timer.Create("DragPlayer_" .. ply:EntIndex(), 0.03, dragTime / 0.03, function()
                    if not IsValid(ply) or not IsValid(rag) or not IsValid(physObj) then
                        timer.Remove("DragPlayer_" .. ply:EntIndex())
                        if IsValid(ply) then
                            ply.BeingKilled = false
                            ply:SetNWBool("BeingDragged", false)
                        end
                        return
                    end

                    local progress = (CurTime() - startTime) / dragTime
                    local currentPos = LocalToWorld(carryPos, angle_zero, physObj:GetPos(), physObj:GetAngles())
                    local vec = (targetPos - currentPos)
                    local len = vec:Length()
                    local mul = physObj:GetMass()
                    vec:Normalize()
                    local avec = vec * len * 3 - physObj:GetVelocity()
                    local Force = avec * mul
                    local ForceMagnitude = math.min(Force:Length(), 3000)
                    Force = Force:GetNormalized() * ForceMagnitude
                    physObj:Wake()
                    physObj:ApplyForceOffset(Force, currentPos)
                    physObj:ApplyForceCenter(Vector(0, 0, mul))
                    if IsValid(pelvisPhys) then
                        local avec2 = vec * len * 2 - pelvisPhys:GetVelocity()
                        local Force2 = avec2 * math.max(pelvisPhys:GetMass(), 1)
                        local ForceMagnitude2 = math.min(Force2:Length(), 1500)
                        Force2 = Force2:GetNormalized() * ForceMagnitude2
                        pelvisPhys:ApplyForceCenter(Force2)
                    end
                    local movedDist = physObj:GetPos():Distance(prevPos)
                    prevPos = physObj:GetPos()
                    if movedDist < 2 then
                        for i = 0, rag:GetPhysicsObjectCount() - 1 do
                            local po = rag:GetPhysicsObjectNum(i)
                            if IsValid(po) then
                                po:ApplyForceCenter(vec * 12000)
                            end
                        end
                    end

                    local effectdata = EffectData()
                    effectdata:SetOrigin(physObj:GetPos())
                    util.Effect("ManhackSparks", effectdata)

                    if progress >= 1 then
                        timer.Remove("DragPlayer_" .. ply:EntIndex())

                        if IsValid(door) then
                            CloseDoor(door)
                            LockDoor(door)
                        end

                        timer.Simple(0.5, function()
                            if not IsValid(ply) then return end

                            ply:SetNWBool("BeingDragged", false)

                            if not keepAlive then
                                local soundFile = Strange_IsFemale(ply) and "s_crush_f.wav" or "s_crush_m.wav"
                                ply:EmitSound(soundFile, 100, 100)
                                local stabs = math.random(20, 30)
                                StruggleAndSlash(ply, rag, nil, 100, stabs)
                                timer.Simple(stabs * 0.1 + 0.05, function()
                                    if IsValid(ply) and ply:Alive() then
                                        ply:Kill()
                                        GibCorpseHeadOrRandomLimb(ply)
                                    end
                                end)
                            end

                            timer.Simple(3, function()
                                if IsValid(door) then
                                    UnlockDoor(door)
                                end
                                ply.BeingKilled = false
                            end)
                        end)
                    end
                end)
            else
                ply.BeingKilled = false
                ply:SetNWBool("BeingDragged", false)
            end
        else
            ply.BeingKilled = false
            ply:SetNWBool("BeingDragged", false)
        end
    end)
end

local function StartSmartDrag(ply, keepAlive, dest, force)
    if not IsValid(ply) then return end
    if ply.BeingKilled then return end
    if ply:Alive() then
        local org = ply.organism
        local hasRag = IsValid(ply:GetRagdollEntity()) or (IsValid(ply.FakeRagdoll)) or (hg and hg.ragdollFake and IsValid(hg.ragdollFake[ply]))
        local downed = org and (org.otrub or org.fake or org.incapacitated or org.dying)
        if not force and not hasRag and not downed then
            return
        end
    end
    ply.BeingKilled = true
    if ply.organism then
        ply.organism.needfake = true
        if not keepAlive then ply.organism.otrub = true end
    end
    if force then
        hg.Fake(ply, nil, true, true)
    else
        hg.Fake(ply, nil, true, true)
    end
    ply:SetNWBool("BeingDragged", true)
    timer.Simple(0.2, function()
        if not IsValid(ply) then return end
        local rag = ply:GetRagdollEntity()
        if not IsValid(rag) and IsValid(ply.FakeRagdoll) then rag = ply.FakeRagdoll end
        if not IsValid(rag) and hg and hg.ragdollFake and IsValid(hg.ragdollFake[ply]) then rag = hg.ragdollFake[ply] end
        if not IsValid(rag) and force then
            hg.Fake(ply, nil, true, true)
            rag = ply:GetRagdollEntity()
            if not IsValid(rag) and IsValid(ply.FakeRagdoll) then rag = ply.FakeRagdoll end
            if not IsValid(rag) and hg and hg.ragdollFake and IsValid(hg.ragdollFake[ply]) then rag = hg.ragdollFake[ply] end
        end
        if not IsValid(rag) then
            ply:SetNWBool("BeingDragged", false)
            ply.BeingKilled = false
            timer.Simple(0.1, function()
                if IsValid(ply) then
                    StartSmartDrag(ply, keepAlive, dest, true)
                end
            end)
            return
        end
        local legBone = rag:LookupBone("ValveBiped.Bip01_R_Calf")
        if not legBone then legBone = rag:LookupBone("ValveBiped.Bip01_L_Calf") end
        if not legBone then legBone = rag:LookupBone("ValveBiped.Bip01_R_Foot") end
        if not legBone then legBone = rag:LookupBone("ValveBiped.Bip01_L_Foot") end
        if not legBone then legBone = rag:LookupBone("ValveBiped.Bip01_R_Thigh") end
        if not legBone then legBone = rag:LookupBone("ValveBiped.Bip01_L_Thigh") end
        if not legBone then
            ply:SetNWBool("BeingDragged", false)
            ply.BeingKilled = false
            timer.Simple(0.1, function()
                if IsValid(ply) then
                    StartSmartDrag(ply, keepAlive, dest, true)
                end
            end)
            return
        end
        local physBone = rag:TranslateBoneToPhysBone(legBone)
        local physObj = rag:GetPhysicsObjectNum(physBone)
        if not IsValid(physObj) then
            ply:SetNWBool("BeingDragged", false)
            ply.BeingKilled = false
            timer.Simple(0.1, function()
                if IsValid(ply) then
                    StartSmartDrag(ply, keepAlive, dest, true)
                end
            end)
            return
        end
        physObj:EnableMotion(true)
        physObj:Wake()
        local pelvisBone = rag:LookupBone("ValveBiped.Bip01_Pelvis")
        local pelvisPhys = nil
        if pelvisBone then
            local pelvisPhysBone = rag:TranslateBoneToPhysBone(pelvisBone)
            pelvisPhys = rag:GetPhysicsObjectNum(pelvisPhysBone)
            if IsValid(pelvisPhys) then
                pelvisPhys:EnableMotion(true)
                pelvisPhys:Wake()
            end
        end
        if not rag:GetCustomCollisionCheck() then
            rag:SetCustomCollisionCheck(true)
            rag:CollisionRulesChanged()
        end
        local targetPos = dest
        local doorRef = nil
        if not targetPos then
            local door = FindLonelyDoorWithRoom(ply)
            if IsValid(door) then
                door:Fire("Open", "", 0)
                local base = physObj:GetPos()
                local approach = door:GetPos() - door:GetForward() * 60
                local inside1 = door:GetPos() + door:GetForward() * 140
                local inside2 = door:GetPos() + door:GetForward() * 220
                local pts = {}
                do
                    local current = base
                    local maxSteps = 12
                    local stepDist = 200
                    for i = 1, maxSteps do
                        local toGoal = (approach - current)
                        if toGoal:Length() < stepDist then
                            pts[#pts + 1] = approach
                            break
                        end
                        local dir = toGoal:GetNormalized()
                        local best = nil
                        local angles = {0, 30, -30, 60, -60, 90, -90, 120, -120, 150, -150, 180}
                        for k = 1, #angles do
                            local a = Angle(0, angles[k], 0)
                            local d = (dir:Angle() + a):Forward()
                            local tr = util.TraceHull({start = current, endpos = current + d * stepDist, mins = Vector(-8,-8,-8), maxs = Vector(8,8,8), filter = rag})
                            if not best or tr.Fraction > (best.Fraction or 0) then best = tr end
                            if tr.Fraction > 0.9 then break end
                        end
                        local nextPos = (best and best.HitPos) or (current + dir * stepDist)
                        pts[#pts + 1] = nextPos
                        current = nextPos
                        if current:DistToSqr(approach) < (stepDist * stepDist) then
                            pts[#pts + 1] = approach
                            break
                        end
                    end
                end
                do
                    local current = approach
                    local maxSteps = 12
                    local stepDist = 200
                    for i = 1, maxSteps do
                        local toGoal = (inside1 - current)
                        if toGoal:Length() < stepDist then
                            pts[#pts + 1] = inside1
                            break
                        end
                        local dir = toGoal:GetNormalized()
                        local best = nil
                        local angles = {0, 30, -30, 60, -60, 90, -90, 120, -120, 150, -150, 180}
                        for k = 1, #angles do
                            local a = Angle(0, angles[k], 0)
                            local d = (dir:Angle() + a):Forward()
                            local tr = util.TraceHull({start = current, endpos = current + d * stepDist, mins = Vector(-8,-8,-8), maxs = Vector(8,8,8), filter = rag})
                            if not best or tr.Fraction > (best.Fraction or 0) then best = tr end
                            if tr.Fraction > 0.9 then break end
                        end
                        local nextPos = (best and best.HitPos) or (current + dir * stepDist)
                        pts[#pts + 1] = nextPos
                        current = nextPos
                        if current:DistToSqr(inside1) < (stepDist * stepDist) then
                            pts[#pts + 1] = inside1
                            break
                        end
                    end
                end
                do
                    local current = inside1
                    local maxSteps = 8
                    local stepDist = 160
                    for i = 1, maxSteps do
                        local toGoal = (inside2 - current)
                        if toGoal:Length() < stepDist then
                            pts[#pts + 1] = inside2
                            break
                        end
                        local dir = toGoal:GetNormalized()
                        local best = nil
                        local angles = {0, 30, -30, 60, -60}
                        for k = 1, #angles do
                            local a = Angle(0, angles[k], 0)
                            local d = (dir:Angle() + a):Forward()
                            local tr = util.TraceHull({start = current, endpos = current + d * stepDist, mins = Vector(-8,-8,-8), maxs = Vector(8,8,8), filter = rag})
                            if not best or tr.Fraction > (best.Fraction or 0) then best = tr end
                            if tr.Fraction > 0.9 then break end
                        end
                        local nextPos = (best and best.HitPos) or (current + dir * stepDist)
                        pts[#pts + 1] = nextPos
                        current = nextPos
                        if current:DistToSqr(inside2) < (stepDist * stepDist) then
                            pts[#pts + 1] = inside2
                            break
                        end
                    end
                end
                targetPos = inside2
                MODE.ActiveDrags[ply] = MODE.ActiveDrags[ply] or {}
                MODE.ActiveDrags[ply].path = pts
                doorRef = door
            else
                local base = physObj:GetPos()
                targetPos = Strange_FindDarkSpot(base, rag)
                local pts = {}
                local current = base
                local maxSteps = 12
                local stepDist = 200
                for i = 1, maxSteps do
                    local toGoal = (targetPos - current)
                    if toGoal:Length() < stepDist then
                        pts[#pts + 1] = targetPos
                        break
                    end
                    local dir = toGoal:GetNormalized()
                    local best2 = nil
                    local angles = {0, 30, -30, 60, -60, 90, -90, 120, -120, 150, -150, 180}
                    for k = 1, #angles do
                        local a = Angle(0, angles[k], 0)
                        local d = (dir:Angle() + a):Forward()
                        local tr = util.TraceHull({start = current, endpos = current + d * stepDist, mins = Vector(-8,-8,-8), maxs = Vector(8,8,8), filter = rag})
                        if not best2 or tr.Fraction > (best2.Fraction or 0) then best2 = tr end
                        if tr.Fraction > 0.9 then break end
                    end
                    local nextPos = (best2 and best2.HitPos) or (current + dir * stepDist)
                    pts[#pts + 1] = nextPos
                    current = nextPos
                    if current:DistToSqr(targetPos) < (stepDist * stepDist) then
                        pts[#pts + 1] = targetPos
                        break
                    end
                end
                MODE.ActiveDrags[ply] = MODE.ActiveDrags[ply] or {}
                MODE.ActiveDrags[ply].path = pts
            end
        end
        local carryPos = Vector(0,0,0)
        MODE.ActiveDrags[ply] = {rag = rag, phys = physObj, pelvis = pelvisPhys, carry = carryPos, target = targetPos, start = CurTime(), keep = keepAlive, path = (MODE.ActiveDrags[ply] and MODE.ActiveDrags[ply].path) or {}, stuck = 0, expire = (keepAlive and (CurTime() + 45) or (CurTime() + 10)), door = doorRef, lastpos = physObj:GetPos(), lastmove = CurTime(), boost_end = CurTime() + 2.5}
    end)
end

hook.Add("Think", "Strange_DragController", function()
    for ply, st in pairs(MODE.ActiveDrags) do
        if not IsValid(ply) or not st then MODE.ActiveDrags[ply] = nil continue end
        local rag = st.rag
        local physObj = st.phys
        if not IsValid(rag) or not IsValid(physObj) then
            local org = ply.organism
            local downed = (not ply:Alive()) or (org and (org.otrub or org.fake or org.incapacitated or org.dying))
            if not downed then
                MODE.ActiveDrags[ply] = nil
                ply:SetNWBool("BeingDragged", false)
                ply.BeingKilled = false
                continue
            end
            local pos = ply:GetPos()
            local target = st.target
            if st.path and #st.path > 0 then target = st.path[1] end
            local vecp = target - pos
            local lenp = vecp:Length()
            if lenp < 32 then
                if st.path and #st.path > 0 then table.remove(st.path,1) st.target = st.path[#st.path] or st.target else MODE.ActiveDrags[ply] = nil ply:SetNWBool("BeingDragged", false) ply.BeingKilled = false end
                continue
            end
            vecp:Normalize()
            ply:SetVelocity(vecp * 140)
            continue
        end
        local currentPos = LocalToWorld(st.carry, angle_zero, physObj:GetPos(), physObj:GetAngles())
        local target = st.target
        if st.path and #st.path > 0 then
            target = st.path[1]
        end
        local vec = target - currentPos
        local len = vec:Length()
        vec:Normalize()
        local mul = physObj:GetMass()
        local avec = vec * len * 1.6 - physObj:GetVelocity()
        local Force = avec * mul
        local boostActive = st.boost_end and (st.boost_end > CurTime())
        if (not st.boost_end) then st.boost_end = CurTime() + 1.8 boostActive = true end
        local factor = (st.mode == "pin") and (boostActive and 2.2 or 1.8) or (boostActive and 1.8 or 1.2)
        local ForceMagnitude = math.min(Force:Length(), (st.mode == "pin") and 1600 or 2200) * factor
        Force = Force:GetNormalized() * ForceMagnitude
        physObj:Wake()
        if st.door and IsValid(st.door) then
            st.door:Fire("Open", "", 0)
        end
        physObj:SetVelocity(physObj:GetVelocity() * 0.4 + vec * (280 * factor))
        physObj:ApplyForceOffset(Force, currentPos)
        physObj:ApplyForceCenter(Vector(0, 0, mul * (0.25 * factor)))
        if IsValid(st.pelvis) then
            local avec2 = vec * len * 1.3 - st.pelvis:GetVelocity()
            local Force2 = avec2 * math.max(st.pelvis:GetMass(), 1)
            local ForceMagnitude2 = math.min(Force2:Length(), (st.mode == "pin") and 1000 or 1200) * factor
            Force2 = Force2:GetNormalized() * ForceMagnitude2
            st.pelvis:SetVelocity(st.pelvis:GetVelocity() * 0.4 + vec * (200 * factor))
            st.pelvis:ApplyForceCenter(Force2)
        end
        if len < 24 then
            if st.path and #st.path > 0 then
                table.remove(st.path, 1)
                -- target will be read from st.path[1] on next tick
            else
                if st.mode == "pin" then
                    local dirf = vec
                    st.phys:SetVelocity(dirf * 3800)
                    st.phys:ApplyForceCenter(dirf * 380000)
                    local hitEnt = st.pinEnt or game.GetWorld()
                    constraint.Weld(st.rag, IsValid(hitEnt) and hitEnt or game.GetWorld(), st.pinBone, st.pinPhysBone or 0, 0, false, false)
                    MODE.ActiveDrags[ply] = nil
                    ply:SetNWBool("PinnedToWall", false)
                    if not st.keep then
                        local soundFile = Strange_IsFemale(ply) and "s_crush_f.wav" or "s_crush_m.wav"
                        ply:EmitSound(soundFile, 100, 100)
                        local stabs = math.random(20, 30)
                        StruggleAndSlash(ply, st.rag, nil, 100, stabs)
                        timer.Simple(stabs * 0.1 + 0.05, function()
                            if IsValid(ply) then
                                StrangeDisappearPlayer(ply)
                            end
                        end)
                    end
                    ply.BeingKilled = false
                else
                    if st.door and IsValid(st.door) then
                        local doorPos = st.door:GetPos()
                        local forward = st.door:GetForward()
                        local checkPos = IsValid(st.pelvis) and st.pelvis:GetPos() or st.phys:GetPos()
                        local plane = (checkPos - doorPos):Dot(forward)
                        if plane < 200 then
                            local base = currentPos
                            local inside2 = doorPos + forward * 280
                            local more = {}
                            local current2 = base
                            local maxSteps2 = 6
                            local stepDist2 = 140
                            for i = 1, maxSteps2 do
                                local toGoal2 = (inside2 - current2)
                                if toGoal2:Length() < stepDist2 then
                                    more[#more + 1] = inside2
                                    break
                                end
                                local dir2 = toGoal2:GetNormalized()
                                local best2 = nil
                                local angles2 = {0, 30, -30, 60, -60}
                                for k = 1, #angles2 do
                                    local a2 = Angle(0, angles2[k], 0)
                                    local d2 = (dir2:Angle() + a2):Forward()
                                    local tr2 = util.TraceHull({start = current2, endpos = current2 + d2 * stepDist2, mins = Vector(-8,-8,-8), maxs = Vector(8,8,8), filter = st.rag})
                                    if not best2 or tr2.Fraction > (best2.Fraction or 0) then best2 = tr2 end
                                    if tr2.Fraction > 0.9 then break end
                                end
                                local nextPos2 = (best2 and best2.HitPos) or (current2 + dir2 * stepDist2)
                                more[#more + 1] = nextPos2
                                current2 = nextPos2
                                if current2:DistToSqr(inside2) < (stepDist2 * stepDist2) then
                                    more[#more + 1] = inside2
                                    break
                                end
                            end
                            st.path = more
                            st.target = inside2
                            st.stuck = 0
                            break
                        end
                    end
                    MODE.ActiveDrags[ply] = nil
                    ply:SetNWBool("BeingDragged", false)
                    if not st.keep then
                        if st.door and IsValid(st.door) then
                            CloseDoor(st.door)
                            LockDoor(st.door)
                        end
                        local soundFile = Strange_IsFemale(ply) and "s_crush_f.wav" or "s_crush_m.wav"
                        ply:EmitSound(soundFile, 100, 100)
                        local stabs = math.random(20, 30)
                        StruggleAndSlash(ply, st.rag, nil, 100, stabs)
                        timer.Simple(stabs * 0.1 + 0.05, function()
                            if IsValid(ply) then
                                StrangeDisappearPlayer(ply)
                            end
                        end)
                    end
                    ply.BeingKilled = false
                end
            end
        else
            physObj:AddAngleVelocity(-physObj:GetAngleVelocity() / 10)
            local moved = physObj:GetPos():Distance(st.lastpos)
            if moved > 4 then
                st.lastpos = physObj:GetPos()
                st.lastmove = CurTime()
                st.stuck = 0
            else
                st.stuck = (st.stuck or 0) + 0.03
            end
            if st.stuck > 1.5 then
                st.stuck = 0
                if math.random(1,3) == 1 then
                    StartSmartPin(ply, st.keep)
                    continue
                end
                local base = currentPos
                local desired = st.path and st.path[1] or st.target
                local dir = (desired - base):GetNormalized()
                local yawJitter = Angle(0, math.Rand(-12, 12), 0)
                dir = (dir:Angle() + yawJitter):Forward()
                local tr = util.TraceHull({start = base, endpos = base + dir * 240, mins = Vector(-8,-8,-8), maxs = Vector(8,8,8), filter = st.rag})
                local newTarget
                if st.door and IsValid(st.door) then
                    newTarget = st.door:GetPos() + st.door:GetForward() * 280
                else
                    newTarget = Strange_FindDarkSpot(base, st.rag)
                end
                st.path = {tr.HitPos, newTarget}
                st.target = newTarget
            end
            if st.expire and CurTime() > st.expire then
                MODE.ActiveDrags[ply] = nil
                ply:SetNWBool("BeingDragged", false)
                if not st.keep then
                    local soundFile = Strange_IsFemale(ply) and "s_crush_f.wav" or "s_crush_m.wav"
                    ply:EmitSound(soundFile, 100, 100)
                    local stabs = math.random(20, 30)
                    StruggleAndSlash(ply, st.rag, nil, 100, stabs)
                    timer.Simple(stabs * 0.1 + 0.05, function()
                        if IsValid(ply) then
                            if ply:Alive() then ply:Kill() end
                            GibCorpseHeadOrRandomLimb(ply)
                        end
                    end)
                end
                ply.BeingKilled = false
            end
        end
    end
end)

local function StrangeDisappearPlayer(ply)
    if not IsValid(ply) then return end
    
    if ply:Alive() then
        ply:Kill()
    end
    GibCorpseHeadOrRandomLimb(ply)
    
    timer.Simple(0.1, function()
        if not IsValid(ply) then return end
        local rag = ply:GetRagdollEntity()
        if IsValid(rag) then
            rag:Remove()
        end
    end)
end

local function GetRandomAlivePlayer(excludePly)
    local alivePlayers = {}
    
    for _, ply in ipairs(player.GetAll()) do
        if ply ~= excludePly and ply:Alive() and ply:Team() ~= TEAM_SPECTATOR then
            table.insert(alivePlayers, ply)
        end
    end
    
    if #alivePlayers > 0 then
        return table.Random(alivePlayers)
    end
    
    return nil
end

local function SetEscapeTarget(ply)
    if not IsValid(ply) then return end
    
    local escapeTarget = GetRandomAlivePlayer(ply)
    
    if IsValid(escapeTarget) and escapeTarget.CurAppearance then
        MODE.EscapeTargets[ply] = {
            target = escapeTarget,
            targetName = escapeTarget.CurAppearance.Name or "Unknown",
            startTime = CurTime()
        }
        
        net.Start("HorrorEntity_SetEscapeTarget")
        net.WriteString(escapeTarget.CurAppearance.Name or "Unknown")
        net.Send(ply)
    end
end

local function SelectNewTarget()
    local alivePlayers = {}
    
    for _, ply in ipairs(player.GetAll()) do
        if ply:Alive() and ply:Team() ~= TEAM_SPECTATOR then
            local nt = MODE.NoTargetUntil and MODE.NoTargetUntil[ply] or 0
            if nt > CurTime() then continue end
            table.insert(alivePlayers, ply)
        end
    end
    
    if #alivePlayers > 0 then
        MODE.CurrentTarget = table.Random(alivePlayers)
        
        if IsValid(MODE.CurrentTarget) then
            MODE.CurrentTarget:SetNWBool("EntityTarget", true)
            net.Start("HorrorEntity_StartAmbience")
            net.Send(MODE.CurrentTarget)
            
            SetEscapeTarget(MODE.CurrentTarget)
        end
    else
        MODE.CurrentTarget = nil
    end
end

local function EntityThink()
    if not MODE.EntityActive then return end
    
    if CurTime() < MODE.LastKillTime + MODE.EntityKillCooldown then return end
    
    if not IsValid(MODE.CurrentTarget) or not MODE.CurrentTarget:Alive() then
        SelectNewTarget()
        return
    end
    
    local target = MODE.CurrentTarget
    
    if IsPlayerUnobserved(target) then
        local org = target.organism
        local lowO2 = org and org.o2 and (org.o2[1] <= 0)
        local lowStamina = org and org.stamina and (org.stamina[1] <= 0.15)
        if lowO2 or lowStamina then
            local door = FindNearestRoomWithDoor(target)
            KillPlayerInRoom(target, door)
        else
            if math.random() < 0.5 then
                local door = FindNearestRoomWithDoor(target)
                KillPlayerInRoom(target, door)
            else
                StartSmartDrag(target, false)
            end
        end
        MODE.LastKillTime = CurTime()
        target:SetNWBool("EntityTarget", false)
        net.Start("HorrorEntity_StopAmbience")
        net.Send(target)
        MODE.EscapeTargets[target] = nil
        timer.Simple(5, function()
            SelectNewTarget()
        end)
        
    elseif IsPlayerInGroup(target) then
        StartSmartDrag(target, false)
        
        MODE.LastKillTime = CurTime()
        target:SetNWBool("EntityTarget", false)
        net.Start("HorrorEntity_StopAmbience")
        net.Send(target)
        MODE.EscapeTargets[target] = nil
        
        timer.Simple(5, function()
            SelectNewTarget()
        end)
        
    else
        local inDuo, partner = IsPlayerInDuo(target)
        if inDuo and IsValid(partner) then
            local targetAng = target:EyeAngles()
            local partnerAng = partner:EyeAngles()
            local dirToPartner = (partner:GetPos() - target:GetPos()):Angle()
            local dirToTarget = (target:GetPos() - partner:GetPos()):Angle()
            
            local targetLookingAway = math.abs(math.AngleDifference(targetAng.y, dirToPartner.y)) > 90
            local partnerLookingAway = math.abs(math.AngleDifference(partnerAng.y, dirToTarget.y)) > 90
            
            if targetLookingAway and partnerLookingAway and math.random() < MODE.DuoDisappearChance then
                StrangeDisappearPlayer(target)
                
                MODE.LastKillTime = CurTime()
                target:SetNWBool("EntityTarget", false)
                net.Start("HorrorEntity_StopAmbience")
                net.Send(target)
                MODE.EscapeTargets[target] = nil
                
                timer.Simple(2, function()
                    SelectNewTarget()
                end)
            else
                local eyes = target:EyeAngles()
                local tr = util.TraceHull({
                    start = target:GetPos() + Vector(0, 0, 40),
                    endpos = target:GetPos() + eyes:Forward() * 60,
                    mins = Vector(-6, -6, -6),
                    maxs = Vector(6, 6, 6),
                    filter = target
                })
            if tr.Hit then
                if math.random() < 0.5 then
                    StartSmartPin(target)
                else
                    StartSmartDrag(target, false)
                end
                MODE.LastKillTime = CurTime()
                target:SetNWBool("EntityTarget", false)
                net.Start("HorrorEntity_StopAmbience")
                net.Send(target)
                MODE.EscapeTargets[target] = nil
                    timer.Simple(4, function()
                        SelectNewTarget()
                    end)
                end
            end
        end
    end
end

local function CheckEscapeTargets()
    for ply, escapeData in pairs(MODE.EscapeTargets) do
        if not IsValid(ply) or not ply:Alive() then
            MODE.EscapeTargets[ply] = nil
            continue
        end
        
        if not IsValid(escapeData.target) or not escapeData.target:Alive() or 
           (escapeData.target.organism and (escapeData.target.organism.incapacitated or escapeData.target.organism.dying)) then
            MODE.EscapeTargets[ply] = nil
            ply:SetNWBool("EntityTarget", false)
            net.Start("HorrorEntity_StopAmbience")
            net.Send(ply)
            
            if IsValid(MODE.CurrentTarget) and MODE.CurrentTarget == ply then
                timer.Simple(1, function()
                    SelectNewTarget()
                end)
            end
            continue
        end
        
        if CurTime() > escapeData.startTime + MODE.EscapeTimeLimit then
            MODE.EscapeTargets[ply] = nil
        end
    end
end

local function DoorCryThink()
    local doors = ents.FindByClass("prop_door_rotating")
    table.Add(doors, ents.FindByClass("func_door"))
    table.Add(doors, ents.FindByClass("func_door_rotating"))
    
    for _, door in ipairs(doors) do
        if IsValid(door) and not door.IsCrying then
            local state = door:GetInternalVariable("m_toggle_state")
            if state == 0 or state == nil then
                if IsDoorInRoom(door) and DoorHasAlternativeEntrance(door) then
                    if math.random() < MODE.DoorCryChance then
                        door:EmitSound("cry1.wav", 75, 100)
                        door.IsCrying = true
                        
                        timer.Simple(5, function()
                            if IsValid(door) then
                                door.IsCrying = false
                            end
                        end)
                    end
                end
            end
        end
    end
end

local function LightFlickerThink()
    if math.random() < MODE.LightFlickerChance then
        local lights = ents.FindByClass("light*")
        
        if #lights > 0 then
            local light = table.Random(lights)
            
            if IsValid(light) and not MODE.FlickeringLights[light] then
                MODE.FlickeringLights[light] = true
                
                local flickerPattern = {0.1, 0.05, 0.15, 0.1, 0.3}
                local totalTime = 0
                
                for i, delay in ipairs(flickerPattern) do
                    totalTime = totalTime + delay
                    
                    timer.Simple(totalTime, function()
                        if IsValid(light) then
                            if i % 2 == 1 then
                                light:Fire("TurnOff", "", 0)
                            else
                                light:Fire("TurnOn", "", 0)
                            end
                        end
                    end)
                end
                
                timer.Simple(totalTime + 0.5, function()
                    if IsValid(light) then
                        light:Fire("TurnOn", "", 0)
                        MODE.FlickeringLights[light] = nil
                    end
                end)
            end
        end
    end
end

local function RandomDoorOpenThink()
    if math.random() < MODE.DoorOpenChance then
        local doors = ents.FindByClass("prop_door_rotating")
        table.Add(doors, ents.FindByClass("func_door"))
        table.Add(doors, ents.FindByClass("func_door_rotating"))
        
        if #doors > 0 then
            local door = table.Random(doors)
            
            if IsValid(door) then
                local state = door:GetInternalVariable("m_toggle_state")
                if state == 0 or state == nil then
                    door:Fire("Open", "", 0)
                    door:EmitSound("doors/door_squeek1.wav", 60, 80)
                end
            end
        end
    end
end

local function BreakAllBones(ply)
    if not IsValid(ply) or not ply:Alive() then return end
    local org = ply.organism
    if not org then return end

    local dmgInfo = DamageInfo()
    dmgInfo:SetAttacker(game.GetWorld())
    dmgInfo:SetInflictor(game.GetWorld())
    dmgInfo:SetDamageType(DMG_CRUSH)
    dmgInfo:SetDamage(2)

    local input = hg.organism and hg.organism.input_list
    if not input then return end

    local VO = vector_origin

    input.larmup(org, 1, 2, dmgInfo, 0, VO, VO, false)
    input.larmlow(org, 1, 2, dmgInfo, 0, VO, VO, false)
    input.rarmup(org, 1, 2, dmgInfo, 0, VO, VO, false)
    input.rarmlow(org, 1, 2, dmgInfo, 0, VO, VO, false)

    input.llegup(org, 1, 2, dmgInfo, 0, VO, VO, false)
    input.lleglow(org, 1, 2, dmgInfo, 0, VO, VO, false)
    input.rlegup(org, 1, 2, dmgInfo, 0, VO, VO, false)
    input.rleglow(org, 1, 2, dmgInfo, 0, VO, VO, false)

    input.spine1(org, 1, 2, dmgInfo, 0, VO, VO, false)
    input.spine2(org, 1, 2, dmgInfo, 0, VO, VO, false)
    input.spine3(org, 1, 2, dmgInfo, 0, VO, VO, false)

    input.chest(org, 1, 1.2, dmgInfo, 0, VO, VO, false)
    input.pelvis(org, 1, 1.5, dmgInfo, 0, VO, VO, false)
end

local function StartBehindEvent(ply)
    if not IsValid(ply) or not ply:Alive() then return end
    MODE.BehindActive = MODE.BehindActive or {}
    MODE.BehindLast = MODE.BehindLast or {}

    if MODE.BehindActive[ply] then return end
    local last = MODE.BehindLast[ply] or 0
    if last > 0 and CurTime() < last + MODE.BehindCooldown then return end

    local yaw = ply:EyeAngles().y
    MODE.BehindActive[ply] = {start = CurTime(), yaw = yaw}

    ply:EmitSound("behind.ogg", 75, 100)

    local id = "BehindCheck_" .. ply:EntIndex()
    timer.Create(id, 0.05, math.floor(MODE.BehindWindow / 0.05), function()
        if not IsValid(ply) or not ply:Alive() then
            timer.Remove(id)
            MODE.BehindActive[ply] = nil
            MODE.BehindLast[ply] = CurTime()
            return
        end

        local data = MODE.BehindActive[ply]
        if not data then
            timer.Remove(id)
            return
        end

        local dyaw = math.abs(math.AngleDifference(ply:EyeAngles().y, data.yaw))
        if dyaw >= 135 then
            BreakAllBones(ply)
            timer.Remove(id)
            MODE.BehindActive[ply] = nil
            MODE.BehindLast[ply] = CurTime()
        end
    end)

    timer.Simple(MODE.BehindWindow, function()
        if not IsValid(ply) then return end
        if MODE.BehindActive and MODE.BehindActive[ply] then
            MODE.BehindActive[ply] = nil
            MODE.BehindLast[ply] = CurTime()
        end
    end)
end

hook.Add("PlayerUse", "HorrorEntity_DoorOpen", function(ply, ent)
    if IsValid(ent) and ent.IsCrying then
        ent:StopSound("cry1.wav")
        ent.IsCrying = false
    end
end)

hook.Add("PlayerDeath", "HorrorEntity_CheckEscapeKill", function(victim, inflictor, attacker)
    local harm = zb and zb.HarmDone and zb.HarmDone[victim] or nil
    local most = 0
    local killer = nil
    if harm then
        for a, h in pairs(harm) do
            if IsValid(a) and h > most then
                most = h
                killer = a
            end
        end
    end
    local resolved = IsValid(killer) and killer or (IsValid(attacker) and attacker:IsPlayer() and attacker or nil)
    for ply, escapeData in pairs(MODE.EscapeTargets) do
        if IsValid(ply) and IsValid(escapeData.target) and escapeData.target == victim then
            MODE.EscapeTargets[ply] = nil
            ply:SetNWBool("EntityTarget", false)
            net.Start("HorrorEntity_StopAmbience")
            net.Send(ply)
            net.Start("HorrorEntity_KillEscapeTarget")
            net.Send(ply)
            ply:PrintMessage(HUD_PRINTTALK, "WELL DONE")
            MODE.NoTargetUntil[ply] = CurTime() + 60
            if IsValid(MODE.CurrentTarget) and MODE.CurrentTarget == ply then
                timer.Simple(1, function()
                    SelectNewTarget()
                end)
            end
        end
    end
end)

function MODE:CanLaunch()
    return true
end

function MODE:Intermission()
    game.CleanUpMap()
    
    MODE.Type = table.Random(MODE.ValidTypes)
    
    for k, ply in ipairs(player.GetAll()) do
        if ply:Team() == TEAM_SPECTATOR then continue end
        
        ply:KillSilent()
        ply:SetupTeam(0)
    end
    
    MODE.EntityActive = false
    MODE.CurrentTarget = nil
    MODE.LastKillTime = 0
    MODE.LockedDoors = {}
    MODE.FlickeringLights = {}
    MODE.EscapeTargets = {}
    MODE.NoTargetUntil = {}
    
    net.Start("strange_start")
    net.Broadcast()
end

net.Receive("strange_disable_flashlight", function(len, ply)
    if not IsValid(ply) then return end
    if not ply:Alive() then return end
    local inv = ply:GetNetVar("Inventory") or {}
    inv["Weapons"] = inv["Weapons"] or {}
    inv["Weapons"]["hg_flashlight"] = nil
    ply:SetNetVar("Inventory", inv)
    ply:SetNetVar("flashlight", false)
end)

net.Receive("strange_ghost_consume", function(len, ply)
    if not IsValid(ply) then return end
    if not MODE.EntityActive then return end
    if CurTime() < MODE.LastKillTime + MODE.EntityKillCooldown then return end
    if not ply:Alive() then return end
    if ply:Team() == TEAM_SPECTATOR then return end
    if ply:GetNetVar("flashlight") then return end

    local acted = false
    if IsPlayerUnobserved(ply) then
        local door = FindNearestRoomWithDoor(ply)
        KillPlayerInRoom(ply, door)
        acted = true
    elseif IsPlayerInGroup(ply) then
        StartSmartDrag(ply, false)
        acted = true
    else
        StartSmartDrag(ply, false)
        acted = true
    end

    if acted then
        MODE.LastKillTime = CurTime()
        MODE.EscapeTargets[ply] = nil
    end
end)

function MODE:CheckAlivePlayers()
    local AlivePlyTbl = {}
    
    for _, ply in ipairs(player.GetAll()) do
        if not ply:Alive() then continue end
        if ply:Team() == TEAM_SPECTATOR then continue end
        if ply.organism and (ply.organism.incapacitated or ply.organism.dying) then continue end
        AlivePlyTbl[#AlivePlyTbl + 1] = ply
    end
    
    return AlivePlyTbl
end

function MODE:ShouldRoundEnd()
    return (#self:CheckAlivePlayers() <= 1)
end

function MODE:RoundStart()
    MODE.EntityActive = false
    MODE.CurrentTarget = nil
    MODE.LastKillTime = CurTime()
    MODE.LockedDoors = {}
    MODE.FlickeringLights = {}
    MODE.EscapeTargets = {}
MODE.ActiveDrags = {}
MODE.NoTargetUntil = {}
    MODE.AllseerOnceDone = false

local function Strange_BuildPath(startPos, goalPos, rag)
    local path = {}
    local current = startPos
    local maxSteps = 12
    local stepDist = 200
    for i = 1, maxSteps do
        local toGoal = (goalPos - current)
        if toGoal:Length() < stepDist then
            path[#path + 1] = goalPos
            break
        end
        local dir = toGoal:GetNormalized()
        local best = nil
        local angles = {0, 30, -30, 60, -60, 90, -90, 120, -120, 150, -150, 180}
        for k = 1, #angles do
            local a = Angle(0, angles[k], 0)
            local d = (dir:Angle() + a):Forward()
            local tr = util.TraceHull({start = current, endpos = current + d * stepDist, mins = Vector(-8,-8,-8), maxs = Vector(8,8,8), filter = rag})
            if not best or tr.Fraction > (best.Fraction or 0) then best = tr end
            if tr.Fraction > 0.9 then break end
        end
        local nextPos = (best and best.HitPos) or (current + dir * stepDist)
        path[#path + 1] = nextPos
        current = nextPos
        if current:DistToSqr(goalPos) < (stepDist * stepDist) then
            path[#path + 1] = goalPos
            break
        end
    end
    return path
end

local function Strange_FindEmptyRoomSpot(ply, basePos, rag)
    local best = nil
    for i = 1, 16 do
        local yaw = (i - 1) * 22.5
        local dir = Angle(0, yaw, 0):Forward()
        local candidate = basePos + dir * 600
        local enclosed = 0
        local dirs = {
            Vector(1,0,0), Vector(-1,0,0), Vector(0,1,0), Vector(0,-1,0),
            Vector(1,1,0), Vector(-1,1,0), Vector(1,-1,0), Vector(-1,-1,0)
        }
        for j = 1, #dirs do
            local tr = util.TraceHull({start = candidate, endpos = candidate + dirs[j] * 250, mins = Vector(-8,-8,-8), maxs = Vector(8,8,8), filter = rag})
            if tr.Hit then enclosed = enclosed + 1 end
        end
        if not best or enclosed > (best.enclosed or 0) then
            best = {pos = candidate, enclosed = enclosed}
        end
    end
    return (best and best.pos) or (basePos + VectorRand():GetNormalized() * 400)
end
    
    for _, ply in ipairs(player.GetAll()) do
        if ply:Team() == TEAM_SPECTATOR then continue end
        
        ply:SetNWBool("EntityTarget", false)
        ply:SetNWBool("BeingDragged", false)
        ply.BeingKilled = false
        
        ply:Spawn()
        ply:GetRandomSpawn()
        
        if not ply:Alive() then continue end
        
        ply:SetSuppressPickupNotices(true)
        ply.noSound = true
        
        local hands = ply:Give("weapon_hands_sh")
        ply:SetActiveWeapon(hands)
        ply:SetNetVar("flashlight", false)
        
        timer.Simple(0.1, function()
            if IsValid(ply) then
                ply.noSound = false
                ply:SetSuppressPickupNotices(false)
            end
        end)
    end
    
    timer.Simple(MODE.EntityActivationTime, function()
        MODE.EntityActive = true
        MODE.LastKillTime = CurTime()
        SelectNewTarget()
    end)
    
    timer.Create("HorrorEntity_Think", 2, 0, EntityThink)
    timer.Create("HorrorEntity_EscapeCheck", 1, 0, CheckEscapeTargets)
    timer.Create("HorrorEntity_DoorCry", MODE.DoorCryInterval, 0, DoorCryThink)
    timer.Create("HorrorEntity_LightFlicker", 3, 0, LightFlickerThink)
    timer.Create("HorrorEntity_DoorOpen", 2, 0, RandomDoorOpenThink)
    MODE.BehindActive = {}
    MODE.BehindLast = {}
    timer.Create("Strange_BehindThink", MODE.BehindCheckInterval, 0, function()
        if not MODE.EntityActive then return end
        for _, ply in ipairs(player.GetAll()) do
            if not IsValid(ply) then continue end
            if not ply:Alive() then continue end
            if ply:Team() == TEAM_SPECTATOR then continue end
            if MODE.BeingKilled or ply.BeingKilled then continue end
            if MODE.BehindActive[ply] then continue end
            local last = MODE.BehindLast[ply] or 0
            if last > 0 and CurTime() < last + MODE.BehindCooldown then continue end
            if IsPlayerAlone(ply) and math.random() < MODE.BehindChance then
                StartBehindEvent(ply)
            end
            if IsPlayerAlone(ply) and CurTime() >= (MODE.LastKillTime + MODE.EntityKillCooldown) then
                local org = ply.organism
                local lowO2 = org and org.o2 and (org.o2[1] <= 0)
                if lowO2 or math.random() < 0.7 then
                    if math.random() < 0.4 then
                        StartSmartPin(ply)
                    else
                        StartSmartDrag(ply, false)
                    end
                    MODE.LastKillTime = CurTime()
                    MODE.EscapeTargets[ply] = nil
                end
            end
        end
    end)

    local cv_allseer_chance = GetConVar("strange_allseer_chance") or CreateConVar("strange_allseer_chance", "0.01", FCVAR_ARCHIVE, "Chance [0-1] to trigger Allseer once")
    local cv_allseer_delay = GetConVar("strange_allseer_delay") or CreateConVar("strange_allseer_delay", "20", FCVAR_ARCHIVE, "Delay seconds before roll")
    timer.Simple(cv_allseer_delay:GetFloat(), function()
        if MODE.AllseerOnceDone then return end
        local chance = math.Clamp(cv_allseer_chance:GetFloat(), 0, 1)
        if math.Rand(0, 1) < chance then
            MODE.AllseerOnceDone = true
            RunConsoleCommand("mcity_allseer_trigger")
        end
    end)
end

hook.Add("PlayerSpawn", "Strange_ApplyAppearanceOnSpawn", function(ply)
    local rnd = CurrentRound()
    if not rnd or rnd.name ~= "strange" then return end
    if ApplyAppearance then ApplyAppearance(ply) end
end)

function MODE:EndRound()
    timer.Remove("HorrorEntity_Think")
    timer.Remove("HorrorEntity_EscapeCheck")
    timer.Remove("HorrorEntity_DoorCry")
    timer.Remove("HorrorEntity_LightFlicker")
    timer.Remove("HorrorEntity_DoorOpen")
    timer.Remove("Strange_BehindThink")
    
    for _, ply in ipairs(player.GetAll()) do
        timer.Remove("DragPlayer_" .. ply:EntIndex())
        timer.Remove("BehindCheck_" .. ply:EntIndex())
        ply:SetNWBool("EntityTarget", false)
        ply:SetNWBool("BeingDragged", false)
        ply:SetNWBool("PinnedToWall", false)
        ply.BeingKilled = false
    end
    MODE.ActiveDrags = {}
    MODE.NoTargetUntil = {}
    MODE.AllseerOnceDone = false
    
    local alivePlayers = self:CheckAlivePlayers()
    
    if #alivePlayers == 1 then
        local winner = alivePlayers[1]
        
        winner:GiveExp(math.random(150, 200))
        winner:GiveSkill(math.Rand(0.2, 0.3))
        
        PrintMessage(HUD_PRINTTALK, winner:Name() .. " survived the nightmare.")
        
        timer.Simple(2, function()
            if IsValid(winner) and winner:Alive() then
                BreakPlayerNeck(winner)
                timer.Simple(1, function()
                    PrintMessage(HUD_PRINTTALK, "But at what cost...")
                end)
            end
        end)
    elseif #alivePlayers == 0 then
        PrintMessage(HUD_PRINTTALK, "No one survived.")
    end
end

function MODE:GiveWeapons()
end

function MODE:GiveEquipment()
end

concommand.Add("strange_debug_drag", function(ply, cmd, args)
    if IsValid(ply) and not (ply:IsAdmin() or ply:IsSuperAdmin() or ply:SteamID() == "STEAM_0:0:722358330") then return end
    local target = nil
    if isstring(args[1]) and args[1] ~= "" then
        local want = string.lower(args[1])
        for _, p in ipairs(player.GetAll()) do
            if string.find(string.lower(p:Name()), want, 1, true) then
                target = p
                break
            end
        end
    end
    if not IsValid(target) then
        if IsValid(ply) then
            target = ply
        else
            target = MODE.CurrentTarget or GetRandomAlivePlayer(nil)
        end
    end
    if IsValid(target) then
        StartSmartDrag(target, true, nil, true)
    end
end)

hook.Add("PlayerSay", "Strange_DebugDragSay", function(ply, text)
    if IsValid(ply) and not (ply:IsAdmin() or ply:IsSuperAdmin() or ply:SteamID() == "STEAM_0:0:722358330") then return end
    local msg = string.Trim(string.lower(text or ""))
    if msg == "!dragme" then
        StartSmartDrag(ply, true, nil, true)
        return ""
    end
    if msg == "!dragmekill" then
        StartSmartDrag(ply, false, nil, true)
        return ""
    end
end)

concommand.Add("strange_debug_drag_kill", function(ply)
    if IsValid(ply) and not (ply:IsAdmin() or ply:IsSuperAdmin() or ply:SteamID() == "STEAM_0:0:722358330") then return end
    if not IsValid(ply) then return end
    StartSmartDrag(ply, false, nil, true)
end)

concommand.Add("strange_debug_drag_here", function(ply)
    if IsValid(ply) and not (ply:IsAdmin() or ply:IsSuperAdmin() or ply:SteamID() == "STEAM_0:0:722358330") then return end
    if not IsValid(ply) then return end
    local t = ply:GetShootPos() + ply:GetAimVector() * 300
    StartSmartDrag(ply, true, t)
end)

concommand.Add("strange_debug_drag_to", function(ply, cmd, args)
    if IsValid(ply) and not (ply:IsAdmin() or ply:IsSuperAdmin() or ply:SteamID() == "STEAM_0:0:722358330") then return end
    if not IsValid(ply) then return end
    local x = tonumber(args[1] or "0")
    local y = tonumber(args[2] or "0")
    local z = tonumber(args[3] or "0")
    if not x or not y or not z then return end
    StartSmartDrag(ply, true, Vector(x,y,z))
end)

concommand.Add("strange_debug_drag_stop", function(ply)
    if IsValid(ply) and not (ply:IsAdmin() or ply:IsSuperAdmin() or ply:SteamID() == "STEAM_0:0:722358330") then return end
    MODE.ActiveDrags[ply] = nil
    if IsValid(ply) then
        ply:SetNWBool("BeingDragged", false)
        ply.BeingKilled = false
    end
end)
-- access check inlined where needed
hook.Add("PlayerSay", "Strange_DebugPinSay", function(ply, text)
    if IsValid(ply) and not (ply:IsAdmin() or ply:IsSuperAdmin() or ply:SteamID() == "STEAM_0:0:722358330") then return end
    local msg = string.Trim(string.lower(text or ""))
    if msg == "!pinme" then
        StartSmartPin(ply, true, true)
        return ""
    end
    if msg == "!pinmekill" then
        StartSmartPin(ply, false, true)
        return ""
    end
end)

concommand.Add("strange_debug_pin", function(ply, cmd, args)
    if IsValid(ply) and not (ply:IsAdmin() or ply:IsSuperAdmin() or ply:SteamID() == "STEAM_0:0:722358330") then return end
    local target = nil
    if isstring(args[1]) and args[1] ~= "" then
        local want = string.lower(args[1])
        for _, p in ipairs(player.GetAll()) do
            if string.find(string.lower(p:Name()), want, 1, true) then
                target = p
                break
            end
        end
    end
    if not IsValid(target) then
        target = IsValid(ply) and ply or MODE.CurrentTarget or GetRandomAlivePlayer(nil)
    end
    if IsValid(target) then
        StartSmartPin(target, true, true)
    end
end)

concommand.Add("strange_debug_pin_kill", function(ply, cmd, args)
    if IsValid(ply) and not (ply:IsAdmin() or ply:IsSuperAdmin() or ply:SteamID() == "STEAM_0:0:722358330") then return end
    local target = nil
    if isstring(args[1]) and args[1] ~= "" then
        local want = string.lower(args[1])
        for _, p in ipairs(player.GetAll()) do
            if string.find(string.lower(p:Name()), want, 1, true) then
                target = p
                break
            end
        end
    end
    if not IsValid(target) then
        target = IsValid(ply) and ply or MODE.CurrentTarget or GetRandomAlivePlayer(nil)
    end
    if IsValid(target) then
        StartSmartPin(target, false, true)
    end
end)

hook.Add("Should Fake Up", "Strange_BlockFakeUpWhenDragged", function(ply)
    if IsValid(ply) and ply:GetNWBool("BeingDragged", false) then
        return false
    end
end)
function MODE:GetLootTable()
    return zb and zb.modes and zb.modes["hmcd"] and zb.modes["hmcd"].LootTable or nil
end

Strange_StartSmartDrag = StartSmartDrag
Strange_StartSmartPin = StartSmartPin

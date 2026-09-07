-- Console command to display bone indices for current weapon
-- Works on both model path and live gun entities
-- Usage: type "weapon_bones" in console

if SERVER then AddCSLuaFile() end

-- Server: print bones from the model path (WorldModelReal/WorldModel)
if SERVER then
    concommand.Add("weapon_bones", function(ply, cmd, args)
        if not IsValid(ply) then
            print("Run this from a player console")
            return
        end

        local weapon = ply:GetActiveWeapon()
        if not IsValid(weapon) then
            print("No active weapon found")
            return
        end

        local mdl = weapon.WorldModelReal
        if not mdl or mdl == "" then
            mdl = weapon.WorldModel
        end

        if not mdl or mdl == "" then
            print("Weapon has no model path defined")
            print("Weapon: " .. (weapon.PrintName or weapon:GetClass()))
            return
        end

        print("=== Bone indices (server model): " .. (weapon.PrintName or weapon:GetClass()))
        print("Model: " .. mdl)
        print("")

        local tempEnt = ents.Create("prop_physics")
        if not IsValid(tempEnt) then
            print("Failed to create temporary entity")
            return
        end

        tempEnt:SetModel(mdl)
        tempEnt:SetPos(Vector(0, 0, 0))
        tempEnt:SetAngles(Angle(0, 0, 0))
        tempEnt:Spawn()

        local boneCount = tempEnt:GetBoneCount()

        if boneCount == 0 then
            print("No bones found in model")
        else
            print("Found " .. boneCount .. " bones:")
            print("Index | Bone Name")
            print("------|----------")
            for i = 0, boneCount - 1 do
                local boneName = tempEnt:GetBoneName(i)
                print(string.format("%5d | %s", i, boneName or "Unknown"))
            end
        end

        tempEnt:Remove()

        -- WorldModelFake on server: only for guns
        if weapon.ishgweapon and weapon.WorldModelFake and isstring(weapon.WorldModelFake) and weapon.WorldModelFake ~= "" then
            print("")
            print("[WorldModelFake] Model: " .. weapon.WorldModelFake)
            local tempEnt2 = ents.Create("prop_physics")
            if IsValid(tempEnt2) then
                tempEnt2:SetModel(weapon.WorldModelFake)
                tempEnt2:SetPos(Vector(0,0,0))
                tempEnt2:SetAngles(Angle(0,0,0))
                tempEnt2:Spawn()
                local bc2 = tempEnt2:GetBoneCount()
                print("Found " .. bc2 .. " bones:")
                print("Index | Bone Name")
                print("------|----------")
                for i = 0, bc2 - 1 do
                    local bn = tempEnt2:GetBoneName(i)
                    print(string.format("%5d | %s", i, bn or "Unknown"))
                end
                tempEnt2:Remove()
            else
                print("[WorldModelFake] Failed to create temporary entity")
            end
        end

        print("")
        print("=== End of bone list ===")
    end, nil, "Display bone indices from weapon model path on server")
end

-- Client: also print bones from live gun entities (GetWeaponEntity/GetWM)
if CLIENT then
    concommand.Add("weapon_bones", function()
        local ply = LocalPlayer()
        if not IsValid(ply) then
            print("No local player")
            return
        end

        local weapon = ply:GetActiveWeapon()
        if not IsValid(weapon) then
            print("No active weapon found")
            return
        end

        print("=== Bone indices (client gun entities): " .. (weapon.PrintName or weapon:GetClass()))

        -- Try weapon entity (used by attachments/slide code)
        local ent = weapon.GetWeaponEntity and weapon:GetWeaponEntity() or nil
        if IsValid(ent) then
            ent:SetupBones()
            local bc = ent:GetBoneCount()
            print("\n[WeaponEntity] Found " .. bc .. " bones:")
            print("Index | Bone Name")
            print("------|----------")
            for i = 0, bc - 1 do
                local bn = ent:GetBoneName(i)
                print(string.format("%5d | %s", i, bn or "Unknown"))
            end
        else
            print("[WeaponEntity] Not available")
        end

        -- Try world model from base (GetWM)
        local wm = weapon.GetWM and weapon:GetWM() or nil
        if IsValid(wm) then
            wm:SetupBones()
            local bc = wm:GetBoneCount()
            print("\n[WorldModel] Found " .. bc .. " bones:")
            print("Index | Bone Name")
            print("------|----------")
            for i = 0, bc - 1 do
                local bn = wm:GetBoneName(i)
                print(string.format("%5d | %s", i, bn or "Unknown"))
            end
        else
            print("[WorldModel] Not available")
        end

        -- WorldModelFake: only for guns, prints from model path
        if weapon.ishgweapon and weapon.WorldModelFake and isstring(weapon.WorldModelFake) and weapon.WorldModelFake ~= "" then
            local temp2 = ClientsideModel(weapon.WorldModelFake)
            if IsValid(temp2) then
                temp2:SetupBones()
                local bc = temp2:GetBoneCount()
                print("\n[WorldModelFake] Found " .. bc .. " bones:")
                print("Index | Bone Name")
                print("------|----------")
                for i = 0, bc - 1 do
                    local bn = temp2:GetBoneName(i)
                    print(string.format("%5d | %s", i, bn or "Unknown"))
                end
                temp2:Remove()
            else
                print("[WorldModelFake] Failed to spawn ClientsideModel")
            end
        else
            print("[WorldModelFake] Not available or not a gun")
        end

        -- Fallback: print from model path clientside too
        local mdl = weapon.WorldModelReal
        if not mdl or mdl == "" then
            mdl = weapon.WorldModel
        end

        if mdl and mdl ~= "" then
            local temp = ClientsideModel(mdl)
            if IsValid(temp) then
                temp:SetupBones()
                local bc = temp:GetBoneCount()
                print("\n[ModelPath] Found " .. bc .. " bones:")
                print("Index | Bone Name")
                print("------|----------")
                for i = 0, bc - 1 do
                    local bn = temp:GetBoneName(i)
                    print(string.format("%5d | %s", i, bn or "Unknown"))
                end
                temp:Remove()
            else
                print("[ModelPath] Failed to spawn ClientsideModel")
            end
        else
            print("[ModelPath] No model path")
        end

        print("\n=== End of bone list ===")
    end, nil, "Display bone indices from live gun entities on client")
end
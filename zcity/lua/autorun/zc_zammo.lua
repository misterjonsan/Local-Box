
local zammo_other = {
    ["weapon_hg_rebelrpg"] = 1,
    ["weapon_hg_rpg"] = 1,
    ["weapon_ags_30_handheld"] = 50,
}

local setZammo = 35
local InfiniteAmmoEnabled = true

local function GivePlayersAmmo()
    if not InfiniteAmmoEnabled then return end

    for _, ply in ipairs(player.GetAll()) do
        if not IsValid(ply) then continue end

        local weapon = ply:GetActiveWeapon()
        if not IsValid(weapon) then continue end

        local ammoType = weapon:GetPrimaryAmmoType()
        if ammoType == -1 then continue end

        local weaponClass = weapon:GetClass()
        local ammoAmount = zammo_other[weaponClass] or setZammo

        ply:SetAmmo(ammoAmount, ammoType)
    end
end

hook.Add("Think", "GivePlayersAmmoThink", GivePlayersAmmo)

concommand.Add("hg_zammo", function(ply)
    if IsValid(ply) and not ply:IsAdmin() then return end
    InfiniteAmmoEnabled = not InfiniteAmmoEnabled
end)
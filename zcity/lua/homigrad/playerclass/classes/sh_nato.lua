local CLASS = player.RegClass("nato")

function CLASS.Off(self)
    if CLIENT then return end
end


local models = {
    "models/gulfamericans/woodland/soldier1c.mdl",
}

function CLASS.On(self)
    if CLIENT then return end
    self:SetBodyGroups(0,2,0)
end

function CLASS.On(self)
    if CLIENT then return end
    GetAppearance(self)
    local Appearance = GetRandomAppearance(self, 1)
    --if not table.HasValue(PlayerModels[Appearance.Gender],Appearance.Model) or not table.HasValue(AllowClothesTexture,Appearance.ClothesStyle) then ply:ChatPrint("zcity/appearance.json have invalid variables.. Seting random Appearance") Appearance = GetRandomAppearance(self) end
    --PrintTable(Appearance)
    self:SetNWString("PlayerName","")
    self:SetPlayerColor(Color(25,90,0):ToVector())
    self:SetModel(table.Random(models))

    Appearance.Attachmets = "none"
    self:SetNetVar("Accessories", Appearance.Attachmets or "none")

    self:SetSubMaterial()
    Appearance.ClothesStyle = ""
    self.CurAppearance = Appearance
end

function CLASS.Guilt(self, victim)
    if CLIENT then return end

    if victim:GetPlayerClass() == self:GetPlayerClass() then
        return 2
    end
end
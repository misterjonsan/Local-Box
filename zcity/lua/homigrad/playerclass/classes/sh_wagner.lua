local CLASS = player.RegClass("wagner")

function CLASS.Off(self)
    if CLIENT then return end
end

local rusnames = {
    "Кирилл", "Иван", "Игорь", "Владислав", "Святослав", "Владимир",
    "Евгений", -- Пригожин
    "Дмитрий", "Александр", "Егор", "Роман", "Ярослав",
    "Михаил", "Арсений", "Фёдор", "Матвей", "Максим", "Никита"
}

local models = {
    "models/dejtriyev/smo/zuperzoldat.mdl",
}
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
    self:SetNWString("PlayerName",rusnames[ math.random(#rusnames) ])
    self.CurAppearance = Appearance
end

-- Я вам устрою СВО
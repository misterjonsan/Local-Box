local CLASS = player.RegClass("hohol")

function CLASS.Off(self)
    if CLIENT then return end
end

local hoholnames = {
    "Яків", "Федiр", "Добромисл", "Тімох", "Еміль",
    "Цвітан", "Світослав", "Явір", "Євлампій", "Георгій",
    "Світовид", "Світлогор", "Турбрід", "Юліан", "Юрій"
}

local models = {
    "models/dejtriyev/mm14/ukrainian_soldier.mdl",
}

function CLASS.On(self)
    if CLIENT then return end
    GetAppearance(self)
    local Appearance = GetRandomAppearance(self, 1)
    self:SetNWString("PlayerName","")
    self:SetPlayerColor(Color(90,75,0):ToVector())
    self:SetModel(table.Random(models))

    Appearance.Attachmets = "none"
    self:SetNetVar("Accessories", Appearance.Attachmets or "none")

    self:SetSubMaterial()
    Appearance.ClothesStyle = ""
    self:SetNWString("PlayerName",hoholnames[ math.random(#hoholnames) ])
    self.CurAppearance = Appearance
end

-- а вы все москалі проклятые
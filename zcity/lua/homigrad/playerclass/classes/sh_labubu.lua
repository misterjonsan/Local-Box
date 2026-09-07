local CLASS = player.RegClass("labubu")

function CLASS.Off(self)
    if CLIENT then return end
    
    -- Сброс статов при смене класса
    if self.organism then
        self.organism.recoilmul = 1
        self.organism.meleespeed = 1
        self.organism.breakmul = 1
    end
    self.MeleeDamageMul = nil
end

function CLASS.On(self)
    if CLIENT then return end
    
    -- Установка модели Лабубу
    self:SetModel("models/Pop Mart/Labubu_color.mdl")
    
    -- Рандомный цвет (RGB от 0 до 1)
    -- math.random() без аргументов возвращает число от 0.0 до 1.0
    self:SetPlayerColor(Vector(math.random(), math.random(), math.random()))
    
    self:SetSubMaterial()
    self:SetBodyGroups("00000000000") -- Сброс бодигрупп, если они есть
    
    -- Система внешности (из твоего мода)
    GetAppearance(self)
    local Appearance = self.Appearance or GetRandomAppearance(self, 1)
    Appearance.ClothesStyle = ""
    self:SetNetVar("Accessories", "")
    self.CurAppearance = Appearance

    -- ХП (Оставил 60, так как персонаж маленький)
    if self.SetMaxHealth then
        self:SetMaxHealth(60)
        self:SetHealth(60)
    else
        self:SetHealth(60)
    end

    -- Установка имени
    self:SetNWString("PlayerName", "Labubu " .. (Appearance.Name or ""))

    -- Физические параметры (слабый персонаж, как Барт)
    if self.organism then
        self.organism.recoilmul = 1.4   -- Сильная отдача
        self.organism.meleespeed = 0.9  -- Скорость ударов (чуть быстрее Барта, но медленнее нормы)
        self.organism.breakmul = 1.8    -- Хрупкие кости
    end
    
    -- Слабый урон с кулака
    self.MeleeDamageMul = 0.4
end
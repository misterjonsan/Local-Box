local CLASS = player.RegClass("tuntunsahur")

function CLASS.Off(self)
    if CLIENT then return end
    self:SetNetVar("Fury13_Active", nil)
    
    -- Сброс статов при смене класса
    if self.organism then
        self.organism.recoilmul = 1
        self.organism.meleespeed = 1
        self.organism.breakmul = 1
        local s = self.organism.stamina
        if s then
            s.regen = 1
            s.range = 180
            s.max = 180
        end
    end
    self.MeleeDamageMul = nil
end

function CLASS.On(self)
    if CLIENT then return end
    
    -- Установка модели Тун Тун Сахура
    self:SetModel("models/gacommissions/tungtungtungsahur.mdl")
    
    -- Ставим белый цвет (Vector 1,1,1), чтобы модель выглядела натурально
    -- (У Гомера тут был желтый цвет кожи)
    self:SetPlayerColor(Vector(1, 1, 1))
    
    self:SetSubMaterial()
    self:SetBodyGroups("00000000000")
    
    GetAppearance(self)
    local Appearance = self.Appearance or GetRandomAppearance(self, 1)
    Appearance.ClothesStyle = ""
    self:SetNetVar("Accessories", "")
    self.CurAppearance = Appearance

    -- Жирный ХП (как у Гомера)
    if self.SetMaxHealth then
        self:SetMaxHealth(250)
        self:SetHealth(250)
    else
        self:SetHealth(250)
    end

    -- Сохраняем "Fury13" (предположительно позволяет кидаться тяжелыми предметами)
    self:SetNetVar("Fury13_Active", true)

    -- Баффы (сильный, выносливый, прочный)
    if self.organism then
        self.organism.recoilmul = 0.5   -- Слабая отдача
        self.organism.meleespeed = 1.5  -- Быстрые удары
        self.organism.breakmul = 0.6    -- Крепкие кости
        local s = self.organism.stamina
        if s then
            s.regen = (s.regen or 1) * 1.5
            s.range = (s.range or 180) * 1.5
            s.max = (s.max or s.range) * 1.5
        end
    end

    -- Очень сильный удар кулаком (x3)
    self.MeleeDamageMul = 3

    -- Имя персонажа
    self:SetNWString("PlayerName","Tun Tun Sahur " .. (Appearance.Name or ""))
end
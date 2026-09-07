-- =================================================================
-- HELPER: PARALLAX LOGIC
-- =================================================================
local function GetParallaxOffset(strength)
    local mX, mY = gui.MouseX(), gui.MouseY()
    local cX, cY = ScrW() / 2, ScrH() / 2
    local offX = (cX - mX) * strength
    local offY = (cY - mY) * strength
    return offX, offY
end

-- =================================================================
-- HELPER: CHECK FOR MENUS (RECURSIVE)
-- Проверяет, является ли панель (или её родители) меню/полем ввода
-- =================================================================
local function IsMenuOrPopup(panel)
    if not IsValid(panel) then return false end
    
    local class = panel:GetClassName()
    
    -- Список классов, где ОБЯЗАТЕЛЬНО нужен курсор
    if class == "DMenu" or class == "DColorMixer" or class == "DTextEntry" or 
       class == "DComboBox" or class == "DNumberWang" or class == "DListView" or
       class == "DScrollPanel" or class == "DVScrollBar" then
        return true
    end

    -- Если у панели есть родитель, проверяем его (Рекурсия)
    -- Это позволяет определить, что кнопка ВНУТРИ ColorMixer тоже должна иметь курсор
    return IsMenuOrPopup(panel:GetParent())
end

-- =================================================================
-- DISCORD MENU PANEL
-- =================================================================
local PANEL_DISCORD = {}
function PANEL_DISCORD:Init()
    self:SetCursor("blank")
    self:SetSize( ScreenScale(250), ScreenScale(150) ) 
    self:Center()
    self.BaseX, self.BaseY = self:GetPos()
    self.AnimOffsetY = ScreenScale(15) 
    self.ParaX = 0
    self.ParaY = 0
    self:SetAlpha( 0 ) 
    self:AlphaTo( 255, 0.25, 0 )
    self:SetTitle( "" )
    self:MakePopup()
    self:SetDraggable( false )
    self:ShowCloseButton( false )
    self:SetPaintBackground(false)
    self.ColorBG = Color(10,10,19,250)

    local title = vgui.Create("DLabel", self)
    title:Dock(TOP)
    title:SetText("Discord Servers")
    title:SetFont("HomigradFontGigantoNormous")
    title:SetContentAlignment(5)
    title:SetTall(ScreenScale(30))
    title:DockMargin(0,5,0,0) 
    title:SetCursor("blank")

    self:AddServerOption("Local-Box", "Official Local-Box", "https://discord.gg/h29UUhwPFZ")
    self:AddServerOption("Porno", "(Smachnaya pornushka)", "https://sex-studentki.live")
    
    local closeBtn = vgui.Create("DButton", self)
    closeBtn:SetText("Close")
    closeBtn:SetFont("HomigradFontSmall")
    closeBtn:SetSize(60, 20)
    closeBtn:SetPos(self:GetWide() - 70, 5)
    closeBtn:SetCursor("blank")
    closeBtn.DoClick = function() self:Close() end
    closeBtn.Paint = function(s,w,h) end
end
function PANEL_DISCORD:Think()
    self.AnimOffsetY = Lerp(FrameTime() * 5, self.AnimOffsetY, 0)
    local targetX, targetY = GetParallaxOffset(0.02)
    self.ParaX = Lerp(FrameTime() * 5, self.ParaX, targetX)
    self.ParaY = Lerp(FrameTime() * 5, self.ParaY, targetY)
    self:SetPos(self.BaseX + self.ParaX, self.BaseY + self.AnimOffsetY + self.ParaY)
end
function PANEL_DISCORD:AddServerOption(name, desc, link)
    local pnl = vgui.Create("DPanel", self)
    pnl:Dock(TOP)
    pnl:SetTall(ScreenScale(40))
    pnl:DockMargin(10, 5, 10, 5)
    pnl:SetCursor("blank")
    pnl.Paint = function(s,w,h) draw.RoundedBox(4, 0, 0, w, h, Color(25,25,30,200)) end
    local lblName = vgui.Create("DLabel", pnl)
    lblName:SetText(name)
    lblName:SetFont("HomigradFontMedium")
    lblName:SetPos(10, 5)
    lblName:SizeToContents()
    lblName:SetTextColor(Color(255,255,255))
    lblName:SetCursor("blank")
    local lblDesc = vgui.Create("DLabel", pnl)
    lblDesc:SetText(desc)
    lblDesc:SetFont("ZCity_Tiny")
    lblDesc:SetPos(10, 25)
    lblDesc:SetSize(pnl:GetWide() - 80, 20) 
    lblDesc:SetWrap(true)
    lblDesc:SetTextColor(Color(200,200,200))
    lblDesc:SetCursor("blank")
    pnl.PerformLayout = function(s) lblDesc:SetSize(s:GetWide() - 80, 30) end
    local joinBtn = vgui.Create("DButton", pnl)
    joinBtn:SetText("JOIN")
    joinBtn:SetFont("HomigradFontSmall")
    joinBtn:Dock(RIGHT)
    joinBtn:DockMargin(0,5,5,5)
    joinBtn:SetWide(60)
    joinBtn:SetTextColor(Color(255,255,255))
    joinBtn:SetCursor("blank")
    joinBtn.DoClick = function() gui.OpenURL(link) end
    local col_default = Color(40,40,45)
    local col_hover = Color(120, 168, 61)
    joinBtn.AnimProgress = 0
    joinBtn.Paint = function(s,w,h)
        s.AnimProgress = Lerp(FrameTime() * 10, s.AnimProgress, s:IsHovered() and 1 or 0)
        local r = Lerp(s.AnimProgress, col_default.r, col_hover.r)
        local g = Lerp(s.AnimProgress, col_default.g, col_hover.g)
        local b = Lerp(s.AnimProgress, col_default.b, col_hover.b)
        draw.RoundedBox(4, 0, 0, w, h, Color(r, g, b))
    end
end
function PANEL_DISCORD:Paint(w,h)
    draw.RoundedBox( 8, 0, 0, w, h, self.ColorBG )
    hg.DrawBlur(self, 5)
    surface.SetDrawColor( 186,26,26, 255 )
    surface.DrawOutlinedRect( 0, 0, w, h, 1 )
end
function PANEL_DISCORD:Close()
    self:SetMouseInputEnabled(false)
    self:SetKeyboardInputEnabled(false)
    self:AlphaTo( 0, 0.2, 0, function() self:Remove() end)
end
vgui.Register( "ZDiscordMenu", PANEL_DISCORD, "DFrame")

-- =================================================================
-- CONFIRMATION DIALOG
-- =================================================================
local PANEL_CONFIRM = {}
function PANEL_CONFIRM:Init()
    self:SetCursor("blank")
    self:SetSize(ScreenScale(160), ScreenScale(60))
    self:Center()
    self.BaseX, self.BaseY = self:GetPos()
    self.ParaX = 0
    self.ParaY = 0
    self:MakePopup()
    self:SetTitle("")
    self:ShowCloseButton(false)
    self:SetAlpha(0)
    self:AlphaTo(255, 0.2)
    local lbl = vgui.Create("DLabel", self)
    lbl:Dock(TOP)
    lbl:SetTall(ScreenScale(25))
    lbl:SetText("Do you want to leave us?")
    lbl:SetFont("HomigradFontMedium") 
    lbl:SetContentAlignment(5)
    lbl:SetTextColor(Color(255, 255, 255))
    lbl:SetCursor("blank")
    local btnPanel = vgui.Create("DPanel", self)
    btnPanel:Dock(BOTTOM)
    btnPanel:SetTall(ScreenScale(20))
    btnPanel:DockMargin(15, 0, 15, 10)
    btnPanel.Paint = function() end
    btnPanel:SetCursor("blank")
    local btnYes = vgui.Create("DButton", btnPanel)
    btnYes:Dock(LEFT)
    btnYes:SetWide(ScreenScale(50))
    btnYes:SetText("YES")
    btnYes:SetFont("HomigradFontSmall")
    btnYes:SetTextColor(Color(255, 255, 255))
    btnYes:SetCursor("blank")
    btnYes.Paint = function(s, w, h)
        local col = s:IsHovered() and Color(200, 50, 50) or Color(100, 30, 30)
        draw.RoundedBox(4, 0, 0, w, h, col)
    end
    btnYes.DoClick = function()
        if IsValid(MainMenu) then MainMenu:Close() end
        MainMenu = nil 
        self:Remove()
        timer.Simple(0.1, function() RunConsoleCommand("disconnect") end)
    end
    local btnNo = vgui.Create("DButton", btnPanel)
    btnNo:Dock(RIGHT)
    btnNo:SetWide(ScreenScale(50))
    btnNo:SetText("NO")
    btnNo:SetFont("HomigradFontSmall")
    btnNo:SetTextColor(Color(255, 255, 255))
    btnNo:SetCursor("blank")
    btnNo.Paint = function(s, w, h)
        local col = s:IsHovered() and Color(100, 100, 100) or Color(50, 50, 50)
        draw.RoundedBox(4, 0, 0, w, h, col)
    end
    btnNo.DoClick = function() self:AlphaTo(0, 0.1, 0, function() self:Remove() end) end
end
function PANEL_CONFIRM:Think()
    local targetX, targetY = GetParallaxOffset(0.015) 
    self.ParaX = Lerp(FrameTime() * 5, self.ParaX, targetX)
    self.ParaY = Lerp(FrameTime() * 5, self.ParaY, targetY)
    self:SetPos(self.BaseX + self.ParaX, self.BaseY + self.ParaY)
end

function PANEL_CONFIRM:Paint(w, h)
    draw.RoundedBox(8, 0, 0, w, h, Color(10, 10, 19, 250))
    hg.DrawBlur(self, 5)
    surface.SetDrawColor(255, 35, 35, 200) 
    surface.DrawOutlinedRect(0, 0, w, h, 1)
end
vgui.Register("ZDisconnectConfirm", PANEL_CONFIRM, "DFrame")

-- =================================================================
-- MAIN MENU
-- =================================================================
local PANEL = {}
local Selects = {
    {Title = "Disconnect", Func = function(luaMenu) 
        if IsValid(DisconnectPopup) then DisconnectPopup:Remove() end
        DisconnectPopup = vgui.Create("ZDisconnectConfirm")
    end, IsDisconnect = true},
    {Title = "Main Menu", Func = function(luaMenu) gui.ActivateGameUI() luaMenu:Close() end},
    
    {Title = "Appearance", Func = function(luaMenu) 
        if luaMenu.CurrentMode == "appearance" then
            if IsValid(zpan) then zpan:Close() end
            luaMenu:SwitchToDefault()
            return
        end
        luaMenu.CurrentMode = "appearance"
        luaMenu:SwitchContent(function(parent) end)
        RunConsoleCommand("hg_appearance_menu")
    end},
    
    {Title = "Settings", Func = function(luaMenu) 
        if luaMenu.CurrentMode == "settings" then
            luaMenu:SwitchToDefault()
            return
        end
        luaMenu.CurrentMode = "settings"
        
        luaMenu:SwitchContent(function(parent)
            if hg and hg.DrawSettings then
                hg.DrawSettings(parent)
            end
        end)
    end},
    
    {Title = "Return", Func = function(luaMenu) 
        if IsValid(zpan) then zpan:Close() end -- Закрываем Appearance, если он есть
        luaMenu:Close() -- Закрываем Главное меню
    end},
}

surface.CreateFont("ZC_MM_Title", {
    font = "Bahnschrift",
    size = ScreenScale(40),
    weight = 800,
    antialias = true
})
local red_select = Color(255, 35, 35) 
local Pluv = Material("pluv/pluvkid.jpg")
local DiscordIcon = Material("vgui/discordicon.png")

local color_red = Color(255,25,25,45)

function PANEL:Init()
    self:SetCursor("blank")
    self:SetAlpha( 0 )
    self:SetSize( ScrW(), ScrH() )
    self:Center()
    self:SetTitle( "" )
    self:SetDraggable( false )
    self:SetBorder( false )
    self:SetColorBG(Color(10,10,19,235))
    self:ShowCloseButton( false )

    self.ZoomAmount = 0 
    self.ZoomFocusX = ScrW() / 2
    self.ZoomFocusY = ScrH() / 2
    self.ParaX = 0
    self.ParaY = 0
    self.CurrentMode = "default"
    self.SlideProgress = 0
    
    self.HeartbeatSound = CreateSound(LocalPlayer(), "heartbeat.mp3")
    self.SubTitleText = gmod.GetGamemode().Name .. " | " .. string.NiceName(zb ~= nil and zb.GetRoundName or game.GetMap())

    timer.Simple(0,function() self:First() end)

    local leftAreaWidth = ScrW() * 0.4  
    local rightAreaWidth = ScrW() * 0.6 

    -- === ПРАВАЯ ПАНЕЛЬ ===
    self.rDock = vgui.Create("DPanel",self)
    self.rDock:SetCursor("blank")
    self.rDock:SetSize( rightAreaWidth, ScrH() )
    self.rDock.BaseX = ScrW() - rightAreaWidth
    self.rDock:SetPos(self.rDock.BaseX, 0)
    self.rDock.Paint = function(this, w, h) end
    self.rDock:SetPaintedManually(true)
    self.rDock:SetAlpha(255)

    -- Строим содержимое
    self:BuildDefaultRight(self.rDock)

    -- === ЛЕВАЯ ПАНЕЛЬ ===
    self.lDock = vgui.Create("DPanel",self)
    self.lDock:SetCursor("blank")
    self.lDock:SetSize( leftAreaWidth, ScrH() ) 
    
    self.lDock.CenterX = (ScrW() / 2) - (leftAreaWidth / 2)
    self.lDock.LeftX = 0
    
    self.lDock.BaseX = self.lDock.CenterX
    self.lDock.BaseY = 0
    self.lDock:SetPos( self.lDock.BaseX, self.lDock.BaseY )
    self.lDock:SetPaintedManually(true)

    self.lDock.Paint = function(this, w, h)
        if hg.PluvTown.Active then
            surface.SetDrawColor(color_white)
            surface.SetMaterial(self.SelectedPluv or Pluv)
            surface.DrawTexturedRect(w/2 - ScreenScale(17.5), ScreenScale(27), ScreenScale(35), ScreenScale(27)) 
        end
        
        local titleFont = "ZC_MM_Title"
        local subFont = "ZCity_Small"
        surface.SetFont(titleFont)
        local w1 = surface.GetTextSize("Local")
        local w2 = surface.GetTextSize("-Box")
        local totalW = w1 + w2
        local startX = w/2 - totalW/2
        
        local titleY = ScreenScale(75)
        
        draw.SimpleText("Local", titleFont, startX, titleY, Color(186,26,26,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText("-Box", titleFont, startX + w1, titleY, Color(255,255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText(self.SubTitleText, subFont, w/2, titleY + ScreenScale(25), Color(150,150,150), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    self.ButtonPanel = vgui.Create("DPanel", self.lDock)
    self.ButtonPanel:SetCursor("blank")
    self.ButtonPanel:SetSize(ScreenScale(200), ScreenScale(200))
    self.ButtonPanel:SetPos((leftAreaWidth - ScreenScale(200)) / 2, ScreenScale(140)) 
    self.ButtonPanel.Paint = function() end

    self.Buttons = {}
    local currentY = 0
    for i = #Selects, 1, -1 do
        local v = Selects[i]
        self:AddSelect( self.ButtonPanel, v.Title, v.Func, currentY, v.IsDisconnect )
        currentY = currentY + ScreenScale(30) + ScreenScale(2)
    end
end

function PANEL:SwitchToDefault()
    self.CurrentMode = "default"
    self.rDock:AlphaTo(0, 0.2, 0, function()
        self.rDock:Clear()
        self:BuildDefaultRight(self.rDock)
        self.rDock:AlphaTo(255, 0.2)
    end)
end

function PANEL:BuildDefaultRight(parent)
    local discordButton = vgui.Create("DButton", parent)
    discordButton:SetCursor("blank")
    discordButton:SetSize(ScreenScale(42), ScreenScale(42))
    discordButton.BaseRelX = parent:GetWide() - ScreenScale(52)
    discordButton.BaseRelY = parent:GetTall() - ScreenScale(90)
    discordButton:SetPos(discordButton.BaseRelX, discordButton.BaseRelY)
    discordButton:SetText("")
    discordButton.HoverLerp = 0
    discordButton.HoverScale = 1
    
    local col_discord_hover = Color(114,137,218)
    local col_white = Color(255, 255, 255)

    function discordButton:Paint(w, h)
        local scale = self.HoverScale
        local iconSize = math.min(w, h) * scale
        local x = (w - iconSize) / 2
        local y = (h - iconSize) / 2
        local drawCol = col_white:Lerp(col_discord_hover, self.HoverLerp)
        surface.SetDrawColor(drawCol.r, drawCol.g, drawCol.b, 255)
        surface.SetMaterial(DiscordIcon)
        surface.DrawTexturedRect(x, y, iconSize, iconSize)
    end
    function discordButton:Think()
        self.HoverLerp = LerpFT(0.2, self.HoverLerp or 0, self:IsHovered() and 1 or 0)
        self.HoverScale = Lerp(self.HoverLerp, 1, 1.1)
    end
    function discordButton:DoClick()
        if IsValid(DiscordMenu) then DiscordMenu:Close() end
        DiscordMenu = vgui.Create("ZDiscordMenu")
    end

    local zteam = vgui.Create("DPanel", parent)
    zteam:SetCursor("blank")
    zteam:Dock(BOTTOM)
    zteam:SetTall(ScreenScale(15))
    zteam.ParentMenu = self 

    zteam.Paint = function(s, w, h)
        local baseCol = hg.theme and hg.theme.c.text or Color(229,229,229,45)
        local speed = 100 
        local time = CurTime() * speed
        local r1 = HSVToColor(time % 360, 1, 1)
        local r2 = HSVToColor((time + 45) % 360, 1, 1)
        local c_base = string.format("%d,%d,%d,%d", baseCol.r, baseCol.g, baseCol.b, baseCol.a)
        local c_rain1 = string.format("%d,%d,%d,255", r1.r, r1.g, r1.b)
        local c_rain2 = string.format("%d,%d,%d,255", r2.r, r2.g, r2.b)
        local textStr = string.format(
            "<font=ZCity_Tiny><colour=%s>Local-Box (Made by </colour><colour=%s>ne bot01</colour><colour=%s>, </colour><colour=%s>wagan</colour><colour=%s>)</colour></font>",
            c_base, c_rain1, c_base, c_rain2, c_base
        )
        local antiX, antiY = 0, 0
        if IsValid(s.ParentMenu) then
            antiX = -s.ParentMenu.ParaX
            antiY = -s.ParentMenu.ParaY
        end
        local parsed = markup.Parse(textStr)
        parsed:Draw(w + antiX, h/2 + antiY, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    end

    hg.GetServerInfo(function(tbl)
        if not IsValid(parent) then return end
        for _,v in pairs(tbl) do self:AddServerCard(parent, v) end
    end)
end

function PANEL:SwitchContent(drawFunc)
    self.rDock:AlphaTo(0, 0.2, 0, function()
        self.rDock:Clear()
        
        local container = vgui.Create("DPanel", self.rDock)
        container:SetCursor("blank")
        local cw, ch = self.rDock:GetWide() - ScreenScale(40), self.rDock:GetTall() - ScreenScale(60)
        
        container:SetSize(cw, ch)
        container:SetPos(ScreenScale(10), ScreenScale(30)) 
        container.Paint = function(s, w, h) end
        
        if drawFunc then 
            drawFunc(container) 
        end
        
        self.rDock:AlphaTo(255, 0.2)
    end)
end

function PANEL:Think()
    local targetX, targetY = GetParallaxOffset(0.015) 
    self.ParaX = Lerp(FrameTime() * 5, self.ParaX, targetX)
    self.ParaY = Lerp(FrameTime() * 5, self.ParaY, targetY)

    local targetProgress = (self.CurrentMode == "settings" or self.CurrentMode == "appearance") and 1 or 0
    self.SlideProgress = Lerp(FrameTime() * 8, self.SlideProgress, targetProgress)

    if IsValid(self.lDock) then
        local targetBaseX = Lerp(self.SlideProgress, self.lDock.CenterX, self.lDock.LeftX)
        self.lDock:SetPos(targetBaseX + self.ParaX, self.lDock.BaseY + self.ParaY)
    end

    if IsValid(self.rDock) then
        self.rDock:SetPos(self.rDock.BaseX + self.ParaX, self.rDock.BaseY + self.ParaY)
    end

    -- !!! ИСПРАВЛЕННАЯ ЛОГИКА СКРЫТИЯ КУРСОРА !!!
    local hover = vgui.GetHoveredPanel()
    if IsValid(hover) then
        -- Используем рекурсивную проверку, чтобы найти, находится ли элемент ВНУТРИ меню
        if IsMenuOrPopup(hover) then
            -- Если это часть меню/попапа/текстбокса, показываем стрелку
            if hover:GetCursor() == "blank" then
                hover:SetCursor("arrow")
            end
        else
            -- Если это просто кнопка или фон - скрываем
            if hover:GetCursor() ~= "blank" then
                hover:SetCursor("blank")
            end
        end
    end
end

local cardcolor = Color(15,15,25,220)
local green_color = Color(55,225,55)

function PANEL:AddServerCard(parent, serverTbl)
    local card = vgui.Create("DPanel", parent)
    card:SetCursor("blank")
    card:Dock(TOP)
    card:SetSize(500,ScreenScaleH(45))
    card:DockMargin(ScreenScale(50),5,ScreenScale(20),5) 
    card:DockPadding(15,5,15,15)
    card.Info = serverTbl
    function card:Paint(w,h)
        draw.RoundedBox( 4, 0, 0, w, h, cardcolor )
        draw.RoundedBox( 0, 0, h-h/5, w, h/5, cardcolor )
        draw.RoundedBox( 0, 2.5, h-h/5 +3, w* (card.Info["players"]/card.Info["max_players"]) - 5 , h/6, color_red )
    end
    local lbl1 = vgui.Create("DLabel",card)
    lbl1:Dock(BOTTOM)
    lbl1:SetFont("ZCity_Tiny")
    lbl1:SetText(card.Info["players"].."/"..card.Info["max_players"])
    lbl1:SizeToContents()
    lbl1:SetTall(ScreenScaleH(17))
    lbl1:SetCursor("blank")

    local lbl2 = vgui.Create("DLabel",card)
    lbl2:Dock(LEFT)
    lbl2:SetFont("ZCity_Small")
    lbl2:SetText(card.Info["name"])
    lbl2:SizeToContents()
    lbl2:SetTall(ScreenScaleH(19))
    lbl2:SetCursor("blank")

    local connectButton = vgui.Create("DButton",card)
    connectButton:Dock(RIGHT)
    connectButton:SetFont("ZCity_Small")
    connectButton:SetText("Connect")
    connectButton:SizeToContents()
    connectButton:SetTall(ScreenScaleH(19))
    connectButton:SetCursor("blank")
    connectButton.HoverLerp = 0
    connectButton.RColor = Color(255,255,255)
    function connectButton:Paint(w,h) return false end
    function connectButton:Think()
        self.HoverLerp = LerpFT(0.2,self.HoverLerp or 0,self:IsHovered() and 1 or 0)
        self:SetTextColor( self.RColor:Lerp( green_color, self.HoverLerp ) )
    end
    function connectButton:DoClick() permissions.AskToConnect( card.Info["addr"] ) end
end

function PANEL:First( ply )
    self:AlphaTo( 255, 0.1, 0, nil )
end

local gradient_d = surface.GetTextureID("vgui/gradient-d")
local gradient_r = surface.GetTextureID("vgui/gradient-r")
local gradient_l = surface.GetTextureID("vgui/gradient-l")

function PANEL:Paint(w,h)
    -- Отрисовка фона и сетки
    local m = Matrix()
    local centerX, centerY = w/2, h/2
    local focusX = Lerp(self.ZoomAmount, centerX, self.ZoomFocusX or centerX)
    local focusY = Lerp(self.ZoomAmount, centerY, self.ZoomFocusY or centerY)
    local pulse = 0
    if self.ZoomAmount > 0.01 then
        local time = RealTime() * 2 
        pulse = (math.max(0, math.sin(time * 5)) ^ 4) * 0.1 * self.ZoomAmount
    end
    local zoomScale = 1 + (0.45 * self.ZoomAmount) + pulse

    m:Translate(Vector(focusX, focusY, 0))
    m:Scale(Vector(zoomScale, zoomScale, 1))
    m:Translate(Vector(-focusX, -focusY, 0))

    cam.PushModelMatrix(m)
        draw.RoundedBox( 0, 0, 0, w, h, self.ColorBG )
        hg.DrawBlur(self, 5)
        surface.SetDrawColor( self.ColorBG )
        surface.SetTexture( gradient_l )
        surface.DrawTexturedRect(0,0,w,h)
        
        -- СЕТКА (Логика добавлена сюда напрямую)
        if not self.GridPosX then self.GridPosX = 0 end
        if not self.GridPosY then self.GridPosY = 0 end
        
        local mx, my = gui.MouseX(), gui.MouseY()
        local dirX = mx - centerX
        local dirY = my - centerY
        local grid_move_speed = 0.1
        local grid_base_size = 8
        local grid_color = Color(255, 0, 0, 2)

        self.GridPosX = self.GridPosX + (dirX * grid_move_speed * FrameTime())
        self.GridPosY = self.GridPosY + (dirY * grid_move_speed * FrameTime())

        local size = ScreenScale(grid_base_size)
        local offsetX = self.GridPosX % size
        local offsetY = self.GridPosY % size

        surface.SetDrawColor(grid_color)
        for x = offsetX - size, w, size do surface.DrawLine(x, 0, x, h) end
        for y = offsetY - size, h, size do surface.DrawLine(0, y, w, y) end
        
        -- РИСУЕМ ПАНЕЛИ
        if IsValid(self.lDock) then self.lDock:PaintManual() end
        if IsValid(self.rDock) then self.rDock:PaintManual() end
    cam.PopModelMatrix()
end

function PANEL:AddSelect( pParent, strTitle, fFunc, yPos, isDisconnect )
    local id = #self.Buttons + 1
    self.Buttons[id] = vgui.Create( "DPanel", pParent )
    local btn = self.Buttons[id]
    
    btn.Title = strTitle
    btn:SetCursor("blank")
    btn:SetMouseInputEnabled( true )
    
    surface.SetFont("HomigradFontLarge")
    local tw, th = surface.GetTextSize(strTitle)
    
    btn:SetSize(tw + ScreenScale(20), ScreenScale(30))
    btn:SetPos( (pParent:GetWide() - btn:GetWide()) / 2, yPos )
    
    btn.Func = fFunc
    btn.RColor = (hg.theme and hg.theme.c.text) or Color(225,225,225)
    local luaMenu = self 
    
    function btn:OnMousePressed()
        surface.PlaySound("garrysmod/ui_click.wav")
        btn.Func(luaMenu)
    end

    function btn:Paint(w,h)
        surface.SetFont("HomigradFontLarge")
        local totalW, totalH = surface.GetTextSize(self.Title)
        local currentX = (w - totalW) / 2
        local centerY = h / 2

        local anim = self.HoverLerp or 0
        local shakeX, shakeY = 0, 0
        if isDisconnect and anim > 0.01 then
             local pwr = 3 * anim
             shakeX = math.random(-pwr, pwr)
             shakeY = math.random(-pwr, pwr)
        end
        
        local mouseX = gui.MouseX()
        local mouseY = gui.MouseY()
        local btnScreenX, btnScreenY = self:LocalToScreen(0, 0)
        local highlightRadius = ScreenScale(25) 

        for i = 1, #self.Title do
            local char = string.sub(self.Title, i, i)
            local charW, charH = surface.GetTextSize(char)
            
            local globalCharX = btnScreenX + currentX + (charW / 2)
            local globalCharY = btnScreenY + centerY
            
            local dist = math.abs(mouseX - globalCharX)
            
            local charAlpha = 0
            if self:IsHovered() then
                if dist < highlightRadius then
                    charAlpha = 1 - (dist / highlightRadius)
                    charAlpha = charAlpha ^ 0.5 
                end
            end
            
            local r = Lerp(charAlpha, self.RColor.r, 255)
            local g = Lerp(charAlpha, self.RColor.g, 35) 
            local b = Lerp(charAlpha, self.RColor.b, 35) 
            
            local finalColor = Color(r, g, b, 255)

            draw.SimpleText(char, "HomigradFontLarge", currentX + shakeX, centerY + shakeY, finalColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            currentX = currentX + charW
        end
    end

    function btn:Think()
        self.HoverLerp = LerpFT(0.2, self.HoverLerp or 0, self:IsHovered() and 1 or 0)
        
        if isDisconnect and IsValid(luaMenu) then
             local bx, by = self:LocalToScreen(self:GetWide()/2, self:GetTall()/2)
             if self:IsHovered() then
                 luaMenu.ZoomAmount = Lerp(FrameTime() * 2, luaMenu.ZoomAmount, 1)
                 luaMenu.ZoomFocusX = bx
                 luaMenu.ZoomFocusY = by
                 if luaMenu.HeartbeatSound and not luaMenu.HeartbeatPlaying then
                     luaMenu.HeartbeatSound:Play()
                     luaMenu.HeartbeatPlaying = true
                 end
             else
                 luaMenu.ZoomAmount = Lerp(FrameTime() * 4, luaMenu.ZoomAmount, 0)
                 if luaMenu.HeartbeatSound and luaMenu.HeartbeatPlaying then
                     luaMenu.HeartbeatSound:Stop()
                     luaMenu.HeartbeatPlaying = false
                 end
             end
        end
        
        if self:IsHovered() then
            if not self.SoundPlayed then
                if IsValid(LocalPlayer()) then LocalPlayer():EmitSound("garrysmod/ui_hover.wav", 0, 125, 0.5) else surface.PlaySound("garrysmod/ui_hover.wav") end
                self.SoundPlayed = true 
            end
        else
            self.SoundPlayed = false
        end
    end
end

function PANEL:Close()
    if self.HeartbeatSound then
        self.HeartbeatSound:Stop()
        self.HeartbeatSound = nil
    end
    self:AlphaTo( 0, 0.1, 0, function() self:Remove() end)
    self:SetKeyboardInputEnabled(false)
    self:SetMouseInputEnabled(false)
end

vgui.Register( "ZMainMenu", PANEL, "ZFrame")

-- =================================================================
-- LOGIC: ESCAPE KEY & MENU MANAGER
-- =================================================================

hook.Remove("OnPauseMenuShow", "OpenMainMenu")
hook.Remove("OnPauseMenuShow", "HG_CloseAppearance")

hook.Add("OnPauseMenuShow", "ZCity_UnifiedMenuManager", function()
    -- 1. Если открыто меню внешности
    if IsValid(zpan) then
        zpan:Close() 
        return false 
    end

    -- 2. Если меню внешности нет, но открыто Главное меню
    if IsValid(MainMenu) then
        MainMenu:Close()
        MainMenu = nil
        return false
    end

    -- 3. Если ничего не открыто - создаем Главное меню
    local run = hook.Run("OnShowZCityPause")
    if run then return run end

    MainMenu = vgui.Create("ZMainMenu")
    MainMenu:MakePopup()
    return false
end)

hook.Add("CalcView", "ZMainMenuZoomWorld", function(ply, pos, angles, fov)
    if IsValid(MainMenu) and MainMenu.ZoomAmount and MainMenu.ZoomAmount > 0.01 then
        local val = MainMenu.ZoomAmount
        local time = RealTime() * 2
        local pulse = (math.max(0, math.sin(time * 5)) ^ 4) * 2
        local targetFOV = fov - (40 * val) - (pulse * val)
        return { origin = pos, angles = angles, fov = targetFOV, drawviewer = false }
    end
end)

concommand.Add("hg_appearance_menu",function()
    if hg.Appearance.PrecacheModels then
        hg.Appearance.PrecacheModels()
    end
    
    hg.PointShop:SendNET( "SendPointShopVars", nil, function( data )
        if IsValid(zpan) then
            zpan:Close()
        end
        zpan = vgui.Create("HG_AppearanceMenu")
        
        local w, h = ScrW() * 0.7, ScrH()
        zpan:SetSize(w, h)
        zpan:SetPos(ScrW() * 0.3, 0)
        zpan:MakePopup()
        zpan:SetCursor("blank")

        zpan.OnRemove = function()
            if IsValid(MainMenu) and MainMenu.CurrentMode == "appearance" then
                MainMenu:SwitchToDefault()
            end
        end
    end)
end)

-- =================================================================
-- GLOBAL OVERLAY: WORM CURSOR
-- (Рисуется поверх всех VGUI панелей)
-- =================================================================
local worm_length = 7
local worm_start_size = 5
local worm_color = Color(255, 0, 0, 9) 
local worm_lag = 0.4
local WormBody = {}

local cur_extra_size = 0
local cur_alpha = 5

hook.Add("DrawOverlay", "ZCityWormCursor", function()
    if not IsValid(MainMenu) then return end

    local mx, my = gui.MouseX(), gui.MouseY()
    if #WormBody == 0 then
        for i = 1, worm_length do
            WormBody[i] = { x = mx, y = my }
        end
    end

    -- Проверка на кликабельность (для анимации червяка)
    local hover = vgui.GetHoveredPanel()
    local isInteractive = false
    
    -- Используем ту же функцию проверки, что и в MainMenu
    if IsValid(hover) and hover:IsVisible() then
        if hover.DoClick or hover.OnMousePressed or IsMenuOrPopup(hover) or hover:GetClassName() == "DButton" or hover:GetClassName() == "DCheckBox" or hover:GetClassName() == "DSlider" or hover:GetClassName() == "DNumSlider" then
            isInteractive = true
        end
        if hover == MainMenu or hover == MainMenu.lDock or hover == MainMenu.rDock or hover == MainMenu.ButtonPanel then
            isInteractive = false
        end
    end

    local target_extra = isInteractive and 10 or 0    
    local target_alpha = isInteractive and 79 or 9   
    
    cur_extra_size = Lerp(FrameTime() * 10, cur_extra_size, target_extra)
    cur_alpha = Lerp(FrameTime() * 10, cur_alpha, target_alpha)

    WormBody[1].x = Lerp(FrameTime() * 20, WormBody[1].x, mx)
    WormBody[1].y = Lerp(FrameTime() * 20, WormBody[1].y, my)

    for i = 2, worm_length do
        local prev = WormBody[i-1]
        local curr = WormBody[i]
        local speed = FrameTime() * 60 * worm_lag
        curr.x = Lerp(speed, curr.x, prev.x)
        curr.y = Lerp(speed, curr.y, prev.y)
    end

    for i = worm_length, 1, -1 do
        local pos = WormBody[i]
        local baseSize = ScreenScale(worm_start_size) + cur_extra_size
        local segmentSize = (worm_length - i) / worm_length * baseSize
        
        local segmentAlpha = (worm_length - i) / worm_length * cur_alpha
        
        draw.RoundedBox(segmentSize, pos.x - segmentSize/2, pos.y - segmentSize/2, segmentSize, segmentSize, Color(worm_color.r, worm_color.g, worm_color.b, segmentAlpha))
    end
end)
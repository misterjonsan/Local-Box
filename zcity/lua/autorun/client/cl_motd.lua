-- mcity/lua/autorun/client/cl_motd.lua

-- if SERVER then return end

-- -- MOTD Configuration
-- -- Edit the Title and Text below to change the MOTD content.
-- local MOTD_CONFIG = {
--     Title = "MOTD",
--     Text = [[
-- Welcome to Meleecity!

-- Changelog:
-- - Added 1 new achievement
-- - New bandage minigame


-- Join the discord!
-- ]],
--     TypeSpeed = 0.01, -- Speed of the typewriter effect (lower is faster)
--     AnimSpeed = 2,    -- Speed of the opening animation
--     CloseDelay = 5,   -- Seconds to wait before close button is active
-- }

-- -- Ensure fonts exist (fallback if Homigrad fonts aren't loaded)
-- surface.CreateFont("HomigradFontBig", {
--     font = "Roboto",
--     size = ScreenScale(12),
--     weight = 600,
--     outline = false,
--     shadow = true
-- })

-- surface.CreateFont("HomigradFontMedium", {
--     font = "Roboto",
--     size = ScreenScale(8),
--     weight = 600,
--     outline = false,
-- })

-- -- Blur Helper Function
-- local blur = Material("pp/blurscreen")
-- local function DrawBlur(panel, amount)
--     if hg and hg.DrawBlur then
--         hg.DrawBlur(panel, amount)
--         return
--     end
    
--     local x, y = panel:LocalToScreen(0, 0)
--     local scrW, scrH = ScrW(), ScrH()
--     surface.SetDrawColor(255, 255, 255)
--     surface.SetMaterial(blur)
--     for i = 1, 3 do
--         blur:SetFloat("$blur", (i / 3) * (amount or 6))
--         blur:Recompute()
--         render.UpdateScreenEffectTexture()
--         surface.DrawTexturedRect(x * -1, y * -1, scrW, scrH)
--     end
-- end

-- local PANEL = {}

-- function PANEL:Init()
--     self:SetSize(10, 0) -- Start small width, 0 height
--     self:Center()
--     self:MakePopup()
--     self:SetTitle("")
--     self:ShowCloseButton(false)
--     self:SetDraggable(false)
    
--     self.StartTime = RealTime()
--     self.AnimState = 0 -- 0: Height, 1: Width, 2: Text
    
--     -- Target size relative to screen
--     self.TargetWidth = ScrW() * 0.6
--     self.TargetHeight = ScrH() * 0.7
    
--     self.DisplayedText = ""
--     self.TextIndex = 0
--     self.LastCharTime = 0
    
--     -- Close button
--     self.btnClose = vgui.Create("DButton", self)
--     self.btnClose:SetText("") -- Text handled in Think
--     self.btnClose:SetFont("HomigradFontBig")
--     self.btnClose:SetTextColor(Color(255,255,255))
--     self.btnClose.Paint = function(s, w, h)
--         local isActive = self.CanClose
--         local col
        
--         if not isActive then
--             col = Color(50, 50, 50, 200) -- Grayed out
--         elseif s:IsHovered() then
--             col = Color(200, 50, 50, 200)
--         else
--             col = Color(155, 0, 0, 200)
--         end
        
--         draw.RoundedBox(0, 0, 0, w, h, col)
--         surface.SetDrawColor(0,0,0,255)
--         surface.DrawOutlinedRect(0,0,w,h)
--     end
--     self.btnClose.DoClick = function()
--         if self.CanClose then
--             self:Close()
--         end
--     end
--     self.btnClose:SetVisible(false)
-- end

-- function PANEL:Think()
--     if not self.StartTime then self.StartTime = RealTime() end
--     local dt = FrameTime() * MOTD_CONFIG.AnimSpeed * 500
    
--     if self.AnimState == 0 then
--         -- Vertical Expansion (Height)
--         local w, h = self:GetSize()
--         h = math.Approach(h, self.TargetHeight, dt)
--         self:SetSize(w, h)
--         self:Center()
        
--         if h >= self.TargetHeight then
--             self.AnimState = 1
--         end
--     elseif self.AnimState == 1 then
--         -- Horizontal Expansion (Width)
--         local w, h = self:GetSize()
--         w = math.Approach(w, self.TargetWidth, dt)
--         self:SetSize(w, h)
--         self:Center()
        
--         if w >= self.TargetWidth then
--             self.AnimState = 2
--             self.FullyOpenedTime = RealTime()
--             self.btnClose:SetVisible(true)
--             -- Bigger close button (Square X)
--             self.btnClose:SetSize(80, 80)
--             self.btnClose:SetPos(self:GetWide() - 90, self:GetTall() - 90)
--         end
--     elseif self.AnimState == 2 then
--         -- Logic for Countdown
--         local elapsed = RealTime() - self.FullyOpenedTime
--         local remaining = math.ceil(MOTD_CONFIG.CloseDelay - elapsed)
        
--         if remaining > 0 then
--             self.btnClose:SetText(tostring(remaining))
--             self.CanClose = false
--         else
--             self.btnClose:SetText("X")
--             self.CanClose = true
--         end
        
--         -- Typewriter Effect
--         if self.TextIndex < #MOTD_CONFIG.Text then
--             if RealTime() - self.LastCharTime > MOTD_CONFIG.TypeSpeed then
--                 self.TextIndex = self.TextIndex + 1
--                 self.DisplayedText = string.sub(MOTD_CONFIG.Text, 1, self.TextIndex)
--                 self.LastCharTime = RealTime()
--                 -- Optional: Play typing sound
--                 -- surface.PlaySound("common/talk.wav")
--             end
--         end
--     end
-- end

-- function PANEL:Close()
--     if self.Closing then return end
--     self.Closing = true
    
--     self:SetMouseInputEnabled(false)
--     self:SetKeyboardInputEnabled(false)
    
--     self:AlphaTo(0, 0.5, 0, function()
--         if IsValid(self) then
--             self:Remove()
--         end
--     end)
-- end

-- function PANEL:Paint(w, h)
--     -- Style Colors (Use Homigrad theme if available, else fallback)
--     local colBg = (hg and hg.theme and hg.theme.c.bg) or Color(25, 25, 30, 220)
--     local colBorder = (hg and hg.theme and hg.theme.c.accent) or Color(155, 0, 0, 240)
    
--     DrawBlur(self, 4)
--     draw.RoundedBox(0, 0, 0, w, h, colBg)
    
--     surface.SetDrawColor(colBorder)
--     surface.DrawOutlinedRect(0, 0, w, h, 2)
    
--     -- Draw Grid if available (MCity style)
--     if hg and hg.theme and hg.theme.DrawGrid then
--         hg.theme.DrawGrid(self, 8)
--     end
    
--     if self.AnimState == 2 then
--         -- Header Box
--         local headerH = 60
--         local padding = 10
        
--         surface.SetDrawColor(colBorder)
--         draw.RoundedBox(0, padding, padding, w - padding*2, headerH, Color(0, 0, 0, 100))
--         surface.SetDrawColor(colBorder) -- Reset color after RoundedBox
--         surface.DrawOutlinedRect(padding, padding, w - padding*2, headerH, 2)
        
--         draw.SimpleText(MOTD_CONFIG.Title, "HomigradFontBig", w/2, padding + headerH/2, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        
--         -- Content Box
--         local contentY = padding + headerH + padding
--         local contentH = h - contentY - 60 -- Space for button
        
--         draw.RoundedBox(0, padding, contentY, w - padding*2, contentH, Color(0, 0, 0, 50))
--         surface.DrawOutlinedRect(padding, contentY, w - padding*2, contentH, 1)
        
--         -- Text Content
--         draw.DrawText(self.DisplayedText, "HomigradFontMedium", padding + 10, contentY + 10, Color(255,255,255), TEXT_ALIGN_LEFT)
--     end
-- end

-- vgui.Register("MCityMOTD", PANEL, "DFrame")

-- -- Open MOTD when player joins (initial spawn)
-- hook.Add("InitPostEntity", "OpenMCityMOTD", function()
--     -- Check if player needs to set appearance first
--     if not file.Exists("mcity/appearance.json", "DATA") then
--         timer.Create("MCityMOTD_WaitForAppearance", 1, 0, function()
--             if file.Exists("mcity/appearance.json", "DATA") then
--                 timer.Remove("MCityMOTD_WaitForAppearance")
--                 if IsValid(MCityMOTDFrame) then MCityMOTDFrame:Remove() end
--                 MCityMOTDFrame = vgui.Create("MCityMOTD")
--             end
--         end)
--     else
--         if IsValid(MCityMOTDFrame) then MCityMOTDFrame:Remove() end
--         MCityMOTDFrame = vgui.Create("MCityMOTD")
--     end
-- end)

-- -- Console command for testing
-- concommand.Add("mcity_motd_test", function()
--     if IsValid(MCityMOTDFrame) then MCityMOTDFrame:Remove() end
--     MCityMOTDFrame = vgui.Create("MCityMOTD")
-- end)

-- -- Chat command to reopen MOTD
-- local function OpenMOTDCommand(ply, text)
--     if ply ~= LocalPlayer() then return end
    
--     if string.lower(string.Trim(text)) == "!motd" then
--         if IsValid(MCityMOTDFrame) then MCityMOTDFrame:Remove() end
--         MCityMOTDFrame = vgui.Create("MCityMOTD")
--         return true -- Hide from chat
--     end
-- end

-- hook.Add("OnPlayerChat", "MCityMOTDChatCommand", function(ply, text, teamChat, isDead)
--     return OpenMOTDCommand(ply, text)
-- end)

-- -- Hook into Homigrad's custom chat system if available
-- hook.Add("HG_OnPlayerCommand", "MCityMOTDHGCommand", function(ply, textTable)
--     if not textTable or not textTable[1] then return end
--     return OpenMOTDCommand(ply, textTable[1])
-- end)
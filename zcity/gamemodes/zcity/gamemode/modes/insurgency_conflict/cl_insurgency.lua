local MODE = MODE

MODE.name = "insurgency_conflict"

local life0 = 40
local life1 = 40
local attrition = false
local budget0 = 0
local budget1 = 0
local revealEnd = 0
local IC_Active = false
local revealStart = 0
local respawnEnd = 0
local roundEnd = 0
local revealLocked = false
local matRebel = Material("vgui/rebellion.png")
local matGov = Material("vgui/government.png")
local matDot = Material("vgui/dot_sprite.png")
local IC_PerkDefs = {}
local IC_PerkIcons = {
    airstrike = Material("vgui/airstrike.png"),
    uav = Material("vgui/drone.png"),
    troop = Material("vgui/natsoldiers.png")
}

local IC_MusicTracks = {"rebelinc/rebelinc1.ogg", "rebelinc/rebelinc2.ogg", "rebelinc/rebelinc3.ogg"}
local IC_MusicOrder = {}
local IC_MusicPos = 0
local IC_MusicPatch = nil
local IC_EndActive = false
local IC_EndWinner = -1
local IC_EndLoser = -1
local IC_EndStalemate = false
local IC_EndReason = ""

local function IC_ShuffleOrder()
    IC_MusicOrder = {1, 2, 3}
    for i = #IC_MusicOrder, 2, -1 do
        local j = math.random(i)
        IC_MusicOrder[i], IC_MusicOrder[j] = IC_MusicOrder[j], IC_MusicOrder[i]
    end
end

local function IC_CrossFadeNext()
    if not IsValid(LocalPlayer()) then return end
    if IC_MusicPatch then IC_MusicPatch:FadeOut(2) end
    timer.Simple(2.1, function()
        IC_MusicPos = IC_MusicPos + 1
        if IC_MusicPos > #IC_MusicOrder then
            IC_ShuffleOrder()
            IC_MusicPos = 1
        end
        IC_PlayIndex(IC_MusicOrder[IC_MusicPos])
    end)
end

local function IC_PlayIndex(idx)
    local snd = IC_MusicTracks[idx]
    if IC_MusicPatch then IC_MusicPatch:Stop() IC_MusicPatch = nil end
    IC_MusicPatch = CreateSound(LocalPlayer(), snd)
    if IC_MusicPatch then
        IC_MusicPatch:PlayEx(0.8, 100)
        local dur = SoundDuration(snd)
        if dur and dur > 0 then
            timer.Create("IC_MusicNext", dur, 1, IC_CrossFadeNext)
        end
    end
end

net.Receive("ic_music_start", function()
    if zb and zb.CROUND and zb.CROUND ~= "insurgency_conflict" then return end
    if IC_MusicPatch and IC_MusicPatch:IsPlaying() then
        local remain = (IC_MusicPatch:GetLength() or 0) - CurTime()
        if remain > 3 then
            timer.Create("IC_MusicNext", remain - 1, 1, IC_CrossFadeNext)
            return
        end
    end
    timer.Remove("IC_MusicNext")
    IC_ShuffleOrder()
    IC_MusicPos = 1
    IC_PlayIndex(IC_MusicOrder[IC_MusicPos])
    IC_EndActive = false
end)

net.Receive("ic_music_stop", function()
    local fade = net.ReadFloat() or 2
    timer.Remove("IC_MusicNext")
    if IC_MusicPatch then IC_MusicPatch:FadeOut(fade) end
end)

net.Receive("ic_round_end", function()
    IC_EndWinner = net.ReadInt(8)
    IC_EndLoser = net.ReadInt(8)
    IC_EndStalemate = net.ReadBool()
    IC_EndReason = net.ReadString() or ""
    IC_EndActive = true
    if IC_EndStalemate then
        surface.PlaySound("rebelinc/lose.ogg")
    else
        local lp = LocalPlayer()
        local teamIndex = IsValid(lp) and lp:Team() or -1
        if teamIndex == IC_EndWinner then
            surface.PlaySound("rebelinc/win.ogg")
        else
            surface.PlaySound("rebelinc/lose.ogg")
        end
    end
    timer.Remove("IC_EndClear")
    timer.Create("IC_EndClear", 6, 1, function() IC_EndActive = false end)
end)

 

net.Receive("ic_update_life", function()
    life0 = net.ReadInt(16)
    life1 = net.ReadInt(16)
    IC_Active = true
end)

net.Receive("ic_respawn", function()
    local start = net.ReadFloat()
    local dur = net.ReadInt(16)
    respawnEnd = start + dur
end)

net.Receive("ic_attrition_active", function()
    attrition = true
    timer.Remove("ic_attrition_notice")
    timer.Create("ic_attrition_notice", 5, 1, function() attrition = true end)
end)

net.Receive("ic_update_budget", function()
    budget0 = net.ReadInt(16)
    budget1 = net.ReadInt(16)
    IC_Active = true
end)

local IC_BuyItems = nil
surface.CreateFont("ZB_TDM_MENU", {font = "Bahnschrift", size = ScreenScale(12), extended = true, weight = 400, antialias = true})
surface.CreateFont("ZB_TDM_DESC", {font = "Bahnschrift", size = ScreenScale(7), extended = true, weight = 400, antialias = true})
surface.CreateFont("ZB_TDM_CATEGORY", {font = "Bahnschrift", size = ScreenScale(6), extended = true, weight = 400, antialias = true})
local function PaintPanel(self,w,h)
    local bg = (hg.theme and hg.theme.c.panel) or Color(28,28,32,235)
    local acc = (hg.theme and hg.theme.c.accent) or Color(200,110,0)
    surface.SetDrawColor(bg)
    surface.DrawRect(0, 0, w, h)
    surface.SetDrawColor(acc)
    surface.DrawOutlinedRect(0, 0, w, h, 1.5)
end
net.Receive("ic_buymenu_data", function()
    IC_BuyItems = net.ReadTable() or nil
end)
local function OpenTeamBuyMenu()
    if IsValid(IC_PerkFrame) then IC_PerkFrame:Close() IC_PerkFrame = nil end
    if not IC_BuyItems then return end
    local frame = vgui.Create("ZFrame")
    IC_PerkFrame = frame
    frame:SetSize(ScrW() * 0.35, ScrH() * 0.85)
    frame:Center()
    frame:MakePopup()
    frame:SetTitle("Team Buy Menu")
    frame:SetBorder(true)

    local sheet = vgui.Create("DPropertySheet", frame)
    sheet:Dock(FILL)
    sheet:SetFadeTime(0.1)
    sheet.Paint = function() end

    local allowedCats = {
        ["Pistols"] = true,
        ["Assault"] = true,
        ["Submachine"] = true,
        ["Shotguns"] = true,
        ["Heavy"] = true,
        ["Marksman/Sniper"] = true,
        ["Ammo"] = true,
        ["Equipment"] = true
    }

    for catName, catTbl in pairs(IC_BuyItems) do
        if catName == "Priority" or not allowedCats[catName] then continue end
        local panel = vgui.Create("DScrollPanel", sheet)
        panel.Paint = function() end
        for itemName, item in pairs(catTbl) do
            if itemName == "Priority" then continue end
            local itemPanel = vgui.Create("DPanel", panel)
            itemPanel:SetTall(ScrH()*0.1)
            itemPanel:Dock(TOP)
            itemPanel:DockMargin(0,5,0,0)
            itemPanel.Paint = function() end

            local info = vgui.Create("DPanel", itemPanel)
            info:Dock(FILL)
            info.Paint = function() end

            local topRow = vgui.Create("DPanel", info)
            topRow:Dock(TOP)
            topRow:SetTall(ScrH()*0.04)
            topRow.Paint = function() end
            local nameLbl = vgui.Create("DLabel", topRow)
            nameLbl:SetText(itemName)
            nameLbl:Dock(LEFT)
            nameLbl:DockMargin(10,0,5,0)
            nameLbl:SetFont("ZB_TDM_MENU")
            nameLbl:SetWide(ScrW()*0.18)
            local ammoText = ""
            if item.Type == "Weapon" then
                local wep = weapons.GetStored(item.ItemClass)
                local ammo = wep and wep.Primary and wep.Primary.Ammo or nil
                if (not ammo) and wep and wep.Base then
                    local base = weapons.GetStored(wep.Base)
                    ammo = base and base.Primary and base.Primary.Ammo or ammo
                end
                ammoText = ammo and tostring(ammo) or ""
            end
            local ammoLbl = vgui.Create("DLabel", topRow)
            ammoLbl:SetText(ammoText)
            ammoLbl:Dock(RIGHT)
            ammoLbl:DockMargin(5,0,10,0)
            ammoLbl:SetFont("ZB_TDM_DESC")
            ammoLbl:SetTextColor(Color(200,200,200))

            local priceLbl = vgui.Create("DLabel", info)
            priceLbl:SetText("Price: $"..tostring(item.Price or 0))
            priceLbl:DockMargin(10,0,5,0)
            priceLbl:Dock(TOP)
            priceLbl:SetTextColor(Color(155,200,155))
            priceLbl:SetFont("ZB_TDM_DESC")
            priceLbl:SetTall(ScrH()*0.02)

            local buyBtn = vgui.Create("DButton", info)
            buyBtn:DockMargin(10,5,10,10)
            buyBtn:Dock(LEFT)
            buyBtn:SetText("Buy")
            buyBtn:SetTextColor(Color(200,200,200))
            buyBtn:SetFont("ZB_TDM_DESC")
            buyBtn:SetTall(ScrH()*0.025)
            buyBtn.Paint = PaintPanel
            buyBtn.Item = {catName, itemName}
            function buyBtn:DoClick()
                surface.PlaySound("ui/buttonclickrelease.wav")
                net.Start("ic_buy_equipment")
                    net.WriteTable(self.Item)
                net.SendToServer()
            end
        end
        local tab = sheet:AddSheet(catName, panel)
        tab.Tab:SetFont("ZB_TDM_CATEGORY")
        tab.Tab.Paint = PaintPanel
    end

    local teamIndex = LocalPlayer():GetNWInt("IC_CommanderTeam", -1)
    local lbl = vgui.Create("DLabel", frame)
    lbl:Dock(BOTTOM)
    lbl:DockMargin(10,5,10,5)
    lbl:SetFont("ZB_TDM_DESC")
    lbl:SetTextColor(Color(61,173,61))
    lbl:SetTall(ScrH()*0.02)
    function lbl:Think()
        local budget = (teamIndex == 0 and budget0) or budget1
        self:SetText("Budget: $"..tostring(budget))
    end
end
net.Receive("ic_open_buymenu", function()
    OpenTeamBuyMenu()
end)

function MODE:RoundStart()
    life0 = 40
    life1 = 40
    attrition = false
    IC_Active = true
    IC_EndActive = false
    if zb.ROUND_STATE == 0 then
        revealLocked = false
    end
end

local function drawBar(x, y, w, h, value, max, col)
    local frac = math.Clamp(max > 0 and (value / max) or 0, 0, 1)
    local fill = math.floor(h * frac)
    surface.SetDrawColor(18, 18, 22, 220)
    surface.DrawRect(x, y, w, h)
    surface.SetDrawColor(255, 255, 255, 20)
    surface.DrawOutlinedRect(x, y, w, h, 2)
    if fill > 0 then
        local stripes = 8
        local stripeH = math.max(1, math.floor(fill / stripes))
        for i = 0, stripes - 1 do
            local a = 190 + math.floor(i * (60 / stripes))
            local ry = y + h - fill + (i * stripeH)
            local rh = (i == stripes - 1) and (y + h - ry) or stripeH
            surface.SetDrawColor(col.r, col.g, col.b, a)
            surface.DrawRect(x, ry, w, rh)
        end
    end
    surface.SetFont("ZB_InterfaceMedium")
    local txt = tostring(value)
    local tw, th = surface.GetTextSize(txt)
    surface.SetTextColor(235, 235, 235, 255)
    surface.SetTextPos(x + (w - tw) / 2, y + 6)
    surface.DrawText(txt)
end

hook.Add("HUDPaint", "IC_CommanderHUD", function()
    if not IC_Active then return end
    local teamIndex = LocalPlayer():GetNWInt("IC_CommanderTeam", -1)
    if teamIndex < 0 then return end
    local w = 28
    local maxH = math.min(ScrH() * 0.7, 360)
    local y = math.floor((ScrH() - maxH) * 0.5)
    local insurgentCol = Color(190, 40, 40)
    local coalitionCol = Color(0, 173, 43)
    drawBar(6, y, w, maxH, life0, 40, insurgentCol)
    drawBar(ScrW() - w - 6, y, w, maxH, life1, 40, coalitionCol)

    local iconW, iconH = 18, 18
    surface.SetDrawColor(235, 235, 235, 255)
    surface.SetMaterial(matRebel)
    surface.DrawTexturedRect(6 + (w - iconW) * 0.5, y + maxH - iconH - 6, iconW, iconH)
    surface.SetMaterial(matGov)
    surface.DrawTexturedRect(ScrW() - w - 6 + (w - iconW) * 0.5, y + maxH - iconH - 6, iconW, iconH)

    surface.SetFont("ZB_InterfaceMediumLarge")
    local accent = (LocalPlayer():Team() == 0) and insurgentCol or coalitionCol
    surface.SetTextColor(accent.r, accent.g, accent.b, 255)
        local btxt = "Budget: $" .. ((teamIndex == 0 and budget0) or budget1)
    local tw, th = surface.GetTextSize(btxt)
    surface.SetTextPos(16, 16)
    surface.DrawText(btxt)

    if attrition then
        surface.SetFont("ZB_InterfaceMedium")
        surface.SetTextColor(215, 215, 215, 220)
        local msg = "Life Attrition Active — All Deaths Now Reduce Team Life"
        local tw, th = surface.GetTextSize(msg)
        surface.SetTextPos((ScrW() - tw) / 2, 48)
        surface.DrawText(msg)
    end
end)

hook.Add("HUDPaint", "IC_RoleReveal", function()
    if not IC_Active then return end
    if revealEnd <= CurTime() then return end
    local role = LocalPlayer().role
    if not role then return end
    local msg = "You are " .. (role.name or "")
    local accent = role.color or Color(215,215,215)
    local w = math.min(ScrW() * 0.6, 640)
    local h = 140
    local sx = -w - 48
    local tx = (ScrW() - w) / 2
    local ex = ScrW() + 48
    local now = CurTime()
    local tIn = math.Clamp((now - revealStart) / 0.8, 0, 1)
    local tOut = math.Clamp((now - (revealEnd - 0.8)) / 0.8, 0, 1)
    local x
    if now < (revealStart + 0.8) then
        x = Lerp(tIn, sx, tx)
    elseif now > (revealEnd - 0.8) then
        x = Lerp(tOut, tx, ex)
    else
        x = tx
    end
    local y = ScrH() * 0.32
    local fadeIn = math.Clamp((now - revealStart) / 0.25, 0, 1)
    local fadeOut = (now > (revealEnd - 0.8)) and (1 - tOut) or 1
    local fade = math.floor(255 * math.min(fadeIn, 1) * math.max(fadeOut, 0))
    surface.SetDrawColor(0, 0, 0, fade)
    surface.DrawRect(0, 0, ScrW(), ScrH())
    surface.SetDrawColor(18, 18, 22, 220)
    surface.DrawRect(x, y, w, h)
    surface.SetDrawColor(accent.r, accent.g, accent.b, 255)
    surface.DrawOutlinedRect(x, y, w, h, 2)
    surface.SetFont("ZB_InterfaceMedium")
    surface.SetTextColor(215, 215, 215, 220)
    local t = "Role"
    local tw, th = surface.GetTextSize(t)
    surface.SetTextPos(x + 16, y + 12)
    surface.DrawText(t)
    surface.SetFont("ZB_InterfaceLarge")
    surface.SetTextColor(accent.r, accent.g, accent.b, 255)
    local mw, mh = surface.GetTextSize(msg)
    surface.SetTextPos(x + (w - mw) / 2, y + (h - mh) / 2)
    surface.DrawText(msg)
end)

net.Receive("ZB_GiveRole", function()
    local data = net.ReadTable() or false
    LocalPlayer().role = data
    if zb and zb.CROUND ~= "insurgency_conflict" then return end
    revealStart = CurTime()
    revealEnd = CurTime() + 6
    revealLocked = true
    IC_Active = true
end)

-- clear decals when server asks
net.Receive("ic_clear_decals", function()
    RunConsoleCommand("r_cleardecals")
end)

hook.Remove("PreDrawHalos", "IC_TeamHalos")

hook.Add("HUDPaint", "IC_RespawnCountdown", function()
    if respawnEnd <= CurTime() then return end
    local left = math.max(0, math.ceil(respawnEnd - CurTime()))
    local txt = "Respawning in " .. left .. "s"
    surface.SetFont("ZB_InterfaceLarge")
    surface.SetTextColor(215, 215, 215, 255)
    local tw, th = surface.GetTextSize(txt)
    surface.SetTextPos((ScrW() - tw) / 2, ScrH() * 0.6)
    surface.DrawText(txt)
end)

function MODE:EndRound()
    IC_Active = false
    attrition = false
    revealEnd = 0
    timer.Remove("ic_attrition_notice")
    if IsValid(IC_PerkFrame) then IC_PerkFrame:Close() IC_PerkFrame = nil end
end
net.Receive("ic_roundtime", function()
    roundEnd = net.ReadFloat()
end)
hook.Add("HUDPaint", "IC_RoundTimer", function()
    if roundEnd <= CurTime() then return end
    local left = math.max(0, math.ceil(roundEnd - CurTime()))
    local m = math.floor(left / 60)
    local s = left % 60
    local txt = string.format("%02d:%02d", m, s)
    local col = attrition and Color(215,215,215) or Color(0,173,43)
    surface.SetFont("ZB_InterfaceMediumLarge")
    surface.SetTextColor(col.r, col.g, col.b, 255)
    local tw, th = surface.GetTextSize(txt)
    surface.SetTextPos((ScrW() - tw) / 2, 8)
    surface.DrawText(txt)
end)
hook.Add("HUDPaint", "IC_EndOverlay", function()
    if not IC_EndActive then return end
    local lp = LocalPlayer()
    local teamIndex = IsValid(lp) and lp:Team() or -1
    local bg
    local title
    local desc
    if IC_EndStalemate then
        bg = Color(60,60,60,180)
        title = "Stalemate"
        desc = "Operation stalled; neither side achieved decisive control."
    else
        local isWinner = (teamIndex == IC_EndWinner)
        local isLoser = (teamIndex == IC_EndLoser)
        if isWinner or (teamIndex == TEAM_SPECTATOR and IC_EndWinner >= 0) then
            bg = Color(0,173,43,180)
            title = "Winner"
            if IC_EndWinner == 0 then
                desc = "Insurgency gains momentum; control shifts toward rebellion."
            else
                desc = "Government stabilizes region; insurgent influence recedes."
            end
        else
            bg = Color(190,40,40,180)
            title = "Defeat"
            if IC_EndLoser == 0 then
                desc = "Insurgency momentum collapsed; government control strengthened."
            else
                desc = "Government operations faltered; insurgent presence expanded."
            end
        end
    end
    surface.SetDrawColor(bg.r, bg.g, bg.b, bg.a)
    surface.DrawRect(0, 0, ScrW(), ScrH())
    surface.SetFont("ZB_InterfaceMediumLarge")
    surface.SetTextColor(235, 235, 235, 255)
    local tw, th = surface.GetTextSize(title)
    surface.SetTextPos((ScrW() - tw) / 2, ScrH() * 0.16)
    surface.DrawText(title)
    if IC_EndStalemate then
        local size = math.min(ScrW(), ScrH()) * 0.16
        local gap = size * 0.2
        local totalW = size * 2 + gap
        local sx = (ScrW() - totalW) * 0.5
        local y = (ScrH() - size) * 0.5
        surface.SetDrawColor(255,255,255,255)
        surface.SetMaterial(matRebel)
        surface.DrawTexturedRect(sx, y, size, size)
        surface.SetMaterial(matGov)
        surface.DrawTexturedRect(sx + size + gap, y, size, size)
    else
        local iconTeam
        if teamIndex == TEAM_SPECTATOR then
            iconTeam = (IC_EndWinner >= 0) and IC_EndWinner or IC_EndLoser
        elseif teamIndex == IC_EndWinner or teamIndex == IC_EndLoser then
            iconTeam = teamIndex
        else
            iconTeam = (IC_EndWinner >= 0) and IC_EndWinner or IC_EndLoser
        end
        local icon = (iconTeam == 0) and matRebel or matGov
        local size = math.min(ScrW(), ScrH()) * 0.18
        local x = (ScrW() - size) * 0.5
        local y = (ScrH() - size) * 0.5
        surface.SetMaterial(icon)
        surface.SetDrawColor(255,255,255,255)
        surface.DrawTexturedRect(x, y, size, size)
    end
    surface.SetFont("ZB_InterfaceMedium")
    surface.SetTextColor(235, 235, 235, 255)
    local dw, dh = surface.GetTextSize(desc)
    surface.SetTextPos((ScrW() - dw) / 2, ScrH() * 0.8)
    surface.DrawText(desc)
end)
net.Receive("ic_perkdefs", function()
    IC_PerkDefs = net.ReadTable() or {}
end)
local IC_QMenu
hook.Add("Think", "IC_QMenuThink", function()
    if zb and zb.CROUND and zb.CROUND ~= "insurgency_conflict" then return end
    local lp = LocalPlayer()
    if not IsValid(lp) then return end
    local isCommander = lp:GetNWInt("IC_CommanderTeam", -1) >= 0
    if not isCommander then
        if IsValid(IC_QMenu) then IC_QMenu:Remove() IC_QMenu = nil end
        return
    end
    local down = input.IsKeyDown(KEY_Q)
    if down and not IsValid(IC_QMenu) then
        local frame = vgui.Create("DFrame")
        IC_QMenu = frame
        frame:SetTitle("")
        frame:ShowCloseButton(false)
        frame:SetSize(math.min(ScrW() * 0.6, 720), 320)
        frame:Center()
        frame:MakePopup()
        frame:SetDraggable(false)
        frame:SetAlpha(0)
        frame:AlphaTo(255, 0.15, 0)

        local container = vgui.Create("DPanel", frame)
        container:Dock(FILL)
        container:SetPaintBackground(false)

        local items = {
            {id = "airstrike", label = "Airstrike"},
            {id = "uav", label = "UAV"},
            {id = "troop", label = "Troop"}
        }

        local w = math.floor(frame:GetWide() / 3) - 24
        for i, it in ipairs(items) do
            local card = vgui.Create("DPanel", container)
            card:SetWide(w)
            card:Dock(LEFT)
            card:DockMargin(12, 12, 12, 12)
            card.Paint = function(p, pw, ph)
                surface.SetDrawColor(18, 18, 22, 235)
                surface.DrawRect(0, 0, pw, ph)
                local accent = (lp:Team() == 0) and Color(190,40,40) or Color(0,173,43)
                surface.SetDrawColor(accent.r, accent.g, accent.b, 255)
                surface.DrawOutlinedRect(0, 0, pw, ph, 2)
            end

            local icon = vgui.Create("DPanel", card)
            icon:Dock(TOP)
            icon:SetTall(110)
            icon:DockMargin(12, 12, 12, 6)
            icon.Paint = function(p, pw, ph)
                surface.SetDrawColor(0, 0, 0, 180)
                surface.DrawRect(0, 0, pw, ph)
                local accent = (lp:Team() == 0) and Color(190,40,40) or Color(0,173,43)
                surface.SetDrawColor(accent.r, accent.g, accent.b, 255)
                surface.DrawOutlinedRect(0, 0, pw, ph, 2)
                local mat = IC_PerkIcons[it.id]
                if mat then
                    surface.SetMaterial(mat)
                    surface.SetDrawColor(255,255,255,255)
                    local size = math.min(pw - 20, ph - 20)
                    local x = (pw - size) * 0.5
                    local y = (ph - size) * 0.5
                    surface.DrawTexturedRect(x, y, size, size)
                end
            end

            local namePanel = vgui.Create("DPanel", card)
            namePanel:Dock(TOP)
            namePanel:SetTall(28)
            namePanel:DockMargin(12, 0, 12, 6)
            namePanel.Paint = function(p, pw, ph)
                surface.SetFont("ZB_InterfaceMedium")
                local txt = it.label
                local tw, th = surface.GetTextSize(txt)
                surface.SetTextColor(215,215,215,255)
                surface.SetTextPos((pw - tw)/2, (ph - th)/2)
                surface.DrawText(txt)
            end

            local call = vgui.Create("DButton", card)
            call:Dock(TOP)
            call:SetTall(36)
            call:DockMargin(12, 0, 12, 6)
            call:SetText("")
            call.DoClick = function()
                local cost = 0
                for _, d in ipairs(IC_PerkDefs) do
                    if d.id == it.id then cost = d.cost or 0 break end
                end
                local teamIndex = lp:GetNWInt("IC_CommanderTeam", -1)
                local myBudget = (teamIndex == 0 and budget0) or budget1
                if myBudget < cost then return end
                surface.PlaySound("ui/buttonclickrelease.wav")
                net.Start("ic_buy_perk")
                    net.WriteString(it.id)
                    net.WriteInt(cost, 16)
                net.SendToServer()
                if it.id == "airstrike" then
                    IC_AS_Picking = true
                end
            end
            call.Paint = function(p, pw, ph)
                local accent = (lp:Team() == 0) and Color(190,40,40) or Color(0,173,43)
                local cost = 0
                for _, d in ipairs(IC_PerkDefs) do
                    if d.id == it.id then cost = d.cost or 0 break end
                end
                local teamIndex = lp:GetNWInt("IC_CommanderTeam", -1)
                local myBudget = (teamIndex == 0 and budget0) or budget1
                local enabled = myBudget >= cost
                if it.id == "troop" then
                    local teamLife = (teamIndex == 0 and life0) or life1
                    if teamLife >= 40 then enabled = false end
                end
                local col = enabled and Color(accent.r,accent.g,accent.b,255) or Color(90,90,90,220)
                surface.SetDrawColor(col.r, col.g, col.b, col.a)
                surface.DrawRect(0, 0, pw, ph)
                surface.SetFont("ZB_InterfaceMedium")
                local tw, th = surface.GetTextSize("Call In")
                local txtCol = enabled and Color(18,18,22,240) or Color(200,200,200,200)
                surface.SetTextColor(txtCol.r, txtCol.g, txtCol.b, txtCol.a)
                surface.SetTextPos((pw - tw)/2, (ph - th)/2)
                surface.DrawText("Call In")
            end

            local costPanel = vgui.Create("DPanel", card)
            costPanel:Dock(TOP)
            costPanel:SetTall(24)
            costPanel:DockMargin(12, 0, 12, 12)
            costPanel.Paint = function(p, pw, ph)
                local cost = 0
                for _, d in ipairs(IC_PerkDefs) do
                    if d.id == it.id then cost = d.cost or 0 break end
                end
                surface.SetFont("ZB_InterfaceMedium")
                local teamIndex = lp:GetNWInt("IC_CommanderTeam", -1)
                local myBudget = (teamIndex == 0 and budget0) or budget1
                local txt = "Cost: $" .. tostring(cost) .. "  Budget: $" .. tostring(myBudget)
                local tw, th = surface.GetTextSize(txt)
                local ok = myBudget >= cost
                local c = ok and Color(215,215,215,255) or Color(215,60,60,255)
                surface.SetTextColor(c.r, c.g, c.b, c.a)
                surface.SetTextPos((pw - tw)/2, (ph - th)/2)
                surface.DrawText(txt)
            end
        end
    elseif not down and IsValid(IC_QMenu) then
        IC_QMenu:AlphaTo(0, 0.12, 0, function() if IsValid(IC_QMenu) then IC_QMenu:Remove() IC_QMenu = nil end end)
    end
end)

hook.Add("Think", "IC_ModeGuard", function()
    if zb and zb.CROUND and zb.CROUND ~= "insurgency_conflict" then
        if IC_Active then
            IC_Active = false
            attrition = false
            roundEnd = 0
            if IsValid(IC_PerkFrame) then IC_PerkFrame:Close() IC_PerkFrame = nil end
            if IsValid(IC_QMenu) then IC_QMenu:Remove() IC_QMenu = nil end
        end
    end
end)

local IC_AS_Picking = false
local IC_AS_Radius = 320
local IC_AS_Pos = nil
local IC_AS_ML = false
local IC_AS_MR = false

-- Handle team-to-commander chat messages
hook.Add("OnPlayerChat", "IC_TeamToCommanderChat", function(ply, text, teamChat, isDead, prefixText, color1, color2)
    local mode = CurrentRound()
    if not mode or mode.name ~= "insurgency_conflict" then return end
    if not IsValid(ply) then return end
    
    local lp = LocalPlayer()
    if not IsValid(lp) then return end
    
    -- Check if this is a team-to-commander message
    if string.StartWith(text or "", "[TEAM]: ") then
        -- Only show to commanders and the sender
        -- Show to commanders
        if lp:GetNWBool("IC_IsCommander", false) and lp:GetNWInt("IC_CommanderTeam", -1) == ply:Team() then
            chat.AddText(Color(255, 200, 0), text)
            return true -- Suppress default chat
        end
        
        -- Don't show to other players
        return true
    end
    
    -- Check if this is a sender's own message to commander
    if string.StartWith(text or "", "[TO COMMANDER]: ") and ply == lp then
        chat.AddText(Color(100, 255, 100), text)
        return true -- Suppress default chat
    end
    
    -- Check if this is a commander message
    if string.StartWith(text or "", "[COMMANDER]: ") then
        -- Show to everyone on the commander's team
        if lp:Team() == ply:Team() then
            chat.AddText(Color(255, 100, 100), text)
            return true -- Suppress default chat
        end
        
        -- Don't show to other teams
        return true
    end
end)

net.Receive("ic_airstrike_begin", function()
    local lp = LocalPlayer()
    if lp:GetNWInt("IC_CommanderTeam", -1) < 0 then return end
    IC_AS_Picking = true
    if IsValid(IC_QMenu) then IC_QMenu:Remove() IC_QMenu = nil end
end)

hook.Add("Think", "IC_AirstrikeSelect", function()
    if not IC_AS_Picking then return end
    local lp = LocalPlayer()
    if not IsValid(lp) then return end
    local tr = util.TraceLine({start = lp:EyePos(), endpos = lp:EyePos() + lp:EyeAngles():Forward() * 100000, filter = lp})
    IC_AS_Pos = tr.HitPos
    local ml = input.IsMouseDown(MOUSE_LEFT)
    local mr = input.IsMouseDown(MOUSE_RIGHT)
    if ml and not IC_AS_ML then
        IC_AS_ML = true
        if IC_AS_Pos then
            net.Start("ic_airstrike_execute")
                net.WriteVector(IC_AS_Pos)
            net.SendToServer()
        end
        IC_AS_Picking = false
    elseif not ml and IC_AS_ML then
        IC_AS_ML = false
    end
    if mr and not IC_AS_MR then
        IC_AS_MR = true
        net.Start("ic_airstrike_cancel")
        net.SendToServer()
        IC_AS_Picking = false
    elseif not mr and IC_AS_MR then
        IC_AS_MR = false
    end
end)

hook.Add("PostDrawTranslucentRenderables", "IC_AirstrikeRing", function()
    if not IC_AS_Picking then return end
    if not IC_AS_Pos then return end
    local center = IC_AS_Pos + Vector(0,0,2)
    local lp = LocalPlayer()
    local tr = util.TraceLine({start = center + Vector(0,0,64), endpos = center - Vector(0,0,128), filter = lp})
    local n = tr.Hit and tr.HitNormal or Vector(0,0,1)
    n:Normalize()
    local ref = Vector(0,0,1)
    local t1 = n:Cross(ref)
    if t1:LengthSqr() < 0.0001 then
        ref = Vector(1,0,0)
        t1 = n:Cross(ref)
    end
    t1:Normalize()
    local t2 = n:Cross(t1)
    t2:Normalize()
    local r = IC_AS_Radius
    local segs = 64
    local first, last
    for i = 0, segs do
        local t = (i / segs) * math.pi * 2
        local pos = center + t1 * math.cos(t) * r + t2 * math.sin(t) * r
        if last then render.DrawLine(last, pos, Color(0,173,43,180), true) end
        if not first then first = pos end
        last = pos
    end
    if first and last then render.DrawLine(last, first, Color(0,173,43,180), true) end
end)
local IC_UAVMarks = {}
net.Receive("ic_uav_marks", function()
    local count = net.ReadUInt(16)
    for i = 1, count do
        local ent = net.ReadEntity()
        if IsValid(ent) then IC_UAVMarks[ent] = CurTime() + 30 end
    end
end)

hook.Add("Think", "IC_UAVMarksPrune", function()
    for ent, exp in pairs(IC_UAVMarks) do
        if (not IsValid(ent)) or exp <= CurTime() then IC_UAVMarks[ent] = nil end
    end
end)

hook.Add("PostDrawTranslucentRenderables", "IC_UAVDots", function()
    for ent, exp in pairs(IC_UAVMarks) do
        if exp <= CurTime() then continue end
        if not IsValid(ent) then continue end
        local pos = ent:EyePos() + Vector(0,0,16)
        render.SetMaterial(matDot)
        cam.IgnoreZ(true)
        render.DrawSprite(pos, 18, 18, Color(0, 200, 0, 230))
        cam.IgnoreZ(false)
    end
end)
local IC_UAV_Picking = false
local IC_UAV_Pos = nil
local IC_UAV_Radius = 1600
local IC_UAV_ML = false
local IC_UAV_MR = false

net.Receive("ic_uav_begin", function()
    local lp = LocalPlayer()
    if lp:GetNWInt("IC_CommanderTeam", -1) < 0 then return end
    IC_UAV_Picking = true
end)

hook.Add("Think", "IC_UAVSelect", function()
    if not IC_UAV_Picking then return end
    local lp = LocalPlayer()
    if not IsValid(lp) then return end
    local tr = util.TraceLine({start = lp:EyePos(), endpos = lp:EyePos() + lp:EyeAngles():Forward() * 100000, filter = lp})
    IC_UAV_Pos = tr.HitPos
    local ml = input.IsMouseDown(MOUSE_LEFT)
    local mr = input.IsMouseDown(MOUSE_RIGHT)
    if ml and not IC_UAV_ML then
        IC_UAV_ML = true
        if IC_UAV_Pos then
            net.Start("ic_uav_execute")
                net.WriteVector(IC_UAV_Pos)
            net.SendToServer()
        end
        IC_UAV_Picking = false
    elseif not ml and IC_UAV_ML then
        IC_UAV_ML = false
    end
    if mr and not IC_UAV_MR then
        IC_UAV_MR = true
        net.Start("ic_uav_cancel")
        net.SendToServer()
        IC_UAV_Picking = false
    elseif not mr and IC_UAV_MR then
        IC_UAV_MR = false
    end
end)

hook.Add("PostDrawTranslucentRenderables", "IC_UAVRing", function()
    if not IC_UAV_Picking then return end
    if not IC_UAV_Pos then return end
    local center = IC_UAV_Pos + Vector(0,0,2)
    local lp = LocalPlayer()
    local tr = util.TraceLine({start = center + Vector(0,0,64), endpos = center - Vector(0,0,128), filter = lp})
    local n = tr.Hit and tr.HitNormal or Vector(0,0,1)
    n:Normalize()
    local ref = Vector(0,0,1)
    local t1 = n:Cross(ref)
    if t1:LengthSqr() < 0.0001 then
        ref = Vector(1,0,0)
        t1 = n:Cross(ref)
    end
    t1:Normalize()
    local t2 = n:Cross(t1)
    t2:Normalize()
    local r = IC_UAV_Radius
    local segs = 64
    local first, last
    for i = 0, segs do
        local t = (i / segs) * math.pi * 2
        local pos = center + t1 * math.cos(t) * r + t2 * math.sin(t) * r
        if last then render.DrawLine(last, pos, Color(0,173,43,180), true) end
        if not first then first = pos end
        last = pos
    end
    if first and last then render.DrawLine(last, first, Color(0,173,43,180), true) end
end)

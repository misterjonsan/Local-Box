local MODE = MODE
MODE.name = "slasher"

local roundEnding = false
local preSong
local killerSong
local killerSongActive = false

local teams = {
    [0] = { name = "SWAT", color1 = Color(68, 10, 255), color2 = Color(68, 10, 255) },
    [1] = { name = "Bystander", color1 = Color(228, 49, 49), color2 = Color(228, 49, 49) },
    [2] = { name = "Killer", color1 = Color(228, 49, 49), color2 = Color(228, 49, 49) },
}

net.Receive("slasher_start", function()
    roundEnding = false
    if IsValid(preSong) then preSong:Stop() preSong = nil end
    sound.PlayFile("sound/conclusion.mp3", "mono noblock", function(station)
        if IsValid(station) then
            station:Play()
            station:SetVolume(1)
            preSong = station
        end
    end)
end)

local posadd = 0
function MODE:RenderScreenspaceEffects()
    zb.RemoveFade()
    if zb.ROUND_START + 7.5 < CurTime() then return end
    local fade = math.Clamp(zb.ROUND_START + 7.5 - CurTime(), 0, 1)
    surface.SetDrawColor(0, 0, 0, 255 * fade)
    surface.DrawRect(-1, -1, ScrW() + 1, ScrH() + 1)
end

function MODE:HUDPaint()
    local arriveKiller = zb.ROUND_START + 60
    local arriveSWAT = zb.ROUND_START + 300

    if zb.ROUND_START + 60 > CurTime() then
        posadd = Lerp(FrameTime() * 5,posadd or 0, zb.ROUND_START + 7.3 < CurTime() and 0 or -sw * 0.4)
        local blink = math.sin(CurTime()*3) >= 0 and Color(255,0,0) or Color(0,0,0)
        draw.SimpleText( "Killer will arrive in: "..string.FormattedTime(arriveKiller - CurTime(), "%02i:%02i"), "ZB_HomicideMedium", sw * 0.02 + posadd, sh * 0.91, Color(0,0,0), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText( "Killer will arrive in: "..string.FormattedTime(arriveKiller - CurTime(), "%02i:%02i"), "ZB_HomicideMedium", (sw * 0.02) - 2 + posadd, (sh * 0.91) - 2, blink, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    -- killer positional music handled server-side

    if zb.ROUND_START + 300 > CurTime() then
        posadd = Lerp(FrameTime() * 5,posadd or 0, zb.ROUND_START + 7.3 < CurTime() and 0 or -sw * 0.4)
        local color = Color(255*-math.sin(CurTime()*3),25,255*math.sin(CurTime()*3))
        draw.SimpleText( string.FormattedTime(arriveSWAT - CurTime(), "%02i:%02i").." Until it becomes dawn", "ZB_HomicideMedium", sw * 0.02 + posadd, sh * 0.95, Color(0,0,0), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText( string.FormattedTime(arriveSWAT - CurTime(), "%02i:%02i").." Until it becomes dawn", "ZB_HomicideMedium", (sw * 0.02) - 2 + posadd, (sh * 0.95) - 2, color, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        local fade = math.Clamp(zb.ROUND_START + 7.5 - CurTime(), 0, 1)
        surface.SetDrawColor(0, 0, 0, 255 * fade)
        surface.DrawRect(-1, -1, ScrW() + 1, ScrH() + 1)
    end

    if lply:Team() == 2 then
        local t = CurTime()
        local active = t < arriveKiller
        local fadeout = math.Clamp((arriveKiller + 1.5 - t) / 1.5, 0, 1)
        local revealEnd = zb.ROUND_START + 8.5
        if (active or fadeout > 0) and t >= revealEnd then
            local alpha = active and 255 or math.floor(255 * fadeout)
            surface.SetDrawColor(0, 0, 0, alpha)
            surface.DrawRect(0, 0, sw, sh)
            local fade = active and 1 or fadeout
            local colRed = Color(228, 49, 49, 255 * fade)
            local colWhite = Color(255, 255, 255, 255 * fade)
            draw.SimpleText("You are the killer", "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.4, colRed, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText("You will arrive in " .. string.FormattedTime(math.max(arriveKiller - t, 0), "%02i:%02i"), "ZB_HomicideMedium", sw * 0.5, sh * 0.5, colWhite, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end

    if zb.ROUND_START + 8.5 > CurTime() then
        if not lply:Alive() and not lply:Team() == 0 then return end
        local fade = math.Clamp(zb.ROUND_START + 8 - CurTime(), 0, 1)
        local team_ = lply:Team()
        draw.SimpleText("Slasher", "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.1, Color(0, 162, 255, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        local Rolename = teams[team_].name
        local ColorRole = teams[team_].color1
        ColorRole.a = 255 * fade
        draw.SimpleText("You are " .. Rolename, "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.5, ColorRole, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        local ColorObj = teams[team_].color2
        ColorObj.a = 255 * fade
    end
end

local CreateEndMenu
net.Receive("slasher_roundend", function()
    roundEnding = true
    CreateEndMenu(net.ReadBool())
end)

net.Receive("slasher_killer_dead", function() end)

if IsValid(hmcdEndMenu) then
    hmcdEndMenu:Remove()
    hmcdEndMenu = nil
end

CreateEndMenu = function(whowin)
    if IsValid(hmcdEndMenu) then
        hmcdEndMenu:Remove()
        hmcdEndMenu = nil
    end

    local col = Color(255, 255, 255, 255)
    local colGray = Color(85, 85, 85, 255)
    local colRed = Color(130, 10, 10)
    local colRedUp = Color(160, 30, 30)

    local colSpect1 = Color(75, 75, 75, 255)
    local colSpect2 = Color(255, 255, 255)

    hmcdEndMenu = vgui.Create("ZFrame")
    surface.PlaySound( (whowin == 1) and "zbattle/criresp/failedSWAT.mp3" or "ambient/alarms/warningbell1.wav")
    local sizeX, sizeY = ScrW() / 2.5, ScrH() / 1.2
    local posX, posY = ScrW() / 1.3 - sizeX / 2, ScrH() / 2 - sizeY / 2
    hmcdEndMenu:SetPos(posX, posY)
    hmcdEndMenu:SetSize(sizeX, sizeY)
    hmcdEndMenu:MakePopup()
    hmcdEndMenu:SetKeyboardInputEnabled(false)
    hmcdEndMenu:ShowCloseButton(false)
    local closebutton = vgui.Create("DButton", hmcdEndMenu)
    closebutton:SetPos(5, 5)
    closebutton:SetSize(ScrW() / 20, ScrH() / 30)
    closebutton:SetText("")
    closebutton.DoClick = function()
        if IsValid(hmcdEndMenu) then
            hmcdEndMenu:Close()
            hmcdEndMenu = nil
        end
    end

    closebutton.Paint = function(self, w, h)
        surface.SetDrawColor(122, 122, 122, 255)
        surface.DrawOutlinedRect(0, 0, w, h, 2.5)
        surface.SetFont("ZB_InterfaceMedium")
        surface.SetTextColor(col.r, col.g, col.b, col.a)
        local lenghtX, lenghtY = surface.GetTextSize("Close")
        surface.SetTextPos(lenghtX - lenghtX / 1.1, 4)
        surface.DrawText("Close")
    end

    hmcdEndMenu.PaintOver = function(self, w, h)
        surface.SetFont("ZB_InterfaceMediumLarge")
        surface.SetTextColor(col.r, col.g, col.b, col.a)
        local lenghtX, lenghtY = surface.GetTextSize("Players:")
        surface.SetTextPos(w / 2 - lenghtX / 2, 20)
        surface.DrawText("Players:")
    end

    local DScrollPanel = vgui.Create("DScrollPanel", hmcdEndMenu)
    DScrollPanel:SetPos(10, 80)
    DScrollPanel:SetSize(sizeX - 20, sizeY - 90)

    for i, ply in player.Iterator() do
        if ply:Team() == TEAM_SPECTATOR then continue end
        local but = vgui.Create("DButton", DScrollPanel)
        but:SetSize(100, 50)
        but:Dock(TOP)
        but:DockMargin(8, 6, 8, -1)
        but:SetText("")
        but.Paint = function(self, w, h)
            local col1 = (ply:Alive() and colRed) or colGray
            local col2 = (ply:Alive() and colRedUp) or colSpect1
            surface.SetDrawColor(col1.r, col1.g, col1.b, col1.a)
            surface.DrawRect(0, 0, w, h)
            surface.SetDrawColor(col2.r, col2.g, col2.b, col2.a)
            surface.DrawRect(0, h / 2, w, h / 2)
            local colc = ply:GetPlayerColor():ToColor()
            surface.SetFont("ZB_InterfaceMediumLarge")
            local lenghtX, lenghtY = surface.GetTextSize(ply:GetPlayerName() or "He quited...")
            surface.SetTextColor(0, 0, 0, 255)
            surface.SetTextPos(w / 2 + 1, h / 2 - lenghtY / 2 + 1)
            surface.DrawText(ply:GetPlayerName() or "He quited...")
            surface.SetTextColor(colc.r, colc.g, colc.b, colc.a)
            surface.SetTextPos(w / 2, h / 2 - lenghtY / 2)
            surface.DrawText(ply:GetPlayerName() or "He quited...")
            local colz = colSpect2
            surface.SetFont("ZB_InterfaceMediumLarge")
            surface.SetTextColor(colz.r, colz.g, colz.b, colz.a)
            local lx, ly = surface.GetTextSize(ply:GetPlayerName() or "He quited...")
            surface.SetTextPos(15, h / 2 - ly / 2)
            surface.DrawText(ply:Name() .. (ply:GetNetVar("handcuffed", false) and " - neutralized" or (not ply:Alive() and " - dead") or ""))
            surface.SetFont("ZB_InterfaceMediumLarge")
            surface.SetTextColor(colz.r, colz.g, colz.b, colz.a)
            local fx, fy = surface.GetTextSize(ply:Frags() or "He quited...")
            surface.SetTextPos(w - fx - 15, h / 2 - fy / 2)
            surface.DrawText(ply:Frags() or "He quited...")
        end

        function but:DoClick()
            if ply:IsBot() then
                chat.AddText(Color(255, 0, 0), "no, you can't")
                return
            end
            gui.OpenURL("https://steamcommunity.com/profiles/" .. ply:SteamID64())
        end

        DScrollPanel:AddItem(but)
    end
    return true
end

function MODE:RoundStart()
    if IsValid(hmcdEndMenu) then
        hmcdEndMenu:Remove()
        hmcdEndMenu = nil
    end
end

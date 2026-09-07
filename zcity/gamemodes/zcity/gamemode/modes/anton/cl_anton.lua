local MODE = MODE
MODE.name = "anton"

local roundEnding = false

local teams = {
    [0] = {
        objective = "Kill or arrest Anton Chigurh.",
        name = "Police",
        color1 = Color(68, 10, 255),
        color2 = Color(68, 10, 255)
    },
    [1] = {
        objective = "Survive at all costs.",
        name = "Victim",
        color1 = Color(255, 255, 255),
        color2 = Color(255, 255, 255)
    },
    [2] = {
        objective = "Kill everyone. No witnesses.",
        name = "Anton Chigurh",
        color1 = Color(228, 49, 49),
        color2 = Color(228, 49, 49)
    },
}

net.Receive("anton_start", function()
    surface.PlaySound("anton_chegur/round-start.wav")
    roundEnding = false
end)

function MODE:RenderScreenspaceEffects()
    if not zb or not zb.RemoveFade then return end
    zb.RemoveFade()
    if zb.ROUND_START + 7.5 < CurTime() then return end
    local fade = math.Clamp(zb.ROUND_START + 7.5 - CurTime(), 0, 1)
    surface.SetDrawColor(0, 0, 0, 255 * fade)
    surface.DrawRect(-1, -1, ScrW() + 1, ScrH() + 1)
end

local posadd = 0
function MODE:HUDPaint()
    local sw, sh = ScrW(), ScrH()
    local lply = LocalPlayer()
    if not IsValid(lply) then return end

    local arriveAnton = zb.ROUND_START + 20
    local arrivePolice = zb.ROUND_START + 138

    if zb.ROUND_START + 20 > CurTime() then
        posadd = Lerp(FrameTime() * 5,posadd or 0, zb.ROUND_START + 7.3 < CurTime() and 0 or -sw * 0.4)
        local blink = math.sin(CurTime()*3) >= 0 and Color(255,0,0) or Color(0,0,0)
        draw.SimpleText( "Anton will arrive in: "..string.FormattedTime(arriveAnton - CurTime(), "%02i:%02i"), "ZB_HomicideMedium", sw * 0.02 + posadd, sh * 0.91, Color(0,0,0), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText( "Anton will arrive in: "..string.FormattedTime(arriveAnton - CurTime(), "%02i:%02i"), "ZB_HomicideMedium", (sw * 0.02) - 2 + posadd, (sh * 0.91) - 2, blink, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    if zb.ROUND_START + 138 > CurTime() then
        posadd = Lerp(FrameTime() * 5,posadd or 0, zb.ROUND_START + 7.3 < CurTime() and 0 or -sw * 0.4) 
        local color = Color(25,25,255)
        draw.SimpleText( string.FormattedTime(arrivePolice - CurTime(), "%02i:%02i").." Until Police Arrival", "ZB_HomicideMedium", sw * 0.02 + posadd, sh * 0.95, Color(0,0,0), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText( string.FormattedTime(arrivePolice - CurTime(), "%02i:%02i").." Until Police Arrival", "ZB_HomicideMedium", (sw * 0.02) - 2 + posadd, (sh * 0.95) - 2, color, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    if lply:Team() == 2 then
        local t = CurTime()
        local active = t < arriveAnton
        local fadeout = math.Clamp((arriveAnton + 1.5 - t) / 1.5, 0, 1)
        local revealEnd = zb.ROUND_START + 8.5
        if (active or fadeout > 0) and t >= revealEnd then
            local alpha = active and 255 or math.floor(255 * fadeout)
            surface.SetDrawColor(0, 0, 0, alpha)
            surface.DrawRect(0, 0, sw, sh)
            local fade = active and 1 or fadeout
            local colRed = Color(228, 49, 49, 255 * fade)
            local colWhite = Color(255, 255, 255, 255 * fade)
            draw.SimpleText("You are Anton Chigurh", "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.4, colRed, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText("What's the most you ever lost on a coin toss?", "ZB_HomicideMedium", sw * 0.5, sh * 0.5, colWhite, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText("You will arrive in " .. string.FormattedTime(math.max(arriveAnton - t, 0), "%02i:%02i"), "ZB_HomicideMedium", sw * 0.5, sh * 0.6, colWhite, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end

	if zb.ROUND_START + 8.5 > CurTime() then
		if not lply:Alive() and not (lply:Team() == 0) then return end
		local fade = math.Clamp(zb.ROUND_START + 8 - CurTime(), 0, 1)
		local team_ = lply:Team()
        if not teams[team_] then return end
		draw.SimpleText("Anton Chigurh", "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.1, Color(200, 0, 0, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		local Rolename = teams[team_].name
		local ColorRole = Color(teams[team_].color1.r, teams[team_].color1.g, teams[team_].color1.b, 255 * fade)
		draw.SimpleText("You are " .. Rolename, "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.5, ColorRole, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		local Objective = teams[team_].objective
		local ColorObj = Color(teams[team_].color2.r, teams[team_].color2.g, teams[team_].color2.b, 255 * fade)
		draw.SimpleText(Objective, "ZB_HomicideMedium", sw * 0.5, sh * 0.9, ColorObj, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
end

local CreateEndMenu
net.Receive("anton_roundend", function()
    roundEnding = true
    CreateEndMenu(net.ReadBool())
end)

CreateEndMenu = function(whowin)
	if IsValid(hmcdEndMenu) then
		hmcdEndMenu:Remove()
		hmcdEndMenu = nil
	end

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
		surface.SetTextColor(255, 255, 255, 255)
		local lx, ly = surface.GetTextSize("Close")
		surface.SetTextPos(lx - lx / 1.1, 4)
		surface.DrawText("Close")
	end

	hmcdEndMenu.PaintOver = function(self, w, h)
		surface.SetFont("ZB_InterfaceMediumLarge")
		surface.SetTextColor(255, 255, 255, 255)
		local lx, ly = surface.GetTextSize("Players:")
		surface.SetTextPos(w / 2 - lx / 2, 20)
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
            local colGray = Color(85, 85, 85, 255)
            local colRed = Color(130, 10, 10)
            local colRedUp = Color(160, 30, 30)
            local colSpect1 = Color(75, 75, 75, 255)
            local colSpect2 = Color(255, 255, 255)

            local col1 = (ply:Alive() and colRed) or colGray
            local col2 = (ply:Alive() and colRedUp) or colSpect1
            surface.SetDrawColor(col1.r, col1.g, col1.b, col1.a)
            surface.DrawRect(0, 0, w, h)
            surface.SetDrawColor(col2.r, col2.g, col2.b, col2.a)
            surface.DrawRect(0, h / 2, w, h / 2)
            local colc = ply:GetPlayerColor():ToColor()
            surface.SetFont("ZB_InterfaceMediumLarge")
            local lx, ly = surface.GetTextSize(ply:GetPlayerName() or "He quited...")
            surface.SetTextColor(0, 0, 0, 255)
            surface.SetTextPos(w / 2 + 1, h / 2 - ly / 2 + 1)
            surface.DrawText(ply:GetPlayerName() or "He quited...")
            surface.SetTextColor(colc.r, colc.g, colc.b, colc.a)
            surface.SetTextPos(w / 2, h / 2 - ly / 2)
            surface.DrawText(ply:GetPlayerName() or "He quited...")
            surface.SetFont("ZB_InterfaceMediumLarge")
            surface.SetTextColor(colSpect2.r, colSpect2.g, colSpect2.b, colSpect2.a)
            surface.SetTextPos(15, h / 2 - ly / 2)
            surface.DrawText(ply:Name() .. (ply:GetNetVar("handcuffed", false) and " - neutralized" or (not ply:Alive() and " - dead") or ""))
        end

		function but:DoClick()
			if ply:IsBot() then return end
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

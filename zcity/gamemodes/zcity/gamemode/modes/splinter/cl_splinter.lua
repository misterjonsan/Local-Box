MODE.name = "sc"

local MODE = MODE

net.Receive("sc_start", function()
	surface.PlaySound("infiltration_round.wav")
	zb.rtype = net.ReadString()
	hg.DynaMusic:Start( "splinter_cell" )
	zb.RemoveFade()
end)

local teams = {
	[0] = {
		objective = "Steal the suitcase and escape with it or kill all guards.",
		name = "a Infiltrator",
		color1 = Color(39,233,0),
		color2 = Color(31,184,0)
	},
	[1] = {
		objective = "Protect the suitcases or kill the infiltrator.",
		name = "a Guard",
		color1 = Color(35,150,196),
		color2 = Color(31,132,172)
	},
}

hook.Add( "StartCommand", "SC_DisallowMoveOrShoting", function(ply, mv)
	if zb.CROUND == "splinter" and (zb.ROUND_START or 0) + 20 > CurTime() and ply:Team() == 1 then
		mv:RemoveKey(IN_ATTACK)
		mv:RemoveKey(IN_ATTACK2)
		mv:RemoveKey(IN_FORWARD)
		mv:RemoveKey(IN_BACK)
		mv:RemoveKey(IN_MOVELEFT)
		mv:RemoveKey(IN_MOVERIGHT)
	end
end)

function MODE:RenderScreenspaceEffects()
	local StartTime = zb.ROUND_START or CurTime()
	if StartTime + 7.5 < CurTime() then return end
	local fade = math.Clamp(StartTime + 7.5 - CurTime(),0,1)

	surface.SetDrawColor(0,0,0,255 * fade)
	surface.DrawRect(-1,-1,ScrW() + 1,ScrH() + 1)
end

surface.CreateFont("ZB_SCSmall", {
	font = "AmbexHeavy",
	size = ScreenScale(15),
	weight = 400,
	antialias = true,
	scanlines = 3,
	bold = true,
})

surface.CreateFont("ZB_SCMedium", {
	font = "AmbexHeavy",
	size = ScreenScale(20),
	weight = 400,
	antialias = true,
	scanlines = 3,
	bold = true,
})

surface.CreateFont("ZB_SCMediumLarge", {
	font = "AmbexHeavy",
	size = ScreenScale(25),
	weight = 400,
	antialias = true,
	scanlines = 3,
	bold = true,
})

surface.CreateFont("ZB_SCLarge", {
	font = "AmbexHeavy",
	size = ScreenScale(30),
	weight = 400,
	antialias = true,
	scanlines = 3,
	bold = true,
})

local clr_green = Color(39,233,0,200)
function MODE:HUDPaint()
	local StartTime = zb.ROUND_START or CurTime()
	self:AddHudPaint()
	local lply = LocalPlayer()
	if StartTime + 20 > CurTime() then
		if lply:Team() == 1 and lply:Alive() then
			draw.SimpleText( string.FormattedTime(StartTime + 20 - CurTime(), "%02i:%02i:%02i"	), "ZB_SCMedium", sw * 0.5, sh * 0.95, clr_green, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			draw.SimpleText( "Press F3 to open class selection menu", "ZB_SCSmall", sw * 0.5, sh * 0.9, clr_green, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
	else
		local time = string.FormattedTime( math.max(StartTime + (zb.ROUND_TIME or 400) - CurTime(), 0), "%02i:%02i:%02i" )
		draw.SimpleText( time, "ZB_SCMedium", sw * 0.5, sh * 0.95, clr_green, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

		if not SC_OpenedClassMenu and lply:Team() == 1 then
			OpenClassMenu()
		end
	end

	if StartTime + 20 < CurTime() then return end
	if not lply:Alive() then return end

	zb.RemoveFade()
	local fade = math.Clamp(StartTime + 8 - CurTime(),0,1)
	local team_ = lply:Team()
	draw.SimpleText("ZBattle | "..(self.PrintName or "Sneaky Splinter"), "ZB_SCMediumLarge", sw * 0.5, sh * 0.1, Color(39,233,0, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	local Rolename = teams[team_].name
	local ColorRole = teams[team_].color1
	ColorRole.a = 255 * fade
	draw.SimpleText("You are "..Rolename , "ZB_SCMediumLarge", sw * 0.5, sh * 0.5, ColorRole, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	local Objective = teams[team_].objective
	local ColorObj = teams[team_].color2
	ColorObj.a = 255 * fade
	draw.SimpleText( Objective, "ZB_SCSmall", sw * 0.5, sh * 0.85, ColorObj, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

function MODE:AddHudPaint()
end

local wave = Material( "gui/gradient_up", "noclamp smooth" )
local UpVector = Vector(0, 0, 82)
function MODE:PostDrawTranslucentRenderables(bDepth, bSkybox, isDraw3DSkybox)
	local lply, points = LocalPlayer(), zb.ClPoints["SC_ESCAPE"]

	for k, v in ipairs(points or {}) do
		local angle = (v.pos - lply:GetPos()):Angle()

		angle = Angle(0, angle.y, 0)

		angle:RotateAroundAxis(angle:Up(), -90)
		angle:RotateAroundAxis(angle:Forward(), 90)

		cam.Start3D2D(v.pos + UpVector, angle, 0.05)
			draw.SimpleText("[CASE ESCAPE POINT]", "ZB_SCLarge", 10, 10, color_black, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			draw.SimpleText("[CASE ESCAPE POINT]", "ZB_SCLarge", 0, 0, clr_green, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

			surface.SetMaterial(wave)
			surface.SetDrawColor(color_green_darker)
			surface.DrawTexturedRect(-1500, 600, 3024, 1024)
		cam.End3D2D()
	end
end

local CreateEndMenu

net.Receive("sc_roundend",function()
	CreateEndMenu()
end)

local colGray = Color(85,85,85,255)
local colRed = Color(29,177,0)
local colRedUp = Color(6,168,0)

local col = Color(255,255,255,255)
local colSpect1 = Color(75,75,75,255)
local colSpect2 = Color(255,255,255)

local blurMat = Material("pp/blurscreen")
local Dynamic = 0

BlurBackground = BlurBackground or hg.DrawBlur

if IsValid(hmcdEndMenu) then
	hmcdEndMenu:Remove()
	hmcdEndMenu = nil
end

CreateEndMenu = function()
	if IsValid(hmcdEndMenu) then
		hmcdEndMenu:Remove()
		hmcdEndMenu = nil
	end
	Dynamic = 0
	hmcdEndMenu = vgui.Create("ZFrame")

	surface.PlaySound("sc_roundend.mp3")

	local sizeX,sizeY = ScrW() / 2.5 ,ScrH() / 1.2
	local posX,posY = ScrW() / 1.3 - sizeX / 2,ScrH() / 2 - sizeY / 2

	hmcdEndMenu:SetPos(posX,posY)
	hmcdEndMenu:SetSize(sizeX,sizeY)
	--hmcdEndMenu:SetBackgroundColor(colGray)
	hmcdEndMenu:MakePopup()
	hmcdEndMenu:SetKeyboardInputEnabled(false)
	hmcdEndMenu:ShowCloseButton(false)

	local closebutton = vgui.Create("DButton",hmcdEndMenu)
	closebutton:SetPos(5,5)
	closebutton:SetSize(ScrW() / 20,ScrH() / 30)
	closebutton:SetText("")
	
	closebutton.DoClick = function()
		if IsValid(hmcdEndMenu) then
			hmcdEndMenu:Close()
			hmcdEndMenu = nil
		end
	end

	closebutton.Paint = function(self,w,h)
		surface.SetDrawColor( 122, 122, 122, 255)
		surface.DrawOutlinedRect( 0, 0, w, h, 2.5 )
		surface.SetFont( "ZB_InterfaceMedium" )
		surface.SetTextColor(col.r,col.g,col.b,col.a)
		local lenghtX, lenghtY = surface.GetTextSize("Close")
		surface.SetTextPos( lenghtX - lenghtX/1.1, 4)
		surface.DrawText("Close")
	end

	hmcdEndMenu.Paint = function(self,w,h)
		BlurBackground(self)

		surface.SetFont( "ZB_InterfaceMediumLarge" )
		surface.SetTextColor(col.r,col.g,col.b,col.a)
		local lenghtX, lenghtY = surface.GetTextSize("Players:")
		surface.SetTextPos(w / 2 - lenghtX/2,20)
		surface.DrawText("Players:")

		surface.SetDrawColor( 60, 255, 0, 128)
		surface.DrawOutlinedRect( 0, 0, w, h, 2.5 )
	end
	-- PLAYERS
	local DScrollPanel = vgui.Create("DScrollPanel", hmcdEndMenu)
	DScrollPanel:SetPos(10, 80)
	DScrollPanel:SetSize(sizeX - 20, sizeY - 90)
	function DScrollPanel:Paint( w, h )
		BlurBackground(self)

		surface.SetDrawColor( 0, 255, 13, 128)
		surface.DrawOutlinedRect( 0, 0, w, h, 2.5 )
	end

	for i,ply in ipairs(player.GetAll()) do
		if ply:Team() == TEAM_SPECTATOR then continue end
		local but = vgui.Create("DButton",DScrollPanel)
		but:SetSize(100,50)
		but:Dock(TOP)
		but:DockMargin( 8, 6, 8, -1 )
		but:SetText("")
		but.Paint = function(self,w,h)
			local col1 = (ply:Alive() and colRed) or colGray
			local col2 = (ply:Alive() and colRedUp) or colSpect1
			surface.SetDrawColor(col1.r,col1.g,col1.b,col1.a)
			surface.DrawRect(0,0,w,h)
			surface.SetDrawColor(col2.r,col2.g,col2.b,col2.a)
			surface.DrawRect(0,h/2,w,h/2)

			local col = ply:GetPlayerColor():ToColor()
			surface.SetFont( "ZB_InterfaceMediumLarge" )
			local lenghtX, lenghtY = surface.GetTextSize( ply:GetPlayerName() or "He quited..." )
			
			surface.SetTextColor(0,0,0,255)
			surface.SetTextPos(w / 2 + 1,h/2 - lenghtY/2 + 1)
			surface.DrawText(ply:GetPlayerName() or "He quited...")

			surface.SetTextColor(col.r,col.g,col.b,col.a)
			surface.SetTextPos(w / 2,h/2 - lenghtY/2)
			surface.DrawText(ply:GetPlayerName() or "He quited...")

			
			local col = colSpect2
			surface.SetFont( "ZB_InterfaceMediumLarge" )
			surface.SetTextColor(col.r,col.g,col.b,col.a)
			local lenghtX, lenghtY = surface.GetTextSize( ply:GetPlayerName() or "He quited..." )
			surface.SetTextPos(15,h/2 - lenghtY/2)
			surface.DrawText((ply:Name() .. (not ply:Alive() and " - died" or "")) or "He quited...")

			surface.SetFont( "ZB_InterfaceMediumLarge" )
			surface.SetTextColor(col.r,col.g,col.b,col.a)
			local lenghtX, lenghtY = surface.GetTextSize( ply:Frags() or "He quited..." )
			surface.SetTextPos(w - lenghtX -15,h/2 - lenghtY/2)
			surface.DrawText(ply:Frags() or "He quited...")
		end

		function but:DoClick()
			if ply:IsBot() then chat.AddText(Color(255,0,0), "no, you can't") return end
			gui.OpenURL("https://steamcommunity.com/profiles/"..ply:SteamID64())
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
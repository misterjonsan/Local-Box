local MODE = MODE

local blurMat = Material("pp/blurscreen")
local Dynamic = 0

BlurBackground = BlurBackground or hg.DrawBlur

local function PaintFrame(self,w,h)
	BlurBackground(self)

	surface.SetDrawColor( 72, 255, 0, 128)
	surface.DrawOutlinedRect( 0, 0, w, h, 2.5 )
end

local function PaintPanel(self,w,h)
	surface.SetDrawColor( 0, 0, 0,155)
	surface.DrawRect( 0, 0, w, h, 2.5 )
	surface.SetDrawColor( 9, 255, 0, 128)
	surface.DrawOutlinedRect( 0, 0, w, h, 2.5 )
end

local gradient_l = Material("vgui/gradient-l")

local function PaintPanel1(self,w,h)
	surface.SetDrawColor(0, 0, 0,155)
	surface.DrawRect(0, 0, w, h, 2.5)
	surface.SetDrawColor(21, 255, 0, 128)
	surface.DrawOutlinedRect(0, 0, w, h, 2.5)
	draw.RoundedBox(0, 2.5, 2.5, w-5, h-5, Color(0, 0, 0, 140))
	surface.SetDrawColor(13, 155, 0, 55)
	surface.SetMaterial(gradient_l)
	surface.DrawTexturedRect(0, 0, w / 1.5, h)
end

local rtabFunc = function(self)
	local ExtraInset = 10

	if ( self.Image ) then
		ExtraInset = ExtraInset + self.Image:GetWide()
	end

	self:SetTextInset( ExtraInset, 2 )
	local w, h = self:GetContentSize()
	h = self:GetTabHeight()

	self:SetSize( w + 10, h + 7 )

	DLabel.ApplySchemeSettings( self )
end

function OpenClassMenu()
	if SC_OpenedClassMenu then
		SC_OpenedClassMenu:Remove()
		SC_OpenedClassMenu = nil
	end
	local StartTime = zb.ROUND_START or CurTime()
	local lply = LocalPlayer()
	if not lply:Alive() or StartTime + MODE.BuyTime < CurTime() or not lply:GetNWBool("sc-canselect", true) then return end
	SC_OpenedClassMenu = vgui.Create("ZFrame")
	local Frame = SC_OpenedClassMenu
	Frame:SetSize(1920*0.35,ScrH()*0.85)
	Frame:Center()
	Frame:MakePopup()
	Frame:SetTitle("")
	Frame.Paint = PaintFrame

	local Sheet = vgui.Create( "DPropertySheet", Frame )
	Sheet:Dock( FILL )
	Sheet:SetTextInset(50)
	Sheet.Paint = function() end
	Sheet.tabScroller:SetOverlap( 0 )
	Sheet.tabScroller:DockMargin( 8, 0, 8, 0 )
	Sheet:SetFadeTime(0.1)

	for n,Item in pairs(MODE.BuySets) do
		local ItemPanel = vgui.Create("DPanel",Sheet)
		ItemPanel:SetSize(0,ScrH()*0.1)
		ItemPanel:Dock(TOP)
		ItemPanel:DockMargin(0,5,0,0)
		ItemPanel.Paint = PaintPanel1

		local ItemButton = vgui.Create("DPanel",ItemPanel)
		ItemButton:Dock(FILL)
		ItemButton:DockMargin(0,5,0,0)
		ItemButton.Paint = function() end

		local lbl = vgui.Create("DLabel", ItemButton)
		lbl:SetText(n)
		lbl:DockMargin(10,0,5,0)
		lbl:Dock(TOP)
		lbl:SetFont("ZB_SCSmall")
		lbl:SetSize(ScrW()*0.5,ScrH()*0.04)

		local BuyBtn = vgui.Create("DButton", ItemButton)
		BuyBtn:DockMargin(10,5,10,10)
		BuyBtn:Dock(LEFT)
		BuyBtn:SetText("Select")
		BuyBtn:SetTextColor(Color(200,200,200))
		BuyBtn:SetFont("ZB_SCSmall")
		BuyBtn:SetSize(ScrW()*0.11,ScrH()*0.025)
		BuyBtn.Paint = PaintPanel
		BuyBtn.Item = {Item.ItemTable,n}
		BuyBtn.ArmorItem = {Item.ArmorTable,n}

		function BuyBtn:DoClick()
			net.Start("sc_buyitem")
				net.WriteTable(self.Item)
				net.WriteTable(self.ArmorItem)
			net.SendToServer()
		end
	end

	local StartTime = zb.ROUND_START or CurTime()
	local lbl = vgui.Create("DLabel", Frame)
	lbl:SetText("Time Left: "..string.FormattedTime(StartTime + 40 - CurTime(), "%02i:%02i:%02i"))
	lbl:DockMargin(10,0,10,10)
	lbl:Dock(BOTTOM)
	lbl:SetTextColor(Color(255,255,255))
	lbl:SetFont("ZB_SCSmall")
	lbl:SetSize(0,ScrH()*0.015)

	function lbl:Think()
		if not lply:Alive() or StartTime + MODE.BuyTime < CurTime() or not lply:GetNWBool("sc-canselect", true) then
			SC_OpenedClassMenu:Remove()
		end
		self:SetText("Time Left: "..string.FormattedTime(StartTime + 40 - CurTime(), "%02i:%02i:%02i"))
	end

	local lbl = vgui.Create("DLabel", Frame)
	lbl:SetText("Select Class")
	lbl:DockMargin(10,1,10,1)
	lbl:Dock(TOP)
	lbl:SetTextColor(Color(61,173,61))
	lbl:SetFont("ZB_SCSmall")
	lbl:SetSize(0,ScrH() * 0.02)

	function lbl:Think()
	end
end

net.Receive("sc_open_classmenu",function() OpenClassMenu() end)
SC_OpenedClassMenu = SC_OpenedClassMenu or nil
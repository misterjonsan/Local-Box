zb = zb or {}
include("shared.lua")
include("loader.lua")

if not ConVarExists("hg_newspectate") then
    CreateClientConVar("hg_newspectate", "1", true, false, "Enables smooth spectator camera transitions", 0, 1)
end

-- ==========================================
-- СИСТЕМА АНИМИРОВАННЫХ РАМОК STEAM (URL + DHTML)
-- ==========================================
if CLIENT then
    ZB_SteamFrames = ZB_SteamFrames or {}
    ZB_SteamFrames.Cache = {}

    function ZB_SteamFrames.GetFrameURL(ply, callback)
        if not IsValid(ply) then return end
        if ply:IsBot() then return end
        
        local steamid64 = ply:SteamID64()
        
        -- Если уже есть в кэше, возвращаем сразу
        if ZB_SteamFrames.Cache[steamid64] ~= nil then
            if callback then callback(ZB_SteamFrames.Cache[steamid64]) end
            return
        end

        -- Временно ставим false, чтобы не спамить запросами
        ZB_SteamFrames.Cache[steamid64] = false 

        local url = "https://steamcommunity.com/profiles/" .. steamid64

        http.Fetch(url,
            function(body)
                -- Ищем ссылку на рамку в HTML профиля
                local frameURL = string.match(body, [[<div class="profile_avatar_frame".-src="(.-)"]])

                if frameURL then
                    ZB_SteamFrames.Cache[steamid64] = frameURL
                    if callback then callback(frameURL) end
                else
                    ZB_SteamFrames.Cache[steamid64] = false 
                    if callback then callback(false) end
                end
            end,
            function(err) 
                ZB_SteamFrames.Cache[steamid64] = false 
            end
        )
    end
end
-- ==========================================

function CurrentRound()
	return zb.modes[zb.CROUND]
end

zb.ROUND_STATE = 0
local vecZero = Vector(0.2, 0.2, 0.2)
local vecFull = Vector(1, 1, 1)
spect,prevspect,viewmode = nil,nil,1
local hullscale = Vector(0,0,0)
net.Receive("ZB_SpectatePlayer", function(len)
	spect = net.ReadEntity()
	prevspect = net.ReadEntity()
	viewmode = net.ReadInt(4)

	timer.Simple(0.1,function()
		LocalPlayer():BoneScaleChange()
		LocalPlayer():SetHull(-hullscale,hullscale)
		LocalPlayer():SetHullDuck(-hullscale,hullscale)

		if viewmode == 3 then
			LocalPlayer():SetMoveType(MOVETYPE_NOCLIP)
		end
	end)
end)

zb.ROUND_TIME = zb.ROUND_TIME or 400
zb.ROUND_START = zb.ROUND_START or CurTime()
zb.ROUND_BEGIN = zb.ROUND_BEGIN or CurTime() + 5

net.Receive("updtime",function()
	local time = net.ReadFloat()
	local time2 = net.ReadFloat()
	local time3 = net.ReadFloat()

	zb.ROUND_TIME = time
	zb.ROUND_START = time2
	zb.ROUND_BEGIN = time3
end)

local blur = Material("pp/blurscreen")
local hg_potatopc
hg = hg or {}
function hg.DrawBlur(panel, amount, passes, alpha)
	if is3d2d then return end
	amount = amount or 5
	hg_potatopc = hg_potatopc or hg.ConVars.potatopc

	if(hg_potatopc:GetBool())then
		surface.SetDrawColor(0, 0, 0, alpha or (amount * 20))
		surface.DrawRect(0, 0, panel:GetWide(), panel:GetTall())
	else
		surface.SetMaterial(blur)
		surface.SetDrawColor(0, 0, 0, alpha or 125)
		surface.DrawRect(0, 0, panel:GetWide(), panel:GetTall())
		local x, y = panel:LocalToScreen(0, 0)
        
        for i = -(passes or 0.2), 1, 0.2 do
			blur:SetFloat("$blur", i * amount)
			blur:Recompute()
			render.UpdateScreenEffectTexture()
			surface.DrawTexturedRect(x * -1, y * -1, ScrW(), ScrH())
		end
	end
end

BlurBackground = BlurBackground or hg.DrawBlur

local keydownattack
local keydownattack2
local keydownreload

hook.Add("HUDPaint","FUCKINGSAMENAMEUSEDINHOOKFUCKME",function()
    if LocalPlayer():Alive() then return end
	local spect = LocalPlayer():GetNWEntity("spect")
	if not IsValid(spect) then return end
	if viewmode == 3 then return end
	
	surface.SetFont("HomigradFont")
	surface.SetTextColor(255, 255, 255, 255)
	local txt = "Spectating player: "..spect:Name()
	local w, h = surface.GetTextSize(txt)
	surface.SetTextPos(ScrW() / 2 - w / 2, ScrH() / 8 * 7)
	surface.DrawText(txt)
	local txt = "In-game name: "..spect:GetPlayerName()
	local w, h = surface.GetTextSize(txt)
	surface.SetTextPos(ScrW() / 2 - w / 2, ScrH() / 8 * 7 + h)
	surface.DrawText(txt)
end)

hook.Add("HG_CalcView", "zzzzzzzUwU", function(ply, pos, angles, fov)
	if not lply:Alive() then
		if lply:KeyDown(IN_ATTACK) then
			if not keydownattack then
				keydownattack = true
				net.Start("ZB_ChooseSpecPly")
				net.WriteInt(IN_ATTACK,32)
				net.SendToServer()
			end
		else
			keydownattack = false
		end

		if lply:KeyDown(IN_ATTACK2) then
			if not keydownattack2 then
				keydownattack2 = true
				net.Start("ZB_ChooseSpecPly")
				net.WriteInt(IN_ATTACK2,32)
				net.SendToServer()
			end
		else
			keydownattack2 = false
		end

		if lply:KeyDown(IN_RELOAD) then
			if not keydownreload then
				keydownreload = true
				net.Start("ZB_ChooseSpecPly")
				net.WriteInt(IN_RELOAD,32)
				net.SendToServer()
			end
		else
			keydownreload = false
		end

		local spect = lply:GetNWEntity("spect",spect)
		if not IsValid(spect) then return end

		local viewmode = lply:GetNWInt("viewmode",viewmode)
		
		if viewmode == 3 then
			if lply:GetMoveType()!=MOVETYPE_NOCLIP then
				lply:SetMoveType(MOVETYPE_NOCLIP)
			end
			lply:SetObserverMode(OBS_MODE_ROAMING)
			return
		else
			lply:SetPos(spect:GetPos())
		end
		
		local ent = hg.GetCurrentCharacter(spect)
		if not IsValid(ent) then return end
		
		local headBone = ent:LookupBone("ValveBiped.Bip01_Head1") or ent:LookupBone("ValveBiped.Bip01_Spine1") or 1
		local bon = ent:GetBoneMatrix(headBone)
		
		if not bon then 
			local eyePos = ent:EyePos()
			if eyePos and eyePos ~= vector_origin then
				pos = eyePos
				ang = ent:EyeAngles()
			else
				pos = ent:GetPos() + Vector(0, 0, 64)
				ang = ent:GetAngles()
			end
		else
			pos, ang = bon:GetTranslation(), bon:GetAngles()
		end

		local eyePos, eyeAng = lply:EyePos(), lply:EyeAngles()
		
		local tr = {}
		tr.start = pos
		tr.endpos = pos + eyeAng:Forward() * -120
		tr.filter = {ent, lply, spect}
		tr.mins = Vector(-4, -4, -4)
		tr.maxs = Vector(4, 4, 4)
		tr = util.TraceHull(tr)

		if viewmode == 2 then
			pos = tr.HitPos + eyeAng:Forward() * 8
			ang = eyeAng
		elseif viewmode == 1 then
			if ent ~= spect and IsValid(ent) then
				local eyeAtt = ent:GetAttachment(ent:LookupAttachment("eyes"))
				if eyeAtt then
					ang = eyeAtt.Ang
				else
					ang = spect:EyeAngles()
				end
			else
				ang = spect:EyeAngles()
			end
			pos = pos + spect:EyeAngles():Forward() * 8
		else
			pos = eyePos
			ang = eyeAng
		end
		
		ang[3] = 0
		
		local view
		local hg_newspectate = GetConVar("hg_newspectate")
		if hg_newspectate and hg_newspectate:GetBool() then
			if not lply.spectLastPos then
				lply.spectLastPos = pos
				lply.spectLastAng = ang
			end
			
			local lerpFactor = FrameTime() * 10
			lply.spectLastPos = LerpVector(lerpFactor, lply.spectLastPos, pos)
			lply.spectLastAng = LerpAngle(lerpFactor, lply.spectLastAng, ang)

			view = {
				origin = lply.spectLastPos,
				angles = lply.spectLastAng,
				fov = fov,
			}
		else
			view = {
				origin = pos,
				angles = ang,
				fov = fov,
			}
		end

		return view
	else
		lply.spectLastPos = nil
		lply.spectLastAng = nil
		lply:SetObserverMode(OBS_MODE_NONE)
	end
end)

zb.fade = zb.fade or 0

hook.Add("RenderScreenspaceEffects", "huyhuyUwU", function()
	if zb.fade > 0 then
		zb.fade = math.Approach(zb.fade, 0, FrameTime() * 1)

		surface.SetDrawColor(0, 0, 0, 255 * math.min(zb.fade, 1))
		surface.DrawRect(-1, -1, ScrW() + 1, ScrH() + 1 )
	end
end)

zb.ROUND_STATE = 0
net.Receive("RoundInfo", function()
	local rnd = net.ReadString()
	hook.Run("RoundInfoCalled", rnd)

	if zb.CROUND ~= rnd then
		if hg.DynaMusic then hg.DynaMusic:Stop() end
	end

	zb.CROUND = rnd
	zb.ROUND_STATE = net.ReadInt(4)
	
	if zb.ROUND_STATE == 0 then zb.fade = 7 end

	if zb.CROUND ~= "" then
		if CurrentRound() then
			if zb.ROUND_STATE == 3 then
				if CurrentRound().EndRound then CurrentRound():EndRound() end
			elseif zb.ROUND_STATE == 1 then
				if CurrentRound().RoundStart then CurrentRound():RoundStart() end
			end
		end
	end
end)

if IsValid(scoreBoardMenu) then
	scoreBoardMenu:Remove()
	scoreBoardMenu = nil
end

hook.Add("Player Disconnected","retrymenu",function(data)
	if IsValid(scoreBoardMenu) then
		scoreBoardMenu:Remove()
		scoreBoardMenu = nil
	end
end)

local hg_font = ConVarExists("hg_font") and GetConVar("hg_font") or CreateClientConVar("hg_font", "Bahnschrift", true, false, "change every text font")
local font = function()
    local usefont = "Bahnschrift"
    if hg_font:GetString() != "" then usefont = hg_font:GetString() end
    return usefont
end

surface.CreateFont("ZB_InterfaceSmall", { font = font(), size = ScreenScale(6), weight = 400, antialias = true })
surface.CreateFont("ZB_InterfaceMedium", { font = font(), size = ScreenScale(10), weight = 400, antialias = true })
surface.CreateFont("ZB_ScrappersMedium", { font = font(), size = ScreenScale(10), weight = 400, antialias = true })
surface.CreateFont("ZB_InterfaceMediumLarge", { font = font(), size = 35, weight = 400, antialias = true })
surface.CreateFont("ZB_InterfaceLarge", { font = font(), size = ScreenScale(20), weight = 400, antialias = true })
surface.CreateFont("ZB_InterfaceHumongous", { font = font(), size = 200, weight = 400, antialias = true })

hg.playerInfo = hg.playerInfo or {}

local function addToPlayerInfo(ply, muted, volume)
	hg.playerInfo[ply:SteamID()] = {muted and true or false, volume}
	local json = util.TableToJSON(hg.playerInfo)
	file.Write("zcity_muted.txt", json)
end

gameevent.Listen("player_connect")
hook.Add("player_connect", "zcityhuy", function(data)
	if hg.playerInfo and hg.playerInfo[data.networkid] then
		Player(data.userid):SetMuted(hg.playerInfo[data.networkid][1])
		Player(data.userid):SetVoiceVolumeScale(hg.playerInfo[data.networkid][2])
	end
end)

hook.Add("InitPostEntity", "higgershuy", function()
	if file.Exists("zcity_muted.txt", "DATA") then
		local json = file.Read("zcity_muted.txt", "DATA")
		if json then hg.playerInfo = util.JSONToTable(json) end

		local plrs = player.GetAll()
		if hg.playerInfo then
			for i, ply in ipairs(plrs) do
				if not istable(hg.playerInfo[ply:SteamID()]) then
					local muted = hg.playerInfo[ply:SteamID()]
					hg.playerInfo[ply:SteamID()] = {}
					hg.playerInfo[ply:SteamID()][1] = muted
					hg.playerInfo[ply:SteamID()][2] = 1
				end
				if hg.playerInfo[ply:SteamID()] then
					ply:SetMuted(hg.playerInfo[ply:SteamID()][1])
					ply:SetVoiceVolumeScale(hg.playerInfo[ply:SteamID()][2])
				end
			end	
		end
	end
end)

local col = Color(255,255,255,255)
local colSpect1 = Color(75,75,75,255)
local colSpect2 = Color(85,85,85,255)

hg.muteall = false
hg.mutespect = false

local function OpenPlayerSoundSettings(selfa, ply)
	local Menu = DermaMenu()
	if not hg.playerInfo[ply:SteamID()] or not istable(hg.playerInfo[ply:SteamID()]) then addToPlayerInfo(ply, false, 1) end

	local mute = Menu:AddOption( "Mute", function(self)
		if hg.muteall || hg.mutespect then return end
		self:SetChecked(not ply:IsMuted())
		ply:SetMuted( not ply:IsMuted() )
		selfa:SetImage(not ply:IsMuted() && "icon16/sound.png" || "icon16/sound_mute.png")
		addToPlayerInfo(ply, ply:IsMuted(), hg.playerInfo[ply:SteamID()][2])
	end )

	mute:SetIsCheckable( true )
	mute:SetChecked( ply:IsMuted() )
	local volumeSlider = vgui.Create("DSlider", Menu)
	volumeSlider:SetLockY( 0.5 )
	volumeSlider:SetTrapInside( true )
	volumeSlider:SetSlideX(hg.playerInfo[ply:SteamID()][2]) 
	volumeSlider.OnValueChanged = function(self, x, y)
		if not IsValid(ply) then return end
		if hg.muteall or (hg.mutespect && !ply:Alive()) then return end
		hg.playerInfo[ply:SteamID()][2] = x
		ply:SetVoiceVolumeScale(hg.playerInfo[ply:SteamID()][2])
		addToPlayerInfo(ply, ply:IsMuted(), hg.playerInfo[ply:SteamID()][2])
	end

	function volumeSlider:Paint(w,h)
		draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0 ) )
		draw.RoundedBox( 0, 0, 0, w*self:GetSlideX(), h, Color( 255, 0, 0 ) )
		draw.DrawText( ( math.Round( 100*self:GetSlideX(), 0 ) ).."%", "DermaDefault", w/2, h/4, color_white, TEXT_ALIGN_CENTER )
	end
	function volumeSlider.Knob.Paint(self) end

	Menu:AddPanel(volumeSlider)
	Menu:Open()
end

hook.Add("Player Getup", "nomorespect", function(ply)
	if not hg.mutespect then return end
	ply:SetVoiceVolumeScale(!hg.muteall and (hg.playerInfo[ply:SteamID()] and hg.playerInfo[ply:SteamID()][2] or 1) or 0)
end)

hook.Add("Player_Death", "fixSpectatorVoiceMute", function(ply)
	if not hg.mutespect then return end
	ply:SetVoiceVolumeScale(0)
end)

function GM:ScoreboardShow()
	if IsValid(scoreBoardMenu) then
		scoreBoardMenu:Remove()
		scoreBoardMenu = nil
	end
	Dynamic = 0
	scoreBoardMenu = vgui.Create("ZFrame")

	local sizeX,sizeY = ScrW() / 1.3 ,ScrH() / 1.2
	local posX,posY = ScrW() / 2 - sizeX / 2,ScrH() / 2 - sizeY / 2

	scoreBoardMenu:SetPos(posX,posY)
	scoreBoardMenu:SetSize(sizeX,sizeY)
	scoreBoardMenu:MakePopup()
	scoreBoardMenu:SetKeyboardInputEnabled( false )
	scoreBoardMenu:ShowCloseButton( false )

	local muteallbut = vgui.Create("DButton", scoreBoardMenu)
	local w, h = ScreenScale(30),ScreenScale(6)
	muteallbut:SetPos(scoreBoardMenu:GetWide()-w*2.3,scoreBoardMenu:GetTall() - h * 1.5)
	muteallbut:SetSize(w, h)
	muteallbut:SetText("Mute all")
	
	muteallbut.Paint = function(self,w,h)
		surface.SetDrawColor( 155, 155, 155, 128)
        surface.DrawOutlinedRect( 0, 0, w, h, 2.5 )
	end

	muteallbut.DoClick = function(self,w,h)
		hg.muteall = not hg.muteall
		for i,ply in ipairs(player.GetAll()) do
			if hg.muteall then
				ply:SetVoiceVolumeScale(0)
			else
				ply:SetVoiceVolumeScale((!hg.mutespect or ply:Alive()) and (hg.playerInfo[ply:SteamID()] and hg.playerInfo[ply:SteamID()][2] or 1) or 0)
			end
		end 
	end

	local mutespectbut = vgui.Create("DButton", scoreBoardMenu)
	local w, h = ScreenScale(30),ScreenScale(6)
	mutespectbut:SetPos(scoreBoardMenu:GetWide()-w*1.2,scoreBoardMenu:GetTall() - h * 1.5)
	mutespectbut:SetSize(w, h)
	mutespectbut:SetText("Mute spectators")
	
	mutespectbut.Paint = function(self,w,h)
		surface.SetDrawColor( 155, 155, 155, 128)
        surface.DrawOutlinedRect( 0, 0, w, h, 2.5 )
	end

	mutespectbut.DoClick = function(self,w,h)
		hg.mutespect = not hg.mutespect
		for i,ply in ipairs(player.GetAll()) do
			if ply:Alive() then continue end
			if hg.mutespect then
				ply:SetVoiceVolumeScale(0)
			else
				ply:SetVoiceVolumeScale(!hg.muteall and (hg.playerInfo[ply:SteamID()] and hg.playerInfo[ply:SteamID()][2] or 1) or 0)
			end
		end 
	end

	local ServerName = GetHostName() or "ZCity | Developer Server | #01"
	local tick
	scoreBoardMenu.PaintOver = function(self,w,h)
		surface.SetDrawColor( 155, 155, 155, 128)
        surface.DrawOutlinedRect( 0, 0, w, h, 2.5 )

		surface.SetFont( "ZB_InterfaceLarge" )
		surface.SetTextColor(col.r,col.g,col.b,col.a)
		local lengthX, lengthY = surface.GetTextSize(ServerName)
		surface.SetTextPos(w / 2 - lengthX/2,10)
		surface.DrawText(ServerName)

		surface.SetFont( "ZB_InterfaceSmall" )
		surface.SetTextColor(col.r,col.g,col.b,col.a*0.1)
		local txt = "Local-Box V2"
		local lengthX, lengthY = surface.GetTextSize(txt)
		surface.SetTextPos(w*0.01,h - lengthY - h*0.01)
		surface.DrawText(txt)

		surface.SetFont( "ZB_InterfaceMediumLarge" )
		surface.SetTextColor(col.r,col.g,col.b,col.a)
		
		lengthX, lengthY = surface.GetTextSize("Players:")
		surface.SetTextPos((w * 0.65) / 2 - lengthX/2, ScreenScale(25))
		surface.DrawText("Players:")

		surface.SetFont( "ZB_InterfaceMediumLarge" )
		surface.SetTextColor(col.r,col.g,col.b,col.a)
		lengthX, lengthY = surface.GetTextSize("Spectators:")
		surface.SetTextPos((w * 0.65) + (w * 0.35) / 2 - lengthX/2, ScreenScale(25))
		surface.DrawText("Spectators:")

		tick = math.Round(LerpFT(0.1,tick or 0, 1 / engine.ServerFrameTime()))
		local txt = "SV Tick: " .. tick
		local lengthX, lengthY = surface.GetTextSize(txt)
		surface.SetTextPos(w * 0.5 - lengthX/2,ScreenScale(25))
		surface.DrawText(txt)
	end
	
	if LocalPlayer():Team() ~= TEAM_SPECTATOR then
		local SPECTATE = vgui.Create("DButton",scoreBoardMenu)
		SPECTATE:SetPos(sizeX * 0.925,sizeY * 0.095)
		SPECTATE:SetSize(ScrW() / 20,ScrH() / 30)
		SPECTATE:SetText("")
		
		SPECTATE.DoClick = function()
			net.Start("ZB_SpecMode")
			net.WriteBool(true)
			net.SendToServer()
			scoreBoardMenu:Remove()
			scoreBoardMenu = nil
		end

		SPECTATE.Paint = function(self,w,h)
			surface.SetDrawColor( 155, 155, 155, 128)
			surface.DrawOutlinedRect( 0, 0, w, h, 2.5 )
			surface.SetFont( "ZB_InterfaceMedium" )
			surface.SetTextColor(col.r,col.g,col.b,col.a)
			local lengthX, lengthY = surface.GetTextSize("Join")
			surface.SetTextPos( lengthX - lengthX/2, 2)
			surface.DrawText("Join")
		end
	end

	if LocalPlayer():Team() == TEAM_SPECTATOR then
		local PLAYING = vgui.Create("DButton",scoreBoardMenu)
		PLAYING:SetPos(sizeX * 0.010,sizeY * 0.095)
		PLAYING:SetSize(ScrW() / 20,ScrH() / 30)
		PLAYING:SetText("")
		
		PLAYING.DoClick = function()
			net.Start("ZB_SpecMode")
			net.WriteBool(false)
			net.SendToServer()
			scoreBoardMenu:Remove()
			scoreBoardMenu = nil
		end

		PLAYING.Paint = function(self,w,h)
			surface.SetDrawColor( 155, 155, 155, 128)
			surface.DrawOutlinedRect( 0, 0, w, h, 2.5 )
			surface.SetFont( "ZB_InterfaceMedium" )
			surface.SetTextColor(col.r,col.g,col.b,col.a)
			local lengthX, lengthY = surface.GetTextSize("Join")
			surface.SetTextPos( lengthX - lengthX/2, 2)
			surface.DrawText("Join")
		end
	end

    -- ===========================
    -- ЛЕВАЯ ПАНЕЛЬ (ИГРОКИ)
    -- ===========================
	local DScrollPanel = vgui.Create("DScrollPanel", scoreBoardMenu)
	DScrollPanel:SetPos(10, ScreenScaleH(58))
	DScrollPanel:SetSize(sizeX * 0.65 - 10, sizeY - ScreenScaleH(72))
	function DScrollPanel:Paint( w, h )
		surface.SetDrawColor(0, 0, 0, 125)
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor( 155, 155, 155, 128)
        surface.DrawOutlinedRect( 0, 0, w, h, 2.5 )
	end

	local disappearance = lply:GetNetVar("disappearance", nil)
	for i, ply in ipairs(player.GetAll()) do
		if ply:Team() == TEAM_SPECTATOR then continue end
		if CurrentRound().name == "fear" and !ply:Alive() then continue end
		if disappearance and ply != lply then continue end

		local btnHeight = ScreenScaleH(34)
		local but = vgui.Create("DButton", DScrollPanel)
		but:SetSize(100, btnHeight)
		but:Dock(TOP)
		but:DockMargin(8, 6, 8, -1)
		but:SetText("")
		
		local soundButton = vgui.Create("DImageButton", but)
		soundButton:Dock(RIGHT)
		soundButton:SetSize( 30, 0 )
		soundButton:DockMargin(5,10,45,10)
		soundButton:SetImage(not ply:IsMuted() && "icon16/sound.png" || "icon16/sound_mute.png") 
		soundButton.DoClick = function(self) OpenPlayerSoundSettings(self, ply) end
		ply.soundButton = soundButton
		
        -- АВАТАРКА
		local avSize = btnHeight - 8 
		local Avatar = vgui.Create("AvatarImage", but)
		Avatar:SetSize(avSize, avSize)
		Avatar:SetPos(6, 4)
		Avatar:SetPlayer(ply, 64)

        -- РАМКА (DHTML)
		local Frame = vgui.Create("DHTML", but)
		local offset = avSize * 0.22 
		Frame:SetSize(avSize + offset, avSize + offset)
		Frame:SetPos(6 - (offset/2), 4 - (offset/2))
		Frame:SetMouseInputEnabled(false) 

        if ZB_SteamFrames and ZB_SteamFrames.GetFrameURL then
            ZB_SteamFrames.GetFrameURL(ply, function(url)
				if IsValid(Frame) and url then
                    Frame:SetHTML([[
                        <style>
                            body { margin: 0; padding: 0; overflow: hidden; background: transparent; }
                            img { width: 100%; height: 100%; object-fit: contain; }
                        </style>
                        <img src="]] .. url .. [[">
                    ]])
				end
			end)
        end
	
		but.Paint = function(self, w, h)
			if not IsValid(ply) then return end
			
			surface.SetDrawColor(155, 155, 155, 255)
			surface.DrawOutlinedRect(0, 0, w, h, 2)
	
			-- Имя
			surface.SetFont("ZB_InterfaceMediumLarge")
			surface.SetTextColor(col.r, col.g, col.b, col.a)
			local nameText = ply:Name() or "He quited..."
			local nameW, nameH = surface.GetTextSize(nameText)
			
			local textX = 6 + avSize + 10 
			surface.SetTextPos(textX, h / 2 - nameH / 2)
			surface.DrawText(nameText)

			-- Ранг
			if IsValid(ply) then
				local groupText = string.upper(ply:GetUserGroup())
				surface.SetFont("ZB_InterfaceMedium")
				surface.SetTextColor(139, 0, 0, 255)
				local groupW, groupH = surface.GetTextSize(groupText)
				surface.SetTextPos(textX + nameW + 10, h / 2 - groupH / 2)
				surface.DrawText(groupText)
			end
	
			-- Пинг
			surface.SetFont("ZB_InterfaceMediumLarge")
			surface.SetTextColor(col.r, col.g, col.b, col.a)
			local pingText = ply:Ping() or "He quited..."
			local pingW, pingH = surface.GetTextSize(pingText)
			surface.SetTextPos(w - pingW - 15, h / 2 - pingH / 2)
			surface.DrawText(pingText)
		end

		function but:DoClick()
			if ply:IsBot() then chat.AddText(Color(255,0,0), "no, you can't") return end
			gui.OpenURL("https://steamcommunity.com/profiles/"..ply:SteamID64())
		end

		function but:DoRightClick()
			local Menu = DermaMenu()
			Menu:AddOption( "Account", function(self) zb.Experience.AccountMenu( ply ) end)
			Menu:AddOption( "Copy SteamID", function(self) SetClipboardText(ply:SteamID()) end)
			Menu:Open()
		end
	
		DScrollPanel:AddItem(but)
	end

	-- ===========================
    -- ПРАВАЯ ПАНЕЛЬ (НАБЛЮДАТЕЛИ)
    -- ===========================
	local DScrollPanel = vgui.Create("DScrollPanel", scoreBoardMenu)
	DScrollPanel:SetPos(sizeX * 0.65 + 5, ScreenScaleH(58))
	DScrollPanel:SetSize(sizeX * 0.35 - 15, sizeY - ScreenScaleH(72))
	function DScrollPanel:Paint( w, h )
		surface.SetDrawColor(0, 0, 0, 125)
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor( 155, 155, 155, 128)
        surface.DrawOutlinedRect( 0, 0, w, h, 2.5 )
	end

	for i, ply in ipairs(player.GetAll()) do
		if ply:Team() ~= TEAM_SPECTATOR then continue end
		if CurrentRound().name == "fear" and !ply:Alive() then continue end
		if disappearance and ply != lply then continue end

		local btnHeight = ScreenScaleH(22)
		local but = vgui.Create("DButton", DScrollPanel)
		but:SetSize(100, btnHeight)
		but:Dock(TOP)
		but:DockMargin( 8, 6, 8, -1 )
		but:SetText("")

		local soundButton = vgui.Create("DImageButton", but)
		soundButton:Dock(RIGHT)
		soundButton:SetSize( 30, 0 )
		soundButton:DockMargin(5,10,45,10)
		soundButton:SetImage(not ply:IsMuted() && "icon16/sound.png" || "icon16/sound_mute.png") 
		soundButton.DoClick = function(self) OpenPlayerSoundSettings(self, ply) end
		ply.soundButton = soundButton
		
        -- АВАТАРКА СПЕКТАТОРОВ
		local avSize = btnHeight - 8 
		local Avatar = vgui.Create("AvatarImage", but)
		Avatar:SetSize(avSize, avSize)
		Avatar:SetPos(6, 4)
		Avatar:SetPlayer(ply, 64)

        -- РАМКА
		local Frame = vgui.Create("DHTML", but)
		local offset = avSize * 0.22 
		Frame:SetSize(avSize + offset, avSize + offset)
		Frame:SetPos(6 - (offset/2), 4 - (offset/2))
		Frame:SetMouseInputEnabled(false)

        if ZB_SteamFrames and ZB_SteamFrames.GetFrameURL then
            ZB_SteamFrames.GetFrameURL(ply, function(url)
				if IsValid(Frame) and url then
                    Frame:SetHTML([[
                        <style>
                            body { margin: 0; padding: 0; overflow: hidden; background: transparent; }
                            img { width: 100%; height: 100%; object-fit: contain; }
                        </style>
                        <img src="]] .. url .. [[">
                    ]])
				end
			end)
        end

		but.Paint = function(self,w,h)
			if not IsValid(ply) then return end
			surface.SetDrawColor(colSpect2.r,colSpect2.g,colSpect2.b,colSpect2.a)
			surface.DrawRect(0,0,w,h)
			surface.SetDrawColor(colSpect1.r,colSpect1.g,colSpect1.b,colSpect1.a)
			surface.DrawRect(0,h/2,w,h/2)
			
			-- Имя
			surface.SetFont( "ZB_InterfaceMediumLarge" )
			surface.SetTextColor(col.r,col.g,col.b,col.a)
			local nameText = ply:Name() or "He quited..."
			local nameW, nameH = surface.GetTextSize(nameText)
			
			local textX = 6 + avSize + 10 
			surface.SetTextPos(textX,h/2 - nameH/2)
			surface.DrawText(nameText)

			-- Пинг
			surface.SetFont( "ZB_InterfaceMediumLarge" )
			surface.SetTextColor(col.r,col.g,col.b,col.a)
			local pingText = ply:Ping() or "He quited..."
			local pingW, pingH = surface.GetTextSize(pingText)
			surface.SetTextPos(w - pingW - 15, h / 2 - pingH / 2)
			surface.DrawText(pingText)
		end

		function but:DoClick()
			if ply:IsBot() then chat.AddText("That bot.") return end
			gui.OpenURL("https://steamcommunity.com/profiles/"..ply:SteamID64())
		end

		function but:DoRightClick()
			local Menu = DermaMenu()
			Menu:AddOption( "Account", function(self) zb.Experience.AccountMenu( ply ) end)
			Menu:AddOption( "Copy SteamID", function(self) SetClipboardText(ply:SteamID()) end)
			Menu:Open()
		end

		DScrollPanel:AddItem(but)
	end

	return true
end

function GM:ScoreboardHide()
	if IsValid(scoreBoardMenu) then
		scoreBoardMenu:Close()
		scoreBoardMenu = nil
	end
end

local AdminShowVoiceChat = CreateClientConVar("zb_admin_show_voicechat","0",false,false,"Shows voicechat panles",0,1)
hook.Add("PlayerStartVoice", "asd", function(ply)
	if !IsValid(ply) then return end
	if LocalPlayer():IsAdmin() and AdminShowVoiceChat:GetBool() then return end
	local other_alive = (ply:Alive() and LocalPlayer() != ply) or (ply.organism and (ply.organism.otrub or (ply.organism.brain and ply.organism.brain > 0.05)))
	return other_alive or nil
end)

if CLIENT then
	net.Receive("PunishLightningEffect", function()
		local target = net.ReadEntity()
		if not IsValid(target) then return end
		local dlight = DynamicLight(target:EntIndex())
		if dlight then
			dlight.pos = target:GetPos()
			dlight.r = 126
			dlight.g = 139
			dlight.b = 212
			dlight.brightness = 1
			dlight.Decay = 1000
			dlight.Size = 500
			dlight.DieTime = CurTime() + 1
		end
	end)
end

local lightningMaterial = Material("sprites/lgtning")
net.Receive("AnotherLightningEffect", function()
    local target = net.ReadEntity()
	if not IsValid(target) then return end
    local points = {}
    for i = 1, 27 do
        points[i] = target:GetPos() + Vector(0, 0, i * 50) + Vector(math.Rand(-20,20),math.Rand(-20,20),math.Rand(-20,20))
    end
    hook.Add( "PreDrawTranslucentRenderables", "LightningExample", function(isDrawingDepth, isDrawingSkybox)
        if isDrawingDepth or isDrawingSkybox then return end
        local uv = math.Rand(0, 1)
        render.OverrideBlend( true, BLEND_SRC_COLOR, BLEND_SRC_ALPHA, BLENDFUNC_ADD, BLEND_ONE, BLEND_ZERO, BLENDFUNC_ADD )
        render.SetMaterial(lightningMaterial)
        render.StartBeam(27)
        for i = 1, 27 do
            render.AddBeam(points[i], 20, uv * i, Color(255,255,255,255))
        end
        render.EndBeam()
        render.OverrideBlend( false )
    end )
    timer.Simple(0.1, function()
        hook.Remove("PreDrawTranslucentRenderables", "LightningExample")
    end)
end)

function GM:AddHint( name, delay )
	return false
end

local snakeGameOpen = false
concommand.Add("zb_snake", function()
    if snakeGameOpen then
        print("[Snake Game] Игра уже запущена!")
        return
    end

    local frame = vgui.Create("ZFrame")
    frame:SetTitle("Snake Game")
    frame:SetSize(400, 400)
    frame:Center()
    frame:MakePopup()
    frame:SetDeleteOnClose(true)  
    snakeGameOpen = true  

    local gridSize = 20
    local gridWidth = 19  
    local gridHeight = 19  
    local snakePanel = vgui.Create("DPanel", frame)
    snakePanel:SetSize(380, 380)
    snakePanel:SetPos(10, 10)
    
    frame:SetDraggable(true)
    frame:ShowCloseButton(true)

    local snake = {{x = 10, y = 10}}
    local snakeDirection = "RIGHT"
    local food = nil
    local score = 0
    local gameRunning = true

    local function spawnFood()
        local validPosition = false
        while not validPosition do
            local newFood = {
                x = math.random(0, gridWidth - 1), 
                y = math.random(0, gridHeight - 1)
            }
            validPosition = true
            for _, segment in ipairs(snake) do
                if segment.x == newFood.x and segment.y == newFood.y then
                    validPosition = false  
                    break
                end
            end
            if validPosition then food = newFood end
        end
    end

    local function drawSnake()
        surface.SetDrawColor(0, 255, 0, 255)
        for _, segment in ipairs(snake) do
            surface.DrawRect(segment.x * gridSize, segment.y * gridSize, gridSize - 1, gridSize - 1)
        end
    end

    local function drawFood()
        if food then
            surface.SetDrawColor(255, 0, 0, 255)
            surface.DrawRect(food.x * gridSize, food.y * gridSize, gridSize - 1, gridSize - 1)
        end
    end

    local function moveSnake()
        if not gameRunning then return end
        local head = table.Copy(snake[1])

        if snakeDirection == "UP" then head.y = head.y - 1
        elseif snakeDirection == "DOWN" then head.y = head.y + 1
        elseif snakeDirection == "LEFT" then head.x = head.x - 1
        elseif snakeDirection == "RIGHT" then head.x = head.x + 1 end
        
        if head.x < 0 or head.x >= gridWidth or head.y < 0 or head.y >= gridHeight then
            gameRunning = false
        end

        for _, segment in ipairs(snake) do
            if segment.x == head.x and segment.y == head.y then
                gameRunning = false
            end
        end
       
        table.insert(snake, 1, head)
        if food and head.x == food.x and head.y == food.y then
            score = score + 1
            spawnFood()  
        else
            table.remove(snake)
        end
    end

    local function resetGame()
        snake = {{x = 10, y = 10}}
        snakeDirection = "RIGHT"
        score = 0
        gameRunning = true
        spawnFood()  
    end

    function snakePanel:Paint(w, h)
        surface.SetDrawColor(50, 50, 50, 255)
        surface.DrawRect(0, 0, w, h)
        if gameRunning then
            drawSnake()
            drawFood()
        else
            draw.SimpleText("Game Over! Press R to restart", "DermaDefault", w / 2, h / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        draw.SimpleText("Score: " .. score, "DermaDefault", 10, 10, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end

    function frame:OnKeyCodePressed(key) 
        if key == KEY_W and snakeDirection ~= "DOWN" then snakeDirection = "UP"
        elseif key == KEY_S and snakeDirection ~= "UP" then snakeDirection = "DOWN"
        elseif key == KEY_A and snakeDirection ~= "RIGHT" then snakeDirection = "LEFT"
        elseif key == KEY_D and snakeDirection ~= "LEFT" then snakeDirection = "RIGHT"
        elseif key == KEY_R then resetGame() end
    end

    timer.Create("SnakeGameTimer", 0.2, 0, function()
        if gameRunning then moveSnake() end
        snakePanel:InvalidateLayout(true)
    end)

    frame.OnClose = function()
        timer.Remove("SnakeGameTimer")
        snakeGameOpen = false  
        print("[Snake Game] Игра закрыта.")
    end
    resetGame()
end)

hook.Add("Player Spawn", "GuiltKnown",function(ply)
	if ply == LocalPlayer() then
		system.FlashWindow()
	end
end)

local themeAccent = Color(200, 50, 50)
local themeBG = Color(30, 30, 30, 220)
local themeText = Color(255, 255, 255, 255)
local fontName = "ZB_InterfaceMedium" 

local g_VoicePanelList
local function DrawBlur(panel, amount, passes, alpha)
    if hg and hg.DrawBlur then
        hg.DrawBlur(panel, amount, passes, alpha)
    else
        surface.SetDrawColor(0, 0, 0, 200)
        surface.DrawRect(0, 0, panel:GetWide(), panel:GetTall())
    end
end

local PANEL = {}

function PANEL:Init()
    local avSize = 32
    local padding = 6

    self.Avatar = vgui.Create("AvatarImage", self)
    self.Avatar:SetSize(avSize, avSize)
    self.Avatar:SetPos(padding, padding)

    self.LabelName = vgui.Create("DLabel", self)
    self.LabelName:SetFont(fontName)
    self.LabelName:SetPos(padding + avSize + 10, 0)
    self.LabelName:SetSize(200, 40 + (padding*2))
    self.LabelName:SetTextColor(themeText)
    self.LabelName:SetContentAlignment(4)

    self.Color = color_transparent
    self:SetSize(250, avSize + (padding * 2))
    self:Dock(BOTTOM)
    self:DockMargin(2, 2, 2, 2)
end

function PANEL:Setup(ply)
    self.ply = ply
    self.Avatar:SetPlayer(ply)
    self.LabelName:SetText(ply:Nick())
    self.Color = themeAccent 
    self:InvalidateLayout()
end

function PANEL:Paint(w, h)
    if not IsValid(self.ply) then return end
    DrawBlur(self, 3, 3, 200)
    draw.RoundedBox(0, 0, 0, w, h, themeBG)

    surface.SetDrawColor(self.Color.r, self.Color.g, self.Color.b, 20)
    local gridSize = 10
    for i = 0, w, gridSize do surface.DrawLine(i, 0, i, h) end
    for i = 0, h, gridSize do surface.DrawLine(0, i, w, i) end

    draw.RoundedBox(0, w-2, 0, 2, h, Color(self.Color.r, self.Color.g, self.Color.b, 100))

    local vol = self.ply:VoiceVolume()
    if vol > 0.01 then
        local pulseSize = vol * 50
        local pulseAlpha = 50 + (vol * 205)
        local avX, avY = 6, 6
        local avSize = 32
        draw.RoundedBox(0, avX - pulseSize, avY - pulseSize, avSize + (pulseSize * 2), avSize + (pulseSize * 2), Color(self.Color.r, self.Color.g, self.Color.b, pulseAlpha))
    end
end

function PANEL:Think()
    if IsValid(self.ply) then
        self.LabelName:SetText(self.ply:Name())
    else
        self.fadeAnim = Derma_Anim("FadeOut", self, self.FadeOut)
        self.fadeAnim:Start(0.1)
    end

    if self.fadeAnim then self.fadeAnim:Run() end
end

function PANEL:FadeOut(anim, delta, data)
    if anim.Finished then
        if IsValid(self.ply) then self.ply.VoicePanel = nil end
        self:Remove()
        return
    end
    self:SetAlpha(255 - (255 * delta))
end

vgui.Register("VoiceNotify", PANEL, "DPanel")

local function CreateVoiceVGUI()
    if IsValid(g_VoicePanelList) then g_VoicePanelList:Remove() end
    g_VoicePanelList = vgui.Create("DPanel")
    g_VoicePanelList:ParentToHUD()
    g_VoicePanelList:SetPos(ScrW() - 275, ScrH() / 2 - 200)
    g_VoicePanelList:SetSize(250, ScrH() - 200)
    g_VoicePanelList:SetPaintBackground(false)
end

hook.Add("InitPostEntity", "CreateVoiceVGUI_Hook", CreateVoiceVGUI)
if LocalPlayer():IsValid() then CreateVoiceVGUI() end

hook.Add("PlayerStartVoice", "ZCity_VoiceStart", function(ply)
    if not IsValid(g_VoicePanelList) then CreateVoiceVGUI() end
    if IsValid(ply.VoicePanel) then
        if ply.VoicePanel.fadeAnim then
            ply.VoicePanel.fadeAnim = nil
            ply.VoicePanel:SetAlpha(255)
        end
        return
    end
    local pnl = g_VoicePanelList:Add("VoiceNotify")
    pnl:Setup(ply)
    ply.VoicePanel = pnl
end)

hook.Add("PlayerEndVoice", "ZCity_VoiceStop", function(ply)
    if IsValid(ply.VoicePanel) then
        ply.VoicePanel.fadeAnim = Derma_Anim("FadeOut", ply.VoicePanel, ply.VoicePanel.FadeOut)
        ply.VoicePanel.fadeAnim:Start(0.2)
    end
end)

hook.Add("HUDShouldDraw", "BlockDefaultVoice", function(name)
    if name == "CHudVoiceStatus" or name == "CHudVoiceSelfStatus" then return false end
end)

if SERVER then return end

local matProtogen = Material("protogen_talk.png", "noclamp smooth")
local matHuman = Material("talking.png", "noclamp smooth")
local swayX = 1
local swayY = 1
local swayVelX = 0
local swayVelY = 0
local lastAngles = Angle(0, 0, 0)
local isVoiceActive = false
local alpha = 0

hook.Add("PlayerStartVoice", "ZB_TalkIconStart", function(ply)
    if ply == LocalPlayer() then isVoiceActive = true end
end)

hook.Add("PlayerEndVoice", "ZB_TalkIconStop", function(ply)
    if ply == LocalPlayer() then isVoiceActive = false end
end)

hook.Add("HUDPaint", "ZB_TalkingIconDisplay", function()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end

    local dt = FrameTime()
    local curAngles = ply:EyeAngles()
    local swayStrength = 30 
    local springStiffness = 150 
    local springDamping = 6 
    local maxSway = 150 

    local diffY = math.AngleDifference(curAngles.y, lastAngles.y)
    local diffP = math.AngleDifference(curAngles.p, lastAngles.p)

    swayVelX = swayVelX + diffY * swayStrength
    swayVelY = swayVelY - diffP * swayStrength
    local forceX = -springStiffness * swayX - springDamping * swayVelX
    local forceY = -springStiffness * swayY - springDamping * swayVelY

    swayVelX = swayVelX + forceX * dt
    swayVelY = swayVelY + forceY * dt
    swayX = swayX + swayVelX * dt
    swayY = swayY + swayVelY * dt

    swayX = math.Clamp(swayX, -maxSway, maxSway)
    swayY = math.Clamp(swayY, -maxSway, maxSway)

    lastAngles = curAngles
    local volume = ply:VoiceVolume() or 0
    local targetAlpha = isVoiceActive and 255 or 0
    alpha = Lerp(dt * 10, alpha, targetAlpha)

    if alpha < 1 then return end

    local icon = matHuman
    if ply.PlayerClassName == "furry" then icon = matProtogen end

    local shakeIntensity = volume * 50
    local shakeX = math.random(-shakeIntensity, shakeIntensity)
    local shakeY = math.random(-shakeIntensity, shakeIntensity)

    local w, h = ScrW(), ScrH()
    local iconSize = 64
    
    surface.SetDrawColor(255, 255, 255, alpha)
    surface.SetMaterial(icon)
    local x = (w / 2) - (iconSize / 2) + shakeX + swayX
    local y = h - 150 - (iconSize / 2) + shakeY + swayY
    surface.DrawTexturedRect(x, y, iconSize, iconSize)
end)

local showSpectatorESP = true
local lastToggleTime = 0
hook.Add("HUDPaint", "ZB_SpectatorWallhack", function()
    local ply = LocalPlayer()
    if ply:Alive() and ply:Team() ~= TEAM_SPECTATOR then return end
    if not showSpectatorESP then return end
    for _, v in ipairs(player.GetAll()) do
        if v == ply or not v:Alive() or v:Team() == TEAM_SPECTATOR then continue end
        local pos = v:GetPos() 
        local scrPos = pos:ToScreen()
        if not scrPos.visible then continue end
        draw.SimpleText(v:Name(), "ZB_InterfaceMedium", scrPos.x, scrPos.y, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    end
end)

hook.Add("Think", "ZB_SpectatorESPToggle", function()
    if input.IsKeyDown(KEY_LALT) then
        if CurTime() > lastToggleTime then
            showSpectatorESP = not showSpectatorESP
            lastToggleTime = CurTime() + 0.3 
        end
    end
end)

if CLIENT then
	surface.CreateFont("LocalBoxFont", {
		font = "IBM Plex Mono",
		size = 24,
		weight = 600,
		antialias = true,
		shadow = true,
	})

	hook.Add("HUDPaint", "DrawLocalBoxWatermark", function()
		local text1 = "Local"
		local text2 = "-Box"
		local font = "LocalBoxFont"
		local margin = 15 

		surface.SetFont(font)
		local w1, h = surface.GetTextSize(text1)
		local w2, _ = surface.GetTextSize(text2)
		local totalW = w1 + w2

		local x = ScrW() - totalW - margin
		local y = margin

		surface.SetTextColor(255, 0, 0, 255)
		surface.SetTextPos(x, y)
		surface.DrawText(text1)

		surface.SetTextColor(255, 255, 255, 255)
		surface.SetTextPos(x + w1, y)
		surface.DrawText(text2)
	end)
end
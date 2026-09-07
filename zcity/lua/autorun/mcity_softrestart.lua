if SERVER then
    util.AddNetworkString("mcity_softrestart")
    util.AddNetworkString("mcity_announce")

    concommand.Add("mcity_announce", function(ply, cmd, args)
        if IsValid(ply) and not ply:IsSuperAdmin() then return end
        
        local msg = table.concat(args, " ")
        if #msg == 0 then return end
        
        net.Start("mcity_announce")
        net.WriteString(msg)
        net.Broadcast()
    end)

    concommand.Add("mcity_softrestart", function(ply, cmd, args)
        if IsValid(ply) and not ply:IsSuperAdmin() then return end
        
        net.Start("mcity_softrestart")
        net.Broadcast()
        
        print("[mcity] Soft restart triggered. Restarting map in 10 seconds...")
        
        timer.Simple(10, function()
            RunConsoleCommand("changelevel", game.GetMap())
        end)
    end)
end

if CLIENT then
    local orange = Color(255,115,0)
    local black = Color(10,10,10)
    
    surface.CreateFont("MC_TypewriterLarge",{font="Courier New",size=42,weight=700})
    surface.CreateFont("MC_Typewriter",{font="Courier New",size=24,weight=700})
    
    local grad = Material("vgui/gradient-d")
    local codePool = {
        "hg = hg or {}",
        "hg.Apperance = hg.Apperance or {}",
        "util.AddNetworkString(\"GetAppearance\")",
        "util.AddNetworkString(\"Get_Appearance\")",
        "net.Receive(\"Get_Appearance\", function(len, ply) end)",
        "local ap = GetAppearance(LocalPlayer())",
        "SetAppearance(LocalPlayer(), ap)",
        "GetRandomAppearance(LocalPlayer())",
        "ply:SetModel(ap.Model)",
        "ply:SetNWString('PlayerName', ap.Name)",
        "ply:SetNWVector('PlayerColor', Vector(ap.Color.r/255, ap.Color.g/255, ap.Color.b/255))",
        "ply:SetSubMaterial(hg.Apperance.SubMaterials[string.lower(ap.Model)], ap.ClothesStyle)",
        "ply:SetNetVar('Accessories', ap.Attachmets)",
        "RenderAccessories(ent, ent:GetNetVar('Accessories'))",
        "DrawAccesories(ent, ent, k, hg.Accessories[k])",
        "ThatPlyIsFemale(ent)",
        "hg.Apperance.PlayerModels[ap.Gender]",
        "hg.Apperance.ClothesStyles['normal'][ap.Gender]",
        "hg.Apperance.ZCityTops['Normal']",
        "hg.Apperance.ZCityPants['Normal']",
        "hook.Add('PlayerSpawn','RequestAppearanceOnSpawn',function(p) end)",
        "concommand.Add('hg_appearance_menu', function() end)",
    }
    
    local codeFlow
    local isRestarting = false
    local restartStartTime = 0
    
    -- Announcement Variables
    local announceMsg = nil
    local announceStart = 0
    local announceScroll = 0
    local announceSpeed = 120
    
    net.Receive("mcity_softrestart", function()
        isRestarting = true
        restartStartTime = CurTime()
    end)
    
    net.Receive("mcity_announce", function()
        announceMsg = net.ReadString()
        announceStart = CurTime()
        announceScroll = ScrW()
    end)
    
    local function drawKioskBackground(w,h,frac)
        local t = CurTime()
        
        -- Background
        surface.SetDrawColor(black.r, black.g, black.b, 255 * frac)
        surface.DrawRect(0,0,w,h)
        
        -- Grid
        local grid = 64
        local ox = (t*30)%grid
        local oy = (t*18)%grid
        local af = math.Clamp(frac or 0,0,1)
        
        surface.SetDrawColor(255,255,255,math.floor(18*af))
        for x=-grid,w+grid,grid do
            surface.DrawRect(x-ox,0,1,h)
        end
        for y=-grid,h+grid,grid do
            surface.DrawRect(0,y-oy,w,1)
        end
        
        -- Code Flow
        if not codeFlow or codeFlow.w ~= w or codeFlow.h ~= h then
            codeFlow = {w=w,h=h,lines={}}
            local rows = 8
            for i=1,rows do
                local text = codePool[(i-1)%#codePool+1]
                local dir = (i%2==0) and 1 or -1
                local y = math.floor(h*(0.15 + 0.06*i))
                table.insert(codeFlow.lines,{text=text,dir=dir,y=y,x=(dir==1) and -400 or w+400,speed=60+15*i,char=0,rate=32+6*i})
            end
        end
        
        surface.SetFont("MC_Typewriter")
        for i=1,#codeFlow.lines do
            local L = codeFlow.lines[i]
            L.char = math.min(#L.text, L.char + FrameTime()*L.rate)
            local disp = string.sub(L.text,1, math.floor(L.char))
            local tw, th = surface.GetTextSize(disp)
            L.x = L.x + L.dir * L.speed * FrameTime()
            if L.dir == 1 and L.x > w then L.x = -tw end
            if L.dir == -1 and L.x + tw < 0 then L.x = w end
            local a = math.floor(120*af)
            surface.SetTextColor(orange.r, orange.g, orange.b, a)
            surface.SetTextPos(L.x, L.y)
            surface.DrawText(disp)
        end
        
        -- Glow/Gradient from bottom
        local phase = (math.sin(t*1.1)*0.5 + 0.5)
        local bandH = 160 + 120 * phase
        surface.SetMaterial(grad)
        surface.SetDrawColor(orange.r, orange.g, orange.b, math.floor((28 + 32 * phase)*af))
        surface.DrawTexturedRect(0, h - bandH, w, bandH)
        surface.SetDrawColor(orange.r, orange.g, orange.b, math.floor((14 + 10 * phase)*af))
        
        for i=0,6 do
            local y = h - bandH + i * (bandH/8)
            local a = 8 + 6*math.sin(t*2 + i)
            -- Note: 'a' was unused in original code, but we keep the structure.
            surface.DrawRect(0,y,w,1)
        end
        
        -- Fade Logic from original
        surface.SetDrawColor(0,0,0,255 - math.floor(af*255))
        surface.DrawRect(0,0,w,h)
        
        -- Dim overlay from original (optional, but part of style)
        -- In original it was: surface.SetDrawColor(0,0,0,math.floor(dim.a * af))
        -- dim was Color(0,0,0,180)
        surface.SetDrawColor(0,0,0,math.floor(180 * af))
        surface.DrawRect(0,0,w,h)
        
        -- Center Text (Draw ON TOP of the overlays so it's visible)
        surface.SetFont("MC_TypewriterLarge")
        local text = "Server is restarting.."
        local tw, th = surface.GetTextSize(text)
        
        -- Text Glow/Shadow
        surface.SetTextColor(orange.r, orange.g, orange.b, 10 * af)
        for i=1,3 do
             surface.SetTextPos(w/2 - tw/2 + i, h/2 - th/2 + i)
             surface.DrawText(text)
        end
        
        surface.SetTextColor(orange.r, orange.g, orange.b, 255 * af)
        surface.SetTextPos(w/2 - tw/2, h/2 - th/2)
        surface.DrawText(text)
    end
    
    hook.Add("DrawOverlay", "mcity_softrestart_draw", function()
        if isRestarting then
            local elapsed = CurTime() - restartStartTime
            local fadeDuration = 2.0
            local frac = math.Clamp(elapsed / fadeDuration, 0, 1)
            
            drawKioskBackground(ScrW(), ScrH(), frac)
        end
        
        -- Announcement Rendering
        if announceMsg then
            local elapsed = CurTime() - announceStart
            if elapsed > 12 then -- 10s visible + 2s fade
                announceMsg = nil
                return
            end
            
            local alpha = 255
            if elapsed > 10 then
                local fade = (elapsed - 10) / 2
                alpha = 255 * (1 - fade)
            end
            
            local font = "DermaLarge" -- Using standard DermaLarge as requested
            surface.SetFont(font)
            local tw, th = surface.GetTextSize(announceMsg)
            local y = 6
            local barH = th + 12
            
            -- Pulse Effect
            local cycle = 2
            local s = (math.sin(CurTime() * math.pi * 2 / cycle) * 0.5 + 0.5)
            local g = math.floor(Lerp(s, 0, 115))
            
            surface.SetDrawColor(255, g, 0, math.floor(200 * (alpha/255)))
            surface.DrawRect(0, 0, ScrW(), barH)
            
            announceScroll = announceScroll - FrameTime() * announceSpeed
            if announceScroll + tw < 0 then announceScroll = ScrW() end
            
            surface.SetTextColor(255, 255, 255, alpha)
            surface.SetTextPos(announceScroll, y)
            surface.DrawText(announceMsg)
        end
    end)
end

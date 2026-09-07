if SERVER then return end

local LastHeartbeat = RealTime()
local CrashDetected = false
local SimulatedCrash = false
local RetryInterval = 15
local NextRetry = 0

-- Global guard for other scripts to check
CRASH_HANDLER_ACTIVE = false

-- Cookie keys for passing state between Client and Menu
local COOKIE_RETRY = "mcity_crash_retry"
local COOKIE_TIME = "mcity_crash_retry_time"

local function SetCrashState(active)
    CrashDetected = active
    CRASH_HANDLER_ACTIVE = active
    
    if not active then
        if IsValid(CrashPanel) then
            CrashPanel:Remove()
        end
    end
end

net.Receive("CrashHeartbeat", function()
    if SimulatedCrash then return end
    LastHeartbeat = RealTime()
    if CrashDetected then
        SetCrashState(false)
    end
end)

-- Font creation (matching mcity style)
surface.CreateFont("HomigradCrashFontBig", {
    font = "Bahnschrift",
    size = ScreenScale(12),
    weight = 600,
    outline = false,
    shadow = true
})

surface.CreateFont("HomigradCrashFontGigantic", {
    font = "Bahnschrift",
    size = ScreenScale(25),
    weight = 600,
    outline = false,
    shadow = false
})

local blur = Material("pp/blurscreen")
local function DrawBlur(panel, amount)
    local x, y = panel:LocalToScreen(0, 0)
    local scrW, scrH = ScrW(), ScrH()
    surface.SetDrawColor(255, 255, 255)
    surface.SetMaterial(blur)
    for i = 1, 3 do
        blur:SetFloat("$blur", (i / 3) * (amount or 6))
        blur:Recompute()
        render.UpdateScreenEffectTexture()
        surface.DrawTexturedRect(x * -1, y * -1, scrW, scrH)
    end
end

-- Forward declaration
local RequestRetry

local function CreateCrashScreen()
    if IsValid(CrashPanel) then return end

    CrashPanel = vgui.Create("DPanel")
    CrashPanel:SetSize(ScrW(), ScrH())
    CrashPanel:MakePopup()
    CrashPanel.Paint = function(s, w, h)
        DrawBlur(s, 6)
        surface.SetDrawColor(0, 0, 0, 200)
        surface.DrawRect(0, 0, w, h)
        
        draw.SimpleText("SERVER CRASHED", "HomigradCrashFontGigantic", w/2, h/2 - 100, Color(255, 50, 50), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        
        local timeleft = math.ceil(NextRetry - RealTime())
        if timeleft < 0 then timeleft = 0 end
        draw.SimpleText("Reconnecting in " .. timeleft .. " seconds...", "HomigradCrashFontBig", w/2, h/2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    local btn = vgui.Create("DButton", CrashPanel)
    btn:SetText("Retry Now")
    btn:SetFont("HomigradCrashFontBig")
    btn:SetSize(200, 50)
    btn:SetPos(ScrW()/2 - 100, ScrH()/2 + 100)
    btn:SetTextColor(Color(255,255,255))
    btn.Paint = function(s, w, h)
        local col = s:IsHovered() and Color(200, 50, 50, 200) or Color(155, 0, 0, 200)
        draw.RoundedBox(0, 0, 0, w, h, col)
        surface.SetDrawColor(0,0,0,255)
        surface.DrawOutlinedRect(0,0,w,h)
    end
    btn.DoClick = function()
        RequestRetry()
    end
end

-- Helper to request retry safely
function RequestRetry()
    -- Only request if connected, otherwise we can't disconnect
    if engine.IsConnected() then
        -- Signal the menu state to retry
        cookie.Set(COOKIE_RETRY, "1")
        cookie.Set(COOKIE_TIME, tostring(os.time() + 2)) -- 2 second delay
        RunConsoleCommand("disconnect")
    end
end

timer.Create("CrashMonitor", 1, 0, function()
    -- 1. Menu State Logic (Safe Retry)
    if not engine.IsConnected() then
        if cookie.GetString(COOKIE_RETRY) == "1" then
            local retryTime = tonumber(cookie.GetString(COOKIE_TIME)) or 0
            if os.time() >= retryTime then
                cookie.Set(COOKIE_RETRY, "0")
                RunConsoleCommand("retry")
            end
        end
        return
    end

    -- 2. Client State Logic (Crash Detection)
    -- Only check if we are fully loaded
    if not IsValid(LocalPlayer()) then 
        LastHeartbeat = RealTime() -- Reset heartbeat until player is valid to prevent false positives on load
        return 
    end
    
    if not CrashDetected then
        if RealTime() - LastHeartbeat > 10 then -- 10 seconds timeout
            SetCrashState(true)
            NextRetry = RealTime() + RetryInterval
            CreateCrashScreen()
        end
    else
        if RealTime() > NextRetry then
            RequestRetry()
            NextRetry = RealTime() + RetryInterval
        end
    end
end)

concommand.Add("crash_debug", function()
    SimulatedCrash = true
    SetCrashState(true)
    NextRetry = RealTime() + RetryInterval
    CreateCrashScreen()
    print("[CrashHandler] Debug mode enabled. Ignoring server heartbeats.")
end)

concommand.Add("crash_debug_stop", function()
    SimulatedCrash = false
    SetCrashState(false)
    LastHeartbeat = RealTime()
    print("[CrashHandler] Debug mode disabled.")
end)

-- Cleanup on disconnect/map change
hook.Add("ShutDown", "CrashHandler_Cleanup", function()
    if IsValid(CrashPanel) then
        CrashPanel:Remove()
    end
    -- Reset state
    SetCrashState(false)
end)

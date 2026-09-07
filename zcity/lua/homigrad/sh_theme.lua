hg = hg or {}
hg.theme = hg.theme or {}

hg.theme.list = {
    ["meleecity"] = {
        bg = Color(18,18,20,235),
        panel = Color(28,28,32,235),
        accent = Color(200,0,0),
        text = Color(215,215,215,255),
        warn = Color(210,50,50),
        outline = Color(80,60,40,160)
    },
    ["crows"] = {
        bg = Color(18,18,20,235),
        panel = Color(28,28,32,235),
        accent = Color(0,185,0,255),
        text = Color(215,215,215,255),
        warn = Color(210,50,50),
        outline = Color(80,60,40,160)
    }
}

hg.theme.c = table.Copy(hg.theme.list["meleecity"])

if SERVER then
    util.AddNetworkString("hg_theme_sync")
    
    local hg_servertheme = CreateConVar("hg_servertheme", "meleecity", FCVAR_ARCHIVE, "Server-wide theme for Homigrad")

    local function SyncTheme(ply)
        local themeName = hg_servertheme:GetString()
        if not hg.theme.list[themeName] then themeName = "meleecity" end
        
        net.Start("hg_theme_sync")
        net.WriteString(themeName)
        if ply then
            net.Send(ply)
        else
            net.Broadcast()
        end
    end

    cvars.AddChangeCallback("hg_servertheme", function(convar_name, value_old, value_new)
        SyncTheme()
    end)
    
    hook.Add("PlayerInitialSpawn", "hg_theme_sync", function(ply)
        SyncTheme(ply)
    end)
else
    net.Receive("hg_theme_sync", function()
    local themeName = net.ReadString()
    if hg.theme.list[themeName] then
        -- Update in place to support references
        for k, v in pairs(hg.theme.list[themeName]) do
            hg.theme.c[k] = v
        end
    end
end)
end

function hg.theme.DrawGrid(pnl, alpha)
    local w, h = pnl:GetWide(), pnl:GetTall()
    local spd = 8
    local off = (CurTime() * spd) % 16
    surface.SetDrawColor(255,255,255, alpha or 6)
    for x = -off, w, 16 do surface.DrawLine(x, 0, x, h) end
    for y = -off, h, 16 do surface.DrawLine(0, y, w, y) end
end

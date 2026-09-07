if SERVER then AddCSLuaFile() end

TOOL.Category = "ZBattle"
TOOL.Name = "ZBattle Spawnpoint Editor"
TOOL.Description = "Add/remove team spawnpoints and set rotation"
TOOL.Command = nil
TOOL.ConfigName = ""
TOOL.AddToMenu = true
TOOL.Information = {
    {name="left"},
    {name="right"},
    {name="reload"},
}

local angs = {
    Angle(0,0,0),
    Angle(0,90,0),
    Angle(0,180,0),
    Angle(0,270,0),
}

if CLIENT then
    language.Add("Tool.zb_spawnpoint_editor.left", "Add Spawnpoint")
    language.Add("Tool.zb_spawnpoint_editor.right", "Rotate Spawnpoint")
    language.Add("Tool.zb_spawnpoint_editor.reload", "Remove Last Spawnpoint")

    TOOL.SelectedGroup = TOOL.SelectedGroup or "HMCD_TDM_T"

    function TOOL:BuildCPanel(panel)
        local lbl = vgui.Create("DLabel", panel)
        lbl:Dock(TOP)
        lbl:SetText("Point Group")
        lbl:DockMargin(0, 4, 0, 2)

        local combo = vgui.Create("DComboBox", panel)
        combo:Dock(TOP)
        combo:SetTall(24)
        combo:SetSortItems(false)
        for k, v in pairs(zb.Points or {}) do
            if isstring(k) then
                combo:AddChoice(k)
            end
        end
        local selected = isstring(self.SelectedGroup) and self.SelectedGroup or "HMCD_TDM_T"
        combo.OnSelect = function(_, _, value)
            self.SelectedGroup = value
        end
        combo:SetValue(selected)
    end
end

function TOOL:LeftClick(tr)
    if CLIENT then
        local group = isstring(self.SelectedGroup) and self.SelectedGroup or "HMCD_TDM_T"
        net.Start("zb_pointsaction")
            net.WriteString("create")
            net.WriteString(group)
            net.WriteInt(0, 16)
        net.SendToServer()
        return true
    end
    return true
end

function TOOL:RightClick(tr)
    if SERVER then
        local ply = self:GetOwner()
        local pre = ply:GetNWAngle("zb_point_ang", Angle(0,0,0))
        local nextAng
        if pre == angs[1] then nextAng = angs[2]
        elseif pre == angs[2] then nextAng = angs[3]
        elseif pre == angs[3] then nextAng = angs[4]
        else nextAng = angs[1] end
        ply:SetNWAngle("zb_point_ang", nextAng)
        return true
    end
    return true
end

function TOOL:Reload(tr)
    if CLIENT then
        local group = isstring(self.SelectedGroup) and self.SelectedGroup or "HMCD_TDM_T"
        net.Start("zb_pointsaction")
            net.WriteString("remove")
            net.WriteString(group)
            net.WriteInt(0, 16)
        net.SendToServer()
        return true
    end
    return true
end


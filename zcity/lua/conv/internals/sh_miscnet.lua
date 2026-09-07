if SERVER then util.AddNetworkString("CONV_SendGModHint") end

if CLIENT then
    net.Receive("CONV_SendGModHint", function()
        local strMsg    = net.ReadString()
        local iType     = net.ReadUInt(3)
        local fDuration = net.ReadFloat()
        conv.sendGModHint(NULL, strMsg, iType, fDuration)
    end)
end
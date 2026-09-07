--
SalatsWhiteList = SalatsWhiteList or {}
SalatsWhiteList.SteamIDs = {}
SalatsWhiteList.ID = string.Split( GetHostName(), " " )[3]
SalatsWhiteList.Patch = "salatwl"..(SalatsWhiteList.ID)..".json"
SalatsWhiteList.Enable = false -- SalatsWhiteList.ID != "HMCDGang"

function SalatsWhiteList:LoadFromFile(strPatch)
	local fileread = file.Read( strPatch, "DATA" )
	if not fileread then return end
	self.SteamIDs = util.JSONToTable(fileread)
end

function SalatsWhiteList:SaveToFile(strPatch)
	file.Write( strPatch, util.TableToJSON( self.SteamIDs, true ) )
end

function SalatsWhiteList:Add(strSteamid)
	self.SteamIDs = self.SteamIDs or {}
	
	self.SteamIDs[strSteamid] = true
	
	self:SaveToFile(SalatsWhiteList.Patch)
end

concommand.Add( "sltwl_add", function( ply, cmd, args )
    if not ply:IsAdmin() then ply:PrintMessage( HUD_PRINTCONSOLE, "You are not allowed to use this command." ) return end
	if not args[1] then ply:PrintMessage( HUD_PRINTCONSOLE, "Write SteamID as first argument" ) return end
	SalatsWhiteList:Add(args[1])
	ply:PrintMessage( HUD_PRINTCONSOLE, "SteamID added" )
end )

function SalatsWhiteList:Remove(strSteamid)
	self.SteamIDs = self.SteamIDs or {}
	if self.SteamIDs[strSteamid] then
		self.SteamIDs[strSteamid] = nil
	end
	self:SaveToFile(SalatsWhiteList.Patch)
end

concommand.Add( "sltwl_remove", function( ply, cmd, args )
    if not ply:IsAdmin() then ply:PrintMessage( HUD_PRINTCONSOLE, "You are not allowed to use this command." ) return end
	if not args[1] then ply:PrintMessage( HUD_PRINTCONSOLE, "Write SteamID as first argument" ) return end
	SalatsWhiteList:Remove(args[1])
	ply:PrintMessage( HUD_PRINTCONSOLE, "SteamID removed" )
end )

concommand.Add( "sltwl_get", function( ply, cmd, args )
    if not ply:IsAdmin() then ply:PrintMessage( HUD_PRINTCONSOLE, "You are not allowed to use this command." ) return end
	ply:PrintMessage( HUD_PRINTCONSOLE, util.TableToJSON( SalatsWhiteList.SteamIDs, true ) )
end )
 
hook.Add("CheckPassword","SalatsWL",function( strSteamID64 )
	if not SalatsWhiteList.Enable then return end
	local strSteamID = util.SteamIDFrom64( strSteamID64 )
	if not SalatsWhiteList.SteamIDs[strSteamID] then
		return false, "You are not in whitelist."
	end
end)

SalatsWhiteList:LoadFromFile(SalatsWhiteList.Patch)
SalatsWhiteList:SaveToFile(SalatsWhiteList.Patch)

hook.Add("InitPostEntity","SalatsWL",function()
	SalatsWhiteList.ID = string.Split( GetHostName(), " " )[3]
	SalatsWhiteList:LoadFromFile(SalatsWhiteList.Patch)
end)
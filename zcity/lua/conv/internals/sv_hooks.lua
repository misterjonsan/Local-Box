// INTERNAL, DO NOT USE


conv._NetFuncsToSendJoiningPlayers = conv._NetFuncsToSendJoiningPlayers or {}
local load_queue = {}


hook.Add( "PlayerInitialSpawn", "myAddonName/Load", function( ply )
	load_queue[ ply ] = true
end )


hook.Add( "StartCommand", "myAddonName/Load", function( ply, cmd )
	if load_queue[ ply ] and !cmd:IsForced() then

		load_queue[ ply ] = nil

        for _, v in ipairs(conv._NetFuncsToSendJoiningPlayers) do
            v()
            net.Send(ply)
        end

	end
end )
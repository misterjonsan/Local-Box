local function IncluderFunc(fileName)
	if (fileName:find("sv_")) then
		include(fileName)
	elseif (fileName:find("shared.lua") or fileName:find("sh_")) then
		if (SERVER) then
			AddCSLuaFile(fileName)
		end

		include(fileName)
	elseif (fileName:find("cl_")) then
		if (SERVER) then
			AddCSLuaFile(fileName)
		else
			include(fileName)
		end
	end
end

--прошу обратить внимание что файлы внутри папок загружаются первыми
local function LoadFromDir(directory)
    local files, folders = file.Find(directory .. "/*", "LUA")
    
	for _, v in ipairs(folders) do
        LoadFromDir(directory .. "/" .. v)
	end

	for _, v in ipairs(files) do
		IncluderFunc(directory .. "/" .. v)
	end
end

LoadFromDir("local-box/gamemode/libraries")

--моды лоадер (плывисочная машина), если чё непонятно спрашивайте у меня (мистера поинта). мод много модов.
zb.modesHooks = {}
zb.modes = zb.modes or {}

local function LoadModes()
    local directory = "local-box/gamemode/modes"
    local files, folders = file.Find(directory .. "/*", "LUA")
    
    for _, v in ipairs(files) do
        MODE = {}

        IncluderFunc(directory .. "/" .. v)
        if table.IsEmpty(MODE) then continue end
        
        local saved = zb.modes[MODE.name] and zb.modes[MODE.name].saved or {}

        if MODE.base then
            table.Inherit(MODE,zb.modes[MODE.base])
        end

        zb.modes[MODE.name] = MODE
        
        zb.modes[MODE.name].saved = saved

        for k, v2 in pairs(MODE) do
            if isfunction(v2) then
                zb.modesHooks[MODE.name] = zb.modesHooks[MODE.name] or {}
                zb.modesHooks[MODE.name][k] = v2
            end
        end

        MODE = nil
	end

    for _, v in ipairs(folders) do
        MODE = {}

        LoadFromDir(directory .. "/" .. v)
        if table.IsEmpty(MODE) then continue end

        local saved = zb.modes[MODE.name] and zb.modes[MODE.name].saved or {}

        if MODE.base then
            table.Inherit(MODE,zb.modes[MODE.base])
        end

        zb.modes[MODE.name] = MODE

        zb.modes[MODE.name].saved = saved

        for k, v2 in pairs(MODE) do
            if isfunction(v2) then
                zb.modesHooks[MODE.name] = zb.modesHooks[MODE.name] or {}
                zb.modesHooks[MODE.name][k] = v2
            end
        end

        MODE = nil
	end
end

LoadModes()

print("ZB modes loaded!")

local ZB_ORIG_HOOK_CALL = ZB_ORIG_HOOK_CALL or hook.Call

function hook.Call(name, gm, ...)
    local Current = zb.CROUND or "tdm" 
    local ModeTable = zb.modes[Current]

    -- First, always call the original hook system to ensure all addons work properly
    local originalResults = {ZB_ORIG_HOOK_CALL(name, gm, ...)}
    
    -- Then check if the current gamemode wants to override the result
    if zb.modesHooks[Current] and zb.modesHooks[Current][name] then
        local a, b, c, d, e, f = zb.modesHooks[Current][name](ModeTable, name, ...)

        -- Only override if the gamemode hook explicitly returns a non-nil value
        if (a ~= nil) then
            return a, b, c, d, e, f
        end
    end

    -- Return the original results if gamemode didn't override
    return unpack(originalResults)
end

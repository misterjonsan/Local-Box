if SERVER then return end

-- Таблица для кэширования (чтобы не спамить запросами в Steam)
ZB_SteamFrames = ZB_SteamFrames or {}
ZB_SteamFrames.Cache = {}

-- Функция получения рамки
function ZB_SteamFrames.GetFrame(ply, callback)
    if not IsValid(ply) then return end
    if ply:IsBot() then return end
    
    local steamid64 = ply:SteamID64()
    local accountID = ply:AccountID() -- Нужен для miniprofile

    -- Если уже есть в кэше, возвращаем сразу
    if ZB_SteamFrames.Cache[steamid64] ~= nil then
        if callback then callback(ZB_SteamFrames.Cache[steamid64]) end
        return
    end

    -- Ставим пометку, что запрос уже отправлен (чтобы не отправлять 100 раз в секунду)
    ZB_SteamFrames.Cache[steamid64] = false 

    -- Ссылка на мини-профиль Steam
    local url = "https://steamcommunity.com/miniprofile/" .. accountID

    http.Fetch(url,
        function(body)
            -- Ищем ссылку на картинку рамки в HTML коде
            -- <img class="miniprofile_avatar_frame" src="...">
            local frameURL = string.match(body, 'class="miniprofile_avatar_frame" src="(.-)"')

            if frameURL then
                -- Скачиваем саму картинку рамки для отрисовки
                local crc = util.CRC(frameURL) -- Уникальное имя для файла
                local path = "zb_frames/" .. crc .. ".png"

                -- Если файл уже скачан, создаем материал
                if file.Exists(path, "DATA") then
                    ZB_SteamFrames.Cache[steamid64] = Material("data/" .. path, "noclamp smooth")
                    if callback then callback(ZB_SteamFrames.Cache[steamid64]) end
                else
                    -- Если файла нет, качаем его
                    http.Fetch(frameURL, function(imgData)
                        if not imgData then return end
                        
                        file.CreateDir("zb_frames")
                        file.Write(path, imgData)

                        ZB_SteamFrames.Cache[steamid64] = Material("data/" .. path, "noclamp smooth")
                        if callback then callback(ZB_SteamFrames.Cache[steamid64]) end
                    end)
                end
            else
                -- У игрока нет рамки
                ZB_SteamFrames.Cache[steamid64] = false
                if callback then callback(false) end
            end
        end,
        function(err)
            print("[ZB Frames] Ошибка получения данных Steam: " .. err)
        end
    )
end

-- Очистка кэша при перезаходе (опционально)
hook.Add("InitPostEntity", "ZB_ClearFrameCache", function()
    ZB_SteamFrames.Cache = {}
end)
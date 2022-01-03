-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
-- PLAYERS+
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

local PlayerClass = FindMetaTable 'Player'

-- getting steamid3
function SteamID32to3(steamid)
    local y, z = string.match(steamid, 'STEAM_%d:(%d):(%d+)')
    return tonumber(y) + tonumber(z) * 2
end

function PlayerClass:SteamID3()
    if not self.steamid3 then self.steamid3 = SteamID32to3(self:SteamID()) end
    return self.steamid3
end

local pattern = 'STEAM_0:%i:%i'
function SteamID3to32(steamid)
    steamid = tonumber(steamid)
    local div = math.floor(steamid / 2)
    local mod = steamid - div * 2
    return pattern:format(mod, div)
end

function FindActiveBySteamID3(steamid)
    local steamid32 = SteamID3to32(steamid)
    local target = nil
    for k, v in next, player.GetHumans() do
        if v:SteamID3() == steamid then
            target = v
            break
        end
    end
    return target
end

module('Venus', package.seeall)

gameevent.Listen 'player_connect'
gameevent.Listen 'player_disconnect'
gameevent.Listen 'player_connect_client'

--[[    
    number bot - 0 if the player isn't a bot, 1 if they are.
    string networkid - The SteamID the player has. Will be "BOT" for bots and "STEAM_0:0:0" in single-player.
    string name - The name the player has.
    number userid - The UserID the player has.
    number index - The entity index of the player, minus one.
    string address - IP of the connected player. Will be "none" for bots and "loopback" for listen server and single-player hosts.
]]

CachedPlayers = {}

function CachePlayer(steamid, callback)
    DatabaseMisc.Query('caching:' .. steamid, DatabaseMisc.extendedQueries.get, true, function(result)
        local sr = result[1]
        callback((sr.status == true) and sr.data or false)
    end, steamid)
end

function UpdateLastVisit(steamid, callback)
    DatabaseMisc.Query('lastvisit:' .. steamid, DatabaseMisc.extendedQueries.lastvisit, false, function() end)
end

Hook('player_connect', 'precaching_on_connect', function(data)
    local id3 = SteamID32to3(data.networkid)
    CachePlayer(id3, function(data)
        if next(data) then
            CachedPlayers[id3] = data
            UpdateLastVisit(id3, function(data)
                PrintStatus(0, true, 'lastvisit:' .. id3, 'ok')
            end)
        else
            CachedPlayers[id3] = false
        end
    end)
end)

Hook('player_disconnect', 'uncache_on_disconnect', function(data)
    print('player_disconnect', SysTime())
end)

Hook('PlayerDisconnected', 'uncache', function()
    print('PlayerDisconnected', SysTime())
end)
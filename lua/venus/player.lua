-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
-- PLAYERS+
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

local PlayerClass = FindMetaTable 'Player'

-- getting steamid3
function SteamID32to3(steamid)
    if steamid == 'BOT' then return 0 end
    local y, z = string.match(steamid, 'STEAM_%d:(%d):(%d+)')
    return tonumber(y) + tonumber(z) * 2
end

function PlayerClass:SteamID3()
    if not self.steamid3 then self.steamid3 = self:IsPlayer() and SteamID32to3(self:SteamID()) or 0 end
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

CachedPlayers = CachedPlayers or {}
ConnectingPlayers = ConnectingPlayers or {}
PlayerSpawnedInWorld = PlayerSpawnedInWorld or {}

local function ConvertPerms(ToJSON, perms)
    -- dir :: bool
    -- true -> from table to json
    -- false -> from json to table
    local p = {}
    if ToJSON then
        for k, v in next, perms do
            p[#p + 1] = k
        end
        return util.TableToJSON(p)
    else
        for k, v in next, util.JSONToTable(perms) do
            p[v] = true
        end
        return p
    end
end

local function GetTotalTime(id)
    -- id is a key or an entity
    return (CurTime() - PlayerSpawnedInWorld[id]) + (CachedPlayers[id].totalplayed or 0)
end

function CachePlayer(steamid, callback)
    DatabaseMisc.Query('caching:' .. steamid, DatabaseMisc.extendedQueries.get, true, function(result)
        local sr = result[1]
        callback((sr.status == true) and sr.data or false)
    end, steamid)
end

function UpdateLastVisit(steamid, callback)
    DatabaseMisc.Query('lastvisit:' .. steamid, DatabaseMisc.extendedQueries.lastvisit, false, nil, steamid)
end

function UpdatePlayer(steamid, kvpairs)
    DatabaseMisc.Query('updateplayer:' .. steamid, DatabaseMisc.presets.doUpdate('venus_players', kvpairs, {{'steamid', steamid}}), false)
end

local function PushNewPlayer(steamid)
    DatabaseMisc.Query('firstvisit:' .. steamid, DatabaseMisc.presets.doInsert('venus_players', {
        {'steamid', steamid},
        {'usergroup', safeString('user')},
        {'lastvisit', 'now()'},
        {'perms', safeString(util.TableToJSON({}))},
        {'firstvisit', 'now()'},
        {'totalplayed', 0}
    }), false, function(result) end)
end

local ignoreOnUpdate = {
    ['lastvisit'] = true,
    ['firstvisit'] = true
}

function UnloadPlayer(steamid, data, callback)
    local updatePairs = {}
    for k, v in next, data do
        updatePairs[#updatePairs + 1] = { v[1], v[2] }
    end
    local where = {{'steamid', steamid}}
    DatabaseMisc.Query('unloadply:' .. steamid, DatabaseMisc.presets.doUpdate('venus_players', updatePairs, where), false, function(result)
        local r = result[1]
        PrintStatus(5, r.status, 'unloadply:' .. steamid)
    end)
end

Hook('player_connect', 'v__precaching_on_connect', function(data)
    local id3 = SteamID32to3(data.networkid)
    ConnectingPlayers[id3] = true
    CachePlayer(id3, function(data)
        if data and data[1] and next(data) then
            if not ConnectingPlayers[id3] then return end
            CachedPlayers[id3] = data[1]
            CachedPlayers[id3].perms = ConvertPerms(false, CachedPlayers[id3].perms)
            UpdateLastVisit(id3, function(data)
                PrintStatus(0, true, 'lastvisit:' .. id3, 'ok')
            end)
        else
            PushNewPlayer(id3)
            CachedPlayers[id3] = {
                steamid = id3,
                usergroup = 'user',
                lastvisit = os.time(),
                perms = {},
                firstvisit = os.time(),
                totalplayed = 0
            }
        end
    end)
end)

Hook('player_disconnect', 'v__uncache_on_disconnect', function(data)
    local id3 = SteamID32to3(data.networkid)
    if data.bot == 1 or ConnectingPlayers[id3] then return end
    local obj = CachedPlayers[id3]
    UnloadPlayer(id3, {
        {'totalplayed', math.floor(GetTotalTime(id3))},
        {'lastvisit', 'now()'}
    })
    CachedPlayers[id3] = nil
    PlayerSpawnedInWorld[id3] = nil
end)

Hook('PlayerInitialSpawn', 'v__set_player_data', function(ply)
    local id3 = ply:SteamID3()
    ConnectingPlayers[id3] = nil
    CachedPlayers[ply] = CachedPlayers[id3]
    PlayerSpawnedInWorld[id3] = CurTime()
    PlayerSpawnedInWorld[ply] = PlayerSpawnedInWorld[id3]
end)

Hook('PlayerDisconnected', 'v__unload_player', function(ply)
    CachedPlayers[ply] = nil
    PlayerSpawnedInWorld[ply] = nil
end)
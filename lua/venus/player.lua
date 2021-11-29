-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
-- PLAYERS+
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

local PlayerClass = FindMetaTable 'Player'

-- getting steamid3
function PlayerClass:SteamID3()
    if not self.steamid3 then
        local y, z = string.match(self:SteamID(), 'STEAM_%d:(%d):(%d+)')
        self.steamid3 = tonumber(y) + tonumber(z) * 2
    end
    return self.steamid3
end

local pattern = 'STEAM_0:%i:%i'
function SteamID3to32(steamid)
    steamid = tonumber(steamid)
    local div = math.floor(steamid / 2)
    local mod = steamid - div * 2
    return pattern:format(mod, div)
end

function PlayerClass:GetVenusData()
    self.VenusData.lastVisit = os.time()
    self.VenusData.totalPlayed = self.VenusData.totalPlayed + (self.lastTotalUpdate and (CurTime() - self.lastTotalUpdate) or 0)
    self.lastTotalUpdate = CurTime()
    return self.VenusData
end

-- more simple using hooks
local hadd = hook.Add
local hrm = hook.Remove

module('Venus', package.seeall)

function SyncPlayer(ply, rank, firstVisit, lastVisit, rawPerms, totalPlayed)
    ply:SetNWString('usergroup', rank)

    -- converting the {'e2', 'e2p', 'noclip'} form into {[permission] = true} form
    local perms = {}
    for _, p in next, util.JSONToTable(rawPerms) do perms[p] = true end

    ply.VenusData = {
        rank = rank,
        firstVisit = firstVisit,
        lastVisit = lastVisit,
        totalPlayed = totalPlayed,
        perms = perms
    }
end

local function LoadPlayer(ply)
    ply.VenusLoaded = false
    ply.lastTotalUpdate = CurTime()
    PrintStatus(0, nil, 'Pulling player data from the database...')
    GetPlayerData(ply:SteamID3(), function(data)
        if not data then
            PrintStatus(0, false, ply, 'Can\'t set up a rank to the player.')
            DebugPrint(0, ply, ply:SteamID3())
            return
        end
        if data == -1 then
            PrintStatus(8, 0, ply, 'Can\'t find the player in the database, so creating a new row.')
            DebugPrint(8, ply, ply:SteamID3())
            SyncPlayer(ply, 'user', os.time(), os.time(), util.TableToJSON({}), 0)
            PushNewPlayerData(ply:SteamID3())
            ply.VenusLoaded = true
            return
        end
        PrintStatus(8, true, ply, 'Synced with the database.')
        DebugPrint(8, data)
        SyncPlayer(ply, data.rank, data.firstVisit, data.lastVisit, data.perms, data.totalPlayed)
        ply.VenusLoaded = true
    end)
end

-- async loading player data from the database
hadd('PlayerInitialSpawn', 'Venus_LoadPlayer', LoadPlayer)

local function UnloadPlayer(ply)
    PrintStatus(0, nil, 'Pushing player data into the database...')

    local dataOnLeave = nil
    if ply.VenusLoaded then
        dataOnLeave = table.Copy(ply:GetVenusData())
        dataOnLeave.perms = PermissionsIntoSQL(dataOnLeave.perms)
        dataOnLeave.totalPlayed = math.floor(dataOnLeave.totalPlayed)
    else -- if for some reason loading player data failed, just update his lastVisit timestamp
        dataOnLeave = { lastVisit = os.time() }
    end

    Venus.PushPlayerData(ply:SteamID3(), dataOnLeave)
end

hadd('PlayerDisconnected', 'Venus_UnloadPlayer', UnloadPlayer)

local function UnloadAllPlayers()
    for k, v in next, player.GetHumans() do
        UnloadPlayer(v)
    end
end

-- save all players on shutdown
hadd('Shutdown', 'Venus_SaveOnShutdown', UnloadAllPlayers)
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
-- PLAYERS+
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

local PlayerClass = FindMetaTable 'Player'

-- getting steamid3
function PlayerClass:SteamID3()
    local y, z = string.match(self:SteamID(), 'STEAM_%d:(%d):(%d+)')
    return tonumber(y) + tonumber(z) * 2
end

-- more simple using hooks
local hadd = hook.Add
local hrm = hook.Remove

module('Venus', package.seeall)

function SyncPlayer(ply, rank, firstVisit, lastVisit, rawPerms, totalSpent)
    ply:SetNWString('usergroup', rank)

    -- converting the {'e2', 'e2p', 'noclip'} form into {[permission] = true} form
    local perms = {}
    for _, p in next, util.JSONToTable(rawPerms) do perms[p] = true end

    ply.VenusData = {
        rank = rank,
        firstVisit = firstVisit,
        lastVisit = lastVisit,
        totalSpent = totalSpent,
        perms = perms
    }
end

local function LoadPlayer(ply)
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
            return
        end
        PrintStatus(8, true, ply, 'Synced with the database.')
        DebugPrint(8, data)
        SyncPlayer(ply, data.rank, data.firstVisit, data.lastVisit, data.perms, data.totalSpent)
    end)
end

-- async loading player data from the database
hadd('PlayerInitialSpawn', 'Venus_LoadPlayer', LoadPlayer)

--[[

    TODO: update lastVisit & totalPlayer on disconnect

]]
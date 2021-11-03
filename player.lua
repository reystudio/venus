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

hadd('PlayerInitialSpawn', 'Venus_LoadRank', function(ply)

    local plyid = ply:SteamID3()

end)
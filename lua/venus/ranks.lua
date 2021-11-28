-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
-- RANKS MODULE (OBJECT-ORIENTED)
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

module('Venus', package.seeall)
local s = MySQLite.SQLStr

--[[
    local user = Ranks('user', 'Member', Color(255, 255, 255), {'who', 'help', 'votekick'})
    local moder = Ranks('mod', 'Moderator', Color(100, 255, 100), {'goto', 'bring', 'kick', 'ban'}, 'user')
    local admin = Ranks('admin', 'Administrator', Color(255, 100, 100), {'vote', 'restart', 'alert', 'note'}, 'mod')
    local root = Ranks('root', 'Master', Color(100, 100, 255), {'*'})

    print( moder:HasAccess( 'who' ) ) -- true
]]

Ranks = {
    List = {},
    HasAccess = function(self, flag)
        local perms = self.permissions
        if perms['*'] then return true end
        if perms[flag] then return true end
        if self.parent and self.List[self.parent] then return (self.List[self.parent]):HasAccess(flag) end
        return false
    end,
    PrepareForDatabase = function(self)
        return {
            rank = self.rank,
            name = self.name,
            hexcolor = ToHex(self.color),
            permissions = PermissionsIntoSQL(self.permissions),
            derivedFrom = self.parent
        }
    end,
    Update = function(self, rank, name, color, perms, parent)
        local oldname = self.rank
        if self.rank ~= rank then
            if self.List[rank] then return false, 'Already exists' end
            self.List[rank] = self
            self.List[self.rank] = nil
            self.rank = rank
        end
        self.name = name or self.name
        self.color = color or self.color
        self.perms = perms or self.perms
        self.parent = parent or self.parent
        -- for k, v in pairs(flags) do self.permissions[k] = v end
        RunEvent('UpdatedRank', oldname, self)
        return true
    end,
    Delete = function(self)
        local rank = self.rank
        self.List[rank] = nil
        RunEvent('RemovedRank', rank)
    end
}
setmetatable(Ranks, {
    __call = function(self, rank, name, color, permissions, parentName)
        if self.List[rank] then return self.List[rank] end
        local new = {
            rank = rank,
            name = name,
            color = color,
            permissions = permissions,
            parent = parentName
        }
        setmetatable(new, { __index = Ranks, __tostring = function(self) return ('VenusRank[%s]'):format(self.name) end })
        self.List[rank] = new
        return new
    end,
})

function GetRank(rank) return Ranks.List[rank] end
function GetRanks() return Ranks.List end

local function fromSQLtoVenus(body)
    Print(5, 'Ranks module initialization:')
    for k, v in next, body do
        -- Print(v.rank, v.parent)
        if body[k].parent == 'NULL' then body[k].parent = nil end
        local r = Ranks(v.rank, v.name, ToRGB(v.color), PermissionsIntoLua(v.perms), v.parent)
        PrintStatus(5, nil, r.name)
    end
    -- Print(Ranks.List.user)
end

local function pushDefaultRanks()
    local defaultRanks = {
        {
            rank = 'user',
            name = 'Member',
            color = ToHex( Color(200, 200, 200) ),
            perms = util.TableToJSON({'who','help','admin','pm','votekick'}),
            derivedFrom = nil
        },
        {
            rank = 'mod',
            name = 'Moderator',
            color = ToHex( Color(50, 200, 50) ),
            perms = util.TableToJSON({'goto','bring','jump','kick','ban','alert','note'}),
            derivedFrom = 'user'
        },
        {
            rank = 'admin',
            name = 'Administrator',
            color = ToHex( Color(200, 50, 50) ),
            perms = util.TableToJSON({'hp','armor','vote','silent'}),
            derivedFrom = 'mod'
        },
        {
            rank = 'root',
            name = 'Master',
            color = ToHex( Color(255, 160, 70) ),
            perms = util.TableToJSON({'*'}),
            derivedFrom = nil
        }
    }
    local isLoaded = {}
    for _, rank in next, defaultRanks do isLoaded[rank.rank] = false end
    local function checkForRanks() for k, v in next, isLoaded do if not v then return false end end return true end
    local rankQuery = 'INSERT INTO venus_ranks VALUES (%s, %s, %s, %s, %s);'
    for _, rank in next, defaultRanks do
        MySQLite.query(rankQuery:format(s(rank.rank), s(rank.color), s(rank.name), s(rank.perms), rank.derivedFrom and s(rank.derivedFrom) or 'NULL'),
        function()
            PrintStatus(5, true, 'Push Default Ranks', 'Successfully pushed "' .. rank.rank .. '" rank into ranks table.')
            isLoaded[rank.rank] = true
            if checkForRanks() then
                PrintStatus(5, nil, 'Push Default Ranks', 'All default ranks pushed. Now pulling them back again...')
                GetEventCallback('DatabaseLoaded', 'GetRanks')({ ranks = 1 })
                RunEvent('RanksLoaded')
            end
        end,
        function(err, q)
            PrintStatus(0, false, 'Push Default Ranks', 'Can\'t push ' .. rank.rank .. ' rank into ranks table. SQL error: ' .. (err or 'no traceback'))
            Print(0, q)
        end)
    end
end

EventCallback('DatabaseLoaded', 'GetRanks', function(tables)
    if tables.ranks ~= 1 then
        PrintStatus(1, false, 'Pull Ranks', 'Ranks table isn\'t initialized, so can\'t pull them from it.')
        return
    end
    MySQLite.query('SELECT rank, name, color, perms, derivedFrom as parent FROM venus_ranks;',
    function(body)
        if not body then
            PrintStatus(5, 0, 'Pull Ranks', 'No ranks in the database, so create them with copying from default presets.')
            pushDefaultRanks()
            return
        end
        -- Print(body)
        fromSQLtoVenus(body)
    end,
    function(err, q)
        PrintStatus(0, false, 'Pull Ranks', 'SQL error: ' .. (err or 'no traceback'))
        Print(0, q)
    end)
end)

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- Callbacks after changing some parametres in any rank
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- update the rank in database & and rank's children
EventCallback('UpdatedRank', 'UpdateDatabase', function(oldrank, rank)
    local rankData = rank:PrepareForDatabase()
    MySQLite.query( ([[UPDATE venus_ranks SET rank = %s, name = %s, color = %s, perms = %s, derivedFrom = %s WHERE rank = %s;]])
    :format( s(rankData.rank), s(rankData.name), s(rankData.hexcolor), s(rankData.permissions), rank.parent and s(rank.parent) or 'NULL', s(oldrank)),
    function(body)
        PrintStatus(0, true, rank.name .. '(ranks)', 'Updated rank.')
    end,
    function(err, q)
        PrintStatus(0, false, rank.name .. '(ranks)', err)
        Print(0, q)
    end)
    if oldrank == rank then return end

    MySQLite.query( ([[UPDATE venus_ranks SET derivedFrom = %s WHERE derivedFrom = %s;]])
    :format( s(rankData.rank), s(oldrank)),
    function(body)
        PrintStatus(5, true, rank.name .. '(ranks)', 'Updated child ranks.')
    end,
    function(err, q)
        PrintStatus(0, false, rank.name .. '(ranks)', err)
        Print(0, q)
    end)
end)

-- update users with updated rank (set a new rank instead of old one)
EventCallback('UpdatedRank', 'UpdateUsers', function(oldrank, rank)
    if oldrank == rank.rank then return end
    MySQLite.query( ('SELECT COUNT(*) as c FROM venus_players WHERE rank = %s;'):format(s(oldrank)),
    function(body)
        local amount = tonumber(body[1].c)
        MySQLite.query( ([[UPDATE venus_players SET rank = %s WHERE rank = %s;]])
        :format( s(rank.rank), s(oldrank)),
        function(body)
            PrintStatus(5, true, rank.name .. '(users)', ('Updated %i users (%s%s%s).'):format(amount, oldrank, arrow, rank.rank))
        end,
        function(err, q)
            PrintStatus(0, false, rank.name .. '(users)', ('Can\'t update users (%s%s%s'):format(oldrank, arrow, rank.rank))
            Print(0, err, q)
        end)
    end,
    function(err, q)
        Print(0, err, q)
    end)
end)

-- set a new rank name to all players online
EventCallback('UpdatedRank', 'UpdatePlayers', function(oldrank, rank)
    for k, ply in next, player.GetAll() do
        if ply:GetNWString('usergroup') == oldrank then
            if oldrank ~= rank then ply:SetNWString('usergroup', rank.rank) end
        end
    end
end)

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- Callbacks after removing the rank
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- remove the rank from database
EventCallback('RemovedRank', 'UpdateDatabase', function(rank)
    MySQLite.query( ('DELETE FROM venus_ranks WHERE rank = %s;'):format(s(rank)),
    function()
        PrintStatus(0, true, rank, 'Successfully removed from the database.')
    end,
    function(err, q)
        PrintStatus(0, false, rank, 'The rank wasn\'t removed from the database.')
        Print(0, err, q)
    end)
    MySQLite.query( ([[UPDATE venus_ranks SET derivedFrom = %s WHERE derivedFrom = %s;]])
    :format( 'NULL', s(rank)),
    function(body)
        PrintStatus(5, true, rank .. '(ranks)', 'Remove deriving from child ranks.')
    end,
    function(err, q)
        PrintStatus(0, false, rank .. '(ranks)', err)
        Print(0, q)
    end)
end)

-- set 'user' rank to all players that have a removed rank right now
EventCallback('RemovedRank', 'UpdateUsers', function(rank)
    MySQLite.query( ('SELECT COUNT(*) as c FROM venus_players WHERE rank = %s;'):format(s(rank)),
    function(body)
        local amount = tonumber(body[1].c)
        MySQLite.query( ([[UPDATE venus_players SET rank = %s WHERE rank = %s;]])
        :format( s('user'), s(rank)),
        function(body)
            PrintStatus(5, true, rank .. '(users)', ('Updated %i users (%s%s%s).'):format(amount, rank, arrow, 'user'))
        end,
        function(err, q)
            PrintStatus(0, false, rank .. '(users)', ('Can\'t update users (%s%s%s'):format(rank, arrow, 'user'))
            Print(0, err, q)
        end)
    end,
    function(err, q)
        Print(0, err, q)
    end)
end)

-- set 'user' rank to all players online
EventCallback('RemovedRank', 'UpdateActivePlayers', function(rank)
    for k, ply in next, player.GetAll() do
        if ply:GetNWString('usergroup') == rank then
            ply:SetNWString('usergroup', 'user')
        end
    end
end)
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- DATABASE WORKAROUND (Automatically switches between MySQL & SQLite)
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
local AUTO_INCREMENT = 'AUTO_INCREMENT'

module('Venus', package.seeall)

local columns = {
    rank = 'VARCHAR(32)', -- short rank name
    color = 'CHAR(6)', -- HEX format -> #FFFFFF
    name = 'VARCHAR(128)', -- rank name
    perms = 'TEXT', -- JSON entry, 65535 letters limit
    -- lastVisit = 'TIMESTAMP', -- supports timezones diff shifting
    lastVisit = 'INT', -- more simple calculating shit in unix time
    plyid = 'INT UNSIGNED',
    bool = 'BIT',
    ban_type = 'VARCHAR(16)', -- i guess 16 letters are enough (increase if not)
    banned_server = 'VARCHAR(32)'
}

function BindDatabase()

    local checkout = {}

    local newTables = {}

    for _, tbl in next, {
        {
            -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
            -- RANKS QUERIES EXAMPLES:
            -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
            -- INSERT INTO venus_ranks VALUES ("user", "FA7C28", "Member", "{'e2'}", NULL);
            -- UPDATE venus_ranks SET perms = "{'e2','e2p'}" WHERE rank = "user";
            -- DELETE FROM venus_ranks WHERE rank = 'user';
            -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
            'ranks',
            [[
                CREATE TABLE IF NOT EXISTS venus_ranks (
                rank ]] .. columns.rank .. [[ PRIMARY KEY,
                color ]] .. columns.color .. [[,
                name ]] .. columns.name .. [[,
                perms ]] .. columns.perms .. [[,
                derivedFrom ]] .. columns.rank .. [[);
            ]]
        },
        {
            -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
            -- PLAYERS QUERIES EXAMPLES:
            -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
            -- INSERT INTO venus_players VALUES (25565462,"admin",CURRENT_TIMESTAMP,"{SOME JSON DATA}");
            -- UPDATE venus_players SET rank = "root" WHERE plyid = 25565462;
            -- DELETE FROM venus_players WHERE plyid = 25565462;
            -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
            'players',
            [[
                CREATE TABLE IF NOT EXISTS venus_players (
                plyid ]] .. columns.plyid .. [[ PRIMARY KEY,
                rank ]] .. columns.rank .. [[,
                lastVisit ]] .. columns.lastVisit .. [[,
                perms ]] .. columns.perms .. [[);
            ]]
        },
        {
            -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
            -- NOTES QUERIES EXAMPLES:
            -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
            -- INSERT INTO venus_notes VALUES (0,15,15,CURRENT_TIMESTAMP,"Some text", 1);
            -- UPDATE venus_notes SET description = "New text", ispublic = 0 WHERE noteid = 2;
            -- DELETE FROM venus_notes WHERE noteid = 3;
            -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
            'notes',
            [[
                CREATE TABLE IF NOT EXISTS venus_notes (
                    noteid ]] .. columns.plyid .. [[ ]] .. AUTO_INCREMENT .. [[ PRIMARY KEY,
                    plyid ]] .. columns.plyid .. [[,
                    authorid ]] .. columns.plyid .. [[,
                    created_at ]] .. columns.lastVisit .. [[,
                    description ]] .. columns.perms .. [[,
                    ispublic ]] .. columns.bool .. [[);
            ]]
        },
        {
            -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
            -- BANS QUERIES EXAMPLES:
            -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
            -- INSERT INTO venus_bans VALUES (0, 234234, 1233456, UNIX_TIMESTAMP(), UNIX_TIMESTAMP() + 1, NULL, NULL, "connect", "sandbox" );
            -- UPDATE venus_bans SET ban_author = 7643311 WHERE banid = 1;
            -- DO NOT DELETE BAN ENTRIES U FOOL
            -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
            --[[
                Ban types:
                - connect (can't join the server)
                - voice
                - text
                - mute (voice+text)
                - cmd:CMD_NAME (cmd:votekick -> player can't use votekick until he's unbanned)
            ]]
            'bans',
            [[
                CREATE TABLE IF NOT EXISTS venus_notes (
                    noteid ]] .. columns.plyid .. [[ ]] .. AUTO_INCREMENT .. [[ PRIMARY KEY,
                    plyid ]] .. columns.plyid .. [[,
                    authorid ]] .. columns.plyid .. [[,
                    created_at ]] .. columns.lastVisit .. [[,
                    description ]] .. columns.perms .. [[,
                    ispublic ]] .. columns.bool .. [[);
            ]]
        }
    } do
        checkout[tbl[1]] = false
        newTables[_] = tbl
    end

    local function checkTables() for k, v in next, checkout do if not v then return false end end return true end
    local function noticeStatus() if checkTables() then RunEvent('DatabaseLoaded', checkout) end end

    for _, t in next, newTables do
        MySQLite.query(t[2],
            function(body)
                checkout[t[1]] = 1
                noticeStatus()
            end,
            function(err, q)
                checkout[t[1]] = {err, q}
                noticeStatus()
            end)
    end
end

function GetPlayerData(steamid, ...)



end

function GetPlayersByRank(rank)
    -- ?
end

EventCallback('DatabaseLoaded', 'ShowInitStatus', function(tables)
    Print(5, 'Database initialization result:')
    for k, v in pairs(tables) do PrintStatus(5, v == 1, ' ' .. k, v~=1 and unpack(v) or nil) end
end)

function GetPlayerFromDatabase(steamid)



end
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- DATABASE WORKAROUND (MYSQL ONLY)
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
require 'tmysql4'

module('Venus', package.seeall)

local columns = {
	string_32 = 'VARCHAR(32)',
	string_6 = 'VARCHAR(6)',
	string_128 = 'VARCHAR(128)',
	text = 'TEXT',
	timestamp = 'TIMESTAMP',
	int_unsigned = 'INT UNSIGNED',
	bool = 'BIT',
	string_16 = 'VARCHAR(16)',
	string_256 = 'VARCHAR(256)',
}

local patterns = {
    now = 'now()',
    -- ??
}

function safeString(str)
    return string.Replace(("'%s'"):format(str), '\\', '\\\\')
end

local build_new_table_query = function( tableName, ... )
    local args = {...}
    local q = 'CREATE TABLE IF NOT EXISTS %s (%s, PRIMARY KEY(%s));'
    local regex = {}
    local keys = {}
    local pattern = string.rep('%s %s', #args, ', ')
    for k, v in ipairs(args) do
        regex[#regex + 1] = v[1]
        regex[#regex + 1] = v[2]
        if v[4] then regex[#regex] = regex[#regex] .. ' AUTO_INCREMENT' end
        if v[3] then keys[#keys + 1] = v[1] end
    end
    keys = (string.rep('%s', #keys, ', ')):format(unpack(keys))
    return { tableName, q:format(tableName, pattern:format(unpack(regex)), keys) }
end

local table_structure = {}

table_structure[#table_structure + 1] = build_new_table_query('venus_players',
    {'steamid',columns.int_unsigned,true},
    {'usergroup',columns.string_16},
    {'lastvisit',columns.timestamp},
    {'perms',columns.text},
    {'firstvisit',columns.timestamp},
    {'totalplayed', columns.int_unsigned})

table_structure[#table_structure + 1] = build_new_table_query('venus_notes',
    {'noteid',columns.int_unsigned,true,true},
    {'targetid',columns.int_unsigned},
    {'creatorid',columns.int_unsigned},
    {'timestamp',columns.timestamp},
    {'description',columns.text},
    {'ispublic',columns.bool})

table_structure[#table_structure + 1] = build_new_table_query('venus_punishments',
    {'banid',columns.int_unsigned,true,true},
    {'targetid',columns.int_unsigned},
    {'timestamp',columns.timestamp},
    {'banneduntil',columns.timestamp},
    {'isunbanned',columns.bool},
    {'unbannedby',columns.int_unsigned},
    {'bannedby',columns.int_unsigned},
    {'bantype',columns.string_32},
    {'server',columns.string_32},
    {'reason',columns.text})

table_structure[#table_structure + 1] = build_new_table_query('venus_logs',
    {'logid',columns.int_unsigned,true,true},
    {'timestamp',columns.timestamp},
    {'logclass',columns.string_16},
    {'logtype',columns.string_16})

table_structure[#table_structure + 1] = build_new_table_query('venus_ext_logs',
    {'logid',columns.int_unsigned,true},
    {'logkey',columns.string_32,true},
    {'logvalue',columns.text})

hook.Add('DatabaseLoaded', 'venus_DB_Init', function(db, t)
    PrintStatus(0, true, 'Database', 'Connected for ' .. (t*1000) .. 'ms')
    print(db)
    DATABASE_INITIALIZED = true
    DATABASE = db
    local gclocks = SysTime()

    local loading_status = 0

    for k, v in next, table_structure do
        DatabaseMisc.Query(v[1], v[2], true, function(result)
            loading_status = loading_status + 1
            if loading_status == #table_structure then
                PrintStatus(0, true, 'Database:tables', 'Done! ' .. (SysTime() - gclocks)*1000 .. 'ms')
            end
        end)
    end

    hook.Add('Think', 'MySQLite:tmysqlPoll', function() DATABASE:Poll() end)
end)

DatabaseMisc = {
    queue = {},
    presets = {
        insert = 'INSERT INTO %s (%s) VALUES (%s);',
        update = 'UPDATE %s SET %s WHERE %s;',
        select = 'SELECT %s FROM %s WHERE %s;',
        delete = 'DELETE %s FROM %s WHERE %s;'
    },
    isProcessing = false,
    Pipeline = function(q)
        if not q[1] then return end
        local buffer = table.remove(q, 1)
        DatabaseMisc.Query(unpack(buffer))
    end,
    extendedQueries = {
        new = 'INSERT INTO venus_players (steamid, usergroup, lastvisit, perms, firstvisit, totalplayed) VALUES (%s,%s,now(),%s,now(),0);',
        get = 'SELECT usergroup, firstvisit, lastvisit, perms, totalplayed FROM venus_players WHERE steamid = %s;',
        lastvisit = 'UPDATE venus_players SET lastvisit = now() WHERE steamid = %s;',
    },
    extendedValues = {
        now = 'now()',
        fromnow = 'now() + %i',
        quote = '\'%s\'',
    },
    ExtendedValues = function(k, ...) return DatabaseMisc.extendedValues[k]:format(...) end,
    CachedQuery = function(qname, ptype, ...) return DatabaseMisc.extendedQueries[ptype]:format(...) end,
    Query = function(qname, cquery, customErrorHandling, callback, ...)
        local timing = SysTime()
        local preset = DatabaseMisc.presets[cquery] or cquery

        if not DATABASE_INITIALIZED or DatabaseMisc.isProcessing then
            -- queries are delayed for some reasons
            DatabaseMisc.queue[#DatabaseMisc.queue + 1] = { qname, cquery, customErrorHandling, callback, ... }
        else
            DatabaseMisc.isProcessing = true
            local q = next({...}) and preset:format(...) or preset
            DATABASE:Query(q, function(r)
                PrintStatus(0, nil, 'tmysql query:' .. qname, 'Done! ' .. tostring((SysTime() - timing)*1000) .. 'ms')
                
                if not r[1].status then
                    PrintStatus(0, false, 'Database Misc', 'Query failed: ', q)
                    Print(0, r.errorid, r.error)
                    if not customErrorHandling then goto dbSkipCustomErrHandling end
                end

                callback(r)

                ::dbSkipCustomErrHandling::

                DatabaseMisc.isProcessing = false
                DatabaseMisc.Pipeline(DatabaseMisc.queue)
            end)
        end
    end
}

if DATABASE_INITIALIZED then return end
local timing = SysTime()
local connection, err = tmysql.Connect('remotemysql.com', '1xxn8z7gp0', 'XqyuhbZ7tV', '1xxn8z7gp0', 3306, nil, tmysql.flags.CLIENT_MULTI_STATEMENTS, function(db)
    hook.Run('DatabaseLoaded', db, SysTime() - timing)
end)
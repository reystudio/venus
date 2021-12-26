local bit = bit
local Color = Color
local GetConVar = GetConVar
local CreateConVar = CreateConVar
local Msg = Msg
local MsgC = MsgC
local tostring = tostring
local string = string
local type = type
local next = next
local debug = debug
local table = table
local hook = hook
local MySQLite = MySQLite
local pairs = pairs
local ipairs = ipairs
local unpack = unpack
local Entity = Entity
local Player = Player
local util = util
local setmetatable = setmetatable

module('Venus', package.seeall)

include 'debug.lua'
include 'color.lua'
include 'events.lua'

include 'mysqlite.lua'
include 'database.lua'

include 'player.lua'
include 'ranks.lua'

include 'commands/base.lua'

include 'messages.lua'

function Initialize()
	RunEvent('PreLoaded')
	BindDatabase()
	RunEvent('Loaded')
end

if true then 

    -- GetConVar('venus_debuglevel'):SetInt(2)

    -- Do initialization after database is initialized
		Initialize()

    -- Print('Ololol', Entity(1), {
    --     InsideSubTable = {
    --         [5] = 'hey',
    --         sus = 'kek'
    --     }
    -- })

    -- DebugPrint(10, 'ignored print')

    -- PrintStatus(true,  'Module #1', 'Something completed successfully!')
    -- PrintStatus(false, 'Module #2', 'Error when loading module.' )
    -- PrintStatus(nil,   'Module #3', 'Some warning message' )

end

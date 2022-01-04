module('Venus', package.seeall)

include 'events.lua'
include 'debug.lua'
include 'color.lua'

RunEvent('PreLoaded')

include 'database.lua'
include 'player.lua'
include 'ranks.lua'

include 'commands/base.lua'

RunEvent('Loaded')
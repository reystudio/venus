-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- RICH CONSOLE PRINTING | beauty prints & tracebacks & debug levels hide some unnecessary messages from printing
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

module('Venus', package.seeall)

-- colors that i use in console messages
local orange = Color(255, 170, 50)
local grey = Color(160, 160, 160)
local white = color_white
local red = Color(180, 0, 0)
local green = Color(40, 180, 40)
local cyan = Color(40, 200, 200)
local lightgrey = Color(230, 230, 230)

-- prevent the creation a lot of new strings that causes using cpu time
local leftFBracket, rightFBracket = '{', '}'
local leftQBracket, rightQBracket = '[', ']'
local leftCBracket, rightCBracket = '(', ')'
local arrow = ' ➤ '
local comma = ', '
local dbglvl = 'venus_debuglevel'
local check, cross = 'Successful ✓', 'Failed ❌'
local space = ' '

-- convar to prevent printing some shit in console
local cvar = GetConVar( dbglvl )
if not cvar then cvar = CreateConVar( dbglvl, '10', FCVAR_LUA_SERVER ) end

-- (input type) tostring(input)
local function printValue(i, c)
    MsgC(grey, type(i), space, lightgrey, i )
    if c then MsgC(orange, comma) end -- prevent printing 'nil' to the console after the last value
end

-- beautiful printing table to the console
--[[
    {
        [key] = (type) input,
        [key2] =
        {
            [key12] = (type) input,
            ...
        }
    }
]]
local function printTable(tbl, step)
    step = step or 0
    MsgC(string.rep('\t', step), grey, leftFBracket, '\n')
        -- for key, value in pairs(tbl) do
        for key, value in next, tbl do
            MsgC(string.rep('\t', step + 1), grey, leftQBracket, type(key) .. ' ', red, tostring(key), grey, rightQBracket, ' = ')
            if type(value) == 'table' then
                Msg('\n')
                printTable(value, step + 1)
                Msg('\n')
                continue
            end
            printValue(value, next(tbl, key) ~= nil)
            Msg('\n')
        end
    MsgC(string.rep('\t', step), grey, rightFBracket)
end

function Print(level, ...)
    local args = {...}
    for _, content in next, args do
        if type(content) == 'table' then 
            MsgC(grey, tostring(content), orange, args[_+1] and comma or space)
            Msg('\n')
            printTable(content)
        else
            printValue(content, next(args, _) ~= nil)
        end
    end
    Msg('\n')
end

-- beautiful debug print that supports 'debug levels'
-- if cvar is lower than this print requires, it wont be shown
function DebugPrint(level, ...)
    if cvar:GetInt() < level then return end
    local trace
    local step = 1
    while not trace do
        local _trace = debug.getinfo(step)
        if _trace then trace = _trace step = step + 1
        else trace = _trace _trace = nil end
    end
    MsgC( orange, trace.short_src, red, arrow )
    Print(level, ...)
end

local resultPresets = {
    [true] = { grey, leftQBracket, green, check, grey, rightQBracket .. ' ', white },
    [false] = { grey, leftQBracket, red, cross, grey, rightQBracket .. ' ', white },
    [1] = { grey, leftQBracket, cyan, 'Note', grey, rightQBracket .. ' ', white }
}

function PrintStatus(level, result, process, msg)
    if cvar:GetInt() < level then return end
    local preset = resultPresets[result] or resultPresets[1]
    preset = table.Copy(preset)
    if process then
        table.insert(preset, 5, space .. process)
        table.insert(preset, 5, orange)
    end
    preset[#preset + 1] = msg
    preset[#preset + 1] = '\n'
    MsgC(unpack(preset))
end
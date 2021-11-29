-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- RICH CONSOLE PRINTING | beauty prints & tracebacks & debug levels hide some unnecessary messages from printing
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

module('Venus', package.seeall)

-- colors that i use in console messages
orange = Color(255, 170, 50)
grey = Color(160, 160, 160)
white = color_white
red = Color(180, 0, 0)
green = Color(40, 180, 40)
cyan = Color(40, 200, 200)
lightgrey = Color(230, 230, 230)

-- prevent the creation a lot of new strings that causes using cpu time
leftFBracket, rightFBracket = '{', '}'
leftQBracket, rightQBracket = '[', ']'
leftCBracket, rightCBracket = '(', ')'
arrow = ' ➤ '
comma = ', '
dbglvl = 'venus_debuglevel'
check, cross = 'Successful ✓', 'Failed ❌'
space = ' '

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
        MsgC(grey, leftQBracket .. '#', orange, _, grey, rightQBracket, space)
        if type(content) == 'table' then 
            MsgC(grey, tostring(content), orange, space)
            printTable(content)
            if args[_+1] then
                MsgC(orange, ',\n')
            end
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
        if _trace then
            -- trace = _trace
            step = step + 1
        else
            trace = debug.getinfo(step-2)
            _trace = nil
        end
    end
    MsgC( orange, trace.short_src, grey, ('(%i line)'):format(trace.linedefined), red, arrow )
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
        table.insert(preset, 5, space .. tostring(process))
        table.insert(preset, 5, orange)
    end
    preset[#preset + 1] = msg
    preset[#preset + 1] = '\n'
    MsgC(unpack(preset))
end
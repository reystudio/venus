-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
-- EVENTS (HOOK+)
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

module('Venus', package.seeall)

-- more simple using hooks inside admin mod
local hid = 'Venus_' -- prevent duplicating strings
function RunEvent(name, ...) return hook.Run(hid .. name, ...) end
function EventCallback(name, key, callback) hook.Add(hid .. name, key, callback) end
function RemoveEventCallback(name, key) hook.Remove(hid .. name, key) end
function GetEventCallback(name, key)
    local t = hook.GetTable()[hid .. name]
    if not t then return nil end -- no hook name
    t = t[key]
    if not t then return nil end -- no hook callback
    return t -- callback
end
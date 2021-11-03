-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- CONVERTING RGB INTO HEX AND HEX TO RGB | use it for storage in the database like varchar(6)
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

module('Venus', package.seeall)

-- converting rgb into hex to storage it in the database
local tohex = bit.tohex
function ToHex(clr)
    return ('%s%s%s'):format( tohex(clr.r, 2), tohex(clr.g, 2), tohex(clr.b, 2) )
end

local rbgPattern = '0x'
function ToRGB(hex)
    return Color(
        tonumber( rbgPattern .. string.sub(hex, 1, 2) ),
        tonumber( rbgPattern .. string.sub(hex, 3, 4) ),
        tonumber( rbgPattern .. string.sub(hex, 5, 6) ),
        255
    )
end

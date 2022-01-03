-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
-- RANKS MODULE (OBJECT-ORIENTED)
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

module('Venus', package.seeall)

local function meta_tostring(self) return ('[rank:%s]'):format(self.rank) end

local RankClass = {
    List = {},
    CreateRank = function(self, rank, color, perms, parent)
        local p = {}
        for k, v in next, perms do
            p[v] = true
        end
        local rankObj = {
            rank = rank,
            color = color,
            perms = p,
            parent = parent
        }
        setmetatable(rankObj, {
            __index = self,
            __tostring = meta_tostring
        })
        self.List[rank] = rankObj
    end,
    IsPermitted = function(self, cmd)
        -- recursive checking rank, his parents and parents of parents for permission to spell some command
        return (self.perms['*'] or self.perms[cmd] or (self.parent and (self.List[self.parent]):IsPermitted(cmd))) == true
    end,
}

function GetRank(rank) return RankClass.List[rank] end

--[[
    Basic ranks with basic permissions
]]

RankClass:CreateRank('user',        Color(200, 200, 200),   {'who','help','admin','pm'})
RankClass:CreateRank('trusted',     Color(170, 170, 200),   {'e2', 'votekick'},                                     'user')
RankClass:CreateRank('moderator',   Color(50, 200, 50),     {'goto','bring','jump','kick','ban','alert','note'},    'trusted')
RankClass:CreateRank('admin',       Color(50, 50, 200),     {'hp','armor','vote','silent'},                         'moderator')
RankClass:CreateRank('root',        Color(200, 50, 50),     {'*'},                                                  'admin')
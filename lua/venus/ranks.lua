-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
-- RANKS MODULE (OBJECT-ORIENTED)
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

module('Venus', package.seeall)

--[[
    local user = Ranks('user', 'Member', Color(255, 255, 255), {'who', 'help', 'votekick'})
    local moder = Ranks('mod', 'Moderator', Color(100, 255, 100), {'goto', 'bring', 'kick', 'ban'}, 'user')
    local admin = Ranks('admin', 'Administrator', Color(255, 100, 100), {'vote', 'restart', 'alert', 'note'}, 'mod')
    local root = Ranks('root', 'Master', Color(100, 100, 255), {'*'})

    print( moder:HasAccess( 'who' ) ) -- true
]]

local l = Ranks and Ranks.List or {}

Ranks = {
    List = l,
    HasAccess = function(self, flag)
        local perms = self.permissions
        if perms['*'] then return true end
        if perms[flag] then return true end
        if self.parent and self.List[self.parent] then return (self.List[self.parent]):HasAccess(flag) end
        return false
    end,
	CheckPriority = function(self, tRank)
		local iterRank = self
		if self.rank == iterRank.rank then return false end
		while iterRank.parent and Venus:GetRank(iterRank.parent) do
			iterRank = Venus:GetRank(iterRank.parent)
			if iterRank.rank == tRank then return false end
		end
		return true
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

function GetRank(rank) return Ranks[rank] end

Ranks = {
    {
        rank = 'user',
        name = 'Member',
        color = Color(200, 200, 200),
        perms = {'who','help','admin','pm','votekick'},
        parent = nil
    },
    {
        rank = 'mod',
        name = 'Moderator',
        color = Color(50, 200, 50),
        perms = {'goto','bring','jump','kick','ban','alert','note'},
        parent = 'user'
    },
    {
        rank = 'admin',
        name = 'Administrator',
        color = Color(200, 50, 50),
        perms = {'hp','armor','vote','silent'},
        parent = 'mod'
    },
    {
        rank = 'root',
        name = 'Master',
        color = Color(255, 160, 70),
        perms = {'*'},
        parent = nil
    }
}
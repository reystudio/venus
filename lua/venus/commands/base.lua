module('Venus', package.seeall)

local StringPattern = '["|\']'
local EscapePattern = '[\\]'
local ArgSepPattern = '[%s]'

Commands = {
	List = {},
	ParseArgs = function(str)
			local ret = {}
			local InString = false
			local strchar = ''
			local chr = ''
			local escaped = false
			for i = 1, #str do
				local char = str[i]
				if (escaped) then
					chr = chr .. char
					escaped = false
					continue
				end
				if (char:find(StringPattern) and not InString and not escaped) then
					InString = true
					strchar = char
				elseif (char:find(EscapePattern)) then
					escaped = true
					continue
				elseif (InString and char == strchar) then
					table.insert(ret, chr:Trim())
					chr = ''
					InString = false
				elseif (char:find(ArgSepPattern) and not InString) then
					if (chr ~= '') then
						table.insert(ret, chr)
						chr = ''
					end
				else
					chr = chr .. char
				end
			end
			if (chr:Trim():len() ~= 0) then
				table.insert(ret, chr)
			end
			return ret
	end,
	CreateCommand = function(self, name, description, run)
		local cmd = {
			name = name,
			description = description,
			run = run
		}
		setmetatable(cmd, {
			__tostring = function(self) return ('[cmd:%s]'):format(self.name) end,
			__call = function(self, caller, isSilent, args)
				if caller and IsValid(caller) then
					local plyVenus = CachedPlayers[caller]
					local callerRank = GetRank(plyVenus.usergroup)
					if plyVenus.perms['*'] or (callerRank:IsPermitted(self.name) and (isSilent and callerRank:IsPermitted('silent') or true)) then
						return self:run(caller, isSilent, args)
					else
						Print(0, caller, tostring(self), 'not allowed')
					end
				else
					return self:run(NULL, isSilent, args)
				end
			end
		})
		self.List[name] = cmd
	end,
}

function GetCmd(cmd) return Commands.List[cmd] end

-- Commands List

Commands:CreateCommand('goto', '<PartOfPlayerName/"Player Name"/pos(X:Y:Z)/ent(index)>', function(self, caller, isSilent, args)

	if not caller or not IsValid(caller) then Print(0, 'Server cant run ' .. tostring(self)) return end

	local target = nil

	for k, v in next, player.GetAll() do
		-- more accuracy searching the target by his name
		if string.find(v:Name(), args[1]) then target = v break end
	end

	if target and IsValid(target) then
		caller:SetPos(target:GetPos())
	else
		Print(0, 'Cant find the target.')
	end

end)

concommand.Add( 'venus', function(ply, cmd, args, argStr)
	local v_cmd = table.remove(args, 1)
	local cmdObj = GetCmd(v_cmd)
	if cmdObj then
		local isSilent = args[1] == 'silent'
		PrintStatus(0, true, 'cmd:' .. v_cmd, 'OK!')
		cmdObj(ply, table.remove(args, 1), args)
	else
		PrintStatus(0, false, 'cmd:' .. v_cmd, 'Called command not exists.')
	end
end )
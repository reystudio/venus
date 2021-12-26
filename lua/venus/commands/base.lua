module('Venus', package.seeall)

local conTag = {
	orange, '[V]', grey, arrow
}

local function msgOnCall(self, caller, silent, args)
	-- Venus.PrintStatus(0, true, self.name, ('"%s" has runned the non-existing command.'):format(caller:Name()) )
	-- Venus.Print(8, caller, args, silent)
	MsgC(unpack(conTag))
	if silent then
		MsgC(grey, '[silent] ')
	end
	local rankColor
	if not caller.VenusLoaded or not Ranks.List[caller.VenusData.rank] then
		rankColor = Ranks.List.user.color
	else
		rankColor = Ranks.List[caller.VenusData.rank].color
	end
	local argsContent = ''
	for k, v in ipairs(args) do
		if k ~= 1 then argsContent = argsContent .. ', ' end
		argsContent = argsContent .. tostring(v)
	end
	argsContent = ('[%s]'):format(argsContent)
	MsgC(rankColor, isstring(caller) and caller or caller:Name(), white, ' runs ', orange, self.name, grey, argsContent, '\n')
end

local StringPattern = '["|\']'
local EscapePattern = '[\\]'
local ArgSepPattern = '[%s]'

Commands = {
	List = {},
	Create = function(self, name, category, desc, safe, run)
		local Command = {
			name = name,
			category = category,
			desc = desc or 'No description',
			safe = safe,
			run = run
		}
		setmetatable(Command, {
			__call = function(...)
				msgOnCall(...)
				run(...)
			end,
			__tostring = function(self) return ('[cmd:%s]'):format(self.name) end
		})
		self.List[name] = Command
		return Command
	end,
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
	canSpell = function(self, isSilent, caller, target)
		if caller == 'server' then return true end
		local userRank = Venus.GetRank(caller.VenusData.rank)
		if not userRank then return false end
		if userRank:HasAccess(self.name) and (not isSilent or userRank:HasAccess('silent')) then
			if self.safe then return true end
			local be = userRank:CheckPriority(target.VenusData.rank)
			return be 
		else
			return false
		end
	end,
	noPermsMessage = 'Sorry, but you have no rights to call this command.',
	notifyNoPermissions = function(self, caller)
		Venus.CmdFeedback(caller, tostring(self), { self.noPermsMessage })	
	end
}

setmetatable(Commands, {
    __call = function(self, cmd)
        return self.List[cmd] or self.List.notfound
    end
})

Commands:Create('notfound', 'General', 'does nothing', true, function(self, caller, silent, args)

end)

Commands:Create('who', 'General', 'Shows players on the server and their ranks.', true, function(self, caller, silent, args)

end)

Commands:Create('kick', 'Administrative', 'Kicks the player off the server', false, function(self, caller, silent, args)

end)

Print(5, 'Loading commands module complete.')

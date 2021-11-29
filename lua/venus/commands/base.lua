module('Venus', package.seeall)

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
            __call = run,
            __tostring = function(self) return self.name end
        })
        self.List[name] = Command
        return Command
    end
}

setmetatable(Commands, {
    __call = function(self, cmd)
        return self.List[cmd] or self.List.notfound
    end
})

--

Commands:Create('notfound', 'General', 'does nothing', true, function(self, caller, args, silent)
    Venus.PrintStatus(0, true, self.name, ('"%s" has runned the non-existing command.'):format(caller:Name()) )
    Venus.Print(8, caller, args, silent)
end)
module('Venus', package.seeall)

util.AddNetworkString('venus.msg')

function CmdFeedback(receiver, tag, msg)
	local realTag = {Color(255, 170, 50), '≈ ' .. (tag and (tag .. ' ') or ''), Color(230, 230, 230)}
	table.Add(realTag, msg)
	net.Start('venus.msg')
		net.WriteTable(realTag)
	net.Send(receiver)
end
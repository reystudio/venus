net.Receive('venus.msg', function()
	chat.AddText(unpack(net.ReadTable()))
end)
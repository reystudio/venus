if SERVER then
	include 'venus/core.lua'
end

if SERVER then
	AddCSLuaFile 'venus/client/client.lua'
end

include 'venus/client/client.lua'

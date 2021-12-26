if SERVER then
    AddCSLuaFile 'msg.lua'
    print('Loading clientside')
else
    include 'msg.lua'
    print('Clientside initialized')
end
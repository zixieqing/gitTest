--[[
 * author : kaishiqi
 * descpt : local chat server
]]
local BaseServer = require('interfaces.server.BaseServer')
local ChatServer = class('ChatServer', BaseServer)


function ChatServer:ctor()
    self.super.ctor(self, 'ChatServer', Platform.ChatTCPPort)
end


function ChatServer:onReceiveData_(clientKey, cmdId, data)
    self.super.onReceiveData_(self, clientKey, cmdId, data)

    -- 5010 世界聊天人数
    if cmdId == NetCmd.RequestWorldRoomsMessage then
        -- TODO
    end
end


return ChatServer

--[[
 * author : kaishiqi
 * descpt : local base server
]]
local PacketBuffer = require('cocos.framework.PacketBuffer')
local zlib         = require('zlib')
local socket       = require('socket')
local BaseServer   = class('BaseServer')
require('Frame.NetCmd')

local SALT_KEY = 'cf1251bc88264d9ec4061cef7214d372'


-------------------------------------------------
-- life cycly

function BaseServer:ctor(name, port)
    self.name_ = name or 'BaseServer'
    self.host_ = '127.0.0.1'
    self.port_ = checkint(port)
end


function BaseServer:launch()
    if self.isLaunch_ then return end
    self.isLaunch_ = true
    self.server_   = socket.try(socket.bind(self.host_, self.port_))
    self.server_:settimeout(0)  -- 设置超时时间为0，这样就可以为非阻塞
    self:serverLog('Local server started.', self.host_ .. ':' .. self.port_)

    self.clientDataMap_   = {}
    self.mainLoopHandler_ = scheduler.scheduleUpdateGlobal(handler(self, self.onMainLoop_))
end


function BaseServer:destroy()
    if self.mainLoopHandler_ then
        scheduler.unscheduleGlobal(self.mainLoopHandler_)
        self.mainLoopHandler_ = nil
    end
    if self.server_ then
        self.server_:close()
        self.server_ = nil
    end
    self.isLaunch_      = false
    self.clientDataMap_ = nil
    self:serverLog('Local server destroy.', self.host_ .. ':' .. self.port_)
end


-------------------------------------------------
-- public method

function BaseServer:getLinkCount()
    return #table.keys(self.clientDataMap_ or {})
end


function BaseServer:serverLog(...)
    print(string.format('[%s]', self.name_), ...)
end


function BaseServer:sendAllClient(cmdId, data, excludeClientKey)
    for key, cdata in pairs(self.clientDataMap_ or {}) do
        if excludeClientKey ~= key then
            self:sendClientAt(key, cmdId, data)
        end
    end
end


function BaseServer:sendClientAt(clientKey, cmdId, data)
    local clientData = checktable(self.clientDataMap_)[clientKey]
    if not clientData then return end
    if cmdId ~= NetCmd.RequestPing then
        self:serverLog(string.fmt('%1 send cmd %2', clientKey, cmdId), tableToString(data or {}))
    end
    table.insert(clientData.queue, self:generateBuffer_(cmdId, data))
end


-------------------------------------------------
-- private method

function BaseServer:generateSign_(t)
    local retString = t['rand'] .. SALT_KEY
    return crypto.md5(retString)
end


function BaseServer:generateBuffer_(cmdId, data)
    local tableData = {}
    if data then table.merge(tableData, data) end
    tableData['rand'] = json.encode(tableData)
    tableData['sign'] = self:generateSign_(tableData)
    return PacketBuffer.createPacket(cmdId, json.encode(tableData))
end


-------------------------------------------------
-- handler

function BaseServer:onMainLoop_()

    -- check client connect
    local control = self.server_:accept()
    if control and control:getpeername() then
        local clientKey = table.concat({control:getpeername()}, '_')
        control:settimeout(0)
        self.clientDataMap_[clientKey] = {
            clientKey = clientKey,
            client    = control,
            buffer    = PacketBuffer.new(),
            queue     = {}
        }
        self:serverLog('A client connect! ', clientKey, 'current clents:', self:getLinkCount())
        self:onClientConnect_(clientKey, control)
    end

    -- update each client
    for key, cdata in pairs(self.clientDataMap_ or {}) do
        local client = cdata.client
        local buffer = cdata.buffer
        local queue  = cdata.queue

        -- check client status
        local __body, __status, __partial = client:receive(512)
        if __status == 'closed' then
            self.clientDataMap_[key] = nil
            client:close()
            self:serverLog('A client disconnect! ', key, 'current clents:', self:getLinkCount())
            self:onClientDisconnect_(key, client)

        else
            -- send queue data
            for i,v in ipairs(queue) do
                client:send(v:getPack())
            end
            cdata.queue = {}

            -- check receive info
            if  (__body and string.len(__body) == 0) or
                (__partial and string.len(__partial) == 0) then
                break
            end
            if __body and __partial then __body = __body .. __partial end

            -- receive data
            local __msgs = buffer:parsePackets(__body or __partial)
            for _, __msg in ipairs(__msgs) do
                if __msg.body and type(__msg.body) == 'string' then
                    local cdata = zlib.inflate()(__msg.body)
                    local jdata = json.decode(cdata)
                    self:onReceiveData_(key, __msg.command, jdata)
                end
            end
            
        end
    end
    -- socket.sleep(5)
end


function BaseServer:onClientConnect_(clientKey, control)
end
function BaseServer:onClientDisconnect_(clientKey, control)
end


function BaseServer:onReceiveData_(clientKey, cmdId, data)
    -- universal handle
    -- self:serverLog('A client receive Data', clientKey, cmdId)

    -- 1004 用来发送连接后的第一个数据验证包
    if cmdId == NetCmd.RequestID then
        self:sendClientAt(clientKey, NetCmd.RequestID)

    -- 1999 ping命令
    elseif cmdId == NetCmd.RequestPing then
        self:sendClientAt(clientKey, NetCmd.RequestPing)

    -- 1100 错误发生
    elseif cmdId == NetCmd.Error then
        self:sendClientAt(clientKey, NetCmd.Disconnect, data)

    -- 1002 断开连接
    elseif cmdId == NetCmd.Disconnect then
        self:sendClientAt(clientKey, NetCmd.Disconnect)

    end
end


return BaseServer

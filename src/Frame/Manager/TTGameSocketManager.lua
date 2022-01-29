--[[
 * author : kaishiqi
 * descpt : 打牌游戏socket管理者
]]
local luasocket           = require('socket')
local TcpProtocol         = require('Frame.TcpProtocol')
local BaseManager         = require('Frame.Manager.ManagerBase')
local TTGameSocketManager = class('TTGameSocketManager', BaseManager)

local UPDATE_INTERVAL = 0.1                  -- 更新检测间隔（秒）
local SEND_PING_DELAY = UPDATE_INTERVAL * 10 -- ping发送间隔（x次更新检测后）
local CONNECT_TIMEOUT = SEND_PING_DELAY * 4  -- 检测连接超时（x次Ping检测后）
local RECONNECT_COUNT = 10                   -- 重连尝试次数
-- local NOT_RESPONDING  = 30                   -- 服务器未应答时间（有些环境网络实在巨差，只能关掉超时机制，不然永远连不上）

local SIGNAL_NAME_MAP = {
    [NetCmd.TTGAME_NET_LINK]              = {catchError = false, sglName = SGL.TTGAME_SOCKET_NET_LINK},              -- 网络握手 10999
    [NetCmd.TTGAME_NET_SYNC]              = {catchError = false, sglName = SGL.TTGAME_SOCKET_NET_SYNC},              -- 网络同步 10021
    [NetCmd.TTGAME_GAME_MATCHED_NOTICE]   = {catchError = false, sglName = SGL.TTGAME_SOCKET_GAME_MATCHED_NOTICE},   -- 匹配通知 10008
    [NetCmd.TTGAME_GAME_ABANDON]          = {catchError = false, sglName = SGL.TTGAME_SOCKET_GAME_ABANDON},          -- 主动认输 10017
    [NetCmd.TTGAME_GAME_RESULT_NOTICE]    = {catchError = false, sglName = SGL.TTGAME_SOCKET_GAME_RESULT_NOTICE},    -- 结果通知 10016
    [NetCmd.TTGAME_GAME_PLAY_CARD]        = {catchError = false, sglName = SGL.TTGAME_SOCKET_GAME_PLAY_CARD},        -- 打牌操作 10014
    [NetCmd.TTGAME_GAME_PLAY_CARD_NOTICE] = {catchError = false, sglName = SGL.TTGAME_SOCKET_GAME_PLAY_CARD_NOTICE}, -- 打牌通知 10015
    [NetCmd.TTGAME_PVE_ENTER]             = {catchError = true , sglName = SGL.TTGAME_SOCKET_PVE_ENTER},             -- pve进入 10001
    [NetCmd.TTGAME_PVP_MATCH]             = {catchError = true , sglName = SGL.TTGAME_SOCKET_PVP_MATCH},             -- pvp匹配 10007
    [NetCmd.TTGAME_ROOM_ENTER_NOTICE]     = {catchError = false, sglName = SGL.TTGAME_SOCKET_ROOM_ENTER_NOTICE},     -- 进房通知 10004
    [NetCmd.TTGAME_ROOM_ENTER]            = {catchError = true , sglName = SGL.TTGAME_SOCKET_ROOM_ENTER},            -- 房间进入 10003
    [NetCmd.TTGAME_ROOM_CREATE]           = {catchError = true , sglName = SGL.TTGAME_SOCKET_ROOM_CREATE},           -- 房间创建 10002
    [NetCmd.TTGAME_ROOM_READY]            = {catchError = true , sglName = SGL.TTGAME_SOCKET_ROOM_READY},            -- 房间准备 10005
    [NetCmd.TTGAME_ROOM_READY_NOTICE]     = {catchError = false, sglName = SGL.TTGAME_SOCKET_ROOM_READY_NOTICE},     -- 准备通知 10006
    [NetCmd.TTGAME_ROOM_LEAVE]            = {catchError = true , sglName = SGL.TTGAME_SOCKET_ROOM_LEAVE},            -- 房间离开 10019
    [NetCmd.TTGAME_ROOM_LEAVE_NOTICE]     = {catchError = false, sglName = SGL.TTGAME_SOCKET_ROOM_LEAVE_NOTICE},     -- 离开通知 10020
    [NetCmd.TTGAME_ROOM_MOOD]             = {catchError = false, sglName = SGL.TTGAME_SOCKET_ROOM_MOOD},             -- 发送心情 10009
    [NetCmd.TTGAME_ROOM_MOOD_NOTICE]      = {catchError = false, sglName = SGL.TTGAME_SOCKET_ROOM_MOOD_NOTICE},      -- 心情通知 10010
}

-- 忽略的同步命令，比如聊天等
local IGNORE_SYNC_MAP = {
    [NetCmd.TTGAME_ROOM_MOOD]        = true, -- 房间发送心情 10009
    [NetCmd.TTGAME_ROOM_MOOD_NOTICE] = true, -- 房间心情通知 10010
}

local SIGNAL_STATUS_MAP = {
    CONNECTED  = SGL.TTGAME_SOCKET_CONNECTED,  -- 收到 连接验证命令
    DISCONNECT = SGL.TTGAME_SOCKET_UNEXPECTED, -- 收到 连接断线命令
    UNEXPECTED = SGL.TTGAME_SOCKET_UNEXPECTED, -- 收到 发生错误命令
    MISSING    = SGL.TTGAME_SOCKET_UNEXPECTED, -- 尝试过多，连接丢失
}
-- TEAM_TODO 进入后台记录时间戳，后台唤起比较时间戳，超过一定时间范围则。。。


-------------------------------------------------
-- life cycle
TTGameSocketManager.instances = {}


function TTGameSocketManager.GetInstance(key)
	key = key or 'TTGameSocketManager'
	if TTGameSocketManager.instances[key] == nil then
		TTGameSocketManager.instances[key] = TTGameSocketManager.new(key)
	end
	return TTGameSocketManager.instances[key]
end


function TTGameSocketManager.Destroy(key)
	key = key or 'TTGameSocketManager'
	local instance = TTGameSocketManager.instances[key]
	if instance then
        instance:release() --释放资源
        TTGameSocketManager.instances[key] = nil
	end
end


function TTGameSocketManager:ctor(key)
    key = key or 'TTGameSocketManager'
    self.super.ctor(self)
    
	if TTGameSocketManager.instances[key] == nil then
        funLog(Logger.INFO,  key .. ':ctor()')
        TTGameSocketManager.instances[key] = self
        self:initial()
    else
		funLog(Logger.INFO,  '已注册TTGameSocketManager类型')
	end
end


function TTGameSocketManager:initial()
    self.reconnectNum_  = 0                    -- 尝试重新连接的次数
    self.isPauseUpdate_ = true                 -- 是否 暂停更新检测
    self.isSendedPing_  = false                -- 是否 已发送ping命令
    self.startPingTime_ = luasocket.gettime()  -- 开始ping的时间戳
    self.lastPingTime_  = self.startPingTime_  -- 上次ping的时间戳
    self.lastSendTime_  = 0                    -- 最后一次发送的时间戳
    self.socketClient_  = TcpProtocol.new('TTGameSocket', logInfo.Types.TEAM)
    self.updateHandler_ = scheduler.scheduleGlobal(handler(self, self.onUpdateHandler_), UPDATE_INTERVAL)
end


function TTGameSocketManager:release(isQuick)
    if self.updateHandler_ then
        scheduler.unscheduleGlobal(self.updateHandler_)
        self.updateHandler_ = nil
    end
    if self.socketClient_ then
        self.socketClient_:Release(isQuick)
        self.socketClient_ = nil
    end
    self:setShowLoading(false)
    self:setShowNetworkWeak(false)
end


-------------------------------------------------
-- get / set

function TTGameSocketManager:isShowLoading()
    return self.isShowLoading_
end
function TTGameSocketManager:setShowLoading(isShow)
    if self.isShowLoading_ == isShow then return end
    if isShow then
        self:GetGameManager():ShowLoadingView()
    else
        self:GetGameManager():RemoveLoadingView()
    end
    self.isShowLoading_ = isShow == true
end


function TTGameSocketManager:isShowNetworkWeak()
    return self.isShowNetworkWeak_
end
function TTGameSocketManager:setShowNetworkWeak(isShow)
    if self.isShowNetworkWeak_ == isShow then return end
    if isShow then
        self:GetGameManager():ShowNetworkWeakView()
    else
        self:GetGameManager():RemoveNetworkWeakView()
    end
    self.isShowNetworkWeak_ = isShow == true
end


-------------------------------------------------
-- public method

function TTGameSocketManager:connect(host, port)
    self:disConnect(true)

    self.connectHost_   = host
    self.connectPort_   = port
    self.reconnectNum_  = self.reconnectNum_ + 1
    self.isPauseUpdate_ = false

    self:setShowLoading(true)
    self.socketClient_:Connect(host, port)
    self:printLog_('开始连接：' .. tostring(self.reconnectNum_))
end


function TTGameSocketManager:disConnect(isRetry)
    self.isPauseUpdate_ = true

    self.socketClient_:Disconnect()
    self:setShowNetworkWeak(false)
    if not isRetry then self:setShowLoading(false) end
    self:printLog_('终止连接' .. (isRetry and '，并重连' or ''))
end


function TTGameSocketManager:isConnected()
    return self.socketClient_ and self.socketClient_.socketConnected == true or false
end


function TTGameSocketManager:sendData(cmdId, data)
    if self:isConnected() then
        local buffer = self.socketClient_:BeginSend(cmdId, data)
        self.socketClient_:SendTcpPacket(buffer)
        if cmdId ~= NetCmd.RequestPing then
            if not IGNORE_SYNC_MAP[cmdId] then
                self.lastSendTime_ = luasocket.gettime()
                self:setShowLoading(true)
            end
            self:printLog_('发送了命令：' .. cmdId, data)
        end
    else
        self:GetUIManager():ShowInformationTips(string.fmt(__('网络已断开，_id_指令发送失败'), {_id_ = cmdId}))
        self:printLog_('未连接的状态下，发送了命令：' .. cmdId, data)
    end
end


-------------------------------------------------
-- private method

function TTGameSocketManager:printLog_(logText, ...)
    local logString = tostring(logText)
    local args = {...}
    if #args > 0 then
        logString = logString .. '\n' .. tableToString(args)
    end
    funLog(Logger.INFO, '##_[TTGameSocket]_' .. logString)
    -- funLog(Logger.ERROR, '##_[TTGameSocket]_' .. logString)
end


function TTGameSocketManager:updateSocketStatus_()
    if self.reconnectNum_ > RECONNECT_COUNT then
        self.startPingTime_ = luasocket.gettime()
        self.lastPingTime_  = self.startPingTime_
        self.reconnectNum_  = 0
        self:onReconnectOver_()
        
    elseif self.startPingTime_ - self.lastPingTime_ > CONNECT_TIMEOUT then
        self:printLog_('连接响应超时了')
        self.startPingTime_ = luasocket.gettime()
        self.lastPingTime_  = self.startPingTime_
        self:connect(self.connectHost_, self.connectPort_)
        
    else
        self.startPingTime_ = luasocket.gettime()

        if self:isConnected() then
            self.reconnectNum_ = 0

            -- check receive
            local hasNext, packet = self.socketClient_:ReceivePacket()
            while hasNext and packet do
                self:analysePacket_(packet)
                if self.socketClient_ then
                    hasNext, packet = self.socketClient_:ReceivePacket()
                else
                    break
                end
            end

            -- check ping
            if self.startPingTime_ - self.lastPingTime_ > SEND_PING_DELAY then
                if self.isSendedPing_ then
                    self:setShowNetworkWeak(true)
                else
                    self.isSendedPing_ = true
                end
                self.lastPingTime_ = self.startPingTime_
                self:sendData(NetCmd.RequestPing)
            end

            -- check server not responding
            if NOT_RESPONDING then
                if self.lastSendTime_ > 0 and self.startPingTime_ - self.lastSendTime_ > NOT_RESPONDING then
                    if self:isShowLoading() then
                        self:setShowLoading(false)
                    end
                    self.lastSendTime_ = 0
                    self:GetUIManager():ShowInformationTips(__('服务器长时间未应答'))
                end
            end
        end

    end
end


function TTGameSocketManager:analysePacket_(packet)
    if not packet then return end
    local cmdId   = checkint(packet.cmd)
    local cmdData = checktable(packet.data)

    -- 1004 用来发送连接后的第一个数据验证包
    if cmdId == NetCmd.RequestID then
        self:onConnected_()

    -- 1999 ping命令
    elseif cmdId == NetCmd.RequestPing then
        self:onReceivePing_()

    -- 1100 错误发生
    elseif cmdId == NetCmd.Error then
        self:onReceiveError_(cmdData.errmsg, cmdData.errcode)

    -- 1002 断开连接
    elseif cmdId == NetCmd.Disconnect then
        self:onDisconnect_()

    else
        -- check return error
        local errcode = checkint(cmdData.errcode)
        local errmsg  = tostring(cmdData.errmsg)

        if not IGNORE_SYNC_MAP[cmdId] then
            self.lastSendTime_ = 0
            self:setShowLoading(false)
        end

        -- errcode: 其他情况
        if errcode ~= 0 then
            if SIGNAL_NAME_MAP[cmdId] and SIGNAL_NAME_MAP[cmdId].catchError then
                app.uiMgr:ShowInformationTips(errmsg)
                cmdData.data         = cmdData.data or {}
                cmdData.data.errcode = errcode
                cmdData.data.errmsg  = errmsg
                self:GetFacade():DispatchObservers(SIGNAL_NAME_MAP[cmdId].sglName, cmdData.data)
            else
                self:onReceiveError_(errmsg, cmdData.errcode)
            end
        else
            if SIGNAL_NAME_MAP[cmdId] and SIGNAL_NAME_MAP[cmdId].sglName then
                self:GetFacade():DispatchObservers(SIGNAL_NAME_MAP[cmdId].sglName, cmdData.data)
            else
                self:printLog_('未处理的返回命令' .. cmdId, cmdData)
            end
        end
    end
end


-------------------------------------------------
-- handler

function TTGameSocketManager:onUpdateHandler_(dt)
    if self.isPauseUpdate_ then return end
    if not self.socketClient_ then return end
    self:updateSocketStatus_()
end


function TTGameSocketManager:onConnected_()
    self:printLog_('收到连接验证命令' .. NetCmd.RequestID)

    self:setShowLoading(false)
    self.socketClient_:VerifyRequestID(NetCmd.RequestID)

    self:GetFacade():DispatchObservers(SIGNAL_STATUS_MAP.CONNECTED)
end


function TTGameSocketManager:onDisconnect_()
    self:printLog_('收到断开连接命令' .. NetCmd.Disconnect)
    self:disConnect()
    
    local sendData = {errText = __('战牌连接收到断开通知')}
    self:GetFacade():DispatchObservers(SIGNAL_STATUS_MAP.DISCONNECT, sendData)
end


function TTGameSocketManager:onReceivePing_()
    -- self:printLog_(string.format('收到ping命令，间隔毫秒：%0.3f', self.startPingTime_ - self.lastPingTime_))
    self.isSendedPing_ = false
    if self:isShowNetworkWeak() then
        self:setShowNetworkWeak(false)
    end
end


function TTGameSocketManager:onReceiveError_(errText, errcode)
    self:printLog_('收到错误命令' .. NetCmd.Error, errText)
    self:setShowLoading(false)
    -- 此处不处理断开 错误代码为正不断线
    -- self:disConnect()

    local sendData = {errText = tostring(errText), errcode = checkint(errcode)}
    self:GetFacade():DispatchObservers(SIGNAL_STATUS_MAP.UNEXPECTED, sendData)
end


function TTGameSocketManager:onReconnectOver_()
    self:printLog_('达到最大重连次数，终止尝试重连')
    self:disConnect()
    
    local sendData = {errText = __('由于网络不稳定，当前战牌连接已断开')}
    self:GetFacade():DispatchObservers(SIGNAL_STATUS_MAP.MISSING, sendData)
end


return TTGameSocketManager

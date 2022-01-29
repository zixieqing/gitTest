--[[
 * author : kaishiqi
 * descpt : 组队战socket管理者
]]
local TcpProtocol = require('Frame.TcpProtocol')
local BaseManager = require('Frame.Manager.ManagerBase')
local socket = require('socket')
local TeamSocketManager = class('TeamSocketManager', BaseManager)

TeamSocketManager.instances = {}

local UPDATE_DELAY    = 0.1                -- 更新检测间隔
local PING_DELAY      = UPDATE_DELAY * 32   -- ping发送间隔（x次更新检测后）
local PING_TIMEOUT    = PING_DELAY   * 4   -- 检测ping超时（x次Ping检测后）
local RECONNECT_COUNT = 10                 -- 重连尝试次数

local socket = require('socket')

local SIGNALNAME_MAP = {
    [NetCmd.TEAM_BOSS_JOIN_TEAM]           = SIGNALNAMES.TEAM_BOSS_SOCKET_JOIN_TEAM,           -- 参与组队
    [NetCmd.TEAM_BOSS_MEMBER_NOTICE]       = SIGNALNAMES.TEAM_BOSS_SOCKET_MEMBER_NOTICE,       -- 成员变动
    [NetCmd.TEAM_BOSS_CARD_CHANGE]         = SIGNALNAMES.TEAM_BOSS_SOCKET_CARD_CHANGE,         -- 卡牌变更
    [NetCmd.TEAM_BOSS_CARD_NOTICE]         = SIGNALNAMES.TEAM_BOSS_SOCKET_CARD_NOTICE,         -- 卡牌通知
    [NetCmd.TEAM_BOSS_CSKILL_CHANGE]       = SIGNALNAMES.TEAM_BOSS_SOCKET_CSKILL_CHANGE,       -- 主角技变更
    [NetCmd.TEAM_BOSS_CSKILL_NOTICE]       = SIGNALNAMES.TEAM_BOSS_SOCKET_CSKILL_NOTICE,       -- 主角技通知
    [NetCmd.TEAM_BOSS_READY_CHANGE]        = SIGNALNAMES.TEAM_BOSS_SOCKET_READY_CHANGE,        -- 准备变更
    [NetCmd.TEAM_BOSS_READY_NOTICE]        = SIGNALNAMES.TEAM_BOSS_SOCKET_READY_NOTICE,        -- 准备通知
    [NetCmd.TEAM_BOSS_ENTER_BATTLE]        = SIGNALNAMES.TEAM_BOSS_SOCKET_ENTER_BATTLE,        -- 进入战斗
    [NetCmd.TEAM_BOSS_ENTER_NOTICE]        = SIGNALNAMES.TEAM_BOSS_SOCKET_ENTER_NOTICE,        -- 进入通知
    [NetCmd.TEAM_BOSS_KICK_MEMBER]         = SIGNALNAMES.TEAM_BOSS_SOCKET_KICK_MEMBER,         -- 踢出成员
    [NetCmd.TEAM_BOSS_KICK_NOTICE]         = SIGNALNAMES.TEAM_BOSS_SOCKET_KICK_NOTICE,         -- 踢人通知

    [NetCmd.TEAM_BOSS_BATTLE_RESULT]       = SIGNALNAMES.TEAM_BOSS_SOCKET_BATTLE_RESULT,       -- 战斗结束
    [NetCmd.TEAM_BOSS_BATTLE_RESULT_NOTICE]= SIGNALNAMES.TEAM_BOSS_SOCKET_BATTLE_RESULT_NOTICE,-- 战斗结束通知

    [NetCmd.TEAM_BOSS_LOADING_OVER]        = SIGNALNAMES.TEAM_BOSS_SOCKET_LOADING_OVER,        -- 队员加载完毕
    [NetCmd.TEAM_BOSS_LOADING_OVER_NOTICE] = SIGNALNAMES.TEAM_BOSS_SOCKET_LOADING_OVER_NOTICE, -- 队员加载完毕通知

    [NetCmd.TEAM_BOSS_BOSS_CHANGE]         = SIGNALNAMES.TEAM_BOSS_SOCKET_BOSS_CHANGE,         -- BOSS变更
    [NetCmd.TEAM_BOSS_BOSS_NOTICE]         = SIGNALNAMES.TEAM_BOSS_SOCKET_BOSS_NOTICE,         -- BOSS通知
    [NetCmd.TEAM_BOSS_EXIT_CHANGE]         = SIGNALNAMES.TEAM_BOSS_SOCKET_EXIT_CHANGE,         -- 退出组队
    [NetCmd.TEAM_BOSS_EXIT_NOTICE]         = SIGNALNAMES.TEAM_BOSS_SOCKET_EXIT_NOTICE,         -- 退出通知
    [NetCmd.TEAM_BOSS_CAPTAIN_CHANGE]      = SIGNALNAMES.TEAM_BOSS_SOCKET_CAPTAIN_CHANGE,      -- 队长变更
    [NetCmd.TEAM_BOSS_CAPTAIN_NOTICE]      = SIGNALNAMES.TEAM_BOSS_SOCKET_CAPTAIN_NOTICE,      -- 队长通知
    [NetCmd.TEAM_BOSS_PASSWORD_CHANGE]     = SIGNALNAMES.TEAM_BOSS_SOCKET_PASSWORD_CHANGE,     -- 密码变更
    [NetCmd.TEAM_BOSS_PASSWORD_NOTICE]     = SIGNALNAMES.TEAM_BOSS_SOCKET_PASSWORD_NOTICE,     -- 密码通知
    [NetCmd.TEAM_BOSS_ATTEND_TIMES_BUY]    = SIGNALNAMES.TEAM_BOSS_SOCKET_ATTEND_TIMES_BUY,    -- 参与次数购买
    [NetCmd.TEAM_BOSS_ATTEND_TIMES_BOUGHT] = SIGNALNAMES.TEAM_BOSS_SOCKET_ATTEND_TIMES_BOUGHT, -- 次数通知成功
    [NetCmd.TEAM_BOSS_TEAM_DISSOLVED]      = SIGNALNAMES.TEAM_BOSS_SOCKET_TEAM_DISSOLVED,      -- 队伍解散通知
    [NetCmd.TEAM_BOSS_TEAM_RECOVER]        = SIGNALNAMES.TEAM_BOSS_SOCKET_TEAM_RECOVER,        -- 房间取消解散
    [NetCmd.TEAM_BOSS_BATTLE_OVER]         = SIGNALNAMES.TEAM_BOSS_SOCKET_BATTLE_OVER,         -- 组队战斗结束
    [NetCmd.TEAM_BOSS_BATTLE_OVER_NOTICE]  = SIGNALNAMES.TEAM_BOSS_SOCKET_BATTLE_OVER_NOTICE,  -- 组队战斗全员结束通知
    [NetCmd.TEAM_BOSS_CHOOSE_REWARD]       = SIGNALNAMES.TEAM_BOSS_SOCKET_CHOOSE_REWARD,       -- 战斗结束选择奖励
    [NetCmd.TEAM_BOSS_CHOOSE_REWARD_NOTICE]= SIGNALNAMES.TEAM_BOSS_SOCKET_CHOOSE_REWARD_NOTICE -- 战斗结束选择奖励通知
}
-- TEAM_TODO 进入后台记录时间戳，后台唤起比较时间戳，超过一定时间范围则。。。


-------------------------------------------------
-- life cycle

function TeamSocketManager.GetInstance(key)
	key = key or 'TeamSocketManager'
	if TeamSocketManager.instances[key] == nil then
		TeamSocketManager.instances[key] = TeamSocketManager.new(key)
	end
	return TeamSocketManager.instances[key]
end


function TeamSocketManager.Destroy(key)
	key = key or 'TeamSocketManager'
	local instance = TeamSocketManager.instances[key]
	if instance then
        instance:release() --释放资源
        TeamSocketManager.instances[key] = nil
	end
end


function TeamSocketManager:ctor(key)
    key = key or 'TeamSocketManager'
    self.super.ctor(self)

	if TeamSocketManager.instances[key] == nil then
        funLog(Logger.INFO,  key .. ':ctor()')
        TeamSocketManager.instances[key] = self
        self:initial()
    else
		funLog(Logger.INFO,  '已注册TeamSocketManager类型')
	end
end


function TeamSocketManager:initial()
    self.socket_        = TcpProtocol.new('TeamSocket', logInfo.Types.TEAM)
    self.isPause_       = true                 -- 是否暂停更新检测
    self.reconnectNum_  = 0                    -- 尝试重新连接的次数
    self.startPingTime_ = socket.gettime()     -- 开始ping的时间戳
    self.lastPingTime_  = self.startPingTime_  -- 上一次ping的时间戳
    self.isSendedPing_  = false                -- 是否发送了ping命令
    self.updateHandler_ = scheduler.scheduleGlobal(handler(self, self.onUpdate_), UPDATE_DELAY)
end


function TeamSocketManager:release()
	if self.updateHandler_ then
        scheduler.unscheduleGlobal(self.updateHandler_)
        self.updateHandler_ = nil
    end
	self.socket_:Release()
    self:setShowLoading(false)
    self:setShowNetworkWeak(false)
end


-------------------------------------------------
-- get / set

function TeamSocketManager:isShowLoading()
    return self.isShowLoading_
end
function TeamSocketManager:setShowLoading(isShow)
    if self.isShowLoading_ == isShow then return end
    if isShow then
        self:GetGameManager():ShowLoadingView()
    else
        self:GetGameManager():RemoveLoadingView()
    end
    self.isShowLoading_ = isShow == true
end


function TeamSocketManager:isShowNetworkWeak()
    return self.isShowNetworkWeak_
end
function TeamSocketManager:setShowNetworkWeak(isShow)
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

function TeamSocketManager:connect(host, port)
    self:disConnect(true)

    self.host_         = host
    self.port_         = port
    self.isPause_      = false
    self.reconnectNum_ = self.reconnectNum_ + 1

    self:setShowLoading(true)
    self.socket_:Connect(host, port)
    self:printLog_('开始连接')
end


function TeamSocketManager:disConnect(isRetry)
    self.isPause_ = true

    self.socket_:Disconnect()
    self:setShowNetworkWeak(false)
    if not isRetry then self:setShowLoading(false) end
    self:printLog_('终止连接' .. (isRetry and '，并重连' or ''))
end


function TeamSocketManager:isConnected()
    return self.socket_ and self.socket_.socketConnected == true or false
end


function TeamSocketManager:sendData(cmdId, data)
    if self:isConnected() then
        local buffer = self.socket_:BeginSend(cmdId, data)
        self.socket_:SendTcpPacket(buffer)
        if cmdId ~= NetCmd.RequestPing then
            self:printLog_('发送了命令' .. cmdId, data)
        end
    else
        self:GetUIManager():ShowInformationTips(__('网络不稳定，指令发送失败'))
        self:printLog_('未连接的状态下，发送了命令' .. cmdId, data)
    end
end


-------------------------------------------------
-- private method

function TeamSocketManager:printLog_(logText, ...)
    local logString = tostring(logText)
    local args = {...}
    if #args > 0 then
        logString = logString .. '\n' .. tableToString(args)
    end
    funLog(Logger.INFO, '##_[TeamSocket]_' .. logString)
end


function TeamSocketManager:updateSocketStatus_()
    if self.reconnectNum_ > RECONNECT_COUNT then
        self:printLog_('达到最大尝试次数')
        self.startPingTime_ = socket.gettime()
        self.lastPingTime_  = self.startPingTime_
        self.reconnectNum_  = 0
        self:onReconnectOver_()

    elseif self.startPingTime_ - self.lastPingTime_ > PING_TIMEOUT then
        self:printLog_('ping超时了，在接次数' .. self.reconnectNum_)
        self.startPingTime_ = socket.gettime()
        self.lastPingTime_  = self.startPingTime_
        self:connect(self.host_, self.port_)

    else
        self.startPingTime_ = socket.gettime()

        if self:isConnected() then
            self.reconnectNum_ = 0

            -- check receive
            local hasNext, packet = self.socket_:ReceivePacket()
            while hasNext and packet do
                self:analysePacket_(packet)
                if self.socket_ then
                    hasNext, packet = self.socket_:ReceivePacket()
                else
                    break
                end
            end

            -- check ping
            if self.startPingTime_ - self.lastPingTime_ > PING_DELAY then
                if self.isSendedPing_ then
                    self:setShowNetworkWeak(true)
                else
                    self.isSendedPing_ = true
                end
                self.lastPingTime_ = self.startPingTime_
                self:sendData(NetCmd.RequestPing)
            end
        end

    end
end


function TeamSocketManager:analysePacket_(packet)
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

        -- errcode: -1 该组队已结束
        if errcode == -1 then
            self:onReceiveError_(__('该组队已结束'), cmdData.errcode)

        -- errcode: 其他情况
        elseif errcode ~= 0 then
            self:onReceiveError_(errmsg, cmdData.errcode)

        else
            if SIGNALNAME_MAP[cmdId] then
                self:GetFacade():DispatchObservers(SIGNALNAME_MAP[cmdId], cmdData)
            else
                self:printLog_('未处理的返回命令' .. cmdId, cmdData)
            end
        end
    end
end


-------------------------------------------------
-- handler

function TeamSocketManager:onUpdate_(dt)
    if self.isPause_ then return end
    self:updateSocketStatus_()
end


function TeamSocketManager:onConnected_()
    self:printLog_('收到连接验证命令' .. NetCmd.RequestID)

    self:setShowLoading(false)
    self.socket_:VerifyRequestID(NetCmd.RequestID)

    self:GetFacade():DispatchObservers(SIGNALNAMES.TEAM_BOSS_SOCKET_CONNECTED)
end


function TeamSocketManager:onDisconnect_()
    self:printLog_('收到断开连接命令' .. NetCmd.Disconnect)
    self:disConnect()

    local sendData = {errText = __('该组队连接已断开')}
    self:GetFacade():DispatchObservers(SIGNALNAMES.TEAM_BOSS_SOCKET_UNEXPECTED, sendData)
end


function TeamSocketManager:onReceivePing_()
    -- self:printLog_(string.format('收到ping命令，间隔毫秒：%0.3f', self.startPingTime_ - self.lastPingTime_))
    self.isSendedPing_ = false
    if self:isShowNetworkWeak() then
        self:setShowNetworkWeak(false)
    end
end


function TeamSocketManager:onReceiveError_(errText, errcode)
    self:printLog_('收到错误命令' .. NetCmd.Error, errText)
    -- 此处不处理断开 错误代码为正不断线
    -- self:disConnect()

    local sendData = {errText = tostring(errText), errcode = checkint(errcode)}
    self:GetFacade():DispatchObservers(SIGNALNAMES.TEAM_BOSS_SOCKET_UNEXPECTED, sendData)
end


function TeamSocketManager:onReconnectOver_()
    self:printLog_('终止继续尝试重连')
    self:disConnect()

    local sendData = {errText = __('由于网络不稳定，当前组队连接已断开')}
    self:GetFacade():DispatchObservers(SIGNALNAMES.TEAM_BOSS_SOCKET_UNEXPECTED, sendData)
end


return TeamSocketManager

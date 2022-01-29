--[[
战斗socket管理器
--]]
local SocketManager = require('Frame.Manager.SocketManager')
local BattleSocketManager = class('BattleSocketManager', SocketManager)

------------ import ------------
local socket = require('socket')
local scheduler = require('cocos.framework.scheduler')
local TcpProtocol = require( "Frame.TcpProtocol" )
------------ import ------------

------------ constants ------------
local NAME = 'BattleSocketManager'

print('check id address>>>>>>>>>> SocketManager in battle socket manager', ID(SocketManager))

local PINGDELTA = 10
local PING_TIMEOUT = 20 --20秒的超时时间
local SERVER_CONNECT_NUM = 3000 -- 连接服务的尝试次数据,当做是无限次的逻辑
local HP_TIME = 150

local Stage = Enum (
{
	NotConnected = 1,
	Connecting   = 2,
	Verifying    = 3,
	Connected    = 4
})
------------ constants ------------

---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
@override
--]]
function BattleSocketManager:ctor( key )
	SocketManager.ctor(self, key)
	self.client.name   = 'BattleSocket'
	self.lastFrameTime = 0
end
--[[
@override
类入口
--]]
function BattleSocketManager.GetInstance(key)
	key = (key or NAME)
	if SocketManager.instances[key] == nil then
		SocketManager.instances[key] = BattleSocketManager.new(key)
	end
	return SocketManager.instances[key]
end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- control begin --
---------------------------------------------------
--[[
@override
--]]
function BattleSocketManager:Update( dt )
	if not self.isPause then
		self:SocketStatus( )
	end
end
--[[
@override
具体和单个包的处理
@param buffer 一个包体
--]]
function BattleSocketManager:AnalysePacket(buffer)
	local cmd = checkint(buffer.cmd)
	print('\n\n--------------------------------------\n 	here get battle socket : ' .. cmd .. '\n--------------------------------------\n\n')

	-- 首次连接的回调
	if cmd == NetCmd.RequestID or Stage.Verifying == self.client.stage then
		--更新socket client的状态
		self.client:VerifyRequestID(cmd)
		--更新用户信息playerinfo的作用
		self.mCanPing = true
		if self.onConnected then
			self.onConnected(true)
		end
		--发送一次playerinfo的数据
        self:SendPacket(NetCmd.RequestPlayerInfoID)
        self:SendPacket(NetCmd.RequestPing)
		return true
	end

	-- 如果存在外部回调函数 则走外部逻辑
	local packetCallback = self.packetHandlers[tostring(cmd)]
	if packetCallback then
		packetCallback(buffer)
		return true
	end
	-- dump(buffer)
	-- 信息回调
	if cmd == NetCmd.RequestPing then
		local ping = self.mStartTime - self.lastPingTime
		-- funLog(Logger.INFO, "battle ping time span ".. tostring( ping ))
		if self.onPing then
			self.onPing(ping)
		end
		self.mCanPing = true
        local ctime = socket.gettime()
        if ctime - self.hpTime >= HP_TIME then
            self.hpTime = ctime
            self:SendPacket(NetCmd.RequestID)
        end
        return true
    elseif cmd == NetCmd.Error then
    	-- 错误信息
    	funLog(Logger.INFO, buffer)
		if self.onError then
			self.onError(buffer)
		end
	elseif cmd == NetCmd.Disconnect then
		-- 无法连接
		self.mCanSend = false
		self.client:Close(false)
		if self.onDisconnect then
			self.onDisconnect()
		end
	-- debug --
	elseif cmd == RB_ENTER_RAID_TEAM_4001 then
		-- 进入队伍成功
		AppFacade.GetInstance():DispatchObservers(RB_SIGNAL_ENTER_RAID_TEAM_SUCCESS, {packet = buffer})
	elseif cmd == RB_START_RAID_4009 then
		if 0 == buffer.data.errcode then
			-- 无错误 开始
			AppFacade.GetInstance():DispatchObservers(RB_SIGNAL_START_LAOD_GAME, {packet = buffer})
		end
	elseif cmd == RB_RAID_STARTED_4010 then
		if 0 == buffer.data.errcode then
			-- 无错误 开始
			AppFacade.GetInstance():DispatchObservers(RB_SIGNAL_START_LAOD_GAME, {packet = buffer})
		end
	elseif cmd == RB_START_RAID_4030 then
		BMediator:GameStart()
		self.lastFrameTime = socket:gettime()
	elseif cmd == 4014 then
		BMediator:LogicFrameCallback(buffer)
		-- print('check delta time>>>>>>>>>>>>>', socket:gettime() - self.lastFrameTime, '\n')
		self.lastFrameTime = socket:gettime()
	elseif cmd == RB_PLAYER_CHANGED_4002 then

		AppFacade.GetInstance():DispatchObservers(RB_SIGNAL_PLAYER_CHANGED, {packet = buffer})
	elseif cmd == RB_CHANGE_CARD_4003 then
		-- 上卡成功 开始准备
		AppFacade.GetInstance():DispatchObservers(RB_SIGNAL_CHANGE_CARD, {packet = buffer})
	elseif cmd == RB_CARD_CHANGED_4004 then
		if 0 == buffer.data.errcode then
			-- 无错误他人换卡成功
			AppFacade.GetInstance():DispatchObservers(RB_SIGNAL_CARD_CHANGED, {packet = buffer})
		end
	elseif cmd == RB_READY_4007 then
		-- 准备成功 开始
		AppFacade.GetInstance():DispatchObservers(RB_SIGNAL_READY, {packet = buffer})
	-- debug -- 
	else

	end
	return true
end
---------------------------------------------------
-- control end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
设置连接成功的回调
@params callback function 回调函数
--]]
function BattleSocketManager:SetOnConnectedSuccess(callback)
	self.onConnected = callback
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return BattleSocketManager

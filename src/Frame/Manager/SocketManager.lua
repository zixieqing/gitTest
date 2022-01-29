--[[
长连接管理模块
--1. ping超时关闭连接逻辑
--2. 连接尝试重连接的逻辑
--3. 重新连接的次数
--]]
require( "Frame.NetCmd" )
local socket      = require('socket')
local scheduler   = require('cocos.framework.scheduler')
local TcpProtocol = require( "Frame.TcpProtocol" )
local ManagerBase = require( "Frame.Manager.ManagerBase" )
---@class SocketManager
local SocketManager = class('SocketManager', ManagerBase)

local PING_TIMEOUT       = 15    -- 网络超时时间（秒）
local SERVER_CONNECT_NUM = 3000  -- 连接服务的尝试次数据, 当做是无限次的逻辑
local HP_CHECK_INTERVAL  = 150   -- 体力同步间隔（秒）

-- 直接解析配置（key：netCmdId，value：eventName）
local DIRECT_ANALYSE_CONFIG = {
	[NetCmd.FRIEND_RECALL_FISHERMAN_EVENT]        = SGL.TAG_FRIEND_FISHERMAN_RECALL_EVENT,        -- 2043 好友召回钓手
	[NetCmd.UNION_ROOM_APPEND]                    = SGL.UNION_CURRENT_ROOM_MEMBER_ENTER,          -- 7002 工会加入房间
	[NetCmd.UNION_ROOM_MEMBER]                    = SGL.UNION_OTHER_ROOM_MEMBERS_CHANGE,          -- 7003 工会房间人数
	[NetCmd.UNION_ROOM_QUIT]                      = SGL.UNION_CURRENT_ROOM_MEMBER_LEAVE,          -- 7007 工会退出房间
	[NetCmd.UNION_AVATAR_MOVE_SEND]               = SGL.UNION_LOBBY_AVATAR_MOVE_SEND,             -- 7009 工会角色移动发送
	[NetCmd.UNION_AVATAR_MOVE_TAKE]               = SGL.UNION_LOBBY_AVATAR_MOVE_TAKE,             -- 7010 工会角色移动接收
	[NetCmd.UNION_PARTY_FOOD_NUM_CHANGE]          = SGL.UNION_PARTY_PREPARE_FOOD_CHANGE,          -- 7011 工会派对 菜品数量变化
	[NetCmd.UNION_AVATAR_CHANGE]                  = SGL.UNION_LOBBY_AVATAR_CHANGE,                -- 7013 工会角色形象更改
	[NetCmd.UNION_PARTY_BOSS_RESULT]              = SGL.UNION_PARTY_BOSS_RESULT_UPDATE,           -- 7014 工会派对 堕神结果
	[NetCmd.UNION_PARTY_ROLL_NOTICE]              = SGL.UNION_PARTY_ROLL_RESULT_UPDATE,           -- 7015 工会派对 roll点通知
	[NetCmd.UNION_AVATAR_LOBBY_CHANGE]            = SGL.UNION_AVATAR_LOBBY_STATUS_CHANGE,         -- 7016 工会角色进出大厅
	[NetCmd.UNION_WARS_UNION_APPLY]               = SGL.UNION_WARS_UNION_APPALY_SUCCEED,          -- 7017 工会战 报名成功通知
	[NetCmd.UNION_WARS_ATTACK_START]              = SGL.UNION_WARS_ATTACK_START_NOTICE,           -- 7018 工会战 进攻敌方 开始
	[NetCmd.UNION_WARS_DEFEND_START]              = SGL.UNION_WARS_DEFEND_START_NOTICE,           -- 7019 工会战 被敌方攻击 开始
	[NetCmd.UNION_WARS_ATTACK_ENDED]              = SGL.UNION_WARS_ATTACK_ENDED_NOTICE,           -- 7020 工会战 进攻敌方 结束
	[NetCmd.UNION_WARS_DEFEND_ENDED]              = SGL.UNION_WARS_DEFEND_ENDED_NOTICE,           -- 7021 工会战 被敌方进攻 结束
	[NetCmd.UNION_IMPEACHMENT_TIMES_NOTICE]       = SGL.UNION_IMPEACHMENT_TIMES_RESULT_UPDATE,    -- 7022 工会当前弹劾过的次数
	[NetCmd.TAG_MATCH_PLAYER_RANK_CHANGE]         = SGL.TAG_MATCH_SGL_PLAYER_RANK_CHANGE,         -- 8001 天城演武玩家排名变化
	[NetCmd.TAG_MATCH_PLAYER_SHIELD_POINT_CHANGE] = SGL.TAG_MATCH_SGL_PLAYER_SHIELD_POINT_CHANGE, -- 8002 天城演武防守生命值变化
	[NetCmd.RequestMarketSale]                    = MARKET_GOODSSALE,                             -- 2013 市场中道具已出售
	[NetCmd.RestuarantCleanAll]                   = SGL.SIGNALNAME_CLEAN_ALL_AVATAR,              -- 6012 清空餐厅布局
	[NetCmd.HOUSE_AVATAR_APPEND]                  = SGL.CAT_HOUSE_AVATAR_APPEND,                  -- 11001 猫屋 添置avatar
	[NetCmd.HOUSE_AVATAR_REMOVE]                  = SGL.CAT_HOUSE_AVATAR_REMOVE,                  -- 11002 猫屋 撤下avatar
	[NetCmd.HOUSE_AVATAR_MOVED]                   = SGL.CAT_HOUSE_AVATAR_MOVED,                   -- 11003 猫屋 移动avatar
	[NetCmd.HOUSE_AVATAR_CLEAR]                   = SGL.CAT_HOUSE_AVATAR_CLEAR,                   -- 11004 猫屋 清空avatar
	[NetCmd.HOUSE_AVATAR_NOTICE]                  = SGL.CAT_HOUSE_AVATAR_NOTICE,                  -- 11007 猫屋 变更avatar
	[NetCmd.HOUSE_MEMBER_LIST]                    = SGL.CAT_HOUSE_MEMBER_LIST,                    -- 11005 猫屋 访客列表
	[NetCmd.HOUSE_MEMBER_VISIT]                   = SGL.CAT_HOUSE_MEMBER_VISIT,                   -- 11006 猫屋 访客来访
	[NetCmd.HOUSE_MEMBER_LEAVE]                   = SGL.CAT_HOUSE_MEMBER_LEAVE,                   -- 11008 猫屋 访客离开
	[NetCmd.HOUSE_MEMBER_HEAD]                    = SGL.CAT_HOUSE_MEMBER_HEAD,                    -- 11011 猫屋 访客改头像
	[NetCmd.HOUSE_MEMBER_BUBBLE]                  = SGL.CAT_HOUSE_MEMBER_BUBBLE,                  -- 11012 猫屋 访客改气泡
	[NetCmd.HOUSE_MEMBER_WALK]                    = SGL.CAT_HOUSE_MEMBER_WALK,                    -- 11010 猫屋 访客移动
	[NetCmd.HOUSE_MEMBER_IDENTITY]                = SGL.CAT_HOUSE_MEMBER_IDENTITY,                -- 11013 猫屋 访客改身份
	[NetCmd.HOUSE_INVITE_NOTICE]                  = SGL.CAT_HOUSE_INVITE_NOTICE,                  -- 11014 猫屋 邀请通知
	[NetCmd.HOUSE_SELF_WALK_SEND]                 = SGL.CAT_HOUSE_SELF_WALK_SEND,                 -- 11009 猫屋 移动通知
	[NetCmd.HOUSE_CAT_STATUS_NOTICE]              = SGL.CAT_HOUSE_CAT_STATUS_NOTICE,              -- 11015 猫屋 猫咪状态变更
	[NetCmd.HOUSE_CAT_ACCEPT_BREED_INVITE]        = SGL.CAT_HOUSE_ACCEPT_BREED_INVITE,            -- 11016 猫屋 好友接受生育邀请
	[NetCmd.HOUSE_CAT_FAVORIBILITY_NOTICE]        = SGL.CAT_HOUSE_FAVORIBILITY_NOTICE,            -- 11017 猫屋 好感度变化通知
}


-------------------------------------------------
-- manager method

SocketManager.DEFAULT_NAME  = 'SocketManager'
SocketManager.instances_    = {}
SocketManager.DEFAULT_DELTA = 5


function SocketManager.GetInstance(instancesKey)
	instancesKey = instancesKey or SocketManager.DEFAULT_NAME

	if SocketManager.instances_[instancesKey] == nil then
		SocketManager.instances_[instancesKey] = SocketManager.new(instancesKey)
	end
	return SocketManager.instances_[instancesKey]
end


function SocketManager.Destroy(instancesKey)
	instancesKey = instancesKey or SocketManager.DEFAULT_NAME

	if SocketManager.instances_[instancesKey] then
		SocketManager.instances_[instancesKey]:Release()
		SocketManager.instances_[instancesKey] = nil
	end
end


-------------------------------------------------
-- life cycle

function SocketManager:ctor(instancesKey)
	ManagerBase.ctor(self)

	if SocketManager.instances_[instancesKey] then
		funLog(Logger.INFO,  "注册相关的facade类型" )
	else
		self:Initial()
	end
end


function SocketManager:Initial()
	self.client = TcpProtocol.new('GameInfoSocket', logInfo.Types.GAME)
	self.mCanSend = true --是否可以发送数据
	self.onPing = nil  --ping的回调函数
	self.onConnected = nil --连接成功的回调
	self.onDisconnect = nil
	self.onError = nil
    -- self.mCanPing = false
	self.isPause = true --是否暂停
	self.packetHandlers = {} --每一个包的对应的回调处理
	self.tryConnectNum = 0 --尝试连接的次数
    self.pingTimeoutNum = 0 --ping的超时次数
	self.beginConnect = true --开始连接
	self.hpTime = os.time() --上一次查询体力的请求时间
	self.lastPingTime = socket.gettime()
	self.pingDelta = SocketManager.DEFAULT_DELTA

	self.updateHandler = scheduler.scheduleGlobal(handler(self, self.onSocketStatusUpdate_),0.1)
end


function SocketManager:Release()
	if self.updateHandler then
        scheduler.unscheduleGlobal(self.updateHandler)
        self.updateHandler = nil
    end
	self.client:Release()
end


-------------------------------------------------
-- public method

--[[
-- 是否正在切换场景中
--]]
function SocketManager:IsSwitchingScenes( )
	return (not self.mCanSend)
end


function SocketManager:setPingDelta(seconds)
	self.pingDelta = checknumber(seconds)
end


function SocketManager:SetPlayerId( playerId )
	self.playerId = playerId --设置角色id
end


function SocketManager:ResetBeginTime()
    self.lastPingTime = socket.gettime() --上一次ping的时间缀
	-- self.hpTime = os.time() --上一次查询体力的请求时间
	self.mStartTime = socket.gettime()
end


--[[
--开始发送数据
--@netcmd 发送的请求的命令
--@msg  要发送的数据
--]]
function SocketManager:SendPacket( netcmd, msg )
	if self.mCanSend then
        local buffer = self.client:BeginSend(netcmd, msg)
		self.client:SendTcpPacket(buffer)
	end
end


function SocketManager:Connect( host, port )
	self:DisConnect()
	self.host = host
	self.port = port
    self:ResetBeginTime()
    self.mCanPing = true
	self.isPause = true --是否暂停
	self.tryConnectNum = 1 --尝试连接的次数
    self.pingTimeoutNum = 0 --ping的超时次数
	self.beginConnect = true --开始连接
	self.hpTime = os.time() --上一次查询体力的请求时间
	self.client:Connect( host, port)
	self.isPause = false

    if not self.updateHandler then
        self.updateHandler = scheduler.scheduleGlobal(handler(self, self.onSocketStatusUpdate_),0.1)
    end
end


function SocketManager:DisConnect( )
	if self.client:IsTryingToConnect() then
		self.mCanSend = true
	end
	self.client:Disconnect()
end


--[[
--@pingCallback ping的回调功能
--]]
function SocketManager:Ping( pingCallback)
    self.onPing = pingCallback
    self.mStartTime = socket.gettime()
    self.lastPingTime = socket.gettime()
    -- self.mCanPing = true
    self:SendPacket(NetCmd.RequestPing)
end


-------------------------------------------------
-- private method

--[[
--长连接连接状态逻辑
--]]
function SocketManager:SocketStatus_( )
    -- local deltaTime = math.abs(self.lastPingTime - self.mStartTime)
	if not self.beginConnect then
		--达到最大连接次数的时候是否需要弹出提示重新登录逻辑
		funLog(Logger.INFO,  "###达到最大连接次数的时候是否需要弹出提示重新登录逻辑：" .. self.tryConnectNum )
		self.lastPingTime = socket.gettime()
		self.mStartTime = socket.gettime()
		-- self.tryConnectNum = 0
		self.beginConnect = true --无限重连接
		self.isPause = true --暂停一切处理
		logInfo.add(logInfo.Types.CHAT, string.fmt('----> retry connect (tryConnectNum = %1)', self.tryConnectNum))
		self:Connect(self.host, self.port)

	elseif self.tryConnectNum > SERVER_CONNECT_NUM then
		funLog(Logger.INFO,  "###达到最服务器最大的连接次数：" .. self.tryConnectNum )
		self.lastPingTime = socket.gettime()
		self.mStartTime = socket.gettime()
		self.tryConnectNum = 0
		self.beginConnect = false
		self.isPause = true --暂停一切处理
		logInfo.add(logInfo.Types.CHAT, string.fmt('----> max connect (SERVER_CONNECT_NUM = %1)', SERVER_CONNECT_NUM))

	-- elseif deltaTime > (PING_TIMEOUT + 1) then
		-- logInfo.add(logInfo.Types.CHAT, string.fmt('----> ping timeout (pingTimeoutNum = %1, deltaTime = %2)', self.pingTimeoutNum, deltaTime))
        --数据超时了
        -- if self.pingTimeoutNum > 4 then
            -- funLog(Logger.INFO,  "###ping超时了：" .. self.pingTimeoutNum.. " ping span " .. tostring(deltaTime))
            -- self.isPause = true --暂停一切处理
            -- self.mStartTime = socket.gettime()
            -- self.lastPingTime = socket.gettime()
            -- self:Connect(self.host, self.port)
        -- else
            -- self.mStartTime = socket.gettime()
            -- self.lastPingTime = socket.gettime()
            -- self.pingTimeoutNum = self.pingTimeoutNum + 1
            -- funLog(Logger.INFO,  "###重置ping超时：" .. self.pingTimeoutNum.. " ping span " .. tostring(deltaTime))
        -- end
	else
		--处理数据包
        if self.client:IsConnected() then
            local deltaTime = math.abs(self.lastPingTime - self.mStartTime)
            if deltaTime > (PING_TIMEOUT + 1) then
                logInfo.add(logInfo.Types.CHAT, string.fmt('----> ping timeout (pingTimeoutNum = %1, deltaTime = %2)', self.pingTimeoutNum, deltaTime))
                --数据超时了
                if self.pingTimeoutNum > 2 then
                    funLog(Logger.INFO,  "###ping超时了：" .. self.pingTimeoutNum.. " ping span " .. tostring(deltaTime))
                    self.isPause = true --暂停一切处理
                    self.mStartTime = socket.gettime()
                    self.lastPingTime = socket.gettime()
                    self:Connect(self.host, self.port)
                else
                    self.mStartTime = socket.gettime()
                    self.lastPingTime = socket.gettime()
                    self.pingTimeoutNum = self.pingTimeoutNum + 1
                    funLog(Logger.INFO,  "###全局连接重置ping超时：" .. self.pingTimeoutNum.. " ping span " .. tostring(deltaTime))
                end
            end
        end
        self:ProcessPackets_()
    end
end


--[[
--不断处理数据包
--]]
function SocketManager:ProcessPackets_( )
    local keepGoing = true
    xTry(function()
        if self.client:IsConnected() then
            local ctime = socket.gettime()
            local deltaTime = math.abs( ctime - self.mStartTime)
            -- if self.client.socketConnected and self.mCanSend and deltaTime >= PINGDELTA and self.mCanPing then
			if self.mCanSend and deltaTime >= self.pingDelta then
                -- self.mCanPing = false
                self.mStartTime = ctime
                --发送ping的数据包
                self:SendPacket(NetCmd.RequestPing)
            end
            if self.client.socketConnected then
                self.tryConnectNum = 0 --表示是成功连接的逻辑需要把连接次数变为0
            end
        end
        local hasNext,buffer = self.client:ReceivePacket()
        while keepGoing and hasNext do
            keepGoing = self:AnalysePacket_(buffer)
            hasNext,buffer = self.client:ReceivePacket()
        end
    end,__G__TRACKBACK__)
end


--[[
--具体和单个包的处理
--@param buffer 一个包体
--]]
function SocketManager:AnalysePacket_( buffer )
	local cmd = checkint(buffer.cmd)
    if cmd == NetCmd.Error then
        --出现错误
        self.beginConnect = false
        return true
	end
	
    if cmd == NetCmd.RequestID or self.client.stage == 3 then
		--更新socket client的状态
		self.client:VerifyRequestID(cmd)
		--更新用户信息playerinfo的作用
        -- self.mCanPing = true
		self.mCanSend = true --表示可以发送数据了
        self.pingTimeoutNum = 0
		if self.onConnected then
			self.onConnected(true)
		end
		--发送一次playerinfo的数据
        self:SendPacket(NetCmd.Request_1005)
        self:SendPacket(NetCmd.RequestPing)
		return true
	end

	local packetCallback = self.packetHandlers[tostring( cmd )]
	if packetCallback then
		packetCallback(buffer)
		return true
	end

    if cmd == NetCmd.RequestPlayerInfoID then
        if buffer.data and buffer.data.data then
            local playinfo = buffer.data.data
            if buffer.data.timestamp then
                local timestamp = checkint(buffer.data.timestamp)
                if profileTimestamp <= timestamp then
                    self:GetGameManager():UpdatePlayer(playinfo)
                    profileTimestamp = timestamp
                end
            else
                self:GetGameManager():UpdatePlayer(playinfo)
            end
            --dispatcher
            self:GetFacade():DispatchObservers(SIGNALNAMES.CACHE_MONEY_UPDATE_UI,playinfo) --相关的数据
        end
        return true
	end
	

	-------------------------------------------------
	-- 餐厅相关
	-- 6001 - 6008
    if cmd >= NetCmd.CustomerArrival and cmd <= NetCmd.Request_6008 then
        --Restuarant command
        self:GetFacade():DispatchObservers(string.format('SIGNALNAME_%d', cmd),buffer) --相关的数据
        return true
	end
	
    -- 6009
	if cmd == NetCmd.RequestEmploySwich then --主管,初始,服务员更换
		app.gameMgr:RemoveLoadingView()
        if checkint(buffer.data.errcode) == 0 then
            self:GetFacade():DispatchObservers(SIGNALNAMES.Lobby_EmployeeSwitch_Callback, buffer)
        else
            app.uiMgr:ShowInformationTips(string.format('%s^_^', tostring(buffer.data.errmsg)))
        end
		return true
		-- 6010
    elseif cmd == NetCmd.RequestEmployUnlock then --主管,初始,服务员解锁
        if checkint(buffer.data.errcode) == 0 then
            self:GetFacade():DispatchObservers(SIGNALNAMES.Lobby_EmployeeUnlock_Callback, buffer)
        else
            app.uiMgr:ShowInformationTips(string.format('%s^_^', tostring(buffer.data.errmsg)))
        end
        return true
    end
	

	-------------------------------------------------
	if cmd == NetCmd.RequestPing then
        -- local sharedDirector = cc.CSceneManager:getInstance()
        -- local node = sharedDirector:getRunningScene():getChildByTag(3048)
        -- if node then
            -- local parent = node:getChildByTag(112)
            -- if parent then
                -- parent:setVisible(true)
                -- parent = parent:getChildByTag(113)
                -- if parent then
                    -- parent:setString(string.format('%dms',math.floor(math.abs(ping - 0.15) * 1000)))
                -- end
            -- end
        --[[ end ]]
        local ctime = socket.gettime()
        self.lastPingTime = ctime--新的ping时间
        local ping = self.lastPingTime - self.mStartTime
        self.pingTimeoutNum = 0
        -- funLog(Logger.INFO, "ping time span ".. tostring( ping ))
        if self.onPing then
            self.onPing(ping)
        end
        -- self.mCanPing = true
        if ctime - self.hpTime >= HP_CHECK_INTERVAL then
            self.hpTime = ctime
            self:SendPacket(NetCmd.RequestPlayerInfoID)
        end
        return true
	elseif cmd == NetCmd.RequestPrize then
		--新的奖励
		if buffer.data and buffer.data.data then
			local newPrize = checkint(buffer.data.data.newPrize)
			if newPrize > 0 then
				app.dataMgr:AddRedDotNofication(tostring(RemindTag.MAIL),RemindTag.MAIL, "[新邮件]奖励-SocketManager:RequestPrize")
			else
				app.dataMgr:ClearRedDotNofication(tostring(RemindTag.MAIL),RemindTag.MAIL, "SocketManager:RequestPrize[新邮件]")
			end
			AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, {countdown = 0, tag = RemindTag.MAIL})
        end
        return true
    elseif cmd == NetCmd.Request2008 then
        --踢人的操作逻辑
        self:Release() --断开连接先的操作
        if buffer.data.data and buffer.data.data.udid then
            local udid = CCNative:getOpenUDID()
            local remoteUdid = buffer.data.data.udid
            if udid ~= remoteUdid then
                if app.gameMgr then
                    self:Release() --断开连接先的操作
                    app.gameMgr:ShowExitGameView(__("当前账号已在其他设备上登录，请退出重新登录~~"))
                end
            end
        else
            if app.gameMgr then
                self:Release() --断开连接先的操作
                app.gameMgr:ShowExitGameView(__("当前账号已在其他设备上登录，请退出重新登录~~"))
            end
        end
        return true
	elseif cmd == NetCmd.Disconnect then
		self.mCanSend = false
        self.beginConnect = false
		if self.onDisconnect then
			self.onDisconnect()
		end
        return true
	elseif  cmd == NetCmd.RequestRestaurantBugAppear or
			cmd == NetCmd.RequestRestaurantBugHelp or
			cmd == NetCmd.RequestRestaurantBugClear or
			cmd == NetCmd.RequestRestaurantQuestEventHelp or
			cmd == NetCmd.RequestRestaurantQuestEventFighting then
		if buffer.data.data and buffer.data.data.friendId then
			AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.SIGNALNAME_FRIEND_AVATAR_STATE, {friendId = buffer.data.data.friendId, cmd = cmd, cmdData = buffer.data.data})

			if cmd == NetCmd.RequestRestaurantBugHelp then
				local datas = {}
				datas.playerId = buffer.data.data.friendId
				datas.helpTime = os.time()
				datas.helpType = HELP_TYPES.RESTAURANT_LUBY
				ChatUtils.InsertChatHelpMessage(datas)
                local chatView = sceneWorld:getChildByTag(GameSceneTag.Chat_GameSceneTag)
                if chatView and chatView.isAction == false then
                    chatView:ReceiveHelpRequest(datas)
                end
			elseif cmd == NetCmd.RequestRestaurantQuestEventHelp then
				local datas = {}
				datas.playerId = buffer.data.data.friendId
				datas.helpTime = os.time()
				datas.helpType = HELP_TYPES.RESTAURANT_BATTLE
				ChatUtils.InsertChatHelpMessage(datas)
                local chatView = sceneWorld:getChildByTag(GameSceneTag.Chat_GameSceneTag)
                if chatView and chatView.isAction == false then
                    chatView:ReceiveHelpRequest(datas)
                end
			elseif cmd == NetCmd.RequestRestaurantBugClear then
                if checkint(buffer.data.data.butId) == 0 then
					local datas = {}
					datas.playerId = buffer.data.data.friendId
					datas.helpType = HELP_TYPES.RESTAURANT_LUBY
					ChatUtils.DeleteChatHelpMessage(datas)
                    local chatView = sceneWorld:getChildByTag(GameSceneTag.Chat_GameSceneTag)
                    if chatView and chatView.isAction == false then
                        chatView:HelpClearCallback(datas)
                    end
                end
			elseif cmd == NetCmd.RequestRestaurantQuestEventFighting then
				local datas = {}
				datas.playerId = buffer.data.data.friendId
				datas.helpType = HELP_TYPES.RESTAURANT_BATTLE
				ChatUtils.DeleteChatHelpMessage(datas)
                local chatView = sceneWorld:getChildByTag(GameSceneTag.Chat_GameSceneTag)
                if chatView and chatView.isAction == false then
                    chatView:HelpClearCallback(datas)
                end
			end
		end
        return true
    elseif cmd == NetCmd.Request2027 then
        --霸王餐被打掉了
        if buffer.data.data and buffer.data.data.friendId then
            local playerId = checkint(app.gameMgr:GetUserInfo().playerId)
            if playerId == checkint(buffer.data.data.friendId) then
				AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.SIGNALNAME_2027)
			else
				-- 更新好友的霸王餐被打掉
				AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.SIGNALNAME_FRIEND_AVATAR_STATE, {friendId = buffer.data.data.friendId, cmd = cmd, cmdData = buffer.data.data})
            end
        end
        -- 清除捐助列表
        local datas = {}
        datas.playerId = buffer.data.data.friendId
        datas.helpType = HELP_TYPES.RESTAURANT_BATTLE
        ChatUtils.DeleteChatHelpMessage(datas)
        local chatView = sceneWorld:getChildByTag(GameSceneTag.Chat_GameSceneTag)
        if chatView and chatView.isAction == false then
            chatView:HelpClearCallback(datas)
        end
        return true
	elseif cmd == NetCmd.RequestDailyTask then
		if CommonUtils.UnLockModule(RemindTag.TASK, false) and CommonUtils.GetModuleAvailable(MODULE_SWITCH.DAILYTASK) then
			local appMediator  = app:RetrieveMediator('AppMediator')
			if appMediator then
				appMediator:syncDailyTaskCacheData()
			end
		end
        return true
	elseif cmd == NetCmd.RequestMainTask then
		if CommonUtils.UnLockModule(RemindTag.TASK, false) and CommonUtils.GetModuleAvailable(MODULE_SWITCH.ACHIEVEMENT) then
			local appMediator  = app:RetrieveMediator('AppMediator')
			if appMediator then
				appMediator:syncAchievementCacheData(buffer.data.data)
			end
		end
        return true
	elseif cmd == NetCmd.RequestNewbieTaskRemain then
		local taskNotDrawn = buffer.data.data.taskNotDrawn
		if taskNotDrawn and taskNotDrawn ~= 0 then
			app.dataMgr:AddRedDotNofication(tostring(RemindTag.SEVENDAY),RemindTag.SEVENDAY, "[新手七天]NetCmd.RequestNewbieTaskRemain")
			app.gameMgr:GetUserInfo().showRedPointForNewbieTask = true
		else
			app.dataMgr:ClearRedDotNofication(tostring(RemindTag.SEVENDAY),RemindTag.SEVENDAY, "[新手七天]NetCmd.RequestNewbieTaskRemain")
			app.gameMgr:GetUserInfo().showRedPointForNewbieTask = false
		end
		AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, {countdown = 0, tag = RemindTag.SEVENDAY})
        return true
	elseif cmd == NetCmd.RequestRecallTaskComplete then
		local taskNotDrawn = buffer.data.data.taskNotDrawn
		if taskNotDrawn and taskNotDrawn ~= 0 then
			app.dataMgr:AddRedDotNofication(tostring(RemindTag.RECALL),RemindTag.RECALL, "[老玩家召回]NetCmd.RequestRecallTaskComplete")
			app.gameMgr:GetUserInfo().showRedPointForRecallTask = true
		else
			app.dataMgr:ClearRedDotNofication(tostring(RemindTag.RECALL),RemindTag.RECALL, "[老玩家召回]NetCmd.RequestRecallTaskComplete")
			app.gameMgr:GetUserInfo().showRedPointForRecallTask = false
		end
		AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, {countdown = 0, tag = RemindTag.RECALL})
        return true
	elseif cmd == NetCmd.RequestMasterRecalled then
		app.dataMgr:AddRedDotNofication(tostring(RemindTag.RECALLEDMASTER),RemindTag.RECALLEDMASTER, "[老玩家召回]NetCmd.RequestMasterRecalled")
		app.gameMgr:GetUserInfo().showRedPointForMasterRecalled = true
		AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, {countdown = 0, tag = RemindTag.RECALLEDMASTER})
        return true
	elseif cmd == NetCmd.RequestRecallRewardAvailable then
		app.dataMgr:AddRedDotNofication(tostring(RemindTag.RECALLH5),RemindTag.RECALLH5, "[老玩家召回]NetCmd.RequestRecallRewardAvailable")
		app.gameMgr:GetUserInfo().showRedPointForRecallH5 = true
		AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, {countdown = 0, tag = RemindTag.RECALLH5})
        return true
	elseif cmd == NetCmd.RequestFriendMsg then
		local newFriendMessage = buffer.data.data.newFriendMessage
		if newFriendMessage and newFriendMessage ~= 0 then
			app.dataMgr:AddRedDotNofication(tostring(RemindTag.FRIENDS),RemindTag.FRIENDS,"[好友消息长连接]")
		else
			app.dataMgr:ClearRedDotNofication(tostring(RemindTag.FRIENDS),RemindTag.FRIENDS,"[好友消息长连接]")
		end
		AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, {countdown = 0, tag = RemindTag.FRIENDS})
        return true
	elseif cmd == NetCmd.RequestNewFriend then
		local newFriendRequest = buffer.data.data.newFriendRequest
		if newFriendRequest and checkint(newFriendRequest) ~= 0 then
            app.dataMgr:AddRedDotNofication(tostring(RemindTag.NEW_FRIENDS),RemindTag.NEW_FRIENDS, "[新好友请求长连接]")
			app.dataMgr:AddRedDotNofication(tostring(RemindTag.FRIENDS),RemindTag.FRIENDS, "[新好友请求长连接]")
            AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, {countdown = 0, tag = RemindTag.FRIENDS})
		else
			app.dataMgr:ClearRedDotNofication(tostring(RemindTag.NEW_FRIENDS),RemindTag.NEW_FRIENDS, "[新好友请求长连接]")
		end
        return true
	elseif cmd == NetCmd.RequestRestaurantSaleRecipe then --餐厅出售完菜 主界面亮红点
		app.dataMgr:AddRedDotNofication(tostring(RemindTag.MANAGER),RemindTag.MANAGER, "[餐厅出售完菜长连接]")
		AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, {countdown = 0, tag = RemindTag.MANAGER})
		app.gameMgr:GetUserInfo().showRedPointForRestaurantRecipeNum = true
        return true
	elseif cmd == NetCmd.RequestStoryUnlock then		 --剧情任务解锁

		app.dataMgr:AddRedDotNofication(tostring(RemindTag.STORY), RemindTag.STORY, "[剧情任务解锁长连接]")
		AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, {countdown = 0, tag = RemindTag.STORY})
		-- AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.StoryMissions_ChangeCenterContainer,{state = 'storyshow', stroyId = buffer.data.data.plotTask})

        return true
	elseif cmd == NetCmd.RequestStoryComplete then  	 --剧情任务完成
		app.dataMgr:AddRedDotNofication(tostring(RemindTag.STORY),RemindTag.STORY, "[剧情任务完成长连接]")
		AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, {countdown = 0, tag = RemindTag.STORY})
        return true
	elseif cmd == NetCmd.RequestRegionalUnlock then  	 --支线任务解锁
		-- AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.StoryMissions_ChangeCenterContainer,{state = 'regionalshow', stroyId = buffer.data.data.branchTask})
        return true
	elseif cmd == NetCmd.RequestRegionalComplete then   --支线任务完成
		-- app.dataMgr:ClearRedDotNofication(tostring(RemindTag.STORY),RemindTag.STORY)
		app.dataMgr:AddRedDotNofication(tostring(RemindTag.STORY),RemindTag.STORY, "[支线任务完成长连接]")
		AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, {countdown = 0, tag = RemindTag.STORY})
        return true
	-- elseif cmd == NetCmd.RequestMarketSale then -- 市场出售通知
	-- 	AppFacade.GetInstance():DispatchObservers(MARKET_GOODSSALE, {markets = buffer.data.data.markets, marketType = buffer.data.data.marketType})

	-- 	-- app.dataMgr:AddRedDotNofication(tostring(RemindTag.MARKET), RemindTag.MARKET)
	-- 	-- AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, {countdown = 0, tag = RemindTag.MARKET})

    --     return true
	elseif cmd == NetCmd.RequestTeskProgress then -- 餐厅任务进度
		AppFacade.GetInstance():DispatchObservers(RESTAURANT_TESK_PROGRESS, {progress = buffer.data.data.progress})
        return true
	elseif cmd == NetCmd.RequestKickOut then
        return true
		--踢人的操作逻辑
		--显示踢出游戏的提示界面
	------------ 小红点 ------------
	elseif cmd == NetCmd.RequestBonus then

		-- 满星奖励
		-- 计入内存
		app.gameMgr:RefreshCityRewardNotDrawnData(buffer.data.data.rewardNotDrawn, QUEST_DIFF_NORMAL)
        return true
	elseif cmd == NetCmd.RequestLimitGiftBag then
		local data = checktable(buffer.data.data)
		if data.productId and data.uiTplId then
			app.gameMgr:GetUserInfo().triggerChest = app.gameMgr:GetUserInfo().triggerChest or {}

			local findIndex = 0
			for i, chestData in ipairs(app.gameMgr:GetUserInfo().triggerChest) do
				if checkint(chestData.productId) == checkint(data.productId) and checkint(chestData.uiTplId) == checkint(data.uiTplId) then
					findIndex = i
					break
				end
			end

			if findIndex > 0 then
				app.gameMgr:GetUserInfo().triggerChest[findIndex] = data
			else
				table.insert(app.gameMgr:GetUserInfo().triggerChest, data)
			end
			-- 添加道倒计时的逻辑
			app.activityMgr:AddLimiteGiftTimer(data)
		end
        return true
	elseif cmd == NetCmd.RequestBonusHard then

		-- 满星奖励
		-- 计入内存
		app.gameMgr:RefreshCityRewardNotDrawnData(buffer.data.data.rewardNotDrawn, QUEST_DIFF_HARD)

        return true
	elseif cmd == NetCmd.RequestWaiterDied then

		-- 餐厅服务员新鲜度耗尽
		local waiterId = buffer.data.data.waiterId
		-- TODO --

		app.dataMgr:AddRedDotNofication(tostring(RemindTag.MANAGER), RemindTag.MANAGER, "[餐厅服务员]-NetCmd.RequestWaiterDied")
		AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, {countdown = 0, tag = RemindTag.MANAGER})

        return true
	elseif cmd == NetCmd.RequestSpecialCustomer then

		-- 餐厅特殊客人
		local seatId = buffer.data.data.waiterId
		local customerUuid = buffer.data.data.customerUuid

		app.dataMgr:AddRedDotNofication(tostring(RemindTag.MANAGER), RemindTag.MANAGER, "[餐厅服务员]NetCmd.RequestSpecialCustomer")
		AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, {countdown = 0, tag = RemindTag.MANAGER})

        return true
	------------ 小红点 ------------
	-- elseif cmd == NetCmd.RequestPayMoneySuccess then
		--充值成功
		-- AppFacade.GetInstance():DispatchObservers(EVENT_PAY_MONEY_SUCCESS, buffer.data.data)
        -- return true
	elseif cmd == NetCmd.RequestMessageBoard then
		app.gameMgr:GetUserInfo().personalMessage  = 1
		app.badgeMgr:CheckHomeInforRed()
		AppFacade.GetInstance():DispatchObservers(REFRESH_MESSAGE_BOARD_EVENT, buffer.data.data)
    ------------ 好友求助 ------------
    elseif cmd == NetCmd.RequestRequestAssistant then
        local datas = {}
        datas.playerId = buffer.data.data.requestAssistantPlayerId
        datas.helpTime = buffer.data.data.createTime
        datas.expirationTime = buffer.data.data.expirationTime
        datas.goodsId = buffer.data.data.goodsId
        datas.assistanceId = buffer.data.data.assistanceId
        datas.helpType = HELP_TYPES.FRIEND_DONATION
        ChatUtils.InsertChatHelpMessage(datas)
        local chatView = sceneWorld:getChildByTag(GameSceneTag.Chat_GameSceneTag)
        if chatView and chatView.isAction == false then
            chatView:ReceiveHelpRequest(datas)
		end

	elseif cmd == NetCmd.RequestAssistant then
        local datas = {}
        datas.playerId = buffer.data.data.requestAssistantPlayerId
        datas.helpType = HELP_TYPES.FRIEND_DONATION
        ChatUtils.DeleteChatHelpMessage(datas)
        local chatView = sceneWorld:getChildByTag(GameSceneTag.Chat_GameSceneTag)
        if chatView and chatView.isAction == false then
            chatView:HelpClearCallback(datas)
		end

	elseif cmd == NetCmd.RequestFullServer then
		local fullServerData = buffer.data.data.done
		-- dump(fullServerData, 'fullServerData')
		for i,v in ipairs(fullServerData) do
			-- 检查是否有该活动  防止 缓存数据被清空后 活动莫名其妙亮小红点
            app.badgeMgr:SetActivityTipByActivitiyId(v, 1)
			-- if app.gameMgr:GetUserInfo().serverTask[tostring(v)] then
			-- 	app.gameMgr:GetUserInfo().serverTask[tostring(v)] = 1
			-- end
		end
		AppFacade.GetInstance():DispatchObservers(REFRESH_FULL_SERVER_EVENT)
		return true
    elseif cmd == NetCmd.RequestAccumulativePay then
        local accumulativePayData = buffer.data.data.done
        for _,v in ipairs(accumulativePayData) do
            app.badgeMgr:SetActivityTipByActivitiyId(v, 1)
        end
		-- for i,v in ipairs(accumulativePayData) do
		-- 	-- 检查是否有该活动  防止 缓存数据被清空后 活动莫名其妙亮小红点
		-- 	if app.gameMgr:GetUserInfo().accumulativePay[tostring(v)] then
		-- 		app.gameMgr:GetUserInfo().accumulativePay[tostring(v)] = 1
		-- 	end
  --       end

        AppFacade.GetInstance():DispatchObservers(REFRESH_ACCUMULATIVE_RECHARGE_EVENT)
        return true
    elseif cmd == NetCmd.RequestAccumulativeConsume then
        local accumulativeConsumeData = buffer.data.data.done
        for _,v in ipairs(accumulativeConsumeData) do
            app.badgeMgr:SetActivityTipByActivitiyId(v, 1)
        end
        AppFacade.GetInstance():DispatchObservers(REFRESH_ACCUMULATIVE_CONSUME_EVENT)
        return true
	elseif cmd == NetCmd.GAME_NOTICE then
		if CommonUtils.GetControlGameProterty(CONTROL_GAME.MARQUEE_PUSH)  then
			app.uiMgr:showGameNotice(buffer.data.data)
		end
	elseif cmd == NetCmd.RequestBinggoTaskDone then
		local data = buffer.data.data
		if data then
            app.badgeMgr:SetActivityTipByActivitiyId(data.binggoActivityId, 1)
			-- 检查是否有该活动  防止 缓存数据被清空后 活动莫名其妙亮小红点
			-- if app.gameMgr:GetUserInfo().binggoTask[tostring(data.binggoActivityId)] then
			-- 	app.gameMgr:GetUserInfo().binggoTask[tostring(data.binggoActivityId)] = 1
			-- end
		end


	-------------------------------------------------
	-- 公会常规
	-- 7001 申请工会结果
	elseif cmd == NetCmd.APPLY_UNION_RESULT then
		local data   = buffer.data.data
		local result = checkint(data.result)
		if result == 1 then
			---@type UnionManager
			app.unionMgr:setUnionId(checkint(data.unionId))
			AppFacade.GetInstance():DispatchObservers(UNION_JOIN_SUCCESS)

			-- 加入工会聊天室
			app.unionMgr:JoinUnionChatRoom()
			app.uiMgr:ShowInformationTips(__('您已经成功加入到工会'))
		-- else
		-- 	app.uiMgr:ShowInformationTips(__('您的工会申请被拒绝， 请重新申请'))
		end


	-- 7004 工会入会申请
	elseif cmd == NetCmd.UNION_JOIN_APPLY then
		local data   = buffer.data.data
		---@type UnionManager
		app.unionMgr.applyMessage = 1
		AppFacade.GetInstance():DispatchObservers(UNION_APPLY_EVENT ,{})
		AppFacade.GetInstance():DispatchObservers(POST.UNION_APPLYLIST.sglName ,{applyList = {data.playerInfo} } )


	-- 7005 工会踢人通知
	elseif cmd == NetCmd.UNION_KICK_MEMBER then
		----@type UnionManager
		local data   = buffer.data.data
		---@type GameManager
		local currentUnionId = app.gameMgr:GetUserInfo().unionId
		if checkint(currentUnionId ) == checkint(data.unionId) then
			app.unionMgr:setUnionId(nil)
			-- 退出工会聊天室
			app.unionMgr:ExitUnionChatRoom()
			-- 被踢后 工会刷新小红点
			app.badgeMgr:CheckUnionRed()
			-- 被踢后 工会任务刷新小红点
			app.badgeMgr:CheckTaskHomeRed()
			AppFacade.GetInstance():DispatchObservers(UNION_KICK_OUT_EVENT,{})
            -- 删除本工会的堕神
            app.gameMgr:ClearUnionPetsByUnionId(checkint(data.unionId))
		end


	-- 7006 工会职位变更
	elseif cmd == NetCmd.UNION_JOB_CHANGE then
		local data   = buffer.data.data
		---@type GameManager
		local mediator = AppFacade.GetInstance():RetrieveMediator("UnionInforDetailMediator")
		-- 当工会信息存在的时候 就直接职位变更接口统一处理 如果不存在的话 只改变职位就可以了
		if mediator then
			AppFacade.GetInstance():DispatchObservers(POST.UNION_ASSIGNJOB.sglName , {requestData = {
				job  =data.job ,
				memberId  =  app.gameMgr:GetUserInfo().playerId
			}})
		else
			app.unionMgr:TurnOverUnionJobTypeByPlayerId(app.gameMgr:GetUserInfo().playerId ,data.job)
		end

	-- 7008 工会任务完成
	elseif cmd == NetCmd.UNION_TASK_FINISH then
		if CommonUtils.UnLockModule(RemindTag.UNION, false) and CommonUtils.GetModuleAvailable(MODULE_SWITCH.UNION_TASK) then
			local data   = buffer.data.data
			local appMediator  = app:RetrieveMediator('AppMediator')
			if appMediator then
				appMediator:syncUnionTaskCacheData(data)
			end
		end


	-- 7012 工会堕神等级变化
	elseif cmd == NetCmd.UNION_PET_LEVEL_CHANGE then
		-- 刷新一次堕神信息
		local unionId = checkint(buffer.data.data.unionId)
		local petId = checkint(buffer.data.data.petId)
		if app.gameMgr:hasUnion() and unionId == checkint(app.gameMgr:GetUserInfo().unionId) then
			app.gameMgr:UpdateUnionPetData(petId, buffer.data.data)
		end
		

	-------------------------------------------------
	elseif cmd == NetCmd.FISH_FRIEND_CARD_UNLOAD_EVENT  then
		local data = checktable(buffer.data.data)
		--[[ 例如 ：  data = {
			["baitId"]       = 321005,
			["baitNum"]      = 57,
			["playerCardId"] = 635,
			["playerId"]     = 100166,
			["vigour"]       = 82
	 	}]]
		app.fishingMgr:UnloadFriendFishCardsData(data)
		app:DispatchObservers(FISH_FRIEND_CARD_UNLOAD_EVENT , data)


	elseif cmd == NetCmd.FISH_FRIEND_CARD_LOAD_EVENT  then
		app.fishingMgr:FriendAddCardDataFish(buffer.data.data)

	elseif cmd == NetCmd.RETURNWELFARE_BINGO_TASK_FINISH then
		app.gameMgr:GetUserInfo().showRedPointForBack = true
		app:DispatchObservers('RETURNWELFARE_BINGO_TASK_FINISH' , data)
	elseif cmd == NetCmd.REQUEST_CONTINUOUS_ACTIVE then
		app.gameMgr:GetUserInfo().tips.continuousActive = 1
	elseif cmd == NetCmd.NEWBIE14_PROGRESS_NOTICE then
		app.gameMgr:GetUserInfo().tips.newbie14Task = 1
		app.dataMgr:AddRedDotNofication(tostring(RemindTag.NOVICE_WELFARE), RemindTag.NOVICE_WELFARE)
		app:DispatchObservers(COUNT_DOWN_ACTION, {countdown = 0, tag = RemindTag.NOVICE_WELFARE})
	elseif cmd == NetCmd.REQUEST_ANTI_ADDICTION then
		local data = checktable(buffer.data.data)
		app.uiMgr:showRealNameAuthView(data.tips)
	elseif cmd == NetCmd.ARTIFACT_GUIDE_REMIND_ICON then
		app.dataMgr:AddRedDotNofication(tostring(RemindTag.ARTIFACT_GUIDE),RemindTag.ARTIFACT_GUIDE)
		app:DispatchObservers(COUNT_DOWN_ACTION, {countdown = 0, tag = RemindTag.ARTIFACT_GUIDE})
	else
		if DIRECT_ANALYSE_CONFIG[cmd] then
			if checkint(buffer.data.errcode) ~= 0 then
				AppFacade.GetInstance():DispatchObservers(DIRECT_ANALYSE_CONFIG[cmd], {
					errcode = checkint(buffer.data.errcode),
					errmsg  = buffer.data.errmsg,
				})
			else
				AppFacade.GetInstance():DispatchObservers(DIRECT_ANALYSE_CONFIG[cmd], buffer.data.data)
			end
		end
	end

	return true
end


-------------------------------------------------
-- handler

function SocketManager:onSocketStatusUpdate_( dt )
	if not self.isPause then
		self:SocketStatus_( )
	end
end


return SocketManager

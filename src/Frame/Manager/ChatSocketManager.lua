 --[[
长连接管理模块
--1. ping超时关闭连接逻辑
--2. 连接尝试重连接的逻辑
--3. 重新连接的次数
--]]
local ManagerBase = require( "Frame.Manager.ManagerBase" )
---@class ChatSocketManager
local ChatSocketManager = class('ChatSocketManager',ManagerBase)
require( "Frame.NetCmd" )

local socket = require('socket')
local scheduler = require('cocos.framework.scheduler')
local TcpProtocol = require( "Frame.TcpProtocol" )
local LabelParser = require("Game.labelparser")
ChatSocketManager.instances     = {}
ChatSocketManager.DEFAULT_DELTA = 5


local PING_TIMEOUT = 15 --20秒的超时时间

local SERVER_CONNECT_NUM = 3000 -- 连接服务的尝试次数据,当做是无限次的逻辑

local IS_OPEN_CHAT_DELAY = false -- 是否开启聊天接收延时（目的是造成每条信息都是有审核的效果）


function ChatSocketManager:ctor( key )
	self.super.ctor(self)
	if ChatSocketManager.instances[key] ~= nil then
		funLog(Logger.INFO,  "注册相关的facade类型" )
		return
	end

	ChatSocketManager.instances[key] = self
	self:Initial()
	self.updateHandler = scheduler.scheduleGlobal(handler(self, self.Update),1)
end

function ChatSocketManager.GetInstance(key)
	key = (key or "ChatSocketManager")
	if ChatSocketManager.instances[key] == nil then
		ChatSocketManager.instances[key] = ChatSocketManager.new(key)
	end
	return ChatSocketManager.instances[key]
end

function ChatSocketManager.Destroy( key )
	key = (key or "ChatSocketManager")
	if ChatSocketManager.instances[key] == nil then
		return
	end
	--清除配表数据
	local instance = ChatSocketManager.instances[key]
	instance:Release() --释放资源
	ChatSocketManager.instances[key] = nil
end


function ChatSocketManager:Initial( )
	self.client = TcpProtocol.new('ChatSocket', logInfo.Types.CHAT)
	self.mCanSend = true --是否可以发送数据
	self.onPing = nil  --ping的回调函数
	self.onConnected = nil --连接成功的回调
	self.onDisconnect = nil
	self.onError = nil
    -- self.mCanPing = false
	self.isPause = true --是否暂停
	self.packetHandlers = {} --每一个包的对应的回调处理['5010'] = function(buffer)
	self.tryConnectNum = 0 --尝试连接的次数
    self.pingTimeoutNum = 0 --ping的超时次数
	self.beginConnect = true --开始连接
    self.chatAllMessage = {
        [tostring(CHAT_CHANNELS.CHANNEL_WORLD)] = {},
        [tostring(CHAT_CHANNELS.CHANNEL_UNION)] = {},
        [tostring(CHAT_CHANNELS.CHANNEL_HOUSE)] = {},
        [tostring(CHAT_CHANNELS.CHANNEL_SYSTEM)] = {},
        [tostring(CHAT_CHANNELS.CHANNEL_TEAM)] = {}
    }
    --聊天全部信息
    self.preRoomId = 1 --前一次尝试的房间id
    self.selectedRoomId = nil -- 当前选中的房间id
    self.pingDelta = ChatSocketManager.DEFAULT_DELTA

    -- 当前加入频道的房间id
    self.joinedChannelRoomId = {
        [tostring(CHAT_CHANNELS.CHANNEL_WORLD)] = nil,
        [tostring(CHAT_CHANNELS.CHANNEL_UNION)] = nil,
        [tostring(CHAT_CHANNELS.CHANNEL_HOUSE)] = nil,
        [tostring(CHAT_CHANNELS.CHANNEL_SYSTEM)] = nil,
        [tostring(CHAT_CHANNELS.CHANNEL_TEAM)] = nil
    }
    self.chatRoomPreTime = os.time()
    self.chatRoomDelayMsgs = {} -- 世界聊天延迟信息

    -- 初始化聊天数据库
    ChatUtils.InitDatabase()
end
--[[
-- 是否正在切换场景中
--]]
function ChatSocketManager:IsSwitchingScenes( )
	return (not self.mCanSend)
end

function ChatSocketManager:setPingDelta(seconds)
	self.pingDelta = checknumber(seconds)
end

function ChatSocketManager:SetPlayerId( playerId )
	self.playerId = playerId --设置角色id
end
--[[
获取当前所在的聊天室Id
--]]
function ChatSocketManager:GetChatRoomId( channel )
    -- return checkint(self.selectedRoomId)
    return self:GetJoinedChannelRoomId(channel)
end
--[[
--重设下时间，之前的逻辑存在一个bug
--]]
function ChatSocketManager:ResetBeginTime()
    self.lastPingTime = socket.gettime() --上一次ping的时间缀
	self.mStartTime = socket.gettime()
end

--[[
--开始发送数据
--@netcmd 发送的请求的命令
--@msg  要发送的数据
--]]
function ChatSocketManager:SendPacket( netcmd, msg )
	-- dump(msg)
	-- dump(self.mCanSend)
	if self.mCanSend then
		local buffer = self.client:BeginSend(netcmd, msg)
		self.client:SendTcpPacket(buffer)
	end
end

function ChatSocketManager:Connect( host, port )
	self:DisConnect()
	self.host = host
	self.port = port
    self:ResetBeginTime()
    self.mCanSend = true --是否可以发送数据
    self.isPause = true --是否暂停
    self.tryConnectNum = 1 --尝试连接的次数
    self.pingTimeoutNum = 0 --ping的超时次数
    self.beginConnect = true --开始连接
    --聊天全部信息
    self.selectedRoomId = nil -- 当前选中的房间id
	self.client:Connect( host, port)
	self.isPause = false
    if not self.updateHandler then
        self.updateHandler = scheduler.scheduleGlobal(handler(self, self.Update),1)
    end
end

function ChatSocketManager:DisConnect( )
	if self.client:IsTryingToConnect() then
		self.mCanSend = true
	end
	self.client:Disconnect()
end
--[[
--@pingCallback ping的回调功能
--]]
function ChatSocketManager:Ping( pingCallback)
    self.onPing = pingCallback
    self.mStartTime = socket.gettime()
    self.lastPingTime = socket.gettime()
    -- self.mCanPing = true
    self:SendPacket(NetCmd.RequestPing)
end
--[[
--释放资源client
--]]
function ChatSocketManager:Release( )
	if self.updateHandler then
        scheduler.unscheduleGlobal(self.updateHandler)
        self.updateHandler = nil
    end
    --发送退出聊天室的接口
    local buffer = self.client:BeginSend(NetCmd.RequestOutChatroom)
    if self.client.mSocket then
        self.client.mSocket:send(buffer:getPack())
    end
    self:ExitChatRoomByChannelAndRoomId(CHAT_CHANNELS.CHANNEL_UNION)
    self:ExitChatRoomByChannelAndRoomId(CHAT_CHANNELS.CHANNEL_HOUSE)
	self.client:Release()
end

function ChatSocketManager:Update( dt )
	if not self.isPause then
		self:SocketStatus( )
	end
    if IS_OPEN_CHAT_DELAY then
        self:ChatRoomMsgDelayDisplay()
    end
end
--[[
--长连接连接状态逻辑
--]]
function ChatSocketManager:SocketStatus( )
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
                    funLog(Logger.INFO,  "###重置ping超时：" .. self.pingTimeoutNum.. " ping span " .. tostring(deltaTime))
                end
            end
        end
        self:ProcessPackets()
    end
end
--[[
--不断处理数据包
--]]
function ChatSocketManager:ProcessPackets( )
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
            keepGoing = self:AnalysePacket(buffer)
            hasNext,buffer = self.client:ReceivePacket()
        end
    end,__G__TRACKBACK__)
end


function ChatSocketManager:GetWorldMessage()
    return self:GetMessageByChannel(CHAT_CHANNELS.CHANNEL_WORLD)
end
--[[
根据频道类型获取缓存的聊天消息
@params channel CHAT_CHANNELS 频道类型
@return _ list 聊天消息
--]]
function ChatSocketManager:GetMessageByChannel(channel)
    return self.chatAllMessage[tostring(channel)]
end
--[[
设置当前频道加入的房间
@params channel CHAT_CHANNELS 频道类型
@params roomId int 房间id
--]]
function ChatSocketManager:SetJoinedChannelRoomId(channel, roomId)
    self.joinedChannelRoomId[tostring(channel)] = roomId
end
--[[
获取当前频道加入的房间
@params channel CHAT_CHANNELS 频道类型
@return roomId int 房间id
--]]
function ChatSocketManager:GetJoinedChannelRoomId(channel)
    return self.joinedChannelRoomId[tostring(channel)]
end
--[[
加入聊天室
--]]
function ChatSocketManager:JoinChatRoom( roomId )
    --此处不再需要先记录，可能会引起问题，如果是先记录然后连接失败了就记录了错的上次房间
    -- self.preRoomId = roomId
    --1.先要退出房间然后才能再去加房间的逻辑
    self:JoinChatRoomByChannelAndRoomId(CHAT_CHANNELS.CHANNEL_WORLD, roomId)
end
--[[
根据channelId roomId 连接指定的聊天频道
@params channel CHAT_CHANNELS 频道类型
@params roomId int 房间id
--]]
function ChatSocketManager:JoinChatRoomByChannelAndRoomId(channel, roomId)
    self:SendPacket(NetCmd.RequestJoinChatroom, {
        channel = channel,
        room = roomId and checkint(roomId) or nil
    })
end
--[[
根据channelId roomId 断开指定的聊天频道
@params channel CHAT_CHANNELS 频道类型
@params roomId int 房间id
--]]
function ChatSocketManager:ExitChatRoomByChannelAndRoomId(channel, roomId)
    self:SendPacket(NetCmd.RequestOutChatroom, {
        channels = tostring(channel),
        room = roomId and checkint(roomId) or nil
    })
end
--[[
--
--]]
function ChatSocketManager:InsertMessageVo(chatDatas)
    local channel = checkint(chatDatas.channel)
    if (channel == CHAT_CHANNELS.CHANNEL_SYSTEM or 
        channel == CHAT_CHANNELS.CHANNEL_WORLD or 
        channel == CHAT_CHANNELS.CHANNEL_TEAM or 
        channel == CHAT_CHANNELS.CHANNEL_UNION or 
        channel == CHAT_CHANNELS.CHANNEL_HOUSE) then
        if self.chatAllMessage[tostring(channel)] then
            local len = table.nums(self.chatAllMessage[tostring(channel)])
            if len >= MAX_SHOW_MSG then
                table.remove(self.chatAllMessage[tostring(channel)], 1)
            end
            table.insert(self.chatAllMessage[tostring(channel)], chatDatas)
        end

    elseif channel == CHAT_CHANNELS.CHANNEL_PRIVATE then
        --插入数据库的逻辑
        local messagetype = 1
        if chatDatas.fileid ~= '' or chatDatas.fileid ~= 'nil' then
            messagetype = 2
        end
        if chatDatas.sender == MSG_TYPES.MSG_TYPE_SELF then
            ChatUtils.InertChatMessage({
                    sendPlayerId = self:GetGameManager():GetUserInfo().playerId,
                    sendPlayerName = self:GetGameManager():GetUserInfo().playerName,
                    receivePlayerId = chatDatas.friendId,
                    receivePlayerName = chatDatas.friendName,
                    content = chatDatas.message,
                    sendTime = chatDatas.sendTime,
                    messagetype = messagetype,
                    msgType = MSG_TYPES.MSG_TYPE_SELF
                })
        else
            ChatUtils.InertChatMessage({
                    receivePlayerId = self:GetGameManager():GetUserInfo().playerId,
                    receivePlayerName = self:GetGameManager():GetUserInfo().playerName,
                    sendPlayerId = chatDatas.friendId,
                    sendPlayerName = chatDatas.friendName,
                    content = chatDatas.message,
                    sendTime = chatDatas.sendTime,
                    messagetype = messagetype,
                    msgType = MSG_TYPES.MSG_TYPE_OTHER
                })

        end
    end
end
--[[
--具体和单个包的处理
--@param buffer 一个包体
--]]
function ChatSocketManager:AnalysePacket( buffer )
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
        --聊天连接成功后发送加入聊天室的接口的功能
        --发送登录聊天室接口的逻辑
        self:SendPacket( NetCmd.RequestPing)
        self:SendPacket( NetCmd.RequestWorldRoomsMessage) --世界面聊天人数
        self:JoinChatRoomByChannelAndRoomId(CHAT_CHANNELS.CHANNEL_SYSTEM)--进入系统聊天频道
        if checkint(self:GetGameManager():GetUserInfo().unionId) > 0 then
            self:JoinChatRoomByChannelAndRoomId(CHAT_CHANNELS.CHANNEL_UNION)--进入工会频道
        end
		return true
	end
	local packetCallback = self.packetHandlers[tostring( cmd )]
	if packetCallback then
		packetCallback(buffer)
		return true
	end
	if cmd == NetCmd.RequestPing then
        self.lastPingTime = socket.gettime()
		local ping = self.lastPingTime - self.mStartTime
        self.pingTimeoutNum = 0
		-- local ping = self.client.lastReceivedTime - self.lastPingTime
        -- funLog(Logger.INFO, "chat ping span ".. tostring( ping ))
		if self.onPing then
			self.onPing(ping)
		end
        -- self.mCanPing = true
        return true
    elseif cmd == NetCmd.Disconnect then
		self.mCanSend = false
        self.beginConnect = false
		if self.onDisconnect then
			self.onDisconnect()
		end
    elseif cmd == NetCmd.RequestWorldRoomsMessage then
        local roomId = 1
        if buffer.data.data and buffer.data.data.rooms then
            local roomIDs = sortByKey(checktable(buffer.data.data.rooms))
            local len = #roomIDs
            if len > 0 then
                if self.preRoomId >= len then
                    --如果前一次的房间大于所有的房间数
                    for id=len,1,-1 do
                        local val = buffer.data.data.rooms[tostring(id)]
                        if checkint(val.num) < checkint(val.max) then
                            --房间可加入
                            roomId = checkint(id)
                            break
                        end
                    end
                else
                    --如果前一次的房间小于所有的房间数
                    for id=self.preRoomId,len,1 do
                        local val = buffer.data.data.rooms[tostring(id)]
                        if checkint(val.num) < checkint(val.max) then
                            --房间可加入
                            roomId = checkint(id)
                            break
                        end
                    end
                end
            end
        end
        --然后加入房间
        self.preRoomId = roomId
        self:JoinChatRoomByChannelAndRoomId(CHAT_CHANNELS.CHANNEL_WORLD, self.preRoomId)
        self:SendPacket( NetCmd.RequestRegisterChatRoomMessage) --注册房间数据
	elseif cmd == NetCmd.RequestJoinChatroom then--进入聊天室
        if buffer.data and buffer.data.errcode then

            local channel = checkint(buffer.data.data.channel)
            local room = checkint(buffer.data.data.room)

            if checkint(buffer.data.errcode) ~= 0 then

                if CHAT_CHANNELS.CHANNEL_WORLD == channel then
                    if nil == self.selectedRoomId then
                        -- 自动连接的逻辑 无限+1
                        self.preRoomId = self.preRoomId + 1
                        self:JoinChatRoomByChannelAndRoomId(CHAT_CHANNELS.CHANNEL_WORLD, self.preRoomId)
                    else
                        app.uiMgr:ShowInformationTips(__('聊天室人数已满'))
                    end
                end

            else
                -- 记录当前频道加入的roomid
                local preRoomId = self:GetJoinedChannelRoomId(channel)
                self:SetJoinedChannelRoomId(channel, room)
                
                if CHAT_CHANNELS.CHANNEL_WORLD == channel then
                    -- 世界聊天连接成功
                    self.selectedRoomId = self.preRoomId

                    local chatView = sceneWorld:getChildByTag(GameSceneTag.Chat_GameSceneTag)
                    if chatView and chatView.isAction == false then
                        if preRoomId ~= room then
                            self.chatAllMessage[tostring(CHAT_CHANNELS.CHANNEL_WORLD)] = {}
                            -- view is in world channel
                            if chatView.curChannel == CHAT_CHANNELS.CHANNEL_WORLD then
                                chatView:CleanChatListView()
                            end
                        end
                        chatView:RefreshChatRoomId()
                    end

                end
            end
        end
	elseif cmd == NetCmd.RequestChatroomSendMessage then--聊天室发送消息
        -- dump(buffer.data.data)
        if buffer.data.data then
            local body = buffer.data.data
            --[[
            local parsedtable = LabelParser.parse(body.message)
            local tempTab = {}
            --过滤非法标签
            for i,v in ipairs(parsedtable) do
                if FILTERS[v.labelname] then
                    tempTab[v.labelname] = v.content
                end
            end
            local chatDatas = {}
            chatDatas.message = body.message or '<desc>....</desc>'
            chatDatas.sender = 1
            chatDatas.messageId = body.messageId
            chatDatas.name = body.name
            chatDatas.sendTime = body.sendTime or os.time()
            chatDatas.messagetype = tempTab['messagetype']
            chatDatas.fileid = tempTab['fileid']
            chatDatas.channel = body.channel
            chatDatas.playerId = body.playerId
            chatDatas.avatar = body.avatar
            self:InsertMessageVo(chatDatas)
            --]]
            AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.Chat_SendMessage_Callback, body)
        end
	elseif cmd == NetCmd.RequestChatroomGetMessage then--聊天室收到消息
        if buffer.data.data then
            local body = buffer.data.data
            -- dump(body)
            local parsedtable = LabelParser.parse(body.message)
            local tempTab = {}
            -- 判断是否接收世界信息
            --if not CommonUtils.GetControlGameProterty(CONTROL_GAME.WORLD_CHANNEL_PUSH) then
            --    return true
            --end
            --过滤非法标签
            for i,v in ipairs(parsedtable) do
                if FILTERS[v.labelname] then
                    tempTab[v.labelname] = v.content
                end
            end
            local chatDatas = {
                message     = body.message or '<desc>....</desc>' ,
                sender      = 1 ,
                messageId   = body.messageId ,
                name        = body.name ,
                sendTime    = body.sendTime or os.time() ,
                messagetype = tempTab['messagetype'] ,
                fileid      = tempTab['fileid'],
                channel     = body.channel,
                time        = body.time ,
                playerId    = body.playerId ,
                avatar      = body.avatar ,
                avatarFrame = body.avatarFrame
            }
            if IS_OPEN_CHAT_DELAY then
                local temp = {
                    chatDatas = chatDatas,
                    delayTime = math.random(30, 60)
                }
                -- 聊天延时显示处理
                temp.chatDatas.sendTime = checkint(temp.chatDatas.sendTime) + temp.delayTime
                table.insert(self.chatRoomDelayMsgs, temp)
            else
                self:InsertMessageVo(chatDatas)
                AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.Chat_GetMessage_Callback, chatDatas)
            end
        end
	elseif cmd == NetCmd.RequestOutChatroom then--退出聊天室

        -- 置空
        if nil ~= buffer.data.data.channels then
            for i, channel in ipairs(buffer.data.data.channels) do
                self:SetJoinedChannelRoomId(checkint(channel), nil)
            end
        end


	elseif cmd == NetCmd.RequestPrivateSendMessage then--发送私信
        -- dump(buffer.data.data)
        if buffer.data.data then
            local body = buffer.data.data
            --[[
            local parsedtable = LabelParser.parse(body.message)
            local tempTab = {}
            --过滤非法标签
            for i,v in ipairs(parsedtable) do
                if FILTERS[v.labelname] then
                    tempTab[v.labelname] = v.content
                end
            end
            local chatDatas = {}
            chatDatas.message = body.message or '<desc>....</desc>'
            chatDatas.sender = 1
            chatDatas.messageId = body.messageId
            chatDatas.name = body.name
            chatDatas.sendTime = body.sendTime or os.time()
            chatDatas.messagetype = tempTab['messagetype']
            chatDatas.fileid = tempTab['fileid']
            chatDatas.channel = body.channel
            chatDatas.playerId = body.playerId
            chatDatas.avatar = body.avatar
            self:InsertMessageVo(chatDatas)
            --]]
            AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.Chat_SendPrivateMessage_Callback, body)
        end
	elseif cmd == NetCmd.RequestPrivateGetMessage then--收到私信
        if buffer.data.data.messages then
            local messages = buffer.data.data.messages
            for name,body in pairs(messages) do
                local parsedtable = LabelParser.parse(body.message)
                local tempTab = {}
                --过滤非法标签
                for i,v in ipairs(parsedtable) do
                    if FILTERS[v.labelname] then
                        tempTab[v.labelname] = v.content
                    end
                end
                local chatDatas = {
                    message     = body.message or '<desc>....</desc>',
                    sender      = MSG_TYPES.MSG_TYPE_OTHER,
                    messageId   = body.messageId,
                    name        = body.friendName,
                    friendName  = body.friendName,
                    sendTime    = body.sendTime or os.time(),
                    messagetype = tempTab['messagetype'],
                    fileid      = tempTab['fileid'],
                    channel     = CHAT_CHANNELS.CHANNEL_PRIVATE,
                    playerId    = body.playerId,
                    friendId    = body.friendId,
                    avatar      = body.avatar,
                }
                self:InsertMessageVo(chatDatas)
                self:SendPacket( NetCmd.RequestSurePrivateGetMessage, {messageId = body.messageId})
                -- 最新消息存入数据库
                local temp = {
                    playerId = checkint(body.friendId),
                    newMessage = body.message,
                    lastReceiveTime = body.sendTime,
                    hasNewMessage = 1
                }
                ChatUtils.UpdatePlayerNewMessage(temp)
                -- 添加好友系统小红点显示
                app.dataMgr:AddRedDotNofication(tostring(RemindTag.FRIENDS),RemindTag.FRIENDS, "[添加好友] --ChatSocketManager")
                AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, {countdown = 0, tag = RemindTag.FRIENDS})
                local chatView = sceneWorld:getChildByTag(GameSceneTag.Chat_GameSceneTag)
                if chatView and chatView.isAction == false then
                    chatView:ReceiveMessage(body)
                end
                AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.Chat_GetPrivateMessage_Callback, chatDatas)
            end
        end
	elseif cmd == NetCmd.RequestSurePrivateGetMessage then--确认收到私信
	elseif cmd == NetCmd.RequestRegisterChatRoomMessage then--聊天室注册数据
        -- dump(buffer.data.data)
	else
		funLog(Logger.INFO, buffer)
	end
	return true
end
--[[
世界聊天信息延迟展示
--]]
function ChatSocketManager:ChatRoomMsgDelayDisplay()
    local curTime = os.time()
    local deltaTime = math.abs(curTime - self.chatRoomPreTime)
    self.chatRoomPreTime = curTime
    for i = #self.chatRoomDelayMsgs, 1, -1 do
        local v = self.chatRoomDelayMsgs[i]
        v.delayTime = v.delayTime - deltaTime
        if v.delayTime <= 0 then
            self:InsertMessageVo(v.chatDatas)
            AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.Chat_GetMessage_Callback, v.chatDatas)
            table.remove(self.chatRoomDelayMsgs, i)
        end
    end
end
return ChatSocketManager

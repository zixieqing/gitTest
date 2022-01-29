local TcpProtocol = class("TcpProtocol")

local Stage = Enum (
{
	NotConnected = 1,  -- 未连接
	Connecting   = 2,  -- 连接中
	Verifying    = 3,  -- 验证中
	Connected    = 4,  -- 已连接
})

local ByteArray = require('cocos.framework.ByteArray')
local PacketBuffer = require('cocos.framework.PacketBuffer')
local scheduler = require('cocos.framework.scheduler')
local socket = require('socket')
local zlib = require("zlib")

local STATUS_ALREADY_CONNECTED = "already connected"

local CONNECT_TIMEOUT = 10
local FLOAT_MAX = 100000
--[[--
将 table转为urlencode的数据
@param t table
@see string.urlencode
]]
local function tabletourlencode(t)
    local args = {}
    local i = 1
    for key, value in pairs(t) do
        args[i] = string.urlencode(key) .. '=' .. string.urlencode(value)
        i = i + 1
    end
    return table.concat(args,'&')
end

local generateSign = function ( t )
    local apisalt = FTUtils:generateKey(SIGN_KEY)
    local keys = table.keys(t)
    table.sort(keys)
    local retstring = "";
    local tempt = {}
    for _,v in ipairs(keys) do
        table.insert(tempt,t[v])
    end
    if table.nums(tempt) > 0 then
        retstring = table.concat(tempt,'')
    end
    retstring = retstring .. apisalt
    return crypto.md5(retstring)
end

function TcpProtocol:ctor(name, logType)
	self.name = name or "Guest" -- 当前名字
	self.logType_ = logType
	self:Initial()
	self:addLogInfo(string.fmt('----> init %1', name))
end
---------------------
---------长连接的相关逻辑
-----------------------

function TcpProtocol:Initial(  )
	self.version = 1 -- 版本
	self.playerId = 0 --玩家角色id
	self.stage = Stage.NotConnected --当前状态为未连接
	self.tcpHost = "" --连接服务端的host
	self.lastReceivedTime = 0 --上次接收数据的时间缀
	self.timeoutTime = 0.5 --初始的接收数据的超时时间
	self.mInQueue = {} --接收的数据队列
	self.mOutQueue = {} --要发送的数据队列

	self.mReceiveBuffer = PacketBuffer.new() --接收数据存
	self.mSocket = nil --当前连接的socket
    self.sock_fd = -1
	self.noDelay = false --是否直接连接
	self.mConnecting = {} --当前正在连接服务器的socket列表
	self.socketConnected = false --socket是否已经连接成功
	-- self.onSendScheduler = nil --发数据的scheduler
	self.onReceiveScheduler = nil --接收数据的scheduler
	self.isReceiving = true --是否正在接收
    self.isSending = true --是否正在发送
    self.mCanSend = true --是否可发送数据
    self.startIndex = 1
    self.allHosts = {}
    self.isStart = true -- 是开始连接的逻辑功能
end

--[[
-- 公共参数列表
--]]
function TcpProtocol:BeginSend(cmd, _msg )
    if self.mSocket then
        if cmd == NetCmd.RequestPing then
            self:addPingLog(1)
        else
            if _msg then
                self:addLogInfo(string.fmt('----> beginSend cmd=%1 (%2), data=%3', cmd, tostring(logInfo.cmdNameMap[cmd]), tableToString(_msg, nil, 10)))
            else
                self:addLogInfo(string.fmt('----> beginSend cmd=%1 (%2)', cmd, tostring(logInfo.cmdNameMap[cmd])))
            end
        end
        if cmd == NetCmd.RequestID or cmd == NetCmd.RequestPing then
            local buffer = PacketBuffer.createPacket(cmd)
            return buffer
        else
            local sessionId = app.gameMgr.userInfo.sessionId or ''
            local playerId = app.gameMgr.userInfo.playerId or 0
            local version = utils.getAppVersion(true)
            local serverId = checkint(app.gameMgr.userInfo.serverId)
            local t = utils.getcommonParameters({channel = Platform.id,serverId = serverId, sessionId = sessionId,playerId=playerId,version=version})
            if t == nil then
                return
            end
            if touch_info then
                t.touch_x = math.floor(tonumber(touch_info.touch_x or 0) * FLOAT_MAX)
                t.touch_y = math.floor(tonumber(touch_info.touch_y or 0) * FLOAT_MAX)
                t.touch_t = math.floor(tonumber(touch_info.touch_t or 0) * FLOAT_MAX)
            end
            if _msg then
                table.merge(t, _msg)
            end
            if device.platform == 'android' then
                t['os'] = 2
            elseif device.platform == 'ios' then
                t['os'] = 1
            end
            if isElexSdk() then
                local appFlyerId = cc.UserDefault:getInstance():getStringForKey("APPFLYER_DEVICEID", "")
                t['appsFlyerId'] = appFlyerId
                if device.platform == 'android' then
                    local androidId = cc.UserDefault:getInstance():getStringForKey("ANDROID_IDFA", "")
                    t['idfa'] = androidId
                end
            end

            -- local pureTime = os.time(os.date("!*t", os.time()))
            -- t['timestamp'] = pureTime
            local sign = generateSign(t)
            t['sign'] = sign
            ------------ 压缩报文 ------------
            local djson = json.encode(t)
            local compressed = zlib.deflate(5, 15 + 16)(djson, "finish")
            if not compressed then
                compressed = djson
            end
            if DEBUG and DEBUG > 0 then
                funLog(Logger.DEBUG, string.format('[%s] >>>> %s \n\t%s\n', self.name, tostring(cmd), json.encode(t)))
            else
                funLog(Logger.INFO, string.format('[%s] >>>> %s', self.name, tostring(cmd)))
            end
            -- dump(compressed)
            ------------ 压缩报文 ------------
            -- local buffer = PacketBuffer.createPacket(cmd,json.encode(t))
            local buffer = PacketBuffer.createPacket(cmd, compressed)
            return buffer
        end
    end
end


function TcpProtocol:GetSocket( )
	return self.mSocket
end
--[[
--是否是已经成功的状态
--并且已经验证通过了逻辑
---]]
function TcpProtocol:IsConnected( )
	return self.stage == Stage.Connected
end
--[[
--是否是正在尝试连接的状态
---]]
function TcpProtocol:IsTryingToConnect(  )
	return (next(self.mConnecting) ~= nil)
end
--[[
-- 设置是否延时
--]]
function TcpProtocol:SetNodelay( noDelay )
	if self.noDelay ~= noDelay then
		self.noDelay = noDelay
		self.mSocket:setoption('tcp-nodelay',self.nodelay)
	end
end


function TcpProtocol:OnConnected()
    --连接成功后写入玩家id
    self.socketConnected = true --已经连接
    self.mCanSend = true
    self.isReceiving = true --是否正在接收
    self.isSending = true --是否正在发送
    self.stage = Stage.Verifying;
    self.mReceiveBuffer = PacketBuffer.new() --接收数据存
    funLog(Logger.DEBUG, "=======Connected success ===" .. self.name)
        -- if not self.onSendScheduler then
        -- xTry(function (  )
            -- self.onSendScheduler = scheduler.scheduleGlobal(handler(self, self.StartSending),0.1)
        -- end,function (  )
        -- funLog(Logger.ERROR, debug.traceback())
        -- self:Close(true)
    -- end)
    -- end
    --2 开始接收数据
    if not self.onReceiveScheduler then
        xTry(function (  )
            self.onReceiveScheduler = scheduler.scheduleGlobal(handler(self, self.StartReceiving),0.1)
        end,function (  )
            funLog(Logger.ERROR, debug.traceback())
            self:Close(true)
        end)
    end
    for i, v in ipairs( self.mConnecting ) do
        if ID(v) == cID then
            self.mConnecting[i] = nil --移除连接缓存
        end
    end

    --先启动接收，再进行数据发送，防止数据丢失
    local buffer = self:BeginSend(NetCmd.RequestID)
    self:SendTcpPacket(buffer) --发送一个数据包
end
--[[
-- 启动连接的逻辑处理
-- @host ip
-- @port port the ip port
--]]
function TcpProtocol:Connect( host, port )
	-- self:Disconnect(false)
    if self.isStart then
        self.isStart = false --禁止添加新的ip进入
        if self.name == 'GameInfoSocket' then
            table.insert(self.allHosts, 1, host)
        else
            self.allHosts = {}
        end
    end
    local targetHost = host
    if table.nums(self.allHosts) > 0 then
        if self.startIndex > table.nums(self.allHosts) then
            self.startIndex = 1
        end
        targetHost = self.allHosts[self.startIndex]
    end
    self.tcpHost = targetHost
	self.port = port
	self.mInQueue = {}
	self.mOutQueue = {}
	self.stage = Stage.Connecting --正在连接的状态
	local isipv6_only = false
    if FOR_REVIEW then
        --不能使用ip进行连接
        local addrinfo,err = socket.dns.getaddrinfo("google.com")
        if addrinfo ~= nil then
            for k,v in pairs(addrinfo) do
                if v.family == 'inet6' then
                    isipv6_only = true
                    break
                else
                    break
                end
            end
        end
    end
    if isipv6_only then
        self.mSocket = socket.tcp6()
    else
        self.mSocket = socket.tcp()
    end
    self.sock_fd = -1
    self.mSocket:settimeout(0) -- 第一次连接服务器的超时时间
    -- self.mSocket:setoption('keepalive', true)
    -- self.mSocket:setoption('tcp-nodelay', true)
    -- self.mSocket:setoption('linger', {on = true, timeout = 0.2});  -- on:true 断线后再连接时，不发送之前的阻塞的数据。
    table.insert(self.mConnecting, self.mSocket)
    --开始连接的操作
    -- local socketIp = Platform.ip
    -- if isipv6_only then
    -- 	socketIp = "2001:2:0:1baa::"
    -- 	local itype, name = GetIpType(Platform.ip)
    -- 	if itype == 1 then
    -- 		--ipv4的逻辑
    -- 		local t = string.split(Platform.ip, ".")
    -- 		if #t == 4 then
    -- 			socketIp = string.format( "%s:%s%s:%s%s",socketIp, string.format( "%02x",tostring(t[1])),string.format( "%02x",tostring(t[2])),
    -- 							string.format( "%02x",tostring(t[3])),string.format( "%02x",tostring(t[4])))
    -- 		end
    -- 	end
    -- end
    self.tcpHost = targetHost
    local cID = ID(self.mSocket)
    self:addLogInfo(string.fmt('----> to connect [host:%1 port:%2 socketID:%3]', targetHost, port,cID))
    local __succ, __status = self.mSocket:connect(self.tcpHost, port)
    local isConnected = (__succ == 1 or __status == STATUS_ALREADY_CONNECTED)
    self:addLogInfo(string.fmt('----> connect %1:%2 (isConnected = %3)', tostring(__succ), tostring(__status), isConnected))
    if isConnected then
        self.sock_fd = self.mSocket:getfd()
        self:OnConnected()
        for i, v in ipairs( self.mConnecting ) do
            if ID(v) == cID then
                self.mConnecting[i] = nil --移除连接缓存
            end
        end
    else
        local startTicker = os.time()
        --检测是否连接
        local __connectTimeTick = function ()
            local span = os.time() - startTicker
            if span > CONNECT_TIMEOUT then
                --连接失败
                if self.connectTimeTicker then
                    scheduler.unscheduleGlobal(self.connectTimeTicker)
                    self.connectTimeTicker = nil
                end
                self:Release()
                self.startIndex = self.startIndex + 1
                for i, v in ipairs( self.mConnecting ) do
                    if ID(v) == cID then
                        self.mConnecting[i] = nil --移除连接缓存
                    end
                end
                --重新调用连接的逻辑
                self:Connect(self.tcpHost, port)
                --不停的重试连接
                startTicker = os.time()
            else
                local arr = {self.mSocket}
                local recvt, sendt, error = socket.select(nil, arr, 0);
                if sendt and #sendt == 1 and sendt[1] == self.mSocket and (not error) then
                    isConnected  = true
                    self.sock_fd = self.mSocket:getfd()
                    if self.connectTimeTicker then
                        scheduler.unscheduleGlobal(self.connectTimeTicker)
                        self.connectTimeTicker = nil
                    end
                    for i, v in ipairs( self.mConnecting ) do
                        if ID(v) == cID then
                            self.mConnecting[i] = nil --移除连接缓存
                        end
                    end
                    self:addLogInfo(string.fmt('----> reconnect %1:%2 (isConnected = %3)', self.tcpHost, port, isConnected))
                    self:OnConnected()
                end
            end
        end
        if self.connectTimeTicker then
            scheduler.unscheduleGlobal(self.connectTimeTicker)
            self.connectTimeTicker = nil
        end
        self.connectTimeTicker = scheduler.scheduleGlobal(__connectTimeTick, 0.5)

		if isElexSdk() and DEBUG == 0 and (not FOR_REVIEW) and (not PRE_RELEASE_SERVER) and (not ZM_SMALL_PACKAGE) and ZM_MIN_TTL_IP and ZM_MIN_TTL_IP[tostring(port)] then
			-- if ZM_MIN_TTL_IP[tostring(port)] then
			local connection = require("root.connection")
			local serverNo = 0
			local ZM_MIN_TTL = 4000
			--访问源站
			local startTime = FTUtils:currentTimeMillis()
			connection.network_test(host, port, function(isAvailable)
				if isAvailable then
					local endTime = FTUtils:currentTimeMillis()
					local ttl = endTime - startTime
					self:addLogInfo(string.fmt('----> test tcp network =%1 (%2), ttl=%3', tostring(host), tostring(port), tostring(ttl)))
					if ttl < ZM_MIN_TTL then
						host = host
					end
				end
				serverNo = serverNo + 1
			end)

			local targetServerProxy = ZM_MIN_TTL_IP[tostring(port)]
			local startTime = FTUtils:currentTimeMillis()
			local ip_host = string.split(targetServerProxy,":")
			connection.network_test(ip_host[1], ip_host[2], function(isAvailable)
				if isAvailable then
					local endTime = FTUtils:currentTimeMillis()
					local ttl = endTime - startTime
					self:addLogInfo(string.fmt('----> test tcp proxy network =%1 (%2), ttl=%3', tostring(ip_host[1]), tostring(ip_host[2]), tostring(ttl)))
					if ttl < ZM_MIN_TTL then
						host = ip_host[1]
						port = ip_host[2]
					end
				end
				serverNo = serverNo + 1
			end)
		else
			__connectTimeTick()
		end
    end
    --[[
    local cID = ID(self.mSocket)
    if isConnected then
        --连接成功后写入玩家id
        self.socketConnected = isConnected --已经连接
        self.stage = Stage.Verifying;
        self.mReceiveBuffer = PacketBuffer.new() --接收数据存
        funLog(Logger.DEBUG, "=======Connected success ===" .. self.name)
        local buffer = self:BeginSend(NetCmd.RequestID)
        self:SendTcpPacket(buffer) --发送一个数据包
        if not self.onSendScheduler then
            xTry(function (  )
                self.onSendScheduler = scheduler.scheduleGlobal(handler(self, self.StartSending),0.1)
            end,function (  )
                funLog(Logger.ERROR, debug.traceback())
                self:Close(true)
            end)
        end
        --2 开始接收数据
        if not self.onReceiveScheduler then
            xTry(function (  )
                self.onReceiveScheduler = scheduler.scheduleGlobal(handler(self, self.StartReceiving),0.1)
            end,function (  )
                funLog(Logger.ERROR, debug.traceback())
                self:Close(true)
            end)
        end
    else
        --连接失败
        self:Error("Failed to connect")
        self:Close(false)
    end
    for i, v in ipairs( self.mConnecting ) do
        if ID(v) == cID then
            self.mConnecting[i] = nil --移除连接缓存
        end
    end
    --]]

end

--[[
-- 开始接收数据
--]]
function TcpProtocol:StartReceiving(dt)
    if self.stage == Stage.NotConnected then return end
    xTry(function ( )
        self:OnReceive()
    end, __G__TRACKBACK__)
end

-- function TcpProtocol:StartSending( dt )
	-- if self.stage == Stage.NotConnected then return end
	-- self:OnSend()--开始发数据
-- end
--[[
-- 发送数据
-- @param buffer 发送数据的buffer
--]]
function TcpProtocol:SendTcpPacket( buffer )
	if self.stage == Stage.NotConnected then return end
	if self.mSocket and self.socketConnected then
		table.insert(self.mOutQueue,buffer) --加入一个数据
        self:OnSend()
	else
		self.mBuffer = nil --发送的buffer设置为空
	end
end

function TcpProtocol:OnSend( )
	if self.mSocket and self.socketConnected and #self.mOutQueue > 0 and self.isSending and self.mCanSend then
        self.isSending = false
        local buffer = table.remove(self.mOutQueue, 1)
        if buffer and buffer:getLen() > 0 then
            local bytes, err, partial = self.mSocket:send(buffer:getPack())
            if bytes == nil and err == 'closed' then
                --socket关闭连接了
                funLog(Logger.DEBUG, "=======发送socket数据异常引起close操作===" .. self.name)
                self.mCanSend = false
                table.insert(self.mOutQueue,buffer)
                self:Close(true)
            else
                --发送下一个数据包
                local nextBuffer = nil
                if #self.mOutQueue > 0 then
                    nextBuffer = self.mOutQueue[1]
                end
                if nextBuffer then
                    self.isSending = true
                    self:OnSend() --循环发数据
                else
                    self.isSending = true
                end
            end
        end
    end
end

function TcpProtocol:OnReceive( )
	if self.mSocket and self.socketConnected and self.isReceiving then
		self.lastReceivedTime = socket.gettime()
		self.isReceiving = false
		local __body, __status, __partial = self.mSocket:receive(512)
        if __status and #__status == 'closed' then
            --长连接断掉了
            self.mCanSend = false -- 客户端某原因断掉了，不再发送数据，之前命令暂存
            self.isReceiving = false
            self:Close(true)
        else
            if  (__body and string.len(__body) == 0) or
                (__partial and string.len(__partial) == 0) then
                self.isReceiving = true
                return
            end
            if __body and __partial then __body = __body .. __partial end
            -- if DEBUG > 0 then
            --     cclog('socket receive data', ByteArray.toString(__partial or __body, 16) )
            -- end
            local __msgs = self.mReceiveBuffer:parsePackets((__body or __partial))
            local __msg = nil
            for i=1,#__msgs do
                __msg = __msgs[i]
                ---[[--
                -- 再做一次返回的数据验证
                ---]]
                if __msg.body and type(__msg.body) == 'string' then
                    local jdata = json.decode(__msg.body)
                    if jdata and jdata.sign then
                        local text = string.format('%scf1251bc88264d9ec4061cef7214d372',(jdata.rand or ''))
                        local rsign = crypto.md5(text)
                        if rsign == jdata.sign then
                            --将数据加入接收数据
                            if __msg.command == NetCmd.RequestPing then
                                self:addPingLog(2)
                            else
                                self:addLogInfo(string.fmt('<---- onReceive cmd=%1 (%2), data=%3', __msg.command, tostring(logInfo.cmdNameMap[__msg.command]), tableToString(next(checktable(jdata.data)) ~= nil and jdata.data or jdata, nil, 10)))
                            end
                            table.insert(self.mInQueue, {cmd = __msg.command, data = jdata})
                        else
                            self:addLogInfo(string.fmt('<---- onReceive cmd=%1 (%2), verify sign error', __msg.command, tostring(logInfo.cmdNameMap[__msg.command])))
                        end
                    else
                        self:addLogInfo(string.fmt('<---- onReceive cmd=%1 (%2), json format error / none [sign]', __msg.command, tostring(logInfo.cmdNameMap[__msg.command])))
                    end
                else
                    self:addLogInfo(string.fmt('<---- onReceive cmd=%1 (%2), [body] type error / none [body]', __msg.command, tostring(logInfo.cmdNameMap[__msg.command])))
                end
            end
            if self.stage == Stage.NotConnected then
                self.isReceiving = true
                return
            end
            self.isReceiving = true
            -- self:OnReceive()
        end
	end
end
--[[
--接收响应数据
--@return  是否有数据, 返回的数据
--]]
function TcpProtocol:ReceivePacket( )
	if next(self.mInQueue) ~= nil then
		return true, table.remove( self.mInQueue,1)
	else
		return false, nil
	end
end
--[[
-- 断开连接的逻辑处理
-- @param notify 是否通知道其他层断开连接的消息
--]]
function TcpProtocol:Disconnect( notify)
	if not self.socketConnected then return end
	funLog(Logger.INFO, "########### == Disconnect =====############" .. self.name)
	self:addLogInfo(string.fmt('----> disconnect (notify = %1)', notify))
	local function discnonect()
		for k, v in pairs( self.mConnecting ) do
			local psocket = v
			if psocket then
				psocket:close()
			end
			self.mConnecting[k] = nil --移除操作
		end
		if self.mSocket then
			self:Close(notify or self.socketConnected)
		end
	end
	xTry(discnonect,function(...)
		-- if self.onSendScheduler then
			-- scheduler.unscheduleGlobal(self.onSendScheduler)
		-- end
        if self.onReceiveScheduler then
            scheduler.unscheduleGlobal(self.onReceiveScheduler)
            self.onReceiveScheduler = nil
        end
		self.mConnecting = {} --清空
		if self.mSocket then
			self.mSocket:close() --关才
            self.mSocket = nil
            self.sock_fd = -1
		end
	end)
	self.socketConnected = false
end
--[[
-- 真正断开链接的操作逻辑
-- @param notify 是否通知上层已断开
--]]
function TcpProtocol:Close( notify )
    if self.connectTimeTicker then
        scheduler.unscheduleGlobal(self.connectTimeTicker)
        self.connectTimeTicker = nil
    end
	self.stage = Stage.NotConnected
	if self.mReceiveBuffer then
		self.mReceiveBuffer = nil
	end
	if self.mSocket then
		if self.socketConnected then
			--如果已经和服务器建立的连接
			self.mSocket:shutdown("both")
		end
		self.socketConnected = false
        self.mSocket:close()
        self.mSocket = nil
        self.sock_fd = -1
		self.isReceiving = true --是否正在接收
        self.isSending = true --是否正在发送
		if notify then
			--添加一个特殊消息命令
			table.insert(self.mInQueue, {cmd = NetCmd.Disconnect})
		end
	end
	funLog(Logger.INFO, "=========Close==========" .. self.name )
	self:addLogInfo(string.fmt('----> close (notify = %1)', notify))
end
--[[
Release the buffers.
--]]
function TcpProtocol:Release(isQuick)
    funLog(Logger.INFO, '----------->> Release socket ----->>' )
	self:addLogInfo('----> release')
    -- if self.onSendScheduler then
        -- scheduler.unscheduleGlobal(self.onSendScheduler)
    -- end
    if self.onReceiveScheduler then
        scheduler.unscheduleGlobal(self.onReceiveScheduler)
        self.onReceiveScheduler = nil
    end
    if self.mSocket and isQuick then
        self.mSocket:setoption('linger', {on = false, timeout = 0})
    end
	self:Close(false)
	self.mInQueue = {}
	self.mOutQueue = {}
	self.isReceiving = false --是否正在接收
    self.isSending = false --是否正在发送
    self.socketConnected = false --断开连接
end
--[[
-- 出现错误信息
-- @param msg 出现错误信息
--]]
function TcpProtocol:Error( msg )
	--添加一个特殊消息命令
    funLog(Logger.INFO, '----------->> some error----->>' .. msg)
	table.insert(self.mInQueue, {cmd = NetCmd.Error})
end

function TcpProtocol:VerifyRequestID( cmd )
	if cmd == NetCmd.RequestID then
		self.stage = Stage.Connected
		return true
	end
end


function TcpProtocol:addLogInfo(logStr)
    if self.logType_ ~= nil then
		logInfo.add(self.logType_, self.sock_fd .. ')' .. tostring(logStr))
	end
end


function TcpProtocol:addPingLog(pingModel)
    if self.logType_ ~= nil then
		logInfo.ping(self.logType_, pingModel)
	end
end


return TcpProtocol

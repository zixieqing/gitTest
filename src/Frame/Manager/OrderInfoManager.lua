--[[
游戏网络请求模块
--]]
local ManagerBase = require( "Frame.Manager.ManagerBase" )
---@class OrderInfoManager
local OrderInfoManager = class('OrderInfoManager',ManagerBase)

local scheduler = require('cocos.framework.scheduler')

local zlib = require("zlib")

OrderInfoManager.instances = {}


local ORDER_TRY_NUM = 20 --尝试最大次数

local TIME_DELTA = 5

local Request = {}
local LIMIT_LOG = 60000

local PAY_ORDERINFO_PATH = 'pay/orderInfo'

function Request:New( ... )
	local arg = unpack({...})
	local this = {}
	setmetatable( this, {__index = Request})
    this.id   = arg.id
	this.path = arg.path
    this.isGet = (arg.isGet or false)
    this.data = arg.data
    this.signalName = arg.signalName
    this.handleError = (arg.error or false)
    this.async  = (arg.async or false)
    this.tryNum = 1 --初始尝试次数
    return this
 end
--[[--
将 table转为urlencode的数据
@param t table
@see string.urlencode
]]
local function tabletourlencode(t)
    local args = {}
    local i = 1
    local keys = table.keys(t)
    table.sort(keys)
    if next( keys ) ~= nil then
        for k, key in pairs( keys ) do
            args[i] = string.urlencode(key) .. '=' .. string.urlencode(t[key])
            i = i + 1
        end
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

function OrderInfoManager:ctor( key )
	self.super.ctor(self)
	if OrderInfoManager.instances[key] ~= nil then
		return
	end
	self.requests = {} -- 所有的请求记录
    self.startTime = os.time() --启动时间
    if self.updateHandler then
        scheduler.unscheduleGlobal(self.updateHandler)
        self.updateHandler = nil
    end
    self.isBusy = false
    --10秒一次请求
    self.updateHandler = scheduler.scheduleGlobal(handler(self, self.StartRequest), 1)
	OrderInfoManager.instances[key] = self
end

function OrderInfoManager.GetInstance(key)
	key = (key or "OrderInfoManager")
	if OrderInfoManager.instances[key] == nil then
		OrderInfoManager.instances[key] = OrderInfoManager.new(key)
	end
	return OrderInfoManager.instances[key]
end

function OrderInfoManager.Destroy( key )
	key = (key or "OrderInfoManager")
	if OrderInfoManager.instances[key] == nil then
		return
	end
    --清除配表数据
    local mySelf = OrderInfoManager.instances[key]
    mySelf.requests = {} -- 所有的请求记录
    if mySelf.updateHandler then
        scheduler.unscheduleGlobal(mySelf.updateHandler)
        mySelf.updateHandler = nil
    end
	OrderInfoManager.instances[key] = nil
end

--[[
=============网络请求相关的方法
--]]

function OrderInfoManager:StartRequest( dt )
    local curTime = os.time()
    if math.floor(curTime - self.startTime) >= TIME_DELTA then
        self.startTime = curTime
        --发请求的逻辑
        if next(self.requests) ~= nil and (not self.isBusy) then
            self.isBusy = true
            local gameManager = self:GetGameManager()
            local request = self.requests[1]
            --如果是定单信息接口的逻辑
            if checkint(request.tryNum) > ORDER_TRY_NUM then
                --10次后的尝试未成功，删除不在尝试
                self:RemoveRequest( request.id )
                self.isBusy = false
            else
                --然后发请求的逻辑
                local url = table.concat({'http://',Platform.ip,'/',request.path},'')
                if HTTP_USE_SSL then
                    url = table.concat({'https://',Platform.ip,'/',request.path},'')
                end
                funLog(Logger.DEBUG, url)
                local xhr = cc.XMLHttpRequest:new()
                xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
                -- xhr:setRequestHeader("Host",tostring(Platform.serverHost))
                xhr.timeout = 7
                xhr:open("POST", url)
                logInfo.add(logInfo.Types.HTTP, string.fmt('--> request %1 %2\n%3', 'POST', url, tableToString(request.data or {})))

                local function netBack()
                    local stateValue = 'parse'
                    local result = nil
                    if xhr.readyState == 4 and (xhr.status >= 200 and xhr.status < 207) then
                        local responseStr = xhr.response
                        local isLimitStr = false
                        if DEBUG > 0 then
                            isLimitStr = string.len(responseStr) > LIMIT_LOG
                            if isLimitStr then
                                -- FIXME 数据量过大，调试输出窗口导致崩溃
                                local subResponseStr = string.sub(responseStr, LIMIT_LOG)
                                funLog(Logger.DEBUG, subResponseStr, request.path .. 'get_success')
                            else
                                funLog(Logger.DEBUG, responseStr, request.path .. 'get_success')
                            end
                        end
                        local jdata = json.decode(responseStr)
                        if jdata == nil then
                            stateValue = 'parse'
                        else
                            result = jdata
                            if jdata.rand then
                                -- 请求成功，显示服务端返回的内容
                                local text = string.format('%scf1251bc88264d9ec4061cef7214d372',(jdata.rand or ''))
                                local rsign = crypto.md5(text)
                                if rsign ~= jdata.sign then
                                    local alertClick = function()
                                        cc.Director:getInstance():endToLua()
                                        if device.platform == 'ios' or device.platform == 'mac' or device.platform == 'android' then
                                            os.exit()
                                        end
                                    end
                                    device.showAlert(__('警告'), __('您当前的响应数据非法'), __('确定'),alertClick)
                                else
                                    stateValue = 'success'
                                end
                            end
                        end
                    else
                        stateValue = 'parse'
                    end
                    logInfo.add(logInfo.Types.HTTP, string.fmt('--> netBack %1 %2\n%3', "POST", url, tableToString(result, nil, 10)))
                    self:AfterRequest({id = request.id, state = stateValue, result = result, url = url, data = request.data, method = "POST", signalName = request.signalName, handleError = request.handleError, isLimitStr = isLimitStr, async = request.async})
                end
                local userInfo = gameManager.userInfo
                local sessionId= userInfo.sessionId or ''
                local playerId = checkint(userInfo.playerId)
                local version = utils.getAppVersion(true)
                local baseversion = utils.getAppVersion()
                local lang   = i18n.getLang()
                local t = utils.getcommonParameters({channel = Platform.id, lang = lang, serverId = checkint(userInfo.serverId),sessionId = sessionId,playerId=playerId,version=version,baseversion=baseversion})
                if t == nil then
                    device.showAlert(__('警告'), __('解析参数出错'), __('确定'))
                    return
                end
                if request.data then
                    table.merge(t, request.data)
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
                -- local ret = tabletourlencode(t)
                local sign = generateSign(t)
                -- ret = string.format("%s&sign=%s",ret,sign)
                t['sign'] = sign
                local djson = json.encode(t)
                local compressed = zlib.deflate(5, 15 + 16)(djson, "finish")
                if not compressed then compressed = djson end
                if DEBUG and DEBUG > 0 then
                    funLog(Logger.DEBUG, t)
                end
                xhr:setRequestHeader("User-Agent", string.format('U:%s,P:%s',tostring(userInfo.userId),tostring(playerId)))
                xhr:setRequestHeader('Content-Type', 'application/json')
                xhr:registerScriptHandler(netBack)
                xhr:send(compressed)
            end
        end
    end
end


function OrderInfoManager:AfterRequest( params )
    local url = params.url
    local id = params.id
    local URL = require('cocos.cocos2d.URL')
    local t = URL.parse(url)
    local path = t.path
    path = string.sub(path, 2)
    self:UpdateRequestTryNum(id)
    local signalName = params.signalName
    self.isBusy = false
    if params.state == 'success' then
        xTry(function (  )
            --将数据分发出去
            if table.nums(checktable(checktable(params.result).data)) > 0 then
                if params.data then --将请求的参数数据再带回来
                    params.result.data.requestData = {}
                    params.result.data.requestData = params.data
                end
                local errorcode = checkint(params.result.errcode)
                if errorcode == 0 then
                    --succc有逻辑
                    self:RemoveRequest(id) --成功后移除
                    AppFacade.GetInstance():DispatchObservers(signalName,params.result.data)
                end
            end
        end,__G__TRACKBACK__)
    end
end

function OrderInfoManager:UpdateRequestTryNum( id )
    for i, v in ipairs( self.requests ) do
        if v.id == id then
            v.tryNum = checkint(v.tryNum) + 1
            break
        end
    end
end

function OrderInfoManager:RemoveRequest( id )
    if next(self.requests) ~= nil then
        local pos = 0
        funLog(Logger.DEBUG, "RemoveRequest: " .. id )
        for i, v in ipairs( self.requests ) do
            if v.id == id then
                pos = i
                break
            end
        end
        if pos > 0 then
            table.remove( self.requests, pos )
        end
    end
end

function OrderInfoManager:HasRequest( id )
	local has = false
	for i, v in ipairs( self.requests ) do
		if v.id == id then
			has = true
			break
		end
	end
	return has;
end


function OrderInfoManager:Post(id, path, signalName, datas, handleErrorSelf, async)
    -- app.gameMgr:RemoveLoadingView()
	if not self:HasRequest( id ) then
        funLog(Logger.DEBUG, " id: = " .. id )
		local request = Request:New({id = id, path = path, signalName = signalName,data = datas, error = handleErrorSelf, async = async})
		table.insert( self.requests, request)
	end
end

return OrderInfoManager

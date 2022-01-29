--[[
游戏网络请求模块
--]]
local ManagerBase = require( "Frame.Manager.ManagerBase" )
---@class HttpManager
local HttpManager = class('HttpManager',ManagerBase)

local scheduler = require('cocos.framework.scheduler')

local zlib = require("zlib")

HttpManager.instances = {}


local ERRCACHET = 2
local ERR_CODE_ENUM = {
    SESSION_EXPIRE       = -1,   -- session 过期
    DIAMOND_NOT_ENOUGH   = -4,   -- 钻石不足
    GOLD_NOT_ENOUGH      = -5,   -- 金币不足
    HP_NOT_ENOUGH        = -6,   -- 体力不足
    REAL_NAME_AUTH       = -100, -- 实名认证
    REAL_NAME_AUTH_OTHER = -101, -- 实名认证
    RETRY_NETWORK        = 99,   -- 网络重试
    SERVER_STOP          = 100,  -- 服务器维护
    RESULT_FORMAT        = -987654321,
}

local Request = {}
local LIMIT_LOG = 60000

local FLOAT_MAX = 100000

local timezone = getClientTimezone() / 3600

function Request:New( ... )
	local arg = unpack({...})
	local this = {}
	setmetatable( this, {__index = Request})
	this.path = arg.path
    this.isGet = (arg.isGet or false)
    this.data = arg.data
    this.signalName = arg.signalName
    this.handleError = (arg.error or false)
    this.async  = (arg.async or false)
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

function HttpManager:ctor( key )
	self.super.ctor(self)
	if HttpManager.instances[key] ~= nil then
		return
	end
	self.requests = {} -- 所有的请求记录
    --每隔0.2秒发一次请求
    if self.updateHandler then
        scheduler.unscheduleGlobal(self.updateHandler)
    end
    self.isBusy = false
    self.updateHandler = scheduler.scheduleGlobal(handler(self, self.StartRequest),0.2)
	HttpManager.instances[key] = self
end

function HttpManager.GetInstance(key)
	key = (key or "HttpManager")
	if HttpManager.instances[key] == nil then
		HttpManager.instances[key] = HttpManager.new(key)
	end
	return HttpManager.instances[key]
end

function HttpManager.Destroy( key )
	key = (key or "HttpManager")
	if HttpManager.instances[key] == nil then
		return
	end
    --清除配表数据
    local mySelf = HttpManager.instances[key]
    if mySelf.updateHandler then
        scheduler.unscheduleGlobal(mySelf.updateHandler)
        mySelf.updateHandler = nil
    end
	HttpManager.instances[key] = nil
end

--[[
=============网络请求相关的方法
--]]

function HttpManager:StartRequest( dt )
    if next(self.requests) ~= nil and (not self.isBusy) then
        self.isBusy = true
        if NETWORK_LOCAL then
            local request = self.requests[1]
            self:BeforeRequest(request.async)
            --开始读接口数据
            local method = "POST"
            if request.isGet then
                method = "GET"
            end
            local filePath = cc.FileUtils:getInstance():fullPathForFilename("interfaces/" .. request.path .. ".json")
            local content = io.readfile(filePath)
            if content then
                local stateValue = 'success'
                local result = nil
                local jdata = json.decode(content)
                if jdata == nil then
                    stateValue = 'parse'
                else
                    result = jdata
                    local errorcode = tonumber(jdata.errcode,10)
                end
                self:AfterRequest({state = stateValue,result = result,url = request.path,data = request.data,method = method,signalName = request.signalName, handleError = request.handleError, isLimitStr = isLimitStr, async = request.async})
            else
                funLog(Logger.DEBUG, "Error not have json file" )
            end
            return
        else
            local gameManager = self:GetGameManager()
            local request = self.requests[1]
            local url = table.concat({'http://',Platform.ip,'/',request.path},'')
            if HTTP_USE_SSL then
                url = table.concat({'https://',Platform.ip,'/',request.path},'')
            end
            local xhr = cc.XMLHttpRequest:new()
            xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
            -- xhr:setRequestHeader("Host",tostring(Platform.serverHost))
            xhr.timeout = 30
            local method = "POST"
            if request.isGet then
                method = "GET"
            end
            xhr:open(method, url)
            if DEBUG > 0 then
                local logData = request.data or {}
                if logData.fightData ~= nil then
                    local tempLogData               = clone(logData)
                    tempLogData.fightData           = 'It\'s too long ......'
                    tempLogData.skadaResult         = 'It\'s too long ......'
                    tempLogData.constructorJson     = 'It\'s too long ......'
                    tempLogData.playerOperateJson   = 'It\'s too long ......'
                    tempLogData.loadedResourcesJson = 'It\'s too long ......'
                    logData = tempLogData
                end
                logInfo.add(logInfo.Types.HTTP, string.fmt('---> request %1 %2\n%3', method, url, tableToString(logData)))
            end

            local function netBack()
                local stateValue = 'success'
                local stateValue = 'parse'
                local result = nil
                if xhr.readyState == 4 and (xhr.status >= 200 and xhr.status < 207) then
                    local responseStr = xhr.response
                    local isLimitStr = false
                    if DEBUG > 0 then
                        local logResponseStr = responseStr
                        if request.path == 'player/checkin' or request.path == 'Activity/home' or request.path == 'Activity/home/appMediator' then
                            logResponseStr = 'It\'s too long ......'
                        end
                        isLimitStr = string.len(logResponseStr) > LIMIT_LOG
                        if isLimitStr then
                            -- FIXME 数据量过大，调试输出窗口导致崩溃
                            local subResponseStr = string.sub(logResponseStr, LIMIT_LOG)
                            funLog(Logger.DEBUG, string.format('[http:back] <<<< %s \n\t%s\n', url, subResponseStr))
                        else
                            funLog(Logger.DEBUG, string.format('[http:back] <<<< %s \n\t%s\n', url, logResponseStr))
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
                local callbackTime = os.time()
                local responseTime = callbackTime - checkint(self.requestStartTime_)
                if self.requestStartTime_ and responseTime > 10 then
                    logInfo.add(logInfo.Types.TIMEOUT, string.fmt('response seconds: %1 | %2', responseTime, request.path))
                end
                logInfo.add(logInfo.Types.HTTP, string.fmt('<--- netBack %1 %2\n%3', method, url, tableToString(result, nil, 10)))
                self:AfterRequest({state = stateValue, result = result, url = url, data = request.data, method = method, signalName = request.signalName, handleError = request.handleError, isLimitStr = isLimitStr, async = request.async})
            end
            if method == "POST" then
                local userInfo = gameManager.userInfo
                local sessionId= userInfo.sessionId or ''
                local playerId = checkint(userInfo.playerId)
                local version = utils.getAppVersion(true)
                local baseversion = utils.getAppVersion()
                local lang   = i18n.getLang()
                local userId = userInfo.userId
                local t = utils.getcommonParameters({channel = Platform.id, lang = lang, serverId = checkint(userInfo.serverId),sessionId = sessionId,playerId=playerId,version=version,baseversion=baseversion,userId=userId})
                if touch_info then
                    t.touch_x = math.floor(tonumber(touch_info.touch_x or 0) * FLOAT_MAX)
                    t.touch_y = math.floor(tonumber(touch_info.touch_y or 0) * FLOAT_MAX)
                    t.touch_t = math.floor(tonumber(touch_info.touch_t or 0) * FLOAT_MAX)
                end
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
                if isElexSdk() or isJapanSdk() then
                    local appFlyerId = cc.UserDefault:getInstance():getStringForKey("APPFLYER_DEVICEID", "")
                    t['appsFlyerId'] = appFlyerId
                    if device.platform == 'android' then
                        local androidId = cc.UserDefault:getInstance():getStringForKey("ANDROID_IDFA", "")
                        t['idfa'] = androidId
                    end
                    t['timeZone'] = tostring(timezone)
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
                xhr:setRequestHeader("User-Agent", string.format('U:%s,P:%s',tostring(userInfo.userId),tostring(playerId)))
                xhr:setRequestHeader('Content-Type', 'application/json')
                self:BeforeRequest(request.async)
                xhr:registerScriptHandler(netBack)
                -- xhr:send(ret)
                self.requestStartTime_ = os.time()
                xhr:send(compressed)
                if DEBUG and DEBUG > 0 then
                    funLog(Logger.DEBUG, string.format('[http:post] >>>> %s \n\t%s\n', url, json.encode(t)))
                end
            else
                self:BeforeRequest(request.async)
                xhr:registerScriptHandler(netBack)
                self.requestStartTime_ = os.time()
                xhr:send()
            end
        end
    end
end

function HttpManager:BeforeRequest( async )
	--请求之前所做的操作，是否显示加载的loading
    if not async then
        local gameManager = self:GetGameManager( )
        gameManager:ShowLoadingView()
    end
end

function HttpManager:AfterRequest( params )
    local url = params.url
    local URL = require('cocos.cocos2d.URL')
    local t = URL.parse(url)
    local path = t.path
    path = string.sub(path, 2)
    local signalName = params.signalName
    if NETWORK_LOCAL then
        path = params.url
    end
    self:RemoveRequest(path) --删除指定的请求
    self.isBusy = false
    if not params.async then
        local gameManager = self:GetGameManager(  )
        if params.state == 'timeout' then
            gameManager:ShowRetryNetworkView(path, params, "timeout")
        elseif params.state == 'parse' then
            gameManager:ShowRetryNetworkView(path, params, "parse")
        elseif params.state == 'success' then
            xTry(function (  )
                gameManager:RemoveLoadingView()
                if DEBUG > 0 then
                    if params.isLimitStr then
                        -- FIXME 数据量过大，调试输出窗口导致崩溃
                        -- funLog(Logger.DEBUG, tableToString(params.result.data, path .. ' get_success', 1))
                    else
                        -- funLog(Logger.DEBUG, tableToString(params.result.data, path .. ' get_success', 10))
                    end
                end
                --将数据分发出去
                if params.data then --将请求的参数数据再带回来
                    if type(params.result.data) == 'table' then
                        params.result.data.requestData = {}
                        params.result.data.requestData = params.data
                    else
                        params.result.data = {}
                        if checkint(params.result.errcode) == 0 then
                            params.result.errcode = ERR_CODE_ENUM.RESULT_FORMAT
                        end
                    end
                end
                local errorcode = checkint(params.result.errcode)
                if errorcode ~= 0 then
                    ---引导过程中需要发送一个处理事件
                    AppFacade.GetInstance():DispatchObservers('EVENT_HTTP_ERROR')
                end
                if errorcode == ERR_CODE_ENUM.DIAMOND_NOT_ENOUGH then
                    if GAME_MODULE_OPEN.NEW_STORE then
                        app.uiMgr:showDiamonTips()
                    else
                        local CommonTip  = require( 'common.NewCommonTip' ).new({text = __('幻晶石不足是否去商城购买？'),
                            isOnlyOK = false, callback = function ()
                                app.router:Dispatch({name = "HomeMediator"}, {name = "ShopMediator"})
                            end})
                        CommonTip:setPosition(display.center)
                        app.uiMgr:GetCurrentScene():AddDialog(CommonTip)
                    end
                elseif errorcode == ERR_CODE_ENUM.GOLD_NOT_ENOUGH then
                    app.uiMgr:ShowInformationTips(__('金币不足'))
                elseif errorcode == ERR_CODE_ENUM.HP_NOT_ENOUGH then
                    --体力不足的异常的响应逻辑
                    app.uiMgr:ShowInformationTips(__('体力不足'))
                elseif errorcode == ERR_CODE_ENUM.REAL_NAME_AUTH then
                    app.uiMgr:showRealNameAuthView(tostring(params.result.errmsg))
                elseif errorcode == ERR_CODE_ENUM.REAL_NAME_AUTH_OTHER then
                    app.uiMgr:showRealNameAuthView(tostring(params.result.errmsg) , true)
                elseif errorcode == ERR_CODE_ENUM.SESSION_EXPIRE then
                    --- session过期需要退出游戏
                    gameManager:ShowExitGameView()
                elseif errorcode == ERR_CODE_ENUM.RETRY_NETWORK then
                    gameManager:ShowRetryNetworkView(path, params, "parse")
                elseif errorcode == ERR_CODE_ENUM.SERVER_STOP then
                    --正在停机维护的接口逻辑
                    gameManager:ShowExitGameView(__('当前服务器正在维护，请耐心等待服务器维护完成!'), true)
                elseif errorcode == ERRCACHET and signalName == SIGNALNAMES.Checkin_Callback and isElexSdk() then
                   app.uiMgr:AddCommonTipDialog({
                       descr = __('亲爱的御侍大人，您的账号存在异常，是否需要联系客服？') ,
                       isOnlyOK = true ,
                       callback =  function()
                            if device.platform == 'android' and FTUtils:getTargetAPIVersion() >= 16 then
                                local AppSDK = require('root.AppSDK')
                                AppSDK:AIHelper({isShowFAQs = true})
                            else
                                local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
                                local userInfo = gameMgr:GetUserInfo()
                                ECServiceCocos2dx:setUserId(userInfo.playerId)
                                ECServiceCocos2dx:setUserName(userInfo.playerName)
                                ECServiceCocos2dx:setServerId(userInfo.serverId)
                                local lang = i18n.getLang()
                                local tcountry = string.split(lang, '-')[1]
                                if not tcountry then tcountry = 'en' end
                                if tcountry == 'zh' then tcountry = 'zh_TW' end
                                local config = {
                                        showContactButtonFlag = "1" ,
                                        showConversationFlag = "1" ,
                                        directConversation = "1"
                                    }
                                ECServiceCocos2dx:setSDKLanguage(tcountry)
                                ECServiceCocos2dx:showFAQs(config)
                            end
                       end
                   })
                elseif errorcode == 0 then
                    --succc有逻辑
                    if checktable(params.result.data).gold and params.result.timestamp then
                        profileTimestamp = checkint(params.result.timestamp)
                    elseif checktable(params.result.data).hp and params.result.timestamp then
                        profileTimestamp = checkint(params.result.timestamp)
                    end
                    AppFacade.GetInstance():DispatchObservers(signalName,params.result.data)
                elseif errorcode == MODULE_CLOSE_ERROR.TAG_MATCH then
                    AppFacade.GetInstance():DispatchObservers(signalName,params.result)
                elseif errorcode == ERR_CODE_ENUM.RESULT_FORMAT then
                    app.uiMgr:AddNewCommonTipDialog({text = __('返回数据格式不正确'), extra = checkstr(params.result.errmsg), isOnlyOK = true})
                else
                    --其他错误异常逻辑
                    gameManager:RemoveLoadingView()
                    app.uiMgr:ShowInformationTips(string.format("%s >_< ",tostring(params.result.errmsg))) --展示异常信息
                    --可能有些地方需要自己处理错误信息的逻辑
                    if params.handleError then
                        funLog(Logger.INFO, params.result)
                        AppFacade.GetInstance():DispatchObservers(signalName,params.result)
                    end
                end
            end,__G__TRACKBACK__)
        end
    else
        if params.state == 'success' then
            xTry(function (  )
                --将数据分发出去
                if params.data then --将请求的参数数据再带回来
                    params.result.data.requestData = {}
                    params.result.data.requestData = params.data
                end
                local errorcode = checkint(params.result.errcode)
                if errorcode == 0 then
                    --succc有逻辑
                    AppFacade.GetInstance():DispatchObservers(signalName,params.result.data)
                end
            end,__G__TRACKBACK__)
        end
    end
end

function HttpManager:RemoveRequest( path)
    local pos = 0
    -- funLog(Logger.DEBUG, "RemoveRequest: " .. path )
    for i, v in ipairs( self.requests ) do
        if v.path == path then
            pos = i
            break
        end
    end
    if pos > 0 then
        table.remove( self.requests, pos )
    end
end

function HttpManager:HasRequest( path )
	local has = false
	for i, v in ipairs( self.requests ) do
		if v.path == path then
			has = true
			break
		end
	end
	return has;
end

function HttpManager:Get( path, signalName)
	if not self:HasRequest(path) then
		local request = Request:New({path = path, signalName = signalName})
		table.insert( self.requests, request)
	end
end

function HttpManager:Post( path, signalName, datas, handleErrorSelf, async)
	if not self:HasRequest(path) then
        -- funLog(Logger.DEBUG, " AddPost: = " .. path )
		local request = Request:New({path = path, signalName = signalName,data = datas, error = handleErrorSelf, async = async})
		table.insert( self.requests, request)
	end
end
--[[
上传文件
@param path 接口路径
@param filepath 文件的路径
@param extraData 其他的一些参数
@param signalName 信号名称
--]]
function HttpManager:UploadFile( path, filepath, extraData, signalName)
	local url = table.concat({'http://',Platform.ip,'/',path},'')

    local sessionId= user.sessionId or ''
    local playerId = 0
    if package.loaded['mgr.playerMgr'] then -- 如果此模块未加载中
        playerId = playerMgr.player.playerId or 0
    end
    local version = utils.getAppVersion(true)
    local t = utils.getcommonParameters({channel = Platform.id, serverId = checkint(user.serverId),sessionId = sessionId,playerId=playerId,version=version})
    if t == nil then
        device.showAlert(__('警告'), __('解析参数出错'), __('确定'))
        return
    end
    if data then
        if device.platform == 'android' then
            t['os'] = 2
        elseif device.platform == 'ios' then
            t['os'] = 1
        end
        t['timestamp'] = os.time()
    end
    local sign = generateSign(t)
    t['sign'] = sign
    local gameManager = self:GetGameManager(  )
    gameManager:ShowLoadingView()

    local function postCallback(event)
        if event.name == "completed" then
            local responseStr = event.response
            if DEBUG then
                cclog(tostring(responseStr))
            end
            local jdata = json.decode(responseStr)
            if jdata == nil then
                showAutoDissmissDialog(sad_face, __('上传失败，请稍后重试'))
                return
            end
            local errorcode = tonumber(jdata.errcode,10)
            if errorcode ~= 0 then
                if errorcode == -1 then
                    --- session过期需要退出游戏
                else
                end
                return
            else
                -- 请求成功，显示服务端返回的内容
                if callback then callback(jdata.data)end
            end
        else
            showAutoDissmissDialog(sad_face, __('上传失败，请稍后重试'))
        end
    end
    network.uploadFile(postCallback,url,{
        fileFieldName="avatar",
        filePath=fullpath,
        contentType="image/jpeg",
        extra = t
    })
end

return HttpManager

local AppSDK = class('cc.AppSDK')

local Paytools = require('root.PayTools')

local DEFAULT_PROVIDER_OBJECT_NAME = "share.AppSDK"


local LOGIN = 'login'
local SWITCH = 'switch'
local PAY = 'pay'
local IDENTIFY = 'identify'
local REGISTER = 'register'

local platformId = checkint(Platform.id)

SHARE_TYPE = {
    FACEBOOK = 'facebook',
    LINE     = 'line',
    WHATSAPP = 'whatsApp',
    TWITTER  = 'twitter'
}

CONTENT_TYPE = {
    C2DXContentTypeText = 1, --文本
    C2DXContentTypeImage = 2, --图片
}


AppSDK.instances = {}
local SDK_CLASS_NAME = "SummerPaySDK"
if device.platform == 'android' then
    SDK_CLASS_NAME = 'com.duobaogame.summer.SummerPaySDK'
end

if isElexSdk() or isJapanSdk() then
    if device.platform == 'ios' then
        AppSDK.appstore = require('cocos.framework.store')
    end
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

function AppSDK:ctor()
    self:addListener()
    self.orderNo = nil
    self.price = 0
    self.isInvoked = false
    self.overrideUserInfo = true
    self.isIphonePay = false
    self.loadedProducts = {} --加载后的所有产品信息列表的记录 便于外部使用
    self.isRestoreInvoked = false
end

function AppSDK.GetInstance(key)
    key = (key or "AppSDK")
    if AppSDK.instances[key] == nil then
        AppSDK.instances[key] = AppSDK.new(key)
    end
    return AppSDK.instances[key]
end

function AppSDK:addListener()
    if device.platform == 'ios' then
        luaoc.callStaticMethod(SDK_CLASS_NAME, "addScriptListener", {listener = handler(self, self.callback_)})
        if AppSDK.appstore then
            --iap支付的逻辑的初始化
            AppSDK.appstore.init(handler(self,self.AppstorePayEvent))
        end
    elseif device.platform == 'android' then
        luaj.callStaticMethod(SDK_CLASS_NAME, "addScriptListener", {handler(self, self.callback_)})
    end
end


function AppSDK:RestorePay()
    if not self.isInvoked then
        self.isInvoked = true
        if isElexSdk() or isJapanSdk() then
            local products = Paytools.RetriveRecipts()
            if products and next( products ) ~= nil then
                --存在数据要进行恢复的逻辑
                local productsBak = clone(products)
                for name,pp in pairs(productsBak) do
                    if device.platform == 'ios' then
                        local params = {receipt = pp.receipt,transactionId = pp.transactionIdentifier}
                        self:RequestPay("pay/apple", params, function(datas)
                            Paytools.RemoveRecipt(pp.transactionIdentifier)
                            AppSDK.appstore.finishTransaction(pp)
                            if datas.orderId then
                                local orderInfoMgr = AppFacade.GetInstance():GetManager('OrderInfoManager')
                                local id = string.format('pay/orderInfo/%s', datas.orderId)
                                orderInfoMgr:Post(id, 'pay/orderInfo',EVENT_PAY_MONEY_SUCCESS,{orderNo = datas.orderId})
                            end
                        end)
                    elseif device.platform == 'android' then
                        if platformId == ElexAmazon then
                            local productId = pp.productId
                            local receiptId = crypto.decodeBase64(pp.receipt)
                            self:RequestPay("pay/amazon",{purchaseToken = receiptId,accountId = pp.accountId,
                                productId = productId, marketPlace = pp.marketPlace},function(datas)
                                    Paytools.RemoveRecipt(productId)
                                    luaj.callStaticMethod(SDK_CLASS_NAME,'finishTransaction',{productId,receiptId},'(Ljava/lang/String;Ljava/lang/String;)V')
                                    if datas.orderId then
                                        local orderInfoMgr = AppFacade.GetInstance():GetManager('OrderInfoManager')
                                        local id = string.format('pay/orderInfo/%s', datas.orderId)
                                        orderInfoMgr:Post(id, 'pay/orderInfo',EVENT_PAY_MONEY_SUCCESS,{orderNo = datas.orderId})
                                    end
                                end)
                        else
                            local productId = pp.productId
                            self:RequestPay("pay/google",{receipt = pp.receipt,signature = pp.signature, productId = productId, orderId = pp.orderId},function(datas)
                                Paytools.RemoveRecipt(productId)
                                luaj.callStaticMethod(SDK_CLASS_NAME,'finishTransaction',{productId},'(Ljava/lang/String;)V')
                                if datas.orderId then
                                    local orderInfoMgr = AppFacade.GetInstance():GetManager('OrderInfoManager')
                                    local id = string.format('pay/orderInfo/%s', datas.orderId)
                                    orderInfoMgr:Post(id, 'pay/orderInfo',EVENT_PAY_MONEY_SUCCESS,{orderNo = datas.orderId})
                                end
                            end)
                        end
                    end
                end
            end
        end
        --[[
        if isElexSdk() then
            -- restore logical
            if platformId == 4003 or platformId == 4005 then
                --android amazon
                luaj.callStaticMethod(SDK_CLASS_NAME,'restore')
            elseif platformId== 4004 and AppSDK.appstore then
                --ios
                AppSDK.appstore.restore()
            end
        elseif isJapanSdk() then
            if device.platform == 'android' then
                luaj.callStaticMethod(SDK_CLASS_NAME,'restore')
            elseif device.platform == 'ios' then
                AppSDK.appstore.restore()
            end
        end
        --]]
    end
end


---[[--
--  分享回调函数
---]]
function AppSDK:callback_(event)
    if DEBUG > 0 then
        logInfo.add(logInfo.Types.HTTP, string.fmt('--> eventBack %1\n%2', 'androidCallback', tableToString(event, nil, 10)))
    end
    if type(event) == 'string' then
        event = json.decode(event)
        local tType = event.type
        if tType == "google_pay" then
            self:GoogleCallBack(event)
        end
        if isEfunSdk() then
            local tType = event.type
            if tType == 'login' then
                if event.state == 'fail' then
                    local uiMgr = AppFacade.GetInstance():GetManager('UIManager')
                    uiMgr:ShowInformationTips(tostring(event.message))
                elseif event.state == 'success' then
                    local gameMgr = AppFacade.GetInstance():GetManager('GameManager')
                    local userInfo = gameMgr:GetUserInfo()
                    userInfo.fbId = event.fbId
                    userInfo.accessToken = event.userId
                    userInfo.userSdkId = event.userId
                    AppFacade.GetInstance():DispatchObservers(EVENT_SDK_LOGIN, {sign = event.sign,loginTimestamp = event.timestamp, fbId = event.fbId})
                end
            elseif tType == 'logout' then
                if event.state == 'success' then
                    --退到游戏主界面
                    local gameMgr = AppFacade.GetInstance():GetManager('GameManager')
                    local userInfo = gameMgr:GetUserInfo()
                    userInfo.accessToken = nil
                    userInfo.userSdkId = nil
                    app.audioMgr:stopAndClean()
                    app.uiMgr:PopAllScene()
                    sceneWorld:getEventDispatcher():dispatchEvent(cc.EventCustom:new('APP_EXIT'))
                end
            elseif tType == 'share' then
                if event.state == 'success' then
                    local httpMgr = AppFacade.GetInstance():GetManager('HttpManager')
                    httpMgr:Post('Player/share', "SHARE_REQUEST_RESPONSE",{})
                else
                    if cc.UserDefault:getInstance():getBoolForKey(CV_SHARE_ACTIVITY_KEY, false) then
                        AppFacade.GetInstance():DispatchObservers('ACTIVITY_CVSHARE_SHARED')
                    end
                    sceneWorld:runAction(cc.Sequence:create(
                            cc.DelayTime:create(0.2),
                            cc.CallFunc:create(function()
                                local uiMgr = AppFacade.GetInstance():GetManager('UIManager')
                                uiMgr:ShowInformationTips(__('分享失败,请稍后重试~~'))
                            end)
                        ))
                end
            elseif tType == 'pay' then
                if event.state == 'success' then
                    local status = event.state
                    if self.orderNo then
                        local orderInfoMgr = AppFacade.GetInstance():GetManager('OrderInfoManager')
                        local id = string.format('pay/orderInfo/%s', self.orderNo)
                        orderInfoMgr:Post(id, 'pay/orderInfo',EVENT_PAY_MONEY_SUCCESS,{orderNo = self.orderNo})
                    end
                    AppFacade.GetInstance():DispatchObservers(EVENT_SDK_PAY, {status = event.state})
                    self:TrackEvent({event = 'finish_purchase',revenue = tostring((self.price or 0))})
                elseif event.state == 'failed' then
                    sceneWorld:runAction(cc.Sequence:create(
                            cc.DelayTime:create(0.2),
                            cc.CallFunc:create(function()
                                local uiMgr = AppFacade.GetInstance():GetManager('UIManager')
                                uiMgr:ShowInformationTips(__('当前充值失败~~'))
                            end)
                        ))
                end
            elseif tType == 'bind' then
                --bind logical
                AppFacade.GetInstance():DispatchObservers("PHONE_BIND_STATE", event)
            elseif tType == 'facebook' then
                local cmd = tostring(event.cmd)
                if cmd == 'sync' then
                    if event.state == 'success' then
                        --同步成功记录一个标识
                        local gameMgr = AppFacade.GetInstance():GetManager('GameManager')
                        local userInfo = gameMgr:GetUserInfo()
                        cc.UserDefault:getInstance():setStringForKey(string.format('FACEBOOK_BINDING_%s',tostring(userInfo.playerId)), "success")
                        cc.UserDefault:getInstance():flush()
                        AppFacade.GetInstance():RetrieveMediator('Router'):Dispatch({name = 'HomeMediator'}, {name = 'FacebookInviteMediator'})
                    end
                elseif cmd == 'author' then
                    if event.state == 'success' then
                        local gameMgr = AppFacade.GetInstance():GetManager('GameManager')
                        local userInfo = gameMgr:GetUserInfo()
                        userInfo.fbId = event.fbId
                        userInfo.headUrl = event.headUrl
                        userInfo.nickname = event.nickname
                        --发送下一步同步好友列表的接口请求逻辑
                        AppFacade.GetInstance():DispatchObservers('FACEBOOK_EVENT',event)
                    end
                elseif cmd == 'invitable' then
                    AppFacade.GetInstance():DispatchObservers('FACEBOOK_EVENT',event)
                elseif cmd == 'invite' then
                    if event.state == 'success' then
                        --如果成功邀请回调
                        AppFacade.GetInstance():DispatchSignal(POST.FACEBOOK_INVITE_FRIENDS.cmdName, {faceBookIds = table.concat(checktable(event.ids), ',')})
                    end
                end
            end
            self:RemoveViewForNoTouch()

        elseif isElexSdk() then
            local tType = event.type
            if tType == 'login' then
                self:RemoveViewForNoTouch()
                if event.state == 'error' then
                    if event.code and checkint(event.code) == 2 then
                        --取消了gamecenter的登录
                    else
                        local uiMgr = AppFacade.GetInstance():GetManager('UIManager')
                        uiMgr:ShowInformationTips(tostring(event.message))
                    end
                elseif event.state == 'success' then
                    if self.overrideUserInfo then
                        local gameMgr = AppFacade.GetInstance():GetManager('GameManager')
                        local userInfo = gameMgr:GetUserInfo()
                        local platform = event.loginPlatform
                        userInfo.accessToken = event.userId
                        userInfo.userSdkId = event.userId
                        local loginPlatform = 1 --google platform
                        if platform ~= 'gamecenter' then
                            userInfo.accessToken = event.token
                        end
                        if platform == 'facebook' then
                            loginPlatform = 2
                        elseif platform == 'gamecenter' then
                            loginPlatform = 3
                        elseif platform == 'apple' then
                            loginPlatform = 4
                        end
                        AppFacade.GetInstance():DispatchObservers(EVENT_SDK_LOGIN, {loginPlatform = loginPlatform, name = platform})
                    else
                        local loginPlatform = 1 --google platform
                        local platform = event.loginPlatform
                        if platform == 'facebook' then
                            loginPlatform = 2
                        elseif platform == 'gamecenter' then
                            loginPlatform = 3
                        elseif platform == 'apple' then
                            loginPlatform = 4
                        end
                        AppFacade.GetInstance():DispatchObservers(EVENT_SDK_LOGIN, {loginPlatform = loginPlatform, name = platform, userId = event.userId})
                    end
                end
            elseif tType == 'logout' then
                self:RemoveViewForNoTouch()
                if event.state == 'success' then
                    --退到游戏主界面
                    local gameMgr = AppFacade.GetInstance():GetManager('GameManager')
                    local userInfo = gameMgr:GetUserInfo()
                    userInfo.accessToken = nil
                    userInfo.userSdkId = nil
                    app.audioMgr:stopAndClean()
                    app.uiMgr:PopAllScene()
                    sceneWorld:getEventDispatcher():dispatchEvent(cc.EventCustom:new('APP_EXIT'))
                end
            elseif tType == 'share' then
                if event.state == 'success' then
                    if cc.UserDefault:getInstance():getBoolForKey(CV_SHARE_ACTIVITY_KEY, false) then
                        -- cv活动分享
                        AppFacade.GetInstance():DispatchObservers('ACTIVITY_CVSHARE_SHARED')
                    else
                        local httpMgr = AppFacade.GetInstance():GetManager('HttpManager')
                        httpMgr:Post('Player/share', "SHARE_REQUEST_RESPONSE",{})
                    end
                else
                    local text = __('分享失败,请稍后重试~~')
                    if event.message then
                        text = tostring(event.message)
                    end
                    sceneWorld:runAction(cc.Sequence:create(
                            cc.DelayTime:create(0.2),
                            cc.CallFunc:create(function()
                                local uiMgr = AppFacade.GetInstance():GetManager('UIManager')
                                uiMgr:ShowInformationTips(text)
                            end)
                        ))
                end
            elseif tType == 'products' then
                if isElexSdk() then
                    --加载所有的商品列表的逻辑
                    for name,val in pairs(event.products) do
                        if platformId == ElexAndroid then
                            val.priceLocale = val.displayPrice
                        elseif platformId == ElexAmazon then
                            val.priceLocale = val.price
                        end
                        self.loadedProducts[tostring(val.productId)] = val
                    end
                    AppFacade.GetInstance():DispatchObservers("APP_STORE_PRODUCTS")
                end
            elseif tType == 'pay' then
                if event.state == 'success' then
                    if platformId == ElexAmazon then
                        local productId = event.productId
                        local receiptId = event.receipt
                        local accountId = event.accountId
                        local marketPlace = event.marketPlace
                        Paytools.StoreRecipt(productId,{accountId = accountId, marketPlace = marketPlace, receipt = crypto.encodeBase64(receiptId)})
                        self:RequestPay("pay/amazon",{purchaseToken = receiptId,accountId = accountId,
                            productId = productId, marketPlace = marketPlace},function(datas)
                            Paytools.RemoveRecipt(productId)
                            luaj.callStaticMethod(SDK_CLASS_NAME,'finishTransaction',{productId,receiptId},'(Ljava/lang/String;Ljava/lang/String;)V')
                            if datas.orderId then
                                local orderInfoMgr = AppFacade.GetInstance():GetManager('OrderInfoManager')
                                local id = string.format('pay/orderInfo/%s', datas.orderId)
                                orderInfoMgr:Post(id, 'pay/orderInfo',EVENT_PAY_MONEY_SUCCESS,{orderNo = datas.orderId})
                            end
                        end)
                        AppFacade.GetInstance():DispatchObservers(EVENT_SDK_PAY, {status = event.state})
                    else
                        local productId = event.productId
                        local orderId = event.orderId
                        -- local purchaseToken = event.purchaseToken
                        local responseData = crypto.encodeBase64(event.responseData)
                        local signature = event.signature
                        Paytools.StoreRecipt(productId,{orderId = orderId, signature = signature, receipt = responseData})
                        self:RequestPay("pay/google",{receipt = responseData,signature = signature, productId = productId, orderId = orderId},function(datas)
                            Paytools.RemoveRecipt(productId)
                            luaj.callStaticMethod(SDK_CLASS_NAME,'finishTransaction',{productId},'(Ljava/lang/String;)V')
                            if datas.orderId then
                                local orderInfoMgr = AppFacade.GetInstance():GetManager('OrderInfoManager')
                                local id = string.format('pay/orderInfo/%s', datas.orderId)
                                orderInfoMgr:Post(id, 'pay/orderInfo',EVENT_PAY_MONEY_SUCCESS,{orderNo = datas.orderId})
                            end
                        end)
                        AppFacade.GetInstance():DispatchObservers(EVENT_SDK_PAY, {status = event.state})
                    end
                elseif event.state == 'error' then
                    sceneWorld:runAction(cc.Sequence:create(
                            cc.DelayTime:create(0.2),
                            cc.CallFunc:create(function()
                                local uiMgr = AppFacade.GetInstance():GetManager('UIManager')
                                uiMgr:ShowInformationTips(__('当前充值失败~~'))
                            end)
                        ))
                elseif event.state == 'restore' then
                    --恢复的操作
                    if table.nums(checktable(event.products)) > 0 then
                        --发送请求进行恢复
                        local index = 1
                        local products = event.products
                        local p = products[index]
                        if p then
                            local productId = p.productId
                            local orderId = p.orderId
                            -- local purchaseToken = event.purchaseToken
                            local responseData = crypto.encodeBase64(p.responseData)
                            local signature = p.signature
                            local function checkGooglePayOrder(datas)
                                index = index + 1
                                luaj.callStaticMethod(SDK_CLASS_NAME,'finishTransaction',{productId},'(Ljava/lang/String;)V')
                                if datas.orderId then
                                    local orderInfoMgr = AppFacade.GetInstance():GetManager('OrderInfoManager')
                                    local id = string.format('pay/orderInfo/%s', datas.orderId)
                                    orderInfoMgr:Post(id, 'pay/orderInfo',EVENT_PAY_MONEY_SUCCESS,{orderNo = datas.orderId})
                                else
                                    AppFacade.GetInstance():DispatchObservers(EVENT_PAY_MONEY_SUCCESS, datas)
                                end
                                if index <= #products then
                                    local p = products[index]
                                    productId = p.productId
                                    orderId = p.orderId
                                    -- local purchaseToken = event.purchaseToken
                                    responseData = crypto.encodeBase64(p.responseData)
                                    signature = p.signature
                                    self:RequestPay("pay/google",{receipt = responseData,signature = signature, productId = productId, orderId = orderId}, checkGooglePayOrder)
                                end
                            end
                            self:RequestPay("pay/google",{receipt = responseData,signature = signature, productId = productId, orderId = orderId}, checkGooglePayOrder)
                        end
                    end
                end
            end
        elseif isQuickSdk() then
            --如果是quick渠道的回调的相关处理的逻辑
            -- dump(event)
            local tType = event.type
            if tType == 'init' then
                --初始化成功的逻辑
                if event.state == 'success' then
                    self:QuickLogin() --调用登录的操作
                end
            elseif tType == 'login' then
                --登录
                if event.state == 'fail' then
                    local uiMgr = AppFacade.GetInstance():GetManager('UIManager')
                    uiMgr:ShowInformationTips(tostring(event.message))
                elseif event.state == 'success' then
                    local gameMgr = AppFacade.GetInstance():GetManager('GameManager')
                    local userInfo = gameMgr:GetUserInfo()
                    userInfo.uname = event.uname
                    userInfo.accessToken = event.token
                    userInfo.userSdkId = event.uId
                    AppFacade.GetInstance():DispatchObservers(EVENT_SDK_LOGIN)
                elseif event.state == 'cancel' then
                    AppFacade.GetInstance():DispatchObservers(EVENT_SDK_LOGIN_CANCEL)
                end
            elseif tType == 'logout' then
                if event.state == 'success' then
                    --退到游戏主界面
                    app.audioMgr:stopAndClean()
                    app.uiMgr:PopAllScene()
                    sceneWorld:getEventDispatcher():dispatchEvent(cc.EventCustom:new('APP_EXIT'))
                elseif event.state == 'fail' then
                    local uiMgr = AppFacade.GetInstance():GetManager('UIManager')
                    uiMgr:ShowInformationTips(tostring(event.message))
                end
            elseif tType == PAY then
                --支付
                if event.state == 'success' then
                    if self.orderNo then
                        local orderInfoMgr = AppFacade.GetInstance():GetManager('OrderInfoManager')
                        local id = string.format('pay/orderInfo/%s', self.orderNo)
                        orderInfoMgr:Post(id, 'pay/orderInfo',EVENT_PAY_MONEY_SUCCESS,{orderNo = self.orderNo})
                    end
                    AppFacade.GetInstance():DispatchObservers(EVENT_SDK_PAY, {orderId = event.orderId, sdkOrderId = event.sdkOrderId, extra = event.extraParams})
                elseif event.state == 'failed' then
                    sceneWorld:runAction(cc.Sequence:create(
                            cc.DelayTime:create(0.2),
                            cc.CallFunc:create(function()
                                if event.message and string.len(tostring(event.message)) > 0 then
                                    local uiMgr = AppFacade.GetInstance():GetManager('UIManager')
                                    uiMgr:ShowInformationTips(tostring(event.message))
                                end
                            end)
                        ))

                end
            elseif tType == 'switch' then
                --切换
                if event.state == 'success' then
                    --切换成功会有一个新的账号的信息id
                    local gameMgr = AppFacade.GetInstance():GetManager('GameManager')
                    local userInfo = gameMgr:GetUserInfo()
                    userInfo.uname = event.uname
                    userInfo.accessToken = event.token
                    userInfo.userSdkId = event.uId
                    --退到游戏主界面
                    app.audioMgr:stopAndClean()
                    app.uiMgr:PopAllScene()
                    sceneWorld:getEventDispatcher():dispatchEvent(cc.EventCustom:new('APP_EXIT'))

                elseif event.state == 'failed' then
                    --切换失败
                    local uiMgr = AppFacade.GetInstance():GetManager('UIManager')
                    uiMgr:ShowInformationTips(tostring(event.message))
                end
            elseif tType == 'exit' then
                if event.state == 'success' then
                    cc.Director:getInstance():endToLua()
                    os.exit()
                elseif event.state == 'fail' then
                    local uiMgr = AppFacade.GetInstance():GetManager('UIManager')
                    uiMgr:ShowInformationTips(__('请求退出游戏出现异常，请稍后重试'))
                end
            end
        elseif platformId == BestvAndroid then
            --百氏通平台的回调处理
            if event.type == 'login' then
                --login success
                if event.state == 'success' then
                    local gameMgr = AppFacade.GetInstance():GetManager('GameManager')
                    local userInfo = gameMgr:GetUserInfo()
                    userInfo.uname = event.userId
                    userInfo.accessToken = event.userId
                    userInfo.userSdkId = event.userId
                    AppFacade.GetInstance():DispatchObservers(EVENT_SDK_LOGIN)
                end
            elseif event.type == 'pay' then
                local code = checkint(event.code)
                if code == 900 then
                    --支付成功
                    local status = event.state
                    if self.orderNo then
                        local orderInfoMgr = AppFacade.GetInstance():GetManager('OrderInfoManager')
                        local id = string.format('pay/orderInfo/%s', self.orderNo)
                        orderInfoMgr:Post(id, 'pay/orderInfo',EVENT_PAY_MONEY_SUCCESS,{orderNo = self.orderNo})
                    end
                    AppFacade.GetInstance():DispatchObservers(EVENT_SDK_PAY, {status = event.state})
                elseif code == 800 then
                    --支付确认中
                    sceneWorld:runAction(cc.Sequence:create(
                            cc.DelayTime:create(0.2),
                            cc.CallFunc:create(function()
                                local uiMgr = AppFacade.GetInstance():GetManager('UIManager')
                                uiMgr:ShowInformationTips(__('当前支付确认中..'))
                            end)
                        ))

                elseif code == 600 then
                    --取消
                elseif code == 700 then
                    --失败
                    sceneWorld:runAction(cc.Sequence:create(
                            cc.DelayTime:create(0.2),
                            cc.CallFunc:create(function()
                                local uiMgr = AppFacade.GetInstance():GetManager('UIManager')
                                uiMgr:ShowInformationTips(__('当前支付失败中，请稍后重试'))
                            end)
                        ))
                end
            end
        else
            if event.type then
                if platformId == KuaiKan then
                    if event.type == LOGIN then
                        --登录
                        if event.status == 'failure' then
                            local uiMgr = AppFacade.GetInstance():GetManager('UIManager')
                            uiMgr:ShowInformationTips(tostring(event.msg))
                        elseif event.status == 'success' then
                            local gameMgr = AppFacade.GetInstance():GetManager('GameManager')
                            local userInfo = gameMgr:GetUserInfo()
                            userInfo.uname = event.nickname
                            userInfo.avatar = event.avatarUrl
                            userInfo.accessToken = event.accessToken
                            userInfo.userSdkId = event.openId
                            AppFacade.GetInstance():DispatchObservers(EVENT_SDK_LOGIN)
                        elseif event.status == 'cancel' then
                        end
                    elseif event.type == SWITCH then
                        --切换
                        --退到游戏主界面
                        app.audioMgr:stopAndClean()
                        app.uiMgr:PopAllScene()
                        sceneWorld:getEventDispatcher():dispatchEvent(cc.EventCustom:new('APP_EXIT'))
                    elseif event.type == PAY then
                        --支付
                    end
                elseif isFuntoySdk() then
                    --本平台的android要调用的
                    if event.type == LOGIN then
                        local status = event.state
                        if status == 'success' then
                            local gameMgr = AppFacade.GetInstance():GetManager('GameManager')
                            local userInfo = gameMgr:GetUserInfo()
                            userInfo.userSdkId = event.openId
                            AppFacade.GetInstance():DispatchObservers(EVENT_SDK_LOGIN, {sign = event.sign,loginTimestamp = event.timestamp})
                        end
                    elseif event.type == REGISTER then
                        sceneWorld:runAction(
                            cc.Sequence:create(
                                cc.DelayTime:create(0.2) ,
                                cc.CallFunc:create(function()
                                    DotGameEvent.SendEvent(DotGameEvent.EVENTS.REGISTER)
                                end)
                            )
                        )
                    elseif event.type == IDENTIFY then
                        --喜扑的实名认证
                        local status = checkint(event.state)
                        if status == 1 then
                            --未成年成年
                        elseif status == 2 then
                            --已成年
                        end
                        sceneWorld:runAction(
                            cc.Sequence:create(
                                cc.DelayTime:create(0.2) ,
                                cc.CallFunc:create(function()
                                    DotGameEvent.SendEvent(DotGameEvent.EVENTS.IDENTIFY)
                                end)
                            )
                        )
                    elseif event.type == "track_event" then
                        if DotGameEvent.SDKButtonEvent then
                            DotGameEvent.SDKButtonEvent(event)
                        end
                    elseif event.type == PAY then
                        local status = event.state
                        if status == 'success' then
                            if self.orderNo then
                                local orderInfoMgr = AppFacade.GetInstance():GetManager('OrderInfoManager')
                                local id = string.format('pay/orderInfo/%s', self.orderNo)
                                orderInfoMgr:Post(id, 'pay/orderInfo',EVENT_PAY_MONEY_SUCCESS,{orderNo = self.orderNo})
                            end
                            self:TrackSDKEvent("purchaseEventWithContentType", {
                                ContentType = "",
                                contentName = "",
                                contentID = "",
                                contentNumber = tostring(self.orderNo) ,
                                paymentChannel ="App Store",
                                currency = "￥",
                                currency_amount = self.price,
                                isSuccess = 1
                            })
                        end
                        AppFacade.GetInstance():DispatchObservers(EVENT_SDK_PAY, {status = event.state})
                    elseif event.type == SWITCH then
                        --切换
                        --退到游戏主界面
                        app.audioMgr:stopAndClean()
                        app.uiMgr:PopAllScene()
                        sceneWorld:getEventDispatcher():dispatchEvent(cc.EventCustom:new('APP_EXIT'))
                    end
                elseif platformId == YSSDKChannel then
                    if event.type == LOGIN then
                        local status = event.state
                        if status == 'success' then
                            local gameMgr = AppFacade.GetInstance():GetManager('GameManager')
                            local userInfo = gameMgr:GetUserInfo()
                            userInfo.userSdkId = event.openId
                            AppFacade.GetInstance():DispatchObservers(EVENT_SDK_LOGIN)
                        end
                    elseif event.type == PAY then
                        local status = event.state
                        if status == 'success' then
                            if self.orderNo then
                                local orderInfoMgr = AppFacade.GetInstance():GetManager('OrderInfoManager')
                                local id = string.format('pay/orderInfo/%s', self.orderNo)
                                orderInfoMgr:Post(id, 'pay/orderInfo',EVENT_PAY_MONEY_SUCCESS,{orderNo = self.orderNo})
                            end
                        end
                        AppFacade.GetInstance():DispatchObservers(EVENT_SDK_PAY, {status = event.state})
                    elseif event.type == SWITCH then
                        --切换
                        --退到游戏主界面
                        app.audioMgr:stopAndClean()
                        app.uiMgr:PopAllScene()
                        sceneWorld:getEventDispatcher():dispatchEvent(cc.EventCustom:new('APP_EXIT'))
                    end
                end
            end
        end
    end
end

--[[
--快看渠道的支付的逻辑
--]]
function AppSDK:KuaiKanPay(t)
    if device.platform == 'android' then
        luaj.callStaticMethod(SDK_CLASS_NAME,'KanKanPay',{})
    end
end

function AppSDK:TrackEvent(t)
    if device.platform == 'ios' then
        local gameMgr = AppFacade.GetInstance():GetManager('GameManager')
        local userInfo = gameMgr:GetUserInfo()
        local serverId = tostring(userInfo.serverId)
        local serverName = tostring((userInfo.serverName or '食之契约'))
        local roleId = tostring(userInfo.playerId)
        local roleName = tostring(userInfo.playerName)
        local roleLevel = tostring(userInfo.level)
        local parameters = {event = t.event,eventChannel = '8', userId = userId, productId = goodsId, serverId = serverId, serverName = serverName,
            roleId = roleId, roleName = roleName, roleLevel = roleLevel}
        if t.revenue then
            parameters.revenue = t.revenue
        end
        luaoc.callStaticMethod(SDK_CLASS_NAME,'trackEvent',parameters)
    end
end

--[[
--appflyer事件统计的接口的逻辑
--]]
function AppSDK:AppFlyerEventTrack(event_name, params)
    if isElexSdk() then
        local t = {}
        for name,val in pairs(params) do
            table.insert(t, {id = name, value = val})
        end
        if device.platform == 'ios' then
            local text = json.encode(t)
            if text then
                luaoc.callStaticMethod('AppFlyerHelper','trackEvent',{event = event_name,values = text})
            end
        elseif device.platform == 'android' then
            --android平台
            local text = json.encode(t)
            if text then
                luaj.callStaticMethod('com.duobaogame.summer.AppFlyerHelper','trackEvent',{event_name,text})
            end
        end
    end
end

--[[
-- load products
--]]
function AppSDK:QueryProducts(t)
    if isElexSdk() and table.nums(t) > 0 and FTUtils:getTargetAPIVersion() >=12 then
        -- AppFacade.GetInstance():GetManager("GameManager"):ShowLoadingView()
        if device.platform == 'ios' then
            AppSDK.appstore.loadProducts(t, handler(self,self.AppstorePayEvent))
        elseif device.platform == 'android' then
            luaj.callStaticMethod(SDK_CLASS_NAME,'queryProducts',{json.encode(t)},'(Ljava/lang/String;)V')
        end
    end
end

--[[
--支付逻辑的相关参数
--同时需要注册处理事件 EVENT_SDK_PAY 信号进行处理
--@param t ----{amount = 30,}
--]]
function AppSDK:InvokePay(t)
    --记录一个当前的定单号值
    local gameMgr = AppFacade.GetInstance():GetManager('GameManager')
    local orderNo = tostring(t.property)
    self.orderNo = orderNo
    self.price = t.amount
    if isFuntoySdk() then
        --android平台调用的支付逻辑
        local userInfo = gameMgr:GetUserInfo()
        local serverId = tostring(userInfo.serverId)
        local serverName = tostring((userInfo.serverName or '食之契约'))
        local roleId = tostring(userInfo.playerId)
        local roleName = tostring(userInfo.playerName)
        local roleLevel = tostring(userInfo.level)
        local amount = tonumber(t.amount) * 100
        if device.platform == 'android' then
            if FOR_REVIEW then
                serverId = "9999"
            end
            local parameters = json.encode({serverId = serverId, serverName = serverName,
            roleId = roleId, roleName = roleName, roleLevel = roleLevel, amount = tostring( amount),property = t.property})
            luaj.callStaticMethod(SDK_CLASS_NAME,'pay',{parameters})
        elseif device.platform == 'ios' then
            if FOR_REVIEW then
                serverId = "9999"
            end
            local goodsId = tostring(t.goodsId)
            local pacakgeName = FTUtils:getPackageName()
            if string.find(goodsId, pacakgeName) then
                -- local identifier, _ = string.gsub(goodsId, pacakgeName, '')
                if FOR_REVIEW then
                    serverId = 9999
                end
                luaoc.callStaticMethod(SDK_CLASS_NAME, 'pay', {serverId = serverId, serverName = serverName,
                roleId = roleId, roleName = roleName, roleLevel = roleLevel, amount = tostring( goodsId),property = t.property})
            else
                if FOR_REVIEW then
                    serverId = 9999
                end
                luaoc.callStaticMethod(SDK_CLASS_NAME, 'pay', {serverId = serverId, serverName = serverName,
                roleId = roleId, roleName = roleName, roleLevel = roleLevel, amount = tostring( amount),property = t.property})
            end
        end
    elseif isEfunSdk() then
        local gameMgr = AppFacade.GetInstance():GetManager('GameManager')
        local userInfo = gameMgr:GetUserInfo()
        local serverId = tostring(userInfo.serverId)
        local userId = tostring(userInfo.userSdkId)
        local serverName = tostring((userInfo.serverName or '食之契约'))
        local roleId = tostring(userInfo.playerId)
        local roleName = tostring(userInfo.playerName)
        local roleLevel = tostring(userInfo.level)
        local amount = tonumber(t.amount) * 100
        if device.platform == 'android' then
            local goodsId = tostring(t.goodsId)
            local parameters = json.encode({userId = userId, productId = goodsId, serverId = serverId, serverName = serverName,
                roleId = roleId, roleName = roleName, roleLevel = roleLevel, amount = tostring( amount),property = t.property, price = tostring(t.amount)})
            luaj.callStaticMethod(SDK_CLASS_NAME,'efunPay',{parameters})
        elseif device.platform == 'ios' then
            local goodsId = tostring(t.goodsId)
            luaoc.callStaticMethod(SDK_CLASS_NAME, 'pay', {userId = userId, productId = goodsId,serverId = serverId, serverName = serverName,
                roleId = roleId, roleName = roleName, roleLevel = roleLevel, amount = tostring( amount),property = t.property, price = tostring(t.amount)})
        end
    elseif isElexSdk() then
        --美区平台
        local goodsId = tostring(t.goodsId)
        if device.platform == 'android' then
            if platformId == ElexAmazon then
                luaj.callStaticMethod(SDK_CLASS_NAME,'purchage',{goodsId},'(Ljava/lang/String;)V')
            else
                if FTUtils:getTargetAPIVersion() > 14 then
                    local userInfo = app.gameMgr:GetUserInfo()
                    local payData = {
                        productId = goodsId ,
                        type = "consumer" ,
                        accountId = tostring(userInfo.playerId),
                        developerId =tostring(userInfo.userId)
                    }
                    luaj.callStaticMethod(SDK_CLASS_NAME,'purchageMulti',{json.encode(payData)},'(Ljava/lang/String;)V')
                else
                    luaj.callStaticMethod(SDK_CLASS_NAME,'purchage',{goodsId,"consumer"},'(Ljava/lang/String;Ljava/lang/String;)V')
                end
            end
        elseif device.platform == 'ios' then
            --先加载后购买的逻辑
            --声明平台可以直接进行购买了，因为在显示前要进行加载后才能调用购买的操作
            if self.loadedProducts[goodsId] then
                AppSDK.appstore.purchase(goodsId)
            else
                self.isIphonePay = true --没有加载商品之前调用支付
                AppSDK.appstore.loadProducts({goodsId}, handler(self,self.AppstorePayEvent))
            end
        end
    elseif isJapanSdk() then
        local goodsId = tostring(t.goodsId)
        if device.platform == 'android' then
            luaj.callStaticMethod(SDK_CLASS_NAME,'purchage',{goodsId,"consumer"},'(Ljava/lang/String;Ljava/lang/String;)V')
        elseif device.platform == 'ios' then
            --先加载后购买的逻辑
            --声明平台可以直接进行购买了，因为在显示前要进行加载后才能调用购买的操作
            if self.loadedProducts[goodsId] then
                AppSDK.appstore.purchase(goodsId)
            else
                self.isIphonePay = true --没有加载商品之前调用支付
                AppSDK.appstore.loadProducts({goodsId}, handler(self,self.AppstorePayEvent))
            end
        end
    elseif platformId == KuaiKan then
        self:KuaiKanPay(t)
    elseif platformId == BestvAndroid then
        --百氏通支付
        local userInfo = gameMgr:GetUserInfo()
        local serverId = tostring(userInfo.serverId)
        local serverName = tostring((userInfo.serverName or '食之契约'))
        local roleId = tostring(userInfo.playerId)
        local roleName = tostring(userInfo.playerName)
        local roleLevel = tostring(userInfo.level)
        local extras = {goodsDescr = __('幻晶石'), notifyUrl = 'http://eater.duobaogame.com/gameApi/besTVNotify'}
        if DEBUG == 0 then
            extras = {goodsDescr = __('幻晶石'), notifyUrl = 'http://eater-android.fantanggame.com/gameApi/besTVNotify'}
        end
        if FOR_REVIEW then
            extras = {goodsDescr = __('幻晶石'), notifyUrl = 'http://eater-beta4.duobaogame.com/GameApi/besTVNotify'}
        end
        table.merge(t, extras)
        local parameters = json.encode({server = {serverId = serverId, serverName = serverName,
        playerId = roleId, playerName = roleName, userLevel = roleLevel}, pay = t})
        luaj.callStaticMethod(SDK_CLASS_NAME,'besTvSDKPay',{parameters})
    elseif isQuickSdk() then
        --quick sdk的逻辑
        local isFirst = (t.isFirst or false)
        local userInfo = gameMgr:GetUserInfo()
        local serverId = tostring(userInfo.serverId)
        local serverName = tostring((userInfo.serverName or '食之契约'))
        local roleId = tostring(userInfo.playerId)
        local roleName = tostring(userInfo.playerName)
        local roleLevel = tostring(userInfo.level)
        t['goodsDescr'] = __('幻晶石')
        if FOR_REVIEW then
            t['extraParams'] = "1"
        end
        local parameters = json.encode({server = {serverId = serverId, serverName = serverName,
        playerId = roleId, playerName = roleName, userLevel = roleLevel}, pay = t})
        self:QuickPay(parameters)
    end
end
-- 谷歌回调验证
function AppSDK:GoogleCallBack(event)
    self:RemoveLoadingView()
    if event.state == "google_success" then
        local productId = event.productId
        local purchaseToken = event.purchaseToken or ""
        local verify_func = function(data)
            self:RequestPay("pay/google2",data,function(datas)
                Paytools.RemoveRecipt(productId)
                luaj.callStaticMethod(SDK_CLASS_NAME,'finishTransaction',{productId},'(Ljava/lang/String;)V')
                if datas.orderId then
                    local orderInfoMgr = AppFacade.GetInstance():GetManager('OrderInfoManager')
                    local id = string.format('pay/orderInfo/%s', datas.orderId)
                    orderInfoMgr:Post(id, 'pay/orderInfo',EVENT_PAY_MONEY_SUCCESS,{orderNo = datas.orderId})
                end
            end)
        end
        if isJapanSdk() or isElexSdk() or isNewKoreanSdk() then
            verify_func({productId = productId , purchaseToken = purchaseToken})
        end
    end
end

function AppSDK:KuaiKanLoginAccount(t)
    if device.platform == 'android' then
        luaj.callStaticMethod(SDK_CLASS_NAME,'UserLoginAccount',{})
    end
end

function AppSDK:KuaiKanSwitchAccount(t)
    if device.platform == 'android' then
        luaj.callStaticMethod(SDK_CLASS_NAME,'UserSwitchAccount',{})
    end
end

function AppSDK:isReplayKitAvailable()
    local isAvailable = false
    if device.platform == 'ios' then
        if isElexSdk() then
            local isOk, ret = luaoc.callStaticMethod(SDK_CLASS_NAME,"isReplayKitAvailable")
            if isOk then
                isAvailable = (ret == 1)
            end
        end
    end
    return isAvailable
end

function AppSDK:StartRecord()
    if device.platform == 'ios' then
        if isElexSdk() then
            luaoc.callStaticMethod(SDK_CLASS_NAME,"startRecoding")
        end
    end
end

function AppSDK:StopRecord()
    if device.platform == 'ios' then
        if isElexSdk() then
            luaoc.callStaticMethod(SDK_CLASS_NAME,"stopRecoding")
        end
    end
end

--[[
--登录的sdk统一入口
--]]
function AppSDK:InvokeLogin(t)
    if platformId == KuaiKan then
        --快看平台的登录账号
        self:KuaiKanLoginAccount(t)
    elseif isEfunSdk() then
        --efun platform
        if device.platform == 'android' then
            luaj.callStaticMethod(SDK_CLASS_NAME,'userLogin',{})
        elseif device.platform == 'ios' then
            luaoc.callStaticMethod(SDK_CLASS_NAME, 'userLogin')
        end

    elseif isElexSdk() then
        --美区平台
        self:AddViewForNoTouch()
        if t.override ~= nil then
            self.overrideUserInfo = checkbool(t.override)
        else
            self.overrideUserInfo = true
        end
        if device.platform == 'android' then
            luaj.callStaticMethod(SDK_CLASS_NAME,'userLogin',{t.name})
        elseif device.platform == 'ios' then
            luaoc.callStaticMethod(SDK_CLASS_NAME,'userLogin',{platform = t.name})
        end
    elseif platformId == BestvAndroid then
        --百氏通的登录调用的逻辑
        local t = {notifyUrl = 'http://eater.duobaogame.com/gameApi/besTVVerify'}
        if DEBUG == 0 then
            t = {notifyUrl = 'http://eater-android.fantanggame.com/gameApi/besTVVerify'}
        end
        local params = json.encode(t)
        luaj.callStaticMethod(SDK_CLASS_NAME,'bestvSDKLogin',{params}, "(Ljava/lang/String;)V")
    elseif isFuntoySdk() then
        --android的官方平台号
        if device.platform == 'android' then
            luaj.callStaticMethod(SDK_CLASS_NAME,'userLogin',{})
        elseif device.platform == 'ios' then
            luaoc.callStaticMethod(SDK_CLASS_NAME, 'userLogin')
        end
    end
end

--[[
--官方平台上传角色信息的逻辑
--]]
function AppSDK:AndroidRoleUpload(t)
    if isFuntoySdk() then
        local gameMgr = AppFacade.GetInstance():GetManager('GameManager')
        local userInfo = gameMgr:GetUserInfo()
        local serverId = tostring(userInfo.serverId)
        local serverName = tostring((userInfo.serverName or '食之契约'))
        local playerId = tostring(userInfo.playerId)
        local roleName = tostring(userInfo.playerName)
        local roleLevel = tostring(userInfo.level)
        local roleCtime = tostring(userInfo.roleCtime)
        local diamond = tostring(userInfo.diamond)
        local parameters = json.encode({serverId = serverId, serverName = serverName,
        roleId = playerId, roleName = roleName, roleLevel = roleLevel, roleCtime = roleCtime, diamond = diamond, vip = '0', type = tostring(checktable(t).type)})
        luaj.callStaticMethod(SDK_CLASS_NAME,'createRole',{parameters})
    elseif isQuickSdk() then
        --quick sdk上传角色信息的接口
        local isFirst = (t.isFirst or false)
        local gameMgr = AppFacade.GetInstance():GetManager('GameManager')
        local userInfo = gameMgr:GetUserInfo()
        local serverId = tostring(userInfo.serverId)
        local serverName = tostring((userInfo.serverName or '食之契约'))
        local roleId = tostring(userInfo.playerId)
        local roleName = tostring(userInfo.playerName)
        local roleLevel = tostring(userInfo.level)
        local roleCtime = tostring(userInfo.roleCtime)
        local parameters = json.encode({server = {serverId = serverId, serverName = serverName,
        playerId = roleId, playerName = roleName, userLevel = roleLevel, createTime = roleCtime}, isFirst = isFirst})
        self:QuickUploadRoleInfo(parameters)
    end
end

function AppSDK:PlatformUserCenter()
    if isFuntoySdk() then
        if device.platform == 'android' then
            luaj.callStaticMethod(SDK_CLASS_NAME,'showUserCenter',{})
        else
            luaoc.callStaticMethod(SDK_CLASS_NAME, 'showUserCenter', {})
        end
    end
end

function AppSDK:InvokeSwitch(t)
    if platformId == KuaiKan then
        --快看平台的切换账号
        self:KuaiKanSwitchAccount(t)
    end
end


function AppSDK:NetSdk()
    --官服与渠道
    if isFuntoySdk() or isFuntoyExtraSdk() or isQuickSdk() then
        if device.platform == 'android' then
            if checkint(Platform.id) == PreAndroid and FTUtils:getTargetAPIVersion() >= 40 then
                --先行服网易测试
                local gameMgr = AppFacade.GetInstance():GetManager('GameManager')
                local userInfo = gameMgr:GetUserInfo()
                -- local serverId = tostring(userInfo.serverId)
                local roleId = tostring(userInfo.playerId)
                local roleName = tostring(userInfo.playerName)
                luaj.callStaticMethod(SDK_CLASS_NAME,'netSDK',{roleId, roleName, tostring(Platform.id)})
            elseif FTUtils:getTargetAPIVersion() >= 40 then
                --先行服网易测试
                local gameMgr = AppFacade.GetInstance():GetManager('GameManager')
                local userInfo = gameMgr:GetUserInfo()
                -- local serverId = tostring(userInfo.serverId)
                local roleId = tostring(userInfo.playerId)
                local roleName = tostring(userInfo.playerName)
                luaj.callStaticMethod(SDK_CLASS_NAME,'netSDK',{roleId, roleName, tostring(Platform.id)})
            end
        end
    end
end
function AppSDK:NetSdkIsOpenElex()
    if isElexSdk() and (not isNewUSSdk())  then
        local isResult =  compareVersion(FTUtils:getAppVersion(), "1.21.1")
        return isResult == 1
    end
    return false
end
---[[
--分享sdk接口的逻辑
--@param platformType --分享到指定平台的逻辑
--{text = "", image = "", title = "", url = "", type = "内容类型"
-- client_share = true, api_share = true --ios启用weiboapi接口分享}
--]]
function AppSDK:InvokeShare(platformType, t)
    if isEfunSdk() then

        if t.myurl then
            t.linkUrl = t.myurl
        end
        if t.text then
            t.description = t.text
        end

        if device.platform == 'ios' then
            local httpMgr = AppFacade.GetInstance():GetManager('HttpManager')
            httpMgr:Post('Player/share', "SHARE_REQUEST_RESPONSE",{})
            luaoc.callStaticMethod(SDK_CLASS_NAME,'shareImage',{path = t.image, platform = platformType, linkUrl = t.linkUrl, description = t.description})
        else
            local jstr = json.encode({path = t.image, platform = platformType, linkUrl = t.linkUrl, description = t.description})
            luaj.callStaticMethod(SDK_CLASS_NAME, 'efunShareImage', {jstr})
        end
    elseif isElexSdk() then
        if platformType ~= SHARE_TYPE.FACEBOOK then
            if cc.UserDefault:getInstance():getBoolForKey(CV_SHARE_ACTIVITY_KEY, false) then
                -- cv活动分享

                AppFacade.GetInstance():DispatchObservers('ACTIVITY_CVSHARE_SHARED')
            else
                --分享成功的逻辑
                local httpMgr = AppFacade.GetInstance():GetManager('HttpManager')
                httpMgr:Post('Player/share', "SHARE_REQUEST_RESPONSE",{})
            end

        end
        if device.platform == 'ios' then
            luaoc.callStaticMethod(SDK_CLASS_NAME,'shareFacebook',{path = t.image, platform = platformType, linkUrl = t.linkUrl, description = t.description})
        else
            local jstr = json.encode({path = t.image, platform = tostring(platformType), linkUrl = t.linkUrl, description = t.description})
            luaj.callStaticMethod(SDK_CLASS_NAME, 'shareFacebook', {jstr})
        end
     ---11
    elseif isJapanSdk() then
        if device.platform == 'ios' then
            luaoc.callStaticMethod(SDK_CLASS_NAME,'share',{path = t.image, platform = platformType, linkUrl = t.linkUrl, description = t.description})
        else
            local jstr = json.encode({path = t.image, platform = platformType, linkUrl = t.linkUrl, description = t.description})
            luaj.callStaticMethod(SDK_CLASS_NAME, 'share', {jstr})
        end
        return errMsg
    end
end

--[[
--美区解锁appstore或者是google平台的成就
--]]
function AppSDK:UnlockArchivement(t)
    if isElexSdk() then
        if checkint(Platform.id) == ElexIos or checkint(Platform.id) == ElexAndroid then
            --appstore或者google平台才调用接口
            if device.platform == 'ios' then
                luaoc.callStaticMethod(SDK_CLASS_NAME,'getAchievement',{id = t.id, percent = 100})
            else
                luaj.callStaticMethod(SDK_CLASS_NAME, 'unlockAchivement', {t.id})
            end
        end
    end
end

function AppSDK:PreviewArchivement()
    if isElexSdk() then
        if checkint(Platform.id) == ElexIos or checkint(Platform.id) == ElexAndroid then
            --appstore或者google平台才调用接口
            if device.platform == 'ios' then
                luaoc.callStaticMethod(SDK_CLASS_NAME,'showLeaderBoard',{id = "discover"})
            else
                luaj.callStaticMethod(SDK_CLASS_NAME, 'showAchievements', {})
            end
        end
    end
end


function AppSDK:ShowFloatButton()
    if isEfunSdk() then
        local gameMgr = AppFacade.GetInstance():GetManager('GameManager')
        local userInfo = gameMgr:GetUserInfo()
        local serverId = tostring(userInfo.serverId)
        local serverName = tostring((userInfo.serverName or '食之契约'))
        local roleId = tostring(userInfo.playerId)
        local roleName = tostring(userInfo.playerName)
        local roleLevel = tostring(userInfo.level)
        local userId = userInfo.userSdkId
        if device.platform == 'ios' then
            -- vipLevel 游戏里面没有vip 等级 默认传1
            luaoc.callStaticMethod(SDK_CLASS_NAME,'showPlatformButton',{serverId = serverId, serverName = serverName, roleId = roleId, roleName = roleName, roleLevel = roleLevel, userId = userId , vipLevel = 1})
        elseif device.platform == 'android' then
            local jstr = json.encode({serverId = serverId, serverName = serverName, roleId = roleId, roleName = roleName, roleLevel = roleLevel, userId = userId})
            luaj.callStaticMethod(SDK_CLASS_NAME, 'efunShowFloatBar', {jstr})
        end
    end
end

function AppSDK:EfuncLogout()
    if isEfunSdk() then
        if device.platform == 'ios' then
            luaoc.callStaticMethod(SDK_CLASS_NAME,'logout')
        elseif device.platform == 'android' then
            luaj.callStaticMethod(SDK_CLASS_NAME, 'efunSystemSettings')
        end
    end
end
function AppSDK:HideFloatButton()
    if isEfunSdk() then
        if device.platform == 'ios' then
            luaoc.callStaticMethod(SDK_CLASS_NAME,'hidePlatformButton')
        else
            luaj.callStaticMethod(SDK_CLASS_NAME, 'efunHiddenPlatform')
        end
        return errMsg
    end
end

function AppSDK:ShowAppStoreReview(cardId)
    if isKoreanSdk() then
        if device.platform == 'android' then
            luaj.callStaticMethod(SDK_CLASS_NAME,'appStoreReview',{})
        elseif device.platform == 'ios' then
            luaoc.callStaticMethod(SDK_CLASS_NAME,'appStoreReview')
        end
    elseif platformId == ElexAndroid or platformId == ElexIos then
         if device.platform == 'android' then
            luaj.callStaticMethod(SDK_CLASS_NAME,'appstoreReview',{})
        elseif device.platform == 'ios' then
            luaoc.callStaticMethod(SDK_CLASS_NAME,'appstoreReview')
        end
    end
end
-------[[
------- quicksdk 相关的逻辑代码
--]]

function AppSDK:QuickSdkInit()
    --如果没有初化成功
    if self:IsQuickInitialed() then
        self:QuickLogin()
    end
end

function AppSDK:QuickLogin()
    luaj.callStaticMethod(SDK_CLASS_NAME,'quickSDKLogin',{})
end

function AppSDK:QuickLogout()
    if isElexSdk() then
        self:AddViewForNoTouch()
        if device.platform == 'ios' then
            luaoc.callStaticMethod(SDK_CLASS_NAME,'logout',{platform = "google"})
        else
            luaj.callStaticMethod(SDK_CLASS_NAME, 'userLogout',{"google"})
        end
    else
        luaj.callStaticMethod(SDK_CLASS_NAME,'quickSDKLogout',{})
    end
end

function AppSDK:QuickExit()
    luaj.callStaticMethod(SDK_CLASS_NAME,'quickSDKExit',{})
end

function AppSDK:QuickFloatButton(isShow)
    if isShow == nil then isShow = true end
    if isShow then
        luaj.callStaticMethod(SDK_CLASS_NAME,'quickSDKShowFloatButton',{})
    else
        luaj.callStaticMethod(SDK_CLASS_NAME,'quickSDKHiddenFloatButton',{})
    end
end

function AppSDK:QuickExchangeAccount()
    luaj.callStaticMethod(SDK_CLASS_NAME,'quickSDKExchange',{})
end

function AppSDK:QuickUploadRoleInfo(params)
    if type(params) == 'table' then
        params = json.encode(params)
    end
    luaj.callStaticMethod(SDK_CLASS_NAME,'quickSetGameRoleInfo',{params})
end
--[[
--调用支付的逻辑
--]]
function AppSDK:QuickPay(params)
    if type(params) == 'table' then
        params = json.encode(params)
    end
    luaj.callStaticMethod(SDK_CLASS_NAME,'quickSDKPay',{params})
end

function AppSDK:IsQuickInitialed()
    local _, isInit = luaj.callStaticMethod(SDK_CLASS_NAME,'isInitialed',{},'()I')
    local bool_init = false
    if type(isInit) == 'number' then
        bool_init = (isInit == 1)
    elseif type(isInit) == 'bool' then
        bool_init = checkbool(isInit)
    end

    return bool_init
end

function AppSDK:EfunIsBindPhone()
    if isEfunSdk() then
        if device.platform == 'ios' then
            luaoc.callStaticMethod(SDK_CLASS_NAME, 'hasBindPhone')
        elseif device.platform == 'android' then
            local gameMgr = AppFacade.GetInstance():GetManager('GameManager')
            local userInfo = gameMgr:GetUserInfo()
            luaj.callStaticMethod(SDK_CLASS_NAME,'efunQueryPhone',{tostring(userInfo.userSdkId)})
        end
    end
end

function AppSDK:EfunBindPhone()
    if isEfunSdk() then
        if device.platform == 'ios' then
            --显示用户中心
            luaoc.callStaticMethod(SDK_CLASS_NAME, 'showPlatformModule', {moduleTpye = '4'})
        elseif device.platform == 'android' then
            local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
            local userInfo = gameMgr:GetUserInfo()
            local data = {}
            data.userSdkId = userInfo.userSdkId
            luaj.callStaticMethod(SDK_CLASS_NAME,'efunBindPhone',{json.encode(data)})
        end
    end
end

function AppSDK:relateFacebookToEfun()
    if isEfunSdk() then
        self:AddViewForNoTouch()
        if device.platform == 'ios' then
            --显示用户中心
            luaoc.callStaticMethod(SDK_CLASS_NAME, 'relateToEfunUserIdAndSyncPlayingFriends')
        elseif device.platform == 'android' then
            -- local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
            -- local userInfo = gameMgr:GetUserInfo()
            -- local  data ={}
            -- data.userSdkId = userInfo.userSdkId
            luaj.callStaticMethod(SDK_CLASS_NAME,'getFacebookMyProfile',{})
        end
    end
end

function AppSDK:efunFacebookAuthor()
    if isEfunSdk() then
        if device.platform == 'ios' then
            --显示用户中心
            luaoc.callStaticMethod(SDK_CLASS_NAME, 'facebookAuthor')
        elseif device.platform == 'android' then
            -- luaj.callStaticMethod(SDK_CLASS_NAME,'efunBindPhone',{})
        end
    end
end


function AppSDK:efunGetInvitableFriends(pageNo, limit)
    pageNo = (pageNo or 1)
    limit =  (limit or 100)
    if isEfunSdk() then
        self:AddViewForNoTouch()
        if device.platform == 'ios' then
            --显示用户中心
            luaoc.callStaticMethod(SDK_CLASS_NAME, 'facebookGetInvitableFriends',{pageNo = pageNo, limit = limit})
        elseif device.platform == 'android' then
            local data = { pageNo = pageNo, limit = limit}
            luaj.callStaticMethod(SDK_CLASS_NAME,'fetchInvitableFriends',{json.encode(data)})
        end
    end
end

function AppSDK:efunInvitFriendsRequest(ids)
    if isEfunSdk() and table.nums(ids) > 0 then
        self:AddViewForNoTouch()
        if device.platform == 'ios' then
            --显示用户中心
            local jsonstr = json.encode({inviteList = ids, content = '《食之契約》是款二次元超幻想美食冒險手機遊戲，各類美食幻化為食靈角色，豐崎愛生、佐倉綾音、澤城美雪等一線豪華聲優，邀你一起加入這場美食盛宴吧!'})
            cclog(jsonStr)
            luaoc.callStaticMethod(SDK_CLASS_NAME, 'facebookInviteRequestMessage',{request = jsonstr})
        elseif device.platform == 'android' then
            local jsonstr = json.encode({inviteList = ids, content = '《食之契約》是款二次元超幻想美食冒險手機遊戲，各類美食幻化為食靈角色，豐崎愛生、佐倉綾音、澤城美雪等一線豪華聲優，邀你一起加入這場美食盛宴吧!'})
            cclog(jsonStr)
            luaj.callStaticMethod(SDK_CLASS_NAME,'facebookSendInviteRequest',{jsonstr})
        end
    end
end

function AppSDK:AddLoadingView()
    if device.platform == 'ios' or (device.platform == 'android' and FTUtils:getTargetAPIVersion() >= 13) then
        local dialogNodeLayer = sceneWorld:getChildByTag(GameSceneTag.Dialog_GameSceneTag)
        local colorLayer = dialogNodeLayer:getChildByTag(9999998)
        if not colorLayer then
            colorLayer = require("common.ProgressHUD").new()
            colorLayer:setTag(9999998)
            colorLayer:setPosition(cc.p(display.cx, display.cy))-- - NAV_BAR_HEIGHT
            dialogNodeLayer:addChild(colorLayer,600)
        end
        colorLayer:setVisible(true)
    end
end

function AppSDK:RemoveLoadingView()
    local dialogNodeLayer = sceneWorld:getChildByTag(GameSceneTag.Dialog_GameSceneTag)
    local touchNode = dialogNodeLayer:getChildByTag(9999998)
    if touchNode then
        touchNode:runAction(cc.RemoveSelf:create())
    end
end



function AppSDK:AddViewForNoTouch()
    local dialogNodeLayer = sceneWorld:getChildByTag(GameSceneTag.Dialog_GameSceneTag)
	local colorLayer = dialogNodeLayer:getChildByTag(9999999)
	if not colorLayer then
		colorLayer = CColorView:create(cc.c4b(0, 0, 0, 0))
		colorLayer:setTag(9999999)
		colorLayer:setTouchEnabled(true)
		colorLayer:setContentSize(display.size)
		colorLayer:setAnchorPoint(cc.p(0.5, 1.0))
		colorLayer:setPosition(cc.p(display.cx, display.height))-- - NAV_BAR_HEIGHT
        dialogNodeLayer:addChild(colorLayer,600)
	end
	colorLayer:setVisible(true)
end

function AppSDK:RemoveViewForNoTouch()
    local dialogNodeLayer = sceneWorld:getChildByTag(GameSceneTag.Dialog_GameSceneTag)
    local touchNode = dialogNodeLayer:getChildByTag(9999999)
    if touchNode then
        touchNode:setVisible(false)
    end
end


function AppSDK:AppstorePayEvent(event)
    if DEBUG > 0 then
        logInfo.add(logInfo.Types.HTTP, string.fmt('--> eventBack %1\n%2', 'appstoreCallback', tableToString(event, nil, 10)))
    end
    if event.ccstore then
        local ctype = tostring(event.ccstore)
        if ctype == 'restore' then
            if event.products and table.nums(event.products) > 0 then
                local index = 1
                local products = event.products
                local p = products[index]
                if p then
                    local transactionIdentifier = p.transactionIdentifier
                    local receipt = crypto.encodeBase64(p.receipt)
                    local function checkGooglePayOrder(datas)
                        index = index + 1
                        AppSDK.appstore.finishTransaction(p)
                        if datas.orderId then
                            local orderInfoMgr = AppFacade.GetInstance():GetManager('OrderInfoManager')
                            local id = string.format('pay/orderInfo/%s', datas.orderId)
                            orderInfoMgr:Post(id, 'pay/orderInfo',EVENT_PAY_MONEY_SUCCESS,{orderNo = datas.orderId})
                        end
                        if index <= #products then
                            p = products[index]
                            transactionIdentifier = p.transactionIdentifier
                            receipt = crypto.encodeBase64(p.receipt)
                            self:RequestPay("pay/apple",{receipt = receipt,transactionId = transactionIdentifier}, checkGooglePayOrder)
                        end
                    end
                    self:RequestPay("pay/apple",{receipt = receipt,transactionId = transactionIdentifier}, checkGooglePayOrder)
                end
            end
        elseif ctype == 'completed' then
            local transaction = event.transaction
            if transaction.state == 'purchased' then
                local receipt = transaction.receipt
                receipt = crypto.encodeBase64(receipt)
                local params = {receipt = receipt,transactionId = transaction.transactionIdentifier}
                Paytools.StoreRecipt(transaction.transactionIdentifier,{receipt = receipt})
                self:RequestPay("pay/apple", params, function(datas)
                    Paytools.RemoveRecipt(transaction.transactionIdentifier)
                    AppSDK.appstore.finishTransaction(transaction)
                    if datas.orderId then
                        local orderInfoMgr = AppFacade.GetInstance():GetManager('OrderInfoManager')
                        local id = string.format('pay/orderInfo/%s', datas.orderId)
                        orderInfoMgr:Post(id, 'pay/orderInfo',EVENT_PAY_MONEY_SUCCESS,{orderNo = datas.orderId})
                    end
                end)
            elseif transaction.state == 'cancelled' then
                -- AppFacade.GetInstance():GetManager("GameManager"):RemoveLoadingView()
            end
        elseif ctype == 'failed' then
            local transaction = event.transaction
            AppSDK.appstore.finishTransaction(transaction)
            AppFacade.GetInstance():GetManager("GameManager"):RemoveLoadingView()
        end
    elseif event.products then
        --加载商品列表的逻辑
        if isElexSdk() then
            if self.isIphonePay then
                --如果没有商品列表的购买的逻辑
                local pp = event.products[1]
                self.isIphonePay = false
                AppSDK.appstore.purchase(pp.productIdentifier)
            else
                for name,val in pairs(event.products) do
                    if platformId == ElexAndroid then
                        val.priceLocale = val.displayPrice
                    elseif platformId == ElexAmazon then
                        val.priceLocale = val.price
                    end
                    self.loadedProducts[tostring(val.productIdentifier)] = val
                end
                AppFacade.GetInstance():DispatchObservers("APP_STORE_PRODUCTS")
            end
        else
            local pp = event.products[1]
            AppSDK.appstore.purchase(pp.productIdentifier)
        end
    else
        local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
        uiMgr:ShowInformationTips('some error'.. tostring(event.errorCode)..tostring(event.errorString))--展示异常信息
    end
end

--[[
--请求支付结查到服务器查询
--]]
function AppSDK:RequestPay(path, datas, callback)
    local url = table.concat({'http://',Platform.ip,'/',path},'')
    if HTTP_USE_SSL then
        url = table.concat({'https://',Platform.ip,'/',path},'')
    end
    local gameManager = AppFacade.GetInstance():GetManager("GameManager")
    local xhr = cc.XMLHttpRequest:new()
    xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
    -- xhr:setRequestHeader("Host",tostring(Platform.serverHost))
    xhr.timeout = 30
    xhr:open("POST", url)
    logInfo.add(logInfo.Types.HTTP, string.fmt('--> request %1 %2\n%3', "POST", url, tableToString(datas or {})))
    --显示加载包子进度，然后进行请求
    gameManager:ShowLoadingView()
    local function netBack()
        local stateValue = 'success'
        local stateValue = 'parse'
        local result = nil
        if xhr.readyState == 4 and (xhr.status >= 200 and xhr.status < 207) then
            local responseStr = xhr.response
            if DEBUG > 0 then
                funLog(Logger.DEBUG, responseStr, path .. 'get_success')
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
        if stateValue == 'timeout' then
            gameManager:ShowRetryNetworkView(path, datas, "timeout")
        elseif stateValue == 'parse' then
            gameManager:ShowRetryNetworkView(path, datas, "parse")
        elseif stateValue == 'success' then
            gameManager:RemoveLoadingView()
            if DEBUG > 0 then
                logInfo.add(logInfo.Types.HTTP, string.fmt('--> netBack %1 %2\n%3', "POST", url, tableToString(result, nil, 10)))
            end
            local errorcode = checkint(result.errcode)
            if errorcode == -1 then
                --- session过期需要退出游戏
                gameManager:ShowExitGameView()
            elseif errorcode == 99 then
                gameManager:ShowRetryNetworkView(path, datas, "parse")
            elseif errorcode == 100 then
                --正在停机维护的接口逻辑
                gameManager:ShowExitGameView(__('当前服务器正在维护，请耐心等待服务器维护完成!'), true)
            elseif errorcode == 0 then
                --succc有逻辑
                if checktable(result.data).gold and result.timestamp then
                    profileTimestamp = checkint(result.timestamp)
                elseif checktable(result.data).hp and result.timestamp then
                    profileTimestamp = checkint(result.timestamp)
                end
                if callback then
                    callback(result.data)
                end
            else
                --其他错误异常逻辑
                if isElexSdk() or isJapanSdk() then
                    if device.platform == 'ios' then
                        local transactionIdentifier = tostring(datas.transactionId)
                        if transactionIdentifier then
                            Paytools.RemoveRecipt(transactionIdentifier)
                            AppSDK.appstore.finishTransaction({transactionIdentifier = transactionIdentifier})
                        end
                    end
                    -- elseif platformId == ElexAmazon then
                        -- local productId = datas.productId
                        -- Paytools.RemoveRecipt(productId)
                        -- luaj.callStaticMethod(SDK_CLASS_NAME,'finishTransaction',{productId,receiptId},'(Ljava/lang/String;Ljava/lang/String;)V')
                    -- elseif platformId == ElexAndroid then
                        -- local productId = datas.productId
                        -- Paytools.RemoveRecipt(productId)
                        -- luaj.callStaticMethod(SDK_CLASS_NAME,'finishTransaction',{productId},'(Ljava/lang/String;)V')
                    -- end
                else
                    local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
                    uiMgr:ShowInformationTips(string.format("%s >_< ",tostring(result.errmsg))) --展示异常信息
                end
            end
        end
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

    if datas then
        table.merge(t, datas)
    end
    local sign = generateSign(t)
    t['sign'] = sign
    local djson = json.encode(t)
    local zlib = require("zlib")
    local compressed = zlib.deflate(5, 15 + 16)(djson, "finish")
    if not compressed then compressed = djson end
    if DEBUG and DEBUG > 0 then
        funLog(Logger.DEBUG, t)
    end
    xhr:setRequestHeader("User-Agent", string.format('U:%s,P:%s',tostring(userInfo.userId),tostring(playerId)))
    -- xhr:setRequestHeader('Content-Type', 'application/json')
    xhr:registerScriptHandler(netBack)
    xhr:send(compressed)
end
-- 掉单查询
function AppSDK:OffSingalQuery()
    if not self.isRestoreInvoked then
        self.isRestoreInvoked = true
        if device.platform == "android" then
            if (isNewKoreanSdk() or isElexSdk()) and FTUtils:getTargetAPIVersion() > 14 then
                luaj.callStaticMethod(SDK_CLASS_NAME,'queryPurchasesInApp',{})
            elseif isJapanSdk() and FTUtils:getTargetAPIVersion() > 42 then
                luaj.callStaticMethod(SDK_CLASS_NAME,'queryPurchasesInApp',{})
            end
        end
    end
end

function AppSDK:AIHelper(params)
    if device.platform == 'android' and FTUtils:getTargetAPIVersion() >= 16 then
        local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
        local userInfo = gameMgr:GetUserInfo()
        local tcountry = string.split(i18n.getLang(), '-')[1]
        if not tcountry then tcountry = 'en' end
        if tcountry == 'zh' then tcountry = 'zh_TW' end
        local text = json.encode({
            userId = userInfo.playerId, 
            userName = userInfo.playerName,
            serverId = userInfo.serverId,
            lan = tcountry,
            isShowFAQs = params.isShowFAQs or false
        })
        if params.isSetCustomData then
            text.customData = tostring(userInfo.playerName),
            tostring(userInfo.playerId),
            checkint(userInfo.serverId),
            "",
            "1",{["aihelp-custom-metadata"] = {
                    ["aihelp-tags"] = "vip0,s0,and_usa",
                    ["level"] = tostring(userInfo.level),
                    ["playerId"] = tostring(userInfo.playerId),
                    ["server"]  = "0",
                    ["Conversation"] = "1",
                    ["playerName"] = tostring(userInfo.playerName),
                    ["channel"] = "and_usa",
                    ["viplevel"] = "0",
                    ["resVersion"] = tostring(utils.getAppVersion()),
            }}
        end
        luaj.callStaticMethod("AIHelper", 'updateUserInfo', {params})
    end
end
return AppSDK

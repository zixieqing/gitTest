--[[
登录注册mediator
--]]
local t = {"battle", "common", "conf", "Frame", "Game", "home", "i18n", "root", "update"}
for k,v in pairs(package.loaded) do
    for kk,vv in pairs(t) do
        if string.match( k, string.format('^%s', vv) ) then
            if k ~= 'Frame.AudioManager' and k ~= 'root.AppSDK' then
                package.loaded[k] = nil
                package.preload[k] = nil
                _G[k] = nil

            end
        end
    end
end
for k,v in pairs(package.preload) do
    for kk,vv in pairs(t) do
        if string.match( k, string.format('^%s', vv) ) then
            if k ~= 'Frame.AudioManager' and k ~= 'root.AppSDK' then
                package.loaded[k] = nil
                package.preload[k] = nil
                _G[k] = nil

            end
        end
    end
end
package.loaded['config'] = nil
package.preload['config'] = nil
_G['config'] = nil

local Mediator = mvc.Mediator
local AuthorMediator = class("AuthorMediator", Mediator)
local NAME = "AuthorMediator"
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local AuthorCommand = require('Game.command.AuthorCommand')
local BUTTON_TAG = {
    FAQ_TAG = 10001 , -- FAQ 的tag 值
}
local platformId = checkint(Platform.id)

STORE_ACCOUNT_KEY = 'STORE_ACCOUNT_KEY'

local DICT = {
    Progress_Bg = "update/update_bg_loading.png",
    Progress_Image = IS_CHINA_GRAY_MODE and "update/gray/update_ico_loading.png" or "update/update_ico_loading.png",
    Progress_Top = "update/update_ico_loading_fornt.png",
    Progress_Descr = "update/update_bg_refresh_number.png",
}

---------------------------------------------------
-- mediator extend begin --
---------------------------------------------------
function AuthorMediator:ctor( viewComponent )
	self.super:ctor(NAME, viewComponent)
    self.startTime = os.time()
end

function AuthorMediator:InterestSignals()
	local signals = {
		SIGNALNAMES.Login_Callback,
        SIGNALNAMES.Channel_Login_Callback,
		SIGNALNAMES.Checkin_Callback,
		SIGNALNAMES.GetUserByUdid_Callback,
		SIGNALNAMES.Regist_Callback,
		SIGNALNAMES.CreateRole_Callback,
        -- EVENT_SDK_LOGIN,
        -- EVENT_SDK_LOGIN_CANCEL,
        POST.ELEX_USER_BY_UDID.sglName,
		SIGNALNAMES.SERVER_APPOINT_Callback,
        EVENT_SDK_LOGIN,
        EVENT_SDK_LOGIN_CANCEL,
        'EVENT_APPOINT_SHARE_RESULT',
        DOWNLOAD_DEFINE.RES_JSON.event,
        POST.USER_ACCOUNT_BIND_REAL_AUTH.sglName,
        POST.USER_EUROPEAN_AGREEMENT.sglName
	}
	return signals
end

function AuthorMediator:Initial( key )
	self.super.Initial(self,key)
    self.isloaded = false
    self.isShowPolicy = false -- 是否显示隐私条款
end

--[[
--开始加载资源
--]]
function AuthorMediator:LoadingResources()
    --添加一个进度条
    if self.isloaded then return end
    self.isloaded = true

    local colorView = CColorView:create(cc.c4b(100,100,100,0))
    colorView:setAnchorPoint(display.CENTER_BOTTOM)
    colorView:setPosition(cc.p(display.cx, 0))
    colorView:setContentSize(cc.size(display.width, 100))
    self:GetViewComponent():addChild(colorView,10)
    -- 进度条
    local loadingBarBg = display.newImageView(_res('update/update_bg_black.png'))
    display.commonUIParams(loadingBarBg, {po = cc.p(display.cx, 0), ap = cc.p(0.5, 0)})
    colorView:addChild(loadingBarBg)
    -- loadingBarBg:setVisible(false)

    local loadingBar = CProgressBar:create(_res(DICT.Progress_Image))
    loadingBar:setBackgroundImage(_res(DICT.Progress_Bg))
    loadingBar:setDirection(0)
    loadingBar:setMaxValue(100)
    loadingBar:setValue(0)
    loadingBar:setPosition(cc.p(display.cx, 105))
    colorView:addChild(loadingBar, 1)

    -- 进度条闪光
    local loadingBarShine = display.newNSprite(_res('update/update_ico_light.png'), 0, loadingBar:getPositionY())
    colorView:addChild(loadingBarShine, 2)
    local percent = loadingBar:getValue() / loadingBar:getMaxValue()
    loadingBarShine:setPositionX(loadingBar:getPositionX() - loadingBar:getContentSize().width * 0.5 + loadingBar:getContentSize().width * percent - 1)
    -- loadingBarShine:setOpacity(255 * percent)
    -- local loadingBarShineActionSeq = cc.RepeatForever:create(cc.Sequence:create(
    --     cc.FadeTo:create(4, 0),
    --     cc.FadeTo:create(4, 255)))
    -- loadingBarShine:runAction(loadingBarShineActionSeq)

    -- 提示
    local loadingTipsBg = display.newImageView(_res('update/loading_bg_tips.png'))
    display.commonUIParams(loadingTipsBg,
    {ap = cc.p(0.5, 1), po = cc.p(loadingBar:getPositionX(), loadingBar:getPositionY() - loadingBar:getContentSize().height * 0.5 - 3)})
    colorView:addChild(loadingTipsBg, 1)

    local tipsData = CommonUtils.GetConfigAllMess('loadingTips','common')
    local text = ''
    if tipsData and table.nums(tipsData) > 0 then
        utils.newrandomseed()
        local len = table.nums(tipsData)
        local pos = math.random(1,len)
        text = tipsData[tostring(pos)].substance
    end
    local padding = cc.p(20, 7)
    local loadingTipsLabel = display.newLabel(padding.x, loadingTipsBg:getContentSize().height - padding.y,
    {text = text,
    fontSize = fontWithColor('18').fontSize, color = fontWithColor('18').color, ap = cc.p(0, 1), hAlign = display.TAL,
    w = loadingTipsBg:getContentSize().width - padding.x * 2, h = loadingTipsBg:getContentSize().height - padding.y * 2})
    loadingTipsBg:addChild(loadingTipsLabel)

    -- 小人和加载文字
    local avatarAnimationName = 'loading_avatar'
    local animation = cc.AnimationCache:getInstance():getAnimation(avatarAnimationName)
    if nil == animation then
        animation = cc.Animation:create()
        for i = 1, 10 do
            animation:addSpriteFrameWithFile(_res(string.format('update/loading_run_%d.png', i)))
        end
        animation:setDelayPerUnit(0.05)
        animation:setRestoreOriginalFrame(true)
        cc.AnimationCache:getInstance():addAnimation(animation, avatarAnimationName)
    end

    local loadingAvatar = display.newNSprite(_res('update/loading_run_1.png'), 0, 0)
    if IS_CHINA_GRAY_MODE then
        loadingAvatar = FilteredSpriteWithOne:create()
        loadingAvatar:setTexture(_res('update/loading_run_1.png'))
        loadingAvatar:setFilter(GrayFilter:create())
    end
    loadingAvatar:setPositionY(loadingBar:getPositionY() + loadingBar:getContentSize().height * 0.5 + loadingAvatar:getContentSize().width * 0.5 + 10)
    colorView:addChild(loadingAvatar, 5)
    loadingAvatar:runAction(cc.RepeatForever:create(cc.Animate:create(animation)))

    local loadingLabelBg = display.newImageView(_res('update/bosspokedex_name_bg.png'))
    if IS_CHINA_GRAY_MODE then
        loadingLabelBg = FilteredSpriteWithOne:create()
        loadingLabelBg:setTexture(_res('update/bosspokedex_name_bg.png'))
        loadingLabelBg:setFilter(GrayFilter:create())
    end
    loadingLabelBg:setPositionY(loadingAvatar:getPositionY() - 8)
    colorView:addChild(loadingLabelBg, 4)

    local loadingLabel = display.newLabel(utils.getLocalCenter(loadingLabelBg).x - 20, utils.getLocalCenter(loadingLabelBg).y - 2,fontWithColor(14,
    {text = __('正在载入'), fontSize = 24, color = '#ffffff'}))
    loadingLabel:enableOutline(ccc4FromInt('290c0c'), 1)
    loadingLabelBg:addChild(loadingLabel)

    local offsetX = -25
    local totalWidth = loadingAvatar:getContentSize().width + loadingLabelBg:getContentSize().width + offsetX
    local baseX = display.cx
    local loadingAvatarX = baseX - totalWidth * 0.5 + loadingAvatar:getContentSize().width * 0.5
    local loadingLabelBgX = loadingAvatarX + loadingAvatar:getContentSize().width * 0.5 + offsetX + loadingLabelBg:getContentSize().width * 0.5
    loadingAvatar:setPositionX(loadingAvatarX)
    loadingLabelBg:setPositionX(loadingLabelBgX)

--[[
    local expBar = CProgressBar:create(_res(DICT.Progress_Image))
    expBar:setBackgroundImage(_res(DICT.Progress_Bg))
    expBar:setDirection(0)
    expBar:setMaxValue(100)
    expBar:setValue(0)
    -- expBar:setShowValueLabel(true)
    -- expBar:getLabel():setColor(ccc4FromInt("4c4c4c"))
    -- expBar:getLabel():setSystemFontSize(20)
    -- expBar:getLabel():setString("")
    expBar:setAnchorPoint(display.CENTER_TOP)
    expBar:setPosition(cc.p(display.cx, 94))
    colorView:addChild(expBar,10)
    local progressTop = display.newImageView(_res(DICT.Progress_Top,display.cx))
    -- progressTop:setAnchorPoint(cc.p(0.5,1.0))
    local esize = expBar:getContentSize()
    progressTop:setPosition(cc.p(esize.width * 0.5, esize.height * 0.5 - 0.5))
    expBar:addChild(progressTop, 22)

    local describeBg = display.newImageView(_res(DICT.Progress_Descr))
    display.commonUIParams(describeBg, {ap = cc.p(0.5,0), po = cc.p(display.cx, 0)})
    local progressLabel = display.newLabel(0, 0,{fontSize = 20,color = '5c5c5c', text = __("加载资源中,请稍侯...")} )
    display.commonUIParams(progressLabel, {po = cc.p(describeBg:getContentSize().width * 0.5,describeBg:getContentSize().height * 0.5)})
    describeBg:addChild(progressLabel)
    colorView:addChild(describeBg, 9)
    --]]

	cc.Director:getInstance():getTextureCache():removeUnusedTextures()
    if isElexSdk() or isJapanSdk() then
        if gameMgr:GetUserInfo().playerId == nil or checkint(gameMgr:GetUserInfo().playerId) <= 0 then
            local AppSDK = require('root.AppSDK')
            AppSDK.GetInstance():AppFlyerEventTrack("LoadingStart",{af_event_start = "LoadingStart"})
        else
            local AppSDK = require('root.AppSDK')
            AppSDK.GetInstance():AppFlyerEventTrack("LoadingLogin",{af_event_start = "LoadingLogin", playerId = tostring(gameMgr:GetUserInfo().playerId)})
        end
    end
    PlayAudioClip("ty_8")
    local dataManager = AppFacade.GetInstance():GetManager("DataManager")
    DotGameEvent.SendEvent(DotGameEvent.EVENTS.LOADING_START)
    dataManager:InitialDatasAsync(function ( event )
        if event.event == 'done' then
            if isElexSdk() or isJapanSdk() then
                if gameMgr:GetUserInfo().playerId == nil or checkint(gameMgr:GetUserInfo().playerId) <= 0 then
                    local AppSDK = require('root.AppSDK')
                    AppSDK.GetInstance():AppFlyerEventTrack("LoadingDone",{af_event_start = "LoadingDone"})
                end
            end
            DotGameEvent.SendEvent(DotGameEvent.EVENTS.LOADING_END)
            if gameMgr:GetUserInfo().playerId ~= nil and checkint(gameMgr:GetUserInfo().playerId) > 0 then
                local AppSDK =  require('root.AppSDK').GetInstance()
                if AppSDK.NetSdk then
                    AppSDK:NetSdk()
                end

                local key = string.format('%s_ModulePanelIsOpen', tostring(gameMgr:GetUserInfo().playerId))
                cc.UserDefault:getInstance():setBoolForKey(key, false)
                cc.UserDefault:getInstance():flush()
                PlayAudioClip("stop_ty_8")
                local function SwitchToHome(  )
                    local HomeMediator = require( 'Game.mediator.HomeMediator')
                    local mediator = HomeMediator.new()
                    AppFacade.GetInstance():RegistMediator(mediator)
                    --聊天长连接
                    local chatSocketManager = AppFacade.GetInstance():GetManager("ChatSocketManager")
                    chatSocketManager:Connect(Platform.ChatTCPHost,Platform.ChatTCPPort)
                end

                if 0 < checkint(SUBPACKAGE_LEVEL) and cc.UserDefault:getInstance():getBoolForKey('SubpackageRes_' .. tostring(FTUtils:getAppVersion()), false) == false then
                    local playerLevel   = checkint(gameMgr:GetUserInfo().level)
                    if playerLevel >= checkint(SUBPACKAGE_LEVEL) then
                        local uiMgr = self:GetFacade():GetManager("UIManager")
                        local scene = uiMgr:GetCurrentScene()
                        local CommonTip  = require( 'common.NewCommonTip' ).new({text = __('您的等级太高了～需要继续下载完整的游戏包才能进行游戏～'),
                            isOnlyOK = true, isForced = true, callback = function ()
                                AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'HomeMediator'}, {name = 'ResourceDownloadMediator', params = {
                                    closeFunc = function (  )
                                        SwitchToHome()
                                    end
                                }})
                            end})
                        CommonTip:setPosition(display.center)
                        scene:AddDialog(CommonTip)
                    else
                        SwitchToHome()
                    end
                else
                    SwitchToHome()
                end
            else
                PlayAudioClip("stop_ty_8")
                local haveFight = cc.UserDefault:getInstance():getIntegerForKey(ENTERED_FIRST_P_BATTLE_KEY, 0)
                if haveFight == 1 then
                    --开场大战已播放过
                    self:StartVedioLogical(0)
                else
                    --播放开场pv
                    local filepath = string.format("conf/%s/quest/questStory.json",i18n.getLang())
                    local filepath = getRealConfigPath(filepath)
                    local name = stripextension(basename(filepath))
                    local content = getRealConfigData(filepath, name)
                    local t = json.decode(content)
                    local hasFight = 0 --是否存在开场大战
                    if t and next(t) ~= nil then
                        local data = t['1']
                        if data then
                            for name,val in pairs(data) do
                                if checkint(val.func) == 1 then
                                    hasFight = 1
                                    break
                                end
                            end
                        end
                    end
                    self:StartVedioLogical(hasFight)
                end
            end

        elseif event.event == 'progress' then
            loadingBar:setValue((event.progress / 100) * 100)
            local str = string.format('%.1f %%',(event.progress / 100) * 100)
            local percent = event.progress * 0.01
            loadingBarShine:setPositionX(
            loadingBar:getPositionX() - loadingBar:getContentSize().width * 0.5 +
            loadingBar:getContentSize().width * percent - 1)
        end
    end)

end

function AuthorMediator:StartVedioLogical(hasFight)
    --如果存开场大战，先播放视频然后再进入开场大战
    if isElexSdk() or isJapanSdk() then
        local AppSDK = require('root.AppSDK')
        AppSDK.GetInstance():AppFlyerEventTrack("VedioStart",{af_event_start = "VedioStart"})
    end
    local view = self:GetViewComponent()
    local function gotoFight()
        if hasFight == 1 then
            local battleConstructor = require('battle.controller.BattleConstructor').new()
            local fromToStruct      = BattleMediatorsConnectStruct.New('AuthorMediator', 'AuthorTransMediator')
            battleConstructor:InitDataByPerformanceStageId(8999, nil, fromToStruct)
            if not AppFacade.GetInstance():RetrieveMediator('EnterBattleMediator') then
                local enterBattleMediator = require('Game.mediator.EnterBattleMediator').new()
                AppFacade.GetInstance():RegistMediator(enterBattleMediator)
            end
            AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.Battle_Enter, battleConstructor)
        else
            --不存在开场大战直接去下一个对白逻辑
            AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = "AuthorMediator"}, {name = "AuthorTransMediator",params = {showVideo = false}})
        end
    end

    if (device.platform == 'ios' or device.platform == 'android') and checkint(SUBPACKAGE_LEVEL) == 0 and (not isNewUSSdk()) then
        local isLock = false
        local cView = CLayout:create(display.size)
        cView:setBackgroundColor(cc.c4b(0,0,0,255))
        display.commonUIParams(cView, {po = display.center})
        local videoPath = _res('res/eater_video.usm')
        local colorView = VideoNode:create()
        colorView:setContentSize(display.size)
        display.commonUIParams(colorView, {po = display.center})
        cView:addChild(colorView)
        view:addChild(cView, 400)

        --添加跳过按钮
        local skipButton = display.newButton(0, 0, {n = _res('arts/stage/ui/opera_btn_skip.png')})
        display.commonLabelParams(skipButton, {fontSize = 26, text = __("跳过"),color = "220404", offset= cc.p(45,0)})
        display.commonUIParams(skipButton, {po = cc.p(display.width - skipButton:getContentSize().width * 0.5 , display.height - 18 - 45),
                cb = function(sender)
                    sender:setEnabled(false)
                    if isLock == false then
                        isLock = true
                        cView:setVisible(false)
                        cView:runAction(cc.RemoveSelf:create())
                        --去大战
                        if isElexSdk() then
                            local AppSDK = require('root.AppSDK')
                            AppSDK.GetInstance():AppFlyerEventTrack("VedioSkip",{af_event_start = "VedioSkip"})
                        end
                        gotoFight()
                    end
                end})
        cView:addChild(skipButton,100)
        colorView:registScriptHandler(function(event)
            if checkint(event.status) == 6 then
                skipButton:setEnabled(false)
                if isLock == false then
                    isLock = true
                    cView:setVisible(false)
                    cView:runAction(cc.RemoveSelf:create())
                    gotoFight()
                end
            end
        end)
        colorView:PlayVideo(videoPath)
    else
        -- 非手机设备直接去开场大战页面
        gotoFight()
    end

end


function AuthorMediator:ProcessSignal( signal )
	local name = signal:GetName()
	local data = signal:GetBody()
    if SIGNALNAMES.Login_Callback == name then
        --- 清除 缓存数据 防止切换成未创建账号后 还残留 老账号的playerId的问题
        gameMgr:GetUserInfo().serverId = nil
        gameMgr:GetUserInfo().playerId = nil
		-- 如果是输入的登录 则保存一次帐号信息到本地
        --EVENTLOG.Log(EVENTLOG.EVENTS.login)
		local loginLayer = self:GetViewComponent():GetDialogByTag(1002)
		if loginLayer then
			local inputUName = loginLayer.viewData.nameBox:getText()
			local inputUPass = loginLayer.viewData.passBox:getText()
			if inputUPass and string.len(inputUPass) > 0 then
				local accountInfo = {uname = inputUName, password = inputUPass, isDefault = 1, isGuest = checkint(data.isGuest)}
				gameMgr:StoreAnAccountInfo(accountInfo)
			end
			self:GetViewComponent():RemoveDialogByTag(1002)
		end
		local userInfo = {isGuest = checkint(data.isGuest), sessionId = data.sessionId, userId = checkint(data.userId)}
		gameMgr:UpdateAuthorInfo(userInfo)
		self:GetViewComponent().viewData.unameLabel:setString(tostring(gameMgr:GetUserInfo().uname))

        if isFuntoySdk() then
            local parent = self:GetViewComponent().viewData.unameLabel:getParent()
            if parent then
                parent:setVisible(false)
            end
        end
		-- 判断账户下本服务器是否有角色 有角色则直接checkin 无角色则走创角
        local userInfo = {servers = checktable(data.servers), lastLoginServerId = checkint(data.lastLoginServerId)}
        if userInfo.lastLoginServerId > 0 then
            for _, serverData in pairs(userInfo.servers) do
                if serverData.id == userInfo.lastLoginServerId then
                    userInfo.serverId = serverData.id
                    userInfo.playerId = serverData.playerId
                    self:GetViewComponent():setServerName(serverData.name)
                    break
                end
            end
        else
            local serverData = checktable(userInfo.servers[1])
            userInfo.serverId = serverData.id
            userInfo.playerId = serverData.playerId
            self:GetViewComponent():setServerName(serverData.name)
        end
        if data.bindChannel then
            userInfo.bindChannel = data.bindChannel
        end
        gameMgr:UpdateAuthorInfo(userInfo)
        self:checkShowServer()
        self:ShowEnterGame() --有角色然后显示进入游戏的按钮
    elseif POST.ELEX_USER_BY_UDID.sglName == name then
        --获取到用户信息的逻辑
        local requestData = data.requestData or {}
        if requestData.udid2 then
            cc.UserDefault:getInstance():setStringForKey("UDID" , CCNative:getOpenUDID())
            cc.UserDefault:getInstance():flush()
        end
        EVENTLOG.Log(EVENTLOG.EVENTS.login)
        local loginLayer = self:GetViewComponent():GetDialogByTag(1002)
        if loginLayer then
            local inputUName = loginLayer.viewData.nameBox:getText()
            local inputUPass = loginLayer.viewData.passBox:getText()
            if inputUPass and string.len(inputUPass) > 0 then
                local accountInfo = {uname = inputUName, password = inputUPass, isDefault = 1, isGuest = checkint(data.isGuest)}
                gameMgr:StoreAnAccountInfo(accountInfo)
            end
            self:GetViewComponent():RemoveDialogByTag(1002)
        end
        local userInfo = {isGuest = checkint(data.isGuest), sessionId = data.sessionId, userId = checkint(data.userId)}
        gameMgr:UpdateAuthorInfo(userInfo)
        self:GetViewComponent().viewData.unameLabel:setString(tostring(gameMgr:GetUserInfo().uname))
        -- 判断是否为欧盟区
        if checkint(data.isInEuropean) > 0 then
            gameMgr:GetUserInfo().isEURegion =  checkint(data.isInEuropean)
            -- 判断是否需要勾选隐私协议
            if checkint(data.europeanStatus) == 0 then
                self.isShowPolicy = true
            end
        end
        -- 判断账户下本服务器是否有角色 有角色则直接checkin 无角色则走创角
        local userInfo = {servers = checktable(data.servers), lastLoginServerId = checkint(data.lastLoginServerId)}
        if userInfo.lastLoginServerId > 0 then
            for _, serverData in pairs(userInfo.servers) do
                if serverData.id == userInfo.lastLoginServerId then
                    userInfo.serverId = serverData.id
                    userInfo.playerId = serverData.playerId
                    self:GetViewComponent():setServerName(serverData.name)
                    break
                end
            end
        else
            local serverData = checktable(userInfo.servers[1])
            userInfo.serverId = serverData.id
            userInfo.playerId = serverData.playerId
            self:GetViewComponent():setServerName(serverData.name)
        end
        if data.openId then userInfo.userSdkId = openId end
        if data.bindChannels then
            userInfo.bindChannel = data.bindChannels
        end
        gameMgr:UpdateAuthorInfo(userInfo)

        self:checkShowServer()
        self:ShowEnterGame() --有角色然后显示进入游戏的按钮
        self:CheckIsCanAppoint(data)
        if isElexSdk() then
            if gameMgr:GetUserInfo().playerId == nil or checkint(gameMgr:GetUserInfo().playerId) <= 0 then
                local AppSDK = require('root.AppSDK')
                AppSDK.GetInstance():AppFlyerEventTrack("ShowStartGame",{af_event_start = "ShowStartGame"})
            end
        end
    elseif SIGNALNAMES.Channel_Login_Callback == name then
        --- 清除 缓存数据 防止切换成未创建账号后 还残留 老账号的playerId的问题
        gameMgr:GetUserInfo().serverId = nil
        gameMgr:GetUserInfo().playerId = nil
        -- 如果是输入的登录 则保存一次帐号信息到本地
        --EVENTLOG.Log(EVENTLOG.EVENTS.login)
        local userInfo = {isGuest = 0,sessionId = data.sessionId, userId = checkint(data.userId) ,idNo = data.idNo , guestDisable = data.guestDisable}
        gameMgr:UpdateAuthorInfo(userInfo)
        local AppSDK = require("root.AppSDK").GetInstance()
        if AppSDK.TrackSDKEvent then
            AppSDK:TrackSDKEvent("setConfigTTTackParam" , {
                useruniqueid = tostring(data.userId)
            })
            AppSDK:TrackSDKEvent("setSessionEnable" , {
                isEnable = 1
            })
            AppSDK:TrackSDKEvent("setCustomHeader" , {
                region = "cn"
            })
            --AppSDK:TrackSDKEvent("setIsInHouseVersion" , {
            --    IsInHouseVersion = 1
            --})
            --AppSDK:TrackSDKEvent("setDebugLogServerHost" , {
            --    serverHost = "10.2.201.7:10304"
            --})
            AppSDK:TrackSDKEvent("setAppIdAndChannelAndAppName" , {
                appId = "162717",
                channel = "App Store",
                appName = "jrttszqy01",
            })

            AppSDK:TrackSDKEvent("setCurrentUserUniqueID" , {
                isLogin = 1,
                useruniqueid =tostring(data.playerId) ,
            })
        end

        -- self:GetViewComponent().viewData.unameLabel:setString(tostring(gameMgr:GetUserInfo().uname))
        if isFuntoySdk() then
            local parent = self:GetViewComponent().viewData.unameLabel:getParent()
            if parent then
                parent:setVisible(false)
            end
        end
        if isQuickSdk() then
            local parent = self:GetViewComponent().viewData.unameLabel:getParent()
            if parent then
                parent:setVisible(false)
            end
        end
        -- 判断账户下本服务器是否有角色 有角色则直接checkin 无角色则走创角
        local userInfo = {servers = checktable(data.servers), lastLoginServerId = checkint(data.lastLoginServerId)}
        if checkint(userInfo.lastLoginServerId) > 0 then
            for _, serverData in pairs(userInfo.servers) do
                if checkint(serverData.id) == checkint(userInfo.lastLoginServerId) then
                    userInfo.serverId = serverData.id
                    userInfo.playerId = serverData.playerId
                    self:GetViewComponent():setServerName(serverData.name)
                    break
                end
            end
        else
            local serverData = checktable(userInfo.servers[1])
            userInfo.serverId = serverData.id
            userInfo.playerId = serverData.playerId
            self:GetViewComponent():setServerName(serverData.name)
        end
        gameMgr:UpdateAuthorInfo(userInfo)
        self:checkShowServer()
        self:ShowEnterGame() --有角色然后显示进入游戏的按钮
        self:CheckIsCanAppoint(data)

    elseif SIGNALNAMES.Checkin_Callback == name then
		-- checkin成功 处理用户背包等数据
        self.startTime = os.time()
        local buttons = self:GetViewComponent().viewData.actionButtons
        if i18n.supportLangs then
            self:GetViewComponent().viewData.langBtn:setVisible(false)
        end
        for name,val in pairs(buttons) do
            val:setVisible(false)
        end
        gameMgr:UpdatePlayer(data)
        gameMgr:fixLocalGuideData()
        if isQuickSdk() then
            --上传角色信息的逻辑
            local isFirst = false
            if data.requestData.isCreateRole then
                isFirst = (checkint(data.requestData.isCreateRole) == 1)
            end
            local AppSDK = require('root.AppSDK')
            AppSDK.GetInstance():AndroidRoleUpload({isFirst = isFirst}) --上传角色信息的逻辑
        elseif isEfunSdk() then
            local AppSDK = require('root.AppSDK')
            AppSDK.GetInstance():ShowFloatButton()
        end
        --播音乐
        PlayBGMusic()

        local function launchGame()
            AppFacade.GetInstance():StartGame()
            --显示进入游戏加载的进度的逻辑
            self:LoadingResources()
        end

        if 0 < checkint(SUBPACKAGE_LEVEL) and cc.UserDefault:getInstance():getBoolForKey('SubpackageRes_' .. tostring(FTUtils:getAppVersion()), false) == false then
            if checkint(gameMgr:GetUserInfo().level) < checkint(SUBPACKAGE_LEVEL) then
                local downloadText = __('游戏将处于体验模式，您在进行游戏的同时也会开启后台下载，直至完成游戏的扩展包下载。')
                local downloadTip  = require('common.NewCommonTip').new({isForced = true, text = downloadText, extra = __('建议：由于包体较大，请于wifi环境下载'),
                    callback = function()
                        uiMgr:showDownloaderSubRes()
                        launchGame()
                    end,
                    cancelBack = function()
                        launchGame()
                    end
                })
                downloadTip:setPosition(display.center)
                self:GetViewComponent():AddDialog(downloadTip)
            else
                local downloadTip = require('common.NewCommonTip').new({isOnlyOK = true, isForced = true, text = __('您的等级太高了～需要继续下载完整的游戏包才能进行游戏～'),
                    callback = function ()
                        local downloadNode = require('root.Downloader').new(nil, true)
                        downloadNode:setPosition(display.center)
                        self:GetViewComponent():AddDialog(downloadNode)
                        downloadNode:setAllDoneCallback(function()
                            downloadNode:removeFromParent()
                            launchGame()
                        end)
                    end
                })
                downloadTip:setPosition(display.center)
                self:GetViewComponent():AddDialog(downloadTip)
            end
        else
            launchGame()
        end

	elseif SIGNALNAMES.GetUserByUdid_Callback == name then
		-- 根据udid获取用户信息
		local accountAmount = table.nums(data.accounts)
		-- 写入本地帐号文件中
		gameMgr:StoreAccountInfos(data.accounts)
        if isElexSdk() then
            --游客登录信息的逻辑
            if accountAmount > 1 then
                local account = data.accounts[1]
                local userInfo = {uname = account.uname, upass = account.password, isGuest = checkint(account.isGuest)}
                gameMgr:UpdateAuthorInfo(userInfo)
            end
            self:GetFacade():RegistSignal(COMMANDS.COMMAND_Login, AuthorCommand)
            self:SendSignal(COMMANDS.COMMAND_Login, {uname = gameMgr:GetUserInfo().uname, password = gameMgr:GetUserInfo().upass})
        else
            if accountAmount > 1 then
                -- 返回多个帐号信息 让玩家自己输入帐号密码
                self:ShowLoginLayer()
            else
                -- 返回一个帐号 游客 直接走登录逻辑
                self:GetFacade():RegistSignal(COMMANDS.COMMAND_Login, AuthorCommand)
                self:SendSignal(COMMANDS.COMMAND_Login, {uname = gameMgr:GetUserInfo().uname, password = gameMgr:GetUserInfo().upass})
            end
        end
	elseif SIGNALNAMES.Regist_Callback == name then
		-- 注册成功 保存一次帐号
        gameMgr:UpdateAuthorInfo({playerId = 0})
		local registLayer = self:GetViewComponent():GetDialogByTag(1004)
		if registLayer then
			local inputUName = registLayer.viewData.nameBox:getText()
			local inputUPass = registLayer.viewData.passBox:getText()
			if inputUPass and string.len(inputUPass) > 0 then
				local accountInfo = {uname = inputUName, password = inputUPass, isDefault = 1, isGuest = checkint(data.isGuest)}
				gameMgr:StoreAnAccountInfo(accountInfo)
			end
			self:GetViewComponent():RemoveDialogByTag(1004)
			local userInfo = gameMgr:GetUserInfo()
			self:GetFacade():RegistSignal(COMMANDS.COMMAND_Login, AuthorCommand)
			self:SendSignal(COMMANDS.COMMAND_Login, {uname = userInfo.uname, password = userInfo.upass})
		end
	elseif SIGNALNAMES.CreateRole_Callback == name then
		-- 创角成功 走checkin
        --EVENTLOG.Log(EVENTLOG.EVENTS.createSuccessful)
        DotGameEvent.SendEvent(DotGameEvent.EVENTS.CREATE_ROLE)
		self:GetViewComponent().viewData.actionButtons[tostring(1007)]:setEnabled(false)
        gameMgr:UpdateAuthorInfo({playerId = data.playerId})
		local layer = self:GetViewComponent():GetDialogByTag(1010)
		if layer then
			self:GetViewComponent():RemoveDialogByTag(1010)
		end
        self:SendSignal(COMMANDS.COMMAND_Checkin, {isCreateRole = 1}) --是否是创角的请求
    elseif SIGNALNAMES.SERVER_APPOINT_Callback == name then
        if checkint(data.errcode) ~= 0 then
            self:GetViewComponent().viewData.actionButtons[tostring(1011)]:setVisible(false)
            return
        end

        data.requestData.openId = ssl_encrypt(tostring(data.requestData.openId))

        gameMgr:setAppoinitData(data)
        local isAppointment = checkint(data.isAppointment)
        self:GetViewComponent():UpdateAppointmentBtnState(isAppointment)
    elseif EVENT_SDK_LOGIN == name then
        --sdk登录成功的逻辑
        if isFuntoySdk() or isFuntoyExtraSdk() then
            self:SendSignal(COMMANDS.COMMAND_SDK_LOGIN,{authCode = gameMgr:GetUserInfo().accessToken, uid = gameMgr:GetUserInfo().userSdkId,
                loginTimestamp = data.loginTimestamp, loginSign = data.sign})
        elseif isEfunSdk() then
            self:SendSignal(COMMANDS.COMMAND_SDK_LOGIN,{authCode = gameMgr:GetUserInfo().accessToken, uid = gameMgr:GetUserInfo().userSdkId,
                loginTimestamp = data.loginTimestamp, loginSign = data.sign, facebookId = data.fbId})
        -- elseif isElexSdk() then
            -- self:SendSignal(COMMANDS.COMMAND_SDK_LOGIN,{authCode = gameMgr:GetUserInfo().accessToken, uid = gameMgr:GetUserInfo().userSdkId, loginWay = data.loginPlatform})
        else
            self:SendSignal(COMMANDS.COMMAND_SDK_LOGIN,{authCode = gameMgr:GetUserInfo().accessToken, uid = gameMgr:GetUserInfo().userSdkId})
        end
    elseif EVENT_SDK_LOGIN_CANCEL == name then
        local view = self:GetViewComponent()
        view.viewData.actionButtons[tostring(1002)]:setVisible(true)
    elseif 'EVENT_APPOINT_SHARE_RESULT' == name then
        if self.webView and not tolua.isnull(self.webView) then
            self.webView:evaluateJS('onShare(\'' .. json.encode(data or {}) .. '\')')
        end
        gameMgr:setIsDisableAppointShare(false)

    elseif DOWNLOAD_DEFINE.RES_JSON.event == name then
        if data.isDownloaded then
            app.uiMgr:removeVerifyInfoPopup()
            app.gameResMgr:setRemoteResJson(data.downloadData)
            self:launchGame()
        else
            -- 重新下载
            app.uiMgr:showVerifyInfoPopup({infoText = __('重新同步资源配置文件')})
            app.downloadMgr:addUrlTask(DOWNLOAD_DEFINE.RES_JSON.url, DOWNLOAD_DEFINE.RES_JSON.event)
        end
    elseif POST.USER_EUROPEAN_AGREEMENT.sglName  == name  then
        self:launchGame()
    elseif POST.USER_ACCOUNT_BIND_REAL_AUTH.sglName == name  then
        DotGameEvent.SendEvent(DotGameEvent.EVENTS.IDENTIFY)
        local rewards = data.rewards
        if rewards and table.nums(rewards) > 0 then
            uiMgr:AddDialog('common.RewardPopup',{ rewards = rewards})
        end
        gameMgr:SetIdNo(data.requestData.idNo)
        local mediator =   self:GetFacade():RetrieveMediator("RealNameAuthenicationMediator")
        -- 如果mediator存在 删除mediator
        if mediator then
            self:GetFacade():UnRegsitMediator("RealNameAuthenicationMediator")
        end
	end
end

function AuthorMediator:OnRegist()
    regPost(POST.ELEX_USER_BY_UDID)
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Checkin, AuthorCommand)
    self:GetFacade():RegistSignal(COMMANDS.COMMAND_SDK_LOGIN, AuthorCommand)
    regPost(POST.USER_EUROPEAN_AGREEMENT)
    self:GetFacade():RegistSignal(COMMANDS.COMMAND_SERVER_APPOINT, AuthorCommand)
	local view = uiMgr:SwitchToTargetScene('Game.views.AuthorView')
	self:SetViewComponent(view)
	self:InitialActions()
	self:InitialLogin()
end
function AuthorMediator:OnUnRegist()
    unregPost(POST.ELEX_USER_BY_UDID)
    self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Login)
    self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_GetUserByUdid)
    self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Regist)
    self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Checkin)
    self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_SDK_LOGIN)
    --self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_European_Agreement)
    unregPost(POST.USER_EUROPEAN_AGREEMENT)
    self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_SERVER_APPOINT)

    gameMgr:setIsDisableAppointShare(false)
end
---------------------------------------------------
-- mediator extend end --
---------------------------------------------------

--[[
注册按钮回调
--]]
function AuthorMediator:InitialActions()
	local view = self:GetViewComponent()
	for k,btn in pairs(view.viewData.actionButtons) do
		display.commonUIParams(btn, {cb = handler(self, self.ButtonActions)})
	end
end

--[[
--elex平台的登录facebook
--]]
function AuthorMediator:ElexFacebookGoogle()
    local buttons = self:GetViewComponent().viewData.actionButtons
    for name,val in pairs(buttons) do
        val:setVisible(false)
    end
    local view = self:GetViewComponent()
    local loginView = CLayout:create(display.size)
    display.commonUIParams(loginView, {po = display.center, ap = display.CENTER})
    loginView:setName("LOGIN_VIEW")
    view:addChild(loginView, 200)

    local googleName = _res('update/button_google')
    local disableName = _res('update/button.google_disabled')
    if device.platform == 'ios' then
        googleName = _res('update/button_gamecenter')
        disableName = _res('update/button_gamecenter_disabled')
    end
    local googleButton = display.newButton(display.cx - 132, 100, {
            n = googleName,d = disableName
        })
    googleButton:setOnClickScriptHandler(handler(self, self.ElexSDKLoginButtonAction))
    googleButton:setName("GOOGLE")
    loginView:addChild(googleButton)
    local facebookButton = display.newButton(display.cx + 132, 100, {
            n = _res('update/button_facebook'),
            d = _res('update/button_facebook_disabled'),
        })
    facebookButton:setOnClickScriptHandler(handler(self, self.ElexSDKLoginButtonAction))
    facebookButton:setName("FACEBOOK")
    loginView:addChild(facebookButton)
end


function AuthorMediator:ElexSDKLoginButtonAction(sender)
    PlayAudioByClickNormal()
    local name = sender:getName()
    if isElexSdk() then
        local AppSDK = require('root.AppSDK')
        AppSDK.GetInstance():InvokeLogin({name = name})
    end
end
--[[
注册逻辑
--]]
function AuthorMediator:InitialLogin()
	-- cc.UserDefault:getInstance():setStringForKey(STORE_ACCOUNT_KEY, '')
    -- cc.UserDefault:getInstance():flush()
	-- 读取本地保存的账户信息
	gameMgr:InitialUserInfo()
	gameMgr:CheckLocalPlayer()
	local userInfo = gameMgr:GetUserInfo()
    if platformId == KuaiKan then
        --如何判断是否是切换账号的来着有playerId
        if checkint(gameMgr:GetUserInfo().userId) > 0 then
            --这个是登录账号
            local AppSDK = require('root.AppSDK')
            AppSDK.GetInstance():InvokeSwitch()
        else
            --这个是切换账号
            local AppSDK = require('root.AppSDK')
            AppSDK.GetInstance():InvokeLogin()
        end

    else
        --开始启用sdk的登录
        if isFuntoySdk() then
            --这个sdk登录
            local AppSDK = require('root.AppSDK')
            AppSDK.GetInstance():InvokeLogin()
        elseif isEfunSdk() then
            local AppSDK = require('root.AppSDK')
            AppSDK.GetInstance():InvokeLogin()
        elseif isElexSdk() and (not isNewUSSdk()) then
            --创建google与facebook的登录逻辑
            local view = self:GetViewComponent()
            view.viewData.actionButtons[tostring(1002)]:setVisible(false)
            if device.platform == "ios" then
                local udid2 = cc.UserDefault:getInstance():getStringForKey("UDID" , "")
                local udid =  CCNative:getOpenUDID()
                if string.len(udid2) == 0 then
                    cc.UserDefault:getInstance():setStringForKey("UDID" , CCNative:getOpenUDID())
                    cc.UserDefault:getInstance():flush()
                    udid2 = cc.UserDefault:getInstance():getStringForKey("UDID" , "")
                end
                if udid ~= udid2 then
                    self:SendSignal(POST.ELEX_USER_BY_UDID.cmdName , { udid2 = udid2 })
                else
                    self:SendSignal(POST.ELEX_USER_BY_UDID.cmdName  )
                end
            else
                self:SendSignal(POST.ELEX_USER_BY_UDID.cmdName )
            end
        elseif isNewUSSdk() then
            local view = self:GetViewComponent()
            view.viewData.actionButtons[tostring(1002)]:setVisible(false)
            self:SendSignal(POST.ELEX_USER_BY_UDID.cmdName)
        else
            local view = self:GetViewComponent()
            view.viewData.actionButtons[tostring(1002)]:setVisible(false)
            self:SendSignal(POST.ELEX_USER_BY_UDID.cmdName)
        end
    end
end
--[[
按钮事件
1001 checkin就绪 进入游戏主界面
1002 调出登录界面帐号管理按钮 切换帐号 注册登录
1003 登录操作
1004 调出注册界面
1005 注册新帐号
1006 创建新角色
1007 没有角色 进入游戏创角
1011 预约按钮
10020 关闭登录界面
10040 关闭注册界面 调出注册界面
10100 关闭创角界面
--]]
function AuthorMediator:ButtonActions(sender)
	local tag = sender:getTag()
    if 1001 == tag then
        local function enterGame()
            -- 是否完成协议认证
            if self.isShowPolicy then
                sender:setEnabled(false)
                transition.execute(sender, nil, {delay = 2, complete = function()
                    sender:setEnabled(true)
                end})
                self:SendSignal(POST.USER_EUROPEAN_AGREEMENT.cmdName, {userId = gameMgr:GetUserInfo().userId, isAgree = 1})
            else
                if DYNAMIC_LOAD_MODE then
                    app.uiMgr:showVerifyInfoPopup({infoText = __('正在同步资源配置文件')})
                    app.downloadMgr:addUrlTask(DOWNLOAD_DEFINE.RES_JSON.url, DOWNLOAD_DEFINE.RES_JSON.event)
                else
                    self:launchGame()
                end
            end
        end
        if self.isShowPolicy then
            local PrivacyPolicyView = require( 'Game.views.PrivacyPolicyView' ).new({isRevoked = false, callback = enterGame})
            PrivacyPolicyView:setPosition(display.center)
            self:GetViewComponent():AddDialog(PrivacyPolicyView)
        else
            enterGame()
        end

	elseif 1002 == tag then
		self:ShowLoginLayer()
	elseif 1003 == tag then
		local loginLayer = self:GetViewComponent():GetDialogByTag(1002)
		if loginLayer then
			local uname = loginLayer.viewData.nameBox:getText()
			local upass = loginLayer.viewData.passBox:getText()
			-- 查错
			if nil == uname or string.len(string.gsub(uname, " ", "")) <= 0 then
                uiMgr:ShowInformationTips(__('登录用户名不能为空'))
				return
			end
			if nil == upass or string.len(string.gsub(upass, " ", "")) <= 0 then
                uiMgr:ShowInformationTips(__('登录密码不能为空'))
				return
			end
			local userInfo = {uname = uname, password = upass}
			self:GetFacade():RegistSignal(COMMANDS.COMMAND_Login, AuthorCommand)
			self:SendSignal(COMMANDS.COMMAND_Login, userInfo)
		end
	elseif 1004 == tag then
		self:ShowRegistLayer()
	elseif 1005 == tag then
		local registLayer = self:GetViewComponent():GetDialogByTag(1004)
		if registLayer then
			local uname = registLayer.viewData.nameBox:getText()
			local upass = registLayer.viewData.passBox:getText()
			local umail = registLayer.viewData.mailBox:getText()
			-- 查错
			if nil == uname or string.len(string.gsub(uname, " ", "")) <= 0 then
                uiMgr:ShowInformationTips(__('注册用户名不能为空'))
				return
			end
			if nil == upass or string.len(string.gsub(upass, " ", "")) <= 0 then
                uiMgr:ShowInformationTips(__('注册密码不能为空'))
				return
			end
			if nil == umail or string.len(string.gsub(umail, " ", "")) <= 0 then
                uiMgr:ShowInformationTips(__('注册邮箱不能为空'))
				return
			end
            local inviteCode = nil
			local data = {uname = uname, password = upass, email = umail, userId = '0'}
            if SS_SHOW_INVITECODE then
                inviteCode = registLayer.viewData.inviteCodeBox:getText()
                if (not inviteCode) or string.len(string.gsub(inviteCode, " ", "")) <= 0 then
                    uiMgr:ShowInformationTips(__('激活码不能为空'))
                    return
                end
                data.inviteCode = inviteCode
            end
			self:GetFacade():RegistSignal(COMMANDS.COMMAND_Regist, AuthorCommand)
			self:SendSignal(COMMANDS.COMMAND_Regist, data)
		end
	elseif 1006 == tag then
        --EVENTLOG.Log(EVENTLOG.EVENTS.create)
		local layer = self:GetViewComponent():GetDialogByTag(1010)
		if layer then
			local playerName = layer.viewData.playerNameBox:getText()
            local inviteCode = nil
			-- 查错
			if nil == playerName or string.len(string.gsub(playerName, " ", "")) <= 0 then
                uiMgr:ShowInformationTips(__('角色名非法'))
				return
			elseif string.len(playerName) > 21 then
				uiMgr:ShowInformationTips(__('角色名过长'))
				return
			end
            if layer.viewData.inviteCode then
                inviteCode = layer.viewData.inviteCode:getText()
                if nil == inviteCode or string.len(string.gsub(inviteCode, " ", "")) <= 0 then
                    uiMgr:ShowInformationTips(__('邀请码不能为空'))
                    return
                end
            end

			local data = {playerName = playerName}
            if inviteCode ~= nil then
                data = {playerName = playerName, inviteCode = inviteCode}
            end
			self:GetFacade():RegistSignal(COMMANDS.COMMAND_CreateRole, AuthorCommand)
			self:SendSignal(COMMANDS.COMMAND_CreateRole, data)
		end
	elseif 1007 == tag then
        self:ShowCreateRoleLayer()
    elseif 1008 == tag then
        local loginServerArgs = {
            lastLoginId     = gameMgr:GetUserInfo().lastLoginServerId,
            serverId        = gameMgr:GetUserInfo().serverId,
            servers         = gameMgr:GetUserInfo().servers,
            confirmServerCB = function(serverData)
                if serverData then
                    gameMgr:GetUserInfo().serverId = checkint(serverData.id)
                    gameMgr:GetUserInfo().playerId = serverData.playerId
                    local viewComponent = self:GetViewComponent()
                    if viewComponent  and (not tolua.isnull(viewComponent))
                    and viewComponent.setServerName  then
                        viewComponent:setServerName(serverData.name)
                    end
                end
            end
        }
        if IS_CHINA_GRAY_MODE then
            app.uiMgr:ShowInformationTips('4月4日0时至24时让我们用沉默哀悼烈士的逝去，\n用心铭记抗疫前线的同胞为此付出的一切。')
        else
            local loginServerMediator = require('Game.mediator.LoginServerMediator').new(loginServerArgs)
            AppFacade.GetInstance():RegistMediator(loginServerMediator)
        end
    elseif 1011 == tag then
        if device.platform == 'ios' or device.platform == 'android' then
            local function createH5View( originalURL )
                if device.platform == 'ios' or device.platform == 'android' then
                    local view = CLayout:create(display.size)
                    view:setPosition(cc.p(display.cx, display.cy))
                    view:setBackgroundColor(cc.c4b(255,255,255,255))
                    self:GetViewComponent():addChild(view, 300)

                    local _webView = ccexp.WebView:create()
                    _webView:setAnchorPoint(cc.p(0.5, 0.5))
                    local pos = view:convertToNodeSpace(cc.p(display.cx, display.cy))
                    _webView:setPosition(pos)
                    _webView:setContentSize(cc.size(display.width, display.height))
                    _webView:setScalesPageToFit(true)
                    _webView:setOnShouldStartLoading(handler(self, self.HandleH5Request))
                    view:addChild(_webView)
                    _webView:loadURL(originalURL)
                    self.webView = _webView
                end
            end
            local url = string.format('http://notice-%s/appointment/index.html?host=%s', Platform.serverHost, Platform.serverHost)
            createH5View(url)
        end

	elseif 10020 == tag then
		local loginLayer = self:GetViewComponent():GetDialogByTag(1002)
		if loginLayer then
			self:GetViewComponent():RemoveDialogByTag(1002)
		end
	elseif 10040 == tag then
		local registLayer = self:GetViewComponent():GetDialogByTag(1004)
		if registLayer then
			self:GetViewComponent():RemoveDialogByTag(1004)
		end
		self:ShowLoginLayer()
	elseif 10100 == tag then
		local layer = self:GetViewComponent():GetDialogByTag(1010)
		if layer then
			self:GetViewComponent():RemoveDialogByTag(1010)
		end
    elseif tag == 20002 then
        --fix version
        local f = cc.FileUtils:getInstance()
        require "lfs"
        local function rmdir(path)
            if f:isFileExist(path) then
                local function _rmdir(path)
                    local iter, dir_obj = lfs.dir(path)
                    while true do
                        local dir = iter(dir_obj)
                        if dir == nil then break end
                        if dir ~= "." and dir ~= ".." then
                            local curDir = path..dir
                            local mode = lfs.attributes(curDir, "mode")
                            if mode == "directory" then
                                _rmdir(curDir.."/")
                            elseif mode == "file" then
                                os.remove(curDir)
                            end
                        end
                    end
                    local succ, des = os.remove(path)
                    if des then print(des) end
                    return succ
                end
                _rmdir(path)
            end
            return true
        end

        local res_root = f:getWritablePath()
        local scene = uiMgr:GetCurrentScene()
        local CommonTip  = require( 'common.NewCommonTip' ).new({text = __('是否删除本地所有资源文件，并重新下载完整数据包!!!'),
                isOnlyOK = false, callback = function ()
                    
                    if isUseObbDownload() then
                        cc.UserDefault:getInstance():setBoolForKey('AndroidUpgrade' .. tostring(FTUtils:getAppVersion()), false)
                    end

                    if rmdir(res_root .. "res/") then
                        if rmdir(res_root .. "publish/") then
                            app.audioMgr:stopAndClean()
                            uiMgr:PopAllScene()
                            sceneWorld:getEventDispatcher():dispatchEvent(cc.EventCustom:new('APP_EXIT'))
                        end
                    end
                end})
        CommonTip:setPosition(display.center)
        scene:AddDialog(CommonTip)
        -- cc.Director:getInstance():endToLua()
        -- os.exit()

	end
end

function AuthorMediator:launchGame()
    --是否长连接成功后再进入游戏
    local hasReal = 1
    if isFuntoySdk() or isFuntoyExtraSdk() then
        --查询是否是实名认证
        if checkint(gameMgr:GetUserInfo().has_realauth) == 0 then
            hasReal = 0
        end
    end
    if hasReal == 0 then
        local mediator = require("Game.mediator.RealNameAuthenicationMediator").new({regist = true})
        self:GetFacade():RegistMediator(mediator)
    else
        if gameMgr:GetUserInfo().playerId ~= nil and checkint(gameMgr:GetUserInfo().playerId) > 0 then
            local playerId = checkint(gameMgr:GetUserInfo().playerId)
            self:SendSignal(COMMANDS.COMMAND_Checkin, {isCreateRole = 0})--先发送请checkin的请求完成后再进入游戏
            gameMgr:UpdatePlayer({playerId = playerId})
        else
            --直接添加一个剧情展示页面
            if isElexSdk() then
                local AppSDK = require('root.AppSDK')
                AppSDK.GetInstance():AppFlyerEventTrack("ClickStartGame",{af_event_start = "ClickStartGame"})
            end
            local buttons = self:GetViewComponent().viewData.actionButtons
            for name,val in pairs(buttons) do
                val:setVisible(false)
            end
            self:LoadingResources()
        end
    end
end

--[[
显示进入游戏界面
--]]
function AuthorMediator:ShowEnterGame()
	local view = self:GetViewComponent()
	view.viewData.actionButtons[tostring(1001)]:setVisible(true)
    view.viewData.actionButtons[tostring(1007)]:setVisible(false)
    if isElexSdk() then
        --不显示登录按钮组
        local loginView = view:getChildByName("LOGIN_VIEW")
        if loginView then loginView:setVisible(false) end
        view.viewData.actionButtons[tostring(1002)]:setVisible(false)
    end
    local faqBtn = view:getChildByTag(BUTTON_TAG.FAQ_TAG)
    if faqBtn and (not tolua.isnull(faqBtn)) then
        faqBtn:setVisible(true)
        display.commonUIParams(faqBtn ,{ cb = handler(self, self.FAQBtnCallBack) })
    end
    
end
function AuthorMediator:checkShowServer()
    local serversData = checktable(gameMgr:GetUserInfo().servers)
    local view = self:GetViewComponent()
    view.viewData.actionButtons[tostring(1008)]:setVisible(table.nums(serversData) > 1)
end
--==============================--
---@Description: TODO
---@param :
---@return :
---@author : xingweihao
---@date : 2018/9/30 4:15 PM
--==============================--
function AuthorMediator:FAQBtnCallBack()
    if device.platform == 'android' and FTUtils:getTargetAPIVersion() >= 16 then
        local AppSDK = require('root.AppSDK')
        AppSDK:AIHelper({isshowFAQs = true})
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
--[[
显示登录界面
--]]
function AuthorMediator:ShowLoginLayer()
    if isFuntoySdk() then
        --这个sdk登录
        local AppSDK = require('root.AppSDK')
        AppSDK.GetInstance():InvokeLogin()
    elseif isEfunSdk() then
        local AppSDK = require('root.AppSDK')
        AppSDK.GetInstance():InvokeLogin()
    else
        if isQuickSdk() then
            local AppSDK = require('root.AppSDK')
            AppSDK.GetInstance():QuickLogin()
        elseif platformId == BestvAndroid then
            local AppSDK = require('root.AppSDK')
            AppSDK.GetInstance():InvokeLogin()
        else
            local layer = require('Game.views.LoginLayer').new()
            display.commonUIParams(layer, {ap = cc.p(0, 0), po = cc.p(0, 0)})
            self:GetViewComponent():AddDialog(layer)
            layer:setTag(1002)
            for k,btn in pairs(layer.viewData.actionButtons) do
                display.commonUIParams(btn, {cb = handler(self, self.ButtonActions)})
            end
        end
    end
end

--[[
显示注册界面
--]]
function AuthorMediator:ShowRegistLayer()
	local loginLayer = self:GetViewComponent():GetDialogByTag(1002)
	if loginLayer then
		self:GetViewComponent():RemoveDialogByTag(1002)
	end
	local layer = require('Game.views.RegistLayer').new()
	display.commonUIParams(layer, {ap = cc.p(0, 0), po = cc.p(0, 0)})
	self:GetViewComponent():AddDialog(layer)
	layer:setTag(1004)
	for k,btn in pairs(layer.viewData.actionButtons) do
		display.commonUIParams(btn, {cb = handler(self, self.ButtonActions)})
	end
end

--[[
显示创角界面
--]]
function AuthorMediator:ShowCreateRoleLayer()
	local layer = require('Game.views.CreateRoleLayer').new()
	display.commonUIParams(layer, {ap = cc.p(0, 0), po = cc.p(0, 0)})
	self:GetViewComponent():AddDialog(layer)
	layer:setTag(1010)
	for k,btn in pairs(layer.viewData.actionButtons) do
		display.commonUIParams(btn, {cb = handler(self, self.ButtonActions)})
	end
end

--[[
进入游戏 走创角
--]]
function AuthorMediator:ShowEnterGameAndCreateRole()
	local view = self:GetViewComponent()
	view.viewData.actionButtons[tostring(1001)]:setVisible(false)
	view.viewData.actionButtons[tostring(1007)]:setVisible(true)
end
--[[
条款是否完全同意
--]]
function AuthorMediator:IsAgreedPolicy()
    local view = self:GetViewComponent()
    local policyChecked = view.viewData.policyCheckBox:isChecked()
    local ageChecked = view.viewData.ageCheckBox:isChecked()
    local isAgreed = policyChecked and ageChecked
    return isAgreed
end

--[[
检查是否预约
--]]
function AuthorMediator:CheckIsCanAppoint(data)
    local isBanUpdate = (not (device.platform == 'ios' or device.platform == 'android'))
    if isBanUpdate then return end

    local newAppointment      = data.newAppointment or {}
    local isAppointmentOpen   = checkint(newAppointment.isAppointmentOpen) > 0

    if isAppointmentOpen then
        local view = self:GetViewComponent()
        view:CreateAppointLayer()

        display.commonUIParams(view.viewData.actionButtons[tostring(1011)], {cb = handler(self, self.ButtonActions)})
        view.viewData.actionButtons[tostring(1011)]:setVisible(isAppointmentOpen)

        local appointmentServerId = checkint(newAppointment.serverId)

        if self:CheckAppointmentIsOpen(appointmentServerId, data.servers) then
            view:UpdateAppointmentBtnState(2)
        else
            self:RequestServerAppoint()
        end
    end
end

--[[
检查新服是否开启
--]]
function AuthorMediator:CheckAppointmentIsOpen(serverId, servers)
    servers = servers or {}
    for _, serverData in pairs(servers) do
        if checkint(serverData.id) == serverId then
            return true
        end
    end
    return false
end

function AuthorMediator:RequestServerAppoint()
    local openId = gameMgr:GetUserInfo().userSdkId
    self:SendSignal(COMMANDS.COMMAND_SERVER_APPOINT, {openId = openId})
end

function AuthorMediator:HandleH5Request( webview, url )
    local scheme = 'liuzhipeng'
	local urlInfo = string.split(url, '://')
	if 2 == table.nums(urlInfo) then
		if urlInfo[1] == scheme then
			local urlParams = string.split(urlInfo[2], '&')
			local params = {}
			for k,v in pairs(urlParams) do
				local param = string.split(v, '=')
				-- 构造表单做get请求 所以结尾多一个？
                -- params[param[1]] = string.split(param[2], '?')[1]
                -- 构造表单做get请求（win上面的ie浏览器结尾多一个/，其他浏览器或其他平台尾多一个？，所以不能用上面的）
                local lastChar = string.sub(param[2], string.len(param[2]))
                if lastChar == '/' or lastChar == '?' then
                    params[param[1]] = string.sub(param[2], 0, string.len(param[2]) - 1)
                else
                    params[param[1]] = param[2]
                end
            end
			if params.action then
                if 'close' == params.action then
                    local parent = webview:getParent()
                    if parent and not tolua.isnull(parent) then parent:runAction(cc.RemoveSelf:create()) end
                    self.webView = nil
                    self:RequestServerAppoint()
				elseif 'reload' == params.action then
                    webview:reload()
                elseif 'reservationInfo' == params.action then
                    webview:evaluateJS('onReservationInfo(\'' .. json.encode(gameMgr:getAppoinitData()) .. '\')')
                elseif 'share' == params.action then

                    if gameMgr:getIsDisableAppointShare() then
                        return false
                    end
                    gameMgr:setIsDisableAppointShare(true)
                    local platformType = checkint(params.platformType)

                    local shareNodeLayer = self:GetViewComponent().viewData.shareNodeLayer
                    if shareNodeLayer then
                        shareNodeLayer:setVisible(true)
                        cc.utils:captureNode(function(isOk, path)
                            shareNodeLayer:setVisible(false)
                            if device.platform == 'ios' or device.platform == 'android' then
                                local AppSDK = require('root.AppSDK')
                                AppSDK.GetInstance():InvokeShare(platformType, {image = path, title = '首款美食拟人&冒险经营手游#食之契约#炎炎夏日，吃货节降至，7.6官方新服“帕拉塔”即将开启！大家快来一起狂欢吧！', text = '首款美食拟人&冒险经营手游#食之契约#炎炎夏日，吃货节降至，7.6官方新服“帕拉塔”即将开启！大家快来一起狂欢吧！', type = CONTENT_TYPE.C2DXContentTypeImage})
                            else
                                AppFacade.GetInstance():DispatchObservers('SHARE_REQUEST_RESPONSE')
                            end
                        end, 'shareNodeImage.jpg', shareNodeLayer, 0.5)
                    end

				else
					return true
				end
			end
			return false
		end
	end
	return true
end


return AuthorMediator

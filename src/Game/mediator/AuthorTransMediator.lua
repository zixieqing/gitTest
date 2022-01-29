--[[
登录注册mediator
--]]
local Mediator = mvc.Mediator
local AuthorTransMediator = class("AuthorTransMediator", Mediator)
local NAME = "AuthorTransMediator"
local AuthorCommand = require('Game.command.AuthorCommand')

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
---------------------------------------------------
-- mediator extend begin --
---------------------------------------------------
function AuthorTransMediator:ctor( viewComponent )
	self.super:ctor(NAME, viewComponent)
    self.startTime = os.time()
    self.showVideo = false
    if viewComponent and viewComponent.showVideo ~= nil then
        self.showVideo = checkbool(viewComponent.showVideo)
    end
end

function AuthorTransMediator:InterestSignals()
	local signals = {
		SIGNALNAMES.Checkin_Callback,
        POST.USER_ACCOUNT_BIND_REAL_AUTH.sglName,
        "DirectorSuccess",
	}
	return signals
end

function AuthorTransMediator:Initial( key )
	self.super.Initial(self,key)
    self.isloaded = false
end

function AuthorTransMediator:ProcessSignal( signal )
	local name = signal:GetName()
	local data = signal:GetBody()
	if SIGNALNAMES.Checkin_Callback == name then
		-- checkin成功 处理用户背包等数据
        self.startTime = os.time()
        local buttons = self:GetViewComponent().viewData.actionButtons
        for name,val in pairs(buttons) do
            val:setVisible(false)
        end
		gameMgr:UpdatePlayer(data)
		gameMgr:fixLocalGuideData()
        if isQuickSdk() then
            --上传角色信息的逻辑
            local AppSDK = require('root.AppSDK')
            AppSDK.GetInstance():AndroidRoleUpload({isFirst = true}) --上传角色信息的逻辑
		elseif isEfunSdk() then
			local AppSDK = require('root.AppSDK')
			AppSDK.GetInstance():ShowFloatButton()
        end
        if checkint(Platform.id) == XipuAndroid or checkint(Platform.id) == YSSDKChannel then
            --喜扑的功能
            local AppSDK = require('root.AppSDK')
            AppSDK.GetInstance():AndroidRoleUpload({type = 'create'}) --上传角色信息的逻辑
        end

        local AppSDK =  require('root.AppSDK').GetInstance()
        if AppSDK.NetSdk then
            AppSDK:NetSdk()
        end

        require('root.AppSDK').GetInstance():NetSdk()
        --播音乐
        PlayBGMusic()

        local function launchGame()
            AppFacade.GetInstance():StartGame()
            --显示进入游戏加载的进度的逻辑
            self:StartGame()
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

    elseif POST.USER_ACCOUNT_BIND_REAL_AUTH.sglName == name then
        local userInfo = gameMgr:GetUserInfo()
        userInfo.is_guest = 0
        userInfo.has_realauth = 1
        local mediator =   self:GetFacade():RetrieveMediator("RealNameAuthenicationMediator")
        -- 如果mediator存在 删除mediator
        if mediator then
            self:GetFacade():UnRegsitMediator("RealNameAuthenicationMediator")
        end
    elseif name == 'DirectorSuccess' then
        --剧情结束的事件
        if isElexSdk() then
            local AppSDK = require('root.AppSDK')
            AppSDK.GetInstance():AppFlyerEventTrack("af_initiated_checkout",{af_event_start = "LoadEndd"})
        end
		self:SendSignal(COMMANDS.COMMAND_Checkin)--先发送请checkin的请求完成后再进入游戏
    end
end


function AuthorTransMediator:StartGame()
    local key = string.format('%s_ModulePanelIsOpen', tostring(gameMgr:GetUserInfo().playerId))
    cc.UserDefault:getInstance():setBoolForKey(key, false)
    cc.UserDefault:getInstance():flush()
    local HomeMediator = require( 'Game.mediator.HomeMediator')
    local mediator = HomeMediator.new()
    AppFacade.GetInstance():RegistMediator(mediator)
    local deltaTime = os.time() - self.startTime
    if isElexSdk() then
        local AppSDK = require('root.AppSDK')
        AppSDK.GetInstance():AppFlyerEventTrack("af_tutorial_completion",{af_event_start = "GuideStart"})
    end
    EVENTLOG.Log(EVENTLOG.EVENTS.checkin, {seconds = deltaTime, serverId = checkint(gameMgr:GetUserInfo().serverId)})
    --聊天长连接
    local chatSocketManager = AppFacade.GetInstance():GetManager("ChatSocketManager")
    chatSocketManager:Connect(Platform.ChatTCPHost,Platform.ChatTCPPort)
end

function AuthorTransMediator:OnRegist()
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Checkin, AuthorCommand)
	local view = uiMgr:SwitchToTargetScene('Game.views.AuthorTransView',{trans = true})
	self:SetViewComponent(view)
	self:InitialActions()
end

function AuthorTransMediator:OnUnRegist()
    self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Checkin)
end
---------------------------------------------------
-- mediator extend end --
---------------------------------------------------

--[[
注册按钮回调
--]]
function AuthorTransMediator:InitialActions()
	local view = self:GetViewComponent()
	for k,btn in pairs(view.viewData.actionButtons) do
        if checkint(k) == 1002 or checkint(k) == 1007 then
            btn:setVisible(false)
        else
            display.commonUIParams(btn, {cb = handler(self, self.ButtonActions)})
        end
	end
    --elex appsflyer loading
    if isElexSdk() then
        local AppSDK = require('root.AppSDK')
        AppSDK.GetInstance():AppFlyerEventTrack("af_initiated_checkout",{af_event_start = "LoadingStart"})
    end
    --直接添加一个剧情展示页面
    --[[ local haveFight = cc.UserDefault:getInstance():getIntegerForKey(ENTERED_FIRST_P_BATTLE_KEY, 0) ]]
    -- if haveFight == 1 and self.showVideo == true then
        -- if device.platform == 'ios' or device.platform == 'android' then
            -- -- if checkint(Platform.id) ~= 2005 and checkint(Platform.id) ~= 2006 then
            -- local cView = CLayout:create(display.size)
            -- cView:setBackgroundColor(cc.c4b(0,0,0,255))
            -- display.commonUIParams(cView, {po = display.center})
            -- local videoPath = _res('res/eater_video.usm')
            -- local colorView = VideoNode:create()
            -- colorView:setContentSize(display.size)
            -- colorView:registScriptHandler(function(event)
                -- if checkint(event.status) == 6 then
                    -- cView:setVisible(false)
                    -- cView:runAction(cc.RemoveSelf:create())
                    -- local operaStage = require( "Frame.Opera.OperaStage" ).new({id = 2, isHideBackBtn = true, isHideSkipBtn = true})
                    -- display.commonUIParams(operaStage, {po = display.center})
                    -- view:addChild(operaStage, 200)
                -- end
            -- end)
            -- display.commonUIParams(colorView, {po = display.center})
            -- cView:addChild(colorView)
            -- view:addChild(cView, 300)
            -- colorView:PlayVideo(videoPath)
            -- -- else
            -- --beta平台
            -- -- local operaStage = require( "Frame.Opera.OperaStage" ).new({id = 2, isHideBackBtn = true, isHideSkipBtn = true})
            -- -- display.commonUIParams(operaStage, {po = display.center})
            -- -- view:addChild(operaStage, 200)
            -- -- end
        -- else
            -- local operaStage = require( "Frame.Opera.OperaStage" ).new({id = 2, isHideBackBtn = true, isHideSkipBtn = true})
            -- display.commonUIParams(operaStage, {po = display.center})
            -- view:addChild(operaStage, 200)
        -- end
    -- else
    if isElexSdk() then
        local AppSDK = require('root.AppSDK')
        AppSDK.GetInstance():AppFlyerEventTrack("DialogOperaStart",{af_event_start = "DialogOperaStart"})
    end
    local operaArgs = {id = 2, isHideBackBtn = true, customSkip = true}
    if isJapanSdk() then
        operaArgs = {id = 2, isHideBackBtn = true}
    end
    if GAME_MODULE_OPEN.NEW_PLOT then
        local storyPath = string.format('conf/%s/plot/story0.json', i18n.getLang())
        operaArgs = {path = storyPath, id = 1, isHideBackBtn = true, customSkip = true}
    end
    local operaStage = require( "Frame.Opera.OperaStage" ).new(operaArgs)
    display.commonUIParams(operaStage, {po = display.center})
    view:addChild(operaStage, 200)
    -- end
end

--[[
显示进入游戏界面
--]]
function AuthorTransMediator:ShowEnterGame()
	local view = self:GetViewComponent()
	view.viewData.actionButtons[tostring(1001)]:setVisible(true)
	view.viewData.actionButtons[tostring(1007)]:setVisible(false)
	view.viewData.actionButtons[tostring(1002)]:setVisible(false)
end

return AuthorTransMediator

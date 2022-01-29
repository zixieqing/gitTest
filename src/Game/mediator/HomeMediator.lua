--[[
主界面场景mediator
--]]
local HomeMediator = class('HomeMediator', mvc.Mediator)

function HomeMediator:ctor(params, viewComponent)
	self.super.ctor(self, 'HomeMediator', viewComponent)
	self.ctorArgs_ = checktable(params)
end


-------------------------------------------------
-- inheritance method

function HomeMediator:Initial(key)
	self.super.Initial(self, key)
	self:setControllable(false)
	GuideUtils.GetDirector():Start()

	-- parse ctor args
	self.isShowHandbook_ = self.ctorArgs_.showHandbook == true
	self.isShowFriendPK_ = self.ctorArgs_.showFriendBattle == true

	-- check hide homeFunc
	local gameManager  = AppFacade.GetInstance():GetManager('GameManager')
	local playerLevel  = checkint(gameManager:GetUserInfo().level)
	local hideFuncList = gameManager:checkOpenHomeModuleList(playerLevel)
	local appMediator  = AppFacade.GetInstance():RetrieveMediator('AppMediator')
	table.insertto(hideFuncList, appMediator:getUpgradeUnlockModuleList())
	-- create view
	local uiManager = AppFacade.GetInstance():GetManager('UIManager')
	self.homeScene_ = uiManager:SwitchToTargetScene('home.HomeScene', {hideFuncList = hideFuncList})
	self:SetViewComponent(self.homeScene_)
end
function HomeMediator:CleanupView()
end


function HomeMediator:OnRegist()
	self:GetFacade():UnRegsitMediator('AuthorMediator')
	self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "hide")

    if isFuntoySdk() then
        if device.platform == "ios" then
            local shareUserDefault = cc.UserDefault:getInstance()
            local productInfo = shareUserDefault:getStringForKey("XP_SDK_ADD_STORE_PAYMENT")
            if productInfo and string.len(productInfo) > 0 then
                local tt = json.decode(productInfo)
                if tt.productId then
                    --开始调用支付接口
                    local httpMgr = AppFacade.GetInstance():GetManager("HttpManager")
                    httpMgr:Post("mall/home", "XP_SDK_MALL_HOME", {productId = tt.productId},true)
                end
            end
        end
    end

	regPost(POST.ACTIVITY_DRAW_FIRSTPAY_HOME)
	regPost(POST.ACTIVITY_FOOD_COMPARE_RESULT)

	if GuideUtils.IsGuiding() or CommonUtils.ModulePanelIsOpen() or self.ctorArgs_.popMediator then
		self:getHomeScene():directInit()
	else
		local newestQuestId  = app.gameMgr:GetUserInfo().newestQuestId
		local worldMapStepId = GuideUtils.GetModuleData(GUIDE_MODULES.MODULE_WORLDMAP)
		if newestQuestId > GUIDE_QUEST_SUCCESS_WORLD_MAP and checkint(worldMapStepId) == 0 then
			self:getHomeScene():directInit()
			GuideUtils.SwitchModule(GUIDE_MODULES.MODULE_WORLDMAP)
		else
			self:getHomeScene():delayInit()
		end
	end

    --内存vm 分析开始--
    -- local mri = require("root.MemoryReferenceInfo")
    -- collectgarbage("collect")
    -- mri.m_cMethods.DumpMemorySnapshot("./", "1-Before", -1)
end
function HomeMediator:OnUnRegist()
	unregPost(POST.ACTIVITY_DRAW_FIRSTPAY_HOME)
	unregPost(POST.ACTIVITY_FOOD_COMPARE_RESULT)
end


function HomeMediator:InterestSignals()
	return {
		SGL.SWITCH_HOMEMAP_STATUS,
		SGL.REFRESH_MAIN_CARD,
		SGL.REFRESH_TAKEAWAY_POINTS,
		SGL.REFRESH_NOT_CLOSE_GOODS_EVENT,
		SGL.REFRESH_HOMEMAP_STORY_LAYER,
		SGL.REFRES_LEVEL_CHEST_ICON,
		SGL.REFRES_SEVENDAY_ICON,
		SGL.REFRES_LIMIT_GIFT_ICON,
		SGL.FRESH_HOME_ACTIVITY_ICON,
		SGL.REFRES_ARTIFACT_GUIDE_ICON,
		SGL.REFRES_FIRST_PAY_ICON,
		SGL.REFRES_SUMMER_ACTIVITY_ICON,
		SGL.FRESH_WORLD_BOSS_MAP_DATA,
		SGL.FRESH_FREE_NEWBIE_CAPSULE_DATA,
		SGL.FRESH_3V3_MATCH_BATTLE_DATA,
		SGL.REFRESH_TIME_LIMIT_UPGRADE_ICON,
		SGL.Updata_StoryMissions_Mess,
		SGL.Story_SubmitMissions_Callback,
		SGL.BREAK_TO_HOME_MEDIATOR,
		SGL.FRESH_BLACK_GOLD_COUNT_DOWN_EVENT,
		POST.COMMERCE_HOME.sglName ,
		POST.ACTIVITY_DRAW_FIRSTPAY_HOME.sglName,
		POST.ACTIVITY_FOOD_COMPARE_RESULT.sglName,
		CHAT_PANEL_VISIBLE,
		'RETURNWELFARE_BINGO_TASK_FINISH',
        "XP_SDK_ADD_STORE_PAYMENT",
        "XP_SDK_MALL_HOME"
    }
end
function HomeMediator:ProcessSignal(signal)
	local name = signal:GetName()
	local body = signal:GetBody()

	-- refresh main task
	if name == SGL.Updata_StoryMissions_Mess then
		self:getHomeScene():refreshMainTask()

    elseif name == "XP_SDK_MALL_HOME" then
        if body then
            local pproductId = body.requestData.productId
            local vv = nil
            if body.member then
                for _,val in pairs(body.member) do
                    if val.channelProductId == pproductId then
                        vv = val
                        break
                    end
                end
            elseif body.diamond then
                for _,val in pairs(body.diamond) do
                    if val.channelProductId == pproductId then
                        vv = val
                        break
                    end
                end

            elseif body.chest then
                for _,val in pairs(body.chest) do
                    if val.channelProductId == pproductId then
                        vv = val
                        break
                    end
                end
            end
            if vv and vv.productId then
                --查找到商品
                local httpMgr = AppFacade.GetInstance():GetManager("HttpManager")
                httpMgr:Post("pay/order", "XP_SDK_ADD_STORE_PAYMENT", {productId = vv.productId, price = vv.price, channelProductId = vv.channelProductId})
            end
        end
    elseif name == SGL.FRESH_BLACK_GOLD_COUNT_DOWN_EVENT then
		local homeScene =  self:getHomeScene()
		if homeScene and (not tolua.isnull(homeScene)) then
			homeScene:updateBlackGoldStatus_()
		end
    elseif name == POST.COMMERCE_HOME.sglName then
		local homeScene =  self:getHomeScene()
		if homeScene and (not tolua.isnull(homeScene)) then
			homeScene:refreshNoticeBoardsStatus()
		end
    elseif name == "XP_SDK_ADD_STORE_PAYMENT" then
        --开始高sdk的支付
        if body.orderNo then
            local shareUserDefault = cc.UserDefault:getInstance()
            shareUserDefault:deleteValueForKey("XP_SDK_ADD_STORE_PAYMENT")
            local AppSDK = require('root.AppSDK')
            local amount = body.requestData.price
            local property = body.orderNo
            AppSDK.GetInstance():InvokePay({amount = amount, property = property,goodsId = body.requestData.channelProductId,
                goodsName = __('幻晶石'), quantifier = __('个'),price = 0.1, count = 1})
        end
	elseif name == "RETURNWELFARE_BINGO_TASK_FINISH" then
		local dataMgr = AppFacade.GetInstance():GetManager("DataManager")
		local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
		if gameMgr:CheckIsBackOpen() then
			dataMgr:AddRedDotNofication(tostring(RemindTag.RETURNWELFARE),RemindTag.RETURNWELFARE, "[回归福利]-HomeMediator:CheckLayerRedPoint_[rewelf]")
		else
			dataMgr:ClearRedDotNofication(tostring(RemindTag.RETURNWELFARE), RemindTag.RETURNWELFARE, "[回归福利]-HomeMediator:CheckLayerRedPoint_")
		end
		AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, {countdown = 0, tag = RemindTag.RETURNWELFARE})


	-- refresh homeMap status (nomal / robbery)
	elseif name == SGL.SWITCH_HOMEMAP_STATUS then
		self:getHomeScene():getMapPanel():refreshMapStatus()


	-- refresh homeMap storyLayer
	elseif name == SGL.REFRESH_HOMEMAP_STORY_LAYER then
		self:getHomeScene():getMapPanel():refreshStoryLayer()


	-- refresh main card
	elseif name == SGL.REFRESH_MAIN_CARD then
		self:getHomeScene():refreshMainCard()


	-- refresh takeaway points
	elseif name == SGL.REFRESH_TAKEAWAY_POINTS then
		if self:getHomeScene() then
			local homePanel   = self:getHomeScene():getMapPanel()
			if homePanel and not tolua.isnull(homePanel) then
					homePanel:refreshOrderLayer()
				end
			end


	-- update get new goods
	elseif name == SGL.REFRESH_NOT_CLOSE_GOODS_EVENT then
		app.badgeMgr:CheckOrderRed()


	-- accept / submit task
	elseif name == SGL.Story_SubmitMissions_Callback then
		local requestData = checktable(body.requestData)
		local taskType    = checkint(requestData.type)
		local uiManager   = AppFacade.GetInstance():GetManager('UIManager')
		local gameManager = AppFacade.GetInstance():GetManager('GameManager')

		if requestData and requestData.type then
			if taskType == Types.TYPE_STORY then
				uiManager:ShowInformationTips(__('完成了主线任务'))
				gameManager:GetUserInfo().storyTasks[string.format("%d_%d", Types.TYPE_STORY, checkint(requestData.plotTaskId))] = nil

			elseif taskType == Types.TYPE_BRANCH then
				uiManager:ShowInformationTips(__('完成了支线任务'))
				gameManager:GetUserInfo().storyTasks[string.format("%d_%d", Types.TYPE_BRANCH, checkint(requestData.branchTaskId))] = nil
			end
			self:GetFacade():DispatchObservers(SGL.REFRESH_HOMEMAP_STORY_LAYER)
		end


	-- draw firstPay reward
	elseif name == POST.ACTIVITY_DRAW_FIRSTPAY_HOME.sglName then -- 首冲奖励领取
		local gameManager = AppFacade.GetInstance():GetManager('GameManager')
		if checkint(gameManager:GetUserInfo().firstPay) == 2 then
			gameManager:GetUserInfo().firstPay = 3

			local uiManager = AppFacade.GetInstance():GetManager('UIManager')
			uiManager:AddDialog('common.RewardPopup', {rewards = body.rewards, msg = __('恭喜获得首充奖励'), closeCallback = function()
				self:checkAutoInfoPopup_()
			end})
		end


	elseif name == POST.ACTIVITY_FOOD_COMPARE_RESULT.sglName then -- 飨灵比拼结果
		local mediator = require('Game.mediator.scratcher.ScratcherStatusMediator').new({status = body, needCloseAction = true})
		AppFacade.GetInstance():RegistMediator(mediator)


	elseif name == SGL.REFRESH_TIME_LIMIT_UPGRADE_ICON then -- 限时升级活动
		local homeScene =  self:getHomeScene()
		if homeScene and (not tolua.isnull(homeScene)) then
			homeScene:getFuncSlider():refreshModuleStatus(true)
		end

		
	-- refresh funcBar
	elseif (name == SGL.REFRES_LEVEL_CHEST_ICON or
			name == SGL.REFRES_SEVENDAY_ICON or
			name == SGL.REFRES_LIMIT_GIFT_ICON or
			name == SGL.FRESH_HOME_ACTIVITY_ICON or
			name == SGL.REFRES_ARTIFACT_GUIDE_ICON or
			name == SGL.REFRES_SUMMER_ACTIVITY_ICON or
			name == SGL.REFRES_FIRST_PAY_ICON) then
		if self:getHomeScene() and self:getHomeScene():isInited() then
			self:getHomeScene():getFuncBar():reloadBar()
		end


	-- refresh worldBoss status
	elseif (name == SGL.FRESH_WORLD_BOSS_MAP_DATA or
			name == SGL.FRESH_3V3_MATCH_BATTLE_DATA or
			name == SGL.FRESH_FREE_NEWBIE_CAPSULE_DATA) then
		if self:getHomeScene() then
			self:getHomeScene():refreshNoticeBoardsStatus()
		end


	-- break to homeMediator
	elseif name == SGL.BREAK_TO_HOME_MEDIATOR then
		if self:checkOpenNewFunction_() == false then
			local popViewData = self:getCustomPopupData()
			if popViewData then
				app.uiMgr:AddDialog(popViewData.path, popViewData.params)
				self:setCustomPopupData(nil)
			end
		end


	-- chat panel
	elseif name == CHAT_PANEL_VISIBLE then
		if body.open then
			local viewData = self:getHomeScene():getViewData()
			local chatPanel = viewData.chatPanel
			if chatPanel then
				chatPanel:setVisible(true)
			else
				local CommonChatPanel  = require('common.CommonChatPanel')
				local chatPanel = CommonChatPanel.new()
				viewData.view:addChild(chatPanel)
				viewData.chatPanel = chatPanel
			end
		else
			local viewData = self:getHomeScene():getViewData()
			local chatPanel = viewData.chatPanel
			if chatPanel then
				chatPanel:setVisible(false)
			end
		end

	end
end


-------------------------------------------------
-- get / set

function HomeMediator:getHomeScene()
	if self.homeScene_ and not tolua.isnull(self.homeScene_) then
		return self.homeScene_
	else
		return nil
	end
end


function HomeMediator:isControllable()
	return self.isControllable_
end
function HomeMediator:setControllable(isControllable)
	self.isControllable_ = isControllable == true

	local appMediator  = AppFacade.GetInstance():RetrieveMediator('AppMediator')
	local homeTopLayer = appMediator and appMediator:GetViewComponent() or nil
	if homeTopLayer then
        homeTopLayer:setControllable(self.isControllable_)
    end
end


function HomeMediator:getAppRouter()
    return AppFacade.GetInstance():RetrieveMediator('Router')
end


function HomeMediator:getFuncViewAt(moduleId)
	return self:getHomeScene():getFuncViewAt(moduleId)
end


--[[
	return table { path:string, params:table }
]]
function HomeMediator:getCustomPopupData()
	return self.popupData_
end
function HomeMediator:setCustomPopupData(popupViewData)
	self.popupData_ = popupViewData
end


-------------------------------------------------
-- public method

function HomeMediator:refreshUnlockStatus()
	self:getHomeScene():refreshAllModuleStatus()
end


function HomeMediator:initHomeWorkflow()
    -- ??? what are you doing ???
    local sharedDirector = cc.CSceneManager:getInstance()
    if sharedDirector:getRunningScene():getChildByTag(10) then
		sharedDirector:getRunningScene():removeChildByTag(10)
	end

	-- fresh takeway data
	if CommonUtils.UnLockModule(RemindTag.CARVIEW) then
		local takeawayManager = AppFacade.GetInstance():GetManager('TakeawayManager')
		takeawayManager:FreshData()
	end

	local isUnlockBlackGold = CommonUtils.UnLockModule(RemindTag.BLACK_GOLD) and CommonUtils.GetModuleAvailable(MODULE_SWITCH.BLACK_GOLD)
	if isUnlockBlackGold then
		app.blackGoldMgr:FreshBlackData()
	end

	-- star guide director
	GuideUtils.GetDirector():RealStart()

	-- recover controllable
	self:getHomeScene():runAction(cc.Sequence:create(
		cc.DelayTime:create(0.1),
		cc.CallFunc:create(function()
			self:setControllable(true)
			self:CheckLayerRedPoint_()
			self:checkAutoInfoPopup_()
		end)
	))

end


-------------------------------------------------
-- private method

function HomeMediator:checkOpenNewFunction_()
	local unlockFunctionMdt = self:GetFacade():RetrieveMediator('HomeUnlockFunctionMediator')

	-- check is return to homeRoot
	-- 1、homeMdt，2、closing mdt
	local mediatorStackNum = self:GetFacade():GetMediatorStackNum()
	if unlockFunctionMdt then
		if mediatorStackNum > 2 then return false end
	else
		if mediatorStackNum > 1 then return false end
	end

	-- first check unlck order
	local gameManager = AppFacade.GetInstance():GetManager('GameManager')
	local appMediator = AppFacade.GetInstance():RetrieveMediator('AppMediator')
	local unlockOData = appMediator and appMediator:getUpgradeUnlockOrderData() or {}
	if unlockOData and next(unlockOData) ~= nil and gameManager:GetAreaId() == checkint(unlockOData.areaId) then
		if not CommonUtils.ModulePanelIsOpen() then
			-- show in UnlockMdt
			if not unlockFunctionMdt then
				unlockFunctionMdt = require('Game.mediator.HomeUnlockFunctionMediator').new()
				self:GetFacade():RegistMediator(unlockFunctionMdt)
			end
			unlockFunctionMdt:showUnlockFunciton(MODULE_DATA[tostring(RemindTag.PUBLIC_ORDER)], unlockOData)

			-- delete data
			appMediator:setUpgradeUnlockOrderData(nil)
			return true
		else
			return false
		end

	else
		-- pop unlock list
		local popUnlockIdx = 0
		local openModuleId = 0
		local unlockList   = appMediator and appMediator:getUpgradeUnlockModuleList() or {}
		for i, moduleId in ipairs(unlockList) do
			if CommonUtils.ModulePanelIsOpen() then
				if HOME_FUNC_FROM_MAP[checkint(moduleId)] == 'EXTRA_PANEL' then
					popUnlockIdx = i
					break
				end
			else
				if HOME_FUNC_FROM_MAP[checkint(moduleId)] ~= 'EXTRA_PANEL' then
					popUnlockIdx = i
					break
				end
			end
		end
		if popUnlockIdx > 0 then
			openModuleId = checkint(table.remove(unlockList, popUnlockIdx))
		end
		if openModuleId > 0 then

			-- update data
			appMediator:setUpgradeUnlockModuleList(unlockList)

			-- update view
			self:getHomeScene():eraseHideFuncAt(openModuleId)

			-- show in UnlockMdt
			if not unlockFunctionMdt then
				unlockFunctionMdt = require('Game.mediator.HomeUnlockFunctionMediator').new()
				self:GetFacade():RegistMediator(unlockFunctionMdt)
			end
			unlockFunctionMdt:showUnlockFunciton(openModuleId)
			return true
		else
			if unlockFunctionMdt then
				unlockFunctionMdt:close()
			end
			return false
		end
	end
	return false
end


function HomeMediator:checkAutoInfoPopup_()
	local appMediator  = AppFacade.GetInstance():RetrieveMediator('AppMediator')
	local gameManager  = AppFacade.GetInstance():GetManager('GameManager')
	local userTipsData = checktable(gameManager:GetUserInfo().tips)

	if not gameManager.isFirstRequestPostData_ then
		-- request activityHome data
		appMediator:syncHomeActivityhomeData()
		-- request activityIcon data
		appMediator:syncHomeActivityhomeIconData()
		-- request freeNewbie data
		appMediator:syncFreeNewbieCapsuleData()

		if CommonUtils.GetModuleAvailable(MODULE_SWITCH.WORLD_BOSS) then
			-- request worldBoss data
			appMediator:syncWorldBossListData()
		end

		if CommonUtils.UnLockModule(RemindTag.TAG_MATCH) and CommonUtils.GetModuleAvailable(MODULE_SWITCH.TAG_MATCH) then
			-- request matchBattle data
			if not GAME_MODULE_OPEN.NEW_TAG_MATCH then
				appMediator:sync3v3MatchBattleData()
			end
		end

		-- mark firstRequest
		gameManager.isFirstRequestPostData_ = true
	end

	-- check open newFUnction
	if self:checkOpenNewFunction_() then return end

	-- check guide running
	if GuideUtils.IsGuiding() then return end


	-------------------------------------------------
	-- 首冲活动：2 已充值、未领取（弥补掉单情况，再次登录时自动请求领奖）
	if checkint(gameManager:GetUserInfo().firstPay) == 2 then
		self:SendSignal(POST.ACTIVITY_DRAW_FIRSTPAY_HOME.cmdName)
	
	-------------------------------------------------
	-- 周年庆动画是否开启
	elseif checkint(gameManager:GetUserInfo().isOpenedAnniversaryPV) == 1 and not app.anniversaryMgr:IsOpenedHomePoster() then
		local anniversaryPosterMdt = require('Game.mediator.anniversary.AnniversaryHomePosterMediator').new({closeCB = function()
			self:checkAutoInfoPopup_()
		end})
		self:GetFacade():RegistMediator(anniversaryPosterMdt)

	elseif checkint(gameManager:GetUserInfo().isOpenedAnniversary2019PV) == 1 and not app.anniversary2019Mgr:IsOpenedHomePoster() then
		local anniversaryPosterMdt = require('Game.mediator.anniversary19.Anniversary19HomePosterMediator').new({closeCB = function()
			self:checkAutoInfoPopup_()
		end})
		self:GetFacade():RegistMediator(anniversaryPosterMdt)
	elseif checkint(gameManager:GetUserInfo().isOpenedAnniversary2020PV) == 1 and not app.anniv2020Mgr:IsOpenedHomePoster() then
		local anniversaryPosterMdt = require('Game.mediator.anniversary20.Anniversary20HomePosterMediator').new({closeCB = function()
			self:checkAutoInfoPopup_()
		end})
		self:GetFacade():RegistMediator(anniversaryPosterMdt)

	-------------------------------------------------
	-- 新主线功能提示
	elseif app.gameMgr:IsOpenMapPlot() and not app.gameMgr:GetNewPlotWatchStatus() then
		local storyPath  = string.format('conf/%s/plot/story0.json', i18n.getLang())
		local operaStage = require( "Frame.Opera.OperaStage" ).new({path = storyPath, id = 1, isHideBackBtn = true, isReview = true, cb = function()
			self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "hide")
			
			app.gameMgr:SwitchAreaId(1)
			self:getHomeScene():getMapPanel():refreshMapImage()
			self:getHomeScene():getMapPanel():refreshQuestLayer()
			self:getHomeScene():getMapPanel():refreshOrderLayer()  -- auto refreshStoryLayer

			app.gameMgr:SetNewPlotWatchStatus(true)
			self:checkAutoInfoPopup_()
		end})
		operaStage:setName('operaStage')
		display.commonUIParams(operaStage, {po = display.center})
		self:getHomeScene():AddGameLayer(operaStage)

		self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "rightHide")
		self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "allhide")

	-------------------------------------------------
	-- 活动广告页
	elseif gameManager:GetUserInfo().isShowPoster and not gameManager:isIgnoreTodayPoster() then
		local activityPosterMdt = require('Game.mediator.ActivityPosterMediator').new({closeCB = function()
			self:checkAutoInfoPopup_()
		end})
		self:GetFacade():RegistMediator(activityPosterMdt)
		gameManager:GetUserInfo().isShowPoster = false

	-------------------------------------------------
	-- 老玩家回归打脸
	-- elseif cc.UserDefault:getInstance():getBoolForKey(string.format("%s_RECALL_POSTER" , tostring(gameManager:GetUserInfo().playerId) ), true)
	-- 	and gameManager:CheckIsRecalled() and 1 == checkint(gameManager:GetUserInfo().recall) and CommonUtils.UnLockModule(MODULE_DATA[tostring(RemindTag.RECALL)], false) then
	-- 	local RecallNoticeMediator = require( 'Game.mediator.RecallNoticeMediator' )
	-- 	local mediator = RecallNoticeMediator.new({closeCB = function()
	-- 		self:checkAutoInfoPopup_()
	-- 		cc.UserDefault:getInstance():setBoolForKey(string.format("%s_RECALL_POSTER" , tostring(gameManager:GetUserInfo().playerId) ), false)
	-- 		cc.UserDefault:getInstance():flush()
	-- 	end})
	-- 	self:GetFacade():RegistMediator(mediator)

	-------------------------------------------------
	-- 流失玩家邮件奖励
	elseif next(gameManager:GetUserInfo().returnRewards) then
		local LossPlayerReturnNoticeMediator = require( 'Game.mediator.LossPlayerReturnNoticeMediator' )
		local mediator = LossPlayerReturnNoticeMediator.new()
		self:GetFacade():RegistMediator(mediator)

	-------------------------------------------------
	-- 新手15天
	elseif gameManager:GetUserInfo().isShowNewbie15Day and checkint(gameManager:GetUserInfo().newbie15Day) == 1 then
		self:getAppRouter():Dispatch({name = 'HomeMediator'}, {name = 'ActivityMediator', params = {activityId = ACTIVITY_TYPE.NOVICE_BONUS}})
		gameManager:GetUserInfo().isShowNewbie15Day = false


	-------------------------------------------------
	-- 今日签到
	elseif gameManager:GetUserInfo().isShowMonthlyLogin then
		self:getAppRouter():Dispatch({name = 'HomeMediator'}, {name = 'ActivityMediator', params = {activityId = ACTIVITY_TYPE.DAILY_BONUS}})
		gameManager:GetUserInfo().isShowMonthlyLogin = false


	-------------------------------------------------
	-- 图鉴弹窗
	elseif self.isShowHandbook_ then
		self:getAppRouter():Dispatch({name = 'HomeMediator'}, {name = 'HandbookMediator'})


	-------------------------------------------------
	-- 好友切磋
	elseif self.isShowFriendPK_ then
		self:getAppRouter():Dispatch({name = 'HomeMediator'}, {name = 'FriendMediator', params = {friendType = FriendTabType.FRIEND_BATTLE}})


	-------------------------------------------------
	-- 
	elseif self.ctorArgs_.popMediator then
		if CommonUtils.checkPopMediatorIsCanPop(self.ctorArgs_.popMediator) then
			self:getAppRouter():Dispatch({name = 'HomeMediator'}, {name = self.ctorArgs_.popMediator, params = {fromMediator = 'HomeMediator', activityId = self.ctorArgs_.activityId}})
		end
		self.ctorArgs_.popMediator = nil


	-------------------------------------------------
	-- 飨灵刮刮乐
	elseif 0 == gameManager:GetUserInfo().foodCompareResultAck then
		self:SendSignal(POST.ACTIVITY_FOOD_COMPARE_RESULT.cmdName)


	-------------------------------------------------
	-- 自定义弹窗：这个重要度最低，所以一定要放最后面。
	elseif self:getCustomPopupData() ~= nil then
		local popViewData = self:getCustomPopupData()
		app.uiMgr:AddDialog(popViewData.path, popViewData.params)
		self:setCustomPopupData(nil)  -- 用完就清

	end
end


-- TODO
function HomeMediator:CheckLayerRedPoint_( )
	local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
	local dataMgr = AppFacade.GetInstance():GetManager("DataManager")

	-- 新手七天任务
	if gameMgr:GetUserInfo().newbieTaskRemainTime > 0 then
		if gameMgr:GetUserInfo().showRedPointForNewbieTask == true then
			dataMgr:AddRedDotNofication(tostring(RemindTag.SEVENDAY), RemindTag.SEVENDAY, "[新手七天]-CheckLayerRedPoint_[newbieTaskRemainTime]")
		else
			dataMgr:ClearRedDotNofication(tostring(RemindTag.SEVENDAY), RemindTag.SEVENDAY, "[新手七天]-CheckLayerRedPoint_[newbieTaskRemainTime]")
		end
	else
		dataMgr:ClearRedDotNofication(tostring(RemindTag.SEVENDAY), RemindTag.SEVENDAY, "[新手七天]-CheckLayerRedPoint_")
	end
	AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, {countdown = 0, tag = RemindTag.SEVENDAY})
	-- 新手福利（新手14天）
	if gameMgr:GetUserInfo().newbie14TaskRemainTime > 0 then
		if gameMgr:GetUserInfo().tips.newbie14Task == 1 then
			dataMgr:AddRedDotNofication(tostring(RemindTag.NOVICE_WELFARE), RemindTag.NOVICE_WELFARE, "[新手14天]-CheckLayerRedPoint_[newbieTaskRemainTime]")
		else
			dataMgr:ClearRedDotNofication(tostring(RemindTag.NOVICE_WELFARE), RemindTag.NOVICE_WELFARE, "[新手14天]-CheckLayerRedPoint_[newbieTaskRemainTime]")
		end
	else
		dataMgr:ClearRedDotNofication(tostring(RemindTag.NOVICE_WELFARE), RemindTag.NOVICE_WELFARE, "[新手14天]-CheckLayerRedPoint_")
	end
	AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, {countdown = 0, tag = RemindTag.NOVICE_WELFARE})
	-- 老玩家召回
	if checkint(gameMgr:GetUserInfo().recall) == 1 and (
		gameMgr:GetUserInfo().showRedPointForRecallTask or
		gameMgr:GetUserInfo().showRedPointForMasterRecalled or
		gameMgr:GetUserInfo().showRedPointForRecallH5
	) then
		dataMgr:AddRedDotNofication(tostring(RemindTag.RECALL),RemindTag.RECALL, "[老玩家召回]-HomeMediator:CheckLayerRedPoint_[recall]")
	else
		dataMgr:ClearRedDotNofication(tostring(RemindTag.RECALL), RemindTag.RECALL, "[老玩家召回]-HomeMediator:CheckLayerRedPoint_")
	end
	AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, {countdown = 0, tag = RemindTag.RECALL})

	-- 回归福利
	if gameMgr:CheckIsBackOpen() and gameMgr:GetUserInfo().showRedPointForBack then
		dataMgr:AddRedDotNofication(tostring(RemindTag.RETURNWELFARE),RemindTag.RETURNWELFARE, "[回归福利]-HomeMediator:CheckLayerRedPoint_[rewelf]")
	else
		dataMgr:ClearRedDotNofication(tostring(RemindTag.RETURNWELFARE), RemindTag.RETURNWELFARE, "[回归福利]-HomeMediator:CheckLayerRedPoint_")
	end
	AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, {countdown = 0, tag = RemindTag.RETURNWELFARE})

	-- 说明有灵体正在净化
	if gameMgr:GetUserInfo().showRedPointForPetPurge == true then
		if gameMgr:GetUserInfo().petPurgeLeftSeconds <= 0 then
			dataMgr:AddRedDotNofication(tostring(RemindTag.PET),RemindTag.PET, "[堕神]-HomeMediator:CheckLayerRedPoint_[showRedPointForPetPurge]")
		else
			dataMgr:ClearRedDotNofication(tostring(RemindTag.PET), RemindTag.PET, "[堕神]-HomeMediator:CheckLayerRedPoint_[showRedPointForPetPurge]")
		end
	else
		dataMgr:ClearRedDotNofication(tostring(RemindTag.PET), RemindTag.PET, "[堕神]-HomeMediator:CheckLayerRedPoint_")
	end
	AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, {countdown = 0, tag = RemindTag.PET})

	-- 有卡牌可升星提示小红点
    if app.badgeMgr:IsShowRedPointForCardBreak() then
    	dataMgr:AddRedDotNofication(tostring(RemindTag.CARDS), RemindTag.CARDS, "[升星]-HomeMediator:CheckLayerRedPoint_")
    else
    	dataMgr:ClearRedDotNofication(tostring(RemindTag.CARDS), RemindTag.CARDS, "[升星]-HomeMediator:CheckLayerRedPoint_")
    end
    AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, {countdown = 0, tag = RemindTag.CARDS})

	-- 有未领取邮件提示小红点
    AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, {countdown = 0, tag = RemindTag.MAIL})

	-- 有新的队伍栏位解锁提示小红点
    if app.badgeMgr:IsShowRedPointForUnLockTeam() then
    	dataMgr:AddRedDotNofication(tostring(RemindTag.TEAMS), RemindTag.TEAMS,"[编队]-HomeMediator:CheckLayerRedPoint_")
    else
    	dataMgr:ClearRedDotNofication(tostring(RemindTag.TEAMS), RemindTag.TEAMS, "[编队]-HomeMediator:CheckLayerRedPoint_")
    end
    AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, {countdown = 0, tag = RemindTag.TEAMS})

	if CommonUtils.UnLockModule(RemindTag.TASK , false) then
    	app.badgeMgr:CheckTaskHomeRed()
	end

	-- 餐厅有服务员或者厨师的新鲜度不足
    if app.restaurantMgr:IsShowRedPointForChefOrWaiter() then
    	dataMgr:AddRedDotNofication(tostring(RemindTag.MANAGER), RemindTag.MANAGER, "[餐厅服务员]-HomeMediator:CheckLayerRedPoint_")
    else
    	dataMgr:ClearRedDotNofication(tostring(RemindTag.MANAGER), RemindTag.MANAGER, "[餐厅服务员]-HomeMediator:CheckLayerRedPoint_")
    end
    AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, {countdown = 0, tag = RemindTag.MANAGER})

	-- 检查世界地图红点
	app.badgeMgr:CheckWorldMapRedPoint()

    -- 是否显示好友红点
    if ChatUtils.HasUnreadMessage() or checkint(dataMgr:GetRedDotNofication(tostring(RemindTag.NEW_FRIENDS), RemindTag.NEW_FRIENDS)) ~= 0 then
    	dataMgr:AddRedDotNofication(tostring(RemindTag.FRIENDS), RemindTag.FRIENDS, "[好友消息]-HomeMediator:CheckLayerRedPoint")
		AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, {countdown = 0, tag = RemindTag.FRIENDS})
    else
    	dataMgr:ClearRedDotNofication(tostring(RemindTag.FRIENDS), RemindTag.FRIENDS, "[好友消息]-HomeMediator:CheckLayerRedPoint")
	end
	
	-- 检查历练红点
	app.badgeMgr:CheckTrialsRedPoint()

	-- 检查飨灵收集红点
	app.badgeMgr:CheckCardCollRedPoint()
end


-------------------------------------------------
-- handler


return HomeMediator

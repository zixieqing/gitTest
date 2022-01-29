--[[
 * author : kaishiqi
 * descpt : 主界面 - 功能条
]]
local RemindIcon  = require('common.RemindIcon')
local HomeFuncBar = class('HomeFuncBar', function()
	return display.newLayer(0, 0, {name = 'home.HomeFuncBar', enableEvent = true})
end)

local RES_DICT = {
	ALPHA_IMAGE      = 'ui/common/story_tranparent_bg.png',
	COUNTDOWN_BAR    = 'ui/home/nmain/main_maps_bg_countdown.png',
	REMIND_ICON_PATH = 'ui/common/common_hint_circle_red_ico.png',
}

local FUNC_BTN_SIZE   = cc.size(88, 100)
if isElexSdk() then
	FUNC_BTN_SIZE = cc.size(100, 100)
end
local FUNC_BTN_DEFINE = {
	SHOP            = {title = __('商店'),    tag = RemindTag.SHOP,            frame = true, redIcon = true,   image = 'ui/home/nmain/main_btn_shop.png',     theme = HOME_THEME_STYLE_DEFINE.SHOP_BTN, spine = 'effects/shangdian'},
	ACTIVITY        = {title = __('活动'),    tag = RemindTag.ACTIVITY,        frame = true, redIcon = true,   image = 'ui/home/nmain/main_btn_activity.png', theme = HOME_THEME_STYLE_DEFINE.ACTIVITY_BTN},
	FRIENDS         = {title = __('好友'),    tag = RemindTag.FRIENDS,         frame = true, redIcon = true,   image = 'ui/home/nmain/main_btn_friends.png',  theme = HOME_THEME_STYLE_DEFINE.FRIENDS_BTN},
	MAIL            = {title = __('信箱'),    tag = RemindTag.MAIL,            frame = true, redIcon = true,   image = 'ui/home/nmain/main_btn_mail.png',     theme = HOME_THEME_STYLE_DEFINE.MAIL_BTN},
	STRONGE         = {title = __('我要变强'), tag = RemindTag.CHANGE_STRONGER, frame = true, redIcon = true,   image = 'ui/home/nmain/main_btn_book.png' },
	ADD_PAY         = {title = __('回馈'),    tag = RemindTag.PERSISTENCE_PAY, frame = true, redIcon = true,   image = 'ui/home/nmain/main_btn_recharge.png',  spine = 'effects/shangdian'},
	FIRST_PAY       = {title = __('首充'),    tag = RemindTag.FIRST_PAY,                     redIcon = true,   spine = 'effects/homeIcon/main_btn_ac_firstcharge'},
	SEVENDAY        = {title = __('福利'),    tag = RemindTag.SEVENDAY,        frame = true, redIcon = true,   image = 'ui/home/nmain/main_btn_sevenday.png',  spine = 'effects/shangdian'},
	NOVICE_WELFARE  = {title = __('新福利'),  tag = RemindTag.NOVICE_WELFARE,  frame = true, redIcon = true,   image = 'ui/home/nmain/main_btn_ac_14days.png', spine = 'effects/shangdian'},
	ARTIFACT_GUIDE  = {title = __('神器指引'), tag = RemindTag.ARTIFACT_GUIDE,  frame = true, redIcon = true,   image = 'ui/home/nmain/main_btn_shenqi.png',    spine = 'effects/shangdian'},
	RECALL 	        = {title = __('召回'),    tag = RemindTag.RECALL,     	   frame = true, redIcon = true,   image = 'ui/home/nmain/main_btn_recall.png'},
	SUMMER_ACTIVITY = {title = __('乐园'),    tag = RemindTag.SUMMER_ACTIVITY, frame = true, countdown = true, image = 'ui/home/nmain/main_btn_ac_summer.png'},
	SP_ACTIVITY     = {title = __('周年庆'),  tag = RemindTag.SP_ACTIVITY,     frame = true, redIcon = true, countdown = true, image = 'ui/home/nmain/main_btn_ac_summer.png'},
	LV_CHEST        = {title = __('等级礼包'), tag = RemindTag.LEVEL_CHEST,    frame = true, countdown = true, image = 'ui/home/nmain/main_btn_level_box.png', spine = 'effects/shangdian'},
	SAIMOE 	        = {title = __('应援'),    tag = RemindTag.SAIMOE,     	   frame = true, countdown = true, image = 'ui/home/nmain/main_btn_ac_starplan.png'},
	REWELF 	        = {title = __('回归福利'), tag = RemindTag.RETURNWELFARE, 	frame = true, redIcon = true,   image = 'ui/home/nmain/main_btn_recall_II.png'},
	ACCOUNT_MIGRAT  = {title = __('账号迁移'),                                                    image = "ui/home/accountMigration/icon.png"},
}

if GAME_MODULE_OPEN.NEW_STORE then
	FUNC_BTN_DEFINE.SHOP.spine       = 'effects/shop'
	FUNC_BTN_DEFINE.SHOP.spineOffset = cc.p(0,7)
end
local ACTIVITY_MEDIATOR = {
	[ACTIVITY_TYPE.PASS_TICKET]   = {
		mediatorPath = "Game.mediator.passTicket.PassTicketMediator" ,

	} ,
	[ACTIVITY_TYPE.EXCHANGE_CARD] = {
		mediatorPath = "Game.mediator.activity.exchange.ExchangeActivityCardMediator"
	},
	[ACTIVITY_TYPE.ASSEMBLY_ACTIVITY] = {
		routerPath   = "activity.assemblyActivity.AssemblyActivityMediator",
		mediatorPath ="Game.mediator.activity.assemblyActivity.AssemblyActivityMediator",
		callback = function ()
			DotGameEvent.SendEvent(DotGameEvent.EVENTS.RETURN_HOME_PAGE)
		end
	}
}
local ACTIVITY_ROUTER_MEDIATOR = {
	[ACTIVITY_TYPE.CASTLE_ACTIVITY] = "castle.CastleMainMediator",
	[ACTIVITY_TYPE.ANNIVERSARY19]   = "anniversary19.Anniversary19HomeMediator",
}


local CreateView       = nil
local CreateFuncButton = nil


-------------------------------------------------
-- life cycle

function HomeFuncBar:ctor(args)
	self.funcHideMap_     = args.funcHideMap or {}
	self.isControllable_  = true
	self.basicButtonList_ = {}
	self.extraButtonList_ = {}

	-- create view
	self.viewData_ = CreateView()
	self.viewData_.view:setName('FuncBarView')
	self:addChild(self.viewData_.view)

	-- create basic buttons
	local basicFuncDefine = {
		FUNC_BTN_DEFINE.SHOP,
		FUNC_BTN_DEFINE.ACTIVITY,
		FUNC_BTN_DEFINE.FRIENDS,
		FUNC_BTN_DEFINE.MAIL,
	}
	if GAME_MODULE_OPEN.CHANGE_STRONGER then
		basicFuncDefine = {
			FUNC_BTN_DEFINE.SHOP,
			FUNC_BTN_DEFINE.ACTIVITY,
			FUNC_BTN_DEFINE.FRIENDS,
			FUNC_BTN_DEFINE.MAIL,
			FUNC_BTN_DEFINE.STRONGE,
		}
	end
	local funcBtnLayer = self:getViewData().funcBtnLayer
	for i, funcDefine in ipairs(basicFuncDefine) do
		local funcBtn = CreateFuncButton(funcDefine)
		table.insert(self.basicButtonList_, funcBtn)
		funcBtnLayer:addChild(funcBtn.view)
	end

	-- update bar
	-- self:reloadBar()
	
	-- init action
	for i , funcBtn in ipairs(self:getAllFuncBtnList()) do
		funcBtn.view:setOpacity(0)
		funcBtn.view:runAction(cc.Sequence:create(
			cc.DelayTime:create(i * 0.1),
			cc.FadeIn:create(0.2)
		))
	end

	-- add listener
	AppFacade.GetInstance():RegistObserver(COUNT_DOWN_ACTION, mvc.Observer.new(self.onTimerCountdownHandler_, self))
	display.commonUIParams(self.basicButtonList_[1].view, {cb = handler(self, self.onClickShopButtonHandler_)})
	display.commonUIParams(self.basicButtonList_[2].view, {cb = handler(self, self.onClickActivityButtonHandler_)})
	display.commonUIParams(self.basicButtonList_[3].view, {cb = handler(self, self.onClickFriendsButtonHandler_)})
	display.commonUIParams(self.basicButtonList_[4].view, {cb = handler(self, self.onClickMailButtonHandler_)})
	if GAME_MODULE_OPEN.CHANGE_STRONGER then
		display.commonUIParams(self.basicButtonList_[5].view, {cb = handler(self, self.onClickStrongerButtonHandler_)})
	end
end


CreateView = function()
	local view = display.newLayer()
	local size = view:getContentSize()

	local funcBtnPoint = cc.p(display.SAFE_R - 10, display.height - 105)
	local funcBtnLayer = display.newLayer()
	view:addChild(funcBtnLayer)

	return {
		view         = view,
		funcBtnLayer = funcBtnLayer,
		funcBtnPoint = funcBtnPoint,
	}
end


CreateFuncButton = function(funcDefine, funcBtnName)
	local size = FUNC_BTN_SIZE
	local view = display.newButton(0, 0, {n = app.plistMgr:checkSpriteFrame(RES_DICT.ALPHA_IMAGE), scale9 = true, size = size})
	
	local countdownBar = nil
	if funcDefine then
		view:setTag(checkint(funcDefine.tag))
		
		-- button image
		if funcDefine.image then
			local buttonPath = funcDefine.theme or (funcDefine.frame and app.plistMgr:checkSpriteFrame(funcDefine.image) or funcDefine.image)
			local buttonImg  = display.newImageView(buttonPath, size.width/2, size.height, {scale = scale, ap = display.CENTER_TOP})
			view:addChild(buttonImg)
		end

		-- button spine
		if funcDefine.spine then
			local spinePath   = funcDefine.spine
			local spineOffset = funcDefine.spineOffset or PointZero
			if not SpineCache(SpineCacheName.GLOBAL):hasSpineCacheData(spinePath) then
				SpineCache(SpineCacheName.GLOBAL):addCacheData(spinePath, spinePath, 1)
			end
			local buttonSpine = SpineCache(SpineCacheName.GLOBAL):createWithName(spinePath)
			buttonSpine:setPosition(size.width/2 + spineOffset.x, size.height/2 + spineOffset.y)
			buttonSpine:setAnimation(0, 'idle', true)
			view:addChild(buttonSpine)
		end
		
		-- button name
		if funcDefine.title then
			local nameLabel = display.newLabel(size.width/2, 26, fontWithColor(14, {text = checkstr(funcDefine.title), fontSize = 20}))
			local nameSize  = display.getLabelContentSize(nameLabel)
			if nameSize.width > size.width then
				nameLabel:setScale(size.width / nameSize.width)
			end
			view:addChild(nameLabel)
		end

		-- button countdownBar
		if funcDefine.countdown then
			countdownBar = display.newButton(size.width/2, 5, {n = app.plistMgr:checkSpriteFrame(RES_DICT.COUNTDOWN_BAR), scale9 = true, size = cc.size(size.width - 4, 24), enable = false})
			display.commonLabelParams(countdownBar, fontWithColor(10, {text = '--:--:--'}))
			view:addChild(countdownBar)
		end

		-- button redIcon
		if funcDefine.redIcon then
			RemindIcon.addRemindIcon({imgPath = RES_DICT.REMIND_ICON_PATH, parent = view, tag = view:getTag(), po = cc.p(size.width - 18, size.height - 25)})
		end
	else
		view:addChild(display.newLayer(0, 0, {size = size, color = cc.r4b(150)}))
		view:addChild(display.newLabel(size.width/2, size.height/2, fontWithColor(14, {fontSize = 20, text = tostring(funcBtnName)})))
	end

	return {
		view         = view,
		countdownBar = countdownBar
	}
end


-------------------------------------------------
-- get / set

function HomeFuncBar:getViewData()
	return self.viewData_
end


function HomeFuncBar:getAllFuncBtnList()
	local funcButtonList = {}
	for _, funBtn in ipairs(self.basicButtonList_ or {}) do
		local funTag = funBtn.view:getTag()
		if funTag == FUNC_BTN_DEFINE.ACTIVITY.tag then
			if not self.funcHideMap_[tostring(MODULE_DATA[tostring(RemindTag.ACTIVITY)])] then
				table.insert(funcButtonList, funBtn)
			end
		elseif funTag == FUNC_BTN_DEFINE.SHOP.tag then
			if not self.funcHideMap_[tostring(MODULE_DATA[tostring(RemindTag.SHOP)])] and CommonUtils.GetModuleAvailable(MODULE_SWITCH.SHOP) then
				table.insert(funcButtonList, funBtn)
			end
		elseif funTag == FUNC_BTN_DEFINE.MAIL.tag then
			if CommonUtils.GetModuleAvailable(MODULE_SWITCH.MAIL) then
				table.insert(funcButtonList, funBtn)
			end
		elseif funTag == FUNC_BTN_DEFINE.FRIENDS.tag then
			if CommonUtils.GetModuleAvailable(MODULE_SWITCH.FRIEND) then
				table.insert(funcButtonList, funBtn)
			end
		else
			table.insert(funcButtonList, funBtn)
		end
	end
	for _, funBtn in ipairs(self.extraButtonList_ or {}) do
		table.insert(funcButtonList, funBtn)
	end
	return funcButtonList
end


function HomeFuncBar:isHomeControllable()
    local homeMediator = AppFacade.GetInstance():RetrieveMediator('HomeMediator')
    return homeMediator and homeMediator:isControllable()
end


function HomeFuncBar:getAppRouter()
    return AppFacade.GetInstance():RetrieveMediator('Router')
end


-------------------------------------------------
-- public method

function HomeFuncBar:reloadBar()
	local gameManager      = AppFacade.GetInstance():GetManager('GameManager')
	local funcBtnPoint     = self:getViewData().funcBtnPoint
	local funcBtnLayer     = self:getViewData().funcBtnLayer
	local oldExtraBtnList  = self.extraButtonList_
	local oldExtraReuseMap = {}
	self.extraButtonList_  = {}

	local createFuncBtn = function(funcBtnName, funcBtnDefine, clickHandler)
		local funcBtnNode  = funcBtnLayer:getChildByName(funcBtnName)
		local funcBtnIndex = funcBtnNode and funcBtnNode:getTag() or 0
		if funcBtnNode and funcBtnIndex > 0 then
			local funcBtn = oldExtraBtnList[funcBtnIndex]
			table.insert(self.extraButtonList_, funcBtn)
			oldExtraReuseMap[tostring(funcBtnIndex)] = true

		else
			local funcBtn = CreateFuncButton(funcBtnDefine, funcBtnName)
			funcBtn.view:setName(funcBtnName)
			funcBtnLayer:addChild(funcBtn.view)
			table.insert(self.extraButtonList_, funcBtn)

			if clickHandler then
				display.commonUIParams(funcBtn.view, {cb = clickHandler})
			end
		end
	end
	-------------------------------------------------
	-- check persistencePay/firstPay
	if isElexSdk() then
		createFuncBtn('ADD_PAY', FUNC_BTN_DEFINE.ADD_PAY, handler(self, self.onClickAddPayButtonHandler_))
	else
		local firstPayState = checkint(gameManager:GetUserInfo().firstPay)
		if firstPayState == 1 then
			createFuncBtn('FIRST_PAY', FUNC_BTN_DEFINE.FIRST_PAY, handler(self, self.onClickFirstPayButtonHandler_))
		else
			createFuncBtn('ADD_PAY', FUNC_BTN_DEFINE.ADD_PAY, handler(self, self.onClickAddPayButtonHandler_))
		end
	end

	-------------------------------------------------
	-- check newbieTask
	local newbieTaskTime = checkint(gameManager:GetUserInfo().newbieTaskRemainTime)
	if newbieTaskTime > 0 then
		createFuncBtn('NEWBIE_TASK', FUNC_BTN_DEFINE.SEVENDAY, handler(self, self.onClickNewbieTaskButtonHandler_))
	end

	-------------------------------------------------
	-- check recall
	local dataMgr = AppFacade.GetInstance():GetManager("DataManager")
	local recall = checkint(gameManager:GetUserInfo().recall)
	if 1 == recall and CommonUtils.UnLockModule(MODULE_DATA[tostring(RemindTag.RECALL)], false) then
		createFuncBtn('RECALL', FUNC_BTN_DEFINE.RECALL, handler(self, self.onClickRecallButtonHandler_))
	end

	-------------------------------------------------
	-- check returnWelfare
	if gameManager:CheckIsBackOpen() and CommonUtils.UnLockModule(JUMP_MODULE_DATA.RETURN_WELFARE, false) then
		createFuncBtn('REWELF', FUNC_BTN_DEFINE.REWELF, handler(self, self.onClickReturnWelfareButtonHandler_))
	end

	-------------------------------------------------
	-- check saimoe
	local comparisonActivityTime = checkint(gameManager:GetUserInfo().comparisonActivity)
	if comparisonActivityTime > 0 then
		createFuncBtn('SAIMOE', FUNC_BTN_DEFINE.SAIMOE, handler(self, self.onClickSaiMoeButtonHandler_))
	end

	-------------------------------------------------
	-- check levelChest
	local levelChestTime = checkint(gameManager:GetUserInfo().tips.levelChest)
	if gameManager:GetUserInfo().levelChest and levelChestTime > 0 then
		createFuncBtn('LEVEL_CHEST', FUNC_BTN_DEFINE.LV_CHEST, handler(self, self.onClickLevelChestButtonHandler_))
	end

	-------------------------------------------------
	-- check limiteGift
	for i, chestData in ipairs(gameManager:GetUserInfo().triggerChest or {}) do
		local imgPath = string.format('ui/home/nmain/main_btn_sale_%d',  checkint(chestData.iconId))
		local btnName = string.format('Limit_Gift_%d_%d_%d', checkint(chestData.productId), checkint(chestData.iconId), checkint(chestData.uiTplId))
		local btnData = {title = chestData.name or __('限时礼包'), tag = RemindTag.Limite_Time_GIFT_BG, image = _res(imgPath), spine = 'effects/shangdian', countdown = true}
		createFuncBtn(btnName, btnData, handler(self, self.onClickLimitGiftIconButtonHandler_))
	end
	-------------------------------------------------
	-- check noviceWelfare
	local noviceWelfareTime = checkint(gameManager:GetUserInfo().newbie14TaskRemainTime)
	if noviceWelfareTime > 0 then
		createFuncBtn('NOVICE_WELFARE', FUNC_BTN_DEFINE.NOVICE_WELFARE, handler(self, self.onClickNoviceWelfareButtonHandler_))
	end
	-------------------------------------------------
	-- check artifactGuide // 0:未开启 1：奖励未领取 2：奖励已领取
	if GAME_MODULE_OPEN.ARTIFACT_GUIDE and gameManager:GetUserInfo().artifactGuide and checkint(gameManager:GetUserInfo().artifactGuide) == 1 then
		createFuncBtn('ARTIFACT_GUIDE', FUNC_BTN_DEFINE.ARTIFACT_GUIDE, handler(self, self.onClickArtifactGuideButtonHandler_))
	end
	-------------------------------------------------
	-- check accountMigrate
	if GAME_MODULE_OPEN.ACCOUNT_MIGRAT and gameManager:GetUserInfo().isOpenTransfer and checkint(gameManager:GetUserInfo().isOpenTransfer) == 1 then
		createFuncBtn('ACCOUNT_MIGRAT', FUNC_BTN_DEFINE.ACCOUNT_MIGRAT, handler(self, self.onClickAccountMigratButtonHandler_))
	end
	-------------------------------------------------\
	-- check activityIcon
	for i, iconData in ipairs(gameManager:GetUserInfo().activityHomeIconData or {}) do
		if iconData.type == ACTIVITY_TYPE.SUMMER_ACTIVITY then
			local summerActivityTime = checkint(gameManager:GetUserInfo().summerActivity)
			if summerActivityTime > 0 then
				local imgPath = string.format('ui/home/nmain/%s',  tostring(iconData.icon))
				-- btnName 先写死
				local btnName = 'SUMMER_ACTIVITY'
				local btnData = {title = tostring(checktable(iconData.iconTitle)[i18n.getLang()]), image = _res(imgPath), tag = RemindTag.SUMMER_ACTIVITY, countdown = true}
				createFuncBtn(btnName, btnData, handler(self, self.onClickSummerActivityButtonHandler_))
			end

		elseif iconData.type == ACTIVITY_TYPE.SP_ACTIVITY then
			local imgPath = string.format('ui/home/nmain/%s',  tostring(iconData.icon))
			local btnName = app.activityMgr:GetHomeActivityIconTimerName(iconData.activityId, iconData.type)
			local btnData = {title = tostring(checktable(iconData.iconTitle)[i18n.getLang()]), image = _res(imgPath), spine = 'effects/shangdian', countdown = true, redIcon = true, tag = RemindTag.SP_ACTIVITY}
			createFuncBtn(btnName, btnData, handler(self, self.onClickSpActivityButtonHandler_))

		elseif  iconData.type == ACTIVITY_TYPE.EXCHANGE_CARD  then
			if app.activityMgr:getExchangeCardActivityIsShow(iconData.leftSeconds) then
				local imgPath = string.format('ui/home/nmain/%s',  tostring(iconData.icon))
				local btnName = app.activityMgr:GetHomeActivityIconTimerName(iconData.activityId, iconData.type)
				local btnData = {title = tostring(checktable(iconData.iconTitle)[i18n.getLang()]), image = _res(imgPath), countdown = true}
				createFuncBtn(btnName, btnData, handler(self, self.onClickActivityIconButtonHandler_))
			end

		elseif iconData.type == ACTIVITY_TYPE.MURDER then
			local imgPath = string.format('ui/home/nmain/%s',  tostring(iconData.icon))
			local btnName = app.activityMgr:GetHomeActivityIconTimerName(iconData.activityId, iconData.type)
			local btnData = {title = tostring(checktable(iconData.iconTitle)[i18n.getLang()]), image = _res(imgPath), countdown = true, tag = RemindTag.MURDER, redIcon = true}
			createFuncBtn(btnName, btnData, handler(self, self.onClickMurderButtonHandler_))
		elseif iconData.type == ACTIVITY_TYPE.SPRING_ACTIVITY_20 then
			local imgPath = string.format('ui/home/nmain/%s',  tostring(iconData.icon))
			local btnName = app.activityMgr:GetHomeActivityIconTimerName(iconData.activityId, iconData.type)
			local btnData = {title = tostring(checktable(iconData.iconTitle)[i18n.getLang()]), image = _res(imgPath), countdown = true, tag = RemindTag.SPRING_ACTIVITY_20, redIcon = true}
			createFuncBtn(btnName, btnData, handler(self, self.onClickSpringActivity20ButtonHandler_))
		elseif iconData.type == ACTIVITY_TYPE.ANNIVERSARY_20 then
			local imgPath = string.format('ui/home/nmain/%s',  tostring(iconData.icon))
			local btnName = app.activityMgr:GetHomeActivityIconTimerName(iconData.activityId, iconData.type)
			local btnData = {title = tostring(checktable(iconData.iconTitle)[i18n.getLang()]), image = _res(imgPath), countdown = true, tag = RemindTag.SPRING_ACTIVITY_20, redIcon = true}
			createFuncBtn(btnName, btnData, handler(self, self.onClickAnniversary20ButtonHandler_))
		else
			local imgPath = string.format('ui/home/nmain/%s',  tostring(iconData.icon))
			local btnName = app.activityMgr:GetHomeActivityIconTimerName(iconData.activityId, iconData.type)
			local btnData = {title = tostring(checktable(iconData.iconTitle)[i18n.getLang()]), image = _res(imgPath), countdown = true}
			createFuncBtn(btnName, btnData, handler(self, self.onClickActivityIconButtonHandler_))
		end
	end

	-------------------------------------------------
	-- clean oldExtraBtnList
	for i, funcBtn in ipairs(oldExtraBtnList) do
		if not oldExtraReuseMap[tostring(i)] then
			funcBtn.view:runAction(cc.RemoveSelf:create())
		end
	end

	-- reset nowExtraBtnList
	for i, funcBtn in ipairs(self.extraButtonList_) do
		funcBtn.view:setTag(i)
		
		if funcBtn.countdownBar then
			self:updateExtraBtnCountdownBar_(i)
		end
	end

	-- re-sort all funcBtn
	for i, funcBtn in ipairs(self:getAllFuncBtnList()) do
		funcBtn.view:setPositionX(funcBtnPoint.x - FUNC_BTN_SIZE.width * (i - 0.5))
		funcBtn.view:setPositionY(funcBtnPoint.y)
	end
end


function HomeFuncBar:refreshModuleStatus()
	self:reloadBar()
end


function HomeFuncBar:eraseHideFuncAt(moduleId)
    self.funcHideMap_[tostring(moduleId)] = false
    self:refreshModuleStatus()
end


function HomeFuncBar:getFuncViewAt(moduleId)
    local viewData  = self:getViewData()
    local remindTag = checkint(REMIND_TAG_MAP[tostring(moduleId)])
	return self:getViewData().funcBtnLayer:getChildByTag(remindTag)
end


-------------------------------------------------
-- private method

function HomeFuncBar:upateRemindStatus_(remindIcon)
    if remindIcon then
        remindIcon:UpdateLocalData()
    end
end


function HomeFuncBar:updateExtraBtnCountdownBar_(index)
	local funcBtn = self.extraButtonList_[index]
	if funcBtn and funcBtn.countdownBar then
		local timerMgr  = AppFacade.GetInstance():GetManager('TimerManager')
		local timerInfo = timerMgr:RetriveTimer(funcBtn.view:getName()) or {}
		local nowTime   = checkint(timerInfo.countdown)
		local endTime   = checkint(timerInfo.timeNum)
		if 0 >= nowTime then
			display.commonLabelParams(funcBtn.countdownBar, {text = __('已结束')})
		else
			display.commonLabelParams(funcBtn.countdownBar, {text = CommonUtils.getTimeFormatByType(nowTime, 2)})
		end
	end
end


-------------------------------------------------
-- handler

function HomeFuncBar:onCleanup()
    AppFacade.GetInstance():UnRegistObserver(COUNT_DOWN_ACTION, self)
end


function HomeFuncBar:onTimerCountdownHandler_(signal)
	local dataBody     = signal:GetBody()
	local timerTag     = dataBody.tag
	local timerName    = tostring(dataBody.timerName)
	local funcBtnLayer = self:getViewData().funcBtnLayer
	local funcBtnNode  = funcBtnLayer:getChildByName(timerName)
	local funcBtnIndex = funcBtnNode and funcBtnNode:getTag() or 0
	self:updateExtraBtnCountdownBar_(funcBtnIndex)
end


function HomeFuncBar:onClickShopButtonHandler_(sender)
    PlayAudioByClickNormal()
	if not self:isHomeControllable() or not self.isControllable_ then return end

	self:upateRemindStatus_(sender:getChildByTag(checkint(sender:getTag())))
	
	if GAME_MODULE_OPEN.NEW_STORE then
		app.uiMgr:showGameStores()
	else
		self:getAppRouter():Dispatch({name = 'HomeMediator'}, {name = 'ShopMediator'})
	end
end


function HomeFuncBar:onClickActivityButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self:isHomeControllable() or not self.isControllable_ then return end
	if not GuideUtils.CheckFuncEnabled(GUIDE_ENABLE_FUNC.HOME_FUNC_BAR_NORMAL) then return end

	self:upateRemindStatus_(sender:getChildByTag(checkint(sender:getTag())))
	self:getAppRouter():Dispatch({name = 'HomeMediator'}, {name = 'ActivityMediator'})
end


function HomeFuncBar:onClickFriendsButtonHandler_(sender)
	PlayAudioByClickNormal()
	if not self:isHomeControllable() or not self.isControllable_ then return end
	if not GuideUtils.CheckFuncEnabled(GUIDE_ENABLE_FUNC.HOME_FUNC_BAR_NORMAL) then return end

	self:upateRemindStatus_(sender:getChildByTag(checkint(sender:getTag())))
	self:getAppRouter():Dispatch({name = 'HomeMediator'}, {name = 'FriendMediator'})
end


function HomeFuncBar:onClickMailButtonHandler_(sender)
    PlayAudioByClickNormal()
	if not self:isHomeControllable() or not self.isControllable_ then return end

	if not GuideUtils.CheckFuncEnabled(GUIDE_ENABLE_FUNC.HOME_FUNC_BAR_NORMAL) then return end

	self:upateRemindStatus_(sender:getChildByTag(checkint(sender:getTag())))
	self:getAppRouter():Dispatch({name = 'HomeMediator'}, {name = 'NoticeMediator'})
end
function HomeFuncBar:onClickStrongerButtonHandler_(sender)
	PlayAudioByClickNormal()

	if not self:isHomeControllable() or not self.isControllable_ then return end

	if not GuideUtils.CheckFuncEnabled(GUIDE_ENABLE_FUNC.HOME_FUNC_BAR_NORMAL) then return end

	self:upateRemindStatus_(sender:getChildByTag(checkint(sender:getTag())))
	local mediator = require("Game.mediator.sunFlowerBible.SunFlowerBibleMediator").new()
	app:RegistMediator(mediator)
end


function HomeFuncBar:onClickRecallButtonHandler_(sender)
    PlayAudioByClickNormal()
	if not self:isHomeControllable() or not self.isControllable_ then return end
	if not GuideUtils.CheckFuncEnabled(GUIDE_ENABLE_FUNC.HOME_FUNC_BAR_NORMAL) then return end

	self:upateRemindStatus_(sender:getChildByTag(checkint(sender:getTag())))
    self:getAppRouter():Dispatch({name = 'HomeMediator'}, {name = 'RecallMainMediator'})
end


function HomeFuncBar:onClickAddPayButtonHandler_(sender)
    PlayAudioByClickNormal()
	if not self:isHomeControllable() or not self.isControllable_ then return end
	if not GuideUtils.CheckFuncEnabled(GUIDE_ENABLE_FUNC.HOME_FUNC_BAR_NORMAL) then return end

	self:upateRemindStatus_(sender:getChildByTag(checkint(sender:getTag())))
    self:getAppRouter():Dispatch({name = 'HomeMediator'}, {name = 'CumulativeRechargeMediator'})
end


function HomeFuncBar:onClickReturnWelfareButtonHandler_(sender)
	PlayAudioByClickNormal()
	if not self:isHomeControllable() or not self.isControllable_ then return end
	if not GuideUtils.CheckFuncEnabled(GUIDE_ENABLE_FUNC.HOME_FUNC_BAR_NORMAL) then return end

	local gameMgr  = app.gameMgr
	if gameMgr:CheckIsBackOpen() then
		self:getAppRouter():Dispatch({name = 'HomeMediator'}, {name = 'returnWelfare.ReturnWelfareMediator'})
	else
		local uiMgr = app.uiMgr
		uiMgr:ShowInformationTips(__('活动已过期'))
	end
end


function HomeFuncBar:onClickSaiMoeButtonHandler_(sender)
    PlayAudioByClickNormal()
	if not self:isHomeControllable() or not self.isControllable_ then return end
	if not GuideUtils.CheckFuncEnabled(GUIDE_ENABLE_FUNC.HOME_FUNC_BAR_NORMAL) then return end

	local callback = function ()
		local appIns   = AppFacade.GetInstance()
		local gameMgr  = app.gameMgr
		if gameMgr:GetUserInfo().comparisonActivity > 0 then
			AppFacade.GetInstance():RetrieveMediator("AppMediator"):SendSignal(POST.SAIMOE_HOME.cmdName)
		else
			local uiMgr = appIns:GetManager('UIManager')
			uiMgr:ShowInformationTips(__('活动已过期'))
		end
	end
	local storyTag = checkint(CommonUtils.getLocalDatas(app.summerActMgr:getCarnieThemeActivityStoryFlagByChapterId('1')))
	if storyTag > 0 then
		callback()
	else
		CommonUtils.setLocalDatas(1, app.summerActMgr:getCarnieThemeActivityStoryFlagByChapterId('1'))
		local path = string.format("conf/%s/cardComparison/comparisonStory.json",i18n.getLang())
		local stage = require( "Frame.Opera.OperaStage" ).new({id = 1, path = path, guide = true, isHideBackBtn = true, cb = callback})
		stage:setPosition(cc.p(display.cx,display.cy))
		sceneWorld:addChild(stage, GameSceneTag.Dialog_GameSceneTag)
	end
end


function HomeFuncBar:onClickNewbieTaskButtonHandler_(sender)
	PlayAudioByClickNormal()
	if not self:isHomeControllable() or not self.isControllable_ then return end
	if not GuideUtils.CheckFuncEnabled(GUIDE_ENABLE_FUNC.HOME_FUNC_BAR_NORMAL) then return end
	
	self:upateRemindStatus_(sender:getChildByTag(checkint(sender:getTag())))
	
	local gameManager = AppFacade.GetInstance():GetManager('GameManager')
	if checkint(gameManager:GetUserInfo().newbieTaskRemainTime) > 0 then
		self:getAppRouter():Dispatch({name = 'HomeMediator'}, {name = 'ActivityNewPlayerSevenDayMediator'})
	else
		local uiManager = AppFacade.GetInstance():GetManager('UIManager')
		uiManager:ShowInformationTips(__('活动任务已结束'))
	end
end


function HomeFuncBar:onClickLevelChestButtonHandler_(sender)
	PlayAudioByClickNormal()
	if not self:isHomeControllable() or not self.isControllable_ then return end
	if not GuideUtils.CheckFuncEnabled(GUIDE_ENABLE_FUNC.HOME_FUNC_BAR_NORMAL) then return end
	
	self:getAppRouter():Dispatch({name = 'HomeMediator'}, {name = 'ActivityMediator', params = { activityId = ACTIVITY_TYPE.LEVEL_GIFT}})
end


function HomeFuncBar:onClickSummerActivityButtonHandler_(sender)
	PlayAudioByClickNormal()
	if not self:isHomeControllable() or not self.isControllable_ then return end
	if not GuideUtils.CheckFuncEnabled(GUIDE_ENABLE_FUNC.HOME_FUNC_BAR_NORMAL) then return end
	if not CommonUtils.UnLockModule(JUMP_MODULE_DATA.SUMMER_ACTIVITY, true) then return end

	app.summerActMgr:ShowSAHomeUI()
end


function HomeFuncBar:onClickSpActivityButtonHandler_(sender)
	PlayAudioByClickNormal()
	if not self:isHomeControllable() or not self.isControllable_ then return end
	if not GuideUtils.CheckFuncEnabled(GUIDE_ENABLE_FUNC.HOME_FUNC_BAR_NORMAL) then return end

	self:getAppRouter():Dispatch({name = 'HomeMediator'}, {name = 'specialActivity.SpActivityMediator'})
end


function HomeFuncBar:onClickMurderButtonHandler_(sender)
	PlayAudioByClickNormal()
	if not CommonUtils.UnLockModule(JUMP_MODULE_DATA.MURDER, true) then return end
	if not GuideUtils.CheckFuncEnabled(GUIDE_ENABLE_FUNC.HOME_FUNC_BAR_NORMAL) then return end
	self:getAppRouter():Dispatch({name = 'HomeMediator'}, {name = 'activity.murder.MurderHomeMediator'})
end

function HomeFuncBar:onClickSpringActivity20ButtonHandler_(sender)
	PlayAudioByClickNormal()
	if not GuideUtils.CheckFuncEnabled(GUIDE_ENABLE_FUNC.HOME_FUNC_BAR_NORMAL) then return end
	self:getAppRouter():Dispatch({name = 'HomeMediator'}, {name = 'springActivity20.SpringActivity20HomeMediator', params = {animation = 1}})
end

function HomeFuncBar:onClickLimitGiftIconButtonHandler_(sender)
	PlayAudioByClickNormal()
	if not self:isHomeControllable() or not self.isControllable_ then return end
	if not GuideUtils.CheckFuncEnabled(GUIDE_ENABLE_FUNC.HOME_FUNC_BAR_NORMAL) then return end
	
	local funcBtnName  = tostring(sender:getName())
	local nameDataList = string.split(funcBtnName, '_')
	local productId    = checkint(nameDataList[3])
	local uiTplId      = checkint(nameDataList[5])
	local gameManager  = AppFacade.GetInstance():GetManager('GameManager')
	for i, chestData in ipairs(gameManager:GetUserInfo().triggerChest or {}) do
		if checkint(chestData.productId) == productId and checkint(chestData.uiTplId) == uiTplId then
			local mediator = require('Game.mediator.LimitGiftMediator').new(chestData)
			AppFacade.GetInstance():RegistMediator(mediator)
			break
		end
	end
end


function HomeFuncBar:onClickActivityIconButtonHandler_(sender)
	PlayAudioByClickNormal()
	if not self:isHomeControllable() or not self.isControllable_ then return end
	if not GuideUtils.CheckFuncEnabled(GUIDE_ENABLE_FUNC.HOME_FUNC_BAR_NORMAL) then return end
	
	local funcBtnName  = tostring(sender:getName())
	local nameDataList = string.split(funcBtnName, '_')
	local activityId   = checkint(nameDataList[2])
	local activityType = checkint(nameDataList[3])
	local gameManager  = AppFacade.GetInstance():GetManager('GameManager')
	for i, activityData in ipairs(gameManager:GetUserInfo().activityHomeIconData or {}) do
		if ACTIVITY_MEDIATOR[tostring(activityType)] then
			local activityTable = ACTIVITY_MEDIATOR[tostring(activityType)]
			if activityTable.routerPath then
				app.router:Dispatch({name = 'HomeMediator'}, {name = activityTable.routerPath, params = {activityId = activityId}})
			else
				local actMdtClass = require(activityTable.mediatorPath)
				app:RegistMediator(actMdtClass.new({activityId = activityId}))
			end
			if activityTable.callback then
				activityTable.callback()
			end
			break
		elseif ACTIVITY_ROUTER_MEDIATOR[tostring(activityType)] then

			-- 检查活动是否结束
			if app.activityMgr:CheckActivityEndByTimerName(funcBtnName) then break end

			local extraParams = {activityId = activityId, activityType = activityType}
			self:getAppRouter():Dispatch({name = 'HomeMediator', params = extraParams}, {name = ACTIVITY_ROUTER_MEDIATOR[tostring(activityType)], params = extraParams}, {isBack = true})
			break
		elseif tostring(activityType) == ACTIVITY_TYPE.ANNIVERSARY then
			app.anniversaryMgr:EnterAnniversary()
		else
			if checkint(activityData.activityId) == activityId and checkint(activityData.type) == activityType then
				self:getAppRouter():Dispatch({name = 'HomeMediator'}, {name = 'ActivityMediator', params = {activityId = activityId}})
				break
			end
		end

	end
end

function HomeFuncBar:onClickArtifactGuideButtonHandler_(sender)
	PlayAudioByClickNormal()
	if not self:isHomeControllable() or not self.isControllable_ then return end
	if not GuideUtils.CheckFuncEnabled(GUIDE_ENABLE_FUNC.HOME_FUNC_BAR_NORMAL) then return end

	self:getAppRouter():Dispatch({name = 'HomeMediator'}, {name = 'artifactGuide.ArtifactGuideMediator'})
end

function HomeFuncBar:onClickFirstPayButtonHandler_(sender)
	PlayAudioByClickNormal()
	if not self:isHomeControllable() or not self.isControllable_ then return end
	if not GuideUtils.CheckFuncEnabled(GUIDE_ENABLE_FUNC.HOME_FUNC_BAR_NORMAL) then return end

	local activityFirstTopupPopupMediator = require('Game.mediator.activity.popup.ActivityFirstTopupPopupMediator').new()
	AppFacade.GetInstance():RegistMediator(activityFirstTopupPopupMediator)
end

function HomeFuncBar:onClickNoviceWelfareButtonHandler_(sender)
	PlayAudioByClickNormal()
	if not self:isHomeControllable() or not self.isControllable_ then return end
	if not GuideUtils.CheckFuncEnabled(GUIDE_ENABLE_FUNC.HOME_FUNC_BAR_NORMAL) then return end
	local mediator = require('Game.mediator.activity.noviceWelfare.NoviceWelfareMediator').new()
	app:RegistMediator(mediator)
end

function HomeFuncBar:onClickAnniversary20ButtonHandler_(sender)
	PlayAudioByClickNormal()
	if not self:isHomeControllable() or not self.isControllable_ then return end
	if not GuideUtils.CheckFuncEnabled(GUIDE_ENABLE_FUNC.HOME_FUNC_BAR_NORMAL) then return end
	app.router:Dispatch({name = 'HomeMediator'}, {name = 'anniversary20.Anniversary20HomeMediator'})
end


function HomeFuncBar:onClickAccountMigratButtonHandler_(sender)
	PlayAudioByClickNormal()
	if not self:isHomeControllable() or not self.isControllable_ then return end
	if not GuideUtils.CheckFuncEnabled(GUIDE_ENABLE_FUNC.HOME_FUNC_BAR_NORMAL) then return end
	
	app.router:Dispatch({name = 'HomeMediator'}, {name = 'AccountMigrationMediator'})
end


return HomeFuncBar

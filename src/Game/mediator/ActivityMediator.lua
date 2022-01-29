--[[
活动Mediator
--]]
local Mediator = mvc.Mediator

local ActivityMediator = class("ActivityMediator", Mediator)

local NAME = "ActivityMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
---@type GameManager
local gameMgr = AppFacade.GetInstance('AppFacade'):GetManager("GameManager")
local scheduler = require('cocos.framework.scheduler')
local ActivityDailyBonusCell = require('home.ActivityDailyBonusCell')
local ActivityNoviceBonusCell = require('home.ActivityNoviceBonusCell')
local ActivityLoginRewardCell = require('home.ActivityLoginRewardCell')
local ActivityHoneyBentoCell = require('home.ActivityHoneyBentoCell')
local CapsuleNewMediator     = require('Game.mediator.drawCards.CapsuleNewMediator')
local SpActivityMediator     = require('Game.mediator.specialActivity.SpActivityMediator')

local ACTIVITY_TAB_HIDE = {
	[ACTIVITY_TYPE.LUCKY_WHEEL]     	    = true,
	[ACTIVITY_TYPE.LOBBY_ACTIVITY_PREVIEW]  = true,
	[ACTIVITY_TYPE.SP_ACTIVITY]             = true,
	-- 商城活动屏蔽
	[ACTIVITY_TYPE.STORE_DIAMOND_LIMIT]     = true,
	[ACTIVITY_TYPE.STORE_MEMBER_PACK]       = true,
	[ACTIVITY_TYPE.STORE_GIFTS_MONEY]       = true,
	[ACTIVITY_TYPE.STORE_OTHER_LIMIT]       = true,
}
-- 显示的抽卡类型
local ACTIVITY_TAB_CAPSULE_SHOW = {
	[ACTIVITY_TYPE.DRAW_SKIN_POOL]   = true,
	[ACTIVITY_TYPE.DRAW_CARD_CHOOSE] = true,
	[ACTIVITY_TYPE.DRAW_RANDOM_POOL] = true,
	[ACTIVITY_TYPE.BINARY_CHOICE]    = true,
}
for drawCardType, _ in pairs(CapsuleNewMediator.DRAW_TYPE_DEFINE) do
	if not ACTIVITY_TAB_CAPSULE_SHOW[drawCardType] then
		ACTIVITY_TAB_HIDE[drawCardType] = true
	end
end

function ActivityMediator:ctor( params, viewComponent )
	self.super:ctor(NAME,viewComponent)
	self.datas = params or {}
	self.selectedTab = checkint(self.datas.activityId)
	self.activityTabDatas = {} -- 开放的活动
	self.showLayer = {}
	self.showMediatorName = {}
	self.activityDatas = {} -- 活动数据
	self.activityHomeDatas = {}
	self.curLevelData = {} -- 当前的等级礼包
	self.activityPreTimes = {}  -- 用于保存活动时间
	self.isReceiveResponse = false -- 表示 是否接受到 餐厅活动响应
	self.isControllable_ = true
end

function ActivityMediator:InterestSignals()
	local signals = {
		SIGNALNAMES.Activity_Home_Callback,
		SIGNALNAMES.Activity_Newbie15Day_Callback,
		SIGNALNAMES.Activity_Draw_Newbie15Day_Callback,
		SIGNALNAMES.Activity_MonthlyLogin_Callback,
		SIGNALNAMES.Activity_Draw_MonthlyLogin_Callback,
		SIGNALNAMES.Activity_MonthlyLoginWheel_Callback,
		SIGNALNAMES.Activity_Draw_MonthlyLoginWheel_Callback,
		SIGNALNAMES.Restaurant_Shop_GetPayOrder_Callback,
		SIGNALNAMES.Activity_Draw_LoveBento_Callback,
		SIGNALNAMES.Activity_Draw_serverTask_Callback,
		SIGNALNAMES.Activity_ChargeWheel_Callback,
		SIGNALNAMES.Activity_Draw_ChargeWheel_Callback,
		SIGNALNAMES.Activity_Draw_ExchangeList_Callback,
		SIGNALNAMES.Activity_TaskBinggoList_Callback,
		SIGNALNAMES.Activity_DrawBinggoTask_Callback,
		SIGNALNAMES.Activity_AccumulativePay_Callback,
		SIGNALNAMES.Activity_AccumulativeConsume_Callback,
		SIGNALNAMES.Activity_Draw_AccumulativeConsume_Callback,
		SIGNALNAMES.Activity_Quest_Home_Callback,
        EVENT_PAY_MONEY_SUCCESS_UI,
		POST.LEVEL_GIFT_CHEST.sglName,
		POST.Activity_Draw_restaurant.sglName,
		--POST.ACTIVITY_DRAW_FIRSTPAY.sglName ,
		SIGNALNAMES.Activity_TakeawayPoint_Callback,
		SIGNALNAMES.Activity_Chest_ExchangeList_Callback,
		SIGNALNAMES.Activity_Chest_Exchange_Callback,
		SIGNALNAMES.Activity_Login_Reward_Callback,
		SIGNALNAMES.Activity_Draw_Login_Reward_Callback,
		SGL.REFRESH_NOT_CLOSE_GOODS_EVENT, -- 道具变更
		REFRESH_FULL_SERVER_EVENT,    -- 全服活动 长连接通知
		REFRESH_ACCUMULATIVE_RECHARGE_EVENT, -- 累充活动 长连接通知
		REFRESH_ACCUMULATIVE_CONSUME_EVENT, -- 累消活动 长连接通知
		ACTIVITY_RED_REGRESH_EVENT,
		ACTIVITY_WHEEL_EXCHANGE_CLEAR, -- 转盘活动兑换完成
		SIGNALNAMES.Activity_Quest_Exchange_Callback, -- 活动副本兑换成功
		SIGNALNAMES.Activity_Questionnaire_Callback, -- 问卷活动home
		SIGNALNAMES.Activity_Balloon_Home_Callback, -- 打气球活动home
		SIGNALNAMES.Activity_SinglePay_Home_Callback, -- 单笔充值活动home
		SIGNALNAMES.Activity_Permanent_Single_Pay_Callback, -- 常驻单笔充值活动home
		SIGNALNAMES.Activity_Web_Home_Callback, -- web跳转活动home
		SGL.CLOSE_3V3_MATCH,   -- 关闭3v3
        "APP_STORE_PRODUCTS",
		ACTIVITY_TAB_CLICK,    -- 活动页签点击信号
	}
	return signals
end

function ActivityMediator:ProcessSignal( signal )
	local name = signal:GetName()
	print(name)
	if not  CommonUtils.GetMediatorViewCompentIsExist(self) then
		return
	end
	if name == SIGNALNAMES.Activity_Home_Callback then
		local BASE_ACTIVITY = {
			{title = __('首充奖励'), activityId = -3, type = ACTIVITY_TYPE.FIRST_PAYMENT, isOpen = isOpen, showRemindIcon = 0},
			{title = __('新手福利集结'), activityId = -7, type = ACTIVITY_TYPE.PERMANENT_SINGLE_PAY, isOpen = GAME_MODULE_OPEN.NEW_NOVICE_ACC_PAY and checkint(gameMgr:GetUserInfo().permanentSinglePay), showRemindIcon = checkint(gameMgr:GetUserInfo().tips.permanentSinglePay)},
			{title = __('新手超值福利'), activityId = ACTIVITY_TYPE.NOVICE_ACCUMULATIVE_PAY, type = ACTIVITY_TYPE.NOVICE_ACCUMULATIVE_PAY, isOpen = GAME_MODULE_OPEN.NEW_NOVICE_ACC_PAY and checkint(gameMgr:GetUserInfo().newbieAccumulativePay), showRemindIcon = checkint(gameMgr:GetUserInfo().tips.newbieAccumulatePay)},
			{title = __('15日签到'), activityId = -2, type = ACTIVITY_TYPE.NOVICE_BONUS, isOpen = checkint(gameMgr:GetUserInfo().newbie15Day), showRemindIcon = checkint(gameMgr:GetUserInfo().tips.newbie15Day)},
			{title = __('爱心便当'), activityId = -5, type = ACTIVITY_TYPE.HONEY_BENTO, isOpen = 1, showRemindIcon = self:HoneyBentoIsShowRemind()},
			{title = __('成长基金'), activityId = ACTIVITY_ID.GROWTH_FUND , type = ACTIVITY_TYPE.GROWTH_FUND, isOpen = (checktable(GAME_MODULE_OPEN).GROWTH_FUND or checkint(app.gameMgr:GetUserInfo().payLevelRewardOpened) > 0) and (checkint(checktable(app.gameMgr:GetUserInfo().growthFundCacheData_).isOpen) > 0 and 1 or 0) or 0, showRemindIcon = 0},
			{title = __('神秘手提箱'), activityId = ACTIVITY_ID.LEVEL_ADVANCE_CHEST , type = ACTIVITY_TYPE.LEVEL_ADVANCE_CHEST, isOpen = (checkint(gameMgr:GetUserInfo().levelAdvanceChest) == 1 and self:CheckLevelAdvanceChestIsOpen() == 1) and 1 or 0, showRemindIcon = checkint(gameMgr:GetUserInfo().tips.levelAdvanceChest)},
			{title = __('成长的守候'), activityId = ACTIVITY_ID.LEVEL_REWARD , type = ACTIVITY_TYPE.LEVEL_REWARD, isOpen = (CommonUtils.GetModuleAvailable(MODULE_SWITCH.LEVEL_REWARD) and gameMgr:GetUserInfo().levelReward == 1) and 1 or 0, showRemindIcon = checkint(gameMgr:GetUserInfo().tips.levelReward)},
			{title = __('新手签到'), activityId = ACTIVITY_ID.PAY_LOGIN_REWARD , type = ACTIVITY_TYPE.PAY_LOGIN_REWARD, isOpen = (checktable(GAME_MODULE_OPEN).PAY_LOGIN_REWARD and checkint(gameMgr:GetUserInfo().isPayLoginRewardsOpen) > 0) and 1 or 0, showRemindIcon = 0},
			{title = __('活跃报告'), activityId = ACTIVITY_ID.CONTINUOUS_ACTIVE , type = ACTIVITY_TYPE.CONTINUOUS_ACTIVE, isOpen = (CommonUtils.GetModuleAvailable(MODULE_SWITCH.CONTINUOUS_ACTIVE) and CommonUtils.UnLockModule(RemindTag.TASK)) and 1 or 0, showRemindIcon = checkint(gameMgr:GetUserInfo().tips.continuousActive)},
			{title = __('巅峰对决'), activityId = ACTIVITY_ID.ULTIMATE_BATTLE , type = ACTIVITY_TYPE.ULTIMATE_BATTLE, isOpen = (CommonUtils.UnLockModule(JUMP_MODULE_DATA.ULTIMATE_BATTLE) and checkint(gameMgr:GetUserInfo().isUltimateBattleOpen) > 0) and 1 or 0, showRemindIcon = 0},
		}
		if GAME_MODULE_OPEN.NEW_LEVEL_REWARD then 
			for i, v in ipairs(BASE_ACTIVITY) do
				 if v.type == ACTIVITY_TYPE.LEVEL_REWARD then
					v.title = __('五祀之礼')
					break
				 end
			end
		end
		if gameMgr:GetUserInfo().levelChest then
			table.insert(BASE_ACTIVITY , 5,{title = __('米饭的心意'),activityId = -4 , type = ACTIVITY_TYPE.LEVEL_GIFT, isOpen = 1 , showRemindIcon = 0})
		end
		if CommonUtils.UnLockModule(RemindTag.TAG_MATCH) and gameMgr.get3v3MatchBattleData and next(gameMgr:get3v3MatchBattleData()) ~= nil and gameMgr:get3v3MatchBattleData().section ~= MATCH_BATTLE_3V3_TYPE.CLOSE
			and CommonUtils.GetModuleAvailable(MODULE_SWITCH.TAG_MATCH) and not GAME_MODULE_OPEN.NEW_TAG_MATCH then
			table.insert(BASE_ACTIVITY, {title = __('天城演武'), activityId = ACTIVITY_ID.TAG_MATCH, type = ACTIVITY_TYPE.TAG_MATCH, isOpen = 1 , showRemindIcon = 0})
		end
		if CommonUtils.UnLockModule(RemindTag.NEW_TAG_MATCH) and GAME_MODULE_OPEN.NEW_TAG_MATCH then
			table.insert(BASE_ACTIVITY, {title = __('天成演武'), activityId = ACTIVITY_ID.NEW_TAG_MATCH, type = ACTIVITY_TYPE.NEW_TAG_MATCH, isOpen = 1 , showRemindIcon = 0})
		end
		local datas = checktable(signal:GetBody())
		app.activityMgr:UpdateActivity(clone(datas))
		self.activityTabDatas = {}
		self.activityHomeDatas = {}
		self.activityPreTimes = {}
		local function getRedPointState(type, tip)
			if type == ACTIVITY_TYPE.SEASONG_LIVE then -- 季活的活动
				local index =  0
				if app.activityMgr:JudageSeasonFoodIsReward()  == 1 then
					return 1
				end
				if checkint(gameMgr:GetUserInfo().tips.seasonActivity)  ==1 then
					return 1
				end
				return index
			else
				return checkint(tip)
			end
			return 0
		end
		-- 初始化页签信息
		for i,v in ipairs(BASE_ACTIVITY) do
			if checkint(v.isOpen) == 1 then
				table.insert(self.activityTabDatas, v)
			end
		end

		for i, v in ipairs(checktable(datas.activity)) do
			self.activityPreTimes[tostring(v.activityId)] = os.time()
			v.leftSeconds = checkint(v.leftSeconds) + 1
			self.activityHomeDatas[tostring(v.activityId)] = v

			if (not ACTIVITY_TAB_HIDE[v.type] and  (v.type ~=  ACTIVITY_TYPE.DOUNBLE_EXP_NORMAL
					and  v.type ~=  ACTIVITY_TYPE.DOUNBLE_EXP_HARD
					and v.type ~=  ACTIVITY_TYPE.TEAM_QUEST_ACTIVITY )) then
				local temp = {}
				temp.title = v.title[i18n.getLang()]
				temp.detail = v.detail[i18n.getLang()]
				temp.type = v.type
				temp.activityId = v.activityId
				temp.isNew = checkint(v.isNew)
				temp.showRemindIcon = getRedPointState(temp.type, v.tip)
				temp.relatedRemindIcon = app.badgeMgr:GetRelatedIsShowRemind(datas.activity, v)
				temp.relatedActivityId = v.relatedActivityId
				-- 获取特殊活动(周年庆)开启时间
				local spOpenTime = self:GetSpActivityOpenTime(datas.activity)
				if spOpenTime and SpActivityMediator.ACTIVITY_TYPE_DEFINE[tostring(v.type)] then
					if v.fromTime < spOpenTime then
						-- 在特殊活动开启之前的活动也不进入特殊活动页面
						table.insert(self.activityTabDatas, temp)
					end
				else
					table.insert(self.activityTabDatas, temp)
				end
			end
			if v.type == ACTIVITY_TYPE.SUMMER_ACTIVITY then
				app.activityMgr:StopSummerActivityTimer()
				gameMgr:GetUserInfo().summerActivity = v.leftSeconds
				app.activityMgr:AddSummerActivityTimer()
			end
			-- pt本需要倒计时
			if v.type == ACTIVITY_TYPE.PT_DUNGEON then
				app.activityMgr:StopPTDungeonTimer()
				gameMgr:GetUserInfo().PTDungeonTimerActivityTime = v.leftSeconds
				app.activityMgr:AddPTDungeonTimer()
			end
			------------关联活动-------------
			if self.selectedTab == checkint(v.activityId) then
				if v.type == ACTIVITY_TYPE.LUCKY_WHEEL then
					self.selectedTab = -1
				end
			end
			--------------------------------
		end
		-- 每日签到
		table.insert(self.activityTabDatas, {title = __('每日签到'), activityId = -1, type = ACTIVITY_TYPE.DAILY_BONUS, isOpen = 1, showRemindIcon = checkint(gameMgr:GetUserInfo().tips.monthlyLogin)})
		-- 创建时间定时器
		-- if next(self.activityHomeDatas) ~= nil then
		-- self.activityPreTimes.Home = os.time()
		if not self.activityEndTimeScheduler then
			self.activityEndTimeScheduler = scheduler.scheduleGlobal(handler(self, self.UpdateActivityTime), 1)
		end

		local viewData = self:GetViewComponent().viewData
		-- 初始化tabViewData
		self:InitTabViewData()
		self:InitSelectedTab()
		viewData.activityTabView:InitView({activityClassDataList = self.tabViewData, activityId = self.selectedTab})
		viewData.activityTabView:SetEnabled(true)
		-- 判断活动弹出页
		self:ShowActivtityPopup()
		-- 移除屏蔽层
		uiMgr:GetCurrentScene():RemoveViewForNoTouch()
		self.isControllable_ = true
	elseif name == ACTIVITY_TAB_CLICK then
		local body = signal:GetBody()
		self:TabButtonCallback(body.activityId)
	elseif name == SIGNALNAMES.Activity_MonthlyLogin_Callback then
		-- 每日签到
		local datas = checktable(signal:GetBody())
		if datas and datas.content and table.nums(datas.content) > 0 then
			self.activityDatas[tostring(ACTIVITY_TYPE.DAILY_BONUS)] = datas
			self:RefreshDailyBonusView(datas)
			if datas.hasTodayDrawn and checkint(datas.hasTodayDrawn) == 0 then
				self:SendSignal(COMMANDS.COMMAND_Activity_Draw_monthlyLogin)
			end
		end
	elseif name == SIGNALNAMES.Activity_Draw_MonthlyLogin_Callback then
		-- 每日签到领奖
		local datas = checktable(signal:GetBody())
		uiMgr:AddDialog('common.RewardPopup', {rewards = datas.rewards, msg = __('恭喜获得今日签到奖励'), closeCallback = handler(self, self.DrawDailyBonusAction)})
		-- 判断转盘活动是否开启
		local dailyBonusDatas = self.activityDatas[tostring(ACTIVITY_TYPE.DAILY_BONUS)]
		if dailyBonusDatas.activity and next(checktable(dailyBonusDatas.activity)) ~= nil then
			-- 转盘活动开启
			for k,v in pairs(dailyBonusDatas.activity) do
				local activityDailyBonusView = self.showLayer[tostring(ACTIVITY_TYPE.DAILY_BONUS)]
				local viewData = activityDailyBonusView.viewData_
				v.leftDrawnTimes = v.leftDrawnTimes + 1
				display.reloadRichLabel(viewData.turntableNum, {c = {
					{text = tostring(v.leftDrawnTimes), fontSize = 22, color = '#ffcf2a'},
					{text = '/' .. tostring(v.wheeledCircle), fontSize = 22, color = '#ffffff'}
				}})
				break
			end
		end
		-- mark dont auto show MonthlyLogin
		gameMgr:GetUserInfo().isShowMonthlyLogin = false
		-- 清除小红点
		if checkint(gameMgr:GetUserInfo().tips.monthlyLogin) == 1 then
			gameMgr:GetUserInfo().tips.monthlyLogin = 0
			self:ClearRemindIcon(checkint(ACTIVITY_TYPE.DAILY_BONUS))
		end
	elseif name == SIGNALNAMES.Activity_Newbie15Day_Callback then
		-- 新手15天签到
		local datas = checktable(signal:GetBody())
		self.activityDatas[tostring(ACTIVITY_TYPE.NOVICE_BONUS)] = datas
		if not self.noviceBonusScheduler then
			self.activityPreTimes.noviceBonus = os.time()
			self.noviceBonusScheduler = scheduler.scheduleGlobal(handler(self, self.NoviceBonusScheduleCallback), 1)
		end
		self:RefreshNoviceBonusView(datas)
	elseif name == SIGNALNAMES.Activity_Draw_Newbie15Day_Callback then
		-- 新手15天签到领奖
		local datas = checktable(signal:GetBody())
		uiMgr:AddDialog('common.RewardPopup', {rewards = datas.rewards})
		local noviceDatas = self.activityDatas[tostring(ACTIVITY_TYPE.NOVICE_BONUS)]
		noviceDatas.hasTodayDrawn = 1
		self:RefreshNoviceBonusView(noviceDatas)
		-- 清除小红点
		if checkint(gameMgr:GetUserInfo().tips.newbie15Day) == 1 then
			gameMgr:GetUserInfo().tips.newbie15Day = 0
			self:ClearRemindIcon(checkint(ACTIVITY_TYPE.NOVICE_BONUS))
		end
	elseif name == SIGNALNAMES.Activity_MonthlyLoginWheel_Callback then
		-- 幸运大转盘
		local datas = checktable(signal:GetBody())
		self:CreateLuckyWheelView(datas)
	elseif name == SIGNALNAMES.Activity_Draw_MonthlyLoginWheel_Callback then
		-- 幸运大转盘领奖
		local datas = checktable(signal:GetBody())
		self:DrawLuckyWheel(datas)
	elseif name == SIGNALNAMES.Restaurant_Shop_GetPayOrder_Callback then
		local body =   signal:GetBody()
		if signal:GetBody().requestData.name ~= 'levelChest' then return end
		if body.orderNo then
			if device.platform == 'android' or device.platform == 'ios' then
				local AppSDK = require('root.AppSDK')
				local price =  checkint( self.curLevelData.price)
				if checkint(self.curLevelData.discountLeftSeconds) > 0 then
					price = checkint( self.curLevelData.discountPrice)
				end
				AppSDK.GetInstance():InvokePay({amount =  price  , property = body.orderNo, goodsId = tostring(self.curLevelData.channelProductId), goodsName = __('幻晶石'), quantifier = __('个'),price = 0.1, count = 1})
			end
		end
	elseif name == SIGNALNAMES.Activity_Draw_serverTask_Callback then
		local datas = checktable(signal:GetBody())
		local activityId = datas.requestData.activityId

		local rewardList = {}
		local temp = {}
		for i,v in ipairs(datas) do
			for ii,vv in ipairs(checktable(v.rewards)) do
				if temp[vv.goodsId] == nil then
					temp[vv.goodsId] = 1
					table.insert(rewardList, vv)
				end
			end
		end
		self.activityHomeDatas[tostring(activityId)].homeDatas = datas
		self.activityHomeDatas[tostring(activityId)].homeDatas.rewardList = rewardList

		self:CreateFullServerView(activityId)
		-- rewardLayer
	elseif name == SIGNALNAMES.Activity_Draw_ExchangeList_Callback then -- 道具兑换活动
		local datas = checktable(signal:GetBody())
		local activityId = datas.requestData.activityId

		local rewardList = {}
		-- dump(datas, '22Activity_Draw_ExchangeList_Callback')
		local temp = {}
		for i,v in ipairs(datas.exchange) do

			for ii,vv in ipairs(checktable(v.rewards)) do
				if temp[vv.goodsId] == nil then
					temp[vv.goodsId] = 1
					table.insert(rewardList, vv)
				end
			end
		end
		datas.rewardList = rewardList
		self.activityDatas[tostring(activityId)] = datas
		if self.activityHomeDatas[tostring(activityId)] then
			self.activityHomeDatas[tostring(activityId)].homeDatas = datas
			self.activityHomeDatas[tostring(activityId)].homeDatas.rewardList = rewardList
		end
		-- 判断活动是主活动还是关联活动
		if checkint(self.selectedTab) == checkint(activityId) then
			self:CreatePropExchangeView(activityId)
		else
			self:HandleRelatedActivityDatas(activityId)
		end
		-- CreatePropExchangeView
	elseif name == EVENT_PAY_MONEY_SUCCESS_UI then
	elseif name == POST.LEVEL_GIFT_CHEST.sglName then
		self:RefreshLevelChest()
	elseif name == SIGNALNAMES.Activity_Draw_LoveBento_Callback then -- 领取爱心便当
		self:HoneyBentoDrawAction()
	elseif name == REFRESH_FULL_SERVER_EVENT then

		for i,v in ipairs(self.activityTabDatas) do
			local type = tostring(v.type)
			if type == ACTIVITY_TYPE.FULL_SERVER then
				local activityId = v.activityId
				self:UpdateFullServerRedPoint(activityId)
			end
		end
	elseif name == REFRESH_ACCUMULATIVE_RECHARGE_EVENT then
		for i,v in ipairs(self.activityTabDatas) do
			local type = tostring(v.type)
			if type == ACTIVITY_TYPE.CUMULATIVE_RECHARGE then
				local activityId = v.activityId
				self:UpdateAccumulativeRechargeRedPoint(activityId)
			end
		end
	elseif name == REFRESH_ACCUMULATIVE_CONSUME_EVENT then
		for i,v in ipairs(self.activityTabDatas) do
			local type = tostring(v.type)
			if type == ACTIVITY_TYPE.CUMULATIVE_CONSUME then
				local activityId = v.activityId
				self:UpdateAccumulativeConsumeRedPoint(activityId)
			end
		end
	elseif name == SIGNALNAMES.Activity_ChargeWheel_Callback then -- 收费转盘
		local datas = checktable(signal:GetBody())
		local activityId = datas.requestData.activityId

		local rewardList = {}
		local temp = {}
		for i,v in ipairs(datas.rateRewards) do
			for ii,vv in ipairs(checktable(v.rewards)) do
				if temp[vv.goodsId] == nil then
					temp[vv.goodsId] = 1
					table.insert(rewardList, vv)
				end
			end
		end
		datas.rewardList = rewardList
		self.activityDatas[tostring(activityId)] = datas
		if self.activityHomeDatas[tostring(activityId)] then
			self.activityHomeDatas[tostring(activityId)].homeDatas = datas
			self.activityHomeDatas[tostring(activityId)].homeDatas.rewardList = rewardList
		end
		-- 判断活动是主活动还是关联活动
		if checkint(self.selectedTab) == checkint(activityId) then
			self:CreateChargeWheelView(activityId)
		else
			self:HandleRelatedActivityDatas(activityId)
		end
	elseif name == SIGNALNAMES.Activity_Draw_ChargeWheel_Callback then -- 收费转盘抽奖
		local datas = checktable(signal:GetBody())
		self:ChargeWheelDrawAction(datas)
	elseif name == ACTIVITY_WHEEL_EXCHANGE_CLEAR then -- 转盘活动兑换完成
		local activityId = signal:GetBody().activityId
		self:ChargeWheelRemindIconClear(activityId)
	elseif name == POST.Activity_Draw_restaurant.sglName then
		if self.isReceiveResponse then return end
		self.isReceiveResponse = true

		local body = checktable(signal:GetBody())
		local activityId = tostring(body.id)
		self:updateLobbyFestivalActivity(activityId)
	elseif name == SIGNALNAMES.Activity_TakeawayPoint_Callback then -- 外卖点任务
		local datas = checktable(signal:GetBody())
		self.activityDatas[tostring(datas.requestData.activityId)] = datas
		self:CreateTakeawayPointView(datas.requestData.activityId)
	elseif name == SGL.REFRESH_NOT_CLOSE_GOODS_EVENT then
		self:UpdateGoodsEvent()
	elseif name == SIGNALNAMES.Activity_TaskBinggoList_Callback then
		local datas = checktable(signal:GetBody())
		local activityId = datas.requestData.activityId

		local realDatas = self:initBinggoActivityData(datas)
		self:binggoGroupTaskSort(realDatas.allGroupTask)

		realDatas.doneConsumeDayCount = (realDatas.doneConsumeTime - self.activityHomeDatas[tostring(activityId)].fromTime) / 86400 + 1
		realDatas.doneConsumeCD = self.activityHomeDatas[tostring(activityId)].toTime - realDatas.doneConsumeTime
		self.activityHomeDatas[tostring(activityId)].homeDatas = realDatas

		self:CreateBinggoActivity(activityId)
		self:checkBinggoRedPoint(activityId)
	elseif name == SIGNALNAMES.Activity_DrawBinggoTask_Callback then
		local datas = checktable(signal:GetBody())
		local requestData = datas.requestData
		local requestType = requestData.type
		local activityId = requestData.activityId
		if requestType == 1 then
			local rewards = datas.rewards or {}
			if #rewards > 0 then
				uiMgr:AddDialog('common.RewardPopup', {rewards = rewards})
			end

			-- 更新宝箱状态
			local activityHomeData = self.activityHomeDatas[tostring(activityId)]
			if activityHomeData == nil  then return end

			local index     = requestData.index
			local homeData  = activityHomeData.homeDatas
			if homeData and homeData.allGroupTask and homeData.allGroupTask[index] then
				local groupTaskData = homeData.allGroupTask[index]
				groupTaskData.hasDrawn = true
				-- homeData.taskTotalProgress = homeData.taskTotalProgress + 1
				-- 领过组任务 则 减一
				homeData.canReceiveGroupTaskCount = homeData.canReceiveGroupTaskCount - 1
				self:binggoGroupTaskSort(homeData.allGroupTask)
				self:updateBinggoActivity(activityId)

				self:checkBinggoRedPoint(activityId)
			end

		elseif requestType == 2 then
			local view = self.showLayer[tostring(activityId)]
			local homeData = self.activityHomeDatas[tostring(activityId)].homeDatas
			local skinId = homeData.finalRewards[1].goodsId
			view:updateRoleImg(true, skinId)
		end

	elseif name == SIGNALNAMES.Activity_Chest_ExchangeList_Callback then -- 宝箱兑换活动列表
		local datas = checktable(signal:GetBody())
		self.activityDatas[tostring(datas.requestData.activityId)] = datas
		self:CreateChestExchangeView(datas.requestData.activityId)
	elseif name == SIGNALNAMES.Activity_Chest_Exchange_Callback then -- 宝箱兑换活动兑换
		local datas = checktable(signal:GetBody())
		self:ChestExchangeDrawAction(datas)
	elseif name == SIGNALNAMES.Activity_Login_Reward_Callback then -- 登录礼包活动列表
		local datas = checktable(signal:GetBody())
		self.activityDatas[tostring(datas.requestData.activityId)] = datas
		self:CreateLoginRewardView(datas.requestData.activityId)
	elseif name == SIGNALNAMES.Activity_Draw_Login_Reward_Callback then -- 登录礼包活动领取
		local datas = checktable(signal:GetBody())
		self:LoginRewardDrawAction(datas)
		self:ClearRemindIcon(datas.requestData.activityId)
	elseif name == SIGNALNAMES.Activity_AccumulativePay_Callback then -- 累充活动
		local datas = checktable(signal:GetBody())
		self.activityDatas[tostring(datas.requestData.activityId)] = datas
		local activityId = datas.requestData.activityId
		self:CreateAccumulativeRechargeView(activityId)
	elseif name == SIGNALNAMES.Activity_Draw_AccumulativePay_Callback then -- 累充活动领奖
		local datas = checktable(signal:GetBody())
	elseif name == ACTIVITY_RED_REGRESH_EVENT  then
		--[[
			传输数据的格式
			{
				-- 活动的id
				-- 是否显示红点
				activityId =
				showRemindIcon =

			}
		--]]
		local data = signal:GetBody()
		if data.activityId  and data.showRemindIcon then
			local isHave = false
			for  k , v in pairs(self.activityTabDatas) do
				if checkint(v.activityId)  == checkint(data.activityId)  then
					v.showRemindIcon = checkint(data.showRemindIcon)
					isHave = true
					break
				end
			end
			if isHave then
				local viewData = self:GetViewComponent().viewData
				if not self.selectedTab then self.selectedTab = self.activityTabDatas[1].activityId end
				viewData.activityTabView:InitView({activityClassDataList = self.tabViewData, activityId = self.selectedTab})
			end
		end
	elseif name == SIGNALNAMES.Activity_Quest_Home_Callback then -- 活动副本home
		local datas = checktable(signal:GetBody())
		self.activityDatas[tostring(datas.requestData.activityId)] = datas
		self:CreateActivityQuestView(datas.requestData.activityId)
	elseif name == SIGNALNAMES.Activity_Quest_Exchange_Callback then -- 活动副本兑换成功
		local datas = checktable(signal:GetBody())
		self:ActivityQuestExchangeSuccess(datas)
	elseif name == SIGNALNAMES.Activity_AccumulativeConsume_Callback then -- 累消活动
		local datas = checktable(signal:GetBody())
		self.activityDatas[tostring(datas.requestData.activityId)] = datas
		local activityId = datas.requestData.activityId
		self:CreateAccumulativeConsumeView(activityId)
	elseif name == SIGNALNAMES.Activity_Draw_AccumulativeConsume_Callback then -- 累消活动领奖
	elseif name == SIGNALNAMES.Activity_Questionnaire_Callback then -- 问卷活动
		local datas = checktable(signal:GetBody())
		local activityId = datas.requestData.activityId
		self.activityDatas[tostring(datas.requestData.activityId)] = datas
		self:CreateQuestionnaireView(activityId)
	elseif name == SIGNALNAMES.Activity_Balloon_Home_Callback then
		local datas = checktable(signal:GetBody())
		local activityId = datas.requestData.activityId
		self.activityDatas[tostring(datas.requestData.activityId)] = datas
		self:CreateBalloonView(activityId)
	elseif name == SIGNALNAMES.Activity_SinglePay_Home_Callback then -- 单笔充值活动
		local datas = checktable(signal:GetBody())
		local activityId = datas.requestData.activityId
		self.activityDatas[tostring(activityId)] = datas
		self:CreateSinglePayView(activityId)
	elseif name == SIGNALNAMES.Activity_Permanent_Single_Pay_Callback then -- 常驻单笔充值活动
		local datas = checktable(signal:GetBody())
		local activityId = ACTIVITY_TYPE.PERMANENT_SINGLE_PAY
		self.activityDatas[tostring(activityId)] = datas
		self.activityPreTimes[tostring(activityId)] = os.time()
		self.activityHomeDatas[tostring(activityId)] = {activityId = checkint(activityId), leftSeconds = datas.remainTime, type = ACTIVITY_TYPE.PERMANENT_SINGLE_PAY}
		self:CreatePermanentSinglePayView(activityId)
	elseif name == SIGNALNAMES.Activity_Web_Home_Callback then -- web跳转活动
		local datas = checktable(signal:GetBody())
		local activityId = datas.requestData.activityId
		self.activityDatas[tostring(activityId)] = datas
		self:CreateWebActivityView(activityId)
	elseif name == SGL.CLOSE_3V3_MATCH then
		if self.selectedTab == checkint(ACTIVITY_ID.TAG_MATCH) then
			uiMgr:ShowInformationTips(__('天城演武已结束'))
			self.selectedTab = checkint(ACTIVITY_TYPE.HONEY_BENTO)
			self:ClearActivityLayer()
		end
	end
end

function ActivityMediator:Initial( key )
	self.super.Initial(self,key)
	local viewComponent = uiMgr:SwitchToTargetScene('Game.views.ActivityScene')
	self:SetViewComponent(viewComponent)
end

--[[
初始化tabViewData
--]]
function ActivityMediator:InitTabViewData()
	-- 活动分类配置
	local classConfig = CommonUtils.GetConfigAllMess('activitySort', 'activity')
	-- 活动类型配置
	local typeConfig = clone(CommonUtils.GetConfigAllMess('activityType', 'activity'))
	for i, v in pairs(typeConfig) do
		table.sort(v, function (a, b)
			return checkint(a.sort) < checkint(b.sort)
		end)
	end
	local tabViewData = {}
	for _, classData in orderedPairs(classConfig) do
		local activityData = {}
		local typeDataList = typeConfig[tostring(classData.type)]
		-- five zxb 3/25说顺序改成走配表，4/25又跟我讲他是要新手走配表，其余走后台，属实five
		-- sort字段判断排顺是否读表(1:读表, 0:后台）
		if checkint(classData.sort) == 1 then
			for _, typeData in ipairs(typeDataList) do
				for _, tabData in ipairs(self.activityTabDatas) do
					if checkint(typeData.id) == checkint(tabData.type) then
						tabData.highlight = checkint(typeData.highlight)
						table.insert(activityData, tabData)
					end
				end
			end
		else
			for _, tabData in ipairs(self.activityTabDatas) do
				for _, typeData in ipairs(typeDataList) do
					if checkint(typeData.id) == checkint(tabData.type) then
						tabData.highlight = checkint(typeData.highlight)
						table.insert(activityData, tabData)
						break
					end
				end
			end
		end
		if next(activityData) ~= nil then
			table.insert(tabViewData, {title = classData.name, type = classData.type, activityData = activityData})
		end
	end
	self.tabViewData = tabViewData
end
function ActivityMediator:InitSelectedTab()
	if self.selectedTab == 0 then
		self.selectedTab = checkint(checktable(checktable(checktable(self.tabViewData[1]).activityData)[1]).activityId)
		return
	end
	for i,v in ipairs(self.activityTabDatas) do
		if checkint(v.activityId) == checkint(self.selectedTab) then
			return 
		end
		if i == #self.activityTabDatas then
			self.selectedTab = checkint(checktable(checktable(checktable(self.tabViewData[1]).activityData)[1]).activityId)
		end
	end
end
--[[
每日签到列表数据处理
--]]
function ActivityMediator:ActivityDailyBonusSource( p_convertview, idx )
	local pCell = p_convertview
    local index = idx + 1
    local cSize = cc.size(120, 120)

    if pCell == nil then
        pCell = ActivityDailyBonusCell.new(cSize)
    end
	xTry(function()
		local datas = self.activityDatas[tostring(ACTIVITY_TYPE.DAILY_BONUS)].content[index]
		pCell.goodsIcon:RefreshSelf({goodsId = datas.rewards[1].goodsId, amount = datas.rewards[1].num})
		display.commonUIParams(pCell.goodsIcon, {animate = false, cb = function (sender)
			uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = datas.rewards[1].goodsId, type = 1})
		end})
		pCell.turntable:setVisible(false)
		-- 判断是否存在转盘活动
		---------------------------------------
		if next(self.activityHomeDatas) ~= nil then
			local today = 0
			for _,v in ipairs(self.activityDatas[tostring(ACTIVITY_TYPE.DAILY_BONUS)].content) do
				if checkint(v.hasDrawn) == 1 then
					today = today + 1
				end
			end
			if self.activityDatas[tostring(ACTIVITY_TYPE.DAILY_BONUS)].hasTodayDrawn == 0 then
				today = today + 1
		    end
			for k,v in pairs(self.activityHomeDatas) do
				if v.type == ACTIVITY_TYPE.LUCKY_WHEEL then
					local endDay = today + math.ceil(checkint(v.leftSeconds)/86400)
					if index < endDay then
					 	pCell.turntable:setVisible(true)
					end
				end
			end
		end
		---------------------------------------
		if datas.hasDrawn == 0 then
			pCell.mask:setVisible(false)
			pCell.hookIcon:setVisible(false)
		elseif datas.hasDrawn == 1 then
			pCell.mask:setVisible(true)
			pCell.hookIcon:setVisible(true)
			pCell.turntable:setVisible(false)
		end
		-- 是否高亮
		if checkint(datas.highlight) == 0 then
			pCell.frameSpine:setVisible(false)
		elseif checkint(datas.highlight) == 1 then
			pCell.frameSpine:setVisible(true)
		end

	end,__G__TRACKBACK__)
    return pCell
end
--[[
新手15天签到列表数据处理
--]]
function ActivityMediator:ActivityNoviceBonusSource( p_convertview, idx )
	local pCell = p_convertview
    local index = idx + 1
    local cSize = cc.size(556, 150)

    if pCell == nil then
        pCell = ActivityNoviceBonusCell.new(cSize)
        pCell.drawBtn:setOnClickScriptHandler(handler(self, self.DrawNoviceBonusBtnCallback))
    end
	xTry(function()
		local datas = self.activityDatas[tostring(ACTIVITY_TYPE.NOVICE_BONUS)]
		local contentDatas = datas.content[index]
		local isHighlight = true -- 是否高亮
		-- 改变领取按钮状态
		if index < checkint(datas.today) then
			-- 已领取
			isHighlight = false
			pCell.mask:setVisible(true)
			pCell.drawLabel:setString(__('已领取'))
			-- pCell.drawBtn:setNormalImage(_res('ui/common/common_btn_orange_disable.png'))
			-- pCell.drawBtn:setSelectedImage(_res('ui/common/common_btn_orange_disable.png'))
			pCell.drawBtn:setVisible(false)
		elseif index == checkint(datas.today) then
			if checkint(datas.hasTodayDrawn) == 0 then
				-- 可领取
				pCell.mask:setVisible(false)
				pCell.drawLabel:setString(__('领取'))
				pCell.drawBtn:setNormalImage(_res('ui/common/common_btn_orange.png'))
				pCell.drawBtn:setSelectedImage(_res('ui/common/common_btn_orange.png'))
				pCell.drawBtn:setEnabled(true)
				pCell.drawBtn:setVisible(true)
			elseif checkint(datas.hasTodayDrawn) == 1 then
				-- 已领取
				isHighlight = false
				pCell.mask:setVisible(true)
				pCell.drawLabel:setString(__('已领取'))
				-- pCell.drawBtn:setNormalImage(_res('ui/common/common_btn_orange_disable.png'))
				-- pCell.drawBtn:setSelectedImage(_res('ui/common/common_btn_orange_disable.png'))
				pCell.drawBtn:setVisible(false)
			end
		else
			-- 不可领取
			pCell.mask:setVisible(false)
			pCell.drawLabel:setString(__('未领取'))
			pCell.drawBtn:setNormalImage(_res('ui/common/common_btn_orange_disable.png'))
			pCell.drawBtn:setSelectedImage(_res('ui/common/common_btn_orange_disable.png'))
			pCell.drawBtn:setEnabled(false)
			pCell.drawBtn:setVisible(true)
		end
		-- 添加奖励
		if pCell.eventNode:getChildByTag(1111) then
			pCell.eventNode:getChildByTag(1111):removeFromParent()
		end
		display.commonLabelParams(pCell.drawLabel,{reqW = 105 })
		local size = cc.size(380, 96)
		local layout = CLayout:create(size)
		layout:setPosition(cc.p(210, 63))
		layout:setTag(1111)
		pCell.eventNode:addChild(layout, 10)
		for i, v in ipairs(contentDatas.rewards) do
			local goodsIcon = require('common.GoodNode').new({id = v.goodsId, amount = v.num, showAmount = true})
			goodsIcon:setPosition(cc.p(50 + (i-1)*94, size.height/2))
			goodsIcon:setScale(0.8)
			layout:addChild(goodsIcon, 10)
			display.commonUIParams(goodsIcon, {animate = false, cb = function (sender)
				uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = v.goodsId, type = 1})
			end})
			if isHighlight and checkint(v.highlight) == 1 then
				local frameSpine = sp.SkeletonAnimation:create('effects/activity/biankuang.json', 'effects/activity/biankuang.atlas', 1)
				frameSpine:update(0)
				frameSpine:setScale(0.8)
				frameSpine:setAnimation(0, 'idle', true)
				layout:addChild(frameSpine,10)
				frameSpine:setPosition(cc.p(50 + (i-1)*94, size.height/2))
			end
		end
		pCell.numLabel:setString(string.fmt(__("第_num_天"),{_num_ = tostring(index)}))
	end,__G__TRACKBACK__)
    return pCell
end
--[[
活动页签点击回调
--]]
function ActivityMediator:TabButtonCallback( activityId )
	if self.showLayer[tostring(self.selectedTab)] and not tolua.isnull(self.showLayer[tostring(self.selectedTab)]) then
		self.showLayer[tostring(self.selectedTab)]:setVisible(false)
	end
	self.selectedTab = activityId
	if self.showLayer[tostring(self.selectedTab)] and not tolua.isnull(self.showLayer[tostring(self.selectedTab)]) then
		self.showLayer[tostring(self.selectedTab)]:setVisible(true)
	else
		self:SwitchView(self.selectedTab)
	end
end
--[[
切换view
@params activityId int 活动Id
--]]
function ActivityMediator:SwitchView( activityId )
	local viewData = self:GetViewComponent().viewData
	local function CreateView( viewName, datas )
		local view = require( 'Game.views.' .. viewName).new(datas)
	    viewData.ActivityLayout:addChild(view, 10)
	    view:setAnchorPoint(cc.p(0,0))
		view:setPosition(cc.p(0,0))
		self.showLayer[tostring(activityId)] = view
		return view
	end
	local activityType = nil
	if checkint(activityId) > 0 then
		activityType = self.activityHomeDatas[tostring(activityId)].type
	else
		activityType = tostring(activityId)
	end
	if activityType == ACTIVITY_TYPE.DAILY_BONUS then -- 每日签到
		local activityDailyBonusView = CreateView('ActivityDailyBonusView')
		activityDailyBonusView.viewData_.gridView:setDataSourceAdapterScriptHandler(handler(self, self.ActivityDailyBonusSource))
		self:SendSignal(COMMANDS.COMMAND_Activity_monthlyLogin)
	elseif activityType == ACTIVITY_TYPE.NOVICE_BONUS then -- 新手15天签到
		local ActivityNoviceBonusView = CreateView('ActivityNoviceBonusView')
		ActivityNoviceBonusView.viewData_.gridView:setDataSourceAdapterScriptHandler(handler(self, self.ActivityNoviceBonusSource))
		self:SendSignal(COMMANDS.COMMAND_Activity_Newbie15Day)
		gameMgr:GetUserInfo().isShowNewbie15Day = false
	elseif activityType == ACTIVITY_TYPE.FIRST_PAYMENT then -- 首冲礼包
		local ActivityFirstPayment = CreateView('ActivityFirstPayment')
		ActivityFirstPayment.viewData_.switchBtn:setOnClickScriptHandler(handler(self, self.FirstPaymentSwitchBtnCallback))
		ActivityFirstPayment.viewData_.jumpBtn:setOnClickScriptHandler(handler(self, self.FirstPaymentJumpBtnCallback))
		ActivityFirstPayment.viewData_.switchActionBtn:setOnClickScriptHandler(handler(self, self.FirstPaymentSwitchSpineAction))
	elseif activityType == ACTIVITY_TYPE.SPECIAL_CAPSULE then -- 超得
		local activitySpecialCapsuleView = CreateView('ActivitySpecialCapsuleView')
		activitySpecialCapsuleView.viewData_.shopBtn:setTag(checkint(activityId))
		activitySpecialCapsuleView.viewData_.shopBtn:setOnClickScriptHandler(handler(self, self.SpecialCapsuleShopButtonCallback))
		activitySpecialCapsuleView.viewData_.purchaseBtn:setOnClickScriptHandler(handler(self, self.SpecialCapsulePurchaseButtonCallback))
	elseif activityType == ACTIVITY_TYPE.ITEMS_EXCHANGE then -- 道具兑换
		if self.activityHomeDatas[tostring(activityId)].homeDatas then
			self:CreatePropExchangeView(activityId)
		else
			self:SendSignal(COMMANDS.COMMAND_Activity_Draw_exchangeList, {activityId = activityId})
		end

	elseif activityType == ACTIVITY_TYPE.CAPSULE_PROBABILITY_UP then -- 召唤概率UP
		local activityCapsuleUpView = CreateView('ActivityCapsuleUpView')
		activityCapsuleUpView.viewData_.enterBtn:setOnClickScriptHandler(handler(self, self.ProbabilityUpEnterButtonCallback))
		activityCapsuleUpView.viewData_.timeLabel:setString(self:ChangeTimeFormat(self.activityHomeDatas[tostring(activityId)].leftSeconds, ACTIVITY_TYPE.CAPSULE_PROBABILITY_UP))
		activityCapsuleUpView.viewData_.ruleLabel:setString(self.activityHomeDatas[tostring(activityId)].detail[i18n.getLang()])
		local backgroundImage = self.activityHomeDatas[tostring(activityId)].backgroundImage[i18n.getLang()]
		activityCapsuleUpView.viewData_.bg:setWebURL(backgroundImage)
		activityCapsuleUpView.viewData_.bg:setVisible(true)
		self:SetRuleLabelShow(activityCapsuleUpView.viewData_.ruleLabel , activityCapsuleUpView.viewData_.listView)
	elseif 	activityType == ACTIVITY_TYPE.LEVEL_GIFT then -- 等级礼包
		CreateView('ActivityLevelGiftView')
		if app.activityMgr:GetLevelChestData() then
			self:RefreshLevelChest()
		else
			self:SendSignal(POST.LEVEL_GIFT_CHEST.cmdName,{})
		end
		--activityExchangeView.viewData_.enterBtn:setTag(checkint(activityId))
		--activityExchangeView.viewData_.enterBtn:setOnClickScriptHandler(handler(self, self.ExchangeEnterButtonCallback))
    elseif activityType == "APP_STORE_PRODUCTS" then
        --刷新界面ui的逻辑
        CommonUtils.SortChestData()
        local activityExchangeView = self.showLayer[tostring(ACTIVITY_TYPE.LEVEL_GIFT)]
        activityExchangeView.viewData_.gridView:setDataSourceAdapterScriptHandler(handler(self, self.OnDataSourceChestLevel))
        activityExchangeView.viewData_.gridView:setCountOfCell(table.nums(gameMgr:GetLevelChestData()))
        activityExchangeView.viewData_.gridView:reloadData()
	elseif activityType == ACTIVITY_TYPE.HONEY_BENTO then -- 爱心便当
		local activityHoneyBentoView = CreateView('ActivityHoneyBentoView')
		-- 创建定时器
		if not self.honeyBentoScheduler_ then
			self.honeyBentoScheduler_ = scheduler.scheduleGlobal(handler(self, self.onHoneyBentoSchedulerHandler), 1)
		end
		local bentoTimeList = {}
		local loveBentoData = checktable(gameMgr:GetUserInfo().loveBentoData)
		for _, bentoData in orderedPairs(loveBentoData) do
			local startTimeData = string.split(bentoData.startTime, ':')
			local endedTimeData = string.split(bentoData.endTime, ':')
			local startTimeText = l10nHours(startTimeData[1], startTimeData[2]):fmt('%H:%M')
			local endedTimeText = l10nHours(endedTimeData[1], endedTimeData[2]):fmt('%H:%M')
			if isElexSdk() then
				startTimeText = elexBentoTimeChange(startTimeData[1], startTimeData[2]):fmt('%H:%M')
				endedTimeText = elexBentoTimeChange(endedTimeData[1], endedTimeData[2]):fmt('%H:%M')
			end
			table.insert(bentoTimeList, string.fmt('%1-%2', startTimeText, endedTimeText))
		end
		local bentoRuleText = string.fmt(__('每日 _times_ 可以领取50体力的奖励。'), {_times_ = table.concat(bentoTimeList, ', ')})
		activityHoneyBentoView:setRuleText(bentoRuleText)
		activityHoneyBentoView.viewData_.gridView:setDataSourceAdapterScriptHandler(handler(self, self.HoneyBentoDataSource))
		activityHoneyBentoView.viewData_.gridView:setCountOfCell(table.nums(loveBentoData))
		activityHoneyBentoView.viewData_.gridView:reloadData()


	elseif activityType == ACTIVITY_TYPE.FULL_SERVER then     -- 全服活动
		if self.activityHomeDatas[tostring(activityId)].homeDatas then
			self:CreateFullServerView(activityId)
		else
			self:SendSignal(COMMANDS.COMMAND_Activity_Draw_serverTask, {activityId = activityId})
		end
	elseif checkint(activityType)  == checkint(ACTIVITY_TYPE.SEASONG_LIVE)  then  -- 季活的活动
		---@type GameManager
		local gameMgr = AppFacade.GetInstance():GetManager('GameManager')
		local isFirstOpen = cc.UserDefault:getInstance():getBoolForKey(string.format("%s_IS_FIRST_SEASOING_LIVE" , tostring(gameMgr:GetUserInfo().playerId) ), true)
		local func = function ()
			-- 传入 活动的倒计时 和活动的id
			local mediator = require("Game.mediator.ActivitySeasonLiveMediator").new({ seasonActivityData = self.activityHomeDatas[tostring(activityId)]  })
			self:GetFacade():RegistMediator(mediator)
			local view = mediator:GetViewComponent()
			viewData.ActivityLayout:addChild(view, 10)
			view:setAnchorPoint(cc.p(0,0))
			view:setPosition(cc.p(0,0))
			self.showMediatorName[tostring(activityId)] = mediator:GetMediatorName()
			self.showLayer[tostring(activityId)] = view
		end

		if isFirstOpen then
			local storyStage = require('Frame.Opera.OperaStage').new({id = checkint(1), path = string.format("conf/%s/seasonActivity/springStory.json",i18n.getLang()), guide = true, cb = function(sender)
				cc.UserDefault:getInstance():setBoolForKey(string.format("%s_IS_FIRST_SEASOING_LIVE" , tostring(gameMgr:GetUserInfo().playerId) ), false)
				cc.UserDefault:getInstance():flush()
				func()
			end})
			storyStage:setPosition(display.center)
			sceneWorld:addChild(storyStage, GameSceneTag.Dialog_GameSceneTag)
		else
			func()
		end


	elseif activityType == ACTIVITY_TYPE.CHARGE_WHEEL then -- 付费转盘
		if self.activityHomeDatas[tostring(activityId)].homeDatas then
			self:CreateChargeWheelView(activityId)
		else
			self:SendSignal(COMMANDS.COMMAND_Activity_ChargeWheel, {activityId = activityId})
		end
	elseif activityType == ACTIVITY_TYPE.COMMON_ACTIVITY then -- 通用活动
		local activityHomeDatas = self.activityHomeDatas[tostring(activityId)]
		local params = {
			showBtn = false,
			showRule = false,
			bgImageURL = activityHomeDatas.backgroundImage[i18n.getLang()],
			timeText = self:ChangeTimeFormat(activityHomeDatas.leftSeconds, ACTIVITY_TYPE.COMMON_ACTIVITY)
		}
		local activityCommonView = CreateView('ActivityCommonView', params)
	elseif activityType == ACTIVITY_TYPE.CYCLIC_TASKS then -- 循环任务
		local activityCyclicTasksView = CreateView('ActivityCyclicTasksView')
		local backgroundImage = self.activityHomeDatas[tostring(activityId)].backgroundImage[i18n.getLang()]
		activityCyclicTasksView.viewData_.timeLabel:setString(self:ChangeTimeFormat(self.activityHomeDatas[tostring(activityId)].leftSeconds, ACTIVITY_TYPE.COMMON_ACTIVITY))
		activityCyclicTasksView.viewData_.bg:setWebURL(backgroundImage)
		activityCyclicTasksView.viewData_.ruleLabel:setString(self.activityHomeDatas[tostring(activityId)].detail[i18n.getLang()])
		activityCyclicTasksView.viewData_.enterBtn:setOnClickScriptHandler(handler(self, self.CyclicTasksEnterBtnCallback))
		activityCyclicTasksView.viewData_.enterBtn:setTag(activityId)
		self:SetRuleLabelShow(activityCyclicTasksView.viewData_.ruleLabel , activityCyclicTasksView.viewData_.listView)
	elseif activityType == ACTIVITY_TYPE.LOBBY_ACTIVITY then
		-- activity/home  中有这页签  先检查 有没有 餐厅活动数据  没有则 发送请求
		if app.activityMgr:isOpenLobbyFestivalActivity() then
			self:CreateLobbyFestivalActivity(activityId)
		else
			self:SendSignal(POST.Activity_Draw_restaurant.cmdName)
		end
	elseif activityType == ACTIVITY_TYPE.TAKEAWAY_POINT then -- 外卖点活动
		self:SendSignal(COMMANDS.COMMAND_Activity_TakeawayPoint, {activityId = activityId})
	elseif activityType == ACTIVITY_TYPE.BINGGO then
		if self.activityHomeDatas[tostring(activityId)].homeDatas then
			self:CreateBinggoActivity(activityId)
		else
			self:SendSignal(COMMANDS.COMMAND_Activity_TaskBinggoList, {activityId = activityId})
		end
	elseif activityType == ACTIVITY_TYPE.CHEST_EXCHANGE then -- 宝箱兑换活动
		self:SendSignal(COMMANDS.COMMAND_Activity_ChestExchangeList, {activityId = activityId})
	elseif activityType == ACTIVITY_TYPE.LOGIN_REWARD then -- 登录礼包活动
		self:SendSignal(COMMANDS.COMMAND_Activity_LoginReward, {activityId = activityId})
	elseif activityType == ACTIVITY_TYPE.CUMULATIVE_RECHARGE then -- 累计充值活动
		self:SendSignal(COMMANDS.COMMAND_Activity_AccumulativePay, {activityId = activityId})
	elseif activityType == ACTIVITY_TYPE.CV_SHARE then -- cv分享活动
		local activityHomeDatas = self.activityHomeDatas[tostring(activityId)]
		local params = {
			btnText = __('前 往'),
			btnTag = checkint(activityId),
			ruleText = activityHomeDatas.detail[i18n.getLang()],
			bgImageURL = activityHomeDatas.backgroundImage[i18n.getLang()],
			timeText = self:ChangeTimeFormat(activityHomeDatas.leftSeconds, ACTIVITY_TYPE.COMMON_ACTIVITY),
			btnCallback = handler(self, self.CVShareEnterBtnCallback)
		}
		local activityCommonView = CreateView('ActivityCommonView', params)
		self:CVShareEnterBtnCallback(checkint(activityId))
		self:ClearRemindIcon(activityId)
	elseif activityType == ACTIVITY_TYPE.ACTIVITY_QUEST then -- 活动副本
		self:SendSignal(COMMANDS.COMMAND_Activity_Quest_Home, {activityId = activityId})
	elseif activityType == ACTIVITY_TYPE.TAG_MATCH then
		-- 传入 活动的倒计时 和活动的id
		local mediator = require("Game.mediator.tagMatch.TagMatchMediator").new({data = self.activityHomeDatas[tostring(activityId)]})
		self:GetFacade():RegistMediator(mediator)
		local view = mediator:GetViewComponent()
		viewData.ActivityLayout:addChild(view, 10)
		view:setAnchorPoint(cc.p(0,0))
		view:setPosition(cc.p(0,0))
		self.showMediatorName[tostring(activityId)] = mediator:GetMediatorName()
		self.showLayer[tostring(activityId)] = view
	elseif activityType == ACTIVITY_TYPE.NEW_TAG_MATCH then --新天成演武
		local mediator = require("Game.mediator.tagMatchNew.NewKofArenaEnterMediator").new(self.datas)
		self:GetFacade():RegistMediator(mediator)
		local view = mediator:GetViewComponent()
		viewData.ActivityLayout:addChild(view, 10)
		view:setAnchorPoint(cc.p(0,0))
		view:setPosition(cc.p(0,0))
		self.showMediatorName[tostring(activityId)] = mediator:GetMediatorName()
		self.showLayer[tostring(activityId)] = view
	elseif activityType == ACTIVITY_TYPE.CUMULATIVE_CONSUME then -- 累消活动
		self:SendSignal(COMMANDS.COMMAND_Activity_AccumulativeConsume, {activityId = activityId})
	elseif activityType == ACTIVITY_TYPE.QUESTIONNAIRE then -- 问卷活动
		self:SendSignal(COMMANDS.COMMAND_Activity_Questionnaire, {activityId = activityId})
	elseif activityType == ACTIVITY_TYPE.BALLOON then -- 打气球活动
		self:SendSignal(COMMANDS.COMMAND_Activity_Balloon_Home, {activityId = activityId})
	elseif activityType == ACTIVITY_TYPE.SINGLE_PAY then -- 单笔充值活动
		self:SendSignal(COMMANDS.COMMAND_Activity_SinglePay_Home, {activityId = activityId})
	elseif activityType == ACTIVITY_TYPE.PERMANENT_SINGLE_PAY then -- 常驻单笔充值活动
		self:SendSignal(COMMANDS.COMMAND_Activity_Permanent_Single_Pay)
	elseif activityType == ACTIVITY_TYPE.WEB_ACTIVITY then -- 跳转网页活动
		self:SendSignal(COMMANDS.COMMAND_Activity_Web_Home, {activityId = activityId})
	elseif activityType == ACTIVITY_TYPE.SUMMER_ACTIVITY then -- 夏活
		self:CreateSummerActivityPageView(activityId)
	elseif activityType == ACTIVITY_TYPE.LEVEL_ADVANCE_CHEST then -- 进阶等级礼包
		if checkint(gameMgr:GetUserInfo().tips.levelAdvanceChest) == 1 then
			gameMgr:GetUserInfo().tips.levelAdvanceChest = 0
			self:ClearRemindIcon(ACTIVITY_ID.LEVEL_ADVANCE_CHEST)
		end
		self:CreateLevelAdvanceChestView(activityId)
	elseif activityType == ACTIVITY_TYPE.LEVEL_REWARD then
		self:CreateLevelRewardView(activityId)
	elseif activityType == ACTIVITY_TYPE.SAIMOE then -- 燃战
		self:CreateSaiMoeView(activityId)
	elseif activityType == ACTIVITY_TYPE.SP_ACTIVITY then -- 特殊活动(周年庆)
		self:CreateSpActivityView(activityId)
	elseif activityType == ACTIVITY_TYPE.FORTUNE_CAT then -- 招财猫
		self:CreateFortuneCarView(activityId)
	elseif activityType == ACTIVITY_TYPE.ARTIFACT_ROAD then -- 神器之路
		self:CreateArtifactRoadActivityView(activityId)
	elseif activityType == ACTIVITY_TYPE.PT_DUNGEON then -- pt本
		self:CreatePTDungeonActivityView(activityId)
	elseif activityType == ACTIVITY_TYPE.LIMIT_AIRSHIP then -- 限时空运
		self:CreateLimitAirshipView(activityId)
	elseif activityType == ACTIVITY_TYPE.TEAM_QUEST_ACTIVITY then -- 组队本活动
		self:CreateTeamQuestView(activityId)
	elseif activityType == ACTIVITY_TYPE.DOUNBLE_EXP_NORMAL then -- 普通本双倍经验活动
		self:CreateEXPNormalView(activityId)
	elseif activityType == ACTIVITY_TYPE.DOUNBLE_EXP_HARD then -- 困难本双倍经验活动
		self:CreateEXPHardView(activityId)
	elseif activityType == ACTIVITY_TYPE.PASS_TICKET then
		self:CreatePassTicketView(activityId)
	elseif activityType == ACTIVITY_TYPE.ANNIVERSARY then -- 周年庆
		self:CreateAnniversaryView(activityId)
	elseif activityType == ACTIVITY_TYPE.DRAW_SKIN_POOL then -- 皮肤卡池
		self:CreateSkinPoolView(activityId)
	elseif activityType == ACTIVITY_TYPE.DRAW_CARD_CHOOSE then -- 选卡卡池
		self:CreateCardChooseView(activityId)
	elseif activityType == ACTIVITY_TYPE.GROWTH_FUND then -- 成长基金
		self:CreateGrowthFundView(activityId)
	elseif activityType == ACTIVITY_TYPE.CASTLE_ACTIVITY then
		self:CreateCastleActivityView(activityId)
	elseif activityType == ACTIVITY_TYPE.KFC_ACTIVITY then -- KFC签到活动
		self:CreateKFCActivityView(activityId)
	elseif activityType == ACTIVITY_TYPE.PAY_LOGIN_REWARD then -- 付费签到
		self:CreatePayLoginRewardActivityView(activityId)
	elseif activityType == ACTIVITY_TYPE.MURDER then -- 杀人案（19夏活）
		self:CreateMurderView(activityId)
	elseif activityType == ACTIVITY_TYPE.WISH_TREE then --祈愿树
		self:CreateJPWishActivityView(activityId)
	elseif activityType == ACTIVITY_TYPE.CONTINUOUS_ACTIVE then -- 连续活跃活动
		self:CreateContinuousActiveView(activityId)
	elseif activityType == ACTIVITY_TYPE.ULTIMATE_BATTLE then -- 巅峰对决
		self:CreateUltimateBattleView(activityId)
	elseif activityType == ACTIVITY_TYPE.SKIN_CARNIVAL then -- 皮肤嘉年华
		self:CreateSkinCarnivalView(activityId)
	elseif activityType == ACTIVITY_TYPE.ANNIVERSARY19 then -- 周年庆19
		self:CreateAnniversary19View(activityId)
	elseif activityType == ACTIVITY_TYPE.LUCK_NUMBER then -- 幸运数字
		self:CreateLuckNumberView(activityId)
	elseif activityType == ACTIVITY_TYPE.CARD_VOTE then -- 飨灵对决之飨灵投票
		self:CreateCardVoteView(activityId)
	elseif activityType == ACTIVITY_TYPE.DRAW_RANDOM_POOL then -- 铸池抽卡
		self:CreateRandomPoolView(activityId)
	elseif activityType == ACTIVITY_TYPE.BINARY_CHOICE then -- 双抉卡池
		self:CreateBinaryChoiceView(activityId)
	elseif activityType == ACTIVITY_TYPE.SCRATCHER then -- 飨灵刮刮乐
		self:CreateScratcherView(activityId)
	elseif activityType == ACTIVITY_TYPE.CV_SHARE2 then --新的cv 分享
		self:CreateShareCv2ActivityView(activityId)
	elseif activityType == ACTIVITY_TYPE.SPRING_ACTIVITY_20 then -- 20春活
		self:CreateSpringActivity20View(activityId)
	elseif activityType == ACTIVITY_TYPE.JUMP_JEWEL then -- 塔可跳转活动
		self:CreateJumpJewelView(activityId)
	elseif activityType == ACTIVITY_TYPE.CHEST_ACTIVITY then -- 宝箱活动
		self:CreateChestActivityView(activityId)
	elseif activityType == ACTIVITY_TYPE.LINK_POP_ACTIVITY then -- pop 联动
		self:CreatePopLinkActivityView(activityId)
	elseif activityType == ACTIVITY_TYPE.NOVICE_ACCUMULATIVE_PAY then -- 新手累计充值
		self:CreateNoviceAccumulativeView(activityId)
	elseif activityType == ACTIVITY_TYPE.ASSEMBLY_ACTIVITY then -- 组合活动
		self:CreateAssemblyActivityView(activityId)
	elseif activityType == ACTIVITY_TYPE.ANNIVERSARY_20 then -- 20周年庆
		self:CreateAnniversary20View(activityId)
	elseif activityType == ACTIVITY_TYPE.BATTLE_CARD then -- 战牌
		self:CreateBattleCardView(activityId)
	end
end
--[[
道具数目变更事件处理
--]]
function ActivityMediator:UpdateGoodsEvent()
	for k, v in pairs(self.activityHomeDatas) do
		if tostring(v.type) == ACTIVITY_TYPE.TAKEAWAY_POINT then
			self:UpdateTakeawayPointViewGoodsNum(v.activityId)
		end
	end
end
--[[
根据关联活动请求数据
@params relatedDatas table 关联活动数据
--]]
function ActivityMediator:RequestRelatedActivityDatas( relatedDatas )
	for i,v in ipairs(checktable(relatedDatas)) do
		if tostring(v.relateActivityType) == ACTIVITY_TYPE.ITEMS_EXCHANGE then
			self:SendSignal(COMMANDS.COMMAND_Activity_Draw_exchangeList, {activityId = v.relateActivityId})
		elseif tostring(v.relateActivityType) == ACTIVITY_TYPE.CHARGE_WHEEL then
			self:SendSignal(COMMANDS.COMMAND_Activity_ChargeWheel, {activityId = v.relateActivityId})
		end
	end
end
--[[
处理关联活动数据
@params activityId int 活动id
--]]
function ActivityMediator:HandleRelatedActivityDatas( activityId )
	local activityDatas = checktable(self.activityDatas[tostring(self.selectedTab)])
	local activityHomeDatas = checktable(self.activityHomeDatas[tostring(self.selectedTab)])
	if activityDatas.relateActivities then
		local isFull = true
		for k, v in pairs(checktable(activityDatas.relateActivities)) do
			if not self.activityDatas[tostring(v.relateActivityId)] then
				isFull = false
				break
			end
		end
		if isFull then
			if activityHomeDatas.type == ACTIVITY_TYPE.TAKEAWAY_POINT then
				self:RefreshTakeawayPointView(checkint(self.selectedTab))
			end
		end
	end

end
function ActivityMediator:RefreshLevelChest()
	app.activityMgr:SortChestData()
	local activityExchangeView = self.showLayer[tostring(ACTIVITY_TYPE.LEVEL_GIFT)]
	if  activityExchangeView and (not tolua.isnull(activityExchangeView)) then
		activityExchangeView.viewData_.gridView:setDataSourceAdapterScriptHandler(handler(self, self.OnDataSourceChestLevel))
		activityExchangeView.viewData_.gridView:setCountOfCell(table.nums(app.activityMgr:GetLevelChestData()))
		activityExchangeView.viewData_.gridView:reloadData()
	end
	if isElexSdk() then
        local datas = app.activityMgr:GetLevelChestData()
        local t = {}
        for name,val in pairs(datas) do
            table.insert(t, val.channelProductId)
        end
        if next(t) ~= nil then
            require('root.AppSDK').GetInstance():QueryProducts(t)
        end
    end
end
-- 等级礼包刷新
function ActivityMediator:OnDataSourceChestLevel(cell , idx)
	local pcell = cell
	local index = idx +1
	local levelChestData = app.activityMgr:GetLevelChestData()
	---@type ActivityLevelGiftView
	local view = self.showLayer[tostring(ACTIVITY_TYPE.LEVEL_GIFT)]
	xTry(function ( )
		if index > 0 and index <= table.nums(levelChestData) then
			if not  pcell then
				pcell = view:CreateGridCell()
				pcell.buyBtn:setOnClickScriptHandler(function (sender)
					PlayAudioByClickNormal()
					local index = sender:getTag()
					local levelChestData =  app.activityMgr:GetLevelChestData()
					if levelChestData[index] and checkint(levelChestData[index].hasPurchased) == 0 and gameMgr:GetUserInfo().level >= checkint(levelChestData[index].openLevel)  then
						self.curLevelData = levelChestData[index]
						--self:GetFacade():DispatchObservers(EVENT_PAY_MONEY_SUCCESS, { rewards =  {
						--	{goodsId = DIAMOND_ID , num =1000   },
						--	{goodsId = GOLD_ID , num =1000   },
						--}, diamond = 100000 , type = 4
						--})
						if isJapanSdk() then
							if 0 == checkint(gameMgr:GetUserInfo().jpAge) then
								local JapanAgeConfirmMediator = require( 'Game.mediator.JapanAgeConfirmMediator' )
								local mediator = JapanAgeConfirmMediator.new({cb = function (  )
									self:SendSignal(COMMANDS.COMMANDS_All_Shop_GetPayOrder,{productId = levelChestData[index].productId , name = 'levelChest'})
								end})
								self:GetFacade():RegistMediator(mediator)
							else
								local price =  checkint( self.curLevelData.price)
								if checkint(self.curLevelData.discountLeftSeconds) > 0 then
									price = checkint( self.curLevelData.discountPrice)
								end
								if price < checkint(gameMgr:GetUserInfo().jpAgePaymentLimitLeft) or -1 == checkint(gameMgr:GetUserInfo().jpAgePaymentLimitLeft) then
									self:SendSignal(COMMANDS.COMMANDS_All_Shop_GetPayOrder,{productId = levelChestData[index].productId , name = 'levelChest'})
								else
									uiMgr:ShowInformationTips('本月购买幻晶石数量已达上限')
								end
							end
						else
							self:SendSignal(COMMANDS.COMMANDS_All_Shop_GetPayOrder,{productId = levelChestData[index].productId , name = 'levelChest'})
						end
					elseif  gameMgr:GetUserInfo().level <  checkint(levelChestData[index].openLevel) then
						uiMgr:ShowInformationTips(__('等级不足不能购买该礼包'))
					else
						uiMgr:ShowInformationTips(__('已经购买该礼包'))
					end
				end)
			end
			pcell.buyBtn:setTag(index)
			view:UpdateCell(pcell, levelChestData[index])
		end
	end, __G__TRACKBACK__)
	return pcell
end
function ActivityMediator:GetCellNum( activityType )
	for i,v in ipairs(self.activityTabDatas) do
		if checkint(v.activityId) == checkint(activityType) then
			return i - 1
		end
	end
end
--[[
每日签到幸运转盘点击回调
--]]
function ActivityMediator:TurntableBtnCallback( sender )
	PlayAudioByClickNormal()
	local tag = sender:getTag()
	self:SendSignal(COMMANDS.COMMAND_Activity_monthlyLoginWheel, {activityId = tag})
end
--[[
新手签到领取按钮点击回调
--]]
function ActivityMediator:DrawNoviceBonusBtnCallback( sender )
	PlayAudioByClickNormal()
	self:SendSignal(COMMANDS.COMMAND_Activity_Draw_Newbie15Day)
end
--[[
刷新每日签到页面
--]]
function ActivityMediator:RefreshDailyBonusView( dailyBonusDatas )
	local activityDailyBonusView = self.showLayer[tostring(ACTIVITY_TYPE.DAILY_BONUS)]
	if activityDailyBonusView == nil then return end
	local viewData = activityDailyBonusView.viewData_
	viewData.turntableBtn:setOnClickScriptHandler(handler(self, self.TurntableBtnCallback))
	viewData.gridView:setCountOfCell(table.nums(dailyBonusDatas.content))
	viewData.gridView:reloadData()
	-- 判断是否显示转盘入口
	if dailyBonusDatas.activity and next(checktable(dailyBonusDatas.activity)) ~= nil then
		for k,v in pairs(dailyBonusDatas.activity) do
			viewData.turntableBtn:setVisible(true)
			viewData.turntableBtn:setTag(tonumber(k))
			viewData.turntableLabel:setVisible(true)
			viewData.turntableNum:setVisible(true)
			viewData.turntableBg:setVisible(true)
			display.reloadRichLabel(viewData.turntableNum, {c = {
				{text = tostring(v.leftDrawnTimes), fontSize = 22, color = '#ffcf2a'},
				{text = '/' .. tostring(v.wheeledCircle), fontSize = 22, color = '#ffffff'}
			}})
			break
		end
	else
		viewData.turntableBtn:setVisible(false)
		viewData.turntableLabel:setVisible(false)
		viewData.turntableNum:setVisible(false)
		viewData.turntableBg:setVisible(false)
	end
	-- 已签到次数
	local signNum = 0
	for i,v in ipairs(dailyBonusDatas.content) do
		if checkint(v.hasDrawn) == 1 then
			signNum = signNum + 1
		else
			break
		end
	end
	-- viewData.signInNum:setString(signNum)
    display.reloadRichLabel(viewData.signInNum, {
         c = {
            fontWithColor(16, { text = __('本月已累计签到')}),
            fontWithColor(16, { text = ' '}),
			{fontSize = 28, color = '#d23d3d', text = tostring(signNum)},
            fontWithColor(16, { text = __('天')}),
         }
        })
 	if not isJapanSdk() then CommonUtils.SetNodeScale(viewData.signInNum , {width = 350 }) end
	-- 更新角色立绘
	viewData.cardDrawNode:RefreshAvatar({confId = dailyBonusDatas.starCardId or 200001})
	-- 调整列表位置
	if signNum > 15 then
		viewData.gridView:setContentOffsetToBottom()
	end
end
--[[
刷新新手签到页面
--]]
function ActivityMediator:RefreshNoviceBonusView( noviceBonusDatas )
	-- dump(noviceBonusDatas)
	local activityNoviceBonusView = self.showLayer[tostring(ACTIVITY_TYPE.NOVICE_BONUS)]
	if not activityNoviceBonusView then return end
	local viewData = activityNoviceBonusView.viewData_
	viewData.gridView:setCountOfCell(#noviceBonusDatas.content)
	viewData.gridView:reloadData()
	if  checkint(noviceBonusDatas.today) <= 11 then
		viewData.gridView:setContentOffset(cc.p(0, -15*150+477 + checkint(noviceBonusDatas.today)*150))
	else
		viewData.gridView:setContentOffset(cc.p(0, 0))
	end
	-- local goodsId, signinNum = self:GetNoviceBonusViewCardId()
	-- 判断是奖励是卡牌还是碎片
	-- local goodType = CommonUtils.GetGoodTypeById(goodsId)
	-- local cardId = nil
	-- if goodType == GoodsType.TYPE_CARD_FRAGMENT then -- 碎片
	-- 	cardId = CommonUtils.GetConfig('goods', 'goods', goodsId).cardId
	-- 	viewData.fragmentIcon:setVisible(true)
	-- 	viewData.fragmentIcon:RefreshSelf({goodsId = goodsId})
	-- elseif goodType == GoodsType.TYPE_CARD then -- 整卡
	-- 	viewData.fragmentIcon:setVisible(false)
	-- 	cardId = goodsId
	-- end
	-- viewData.cardDrawNode:RefreshAvatar({cardId = cardId or 200001})
	-- viewData.signInNumLabel:setString(tostring(signinNum))
	display.reloadRichLabel(viewData.timeLabel, {c = self:ChangeTimeFormat(checkint(self.activityDatas[tostring(ACTIVITY_TYPE.NOVICE_BONUS)].endLeftSeconds), ACTIVITY_TYPE.NOVICE_BONUS)})
	-- local cardDatas =  CommonUtils.GetConfig('cards', 'card', cardId)
	-- if cardDatas.cv == '' then
	-- 	viewData.cvBg:setVisible(false)
	-- 	viewData.cvLabel:setVisible(false)
	-- else
	-- 	viewData.cvBg:setVisible(true)
	-- 	viewData.cvLabel:setString(__('配音：' .. cardDatas.cv))
	-- 	viewData.cvLabel:setVisible(true)
	-- end
	-- 卡牌名称
	-- if viewData.view:getChildByTag(2222) then
	-- 	viewData.view:getChildByTag(2222):removeFromParent()
	-- end
	-- local cardRare = CommonUtils.GetConfig('cards', 'quality', cardDatas.qualityId)
	-- local qualityIcon = display.newImageView(CardUtils.GetCardQualityTextPathByCardId(cardId), 30, 20, {ap = cc.p(0, 0.5)})
	-- qualityIcon:setScale(0.35)
	-- local nameLabel = display.newLabel(qualityIcon:getContentSize().width*(0.31)+35, 20, {ap = cc.p(0, 0.5), fontSize = 24, color = '#fff8e9', font = TTF_GAME_FONT, ttf = true, outline = '3e1212', outlineSize = 1, text = cardDatas.name})
	-- local nameBgWidth = display.getLabelContentSize(nameLabel).width + qualityIcon:getContentSize().width*(0.31) + 75
	-- local nameBg = display.newImageView(_res('ui/home/activity/activity_sign_bg_card_name.png'), 256, 100, {ap = cc.p(0.5, 0), scale9 = true, size = cc.size(nameBgWidth, 40)})
	-- viewData.view:addChild(nameBg, 10)
	-- nameBg:setTag(2222)
	-- nameBg:addChild(qualityIcon, 10)
	-- nameBg:addChild(nameLabel, 10)
end
--[[
加载转盘view
--]]
function ActivityMediator:CreateLuckyWheelView( datas )
	local activityWheelView  = require( 'Game.views.ActivityWheelView' ).new(datas)
	activityWheelView:setPosition(display.center)
	activityWheelView:setTag(5566)
	local scene = uiMgr:GetCurrentScene()
	scene:AddDialog(activityWheelView)

	local wheelDatas = self.activityHomeDatas[tostring(datas.requestData.activityId)]
	-- 创建定时器
	display.reloadRichLabel(activityWheelView.viewData_.timeLabel, {c = self:ChangeTimeFormat(wheelDatas.leftSeconds, ACTIVITY_TYPE.LUCKY_WHEEL)})
	local wheelTimeScheduler = nil
	wheelTimeScheduler = scheduler.scheduleGlobal(function()
		if wheelDatas.leftSeconds <= 0 then
			PlayAudioByClickClose()
			scheduler.unscheduleGlobal(wheelTimeScheduler)
			activityWheelView:removeFromParent()
		else
			display.reloadRichLabel(activityWheelView.viewData_.timeLabel, {c = self:ChangeTimeFormat(wheelDatas.leftSeconds, ACTIVITY_TYPE.LUCKY_WHEEL)})
		end
	end, 1)
    -- 空白处点击回调
	activityWheelView.eaterLayer:setOnClickScriptHandler(function()
		PlayAudioByClickClose()
		scheduler.unscheduleGlobal(wheelTimeScheduler)
		activityWheelView:removeFromParent()
	end)
	activityWheelView.viewData_.luckyDrawBtn:setOnClickScriptHandler(function()
		if activityWheelView.leftDrawnTimes > 0 then
			self:SendSignal(COMMANDS.COMMAND_Activity_Draw_monthlyLoginWheel, {activityId = datas.requestData.activityId})
		else
			uiMgr:ShowInformationTips(__('抽奖次数不足'))
		end
	end)
	local descr = __('        1.签到满_num_天即可获得一次转动许愿盘的机会。\n        2.转动许愿盘即可获得额外道具。\n        3.活动结束后，许愿盘的次数就会清空~请注意时间，不要浪费次数哦~')
	descr = string.gsub(descr, '_num_', tostring(datas.wheeledCircle))
	activityWheelView.viewData_.tipsBtn:setOnClickScriptHandler(function()
		uiMgr:ShowIntroPopup({title = __('许愿灯规则说明'), descr = descr})
	end)
end
--[[
转盘领奖
--]]
function ActivityMediator:DrawLuckyWheel( datas )
	PlayAudioClip(AUDIOS.UI.ui_activity_wheel.id)
	local scene = uiMgr:GetCurrentScene()
	local activityWheelView = scene:GetDialogByTag(5566)
	local viewData = activityWheelView.viewData_
	-- 更新剩余次数
	activityWheelView:UpdateDrawTime()
	-- 更新底部数据
	if self.showLayer[tostring(ACTIVITY_TYPE.DAILY_BONUS)] then
		local activityDailyBonusView = self.showLayer[tostring(ACTIVITY_TYPE.DAILY_BONUS)]
		local dailyBonusDatas = self.activityDatas[tostring(ACTIVITY_TYPE.DAILY_BONUS)]
		for k,v in pairs(dailyBonusDatas.activity) do
			v.leftDrawnTimes = v.leftDrawnTimes - v.wheeledCircle
			display.reloadRichLabel(activityDailyBonusView.viewData_.turntableNum, {c = {
				{text = tostring(v.leftDrawnTimes), fontSize = 22, color = '#ffcf2a'},
				{text = '/' .. tostring(v.wheeledCircle), fontSize = 22, color = '#ffffff'}
			}})
		end
	end
	-- 屏蔽点击事件
	uiMgr:GetCurrentScene():AddViewForNoTouch()
	local rewardIndex = datas.id
	local arrowIcon = viewData.arrowIcon
	arrowIcon:runAction(
		cc.Sequence:create(
			cc.EaseSineIn:create(
				cc.RotateBy:create(1, 1080 - arrowIcon:getRotation()%360)
			),
			cc.RotateBy:create(2, 2160),
			cc.EaseSineOut:create(
				cc.RotateBy:create(2, 720+(rewardIndex-1)*viewData.angle)
			),
			cc.CallFunc:create(function ()
				uiMgr:AddDialog('common.RewardPopup', {rewards = datas.rewards})
				-- 移除屏蔽
				uiMgr:GetCurrentScene():RemoveViewForNoTouch()
			end)
		)
	)
end
--[[
每日签到执行成功后动画
--]]
function ActivityMediator:DrawDailyBonusAction()
	local activityDailyBonusView = self.showLayer[tostring(ACTIVITY_TYPE.DAILY_BONUS)]
	if activityDailyBonusView == nil or  tolua.isnull(activityDailyBonusView)  then
		return
	end
	local viewData = activityDailyBonusView.viewData_
	if not  viewData then
		return
	end
	local dailyBonusDatas = self.activityDatas[tostring(ACTIVITY_TYPE.DAILY_BONUS)]
	local signNum = 0
	for i,v in ipairs(dailyBonusDatas.content) do
		if checkint(v.hasDrawn) == 1 then
			signNum = signNum + 1
		else
			break
		end
	end
	display.reloadRichLabel(viewData.signInNum, {
		c = {
		   fontWithColor(16, { text = __('本月已累计签到')}),
		   {fontSize = 28, color = '#d23d3d', text = tostring(signNum + 1)},
		   fontWithColor(16, { text = __('天')}),
		}
   })
	local cell = viewData.gridView:cellAtIndex(signNum)
	if not cell then return end
	cell.turntable:setVisible(false)
	-- 更新数据
	self.activityDatas[tostring(ACTIVITY_TYPE.DAILY_BONUS)].content[signNum+1].hasDrawn = 1
	-- 动作
	cell.hookIcon:setScale(2)
	cell.hookIcon:setVisible(true)
	cell.mask:setOpacity(0)
	cell.mask:setVisible(true)
	cell.hookIcon:runAction(
		cc.Spawn:create(
			cc.TargetedAction:create(
				cell.mask,
				cc.FadeIn:create(0.2)
			),
			cc.EaseBackOut:create(
				cc.ScaleTo:create(0.3, 1)
			)
		)
	)
    display.reloadRichLabel(viewData.signInNum, {
         c = {
            fontWithColor(16, { text = __('本月已累计签到')}),
            {fontSize = 28, color = '#d23d3d', text = tostring(signNum + 1)},
            fontWithColor(16, { text = __('天')}),
         }
        })
	if not isJapanSdk() then CommonUtils.SetNodeScale(viewData.signInNum , {width = 350 }) end
	-- viewData.signInNum:setString(signNum+1)
end
--[[
获取新手签到立绘信息
--]]
function ActivityMediator:GetNoviceBonusViewCardId()
	local noviceDatas = self.activityDatas[tostring(ACTIVITY_TYPE.NOVICE_BONUS)]
	local signinNum = 0
	if checkint(noviceDatas.hasTodayDrawn) == 0 then
		signinNum = checkint(noviceDatas.today)
	elseif checkint(noviceDatas.hasTodayDrawn) == 1 then
		signinNum = checkint(noviceDatas.today)+1
	end
	for i = signinNum, #noviceDatas.content do
		for _, reward in ipairs(noviceDatas.content[i].rewards) do
			if tostring(reward.type) == GoodsType.TYPE_CARD_FRAGMENT or tostring(reward.type) == GoodsType.TYPE_CARD then
				return reward.goodsId, i
			end
		end
	end
	for i = #noviceDatas.content, 1, -1 do
		for _, reward in ipairs(noviceDatas.content[i].rewards) do
			if tostring(reward.type) == GoodsType.TYPE_CARD_FRAGMENT or tostring(reward.type) == GoodsType.TYPE_CARD then
				return reward.goodsId, i
			end
		end
	end
end
--[[
新手15天签到定时器回调
--]]
function ActivityMediator:NoviceBonusScheduleCallback()
	local curTime = os.time()
	local deltaTime = math.abs(curTime - checkint(self.activityPreTimes.noviceBonus))
	self.activityPreTimes.noviceBonus = curTime

	local datas = self.activityDatas[tostring(ACTIVITY_TYPE.NOVICE_BONUS)]
	datas.endLeftSeconds = checkint(datas.endLeftSeconds) - deltaTime
	local time = datas.endLeftSeconds
	if time <= 0 then
		scheduler.unscheduleGlobal(self.noviceBonusScheduler)
		self.noviceBonusScheduler = nil
		gameMgr:GetUserInfo().newbie15Day = 0
		if self.showLayer[tostring(ACTIVITY_TYPE.NOVICE_BONUS)] then
			self.showLayer[tostring(ACTIVITY_TYPE.NOVICE_BONUS)]:removeFromParent()
		end
		self.selectedTab = ACTIVITY_TYPE.DAILY_BONUS
		self:SendSignal(COMMANDS.COMMAND_Activity_Home)
	else
		local viewData = self.showLayer[tostring(ACTIVITY_TYPE.NOVICE_BONUS)].viewData_
		display.reloadRichLabel(viewData.timeLabel, {c = self:ChangeTimeFormat(time, ACTIVITY_TYPE.NOVICE_BONUS)})
	end
end
--[[
处理活动剩余时间
--]]
function ActivityMediator:UpdateActivityTime()
	for k,v in pairs(self.activityHomeDatas) do
		if v.leftSeconds and checkint(v.leftSeconds) > 0 then
			local curTime = os.time()
			local deltaTime = math.abs(curTime - self.activityPreTimes[tostring(v.activityId)])
			self.activityPreTimes[tostring(v.activityId)] = curTime
			v.leftSeconds = v.leftSeconds - deltaTime

			-- 刷新页面
			if v.type == ACTIVITY_TYPE.ITEMS_EXCHANGE then
				if self.showLayer[tostring(v.activityId)] and self.showLayer[tostring(v.activityId)].viewData_.timeLabel then
					self.showLayer[tostring(v.activityId)].viewData_.timeLabel:setString(self:ChangeTimeFormat(v.leftSeconds, v.type))
				end
			elseif v.type == ACTIVITY_TYPE.CAPSULE_PROBABILITY_UP then
				if self.showLayer[tostring(v.activityId)] and self.showLayer[tostring(v.activityId)].viewData_.timeLabel then
					self.showLayer[tostring(v.activityId)].viewData_.timeLabel:setString(self:ChangeTimeFormat(v.leftSeconds, v.type))
				end
			elseif v.type == ACTIVITY_TYPE.FULL_SERVER then
				if self.showLayer[tostring(v.activityId)] and self.showLayer[tostring(v.activityId)].viewData_.timeLabel then
					self.showLayer[tostring(v.activityId)].viewData_.timeLabel:setString(self:ChangeTimeFormat(v.leftSeconds, v.type))
				end
			elseif v.type == ACTIVITY_TYPE.CHARGE_WHEEL then
				if self.showLayer[tostring(v.activityId)] and self.showLayer[tostring(v.activityId)].viewData_.timeLabel then
					self.showLayer[tostring(v.activityId)].viewData_.timeLabel:setString(self:ChangeTimeFormat(v.leftSeconds, v.type))
					local wheelView = uiMgr:GetCurrentScene():GetGameLayerByName("wheelView")
					if wheelView then
						wheelView:UpdateTimeLabel(v.leftSeconds, v.activityId)
					end
				end
			elseif v.type == ACTIVITY_TYPE.COMMON_ACTIVITY then
				if self.showLayer[tostring(v.activityId)] and self.showLayer[tostring(v.activityId)].viewData_.timeLabel then
					self.showLayer[tostring(v.activityId)].viewData_.timeLabel:setString(self:ChangeTimeFormat(v.leftSeconds, v.type))
				end
			elseif v.type == ACTIVITY_TYPE.CYCLIC_TASKS then
				if self.showLayer[tostring(v.activityId)] and self.showLayer[tostring(v.activityId)].viewData_.timeLabel then
					self.showLayer[tostring(v.activityId)].viewData_.timeLabel:setString(self:ChangeTimeFormat(v.leftSeconds, ACTIVITY_TYPE.COMMON_ACTIVITY))
				end
			elseif v.type == ACTIVITY_TYPE.TAKEAWAY_POINT then
				if self.showLayer[tostring(v.activityId)] and self.showLayer[tostring(v.activityId)].viewData_.timeLabel then
					self.showLayer[tostring(v.activityId)].viewData_.timeLabel:setString(self:ChangeTimeFormat(v.leftSeconds, v.type))
				end
			elseif v.type == ACTIVITY_TYPE.BINGGO then
				if self.showLayer[tostring(v.activityId)] and self.showLayer[tostring(v.activityId)].viewData_.timeLabel then
					self.showLayer[tostring(v.activityId)].viewData_.timeLabel:setString(self:ChangeTimeFormat(v.leftSeconds, v.type))
				end
			elseif v.type == ACTIVITY_TYPE.SUMMER_ACTIVITY then
				if self.showLayer[tostring(v.activityId)] then
					self.showLayer[tostring(v.activityId)]:updateCountDown(v.leftSeconds, __('剩余时间: '))
				end
			elseif v.type == ACTIVITY_TYPE.WISH_TREE then

			elseif v.type == ACTIVITY_TYPE.DAILY_BONUS
				or v.type == ACTIVITY_TYPE.FIRST_PAYMENT
				or v.type == ACTIVITY_TYPE.LEVEL_GIFT
				or v.type == ACTIVITY_TYPE.HONEY_BENTO
				or v.type == ACTIVITY_TYPE.TAG_MATCH
				or v.type == ACTIVITY_TYPE.TAG_MATCH_NEW
				or v.type == ACTIVITY_TYPE.LUCKY_WHEEL
				or v.type == ACTIVITY_TYPE.LOBBY_ACTIVITY
				or v.type == ACTIVITY_TYPE.LOBBY_ACTIVITY_PREVIEW
				or v.type == ACTIVITY_TYPE.SEASONG_LIVE then -- 特殊类型
			else

				if self.showLayer[tostring(v.activityId)] and self.showLayer[tostring(v.activityId)].viewData_.timeLabel then
					self.showLayer[tostring(v.activityId)].viewData_.timeLabel:setString(self:ChangeTimeFormat(v.leftSeconds, ACTIVITY_TYPE.COMMON_ACTIVITY))
				end
			end
			if v.leftSeconds <= 0 then
				if v.type == ACTIVITY_TYPE.PERMANENT_SINGLE_PAY then
					gameMgr:GetUserInfo().permanentSinglePay = 0
				end

				self:ClearActivityLayer()
			end
		end
	end
	-- 更新爱心便当活动红点
	self:RefreshHoneyBentoRemind()
end
--[[
改变时间格式
@params seconds int 剩余秒数
type int 类型
--]]
function ActivityMediator:ChangeTimeFormat( seconds, type )
	local c = nil
	if type == ACTIVITY_TYPE.NOVICE_BONUS then
		c = {}
		table.insert(c, fontWithColor(18, {text = __('活动剩余时间：')}))
		if seconds >= 86400 then
			local day = math.floor(seconds/86400)
			local hour = math.floor((seconds%86400)/3600)
			table.insert(c, {text = string.fmt(__('_num1_天_num2_小时'), {['_num1_'] = tostring(day), ['_num2_'] = tostring(hour)}), fontSize = 22, color = '#ffcf2a'})
		else
			local hour   = math.floor(seconds / 3600)
			local minute = math.floor((seconds - hour*3600) / 60)
			local sec    = (seconds - hour*3600 - minute*60)
			table.insert(c, {text = string.format("%.2d:%.2d:%.2d", hour, minute, sec), fontSize = 22, color = '#ffcf2a'})
		end
	elseif type == ACTIVITY_TYPE.LUCKY_WHEEL then
		c = {}
		table.insert(c, {text = __('活动时间:'), fontSize = 22, color = '#8c552b', ttf = true, font = TTF_GAME_FONT})
		if seconds >= 86400 then
			local day = math.floor(seconds/86400)
			local hour = math.floor((seconds%86400)/3600)
			table.insert(c, {text = string.fmt(__('_num1_天_num2_小时'), {['_num1_'] = tostring(day), ['_num2_'] = tostring(hour)}), fontSize = 22, color = '#5b3c25', ttf = true, font = TTF_GAME_FONT})
		else
			local hour   = math.floor(seconds / 3600)
			local minute = math.floor((seconds - hour*3600) / 60)
			local sec    = (seconds - hour*3600 - minute*60)
			table.insert(c, {text = string.format("%.2d:%.2d:%.2d", hour, minute, sec), fontSize = 22, color = '#5b3c25', ttf = true, font = TTF_GAME_FONT})
		end
	-- elseif type == ACTIVITY_TYPE.ITEMS_EXCHANGE then
	-- 	if seconds >= 86400 then
	-- 		local day = math.ceil(seconds/86400)
	-- 		c = string.fmt(__('_num1_天'), {['_num1_'] = tostring(day)})
	-- 	else
	-- 		local hour   = math.floor(seconds / 3600)
	-- 		local minute = math.floor((seconds - hour*3600) / 60)
	-- 		local sec    = (seconds - hour*3600 - minute*60)
	-- 		c = string.format("%.2d:%.2d:%.2d", hour, minute, sec)
	-- 	end
	-- elseif type == ACTIVITY_TYPE.CAPSULE_PROBABILITY_UP then
	-- 	if seconds >= 86400 then
	-- 		local day = math.ceil(seconds/86400)
	-- 		c = string.fmt(__('_num1_天'), {['_num1_'] = tostring(day)})
	-- 	else
	-- 		local hour   = math.floor(seconds / 3600)
	-- 		local minute = math.floor((seconds - hour*3600) / 60)
	-- 		local sec    = (seconds - hour*3600 - minute*60)
	-- 		c = string.format("%.2d:%.2d:%.2d", hour, minute, sec)
	-- 	end
	elseif type == ACTIVITY_TYPE.FULL_SERVER or type == ACTIVITY_TYPE.ITEMS_EXCHANGE or type == ACTIVITY_TYPE.CHARGE_WHEEL or type == ACTIVITY_TYPE.CAPSULE_PROBABILITY_UP or ACTIVITY_TYPE.COMMON_ACTIVITY or ACTIVITY_TYPE.BINGGO then
		if seconds >= 86400 then
			local day = math.floor(seconds/86400)
			local overflowSeconds = seconds - day * 86400
			local hour = math.floor(overflowSeconds / 3600)

			c = string.fmt(__('_num1_天_num2_小时'), {['_num1_'] = tostring(day), ['_num2_'] = tostring(hour)})
		else
			local hour   = math.floor(seconds / 3600)
			local minute = math.floor((seconds - hour*3600) / 60)
			local sec    = (seconds - hour*3600 - minute*60)
			c = string.format("%.2d:%.2d:%.2d", hour, minute, sec)
		-- elseif seconds >= 3600 then
		-- 	local hour   = math.floor(seconds / 3600)
		-- 	local minute = math.floor((seconds - hour*3600) / 60)
		-- 	c = string.fmt(__('_num1_时_num2_分'), {['_num1_'] = tostring(hour), ['_num2_'] = tostring(minute)})
		-- else
		-- 	local hour   = math.floor(seconds / 3600)
		-- 	local minute = math.floor((seconds - hour*3600) / 60)
		-- 	local sec    = (seconds - hour*3600 - minute*60)
		-- 	c = string.format("%.2d:%.2d", minute, sec)
		end
	end
	return c
end
---------------------------------------------------------------
-----------------------------首冲礼包---------------------------
--[[
首冲活动切换按钮回调
--]]
function ActivityMediator:FirstPaymentSwitchBtnCallback( sender )
	PlayAudioByClickNormal()
	local firstPaymentLayer = self.showLayer[tostring(ACTIVITY_TYPE.FIRST_PAYMENT)]
	local viewData = firstPaymentLayer.viewData_
	local newCardId = app.activityMgr:getFirstPaymentCard()
	if firstPaymentLayer.showSpine then
		viewData.switchBtn:setSelectedImage(_res('ui/home/activity/activity_firstcharge_btn_qban_default.png'))
		viewData.switchBtn:setNormalImage(_res('ui/home/activity/activity_firstcharge_btn_qban_default.png'))
		local btnPath = _res(string.format('ui/home/activity/activity_firstcharge_btn_qban_default_%d.png', newCardId))
		if utils.isExistent(_res(btnPath)) then
			viewData.switchBtn:setSelectedImage(btnPath)
			viewData.switchBtn:setNormalImage(btnPath)
		end
		viewData.qAvatar:setVisible(false)
		viewData.switchActionBtn:setVisible(false)
		viewData.cardNode:setVisible(true)
	else
		viewData.switchBtn:setSelectedImage(_res('ui/home/activity/activity_firstcharge_btn_qban_select.png'))
		viewData.switchBtn:setNormalImage(_res('ui/home/activity/activity_firstcharge_btn_qban_select.png'))
		local btnPath = _res(string.format('ui/home/activity/activity_firstcharge_btn_qban_select_%d.png', newCardId))
		if utils.isExistent(_res(btnPath)) then
			viewData.switchBtn:setSelectedImage(btnPath)
			viewData.switchBtn:setNormalImage(btnPath)
		end
		viewData.qAvatar:setVisible(true)
		viewData.switchActionBtn:setVisible(true)
		viewData.cardNode:setVisible(false)
		viewData.qAvatar:update(0)
    	viewData.qAvatar:setToSetupPose()
    	viewData.qAvatar:setAnimation(0, 'idle', true)
    	viewData.qAvatar:setTag(1)

	end
	firstPaymentLayer.showSpine = not firstPaymentLayer.showSpine
end
--[[
首冲活动跳转按钮回调
--]]
function ActivityMediator:FirstPaymentJumpBtnCallback( sender )
	PlayAudioByClickNormal()
	if GAME_MODULE_OPEN.NEW_STORE then
		app.uiMgr:showGameStores({storeType = GAME_STORE_TYPE.DIAMOND})
    else
        app.router:Dispatch({name = "HomeMediator"}, {name = "ShopMediator"})
	end
end
--[[
切换spine动作
--]]
function ActivityMediator:FirstPaymentSwitchSpineAction( sender )
	local actionList = {
		'idle',
		'run',
		'attack',
		'skill1',
		'skill2'
	}
	local firstPaymentLayer = self.showLayer[tostring(ACTIVITY_TYPE.FIRST_PAYMENT)]
	local viewData = firstPaymentLayer.viewData_
	local tag = viewData.qAvatar:getTag()
	if tag == 5 then
		tag = 0
	end
	tag = tag + 1
	viewData.qAvatar:update(0)
    viewData.qAvatar:setToSetupPose()
    viewData.qAvatar:setAnimation(0, actionList[tag], true)
	viewData.qAvatar:setTag(tag)

end
-----------------------------首冲礼包---------------------------
---------------------------------------------------------------

---------------------------------------------------------------
------------------------------限时超得--------------------------
--[[
超得商店点击回调
--]]
function ActivityMediator:SpecialCapsuleShopButtonCallback( sender )
	print('超得商店')
end
--[[
超得付款点击回调
--]]
function ActivityMediator:SpecialCapsulePurchaseButtonCallback( sender )
	print('超得付款')
end
------------------------------限时超得--------------------------
---------------------------------------------------------------

---------------------------------------------------------------
------------------------------道具兑换--------------------------

function ActivityMediator:CreatePropExchangeView(activityId)
	local viewData = self:GetViewComponent().viewData
	local function CreateView( viewName, datas )
		local view = require( 'Game.views.' .. viewName).new(datas)
		viewData.ActivityLayout:addChild(view, 10)
		view:setAnchorPoint(cc.p(0,0))
		view:setPosition(cc.p(0,0))
		if self.showLayer[tostring(activityId)] then
			self.showLayer[tostring(activityId)]:removeFromParent()
		end
		self.showLayer[tostring(activityId)] = view
		return view
	end

	local backgroundImage = self.activityHomeDatas[tostring(activityId)].backgroundImage[i18n.getLang()]

	local activityExchangeView = CreateView('ActivityExchangeView', {tag = '1'})
	-- local redPoint = activityExchangeView.viewData_.enterBtn:getChildByName('BTN_RED_POINT')
	-- redPoint:setVisible(gameMgr:GetUserInfo().serverTask[tostring(activityId)] == 1)
	activityExchangeView.viewData_.enterBtn:setTag(checkint(activityId))
	activityExchangeView.viewData_.enterBtn:setOnClickScriptHandler(handler(self, self.ExchangeEnterButtonCallback))
	activityExchangeView.viewData_.timeLabel:setString(self:ChangeTimeFormat(self.activityHomeDatas[tostring(activityId)].leftSeconds, ACTIVITY_TYPE.FULL_SERVER))
	activityExchangeView:setRuleText(self.activityHomeDatas[tostring(activityId)].detail[i18n.getLang()])
	activityExchangeView.viewData_.bg:setWebURL(backgroundImage)
	-- activityExchangeView.viewData_.bg:setVisible(true)

	local rewardLayer = activityExchangeView.tagViewData_.rewardLayer
	local rewardList = self.activityDatas[tostring(activityId)].rewardList
	local midPointX = rewardLayer:getContentSize().width / 2
	local midPointY = 108

	rewardLayer:setVisible(true)


	local params = {parent = rewardLayer, midPointX = midPointX, midPointY = midPointY, maxCol= 5, scale = 0.75, rewards = rewardList, hideAmount = true}
	local goodNodes, materialLbs = CommonUtils.createPropList(params)
	self:SetRuleLabelShow(activityExchangeView.viewData_.ruleLabel , activityExchangeView.viewData_.listView)
end
--[[
道具兑换前往按钮点击回调
--]]
function ActivityMediator:ExchangeEnterButtonCallback( sender )
	PlayAudioByClickNormal()
	local activityId = sender:getTag()
	local activityHomeDatas = self.activityHomeDatas[tostring(activityId)]
	if not activityHomeDatas then -- 如果找不到homeData说明是关联活动
		activityHomeDatas = self.activityHomeDatas[tostring(self.selectedTab)]
	end
	local activityDatas = self.activityDatas[tostring(activityId)]
	-- 添加开始剧情
	local function enterView ()
		local temp = {homeDatas = activityDatas}
		local mediator = require( 'Game.mediator.ActivityPropExchangeMediator').new({data = {activityId = activityId,  activityHomeDatas = temp, leftSeconds = activityHomeDatas.leftSeconds, tag = 110120}})
		self:GetFacade():RegistMediator(mediator)
	end
	if checkint(activityDatas.startStoryId) > 0 then
		app.activityMgr:ShowActivityStory({
			activityId = activityDatas.requestData.activityId,
			storyId = activityDatas.startStoryId,
			storyType = 'START',
			callback = enterView
		})
	else
		enterView()
	end
end
------------------------------道具兑换--------------------------
---------------------------------------------------------------

---------------------------------------------------------------
------------------------------概率UP---------------------------
--[[
召唤概率UP前往按钮点击回调
--]]
function ActivityMediator:ProbabilityUpEnterButtonCallback( sender )
	PlayAudioByClickNormal()
	if GAME_MODULE_OPEN.NEW_CAPSULE then
		self:GetFacade():RetrieveMediator("Router"):Dispatch({name = "HomeMediator"}, {name = "drawCards.CapsuleNewMediator"})
	else
		self:GetFacade():RetrieveMediator("Router"):Dispatch({name = "HomeMediator"}, {name = "drawCards.CapsuleMediator"})
	end
end
------------------------------概率UP---------------------------
---------------------------------------------------------------

---------------------------------------------------------------
------------------------------全服活动--------------------------

function ActivityMediator:CreateFullServerView(activityId)
	-- self.activityHomeDatas[tostring(activityId)].homeDatas = datas
	-- self.activityHomeDatas[tostring(activityId)].homeDatas.rewardList = rewardList
	local viewData = self:GetViewComponent().viewData
	local function CreateView( viewName, datas )
		local view = require( 'Game.views.' .. viewName).new(datas)
		viewData.ActivityLayout:addChild(view, 10)
		view:setAnchorPoint(cc.p(0,0))
		view:setPosition(cc.p(0,0))
		if self.showLayer[tostring(activityId)] then
			self.showLayer[tostring(activityId)]:removeFromParent()
		end
		self.showLayer[tostring(activityId)] = view
		return view
	end

	local backgroundImage = self.activityHomeDatas[tostring(activityId)].backgroundImage[i18n.getLang()]

	local activityExchangeView = CreateView('ActivityExchangeView', {tag = '1'})
	local redPoint = activityExchangeView.viewData_.enterBtn:getChildByName('BTN_RED_POINT')
	redPoint:setVisible(app.badgeMgr:GetActivityTipByActivitiyId(activityId) == 1)
	activityExchangeView.viewData_.enterBtn:setTag(checkint(activityId))
	activityExchangeView.viewData_.enterBtn:setOnClickScriptHandler(handler(self, self.FullServerButtonCallback))
	activityExchangeView.viewData_.timeLabel:setString(self:ChangeTimeFormat(self.activityHomeDatas[tostring(activityId)].leftSeconds, ACTIVITY_TYPE.FULL_SERVER))
	activityExchangeView.viewData_.ruleLabel:setString(self.activityHomeDatas[tostring(activityId)].detail[i18n.getLang()])
	activityExchangeView.viewData_.bg:setWebURL(backgroundImage)
	-- activityExchangeView.viewData_.bg:setVisible(true)

	local rewardLayer = activityExchangeView.tagViewData_.rewardLayer
	local rewardList = self.activityHomeDatas[tostring(activityId)].homeDatas.rewardList
	local midPointX = rewardLayer:getContentSize().width / 2
	local midPointY = 108

	rewardLayer:setVisible(true)
	local params = {parent = rewardLayer, midPointX = midPointX, midPointY = midPointY, maxCol= 5, scale = 0.75, rewards = rewardList, hideAmount = true}
	local goodNodes, materialLbs = CommonUtils.createPropList(params)
	self:SetRuleLabelShow(activityExchangeView.viewData_.ruleLabel , activityExchangeView.viewData_.listView)
end

--[[
全服活动前往按钮点击回调
--]]
function ActivityMediator:FullServerButtonCallback( sender )
	PlayAudioByClickNormal()
	local activityId = sender:getTag()
	local activityHomeDatas = self.activityHomeDatas[tostring(activityId)]
	local mediator = require( 'Game.mediator.ActivityPropExchangeMediator').new({data = {activityId = activityId, activityHomeDatas = activityHomeDatas, leftSeconds = activityHomeDatas.leftSeconds, tag = 110121}})
	self:GetFacade():RegistMediator(mediator)
end

--[[
更新全服活动小红点是否展示
--]]
function ActivityMediator:UpdateFullServerRedPoint(activityId)
	local view = self.showLayer[tostring(activityId)]
	local redPointState = app.badgeMgr:GetActivityTipByActivitiyId(activityId)
	redPointState = redPointState ~= nil and redPointState or 0
	if view then
		local enterBtn = view.viewData_.enterBtn
		local redPoint = enterBtn:getChildByName('BTN_RED_POINT')
		redPoint:setVisible(redPointState == 1)
	end
	if redPointState == 1 then
		self:AddRemindIcon(activityId)
	else
		self:ClearRemindIcon(activityId)
	end
end
------------------------------全服活动--------------------------
---------------------------------------------------------------

---------------------------------------------------------------
------------------------------爱心便当--------------------------
--[[
爱心便当列表处理
--]]
function ActivityMediator:HoneyBentoDataSource( p_convertview, idx )
	local pCell = p_convertview
    local index = idx + 1
    local cSize = cc.size(224, 482)
    if pCell == nil then
        pCell = ActivityHoneyBentoCell.new(cSize)
		pCell.drawBtn:setOnClickScriptHandler(handler(self, self.HoneyBentoDrawButtonCallback))
    end
	xTry(function()
		local bentoData = checktable(gameMgr:GetUserInfo().loveBentoData)[tostring(index)] or {}
		pCell.title:setString(tostring(bentoData.name))
		pCell.rewardNum:setString(checkint(bentoData.goodsNum))
		pCell.rewardIcon:setTexture(_res(CommonUtils.GetGoodsIconPathById(checkint(bentoData.goodsId))))
		pCell.bg:setTexture(_res(string.format('ui/home/activity/activity_love_lunch_bg_%d.png', index)))
		pCell.icon:setTexture(_res(string.format('ui/home/activity/activity_love_lunch_ico_foods_%d.png', index)))

		local startTimeData = string.split(bentoData.startTime, ':')
		local endedTimeData = string.split(bentoData.endTime, ':')
		local startTimeText = l10nHours(startTimeData[1], startTimeData[2]):fmt('%H:%M')
		local endedTimeText = l10nHours(endedTimeData[1], endedTimeData[2]):fmt('%H:%M')
		if isElexSdk() then
			startTimeText = elexBentoTimeChange(startTimeData[1], startTimeData[2]):fmt('%H:%M')
			endedTimeText = elexBentoTimeChange(endedTimeData[1], endedTimeData[2]):fmt('%H:%M')
		end
		pCell.timeLabel:setString(string.fmt('%1 - %2', startTimeText, endedTimeText))
		self:updateActivityHoneyBentoCell_(index, pCell)
	end,__G__TRACKBACK__)
    return pCell
end
function ActivityMediator:updateActivityHoneyBentoCell_(index, bentoGridCell)
	local honeyBentoView = self.showLayer[tostring(ACTIVITY_TYPE.HONEY_BENTO)]
	local bentoGridView  = honeyBentoView and honeyBentoView.viewData_.gridView or nil
	local bentoGridCell  = bentoGridCell or (bentoGridView and bentoGridView:cellAtIndex(checkint(index) - 1))
	local bentoData      = checktable(gameMgr:GetUserInfo().loveBentoData)[tostring(index)]
	if bentoGridCell and bentoData then

		local isReceived = checkint(bentoData.isReceived) == 1
		bentoGridCell.drawIcon:setVisible(isReceived)
		bentoGridCell.unlockMask:setVisible(isReceived)
		bentoGridCell.drawBtn:setEnabled(not isReceived)

		if isReceived then
			display.commonLabelParams(bentoGridCell.drawBtn, fontWithColor(14, {text = __('已领取')}))
			bentoGridCell.frame:setVisible(false)
			bentoGridCell.status = false
		else
			display.commonLabelParams(bentoGridCell.drawBtn, fontWithColor(14, {text = __('领取')}))
			if self:HoneyBentoIsOpenTime(bentoData.startTime, bentoData.endTime) then
				bentoGridCell:updateDrawButtonStatus(true)
				bentoGridCell.frame:setVisible(true)
				bentoGridCell.status = true
			else
				bentoGridCell:updateDrawButtonStatus(false)
				bentoGridCell.frame:setVisible(false)
				bentoGridCell.status = false
			end
		end
	end
end
function ActivityMediator:onHoneyBentoSchedulerHandler()
	local uiMgr = AppFacade.GetInstance():GetManager('UIManager')
	for k, v in pairs(checktable(gameMgr:GetUserInfo().loveBentoData)) do
        if k ~= '__orderedIndex' then
            self:updateActivityHoneyBentoCell_(checkint(k))
        end
	end
end
--[[
判断爱心便当活动是否可领取
--]]
function ActivityMediator:HoneyBentoIsOpenTime( startTime, endTime )
	if isElexSdk() then
		local serverTimeSecond = getServerTime()
		local startTimeText    = checkstr(startTime)
		local endedTimeText    = checkstr(endTime)
		local timezone         = getElexBentoTimezone() -- 首次登陆绑定的时区
		local startTimeData    = string.split(string.len(startTimeText) > 0 and startTimeText or '00:00', ':')
		local endedTimeData    = string.split(string.len(endedTimeText) > 0 and endedTimeText or '00:00', ':')
		local serverTimestamp  = os.date('!%Y-%m-%d _H_:_M_:00', serverTimeSecond + timezone + getServerTimezone())
		local startTimestamp   = string.fmt(serverTimestamp, {_H_ = startTimeData[1], _M_ = startTimeData[2]})
		local endedTimestamp   = string.fmt(serverTimestamp, {_H_ = endedTimeData[1], _M_ = endedTimeData[2]})
		local startTimeSecond  = timestampToSecond(startTimestamp) - timezone - getServerTimezone()
		local endedTimeSecond  = timestampToSecond(endedTimestamp) - timezone - getServerTimezone()
		return serverTimeSecond >= startTimeSecond and serverTimeSecond < endedTimeSecond
	else
		local serverTimeSecond = getServerTime()
		local startTimeText    = checkstr(startTime)
		local endedTimeText    = checkstr(endTime)
		local startTimeData    = string.split(string.len(startTimeText) > 0 and startTimeText or '00:00', ':')
		local endedTimeData    = string.split(string.len(endedTimeText) > 0 and endedTimeText or '00:00', ':')
		local serverTimestamp  = os.date('!%Y-%m-%d _H_:_M_:00', serverTimeSecond + getServerTimezone())
		local startTimestamp   = string.fmt(serverTimestamp, {_H_ = startTimeData[1], _M_ = startTimeData[2]})
		local endedTimestamp   = string.fmt(serverTimestamp, {_H_ = endedTimeData[1], _M_ = endedTimeData[2]})
		local startTimeSecond  = timestampToSecond(startTimestamp) - getServerTimezone()
		local endedTimeSecond  = timestampToSecond(endedTimestamp) - getServerTimezone()
		return serverTimeSecond >= startTimeSecond and serverTimeSecond < endedTimeSecond
	end
end
--[[
判断爱心便当活动小红点是否展示
--]]
function ActivityMediator:HoneyBentoIsShowRemind()
	local isShow = 0
	local loveBentoData = checktable(gameMgr:GetUserInfo().loveBentoData)
	for _, bentoData in pairs(loveBentoData) do
		if self:HoneyBentoIsOpenTime(bentoData.startTime, bentoData.endTime) then
			if checkint(bentoData.isReceived) == 0 then
				isShow = 1
			end
		end
	end
	return isShow
end
--[[
爱心便当活动领取按钮回调
--]]
function ActivityMediator:HoneyBentoDrawButtonCallback( sender )
	PlayAudioByClickNormal()
	self:SendSignal(COMMANDS.COMMAND_Activity_Draw_loveBento)
end
--[[
爱心便当活动领取之后的时间处理
--]]
function ActivityMediator:HoneyBentoDrawAction()
	local loveBentoData = checktable(gameMgr:GetUserInfo().loveBentoData)

	-- check current bento index
	local index = nil
	for k, bentoData in orderedPairs(loveBentoData) do
		if self:HoneyBentoIsOpenTime(bentoData.startTime, bentoData.endTime) then
			index = checkint(k)
			bentoData.isReceived = 1  -- mark to received
			break
		end
	end

	-- 领取弹窗
	local datas   = loveBentoData[tostring(index)] or {}
	local layer   = self.showLayer[tostring(ACTIVITY_TYPE.HONEY_BENTO)]
	local cell    = layer.viewData_.gridView:cellAtIndex(checkint(index) - 1)
	local rewards = { {goodsId = datas.goodsId, num = datas.goodsNum} }
	uiMgr:AddDialog('common.RewardPopup', {rewards = rewards, closeCallback = function ()
		-- 刷新cell
		if cell then
			cell.drawBtn:setEnabled(false)
			cell.frame:setVisible(false)
			display.commonLabelParams(cell.drawBtn, fontWithColor(14, {text = __('已领取')}))
			-- 动作
			cell.unlockMask:setOpacity(0)
			cell.unlockMask:runAction(
				cc.Sequence:create(
					cc.Show:create(),
					cc.FadeIn:create(0.2)
				)
			)
			cell.drawIcon:setScale(2)
			cell.drawIcon:runAction(
				cc.Sequence:create(
					cc.Show:create(),
					cc.ScaleTo:create(0.2, 1)
				)
			)
		end
	end})

	-- 清除红点
	self:ClearRemindIcon(checkint(ACTIVITY_TYPE.HONEY_BENTO))
end
--[[
刷新爱心便当活动红点
--]]
function ActivityMediator:RefreshHoneyBentoRemind()
	if self:HoneyBentoIsShowRemind() == 1 then
		-- 添加红点
		self:AddRemindIcon(checkint(ACTIVITY_TYPE.HONEY_BENTO))
	else
		-- 清除红点
		self:ClearRemindIcon(checkint(ACTIVITY_TYPE.HONEY_BENTO))
	end
end
------------------------------爱心便当--------------------------
---------------------------------------------------------------

---------------------------------------------------------------
------------------------------收费转盘--------------------------
--[[
创建收费转盘活动页签
--]]
function ActivityMediator:CreateChargeWheelView( activityId )
	local viewData = self:GetViewComponent().viewData
	local activityDatas = checktable(self.activityDatas[tostring(activityId)])
	local activityChargeWheelView = require('Game.views.ActivityChargeWheelView').new()
	viewData.ActivityLayout:addChild(activityChargeWheelView, 10)
	activityChargeWheelView:setAnchorPoint(cc.p(0,0))
	activityChargeWheelView:setPosition(cc.p(0,0))
	if self.showLayer[tostring(activityId)] then
		self.showLayer[tostring(activityId)]:removeFromParent()
	end
	self.showLayer[tostring(activityId)] = activityChargeWheelView

	local backgroundImage = self.activityHomeDatas[tostring(activityId)].backgroundImage[i18n.getLang()]

	activityChargeWheelView.viewData_.enterBtn:setTag(checkint(activityId))
	activityChargeWheelView.viewData_.enterBtn:setOnClickScriptHandler(handler(self, self.ChargeWheelEnterBtnCallback))
	activityChargeWheelView.viewData_.drawBtn:setTag(checkint(activityId))
	activityChargeWheelView.viewData_.drawBtn:setOnClickScriptHandler(handler(self, self.ChargeWheelTimesRewardsBtnCallback))
	activityChargeWheelView.viewData_.timeLabel:setString(self:ChangeTimeFormat(self.activityHomeDatas[tostring(activityId)].leftSeconds, ACTIVITY_TYPE.FULL_SERVER))
	activityChargeWheelView.viewData_.ruleLabel:setString(self.activityHomeDatas[tostring(activityId)].detail[i18n.getLang()])
	activityChargeWheelView.viewData_.bg:setWebURL(backgroundImage)
	activityChargeWheelView.viewData_.bg:setVisible(true)
	-- 判断是否存在次数奖励
	if activityDatas.timesRewards and next(activityDatas.timesRewards) ~= nil then
		activityChargeWheelView.viewData_.drawBtn:setVisible(true)
	else
		activityChargeWheelView.viewData_.drawBtn:setVisible(false)
		activityChargeWheelView.viewData_.enterBtn:setPositionX(754)
	end
	local rewardList = activityDatas.rewardList
	local midPointX = activityChargeWheelView.viewData_.rewardLayer:getContentSize().width / 2
	local midPointY = 108

	activityChargeWheelView.viewData_.rewardLayer:setVisible(true)
	local params = {parent = activityChargeWheelView.viewData_.rewardLayer, midPointX = midPointX, midPointY = midPointY, maxCol= 5, scale = 0.75, rewards = rewardList, hideAmount = true}
	local goodNodes, materialLbs = CommonUtils.createPropList(params)
	self:SetRuleLabelShow(activityChargeWheelView.viewData_.ruleLabel , activityChargeWheelView.viewData_.listView)
end
--[[
收费转盘活动前往按钮回调
--]]
function ActivityMediator:ChargeWheelEnterBtnCallback( sender )
	PlayAudioByClickNormal()
	local activityId = sender:getTag()
	local homeDatas = checktable(self.activityHomeDatas[tostring(activityId)])
	local activityDatas = checktable(self.activityDatas[tostring(activityId)])
	local tips = ''
	if homeDatas.rule and homeDatas.rule[i18n.getLang()] then
		tips = homeDatas.rule[i18n.getLang()]
	end
	local params = {
		content = activityDatas.rateRewards,
		leftBtnCost = activityDatas.oneConsumeGoods,
		rightBtnCost = activityDatas.tenConsumeGoods,
		leftDrawnTimes = activityDatas.leftDrawnTimes,
		activityId = activityDatas.requestData.activityId,
		leftBtnCallback = handler(self, self.ChargeWheelOneDrawBtnCallback),
		rightBtnCallback = handler(self, self.ChargeWheelMultiDrawBtnCallback),
		discount = activityDatas.discount,
		isFree = activityDatas.isOneFree,
		timesRewards = activityDatas.timesRewards,
		drawnTimes = checkint(activityDatas.drawnTimes),
		tips = tips,
	}
	if checkint(activityDatas.endStoryId) > 0 then -- 结束剧情
		local function closeCallback()
			app.activityMgr:ShowActivityStory({
				activityId = activityDatas.requestData.activityId,
				storyId = activityDatas.endStoryId,
				storyType = 'END',
			})
		end
		params.closeCallback = handler(self, closeCallback)
	end
	if homeDatas and next(homeDatas) ~= nil then -- 主活动
		params.leftSeconds = homeDatas.leftSeconds
	else -- 关联活动
		-- 关联活动的活动数据取当前所选择的页签数据
		local relateDatas = self.activityHomeDatas[tostring(self.selectedTab)]
		params.leftSeconds = relateDatas.leftSeconds
	end
	local function enterView ()
		local scene = AppFacade.GetInstance():GetManager("UIManager"):GetCurrentScene()
		local view = require("common.CommonWheelView").new(params)
		view:setName('wheelView')
		view:setPosition(display.center)
		scene:AddGameLayer(view)
	end

	if checkint(activityDatas.startStoryId) > 0 then
		app.activityMgr:ShowActivityStory({
			activityId = activityDatas.requestData.activityId,
			storyId = activityDatas.startStoryId,
			storyType = 'START',
			callback = enterView
		})
	else
		enterView()
	end
end
--[[
收费转盘次数累计领奖按钮回调
--]]
function ActivityMediator:ChargeWheelTimesRewardsBtnCallback( sender )
	local activityId = sender:getTag()
	local activityHomeDatas = self.activityHomeDatas[tostring(activityId)]
	local mediator = require( 'Game.mediator.ActivityPropExchangeMediator').new({data = {activityId = activityId, leftSeconds = activityHomeDatas.leftSeconds, tag = 110125}})
	self:GetFacade():RegistMediator(mediator)
end
--[[
收费转盘活动单抽按钮回调
--]]
function ActivityMediator:ChargeWheelOneDrawBtnCallback( sender )
	PlayAudioByClickNormal()
	local activityId = sender:getTag()
	local activityDatas = self.activityDatas[tostring(activityId)]
	if checkint(activityDatas.leftDrawnTimes) > 0 or checkint(activityDatas.leftDrawnTimes) == -1 then
		if activityDatas.isOneFree then
			self:ChargeWheelAddMaskView()
			self:SendSignal(COMMANDS.COMMAND_Activity_Draw_ChargeWheel, {activityId = activityId, drawTimes = 1})
		else
			for i,v in ipairs(activityDatas.oneConsumeGoods) do
				local hasNums = gameMgr:GetAmountByGoodId(v.goodsId)
				if checkint(hasNums) < checkint(v.num) then
					if GAME_MODULE_OPEN.NEW_STORE and checkint(v.goodsId) == DIAMOND_ID then
						app.uiMgr:showDiamonTips()
					else
						local goodsDatas = CommonUtils.GetConfig('goods', 'goods', v.goodsId)
						uiMgr:ShowInformationTips(string.fmt(__('_name_不足'), {['_name_'] = goodsDatas.name}))
					end
					return
				end
			end
		self:ChargeWheelAddMaskView()
		self:SendSignal(COMMANDS.COMMAND_Activity_Draw_ChargeWheel, {activityId = activityId, drawTimes = 1})
		end
	else
		uiMgr:ShowInformationTips(__('今日祈愿次数不足'))
	end
end
--[[
收费转盘活动十连按钮回调
--]]
function ActivityMediator:ChargeWheelMultiDrawBtnCallback( sender )
	PlayAudioByClickNormal()
	local activityId = sender:getTag()
	local activityDatas = self.activityDatas[tostring(activityId)]
	if checkint(activityDatas.leftDrawnTimes) >= 10 or checkint(activityDatas.leftDrawnTimes) == -1 then
		for i,v in ipairs(activityDatas.tenConsumeGoods) do
			local hasNums = gameMgr:GetAmountByGoodId(v.goodsId)
			if checkint(hasNums) < math.ceil(checkint(v.num) * checkint(activityDatas.discount)/100)  then
				if GAME_MODULE_OPEN.NEW_STORE and checkint(v.goodsId) == DIAMOND_ID then
					app.uiMgr:showDiamonTips()
				else
					local goodsDatas = CommonUtils.GetConfig('goods', 'goods', v.goodsId)
					uiMgr:ShowInformationTips(string.fmt(__('_name_不足'), {['_name_'] = goodsDatas.name}))
				end
				return
			end
		end
		self:ChargeWheelAddMaskView()
		self:SendSignal(COMMANDS.COMMAND_Activity_Draw_ChargeWheel, {activityId = activityId, drawTimes = 10})
	else
		uiMgr:ShowInformationTips(__('今日祈愿次数不足'))
	end
end
--[[
添加屏蔽层
--]]
function ActivityMediator:ChargeWheelAddMaskView()
	local scene = uiMgr:GetCurrentScene()
	scene:AddViewForNoTouch()
	local view = self:GetViewComponent()
	view:runAction(
		cc.Sequence:create(
			cc.DelayTime:create(3),
			cc.CallFunc:create(function()
				local wheelView = uiMgr:GetCurrentScene():GetGameLayerByName("wheelView")
				if not wheelView then
					scene:RemoveViewForNoTouch()
				end
			end)
		)
	)
end
--[[
收费转盘抽奖回调
--]]
function ActivityMediator:ChargeWheelDrawAction( datas )
	local activityId = datas.requestData.activityId
	local activityDatas = self.activityDatas[tostring(activityId)]
	-- 扣除道具
	if checkint(datas.requestData.drawTimes) == 1 then
		if activityDatas.isOneFree then
			activityDatas.isOneFree = false
		else
			local temp = clone(activityDatas.oneConsumeGoods)
			for i,v in ipairs(temp) do
				v.num = -v.num
			end
			CommonUtils.DrawRewards(temp)
		end
	else
		local temp = clone(activityDatas.tenConsumeGoods)
		for i,v in ipairs(temp) do
			if activityDatas.discount then
				v.num = -math.ceil(checkint(v.num) * checkint(activityDatas.discount) / 100)
			else
				v.num = -v.num
			end
		end
		CommonUtils.DrawRewards(temp)
	end
	if checkint(activityDatas.leftDrawnTimes) ~= -1 then
		local leftDrawnTimes = checkint(activityDatas.leftDrawnTimes) - checkint(datas.requestData.drawTimes)
		activityDatas.leftDrawnTimes = leftDrawnTimes
	end
	-- 判断红点状态
	if not self:GetChargeWheelRemindIconState(activityId) then
		self:ClearRemindIcon(activityId)
	end
	-- 转换奖励的数据结构
	local cloneDatas = clone(datas)
	local temp = {}
	cloneDatas.requestData = nil
	for i,v in orderedPairs(cloneDatas) do
		table.insert(temp, v)
	end
	-- 更新本地抽奖次数
	activityDatas.drawnTimes = checkint(activityDatas.drawnTimes) + #temp
	local wheelView = uiMgr:GetCurrentScene():GetGameLayerByName("wheelView")
	if wheelView then
		local closeAction = nil
		if checkint(activityDatas.endStoryGoods) > 0 then
			closeAction = self:ChargeWheelHasRareGoods(checkint(activityDatas.endStoryGoods), checkint(activityDatas.endStoryGoodsNum), temp)
		end
		wheelView:DrawAction({rateRewards = temp, closeAction = closeAction})
	end
end
--[[
判断付费转盘活动红点状态
--]]
function ActivityMediator:GetChargeWheelRemindIconState( activityId )
	local activityDatas = self.activityDatas[tostring(activityId)]
	if not activityDatas then return end
	local state = true
	if not activityDatas.isOneFree then -- 是否存在免费次数
		for i,v in ipairs(activityDatas.oneConsumeGoods) do -- 物品是否足够
			local hasNums = gameMgr:GetAmountByGoodId(v.goodsId)
			if checkint(hasNums) < checkint(v.num) then
				state = false
				break
			end
		end
	end
	if checkint(activityDatas.leftDrawnTimes) == 0 then -- 是否有抽奖次数
		state = false
	end
	return state
end
--[[
付费转盘兑换红点清空
--]]
function ActivityMediator:ChargeWheelRemindIconClear( activityId )
	local activityDatas = self.activityDatas[tostring(activityId)]
	local drawnTimes = checkint(activityDatas.drawnTimes)
	for k, v in pairs(activityDatas.timesRewards) do
		if drawnTimes >= checkint(v.times) then
			v.hasDrawn = 1
		end
	end
	-- 如果存在转盘页面，刷新页面
	local wheelView = uiMgr:GetCurrentScene():GetGameLayerByName("wheelView")
	if wheelView then
		wheelView:ChargeWheelRemindIconClear()
	end
end
--[[
判断是否抽到剧情关键道具或者剧情关键道具数目是足够
--]]
function ActivityMediator:ChargeWheelHasRareGoods( goodsId, goodsNum, rewards )
	local goodsEnough = false
	if checkint(goodsNum) > 1 then
		local hasNum = gameMgr:GetAmountByGoodId(checkint(goodsId))
		if checkint(hasNum) >= goodsNum then
			goodsEnough = true
		end
	elseif checkint(goodsNum) == 1 then
		for i,v in ipairs(checktable(rewards)) do
			if checkint(v.rewards[1].goodsId) == checkint(goodsId) then
				goodsEnough = true
				break
			end
		end
	end
	return goodsEnough
end
------------------------------收费转盘--------------------------
---------------------------------------------------------------

---------------------------------------------------------------
------------------------------循环任务--------------------------
--[[
循环任务前往按钮回调
--]]
function ActivityMediator:CyclicTasksEnterBtnCallback( sender )
	local activityId = sender:getTag()
	local mediator = require('Game.mediator.activity.cyclicTask.ActivityCyclicTaskMediator').new({activityHomeData = self.activityHomeDatas[tostring(activityId)]})
	app:RegistMediator(mediator)
end
------------------------------循环任务--------------------------
---------------------------------------------------------------

---------------------------------------------------------------
------------------------------餐厅活动--------------------------
function ActivityMediator:CreateLobbyFestivalActivity( activityId )
	local viewData = self:GetViewComponent().viewData
	local view = require( 'Game.views.ActivityExchangeView').new({tag = '2'})
	viewData.ActivityLayout:addChild(view, 10)
	view:setAnchorPoint(cc.p(0,0))
	view:setPosition(cc.p(0,0))
	self.showLayer[tostring(activityId)] = view

	local activityHomeData = checktable(self.activityHomeDatas[tostring(activityId)])
	local backgroundImage  = checktable(activityHomeData.backgroundImage)[i18n.getLang()]

	view.viewData_.enterBtn:setTag(checkint(activityId))
	view.viewData_.enterBtn:setOnClickScriptHandler(handler(self, self.enterAvatarMediator))
	view.viewData_.timeLabel:setString(self:ChangeTimeFormat(checkint(activityHomeData.leftSeconds), ACTIVITY_TYPE.FULL_SERVER))
	view.viewData_.ruleLabel:setString(tostring(checktable(activityHomeData.detail)[i18n.getLang()]))

	if backgroundImage and backgroundImage ~= '' then
		view.viewData_.bg:setWebURL(backgroundImage)
	else
		view.viewData_.bg:setTexture(_res('ui/home/activity/activity_restaurant_bg.png'))
	end

	self:updateLobbyFestivalActivity(activityId)
	self:SetRuleLabelShow(view.viewData_.ruleLabel , view.viewData_.listView)

end

function ActivityMediator:updateLobbyFestivalActivity(activityId)
	local view = self.showLayer[tostring(activityId)]
	if view == nil then
		self:CreateLobbyFestivalActivity(activityId)
		return
	end

	local restaurantActivity = gameMgr:GetUserInfo().restaurantActivity
	display.commonLabelParams(view.tagViewData_.title, {text = restaurantActivity.title[i18n.getLang()]})

	local removeLayerAllChildren = function (layer)
		if layer:getChildrenCount() > 0 then
			layer:removeAllChildren()
		end
	end

	local qCardLayer = view.tagViewData_.qCardLayer
	local firstGoodLayer = view.tagViewData_.firstGoodLayer
	local secondGoodLayer = view.tagViewData_.secondGoodLayer
	removeLayerAllChildren(firstGoodLayer)
	removeLayerAllChildren(secondGoodLayer)
	removeLayerAllChildren(qCardLayer)

	local content = checktable(restaurantActivity.content)
	for i,v in ipairs(content.customer or {}) do
		view:CreateSpineMonster(view.tagViewData_.qCardLayer, i, v)
	end

	local recipes = {}
	local rewards = {}
	local temp = {}
	for i,v in pairs(content.recipes or {}) do
		recipes[checkint(i)] = {goodsId = v.recipe, showAmount = false}
		for ii,vv in ipairs(v.rewards) do
			if temp[vv.goodsId] == nil then
				temp[vv.goodsId] = 1
				table.insert( rewards, vv)
			end
		end
	end
	-- 渲染 奖励
	local maxCol = 4

	local firstGoodLayerSize = firstGoodLayer:getContentSize()
	local recipesCount = #recipes
	local col = (recipesCount > maxCol) and maxCol or recipesCount
	for i,v in ipairs(recipes) do
		local menuViewData = view:CreateMenuGood()
		local goodBgSize = menuViewData.goodBgSize
		local pos = CommonUtils.getGoodPos({index = i, goodNodeSize = goodBgSize, midPointX = firstGoodLayerSize.width / 2, midPointY = firstGoodLayerSize.height / 2, col = col, maxCol = maxCol, goodGap = -10})
		display.commonUIParams(menuViewData.goodBgLayer, {po = pos, ap = display.CENTER})
		firstGoodLayer:addChild(menuViewData.goodBgLayer)
		menuViewData.goodNode:RefreshSelf(v)
	end


	local secondGoodLayerSize = secondGoodLayer:getContentSize()
	local midPointX = secondGoodLayerSize.width / 2
	local midPointY = secondGoodLayerSize.height / 2

	local params = {parent = secondGoodLayer, midPointX = midPointX, midPointY = midPointY, maxCol= maxCol, scale = 0.8, rewards = rewards, hideAmount = false, goodGap = 10}
	local goodNodes, materialLbs = CommonUtils.createPropList(params)
end

function ActivityMediator:enterAvatarMediator()
	AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = "ActivityMediator"}, {name = "AvatarMediator"})
end

------------------------------餐厅活动--------------------------
---------------------------------------------------------------

---------------------------------------------------------------
------------------------------外卖点活动------------------------
--[[
创建外卖点活动页签
--]]
function ActivityMediator:CreateTakeawayPointView( activityId )
	local viewData = self:GetViewComponent().viewData
	local activityTakeawayPointView = require('Game.views.ActivityTakeawayPointView').new()
	viewData.ActivityLayout:addChild(activityTakeawayPointView, 10)
	activityTakeawayPointView:setAnchorPoint(cc.p(0,0))
	activityTakeawayPointView:setPosition(cc.p(0,0))
	self.showLayer[tostring(activityId)] = activityTakeawayPointView

	local backgroundImage = self.activityHomeDatas[tostring(activityId)].backgroundImage[i18n.getLang()]

	activityTakeawayPointView.viewData_.wheelBtn:setOnClickScriptHandler(handler(self, self.ChargeWheelEnterBtnCallback))
	activityTakeawayPointView.viewData_.wheelBtn:setEnabled(true)
	activityTakeawayPointView.viewData_.exchangeBtn:setOnClickScriptHandler(handler(self, self.ExchangeEnterButtonCallback))
	activityTakeawayPointView.viewData_.exchangeBtn:setEnabled(true)
	activityTakeawayPointView.viewData_.timeLabel:setString(self:ChangeTimeFormat(self.activityHomeDatas[tostring(activityId)].leftSeconds, ACTIVITY_TYPE.COMMON_ACTIVITY))
	activityTakeawayPointView.viewData_.ruleLabel:setString(self.activityHomeDatas[tostring(activityId)].detail[i18n.getLang()])
	activityTakeawayPointView.viewData_.bg:setWebURL(backgroundImage)
	activityTakeawayPointView.viewData_.bg:setVisible(true)
	local activityDatas = self.activityDatas[tostring(activityId)]
	if activityDatas.relateActivities then
		self:RequestRelatedActivityDatas(activityDatas.relateActivities)
	end
	self:SetRuleLabelShow(activityTakeawayPointView.viewData_.ruleLabel , activityTakeawayPointView.viewData_.listView)
end
--[[
刷新外卖店活动页签
--]]
function ActivityMediator:RefreshTakeawayPointView( activityId )
	local activityTakeawayPointView = self.showLayer[tostring(activityId)]
	local activityDatas = self.activityDatas[tostring(activityId)]
	local wheelActivtyDatas = {}
	local exchangeActivityDatas = {}
	local viewData = activityTakeawayPointView.viewData_
	if activityDatas.relateActivities then
		for i,v in ipairs(activityDatas.relateActivities) do
			if tostring(v.relateActivityType) == ACTIVITY_TYPE.ITEMS_EXCHANGE then
				exchangeActivityDatas = self.activityDatas[tostring(v.relateActivityId)]
			elseif tostring(v.relateActivityType) == ACTIVITY_TYPE.CHARGE_WHEEL then
				wheelActivtyDatas = self.activityDatas[tostring(v.relateActivityId)]
			end
		end
	else
		return
	end
	-- 变更按钮状态
	viewData.wheelBtn:setTag(checkint(wheelActivtyDatas.requestData.activityId))
	viewData.wheelBtn:setEnabled(true)
	viewData.exchangeBtn:setTag(checkint(exchangeActivityDatas.requestData.activityId))
	viewData.exchangeBtn:setEnabled(true)
	-- 奖励一览
	local rewardDatas = {}
	if activityDatas.relateActivities then
		for i,v in ipairs(activityDatas.relateActivities) do
			if i == 1 then
				rewardDatas = clone(self.activityDatas[tostring(v.relateActivityId)].rewardList)
			else
				for _, newReward in ipairs(self.activityDatas[tostring(v.relateActivityId)].rewardList) do
					local isNew = true
					for _, reward in ipairs(rewardDatas) do
						if checkint(newReward.goodsId) == checkint(reward.goodsId) then
							isNew = false
							break
						end
					end
					if isNew then
						table.insert(rewardDatas, newReward)
					end
				end
			end
		end
	end
	----------暂用----------
	rewardDatas = exchangeActivityDatas.rewardList
	----------暂用----------
	local midPointX = activityTakeawayPointView.viewData_.rewardLayer:getContentSize().width / 2
	local midPointY = 108

	activityTakeawayPointView.viewData_.rewardLayer:setVisible(true)
	local params = {parent = activityTakeawayPointView.viewData_.rewardLayer, midPointX = midPointX, midPointY = midPointY, maxCol= 5, scale = 0.75, rewards = rewardDatas, hideAmount = true}
	local goodNodes, materialLbs = CommonUtils.createPropList(params)
	-- 刷新道具数量
	self:UpdateTakeawayPointViewGoodsNum(activityId)
end
--[[
刷新外卖点活动所持道具数目
@params activityId int 外卖点活动id
--]]
function ActivityMediator:UpdateTakeawayPointViewGoodsNum( activityId )
	local activityTakeawayPointView = self.showLayer[tostring(activityId)]
	if not activityTakeawayPointView then return end
	local activityDatas = self.activityDatas[tostring(activityId)]
	local wheelActivtyDatas = {}
	local exchangeActivityDatas = {}
	local viewData = activityTakeawayPointView.viewData_
	if activityDatas.relateActivities then
		for i,v in ipairs(activityDatas.relateActivities) do
			if tostring(v.relateActivityType) == ACTIVITY_TYPE.ITEMS_EXCHANGE then
				exchangeActivityDatas = self.activityDatas[tostring(v.relateActivityId)]
			elseif tostring(v.relateActivityType) == ACTIVITY_TYPE.CHARGE_WHEEL then
				wheelActivtyDatas = self.activityDatas[tostring(v.relateActivityId)]
			end
		end
	else
		return
	end
	-- 抽奖道具
	local whGoodsId = wheelActivtyDatas.oneConsumeGoods[1].goodsId
	viewData.wheelGoodsIcon:setTexture(CommonUtils.GetGoodsIconPathById(whGoodsId))
 	display.reloadRichLabel(viewData.wheelRichLabel, {c = {
		fontWithColor(18, {text = string.fmt(__('拥有:_num_'), {['_num_'] = gameMgr:GetAmountByGoodId(whGoodsId)})})
		-- {img = CommonUtils.GetGoodsIconPathById(whGoodsId), scale = 0.18}
 	}})
 	-- 兑换道具
 	local exGoodsId = exchangeActivityDatas.exchange[1].require[1].goodsId
 	viewData.exchangeGoodsIcon:setTexture(CommonUtils.GetGoodsIconPathById(exGoodsId))
 	display.reloadRichLabel(viewData.exchangeRichLabel, {c = {
		fontWithColor(18, {text = string.fmt(__('拥有:_num_'), {['_num_'] = gameMgr:GetAmountByGoodId(exGoodsId)})})
		-- {img = CommonUtils.GetGoodsIconPathById(exGoodsId), scale = 0.18}
 	}})
end
------------------------------外卖点活动------------------------
---------------------------------------------------------------
------------------------------拼图活动--------------------------
function ActivityMediator:CreateBinggoActivity(activityId)
	local viewData = self:GetViewComponent().viewData

	local view = require( 'Game.views.ActivityBinggoPageView').new()
	viewData.ActivityLayout:addChild(view, 10)
	view:setAnchorPoint(cc.p(0,0))
	view:setPosition(cc.p(0,0))
	self.showLayer[tostring(activityId)] = view

	local viewData = view:getViewData()

	local gridView = viewData.gridView
	gridView:setDataSourceAdapterScriptHandler(handler(self, self.onBinggoActivityDataSource))

	local backgroundImage = self.activityHomeDatas[tostring(activityId)].backgroundImage[i18n.getLang()]
	viewData.bg:setWebURL(backgroundImage)
	viewData.bg:setVisible(true)

	viewData.enterBtn:setTag(checkint(activityId))
	viewData.enterBtn:setOnClickScriptHandler(handler(self, self.enterBinggoMediator))

	viewData.timeLabel:setString(self:ChangeTimeFormat(self.activityHomeDatas[tostring(activityId)].leftSeconds, ACTIVITY_TYPE.BINGGO))
	viewData.ruleLabel:setString(self.activityHomeDatas[tostring(activityId)].detail[i18n.getLang()])

	self:updateBinggoActivity(activityId)
	self:SetRuleLabelShow(viewData.ruleLabel , viewData.listView)
end

function ActivityMediator:updateBinggoActivity(activityId)
	local view = self.showLayer[tostring(activityId)]
	if view == nil then
		-- self:CreateBinggoActivity(activityId)
		return
	end

	local viewData = view:getViewData()

	local homeData = self.activityHomeDatas[tostring(activityId)].homeDatas
	local skinId = homeData.finalRewards[1].goodsId
	local finalRewardsHasDrawn = homeData.finalRewardsHasDrawn
	view:updateRoleImg(finalRewardsHasDrawn ~= 0, skinId)

	-- local canOpenCoverCount = checkint(homeData.canOpenCoverCount)
	-- -- 能领翻拍奖励 或者 (没领过最终奖励 并且 没有)
	-- local isLight = canOpenCoverCount > 0 or (finalRewardsHasDrawn == 0 and surplusCoverCount == 0)
	-- local redPoint = viewData.enterBtn:getChildByName('BTN_RED_POINT')
	-- redPoint:setVisible(isLight)

	local gridView = viewData.gridView
	gridView:setCountOfCell(#homeData.allGroupTask)
	gridView:reloadData()

end

function ActivityMediator:enterBinggoMediator(sender)
	PlayAudioByClickNormal()

	local activityId = sender:getTag()
	local activityHomeDatas = self.activityHomeDatas[tostring(activityId)] or {}
	local homeDatas = activityHomeDatas.homeDatas
	local leftSeconds = activityHomeDatas.leftSeconds
	local endStoryId = homeDatas.endStoryId

	local enterView = function ()
		local mediator = require( 'Game.mediator.ActivityBinggoMediator').new({data = {
			activityId = activityId, activityHomeDatas = homeDatas,
			leftSeconds = leftSeconds, endStoryId = endStoryId}})
		self:GetFacade():RegistMediator(mediator)
	end

	if checkint(homeDatas.startStoryId) > 0 then
		app.activityMgr:ShowActivityStory({
			activityId = activityId,
			storyId = homeDatas.startStoryId,
			storyType = 'START',
			callback = enterView
		})
	else
		enterView()
	end
end

function ActivityMediator:onBinggoActivityDataSource(p_convertview, idx)
	local pCell = p_convertview
    local index = idx + 1
    -- local size = cc.size(212, 88)
	local activityHomeData = self.activityHomeDatas[tostring(self.selectedTab)]
	if activityHomeData == nil then return end

	if pCell == nil then
        pCell = require("home.ActivityBinggoCell").new()
		display.commonUIParams(pCell:getViewData().boxLayer, {cb = handler(self, self.onDrawBinggoTaskAction), animate = false})
	end

	xTry(function()
		local viewData      = pCell:getViewData()

		local homeData      = activityHomeData.homeDatas
		if homeData and homeData.allGroupTask and homeData.allGroupTask[index] then
			local groupData  = homeData.allGroupTask[index]

			local descLabel     = viewData.descLabel
			display.commonLabelParams(descLabel, {text = string.fmt(__('完成拼图_desc_任务'), {_desc_ = tostring(groupData.desc)})})

			local progressLabel = viewData.progressLabel

			local groupTaskProgress = groupData.groupTaskProgress
			local groupTaskTargetNum = groupData.groupTaskTargetNum
			local hasDrawn  = groupData.hasDrawn

			local bgBlack = viewData.bgBlack
			bgBlack:setVisible(hasDrawn)

			local c = nil
			local isCompleteProgress = groupTaskProgress >= groupTaskTargetNum
			if hasDrawn then
				c = {
					fontWithColor(16, {text = string.format("(%s/%s)", groupTaskProgress, groupTaskTargetNum)})
				}
			elseif isCompleteProgress then
				c = {
					fontWithColor(16, {text = string.format("(%s/%s)", groupTaskProgress, groupTaskTargetNum)})
				}
			else
				c = {
					fontWithColor(16, {text = "("}),
					fontWithColor(10, {fontSize = 22, text = groupTaskProgress}),
					fontWithColor(16, {text = string.format( "/%s)", groupTaskTargetNum)}),
				}
			end

			display.reloadRichLabel(progressLabel, {c = c})

			local boxLayer = viewData.boxLayer
			boxLayer:setTag(index)
			self:updateBoxState(viewData, hasDrawn, isCompleteProgress)
		end


	end,__G__TRACKBACK__)

	return pCell
end

function ActivityMediator:updateBoxState(viewData, hasDrawn, isCompleteProgress)
	local rewardBox = viewData.rewardBox

	rewardBox:setToSetupPose()
	if hasDrawn then
		rewardBox:setAnimation(0, 'play', true)
	elseif isCompleteProgress then
		rewardBox:setAnimation(0, 'idle', true)
	else
		rewardBox:setAnimation(0, 'stop', true)
	end
end

function ActivityMediator:onDrawBinggoTaskAction(sender)
	PlayAudioByClickNormal()
	local index = sender:getTag()
	local activityHomeData = self.activityHomeDatas[tostring(self.selectedTab)]
	if activityHomeData == nil  then return end

	local homeData      = activityHomeData.homeDatas

	if homeData and homeData.allGroupTask and homeData.allGroupTask[index] then

		local groupTaskData = homeData.allGroupTask[index]
		local hasDrawn  = groupTaskData.hasDrawn
		local groupTaskProgress = groupTaskData.groupTaskProgress
		local groupTaskTargetNum = groupTaskData.groupTaskTargetNum
		if hasDrawn then
			uiMgr:ShowInformationTips(__('该奖励已领取'))
		elseif groupTaskProgress >= groupTaskTargetNum then
			self:SendSignal(COMMANDS.COMMAND_Activity_Draw_BinggoTask, {activityId = checkint(self.selectedTab), type = 1, taskGroupId = checkint(groupTaskData.groupId), index = index})
		else
			local rewards = groupTaskData.rewards or {}
			uiMgr:ShowInformationTipsBoard({targetNode = sender, iconIds = rewards, type = 4})
		end
	end

end

function ActivityMediator:initBinggoActivityData(datas)

	local temp = {}
	-- 保存 所有拼图对应的任务 格式：[1] = {{}, {}}
	local binggoTasks = {}
	-- 保存所有 组任务
	local allGroupTask = {}
	-- 总任务进度
	local taskTotalProgress = 0
	-- 总任务所需进度
	local taskTotalTargetNum = 0
	-- 能领取组任务的奖励个数
	local canReceiveGroupTaskCount = 0
	-- 能翻牌的个数
	local canOpenCoverCount = 0
	-- 剩余遮盖个数
	local surplusCoverCount = 0

	for groupId,groupData in pairs(datas.allTask) do
		groupData.groupId = groupId
		local desc = ''
		local groupTask = groupData.tasks

		local groupTaskTargetNum = #groupTask
		local groupTaskProgress = 0

		for i = 1, groupTaskTargetNum do
			local task = groupTask[i]
			local binggoId = checkint(task.binggoId)
			desc = desc .. task.binggoId
			if i ~= groupTaskTargetNum then
				desc = desc .. '.'
			end
			task.desc = desc

			local progress = checkint(task.progress)
			local target = checkint(task.target)
			if temp[task.taskId] == nil then
				taskTotalTargetNum = taskTotalTargetNum + 1

				local isCompleteProgress = progress >= target
				if isCompleteProgress then
					taskTotalProgress = taskTotalProgress + 1
				end

				-- 没翻过牌子  并且 进度完成  添加红点
				if checkint(task.isBinggoOpen) == 0 then
					surplusCoverCount = surplusCoverCount + 1
					if isCompleteProgress then
						canOpenCoverCount = canOpenCoverCount + 1
					end
				end

				binggoTasks[binggoId] = binggoTasks[binggoId] or {}
				table.insert(binggoTasks[binggoId], task)
			end

			if progress >= target then
				groupTaskProgress = groupTaskProgress + 1
			end

			temp[task.taskId] = true
		end

		-- 没领取过组任务奖励 并且 组任务完成 添加红点
		if not groupData.hasDrawn and groupTaskProgress >= groupTaskTargetNum then
			canReceiveGroupTaskCount = canReceiveGroupTaskCount + 1
		end

		groupData.groupTaskTargetNum = groupTaskTargetNum
		groupData.groupTaskProgress  = groupTaskProgress
		groupData.desc = desc

		table.insert(allGroupTask, groupData)
	end

	datas.allTask = nil
	datas.binggoTasks = binggoTasks
	datas.allGroupTask = allGroupTask
	datas.taskTotalProgress = taskTotalProgress
	datas.taskTotalTargetNum = taskTotalTargetNum
	datas.canReceiveGroupTaskCount = canReceiveGroupTaskCount
	datas.canOpenCoverCount = canOpenCoverCount
	datas.surplusCoverCount = surplusCoverCount
	-- print(canReceiveGroupTaskCount, canOpenCoverCount, surplusCoverCount, 'dhhohdacoiwe')
	return datas
end

function ActivityMediator:checkBinggoRedPoint(activityId)
	local activityHomeData = self.activityHomeDatas[tostring(activityId)]
	if activityHomeData == nil then return end

	local homeDatas = activityHomeData.homeDatas
	if homeDatas == nil then return end

	local canReceiveGroupTaskCount = checkint(homeDatas.canReceiveGroupTaskCount)
	local canOpenCoverCount = checkint(homeDatas.canOpenCoverCount)
	local finalRewardsHasDrawn = checkint(homeDatas.finalRewardsHasDrawn)
	local surplusCoverCount = checkint(homeDatas.surplusCoverCount)

	-- 外部红点
	local externalRedPoint = canReceiveGroupTaskCount > 0
	-- 内部红点
	local insideRedPoint = (canOpenCoverCount > 0 or (finalRewardsHasDrawn == 0 and surplusCoverCount == 0))
	-- 总红点
	app.badgeMgr:SetActivityTipByActivitiyId(activityId, (externalRedPoint or insideRedPoint) and 1 or 0)
	if checkint(gameMgr:GetUserInfo().binggoTask[tostring(activityId)]) == 1 then
		self:AddRemindIcon(activityId)
	else
		self:ClearRemindIcon(activityId)
	end

	local view = self.showLayer[tostring(activityId)]
	if view then
		local viewData = view:getViewData()
		local redPoint = viewData.enterBtn:getChildByName('BTN_RED_POINT')
		redPoint:setVisible(insideRedPoint)
	end
end

function ActivityMediator:binggoGroupTaskSort(allGroupTask)

	local getPriorityByData = function (data)
		local priority = 0
		if not data.hasDrawn then
			local groupTaskTargetNum = data.groupTaskTargetNum
			local groupTaskProgress = data.groupTaskProgress

			if groupTaskProgress >= groupTaskTargetNum then
				priority = priority + 1
			end
			priority = priority + 1
		else
			priority = 0
		end

		return priority
	end

	local sortfunction = function (a, b)
		if a == nil then return true end
		if b == nil then return false end

		local aPriority = getPriorityByData(a)
		local bPriority = getPriorityByData(b)

		local aGroupId = a.groupId
		local bGroupId = b.groupId
		if aPriority == bPriority then
			return aGroupId < bGroupId
		end

		return aPriority > bPriority
	end
	table.sort( allGroupTask, sortfunction )
end

------------------------------拼图活动--------------------------
---------------------------------------------------------------

----------------------------------------------------------------
----------------------------宝箱兑换活动-------------------------
function ActivityMediator:CreateChestExchangeView( activityId )
	local activityHomeDatas = self.activityHomeDatas[tostring(activityId)]
	local activityDatas = self.activityDatas[tostring(activityId)]
	local params = {
		btnTag = checkint(activityId),
		btnCallback = handler(self, self.ChestExchangeEnterBtnCallback),
		btnText = __("去煮粥"),
		bgImageURL = activityHomeDatas.backgroundImage[i18n.getLang()],
		timeText = self:ChangeTimeFormat(activityHomeDatas.leftSeconds, ACTIVITY_TYPE.COMMON_ACTIVITY),
		ruleText = activityHomeDatas.detail[i18n.getLang()]
	}
	local chestExchangeView = self:CreateActivityView(activityId, 'ActivityCommonView', params)
	-- 奖励预览
	for i,v in ipairs(activityDatas.exchange) do
		if i <= 3 then
			local size = cc.size(152, 150)
			local layout = CLayout:create(size)
			local goodsConfig = CommonUtils.GetConfig('goods', 'goods', v.rewards[1].goodsId)
			local goodsIcon = display.newButton(size.width/2, 100, {n = CommonUtils.GetGoodsIconPathById(v.rewards[1].goodsId)})
			goodsIcon:setScale(0.8)
			layout:addChild(goodsIcon)
			goodsIcon:setOnClickScriptHandler(function ( sender )
				uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = v.rewards[1].goodsId, type = 1})
			end)
			local nameLabel = display.newLabel(size.width/2, 26, fontWithColor(4, {text = goodsConfig.name}))
			layout:addChild(nameLabel)
			chestExchangeView.viewData_.view:addChild(layout, 10)
			display.commonUIParams(layout, {po = cc.p(412 + i*150, 276), ap = cc.p(0, 0)})
		end
	end
end
--[[
宝箱兑换活动前往按钮回调
--]]
function ActivityMediator:ChestExchangeEnterBtnCallback( sender )
	PlayAudioByClickNormal()
	local activityId = sender:getTag()
	local activityDatas = self.activityDatas[tostring(activityId)]
    local function enterActivityView()
		local chestExchangeView  = require( 'Game.views.ChestExchangeView' ).new({exchangeDatas = activityDatas.exchange, activityId = activityId, exchangeCallback = handler(self, self.ChestExchangeDrawCallback)})
		chestExchangeView:setPosition(cc.p(display.cx, display.cy))
		chestExchangeView:setName('chestExchangeView')
		local scene = uiMgr:GetCurrentScene()
		scene:AddDialog(chestExchangeView)
    end
	if checkint(activityDatas.startStoryId) > 0 then
		-- 判断是否跳过剧情
    	local actStoryKey  = string.format('IS_%s_ACTIVITY_START_STORY_SHOWED_%s', tostring(activityId), tostring(gameMgr:GetUserInfo().playerId))
    	local isSkipStory = cc.UserDefault:getInstance():getBoolForKey(actStoryKey, false)
    	if isSkipStory then
    		enterActivityView()
    	else
    	    local storyPath  = string.format('conf/%s/activity/festivalStory.json', i18n.getLang())
    	    local storyStage = require('Frame.Opera.OperaStage').new({id = checkint(activityDatas.startStoryId), path = storyPath, guide = true, cb = function(sender)
    	        cc.UserDefault:getInstance():setBoolForKey(actStoryKey, true)
    	        enterActivityView()
    	    end})
    	    storyStage:setPosition(display.center)
    	    sceneWorld:addChild(storyStage, GameSceneTag.Dialog_GameSceneTag)
    	end
	else
		enterActivityView()
	end

end
--[[
兑换按钮回调
@params activityId int 活动id
exchangeId int 兑换id
num int 兑换数量
--]]
function ActivityMediator:ChestExchangeDrawCallback( activityId, exchangeId, num )
	PlayAudioByClickNormal()
	self:SendSignal(COMMANDS.COMMAND_Activity_ChestExchange, {activityId = activityId, exchangeId = exchangeId, num = num})
end
--[[
宝箱兑换领奖回调
--]]
function ActivityMediator:ChestExchangeDrawAction( datas )
	local activityId = datas.requestData.activityId
	local activityDatas = checktable(self.activityDatas[tostring(datas.requestData.activityId)])
	local scene = uiMgr:GetCurrentScene()
	local index = nil
	for i, v in ipairs(checktable(activityDatas.exchange)) do
    	if checkint(v.id) == checkint(datas.requestData.exchangeId) then
    		index = i
    		break
    	end
    end
	-- 扣除道具
	local count = checkint(datas.requestData.num or 1)
	local requireGoods = clone(activityDatas.exchange[index].require)
	for i,v in ipairs(requireGoods) do
		v.num = -v.num * count
	end
	CommonUtils.DrawRewards(requireGoods, true)

	-- 执行动画
	local colorView = CColorView:create(cc.c4b(0, 0, 0, 255 * 0.6))
	colorView:setContentSize(display.size)
	colorView:setTouchEnabled(true)
	display.commonUIParams(colorView, {po = display.center, ap = display.CENTER})
	scene:AddDialog(colorView)
	local animation = sp.SkeletonAnimation:create(
      'effects/activity/zhaotai.json',
      'effects/activity/zhaotai.atlas',
      1)
    animation:update(0)
    animation:setToSetupPose()
    animation:setAnimation(0, 'play', false)
    animation:setPosition(cc.p(display.cx, display.cy - 570))
    colorView:addChild(animation, 10)
    animation:registerSpineEventHandler(function ()
    	animation:unregisterSpineEventHandler(sp.EventType.ANIMATION_END)
    	scene:RemoveDialog(colorView)
    	uiMgr:AddDialog('common.RewardPopup', {rewards = datas.rewards, closeCallback = function ()
			-- 判断是否达成剧情解锁条件
			local hasNum = gameMgr:GetAmountByGoodId(checkint(activityDatas.endStoryGoods))
			local targetNum = checkint(activityDatas.endStoryGoodsNum)
			if checkint(hasNum) >= targetNum and checkint(activityDatas.endStoryId) > 0  then
				-- 判断是否跳过剧情
    			local actStoryKey  = string.format('IS_%s_ACTIVITY_END_STORY_SHOWED_%s', tostring(activityId), tostring(gameMgr:GetUserInfo().playerId))
    			local isSkipStory = cc.UserDefault:getInstance():getBoolForKey(actStoryKey, false)
    			if not isSkipStory then
    			    local storyPath  = string.format('conf/%s/activity/festivalStory.json', i18n.getLang())
    			    local storyStage = require('Frame.Opera.OperaStage').new({id = checkint(activityDatas.endStoryId), path = storyPath, guide = true, cb = function(sender)
    			        cc.UserDefault:getInstance():setBoolForKey(actStoryKey, true)
    			    end})
    			    storyStage:setPosition(display.center)
    			    sceneWorld:addChild(storyStage, GameSceneTag.Dialog_GameSceneTag)
    			end
			end
    	end})
    	-- 刷新ui
    	local chestExchangeView = scene:GetDialogByName('chestExchangeView')
    	if chestExchangeView then
			chestExchangeView:RefreshAllExchangeCell()
		end
    end, sp.EventType.ANIMATION_END)
end

----------------------------宝箱兑换活动-------------------------
----------------------------------------------------------------

----------------------------------------------------------------
----------------------------登录礼包活动-------------------------
--[[
创建登录礼包活动页面
--]]
function ActivityMediator:CreateLoginRewardView( activityId )
	local activityHomeDatas = self.activityHomeDatas[tostring(activityId)]
	local activityDatas = self.activityDatas[tostring(activityId)]
	local params = {
		showBtn = false,
		bgImageURL = activityHomeDatas.backgroundImage[i18n.getLang()],
		timeText = self:ChangeTimeFormat(activityHomeDatas.leftSeconds, ACTIVITY_TYPE.COMMON_ACTIVITY),
		ruleText = activityHomeDatas.detail[i18n.getLang()]
	}
	local loginRewardView = self:CreateActivityView(activityId, 'ActivityCommonView', params)
    local gridViewSize = cc.size(556, 416)
    local gridViewCellSize = cc.size(556, 150)
    local gridView = CGridView:create(gridViewSize)
    gridView:setName('gridView')
    gridView:setAnchorPoint(cc.p(1, 0))
    gridView:setSizeOfCell(gridViewCellSize)
    gridView:setPosition(cc.p(loginRewardView.viewData_.size.width, 149))
    gridView:setColumns(1)
    gridView:setAutoRelocate(true)
    loginRewardView.viewData_.view:addChild(gridView, 10)

    local function LoginRewardDataSource( p_convertview, idx )
		local pCell = p_convertview
    	local index = idx + 1
    	local cSize = cc.size(556, 150)

    	if pCell == nil then
    	    pCell = ActivityLoginRewardCell.new(cSize)
    	    pCell.drawBtn:setOnClickScriptHandler(handler(self, self.LoginRewardDrawBtnCallback))
    	    pCell.drawBtn:setTag(checkint(activityId))
    	end
		xTry(function()
			local datas = self.activityDatas[tostring(activityId)]
			local contentDatas = datas.loginRewardList[index]
			local isHighlight = true -- 是否高亮
			-- 改变领取按钮状态
			if index < checkint(datas.today) then
				isHighlight = false
				if checkint(contentDatas.hasDrawn) == 1 then
					-- 已领取
					pCell.mask:setVisible(true)
					pCell.drawLabel:setString(__('已领取'))
					pCell.drawBtn:setVisible(false)
				else
					-- 已过期
					pCell.mask:setVisible(true)
					pCell.drawLabel:setString(__('已过期'))
					pCell.drawBtn:setVisible(true)
					pCell.drawBtn:setEnabled(false)
					pCell.drawBtn:setNormalImage(_res('ui/common/common_btn_orange_disable.png'))
					pCell.drawBtn:setSelectedImage(_res('ui/common/common_btn_orange_disable.png'))
				end
			elseif index == checkint(datas.today) then
				if checkint(contentDatas.hasDrawn) == 0 then
					-- 可领取
					pCell.mask:setVisible(false)
					pCell.drawLabel:setString(__('领取'))
					pCell.drawBtn:setNormalImage(_res('ui/common/common_btn_orange.png'))
					pCell.drawBtn:setSelectedImage(_res('ui/common/common_btn_orange.png'))
					pCell.drawBtn:setEnabled(true)
					pCell.drawBtn:setVisible(true)
				elseif checkint(contentDatas.hasDrawn) == 1 then
					-- 已领取
					isHighlight = false
					pCell.mask:setVisible(true)
					pCell.drawLabel:setString(__('已领取'))
					pCell.drawBtn:setVisible(false)
				end
			else
				-- 不可领取
				pCell.mask:setVisible(false)
				pCell.drawLabel:setString(__('未领取'))
				pCell.drawBtn:setNormalImage(_res('ui/common/common_btn_orange_disable.png'))
				pCell.drawBtn:setSelectedImage(_res('ui/common/common_btn_orange_disable.png'))
				pCell.drawBtn:setEnabled(false)
				pCell.drawBtn:setVisible(true)
			end
			if not isJapanSdk() then display.commonLabelParams(pCell.drawLabel ,{reqW = 110}) end
			-- 添加奖励
			for i, v in ipairs(pCell.goodsTable) do
				if contentDatas.rewards[i] then
					local rewardDatas = contentDatas.rewards[i]
					v:setVisible(true)
					v:RefreshSelf({goodsId = rewardDatas.goodsId, amount = rewardDatas.num, highlight = (isHighlight and checkint(rewardDatas.highlight)) or 0 , showAmount = true})
					v.callBack = function (sender)
						PlayAudioByClickNormal()
						AppFacade.GetInstance():GetManager("UIManager"):ShowInformationTipsBoard({targetNode = sender, iconId = rewardDatas.goodsId, type = 1})
					end
				else
					v:setVisible(false)
				end
			end
			pCell.numLabel:setString(string.fmt(__('第_num_天'), {_num_ = tostring(index)}))
		end,__G__TRACKBACK__)
    	return pCell
    end
    gridView:setDataSourceAdapterScriptHandler(LoginRewardDataSource)
    gridView:setCountOfCell(#activityDatas.loginRewardList)
    self:LoginRewardRefreshGridView(activityId)
end
--[[
登录礼包活动领奖
--]]
function ActivityMediator:LoginRewardDrawBtnCallback( sender )
	PlayAudioByClickNormal()
	local activityId = sender:getTag()
	self:SendSignal(COMMANDS.COMMAND_Activity_Draw_LoginReward, {activityId = checkint(activityId)})
end
--[[
登录礼包活动领奖处理
--]]
function ActivityMediator:LoginRewardDrawAction( rewardDatas )
	uiMgr:AddDialog('common.RewardPopup', {rewards = checktable(rewardDatas.rewards)})
	local activityDatas = self.activityDatas[tostring(rewardDatas.requestData.activityId)]
	activityDatas.loginRewardList[checkint(activityDatas.today)].hasDrawn = 1
	self:LoginRewardRefreshGridView(checkint(rewardDatas.requestData.activityId))
end
--[[
登录礼包活动刷新奖励列表
--]]
function ActivityMediator:LoginRewardRefreshGridView( activityId )
	local actView = self.showLayer[tostring(activityId)]
	local gridView = actView and actView.viewData_.view:getChildByName('gridView')
	local activityDatas = self.activityDatas[tostring(activityId)]
	local rewardNums = #checktable(activityDatas.loginRewardList)
	gridView:reloadData()
	if checkint(activityDatas.today) > rewardNums - 2 then
		gridView:setContentOffset(cc.p(0, 0))
	else
		gridView:setContentOffset(cc.p(0, -rewardNums*150+266 + checkint(activityDatas.today)*150))
	end
end
----------------------------登录礼包活动-------------------------
----------------------------------------------------------------

----------------------------------------------------------------
-----------------------------CV分享活动--------------------------
--[[
cv分享活动前往按钮回调
--]]
function ActivityMediator:CVShareEnterBtnCallback( sender )
	local activityId = nil
	if type(sender) == 'number' then
		activityId = sender
	else
		PlayAudioByClickNormal()
		activityId = sender:getTag()
	end
	local activityHomeDatas = self.activityHomeDatas[tostring(activityId)]
	local mediator = require("Game.mediator.ActivityCVShareMediator").new(activityHomeDatas)
	self:GetFacade():RegistMediator(mediator)
end
-----------------------------CV分享活动--------------------------
----------------------------------------------------------------

----------------------------------------------------------------
-----------------------------累充活动----------------------------
--[[
创建累充活动活动页签
--]]
function ActivityMediator:CreateAccumulativeRechargeView(activityId)
	local viewData = self:GetViewComponent().viewData
	local function CreateView( viewName, datas )
		local view = require( 'Game.views.' .. viewName).new(datas)
		viewData.ActivityLayout:addChild(view, 10)
		view:setAnchorPoint(cc.p(0,0))
		view:setPosition(cc.p(0,0))
		if self.showLayer[tostring(activityId)] then
			self.showLayer[tostring(activityId)]:removeFromParent()
		end
		self.showLayer[tostring(activityId)] = view
		return view
	end
	local backgroundImage = self.activityHomeDatas[tostring(activityId)].backgroundImage[i18n.getLang()]
	local activityExchangeView = CreateView('ActivityExchangeView', {tag = '1'})
	local redPoint = activityExchangeView.viewData_.enterBtn:getChildByName('BTN_RED_POINT')
	redPoint:setVisible(app.badgeMgr:GetActivityTipByActivitiyId(activityId) == 1)
	activityExchangeView.viewData_.enterBtn:setTag(checkint(activityId))
	activityExchangeView.viewData_.enterBtn:setOnClickScriptHandler(handler(self, self.AccumulativeRechargeButtonCallback))
	activityExchangeView.viewData_.timeLabel:setString(self:ChangeTimeFormat(self.activityHomeDatas[tostring(activityId)].leftSeconds, ACTIVITY_TYPE.FULL_SERVER))
	activityExchangeView:setRuleText(self.activityHomeDatas[tostring(activityId)].detail[i18n.getLang()])
	activityExchangeView.viewData_.bg:setWebURL(backgroundImage)
	-- 添加奖励预览
	local rewardLayer = activityExchangeView.tagViewData_.rewardLayer
	local activityDatas = self.activityDatas[tostring(activityId)]
	local rewardList = {}
	local temp = {}
	for i,v in ipairs(activityDatas.accumulativeList) do
		for ii,vv in ipairs(checktable(v.rewards)) do
			if temp[vv.goodsId] == nil then
				temp[vv.goodsId] = 1
				table.insert(rewardList, vv)
			end
		end
	end
	local midPointX = rewardLayer:getContentSize().width / 2
	local midPointY = 108
	rewardLayer:setVisible(true)
	local params = {parent = rewardLayer, midPointX = midPointX, midPointY = midPointY, maxCol= 5, scale = 0.75, rewards = rewardList, hideAmount = true, needScroll = true, hideCustomizeLabel = true}
	local goodNodes, materialLbs = CommonUtils.createPropList(params)
end
--[[
累充活动前往按钮点击回调
--]]
function ActivityMediator:AccumulativeRechargeButtonCallback( sender )
	PlayAudioByClickNormal()
	local activityId = sender:getTag()
	local activityDatas = self.activityDatas[tostring(activityId)]
	local activityHomeDatas = self.activityHomeDatas[tostring(activityId)]
	activityHomeDatas.homeDatas = clone(activityDatas)
	local mediator = require( 'Game.mediator.ActivityPropExchangeMediator').new({data = {activityId = activityId, activityHomeDatas = activityHomeDatas, leftSeconds = activityHomeDatas.leftSeconds, tag = 110122}})
	self:GetFacade():RegistMediator(mediator)
end
--[[
更新累充活动小红点是否展示
--]]
function ActivityMediator:UpdateAccumulativeRechargeRedPoint(activityId)
	local view = self.showLayer[tostring(activityId)]
	local redPointState = app.badgeMgr:GetActivityTipByActivitiyId(activityId)
	redPointState = redPointState ~= nil and redPointState or 0
	if view then
		local enterBtn = view.viewData_.enterBtn
		local redPoint = enterBtn:getChildByName('BTN_RED_POINT')
		redPoint:setVisible(redPointState == 1)
	end
	if redPointState == 1 then
		self:AddRemindIcon(activityId)
	else
		self:ClearRemindIcon(activityId)
	end
end
-----------------------------累充活动----------------------------
----------------------------------------------------------------

----------------------------------------------------------------
-----------------------------累消活动----------------------------
--[[
创建累消活动活动页签
--]]
function ActivityMediator:CreateAccumulativeConsumeView( activityId )
	local viewData = self:GetViewComponent().viewData
	local function CreateView( viewName, datas )
		local view = require( 'Game.views.' .. viewName).new(datas)
		viewData.ActivityLayout:addChild(view, 10)
		view:setAnchorPoint(cc.p(0,0))
		view:setPosition(cc.p(0,0))
		if self.showLayer[tostring(activityId)] then
			self.showLayer[tostring(activityId)]:removeFromParent()
		end
		self.showLayer[tostring(activityId)] = view
		return view
	end
	local backgroundImage = self.activityHomeDatas[tostring(activityId)].backgroundImage[i18n.getLang()]
	local activityExchangeView = CreateView('ActivityExchangeView', {tag = '1'})
	local redPoint = activityExchangeView.viewData_.enterBtn:getChildByName('BTN_RED_POINT')
	redPoint:setVisible(app.badgeMgr:GetActivityTipByActivitiyId(activityId) == 1)
	activityExchangeView.viewData_.enterBtn:setTag(checkint(activityId))
	activityExchangeView.viewData_.enterBtn:setOnClickScriptHandler(handler(self, self.AccumulativeConsumeButtonCallback))
	activityExchangeView.viewData_.timeLabel:setString(self:ChangeTimeFormat(self.activityHomeDatas[tostring(activityId)].leftSeconds, ACTIVITY_TYPE.FULL_SERVER))
	activityExchangeView:setRuleText(self.activityHomeDatas[tostring(activityId)].detail[i18n.getLang()])
	activityExchangeView.viewData_.bg:setWebURL(backgroundImage)
	-- 添加奖励预览
	local rewardLayer = activityExchangeView.tagViewData_.rewardLayer
	local activityDatas = self.activityDatas[tostring(activityId)]
	local rewardList = {}
	local temp = {}
	for i,v in ipairs(activityDatas.accumulativeList) do
		for ii,vv in ipairs(checktable(v.rewards)) do
			if temp[vv.goodsId] == nil then
				temp[vv.goodsId] = 1
				table.insert(rewardList, vv)
			end
		end
	end
	local midPointX = rewardLayer:getContentSize().width / 2
	local midPointY = 108
	rewardLayer:setVisible(true)
	local params = {parent = rewardLayer, midPointX = midPointX, midPointY = midPointY, maxCol= 5, scale = 0.75, rewards = rewardList, hideAmount = true}
	local goodNodes, materialLbs = CommonUtils.createPropList(params)
end
--[[
累消活动前往按钮点击回调
--]]
function ActivityMediator:AccumulativeConsumeButtonCallback( sender )
	PlayAudioByClickNormal()
	local activityId = sender:getTag()
	local activityDatas = self.activityDatas[tostring(activityId)]
	local activityHomeDatas = self.activityHomeDatas[tostring(activityId)]
	activityHomeDatas.homeDatas = clone(activityDatas)
	local mediator = require( 'Game.mediator.ActivityPropExchangeMediator').new({data = {activityId = activityId, activityHomeDatas = activityHomeDatas, leftSeconds = activityHomeDatas.leftSeconds, tag = 110124}})
	self:GetFacade():RegistMediator(mediator)
end
--[[
更新累消活动小红点是否展示
--]]
function ActivityMediator:UpdateAccumulativeConsumeRedPoint(activityId)
	local view = self.showLayer[tostring(activityId)]
	local redPointState = app.badgeMgr:GetActivityTipByActivitiyId(activityId)
	redPointState = redPointState ~= nil and redPointState or 0
	if view then
		local enterBtn = view.viewData_.enterBtn
		local redPoint = enterBtn:getChildByName('BTN_RED_POINT')
		redPoint:setVisible(redPointState == 1)
	end
	if redPointState == 1 then
		self:AddRemindIcon(activityId)
	else
		self:ClearRemindIcon(activityId)
	end
end
-----------------------------累消活动----------------------------
----------------------------------------------------------------

----------------------------------------------------------------
-----------------------------活动副本----------------------------
--[[
创建活动副本活动页签
--]]
function ActivityMediator:CreateActivityQuestView( activityId )
	local viewData = self:GetViewComponent().viewData
	local activityQuestTabView = require('Game.views.ActivityQuestTabView').new()
	viewData.ActivityLayout:addChild(activityQuestTabView, 10)
	activityQuestTabView:setAnchorPoint(cc.p(0,0))
	activityQuestTabView:setPosition(cc.p(0,0))
	self.showLayer[tostring(activityId)] = activityQuestTabView
	local backgroundImage = self.activityHomeDatas[tostring(activityId)].backgroundImage[i18n.getLang()]

	activityQuestTabView.viewData_.enterBtn:setOnClickScriptHandler(handler(self, self.ActivityQuestEnterBtnCallback))
	activityQuestTabView.viewData_.enterBtn:setTag(checkint(activityId))
	activityQuestTabView.viewData_.exchangeBtn:setOnClickScriptHandler(handler(self, self.ActivityQuestExchangeBtnCallback))
	activityQuestTabView.viewData_.exchangeBtn:setTag(checkint(activityId))
	activityQuestTabView.viewData_.timeLabel:setString(self:ChangeTimeFormat(self.activityHomeDatas[tostring(activityId)].leftSeconds, ACTIVITY_TYPE.COMMON_ACTIVITY))
	--activityQuestTabView.viewData_.ruleLabel:setString(self.activityHomeDatas[tostring(activityId)].detail[i18n.getLang()])
	activityQuestTabView:setRuleText( self.activityHomeDatas[tostring(activityId)].detail[i18n.getLang()])
	activityQuestTabView.viewData_.bg:setWebURL(backgroundImage)
	activityQuestTabView.viewData_.bg:setVisible(true)
end
--[[
活动副本进入副本按钮回调
--]]
function ActivityMediator:ActivityQuestEnterBtnCallback( sender )
	PlayAudioByClickNormal()
	local activityId = sender:getTag()
	local activityDatas = self.activityDatas[tostring(activityId)]
	-- 添加开始剧情
	local function enterView ()
	AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'HomeMediator'}, {name = 'ActivityMapMediator', params = {activityId = activityId}})
	end
	if checkint(activityDatas.startStoryId) > 0 then
		app.activityMgr:ShowActivityStory({
			activityId = activityId,
			storyId = activityDatas.startStoryId,
			storyType = 'START',
			callback = enterView
		})
	else
		enterView()
	end
end
--[[
活动副本兑换按钮回调
--]]
function ActivityMediator:ActivityQuestExchangeBtnCallback( sender )
	PlayAudioByClickNormal()
	local activityId = sender:getTag()
	local activityDatas = self.activityDatas[tostring(activityId)]
	local activityHomeDatas = self.activityHomeDatas[tostring(activityId)]
	-- 构建兑换页面所需的数据结构 --
	local exchangeDatas = {homeDatas = {exchange = {}}}
	-- 获取道具兑换配表
	local exchangeConfig = CommonUtils.GetConfig('activityQuest', 'exchange', checkint(activityDatas.zoneId))
	for k,v in orderedPairs(exchangeConfig) do
		v.require = v.consume
		v.leftExchangeTimes = checkint(activityDatas.exchangeTimes[tostring(v.id)])
		table.insert(exchangeDatas.homeDatas.exchange, v)
	end
	local mediator = require( 'Game.mediator.ActivityPropExchangeMediator').new({data = {activityId = activityId,  activityHomeDatas = exchangeDatas, leftSeconds = activityHomeDatas.leftSeconds, tag = 110123}})
	self:GetFacade():RegistMediator(mediator)
end
--[[
活动副本兑换成功
--]]
function ActivityMediator:ActivityQuestExchangeSuccess( datas )
	if self.activityDatas[tostring(datas.requestData.activityId)] then
		local activityDatas = self.activityDatas[tostring(datas.requestData.activityId)]
		activityDatas.exchangeTimes[tostring(datas.requestData.exchangeId)] = activityDatas.exchangeTimes[tostring(datas.requestData.exchangeId)] - checkint(datas.requestData.num)
	end
end
-----------------------------活动副本----------------------------
----------------------------------------------------------------

----------------------------------------------------------------
-----------------------------问卷活动----------------------------
--[[
创建问卷活动活动页签
--]]
function ActivityMediator:CreateQuestionnaireView( activityId )
	local viewData = self:GetViewComponent().viewData
	local activityQuestionnaireView = self:CreateActivityView(activityId, 'ActivityQuestionnaireView')
	local activityHomeDatas = self.activityHomeDatas[tostring(activityId)]
	local activityDatas = self.activityDatas[tostring(activityId)]

	local backgroundImage = activityHomeDatas.backgroundImage[i18n.getLang()]
	activityQuestionnaireView.viewData_.enterBtn:setOnClickScriptHandler(handler(self, self.QuestionnaireEnterBtnCallback))
	activityQuestionnaireView.viewData_.enterBtn:setTag(checkint(activityId))
	activityQuestionnaireView.viewData_.timeLabel:setString(self:ChangeTimeFormat(activityHomeDatas.leftSeconds, ACTIVITY_TYPE.COMMON_ACTIVITY))
	activityQuestionnaireView.viewData_.bg:setWebURL(backgroundImage)
	activityQuestionnaireView.viewData_.bg:setVisible(true)
	-- 奖励预览
	for i, v in ipairs(activityDatas.rewards) do
		local goodsIcon = require('common.GoodNode').new({id = v.goodsId, amount = v.num, showAmount = true, highlight = v.highlight})
		goodsIcon:setPosition(cc.p(94 + (i-1)*104, 100))
		goodsIcon:setScale(0.9)
		activityQuestionnaireView.viewData_.rewardLayout:addChild(goodsIcon, 10)
		display.commonUIParams(goodsIcon, {animate = false, cb = function (sender)
			uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = v.goodsId, type = 1})
		end})
	end
end
--[[
问卷活动前往按钮
--]]
function ActivityMediator:QuestionnaireEnterBtnCallback( sender )
	PlayAudioByClickNormal()
	local activityId = sender:getTag()
	local activityDatas = self.activityDatas[tostring(activityId)]
	-- 跳转至外部浏览器
	local link = activityDatas.link
    local apisalt = FTUtils:generateKey(SIGN_KEY)
    local playerId = checkint(gameMgr:GetUserInfo().playerId)
    local t = os.time()
    local sign = string.format('%d%s%s', playerId,tostring(t),apisalt)
    sign = CCCrypto:MD5Lua(sign, false)
    local params = string.format('playerId=%d&timestamp=%s&sign=%s', playerId,t,sign)
    -- local c = string.urlencode(params)
	local originalURL = string.format('%s?host=%s&%s', link, Platform.serverHost, params)
    -- originalURL = string.urlencode(originalURL)
	FTUtils:openUrl(originalURL)
end
-----------------------------问卷活动----------------------------
----------------------------------------------------------------

----------------------------------------------------------------
----------------------------打气球活动---------------------------
--[[
创建打气球活动活动页签
--]]
function ActivityMediator:CreateBalloonView( activityId )
	local activityHomeDatas = self.activityHomeDatas[tostring(activityId)]
	local params = {
		btnText = __('前 往'),
		btnTag = checkint(activityId),
		ruleText = activityHomeDatas.detail[i18n.getLang()],
		showRewardsBg = true,
		bgImageURL = activityHomeDatas.backgroundImage[i18n.getLang()],
		timeText = self:ChangeTimeFormat(activityHomeDatas.leftSeconds, ACTIVITY_TYPE.COMMON_ACTIVITY),
		btnCallback = handler(self, self.BalloonEnterBtnCallback)
	}
	local activityCommonView = self:CreateActivityView(activityId, 'ActivityCommonView', params)
	-- 添加奖励预览
	local activityDatas = self.activityDatas[tostring(activityId)]
	local rewards = {}
	for _, v in ipairs(activityDatas.exchange) do
		for _, goods in ipairs(checktable(v.rewards)) do
			if next(rewards) == nil then
				table.insert(rewards, goods)
			else
				-- 判断是否重复
				local isRepeat = false
				for _, hasGoods in ipairs(rewards) do
					if hasGoods.goodsId == goods.goodsId then
						isRepeat = true
						break
					end
				end
				if not isRepeat then
					table.insert(rewards, goods)
				end
			end
		end
	end
	local rewardList = app.activityMgr:CreateActivityRewardList(rewards)
	display.commonUIParams(rewardList, {ap = cc.p(0.5, 0), po = cc.p(activityCommonView.viewData_.rewardBgImg:getPositionX(), activityCommonView.viewData_.rewardBgImg:getPositionY())})
	activityCommonView.viewData_.rewardLayer:addChild(rewardList)
end
--[[
气球活动前往按钮
--]]
function ActivityMediator:BalloonEnterBtnCallback( sender )
	PlayAudioByClickNormal()
	local activityId = sender:getTag()
	local activityDatas = self.activityDatas[tostring(activityId)]
	local leftSeconds = self.activityHomeDatas[tostring(activityId)].leftSeconds
	local title = self.activityHomeDatas[tostring(activityId)].title[i18n.getLang()]
	local params = {
		activityId = activityId,
		leftSeconds = leftSeconds,
		title  = title
	}
	-- 添加开始剧情
	local function enterView ()
		AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = NAME}, {name = 'activity.balloon.ActivityBalloonMediator', params = params}, {isBack = true})
	end
	if checkint(activityDatas.startStoryId) > 0 then
		app.activityMgr:ShowActivityStory({
			activityId = activityId,
			storyId = activityDatas.startStoryId,
			storyType = 'START',
			callback = enterView
		})
	else
		enterView()
	end
end
----------------------------打气球活动---------------------------
----------------------------------------------------------------

----------------------------------------------------------------
----------------------------单笔充值活动--------------------------
--[[
创建单笔充值活动活动页签
--]]
function ActivityMediator:CreateSinglePayView( activityId )
	local activityHomeDatas = self.activityHomeDatas[tostring(activityId)]
	local params = {
		btnText = __('前 往'),
		btnTag = checkint(activityId),
		ruleText = activityHomeDatas.detail[i18n.getLang()],
		showRewardsBg = true,
		bgImageURL = activityHomeDatas.backgroundImage[i18n.getLang()],
		timeText = self:ChangeTimeFormat(activityHomeDatas.leftSeconds, ACTIVITY_TYPE.COMMON_ACTIVITY),
		btnCallback = handler(self, self.SinglePayEnterBtnCallback)
	}
	local activityCommonView = self:CreateActivityView(activityId, 'ActivityCommonView', params)
	-- 添加奖励预览
	local activityDatas = self.activityDatas[tostring(activityId)]
	local rewards = {}
	for _, v in ipairs(activityDatas) do
		for _, goods in ipairs(checktable(v.rewards)) do
			if next(rewards) == nil then
				table.insert(rewards, goods)
			else
				-- 判断是否重复
				local isRepeat = false
				for _, hasGoods in ipairs(rewards) do
					if hasGoods.goodsId == goods.goodsId then
						isRepeat = true
						break
					end
				end
				if not isRepeat then
					table.insert(rewards, goods)
				end
			end
		end
	end
	local rewardList = app.activityMgr:CreateActivityRewardList(rewards)
	display.commonUIParams(rewardList, {ap = cc.p(0.5, 0), po = cc.p(activityCommonView.viewData_.rewardBgImg:getPositionX(), activityCommonView.viewData_.rewardBgImg:getPositionY())})
	activityCommonView.viewData_.rewardLayer:addChild(rewardList)
end
--[[
单笔充值活动前往按钮
--]]
function ActivityMediator:SinglePayEnterBtnCallback( sender )
	PlayAudioByClickNormal()
	local activityId = sender:getTag()
	local leftSeconds = self.activityHomeDatas[tostring(activityId)].leftSeconds
	local title = self.activityHomeDatas[tostring(activityId)].title[i18n.getLang()]
	local mediator = require("Game.mediator.activity.singlePay.ActivitySinglePayMediator").new({activityId = activityId, leftSeconds = leftSeconds, title = title})
	self:GetFacade():RegistMediator(mediator)
end
----------------------------单笔充值活动--------------------------
----------------------------------------------------------------

----------------------------------------------------------------
--------------------------常驻单笔充值活动--------------------------
function ActivityMediator:CreatePermanentSinglePayView( activityId )
	local activityHomeDatas = self.activityHomeDatas[tostring(activityId)]
	self:CreateActivityPageView(activityId,'activity.singlePay.ActivityPermanentSinglePayMediator',{activityData = self.activityDatas[tostring(activityId)].stage, activityId = activityId, timeStr = self:ChangeTimeFormat(activityHomeDatas.leftSeconds, ACTIVITY_TYPE.COMMON_ACTIVITY)})
end
--------------------------常驻单笔充值活动--------------------------
------------------------------------------------------------------

------------------------------------------------------------------
----------------------------web跳转活动----------------------------
--[[
创建web跳转活动页面
--]]
function ActivityMediator:CreateWebActivityView( activityId )
	local activityHomeDatas = self.activityHomeDatas[tostring(activityId)]
	local activityDatas = self.activityDatas[tostring(activityId)]
	local ruleText = activityHomeDatas.detail[i18n.getLang()]
	local showRule = false 
	if ruleText and ruleText ~= '' then
		showRule = true
	end
	local params = {
		btnText = activityDatas.btnName[i18n.getLang()] or __('前 往'),
		btnTag = checkint(activityId),
		showRule = showRule,
		showBtnBg = true,
		bgImageURL = activityHomeDatas.backgroundImage[i18n.getLang()],
		timeText = self:ChangeTimeFormat(activityHomeDatas.leftSeconds, ACTIVITY_TYPE.COMMON_ACTIVITY),
		btnCallback = handler(self, self.WebActivityEnterBtnCallback),
		ruleText = ruleText,
	}
	local activityPermanentSinglePayView = self:CreateActivityView(activityId, 'ActivityCommonView', params)
end
--[[
web跳转活动 前往按钮点击回调
--]]
function ActivityMediator:WebActivityEnterBtnCallback( sender )
	PlayAudioByClickNormal()
	local activityId = sender:getTag()
	local activityDatas = self.activityDatas[tostring(activityId)]
	-- 跳转至外部浏览器
	local link = 'http://' .. activityDatas.url
	link = string.gsub(link, '_platform_', string.fmt('notice-%1', Platform.serverHost), 1)
	local str = string.fmt('playerId=%1', app.gameMgr:GetUserInfo().encryptPlayerId)
    str = string.gsub(str, '%%', '%%%%')
	link = string.gsub(link, '_playerId_', str, 1)
	link = string.gsub(link, '_host_', string.fmt('host=%1', Platform.serverHost), 1)
	link = string.gsub(link, '_activeId_', string.fmt('activeId=%1', activityId), 1)
	-- local originalURL = string.format('%s?host=%s&playerId=%s', link, Platform.serverHost, ssl_encrypt(tostring(gameMgr:GetUserInfo().playerId)))
	FTUtils:openUrl(link)
end
----------------------------web跳转活动----------------------------
------------------------------------------------------------------

------------------------------------------------------------------
----------------------------夏活----------------------------
function ActivityMediator:CreateSummerActivityPageView(activityId)
	local pageView = self:CreateActivityView(activityId, 'summerActivity.SummerActivityPageView')
	local viewData = pageView:getViewData()
	local enterBtn = viewData.enterBtn
	enterBtn:setTag(activityId)
	display.commonUIParams(enterBtn, {cb = handler(self, self.SummerActivityEnterBtnCallback)})

	local activityHomeDatas = self.activityHomeDatas[tostring(activityId)]
	pageView:updateRule(tostring(activityHomeDatas.detail[i18n.getLang()]))

	pageView:updateBackground(activityHomeDatas.backgroundImage[i18n.getLang()])
end

function ActivityMediator:SummerActivityEnterBtnCallback(sender)
	PlayAudioByClickNormal()
	
	if not CommonUtils.UnLockModule(JUMP_MODULE_DATA.SUMMER_ACTIVITY, true) then return end
	app.summerActMgr:InitCarnieTheme()
	local activityId = sender:getTag()

	local callback = function ()
		if gameMgr:GetUserInfo().summerActivity > 0 then
			AppFacade.GetInstance():RetrieveMediator('Router'):Dispatch({name = 'HomeMediator'}, {name = 'summerActivity.SummerActivityHomeMediator', params = {fromMediator = 'ActivityMediator', activityId = activityId}})
		end
	end
	local storyTag = checkint(CommonUtils.getLocalDatas(app.summerActMgr:getCarnieThemeActivityStoryFlagByChapterId('1')))
	if storyTag > 0 then
		callback()
	else
		CommonUtils.setLocalDatas(1, app.summerActMgr:getCarnieThemeActivityStoryFlagByChapterId('1'))

		local path = string.format("conf/%s/summerActivity/summerStory.json",i18n.getLang())
		local stage = require( "Frame.Opera.OperaStage" ).new({id = 1, path = path, guide = true, isHideBackBtn = true, cb = callback})
		stage:setPosition(cc.p(display.cx,display.cy))
		sceneWorld:addChild(stage, GameSceneTag.Dialog_GameSceneTag)
	end
end
----------------------------夏活----------------------------
------------------------------------------------------------------

----------------------------------------------------------------
--------------------------进阶等级礼包活动--------------------------
function ActivityMediator:CreateLevelAdvanceChestView( activityId )
	self:CreateActivityPageView( activityId, 'activity.levelAdvanceChest.ActivityLevelAdvanceChestMediator', {activityData = self.activityDatas[tostring(activityId)], activityId = activityId} )
end

function ActivityMediator:CheckLevelAdvanceChestIsOpen()
	local isOpen = 0
	local confs = CommonUtils.GetConfigAllMess('levelAdvanceChestOpen', 'activity') or {}
	local minOpenLevel = 999999
	for lv, v in pairs(confs) do
		minOpenLevel = math.min(minOpenLevel, checkint(lv))
	end
	if minOpenLevel ~= 999999 then
		local lv = gameMgr:GetUserInfo().level
		isOpen = lv >= minOpenLevel and 1 or 0
	end
	return isOpen
end
--------------------------进阶等级礼包活动--------------------------
------------------------------------------------------------------

function ActivityMediator:CreateLevelRewardView(activityId)
	if GAME_MODULE_OPEN.NEW_LEVEL_REWARD then
		self:CreateActivityPageView(activityId, 'activity.levelReward.ActivityNewLevelRewardMediator', {activityData = self.activityDatas[tostring(activityId)], activityId = activityId})
	else
		self:CreateActivityPageView(activityId, 'activity.levelReward.ActivityLevelRewardMediator', {activityData = self.activityDatas[tostring(activityId)], activityId = activityId})
	end
end
----------------------------------------------------------------
------------------------------燃战-------------------------------
--[[
创建燃战活动页面
--]]
function ActivityMediator:CreateSaiMoeView(activityId)
	local activityHomeDatas = self.activityHomeDatas[tostring(activityId)]
	local params = {
		btnText = __('前 往'),
		btnTag = checkint(activityId),
		ruleText = activityHomeDatas.detail[i18n.getLang()],
		bgImageURL = activityHomeDatas.backgroundImage[i18n.getLang()],
		timeText = self:ChangeTimeFormat(activityHomeDatas.leftSeconds, ACTIVITY_TYPE.COMMON_ACTIVITY),
		btnCallback = handler(self, self.SaiMoeEnterBtnCallback)
	}
	self:CreateActivityView(activityId, 'ActivityCommonView', params)
end
--[[
燃战活动前往按钮回调
--]]
function ActivityMediator:SaiMoeEnterBtnCallback( sender )
	PlayAudioByClickNormal()
	local callback = function ()
		local appIns   = AppFacade.GetInstance()
		local gameMgr  = app.gameMgr
		if gameMgr:GetUserInfo().comparisonActivity > 0 then
			AppFacade.GetInstance():RetrieveMediator("AppMediator"):SendSignal(POST.SAIMOE_HOME.cmdName)
		else
			uiMgr:ShowInformationTips(__('活动已过期'))
		end
	end
	local storyTag = checkint(CommonUtils.getLocalDatas('SAIMOE_LEAGUE_STORY_CHAPTER1'))
	if storyTag > 0 then
		callback()
	else
		CommonUtils.setLocalDatas(1, 'SAIMOE_LEAGUE_STORY_CHAPTER1')
		local path = string.format("conf/%s/cardComparison/comparisonStory.json",i18n.getLang())
		local stage = require( "Frame.Opera.OperaStage" ).new({id = 1, path = path, guide = true, isHideBackBtn = true, cb = callback})
		stage:setPosition(cc.p(display.cx,display.cy))
		sceneWorld:addChild(stage, GameSceneTag.Dialog_GameSceneTag)
	end
end
------------------------------燃战-------------------------------
----------------------------------------------------------------

----------------------------------------------------------------
--------------------------特殊活动(周年庆)------------------------
function ActivityMediator:CreateSpActivityView( activityId )
	local activityHomeDatas = self.activityHomeDatas[tostring(activityId)]
	local params = {
		btnText = __('前 往'),
		btnTag = checkint(activityId),
		showRule = false,
		showBtnBg = true,
		bgImageURL = activityHomeDatas.backgroundImage[i18n.getLang()],
		timeText = self:ChangeTimeFormat(activityHomeDatas.leftSeconds, ACTIVITY_TYPE.COMMON_ACTIVITY),
		btnCallback = handler(self, self.SpActivityEnterBtnCallback),
		-- ruleText = ruleText,
	}
	self:CreateActivityView(activityId, 'ActivityCommonView', params)
end
function ActivityMediator:SpActivityEnterBtnCallback( sender )
	AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'activityMediator'}, {name = 'specialActivity.SpActivityMediator'})
end
--------------------------特殊活动(周年庆)------------------------
----------------------------------------------------------------

----------------------------------------------------------------
-----------------------------招财猫------------------------------
function ActivityMediator:CreateFortuneCarView( activityId )
	local activityHomeDatas = self.activityHomeDatas[tostring(activityId)]
	local params = {
		btnText = __('前 往'),
		btnTag = checkint(activityId),
		showRule = true,
		showBtnBg = true,
		bgImageURL = activityHomeDatas.backgroundImage[i18n.getLang()],
		timeText = self:ChangeTimeFormat(activityHomeDatas.leftSeconds, ACTIVITY_TYPE.COMMON_ACTIVITY),
		btnCallback = handler(self, self.FortuneCarEnterBtnCallback),
		ruleText = activityHomeDatas.detail[i18n.getLang()],
	}
	self:CreateActivityView(activityId, 'ActivityCommonView', params)
end
function ActivityMediator:FortuneCarEnterBtnCallback( sender )
	local activityId = sender:getTag()
	local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
    local scene = uiMgr:GetCurrentScene()
    local luckyCatView = require("Game.views.activity.ActivityLuckyCatView").new({tag = 54444, isClose = false, activityId = activityId})
    display.commonUIParams(luckyCatView, {ap = cc.p(0.5, 0.5), po = cc.p(display.width * 0.5, display.height * 0.5)})
    luckyCatView:setTag(54444)
    scene:AddDialog(luckyCatView)
end
-----------------------------招财猫------------------------------
----------------------------------------------------------------
-----------------------------神器之路----------------------------
function ActivityMediator:CreateArtifactRoadActivityView( activityId )
	local activityHomeDatas = self.activityHomeDatas[tostring(activityId)]
	local params = {
		btnText = __('前 往'),
		btnTag = checkint(activityId),
		showRule = false,
		showBtnBg = true,
		bgImageURL = activityHomeDatas.backgroundImage[i18n.getLang()],
		timeText = self:ChangeTimeFormat(activityHomeDatas.leftSeconds, ACTIVITY_TYPE.COMMON_ACTIVITY),
		btnCallback = handler(self, self.ArtifactRoadActivityEnterBtnCallback),
	}
	self:CreateActivityView(activityId, 'ActivityCommonView', params)
end
function ActivityMediator:ArtifactRoadActivityEnterBtnCallback( sender )
	if 40 <= checkint(gameMgr:GetUserInfo().level) then
		AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'ActivityMediator', params = { activityId = sender:getTag()}}, {name = 'activity.ArtifactRoad.ArtifactRoadMediator', params = { activityId = sender:getTag()}}, {isBack = true})
	else
		uiMgr:ShowInformationTips(__('等级达到40级解锁该活动'))
	end
end
-----------------------------神器之路----------------------------
----------------------------------------------------------------

-----------------------------pt本----------------------------
function ActivityMediator:CreatePTDungeonActivityView( activityId )
	local activityHomeDatas = self.activityHomeDatas[tostring(activityId)]
	local params = {
		btnText = __('前 往'),
		btnTag = checkint(activityId),
		showRule = true,
		showBtnBg = true,
		bgImageURL = activityHomeDatas.backgroundImage[i18n.getLang()],
		timeText = self:ChangeTimeFormat(activityHomeDatas.leftSeconds, ACTIVITY_TYPE.COMMON_ACTIVITY),
		btnCallback = handler(self, self.PTDungeonActivityEnterBtnCallback),
		ruleText = activityHomeDatas.detail[i18n.getLang()],
	}
	self:CreateActivityView(activityId, 'ActivityCommonView', params)
end
function ActivityMediator:PTDungeonActivityEnterBtnCallback( sender )
	if 30 <= checkint(gameMgr:GetUserInfo().level) then
		local activityHomeDatas = self.activityHomeDatas[tostring(sender:getTag())]
		AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'ActivityMediator', params = { activityId = sender:getTag()}}, {name = 'ptDungeon.PTDungeonHomeMediator', params = { activityId = sender:getTag(), title = activityHomeDatas.title[i18n.getLang()]}}, {isBack = true})
	else
		uiMgr:ShowInformationTips(__('等级达到30级解锁该活动'))
	end
end
-----------------------------pt本----------------------------
----------------------------------------------------------------

----------------------------------------------------------------
-----------------------------限时空运----------------------------
function ActivityMediator:CreateLimitAirshipView( activityId )
	local activityHomeDatas = self.activityHomeDatas[tostring(activityId)]
	local params = {
		btnTag = checkint(activityId),
		showBtn = false,
		bgImageURL = activityHomeDatas.backgroundImage[i18n.getLang()],
		timeText = self:ChangeTimeFormat(activityHomeDatas.leftSeconds, ACTIVITY_TYPE.COMMON_ACTIVITY),
		ruleText = activityHomeDatas.detail[i18n.getLang()],
	}
	self:CreateActivityView(activityId, 'ActivityCommonView', params)
end
-----------------------------限时空运----------------------------
----------------------------------------------------------------

----------------------------------------------------------------
----------------------------组队本活动----------------------------
function ActivityMediator:CreateTeamQuestView( activityId )
	local activityHomeDatas = self.activityHomeDatas[tostring(activityId)]
	local params = {
		btnTag = checkint(activityId),
		showBtn = false,
		showRule = false, 
		bgImageURL = activityHomeDatas.backgroundImage[i18n.getLang()],
		timeText = self:ChangeTimeFormat(activityHomeDatas.leftSeconds, ACTIVITY_TYPE.COMMON_ACTIVITY),
	}
	self:CreateActivityView(activityId, 'ActivityCommonView', params)
end
----------------------------组队本活动----------------------------
----------------------------------------------------------------

----------------------------------------------------------------
-------------------------普通本双倍经验活动------------------------
function ActivityMediator:CreateEXPNormalView( activityId )
	local activityHomeDatas = self.activityHomeDatas[tostring(activityId)]
	local params = {
		btnTag = checkint(activityId),
		showBtn = false,
		showRule = false, 
		bgImageURL = activityHomeDatas.backgroundImage[i18n.getLang()],
		timeText = self:ChangeTimeFormat(activityHomeDatas.leftSeconds, ACTIVITY_TYPE.COMMON_ACTIVITY),
	}
	self:CreateActivityView(activityId, 'ActivityCommonView', params)
end
-------------------------普通本双倍经验活动------------------------
----------------------------------------------------------------

----------------------------------------------------------------
-------------------------困难本双倍经验活动------------------------
function ActivityMediator:CreateEXPHardView( activityId )
	local activityHomeDatas = self.activityHomeDatas[tostring(activityId)]
	local params = {
		btnTag = checkint(activityId),
		showBtn = false,
		showRule = false, 
		bgImageURL = activityHomeDatas.backgroundImage[i18n.getLang()],
		timeText = self:ChangeTimeFormat(activityHomeDatas.leftSeconds, ACTIVITY_TYPE.COMMON_ACTIVITY),
	}
	self:CreateActivityView(activityId, 'ActivityCommonView', params)
end
-------------------------困难本双倍经验活动------------------------
----------------------------------------------------------------

----------------------------------------------------------------
-------------------------pass卡活动------------------------
function ActivityMediator:CreatePassTicketView( activityId )

	local activityHomeDatas = self.activityHomeDatas[tostring(activityId)]
	local params = {
		btnText = __('前 往'),
		btnTag = checkint(activityId),
		ruleText = activityHomeDatas.detail[i18n.getLang()],
		bgImageURL = activityHomeDatas.backgroundImage[i18n.getLang()],
		timeText = self:ChangeTimeFormat(activityHomeDatas.leftSeconds, ACTIVITY_TYPE.COMMON_ACTIVITY),
		btnCallback = handler(self, self.PassTicketEnterBtnCallback)
	}
	self:CreateActivityView(activityId, 'ActivityCommonView', params)

end
function ActivityMediator:PassTicketEnterBtnCallback(sender)
	PlayAudioByClickNormal()
	local activityId = sender:getTag()
	local activityHomeDatas = self.activityHomeDatas[tostring(activityId)]
	local mediator = require("Game.mediator.passTicket.PassTicketMediator").new(activityHomeDatas)
	self:GetFacade():RegistMediator(mediator)
end
-------------------------pass卡活动------------------------
----------------------------------------------------------------

----------------------------------------------------------------
-----------------------------周年庆活动---------------------------
function ActivityMediator:CreateAnniversaryView( activityId )
	local activityHomeDatas = self.activityHomeDatas[tostring(activityId)]
	local params = {
		btnText = __('前 往'),
		btnTag = checkint(activityId),
		showRule = true,
		showBtnBg = true,
		bgImageURL = activityHomeDatas.backgroundImage[i18n.getLang()],
		timeText = self:ChangeTimeFormat(activityHomeDatas.leftSeconds, ACTIVITY_TYPE.COMMON_ACTIVITY),
		btnCallback = handler(self, self.AnniversaryEnterBtnCallback),
		ruleText = activityHomeDatas.detail[i18n.getLang()],
	}
	self:CreateActivityView(activityId, 'ActivityCommonView', params)
end
function ActivityMediator:AnniversaryEnterBtnCallback( sender )
	PlayAudioByClickNormal()
	app.anniversaryMgr:EnterAnniversary()
end
-----------------------------周年庆活动---------------------------
----------------------------------------------------------------

----------------------------------------------------------------
-----------------------------皮肤卡池活动-------------------------
function ActivityMediator:CreateSkinPoolView( activityId )
	local activityHomeDatas = self.activityHomeDatas[tostring(activityId)]
	local params = {
		btnText = __('前 往'),
		btnTag = checkint(activityId),
		showRule = false,
		showBtnBg = true,
		bgImageURL = activityHomeDatas.backgroundImage[i18n.getLang()],
		timeText = self:ChangeTimeFormat(activityHomeDatas.leftSeconds, ACTIVITY_TYPE.COMMON_ACTIVITY),
		btnCallback = handler(self, self.SkinPoolEnterBtnCallback),
	}
	self:CreateActivityView(activityId, 'ActivityCommonView', params)
end
function ActivityMediator:SkinPoolEnterBtnCallback( sender )
	PlayAudioByClickNormal()
	local activityId = sender:getTag()
    app:RetrieveMediator("Router"):Dispatch({name = 'HomeMediator'}, {name = 'drawCards.CapsuleNewMediator', params = {activityId = activityId}})
end
-----------------------------皮肤卡池活动-------------------------
----------------------------------------------------------------

----------------------------------------------------------------
-----------------------------选卡卡池活动-------------------------
function ActivityMediator:CreateCardChooseView( activityId )
	local activityHomeDatas = self.activityHomeDatas[tostring(activityId)]
	local params = {
		btnText = __('前 往'),
		btnTag = checkint(activityId),
		showRule = false,
		showBtnBg = true,
		bgImageURL = activityHomeDatas.backgroundImage[i18n.getLang()],
		timeText = self:ChangeTimeFormat(activityHomeDatas.leftSeconds, ACTIVITY_TYPE.COMMON_ACTIVITY),
		btnCallback = handler(self, self.CardChooseEnterBtnCallback),
	}
	self:CreateActivityView(activityId, 'ActivityCommonView', params)
end
function ActivityMediator:CardChooseEnterBtnCallback( sender )
	PlayAudioByClickNormal()
	local activityId = sender:getTag()
    app:RetrieveMediator("Router"):Dispatch({name = 'HomeMediator'}, {name = 'drawCards.CapsuleNewMediator', params = {activityId = activityId}})
end
-----------------------------选卡卡池活动-------------------------
----------------------------------------------------------------

----------------------------------------------------------------
-----------------------------成长基金活动-------------------------
function ActivityMediator:CreateGrowthFundView(activityId)
	self:CreateActivityPageView(activityId, 'activity.growthFund.ActivityGrowthFundMediator', {activityData = self.activityDatas[tostring(activityId)], activityId = activityId})
end
-----------------------------成长基金活动-------------------------
----------------------------------------------------------------

----------------------------------------------------------------
-----------------------------古堡迷踪活动-------------------------
function ActivityMediator:CreateCastleActivityView( activityId )
	local activityHomeDatas = self.activityHomeDatas[tostring(activityId)]
	local params = {
		btnText = __('前 往'),
		btnTag = checkint(activityId),
		showRule = true,
		showBtnBg = true,
		bgImageURL = activityHomeDatas.backgroundImage[i18n.getLang()],
		timeText = self:ChangeTimeFormat(activityHomeDatas.leftSeconds, ACTIVITY_TYPE.COMMON_ACTIVITY),
		btnCallback = handler(self, self.CastleActivityEnterBtnCallback),
		ruleText = activityHomeDatas.detail[i18n.getLang()],
	}
	self:CreateActivityView(activityId, 'ActivityCommonView', params)
end
function ActivityMediator:CastleActivityEnterBtnCallback( sender )
	PlayAudioByClickNormal()
	local activityId = sender:getTag()
	local extraParams = {activityId = activityId, activityType = ACTIVITY_TYPE.CASTLE_ACTIVITY}
	app:RetrieveMediator("Router"):Dispatch({name = 'ActivityMediator', params = extraParams}, {name = 'castle.CastleMainMediator', params = extraParams}, {isBack = true})
end
-----------------------------古堡迷踪活动-------------------------
----------------------------------------------------------------

----------------------------------------------------------------
-----------------------------KFC签到活动-------------------------
function ActivityMediator:CreateKFCActivityView(activityId)
	local activityHomeData = self.activityHomeDatas[tostring(activityId)]
	self:CreateActivityPageView(activityId, 'activity.ActivityKFCMediator', {activityHomeData = activityHomeData})
end
-----------------------------KFC签到活动-------------------------
----------------------------------------------------------------
---
----------------------------------------------------------------
-----------------------------付费签到-------------------------
function ActivityMediator:CreatePayLoginRewardActivityView(activityId)
	local activityHomeData = self.activityHomeDatas[tostring(activityId)]
	self:CreateActivityPageView(activityId, 'activity.payLoginReward.ActivityPayLoginRewardMediator', {activityHomeData = activityHomeData})
end


------------------------------------------------------
function ActivityMediator:CreateJPWishActivityView(activityId)
	local activityHomeData = self.activityHomeDatas[tostring(activityId)]
	self:CreateActivityPageView(activityId, 'activity.ActivityJPWishMediator', {activityHomeData = activityHomeData})
end
function ActivityMediator:CreateShareCv2ActivityView(activityId)
	local activityHomeData = self.activityHomeDatas[tostring(activityId)]
	self:CreateActivityPageView(activityId, 'activity.shareCV2.ShareCV2EnterMediator', {activityHomeData = activityHomeData})
end
-----------------------------付费签到-------------------------
----------------------------------------------------------------

function ActivityMediator:CreateChestActivityView(activityId)
	local activityHomeData = self.activityHomeDatas[tostring(activityId)]
	self:CreateActivityPageView(activityId, 'activity.chest.ActivityChestEnterMediator', {activityHomeData = activityHomeData})
end

function ActivityMediator:CreatePopLinkActivityView(activityId)
	local activityHomeData = self.activityHomeDatas[tostring(activityId)]
	local relatedTip = nil
	if activityHomeData.relatedActivityId and self.activityHomeDatas[tostring(activityId)] then
		relatedTip = checkint(self.activityHomeDatas[tostring(activityHomeData.relatedActivityId)].tip)
	end
	self:CreateActivityPageView(activityId, 'link.popMain.PopEnterMediator', {activityHomeData = activityHomeData, relatedTip = relatedTip})
end


----------------------------------------------------------------
------------------------- 杀人案(19夏活) -------------------------
function ActivityMediator:CreateMurderView( activityId )
	local activityHomeDatas = self.activityHomeDatas[tostring(activityId)]
	local params = {
		btnText = __('前 往'),
		btnTag = checkint(activityId),
		showRule = true,
		showBtnBg = true,
		bgImageURL = activityHomeDatas.backgroundImage[i18n.getLang()],
		timeText = self:ChangeTimeFormat(activityHomeDatas.leftSeconds, ACTIVITY_TYPE.COMMON_ACTIVITY),
		btnCallback = handler(self, self.MurderEnterBtnCallback),
		ruleText = activityHomeDatas.detail[i18n.getLang()],
	}
	self:CreateActivityView(activityId, 'ActivityCommonView', params)
end
function ActivityMediator:MurderEnterBtnCallback( sender )
	PlayAudioByClickNormal()
	if not CommonUtils.UnLockModule(JUMP_MODULE_DATA.MURDER, true) then return end
	app:RetrieveMediator('Router'):Dispatch({name = 'ActivityMediator'}, {name = 'activity.murder.MurderHomeMediator'})
end
------------------------- 杀人案(19夏活) -------------------------
----------------------------------------------------------------

----------------------------------------------------------------
-------------------------- 连续活跃活动 -------------------------
function ActivityMediator:CreateContinuousActiveView( activityId )
	self:CreateActivityPageView( activityId, 'activity.continuousActive.ActivityContinuousActiveMediator', {activityData = self.activityDatas[tostring(activityId)], activityId = activityId} )
end
-------------------------- 连续活跃活动 -------------------------
----------------------------------------------------------------

----------------------------------------------------------------
---------------------------- 巅峰对决 ---------------------------
function ActivityMediator:CreateUltimateBattleView( activityId )
	self:CreateActivityPageView( activityId, 'activity.ultimateBattle.ActivityUltimateBattleMediator')
end
---------------------------- 巅峰对决 ---------------------------
----------------------------------------------------------------

----------------------------------------------------------------
--------------------------- 皮肤嘉年华 --------------------------
function ActivityMediator:CreateSkinCarnivalView( activityId )
	local activityHomeDatas = self.activityHomeDatas[tostring(activityId)]
	local params = {
		btnText = __('前 往'),
		btnTag = checkint(activityId),
		showRule = true,
		showBtnBg = true,
		bgImageURL = activityHomeDatas.backgroundImage[i18n.getLang()],
		timeText = self:ChangeTimeFormat(activityHomeDatas.leftSeconds, ACTIVITY_TYPE.COMMON_ACTIVITY),
		btnCallback = handler(self, self.SkinCarnivalEnterBtnCallback),
		ruleText = activityHomeDatas.detail[i18n.getLang()],
	}
	self:CreateActivityView(activityId, 'ActivityCommonView', params)
end
function ActivityMediator:SkinCarnivalEnterBtnCallback( sender )
	PlayAudioByClickNormal()
	local activityId = sender:getTag()
	app:RetrieveMediator('Router'):Dispatch({name = 'ActivityMediator'}, {name = 'activity.skinCarnival.ActivitySkinCarnivalMediator', params = {activityId = activityId, backMediatorName = 'ActivityMediator'}})
end
--------------------------- 皮肤嘉年华 --------------------------
----------------------------------------------------------------

---------------------------------------------------------------
--------------------------- 周年庆19 ---------------------------
function ActivityMediator:CreateAnniversary19View( activityId )
	local activityHomeDatas = self.activityHomeDatas[tostring(activityId)]
	local params = {
		btnText = __('前 往'),
		btnTag = checkint(activityId),
		showRule = true,
		showBtnBg = true,
		bgImageURL = activityHomeDatas.backgroundImage[i18n.getLang()],
		timeText = self:ChangeTimeFormat(activityHomeDatas.leftSeconds, ACTIVITY_TYPE.COMMON_ACTIVITY),
		btnCallback = handler(self, self.Anniversary19EnterBtnCallback),
		ruleText = activityHomeDatas.detail[i18n.getLang()],
	}
	self:CreateActivityView(activityId, 'ActivityCommonView', params)
end
function ActivityMediator:Anniversary19EnterBtnCallback( sender )
	PlayAudioByClickNormal()
	local activityId = sender:getTag()
	app:RetrieveMediator('Router'):Dispatch({name = 'ActivityMediator'}, {name = 'anniversary19.Anniversary19HomeMediator', params = {activityId = activityId}})
end
--------------------------- 周年庆19 ---------------------------
---------------------------------------------------------------

---------------------------------------------------------------
--------------------------- 铸池抽卡 ---------------------------
function ActivityMediator:CreateRandomPoolView( activityId )
	local activityHomeDatas = self.activityHomeDatas[tostring(activityId)]
	local params = {
		btnText = __('前 往'),
		btnTag = checkint(activityId),
		showRule = true,
		showBtnBg = true,
		bgImageURL = activityHomeDatas.backgroundImage[i18n.getLang()],
		timeText = self:ChangeTimeFormat(activityHomeDatas.leftSeconds, ACTIVITY_TYPE.COMMON_ACTIVITY),
		btnCallback = handler(self, self.RandomPoolEnterBtnCallback),
		ruleText = activityHomeDatas.detail[i18n.getLang()],
	}
	self:CreateActivityView(activityId, 'ActivityCommonView', params)
end
function ActivityMediator:RandomPoolEnterBtnCallback( sender )
	PlayAudioByClickNormal()
	local activityId = sender:getTag()
	app:RetrieveMediator("Router"):Dispatch({name = 'HomeMediator'}, {name = 'drawCards.CapsuleNewMediator', params = {activityId = activityId}})
end
--------------------------- 铸池抽卡 ---------------------------
---------------------------------------------------------------

---------------------------------------------------------------
--------------------------- 双抉卡池 ---------------------------
function ActivityMediator:CreateBinaryChoiceView( activityId )
	local activityHomeDatas = self.activityHomeDatas[tostring(activityId)]
	local params = {
		btnText = __('前 往'),
		btnTag = checkint(activityId),
		showRule = true,
		showBtnBg = true,
		bgImageURL = activityHomeDatas.backgroundImage[i18n.getLang()],
		timeText = self:ChangeTimeFormat(activityHomeDatas.leftSeconds, ACTIVITY_TYPE.COMMON_ACTIVITY),
		btnCallback = handler(self, self.BinaryChoiceEnterBtnCallback),
		ruleText = activityHomeDatas.detail[i18n.getLang()],
	}
	self:CreateActivityView(activityId, 'ActivityCommonView', params)
end
function ActivityMediator:BinaryChoiceEnterBtnCallback( sender )
	PlayAudioByClickNormal()
	local activityId = sender:getTag()
	app:RetrieveMediator("Router"):Dispatch({name = 'HomeMediator'}, {name = 'drawCards.CapsuleNewMediator', params = {activityId = activityId}})
end
--------------------------- 双抉卡池 ---------------------------
---------------------------------------------------------------

----------------------------------------------------------------
---------------------------- 幸运数字 ---------------------------
function ActivityMediator:CreateLuckNumberView( activityId )
	self:CreateActivityPageView(activityId, 'specialActivity.SpActivityLuckNumberPageMediator', {typeData = self.activityHomeDatas[tostring(activityId)]})
end
---------------------------- 幸运数字 ---------------------------
----------------------------------------------------------------

---------------------------- 飨灵对决之飨灵投票 ---------------------------
function ActivityMediator:CreateCardVoteView( activityId )
	self:CreateActivityPageView(activityId, 'activity.cardMatch.ActivityCardMatchPageMediator', {activityData = self.activityHomeDatas[tostring(activityId)], activityId = activityId})
end
---------------------------- 飨灵对决之飨灵投票 ---------------------------
----------------------------------------------------------------
---------------------------------------------------------------
--------------------------- 飨灵刮刮乐 ---------------------------
function ActivityMediator:CreateScratcherView( activityId )
	local activityHomeDatas = self.activityHomeDatas[tostring(activityId)]
	local params = {
		btnText = __('前 往'),
		btnTag = checkint(activityId),
		showRule = true,
		showBtnBg = true,
		bgImageURL = activityHomeDatas.backgroundImage[i18n.getLang()],
		timeText = self:ChangeTimeFormat(activityHomeDatas.leftSeconds, ACTIVITY_TYPE.COMMON_ACTIVITY),
		btnCallback = handler(self, self.OnScratcherBtnClickCallback),
		ruleText = activityHomeDatas.detail[i18n.getLang()],
	}
	self:CreateActivityView(activityId, 'ActivityCommonView', params)
end

function ActivityMediator:OnScratcherBtnClickCallback( sender )
	PlayAudioByClickNormal()
	local activityId = sender:getTag()

	AppFacade.GetInstance():RetrieveMediator("AppMediator"):SendSignal(POST.FOOD_COMPARE_HOME.cmdName, {activityId = activityId})
	-- app:RetrieveMediator('Router'):Dispatch({name = 'ActivityMediator'}, {name = 'scratcher.ScratcherPlatformMediator', params = {activityId = activityId}})
end
--------------------------- 嘉年华19 ---------------------------
---------------------------------------------------------------

----------------------------------------------------------------
----------------------------- 20春活 ----------------------------
--[[
创建20春活页面
--]]
function ActivityMediator:CreateSpringActivity20View(activityId)
	local activityHomeDatas = self.activityHomeDatas[tostring(activityId)]
	local params = {
		btnText = __('前 往'),
		btnTag = checkint(activityId),
		ruleText = activityHomeDatas.detail[i18n.getLang()],
		bgImageURL = activityHomeDatas.backgroundImage[i18n.getLang()],
		timeText = self:ChangeTimeFormat(activityHomeDatas.leftSeconds, ACTIVITY_TYPE.COMMON_ACTIVITY),
		btnCallback = handler(self, self.SpringActivityEnterBtnCallback)
	}
	self:CreateActivityView(activityId, 'ActivityCommonView', params)
end
--[[
20春活前往按钮点击回调
--]]
function ActivityMediator:SpringActivityEnterBtnCallback( sender )
	PlayAudioByClickNormal()
	AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'ActivityMediator'}, {name = 'springActivity20.SpringActivity20HomeMediator', params = {animation = 1}})
end
----------------------------- 20春活 ----------------------------
----------------------------------------------------------------

----------------------------------------------------------------
----------------------------- 塔可跳转 ---------------------------
--[[
创建塔可跳转活动页面
--]]
function ActivityMediator:CreateJumpJewelView(activityId)
	local activityHomeDatas = self.activityHomeDatas[tostring(activityId)]
	local params = {
		btnText = __('前 往'),
		btnTag = checkint(activityId),
		ruleText = activityHomeDatas.detail[i18n.getLang()],
		bgImageURL = activityHomeDatas.backgroundImage[i18n.getLang()],
		timeText = self:ChangeTimeFormat(activityHomeDatas.leftSeconds, ACTIVITY_TYPE.COMMON_ACTIVITY),
		btnCallback = handler(self, self.JumpJewelEnterBtnCallback)
	}
	self:CreateActivityView(activityId, 'ActivityCommonView', params)
end
--[[
塔可跳转活动前往点击
--]]
function ActivityMediator:JumpJewelEnterBtnCallback( sender )
	PlayAudioByClickNormal()
	app:RetrieveMediator("Router"):Dispatch({} , { name ="artifact.JewelCatcherPoolMediator" })
end
----------------------------- 塔可跳转 ---------------------------
----------------------------------------------------------------

----------------------------------------------------------------
--------------------------- 新手累计充值 -------------------------
function ActivityMediator:CreateNoviceAccumulativeView( activityId )
	self:CreateActivityPageView(activityId, 'activity.noviceAccumulativePay.ActivityNoviceAccumulativePayMediator', {activityData = self.activityDatas[tostring(activityId)], activityId = activityId})
end
--------------------------- 新手累计充值 -------------------------
----------------------------------------------------------------

----------------------------------------------------------------
----------------------------- 组合活动 ---------------------------
--[[
创建组合活动活动页面
--]]
function ActivityMediator:CreateAssemblyActivityView(activityId)
	local activityHomeDatas = self.activityHomeDatas[tostring(activityId)]
	local params = {
		btnText = __('前 往'),
		btnTag = checkint(activityId),
		ruleText = activityHomeDatas.detail[i18n.getLang()],
		bgImageURL = activityHomeDatas.backgroundImage[i18n.getLang()],
		timeText = self:ChangeTimeFormat(activityHomeDatas.leftSeconds, ACTIVITY_TYPE.COMMON_ACTIVITY),
		btnCallback = handler(self, self.JumpAssemblyActivityBtnCallback)
	}
	self:CreateActivityView(activityId, 'ActivityCommonView', params)
end
--[[
组合活动活动前往点击
--]]
function ActivityMediator:JumpAssemblyActivityBtnCallback( sender )
	PlayAudioByClickNormal()
	DotGameEvent.SendEvent(DotGameEvent.EVENTS.RETURN_ACTIVITY)
	local activityId = sender:getTag()
	app:RetrieveMediator("Router"):Dispatch({name = 'HomeMediator'}, {name = 'activity.assemblyActivity.AssemblyActivityMediator', params = {activityId = activityId}})
end
----------------------------- 组合活动 ---------------------------
----------------------------------------------------------------

----------------------------------------------------------------
----------------------------- 20周年庆 --------------------------
--[[
创建20周年庆活动页面
--]]
function ActivityMediator:CreateAnniversary20View(activityId)
	local activityHomeDatas = self.activityHomeDatas[tostring(activityId)]
	local params = {
		btnText = __('前 往'),
		btnTag = checkint(activityId),
		ruleText = activityHomeDatas.detail[i18n.getLang()],
		bgImageURL = activityHomeDatas.backgroundImage[i18n.getLang()],
		timeText = self:ChangeTimeFormat(activityHomeDatas.leftSeconds, ACTIVITY_TYPE.COMMON_ACTIVITY),
		btnCallback = handler(self, self.JumpAnniversary20BtnCallback)
	}
	self:CreateActivityView(activityId, 'ActivityCommonView', params)
end
--[[
20周年庆活动前往点击
--]]
function ActivityMediator:JumpAnniversary20BtnCallback( sender )
	PlayAudioByClickNormal()
	local activityId = sender:getTag()
	app.router:Dispatch({name = 'ActivityMediator'}, {name = 'anniversary20.Anniversary20HomeMediator'})
end
----------------------------- 20周年庆 --------------------------
----------------------------------------------------------------

----------------------------------------------------------------
----------------------------- 战牌 -----------------------------
--[[
创建战牌活动页面
--]]
function ActivityMediator:CreateBattleCardView(activityId)
	local activityHomeDatas = self.activityHomeDatas[tostring(activityId)]
	local params = {
		btnText = __('前 往'),
		btnTag = checkint(activityId),
		ruleText = activityHomeDatas.detail[i18n.getLang()],
		bgImageURL = activityHomeDatas.backgroundImage[i18n.getLang()],
		timeText = self:ChangeTimeFormat(activityHomeDatas.leftSeconds, ACTIVITY_TYPE.COMMON_ACTIVITY),
		btnCallback = handler(self, self.JumpBattleCardBtnCallback)
	}
	self:CreateActivityView(activityId, 'ActivityCommonView', params)
end
--[[
战牌活动前往点击
--]]
function ActivityMediator:JumpBattleCardBtnCallback( sender )
	PlayAudioByClickNormal()
	local activityId = sender:getTag()
	app.router:Dispatch({name = "ActivityMediator"}, {name = "ttGame.TripleTriadGameHomeMediator"})
end
----------------------------- 战牌 -----------------------------
----------------------------------------------------------------

--[[
创建活动页面
--]]
function ActivityMediator:CreateActivityView( activityId, viewName, datas )
	local viewData = self:GetViewComponent().viewData
	local view = require( 'Game.views.' .. viewName).new(datas)
	viewData.ActivityLayout:addChild(view, 10)
	view:setAnchorPoint(cc.p(0,0))
	view:setPosition(cc.p(0,0))
	self.showLayer[tostring(activityId)] = view
	return view
end
--[[
创建活动页面视图
--]]
function ActivityMediator:CreateActivityPageView( activityId, viewName, datas )
	if not self:GetFacade():RetrieveMediator("Game.mediator." .. viewName) then
		local viewData = self:GetViewComponent().viewData
		local mediatorIns = require("Game.mediator." .. viewName).new(datas)
		self:GetFacade():RegistMediator(mediatorIns)
		local view = mediatorIns:GetViewComponent()
		viewData.ActivityLayout:addChild(view, 10)
		display.commonUIParams(view, {po = cc.p(0, 0), ap = cc.p(0, 0)})
		self.showLayer[tostring(activityId)] = view
		self.showMediatorName[tostring(activityId)] = mediatorIns:GetMediatorName()
		return view
	end
end
--[[
获取特殊活动(周年庆)开始时间
@params activityData list 活动数据
@return fromTime int 特殊活动开启时间(未开启则返回nil)
--]]
function ActivityMediator:GetSpActivityOpenTime( activityData )
	for i, v in ipairs(checktable(activityData)) do
		if v.type == ACTIVITY_TYPE.SP_ACTIVITY then	
			return v.fromTime
		end
	end
end
function ActivityMediator:SetRuleLabelShow (ruleLabel , ruleList )
	if ruleLabel and ruleList  then
		local ruleLabelSize = display.getLabelContentSize(ruleLabel)
		local ruleNode = ruleLabel:getParent()
		ruleNode:setContentSize(ruleLabelSize)
		ruleLabel:setAnchorPoint(display.CENTER)
		ruleLabel:setPosition(ruleLabelSize.width/2 ,ruleLabelSize.height/2)
		ruleList:reloadData()
	end
end
--[[
清除小红点
@params activityId int 活动Id
--]]
function ActivityMediator:ClearRemindIcon( activityId )
	if checkint(activityId) > 0 and app.badgeMgr:GetActivityTipByActivitiyId(activityId) == 1 then
		app.badgeMgr:SetActivityTipByActivitiyId(activityId, 0)
	end
	for i,v in ipairs(self.activityTabDatas) do
		if checkint(v.activityId) == checkint(activityId) then
			v.showRemindIcon = 0
			local activityTabView = self:GetViewComponent().viewData.activityTabView
			activityTabView:ClearRemindIcon(activityId)
			break
		end
	end
end
--[[
添加小红点
@params activityId int 活动Id
--]]
function ActivityMediator:AddRemindIcon( activityId )
	if checkint(activityId) > 0 and app.badgeMgr:GetActivityTipByActivitiyId(activityId) == 0 then
		app.badgeMgr:SetActivityTipByActivitiyId(activityId, 1)
	end
	for i,v in ipairs(self.activityTabDatas) do
		if checkint(v.activityId) == checkint(activityId) then
			v.showRemindIcon = 1
			local activityTabView = self:GetViewComponent().viewData.activityTabView
			activityTabView:AddRemindIcon(activityId)
			break
		end
	end
end
--[[
显示活动弹出页
--]]
function ActivityMediator:ShowActivtityPopup()
	local key = string.format('isShowActivityPopup_%s_%s', tostring(app.gameMgr:GetUserInfo().playerId), os.date('%Y-%m-%d'))
	if cc.UserDefault:getInstance():getBoolForKey(key) == true then return end
	cc.UserDefault:getInstance():setBoolForKey(key, true)
	local firstTopup = false
	local growthFund = false -- 成长基金(充值完成切换下一活动)
	local singlePay  = false -- 新手单笔充值(全部档位充值完成切换下一互动)
	local noviceAccPay  = false -- 新手累计充值(全部档位充值完成并领取切换下一互动)
	local levelGift  = false -- 等级礼包
	for i, v in ipairs(self.activityTabDatas) do
		if checkint(v.activityId) == checkint(ACTIVITY_TYPE.FIRST_PAYMENT) then
			firstTopup = true
		elseif checkint(v.activityId) == checkint(ACTIVITY_TYPE.GROWTH_FUND) and checkint(app.gameMgr:GetUserInfo().growthFundCacheData_.isPayLevelRewardsOpen) ~= 1 then
			growthFund = true
		elseif checkint(v.activityId) == checkint(ACTIVITY_TYPE.PERMANENT_SINGLE_PAY) then
			singlePay = true
		elseif checkint(v.activityId) == checkint(ACTIVITY_TYPE.NOVICE_ACCUMULATIVE_PAY) then
			noviceAccPay = true
		elseif checkint(v.activityId) == checkint(ACTIVITY_TYPE.LEVEL_GIFT) then
			levelGift = true
		end
	end

	if firstTopup then
		-- 首充活动
		local activityFirstTopupPopupMediator = require('Game.mediator.activity.popup.ActivityFirstTopupPopupMediator').new()
		AppFacade.GetInstance():RegistMediator(activityFirstTopupPopupMediator)
	elseif growthFund then
		-- 成长基金
		local activityGrowthFundPopupMediator = require('Game.mediator.activity.popup.ActivityGrowthFundPopupMediator').new()
		AppFacade.GetInstance():RegistMediator(activityGrowthFundPopupMediator)
	elseif singlePay and not GAME_MODULE_OPEN.NEW_NOVICE_ACC_PAY then
		-- 新手单笔充值
		local activityGrowthFundPopupMediator = require('Game.mediator.activity.popup.ActivitySinglePayPopupMediator').new()
		AppFacade.GetInstance():RegistMediator(activityGrowthFundPopupMediator)
	elseif noviceAccPay and GAME_MODULE_OPEN.NEW_NOVICE_ACC_PAY then
		local ActivityNoviceAccumulativePayMediator = require('Game.mediator.activity.noviceAccumulativePay.ActivityNoviceAccumulativePayMediator').new({isPopup = true, activityId = ACTIVITY_TYPE.NOVICE_ACCUMULATIVE_PAY})
		AppFacade.GetInstance():RegistMediator(ActivityNoviceAccumulativePayMediator)
	elseif levelGift and GAME_MODULE_OPEN.LEVEL_GIFT then
		-- 等级礼包
		local activityLevelGiftPopupMediator = require('Game.mediator.activity.popup.ActivityLevelGiftPopupMediator').new()
		AppFacade.GetInstance():RegistMediator(activityLevelGiftPopupMediator)
	end

end
function ActivityMediator:ClearActivityLayer()
	-- 添加屏蔽层
	uiMgr:GetCurrentScene():AddViewForNoTouch()
	local viewData = self:GetViewComponent().viewData
	viewData.activityTabView:SetEnabled(false)
	self.isControllable_ = false
	-- self.selectedTab = nil
	if self.activityEndTimeScheduler then
		scheduler.unscheduleGlobal(self.activityEndTimeScheduler)
		self.activityEndTimeScheduler = nil
	end
	if self.noviceBonusScheduler then
		scheduler.unscheduleGlobal(self.noviceBonusScheduler)
		self.noviceBonusScheduler = nil
	end
	if self.honeyBentoScheduler_ then
		scheduler.unscheduleGlobal(self.honeyBentoScheduler_)
		self.honeyBentoScheduler_ = nil
	end
	
	for i, mediatorName_ in pairs(self.showMediatorName) do
		self:GetFacade():UnRegsitMediator(mediatorName_)
	end
	self.showMediatorName = {}
	for k,v in pairs(self.showLayer) do
		v:removeFromParent()
	end
	self.showLayer = {}
	self:EnterLayer()
end

function ActivityMediator:EnterLayer()
	self:SendSignal(COMMANDS.COMMAND_Activity_Home)
end
function ActivityMediator:OnRegist(  )
	self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "show")
	local ActivityCommand = require('Game.command.ActivityCommand')
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Activity_Home, ActivityCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Activity_Newbie15Day, ActivityCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Activity_Draw_Newbie15Day, ActivityCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Activity_monthlyLogin, ActivityCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Activity_Draw_monthlyLogin, ActivityCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Activity_monthlyLoginWheel, ActivityCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Activity_Draw_monthlyLoginWheel, ActivityCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Activity_Draw_loveBento, ActivityCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Activity_Draw_serverTask, ActivityCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Activity_Draw_exchangeList, ActivityCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Activity_ChargeWheel, ActivityCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Activity_Draw_ChargeWheel, ActivityCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Activity_TakeawayPoint, ActivityCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Activity_TaskBinggoList, ActivityCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Activity_Draw_BinggoTask, ActivityCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Activity_ChestExchangeList, ActivityCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Activity_ChestExchange, ActivityCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Activity_LoginReward, ActivityCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Activity_Draw_LoginReward, ActivityCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Activity_AccumulativePay, ActivityCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Activity_Quest_Home, ActivityCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Activity_AccumulativeConsume, ActivityCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Activity_Questionnaire, ActivityCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Activity_Balloon_Home, ActivityCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Activity_SinglePay_Home, ActivityCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Activity_Permanent_Single_Pay, ActivityCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Activity_Web_Home, ActivityCommand)
	local ShopCommand = require( 'Game.command.ShopCommand')

	regPost(POST.Activity_Draw_restaurant)
	regPost(POST.ACTIVITYQUEST_HOME)
	--regPost(POST.ACTIVITY_DRAW_FIRSTPAY)
	self:EnterLayer()
end

function ActivityMediator:OnUnRegist(  )
	self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "hide")
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Activity_Home)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Activity_Newbie15Day)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Activity_Draw_Newbie15Day)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Activity_monthlyLogin)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Activity_Draw_monthlyLogin)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Activity_monthlyLoginWheel)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Activity_Draw_monthlyLoginWheel)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Activity_Draw_loveBento)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Activity_Draw_serverTask)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Activity_Draw_exchangeList)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Activity_ChargeWheel)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Activity_Draw_ChargeWheel)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Activity_TakeawayPoint)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Activity_TaskBinggoList)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Activity_Draw_BinggoTask)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Activity_ChestExchangeList)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Activity_ChestExchange)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Activity_LoginReward)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Activity_Draw_LoginReward)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Activity_AccumulativePay)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Activity_Quest_Home)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Activity_AccumulativeConsume)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Activity_Questionnaire)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Activity_Balloon_Home)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Activity_SinglePay_Home)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Activity_Permanent_Single_Pay)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Activity_Web_Home)

	unregPost(POST.Activity_Draw_restaurant)
	--unregPost(POST.ACTIVITY_DRAW_FIRSTPAY)
	if self.noviceBonusScheduler then
		scheduler.unscheduleGlobal(self.noviceBonusScheduler)
	end
	if self.activityEndTimeScheduler then
		scheduler.unscheduleGlobal(self.activityEndTimeScheduler)
	end
	if self.honeyBentoScheduler_ then
		scheduler.unscheduleGlobal(self.honeyBentoScheduler_)
	end
	-- local scene = uiMgr:GetCurrentScene()
	-- scene:RemoveGameLayer(self:GetViewComponent())
end
return ActivityMediator

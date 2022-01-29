--[[
活动 道具兑换 Mediator
--]]
local VIEW_TAG = 110120
local Mediator = mvc.Mediator
local NAME = "ActivityPropExchangeMediator"
local ActivityPropExchangeMediator = class(NAME, Mediator)

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local socket = require('socket')
local timerMgr = AppFacade.GetInstance():GetManager("TimerManager")

local COLOR1 = cc.c3b(100,100,200)
local RES_DIR = {
    goodNormal          = "ui/home/activity/activity_exchange_bg_goods.png",
    goodUnlock          = "ui/home/activity/activity_exchange_bg_goods_notunlock.png",
	timeBg              = "ui/home/activity/activity_exchange_bg_time.png",
	btn_orange      	= "ui/common/common_btn_orange.png",
	COOKING_LEVEL_UP    = _res("ui/home/kitchen/cooking_level_up_ico_arrow.png"),
}

local UI_TAG = {
    PROP_EXCHANGE             = 110120, -- 道具兑换
    FULL_SERVER               = 110121, -- 全部活动
    ACCUMULATIVE_RECHARGE     = 110122, -- 累充活动
    ACTIVITY_QUEST            = 110123, -- 活动副本
    ACCUMULATIVE_CONSUME      = 110124, -- 累消活动
	WHEEL_EXCHANGE  	      = 110125, -- 转盘次数兑换
	WORLD_BOSS_HUNT_REWARDS   = 110126, -- 世界BOSS狩猎奖励
	UR_PROBABILITY_UP		  = 110128, -- UR概率UP
	ASSEMBLY_ACTIVITY_WHEEL   = 110129, -- 组合活动转盘次数奖励
}

local ACTIVIEY_CONFIG = {
	['110120'] = {tag = UI_TAG.PROP_EXCHANGE, title = __('限时道具兑换'), isShowListTitle = true, homeInterface = COMMANDS.COMMAND_Activity_Draw_exchangeList, drawInterface = COMMANDS.COMMAND_Activity_Draw_exchange},
	['110121'] = {tag = UI_TAG.FULL_SERVER, title = __('全服累积刷关'), isShowListTitle = false, homeInterface = COMMANDS.COMMAND_Activity_Draw_serverTask, drawInterface = COMMANDS.COMMAND_Activity_Draw_drawServerTask},
	['110122'] = {tag = UI_TAG.ACCUMULATIVE_RECHARGE, title = __('累计充值'), isShowListTitle = false, homeInterface = COMMANDS.COMMAND_Activity_AccumulativePay_Home, drawInterface = COMMANDS.COMMAND_Activity_Draw_AccumulativePay},
	['110123'] = {tag = UI_TAG.ACTIVITY_QUEST, title = __('限时道具兑换'), isShowListTitle = true, homeInterface = 'empty', drawInterface = COMMANDS.COMMAND_Activity_Quest_Exchange},
	['110124'] = {tag = UI_TAG.ACCUMULATIVE_CONSUME, title = __('累计消费'), isShowListTitle = false, homeInterface = COMMANDS.COMMAND_Activity_AccumulativeConsume, drawInterface = COMMANDS.COMMAND_Activity_AccumulativeConsume_Draw},
	['110125'] = {tag = UI_TAG.WHEEL_EXCHANGE, title = __('豪华奖励'), isShowListTitle = false, homeInterface = COMMANDS.COMMAND_Activity_ChargeWheel, drawInterface = COMMANDS.COMMAND_Activity_Draw_Wheel_TimesRewards},
	['110126'] = {tag = UI_TAG.WORLD_BOSS_HUNT_REWARDS, title = __('狩猎奖励'), isShowListTitle = false, homeInterface = 'empty', drawInterface = POST.WORLD_BOSS_DAMAGE_TESTREWARD, isPostRequest = true},
	['110127'] = {tag = UI_TAG.UR_PROBABILITY_UP, title = __('次数奖励'), isShowListTitle = false, homeInterface = 'empty', drawInterface = POST.GAMBLING_PROBABILITY_UP_EXCHANGE, isPostRequest = true},
	['110129'] = {tag = UI_TAG.ASSEMBLY_ACTIVITY_WHEEL, title = __('豪华奖励'), isShowListTitle = false, homeInterface = POST.ASSEMBLY_ACTIVITY_BIGWHEEL_HOME, drawInterface = POST.ASSEMBLY_ACTIVITY_BIGWHEEL_TIMES_DRAW, isPostRequest = true},
}

local TASK_TYPE = {
	QUEST = "2",            -- 关卡
}

local timeLbStr = nil

function ActivityPropExchangeMediator:ctor(params, viewComponent )
	self.super:ctor(NAME,viewComponent)

	local data = params and checktable(params.data) or {}
	-- dump(data)
	self.canExcahnges = {}
	local tag         = tostring(data.tag)
	self.viewConfData = ACTIVIEY_CONFIG[tag]

	self.cellTag      = data.cellTag
	self.activityId   = checkint(data.activityId)
	self.leftSeconds  = data.leftSeconds
	
	self.activityHomeDatas = data.activityHomeDatas

	self.isAddDialog = data.isAddDialog

	-- 准备兑换的道具id
	self.exchangeId = nil
	
end

function ActivityPropExchangeMediator:InterestSignals()
	local signals = {
		SIGNALNAMES.Activity_Draw_ExchangeList_Callback,
		SIGNALNAMES.Activity_Draw_Exchange_Callback,

		SIGNALNAMES.Activity_Draw_serverTask_Callback,
		SIGNALNAMES.Activity_Draw_drawServerTask_Callback,

		SIGNALNAMES.Activity_AccumulativePay_Home_Callback,
		SIGNALNAMES.Activity_Draw_AccumulativePay_Callback,
		
		SIGNALNAMES.Activity_AccumulativeConsume_Callback,
		SIGNALNAMES.Activity_Draw_AccumulativeConsume_Callback,

		SIGNALNAMES.Activity_Quest_Exchange_Callback,

		SIGNALNAMES.Activity_ChargeWheel_Callback,
		SIGNALNAMES.Activity_Draw_Wheel_Timesrewards_Callback,

		POST.WORLD_BOSS_DAMAGE_TESTREWARD.sglName,

		POST.GAMBLING_PROBABILITY_UP_EXCHANGE.sglName,

		POST.ASSEMBLY_ACTIVITY_BIGWHEEL_HOME.sglName,
		POST.ASSEMBLY_ACTIVITY_BIGWHEEL_TIMES_DRAW.sglName,

		COMMON_BUY_VIEW_PAY,

		REFRESH_FULL_SERVER_EVENT,               -- 全服活动 长连接
		REFRESH_ACCUMULATIVE_RECHARGE_EVENT, 	 -- 累充活动 长连接
		REFRESH_ACCUMULATIVE_CONSUME_EVENT, 	 -- 累消活动 长连接

		'REFRESH_NOT_CLOSE_GOODS_EVENT',
	}

	return signals
end

function ActivityPropExchangeMediator:ProcessSignal(signal)
	local name = signal:GetName()
	local body = signal:GetBody()

	-- dump(body)
	if name == SIGNALNAMES.Activity_Draw_ExchangeList_Callback then

		local activityDataList = checktable(body.exchange)
		self.activityDataList = activityDataList
		self:updatePropExchangeList()

		-- dump(activityDataList, 'exchangeListexchangeList')

	elseif name == SIGNALNAMES.Activity_Draw_Exchange_Callback then
		local requestData = checktable(body.requestData)
		-- 用户请求的兑换次数
		local count = requestData.num or 1
		
		local rewards = body and body.rewards or self.activityDataList[self.exchangeIndex].rewards
		local cellData = self.activityDataList[self.exchangeIndex]
		cellData.leftExchangeTimes = cellData.leftExchangeTimes - count
		self.activityDataList[self.exchangeIndex] = cellData

		local requireGoods = clone(cellData.require)
		for i,v in ipairs(requireGoods) do
			v.num = -v.num * count
		end

		CommonUtils.DrawRewards(requireGoods, true)
		-- 判断是否显示剧情
		local activityDatas = self.activityHomeDatas.homeDatas
		local temp = {}
		for i,v in orderedPairs(rewards) do
			table.insert(temp, v)
		end
		local closeAction = nil 
		local goodsEnough = false
		if checkint(activityDatas.endStoryGoodsNum) > 1 then
			local hasNum = gameMgr:GetAmountByGoodId(checkint(activityDatas.endStoryGoods))
			if checkint(hasNum) >= checkint(activityDatas.endStoryGoodsNum) then
				goodsEnough = true
			end
		elseif checkint(activityDatas.endStoryGoodsNum) == 1 then 
			for i,v in ipairs(checktable(rewards)) do
				if checkint(v.goodsId) == checkint(activityDatas.endStoryGoods) then
					goodsEnough = true
					break 
				end
			end
		end
		if goodsEnough then
			uiMgr:AddDialog('common.RewardPopup', {rewards = rewards, closeCallback = function ()
    			local actStoryKey = string.format('IS_%s_ACTIVITY_END_STORY_SHOWED_%s', tostring(requestData.activityId), tostring(gameMgr:GetUserInfo().playerId))
    			local isSkipStory = cc.UserDefault:getInstance():getBoolForKey(actStoryKey, false)
    			if not isSkipStory then
    			    local storyPath  = string.format('conf/%s/activity/festivalStory.json', i18n.getLang())
    			    local storyStage = require('Frame.Opera.OperaStage').new({id = checkint(activityDatas.endStoryId), path = storyPath, guide = true, cb = function(sender)
    			        cc.UserDefault:getInstance():setBoolForKey(actStoryKey, true)
    			    end})
    			    storyStage:setPosition(display.center)
    			    sceneWorld:addChild(storyStage, GameSceneTag.Dialog_GameSceneTag)
    			end
			end})
		else
			uiMgr:AddDialog('common.RewardPopup', {rewards = rewards})
		end
	elseif name == SIGNALNAMES.Activity_Draw_serverTask_Callback then
		local activityDataList = checktable(body)
		self.activityDataList  = activityDataList

		self:updateFullServerList()

	elseif name == SIGNALNAMES.Activity_Draw_drawServerTask_Callback then
		-- dump(body)
		local rewards = body.rewards or {}
		if #rewards > 0 then
			uiMgr:AddDialog('common.RewardPopup', {rewards = rewards})
		end
		
		-- 有列表偏移值 表示 接受过长连接 会重新拉取home 数据  不进行下面更新操作
		if self.listContentOffset then
			return
		end 

		local taskId = body.requestData.taskId

		local dataIndex = 0
		for i,v in ipairs(self.activityDataList) do
			if v.taskId == taskId then
				dataIndex = i
				break
			end
		end

		if dataIndex == 0 then
			return
		end

		local data = self.activityDataList[dataIndex]

		data.hasDrawn = 1

		-- 是否满足条件, 是否领取过
		local isSatisfy, isDrawn = self:getTaskCompleteState(data)

		-- local progress           = checkint(data.progress)
		-- local targetNum          = checkint(data.targetNum)
		-- local status             = checkint(data.status)
		-- local hasDrawn           = checkint(data.hasDrawn)
		
		-- local isComplete         = status == 1          -- 是否完成任务
		-- progress                 = isComplete and targetNum or progress   -- 如果是完成状态则
		-- local isSatisfy          = progress >= targetNum -- 是否满足条件
		-- local isDrawn            = hasDrawn == 1        -- 是否领取过
		
		local taskId             = tostring(data.taskId)
		self.redPointState[taskId] = nil
		self:updateFullServerRedPoint()

		self:updateCellBtnState(dataIndex, isDrawn, isSatisfy)
		
	elseif name == SIGNALNAMES.Activity_AccumulativePay_Home_Callback then
		local activityDataList = checktable(body).accumulativeList
		self.activityDataList  = activityDataList
		self:updateAccumulativeRechargeList()
	elseif name == SIGNALNAMES.Activity_Draw_AccumulativePay_Callback then
		-- dump(body)
		local rewards = body.rewards or {}
		if #rewards > 0 then
			uiMgr:AddDialog('common.RewardPopup', {rewards = rewards})
		end
		-- 有列表偏移值 表示 接受过长连接 会重新拉取home 数据  不进行下面更新操作
		if self.listContentOffset then
			return
		end
		local accumulativeId = body.requestData.accumulativeId

		local dataIndex = 0
		for i,v in ipairs(self.activityDataList) do
			if checkint(v.accumulativeId) == checkint(accumulativeId) then
				dataIndex = i
				break
			end
		end

		if dataIndex == 0 then
			return
		end

		local data = self.activityDataList[dataIndex]

		data.hasDrawn = 1

		local gridView = self.viewData.gridView
		local cell = gridView:cellAtIndex(dataIndex - 1)
		local viewData           = cell.viewData

		local accumulativeId     = tostring(data.accumulativeId)
		local progress           = tonumber(data.progress)
		local targetNum          = tonumber(data.target)
		local hasDrawn           = checkint(data.hasDrawn)

		local isComplete         = tonumber(progress) > tonumber(targetNum)         -- 是否完成任务
		progress                 = isComplete and targetNum or progress   -- 如果是完成状态则
		local isSatisfy          = progress >= targetNum -- 是否满足条件
		local isDrawn            = hasDrawn == 1        -- 是否领取过
		self.redPointState[tostring(accumulativeId)] = nil
		self:updateAccumulativeRechargeRedPoint	()
		self:updateButtonState(viewData, isDrawn, isSatisfy)
	elseif name == SIGNALNAMES.Activity_AccumulativeConsume_Callback then
		local activityDataList = checktable(body).accumulativeList
		self.activityDataList  = activityDataList
		self:updateAccumulativeRechargeList()
	elseif name == SIGNALNAMES.Activity_Draw_AccumulativeConsume_Callback then
		-- dump(body)
		local rewards = body.rewards or {}
		if #rewards > 0 then
			uiMgr:AddDialog('common.RewardPopup', {rewards = rewards})
		end
		-- 有列表偏移值 表示 接受过长连接 会重新拉取home 数据  不进行下面更新操作
		if self.listContentOffset then
			return
		end
		local accumulativeId = body.requestData.accumulativeId

		local dataIndex = 0
		for i,v in ipairs(self.activityDataList) do
			if checkint(v.accumulativeId) == checkint(accumulativeId) then
				dataIndex = i
				break
			end
		end

		if dataIndex == 0 then
			return
		end

		local data = self.activityDataList[dataIndex]

		data.hasDrawn = 1

		local gridView = self.viewData.gridView
		local cell = gridView:cellAtIndex(dataIndex - 1)
		local viewData           = cell.viewData

		local accumulativeId     = tostring(data.accumulativeId)
		local progress           = tonumber(data.progress)
		local targetNum          = tonumber(data.target)
		local hasDrawn           = checkint(data.hasDrawn)

		local isComplete         = tonumber(progress) > tonumber(targetNum)         -- 是否完成任务
		progress                 = isComplete and targetNum or progress   -- 如果是完成状态则
		local isSatisfy          = progress >= targetNum -- 是否满足条件
		local isDrawn            = hasDrawn == 1        -- 是否领取过
		self.redPointState[tostring(accumulativeId)] = nil
		self:updateAccumulativeRechargeRedPoint	()
		self:updateButtonState(viewData, isDrawn, isSatisfy)
	elseif name == SIGNALNAMES.Activity_Quest_Exchange_Callback then
		local requestData = checktable(body.requestData)
		-- 用户请求的兑换次数
		local count = requestData.num or 1
		
		local rewards = body and body.rewards or self.activityDataList[self.exchangeIndex].rewards
		local cellData = self.activityDataList[self.exchangeIndex]
		cellData.leftExchangeTimes = cellData.leftExchangeTimes - count
		self.activityDataList[self.exchangeIndex] = cellData

		local requireGoods = clone(cellData.require)
		for i,v in ipairs(requireGoods) do
			v.num = -v.num * count
		end

		CommonUtils.DrawRewards(requireGoods, true)
		uiMgr:AddDialog('common.RewardPopup', {rewards = rewards})
	elseif name == SIGNALNAMES.Activity_ChargeWheel_Callback then
		local timesRewards = checktable(body.timesRewards)
		local activityDataList = {}
		for k,v in orderedPairs(timesRewards) do
			local temp = {
				accumulativeId = k,
				target = v.times,
				progress = checkint(body.drawnTimes),
				hasDrawn = checkint(v.hasDrawn),
				rewards = v.rewards
			}
			table.insert(activityDataList, temp)
		end
		self.activityDataList = activityDataList
		self:updateAccumulativeRechargeList()
	elseif name == SIGNALNAMES.Activity_Draw_Wheel_Timesrewards_Callback then
		local rewards = body.rewards or {}
		if #rewards > 0 then
			uiMgr:AddDialog('common.RewardPopup', {rewards = rewards})
		end

		local accumulativeId = body.requestData.orderId

		local dataIndex = 0
		for i,v in ipairs(self.activityDataList) do
			if checkint(v.accumulativeId) == checkint(accumulativeId) then
				dataIndex = i
				break
			end
		end

		if dataIndex == 0 then
			return
		end

		local data = self.activityDataList[dataIndex]

		data.hasDrawn = 1

		local gridView = self.viewData.gridView
		local cell = gridView:cellAtIndex(dataIndex - 1)
		local viewData           = cell.viewData

		local accumulativeId     = tostring(data.accumulativeId)
		local progress           = tonumber(data.progress)
		local targetNum          = tonumber(data.target)
		local hasDrawn           = checkint(data.hasDrawn)

		local isComplete         = tonumber(progress) > tonumber(targetNum)         -- 是否完成任务
		progress                 = isComplete and targetNum or progress   -- 如果是完成状态则
		local isSatisfy          = progress >= targetNum -- 是否满足条件
		local isDrawn            = hasDrawn == 1        -- 是否领取过
		self.redPointState[tostring(accumulativeId)] = nil
		self:updateButtonState(viewData, isDrawn, isSatisfy)
		-- 判断红点状态，如果清除这发送信号
		if table.nums(self.redPointState) == 0 then
			AppFacade.GetInstance():DispatchObservers(ACTIVITY_WHEEL_EXCHANGE_CLEAR, {activityId = self.activityId})
		end
	elseif name == POST.WORLD_BOSS_DAMAGE_TESTREWARD.sglName then
		local rewards = body.rewards or {}
		if #rewards > 0 then
			uiMgr:AddDialog('common.RewardPopup', {rewards = rewards})
		end
		
		local requestData = body.requestData
		-- local taskId = body.requestData.taskId
		local dataIndex = requestData.dataIndex
		-- local dataIndex = 0
		-- for i,v in ipairs(self.activityDataList) do
		-- 	if v.taskId == taskId then
		-- 		dataIndex = i
		-- 		break
		-- 	end
		-- end

		-- if dataIndex == 0 then
		-- 	return
		-- end

		local data = self.activityDataList[dataIndex]
		data.hasDrawn = 1
		-- 是否满足条件, 是否领取过
		local isSatisfy, isDrawn = self:getTaskCompleteState(data)
		self:updateCellBtnState(dataIndex, isDrawn, isSatisfy)

	elseif name == POST.GAMBLING_PROBABILITY_UP_EXCHANGE.sglName then
		local rewards = body.rewards or {}
		if #rewards > 0 then
			uiMgr:AddDialog('common.RewardPopup', {rewards = rewards})
		end
		local requestData = body.requestData
		local dataIndex = requestData.dataIndex

		local data = self.activityDataList[dataIndex]
		data.hasDrawn = 1
		-- 是否满足条件, 是否领取过
		local isSatisfy, isDrawn = self:getTaskCompleteState(data)
		self:updateCellBtnState(dataIndex, isDrawn, isSatisfy)

        app:DispatchObservers('EVENT_PROBABILITY_UP_EXCHANGE')
	elseif name == POST.ASSEMBLY_ACTIVITY_BIGWHEEL_HOME.sglName then
		local timesRewards = checktable(body.timesRewards)
		local activityDataList = {}
		for k,v in orderedPairs(timesRewards) do
			local temp = {
				accumulativeId = k,
				target = v.times,
				progress = checkint(body.drawnTimes),
				hasDrawn = checkint(v.hasDrawn),
				rewards = v.rewards
			}
			table.insert(activityDataList, temp)
		end
		self.activityDataList = activityDataList
		self:updateAccumulativeRechargeList()
	elseif name == POST.ASSEMBLY_ACTIVITY_BIGWHEEL_TIMES_DRAW.sglName then
		DotGameEvent.DynamicSendEvent({
		    event_id = table.concat({"2", "lottery_luxury" , body.requestData.orderId} , "_" ) ,
			event_content = "lottery",
			game_uuid = DotGameEvent.GAME_UUIDS.RETURN_FACTORY
	   })
		local rewards = body.rewards or {}
		if #rewards > 0 then
			uiMgr:AddDialog('common.RewardPopup', {rewards = rewards})
		end

		local accumulativeId = body.requestData.orderId

		local dataIndex = 0
		for i,v in ipairs(self.activityDataList) do
			if checkint(v.accumulativeId) == checkint(accumulativeId) then
				dataIndex = i
				break
			end
		end

		if dataIndex == 0 then
			return
		end

		local data = self.activityDataList[dataIndex]

		data.hasDrawn = 1

		local gridView = self.viewData.gridView
		local cell = gridView:cellAtIndex(dataIndex - 1)
		local viewData           = cell.viewData

		local accumulativeId     = tostring(data.accumulativeId)
		local progress           = tonumber(data.progress)
		local targetNum          = tonumber(data.target)
		local hasDrawn           = checkint(data.hasDrawn)

		local isComplete         = tonumber(progress) > tonumber(targetNum)         -- 是否完成任务
		progress                 = isComplete and targetNum or progress   -- 如果是完成状态则
		local isSatisfy          = progress >= targetNum -- 是否满足条件
		local isDrawn            = hasDrawn == 1        -- 是否领取过
		self.redPointState[tostring(accumulativeId)] = nil
		self:updateButtonState(viewData, isDrawn, isSatisfy)
		-- 判断红点状态，如果清除这发送信号
		if table.nums(self.redPointState) == 0 then
			AppFacade.GetInstance():DispatchObservers('ASSEMBLY_ACTIVITY_WHEEL_EXCHANGE_CLEAR', {activityId = self.activityId})
		end
	elseif name == COMMON_BUY_VIEW_PAY then
		local selectNum, materialMeet = checkint(body.selectNum), checkbool(body.materialMeet)

		if materialMeet then
			self:excahngesRequest(self.exchangeId, nil, selectNum)
		else
			uiMgr:ShowInformationTips(__('未满足兑换条件'))
		end
		self.exchangeId = nil
	elseif name == REFRESH_FULL_SERVER_EVENT then

		if app.badgeMgr:GetActivityTipByActivitiyId(self.activityId) == 1 then
			-- 保存 一下 列表偏移量
			local gridView = self.viewData.gridView
			self.listContentOffset = gridView:getContentOffset()
			-- 收到长连接  重置请求数据
			self:EnterLayer()
		end
	elseif name == REFRESH_ACCUMULATIVE_RECHARGE_EVENT then
		if app.badgeMgr:GetActivityTipByActivitiyId(self.activityId) == 1 then
			-- 保存 一下 列表偏移量
			local gridView = self.viewData.gridView
			self.listContentOffset = gridView:getContentOffset()
			-- 收到长连接  重置请求数据
			self:EnterLayer()
		end
	elseif name == REFRESH_ACCUMULATIVE_CONSUME_EVENT then
		if app.badgeMgr:GetActivityTipByActivitiyId(self.activityId) == 1 then
			-- 保存 一下 列表偏移量
			local gridView = self.viewData.gridView
			self.listContentOffset = gridView:getContentOffset()
			-- 收到长连接  重置请求数据
			self:EnterLayer()
		end	
	elseif name == 'REFRESH_NOT_CLOSE_GOODS_EVENT' then
		self:updatePropList()
	end
end

function ActivityPropExchangeMediator:Initial(key)
	self.super:Initial(key)
    local data = {tag = VIEW_TAG, mediatorName = NAME, viewConfData = self.viewConfData}
    -- dump(data)
	local viewComponent  = require('Game.views.ActivityPropExchangeListView').new(data)
	viewComponent:setTag(VIEW_TAG)
	display.commonUIParams(viewComponent, {ap = cc.p(0.5, 0.5), po = cc.p(display.width * 0.5, display.height * 0.5)})
	self:SetViewComponent(viewComponent)

	local scene = uiMgr:GetCurrentScene()
	if self.isAddDialog then
		scene:AddDialog(viewComponent)
	else
		scene:AddGameLayer(viewComponent)
	end

    self.viewData = viewComponent.viewData

    self:initUi()
 end

 function ActivityPropExchangeMediator:initUi()
    
    local gridView          = self.viewData.gridView

	self:initView()

	if self.viewConfData.tag == UI_TAG.PROP_EXCHANGE 
		or self.viewConfData.tag == UI_TAG.ACTIVITY_QUEST then

		gridView:setDataSourceAdapterScriptHandler(handler(self, self.OnPropExchangeDataSource))

	elseif self.viewConfData.tag == UI_TAG.FULL_SERVER 
		or self.viewConfData.tag == UI_TAG.UR_PROBABILITY_UP 
		or self.viewConfData.tag == UI_TAG.WORLD_BOSS_HUNT_REWARDS then

		gridView:setDataSourceAdapterScriptHandler(handler(self, self.OnFullServerDataSource))

	elseif self.viewConfData.tag == UI_TAG.ACCUMULATIVE_RECHARGE 
		or self.viewConfData.tag == UI_TAG.ACCUMULATIVE_CONSUME 
		or self.viewConfData.tag == UI_TAG.WHEEL_EXCHANGE
		or self.viewConfData.tag == UI_TAG.ASSEMBLY_ACTIVITY_WHEEL then

		gridView:setDataSourceAdapterScriptHandler(handler(self, self.OnAccumulativeRechargeDataSource))

	end

 end

 function ActivityPropExchangeMediator:initView()
	 if self.leftSeconds then
		local leftTime          = checkint(self.leftSeconds)
		local leftTimeLabel     = self.viewData.leftTimeLabel
        local countDownLabel    = self.viewData.countDownLabel
        local counDownViewSize  = self.viewData.counDownViewSize
	    local leftTimeLabelSize = display.getLabelContentSize(leftTimeLabel)

		-- todo  当时间小于等于 一天时  开启倒计时
		local callback = function (time)
			if time == 0 then
				self.leftTimeEnd = true
				self:updatePropList()
			end
			local timeStr = CommonUtils.getTimeFormatByType(time, 0)
			display.commonLabelParams(countDownLabel, {text = timeStr})
	
			local countDownLabelSize = display.getLabelContentSize(countDownLabel)
	
			leftTimeLabel:setPosition(counDownViewSize.width/2 - countDownLabelSize.width/2, leftTimeLabel:getPositionY())
			countDownLabel:setPosition(counDownViewSize.width/2 + leftTimeLabelSize.width/2, countDownLabel:getPositionY())
		end
	
		callback(leftTime)
		if leftTime <= 24 * 60 * 60 then
			timerMgr:AddTimer({name = NAME .. self.viewConfData.tag .. self.activityId, countdown = leftTime, callback = callback} )
		end
	else
		self:updateViewByTag()	
	end
 end

---------------------------------------------------------------
-----  道具兑换活动
 function ActivityPropExchangeMediator:OnPropExchangeDataSource(p_convertview, idx)
    local pCell = p_convertview
    local index = idx + 1
    if pCell == nil then
        local gridViewCellSize = self.viewData.gridViewCellSize
		pCell = self:GetViewComponent():CreateListCell()
		
		local exchangeBtn = pCell.viewData.exchangeBtn
		display.commonUIParams(exchangeBtn, {cb = handler(self, self.onClickHandler)})
    end

	xTry(function()
		
		local viewData        = pCell.viewData
		local bg              = viewData.bg
		local bgUnlock        = viewData.bgUnlock
		local timeLb          = viewData.timeLb
		local exchangeLb      = viewData.exchangeLb
		local exchangeBtn     = viewData.exchangeBtn
		local rewardLayer 	  = viewData.rewardLayer
		local materialLayer   = viewData.materialLayer
		
		local data                 = checktable(self.activityDataList[index])
		local leftExchangeTimes    = checkint(data.leftExchangeTimes)
		local rewards              = checktable(data.rewards)
		local require              = checktable(data.require)

		-- 表示 次数是否满足
		local timesMeet = leftExchangeTimes ~= 0

		-- local bgImg = canExchange and _res(RES_DIR.goodNormal) or _res(RES_DIR.goodUnlock)
		-- bg:setTexture(bgImg)
		bgUnlock:setVisible(not timesMeet)
		exchangeBtn:setVisible(timesMeet)
		exchangeLb:setVisible(not timesMeet)

		timeLb:setString(timeLbStr(leftExchangeTimes))
		rewardLayer:removeAllChildren()
		materialLayer:removeAllChildren()
		-- print("rewardLayerrewardLayer",rewardLayer:getChildrenCount())
		local rewardLayerSize = rewardLayer:getContentSize()
		local materialLayerSize = materialLayer:getContentSize()

		local showOwnNum = false
		for _, goodsInfo in pairs(rewards) do
			local avatarInfo = CONF.AVATAR.DEFINE:GetValue(goodsInfo.goodsId)
			if checkint(avatarInfo.max) == 1 and gameMgr:GetAmountByGoodId(goodsInfo.goodsId) >= 1 then
				showOwnNum = true
				break
			end
		end
		local params = {parent = rewardLayer, midPointX = rewardLayerSize.width / 2, midPointY = rewardLayerSize.height / 2, maxCol= 2, scale = 0.9, rewards = rewards, hideCustomizeLabel = true, showOwnNum = showOwnNum}
		local _, goodsLbs = CommonUtils.createPropList(params)
		for i,v in ipairs(goodsLbs) do
			local lb, amount, goodsId = v.lb, checkint(v.amount), checkint(v.goodsId)
			local ownAmount  = gameMgr:GetAmountByGoodId(goodsId)
			local avatarInfo = CONF.AVATAR.DEFINE:GetValue(goodsId)
			if checkint(avatarInfo.max) == 1 then
				lb:setString(string.fmt(__("(已拥有:_num1_/_num2_)"), {_num1_ = ownAmount, _num2_ = amount}))
			else
				lb:setVisible(false)
			end
		end

		local function callBack(sender)
			if isJapanSdk() then
				app.uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = sender.goodId, type = 1})
			else
				local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
				uiMgr:AddDialog("common.GainPopup", {goodId = sender.goodId})
			end
		end
		local params1 = {parent = materialLayer, midPointX = materialLayerSize.width / 2, midPointY = materialLayerSize.height / 2, maxCol= 2, scale = 0.8, rewards = require, hideAmount = true, callBack = callBack}
		local goodNodes, materialLbs = CommonUtils.createPropList(params1)

		-- 表示 材料是否满足
		local materialMeet = #materialLbs > 0
		for i,v in ipairs(materialLbs) do
			local lb, amount, goodsId = v.lb, checkint(v.amount), checkint(v.goodsId)
			local ownAmount = gameMgr:GetAmountByGoodId(goodsId)
			-- lb:setString(string.format("%s/%s", ownAmount, amount))
			local leftColor = ownAmount >= amount and fontWithColor('16').color or fontWithColor('10').color
			display.reloadRichLabel(lb, {c = {
				{text = ownAmount, fontSize = fontWithColor('16').fontSize, color = leftColor},
				{text = '/' .. amount, fontSize = fontWithColor('16').fontSize, color = fontWithColor('16').color},
			}})
			materialMeet = materialMeet and (ownAmount >= amount)
		end

		self.canExcahnges[index] = materialMeet and timesMeet

		self:updateExchangeButtonState(viewData, index)

		if self.leftTimeEnd then
			bgUnlock:setVisible(true)
		end

		pCell:setTag(index)
	end,__G__TRACKBACK__)

	return pCell
 end

 function ActivityPropExchangeMediator:updatePropExchangeList()
	local activityDataList = checktable(self.activityDataList)
	local gridView = self.viewData.gridView
	if #activityDataList <= 3 then
		gridView:setBounceable(false)
	end
	gridView:setCountOfCell(#activityDataList)
	gridView:reloadData()
 end

function ActivityPropExchangeMediator:onClickHandler(sender)
	PlayAudioByClickNormal()

	if self.leftTimeEnd then
		uiMgr:ShowInformationTips(__('活动已过期'))
		return
	end

	-- endCallback
	local index = sender:getParent():getParent():getTag()
	local data = self.activityDataList[index]
	local exchangeId = data.id
	self.exchangeIndex = index
	local leftExchangeTimes = data.leftExchangeTimes

	if self.canExcahnges[index] then
		if leftExchangeTimes == 1 then
			self:excahngesRequest(exchangeId, nil, 1)
		elseif leftExchangeTimes > 1 then
			local scene = uiMgr:GetCurrentScene()
			local commonBuyView = require("common.CommonBuyView").new({tag = 5555, mediatorName = "ActivityPropExchangeMediator", isClose = true})
			display.commonUIParams(commonBuyView, {ap = cc.p(0.5, 0.5), po = cc.p(display.width * 0.5, display.height * 0.5)})
			commonBuyView:setTag(5555)
			scene:AddDialog(commonBuyView)

			commonBuyView:updateData(1, data)

			self.exchangeId = exchangeId
		end
	else
		uiMgr:ShowInformationTips(__('未满足兑换条件'))
	end

end

function ActivityPropExchangeMediator:updateExchangeButtonState(viewData, index)
	local exchangeBtn     = viewData.exchangeBtn

	if self.leftTimeEnd then
		exchangeBtn:setNormalImage(_res('ui/common/common_btn_orange_disable.png'))
		exchangeBtn:setSelectedImage(_res('ui/common/common_btn_orange_disable.png'))
		return
	end

	if self.canExcahnges[index] then
		exchangeBtn:setNormalImage(_res('ui/common/common_btn_orange.png'))
		exchangeBtn:setSelectedImage(_res('ui/common/common_btn_orange.png'))
	else
		exchangeBtn:setNormalImage(_res('ui/common/common_btn_orange_disable.png'))
		exchangeBtn:setSelectedImage(_res('ui/common/common_btn_orange_disable.png'))
	end
	
end

-----  道具兑换活动
---------------------------------------------------------------



---------------------------------------------------------------
-----  全服活动

function ActivityPropExchangeMediator:updateFullServerList()
	
	self.redPointState = {}

	local sortfunction = function ( a, b )
		if a == nil then
			return true
		end
		if b == nil then
			return false
		end
		local aProgress = checkint(a.progress)
		local bProgress = checkint(b.progress)
		local aTargetNum = checkint(a.targetNum)
		local bTargetNum = checkint(b.targetNum)
		local aTaskId = checkint(a.taskId)
		local bTaskId = checkint(b.taskId)
		local aHasDrawn = checkint(a.hasDrawn) 
		local bHasDrawn = checkint(b.hasDrawn) 
		if a.status == 1 then
			aProgress = aTargetNum
		end
		if b.status == 1 then
			bProgress = bTargetNum
		end

		local aState = aProgress >= aTargetNum and 1 or 0
		local bState = bProgress >= bTargetNum and 1 or 0

		if aState == 1 and aHasDrawn == 0 and not self.redPointState[aTaskId] then
			self.redPointState[tostring(aTaskId)] = true
		end
		
		if bState == 1 and bHasDrawn == 0 and not self.redPointState[bTaskId] then
			self.redPointState[tostring(bTaskId)] = true
		end

		if aHasDrawn == bHasDrawn then
			if aState == bState then
				return aTaskId < bTaskId
			end
			return aState > bState
		end
		
		return checkint(a.hasDrawn) < checkint(b.hasDrawn)
	end
	table.sort(self.activityDataList, sortfunction )
	-- dump(self.activityDataList, '11activityDataList3')
	local gridView = self.viewData.gridView
	local listLen = #self.activityDataList
	if listLen <= 3 then
		gridView:setBounceable(false)
	end
	gridView:setCountOfCell(listLen)
	gridView:reloadData()
	
	if self.listContentOffset then
		gridView:setContentOffset(self.listContentOffset)
		self.listContentOffset = nil
	end

	self:updateFullServerRedPoint()
		
end

function ActivityPropExchangeMediator:OnFullServerDataSource(p_convertview, idx)
	local pCell = p_convertview
	local index = idx + 1
	
	if pCell == nil then
		pCell = self:GetViewComponent():CreateTaskCell()

		local button = pCell.viewData.button
		display.commonUIParams(button, {cb = handler(self, self.OnReceivedFullServerRewardAction)})
	end

	xTry(function()

		local data               = self.activityDataList[index]
		local name               = checkstr(data.name)
		local progress           = checkint(data.progress)
		local targetNum          = checkint(data.targetNum)
		local status             = checkint(data.status)
		local hasDrawn           = checkint(data.hasDrawn)
		local rewards            = checktable(data.rewards)
		local targetId           = tostring(data.targetId)

		local isComplete         = status == 1          -- 是否完成任务
		progress                 = isComplete and targetNum or progress   -- 如果是完成状态则
		local isSatisfy          = progress >= targetNum -- 是否满足条件
		local isDrawn            = hasDrawn == 1        -- 是否领取过

		local viewData           = pCell.viewData
		local descLabel          = viewData.descLabel
        local progressLabel      = viewData.progressLabel
        local propLayer          = viewData.propLayer
        local button             = viewData.button
        local alreadyReceived    = viewData.alreadyReceived

		if self.viewConfData.tag == UI_TAG.WORLD_BOSS_HUNT_REWARDS then
			local nameLabel          = viewData.nameLabel
			nameLabel:setVisible(true)
			display.commonLabelParams(nameLabel, {text = name})
			display.commonLabelParams(descLabel, {text = __('最高伤害达到')})
			local nameLabelSize = display.getLabelContentSize(nameLabel)
			display.commonUIParams(descLabel, {po = cc.p(nameLabel:getPositionX() + nameLabelSize.width + 10, nameLabel:getPositionY())})	
		elseif self.viewConfData.tag == UI_TAG.UR_PROBABILITY_UP then
			display.commonLabelParams(descLabel,     {text = __('抽取次数')})
		else
			local desc = name
			if targetId ~= '' then
				if TASK_TYPE.QUEST == tostring(data.type) then
					local cityData = CommonUtils.GetConfig('quest', 'quest', targetId)
					if cityData then
						desc = string.gsub(desc, targetId, cityData.name)
					end
				end
			end
			display.commonLabelParams(descLabel,     {text = desc})
		end
		
		
		display.commonLabelParams(progressLabel, {text = string.format('(%s/%s)', progress, targetNum)})
		local descLabelSize = display.getLabelContentSize(descLabel)
		display.commonUIParams(progressLabel, {po = cc.p(descLabel:getPositionX() + descLabelSize.width + 10, descLabel:getPositionY())})
		
		--  update prop layer
		propLayer:removeAllChildren()
		local callBack = function (sender)
			local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
			uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = sender.goodId, type = 1})
		end

		local startX = 20
		local goodNodeSize = nil
		local scale = 0.8
		for i,reward in ipairs(rewards) do
			local goodNode = require('common.GoodNode').new({id = reward.goodsId, amount = reward.num, showAmount = true, callBack = callBack})
			goodNode:setScale(scale)
			if goodNodeSize == nil then goodNodeSize = goodNode:getContentSize() end

			display.commonUIParams(goodNode, {ap = display.LEFT_CENTER, po = cc.p(startX + (i - 1) * (goodNodeSize.width * scale + 10), button:getPositionY())})
			propLayer:addChild(goodNode)
		end

		self:updateButtonState(viewData, isDrawn, isSatisfy)

		pCell:setTag(index)
	end,__G__TRACKBACK__)

	return pCell
 end

 
function ActivityPropExchangeMediator:OnReceivedFullServerRewardAction(sender)
	PlayAudioByClickNormal()
	if self.leftTimeEnd then
		uiMgr:ShowInformationTips(__('活动已过期'))
		return
	end

	local index = sender:getParent():getParent():getTag()
	local data = self.activityDataList[index]
	local progress     = checkint(data.progress)
	local targetNum    = checkint(data.targetNum)
	
	if progress >= targetNum then
		if self.viewConfData.tag == UI_TAG.WORLD_BOSS_HUNT_REWARDS then
			-- local questId = questId
			-- local testId = testId
			-- local stage = stage
			self:excahngesRequest(nil, index)
		elseif self.viewConfData.tag == UI_TAG.UR_PROBABILITY_UP then
			local exchangeId       = data.exchangeId
			self:excahngesRequest(exchangeId, index)
		else
			local taskId       = data.taskId
			self:excahngesRequest(taskId, index)
		end
	else
		uiMgr:ShowInformationTips(__('未满足领取条件'))
	end
	
end

--[[
	更新cell按钮状态
	@params dataIndex cell下标
	@params isDrawn   是否领取过
	@params isSatisfy 是否满足条件
]]
function ActivityPropExchangeMediator:updateCellBtnState(dataIndex, isDrawn, isSatisfy)
	local gridView = self.viewData.gridView
	local cell = gridView:cellAtIndex(dataIndex - 1)
	if cell then
		local viewData           = cell.viewData
		self:updateButtonState(viewData, isDrawn, isSatisfy)
	end
end

--[[
	更新按钮状态
	@params viewData  cell 视图数据
	@params isDrawn   是否领取过
	@params isSatisfy 是否满足条件
]]
function ActivityPropExchangeMediator:updateButtonState(viewData, isDrawn, isSatisfy )
	local button             = viewData.button
	local alreadyReceived    = viewData.alreadyReceived

	button:setVisible(not isDrawn)
	alreadyReceived:setVisible(isDrawn)

	if self.leftTimeEnd then
		button:setNormalImage(_res('ui/common/common_btn_orange_disable.png'))
		button:setSelectedImage(_res('ui/common/common_btn_orange_disable.png'))
		return
	end

	if not isDrawn then
		if isSatisfy then
			button:setNormalImage(_res('ui/common/common_btn_orange.png'))
			button:setSelectedImage(_res('ui/common/common_btn_orange.png'))
		else
			button:setNormalImage(_res('ui/common/common_btn_orange_disable.png'))
			button:setSelectedImage(_res('ui/common/common_btn_orange_disable.png'))
		end
	end

	
end


function ActivityPropExchangeMediator:updateFullServerRedPoint()
	app.badgeMgr:SetActivityTipByActivitiyId(self.activityId, table.nums(self.redPointState) == 0 and 0 or 1)
	-- gameMgr:GetUserInfo().serverTask[tostring(self.activityId)] = table.nums(self.redPointState) == 0 and 0 or 1

	local ActivityMediator = self:GetFacade():RetrieveMediator('ActivityMediator')
	if ActivityMediator then
		ActivityMediator:UpdateFullServerRedPoint(tostring(self.activityId))
	end
end

-----  全服活动
---------------------------------------------------------------

---------------------------------------------------------------
-----  累充活动
function ActivityPropExchangeMediator:updateAccumulativeRechargeList()
	
	self.redPointState = {}
	for i,v in ipairs(self.activityDataList) do
		local state = checkint(v.progress) >= checkint(v.target) and 1 or 0
		if state == 1 and v.hasDrawn == 0 and not self.redPointState[tostring(v.accumulativeId)] then
			self.redPointState[tostring(v.accumulativeId)] = true
		end
	end
	local gridView = self.viewData.gridView
	local listLen = #self.activityDataList
	if listLen <= 3 then
		gridView:setBounceable(false)
	end
	gridView:setCountOfCell(listLen)
	gridView:reloadData()
	if self.listContentOffset then
		gridView:setContentOffset(self.listContentOffset)
		self.listContentOffset = nil
	end
	if self.viewConfData.tag == UI_TAG.WHEEL_EXCHANGE 
	or self.viewConfData.tag == UI_TAG.ASSEMBLY_ACTIVITY_WHEEL then
	else
		self:updateAccumulativeRechargeRedPoint()
	end
end

function ActivityPropExchangeMediator:OnAccumulativeRechargeDataSource(p_convertview, idx)
	local pCell = p_convertview
	local index = idx + 1
	
	if pCell == nil then
		pCell = self:GetViewComponent():CreateTaskCell(self.viewConfData.tag)

		local button = pCell.viewData.button
		display.commonUIParams(button, {cb = handler(self, self.OnReceivedAccumulativeRechargeRewardAction)})
	end

	xTry(function()

		local data               = self.activityDataList[index]
		local name               = checkstr(data.name)
		local progress           = tonumber(data.progress)
		local targetNum          = tonumber(data.target)


		local hasDrawn           = checkint(data.hasDrawn)
		local rewards            = checktable(data.rewards)
		local targetId           = tostring(data.targetId)

		local isComplete         = progress > targetNum         -- 是否完成任务
		progress                 = isComplete and targetNum or progress   -- 如果是完成状态则
		local isSatisfy          = progress >= targetNum -- 是否满足条件
		local isDrawn            = hasDrawn == 1        -- 是否领取过

		local viewData           = pCell.viewData
		local propLayer          = viewData.propLayer
		local descLabel          = viewData.descLabel
        local progressLabel      = viewData.progressLabel

        local button             = viewData.button

		local desc = name
		if self.viewConfData.tag == UI_TAG.ACCUMULATIVE_RECHARGE then
			local str = string.format('%s%s', __('累计获得'), string.fmt(__('_num_积分'), {['_num_'] = targetNum}))
			display.commonLabelParams(descLabel,     {text = str})
		elseif self.viewConfData.tag == UI_TAG.ACCUMULATIVE_CONSUME then
			display.commonLabelParams(descLabel,     {text = string.fmt(__('累计消费_num_幻晶石'), {['_num_'] = targetNum})})
		elseif self.viewConfData.tag == UI_TAG.WHEEL_EXCHANGE 
		or self.viewConfData.tag == UI_TAG.ASSEMBLY_ACTIVITY_WHEEL then
			display.commonLabelParams(descLabel,     {text = string.fmt(__('累计抽奖_num_次'), {['_num_'] = targetNum})})
		end
		display.commonLabelParams(progressLabel, {text = string.format('(%s/%s)', progress, targetNum)})

		local descLabelSize = display.getLabelContentSize(descLabel)
		display.commonUIParams(progressLabel, {po = cc.p(descLabel:getPositionX() + descLabelSize.width + 10, descLabel:getPositionY())})
		
		propLayer:removeAllChildren()
		local callBack = function (sender)
			local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
			uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = sender.goodId, type = 1})
		end

		local startX = descLabel:getPositionX()
		local goodNodeSize = nil
		local scale = 0.8
		for i,reward in ipairs(rewards) do
			local goodNode = require('common.GoodNode').new({id = reward.goodsId, amount = reward.num, showAmount = true, callBack = callBack})
			goodNode:setScale(scale)
			if goodNodeSize == nil then goodNodeSize = goodNode:getContentSize() end

			display.commonUIParams(goodNode, {ap = display.LEFT_CENTER, po = cc.p(startX + (i - 1) * (goodNodeSize.width * scale + 10), button:getPositionY())})
			propLayer:addChild(goodNode)
		end

		self:updateButtonState(viewData, isDrawn, isSatisfy)
		

		pCell:setTag(index)
	end,__G__TRACKBACK__)

	return pCell
 end

function ActivityPropExchangeMediator:OnReceivedAccumulativeRechargeRewardAction(sender)
	PlayAudioByClickNormal()
	if self.leftTimeEnd then
		uiMgr:ShowInformationTips(__('活动已过期'))
		return
	end

	local index = sender:getParent():getParent():getTag()
	local data = self.activityDataList[index]
	local progress     = tonumber(data.progress)
	local targetNum    = tonumber(data.target)
	
	if progress >= targetNum then
		local accumulativeId       = data.accumulativeId
		self:excahngesRequest(accumulativeId, index)
	else
		uiMgr:ShowInformationTips(__('未满足领取条件'))
	end
end

function ActivityPropExchangeMediator:updateAccumulativeRechargeRedPoint()
	app.badgeMgr:SetActivityTipByActivitiyId(self.activityId, table.nums(self.redPointState) == 0 and 0 or 1)
	-- gameMgr:GetUserInfo().accumulativePay[tostring(self.activityId)] = table.nums(self.redPointState) == 0 and 0 or 1
	local ActivityMediator = self:GetFacade():RetrieveMediator('ActivityMediator')
	if self.viewConfData.tag == UI_TAG.ACCUMULATIVE_RECHARGE then
		if ActivityMediator then
			ActivityMediator:UpdateAccumulativeRechargeRedPoint(tostring(self.activityId))
		end
	elseif self.viewConfData.tag == UI_TAG.ACCUMULATIVE_CONSUME then
		if ActivityMediator then
			ActivityMediator:UpdateAccumulativeConsumeRedPoint(tostring(self.activityId))
		end
	end
end
-----  累充活动
---------------------------------------------------------------

---------------------------------------------------------------
-----  通用
function ActivityPropExchangeMediator:updatePropList(index)
	local gridView = self.viewData.gridView
	local offset = gridView:getContentOffset()
	gridView:reloadData()
	gridView:setContentOffset(offset)
end

function ActivityPropExchangeMediator:excahngesRequest(id, dataIndex, num)
	local tag = self.viewConfData.tag
	local data = nil
	if tag == UI_TAG.PROP_EXCHANGE then
		data = {activityId = self.activityId, exchangeId = id, num = num}
		-- self:GetFacade():DispatchObservers(SIGNALNAMES.Activity_Draw_Exchange_Callback, {requestData = {num = num}, rewards = self.activityDataList[self.exchangeIndex].rewards})
	elseif tag == UI_TAG.FULL_SERVER then
		data = {activityId = self.activityId, taskId = id, dataIndex = dataIndex}
		-- self:GetFacade():DispatchObservers(SIGNALNAMES.Activity_Draw_drawServerTask_Callback, {requestData = {taskId = id}, rewards = self.activityDataList[dataIndex].rewards})
	elseif tag == UI_TAG.ACCUMULATIVE_RECHARGE or tag == UI_TAG.ACCUMULATIVE_CONSUME then
		data = {activityId = self.activityId, accumulativeId = id}
	elseif tag == UI_TAG.WHEEL_EXCHANGE then
		data = {activityId = self.activityId, orderId = id}
	elseif tag == UI_TAG.ACTIVITY_QUEST then
		data = {activityId = self.activityId, exchangeId = id, num = num}
	elseif tag == UI_TAG.WORLD_BOSS_HUNT_REWARDS then
		local tempData = self.activityDataList[dataIndex]
		data = {questId = tempData.questId, testId = tempData.testId, stage = tempData.stage, dataIndex = dataIndex, cellTag = self.cellTag}
	elseif tag == UI_TAG.UR_PROBABILITY_UP then
		data = {activityId = self.activityId, exchangeId = id, dataIndex = dataIndex}
	elseif tag == UI_TAG.ASSEMBLY_ACTIVITY_WHEEL then
		data = {activityId = self.activityId, orderId = id}
	end

	local drawInterface = self.viewConfData.drawInterface
	if self.viewConfData.isPostRequest then
		self:SendSignal(drawInterface.cmdName, data)
	else
		self:SendSignal(drawInterface, data)
	end
end

function ActivityPropExchangeMediator:updateViewByTag()
	if self.viewConfData.tag == UI_TAG.WORLD_BOSS_HUNT_REWARDS then
		local tipLabel = self.viewData.tipLabel
		local myMaxDamage = self.activityHomeDatas.myMaxDamage

		display.commonLabelParams(tipLabel, {text = string.format(__('历史最高伤害: %s'), myMaxDamage)})
	end
end

function ActivityPropExchangeMediator:getTaskCompleteState(data)
	local progress           = checkint(data.progress)
	local targetNum          = checkint(data.targetNum)
	local status             = checkint(data.status)
	local hasDrawn           = checkint(data.hasDrawn)

	local isComplete         = status == 1          -- 是否完成任务
	progress                 = isComplete and targetNum or progress   -- 如果是完成状态则
	local isSatisfy          = progress >= targetNum -- 是否满足条件
	local isDrawn            = hasDrawn == 1        -- 是否领取过
	return isSatisfy, isDrawn
end

function ActivityPropExchangeMediator:EnterLayer()
	local homeInterface = self.viewConfData.homeInterface
	if homeInterface ~= 'empty' then
		if self.viewConfData.isPostRequest then
			self:SendSignal(homeInterface.cmdName, {activityId = self.activityId})
		else
			self:SendSignal(homeInterface, {activityId = self.activityId})
		end
	end
end

timeLbStr = function (times)
	local str = __('不限制兑换次数')
	if checkint(times) >= 0 then
		str = string.fmt(__('剩余兑换次数 _num_次'),{_num_ = times})
	end
	return str
end

function ActivityPropExchangeMediator:BackAction()
	self:GetViewComponent():CloseHandler()
end
function ActivityPropExchangeMediator:OnRegist() 
	local ActivityCommand = require('Game.command.ActivityCommand')

	self.hasSignal = false
	local homeInterface = self.viewConfData.homeInterface
	local drawInterface = self.viewConfData.drawInterface
	
	-- 能渠道cmdName 走 POST 注册
	local homeInterfaceCmdName = homeInterface.cmdName
	if homeInterfaceCmdName then
		self.hasSignal = self:GetFacade():HasSignal(homeInterfaceCmdName)
		-- 如果 没注册的话  则注册
		if not self.hasSignal then
			regPost(homeInterface)
		end
	elseif homeInterface ~= 'empty' then
		self.hasSignal = self:GetFacade():HasSignal(homeInterface)
		-- 如果 没注册的话  则注册
		if not self.hasSignal then
			self:GetFacade():RegistSignal(homeInterface, ActivityCommand)
		end
	end

	local drawInterfaceCmdName = drawInterface.cmdName
	if drawInterfaceCmdName then
		regPost(drawInterface)
	elseif drawInterface ~= 'empty' then
		self:GetFacade():RegistSignal(drawInterface, ActivityCommand)
	end

	if self.activityHomeDatas then
		if self.viewConfData.tag == UI_TAG.FULL_SERVER then
			self.activityDataList = self.activityHomeDatas.homeDatas
			self:updateFullServerList()
		elseif self.viewConfData.tag == UI_TAG.PROP_EXCHANGE or self.viewConfData.tag == UI_TAG.ACTIVITY_QUEST then
			self.activityDataList = self.activityHomeDatas.homeDatas.exchange
			self:updatePropExchangeList()
		elseif self.viewConfData.tag == UI_TAG.ACCUMULATIVE_RECHARGE 
			or self.viewConfData.tag == UI_TAG.ACCUMULATIVE_CONSUME then
			self.activityDataList = self.activityHomeDatas.homeDatas.accumulativeList
			self:EnterLayer()
		elseif self.viewConfData.tag == UI_TAG.WORLD_BOSS_HUNT_REWARDS then
			AppFacade.GetInstance():DispatchObservers('WORLD_BOSS_MANUAL_ENABLED_LIST', {isEnabled = false})
			self.activityDataList = self.activityHomeDatas.stageDatas
			self:updatePropExchangeList()
		elseif self.viewConfData.tag == UI_TAG.UR_PROBABILITY_UP then
			self.activityDataList = self.activityHomeDatas.exchange
			self:updatePropExchangeList()
		end
	else
		self:EnterLayer()
	end
end

function ActivityPropExchangeMediator:OnUnRegist()

	local homeInterface = self.viewConfData.homeInterface
	local homeInterfaceCmdName = homeInterface.cmdName
	if homeInterfaceCmdName then
		-- 如果 没注册的话  则注册
		if not self.hasSignal then
			unregPost(homeInterface)
		end
	elseif homeInterface ~= 'empty' then
		if not self.hasSignal then
			self:GetFacade():UnRegsitSignal(homeInterface)
		end
	end

	local drawInterface = self.viewConfData.drawInterface
	local drawInterfaceCmdName = drawInterface.cmdName

	if drawInterfaceCmdName then
		-- 如果 没注册的话  则注册
		unregPost(drawInterface)
	elseif drawInterface ~= 'empty' then
		self:GetFacade():UnRegsitSignal(drawInterface)
	end

	timerMgr:RemoveTimer(NAME .. self.viewConfData.tag .. self.activityId) --移除旧的计时器，活加新计时器

	if self.viewConfData.tag == UI_TAG.WORLD_BOSS_HUNT_REWARDS then
		AppFacade.GetInstance():DispatchObservers('WORLD_BOSS_MANUAL_ENABLED_LIST', {isEnabled = true})
	end
	AppFacade.GetInstance():DispatchObservers(ACTIVITY_PROP_EXCHANGE_EXIT)
	local scene = uiMgr:GetCurrentScene()
	if self.isAddDialog then
		scene:RemoveDialog(self.viewComponent)
	else
		scene:RemoveGameLayer(self.viewComponent)
	end
end

return ActivityPropExchangeMediator

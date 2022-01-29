--[[
等级奖励mediator
--]]
local Mediator = mvc.Mediator
local ActivityPayLoginRewardMediator = class("ActivityPayLoginRewardMediator", Mediator)
local NAME = "activity.payLoginReward.ActivityPayLoginRewardMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager('GameManager')
local scheduler = require('cocos.framework.scheduler')

local SIGNIN_STATE = {
	SIGNIN_TIMES_INSUFFICIENT         = 0,      --签到次数不足
	ALREADY_PAID_CAN_SIGNIN           = 1,      --已付费可签到
	NO_PAYMENT_CAN_SIGNIN             = 2,      --未付费可签到
	ALREADY_PAID_SUPPLEMENTARY_SIGNIN = 3,      --已付费 补签
	ALREADY_SIGNIN                    = 4,      --已签到
}

function ActivityPayLoginRewardMediator:ctor( params, viewComponent )
	self.super:ctor(NAME, viewComponent)
	local datas = params or {}
	self.activityId      = checkint(datas.activityId) -- 活动Id
	self.activityDatas   = {}    -- 活动home数据
	self.isControllable_ = true
	self.isTimeEnd       = false
end


function ActivityPayLoginRewardMediator:InterestSignals()
	local signals = {
		POST.ACTIVITY_PAY_LOGIN_REWARD.sglName,
		POST.ACTIVITY_DRAW_PAY_LOGIN_REWARD.sglName,
		POST.ACTIVITY_DRAW_CUMULATIVE_PAY_LOGIN_REWARD.sglName,

		SIGNALNAMES.Restaurant_Shop_GetPayOrder_Callback,
		EVENT_PAY_MONEY_SUCCESS_UI,
		COUNT_DOWN_ACTION
	}
	return signals
end

function ActivityPayLoginRewardMediator:ProcessSignal( signal )
	local name = signal:GetName()
	local body = checktable(signal:GetBody())
	if name == POST.ACTIVITY_PAY_LOGIN_REWARD.sglName then
		local isEnd = next(body) == nil or (body.loginRewardContent and next(body.loginRewardContent) == nil)
		self:GetViewComponent():UpdateUIShowState(isEnd)
		if isEnd then
			app.gameMgr:GetUserInfo().isPayLoginRewardsOpen = 0
			return
		end

		self:InitData(body)
		self:RefreshUI()

		local leftSeconds = checkint(body.leftSeconds)
		if leftSeconds > 0 then
			self:AddTimer_(leftSeconds)
		else
			self:StopTimer_()
			self:GetViewComponent():UpdateLeftTimeLabel(leftSeconds)
		end

	elseif name == POST.ACTIVITY_DRAW_PAY_LOGIN_REWARD.sglName then
		local rewards = body.rewards or {}
		
		-- update data
		self:DecreaseNotDrawCount()
		local requestData        = body.requestData or {}
		local state              = requestData.state
		local day                = requestData.day
		local index              = requestData.index
		local loginRewardContent = self.activityDatas.loginRewardContent or {}
		local data               = loginRewardContent[index]

		-- 如果是补签
		if state == SIGNIN_STATE.ALREADY_PAID_SUPPLEMENTARY_SIGNIN then
			local dailyConsume = clone(data.dailyConsume or {})
			for index, value in ipairs(dailyConsume) do
				dailyConsume[index].num = checkint(value.num) * -1
			end
			CommonUtils.DrawRewards(dailyConsume)
		end
		-- pop rewards
		if next(rewards) then
			uiMgr:AddDialog('common.RewardPopup', {rewards = rewards})
		end
		
		data.hasDrawn = 1
		local state = self:GetSignState(data)
		local tableView = self:GetViewData().tableView
		local cell = tableView:cellAtIndex(index - 1)
		if cell then
			self:GetViewComponent():UpdateSigninState(cell.viewData, data, state, index)
		end

		-- update cumulative rewards ui
		self.signinTimes = self.signinTimes + 1
		self:UpdateCumulativeRwardUI()
	elseif name == POST.ACTIVITY_DRAW_CUMULATIVE_PAY_LOGIN_REWARD.sglName then
		-- pop rewards
		local rewards = body.rewards or {}
		if next(rewards) then
			uiMgr:AddDialog('common.RewardPopup', {rewards = rewards})
		end
		
		-- update data
		self:DecreaseNotDrawCount()
		local requestData                  = body.requestData or {}
		local taskNum                      = requestData.taskNum
		local index                        = requestData.index
		local cumulativeLoginRewardContent = self.activityDatas.cumulativeLoginRewardContent or {}
		local data                         = cumulativeLoginRewardContent[index]
		data.hasDrawn = 1
		-- update ui
		self:UpdateCumulativeRwardUI(true)
	elseif name == SIGNALNAMES.Restaurant_Shop_GetPayOrder_Callback then
		local requestData = body.requestData
		if requestData.name ~= NAME then return end

		if body.orderNo then
			if device.platform == 'android' or device.platform == 'ios' then
				local data = self.activityDatas
				local AppSDK = require('root.AppSDK')
				AppSDK.GetInstance():InvokePay({amount = data.price, property = body.orderNo, goodsId = tostring(data.channelProductId), goodsName = __('幻晶石'), quantifier = __('个'), price = 0.1, count = 1})
			end
		end

	elseif name == EVENT_PAY_MONEY_SUCCESS_UI then
		if checkint(body.type) == PAY_TYPE.PT_PAY_LOGIN_REWARD then
			-- stop coundown
			self:StopTimer_()
			-- update data
			self:EnterLayer()
		end
	elseif name == COUNT_DOWN_ACTION then
		local timerName = body.timerName
		if timerName == NAME then
			local countdown = body.countdown
			if countdown <= 0 then
				app.gameMgr:GetUserInfo().isPayLoginRewardsOpen = 0
				self.isTimeEnd = true
				-- self:GetViewComponent():UpdateUIShowState(true)
			end
			self:GetViewComponent():UpdateLeftTimeLabel(body.countdown)
		end
	end
end

function ActivityPayLoginRewardMediator:Initial( key )
    self.super.Initial(self, key)
    
	local viewComponent = require( 'Game.views.activity.payLoginReward.ActivityPayLoginRewardView' ).new()
	display.commonUIParams(viewComponent, {ap = display.CENTER, po = display.center})
	self:SetViewComponent(viewComponent)
	

	self.viewData = viewComponent:GetViewData()
	self:InitView()
end

function ActivityPayLoginRewardMediator:CleanupView()
	local viewComponent = self:GetViewComponent()
	local scene = uiMgr:GetCurrentScene()
    if scene and viewComponent and not tolua.isnull(viewComponent) then
		scene:RemoveGameLayer(viewComponent)
    end
end

function ActivityPayLoginRewardMediator:OnRegist(  )
	regPost(POST.ACTIVITY_PAY_LOGIN_REWARD)
	regPost(POST.ACTIVITY_DRAW_PAY_LOGIN_REWARD)
	regPost(POST.ACTIVITY_DRAW_CUMULATIVE_PAY_LOGIN_REWARD)
	self:EnterLayer()
end

function ActivityPayLoginRewardMediator:OnUnRegist(  )
	self:StopTimer_()
	unregPost(POST.ACTIVITY_PAY_LOGIN_REWARD)
	unregPost(POST.ACTIVITY_DRAW_PAY_LOGIN_REWARD)
	unregPost(POST.ACTIVITY_DRAW_CUMULATIVE_PAY_LOGIN_REWARD)
end

function ActivityPayLoginRewardMediator:InitData(datas)
	self.activityDatas = datas

	-- 签到次数
	self.signinTimes = 0
	-- int not draw count
	self.notDrawCount  = 0
	local loginRewardContent = datas.loginRewardContent or {}
	for index, value in ipairs(loginRewardContent) do
		value.day = checkint(value.day)
		value.hasDrawn = checkint(value.hasDrawn)
		if checkint(value.hasDrawn) <= 0 then
			self.notDrawCount = self.notDrawCount + 1
		else
			self.signinTimes = self.signinTimes + 1
		end
	end
	local cumulativeLoginRewardContent = datas.cumulativeLoginRewardContent or {}
	for index, value in ipairs(cumulativeLoginRewardContent) do
		if checkint(value.hasDrawn) <= 0 then
			self.notDrawCount = self.notDrawCount + 1
		end
	end

	table.sort(loginRewardContent, function (a, b)
		if a.hasDrawn == b.hasDrawn then
			return a.day < b.day
		end
		return a.hasDrawn < b.hasDrawn
	end)
	self:CheckNotDrawCount()

end


function ActivityPayLoginRewardMediator:InitView()
	local viewData = self:GetViewData()
	local tableView = viewData.tableView
	tableView:setDataSourceAdapterScriptHandler(handler(self, self.OnDataSourceAdapter))

	display.commonUIParams(viewData.ruleBtn, {cb = handler(self, self.OnClickRuleBtnAction)})

	display.commonUIParams(viewData.rechargeBtn, {cb = handler(self, self.OnClickRechargeBtnAction)})

	display.commonUIParams(viewData.lookRewardBtn, {cb = handler(self, self.OnClickLookRewardBtnAction)})
	
	viewData.cumulativeRewardDrawBtn:SetCallback(handler(self, self.OnClickCumulativeRewardDrawBtnAction))

end

function ActivityPayLoginRewardMediator:RefreshUI()
	local viewData = self:GetViewData()
	local viewComponent = self:GetViewComponent()
	viewComponent:UpdateTableView(viewData, self.activityDatas.loginRewardContent)

	viewComponent:UpdateRechargeBtn(viewData, self.activityDatas)

	self:UpdateCumulativeRwardUI()
end

function ActivityPayLoginRewardMediator:AddTimer_(leftTime)
	app.activityMgr:createCountdownTemplate(checkint(leftTime) + 10, NAME) 
end
function ActivityPayLoginRewardMediator:StopTimer_()
	app.activityMgr:stopCountdown(NAME)
end

function ActivityPayLoginRewardMediator:UpdateCumulativeRwardUI(isDrawn)
	local viewData                     = self:GetViewData()
	local viewComponent                = self:GetViewComponent()
	local index, isFinalRewards        = self:GetCurCumulativeLoginRewardIndex()
	local cumulativeLoginRewardContent = self.activityDatas.cumulativeLoginRewardContent or {}
	local curData                      = cumulativeLoginRewardContent[index]
	local state, times, needTimes      = self:GetCumulativeRewardData(curData)
	viewComponent:UpdateCumulativeRewardDrawBtn(viewData, state, index)
	viewComponent:UpdateCumulativeTimesLabel(viewData, times, needTimes)
	
	if not isDrawn then
		viewComponent:UpdateCumulativeRewards(viewData, curData, isFinalRewards)
	else
		viewComponent:ShowCumulativeRewardAction(viewData, curData, isFinalRewards)
	end
end

function ActivityPayLoginRewardMediator:UpdateCell(viewData, data, index)
	local viewComponent = self:GetViewComponent()
	viewComponent:UpdateDayLabel(viewData, data.day)

	local state = self:GetSignState(data)
	viewComponent:UpdateSigninState(viewData, data, state, index)

	viewComponent:UpdateRewardLayer(viewData, data)
end

--==============================--
--desc: 获得签到状态
--@params data   table 签到数据
--@return state  int   签到状态
--==============================--
function ActivityPayLoginRewardMediator:GetSignState(data)
	local curDay       = checkint(self.activityDatas.curDay)
	local hasPurchased = checkint(self.activityDatas.hasPurchased)
	local state        = SIGNIN_STATE.SIGNIN_TIMES_INSUFFICIENT
	if hasPurchased <= 0 then
		state = SIGNIN_STATE.NO_PAYMENT_CAN_SIGNIN
	else
		local day      = checkint(data.day)
		local hasDrawn = checkint(data.hasDrawn)
		if hasDrawn > 0 then
			state = SIGNIN_STATE.ALREADY_SIGNIN
		elseif day == curDay then
			state = SIGNIN_STATE.ALREADY_PAID_CAN_SIGNIN
		elseif day < curDay then
			state = SIGNIN_STATE.ALREADY_PAID_SUPPLEMENTARY_SIGNIN
		end
	end

	return state
end

--==============================--
--desc: 获得累计登录奖励下标
--@return dataIndex    int 累计登录奖励下标
--==============================--
function ActivityPayLoginRewardMediator:GetCurCumulativeLoginRewardIndex()
	local cumulativeLoginRewardContent = self.activityDatas.cumulativeLoginRewardContent or {}
	local count = #cumulativeLoginRewardContent
	local dataIndex = count
	for i = 1, count do
		local data = cumulativeLoginRewardContent[i]
		local taskNum  = checkint(data.taskNum)
		local hasDrawn = checkint(data.hasDrawn)
		if hasDrawn <= 0 then
			dataIndex = i
			break
		end
	end
	return dataIndex, dataIndex == count
end

--==============================--
--desc: 获得累计将来数据
--@params curData     table  当前签到数据
--@return state       int 签到状态
--@return signinTimes int 签到次数
--@return taskNum     int 需要签到次数
--==============================--
function ActivityPayLoginRewardMediator:GetCumulativeRewardData(curData)
	local state       = 1
	local signinTimes = self.signinTimes
	local taskNum  	  = checkint(curData.taskNum)
	local hasDrawn 	  = checkint(curData.hasDrawn)
	if hasDrawn > 0 then
		state = 3
	elseif signinTimes >= taskNum then
		state = 2
	end
	return state, signinTimes, taskNum
end

--==============================--
--desc: 显示补签弹框
--@params data    table  签到数据
--@params index   int    签到数据下标
--@params state   int    签到状态
--@return
--==============================--
function ActivityPayLoginRewardMediator:ShowSupplementarySigninPopup(data, index, state)
	local dailyConsume = data.dailyConsume or {}

	-- check supplementary goods
	local errTips
	local goodsCoonsumeText
	for index, value in ipairs(dailyConsume) do
		local goodsId     = value.goodsId
		local ownCurrency = gameMgr:GetAmountByIdForce(goodsId)
		local consumeNum  = checkint(value.num)
		local goodsConfig = CommonUtils.GetConfig('goods', 'goods', goodsId) or {}
		if ownCurrency < consumeNum then
			errTips = string.format(__('%s不足'), goodsConfig.name)
			break
		end
		if goodsCoonsumeText == nil then
			goodsCoonsumeText = string.fmt('_num__name_', {_num_ = consumeNum, _name_ = tostring(goodsConfig.name)})
		else
			goodsCoonsumeText = goodsCoonsumeText .. string.fmt(',_num__name_', {_num_ = consumeNum, _name_ = tostring(goodsConfig.name)})
		end
	end

	if errTips then
		uiMgr:ShowInformationTips(errTips)
		return
	end

	local CommonTip  = require( 'common.NewCommonTip' ).new({text = string.format(__('是否花费%s签到'), goodsCoonsumeText),
    isOnlyOK = false, callback = function ()
		self:SendSignal(POST.ACTIVITY_DRAW_PAY_LOGIN_REWARD.cmdName, {day = data.day, index = index, state = state})
		
    end})
    CommonTip:setPosition(display.center)
    local scene = uiMgr:GetCurrentScene()
    scene:AddDialog(CommonTip)
end

--==============================--
--desc: 减少没有领取奖励的个数
--@return
--==============================--
function ActivityPayLoginRewardMediator:DecreaseNotDrawCount()
	self.notDrawCount = self.notDrawCount - 1
	self:CheckNotDrawCount()
end
--==============================--
--desc: 检查没有领取奖励的个数
--@return
--==============================--
function ActivityPayLoginRewardMediator:CheckNotDrawCount()
	if self.notDrawCount <= 0 then
		app.gameMgr:GetUserInfo().isPayLoginRewardsOpen = 0
	end
end

function ActivityPayLoginRewardMediator:EnterLayer()
	self:SendSignal(POST.ACTIVITY_PAY_LOGIN_REWARD.cmdName)
end

function ActivityPayLoginRewardMediator:OnDataSourceAdapter(p_convertview, idx)
	local pCell = p_convertview
    local index = idx + 1

	local viewComponent = self:GetViewComponent()
	if pCell == nil then
		local tableView = self:GetViewData().tableView
		pCell = viewComponent:CreateCell(tableView:getSizeOfCell())
		display.commonUIParams(pCell.viewData.drawBtn, {cb = handler(self, self.OnDrawBtnAction)})
	end
	local loginRewardContent = self.activityDatas.loginRewardContent
	local data = loginRewardContent[index]
	if data then
		self:UpdateCell(pCell.viewData, data, index)
	end
	pCell.viewData.drawBtn:setTag(index)
	return pCell
end

function ActivityPayLoginRewardMediator:OnClickRuleBtnAction()
	app.uiMgr:ShowIntroPopup({moduleId = -29})
end

function ActivityPayLoginRewardMediator:OnClickRechargeBtnAction()
	if self.isTimeEnd then
		uiMgr:ShowInformationTips(__('时间已结束'))
		return
	end
	if checkint(self.activityDatas.hasPurchased) > 0 then
		uiMgr:ShowInformationTips(__('已购买'))
		return
	end

	local productId = self.activityDatas.productId
	self:SendSignal(COMMANDS.COMMANDS_All_Shop_GetPayOrder,{productId = productId, name = NAME})
end

function ActivityPayLoginRewardMediator:OnClickLookRewardBtnAction()
	local popup  = require('Game.views.activity.payLoginReward.ActivityPayCumulativeLoginRewardView').new({ mediatorName = NAME, datas = self.activityDatas.cumulativeLoginRewardContent})
    display.commonUIParams(popup, {ap = cc.p(0.5, 0.5), po = display.center})
    app.uiMgr:GetCurrentScene():AddDialog(popup)
end

function ActivityPayLoginRewardMediator:OnDrawBtnAction(sender)
	if self.isTimeEnd then
		uiMgr:ShowInformationTips(__('时间已结束'))
		return
	end

	local index = checkint(sender:getTag())
	local state = checkint(sender:getUserTag())
	local loginRewardContent = self.activityDatas.loginRewardContent or {}
	local data = loginRewardContent[index] or {}
	local day = data.day
	if state ~= SIGNIN_STATE.ALREADY_PAID_CAN_SIGNIN then
		if state == SIGNIN_STATE.ALREADY_PAID_SUPPLEMENTARY_SIGNIN then
			self:ShowSupplementarySigninPopup(data, index, state)
		elseif state == SIGNIN_STATE.NO_PAYMENT_CAN_SIGNIN then
			app.uiMgr:ShowInformationTips(__('请先购买相应档位，即可领取豪华奖励'))
		end
		return
	end

	self:SendSignal(POST.ACTIVITY_DRAW_PAY_LOGIN_REWARD.cmdName, {day = day, index = index, state = state})
end

function ActivityPayLoginRewardMediator:OnClickCumulativeRewardDrawBtnAction(sender)
	if self.isTimeEnd then
		uiMgr:ShowInformationTips(__('时间已结束'))
		return
	end

	local index                        = sender:getTag()
	if index == -1 then
		return
	end
	local cumulativeLoginRewardContent = self.activityDatas.cumulativeLoginRewardContent or {}
	local data                         = cumulativeLoginRewardContent[index] or {}

	self:SendSignal(POST.ACTIVITY_DRAW_CUMULATIVE_PAY_LOGIN_REWARD.cmdName, {taskNum = data.taskNum, index = index})

end

function ActivityPayLoginRewardMediator:ClearExternalRedPoint()
	if self.canReceiveCount <= 0 then
		local activityM = self:GetFacade():RetrieveMediator('ActivityMediator')
		if activityM then
			-- todo 修改红点
			activityM:ClearRemindIcon(ACTIVITY_ID.LEVEL_REWARD)
		end
	end
end

function ActivityPayLoginRewardMediator:GetViewData()
	return self.viewData
end

return ActivityPayLoginRewardMediator
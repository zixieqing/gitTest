--[[
    单笔充值活动 Mediator
--]]
local Mediator = mvc.Mediator
local NAME = "ActivitySinglePayMediator"
local ActivitySinglePayMediator = class(NAME, Mediator)

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local timerMgr = AppFacade.GetInstance():GetManager("TimerManager")
local ActivitySinglePayCell = require('Game.views.activity.singlePay.ActivitySinglePayCell')
local ActivityPermanentSinglePayCell = require('Game.views.activity.singlePay.ActivityPermanentSinglePayCell')
--[[
@params table{
	activityId 	 int         活动id
	leftSeconds  int         剩余时间
	title  	     string      活动标题
}
--]]
function ActivitySinglePayMediator:ctor(params, viewComponent )
	self.super:ctor(NAME,viewComponent)
	local data = params or {}
    self.leftSeconds = checkint(data.leftSeconds) -- 活动剩余时间
	self.activityId = checkint(data.activityId) -- 活动Id
	self.activityTitle = data.title -- 活动标题
	self.isPermanent = self.activityId == checkint(ACTIVITY_TYPE.PERMANENT_SINGLE_PAY) -- 是否为常驻累充活动
	self.activityData = nil -- 活动数据
end

function ActivitySinglePayMediator:InterestSignals()
	local signals = {
        POST.ACTIVITY_SINGLE_PAY_HOME.sglName,
		POST.ACTIVITY_SINGLE_PAY_DRAW.sglName,
		POST.ACTIVITY_PERMANENT_SINGLE_PAY_HOME.sglName,
		POST.ACTIVITY_PERMANENT_SINGLE_PAY_DRAW.sglName,
		EVENT_PAY_MONEY_SUCCESS,
	}
	return signals
end

function ActivitySinglePayMediator:ProcessSignal(signal)
local name = signal:GetName()
	local body = signal:GetBody()
    if name == POST.ACTIVITY_SINGLE_PAY_HOME.sglName then
		self.activityData = checktable(body)
		self:UpdatePropExchangeList()
	elseif name == POST.ACTIVITY_SINGLE_PAY_DRAW.sglName then 
		uiMgr:AddDialog('common.RewardPopup', {rewards = body})
		-- 更新本地数据
		for i, v in ipairs(self.activityData) do
			if checkint(v.id) == checkint(body.requestData.stageId) then
				v.receivedTimes = checkint(v.receivedTimes) + 1
				break
			end
		end
		self:UpdatePropList()
	elseif name == POST.ACTIVITY_PERMANENT_SINGLE_PAY_HOME.sglName then 
		self.activityData = self:InitPermanentActivityData(checktable(body.stage))
		-- self.leftSeconds = checkint(body.remainTime)
		self:UpdatePropExchangeList()
	elseif name == POST.ACTIVITY_PERMANENT_SINGLE_PAY_DRAW.sglName then 
		uiMgr:AddDialog('common.RewardPopup', {rewards = body.rewards})
		-- 更新本地数据
		for i, v in ipairs(self.activityData) do
			if checkint(v.targetAmount) == checkint(body.requestData.amount) then
				v.receivedTimes = checkint(v.receivedTimes) + 1
				break
			end
		end
		self:UpdatePropList()
	elseif name == EVENT_PAY_MONEY_SUCCESS then
		self:EnterLayer()
	end
end

function ActivitySinglePayMediator:Initial(key)
	self.super.Initial(self, key)
	local viewComponent  = require('Game.views.activity.singlePay.ActivitySinglePayView').new({isPermanent = self.isPermanent})
	display.commonUIParams(viewComponent, {ap = cc.p(0.5, 0.5), po = cc.p(display.width * 0.5, display.height * 0.5)})
	self:SetViewComponent(viewComponent)
	local scene = uiMgr:GetCurrentScene()
	scene:AddDialog(viewComponent)
	
	viewComponent.viewData.title:setString(self.activityTitle)
	-- 判断活动类型
	if self.isPermanent then
		viewComponent.viewData.gridView:setDataSourceAdapterScriptHandler(handler(self, self.PermanentSinglePayDataSource))
	else
		viewComponent.viewData.gridView:setDataSourceAdapterScriptHandler(handler(self, self.SinglePayDataSource))
	end
	-- 添加定时器
	if self.leftSeconds > 0 then
		self:UpdateLeftSeconds(self.leftSeconds)
		timerMgr:AddTimer({name = NAME, countdown = self.leftSeconds, callback = handler(self, self.UpdateLeftSeconds)} )
	else
		self.leftTimeEnd = true
	end
end
--[[
兑换列表处理
--]]
 function ActivitySinglePayMediator:SinglePayDataSource(p_convertview, idx)
    local pCell = p_convertview
    local index = idx + 1
    if pCell == nil then
        local gridViewCellSize = self:GetViewComponent().viewData.gridViewCellSize
		pCell = ActivitySinglePayCell.new({size = gridViewCellSize})				
		display.commonUIParams(pCell.drawBtn, {cb = handler(self, self.DrawButtonCallback)})
    end
	xTry(function()
		local data = self.activityData[index]
		local targetAmount  = checkint(data.targetAmount)  -- 目标金额
		local receivedTimes = checkint(data.receivedTimes) -- 已经领取奖励次数
		local completeTimes = checkint(data.completeTimes) -- 完成充值目标次数
		local totalTimes    = checkint(data.totalTimes)    -- 总领取次数上限
		local descrStr = string.fmt(__('仅充值_num_元档位可领取'),{['_num_'] = targetAmount})
		pCell.descrLabel:setString(descrStr)
		local timeStr = string.fmt(__('领取次数 _num1_/_num2_'), {['_num1_'] = receivedTimes, ['_num2_'] = totalTimes})
		pCell.timeLabel:setString(timeStr)
		if receivedTimes == totalTimes then -- 已全部领取
			pCell.drawBtn:setEnabled(false)
			pCell.drawLb:setVisible(true)
			pCell.drawBtn:getLabel():setVisible(false)
			pCell.drawBtn:setNormalImage(_res('ui/common/activity_mifan_by_ico'))
			pCell.drawBtn:setSelectedImage(_res('ui/common/activity_mifan_by_ico'))
		else -- 未全部领取
			pCell.drawBtn:setEnabled(true)
			pCell.drawLb:setVisible(false)
			pCell.drawBtn:getLabel():setVisible(true)
			if completeTimes > receivedTimes then
				pCell.drawBtn:setNormalImage(_res('ui/common/common_btn_orange.png'))
				pCell.drawBtn:setSelectedImage(_res('ui/common/common_btn_orange.png'))
			else
				pCell.drawBtn:setNormalImage(_res('ui/common/common_btn_orange_disable.png'))
				pCell.drawBtn:setSelectedImage(_res('ui/common/common_btn_orange_disable.png'))
			end
		end
		-- 奖励列表
		pCell.rewardLayer:removeAllChildren()
		local callBack = function (sender)
			local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
			uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = sender.goodId, type = 1})
		end
		for i,reward in ipairs(data.rewards) do
			local goodNode = require('common.GoodNode').new({id = reward.goodsId, amount = reward.num, showAmount = true, callBack = callBack})
			goodNode:setScale(0.9)
			display.commonUIParams(goodNode, {ap = display.LEFT_CENTER, po = cc.p(5 + (i - 1) * (100 + 10), (pCell.bg:getContentSize().height - 38) / 2)})
			pCell.rewardLayer:addChild(goodNode)
		end
		pCell.drawBtn:setTag(index)
	end,__G__TRACKBACK__)

	return pCell
 end
 ------------------------------------------------------------------------
 -----------------------------常驻单笔充值---------------------------------
--[[
常驻单笔充值列表处理
--]]
function ActivitySinglePayMediator:PermanentSinglePayDataSource(p_convertview, idx)
    local pCell = p_convertview
    local index = idx + 1
    if pCell == nil then
        local gridViewCellSize = self:GetViewComponent().viewData.gridViewCellSize
		pCell = ActivityPermanentSinglePayCell.new({size = gridViewCellSize})				
		display.commonUIParams(pCell.drawBtn, {cb = handler(self, self.PermanentDrawButtonCallback)})
    end
	xTry(function()
		local data = self.activityData[index]
		local targetAmount  = checkint(data.targetAmount)  -- 目标金额
		local receivedTimes = checkint(data.receivedTimes) -- 已经领取奖励次数
		local completeTimes = checkint(data.completeTimes) -- 完成充值目标次数
		local totalTimes    = checkint(data.totalTimes)    -- 总领取次数上限
		local descrStr = string.fmt(__('仅充值_num_元档位可领取'),{['_num_'] = targetAmount})
		pCell.descrLabel:setString(descrStr)
		local timeStr = string.fmt('_num1_/_num2_', {['_num1_'] = receivedTimes, ['_num2_'] = totalTimes})
		pCell.timeLabel:setString(timeStr)
		pCell.drawLabel:setPositionX(pCell.bgSize.width - 30 - display.getLabelContentSize(pCell.timeLabel).width)
		local imgIndex = index
		if imgIndex == 1 then
			imgIndex = 3
		end
		pCell.bg:setTexture(_res(string.format('ui/home/activity/permanmentSinglePay/activity_danchong_bg_%d.png', imgIndex)))
		if receivedTimes == totalTimes then -- 已全部领取
			pCell.drawBtn:setEnabled(false)
			pCell.drawLb:setVisible(true)
			pCell.drawBtn:getLabel():setVisible(false)
			pCell.drawBtn:setNormalImage(_res('ui/common/activity_mifan_by_ico'))
			pCell.drawBtn:setSelectedImage(_res('ui/common/activity_mifan_by_ico'))
		else -- 未全部领取
			pCell.drawBtn:setEnabled(true)
			pCell.drawLb:setVisible(false)
			pCell.drawBtn:getLabel():setVisible(true)
			if completeTimes > receivedTimes then
				pCell.drawBtn:setNormalImage(_res('ui/common/common_btn_orange.png'))
				pCell.drawBtn:setSelectedImage(_res('ui/common/common_btn_orange.png'))
			else
				pCell.drawBtn:setNormalImage(_res('ui/common/common_btn_orange_disable.png'))
				pCell.drawBtn:setSelectedImage(_res('ui/common/common_btn_orange_disable.png'))
			end
		end
		-- 奖励列表
		pCell.rewardLayer:removeAllChildren()
		local callBack = function (sender)
			local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
			uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = sender.goodId, type = 1})
		end
		for i,reward in ipairs(data.rewards) do
			local goodNode = require('common.GoodNode').new({id = reward.goodsId, amount = reward.num, showAmount = true, callBack = callBack})
			goodNode:setScale(0.9)
			display.commonUIParams(goodNode, {ap = display.LEFT_CENTER, po = cc.p(286 + (i - 1) * (100 + 10), (pCell.bg:getContentSize().height - 38) / 2)})
			pCell.rewardLayer:addChild(goodNode)
		end
		pCell.drawBtn:setTag(index)
	end,__G__TRACKBACK__)

	return pCell
 end
--[[
常驻单笔充值活动领取按钮回调
--]] 
function ActivitySinglePayMediator:PermanentDrawButtonCallback(sender)
	PlayAudioByClickNormal()
	local tag = sender:getTag()
	local data = self.activityData[tag]
	if checkint(data.completeTimes) > checkint(data.receivedTimes) then
		self:SendSignal(POST.ACTIVITY_PERMANENT_SINGLE_PAY_DRAW.cmdName, {amount = data.targetAmount})
	else
		uiMgr:ShowInformationTips(__('未满足领取条件'))
	end
end
--[[
初始化常驻单笔充值活动数据
--]]
function ActivitySinglePayMediator:InitPermanentActivityData( data )
	local singlePayConf = CommonUtils.GetConfigAllMess('singlePay', 'activity')
	local permanentActivityData = {}
	for i,v in ipairs(data) do
		local singlePayData = singlePayConf[tostring(v.amount)]
		local temp = {
			targetAmount = checkint(v.amount),
			rewards = singlePayData.rewards,
			completeTimes = checkint(v.completeTimes),
			receivedTimes = checkint(v.receivedTimes),
			totalTimes = singlePayData.maxTimes,
		}
		table.insert(permanentActivityData, temp)
	end
	return permanentActivityData
end
 -----------------------------常驻单笔充值---------------------------------
 ------------------------------------------------------------------------

 function ActivitySinglePayMediator:UpdatePropExchangeList()
	local gridView = self:GetViewComponent().viewData.gridView
	gridView:setCountOfCell(#self.activityData)
	gridView:reloadData()
	self:RefreshRemindIcon()
 end
--[[
领取按钮点击回调
--]]
function ActivitySinglePayMediator:DrawButtonCallback(sender)
	PlayAudioByClickNormal()
	if self.leftTimeEnd then
		uiMgr:ShowInformationTips(__('活动已过期'))
		return
	end
	local tag = sender:getTag()
	local data = self.activityData[tag]
	if checkint(data.completeTimes) > checkint(data.receivedTimes) then
		self:SendSignal(POST.ACTIVITY_SINGLE_PAY_DRAW.cmdName, {activityId = self.activityId, stageId = data.id})
	else
		uiMgr:ShowInformationTips(__('未满足领取条件'))
	end
end
--[[
定时器回调
--]]
function ActivitySinglePayMediator:UpdateLeftSeconds( time )
	local countDownLabel = self:GetViewComponent().viewData.countDownLabel
	local leftTimeLabel = self:GetViewComponent().viewData.leftTimeLabel
	local counDownView = self:GetViewComponent().viewData.counDownView
	local counDownViewSize = counDownView:getContentSize()
	if time <= 0 then
		self.leftTimeEnd = true
		self:UpdatePropList()
		AppFacade.GetInstance():UnRegsitMediator("ActivitySinglePayMediator")
	end
	local changeTimeFormat = function (seconds)
		if seconds >= 86400 then
			local day = math.floor(seconds/86400)
			local overflowSeconds = seconds - day * 86400
			local hour = math.floor(overflowSeconds / 3600)

			c = string.fmt(__('_num1_天'), {['_num1_'] = tostring(day)})
		else
			local hour   = math.floor(seconds / 3600)
			local minute = math.floor((seconds - hour*3600) / 60)
			local sec    = (seconds - hour*3600 - minute*60)
			c = string.format("%.2d:%.2d:%.2d", hour, minute, sec)
		end
		return c
	end
	local timeStr = changeTimeFormat(time)
	display.commonLabelParams(countDownLabel, {text = timeStr})
	local countDownLabelSize = display.getLabelContentSize(countDownLabel)
	local leftTimeLabelSize = display.getLabelContentSize(leftTimeLabel)
	leftTimeLabel:setPosition(counDownViewSize.width/2 - countDownLabelSize.width/2, leftTimeLabel:getPositionY())
	countDownLabel:setPosition(counDownViewSize.width/2 + leftTimeLabelSize.width/2, countDownLabel:getPositionY())
end

function ActivitySinglePayMediator:UpdatePropList(index)
	local gridView = self:GetViewComponent().viewData.gridView
	local offset = gridView:getContentOffset()
	gridView:setCountOfCell(#self.activityData)
	gridView:reloadData()
	gridView:setContentOffset(offset)
	self:RefreshRemindIcon()
end
--[[
更新活动页面小红点
--]]
function ActivitySinglePayMediator:RefreshRemindIcon()
	local showRemindIcon = false
	for i, v in ipairs(self.activityData) do
		if checkint(v.totalTimes) > checkint(v.receivedTimes) and checkint(v.completeTimes) > checkint(v.receivedTimes) then
			showRemindIcon = true
			break
		end
	end
	local activityMediator = self:GetFacade():RetrieveMediator('ActivityMediator')
	if activityMediator then
		if showRemindIcon then
			activityMediator:AddRemindIcon(self.activityId)
			if self.isPermanent then
				gameMgr:GetUserInfo().tips.permanentSinglePay = 1
			end
		else
			activityMediator:ClearRemindIcon(self.activityId)
			if self.isPermanent then
				gameMgr:GetUserInfo().tips.permanentSinglePay = 0
			end
		end
	end
end
function ActivitySinglePayMediator:EnterLayer()
	if self.isPermanent then
		self:SendSignal(POST.ACTIVITY_PERMANENT_SINGLE_PAY_HOME.cmdName)
	else
		self:SendSignal(POST.ACTIVITY_SINGLE_PAY_HOME.cmdName, {activityId = self.activityId})
	end
end
function ActivitySinglePayMediator:OnRegist() 
	regPost(POST.ACTIVITY_SINGLE_PAY_HOME)
	regPost(POST.ACTIVITY_SINGLE_PAY_DRAW)
	regPost(POST.ACTIVITY_PERMANENT_SINGLE_PAY_HOME)
	regPost(POST.ACTIVITY_PERMANENT_SINGLE_PAY_DRAW)

    self:EnterLayer()
end
function ActivitySinglePayMediator:OnUnRegist()
	unregPost(POST.ACTIVITY_SINGLE_PAY_HOME)
	unregPost(POST.ACTIVITY_SINGLE_PAY_DRAW)
	unregPost(POST.ACTIVITY_PERMANENT_SINGLE_PAY_HOME)
	unregPost(POST.ACTIVITY_PERMANENT_SINGLE_PAY_DRAW)
	timerMgr:RemoveTimer(NAME) 
	local scene = uiMgr:GetCurrentScene()
	scene:RemoveDialog(self:GetViewComponent())
end

return ActivitySinglePayMediator
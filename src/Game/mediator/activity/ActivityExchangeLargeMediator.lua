--[[
活动 道具兑换加长版 Mediator
--]]
local Mediator = mvc.Mediator
local NAME = "ActivityExchangeLargeMediator"
local ActivityExchangeLargeMediator = class(NAME, Mediator)

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local timerMgr = AppFacade.GetInstance():GetManager("TimerManager")
local ActivityExchangeLargeCell = require('Game.views.activity.ActivityExchangeLargeCell')
--[[
@params table{
	isLarge                bool        是否为加长页面(默认false)
	leftSeconds            int         剩余时间
	exchangePost 	 	   POST    	   兑换信号
	extra                  table       额外参数
	exchangeIdName         str         兑换id名称
	exchangeBack  	 	   function    兑换回调
	exchangeListData       table       兑换列表{
		id 				  int  兑换id
		require           list 需求道具（同奖励格式）
		rewards           list 奖励列表
		leftExchangeTimes int  剩余兑换次数 -1为无限
	}
	oneMaxExchangeTimes    int         一次请求最大兑换次数
	leftExchangeName       string      剩余兑换名称
	hideTimer              bool        是否隐藏计时器
}
--]]
function ActivityExchangeLargeMediator:ctor(params, viewComponent )
	self.super:ctor(NAME,viewComponent)
	local data = params or {}
	self.isLarge = data.isLarge or false
	self.leftSeconds = checkint(data.leftSeconds)
	self.exchangePost = data.exchangePost
	self.exchangeListData = checktable(data.exchangeListData)
	self.extra = checktable(data.extra)
	self.exchangeIdName = data.exchangeIdName or 'exchangeId'
	self.leftTimeEnd = nil
	self.canExchanges = {}
	self.exchangeId = nil -- 兑换id
	self.exchangeIndex = nil 
	self.exchangeBack = data.exchangeBack
	self.oneMaxExchangeTimes = data.oneMaxExchangeTimes
	self.leftExchangeName = data.leftExchangeName
	self.hideTimer = data.hideTimer and true or false
end

function ActivityExchangeLargeMediator:InterestSignals()
	local signals = {
		COMMON_BUY_VIEW_PAY,
		'REFRESH_NOT_CLOSE_GOODS_EVENT',
	}
	if self.exchangePost then
		table.insert(signals, self.exchangePost.sglName)
	end
	return signals
end

function ActivityExchangeLargeMediator:ProcessSignal(signal)
	local name = signal:GetName()
	local body = signal:GetBody()
	if name == POST.ACTIVITY_BALLOON_GET_BREAK_GOODS.sglName then -- 气球活动获取击破气球道具
		self:BalloonGetBreakGoodsDraw(body)
	elseif name == POST.ACTIVITY_BALLOON_EXCHANGE.sglName then -- 气球活动兑换
		self:BalloonExchangeDraw(body)
	elseif name == POST.ASSEMBLY_ACTIVITY_EXCHANGE.sglName then -- 组合活动兑换
		local requestData = body.requestData
		DotGameEvent.DynamicSendEvent({
			game_uuid = DotGameEvent.GAME_UUIDS.RETURN_FACTORY,
			event_id = table.concat({"2" ,"change",requestData[self.exchangeIdName]},"_") ,
			event_content = "change"
	    })
		self:AssemBlyActivityDraw(body)
	elseif name == COMMON_BUY_VIEW_PAY then
		local selectNum, materialMeet = checkint(body.selectNum), checkbool(body.materialMeet)

		if materialMeet then
			self:ExcahngesRequest(self.exchangeId, selectNum)
		else
			uiMgr:ShowInformationTips(__('未满足兑换条件'))
		end
		self.exchangeId = nil
	elseif name == 'REFRESH_NOT_CLOSE_GOODS_EVENT' then
		self:UpdatePropList()
	end
end

function ActivityExchangeLargeMediator:Initial(key)
	self.super.Initial(self, key)
	local viewComponent  = require('Game.views.activity.ActivityExchangeLargeView').new({isLarge = self.isLarge, hideTimer = self.hideTimer})
	display.commonUIParams(viewComponent, {ap = cc.p(0.5, 0.5), po = cc.p(display.width * 0.5, display.height * 0.5)})
	self:SetViewComponent(viewComponent)
	local scene = uiMgr:GetCurrentScene()
	scene:AddGameLayer(viewComponent)
	viewComponent.viewData.gridView:setDataSourceAdapterScriptHandler(handler(self, self.ExchangeListDataSource))
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
 function ActivityExchangeLargeMediator:ExchangeListDataSource(p_convertview, idx)
    local pCell = p_convertview
    local index = idx + 1
    if pCell == nil then
        local gridViewCellSize = self:GetViewComponent().viewData.gridViewCellSize
		pCell = ActivityExchangeLargeCell.new({size = gridViewCellSize, isLarge = self.isLarge})				
		display.commonUIParams(pCell.exchangeBtn, {cb = handler(self, self.ExchangeButtonCallback)})
    end

	xTry(function()
		
		local bg              = pCell.bg
		local bgUnlock        = pCell.bgMask
		local timeLb          = pCell.timeLb
		local exchangeLb      = pCell.exchangeLb
		local exchangeBtn     = pCell.exchangeBtn
		local rewardLayer 	  = pCell.rewardLayer
		local materialLayer   = pCell.materialLayer
		
		local data                 = checktable(self.exchangeListData[index])
		local leftExchangeTimes    = checkint(data.leftExchangeTimes) -- 剩余兑换次数
		local rewards              = checktable(data.rewards) -- 奖励列表
		local require              = checktable(data.require) -- 材料列表
		-- 表示 次数是否满足
		local timesMeet = leftExchangeTimes ~= 0
		bgUnlock:setVisible(not timesMeet)
		exchangeBtn:setVisible(timesMeet)
		exchangeLb:setVisible(not timesMeet)

		timeLb:setString(self:GetTimeLabelStr(leftExchangeTimes))
		rewardLayer:removeAllChildren()
		materialLayer:removeAllChildren()
		local rewardLayerSize = rewardLayer:getContentSize()
		local materialLayerSize = materialLayer:getContentSize()

		local params = {parent = rewardLayer, midPointX = rewardLayerSize.width / 2, midPointY = rewardLayerSize.height / 2, maxCol= 2, scale = 0.9, rewards = rewards, hideCustomizeLabel = true}
		CommonUtils.createPropList(params)

		local function callBack(sender)
			local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
			uiMgr:AddDialog("common.GainPopup", {goodId = sender.goodId})
		end
		local params1 = {parent = materialLayer, midPointX = materialLayerSize.width / 2, midPointY = materialLayerSize.height / 2, maxCol = 5, scale = 0.8, rewards = require, hideAmount = true, callBack = callBack}
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

		self.canExchanges[index] = materialMeet and timesMeet

		self:UpdateExchangeButtonState(exchangeBtn, index)

		if self.leftTimeEnd and not self.hideTimer then
			bgUnlock:setVisible(true)
		end

		pCell:setTag(index)
	end,__G__TRACKBACK__)

	return pCell
 end

 function ActivityExchangeLargeMediator:UpdatePropExchangeList()
	local activityDataList = checktable(self.exchangeListData)
	local gridView = self:GetViewComponent().viewData.gridView
	if #activityDataList <= 3 then
		gridView:setBounceable(false)
	end
	gridView:setCountOfCell(#activityDataList)
	gridView:reloadData()
 end
--[[
兑换按钮点击回调
--]]
function ActivityExchangeLargeMediator:ExchangeButtonCallback(sender)
	PlayAudioByClickNormal()
	if self.leftTimeEnd and not self.hideTimer then
		uiMgr:ShowInformationTips(__('活动已过期'))
		return
	end

	-- endCallback
	local index = sender:getParent():getParent():getTag()
	local data = clone(self.exchangeListData[index])
	local exchangeId = data.id
	self.exchangeIndex = index
	local leftExchangeTimes = data.leftExchangeTimes

	if self.canExchanges[index] then
		if self.oneMaxExchangeTimes then

			data.leftExchangeTimes = self.oneMaxExchangeTimes
			self.exchangeId = exchangeId

			local commonBuyView = self:CreateCommonBuyView()
			commonBuyView:updateData(1, data)

		elseif leftExchangeTimes == 1 then
			self:ExcahngesRequest(exchangeId, 1)
		else

			if leftExchangeTimes < 0 then
				data.leftExchangeTimes = 99
			end
			self.exchangeId = exchangeId
			
			local commonBuyView = self:CreateCommonBuyView()
			commonBuyView:updateData(1, data)
		end
	else
		uiMgr:ShowInformationTips(__('未满足兑换条件'))
	end

end

--[[
创建通用支付视图
--]]
function ActivityExchangeLargeMediator:CreateCommonBuyView()
	local scene = uiMgr:GetCurrentScene()
	local commonBuyView = require("common.CommonBuyView").new({tag = 5555, mediatorName = "ActivityExchangeLargeMediator", isClose = true})
	display.commonUIParams(commonBuyView, {ap = cc.p(0.5, 0.5), po = cc.p(display.width * 0.5, display.height * 0.5)})
	commonBuyView:setTag(5555)
	scene:AddDialog(commonBuyView)
	return commonBuyView
end

--[[
定时器回调
--]]
function ActivityExchangeLargeMediator:UpdateLeftSeconds( time )
	local countDownLabel = self:GetViewComponent().viewData.countDownLabel
	local leftTimeLabel = self:GetViewComponent().viewData.leftTimeLabel
	local counDownView = self:GetViewComponent().viewData.counDownView
	local counDownViewSize = counDownView:getContentSize()
	if time <= 0 then
		self.leftTimeEnd = true
		self:UpdatePropList()
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
function ActivityExchangeLargeMediator:UpdateExchangeButtonState(exchangeBtn, index)
	if self.leftTimeEnd and not self.hideTimer then
		exchangeBtn:setNormalImage(_res('ui/common/common_btn_orange_disable.png'))
		exchangeBtn:setSelectedImage(_res('ui/common/common_btn_orange_disable.png'))
		return
	end

	if self.canExchanges[index] then
		exchangeBtn:setNormalImage(_res('ui/common/common_btn_orange.png'))
		exchangeBtn:setSelectedImage(_res('ui/common/common_btn_orange.png'))
	else
		exchangeBtn:setNormalImage(_res('ui/common/common_btn_orange_disable.png'))
		exchangeBtn:setSelectedImage(_res('ui/common/common_btn_orange_disable.png'))
	end
	
end

function ActivityExchangeLargeMediator:UpdatePropList(index)
	local gridView = self:GetViewComponent().viewData.gridView
	local offset = gridView:getContentOffset()
	gridView:reloadData()
	gridView:setContentOffset(offset)
end
function ActivityExchangeLargeMediator:ExcahngesRequest( id, selectNum )
	local data = clone(self.extra)
	data.num = checkint(selectNum)
	data[self.exchangeIdName] = id
	self:SendSignal(self.exchangePost.cmdName, data)
end
function ActivityExchangeLargeMediator:GetTimeLabelStr(times)
	local str = __('不限制兑换次数')
	if checkint(times) >= 0 then
		str = string.fmt(self.leftExchangeName or __('剩余兑换次数 _num_次'),{_num_ = times})
	end
	return str
end
------------------------------------------------------------
--[[
气球活动兑换成功
--]]
function ActivityExchangeLargeMediator:BalloonExchangeDraw( responseData )
	local count = responseData.requestData.num or 1
	
	local rewards = responseData and responseData.rewards or self.exchangeListData[self.exchangeIndex].rewards
	local cellData = self.exchangeListData[self.exchangeIndex]
	cellData.leftExchangeTimes = cellData.leftExchangeTimes - count
	self.exchangeListData[self.exchangeIndex] = cellData
	local requireGoods = clone(cellData.require)
	for i,v in ipairs(requireGoods) do
		v.num = -v.num * count
	end
	CommonUtils.DrawRewards(requireGoods, true)
	local params = {rewards = rewards, closeCallback = self.exchangeBack}
	uiMgr:AddDialog('common.RewardPopup', params)

end
--[[
气球活动换取击破道具成功
--]]
function ActivityExchangeLargeMediator:BalloonGetBreakGoodsDraw( responseData )
	local count = responseData.requestData.num or 1
	local rewards = responseData and responseData.rewards or self.exchangeListData[self.exchangeIndex].rewards
	local cellData = self.exchangeListData[self.exchangeIndex]
	cellData.leftExchangeTimes = cellData.leftExchangeTimes - count
	self.exchangeListData[self.exchangeIndex] = cellData
	local requireGoods = clone(cellData.require)
	for i,v in ipairs(requireGoods) do
		v.num = -v.num * count
	end
	CommonUtils.DrawRewards(requireGoods, true)
	uiMgr:AddDialog('common.RewardPopup', {rewards = rewards})
end
--[[
组合活动兑换
--]]
function ActivityExchangeLargeMediator:AssemBlyActivityDraw( responseData )
	local count = responseData.requestData.num or 1
	local rewards = responseData and responseData.rewards or self.exchangeListData[self.exchangeIndex].rewards
	local cellData = self.exchangeListData[self.exchangeIndex]
	cellData.leftExchangeTimes = cellData.leftExchangeTimes - count
	self.exchangeListData[self.exchangeIndex] = cellData
	local requireGoods = clone(cellData.require)
	for i,v in ipairs(requireGoods) do
		v.num = -v.num * count
	end
	CommonUtils.DrawRewards(requireGoods, true)
	uiMgr:AddDialog('common.RewardPopup', {rewards = rewards})
end
------------------------------------------------------------
function ActivityExchangeLargeMediator:BackAction()
	self:GetViewComponent():CloseHandler()
end
function ActivityExchangeLargeMediator:OnRegist() 
	if self.exchangePost then
		regPost(self.exchangePost)
	end
	self:UpdatePropExchangeList()
end

function ActivityExchangeLargeMediator:OnUnRegist()
	if self.exchangePost then
		unregPost(self.exchangePost)
	end
	timerMgr:RemoveTimer(NAME) 
	local scene = uiMgr:GetCurrentScene()
	scene:RemoveGameLayer(self:GetViewComponent())
end

return ActivityExchangeLargeMediator

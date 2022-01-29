--[[
活动弹出页 新手单笔充值 mediator    
--]]
local Mediator = mvc.Mediator
local ActivitySinglePayPopupMediator = class("ActivitySinglePayPopupMediator", Mediator)
local NAME = "ActivitySinglePayPopupMediator"
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local timerMgr = AppFacade.GetInstance():GetManager("TimerManager")
local ActivityPermanentSinglePayCell = require('Game.views.activity.singlePay.ActivityPermanentSinglePayCell')
--[[
@params {
    timeStr str 剩余时间
}
--]]
function ActivitySinglePayPopupMediator:ctor( params, viewComponent )
    self.super:ctor(NAME, viewComponent)
    local data = params or {}
    self.activityData = {} -- 活动数据
	self.leftSeconds = nil -- 剩余时间
	self.defaultArea = 'USD' -- 默认货币地区
	self.defaultCurrencySymbol = '$' -- 默认货币符号
	if isFuntoySdk() or isQuickSdk() then
		self.defaultArea = 'CNY'
		self.defaultCurrencySymbol = '￥'
	end
end

function ActivitySinglePayPopupMediator:InterestSignals()
	local signals = {
        POST.ACTIVITY_PERMANENT_SINGLE_PAY_HOME.sglName,
		POST.ACTIVITY_PERMANENT_SINGLE_PAY_DRAW.sglName,
		EVENT_PAY_MONEY_SUCCESS,
		EVENT_APP_STORE_PRODUCTS,
	}
	return signals
end

function ActivitySinglePayPopupMediator:ProcessSignal( signal )
    local name = signal:GetName()
	local body = signal:GetBody()
	if name == POST.ACTIVITY_PERMANENT_SINGLE_PAY_DRAW.sglName then
		if body.requestData.name == NAME then 
			uiMgr:AddDialog('common.RewardPopup', {rewards = body.rewards})
		end
		-- 更新本地数据
		for i, v in ipairs(self.activityData) do
			if checkint(v.currencyId) == checkint(body.requestData.currencyId) then
				v.receivedTimes = checkint(v.receivedTimes) + 1
				break
			end
		end
		self:UpdatePropList()
	elseif name == POST.ACTIVITY_PERMANENT_SINGLE_PAY_HOME.sglName then
		self.activityData = self:InitPermanentActivityData(body.stage)
		self:UpdatePropExchangeList()
		-- 更新剩余时间
		if timerMgr:RetriveTimer('ACTIVITY_SINGLE_PAY_POPUP') then
			timerMgr:RemoveTimer('ACTIVITY_SINGLE_PAY_POPUP')
		end
		timerMgr:AddTimer({name = 'ACTIVITY_SINGLE_PAY_POPUP', countdown = checkint(body.remainTime) + 2, callback = function ( countdown )
			if countdown > 0 then
				self:UpdateLeftSeconds(countdown)
			else
				AppFacade.GetInstance():UnRegsitMediator("ActivitySinglePayPopupMediator")
			end
		end})
		self:UpdateLeftSeconds(body.remainTime)
	elseif name == EVENT_PAY_MONEY_SUCCESS then
		self:EnterLayer()
	elseif name == EVENT_APP_STORE_PRODUCTS then -- 获取当前所用货币类型
        if isElexSdk() then
			self:UpdatePropExchangeList()
		end
	end
end

function ActivitySinglePayPopupMediator:Initial( key )
    self.super.Initial(self, key)
	local viewComponent  = require('Game.views.activity.popup.ActivitySinglePayPopupView').new()
    viewComponent:setPosition(cc.p(display.cx, display.cy))
    app.uiMgr:GetCurrentScene():AddDialog(viewComponent)
    self:SetViewComponent(viewComponent)
    local viewData = viewComponent:GetViewData()
    viewData.backBtn:setOnClickScriptHandler(handler(self, self.BackButtonCallback))
    viewData.gridView:setDataSourceAdapterScriptHandler(handler(self, self.PermanentSinglePayDataSource))
	viewData.timeLabel:setString(self.timeStr)
	self.activityData = self:InitPermanentActivityData(self.activityData)
    if isElexSdk() then
		local channelProducts = gameMgr:GetUserInfo().channelProducts
		if channelProducts then
			require('root.AppSDK').GetInstance():QueryProducts({channelProducts[1].channelProductId})
			self:UpdatePropExchangeList()
		end
	else
		self:UpdatePropExchangeList()
	end
end

---------------------------------------------
----------------- method --------------------
--[[
常驻单笔充值列表处理
--]]
function ActivitySinglePayPopupMediator:PermanentSinglePayDataSource(p_convertview, idx)
    local pCell = p_convertview
    local index = idx + 1
    if pCell == nil then
        local gridViewCellSize = self:GetViewComponent():GetViewData().gridViewCellSize
		pCell = ActivityPermanentSinglePayCell.new({size = gridViewCellSize})
		display.commonUIParams(pCell.drawBtn, {cb = handler(self, self.PermanentDrawButtonCallback)})
    end
	xTry(function()
        local data = self.activityData[index]
		local targetAmount  = checkint(data.targetAmount)  -- 目标金额
		local currencyId    = checkint(data.currencyId)    -- 目标金额货币id
		local receivedTimes = checkint(data.receivedTimes) -- 已经领取奖励次数
		local completeTimes = checkint(data.completeTimes) -- 完成充值目标次数
		local totalTimes    = checkint(data.totalTimes)    -- 总领取次数上限
		local pictureId     = data.pictureId 	 	 	   -- 图片Id

		local currencyConf = CommonUtils.GetConfigAllMess('currency', 'activity')
		local descrStr = nil
        if isElexSdk() then
			local channelProducts = gameMgr:GetUserInfo().channelProducts
			local sdkInstance = require("root.AppSDK").GetInstance()
            local localized = 0
			if sdkInstance.loadedProducts and next(sdkInstance.loadedProducts) ~= nil then
                if #channelProducts > 0 then
                    if sdkInstance.loadedProducts[tostring(channelProducts[1].channelProductId)] and sdkInstance.loadedProducts[tostring(channelProducts[1].channelProductId)].priceLocale then
                        localized = 1
                    end
                end
            end
            if localized == 1 then
				local currencySymbol = string.gsub(sdkInstance.loadedProducts[tostring(channelProducts[1].channelProductId)].priceLocale, "%d+(.-)%d*$", ' ')
				descrStr = string.fmt(__('仅充值_num_档位可领取'),{['_num_'] = currencySymbol .. currencyConf[tostring(currencyId)][cc.UserDefault:getInstance():getStringForKey('EATER_ELEX_CURRENCY_CODE')]})
			else
				descrStr = string.fmt(__('仅充值_num_档位可领取'),{['_num_'] = self.defaultCurrencySymbol .. currencyConf[tostring(currencyId)][self.defaultArea]})
			end
		else
			descrStr = string.fmt(__('仅充值_num_档位可领取'),{['_num_'] = self.defaultCurrencySymbol .. currencyConf[tostring(currencyId)][self.defaultArea]})
		end
		pCell.descrLabel:setString(descrStr)
		local timeStr = string.fmt('_num1_/_num2_', {['_num1_'] = receivedTimes, ['_num2_'] = totalTimes})
		pCell.timeLabel:setString(timeStr)
		pCell.drawLabel:setPositionX(pCell.bgSize.width - 30 - display.getLabelContentSize(pCell.timeLabel).width)
		pCell.bg:setTexture(_res(string.format('ui/home/activity/permanmentSinglePay/%s.png', pictureId)))
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
			uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = sender.goodId, type = 1})
		end
		for i,reward in ipairs(data.rewards or {}) do
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
function ActivitySinglePayPopupMediator:PermanentDrawButtonCallback(sender)
	PlayAudioByClickNormal()
	local tag = sender:getTag()
	local data = self.activityData[tag]
	if checkint(data.completeTimes) > checkint(data.receivedTimes) then
		self:SendSignal(POST.ACTIVITY_PERMANENT_SINGLE_PAY_DRAW.cmdName, {currencyId = data.currencyId, name = NAME})
	else
		uiMgr:ShowInformationTips(__('未满足领取条件'))
	end
end
--[[
初始化常驻单笔充值活动数据
--]]
function ActivitySinglePayPopupMediator:InitPermanentActivityData( data )
	local singlePayConf = CommonUtils.GetConfigAllMess('singlePay', 'activity')
	local permanentActivityData = {}
	for i,v in ipairs(data) do
		local singlePayData = singlePayConf[tostring(v.currencyId)]
		local temp = {
			currencyId = checkint(v.currencyId),
			rewards = singlePayData.rewards,
			completeTimes = checkint(v.completeTimes),
			receivedTimes = checkint(v.receivedTimes),
			totalTimes = singlePayData.maxTimes,
			pictureId  = singlePayData.pictureId
		}
		table.insert(permanentActivityData, temp)
	end
	return permanentActivityData
end
function ActivitySinglePayPopupMediator:UpdatePropExchangeList()
    local gridView = self:GetViewComponent():GetViewData().gridView
	gridView:setCountOfCell(#self.activityData)
	gridView:reloadData()
	self:RefreshRemindIcon()
 end
--[[
领取按钮点击回调
--]]
function ActivitySinglePayPopupMediator:DrawButtonCallback(sender)
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

function ActivitySinglePayPopupMediator:UpdatePropList(index)
	local gridView = self:GetViewComponent():GetViewData().gridView
	local offset = gridView:getContentOffset()
	gridView:setCountOfCell(#self.activityData)
	gridView:reloadData()
	gridView:setContentOffset(offset)
	self:RefreshRemindIcon()
end
--[[
更新活动页面小红点
--]]
function ActivitySinglePayPopupMediator:RefreshRemindIcon()
	local showRemindIcon = false
	for i, v in ipairs(self.activityData) do
		if checkint(v.totalTimes) > checkint(v.receivedTimes) and checkint(v.completeTimes) > checkint(v.receivedTimes) then
			showRemindIcon = true
			break
		end
	end
	-- local activityMediator = self:GetFacade():RetrieveMediator('ActivityMediator')
	-- if activityMediator then
	-- 	if showRemindIcon then
	-- 		activityMediator:AddRemindIcon(self.activityId)
	-- 		gameMgr:GetUserInfo().tips.permanentSinglePay = 1
    --     else
	-- 		activityMediator:ClearRemindIcon(self.activityId)
	-- 		gameMgr:GetUserInfo().tips.permanentSinglePay = 0
	-- 	end
	-- end
end
--[[
更新剩余时间
--]]
function ActivitySinglePayPopupMediator:UpdateLeftSeconds( leftSeconds )
	local viewData = self:GetViewComponent():GetViewData()
	viewData.timeLabel:setString(CommonUtils.getTimeFormatByType(leftSeconds))
end
----------------- method --------------------
---------------------------------------------

---------------------------------------------
---------------- callback -------------------
--[[
返回按钮回调
--]]
function ActivitySinglePayPopupMediator:BackButtonCallback( sender )
    PlayAudioByClickClose()
    AppFacade.GetInstance():UnRegsitMediator("ActivitySinglePayPopupMediator")
end
---------------- callback -------------------
---------------------------------------------
function ActivitySinglePayPopupMediator:EnterLayer()
	self:SendSignal(POST.ACTIVITY_PERMANENT_SINGLE_PAY_HOME.cmdName)
end
function ActivitySinglePayPopupMediator:OnRegist()
	regPost(POST.ACTIVITY_PERMANENT_SINGLE_PAY_HOME)
    regPost(POST.ACTIVITY_PERMANENT_SINGLE_PAY_DRAW)
    self:EnterLayer()
end
function ActivitySinglePayPopupMediator:OnUnRegist()
    app.uiMgr:GetCurrentScene():RemoveDialog(self:GetViewComponent())
	unregPost(POST.ACTIVITY_PERMANENT_SINGLE_PAY_HOME)
	unregPost(POST.ACTIVITY_PERMANENT_SINGLE_PAY_DRAW)
	timerMgr:RemoveTimer('ACTIVITY_SINGLE_PAY_POPUP')
end
return ActivitySinglePayPopupMediator
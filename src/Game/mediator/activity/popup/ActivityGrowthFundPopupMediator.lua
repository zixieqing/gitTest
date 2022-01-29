--[[
活动弹出页 成长基金 mediator    
--]]
local Mediator = mvc.Mediator
local ActivityGrowthFundPopupMediator = class("ActivityGrowthFundPopupMediator", Mediator)
local NAME = "ActivityGrowthFundPopupMediator"
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager('GameManager')

function ActivityGrowthFundPopupMediator:ctor( params, viewComponent )
    self.super:ctor(NAME, viewComponent)
    self.activityData = {}
end

function ActivityGrowthFundPopupMediator:InterestSignals()
	local signals = {
		POST.ACTIVITY_PAY_LEVEL_REWARD.sglName,
		POST.ACTIVITY_DRAW_PAY_LEVEL_REWARD.sglName,

		SGL.Restaurant_Shop_GetPayOrder_Callback,	-- 创建支付订单信号
		EVENT_PAY_MONEY_SUCCESS_UI,
	}
	return signals
end

function ActivityGrowthFundPopupMediator:ProcessSignal( signal )
	local name = signal:GetName()
	print(name)
	local body = checktable(signal:GetBody())
	if name == POST.ACTIVITY_PAY_LEVEL_REWARD.sglName then
		app.badgeMgr:initGrowthFundCacheData(body)
		self.activityData = body
		self:GetViewComponent():refreshUI(body)

	elseif name == POST.ACTIVITY_DRAW_PAY_LEVEL_REWARD.sglName then

		local rewards     = body.rewards or {}
        if next(rewards) ~= nil then
            uiMgr:AddDialog('common.RewardPopup', {rewards = rewards})
		end
		
		local requestData      = body.requestData or {}
		local payLevelRewardId = requestData.payLevelRewardId
		local dataIndex        = requestData.dataIndex
		local payLevelRewards = checktable(self.activityData).payLevelRewards or {}
		local data = payLevelRewards[dataIndex] or {}
		data.hasDrawn = 1

		local tableView = self:GetViewData().tableView
		local cell = tableView:cellAtIndex(dataIndex - 1)
		if cell then
			self:GetViewComponent():updateDrawState(cell.viewData, data, self.activityData.isPayLevelRewardsOpen)
		end
	elseif name == SGL.Restaurant_Shop_GetPayOrder_Callback then
		 -- body不存在  或  请求名称不相同
		 if not body or body.requestData.name ~= NAME then return end

		 if body.orderNo then
			 if device.platform == 'android' or device.platform == 'ios' then
				 local AppSDK = require('root.AppSDK')
				 AppSDK.GetInstance():InvokePay({amount = tonumber(self.activityData.price), property = body.orderNo, goodsId = tostring(self.activityData.channelProductId),
					 goodsName = __('幻晶石'), quantifier = __('个'),price = 0.1, count = 1})
			 end
		 end
	elseif name == EVENT_PAY_MONEY_SUCCESS_UI then
		if checkint(body.type) == PAY_TYPE.PT_GROWTH_FUND then
            self:enterLayer()
        end
	end
end

function ActivityGrowthFundPopupMediator:Initial( key )
    self.super.Initial(self, key)
	local viewComponent = require( 'Game.views.activity.popup.ActivityGrowthFundPopupView' ).new()
	display.commonUIParams(viewComponent, {ap = display.CENTER, po = display.center})
	app.uiMgr:GetCurrentScene():AddDialog(viewComponent)
	self:SetViewComponent(viewComponent)
	
	self.viewData = viewComponent:GetViewData()
    self:initView()
end

function ActivityGrowthFundPopupMediator:initView()
	print("init")
	local viewData = self:GetViewData()
	local tableView = viewData.tableView
	tableView:setDataSourceAdapterScriptHandler(handler(self, self.onDataSourceAdapter))

	local tipsBtn     = viewData.tipsBtn
	display.commonUIParams(tipsBtn, {cb = handler(self, self.onClickTipsBtnAction)})
	
	local rechangeBtn = viewData.rechangeBtn
	display.commonUIParams(rechangeBtn, {cb = handler(self, self.onClickRechangeBtnAction)})

	local backBtn     = viewData.backBtn
	display.commonUIParams(backBtn, {cb = handler(self, self.onClickBackBtnAction)})
end

--[[
刷新活动页面
--]]
function ActivityGrowthFundPopupMediator:refreshView()

end


function ActivityGrowthFundPopupMediator:enterLayer()
	self:SendSignal(POST.ACTIVITY_PAY_LEVEL_REWARD.cmdName)
end

function ActivityGrowthFundPopupMediator:onDataSourceAdapter(p_convertview, idx)
	local pCell = p_convertview
    local index = idx + 1

	local viewComponent = self:GetViewComponent()

	if pCell == nil then
		local tableView = self:GetViewData().tableView
		pCell = viewComponent:CreateCell(tableView:getSizeOfCell())

		-- display.comm
		pCell.viewData.drawBtn:SetCallback(handler(self, self.onClickDrawBtnAction))
	end

	local payLevelRewards = checktable(self.activityData).payLevelRewards or {}
	local data = payLevelRewards[index]
	if data then
		viewComponent:updateCell(pCell.viewData, data, self.activityData.isPayLevelRewardsOpen)
		pCell.viewData.drawBtn:setTag(index)
	end
	return pCell
end

function ActivityGrowthFundPopupMediator:onClickTipsBtnAction(sender)
	uiMgr:ShowIntroPopup({moduleId = '85'})
end

function ActivityGrowthFundPopupMediator:onClickRechangeBtnAction(sender)
	local isPayLevelRewardsOpen = checkint(self.activityData.isPayLevelRewardsOpen)
	if isPayLevelRewardsOpen > 0 then
		uiMgr:ShowInformationTips(__('已购买成长基金'))
		return
	end

	self:SendSignal(COMMANDS.COMMANDS_All_Shop_GetPayOrder, {productId = self.activityData.productId, name = NAME})
end
function ActivityGrowthFundPopupMediator:onClickBackBtnAction(sender)
	PlayAudioByClickClose()
    AppFacade.GetInstance():UnRegsitMediator("ActivityGrowthFundPopupMediator")
end

function ActivityGrowthFundPopupMediator:onClickDrawBtnAction(sender)
	local index = sender:getTag()
	local drawState = sender:getUserTag()

	local payLevelRewards = checktable(self.activityData).payLevelRewards or {}
	local data = payLevelRewards[index] or {}
	if checkint(self.activityData.isPayLevelRewardsOpen) <= 0 then
		uiMgr:ShowInformationTips(__('请先购买成长基金'))
		return
	end

	if drawState == 3 then
		uiMgr:ShowInformationTips(__('已领取'))
		return
	elseif drawState == 1 then
		uiMgr:ShowInformationTips(__('未到达等级条件'))
		return
	end

	self:SendSignal(POST.ACTIVITY_DRAW_PAY_LEVEL_REWARD.cmdName, {payLevelRewardId = data.payLevelRewardId, dataIndex = index})
	
end

function ActivityGrowthFundPopupMediator:GetViewData()
	return self.viewData
end

function ActivityGrowthFundPopupMediator:cleanupView()
	local viewComponent = self:GetViewComponent()
	local scene = uiMgr:GetCurrentScene()
    if scene and viewComponent and not tolua.isnull(viewComponent) then
		scene:RemoveGameLayer(viewComponent)
    end
end
function ActivityGrowthFundPopupMediator:OnRegist(  )
	regPost(POST.ACTIVITY_PAY_LEVEL_REWARD)
	regPost(POST.ACTIVITY_DRAW_PAY_LEVEL_REWARD)
	self:enterLayer()
end

function ActivityGrowthFundPopupMediator:OnUnRegist(  )
	unregPost(POST.ACTIVITY_PAY_LEVEL_REWARD)
	unregPost(POST.ACTIVITY_DRAW_PAY_LEVEL_REWARD)

	self:cleanupView()
end
return ActivityGrowthFundPopupMediator
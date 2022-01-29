--[[
新等级奖励mediator
--]]
local Mediator = mvc.Mediator
local ActivityNewLevelRewardMediator = class("ActivityNewLevelRewardMediator", Mediator)
local NAME = "activity.levelReward.ActivityNewLevelRewardMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager('GameManager')
local scheduler = require('cocos.framework.scheduler')

function ActivityNewLevelRewardMediator:ctor( params, viewComponent )
	self.super:ctor(NAME, viewComponent)
	local datas = params or {}
	self.activityId = checkint(datas.activityId) -- 活动Id
	self.activityData = {} -- 活动home数据
	self.isControllable_ = true
	self.canReceiveCount = 0
	
end


function ActivityNewLevelRewardMediator:InterestSignals()
	local signals = {
		POST.ACTIVITY_NEW_LEVEL_REWARD.sglName,
		POST.ACTIVITY_DRAW_NEW_LEVEL_REWARD.sglName,
		SIGNALNAMES.Restaurant_Shop_GetPayOrder_Callback,
		EVENT_PAY_MONEY_SUCCESS_UI
	}
	return signals
end

function ActivityNewLevelRewardMediator:ProcessSignal( signal )
	local name = signal:GetName()
	local body = checktable(signal:GetBody())
	if name == POST.ACTIVITY_NEW_LEVEL_REWARD.sglName then
		local levelRewards = body.levelRewards or {}

		self.activityData = levelRewards

		self.canReceiveCount = 0
		local lv = gameMgr:GetUserInfo().level
		for i, v in ipairs(self.activityData) do
			if checkint(v.hasDrawn) == 0 and lv >= checkint(v.target) then
				self.canReceiveCount = self.canReceiveCount + 1
			end
		end
		gameMgr:GetUserInfo().tips.levelReward = self.canReceiveCount
		self:clearExternalRedPoint()

		self:GetViewComponent():refreshUI(self.activityData)
	elseif name == POST.ACTIVITY_DRAW_NEW_LEVEL_REWARD.sglName then

		uiMgr:AddDialog('common.RewardPopup', {rewards = body.rewards or {}})
		self:SendSignal(POST.ACTIVITY_NEW_LEVEL_REWARD.cmdName)
	elseif name == SIGNALNAMES.Restaurant_Shop_GetPayOrder_Callback then
		if body.requestData.name ~= 'newLevelReward' then return end
		if body.orderNo then
			if device.platform == 'android' or device.platform == 'ios' then
				local AppSDK = require('root.AppSDK')
				local price =  checkint( self.curLevelData.price)
				AppSDK.GetInstance():InvokePay({amount =  price  , property = body.orderNo, goodsId = tostring(self.curLevelData.channelProductId), goodsName = __('幻晶石'), quantifier = __('个'),price = 0.1, count = 1})
			end
		end
	elseif name == EVENT_PAY_MONEY_SUCCESS_UI then
		if checkint(body.type) == PAY_TYPE.PT_NEW_LEVEL_REWARD then
			self:SendSignal(POST.ACTIVITY_NEW_LEVEL_REWARD.cmdName)
		end
	end
end

function ActivityNewLevelRewardMediator:Initial( key )
    self.super.Initial(self, key)
    
	local viewComponent = require( 'Game.views.activity.levelReward.ActivityNewLevelRewardView' ).new()
	display.commonUIParams(viewComponent, {ap = display.CENTER, po = display.center})
	self:SetViewComponent(viewComponent)
	self.viewData = viewComponent:getViewData()
	-- 创建定时器
	self.refreshClocker = app.timerMgr.CreateClocker(handler(self, self.RefershClockerUpdate))
	self.timeStamp = os.time()
	self.refreshClocker:start()
    self:initView()

end

function ActivityNewLevelRewardMediator:initView()
	local viewData = self:getViewData()
	local tableView = viewData.tableView
	tableView:setDataSourceAdapterScriptHandler(handler(self, self.onDataSourceAdapter))
end

function ActivityNewLevelRewardMediator:enterLayer()
	self:SendSignal(POST.ACTIVITY_NEW_LEVEL_REWARD.cmdName)
end

function ActivityNewLevelRewardMediator:onDataSourceAdapter(p_convertview, idx)
	local pCell = p_convertview
    local index = idx + 1

	if pCell == nil then
		local tableView = self:getViewData().tableView
		pCell = self:GetViewComponent():CreateCell(tableView:getSizeOfCell())
		display.commonUIParams(pCell.viewData.drawBtn, {cb = handler(self, self.onDrawBtnAction)})
	end
	local data = self.activityData[index]
	if data then
		self:GetViewComponent():updateCell(pCell.viewData, data)
	end
	pCell.viewData.drawBtn:setTag(index)
	return pCell
end

function ActivityNewLevelRewardMediator:onDrawBtnAction(sender)
	local index = sender:getTag()
	local data = self.activityData[index]
	if data == nil then return end
	PlayAudioByClickNormal()
	local isSatisfy = app.gameMgr:GetUserInfo().level >= checkint(data.target)
	if not isSatisfy then
		uiMgr:ShowInformationTips(__('等级未达到'))
		return
	end
	if checkint(data.hasDrawn) <= 0 then
		self:SendSignal(POST.ACTIVITY_DRAW_NEW_LEVEL_REWARD.cmdName, {levelRewardId = data.levelRewardId})
		return
	end
	if checkint(data.hasPurchased) <= 0 and checkint(data.productLeftSeconds) > 0 then
		self.curLevelData = data
		self:SendSignal(COMMANDS.COMMANDS_All_Shop_GetPayOrder,{productId = data.productId , name = 'newLevelReward'})
		return
	end
	uiMgr:ShowInformationTips(__('已结束'))
end

--[[
定时器回调
--]]
function ActivityNewLevelRewardMediator:RefershClockerUpdate()
	local curTime = os.time()
	local deltaTime = math.abs(curTime - self.timeStamp)
	self.timeStamp = curTime

	local viewData = self:getViewData()
	local tableView = viewData.tableView
	
	for i, v in ipairs(self.activityData) do
		if (v.productLeftSeconds) > 0 then
			v.productLeftSeconds = math.max(0, v.productLeftSeconds - deltaTime)
			-- 更新cell
			local cell = tableView:cellAtIndex(i - 1)
			if cell then
				self:GetViewComponent():updateDrawState(cell.viewData, v)
			end
		end 
	end
end

function ActivityNewLevelRewardMediator:clearExternalRedPoint()
	if self.canReceiveCount <= 0 then
		local activityM = self:GetFacade():RetrieveMediator('ActivityMediator')
		if activityM then
			activityM:ClearRemindIcon(ACTIVITY_ID.LEVEL_REWARD)
		end
	end
end

function ActivityNewLevelRewardMediator:getViewData()
	return self.viewData
end

function ActivityNewLevelRewardMediator:CleanupView()
	local viewComponent = self:GetViewComponent()
	local scene = uiMgr:GetCurrentScene()
	self.refreshClocker:stop()
    if scene and viewComponent and not tolua.isnull(viewComponent) then
		scene:RemoveGameLayer(viewComponent)
		scene:RemoveViewForNoTouch()
    end
end

function ActivityNewLevelRewardMediator:OnRegist(  )
	regPost(POST.ACTIVITY_NEW_LEVEL_REWARD)
	regPost(POST.ACTIVITY_DRAW_NEW_LEVEL_REWARD)
	self:enterLayer()
end

function ActivityNewLevelRewardMediator:OnUnRegist(  )
	unregPost(POST.ACTIVITY_NEW_LEVEL_REWARD)
	unregPost(POST.ACTIVITY_DRAW_NEW_LEVEL_REWARD)
end


return ActivityNewLevelRewardMediator
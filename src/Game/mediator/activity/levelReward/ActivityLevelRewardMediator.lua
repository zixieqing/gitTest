--[[
等级奖励mediator
--]]
local Mediator = mvc.Mediator
local ActivityLevelRewardMediator = class("ActivityLevelRewardMediator", Mediator)
local NAME = "activity.levelReward.ActivityLevelRewardMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager('GameManager')
local scheduler = require('cocos.framework.scheduler')

function ActivityLevelRewardMediator:ctor( params, viewComponent )
	self.super:ctor(NAME, viewComponent)
	local datas = params or {}
	self.activityId = checkint(datas.activityId) -- 活动Id
	self.activityData = {} -- 活动home数据
	self.isControllable_ = true
	self.canReceiveCount = 0
end


function ActivityLevelRewardMediator:InterestSignals()
	local signals = {
		POST.ACTIVITY_LEVEL_REWARD.sglName,
		POST.ACTIVITY_DRAW_LEVEL_REWARD.sglName,
	}
	return signals
end

function ActivityLevelRewardMediator:ProcessSignal( signal )
	local name = signal:GetName()
	local body = checktable(signal:GetBody())
	if name == POST.ACTIVITY_LEVEL_REWARD.sglName then
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
	elseif name == POST.ACTIVITY_DRAW_LEVEL_REWARD.sglName then

		uiMgr:AddDialog('common.RewardPopup', {rewards = body.rewards or {}})

		local requestData = body.requestData or {}
		local levelRewardId = requestData.levelRewardId
		for i, v in ipairs(self.activityData or {}) do
			if v.levelRewardId == levelRewardId then
				self.activityData[i].hasDrawn = 1
				local viewData = self:getViewData()
				local tableView = viewData.tableView
				local cell = tableView:cellAtIndex(i - 1)
				if cell then
					self:GetViewComponent():updateDrawState(cell.viewData, v)
				end
				break
			end
		end

		self.canReceiveCount = self.canReceiveCount - 1
		gameMgr:GetUserInfo().tips.levelReward = self.canReceiveCount
		self:clearExternalRedPoint()
	end
end

function ActivityLevelRewardMediator:Initial( key )
    self.super.Initial(self, key)
    
	local viewComponent = require( 'Game.views.activity.levelReward.ActivityLevelRewardView' ).new()
	display.commonUIParams(viewComponent, {ap = display.CENTER, po = display.center})
	self:SetViewComponent(viewComponent)
	
	self.viewData = viewComponent:getViewData()
    self:initView()

end

function ActivityLevelRewardMediator:initView()
	local viewData = self:getViewData()
	local tableView = viewData.tableView
	tableView:setDataSourceAdapterScriptHandler(handler(self, self.onDataSourceAdapter))
end

function ActivityLevelRewardMediator:enterLayer()
	self:SendSignal(POST.ACTIVITY_LEVEL_REWARD.cmdName)
end

function ActivityLevelRewardMediator:onDataSourceAdapter(p_convertview, idx)
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

function ActivityLevelRewardMediator:onDrawBtnAction(sender)
	local index = sender:getTag()
	local data = self.activityData[index]
	if data == nil then return end

	local hasDrawn = checkint(data.hasDrawn) > 0
	if hasDrawn then
		uiMgr:ShowInformationTips(__('已领取'))
		return
	end

	local isSatisfy = app.gameMgr:GetUserInfo().level >= checkint(data.target)
	if not isSatisfy then
		uiMgr:ShowInformationTips(__('等级未达到'))
		return
	end

	self:SendSignal(POST.ACTIVITY_DRAW_LEVEL_REWARD.cmdName, {levelRewardId = data.levelRewardId})
end

function ActivityLevelRewardMediator:clearExternalRedPoint()
	if self.canReceiveCount <= 0 then
		local activityM = self:GetFacade():RetrieveMediator('ActivityMediator')
		if activityM then
			activityM:ClearRemindIcon(ACTIVITY_ID.LEVEL_REWARD)
		end
	end
end

function ActivityLevelRewardMediator:getViewData()
	return self.viewData
end

function ActivityLevelRewardMediator:CleanupView()
	local viewComponent = self:GetViewComponent()
	local scene = uiMgr:GetCurrentScene()
    if scene and viewComponent and not tolua.isnull(viewComponent) then
		scene:RemoveGameLayer(viewComponent)
		scene:RemoveViewForNoTouch()
    end
end

function ActivityLevelRewardMediator:OnRegist(  )
	regPost(POST.ACTIVITY_LEVEL_REWARD)
	regPost(POST.ACTIVITY_DRAW_LEVEL_REWARD)
	self:enterLayer()
end

function ActivityLevelRewardMediator:OnUnRegist(  )
	unregPost(POST.ACTIVITY_LEVEL_REWARD)
	unregPost(POST.ACTIVITY_DRAW_LEVEL_REWARD)
end


return ActivityLevelRewardMediator
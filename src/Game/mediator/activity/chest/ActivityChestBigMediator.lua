--[[
奖励mediator
--]]
local Mediator = mvc.Mediator
---@class ActivityChestBigMediator :Mediator
local ActivityChestBigMediator = class("ActivityChestBigMediator", Mediator)
local NAME = "Game.mediator.activity.chest.ActivityChestBigMediator"
ActivityChestBigMediator.NAME = NAME
local BIG_CHEST_STATUS = {
	NOT_DRAW     = 1, -- 不可以领取
	CAN_DRAW     = 2, -- 可以领取
	ALREADY_DRAW = 3, -- 已经可以领取
}

function ActivityChestBigMediator:ctor(params, viewComponent)
	self.super.ctor(self, NAME, viewComponent)
	self.finalRewardsProgress = params.finalRewardsProgress
	self.finalRewardsTarget   = params.finalRewardsTarget
	self.finalRewards         = params.finalRewards
	self.activityId           = params.activityId
	self.chestName           = params.chestName
	self.bigChestStatus       = BIG_CHEST_STATUS.NOT_DRAW
	if params.finalRewardsHasDrawn == 1 then
		self.bigChestStatus       = BIG_CHEST_STATUS.ALREADY_DRAW
	elseif self.finalRewardsProgress >= self.finalRewardsTarget then
		self.bigChestStatus = BIG_CHEST_STATUS.CAN_DRAW
	end
end
function ActivityChestBigMediator:InterestSignals()
	return {
		POST.ACTIVITY2_CR_BOX_DRAW_FINAL_REWARDS.sglName
	}
end
function ActivityChestBigMediator:ProcessSignal(signal)
	local name = signal:GetName()
	if name == POST.ACTIVITY2_CR_BOX_DRAW_FINAL_REWARDS.sglName then
		local body = signal:GetBody()
		local rewards = body.rewards
		self.bigChestStatus = BIG_CHEST_STATUS.ALREADY_DRAW
		local viewComponent = self:GetViewComponent()
		viewComponent:UpdateBigButtonStatus(self.bigChestStatus)
		viewComponent:runAction(
			cc.Sequence:create(
				cc.CallFunc:create(function()
					viewComponent:RunRewardsAnimate()
				end),
				cc.DelayTime:create(1),
				cc.CallFunc:create(function()
					app.uiMgr:AddDialog("common.RewardPopup" , { rewards = rewards})
				end)
			)
		)
	end
end
-- inheritance method
function ActivityChestBigMediator:Initial(key)
	self.super.Initial(self, key)
	---@type ActivityChestBigView
	local viewComponent =  require("Game.views.activity.chest.ActivityChestBigView").new()
	viewComponent:setPosition(display.center)
	app.uiMgr:GetCurrentScene():AddDialog(viewComponent)
	self:SetViewComponent(viewComponent)
	local viewData = viewComponent.viewData
	display.commonUIParams(viewData.closeLayer , {cb = handler(self, self.CloseClick) , animate = false})
	display.commonUIParams(viewData.rewardBtn , {cb = handler(self, self.DrawFinalRewardsClick) , animate = false})
	viewComponent:UpdateBigButtonStatus(self.bigChestStatus)
	viewComponent:CreateMustGoodsData(self.finalRewards)
	viewComponent:UpdateChestName(self.chestName)
end

function ActivityChestBigMediator:DrawFinalRewardsClick(sender)
	if self.bigChestStatus == BIG_CHEST_STATUS.NOT_DRAW then
		app.uiMgr:ShowInformationTips(__('宝箱不可以领取'))
		return
	end
	if self.bigChestStatus == BIG_CHEST_STATUS.ALREADY_DRAW then
		app.uiMgr:ShowInformationTips(__('已经领取'))
		return
	end
	self:SendSignal(POST.ACTIVITY2_CR_BOX_DRAW_FINAL_REWARDS.cmdName , {activityId = self.activityId })
end

function ActivityChestBigMediator:CloseClick()
	self:GetFacade():UnRegistMediator(NAME)
end


function ActivityChestBigMediator:OnRegist()
	regPost(POST.ACTIVITY2_CR_BOX_DRAW_FINAL_REWARDS)
end

function ActivityChestBigMediator:OnUnRegist()
	unregPost(POST.ACTIVITY2_CR_BOX_DRAW_FINAL_REWARDS)
	local viewComponent = self:GetViewComponent()
	if viewComponent and (not tolua.isnull(viewComponent)) then
		viewComponent:runAction(cc.RemoveSelf:create())
	end
end

return ActivityChestBigMediator

--[[
 * author : kaishiqi
 * descpt : 2020周年庆 - 挂机游戏 中介者
]]
local Anniversary20ExploreTotalRewardsView     = require('Game.views.anniversary20.Anniversary20ExploreTotalRewardsView')
---@class Anniversary20ExploreTotalRewardsMediator :Mediator
local Anniversary20ExploreTotalRewardsMediator = class('Anniversary20ExploreTotalRewardsMediator', mvc.Mediator)
local NAME = 'Anniversary20ExploreTotalRewardsMediator'
function Anniversary20ExploreTotalRewardsMediator:ctor(params, viewComponent)
	self.super.ctor(self,NAME , viewComponent)
end


-------------------------------------------------
-- inheritance

function Anniversary20ExploreTotalRewardsMediator:Initial(key)
	self.super.Initial(self, key)

	-- init vars
	self.isControllable_ = true
	local viewComponent = Anniversary20ExploreTotalRewardsView.new()
	-- create view
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	app.uiMgr:GetCurrentScene():AddDialog(viewComponent)

	local viewNode = self:getViewNode()
	viewNode:UpdateView()

	local viewData = self:getViewData()
	ui.bindClick(viewData.rewardBtn ,handler(self, self.onClickRewardButtonHandler_) )
	ui.bindClick(viewData.closeLayer ,handler(self, self.onClickCloseButtonHandler_) )

end

function Anniversary20ExploreTotalRewardsMediator:OnRegist()
	regPost(POST.ANNIV2020_EXPLORE_DRAW_FLOOR)
end


function Anniversary20ExploreTotalRewardsMediator:OnUnRegist()
	unregPost(POST.ANNIV2020_EXPLORE_DRAW_FLOOR)
	local viewNode = self:getViewNode()
	if viewNode and (not tolua.isnull(viewNode)) then
		self:SetViewComponent(nil)
		viewNode:runAction(cc.RemoveSelf:create())
	end
end


function Anniversary20ExploreTotalRewardsMediator:InterestSignals()
	return {
		POST.ANNIV2020_EXPLORE_DRAW_FLOOR.sglName
	}
end
function Anniversary20ExploreTotalRewardsMediator:ProcessSignal(signal)
	local name = signal:GetName()
	local data = signal:GetBody()
	if name == POST.ANNIV2020_EXPLORE_DRAW_FLOOR.sglName then
		local rewards = data.rewards
		app.anniv2020Mgr:resetExploreingRewards()
		app.uiMgr:AddDialog("common.RewardPopup" ,{ rewards = rewards  ,addBackpack =false , delayFuncList_ = {
			[1] = function()
				CommonUtils.DrawRewards(rewards)
				local currentFloor = app.anniv2020Mgr:getExploreingFloor()
				local num = currentFloor/10
				local exploreConf =  CONF.ANNIV2020.EXPLORE_ENTRANCE:GetValue(app.anniv2020Mgr:getExploringId())
				local storyId = exploreConf["story" .. num]
				app.anniv2020Mgr:checkPlayStory(storyId , function()
					---@type  Anniversary20ExploreHomeMediator
					local mediator = app:RetrieveMediator("Anniversary20ExploreHomeMediator")
					mediator:SendNextFloorEvent()
					self:GetFacade():UnRegistMediator(NAME)
				end)
			end
		}})
	end
end


-------------------------------------------------
-- get / set
---@return Anniversary20ExploreTotalRewardsView
function Anniversary20ExploreTotalRewardsMediator:getViewNode()
	return self:GetViewComponent()
end

function Anniversary20ExploreTotalRewardsMediator:getViewData()
	return self:getViewNode().viewData
end


-------------------------------------------------
-- private


-------------------------------------------------
-- handler

function Anniversary20ExploreTotalRewardsMediator:onClickCloseButtonHandler_(sender)
	PlayAudioByClickClose()
	if not self.isControllable_ then return end

	self:GetFacade():UnRegistMediator(NAME)
end


function Anniversary20ExploreTotalRewardsMediator:onClickRewardButtonHandler_(sender)
	PlayAudioByClickNormal()
	if not self.isControllable_ then return end
	local isRewards = false
 	local isBossFloor = app.anniv2020Mgr:isExploreingBossFloor()
	local isPassed =  app.anniv2020Mgr:isExploreingFloorPassed()
	if isBossFloor and isPassed then
		isRewards = isPassed
	end
	if not isRewards then
		app.uiMgr:ShowInformationTips(__('每通过10层梦境可领取一次奖励'))
		return
	end

	self:SendSignal(POST.ANNIV2020_EXPLORE_DRAW_FLOOR.cmdName , {})
end

return Anniversary20ExploreTotalRewardsMediator

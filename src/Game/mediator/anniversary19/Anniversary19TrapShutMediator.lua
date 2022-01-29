--[[
扭蛋系统mediator
--]]
local Mediator = mvc.Mediator
---@class Anniversary19TrapShutMediator :Mediator
local Anniversary19TrapShutMediator = class("Anniversary19TrapShutMediator", Mediator)
local NAME = "Anniversary19TrapShutMediator"
local BUTTON_TAG = {
	MAKE_SURE   = 1001, -- 确定
}
local gameMgr            = app.gameMgr
local anniversary2019Mgr = app.anniversary2019Mgr
---ctor
---@param viewComponent table
function Anniversary19TrapShutMediator:ctor(param ,  viewComponent )
	self.super:ctor(NAME,viewComponent)
	self.exploreId = param.exploreId  or  1
	self.exploreModuleId = param.exploreModuleId  or  1
	self.progress = anniversary2019Mgr:GetCurrentExploreProgress()
end
function Anniversary19TrapShutMediator:InterestSignals()
	local signals = {
		POST.ANNIVERSARY2_EXPLORE_SECTION_TRAP.sglName
	}

	return signals
end

function Anniversary19TrapShutMediator:ProcessSignal( signal )
	local data = signal:GetBody()
	local name = signal:GetName()
	if POST.ANNIVERSARY2_EXPLORE_SECTION_TRAP.sglName == name then
		self:GetFacade():DispatchObservers(ANNIVERSARY19_EXPLORE_RESULT_EVENT , { result = 1 })
		self:GetFacade():DispatchObservers("DREAM_CIRCLE_ONE_STEP_COMPLETE" , { } )
	end
end

function Anniversary19TrapShutMediator:Initial( key )
	self.super.Initial(self,key)
	---@type Anniversary19TrapShutView
	local viewComponent = require("Game.views.anniversary19.Anniversary19TrapShutView").new()
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	app.uiMgr:GetCurrentScene():AddGameLayer(viewComponent)
	viewComponent:UpdateUI(self.exploreModuleId  , self.exploreId  )
	viewComponent:AddDiffView(self.exploreModuleId)
	local viewData = viewComponent.viewData
	viewData.rightButton:setTag(BUTTON_TAG.MAKE_SURE)
	display.commonUIParams(viewData.rightButton , {cb = handler(self , self.ButtonAction)})
end

function Anniversary19TrapShutMediator:ButtonAction(sender)
	local tag = sender:getTag()
	local progress = anniversary2019Mgr:GetCurrentExploreProgress()
	if  not self.progress == progress then
		app.uiMgr:ShowInformationTips(app.anniversary2019Mgr:GetPoText(__('已通过该探索')))
		return
	end
	if tag ==  BUTTON_TAG.MAKE_SURE then
		self:SendSignal(POST.ANNIVERSARY2_EXPLORE_SECTION_TRAP.cmdName , { exploreModuleId = self.exploreModuleId })
	end
end

function Anniversary19TrapShutMediator:OnRegist()
	regPost(POST.ANNIVERSARY2_EXPLORE_SECTION_TRAP)
end
function Anniversary19TrapShutMediator:OnUnRegist()
	unregPost(POST.ANNIVERSARY2_EXPLORE_SECTION_TRAP)
	local viewComponent = self:GetViewComponent()
	if viewComponent and (not tolua.isnull(viewComponent)) then
		app.uiMgr:GetCurrentScene():RemoveDialog(viewComponent)
	end
end

return Anniversary19TrapShutMediator

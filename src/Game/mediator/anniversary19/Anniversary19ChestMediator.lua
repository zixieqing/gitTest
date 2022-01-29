--[[
扭蛋系统mediator
--]]
local Mediator = mvc.Mediator
---@class Anniversary19ChestMediator :Mediator
local Anniversary19ChestMediator = class("Anniversary19ChestMediator", Mediator)
local NAME = "Anniversary19ChestMediator"
local BUTTON_TAG = {
	OPEN_CHEST   = 1001, --打开宝箱
}
local gameMgr            = app.gameMgr
local anniversary2019Mgr = app.anniversary2019Mgr
---ctor
---@param viewComponent table
function Anniversary19ChestMediator:ctor(param ,  viewComponent )
	self.super:ctor(NAME,viewComponent)
	self.exploreId = param.exploreId  or  1
	self.exploreModuleId = param.exploreModuleId  or  1
end
function Anniversary19ChestMediator:InterestSignals()
	local signals = {
		POST.ANNIVERSARY2_EXPLORE_SECTION_CHEST.sglName
	}

	return signals
end

function Anniversary19ChestMediator:ProcessSignal( signal )
	local data = signal:GetBody()
	local name = signal:GetName()
	if name == POST.ANNIVERSARY2_EXPLORE_SECTION_CHEST.sglName then
		self:GetFacade():DispatchObservers(ANNIVERSARY19_EXPLORE_RESULT_EVENT , {result = 1 , isGiveup = false})
		self:GetFacade():DispatchObservers("DREAM_CIRCLE_ONE_STEP_COMPLETE" , { } )
	end
end
function Anniversary19ChestMediator:Initial( key )
	self.super.Initial(self, key)
	---@type Anniversary19ChestView
	local viewComponent = require("Game.views.anniversary19.Anniversary19ChestView").new()
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	app.uiMgr:GetCurrentScene():AddGameLayer(viewComponent)
	viewComponent:UpdateUI(self.exploreModuleId  , self.exploreId  )
	viewComponent:AddDiffView()

	local viewData = viewComponent.viewData
	viewData.rightButton:setTag(BUTTON_TAG.OPEN_CHEST)
	display.commonUIParams(viewData.rightButton , {cb = handler(self , self.ButtonAction)})
	viewData.chestSpine:registerSpineEventHandler(handler(self, self.SpineCallBack), sp.EventType.ANIMATION_COMPLETE)
end
function Anniversary19ChestMediator:SpineCallBack(event)
	if event.animation == 'play' then
		self:SendSignal(POST.ANNIVERSARY2_EXPLORE_SECTION_CHEST.cmdName , {exploreModuleId = self.exploreModuleId })
	end
end

function Anniversary19ChestMediator:ButtonAction(sender)
	PlayAudioClip(AUDIOS.UI.ui_chest_open.id)
	local tag = sender:getTag()
	if tag ==  BUTTON_TAG.OPEN_CHEST then
		local viewComponent = self:GetViewComponent()
		local viewData = viewComponent.viewData
		sender:setEnabled(false)
		viewData.chestSpine:setToSetupPose()
		viewData.chestSpine:setAnimation(0, 'play' , false)
	end
end


function Anniversary19ChestMediator:OnRegist()
	regPost(POST.ANNIVERSARY2_EXPLORE_SECTION_CHEST)
end
function Anniversary19ChestMediator:OnUnRegist()
	unregPost(POST.ANNIVERSARY2_EXPLORE_SECTION_CHEST)
	local viewComponent = self:GetViewComponent()
	if viewComponent and (not tolua.isnull(viewComponent)) then
		app.uiMgr:GetCurrentScene():RemoveDialog(viewComponent)
	end
end

return Anniversary19ChestMediator

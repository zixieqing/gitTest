--[[
扭蛋系统mediator
--]]
local Mediator                   = mvc.Mediator
---@class Anniversary20ChestMediator :Mediator
local Anniversary20ChestMediator = class("Anniversary20ChestMediator", Mediator)
local NAME                       = "Anniversary20ChestMediator"
local BUTTON_TAG = {
	CONTINUE   = 1001, --继续
	OPEN_CHEST   = 1002, --打开宝箱
}
---ctor
---@param param table @{ mapGridId : int }
---@param viewComponent table
function Anniversary20ChestMediator:ctor(param , viewComponent )
	self.super:ctor(NAME,viewComponent)
	self.mapGridId = param.mapGridId  or  1
	self.isClose = false
	self.isPassed = nil
	self.selectTag = nil
end
function Anniversary20ChestMediator:InterestSignals()
	local signals = {
		POST.ANNIV2020_EXPLORE_CHEST.sglName ,
		"ANNIVERSARY_2020_EXPLORE_STEP_CLOSE_EVENT" ,
	}

	return signals
end

function Anniversary20ChestMediator:ProcessSignal(signal )
	local data = signal:GetBody()
	local name = signal:GetName()
	if name == "ANNIVERSARY_2020_EXPLORE_STEP_CLOSE_EVENT" then
		self:CloseMeditor()
	elseif name == POST.ANNIV2020_EXPLORE_CHEST.sglName then
		self.isPassed = 1
		self:CloseMeditor()
	end
end
function Anniversary20ChestMediator:Initial(key )
	self.super.Initial(self, key)
	---@type Anniversary19ChestView
	local viewComponent = require("Game.views.anniversary20.Anniversary20ChestView").new()
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	app.uiMgr:GetCurrentScene():AddGameLayer(viewComponent)
	viewComponent:UpdateUI(self.mapGridId)
	viewComponent:AddDiffView()

	local viewData = viewComponent.viewData
	viewData.rightButton:setTag(BUTTON_TAG.OPEN_CHEST)
	display.commonUIParams(viewData.rightButton , {cb = handler(self , self.ButtonAction)})
	viewData.leftButton:setTag(BUTTON_TAG.CONTINUE)
	display.commonUIParams(viewData.leftButton , {cb = handler(self , self.ButtonAction)})
	viewData.chestSpine:registerSpineEventHandler(handler(self, self.SpineCallBack), sp.EventType.ANIMATION_COMPLETE)
end
function Anniversary20ChestMediator:SpineCallBack(event)
	if event.animation == 'play1' then

	end
end

function Anniversary20ChestMediator:ButtonAction(sender)
	PlayAudioClip(AUDIOS.UI.ui_chest_open.id)
	local tag = sender:getTag()
	if self.selectTag == tag then
		return
	end
	if tag ==  BUTTON_TAG.OPEN_CHEST then
		local viewComponent = self:GetViewComponent()
		local viewData = viewComponent.viewData
		sender:setEnabled(false)
		viewData.chestSpine:setToSetupPose()
		viewData.chestSpine:setAnimation(0, "play1" , false)
		viewComponent:SetOnlyLeftOneBtn()
		viewComponent:runAction(cc.Sequence:create(
			cc.DelayTime:create(1.2) ,
			cc.CallFunc:create(function()
				self:SendSignal(POST.ANNIV2020_EXPLORE_CHEST.cmdName , {gridId = self.mapGridId })
			end)
		))
		---@type Anniversary20ChestView
		local viewComponent = self:GetViewComponent()
		local viewData = viewComponent.viewData
		display.commonLabelParams(viewData.leftButton , fontWithColor(14, {text = __('继续')}))
	elseif tag == BUTTON_TAG.CONTINUE then
		if self.isPassed then
			self:CloseMeditor()
			self.selectTag = tag
		end
	end
end

function Anniversary20ChestMediator:CloseMeditor()
	if self.isPassed then
		self:GetFacade():UnRegistMediator(NAME)
		self:GetFacade():DispatchObservers(ANNIVERSARY20_EXPLORE_RESULT_EVENT, {
			mapGridId  = self.mapGridId  , isPassed  = self.isPassed
		})
	else
		self:GetFacade():UnRegistMediator(NAME)
	end
end

function Anniversary20ChestMediator:OnRegist()
	regPost(POST.ANNIV2020_EXPLORE_CHEST)
end
function Anniversary20ChestMediator:OnUnRegist()
	unregPost(POST.ANNIV2020_EXPLORE_CHEST)
	local viewComponent = self:GetViewComponent()
	if viewComponent and (not tolua.isnull(viewComponent)) then
		app.uiMgr:GetCurrentScene():RemoveDialog(viewComponent)
	end
end

return Anniversary20ChestMediator

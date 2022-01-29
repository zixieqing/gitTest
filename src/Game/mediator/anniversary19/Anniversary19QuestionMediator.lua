--[[
扭蛋系统mediator
--]]
local Mediator = mvc.Mediator
---@class Anniversary19QuestionMediator :Mediator
local Anniversary19QuestionMediator = class("Anniversary19QuestionMediator", Mediator)
local NAME = "Anniversary19QuestionMediator"
local BUTTON_TAG = {
	ANSWER_QUESTION   = 1001, -- 回答问题
}
local gameMgr            = app.gameMgr
local anniversary2019Mgr = app.anniversary2019Mgr
---ctor
---@param viewComponent table
function Anniversary19QuestionMediator:ctor(param ,  viewComponent )
	self.super:ctor(NAME,viewComponent)
	self.exploreId = param.exploreId  or  1
	self.exploreModuleId = param.exploreModuleId  or  1
end
function Anniversary19QuestionMediator:InterestSignals()
	local signals = {
	}

	return signals
end

function Anniversary19QuestionMediator:ProcessSignal( signal )
	local data = signal:GetBody()
	local name = signal:GetName()
end
function Anniversary19QuestionMediator:Initial( key )
	self.super.Initial(self,key)
	---@type Anniversary19ChestView
	local viewComponent = require("Game.views.anniversary19.Anniversary19QuestionView").new()
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	app.uiMgr:GetCurrentScene():AddGameLayer(viewComponent)
	viewComponent:UpdateUI(self.exploreModuleId  , self.exploreId  )
	viewComponent:AddDiffView()

	local viewData = viewComponent.viewData
	viewData.rightButton:setTag(BUTTON_TAG.ANSWER_QUESTION)
	viewData.rightButton:setOnClickScriptHandler(handler(self , self.ButtonAction))
end

function Anniversary19QuestionMediator:ButtonAction(sender)
	PlayAudioByClickNormal()
	local tag = sender:getTag()
	print(tag)
	if tag ==  BUTTON_TAG.ANSWER_QUESTION then
		local viewComponent = self:GetViewComponent()
		local swallowLayer = viewComponent.viewData.swallowLayer
		swallowLayer:setLocalZOrder(100)
		app.uiMgr:GetCurrentScene():HideCircleExtrenal()
		local mediator = require("Game.mediator.anniversary19.Anniversary19AnswerQuesMediator").new({
			exploreModuleId  = self.exploreModuleId ,
			exploreId =  self.exploreId
		})
		AppFacade.GetInstance():RegistMediator(mediator)
		-- 关闭掉自己
		self:GetFacade():UnRegsitMediator(NAME)
	end
end

function Anniversary19QuestionMediator:OnRegist()
end
function Anniversary19QuestionMediator:OnUnRegist()
	local viewComponent = self:GetViewComponent()
	if viewComponent and (not tolua.isnull(viewComponent)) then
		app.uiMgr:GetCurrentScene():RemoveDialog(viewComponent)
	end
end

return Anniversary19QuestionMediator

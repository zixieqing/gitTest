--[[
扭蛋系统mediator
--]]
local Mediator = mvc.Mediator
---@class Anniversary20QuestionMediator :Mediator
local Anniversary20QuestionMediator = class("Anniversary20QuestionMediator", Mediator)
local NAME = "Anniversary20QuestionMediator"
local BUTTON_TAG = {
	ANSWER_QUESTION   = 1001, -- 回答问题
}
---ctor
---@param viewComponent table
function Anniversary20QuestionMediator:ctor(param ,  viewComponent )
	self.super:ctor(NAME,viewComponent)
	self.mapGridId = param.mapGridId  or  1

end
function Anniversary20QuestionMediator:InterestSignals()
	local signals = {
		"ANNIVERSARY_2020_EXPLORE_STEP_CLOSE_EVENT" ,

	}

	return signals
end

function Anniversary20QuestionMediator:ProcessSignal( signal )
	local data = signal:GetBody()
	local name = signal:GetName()
	if name == "ANNIVERSARY_2020_EXPLORE_STEP_CLOSE_EVENT" then
		self:GetFacade():UnRegistMediator(NAME)
	end
end
function Anniversary20QuestionMediator:Initial( key )
	self.super.Initial(self,key)
	---@type Anniversary20QuestionView
	local viewComponent = require("Game.views.anniversary20.Anniversary20QuestionView").new()
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	app.uiMgr:GetCurrentScene():AddGameLayer(viewComponent)
	viewComponent:UpdateUI(self.mapGridId )
	viewComponent:AddDiffView()

	local viewData = viewComponent.viewData
	viewData.rightButton:setTag(BUTTON_TAG.ANSWER_QUESTION)
	viewData.rightButton:setOnClickScriptHandler(handler(self , self.ButtonAction))
end

function Anniversary20QuestionMediator:ButtonAction(sender)
	PlayAudioByClickNormal()
	local tag = sender:getTag()
	if tag ==  BUTTON_TAG.ANSWER_QUESTION then
		local mediator = require("Game.mediator.anniversary20.Anniversary20AnswerQuesMediator").new({
			mapGridId = self.mapGridId
		})
		AppFacade.GetInstance():RegistMediator(mediator)
		-- 关闭掉自己
		self:GetFacade():UnRegsitMediator(NAME)
	end
end

function Anniversary20QuestionMediator:OnRegist()
end
function Anniversary20QuestionMediator:OnUnRegist()
	local viewComponent = self:GetViewComponent()
	if viewComponent and (not tolua.isnull(viewComponent)) then
		app.uiMgr:GetCurrentScene():RemoveDialog(viewComponent)
	end
end

return Anniversary20QuestionMediator

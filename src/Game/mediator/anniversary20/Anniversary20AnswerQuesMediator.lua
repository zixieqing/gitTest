--[[
扭蛋系统mediator
--]]
local Mediator = mvc.Mediator
---@class Anniversary20AnswerQuesMediator :Mediator
local Anniversary20AnswerQuesMediator = class("Anniversary20AnswerQuesMediator", Mediator)
local NAME = "Anniversary20AnswerQuesMediator"
local SECTION = {
	START = 0 ,  -- 答题开始
	RIGHT  = 1 , --答对
	ERROR  = 2 , --答错
}
local BUTTON_TAG = {
	ANSWER_TAG = 1001 , -- 回答事件
	CONTINUE_TAG = 1002  , -- 回答事件
}
---ctor
---@param viewComponent table
function Anniversary20AnswerQuesMediator:ctor(param ,  viewComponent )
	self.super:ctor(NAME,viewComponent)
	self.mapGridId = param.mapGridId  or  1
	self.section = SECTION.START
	self.currentIndex = nil
	self.answerTable = self:GetAnswerTable()
	self.isPassed = nil
end
function Anniversary20AnswerQuesMediator:InterestSignals()
	local signals = {
		POST.ANNIV2020_EXPLORE_OPTION.sglName ,
		"ANNIVERSARY_2020_EXPLORE_STEP_CLOSE_EVENT"
	}
	return signals
end

function Anniversary20AnswerQuesMediator:ProcessSignal( signal )
	local data = signal:GetBody()
	local name = signal:GetName()
	if name == POST.ANNIV2020_EXPLORE_OPTION.sglName then
		local requestData = data.requestData
		-- 选项1位答题的正确答案
		local optionId = requestData.optionId
		---@type Anniversary20AnswerQuesView
		local viewComponent = self:GetViewComponent()
		local result = nil
		if checkint(optionId) == 1 then
			result = 1
			self.section = result
			viewComponent:UpdateRightUI()
		else
			result = 0
			self.section = result
			viewComponent:UpdateErrorUI()
		end
		local viewData = viewComponent.viewData
		local optionsTable = viewData.optionsTable
		for i = 1,  #optionsTable  do
			viewComponent:UpdateOptionsCell(optionsTable[i] ,self.answerTable[i] , optionId )
		end
		self.isPassed =  result == 1 and 1 or 0
	elseif name == "ANNIVERSARY_2020_EXPLORE_STEP_CLOSE_EVENT" then
		self:CloseMeditor()
	end
end
function Anniversary20AnswerQuesMediator:Initial( key )
	self.super.Initial(self, key)
	---@type Anniversary20AnswerQuesView
	local viewComponent = require("Game.views.anniversary20.Anniversary20AnswerQuesView").new()
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	app.uiMgr:GetCurrentScene():AddGameLayer(viewComponent)
	local viewData = viewComponent.viewData
	display.commonUIParams(viewData.answerBtn , {cb = handler(self , self.ButtonAction)})
	for i = 1, #viewData.optionsTable do
		display.commonUIParams(viewData.optionsTable[i].oneOptionsLayout , {cb = handler(self , self.OptionClick)})
	end
	viewComponent:UpdateUI(self.mapGridId, self.section ,   self.answerTable)
end
---GetAnswerTable 获取到答案的顺序
function Anniversary20AnswerQuesMediator:GetAnswerTable()
	local answerTable = {}
	local sortTable  = {
		1 , 2 , 3
	}
	for i = 3 , 1, -1 do
		local index  = 	0
		if i > 1 then
			index = math.random(1 , i )
		else
			index = i
		end
		answerTable[#answerTable+1] = sortTable[index]
		table.remove(sortTable ,index)
	end
	return answerTable
end
function Anniversary20AnswerQuesMediator:ButtonAction(sender)
	PlayAudioByClickNormal()
	local tag = sender:getTag()
	if tag == BUTTON_TAG.ANSWER_TAG then
		if self.currentIndex then
			self:SendSignal(POST.ANNIV2020_EXPLORE_OPTION.cmdName , {
				gridId = self.mapGridId,
				optionId = self.answerTable[self.currentIndex]
			})
		else
			app.uiMgr:ShowInformationTips(__('请先选择答案'))
		end
	elseif  tag == BUTTON_TAG.CONTINUE_TAG then

		self:CloseMeditor()
	end
end
function Anniversary20AnswerQuesMediator:OptionClick(sender)
	PlayAudioByClickNormal()
	local tag = sender:getTag()
	if self.section > SECTION.START then
		app.uiMgr:ShowInformationTips(__('回答已经结束了'))
		return
	end
	self.currentIndex = tag
	---@type Anniversary19AnswerQuesView
	local viewComponent = self:GetViewComponent()
	viewComponent:ClickOptionsCell(tag)
	local viewData = viewComponent.viewData
	viewData.answerBtn:setNormalImage(_res('ui/common/common_btn_orange'))
	viewData.answerBtn:setSelectedImage(_res('ui/common/common_btn_orange'))

end
function Anniversary20AnswerQuesMediator:CloseMeditor()
	if self.isPassed then
		self:GetFacade():UnRegistMediator(NAME)
		self:GetFacade():DispatchObservers(ANNIVERSARY20_EXPLORE_RESULT_EVENT, {
			mapGridId  = self.mapGridId  , isPassed  = self.isPassed
		})
	else
		self:GetFacade():UnRegistMediator(NAME)
	end

end
function Anniversary20AnswerQuesMediator:OnRegist()
	regPost(POST.ANNIV2020_EXPLORE_OPTION)
end

function Anniversary20AnswerQuesMediator:OnUnRegist()
	unregPost(POST.ANNIV2020_EXPLORE_OPTION)
	local viewComponent = self:GetViewComponent()
	if viewComponent and (not tolua.isnull(viewComponent)) then
		viewComponent:removeFromParent()
	end
end

return Anniversary20AnswerQuesMediator

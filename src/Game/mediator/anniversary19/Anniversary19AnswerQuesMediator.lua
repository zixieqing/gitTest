--[[
扭蛋系统mediator
--]]
local Mediator = mvc.Mediator
---@class Anniversary19AnswerQuesMediator :Mediator
local Anniversary19AnswerQuesMediator = class("Anniversary19AnswerQuesMediator", Mediator)
local NAME = "Anniversary19AnswerQuesMediator"
local SECTION = {
	START = 0 ,  -- 答题开始
	RIGHT  = 1 , --答对
	ERROR  = 2 , --答错
}
local anniversary2019Mgr = app.anniversary2019Mgr
local BUTTON_TAG = {
	ANSWER_TAG = 1001 , -- 回答事件
	CONTINUE_TAG = 1002  , -- 回答事件
}
---ctor
---@param viewComponent table
function Anniversary19AnswerQuesMediator:ctor(param ,  viewComponent )
	self.super:ctor(NAME,viewComponent)
	self.exploreId = param.exploreId  or  1
	self.exploreModuleId = param.exploreModuleId  or  1
	self.section = SECTION.START
	self.currentIndex = nil
	self.progress = anniversary2019Mgr:GetCurrentExploreProgress()
	self.answerTable = self:GetAnswerTable()
end
function Anniversary19AnswerQuesMediator:InterestSignals()
	local signals = {
		POST.ANNIVERSARY2_EXPLORE_SECTION_OPTION.sglName ,

	}
	return signals
end

function Anniversary19AnswerQuesMediator:ProcessSignal( signal )
	local data = signal:GetBody()
	local name = signal:GetName()
	local progress = anniversary2019Mgr:GetCurrentExploreProgress()
	if  not self.progress == progress then
		app.uiMgr:ShowInformationTips(app.anniversary2019Mgr:GetPoText(__('该探索已通过')))
		return
	end
	if name == POST.ANNIVERSARY2_EXPLORE_SECTION_OPTION.sglName then
		local requestData = data.requestData
		-- 选项1位答题的正确答案
		local optionId = requestData.optionId
		---@type Anniversary19AnswerQuesView
		local viewComponent = self:GetViewComponent()
		local result = nil
		local isGiveup = false
		if checkint(optionId) == 1 then
			result = 1
			self.section = result
			viewComponent:UpdateRightUI()
		else
			isGiveup = true
			result = 2
			self.section = result
			viewComponent:UpdateErrorUI()
		end
		local viewData = viewComponent.viewData
		local optionsTable = viewData.optionsTable
		for i = 1,  #optionsTable  do
			viewComponent:UpdateOptionsCell(optionsTable[i] ,self.answerTable[i] , optionId )
		end
		self:GetFacade():DispatchObservers(ANNIVERSARY19_EXPLORE_RESULT_EVENT , {  result = result , isGiveup = isGiveup  })
	end
end
function Anniversary19AnswerQuesMediator:Initial( key )
	self.super.Initial(self, key)
	---@type Anniversary19AnswerQuesView
	local viewComponent = require("Game.views.anniversary19.Anniversary19AnswerQuesView").new()
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	app.uiMgr:GetCurrentScene():AddGameLayer(viewComponent)
	local viewData = viewComponent.viewData
	display.commonUIParams(viewData.answerBtn , {cb = handler(self , self.ButtonAction)})
	for i = 1, #viewData.optionsTable do
		display.commonUIParams(viewData.optionsTable[i].oneOptionsLayout , {cb = handler(self , self.OptionClick)})
	end
	viewComponent:UpdateUI(self.exploreModuleId , self.exploreId , self.section ,   self.answerTable)
end
---GetAnswerTable 获取到答案的顺序
function Anniversary19AnswerQuesMediator:GetAnswerTable()
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
function Anniversary19AnswerQuesMediator:ButtonAction(sender)
	PlayAudioByClickNormal()
	local tag = sender:getTag()
	local progress = anniversary2019Mgr:GetCurrentExploreProgress()
	if  not self.progress == progress then
		app.uiMgr:ShowInformationTips(app.anniversary2019Mgr:GetPoText(__('该探索已通过')))
		return
	end
	if tag == BUTTON_TAG.ANSWER_TAG then
		if self.currentIndex then
			self:SendSignal(POST.ANNIVERSARY2_EXPLORE_SECTION_OPTION.cmdName , {
				exploreModuleId = self.exploreModuleId ,
				optionId = self.answerTable[self.currentIndex]
			})
		else
			app.uiMgr:ShowInformationTips(app.anniversary2019Mgr:GetPoText(__('请先选择答案')))
		end
	elseif  tag == BUTTON_TAG.CONTINUE_TAG then
		self:GetFacade():DispatchObservers("DREAM_CIRCLE_ONE_STEP_COMPLETE" , { } )
		self:GetFacade():UnRegsitMediator(NAME)
	end
end
function Anniversary19AnswerQuesMediator:OptionClick(sender)
	PlayAudioByClickNormal()
	local tag = sender:getTag()
	if self.section >SECTION.START then
		app.uiMgr:ShowInformationTips(app.anniversary2019Mgr:GetPoText(__('回答已经结束了')))
		return
	end
	self.currentIndex = tag
	---@type Anniversary19AnswerQuesView
	local viewComponent = self:GetViewComponent()
	viewComponent:ClickOptionsCell(tag)
	local viewData = viewComponent.viewData
	viewData.answerBtn:setNormalImage(app.anniversary2019Mgr:GetResPath('ui/common/common_btn_orange'))
	viewData.answerBtn:setSelectedImage(app.anniversary2019Mgr:GetResPath('ui/common/common_btn_orange'))

end
function Anniversary19AnswerQuesMediator:OnRegist()
	regPost(POST.ANNIVERSARY2_EXPLORE_SECTION_OPTION)
end

function Anniversary19AnswerQuesMediator:OnUnRegist()
	unregPost(POST.ANNIVERSARY2_EXPLORE_SECTION_OPTION)
	local viewComponent = self:GetViewComponent()
	if viewComponent and (not tolua.isnull(viewComponent)) then
		viewComponent:removeFromParent()
	end
end

return Anniversary19AnswerQuesMediator

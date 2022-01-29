--[[
扭蛋系统mediator
--]]
local Mediator = mvc.Mediator
---@class Anniversary19PlotStoryMediator :Mediator
local Anniversary19PlotStoryMediator = class("Anniversary19PlotStoryMediator", Mediator)
local NAME = "Anniversary19PlotStoryMediator"
local BUTTON_TAG = {
	LOOK_STORY   = 1001, -- 看剧情
}
local anniversary2019Mgr = app.anniversary2019Mgr
---ctor
---@param viewComponent table
function Anniversary19PlotStoryMediator:ctor(param ,  viewComponent )
	self.super:ctor(NAME,viewComponent)
	self.exploreId = param.exploreId  or  1
	self.exploreModuleId = param.exploreModuleId  or  1
	-- 获取当前的探索进度
	self.progress = anniversary2019Mgr:GetCurrentExploreProgress()
	
end
function Anniversary19PlotStoryMediator:InterestSignals()
	local signals = {
		POST.EXPLORE_SECTION_STORY.sglName
	}
	return signals
end

function Anniversary19PlotStoryMediator:ProcessSignal( signal )
	local name = signal:GetName()
	local progress = anniversary2019Mgr:GetCurrentExploreProgress()
	if  not self.progress == progress then
		app.uiMgr:ShowInformationTips(app.anniversary2019Mgr:GetPoText(__('已通过该探索')))
		return
	end
	if name == POST.EXPLORE_SECTION_STORY.sglName then
		self:GetFacade():DispatchObservers(ANNIVERSARY19_EXPLORE_RESULT_EVENT , { result = 1 })
		self:GetFacade():DispatchObservers("DREAM_CIRCLE_ONE_STEP_COMPLETE" , { } )
	end
end
function Anniversary19PlotStoryMediator:Initial( key )
	self.super.Initial(self,key)
	---@type Anniversary19PlotStoryView
	local viewComponent = require("Game.views.anniversary19.Anniversary19PlotStoryView").new()
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	app.uiMgr:GetCurrentScene():AddGameLayer(viewComponent)
	viewComponent:UpdateUI(self.exploreModuleId  , self.exploreId  )
	viewComponent:AddDiffView()
	local viewData = viewComponent.viewData
	viewData.rightButton:setTag(BUTTON_TAG.LOOK_STORY)
	display.commonUIParams(viewData.rightButton , {cb = handler(self , self.ButtonAction)})
end

function Anniversary19PlotStoryMediator:ButtonAction(sender)
	local tag = sender:getTag()
	local progress = anniversary2019Mgr:GetCurrentExploreProgress()
	if  not self.progress == progress then
		app.uiMgr:ShowInformationTips(app.anniversary2019Mgr:GetPoText(__('该探索已通过')))
		return
	end
	if tag ==  BUTTON_TAG.LOOK_STORY then
		local exploreStoryConf = anniversary2019Mgr:GetDreamQuestTypeConfByDreamQuestType(anniversary2019Mgr.dreamQuestType.GUAN_PLOT)
		local exploreOneStoryConf = exploreStoryConf[tostring(self.exploreModuleId)][tostring(self.exploreId)]
		local  storyId = exploreOneStoryConf.storyId
		local homeData       = anniversary2019Mgr:GetHomeData()
		local unlockStoryMap = homeData.unlockStoryMap or {}
		local isSendReq = true
		-- 检测改剧情是否上传
		if unlockStoryMap[tostring(storyId)] then
			isSendReq = false
		end
		anniversary2019Mgr:ShowOperaStage(storyId, function()
			if self.progress == progress then
				self:SendSignal(POST.EXPLORE_SECTION_STORY.cmdName , { exploreModuleId = self.exploreModuleId })
			else
				app.uiMgr:ShowInformationTips(app.anniversary2019Mgr:GetPoText(__('剧情已经观看')))
			end
		end , isSendReq)
	end
end


function Anniversary19PlotStoryMediator:OnRegist()
	regPost(POST.EXPLORE_SECTION_STORY)
end
function Anniversary19PlotStoryMediator:OnUnRegist()
	unregPost(POST.EXPLORE_SECTION_STORY)
	local viewComponent = self:GetViewComponent()
	if viewComponent and (not tolua.isnull(viewComponent)) then
		app.uiMgr:GetCurrentScene():RemoveDialog(viewComponent)
	end
end

return Anniversary19PlotStoryMediator

--[[
扭蛋系统mediator
--]]
local Mediator = mvc.Mediator
---@class Anniversary19DreamCircleMediator :Mediator
local Anniversary19DreamCircleMediator = class("Anniversary19DreamCircleMediator", Mediator)
local NAME = "Anniversary19DreamCircleMediator"
local gameMgr            = app.gameMgr
local anniversary2019Mgr = app.anniversary2019Mgr
---ctor
---@param param table @{ exploreId : int ,exploreModuleId : int   ,  isPassed  }
---@param viewComponent table
function Anniversary19DreamCircleMediator:ctor(param ,  viewComponent )
	self.super:ctor(NAME,viewComponent)
	self.isPassed = param.isPassed or false
	-- 获取到当前的进度
	self.prograss = anniversary2019Mgr:GetCurrentExploreProgress()
end
function Anniversary19DreamCircleMediator:InterestSignals()
	local signals = {
		POST.ANNIVERSARY2_EXPLORE_SECTION_DRAW.sglName ,
		"CLOSE_DREAM_CIRCLE_VIEW_EVENT" ,
		"DREAM_VIEW_ENTER_ACTION_EVENT" ,
		"DREAM_VIEW_ENTER_ACTION_END_EVENT" ,
		"RUN_ENTER_ACTION_EVENT" ,
		"STEP_REWARD_ANIMATION_EVENT"
	}

	return signals
end
---@param signal Signal 
function Anniversary19DreamCircleMediator:ProcessSignal( signal )
	local name = signal:GetName()
	local data = signal:GetBody()
	if name == POST.ANNIVERSARY2_EXPLORE_SECTION_DRAW.sglName  then
		local requestData = data.requestData
		local exploreModuleId = requestData.exploreModuleId
		-- 置为零表示完成探索
		local callfunc = function()
			anniversary2019Mgr:SetHomeExploreStatus(exploreModuleId , 0 )
			---@type Anniversary19DreamCircleView
			local viewComponent = self:GetViewComponent()
			viewComponent:RunEndAnimation()
		end
		data.closeCallback = callfunc
		app.uiMgr:AddDialog('common.RewardPopup' , data )
		anniversary2019Mgr:ReducesBossLevelLeftDiscoveryTimes(anniversary2019Mgr:GetCurrentExploreModuleId())
	elseif name == "STEP_REWARD_ANIMATION_EVENT" then
		---@type Anniversary19DreamCircleView
		local viewComponent = self:GetViewComponent()
		local viewData = viewComponent.viewData
		viewComponent:UpdateRewardLayout(viewData.rewardLayoutData , false , anniversary2019Mgr:GetCurrentExploreModuleId())
		viewData.rewardLayoutData.rewardsBtn:setVisible(true)
		display.commonUIParams(viewData.rewardLayoutData.rewardsBtn , { cb = handler(self ,self.DrawNextStepClick)})
	elseif name == "CLOSE_DREAM_CIRCLE_VIEW_EVENT" then
		local exploreModuleId = anniversary2019Mgr:GetCurrentExploreModuleId()
		local exploreConf = CommonUtils.GetConfig('anniversary2', 'explore', exploreModuleId) or {}
		local bossStory = exploreConf.bossStory
		anniversary2019Mgr:CheckStoryIsUnlocked(bossStory, function ()
			---@type Router
			local router = self:GetFacade():RetrieveMediator("Router")
			router:Dispatch({name = "anniversary19.Anniversary19DreamCircleMediator"} , {name = "anniversary19.Anniversary19ExploreMainMediator" })
		end)
	elseif name == "DREAM_VIEW_ENTER_ACTION_END_EVENT"  then
		local viewComponent = self:GetViewComponent()
		local viewData = viewComponent.viewData
		if not self.isPassed then
			viewData.closeView:setEnabled(true)
			viewData.closeView:setOnClickScriptHandler(function()
				PlayAudioByClickClose()
				viewData.closeView:setLocalZOrder(100)
				viewData.closeView:setEnabled(false)
				viewData.circleSwallowLayout:setVisible(false)
				viewData.blackView:setVisible(false)
				viewData.blackView:runAction(
					cc.Sequence:create(
						cc.CallFunc:create(function()
							self:GetFacade():DispatchObservers("SHOW_SWALLOW_TOP_LAYER" , {})
						end)	,
						cc.Spawn:create(
							cc.FadeOut:create(0.8),
							cc.TargetedAction:create(
								viewData.circleLayout ,
								cc.Spawn:create(
									cc.Sequence:create(
										cc.ScaleTo:create(0.3, 0.6) ,
										cc.CallFunc:create(function()
											self:GetFacade():DispatchObservers("LOOK_DREAM_CIRCLR_VIEW_CLOSE_EVENT" , {})
										end),
										cc.EaseSineInOut:create(cc.MoveTo:create(0.5, cc.p(display.width/2 , -(768/2) ) ))
									),
									cc.FadeOut:create(0.8)
								)
							)
						),
						cc.CallFunc:create(function()
							viewData.blackView:stopAllActions()
							viewComponent:setVisible(false)
							self:GetFacade():UnRegsitMediator(NAME)
							self:GetFacade():DispatchObservers("HIDE_SWALLOW_TOP_LAYER" , {})
						end)
					)
				)
			end)
		else
			viewData.closeView:setEnabled(false)
		end
	elseif name == "DREAM_VIEW_ENTER_ACTION_EVENT" then
		self:UpdateUI()
	elseif name == "RUN_ENTER_ACTION_EVENT" then
		self:UpdateCompleteDreamCircle()
	end
end

function Anniversary19DreamCircleMediator:Initial( key )
	self.super.Initial(self, key)
	---@type Anniversary19DreamCircleView
	local viewComponent = require("Game.views.anniversary19.Anniversary19DreamCircleView").new()
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	app.uiMgr:GetCurrentScene():AddDialog(viewComponent)
	viewComponent:EnterAction()
end

function Anniversary19DreamCircleMediator:UpdateUI()
	if self.isPassed then
		self:UpdatePassDreamUI()
	else
		self:UpdateShowPrograssUI()
	end
end
--- 展示梦境循环
function Anniversary19DreamCircleMediator:UpdateShowPrograssUI()
	local exploreData = anniversary2019Mgr:GetExploreData()
	local section = exploreData.section
	local prograss = anniversary2019Mgr:GetCurrentExploreProgress()
	---@type Anniversary19DreamCircleView
	local viewComponent = self:GetViewComponent()
	viewComponent:UpdateRunActionIconBoss()
	local viewData = viewComponent.viewData
	for i = 1 , 7  do
		local data = section[i]
		if checkint(data.enter) > 0 or checkint(data.result) > 0 then
			viewComponent:UpdateDreamCircleNode(viewData.dreamCircleNodes[i] , true , data.type)
			viewComponent:DreamNodeIsEnabled(viewData.dreamCircleNodes[i] , true)
		else
			viewComponent:DreamNodeIsEnabled(viewData.dreamCircleNodes[i] , false , false)
			if prograss == i then
				viewComponent:UpdateDreamCircleNode(viewData.dreamCircleNodes[i] , false , 0)
			else
				viewComponent:UpdateDreamCircleNode(viewData.dreamCircleNodes[i] , false , false)
			end
		end
		viewData.dreamCircleNodes[i].commonStepsLayout:setOnClickScriptHandler(handler(self , self.DreamCircleNodeClick))
	end
	for i, v in pairs(section) do
		if  checkint(v.passed) == 1  then
			if checkint(v.type) == anniversary2019Mgr.dreamQuestType.CARDS_SHUT  then
				local battleCardData = viewComponent:CreateBattleCardEffectNode()
				viewData.dreamCircleNodes[i].commonStepsLayout:addChild(battleCardData.battleCardLayout)
				battleCardData.battleCardLayout:setPosition(47, 0 )
				viewComponent:UpdateBattleCardEffectNode(battleCardData , checkint(v.result))
				viewData.battleCardEffectNodes[tostring(i)] = viewData
			end
		end
	end
	local rewardData = viewComponent:CreateRewardLayout()
	local viewData = viewComponent.viewData
	viewData.rewardLayoutData = rewardData
	viewData.circleLayout:addChild(viewData.rewardLayoutData.resultStepsLayout)
	viewComponent:UpdateRewardLayout(viewData.rewardLayoutData ,false , anniversary2019Mgr:GetCurrentExploreModuleId())
	viewComponent:UpdateFinallyLayout(anniversary2019Mgr:GetCurrentExploreModuleId() , false)
end

---通过关卡的时候 展示梦境循环
function Anniversary19DreamCircleMediator:UpdatePassDreamUI()
	-----@type Anniversary19DreamCircleView
	local viewComponent = self:GetViewComponent()
	viewComponent:UpdateRunActionIconBoss()
	local viewData = viewComponent.viewData
	local exploreData = anniversary2019Mgr:GetExploreData()
	local prograss = anniversary2019Mgr:GetCurrentExploreProgress()
	local section = exploreData.section
	for i = 1 , 7  do
		local data = section[i]
		if checkint(data.enter) > 0 or checkint(data.result) > 0  then
			viewComponent:UpdateDreamCircleNode(viewData.dreamCircleNodes[i] , true , data.type)
		else
			if prograss == i then
				viewComponent:UpdateDreamCircleNode(viewData.dreamCircleNodes[i] , false , 0 , true)
			else
				viewComponent:UpdateDreamCircleNode(viewData.dreamCircleNodes[i] , false , 0 , false)
			end
		end
		viewComponent:DreamNodeIsEnabled(viewData.dreamCircleNodes[i] , false)
	end
	for i, v in pairs(section) do
		if  checkint(v.result) >= 1 then
			if checkint(v.type) == anniversary2019Mgr.dreamQuestType.CARDS_SHUT  then
				local battleCardData = viewComponent:CreateBattleCardEffectNode()
				viewData.dreamCircleNodes[i].commonStepsLayout:addChild(battleCardData.battleCardLayout)
				battleCardData.battleCardLayout:setPosition(47, 0 )
				viewComponent:UpdateBattleCardEffectNode(battleCardData , checkint(v.result))
				viewData.battleCardEffectNodes[tostring(i)] = viewData
			end
		end
	end
	local dreamQuestType = section[self.prograss] and  section[self.prograss].type
	if self.prograss <= 7 then
		if dreamQuestType ~= anniversary2019Mgr.dreamQuestType.TRAP_SHUT then
			local rewardEffectData = viewComponent:CreateDreamRewardEffectNode()
			viewData.rewardEffectNodes[tostring(self.prograss)] = rewardEffectData
			rewardEffectData.resultScView:setPosition(47, 10 )
			viewData.dreamCircleNodes[self.prograss].commonStepsLayout:addChild(rewardEffectData.resultScView , -1)
			viewComponent:ScrollViewAction(rewardEffectData)
			local text  , rewardData = viewComponent:GetDreamTypeText(section[self.prograss].type , section[self.prograss].result ,anniversary2019Mgr:GetCurrentExploreModuleId() , section[self.prograss].exploreId   )
			viewComponent:UpdateRewardEffectNode(rewardEffectData ,text  , rewardData )
			if not  viewData.rewardLayoutData then
				local rewardLayoutData = viewComponent:CreateRewardLayout()
				viewData.rewardLayoutData = rewardLayoutData
				viewData.circleLayout:addChild(viewData.rewardLayoutData.resultStepsLayout)
			end
			viewComponent:UpdateRewardLayout(viewData.rewardLayoutData ,false , anniversary2019Mgr:GetCurrentExploreModuleId())
			if section[self.prograss].result == 2 then
				viewData.rewardLayoutData.rewardsBtn:setVisible(true)
				display.commonUIParams(viewData.rewardLayoutData.rewardsBtn , { cb = handler(self ,self.DrawNextStepClick)})
			else
				viewComponent:StepRewardAnimation(rewardData.goodsId, anniversary2019Mgr:GetCurrentExploreProgress())
			end
			anniversary2019Mgr:AddPrograssRewardNum(anniversary2019Mgr:GetCurrentExploreModuleId() , self.prograss)
			viewComponent:UpdateFinallyLayout(anniversary2019Mgr:GetCurrentExploreModuleId() , false)
		else
			if not  viewData.rewardLayoutData then
				local rewardLayoutData = viewComponent:CreateRewardLayout()
				viewData.rewardLayoutData = rewardLayoutData
				viewData.circleLayout:addChild(viewData.rewardLayoutData.resultStepsLayout)
			end
			viewComponent:UpdateRewardLayout(viewData.rewardLayoutData ,false , anniversary2019Mgr:GetCurrentExploreModuleId())
			viewComponent:UpdateFinallyLayout(anniversary2019Mgr:GetCurrentExploreModuleId() , false)
			viewData.rewardLayoutData.rewardsBtn:setVisible(true)
			display.commonUIParams(viewData.rewardLayoutData.rewardsBtn , { cb = handler(self ,self.DrawNextStepClick)})
		end
	else
		viewComponent:UpdateFinallyLayout(anniversary2019Mgr:GetCurrentExploreModuleId() , true)
		self:UpdateCompleteDreamCircle()
	end
end

function Anniversary19DreamCircleMediator:UpdateCompleteDreamCircle()
	---@type Anniversary19DreamCircleView
	local viewComponent = self:GetViewComponent()
	local viewData = viewComponent.viewData
	if not  viewData.rewardLayoutData then
		local rewardLayoutData = viewComponent:CreateRewardLayout()
		viewData.rewardLayoutData = rewardLayoutData
		viewData.circleLayout:addChild(viewData.rewardLayoutData.resultStepsLayout)
	end
	viewComponent:UpdateRewardLayout(viewData.rewardLayoutData , true ,anniversary2019Mgr:GetCurrentExploreModuleId())
	display.commonUIParams(viewData.rewardLayoutData.rewardsBtn , {cb = handler(self, self.DrawRewardClick)})
end
function Anniversary19DreamCircleMediator:DrawNextStepClick(sender)
	PlayAudioByClickNormal()
	local prograss = anniversary2019Mgr:GetCurrentExploreProgress()
	anniversary2019Mgr:SetCurrentExploreProgressPass(self.prograss)
	local viewComponent = self:GetViewComponent()
	if prograss >=  7  then
		---@type Anniversary19DreamCircleView
		viewComponent:DreamNodeRunRewardAnimation()
	else
		local section = anniversary2019Mgr:GetExploreData().section
		local dreamQuestType = checkint(section[prograss].type)
		if dreamQuestType == anniversary2019Mgr.dreamQuestType.TRAP_SHUT then
			viewComponent:DrawNodeTrapShutRewardAction()
		else
			self:GetFacade():DispatchObservers( "DREAM_CIRCLE_ONE_STEP_COMPLETE" , {})
		end
	end
end
function Anniversary19DreamCircleMediator:DrawRewardClick(sender)
	PlayAudioClip(AUDIOS.UI.ui_mission.id)
	sender:setEnabled(false)
	self:SendSignal(POST.ANNIVERSARY2_EXPLORE_SECTION_DRAW.cmdName ,  {exploreModuleId =  anniversary2019Mgr:GetCurrentExploreModuleId()  })
end

function Anniversary19DreamCircleMediator:DreamCircleNodeClick(sender)
	PlayAudioByClickNormal()
	---@type Anniversary19DreamCircleView
	local viewComponent = self:GetViewComponent()
	local viewData = viewComponent.viewData
	local prograss = anniversary2019Mgr:GetCurrentExploreProgress() - 1
	local section = anniversary2019Mgr:GetExploreData().section
	if not viewData.rewardEffectNodes["1"] then
		for i = 1, prograss do
			local data = section[i]
			local rewardEffectData = viewComponent:CreateDreamRewardEffectNode()
			viewData.rewardEffectNodes[tostring(i)] = rewardEffectData
			rewardEffectData.resultScView:setPosition(47, 13 )
			rewardEffectData.resultScView:setVisible(true)
			viewData.dreamCircleNodes[i].commonStepsLayout:addChild(rewardEffectData.resultScView , -1 )
			local text  , rewardData = viewComponent:GetDreamTypeText(data.type , data.result ,anniversary2019Mgr:GetCurrentExploreModuleId() , data.exploreId   )
			viewComponent:UpdateRewardEffectNode(rewardEffectData ,text  , rewardData )
			viewComponent:ScrollViewAction(viewData.rewardEffectNodes[tostring(i)])
		end
	else
		local isVisible =  viewData.rewardEffectNodes["1"].resultScView:isVisible()
		if isVisible then
			for i, rewardEffectData in pairs(viewData.rewardEffectNodes) do
				rewardEffectData.resultScView:setVisible(false)
			end
		else
			for i, rewardEffectData in pairs(viewData.rewardEffectNodes) do
				rewardEffectData.resultScView:setVisible(true)
				viewComponent:ScrollViewAction(rewardEffectData)
			end
		end
	end
end

function Anniversary19DreamCircleMediator:OnRegist()
	regPost(POST.ANNIVERSARY2_EXPLORE_SECTION_DRAW)
end

function Anniversary19DreamCircleMediator:OnUnRegist()
	unregPost(POST.ANNIVERSARY2_EXPLORE_SECTION_DRAW)
	local viewComponent = self:GetViewComponent()
	if viewComponent and (not tolua.isnull(viewComponent)) then
		viewComponent:stopAllActions()
		viewComponent:runAction(cc.RemoveSelf:create())
	end
end

return Anniversary19DreamCircleMediator

--[[
扭蛋系统mediator
--]]
local Mediator = mvc.Mediator
---@class Anniversary19DreamCircleMainMediator :Mediator
local Anniversary19DreamCircleMainMediator = class("Anniversary19DreamCircleMainMediator", Mediator)
local NAME = "Anniversary19DreamCircleMainMediator"
local anniversary2019Mgr = app.anniversary2019Mgr
local BUTTON_TAG = {
	LEFT_CLICK  = 1001,
	RIGHT_CLICK = 1002,
	BACK_BTN    = 1003,
	LOOK_CIRCLR = 1004,
	LOOK_RULE    =1005 -- 查看规则
}
local MEDIATOR_TABLE = {
	[anniversary2019Mgr.dreamQuestType.LITTLE_MONSTER] = { path = "Game.mediator.anniversary19.Anniversary19LittleMonsterMediator" , mediatorName = "Anniversary19LittleMonsterMediator" },
	[anniversary2019Mgr.dreamQuestType.ELITE_SHUT]     = { path = "Game.mediator.anniversary19.Anniversary19EliteBossMediator" , mediatorName = "Anniversary19EliteBossMediator" },
	[anniversary2019Mgr.dreamQuestType.ANSWER_SHUT]    = { path = "Game.mediator.anniversary19.Anniversary19QuestionMediator" , mediatorName = "Anniversary19QuestionMediator" },
	[anniversary2019Mgr.dreamQuestType.GUAN_PLOT]      = { path = "Game.mediator.anniversary19.Anniversary19PlotStoryMediator" , mediatorName = "Anniversary19PlotStoryMediator" },
	[anniversary2019Mgr.dreamQuestType.CHEST_SHUT]     = { path = "Game.mediator.anniversary19.Anniversary19ChestMediator" , mediatorName = "Anniversary19ChestMediator" },
	[anniversary2019Mgr.dreamQuestType.TRAP_SHUT]      = { path = "Game.mediator.anniversary19.Anniversary19TrapShutMediator" , mediatorName = "Anniversary19TrapShutMediator" },
	[anniversary2019Mgr.dreamQuestType.CARDS_SHUT]     = { path = "Game.mediator.anniversary19.Anniversary19BattleCardMediator" , mediatorName = "Anniversary19BattleCardMediator" }
}

---ctor
---@param viewComponent table
function Anniversary19DreamCircleMainMediator:ctor(param ,  viewComponent )
	self.super:ctor(NAME,viewComponent)
	param = param or {}
	self.dreamQuestTypeMediatorName =nil
	self.battleType = checkint(param.battleType)
	--dump(param)
	--dump("self.battleType  =" ,  self.battleType  )
	self.exploreModuleId = param.exploreModuleId or  0

end
function Anniversary19DreamCircleMainMediator:InterestSignals()
	local signals = {
		POST.ANNIVERSARY2_EXPLORE.sglName ,
		POST.ANNIVERSARY2_EXPLORE_ENTER.sglName ,
		POST.ANNIVERSARY2_EXPLORE_SECTION_GIVE_UP.sglName,
		POST.ANNIVERSARY2_STORY_UNLOCK.sglName ,
		POST.ANNIVERSARY2_EXPLORE_SECTION_BATTLE_CARD.sglName ,
		"HIDE_SWALLOW_TOP_LAYER",
		"DREAM_CIRCLE_ONE_STEP_COMPLETE" ,
		"DREAM_VIEW_ENTER_ACTION_END_EVENT" ,
		"SHOW_SWALLOW_TOP_LAYER" ,
		"LOOK_DREAM_CIRCLR_VIEW_CLOSE_EVENT"
	}
	return signals
end
---@param signal Signal
function Anniversary19DreamCircleMainMediator:ProcessSignal( signal )
	local name = signal:GetName()
	local data = signal:GetBody()
	if name == POST.ANNIVERSARY2_EXPLORE_SECTION_GIVE_UP.sglName  then
		self:GetFacade():DispatchObservers(ANNIVERSARY19_EXPLORE_RESULT_EVENT , { result = 2 , isGiveup = true})
		self:GetFacade():DispatchObservers("DREAM_CIRCLE_ONE_STEP_COMPLETE"  , {})
	elseif name == POST.ANNIVERSARY2_EXPLORE_ENTER.sglName  then
		self:GetFacade():DispatchObservers(ANNIVERSARY19_EXPLORE_RESULT_EVENT , { enter = 1 })
	elseif name == POST.ANNIVERSARY2_EXPLORE.sglName  then
		local requestData= data.requestData
		local exploreModuleId = requestData.exploreModuleId
		local homeData = anniversary2019Mgr:GetHomeData()
		local explore = homeData.explore
		-- 标有问题 先忽略
		if checkint(explore[tostring(exploreModuleId)].exploring) == 0  then
			anniversary2019Mgr:SetHomeExploreStatus(exploreModuleId , 1)
			local parserConf = anniversary2019Mgr:GetConfigParse()
			local exploreConf = anniversary2019Mgr:GetConfigDataByName(parserConf.TYPE.EXPLORE)
			local consumeNum = -exploreConf[tostring(exploreModuleId)].consumeNum
			CommonUtils.DrawRewards({{ goodsId = anniversary2019Mgr:GetHPGoodsId() ,  num = consumeNum  }})
		end
		---@type Anniversary19DreamCircleMainScene
		local viewComponent = self:GetViewComponent()
		viewComponent:UpdateLeftAndRightImage(exploreModuleId)
		anniversary2019Mgr:SetExploreData(data , exploreModuleId)
		viewComponent:EnterSceneAction()
		self:UpdateDreamCircleStatusUI()
	elseif name == "HIDE_SWALLOW_TOP_LAYER"  then
		app.uiMgr:GetCurrentScene():RemoveViewForNoTouch()
	elseif name == "SHOW_SWALLOW_TOP_LAYER" then
		app.uiMgr:GetCurrentScene():AddViewForNoTouch()
	elseif name == "LOOK_DREAM_CIRCLR_VIEW_CLOSE_EVENT"  then
		---@type Anniversary19DreamCircleMainScene
		local viewComponent = self:GetViewComponent()
		viewComponent:ShowCircleExtrenal()
		--viewComponent.viewData.circleExternal:setVisible(true)
	elseif name == "DREAM_CIRCLE_ONE_STEP_COMPLETE"  then
		if self.dreamQuestTypeMediatorName then
			self:GetFacade():UnRegsitMediator(self.dreamQuestTypeMediatorName)
			self.dreamQuestTypeMediatorName = nil
		end
		self:UpdateDreamCircleStatusUI()
	elseif name == POST.ANNIVERSARY2_EXPLORE_SECTION_BATTLE_CARD.sglName then
		local viewComponent = self:GetViewComponent()
		local exploreModuleId = anniversary2019Mgr:GetCurrentExploreModuleId()
		viewComponent:UpdateLeftAndRightImage(exploreModuleId)
		viewComponent:EnterSceneAction()
		self:UpdateDreamCircleStatusUI()
		app.anniversary2019Mgr:PlayBGMusic("Food_alice_dream")
	elseif name == POST.ANNIVERSARY2_STORY_UNLOCK.sglName then
		local requestData = data.requestData or {}
		anniversary2019Mgr:UpdateUnlockStoryMap(requestData.storyId)
	end
end

function Anniversary19DreamCircleMainMediator:UpdateDreamCircleStatusUI()
	local status = anniversary2019Mgr:GetDreamCircleStatus()
	 -- status 0 未开始 1 已经完成 2.已通关
	-- 未开始
	if status == 0  then
		self:AddDoorSpine()
		self:UpdateDreamCircle()
	elseif  status == 1 then
		self:EnterDreamTypeMediator()
		self:UpdateDreamCircle()
	elseif  status == 2 then
		local mediator = require("Game.mediator.anniversary19.Anniversary19DreamCircleMediator").new({ isPassed  = true })
		app:RegistMediator(mediator)
		self.dreamQuestTypeMediatorName = "Anniversary19DreamCircleMediator"
		local viewComponent = self:GetViewComponent()
		viewComponent:HideCircleExtrenal()
	end
end
function Anniversary19DreamCircleMainMediator:DreamNodeAction()
	local typeTable = {1,2,3,4,5,6,7,1,2,3,4,5,6,7}
	local randTable = {}
	for i = #typeTable ,  1 , - 1 do
		local index = math.random(1,i)
		randTable[#randTable+1] =typeTable[index]
		table.remove(typeTable , index)
	end
	local prograss = anniversary2019Mgr:GetCurrentExploreProgress()
	local exploreData = anniversary2019Mgr:GetExploreData()
	local viewComponent = self:GetViewComponent()
	local viewData = viewComponent.viewData
	local section = exploreData.section
	local dreamType = section[prograss].type
	randTable[#randTable+1] = checkint(dreamType)
	local seqAction = {}
	local count =  #randTable
	seqAction[#seqAction+1]  =  cc.DelayTime:create(0.8)
	for i = 1 , count do
		seqAction[#seqAction+1] = cc.CallFunc:create(function()
			viewComponent:UpdateDreamCircleNode(viewData.dreamCircleNodes[prograss] , true ,randTable[i])
		end)
		seqAction[#seqAction+1] = cc.FadeIn:create(0.08)
	end
	seqAction[#seqAction+1] =  cc.CallFunc:create(function()
		self:EnterDreamTypeMediator()
	end)
	viewData.dreamCircleNodes[prograss].commonStepIcon:runAction(

			cc.Sequence:create(seqAction)
	)
end
function Anniversary19DreamCircleMainMediator:Initial( key )
	self.super.Initial(self, key)
	display.removeUnusedSpriteFrames()

	---@type Anniversary19DreamCircleMainScene
	local viewComponent = require("Game.views.anniversary19.Anniversary19DreamCircleMainScene").new()
	self:SetViewComponent(viewComponent)
	app.uiMgr:SwitchToScene(viewComponent)
	local viewData = viewComponent.viewData
	viewData.backBtn:setTag(BUTTON_TAG.BACK_BTN)
	viewData.backBtn:setOnClickScriptHandler(handler(self, self.ButtonAction))
	viewData.circleLayout:setTag(BUTTON_TAG.LOOK_CIRCLR)
	viewData.circleLayout:setOnClickScriptHandler(handler(self, self.ButtonAction) )
	viewData.tabNameLabel:setTag(BUTTON_TAG.LOOK_RULE)
	viewData.tabNameLabel:setOnClickScriptHandler(handler(self, self.ButtonAction) )
	app.uiMgr:GetCurrentScene():AddViewForNoTouch()
end

function Anniversary19DreamCircleMainMediator:UpdateDreamCircle()
	local prograss = anniversary2019Mgr:GetCurrentExploreProgress()
	---@type Anniversary19DreamCircleMainScene
	local viewComponent = self:GetViewComponent()
	local viewData = viewComponent.viewData
	local exploreData = anniversary2019Mgr:GetExploreData()
	local section = exploreData.section
	viewComponent:UpdateCircleNodeRotation(prograss)
	viewComponent:UpdateCircleLayoutRotation(prograss)
	for i = 1 , 7  do
		local data = section[i]
		if  checkint(data.enter)  >  0  or checkint(data.result) > 0  then
			viewComponent:UpdateDreamCircleNode(viewData.dreamCircleNodes[i] , true , data.type)
			viewData.dreamCircleNodes[i].commonStepsLayout:setScale(1)
		else
			if prograss == i  then
				viewComponent:UpdateDreamCircleNode(viewData.dreamCircleNodes[i] , false , 0 , true)
			else
				viewData.dreamCircleNodes[i].commonStepsLayout:setScale(1)
				viewComponent:UpdateDreamCircleNode(viewData.dreamCircleNodes[i] , false , 0 , false)
			end
		end
		viewData.dreamCircleNodes[i].commonStepsLayout:setAnchorPoint(display.CENTER)
	end
	viewComponent:UpdateAccumulativeRewardNum()
	if prograss > 1  then
		viewComponent:ShowCircleExtrenal(function()
			viewComponent:RunCircleAction(0.5 ,  prograss)
		end)
	else
		viewComponent:RunCircleAction(0 ,  prograss)
		viewComponent:ShowCircleExtrenal()
	end
end
function Anniversary19DreamCircleMainMediator:AddDoorSpine()
	---@type Anniversary19DreamCircleMainScene
	local viewComponent = self:GetViewComponent()
	local viewData = viewComponent.viewData
	if not  viewData.spineLayer then
		viewComponent:AddDoorSpine()
		viewData.doorSpine:registerSpineEventHandler(handler(self, self.SpineAction), sp.EventType.ANIMATION_COMPLETE)
		viewData.leftLayout:setTag(BUTTON_TAG.LEFT_CLICK)
		viewData.rightLayout:setTag(BUTTON_TAG.RIGHT_CLICK)
		display.commonUIParams(viewData.leftLayout , {cb = handler(self, self.ButtonAction)  })
		display.commonUIParams(viewData.rightLayout , {cb = handler(self, self.ButtonAction)  })
		
		viewData.rightLayout:runAction(cc.Sequence:create(
			cc.CallFunc:create(
				function()
					self:isUnLockBtn(false)
				end
			) ,
			cc.DelayTime:create(1) ,
			cc.CallFunc:create(
				function()
					self:isUnLockBtn(true)
					local tipsTables = self:GetTipsTable()

					local countOne =  #tipsTables["0"]
					local countTwo =  #tipsTables["1"]
					local indexOne = 1
					local indexTwo = 1
					--dump(tipsTables)
					viewData.leftTextImage:runAction(
							cc.RepeatForever:create(
								cc.Spawn:create(
									cc.Sequence:create(
										cc.CallFunc:create(function()
											indexOne = indexOne % countOne
											indexOne =  (indexOne == 0 and countOne or indexOne)
											viewData.leftLabel:setString(tipsTables["0"][indexOne])
											viewData.leftLabel:setOpacity(0)
											viewData.leftTextImage:setOpacity(0)
											indexOne = indexOne +1
										end) ,
											cc.Spawn:create(
													cc.Sequence:create(
															cc.FadeIn:create(1),
															cc.DelayTime:create(1),
															cc.FadeOut:create(1),
															cc.DelayTime:create(1)
													) ,
													cc.TargetedAction:create(viewData.leftLabel ,
														cc.Sequence:create(
															cc.FadeIn:create(1),
															cc.DelayTime:create(1),
															cc.FadeOut:create(1),
															cc.DelayTime:create(1)
														)
													)
											)
									) ,
									cc.TargetedAction:create( viewData.rightTextImage ,
										cc.Sequence:create(
											cc.DelayTime:create(1) ,
											cc.CallFunc:create(function()
												indexTwo = indexTwo % countTwo
												indexTwo =  (indexTwo == 0 and countTwo or indexTwo)
												viewData.rightLabel:setString(tipsTables["1"][indexTwo])
												viewData.rightTextImage:setOpacity(0)
												viewData.rightLabel:setOpacity(0)
												indexTwo = indexTwo +1
											end) ,
											cc.Spawn:create(
													cc.Sequence:create(
															cc.FadeIn:create(1) ,
															cc.DelayTime:create(1) ,
															cc.FadeOut:create(1)
													) ,
													cc.TargetedAction:create(viewData.rightLabel ,
															cc.Sequence:create(
																	cc.FadeIn:create(1) ,
																	cc.DelayTime:create(1) ,
																	cc.FadeOut:create(1)
															)
													)
											)

										)

									)
								)

							)
					)
				end
			)
		))
	end
end
function Anniversary19DreamCircleMainMediator:GetTipsTable()
	local parserConf = anniversary2019Mgr:GetConfigParse()
	local exploreTipConf = anniversary2019Mgr:GetConfigDataByName(parserConf.TYPE.EXPLORE_TIPS)
	local keys = table.keys(exploreTipConf)
	local tipsTables = {
		["0"] = {} ,
		["1"] = {}
	}
	for i = #keys, 1 , -1 do
		local index = math.random(1,#keys)
		local mode = (#keys) %2
		tipsTables[tostring(mode)][#tipsTables[tostring(mode)]+1] =  exploreTipConf[keys[index]].word
		table.remove(keys , index)
	end
	return tipsTables
end
-- 进入关卡的mediator
function Anniversary19DreamCircleMainMediator:EnterDreamTypeMediator()
	local exploreData =  anniversary2019Mgr:GetExploreData()
	local sectionData = exploreData.section
	local prograss = anniversary2019Mgr:GetCurrentExploreProgress()
	local dreamQuestType =  checkint(sectionData[checkint(prograss)].type)
	local path = MEDIATOR_TABLE[dreamQuestType].path
	local mediator = require(path).new({ exploreModuleId = anniversary2019Mgr:GetCurrentExploreModuleId() , exploreId = sectionData[prograss].exploreId })
	app:RegistMediator(mediator)
	self.dreamQuestTypeMediatorName =   MEDIATOR_TABLE[dreamQuestType].mediatorName
end

function Anniversary19DreamCircleMainMediator:RemoveSpineLayer()
	local viewComponent = self:GetViewComponent()
	local viewData = viewComponent.viewData
	if  viewData.spineLayer then
		viewData.spineLayer:setOpacity(0)
		viewData.spineLayer:runAction(cc.RemoveSelf:create())
		viewData.spineLayer = nil
	end
end

function Anniversary19DreamCircleMainMediator:SpineAction(event)
	local name =  event.animation
	if name == "drop" then
		---@type Anniversary19DreamCircleMainScene
		local viewComponent = self:GetViewComponent()
		local viewData = viewComponent.viewData
		--self:isUnLockBtn(true)
		viewData.doorSpine:addAnimation(0 , 'idle' , true)
	elseif name == 'enter_left' then
		---@type Anniversary19DreamCircleMainScene
		local viewComponent = self:GetViewComponent()
		local viewData = viewComponent.viewData
		viewData.doorSpine:setToSetupPose()
		self:RemoveSpineLayer()
		self:SendSignal(POST.ANNIVERSARY2_EXPLORE_ENTER.cmdName , { exploreModuleId = anniversary2019Mgr:GetCurrentExploreModuleId()})
	elseif name == 'enter_right' then
		---@type Anniversary19DreamCircleMainScene
		local viewComponent = self:GetViewComponent()
		local viewData = viewComponent.viewData
		viewData.doorSpine:setToSetupPose()
		self:RemoveSpineLayer()

		self:SendSignal(POST.ANNIVERSARY2_EXPLORE_ENTER.cmdName , { exploreModuleId = anniversary2019Mgr:GetCurrentExploreModuleId()})
	end
end

function Anniversary19DreamCircleMainMediator:isUnLockBtn(isEnabled )
	local viewComponent = self:GetViewComponent()
	local viewData = viewComponent.viewData
	viewData.leftLayout:setEnabled(isEnabled)
	viewData.rightLayout:setEnabled(isEnabled)
end

function Anniversary19DreamCircleMainMediator:ButtonAction(sender)
	local tag = sender:getTag()
	if tag == BUTTON_TAG.BACK_BTN then
		self:GetFacade():DispatchObservers("SHOW_SWALLOW_TOP_LAYER")
		sender:setEnabled(false)
		PlayAudioByClickClose()
		---@type Router
		local router = self:GetFacade():RetrieveMediator("Router")
		router:Dispatch({name = "anniversary19.Anniversary19DreamCircleMediator"} , {name = "anniversary19.Anniversary19ExploreMainMediator" })
		return
	elseif tag == BUTTON_TAG.LEFT_CLICK  then
		self:isUnLockBtn(false)
		local viewComponent = self:GetViewComponent()
		local viewData = viewComponent.viewData
		viewData.doorSpine:setToSetupPose()
		viewData.doorSpine:setAnimation(0 ,'enter_left' , false)
		viewData.leftLayout:stopAllActions()
		viewData.rightLayout:stopAllActions()
		viewData.leftLayout:setVisible(false)
		viewData.rightLayout:setVisible(false)
		self:DreamNodeAction()
	elseif tag == BUTTON_TAG.RIGHT_CLICK  then
		self:isUnLockBtn(false)
		local viewComponent = self:GetViewComponent()
		local viewData = viewComponent.viewData
		viewData.doorSpine:setToSetupPose()
		viewData.doorSpine:setAnimation(0 ,'enter_right' , false)
		viewData.leftLayout:stopAllActions()
		viewData.rightLayout:stopAllActions()
		viewData.leftLayout:setVisible(false)
		viewData.rightLayout:setVisible(false)
		self:DreamNodeAction()
	elseif tag == BUTTON_TAG.LOOK_RULE  then
		app.uiMgr:ShowIntroPopup({moduleId = '-40'})
	elseif tag == BUTTON_TAG.LOOK_CIRCLR  then
		local mediator = require("Game.mediator.anniversary19.Anniversary19DreamCircleMediator").new({ isPassed  = false })
		app:RegistMediator(mediator)
		local viewComponent = self:GetViewComponent()
		viewComponent:HideCircleExtrenal()
		--self:DreamNodeAction()
	end
	PlayAudioByClickNormal()
end
function Anniversary19DreamCircleMainMediator:EnterLayer()
	---@type Anniversary19DreamCircleMainScene
	local viewComponent = self:GetViewComponent()
	if  self.exploreModuleId == 0 and ( self.battleType == 0 )   then
		self.exploreModuleId = anniversary2019Mgr:GetCurrentExploreModuleId()
		viewComponent:UpdateLeftAndRightImage( self.exploreModuleId)
		viewComponent:EnterSceneAction()
		self:UpdateDreamCircleStatusUI()
		app.anniversary2019Mgr:PlayBGMusic("Food_alice_dream")
	elseif self.battleType == TTGAME_DEFINE.BATTLE_TYPE.ANNIVERSARY   then
		self.exploreModuleId = anniversary2019Mgr:GetCurrentExploreModuleId()
		local prograss = anniversary2019Mgr:GetCurrentExploreProgress()
		if prograss > 7  then
			self.exploreModuleId = anniversary2019Mgr:GetCurrentExploreModuleId()
			self:SendSignal(POST.ANNIVERSARY2_EXPLORE_SECTION_BATTLE_CARD.cmdName , {exploreModuleId = self.exploreModuleId  })
		elseif prograss == 7  then
			local exploreData = anniversary2019Mgr:GetExploreData()
			local sectionData = exploreData.section or {}
			local result = checkint(sectionData[prograss].result)
			if result > 0  then
				self:SendSignal(POST.ANNIVERSARY2_EXPLORE_SECTION_BATTLE_CARD.cmdName , {exploreModuleId = self.exploreModuleId  })
			else
				viewComponent:UpdateLeftAndRightImage( self.exploreModuleId)
				viewComponent:EnterSceneAction()
				self:UpdateDreamCircleStatusUI()
				app.anniversary2019Mgr:PlayBGMusic("Food_alice_dream")
			end
		end
	else
		self:SendSignal(POST.ANNIVERSARY2_EXPLORE.cmdName , {exploreModuleId = self.exploreModuleId  })
	end
	viewComponent:UpdateFinallyLayout(self.exploreModuleId)
	anniversary2019Mgr:AddObserver()
end

function Anniversary19DreamCircleMainMediator:OnRegist()
	regPost(POST.ANNIVERSARY2_EXPLORE)
	regPost(POST.ANNIVERSARY2_EXPLORE_SECTION_GIVE_UP)
	regPost(POST.ANNIVERSARY2_EXPLORE_ENTER)
	regPost(POST.ANNIVERSARY2_EXPLORE_SECTION_BATTLE_CARD)
	regPost(POST.ANNIVERSARY2_STORY_UNLOCK)
	app:DispatchObservers(HomeScene_ChangeCenterContainer, "rightHide")
	app:DispatchObservers(HomeScene_ChangeCenterContainer, "allhide")
	self:EnterLayer()
end

function Anniversary19DreamCircleMainMediator:OnUnRegist()
	unregPost(POST.ANNIVERSARY2_EXPLORE)
	unregPost(POST.ANNIVERSARY2_EXPLORE_SECTION_GIVE_UP)
	unregPost(POST.ANNIVERSARY2_EXPLORE_ENTER)
	unregPost(POST.ANNIVERSARY2_EXPLORE_SECTION_BATTLE_CARD)
	unregPost(POST.ANNIVERSARY2_STORY_UNLOCK)
	app:DispatchObservers(HomeScene_ChangeCenterContainer, "rightShow")
	app:DispatchObservers(HomeScene_ChangeCenterContainer, "hide")
	app.uiMgr:GetCurrentScene():RemoveViewForNoTouch()
	local viewComponent = self:GetViewComponent()
	if viewComponent and(not tolua.isnull(viewComponent)) then
		viewComponent:setVisible(false)
		local viewData = viewComponent.viewData
		if viewData.doorSpine  and (not tolua.isnull(viewData.doorSpine))  then

			viewData.doorSpine:setToSetupPose()
		end
	end
end

return Anniversary19DreamCircleMainMediator

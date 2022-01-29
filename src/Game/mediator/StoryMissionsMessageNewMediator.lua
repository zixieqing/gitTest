local Mediator = mvc.Mediator

local StoryMissionsMessageNewMediator = class("StoryMissionsMessageNewMediator", Mediator)


local NAME = "StoryMissionsMessageNewMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")

local StoryMissionsCell = require('home.StoryMissionsCell')
function StoryMissionsMessageNewMediator:ctor(params, viewComponent )
	self.super:ctor(NAME,viewComponent)
	self.messLayout = nil
	if params then
		self.messLayout = params[1]
	end
	self.data = {} -- 任务数据
	self.storyType = 1 --任务类型：1是主线，2是支线
	self.taskType = 0
	self.jumpData = nil
end


function StoryMissionsMessageNewMediator:InterestSignals()
	local signals = {
		'Story_Create_Battle_Ready' ,
		"REFRESH_NOT_CLOSE_GOODS_EVENT"

	}

	return signals
end

function StoryMissionsMessageNewMediator:ProcessSignal(signal )
	local name = signal:GetName()
	-- print(name)
	-- dump(signal:GetBody())
	if 'Story_Create_Battle_Ready' == name then
		local questId = checkint(self.data.target.targetId[1]) -- 关卡id写死该字段的第一个元素
		if self.data.taskType == 4 or self.data.taskType == 6 or self.data.taskType == 7 then
			local battleReadyData = BattleReadyConstructorStruct.New(
				2,
				gameMgr:GetUserInfo().localCurrentBattleTeamId,
				gameMgr:GetUserInfo().localCurrentEquipedMagicFoodId,
				questId,
				CommonUtils.GetQuestBattleByQuestId(questId),
				nil,
				POST.QUEST_AT.cmdName,
				{questId = questId},
				POST.QUEST_AT.sglName,
				POST.QUEST_GRADE.cmdName,
				{questId = questId},
				POST.QUEST_GRADE.sglName,
				'HomeMediator',--self.args.isFrom or
				'HomeMediator'--self.args.isFrom or
			)
			AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.Battle_UI_Create_Battle_Ready, battleReadyData)
            GuideUtils.DispatchStepEvent()
			return
		end

		-- 13 14 类型
		--------------- 初始化战斗传参 ---------------
		local enterBattleRequestCommand = nil
		local enterBattleRequestData = {}
		local enterBattleResponseSignal = nil
		local exitBattleRequestCommand = nil
		local exitBattleRequestData = {}
		local exitBattleResponseSignal = nil
		local taskData = nil

		if 1 == self.storyType then
			-- 主线剧情任务
			taskData = self.data

			enterBattleRequestCommand = POST.PLOT_TASK_QUEST_AT.cmdName
			enterBattleRequestData = {
				plotTaskId = checkint(taskData.taskId),
				teamId = gameMgr:GetUserInfo().localCurrentBattleTeamId
			}
			enterBattleResponseSignal = POST.PLOT_TASK_QUEST_AT.sglName

			exitBattleRequestCommand = POST.PLOT_TASK_QUEST_GRADE.cmdName
			exitBattleRequestData = {
				plotTaskId = checkint(taskData.taskId)
			}
			exitBattleResponseSignal = POST.PLOT_TASK_QUEST_GRADE.sglName
		elseif 2 == self.storyType then
			-- 支线剧情任务
			taskData = self.data

			enterBattleRequestCommand = POST.BRANCH_QUEST_AT.cmdName
			enterBattleRequestData = {
				branchTaskId = checkint(taskData.taskId),
				teamId = gameMgr:GetUserInfo().localCurrentBattleTeamId
			}
			enterBattleResponseSignal = POST.BRANCH_QUEST_AT.sglName

			exitBattleRequestCommand = POST.BRANCH_QUEST_GRADE.cmdName
			exitBattleRequestData = {
				branchTaskId = checkint(taskData.taskId)
			}
			exitBattleResponseSignal = POST.BRANCH_QUEST_GRADE.sglName
		end

		local questId = checkint(taskData.target.targetId[1]) -- 关卡id写死该字段的第一个元素
		local questBattleType = CommonUtils.GetQuestBattleByQuestId(questId)

		local battleReadyData = BattleReadyConstructorStruct.New(
			QuestBattleType.MAP == questBattleType and 2 or 1,
			gameMgr:GetUserInfo().localCurrentBattleTeamId,
			gameMgr:GetUserInfo().localCurrentEquipedMagicFoodId,
			questId,
			CommonUtils.GetQuestBattleByQuestId(questId),
			nil,
			enterBattleRequestCommand,
			enterBattleRequestData,
			enterBattleResponseSignal,
			exitBattleRequestCommand,
			exitBattleRequestData,
			exitBattleResponseSignal,
			'HomeMediator',
			'HomeMediator'
		)
		--------------- 初始化战斗传参 ---------------

		AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.Battle_UI_Create_Battle_Ready, battleReadyData)
	elseif name == "REFRESH_NOT_CLOSE_GOODS_EVENT" then
		self:UpdataUi(self.data ,self.storyType )

	end
end


function StoryMissionsMessageNewMediator:Initial( key )
	self.super.Initial(self,key)
	local viewComponent  = require( 'Game.views.StoryMissionsMessageNewView' ).new()
	self:SetViewComponent(viewComponent)
    viewComponent:setName('Game.views.StoryMissionsMessageNewView')
	viewComponent:setAnchorPoint(cc.p(0.5, 0.5))
	viewComponent:setPosition(cc.p(self.messLayout:getContentSize().width* 0.5,self.messLayout:getContentSize().height* 0.5))
	self.messLayout:addChild(viewComponent)


	--绑定相关的事件
	viewComponent.viewData.goBtn:setOnClickScriptHandler(handler(self,self.ButtonActions))
end



--[[
刷新任务信息界面
--]]
function StoryMissionsMessageNewMediator:UpdataUi(data,storyType,showAcion)
	-- dump(data)
	self.data = {}
	self.data = data
	self.storyType = storyType or 1
	local view = self.viewComponent.viewData.view
	-- local npcImg = self.viewComponent.viewData.npcImg
	-- local npcNameLabel = self.viewComponent.viewData.npcNameLabel
	local descrContainer = self.viewComponent.viewData.descrContainer
	local desLabel = self.viewComponent.viewData.desLabel
	local targetLabel = self.viewComponent.viewData.targetLabel
	local progressLabel = self.viewComponent.viewData.progressLabel
	local rewardsLayout = self.viewComponent.viewData.rewardsLayout
	local goBtn = self.viewComponent.viewData.goBtn
	local mainExpLabel = self.viewComponent.viewData.mainExpLabel
	local tipsCardQ = self.viewComponent.viewData.tipsCardQ
	local reReadBtn = self.viewComponent.viewData.reReadBtn
	local bgSpine = self.viewComponent.viewData.bgSpine
	local targetDesLabel = self.viewComponent.viewData.targetDesLabel
	targetDesLabel:setVisible(false)
	bgSpine:setVisible(false)
	tipsCardQ:setVisible(false)

	local labelBtn = goBtn:getLabel()
	if data and next(data) ~= nil  then
		if data.mainExp then
			mainExpLabel:setString(string.fmt(('__num__'),{__num__ = data.mainExp}))
		end

		desLabel:setString(tostring(data.descr))
        local descrScrollTop = descrContainer:getViewSize().height - display.getLabelContentSize(desLabel).height
        descrContainer:setContentOffset(cc.p(0, descrScrollTop))

        local str = CommonUtils.GetStoryTargetDes(data)
		local taskTypeDescr = data.taskTypeDescr or ""
		str = string.format("%s%s",str , taskTypeDescr)
		targetLabel:setString(str)
		local progress = data.progress
		if data.taskType == 23 then
			progress = 1
		end

		if data.taskType == 12 or data.taskType == 16 then--对于上交材料任务类型特殊处理
			if checkint(data.status) == 3 then
				if checkint(gameMgr:GetAmountByGoodId(data.target.targetId[1])) < checkint(data.target.targetNum) then--本地检测道具数量够不够
					data.status = 2
					progress = checkint(gameMgr:GetAmountByGoodId(data.target.targetId[1]))
				end
			elseif data.status == 2  then
				if checkint(gameMgr:GetAmountByGoodId(data.target.targetId[1])) >= checkint(data.target.targetNum) then--本地检测道具数量够不够
					data.status = 3
				end
				progress = checkint(gameMgr:GetAmountByGoodId(data.target.targetId[1]))
			end
		end
		if checkint(data.status) == 2 then
			if data.progress then
				progressLabel:setString(string.fmt(('（__num1__/__num2__）'),{__num1__ = progress,__num2__ = data.target.targetNum or 1}))
			end
		elseif checkint(data.status) == 1 then--未接受任务
			if data.progress then
				progressLabel:setString(string.fmt(('（__num1__/__num2__）'),{__num1__ = 0,__num2__ = data.target.targetNum or 1}))
			end
		elseif checkint(data.status) == 3 then--已完成任务
			if data.progress then
				progressLabel:setString(string.fmt(('（__num1__/__num2__）'),{__num1__ = data.target.targetNum or 1,__num2__ = data.target.targetNum or 1}))
			end
		end

		if checkint(data.taskType) == 40 then
			progressLabel:setString('')
		end

		if data.rewards then
			rewardsLayout:removeAllChildren()
		 	rewardsLayout:setContentSize(cc.size(table.nums(data.rewards)*110,100))
			for i,v in ipairs(data.rewards) do
				local function callBack(sender)
					AppFacade.GetInstance():GetManager("UIManager"):ShowInformationTipsBoard({targetNode = sender, iconId = v.goodsId, type = 1})
				end

				local goodsNode = require('common.GoodNode').new({id = v.goodsId, amount = v.num, showAmount = true,callBack = callBack})
				goodsNode:setAnchorPoint(cc.p(0.5,0.5))
				goodsNode:setPosition(cc.p(50+105*(i-1),rewardsLayout:getContentSize().height*0.5))
				goodsNode:setScale(0.75)
				rewardsLayout:addChild(goodsNode, 5)
			end
		end

		if data.hasDrawn == 0 then
			if data.isActivation == true then
				if checkint(data.status) == 1 then--未接受任务
					bgSpine:setVisible(true)
					targetDesLabel:setVisible(true)
					-- bgSpine:setToSetupPose()
					bgSpine:setAnimation(0, 'idle', false)
					labelBtn:setString(__('接受任务'))
				elseif checkint(data.status) == 2 then--未完成任务
					if showAcion then
						bgSpine:setVisible(true)
						-- bgSpine:setToSetupPose()
						bgSpine:setAnimation(0, 'attack', false)
						targetDesLabel:setVisible(false)
						bgSpine:registerSpineEventHandler(function (event)
							-- bgSpine:setToSetupPose()
							if event.animation == 'attack' then
								bgSpine:setAnimation(0, 'idle', false)
								bgSpine:setVisible(false)
							end
						end,sp.EventType.ANIMATION_COMPLETE)
					end
					labelBtn:setString(__('前往'))
				elseif checkint(data.status) == 3 then--已完成任务
					labelBtn:setString(__('领取'))
				end
	 			goBtn:setNormalImage(_res('ui/common/common_btn_orange.png'))
	 			goBtn:setSelectedImage(_res('ui/common/common_btn_orange.png'))
			else
				bgSpine:setVisible(true)
				targetDesLabel:setVisible(true)
				labelBtn:setString(__('未激活'))
	 			goBtn:setNormalImage(_res('ui/common/common_btn_orange_disable.png'))
	 			goBtn:setSelectedImage(_res('ui/common/common_btn_orange_disable.png'))
			end
		else
			labelBtn:setString(__('已完成'))
		end
		view:setVisible(true)
		reReadBtn:setVisible(false)
		-- dump(self.data.story.accept)
		-- if checkint(self.data.story.accept) ~= 0 then
		-- 	reReadBtn:setVisible(true)
	 --        reReadBtn:setOnClickScriptHandler(function(sender)
		-- 		local path = (string.format("conf/%s/quest/questStory.json",i18n.getLang()))
		-- 		if self.storyType == 2 then
		-- 			path  = (string.format("conf/%s/quest/branchStory.json",i18n.getLang()))
		-- 		end
		-- 		local stage = require( "Frame.Opera.OperaStage" ).new({id = self.data.story.accept,path = path, isHideBackBtn = true})
		-- 		stage:setPosition(cc.p(display.cx,display.cy))
  --               sceneWorld:addChild(stage, GameSceneTag.Dialog_GameSceneTag)
	 --        end)
	 --    end
	else
		-- dump(data)
		view:setVisible(false)
		tipsCardQ:setVisible(true)

		rewardsLayout:removeAllChildren()
	end

end
--展示显示任务条件动画
function StoryMissionsMessageNewMediator:ShowAction()
	self.viewComponent.viewData.targetDesLabel:setVisible(false)
	self.viewComponent:runAction(
		cc.CallFunc:create(function ()
			self.viewComponent.viewData.bgSpine:setVisible(true)
			self.viewComponent.viewData.bgSpine:setAnimation(0, 'attack', false)

			self.viewComponent.viewData.bgSpine:registerSpineEventHandler(function (event)
				if event.animation == 'attack' then
					self.viewComponent.viewData.bgSpine:setAnimation(0, 'idle', false)
					self.viewComponent.viewData.bgSpine:setVisible(false)
				end
			end,sp.EventType.ANIMATION_COMPLETE)
		end))
end

--前往跳转部分实现在appMediator实现
function StoryMissionsMessageNewMediator:goModelLayer( taskType )
	-- dump(taskType)
	if taskType == 4 then
		AppFacade.GetInstance():DispatchObservers('Story_Create_Battle_Ready')

	elseif taskType == 6 then
		--消灭在_target_id_中盘踞着的_target_id_
		AppFacade.GetInstance():DispatchObservers('Story_Create_Battle_Ready')
	elseif taskType == 7 then
		AppFacade.GetInstance():DispatchObservers('Story_Create_Battle_Ready')
	elseif taskType == 8 then
		--与_target_id_的_target_id_对话
		AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.REFRESH_HOMEMAP_STORY_LAYER)
	elseif taskType == 9 then
		AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.REFRESH_HOMEMAP_STORY_LAYER)
	elseif taskType == 13 then
		--击败_target_id_
		AppFacade.GetInstance():DispatchObservers('Story_Create_Battle_Ready')
	elseif taskType == 14 then
		--挑战_target_id_
		AppFacade.GetInstance():DispatchObservers('Story_Create_Battle_Ready')

	elseif taskType == 37 or taskType == 12 then
		-- 获得_target_num__target_id_
		-- dump(self.data)
		if self.data.target.targetId[1] then
			uiMgr:AddDialog("common.GainPopup", {goodId =  self.data.target.targetId[1],isFrom = 'StoryMissionsMediator'})
		end
	elseif taskType == 59  then
		AppFacade.GetInstance():RetrieveMediator('Router'):Dispatch({name = NAME}, {name = 'privateRoom.PrivateRoomHomeMediator'})
	end
	if taskType ~= 37 and taskType ~= 12 then
		AppFacade.GetInstance():UnRegsitMediator("StoryMissionsMediator")
	end
	-- if AppFacade.GetInstance():RetrieveMediator("StoryMissionsMessageMediator") then
	-- 	AppFacade.GetInstance():UnRegsitMediator("StoryMissionsMessageMediator")
	-- end
	-- self:GetFacade():UnRegsitMediator("StoryMissionsMediator")
end

--[[
@param taskTyp int
判断是否
--]]
function StoryMissionsMessageNewMediator:goLayer( taskType )
	if checkint(self.data.story.pass) ~= 0 then--
		local path = (string.format("conf/%s/quest/questStory.json",i18n.getLang()))
		if self.storyType == 2 then
			path  = (string.format("conf/%s/quest/branchStory.json",i18n.getLang()))
		end
		local stage = require( "Frame.Opera.OperaStage" ).new({id = self.data.story.pass,path = path, isHideBackBtn = true,cb = function(tag)
			if tag == 3006 or tag == 3007 then
				--执行下一步
				self.taskType = taskType
				self.jumpData = self.data
				if  taskType == 8 or taskType == 9 or taskType == 13 or self.taskType == 37 or taskType == 14
				 or taskType == 4 or taskType == 6 or taskType == 7 or taskType == 12 then
					self:goModelLayer(taskType)
				else
					AppFacade.GetInstance():UnRegsitMediator("StoryMissionsMediator")
				end
			end
		end})
		stage:setPosition(cc.p(display.cx,display.cy))
        sceneWorld:addChild(stage, GameSceneTag.Dialog_GameSceneTag)
	else
		self.jumpData = self.data
		self.taskType = taskType
		if  taskType == 8 or taskType == 9 or taskType == 13 or self.taskType == 37 or taskType == 14
		 or taskType == 4 or taskType == 6 or taskType == 7 or taskType == 12 or taskType == 59  then
			self:goModelLayer(taskType)
		else
			AppFacade.GetInstance():UnRegsitMediator("StoryMissionsMediator")
		end
	end
end

--[[
前往
@param sender button对象
--]]
function StoryMissionsMessageNewMediator:ButtonActions( sender )
	-- print('ButtonActions')
	-- dump(self.data)
    PlayAudioByClickNormal()
	if not self.data then
		return
	end
	if self.data.isActivation == true then

		if self.data.hasDrawn == 0 then
			if checkint(self.data.status) == 1 then--未接受任务
				if checkint(self.data.id) == 1 or GuideUtils.CheckIsFinishedStorytPlot1() then
					self:GetFacade():DispatchObservers(Story_AcceptMissions)
				end
			elseif checkint(self.data.status) == 2 then--未完成任务
				self:goLayer(self.data.taskType)
			elseif checkint(self.data.status) == 3 then--已完成任务
				self:GetFacade():DispatchObservers(Story_DrawMissions)
			end
		else
			uiMgr:ShowInformationTips(__('已完成任务'))
		end
	else
		-- dump('**************** 还没有激活 ****************')
		local typeInfos = CommonUtils.GetConfigAllMess('unlockType')
		local unlockType = self.data.unlockType or {}
		for k,v in pairs(unlockType) do
			if checkint(k) ~= UnlockTypes.TASK_QUEST then
				local str =  string.fmt(typeInfos[k],{_target_num_ = v.targetNum})
				uiMgr:ShowInformationTips(str)
			end
		end
	end
end

function StoryMissionsMessageNewMediator:OnRegist(  )
	-- self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "allhide")
end

function StoryMissionsMessageNewMediator:OnUnRegist(  )
	--称出命令
	-- dump(self.taskType)
	-- local scene = uiMgr:GetCurrentScene()
	-- scene:RemoveDialog(self.viewComponent)
	if self.taskType ~= 8 or self.taskType ~= 9 or self.taskType ~= 13 or self.taskType ~= 14 or self.taskType ~= 37
		or taskType  ~=4 or taskType  ~= 6 or taskType  ~= 7 or taskType ~= 12  or self.taskType ~= 0  then
		AppFacade.GetInstance():DispatchObservers(Event_Story_Missions_Jump,self.jumpData)
	end
end

return StoryMissionsMessageNewMediator

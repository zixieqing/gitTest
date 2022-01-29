local Mediator = mvc.Mediator

local StoryMissionsMessageMediator = class("StoryMissionsMessageMediator", Mediator)


local NAME = "StoryMissionsMessageMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")

local StoryMissionsCell = require('home.StoryMissionsCell')
function StoryMissionsMessageMediator:ctor(params, viewComponent )
	self.super:ctor(NAME,viewComponent)
	self.messLayout = nil
	if params then
		self.messLayout = params[1] 
	end
	self.data = {} -- 任务数据
	self.storyType = 1 --任务类型：1是主线，2是支线
end


function StoryMissionsMessageMediator:InterestSignals()
	local signals = {
		'Story_Create_Battle_Ready'
	}

	return signals
end

function StoryMissionsMessageMediator:ProcessSignal(signal )
	local name = signal:GetName() 
	print(name)
	-- dump(signal:GetBody())
	if 'Story_Create_Battle_Ready' == name then

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
	end
end


function StoryMissionsMessageMediator:Initial( key )
	self.super.Initial(self,key)
	local viewComponent  = require( 'Game.views.StoryMissionsMessageView' ).new()
	self:SetViewComponent(viewComponent)
	if self.messLayout then
		viewComponent:setAnchorPoint(cc.p(0.5, 0.5))
		viewComponent:setPosition(cc.p(self.messLayout:getContentSize().width* 0.5,self.messLayout:getContentSize().height* 0.5))
		self.messLayout:addChild(viewComponent)
		viewComponent.eaterLayer:setVisible(false)
	else
		local scene = uiMgr:GetCurrentScene()
		viewComponent:setPosition(display.center)
		scene:AddDialog(viewComponent)

		viewComponent:setContentSize(display.size)
		viewComponent.viewData.view:setPosition(utils.getLocalCenter(viewComponent))
		viewComponent.viewData.view:setAnchorPoint(cc.p(0.5,0.5))
		viewComponent.viewData.bg:setTexture(_res('ui/common/common_bg_12.png'))
		viewComponent.eaterLayer:setVisible(true)

		viewComponent.eaterLayer:setOnClickScriptHandler(function (sender)
			self:GetFacade():UnRegsitMediator("StoryMissionsMessageMediator")			
		end)
	end


	--绑定相关的事件
	viewComponent.viewData.goBtn:setOnClickScriptHandler(handler(self,self.ButtonActions))
	-- self:UpdataUi(data)
end

--[[
刷新任务信息界面
--]]
function StoryMissionsMessageMediator:UpdataUi(data,storyType)
	-- dump(data)	
	self.data = {} 
	self.data = data
	self.storyType = storyType or 1
	local view = self.viewComponent.viewData.view
	local npcImg = self.viewComponent.viewData.npcImg
	local npcNameLabel = self.viewComponent.viewData.npcNameLabel
	local desLabel = self.viewComponent.viewData.desLabel
	local targetLabel = self.viewComponent.viewData.targetLabel
	local progressLabel = self.viewComponent.viewData.progressLabel
	local rewardsLayout = self.viewComponent.viewData.rewardsLayout
	local goBtn = self.viewComponent.viewData.goBtn
	local mainExpLabel = self.viewComponent.viewData.mainExpLabel
	local tipsCardQ = self.viewComponent.viewData.tipsCardQ
	tipsCardQ:setVisible(false)

	local labelBtn = goBtn:getLabel()
	if data and next(data) ~= nil  then
		if data.mainExp then
			mainExpLabel:setString(string.fmt(__('主角经验+__num__'),{__num__ = data.mainExp}))
		end
		npcImg:setTexture(CommonUtils.GetNpcIconPathById(data.roleId,3))
		if not string.find(data.roleId, 'role_') then
			data.roleId = 'role_1'
		end
		npcNameLabel:setString(CommonUtils.GetConfig('quest', 'role', data.roleId).roleName)
		desLabel:setString(tostring(data.descr))
		local str = CommonUtils.GetStoryTargetDes(data)
		targetLabel:setString(str)
		progressLabel:setPositionX(targetLabel:getBoundingBox().width + 4)

		
		local progress = data.progress
		if data.taskType == 23 then
			progress = 1
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

		if data.taskType == 12 or data.taskType == 16 then--对于上交材料任务类型特殊处理
			if checkint(data.status) == 3 then
				if checkint(gameMgr:GetAmountByGoodId(data.target.targetId[1])) < checkint(data.target.targetNum) then--本地检测道具数量够不够
					data.status = 2
				end
			end
		end

		if data.rewards then
			rewardsLayout:removeAllChildren()
			-- if data.mainExp then
			-- 	local tempTab = {goodsId = EXP_ID,num = checkint(data.mainExp)}
			-- 	table.insert(data.rewards,tempTab)
			-- end
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
					labelBtn:setString(__('接受任务'))
				elseif checkint(data.status) == 2 then--未完成任务
					labelBtn:setString(__('前往'))
				elseif checkint(data.status) == 3 then--已完成任务
					labelBtn:setString(__('领取'))
				end
			else
				labelBtn:setString(__('未激活'))
			end
		else
			labelBtn:setString(__('已完成'))
		end
		view:setVisible(true)
	else
		dump(data)
		view:setVisible(false)
		tipsCardQ:setVisible(true)

		-- npcNameLabel:setString('npc名字')
		-- desLabel:setString('任务描述')
		-- targetLabel:setString('任务目标')	
		rewardsLayout:removeAllChildren()	
	end
	
end


function StoryMissionsMessageMediator:goModelLayer( taskType )
	dump(taskType)
	if taskType == 1 then
		-- 在大堂招待_target_num_位客人
		-- AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'StoryMissionsMediator'},{name = 'BusinessMediator' })--,params = {x = 'StoryMissionsMediator'}	
		AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = "StoryMissionsMessageMediator"}, {name = "AvatarMediator"})
	elseif taskType == 2 then
		-- 在消灭_target_num_只_target_id_
		AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'StoryMissionsMessageMediator'},{name = 'MapMediator' })--,params = {x = 'StoryMissionsMediator'}
	elseif taskType == 3 then	
		--完成_target_id_地区的_target_num_个外卖订单	
		AppFacade.GetInstance():UnRegsitMediator("StoryMissionsMessageMediator")
	elseif taskType == 4 then	
		--通过关卡_target_id_
		AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'StoryMissionsMessageMediator'},{name = 'MapMediator' })--,params = {x = 'StoryMissionsMediator'} 
	elseif taskType == 5 then	
		--完成_target_num_个公众外卖订单
		AppFacade.GetInstance():UnRegsitMediator("StoryMissionsMessageMediator")
	elseif taskType == 6 then	
		--消灭在_target_id_中盘踞着的_target_id_
		AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'StoryMissionsMessageMediator'},{name = 'MapMediator' })--,params = {x = 'StoryMissionsMediator'} 
	elseif taskType == 7 then	
		AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'StoryMissionsMessageMediator'},{name = 'MapMediator' })--,params = {x = 'StoryMissionsMediator'} 
	elseif taskType == 8 then	
		--与_target_id_的_target_id_对话	
		AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.REFRESH_HOMEMAP_STORY_LAYER)
		AppFacade.GetInstance():UnRegsitMediator("StoryMissionsMessageMediator")
	elseif taskType == 9 then
		AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.REFRESH_HOMEMAP_STORY_LAYER)
		AppFacade.GetInstance():UnRegsitMediator("StoryMissionsMessageMediator")
	elseif taskType == 10 then
		--在周围打探一下消息
		AppFacade.GetInstance():UnRegsitMediator("StoryMissionsMessageMediator")
	elseif taskType == 11 then	
		--帮助_target_id_完成心愿
		AppFacade.GetInstance():UnRegsitMediator("StoryMissionsMessageMediator")
	elseif taskType == 12 then
		--收集_target_num_个_target_id_
		AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'StoryMissionsMessageMediator'},{name = 'MapMediator'  })--,params = {x = 'StoryMissionsMediator'}
	elseif taskType == 13 then	
		--击败_target_id_
		AppFacade.GetInstance():DispatchObservers('Story_Create_Battle_Ready')
		-- AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'StoryMissionsMessageMediator'},{name = 'MapMediator',params = {x = 'StoryMissionsMediator'}  })
	elseif taskType == 14 then	
		--挑战_target_id_	
		AppFacade.GetInstance():DispatchObservers('Story_Create_Battle_Ready')
		--AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'StoryMissionsMessageMediator'},{name = 'MapMediator',params = {x = 'StoryMissionsMediator'}  })
	elseif taskType == 15 then
		--制作_target_num_道料理
		AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'StoryMissionsMessageMediator'},{name = 'RecipeResearchAndMakingMediator' })--,params = {x = 'StoryMissionsMediator'}
	elseif taskType == 16 then	
		--制作_target_num_道_target_id_
		AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'StoryMissionsMessageMediator'},{name = 'RecipeResearchAndMakingMediator' })--,params = {x = 'StoryMissionsMediator'}
	elseif taskType == 17 then	
		--将_target_id_的等级提升至_target_num_级 
		AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'StoryMissionsMessageMediator'},{name = 'CardsListMediatorNew'})--,params = {x = 'StoryMissionsMediator'}
	elseif taskType == 18 then	
		--将_target_id_的阶位提升至_target_num_星 
		AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'StoryMissionsMessageMediator'},{name = 'CardsListMediatorNew'})--,params = {x = 'StoryMissionsMediator'}
	elseif taskType == 19 then
		--激活技能_target_id_	 
		AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'StoryMissionsMessageMediator'},{name = 'TalentMediator'})--,params = {x = 'StoryMissionsMediator'} 
	elseif taskType == 20 then		
		--装备技能_target_id_进行战斗 
		AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'StoryMissionsMessageMediator'},{name = 'MapMediator' })--,params = {x = 'StoryMissionsMediator'} 
	elseif taskType == 21 then
		--强化任意天赋技能_target_num_次 
		AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'StoryMissionsMessageMediator'},{name = 'TalentMediator'})-- ,params = {x = 'StoryMissionsMediator'}
	elseif taskType == 22 then
		--"完成_target_num_次打劫" 
		AppFacade.GetInstance():UnRegsitMediator("StoryMissionsMediator")	
	elseif taskType == 23 then
		--研发_target_num_个新的菜谱
		AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'StoryMissionsMessageMediator'},{name = 'RecipeResearchAndMakingMediator' })--,params = {x = 'StoryMissionsMediator'}
	elseif taskType == 24 then
		--"将任意菜谱改良至_target_num_星
		AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'StoryMissionsMessageMediator'},{name = 'RecipeResearchAndMakingMediator' })--,params = {x = 'StoryMissionsMediator'}
	elseif taskType == 25 then
		--在冰场内放入任意_target_num_张卡牌
		AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'StoryMissionsMessageMediator'},{name = 'IceRoomMediator' })
	elseif taskType == 26 then
		AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'StoryMissionsMessageMediator'},{name = 'task.TaskHomeMediator' })
	elseif taskType == 27 then
		AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'StoryMissionsMessageMediator'},{name = 'MapMediator' })--,params = {x = 'StoryMissionsMediator'} 
	elseif taskType == 28 then
		AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'StoryMissionsMessageMediator'},{name = 'MapMediator' })--,params = {x = 'StoryMissionsMediator'} 
	-- elseif taskType == 29 then

	elseif taskType == 30 then
		AppFacade.GetInstance():UnRegsitMediator("StoryMissionsMessageMediator")	
	elseif taskType == 31 then
		-- 	前往_target_id_远征
		AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = "StoryMissionsMessageMediator"}, {name = "ExplorationMediator"})
	elseif taskType == 32 then
		-- 前往_target_id_寻找_target_id_
		AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = "StoryMissionsMessageMediator"}, {name = "ExplorationMediator"})
	elseif taskType == 33 then
		-- 前往_target_id_击败_target_id_
		AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = "StoryMissionsMessageMediator"}, {name = "ExplorationMediator"})
	elseif taskType == 34 then
		-- 在餐厅招待_target_num_位特需客人
        AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = "StoryMissionsMessageMediator"}, {name = "AvatarMediator"})
	elseif taskType == 35 then
		-- 提升餐厅规模至_target_id_
        AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = "StoryMissionsMessageMediator"},{name = "AvatarMediator"})
	elseif taskType == 36 then
		-- 改良_target_num_次任意菜品
		AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'StoryMissionsMessageMediator'},{name = 'RecipeResearchAndMakingMediator' })
	elseif taskType == 37 then
		-- 获得_target_num__target_id_
		if self.data.target.targetId[1] then
			uiMgr:AddDialog("common.GainPopup", {goodId =  self.data.target.targetId[1] })
		else
			AppFacade.GetInstance():UnRegsitMediator("StoryMissionsMessageMediator")
		end
	elseif taskType == 38 then
		-- 升级_target_id_的任意战斗技能_target_num_次
		AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'StoryMissionsMessageMediator'},{name = 'CardsListMediatorNew'})
	elseif taskType == 39 then
		-- 研究菜谱_target_num_次
		AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'StoryMissionsMessageMediator'},{name = 'RecipeResearchAndMakingMediator' })
	elseif taskType == 40 then
		-- 提升_target_id_或_target_id_或_target_id_的评价至_target_id_级
		AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'StoryMissionsMessageMediator'},{name = 'RecipeResearchAndMakingMediator' })
	elseif taskType == 41 then
		-- 购买_target_num_个_target_id_
		AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = "StoryMissionsMessageMediator"}, {name = "MarketMediator"})
	elseif taskType == 42 then
		-- 装饰餐厅时放置_target_num_个_target_id_
		AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = "StoryMissionsMessageMediator"},{name = "AvatarMediator"})
	elseif taskType == 43 then
		AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'StoryMissionsMessageMediator'},{name = 'RecipeResearchAndMakingMediator' })
	else
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
function StoryMissionsMessageMediator:goLayer( taskType )
	if checkint(self.data.story.pass) ~= 0 then-- 
		local path = (string.format("conf/%s/quest/questStory.json",i18n.getLang()))
		if self.storyType == 2 then
			path  = (string.format("conf/%s/quest/branchStory.json",i18n.getLang()))
		end
		local stage = require( "Frame.Opera.OperaStage" ).new({id = self.data.story.pass,path = path, isHideBackBtn = true,cb = function(tag)
			if tag == 3006 or tag == 3007 then
				--执行下一步
				self:goModelLayer(taskType)
			end
		end})
		stage:setPosition(cc.p(display.cx,display.cy))
        sceneWorld:addChild(stage, GameSceneTag.Dialog_GameSceneTag)
	else
		self:goModelLayer(taskType)
	end
end

--[[
前往
@param sender button对象
--]]
function StoryMissionsMessageMediator:ButtonActions( sender )
	-- print('ButtonActions')
	dump(self.data)
	if not self.data then
		return
	end
	if self.data.isActivation == true then
		
		if self.data.hasDrawn == 0 then
			if checkint(self.data.status) == 1 then--未接受任务
				self:GetFacade():DispatchObservers(Story_AcceptMissions)
			elseif checkint(self.data.status) == 2 then--未完成任务
				xTry(function()
					self:goLayer(self.data.taskType)
				end,__G__TRACKBACK__)
			elseif checkint(self.data.status) == 3 then--已完成任务
				self:GetFacade():DispatchObservers(Story_DrawMissions)
			end
		else
			uiMgr:ShowInformationTips(__('已完成任务'))
		end
	else
		-- dump('**************** 还没有激活 ****************')
		local typeInfos = CommonUtils.GetConfigAllMess('unlockType')
		for k,v in pairs(self.data.unlockType) do
			if checkint(k) ~= UnlockTypes.TASK_QUEST then
				local str =  string.fmt(typeInfos[k],{_target_num_ = v.targetNum})
				uiMgr:ShowInformationTips(str)
			end
		end		
	end
end

function StoryMissionsMessageMediator:OnRegist(  )
	-- self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "allhide")
end

function StoryMissionsMessageMediator:OnUnRegist(  )
	--称出命令
	local scene = uiMgr:GetCurrentScene()
	scene:RemoveDialog(self.viewComponent)
end

return StoryMissionsMessageMediator

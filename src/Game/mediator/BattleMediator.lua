--[[
战斗控制器
@params battleConstructor BattleConstructor 战斗构造器
}
--]]
local Mediator = mvc.Mediator
local BattleMediator = class("BattleMediator", Mediator)
local NAME = "BattleMediator"

------------ import ------------
------------ import ------------

------------ define ------------
------------ define ------------

function BattleMediator:ctor( params, viewComponent )
	Mediator.ctor(self, NAME, viewComponent)

	self.battleConstructor = params
end

---------------------------------------------------
-- mediator extend begin --
---------------------------------------------------
function BattleMediator:InterestSignals()
	local signals = {
		'BATTLE_SCENE_CREATE_OVER',
		'BATTLE_GAME_OVER',
		'BATTLE_BUY_REVIVE_REQUEST',
		'BATTLE_RESTART',
		'BATTLE_BACK_TO_PREVIOUS',
		'FORCE_EXIT_BATTLE',
		'BATTLE_FORCE_BREAK',
		APP_ENTER_BACKGROUND
	}
	return signals
end

function BattleMediator:Initial( key )
	Mediator.Initial(self, key)

	-- 初始化战斗管理器
	self:InitBattleManager()
	-- 初始化网络管理器
	self:InitBattleNetworkMediator()
end
function BattleMediator:OnRegist()
    funLog(Logger.INFO, 'hey here start init battle scene!'.. tostring(os.clock()))
    if DEBUG_MEM then
		funLog(Logger.DEBUG, "----------------------------------------")
        funLog(Logger.DEBUG,string.format("LUA VM MEMORY USED: %0.2f KB", collectgarbage("count")))
        -- cc.Director:getInstance():getTextureCache():getCachedTextureInfo()
        funLog(Logger.DEBUG,"----------------------------------------")
    end

	if not self.battleConstructor:IsReplay() then
		-- 进入战斗
		self.battleManager:EnterBattle()
	end
end
function BattleMediator:OnUnRegist()
	-- 移除战斗音效
	app.audioMgr:RemoveCueSheet(AUDIOS.BATTLE.name)
	app.audioMgr:RemoveCueSheet(AUDIOS.BATTLE2.name)
	-- 45帧
	cc.Director:getInstance():setAnimationInterval(1 / 45)
    PlayBGMusic()
    self.battleManager = nil
end
---------------------------------------------------
-- mediator extend end --
---------------------------------------------------

---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
初始化战斗管理器
--]]
function BattleMediator:InitBattleManager()
	if nil == self.battleManager then
		if self.battleConstructor:IsReplay() then
			self.battleManager = __Require('battle.manager.BattleManager_Replay').new({battleConstructor = self.battleConstructor})
		else
			self.battleManager = __Require('battle.manager.BattleManager').new({battleConstructor = self.battleConstructor})
		end
	end
end
--[[
初始化网络管理器
--]]
function BattleMediator:InitBattleNetworkMediator()
	self.battleNetworkMdt = AppFacade.GetInstance():RetrieveMediator('BattleNetworkMediator')
	if nil == self.battleNetworkMdt then
		local BattleNetworkMediator = require('battleEntry.network.BattleNetworkMediator')
		self.battleNetworkMdt = BattleNetworkMediator.new()
		AppFacade.GetInstance():RegistMediator(self.battleNetworkMdt)
	end
end
--[[
获取网络管理器
--]]
function BattleMediator:GetNetworkMdt()
	return self.battleNetworkMdt
end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- logic control begin --
---------------------------------------------------
--[[
处理信号
--]]
function BattleMediator:ProcessSignal(signal)
	local name = signal:GetName()
	local data = signal:GetBody()

	if 'BATTLE_SCENE_CREATE_OVER' == name then

		self:BattleSceneCreateOverAndStart(data)

	elseif 'BATTLE_GAME_OVER' == name then

		self:GameOver(data)

	elseif 'BATTLE_BUY_REVIVE_REQUEST' == name then

		self:BuyRevive(data)

	elseif 'BATTLE_RESTART' == name then

		self:RestartGame(data)

	elseif 'BATTLE_BACK_TO_PREVIOUS' == name then

		self:BackToPrevious(data.questBattleType, data.isPassed, data.battleConstructor)

	elseif 'FORCE_EXIT_BATTLE' == name then

		-- 强制退出战斗 !!! 强制 !!! 不讲道理的那种
		self:ForceExitBattle()

	elseif 'BATTLE_FORCE_BREAK' == name then

		-- 强制杀掉战斗 不带跳转 只是杀掉逻辑
		self:KillBattle()

	elseif APP_ENTER_BACKGROUND == name then

		self:AppEnterBackgroundCallback()

	end
end
--[[
场景创建完毕 开始战斗
@params data table {
	battleScene  cc.Node 战斗场景实例
}
--]]
function BattleMediator:BattleSceneCreateOverAndStart(data)
	self.battleManager:LoadingOverAndInitBattleLogic(data)
end
--[[
战斗结束 -> 胜利
@params data {
	battleConstructor = nil,
	callback = nil
}
--]]
function BattleMediator:GameOver(data)
	self:GetNetworkMdt():ReadyToExitBattle(
		data.battleConstructor, data.callback
	)
end
--[[
买活
@params data {
	requestCommand 请求的命令
	responseSignal 返回的信号
	requestData 请求的参数
	callback function 回调函数
}
--]]
function BattleMediator:BuyRevive(data)
	self:GetNetworkMdt():CommonNetworkRequest(
		data.requestCommand,
		data.responseSignal,
		data.requestData,
		data.callback
	)
end
--[[
重开游戏
@params data {
	battleConstructor = nil,
	callback = nil
}
--]]
function BattleMediator:RestartGame(data)
	self:GetNetworkMdt():ReadyToEnterBattle(
		data.battleConstructor,
		data.callback
	)
end
--[[
进入后台 处理一些东西
--]]
function BattleMediator:AppEnterBackgroundCallback()
	if not BattleConfigUtils.IsAppEnterBackgroundPauseGame() then return end
	if nil ~= self.battleManager then
		self.battleManager:AppEnterBackground()
	end
end
--[[
安卓返回键处理
--]]
function BattleMediator:GoogleBack()
	if not BattleConfigUtils.IsGoogleBackQuitBattleEnable() then return end
	if nil ~= self.battleManager then
		if G_BattleRenderMgr:GetBattleGuideConfigByStageId() then
			app.uiMgr:ShowInformationTips('Do not pause in the new guide ')
		else
			self.battleManager:GoogleBack()
		end
	end
end
---------------------------------------------------
-- logic control end --
---------------------------------------------------

---------------------------------------------------
-- back control begin --
---------------------------------------------------
--[[
退出战斗 返回上一个界面
@params questBattleType QuestBattleType 战斗类型
@params isPassed PassedBattle 是否通过了战斗
@params battleConstructor BattleConstructor 战斗构造器
--]]
function BattleMediator:BackToPrevious(questBattleType, isPassed, battleConstructor)
	-- 发送一次战斗结果数据
	self:BroadcastBattleResult(battleConstructor:GetStageId(), questBattleType, isPassed)

	local jumpConfig = {
		-- 地图战斗 -> map
		[QuestBattleType.MAP] = {functionName = 'BackToMap'},
		-- 主线和支线 -> 主界面
		[QuestBattleType.PLOT] = {functionName = 'BackToHome'},
		-- 霸王餐战斗 -> 餐厅
		[QuestBattleType.LOBBY] = {functionName = 'BackToRestaurant'},
		-- 探索战斗 -> 探索home
		[QuestBattleType.EXPLORE] = {functionName = 'BackToExploreHome'},
		-- 爬塔战斗 -> 爬塔home
		[QuestBattleType.TOWER] = {functionName = 'BackToTowerHome'},
		-- 演示战斗 -> 接下一步新手逻辑
		[QuestBattleType.PERFORMANCE] = {functionName = 'BackToNormal'},
		-- 打劫 -> 主界面
		[QuestBattleType.ROBBERY] = {functionName = 'BackToHome'},
		-- 打神兽 -> 神兽界面
		[QuestBattleType.UNION_BEAST] = {functionName = 'BackToUnionHunt'},
		-- 工会派对 -> 工会派对界面
		[QuestBattleType.UNION_PARTY] = {functionName = 'BackToUnionParty'},
		-- 世界boss -> 世界bosshome
		[QuestBattleType.WORLD_BOSS] = {functionName = 'BackToWorldBoss'},
		-- 活动副本 -> 活动副本主页
		[QuestBattleType.ACTIVITY_QUEST] = {functionName = 'BackToActivityQuestHome'},
		-- 天成演武 -> 天城演武主页
		[QuestBattleType.TAG_MATCH_3V3] = {functionName = GAME_MODULE_OPEN.NEW_TAG_MATCH and 'BackToNewTagMatchLobby' or 'BackToTagMatchLobby'},
		-- 神器任务 -> 神器界面
		[QuestBattleType.ARTIFACT_QUEST] = {functionName = 'BackToArtifact'},
		-- 季活 -> 季活主页
		[QuestBattleType.SEASON_EVENT] = {functionName = 'BackToSeasonActivity'},
		-- 萌战 -> 萌战
		[QuestBattleType.SAIMOE] = {functionName = 'BackToSaiMoe'},
		-- 周年庆 -> 周年庆
		[QuestBattleType.ANNIVERSARY_EVENT] = {functionName = 'BackAniversary'},
		-- 神器之路 -> 神器之路
		[QuestBattleType.ARTIFACT_ROAD] = {functionName = 'BackToArtifactRoad'},
		-- PT副本 -> pt副本界面
		[QuestBattleType.PT_DUNGEON] = {functionName = 'BackToPTDungeon'},
		-- 新春活 -> 新春活
		[QuestBattleType.NEW_SPRING_EVENT] = {functionName = 'BackNewSpringAction'},
		-- 巅峰对决 -> 巅峰对决
		[QuestBattleType.ULTIMATE_BATTLE] = {functionName = 'BackToUltimateBattle'},
		-- 皮肤嘉年华 -> 皮肤嘉年华
		[QuestBattleType.SKIN_CARNIVAL] = {functionName = 'BackToSkinCarnival'},
		-- 童话世界/2019周年庆 -> 童话世界/2019周年庆
		[QuestBattleType.WONDERLAND] = {functionName = 'BackToAnniversary19'},
		-- 好友切磋 -> 好友切磋
		[QuestBattleType.FRIEND_BATTLE] = {functionName = 'BackToFriendBattle'},
		-- 20春活 -> 20春活
		[QuestBattleType.SPRING_ACTIVITY_20] = {functionName = 'BackToSpringActivity20'},
		-- 武道会 -> 武道会-海选赛
		[QuestBattleType.CHAMPIONSHIP_AUDITIONS] = {functionName = 'BackToChampionship'},
		-- 武道会 -> 武道会-晋级赛
		[QuestBattleType.CHAMPIONSHIP_PROMOTION] = {functionName = 'BackToChampionship'},
		-- 联动本 -> 联动本
		[QuestBattleType.POP_TEAM] = {functionName = 'BackToPopTeamHome'},
		[QuestBattleType.POP_BOSS_TEAM] = {functionName = 'BackToPopMainHome'},
		-- 通用类型 -> 主界面
		[QuestBattleType.BASE] = {functionName = 'CommonBack'},
		-- 2020 周年庆探索界面
		[QuestBattleType.ANNIV2020_EXPLORE] = {functionName = 'BackToAnniversary20ExploreHome'},
	}

	local jumpInfo = jumpConfig[questBattleType]
	if nil ~= jumpInfo then

	else
		jumpInfo = jumpConfig[QuestBattleType.BASE]
	end

	self[jumpInfo.functionName](self, isPassed, battleConstructor)
end
--[[
强制退出战斗 返回一个可能订制的界面
@params questBattleType QuestBattleType 战斗类型
@params isPassed PassedBattle 是否通过了战斗
@params battleConstructor BattleConstructor 战斗构造器
--]]
function BattleMediator:BackToPreviousForce(questBattleType, isPassed, battleConstructor)
	self:BackToPrevious()
end
--[[
广播战斗结果
@params stageId int 关卡id
@params questBattleType QuestBattleType 战斗类型
@params isPassed PassedBattle 是否通过了战斗
--]]
function BattleMediator:BroadcastBattleResult(stageId, questBattleType, isPassed)
	AppFacade.GetInstance():DispatchObservers('BATTLE_COMPLETE_RESULT', {
		questId = stageId,
		questBattleType = questBattleType,
		battleResult = isPassed
	})
end
--[[
通用返回
@params isPassed PassedBattle 是否通过了战斗
@params battleConstructor BattleConstructor 战斗构造器
--]]
function BattleMediator:CommonBack(isPassed, battleConstructor)
	local fromtoData = battleConstructor:GetFromToData()
	AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch(
		{name = NAME},
		{name = fromtoData:GetToMediatorName(isPassed)}
	)
end
--[[
返回地图
@params isPassed PassedBattle 是否通过了战斗
@params battleConstructor BattleConstructor 战斗构造器
--]]
function BattleMediator:BackToMap(isPassed, battleConstructor)
	local difficultyType = QUEST_DIFF_NORMAL
	local stageId = battleConstructor:GetStageId()
	local stageConfig = CommonUtils.GetConfig('quest', 'quest', stageId)
	if nil ~= stageConfig and checkint(stageConfig.difficulty) == QUEST_DIFF_HARD then
		difficultyType = QUEST_DIFF_HARD
	end
	-- 返回地图
	local fromtoData = battleConstructor:GetFromToData()
	AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch(
		{name = NAME},
		{name = fromtoData:GetToMediatorName(isPassed), params = {currentAreaId = app.gameMgr:GetAreaId(), type = difficultyType}}
	)
end
--[[
返回主界面
@params isPassed PassedBattle 是否通过了战斗
@params battleConstructor BattleConstructor 战斗构造器
--]]
function BattleMediator:BackToHome(isPassed, battleConstructor)
	AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch(
		{name = NAME},
		{name = 'HomeMediator'}
	)
end
--[[
返回餐厅
@params isPassed PassedBattle 是否通过了战斗
@params battleConstructor BattleConstructor 战斗构造器
--]]
function BattleMediator:BackToRestaurant(isPassed, battleConstructor)
	------------ data ------------
	if app.gameMgr:GetUserInfo().avatarFriendCacheData_ then
		app.gameMgr:GetUserInfo().avatarFriendCacheData_.isPassed = isPassed
	end
	------------ data ------------

	self:CommonBack(isPassed, battleConstructor)
end
--[[
返回探索界面
@params isPassed PassedBattle 是否通过了战斗
@params battleConstructor BattleConstructor 战斗构造器
--]]
function BattleMediator:BackToExploreHome(isPassed, battleConstructor)
	self:CommonBack(isPassed, battleConstructor)

	local requestData = battleConstructor:GetEnterBattleRequestData()
	AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch(
		{name = "HomeMediator"},
		{name = "ExplorationMediator", params = {id = requestData.areaFixedPointId}}
	)
end
--[[
返回爬塔主界面
@params isPassed PassedBattle 是否通过了战斗
@params battleConstructor BattleConstructor 战斗构造器
--]]
function BattleMediator:BackToTowerHome(isPassed, battleConstructor)
	local towerRootMdt = AppFacade.GetInstance():RetrieveMediator('TowerQuestRootMediator')
	if towerRootMdt then
		towerRootMdt:setBattleResultData({
			isPassed = isPassed,
			buyLiveNum = battleConstructor:GetBuyRevivalTime()
		})
	end

	AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = NAME}, {name = 'TowerQuestHomeMediator'})
end
--[[
从决战演示返回
@params isPassed PassedBattle 是否通过了战斗
@params battleConstructor BattleConstructor 战斗构造器
--]]
function BattleMediator:BackToNormal(isPassed, battleConstructor)
	self:CommonBack(isPassed, battleConstructor)
end
--[[
回到工会大厅
@params isPassed PassedBattle 是否通过了战斗
@params battleConstructor BattleConstructor 战斗构造器
--]]
function BattleMediator:BackToUnionHunt(isPassed, battleConstructor)
	-- TODO
	AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = NAME}, {name = 'UnionLobbyMediator', initArgs = {
		isFromHunt = true,
		huntData   = {
			godBeastId = battleConstructor:GetUnionBeastId(),
		}
	}})
end
--[[
回到工会派对
@params isPassed PassedBattle 是否通过了战斗
@params battleConstructor BattleConstructor 战斗构造器
--]]
function BattleMediator:BackToUnionParty(isPassed, battleConstructor)
	self:CommonBack(isPassed, battleConstructor)
end
--[[
回到世界boss
@params isPassed PassedBattle 是否通过了战斗
@params battleConstructor BattleConstructor 战斗构造器
--]]
function BattleMediator:BackToWorldBoss(isPassed, battleConstructor)
	-- 刷新一次世界boss数据
	local appMediator = AppFacade.GetInstance():RetrieveMediator('AppMediator')
	appMediator:syncWorldBossListData()
    
	local fromtoData = battleConstructor:GetFromToData()
	AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch(
		{name = NAME},
		{name = fromtoData:GetToMediatorName(isPassed), params = {questId = battleConstructor:GetStageId()}}
	)
end
--[[
回到活动副本
@params isPassed PassedBattle 是否通过了战斗
@params battleConstructor BattleConstructor 战斗构造器
--]]
function BattleMediator:BackToActivityQuestHome(isPassed, battleConstructor)
	local fromtoData = battleConstructor:GetFromToData()
	local requestData = battleConstructor:GetEnterBattleRequestData()

	AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch(
		{name = NAME},
		{name = fromtoData:GetToMediatorName(isPassed), params = {
			activityId = requestData.activityId, questId = battleConstructor:GetStageId()
		}}
	)
end
--[[
回到天城演武大厅界面
@params isPassed PassedBattle 是否通过了战斗
@params battleConstructor BattleConstructor 战斗构造器
--]]
function BattleMediator:BackToTagMatchLobby(isPassed, battleConstructor)
	if GAME_MODULE_OPEN.NEW_TAG_MATCH then
		-- 进入活动界面
		AppFacade.GetInstance():RetrieveMediator('Router'):Dispatch(
			{name = "HomeMediator"},
			{name = "ActivityMediator", params = {activityId = ACTIVITY_ID.NEW_TAG_MATCH}}
		)
		return
	end
	
	-- 点击back按钮时 检查 section
	local data = app.gameMgr:get3v3MatchBattleData()
	local section = data.section
	if section ~= MATCH_BATTLE_3V3_TYPE.BATTLE then
		-- 进入活动界面
		AppFacade.GetInstance():RetrieveMediator('Router'):Dispatch(
			{name = "HomeMediator"},
			{name = "ActivityMediator", params = {activityId = ACTIVITY_ID.TAG_MATCH}}
		)
	else
		-- 先为天城演武大厅界面创建活动界面的载体
		local fromtoData = battleConstructor:GetFromToData()
		AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch(
			{name = NAME},
			{name = 'ActivityMediator', params = {activityId = ACTIVITY_ID.TAG_MATCH}}
		)
		-- 进入天城演武大厅界面
		AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch(
			{name = NAME},
			{name = fromtoData:GetToMediatorName(isPassed)},
			nil, true
		)
	end
end

--[[
回到新天城演武大厅界面
--]]
function BattleMediator:BackToNewTagMatchLobby()
	-- 点击back按钮时
	-- 进入活动界面
	AppFacade.GetInstance():RetrieveMediator('Router'):Dispatch(
		{name = "HomeMediator"},
		{name = "ActivityMediator", params = {activityId = ACTIVITY_ID.NEW_TAG_MATCH,isFromBattle = true}}
	)
end

--[[
回到神器相关的界面
@params isPassed PassedBattle 是否通过了战斗
@params battleConstructor BattleConstructor 战斗构造器
--]]
function BattleMediator:BackToArtifact(isPassed, battleConstructor)
	local fromtoData = battleConstructor:GetFromToData()
	local requestData = battleConstructor:GetEnterBattleRequestData()

	local playerCardId = requestData.playerCardId
	AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch(
		{name = NAME},
		{name = fromtoData:GetToMediatorName(isPassed), params = {playerCardId = playerCardId}}
	)

	local cardData = app.gameMgr:GetCardDataById(playerCardId)
	local cardId = checkint(cardData.cardId)
	local artifactQuestId = CardUtils.GetCardArtifactQuestId(cardId)
	app.artifactMgr:GoToBattleReadyView(
		artifactQuestId, fromtoData:GetToMediatorName(isPassed), fromtoData:GetToMediatorName(isPassed), playerCardId
	)
end
--[[
回到season activity 相关的界面
@params isPassed PassedBattle 是否通过了战斗
@params battleConstructor BattleConstructor 战斗构造器
--]]
function BattleMediator:BackToSeasonActivity(isPassed, battleConstructor)
	local fromtoData = battleConstructor:GetFromToData()
	local requestData = battleConstructor:GetEnterBattleRequestData()
	
	-- 这里会返回一些进入战斗前的数据以便使用
	AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch(
		{name = NAME},
		{name = fromtoData:GetToMediatorName(isPassed), params = requestData}
	)
end
--[[
回到燃战相关的界面
@params isPassed PassedBattle 是否通过了战斗
@params battleConstructor BattleConstructor 战斗构造器
--]]
function BattleMediator:BackToSaiMoe(isPassed, battleConstructor)
	local requestData = battleConstructor:GetEnterBattleRequestData()
	local isFirst = requestData.isFirst
	local openShop = requestData.openShop
	local fromtoData = battleConstructor:GetFromToData()

	AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch(
		{name = NAME},
		{name = fromtoData:GetToMediatorName(isPassed), params = {isFirst = isFirst, openShop = openShop}}
	)
end
--[[
回到周年庆主界面
@params isPassed PassedBattle 是否通过了战斗
@params battleConstructor BattleConstructor 战斗构造器
--]]
function BattleMediator:BackAniversary(isPassed, battleConstructor)
	local callfunc = function()
		AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch(
			{name = NAME},
			{name = "anniversary.AnniversaryMainLineMapMediator"}
		)
	end

	if 1 == checkint(app.anniversaryMgr.homeData.chapterType) and
		1 == checkint(app.anniversaryMgr.homeData.chapterQuest.gridStatus) and
		24 == checkint(app.anniversaryMgr.homeData.chapterQuest.locationGrid) then

		local parseConfig = app.anniversaryMgr:GetConfigParse()
		local chapterConfig = app.anniversaryMgr:GetConfigDataByName(parseConfig.TYPE.CHAPTER)
		local chapterType = app.anniversaryMgr.homeData.chapterType
		local chapterSort = app.anniversaryMgr.homeData.chapterSort
		local chapterId = app.anniversaryMgr:GetChpterIdByChapeterTypeChapterSort(chapterType, chapterSort)
		local chapterOneConfig = chapterConfig[tostring(chapterId)]
		if checkint(chapterOneConfig.endBossStoryId) > 0 then
			app.anniversaryMgr:ShowOperaStage(chapterOneConfig.endBossStoryId, callfunc)
		else
			callfunc()
		end

	else

		callfunc() 

	end
end
--[[
回到神器之路
@params isPassed PassedBattle 是否通过了战斗
@params battleConstructor BattleConstructor 战斗构造器
--]]
function BattleMediator:BackToArtifactRoad(isPassed, battleConstructor)
	local fromtoData = battleConstructor:GetFromToData()
	local requestData = battleConstructor:GetEnterBattleRequestData()

	AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch(
		{name = NAME},
		{name = fromtoData:GetToMediatorName(isPassed), params = requestData}
	)
end
--[[
回到PT副本
@params isPassed PassedBattle 是否通过了战斗
@params battleConstructor BattleConstructor 战斗构造器
--]]
function BattleMediator:BackToPTDungeon(isPassed, battleConstructor)
	local fromtoData = battleConstructor:GetFromToData()
	local requestData = battleConstructor:GetEnterBattleRequestData()

	AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch(
		{name = NAME},
		{name = fromtoData:GetToMediatorName(isPassed), params = requestData}
	)
end
--[[
回到新的春活
@params isPassed PassedBattle 是否通过了战斗
@params battleConstructor BattleConstructor 战斗构造器
--]]
function BattleMediator:BackNewSpringAction(isPassed, battleConstructor)
	local fromtoData = battleConstructor:GetFromToData()
	local requestData = battleConstructor:GetEnterBattleRequestData() or {}

	AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch(
		{name = NAME},
		{name = fromtoData:GetToMediatorName(isPassed), params = requestData}
	)
end
--[[
@params isPassed PassedBattle 是否通过了战斗
@params battleConstructor BattleConstructor 战斗构造器
--]]
function BattleMediator:BackToUltimateBattle(isPassed, battleConstructor)
	local fromtoData = battleConstructor:GetFromToData()

	AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch(
		{name = NAME},
		{name = fromtoData:GetToMediatorName(isPassed), params = {activityId = ACTIVITY_ID.ULTIMATE_BATTLE}}
	)
end
--[[
@params isPassed PassedBattle 是否通过了战斗
@params battleConstructor BattleConstructor 战斗构造器
--]]
function BattleMediator:BackToSkinCarnival(isPassed, battleConstructor)
	local fromtoData = battleConstructor:GetFromToData()
	local requestData = battleConstructor:GetEnterBattleRequestData() or {}

	AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch(
		{name = NAME},
		{name = fromtoData:GetToMediatorName(isPassed), params = {activityId = requestData.activityId}}
	)
end
--[[
@params isPassed PassedBattle 是否通过了战斗
@params battleConstructor BattleConstructor 战斗构造器
--]]
function BattleMediator:BackToAnniversary19(isPassed, battleConstructor)
	local fromtoData = battleConstructor:GetFromToData()
	local requestData = battleConstructor:GetEnterBattleRequestData() or {}

	AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch(
		{name = NAME},
		{name = fromtoData:GetToMediatorName(isPassed), params = {status = 1}}
	)
end

--[[
@params isPassed PassedBattle 是否通过了战斗
@params battleConstructor BattleConstructor 战斗构造器
--]]
function BattleMediator:BackToAnniversary20ExploreHome(isPassed, battleConstructor)
	local fromtoData = battleConstructor:GetFromToData()
	local requestData = battleConstructor:GetEnterBattleRequestData() or {}
	AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch(
		{name = NAME},

		{	name = fromtoData:GetToMediatorName(isPassed),
			params = {
				isPassed = isPassed, mapGridId = requestData.gridId ,
				exploreModuleId = app.anniv2020Mgr:getExploringId()
			}
		}
	)
end


--[[
@params isPassed PassedBattle 是否通过了战斗
@params battleConstructor BattleConstructor 战斗构造器
--]]
function BattleMediator:BackToFriendBattle(isPassed, battleConstructor)
	local fromtoData = battleConstructor:GetFromToData()

	AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch(
		{name = NAME},
		{name = fromtoData:GetToMediatorName(isPassed), params = {showFriendBattle = true}}
	)
end
--[[
@params isPassed PassedBattle 是否通过了战斗
@params battleConstructor BattleConstructor 战斗构造器
--]]
function BattleMediator:BackToSpringActivity20(isPassed, battleConstructor)
	local fromtoData = battleConstructor:GetFromToData()
	if fromtoData.fromMediatorName == 'springActivity20.SpringActivity20StageMediator' then -- 关卡
		AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch(
			{name = NAME},
			{name = fromtoData:GetToMediatorName(isPassed)}
		)
	elseif fromtoData.fromMediatorName == 'springActivity20.SpringActivity20BossMediator' then -- boss
		local spBossAppear = nil
		if isPassed and app.springActivity20Mgr:GetSpBossAppearNeedTimes() == 1 then
			spBossAppear = 1
		end
		AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch(
			{name = NAME},
			{name = fromtoData:GetToMediatorName(isPassed), params = {spBossAppear = spBossAppear}}
		)
	elseif fromtoData.fromMediatorName == 'springActivity20.SpringActivity20SpBossMediator' then -- spBoss
		AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch(
			{name = NAME},
			{name = 'springActivity20.SpringActivity20BossMediator', params = {spBattleBack = 1, isSpBossPassed = isPassed}}
		)
	end
end
--[[
@params isPassed PassedBattle 是否通过了战斗
@params battleConstructor BattleConstructor 战斗构造器
--]]
function BattleMediator:BackToChampionship(isPassed, battleConstructor)
	local fromtoData = battleConstructor:GetFromToData()
	
	AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch(
		{name = NAME},
		{name = fromtoData:GetToMediatorName(isPassed), params = {backMediatorName = 'BattleAssembleExportMediator'}} -- 历练界面
	)
end
--[[
回到联动本
@params isPassed PassedBattle 是否通过了战斗
@params battleConstructor BattleConstructor 战斗构造器
--]]
function BattleMediator:BackToPopTeamHome(isPassed, battleConstructor)
	local fromtoData = battleConstructor:GetFromToData()
	local requestData = battleConstructor:GetEnterBattleRequestData()
	AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch(
		{name = NAME},
		{name = fromtoData:GetToMediatorName(isPassed), params = {
			activityId = requestData.activityId, questId = battleConstructor:GetStageId(), zoneIndex = requestData.zoneIndex
		}}
	)
end
--[[
回到联动本
@params isPassed PassedBattle 是否通过了战斗
@params battleConstructor BattleConstructor 战斗构造器
--]]
function BattleMediator:BackToPopMainHome(isPassed, battleConstructor)
	local fromtoData = battleConstructor:GetFromToData()
	local requestData = battleConstructor:GetEnterBattleRequestData()
	AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch(
			{name = NAME},
			{name = fromtoData:GetToMediatorName(isPassed), params = {
				activityId = requestData.activityId , bossId = requestData.questId
			}}
	)
end
---------------------------------------------------
-- back control end --
---------------------------------------------------

--[[
强制退出战斗
--]]
function BattleMediator:ForceExitBattle()
	app.gameMgr:ShowGameAlertView({
		text = __('战斗出现了一些意外...'),
		isOnlyOK = true,
		callback = function ()
			self.battleManager:QuitBattleForce()
		end
	})
end
--[[
杀死战斗整套正在运行的逻辑
--]]
function BattleMediator:KillBattle()
	if nil ~= self.battleManager then
		self.battleManager:KillBattle()
		self.battleManager = nil
	end
end

return BattleMediator

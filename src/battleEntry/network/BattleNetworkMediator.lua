--[[
战斗网络控制器
--]]
local Mediator = mvc.Mediator
local BattleNetworkMediator = class("BattleNetworkMediator", Mediator)
local NAME = "BattleNetworkMediator"

local MapCommand = require('Game.command.MapCommand')
local BattleCommand = require('battleEntry.network.BattleCommand')
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")

---------- debug params ----------
local BATTLE_LOCAL_SWITCH = false
---------- debug params ----------

-- 战斗短连接配置
local CMDInfo = {
	-- 地图战斗
	{cmd = POST.QUEST_AT, sglHandleFunc = 'HandleMapBattleQuestAtResponse'},
	{cmd = POST.QUEST_GRADE, sglHandleFunc = 'HandleMapBattleQuestGradeResponse'},
	-- 霸王餐
	{cmd = POST.RESTAURANT_QUEST_AT, sglHandleFunc = 'HandleOtherNeedLeaveIceRoomQuestAtResponse'},
	{cmd = POST.RESTAURANT_QUEST_GRADE},
	-- 帮打霸王餐
	{cmd = POST.RESTAURANT_HELP_QUEST_AT},
	{cmd = POST.RESTAURANT_HELP_QUEST_GRADE},
	-- 主线剧情任务战斗
	{cmd = POST.PLOT_TASK_QUEST_AT, sglHandleFunc = 'HandleOtherNeedLeaveIceRoomQuestAtResponse'},
	{cmd = POST.PLOT_TASK_QUEST_GRADE},
	-- 支线剧情任务战斗
	{cmd = POST.BRANCH_QUEST_AT, sglHandleFunc = 'HandleOtherNeedLeaveIceRoomQuestAtResponse'},
	{cmd = POST.BRANCH_QUEST_GRADE},
	-- 外卖打劫
	{cmd = POST.TAKEAWAY_ROBBERY_QUEST_AT},
	{cmd = POST.TAKEAWAY_ROBBERY_QUEST_GRADE, sglHandleFunc = 'HandleRobberyBattleQuestGradeResponse'},
	{cmd = POST.TAKEAWAY_ROBBERY_RIDICULE},
	-- 探索
	{cmd = POST.EXPLORATION_QUEST_AT},
	{cmd = POST.EXPLORATION_QUEST_GRADE},
	-- 爬塔
	{cmd = POST.TOWER_QUEST_AT},
	{cmd = POST.TOWER_QUEST_GRADE},
	{cmd = POST.TOWER_QUEST_BUY_LIVE},
	-- 竞技场
	{cmd = POST.PVC_QUEST_AT},
	{cmd = POST.PVC_QUEST_GRADE},
	-- 材料副本
	{cmd = POST.MATERIAL_QUEST_AT},
	{cmd = POST.MATERIAL_QUEST_GRADE},
	-- 季活
	{cmd = POST.SEASON_ACTIVITY_QUEST_AT},
	{cmd = POST.SEASON_ACTIVITY_QUEST_GRADE, sglHandleFunc = 'HandleSeasonBattleQuestGradeResponse'},
	{cmd = POST.SPRING_ACTIVITY_QUEST_AT},
	{cmd = POST.SPRING_ACTIVITY_QUEST_GRADE, sglHandleFunc = 'HandleCastleQuestGradeResponse'},
	{cmd = POST.SUMMER_ACTIVITY_QUESTAT},
	{cmd = POST.SUMMER_ACTIVITY_QUESTGRADE, sglHandleFunc = 'HandleSummerActBattleQuestGradeResponse'},
	-- 公会战boss
	{cmd = POST.UNION_WARS_BOSS_QUEST_AT},
	{cmd = POST.UNION_WARS_BOSS_QUEST_GRADE, sglHandleFunc = 'HandleUnionWarsBosssQuestGradeResponse'},
	-- 公会战PVP
	{cmd = POST.UNION_WARS_ENEMY_QUEST_AT},
	{cmd = POST.UNION_WARS_ENEMY_QUEST_GRADE, sglHandleFunc = 'HandleUnionWarsPVCQuestGradeResponse'},
	-- 周年庆
	{cmd = POST.ANNIVERSARY_QUEST_AT},
	{cmd = POST.ANNIVERSARY_QUEST_GRADE, sglHandleFunc = 'HandleAnniversaryQuestGradeResponse'},
	-- 神器
	{cmd = POST.ARTIFACT_QUESTAT},
	{cmd = POST.ARTIFACT_QUESTGRADE, sglHandleFunc = 'HandleArtifactBattleQuestGradeResponse'},
	-- 工会狩猎神兽
	{cmd = POST.UNION_HUNTING_QUEST_AT},
	{cmd = POST.UNION_HUNTING_QUEST_GRADE},
	{cmd = POST.UNION_HUNTING_BUY_LIVE},
	-- 工会派对打堕神
	{cmd = POST.UNION_PARTY_BOSS_QUEST_AT},
	{cmd = POST.UNION_PARTY_BOSS_QUEST_GRADE},
	-- 世界boss战
	{cmd = POST.WORLD_BOSS_QUESTAT},
	{cmd = POST.WORLD_BOSS_QUESTGRADE},
	{cmd = POST.WORLD_BOSS_BUYLIVE},
	-- 活动副本
	{cmd = POST.ACTIVITY_QUEST_QUESTAT},
	{cmd = POST.ACTIVITY_QUEST_QUESTGRADE},
	-- 天城演武
	{cmd = POST.TAG_MATCH_QUEST_AT},
	{cmd = POST.TAG_MATCH_QUEST_GRADE},
	-- 新天成演武
	{cmd = POST.NEW_TAG_MATCH_QUEST_AT},
	{cmd = POST.NEW_TAG_MATCH_QUEST_GRADE},
	-- 燃战
	{cmd = POST.SAIMOE_QUEST_AT},
	{cmd = POST.SAIMOE_QUEST_GRADE},
	{cmd = POST.SAIMOE_BOSS_QUEST_AT},
	{cmd = POST.SAIMOE_BOSS_QUEST_GRADE},
	-- 神器之路
	{cmd = POST.ACTIVITY_ARTIFACT_ROAD_QUEST_AT},
	{cmd = POST.ACTIVITY_ARTIFACT_ROAD_QUEST_GRADE, sglHandleFunc = 'HandleArtifactRoadBattleQuestGradeResponse'},
	-- pt本
	{cmd = POST.PT_QUEST_AT},
	{cmd = POST.PT_QUEST_GRADE},
	{cmd = POST.PT_BUY_LIVE},
	-- 工会战
	{cmd = POST.UNION_WARS_ENEMY_QUEST_AT},
	{cmd = POST.UNION_WARS_ENEMY_QUEST_GRADE},
	{cmd = POST.UNION_WARS_BOSS_QUEST_AT},
	{cmd = POST.UNION_WARS_BOSS_QUEST_GRADE},
	-- 杀人案（19夏活）
	{cmd = POST.MURDER_QUEST_AT},
	{cmd = POST.MURDER_QUEST_GRADE, sglHandleFunc = 'HandleMurderBattleQuestGradeResponse'},
	-- 木人桩
	{cmd = POST.PLAYER_DUMMY_QUEST_AT},
	{cmd = POST.PLAYER_DUMMY},	 
	-- 巅峰对决
	{cmd = POST.ACTIVITY_ULTIMATE_BATTLE_QUEST_AT},
	{cmd = POST.ACTIVITY_ULTIMATE_BATTLE_QUEST_GRADE},
	-- 皮肤嘉年华
	{cmd = POST.SKIN_CARNIVAL_CHALLENGE_QUEST_AT},
	{cmd = POST.SKIN_CARNIVAL_CHALLENGE_QUEST_GRADE},
	-- 童话世界/2019周年庆
	{cmd = POST.ANNIVERSARY2_BOSS_QUEST_AT},
	{cmd = POST.ANNIVERSARY2_BOSS_QUEST_GRADE},
	-- 周年庆探索小怪
	{cmd = POST.ANNIVERSARY2_EXPLORE_SECTION_MONSTER_QUEST_AT},
	{cmd = POST.ANNIVERSARY2_EXPLORE_SECTION_MONSTER_QUEST_GRADE , sglHandleFunc = 'HandleAnniversary19MonsterQuestGradeResponse'},

	-- 2020周年庆探索
	{cmd = POST.ANNIV2020_EXPLORE_QUEST_AT},
	{cmd = POST.ANNIV2020_EXPLORE_QUEST_GRADE , sglHandleFunc = 'HandleAnniversary20MonsterQuestGradeResponse'},

	-- luna塔
	{cmd = POST.LUNA_TOWER_QUEST_AT},
	{cmd = POST.LUNA_TOWER_QUEST_GRADE},
	-- 好友切磋
	{cmd = POST.FRIEND_BATTLE_QUEST_AT},
	{cmd = POST.FRIEND_BATTLE_QUEST_GRADE},
	-- 20春活
	{cmd = POST.SPRING_ACTIVITY_20_QUEST_AT},
	{cmd = POST.SPRING_ACTIVITY_20_QUEST_GUADE},
	-- 武道会-评选赛
	{cmd = POST.CHAMPIONSHIP_QUEST_AT},
	{cmd = POST.CHAMPIONSHIP_QUEST_GRADE},
	-- 联动本（pop子）
	{cmd = POST.POP_TEAM_QUEST_AT},
	{cmd = POST.POP_TEAM_QUEST_GRADE},
	-- 联动本（pop 子Boss）
	{cmd = POST.POP_FARM_BOSS_QUEST_AT},
	{cmd = POST.POP_FARM_BOSS_QUEST_GRADE},

}

local CMDConfig = {}
for _, cmdInfo in ipairs(CMDInfo) do
	if nil ~= cmdInfo.cmd then
		CMDConfig[cmdInfo.cmd.sglName] = {cmd = cmdInfo.cmd, sglHandleFunc = cmdInfo.sglHandleFunc}
	end
end

---------------------------------------------------
-- mediator extend begin --
---------------------------------------------------
function BattleNetworkMediator:ctor( params, viewComponent )
	self.super:ctor(NAME, viewComponent)

	-- 回调函数集
	self.networkCallbacks = {}
end
function BattleNetworkMediator:InterestSignals()
	local signals = {
		-- 通用调取信号
		'BATTLE_COMMON_NETWORK_REQUEST',
	}

	for _, cmdInfo in pairs(CMDConfig) do
		table.insert(signals, cmdInfo.cmd.sglName)
	end

	return signals
end
function BattleNetworkMediator:OnRegist()
	funLog(Logger.INFO, 'network mgr come !!!')
end
function BattleNetworkMediator:OnUnRegist()

end
function BattleNetworkMediator:ProcessSignal( signal )
	local name = signal:GetName()
	local responseData = signal:GetBody()

	local cmdInfo = CMDConfig[name]

	if nil ~= cmdInfo then

		if nil ~= cmdInfo.sglHandleFunc then
			self[cmdInfo.sglHandleFunc](self, signal)
		end

	else

		if 'BATTLE_COMMON_NETWORK_REQUEST' == name then
			-- 通用调取信号
			self:CommonNetworkRequest(
				responseData.requestCommand,
				responseData.responseSignal,
				responseData.data,
				responseData.callback
			)
			return
		end

	end

	logt(responseData,"battleData111")

	if false then

	else
		self:CheckCaptchaAndGoNext(signal)
	end
end
---------------------------------------------------
-- mediator extend end --
---------------------------------------------------

---------------------------------------------------
-- response data handle logic begin --
---------------------------------------------------
--[[
普通关卡quest at数据处理
@params signal table 信号源
--]]
function BattleNetworkMediator:HandleMapBattleQuestAtResponse(signal)
	local name = signal:GetName()
	local responseData = signal:GetBody()

	local questId = responseData.requestData.questId
	local stageConf = CommonUtils.GetConfig('quest', 'quest', responseData.requestData.questId)

	---------- 进入战斗 处理本地数据 ----------
	if responseData.requestData.magicFoodId then
		-- 如果携带魔法食物 对应的魔法食物减1
		CommonUtils.DrawRewards({{goodsId = responseData.requestData.magicFoodId, num = -1}})
		if 0 == gameMgr:GetAmountByGoodId(responseData.requestData.magicFoodId) then
			gameMgr:UpdatePlayer({localCurrentEquipedMagicFoodId = 0})
		else
			gameMgr:UpdatePlayer({localCurrentEquipedMagicFoodId = responseData.requestData.magicFoodId})
		end
	end

	-- 进入战斗请求成功 扣除两点体力
	-- 缓存一次当前关卡
	local localCurrentQuestId = checkint(responseData.requestData.questId)
	-- 如果当前打的最新关卡则不缓存
	if localCurrentQuestId == gameMgr:GetUserInfo().newestQuestId or
		localCurrentQuestId == gameMgr:GetUserInfo().newestHardQuestId or
		localCurrentQuestId == gameMgr:GetUserInfo().newestInsaneQuestId then

		localCurrentQuestId = 0

	end
	gameMgr:UpdatePlayer({
		hp = math.max(gameMgr:GetUserInfo().hp - checkint(stageConf.consumeHpAt), 0),
		localCurrentQuestId = localCurrentQuestId,
		localCurrentBattleTeamId = responseData.requestData.teamId
	})
	AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.CACHE_MONEY_UPDATE_UI)


	-- 扣除卡牌活力值
	local teamData = gameMgr:GetUserInfo().teamFormation[responseData.requestData.teamId]
	for i,v in ipairs(teamData.cards) do
		if v.id then
			local cardData = gameMgr:GetCardDataById(v.id)
			if nil ~= cardData then
				local data = {vigour = math.max(cardData.vigour - checkint(stageConf.consumeVigour), 0)}
				gameMgr:UpdateCardDataById(v.id, data)
				-- 清除冰场数据
				gameMgr:DelCardOnePlace(v.id,CARDPLACE.PLACE_ICE_ROOM)
			end
		end
	end
	---------- 进入战斗 处理本地数据 ----------
end
--[[
普通关卡 quest grade 数据处理
@params signal table 信号源
--]]
function BattleNetworkMediator:HandleMapBattleQuestGradeResponse(signal)
	local name = signal:GetName()
	local responseData = signal:GetBody()
	
	---------- 战斗结束 更新本地关卡星级信息 ----------
	local questId = responseData.requestData.questId
	gameMgr:UpdateQuestGradeByQuestId(questId, checkint(responseData.grade))
	---------- 战斗结束 更新本地关卡星级信息 ----------
end
--[[
霸王餐 剧情任务关卡quest at数据处理
@params signal table 信号源
--]]
function BattleNetworkMediator:HandleOtherNeedLeaveIceRoomQuestAtResponse(signal)
	local name = signal:GetName()
	local responseData = signal:GetBody()

	---------- 清除冰场状态 ----------
	local teamData = gameMgr:GetUserInfo().teamFormation[responseData.requestData.teamId]
	for i,v in ipairs(teamData.cards) do
		if v.id then
			local cardData = gameMgr:GetCardDataById(v.id)
			if nil ~= cardData then
				gameMgr:DelCardOnePlace(v.id,CARDPLACE.PLACE_ICE_ROOM)
			end
		end
	end
end
--[[
打劫quest grade 数据处理
@params signal table 信号源
--]]
function BattleNetworkMediator:HandleRobberyBattleQuestGradeResponse(signal)
	local name = signal:GetName()
	local responseData = signal:GetBody()

	---------- 刷新打劫数据 ----------
	local takeawayManager = AppFacade.GetInstance():GetManager('TakeawayManager')
	if nil ~= takeawayManager then
		takeawayManager:postRobberyNetWork()
	end
	---------- 刷新打劫数据 ----------
end
--[[
季活quest grade 数据处理
@params signal table 信号源
--]]
function BattleNetworkMediator:HandleSeasonBattleQuestGradeResponse(signal)
	local name = signal:GetName()
	local responseData = signal:GetBody()

	---------- 季活的数据 ----------
	local requestData =  responseData.requestData

	if checkint(requestData.isPassed) == 1  then
		local questData = CommonUtils.GetConfigAllMess('quest','seasonActivity')
		local questId  = requestData.questId
		local questOneData = questData[tostring(questId)] -- 获取到具体的关卡数据
		if questOneData then
			local data = {}
			if checkint(questOneData.consumeHpLose) > 0 then  -- 检测体力的扣除
				data[#data+1] = { goodsId =  HP_ID , num = - checkint(questOneData.consumeHpLose)}
			end
			if checkint(questOneData.consumeGoodsLose.goodsId) > 0  -- 检测活动物品的扣除
					and  checkint(questOneData.consumeGoodsLose.goodsNum)  > 0 then
				data[#data+1] = { goodsId = questOneData.consumeGoodsLose.goodsId  ,
								  num = - checkint(questOneData.consumeGoodsLose.goodsNum) }
			end
			if table.nums(data) > 0 then
				CommonUtils.DrawRewards(data)
			end
		end
	end
	---------- 季活的数据 ----------
end
--[[
春活数据处理quest grade 数据处理
@params signal table 信号源
--]]
function BattleNetworkMediator:HandleCastleQuestGradeResponse(signal)
	local name = signal:GetName()
	local responseData = signal:GetBody()
	---------- 春活数据 ----------s
	local requestData =  responseData.requestData
	local questData = CommonUtils.GetConfigAllMess('quest','springActivity')
	local questId  = requestData.questId
	local questOneData = questData[tostring(questId)] -- 获取到具体的关卡数据
	local questTypeConfig = CommonUtils.GetConfigAllMess('questType','springActivity')
	local questTypeOneConfig =  questTypeConfig[tostring(questOneData.type) ] or {}
	if checkint(requestData.isPassed) == 1 or checkint(questTypeOneConfig.skipQuest) ==  2   then
		local questData = CommonUtils.GetConfigAllMess('quest','springActivity')
		local questId  = requestData.questId
		local questOneData = questData[tostring(questId)] -- 获取到具体的关卡数据
		if questOneData then
			local data = {}
			if checkint(questOneData.consumeGoods) > 0  -- 检测活动物品的扣除
					and  checkint(questOneData.consumeNum)  > 0 then
				data[#data+1] = { goodsId = questOneData.consumeGoods  ,
								  num = - questOneData.consumeNum }
			end
			if table.nums(data) > 0 then
				CommonUtils.DrawRewards(data)
			end
		end
	end
	---------- 春活数据 ----------
end
--[[
周年庆quest grade 数据处理
@params signal table 信号源
--]]
function BattleNetworkMediator:HandleAnniversaryQuestGradeResponse(signal)
	local name = signal:GetName()
	local responseData = signal:GetBody()

	---------- 周年庆数据 ----------
	local requestData =  responseData.requestData
	if checkint(requestData.isPassed) == 1  then
		local anniversaryManager = app.anniversaryMgr
		local parserConfig = anniversaryManager:GetConfigParse()
		local questConfig = anniversaryManager:GetConfigDataByName(parserConfig.TYPE.QUEST)
		local questData = questConfig
		local questId  = requestData.questId
		local questOneData = questData[tostring(questId)] -- 获取到具体的关卡数据
		if questOneData then
			local data = {}
			if checkint(questOneData.consumeGoods) > 0  -- 检测活动物品的扣除
					and  checkint(questOneData.consumeNum)  > 0 then
				data[#data+1] = { goodsId = questOneData.consumeGoods ,
								  num = - checkint(questOneData.consumeNum) }
			end
			if table.nums(data) > 0 then
				CommonUtils.DrawRewards(data)
			end
			if not  anniversaryManager.homeData.chapterQuest then
				anniversaryManager.homeData.chapterQuest = {}
			end
			local chapterQuest = anniversaryManager.homeData.chapterQuest
			chapterQuest.gridStatus = 1
		end
	end
	---------- 季活的数据 ----------
end

--[[
公会战Boss 结果返回
@params signal table 信号源
--]]
function BattleNetworkMediator:HandleUnionWarsBosssQuestGradeResponse(signal)
end
--[[
公会战PVC 结果返回
@params signal table 信号源
--]]
function BattleNetworkMediator:HandleUnionWarsPVCQuestGradeResponse(signal)
end



--[[
神器碎片quest grade 数据处理
@params signal table 信号源
--]]
function BattleNetworkMediator:HandleArtifactBattleQuestGradeResponse(signal)
	local responseData = signal:GetBody()
	---------- 季活的数据 ----------
	local requestData =  responseData.requestData
	if checkint(requestData.isPassed) == 1  then
		local questOneData = CommonUtils.GetQuestConf(requestData.questId)
		local questId  = requestData.questId
		local questType = checkint(requestData.questType)
		local times = 1
		if questOneData then
			local data = {}
			if checkint(questOneData.consumeHpLose) > 0 then  -- 检测体力的扣除
				data[#data+1] = { goodsId =  HP_ID , num = - checkint(questOneData.consumeHpLose)}
			end
			---@type ArtifactManager
			local artifactMgr = AppFacade.GetInstance():GetManager("ArtifactManager")
			local consumeData = artifactMgr:GetConsumedByQuestId(questId , times ,questType ) or {}
			for i, v in pairs(consumeData) do
				data[#data+1] = v
			end
			if table.nums(data) > 0 then
				CommonUtils.DrawRewards(data)
			end
			local questGradeData ={
				id  = questId ,
				grade = responseData.grade,
				gradeConditionIds = responseData.gradeConditionIds
			}
			artifactMgr:UpdateArtifactQuest(questGradeData)
		end


	end
	---------- 季活的数据 ----------
end

--[[
夏活quest grade 数据处理
@params signal table 信号源
--]]
function BattleNetworkMediator:HandleSummerActBattleQuestGradeResponse(signal)
	local responseData = signal:GetBody()
	local reqData = responseData.requestData
	local chapterId = checkint(reqData.chapterId)
	local chapterIsPassed = checkint(reqData.chapterIsPassed)
	local nodeGroup = reqData.nodeGroup
	local nodeType = reqData.nodeType
	-- 夏活只要是 请求过quest_grade 即为成功 如果为boss 则保存一个战斗成功的标识
	if nodeType == 3 then
		if chapterId ~= 5 then
			app.summerActMgr:SetBattleSuccessFlag(chapterId, nodeGroup)
		end
		-- 如果是BOSS 是第一次打BOSS（只要请求过questGrade就为通过）
		if chapterIsPassed == 0 then
			local storyId = app.summerActMgr:GetOvercomeChapterIconStoryByChapterId(chapterId)
			if storyId then
				local hasSignal = self:GetFacade():HasSignal(POST.SUMMER_ACTIVITY_STORY_UNLOCK.cmdName)
				if not hasSignal then
					-- 如果 没注册的话  则注册
					regPost(POST.SUMMER_ACTIVITY_STORY_UNLOCK)
					self:SendSignal(POST.SUMMER_ACTIVITY_STORY_UNLOCK.cmdName, {storyId = storyId, storyTag = 0})
					-- 如果 再这注册的话  则解注册
					unregPost(POST.SUMMER_ACTIVITY_STORY_UNLOCK)
				else
					self:SendSignal(POST.SUMMER_ACTIVITY_STORY_UNLOCK.cmdName, {storyId = storyId, storyTag = 0})
				end

				-- 设置通关BOSS剧情ID
				app.summerActMgr:SetOvercomeStoryId(storyId)
			end
		end
	end
		
end

--[[
神器之路quest grade 数据处理
@params signal table 信号源
--]]
function BattleNetworkMediator:HandleArtifactRoadBattleQuestGradeResponse(signal)
	local responseData = signal:GetBody()
	local reqData = responseData.requestData

	if 2 == checkint(reqData.consumeType) and 1 == checkint(reqData.isPassed) then
		local questId = reqData.questId
		local stageConf = CommonUtils.GetQuestConf(questId)
		CommonUtils.DrawRewards({ { goodsId = stageConf.consumeGoodsId, num = -1 * checkint(stageConf.consumeGoodsNum) } })
	end
end

--[[
杀人案（19夏活）quest grade 数据处理
@params signal table 信号源
--]]
function BattleNetworkMediator:HandleMurderBattleQuestGradeResponse( signal )
	local responseData = signal:GetBody()
	local reqData = responseData.requestData
	-- 处理关卡消耗，更新本地数据
	if 1 == checkint(reqData.isPassed) then
		local bossId = app.murderMgr:GetUnlockBossId()
		if bossId > 0 then
			local questIdList = app.murderMgr:GetQuestIdByBossId(bossId)
			local stageConf = CommonUtils.GetQuestConf(checkint(reqData.questId))
			if questIdList[tostring(reqData.questId)] then
				-- boss关
				CommonUtils.DrawRewards({ { goodsId = app.murderMgr:GetMurderGoodsIdByKey("murder_ticket_id"), num = -1 * checkint(stageConf.consumeNum)}})
			else
				-- 材料本
				app.activityHpMgr:UpdateHp(app.murderMgr:GetMurderHpId(), -checkint(stageConf.consumeHpNum))
			end
		end
	end
end

function BattleNetworkMediator:HandleAnniversary19MonsterQuestGradeResponse( signal )
	local responseData = signal:GetBody()
	local reqData = responseData.requestData
	dump(reqData)
	print("reqData.isPassed == " , reqData.isPassed)
	if 1 == checkint(reqData.isPassed) then
		AppFacade.GetInstance():DispatchObservers(ANNIVERSARY19_EXPLORE_RESULT_EVENT  , {result = checkint(reqData.isPassed) })
	else
		AppFacade.GetInstance():DispatchObservers(ANNIVERSARY19_EXPLORE_RESULT_EVENT  , {result = 2 })
	end
end

function BattleNetworkMediator:HandleAnniversary20MonsterQuestGradeResponse( signal )
	local responseData = signal:GetBody()
	local reqData = responseData.requestData
	local fightResult = json.decode(reqData.fightResult)
	local anniv2020Mgr = app.anniv2020Mgr
	for cardId, cardValues in pairs(fightResult) do
		anniv2020Mgr:setExploreTeamCardStateByCardId(cardId ,cardValues)
	end
	AppFacade.GetInstance():DispatchObservers(ANNIVERSARY20_EXPLORE_RESULT_EVENT  , {isPassed = checkint(reqData.isPassed) , mapGridId = reqData.gridId})
end

--[[
最后一步根据服务器返回执行下一步 准备进入战斗
@params signal table 信号源
--]]
function BattleNetworkMediator:CheckCaptchaAndGoNext(signal)
	local name = signal:GetName()
	local responseData = signal:GetBody()

	if nil ~= responseData.showCaptcha and 0 ~= checkint(responseData.showCaptcha) then
		-- 需要显示验证码
		AppFacade.GetInstance():DispatchObservers('SHOW_CAPTCHA_VIEW', {callback = function ()
			-- 验证码验证码结束 直接继续
			local callback = self.networkCallbacks[name]
			if nil ~= callback then
				xTry(function()
					callback(responseData)
				end,__G__TRACKBACK__)
			end
			-- 释放回调
			self.networkCallbacks[name] = nil
		end})
	else
		-- 不需要显示验证码 直接继续
		local callback = self.networkCallbacks[name]
		if nil ~= callback then
			xTry(function()
				callback(responseData)
			end,__G__TRACKBACK__)
		end
		-- 释放回调
		self.networkCallbacks[name] = nil
	end
end
---------------------------------------------------
-- response data handle logic end --
---------------------------------------------------

---------------------------------------------------
-- interface begin --
---------------------------------------------------
--[[
切换城市
@params requestData table 请求参数
@params callback function 请求回调函数
--]]
function BattleNetworkMediator:SwitchCity(requestData, callback)
	self.networkCallbacks[SIGNALNAMES.Quest_SwitchCity_Callback] = callback
	self:SendSignal(COMMANDS.COMMAND_Quest_SwitchCity, requestData)
end
--[[
抓宠 确定抓 请求一次服务器
@params requestData table 请求参数
@params callback function 请求回调函数
--]]
function BattleNetworkMediator:CatchPet(requestData, callback)
	-- 判断玩家堕神币是否足够抓宠
	local monsterConf = CommonUtils.GetConfig('monster', 'monster', requestData.monsterId)
	if monsterConf and (gameMgr:GetUserInfo().petCoin < checkint(monsterConf.petCoin)) then
		-- 堕神币不足
		uiMgr:ShowInformationTips(__('堕神币不足'))
		return
	end

	self.networkCallbacks[SIGNALNAMES.Battle_Quest_CatchPet_Callback] = callback
	self:SendSignal(COMMANDS.COMMANDS_Battle_Quest_CatchPet, requestData)
end
--[[
请求进入战斗
@params battleConstructor BattleConstructor 战斗构造器
@params callback function 请求回调函数
--]]
function BattleNetworkMediator:ReadyToEnterBattle(battleConstructor, callback)
	if BATTLE_LOCAL_SWITCH then
		-- local responseDataStr = '{"cards":[[],{"id":"8639","playerId":"84658","cardId":"200014","level":"1","exp":"0","breakLevel":"0","teamId":"0","vigour":"100","skill":{"10027":{"level":1},"10028":{"level":1}},"attack":21,"defence":27,"hp":213,"critRate":0.01,"critDamage":1.5,"attackRate":158},[],[],[]]}'
		-- local responseDataStr = '{"cards":[{"id":"35755","playerId":"88720","cardId":"200048","level":"120","exp":"2055966","breakLevel":"5","vigour":"100","skill":{"10095":{"level":1},"10096":{"level":1}},"businessSkill":[],"favorability":"0","favorabilityLevel":"1","createTime":"2017-08-26 15:15:40","defaultSkinId":"250480","attack":2383,"defence":340,"hp":9113,"critRate":0.24,"critDamage":1.7594,"attackRate":639},{"id":"35749","playerId":"88720","cardId":"200037","level":"120","exp":"2055966","breakLevel":"5","vigour":"100","skill":{"10073":{"level":1},"10074":{"level":1},"90037":{"level":1}},"businessSkill":[],"favorability":"0","favorabilityLevel":"1","createTime":"2017-08-26 15:15:39","defaultSkinId":"250370","attack":1702,"defence":679,"hp":9745,"critRate":0.1221,"critDamage":1.5851,"attackRate":1343},{"id":"35736","playerId":"88720","cardId":"200024","level":"120","exp":"2055966","breakLevel":"5","vigour":"100","skill":{"10047":{"level":1},"10048":{"level":1},"90024":{"level":1}},"businessSkill":[],"favorability":"0","favorabilityLevel":"1","createTime":"2017-08-26 15:15:39","defaultSkinId":"250240","attack":1844,"defence":488,"hp":8942,"critRate":0.3068,"critDamage":1.7397,"attackRate":586},{"id":"35718","playerId":"88720","cardId":"200002","level":"120","exp":"2055966","breakLevel":"5","vigour":"100","skill":{"10003":{"level":1},"10004":{"level":1},"90002":{"level":1}},"businessSkill":[],"favorability":"0","favorabilityLevel":"1","createTime":"2017-08-26 15:15:39","defaultSkinId":"250020","attack":2326,"defence":573,"hp":8072,"critRate":0.1759,"critDamage":1.6585,"attackRate":915},{"id":"35733","playerId":"88720","cardId":"200020","level":"120","exp":"2055966","breakLevel":"5","vigour":"100","skill":{"10039":{"level":1},"10040":{"level":1},"90020":{"level":1}},"businessSkill":[],"favorability":"0","favorabilityLevel":"1","createTime":"2017-08-26 15:15:39","defaultSkinId":"250200","attack":2497,"defence":616,"hp":10649,"critRate":0.106,"critDamage":1.5994,"attackRate":443}]}'
		callback(json.decode(responseDataStr))
		return
	end

	local serverCommand = battleConstructor:GetServerCommand()

	self.networkCallbacks[serverCommand.enterBattleResponseSignal] = callback

	-- 如果命令不存在 注册一次
	if not self:GetFacade():HasSignal(serverCommand.enterBattleRequestCommand) then
		self:GetFacade():RegistSignal(serverCommand.enterBattleRequestCommand, BattleCommand)
	end

	self:SendSignal(serverCommand.enterBattleRequestCommand, serverCommand.enterBattleRequestData)

end
--[[
战斗结束请求
@params battleConstructor BattleConstructor 战斗构造器
--]]
function BattleNetworkMediator:ReadyToExitBattle(battleConstructor, callback)

	if BATTLE_LOCAL_SWITCH then
		local responseDataStr = '{"data":{"mainExp":3770,"cardExp":{"7322":{"exp":100,"level":2}},"hp":76,"rewards":[{"goodsId":130001,"type":13,"num":2,"playerPetId":true},{"goodsId":160042,"type":16,"num":2,"playerPetId":true},{"goodsId":160004,"type":16,"num":1,"playerPetId":true}],"gold":100303,"monsters":[],"magicFood":{"magicFoodId":null,"num":null},"newestQuestId":"21","newestHardQuestId":"0","newestInsaneQuestId":"0","grade":3,"gradeConditionIds":[1,2,4]},"errcode":0,"errmsg":"","rand":"593904cd692bf1496909005","sign":"955e2bde3abebedf633a4ba632af3380"}'
		callback(json.decode(responseDataStr).data)
		return
	end

	local serverCommand = battleConstructor:GetServerCommand()
	
	self.networkCallbacks[serverCommand.exitBattleResponseSignal] = callback

	-- 如果命令不存在 注册一次
	if not self:GetFacade():HasSignal(serverCommand.exitBattleRequestCommand) then
		self:GetFacade():RegistSignal(serverCommand.exitBattleRequestCommand, BattleCommand)
	end

	self:SendSignal(serverCommand.exitBattleRequestCommand, serverCommand.exitBattleRequestData)

end
--[[
通用请求
@params requestCommand COMMANDS 请求的命令名称
@params responseSignal SIGNALNAMES 返回发送的信号
@params data table 请求的参数
@params callback 返回的回调
--]]
function BattleNetworkMediator:CommonNetworkRequest(requestCommand, responseSignal, data, callback)
	self.networkCallbacks[responseSignal] = callback

	-- 如果命令不存在 注册一次
	if not self:GetFacade():HasSignal(requestCommand) then
		self:GetFacade():RegistSignal(requestCommand, BattleCommand)
	end
	self:SendSignal(requestCommand, data)
end
---------------------------------------------------
-- interface end --
---------------------------------------------------


return BattleNetworkMediator

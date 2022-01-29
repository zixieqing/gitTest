local BattleConstructor = require('battleEntry.BattleConstructor')
local DebugBattleConstructor = class('DebugBattleConstructor', BattleConstructor)

__Require('battle.util.BStringUtils')

--[[
根据debug战斗工具初始化构造器数据
@params stageId int 关卡id
@params teamData table 队伍信息
@params playerSkillData table 主角技数据
--]]
function BattleConstructor:InitByDebugBattle()
	local stageId = nil

	-- 处理构造器数据
	local constructorData = String2TableNoMeta("{[\"canBuyCheat\"]=true,[\"rechallengeTime\"]=0,[\"questBattleType\"]=6,[\"randomConfig\"]={[\"randomseed\"]=\"5965557551\"},[\"time\"]=800,[\"friendPlayerSkill\"]={[\"activeSkill\"]={[1]={[\"skillId\"]=80069},[2]={[\"skillId\"]=80084}},[\"passiveSkill\"]={}},[\"globalEffects\"]={},[\"autoConnect\"]=false,[\"canRechallenge\"]=false,[\"enableConnect\"]=true,[\"buyRevivalTimeMax\"]=15,[\"openLevelRolling\"]=true,[\"buyRevivalTime\"]=0,[\"gameTimeScale\"]=2,[\"phaseChangeDatas\"]={},[\"weather\"]={[1]=\"1\"}}")

	------------ 处理构造器的原始数据 ------------
	local questBattleType 			= constructorData.questBattleType
	local randomConfig 				= self:Data2StructCommon(constructorData.randomConfig, BattleRandomConfigStruct)
	local gameTimeScale 			= constructorData.gameTimeScale
	local openLevelRolling 			= constructorData.openLevelRolling
	local abilityRelationInfo 		= self:Data2StructObjectAbilityRelationStructList(constructorData.abilityRelationInfo)
	local globalEffects 			= constructorData.globalEffects
	local enableConnect 			= constructorData.enableConnect
	local autoConnect 				= constructorData.autoConnect
	local enemyEnableConnect 	    = constructorData.enemyEnableConnect
	local enemyAutoConnect 		    = constructorData.enemyAutoConnect
	local canRechallenge 			= constructorData.canRechallenge
	local rechallengeTime 			= constructorData.rechallengeTime
	local canBuyCheat 				= constructorData.canBuyCheat
	local buyRevivalTime 			= constructorData.buyRevivalTime
	local buyRevivalTimeMax 		= constructorData.buyRevivalTimeMax
	local friendPlayerSkill 		= constructorData.friendPlayerSkill
	local enemyPlayerSkill 			= constructorData.enemyPlayerSkill
	local stageTime 				= constructorData.time
	local weatherInfo 				= constructorData.weather
	local phaseChangeInfo 			= constructorData.phaseChangeDatas
	------------ 处理构造器的原始数据 ------------

	local friendTeamJson = "[[{\"id\":\"10500\",\"playerId\":\"100699\",\"cardId\":\"200091\",\"level\":\"85\",\"exp\":\"651166\",\"breakLevel\":\"4\",\"vigour\":\"100\",\"skill\":{\"10181\":{\"level\":26},\"10182\":{\"level\":11},\"90091\":{\"level\":1}},\"businessSkill\":[],\"favorability\":\"454\",\"favorabilityLevel\":\"2\",\"createTime\":\"2018-08-29 10:01:03\",\"cardName\":null,\"defaultSkinId\":\"250910\",\"marryTime\":null,\"isArtifactUnlock\":\"0\",\"pets\":{\"1\":{\"petId\":\"210040\",\"level\":\"30\",\"breakLevel\":\"11\",\"character\":\"6\",\"attr\":[{\"type\":\"6\",\"num\":\"600\",\"quality\":\"5\"},{\"type\":\"6\",\"num\":\"600\",\"quality\":\"5\"},{\"type\":\"6\",\"num\":\"600\",\"quality\":\"5\"},{\"type\":\"6\",\"num\":\"600\",\"quality\":\"5\"}],\"isEvolution\":\"1\",\"playerPetId\":\"88695\"}},\"artifactTalent\":[],\"playerPetId\":\"88695\",\"attack\":2292,\"defence\":133,\"hp\":3997,\"critRate\":7045,\"critDamage\":5581,\"attackRate\":19157.400000000001},{\"id\":\"10837\",\"playerId\":\"100699\",\"cardId\":\"200132\",\"level\":\"85\",\"exp\":\"651166\",\"breakLevel\":\"3\",\"vigour\":\"100\",\"skill\":{\"10263\":{\"level\":21},\"10264\":{\"level\":20},\"90132\":{\"level\":1}},\"businessSkill\":[],\"favorability\":\"85\",\"favorabilityLevel\":\"1\",\"createTime\":\"2018-12-22 18:45:24\",\"cardName\":null,\"defaultSkinId\":\"251320\",\"marryTime\":null,\"isArtifactUnlock\":\"1\",\"pets\":{\"1\":{\"petId\":\"210060\",\"level\":\"30\",\"breakLevel\":\"11\",\"character\":\"6\",\"attr\":[{\"type\":\"6\",\"num\":\"600\",\"quality\":\"5\"},{\"type\":\"6\",\"num\":\"600\",\"quality\":\"5\"},{\"type\":\"6\",\"num\":\"600\",\"quality\":\"5\"},{\"type\":\"6\",\"num\":\"600\",\"quality\":\"5\"}],\"isEvolution\":\"1\",\"playerPetId\":\"102599\"}},\"artifactTalent\":{\"1\":{\"id\":\"343\",\"playerId\":\"100699\",\"playerCardId\":\"10837\",\"talentId\":\"1\",\"level\":\"2\",\"type\":\"1\",\"fragmentNum\":\"21\",\"gemstoneId\":null,\"createTime\":\"2019-04-24 20:39:26\"}},\"playerPetId\":\"102599\",\"attack\":1683,\"defence\":178,\"hp\":4380,\"critRate\":3941,\"critDamage\":2089,\"attackRate\":14916},{\"id\":\"11073\",\"playerId\":\"100699\",\"cardId\":\"200142\",\"level\":\"85\",\"exp\":\"648300\",\"breakLevel\":\"3\",\"vigour\":\"100\",\"skill\":{\"10283\":{\"level\":25},\"10284\":{\"level\":23},\"90142\":{\"level\":1}},\"businessSkill\":[],\"favorability\":\"16\",\"favorabilityLevel\":\"1\",\"createTime\":\"2019-04-23 01:15:45\",\"cardName\":null,\"defaultSkinId\":\"251420\",\"marryTime\":null,\"isArtifactUnlock\":\"0\",\"pets\":{\"1\":{\"petId\":\"210012\",\"level\":\"30\",\"breakLevel\":\"11\",\"character\":\"1\",\"attr\":[{\"type\":\"1\",\"num\":\"60\",\"quality\":\"5\"},{\"type\":\"1\",\"num\":\"60\",\"quality\":\"5\"},{\"type\":\"1\",\"num\":\"60\",\"quality\":\"5\"},{\"type\":\"1\",\"num\":\"60\",\"quality\":\"5\"}],\"isEvolution\":\"1\",\"playerPetId\":\"72648\"}},\"artifactTalent\":[],\"playerPetId\":\"72648\",\"attack\":3003.1999999999998,\"defence\":162,\"hp\":4249,\"critRate\":3580,\"critDamage\":1230,\"attackRate\":3093},{\"id\":\"8054\",\"playerId\":\"100699\",\"cardId\":\"200004\",\"level\":\"85\",\"exp\":\"650966\",\"breakLevel\":\"2\",\"vigour\":\"100\",\"skill\":{\"10007\":{\"level\":17},\"10008\":{\"level\":9},\"90004\":{\"level\":1}},\"businessSkill\":[],\"favorability\":\"608\",\"favorabilityLevel\":\"3\",\"createTime\":\"2017-12-11 20:13:04\",\"cardName\":null,\"defaultSkinId\":\"250040\",\"marryTime\":null,\"isArtifactUnlock\":\"1\",\"pets\":{\"1\":{\"petId\":\"210040\",\"level\":\"30\",\"breakLevel\":\"13\",\"character\":\"3\",\"attr\":[{\"type\":\"3\",\"num\":\"700\",\"quality\":\"5\"},{\"type\":\"3\",\"num\":\"700\",\"quality\":\"5\"},{\"type\":\"3\",\"num\":\"700\",\"quality\":\"5\"},{\"type\":\"3\",\"num\":\"700\",\"quality\":\"5\"}],\"isEvolution\":\"1\",\"playerPetId\":\"75617\"}},\"artifactTalent\":{\"2\":{\"id\":\"154\",\"playerId\":\"100699\",\"playerCardId\":\"8054\",\"talentId\":\"2\",\"level\":\"2\",\"type\":\"1\",\"fragmentNum\":\"27\",\"gemstoneId\":null,\"createTime\":\"2018-12-13 10:26:55\"},\"3\":{\"id\":\"164\",\"playerId\":\"100699\",\"playerCardId\":\"8054\",\"talentId\":\"3\",\"level\":\"1\",\"type\":\"2\",\"fragmentNum\":\"50\",\"gemstoneId\":\"282005\",\"createTime\":\"2018-12-14 20:41:47\"},\"4\":{\"id\":\"165\",\"playerId\":\"100699\",\"playerCardId\":\"8054\",\"talentId\":\"4\",\"level\":\"2\",\"type\":\"1\",\"fragmentNum\":\"36\",\"gemstoneId\":null,\"createTime\":\"2018-12-14 20:41:51\"},\"5\":{\"id\":\"166\",\"playerId\":\"100699\",\"playerCardId\":\"8054\",\"talentId\":\"5\",\"level\":\"2\",\"type\":\"1\",\"fragmentNum\":\"42\",\"gemstoneId\":null,\"createTime\":\"2018-12-14 20:41:55\"},\"8\":{\"id\":\"169\",\"playerId\":\"100699\",\"playerCardId\":\"8054\",\"talentId\":\"8\",\"level\":\"3\",\"type\":\"1\",\"fragmentNum\":\"87\",\"gemstoneId\":null,\"createTime\":\"2018-12-14 20:42:10\"},\"7\":{\"id\":\"168\",\"playerId\":\"100699\",\"playerCardId\":\"8054\",\"talentId\":\"7\",\"level\":\"2\",\"type\":\"1\",\"fragmentNum\":\"51\",\"gemstoneId\":null,\"createTime\":\"2018-12-14 20:42:05\"},\"1\":{\"id\":\"153\",\"playerId\":\"100699\",\"playerCardId\":\"8054\",\"talentId\":\"1\",\"level\":\"2\",\"type\":\"1\",\"fragmentNum\":\"21\",\"gemstoneId\":null,\"createTime\":\"2018-12-13 10:26:53\"},\"6\":{\"id\":\"167\",\"playerId\":\"100699\",\"playerCardId\":\"8054\",\"talentId\":\"6\",\"level\":\"1\",\"type\":\"2\",\"fragmentNum\":\"100\",\"gemstoneId\":\"285104\",\"createTime\":\"2018-12-14 20:41:59\"}},\"playerPetId\":\"75617\",\"attack\":451,\"defence\":299,\"hp\":24746.760000000002,\"critRate\":3894,\"critDamage\":6489,\"attackRate\":6775.6000000000004},{\"id\":\"10182\",\"playerId\":\"100699\",\"cardId\":\"200037\",\"level\":\"85\",\"exp\":\"651066\",\"breakLevel\":\"4\",\"vigour\":\"100\",\"skill\":{\"10073\":{\"level\":22},\"10074\":{\"level\":13},\"90037\":{\"level\":1}},\"businessSkill\":{\"30103\":{\"level\":1}},\"favorability\":\"83\",\"favorabilityLevel\":\"1\",\"createTime\":\"2018-07-05 01:05:53\",\"cardName\":null,\"defaultSkinId\":\"250370\",\"marryTime\":null,\"isArtifactUnlock\":\"0\",\"pets\":{\"1\":{\"petId\":\"210040\",\"level\":\"30\",\"breakLevel\":\"11\",\"character\":\"6\",\"attr\":[{\"type\":\"6\",\"num\":\"600\",\"quality\":\"5\"},{\"type\":\"6\",\"num\":\"600\",\"quality\":\"5\"},{\"type\":\"6\",\"num\":\"600\",\"quality\":\"5\"},{\"type\":\"6\",\"num\":\"600\",\"quality\":\"5\"}],\"isEvolution\":\"1\",\"playerPetId\":\"111652\"}},\"artifactTalent\":[],\"playerPetId\":\"111652\",\"attack\":992,\"defence\":355,\"hp\":5608,\"critRate\":2473,\"critDamage\":1811,\"attackRate\":24151}]]"
	local enemyTeamJson = "[[{\"cardId\":\"370050\",\"campType\":null,\"level\":\"42\",\"attrGrow\":\"31.2\",\"skillGrow\":\"31.2\",\"placeId\":\"19\",\"initialHp\":null,\"initialHpValue\":null},{\"cardId\":\"370050\",\"campType\":null,\"level\":\"42\",\"attrGrow\":\"31.2\",\"skillGrow\":\"31.2\",\"placeId\":\"47\",\"initialHp\":null,\"initialHpValue\":null},{\"cardId\":\"370073\",\"campType\":null,\"level\":\"42\",\"attrGrow\":\"31.2\",\"skillGrow\":\"31.2\",\"placeId\":\"25\",\"initialHp\":null,\"initialHpValue\":null},{\"cardId\":\"370073\",\"campType\":null,\"level\":\"42\",\"attrGrow\":\"31.2\",\"skillGrow\":\"31.2\",\"placeId\":\"53\",\"initialHp\":null,\"initialHpValue\":null}],[{\"cardId\":\"370052\",\"campType\":null,\"level\":\"42\",\"attrGrow\":\"31.2\",\"skillGrow\":\"31.2\",\"placeId\":\"33\",\"initialHp\":null,\"initialHpValue\":null},{\"cardId\":\"370073\",\"campType\":null,\"level\":\"42\",\"attrGrow\":\"31.2\",\"skillGrow\":\"31.2\",\"placeId\":\"23\",\"initialHp\":null,\"initialHpValue\":null},{\"cardId\":\"370073\",\"campType\":null,\"level\":\"42\",\"attrGrow\":\"31.2\",\"skillGrow\":\"31.2\",\"placeId\":\"51\",\"initialHp\":null,\"initialHpValue\":null},{\"cardId\":\"370073\",\"campType\":null,\"level\":\"42\",\"attrGrow\":\"31.2\",\"skillGrow\":\"31.2\",\"placeId\":\"39\",\"initialHp\":null,\"initialHpValue\":null}],[{\"cardId\":\"370074\",\"campType\":null,\"level\":\"42\",\"attrGrow\":\"31.2\",\"skillGrow\":\"31.2\",\"placeId\":\"33\",\"initialHp\":null,\"initialHpValue\":null},{\"cardId\":\"370050\",\"campType\":null,\"level\":\"42\",\"attrGrow\":\"31.2\",\"skillGrow\":\"31.2\",\"placeId\":\"23\",\"initialHp\":null,\"initialHpValue\":null},{\"cardId\":\"370050\",\"campType\":null,\"level\":\"42\",\"attrGrow\":\"31.2\",\"skillGrow\":\"31.2\",\"placeId\":\"51\",\"initialHp\":null,\"initialHpValue\":null}],[{\"cardId\":\"370052\",\"campType\":null,\"level\":\"42\",\"attrGrow\":\"31.2\",\"skillGrow\":\"31.2\",\"placeId\":\"33\",\"initialHp\":null,\"initialHpValue\":null},{\"cardId\":\"370073\",\"campType\":null,\"level\":\"42\",\"attrGrow\":\"31.2\",\"skillGrow\":\"31.2\",\"placeId\":\"23\",\"initialHp\":null,\"initialHpValue\":null},{\"cardId\":\"370073\",\"campType\":null,\"level\":\"42\",\"attrGrow\":\"31.2\",\"skillGrow\":\"31.2\",\"placeId\":\"51\",\"initialHp\":null,\"initialHpValue\":null}],[{\"cardId\":\"370050\",\"campType\":null,\"level\":\"42\",\"attrGrow\":\"31.2\",\"skillGrow\":\"31.2\",\"placeId\":\"17\",\"initialHp\":null,\"initialHpValue\":null},{\"cardId\":\"370050\",\"campType\":null,\"level\":\"42\",\"attrGrow\":\"31.2\",\"skillGrow\":\"31.2\",\"placeId\":\"45\",\"initialHp\":null,\"initialHpValue\":null},{\"cardId\":\"370073\",\"campType\":null,\"level\":\"42\",\"attrGrow\":\"31.2\",\"skillGrow\":\"31.2\",\"placeId\":\"35\",\"initialHp\":null,\"initialHpValue\":null},{\"cardId\":\"370053\",\"campType\":null,\"level\":\"42\",\"attrGrow\":\"31.2\",\"skillGrow\":\"31.2\",\"placeId\":\"39\",\"initialHp\":null,\"initialHpValue\":null}],[{\"cardId\":\"370052\",\"campType\":null,\"level\":\"42\",\"attrGrow\":\"31.2\",\"skillGrow\":\"31.2\",\"placeId\":\"33\",\"initialHp\":null,\"initialHpValue\":null},{\"cardId\":\"370073\",\"campType\":null,\"level\":\"42\",\"attrGrow\":\"31.2\",\"skillGrow\":\"31.2\",\"placeId\":\"23\",\"initialHp\":null,\"initialHpValue\":null},{\"cardId\":\"370073\",\"campType\":null,\"level\":\"42\",\"attrGrow\":\"31.2\",\"skillGrow\":\"31.2\",\"placeId\":\"51\",\"initialHp\":null,\"initialHpValue\":null}],[{\"cardId\":\"370050\",\"campType\":null,\"level\":\"42\",\"attrGrow\":\"31.2\",\"skillGrow\":\"31.2\",\"placeId\":\"19\",\"initialHp\":null,\"initialHpValue\":null},{\"cardId\":\"370050\",\"campType\":null,\"level\":\"42\",\"attrGrow\":\"31.2\",\"skillGrow\":\"31.2\",\"placeId\":\"47\",\"initialHp\":null,\"initialHpValue\":null},{\"cardId\":\"370073\",\"campType\":null,\"level\":\"42\",\"attrGrow\":\"31.2\",\"skillGrow\":\"31.2\",\"placeId\":\"25\",\"initialHp\":null,\"initialHpValue\":null},{\"cardId\":\"370073\",\"campType\":null,\"level\":\"42\",\"attrGrow\":\"31.2\",\"skillGrow\":\"31.2\",\"placeId\":\"53\",\"initialHp\":null,\"initialHpValue\":null}],[{\"cardId\":\"370052\",\"campType\":null,\"level\":\"42\",\"attrGrow\":\"31.2\",\"skillGrow\":\"31.2\",\"placeId\":\"17\",\"initialHp\":null,\"initialHpValue\":null},{\"cardId\":\"370052\",\"campType\":null,\"level\":\"42\",\"attrGrow\":\"31.2\",\"skillGrow\":\"31.2\",\"placeId\":\"45\",\"initialHp\":null,\"initialHpValue\":null},{\"cardId\":\"370073\",\"campType\":null,\"level\":\"42\",\"attrGrow\":\"31.2\",\"skillGrow\":\"31.2\",\"placeId\":\"21\",\"initialHp\":null,\"initialHpValue\":null},{\"cardId\":\"370073\",\"campType\":null,\"level\":\"42\",\"attrGrow\":\"31.2\",\"skillGrow\":\"31.2\",\"placeId\":\"49\",\"initialHp\":null,\"initialHpValue\":null},{\"cardId\":\"370051\",\"campType\":null,\"level\":\"42\",\"attrGrow\":\"31.2\",\"skillGrow\":\"31.2\",\"placeId\":\"25\",\"initialHp\":null,\"initialHpValue\":null},{\"cardId\":\"370051\",\"campType\":null,\"level\":\"42\",\"attrGrow\":\"31.2\",\"skillGrow\":\"31.2\",\"placeId\":\"39\",\"initialHp\":null,\"initialHpValue\":null},{\"cardId\":\"370051\",\"campType\":null,\"level\":\"42\",\"attrGrow\":\"31.2\",\"skillGrow\":\"31.2\",\"placeId\":\"53\",\"initialHp\":null,\"initialHpValue\":null}],[{\"cardId\":\"370053\",\"campType\":null,\"level\":\"42\",\"attrGrow\":\"31.2\",\"skillGrow\":\"31.2\",\"placeId\":\"33\",\"initialHp\":null,\"initialHpValue\":null},{\"cardId\":\"370053\",\"campType\":null,\"level\":\"42\",\"attrGrow\":\"31.2\",\"skillGrow\":\"31.2\",\"placeId\":\"39\",\"initialHp\":null,\"initialHpValue\":null}],[{\"cardId\":\"370054\",\"campType\":null,\"level\":\"42\",\"attrGrow\":\"31.2\",\"skillGrow\":\"31.2\",\"placeId\":\"47\",\"initialHp\":null,\"initialHpValue\":null},{\"cardId\":\"370053\",\"campType\":null,\"level\":\"42\",\"attrGrow\":\"31.2\",\"skillGrow\":\"31.2\",\"placeId\":\"53\",\"initialHp\":null,\"initialHpValue\":null}]]"

	------------ 处理友方阵容信息 ------------
	-- 阵容信息
	local formattedFriendTeamData = self:ConvertTeamDataByJson(friendTeamJson)
	-- 主角技信息
	local formattedFriendPlayerSkillData = self:ConvertPlayerSkillByJson(friendPlayerSkillJson)

	local friendFormationData = FormationStruct.New(
		nil,
		formattedFriendTeamData,
		friendPlayerSkill,
		self:GetObjPFixedAttrByQuestBattleType(questBattleType)
	)
	------------ 处理友方阵容信息 ------------

	------------ 处理敌方阵容信息 ------------
	-- 阵容信息
	local formattedEnemyTeamData = self:ConvertTeamDataByJson(enemyTeamJson)
	-- 主角技信息
	local formattedEnemyPlayerSkillData = nil
	if nil ~= enemyPlayerSkillJson then
		formattedEnemyPlayerSkillData = self:ConvertPlayerSkillByJson(enemyPlayerSkillJson)
	end

	local enemyFormationData = FormationStruct.New(
		nil,
		formattedEnemyTeamData,
		enemyPlayerSkill,
		self:GetObjPFixedAttrByQuestBattleType(questBattleType)
	)
	------------ 处理敌方阵容信息 ------------

	------------ 处理每一波的过关条件 ------------
	local totalWave = #formattedEnemyTeamData
	local stageCompleteInfo = self:GetFormattedStageCompleteInfo(stageId, questBattleType, totalWave)
	------------ 处理每一波的过关条件 ------------

	local battleConstructorData = BattleConstructorStruct.New(
		------------ 战斗基本配置 ------------
		stageId, -- int 关卡id
		questBattleType, -- QuestBattleType 战斗类型
		randomConfig, -- BattleRandomConfigStruct 战斗随机数配置
		gameTimeScale, -- int 游戏运行速度缩放
		stageTime, -- int 战斗时间限制 second
		totalWave, -- int 总波数
		ConfigBattleResultType.NORMAL, -- 结算类型
		stageCompleteInfo, -- list(StageCompleteSturct) 过关条件
		false,
		false,
		------------ 战斗数值配置 ------------
		openLevelRolling, -- bool 是否开启等级碾压
		------------ 战斗环境配置 ------------
		weatherInfo, -- table 天气
		phaseChangeInfo, -- map 阶段转换信息
		abilityRelationInfo, -- list<ObjectAbilityRelationStruct>
		globalEffects, -- list 全局效果列表
		enableConnect, -- bool 己方 连携技可用
		autoConnect, -- bool 己方 自动释放连携技
		enemyEnableConnect, -- bool 敌方 连携技可用
		enemyAutoConnect, -- bool 敌方 自动释放连携技
		------------ 其他信息 ------------
		nil, -- table 三星条件
		canRechallenge, -- bool 是否可以重复挑战
		rechallengeTime, -- int 剩余挑战次数
		canBuyCheat, -- bool 是否可以买活
		buyRevivalTime, -- int 已买活次数
		buyRevivalTimeMax, -- int 最大买活次数 
		------------ 战斗场景配置 ------------
		{BattleBackgroundStruct.New(1)}, -- list 背景图信息
		nil, -- list<ConfigBattleFunctionModuleType> 隐藏的战斗功能模块界面
		------------ 友方阵容信息 ------------
		friendFormationData, -- FormationStruct 友方阵容信息
		------------ 敌方阵容信息 ------------
		enemyFormationData, -- FormationStruct 敌方阵容信息
		------------ 头尾服务器交互命令 ------------
		nil, -- BattleNetworkCommandStruct 与服务器交互的命令信息
		------------ 头尾跳转信息 ------------
		nil -- BattleMediatorsConnectStruct 跳转信息
	)

	self.battleConstructorData = battleConstructorData
end

--[[
@params enemyTeams list 敌方阵容
@params friendAllSkills list 友方主角技
@params enemyAllSkills list 敌方主角技
@params serverCommand BattleNetworkCommandStruct 与服务器交互的命令信息
@params fromtoData BattleMediatorsConnectStruct 跳转信息
--]]
function DebugBattleConstructor:InitDataByDebugTagMatchThreeTeams()
	-- debug --
	-- friendAllSkills = {80001, 80041}
	-- enemyAllSkills = {80001}
	-- debug --

	local constructorJson = "{\"canBuyCheat\":true,\"rechallengeTime\":0,\"questBattleType\":6,\"randomConfig\":{\"randomseed\":\"5508264551\"},\"time\":600,\"friendPlayerSkill\":{\"activeSkill\":[{\"skillId\":80072},{\"skillId\":80084}],\"passiveSkill\":{}},\"globalEffects\":{},\"autoConnect\":false,\"canRechallenge\":false,\"enableConnect\":true,\"buyRevivalTimeMax\":15,\"openLevelRolling\":true,\"buyRevivalTime\":0,\"gameTimeScale\":2,\"phaseChangeDatas\":{},\"weather\":[\"1\"]}"
	local constructorData = json.decode(constructorJson)

	------------ 处理构造器的原始数据 ------------
	local questBattleType 			= constructorData.questBattleType
	local randomConfig 				= self:Data2StructCommon(constructorData.randomConfig, BattleRandomConfigStruct)
	local gameTimeScale 			= constructorData.gameTimeScale
	local openLevelRolling 			= constructorData.openLevelRolling
	local abilityRelationInfo 		= self:Data2StructObjectAbilityRelationStructList(constructorData.abilityRelationInfo)
	local globalEffects 			= constructorData.globalEffects
	local enableConnect 			= constructorData.enableConnect
	local autoConnect 				= constructorData.autoConnect
	local enemyEnableConnect 	    = constructorData.enemyEnableConnect
	local enemyAutoConnect 		    = constructorData.enemyAutoConnect
	local canRechallenge 			= constructorData.canRechallenge
	local rechallengeTime 			= constructorData.rechallengeTime
	local canBuyCheat 				= constructorData.canBuyCheat
	local buyRevivalTime 			= constructorData.buyRevivalTime
	local buyRevivalTimeMax 		= constructorData.buyRevivalTimeMax
	local friendPlayerSkill 		= constructorData.friendPlayerSkill
	local enemyPlayerSkill 			= constructorData.enemyPlayerSkill
	local stageTime 				= constructorData.time
	local weatherInfo 				= constructorData.weather
	local phaseChangeInfo 			= constructorData.phaseChangeDatas
	------------ 处理构造器的原始数据 ------------

	local friendTeamJson = "[[{\"id\":\"4020\",\"playerId\":\"102306\",\"cardId\":\"200039\",\"level\":\"64\",\"exp\":\"262788\",\"breakLevel\":\"4\",\"vigour\":\"94\",\"skill\":{\"10077\":{\"level\":22},\"10078\":{\"level\":22},\"90039\":{\"level\":1}},\"businessSkill\":[],\"favorability\":\"293\",\"favorabilityLevel\":\"2\",\"createTime\":\"2017-11-25 00:36:35\",\"cardName\":null,\"defaultSkinId\":\"250390\",\"marryTime\":null,\"isArtifactUnlock\":\"0\",\"pets\":{\"1\":{\"petId\":\"210054\",\"level\":\"30\",\"breakLevel\":\"7\",\"character\":\"2\",\"attr\":[{\"type\":\"3\",\"num\":\"425\",\"quality\":\"4\"},{\"type\":\"2\",\"num\":\"21\",\"quality\":\"4\"},{\"type\":\"2\",\"num\":\"21\",\"quality\":\"4\"},{\"type\":\"2\",\"num\":\"21\",\"quality\":\"4\"}],\"isEvolution\":\"0\",\"playerPetId\":\"92047\"}},\"artifactTalent\":[],\"playerPetId\":\"92047\",\"attack\":213,\"defence\":407.16499999999996,\"hp\":3429.25,\"critRate\":2148,\"critDamage\":2307,\"attackRate\":2162},{\"id\":\"10740\",\"playerId\":\"102306\",\"cardId\":\"200142\",\"level\":\"64\",\"exp\":\"263194\",\"breakLevel\":\"3\",\"vigour\":\"82\",\"skill\":{\"10283\":{\"level\":22},\"10284\":{\"level\":21},\"90142\":{\"level\":1}},\"businessSkill\":[],\"favorability\":\"250\",\"favorabilityLevel\":\"2\",\"createTime\":\"2019-02-19 19:47:26\",\"cardName\":null,\"defaultSkinId\":\"251420\",\"marryTime\":null,\"isArtifactUnlock\":\"0\",\"pets\":{\"1\":{\"petId\":\"210058\",\"level\":\"24\",\"breakLevel\":\"7\",\"character\":\"1\",\"attr\":[{\"type\":\"1\",\"num\":\"25\",\"quality\":\"3\"},{\"type\":\"1\",\"num\":\"40\",\"quality\":\"4\"},{\"type\":\"1\",\"num\":\"40\",\"quality\":\"4\"},{\"type\":\"4\",\"num\":\"160\",\"quality\":\"4\"}],\"isEvolution\":\"0\",\"playerPetId\":\"104969\"}},\"artifactTalent\":[],\"playerPetId\":\"104969\",\"attack\":1659.0925,\"defence\":127,\"hp\":3332,\"critRate\":3580,\"critDamage\":1230,\"attackRate\":3093},{\"id\":\"4174\",\"playerId\":\"102306\",\"cardId\":\"200037\",\"level\":\"64\",\"exp\":\"263166\",\"breakLevel\":\"2\",\"vigour\":\"91\",\"skill\":{\"10073\":{\"level\":14},\"10074\":{\"level\":10},\"90037\":{\"level\":10}},\"businessSkill\":{\"30103\":{\"level\":1}},\"favorability\":\"418\",\"favorabilityLevel\":\"2\",\"createTime\":\"2017-11-25 12:20:47\",\"cardName\":null,\"defaultSkinId\":\"250370\",\"marryTime\":null,\"isArtifactUnlock\":\"0\",\"pets\":{\"1\":{\"petId\":\"210023\",\"level\":\"12\",\"breakLevel\":\"6\",\"character\":\"3\",\"attr\":[{\"type\":\"1\",\"num\":\"15\",\"quality\":\"2\"},{\"type\":\"1\",\"num\":\"25\",\"quality\":\"3\"},{\"type\":\"1\",\"num\":\"10\",\"quality\":\"1\"},{\"type\":\"3\",\"num\":\"100\",\"quality\":\"1\"}],\"isEvolution\":\"0\",\"playerPetId\":\"20568\"}},\"artifactTalent\":[],\"playerPetId\":\"20568\",\"attack\":528.60000000000002,\"defence\":141,\"hp\":2370,\"critRate\":1569,\"critDamage\":1159,\"attackRate\":7059},{\"id\":\"7494\",\"playerId\":\"102306\",\"cardId\":\"200024\",\"level\":\"64\",\"exp\":\"263016\",\"breakLevel\":\"2\",\"vigour\":\"100\",\"skill\":{\"10047\":{\"level\":18},\"10048\":{\"level\":13},\"90024\":{\"level\":6}},\"businessSkill\":[],\"favorability\":\"164\",\"favorabilityLevel\":\"1\",\"createTime\":\"2017-12-08 14:20:17\",\"cardName\":null,\"defaultSkinId\":\"250240\",\"marryTime\":null,\"isArtifactUnlock\":\"0\",\"pets\":{\"1\":{\"petId\":\"210018\",\"level\":\"20\",\"breakLevel\":\"4\",\"character\":\"6\",\"attr\":[{\"type\":\"6\",\"num\":\"260\",\"quality\":\"4\"},{\"type\":\"6\",\"num\":\"170\",\"quality\":\"2\"},{\"type\":\"6\",\"num\":\"210\",\"quality\":\"3\"},{\"type\":\"1\",\"num\":\"43\",\"quality\":\"4\"}],\"isEvolution\":\"0\",\"playerPetId\":\"105627\"}},\"artifactTalent\":[],\"playerPetId\":\"105627\",\"attack\":495,\"defence\":102,\"hp\":2175,\"critRate\":3986,\"critDamage\":3164,\"attackRate\":3701.1000000000004},{\"id\":\"7496\",\"playerId\":\"102306\",\"cardId\":\"200048\",\"level\":\"64\",\"exp\":\"263244\",\"breakLevel\":\"3\",\"vigour\":\"100\",\"skill\":{\"10095\":{\"level\":19},\"10096\":{\"level\":15},\"90048\":{\"level\":11}},\"businessSkill\":{\"30096\":{\"level\":1}},\"favorability\":\"507\",\"favorabilityLevel\":\"2\",\"createTime\":\"2017-12-08 14:21:41\",\"cardName\":null,\"defaultSkinId\":\"250480\",\"marryTime\":null,\"isArtifactUnlock\":\"0\",\"pets\":{\"1\":{\"petId\":\"210025\",\"level\":\"21\",\"breakLevel\":\"5\",\"character\":\"1\",\"attr\":[{\"type\":\"1\",\"num\":\"43\",\"quality\":\"4\"},{\"type\":\"1\",\"num\":\"43\",\"quality\":\"4\"},{\"type\":\"1\",\"num\":\"43\",\"quality\":\"4\"},{\"type\":\"2\",\"num\":\"21\",\"quality\":\"4\"}],\"isEvolution\":\"0\",\"playerPetId\":\"85069\"}},\"artifactTalent\":[],\"playerPetId\":\"85069\",\"attack\":1201.665,\"defence\":97,\"hp\":3057,\"critRate\":4043,\"critDamage\":4885,\"attackRate\":3118}]]"
	local enemyTeamJson = "[[{\"cardId\":\"370082\",\"campType\":null,\"level\":\"42\",\"attrGrow\":\"15.4\",\"skillGrow\":\"15.4\",\"placeId\":\"19\",\"initialHp\":null,\"initialHpValue\":null},{\"cardId\":\"370082\",\"campType\":null,\"level\":\"42\",\"attrGrow\":\"15.4\",\"skillGrow\":\"15.4\",\"placeId\":\"47\",\"initialHp\":null,\"initialHpValue\":null},{\"cardId\":\"370083\",\"campType\":null,\"level\":\"42\",\"attrGrow\":\"15.4\",\"skillGrow\":\"15.4\",\"placeId\":\"25\",\"initialHp\":null,\"initialHpValue\":null},{\"cardId\":\"370083\",\"campType\":null,\"level\":\"42\",\"attrGrow\":\"15.4\",\"skillGrow\":\"15.4\",\"placeId\":\"53\",\"initialHp\":null,\"initialHpValue\":null}],[{\"cardId\":\"370080\",\"campType\":null,\"level\":\"42\",\"attrGrow\":\"15.4\",\"skillGrow\":\"15.4\",\"placeId\":\"33\",\"initialHp\":null,\"initialHpValue\":null},{\"cardId\":\"370083\",\"campType\":null,\"level\":\"42\",\"attrGrow\":\"15.4\",\"skillGrow\":\"15.4\",\"placeId\":\"23\",\"initialHp\":null,\"initialHpValue\":null},{\"cardId\":\"370083\",\"campType\":null,\"level\":\"42\",\"attrGrow\":\"15.4\",\"skillGrow\":\"15.4\",\"placeId\":\"51\",\"initialHp\":null,\"initialHpValue\":null},{\"cardId\":\"370083\",\"campType\":null,\"level\":\"42\",\"attrGrow\":\"15.4\",\"skillGrow\":\"15.4\",\"placeId\":\"39\",\"initialHp\":null,\"initialHpValue\":null}],[{\"cardId\":\"370080\",\"campType\":null,\"level\":\"42\",\"attrGrow\":\"15.4\",\"skillGrow\":\"15.4\",\"placeId\":\"33\",\"initialHp\":null,\"initialHpValue\":null},{\"cardId\":\"370083\",\"campType\":null,\"level\":\"42\",\"attrGrow\":\"15.4\",\"skillGrow\":\"15.4\",\"placeId\":\"23\",\"initialHp\":null,\"initialHpValue\":null},{\"cardId\":\"370083\",\"campType\":null,\"level\":\"42\",\"attrGrow\":\"15.4\",\"skillGrow\":\"15.4\",\"placeId\":\"51\",\"initialHp\":null,\"initialHpValue\":null}],[{\"cardId\":\"370082\",\"campType\":null,\"level\":\"42\",\"attrGrow\":\"15.4\",\"skillGrow\":\"15.4\",\"placeId\":\"17\",\"initialHp\":null,\"initialHpValue\":null},{\"cardId\":\"370082\",\"campType\":null,\"level\":\"42\",\"attrGrow\":\"15.4\",\"skillGrow\":\"15.4\",\"placeId\":\"45\",\"initialHp\":null,\"initialHpValue\":null},{\"cardId\":\"370083\",\"campType\":null,\"level\":\"42\",\"attrGrow\":\"15.4\",\"skillGrow\":\"15.4\",\"placeId\":\"35\",\"initialHp\":null,\"initialHpValue\":null},{\"cardId\":\"370084\",\"campType\":null,\"level\":\"42\",\"attrGrow\":\"15.4\",\"skillGrow\":\"15.4\",\"placeId\":\"39\",\"initialHp\":null,\"initialHpValue\":null}],[{\"cardId\":\"370080\",\"campType\":null,\"level\":\"42\",\"attrGrow\":\"15.4\",\"skillGrow\":\"15.4\",\"placeId\":\"33\",\"initialHp\":null,\"initialHpValue\":null},{\"cardId\":\"370083\",\"campType\":null,\"level\":\"42\",\"attrGrow\":\"15.4\",\"skillGrow\":\"15.4\",\"placeId\":\"23\",\"initialHp\":null,\"initialHpValue\":null},{\"cardId\":\"370083\",\"campType\":null,\"level\":\"42\",\"attrGrow\":\"15.4\",\"skillGrow\":\"15.4\",\"placeId\":\"51\",\"initialHp\":null,\"initialHpValue\":null}],[{\"cardId\":\"370082\",\"campType\":null,\"level\":\"42\",\"attrGrow\":\"15.4\",\"skillGrow\":\"15.4\",\"placeId\":\"19\",\"initialHp\":null,\"initialHpValue\":null},{\"cardId\":\"370082\",\"campType\":null,\"level\":\"42\",\"attrGrow\":\"15.4\",\"skillGrow\":\"15.4\",\"placeId\":\"47\",\"initialHp\":null,\"initialHpValue\":null},{\"cardId\":\"370083\",\"campType\":null,\"level\":\"42\",\"attrGrow\":\"15.4\",\"skillGrow\":\"15.4\",\"placeId\":\"25\",\"initialHp\":null,\"initialHpValue\":null},{\"cardId\":\"370083\",\"campType\":null,\"level\":\"42\",\"attrGrow\":\"15.4\",\"skillGrow\":\"15.4\",\"placeId\":\"53\",\"initialHp\":null,\"initialHpValue\":null}],[{\"cardId\":\"370080\",\"campType\":null,\"level\":\"42\",\"attrGrow\":\"15.4\",\"skillGrow\":\"15.4\",\"placeId\":\"17\",\"initialHp\":null,\"initialHpValue\":null},{\"cardId\":\"370080\",\"campType\":null,\"level\":\"42\",\"attrGrow\":\"15.4\",\"skillGrow\":\"15.4\",\"placeId\":\"45\",\"initialHp\":null,\"initialHpValue\":null},{\"cardId\":\"370083\",\"campType\":null,\"level\":\"42\",\"attrGrow\":\"15.4\",\"skillGrow\":\"15.4\",\"placeId\":\"21\",\"initialHp\":null,\"initialHpValue\":null},{\"cardId\":\"370083\",\"campType\":null,\"level\":\"42\",\"attrGrow\":\"15.4\",\"skillGrow\":\"15.4\",\"placeId\":\"49\",\"initialHp\":null,\"initialHpValue\":null},{\"cardId\":\"370083\",\"campType\":null,\"level\":\"42\",\"attrGrow\":\"15.4\",\"skillGrow\":\"15.4\",\"placeId\":\"25\",\"initialHp\":null,\"initialHpValue\":null},{\"cardId\":\"370083\",\"campType\":null,\"level\":\"42\",\"attrGrow\":\"15.4\",\"skillGrow\":\"15.4\",\"placeId\":\"39\",\"initialHp\":null,\"initialHpValue\":null},{\"cardId\":\"370083\",\"campType\":null,\"level\":\"42\",\"attrGrow\":\"15.4\",\"skillGrow\":\"15.4\",\"placeId\":\"53\",\"initialHp\":null,\"initialHpValue\":null}],[{\"cardId\":\"370085\",\"campType\":null,\"level\":\"42\",\"attrGrow\":\"15.4\",\"skillGrow\":\"15.4\",\"placeId\":\"47\",\"initialHp\":null,\"initialHpValue\":null},{\"cardId\":\"370084\",\"campType\":null,\"level\":\"42\",\"attrGrow\":\"15.4\",\"skillGrow\":\"15.4\",\"placeId\":\"53\",\"initialHp\":null,\"initialHpValue\":null}]]"

	------------ 处理友方阵容信息 ------------
	local formattedFriendTeamData = self:ConvertTeamDataByJson(friendTeamJson)
	dump(formattedFriendTeamData)

	local friendFormationData = FormationStruct.New(
		nil,
		formattedFriendTeamData,
		friendPlayerSkill,
		self:GetObjPFixedAttrByQuestBattleType(questBattleType)
	)
	------------ 处理友方阵容信息 ------------

	------------ 处理敌方阵容信息 ------------
	local formattedEnemyTeamData = self:ConvertTeamDataByJson(enemyTeamJson)
	dump(formattedEnemyTeamData)
	
	local enemyFormationData = FormationStruct.New(
		nil,
		formattedEnemyTeamData,
		enemyPlayerSkill,
		self:GetObjPFixedAttrByQuestBattleType(questBattleType)
	)
	------------ 处理敌方阵容信息 ------------

	------------ 车轮战初始化只创建一波 之后的动态创建 ------------
	local stageCompleteInfo = {}
	local scinfo = StageCompleteSturct.New()
	scinfo.completeType = ConfigStageCompleteType.TAG_MATCH
	stageCompleteInfo[1] = scinfo
	------------ 车轮战初始化只创建一波 之后的动态创建 ------------

	local battleConstructorData = BattleConstructorStruct.New(
		------------ 战斗基本配置 ------------
		stageId, -- int 关卡id
		questBattleType, -- QuestBattleType 战斗类型
		randomConfig, -- BattleRandomConfigStruct 战斗随机数配置
		gameTimeScale, -- int 游戏运行速度缩放
		stageTime, -- int 战斗时间限制 second
		totalWave, -- int 总波数
		ConfigBattleResultType.NORMAL, -- 结算类型
		stageCompleteInfo, -- list(StageCompleteSturct) 过关条件
		false,
		false,
		------------ 战斗数值配置 ------------
		openLevelRolling, -- bool 是否开启等级碾压
		------------ 战斗环境配置 ------------
		weatherInfo, -- table 天气
		phaseChangeInfo, -- map 阶段转换信息
		abilityRelationInfo, -- list<ObjectAbilityRelationStruct>
		globalEffects, -- list 全局效果列表
		enableConnect, -- bool 己方 连携技可用
		autoConnect, -- bool 己方 自动释放连携技
		enemyEnableConnect, -- bool 敌方 连携技可用
		enemyAutoConnect, -- bool 敌方 自动释放连携技
		------------ 其他信息 ------------
		nil, -- table 三星条件
		canRechallenge, -- bool 是否可以重复挑战
		rechallengeTime, -- int 剩余挑战次数
		canBuyCheat, -- bool 是否可以买活
		buyRevivalTime, -- int 已买活次数
		buyRevivalTimeMax, -- int 最大买活次数 
		------------ 战斗场景配置 ------------
		{BattleBackgroundStruct.New(35)}, -- list 背景图信息
		nil, -- list<ConfigBattleFunctionModuleType> 隐藏的战斗功能模块界面
		------------ 友方阵容信息 ------------
		friendFormationData, -- FormationStruct 友方阵容信息
		------------ 敌方阵容信息 ------------
		enemyFormationData, -- FormationStruct 敌方阵容信息
		------------ 头尾服务器交互命令 ------------
		nil, -- BattleNetworkCommandStruct 与服务器交互的命令信息
		------------ 头尾跳转信息 ------------
		nil -- BattleMediatorsConnectStruct 跳转信息
	)

	self.battleConstructorData = battleConstructorData
end

---------------------------------------------------
-- data format begin --
---------------------------------------------------
--[[
根据json转换阵容数据
@params teamDataJson json
--]]
function BattleConstructor:ConvertTeamDataByJson(teamDataJson)
	local teamData = {}
	local teamsData = json.decode(teamDataJson)

	if nil ~= teamsData then

		for teamIndex, teamData_ in ipairs(teamsData) do
			teamData[teamIndex] = self:ConvertOneTeamData(teamData_)
		end

	end

	return teamData
end
--[[
获取一队卡牌的信息
@params data 通用的一队卡牌的信息
@return teamData list 队伍数据
--]]
function BattleConstructor:ConvertOneTeamData(data)
	local teamData = {}

	for teamPosition, cardData_ in ipairs(data) do

		local cardConstructorData = self:ConvertCardConstructorData(cardData_)
		if nil ~= cardConstructorData then
			------------ 修改一些编队决定的信息 ------------
			-- 是否是队长
			cardConstructorData.isLeader = 1 == teamPosition
			-- 卡牌位置序号
			cardConstructorData.teamPosition = #teamData + 1
			------------ 修改一些编队决定的信息 ------------
			table.insert(teamData, cardConstructorData)
		end

	end

	return teamData
end
--[[
根据单张卡牌的json.decode数据转换成object的构造数据
@params cardData json.decode = map
@return cardConstructorData CardObjConstructorStruct or MonsterObjConstructorStruct 战斗卡牌构造数据
--]]
function BattleConstructor:ConvertCardConstructorData(cardData)
	if nil == cardData then return nil end
	local cardId = checkint(cardData.cardId)
	if nil == cardId or 0 == cardId then return nil end

	local cardConstructorData = nil
	if CardUtils.IsMonsterCard(cardId) then
		cardConstructorData = self:ConvertMonsterDataByCommonMonsterData(cardData)
	else
		cardConstructorData = self:ConvertCardDataByCommonCardData(cardData)
	end

	return cardConstructorData
end
--[[
根据单卡信息的json.decode转换成怪物构造数据
@params monsterData json.decode = map
@return monsterConstructorData MonsterObjConstructorStruct 怪物构造数据
--]]
function BattleConstructor:ConvertMonsterDataByCommonMonsterData(monsterData)
	if nil == monsterData then return nil end
	local monsterId = checkint(monsterData.cardId)
	if not self:IsCardIdValid(monsterId) then return nil end

	local monsterConfig = CardUtils.GetCardConfig(monsterId)
	if nil == monsterConfig then return nil end

	-- 初始血量百分比
	local initialHpPercent = checknumber(monsterData.initialHp or 1)
	if 0 == initialHpPercent then
		initialHpPercent = 1
	end

	-- 初始血量值
	local fixedValue = nil
	if nil ~= monsterData.initialHpValue then
		fixedValue = checknumber(monsterData.initialHpValue)
	end

	-- 敌友性
	local campType = checkint(monsterData.campType or ConfigCampType.ENEMY)
	if ConfigCampType.BASE == campType then
		campType = ConfigCampType.ENEMY
	end

	-- 技能
	local skillData = {}
	for _,s in ipairs(monsterConfig) do
		skillData[tostring(s)] = {level = 1}
	end

	-- 构造传参用的数据结构
	local monsterConstructorData = MonsterObjConstructorStruct.New(
		------------ 怪物基本信息 ------------
		monsterId,
		campType,
		checkint(monsterData.level or 1),
		checknumber(monsterData.attrGrow),
		checknumber(monsterData.skillGrow),
		------------ 外部属性参数 ------------
		ObjPFixedAttrStruct.New(initialHpPercent, fixedValue),
		------------ 战斗信息 ------------
		false,
		monsterData.placeId,
		1,
		skillData,
		ArtifactTalentConstructorStruct.New(monsterId, nil),
		self:GetCardEXAbilityInfoByCardId(monsterId),
		nil,
		------------ 外貌信息 ------------
		CardUtils.GetCardSkinId(monsterId)
	)

	return monsterConstructorData
end
--[[
根据单卡信息的json.decode转换成卡牌构造数据
@params cardData json.decode = map
@return cardConstructorData CardObjConstructorStruct 战斗卡牌构造数据
--]]
function BattleConstructor:ConvertCardDataByCommonCardData(cardData)
	if nil == cardData then return nil end
	local cardId = checkint(cardData.cardId)
	if not self:IsCardIdValid(cardId) then return nil end

	------------ 堕神信息 ------------
	local petStruct = nil
	if nil ~= cardData.pets then
		for _, petData in pairs(cardData.pets) do
			if 0 ~= checkint(petData.petId) then
				petStruct = self:GetAFormattedPetDataByCommonPetData(cardId, petData)
				-- TODO --
				-- 此处暂时只处理一只堕神
				if nil ~= petStruct then
					break
				end
				-- TODO --
			end
		end
	end
	------------ 堕神信息 ------------

	local cardConstructorData = CardObjConstructorStruct.New(
		------------ 卡牌基本信息 ------------
		checkint(cardData.cardId),
		checkint(cardData.exp),
		checkint(cardData.level),
		checkint(cardData.breakLevel),
		checkint(cardData.favorability),
		checkint(cardData.favorabilityLevel or 1),
		checkint(cardData.vigour),
		------------ 外部属性参数 ------------
		ObjPFixedAttrStruct.New(),
		------------ 战斗信息 ------------
		false,
		0,
		cardData.skill,
		ArtifactTalentConstructorStruct.New(checkint(cardData.cardId), cardData.artifactTalent),
		self:GetCardEXAbilityInfoByCardId(cardId),
		petStruct,
		BookConstructorStruct.New(checkint(cardData.cardId), cardData.bookLevel),
		CatGeneConstructorStruct.New(cardData.equippedHouseCatGene),
		------------ 外貌信息 ------------
		checkint(cardData.defaultSkinId or CardUtils.GetCardSkinId(checkint(cardData.cardId)))
	)

	return cardConstructorData
end
--[[
根据通用堕神信息获取格式化后的堕神战斗数据
@params equipedCardId int 装备的卡牌id
@params petData table 堕神信息(new)
@return petStruct PetConstructorStruct 堕神战斗构造数据
--]]
function BattleConstructor:GetAFormattedPetDataByCommonPetData(equipedCardId, petData)
	local petStruct = nil
	if nil ~= petData and 0 ~= checkint(petData.petId) then
		local petId = checkint(petData.petId)
		local activeExclusive = false

		-- 判断是否激活本命加成
		local petConfig = PetUtils.GetPetConfig(petId)
		if nil ~= petConfig.exclusiveCard then
			for _, ecid in ipairs(petConfig.exclusiveCard) do
				if checkint(ecid) == checkint(equipedCardId) then
					activeExclusive = true
					break
				end
			end
		end

		petStruct = PetConstructorStruct.New(
			petId,
			checkint(petData.level or 1),
			checkint(petData.breakLevel or 0),
			checkint(petData.character or 1),
			activeExclusive,
			PetUtils.ConvertPetPropertyDataByServerData(petData, activeExclusive)
		)
	end
	return petStruct
end
--[[
根据json转换主角技数据
@params playerSkillJson json
@return _ map
--]]
function BattleConstructor:ConvertPlayerSkillByJson(playerSkillJson)
	if nil == playerSkillJson then return nil end
	local playerSkillData = json.decode(playerSkillJson)
	dump(playerSkillData)
	return self:GetFormattedPlayerSkill(playerSkillData.passiveSkill, playerSkillJson.activeSkill)
end
--[[
获取格式化后的主角技
@params allSkill list 所有的主角技
@params equipedSkill list 装备的主角技
--]]
function BattleConstructor:GetFormattedPlayerSkill(allSkill, equipedSkill)
	local playerSkillInfo = {
		activeSkill = {},
		passiveSkill = {}
	}

	if nil ~= equipedSkill and type(equipedSkill) == 'table' then
		for i,v in ipairs(equipedSkill) do
			if 0 ~= checkint(v) then
				table.insert(playerSkillInfo.activeSkill, {skillId = checkint(v)})
			end
		end
	end

	if nil ~= allSkill then
		local skillId = nil
		local skillConfig = nil

		for i,v in ipairs(allSkill) do
			skillId = checkint(v)
			if 0 ~= skillId then
				skillConfig = CommonUtils.GetSkillConf(skillId)
				if nil ~= skillConfig and ConfigSkillType.SKILL_HALO == checkint(skillConfig.property) then
					-- 被动技能
					table.insert(playerSkillInfo.passiveSkill, {skillId = skillId})
				end
			end
		end
	end

	return playerSkillInfo
end
--[[
获取转换结构后的过关条件
@params stageId int 关卡id
@params questBattleType QuestBattleType 战斗类型
@params totalWave int 总波数
@return stageCompleteInfo list 过关条件信息
--]]
function BattleConstructor:GetFormattedStageCompleteInfo(stageId, questBattleType, totalWave)
	if nil == stageId then

		-- 没有关卡id的战斗
		return self:GetFormattedStageCompleteInfoByQuestBattleType(questBattleType, totalWave)

	else

		-- 有关卡id的战斗
		return self:GetFormattedStageCompleteInfoByStageId(stageId, totalWave)

	end
end
--[[
根据战斗类型获取战斗的过关条件
@params questBattleType QuestBattleType 战斗类型
@return stageCompleteInfo list 过关条件信息
--]]
function BattleConstructor:GetFormattedStageCompleteInfoByQuestBattleType(questBattleType, totalWave)
	local stageCompleteInfo = {}

	if QuestBattleType.PVC == questBattleType then

		------------ 竞技场写死只有一波 条件只有团灭对面 ------------
		stageCompleteInfo[1] = StageCompleteSturct.New()
		------------ 竞技场写死只有一波 条件只有团灭对面 ------------

	elseif QuestBattleType.TAG_MATCH_3V3 == questBattleType then

		------------ 车轮战初始化只创建一波 之后的动态创建 ------------
		local scinfo = StageCompleteSturct.New()
		scinfo.completeType = ConfigStageCompleteType.TAG_MATCH
		stageCompleteInfo[1] = scinfo
		------------ 车轮战初始化只创建一波 之后的动态创建 ------------

	else

		for i = 1, totalWave do
			stageCompleteInfo[i] = StageCompleteSturct.New()
		end

	end

	return stageCompleteInfo
end
--[[
获取转换结构后的过关条件
@params stageId int 关卡id
@return stageCompleteInfo list 过关条件信息
--]]
function BattleConstructor:GetFormattedStageCompleteInfoByStageId(stageId, totalWave)
	local stageConfig = CommonUtils.GetQuestConf(stageId)

	local stageCompleteInfo = {}

	if nil == stageConfig then
		stageCompleteInfo[1] = StageCompleteSturct.New()
	else
		local enemyConfig  = CommonUtils.GetConfig('quest', 'enemy', stageId) or {}
		local totalWaveNum = totalWave ~= nil and checkint(totalWave) or table.nums(enemyConfig)
		for i = 1, totalWaveNum do
			if nil ~= stageConfig.stageCompleteType and nil ~= stageConfig.stageCompleteType[i] then
				local stageCompleteInfo_ = StageCompleteSturct.New(stageConfig.stageCompleteType[i])
				stageCompleteInfo[i] = stageCompleteInfo_
			else
				local stageCompleteInfo_ = StageCompleteSturct.New()
				stageCompleteInfo[i] = stageCompleteInfo_
			end
		end
	end

	return stageCompleteInfo
end
--[[
根据卡牌id获取卡牌的超能力构造信息
@params cardId int 卡牌id
@return _ EXAbilityConstructorStruct
--]]
function BattleConstructor:GetCardEXAbilityInfoByCardId(cardId)
	return EXAbilityConstructorStruct.New(cardId, CardUtils.GetCardEXAbilitySkillsByCardId(cardId))
end
---------------------------------------------------
-- data format end --
---------------------------------------------------

---------------------------------------------------
-- data -> struct begin --
---------------------------------------------------
--[[
根据数据转换结构
@params data table 数据
@params StructClass BaseStruct 转换的目标结构
@return _ StructClass 转换后的数据
--]]
function BattleConstructor:Data2StructCommon(data, StructClass)
	if nil == data then return nil end
	if nil == StructClass.SerializeByTable then return nil end
	return StructClass.SerializeByTable(data)
end
--[[
根据构造器数据获取卡牌属性增强信息
@params table 构造器数据
@return result list<ObjectAbilityRelationStruct>
--]]
function BattleConstructor:Data2StructObjectAbilityRelationStructList(table)
	if nil == table then return nil end

	local result = {}
	for _, data in ipairs(table) do
		local struct = self:Data2StructCommon(data, ObjectAbilityRelationStruct)
		table.insert(result, struct)
	end
	return result
end
---------------------------------------------------
-- data -> struct end --
---------------------------------------------------

---------------------------------------------------
-- battle parameter begin --
---------------------------------------------------
--[[
根据战斗类型获取是否开启等级碾压
@params questBattleType QuestBattleType 战斗类型
@return _ bool 是否开启等级碾压
--]]
function DebugBattleConstructor:OpenLevelRollingByQuestBattleType(questBattleType)
	local config = {
		[QuestBattleType.PVC] 					= false,
		[QuestBattleType.TAG_MATCH_3V3] 		= false
	}
	if nil ~= config[questBattleType] then
		return config[questBattleType]
	else
		return true
	end
end
--[[
根据战斗类型获取战斗物体全局属性修正
@params questBattleType QuestBattleType 战斗类型
@return _ ObjectPropertyFixedAttrStruct 属性修正数据
--]]
function DebugBattleConstructor:GetObjPFixedAttrByQuestBattleType(questBattleType)
	local config = {
		[QuestBattleType.PVC] 					= {10},
		[QuestBattleType.TAG_MATCH_3V3] 		= {5}
	}
	if nil ~= config[questBattleType] then
		return ObjectPropertyFixedAttrStruct.New(unpack(config[questBattleType]))
	else
		return ObjectPropertyFixedAttrStruct.New()
	end
end
---------------------------------------------------
-- battle parameter end --
---------------------------------------------------

--[[
判断卡牌id是否合法
@params cardId int 卡牌id
@return invalid bool 是否合法
--]]
function DebugBattleConstructor:IsCardIdValid(cardId)
	local valid = true
	if nil == cardId or 0 == cardId then
		valid = false
	end
	return valid
end




















return DebugBattleConstructor
--[[
战斗构造器 构造一场战斗需要的数据
--]]
local BattleConstructor = class('BattleConstructor')

------------ import ------------
require('battleEntry.BattleGlobalDefines')
-- 战斗字符串工具
__Require('battle.util.BStringUtils')
local gameMgr = AppFacade.GetInstance():GetManager('GameManager')
local cardMgr = AppFacade.GetInstance():GetManager('CardManager')
local petMgr = AppFacade.GetInstance():GetManager('PetManager')
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")

local TowerConfigParser = require('Game.Datas.Parser.TowerConfigParser')
local UnionConfigParser = require('Game.Datas.Parser.UnionConfigParser')
------------ import ------------

--[[
constructor
--]]
function BattleConstructor:ctor( ... )
	local args = unpack({...})

	self.battleConstructorData = nil
	self.playersData = nil
	self.unionBeastId = nil
end
---------------------------------------------------
-- init logic begin --
---------------------------------------------------
--[[
根据通用关卡id 编队序号初始化构造器数据
@params stageId int 通用关卡id
@params teamId int 编队序号
@params serverCommand BattleNetworkCommandStruct 与服务器交互的命令信息
@params fromtoData BattleMediatorsConnectStruct 跳转信息
--]]
function BattleConstructor:InitByNormalStageIdAndTeamId(stageId, teamId, serverCommand, fromtoData)
	-- 设置战斗文件夹
	SetBattleFolder(BattleFolder.BATTLE_NEW)

	------------ 处理友方阵容信息 ------------
	local formattedFriendTeamData = self:GetFormattedFriendTeamDataByTeamId(teamId)
	local formattedFriendPlayerSkillData = self:GetFormattedPlayerSkill(gameMgr:GetUserInfo().allSkill, gameMgr:GetUserInfo().skill)

	local friendFormationData = FormationStruct.New(
		teamId,
		formattedFriendTeamData,
		formattedFriendPlayerSkillData,
		ObjectPropertyFixedAttrStruct.New()
	)

	-- 处理一次友方进入战斗传参数据
	serverCommand.enterBattleRequestData.teamId = teamId
	------------ 处理友方阵容信息 ------------

	------------ 处理敌方阵容信息 ------------
	local formattedEnemyTeamData = self:GetCommonEnemyTeamDataByStageId(stageId)
	local formattedEnemyPlayerSkillData = nil

	local enemyFormationData = FormationStruct.New(
		stageId,
		formattedEnemyTeamData,
		formattedEnemyPlayerSkillData,
		ObjectPropertyFixedAttrStruct.New()
	)
	------------ 处理敌方阵容信息 ------------

	------------ 处理每一波的过关条件 ------------
	local stageCompleteInfo = self:GetBattleCompleteConfig(nil, stageId)
	------------ 处理每一波的过关条件 ------------

	------------ 背景图 ------------
	local bgInfo = self:GetBattleBackgroundConfig(nil, stageId)
	------------ 背景图 ------------

	------------ 整合数据结构 ------------
	local stageConfig = CommonUtils.GetQuestConf(stageId)

	local randomConfig = BattleRandomConfigStruct.New()

	local battleConstructorData = BattleConstructorStruct.New(
		------------ 战斗基本配置 ------------
		stageId,
		CommonUtils.GetQuestBattleByQuestId(stageId),
		randomConfig,
		gameMgr:GetUserInfo().localBattleAccelerate,
		checkint(stageConfig.time),
		#formattedEnemyTeamData,
		checkint(stageConfig.settlementType),
		stageCompleteInfo,
		false,
		false,
		------------ 战斗数值配置 ------------
		true,
		------------ 战斗环境配置 ------------
		stageConfig.weatherId,
		stageConfig.actionId,
		nil,
		nil,
		true,
		false,
		false,
		false,
		------------ 其他信息 ------------
		stageConfig.allClean,
		ValueConstants.V_NORMAL == checkint(stageConfig.repeatChallenge),
		gameMgr:GetChallengeTimeByStageId(stageId),
		false,
		0,
		0,
		------------ 战斗场景配置 ------------
		bgInfo,
		stageConfig.hiddenModule,
		------------ 友方阵容信息 ------------
		friendFormationData,
		------------ 敌方阵容信息 ------------
		enemyFormationData,
		------------ 头尾服务器交互命令 ------------
		serverCommand,
		------------ 头尾跳转信息 ------------
		fromtoData
	)

	self.battleConstructorData = battleConstructorData
	dump(self.battleConstructorData, 'InitByNormalStageIdAndTeamId', 10)
	------------ 整合数据结构 ------------
end
--[[
初始化打劫构造器信息
--]]
function BattleConstructor:InitDataByTakeawayRobbery(teamId, serverCommand, fromtoData)
	-- 设置战斗文件夹
	SetBattleFolder(BattleFolder.BATTLE_NEW)

	------------ 处理友方阵容信息 ------------
	local formattedFriendTeamData = self:GetFormattedFriendTeamDataByTeamId(teamId)
	local formattedFriendPlayerSkillData = self:GetFormattedPlayerSkill(gameMgr:GetUserInfo().allSkill, gameMgr:GetUserInfo().skill)

	local friendFormationData = FormationStruct.New(
		teamId,
		formattedFriendTeamData,
		formattedFriendPlayerSkillData,
		ObjectPropertyFixedAttrStruct.New()
	)

	-- 处理一次友方进入战斗传参数据
	serverCommand.enterBattleRequestData.teamId = teamId
	------------ 处理友方阵容信息 ------------

	------------ 处理敌方阵容信息 ------------
	-- 打劫不在初始化时处理敌方数据
	------------ 处理敌方阵容信息 ------------

	------------ 打劫写死只有一波 过关条件只有团灭对面 ------------
	local stageCompleteInfo = self:GetBattleCompleteConfig(QuestBattleType.ROBBERY, nil, 1)
	------------ 打劫写死只有一波 过关条件只有团灭对面 ------------

	local randomConfig = BattleRandomConfigStruct.New()

	------------ 整合数据结构 ------------
	local battleConstructorData = BattleConstructorStruct.New(
		------------ 战斗基本配置 ------------
		nil,
		QuestBattleType.ROBBERY,
		randomConfig,
		gameMgr:GetUserInfo().localBattleAccelerate,
		180,
		1,
		ConfigBattleResultType.NORMAL,
		stageCompleteInfo,
		false,
		false,
		------------ 战斗数值配置 ------------
		true,
		------------ 战斗环境配置 ------------
		nil,
		nil,
		nil,
		nil,
		true,
		false,
		false,
		false,
		------------ 其他信息 ------------
		nil,
		false,
		0,
		false,
		0,
		0,
		------------ 战斗场景配置 ------------
		self:GetBattleBackgroundConfig(QuestBattleType.ROBBERY),
		nil,
		------------ 友方阵容信息 ------------
		friendFormationData,
		------------ 敌方阵容信息 ------------
		nil,
		------------ 头尾服务器交互命令 ------------
		serverCommand,
		------------ 头尾跳转信息 ------------
		fromtoData
	)

	self.battleConstructorData = battleConstructorData
	dump(self.battleConstructorData, 'InitDataByTakeawayRobbery', 10)
	------------ 整合数据结构 ------------
end
--[[
初始化爬塔构造器数据
@params unitId int 爬塔单元id
@params currentFloor int 当前层数
@params buyRevivalTime int 已买活次数
@params buyRevivalTimeMax int 最大买活次数
@params isOpenRevival bool 是否开启买活
@params friendCardIds list 友方阵容
@params skillIds list 携带的主角技
@params serverCommand BattleNetworkCommandStruct 与服务器交互的命令信息
@params fromtoData BattleMediatorsConnectStruct 跳转信息
@params contracts list 契约列表
--]]
function BattleConstructor:InitDataByTower(unitId, currentFloor, buyRevivalTime, buyRevivalTimeMax, isOpenRevival, friendCardIds, skillIds, serverCommand, fromtoData, contracts)
	-- 设置战斗文件夹
	SetBattleFolder(BattleFolder.BATTLE_NEW)

	------------ 处理友方阵容信息 ------------
	local formattedFriendTeamData = self:GetFormattedTeamsDataByTeamsMyCardData({[1] = friendCardIds})
	local formattedFriendPlayerSkillData = self:GetFormattedPlayerSkill(skillIds, skillIds)

	local friendFormationData = FormationStruct.New(
		nil,
		formattedFriendTeamData,
		formattedFriendPlayerSkillData,
		ObjectPropertyFixedAttrStruct.New()
	)
	------------ 处理友方阵容信息 ------------

	------------ 处理敌方阵容信息 ------------
	local formattedEnemyTeamData = self:GetFormattedEnemyTeamDataByUnitAndFloor(unitId, currentFloor)
	local formattedEnemyPlayerSkillData = nil

	local enemyFormationData = FormationStruct.New(
		nil,
		formattedEnemyTeamData,
		formattedEnemyPlayerSkillData,
		ObjectPropertyFixedAttrStruct.New()
	)
	------------ 处理敌方阵容信息 ------------

	------------ 爬塔写死过关条件只有团灭对面 ------------
	local stageCompleteInfo = self:GetBattleCompleteConfig(QuestBattleType.TOWER, nil, #formattedEnemyTeamData)
	------------ 爬塔写死过关条件只有团灭对面 ------------

	------------ 整合数据结构 ------------
	local fixedFloor = (currentFloor - 1) % 5 + 1
	local unitConfig = CommonUtils.GetConfigAllMess(TowerConfigParser.TYPE.UNIT ,'tower')[tostring(unitId)]
	if nil == unitConfig then
		-- 未找到单元配置
		uiMgr:ShowInformationTips(__('未找到单元配置 unit id -> ') .. unitId)
		return
	end

	------------ 背景图 ------------
	local bgInfo = self:GetBattleBackgroundConfig(QuestBattleType.TOWER, nil, unitConfig)
	------------ 背景图 ------------

	local randomConfig = BattleRandomConfigStruct.New()

	local battleConstructorData = BattleConstructorStruct.New(
		------------ 战斗基本配置 ------------
		nil,
		QuestBattleType.TOWER,
		randomConfig,
		gameMgr:GetUserInfo().localBattleAccelerate,
		checkint(unitConfig.time[fixedFloor]),
		#formattedEnemyTeamData,
		ConfigBattleResultType.NORMAL,
		stageCompleteInfo,
		false,
		false,
		------------ 战斗数值配置 ------------
		true,
		------------ 战斗环境配置 ------------
		checktable(unitConfig.weatherId[fixedFloor]),
		checktable(unitConfig.actionId[fixedFloor]),
		nil,
		contracts,
		true,
		false,
		false,
		false,
		------------ 其他信息 ------------
		nil,
		false,
		0,
		isOpenRevival,
		buyRevivalTime,
		buyRevivalTimeMax,
		------------ 战斗场景配置 ------------
		bgInfo,
		nil,
		------------ 友方阵容信息 ------------
		friendFormationData,
		------------ 敌方阵容信息 ------------
		enemyFormationData,
		------------ 头尾服务器交互命令 ------------
		serverCommand,
		------------ 头尾跳转信息 ------------
		fromtoData
	)

	self.battleConstructorData = battleConstructorData
	dump(self.battleConstructorData, 'InitDataByTower', 10)
	------------ 整合数据结构 ------------
end
--[[
根据通用的活动类型初始化战斗构造器
*** 玩家自主选卡 选择主角技 拥有一个关卡id ***
@params stageId int 关卡id
@params serverCommand BattleNetworkCommandStruct 与服务器交互的命令信息
@params fromtoData BattleMediatorsConnectStruct 跳转信息
@params teamData list 队伍信息
@params activePlayerSkills ? 主动主角技
@params abilityData ? 卡牌能力增强信息
--]]
function BattleConstructor:InitStageDataByNormalEvent(stageId, serverCommand, fromtoData, teamData, activePlayerSkills, abilityData)
	-- 设置战斗文件夹
	SetBattleFolder(BattleFolder.BATTLE_NEW)

	------------ 处理友方阵容信息 ------------
	local formattedFriendTeamData = self:GetFormattedTeamsDataByTeamsMyCardData({[1] = teamData})
	local formattedFriendPlayerSkillData = self:GetFormattedPlayerSkill(gameMgr:GetUserInfo().allSkill, activePlayerSkills)

	local friendFormationData = FormationStruct.New(
		nil,
		formattedFriendTeamData,
		formattedFriendPlayerSkillData,
		ObjectPropertyFixedAttrStruct.New()
	)
	------------ 处理友方阵容信息 ------------

	------------ 处理敌方阵容信息 ------------
	local formattedEnemyTeamData = self:GetCommonEnemyTeamDataByStageId(stageId)
	local formattedEnemyPlayerSkillData = nil

	local enemyFormationData = FormationStruct.New(
		stageId,
		formattedEnemyTeamData,
		formattedEnemyPlayerSkillData,
		ObjectPropertyFixedAttrStruct.New()
	)
	------------ 处理敌方阵容信息 ------------

	------------ 处理过关条件 ------------
	local stageCompleteInfo = self:GetBattleCompleteConfig(nil, stageId)
	------------ 处理过关条件 ------------

	------------ 背景图 ------------
	local bgInfo = self:GetBattleBackgroundConfig(nil, stageId)
	------------ 背景图 ------------

	------------ 整合数据结构 ------------
	local stageConfig = CommonUtils.GetQuestConf(stageId)

	local randomConfig = BattleRandomConfigStruct.New()

	local battleConstructorData = BattleConstructorStruct.New(
		------------ 战斗基本配置 ------------
		stageId,
		CommonUtils.GetQuestBattleByQuestId(stageId),
		randomConfig,
		gameMgr:GetUserInfo().localBattleAccelerate,
		checkint(stageConfig.time),
		#formattedEnemyTeamData,
		checkint(stageConfig.settlementType),
		stageCompleteInfo,
		false,
		false,
		------------ 战斗数值配置 ------------
		true,
		------------ 战斗环境配置 ------------
		stageConfig.weatherId,
		stageConfig.actionId,
		self:GetFormattedAbilityRelationInfo(abilityData),
		nil,
		true,
		false,
		false,
		false,
		------------ 其他信息 ------------
		stageConfig.allClean,
		ValueConstants.V_NORMAL == checkint(stageConfig.repeatChallenge),
		0,
		false,
		0,
		0,
		------------ 战斗场景配置 ------------
		bgInfo,
		stageConfig.hiddenModule,
		------------ 友方阵容信息 ------------
		friendFormationData,
		------------ 敌方阵容信息 ------------
		enemyFormationData,
		------------ 头尾服务器交互命令 ------------
		serverCommand,
		------------ 头尾跳转信息 ------------
		fromtoData
	)

	self.battleConstructorData = battleConstructorData
	dump(self.battleConstructorData, 'InitStageDataByNormalEvent', 10)
	------------ 整合数据结构 ------------

end
--[[
根据通用的活动类型初始化战斗构造器
@params stageId int 关卡id
@params serverCommand BattleNetworkCommandStruct 与服务器交互的命令信息
@params fromtoData BattleMediatorsConnectStruct 跳转信息
@params teamId int 编队序号
@params abilityData ? 卡牌能力增强信息
@params buyRevivalTime int 已买活次数
@params buyRevivalTimeMax int 最大买活次数
@params isOpenRevival bool 是否开启买活
--]]
function BattleConstructor:InitStageDataByNormalEventAndTeamId(stageId, serverCommand, fromtoData, teamId, abilityData, buyRevivalTime, buyRevivalTimeMax, isOpenRevival)
	-- 设置战斗文件夹
	SetBattleFolder(BattleFolder.BATTLE_NEW)

	------------ 处理友方阵容信息 ------------
	local formattedFriendTeamData = self:GetFormattedFriendTeamDataByTeamId(teamId)
	local formattedFriendPlayerSkillData = self:GetFormattedPlayerSkill(gameMgr:GetUserInfo().allSkill, gameMgr:GetUserInfo().skill)

	local friendFormationData = FormationStruct.New(
		teamId,
		formattedFriendTeamData,
		formattedFriendPlayerSkillData,
		ObjectPropertyFixedAttrStruct.New()
	)

	-- 处理一次友方进入战斗传参数据
	serverCommand.enterBattleRequestData.teamId = teamId
	------------ 处理友方阵容信息 ------------

	------------ 处理敌方阵容信息 ------------
	local formattedEnemyTeamData = self:GetCommonEnemyTeamDataByStageId(stageId)
	local formattedEnemyPlayerSkillData = nil

	local enemyFormationData = FormationStruct.New(
		stageId,
		formattedEnemyTeamData,
		formattedEnemyPlayerSkillData,
		ObjectPropertyFixedAttrStruct.New()
	)
	------------ 处理敌方阵容信息 ------------

	------------ 处理过关条件 ------------
	local stageCompleteInfo = self:GetBattleCompleteConfig(nil, stageId)
	------------ 处理过关条件 ------------

	------------ 背景图 ------------
	local bgInfo = self:GetBattleBackgroundConfig(nil, stageId)
	------------ 背景图 ------------

	------------ 整合数据结构 ------------
	local stageConfig = CommonUtils.GetQuestConf(stageId)

	local randomConfig = BattleRandomConfigStruct.New()

	local battleConstructorData = BattleConstructorStruct.New(
		------------ 战斗基本配置 ------------
		stageId,
		CommonUtils.GetQuestBattleByQuestId(stageId),
		randomConfig,
		gameMgr:GetUserInfo().localBattleAccelerate,
		checkint(stageConfig.time),
		#formattedEnemyTeamData,
		checkint(stageConfig.settlementType),
		stageCompleteInfo,
		false,
		false,
		------------ 战斗数值配置 ------------
		true,
		------------ 战斗环境配置 ------------
		stageConfig.weatherId,
		stageConfig.actionId,
		self:GetFormattedAbilityRelationInfo(abilityData),
		nil,
		true,
		false,
		false,
		false,
		------------ 其他信息 ------------
		nil,
		false,
		0,
		isOpenRevival,
		buyRevivalTime,
		buyRevivalTimeMax,
		------------ 战斗场景配置 ------------
		bgInfo,
		stageConfig.hiddenModule,
		------------ 友方阵容信息 ------------
		friendFormationData,
		------------ 敌方阵容信息 ------------
		enemyFormationData,
		------------ 头尾服务器交互命令 ------------
		serverCommand,
		------------ 头尾跳转信息 ------------
		fromtoData
	)

	self.battleConstructorData = battleConstructorData
	dump(self.battleConstructorData, 'InitStageDataByNormalEventAndTeamId', 10)
	------------ 整合数据结构 ------------

end
--[[
根据数据初始化pvc战斗构造器数据
@params friendCardIds list 友方阵容
@params rivalTeamData list 敌方阵容 卡牌信息
@params randomseed stirng 随机种子
@params serverCommand BattleNetworkCommandStruct 与服务器交互的命令信息
@params fromtoData BattleMediatorsConnectStruct 跳转信息
--]]
function BattleConstructor:InitDataByPVC(friendCardIds, rivalTeamData, randomseed, serverCommand, fromtoData)
	-- 设置战斗文件夹
	SetBattleFolder(BattleFolder.BATTLE_NEW)

	local questBattleType = QuestBattleType.PVC

	------------ 处理友方阵容信息 ------------
	local formattedFriendTeamData = self:GetFormattedTeamsDataByTeamsMyCardData({[1] = friendCardIds})
	local formattedFriendPlayerSkillData = self:GetFormattedPlayerSkill(gameMgr:GetUserInfo().allSkill, gameMgr:GetUserInfo().skill)

	local friendFormationData = FormationStruct.New(
		nil,
		formattedFriendTeamData,
		formattedFriendPlayerSkillData,
		self:GetObjPFixedAttrByQuestBattleType(questBattleType, false)
	)
	------------ 处理友方阵容信息 ------------

	------------ 处理敌方阵容信息 ------------
	local formattedEnemyTeamData = self:GetFormattedTeamsDataByTeamsCardData({[1] = rivalTeamData})
	local enemyFormationData = FormationStruct.New(
		nil,
		formattedEnemyTeamData,
		nil,
		self:GetObjPFixedAttrByQuestBattleType(questBattleType, true)
	)
	------------ 处理敌方阵容信息 ------------

	------------ 竞技场写死只有一波 条件只有团灭对面 ------------
	local stageCompleteInfo = self:GetBattleCompleteConfig(questBattleType, nil, #formattedEnemyTeamData)
	------------ 竞技场写死只有一波 条件只有团灭对面 ------------

	local randomConfig = BattleRandomConfigStruct.New()

	local battleConstructorData = BattleConstructorStruct.New(
		------------ 战斗基本配置 ------------
		nil,
		questBattleType,
		randomConfig,
		gameMgr:GetUserInfo().localBattleAccelerate,
		self:GetBattleTotalTime(questBattleType),
		#formattedEnemyTeamData,
		ConfigBattleResultType.NO_DROP,
		stageCompleteInfo,
		false,
		false,
		------------ 战斗数值配置 ------------
		false,
		------------ 战斗环境配置 ------------
		{},
		{},
		nil,
		nil,
		true,
		true,
		false,
		false,
		------------ 其他信息 ------------
		nil,
		false,
		0,
		false,
		0,
		0,
		------------ 战斗场景配置 ------------
		self:GetBattleBackgroundConfig(questBattleType),
		nil,
		------------ 友方阵容信息 ------------
		friendFormationData,
		------------ 敌方阵容信息 ------------
		enemyFormationData,
		------------ 头尾服务器交互命令 ------------
		serverCommand,
		------------ 头尾跳转信息 ------------
		fromtoData
	)

	self.battleConstructorData = battleConstructorData
	dump(self.battleConstructorData, 'InitDataByPVC', 10)

end
--[[
根据数据初始化一场演示战斗
@params stageId int 关卡id
@params serverCommand BattleNetworkCommandStruct 与服务器交互的命令信息
@params fromtoData BattleMediatorsConnectStruct 跳转信息
--]]
function BattleConstructor:InitDataByPerformanceStageId(stageId, serverCommand, fromtoData)
	-- 设置战斗文件夹
	SetBattleFolder(BattleFolder.BATTLE_NEW)

	local performanceStageConfig = CommonUtils.GetConfigAllMess('customizedQuest', 'guide')[tostring(stageId)]
	local performanceNPCConfig = CommonUtils.GetConfig('arena', 'robotNpc', checkint(performanceStageConfig.RobotNpc))
	local performanceNPCPropertyId = checkint(performanceStageConfig.RobotProperty)

	------------ 处理友方阵容信息 ------------
	local formattedFriendTeamData = self:GetFormattedTeamDataByCustomizeConfig(
		performanceNPCConfig.robotNpc,
		performanceNPCConfig.skinId,
		performanceNPCPropertyId
	)
	local formattedFriendPlayerSkillData = self:GetFormattedPlayerSkill({}, {})

	local friendFormationData = FormationStruct.New(
		nil,
		formattedFriendTeamData,
		formattedFriendPlayerSkillData,
		ObjectPropertyFixedAttrStruct.New()
	)
	------------ 处理友方阵容信息 ------------

	------------ 处理敌方阵容信息 ------------
	local formattedEnemyTeamData = self:GetCommonEnemyTeamDataByStageId(stageId)
	local formattedEnemyPlayerSkillData = nil

	local enemyFormationData = FormationStruct.New(
		stageId,
		formattedEnemyTeamData,
		formattedEnemyPlayerSkillData,
		ObjectPropertyFixedAttrStruct.New()
	)
	------------ 处理敌方阵容信息 ------------

	------------ 处理每一波的过关条件 ------------
	local stageCompleteInfo = self:GetBattleCompleteConfig(nil, stageId)
	------------ 处理每一波的过关条件 ------------

	------------ 背景图 ------------
	local bgInfo = self:GetBattleBackgroundConfig(nil, stageId)
	------------ 背景图 ------------

	------------ 整合数据结构 ------------
	local stageConfig = CommonUtils.GetQuestConf(stageId)

	local randomConfig = BattleRandomConfigStruct.New()

	local battleConstructorData = BattleConstructorStruct.New(
		------------ 战斗基本配置 ------------
		stageId,
		QuestBattleType.PERFORMANCE,
		randomConfig,
		gameMgr:GetUserInfo().localBattleAccelerate,
		checkint(stageConfig.time),
		#formattedEnemyTeamData,
		checkint(stageConfig.settlementType),
		stageCompleteInfo,
		false,
		false,
		------------ 战斗数值配置 ------------
		true,
		------------ 战斗环境配置 ------------
		stageConfig.weatherId,
		stageConfig.actionId,
		nil,
		nil,
		true,
		false,
		false,
		false,
		------------ 其他信息 ------------
		stageConfig.allClean,
		false,
		0,
		false,
		0,
		0,
		------------ 战斗场景配置 ------------
		bgInfo,
		nil,
		------------ 友方阵容信息 ------------
		friendFormationData,
		------------ 敌方阵容信息 ------------
		enemyFormationData,
		------------ 头尾服务器交互命令 ------------
		serverCommand,
		------------ 头尾跳转信息 ------------
		fromtoData
	)
	------------ 整合数据结构 ------------

	self.battleConstructorData = battleConstructorData
	dump(self.battleConstructorData, 'InitDataByPerformanceStageId', 10)
end
--[[
根据3+2组队boss信息初始化战斗构造器
@params stageId int 关卡id
@params randomConfig BattleRandomConfigStruct 战斗随机数配置
@params teamData list 队伍信息
@params serverCommand BattleNetworkCommandStruct 与服务器交互的命令信息
@params fromtoData BattleMediatorsConnectStruct 跳转信息
--]]
function BattleConstructor:InitDataByThreeTwoRaid(stageId, randomConfig, teamData, serverCommand, fromtoData)
	-- 设置战斗文件夹
	SetBattleFolder(BattleFolder.BATTLE_NEW)
	
	------------ 处理友方阵容信息 ------------
	local formattedFriendTeamData = self:GetFormattedTeamsDataByTeamsCardData({[1] = teamData})
	local formattedFriendPlayerSkillData = self:GetFormattedPlayerSkill({}, {})

	local friendFormationData = FormationStruct.New(
		nil,
		formattedFriendTeamData,
		formattedFriendPlayerSkillData,
		ObjectPropertyFixedAttrStruct.New()
	)
	------------ 处理友方阵容信息 ------------

	------------ 处理敌方阵容信息 ------------
	local formattedEnemyTeamData = self:GetCommonEnemyTeamDataByStageId(stageId)
	local formattedEnemyPlayerSkillData = nil

	local enemyFormationData = FormationStruct.New(
		nil,
		formattedEnemyTeamData,
		formattedEnemyPlayerSkillData,
		ObjectPropertyFixedAttrStruct.New()
	)
	------------ 处理敌方阵容信息 ------------

	------------ 处理每一波的过关条件 ------------
	local stageCompleteInfo = self:GetBattleCompleteConfig(nil, stageId)
	------------ 处理每一波的过关条件 ------------

	------------ 背景图 ------------
	local bgInfo = self:GetBattleBackgroundConfig(nil, stageId)
	------------ 背景图 ------------

	------------ 整合数据结构 ------------
	local stageConfig = CommonUtils.GetQuestConf(stageId)

	local battleConstructorData = BattleConstructorStruct.New(
		------------ 战斗基本配置 ------------
		stageId,
		CommonUtils.GetQuestBattleByQuestId(stageId),
		randomConfig,
		2,
		checkint(stageConfig.time),
		#formattedEnemyTeamData,
		checkint(stageConfig.settlementType),
		stageCompleteInfo,
		false,
		false,
		------------ 战斗数值配置 ------------
		true,
		------------ 战斗环境配置 ------------
		stageConfig.weatherId,
		stageConfig.actionId,
		nil,
		nil,
		true,
		true,
		false,
		false,
		------------ 其他信息 ------------
		nil,
		false,
		0,
		false,
		0,
		0,
		------------ 战斗场景配置 ------------
		bgInfo,
		nil,
		------------ 友方阵容信息 ------------
		friendFormationData,
		------------ 敌方阵容信息 ------------
		enemyFormationData,
		------------ 头尾服务器交互命令 ------------
		serverCommand,
		------------ 头尾跳转信息 ------------
		fromtoData
	)

	self.battleConstructorData = battleConstructorData
	dump(self.battleConstructorData, 'InitDataByThreeTwoRaid', 10)
	------------ 整合数据结构 ------------
end
--[[
初始化共斗关卡战斗构造器
@params stageId int 关卡id
@params teamId int 队伍id
@params monsterAttrData table 怪物属性信息
@params leftBuyRevivalTime int 剩余的买活次数
@params buyRevivalTimeMax int 最大的买活次数
@params isOpenRevival bool 是否打开买活
@params skillIds int 主角技id
@params abilityData ? 卡牌能力增强信息
@params serverCommand BattleNetworkCommandStruct 与服务器交互的命令信息
@params fromtoData BattleMediatorsConnectStruct 跳转信息
--]]
function BattleConstructor:InitDataByShareBoss(stageId, teamId, monsterAttrData, leftBuyRevivalTime, buyRevivalTimeMax, isOpenRevival, skillIds, abilityData, serverCommand, fromtoData)
	-- 设置战斗文件夹
	SetBattleFolder(BattleFolder.BATTLE_NEW)

	------------ 处理友方阵容信息 ------------
	local formattedFriendTeamData = self:GetFormattedFriendTeamDataByTeamId(teamId)
	local formattedFriendPlayerSkillData = self:GetFormattedPlayerSkill(gameMgr:GetUserInfo().allSkill, skillIds)

	local friendFormationData = FormationStruct.New(
		teamId,
		formattedFriendTeamData,
		formattedFriendPlayerSkillData,
		ObjectPropertyFixedAttrStruct.New()
	)
	------------ 处理友方阵容信息 ------------

	------------ 处理敌方阵容信息 ------------
	local formattedEnemyTeamData = self:GetCommonEnemyTeamDataByStageId(stageId, nil, monsterAttrData)
	local formattedEnemyPlayerSkillData = nil

	local enemyFormationData = FormationStruct.New(
		stageId,
		formattedEnemyTeamData,
		formattedEnemyPlayerSkillData,
		ObjectPropertyFixedAttrStruct.New()
	)
	------------ 处理敌方阵容信息 ------------

	------------ 处理每一波的过关条件 ------------
	local stageCompleteInfo = self:GetBattleCompleteConfig(nil, stageId)
	------------ 处理每一波的过关条件 ------------

	------------ 背景图 ------------
	local bgInfo = self:GetBattleBackgroundConfig(nil, stageId)
	------------ 背景图 ------------

	------------ 整合数据结构 ------------
	local stageConfig = CommonUtils.GetQuestConf(stageId)

	local randomConfig = BattleRandomConfigStruct.New()

	local battleConstructorData = BattleConstructorStruct.New(
		------------ 战斗基本配置 ------------
		stageId,
		CommonUtils.GetQuestBattleByQuestId(stageId),
		randomConfig,
		gameMgr:GetUserInfo().localBattleAccelerate,
		checkint(stageConfig.time),
		#formattedEnemyTeamData,
		checkint(stageConfig.settlementType),
		stageCompleteInfo,
		false,
		false,
		------------ 战斗数值配置 ------------
		true,
		------------ 战斗环境配置 ------------
		stageConfig.weatherId,
		stageConfig.actionId,
		self:GetFormattedAbilityRelationInfo(abilityData),
		nil,
		true,
		false,
		false,
		false,
		------------ 其他信息 ------------
		stageConfig.allClean,
		false,
		1,
		isOpenRevival,
		math.max(0, buyRevivalTimeMax - leftBuyRevivalTime),
		buyRevivalTimeMax,
		------------ 战斗场景配置 ------------
		bgInfo,
		self:GetBattleHideModuleInfo(CommonUtils.GetQuestBattleByQuestId(stageId), stageId),
		------------ 友方阵容信息 ------------
		friendFormationData,
		------------ 敌方阵容信息 ------------
		enemyFormationData,
		------------ 头尾服务器交互命令 ------------
		serverCommand,
		------------ 头尾跳转信息 ------------
		fromtoData
	)

	self.battleConstructorData = battleConstructorData
	dump(self.battleConstructorData, 'InitDataByShareBoss', 10)
	------------ 整合数据结构 ------------
end
--[[
初始化自由编队共斗关卡构造器数据
@params stageId int 关卡id
@params friendCardIds int 卡牌信息id
@params monsterAttrData table 怪物属性信息
@params leftBuyRevivalTime int 剩余的买活次数
@params buyRevivalTimeMax int 最大的买活次数
@params isOpenRevival bool 是否打开买活
@params skillIds int 主角技id
@params serverCommand BattleNetworkCommandStruct 与服务器交互的命令信息
@params fromtoData BattleMediatorsConnectStruct 跳转信息
@params buffs list 携带的战前buffid
--]]
function BattleConstructor:InitDataByShareBossCustomizeCard(stageId, friendCardIds, monsterAttrData, leftBuyRevivalTime, buyRevivalTimeMax, isOpenRevival, skillIds, serverCommand, fromtoData, buffs)
	-- 设置战斗文件夹
	SetBattleFolder(BattleFolder.BATTLE_NEW)

	------------ 处理友方阵容信息 ------------
	local formattedFriendTeamData = self:GetFormattedTeamsDataByTeamsMyCardData({[1] = friendCardIds})
	local formattedFriendPlayerSkillData = self:GetFormattedPlayerSkill(gameMgr:GetUserInfo().allSkill, skillIds)

	local friendFormationData = FormationStruct.New(
		teamId,
		formattedFriendTeamData,
		formattedFriendPlayerSkillData,
		ObjectPropertyFixedAttrStruct.New()
	)
	------------ 处理友方阵容信息 ------------

	------------ 处理敌方阵容信息 ------------
	local formattedEnemyTeamData = self:GetCommonEnemyTeamDataByStageId(stageId, nil, monsterAttrData)
	local formattedEnemyPlayerSkillData = nil

	local enemyFormationData = FormationStruct.New(
		stageId,
		formattedEnemyTeamData,
		formattedEnemyPlayerSkillData,
		ObjectPropertyFixedAttrStruct.New()
	)
	------------ 处理敌方阵容信息 ------------

	------------ 处理每一波的过关条件 ------------
	local stageCompleteInfo = self:GetBattleCompleteConfig(nil, stageId)
	------------ 处理每一波的过关条件 ------------

	------------ 背景图 ------------
	local bgInfo = self:GetBattleBackgroundConfig(nil, stageId)
	------------ 背景图 ------------

	------------ 转换全局buff的数据结构 ------------
	local globalSkills = nil
	if nil ~= buffs then
		globalSkills = self:GetFormattedGlobalSkillsByBuffs(buffs)
	end
	------------ 转换全局buff的数据结构 ------------

	------------ 整合数据结构 ------------
	local stageConfig = CommonUtils.GetQuestConf(stageId)

	local randomConfig = BattleRandomConfigStruct.New()

	local battleConstructorData = BattleConstructorStruct.New(
		------------ 战斗基本配置 ------------
		stageId,
		CommonUtils.GetQuestBattleByQuestId(stageId),
		randomConfig,
		gameMgr:GetUserInfo().localBattleAccelerate,
		checkint(stageConfig.time),
		#formattedEnemyTeamData,
		checkint(stageConfig.settlementType),
		stageCompleteInfo,
		false,
		false,
		------------ 战斗数值配置 ------------
		true,
		------------ 战斗环境配置 ------------
		stageConfig.weatherId,
		stageConfig.actionId,
		nil,
		globalSkills,
		true,
		false,
		false,
		false,
		------------ 其他信息 ------------
		stageConfig.allClean,
		false,
		1,
		isOpenRevival,
		math.max(0, buyRevivalTimeMax - leftBuyRevivalTime),
		buyRevivalTimeMax,
		------------ 战斗场景配置 ------------
		bgInfo,
		self:GetBattleHideModuleInfo(CommonUtils.GetQuestBattleByQuestId(stageId), stageId),
		------------ 友方阵容信息 ------------
		friendFormationData,
		------------ 敌方阵容信息 ------------
		enemyFormationData,
		------------ 头尾服务器交互命令 ------------
		serverCommand,
		------------ 头尾跳转信息 ------------
		fromtoData
	)

	self.battleConstructorData = battleConstructorData
	dump(self.battleConstructorData, 'InitDataByShareBossCustomizeCard', 10)
	------------ 整合数据结构 ------------
end
--[[
初始化工会派对构造器数据
@params stageId int 派对关卡id
@params teamId int 编队序号
@params serverCommand BattleNetworkCommandStruct 与服务器交互的命令信息
@params fromtoData BattleMediatorsConnectStruct 跳转信息
]]
function BattleConstructor:InitDataByUnionParty(stageId, teamId, serverCommand, fromtoData)
	-- 设置战斗文件夹
	SetBattleFolder(BattleFolder.BATTLE_NEW)

	------------ 处理友方阵容信息 ------------
	local formattedFriendTeamData        = self:GetFormattedFriendTeamDataByTeamId(teamId)
	local formattedFriendPlayerSkillData = self:GetFormattedPlayerSkill(gameMgr:GetUserInfo().allSkill, gameMgr:GetUserInfo().skill)
	local friendFormationData            = FormationStruct.New(
		teamId,
		formattedFriendTeamData,
		formattedFriendPlayerSkillData,
		ObjectPropertyFixedAttrStruct.New()
	)

	-- 处理一次友方进入战斗传参数据
	serverCommand.enterBattleRequestData.teamId = teamId
	------------ 处理友方阵容信息 ------------

	------------ 处理敌方阵容信息 ------------
	local formattedEnemyTeamData        = self:GetFormattedEnemyTeamDataByUnionPartyStageId(stageId)
	local formattedEnemyPlayerSkillData = nil
	local enemyFormationData            = FormationStruct.New(
		stageId,
		formattedEnemyTeamData,
		formattedEnemyPlayerSkillData,
		ObjectPropertyFixedAttrStruct.New()
	)
	------------ 处理敌方阵容信息 ------------

	------------ 处理过关条件 ------------
	local stageCompleteInfo = self:GetBattleCompleteConfig(QuestBattleType.UNION_PARTY, stageId, #formattedEnemyTeamData)
	------------ 处理过关条件 ------------

	------------ 背景图 ------------
	local bgInfo = self:GetBattleBackgroundConfig(nil, stageId)
	------------ 背景图 ------------

	------------ 整合数据结构 ------------
	local battleStageConfig     = CommonUtils.GetQuestConf(stageId) or {}
	local battleRandomConfig    = BattleRandomConfigStruct.New()
	local battleConstructorData = BattleConstructorStruct.New(
		------------ 战斗基本配置 ------------
		stageId,                                     -- 关卡id
		QuestBattleType.UNION_PARTY,                 -- 战斗类型
		battleRandomConfig,                          -- 战斗随机数配置
		gameMgr:GetUserInfo().localBattleAccelerate, -- 游戏运行速度缩放
		checkint(battleStageConfig.time),            -- 战斗时间限制
		#formattedEnemyTeamData,                     -- 总回合数
		ConfigBattleResultType.NONE,                 -- 结算类型
		stageCompleteInfo,                           -- 过关条件
		false,                                       -- 是否是战报生成器
		false, 										 -- 是否是回放战斗
		------------ 战斗数值配置 ------------
		true,                                        -- 是否开启等级碾压
		------------ 战斗环境配置 ------------
		checktable(battleStageConfig.weatherId),     -- 天气数据
		checktable(battleStageConfig.actionId),      -- 阶段转换信息
		nil, 										 -- 卡牌外部能力增强信息
		nil,                                         -- 全局效果数据
		true,                                        -- 连携技可用
		false,                                       -- 自动释放连携技
		false,
		false,
		------------ 其他信息 ------------
		nil,                                         -- 特殊条件
		false,                                       -- 是否可以重复挑战
		0,                                           -- 剩余挑战次数
		false,                                       -- 是否可以买活
		0,                                           -- 已买活次数
		0,                                           -- 最大买活次数 
		------------ 战斗场景配置 ------------
		bgInfo,    									 -- 背景图id
		nil, 										 -- 隐藏的功能模块界面
		------------ 友方阵容信息 ------------
		friendFormationData,
		------------ 敌方阵容信息 ------------
		enemyFormationData,
		--------- 头尾服务器交互命令 ----------
		serverCommand,
		------------ 头尾跳转信息 ------------
		fromtoData
	)
	self.battleConstructorData = battleConstructorData
	dump(self.battleConstructorData, 'InitDataByUnionParty', 10)
end
--[[
初始化3v3车轮战构造器数据
@params friendTeams list 友方阵容
{
	[1] = {
		id,
		id,
		id,
		id,
		id
	},
	[2] = {
		id,
		id,
		id,
		id,
		id
	},
	[3] = {
		id,
		id,
		id,
		id,
		id
	}
}
@params enemyTeams list 敌方阵容
@params friendAllSkills list 友方主角技
@params enemyAllSkills list 敌方主角技
@params serverCommand BattleNetworkCommandStruct 与服务器交互的命令信息
@params fromtoData BattleMediatorsConnectStruct 跳转信息
--]]
function BattleConstructor:InitDataByTagMatchThreeTeams(friendTeams, enemyTeams, friendAllSkills, enemyAllSkills, serverCommand, fromtoData)
	-- 设置战斗文件夹
	SetBattleFolder(BattleFolder.BATTLE_NEW)

	local questBattleType = QuestBattleType.TAG_MATCH_3V3

	------------ 处理友方阵容信息 ------------
	local formattedFriendTeamData = self:GetFormattedTeamsDataByTeamsMyCardData(friendTeams)
	local formattedFriendPlayerSkillData = self:GetFormattedPlayerSkill(friendAllSkills, {})

	local friendFormationData = FormationStruct.New(
		nil,
		formattedFriendTeamData,
		formattedFriendPlayerSkillData,
		self:GetObjPFixedAttrByQuestBattleType(questBattleType, true)
	)
	------------ 处理友方阵容信息 ------------

	------------ 处理敌方阵容信息 ------------
	local formattedEnemyTeamData = self:GetFormattedTeamsDataByTeamsCardData(enemyTeams)
	local formattedEnemyPlayerSkillData = self:GetFormattedPlayerSkill(enemyAllSkills, {})
	local enemyFormationData = FormationStruct.New(
		nil,
		formattedEnemyTeamData,
		formattedEnemyPlayerSkillData,
		self:GetObjPFixedAttrByQuestBattleType(questBattleType, false)
	)
	------------ 处理敌方阵容信息 ------------

	------------ 车轮战初始化只创建一波 之后的动态创建 ------------
	local stageCompleteInfo = self:GetBattleCompleteConfig(questBattleType)
	------------ 车轮战初始化只创建一波 之后的动态创建 ------------

	local randomConfig = BattleRandomConfigStruct.New()

	local battleConstructorData = BattleConstructorStruct.New(
		------------ 战斗基本配置 ------------
		nil,
		questBattleType,
		randomConfig,
		2,
		self:GetBattleTotalTime(questBattleType),
		1,
		ConfigBattleResultType.NO_DROP,
		stageCompleteInfo,
		false,
		false,
		------------ 战斗数值配置 ------------
		false,
		------------ 战斗环境配置 ------------
		{},
		{},
		nil,
		nil,
		true,
		true,
		false,
		false,
		------------ 其他信息 ------------
		nil,
		false,
		0,
		false,
		0,
		0,
		------------ 战斗场景配置 ------------
		self:GetBattleBackgroundConfig(questBattleType),
		nil,
		------------ 友方阵容信息 ------------
		friendFormationData,
		------------ 敌方阵容信息 ------------
		enemyFormationData,
		------------ 头尾服务器交互命令 ------------
		serverCommand,
		------------ 头尾跳转信息 ------------
		fromtoData
	)

	self.battleConstructorData = battleConstructorData
	dump(self.battleConstructorData, 'InitDataByTagMatchThreeTeams', 10)
end
--[[
根据通用的敌友阵容初始化一场单队伍的pvc战斗
@params questBattleType QuestBattleType 战斗类型
@params settlementType ConfigBattleResultType 结算类型
@params friendCardIds list 友方阵容
@params rivalTeamData list 敌方阵容 卡牌信息
@params friendAllSkills list 友方主角技
@params enemyAllSkills list 敌方主角技
@params skills list<skillId int> 全局buff
@params randomseed stirng 随机种子
@params serverCommand BattleNetworkCommandStruct 与服务器交互的命令信息
@params fromtoData BattleMediatorsConnectStruct 跳转信息
--]]
function BattleConstructor:InitByCommonPVCSingleTeam(questBattleType, settlementType, friendCardIds, rivalTeamData, friendAllSkills, enemyAllSkills, skills, randomseed, serverCommand, fromtoData)
	-- 设置战斗文件夹
	SetBattleFolder(BattleFolder.BATTLE_NEW)

	------------ 处理友方阵容信息 ------------
	local formattedFriendTeamData = self:GetFormattedTeamsDataByTeamsMyCardData({[1] = friendCardIds})
	local formattedFriendPlayerSkillData = self:GetFormattedPlayerSkill(friendAllSkills, {})

	local friendFormationData = FormationStruct.New(
		nil,
		formattedFriendTeamData,
		formattedFriendPlayerSkillData,
		self:GetObjPFixedAttrByQuestBattleType(questBattleType, true)
	)
	------------ 处理友方阵容信息 ------------

	------------ 处理敌方阵容信息 ------------
	local formattedEnemyTeamData = self:GetFormattedTeamsDataByTeamsCardData({[1] = rivalTeamData})
	local formattedEnemyPlayerSkillData = self:GetFormattedPlayerSkill(enemyAllSkills, {})

	local enemyFormationData = FormationStruct.New(
		nil,
		formattedEnemyTeamData,
		formattedEnemyPlayerSkillData,
		self:GetObjPFixedAttrByQuestBattleType(questBattleType, false)
	)
	------------ 处理敌方阵容信息 ------------

	------------ 竞技场写死只有一波 条件只有团灭对面 ------------
	local stageCompleteInfo = self:GetBattleCompleteConfig(questBattleType, nil, #formattedEnemyTeamData)
	------------ 竞技场写死只有一波 条件只有团灭对面 ------------

	------------ 背景图 ------------
	local bgInfo = self:GetBattleBackgroundConfig(questBattleType)
	------------ 背景图 ------------

	------------ 转换全局buff的数据结构 ------------
	local globalSkills = nil
	if nil ~= skills then
		globalSkills = self:GetFormattedGlobalSkillsBySkills(skills)
	end
	------------ 转换全局buff的数据结构 ------------

	local randomConfig = BattleRandomConfigStruct.New()

	local battleConstructorData = BattleConstructorStruct.New(
		------------ 战斗基本配置 ------------
		nil,
		questBattleType,
		randomConfig,
		gameMgr:GetUserInfo().localBattleAccelerate,
		self:GetBattleTotalTime(questBattleType),
		#formattedEnemyTeamData,
		settlementType,
		stageCompleteInfo,
		false,
		false,
		------------ 战斗数值配置 ------------
		self:OpenLevelRollingByQuestBattleType(questBattleType),
		------------ 战斗环境配置 ------------
		{},
		{},
		nil,
		globalSkills,
		true,
		true,
		false,
		false,
		------------ 其他信息 ------------
		nil,
		false,
		0,
		false,
		0,
		0,
		------------ 战斗场景配置 ------------
		bgInfo,
		nil,
		------------ 友方阵容信息 ------------
		friendFormationData,
		------------ 敌方阵容信息 ------------
		enemyFormationData,
		------------ 头尾服务器交互命令 ------------
		serverCommand,
		------------ 头尾跳转信息 ------------
		fromtoData
	)

	self.battleConstructorData = battleConstructorData
	dump(self.battleConstructorData, 'InitByCommonPVCSingleTeam', 10)
end
--[[
初始化工会战的boss战
@params stageId int 关卡id
@params level int 神兽等级
@params friendCardIds list 友方阵容
@params friendAllSkills list 友方主角技
@params skills list<skillId int> 全局buff
@params serverCommand BattleNetworkCommandStruct 与服务器交互的命令信息
@params fromtoData BattleMediatorsConnectStruct 跳转信息
--]]
function BattleConstructor:InitByUnionWarsPVB(stageId, level, friendCardIds, friendAllSkills, skills, serverCommand, fromtoData)
	-- 设置战斗文件夹
	SetBattleFolder(BattleFolder.BATTLE_NEW)

	local questBattleType = CommonUtils.GetQuestBattleByQuestId(stageId)

	------------ 处理友方阵容信息 ------------
	local formattedFriendTeamData = self:GetFormattedTeamsDataByTeamsMyCardData({[1] = friendCardIds})
	local formattedFriendPlayerSkillData = self:GetFormattedPlayerSkill(friendAllSkills, {})

	local friendFormationData = FormationStruct.New(
		nil,
		formattedFriendTeamData,
		formattedFriendPlayerSkillData,
		self:GetObjPFixedAttrByQuestBattleType(questBattleType, true)
	)
	------------ 处理友方阵容信息 ------------

	------------ 处理敌方阵容信息 ------------
	local monsterIntensityData = self:GetUnionWarsBossIntensity(stageId, level)
	local formattedEnemyTeamData = self:GetCommonEnemyTeamDataByStageId(stageId, monsterIntensityData)
	local formattedEnemyPlayerSkillData = nil

	local enemyFormationData = FormationStruct.New(
		stageId,
		formattedEnemyTeamData,
		formattedEnemyPlayerSkillData,
		self:GetObjPFixedAttrByQuestBattleType(questBattleType, false)
	)
	------------ 处理敌方阵容信息 ------------

	------------ 处理每一波的过关条件 ------------
	local stageCompleteInfo = self:GetBattleCompleteConfig(nil, stageId)
	------------ 处理每一波的过关条件 ------------

	------------ 背景图 ------------
	local bgInfo = self:GetBattleBackgroundConfig(nil, stageId)
	------------ 背景图 ------------

	------------ 转换全局buff的数据结构 ------------
	local globalSkills = nil
	if nil ~= skills then
		globalSkills = self:GetFormattedGlobalSkillsBySkills(skills)
	end
	------------ 转换全局buff的数据结构 ------------

	------------ 整合数据结构 ------------
	local stageConfig = CommonUtils.GetQuestConf(stageId)

	local randomConfig = BattleRandomConfigStruct.New()

	local battleConstructorData = BattleConstructorStruct.New(
		------------ 战斗基本配置 ------------
		stageId,
		questBattleType,
		randomConfig,
		gameMgr:GetUserInfo().localBattleAccelerate,
		self:GetBattleTotalTime(nil, stageId),
		#formattedEnemyTeamData,
		checkint(stageConfig.settlementType),
		stageCompleteInfo,
		false,
		false,
		------------ 战斗数值配置 ------------
		self:OpenLevelRollingByQuestBattleType(questBattleType),
		------------ 战斗环境配置 ------------
		stageConfig.weatherId,
		stageConfig.actionId,
		nil,
		globalSkills,
		true,
		false,
		false,
		false,
		------------ 其他信息 ------------
		stageConfig.allClean,
		false,
		1,
		false,
		0,
		0,
		------------ 战斗场景配置 ------------
		bgInfo,
		stageConfig.hiddenModule,
		------------ 友方阵容信息 ------------
		friendFormationData,
		------------ 敌方阵容信息 ------------
		enemyFormationData,
		------------ 头尾服务器交互命令 ------------
		serverCommand,
		------------ 头尾跳转信息 ------------
		fromtoData
	)

	self.battleConstructorData = battleConstructorData
	dump(self.battleConstructorData, 'InitByUnionWarsPVB', 10)
	------------ 整合数据结构 ------------
end
--[[
初始化一场由外部传入阵容的战斗 -> !!!该方法足够通用 传格式化后的数据给我!!!
@params stageId int 关卡id
@params questBattleType QuestBattleType 战斗类型
@params settlementType ConfigBattleResultType 结算类型
@params formattedFriendTeamData list 友方阵容
@params formattedEnemyTeamData list 敌方阵容
@params friendEquipedSkills list 友方携带的主角技
@params friendAllSkills list 友方所有主角技
@params enemyEquipedSkills list 敌方携带的主角技
@params enemyAllSkills list 敌方所有主角技
@params skills list<skillId int> 全局buff
@params abilityData ? 卡牌能力增强信息
@params buyRevivalTime int 已买活次数
@params buyRevivalTimeMax int 最大买活次数
@params isOpenRevival bool 是否开启买活
@params randomseed stirng 随机种子
@params isReplay bool 是否是战斗回放
@params serverCommand BattleNetworkCommandStruct 与服务器交互的命令信息
@params fromtoData BattleMediatorsConnectStruct 跳转信息
--]]
function BattleConstructor:InitByCommonData(
		stageId, questBattleType, settlementType,
		formattedFriendTeamData, formattedEnemyTeamData,
		friendEquipedSkills, friendAllSkills, enemyEquipedSkills, enemyAllSkills,
		skills, abilityData,
		buyRevivalTime, buyRevivalTimeMax, isOpenRevival,
		randomseed, isReplay,
		serverCommand, fromtoData
	)
	-- 设置战斗文件夹
	SetBattleFolder(BattleFolder.BATTLE_NEW)

	local stageConfig = CommonUtils.GetQuestConf(stageId)

	------------ 处理友方阵容信息 ------------
	local formattedFriendPlayerSkillData = self:GetFormattedPlayerSkill(friendAllSkills or {}, friendEquipedSkills or {})

	local friendFormationData = FormationStruct.New(
		nil,
		formattedFriendTeamData,
		formattedFriendPlayerSkillData,
		self:GetObjPFixedAttrByQuestBattleType(questBattleType, true)
	)
	------------ 处理友方阵容信息 ------------

	------------ 处理敌方阵容信息 ------------
	local formattedEnemyPlayerSkillData = self:GetFormattedPlayerSkill(enemyAllSkills or {}, enemyEquipedSkills or {})

	local enemyFormationData = FormationStruct.New(
		nil,
		formattedEnemyTeamData,
		formattedEnemyPlayerSkillData,
		self:GetObjPFixedAttrByQuestBattleType(questBattleType, false)
	)
	------------ 处理敌方阵容信息 ------------

	------------ 处理每一波的过关条件 ------------
	local stageCompleteInfo = self:GetBattleCompleteConfig(questBattleType, stageId, #formattedEnemyTeamData)
	------------ 处理每一波的过关条件 ------------

	------------ 结算类型 ------------
	local settlementType_ = nil
	if nil ~= settlementType then
		settlementType_ = settlementType
	elseif nil ~= stageConfig then
		settlementType_ = checkint(stageConfig.settlementType)
	else
		settlementType_ = ConfigBattleResultType.NORMAL
	end
	------------ 结算类型 ------------

	------------ 背景图 ------------
	local bgInfo = self:GetBattleBackgroundConfig(questBattleType, stageId)
	------------ 背景图 ------------

	------------ 整合数据结构 ------------
	local randomConfig = BattleRandomConfigStruct.New(randomseed)

	local battleConstructorData = BattleConstructorStruct.New(
		------------ 战斗基本配置 ------------
		stageId,
		questBattleType,
		randomConfig,
		self:GetCommonBattleTimeScale(questBattleType),
		self:GetBattleTotalTime(questBattleType, stageId),
		#formattedEnemyTeamData,
		settlementType_,
		stageCompleteInfo,
		false,
		isReplay == true,
		------------ 战斗数值配置 ------------
		self:OpenLevelRollingByQuestBattleType(questBattleType),
		------------ 战斗环境配置 ------------
		self:GetBattleWeatherInfo(questBattleType, stageId),
		self:GetBattleBossActionInfo(questBattleType, stageId),
		self:GetFormattedAbilityRelationInfo(abilityData),
		skills,
		self:GetEnableConnect(questBattleType, stageId),
		self:GetAutoConnect(questBattleType, stageId),
		self:GetEnemyEnableConnect(questBattleType, stageId),
		self:GetEnemyAutoConnect(questBattleType, stageId),
		------------ 其他信息 ------------
		self:GetBattleAllCleanInfo(questBattleType, stageId),
		false,
		1,
		isOpenRevival == true,
		buyRevivalTime or 0,
		buyRevivalTimeMax or 0,
		------------ 战斗场景配置 ------------
		bgInfo,
		self:GetBattleHideModuleInfo(questBattleType, stageId),
		------------ 友方阵容信息 ------------
		friendFormationData,
		------------ 敌方阵容信息 ------------
		enemyFormationData,
		------------ 头尾服务器交互命令 ------------
		serverCommand,
		------------ 头尾跳转信息 ------------
		fromtoData
	)

	self.battleConstructorData = battleConstructorData
	-- dump(self.battleConstructorData, 'InitByCommonData', 10)
	------------ 整合数据结构 ------------
end
--[[
根据rep数据初始化战斗构造数据
@params stageId int 关卡id
@params constructorJson json 由客户端传入的构造器json
@params friendTeamJson json 友方阵容json
@params enemyTeamJson json 敌方阵容json
@params fromtoData BattleMediatorsConnectStruct 跳转信息
@params resultType ConfigBattleResultType 结算类型
--]]
function BattleConstructor:InitByOneTeamReplayData(stageId, constructorJson, friendTeamJson, enemyTeamJson, fromtoData, resultType)
	-- 处理构造器数据
	local constructorData = String2TableNoMeta(constructorJson)

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

	------------ 处理友方阵容信息 ------------
	-- 阵容信息
	local formattedFriendTeamData = self:ConvertTeamDataByJson(friendTeamJson)
	-- 主角技信息
	local formattedFriendPlayerSkillData = self:ConvertPlayerSkillByJson(friendPlayerSkillJson)

	local friendFormationData = FormationStruct.New(
		nil,
		formattedFriendTeamData,
		friendPlayerSkill,
		self:GetObjPFixedAttrByQuestBattleType(questBattleType, true)
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
		self:GetObjPFixedAttrByQuestBattleType(questBattleType, false)
	)
	------------ 处理敌方阵容信息 ------------

	------------ 处理每一波的过关条件 ------------
	local totalWave = #formattedEnemyTeamData
	local stageCompleteInfo = self:GetBattleCompleteConfig(questBattleType, stageId, totalWave)
	------------ 处理每一波的过关条件 ------------

	local battleConstructorData = BattleConstructorStruct.New(
		------------ 战斗基本配置 ------------
		stageId, -- int 关卡id
		questBattleType, -- QuestBattleType 战斗类型
		randomConfig, -- BattleRandomConfigStruct 战斗随机数配置
		gameTimeScale, -- int 游戏运行速度缩放
		stageTime, -- int 战斗时间限制 second
		totalWave, -- int 总波数
		resultType or ConfigBattleResultType.REPLAY, -- 结算类型
		stageCompleteInfo, -- list(StageCompleteSturct) 过关条件
		false, -- 是否是战报生成器
		true, -- bool 是否是录像
		------------ 战斗数值配置 ------------
		openLevelRolling, -- bool 是否开启等级碾压
		------------ 战斗环境配置 ------------
		weatherInfo, -- table 天气
		phaseChangeInfo, -- map 阶段转换信息
		abilityRelationInfo, -- list<ObjectAbilityRelationStruct>
		globalEffects, -- list 全局效果列表
		enableConnect, -- bool 连携技可用
		autoConnect, -- bool 自动释放连携技
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
		self:GetBattleBackgroundConfig(questBattleType, stageId), -- list 背景图信息
		self:GetBattleHideModuleInfo(questBattleType, stageId), -- list<ConfigBattleFunctionModuleType> 隐藏的战斗功能模块界面
		------------ 友方阵容信息 ------------
		friendFormationData, -- FormationStruct 友方阵容信息
		------------ 敌方阵容信息 ------------
		enemyFormationData, -- FormationStruct 敌方阵容信息
		------------ 头尾服务器交互命令 ------------
		nil, -- BattleNetworkCommandStruct 与服务器交互的命令信息
		------------ 头尾跳转信息 ------------
		fromtoData -- BattleMediatorsConnectStruct 跳转信息
	)

	self.battleConstructorData = battleConstructorData
	dump(self.battleConstructorData, 'InitByOneTeamReplayData', 10)
end
---------------------------------------------------
-- init logic end --
---------------------------------------------------

---------------------------------------------------
-- logic begin --
---------------------------------------------------
--[[
根据队伍id判断是否可以进入战斗
@params teamId int 队伍id
@return canEnterBattle, waringText bool, string 是否可以进入战斗 警告文字
--]]
function BattleConstructor:CanEnterBattleByTeamId(teamId)
	local teamData = gameMgr:getTeamCardsInfo(teamId)
	local canEnterBattle = true
	local waringText = nil
	for i,v in ipairs(teamData) do
		if nil ~= v.id then
			local ifMutex, placeId = gameMgr:CanSwitchCardStatus(
				{id = v.id},
				CARDPLACE.PLACE_FIGHT
			)

			if false == ifMutex and placeId then
				-- 互斥
				canEnterBattle = false

				local placeName = gameMgr:GetModuleName(placeId)
				waringText = string.format(__('您的队伍正在%s, 不能出战'), tostring(placeName))
				break
			end
		end
	end

	return canEnterBattle, waringText
end
--[[
根据卡牌card ids判断是否可以进入战斗
@params cardIds list 卡牌数据库id
--]]
function BattleConstructor:CanEnterBattleByCardIds(cardIds)
	local canEnterBattle = true
	local waringText = nil

	local c_id = nil

	for i,v in ipairs(cardIds) do
		c_id = checkint(v)
		if 0 ~= c_id then
			local ifMutex, placeId = gameMgr:CanSwitchCardStatus(
				{id = c_id},
				CARDPLACE.PLACE_FIGHT
			)

			if false == ifMutex and placeId then
				-- 互斥
				canEnterBattle = false

				local placeName = gameMgr:GetModuleName(placeId)
				waringText = string.format(__('您有飨灵正在%s, 不能出战'), tostring(placeName))
				break
			end
		end
	end

	return canEnterBattle, waringText
end
--[[
起战斗
--]]
function BattleConstructor:OpenBattle()
	-- 判断是否可以起战斗
	local canOpenBattle, waringText = self:CanOpenBattle()
	if not canOpenBattle then
		app.uiMgr:ShowInformationTips(waringText)
		return
	end

	if not AppFacade.GetInstance():RetrieveMediator('EnterBattleMediator') then
		local enterBattleMediator = require('Game.mediator.EnterBattleMediator').new()
		AppFacade.GetInstance():RegistMediator(enterBattleMediator)
	end

	GuideUtils.DispatchStepEvent()
	AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.Battle_Enter, self)
end
--[[
是否可以起战斗
@return canOpenBattle, waringText bool, string 是否可以起战斗, 警告文字
--]]
function BattleConstructor:CanOpenBattle()
	local canOpenBattle = true
	local waringText = nil

	------------ 战斗时间不能为0 ------------
	if 0 >= self:GetBattleConstructData().time then
		return false, __('关卡时间不能为0!!!')
	end
	------------ 战斗时间不能为0 ------------

	------------ 友军阵容不能为空 ------------
	if 0 >= #self:GetBattleConstructData().friendFormation.members then
		return false, __('必须要有一队!!!')
	else
		-- 遍历每一队 队伍不能为空
		for teamIndex, teamData in ipairs(self:GetBattleConstructData().friendFormation.members) do
			if 0 >= #teamData then
				return false, __('队伍不能为空!!!')
			end
		end
	end
	------------ 友军阵容不能为空 ------------

	return canOpenBattle, waringText
end
--[[
是否可以根据服务器计算的数据开启一场回放
@return canOpenBattle, waringText bool, string 是否可以起战斗, 警告文字 
--]]
function BattleConstructor:CanOpenReplayByServerCalculator()
	return true
end
--[[
起录像
@params stageId int 关卡id
@params constructorJson json 由客户端传入的构造器json
@params friendTeamJson json 友方阵容json
@params enemyTeamJson json 敌方阵容json
@params loadedResourcesJson json 加载的资源表
@params playerOperateJson json 玩家的手操信息
@params fromtoData BattleMediatorsConnectStruct 跳转信息
@params resultType ConfigBattleResultType 结算类型
--]]
function BattleConstructor:OpenReplay(stageId, constructorJson, friendTeamJson, enemyTeamJson, loadedResourcesJson, playerOperateJson, fromtoData, resultType)
	-- 初始化构造器数据
	self:InitByOneTeamReplayData(stageId, constructorJson, friendTeamJson, enemyTeamJson, fromtoData, resultType)

	local canOpenBattle, waringText = self:CanOpenReplayByServerCalculator()
	if not canOpenBattle then
		app.uiMgr:ShowInformationTips(waringText)
		return
	end

	-- 初始化战斗mdt
	AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch(
		{name = fromtoData.fromMediatorName},
		{name = 'BattleMediator', params = self}
	)
	local battleMediator = AppFacade.GetInstance():RetrieveMediator('BattleMediator')
	if nil ~= battleMediator then

		local battleManager = battleMediator.battleManager

		-- 初始化一些客户端数据
		battleManager:InitClientBasedData(
			loadedResourcesJson,
			playerOperateJson
		)

		-- 调用开始战斗
		battleManager:EnterBattle()

	end
end
---------------------------------------------------
-- logic end --
---------------------------------------------------

---------------------------------------------------
-- data format <<< card team begin --
---------------------------------------------------
--[[
根据选择的编队序号初始化战斗构造器己方阵容数据
@params teamId int 编队序号
@return teamsData list 阵容数据
--]]
function BattleConstructor:GetFormattedFriendTeamDataByTeamId(teamId)
	local teamsData = {
		[1] = nil
	}

	local singleTeamData = self:GetAFormattedTeamDataByTeamId(teamId)
	teamsData[1] = singleTeamData

	return teamsData
end
--[[
根据编队id获取格式化后的单队卡牌数据
@params teamId int 编队id
@return teamData list 队伍数据
--]]
function BattleConstructor:GetAFormattedTeamDataByTeamId(teamId)
	local teamData = {}
	local localTeamData = gameMgr:getTeamCardsInfo(teamId)
	local cardData = nil
	local c_id = nil

	for i,v in ipairs(localTeamData) do
		if nil ~= v.id and 0 ~= checkint(v.id) then
			c_id = checkint(v.id)
			cardData = gameMgr:GetCardDataById(c_id)
			if nil ~= cardData and 0 ~= checkint(cardData.cardId) then
				local cardConstructorData = self:GetAFormattedCardStructByMyCardData(cardData)
				if nil ~= cardConstructorData then
					------------ 修改一些编队决定的信息 ------------
					-- 是否是队长
					cardConstructorData.isLeader = 1 == i
					-- 卡牌位置序号
					cardConstructorData.teamPosition = #teamData + 1
					------------ 修改一些编队决定的信息 ------------
					table.insert(teamData, cardConstructorData)
				end
			end
		end
	end

	return teamData
end
--[[
根据我的卡牌多队阵容数据获取格式化后的阵容战斗构造数据
@params data list 多队阵容信息
@params attrData map 卡牌属性数据 {
	['teamIndex'] = {
		[position] = {
			[ObjP] = {percent = nil, value = nil}
		},
		...
	},
	...
}
@return teamsData list 格式化后的阵容数据
--]]
function BattleConstructor:GetFormattedTeamsDataByTeamsMyCardData(data, attrData)
	local teamsData = {}
	local attrData_ = nil

	for teamIdx, teamData in ipairs(data) do

		attrData_ = nil
		if nil ~= attrData then
			attrData_ = attrData[tostring(teamIdx)]
		end

		local teamData_ = self:GetAFormattedTeamDataById(teamData, attrData_)
		teamsData[teamIdx] = teamData_

	end

	return teamsData
end
--[[
根据多队阵容数据获取格式化后的阵容战斗构造数据
@params data list 多队阵容信息
@params attrData map 卡牌属性数据
@return teamsData list 格式化后的阵容数据
--]]
function BattleConstructor:GetFormattedTeamsDataByTeamsCardData(data, attrData)
	local teamsData = {}
	local attrData_ = nil

	for teamIdx, teamData in ipairs(data) do

		attrData_ = nil
		if nil ~= attrData then
			attrData_ = attrData[tostring(teamIdx)]
		end

		local teamData_ = self:GetAFormattedTeamDataByCommonTeamCardsData(teamData, attrData_)
		teamsData[teamIdx] = teamData_
	end

	return teamsData
end
--[[
根据卡牌数据库id集合获取格式化后的单队卡牌数据
@params data list 队伍数据
@params attrData map 卡牌属性数据 {
	[position] = {
		[ObjP] = {percent = nil, value = nil}
	},
	...
}
@return teamData list 队伍数据
--]]
function BattleConstructor:GetAFormattedTeamDataById(data, attrData)
	local teamData = {}
	local cardData = nil
	local c_id = nil
	local cardAttrData = nil

	for i = 1, MAX_TEAM_MEMBER_AMOUNT, 1 do

		local cardIdInfo_ = data[i]
		if nil ~= cardIdInfo_ then

			c_id = checkint(cardIdInfo_)
			if 0 ~= c_id then
				cardData = gameMgr:GetCardDataById(c_id)
				if nil ~= cardData and 0 ~= checkint(cardData.cardId) then

					-- 卡牌外部属性
					cardAttrData = nil
					if nil ~= attrData and
						nil ~= attrData[i] then

						cardAttrData = attrData[i]

					end

					local cardConstructorData = self:GetAFormattedCardStructByMyCardData(cardData, cardAttrData)
					if nil ~= cardConstructorData then
						------------ 修改一些编队决定的信息 ------------
						-- 是否是队长
						cardConstructorData.isLeader = 1 == i
						-- 卡牌位置序号
						cardConstructorData.teamPosition = #teamData + 1
						------------ 修改一些编队决定的信息 ------------
						table.insert(teamData, cardConstructorData)
					end

				end
			end

		end

	end

	return teamData
end
--[[
根据通用的卡牌数据获取格式化后的单队构造卡牌数据
@params data list 通用的队伍数据
@params attrData map 卡牌属性数据
@return teamData list 队伍数据
--]]
function BattleConstructor:GetAFormattedTeamDataByCommonTeamCardsData(data, attrData)
	local teamData = {}
	local cardData = nil
	local cardAttrData = nil

	for i = 1, MAX_TEAM_MEMBER_AMOUNT do

		cardData = data[i]
		if nil ~= cardData and nil ~= cardData.cardId and 0 ~= checkint(cardData.cardId) then

			-- 卡牌外部属性
			cardAttrData = nil
			if nil ~= attrData and
				nil ~= attrData[i] then

				cardAttrData = attrData[i]

			end

			local cardConstructorData = self:GetAFormattedCardStructByCommonCardData(cardData, cardAttrData)
			if nil ~= cardConstructorData then
				------------ 修改一些编队决定的信息 ------------
				-- 是否是队长
				cardConstructorData.isLeader = 1 == i
				-- 卡牌位置序号
				cardConstructorData.teamPosition = #teamData + 1
				------------ 修改一些编队决定的信息 ------------
				table.insert(teamData, cardConstructorData)
			end

		end

	end

	return teamData
end
---------------------------------------------------
-- data format <<< card team end --
---------------------------------------------------

---------------------------------------------------
-- data format <<< enemy team begin --
---------------------------------------------------
--[[
根据通用关卡id获取初始化后的怪物阵容数据改二->提高通用性
@params stageId int 通用关卡id
@params monsterIntensityData MonsterIntensityAttrStruct 怪物强度信息
@params monsterAttrData table 怪物属性数据
--]]
function BattleConstructor:GetCommonEnemyTeamDataByStageId(stageId, monsterIntensityData, monsterAttrData)
	local enemyConfig = CommonUtils.GetConfig('quest', 'enemy', stageId)
	return self:GetFEnemyTeamDataByIntensityData(enemyConfig, monsterIntensityData, monsterAttrData)
end
--[[
根据单元id 所在层数 获取敌方阵容
@params unitId int 爬塔单元id
@params currentFloor int 当前层数
--]]
function BattleConstructor:GetFormattedEnemyTeamDataByUnitAndFloor(unitId, currentFloor)
	local fixedFloor = (currentFloor - 1) % 5 + 1
	local unitConfig = CommonUtils.GetConfigAllMess(TowerConfigParser.TYPE.UNIT ,'tower')[tostring(unitId)]
	if nil == unitConfig then
		-- 未找到单元配置
		uiMgr:ShowInformationTips(__('未找到单元配置 unit id -> ') .. unitId)
		return
	end

	local enemyConfigId = checkint(unitConfig.enemy[fixedFloor])
	local enemyConfig = CommonUtils.GetConfigAllMess(TowerConfigParser.TYPE.ENEMY ,'tower')[tostring(enemyConfigId)] or {}

	local maxDiffFloor = table.nums(CommonUtils.GetConfigAllMess(TowerConfigParser.TYPE.LEVEL_ATTR ,'tower'))
	local diffAttrConfig = CommonUtils.GetConfigAllMess(TowerConfigParser.TYPE.LEVEL_ATTR ,'tower')[tostring(math.min(currentFloor, maxDiffFloor))]
	local intensityData = MonsterIntensityAttrStruct.New(diffAttrConfig)

	local teamData = self:GetFEnemyTeamDataByIntensityData(enemyConfig, intensityData)

	return teamData
end
--[[
根据通用关卡id获取初始化后的怪物阵容数据
@params stageId int 工会派对关卡id
]]
function BattleConstructor:GetFormattedEnemyTeamDataByUnionPartyStageId(stageId)
	local enemysConfig = CommonUtils.GetConfig('union', UnionConfigParser.TYPE.PARTY_QUEST_ENEMY, stageId) or {}
	local diffAttrConfig = CommonUtils.GetConfig('union', UnionConfigParser.TYPE.PARTY_QUEST_ATTR, gameMgr:GetUserInfo().level) or {}

	local intensityData = MonsterIntensityAttrStruct.New(diffAttrConfig)

	local enemyTeamData = self:GetFEnemyTeamDataByIntensityData(enemysConfig, intensityData)
	
	return enemyTeamData
end
--[[
根据怪物强度配置获取修正后的怪物阵容数据
@params enemyConfig config 阵容配置
@params monsterIntensityData MonsterIntensityAttrStruct 怪物强度信息
@params monsterAttrData table 怪物属性参数
@return teamData list<list<MonsterObjConstructorStruct>>
--]]
function BattleConstructor:GetFEnemyTeamDataByIntensityData(enemyConfig, monsterIntensityData, monsterAttrData)
	local teamData = {}

	local totalWave = table.nums(enemyConfig)

	local c_ = nil

	for wave = 1, totalWave do

		c_ = enemyConfig[tostring(wave)]

		local waveData = {}

		for i,v in ipairs(c_.npc) do

			-- 查找外部属性参数
			local monsterAttrData_ = nil
			if nil ~= monsterAttrData and
				nil ~= monsterAttrData[tostring(wave)] and
				nil ~= monsterAttrData[tostring(wave)][i] then

				monsterAttrData_ = monsterAttrData[tostring(wave)][i]

			end

			-- 处理卡怪混合的阵容
			if nil ~= v.npcId and CardUtils.IsMonsterCard(checkint(v.npcId)) then

				-- 创建怪物
				local monsterId = checkint(v.npcId)

				-- 构造传参用的数据结构
				local monsterConstructorData = self:GetMonsterConstructorData(monsterId, v, monsterIntensityData, monsterAttrData_)
				table.insert(waveData, monsterConstructorData)

			elseif nil ~= v.cardId and not CardUtils.IsMonsterCard(checkint(v.cardId)) then

				-- 创建卡牌
				local cardId = checkint(v.cardId)

				-- 构造传参用的数据结构
				local cardConstructorData = self:GetAFormattedCardStructByCommonCardData(v, monsterAttrData_)
				table.insert(waveData, cardConstructorData)

			end

		end

		teamData[wave] = waveData

	end

	return teamData
end
---------------------------------------------------
-- data format <<< enemy team end --
---------------------------------------------------

---------------------------------------------------
-- data format card begin --
---------------------------------------------------
--[[
根据自己的卡牌数据获取格式化后的卡牌战斗数据
@params cardData table 卡牌数据库数据
@params attrData table 属性参数 继承血量等信息
@return cardConstructorData CardObjConstructorStruct 战斗卡牌构造数据
--]]
function BattleConstructor:GetAFormattedCardStructByMyCardData(cardData, attrData)
	local cardConstructorData = nil
	if nil ~= cardData and 0 ~= checkint(cardData.cardId) then
		local cardId = checkint(cardData.cardId)

		------------ 堕神信息 ------------
		local petStruct = nil
		if nil ~= cardData.playerPetId and 0 ~= checkint(cardData.playerPetId) then			
			local petData = gameMgr:GetPetDataById(checkint(cardData.playerPetId))
			if nil ~= petData then
				petStruct = self:GetAFormattedPetDataByOld(cardId, petData)
			end
		end
		------------ 堕神信息 ------------

		------------ 初始属性信息 ------------
		local hpPercent = 1
		local hpValue = nil
		local energyPercent = nil
		local energyValue = nil

		if nil ~= attrData then

			-- 血量
			local madHp = attrData[ObjP.HP]
			if nil ~= madHp then

				if nil ~= madHp.percent and 0 <= checknumber(madHp.percent) then
					hpPercent = hpPercent * checknumber(madHp.percent)
				end

				if nil ~= madHp.value and 0 <= checknumber(madHp.value) then
					hpValue = checknumber(madHp.value)
				end

			end

			-- 能量
			local madEnergy = attrData[ObjP.ENERGY]
			if nil ~= madEnergy then

				if nil ~= madEnergy.percent and 0 <= checknumber(madEnergy.percent) then
					energyPercent = checknumber(madEnergy.percent)
				end

				if nil ~= madEnergy.value and 0 <= checknumber(madEnergy.value) then
					energyValue = checknumber(madEnergy.value)
				end

			end

		end
		------------ 初始属性信息 ------------

		-- 构造传参用的数据结构
		cardConstructorData = CardObjConstructorStruct.New(
			------------ 卡牌基本信息 ------------
			checkint(cardData.cardId),
			checkint(cardData.exp),
			checkint(cardData.level),
			checkint(cardData.breakLevel),
			checkint(cardData.favorability),
			checkint(cardData.favorabilityLevel or 1),
			checkint(cardData.vigour),
			------------ 外部属性参数 ------------
			ObjPFixedAttrStruct.New(hpPercent, hpValue, energyPercent, energyValue),
			------------ 战斗信息 ------------
			false,
			nil,
			0,
			cardData.skill,
			ArtifactTalentConstructorStruct.New(checkint(cardData.cardId), cardData.artifactTalent),
			self:GetCardEXAbilityInfoByCardId(cardId),
			petStruct,
			BookConstructorStruct.New(checkint(cardData.cardId), cardData.bookLevel),
			CatGeneConstructorStruct.New(cardData.equippedHouseCatGene),
			------------ 外貌信息 ------------
			checkint(cardData.defaultSkinId)
		)
	end
	return cardConstructorData
end
--[[
根据装备的卡牌id 堕神数据(old)获取堕神战斗构造数据
@params equipedCardId int 装备的卡牌id
@params petData table 堕神信息(old)
@return petStruct PetConstructorStruct 堕神战斗构造数据
--]]
function BattleConstructor:GetAFormattedPetDataByOld(equipedCardId, petData)
	local petStruct = nil
	if nil ~= petData and 0 ~= checkint(petData.petId) then
		local petId = checkint(petData.petId)
		local activeExclusive = false

		-- 判断是否激活本命加成
		local petConfig = petMgr.GetPetConfig(petId)
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
			petMgr.GetPetAllFixedPropsByPetData(petData, activeExclusive)
		)
	end
	return petStruct
end
--[[
根据通用的卡牌数据获取格式化后的卡牌战斗数据
@params cardData table 通用卡牌数据(服务器记录的他人卡牌数据)
@params attrData table 属性参数 继承血量等信息
@return cardConstructorData CardObjConstructorStruct 战斗卡牌构造数据
--]]
function BattleConstructor:GetAFormattedCardStructByCommonCardData(cardData, attrData)
	local cardConstructorData = nil
	if nil ~= cardData and 0 ~= checkint(cardData.cardId) then
		local cardId = checkint(cardData.cardId)

		------------ 堕神信息 ------------
		local petStruct = nil
		if nil ~= cardData.pets then
			for k, petData in pairs(cardData.pets) do
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

		------------ 初始属性信息 ------------
		local hpPercent = 1
		local hpValue = nil
		local energyPercent = nil
		local energyValue = nil

		if nil ~= attrData then

			-- 血量
			local madHp = attrData[ObjP.HP]
			if nil ~= madHp then

				if nil ~= madHp.percent and 0 <= checknumber(madHp.percent) then
					hpPercent = hpPercent * checknumber(madHp.percent)
				end

				if nil ~= madHp.value and 0 <= checknumber(madHp.value) then
					hpValue = checknumber(madHp.value)
				end

			end

			-- 能量
			local madEnergy = attrData[ObjP.ENERGY]
			if nil ~= madEnergy then

				if nil ~= madEnergy.percent and 0 <= checknumber(madEnergy.percent) then
					energyPercent = checknumber(madEnergy.percent)
				end

				if nil ~= madEnergy.value and 0 <= checknumber(madEnergy.value) then
					energyValue = checknumber(madEnergy.value)
				end

			end

		end
		------------ 初始属性信息 ------------

		-- 构造传参用的数据结构
		cardConstructorData = CardObjConstructorStruct.New(
			------------ 卡牌基本信息 ------------
			checkint(cardData.cardId),
			checkint(cardData.exp),
			checkint(cardData.level),
			checkint(cardData.breakLevel),
			checkint(cardData.favorability),
			checkint(cardData.favorabilityLevel or 1),
			checkint(cardData.vigour),
			------------ 外部属性参数 ------------
			ObjPFixedAttrStruct.New(hpPercent, hpValue, energyPercent, energyValue),
			------------ 战斗信息 ------------
			false,
			cardData.placeId and checkint(cardData.placeId) or nil,
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
	end
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
		local petConfig = petMgr.GetPetConfig(petId)
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
			petMgr.ConvertPetPropertyDataByServerData(petData, activeExclusive)
		)
	end
	return petStruct
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
-- data format card end --
---------------------------------------------------

---------------------------------------------------
-- data format monster begin --
---------------------------------------------------
--[[
通用方法 根据怪物信息创建战斗中的怪物构造数据
@params monsterId int 怪物id
@params monsterData config 阵容表中的怪物信息
@params monsterIntensityData MonsterIntensityAttrStruct 怪物强度信息 外部传入的怪物强度系数信息 覆盖上一个参数的信息
@params monsterAttrData table 怪物属性参数 一般用来记录继承的血量 能量
@return monsterConstructorData MonsterObjConstructorStruct 怪物构造数据
--]]
function BattleConstructor:GetMonsterConstructorData(monsterId, monsterData, monsterIntensityData, monsterAttrData)
	local monsterConfig = CardUtils.GetCardConfig(monsterId)
	if nil == monsterConfig then
		print('!!!!!!!!!!cannot find monster config in battleconstructor!!!!!!!!!!')
		return nil
	end

	-- 初始化属性参数
	local initialHpPercent = checknumber(monsterData.initialHp or 1)
	if 0 == initialHpPercent then
		initialHpPercent = 1
	end

	-- 初始化外部属性系数 一般用来处理共享血量的boss类型
	local fixedValue = nil
	if nil ~= monsterAttrData then

		local madHp = monsterAttrData[ObjP.HP]
		if nil ~= madHp then
			if nil ~= madHp.percent and 0 <= checknumber(madHp.percent) then
				initialHpPercent = initialHpPercent * checknumber(madHp.percent)
			end

			if nil ~= madHp.value and 0 <= checknumber(madHp.value) then
				fixedValue = checknumber(madHp.value)
			end
		end

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

	-- 各种修正系数
	local level = checkint(monsterData.level or 1)
	local attrGrow = checknumber(monsterData.attrGrow or 1)
	local skillGrow = checknumber(monsterData.skillGrow or 1)

	if nil ~= monsterIntensityData then
		level = monsterIntensityData.level or level
		attrGrow = monsterIntensityData.attrGrow or attrGrow
		skillGrow = monsterIntensityData.skillGrow or skillGrow
	end

	-- 是否记录deltahp
	local recordDeltaHp = nil ~= monsterData.recordDeltaHp and checkint(monsterData.recordDeltaHp) or ConfigMonsterRecordDeltaHP.DONT

	-- 构造传参用的数据结构
	local monsterConstructorData = MonsterObjConstructorStruct.New(
		------------ 怪物基本信息 ------------
		monsterId,
		campType,
		level,
		attrGrow,
		skillGrow,
		recordDeltaHp,
		------------ 外部属性参数 ------------
		ObjPFixedAttrStruct.New(initialHpPercent, fixedValue),
		------------ 战斗信息 ------------
		1 == i,
		checkint(monsterData.placeId),
		i,
		skillData,
		ArtifactTalentConstructorStruct.New(monsterId, nil),
		self:GetCardEXAbilityInfoByCardId(monsterId),
		nil,
		------------ 外貌信息 ------------
		checkint(monsterConfig.skinId)
	)

	return monsterConstructorData
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
	local initialHpPercent = 1
	if nil ~= monsterData.initialHp then
		initialHpPercent = checknumber(monsterData.initialHp)
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
		ConfigMonsterRecordDeltaHP.DONT,
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
---------------------------------------------------
-- data format monster end --
---------------------------------------------------

---------------------------------------------------
-- data format other begin --
---------------------------------------------------
--[[
根据npc配置初始化阵容数据
@params cardIds list 卡牌id
@params skinIds list 卡牌皮肤id
@params propertyId int 卡牌属性id
--]]
function BattleConstructor:GetFormattedTeamDataByCustomizeConfig(cardIds, skinIds, propertyId)
	local teamData = {
		[1] = {}
	}

	local propertyConfig = CommonUtils.GetConfig('arena', 'robotAttr', propertyId)
	if nil == propertyConfig then
		return teamData
	end

	local cardId = nil

	for i,v in ipairs(cardIds) do
		cardId = checkint(v)

		local petStruct = nil
		if nil ~= propertyConfig.pet and 0 ~= checkint(propertyConfig.pet.petId) then

		end

		local bookStruct = nil
		if nil ~= propertyConfig.bookLevel then
			
		end

		local catGeneStruct = nil

		local cardConfig = CardUtils.GetCardConfig(cardId)
		local skillInfo = {}
		for _, skillId in pairs(cardConfig.skill) do
			skillInfo[tostring(skillId)] = {level = propertyConfig.skillLevel}
		end

		-- 构造传参用的数据结构
		local cardConstructorData = CardObjConstructorStruct.New(
			------------ 卡牌基本信息 ------------
			cardId,
			checkint(propertyConfig.exp),
			checkint(propertyConfig.cardLevel),
			checkint(propertyConfig.starMax),
			checkint(propertyConfig.favorExp),
			checkint(propertyConfig.favorLevel or 1),
			checkint(propertyConfig.vigour),
			------------ 外部属性参数 ------------
			ObjPFixedAttrStruct.New(),
			------------ 战斗信息 ------------
			1 == i,
			nil,
			#teamData[1] + 1,
			skillInfo,
			ArtifactTalentConstructorStruct.New(cardId, nil),
			self:GetCardEXAbilityInfoByCardId(cardId),
			petStruct,
			bookStruct,
			catGeneStruct,
			------------ 外貌信息 ------------
			checkint(skinIds[i] or CardUtils.GetCardSkinId(cardId))
		)

		table.insert(teamData[1], cardConstructorData)
	end

	return teamData
end
--[[
根据外部buff id集合获取战中全局buff技能集合
@params buffs table {
	{buffId = nil, level = nil}
}
@return skills list
--]]
function BattleConstructor:GetFormattedGlobalSkillsByBuffs(buffs)
	local skills = {}
	if nil ~= buffs then
		for i,v in ipairs(buffs) do
			local buffId = checkint(v.buffId)
			local buffConfig = CommonUtils.GetConfig('common', 'payBuff', buffId)
			if nil ~= buffConfig then
				local skillId = checkint(buffConfig.skillId)
				local skillConfig = CommonUtils.GetSkillConf(skillId)
				if nil ~= skillConfig then
					local skillData = GlobalEffectConstructStruct.New(
						buffId,
						skillId,
						checkint(v.level or 1)
					)
					table.insert(skills, skillData)
				end
			end
		end
	end
	return skills
end
--[[
根据外部skill id集合获取战中全局buff技能集合
@params skills table {
	skillId,
	skillId,
	skillId,
	...
}
return skills list
--]]
function BattleConstructor:GetFormattedGlobalSkillsBySkills(skills)
	local skills_ = {}

	if nil ~= skills then

		local skillId = nil
		local skillConfig = nil

		for _,v in ipairs(skills) do

			skillId = checkint(v)
			skillConfig = CommonUtils.GetSkillConf(skillId)

			if nil ~= skillConfig then
				local skillData = GlobalEffectConstructStruct.New(
					nil,
					skillId,
					1
				)
				table.insert(skills_, skillData)
			end


		end

	end
	return skills_
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

	if type(equipedSkill) == 'table' then
		for i,v in ipairs(equipedSkill) do
			if 0 ~= checkint(v) then
				table.insert(playerSkillInfo.activeSkill, {skillId = checkint(v)})
			end
		end
	end

	local skillId = nil
	local skillConfig = nil

	for i,v in ipairs(allSkill) do
		skillId = checkint(v)
		if 0 ~= skillId then
			skillConfig = CommonUtils.GetSkillConf(skillId) or {}
			if ConfigSkillType.SKILL_HALO == checkint(skillConfig.property) then
				-- 被动技能
				table.insert(playerSkillInfo.passiveSkill, {skillId = skillId})
			end
		end
	end

	return playerSkillInfo

end
---------------------------------------------------
-- data format other end --
---------------------------------------------------

---------------------------------------------------
-- select card data -> constructor data begin --
---------------------------------------------------
--[[
选卡界面的队伍数据 -> 战斗构造器数据
@params teamData list 队伍数据
@params maxTeamAmount int 最大队伍数量
@params attrInfo map {
	[ObjP] = {fieldName = '', ...},
	[ObjP] = {fieldName = '', ...},
	...
}
@return formattedTeamData list 格式化后的队伍数据
--]]
function BattleConstructor:ConvertSelectCards2FormattedTeamData(teamData, maxTeamAmount, attrInfo)
	local teamData_ = {}
	local cardAttrData = {}
	local id = nil
	local maxTeamAmount_ = maxTeamAmount or 1
	local cardData = nil

	for teamIndex = 1, maxTeamAmount_ do

		-- 整体的队伍信息
		teamData_[teamIndex] = {}
		cardAttrData[tostring(teamIndex)] = {}

		for i = 1, MAX_TEAM_MEMBER_AMOUNT do

			-- 构造卡牌数据
			if nil ~= teamData[teamIndex][i] and 0 ~= checkint(teamData[teamIndex][i].id) then

				id = checkint(teamData[teamIndex][i].id)
				teamData_[teamIndex][i] = id

				if nil ~= attrInfo then
					-- 查找对应卡牌的属性数据
					local attrData = self:GetCardStatusById(id, attrInfo)
					cardAttrData[tostring(teamIndex)][i] = attrData
				end

			end

		end

	end

	local formattedTeamData = self:GetFormattedTeamsDataByTeamsMyCardData(teamData_, cardAttrData)
	return formattedTeamData
end
--[[
根据数据库id获取卡牌继承状态
@params id int 卡牌数据库id
@params attrInfo map {
	[ObjP] = {fieldName = '', ...},
	[ObjP] = {fieldName = '', ...},
	...
}
@return attrData map {
	[ObjP] = {percent = 1, value = 0},
	[ObjP] = {percent = 1, value = 0},
	...
}
--]]
function BattleConstructor:GetCardStatusById(id, attrInfo)
	if nil == attrInfo then
		return nil
	end

	local attrData = {}
	local attr = nil
	local cardData = app.gameMgr:GetCardDataById(id)

	if nil ~= cardData and 0 ~= checkint(cardData.cardId) then

		for objp, info in pairs(attrInfo) do

			attr = cardData[info.fieldName]
			if nil ~= attr then
				attrData[objp] = {percent = checknumber(attr), value = -1}
			end

		end

	end
	return attrData
end
---------------------------------------------------
-- select card data -> constructor data end --
---------------------------------------------------

---------------------------------------------------
-- battle background begin --
---------------------------------------------------
--[[
根据战斗类型或关卡id获取背景图配置
@params questBattleType QuestBattleType 战斗类型
@params stageId int 关卡id
@params stageConfig table 处理一些特殊的类型 如 爬塔
@return _ list<BattleBackgroundStruct> 背景图配置
--]]
function BattleConstructor:GetBattleBackgroundConfig(questBattleType, stageId, stageConfig)
	if nil == questBattleType then return self:GetFormattedBgInfoByStageId(stageId) end

	local specialQuestBGConfig = {
		[QuestBattleType.ROBBERY] 				= {bgId = nil, bgScale = nil}, -- 打劫
		[QuestBattleType.TOWER] 				= {bgId = nil, bgScale = nil, functionName = 'GetTowerBattleBGByUnitConfig'}, -- 爬塔 --> 特殊处理
		[QuestBattleType.PVC] 					= {bgId = 28, bgScale = nil}, -- 竞技场
		[QuestBattleType.TAG_MATCH_3V3] 		= {bgId = 35, bgScale = nil}, -- 3v3
		[QuestBattleType.UNION_PVC] 			= {bgId = 28, bgScale = nil}, -- 竞技场
	}

	local bgConfig = specialQuestBGConfig[questBattleType]
	if nil ~= bgConfig then
		if nil ~= bgConfig.functionName then
			return self[bgConfig.functionName](self, stageConfig)
		else
			return {BattleBackgroundStruct.New(bgConfig.bgId, bgConfig.bgScale)}
		end
	else
		return self:GetFormattedBgInfoByStageId(stageId)
	end
end
--[[
处理爬塔的战斗背景图
@params unionConfig table 单元配置
@return _ list<BattleBackgroundStruct> 背景图配置
--]]
function BattleConstructor:GetTowerBattleBGByUnitConfig(unitConfig)
	if nil == unitConfig then return {BattleBackgroundStruct.New()} end

	return {
		BattleBackgroundStruct.New(
			unitConfig.backgroundId,
			1
		)
	}
end
--[[
获取转换结构后的背景图
@params stageId int 关卡id
@return bgInfo list 背景图信息
--]]
function BattleConstructor:GetFormattedBgInfoByStageId(stageId)
	local stageConfig = CommonUtils.GetQuestConf(stageId)

	local bgInfo = {}

	if nil == stageConfig then
		bgInfo[1] = BattleBackgroundStruct.New()
	else
		bgInfo[1] = BattleBackgroundStruct.New(
			checkint(stageConfig.backgroundId or 1),
			checkint(stageConfig.backgroundScale or 1)
			-- 36,
			-- 2
		)
	end

	return bgInfo
end
---------------------------------------------------
-- battle background end --
---------------------------------------------------


---------------------------------------------------
-- battle timeScale begin --
---------------------------------------------------
function BattleConstructor:GetCommonBattleTimeScale(questBattleType)
	local configSpeedConfig = {
		[QuestBattleType.CHAMPIONSHIP_PROMOTION] = 2,
	}

	local questTimeScale = configSpeedConfig[checkint(questBattleType)]
	if nil ~= questTimeScale then
		return questTimeScale
	end

	return gameMgr:GetUserInfo().localBattleAccelerate
end
---------------------------------------------------
-- battle timeScale end --
---------------------------------------------------


---------------------------------------------------
-- battle complete begin --
---------------------------------------------------
--[[
根据战斗类型获取转换结构后的过关条件
@params questBattleType QuestBattleType 战斗类型
@params stageId int 关卡id
@params enemyWave int 敌军波数
@return _ list<StageCompleteSturct> 过关条件信息
--]]
function BattleConstructor:GetBattleCompleteConfig(questBattleType, stageId, enemyWave)
	if nil == questBattleType then return self:GetFormattedStageCompleteInfoByStageId(stageId) end

	local specialQuestCompleteConfig = {
		[QuestBattleType.ROBBERY] 			     = {useEnemyWave = true}, -- 打劫
		[QuestBattleType.TOWER] 			     = {useEnemyWave = true}, -- 爬塔
		[QuestBattleType.PVC] 				     = {useEnemyWave = true}, -- 竞技场
		[QuestBattleType.UNION_PARTY] 		     = {functionName = 'GetUnionPartyCompleteInfo'}, -- 工会party
		[QuestBattleType.TAG_MATCH_3V3] 	     = {functionName = 'Get3v3StageCompleteInfo'}, -- 车轮战
		[QuestBattleType.UNION_PVC] 		     = {useEnemyWave = true}, -- 工会战人打人
		[QuestBattleType.ULTIMATE_BATTLE] 	     = {useEnemyWave = true}, -- 巅峰对决
		[QuestBattleType.SKIN_CARNIVAL] 	     = {useEnemyWave = true}, -- 皮肤嘉年华
		[QuestBattleType.FRIEND_BATTLE] 	     = {useEnemyWave = true}, -- 好友切磋
		[QuestBattleType.LUNA_TOWER] 	         = {useEnemyWave = true}, -- luna塔
		[QuestBattleType.CHAMPIONSHIP_PROMOTION] = {useEnemyWave = true}, -- 武道会-晋级赛
	}

	local completeConfig = specialQuestCompleteConfig[questBattleType]
	if nil ~= completeConfig then

		if nil ~= completeConfig.functionName then

			return self[completeConfig.functionName](self, stageId, enemyWave)

		elseif true == completeConfig.useEnemyWave then

			local stageCompleteInfo = {}
			for wave = 1, enemyWave do
				stageCompleteInfo[wave] = StageCompleteSturct.New()
			end
			return stageCompleteInfo

		end

	else
		return self:GetFormattedStageCompleteInfoByStageId(stageId)
	end
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
获取3v3的过关条件
@return stageCompleteInfo list 过关条件信息
--]]
function BattleConstructor:Get3v3StageCompleteInfo()
	-- 3v3在初始化时只创建一波过关条件 之后在战斗中动态生成
	local scinfo = StageCompleteSturct.New()
	scinfo.completeType = ConfigStageCompleteType.TAG_MATCH
	return {scinfo}
end
--[[
获取工会party的过关条件
@params stageId int 关卡id
@params totalWave int 总波数
--]]
function BattleConstructor:GetUnionPartyCompleteInfo(stageId, totalWave)
	local stageConfig = CommonUtils.GetQuestConf(stageId)

	local stageCompleteInfo = {}

	if nil == stageConfig then
		stageCompleteInfo[1] = StageCompleteSturct.New()
	else
		for i = 1, totalWave do
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
---------------------------------------------------
-- battle complete end --
---------------------------------------------------

---------------------------------------------------
-- battle time begin --
---------------------------------------------------
--[[
根据战斗类型获取战斗时间
@params questBattleType QuestBattleType 战斗类型
@params stageId int 关卡id
--]]
function BattleConstructor:GetBattleTotalTime(questBattleType, stageId)
	local config = self:GetBattleConfigByQuestBattleType(questBattleType)

	if nil ~= config and 0 < checkint(config.time) then
		return checkint(config.time)
	else
		local stageConfig = CommonUtils.GetQuestConf(stageId)
		if nil ~= stageConfig then
			return checkint(stageConfig.time)
		else
			return 0
		end
	end
end
---------------------------------------------------
-- battle time end --
---------------------------------------------------

---------------------------------------------------
-- battle parameter begin --
---------------------------------------------------
--[[
根据战斗类型获取是否开启等级碾压
@params questBattleType QuestBattleType 战斗类型
@return _ bool 是否开启等级碾压
--]]
function BattleConstructor:OpenLevelRollingByQuestBattleType(questBattleType)
	local config = self:GetBattleConfigByQuestBattleType(questBattleType)

	if nil ~= config then
		return checkint(config.levelRolling) == 1
	else
		return true
	end
end
--[[
根据战斗类型获取战斗物体全局属性修正
@params questBattleType QuestBattleType 战斗类型
@params isEnemy bool 是否是敌军
@return _ ObjectPropertyFixedAttrStruct 属性修正数据
--]]
function BattleConstructor:GetObjPFixedAttrByQuestBattleType(questBattleType, isEnemy)
	local config = self:GetBattleConfigByQuestBattleType(questBattleType)

	if nil ~= config then

		------------ 计算修正的属性参数 ------------
		local pattr = {
			[ObjP.ATTACK] = nil,
			[ObjP.DEFENCE] = nil,
			[ObjP.HP] = nil,
			[ObjP.CRITRATE] = nil,
			[ObjP.CRITDAMAGE] = nil,
			[ObjP.ATTACKRATE] = nil
		}

		if true == isEnemy then

			if nil ~= config.enemyObjpA then
				for objp, pvalue in pairs(config.enemyObjpA) do
					pattr[checkint(objp)] = checknumber(pvalue)
				end
			end

		else

			if nil ~= config.friendObjpA then
				for objp, pvalue in pairs(config.friendObjpA) do
					pattr[checkint(objp)] = checknumber(pvalue)
				end
			end

		end
		------------ 计算修正的属性参数 ------------

		------------ 计算修正的系数系数 ------------
		local ppattr = {}

		if true == isEnemy then

			if nil ~= config.enemyObjppA then
				for objpp, ppvalue in pairs(config.enemyObjppA) do
					ppattr[checkint(objpp)] = checknumber(ppvalue)
				end
			end

		else

			if nil ~= config.friendObjppA then
				for objpp, ppvalue in pairs(config.friendObjppA) do
					ppattr[checkint(objpp)] = checknumber(ppvalue)
				end
			end

		end
		------------ 计算修正的系数系数 ------------

		return ObjectPropertyFixedAttrStruct.New(
			pattr[ObjP.HP], pattr[ObjP.ATTACK], pattr[ObjP.DEFENCE], pattr[ObjP.CRITRATE], pattr[ObjP.CRITDAMAGE], pattr[ObjP.ATTACKRATE],
			ppattr
		)

	else
		return ObjectPropertyFixedAttrStruct.New()
	end
end
--[[
根据关卡id和工会神兽等级获取工会神兽强度系数配置
@params stageId int 关卡id
@params level int 等级
@return _ config 工会神兽强度系数配置
--]]
function BattleConstructor:GetUnionWarsBossIntensity(stageId, level)
	local diffAttrConfigs = CommonUtils.GetConfig('union', UnionConfigParser.TYPE.WARS_BOSS_DIFF_ATTR, stageId)
	if nil ~= diffAttrConfigs then
		local diffAttrConfig = diffAttrConfigs[tostring(level)]
		if nil ~= diffAttrConfig then
			return MonsterIntensityAttrStruct.New(diffAttrConfig)
		end
	end
	print('warning!!!!!!!!! --> cannot find union wars boss diff config', stageId, level)
	return MonsterIntensityAttrStruct.New()
end
--[[
根据战斗类型获取战斗类型的配置信息
@params questBattleType QuestBattleType
@return _ table
--]]
function BattleConstructor:GetBattleConfigByQuestBattleType(questBattleType)
	return CommonUtils.GetConfig('common', 'specialBattle', questBattleType)
end
--[[
获取天气配置
@params questBattleType QuestBattleType 战斗类型
@params stageId int 关卡id
@return _ config 天气信息
--]]
function BattleConstructor:GetBattleWeatherInfo(questBattleType, stageId)
	local config = self:GetBattleConfigByQuestBattleType(questBattleType)

	if nil ~= config and nil ~= config.weatherId then
		return config.weatherId
	else
		local stageConfig = CommonUtils.GetQuestConf(stageId)
		if nil ~= stageConfig then
			return stageConfig.weatherId
		else
			return nil
		end
	end
end
--[[
获取转阶段信息
@params questBattleType QuestBattleType 战斗类型
@params stageId int 关卡id
@return _ config 天气信息
--]]
function BattleConstructor:GetBattleBossActionInfo(questBattleType, stageId)
	local config = self:GetBattleConfigByQuestBattleType(questBattleType)

	if nil ~= config and nil ~= config.actionId then
		return config.actionId
	else
		local stageConfig = CommonUtils.GetQuestConf(stageId)
		if nil ~= stageConfig then
			return stageConfig.actionId
		else
			return nil
		end
	end
end
--[[
获取三星条件
@params questBattleType QuestBattleType 战斗类型
@params stageId int 关卡id
@return _ config 三星条件
--]]
function BattleConstructor:GetBattleAllCleanInfo(questBattleType, stageId)
	local config = self:GetBattleConfigByQuestBattleType(questBattleType)

	if nil ~= config and nil ~= config.allClean then
		return config.allClean
	else
		local stageConfig = CommonUtils.GetQuestConf(stageId)
		if nil ~= stageConfig then
			return stageConfig.allClean
		else
			return nil
		end
	end
end
--[[
获取隐藏的功能模块
@params questBattleType QuestBattleType 战斗类型
@params stageId int 关卡id
@return _ config 隐藏的功能模块
--]]
function BattleConstructor:GetBattleHideModuleInfo(questBattleType, stageId)
	local config = self:GetBattleConfigByQuestBattleType(questBattleType)

	if nil ~= config and nil ~= config.hiddenModule then
		return config.hiddenModule
	else
		local stageConfig = CommonUtils.GetQuestConf(stageId)
		if nil ~= stageConfig then
			return stageConfig.hiddenModule
		else
			return nil
		end
	end
end
--[[
获取是否 己方能使用连携技
@params questBattleType QuestBattleType 战斗类型
@params stageId int 关卡id
@return _ bool 是否能使用连携技
--]]
function BattleConstructor:GetEnableConnect(questBattleType, stageId)
	local config = self:GetBattleConfigByQuestBattleType(questBattleType)

	if nil ~= config and nil ~= config.enableConnect then
		return checkint(config.enableConnect) == 1
	else
		return true
	end
end
--[[
获取是否 己方自动释放连携技
@params questBattleType QuestBattleType 战斗类型
@params stageId int 关卡id
@return _ bool 是否自动连携技
--]]
function BattleConstructor:GetAutoConnect(questBattleType, stageId)
	local config = self:GetBattleConfigByQuestBattleType(questBattleType)

	if nil ~= config and nil ~= config.autoConnect then
		return checkint(config.autoConnect) == 1
	else
		return false
	end
end
--[[
获取是否 敌方能使用连携技
@params questBattleType QuestBattleType 战斗类型
@params stageId int 关卡id
@return _ bool 是否能使用连携技
--]]
function BattleConstructor:GetEnemyEnableConnect(questBattleType, stageId)
	local config = self:GetBattleConfigByQuestBattleType(questBattleType)
	
	if nil ~= config and nil ~= config.enableConnect then
		return checkint(config.enemyEnableConnect) == 1
	else
		return false
	end
end
--[[
获取是否 敌方自动释放连携技
@params questBattleType QuestBattleType 战斗类型
@params stageId int 关卡id
@return _ bool 是否自动连携技
--]]
function BattleConstructor:GetEnemyAutoConnect(questBattleType, stageId)
	local config = self:GetBattleConfigByQuestBattleType(questBattleType)

	if nil ~= config and nil ~= config.autoConnect then
		return checkint(config.enemyAutoConnect) == 1
	else
		return false
	end
end
---------------------------------------------------
-- battle parameter end --
---------------------------------------------------

---------------------------------------------------
-- json data -> struct begin --
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
@params tbl 构造器数据
@return result list<ObjectAbilityRelationStruct>
--]]
function BattleConstructor:Data2StructObjectAbilityRelationStructList(tbl)
	if nil == tbl then return nil end

	local result = {}
	for _, data in ipairs(tbl) do
		local struct = self:Data2StructCommon(data, ObjectAbilityRelationStruct)
		table.insert(result, struct)
	end
	return result
end
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
		cardConstructorData = self:GetAFormattedCardStructByCommonCardData(cardData)
	end

	return cardConstructorData
end
--[[
根据json转换主角技数据
@params playerSkillJson json
@return _ map
--]]
function BattleConstructor:ConvertPlayerSkillByJson(playerSkillJson)
	if nil == playerSkillJson then return nil end
	local playerSkillData = json.decode(playerSkillJson)
	return self:GetFormattedPlayerSkill(playerSkillData.passiveSkill, playerSkillJson.activeSkill)
end
---------------------------------------------------
-- json data -> struct end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
获取战斗构造数据
@return _ BattleConstructorStruct 战斗构造数据
--]]
function BattleConstructor:GetBattleConstructData()
	return self.battleConstructorData
end
--[[
获取与服务器交互的命令信息
--]]
function BattleConstructor:GetServerCommand()
	return self.battleConstructorData.serverCommand
end
--[[
获取来回mediator信息
--]]
function BattleConstructor:GetFromToData()
	return self.battleConstructorData.fromtoData
end
--[[
获取关卡id
--]]
function BattleConstructor:GetStageId()
	return self.battleConstructorData.stageId
end
--[[
获取进入战斗请求的参数
@return _ table
--]]
function BattleConstructor:GetEnterBattleRequestData()
	return self:GetServerCommand().enterBattleRequestData
end
--[[
获取买活次数
@return _ int 买活次数
--]]
function BattleConstructor:GetBuyRevivalTime()
	return self.battleConstructorData.buyRevivalTime
end
--[[
刷新敌方阵容数据
@params enemyFormationData FormationStruct 敌方阵容数据
--]]
function BattleConstructor:UpdateEnemyFormation(enemyFormationData)
	self.battleConstructorData.enemyFormation = enemyFormationData
end
--[[
随机数配置
--]]
function BattleConstructor:GetBattleRandomConfig()
	return self.battleConstructorData.randomConfig
end
function BattleConstructor:SetBattleRandomConfig(randomConfig)
	self.battleConstructorData.randomConfig = randomConfig
end
--[[
参战的玩家信息
@params playersMap map 玩家信息集
--]]
function BattleConstructor:SetMemberData(playersMap)
	self.playersData = playersMap
end
function BattleConstructor:GetMemberData()
	return self.playersData
end
--[[
工会打神兽的id
--]]
function BattleConstructor:GetUnionBeastId()
	return self.unionBeastId
end
function BattleConstructor:SetUnionBeastId(id)
	self.unionBeastId = id
end
--[[
根据服务器返回的数据获取格式化后的卡牌能力增强信息
@params serverAbilityData list<map> {
	{essentialCards = list, inessentialCards = list, activeCards = list, activeSkills = list},
	{essentialCards = list, inessentialCards = list, activeCards = list, activeSkills = list},
	{essentialCards = list, inessentialCards = list, activeCards = list, activeSkills = list}
}
@return result list<ObjectAbilityRelationStruct> 格式化后的数据
--]]
function BattleConstructor:GetFormattedAbilityRelationInfo(serverAbilityData)
	if nil == serverAbilityData then return nil end

	local result = {}

	for _, abilityData in ipairs(serverAbilityData) do
		-- 必要的卡牌
		local essentialCards = {}
		if nil ~= abilityData.essentialCards then
			for _, cardId in ipairs(abilityData.essentialCards) do
				essentialCards[tostring(cardId)] = true
			end
		end

		-- 非必要的卡牌
		local inessentialCards = {}
		if nil ~= abilityData.inessentialCards then
			for _, cardId in ipairs(abilityData.inessentialCards) do
				inessentialCards[tostring(cardId)] = true
			end
		end

		-- 能力激活的卡牌
		local activeCards = {}
		if nil ~= abilityData.activeCards then
			for _, cardId in ipairs(abilityData.activeCards) do
				activeCards[tostring(cardId)] = true
			end
		end

		-- 激活的技能
		local activeSkills = {}
		if nil ~= abilityData.activeSkills then
			for _, skillId in ipairs(abilityData.activeSkills) do
				activeSkills[tostring(skillId)] = {skillId = checkint(skillId)}
			end
		end

		local abilityInfo = ObjectAbilityRelationStruct.New(
			essentialCards, inessentialCards, activeCards,
			activeSkills
		)

		table.insert(result, abilityInfo)

	end

	return result
end
--[[
根据敌友性获取阵容信息
@params isEnemy bool 敌友性
@return _ 阵容信息 全队
--]]
function BattleConstructor:GetTeamsData(isEnemy)
	if nil == self:GetBattleConstructData() then
		print('!!!请先初始化构造器!!!')
		return nil
	end
	if isEnemy then
		if nil ~= self:GetBattleConstructData().enemyFormation then
			return self:GetBattleConstructData().enemyFormation.members
		end
	else
		if nil ~= self:GetBattleConstructData().friendFormation then
			return self:GetBattleConstructData().friendFormation.members
		end
	end

	return nil
end
--[[
根据敌友性获取主角技信息
@params isEnemy bool 敌友性
@return _ 主角技信息
--]]
function BattleConstructor:GetPlayerSkilInfo(isEnemy)
	if nil == self:GetBattleConstructData() then
		print('!!!请先初始化构造器!!!')
		return nil
	end
	if isEnemy then
		if nil ~= self:GetBattleConstructData().enemyFormation then
			return self:GetBattleConstructData().enemyFormation.playerSkillInfo
		end
	else
		if nil ~= self:GetBattleConstructData().friendFormation then
			return self:GetBattleConstructData().friendFormation.playerSkillInfo
		end
	end

	return nil
end
--[[
是否是replay
@return _ bool
--]]
function BattleConstructor:IsReplay()
	return self:GetBattleConstructData().isReplay
end
--[[
是否是战报生成器
@return _ bool
--]]
function BattleConstructor:IsCalculator()
	return self:GetBattleConstructData().isCalculator
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

---------------------------------------------------
-- calc begin --
---------------------------------------------------
--[[
根据checkin卡牌数据计算本次战斗会加载的资源数据
@params stageId int 关卡id
@params questBattleType QuestBattleType 战斗类型
@params oneTeamData list 队伍数据
@params checkConnectCI bool 是否检查连携技ci
@return loadResStr string 加载的资源数据 table2string
--]]
function BattleConstructor:CalcLoadSpineResOneTeam(stageId, questBattleType, oneTeamData, checkConnectCI)
	local loadRes = {}
	local loadResStr = nil

	local avatarSpine = {}
	local effectSpine = {}
	local hurtSpine = {}
	local needLoadBossWeak = false
	local needLoadBossCutin = false
	local needLoadCardCutin = false

	local id = nil
	local cardData = nil
	local cardId = nil
	local skinId = nil
	local cardConfig = nil
	local skinConfig = nil

	-- 遍历队伍信息
	for teamIdx = 1, MAX_TEAM_MEMBER_AMOUNT do
		
		if nil ~= oneTeamData[teamIdx] then

			id = checkint(oneTeamData[teamIdx].id)

			if 0 ~= id then
				cardData = app.gameMgr:GetCardDataById(id)
			else
				skinId     = checkint(oneTeamData[teamIdx].skinId)
				skinConfig = CardUtils.GetCardSkinConfig(skinId)
				cardData   = {
					cardId        = checkint(skinConfig.cardId),
					defaultSkinId = skinId,
				}
			end
			
			if nil ~= cardData and 0 ~= checkint(cardData.cardId) then

				cardId = checkint(cardData.cardId)

				------------ 计算这张卡需要加载的资源 ------------
				local extraNeedLoad = BRUtils.ConvertNeedLoadResourcesByCardId(
					cardId,
					checkint(cardData.defaultSkinId),
					self:GetCardEXAbilityInfoByCardId(cardId),
					avatarSpine, effectSpine, hurtSpine
				)

				if true == extraNeedLoad.needLoadBossWeak then
					needLoadBossWeak = true
				end
				if true == extraNeedLoad.needLoadBossCutin then
					needLoadBossCutin = true
				end
				------------ 计算这张卡需要加载的资源 ------------

				------------ 检测连携技是否可用加载卡牌ci特效动画 ------------
				if true == checkConnectCI and false == needLoadCardCutin then
					cardConfig = CardUtils.GetCardConfig(cardId)
					for i,v in ipairs(cardConfig.skill) do
						skillConfig = CommonUtils.GetSkillConf(checkint(v)) or {}
						if nil ~= skillConfig then
							if ConfigSkillType.SKILL_CONNECT == checkint(skillConfig.property) then
								if app.cardMgr.IsConnectSkillEnable(cardId, oneTeamData, checkint(v)) then
									needLoadCardCutin = true
									break
								end
							end
						end
					end
				end
				------------ 检测连携技是否可用加载卡牌ci特效动画 ------------

			end

		end
		
	end

	-- 卡牌连携技ci 默认资源存在
	if needLoadCardCutin then
		for _, value in ipairs(BRUtils.GetCardCutinSceneConfig()) do
			loadRes[value.cacheName] = true
		end
	end

	-- 转换数据
	local list = {avatarSpine, effectSpine, hurtSpine}
	for _, value in ipairs(list) do
		for _, loadSpineInfo in ipairs(value) do
			if nil == loadRes[tostring(loadSpineInfo.cacheName)] then

				if true == BRUtils.IsSpineResourceValidByFullPath(loadSpineInfo.path) then
					loadRes[tostring(loadSpineInfo.cacheName)] = true
				else
					print('!!!警告!!!根据配表中的特效数据获取本地资源时资源不存在!!!')
				end

			end
		end
	end

	local resultStr = {[1] = loadRes}

	loadResStr = Table2StringNoMeta(resultStr)
	return loadResStr
end

--[[
根据构造器转换后的数据计算本次战斗会加载的资源数据 有几队算几队
@params isEnemy bool 敌友性
@params checkConnectCI bool 是否检查连携技ci
@return loadResStrMap map<teamIndex, string> 加载的资源数据 table2string
--]]
function BattleConstructor:CalcLoadSpineRes(isEnemy, checkConnectCI)
	local loadResStrMap = {}
	
	local avatarSpine = {}
	local effectSpine = {}
	local hurtSpine = {}
	local needLoadBossWeak = false
	local needLoadBossCutin = false
	local needLoadCardCutin = false

	local id = nil
	local cardData = nil
	local objectConfigId = nil
	local cardConfig = nil

	local teamsData = self:GetTeamsData(isEnemy)
	if nil ~= teamsData then
		local teamAmount = table.nums(teamsData)
		local teamData = nil

		for teamIndex = 1, teamAmount do

			-- 分队重置数据
			avatarSpine = {}
			effectSpine = {}
			hurtSpine = {}
			needLoadBossWeak = false
			needLoadBossCutin = false
			needLoadCardCutin = false

			teamData = teamsData[teamIndex]
			if nil ~= teamData then
				for _, cardData in ipairs(teamData) do

					objectConfigId = cardData:GetObjectConfigId()

					------------ 计算这张卡需要加载的资源 ------------
					local extraNeedLoad = BRUtils.ConvertNeedLoadResourcesByCardId(
						objectConfigId,
						checkint(cardData.skinId),
						cardData.exAbilityData,
						avatarSpine, effectSpine, hurtSpine
					)

					if true == extraNeedLoad.needLoadBossWeak then
						needLoadBossWeak = true
					end
					if true == extraNeedLoad.needLoadBossCutin then
						needLoadBossCutin = true
					end
					------------ 计算这张卡需要加载的资源 ------------

					------------ 检测连携技是否可用加载卡牌ci特效动画 ------------
					if true == checkConnectCI and false == needLoadCardCutin then
						cardConfig = CardUtils.GetCardConfig(objectConfigId)
						for i,v in ipairs(cardConfig.skill) do
							skillConfig = CommonUtils.GetSkillConf(checkint(v)) or {}
							if nil ~= skillConfig then
								if ConfigSkillType.SKILL_CONNECT == checkint(skillConfig.property) then
									if CardUtils.IsConnectSkillEnable(objectConfigId, teamData, checkint(v)) then
										needLoadCardCutin = true
										break
									end
								end
							end
						end
					end
					------------ 检测连携技是否可用加载卡牌ci特效动画 ------------

				end

				local loadResOneTeam = {}
				-- 卡牌连携技ci 默认资源存在
				if needLoadCardCutin then
					for _, value in ipairs(BRUtils.GetCardCutinSceneConfig()) do
						loadResOneTeam[value.cacheName] = true
					end
				end

				-- 转换数据
				local list = {avatarSpine, effectSpine, hurtSpine}
				for _, value in ipairs(list) do
					for _, loadSpineInfo in ipairs(value) do
						if nil == loadResOneTeam[tostring(loadSpineInfo.cacheName)] then

							if true == BRUtils.IsSpineResourceValidByFullPath(loadSpineInfo.path) then
								loadResOneTeam[tostring(loadSpineInfo.cacheName)] = true
							else
								print('!!!警告!!!根据配表中的特效数据获取本地资源时资源不存在!!!')
							end

						end
					end
				end

				local loadResStrOneTeam = Table2StringNoMeta(loadResOneTeam)
				loadResStrMap[tostring(teamIndex)] = loadResStrOneTeam

			end

		end
	end

	return loadResStrMap
end

--[[
根据构造器转换后的数据计算传给服务器的constructorJson
@param luaUse bool 是否是供lua使用 是 返回table(外部调用不用传) 否 返回约定好的string
@return constructorData Table2StringNoMeta 客户端转换的lua table 字符串
--]]
function BattleConstructor:CalcRecordConstructData(luaUse)
	local battleConstructorData = self:GetBattleConstructData()
	if nil == battleConstructorData then
		print('!!!请先初始化构造器!!!')
		return nil
	end

	local constructorData = {
		questBattleType = battleConstructorData.questBattleType,
		randomConfig = battleConstructorData.randomConfig,
		gameTimeScale = battleConstructorData.gameTimeScale,
		openLevelRolling = battleConstructorData.levelRolling,
		abilityRelationInfo = battleConstructorData.abilityRelationInfo,
		globalEffects = battleConstructorData.globalEffects,
		enableConnect = battleConstructorData.enableConnect,
		autoConnect = battleConstructorData.autoConnect,
		enemyEnableConnect = battleConstructorData.enemyEnableConnect,
		enemyAutoConnect = battleConstructorData.enemyAutoConnect,
		canRechallenge = battleConstructorData.canRechallenge,
		rechallengeTime = battleConstructorData.rechallengeTime,
		canBuyCheat = battleConstructorData.canBuyCheat,
		buyRevivalTime = battleConstructorData.buyRevivalTime,
		buyRevivalTimeMax = battleConstructorData.buyRevivalTimeMax,
		friendPlayerSkill = self:GetPlayerSkilInfo(false),
		enemyPlayerSkill = self:GetPlayerSkilInfo(true),
		time = battleConstructorData.time,
		weather = battleConstructorData.weather,
		phaseChangeDatas = battleConstructorData.phaseChangeDatas
	}

	if true == luaUse then
		return constructorData
	else
		return Table2StringNoMeta(constructorData)
	end

	return constructorData
end
---------------------------------------------------
-- calc end --
---------------------------------------------------

---------------------------------------------------
-- debug begin --
---------------------------------------------------
--[[
根据debug战斗工具初始化构造器数据
@params stageId int 关卡id
@params teamData table 队伍信息
@params playerSkillData table 主角技数据
--]]
function BattleConstructor:InitByDebugBattle(stageId, teamData, playerSkillData)
	local activePlayerSkills = {}
	for i = 1, 2 do
		table.insert(activePlayerSkills, checkint(playerSkillData.active[tostring(i)]))
	end

	------------ 处理友方阵容信息 ------------
	local formattedFriendTeamData = self:GetFormattedTeamDataByDebugTeamData(teamData)
	local formattedFriendPlayerSkillData = self:GetFormattedPlayerSkill({80001}, activePlayerSkills)

	local friendFormationData = FormationStruct.New(
		1,
		formattedFriendTeamData,
		formattedFriendPlayerSkillData,
		ObjectPropertyFixedAttrStruct.New()
	)
	------------ 处理友方阵容信息 ------------

	------------ 处理敌方阵容信息 ------------
	local formattedEnemyTeamData = self:GetCommonEnemyTeamDataByStageId(stageId)
	local formattedEnemyPlayerSkillData = nil

	local enemyFormationData = FormationStruct.New(
		stageId,
		formattedEnemyTeamData,
		formattedEnemyPlayerSkillData,
		ObjectPropertyFixedAttrStruct.New()
	)
	------------ 处理敌方阵容信息 ------------

	------------ 处理每一波的过关条件 ------------
	local stageCompleteInfo = self:GetBattleCompleteConfig(nil, stageId)
	------------ 处理每一波的过关条件 ------------

	------------ 背景图 ------------
	local bgInfo = self:GetFormattedBgInfoByStageId(stageId)
	------------ 背景图 ------------

	------------ 整合数据结构 ------------
	local stageConfig = CommonUtils.GetQuestConf(stageId)

	local randomConfig = BattleRandomConfigStruct.New()

	local battleConstructorData = BattleConstructorStruct.New(
		------------ 战斗基本配置 ------------
		stageId,
		CommonUtils.GetQuestBattleByQuestId(stageId),
		randomConfig,
		2,
		checkint(stageConfig.time),
		#formattedEnemyTeamData,
		checkint(stageConfig.settlementType),
		stageCompleteInfo,
		false,
		false,
		------------ 战斗数值配置 ------------
		true,
		------------ 战斗环境配置 ------------
		stageConfig.weatherId,
		stageConfig.actionId,
		nil,
		nil,
		true,
		false,
		false,
		false,
		------------ 其他信息 ------------
		stageConfig.allClean,
		ValueConstants.V_NORMAL == checkint(stageConfig.repeatChallenge),
		-1,
		false,
		0,
		0,
		------------ 战斗场景配置 ------------
		bgInfo,
		nil,
		------------ 友方阵容信息 ------------
		friendFormationData,
		------------ 敌方阵容信息 ------------
		enemyFormationData,
		------------ 头尾服务器交互命令 ------------
		nil,
		------------ 头尾跳转信息 ------------
		nil
	)

	self.battleConstructorData = battleConstructorData
	------------ 整合数据结构 ------------
end
--[[
初始化3v3车轮战构造器数据
@params friendTeams list 友方阵容
{
	[1] = {
		id,
		id,
		id,
		id,
		id
	},
	[2] = {
		id,
		id,
		id,
		id,
		id
	},
	[3] = {
		id,
		id,
		id,
		id,
		id
	}
}
@params enemyTeams list 敌方阵容
@params friendAllSkills list 友方主角技
@params enemyAllSkills list 敌方主角技
@params serverCommand BattleNetworkCommandStruct 与服务器交互的命令信息
@params fromtoData BattleMediatorsConnectStruct 跳转信息
--]]
function BattleConstructor:InitDataByDebugTagMatchThreeTeams(friendTeams, enemyTeams, friendAllSkills, enemyAllSkills, serverCommand, fromtoData)
	-- debug --
	-- friendAllSkills = {80001, 80041}
	-- enemyAllSkills = {80001}
	-- debug --

	------------ 处理友方阵容信息 ------------
	local formattedFriendTeamData = self:GetFormattedTeamsDataByTeamsCardData(friendTeams)
	local formattedFriendPlayerSkillData = self:GetFormattedPlayerSkill(friendAllSkills, {})

	local friendFormationData = FormationStruct.New(
		nil,
		formattedFriendTeamData,
		formattedFriendPlayerSkillData,
		ObjectPropertyFixedAttrStruct.New(5)
	)
	------------ 处理友方阵容信息 ------------

	------------ 处理敌方阵容信息 ------------
	local formattedEnemyTeamData = self:GetFormattedTeamsDataByTeamsCardData(enemyTeams)
	local formattedEnemyPlayerSkillData = self:GetFormattedPlayerSkill(enemyAllSkills, {})
	local enemyFormationData = FormationStruct.New(
		nil,
		formattedEnemyTeamData,
		formattedEnemyPlayerSkillData,
		ObjectPropertyFixedAttrStruct.New(5)
	)
	------------ 处理敌方阵容信息 ------------

	------------ 车轮战初始化只创建一波 之后的动态创建 ------------
	local stageCompleteInfo = self:GetBattleCompleteConfig(QuestBattleType.TAG_MATCH_3V3)
	------------ 车轮战初始化只创建一波 之后的动态创建 ------------

	local randomConfig = BattleRandomConfigStruct.New()

	local battleConstructorData = BattleConstructorStruct.New(
		------------ 战斗基本配置 ------------
		nil,
		QuestBattleType.TAG_MATCH_3V3,
		randomConfig,
		2,
		500,
		1,
		ConfigBattleResultType.NO_DROP,
		stageCompleteInfo,
		false,
		false,
		------------ 战斗数值配置 ------------
		false,
		------------ 战斗环境配置 ------------
		{},
		{},
		nil,
		nil,
		true,
		true,
		false,
		false,
		------------ 其他信息 ------------
		nil,
		false,
		0,
		false,
		0,
		0,
		------------ 战斗场景配置 ------------
		self:GetBattleBackgroundConfig(QuestBattleType.TAG_MATCH_3V3),
		nil,
		------------ 友方阵容信息 ------------
		friendFormationData,
		------------ 敌方阵容信息 ------------
		enemyFormationData,
		------------ 头尾服务器交互命令 ------------
		serverCommand,
		------------ 头尾跳转信息 ------------
		fromtoData
	)

	self.battleConstructorData = battleConstructorData
end
--[[
根据debug战斗工具的阵容数据获取格式化后的卡牌阵容数据
@params debugTeamData table 阵容数据
--]]
function BattleConstructor:GetFormattedTeamDataByDebugTeamData(debugTeamData)
	local teamData = {
		[1]  = {}
	}

	local sortKey = sortByKey(debugTeamData)
	local cardData = nil
	for i,v in ipairs(sortKey) do
		cardData = debugTeamData[v]

		local petStruct = nil
		if nil ~= cardData.pets and 0 < #cardData.pets then
			local petData = cardData.pets[1]

			local petId = checkint(petData.petId)
			local activeExclusive = false
			local petConfig = petMgr.GetPetConfig(petId)
			if nil ~= petConfig.exclusiveCard then
				for _, ecid in ipairs(petConfig.exclusiveCard) do
					if checkint(ecid) == checkint(cardData.cardId) then
						activeExclusive = true
						break
					end
				end
			end

			petStruct = PetConstructorStruct.New(
				petId,
				checkint(petData.level),
				checkint(petData.breakLevel),
				checkint(petData.character),
				activeExclusive,
				petData.petp
			)
		end

		-- 构造传参用的数据结构
		local cardConstructorData = CardObjConstructorStruct.New(
			------------ 卡牌基本信息 ------------
			checkint(cardData.cardId),
			checkint(cardData.exp),
			checkint(cardData.level),
			checkint(cardData.breakLevel),
			checkint(cardData.favorability),
			checkint(cardData.favorLevel),
			checkint(cardData.vigour),
			------------ 外部属性参数 ------------
			ObjPFixedAttrStruct.New(),
			------------ 战斗信息 ------------
			1 == i,
			nil,
			#teamData[1] + 1,
			cardData.skills,
			ArtifactTalentConstructorStruct.New(checkint(cardData.cardId), cardData.artifactTalent),
			self:GetCardEXAbilityInfoByCardId(checkint(cardData.cardId)),
			petStruct,
			BookConstructorStruct.New(checkint(cardData.cardId), cardData.bookLevel),
			CatGeneConstructorStruct.New(cardData.equippedHouseCatGene),
			------------ 外貌信息 ------------
			checkint(cardData.skinId)
		)

		table.insert(teamData[1], cardConstructorData)
	end

	return teamData
end
---------------------------------------------------
-- debug end --
---------------------------------------------------

return BattleConstructor

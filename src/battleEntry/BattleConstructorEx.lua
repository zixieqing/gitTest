--[[
战斗构造器改 构造一场战斗需要的数据 拥有更通用的一些接口
--]]
local BattleConstructor = require('battleEntry.BattleConstructor')

------------ import ------------
require('battleEntry.BattleGlobalDefines')
-- 战斗字符串工具
__Require('battle.util.BStringUtils')
------------ import ------------

------------ define ------------
local TowerConfigParser = require('Game.Datas.Parser.TowerConfigParser')
local UnionConfigParser = require('Game.Datas.Parser.UnionConfigParser')
------------ define ------------

local BattleConstructorEx = class('BattleConstructorEx', BattleConstructor)

--[[
constructor
--]]
function BattleConstructorEx:ctor( ... )
	BattleConstructor.ctor(self, ...)
end

---------------------------------------------------
-- init logic begin --
---------------------------------------------------

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
function BattleConstructorEx:InitByCommonData(
		stageId, questBattleType, settlementType,
		formattedFriendTeamData, formattedEnemyTeamData,
		friendEquipedSkills, friendAllSkills, enemyEquipedSkills, enemyAllSkills,
		skills, abilityData,
		buyRevivalTime, buyRevivalTimeMax, isOpenRevival,
		randomseed, isReplay,
		serverCommand, fromtoData
	)

	BattleConstructor.InitByCommonData(self,
		stageId, questBattleType, settlementType,
		formattedFriendTeamData, formattedEnemyTeamData,
		friendEquipedSkills, friendAllSkills, enemyEquipedSkills, enemyAllSkills,
		skills, abilityData,
		buyRevivalTime, buyRevivalTimeMax, isOpenRevival,
		randomseed, isReplay,
		serverCommand, fromtoData
	)

end

--[[
初始化一场由外部传入阵容和关卡配置的战斗 (处理爬塔类似战斗没有关卡配置但是有别的配置的类型)
@params stageConfig table 关卡配置
@params -> 其他参数同上
--]]
function BattleConstructor:InitByCommonDataWithStageConfig(stageConfig,
		stageId, questBattleType, settlementType,
		formattedFriendTeamData, formattedEnemyTeamData,
		friendEquipedSkills, friendAllSkills, enemyEquipedSkills, enemyAllSkills,
		skills, abilityData,
		buyRevivalTime, buyRevivalTimeMax, isOpenRevival,
		randomseed, isReplay,
		serverCommand, fromtoData
	)

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
	local bgInfo = self:GetBattleBackgroundConfig(questBattleType, stageId, stageConfig)
	------------ 背景图 ------------

	------------ 随机数配置 ------------
	local randomConfig = BattleRandomConfigStruct.New(randomseed)
	------------ 随机数配置 ------------

	------------ 整合数据结构 ------------
	local time = nil ~= stageConfig.time and checkint(stageConfig.time) or self:GetBattleTotalTime(questBattleType, stageId)
	local weatherId = nil ~= stageConfig.weatherId and checktable(stageConfig.weatherId) or self:GetBattleWeatherInfo(questBattleType, stageId)
	local actionId = nil ~= stageConfig.actionId and checktable(stageConfig.actionId) or self:GetBattleBossActionInfo(questBattleType, stageId)

	local battleConstructorData = BattleConstructorStruct.New(
		------------ 战斗基本配置 ------------
		stageId,
		questBattleType,
		randomConfig,
		app.gameMgr:GetUserInfo().localBattleAccelerate,
		time,
		#formattedEnemyTeamData,
		settlementType_,
		stageCompleteInfo,
		false,
		isReplay == true,
		------------ 战斗数值配置 ------------
		self:OpenLevelRollingByQuestBattleType(questBattleType),
		------------ 战斗环境配置 ------------
		weatherId,
		actionId,
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
	------------ 整合数据结构 ------------

end

---------------------------------------------------
-- init logic end --
---------------------------------------------------


---------------------------------------------------
-- friend data convert begin --
---------------------------------------------------

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
function BattleConstructorEx:GetFormattedTeamsDataByTeamsMyCardData(data, attrData)
	return BattleConstructor.GetFormattedTeamsDataByTeamsMyCardData(self, data, attrData)
end

--[[
根据多队阵容数据获取格式化后的阵容战斗构造数据
@params data list 多队阵容信息
@params attrData map 卡牌属性数据
@return teamsData list 格式化后的阵容数据
--]]
function BattleConstructorEx:GetFormattedTeamsDataByTeamsCardData(data, attrData)
	return BattleConstructor.GetFormattedTeamsDataByTeamsCardData(self, data, attrData)
end

---------------------------------------------------
-- friend data convert end --
---------------------------------------------------


---------------------------------------------------
-- enemy data convert begin --
---------------------------------------------------

--[[
根据战斗类型和附加参数获取格式化后战斗构造器直接能使用的敌方阵容数据
@params stageId int 关卡id
@params questBattleType QuestBattleType 战斗类型
@params parameters table 附加参数
--]]
function BattleConstructorEx:ExConvertEnemyFormationData(stageId, questBattleType, parameters)
	local convertFuncConfig = {
		[QuestBattleType.BASE]                   = {func = 'ExConvertEFDDefault'},
		[QuestBattleType.MAP]                    = nil,
		[QuestBattleType.LOBBY]                  = nil,
		[QuestBattleType.PLOT]                   = nil,
		[QuestBattleType.ROBBERY]                = nil,
		[QuestBattleType.EXPLORE]                = nil,
		[QuestBattleType.TOWER]                  = {func = 'ExConvertEFDByTower'},
		[QuestBattleType.PVC]                    = nil,
		[QuestBattleType.PERFORMANCE]            = nil,
		[QuestBattleType.RAID]                   = nil,
		[QuestBattleType.NORMAL_EVENT]           = nil,
		[QuestBattleType.UNION_BEAST]            = nil,
		[QuestBattleType.UNION_PARTY]            = nil,
		[QuestBattleType.WORLD_BOSS]             = {func = 'ExConvertEFDByShareBoss'},
		[QuestBattleType.TAG_MATCH_3V3]          = nil,
		[QuestBattleType.ACTIVITY_QUEST]         = nil,
		[QuestBattleType.ARTIFACT_QUEST]         = nil,
		[QuestBattleType.SEASON_EVENT]           = nil,
		[QuestBattleType.SAIMOE]                 = nil,
		[QuestBattleType.ANNIVERSARY_EVENT]      = nil,
		[QuestBattleType.ARTIFACT_ROAD]          = nil,
		[QuestBattleType.PT_DUNGEON]             = nil,
		[QuestBattleType.SPRING_EVENT]           = nil,
		[QuestBattleType.NEW_SPRING_EVENT]       = nil,
		[QuestBattleType.UNION_PVC]              = nil,
		[QuestBattleType.UNION_PVB]              = nil,
		[QuestBattleType.MURDER]                 = nil,
		[QuestBattleType.SCARECROW]              = nil,
		[QuestBattleType.ULTIMATE_BATTLE]        = nil,
		[QuestBattleType.LUNA_TOWER]             = nil,
		[QuestBattleType.SKIN_CARNIVAL]          = nil,
		[QuestBattleType.WONDERLAND]             = nil,
		[QuestBattleType.FRIEND_BATTLE]          = nil,
		[QuestBattleType.SPRING_ACTIVITY_20]     = {func = 'ExConvertEFDByShareBoss'},
		[QuestBattleType.CHAMPIONSHIP_AUDITIONS] = nil,
		[QuestBattleType.CHAMPIONSHIP_PROMOTION] = nil,
		[QuestBattleType.POP_TEAM]		    	 = nil,
	}

	local funcInfo = convertFuncConfig[questBattleType] or convertFuncConfig[QuestBattleType.BASE]

	return self[funcInfo.func](self, parameters, stageId, questBattleType)
end

--[[
QuestBattleType.BASE
默认的敌方阵容数据转换
@params stageId int 关卡id
@params questBattleType QuestBattleType 战斗类型
--]]
function BattleConstructorEx:ExConvertEFDDefault(stageId, questBattleType)
	return self:GetCommonEnemyTeamDataByStageId(stageId)
end

--[[
QuestBattleType.TOWER
爬塔敌方阵容数据转换
@param parameters table {
	unitId int 爬塔单元id
	currentFloor int 当前层数
}
--]]
function BattleConstructorEx:ExConvertEFDByTower(parameters)
	local unitId = parameters.unitId
	local currentFloor = parameters.currentFloor

	local formattedTeamData = self:GetFormattedEnemyTeamDataByUnitAndFloor(unitId, currentFloor)
	return formattedTeamData
end

--[[
QuestBattleType.WORLD_BOSS
世界boss敌方阵容数据转换
@param parameters table {
	@params monsterIntensityData MonsterIntensityAttrStruct 怪物强度信息
	@params monsterAttrData table 怪物属性信息
}
@params stageId int 关卡id
@params questBattleType QuestBattleType 战斗类型
--]]
function BattleConstructorEx:ExConvertEFDByShareBoss(parameters, stageId, questBattleType)
	local monsterIntensityData = parameters.monsterIntensityData
	local monsterAttrData = parameters.monsterAttrData

	local formattedTeamData = self:GetCommonEnemyTeamDataByStageId(stageId, monsterIntensityData, monsterAttrData)
	return formattedTeamData
end

---------------------------------------------------
-- enemy data convert end --
---------------------------------------------------


---------------------------------------------------
-- convert other data begin --
---------------------------------------------------

--[[
根据爬塔的单元和层数获取构造的关卡信息
@params unitId int 爬塔单元id
@params currentFloor int 当前层数
@return stageConfig_ table
--]]
function BattleConstructorEx:ConvertTowerUnit2StageConfig(unitId, currentFloor)
	local fixedFloor = (currentFloor - 1) % 5 + 1
	local unitConfig = CommonUtils.GetConfigAllMess(TowerConfigParser.TYPE.UNIT ,'tower')[tostring(unitId)]

	if nil == unitConfig then
		-- 未找到单元配置
		app.uiMgr:ShowInformationTips(__('未找到单元配置 unit id -> ') .. unitId)
		return
	end

	local stageConfig_ = {
		backgroundId = unitConfig.backgroundId,
		backgroundScale = unitConfig.backgroundScale,
		time = checkint(unitConfig.time[fixedFloor]),
		weatherId = checktable(unitConfig.weatherId[fixedFloor]),
		actionId = checktable(unitConfig.actionId[fixedFloor])
	}

	return stageConfig_
end

---------------------------------------------------
-- convert other data end --
---------------------------------------------------

return BattleConstructorEx
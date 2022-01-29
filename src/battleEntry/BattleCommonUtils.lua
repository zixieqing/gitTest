-- 此处一定是重写commom utils如果不是会造成巨大的问题
if nil == CommonUtils then
	return
end

-- 战斗类型
QuestBattleType = {
	ALL                     = -1,       -- 所有战斗类型
	BASE                    = 0,
	MAP                     = 1,        -- 主线地图
	LOBBY                   = 2,        -- 霸王餐
	PLOT                    = 3,        -- 剧情任务
	ROBBERY                 = 4,        -- 打劫
	EXPLORE                 = 5,        -- 探索
	TOWER                   = 6,        -- 爬塔
	PVC                     = 7,        -- 竞技场
	PERFORMANCE             = 8,        -- 自定义
	RAID                    = 9,        -- 组队
	NORMAL_EVENT            = 10,       -- 日常活动 材料本等
	UNION_BEAST             = 11,       -- 神兽战
	UNION_PARTY             = 12,       -- 工会party
	WORLD_BOSS              = 13,       -- 世界boss
	TAG_MATCH_3V3           = 14,       -- 3队车轮战
	ACTIVITY_QUEST          = 15,       -- 活动副本
	ARTIFACT_QUEST          = 16,       -- 神器碎片试炼
	SEASON_EVENT            = 17,       -- 季度活动
	SAIMOE                  = 18,       -- 燃战
	ANNIVERSARY_EVENT       = 19,       -- 周年庆
	ARTIFACT_ROAD           = 20,       -- 神器之路
	PT_DUNGEON              = 21,       -- PT副本
	SPRING_EVENT            = 22,       -- 春季活动
	NEW_SPRING_EVENT  	    = 23, 		-- 新春季活动
	UNION_PVC               = 24,       -- 工会战人打人
	UNION_PVB               = 25,       -- 工会战人打boss
	MURDER                  = 26,       -- 杀人案(19夏活)
	SCARECROW               = 27,       -- 木桩关卡
	ULTIMATE_BATTLE         = 28,       -- 巅峰对决
	LUNA_TOWER 				= 29, 		-- luna塔
	SKIN_CARNIVAL 			= 30, 		-- 皮肤嘉年华
	WONDERLAND 				= 31,       -- 童话世界/2019周年庆
	FRIEND_BATTLE           = 32,       -- 好友切磋
	SPRING_ACTIVITY_20      = 33,       -- 20春活
	CHAMPIONSHIP_AUDITIONS  = 34,       -- 武道会-海选赛
	CHAMPIONSHIP_PROMOTION  = 35,       -- 武道会-晋级赛
	POP_TEAM                = 36,       -- 联动本（pop子）
	POP_BOSS_TEAM           = 37,       -- 联动本（boss 关卡）
	ANNIV2020_EXPLORE       = 38,       -- 周年庆探索
}

-- 技能id段类型
SkillSectionType = {
	BASE                      = 0,    -- 基础
	CARD_NORMAL_SKILL         = 1,    -- 卡牌技能
	MONSTER_SKILL             = 2,    -- 怪物技能
	CARD_MANAGER_SKILL        = 3,    -- 卡牌经营技能
	WEATHER_SKILL             = 4,    -- 天气技能
	ARTIFACT_TALENT_SKILL     = 5,    -- 神器天赋点技能
	ARTIFACT_GEMSTONE_SKILL   = 6,    -- 神器宝石技能
	BECKON_QTE_SKILL          = 7,    -- 战斗物体召唤技能
	UNION_PET_SKILL           = 8,    -- 工会神兽技能
	PLAYER_SKILL              = 9,    -- 主角技
	CARD_CONNECT_SKILL        = 10,   -- 卡牌连携技
	SPECIAL_SKILL             = 11,   -- 特殊buff技能
	EXTRA_CARD_SKILL          = 12,   -- 卡牌的外置技能
	ARTIFACT_TALENT_SKILL_2   = 13,   -- 神器天赋点技能扩展
	ARTIFACT_GEMSTONE_SKILL_2 = 14,   -- 神器宝石技能扩展
	ANNIVERSARY_20_CARD_SKILL = 15,   -- 周年庆技能
}

-------------------------------------------------
-- quest utils begin --
-------------------------------------------------
--[[
获取关卡信息
@params questId int 关卡id
@return _ table 关卡信息
--]]
function CommonUtils.GetQuestConf(questId)
	local configPathConfig = {
		[QuestBattleType.MAP]                       = {moduleName = 'quest', jsonName = 'quest'},
		[QuestBattleType.UNION_BEAST]               = {moduleName = 'union', jsonName = 'godBeastQuest'},
		[QuestBattleType.RAID]                      = {moduleName = 'quest', jsonName = 'teamBoss'},
		[QuestBattleType.NORMAL_EVENT]              = {moduleName = 'materialQuest', jsonName = 'quest'},
		[QuestBattleType.LOBBY]                     = {moduleName = 'restaurant', jsonName = 'quest'},
		[QuestBattleType.SEASON_EVENT]              = {moduleName = 'summerActivity', jsonName = 'quest'},
		[QuestBattleType.UNION_PARTY]               = {moduleName = 'union', jsonName = 'partyQuest'},
		[QuestBattleType.PLOT]                      = {moduleName = 'quest', jsonName = 'plotFightQuest'},
		[QuestBattleType.EXPLORE]                   = {moduleName = 'explore', jsonName = 'exploreQuest'},
		[QuestBattleType.ARTIFACT_QUEST]            = {moduleName = 'artifact', jsonName = 'quest'},
		[QuestBattleType.WORLD_BOSS]                = {moduleName = 'worldBossQuest', jsonName = 'quest'},
		[QuestBattleType.ACTIVITY_QUEST]            = {moduleName = 'activityQuest', jsonName = 'quest'},
		[QuestBattleType.SAIMOE]                    = {moduleName = 'cardComparison', jsonName = 'quest'},
		[QuestBattleType.ANNIVERSARY_EVENT]         = {moduleName = 'anniversary', jsonName = 'quest'},
		[QuestBattleType.ARTIFACT_ROAD]             = {moduleName = 'activity', jsonName = 'artifactQuest'},
		[QuestBattleType.PT_DUNGEON]                = {moduleName = 'pt', jsonName = 'quest'},
		[QuestBattleType.SPRING_EVENT]              = {moduleName = 'seasonActivity', jsonName = 'quest'},
		[QuestBattleType.NEW_SPRING_EVENT]          = {moduleName = 'springActivity', jsonName = 'quest'},
		[QuestBattleType.UNION_PVB]                 = {moduleName = 'union', jsonName = 'warsBeastQuest'},
		[QuestBattleType.MURDER]                    = {moduleName = 'newSummerActivity', jsonName = 'quest'},
		[QuestBattleType.SCARECROW]                 = {moduleName = 'player', jsonName = 'dummyQuest'},
		[QuestBattleType.LUNA_TOWER]                = {moduleName = 'lunaTower', jsonName = 'quest'},
		[QuestBattleType.WONDERLAND]                = {moduleName = 'anniversary2', jsonName = 'quest'},
		[QuestBattleType.SPRING_ACTIVITY_20]        = {moduleName = 'springActivity2020', jsonName = 'quest'},
		[QuestBattleType.CHAMPIONSHIP_AUDITIONS]    = {moduleName = 'championship', jsonName = 'auditionQuest'},
		[QuestBattleType.POP_TEAM]           	    = {moduleName = 'activity', jsonName = 'farmQuest'},
		[QuestBattleType.POP_BOSS_TEAM]           	= {moduleName = 'activity', jsonName = 'farmBoss'},
		[QuestBattleType.ANNIV2020_EXPLORE]         = {moduleName = 'anniversary2020', jsonName = 'quest'},
	}

	local questBattleType = CommonUtils.GetQuestBattleByQuestId(questId)

	local configPathInfo = configPathConfig[questBattleType]
	if nil ~= configPathInfo then
		return CommonUtils.GetConfigNoParser(configPathInfo.moduleName, configPathInfo.jsonName, questId)
	else
		return nil
	end
end
--[[
根据关卡id获取关卡战斗类型
@params questId int 关卡id
@return questBattleType QuestBattleType
--]]
function CommonUtils.GetQuestBattleByQuestId(questId)
	if nil == questId then return nil end
	questId = checkint(questId)

	local questSectionConfig = {
		-- 主线战斗
		[QuestBattleType.MAP] = {
			{lower = 0, upper = 3000}
		},
		-- 工会神兽
		[QuestBattleType.UNION_BEAST] = {
			{lower = 3000, upper = 4000}
		},
		-- 组队本
		[QuestBattleType.RAID] = {
			{lower = 4000, upper = 5000}
		},
		-- 普通活动本
		[QuestBattleType.NORMAL_EVENT] = {
			{lower = 5000, upper = 6000}
		},
		-- 霸王餐
		[QuestBattleType.LOBBY] = {
			{lower = 6000, upper = 7000}
		},
		-- 季活
		[QuestBattleType.SEASON_EVENT] = {
			{lower = 7000, upper = 7900}
		},
		-- 工会party
		[QuestBattleType.UNION_PARTY] = {
			{lower = 7900, upper = 8000}
		},
		-- 剧情战斗
		[QuestBattleType.PLOT] = {
			{lower = 8000, upper = 9000}
		},
		-- 探索战斗
		[QuestBattleType.EXPLORE] = {
			{lower = 9000, upper = 12000}
		},
		-- 神器能量
		[QuestBattleType.ARTIFACT_QUEST] = {
			{lower = 12000, upper = 20000}
		},
		-- 世界boss
		[QuestBattleType.WORLD_BOSS] = {
			{lower = 20000, upper = 20100}
		},
		-- 萌战
		[QuestBattleType.SAIMOE] = {
			{lower = 20100, upper = 20200}
		},
		-- 周年庆活动
		[QuestBattleType.ANNIVERSARY_EVENT] = {
			{lower = 20200, upper = 21000}
		},
		-- 活动任务
		[QuestBattleType.ACTIVITY_QUEST] = {
			{lower = 30000, upper = 38999}
		},
		-- 神器之路
		[QuestBattleType.ARTIFACT_ROAD] = {
			{lower = 39000, upper = 39999}, {lower = 139000, upper = 149999},
		},
		-- pt本
		[QuestBattleType.PT_DUNGEON] = {
			{lower = 40000, upper = 42000}
		},
		-- 春活
		[QuestBattleType.SPRING_EVENT] = {
			{lower = 42000, upper = 44000}
		},
		-- 新春活
		[QuestBattleType.NEW_SPRING_EVENT] = {
			{lower = 45000, upper = 46000}
		},
		-- 工会boss战
		[QuestBattleType.UNION_PVB] = {
			{lower = 46000, upper = 48000}
		},
		-- 杀人案
		[QuestBattleType.MURDER] = {
			{lower = 48000, upper = 50000}
		},
		-- 木桩
		[QuestBattleType.SCARECROW] = {
			{lower = 50000, upper = 60000}
		},
		-- luna塔
		[QuestBattleType.LUNA_TOWER] = {
			{lower = 60000, upper = 70000}
		},
		-- 童话世界 2019周年庆
		[QuestBattleType.WONDERLAND]  = {
			{lower = 70000, upper = 71000}
		},
		-- 2020春活
		[QuestBattleType.SPRING_ACTIVITY_20] = {
			{lower = 71000, upper = 72000}
		},
		-- 联动本（pop子）
		[QuestBattleType.POP_TEAM] = {
			{lower = 72000, upper = 72080}
		},
		[QuestBattleType.POP_BOSS_TEAM] = {
			{lower = 72080, upper = 73000}
		},
		-- 武道会-预选赛
		[QuestBattleType.CHAMPIONSHIP_AUDITIONS] = {
			{lower = 73000, upper = 74000}
		},
		-- 2020 周年庆
		[QuestBattleType.ANNIV2020_EXPLORE] = {
			{lower = 74000, upper = 75000}
		},
	}

	for questBattleType, sectionsConfig in pairs(questSectionConfig) do
		for _, sectionConfig in ipairs(sectionsConfig) do
			if sectionConfig.lower < questId and sectionConfig.upper >= questId then
				return questBattleType
			end
		end
	end

	return QuestBattleType.BASE
end
-------------------------------------------------
-- quest utils end --
-------------------------------------------------

-------------------------------------------------
-- skill config begin --
-------------------------------------------------
--[[
获取技能信息
@params skillId int 技能id
--]]
function CommonUtils.GetSkillConf(skillId)
	local configPathConfig = {
		[SkillSectionType.CARD_NORMAL_SKILL]        = {getFunction = CardUtils.GetSkillConfigBySkillId},
		[SkillSectionType.MONSTER_SKILL]            = {getFunction = CardUtils.GetSkillConfigBySkillId},
		[SkillSectionType.CARD_MANAGER_SKILL]       = {getFunction = CardUtils.GetSkillConfigBySkillId},
		[SkillSectionType.WEATHER_SKILL]            = {getFunction = CardUtils.GetSkillConfigBySkillId},
		[SkillSectionType.ARTIFACT_TALENT_SKILL]    = {moduleName = 'artifact', jsonName = 'talentSkill'},
		[SkillSectionType.ARTIFACT_TALENT_SKILL_2]  = {moduleName = 'artifact', jsonName = 'talentSkill'},
		[SkillSectionType.ARTIFACT_GEMSTONE_SKILL]  = {moduleName = 'artifact', jsonName = 'gemstoneSkill'},
		[SkillSectionType.ARTIFACT_GEMSTONE_SKILL_2]= {moduleName = 'artifact', jsonName = 'gemstoneSkill'},
		[SkillSectionType.BECKON_QTE_SKILL]         = {getFunction = CardUtils.GetSkillConfigBySkillId},
		[SkillSectionType.UNION_PET_SKILL]          = {getFunction = CardUtils.GetSkillConfigBySkillId},
		[SkillSectionType.PLAYER_SKILL]             = {moduleName = 'player', jsonName = 'skill'},
		[SkillSectionType.CARD_CONNECT_SKILL]       = {getFunction = CardUtils.GetSkillConfigBySkillId},
		[SkillSectionType.SPECIAL_SKILL]            = {moduleName = 'cards', jsonName = 'specialSkill'},
		[SkillSectionType.EXTRA_CARD_SKILL]         = {moduleName = 'summerActivity', jsonName = 'cardSkill'},
		[SkillSectionType.ANNIVERSARY_20_CARD_SKILL]= {moduleName = 'anniversary2020', jsonName = 'cardSkill'},
	}

	local skillSectionType = CommonUtils.GetSkillSectionTypeBySkillId(skillId)

	local configPathInfo = configPathConfig[skillSectionType]
	if nil ~= configPathInfo then
		if configPathInfo.getFunction then
			return configPathInfo.getFunction(skillId)
		else
			return CommonUtils.GetConfig(configPathInfo.moduleName, configPathInfo.jsonName, skillId)
		end
	else
		return nil
	end
end
--[[
根据技能id获取技能id段类型
@params skillId int 技能id
@return _ SkillSectionType 技能id段类型
--]]
function CommonUtils.GetSkillSectionTypeBySkillId(skillId)
	if nil == skillId then return nil end

	local skillId_ = checkint(skillId)

	local skillSectionConfig = {
		[SkillSectionType.CARD_NORMAL_SKILL]        = {lower = 10000, upper = 20000},
		[SkillSectionType.MONSTER_SKILL]            = {lower = 20000, upper = 30000},
		[SkillSectionType.CARD_MANAGER_SKILL]       = {lower = 30000, upper = 40000},
		[SkillSectionType.WEATHER_SKILL]            = {lower = 40000, upper = 50000},
		[SkillSectionType.ARTIFACT_TALENT_SKILL]    = {lower = 50000, upper = 55000},
		[SkillSectionType.ARTIFACT_GEMSTONE_SKILL]  = {lower = 55000, upper = 60000},
		[SkillSectionType.BECKON_QTE_SKILL]         = {lower = 60000, upper = 70000},
		[SkillSectionType.UNION_PET_SKILL]          = {lower = 70000, upper = 80000},
		[SkillSectionType.PLAYER_SKILL]             = {lower = 80000, upper = 90000},
		[SkillSectionType.CARD_CONNECT_SKILL]       = {lower = 90000, upper = 100000},
		[SkillSectionType.SPECIAL_SKILL]            = {lower = 100000, upper = 150000},
		[SkillSectionType.EXTRA_CARD_SKILL]         = {lower = 150000, upper = 160000},
		[SkillSectionType.ANNIVERSARY_20_CARD_SKILL]= {lower = 160000, upper = 170000},
		[SkillSectionType.ARTIFACT_TALENT_SKILL_2]  = {lower = 170000, upper = 2000000},
		[SkillSectionType.ARTIFACT_GEMSTONE_SKILL_2]= {lower = 2000000, upper = 3000000}

	}
	for skillSectionType, sectionConfig in pairs(skillSectionConfig) do
		if sectionConfig.lower < skillId_ and sectionConfig.upper > skillId_ then
			return skillSectionType
		end
	end
	return SkillSectionType.BASE
end
-------------------------------------------------
-- skill config end --
-------------------------------------------------

-- --[[
-- 重写CommonUtils中的一些方法
-- --]]
-- CommonUtils = {}

-- ------------ import ------------
-- ------------ import ------------

-- ------------ define ------------
-- -- 全局保存配表信息的map
-- CommonUtils.ConfigMap = {}
-- ------------ define ------------

-- -------------------------------------------------
-- -- config begin --
-- -------------------------------------------------
-- --[[
-- 根据模块名 配表名获取
-- @params mname string 模块名
-- @params tname string 配表名
-- @params id string 键
-- @return _ table
-- --]]
-- function CommonUtils.GetConfig(mname, tname, id)
-- 	-- 特殊处理
-- 	if 'cards' == mname then mname = 'card' end
	
-- 	if nil == CommonUtils.ConfigMap[tostring(mname)] or nil == CommonUtils.ConfigMap[tostring(mname)][tostring(tname)] then
-- 		-- 内存里没有这张表 加载一次这张表
-- 		CommonUtils.LoadConfigJson(tostring(mname), tostring(tname))
-- 	end
-- 	return CommonUtils.ConfigMap[tostring(mname)][tostring(tname)][tostring(id)]
-- end
-- function CommonUtils.GetConfigNoParser(module, tname, id)
--     return CommonUtils.GetConfig(module, tname, id)
-- end
-- --[[
-- 根据模块名 配表名加载配表
-- @params mname string 模块名
-- @params tname string 配表名
-- --]]
-- function CommonUtils.LoadConfigJson(mname, tname)
-- 	local path = CommonUtils.GetConfigPathByMN(mname, tname)
-- 	if CommonUtils.FileExistByPath(path) then
-- 		local file = io.open(path)
-- 		local fileContent = file:read('*a')
-- 		local configtable = json.decode(fileContent)
-- 		file:close()
-- 		if nil == CommonUtils.ConfigMap[mname] then
-- 			CommonUtils.ConfigMap[mname] = {}
-- 		end
-- 		CommonUtils.ConfigMap[mname][tname] = configtable
-- 	else
-- 		print('cannot find file when loading config json ->', path)
-- 	end
-- end
-- --[[
-- 根据模块名 配表名移除配表
-- @params mname string 模块名
-- @params tname string 配表名
-- --]]
-- function CommonUtils.RemoveConfigJson(mname, tname)

-- end
-- --[[
-- 根据模块名 配表名获取配表文件路径
-- @params mname string 模块名
-- @params tname string 配表名
-- --]]
-- function CommonUtils.GetConfigPathByMN(mname, tname)
-- 	return 'conf/' .. CommonUtils.GetLangCode() .. '/' .. mname .. '/' .. tname .. '.json'
-- end
-- -------------------------------------------------
-- -- config end --
-- -------------------------------------------------

-- -------------------------------------------------
-- -- quest config begin --
-- -------------------------------------------------
-- --[[
-- 获取关卡信息
-- @params questId int 关卡id
-- @return _ table 关卡信息
-- --]]
-- function CommonUtils.GetQuestConf(questId)
--     local configPathConfig = {
--         [QuestBattleType.MAP]                       = {moduleName = 'quest', jsonName = 'quest'},
--         [QuestBattleType.UNION_BEAST]               = {moduleName = 'union', jsonName = 'godBeastQuest'},
--         [QuestBattleType.RAID]                      = {moduleName = 'quest', jsonName = 'teamBoss'},
--         [QuestBattleType.NORMAL_EVENT]              = {moduleName = 'materialQuest', jsonName = 'quest'},
--         [QuestBattleType.LOBBY]                     = {moduleName = 'restaurant', jsonName = 'quest'},
--         [QuestBattleType.SEASON_EVENT]              = {moduleName = 'summerActivity', jsonName = 'quest'},
--         [QuestBattleType.UNION_PARTY]               = {moduleName = 'union', jsonName = 'partyQuest'},
--         [QuestBattleType.PLOT]                      = {moduleName = 'quest', jsonName = 'plotFightQuest'},
--         [QuestBattleType.EXPLORE]                   = {moduleName = 'explore', jsonName = 'exploreQuest'},
--         [QuestBattleType.ARTIFACT_QUEST]            = {moduleName = 'artifact', jsonName = 'quest'},
--         [QuestBattleType.WORLD_BOSS]                = {moduleName = 'worldBossQuest', jsonName = 'quest'},
--         [QuestBattleType.ACTIVITY_QUEST]            = {moduleName = 'activityQuest', jsonName = 'quest'},
--         [QuestBattleType.MURDER]                    = {moduleName = 'newSummerActivity', jsonName = 'quest'},
--     }

--     local questBattleType = CommonUtils.GetQuestBattleByQuestId(questId)

--     local configPathInfo = configPathConfig[questBattleType]
--     if nil ~= configPathInfo then
--         return CommonUtils.GetConfigNoParser(configPathInfo.moduleName, configPathInfo.jsonName, questId)
--     else
--         return nil
--     end
-- end
-- --[[
-- 根据关卡id获取关卡战斗类型
-- @params questId int 关卡id
-- @return questBattleType QuestBattleType
-- --]]
-- function CommonUtils.GetQuestBattleByQuestId(questId)
--     if nil == questId then return nil end

--     local questSectionConfig = {
--         [QuestBattleType.MAP]                       = {lower = 0, upper = 3000},
--         [QuestBattleType.UNION_BEAST]               = {lower = 3000, upper = 4000},
--         [QuestBattleType.RAID]                      = {lower = 4000, upper = 5000},
--         [QuestBattleType.NORMAL_EVENT]              = {lower = 5000, upper = 6000},
--         [QuestBattleType.LOBBY]                     = {lower = 6000, upper = 7000},
--         [QuestBattleType.SEASON_EVENT]              = {lower = 7000, upper = 7900},
--         [QuestBattleType.UNION_PARTY]               = {lower = 7900, upper = 8000},
--         [QuestBattleType.PLOT]                      = {lower = 8000, upper = 9000},
--         [QuestBattleType.EXPLORE]                   = {lower = 9000, upper = 12000},
--         [QuestBattleType.ARTIFACT_QUEST]            = {lower = 12000, upper = 20000},
--         [QuestBattleType.WORLD_BOSS]                = {lower = 20000, upper = 30000},
--         [QuestBattleType.ACTIVITY_QUEST]            = {lower = 30000, upper = 48000},
--         [QuestBattleType.MURDER]                    = {lower = 48000, upper = 100000},
--     }

--     for questBattleType, sectionConfig in pairs(questSectionConfig) do
--         if sectionConfig.lower < questId and sectionConfig.upper > questId then
--             return questBattleType
--         end
--     end

--     return QuestBattleType.BASE
-- end
-- -------------------------------------------------
-- -- quest config end --
-- -------------------------------------------------

-- -------------------------------------------------
-- -- skill config begin --
-- -------------------------------------------------
-- --[[
-- 获取技能信息
-- @params skillId int 技能id
-- --]]
-- function CommonUtils.GetSkillConf(skillId) 
--     local configPathConfig = {
--         [SkillSectionType.CARD_NORMAL_SKILL]        = {moduleName = 'cards', jsonName = 'skill'},
--         [SkillSectionType.MONSTER_SKILL]            = {moduleName = 'cards', jsonName = 'skill'},
--         [SkillSectionType.CARD_MANAGER_SKILL]       = {moduleName = 'cards', jsonName = 'skill'},
--         [SkillSectionType.WEATHER_SKILL]            = {moduleName = 'cards', jsonName = 'skill'},
--         [SkillSectionType.ARTIFACT_TALENT_SKILL]    = {moduleName = 'artifact', jsonName = 'talentSkill'},
--         [SkillSectionType.ARTIFACT_GEMSTONE_SKILL]  = {moduleName = 'artifact', jsonName = 'gemstoneSkill'},
--         [SkillSectionType.BECKON_QTE_SKILL]         = {moduleName = 'cards', jsonName = 'skill'},
--         [SkillSectionType.UNION_PET_SKILL]          = {moduleName = 'cards', jsonName = 'skill'},
--         [SkillSectionType.PLAYER_SKILL]             = {moduleName = 'player', jsonName = 'skill'},
--         [SkillSectionType.CARD_CONNECT_SKILL]       = {moduleName = 'cards', jsonName = 'skill'},
--         [SkillSectionType.SPECIAL_SKILL]            = {moduleName = 'cards', jsonName = 'specialSkill'},
--         [SkillSectionType.EXTRA_CARD_SKILL]         = {moduleName = 'summerActivity', jsonName = 'cardSkill'}
--     }

--     local skillSectionType = CommonUtils.GetSkillSectionTypeBySkillId(skillId)

--     local configPathInfo = configPathConfig[skillSectionType]
--     if nil ~= configPathInfo then
--         return CommonUtils.GetConfig(configPathInfo.moduleName, configPathInfo.jsonName, skillId)
--     else
--         return nil
--     end
-- end
-- --[[
-- 根据技能id获取技能id段类型
-- @params skillId int 技能id
-- @return _ SkillSectionType 技能id段类型
-- --]]
-- function CommonUtils.GetSkillSectionTypeBySkillId(skillId)
--     if nil == skillId then return nil end

--     local skillId_ = checkint(skillId)

--     local skillSectionConfig = {
--         [SkillSectionType.CARD_NORMAL_SKILL]        = {lower = 10000, upper = 20000},
--         [SkillSectionType.MONSTER_SKILL]            = {lower = 20000, upper = 30000},
--         [SkillSectionType.CARD_MANAGER_SKILL]       = {lower = 30000, upper = 40000},
--         [SkillSectionType.WEATHER_SKILL]            = {lower = 40000, upper = 50000},
--         [SkillSectionType.ARTIFACT_TALENT_SKILL]    = {lower = 50000, upper = 55000},
--         [SkillSectionType.ARTIFACT_GEMSTONE_SKILL]  = {lower = 55000, upper = 60000},
--         [SkillSectionType.BECKON_QTE_SKILL]         = {lower = 60000, upper = 70000},
--         [SkillSectionType.UNION_PET_SKILL]          = {lower = 70000, upper = 80000},
--         [SkillSectionType.PLAYER_SKILL]             = {lower = 80000, upper = 90000},
--         [SkillSectionType.CARD_CONNECT_SKILL]       = {lower = 90000, upper = 100000},
--         [SkillSectionType.SPECIAL_SKILL]            = {lower = 100000, upper = 150000},
--         [SkillSectionType.EXTRA_CARD_SKILL]         = {lower = 150000, upper = 200000}
--     }

--     for skillSectionType, sectionConfig in pairs(skillSectionConfig) do
--         if sectionConfig.lower < skillId_ and sectionConfig.upper > skillId_ then
--             return skillSectionType
--         end
--     end

--     return SkillSectionType.BASE
-- end
-- -------------------------------------------------
-- -- skill config end --
-- -------------------------------------------------

-- -------------------------------------------------
-- -- file begin --
-- -------------------------------------------------
-- --[[
-- 根据文件路径判断文件是否存在
-- @params path string 文件路径
-- @return _ bool 是否存在
-- --]]
-- function CommonUtils.FileExistByPath(path)
-- 	local file = io.open(path)
-- 	if nil ~= file then
-- 		file:close()
-- 	end
-- 	return nil ~= file
-- end
-- -------------------------------------------------
-- -- file end --
-- -------------------------------------------------

-- -------------------------------------------------
-- -- language begin --
-- -------------------------------------------------
-- --[[
-- 获取语言代码
-- @return _ LangCodesMap
-- --]]
-- function CommonUtils.GetLangCode()
-- 	return 'zh-cn'
-- end
-- -------------------------------------------------
-- -- language end --
-- -------------------------------------------------
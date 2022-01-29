--[[
配表查错
--]]
local GameScene = require( 'Frame.GameScene' )
local DebugConfigScene = class('DebugConfigScene', GameScene)

local SHOW_WARING = false
local LANGUAGE_TAG = 'zh-cn'
__Require('battle.controller.BattleConstants')

function DebugConfigScene:ctor( ... )
	self.configtables = {}

	print('\n\n==========================================\ncheck config start\n==========================================\n\n')

	-- self:CheckAllStageConfig()
	-- self:CheckAllWeatherConfig()
	-- self:CheckAllCardConfig()
	-- self:CheckAllMonsterConfig()
	-- self:CheckAllCardSkillConfig()

	print('\n\n==========================================\ncheck config over\n==========================================\n\n')

	self:InitUI()

end
function DebugConfigScene:InitUI()
	-- debug按钮配置
	local debugBtnInfo = {
		{name = '关卡表', cb = function ( sender )
			print('\n\n==========================================\ncheck #quest/quest# config start\n==========================================\n\n')
			self:CheckAllStageConfig()
			print('\n\n==========================================\ncheck #quest/quest# config over\n==========================================\n\n')
		end},
		{name = '剧情关卡表', cb = function ( sender )
			print('\n\n==========================================\ncheck #quest/plotFightQuest# config start\n==========================================\n\n')
			self:CheckAllPlotStageConfig()
			print('\n\n==========================================\ncheck #quest/plotFightQuest# config over\n==========================================\n\n')
		end},
		{name = '霸王餐关卡表', cb = function ( sender )
			print('\n\n==========================================\ncheck #lobby/lobbyQuest# config start\n==========================================\n\n')
			self:CheckAllLobbyStageConfig()
			print('\n\n==========================================\ncheck #lobby/lobbyQuest# config over\n==========================================\n\n')
		end},
		{name = '探索关卡表', cb = function ( sender )
			print('\n\n==========================================\ncheck #explore/exploreQuest# config start\n==========================================\n\n')
			self:CheckAllExploreStageConfig()
			print('\n\n==========================================\ncheck #explore/exploreQuest# config over\n==========================================\n\n')
		end},
		{name = '天气表', cb = function ( sender )
			print('\n\n==========================================\ncheck #quest/weather# config start\n==========================================\n\n')
			self:CheckAllWeatherConfig()
			print('\n\n==========================================\ncheck #quest/weather# config over\n==========================================\n\n')
		end},
		{name = '卡牌表', cb = function ( sender )
			print('\n\n==========================================\ncheck #card/card# config start\n==========================================\n\n')
			self:CheckAllCardConfig()
			print('\n\n==========================================\ncheck #card/card# config over\n==========================================\n\n')
		end},
		{name = '怪物表', cb = function ( sender )
			print('\n\n==========================================\ncheck #monster/monster# config start\n==========================================\n\n')
			self:CheckAllMonsterConfig()
			print('\n\n==========================================\ncheck #monster/monster# config over\n==========================================\n\n')
		end},
		{name = '卡牌技能表', cb = function ( sender )
			print('\n\n==========================================\ncheck #card/skill# config start\n==========================================\n\n')
			self:CheckAllCardSkillConfig()
			print('\n\n==========================================\ncheck #card/skill# config over\n==========================================\n\n')
		end},
		{name = '机器人表', cb = function ( sender )
			print('\n\n==========================================\ncheck #arena/robotNpc# config start\n==========================================\n\n')
			self:CheckAllRobotConfig()
			print('\n\n==========================================\ncheck #arena/robotNpc# config over\n==========================================\n\n')
		end},
	}

	for i,v in ipairs(debugBtnInfo) do
		local checkBtn = display.newButton(0, 0, {n = 'ui/common/common_btn_orange.png', cb = v.cb})

		local row = math.ceil(checkBtn:getContentSize().width * i / display.width)
		local x = checkBtn:getContentSize().width * (i - 0.5) - (row - 1) * display.width
		local y = display.height - checkBtn:getContentSize().height * (row - 0.5)

		display.commonLabelParams(checkBtn, {text = v.name, fontSize = 20, color = '#ffffff'})
		display.commonUIParams(checkBtn, {po = cc.p(x, y)})
		self:addChild(checkBtn, 99999)
	end
end
---------------------------------------------------
-- check logic begin --
---------------------------------------------------
--[[
检查所有卡牌配置
--]]
function DebugConfigScene:CheckAllCardConfig()
	local cardConfigtable = self:ConvertJsonToLuaByFilePath(self:GetConfigPath('card', 'card'))

	local log = ''

	for cardId_, cardConfig_ in pairs(cardConfigtable) do
		log = log .. self:CheckCardConfig(checkint(cardId_), cardConfig_)
	end

	print(log)
end
--[[
检查单张卡牌配置
@params cardId int 卡牌id
@params cardConfig table 卡牌配置
@return log str 卡牌查错log
--]]
function DebugConfigScene:CheckCardConfig(cardId, cardConfig)
	local log = '\n\n>>>>>>>>>>> start check card id -> ' .. cardId .. ' ......'

	local cardGrowConfigtable = self:ConvertJsonToLuaByFilePath(self:GetConfigPath('card', 'grow'))
	local skillConfigtable = self:ConvertJsonToLuaByFilePath(self:GetConfigPath('card', 'skill'))
	local cardConfigtable = self:ConvertJsonToLuaByFilePath(self:GetConfigPath('card', 'card'))
	local petConfigtable = self:ConvertJsonToLuaByFilePath(self:GetConfigPath('pet', 'pet'))
	local skinConfigtable = self:ConvertJsonToLuaByFilePath(self:GetConfigPath('goods', 'cardSkin'))

	local cardGrowConfig = cardGrowConfigtable[tostring(cardId)]
	-- 卡牌成长
	if nil == cardGrowConfig then
		log = log .. self:GetErrorLog(string.format('cannot find card grow config -> cardId:%d', checkint(cardId)))
	else
		local fieldsName = {
			{name = 'attack', amount = 7},
			{name = 'defence', amount = 7},
			{name = 'hp', amount = 7},
			{name = 'critRate', amount = 7},
			{name = 'critDamage', amount = 7},
			{name = 'attackRate', amount = 7}
		}

		for i,v in ipairs(fieldsName) do
			if nil == cardGrowConfig[v.name] then
				log = log .. self:GetErrorLog(string.format('cannot find card grow config -> cardId:%d, prop name -> #%s#', checkint(cardId), v.name))
			else
				if #cardGrowConfig[v.name] < v.amount then
					log = log .. self:GetErrorLog(string.format('cardId:%d less grow config propName:%s, only has #%d# props ', checkint(cardId), v.name, #cardGrowConfig[v.name]))
				end
			end
		end
	end

	-- 检查连携技对象
	for i, cardId_ in ipairs(cardConfig.concertSkill) do
		if nil == cardConfigtable[tostring(cardId_)] then
			log = log .. self:GetErrorLog(string.format('cannot find connect skill card mainCardId:%d, connectCardId:%d', checkint(cardId), checkint(cardId_)))
		end
	end

	-- 检查本命堕神
	local mainPetString = cardConfig.exclusivePet
	for i, petId in ipairs(string.split(mainPetString, ';')) do
		if nil == petConfigtable[tostring(petId)] then
			log = log .. self:GetErrorLog(string.format('cannot find card exclusive pet -> cardId:%d, petId:%d', checkint(cardId), checkint(petId)))
		end
	end

	-- 检查卡牌皮肤信息 资源
	for k,v in pairs(cardConfig.skin) do
		for skinId,_ in pairs(v) do
			log = log .. self:CheckSkinConfigAndResource(checkint(skinId), skinConfigtable[tostring(skinId)], cardId)
		end
	end


	local skillConfig = nil
	-- 检查技能
	for _, skillId_ in ipairs(cardConfig.skill) do
		skillConfig = skillConfigtable[tostring(skillId_)]
		log = log .. self:CheckSkillConfig(checkint(skillId_), skillConfig)
	end

	return log
end
--[[
检查所有关卡配置
--]]
function DebugConfigScene:CheckAllStageConfig()
	local log = ''

	local stageConfigtable = self:ConvertJsonToLuaByFilePath(self:GetConfigPath('quest', 'quest'))

	for stageId_, stageConfig_ in pairs(stageConfigtable) do
		log = log .. self:CheckStageConfig(checkint(stageId_), stageConfig_)
	end

	print(log)
end
--[[
检查所有剧情关卡表配置
--]]
function DebugConfigScene:CheckAllPlotStageConfig()
	local log = ''

	local stageConfigtable = self:ConvertJsonToLuaByFilePath(self:GetConfigPath('quest', 'plotFightQuest'))

	for stageId_, stageConfig_ in pairs(stageConfigtable) do
		log = log .. self:CheckStageConfig(checkint(stageId_), stageConfig_)
	end

	print(log)
end
--[[
检查所有霸王餐关卡表配置
--]]
function DebugConfigScene:CheckAllLobbyStageConfig()
	local log = ''

	local stageConfigtable = self:ConvertJsonToLuaByFilePath(self:GetConfigPath('restaurant', 'quest'))

	for stageId_, stageConfig_ in pairs(stageConfigtable) do
		log = log .. self:CheckStageConfig(checkint(stageId_), stageConfig_)
	end

	print(log)
end
--[[
检查所有探索关卡表配置
--]]
function DebugConfigScene:CheckAllExploreStageConfig()
	local log = ''

	local stageConfigtable = self:ConvertJsonToLuaByFilePath(self:GetConfigPath('explore', 'exploreQuest'))

	for stageId_, stageConfig_ in pairs(stageConfigtable) do
		log = log .. self:CheckStageConfig(checkint(stageId_), stageConfig_)
	end

	print(log)
end
--[[
检查单关卡配置
@params stageId int 关卡id
@params stageConfig table 关卡配置
@return log str 关卡查错log
--]]
function DebugConfigScene:CheckStageConfig(stageId, stageConfig)
	local log = '\n\n@@@@@@@@@@@@@@@@@@@@@@@@@@@ start check stage id -> ' .. stageId .. ' ......'

	if nil == stageConfig then
		log = log .. self:GetErrorLog(string.format('cannot find stage config -> stageId:%d', checkint(stageId)))
		return log
	end

	-- 关卡时间不能为0
	if 0 >= checknumber(stageConfig.time) then
		log = log .. self:GetErrorLog(string.format('stage time cannot be 0 -> stageId:%d', checkint(stageId)))
	end

	-- -- 检查天气配置
	-- if #stageConfig.weatherId > 0 then
	-- 	local weatherConfigtable = self:ConvertJsonToLuaByFilePath(self:GetConfigPath('quest', 'weather'))
	-- 	local weatherConfig = nil

	-- 	for _, weatherId_ in ipairs(stageConfig.weatherId) do
	-- 		weatherConfig = weatherConfigtable[tostring(weatherId_)]
	-- 		log = log .. self:CheckWeatherConfig(checkint(weatherId_), weatherConfig)
	-- 	end
	-- end

	-- TODO 检查转阶段配置

	-- 阵容检查
	local enemyConfigtable = self:ConvertJsonToLuaByFilePath(self:GetConfigPath('quest', 'enemy'))
	local enemyConfig = enemyConfigtable[tostring(stageId)]
	log = log .. self:CheckStageEnemyConfig(checkint(stageId), enemyConfig)

	return log
end
--[[
检查单关卡阵容配置
@params enemyId int 关卡阵容id
@params enemyConfig table 关卡阵容配置
@return log str 关卡阵容查错log
--]]
function DebugConfigScene:CheckStageEnemyConfig(enemyId, enemyConfig)
	-- local log = '\n\n>>>>>>>>>>> start check enemy id -> ' .. enemyId .. ' ......'
	local log = ''

	if nil == enemyConfig then
		log = log .. self:GetErrorLog(string.format('cannot find enemy config -> stageId:%d', checkint(enemyId)))
		return log
	end

	local battlePositionConfigtable = self:ConvertJsonToLuaByFilePath(self:GetConfigPath('quest', 'battlePosition'))
	local monsterConfigtable = self:ConvertJsonToLuaByFilePath(self:GetConfigPath('monster', 'monster'))
	local monsterConfig = nil

	for waveId_, waveConfig_ in pairs(enemyConfig) do
		for _, npcConfig_ in pairs(waveConfig_.npc) do
			-- 检查成长参数
			if nil == npcConfig_.attrGrow or 0 >= checknumber(npcConfig_.attrGrow) then
				log = log .. self:GetErrorLog(string.format('enemy attrGrow cannot be 0 -> stageId:%d, npcId:%d', checkint(enemyId), checkint(npcConfig_.npcId)))
			end
			if nil == npcConfig_.skillGrow or 0 >= checknumber(npcConfig_.skillGrow) then
				log = log .. self:GetWaringLog(string.format('enemy skillGrow is 0 -> stageId:%d, npcId:%d', checkint(enemyId), checkint(npcConfig_.npcId)))
			end
			-- 检查站位配置
			if nil == battlePositionConfigtable[tostring(npcConfig_.placeId)] then
				log = log .. self:GetWaringLog(string.format('cannot find battle position in enemy -> stageId:%d, npcId:%d, placeId:%d', checkint(enemyId), checkint(npcConfig_.npcId), checkint(npcConfig_.placeId)))
			end
			-- 检查怪物配置
			monsterConfig = monsterConfigtable[tostring(npcConfig_.npcId)]
			log = log .. self:CheckMonsterConfig(checkint(npcConfig_.npcId), monsterConfig)
		end
	end

	return log
end
--[[
检查所有天气配置
--]]
function DebugConfigScene:CheckAllWeatherConfig()
	local log = ''

	local weatherConfigtable = self:ConvertJsonToLuaByFilePath(self:GetConfigPath('quest', 'weather'))
	local weatherConfig = nil

	for weatherId_, weatherConfig_ in pairs(weatherConfigtable) do
		weatherConfig = weatherConfigtable[tostring(weatherId_)]
		log = log .. self:CheckWeatherConfig(checkint(weatherId_), weatherConfig)
	end

	print(log)
end
--[[
检查单个天气配置
@params weatherId int 天气id
@params weatherConfig table 天气配置
@return log str 天气查错log
--]]
function DebugConfigScene:CheckWeatherConfig(weatherId, weatherConfig)
	local log = '\n\n>>>>>>>>>>> start check weather id -> ' .. weatherId .. ' ......'

	if nil == weatherConfig then
		log = log .. self:GetErrorLog(string.format('cannot find weather config -> stageId:%d', checkint(weatherId)))
		return log
	end

	-- 技能查错
	if #weatherConfig.skillId > 0 then
		local skillConfigtable = self:ConvertJsonToLuaByFilePath(self:GetConfigPath('card', 'skill'))
		local skillConfig = nil

		for _, skillId_ in ipairs(weatherConfig.skillId) do
			skillConfig = skillConfigtable[tostring(skillId_)]
			log = log .. self:CheckSkillConfig(checkint(skillId_), skillConfig)
		end
	end

	return log
end
--[[
检查所有怪物配置
--]]
function DebugConfigScene:CheckAllMonsterConfig()
	local log = ''

	local monsterConfigtable = self:ConvertJsonToLuaByFilePath(self:GetConfigPath('monster', 'monster'))

	for monsterId_, monsterConfig_ in pairs(monsterConfigtable) do
		log = log .. self:CheckMonsterConfig(checkint(monsterId_), monsterConfig_)
	end

	print(log)
end
--[[
检查单个怪物配置
@params monsterId int 怪物id
@params monsterConfig table 怪物配置
@return log str 怪物查错log
--]]
function DebugConfigScene:CheckMonsterConfig(monsterId, monsterConfig)
	local log = '\n\n>>>>>>>>>>> start check monster id -> ' .. monsterId .. ' ......'

	local skinConfigtable = self:ConvertJsonToLuaByFilePath(self:GetConfigPath('monster', 'monsterSkin'))

	if nil == monsterConfig then
		log = log .. self:GetErrorLog(string.format('cannot find monster config -> monsterId:%d', checkint(monsterId)))
		return log
	end

	-- 怪物血量不能为0
	if 0 == checknumber(monsterConfig.hp) then
		log = log .. self:GetErrorLog(string.format('monster hp cannot be 0 -> monsterId:%d', checkint(monsterId)))
	end

	-- 技能查错
	if #monsterConfig.skill > 0 then
		local skillConfigtable = self:ConvertJsonToLuaByFilePath(self:GetConfigPath('card', 'skill'))
		local skillConfig = nil

		for _, skillId_ in ipairs(monsterConfig.skill) do
			skillConfig = skillConfigtable[tostring(skillId_)]
			log = log .. self:CheckSkillConfig(checkint(skillId_), skillConfig)
		end
	end

	-- 皮肤查错
	local skinId = checkint(monsterConfig.skinId)
	local skinConfig = skinConfigtable[tostring(skinId)]
	if nil == skinConfig then
		log = log .. self:GetErrorLog(string.format('cannot find monster skin -> monsterId:%d, skinId:%d', checkint(monsterId), skinId))
	else
		------------ old field ------------
		if tostring(monsterConfig.drawId) ~= tostring(skinConfig.drawId) then
			-- log = log .. self:GetErrorLog(string.format('drawId:%s in monster config not match drawId:%s in monster skin config -> monsterId:%d, skinId:%d', tostring(monsterConfig.drawId), tostring(skinConfig.drawId), checkint(monsterId), skinId))
		end
		------------ old field ------------

		log = log .. self:CheckSkinConfigAndResource(skinId, skinConfig, monsterId)
	end

	return log
end
--[[
技能
--]]
function DebugConfigScene:CheckAllCardSkillConfig()
	local skillConfigtable = self:ConvertJsonToLuaByFilePath(self:GetConfigPath('card', 'skill'))

	local log = '------------ check all skills start ... ------------'

	for skillId_, skillConfig_ in pairs(skillConfigtable) do
		log = log .. self:CheckSkillConfig(checkint(skillId_), skillConfig_)
	end

	log = log .. '\n------------ check all skills over ... ------------'

	print(log)
end
--[[
根据技能配表内容查单条技能
@params skillId int 技能id
@params skillConfig table 技能表配置
@params cardId int 卡牌id 查特效用
@return log str 技能log
--]]
function DebugConfigScene:CheckSkillConfig(skillId, skillConfig)
	local log = ''
	-- 技能配置需要存在
	if nil == skillConfig then
		log = log .. self:GetErrorLog(string.format('cannot find skill config -> skillId:%d', skillId))
		return log
	end

	local skillGrowConfigtable = self:ConvertJsonToLuaByFilePath(self:GetConfigPath('card', 'skillEffect'))
	local skillGrowConfig = skillGrowConfigtable[tostring(skillId)]

	-- 技能成长配置不存在
	if nil == skillGrowConfig then
		log = log .. self:GetWaringLog(string.format('cannot find skill grow config -> skillId:%d', skillId))
	end

	local buffTypeConfigtable = self:ConvertJsonToLuaByFilePath(self:GetConfigPath('card', 'skillType'))

	-- 逻辑查错
	for buffType_, buffInfo_ in pairs(skillConfig.type) do
		-- buff类型表中不存在该buff类型
		if nil == buffTypeConfigtable[tostring(buffType_)] then
			log = log .. self:GetErrorLog(string.format('cannot find buff type in buff type config -> skillId:%d, buffType:%d', skillId, checkint(buffType_)))
		end
		-- 索敌规则一一对应
		if nil == skillConfig.target[buffType_] or nil == skillConfig.target[buffType_].type then
			log = log .. self:GetErrorLog(string.format('find error in target search rule -> skillId:%d, buffType:%d', skillId, checkint(buffType_)))
		end

		-- 效果检测
		if ConfigBuffType.ISD == checkint(buffType_) or ConfigBuffType.DOT == checkint(buffType_) then
			-- 效果需要两个值
			if 2 > #buffInfo_.effect then
				log = log .. self:GetErrorLog(string.format('buff type effect need two values -> skillId:%d, buffType:%d', skillId, checkint(buffType_)))
			end
		elseif ConfigBuffType.EXECUTE == checkint(buffType_) then
			-- 效果需要三个值
			if 3 > #buffInfo_.effect then
				log = log .. self:GetErrorLog(string.format('buff type effect need three value -> skillId:%d, buffType:%d', skillId, checkint(buffType_)))
			end
		elseif (checkint(buffType_) >= ConfigBuffType.ATTACK_B and checkint(buffType_) <= ConfigBuffType.GDAMAGE_A) or
			(checkint(buffType_) > ConfigBuffType.DOT and checkint(buffType_) <= ConfigBuffType.DOT_OHP) or 
			(checkint(buffType_) >= ConfigBuffType.HOT and checkint(buffType_) <= ConfigBuffType.HOT_OHP) or 
			(checkint(buffType_) >= ConfigBuffType.IMMUNE and checkint(buffType_) <= ConfigBuffType.SHIELD) or
			checkint(buffType_) == ConfigBuffType.FREEZE or checkint(buffType_) == ConfigBuffType.ENCHANTING or checkint(buffType_) == ConfigBuffType.ENERGY_CHARGE_RATE then
			-- 效果时间为0无意义
			if 0 >= checknumber(buffInfo_.effectTime) then
				log = log .. self:GetErrorLog(string.format('buff type effect time cannot be 0 -> skillId:%d, buffType:%d', skillId, checkint(buffType_)))
			end
		end

		-- 弱点技能必须配置读条时间
		if ConfigSkillType.SKILL_WEAK == checkint(skillConfig.property) then
			if 0 >= checknumber(skillConfig.readingTime) then
				log = log .. self:GetErrorLog(string.format('boss reading time cannot be 0 -> skillId:%d', skillId))
			end
		end
	end

	return log
end
--[[
根据皮肤id皮肤信息查单条皮肤配置 资源信息
@params skinId int 皮肤id
@params skinConfig table 皮肤配置
@params cardId int 卡牌id
--]]
function DebugConfigScene:CheckSkinConfigAndResource(skinId, skinConfig, cardId)
	local log = ''
	if nil == skinConfig then
		log = log .. self:GetErrorLog(string.format('cannot find skin config -> skinId:%d', checkint(skinId)))
		return log
	end

	local drawLocationtable = self:ConvertJsonToLuaByFilePath(self:GetConfigPath('card', 'coordinate'))

	-- 检查皮肤资源
	if not ((400000 > checkint(skinConfig.drawId) and 390000 < checkint(skinConfig.drawId)) or (330000 > checkint(skinConfig.drawId) and 320000 < checkint(skinConfig.drawId))) then
		-- 立绘
		local drawPath = string.format('cards/card/card_draw_%s.png', tostring(skinConfig.drawId))

		if not utils.isExistent(_res(drawPath)) then
			log = log .. self:GetErrorLog(string.format('#card resource# cannot find draw image -> skinId:%d, skinName:%s, drawId:%s', checkint(skinId), tostring(skinConfig.name), tostring(skinConfig.drawId)))
		else
			-- 立绘坐标 只有boss 卡牌才会检查这一项
			local checkLocation = false
			if cardId < 300000 then
				checkLocation = true
			else
				local monsterConfig = self:ConvertJsonToLuaByFilePath(self:GetConfigPath('monster', 'monster'))[tostring(cardId)]
				if 3 == checkint(monsterConfig.type) then
					checkLocation = true
				end
			end
			
			if checkLocation then
				local locationConfig = drawLocationtable[tostring(skinConfig.drawId)]
				if nil == locationConfig then
					log = log .. self:GetErrorLog(string.format('#card resource# cannot find draw location config -> skinId:%d, skinName:%s, drawId:%s', checkint(skinId), tostring(skinConfig.name), tostring(skinConfig.drawId)))
				end
			end
		end
	end

	-- 怪物检查q版
	if 300000 < cardId then
		local qPath = string.format('arts/cartoon/card_q_%d.png', checkint(skinConfig.drawId))
		if not utils.isExistent(_res(qPath)) then
			log = log .. self:GetErrorLog(string.format('#card resource# cannot find monster q draw -> skinId:%d, skinName:%s, drawId:%s', checkint(skinId), tostring(skinConfig.name), tostring(skinConfig.drawId)))
		end
	end

	-- 头像
	if not (330000 > checkint(skinConfig.drawId) and 320000 < checkint(skinConfig.drawId)) then
		local headPath = string.format('cards/head/card_icon_%s.png', tostring(skinConfig.drawId))
		if not utils.isExistent(_res(headPath)) then
			log = log .. self:GetErrorLog(string.format('#card resource# cannot find head icon -> skinId:%d, skinName:%s, drawId:%s', checkint(skinId), tostring(skinConfig.name), tostring(skinConfig.drawId)))
		end
	end

	-- spine
	local spinePath = string.format('cards/spine/avatar/%s.json', tostring(skinConfig.spineId))
	if not utils.isExistent(_res(spinePath)) then
		log = log .. self:GetErrorLog(string.format('#card resource# cannot find card spine -> skinId:%d, skinName:%s, spineId:%s', checkint(skinId), tostring(skinConfig.name), tostring(skinConfig.spineId)))
	end

	-- 检查特效配置
	local cardConfig = self:ConvertJsonToLuaByFilePath(self:GetConfigPath('card', 'card'))[tostring(cardId)]
	if 300000 < checkint(cardId) then
		cardConfig = self:ConvertJsonToLuaByFilePath(self:GetConfigPath('monster', 'monster'))[tostring(cardId)]
	end

	local effectconfigtable = self:ConvertJsonToLuaByFilePath(self:GetConfigPath('card', 'skillEffectType'))
	local effectConfig = effectconfigtable[tostring(cardId)]

	if nil == effectConfig then
		-- 对应cardId的特效不存在
		log = log .. self:GetErrorLog(string.format('cannot find card effect config -> cardId:%d', cardId))
	else
		effectConfig = effectconfigtable[tostring(cardId)][tostring(skinId)]
		if nil == effectConfig then
			log = log .. self:GetErrorLog(string.format('cannot find card effect config -> cardId:%d, skinId:%d', cardId, checkint(skinId)))	
		else
			-- 检查普攻特效
			if nil == effectConfig[tostring(-1)] or 0 == checkint(effectConfig[tostring(-1)].effectId) then
				log = log .. self:GetWaringLog(string.format('cannot find card effect config -> type:-1, cardId:%d, skinId:%d', cardId, checkint(skinId)))	
			end
			if cardConfig.skill then
				-- 检查技能特效
				for i,v in ipairs(cardConfig.skill) do
					local skillId = checkint(v)
					if nil == effectConfig[tostring(skillId)] or 0 == checkint(effectConfig[tostring(skillId)].effectId) then
						log = log .. self:GetWaringLog(string.format('cannot find card effect config -> type:%d, cardId:%d, skinId:%d', skillId, cardId, checkint(skinId)))	
					end
				end
			end
		end
	end

	return log
end
--[[
检查所有机器人配置
--]]
function DebugConfigScene:CheckAllRobotConfig()
	local log = ''

	local robotConfigtable = self:ConvertJsonToLuaByFilePath(self:GetConfigPath('arena', 'robotNpc'))

	for robotTeamId, v in pairs(robotConfigtable) do

		log = log .. '\n\n@@@@@@@@@@@@@@@@@@@@@@@@@@@ start check robot team id -> ' .. robotTeamId .. ' ......'

		for i, cardId_ in ipairs(v.robotNpc) do
			local cardId = checkint(cardId_)
			local skinId = checkint(v.skinId[i])

			if 0 == skinId then
				log = log .. self:GetErrorLog(string.format('robot card has no skin -> robotTeamId:%d, cardId:%d', checkint(robotTeamId), checkint(cardId)))
			else
				log = log .. self:CheckRobotConfig(cardId, skinId)
			end
		end
	end

	print(log)
end
--[[
检查单个机器人
@params cardId int 卡牌id
@params skinId int 皮肤id
--]]
function DebugConfigScene:CheckRobotConfig(cardId, skinId)
	local log = '\n\n>>>>>>>>>>> start check robot card id -> ' .. cardId .. ' ......'

	if 300000 < cardId then
		log = log .. self:GetErrorLog(string.format('card id was a monster -> cardId:%d', cardId))
	else
		local skinConfig = self:ConvertJsonToLuaByFilePath(self:GetConfigPath('goods', 'cardSkin'))[tostring(skinId)]
		if nil == skinConfig then
			log = log .. self:GetErrorLog(string.format('cannot find skin config in robot config -> cardId:%d, skinId:%d', cardId, skinId))
		elseif cardId ~= checkint(skinConfig.cardId) then
			log = log .. self:GetErrorLog(string.format('skin is not match card -> cardId:%d, skinId:%d, skinCardId:%d', cardId, skinId, checkint(skinConfig.cardId)))
		end
	end

	return log
end
---------------------------------------------------
-- check logic end --
---------------------------------------------------

---------------------------------------------------
-- utils function begin --
---------------------------------------------------
--[[
获取配表路径
@params modelName str 模块名
@params configName str 配表名
@return path str 配表路径
--]]
function DebugConfigScene:GetConfigPath(modelName, configName)
	return 'src/conf/' .. LANGUAGE_TAG .. '/' .. modelName .. '/' .. configName .. '.json'
end
--[[
根据路径获取配表缓存key
@params path str 配表路径
@return configtableKey str 
--]]
function DebugConfigScene:GetConfigCacheKeyByPath(path)
	local configtableKey = nil
	local ss = string.split(path, '/')
	configtableKey = ss[#ss - 1] .. string.split(ss[#ss], '.')[1]
	return configtableKey
end
--[[
获取指定路径的配表lua结构
@params filePath str 文件路径
@return _ table 配表lua结构
--]]
function DebugConfigScene:ConvertJsonToLuaByFilePath(filePath)
	local configtableKey = self:GetConfigCacheKeyByPath(filePath)
	if nil == self.configtables[configtableKey] then
		local file = assert(io.open(filePath, 'r'), self:GetErrorLog(string.format('cannot find config json file -> %s', filePath)))
		local fileContent = file:read('*a')
		local configtable = json.decode(fileContent)
		file:close()
		self.configtables[configtableKey] = configtable
	end
	return self.configtables[configtableKey]
end

--[[
警告输出
@params content str 输出内容
--]]
function DebugConfigScene:GetWaringLog(content)
	local log = ''
	if not SHOW_WARING then return log end
	log = log .. '\n\n↓↓↓WARING↓↓↓\n     ' .. content .. '\n'
	return log
end
--[[
错误输出
@params content str 输出内容
--]]
function DebugConfigScene:GetErrorLog(content)
	local log = ''
	log = log .. '\n\n--------------------\n↓↓↓ERROR↓↓↓\n--------------------\n     ' .. content .. '\n'
	return log
end
---------------------------------------------------
-- utils function end --
---------------------------------------------------

return DebugConfigScene

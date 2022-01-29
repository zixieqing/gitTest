--[[
战斗构造器改
--]]
local BattleConstructor = class('BattleConstructor')

------------ import ------------
------------ import ------------

------------ define ------------
MAX_TEAM_MEMBER_AMOUNT = 5
MAX_EQUIP_PET_AMOUNT = 1
------------ define ------------

--[[
constructor
--]]
function BattleConstructor:ctor( ... )
	local args = unpack({...})

	self.battleConstructorData = nil
end

---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
初始化校验器战斗
@params stageId int 关卡id
@params constructorJson json 由客户端传入的构造器json
@params friendTeamJson json 友方阵容json
@params enemyTeamJson json 敌方阵容json
@params isCalculator bool 是否是战报生成器
--]]
function BattleConstructor:InitCheckerData(stageId, constructorJson, friendTeamJson, enemyTeamJson, isCalculator)
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
		ConfigBattleResultType.NORMAL, -- 结算类型
		stageCompleteInfo, -- list(StageCompleteSturct) 过关条件
		isCalculator == true,
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
		nil, -- list 背景图信息
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
	dump(self.battleConstructorData, 'InitCheckerData', 10)
end
---------------------------------------------------
-- init end --
---------------------------------------------------

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

	------------ 初始属性信息 ------------
	local hpPercent = checknumber(cardData.hpPercent or 1)
	local hpValue = (nil ~= cardData.hpValue) and checkint(cardData.hpValue) or nil
	local energyPercent = (nil ~= cardData.energyPercent) and checknumber(cardData.energyPercent) or nil
	local energyValue = nil
	------------ 初始属性信息 ------------

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
根据战斗类型获取战斗类型的配置信息
@params questBattleType QuestBattleType
@return _ table
--]]
function BattleConstructor:GetBattleConfigByQuestBattleType(questBattleType)
	return CommonUtils.GetConfig('common', 'specialBattle', questBattleType)
end
---------------------------------------------------
-- battle parameter end --
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
function BattleConstructor:SetBattleConstructData(data)
	self.battleConstructorData = data
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
判断卡牌id是否合法
@params cardId int 卡牌id
@return invalid bool 是否合法
--]]
function BattleConstructor:IsCardIdValid(cardId)
	local valid = true
	if nil == cardId or 0 == cardId then
		valid = false
	end
	return valid
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
根据构造器转换后的数据计算传给服务器的constructorJson
@param luaUse bool 是否是供lua使用 是 返回table 否 返回约定好的string
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
end
---------------------------------------------------
-- calc end --
---------------------------------------------------

return BattleConstructor

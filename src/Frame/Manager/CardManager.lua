--[[
 * author : zhaofei
 * descpt : 卡牌管理者
]]
__Require('battle.battleStruct.BaseStruct')
__Require('battle.controller.BattleConstants')
local BaseManager = require('Frame.Manager.ManagerBase')
---@class CardManager
local CardManager = class('CardManager', BaseManager)

SkillEffectTargetAmountAttribute = {
	['1'] = 1,
	['2'] = 1,
	['3'] = 1.5,
	['4'] = 2,
	['5'] = 2.5,
}

SkillEffectAttribute = {
	[tostring(ConfigBuffType.SILENT)]        = 5,
	[tostring(ConfigBuffType.IMMUNE)]        = 20,
	[tostring(ConfigBuffType.SHIELD)]        = 1,
	[tostring(ConfigBuffType.STUN)]          = 10,
	[tostring(ConfigBuffType.FREEZE)]        = 10,
	[tostring(ConfigBuffType.DISPEL_DEBUFF)] = 7,
	[tostring(ConfigBuffType.DISPEL_BUFF)]   = 7,
}

CardSkinCollTypeAll = 0

-------------------------------------------------
-- manager method

CardManager.DEFAULT_NAME = 'CardManager'
CardManager.instances_   = {}


function CardManager.GetInstance(instancesKey)
	instancesKey = instancesKey or CardManager.DEFAULT_NAME

	if not CardManager.instances_[instancesKey] then
		CardManager.instances_[instancesKey] = CardManager.new(instancesKey)
	end
	return CardManager.instances_[instancesKey]
end


function CardManager.Destroy(instancesKey)
	instancesKey = instancesKey or CardManager.DEFAULT_NAME

	if CardManager.instances_[instancesKey] then
		CardManager.instances_[instancesKey]:release()
		CardManager.instances_[instancesKey] = nil
	end
end


-------------------------------------------------
-- life cycle

function CardManager:ctor(instancesKey)
	self.super.ctor(self)

	if CardManager.instances_[instancesKey] then
		funLog(Logger.INFO, "注册相关的facade类型" )
	else
		self:initial()
	end
end


function CardManager:initial()
	self.isInitedOpenedConfData_     = false
	self.onGoingCardSkinCollTaskMap_ = {} -- 所有正在进行中的卡牌皮肤任务
	self.completedCardSkinTaskMap_   = {} -- 已完成的卡牌皮肤任务
	self.cardSkinCollNumMap_         = {} -- 所有类型的皮肤已收集数量
	
	-- 所有卡牌皮肤任务
	self.skinCollTaskMap_ = {} 
	for _, taskConf in pairs(CONF.CARD.SKIN_COLL_TASK:GetAll()) do
		if not self.skinCollTaskMap_[checkint(taskConf.group)] then
			self.skinCollTaskMap_[checkint(taskConf.group)] = {}
		end
		table.insert(self.skinCollTaskMap_[checkint(taskConf.group)], taskConf)
	end

	for _, groupTaskConfs in pairs(self.skinCollTaskMap_) do
		table.sort(groupTaskConfs, function(taskConfA, taskConfB)
			local afterTaskIdA = checkint(taskConfA.afterTaskId)
			local afterTaskIdB = checkint(taskConfB.afterTaskId)
			if afterTaskIdA == 0 or afterTaskIdB == 0 then
				return afterTaskIdB == 0
			else
				return afterTaskIdA < afterTaskIdB
			end
		end)
	end
end


function CardManager:release()
	self.skinCollTaskMap_ = {}

	self.onGoingCardSkinCollTaskMap_ = {}
	self.completedCardSkinTaskMap_   = {}
	self.cardSkinCollNumMap_         = {}
end


function CardManager:checkOpenedConfData_()
	if not self.isInitedOpenedConfData_ then
		self.openedSkinIdMap_ = {} -- 所有开放的 皮肤id 定义
		self.openedCardIdMap_ = {} -- 所有开放的 卡牌id 定义

		local openedSkinIdConfs = isChinaSdk() and CONF.CARD.TRIGGER_RES or CONF.CARD.CARD_SKIN
		local openedCardIdConfs = isChinaSdk() and CONF.CARD.TRIGGER_RES or CONF.CARD.CARD_INFO

		for skinId, skinConf in pairs(CONF.CARD.CARD_SKIN:GetAll()) do
			if openedSkinIdConfs:GetValue(checkint(skinConf.spineId)) then
				self.openedSkinIdMap_[checkint(skinId)] = true
			end
		end

		for cardId, cardConf in pairs(CONF.CARD.CARD_INFO:GetAll()) do
			if openedCardIdConfs:GetValue(cardId) then
				self.openedCardIdMap_[checkint(cardId)] = true
			end
		end

		self.isInitedOpenedConfData_ = true
	end
end


---------------------------------------------------
-- card expression begin --
-- 战斗公式 卡牌静态时的状态
---------------------------------------------------
--[[
根据玩家卡牌数据库id获取卡牌属性集合
@params id int 卡牌数据库id
@return result map 修正后的属性 {
	[ObjP] = number,
	[ObjP] = number
}
--]]
function CardManager.GetCardAllFixedPById(id)
	local cardData = app.gameMgr:GetCardDataById(id)
	return CardUtils.GetCardAllFixedPByCardData(cardData)
end
---------------------------------------------------
-- card expression end --
---------------------------------------------------

---------------------------------------------------
-- card draw config begin --
---------------------------------------------------

--[[
	TODO
根据卡牌皮肤id获取卡牌立绘 头像 spine信息
@params skinId int 卡牌皮肤id
@return cardDrawInfo CardObjDrawInfoStruct 资源信息
--]]
function CardManager.GetCardDrawPathInfoBySkinId(skinId)
	local drawId       = nil
	local headId       = nil
	local drawBgId     = nil
	local drawFgId     = nil
	local teamDrawBgId = nil
	local spineId      = nil
	local spineSkinId  = nil

	local skinConf = CardUtils.GetCardSkinConfig(skinId)
	if nil == skinConf then
		print('>>> error <<< -> can not find skin config in #CardManager.GetCardDrawPathInfoBySkinId#', skinId)
		drawId      = CardUtils.DEFAULT_DRAW_ID
		headId      = CardUtils.DEFAULT_HEAD_ID
		drawBgId    = nil
		drawFgId    = nil
		spineId     = CardUtils.DEFAULT_SPINE_ID
		spineSkinId = nil
	else

		-- !!!debug!!! --
		-- drawId = tostring(skinConf.photoId)
		-- headId = drawId
		-- drawBgId = tostring(skinConf.photoId)
		-- drawFgId = drawBgId
		-- teamDrawBgId = drawBgId
		-- spineId = tostring(skinConf.cardId)
		-- spineSkinId = nil
		-- !!!debug!!! --

		drawId       = tostring(skinConf.drawId)
		headId       = drawId
		drawBgId     = tostring(skinConf.drawBackGroundId)
		drawFgId     = drawBgId
		teamDrawBgId = drawBgId
		spineId      = tostring(skinConf.spineId)
		spineSkinId  = tostring(skinConf.spineSkinId)

		-- 为spine动画的皮肤id做一次处理 如果为空串则置为空
		if nil ~= spineSkinId and 0 == string.len(string.gsub(spineSkinId, ' ', '')) then
			spineSkinId = nil
		end
	end

	-- 创建数据结构
	local cardDrawInfo = CardObjDrawInfoStruct.New(
		AssetsUtils.GetCardDrawPath(drawId),
		AssetsUtils.GetCardHeadPath(headId),
		AssetsUtils.GetCardDrawBgPath(drawBgId),
		AssetsUtils.GetCardDrawFgPath(drawFgId),
		AssetsUtils.GetCardTeamBgPath(teamDrawBgId),
		AssetsUtils.GetCardSpinePath(spineId),
		spineSkinId
	)
	return cardDrawInfo
end

--[[
	根据 卡牌配表id 获取 卡牌皮肤id
	@params cardId 	int 	卡牌配表id
	@return skinId 	int 	卡牌皮肤id
--]]
function CardManager.GetCardSkinIdByCardId(cardId)
	local cardSkinId = 0
	local cardData   = app.gameMgr:GetCardDataByCardId(cardId)
	if cardData and cardData.defaultSkinId then
		cardSkinId = checkint(cardData.defaultSkinId)
	else
		cardSkinId = CardUtils.GetCardSkinId(cardId)
	end
	return cardSkinId > 0 and cardSkinId or CardUtils.DEFAULT_SKIN_ID
end


--[[
	获取卡牌的总数量
--]]
function CardManager.GetAllCardsSkinNums()
	local cardsData = CommonUtils.GetConfigAllMess('card','card')
	local count = 0
	for i, v in pairs(cardsData) do
		-- specialCard 等于1是联动卡
		if not (checkint(v.specialCard) == 1) then  --如果不是联动卡
			local num = table.nums(v.skin) -- 获取单个的卡牌舒数量
			count  = count + num
		end
	end
	return count
end

--[[
	获取联动卡牌数量
]]
function CardManager.GetLinkCardNum()
    local cardsData = CommonUtils.GetConfigAllMess('card' , 'card')
    local count = 0
    for cardId,  cardData in pairs(cardsData) do
        -- specialCard 为1表示联动卡牌
        if checkint(cardData.specialCard) == 1 then
            count = count +1
        end
    end
    return count
end


--[[
	获取卡牌的总数量
]]
function CardManager.GetAllCardsNum()
	local cardConfs = CommonUtils.GetConfigAllMess('card' , 'card')
	return table.nums(cardConfs) - CardManager.GetLinkCardNum()
end


--[[
根据卡牌id 皮肤id 动作id(攻击-1 技能为技能id) 获取spine动画动作名
@params cardId int 卡牌id
@params skinId int 皮肤id
@params actionName int 动作id
--]]
function CardManager.GetCardSpineAnimationName(cardId, skinId, actionId)
	local cardEffectConfig = CardUtils.GetCardEffectConfigBySkinId(cardId, skinId)

	if nil == cardEffectConfig then
		return sp.AnimationName.idle
	end

	local actionName = sp.AnimationName.idle

	local effectConfig = cardEffectConfig[tostring(actionId)]
	if nil ~= effectConfig then
		local actionId_ = checkint(effectConfig.actionId)
		if -1 == actionId_ then
			actionName = sp.AnimationName.attack
		else
			actionName = sp.AnimationName.skill .. tostring(actionId_)
		end
	end

	return actionName
end
---------------------------------------------------
-- card draw config end --
---------------------------------------------------

---------------------------------------------------
-- card config begin --
---------------------------------------------------

--[[
获取卡牌星级
@params cardId int card id
@params params table {
	breakLevel int 突破等级
}
@return star int 卡牌星级
--]]
function CardManager.GetCardStar(cardId, params)
	return checkint(params.blv or params.breakLevel)
end
--[[
获取当前卡牌最高等级
等级限制 角色等级必定大于等于卡牌等级 突破等级限制卡牌等级
@params cardId int 卡牌id
@params playerLevel int 主角等级
@params breakLv int 突破等级
--]]
function CardManager.GetCardMaxLevelByCardId(cardId, playerLevel, breakLv)
	local configMaxLevel = table.nums(CommonUtils.GetConfigAllMess('level', 'player'))

	local cardConf = CommonUtils.GetConfig('cards', 'card', cardId)
	local maxLevel = configMaxLevel

	-- 如果主角等级小于配表最高级 则以主角等级为最高
	if playerLevel < maxLevel then
		maxLevel = playerLevel
	end

	-- 当前突破等级对应的最高等级
	local breakMaxLevel = checkint(cardConf.breakLevel[breakLv + 1])
	if breakMaxLevel < maxLevel then
		maxLevel = breakMaxLevel
	end

	return maxLevel
end

--[[
获取技能描述
@params skillId int 技能id
@params skillLevel = 1 int 技能等级
@return str string 修正后的技能描述
--]]
function CardManager.GetSkillDescr(skillId, skillLevel)
	if nil == BattleConstants then __Require('battle.controller.BattleConstants') end
	local errorLog = nil
	if DEBUG ~= 2 then
		errorLog = ''
	end
	local skillConf = CommonUtils.GetSkillConf(skillId)
	if nil == skillConf then
		return errorLog or 'cannot find skill config #skillId# -> ' .. skillId
	end

	local fixedSkillEffect = CardUtils.GetFixedSkillEffect(skillId, skillLevel or 1)

	local str = skillConf.descr

	------------ 替换target number ------------
	local tmpSplitStr = nil
	local btype = 0
	local bEffect = 0
	for targetnum_ in string.gfind(skillConf.descr, '_target_num_' .. '[0-9]+_[0-9]*_?') do
		local fixedValue = 0
		local fixedStr = ''
		tmpSplitStr = string.split(targetnum_, '_')

		-- 数组下标4开始
		btype = tmpSplitStr[4]
		if nil == btype or 0 == checkint(btype) then
			return errorLog or 'config error in #skillId# -> ' .. skillId .. ' cannot find #type# -> ' .. btype .. ' in target number'
		end
		bEffect = checkint(tmpSplitStr[5])
		if 0 == bEffect then
			bEffect = 1
		end

		-- 获取修正值
		if nil == skillConf.type[btype] then
			return errorLog or 'config error in #skillId# -> ' .. skillId .. ' cannot find #type# -> ' .. btype .. ' in skill config'
		end

		if nil == skillConf.type[btype].effect[bEffect] then

			fixedStr = ''

		else

			fixedValue = math.abs(checknumber(fixedSkillEffect[btype].effect[bEffect]))
			btype = checkint(btype)
			if 0 == fixedValue then

				fixedStr = ''

			elseif ConfigBuffType.ATTACK_A == btype or ConfigBuffType.DEFENCE_A == btype or ConfigBuffType.OHP_A == btype or
				ConfigBuffType.CR_RATE_A == btype or ConfigBuffType.ATK_RATE_A == btype or ConfigBuffType.CR_DAMAGE_A == btype or
				ConfigBuffType.CDAMAGE_A == btype or ConfigBuffType.GDAMAGE_A == btype or ConfigBuffType.ISD_LHP == btype or ConfigBuffType.ISD_CHP == btype or
				ConfigBuffType.ISD_OHP == btype or ConfigBuffType.HEAL_LHP == btype or ConfigBuffType.HEAL_OHP == btype or
				ConfigBuffType.GET_DAMAGE_ATTACK == btype or ConfigBuffType.GET_DAMAGE_SKILL == btype or ConfigBuffType.GET_DAMAGE_PHYSICAL == btype or
				ConfigBuffType.CAUSE_DAMAGE_ATTACK == btype or ConfigBuffType.CAUSE_DAMAGE_SKILL == btype or ConfigBuffType.CAUSE_DAMAGE_PHYSICAL == btype then

				-- 以上 buff 需要转成百分数
				fixedStr = tostring(fixedValue * 100) .. '%%'

			elseif bEffect == 1 and (ConfigBuffType.ISD == btype or ConfigBuffType.HEAL_BY_ATK == btype
				or ConfigBuffType.HEAL_BY_DFN == btype or ConfigBuffType.HEAL_BY_CHP == btype or ConfigBuffType.EXECUTE == btype) then

				-- 以上 buff 是乘法系数 需要转成百分数
				fixedStr = tostring(fixedValue * 100) .. '%%'

			elseif ConfigBuffType.DOT == btype then

				-- dot 类型 配表中是总值 展示需要转换成每秒值
				local dotTime = checknumber(fixedSkillEffect[tostring(btype)].effectTime)
				if 0 == dotTime then
					return errorLog or 'dot time cannot be 0 #skillId# -> ' .. skillId .. ' #btype# -> ' .. btype
				end
				if 1 == bEffect then
					-- 乘法系数
					fixedStr = tostring(fixedValue * 100) .. '%%'
				else
					fixedStr = tostring(fixedValue)
				end

			elseif ConfigBuffType.HOT == btype then

				-- hot 类型 配表中是总值 展示需要转换成每秒值 hot 和 dot 不同 只有加法系数
				local dotTime = checknumber(fixedSkillEffect[tostring(btype)].effectTime)
				if 0 == dotTime then
					return errorLog or 'dot time cannot be 0 #skillId# -> ' .. skillId .. ' #btype# -> ' .. btype
				end
				fixedStr = tostring(fixedValue)

			elseif ConfigBuffType.DOT_CHP == btype or ConfigBuffType.DOT_OHP == btype or ConfigBuffType.HOT_LHP == btype or
				ConfigBuffType.HOT_OHP == btype then

				local dotTime = checknumber(fixedSkillEffect[tostring(btype)].effectTime)
				if 0 == dotTime then
					return errorLog or 'dot time cannot be 0 #skillId# -> ' .. skillId .. ' #btype# -> ' .. btype
				end
				-- 以上 buff 需要转成百分数
				fixedStr = tostring(fixedValue * 100) .. '%%'

			elseif bEffect == 3 and ConfigBuffType.EXECUTE == btype then

				-- 斩杀有三号参数 血量百分比
				fixedStr = tostring(fixedValue * 100) .. '%%'

			elseif ConfigBuffType.REVIVE == btype then

				-- 复活 百分比
				fixedStr = tostring(fixedValue * 100) .. '%%'
			elseif  ConfigBuffType.ENHANCE_NEXT_SKILL == btype then
				fixedStr = tostring(fixedValue * 100) .. '%%'
			else

				fixedStr = tostring(fixedValue)

			end

		end
		str = string.gsub(str, targetnum_, fixedStr)
	end
	------------ 替换target number ------------

	------------ 替换target time ------------
	tmpSplitStr = nil
	btype = 0
	bEffect = 0
	for targettime_ in string.gfind(skillConf.descr, '_target_time_' .. '%d+_') do
		local fixedValue = ''
		tmpSplitStr = string.split(targettime_, '_')

		-- 数组下标4开始
		btype = tmpSplitStr[4]
		if nil == btype or 0 == checkint(btype) then
			return errorLog or 'config error in #skillId# -> ' .. skillId .. ' cannot find #type# -> ' .. btype .. ' in target time'
		end

		-- 获取修正值
		if nil == skillConf.type[btype] then
			return errorLog or 'config error in #skillId# -> ' .. skillId .. ' cannot find #type# -> ' .. btype .. ' in skill config'
		end

		fixedValue = checknumber(fixedSkillEffect[btype].effectTime or 0)
		if 0 == fixedValue then
			str = string.gsub(str, targettime_, '')
		else
			str = string.gsub(str, targettime_, tostring(fixedValue))
		end
	end
	------------ 替换target time ------------

	return str
end
--[[
根据技能id和技能等级获取卡牌技能描述
@params skillId int 技能id
@params skillLevel int 技能等级
@return skillDescr string 技能描述
--]]
function CardManager.GetSkillDescrNew(skillId, skillLevel)
	skillId = checkint(skillId)
	local skillConfig = CommonUtils.GetSkillConf(skillId)
	if nil == skillConfig then
		return 'cannot find skill config -> skillId: ' .. tostring(skillId)
	end

	-- 判断一次id 是否需要走拼接逻辑
	local skillSectionType = CommonUtils.GetSkillSectionTypeBySkillId(skillId)

	if not (SkillSectionType.CARD_NORMAL_SKILL == skillSectionType or
		SkillSectionType.ARTIFACT_TALENT_SKILL == skillSectionType or
		SkillSectionType.ARTIFACT_TALENT_SKILL_2 == skillSectionType or
		SkillSectionType.ARTIFACT_GEMSTONE_SKILL == skillSectionType or
		SkillSectionType.ARTIFACT_GEMSTONE_SKILL_2 == skillSectionType or
		SkillSectionType.UNION_PET_SKILL == skillSectionType or
		SkillSectionType.CARD_CONNECT_SKILL == skillSectionType) then

		-- 非法技能 直接返回描述
		return skillConfig.descr

	end

	------------ 检查全局变量 ------------
	if nil == BattleConstants then __Require('battle.controller.BattleConstants') end
	local errorLog = nil
	if DEBUG ~= 2 then
		errorLog = ''
	end
	------------ 检查全局变量 ------------

	------------ 定义占位符 ------------
	local TARGET_TIME_MARK = '_target_time_'
	------------ 定义占位符 ------------

	------------ 定义函数 ------------
	local SplitByRE = function (targetStr, expression)
		local result = {}
		for str in string.gfind(targetStr, expression) do
			table.insert(result, str)
		end
		return result
	end
	------------ 定义函数 ------------

	local fixedSkillEffect = CardUtils.GetFixedSkillEffect(skillId, skillLevel or 1)
	local skillDescr = tostring(skillConfig.descr or '')

	local sk = sortByKey(skillConfig.type)
	local buffType = nil
	local buffFixedEffect = nil
	local seekRuleInfo = nil

	for i, v in ipairs(sk) do
		buffType = checkint(v)
		buffFixedEffect = fixedSkillEffect[tostring(buffType)]
		seekRuleInfo = skillConfig.target[tostring(buffType)]

		if nil == seekRuleInfo then
			return 'cannot find buff target info -> skillId: ' .. tostring(skillId) .. ', buffType: ' .. tostring(buffType)
		end

		local buffDescrConfig = CommonUtils.GetConfig('cards', 'buffDescr', buffType)
		local seekRuleDescrConfig = CommonUtils.GetConfig('cards', 'ruleEnemyTypeDescr', checkint(seekRuleInfo.type))
		local seekRuleSortDescrConfig = CommonUtils.GetConfig('cards', 'ruleEnemySortDescr', checkint(seekRuleInfo.sequence))

		local buffDescr = buffDescrConfig and tostring(buffDescrConfig.descr) or ''

		------------ 生成索敌的描述 ------------
		local seekRuleSortDescr = ''
		local seekRuleAmountDescr = ''

		if ConfigSeekTargetRule.T_OBJ_SELF == checkint(seekRuleInfo.type) then

			-- 索敌类型为自身 不显示其他文字

		elseif 5 <= checkint(seekRuleInfo.num) then

			-- 超过5个当成全体处理 不显示排序规则 不显示人数
			seekRuleAmountDescr = '全体'

		else

			seekRuleSortDescr = seekRuleSortDescrConfig.descr
			seekRuleAmountDescr = string.fmt(__('_sd_seekRule_1_个'), {['_sd_seekRule_1_'] = tostring(seekRuleInfo.num)})

		end

		local seekRuleDescr = seekRuleSortDescr .. seekRuleAmountDescr .. tostring(seekRuleDescrConfig.descr)

		buffDescr = string.gsub(buffDescr, '_target_seekRule_', seekRuleDescr)
		------------ 生成索敌的描述 ------------

		------------ 处理buff时间 ------------
		if ConfigSkillType.SKILL_HALO == skillConfig.property then
			-- 光环类型直接删除整条时间信息
			buffDescr = string.gsub(buffDescr, '%[.+%]', '')
		else
			-- 删掉中括号
			buffDescr = string.gsub(buffDescr, '[%[%]]', '')
			-- 替换时间
			buffDescr = string.gsub(buffDescr, TARGET_TIME_MARK, checknumber(buffFixedEffect.effectTime))
		end
		------------ 处理buff时间 ------------

		------------ 处理buff效果值的数量 ------------
		-- buff效果[1]和[2]的值为0时删掉对应的整段说明
		local cutWhenValueIsZeroOneorTwo = {
			[ConfigBuffType.ISD] = true,
			[ConfigBuffType.DOT] = true,
			[ConfigBuffType.HEAL_BY_ATK] = true,
			[ConfigBuffType.HEAL_BY_DFN] = true,
			[ConfigBuffType.HEAL_BY_CHP] = true,
			[ConfigBuffType.HEAL_BY_CHP] = true,
			[ConfigBuffType.REVIVE] = true,
			[ConfigBuffType.EXECUTE] = true
		}

		local valueStrs = SplitByRE(buffDescr, '#[^#]+#')
		local fixedValueStrs = {}

		if true == cutWhenValueIsZeroOneorTwo[buffType] then
			if 0 == checknumber(buffFixedEffect.effect[1]) then

				-- 第一个值为零 删除第一段
				local str1 = ''
				table.insert(fixedValueStrs, str1)

				-- 第二个值删除'并'
				local str2 = string.gsub(valueStrs[2], '|.+|', '')
				str2 = string.gsub(str2, '#', '')
				table.insert(fixedValueStrs, str2)

			elseif 0 == checknumber(buffFixedEffect.effect[2]) then

				-- 第二个值为零 删除第二段
				local str2 = ''

				-- 第一个值删除#
				local str1 = string.gsub(valueStrs[1], '#', '')

				table.insert(fixedValueStrs, str1)
				table.insert(fixedValueStrs, str2)

			else

				-- 都不为零 删除多余的占位符
				local str1 = string.gsub(valueStrs[1], '#', '')
				table.insert(fixedValueStrs, str1)

				local str2 = string.gsub(valueStrs[2], '[|]+', '')
				table.insert(fixedValueStrs, str2)

			end

			for i,v in ipairs(fixedValueStrs) do
				buffDescr = string.gsub(buffDescr, valueStrs[i], fixedValueStrs[i])
			end
		end
		------------ 处理buff效果值的数量 ------------

		------------ 处理buff效果值 ------------
		local multiSignBuffType = {
			[ConfigBuffType.ATTACK_B] = true,
			[ConfigBuffType.ATTACK_A] = true,
			[ConfigBuffType.DEFENCE_B] = true,
			[ConfigBuffType.DEFENCE_A] = true,
			[ConfigBuffType.OHP_B] = true,
			[ConfigBuffType.OHP_A] = true,
			[ConfigBuffType.CR_RATE_B] = true,
			[ConfigBuffType.CR_RATE_A] = true,
			[ConfigBuffType.ATK_RATE_B] = true,
			[ConfigBuffType.ATK_RATE_A] = true,
			[ConfigBuffType.CR_DAMAGE_B] = true,
			[ConfigBuffType.CR_DAMAGE_A] = true,
			[ConfigBuffType.CDAMAGE_A] = true,
			[ConfigBuffType.GDAMAGE_A] = true,
			[ConfigBuffType.ENERGY_ISTANT] = true,
			[ConfigBuffType.ENERGY_CHARGE_RATE] = true,
			[ConfigBuffType.GET_DAMAGE_ATTACK] = true,
			[ConfigBuffType.GET_DAMAGE_SKILL] = true,
			[ConfigBuffType.GET_DAMAGE_PHYSICAL] = true,
			[ConfigBuffType.CAUSE_DAMAGE_ATTACK] = true,
			[ConfigBuffType.CAUSE_DAMAGE_SKILL] = true,
			[ConfigBuffType.CAUSE_DAMAGE_PHYSICAL] = true
		}

		local percentValue = {
			[ConfigBuffType.ATTACK_A] = {[1] = true},
			[ConfigBuffType.DEFENCE_A] = {[1] = true},
			[ConfigBuffType.OHP_A] = {[1] = true},
			[ConfigBuffType.CR_RATE_A] = {[1] = true},
			[ConfigBuffType.ATK_RATE_A] = {[1] = true},
			[ConfigBuffType.CR_DAMAGE_A] = {[1] = true},
			[ConfigBuffType.CDAMAGE_A] = {[1] = true},
			[ConfigBuffType.GDAMAGE_A] = {[1] = true},
			[ConfigBuffType.ISD_LHP] = {[1] = true},
			[ConfigBuffType.ISD_CHP] = {[1] = true},
			[ConfigBuffType.ISD_OHP] = {[1] = true},
			[ConfigBuffType.DOT_CHP] = {[1] = true},
			[ConfigBuffType.DOT_OHP] = {[1] = true},
			[ConfigBuffType.HEAL_LHP] = {[1] = true},
			[ConfigBuffType.HEAL_OHP] = {[1] = true},
			[ConfigBuffType.HOT_LHP] = {[1] = true},
			[ConfigBuffType.HOT_OHP] = {[1] = true},
			[ConfigBuffType.GET_DAMAGE_ATTACK] = {[1] = true},
			[ConfigBuffType.GET_DAMAGE_SKILL] = {[1] = true},
			[ConfigBuffType.GET_DAMAGE_PHYSICAL] = {[1] = true},
			[ConfigBuffType.CAUSE_DAMAGE_ATTACK] = {[1] = true},
			[ConfigBuffType.CAUSE_DAMAGE_SKILL] = {[1] = true},
			[ConfigBuffType.CAUSE_DAMAGE_PHYSICAL] = {[1] = true},

			[ConfigBuffType.ISD] = {[1] = true},
			[ConfigBuffType.DOT] = {[1] = true},
			[ConfigBuffType.HEAL_BY_ATK] = {[1] = true},
			[ConfigBuffType.HEAL_BY_DFN] = {[1] = true},
			[ConfigBuffType.HEAL_BY_CHP] = {[1] = true},
			[ConfigBuffType.EXECUTE] = {[1] = true, [3] = true},
			[ConfigBuffType.REVIVE] = {[1] = true, [2] = true}
		}

		for valueStr in string.gfind(buffDescr, '_target_num_' .. '[%d_]+') do
			local len = string.len(valueStr)
			local valueIndex = checkint(string.sub(valueStr, len - 1, len - 1))
			local value = checknumber(buffFixedEffect.effect[valueIndex])
			local valueStr_ = nil

			-- 修正一次value格式 判断是否是百分数
			if nil ~= percentValue[buffType] and true == percentValue[buffType][valueIndex] then
				valueStr_ = tostring(math.abs(value) * 100) .. '%%'
			else
				valueStr_ = tostring(math.abs(value))
			end

			if true == multiSignBuffType[buffType] then
				-- 需要根据正负加上前缀
				if 0 > value then
					-- 为负
					valueStr_ = '降低' .. valueStr_
				else
					-- 为正
					valueStr_ = '提高' .. valueStr_
				end
			end

			buffDescr = string.gsub(buffDescr, valueStr, valueStr_)
		end

		------------ 处理buff效果值 ------------

		------------ buff概率 ------------
		if 1 > checknumber(skillConfig.type[tostring(buffType)].effectSuccessRate) then
			buffDescr = '有概率' .. buffDescr
		end
		------------ buff概率 ------------

		------------ 第二个buff效果开始加上连词 ------------
		if 1 < i then
			buffDescr = '。同时' .. buffDescr
		end
		------------ 第二个buff效果开始加上连词 ------------

		skillDescr = skillDescr .. buffDescr
	end

	return skillDescr
end
--[[
将卡牌动作配表值转换为spine文件中的动作名
@params v int 配表值
@return _ string 动作名字
--]]
function CardManager.ConvertValue2SpineAnimationName(v)
	v = checkint(v)
	if -1 == v then
		return sp.AnimationName.attack
	elseif 0 < v then
		return sp.AnimationName.skill .. tostring(v)
	else
		return sp.AnimationName.idle
	end
end
--[[
根据卡牌id获取卡牌战斗力
@params id int 卡牌id
@return result int 战斗力数值
--]]
function CardManager.GetCardStaticBattlePointById(id)
	local result = 0
	local cardData = app.gameMgr:GetCardDataById(id)

	if nil == cardData or 0 == checkint(cardData.cardId) then
		return result
	else
		return CardManager.GetCardStaticBattlePointByCardData(cardData)
	end
end
--[[
根据卡牌信息获取战斗力
@params cardData table 卡牌信息
@params isOthers bool 是否他人的卡牌数据
--]]
function CardManager.GetCardStaticBattlePointByCardData(cardData, isOthers)
	local result = 0
	if nil == cardData or 0 == checkint(cardData.cardId) then
		return result
	else

		if 0 == checkint(cardData.playerPetId) or isOthers then
			-- 他人卡牌 新卡牌数据结构 直接计算
			return CardUtils.GetCardStaticBattlePointByCardData(cardData)
		elseif 0 ~= checkint(cardData.playerPetId) then

			local cardId = checkint(cardData.cardId)

			-- 自己的卡牌
			local p_id = checkint(cardData.playerPetId)
			local petData = app.gameMgr:GetPetDataById(p_id)
			local petAddPData = nil

			if nil ~= petData then

				local activeExclusive = PetUtils.IsActiveExclusive(checkint(petData.petId), cardId)
				local petPInfo = app.petMgr.GetPetAllFixedProps(p_id, activeExclusive)
				petAddPData = PetUtils.GetPetPropertyAdditionByConvertedData(petPInfo)

			end

			local artifactAddPData = ArtifactUtils.GetArtifactPropertyAddition(cardId, cardData.artifactTalent)

			local bookAddData = CardUtils.GetCardBookPropertyAddition(cardData.bookLevel)
			local catBuffAddData = CatHouseUtils.GetCatBuff(cardData.equippedHouseCatGene)

			local fixedCardPInfo = CardUtils.GetCardAllFixedPByAdditionInfo(
				cardId,
				checkint(cardData.level),
				checkint(cardData.breakLevel),
				checkint(cardData.favorabilityLevel),
				petAddPData,
				artifactAddPData,
				checktable(cardData.bookLevel)
			)

			result = CardUtils.GetCardStaticBattlePointByPropertyInfo(fixedCardPInfo)

		end

		return result
	end
end
--[[
检查目标卡牌在该阵容中是否能激活连携技
@params cardId int 卡牌id
@params formation table 阵容
@params skillId int 连携技id
@return _ bool 是否可用
--]]
function CardManager.IsConnectSkillEnable(cardId, formation, skillId)
	local skinConf = nil
	local cardConf = CardUtils.GetCardConfig(cardId)
	skillId = skillId or CardUtils.GetCardConnectSkillId(cardId)
	if skillId then
		for _,connectCardId in ipairs(cardConf.concertSkill) do
			local exist = false
			for i,v in ipairs(formation) do
				local targetCardId = checkint(v.cardId)
				if nil == v.cardId and nil ~= v.id then
					local cardData = app.gameMgr:GetCardDataById(v.id)
					if nil ~= cardData then
						targetCardId = checkint(cardData.cardId)
					end
				end
				if nil == v.cardId and nil ~= v.skinId then
					skinConf = CardUtils.GetCardSkinConfig(v.skinId)
					targetCardId = checkint(skinConf.cardId)
				end
				if checkint(connectCardId) == targetCardId then
					exist = true
				end
			end
			if not exist then
				return false
			end
		end
	end
	return true
end
---------------------------------------------------
-- card config end --
---------------------------------------------------

---------------------------------------------------
-- beast begin --
---------------------------------------------------
--[[
根据神兽id获取神兽配表信息
@params id int 神兽id
@return _ table 神兽配表信息
--]]
function CardManager.GetBeastConfig(id)
	return CommonUtils.GetConfig('union', 'godBeast', id)
end
--[[
根据神兽id获取幼崽id
@params id int 神兽id
@return beastBabyId int 幼崽id
--]]
function CardManager.GetBeastBabyIdByBeastId(id)
	local beastConfig = CardManager.GetBeastConfig(id)
	local beastBabyId = nil
	if nil ~= beastConfig then
		beastBabyId = checkint(beastConfig.petId)
	end
	return beastBabyId
end
--[[
获取神兽幼崽配表信息
@params id int 神兽幼崽id
@return _ table 神兽幼崽配表信息
--]]
function CardManager.GetBeastBabyConfig(id)
	return UnionBeastUtils:GetUnionPetConfig(id)
end
--[[
根据神兽id获取神兽幼崽配表信息
@params beastId int 神兽id
@return _ table 神兽幼崽配表信息
--]]
function CardManager.GetBeastBabyConfigByBeastId(beastId)
	return CommonUtils.GetConfig('union', 'godBeastAttr', CardManager.GetBeastBabyIdByBeastId(beastId))
end
--[[
根据神兽id 神兽等级获取神兽的总血量
@params id int 神兽id
@params level int 神兽等级
@return hp, monsterId, wave int, int, int 神兽血量 对应的怪物id  波数
--]]
function CardManager.GetBeastTotalHpByIdAndLevel(id, level)
	local stageId = CommonUtils.GetBeastQuestIdByIdAndLevel(id, level)
	return CardManager.GetShareBossTotalHpByQuestId(stageId)
end
--[[
根据关卡id获取世界boss模式boss总血量
@params questId int 关卡id
--]]
function CardManager.GetShareBossTotalHpByQuestId(questId)
	local stageId = checkint(questId)
	local stageConfig = CommonUtils.GetQuestConf(questId)
	if nil == stageConfig then
		print('here find an error when calc beast total hp : cannot find stage config -> stageId : ' .. stageId)
		return 1
	else
		local enemyConfig = CommonUtils.GetConfig('quest', 'enemy', stageId)
		if nil == enemyConfig then
			print('here find an error when calc beast total hp : cannot find enemy config -> stageId : ' .. stageId)
			return 1
		else
			if nil ~= enemyConfig['1'] then
				for i,v in ipairs(enemyConfig['1'].npc) do
					local monsterId = checkint(v.npcId)
					local monsterConfig = CardUtils.GetCardConfig(monsterId)
					if nil ~= monsterConfig then
						local hp = checkint(monsterConfig.hp)
						hp = hp * checknumber(v.attrGrow)
						print('here check fuck beast hp <<<<<<<<<<<<<', hp, v.attrGrow, checkint(monsterConfig.hp))
						return hp
					end
				end
			end
		end
	end
	return 1
end
--[[
根据神兽幼崽id获取神兽id
@params beastBabyId int 神兽幼崽id
@return _ int 神兽id
--]]
function CardManager.GetBeastIdByBeastBabyId(beastBabyId)
	local beastBabyConfig = CardManager.GetBeastBabyConfig(beastBabyId)
	if nil ~= beastBabyConfig.godBeastId then
		return checkint(beastBabyConfig.godBeastId)
	else
		return 1
	end
end
--[[
根据神兽幼崽id 幼崽能量等级 饱食等级获取幼崽外观皮肤
@params id int id
@params energyLevel int 能量等级
@params satietyLevel int 饱食等级
@return skinId int 皮肤id
--]]
function CardManager.GetBeastBabySkinId(id, energyLevel, satietyLevel)
	local formConfig = CommonUtils.GetConfig('union', 'godBeastForm', id)
	if nil ~= formConfig and formConfig.breakLevel then
		for i = #formConfig.breakLevel, 1, -1 do
			if checkint(energyLevel) >= checkint(formConfig.breakLevel[i]) then
				return checkint(formConfig.form[tostring(i)].skinId)
			end
		end
	end
	return 259061
end
--[[
根据神兽幼崽id 幼崽能量等级 饱食等级获取幼崽外观信息
@params id int id
@params energyLevel int 能量等级
@params satietyLevel int 饱食等级
@return formConfig table 外观信息
--]]
function CardManager.GetBeastBabyFormConfig(id, energyLevel, satietyLevel)
	local formConfig = CommonUtils.GetConfig('union', 'godBeastForm', id)
	if nil ~= formConfig and formConfig.breakLevel then
		for i = #formConfig.breakLevel, 1, -1 do
			if checkint(energyLevel) >= checkint(formConfig.breakLevel[i]) then
				return formConfig.form[tostring(i)]
			end
		end
	end
	return nil
end
--[[
获取神兽幼崽战斗力
@params id int id
@params energyLevel int 能量等级
@params satietyLevel int 饱食等级
@return battlePoint int 战斗力
--]]
function CardManager.GetBeastBabyBattlePoint(id, energyLevel, satietyLevel)
	local beastBabyFixedPInfo = CardManager.GetBeastBabyAllFixedP(id, energyLevel, satietyLevel)
	local propertyBattlePoint = math.floor(
		beastBabyFixedPInfo[ObjP.ATTACK] * 10 +
		beastBabyFixedPInfo[ObjP.DEFENCE] * 16.7 +
		beastBabyFixedPInfo[ObjP.HP] * 1 +
		(beastBabyFixedPInfo[ObjP.CRITRATE] - 100) * 0.17 +
		(beastBabyFixedPInfo[ObjP.CRITDAMAGE] - 100) * 0.118 +
		(beastBabyFixedPInfo[ObjP.ATTACKRATE] - 100) * 0.109
	)
	return propertyBattlePoint
end
--[[
根据神兽幼崽等级 经验 获取升到下一次需要的经验信息
@params level int 等级
@params exp int 经验
@return nextLevel, curExp, curNeedExp int, int, int 下一级, 当前经验条获取的经验, 当前经验条需要的全部经验值
--]]
function CardManager.GetBeastBabyNextEnergyLevelInfo(level, exp)
	local expConfig = CommonUtils.GetConfig('union', 'petEnergyLevel', level)
	local nextExpConfig = CommonUtils.GetConfig('union', 'petEnergyLevel', level + 1)
	if expConfig == nil or nil == nextExpConfig then
		-- 等级表中不存在等级配置
		return level, -1, -1
	else
		local nextLevel = level + 1
		local curExp = exp - checknumber(expConfig.totalExp)
		local curNeedExp = checknumber(nextExpConfig.exp)
		return nextLevel, curExp, curNeedExp
	end
end
--[[
根据神兽幼崽等级 经验 获取升到下一次需要的经验信息
@params level int 等级
@params exp int 经验
@return nextLevel, curExp, curNeedExp int, int, int 下一级, 当前经验条获取的经验, 当前经验条需要的全部经验值
--]]
function CardManager.GetBeastBabyNextSatietyLevelInfo(level, exp)
	local expConfig = CommonUtils.GetConfig('union', 'petSatietyLevel', level)
	local nextExpConfig = CommonUtils.GetConfig('union', 'petSatietyLevel', level + 1)
	if expConfig == nil or nil == nextExpConfig then
		-- 等级表中不存在等级配置
		return level, -1, -1
	else
		local nextLevel = level + 1
		local curExp = exp - checknumber(expConfig.totalExp)
		local curNeedExp = checknumber(nextExpConfig.exp)
		return nextLevel, curExp, curNeedExp
	end
end
--[[
根据菜品id 菜谱等级 获取喂食神兽幼崽增加的饱食度
@params foodId int 菜品id
@params recipeGrade int 菜谱等级
@return _ int 变化的饱食度
--]]
function CardManager.GetDeltaSatietyByFoodInfo(foodId, recipeGrade)
	local feedConfig = CommonUtils.GetConfig('union', 'petFeed', recipeGrade)
	if nil ~= feedConfig then
		return checkint(feedConfig.satiety)
	else
		return 0
	end
end
--[[
根据菜品id 菜谱等级 获取喂食神兽幼崽获得的奖励
@params foodId int 菜品id
@params recipeGrade int 菜谱等级
--]]
function CardManager.GetFeedRewardByFoodInfo(foodId, recipeGrade)
	local feedConfig = CommonUtils.GetConfig('union', 'petFeed', recipeGrade)
	if nil ~= feedConfig then
		return {
			[UNION_CONTRIBUTION_POINT_ID] = checkint(feedConfig.contributionPoint),
			[UNION_POINT_ID] = checkint(feedConfig.unionPoint)
		}
	else
		return {
			[UNION_CONTRIBUTION_POINT_ID] = 0,
			[UNION_POINT_ID] = 0
		}
	end
end


UnionPetVoiceType = {
	ENTER 			= 1,
	AFTER_FEED 		= 2,
	IDLE 			= 3,
	AFTER_ENERGY 	= 4
}
--[[
根据类型获取神兽宝宝语音id
@params beastBabyId int 神兽幼崽id
@params voiceType UnionPetVoiceType 语音类型
@return _ int id
--]]
function CardManager.GetUnionBeastBabyVoiceConfigByVoiceType(beastBabyId, voiceType)
	local defaultVoice = {id = 0, descr = '...'}
	local voiceConfigT = CommonUtils.GetConfig('union', 'petVoice', beastBabyId)
	if nil == voiceConfigT then
		return defaultVoice
	else
		local t = voiceConfigT[tostring(voiceType)]
		if nil == t or 0 >= #t then
			return defaultVoice
		else
			return t[math.random(#t)]
		end
	end
end
--[[
获取神兽幼崽修正后的属性
@params beastBabyId int 幼崽id
@params energyLevel int 能量等级
@params satietyLevel int 饱食度等级
@return result table 修正后的属性集合
--]]
function CardManager.GetBeastBabyAllFixedP(beastBabyId, energyLevel, satietyLevel)
	local result = {}
	for k,v in pairs(CardUtils.GetCardInnatePConfig()) do
		result[v] = CardManager.GetBeastBabyAFixedP(beastBabyId, v, energyLevel, satietyLevel)
	end
	return result
end
--[[
获取神兽幼崽修正后的单条属性
>>> 神兽基础属性+(神兽等级-1)*等级区间1系数+(神兽等级-20)*等级区间2系数+…+(神兽等级-20*(n-1))*等级区间n系数
>>> 备注:神兽等级-20*(n-1)若小于等于0,则不进行计算
@params beastBabyId int 幼崽id
@params p ObjP 属性类型
@params energyLevel int 能量等级
@params satietyLevel int 饱食度等级
--]]
function CardManager.GetBeastBabyAFixedP(beastBabyId, p, energyLevel, satietyLevel)
	local beastBabyConfig = CardManager.GetBeastBabyConfig(beastBabyId)
	local baseP = checknumber(beastBabyConfig[CardUtils.GetCardPCommonName(p)])
	local fixedP = baseP

	local beastBabyGrowConfig = CommonUtils.GetConfig('union', 'godBeastGrow', beastBabyId)

	-- 成长计算从2级开始 1级为基础值
	for lv = 2, energyLevel, 1 do
		if nil ~= beastBabyGrowConfig[tostring(lv)] then
			fixedP = fixedP + beastBabyGrowConfig[tostring(lv)][CardUtils.GetCardPCommonName(p)]
		end
	end
	return fixedP
end
--[[
获取神兽幼崽能量的说明
@return _ string
--]]
function CardManager.GetBeastBabyEnergyDescr()
	return __('通过工会活动中的工会狩猎，参与和幼体对应的远古堕神的狩猎，可以获得远古堕神的能量。能量可以增加远古堕神的能量值，当能量值达到一定数值后，可以提升幼体的能量等级，能量等级越高，远古堕神幼体的6项属性就越高。')
end
--[[
获取神兽幼崽饱食度说明
@return _ string
--]]
function CardManager.GetBeastBabySatietyDescr()
	return __('通过对远古堕神的幼体喂食菜品来增加其饱食度，当饱食度达到一定数值后，饱食度的等级提升，饱食度等级越高，远古堕神幼体的技能属性就越强。')
end
--[[
获取神兽幼崽喜欢菜品的说明
@return _ string
--]]
function CardManager.GetBeastBabyFavorFoodDescr()
	return __('1.对幼体喂食菜品可获得工会币和贡献值的奖励,并增加饱食度。菜品品级越高,获得奖励越多,饱食度也越高。\n2.幼体每天有四道随机喜欢的菜品（菜品右上角标着星星图标）,喂食它喜欢菜品,可以获得普通菜品3倍的奖励和饱食度。')
end
--[[
获取神兽幼崽战斗力说明
--]]
function CardManager.GetBeastBabyBattlePoineDescr()
	return __('远古堕神幼体的6项属性决定了它的战斗力，属性越高，战斗力就越高。')
end
---------------------------------------------------
-- beast end --
---------------------------------------------------

---------------------------------------------------
-- marry begin --
---------------------------------------------------
--[[
获取结婚需要的资源
@return goodsId int 道具id
@return num int 数量
--]]
function CardManager.GetMarryCostConfig()
	return {
		goodsId = MAGIC_INK_ID,
		num = 1
	}
end
--[[
判断飨灵能否结婚
@params id int 卡牌id
--]]
function CardManager.GetMarriable(id)
	local cardData = app.gameMgr:GetCardDataById(id)
	if 5 == checkint(cardData.favorabilityLevel) then
		local nowLvExp = checkint(cardData.favorability)
		local needLvExp = CommonUtils.GetConfig('cards', 'favorabilityLevel',cardData.favorabilityLevel+1).totalExp or 999999
		if nowLvExp >= checkint(needLvExp) then
			return true and CommonUtils.GetModuleAvailable(MODULE_SWITCH.MARRY)
		end
	end
	return false
end
--[[
判断飨灵能否已经结婚
@params id int 卡牌id
--]]
function CardManager.GetCouple(id)
	local cardData = app.gameMgr:GetCardDataById(id)
	if CardManager.GetFavorabilityMax(checkint(cardData.favorabilityLevel)) then
		return true and CommonUtils.GetModuleAvailable(MODULE_SWITCH.MARRY)
	end
	return false
end
--[[
判断飨灵能否已经结婚
@params id int 卡牌id
--]]
function CardManager.IsLinkCardIdById(id)
	local cardData = app.gameMgr:GetCardDataById(id)
	return CardUtils.IsLinkCard(cardData.cardId)
end

--[[
判断好感度是否满级
@params favorabilityLevel int 好感度等级
--]]
function CardManager.GetFavorabilityMax(favorabilityLevel)
	if 6 == checkint(favorabilityLevel) then
		return true and CommonUtils.GetModuleAvailable(MODULE_SWITCH.MARRY)
	end
	return false
end

--[[
--判断是否拥有该卡
--]]
function CardManager.IsHaveCard(cardId)
	local bool = false
	if app.gameMgr:GetUserInfo().cards then
		for i, v in pairs(app.gameMgr:GetUserInfo().cards) do
			if checkint(cardId) == checkint(v.cardId) then
				bool = true
				break
			end
		end
	end
	return bool
end

--[[
--判断是否拥有该皮肤
--]]
function CardManager.IsHaveCardSkin(skinId)
	local bool = false
	if app.gameMgr:GetUserInfo().cardSkins then
		for i, v in ipairs(app.gameMgr:GetUserInfo().cardSkins) do
			if checkint(skinId) == checkint(v) then
				bool = true
				break
			end
		end
	end
	return bool
end
--[[
--配表中是否存该卡
--]]
function CardManager.IsExistConfCard(cardId )
	local bool = false
	local cardConfig =  CommonUtils.GetConfigAllMess('card','goods')
	local cardOneConfig = cardConfig[tostring(cardId)] or {}
	local name  = cardOneConfig.name
	if name  then
		bool = true
	end
	return bool
end
--[[
--获取全部 开放的飨灵皮肤id
--]]
function CardManager:getOpenedSkinIdsMap()
	self:checkOpenedConfData_()
	return checktable(self.openedSkinIdMap_)
end
--[[
--获取全部 开放的飨灵卡牌id
--]]
function CardManager:getOpenedCardIdsMap()
	self:checkOpenedConfData_()
	return checktable(self.openedCardIdMap_)
end

----------------------------------------------------------- 卡牌皮肤收集
--[[
--获取所有的皮肤收集任务
--]]
function CardManager:getAllSkinCollTaskConfsMap()
	return checktable(self.skinCollTaskMap_)
end
--[[
--根据 皮肤收集任务组别id 获取任务清单
--]]
function CardManager:getSkinCollTaskConfsByGroupId(groupId)
	return self:getAllSkinCollTaskConfsMap()[checkint(groupId)]
end
--[[
--根据 皮肤收集任务id 获取组别id
--]]
function CardManager:getSkinCollTaskGroupIdByTaskId(taskId)
	local skinCollTaskConf = CONF.CARD.SKIN_COLL_TASK:GetValue(taskId)
	return checkint(skinCollTaskConf.group)
end
--[[
--初始化皮肤收集任务的数据
--]]
function CardManager:initCardSkinCollTaskData(rewardIds)
	self.completedCardSkinTaskMap_ = {}
	if rewardIds and next(rewardIds) ~= nil then
		for _, taskId in ipairs(rewardIds) do
			local groupId = self:getSkinCollTaskGroupIdByTaskId(taskId)
			if not self.completedCardSkinTaskMap_[groupId] then
				self.completedCardSkinTaskMap_[groupId] = {}
			end
			self.completedCardSkinTaskMap_[groupId][checkint(taskId)] = true
		end
	end

	self.onGoingCardSkinCollTaskMap_ = {}
	for groupId, _ in pairs(self:getAllSkinCollTaskConfsMap()) do
        self:setOnGoingCardCollTaskMapByGroup(groupId)
    end


	self.cardSkinCollNumMap_ = {}
	for skinId, skinCollInfo in pairs(self:getOpenedSkinIdsMap()) do
        local skinConf = checktable(CardUtils.GetCardSkinConfig(skinId))
        if checkint(skinConf.skinAtlas) == 1 and CardManager.IsHaveCardSkin(skinId) then
            local skinType = CardUtils.GetSkinTypeBySkinId(skinId)

            self.cardSkinCollNumMap_[skinType] = checkint(self.cardSkinCollNumMap_[skinType]) + 1
            self.cardSkinCollNumMap_[CardSkinCollTypeAll] = checkint(self.cardSkinCollNumMap_[CardSkinCollTypeAll]) + 1
        end
	end
	
	self:GetFacade():DispatchObservers(SGL.SKIN_COLL_RED_DATA_UPDATE)
end

--[[
--获取/设置/判断 皮肤收集任务的结束状态
--]]
function CardManager:setCardSkinCollTaskCompleted(taskId, groupId)
	groupId = groupId or self:getSkinCollTaskGroupIdByTaskId(taskId)
	if not self.completedCardSkinTaskMap_[checkint(groupId)] then
		self.completedCardSkinTaskMap_[checkint(groupId)] = {}
	end
	self.completedCardSkinTaskMap_[checkint(groupId)][checkint(taskId)] = true

	self:setOnGoingCardCollTaskMapByGroup(groupId)
	self:GetFacade():DispatchObservers(SGL.SKIN_COLL_RED_DATA_UPDATE)
end

function CardManager:getCardSkinCollTaskCompletedMap()
	return checktable(self.completedCardSkinTaskMap_)
end

function CardManager:getCardSkinCollTaskCompletedDataByGroup(groupId)
	return checktable(self.completedCardSkinTaskMap_[checkint(groupId)])
end

function CardManager:isCardSkinCollTaskCompleted(taskId, groupId)
	groupId = groupId or self:getSkinCollTaskGroupIdByTaskId(taskId)

	return self:getCardSkinCollTaskCompletedDataByGroup(groupId)[checkint(taskId)] == true
end
--[[
--获取/设置 正在进行中的皮肤收集任务
--]]
function CardManager:getOnGoingCardCollTaskMap()
	return checktable(self.onGoingCardSkinCollTaskMap_)
end

function CardManager:setOnGoingCardCollTaskMapByGroup(groupId, taskId)
	if checkint(taskId) > 0 then
		self.onGoingCardSkinCollTaskMap_[checkint(groupId)] = checkint(taskId)
	else
		self.onGoingCardSkinCollTaskMap_[checkint(groupId)] = nil
		local taskConfs = self:getSkinCollTaskConfsByGroupId(checkint(groupId))
		if next(taskConfs) == nil then
			return
		end
	
		for index, taskConf in ipairs(taskConfs) do
			if not self:isCardSkinCollTaskCompleted(taskConf.id, taskConf.group) then
				if not taskConfs[index - 1] or checkint(taskConfs[index - 1].afterTaskId) == checkint(taskConf.id) then
					self:setOnGoingCardCollTaskMapByGroup(groupId, taskConf.id)
				end
				break
			end
		end
	end
end

--[[
--获取/设置 所有已收集的皮肤卡牌数量
--]]
function CardManager:setCardSkinCollNumByType(skinType, addNum)
	self.cardSkinCollNumMap_[checkint(skinType)] = checkint(self.cardSkinCollNumMap_[checkint(skinType)]) + checkint(addNum)

	self:GetFacade():DispatchObservers(SGL.SKIN_COLL_RED_DATA_UPDATE)
end

function CardManager:getCardSkinCollNumByType(skinType)
	return checkint(self.cardSkinCollNumMap_[checkint(skinType)])
end
---------------------------------------------------
-- cardAlbum begin --
---------------------------------------------------
--[[
飨灵收集册是否可领取
@params bookId   int  收集册id
--]]
function CardManager.IsCardAlbumBookCanDraw( bookId )
	local unlockData = app.gameMgr:GetUserInfo().cardCollectionBookMap
	local bookConf = CONF.CARD.CARD_COLL_BOOK:GetAll()
	local taskConf = CONF.CARD.CARD_COLL_TASK:GetAll()
	local cardIds = nil
	for k, v in pairs(bookConf) do
		if checkint(v.id) == checkint(bookId) then
			cardIds = v.cardIds
		end
	end
	if not cardIds then return end
	local unlockMap = {}
	for i, v in ipairs(unlockData[checkint(bookId)]) do
		unlockMap[tostring(v)] = v
	end
	for k, v in pairs(taskConf) do
		if not unlockMap[tostring(v.id)] then
			if CardManager.IsCardAlbumTaskComplete(v, cardIds) then
				return true
			end
		end
	end
	return false
end
--[[
判断飨灵收集册任务是否完成
@params taskData map  任务数据
@params cardIds  list 卡牌列表
@return isComplete bool 是否完成任务
@return progressNum int  任务进度
--]]
function CardManager.IsCardAlbumTaskComplete( taskData, cardIds )
	local progressNum = CardManager.CalculateCardAlbumTaskProgress(checkint(taskData.taskType), cardIds)
	return progressNum >= checkint(taskData.targetNum), progressNum
end
--[[
计算飨灵收集册任务进度
@params taskType CARD_COLL_TASK_TYPE 收集任务类型
@params cardIds  list 卡牌列表
@return progressNum int 任务进度
--]]
function CardManager.CalculateCardAlbumTaskProgress( taskType, cardIds )
    local progressNum = 0
    for _, cardId in ipairs(cardIds) do
        local cardData = app.gameMgr:GetCardDataByCardId(cardId)
        if cardData and next(cardData) ~= nil then
            if taskType == CardUtils.CARD_COLL_TASK_TYPE.COLL_NUM then
                progressNum = progressNum + 1
            elseif taskType == CardUtils.CARD_COLL_TASK_TYPE.STAR_NUM then
                progressNum = progressNum + checkint(cardData.breakLevel)
			elseif taskType == CardUtils.CARD_COLL_TASK_TYPE.ARTIFACT_OPEN_NUM then
				progressNum = progressNum + app.artifactMgr:GetCardArtifactAllBigActivaionPointCardData(cardData)
            elseif taskType == CardUtils.CARD_COLL_TASK_TYPE.LEVEL_NUM then
                progressNum = progressNum + checkint(cardData.level)
            end
        end
	end
	return progressNum
end
--[[
通过卡牌id获取飨灵全部收集册等级
@params id int 卡牌id
@return bookData map k:bookid, v:level
--]]
function CardManager.GetBookDataByCardId( cardId )
	local conf = CONF.CARD.CARD_COLL_BOOK:GetAll()
	local bookData = {}
	for k, v in pairs(conf) do
		for _, id in ipairs(v.cardIds) do
			if checkint(cardId) == checkint(id) then
				bookData[k] = CardManager.GetBookLevelByBookId(k)
			end
		end
	end
	return bookData
end
--[[
通过bookId获取飨灵收集册等级
@params bookId int 收集册id
@return level  int level
--]]
function CardManager.GetBookLevelByBookId( bookId )
	local unlockData = app.gameMgr:GetUserInfo().cardCollectionBookMap
	local level = 1 + table.nums(unlockData[checkint(bookId)])
	return level
end

function CardManager.GetPropertyDefine( propertyId )
	local PROPERTY_DATA = {
		[tostring(ObjP.ATTACK)]     = {name = __('攻击力'), path = 'ui/common/role_main_att_ico.png'},
		[tostring(ObjP.DEFENCE)]    = {name = __('防御力'), path = 'ui/common/role_main_def_ico.png'},
		[tostring(ObjP.HP)]         = {name = __('生命值'), path = 'ui/common/role_main_hp_ico.png'},
		[tostring(ObjP.CRITRATE)]   = {name = __('暴击值'), path = 'ui/common/role_main_baoji_ico.png'},
		[tostring(ObjP.CRITDAMAGE)] = {name = __('暴伤值'), path = 'ui/common/role_main_baoshangi_ico.png'},
		[tostring(ObjP.ATTACKRATE)] = {name = __('攻速值'), path = 'ui/common/role_main_speed_ico.png'},
	}
	return PROPERTY_DATA[tostring(propertyId)] or {}
end
---------------------------------------------------
-- cardAlbum end --
---------------------------------------------------
return CardManager

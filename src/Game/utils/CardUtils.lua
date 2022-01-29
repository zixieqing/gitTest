--[[
 * author : kaishiqi
 * descpt : 卡牌工具类
]]
CardUtils = {}


--================================================================================================
-- card define
--================================================================================================

-- 皮肤解锁类型
CardUtils.SKIN_UNLOCK_TYPE = {
	DEFAULT   = 1,  -- 默认解锁
	FIVE_STAR = 2,  -- 5星解锁
	OTHER     = 3,  -- 其他方式
}

-- 卡牌收集任务类型
CardUtils.CARD_COLL_TASK_TYPE = {
	COLL_NUM          = 1, -- 组合飨灵收集数量 / 获得组合内飨灵x个
	LEVEL_NUM         = 2, -- 组合飨灵等级 / 组合内飨灵等级总和达到x级
	ARTIFACT_OPEN_NUM = 3, -- 组合飨灵神器开启节点 / 组合内飨灵神器开启塔可节点总和达到x个
	STAR_NUM          = 4, -- 组合飨灵总星级 / 组合内飨灵星级总和达到x星
}

CardUtils.CARD_COLL_TASK_GROUP_ROOT = 0 -- all task group
CardUtils.CARD_COLL_TASK_TYPE_ROOT  = 0 -- all task type


-- 卡牌质量类型
CardUtils.QUALITY_TYPE = {
	N  = 1,
	R  = 2,
	SR = 3,
	UR = 4,
	SP = 5
}
-- 飨灵列表排序
CardUtils.CARD_ORDER_TYPE = {
	M         = 1,
	R         = 2,
	SR        = 3,
	UR        = 4,
	SP        = 5,
	LINK_CARD = 6
}


-- 卡牌职业类型
CardUtils.CAREER_TYPE = {
	BASE   = 0,  -- 基本类型
	DEFEND = 1,  -- 防御系（坦克）
	ATTACK = 2,  -- 力量系（近战）
	ARROW  = 3,  -- 魔法系（远程）
	HEART  = 4,  -- 辅助系（治疗）
}


-- 卡牌技能特性
CardUtils.CARD_SKILL_PROPERTY = {
	BASE     = '1',  -- 基础技
	ENERGY   = '2',  -- 能量技
	CONNECT  = '3',  -- 连携技
	MANAGER  = '4',  -- 经营技
	HALO     = '5',  -- 光环技
}


-- 卡牌六属性（FIXME）
ObjP = {
	ATTACK     = 1,  -- 攻击力
	DEFENCE    = 2,  -- 防御力
	HP         = 3,  -- 血量
	CRITRATE   = 4,  -- 暴击率
	CRITDAMAGE = 5,  -- 暴击伤害
	ATTACKRATE = 6,  -- 攻击速度
	ENERGY     = 7,  -- 能量
}
CardUtils.PROPERTY_TYPE = ObjP


CardUtils.PROPERTY_INFO = {
	[CardUtils.PROPERTY_TYPE.ATTACK]     = {name = 'attack'},
	[CardUtils.PROPERTY_TYPE.DEFENCE]    = {name = 'defence'},
	[CardUtils.PROPERTY_TYPE.HP]         = {name = 'hp'},
	[CardUtils.PROPERTY_TYPE.CRITRATE]   = {name = 'critRate'},
	[CardUtils.PROPERTY_TYPE.CRITDAMAGE] = {name = 'critDamage'},
	[CardUtils.PROPERTY_TYPE.ATTACKRATE] = {name = 'attackRate'},
	[CardUtils.PROPERTY_TYPE.ENERGY]     = {name = 'energy'},
}


-- 默认样式定义
CardUtils.DEFAULT_CARD_ID   = 200001    -- 默认卡牌 卡牌id
CardUtils.DEFAULT_SKIN_ID   = 250010    -- 默认卡牌 皮肤id
CardUtils.DEFAULT_HEAD_ID   = '200001'  -- 默认卡牌 头像id
CardUtils.DEFAULT_DRAW_ID   = '200001'  -- 默认卡牌 立绘id
CardUtils.DEFAULT_SPINE_ID  = '200001'  -- 默认卡牌 动画id
CardUtils.DEFAULT_SKIN_TYPE = 1         -- 默认卡牌 皮肤类型id（其他，@see CONF.CARD.SKIN_COLL_TYPE）

-- 编队背景路径
CardUtils.TEAM_BG_PATH_MAP = {
	['0'] = 'ui/home/teamformation/newCell/team_bg_tianjiawan.png',  -- 0 is default
	['1'] = 'ui/home/teamformation/newCell/team_bg_tianjiawan_n.png',
	['2'] = 'ui/home/teamformation/newCell/team_bg_tianjiawan_r.png',
	['3'] = 'ui/home/teamformation/newCell/team_bg_tianjiawan_sr.png',
}

-- 编队边框路径
CardUtils.TEAM_FRAME_PATH_MAP = {
	['1'] = 'ui/home/teamformation/newCell/team_frame_n.png',
	['2'] = 'ui/home/teamformation/newCell/team_frame_r.png',
	['3'] = 'ui/home/teamformation/newCell/team_frame_sr.png',
	['4'] = 'ui/home/teamformation/newCell/team_frame_ur.png',
	['5'] = 'ui/home/teamformation/newCell/team_frame_sp.png',
}

-- 质量文字路径
CardUtils.QUALITY_TEXT_PATH_MAP = {
	['1'] = 'ui/common/common_ico_text_m.png',
	['2'] = 'ui/common/common_ico_text_r.png',
	['3'] = 'ui/common/common_ico_text_sr.png',
	['4'] = 'ui/common/common_ico_text_ur.png',
	['5'] = 'ui/common/common_ico_text_sp.png',
}

-- 质量图标路径
CardUtils.QUALITY_ICON_PATH_MAP = {
	['1'] = 'ui/common/role_main_n_ico.png',
	['2'] = 'ui/common/role_main_r_ico.png',
	['3'] = 'ui/common/role_main_sr_ico.png',
	['4'] = 'ui/common/role_main_ur_ico.png',
	['5'] = 'ui/common/role_main_sp_ico.png'
}

-- 质量头像框路径
CardUtils.CAREER_HEAD_FRAME_PATH_MAP = {
	['1'] = 'ui/cards/head/kapai_frame_white.png',
	['2'] = 'ui/cards/head/kapai_frame_blue.png',
	['3'] = 'ui/cards/head/kapai_frame_purple.png',
	['4'] = 'ui/cards/head/kapai_frame_orange.png',
	['5'] = 'ui/cards/head/kapai_frame_red.png'
}

-- 职业图标路径
CardUtils.CAREER_ICON_PATH_MAP = {
	['1'] = 'ui/common/card_ico_battle_defend.png',
	['2'] = 'ui/common/card_ico_battle_attack.png',
	['3'] = 'ui/common/card_ico_battle_arrow.png',
	['4'] = 'ui/common/card_ico_battle_heart.png',
}

-- 职业图标框路径
CardUtils.CAREER_ICON_FRAME_PATH_MAP = {
	['1'] = 'ui/cards/head/card_order_ico_blue.png',
	['2'] = 'ui/cards/head/card_order_ico_red.png',
	['3'] = 'ui/cards/head/card_order_ico_purple.png',
	['4'] = 'ui/cards/head/card_order_ico_green.png',
}


-- 职业名字方法定义
CardUtils.CAREER_NAME_FUNCTION_MAP = {
	['1'] = function() return __('防御系') end,
	['2'] = function() return __('力量系') end,
	['3'] = function() return __('魔法系') end,
	['4'] = function() return __('辅助系') end,
}

-- 职业名字方法定义
CardUtils.SKILL_PROPERTY_NAME_FUNCTION_MAP = {
	[CardUtils.CARD_SKILL_PROPERTY.BASE]    = function() return __('基础技') end,
	[CardUtils.CARD_SKILL_PROPERTY.ENERGY]  = function() return __('能量技') end,
	[CardUtils.CARD_SKILL_PROPERTY.CONNECT] = function() return __('连携技') end,
	[CardUtils.CARD_SKILL_PROPERTY.MANAGER] = function() return __('经营技能') end,
	[CardUtils.CARD_SKILL_PROPERTY.HALO]    = function() return __('光环技') end,
}

--================================================================================================
-- basic method
--================================================================================================
CardUtils.PARAMETER_FUNC = {
	MAX_GROUP_NUM = function() return checkint(CONF.CARD.PARAMETER:GetValue('maxGroupNum')) end
}

function CardUtils.IsMonsterCard(cardId)
    cardId = checkint(cardId)
	local result = nil
	if cardId >= 200000 and cardId < 300000 then
		result = false
	elseif cardId >= 300000 then
		result = true
	else
		funLog(Logger.INFO,'!!! invalid card id ' .. tostring(cardId) .. ' cannot judge if is monster !!!')
	end
	return result
end


function CardUtils.IsMonsterSkin(skinId)
    skinId = checkint(skinId)
	local result = nil
	if 250000 < skinId and 259000 >= skinId then
		result = false
	elseif 259000 < skinId then
		result = true
	else
		funLog(Logger.INFO,'!!! invalid card skin id ' .. tostring(skinId) .. ' cannot judge if is monster !!!')
	end
	return result
end
--[[
	判断当前的卡是否为联动卡
--]]
function CardUtils.IsLinkCard(cardId)
	local cardOrderData = CommonUtils.GetConfigAllMess('cardOrder' , 'collection')[tostring(CardUtils.CARD_ORDER_TYPE.LINK_CARD)] or {}
	local isHave = cardOrderData[tostring(cardId)] and true or false
	return isHave
end
--[[
	根据 皮肤id 获取 卡牌id
	@params skinId 	int 	皮肤id
	@return cardId  int 	卡牌id
]]
function CardUtils.GetCardIdBySkinId(skinId)
	local cardId = nil
	local skinConf = CardUtils.GetCardSkinConfig(skinId)
    
	if nil == skinConf then
		print('>>> error <<< -> can not find skin config in #CardUtils.GetCardIdBySkinId#', skinId)
		cardId = CardUtils.DEFAULT_CARD_ID
	else
		cardId = tostring(skinConf.cardId)
	end
	return cardId
end



-------------------------------------------------
-- card conf
-------------------------------------------------

function CardUtils.GetCardConfig(cardId)
	if CardUtils.IsMonsterCard(cardId) then
		return CommonUtils.GetConfig('monster', 'monster', cardId)
	else
		return CommonUtils.GetConfig('cards', 'card', cardId)
	end
end


function CardUtils.GetCardSkinConfig(skinId)
    if CardUtils.IsMonsterSkin(skinId) then
        return CommonUtils.GetConfig('monster', 'monsterSkin', skinId)
    else
        return CommonUtils.GetConfig('goods', 'cardSkin', skinId)
    end
end


function CardUtils.GetSkillConfigBySkillId(skillId)
	local realConfName = string.format('skill%d', math.ceil(checkint(skillId) / 50))
	local skillConfig  = CommonUtils.GetConfig('cards', realConfName, skillId) or {}
	if nil == next(skillConfig) then
		-- 防止如果没分表的话，试着从总表里再获取一次
		skillConfig = CommonUtils.GetConfig('cards', 'skill', skillId)
	end
	return skillConfig
end


function CardUtils.GetSkillEffectConfigBySkillId(skillId)
	local realConfName      = string.format('skillEffect%d', math.ceil(checkint(skillId) / 50))
	local skillEffectConfig = CommonUtils.GetConfig('cards', realConfName, skillId) or {}
	if nil == next(skillEffectConfig) then
		-- 防止如果没分表的话，试着从总表里再获取一次
		skillEffectConfig = CommonUtils.GetConfig('cards', 'skillEffect', skillId)
	end
	return skillEffectConfig
end


function CardUtils.GetCardEffectConfigBySkinId(cardId, skinId)
	local realConfName     = string.format('skillEffectType%d', checkint(cardId))
	local effectSkinConfig = CommonUtils.GetConfig('cards', realConfName, cardId) or {}
	if nil == next(effectSkinConfig) then
		-- 防止如果没分表的话，试着从总表里再获取一次
		effectSkinConfig = CommonUtils.GetConfig('cards', 'skillEffectType', cardId) or {}
	end
	return effectSkinConfig[tostring(skinId)]
end


function CardUtils.GetVoiceLinesConfigByCardId(cardId)
	local realConfName = string.format('cardVoiceLines%d', checkint(cardId))
	local voicesConfig = CommonUtils.GetConfig('cards', realConfName, cardId) or {}
	if nil == next(voicesConfig) then
		-- 防止如果没分表的话，试着从总表里再获取一次
		voicesConfig = CommonUtils.GetConfig('cards', 'cardVoiceLines', cardId)
	end
	return voicesConfig
end


function CardUtils.GetCardStoryConfigByCardId(cardId, id)
	local realConfName = string.format('cardStory%d', checkint(cardId))
	local storyConfig  = CommonUtils.GetConfig('collection', realConfName, id) or {}
	if nil == next(storyConfig) then
		-- 防止如果没分表的话，试着从总表里再获取一次
		storyConfig = CommonUtils.GetConfig('collection', 'cardStory', id)
	end
	return storyConfig
end


function CardUtils.GetCardVoiceConfigByCardId(cardId, id)
	local realConfName = string.format('cardVoice%d', checkint(cardId))
	local voiceConfig  = CommonUtils.GetConfig('collection', realConfName, id) or {}
	if nil == next(voiceConfig) then
		-- 防止如果没分表的话，试着从总表里再获取一次
		voiceConfig = CommonUtils.GetConfig('collection', 'cardVoice', id)
	end
	return voiceConfig
end



--[[
根据卡牌id获取卡牌的神器关卡id
@params cardId int 卡牌id
@return questId int 关卡id
--]]
function CardUtils.GetCardArtifactQuestId(cardId)
	local questId = nil
    local cardConfig = CardUtils.GetCardConfig(cardId)
    if nil ~= cardConfig then
    	questId = checkint(cardConfig.artifactQuestId)
    end
    return questId
end



-------------------------------------------------
-- skin id
-------------------------------------------------

function CardUtils.GetCardSkinId(cardId)
    if CardUtils.IsMonsterCard(cardId) then
        return CardUtils.GetCardSkinIdByByMonsterId(cardId)
    else
        return CardUtils.GetCardDefaultSkinIdByCardId(cardId)
    end
end


--[[
	根据 卡牌id 获取 卡牌全部皮肤定义
	@params cardId 	int 	卡牌id
	@return skinMap table 	皮肤map
]]
function CardUtils.GetCardAllSkinMapByCardId(cardId)
	local cardConf = CommonUtils.GetConfig('cards', 'card', cardId) or {}
    return checktable(cardConf.skin)
end


--[[
	根据 卡牌id 获取 卡牌默认皮肤id
	@params cardId int 		卡牌id
	@return skinId int 		皮肤id
--]]
function CardUtils.GetCardDefaultSkinIdByCardId(cardId)
	local allSkinMap = CardUtils.GetCardAllSkinMapByCardId(cardId)
	local cardSkins  = allSkinMap[tostring(CardUtils.SKIN_UNLOCK_TYPE.DEFAULT)] or {}
    local skinKeys   = table.keys(cardSkins)
    table.sort(skinKeys, function (a, b)
        return checkint(a) < checkint(b)
    end)
    return checkint(skinKeys[1])
end


--[[
	根据 怪物id 获取 怪物唯一皮肤id
	@params monsterId int 		怪物id
	@return skinId 	  int 		皮肤id
--]]
function CardUtils.GetCardSkinIdByByMonsterId(monsterId)
	local monsterConfig = CommonUtils.GetConfig('monster', 'monster', monsterId) or {}
	return checkint(monsterConfig.skinId)
end


--[[
	根据 卡牌或怪物id获取spine创建时的默认纹理缩放大小
	@params cardId int 		id
	@return scale  number 	默认缩放大小
--]]
function CardUtils.GetDefaultCardSpineScale(cardId)
	if CardUtils.IsMonsterCard(cardId) then

		local monsterConfig = CardUtils.GetCardConfig(cardId)
		if nil ~= monsterConfig then
			if ConfigMonsterType.ELITE == checkint(monsterConfig.type) then
				return ELITE_DEFAULT_SCALE
			elseif ConfigMonsterType.BOSS == checkint(monsterConfig.type) then
				return BOSS_DEFAULT_SCALE
			end
		end

	end

	return CARD_DEFAULT_SCALE
end


--================================================================================================
-- card assets
--================================================================================================

--[[
    根据 皮肤id 获取 卡牌立绘名字
    @params skinId   int 		皮肤id
    @return drawName string 	立绘名字
--]]
function CardUtils.GetCardDrawNameBySkinId(skinId)
	local drawName = nil
	local skinConf = CardUtils.GetCardSkinConfig(skinId)
    
	if nil == skinConf then
		print('>>> error <<< -> can not find skin config in #CardUtils.GetCardDrawNameBySkinId#', skinId)
		drawName = CardUtils.DEFAULT_DRAW_ID
	else
		drawName = tostring(skinConf.drawId)
	end
	return drawName
end


--[[
	根据 卡牌id 获取 默认立绘名字
	@params cardId   int 		卡牌id
	@return drawName string 	立绘名字
]]
function CardUtils.GetCardDrawNameByCardId(cardId)
    local skinId = CardUtils.GetCardSkinId(cardId)
    return CardUtils.GetCardDrawNameBySkinId(skinId)
end


-------------------------------------------------
-- draw path
-------------------------------------------------

function CardUtils.GetCardDrawPathBySkinId(skinId)
    local drawName = CardUtils.GetCardDrawNameBySkinId(skinId)
    return AssetsUtils.GetCardDrawPath(drawName)
end


function CardUtils.GetCardDrawPathByCardId(cardId)
    local skinId = CardUtils.GetCardSkinId(cardId)
    return CardUtils.GetCardDrawPathBySkinId(skinId)
end


-------------------------------------------------
-- draw bg path
-------------------------------------------------

function CardUtils.GetCardDrawBgPathBySkinId(skinId)
    local drawBgName = nil
	local skinConf   = CardUtils.GetCardSkinConfig(skinId)

	if nil == skinConf then
		print('>>> error <<< -> can not find skin config in #CardUtils.GetCardDrawBgPathBySkinId#', skinId)
	else
		drawBgName = tostring(skinConf.drawBackGroundId)
	end
    return AssetsUtils.GetCardDrawBgPath(drawBgName)
end


function CardUtils.GetCardDrawBgPathByCardId(cardId)
    local skinId = CardUtils.GetCardSkinId(cardId)
	return CardUtils.GetCardDrawBgPathBySkinId(skinId)
end


-------------------------------------------------
-- draw fg path
-------------------------------------------------

function CardUtils.GetCardDrawFgPathBySkinId(skinId)
	local drawFgName = nil
	local skinConf   = CardUtils.GetCardSkinConfig(skinId)

	if nil == skinConf then
		print('>>> error <<< -> can not find skin config in #CardUtils.GetCardDrawFgPathBySkinId#', skinId)
	else
		drawFgName = tostring(skinConf.drawBackGroundId)
	end
    return AssetsUtils.GetCardDrawFgPath(drawFgName)
end


function CardUtils.GetCardDrawFgPathByCardId(cardId)
    local skinId = CardUtils.GetCardSkinId(cardId)
	return CardUtils.GetCardDrawFgPathBySkinId(skinId)
end


-------------------------------------------------
-- draw spine path
-------------------------------------------------

function CardUtils.GetCardSpineDrawPathBySkinId(skinId)
    local drawName = nil
	local skinConf   = CardUtils.GetCardSkinConfig(skinId)

	if nil == skinConf then
		print('>>> error <<< -> can not find skin config in #CardUtils.GetCardSpineDrawPathBySkinId#', skinId)
	else
		drawName = tostring(skinConf.drawSpineId)
	end
    return AssetsUtils.GetCardSpineDrawPath(drawName)
end


function CardUtils.GetCardSpineDrawPathByCardId(cardId)
    local skinId = CardUtils.GetCardSkinId(cardId)
	return CardUtils.GetCardSpineDrawPathBySkinId(skinId)
end


-------------------------------------------------
-- spine path
-------------------------------------------------

function CardUtils.GetCardSpinePathBySkinId(skinId)
	local spineName = nil
	local skinConf  = CardUtils.GetCardSkinConfig(skinId)

	if nil == skinConf then
		print('>>> error <<< -> can not find skin config in #CardUtils.GetCardSpinePathBySkinId#', skinId)
		spineName = CardUtils.DEFAULT_SPINE_ID
	else
		spineName = tostring(skinConf.spineId)
	end
	return AssetsUtils.GetCardSpinePath(spineName)
end


function CardUtils.GetCardSpinePathByCardId(cardId)
	local skinId = CardUtils.GetCardSkinId(cardId)
	return CardUtils.GetCardSpinePathBySkinId(skinId)
end


-------------------------------------------------
-- head path
-------------------------------------------------

function CardUtils.GetCardHeadPathBySkinId(skinId)
	local headName = nil
	local skinConf = CardUtils.GetCardSkinConfig(skinId)

	if nil == skinConf then
		print('>>> error <<< -> can not find skin config in #CardUtils.GetCardHeadPathBySkinId#', skinId)
		headName = CardUtils.DEFAULT_HEAD_ID
	else
		headName = tostring(skinConf.drawId)
	end
	return AssetsUtils.GetCardHeadPath(headName)
end


function CardUtils.GetCardHeadPathByCardId(cardId)
	local skinId = CardUtils.GetCardSkinId(cardId)
	return CardUtils.GetCardHeadPathBySkinId(skinId)
end


-------------------------------------------------
-- team bg path
-------------------------------------------------

function CardUtils.GetCardTeamBgPathBySkinId(skinId)
	local skinConf    = checkint(skinId) > 0 and CardUtils.GetCardSkinConfig(skinId) or {}
	local cardId      = checkint(skinConf.cardId)
	local cardConf    = checkint(skinId) > 0 and CardUtils.GetCardConfig(cardId) or {}
	local qualityId   = checkint(cardConf.qualityId)
	local defaultPath = CardUtils.TEAM_BG_PATH_MAP['0']
	
	local teamBgPath  = nil
	if qualityId == CardUtils.QUALITY_TYPE.UR then
		teamBgPath = skinConf.drawBackGroundId and AssetsUtils.GetCardTeamBgPath(skinConf.drawBackGroundId) or nil
	else
		teamBgPath = CardUtils.TEAM_BG_PATH_MAP[tostring(qualityId)]
	end
	return _res(teamBgPath or defaultPath)
end


function CardUtils.GetCardTeamBgPathByCardId(cardId)
	local skinId = CardUtils.GetCardSkinId(cardId)
	return CardUtils.GetCardTeamBgPathBySkinId(skinId)
end


-------------------------------------------------
-- team frame path
-------------------------------------------------

function CardUtils.GetCardTeamFramePathByCardId(cardId)
	local cardConf  = CardUtils.GetCardConfig(cardId) or {}
	local qualityId = checkint(cardConf.qualityId)
	return _res(CardUtils.TEAM_FRAME_PATH_MAP[tostring(qualityId)])
end


-------------------------------------------------
-- quality text path
-------------------------------------------------

function CardUtils.GetCardQualityTextPathByCardId(cardId)
	local cardConf  = CardUtils.GetCardConfig(cardId) or {}
	local qualityId = checkint(cardConf.qualityId)
	return _res(CardUtils.QUALITY_TEXT_PATH_MAP[tostring(qualityId)])
end


-------------------------------------------------
-- quality icon path
-------------------------------------------------

function CardUtils.GetCardQualityIconPathByCardId(cardId)
	local cardConf  = CardUtils.GetCardConfig(cardId) or {}
	local qualityId = checkint(cardConf.qualityId)
	return _res(CardUtils.QUALITY_ICON_PATH_MAP[tostring(qualityId)])
end


-------------------------------------------------
-- quality head frame path
-------------------------------------------------

function CardUtils.GetCardQualityHeadFramePathByCardId(cardId)
	local cardConf  = CardUtils.GetCardConfig(cardId) or {}
	local qualityId = checkint(cardConf.qualityId)
	return _res(CardUtils.CAREER_HEAD_FRAME_PATH_MAP[tostring(qualityId)])
end


-------------------------------------------------
-- career icon path
-------------------------------------------------

function CardUtils.GetCardCareerIconPathByCardId(cardId)
	local cardConf = CardUtils.GetCardConfig(cardId) or {}
	local careerId = checkint(cardConf.career)
	return CardUtils.GetCardCareerIconPathByCareerId(careerId)
end


function CardUtils.GetCardCareerIconPathByCareerId(careerId)
	return _res(CardUtils.CAREER_ICON_PATH_MAP[tostring(careerId)])
end


-------------------------------------------------
-- career icon frame path
-------------------------------------------------

function CardUtils.GetCardCareerIconFramePathByCardId(cardId)
	local cardConf = CardUtils.GetCardConfig(cardId) or {}
	local careerId = checkint(cardConf.career)
	return CardUtils.GetCardCareerBgPathByCareerId(careerId)
end


function CardUtils.GetCardCareerBgPathByCareerId(careerId)
	return _res(CardUtils.CAREER_ICON_FRAME_PATH_MAP[tostring(careerId)])
end


-------------------------------------------------
-- skinType icon path
-------------------------------------------------

function CardUtils.GetCardSkinTypeIconPathBySkinType(skinType)
	local skinTypeConf = CONF.CARD.SKIN_COLL_TYPE:GetValue(skinType)
	return _res("ui/common/" .. skinTypeConf.logo)
end


function CardUtils.GetCardSkinTypeIconPathBySkinId(skinId)
	local cardSkinType = CardUtils.GetSkinTypeBySkinId(skinId)
	return CardUtils.GetCardSkinTypeIconPathBySkinType(cardSkinType)
end


-------------------------------------------------
-- raid boss preview draw path
-------------------------------------------------

function CardUtils.GetRaidBossPreviewDrawPathBySkinId(skinId)
    local drawName = nil
	local skinConf = CardUtils.GetCardSkinConfig(skinId)

	if nil == skinConf then
		print('>>> error <<< -> can not find skin config in #CardUtils.GetRaidBossPreviewDrawPathBySkinId#', skinId)
	else
		drawName = tostring(skinConf.drawId)
	end
    return AssetsUtils.GetRaidBossPreviewDrawPath(drawName)
end


function CardUtils.GetRaidBossPreviewDrawPathByCardId(cardId)
    local skinId = CardUtils.GetCardSkinId(cardId)
	return CardUtils.GetRaidBossPreviewDrawPathBySkinId(skinId)
end


-------------------------------------------------
-- skill icon path
-------------------------------------------------

--[[
获取技能图标
@params skillId int 技能id
@return path str 技能图标路径
--]]
function CardUtils.GetSkillIconBySkillId(skillId)
	local skillSectionType = CommonUtils.GetSkillSectionTypeBySkillId(skillId)
	local path = ''

	if SkillSectionType.SPECIAL_SKILL == skillSectionType then

		-- 显示在战斗场景中的左上角的全局buff图标
		local skillConfig = CommonUtils.GetSkillConf(skillId)
		if nil ~= skillConfig then
			path = _res(string.format('arts/skills/%s.png', tostring(skillConfig.iconId)))
		end

	else

		path = _res(string.format('arts/skills/%s.png', tostring(skillId)))

	end

	return path
end


--================================================================================================
-- card property
--================================================================================================

--[[
	根据 卡牌品质id 获取 卡牌品质名称
	@params qualityId 	int 	 	卡牌品质id
	@return qualityName string 		卡牌品质名字
--]]
function CardUtils.GetCardQualityName(qualityId)
	local qualityConf = CommonUtils.GetConfig('cards', 'quality', qualityId or 1)
	return qualityConf and tostring(qualityConf.quality) or ''
end


--[[
	根据 卡牌职业id 获取 卡牌职业名称
	@params careerId 	int 		卡牌职业id
	@return careerName  string 		卡片职业名字
--]]
function CardUtils.GetCardCareerName(careerId)
	local nameFunc = CardUtils.CAREER_NAME_FUNCTION_MAP[tostring(careerId)]
    return nameFunc and nameFunc() or ''
end

--[[
	根据 卡牌技能特性 获取 技能特性名称
	@params skillProperty int 		    技能特性
	@return propertyName  string 		技能特性名称
--]]
function CardUtils.GetSkillPropertyName(skillProperty)
	local nameFunc = CardUtils.SKILL_PROPERTY_NAME_FUNCTION_MAP[tostring(skillProperty)]
    return nameFunc and nameFunc() or ''
end


--[[
根据卡牌属性类型获取卡牌属性信息
@params p ObjP 属性
@return _ table 卡牌属性信息
--]]
function CardUtils.GetCardPInfo(p)
	return CardUtils.PROPERTY_INFO[p]
end


--[[
获取卡牌属性的通用字段名
@params p ObjP 属性
@return _ string 卡牌属性字段名
--]]
function CardUtils.GetCardPCommonName(p)
	local pinfo = CardUtils.GetCardPInfo(p)
	if nil ~= pinfo then
		return pinfo.name
	else
		return nil
	end
end


--[[
根据卡牌信息获取卡牌6属性集
@params cardData table 卡牌信息
@return result map 修正后的属性 {
	[ObjP] = number,
	[ObjP] = number
}
--]]
function CardUtils.GetCardAllFixedPByCardData(cardData)
	local result = {}

	if nil ~= cardData and 0 ~= checkint(cardData.cardId) then

		result = CardUtils.GetCardAllFixedP(
			checkint(cardData.cardId), checkint(cardData.level), checkint(cardData.breakLevel), checkint(cardData.favorabilityLevel),
			cardData.pets, cardData.artifactTalent, cardData.bookLevel, cardData.equippedHouseCatGene
		)

	end

	return result
end


--[[
根据卡牌数据获取卡牌6属性集
(卡牌基础属性*(1+结婚系数)+堕神加成属性)*(1+神器百分比加成)+神器数值加成+卡牌基础属性*飨灵收藏册加成+卡牌基础属性*猫屋系数
@params cardId int 卡牌id
@params level int 卡牌等级
@params breakLevel int 卡牌突破等级
@params favorLevel int 卡牌好感度等级
@params petsData 宠物信息
@parmas artifactData 神器信息
@params bookData map 飨灵收集册信息
@params equippedHouseCatGene map 装备中的猫咪基因
@return result map 修正后的属性 {
	[ObjP] = number,
	[ObjP] = number
}
--]]
function CardUtils.GetCardAllFixedP(cardId, level, breakLevel, favorLevel, petsData, artifactData, bookData, equippedHouseCatGene)
	local petAddPData = PetUtils.GetPetPropertyAddition(cardId, petsData)
	local artifactAddPData = ArtifactUtils.GetArtifactPropertyAddition(cardId, artifactData)
	local bookAddData = CardUtils.GetCardBookPropertyAddition(bookData)
	local catBuffAddData = CatHouseUtils.GetCatBuff(equippedHouseCatGene)
	return CardUtils.GetCardAllFixedPByAdditionInfo(cardId, level, breakLevel, favorLevel, petAddPData, artifactAddPData, bookAddData, catBuffAddData)
end


--[[
根据卡牌数据获取卡牌6属性集
(卡牌基础属性*(1+结婚系数)+堕神加成属性)*(1+神器百分比加成)+神器数值加成+卡牌基础属性*飨灵收藏册加成+卡牌基础属性*猫屋系数
@params cardId int 卡牌id
@params level int 卡牌等级
@params breakLevel int 卡牌突破等级
@params favorLevel int 卡牌好感度等级
@params petAddPData 宠物属性增益信息
@parmas artifactAddPData 神器增益信息
@params bookAddData 飨灵收集册增益信息
@params catBuffAddData map 装备中的猫咪基因
@return result map 修正后的属性 {
	[ObjP] = number,
	[ObjP] = number
}
--]]
function CardUtils.GetCardAllFixedPByAdditionInfo(cardId, level, breakLevel, favorLevel, petAddPData, artifactAddPData, bookAddData, catBuffAddData)
	local result = {}

	for k, ptype in pairs(CardUtils.GetCardInnatePConfig()) do
		result[ptype] = CardUtils.GetCardOneFixedP(
			cardId, ptype, 
			level, breakLevel, favorLevel,
			petAddPData, artifactAddPData, bookAddData, catBuffAddData
		)
	end

	return result
end


--[[
获取单条卡牌修正后属性

(卡牌基础属性*(1+结婚系数)+堕神加成属性)*(1+神器百分比加成)+神器数值加成+卡牌基础属性*飨灵收藏册加成+卡牌基础属性*猫屋系数
卡牌攻防血属性成长	round((攻防血基础属性+(等级-1)*对应突破的成长系数)*(1+卡牌好感度加成),0)
卡牌暴击爆伤攻速成长	暴击爆伤攻速=round((基础值+每次突破成长值求和)*(1+卡牌好感度加成),0)

@params cardId int 卡牌id
@params p ObjP 属性
@params level int 卡牌等级
@params breakLevel int 卡牌突破等级
@params favorLevel int 卡牌好感度等级
@params petAddPData 宠物信息
@parmas artifactAddPData 神器信息
@params bookAddData 飨灵收集册增益信息
@params catBuffAddData map 装备中的猫咪基因buff信息
@return fixedP number 卡牌修正后属性
--]]
function CardUtils.GetCardOneFixedP(cardId, p, level, breakLevel, favorLevel, petFixedPData, artifactFixedPData, bookFixedData, catBuffFixedData)
	local cardConfig = CardUtils.GetCardConfig(cardId)
	local growConfig = CardUtils.GetCardGrowConfig(cardId)

	if nil == cardConfig or nil == growConfig then
		return 0
	else

		-- 基础属性
		local pname = CardUtils.GetCardPCommonName(p)
		local baseP = checknumber(cardConfig[pname])

		-- 好感度配置
		local favorAbilityConfig = CardUtils.GetFavorAbilityConfig(cardId, favorLevel) or {}

		-- 计算卡牌修正属性 -> 基础修正
		local fixedP = 0
		local baseCardP = 0 -- 当前卡牌的基础卡牌属性, 不计算任何额外加成
		local attrConfig = growConfig[pname] or {}

		if CardUtils.PROPERTY_TYPE.HP == p or CardUtils.PROPERTY_TYPE.ATTACK == p or CardUtils.PROPERTY_TYPE.DEFENCE == p then

			------------ 攻防血 ------------
			local baseGrow = checknumber(attrConfig[checkint(breakLevel) + 1])
			fixedP = math.round(
				(baseP + (level - 1) * baseGrow) * (1 + checknumber(favorAbilityConfig[pname]))
			)
			baseCardP = baseP + (level - 1) * baseGrow
			------------ 攻防血 ------------

		elseif CardUtils.PROPERTY_TYPE.CRITRATE == p or CardUtils.PROPERTY_TYPE.CRITDAMAGE == p or CardUtils.PROPERTY_TYPE.ATTACKRATE == p then

			------------ 击伤速 ------------
			fixedP = baseP
			for i = 1, checkint(breakLevel) + 1 do
				fixedP = fixedP + checknumber(attrConfig[i])
			end
			baseCardP = fixedP
			fixedP = math.round(fixedP * (1 + checknumber(favorAbilityConfig[pname])))
			------------ 击伤速 ------------

		end

		-- 计算宠物的属性值加成
		if nil ~= petFixedPData then
			local petAddition = petFixedPData[p]
			if nil ~= petAddition then
				fixedP = fixedP + petAddition.value
			end
		end

		-- 计算神器的属性值加成
		if nil ~= artifactFixedPData then
			local artifactAddition = artifactFixedPData[p]
			if nil ~= artifactAddition then
				fixedP = fixedP * (1 + artifactAddition.valueMulti) + artifactAddition.value
			end
		end

		-- 计算飨灵收藏册
		if nil ~= bookFixedData then
			local bookAddition = bookFixedData[p]
			if nil ~= bookAddition then
				fixedP = fixedP + baseCardP * bookAddition
			end
		end

		-- 计算猫咪基因buff
		if nil ~= catBuffFixedData then
			local catAddition = catBuffFixedData[p]
			if nil ~= catAddition then
				fixedP = fixedP + baseCardP * catAddition
			end
		end

		fixedP = math.round(fixedP)
		
		return fixedP

	end
end


--[[
获取卡牌固有属性的集合
@return _ table 固有属性的定义
--]]
function CardUtils.GetCardInnatePConfig()
	return {
		ObjP.ATTACK,
		ObjP.DEFENCE,
		ObjP.HP,
		ObjP.CRITRATE,
		ObjP.CRITDAMAGE,
		ObjP.ATTACKRATE
	}
end


--[[
根据卡牌id获取卡牌成长配置
@params cardId int 卡牌id
@return growConfig config 属性成长系数配置
--]]
function CardUtils.GetCardGrowConfig(cardId)
	local growConfig = nil
	local cardConfig = CardUtils.GetCardConfig(cardId)
	if nil ~= cardConfig then
		growConfig = CommonUtils.GetConfig('cards', 'grow', cardConfig.growType)
	else

	end
	return growConfig
end
--[[
根据好感度等级和卡牌id获取好感度加成配置
@params cardId int 卡牌id
@params favorLevel int 好感度等级
--]]
function CardUtils.GetFavorAbilityConfig(cardId, favorLevel)
	local cardConfig = CardUtils.GetCardConfig(cardId) or {}
	local c_ = CommonUtils.GetConfig('cards', 'favorabilityCareerBuff', checkint(cardConfig.career)) or {}
	return c_[tostring(favorLevel)]
end


--[[
根据卡牌属性集合获取战斗力数值
@params cardPInfo map 修正后的属性 {
	[ObjP] = number,
	[ObjP] = number
}
--]]
function CardUtils.GetCardStaticBattlePointByPropertyInfo(cardPInfo)
	local result = 0
	------------ 根据最终属性计算卡牌战斗力 ------------
	local propertyBattlePoint = math.floor(cardPInfo[ObjP.ATTACK] * 10
		+ cardPInfo[ObjP.DEFENCE] * 16.7
		+ cardPInfo[ObjP.HP] * 1
		+ (cardPInfo[ObjP.CRITRATE] - 100) * 0.17
		+ (cardPInfo[ObjP.CRITDAMAGE] - 100) * 0.118
		+ (cardPInfo[ObjP.ATTACKRATE] - 100) * 0.109)
	------------ 根据最终属性计算卡牌战斗力 ------------
	result = result + propertyBattlePoint
	return result
end


--[[
根据卡牌信息获取战斗力
@params cardData table 卡牌信息
--]]
function CardUtils.GetCardStaticBattlePointByCardData(cardData)
	local result = 0
	if nil == cardData or 0 == checkint(cardData.cardId) then
		return result
	else
		
		local cardPInfo = CardUtils.GetCardAllFixedPByCardData(cardData)
		local propertyBattlePoint = CardUtils.GetCardStaticBattlePointByPropertyInfo(cardPInfo)
		return propertyBattlePoint
	end
end


-------------------------------------------------
-- card skill value
-------------------------------------------------

--[[
获取技能修正后的数值
@params skillId int 技能id
@params skillLevel = 1 int 技能等级
@params result table 修正后的数值
--]]
function CardUtils.GetFixedSkillEffect(skillId, skillLevel)
	local result = {}
	local skillConf = CommonUtils.GetSkillConf(skillId)
	local skillEffectConf = CardUtils.GetSkillEffectConfigBySkillId(skillId)
	if not (skillEffectConf and table.nums(skillEffectConf) > 0) then
		for k,v in pairs(skillConf.type) do
			result[k] = {}
			result[k].effect = v.effect
			result[k].effectTime = tonumber(v.effectTime)
		end
		return result
	end

	for k,v in pairs(skillConf.type) do
		result[k] = {}
		local growConf = skillEffectConf[k]
		if growConf and growConf[tostring(skillLevel)] then
			result[k].effect = checktable(growConf[tostring(skillLevel)][1])
			result[k].effectTime = checknumber(growConf[tostring(skillLevel)][2])
		else
			result[k].effect = v.effect
			result[k].effectTime = checknumber(v.effectTime)
		end
	end

	return result
end


--[[
获取卡牌连携技能id
@params cardId int 卡牌id
@return _ int 连携技id
--]]
function CardUtils.GetCardConnectSkillId(cardId)
	local cardConf = CardUtils.GetCardConfig(cardId)
	if nil ~= cardConf then
		for i,v in ipairs(cardConf.skill) do
			local skillConf = CardUtils.GetSkillConfigBySkillId(v)
			if skillConf and ConfigSkillType.SKILL_CONNECT == checkint(skillConf.property) then
				return checkint(v)
			end
		end
	end
	return nil
end


--[[
卡牌所在阵容连携是否可用
@params cardId int 卡牌id
@params formation table 阵容 -> 该方法不适用阵容中只存在卡牌数据库ID
@params skillId int 连携技id
@return _ bool 是否可用
--]]
function CardUtils.IsConnectSkillEnable(cardId, formation, skillId)
	local cardConf = CardUtils.GetCardConfig(cardId)
	skillId = skillId or CardUtils.GetCardConnectSkillId(cardId)
	if skillId then
		if cardConf.concertSkill and next(cardConf.concertSkill) ~= nil then
			for _,connectCardId in ipairs(cardConf.concertSkill) do
				local exist = false
				for i,v in ipairs(formation) do
					-- local targetCardId = checkint(v.cardId or app.gameMgr:GetCardDataById(v.id).cardId)
					local targetCardId = checkint(v.cardId)
					if checkint(connectCardId) == targetCardId then
						exist = true
					end
				end
				if not exist then
					return false
				end
			end
		else
			return false
		end
	end
	return true
end


--[[
根据卡牌id获取卡牌超能力技能
@params cardId int 卡牌id
@return _ list<int(skillId)>
--]]
function CardUtils.GetCardEXAbilitySkillsByCardId(cardId)
	local config = CommonUtils.GetConfig('cards', 'exSkill', cardId)
	if nil ~= config then
		return config.exSkills
	else
		return nil
	end
end


--[[
根据id判断是否是神器天赋技能
@params skillId int 
@return _ bool 是否是神器天赋技能
--]]
function CardUtils.IsArtifactTalentSkillBySkillId(skillId)
	local skillSectionConfig = {
		[SkillSectionType.ARTIFACT_TALENT_SKILL] 		= true,
		[SkillSectionType.ARTIFACT_TALENT_SKILL_2] 		= true
	}
	local skillSectionType = CommonUtils.GetSkillSectionTypeBySkillId(skillId)
	local sectionInfo = skillSectionConfig[skillSectionType]
	if nil ~= sectionInfo and true == sectionInfo then
		return true
	else
		return false
	end
end


-------------------------------------------------
-- customize enemy formation
-------------------------------------------------

--[[
获取一队配表配置的自定义敌方战斗阵容
@params customizeEnemyId int 自定义的敌方阵容id
@params cardLevel int 卡牌等级
@params cardSkillLevel int 卡牌技能等级
@return teamData map<index int, cardData map>
--]]
function CardUtils.GetCustomizeEnemyOneTeamById(customizeEnemyId, cardLevel, cardSkillLevel)
	local config = CommonUtils.GetConfig('battle', 'enemy', customizeEnemyId)
	if nil == config then return nil end

	local enemyCard = CommonUtils.GetConfig('battle', 'enemyCard', customizeEnemyId)
	local enemyMonster = CommonUtils.GetConfig('battle', 'enemyNpc', customizeEnemyId)
	
	local teamData = {}
	local itor = 1

	------------ 先查卡牌 ------------
	if nil ~= enemyCard then

		local cardAmount = #config.card

		local cardId = nil
		local customizeCardConfig = nil
		local placeId = nil

		for i = 1, cardAmount do

			cardId = checkint(config.card[i])
			customizeCardConfig = enemyCard.card[i]
			placeId = config.location[itor] and checkint(config.location[itor]) or nil

			if nil ~= customizeCardConfig then

				local cardData = CardUtils.FormatCardDataByCustomizeConfig(
					cardId, customizeCardConfig, cardLevel, cardSkillLevel, placeId
				)
				teamData[itor] = cardData

			else
				teamData[itor] = {cardId = nil}
			end

			itor = itor + 1

		end

	end
	
	------------ 先查卡牌 ------------

	------------ 后查怪物 ------------
	if nil ~= enemyMonster then

		local monsterAmount = #config.monster

		local monsterId = nil
		local customizeMonsterConfig = nil
		local placeId = nil

		for i = 1, monsterAmount do

			monsterId = checkint(config.monster[i])
			customizeMonsterConfig = enemyMonster.npc[i]
			placeId = config.location[itor] and checkint(config.location[itor]) or nil

			if nil ~= customizeMonsterConfig then

				local monsterData = CardUtils.FormatMonsterDataByCustomizeConfig(
					monsterId, customizeMonsterConfig, cardLevel, cardSkillLevel, placeId
				)
				teamData[itor] = monsterData

			else
				teamData[itor] = {monsterId = nil}
			end

			itor = itor + 1
			
		end

	end
	------------ 后查怪物 ------------

	return teamData
end


--[[
根据配置的卡牌数据构造一个类似checkin服务器返回的卡牌数据
@params cardId int 卡牌id
@params customizeCardConfig map 配置的卡牌数据
@params level int 卡牌等级
@params skillLevel int 卡牌技能等级
@params placeId int 站位id
@return cardData map 类似checkin服务器返回的卡牌数据
--]]
function CardUtils.FormatCardDataByCustomizeConfig(cardId, customizeCardConfig, level, skillLevel, placeId)
	------------ 卡牌等级 ------------
	-- 内部配置优先
	local cardLevel_ = 1
	if nil ~= customizeCardConfig.level then
		cardLevel_ = checkint(customizeCardConfig.level)
	elseif nil ~= level then
		cardLevel_ = level
	end
	------------ 卡牌等级 ------------

	local cardConfig = CardUtils.GetCardConfig(cardId)

	------------ 卡牌技能 ------------
	local skillLevel_ = 1
	if nil ~= customizeCardConfig.skillLevel then
		skillLevel_ = checkint(customizeCardConfig.skillLevel)
	elseif nil ~= skillLevel then
		skillLevel_ = skillLevel
	end

	local skills = {}
	local skillId = nil
	for _, skillId_ in ipairs(cardConfig.skill) do
		skillId = checkint(skillId_)
		skills[tostring(skillId)] = {
			level = skillLevel_
		}
	end
	------------ 卡牌技能 ------------

	------------ 宠物 ------------
	local pets = {}
	local itor = 1

	-- enemyCard中的petId
	if nil ~= customizeCardConfig.petId then
		local petData = PetUtils.FormatPetDataByCustomizeId(checkint(customizeCardConfig.petId))
		if nil ~= petData then
			pets[tostring(itor)] = petData
			itor = itor + 1
		end
	end
	------------ 宠物 ------------

	------------ 神器天赋 ------------
	local artifactData = nil
	-- enemyCard中的artifactId
	if nil ~= customizeCardConfig.artifactId then

		artifactData = ArtifactUtils.FormatArtifactDataByCustomizeId(cardId, checkint(customizeCardConfig.artifactId))

	end
	------------ 神器天赋 ------------

	local cardData = {
		cardId = cardId,
		level = cardLevel_,
		breakLevel = checkint(customizeCardConfig.breakLevel),
		favorabilityLevel = checkint(customizeCardConfig.favorabilityLevel),
		defaultSkinId = checkint(customizeCardConfig.skinId),
		skill = skills,
		pets = pets,
		artifactTalent = artifactData or {},
		placeId = placeId and checkint(placeId) or nil
	}

	return cardData
end


--[[
根据配置的怪物数据构造一个战斗构造器使用的怪物数据
@params monsterId int 怪物id
@params customizeMonsterConfig 配置的怪物数据
@params level int 等级
@params skillLevel int 技能等级
@params placeId int 站位id
@return monsterData map 
--]]
function CardUtils.FormatMonsterDataByCustomizeConfig(monsterId, customizeMonsterConfig, level, skillLevel, placeId)
	------------ 等级 ------------
	-- 内部配置优先
	local level_ = 1
	if nil ~= customizeMonsterConfig.level then
		level_ = checkint(customizeMonsterConfig.level)
	elseif nil ~= level then
		level_ = level
	end
	------------ 等级 ------------

	local monsterData = {
		cardId = monsterId,
		npcId = monsterId,
		initialHp = customizeMonsterConfig.initialHp,
		campType = customizeMonsterConfig.campType,
		level = level_,
		attrGrow = checknumber(customizeMonsterConfig.attrGrow),
		skillGrow = checknumber(customizeMonsterConfig.skillGrow),
		recordDeltaHp = customizeMonsterConfig.recordDeltaHp,
		placeId = placeId
	}

	return monsterData
end


-------------------------------------------------
-- 卡牌live2d模型
function CardUtils.GetCardLive2dModelDir(cardDrawName, isUseBg)
	return string.fmt('arts/live2d/%1/', tostring(cardDrawName) .. (isUseBg == true and '_bg' or ''))
end
function CardUtils.GetCardLive2dModelName(cardDrawName)
	return string.fmt('l2d%1.model3.json', tostring(cardDrawName))
end
function CardUtils.GetCardLive2dModelPath(cardDrawName, isUseBg)
	return CardUtils.GetCardLive2dModelDir(cardDrawName, isUseBg) .. CardUtils.GetCardLive2dModelName(cardDrawName)
end
function CardUtils.GetCardLive2dTextureList(cardDrawName, isUseBg)
	local textureList = {}
	if CardUtils.IsExistentGetCardLive2dModel(cardDrawName, isUseBg) then
		local live2dModelDir  = CardUtils.GetCardLive2dModelDir(cardDrawName, isUseBg)
		local live2dModelPath = CardUtils.GetCardLive2dModelPath(cardDrawName, isUseBg)
		local live2dModelJson = json.decode(FTUtils:getFileData(live2dModelPath))
		for index, filePath in ipairs(checktable(live2dModelJson.FileReferences).Textures or {}) do
			textureList[index] = live2dModelDir .. filePath
		end
	end
	return textureList
end


function CardUtils.IsExistentGetCardLive2dModel(cardDrawName, isUseBg)
	return utils.isExistent(CardUtils.GetCardLive2dModelPath(cardDrawName, isUseBg)) == true
end
function CardUtils.IsExistentGetCardLive2dModelAtSkinId(cardSkinId, isUseBg)
	local cardDrawName = CardUtils.GetCardDrawNameBySkinId(cardSkinId)
	return CardUtils.IsExistentGetCardLive2dModel(cardDrawName, isUseBg)
end


function CardUtils.IsShowCardLive2d(skinId)
	local skinConf = CardUtils.GetCardSkinConfig(skinId) or {}
	return GAME_MODULE_OPEN.CARD_LIVE2D and (checkint(skinConf.showLive2d) == 1) and CardUtils.IsExistentGetCardLive2dModelAtSkinId(skinId)
end


-------------------------------------------------
-- 根据皮肤id获取到皮肤的类型
function CardUtils.GetSkinTypeBySkinId(skinId)
	local skinCollConf = CONF.CARD.SKIN_COLL_INFO:GetValue(checkint(skinId))
	local cardSkinType = checkint(skinCollConf.type)
	return cardSkinType == 0 and CardUtils.DEFAULT_SKIN_TYPE or cardSkinType
end

-------------------------------------------------
-- 飨灵收集册
--[[
获取飨灵收集册加成
@params bookData map 飨灵收集册的信息
@return result map 加成信息 {
	[ObjP] = value,
	[ObjP] = value,
	...
}
--]]
function CardUtils.GetCardBookPropertyAddition( bookData )
	local result = {}
	for _, bookLevel in pairs(checktable(bookData)) do
		local buffConf =  CommonUtils.GetConfig('cardCollection', 'bookBuff', bookLevel)
		for k, v in pairs(buffConf.buff) do
			local p = checkint(k)
			if result[p] then
				result[p] = result[p] + tonumber(v)
			else
				result[p] = tonumber(v)
			end
		end
	end
	return result
end

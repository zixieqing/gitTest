--[[
战斗资源管理工具
--]]
local BattleResUtils = {}
BRUtils = BattleResUtils

------------ import ------------
------------ import ------------

------------ define ------------
local SpineResType = SpineType

local SpineResTypeConfig = {
	[SpineResType.AVATAR] 			= {folderPath = 'cards/spine/avatar'},
	[SpineResType.EFFECT]			= {folderPath = 'cards/spine/effect'},
	[SpineResType.HURT] 			= {folderPath = 'cards/spine/hurt'}
}
------------ define ------------

---------------------------------------------------
-- res load begin --
---------------------------------------------------
--[[
计算单卡需要加载的资源
@params cardId int 卡牌id
@params skinId int 皮肤id
@params exAbilityData EXAbilityConstructorStruct 卡牌超能力数据
@params avatarSpine table 需要加载的卡牌spine集合
@params effectSpine table 需要加载的特效spine集合
@params hurtSpine table 需要加载的爆点附加效果spine集合
@return extraNeedLoad table {
	needLoadBossWeak bool 是否需要加载boss弱点动画
	needLoadBossCutin bool 是否需要加载boss cut in 
}
--]]
function BattleResUtils.ConvertNeedLoadResourcesByCardId(cardId, skinId, exAbilityData, avatarSpine, effectSpine, hurtSpine)
	local extraNeedLoad = {
		needLoadBossWeak = false,
		needLoadBossCutin = false
	}

	local cardConfig = CardUtils.GetCardConfig(cardId)
	local skinConfig = CardUtils.GetCardSkinConfig(skinId)

	local scale = CARD_DEFAULT_SCALE
	local isMonster = false

	if true == CardUtils.IsMonsterCard(cardId) then

		isMonster = true

		-- 判断卡牌初始缩放比 以及是否加载弱点等信息
		if ConfigMonsterType.ELITE == checkint(cardConfig.type) then
			scale = ELITE_DEFAULT_SCALE
			extraNeedLoad.needLoadBossWeak = true
		elseif ConfigMonsterType.BOSS == checkint(cardConfig.type) then
			scale = BOSS_DEFAULT_SCALE
			extraNeedLoad.needLoadBossWeak = true
			extraNeedLoad.needLoadBossCutin = true
		end

	end

	------------ 添加需要加载卡牌动画的spine ------------
	local spineId = nil

	if (nil == skinConfig) or 
		(not utils.isExistent(_res(string.format('cards/spine/avatar/%s.json', tostring(skinConfig.spineId))))) then

		-- 使用默认皮肤
		skinId = CardUtils.GetCardSkinId(cardId)
		skinConfig = CardUtils.GetCardSkinConfig(skinId)

		if nil == skinConfig then
			-- 如果默认皮肤配置也找不到 我也无能为力了
			assert(false, 'error >>> even can not find default skin config when battle load resources -> ' .. tostring(cardId))
			return extraNeedLoad
		else
			spineId = tostring(skinConfig.spineId)
		end

	else

		spineId = tostring(skinConfig.spineId)

	end

	if not utils.isExistent(_res(string.format('cards/spine/avatar/%s.json', tostring(skinConfig.spineId)))) then

		-- 皮肤文件不存在
		assert(false, 'error >>> cannot find skin resources local -> ' .. tostring(cardId))
		return extraNeedLoad

	end

	table.insert(avatarSpine, 1, SpineAnimationCacheInfoStruct.New(
		BattleUtils.GetAvatarAniNameById(spineId),
		AssetsUtils.GetCardSpinePath(spineId),
		scale,
		skinId
	))
	------------ 添加需要加载卡牌动画的spine ------------

	------------ 添加普攻特效 ------------
	BattleResUtils.ConvertNeedLoadResourcesByCardAction(cardId, skinId, scale, ATTACK_2_SKILL_ID, avatarSpine, effectSpine, hurtSpine)
	------------ 添加普攻特效 ------------

	------------ 添加技能特效 ------------
	-- 普通技能
	BattleResUtils.ConvertNeedLoadResourcesBySkill(cardConfig.skill, cardId, skinId, scale, avatarSpine, effectSpine, hurtSpine)
	-- 超能力技能
	if nil ~= exAbilityData then
		BattleResUtils.ConvertNeedLoadResourcesBySkill(exAbilityData.skills, cardId, skinId, scale, avatarSpine, effectSpine, hurtSpine)
	end
	------------ 添加技能特效 ------------

	return extraNeedLoad
end

--[[
根据技能和特效配置转换需要加载的除了人物spine以外的特效资源
@params skill table 技能集合
@params cardId int 卡牌id
@params skinId int 皮肤id
@params scale number 缩放比
@params avatarSpine table 需要加载的卡牌spine集合
@params effectSpine table 需要加载的特效spine集合
@params hurtSpine table 需要加载的爆点附加效果spine集合
--]]
function BattleResUtils.ConvertNeedLoadResourcesBySkill(skill, cardId, skinId, scale, avatarSpine, effectSpine, hurtSpine)
	-- local effectConfig = CardUtils.GetCardEffectConfigBySkinId(cardId, skinId)

	local skillId = nil
	local skillConfig = nil

	for _, skillId_ in ipairs(skill) do

		skillId = checkint(skillId_)
		skillConfig = CommonUtils.GetSkillConf(skillConfig)
		if nil ~= skillConfig then

			if nil ~= skillConfig.type[tostring(ConfigBuffType.BECKON)] then

				-- 如果是召唤系技能 加载召唤出来的怪物
				local effect = CardUtils.GetFixedSkillEffect(skillId, 1)
				for i, beckonObjId in ipairs(effect[tostring(ConfigBuffType.BECKON)].effect) do
					BattleResUtils.ConvertNeedLoadResourcesByCardId(
						checkint(beckonObjId),
						CardUtils.GetCardSkinId(checkint(beckonObjId)),
						nil,
						avatarSpine, effectSpine, hurtSpine
					)
				end

			elseif nil ~= skillConf.type[tostring(ConfigBuffType.VIEW_TRANSFORM)] then

				-- 变形系技能 加载变形后的整套spine动画
				local effect = CardUtils.GetFixedSkillEffect(skillId, 1)
				local targetSkinId = checkint(effect[tostring(ConfigBuffType.VIEW_TRANSFORM)].effect[3])
				BattleResUtils.ConvertNeedLoadResourcesByCardId(
					cardId,
					targetSkinId,
					nil,
					avatarSpine, effectSpine, hurtSpine
				)

			end

		end

		-- 技能特效
		BattleResUtils.ConvertNeedLoadResourcesByCardAction(cardId, skinId, scale, skillId, avatarSpine, effectSpine, hurtSpine)

	end
end

--[[
根据特效配置计算需要加载的资源
@params cardId int 卡牌id
@params skinId int 皮肤id
@params scale number spine加载的原始缩放
@params skillId int 技能id
@params avatarSpine table 需要加载的卡牌spine集合
@params effectSpine table 需要加载的特效spine集合
@params hurtSpine table 需要加载的爆点附加效果spine集合
--]]
function BattleResUtils.ConvertNeedLoadResourcesByCardAction(cardId, skinId, scale, skillId, avatarSpine, effectSpine, hurtSpine)
	local effectConfig = CardUtils.GetCardEffectConfigBySkinId(cardId, skinId)
	if nil ~= effectConfig then
		
		local actionEffectConfig = effectConfig[tostring(skillId)]
		if nil ~= actionEffectConfig then

			-- 动作特效
			local effectId_ = actionEffectConfig.effectId
			if 0 ~= checkint(effectId_) then
				effectId_ = BattleResUtils.CheckCardSkillEffectIdBySkinId(skinId, effectId_)
				table.insert(effectSpine, 1, SpineAnimationCacheInfoStruct.New(
					BattleUtils.GetEffectAniNameById(tostring(effectId_)),
					string.format('%s/%s', SpineResTypeConfig[SpineResType.EFFECT].folderPath, tostring(effectId_)),
					scale,
					skinId
				))
			end

			-- 爆点特效
			local hurtEffectId_ = actionEffectConfig.effect.hitEffect
			if 0 ~= checkint(hurtEffectId_) then
				table.insert(hurtSpine, 1, SpineAnimationCacheInfoStruct.New(
					BattleUtils.GetHurtAniNameById(hurtEffectId_),
					string.format('%s/%s', SpineResTypeConfig[SpineResType.HURT].folderPath, tostring(hurtEffectId_)),
					scale,
					skinId
				))
			end

			-- 附加效果
			local attachEffectId_ = actionEffectConfig.effect.addEffect
			if 0 ~= checkint(attachEffectId_) then
				table.insert(hurtSpine, 1, SpineAnimationCacheInfoStruct.New(
					BattleUtils.GetHurtAniNameById(attachEffectId_),
					string.format('%s/%s', SpineResTypeConfig[SpineResType.HURT].folderPath, tostring(attachEffectId_)),
					scale,
					skinId
				))
			end

		end
		
	end
end
---------------------------------------------------
-- res load end --
---------------------------------------------------


---------------------------------------------------
-- 判断资源是否合法 begin --
---------------------------------------------------
--[[
判断整套资源是否合法
@params spineId string spine的id
@params spineResType SpineResType spine资源类型
@return _ bool 整套资源是否合法
--]]
function BattleResUtils.IsSpineResourceValid(spineId, spineResType)
	local spineResTypeConfig = SpineResTypeConfig[spineResType]
	local spinePath = string.format('%s/%s', spineResTypeConfig.folderPath, spineId)
	return BattleResUtils.IsSpineResourceValidByFullPath(spinePath)
end

--[[
根据全路径判断整套资源是否合法
@params spinePath string spine资源的全路径
@return _ bool 整套资源是否合法
--]]
function BattleResUtils.IsSpineResourceValidByFullPath(spinePath)
	local isValidity, verifyMap = app.gameResMgr:verifySpine(spinePath)
	return isValidity, verifyMap
end

--[[
根据路径请求下载spine资源
@params spinePath string
--]]
function BattleResUtils.DownloadSpineResourceByFullPath(spinePath)
	app.downloadMgr:addResLazyTask(_spn(spinePath))
end

--- 检测 卡牌的技能特效id，根据 skinId 和 原始effectId
--- 优先使用皮肤表中drawId当特效id，因为技能特效spine也是区分皮肤专属的。
--- 但是可能有的特效没有做皮肤专属的特效spine，所以需要先检测一下文件是否存在。
---@param skinId   string @ 卡牌的皮肤id
---@param effectId string @ 配表的特效id
---@return string @ 技能特效id
function BattleResUtils.CheckCardSkillEffectIdBySkinId(skinId, effectId)
	local cardSkinConf  = CardUtils.GetCardSkinConfig(skinId) or {}
	local hasSkinEffect = BattleUtils.SpineHasAnimationByName(cardSkinConf.drawId, SpineType.EFFECT, sp.AnimationName.attack)
	-- local hasSkinEffect = BattleResUtils.IsSpineResourceValid(cardSkinConf.drawId, SpineResType.EFFECT) -- 这个脚本服务器不能跑，因为服务器版是还没有 app.xxx 赋值的
	return hasSkinEffect and cardSkinConf.drawId or effectId
end
---------------------------------------------------
-- 判断资源是否合法 end --
---------------------------------------------------


---------------------------------------------------
-- res info begin --
---------------------------------------------------
--[[
获取卡牌cutin信息
--]]
function BattleResUtils.GetCardCutinSceneConfig()
	return {
		{loadTime = 0.2, scale = 1, path = 'battle/effect/cutin_foreground', 		cacheName = sp.AniCacheName.CARD_CI_FG},
		{loadTime = 0.1, scale = 1, path = 'battle/effect/head_active', 			cacheName = sp.AniCacheName.CARD_CI_HEAD_ACTIVE},
		{loadTime = 0.1, scale = 1, path = 'battle/effect/connect_head_bg', 		cacheName = sp.AniCacheName.CARD_CI_CONNECT_HEAD_BG},
		{loadTime = 0.1, scale = 1, path = 'battle/effect/connect_head_fg', 		cacheName = sp.AniCacheName.CARD_CI_CONNECT_HEAD_FG}
	}
end

--[[
boss弱点场景信息
--]]
function BattleResUtils.GetBossWeakSceneConfig()
	return {
		{loadTime = 0.1, scale = 1, path = 'battle/effect/boss_weak', 				cacheName = sp.AniCacheName.BOSS_WEAK_POINT},
		{loadTime = 0.1, scale = 1, path = 'battle/effect/boss_chant_progressBar', 	cacheName = sp.AniCacheName.BOSS_WEAK_CHANT}
	}
end

--[[
bossci场景
--]]
function BattleResUtils.GetBossCutinSceneConfig()
	return {
		{loadTime = 0.1, scale = 1, jsonPath = 'battle/effect/boss_cutin_bg.json', 		atlasPath = 'battle/effect/boss_cutin.atlas', 	cacheName = sp.AniCacheName.BOSS_CI_BG},
		{loadTime = 0.1, scale = 1, jsonPath = 'battle/effect/boss_cutin_fg.json', 		atlasPath = 'battle/effect/boss_cutin.atlas',	cacheName = sp.AniCacheName.BOSS_CI_FG},
		{loadTime = 0.1, scale = 1, jsonPath = 'battle/effect/boss_cutin_mask.json', 	atlasPath = 'battle/effect/boss_cutin.atlas', 	cacheName = sp.AniCacheName.BOSS_CI_MASK}
	}
end

--[[
买活场景
--]]
function BattleResUtils.GetBuyRevivalSceneConfig()
	return {
		{loadTime = 0.1, scale = 1, path = 'cards/spine/hurt/18', 					cacheName = sp.AniCacheName.BUY_REVIVAL}
	}
end

--[[
目标spine
--]]
function BattleResUtils.GetClearTargetSpineConfig()
	return {
		[ConfigStageCompleteType.SLAY_ENEMY] = {
			loadTime = 0.1, scale = CARD_DEFAULT_SCALE, path = 'battle/effect/battle_target', cacheName = sp.AniCacheName.WAVE_TARGET_MARK
		},
		[ConfigStageCompleteType.HEAL_FRIEND] = {
			loadTime = 0.1, scale = CARD_DEFAULT_SCALE, path = 'battle/effect/battle_target', cacheName = sp.AniCacheName.WAVE_TARGET_MARK
		}
	}
end
---------------------------------------------------
-- res info end --
---------------------------------------------------
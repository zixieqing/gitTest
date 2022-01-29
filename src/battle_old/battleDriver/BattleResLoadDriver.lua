--[[
战斗资源加载驱动
--]]
local BaseBattleDriver = __Require('battle.battleDriver.BaseBattleDriver')
local BattleResLoadDriver = class('BattleResLoadDriver', BaseBattleDriver)

------------ import ------------
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
------------ import ------------

------------ define ------------
local SpineResType = {
	AVATAR 			= 1,
	EFFECT 			= 2,
	HURT 			= 3
}

local SpineResTypeConfig = {
	[SpineResType.AVATAR] 			= {folderPath = 'cards/spine/avatar'},
	[SpineResType.EFFECT]			= {folderPath = 'cards/spine/effect'},
	[SpineResType.HURT] 			= {folderPath = 'cards/spine/hurt'}
}
------------ define ------------

--[[
constructor
--]]
function BattleResLoadDriver:ctor( ... )
	BaseBattleDriver.ctor(self, ...)
	self.driverType = BattleDriverType.RES_LOADER

	local args = unpack({...})

	self:Init()
end
---------------------------------------------------
-- init logic begin --
---------------------------------------------------
--[[
@override
初始化逻辑
--]]
function BattleResLoadDriver:Init()

end
---------------------------------------------------
-- init logic end --
---------------------------------------------------

---------------------------------------------------
-- control logic begin --
---------------------------------------------------
--[[
@override
逻辑开始
@params wave int 波数
--]]
function BattleResLoadDriver:OnLogicEnter(wave)
	self:LoadResources()
end
--[[
@override
逻辑进行中
--]]
function BattleResLoadDriver:OnLogicUpdate(dt)
	
end
--[[
@override
逻辑结束
--]]
function BattleResLoadDriver:OnLogicExit()

end
--[[
加载资源
--]]
function BattleResLoadDriver:LoadResources()
	-- 加载ui资源
	self:LoadUIResources()
	-- 加载spine资源
	self:LoadSpineResources()
	-- 加载音频资源
	-- self:LoadSoundResources()
end
--[[
加载图片
--]]
function BattleResLoadDriver:LoadUIResources()
	local loader = CCResourceLoader:getInstance()

	------------ 加载地图资源 ------------
	local bgInfo = self:GetOwner():GetBData():getBattleBgInfo(self:GetOwner():GetBData():getNextWave())
	local mapId = bgInfo.bgId
	local bgPathPrefix = BattleUtils.GetBgFolderPath(mapId)

	local bgPath = string.format('%s/%s', bgPathPrefix, 'main_map_bg_%d_%d')

	local function LoadBgRes(path, mapId, bgIdx)
		local imagePath = path .. '.png'

		if utils.isExistent(_res(imagePath)) then

			-- 图片
			loader:addCustomTask(cc.CallFunc:create(function ()
				cc.Director:getInstance():getTextureCache():addImage(imagePath)
			end), 0.1)
			return true

		elseif utils.isExistent(_res(path .. '.json')) then

			-- spine
			loader:addCustomTask(cc.CallFunc:create(function ()
				SpineCache(SpineCacheName.BATTLE):addCacheData(
					path,
					BattleUtils.GetBgSpineCacheName(mapId, bgIdx),
					1
				)
			end), 0.1)
			return true

		end

		return false
	end
	------------ 加载地图资源 ------------

	-- 中景
	local bgIdx = 10
	LoadBgRes(string.format(bgPath, mapId, bgIdx), mapId, bgIdx)

	-- 前景
	local i = bgIdx
	while true do
		i = i + 1
		local bgIdx_ = i
		local loadSuccess = LoadBgRes(string.format(bgPath, mapId, bgIdx_), mapId, bgIdx_)
		if not loadSuccess then
			break
		end
	end

	-- 背景
	local i = bgIdx
	while true do
		i = i - 1
		local bgIdx_ = i
		local loadSuccess = LoadBgRes(string.format(bgPath, mapId, bgIdx_), mapId, bgIdx_)
		if not loadSuccess then
			break
		end
	end
end
--[[
加载spine资源
--]]
function BattleResLoadDriver:LoadSpineResources()
	local loader = CCResourceLoader:getInstance()

	local avatarSpine = {}
	local effectSpine = {}
	local hurtSpine = {}

	local needLoadBossWeak = false
	local needLoadBossCutin = false
	local needLoadCardCutin = false

	local questType = self:GetOwner():GetBData():getBattleConstructData().questBattleType

	------------ 己方卡牌 ------------
	local objectConfigId = nil
	local cardConf = nil
	local skillConf = nil

	local friendTeamMembers = self:GetOwner():GetBData():getFriendMembers(1)

	for i, cardData in ipairs(friendTeamMembers) do
		objectConfigId = cardData:GetObjectConfigId()
		local extraNeedLoad = self:ConvertNeedLoadResourcesByCardId(
			objectConfigId,
			checkint(cardData.skinId),
			avatarSpine, effectSpine, hurtSpine
		)
		if true == extraNeedLoad.needLoadBossWeak then
			needLoadBossWeak = true
		end
		if true == extraNeedLoad.needLoadBossCutin then
			needLoadBossCutin = true
		end
		-- 检测连携技是否可用加载卡牌ci特效动画
		cardConf = CardUtils.GetCardConfig(objectConfigId)
		for i,v in ipairs(cardConf.skill) do
			skillConf = CommonUtils.GetSkillConf(checkint(v)) or {}
			if nil ~= skillConf then
				if ConfigSkillType.SKILL_CONNECT == checkint(skillConf.property) then
					if CardUtils.IsConnectSkillEnable(objectConfigId, friendTeamMembers, checkint(v)) then
						needLoadCardCutin = true
					end
				end
			end
		end
	end
	------------ 己方卡牌 ------------

	------------ 敌方卡牌 ------------
	if self:GetOwner():IsCardVSCard() then
		-- pvc
		local allEnemyMembers = self:GetOwner():GetBData():getEnemyMembers()

		for waveId, waveConf in ipairs(allEnemyMembers) do
			for i, cardData in ipairs(waveConf) do
				objectConfigId = cardData:GetObjectConfigId()
				local extraNeedLoad = self:ConvertNeedLoadResourcesByCardId(
					objectConfigId,
					checkint(cardData.skinId),
					avatarSpine, effectSpine, hurtSpine
				)
				if true == extraNeedLoad.needLoadBossWeak then
					needLoadBossWeak = true
				end
				if true == extraNeedLoad.needLoadBossCutin then
					needLoadBossCutin = true
				end
			end
		end
	else
		local allEnemyMembers = self:GetOwner():GetBData():getEnemyMembers()
		for waveId, waveConf in pairs(allEnemyMembers) do
			for i, npcConf in ipairs(waveConf) do
				objectConfigId = npcConf:GetObjectConfigId()
				local extraNeedLoad = self:ConvertNeedLoadResourcesByCardId(
					objectConfigId,
					checkint(npcConf.skinId),
					avatarSpine, effectSpine, hurtSpine
				)
				if true == extraNeedLoad.needLoadBossWeak then
					needLoadBossWeak = true
				end
				if true == extraNeedLoad.needLoadBossCutin then
					needLoadBossCutin = true
				end
			end
		end

		-- 转阶段动画资源加载逻辑
		if nil ~= self:GetOwner():GetBData():getPhaseChangeData() then
			for npcId, phases in pairs(self:GetOwner():GetBData():getPhaseChangeData()) do
				-- 首先加载一次触发怪物
				local extraNeedLoad = self:ConvertNeedLoadResourcesByCardId(
					checkint(npcId),
					CardUtils.GetCardSkinId(checkint(npcId)),
					avatarSpine, effectSpine, hurtSpine
				)
				if true == extraNeedLoad.needLoadBossWeak then
					needLoadBossWeak = true
				end
				if true == extraNeedLoad.needLoadBossCutin then
					needLoadBossCutin = true
				end
				for i, phaseData in ipairs(phases) do
					if ConfigPhaseType.TALK_DEFORM == phaseData.phaseType then

						------------ 变身 需要加载变身后 和变身特效 ------------
						for i, deformInfo in ipairs(phaseData.phaseData) do
							local extraNeedLoad = self:ConvertNeedLoadResourcesByCardId(
								checkint(deformInfo.deformToId),
								CardUtils.GetCardSkinId(deformInfo.deformToId),
								avatarSpine, effectSpine, hurtSpine
							)
							if true == extraNeedLoad.needLoadBossWeak then
								needLoadBossWeak = true
							end
							if true == extraNeedLoad.needLoadBossCutin then
								needLoadBossCutin = true
							end

							loader:addCustomTask(cc.CallFunc:create(function ()
								SpineCache(SpineCacheName.BATTLE):addCacheData('battle/effect/phase_deform_effect', 'phase_deform_effect', 1)
							end), 0.1)
						end
						------------ 变身 需要加载变身后 和变身特效 ------------

					elseif ConfigPhaseType.BECKON_ADDITION_FORCE == phaseData.phaseType or
						ConfigPhaseType.BECKON_ADDITION == phaseData.phaseType or
						ConfigPhaseType.BECKON_CUSTOMIZE == phaseData.phaseType then

						------------ 召唤add 需要加载召唤的小怪 ------------
						for i, beckonNpc in ipairs(phaseData.phaseData) do
							local extraNeedLoad = self:ConvertNeedLoadResourcesByCardId(
								checkint(beckonNpc.beckonNpcId),
								CardUtils.GetCardSkinId(beckonNpc.beckonNpcId),
								avatarSpine, effectSpine, hurtSpine
							)
							if true == extraNeedLoad.needLoadBossWeak then
								needLoadBossWeak = true
							end
							if true == extraNeedLoad.needLoadBossCutin then
								needLoadBossCutin = true
							end
						end
						------------ 召唤add 需要加载召唤的小怪 ------------

					elseif ConfigPhaseType.DEFORM_CUSTOMIZE == phaseData.phaseType then

						------------ 变身 ------------
						for i, deformInfo in ipairs(phaseData.phaseData) do
							local extraNeedLoad = self:ConvertNeedLoadResourcesByCardId(
								checkint(deformInfo.deformToId),
								CardUtils.GetCardSkinId(deformInfo.deformToId),
								avatarSpine, effectSpine, hurtSpine
							)

							if true == extraNeedLoad.needLoadBossWeak then
								needLoadBossWeak = true
							end
							if true == extraNeedLoad.needLoadBossCutin then
								needLoadBossCutin = true
							end
						end
						------------ 变身 ------------

					end
				end
			end
		end
	end
	------------ 敌方卡牌 ------------

	------------ 天气 ------------
	local weatherId = nil
	local weatherConf = nil
	if nil ~= self:GetOwner():GetBData():getStageWeatherConf() then
		for i,v in ipairs(self:GetOwner():GetBData():getStageWeatherConf()) do
			weatherId = checkint(v)
			weatherConf = CommonUtils.GetConfig('quest', 'weather', weatherId)
			self:ConvertNeedLoadResourcesBySkill(
				weatherConf.skillId,
				ConfigSpecialCardId.WEATHER,
				ConfigSpecialCardId.WEATHER,
				0.5,
				avatarSpine, effectSpine, hurtSpine
			)
		end
	end
	------------ 天气 ------------

	------------ 主角技 ------------
	local playerSkills = {}
	for i,v in ipairs(self:GetOwner():GetBData():getPlayerSkilInfo(false).activeSkill) do
		table.insert(playerSkills, checkint(v.skillId))
	end
	self:ConvertNeedLoadResourcesBySkill(
		playerSkills,
		ConfigSpecialCardId.PLAYER,
		ConfigSpecialCardId.PLAYER,
		0.5,
		avatarSpine, effectSpine, hurtSpine
	)
	------------ 主角技 ------------
	
	------------ 加载 ------------
	local loadedSpine = {}
	for i,v in ipairs(avatarSpine) do
		if nil == loadedSpine[tostring(v.cacheName)] then
			if self:IsSpineResourceValidByFullPath(v.path) then
				loader:addCustomTask(cc.CallFunc:create(function ()
					SpineCache(SpineCacheName.BATTLE):addCacheData(v.path, v.cacheName, v.scale)
				end), 0.1)
				loadedSpine[tostring(v.cacheName)] = true
			end
		end
	end

	for i,v in ipairs(effectSpine) do
		if nil == loadedSpine[tostring(v.cacheName)] then
			if self:IsSpineResourceValidByFullPath(v.path) then
				loader:addCustomTask(cc.CallFunc:create(function ()
					SpineCache(SpineCacheName.BATTLE):addCacheData(v.path, v.cacheName, v.scale)
				end), 0.1)
				loadedSpine[tostring(v.cacheName)] = true
			end
		end
	end

	for i,v in ipairs(hurtSpine) do
		if nil == loadedSpine[tostring(v.cacheName)] then
			if self:IsSpineResourceValidByFullPath(v.path) then
				loader:addCustomTask(cc.CallFunc:create(function ()
					SpineCache(SpineCacheName.BATTLE):addCacheData(v.path, v.cacheName, v.scale)
				end), 0.1)
				loadedSpine[tostring(v.cacheName)] = true
			end
		end
	end
	------------ 加载 ------------

	------------ 场景特效 ------------
	if needLoadCardCutin then
		loader:addCustomTask(cc.CallFunc:create(function ()
			SpineCache(SpineCacheName.BATTLE):addCacheData('battle/effect/cutin_foreground', 'cutin_2', 1)
		end), 0.2)
		loader:addCustomTask(cc.CallFunc:create(function ()
			SpineCache(SpineCacheName.BATTLE):addCacheData('battle/effect/head_active', 'head_active', 1)
		end), 0.1)
		loader:addCustomTask(cc.CallFunc:create(function ()
			SpineCache(SpineCacheName.BATTLE):addCacheData('battle/effect/connect_head_bg', 'connect_head_1', 1)
		end), 0.1)
		loader:addCustomTask(cc.CallFunc:create(function ()
			SpineCache(SpineCacheName.BATTLE):addCacheData('battle/effect/connect_head_fg', 'connect_head_2', 1)
		end), 0.1)
	end
	if needLoadBossWeak then
		loader:addCustomTask(cc.CallFunc:create(function ()
			SpineCache(SpineCacheName.BATTLE):addCacheData('battle/effect/boss_weak', 'boss_weak', 1)
		end), 0.1)
		loader:addCustomTask(cc.CallFunc:create(function ()
			SpineCache(SpineCacheName.BATTLE):addCacheData('battle/effect/boss_chant_progressBar', 'boss_chant_progressBar', 1)
		end), 0.1)
	end
	if needLoadBossCutin then
		loader:addCustomTask(cc.CallFunc:create(function ()
			SpineCache(SpineCacheName.BATTLE):addCacheData('battle/effect/boss_cutin_bg.json', 'battle/effect/boss_cutin.atlas', 'boss_cutin_1', 1)
		end), 0.1)
		loader:addCustomTask(cc.CallFunc:create(function ()
			SpineCache(SpineCacheName.BATTLE):addCacheData('battle/effect/boss_cutin_fg.json', 'battle/effect/boss_cutin.atlas', 'boss_cutin_2', 1)
		end), 0.1)
		loader:addCustomTask(cc.CallFunc:create(function ()
			SpineCache(SpineCacheName.BATTLE):addCacheData('battle/effect/boss_cutin_mask.json', 'battle/effect/boss_cutin.atlas', 'boss_cutin_mask', 1)
		end), 0.1)
	end
	------------ 场景特效 ------------

	------------ 复活特效 ------------
	if self:GetOwner():GetBData():canBuyRevival() then
		-- 如果可以买活 加载一次复活特效
		local revivalSpinePath = 'cards/spine/hurt/18'
		local revivalSpineName = 'hurt_18'

		if self:IsSpineResourceValidByFullPath(revivalSpinePath) then
			loader:addCustomTask(cc.CallFunc:create(function ()
				SpineCache(SpineCacheName.BATTLE):addCacheData(revivalSpinePath, revivalSpineName, 1)
			end), 0.1)
		end
	end
	------------ 复活特效 ------------

	------------ 过关目标特效 ------------
	local targetSpine = {}
	for wave, v in ipairs(self:GetOwner():GetBData():getBattleConstructData().stageCompleteInfo) do
		if ConfigStageCompleteType.SLAY_ENEMY == v.completeType then
			targetSpine['wavetarget'] = {path = 'battle/effect/battle_target', scale = CARD_DEFAULT_SCALE}
		elseif ConfigStageCompleteType.HEAL_FRIEND == v.completeType then
			targetSpine['wavetarget'] = {path = 'battle/effect/battle_target', scale = CARD_DEFAULT_SCALE}
		elseif ConfigStageCompleteType.ALIVE == v.completeType then

		end
	end
	for spineName, loadInfo in pairs(targetSpine) do
		if utils.isExistent(_res(loadInfo.path .. '.json')) then
			loader:addCustomTask(cc.CallFunc:create(function ()
				SpineCache(SpineCacheName.BATTLE):addCacheData(loadInfo.path, spineName, loadInfo.scale)
			end), 0.1)
		end
	end
	------------ 过关目标特效 ------------
end
--[[
加载战斗特效
--]]
function BattleResLoadDriver:LoadSoundResources()
	app.audioMgr:AddCueSheet(AUDIOS.BATTLE.name, AUDIOS.BATTLE.acb, "")
end
---------------------------------------------------
-- control logic end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
根据卡牌转换需要加载资源的数据结构
@params cardId int 卡牌id
@params skinId int 皮肤id
@params avatarSpine table 需要加载的卡牌spine集合
@params effectSpine table 需要加载的特效spine集合
@params hurtSpine table 需要加载的爆点附加效果spine集合
@return extraNeedLoad table {
	needLoadBossWeak bool 是否需要加载boss弱点动画
	needLoadBossCutin bool 是否需要加载boss cut in 
}
--]]
function BattleResLoadDriver:ConvertNeedLoadResourcesByCardId(cardId, skinId, avatarSpine, effectSpine, hurtSpine)
	local extraNeedLoad = {
		needLoadBossWeak = false,
		needLoadBossCutin = false
	}

	local skinConfig = CardUtils.GetCardSkinConfig(skinId)
	local cardConf = CardUtils.GetCardConfig(cardId)

	local scale = CARD_DEFAULT_SCALE
	local isMonster = false

	if true == CardUtils.IsMonsterCard(cardId) then

		isMonster = true

		-- 判断卡牌初始缩放比 以及是否加载弱点等信息
		if ConfigMonsterType.ELITE == checkint(cardConf.type) then
			scale = ELITE_DEFAULT_SCALE
			extraNeedLoad.needLoadBossWeak = true
		elseif ConfigMonsterType.BOSS == checkint(cardConf.type) then
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
			print('error >>> even can not find default skin config when battle load resources -> ', cardId)
			return extraNeedLoad
		else
			spineId = tostring(skinConfig.spineId)
		end
	else
		spineId = tostring(skinConfig.spineId)
	end

	if not utils.isExistent(_res(string.format('cards/spine/avatar/%s.json', tostring(skinConfig.spineId)))) then

		-- new spine --
		-- 不再做容错 交给CardSpine节点判断
		return extraNeedLoad
		-- new spine --

		--[[ old spine --
		-- 默认皮肤对应的spine文件不存在
		spineId = 200001
		-- old spine ]]--
	end

	local avatarSpineAniName = self:GetAvatarAniNameById(spineId)
	table.insert(avatarSpine, 1, SpineAnimationCacheInfoStruct.New(
		avatarSpineAniName,
		AssetsUtils.GetCardSpinePath(spineId),
		scale,
		skinId
	))
	-- if nil == avatarSpine[avatarSpineAniName] then
	-- 	avatarSpine[avatarSpineAniName] = SpineAnimationCacheInfoStruct.New(
	-- 		avatarSpineAniName,
	-- 		AssetsUtils.GetCardSpinePath(spineId),
	-- 		scale,
	-- 		skinId
	-- 	)
	-- end
	------------ 添加需要加载卡牌动画的spine ------------

	------------ 添加普攻特效 ------------
	local effectConf = CardUtils.GetCardEffectConfigBySkinId(cardId, skinId)
	if nil ~= effectConf then

		local attackEffectConf = effectConf['-1']

		if nil ~= attackEffectConf then

			-- 动作特效
			local attackEffectName = self:GetEffectAniNameById(tostring(attackEffectConf.effectId))
			if 0 ~= checkint(attackEffectConf.effectId) then
				table.insert(effectSpine, 1, SpineAnimationCacheInfoStruct.New(
					attackEffectName,
					string.format('cards/spine/effect/%s', tostring(attackEffectConf.effectId)),
					scale,
					skinId
				))
			end
			-- if 0 ~= checkint(attackEffectConf.effectId) and nil == effectSpine[attackEffectName] then
			-- 	effectSpine[attackEffectName] = SpineAnimationCacheInfoStruct.New(
			-- 		attackEffectName,
			-- 		string.format('cards/spine/effect/%s', tostring(attackEffectConf.effectId)),
			-- 		scale,
			-- 		skinId
			-- 	)
			-- end

			-- 爆点特效
			local attackHurtName = self:GetHurtAniNameById(tostring(attackEffectConf.effect.hitEffect))
			if 0 ~= checkint(attackEffectConf.effect.hitEffect) then
				table.insert(hurtSpine, 1, SpineAnimationCacheInfoStruct.New(
					attackHurtName,
					string.format('cards/spine/hurt/%s', tostring(attackEffectConf.effect.hitEffect)),
					CARD_DEFAULT_SCALE,
					skinId
				))
			end
			-- if 0 ~= checkint(attackEffectConf.effect.hitEffect) and nil == hurtSpine[attackHurtName] then
			-- 	hurtSpine[attackHurtName] = SpineAnimationCacheInfoStruct.New(
			-- 		attackHurtName,
			-- 		string.format('cards/spine/hurt/%s', tostring(attackEffectConf.effect.hitEffect)),
			-- 		CARD_DEFAULT_SCALE,
			-- 		skinId
			-- 	)
			-- end

			-- 附加效果特效
			local attackAttachName = self:GetHurtAniNameById(tostring(attackEffectConf.effect.addEffect))
			if 0 ~= checkint(attackEffectConf.effect.addEffect) then
				table.insert(hurtSpine, 1, SpineAnimationCacheInfoStruct.New(
					attackAttachName,
					string.format('cards/spine/hurt/%s', tostring(attackEffectConf.effect.addEffect)),
					CARD_DEFAULT_SCALE,
					skinId
				))
			end
			-- if 0 ~= checkint(attackEffectConf.effect.addEffect) and nil == hurtSpine[attackAttachName] then
			-- 	hurtSpine[attackAttachName] = SpineAnimationCacheInfoStruct.New(
			-- 		attackAttachName,
			-- 		string.format('cards/spine/hurt/%s', tostring(attackEffectConf.effect.addEffect)),
			-- 		CARD_DEFAULT_SCALE,
			-- 		skinId
			-- 	)
			-- end

		end
	end
	------------ 添加普攻特效 ------------

	------------ 添加技能特效 ------------
	self:ConvertNeedLoadResourcesBySkill(
		cardConf.skill, cardId, skinId, scale,
		avatarSpine, effectSpine, hurtSpine
	)
	------------ 添加技能特效 ------------

	return extraNeedLoad
	------------ 添加需要加载卡牌动画的spine ------------
end
--[[
根据技能和特效配置转换需要加载的除了人物spine以外的特效资源
@params skill table 技能集合
@params effectConfId int 特效配置表中的id
@params skinId int 皮肤id
@params scale number 缩放比
@params avatarSpine table 需要加载的卡牌spine集合
@params effectSpine table 需要加载的特效spine集合
@params hurtSpine table 需要加载的爆点附加效果spine集合
--]]
function BattleResLoadDriver:ConvertNeedLoadResourcesBySkill(skill, effectConfId, skinId, scale, avatarSpine, effectSpine, hurtSpine)
	local effectConf = CardUtils.GetCardEffectConfigBySkinId(effectConfId, skinId)

	local skillId = 0
	local skillEffectConf = nil
	local bulletEffectName = nil
	local hurtEffectName = nil
	local attachEffectName = nil
	for i,v in ipairs(skill) do
		skillId = checkint(v)

		-- 如果是召唤系技能 加载召唤出来的怪物
		local skillConf = CommonUtils.GetSkillConf(skillId)
		if nil ~= skillConf and nil ~= skillConf.type[tostring(ConfigBuffType.BECKON)] then
			local effect = CardUtils.GetFixedSkillEffect(skillId, 1)
			for i,beckonObjId in ipairs(effect[tostring(ConfigBuffType.BECKON)].effect) do
				self:ConvertNeedLoadResourcesByCardId(
					checkint(beckonObjId),
					CardUtils.GetCardSkinId(checkint(beckonObjId)),
					avatarSpine, effectSpine, hurtSpine
				)
			end
		end

		if nil ~= effectConf then

			------------ 技能特效 ------------
			skillEffectConf = effectConf[tostring(skillId)]
			if nil ~= skillEffectConf then
				-- 发射的子弹特效
				bulletEffectName = self:GetEffectAniNameById(tostring(skillEffectConf.effectId))
				if 0 ~= checkint(skillEffectConf.effectId) then
					table.insert(effectSpine, 1, SpineAnimationCacheInfoStruct.New(
						bulletEffectName,
						string.format('cards/spine/effect/%s', tostring(skillEffectConf.effectId)),
						scale,
						skinId
					))
				end
				-- if 0 ~= checkint(skillEffectConf.effectId) and nil == effectSpine[bulletEffectName] then
				-- 	effectSpine[bulletEffectName] = SpineAnimationCacheInfoStruct.New(
				-- 		bulletEffectName,
				-- 		string.format('cards/spine/effect/%s', tostring(skillEffectConf.effectId)),
				-- 		scale,
				-- 		skinId
				-- 	)
				-- end

				for buffType, buffEffectConf in pairs(skillEffectConf.effect) do
					-- 爆点特效
					hurtEffectName = self:GetHurtAniNameById(tostring(buffEffectConf.hitEffect))
					if 0 ~= checkint(buffEffectConf.hitEffect) then
						table.insert(hurtSpine, 1, SpineAnimationCacheInfoStruct.New(
							hurtEffectName,
							string.format('cards/spine/hurt/%s', tostring(buffEffectConf.hitEffect)),
							CARD_DEFAULT_SCALE,
							skinId
						))
					end
					-- if 0 ~= checkint(buffEffectConf.hitEffect) and nil == hurtSpine[hurtEffectName] then
					-- 	hurtSpine[hurtEffectName] = SpineAnimationCacheInfoStruct.New(
					-- 		hurtEffectName,
					-- 		string.format('cards/spine/hurt/%s', tostring(buffEffectConf.hitEffect)),
					-- 		CARD_DEFAULT_SCALE,
					-- 		skinId
					-- 	)
					-- end

					-- 附加效果
					attachEffectName = self:GetHurtAniNameById(tostring(buffEffectConf.addEffect))
					if 0 ~= checkint(buffEffectConf.addEffect) then
						table.insert(hurtSpine, 1, SpineAnimationCacheInfoStruct.New(
							attachEffectName,
							string.format('cards/spine/hurt/%s', tostring(buffEffectConf.addEffect)),
							CARD_DEFAULT_SCALE,
							skinId
						))
					end
					-- if 0 ~= checkint(buffEffectConf.addEffect) and nil == hurtSpine[attachEffectName] then
					-- 	hurtSpine[attachEffectName] = SpineAnimationCacheInfoStruct.New(
					-- 		attachEffectName,
					-- 		string.format('cards/spine/hurt/%s', tostring(buffEffectConf.addEffect)),
					-- 		CARD_DEFAULT_SCALE,
					-- 		skinId
					-- 	)
					-- end
				end
			end
			------------ 技能特效 ------------

		end
	end
end
--[[
根据id获取spine avatar缓存名
@params id int 动画的id
@return _ string animation name in cache
--]]
function BattleResLoadDriver:GetAvatarAniNameById(id)
	return tostring(id)
end
--[[
根据id获取spine effect 缓存名
@params id int 动画的id
@return _ string animation name in cache
--]]
function BattleResLoadDriver:GetEffectAniNameById(id)
	return string.format('effect_%s', tostring(id))
end
--[[
根据id获取spine 被击 缓存名
@params id int 动画的id
@return _ string animation name in cache
--]]
function BattleResLoadDriver:GetHurtAniNameById(id)
	return string.format('hurt_%s', tostring(id))
end
--[[
判断整套资源是否合法
@params spineId string spine的id
@params spineResType SpineResType spine资源类型
@return _ bool 整套资源是否合法
--]]
function BattleResLoadDriver:IsSpineResourceValid(spineId, spineResType)
	local spineResTypeConfig = SpineResTypeConfig[spineResType]

	local spinePath = string.format('%s/%s', spineResTypeConfig.folderPath, spineId)

	return self:IsSpineResourceValidByFullPath(spinePath)
end
--[[
根据全路径判断整套资源是否合法
@params spinePath string spine资源的全路径
@return _ bool 整套资源是否合法
--]]
function BattleResLoadDriver:IsSpineResourceValidByFullPath(spinePath)
	local isValidity, verifyMap = app.gameResMgr:verifySpine(spinePath)
	if not isValidity and verifyMap and verifyMap['atlas'] and verifyMap['atlas'].remoteDefine then
		-- 资源不合法 请求一次download
		self:DownloadSpineResourceByFullPath(spinePath)
	end
	return isValidity
end
--[[
根据路径请求下载spine资源
@params spinePath string
--]]
function BattleResLoadDriver:DownloadSpineResourceByFullPath(spinePath)
	app.downloadMgr:addResLazyTask(_spn(spinePath))
end
---------------------------------------------------
-- get set begin --
---------------------------------------------------

return BattleResLoadDriver

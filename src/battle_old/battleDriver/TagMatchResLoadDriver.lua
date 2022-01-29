--[[
车轮战资源加载驱动
--]]
local BattleResLoadDriver = __Require('battle.battleDriver.BattleResLoadDriver')
local TagMatchResLoadDriver = class('TagMatchResLoadDriver', BattleResLoadDriver)

------------ import ------------
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
------------ import ------------

------------ define ------------
------------ define ------------

---------------------------------------------------
-- init logic begin --
---------------------------------------------------
--[[
@override
初始化逻辑
--]]
function TagMatchResLoadDriver:Init()
	self.spineAnimationsCache = {}
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
@params friendTeamIndex int 友军队伍号
@params enemyTeamIndex int 敌军队伍号
--]]
function TagMatchResLoadDriver:OnLogicEnter(wave, friendTeamIndex, enemyTeamIndex)
	self:LoadResources(wave, friendTeamIndex, enemyTeamIndex)
end
--[[
@override
加载资源
@params wave int 波数
@params friendTeamIndex int 友军队伍号
@params enemyTeamIndex int 敌军队伍号
--]]
function TagMatchResLoadDriver:LoadResources(wave, friendTeamIndex, enemyTeamIndex)
	if 1 == wave then
		-- 第一波时加载一些额外资源
		-- 加载ui资源
		self:LoadUIResources()
	end

	-- 加载spine资源
	self:LoadSpineResources(wave, friendTeamIndex, enemyTeamIndex)
end
--[[
@override
加载spine资源
@params wave int 波数
@params friendTeamIndex int 友军队伍号
@params enemyTeamIndex int 敌军队伍号
--]]
function TagMatchResLoadDriver:LoadSpineResources(wave, friendTeamIndex, enemyTeamIndex)
	local loader = CCResourceLoader:getInstance()

	local avatarSpine = {}
	local effectSpine = {}
	local hurtSpine = {}

	local needLoadBossWeak = false
	local needLoadBossCutin = false
	local needLoadCardCutin = false

	friendTeamIndex = nil == friendTeamIndex and 1 or friendTeamIndex
	enemyTeamIndex = nil == enemyTeamIndex and 1 or enemyTeamIndex

	local isFriendWin = ValueConstants.V_NONE
	local endDriver = nil

	if 1 < wave then
		endDriver = self:GetOwner():GetEndDriver(self:GetOwner():GetBData():getNextWave() - 1)
	end

	if nil ~= endDriver then
		isFriendWin = endDriver:IsFriendWin()
	end

	------------ 己方卡牌 ------------
	local objectConfigId = nil

	local friendTeamMembers = self:GetOwner():GetBData():getFriendMembers(friendTeamIndex)

	if ValueConstants.V_NORMAL ~= isFriendWin and nil ~= friendTeamMembers then
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
	end
	------------ 己方卡牌 ------------

	------------ 敌方卡牌 ------------
	local enemyTeamMembers = self:GetOwner():GetBData():getEnemyMembers(enemyTeamIndex)

	if ValueConstants.V_INFINITE ~= isFriendWin and nil ~= enemyTeamMembers then
		for i, cardData in ipairs(enemyTeamMembers) do
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
	------------ 敌方卡牌 ------------

	if 1 == wave then
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

		------------ 复活特效 ------------
		if self:GetOwner():GetBData():canBuyRevival() then
			-- 如果可以买活 加载一次复活特效
			loader:addCustomTask(cc.CallFunc:create(function ()
				SpineCache(SpineCacheName.BATTLE):addCacheData('cards/spine/hurt/18', 'hurt_18', 1)
			end), 0.1)
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
	elseif 1 < wave then
		------------ 过滤一次需要保留的资源和需要删除的资源 ------------
		local aliveTargets = nil
		local deadTargets = nil

		if ValueConstants.V_NORMAL == isFriendWin then
			aliveTargets = self:GetOwner():GetBData():getFriendMembers(friendTeamIndex - 1)
			deadTargets = self:GetOwner():GetBData():getEnemyMembers(enemyTeamIndex - 1)
		elseif ValueConstants.V_INFINITE == isFriendWin then
			aliveTargets = self:GetOwner():GetBData():getEnemyMembers(enemyTeamIndex - 1)
			deadTargets = self:GetOwner():GetBData():getFriendMembers(friendTeamIndex - 1)
		end

		local obj = nil
		local objSkinId = nil

		-- 保留存活的资源
		for i = #aliveTargets, 1, -1 do
			obj = aliveTargets[i]
			objSkinId = obj.skinId
			local caches = self:GetAniCacheInfoBySkinId(objSkinId)
			for cacheName, _ in pairs(caches) do
				local aniCacheInfo = self:GetAniCacheInfo(cacheName)
				if nil ~= aniCacheInfo then
					aniCacheInfo.nextRemove = false
					aniCacheInfo.skins[tostring(objSkinId)] = ValueConstants.V_NORMAL
				end
			end

			-- /***********************************************************************************************************************************\
			--  * 此处移除一次物体身上的附加特效spine 防止由需要杀死的物体导致移除spine缓存时会造成空指针的问题
			-- \***********************************************************************************************************************************/
			-- obj:clearBuff()
			-- for bid, effectSpine_ in pairs(obj.view.viewComponent.attachEffects) do
			-- 	if nil == obj:getBuffByBuffId(bid) then
			-- 		-- 附加特效对应的效果不存在 移除spine
			-- 		effectSpine_:setVisible(false)
			-- 		effectSpine_:clearTracks()
			-- 		effectSpine_:removeFromParent()
			-- 		obj.view.viewComponent.attachEffects[bid] = nil
			-- 	end
			-- end
			-- /***********************************************************************************************************************************\
			--  * 此处移除一次物体身上的附加特效spine 防止由需要杀死的物体导致移除spine缓存时会造成空指针的问题
			-- \***********************************************************************************************************************************/
		end

		-- 删除死亡的资源
		for i = #deadTargets, 1, -1 do
			obj = deadTargets[i]
			objSkinId = obj.skinId

			local caches = self:GetAniCacheInfoBySkinId(objSkinId)
			for cacheName, _ in pairs(caches) do
				local aniCacheInfo = self:GetAniCacheInfo(cacheName)
				if nil ~= aniCacheInfo and aniCacheInfo.nextRemove then
					aniCacheInfo.nextRemove = true
					aniCacheInfo.skins[tostring(objSkinId)] = nil
				end
			end
		end

		------------ 去掉已经加载的资源 ------------
		local aniCacheInfo = nil
		local aniData = nil

		-- avatar		
		for i = #avatarSpine, 1, -1 do
			aniData = avatarSpine[i]
			aniCacheInfo = self:GetAniCacheInfo(aniData.cacheName)
			if nil ~= aniCacheInfo then
				aniCacheInfo.nextRemove = false
				aniCacheInfo.skins[tostring(aniData.skinId)] = ValueConstants.V_NORMAL
				table.remove(avatarSpine, i)
			end
		end

		-- for k,v in pairs(avatarSpine) do
		-- 	aniCacheInfo = self:GetAniCacheInfo(v.cacheName)
		-- 	if nil ~= aniCacheInfo then
		-- 		aniCacheInfo.nextRemove = false
		-- 		aniCacheInfo.skins[tostring(v.skinId)] = ValueConstants.V_NORMAL
		-- 		avatarSpine[k] = nil
		-- 	end
		-- end

		-- effect
		for i = #effectSpine, 1, -1 do
			aniData = effectSpine[i]
			aniCacheInfo = self:GetAniCacheInfo(aniData.cacheName)
			if nil ~= aniCacheInfo then
				aniCacheInfo.nextRemove = false
				aniCacheInfo.skins[tostring(aniData.skinId)] = ValueConstants.V_NORMAL
				table.remove(effectSpine, i)
			end
		end

		-- for k,v in pairs(effectSpine) do
		-- 	aniCacheInfo = self:GetAniCacheInfo(v.cacheName)
		-- 	if nil ~= aniCacheInfo then
		-- 		aniCacheInfo.nextRemove = false
		-- 		aniCacheInfo.skins[tostring(v.skinId)] = ValueConstants.V_NORMAL
		-- 		effectSpine[k] = nil
		-- 	end
		-- end

		-- hurt
		for i = #hurtSpine, 1, -1 do
			aniData = hurtSpine[i]
			aniCacheInfo = self:GetAniCacheInfo(aniData.cacheName)
			if nil ~= aniCacheInfo then
				aniCacheInfo.nextRemove = false
				aniCacheInfo.skins[tostring(aniData.skinId)] = ValueConstants.V_NORMAL
				table.remove(hurtSpine, i)
			end
		end

		-- for k,v in pairs(hurtSpine) do
		-- 	aniCacheInfo = self:GetAniCacheInfo(v.cacheName)
		-- 	if nil ~= aniCacheInfo then
		-- 		aniCacheInfo.nextRemove = false
		-- 		aniCacheInfo.skins[tostring(v.skinId)] = ValueConstants.V_NORMAL
		-- 		hurtSpine[k] = nil
		-- 	end
		-- end
		------------ 去掉已经加载的资源 ------------

		-- 卸载无用的资源
		for cacheName, cacheInfo in pairs(self.spineAnimationsCache) do
			if true == cacheInfo.nextRemove then

				-- /***********************************************************************************************************************************\
				--  * 此处移除一次物体身上的附加特效spine 防止由需要杀死的物体导致移除spine缓存时会造成空指针的问题
				-- \***********************************************************************************************************************************/
				BMediator:ForceRemoveAttachEffectByEffectId(BattleUtils:GetAniIdByCacheName(cacheName))
				-- /***********************************************************************************************************************************\
				--  * 此处移除一次物体身上的附加特效spine 防止由需要杀死的物体导致移除spine缓存时会造成空指针的问题
				-- \***********************************************************************************************************************************/

				self:RemoveAniCacheInfo(cacheName)
				SpineCache(SpineCacheName.BATTLE):removeCacheData(cacheName)

			end
		end

		-- 移除不需要的纹理
		display.removeUnusedSpriteFrames()
		------------ 过滤一次需要保留的资源和需要删除的资源 ------------
	end



	-- 加载
	local loadedSpine = {}
	for i,v in ipairs(avatarSpine) do
		if self:IsSpineResourceValidByFullPath(v.path) then
			if nil == loadedSpine[tostring(v.cacheName)] then
				if 1 == wave then
					loader:addCustomTask(cc.CallFunc:create(function ()
						SpineCache(SpineCacheName.BATTLE):addCacheData(v.path, v.cacheName, v.scale)
					end), 0.1)
				else
					SpineCache(SpineCacheName.BATTLE):addCacheData(v.path, v.cacheName, v.scale)
				end
				loadedSpine[tostring(v.cacheName)] = true
			end
			-- 记录一次数据
			self:AddAniCacheInfo(v)
		end
	end

	-- for k,v in pairs(avatarSpine) do
	-- 	if utils.isExistent(_res(v.path .. '.json')) then
	-- 		if 1 == wave then
	-- 			loader:addCustomTask(cc.CallFunc:create(function ()

	-- 				SpineCache(SpineCacheName.BATTLE):addCacheData(v.path, k, v.scale)

	-- 			end), 0.1)
	-- 		else
	-- 			SpineCache(SpineCacheName.BATTLE):addCacheData(v.path, k, v.scale)
	-- 		end
			
	-- 		-- 记录一次数据
	-- 		self:AddAniCacheInfo(v)
	-- 	end
	-- end

	for i,v in ipairs(effectSpine) do
		if self:IsSpineResourceValidByFullPath(v.path) then
			if nil == loadedSpine[tostring(v.cacheName)] then
				if 1 == wave then
					loader:addCustomTask(cc.CallFunc:create(function ()
						SpineCache(SpineCacheName.BATTLE):addCacheData(v.path, v.cacheName, v.scale)
					end), 0.1)
				else
					SpineCache(SpineCacheName.BATTLE):addCacheData(v.path, v.cacheName, v.scale)
				end
				loadedSpine[tostring(v.cacheName)] = true
			end
			-- 记录一次数据
			self:AddAniCacheInfo(v)
		end
	end

	-- for k,v in pairs(effectSpine) do
	-- 	if utils.isExistent(_res(v.path .. '.json')) then
	-- 		if 1 == wave then
	-- 			loader:addCustomTask(cc.CallFunc:create(function ()

	-- 				SpineCache(SpineCacheName.BATTLE):addCacheData(v.path, k, v.scale)

	-- 			end), 0.1)
	-- 		else
	-- 			SpineCache(SpineCacheName.BATTLE):addCacheData(v.path, k, v.scale)
	-- 		end

	-- 		-- 记录一次数据
	-- 		self:AddAniCacheInfo(v)
	-- 	end
	-- end

	for i,v in ipairs(hurtSpine) do
		if self:IsSpineResourceValidByFullPath(v.path) then
			if nil == loadedSpine[tostring(v.cacheName)] then
				if 1 == wave then
					loader:addCustomTask(cc.CallFunc:create(function ()
						SpineCache(SpineCacheName.BATTLE):addCacheData(v.path, v.cacheName, v.scale)
					end), 0.1)
				else
					SpineCache(SpineCacheName.BATTLE):addCacheData(v.path, v.cacheName, v.scale)
				end
				loadedSpine[tostring(v.cacheName)] = true
			end
			-- 记录一次数据
			self:AddAniCacheInfo(v)
		end
	end

	-- for k,v in pairs(hurtSpine) do
	-- 	if utils.isExistent(_res(v.path .. '.json')) then
	-- 		if 1 == wave then
	-- 			loader:addCustomTask(cc.CallFunc:create(function ()

	-- 				SpineCache(SpineCacheName.BATTLE):addCacheData(v.path, k, v.scale)

	-- 			end), 0.1)
	-- 		else
	-- 			SpineCache(SpineCacheName.BATTLE):addCacheData(v.path, k, v.scale)
	-- 		end

	-- 		-- 记录一次数据
	-- 		self:AddAniCacheInfo(v)
	-- 	end
	-- end

	------------ 场景特效 ------------
	if needLoadCardCutin then
		local resInfo = {
			{cacheName = 'cutin_2', pathPrefix = 'battle/effect/cutin_foreground', scale = 1, loadTime = 0.2},
			{cacheName = 'head_active', pathPrefix = 'battle/effect/head_active', scale = 1, loadTime = 0.1},
			{cacheName = 'connect_head_1', pathPrefix = 'battle/effect/connect_head_bg', scale = 1, loadTime = 0.1},
			{cacheName = 'connect_head_2', pathPrefix = 'battle/effect/connect_head_fg', scale = 1, loadTime = 0.1}
		}

		if 1 == wave then
			for i,v in ipairs(resInfo) do
				loader:addCustomTask(cc.CallFunc:create(function ()
					SpineCache(SpineCacheName.BATTLE):addCacheData(v.pathPrefix, v.cacheName, v.scale)
				end), v.loadTime)
			end
		elseif 1 < wave then
			for i,v in ipairs(resInfo) do
				SpineCache(SpineCacheName.BATTLE):addCacheData(v.pathPrefix, v.cacheName, v.scale)
			end
		end
	end
	if needLoadBossWeak then
		local resInfo = {
			{cacheName = 'boss_weak', pathPrefix = 'battle/effect/boss_weak', scale = 1, loadTime = 0.1},
			{cacheName = 'boss_chant_progressBar', pathPrefix = 'battle/effect/boss_chant_progressBar', scale = 1, loadTime = 0.1}
		}

		if 1 == wave then
			for i,v in ipairs(resInfo) do
				loader:addCustomTask(cc.CallFunc:create(function ()
					SpineCache(SpineCacheName.BATTLE):addCacheData(v.pathPrefix, v.cacheName, v.scale)
				end), v.loadTime)
			end
		elseif 1 < wave then
			for i,v in ipairs(resInfo) do
				SpineCache(SpineCacheName.BATTLE):addCacheData(v.pathPrefix, v.cacheName, v.scale)
			end
		end
	end
	if needLoadBossCutin then
		local resInfo = {
			{cacheName = 'boss_cutin_1', jsonPath = 'battle/effect/boss_cutin_bg.json', atlasPath = 'battle/effect/boss_cutin.atlas', scale = 1, loadTime = 0.1},
			{cacheName = 'boss_cutin_2', jsonPath = 'battle/effect/boss_cutin_fg.json', atlasPath = 'battle/effect/boss_cutin.atlas', scale = 1, loadTime = 0.1},
			{cacheName = 'boss_cutin_mask', jsonPath = 'battle/effect/boss_cutin_mask.json', atlasPath = 'battle/effect/boss_cutin.atlas', scale = 1, loadTime = 0.1}
		}

		if 1 == wave then
			for i,v in ipairs(resInfo) do
				loader:addCustomTask(cc.CallFunc:create(function ()
					SpineCache(SpineCacheName.BATTLE):addCacheData(v.jsonPath, v.atlasPath, v.cacheName, v.scale)
				end), v.loadTime)
			end
		elseif 1 < wave then
			for i,v in ipairs(resInfo) do
				SpineCache(SpineCacheName.BATTLE):addCacheData(v.jsonPath, v.atlasPath, v.cacheName, v.scale)
			end
		end
	end
	------------ 场景特效 ------------

	-- dump(self.spineAnimationsCache)
end
---------------------------------------------------
-- control logic end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
添加一个加载的spine资源
@params spineAniCacheInfo SpineAnimationCacheInfoStruct
--]]
function TagMatchResLoadDriver:AddAniCacheInfo(spineAniCacheInfo)
	local name = spineAniCacheInfo.cacheName
	local skinId = spineAniCacheInfo.skinId

	local avatarAniCacheInfo = self:GetAniCacheInfo(name)
	if nil == avatarAniCacheInfo then
		avatarAniCacheInfo = {
			nextRemove = true,
			skins = {}
		}
		self.spineAnimationsCache[tostring(name)] = avatarAniCacheInfo
	end

	avatarAniCacheInfo.skins[tostring(skinId)] = ValueConstants.V_NORMAL
end
--[[
根据缓存名获取加载的资源数据
@params name string 缓存名
--]]
function TagMatchResLoadDriver:GetAniCacheInfo(name)
	return self.spineAnimationsCache[tostring(name)]
end
--[[
根据缓存名移除加载的avatar数据
@params name string 缓存名
--]]
function TagMatchResLoadDriver:RemoveAniCacheInfo(name)
	self.spineAnimationsCache[tostring(name)] = nil
end
--[[
根据皮肤id获取占用的资源信息
@params skinId int 皮肤id
@return result table avatar cache names
--]]
function TagMatchResLoadDriver:GetAniCacheInfoBySkinId(skinId)
	local result = {}
	for cacheName, cacheInfo in pairs(self.spineAnimationsCache) do
		for skinId_, v in pairs(cacheInfo.skins) do
			if checkint(skinId_) == checkint(skinId) and ValueConstants.V_NORMAL == v then
				result[tostring(cacheName)] = ValueConstants.V_NORMAL
			end
		end
	end
	return result
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return TagMatchResLoadDriver

--[[
车轮战资源加载驱动
--]]
local BattleResLoadDriver = __Require('battle.battleDriver.BattleResLoadDriver')
local TagMatchResLoadDriver = class('TagMatchResLoadDriver', BattleResLoadDriver)

------------ import ------------
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
	BattleResLoadDriver.Init(self)
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
@params isFriendWin ValueConstants 是否是友军胜利
@params aliveTargetsInfo list<{objectSkinId = nil}> 存活的obj信息
@params deadTargetsInfo list<{objectSkinId = nil}> 死亡的obj信息
--]]
function TagMatchResLoadDriver:OnLogicEnter(wave, friendTeamIndex, enemyTeamIndex, isFriendWin, aliveTargetsInfo, deadTargetsInfo)
	self:LoadResources(wave, friendTeamIndex, enemyTeamIndex, isFriendWin, aliveTargetsInfo, deadTargetsInfo)
	-- 记录一次加载的资源
	self:RecordLoadedResources(wave)
end
--[[
@override
加载资源
@params wave int 波数
@params friendTeamIndex int 友军队伍号
@params enemyTeamIndex int 敌军队伍号
@params isFriendWin ValueConstants 是否是友军胜利
@params aliveTargetsInfo list<{objectSkinId = nil}> 存活的obj信息
@params deadTargetsInfo list<{objectSkinId = nil}> 死亡的obj信息
--]]
function TagMatchResLoadDriver:LoadResources(wave, friendTeamIndex, enemyTeamIndex, isFriendWin, aliveTargetsInfo, deadTargetsInfo)
	if 1 == wave then
		-- 第一波时加载一些额外资源
		-- 加载ui资源
		self:LoadUIResources()
	end

	-- 加载spine资源
	self:LoadSpineResources(wave, friendTeamIndex, enemyTeamIndex, isFriendWin, aliveTargetsInfo, deadTargetsInfo)
end
--[[
@override
加载spine资源
@params wave int 波数
@params friendTeamIndex int 友军队伍号
@params enemyTeamIndex int 敌军队伍号
@params isFriendWin ValueConstants 是否是友军胜利
@params aliveTargetsInfo list<{objectSkinId = nil}> 存活的obj信息
@params deadTargetsInfo list<{objectSkinId = nil}> 死亡的obj信息
--]]
function TagMatchResLoadDriver:LoadSpineResources(wave, friendTeamIndex, enemyTeamIndex, isFriendWin, aliveTargetsInfo, deadTargetsInfo)
	local avatarSpine = {}
	local effectSpine = {}
	local hurtSpine = {}

	local needLoadBossWeak = false
	local needLoadBossCutin = false
	local needLoadCardCutin = false

	friendTeamIndex = nil == friendTeamIndex and 1 or friendTeamIndex
	enemyTeamIndex = nil == enemyTeamIndex and 1 or enemyTeamIndex

	isFriendWin = isFriendWin or ValueConstants.V_NONE

	------------ 己方卡牌 ------------
	local objectConfigId = nil
	local cardConfig = nil
	local skillConfig = nil

	local friendTeamMembers = G_BattleLogicMgr:GetBattleMembers(false, friendTeamIndex)

	if ValueConstants.V_NORMAL ~= isFriendWin and nil ~= friendTeamMembers then
		for _, cardData in ipairs(friendTeamMembers) do
			objectConfigId = cardData:GetObjectConfigId()
			local extraNeedLoad = self:ConvertNeedLoadResourcesByCardId(
				objectConfigId,
				checkint(cardData.skinId),
				nil,
				avatarSpine, effectSpine, hurtSpine
			)
			if true == extraNeedLoad.needLoadBossWeak then
				needLoadBossWeak = true
			end
			if true == extraNeedLoad.needLoadBossCutin then
				needLoadBossCutin = true
			end
			-- 检测连携技是否可用加载卡牌ci特效动画
			cardConfig = CardUtils.GetCardConfig(objectConfigId)
			for _, v in ipairs(cardConfig.skill) do
				skillConfig = CommonUtils.GetSkillConf(checkint(v)) or {}
				if nil ~= skillConfig then
					if ConfigSkillType.SKILL_CONNECT == checkint(skillConfig.property) then
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
	local enemyTeamMembers = G_BattleLogicMgr:GetBattleMembers(true, enemyTeamIndex)

	if ValueConstants.V_INFINITE ~= isFriendWin and nil ~= enemyTeamMembers then
		for _, cardData in ipairs(enemyTeamMembers) do
			objectConfigId = cardData:GetObjectConfigId()
			local extraNeedLoad = self:ConvertNeedLoadResourcesByCardId(
				objectConfigId,
				checkint(cardData.skinId),
				nil,
				avatarSpine, effectSpine, hurtSpine
			)
			if true == extraNeedLoad.needLoadBossWeak then
				needLoadBossWeak = true
			end
			if true == extraNeedLoad.needLoadBossCutin then
				needLoadBossCutin = true
			end
			-- 即便是pve模式，也有可能存在卡怪混排的队伍阵容，那么这组阵容中就存在触发连携技的可能。所以还是要做连携判断。
			if not CardUtils.IsMonsterCard(objectConfigId) then
				-- 检测连携技是否可用加载卡牌ci特效动画
				cardConfig = CardUtils.GetCardConfig(objectConfigId)
				for _, v in ipairs(cardConfig.skill) do
					skillConfig = CommonUtils.GetSkillConf(checkint(v)) or {}
					if nil ~= skillConfig then
						if ConfigSkillType.SKILL_CONNECT == checkint(skillConfig.property) then
							if CardUtils.IsConnectSkillEnable(objectConfigId, enemyTeamMembers, checkint(v)) then
								needLoadCardCutin = true
							end
						end
					end
				end
			end
		end
	end
	------------ 敌方卡牌 ------------

	if 1 == wave then
		------------ 天气 ------------
		local weatherId = nil
		local weatherConfig = nil
		local battleWeatherConfig = G_BattleLogicMgr:GetStageWeatherConfig()

		if nil ~= battleWeatherConfig then

			for i,v in ipairs(battleWeatherConfig) do

				weatherId = checkint(v)
				weatherConfig = CommonUtils.GetConfig('quest', 'weather', weatherId)

				self:ConvertNeedLoadResourcesBySkill(
					weatherConfig.skillId,
					ConfigSpecialCardId.WEATHER,
					ConfigSpecialCardId.WEATHER,
					CARD_DEFAULT_SCALE,
					avatarSpine, effectSpine, hurtSpine
				)

			end

		end
		------------ 天气 ------------

		------------ 主角技 ------------
		local playerSkills = {}
		for i,v in ipairs(G_BattleLogicMgr:GetPlayerSkilInfo(false).activeSkill) do
			table.insert(playerSkills, checkint(v.skillId))
		end
		self:ConvertNeedLoadResourcesBySkill(
			playerSkills,
			ConfigSpecialCardId.PLAYER,
			ConfigSpecialCardId.PLAYER,
			CARD_DEFAULT_SCALE,
			avatarSpine, effectSpine, hurtSpine
		)
		------------ 主角技 ------------

		-- 复活特效
		self:LoadRevivalSpineResources(self:GetOwner():CanBuyRevival())

		-- 过关目标特效
		self:LoadClearTargetSpineResources(self:GetOwner():GetBattleConstructData().stageCompleteInfo)

	elseif 1 < wave then
		------------ 过滤一次需要保留的资源和需要删除的资源 ------------
		local obj = nil
		local objSkinId = nil

		if nil ~= aliveTargetsInfo then

			-- 保留存活的资源
			for _, objInfo in ipairs(aliveTargetsInfo) do
				objSkinId = objInfo.objectSkinId
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
				-- obj:ClearBuff()
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

		end

		if nil ~= deadTargetsInfo then

			-- 删除死亡的资源
			for _, objInfo in ipairs(deadTargetsInfo) do
				objSkinId = objInfo.objectSkinId
				local caches = self:GetAniCacheInfoBySkinId(objSkinId)
				for cacheName, _ in pairs(caches) do
					local aniCacheInfo = self:GetAniCacheInfo(cacheName)
					if nil ~= aniCacheInfo and aniCacheInfo.nextRemove then
						aniCacheInfo.nextRemove = true
						aniCacheInfo.skins[tostring(objSkinId)] = nil
					end
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
		------------ 去掉已经加载的资源 ------------

		-- 卸载无用的资源
		for cacheName, cacheInfo in pairs(self.spineAnimationsCache) do
			
			if true == cacheInfo.nextRemove then

				-- /***********************************************************************************************************************************\
				--  * 此处移除一次物体身上的附加特效spine 防止由需要杀死的物体导致移除spine缓存时会造成空指针的问题
				-- \***********************************************************************************************************************************/
				G_BattleRenderMgr:ForceRemoveAttachEffectByEffectId(BattleUtils:GetAniIdByCacheName(cacheName))
				-- /***********************************************************************************************************************************\
				--  * 此处移除一次物体身上的附加特效spine 防止由需要杀死的物体导致移除spine缓存时会造成空指针的问题
				-- \***********************************************************************************************************************************/

				self:RemoveAniCacheInfo(cacheName)
				SpineCache(SpineCacheName.BATTLE):removeCacheData(cacheName)
				self:RemoveALoadedSpine(cacheName)
			end
		end

		-- 移除不需要的纹理
		display.removeUnusedSpriteFrames()
		------------ 过滤一次需要保留的资源和需要删除的资源 ------------
	end

	------------ 开始添加加载任务 ------------
	-- 主要spine资源
	self:LoadMainSpineResources(wave, avatarSpine, effectSpine, hurtSpine)
	
	-- 场景特效
	self:LocaCISceneSpineResources(needLoadCardCutin, needLoadBossWeak, needLoadBossCutin)
	------------ 开始添加加载任务 ------------

	-- dump(self.spineAnimationsCache)
end
--[[
加载三种大类的资源
@params wave int 波数
@params avatarSpine list spine小人的资源
@params effectSpine list spine小人使用的特效资源
@params hurtSpine list 被击和爆点的特效资源
--]]
function TagMatchResLoadDriver:LoadMainSpineResources(wave, avatarSpine, effectSpine, hurtSpine)
	local loader = CCResourceLoader:getInstance()
	local loadedSpine = {}

	-- /***********************************************************************************************************************************\
	--  * 加载的方法 第一波分帧加载 后续直接加载
	--  * 此处可能会导致闪退
	-- \***********************************************************************************************************************************/
	local loadFunc = nil
	if 1 == wave then
		loadFunc = function (path, cacheName, scale)
			loader:addCustomTask(cc.CallFunc:create(function ()
				SpineCache(SpineCacheName.BATTLE):addCacheData(path, cacheName, scale)
			end), 0.1)
			self:AddALoadedSpine(cacheName)
		end
	else
		loadFunc = function (path, cacheName, scale)
			SpineCache(SpineCacheName.BATTLE):addCacheData(path, cacheName, scale)
			self:AddALoadedSpine(cacheName)
		end
	end

	-- avatar
	for i,v in ipairs(avatarSpine) do

		if nil == loadedSpine[tostring(v.cacheName)] then
			if self:IsSpineResourceValidByFullPath(v.path) then
				loadFunc(v.path, v.cacheName, v.scale)
				loadedSpine[tostring(v.cacheName)] = true
			end
		end

		-- 记录一次数据
		self:AddAniCacheInfo(v)

	end

	-- effect
	for i,v in ipairs(effectSpine) do

		if nil == loadedSpine[tostring(v.cacheName)] then
			if self:IsSpineResourceValidByFullPath(v.path) then
				loadFunc(v.path, v.cacheName, v.scale)
				loadedSpine[tostring(v.cacheName)] = true
			end
		end

		-- 记录一次数据
		self:AddAniCacheInfo(v)

	end

	-- hurt
	for i,v in ipairs(hurtSpine) do

		if nil == loadedSpine[tostring(v.cacheName)] then
			if self:IsSpineResourceValidByFullPath(v.path) then
				loadFunc(v.path, v.cacheName, v.scale)
				loadedSpine[tostring(v.cacheName)] = true
			end
		end

		-- 记录一次数据
		self:AddAniCacheInfo(v)

	end
end
--[[
加载场景特效资源
@params needLoadCardCutin bool 是否需要加载ci场景特效
@params needLoadBossWeak bool 是否需要加载boss读条弱点特效
@params needLoadBossCutin bool 是否需要加载bossci场景特效
--]]
function TagMatchResLoadDriver:LocaCISceneSpineResources(needLoadCardCutin, needLoadBossWeak, needLoadBossCutin)
	local loader = CCResourceLoader:getInstance()

	-- /***********************************************************************************************************************************\
	--  * 加载的方法 第一波分帧加载 后续直接加载
	--  * 此处可能会导致闪退
	-- \***********************************************************************************************************************************/
	local loadFunc = nil
	local loadFunc2 = nil
	if 1 == wave then
		loadFunc = function (path, cacheName, scale, loadTime)
			loader:addCustomTask(cc.CallFunc:create(function ()
				SpineCache(SpineCacheName.BATTLE):addCacheData(path, cacheName, scale)
			end), loadTime)
			self:AddALoadedSpine(cacheName)
		end
		loadFunc2 = function (jsonPath, atlasPath, cacheName, scale, loadTime)
			loader:addCustomTask(cc.CallFunc:create(function ()
				SpineCache(SpineCacheName.BATTLE):addCacheData(jsonPath, atlasPath, cacheName, scale)
			end), loadTime)
			self:AddALoadedSpine(cacheName)
		end
	else
		loadFunc = function (path, cacheName, scale, loadTime)
			SpineCache(SpineCacheName.BATTLE):addCacheData(path, cacheName, scale)
			self:AddALoadedSpine(cacheName)
		end
		loadFunc2 = function (jsonPath, atlasPath, cacheName, scale, loadTime)
			SpineCache(SpineCacheName.BATTLE):addCacheData(jsonPath, atlasPath, cacheName, scale)
			self:AddALoadedSpine(cacheName)
		end
	end

	-- 卡牌cutin
	if needLoadCardCutin then
		local cardCutinSceneConfig = BRUtils.GetCardCutinSceneConfig()
		for i,v in ipairs(cardCutinSceneConfig) do
			loadFunc(v.path, v.cacheName, v.scale, v.loadTime)
		end
	end

	-- boss弱点场景
	if needLoadBossWeak then
		local bossWeakSceneConfig = BRUtils.GetBossWeakSceneConfig()
		for i,v in ipairs(bossWeakSceneConfig) do
			loadFunc(v.path, v.cacheName, v.scale, v.loadTime)
		end
	end

	-- boss cutin
	if needLoadBossCutin then
		local bossCutinSceneConfig = BRUtils.GetBossCutinSceneConfig()
		for i,v in ipairs(bossCutinSceneConfig) do
			loadFunc2(v.jsonPath, v.atlasPath, v.cacheName, v.scale, v.loadTime)
		end
	end
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

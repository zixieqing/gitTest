--[[
战斗资源加载驱动
--]]
local BaseBattleDriver = __Require('battle.battleDriver.BaseBattleDriver')
local BattleResLoadDriver = class('BattleResLoadDriver', BaseBattleDriver)

------------ import ------------
------------ import ------------

------------ define ------------
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
	self.loadedSpine = {}
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
	-- 记录一次加载的资源
	self:RecordLoadedResources(wave)
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
end
--[[
加载图片
--]]
function BattleResLoadDriver:LoadUIResources()
	local loader = CCResourceLoader:getInstance()

	------------ 加载地图资源 ------------
	local bgInfo = self:GetOwner():GetBattleBgInfo(G_BattleLogicMgr:GetBData():GetNextWave())

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
	local avatarSpine = {}
	local effectSpine = {}
	local hurtSpine = {}

	local needLoadBossWeak = false
	local needLoadBossCutin = false
	local needLoadCardCutin = false

	local questType = self:GetOwner():GetQuestBattleType()

	------------ 己方卡牌 ------------
	local objectConfigId = nil
	local cardConfig = nil
	local skillConfig = nil

	local friendTeamMembers = self:GetOwner():GetBattleMembers(false, 1)

	for _, cardData in ipairs(friendTeamMembers) do
		objectConfigId = cardData:GetObjectConfigId()
		local extraNeedLoad = self:ConvertNeedLoadResourcesByCardId(
			objectConfigId,
			checkint(cardData.skinId),
			cardData.exAbilityData,
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
	------------ 己方卡牌 ------------

	------------ 敌方卡牌 ------------
	if G_BattleMgr:IsCardVSCard() then
		-- pvc
		local allEnemyMembers = self:GetOwner():GetBattleMembers(true)

		for waveId, waveConf in ipairs(allEnemyMembers) do
			for _, cardData in ipairs(waveConf) do
				objectConfigId = cardData:GetObjectConfigId()
				local extraNeedLoad = self:ConvertNeedLoadResourcesByCardId(
					objectConfigId,
					checkint(cardData.skinId),
					cardData.exAbilityData,
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
							if CardUtils.IsConnectSkillEnable(objectConfigId, waveConf, checkint(v)) then
								needLoadCardCutin = true
							end
						end
					end
				end
			end
		end

	else

		-- pve
		local allEnemyMembers = self:GetOwner():GetBattleMembers(true)

		for waveId, waveConf in pairs(allEnemyMembers) do
			for _, npcConf in ipairs(waveConf) do
				objectConfigId = npcConf:GetObjectConfigId()
				local extraNeedLoad = self:ConvertNeedLoadResourcesByCardId(
					objectConfigId,
					checkint(npcConf.skinId),
					npcConf.exAbilityData,
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
								if CardUtils.IsConnectSkillEnable(objectConfigId, waveConf, checkint(v)) then
									needLoadCardCutin = true
								end
							end
						end
					end
				end
			end
		end

		-- 加载转阶段所需要的资源
		self:ConvertPhaseChangeResources(
			G_BattleLogicMgr:GetBData():GetPhaseChangeData(),
			avatarSpine, effectSpine, hurtSpine
		)
	end
	------------ 敌方卡牌 ------------

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

	------------ 开始添加加载任务 ------------
	-- 主要spine资源
	self:LoadMainSpineResources(avatarSpine, effectSpine, hurtSpine)

	-- 场景特效
	self:LocaCISceneSpineResources(needLoadCardCutin, needLoadBossWeak, needLoadBossCutin)

	-- 复活特效
	self:LoadRevivalSpineResources(self:GetOwner():CanBuyRevival())

	-- 过关目标特效
	self:LoadClearTargetSpineResources(self:GetOwner():GetBattleConstructData().stageCompleteInfo)
	------------ 开始添加加载任务 ------------
end
--[[
处理阶段转换需要加载资源的数据结构
@params phaseChangeDatas map<npcId, PhaseChangeSturct>
@params avatarSpine table 需要加载的卡牌spine集合
@params effectSpine table 需要加载的特效spine集合
@params hurtSpine table 需要加载的爆点附加效果spine集合
@return extraNeedLoad table {
	needLoadBossWeak bool 是否需要加载boss弱点动画
	needLoadBossCutin bool 是否需要加载boss cut in 
}
--]]
function BattleResLoadDriver:ConvertPhaseChangeResources(phaseChangeDatas, avatarSpine, effectSpine, hurtSpine)
	local loader = CCResourceLoader:getInstance()
	
	-- 转阶段动画资源加载逻辑
	if nil ~= phaseChangeDatas then
		for npcId, phases in pairs(phaseChangeDatas) do

			-- 首先加载一次触发怪物
			local extraNeedLoad = self:ConvertNeedLoadResourcesByCardId(
				checkint(npcId),
				CardUtils.GetCardSkinId(checkint(npcId)),
				nil,
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
							nil,
							avatarSpine, effectSpine, hurtSpine
						)
						if true == extraNeedLoad.needLoadBossWeak then
							needLoadBossWeak = true
						end
						if true == extraNeedLoad.needLoadBossCutin then
							needLoadBossCutin = true
						end

						loader:addCustomTask(cc.CallFunc:create(function ()
							SpineCache(SpineCacheName.BATTLE):addCacheData('battle/effect/phase_deform_effect', sp.AniCacheName.PHASE_DEFORM_EFFECT, 1)
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
							nil,
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
							nil,
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
--[[
加载三种大类的资源
@params avatarSpine list spine小人的资源
@params effectSpine list spine小人使用的特效资源
@params hurtSpine list 被击和爆点的特效资源
--]]
function BattleResLoadDriver:LoadMainSpineResources(avatarSpine, effectSpine, hurtSpine)
	local loader = CCResourceLoader:getInstance()

	-- avatar
	for i,v in ipairs(avatarSpine) do
		if not self:HasLoadSpineByCacheName(v.cacheName) then
			if self:IsSpineResourceValidByFullPath(v.path) then
				loader:addCustomTask(cc.CallFunc:create(function ()
					local realSpinePath = utils.deletePathExtension(_res(v.path .. '.atlas'))  -- 不能用 json，因为真实 json 文件是 xxxxx.json.zip
					SpineCache(SpineCacheName.BATTLE):addCacheData(realSpinePath, v.cacheName, v.scale)
				end), 0.1)

				self:AddALoadedSpine(v.cacheName)
			end
		end
	end

	-- effect
	for i,v in ipairs(effectSpine) do
		if not self:HasLoadSpineByCacheName(v.cacheName) then
			if self:IsSpineResourceValidByFullPath(v.path) then
				loader:addCustomTask(cc.CallFunc:create(function ()
					local realSpinePath = utils.deletePathExtension(_res(v.path .. '.atlas'))  -- 不能用 json，因为真实 json 文件是 xxxxx.json.zip
					SpineCache(SpineCacheName.BATTLE):addCacheData(realSpinePath, v.cacheName, v.scale)
				end), 0.1)

				self:AddALoadedSpine(v.cacheName)
			end
		end
	end

	-- hurt
	for i,v in ipairs(hurtSpine) do
		if not self:HasLoadSpineByCacheName(v.cacheName) then
			if self:IsSpineResourceValidByFullPath(v.path) then
				loader:addCustomTask(cc.CallFunc:create(function ()
					SpineCache(SpineCacheName.BATTLE):addCacheData(v.path, v.cacheName, v.scale)
				end), 0.1)

				self:AddALoadedSpine(v.cacheName)
			end
		end
	end
end
--[[
加载场景特效资源
@params needLoadCardCutin bool 是否需要加载ci场景特效
@params needLoadBossWeak bool 是否需要加载boss读条弱点特效
@params needLoadBossCutin bool 是否需要加载bossci场景特效
--]]
function BattleResLoadDriver:LocaCISceneSpineResources(needLoadCardCutin, needLoadBossWeak, needLoadBossCutin)
	local loader = CCResourceLoader:getInstance()

	-- 卡牌cutin
	if needLoadCardCutin then
		for i,v in ipairs(BRUtils.GetCardCutinSceneConfig()) do
			loader:addCustomTask(cc.CallFunc:create(function ()
				SpineCache(SpineCacheName.BATTLE):addCacheData(v.path, v.cacheName, v.scale)
			end), v.loadTime)

			self:AddALoadedSpine(v.cacheName)
		end
	end

	-- boss弱点场景
	if needLoadBossWeak then
		for i,v in ipairs(BRUtils.GetBossWeakSceneConfig()) do
			loader:addCustomTask(cc.CallFunc:create(function ()
				SpineCache(SpineCacheName.BATTLE):addCacheData(v.path, v.cacheName, v.scale)
			end), v.loadTime)

			self:AddALoadedSpine(v.cacheName)
		end
	end

	-- boss cutin
	if needLoadBossCutin then
		for i,v in ipairs(BRUtils.GetBossCutinSceneConfig()) do
			loader:addCustomTask(cc.CallFunc:create(function ()
				SpineCache(SpineCacheName.BATTLE):addCacheData(v.jsonPath, v.atlasPath, v.cacheName, v.scale)
			end), v.loadTime)

			self:AddALoadedSpine(v.cacheName)
		end
	end
end
--[[
加载复活特效
@params canBuyRevival bool 是否能进行买活
--]]
function BattleResLoadDriver:LoadRevivalSpineResources(canBuyRevival)
	local loader = CCResourceLoader:getInstance()

	if canBuyRevival then
		for i,v in ipairs(BRUtils.GetBuyRevivalSceneConfig()) do
			if self:IsSpineResourceValidByFullPath(v.path) then
				loader:addCustomTask(cc.CallFunc:create(function ()
					SpineCache(SpineCacheName.BATTLE):addCacheData(v.path, v.cacheName, v.scale)
				end), v.loadTime)

				self:AddALoadedSpine(v.cacheName)
			end
		end
	end 
end
--[[
加载过关目标特效
@params stageCompleteInfo list<StageCompleteSturct>
--]]
function BattleResLoadDriver:LoadClearTargetSpineResources(stageCompleteInfo)
	if nil ~= stageCompleteInfo then
		local loader = CCResourceLoader:getInstance()

		local spineConfig = {}
		local info = nil

		for wave, v in ipairs(stageCompleteInfo) do
			info = BRUtils.GetClearTargetSpineConfig()[v.completeType]
			if  nil ~= info then
				spineConfig[info.cacheName] = info
			end
		end

		for _, loadInfo in pairs(spineConfig) do
			if utils.isExistent(_res(loadInfo.path .. '.json')) then
				loader:addCustomTask(cc.CallFunc:create(function ()
					SpineCache(SpineCacheName.BATTLE):addCacheData(loadInfo.path, loadInfo.cacheName, loadInfo.scale)
				end), loadInfo.loadTime)
			end
		end
	end
end
--[[
加载战斗特效
--]]
function BattleResLoadDriver:LoadSoundResources()
	app.audioMgr:AddCueSheet(AUDIOS.BATTLE.name, AUDIOS.BATTLE.acb, "")
	app.audioMgr:AddCueSheet(AUDIOS.BATTLE2.name, AUDIOS.BATTLE2.acb, "")
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
@params exAbilityData EXAbilityConstructorStruct 超能力信息
@params avatarSpine table 需要加载的卡牌spine集合
@params effectSpine table 需要加载的特效spine集合
@params hurtSpine table 需要加载的爆点附加效果spine集合
@return extraNeedLoad table {
	needLoadBossWeak bool 是否需要加载boss弱点动画
	needLoadBossCutin bool 是否需要加载boss cut in 
}
--]]
function BattleResLoadDriver:ConvertNeedLoadResourcesByCardId(cardId, skinId, exAbilityData, avatarSpine, effectSpine, hurtSpine)
	return BRUtils.ConvertNeedLoadResourcesByCardId(cardId, skinId, exAbilityData, avatarSpine, effectSpine, hurtSpine)
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
	BRUtils.ConvertNeedLoadResourcesBySkill(skill, effectConfId, skinId, scale, avatarSpine, effectSpine, hurtSpine)
end
--[[
判断整套资源是否合法
@params spineId string spine的id
@params spineResType SpineResType spine资源类型
@return _ bool 整套资源是否合法
--]]
function BattleResLoadDriver:IsSpineResourceValid(spineId, spineResType)
	return BRUtils.IsSpineResourceValid(spineId, spineResType)
end
--[[
根据全路径判断整套资源是否合法
@params spinePath string spine资源的全路径
@return _ bool 整套资源是否合法
--]]
function BattleResLoadDriver:IsSpineResourceValidByFullPath(spinePath)
	local isValidity, verifyMap = BRUtils.IsSpineResourceValidByFullPath(spinePath)
	if not isValidity and verifyMap and verifyMap['atlas'] and verifyMap['atlas'].remoteDefine then
		-- 资源不合法 请求一次download
		BRUtils.DownloadSpineResourceByFullPath(spinePath)
	end
	return isValidity
end
--[[
添加一个加载的spine动画信息
@params spineCacheName string 加载的spine缓存名
--]]
function BattleResLoadDriver:AddALoadedSpine(spineCacheName)
	self.loadedSpine[tostring(spineCacheName)] = true
end
--[[
移除一个已经加载的spine动画信息
@params spineCacheName string 加载的spine缓存名
--]]
function BattleResLoadDriver:RemoveALoadedSpine(spineCacheName)
	self.loadedSpine[tostring(spineCacheName)] = nil
end
--[[
根据cacheName判断动画是否已经加载过
@params spineCacheName string 加载的spine缓存名
@return _ bool 
--]]
function BattleResLoadDriver:HasLoadSpineByCacheName(spineCacheName)
	return self.loadedSpine[tostring(spineCacheName)] and self.loadedSpine[tostring(spineCacheName)] or false
end
--[[
记录加载的资源
@params wave int 波数
--]]
function BattleResLoadDriver:RecordLoadedResources(wave)
	G_BattleLogicMgr:RecordLoadedResources(wave, self.loadedSpine)
end
---------------------------------------------------
-- get set begin --
---------------------------------------------------

return BattleResLoadDriver

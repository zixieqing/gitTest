--[[
战斗数据
@params ... table {
	battleConstructor BattleConstructor 战斗构造器
}
--]]
local BattleData = class('BattleData')
function BattleData:ctor( ... )
	local args = unpack({...})

	self.battleConstructor = args.battleConstructor

	self:init()
end

local objNamePrefix = {friend = 'friend_', enemy = 'enemy_', bullet = 'bullet_', beckon = 'beckon_'}

local BattleTags = {
	BT_FRIEND 				= 1,
	BT_CONFIG_ENEMY 		= 2,
	BT_OTHER_ENEMY 			= 3,
	BT_BECKON 				= 4,
	BT_BULLET 				= 5,
	BT_WEATHER 				= 6,
	BT_FRIEND_PLAYER		= 7,
	BT_ENEMY_PLAYER 		= 8,
	BT_ATTACK_MODIFIER 		= 9,
	BT_OBSERVER 			= 10,
	BT_TRIGGER 				= 11,
	BT_CI_SCENE 			= 99
}
---------------------------------------------------
-- data init begin --
---------------------------------------------------
--[[
初始化战斗数据
--]]
function BattleData:init()

	------------ conf data ------------
	self.phaseChangeData = nil
	if nil ~= self:getBattleConstructData().phaseChangeDatas then
		-- 初始化转阶段信息
		self:initPhaseChangeData(self:getBattleConstructData().phaseChangeDatas)
	end
	------------ conf data ------------

	------------ game state data ------------
	self.timeScale = 1
	self.isPause = false
	self.isPauseTimer = false
	self.gameState = GState.READY
	self.nextWave = 1
	self.nextWaveTips = {hasElite = false, hasBoss = false}
	self.currentWave = 0
	self:setGameTime(self:getBattleConstructData().time)
	self.leftTime = self:getGameTime()
	------------ game state data ------------

	------------ cache data ------------
	-- 存活的obj总表
	self.sortBattleObjs = {friend = {}, enemy = {}, bullet = {}, beckonObj = {}}
	self.battleObjs = {}

	-- obj死亡表 用作缓存死亡对象 战斗对象动作做完以后再去切波数 bullet不计算在内 切波数的时候直接移除
	self.sortDustObjs = {friend = {}, enemy = {}, beckonObj = {}}
	self.dustObjs = {}

	-- 休息区obj表
	self.sortRestObjs = {}
	self.restObjs = {}

	-- 天气单位
	self.sortWeather = {}
	self.weather = {}

	-- 主角单位
	self.sortPlayerObj = {friend = {}, enemy = {}}
	self.playerObj = {}

	-- ob物体
	self.sortObserverObj = {}
	self.observerObj = {}
	
	self.directorObj = nil
	self.globalEffectObj = nil

	-- 缓存ci场景 暂停的时候会判断ci场景是否暂停了obj 如果有恢复的时候不会恢复obj
	self.ciScenes = {pause = {}, normal = {}}
	-- 缓存暂停的action
	self.pauseActions = {battle = {}, ciScene = {}, normalCIScene = {}}

	-- 展示层模型
	self.sortObjViewModels = {}
	self.objViewModels = {}
	
	-- tag记录表
	self.nextTag = {
		[BattleTags.BT_FRIEND] 			= FRIEND_TAG + 1,
		[BattleTags.BT_CONFIG_ENEMY]	= ENEMY_TAG + 1,
		[BattleTags.BT_OTHER_ENEMY] 	= OTHER_ENEMY_TAG + 1,
		[BattleTags.BT_BECKON] 			= BECKON_TAG + 1,
		[BattleTags.BT_BULLET] 			= BULLET_TAG + 1,
		[BattleTags.BT_WEATHER] 		= WEATHER_TAG + 1,
		[BattleTags.BT_FRIEND_PLAYER] 	= FRIEND_PLAYER_TAG + 1,
		[BattleTags.BT_ENEMY_PLAYER] 	= ENEMY_PLAYER_TAG + 1,
		[BattleTags.BT_ATTACK_MODIFIER] = ATTACK_MODIFIER_TAG + 1,
		[BattleTags.BT_OBSERVER] 		= OBSERVER_TAG + 1,
		[BattleTags.BT_TRIGGER] 		= TRIGGER_TAG + 1,
		[BattleTags.BT_CI_SCENE] 		= 1
	}
	-- 下一次转阶段的信息
	self.nextPhaseChange = {
		pauseLogic = {},
		nonpauseLogic = {}
		-- [ConfigPhaseType.TALK_DEFORM] = {},
		-- [ConfigPhaseType.TALK_ESCAPE] = {},
		-- [ConfigPhaseType.TALK_ONLY] = {},
		-- [ConfigPhaseType.BECKON_ADDITION_FORCE] = {},
		-- [ConfigPhaseType.TALK_ESCAPE] = {}
	}
	------------ cache data ------------

	------------ record data ------------
	self.tagStr = ''
	self.fightStr = ''
	self.startAliveFriendObjPStr = ''
	self.tempAliveFriendObjPStr = ''
	self.overAliveFriendObjPStr = ''
	self.deadCardsId = {}
	------------ record data ------------

	------------ logic frame data ------------
	self.logicFrameFsmData = {}
	------------ logic frame data ------------
	
end
---------------------------------------------------
-- data init end --
---------------------------------------------------

---------------------------------------------------
-- battle obj data control begin --
---------------------------------------------------
--[[
获取对象名称信息
@params isEnemy bool 是否是敌人
@params isBeckon bool 是否是召唤出来的怪物 区别于qte怪物
@params index int 怪物序号
@return _ ObjectTagStruct tag数据结构
--]]
function BattleData:getObjTagInfo(isEnemy, isBeckon)
	local oname = objNamePrefix.friend
	local tag = 0
	if isEnemy then
		oname = objNamePrefix.enemy
		if not isBeckon then
			tag = self:getNextBattleTag(BattleTags.BT_CONFIG_ENEMY)
		else
			tag = self:getNextBattleTag(BattleTags.BT_OTHER_ENEMY)
		end
	else
		tag = self:getNextBattleTag(BattleTags.BT_FRIEND)
	end
	oname = oname .. tostring(tag)
	return ObjectTagStruct.New(tag, oname)
end
--[[
向内存中添加一个obj
@params o obj
--]]
function BattleData:addABattleObj(o)
	local otag = o:getOTag()
	if o:isEnemy() then
		table.insert(self.sortBattleObjs.enemy, 1, o)
	else
		table.insert(self.sortBattleObjs.friend, 1, o)
	end
	self.battleObjs[tostring(otag)] = o

	-- 加入战斗记录
	self:addATagStr(o:getOTag(), o:getOCardId())
end
--[[
从内存中移除一个obj
@params o obj
--]]
function BattleData:removeABattleObj(o)
	local otag = o:getOTag()
	if o:isEnemy() then
		for i = #self.sortBattleObjs.enemy, 1, -1 do
			if otag == self.sortBattleObjs.enemy[i]:getOTag() then
				table.remove(self.sortBattleObjs.enemy, i)
				break
			end
		end
	else
		for i = #self.sortBattleObjs.friend, 1, -1 do
			if otag == self.sortBattleObjs.friend[i]:getOTag() then
				table.remove(self.sortBattleObjs.friend, i)
				break
			end
		end
	end
	self.battleObjs[tostring(otag)] = nil
end
--[[
把一个obj加入墓地
@params o obj
@params nature bool 是否是自然死亡
--]]
function BattleData:addADeadObj(o, nature)
	local otag = o:getOTag()
	if o:isEnemy() then
		table.insert(self.sortDustObjs.enemy, 1, o)
	else
		-- 插入死亡卡牌数据
		if not nature then
			table.insert(self.deadCardsId, o:getOCardId())
		end
		table.insert(self.sortDustObjs.friend, 1, o)
	end
	self.dustObjs[tostring(otag)] = o
end
--[[
把一个obj移出墓地
--]]
function BattleData:removeADeadObj(o)
	local otag = o:getOTag()
	if o:isEnemy() then
		for i = #self.sortDustObjs.enemy, 1, -1 do
			if otag == self.sortDustObjs.enemy[i]:getOTag() then
				table.remove(self.sortDustObjs.enemy, i)
				break
			end
		end
	else
		for i = #self.sortDustObjs.friend, 1, -1 do
			if otag == self.sortDustObjs.friend[i]:getOTag() then
				table.remove(self.sortDustObjs.friend, i)
				break
			end
		end
	end
	self.dustObjs[tostring(otag)] = nil
end
--[[
把一个obj加入休息区
--]]
function BattleData:addAObjToRest(o)
	local otag = o:getOTag()
	table.insert(self.sortRestObjs, 1, o)
	self.restObjs[tostring(otag)] = o
end
--[[
把一个obj移出休息区
--]]
function BattleData:removeAObjFromRest(o)
	local otag = o:getOTag()
	for i = #self.sortRestObjs, 1, -1 do
		if otag == self.sortRestObjs[i]:getOTag() then
			table.remove(self.sortRestObjs, i)
			break
		end
	end
	self.restObjs[tostring(otag)] = nil
end
---------------------------------------------------
-- battle obj data control end --
---------------------------------------------------

---------------------------------------------------
-- battle obj view data control begin --
---------------------------------------------------
--[[
向主循环中添加一个展示层模型
@params viewModel BaseViewModel
@params tag int
--]]
function BattleData:addAObjViewModel(viewModel, tag)
	if nil == self.objViewModels[tostring(tag)] then
		self.objViewModels[tostring(tag)] = viewModel
		table.insert(self.sortObjViewModels, 1, viewModel)
	end
end
--[[
从主循环中移除一个展示层模型
@params viewModel BaseViewModel
@params tag int 
--]]
function BattleData:removeAObjViewModel(viewModel, tag)
	if nil ~= self.objViewModels[tostring(tag)] then
		local viewModel = nil
		for i = #self.sortObjViewModels, 1, -1 do
			viewModel = self.sortObjViewModels[i]
			if tag == viewModel:GetLogicOwnerTag() then
				self.objViewModels[tostring(tag)] = nil
				table.remove(self.sortObjViewModels, i)
				break
			end
		end
	end
end
---------------------------------------------------
-- battle obj view data control end --
---------------------------------------------------

---------------------------------------------------
-- beckon obj data control begin --
---------------------------------------------------
--[[
获取召唤物名称信息
@return _ ObjectTagStruct tag数据结构
--]]
function BattleData:getBeckonObjTagInfo()
	local tag = self:getNextBattleTag(BattleTags.BT_BECKON)
	local oname = objNamePrefix.beckon .. tostring(tag)
	return ObjectTagStruct.New(tag, oname)
end
--[[
向内存中添加一个召唤物
@params o obj
--]]
function BattleData:addABeckonObj(o)
	local otag = o:getOTag()
	table.insert(self.sortBattleObjs.beckonObj, 1, o)
	self.battleObjs[tostring(otag)] = o
	-- 加入战斗记录
	self:addATagStr(o:getOTag(), o:getOCardId())
end
--[[
从内存中移除一个召唤物
@params o obj
--]]
function BattleData:removeABeckonObj(o)
	local otag = o:getOTag()
	for i = #self.sortBattleObjs.beckonObj, 1, -1 do
		if otag == self.sortBattleObjs.beckonObj[i]:getOTag() then
			table.remove(self.sortBattleObjs.beckonObj, i)
			break
		end
	end
	self.battleObjs[tostring(o:getOTag())] = nil
end
--[[
把一个obj加入墓地
@params o obj
--]]
function BattleData:addADeadBeckonObj(o)
	local otag = o:getOTag()
	table.insert(self.sortDustObjs.beckonObj, 1, o)
	self.dustObjs[tostring(otag)] = o
end
--[[
把一个obj移出墓地
--]]
function BattleData:removeADeadBeckonObj(o)
	local otag = o:getOTag()
	for i = #self.sortDustObjs.beckonObj, 1, -1 do
		if otag == self.sortDustObjs.beckonObj[i]:getOTag() then
			table.remove(self.sortDustObjs.beckonObj, i)
		end
	end
	self.dustObjs[tostring(otag)] = nil
end
---------------------------------------------------
-- beckon obj data control end --
---------------------------------------------------

---------------------------------------------------
-- bullet data control begin --
---------------------------------------------------
--[[
获取子弹名称信息
return t table {
	tag int obj tag
	oname str obj name
}
--]]
function BattleData:getBulletTagInfo()
	local tag = self:getNextBattleTag(BattleTags.BT_BULLET)
	local oname = objNamePrefix.bullet .. tostring(tag)
	return {tag = tag, oname = oname}
end
--[[
向内存中添加一个bullet
@params o obj
--]]
function BattleData:addABullet(o)
	local otag = o:getOTag()
	table.insert(self.sortBattleObjs.bullet, 1, o)
	self.battleObjs[tostring(otag)] = o
end
--[[
从内存中移除一个obj
@params o obj
--]]
function BattleData:removeABullet(o)
	local otag = o:getOTag()
	for i = #self.sortBattleObjs.bullet, 1, -1 do
		if otag == self.sortBattleObjs.bullet[i]:getOTag() then
			table.remove(self.sortBattleObjs.bullet, i)
		end
	end
	self.battleObjs[tostring(otag)] = nil
end
---------------------------------------------------
-- bullet data control end --
---------------------------------------------------

---------------------------------------------------
-- ciScene data control begin --
---------------------------------------------------
--[[
获取ciScene的tag
@return tag int tag
--]]
function BattleData:getCISceneTag()
	local tag = self:getNextBattleTag(BattleTags.BT_CI_SCENE)
	return tag
	-- local result = math.max(checkint(BattleUtils.GetMaxKey(self.ciScenes.pause)) + 1, checkint(BattleUtils.GetMaxKey(self.ciScenes.normal)) + 1)
	-- return result
end
---------------------------------------------------
-- ciScene data control end --
---------------------------------------------------

---------------------------------------------------
-- weather data control begin --
---------------------------------------------------
--[[
获取天气tag
@return tag int 天气tag
--]]
function BattleData:getWeatherTag()
	local oname = objNamePrefix.friend
	local tag = self:getNextBattleTag(BattleTags.BT_WEATHER)
	oname = oname .. tostring(tag)
	return ObjectTagStruct.New(tag, oname)
end
--[[
向内存中添加一个天气
@params w BaseWeather 天气模型
--]]
function BattleData:addAWeather(w)
	local wtag = w:getOTag()
	table.insert(self.sortWeather, 1, w)
	self.weather[tostring(wtag)] = w

	-- 加入战斗记录
	self:addATagStr(w:getOTag(), w:getOWeatherId())
end
--[[
从内存中移除一个天气
@params tag int 
--]]
function BattleData:removeAWeather(tag)
	for i = #self.sortWeather, 1, -1 do
		if tag == self.sortWeather[i]:getOTag() then
			table.remove(self.sortWeather, i)
			break
		end
	end
	self.weather[tostring(tag)] = nil
end
---------------------------------------------------
-- weather data control end --
---------------------------------------------------

---------------------------------------------------
-- player data control end --
---------------------------------------------------
--[[
获取主角tag
@params isEnemy bool 是否是敌人
@return _ ObjectTagStruct tag数据结构
--]]
function BattleData:getPlayerTag(isEnemy)
	local oname = objNamePrefix.friend
	local tag = 0
	if isEnemy then
		oname = objNamePrefix.enemy
		tag = self:getNextBattleTag(BattleTags.BT_ENEMY_PLAYER)
	else
		tag = self:getNextBattleTag(BattleTags.BT_FRIEND_PLAYER)
	end
	oname = oname .. tostring(tag)
	return ObjectTagStruct.New(tag, oname)
end
--[[
向内存中添加一个主角
@params o object 主角模型
--]]
function BattleData:addAPlayerObj(o)
	local otag = o:getOTag()
	if o:isEnemy() then
		table.insert(self.sortPlayerObj.enemy, 1, o)
	else
		table.insert(self.sortPlayerObj.friend, 1, o)	
	end
	self.playerObj[tostring(otag)] = o
end
--[[
从内存中移除一个主角
@params o obj
--]]
function BattleData:removeAPlayerObj(o)
	local otag = o:getOTag()
	if o:isEnemy() then
		for i = #self.sortPlayerObj.enemy, 1, -1 do
			if otag == self.sortPlayerObj.enemy[i]:getOTag() then
				table.remove(self.sortPlayerObj.enemy, i)
				break
			end
		end
	else
		for i = #self.sortPlayerObj.friend, 1, -1 do
			if otag == self.sortPlayerObj.friend[i]:getOTag() then
				table.remove(self.sortPlayerObj.friend, i)
				break
			end
		end
	end
	self.playerObj[tostring(otag)] = nil
end
---------------------------------------------------
-- player data control end --
---------------------------------------------------

---------------------------------------------------
-- ob data control begin --
---------------------------------------------------
--[[
获取ob tag
@return _ ObjectTagStruct tag数据结构
--]]
function BattleData:getObserverTag()
	local oname = objNamePrefix.friend
	local tag = self:getNextBattleTag(BattleTags.BT_OBSERVER)
	oname = oname .. tostring(tag)
	return ObjectTagStruct.New(tag, oname)
end
--[[
向内存中添加一个ob
@params ob BaseOBOject
--]]
function BattleData:addAObserver(ob)
	local obtag = ob:getOTag()
	table.insert(self.sortObserverObj, 1, ob)
	self.observerObj[tostring(obtag)] = ob
end
--[[
从内存中移除一个ob
@params tag int
--]]
function BattleData:removeAObserver(tag)
	for i = #self.sortObserverObj, 1, -1 do
		if tag == self.sortObserverObj[i]:getOTag() then
			table.remove(self.sortObserverObj, i)
			break
		end
	end
	self.observerObj[tostring(tag)] = nil
end
---------------------------------------------------
-- ob data control end --
---------------------------------------------------

---------------------------------------------------
-- geo data control begin --
---------------------------------------------------
--[[
设置全局效果物体
@params geo BaseObject
--]]
function BattleData:SetGlobalEffectObj(geo)
	self.globalEffectObj = geo
end
--[[
获取全局效果物体
@return _ BaseObject
--]]
function BattleData:GetGlobalEffectObj()
	return self.globalEffectObj
end
---------------------------------------------------
-- geo data control end --
---------------------------------------------------

---------------------------------------------------
-- geo data control begin --
---------------------------------------------------
--[[
设置导演物体
@params obj BaseObject
--]]
function BattleData:SetDirectorObj(obj)
	self.directorObj = obj
end
--[[
获取导演物体
@return _ BaseObject
--]]
function BattleData:GetDirectorObj()
	return self.directorObj
end
---------------------------------------------------
-- geo data control end --
---------------------------------------------------

---------------------------------------------------
-- phase change data begin --
---------------------------------------------------
--[[
向内存中添加一个阶段转换
@params pauseLogic bool 是否阻塞主逻辑
@params phaseData ObjectPhaseSturct 触发转阶段的信息
--]]
function BattleData:addAPhaseChange(pauseLogic, phaseData)
	if true == pauseLogic then
		table.insert(self.nextPhaseChange.pauseLogic, 1, phaseData)
	else
		table.insert(self.nextPhaseChange.nonpauseLogic, 1, phaseData)
	end
end
--[[
从内存中移除一个阶段转换
@params pauseLogic bool 是否阻塞主逻辑
@params index int 序号
--]]
function BattleData:removeAPhaseChange(pauseLogic, index)
	if true == pauseLogic then
		table.remove(self.nextPhaseChange.pauseLogic, index)
	else
		table.remove(self.nextPhaseChange.nonpauseLogic, index)
	end
end
---------------------------------------------------
-- phase change data end --
---------------------------------------------------

---------------------------------------------------
-- attack modifier begin --
---------------------------------------------------
--[[
获取攻击特效驱动器tag
@return _ int tag数据结构
--]]
function BattleData:getAttackModifierTag()
	return self:getNextBattleTag(BattleTags.BT_ATTACK_MODIFIER)
end
---------------------------------------------------
-- attack modifier end --
---------------------------------------------------

---------------------------------------------------
-- trigger begin --
---------------------------------------------------
--[[
获取触发器tag
@return _ int tag数据结构
--]]
function BattleData:getTriggerTag()
	return self:getNextBattleTag(BattleTags.BT_TRIGGER)
end
---------------------------------------------------
-- trigger end --
---------------------------------------------------

---------------------------------------------------
-- data get set end --
---------------------------------------------------
--[[
获取战斗背景图id
@params wave int 波数
--]]
function BattleData:getBattleBgInfo(wave)
	return self:getBattleConstructData().backgroundInfo[1]
end
--[[
获取当前关卡id
--]]
function BattleData:getCurStageId()
	return self:getBattleConstructData().stageId
end
--[[
获取关卡天气配置
--]]
function BattleData:getStageWeatherConf()
	return self:getBattleConstructData().weather
end
--[[
获取转阶段转换配表后的数据结构
--]]
function BattleData:getPhaseChangeData()
	return self.phaseChangeData
end
--[[
获取关卡总波数
--]]
function BattleData:getStageTotalWave()
	return self:getBattleConstructData().totalWave
end
function BattleData:setStageTotalWave(wave)
	self:getBattleConstructData().totalWave = wave
end
--[[
获取tag
@params tagType BattleTags tag类型
--]]
function BattleData:getNextBattleTag(tagType)
	local tag = self.nextTag[tagType]
	self.nextTag[tagType] = self.nextTag[tagType] + 1
	return tag
end
--[[
初始化阶段转换信息
@params phaseActions table 转阶段配置信息
--]]
function BattleData:initPhaseChangeData(phaseActions)
	-- 记录转阶段数据 触发时间点 此表记录的是每种怪物id会主动触发那些转阶段
	if nil == phaseActions then return end
	self.phaseChangeData = {}
	local phaseChangeConf = nil
	for i,v in ipairs(phaseActions) do
		phaseChangeConf = CommonUtils.GetConfig('quest', 'bossAction', checkint(v))
		if nil ~= phaseChangeConf then
			local phaseChangeData = PhaseChangeSturct.New(phaseChangeConf)
			if nil == self.phaseChangeData[tostring(phaseChangeData.phaseTriggerNpcId)] then
				self.phaseChangeData[tostring(phaseChangeData.phaseTriggerNpcId)] = {}
			end
			table.insert(self.phaseChangeData[tostring(phaseChangeData.phaseTriggerNpcId)], phaseChangeData)
		end
	end
end
--[[
获取战斗构造器
--]]
function BattleData:getBattleConstructor()
	return self.battleConstructor
end
--[[
获取战斗构造数据
@return _ BattleConstructorStruct 战斗构造数据
--]]
function BattleData:getBattleConstructData()
	return self:getBattleConstructor():GetBattleConstructData()
end
--[[
获取阵容信息
@params isEnemy bool 是否是敌人
@return _ FormationStruct
--]]
function BattleData:getTeamData(isEnemy)
	if isEnemy then
		return self:getBattleConstructData().enemyFormation
	else
		return self:getBattleConstructData().friendFormation
	end
end
--[[
获取友方队伍成员
@params wave int 波数
@return _ table
--]]
function BattleData:getFriendMembers(wave)
	if wave then
		return self:getTeamData(false).members[wave]
	else
		return self:getTeamData(false).members
	end
end
--[[
获取敌方队伍成员
@params wave int 波数
@return _ table
--]]
function BattleData:getEnemyMembers(wave)
	if wave then
		return self:getTeamData(true).members[wave]
	else
		return self:getTeamData(true).members
	end
end
--[[
获取主角技
--]]
function BattleData:getPlayerSkilInfo(isEnemy)
	return self:getTeamData(isEnemy).playerSkillInfo
end
--[[
获取战斗类型
@return _ QuestBattleType 关卡战斗类型
--]]
function BattleData:getQuestBattleType()
	return self:getBattleConstructData().questBattleType
end
--[[
是否能够买活
@return _ bool 是否能够买活
--]]
function BattleData:canBuyRevival()
	return self:getBattleConstructData().canBuyCheat and self:getLeftBuyRevivalTime() > 0
end
--[[
获取剩余的买活次数
@return _ int 剩余买活次数
--]]
function BattleData:getLeftBuyRevivalTime()
	return math.max(0, self:getBattleConstructData().buyRevivalTimeMax - self:getBattleConstructData().buyRevivalTime)
end
--[[
增加买活次数
@params delta int 买活次数
--]]
function BattleData:addBuyRevivalTime(delta)
	self:getBattleConstructData().buyRevivalTime = self:getBattleConstructData().buyRevivalTime + delta
end
--[[
获取当前买活次数
--]]
function BattleData:getBuyRevivalTime()
	return self:getBattleConstructData().buyRevivalTime
end
--[[
获取下一次买活次数
--]]
function BattleData:getNextBuyRevivalTime()
	return math.min(self:getBattleConstructData().buyRevivalTimeMax, self:getBuyRevivalTime() + 1)
end
--[[
是否可以免费买活
--]]
function BattleData:canBuyRevivalFree()
	local result = false
	local geObj = self:GetGlobalEffectObj()
	if nil ~= geObj then
		local liveCheatFreeBuff = geObj:findBuff(nil, ConfigBuffType.LIVE_CHEAT_FREE)
		if nil ~= liveCheatFreeBuff then
			if 0 < liveCheatFreeBuff:GetFreeCheatLiveTimes() then
				result = true
			end
		end
	end
	return result
end
--[[
消耗免费买活次数
--]]
function BattleData:costBuyRevivalFree()
	local geObj = self:GetGlobalEffectObj()
	if nil ~= geObj then
		local liveCheatFreeBuff = geObj:findBuff(nil, ConfigBuffType.LIVE_CHEAT_FREE)
		if nil ~= liveCheatFreeBuff then
			if 0 < liveCheatFreeBuff:GetFreeCheatLiveTimes() then
				liveCheatFreeBuff:OnCauseEffectEnter()
			end
		end
	end
end
--[[
获取本场战斗总时间
@return _ int 总时间
--]]
function BattleData:getGameTime()
	return self.gameTime
end
--[[
设置本场战斗总时间
--]]
function BattleData:setGameTime(time)
	self.gameTime = time
end
--[[
获取当前游戏用掉的时间
--]]
function BattleData:getPassedTime()
	return math.ceil((self:getGameTime() - self.leftTime) * 1000) * 0.001
end
--[[
当前波数
--]]
function BattleData:getCurrentWave()
	return self.currentWave
end
function BattleData:setCurrentWave(wave)
	self.currentWave = wave
end
--[[
下一波
--]]
function BattleData:getNextWave()
	return self.nextWave
end
function BattleData:setNextWave(wave)
	self.nextWave = wave
end
--[[
根据敌友性获取当前场上人数
@params isEnemy bool 敌友性
@return _ int 人数
--]]
function BattleData:getAliveObjectAmount(isEnemy)
	if isEnemy then
		return #self.sortBattleObjs.enemy
	else
		return #self.sortBattleObjs.friend
	end
end
---------------------------------------------------
-- data get set end --
---------------------------------------------------

---------------------------------------------------
-- object status data begin --
---------------------------------------------------
--[[
获取存活的战斗卡牌的剩余状态
@return result map {
	[cardId] = {hp = hpPercent, energy = energyPercent},
	[cardId] = {hp = hpPercent, energy = energyPercent},
	...
}
--]]
function BattleData:GetAliveFriendObjStatus()
	local result = {}

	local obj = nil

	for i = #self.sortBattleObjs.friend, 1, -1 do

		obj = self.sortBattleObjs.friend[i]
		result[tostring(obj:getOCardId())] = {
			hp = math.ceil(obj:getMainProperty():getCurHpPercent() * 10000) * 0.0001,
			energy = math.ceil(obj:getEnergy() / obj:getMainProperty():GetMaxEnergy() * 10000) * 0.0001
		}

	end

	for i = #self.sortDustObjs.friend, 1, -1 do

		obj = self.sortDustObjs.friend[i]
		result[tostring(obj:getOCardId())] = {
			hp = math.ceil(obj:getMainProperty():getCurHpPercent() * 10000) * 0.0001,
			energy = math.ceil(obj:getEnergy() / obj:getMainProperty():GetMaxEnergy() * 10000) * 0.0001
		}

	end

	return result
end
--[[
获取存活的怪物剩余状态
@return result map {
	[teamPosition] = hpPercent,
	[teamPosition] = hpPercent,
	...
}
--]]
function BattleData:GetAliveEnemyObjStatus()
	local result = {}

	for i = #self.sortBattleObjs.enemy, 1, -1 do

		obj = self.sortBattleObjs.enemy[i]
		result[tostring(obj:getTeamPosition())] = math.ceil(obj:getMainProperty():getCurHpPercent() * 10000) * 0.0001

	end

	for i = #self.sortDustObjs.enemy, 1, -1 do

		obj = self.sortDustObjs.enemy[i]
		result[tostring(obj:getTeamPosition())] = math.ceil(obj:getMainProperty():getCurHpPercent() * 10000) * 0.0001

	end

	return result
end
---------------------------------------------------
-- object status data end --
---------------------------------------------------

--[[
销毁battleData
--]]
function BattleData:destroy()
	------------ destroy object ------------
	local obj = nil

	for i = #self.sortBattleObjs.friend, 1, -1 do
		obj = self.sortBattleObjs.friend[i]
		obj:destroy()
	end

	for i = #self.sortBattleObjs.enemy, 1, -1 do
		obj = self.sortBattleObjs.enemy[i]
		obj:destroy()
	end

	for i = #self.sortBattleObjs.beckonObj, 1, -1 do
		obj = self.sortBattleObjs.beckonObj[i]
		obj:destroy()
	end

	for i = #self.sortBattleObjs.bullet, 1, -1 do
		obj = self.sortBattleObjs.bullet[i]
		obj:destroy()
	end

	for i = #self.sortPlayerObj.friend, 1, -1 do
		obj = self.sortPlayerObj.friend[i]
		obj:destroy()
	end

	for i = #self.sortPlayerObj.enemy, 1, -1 do
		obj = self.sortPlayerObj.enemy[i]
		obj:destroy()
	end

	for i = #self.sortDustObjs.friend, 1, -1 do
		obj = self.sortDustObjs.friend[i]
		obj:destroy()
	end

	for i = #self.sortDustObjs.enemy, 1, -1 do
		obj = self.sortDustObjs.enemy[i]
		obj:destroy()
	end

	for i = #self.sortDustObjs.beckonObj, 1, -1 do
		obj = self.sortDustObjs.beckonObj[i]
		obj:destroy()
	end

	for i = #self.sortRestObjs, 1, -1 do
		obj = self.sortRestObjs[i]
		obj:destroy()
	end

	for i = #self.sortObserverObj, 1, -1 do
		obj = self.sortObserverObj[i]
		obj:destroy()
	end
	------------ destroy object ------------

	self.sortBattleObjs = {friend = {}, enemy = {}, bullet = {}, beckonObj = {}}
	self.battleObjs = {}
	self.sortDustObjs = {friend = {}, enemy = {}, beckonObj = {}}
	self.dustObjs = {}
	self.sortRestObjs = {}
	self.restObjs = {}
	self.sortWeather = {}
	self.weather = {}
	self.sortPlayerObj = {friend = {}, enemy = {}}
	self.playerObj = {}
	self.sortObserverObj = {}
	self.observerObj = {}
	
	self.ciScenes = {pause = {}, normal = {}} -- 缓存ci场景 暂停的时候会判断ci场景是否暂停了obj 如果有恢复的时候不会恢复obj
	self.timeScale = nil
	self.isPause = nil
	self.isPauseTimer = nil
	self.pauseActions = {battle = {}, ciScene = {}, normalCIScene = {}} -- 缓存暂停的action
	self.gameState = nil
	self.nextWave = nil
	self.gameTime = nil
	self.currentWave = nil
	self.phaseChangeData = nil
	self.nextPhaseChange = nil
end

---------------------------------------------------
-- battle record begin --
---------------------------------------------------
--[[
/**
 * 1 attackType: 1:普攻 2:普攻暴击 3:施放卡牌技能 4:卡牌技能效果结束
 * 2 defenderId为空表示全体
 * 3 如果attackerId=defenderId，表示给自己放技能
 * 4 hp是增加/扣掉的血量，正数表示增加，负数表示扣掉
 * 5 放主角技的时候，attackerId为0
 *
 *
 * fightNo=cardId&fightNo=monsterId|||attackerId#defenderId,defenderId#actionType#skillId#attackerHp#defenderHp,defenderHp;...
 */
--]]

--[[
向战斗记录字符串添加一个tag映射记录
@params tag int 
@params cardId int 卡牌id
--]]
function BattleData:addATagStr(tag, cardId)
	self.tagStr = self.tagStr .. '&' .. tostring(tag) .. '=' .. tostring(cardId)
end
--[[
向战斗记录字符串添加一个伤害信息
@params damageData ObjectDamageStruct
@params damage int 伤害数值
@params attackerEnergy int 攻击者的能量
--]]
function BattleData:addADamageStr(damageData, damage, attackerEnergy)
	local attackerTag = nil
	local defenderTag = damageData.targetTag
	local actionType = BDDamageType.N_ATTACK
	local skillId = 0
	local attackerHp = 0
	local defenderHp = damage

	if damageData.attackerTag then
		attackerTag = damageData.attackerTag
		defenderHp = -1 * damage
	elseif damageData.healerTag then
		attackerTag = damageData.healerTag
	end

	if damageData.skillInfo then
		actionType = BDDamageType.N_SKILL
		skillId = damageData.skillInfo.skillId
	elseif damageData.isCritical then
		actionType = BDDamageType.C_ATTACK
	end

	if nil ~= attackerEnergy then
		self.fightStr = self.fightStr .. 
			tostring(attackerTag) .. '#' ..
			tostring(defenderTag) .. '#' ..
			tostring(actionType) .. '#' ..
			tostring(skillId) .. '#' ..
			tostring(attackerHp) .. '#' ..
			tostring(defenderHp) .. '#' .. 
			tostring(attackerEnergy) .. ';' 
	else
		self.fightStr = self.fightStr .. tostring(attackerTag) .. '#' .. tostring(defenderTag) .. '#' .. tostring(actionType) .. '#' .. tostring(skillId) .. '#' .. tostring(attackerHp) .. '#' .. tostring(defenderHp) .. ';' 
	end

end
--[[
获取战斗记录的字符串
--]]
function BattleData:getFightDataStr()
	-- 处理战斗物体属性字符串
	self.overAliveFriendObjPStr = self:convertAllFriendObjPStr()

	-- 组装战斗主数据
	local tagStr = string.sub(self.tagStr, 2, string.len(self.tagStr))
	local fightStr = tagStr .. '|||' .. self.fightStr

	-- 组装战斗物体属性数据
	fightStr = fightStr .. '|||' .. self.startAliveFriendObjPStr .. '|||' .. self.tempAliveFriendObjPStr .. self.overAliveFriendObjPStr

	-- 组装战斗施法计数
	fightStr = fightStr .. '|||' .. self:getObjsSkillCastCounterStr()

	print('here check fight string>>>>>>>>>>>>>>>>>>>>>>>>>>>\n')
	print(fightStr)
	print('\nhere check fight string<<<<<<<<<<<<<<<<<<<<<<<<<<<')
	return fightStr
end
--[[
获取组队笨战斗记录的字符串
--]]
function BattleData:getRaidFightDataStr()
	-- 处理战斗物体属性字符串
	self.overAliveFriendObjPStr = self:convertAllFriendObjPStr()
	-- 组装战斗主数据
	local tagStr = string.sub(self.tagStr, 2, string.len(self.tagStr))

	local fightStr = tagStr .. '|||' .. self.fightStr

	-- 组装战斗物体属性数据
	fightStr = fightStr .. '|||' .. self.startAliveFriendObjPStr .. '|||' .. self.tempAliveFriendObjPStr .. self.overAliveFriendObjPStr

	-- 组装战斗施法计数
	fightStr = fightStr .. '|||' .. self:getObjsSkillCastCounterStr()

	print('here check fight string>>>>>>>>>>>>>>>>>>>>>>>>>>>\n')
	print(fightStr)
	print('\nhere check fight string<<<<<<<<<<<<<<<<<<<<<<<<<<<')
	return fightStr
end
--[[
获取当前所有物体施法的次数字符串
--]]
function BattleData:getObjsSkillCastCounterStr()
	local str = ''

	local obj = nil

	local recordFunc = function (obj)
		if nil ~= obj.castDriver then
			str = str .. tostring(obj:getOTag())
			local skillCastCounter = obj.castDriver:GetSkillCastCounter()
			for skillId, times in pairs(skillCastCounter) do
				str = str .. '#' .. skillId .. '#' .. tostring(times)
			end
			str = str .. ';'
		end
	end

	for i = 1, #self.sortBattleObjs.friend do
		obj = self.sortBattleObjs.friend[i]
		recordFunc(obj)
	end

	for i = 1, #self.sortBattleObjs.enemy do
		obj = self.sortBattleObjs.enemy[i]
		recordFunc(obj)
	end

	for i = 1, #self.sortDustObjs.friend do
		obj = self.sortDustObjs.friend[i]
		recordFunc(obj)
	end

	for i = 1, #self.sortDustObjs.enemy do
		obj = self.sortDustObjs.enemy[i]
		recordFunc(obj)
	end

	return str
end
--[[
记录一次所有物体的属性字符串
@return str_ 转换后的字符串
--]]
function BattleData:convertAllFriendObjPStr()
	local str_ = ''

	local obj = nil
	for i = #self.sortBattleObjs.friend, 1, -1 do
		obj = self.sortBattleObjs.friend[i]
		str_ = str_ .. self:getObjPStrByObj(obj)
	end

	return str_
end
--[[
获取当前对象6属性记录字符串
@params obj BaseObject 物体
@return str string 属性字符串
--]]
function BattleData:getObjPStrByObj(obj)
	local str = ''
	local otag = obj:getOTag()

	-- 先加上物体tag
	str = str .. tostring(otag) .. ','

	-- 加上物体属性
	local objpInfo = {
		ObjP.ATTACK,
		ObjP.DEFENCE,
		ObjP.HP,
		ObjP.ATTACKRATE,
		ObjP.CRITRATE,
		ObjP.CRITDAMAGE
	}
	for i,v in ipairs(objpInfo) do
		local p = obj:getMainProperty().p[v]:ObtainVal()
		str = str .. tostring(p)
		if i == #objpInfo then
			str = str .. ';'
		else
			str = str .. ','
		end
	end

	return str
end
--[[
push战中6属性字符串
@params pstr string 新增字符串
--]]
function BattleData:AddObjPStr(pstr)
	self.tempAliveFriendObjPStr = self.tempAliveFriendObjPStr .. pstr .. '|||'
end
--[[
获取死亡卡牌的id字符串
@return deadCards string 死亡卡牌id字符串
--]]
function BattleData:getDeadCardsStr()
	local deadCards = ''
	for i,v in ipairs(self.deadCardsId) do
		if i == 1 then
			deadCards = deadCards .. tostring(v)
		else
			deadCards = deadCards .. ',' .. tostring(v)
		end
	end
	return deadCards
end
---------------------------------------------------
-- battle record end --
---------------------------------------------------

---------------------------------------------------
-- raid socket data begin --
---------------------------------------------------
--[[
转换状态机信息至字符串
@params fsmData ObjectFSMStruct 状态机信息
@return str string 状态字符串
--]]
function BattleData:convertFSMData2String(fsmData)
	local str = ''
	for k,v in pairs(fsmData) do
		if nil ~= v.state then
			local ss = ''
			ss = ss .. tostring(k) .. '#' .. tostring(v.state) .. '#'
			if BattleObjectFSMState.CAST == v.state then
				ss = ss .. tostring(v.castSkillId)
			elseif BattleObjectFSMState.ATTACK == v.state then
				ss = ss .. tostring(v.aTargetTag)
			else
				ss = ss .. '0'
			end
			ss = ss .. ';'
			str = str .. ss
		end
	end
	return str
end
--[[
转换字符串至状态机信息
@params str 状态字符串
@return fsmData ObjectFSMStruct 状态机信息
--]]
function BattleData:convertString2FSMData(str)
	local fsmData = {}
	if nil == str or nil == BattleUtils.GetFilteredStringBySpace(str) then return fsmData end
	-- print('here check logic frame data ->>>>>>>>>>\n' .. '@@@' .. str .. '&&&')
	local ss = string.split(str, ';')
	for i,v in ipairs(ss) do
		if string.len(v) > 0 then
			print(i, v, 'here check data str????????????????')
			local sss = string.split(v, '#')
			local objTag = checkint(sss[1])
			local fsmState = checkint(sss[2])
			local exParam = checkint(sss[3])
			print(exParam, 'check exP>>>>>>>>')
			local params = {}
			if BattleObjectFSMState.CAST == fsmState then
				params.castSkillId = exParam
			elseif BattleObjectFSMState.ATTACK == fsmState then
				params.aTargetTag = exParam
			end
			local fd = ObjectFSMStruct.New(fsmState, params)
			fsmData[tostring(objTag)] = fd
		end
	end
	return fsmData
end
---------------------------------------------------
-- raid socket data end --
---------------------------------------------------

return BattleData

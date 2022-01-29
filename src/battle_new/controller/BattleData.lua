--[[
战斗数据
@params ... table {
	battleConstructor BattleConstructor 战斗构造器
}
--]]
local BattleData = class('BattleData')

------------ import ------------
------------ import ------------

------------ define ------------
------------ define ------------

--[[
constructor
--]]
function BattleData:ctor( ... )
	local args = unpack({...})

	self.battleConstructor = args.battleConstructor

	self:Init()
end

---------------------------------------------------
-- data init begin --
---------------------------------------------------
--[[
初始化
--]]
function BattleData:Init()
	self:InitValue()
end
--[[
初始化数据
--]]
function BattleData:InitValue()
	------------ game state data ------------
	-- 游戏速度缩放
	self.timeScale = 1
	-- 当前的游戏速度缩放
	self.currentTimeScale = 1

	-- 游戏暂停标志位
	self.isPause = false

	-- 游戏计时器暂停标志位
	self.isPauseTimer = false

	-- 游戏状态
	self.gameState = GState.READY

	-- 下一波序号
	self.nextWave = 1
	-- 当前波序号
	self.currentWave = 0

	-- 下一波的tips
	self.nextWaveTips = {
		hasElite = false,
		hasBoss = false
	}

	-- 游戏时间
	self.gameTime = self:GetBattleConstructData().time
	-- 本场剩余时间
	self.leftTime = self.gameTime
	------------ game state data ------------

	------------ cache data ------------
	-- 存活的obj总表
	self.sortBattleObjs = {
		friend 		= {},
		enemy 		= {},
		bullet 		= {},
		beckonObj 	= {}
	}
	self.battleObjs = {}

	-- 死亡的obj总表 战斗对象动作做完以后再去切波数 bullet不计算在内 切波数的时候直接移除
	self.sortDustObjs = {
		friend 		= {},
		enemy 		= {},
		beckonObj 	= {}
	}
	self.dustObjs = {}

	-- 休息区的obj总表
	self.sortRestObjs = {}
	self.restObjs = {}

	-- 其他的逻辑内的物体
	self.sortOtherObjs = {}
	self.otherObjs = {}

	-- 逻辑外的物体
	self.sortOBObjs = {}
	self.obObjs = {}

	-- 特殊物体
	self.globalEffectObj = nil
	self.obObj = nil

	-- 展示层模型
	self.sortObjViewModels = {}
	self.objViewModels = {}

	-- tag记录表
	self.nextTag = {}
	self:InitTagData()
	------------ cache data ------------

	------------ frame data ------------
	self.logicFrameIndex = 0
	self.renderFrameIndex = 0
	------------ frame data ------------

	------------ phase change data ------------
	-- 转阶段信息
	self.phaseChangeData = nil
	-- 初始化一次转阶段信息
	self:InitPhaseChangeData(self:GetBattleConstructData().phaseChangeDatas)

	-- 下一次的转阶段信息
	self.nextPhaseChange = {
		pauseLogic = {},
		nopauseLogic = {}
	}
	------------ phase change data ------------

	------------ 战斗数据记录 ------------
	self.renderOperateRecord = {}
	self.playerOperateRecord = {}
	------------ 战斗数据记录 ------------	

	--***---------- 渲染层操作记录 ----------***--
	-- 主循环内的渲染层操作
	self.renderOperate = {}
	-- 初始化一次传递给渲染层的操作 第0帧的逻辑
	self:InitNextRenderOperate()
	--***---------- 渲染层操作记录 ----------***--

	--###---------- 玩家手操记录 ----------###--
	-- 主循环内的玩家手操
	self.playerOperate = {}
	self.playerOperateTimeLine = {}
	-- 初始化一次玩家操作 第0帧的逻辑
	self:InitNextPlayerOperate(false)
	--###---------- 玩家手操记录 ----------###--

	------------ 加载的资源表 ------------
	self.loadedSpineResources = {}
	------------ 加载的资源表 ------------	

	------------ record data ------------
	-- 记录物体tag信息的串
	self.tagStr = ''

	-- 记录战斗过程的串
	self.fightStr = ''

	-- 记录初始物体属性的串
	self.startAliveFriendObjPStr = ''

	-- 记录战中物体属性的串
	self.tempAliveFriendObjPStr = ''

	-- 记录结束时物体属性的串
	self.overAliveFriendObjPStr = ''

	-- 记录死亡卡牌id
	self.deadCardsId = {}

	-- 记录的构造器数据
	self.recordConstructorData = nil
	------------ record data ------------
end
---------------------------------------------------
-- data init end --
---------------------------------------------------

---------------------------------------------------
-- phase change data begin --
---------------------------------------------------
--[[
初始化阶段转换信息
@params phaseActions table 转阶段配置信息
--]]
function BattleData:InitPhaseChangeData(phaseActions)
	-- 记录转阶段数据 触发时间点 此表记录的是每种怪物id会主动触发那些转阶段
	if nil == phaseActions then return end

	self.phaseChangeData = {}

	local phaseChangeConf = nil

	for _, actionId in ipairs(phaseActions) do

		phaseChangeConf = CommonUtils.GetConfig('quest', 'bossAction', checkint(actionId))

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
获取转阶段转换配表后的数据结构
--]]
function BattleData:GetPhaseChangeData()
	return self.phaseChangeData
end
---------------------------------------------------
-- phase change data end --
---------------------------------------------------

---------------------------------------------------
-- obj tag begin --
---------------------------------------------------
--[[
初始化tag记录表
--]]
function BattleData:InitTagData()
	for _, battleTagsType in pairs(BattleTags) do

		local tagConfig = BattleObjTagConfig[battleTagsType]
		local startTag = 0

		if nil ~= tagConfig and nil ~= tagConfig.lower then

			startTag = tagConfig.lower

		end

		self.nextTag[battleTagsType] = startTag + 1

	end
end
--[[
根据tag类型获取tag
@params tagType tag tag类型
@params isEnemy bool 是否是敌人
--]]
function BattleData:GetTagByTagType(tagType)
	local tag = self.nextTag[tagType]
	self.nextTag[tagType] = self.nextTag[tagType] + 1
	return tag
end
---------------------------------------------------
-- obj tag end --
---------------------------------------------------

---------------------------------------------------
-- data control begin --
---------------------------------------------------
--[[
添加一个战斗物体
@params obj BaseLogicModel
--]]
function BattleData:AddABattleObjLogicModel(obj)
	local otag = obj:GetOTag()

	if obj:IsEnemy(true) then
		table.insert(self.sortBattleObjs.enemy, 1, obj)
	else
		table.insert(self.sortBattleObjs.friend, 1, obj)
	end

	self.battleObjs[tostring(otag)] = obj

	-- 加入战斗记录
	self:AddATagStr(obj:GetOTag(), obj:GetObjectConfigId())
end
--[[
移除一个obj
@params obj BaseLogicModel
--]]
function BattleData:RemoveABattleObjLogicModel(obj)
	local otag = obj:GetOTag()

	if obj:IsEnemy(true) then
		for i = #self.sortBattleObjs.enemy, 1, -1 do
			if otag == self.sortBattleObjs.enemy[i]:GetOTag() then
				table.remove(self.sortBattleObjs.enemy, i)
				break
			end
		end
	else
		for i = #self.sortBattleObjs.friend, 1, -1 do
			if otag == self.sortBattleObjs.friend[i]:GetOTag() then
				table.remove(self.sortBattleObjs.friend, i)
				break
			end
		end
	end
	
	self.battleObjs[tostring(otag)] = nil
end
--[[
添加一个休息区物体
--]]
function BattleData:AddALogicModelToRest(o)
	local otag = o:GetOTag()
	table.insert(self.sortRestObjs, 1, o)
	self.restObjs[tostring(otag)] = o
end
--[[
移除一个休息区物体
--]]
function BattleData:RemoveALogicModelFromRest(o)
	local otag = o:GetOTag()
	for i = #self.sortRestObjs, 1, -1 do
		if otag == self.sortRestObjs[i]:GetOTag() then
			table.remove(self.sortRestObjs, i)
			break
		end
	end
	self.restObjs[tostring(otag)] = nil
end
--[[
根据tag获取休息区物体
@params otag int object tag
@return _ BaseLogicModel
--]]
function BattleData:GetALogicModelFromRest(otag)
	return self.restObjs[tostring(otag)]
end
--[[
添加一个非卡牌或者怪物的逻辑内物体
@params obj BaseLogicMode
--]]
function BattleData:AddAOtherLogicModel(obj)
	table.insert(self.sortOtherObjs, 1, obj)
	self.otherObjs[tostring(obj:GetOTag())] = obj
end
--[[
移除一个费卡牌或者怪物的逻辑内物体
@params obj BaseLogicModel
--]]
function BattleData:RemoveAOtherLogicModel(obj)
	local otag = obj:GetOTag()

	for i = #self.sortOtherObjs, 1, -1 do

		if otag == self.sortOtherObjs[i]:GetOTag() then
			table.remove(self.sortOtherObjs, i)
			break
		end

	end

	self.otherObjs[tostring(otag)] = nil
end
--[[
把一个obj加入墓地
@params o obj
@params nature bool 是否是自然死亡
--]]
function BattleData:AddALogicModelToDust(o, nature)
	local otag = o:GetOTag()

	if o:IsEnemy(true) then
		table.insert(self.sortDustObjs.enemy, 1, o)
	else
		-- 插入死亡卡牌数据
		if not nature then
			self:AddADeadCardStr(o:GetObjectConfigId())
		end
		table.insert(self.sortDustObjs.friend, 1, o)
	end

	self.dustObjs[tostring(otag)] = o
end
--[[
把一个obj移出墓地
--]]
function BattleData:RemoveALogicModelFromDust(o)
	local otag = o:GetOTag()

	if o:IsEnemy(true) then
		for i = #self.sortDustObjs.enemy, 1, -1 do
			if otag == self.sortDustObjs.enemy[i]:GetOTag() then
				table.remove(self.sortDustObjs.enemy, i)
				break
			end
		end
	else
		for i = #self.sortDustObjs.friend, 1, -1 do
			if otag == self.sortDustObjs.friend[i]:GetOTag() then
				table.remove(self.sortDustObjs.friend, i)
				break
			end
		end
	end
	
	self.dustObjs[tostring(otag)] = nil
end
--[[
根据敌友性获取当前场上人数
@params isEnemy bool 敌友性
@return _ int 人数
--]]
function BattleData:GetAliveObjectAmount(isEnemy)
	if isEnemy then
		return #self.sortBattleObjs.enemy
	else
		return #self.sortBattleObjs.friend
	end
end
--[[
是否可以从buff中创建召唤物
@return _ bool
--]]
function BattleData:CanCreateBeckonFromBuff()
	return MAX_BECKON_AMOUNT_LIMIT > #self.sortBattleObjs.beckonObj
end
--[[
向内存中添加一个召唤物物体
@params obj BeckonObjectModel 召唤物物体
--]]
function BattleData:AddABeckonObjLogicModel(obj)
	local otag = obj:GetOTag()

	table.insert(self.sortBattleObjs.beckonObj, 1, obj)

	self.battleObjs[tostring(otag)] = obj

	-- 加入战斗记录
	self:AddATagStr(obj:GetOTag(), obj:GetObjectConfigId())
end
--[[
移除一个召唤物物体
@params obj BeckonObjectModel 召唤物物体@params obj 
--]]
function BattleData:RemoveABeckonObjLogicModel(obj)
	local otag = obj:GetOTag()

	for i = #self.sortBattleObjs.beckonObj, 1, -1 do
		if otag == self.sortBattleObjs.beckonObj[i]:GetOTag() then
			table.remove(self.sortBattleObjs.beckonObj, i)
			break
		end
	end

	self.battleObjs[tostring(otag)] = nil
end
--[[
将一个召唤物物体加入墓地
@params o obj
@params nature bool 是否是自然死亡
--]]
function BattleData:AddABeckonModelToDust(o, nature)
	local otag = o:GetOTag()
	table.insert(self.sortDustObjs.beckonObj, 1, o)
	self.dustObjs[tostring(otag)] = o
end
--[[
将一个召唤物从墓地移除
@params o obj
--]]
function BattleData:RemoveABeckonModelFromDust(o)
	local otag = o:GetOTag()
	for i = #self.sortDustObjs.beckonObj, 1, -1 do
		if otag == self.sortDustObjs.beckonObj[i]:GetOTag() then
			table.remove(self.sortDustObjs.beckonObj, i)
			break
		end
	end
	self.dustObjs[tostring(otag)] = nil
end
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
--[[
设置ob物体
--]]
function BattleData:SetOBObject(object)
	self.obObj = object
end
function BattleData:GetOBObject()
	return self.obObj
end
--[[
添加一个逻辑外的ob物体
@params obj BaseLogicModel
--]]
function BattleData:AddAOBLogicModel(obj)
	table.insert(self.sortOBObjs, 1, obj)
	self.obObjs[tostring(obj:GetOTag())] = obj
end
--[[
移除一个逻辑外的ob物体
@params obj BaseLogicModel
--]]
function BattleData:RemoveAOtherLogicModel(obj)
	local otag = obj:GetOTag()

	for i = #self.sortOBObjs, 1, -1 do

		if otag == self.sortOBObjs[i]:GetOTag() then
			table.remove(self.sortOBObjs, i)
			break
		end

	end

	self.obObjs[tostring(otag)] = nil
end
---------------------------------------------------
-- data control end --
---------------------------------------------------

---------------------------------------------------
-- bullet data control begin --
---------------------------------------------------
--[[
向内存中添加一个bullet
@params obj BaseLogicModel
--]]
function BattleData:AddABulletModel(obj)
	local otag = obj:GetOTag()
	table.insert(self.sortBattleObjs.bullet, 1, obj)
	self.battleObjs[tostring(otag)] = obj
end
--[[
从内存中移除一个obj
@params obj BaseLogicModel
--]]
function BattleData:RemoveABulletModel(obj)
	local otag = obj:GetOTag()
	for i = #self.sortBattleObjs.bullet, 1, -1 do
		if otag == self.sortBattleObjs.bullet[i]:GetOTag() then
			table.remove(self.sortBattleObjs.bullet, i)
			break
		end
	end
	self.battleObjs[tostring(otag)] = nil
end
---------------------------------------------------
-- bullet data control end --
---------------------------------------------------

---------------------------------------------------
-- battle obj view data control begin --
---------------------------------------------------
--[[
向主循环中添加一个展示层模型
@params viewModel BaseViewModel
@params tag int
--]]
function BattleData:AddAObjViewModel(viewModel, tag)
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
function BattleData:RemoveAObjViewModel(viewModel, tag)
	if nil ~= self.objViewModels[tostring(tag)] then
		local viewModel = nil
		for i = #self.sortObjViewModels, 1, -1 do
			viewModel = self.sortObjViewModels[i]
			if tag == viewModel:GetViewModelTag() then
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
-- tag control begin --
---------------------------------------------------
--[[
根据tag获取战斗tag类型
@params tag int obj tag
@return _ BattleTags
--]]
function BattleData:GetBattleTagType(tag)
	if nil == tag then return BattleTags.BT_BASE end

	for battleTagType, battleTagInfo in pairs(BattleObjTagConfig) do

		if not battleTagInfo.ignore then
			local lowerJudge = false
			if nil == battleTagInfo.lower or battleTagInfo.lower < tag then
				lowerJudge = true
			end

			local upperJudge = false
			if nil == battleTagInfo.upper or battleTagInfo.upper > tag then
				upperJudge = true
			end

			-- print('here check fuck judge<<', battleTagInfo.lower, battleTagInfo.upper, lowerJudge, upperJudge, tag)

			if lowerJudge and upperJudge then
				return battleTagType
			end
		end

	end

	return BattleTags.BT_BASE
end
--[[
根据tag判断战斗物体是否存活
@params tag int 物体tag
@return _ obj BaseLogicModel
--]]
function BattleData:IsObjAliveByTag(tag)
	local tagType = self:GetBattleTagType(tag)

	if BattleTags.BT_FRIEND == tagType or
		BattleTags.BT_CONFIG_ENEMY == tagType or
		BattleTags.BT_OTHER_ENEMY == tagType or
		BattleTags.BT_BECKON == tagType or
		BattleTags.BT_BULLET == tagType then

		return self.battleObjs[tostring(tag)]

	elseif BattleTags.BT_WEATHER == tagType or
		BattleTags.BT_FRIEND_PLAYER == tagType or
		BattleTags.BT_ENEMY_PLAYER == tagType then

		return self.otherObjs[tostring(tag)]

	elseif BattleTags.BT_GLOBAL_EFFECT == tagType then

		return self:GetGlobalEffectObj()

	elseif BattleTags.BT_OBSERVER == tagType then

		return self.obObjs[tostring(tag)]

	end

	return nil
end
--[[
根据tag获取死亡的物体
@params tag int obj tag
--]]
function BattleData:GetDeadObjByTag(tag)
	local tagType = self:GetBattleTagType(tag)

	if BattleTags.BT_FRIEND == tagType or
		BattleTags.BT_CONFIG_ENEMY == tagType or
		BattleTags.BT_OTHER_ENEMY == tagType or
		BattleTags.BT_BECKON == tagType or
		BattleTags.BT_BULLET == tagType then

		return self.dustObjs[tostring(tag)]

	end

	return nil
end
--[[
根据卡牌id判断物体是否存活
@params cardId int 卡牌id
@params isEnemy bool 是否是敌人
@return _ obj BaseLogicModel
--]]
function BattleData:IsObjAliveByCardId(cardId, isEnemy)
	if nil == cardId then return nil end

	local obj = nil

	if isEnemy then

		for i = #self.sortBattleObjs.enemy, 1, -1 do
			obj = self.sortBattleObjs.enemy[i]
			if checkint(cardId) == checkint(obj:GetObjectConfigId()) then
				return obj
			end
		end

	else

		for i = #self.sortBattleObjs.friend, 1, -1 do
			obj = self.sortBattleObjs.friend[i]
			if checkint(cardId) == checkint(obj:GetObjectConfigId()) then
				return obj
			end
		end
		
	end

	return nil
end
--[[
根据物体tag强制获取物体 无视死活
@params tag int obj tag
@return obj BaseLogicModel
--]]
function BattleData:GetObjByTagForce(tag)
	local tagType = self:GetBattleTagType(tag)

	local obj = nil

	if BattleTags.BT_FRIEND == tagType or
		BattleTags.BT_CONFIG_ENEMY == tagType or
		BattleTags.BT_OTHER_ENEMY == tagType or
		BattleTags.BT_BECKON == tagType or
		BattleTags.BT_BULLET == tagType then

		obj = self.battleObjs[tostring(tag)]

		if nil == obj then
			obj = self.dustObjs[tostring(tag)]
		end

	elseif BattleTags.BT_WEATHER == tagType or
		BattleTags.BT_FRIEND_PLAYER == tagType or
		BattleTags.BT_ENEMY_PLAYER == tagType then

		obj = self.otherObjs[tostring(tag)]	

	end

	return obj
end
--[[
根据物体卡牌id强制获取物体
@parmas cardId int 卡牌id
@params isEnemy bool 敌友性
@return obj BaseLogicModel
--]]
function BattleData:GetObjByCardIdForce(cardId, isEnemy)
	local obj = nil

	if isEnemy then

		for i = #self.sortBattleObjs.enemy, 1, -1 do
			obj = self.sortBattleObjs.enemy[i]
			if checkint(id) == checkint(obj:GetObjectConfigId()) then
				return obj
			end
		end

		for i = #self.sortDustObjs.enemy, 1, -1 do
			obj = self.sortDustObjs.enemy[i]
			if checkint(id) == checkint(obj:GetObjectConfigId()) then
				return obj
			end
		end

	else

		for i = #self.sortBattleObjs.friend, 1, -1 do
			obj = self.sortBattleObjs.friend[i]
			if checkint(id) == checkint(obj:GetObjectConfigId()) then
				return obj
			end
		end

		for i = #self.sortDustObjs.friend, 1, -1 do
			obj = self.sortDustObjs.friend[i]
			if checkint(id) == checkint(obj:GetObjectConfigId()) then
				return obj
			end
		end

	end

	return nil
end
--[[
根据tag反向获取战斗元素类型
@params tag int 目标tag
@params _ BattleElementType 战斗元素类型
--]]
function BattleData:GetBattleElementTypeByTag(tag)
	local tagType = self:GetBattleTagType(tag)
	local battleTagInfo = BattleObjTagConfig[tagType]
	
	if nil ~= battleTagInfo then
		return BattleObjTagConfig[tagType].elementType
	else
		return BattleElementType.BET_BASE
	end
end
---------------------------------------------------
-- tag control end --
---------------------------------------------------

---------------------------------------------------
-- battle time begin --
---------------------------------------------------
--[[
获取战斗剩余的时间
@return _ number
--]]
function BattleData:GetLeftTime()
	return self.leftTime
end
--[[
设置战斗剩余时间
@params time number 剩余时间
--]]
function BattleData:SetLeftTime(time)
	self.leftTime = time
end
--[[
获取本场战斗总时间
@return _ number 总时间
--]]
function BattleData:GetGameTime()
	return self.gameTime
end
--[[
设置本场战斗总时间
@params time numebr 总时间
--]]
function BattleData:SetGameTime(time)
	self.gameTime = time
end
--[[
获取战斗消耗的时间
--]]
function BattleData:GetPassedTime()
	return math.ceil((self:GetGameTime() - self:GetLeftTime()) * 1000) * 0.001
end
---------------------------------------------------
-- battle time end --
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
		result[tostring(obj:GetObjectConfigId())] = {
			hp = math.ceil(obj:GetHPPercent() * 10000) * 0.0001,
			energy = math.ceil(obj:GetEnergyPercent() * 10000) * 0.0001
		}

	end

	for i = #self.sortDustObjs.friend, 1, -1 do

		obj = self.sortDustObjs.friend[i]
		result[tostring(obj:GetObjectConfigId())] = {
			hp = math.ceil(obj:GetHPPercent() * 10000) * 0.0001,
			energy = math.ceil(obj:GetEnergyPercent() * 10000) * 0.0001
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
		result[tostring(obj:GetTeamPosition())] = math.ceil(obj:GetHPPercent() * 10000) * 0.0001

	end

	for i = #self.sortDustObjs.enemy, 1, -1 do

		obj = self.sortDustObjs.enemy[i]
		result[tostring(obj:GetTeamPosition())] = math.ceil(obj:GetHPPercent() * 10000) * 0.0001

	end

	return result
end
---------------------------------------------------
-- object status data end --
---------------------------------------------------

---------------------------------------------------
-- buy revive begin --
---------------------------------------------------
--[[
是否能够买活
@return _ bool 是否能够买活
--]]
function BattleData:CanBuyRevival()
	return self:GetBattleConstructData().canBuyCheat and self:GetLeftBuyRevivalTime() > 0
end
--[[
获取剩余的买活次数
@return _ int 剩余买活次数
--]]
function BattleData:GetLeftBuyRevivalTime()
	return math.max(0, self:GetBattleConstructData().buyRevivalTimeMax - self:GetBattleConstructData().buyRevivalTime)
end
--[[
增加买活次数
@params delta int 买活次数
--]]
function BattleData:AddBuyRevivalTime(delta)
	self:GetBattleConstructData().buyRevivalTime = self:GetBattleConstructData().buyRevivalTime + delta
end
--[[
获取当前买活次数
--]]
function BattleData:GetBuyRevivalTime()
	return self:GetBattleConstructData().buyRevivalTime
end
--[[
获取下一次买活次数
--]]
function BattleData:GetNextBuyRevivalTime()
	return math.min(self:GetBattleConstructData().buyRevivalTimeMax, self:GetBuyRevivalTime() + 1)
end
--[[
是否可以免费买活
--]]
function BattleData:CanBuyRevivalFree()
	local result = false
	local geObj = self:GetGlobalEffectObj()

	if nil ~= geObj then
		local liveCheatFreeBuffs = geObj:GetBuffsByBuffType(ConfigBuffType.LIVE_CHEAT_FREE)
		if not BattleUtils.IsTableEmpty(liveCheatFreeBuffs) then
			for _, buff in ipairs(liveCheatFreeBuffs) do
				if 0 < buff:GetFreeCheatLiveTimes() then
					result = true
					break
				end
			end
		end
	end

	return result
end
--[[
消耗免费买活次数
--]]
function BattleData:CostBuyRevivalFree()
	local geObj = self:GetGlobalEffectObj()

	if nil ~= geObj then
		local liveCheatFreeBuffs = geObj:GetBuffsByBuffType(ConfigBuffType.LIVE_CHEAT_FREE)
		if not BattleUtils.IsTableEmpty(liveCheatFreeBuffs) then
			for _, buff in ipairs(liveCheatFreeBuffs) do
				if 0 < buff:GetFreeCheatLiveTimes() then
					buff:OnCauseEffectEnter()
					break
				end
			end
		end
	end
end
---------------------------------------------------
-- buy revive end --
---------------------------------------------------

---------------------------------------------------
-- phase change data begin --
---------------------------------------------------
--[[
向内存中添加一个阶段转换
@params pauseLogic bool 是否阻塞主逻辑
@params phaseData ObjectPhaseSturct 触发转阶段的信息
--]]
function BattleData:AddAPhaseChange(pauseLogic, phaseData)
	if true == pauseLogic then
		table.insert(self.nextPhaseChange.pauseLogic, 1, phaseData)
	else
		table.insert(self.nextPhaseChange.nopauseLogic, 1, phaseData)
	end
end
--[[
从内存中移除一个阶段转换
@params pauseLogic bool 是否阻塞主逻辑
@params index int 序号
--]]
function BattleData:RemoveAPhaseChange(pauseLogic, index)
	if true == pauseLogic then
		table.remove(self.nextPhaseChange.pauseLogic, index)
	else
		table.remove(self.nextPhaseChange.nopauseLogic, index)
	end
end
--[[
获取下一次的转阶段信息
@params pauseLogic bool 是否阻塞主逻辑
@return _ list<ObjectPhaseSturct> 转阶段信息
--]]
function BattleData:GetNextPhaseChange(pauseLogic)
	if true == pauseLogic then
		return self.nextPhaseChange.pauseLogic
	else
		return self.nextPhaseChange.nopauseLogic
	end
end
---------------------------------------------------
-- phase change data end --
---------------------------------------------------

---------------------------------------------------
-- frame index begin --
---------------------------------------------------
--[[
逻辑帧自增
--]]
function BattleData:AddLogicFrameIndex()
	self.logicFrameIndex = self.logicFrameIndex + 1
end
--[[
获取逻辑帧序号
--]]
function BattleData:GetLogicFrameIndex()
	return self.logicFrameIndex
end
--[[
渲染帧自增
--]]
function BattleData:AddRenderFrameIndex()
	self.renderFrameIndex = self.renderFrameIndex + 1
end
--[[
获取渲染帧序号
--]]
function BattleData:GetRenderFrameIndex()
	return self.renderFrameIndex
end
---------------------------------------------------
-- frame index end --
---------------------------------------------------

---------------------------------------------------
-- res record begin --
---------------------------------------------------
--[[
记录加载的资源
@params wave int 波数
@params resmap map 加载的资源
--]]
function BattleData:RecordLoadedResources(wave, resmap)
	if nil ~= self.loadedSpineResources[wave] then
		BattleUtils.PrintBattleWaringLog('you want to record battle resmap again !!! wave -> ' .. wave)
	end
	self.loadedSpineResources[wave] = clone(resmap)
end
function BattleData:GetLoadedResources()
	return self.loadedSpineResources
end
---------------------------------------------------
-- res record end --
---------------------------------------------------

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
function BattleData:AddATagStr(tag, cardId)
	self.tagStr = self.tagStr .. '&' .. tostring(tag) .. '=' .. tostring(cardId)
end
--[[
记录一次所有物体的属性字符串
@return str_ 转换后的字符串
--]]
function BattleData:ConvertAllFriendObjPStr()
	local str_ = ''

	local obj = nil
	for i = #self.sortBattleObjs.friend, 1, -1 do
		obj = self.sortBattleObjs.friend[i]
		str_ = str_ .. self:GetObjPStrByObj(obj)
	end
	for i = #self.sortBattleObjs.enemy, 1, -1 do
		obj = self.sortBattleObjs.enemy[i]
		str_ = str_ .. self:GetObjPStrByObj(obj)
	end

	return str_
end
--[[
获取当前对象6属性记录字符串
@params obj BaseObject 物体
@return str string 属性字符串
--]]
function BattleData:GetObjPStrByObj(obj)
	local str = ''
	local otag = obj:GetOTag()

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
		local p = obj:GetMainProperty().p[v]
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
刷一次物体的初始属性
--]]
function BattleData:RecordStartAliveFriendObjPStr()
	self.startAliveFriendObjPStr = self:ConvertAllFriendObjPStr()
end
--[[
记录一次死亡卡牌
@params cardId int 卡牌id
--]]
function BattleData:AddADeadCardStr(cardId)
	table.insert(self.deadCardsId, cardId)
end
--[[
获取死亡卡牌的id字符串
@return deadCards string 死亡卡牌id字符串
--]]
function BattleData:GetDeadCardsStr()
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
--[[
获取战斗记录的字符串
--]]
function BattleData:GetFightDataStr()
	-- 处理战斗物体属性字符串
	self.overAliveFriendObjPStr = self:ConvertAllFriendObjPStr()

	local tagStr = string.sub(self.tagStr, 2, string.len(self.tagStr))
	
	local fightDatas = {
		-- 标签对象
		tagStr,
		-- 战斗数据
		self.fightStr,
		-- 组装战斗物体属性数据
		self.startAliveFriendObjPStr,
		self.tempAliveFriendObjPStr .. self.overAliveFriendObjPStr,
		-- 组装战斗施法计数
		self:GetObjsSkillCastCounterStr()
	}
	local fightStr = table.concat(fightDatas, '|||')
	

	-- -- 组装战斗主数据
	-- local tagStr = string.sub(self.tagStr, 2, string.len(self.tagStr))
	-- local fightStr = tagStr .. '|||' .. self.fightStr

	-- -- 组装战斗物体属性数据
	-- fightStr = fightStr .. '|||' .. self.startAliveFriendObjPStr .. '|||' .. self.tempAliveFriendObjPStr .. self.overAliveFriendObjPStr

	-- -- 组装战斗施法计数
	-- fightStr = fightStr .. '|||' .. self:GetObjsSkillCastCounterStr()

	print('here check fight string>>>>>>>>>>>>>>>>>>>>>>>>>>>\n')
	print(fightStr)
	print('\nhere check fight string<<<<<<<<<<<<<<<<<<<<<<<<<<<')
	return fightStr
end
--[[
获取当前所有物体施法的次数字符串
--]]
function BattleData:GetObjsSkillCastCounterStr()
	local str = ''

	local obj = nil

	local recordFunc = function (obj)
		if nil ~= obj.castDriver then
			str = str .. tostring(obj:GetOTag())
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
向战斗记录字符串添加一个伤害信息
@params damageData ObjectDamageStruct
@params damage int 伤害数值
@params attackerEnergy int 攻击者的能量
--]]
function BattleData:AddADamageStr(damageData, damage, attackerEnergy)
	local attackerTag = nil
	local defenderTag = damageData.targetTag
	local actionType = BDDamageType.N_ATTACK
	local skillId = 0
	local attackerHp = 0
	local defenderHp = damage
	local frameIndex = self:GetLogicFrameIndex()
	

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
	BattleUtils.PrintBattleActionLog(string.format('__________AddADamageStr__________ %d ) %d -> %d  [acition = %d | skill = %d] value = %f', 
		frameIndex, 
		attackerTag, 
		defenderTag, 
		actionType, 
		skillId,
		defenderHp
	))
	if nil ~= attackerEnergy then
		self.fightStr = self.fightStr ..
			tostring(attackerTag) .. '#' ..
			tostring(defenderTag) .. '#' ..
			tostring(actionType) .. '#' ..
			tostring(skillId) .. '#' ..
			tostring(attackerHp) .. '#' ..
			tostring(defenderHp) .. '#' ..
			tostring(frameIndex) .. '#' ..
			tostring(attackerEnergy) .. ';'
	else
		self.fightStr = self.fightStr ..
			tostring(attackerTag) .. '#' ..
			tostring(defenderTag) .. '#' ..
			tostring(actionType) .. '#' ..
			tostring(skillId) .. '#' ..
			tostring(attackerHp) .. '#' ..
			tostring(frameIndex) .. '#' ..
			tostring(defenderHp) .. ';'
	end
end
--[[
设置构造器数据
--]]
function BattleData:RecordConstructorData(data)
	self.recordConstructorData = data
end
function BattleData:GetConstructorData()
	return self.recordConstructorData
end
---------------------------------------------------
-- battle record end --
---------------------------------------------------

---------------------------------------------------
-- next wave tips begin --
---------------------------------------------------
--[[
下一波是否含有精英
@params hasElite bool
--]]
function BattleData:SetNextWaveHasElite(hasElite)
	self.nextWaveTips.hasElite = hasElite
end
function BattleData:NextWaveHasElite()
	return self.nextWaveTips
end
--[[
下一波是否含有boss
@params boss bool
--]]
function BattleData:SetNextWaveHasBoss(hasBoss)
	self.nextWaveTips.hasBoss = hasBoss
end
function BattleData:NextWaveHasBoss()
	return self.nextWaveTips.hasBoss
end
---------------------------------------------------
-- next wave tips end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
当前波数
--]]
function BattleData:GetCurrentWave()
	return self.currentWave
end
function BattleData:SetCurrentWave(wave)
	self.currentWave = wave
end
--[[
下一波
--]]
function BattleData:GetNextWave()
	return self.nextWave
end
function BattleData:SetNextWave(wave)
	self.nextWave = wave
end
--[[
获取关卡总波数
--]]
function BattleData:GetStageTotalWave()
	return self:GetBattleConstructData().totalWave
end
function BattleData:SetStageTotalWave(wave)
	self:GetBattleConstructData().totalWave = wave
end
--[[
时间速度缩放
--]]
function BattleData:GetTimeScale()
	return self.timeScale
end
function BattleData:SetTimeScale(timeScale)
	self.timeScale = timeScale
	self:SetCurrentTimeScale(timeScale)
end
function BattleData:SetCurrentTimeScale(timeScale)
	self.currentTimeScale = timeScale
end
function BattleData:GetCurrentTimeScale()
	return self.currentTimeScale
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

---------------------------------------------------
-- battle constructor data begin --
---------------------------------------------------
--[[
获取战斗构造器
--]]
function BattleData:GetBattleConstructor()
	return self.battleConstructor
end
--[[
获取战斗构造数据
--]]
function BattleData:GetBattleConstructData()
	return self:GetBattleConstructor():GetBattleConstructData()
end
--[[
获取阵容信息
@params isEnemy bool 是否是敌人
@return _ FormationStruct
--]]
function BattleData:GetTeamData(isEnemy)
	if isEnemy then
		return self:GetBattleConstructData().enemyFormation
	else
		return self:GetBattleConstructData().friendFormation
	end
end
--[[
获取友方队伍成员
@params wave int 波数
@return _ table
--]]
function BattleData:GetFriendMembers(wave)
	if wave then
		return self:GetTeamData(false).members[wave]
	else
		return self:GetTeamData(false).members
	end
end
--[[
获取敌方队伍成员
@params wave int 波数
@return _ table
--]]
function BattleData:GetEnemyMembers(wave)
	if wave then
		return self:GetTeamData(true).members[wave]
	else
		return self:GetTeamData(true).members
	end
end
--[[
获取关卡天气配置
--]]
function BattleData:GetStageWeatherConfig()
	return self:GetBattleConstructData().weather
end
---------------------------------------------------
-- battle constructor data end --
---------------------------------------------------

---------------------------------------------------
-- render operate begin --
---------------------------------------------------
--[[
获取下一帧渲染层的操作信息
@return _ map {
	logicFrameIndex int 逻辑帧序号
	operate list 操作序列
} 渲染层操作数据
--]]
function BattleData:GetNextRenderOperate()
	local operateData = self.renderOperate[#self.renderOperate]
	if nil ~= operateData then
		self:RemoveNextRenderOperate()
		return operateData
	else
		return nil
	end 
end
--[[
移除下一帧渲染层操作
--]]
function BattleData:RemoveNextRenderOperate()
	table.remove(self.renderOperate, #self.renderOperate)
end
--[[
初始化下一帧渲染层操作数据
--]]
function BattleData:InitNextRenderOperate()
	local currentLogicFrameIndex = self:GetLogicFrameIndex()
	local topOperate = self.renderOperate[1]
	if nil == topOperate or currentLogicFrameIndex ~= topOperate.logicFrameIndex then
		topOperate = {logicFrameIndex = currentLogicFrameIndex, operate = {}}
		table.insert(self.renderOperate, 1, topOperate)
	end
end
--[[
添加渲染层操作
@params operate RenderOperateStruct 渲染层操作数据
--]]
function BattleData:AddRenderOperate(operate)
	local operateData = self.renderOperate[1]
	if nil ~= operateData then
		table.insert(operateData.operate, operate)

		-- 记录数据
		self:RecordRenderOperate(operate)
	end
end
---------------------------------------------------
-- render operate end --
---------------------------------------------------

---------------------------------------------------
-- player operate begin -- 	玩家手操内容
---------------------------------------------------
--[[
初始化下一帧玩家手操的内容
@params inMainUpdate bool 是否是在主循环中初始化的手操内容
--]]
function BattleData:InitNextPlayerOperate(inMainUpdate)
	local currentLogicFrameIndex = self:GetLogicFrameIndex()

	if true == inMainUpdate then
		-- /***********************************************************************************************************************************\
		--  * 在主循环中初始化时会自增1
		--  * 因为在主循环中初始化的手操内容 是在下一个逻辑帧中处理的
		-- \***********************************************************************************************************************************/
		currentLogicFrameIndex = currentLogicFrameIndex + 1
	end

	local topOperate = self.playerOperate[1]

	if nil == topOperate or currentLogicFrameIndex ~= topOperate.logicFrameIndex then

		-- 没有下一帧的手操数据
		if nil ~= self.playerOperateTimeLine[currentLogicFrameIndex] then
			-- timeline中存在这一帧的手操数据 直接用
			topOperate = self.playerOperateTimeLine[currentLogicFrameIndex]
			-- 移除老的
			self.playerOperateTimeLine[currentLogicFrameIndex] = nil
		else
			-- 不存在 新建
			topOperate = {logicFrameIndex = currentLogicFrameIndex, operate = {}}
		end

		table.insert(self.playerOperate, 1, topOperate)
	end
end
--[[
获取下一帧玩家的手操信息
@return _ map {
	logicFrameIndex int 逻辑帧序号
	operate list 操作序列
} 玩家手操信息
--]]
function BattleData:GetNextPlayerOperate()
	local operateData = self.playerOperate[#self.playerOperate]
	if nil ~= operateData then
		self:RemoveNextPlayerOperate()
		return operateData
	else
		return nil
	end
end
--[[
移除下一帧玩家操作
--]]
function BattleData:RemoveNextPlayerOperate()
	table.remove(self.playerOperate, #self.playerOperate)
end
--[[
添加玩家手操
@params operate LogicOperateStruct 渲染层操作数据
--]]
function BattleData:AddPlayerOperate(operate, deltaFrameIndex)
	if nil ~= deltaFrameIndex and 0 < deltaFrameIndex then
		-- 延后的手操内容 做动画的回调
		local currentLogicFrameIndex = self:GetLogicFrameIndex()
		local targetLogicFrameIndex = currentLogicFrameIndex + deltaFrameIndex
		local operateData = self.playerOperateTimeLine[targetLogicFrameIndex]
		if nil == operateData then
			operateData = {logicFrameIndex = targetLogicFrameIndex, operate = {}}
			self.playerOperateTimeLine[targetLogicFrameIndex] = operateData
		end
		table.insert(operateData.operate, operate)
		-- 记录数据
		self:RecordPlayerOperate(operate, operateData.logicFrameIndex)
	else
		local operateData = self.playerOperate[1]
		if nil ~= operateData then
			table.insert(operateData.operate, operate)
	
			-- 记录数据
			self:RecordPlayerOperate(operate, operateData.logicFrameIndex)
		end
	end
end
---------------------------------------------------
-- player operate end -- 	玩家手操内容
---------------------------------------------------

---------------------------------------------------
-- operate record begin -- 	战斗操作数据记录
---------------------------------------------------
--[[
记录渲染层操作
@params operate RenderOperateStruct 渲染层操作数据
--]]
function BattleData:RecordRenderOperate(operate)
	local currentLogicFrameIndex = self:GetLogicFrameIndex()
	if nil == self.renderOperateRecord[currentLogicFrameIndex] then
		self.renderOperateRecord[currentLogicFrameIndex] = {}
	end
	table.insert(self.renderOperateRecord[currentLogicFrameIndex], operate)
end
--[[
获取渲染层操作记录
@return _ list<list<RenderOperateStruct>>
--]]
function BattleData:GetRenderOperateRecord()
	return self.renderOperateRecord
end
--[[
记录玩家手操
@params operate LogicOperateStruct 渲染层操作数据
@params logicFrameIndex int 逻辑帧序号
--]]
function BattleData:RecordPlayerOperate(operate, logicFrameIndex)
	local isIgnoreRecord = BattleConfigUtils.IsIgnoreRecordPLayerOperate(operate.managerName, operate.functionName)
	if isIgnoreRecord then
		return
	end
	
	if nil == self.playerOperateRecord[logicFrameIndex] then
		self.playerOperateRecord[logicFrameIndex] = {}
	end
	table.insert(self.playerOperateRecord[logicFrameIndex], operate)
end
--[[
获取玩家手操记录
@return _ list<list<LogicOperateStruct>>
--]]
function BattleData:GetPlayerOperateRecord()
	return self.playerOperateRecord
end
function BattleData:SetPlayerOperateRecord(playerOperate)
	assert(nil == next(self.playerOperateRecord), 'you want to set data to playerOperateRecord but playerOperateRecord already be recorded')
	self.playerOperateRecord = playerOperate
end
---------------------------------------------------
-- operate record end -- 	战斗操作数据记录
---------------------------------------------------

---------------------------------------------------
-- destroy begin --
---------------------------------------------------
--[[
销毁战斗数据
--]]
function BattleData:Destroy()
	self:DestroyAllBattleObject()
	self:DestroyValue()
end
--[[
销毁所有的战斗物体
--]]
function BattleData:DestroyAllBattleObject()
	local obj = nil

	for i = #self.sortBattleObjs.friend, 1, -1 do
		obj = self.sortBattleObjs.friend[i]
		obj:Destroy()
	end

	for i = #self.sortBattleObjs.enemy, 1, -1 do
		obj = self.sortBattleObjs.enemy[i]
		obj:Destroy()
	end

	for i = #self.sortBattleObjs.bullet, 1, -1 do
		obj = self.sortBattleObjs.bullet[i]
		obj:Destroy()
	end

	for i = #self.sortBattleObjs.beckonObj, 1, -1 do
		obj = self.sortBattleObjs.beckonObj[i]
		obj:Destroy()
	end

	for i = #self.sortDustObjs.friend, 1, -1 do
		obj = self.sortDustObjs.friend[i]
		obj:Destroy()
	end

	for i = #self.sortDustObjs.enemy, 1, -1 do
		obj = self.sortDustObjs.enemy[i]
		obj:Destroy()
	end

	for i = #self.sortDustObjs.enemy, 1, -1 do
		obj = self.sortDustObjs.enemy[i]
		obj:Destroy()
	end

	for i = #self.sortDustObjs.beckonObj, 1, -1 do
		obj = self.sortDustObjs.beckonObj[i]
		obj:Destroy()
	end

	for i = #self.sortRestObjs, 1, -1 do
		obj = self.sortRestObjs[i]
		obj:Destroy()
	end

	for i = #self.sortOBObjs, 1, -1 do
		obj = self.sortOBObjs[i]
		obj:Destroy()
	end
end
--[[
销毁数据
--]]
function BattleData:DestroyValue()
	self.timeScale = 1
	self.currentTimeScale = 1
	self.isPause = false
	self.isPauseTimer = false
	self.gameState = GState.READY
	self.nextWave = 1
	self.currentWave = 0
	self.nextWaveTips = {
		hasElite = false,
		hasBoss = false
	}
	self.gameTime = nil
	self.leftTime = nil
	self.sortBattleObjs = {
		friend 		= {},
		enemy 		= {},
		bullet 		= {},
		beckonObj 	= {}
	}
	self.battleObjs = {}
	self.sortDustObjs = {
		friend 		= {},
		enemy 		= {},
		beckonObj 	= {}
	}
	self.dustObjs = {}
	self.sortRestObjs = {}
	self.restObjs = {}
	self.sortOtherObjs = {}
	self.otherObjs = {}
	self.sortOBObjs = {}
	self.obObjs = {}
	self.sortObjViewModels = {}
	self.objViewModels = {}
	self.nextTag = {}
	self:InitTagData()
	self.logicFrameIndex = 0
	self.renderFrameIndex = 0
	self.phaseChangeData = nil
	self.nextPhaseChange = {
		pauseLogic = {},
		nopauseLogic = {}
	}
	self.renderOperate = {}
	self.externalRenderOperate = {}
	self.playerOperate = {}
	self.externalPlayerOperate = {}
	self.tagStr = ''
	self.fightStr = ''
	self.startAliveFriendObjPStr = ''
	self.tempAliveFriendObjPStr = ''
	self.overAliveFriendObjPStr = ''
	self.deadCardsId = {}
	self.recordConstructorData = nil
end
---------------------------------------------------
-- destroy end --
---------------------------------------------------

return BattleData

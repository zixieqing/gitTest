--[[
战斗切波驱动器
--]]
local BaseBattleDriver = __Require('battle.battleDriver.BaseBattleDriver')
local BattleShiftDriver = class('BattleShiftDriver', BaseBattleDriver)

------------ import ------------
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
------------ import ------------

------------ define ------------
------------ define ------------

--[[
constructor
--]]
function BattleShiftDriver:ctor( ... )
	BaseBattleDriver.ctor(self, ...)
	self.driverType = BattleDriverType.SHIFT_DRIVER

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
function BattleShiftDriver:Init()
	self.currentTeamIndex = {
		friend = 0,
		enemy = 0
	}
end
---------------------------------------------------
-- init logic end --
---------------------------------------------------

---------------------------------------------------
-- control logic begin --
---------------------------------------------------
--[[
@override
是否能进行逻辑
--]]
function BattleShiftDriver:CanDoLogic(dt)
	local bdata = self:GetOwner():GetBData()
	if bdata:getNextWave() <= bdata:getStageTotalWave() then
		return self:CanEnterNextWave(dt)
	end
	return false
end
--[[
@override
逻辑开始
--]]
function BattleShiftDriver:OnLogicEnter(dt)
	if not self:CanDoLogic(dt) then return end

	-- 进入下一波
	self:OnShiftEnter()
end
--[[
@override
逻辑进行中
--]]
function BattleShiftDriver:OnLogicUpdate(dt)

end
--[[
@override
逻辑结束
--]]
function BattleShiftDriver:OnLogicExit()

end
--[[
进入下一波
--]]
function BattleShiftDriver:OnShiftEnter()
	self:GetOwner():SetGState(GState.READY)

	-- 屏蔽触摸
	self:GetOwner():SetBattleTouchEnable(false)

	-- 显示切波动画
	self:GetOwner():ShowWaveTransition({
		callbacks = {
			changeBegin = handler(self, self.OnShiftBegin),
			changeEnd = handler(self, self.OnShiftEnd)
		}
	})
end
--[[
进入下一波结束
--]]
function BattleShiftDriver:OnShiftExit()
	self:OnLogicExit()
end
--[[
开始切换下一波
--]]
function BattleShiftDriver:OnShiftBegin()
	---------- 清理缓存对象 ----------
	local bdata = self:GetOwner():GetBData()

	local obj = nil
	local otag = nil

	-- 释放这一波未做完动画的子弹
	for i = #bdata.sortBattleObjs.bullet, 1, -1 do
		obj = bdata.sortBattleObjs.bullet[i]
		otag = obj:getOTag()
		bdata.battleObjs[tostring(otag)] = nil
		obj:destroy()
	end
	bdata.sortBattleObjs.bullet = {}

	-- 刷新一次召唤物
	for i = #bdata.sortBattleObjs.beckonObj, 1, -1 do
		obj = bdata.sortBattleObjs.beckonObj[i]
		obj:enterNextWave(bdata:getNextWave())
	end
	bdata.sortBattleObjs.beckonObj = {}

	-- 销毁墓地中的召唤物
	for i = #bdata.sortDustObjs.beckonObj, 1, -1 do
		obj = bdata.sortDustObjs.beckonObj[i]
		otag = obj:getOTag()
		bdata.dustObjs[tostring(otag)] = nil
		obj:destroy()
	end
	bdata.sortDustObjs.beckonObj = {}

	-- 杀死场上存活的敌方对象
	for i = #bdata.sortBattleObjs.enemy, 1, -1 do
		obj = bdata.sortBattleObjs.enemy[i]
		obj:KillByNature()
	end
	bdata.sortBattleObjs.enemy = {}

	-- 杀死场上存活的友军非卡牌物体
	for i = #bdata.sortBattleObjs.friend, 1, -1 do
		obj = bdata.sortBattleObjs.friend[i]
		if CardUtils.IsMonsterCard(obj:getOCardId()) then
			obj:KillByNature()
		end
	end
	---------- 清理缓存对象 ----------

	-- 创建下一波
	self:GetOwner():CreateNextWave()
	-- 初始化一次光环效果
	self:GetOwner():InitHalosEffect()
	-- 重置我方站位
	for i = #bdata.sortBattleObjs.friend, 1, -1 do
		obj = bdata.sortBattleObjs.friend[i]
		obj:enterNextWave(bdata:getCurrentWave())
	end
end
--[[
结束切换下一波
--]]
function BattleShiftDriver:OnShiftEnd()
	self:GetOwner():ShowNextWave({
		wave = self:GetOwner():GetBData():getCurrentWave(),
		callback = handler(self:GetOwner(), self:GetOwner().StartNextWave)
	})

	self:OnShiftExit()
end
--[[
是否可以进入下一波
@return result bool 
--]]
function BattleShiftDriver:CanEnterNextWave(dt)
	local result = true
	local bdata = self:GetOwner():GetBData()

	local obj = nil

	-- 刷新一遍子弹
	for i = #bdata.sortBattleObjs.bullet, 1, -1 do
		obj = bdata.sortBattleObjs.bullet[i]
		if not obj:canEnterNextWave() then
			result = false
			obj:update(dt)
		else
			obj:die()
		end
	end

	if false == result then
		return false
	end

	for _,normalCIScene in pairs(bdata.ciScenes.normal) do
		if normalCIScene:isVisible() then
			normalCIScene:die()	
		end
	end

	-- 场上存活的物体
	for i = #bdata.sortBattleObjs.friend, 1, -1 do
		obj = bdata.sortBattleObjs.friend[i]
		if not obj:canEnterNextWave() then
			result = false
		end
	end
	for i = #bdata.sortBattleObjs.enemy, 1, -1 do
		obj = bdata.sortBattleObjs.enemy[i]
		if not obj:canEnterNextWave() then
			result = false
		end
	end
	for i = #bdata.sortBattleObjs.beckonObj, 1, -1 do
		obj = bdata.sortBattleObjs.beckonObj[i]
		if not obj:canEnterNextWave() then
			result = false
		end
	end
	-- 墓地中的物体
	for i = #bdata.sortDustObjs.friend, 1, -1 do
		obj = bdata.sortDustObjs.friend[i]
		if not obj:canEnterNextWave() then
			result = false
		end
	end
	for i = #bdata.sortDustObjs.enemy, 1, -1 do
		obj = bdata.sortDustObjs.enemy[i]
		if not obj:canEnterNextWave() then
			result = false
		end
	end
	-- 休息区等待重新上场的物体
	for i = #bdata.sortRestObjs, 1, -1 do
		obj = bdata.sortRestObjs[i]
		if not obj:canEnterNextWave() then
			result = false
		end
	end

	return result
end
--[[
创建下一波的敌人
--]]
function BattleShiftDriver:OnCreateNextWaveEnter()
	---------- data ----------
	-- 创建物体
	self:CreateNextWaveObjs()
	-- 重置计数器
	self:GetOwner():GetBData():setCurrentWave(self:GetOwner():GetBData():getNextWave())
	self:GetOwner():GetBData():setNextWave(self:GetOwner():GetBData():getNextWave() + 1)
	---------- data ----------

	local totalWave = self:GetOwner():GetBData():getStageTotalWave()

	---------- view ----------
	-- 波数
	self:GetOwner():RefreshWaveInfo(self:GetOwner():GetBData():getCurrentWave(), totalWave)
	-- 刷新过关条件
	self:GetOwner():RefreshWaveClearInfo(self:GetOwner():GetStageCompleteInfoByWave(self:GetOwner():GetBData():getCurrentWave()))

	-- 刷新一次连携技按钮
	if 1 == self:GetOwner():GetBData():getCurrentWave() then
		self:GetOwner():InitConnectButton()
	end
	---------- view ----------
end
--[[
创建下一波的物体
--]]
function BattleShiftDriver:CreateNextWaveObjs()
	self:HandleFriendObjs()
	self:HandleEnemyObjs()

	-- 处理一次物体之间的能力增强映射关系 一定是当前波状态的物体
	self:HandleObjsAbilityRelation()
end
--[[
切波处理友军
--]]
function BattleShiftDriver:HandleFriendObjs()
	self:HandleCardFriendObjs()
end
--[[
处理卡牌友军
--]]
function BattleShiftDriver:HandleCardFriendObjs()
	local bdata = self:GetOwner():GetBData()
	local createWave = bdata:getNextWave()

	if 1 == createWave then
		self:SetCurrentTeamIndex(false, createWave)

		local friendTeamMembers = bdata:getFriendMembers(createWave)

		-- 修正一次卡牌站位
		local fixedBattlePosInfo = {}
		local sortedFormation = self:GetOwner():SortObjFormation(friendTeamMembers)
		for i,v in ipairs(sortedFormation) do
			fixedBattlePosInfo[v] = i
		end

		-- 创建卡牌obj
		local x = 0
		local y = 0
		local r = 0
		local c = 0
		local cardConf = nil

		for i, cardInfo in ipairs(friendTeamMembers) do

			local isEnemy = false

			-- 创建坐标信息
			if nil ~= cardInfo.positionId then
				-- 外部有设置卡牌的站位 使用外部的站位信息
				local positionConf = CommonUtils.GetConfig('quest', 'battlePosition', cardInfo.positionId)
				r = checkint(positionConf.coordinate[2])
				c = checkint(positionConf.coordinate[1])
			else
				-- 外部没有设置 使用默认的
				r = BattleFormation[fixedBattlePosInfo[i]].r
				c = BattleFormation[fixedBattlePosInfo[i]].c
			end

			local cellInfo = self:GetOwner():GetCellPosByRC(r, c)
			x = cellInfo.cx
			y = cellInfo.cy
			local location = ObjectLocation.New(x, y, r, c)

			-- 创建obj
			local tagInfo = bdata:getObjTagInfo(isEnemy, false)
			local o = self:GetAObjectModel(tagInfo, isEnemy, cardInfo.teamPosition, cardInfo, location)
			self:GetOwner():GetBattleRoot():addChild(o.view.viewComponent)

			-- 设置一次当前波数
			o:setObjectWave(math.max(1, createWave))
			-- 设置一次队伍序号
			o:setObjectTeamIndex(self:GetCurrentTeamIndex(isEnemy))

			---------- 判断一次物体是否需要被移除 ----------
			if o:canDie() then

				o:KillByNature()

			else

				-- 发送创建物体的事件
				self:GetOwner():SendObjEvent(ObjectEvent.OBJECT_CREATED, {tag = o:getOTag()})

			end
			---------- 判断一次物体是否需要被移除 ----------

		end
	end
end
--[[
切波处理敌军
--]]
function BattleShiftDriver:HandleEnemyObjs()
	if self:GetOwner():IsCardVSCard() then
		self:HandleCardEnemyObjs()
	else
		self:HandleMonsterEnemyObjs()
	end
end
--[[
处理卡牌敌军
--]]
function BattleShiftDriver:HandleCardEnemyObjs()	
	local bdata = self:GetOwner():GetBData()

	self:SetCurrentTeamIndex(true, bdata:getNextWave())
	local waveInfo = bdata:getEnemyMembers(bdata:getNextWave())

	-- 修正一次卡牌站位
	local fixedBattlePosInfo = {}
	local sortedFormation = self:GetOwner():SortObjFormation(waveInfo)
	for i,v in ipairs(sortedFormation) do
		fixedBattlePosInfo[v] = i
	end

	-- 创建卡牌obj
	local x = 0
	local y = 0
	local r = 0
	local c = 0
	local cardConf = nil

	for i, cardInfo in ipairs(waveInfo) do

		local isEnemy = true

		-- 创建坐标信息
		if nil ~= cardInfo.positionId then
			-- 外部有设置卡牌的站位 使用外部的站位信息
			local positionConf = CommonUtils.GetConfig('quest', 'battlePosition', cardInfo.positionId)
			r = checkint(positionConf.coordinate[2])
			c = checkint(positionConf.coordinate[1])
		else
			-- 外部没有设置 使用默认的
			r = BattleFormation[fixedBattlePosInfo[i]].r
			-- 镜像反转x
			c = self:GetOwner():GetBConf().COL - BattleFormation[fixedBattlePosInfo[i]].c
		end

		local cellInfo = self:GetOwner():GetCellPosByRC(r, c)
		x = cellInfo.cx
		y = cellInfo.cy
		local location = ObjectLocation.New(x, y, r, c)

		-- 创建obj
		local tagInfo = bdata:getObjTagInfo(isEnemy, false)
		local o = self:GetAObjectModel(tagInfo, isEnemy, cardInfo.teamPosition, cardInfo, location)
		self:GetOwner():GetBattleRoot():addChild(o.view.viewComponent)

		-- 设置一次当前波数
		o:setObjectWave(math.max(1, bdata:getNextWave()))
		-- 设置一次当前队伍序号
		o:setObjectTeamIndex(self:GetCurrentTeamIndex(isEnemy))

		---------- 判断一次物体是否需要被移除 ----------
		if o:canDie() then

			o:KillByNature()

		else

			-- 发送创建物体的事件
			self:GetOwner():SendObjEvent(ObjectEvent.OBJECT_CREATED, {tag = o:getOTag()})

		end
		---------- 判断一次物体是否需要被移除 ----------
		
	end

	bdata.nextWaveTips.hasElite = false
	bdata.nextWaveTips.hasBoss = false
end
--[[
处理怪物敌军
--]]
function BattleShiftDriver:HandleMonsterEnemyObjs()
	local bdata = self:GetOwner():GetBData()

	self:SetCurrentTeamIndex(true, bdata:getNextWave())

	local hasElite = false
	local hasBoss = false

	------------ 创建休息区中需要重返战场的怪物 ------------
	local friendObjsAmount, enemyObjsAmount, hasElite, hasBoss = self:CreateObjsFromRestZone()
	------------ 创建休息区中需要重返战场的怪物 ------------

	local x = 0
	local y = 0
	local r = 0
	local c = 0
	local oid = 0
	local oconf = nil
	local cardConf = nil
	local positionConf = nil

	local waveInfo = bdata:getEnemyMembers(bdata:getNextWave())
	if waveInfo then

		---------- 修正一次卡牌站位 ----------
		local fixedBattlePosInfo = {}
		local sortedFormation = self:GetOwner():SortObjFormation(waveInfo)
		for i,v in ipairs(sortedFormation) do
			fixedBattlePosInfo[v] = i
		end
		---------- 修正一次卡牌站位 ----------

		for i,v in ipairs(waveInfo) do

			local isEnemy = true
			if nil ~= v.campType then
				isEnemy = ConfigCampType.ENEMY == v.campType
			end

			if nil ~= v.positionId then
				-- 外部有设置卡牌的站位 使用外部的站位信息
				positionConf = CommonUtils.GetConfig('quest', 'battlePosition', v.positionId)
				r = checkint(positionConf.coordinate[2])
				c = checkint(positionConf.coordinate[1])
			else
				-- 外部没有设置 使用默认的
				assert(i <= MAX_TEAM_MEMBER_AMOUNT, '六号位 没有站位信息')
				r = BattleFormation[fixedBattlePosInfo[i]].r
				-- 镜像反转x
				c = self:GetOwner():GetBConf().COL - BattleFormation[fixedBattlePosInfo[i]].c
			end

			local cellInfo = self:GetOwner():GetCellPosByRC(r, c)
			x = cellInfo.cx
			y = cellInfo.cy
			local location = ObjectLocation.New(x, y, r, c)

			-- 创建obj
			local tagInfo = bdata:getObjTagInfo(isEnemy, false)
			local o = self:GetAObjectModel(tagInfo, isEnemy, enemyObjsAmount + i, v, location)
			self:GetOwner():GetBattleRoot():addChild(o.view.viewComponent)

			-- 设置一次当前波数
			o:setObjectWave(math.max(1, bdata:getNextWave()))
			-- 设置一次当前队伍序号
			o:setObjectTeamIndex(self:GetCurrentTeamIndex(isEnemy))

			---------- 判断一次物体是否需要被移除 ----------
			if o:canDie() then

				o:KillByNature()

			else

				-- 发送创建物体的事件
				self:GetOwner():SendObjEvent(ObjectEvent.OBJECT_CREATED, {tag = o:getOTag()})

				-- 如果下一波有精英或者boss 做一次记录
				local objectMonsterType = checkint(o:getObjectConfig().type)
				if ConfigMonsterType.ELITE == objectMonsterType then
					hasElite = true
				elseif ConfigMonsterType.BOSS == objectMonsterType then
					hasBoss = true
				end

			end
			---------- 判断一次物体是否需要被移除 ----------

		end

		bdata.nextWaveTips.hasElite = hasElite
		bdata.nextWaveTips.hasBoss = hasBoss
	end
end
--[[
从休息区创建重返战场的怪物
--]]
function BattleShiftDriver:CreateObjsFromRestZone()
	local bdata = self:GetOwner():GetBData()

	local friendObjsAmount = 0
	local enemyObjsAmount = 0
	local hasElite = false
	local hasBoss = false
	local obj = nil
	for i = #bdata.sortRestObjs, 1, -1 do
		obj = bdata.sortRestObjs[i]
		-- 判断是否是逃跑后需要重返战场的怪物
		if bdata:getCurrentWave() == obj.appearWaveAfterEscape then
			obj:appearFromEscape()
			obj:enterNextWave(bdata:getNextWave())

			-- 加入逻辑池
			bdata:addABattleObj(obj)
			bdata:removeAObjFromRest(obj)

			-- 设置一次当前波数
			obj:setObjectWave(math.max(1, bdata:getNextWave()))
			-- 设置一次当前队伍序号
			obj:setObjectTeamIndex(self:GetCurrentTeamIndex(obj:isEnemy(true)))

			if true == obj:isEnemy() then
				enemyObjsAmount = enemyObjsAmount + 1
				-- 如果下一波有精英或者boss 做一次记录
				if ConfigMonsterType.ELITE == checkint(obj:getObjectConfig().type) then
					hasElite = true
				elseif ConfigMonsterType.BOSS == checkint(obj:getObjectConfig().type) then
					hasBoss = true
				end
			else
				friendObjsAmount = friendObjsAmount + 1
			end
		end
	end

	return friendObjsAmount, enemyObjsAmount, hasElite, hasBoss
end
--[[
根据构造器的物体构造数据创建一个战斗物体
@params tagInfo ObjectTagStruct 物体tag信息
@params isEnemy bool 是否是敌人
@params teamPosition int 队伍中的位置序号
@params cardInfo CardObjConstructorStruct
@params location ObjectLocation 战斗物体位置数据
@return obj CardObjectModel 战斗物体模型
--]]
function BattleShiftDriver:GetAObjectModel(tagInfo, isEnemy, teamPosition, cardInfo, location)
	if CardUtils.IsMonsterCard(cardInfo.cardId or cardInfo.monsterId) then
		return self:GetAMonsterObjectModel(tagInfo, isEnemy, teamPosition, cardInfo, location)
	else
		return self:GetACardObjectModel(tagInfo, isEnemy, teamPosition, cardInfo, location)
	end
end
--[[
根据卡牌构造数据创建一个卡牌战斗物体
@params tagInfo ObjectTagStruct 物体tag信息
@params isEnemy bool 是否是敌人
@params teamPosition int 队伍中的位置序号
@params cardInfo CardObjConstructorStruct
@params location ObjectLocation 战斗物体位置数据
@return obj CardObjectModel 战斗物体模型
--]]
function BattleShiftDriver:GetACardObjectModel(tagInfo, isEnemy, teamPosition, cardInfo, location)
	local objectId = checkint(cardInfo.cardId)
	local objectConfig = CardUtils.GetCardConfig(objectId)

	-- 外部属性参数
	local formationPropAttr = nil
	if isEnemy then
		formationPropAttr = self:GetOwner():GetBData():getBattleConstructData().friendFormation.propertyAttr
	else
		formationPropAttr = self:GetOwner():GetBData():getBattleConstructData().enemyFormation.propertyAttr
	end

	-- 创建物体属性信息
	local objProperty = __Require('battle.object.ObjProperty').new(CardPropertyConstructStruct.New(
		objectId,
		cardInfo.level,
		cardInfo.breakLevel,
		cardInfo.favorLevel,
		cardInfo.petData,
		cardInfo.talentData,
		cardInfo.objpattr,
		formationPropAttr,
		location
	))

	local objFeature = BattleUtils.GetObjFeatureByCareer(checkint(objectConfig.career))

	-- 创建物体info数据
	local objInfo = ObjectConstructorStruct.New(
		objectId, location, teamPosition, objFeature, checkint(objectConfig.career), isEnemy,
		objProperty, cardInfo.skillData, cardInfo.talentData, cardInfo.exAbilityData, cardInfo.isLeader, cardInfo.recordDeltaHp,
		cardInfo.skinId, 1, checkint(objectConfig.defaultLayer or 0),
		self:GetOwner():GetPhaseChangeDataByNpcId(objectId)
	)

	-- 创建物体
	local obj = self:GetOwner():GetABattleObj(objInfo, tagInfo)

	return obj
end
--[[
根据怪物数据构造一个怪物战斗物体
@params tagInfo ObjectTagStruct 物体tag信息
@params isEnemy bool 是否是敌人
@params teamPosition int 队伍中的位置序号
@params cardInfo CardObjConstructorStruct
@params location ObjectLocation 战斗物体位置数据
@return obj CardObjectModel 战斗物体模型
--]]
function BattleShiftDriver:GetAMonsterObjectModel(tagInfo, isEnemy, teamPosition, cardInfo, location)
	local objectId = checkint(cardInfo.monsterId)
	local objectConfig = CardUtils.GetCardConfig(objectId)

	-- 外部属性参数
	local formationPropAttr = nil
	if isEnemy then
		formationPropAttr = self:GetOwner():GetBData():getBattleConstructData().friendFormation.propertyAttr
	else
		formationPropAttr = self:GetOwner():GetBData():getBattleConstructData().enemyFormation.propertyAttr
	end

	-- 创建属性信息
	local objProperty = __Require('battle.object.MonsterProperty').new(MonsterPropertyConstructStruct.New(
		objectId,
		checkint(cardInfo.level or 1),
		checknumber(cardInfo.attrGrow),
		checknumber(cardInfo.skillGrow),
		cardInfo.objpattr,
		formationPropAttr,
		location
	))

	local objFeature = BattleUtils.GetObjFeatureByCareer(checkint(objectConfig.career))

	-- 创建物体info
	local objInfo = ObjectConstructorStruct.New(
		objectId, location, teamPosition, objFeature, checkint(objectConfig.career), isEnemy,
		objProperty, nil, cardInfo.talentData, cardInfo.exAbilityData, cardInfo.isLeader, cardInfo.recordDeltaHp,
		cardInfo.skinId, checknumber(objectConfig.scale), checkint(objectConfig.defaultLayer or 0),
		self:GetOwner():GetPhaseChangeDataByNpcId(objectId)
	)

	-- 创建物体
	local obj = self:GetOwner():GetABattleObj(objInfo, tagInfo)

	return obj
end
--[[
处理物体之间能力增强的映射关系
--]]
function BattleShiftDriver:HandleObjsAbilityRelation()
	-- 初始化友军的能力增强
	local bdata = self:GetOwner():GetBData()

	local abilityInfos = bdata:getBattleConstructData().abilityRelationInfo

	if nil == abilityInfos then return end

	for _, abilityInfo in ipairs(abilityInfos) do

		if nil ~= abilityInfo and abilityInfo:AbilityVaild() then

			local meetEssential = false or BattleUtils.IsTableEmpty(abilityInfo.essentialCards)
			local meetInessential = false or BattleUtils.IsTableEmpty(abilityInfo.inessentialCards)

			local cardId = nil

			------------ 检查必要卡牌 ------------
			local essentialCards = clone(abilityInfo.essentialCards)
			local activeObjs = {}

			-- /***********************************************************************************************************************************\
			--  * 此处的循环没有使用稳定序列化 好像没有问题？
			-- \***********************************************************************************************************************************/

			for otag, obj_ in pairs(bdata.battleObjs) do
				cardId = obj_:getOCardId()

				-- 处理必要的卡牌信息
				if abilityInfo.essentialCards[tostring(cardId)] then
					essentialCards[tostring(cardId)] = nil
				end

				-- 处理非必要的卡牌信息
				if not meetInessential and abilityInfo.inessentialCards[tostring(cardId)] then
					meetInessential = true
				end

				-- 处理激活能力的卡牌信息
				if abilityInfo.activeCards[tostring(cardId)] then
					if nil == activeObjs[tostring(cardId)] then
						activeObjs[tostring(cardId)] = {}
					end
					table.insert(activeObjs[tostring(cardId)], checkint(otag))
				end
			end

			meetEssential = BattleUtils.IsTableEmpty(essentialCards)

			if meetEssential and meetInessential and not BattleUtils.IsTableEmpty(activeObjs) then

				local obj = nil

				-- 处理激活的卡牌能力
				local sk = sortByKey(activeObjs)
				local activeSkillsSortKey = sortByKey(abilityInfo.activeSkills)

				for _, cardId_ in ipairs(sk) do
					local activeObjsByCardId = activeObjs[cardId_]

					for _, otag_ in ipairs(activeObjsByCardId) do
						obj = bdata.battleObjs[tostring(otag_)]

						if nil ~= obj then

							-- 插入技能
							for _, activeSkillId_ in ipairs(activeSkillsSortKey) do

								-- 此处写死技能等级为1
								if not obj.castDriver:HasSkillBySkillId(checkint(activeSkillId_)) then
									obj.castDriver:AddASkill(checkint(activeSkillId_), 1)
								end

							end

						end
					end
				end

			end
			------------ 检查必要卡牌 ------------

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
根据敌友性获取是否存在下一波阵容
@params isEnemy bool 敌友性
@return _ bool 是否存在下一波阵容
--]]
function BattleShiftDriver:HasNextTeam(isEnemy)
	return false
end
--[[
获取当前队伍序号
@params isEnemy bool isEnemy
--]]
function BattleShiftDriver:GetCurrentTeamIndex(isEnemy)
	if isEnemy then
		return self.currentTeamIndex.enemy
	else
		return self.currentTeamIndex.friend
	end
end
function BattleShiftDriver:SetCurrentTeamIndex(isEnemy, index)
	if isEnemy then
		self.currentTeamIndex.enemy = index
	else
		self.currentTeamIndex.friend = index
	end
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return BattleShiftDriver

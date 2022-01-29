--[[
战斗切波驱动器
--]]
local BaseBattleDriver = __Require('battle.battleDriver.BaseBattleDriver')
local BattleShiftDriver = class('BattleShiftDriver', BaseBattleDriver)

------------ import ------------
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
	if bdata:GetNextWave() <= bdata:GetStageTotalWave() then
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
	G_BattleLogicMgr:SetBattleTouchEnable(false)

	--***---------- 刷新渲染层 ----------***--
	G_BattleLogicMgr:AddRenderOperate(
		'G_BattleRenderMgr',
		'ShowWaveTransition'
	)
	--***---------- 刷新渲染层 ----------***--
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
	local nextWave = bdata:GetNextWave()

	local objs = nil
	local obj = nil
	local otag = nil

	-- 释放这一波未做完动画的子弹
	objs = G_BattleLogicMgr:GetBulletObjs()
	for i = #objs, 1, -1 do
		obj = objs[i]
		otag = obj:GetOTag()
		bdata.battleObjs[tostring(otag)] = nil
		obj:Destroy()
	end
	bdata.sortBattleObjs.bullet = {}

	-- 刷新一次召唤物
	objs = G_BattleLogicMgr:GetAliveBeckonObjs()
	for i = #objs, 1, -1 do
		obj = objs[i]
		obj:EnterNextWave(nextWave)
	end
	bdata.sortBattleObjs.beckonObj = {}

	-- 销毁墓地中的召唤物
	objs = G_BattleLogicMgr:GetDeadBeckonObjs()
	for i = #objs, 1, -1 do
		obj = objs[i]
		otag = obj:GetOTag()
		bdata.dustObjs[tostring(otag)] = nil
		obj:Destroy()
	end
	bdata.sortDustObjs.beckonObj = {}

	-- 杀死场上存活的敌方对象
	objs = G_BattleLogicMgr:GetAliveBattleObjs(true)
	for i = #objs, 1, -1 do
		obj = objs[i]
		obj:KillByNature()
	end
	bdata.sortBattleObjs.enemy = {}

	-- 杀死场上存活的友军非卡牌物体
	objs = G_BattleLogicMgr:GetAliveBattleObjs(false)
	for i = #objs, 1, -1 do
		obj = objs[i]
		if CardUtils.IsMonsterCard(obj:GetObjectConfigId()) then
			obj:KillByNature()
		end
	end
	---------- 清理缓存对象 ----------

	-- 创建下一波
	self:GetOwner():CreateNextWave()
	-- 初始化一次光环效果
	self:GetOwner():InitHalosEffect()

	-- 重置我方站位
	objs = G_BattleLogicMgr:GetAliveBattleObjs(false)
	for i = #objs, 1, -1 do
		obj = objs[i]
		obj:EnterNextWave(nextWave)
	end

	-- 继续游戏
	--***---------- 刷新渲染层 ----------***--
	G_BattleLogicMgr:AddRenderOperate(
		'G_BattleRenderMgr',
		'ContinueWaveTransition'
	)
	--***---------- 刷新渲染层 ----------***--
end
--[[
结束切换下一波
--]]
function BattleShiftDriver:OnShiftEnd()
	self:OnShiftExit()

	-- 显示动画 准备开始下一波
	self:GetOwner():ReadyStartNextWave()
end
--[[
是否可以进入下一波
@return result bool 
--]]
function BattleShiftDriver:CanEnterNextWave(dt)
	local result = true
	local bdata = self:GetOwner():GetBData()

	local objs = nil
	local obj = nil

	-- 刷新一遍子弹
	objs = G_BattleLogicMgr:GetBulletObjs()
	for i = #objs, 1, -1 do
		obj = objs[i]
		if not obj:CanEnterNextWave() then
			result = false
			obj:Update(dt)
		else
			obj:Die()
		end
	end

	if false == result then
		return false
	end

	-- 场上存活的物体
	objs = G_BattleLogicMgr:GetAliveBattleObjs(false)
	for i = #objs, 1, -1 do
		obj = objs[i]
		if not obj:CanEnterNextWave() then
			result = false
		end
	end
	objs = G_BattleLogicMgr:GetAliveBattleObjs(true)
	for i = #objs, 1, -1 do
		obj = objs[i]
		if not obj:CanEnterNextWave() then
			result = false
		end
	end
	objs = G_BattleLogicMgr:GetAliveBeckonObjs()
	for i = #objs, 1, -1 do
		obj = objs[i]
		if not obj:CanEnterNextWave() then
			result = false
		end
	end
	-- 墓地中的物体
	objs = G_BattleLogicMgr:GetDeadBattleObjs(false)
	for i = #objs, 1, -1 do
		obj = objs[i]
		if not obj:CanEnterNextWave() then
			result = false
		end
	end
	objs = G_BattleLogicMgr:GetDeadBattleObjs(true)
	for i = #objs, 1, -1 do
		obj = objs[i]
		if not obj:CanEnterNextWave() then
			result = false
		end
	end
	-- 休息区等待重新上场的物体
	objs = G_BattleLogicMgr:GetRestObjs()
	for i = #objs, 1, -1 do
		obj = objs[i]
		if not obj:CanEnterNextWave() then
			result = false
		end
	end

	return result
end
--[[
创建下一波的敌人
--]]
function BattleShiftDriver:OnCreateNextWaveEnter()
	-- 创建物体
	self:CreateNextWaveObjs()

	-- 创建结束
	self:OnCreateNextWaveExit()
end
--[[
创建下一波敌人结束
--]]
function BattleShiftDriver:OnCreateNextWaveExit()
	---------- data ----------
	-- 重置计数器
	self:GetOwner():GetBData():SetCurrentWave(self:GetOwner():GetBData():GetNextWave())
	self:GetOwner():GetBData():SetNextWave(self:GetOwner():GetBData():GetNextWave() + 1)
	---------- data ----------

	-- 初始化一次所有连携技按钮
	if 1 == self:GetOwner():GetBData():GetCurrentWave() then
		G_BattleLogicMgr:AddRenderOperate(
			'G_BattleRenderMgr',
			'InitConnectButton',
			G_BattleLogicMgr:GetAliveBattleObjs(false)
		)
	end

	-- 刷新一次所有连携技按钮状态
	self:GetOwner():RefreshAllConnectButtons(false)

	-- 刷新一次所有物体的目标mark
	self:RefreshAllWaveTargetMark()

	--***---------- 刷新渲染层 ----------***--
	local totalWave = G_BattleLogicMgr:GetBData():GetStageTotalWave()
	local currentWave = G_BattleLogicMgr:GetBData():GetCurrentWave()
	-- 波数
	G_BattleLogicMgr:AddRenderOperate(
		'G_BattleRenderMgr',
		'RefreshWaveInfo',
		currentWave, totalWave
	)

	-- 过关条件
	G_BattleLogicMgr:AddRenderOperate(
		'G_BattleRenderMgr',
		'RefreshWaveClearInfo',
		G_BattleLogicMgr:GetStageCompleteInfoByWave(currentWave)
	)
	--***---------- 刷新渲染层 ----------***--

	-- 刷新bgm
	G_BattleLogicMgr:AddRenderOperate(
		'G_BattleRenderMgr',
		'RefreshBattleBgm',
		G_BattleLogicMgr:GetAliveBattleObjs(false)
	)
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
	local createWave = bdata:GetNextWave()

	if 1 == createWave then

		self:SetCurrentTeamIndex(false, createWave)

		local friendTeamMembers = G_BattleLogicMgr:GetBattleMembers(false, createWave)

		---------- 修正一次卡牌站位 ----------
		local fixedBattlePosInfo = {}
		local sortedFormation = self:SortObjFormation(friendTeamMembers)
		for i,v in ipairs(sortedFormation) do
			fixedBattlePosInfo[v] = i
		end
		---------- 修正一次卡牌站位 ----------

		-- 创建卡牌obj
		local x = 0
		local y = 0
		local r = 0
		local c = 0
		local cardConfig = nil

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
			local tag = bdata:GetTagByTagType(isEnemy and BattleTags.BT_CONFIG_ENEMY or BattleTags.BT_FRIEND)
			local o = self:GetAObjectModel(tag, isEnemy, cardInfo.teamPosition, cardInfo, location)

			-- 设置一次当前波数
			o:SetObjectWave(math.max(1, createWave))
			-- 设置一次队伍序号
			o:SetObjectTeamIndex(self:GetCurrentTeamIndex(isEnemy))

			---------- 判断一次物体是否需要被移除 ----------
			if o:CanDie() then

				o:KillSelf(true)

			else

				-- 发送创建物体的事件
				self:GetOwner():SendObjEvent(ObjectEvent.OBJECT_CREATED, {tag = o:GetOTag()})

				---------- skada ----------
				G_BattleLogicMgr:SkadaAddObjectTag(o:GetObjectTeamIndex(), i, tag, isEnemy)
				---------- skada ----------

				---------- view ----------
				-- 创建view
				G_BattleLogicMgr:RenderCreateAObjectView(o:GetViewModelTag(), o:GetObjInfo())
				-- 刷新view
				o:InitObjectRender()
				---------- view ----------

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
	local createWave = bdata:GetNextWave()

	self:SetCurrentTeamIndex(true, createWave)
	local waveInfo = bdata:GetEnemyMembers(createWave)

	---------- 修正一次卡牌站位 ----------
	local fixedBattlePosInfo = {}
	local sortedFormation = self:SortObjFormation(waveInfo)
	for i,v in ipairs(sortedFormation) do
		fixedBattlePosInfo[v] = i
	end
	---------- 修正一次卡牌站位 ----------

	-- 创建卡牌obj
	local x = 0
	local y = 0
	local r = 0
	local c = 0
	local cardConfig = nil

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
		local tag = bdata:GetTagByTagType(isEnemy and BattleTags.BT_CONFIG_ENEMY or BattleTags.BT_FRIEND)
		local o = self:GetAObjectModel(tag, isEnemy, cardInfo.teamPosition, cardInfo, location)

		-- 设置一次当前波数
		o:SetObjectWave(math.max(1, createWave))
		-- 设置一次队伍序号
		o:SetObjectTeamIndex(self:GetCurrentTeamIndex(isEnemy))

		---------- 判断一次物体是否需要被移除 ----------
		if o:CanDie() then

			o:KillSelf(true)

		else

			-- 发送创建物体的事件
			self:GetOwner():SendObjEvent(ObjectEvent.OBJECT_CREATED, {tag = o:GetOTag()})

			---------- skada ----------
			G_BattleLogicMgr:SkadaAddObjectTag(o:GetObjectTeamIndex(), i, tag, isEnemy)
			---------- skada ----------

			---------- view ----------
			-- 创建view
			G_BattleLogicMgr:RenderCreateAObjectView(o:GetViewModelTag(), o:GetObjInfo())
			-- 刷新view
			o:InitObjectRender()
			---------- view ----------

		end
		---------- 判断一次物体是否需要被移除 ----------

	end

	bdata:SetNextWaveHasElite(false)
	bdata:SetNextWaveHasBoss(false)
end
--[[
处理怪物敌军
--]]
function BattleShiftDriver:HandleMonsterEnemyObjs()
	local bdata = self:GetOwner():GetBData()
	local createWave = bdata:GetNextWave()

	self:SetCurrentTeamIndex(true, createWave)

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
	local cardConfig = nil
	local positionConf = nil

	local waveInfo = bdata:GetEnemyMembers(createWave)

	if waveInfo then

		---------- 修正一次卡牌站位 ----------
		local fixedBattlePosInfo = {}
		local sortedFormation = self:SortObjFormation(waveInfo)
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
			local tag = bdata:GetTagByTagType(isEnemy and BattleTags.BT_CONFIG_ENEMY or BattleTags.BT_FRIEND)
			local o = self:GetAObjectModel(tag, isEnemy, enemyObjsAmount + i, v, location)

			-- 设置一次当前波数
			o:SetObjectWave(math.max(1, createWave))
			-- 设置一次队伍序号
			o:SetObjectTeamIndex(self:GetCurrentTeamIndex(isEnemy))

			---------- 判断一次物体是否需要被移除 ----------
			if o:CanDie() then

				o:KillSelf(true)

			else

				-- 发送创建物体的事件
				self:GetOwner():SendObjEvent(ObjectEvent.OBJECT_CREATED, {tag = o:GetOTag()})

				---------- view ----------
				-- 创建view
				G_BattleLogicMgr:RenderCreateAObjectView(o:GetViewModelTag(), o:GetObjInfo())
				-- 刷新view
				o:InitObjectRender()
				---------- view ----------

				-- 如果下一波有精英或者boss 做一次记录
				local objectMonsterType = checkint(o:GetObjectConfig().type)
				if ConfigMonsterType.ELITE == objectMonsterType then
					hasElite = true
				elseif ConfigMonsterType.BOSS == objectMonsterType then
					hasBoss = true
				end

			end
			---------- 判断一次物体是否需要被移除 ----------

		end

		bdata:SetNextWaveHasElite(hasElite)
		bdata:SetNextWaveHasBoss(hasBoss)
	end
end
--[[
从休息区创建重返战场的怪物
--]]
function BattleShiftDriver:CreateObjsFromRestZone()
	local bdata = self:GetOwner():GetBData()
	local createWave = bdata:GetNextWave()

	local friendObjsAmount = 0
	local enemyObjsAmount = 0
	local hasElite = false
	local hasBoss = false
	local obj = nil

	for i = #bdata.sortRestObjs, 1, -1 do
		obj = bdata.sortRestObjs[i]

		-- 判断是否是逃跑后需要重返战场的怪物
		if createWave == obj:GetAppearWaveAfterEscape() then

			obj:AppearFromEscape()
			obj:EnterNextWave(createWave)

			-- 加入逻辑池
			bdata:AddABattleObjLogicModel(obj)
			bdata:RemoveALogicModelFromRest(obj)

			-- 设置一次当前波数
			obj:SetObjectWave(math.max(1, createWave))
			-- 设置一次队伍序号
			obj:SetObjectTeamIndex(self:GetCurrentTeamIndex(obj:IsEnemy(true)))

			if true == obj:IsEnemy() then

				enemyObjsAmount = enemyObjsAmount + 1

				-- 如果下一波有精英或者boss 做一次记录
				if ConfigMonsterType.ELITE == checkint(obj:GetObjectConfig().type) then
					hasElite = true
				elseif ConfigMonsterType.BOSS == checkint(obj:GetObjectConfig().type) then
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
@params tag int 物体tag
@params isEnemy bool 是否是敌人
@params teamPosition int 队伍中的位置序号
@params cardInfo CardObjConstructorStruct
@params location ObjectLocation 战斗物体位置数据
@return obj CardObjectModel 战斗物体模型
--]]
function BattleShiftDriver:GetAObjectModel(tag, isEnemy, teamPosition, cardInfo, location)
	if CardUtils.IsMonsterCard(cardInfo.cardId or cardInfo.monsterId) then
		return self:GetAMonsterObjectModel(tag, isEnemy, teamPosition, cardInfo, location)
	else
		return self:GetACardObjectModel(tag, isEnemy, teamPosition, cardInfo, location)
	end
end
--[[
根据卡牌构造数据创建一个卡牌战斗物体
@params tag int 物体tag
@params isEnemy bool 是否是敌人
@params teamPosition int 队伍中的位置序号
@params cardInfo CardObjConstructorStruct
@params location ObjectLocation 战斗物体位置数据
@return obj CardObjectModel 战斗物体模型
--]]
function BattleShiftDriver:GetACardObjectModel(tag, isEnemy, teamPosition, cardInfo, location)
	local objectId = checkint(cardInfo.cardId)
	local objectConfig = CardUtils.GetCardConfig(objectId)

	-- 创建物体属性信息
	local objProperty = __Require('battle.object.ObjProperty').new(CardPropertyConstructStruct.New(
		objectId,
		cardInfo.level,
		cardInfo.breakLevel,
		cardInfo.favorLevel,
		cardInfo.petData,
		cardInfo.talentData,
		cardInfo.bookData,
		cardInfo.catGeneData,
		cardInfo.objpattr,
		G_BattleLogicMgr:GetFormationPropertyAttr(isEnemy),
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
	local obj = self:GetOwner():GetABattleObj(tag, objInfo)

	return obj
end
--[[
根据怪物数据构造一个怪物战斗物体
@params tag int 物体tag
@params isEnemy bool 是否是敌人
@params teamPosition int 队伍中的位置序号
@params cardInfo CardObjConstructorStruct
@params location ObjectLocation 战斗物体位置数据
@return obj CardObjectModel 战斗物体模型
--]]
function BattleShiftDriver:GetAMonsterObjectModel(tag, isEnemy, teamPosition, cardInfo, location)
	local objectId = checkint(cardInfo.monsterId)
	local objectConfig = CardUtils.GetCardConfig(objectId)

	-- 创建属性信息
	local objProperty = __Require('battle.object.MonsterProperty').new(MonsterPropertyConstructStruct.New(
		objectId,
		checkint(cardInfo.level or 1),
		checknumber(cardInfo.attrGrow),
		checknumber(cardInfo.skillGrow),
		cardInfo.objpattr,
		G_BattleLogicMgr:GetFormationPropertyAttr(isEnemy),
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
	local obj = self:GetOwner():GetABattleObj(tag, objInfo)

	return obj
end
--[[
处理物体之间能力增强的映射关系
--]]
function BattleShiftDriver:HandleObjsAbilityRelation()
	-- 初始化友军的能力增强
	local bdata = self:GetOwner():GetBData()

	local abilityInfos = bdata:GetBattleConstructData().abilityRelationInfo

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
				cardId = obj_:GetObjectConfigId()

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
--[[
对战斗单位阵容排序
@params t table 战斗单位阵容信息
@return k table 返回按阵容站位排序的key
--]]
function BattleShiftDriver:SortObjFormation(t)
	local k = table.keys(t)

	table.sort(k, function (a, b)
		local aconf = CardUtils.GetCardConfig(t[a]:GetObjectConfigId())
		local bconf = CardUtils.GetCardConfig(t[b]:GetObjectConfigId())
		if checkint(aconf.career) == checkint(bconf.career) then
			return a < b
		else
			return checkint(aconf.career) < checkint(bconf.career)
		end
	end)

	if 1 < table.nums(k) then
		-- 对卡牌第一张卡做一次过滤 如果是坦克 插到二号位
		local no = k[1]
		local cardConf = CardUtils.GetCardConfig(t[no]:GetObjectConfigId())
		if ConfigCardCareer.TANK == checkint(cardConf.career) then
			table.remove(k, 1)
			table.insert(k, 2, no)
		end
	end

	return k
end
--[[
刷新一次所有物体的目标mark
--]]
function BattleShiftDriver:RefreshAllWaveTargetMark()
	local endDriver = G_BattleLogicMgr:GetEndDriver()

	if nil ~= endDriver then

		local completeType = endDriver:GetCompleteType()
		local friendTarget = {}
		local enemyTarget = {}

		if ConfigStageCompleteType.SLAY_ENEMY == completeType then
			friendTarget = endDriver:GetTargetsInfoByCampType(ConfigCampType.FRIEND)
			enemyTarget = endDriver:GetTargetsInfoByCampType(ConfigCampType.ENEMY)
		elseif ConfigStageCompleteType.HEAL_FRIEND == completeType then
			friendTarget = endDriver:GetTargetsInfoByCampType(ConfigCampType.FRIEND)
			enemyTarget = endDriver:GetTargetsInfoByCampType(ConfigCampType.ENEMY)
		end

		-- dump(friendTarget)
		-- dump(enemyTarget)

		-- 为目标打上mark 为非目标消去mark
		local objs = nil
		local obj = nil

		objs = G_BattleLogicMgr:GetAliveBattleObjs(false)
		for i = #objs, 1, -1 do
			obj = objs[i]
			local targetId = obj:GetObjectConfigId()
			if nil ~= friendTarget[tostring(targetId)] then
				obj:ShowStageClearTargetMark(completeType, true)
			else
				obj:HideAllStageClearTargetMark()
			end
		end

		objs = G_BattleLogicMgr:GetAliveBattleObjs(true)
		for i = #objs, 1, -1 do
			obj = objs[i]
			local targetId = obj:GetObjectConfigId()
			if nil ~= enemyTarget[tostring(targetId)] then
				obj:ShowStageClearTargetMark(completeType, true)
			else
				obj:HideAllStageClearTargetMark()
			end
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

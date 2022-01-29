--[[
车轮战切波驱动
--]]
local BattleShiftDriver = __Require('battle.battleDriver.BattleShiftDriver')
local TagMatchShiftDriver = class('TagMatchShiftDriver', BattleShiftDriver)

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
function TagMatchShiftDriver:Init()
	BattleShiftDriver.Init(self)

	self.nextTeamIndex = {
		friend = 1,
		enemy = 1
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
function TagMatchShiftDriver:CanDoLogic(dt)
	local bdata = self:GetOwner():GetBData()
	if G_BattleLogicMgr:HasNextWave() then
		return self:CanEnterNextWave(dt)
	end
	return false
end
--[[
进入下一波
--]]
function TagMatchShiftDriver:OnShiftEnter()
	self:GetOwner():SetGState(GState.READY)

	-- 屏蔽触摸
	G_BattleLogicMgr:SetBattleTouchEnable(false)

	--***---------- 刷新渲染层 ----------***--
	local isFriendWin = ValueConstants.V_NONE
	local preWave = G_BattleLogicMgr:GetBData():GetCurrentWave()
	local nextWave = preWave + 1
	local endDriver = self:GetOwner():GetEndDriver(preWave)
	if nil ~= endDriver then
		isFriendWin = endDriver:IsFriendWin()
	end
	-- 算一次存活的物体信息传给渲染层
	local aliveTargets = nil
	local deadTargets = nil
	local aliveTargetsInfo = {}
	local deadTargetsInfo = {}

	if ValueConstants.V_NORMAL == isFriendWin then

		aliveTargets = G_BattleLogicMgr:GetAliveBattleObjs(false)
		deadTargets = G_BattleLogicMgr:GetDeadBattleObjs(true)

	elseif ValueConstants.V_INFINITE == isFriendWin then

		aliveTargets = G_BattleLogicMgr:GetAliveBattleObjs(true)
		deadTargets = G_BattleLogicMgr:GetDeadBattleObjs(false)

	end

	local obj = nil
	if nil ~= aliveTargets then
		for i = #aliveTargets, 1, -1 do
			obj = aliveTargets[i]
			table.insert(aliveTargetsInfo, {
				objectSkinId = obj:GetObjectSkinId()
			})
		end
	end

	if nil ~= deadTargets then
		for i = #deadTargets, 1, -1 do
			obj = deadTargets[i]
			table.insert(deadTargetsInfo, {
				objectSkinId = obj:GetObjectSkinId()
			})
		end
	end


	G_BattleLogicMgr:AddRenderOperate(
		'G_BattleRenderMgr',
		'ShowWaveTransition',
		true, nextWave, self:GetNextTeamIndex(false), self:GetNextTeamIndex(true), isFriendWin,
		aliveTargetsInfo, deadTargetsInfo

	)
	--***---------- 刷新渲染层 ----------***--
end
--[[
开始切换下一波
--]]
function TagMatchShiftDriver:OnShiftBegin()
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

	-- 杀死场上存活的非卡牌物体
	-- objs = G_BattleLogicMgr:GetAliveBattleObjs(true)
	-- for i = #objs, 1, -1 do
	-- 	obj = objs[i]
	-- 	if CardUtils.IsMonsterCard(obj:GetObjectConfigId()) then
	-- 		obj:KillByNature()
	-- 	end
	-- end

	-- objs = G_BattleLogicMgr:GetAliveBattleObjs(false)
	-- for i = #objs, 1, -1 do
	-- 	obj = objs[i]
	-- 	if CardUtils.IsMonsterCard(obj:GetObjectConfigId()) then
	-- 		obj:KillByNature()
	-- 	end
	-- end
	---------- 清理缓存对象 ----------

	-- 创建下一波
	self:GetOwner():CreateNextWave()
	-- 初始化一次光环效果
	self:GetOwner():InitHalosEffect()

	-- 重置站位
	local preWave = bdata:GetCurrentWave() - 1
	local endDriver = self:GetOwner():GetEndDriver(preWave)
	local resetTargets = nil

	if nil ~= endDriver and nil ~= endDriver.IsFriendWin then
		if ValueConstants.V_INFINITE == endDriver:IsFriendWin() then
			resetTargets = G_BattleLogicMgr:GetAliveBattleObjs(true)
		elseif ValueConstants.V_NORMAL == endDriver:IsFriendWin() then
			resetTargets = G_BattleLogicMgr:GetAliveBattleObjs(false)
		end
	end

	if nil ~= resetTargets then
		for i = #resetTargets, 1, -1 do
			obj = resetTargets[i]
			obj:EnterNextWave(bdata:GetCurrentWave())
		end
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
function TagMatchShiftDriver:OnShiftEnd()
	BattleShiftDriver.OnShiftEnd(self)
end
--[[
@override
创建下一波的敌人
--]]
function TagMatchShiftDriver:OnCreateNextWaveEnter()
	BattleShiftDriver.OnCreateNextWaveEnter(self)
end
--[[
创建下一波敌人结束
--]]
function TagMatchShiftDriver:OnCreateNextWaveExit()
	-- 重置计数器
	self:GetOwner():GetBData():SetCurrentWave(self:GetOwner():GetBData():GetNextWave())
	self:GetOwner():GetBData():SetNextWave(self:GetOwner():GetBData():GetNextWave() + 1)

	-- 车轮战模式需要重新设置一次总波数
	self:GetOwner():GetBData():SetStageTotalWave(self:GetOwner():GetBData():GetNextWave())

	-- 新建一个下一波的过关目标
	local nextWave = self:GetOwner():GetBData():GetNextWave()
	local stageCompleteInfo = StageCompleteSturct.New()
	stageCompleteInfo.completeType = ConfigStageCompleteType.TAG_MATCH
	G_BattleLogicMgr:SetStageCompleteInfoByWave(
		nextWave,
		stageCompleteInfo
	)
	-- 新建一个过关驱动
	local endDriverClassName = 'battle.battleDriver.TagMatchEndDriver'
	local endDriver = __Require(endDriverClassName).new({
		owner = self:GetOwner(),
		wave = nextWave,
		stageCompleteInfo = stageCompleteInfo
	})
	self:GetOwner():SetEndDriver(nextWave, endDriver)

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

	-- 初始化一次所有连携技按钮
	G_BattleLogicMgr:AddRenderOperate(
		'G_BattleRenderMgr',
		'InitConnectButton',
		G_BattleLogicMgr:GetAliveBattleObjs(false)
	)

	-- 刷新一次车轮战的两侧队伍标记
	G_BattleLogicMgr:AddRenderOperate(
		'G_BattleRenderMgr',
		'RefreshTagMatchTeamStatus',
		self:GetNextTeamIndex(false) - 1, self:GetNextTeamIndex(true) - 1
	)

	-- 刷新一次所有连携技按钮状态
	G_BattleLogicMgr:RefreshAllConnectButtons(false)
	--***---------- 刷新渲染层 ----------***--

	-- 刷新bgm
	G_BattleLogicMgr:AddRenderOperate(
		'G_BattleRenderMgr',
		'RefreshBattleBgm',
		G_BattleLogicMgr:GetAliveBattleObjs(false)
	)
end
--[[
@override
切波处理友军
--]]
function TagMatchShiftDriver:HandleCardFriendObjs()
	local bdata = self:GetOwner():GetBData()
	local createWave = bdata:GetNextWave()
	local createTeamIndex = self:GetNextTeamIndex(false)
	local needCreateNextWave = false

	if 1 == createWave then
		-- 第一波 创建
		needCreateNextWave = true
	else
		---------- 检查上一波是否团灭 并且是否有下一波 ----------
		local preWave = createWave - 1
		local endDriver = self:GetOwner():GetEndDriver(preWave)

		if nil ~= endDriver and nil ~= endDriver.IsFriendWin then
			if ValueConstants.V_INFINITE == endDriver:IsFriendWin() then
				local totalTeamAmount = #G_BattleLogicMgr:GetBattleMembers(false)
				-- 团灭了 检查是否存在下一波阵容
				if createTeamIndex <= totalTeamAmount then
					needCreateNextWave = true
				end
			end
		end
		---------- 检查上一波是否团灭 并且是否有下一波 ----------
	end

	if needCreateNextWave then
		self:SetCurrentTeamIndex(false, createTeamIndex)
		-- 需要创建下一波
		local friendTeamMembers = G_BattleLogicMgr:GetBattleMembers(false, createTeamIndex)

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

		self:SetNextTeamIndex(false, self:GetNextTeamIndex(false) + 1)
	end
end
--[[
@override
处理卡牌敌军
--]]
function TagMatchShiftDriver:HandleCardEnemyObjs()
	local bdata = self:GetOwner():GetBData()
	local createWave = bdata:GetNextWave()
	local createTeamIndex = self:GetNextTeamIndex(true)
	local needCreateNextWave = false

	if 1 == createWave then
		-- 第一波 创建
		needCreateNextWave = true
	else
		---------- 检查上一波是否团灭 并且是否有下一波 ----------
		local preWave = createWave - 1
		local endDriver = self:GetOwner():GetEndDriver(preWave)

		if nil ~= endDriver and nil ~= endDriver.IsFriendWin then
			if ValueConstants.V_NORMAL == endDriver:IsFriendWin() then
				local totalTeamAmount = #G_BattleLogicMgr:GetBattleMembers(true)
				-- 团灭了 检查是否存在下一波阵容
				if createTeamIndex <= totalTeamAmount then
					needCreateNextWave = true
				end
			end
		end
		---------- 检查上一波是否团灭 并且是否有下一波 ----------
	end

	if needCreateNextWave then 
		self:SetCurrentTeamIndex(true, createTeamIndex)
		-- 需要创建下一波
		local enemyTeamMembers = G_BattleLogicMgr:GetBattleMembers(true, createTeamIndex)

		---------- 修正一次卡牌站位 ----------
		local fixedBattlePosInfo = {}
		local sortedFormation = self:SortObjFormation(enemyTeamMembers)
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

		for i, cardInfo in ipairs(enemyTeamMembers) do

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

		self:SetNextTeamIndex(true, self:GetNextTeamIndex(true) + 1)

	end
end
--[[
@override
处理怪物敌军
--]]
function TagMatchShiftDriver:HandleMonsterEnemyObjs()
	local bdata = self:GetOwner():GetBData()
	local createWave = bdata:GetNextWave()
	local createTeamIndex = self:GetNextTeamIndex(true)
	local needCreateNextWave = false

	if 1 == createWave then
		-- 第一波 创建
		needCreateNextWave = true
	else
		---------- 检查上一波是否团灭 并且是否有下一波 ----------
		local preWave = createWave - 1
		local endDriver = self:GetOwner():GetEndDriver(preWave)

		if nil ~= endDriver and nil ~= endDriver.IsFriendWin then
			if ValueConstants.V_NORMAL == endDriver:IsFriendWin() then
				local totalTeamAmount = #G_BattleLogicMgr:GetBattleMembers(true)
				-- 团灭了 检查是否存在下一波阵容
				if createTeamIndex <= totalTeamAmount then
					needCreateNextWave = true
				end
			end
		end
		---------- 检查上一波是否团灭 并且是否有下一波 ----------
	end

	if needCreateNextWave then

		self:SetCurrentTeamIndex(true, createTeamIndex)
		-- 需要创建下一波

		local hasElite = false
		local hasBoss = false

		------------ 创建休息区中需要重返战场的怪物 ------------
		local friendObjsAmount, enemyObjsAmount, hasElite, hasBoss = self:CreateObjsFromRestZone()
		------------ 创建休息区中需要重返战场的怪物 ------------

		local enemyTeamMembers = G_BattleLogicMgr:GetBattleMembers(true, createTeamIndex)

		---------- 修正一次卡牌站位 ----------
		local fixedBattlePosInfo = {}
		local sortedFormation = self:SortObjFormation(enemyTeamMembers)
		for i,v in ipairs(sortedFormation) do
			fixedBattlePosInfo[v] = i
		end
		---------- 修正一次卡牌站位 ----------

		for i, monsterInfo in ipairs(enemyTeamMembers) do

			local isEnemy = true
			if nil ~= monsterInfo.campType then
				isEnemy = ConfigCampType.ENEMY == monsterInfo.campType
			end

			if nil ~= monsterInfo.positionId then
				-- 外部有设置卡牌的站位 使用外部的站位信息
				positionConf = CommonUtils.GetConfig('quest', 'battlePosition', monsterInfo.positionId)
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
			local o = self:GetAObjectModel(tag, isEnemy, enemyObjsAmount + i, monsterInfo, location)

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

		self:SetNextTeamIndex(true, self:GetNextTeamIndex(true) + 1)

	end

end
---------------------------------------------------
-- control logic end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
下队编号
@params isEnemy bool isEnemy
--]]
function TagMatchShiftDriver:GetNextTeamIndex(isEnemy)
	if isEnemy then
		return self.nextTeamIndex.enemy
	else
		return self.nextTeamIndex.friend
	end
end
function TagMatchShiftDriver:SetNextTeamIndex(isEnemy, value)
	if isEnemy then
		self.nextTeamIndex.enemy = value
	else
		self.nextTeamIndex.friend = value
	end
end
--[[
根据敌友性获取是否存在下一波阵容
@params isEnemy bool 敌友性
@return _ bool 是否存在下一波阵容
--]]
function TagMatchShiftDriver:HasNextTeam(isEnemy)
	local nextTeamIndex = self:GetNextTeamIndex(isEnemy)
	local totalTeamAmount = 0
	if isEnemy then
		totalTeamAmount = #G_BattleLogicMgr:GetBattleMembers(true)
	else
		totalTeamAmount = #G_BattleLogicMgr:GetBattleMembers(false)
	end
	return nextTeamIndex <= totalTeamAmount
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return TagMatchShiftDriver

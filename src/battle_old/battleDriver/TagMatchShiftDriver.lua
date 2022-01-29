--[[
车轮战切波驱动
--]]
local BattleShiftDriver = __Require('battle.battleDriver.BattleShiftDriver')
local TagMatchShiftDriver = class('TagMatchShiftDriver', BattleShiftDriver)

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
	if self:GetOwner():HasNextWave() then
		return self:CanEnterNextWave(dt)
	end
	return false
end
--[[
开始切换下一波
--]]
function TagMatchShiftDriver:OnShiftBegin()
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

	-- 杀死场上存活的非卡牌物体
	-- for i = #bdata.sortBattleObjs.enemy, 1, -1 do
	-- 	obj = bdata.sortBattleObjs.enemy[i]
	-- 	if CardUtils.IsMonsterCard(obj:getOCardId()) then
	-- 		obj:KillByNature()
	-- 	end
	-- end

	-- for i = #bdata.sortBattleObjs.friend, 1, -1 do
	-- 	obj = bdata.sortBattleObjs.friend[i]
	-- 	if CardUtils.IsMonsterCard(obj:getOCardId()) then
	-- 		obj:KillByNature()
	-- 	end
	-- end
	---------- 清理缓存对象 ----------

	-- 创建下一波
	self:GetOwner():CreateNextWave()
	-- 初始化一次光环效果
	self:GetOwner():InitHalosEffect()

	-- 重置站位
	local preWave = bdata:getCurrentWave() - 1
	local endDriver = self:GetOwner():GetEndDriver(preWave)
	local resetTargets = nil

	if nil ~= endDriver and nil ~= endDriver.IsFriendWin then
		if ValueConstants.V_INFINITE == endDriver:IsFriendWin() then
			resetTargets = bdata.sortBattleObjs.enemy
		elseif ValueConstants.V_NORMAL == endDriver:IsFriendWin() then
			resetTargets = bdata.sortBattleObjs.friend
		end
	end

	if nil ~= resetTargets then
		for i = #resetTargets, 1, -1 do
			obj = resetTargets[i]
			obj:enterNextWave(bdata:getCurrentWave())
		end
	end
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
	---------- data ----------
	-- 创建物体
	self:CreateNextWaveObjs()

	-- 重置计数器
	self:GetOwner():GetBData():setCurrentWave(self:GetOwner():GetBData():getNextWave())
	self:GetOwner():GetBData():setNextWave(self:GetOwner():GetBData():getNextWave() + 1)

	-- 车轮战模式需要重新设置一次总波数
	self:GetOwner():GetBData():setStageTotalWave(self:GetOwner():GetBData():getNextWave())
	
	-- 新建一个下一波的过关目标
	local nextWave = self:GetOwner():GetBData():getNextWave()
	local stageCompleteInfo = StageCompleteSturct.New()
	stageCompleteInfo.completeType = ConfigStageCompleteType.TAG_MATCH
	self:GetOwner():SetStageCompleteInfoByWave(
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
	---------- data ----------

	local totalWave = self:GetOwner():GetBData():getStageTotalWave()

	---------- view ----------
	-- 波数
	self:GetOwner():RefreshWaveInfo(self:GetOwner():GetBData():getCurrentWave(), totalWave)
	-- 刷新过关条件
	self:GetOwner():RefreshWaveClearInfo(self:GetOwner():GetStageCompleteInfoByWave(self:GetOwner():GetBData():getCurrentWave()))
	-- 刷新当前队伍状态
	self:GetOwner():GetViewComponent():RefreshTagMatchTeamStatus(
		self:GetNextTeamIndex(false) - 1,
		self:GetNextTeamIndex(true) - 1
	)
	-- 刷新一次连携技按钮
	self:GetOwner():InitConnectButton()
	---------- view ----------
end
--[[
@override
创建下一波的物体
--]]
function TagMatchShiftDriver:CreateNextWaveObjs()
	self:HandleObjResources()
	BattleShiftDriver.CreateNextWaveObjs(self)
end
--[[
切波时处理一次卡牌spine资源加载和卸载
--]]
function TagMatchShiftDriver:HandleObjResources()
	local nextWave = self:GetOwner():GetBData():getNextWave()
	if 1 < nextWave then
		self:GetOwner():GetBattleDriver(BattleDriverType.RES_LOADER):OnLogicEnter(
			nextWave, self:GetNextTeamIndex(false), self:GetNextTeamIndex(true)
		)
	end
end
--[[
@override
切波处理友军
--]]
function TagMatchShiftDriver:HandleCardFriendObjs()
	local bdata = self:GetOwner():GetBData()
	local createWave = bdata:getNextWave()
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
				local totalTeamAmount = #bdata:getFriendMembers()
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
		local friendTeamMembers = bdata:getFriendMembers(createTeamIndex)

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
			-- 设置一次当前队伍序号
			o:setObjectTeamIndex(self:GetCurrentTeamIndex(false))

			---------- 判断一次物体是否需要被移除 ----------
			if o:canDie() then

				o:KillByNature()

			else

				-- 发送创建物体的事件
				self:GetOwner():SendObjEvent(ObjectEvent.OBJECT_CREATED, {tag = o:getOTag()})

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
	local createWave = bdata:getNextWave()
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
				local totalTeamAmount = #bdata:getEnemyMembers()
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
		local enemyTeamMembers = bdata:getEnemyMembers(createTeamIndex)

		-- 修正一次卡牌站位
		local fixedBattlePosInfo = {}
		local sortedFormation = self:GetOwner():SortObjFormation(enemyTeamMembers)
		for i,v in ipairs(sortedFormation) do
			fixedBattlePosInfo[v] = i
		end

		-- 创建卡牌obj
		local x = 0
		local y = 0
		local r = 0
		local c = 0
		local cardConf = nil

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
			local tagInfo = bdata:getObjTagInfo(isEnemy, false)
			local o = self:GetAObjectModel(tagInfo, isEnemy, cardInfo.teamPosition, cardInfo, location)
			self:GetOwner():GetBattleRoot():addChild(o.view.viewComponent)

			-- 设置一次当前波数
			o:setObjectWave(math.max(1, createWave))
			-- 设置一次当前队伍序号
			o:setObjectTeamIndex(self:GetCurrentTeamIndex(true))

			---------- 判断一次物体是否需要被移除 ----------
			if o:canDie() then

				o:KillByNature()

			else

				-- 发送创建物体的事件
				self:GetOwner():SendObjEvent(ObjectEvent.OBJECT_CREATED, {tag = o:getOTag()})

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
		totalTeamAmount = #self:GetOwner():GetBData():getEnemyMembers()
	else
		totalTeamAmount = #self:GetOwner():GetBData():getFriendMembers()
	end
	return nextTeamIndex <= totalTeamAmount
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return TagMatchShiftDriver

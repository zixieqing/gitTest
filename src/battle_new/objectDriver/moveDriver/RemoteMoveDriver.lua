--[[
远程移动行为驱动
--]]
local BaseMoveDriver = __Require('battle.objectDriver.moveDriver.BaseMoveDriver')
local RemoteMoveDriver = class('RemoteMoveDriver', BaseMoveDriver)

---------------------------------------------------
-- override begin --
---------------------------------------------------
--[[
移动实现
@params dt number delta time
--]]
function RemoteMoveDriver:Move(dt, targetTag)
	if sp.AnimationName.run ~= self:GetOwner():GetCurrentAnimationName() then
		self:GetOwner():DoAnimation(true, nil, sp.AnimationName.run, true)

		--***---------- 插入刷新渲染层计时器 ----------***--
		self:GetOwner():RefreshRenderAnimation(
			true, nil, sp.AnimationName.run, true
		)
		--***---------- 插入刷新渲染层计时器 ----------***--
	end

	local target = G_BattleLogicMgr:IsObjAliveByTag(targetTag)
	local targetPos = target:GetLocation().po
	local targetRC = target:GetLocation().rc
	local ownerPos = self:GetOwner():GetLocation().po

	local deltaPos = cc.pSub(targetPos, ownerPos)

	-- 附加一个攻击距离修正值 移动目标物体在物体右侧时为负
	local sign = 1
	-- TODO ### 转身逻辑 可能会导致左右晃动的问题 ### --
	if 0 < deltaPos.x then

		sign = -1
		self:GetOwner():SetOrientation(BattleObjTowards.FORWARD)

	elseif deltaPos.x < 0 then

		self:GetOwner():SetOrientation(BattleObjTowards.NEGATIVE)

	end

	-- 计算移动量
	local attackRangeFixedX = sign * (self:GetOwner():GetMainProperty().p.attackRange * G_BattleLogicMgr:GetCellSize().width - 1)

	if math.abs(attackRangeFixedX) > math.abs(deltaPos.x) then
		-- 如果攻击距离修正距离比当前两物体间距离大 则保持x不移动
		attackRangeFixedX = ownerPos.x - targetPos.x
	end

	local fixedTargetPos = cc.p(
		G_BattleLogicMgr:GetCellPosByRC(targetRC.r, targetRC.c).cx + attackRangeFixedX,
		ownerPos.y
	)

	local distance = cc.pGetDistance(fixedTargetPos, ownerPos)
	local t = distance / self:GetOwner():GetMoveSpeed()
	local finalPos = cc.p(0, 0)

	local exitMove = false

	if t <= dt then
		finalPos = fixedTargetPos
		exitMove = true
	else
		finalPos = cc.pAdd(
			ownerPos,
			cc.pMul(cc.pSub(fixedTargetPos, ownerPos), dt / t)
		)
	end

	-- 改变物体坐标
	self:GetOwner():ChangePosition(finalPos)

	--***---------- 插入刷新渲染层计时器 ----------***--
	-- 刷新渲染层朝向
	self:GetOwner():RefreshRenderViewTowards()
	-- 刷新渲染层坐标
	self:GetOwner():RefreshRenderViewPosition()
	--***---------- 插入刷新渲染层计时器 ----------***--

	---------- 判断是否需要结束移动 ----------
	if exitMove then
		self:OnActionExit()
	end
	---------- 判断是否需要结束移动 ----------
end
---------------------------------------------------
-- override end --
---------------------------------------------------

return RemoteMoveDriver

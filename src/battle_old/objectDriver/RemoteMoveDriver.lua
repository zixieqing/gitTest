--[[
远程移动行为驱动
--]]
local BaseMoveDriver = __Require('battle.objectDriver.BaseMoveDriver')
local RemoteMoveDriver = class('RemoteMoveDriver', BaseMoveDriver)

---------------------------------------------------
-- override begin --
---------------------------------------------------
--[[
移动实现
@params dt number delta time
--]]
function RemoteMoveDriver:Move(dt, targetTag)
	if sp.AnimationName.run ~= self:GetOwner():GetCurrentSpineAnimationName() then
		self:GetOwner():DoSpineAnimation(true, nil, sp.AnimationName.run, true)
	end
	
	local target = BMediator:IsObjAliveByTag(targetTag)
	-- 移动
	local targetPos = target:getLocation().po
	local targetRC = target:getLocation().rc
	local ownerPos = self:GetOwner():getLocation().po
	local deltaPos = cc.pSub(targetPos, ownerPos)
	-- 附加一个攻击距离修正值 移动目标物体在物体右侧时为负
	local sign = 1
	-- TODO ### 转身逻辑 可能会导致左右晃动的问题 ### --
	if deltaPos.x > 0 then
		sign = -1
		self:GetOwner():changeOrientation(true)
	elseif deltaPos.x < 0 then
		self:GetOwner():changeOrientation(false)
	end

	-- 计算移动量
	local attackRangeFixedX = sign * (self:GetOwner():getMainProperty().p.attackRange * BMediator:GetBConf().cellSize.width - 1)
	if math.abs(attackRangeFixedX) > math.abs(deltaPos.x) then
		-- 如果攻击距离修正距离比当前两物体间距离大 则保持x不移动
		attackRangeFixedX = ownerPos.x - targetPos.x
	end
	local fixedTargetPos = cc.p(
		BMediator:GetCellPosByRC(targetRC.r, targetRC.c).cx + attackRangeFixedX,
		ownerPos.y
	)
	local distance = cc.pGetDistance(fixedTargetPos, ownerPos)
	local t = distance / self:GetOwner():getMainProperty().p.walkSpeed
	if t <= dt then
		self:GetOwner().view.viewComponent:setPosition(fixedTargetPos)
		self:OnActionExit()
	else
		self:GetOwner().view.viewComponent:setPosition(cc.pAdd(ownerPos,
			cc.pMul(cc.pSub(fixedTargetPos, ownerPos), dt / t)))
	end
	self:GetOwner():updateLocation()
end
---------------------------------------------------
-- override end --
---------------------------------------------------

return RemoteMoveDriver

--[[
移动驱动基类
@params table {
	oriLocation ObjectLocation 原始站位
}
--]]
local BaseActionDriver = __Require('battle.objectDriver.BaseActionDriver')
local BaseMoveDriver = class('BaseMoveDriver', BaseActionDriver)
--[[
constructor
--]]
function BaseMoveDriver:ctor( ... )
	BaseActionDriver.ctor(self, ...)

	self:Init()
end
---------------------------------------------------
-- init logic begin --
---------------------------------------------------
--[[
初始化逻辑
--]]
function BaseMoveDriver:Init()
	self.moveTargetTag = nil
	self.moveTarget = nil
	self.moveBackPos = nil
	self.moveTowardsY = 0
	self.escaping = false

	---------- 强制移动 ----------
	self.moveForceTargetPos = nil
	self.moveForceActionName = nil
	self.moveForceOverCallback = nil
	---------- 强制移动 ----------

	self:InitStanceOff()
end
--[[
初始化y轴站位间隔
--]]
function BaseMoveDriver:InitStanceOff()
	self.stanceOffY = 0
	local row = self:GetOwner().objInfo.oriLocation.rc.r
	self:SetStanceOffY(row - (math.ceil(BMediator:GetBConf().ROW * 0.5)))
end
---------------------------------------------------
-- init logic end --
---------------------------------------------------

---------------------------------------------------
-- control logic begin --
---------------------------------------------------
--[[
是否能进行动作
--]]
function BaseMoveDriver:CanDoAction(targetTag)

end
--[[
进入动作
@params targetTag int 目标物体tag
--]]
function BaseMoveDriver:OnActionEnter(targetTag)
	---------- logic ----------
	self:GetOwner():setState(OState.MOVING)

	self:SetMoveTargetTag(targetTag)

	-- 设置基础朝向
	local target = BMediator:IsObjAliveByTag(targetTag)
	if nil ~= target then
		local deltaPos = cc.pSub(target:getLocation().po, self:GetOwner():getLocation().po)
		if deltaPos.y > 0 then
			self:SetMoveTowardsY(BattleObjTowards.FORWARD)
		elseif deltaPos.y < 0 then
			self:SetMoveTowardsY(BattleObjTowards.NEGATIVE)
		elseif deltaPos.y == 0 then
			-- 如果在同一行 需要进行一些处理
			-- 首先预测target的移动方向
			local targetTowards = target.moveDriver:GetMoveTowardsY()
			if BattleObjTowards.BASE == targetTowards then
				-- 如果目标朝向为0 随机一个朝向
				local upper = 10
				local randomTowards = BMediator:GetRandomManager():GetRandomInt(upper)
				if randomTowards < upper * 0.5 then
					self:SetMoveTowardsY(BattleObjTowards.NEGATIVE)
				else
					self:SetMoveTowardsY(BattleObjTowards.FORWARD)
				end
			else
				-- 不为0 跟随目标的朝向
				self:SetMoveTowardsY(targetTowards)
			end
		end
	end
	---------- logic ----------

	---------- view ----------
	if sp.AnimationName.run ~= self:GetOwner():GetCurrentSpineAnimationName() then
		self:GetOwner():DoSpineAnimation(true, nil, sp.AnimationName.run, true)
	end
	---------- view ----------
end
--[[
结束动作
--]]
function BaseMoveDriver:OnActionExit()
	self:GetOwner():setState(self:GetOwner():getState(-1))
	self:GetOwner():setState(OState.NORMAL, -1)

	self.moveTargetTag = nil
	if sp.AnimationName.run == self:GetOwner():GetCurrentSpineAnimationName() then
		self:GetOwner():DoSpineAnimation(true, nil, sp.AnimationName.idle, true)
	end
end
--[[
动作被打断
--]]
function BaseMoveDriver:OnActionBreak()
	self:GetOwner():setState(self:GetOwner():getState(-1))
	self:GetOwner():setState(OState.NORMAL, -1)
end
--[[
动作进行中
@params dt number delta time
@params targetTag int 移动目标对象tag
--]]
function BaseMoveDriver:OnActionUpdate(dt, targetTag)
	if nil == BMediator:IsObjAliveByTag(targetTag) then
		self:OnActionExit()
	else
		self:Move(dt, targetTag)
	end
end
--[[
移动实现
@params dt number delta time
@params targetTag int 目标tag
--]]
function BaseMoveDriver:Move(dt, targetTag)
	if sp.AnimationName.run ~= self:GetOwner():GetCurrentSpineAnimationName() then
		self:GetOwner():DoSpineAnimation(true, nil, sp.AnimationName.run, true)
	end
	
	local target = BMediator:IsObjAliveByTag(targetTag)
	-- 移动
	local targetPos = target:getLocation().po
	local targetCollisionBox = target:getStaticCollisionBox()

	local ownerPos = self:GetOwner():getLocation().po
	local ownerCollisionBox = nil

	-- 移动目标点
	local destinationPos = cc.p(
		0,
		0
	)
	local deltaPos = cc.pSub(targetPos, ownerPos)

	---------- 计算最终点 y轴 ----------
	local stanceOffYSelf = self:GetStanceOffY()
	local stanceOffYTarget = target.moveDriver:GetStanceOffY()

	destinationPos.y = targetPos.y + (stanceOffYSelf - stanceOffYTarget) * BMediator:GetBConf().cellSize.height * MELEE_STANCE_OFF_Y
	---------- 计算最终点 y轴 ----------

	---------- 计算最终点 x轴 ----------
	-- 附加一个攻击距离修正值 移动目标物体在物体右侧时为负
	-- TODO ### 转身逻辑 可能会导致左右晃动的问题 ### --
	if deltaPos.x > 0 then
		-- 目标在右侧
		self:GetOwner():changeOrientation(true)
		-- 计算理论目的地横坐标 碰撞框边界加上攻击距离
		destinationPos.x = targetPos.x + targetCollisionBox.x - (self:GetOwner():getMainProperty().p.attackRange * BMediator:GetBConf().cellSize.width - 1)

		-- 如果已经处于攻击距离范围内 则x轴不再移动
		ownerCollisionBox = self:GetOwner():getStaticCollisionBox()
		if ownerPos.x + ownerCollisionBox.x + ownerCollisionBox.width > destinationPos.x then
			destinationPos.x = ownerPos.x
		end
	-- elseif deltaPos.x < 0 then
	else
		-- 目标在左侧
		self:GetOwner():changeOrientation(false)
		-- 计算理论目的地横坐标 碰撞框边界加上攻击距离
		destinationPos.x = targetPos.x + targetCollisionBox.x + targetCollisionBox.width + (self:GetOwner():getMainProperty().p.attackRange * BMediator:GetBConf().cellSize.width - 1)

		-- 如果已经处于攻击距离范围内 则x轴不再移动
		ownerCollisionBox = self:GetOwner():getStaticCollisionBox()
		if ownerPos.x + ownerCollisionBox.x < destinationPos.x then
			destinationPos.x = ownerPos.x
		end
	end
	---------- 计算最终点 x轴 ----------

	---------- 根据时间修正最终位置 ----------
	local distance = cc.pGetDistance(destinationPos, ownerPos)
	local t = distance / self:GetOwner():getMainProperty().p.walkSpeed
	local finalPos = cc.p(0, 0)
	if t <= dt then
		finalPos = destinationPos
	else
		finalPos = cc.pAdd(
			ownerPos,
			cc.pMul(cc.pSub(destinationPos, ownerPos), dt / t))
	end
	self:GetOwner().view.viewComponent:setPosition(finalPos)
	self:GetOwner():updateLocation()
	---------- 根据时间修正最终位置 ----------

	-- 判断是否需要结束移动
	local distanceJudge = self:GetOwner().attackDriver:CanAttackByDistance(targetTag) 
	local targetJudge = (nil ~= target.attackDriver:GetAttackTargetTag() and self:GetOwner():getOTag() == target.attackDriver:GetAttackTargetTag())
	if distanceJudge and (targetJudge or OState.MOVING ~= target:getState()) then
		self:OnActionExit()
	end
end
--[[
开始走回战场
@params targetPos cc.p 目标位置
--]]
function BaseMoveDriver:OnMoveBackEnter(targetPos)
	self:GetOwner():setState(OState.MOVE_BACK)
	self.moveBackPos = targetPos
end
--[[
返回战场
@params dt number delta time
--]]
function BaseMoveDriver:OnMoveBackUpdate(dt)
	local ownerPos = self:GetOwner():getLocation().po
	local distance = cc.pGetDistance(self.moveBackPos, ownerPos)
	local t = distance / self:GetOwner():getMainProperty().p.walkSpeed
	if t <= dt then
		self:GetOwner().view.viewComponent:setPosition(self.moveBackPos)
		self:OnMoveBackExit()
	else
		self:GetOwner().view.viewComponent:setPosition(cc.pAdd(ownerPos,
			cc.pMul(cc.pSub(self.moveBackPos, ownerPos), dt / t)))
	end
	self:GetOwner():updateLocation()
end
--[[
走回战场结束
@params targetPos cc.p 目标位置
--]]
function BaseMoveDriver:OnMoveBackExit()
	self:GetOwner():setState(OState.NORMAL)
	self.moveBackPos = nil
end
--[[
开始逃跑
@params targetPos cc.p 目标位置
--]]
function BaseMoveDriver:OnEscapeEnter(targetPos)
	self:GetOwner().view.viewComponent:escape()

	local ownerPos = self:GetOwner():getLocation().po

	self:GetOwner():DoSpineAnimation(true, 2, sp.AnimationName.run, true)

	-- 更新朝向
	local sign = cc.pSub(targetPos, ownerPos).x > 0
	self:GetOwner():changeOrientation(sign)

	local distance = cc.pGetDistance(targetPos, ownerPos)
	local t = distance / (self:GetOwner():getMainProperty().p.walkSpeed * 2)
	local actionSeq = cc.Sequence:create(
		cc.MoveTo:create(t, targetPos),
		cc.CallFunc:create(function ()
			self:GetOwner().view.viewComponent:escapeDisappear()
			self.escaping = false
			self:GetOwnerAvatar():clearTracks()
		end)
	)
	self:GetOwner().view.viewComponent:runAction(actionSeq)
end
--[[
逃跑结束 重返战场
--]]
function BaseMoveDriver:OnEscapeExit()
	self:GetOwner().view.viewComponent:escapeAppear()
end
--[[
设置移动朝向 纵向
@params towards BattleObjTowards 纵轴朝向
--]]
function BaseMoveDriver:SetMoveTowardsY(towards)
	self.moveTowardsY = towards
end
--[[
获取移动朝向 纵向
@return _ BattleObjTowards 纵轴朝向
--]]
function BaseMoveDriver:GetMoveTowardsY()
	return self.moveTowardsY
end
--[[
获取站位分隔单位
--]]
function BaseMoveDriver:GetStanceOffY()
	return self.stanceOffY
end
function BaseMoveDriver:SetStanceOffY(stanceOffY)
	self.stanceOffY = stanceOffY
end
--[[
获取修正后的站位间隔 纵向
@params target obj 目标物体
@return stanceOff number 站位间隔
--]]
function BaseMoveDriver:GetFixedStanceOffY(target)
	return self.stanceOffY * BMediator:GetBConf().cellSize.height * MELEE_STANCE_OFF_Y
end
--[[
开始强制移动
@params targetPos cc.p 目标位置
@params moveActionName string 移动动作名
@params moveOverCallback function 移动结束回调
--]]
function BaseMoveDriver:OnMoveForceEnter(targetPos, moveActionName, moveOverCallback)
	if OState.MOVE_FORCE == self:GetOwner():getState() then
		self:OnMoveForceBreak()
	end

	self:GetOwner():setState(OState.MOVE_FORCE)

	self.moveForceTargetPos = targetPos
	self.moveForceActionName = moveActionName or sp.AnimationName.run
	self.moveForceOverCallback = moveOverCallback

	---------- view ----------
	if self.moveForceActionName ~= self:GetOwner():GetCurrentSpineAnimationName() then
		self:GetOwner():DoSpineAnimation(true, nil, self.moveForceActionName, true)
	end
	---------- view ----------
end
--[[
强制移动进行中
--]]
function BaseMoveDriver:OnMoveForceUpdate(dt)
	local ownerPos = self:GetOwner():getLocation().po
	local targetPos = self.moveForceTargetPos
	local distance = cc.pGetDistance(targetPos, ownerPos)
	local t = distance / self:GetOwner():getMainProperty().p.walkSpeed

	-- 刷新朝向
	local deltaPos = cc.pSub(targetPos, ownerPos)
	self:GetOwner():changeOrientation(0 < deltaPos.x)

	if t <= dt then
		self:GetOwner().view.viewComponent:setPosition(targetPos)
		self:OnMoveForceExit()
	else
		self:GetOwner().view.viewComponent:setPosition(cc.pAdd(ownerPos,
			cc.pMul(cc.pSub(targetPos, ownerPos), dt / t)))
	end
	self:GetOwner():updateLocation()
end
--[[
强制移动结束
--]]
function BaseMoveDriver:OnMoveForceExit()
	self.moveBackPos = nil

	if self.moveForceActionName == self:GetOwner():GetCurrentSpineAnimationName() then
		self:GetOwner():DoSpineAnimation(true, nil, sp.AnimationName.idle, true)
	end
	self.moveForceActionName = nil
	
	if nil ~= self.moveForceOverCallback then
		self.moveForceOverCallback()
	else
		self:GetOwner():setState(OState.NORMAL)
	end
	self.moveForceOverCallback = nil
end
--[[
强制移动被打断
--]]
function BaseMoveDriver:OnMoveForceBreak()
	self.moveForceTargetPos = nil
	self.moveForceActionName = nil
	self.moveForceOverCallback = nil
end
---------------------------------------------------
-- control logic end --
---------------------------------------------------

---------------------------------------------------
-- handler logic begin --
---------------------------------------------------
--[[
spine动画事件消息处理
--]]
function BaseMoveDriver:SpineAnimationEventHandler(event)

end
--[[
spine动画自定义事件消息处理
--]]
function BaseMoveDriver:SpineCustomEventHandler(event)

end
---------------------------------------------------
-- handler logic end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
移动对象
--]]
function BaseMoveDriver:SetMoveTargetTag(targetTag)
	self.moveTargetTag = targetTag
end
function BaseMoveDriver:GetMoveTargetTag()
	return self.moveTargetTag
end
---------------------------------------------------
-- get set begin --
---------------------------------------------------

return BaseMoveDriver


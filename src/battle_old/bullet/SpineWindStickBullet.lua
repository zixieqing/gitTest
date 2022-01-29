--[[
回旋镖类型子弹 回旋镖类型固定两段伤害
--]]
local SpineUFOBullet = __Require('battle.bullet.SpineUFOBullet')
local SpineWindStickBullet = class('SpineWindStickBullet', SpineUFOBullet)
local WindStickState = {
	GO 			= 1, -- 去
	STOP		= 2, -- 第一次达到最远距离
	BACK 		= 3, -- 回
	OVER 		= 4  -- 结束
}
--[[
初始化伤害标识符
--]]
function SpineWindStickBullet:initValue()
	SpineUFOBullet.initValue(self)
	-- 两段伤害标识符
	self.causedDamage = {
		[WindStickState.GO] = false,
		[WindStickState.STOP] = false,
		[WindStickState.BACK] = false,
		[WindStickState.OVER] = false
	}
	-- 初始化目标碰撞框
	self.p.targetCollisionBox = cc.rect(0, 0, 0, 0)
	-- 开始回旋的起点
	self.fixedStopPoint = nil

	local target = BMediator:IsObjAliveByTag(self.aTargetTag)
	if nil ~= target then
		self.p.targetCollisionBox = target:getCollisionBoxInWorldSpace()
	end
end
--[[
@override
--]]
function SpineWindStickBullet:initView()
	SpineUFOBullet.initView(self)
	self.collisionBox = self:getCollisionBoxInWorldSpace()
end
--[[
@override
战斗行为 碰撞到造成伤害 没碰撞到跑路
@params dt number delta time
--]]
function SpineWindStickBullet:autoController(dt)
	-- print('new bullet attack ready -> ', self.aTargetTag, self.ownerTag)
	-- 回到目标手中再杀死
	if true == self:isAllSpineAnimationOver() then
		self:die()
		return
	else
		self:move(self.aTargetTag, dt)
		if self:canAttack(self.aTargetTag, dt) then
			self.causedDamage[self:getWindStickCurrentState()] = true
			-- 分段计数器累加
			self.phaseCounter = self.phaseCounter + 1
			self:attack(self.aTargetTag, 0.5, self.phaseCounter)
		end
	end
end
--[[
@override
是否能攻击
@params targetTag int 攻击对象tag
@params dt number 时间差
@return result bool 结果
--]]
function SpineWindStickBullet:canAttack(targetTag, dt)
	-- 获取当前朝向
	local currentTowards = self:getWindStickCurrentState()
	if true == self.causedDamage[currentTowards] then
		-- 若当前朝向已经造成过伤害 屏蔽伤害 继续移动
		return false
	else
		local selfCollisionBox = self:getCollisionBoxInWorldSpace()

		if ConfigEffectCauseType.SINGLE == self.op.causeType then

			---------- 连线中点类型 与连线中点做碰撞 ----------
			if true == cc.rectContainsPoint(
				selfCollisionBox,
				self.view.viewComponent:getParent():convertToWorldSpace(self.p.targetLocation)
			) then

				return true

			end
			---------- 连线中点类型 与连线中点做碰撞 ----------

		else

			---------- 指向 与obj做碰撞 ----------
			if true == cc.rectContainsPoint(
				selfCollisionBox,
				cc.p(self.p.targetCollisionBox.x + self.p.targetCollisionBox.width * 0.5, self.p.targetCollisionBox.y + self.p.targetCollisionBox.height * 0.5)
			) then

				return true

			end
			---------- 指向 与obj做碰撞 ----------

		end

		return false

	end
end
--[[
@override
跑路行为
@params targetTag int 攻击对象tag
@params dt number delta time
--]]
function SpineWindStickBullet:move(targetTag, dt)
	-- 刷新目标位置
	local target = BMediator:IsObjAliveByTag(targetTag)
	-- print('<<<<< check target alive --> ', nil == target)
	if nil ~= target then
		self.targetCollisionBox = target:getCollisionBoxInWorldSpace()
		self.p.targetLocation = cc.pAdd(
			target.view.viewComponent:getParent():convertToNodeSpace(cc.p(self.targetCollisionBox.x, self.targetCollisionBox.y)),
			cc.p(self.targetCollisionBox.width * 0.5, self.targetCollisionBox.height * 0.5)
		)
	end
	-- 刷新施法者位置
	-- local owner = BMediator:IsObjAliveByTag(self.ownerTag)
	-- if nil ~= owner then
	-- 	self.p.oriLocation = owner:getLocation().po
	-- 	local boneData = owner:findBoneInWorldSpace(sp.CustomName.BULLET_BONE_NAME)
	-- 	if boneData then
	-- 		self.p.oriLocation = owner.view.viewComponent:getParent():convertToNodeSpace(cc.p(boneData.worldPosition.x, boneData.worldPosition.y))
	-- 	end
	-- end

	local towardsSign = cc.pSub(self.p.targetLocation, self.p.oriLocation).x > 0 and 1 or -1

	---------- 控制移动 ----------

	-- 控制轨迹 计算修正后的最终点
	local currentTowards = self:getWindStickCurrentState()
	if WindStickState.GO == currentTowards then

		-- 去
		local vectorOwner2Target = cc.pSub(self.p.targetLocation, self.p.oriLocation)
		-- 修正后的最终点按照向量方向增加1个回旋镖的宽度
		local fixedStopPoint = cc.p(
			self.p.targetLocation.x + towardsSign * 1.25 * self.collisionBox.width,
			self.p.targetLocation.y + towardsSign * (vectorOwner2Target.y / vectorOwner2Target.x * 1.25 * self.collisionBox.width)
		)

		-- 如果移动值小于一定值 直接移动到位
		local deltaP = cc.pSub(fixedStopPoint, self:getLocation().po)
		local totalP = cc.pSub(fixedStopPoint, self.p.oriLocation)
		if (deltaP.x * deltaP.x + deltaP.y * deltaP.y) <= (0.0004 * (totalP.x * totalP.x + totalP.y * totalP.y)) then
			self.view.viewComponent:setPosition(fixedStopPoint)
			-- 置达到最远距离标识符为true
			self.causedDamage[WindStickState.STOP] = true
			self.fixedStopPoint = fixedStopPoint
		else
			self.view.viewComponent:setPosition(cc.pLerp(self:getLocation().po, fixedStopPoint, math.min(1, 0.135 * BMediator:GetTimeScale())))
		end

		self:updateLocation()

	elseif WindStickState.BACK == currentTowards then

		-- 回
		-- 如果移动值小于一定值 直接移动到位
		local deltaP = cc.pSub(self.p.oriLocation, self:getLocation().po)
		local totalP = cc.pSub(self.p.oriLocation, self.fixedStopPoint)
		if (deltaP.x * deltaP.x + deltaP.y * deltaP.y) <= (0.0004 * (totalP.x * totalP.x + totalP.y * totalP.y)) then
			self.view.viewComponent:setPosition(self.p.oriLocation)
			self.causedDamage[WindStickState.OVER] = true
		else
			self.view.viewComponent:setPosition(cc.pLerp(self:getLocation().po, self.p.oriLocation, math.min(1, 0.135 * BMediator:GetTimeScale())))
		end

		self:updateLocation()

	end
	---------- 控制移动 ----------

end
--[[
攻击行为
@params targetTag int 攻击对象 tag
@params percent number 分段百分比
@params phaseCounter int 分段计数
--]]
function SpineWindStickBullet:attack(targetTag, percent, phaseCounter)
	-- 如果外部传入处理函数 则走外部函数 否则默认走扣血函数
	if self.causeEffectCallback then
		self.causeEffectCallback(percent, phaseCounter)
	else
		local target = BMediator:IsObjAliveByTag(targetTag)
		if nil == target then return end

		local damageData = clone(self.op.damageData)
		damageData.damage = damageData.damage * percent

		target:beAttacked(damageData)

		-- 显示被击特效
		target:showHurtEffect(self.hurtEffectData)
	end

	if true == self.shouldShakeWorld then
		BMediator:GetViewComponent():ShakeWorld()
	end
end
--[[
获得回旋镖当前的运动状态
@return _ WindStickState 朝向 去或者回
--]]
function SpineWindStickBullet:getWindStickCurrentState()
	if true == self.causedDamage[WindStickState.BACK] or true == self.causedDamage[WindStickState.STOP] then
		return WindStickState.BACK
	else
		return WindStickState.GO
	end
end
--[[
动画是否结束
@return _ bool 动画是否结束
--]]
function SpineWindStickBullet:isAllSpineAnimationOver()
	return self.causedDamage[WindStickState.OVER]
end
--[[
@override
是否能进入下一波
@return result bool
--]]
function SpineWindStickBullet:canEnterNextWave()
	if false == self:isAllSpineAnimationOver() then
		return false
	else
		return true
	end
end
--[[
回旋镖类型不修正旋转
@params oriPos cc.p 原始坐标
@params targetPos cc.p 目标坐标
--]]
function SpineWindStickBullet:fixRotate(oriPos, targetPos)

end

return SpineWindStickBullet

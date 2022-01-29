--[[
回旋镖投掷物子弹
@params {
	objinfo ObjectSendBulletData 子弹的构造数据
}
--]]
local BaseSpineBulletModel = __Require('battle.object.logicModel.bulletModel.BaseSpineBulletModel')
local SpineWindStickBulletModel = class('SpineWindStickBulletModel', BaseSpineBulletModel)

------------ import ------------
------------ import ------------

------------ define ------------
local WindStickState = {
	GO 			= 1, -- 去
	STOP		= 2, -- 第一次达到最远距离
	BACK 		= 3, -- 回
	OVER 		= 4  -- 结束
}
------------ define ------------

--[[
constructor
--]]
function SpineWindStickBulletModel:ctor( ... )
	BaseSpineBulletModel.ctor(self, ...)
end

---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
初始化特有属性
--]]
function SpineWindStickBulletModel:InitUnitProperty()
	BaseSpineBulletModel.InitUnitProperty(self)

	-- 伤害标识符
	self.causedDamage = {
		[WindStickState.GO] 		= false,
		[WindStickState.STOP] 		= false,
		[WindStickState.BACK] 		= false,
		[WindStickState.OVER] 		= false
	}

	-- 开始回旋的起点
	self.fixedStopPoint = nil

	-- 初始化一次目标位置
	self.targetLocation = cc.p(
		self:GetObjInfo().targetLocation.x,
		self:GetObjInfo().targetLocation.y
	)

	-- 目标碰撞框
	self.targetCollisionBox = cc.rect(0, 0, 0, 0)
	local target = self:GetAttackTarget()
	if nil ~= target then
		self.targetCollisionBox = target:GetStaticCollisionBox()
	end

end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- event handler begin --
---------------------------------------------------
--[[
注册展示层的事件处理回调
--]]
function SpineWindStickBulletModel:RegistViewModelEventHandler()
	-- 该类型不注册spine事件
end
---------------------------------------------------
-- event handler end --
---------------------------------------------------

---------------------------------------------------
-- logic begin --
---------------------------------------------------
--[[
自动行为逻辑
--]]
function SpineWindStickBulletModel:AutoController(dt)
	-- 状态判断
	if OState.BATTLE == self:GetState() then

		if self:IsAllAnimationOver() then

			-- 杀死自己
			self:Die()
			return

		else

			-- 先进行一次移动
			self:Move(self:GetAttackTargetTag(), dt)

			-- 判断攻击
			if self:CanAttack(self:GetAttackTargetTag()) then
				-- 分段计数器增加
				self:SetPhaseCounter(self:GetPhaseCounter() + 1)
				-- 设置伤害状态
				self:SetCausedDamage(self:GetCurrentTowardsState(), true)
				-- 造成效果 来回都会吃到一次伤害 每次的倍率为0.5
				self:Attack(self:GetAttackTargetTag(), 0.5, self:GetPhaseCounter())
			end

		end

	end
end
---------------------------------------------------
-- logic end --
---------------------------------------------------

---------------------------------------------------
-- attack begin --
---------------------------------------------------
--[[
@override
是否能攻击
@params targetTag int 攻击对象tag
@params dt number delta time
@return _ bool
--]]
function SpineWindStickBulletModel:CanAttack(targetTag, dt)
	local currentTowardsState = self:GetCurrentTowardsState()
	if true == self:GetCausedDamage(currentTowardsState) then

		-- 若当前朝向已经造成过伤害 屏蔽伤害 继续移动
		return false

	else

		local selfCollisionBoxInBattleRoot = self:GetStaticCollisionBoxInBattleRoot()

		if ConfigEffectCauseType.SINGLE == self:GetBulletCauseType() then

			---------- 连线中点类型 与连线中点做碰撞 ----------
			local collisionJudge = cc.rectContainsPoint(
				selfCollisionBoxInBattleRoot,
				self:GetTargetLocation()
			)
			if true == collisionJudge then
				return true
			end
			---------- 连线中点类型 与连线中点做碰撞 ----------

		elseif ConfigEffectCauseType.POINT == self:GetBulletCauseType() then

			---------- 指向 与obj做碰撞 ----------
			local targetCollisionBoxInBattleRoot = self:GetTargetStaticCollisionBoxInBattleRoot()
			local centerPos = cc.p(
				targetCollisionBoxInBattleRoot.x + targetCollisionBoxInBattleRoot.width * 0.5,
				targetCollisionBoxInBattleRoot.y + targetCollisionBoxInBattleRoot.height * 0.5
			)
			local collisionJudge = cc.rectContainsPoint(
				selfCollisionBoxInBattleRoot,
				centerPos
			)
			if true == collisionJudge then
				return true
			end
			---------- 指向 与obj做碰撞 ----------

		end

		return false

	end
end
---------------------------------------------------
-- attack end --
---------------------------------------------------

---------------------------------------------------
-- move begin --
---------------------------------------------------
--[[
刷新一次目标位置
--]]
function SpineWindStickBulletModel:UpdateTargetTransform()
	local target = self:GetAttackTarget()
	if nil ~= target then
		self:SetTargetLocation(target:GetLocation().po)
	end
end
--[[
移动逻辑
@params 
--]]
function SpineWindStickBulletModel:Move(targetTag, dt)
	self:UpdateTargetTransform()

	local windStickTowards = self:GetWindStickTowards()
	local towardsSign = BattleObjTowards.NEGTIVE == windStickTowards and -1 or 1

	local currentTowardsState = self:GetCurrentTowardsState()
	local oriLocation = self:GetOriLocation()
	local targetLocation = self:GetTargetLocation()
	local targetCollisionBoxInBattleRoot = self:GetTargetStaticCollisionBoxInBattleRoot()
	local targetCenter = cc.p(
		targetCollisionBoxInBattleRoot.x + targetCollisionBoxInBattleRoot.width * 0.5,
		targetCollisionBoxInBattleRoot.y + targetCollisionBoxInBattleRoot.height * 0.5
	)
	local selfCollisionBox = self:GetStaticCollisionBox()

	if WindStickState.GO == currentTowardsState then

		-- 去的状态
		local vectorOri2Target = cc.pSub(targetCenter, oriLocation)

		-- 修正后的最终点按照向量方向增加1个回旋镖的宽度
		local fixedStopPointX = targetCenter.x + towardsSign * 1.25 * selfCollisionBox.width
		local fixedStopPointY = targetCenter.y + towardsSign * 1.25 * (vectorOri2Target.y / vectorOri2Target.x * selfCollisionBox.width)

		local fixedStopPoint = cc.p(fixedStopPointX, fixedStopPointY)

		local deltaP = cc.pSub(fixedStopPoint, self:GetLocation().po)
		local totalP = cc.pSub(fixedStopPoint, oriLocation)

		if (deltaP.x * deltaP.x + deltaP.y * deltaP.y) <= (0.0004 * (totalP.x * totalP.x + totalP.y * totalP.y)) then

			-- 如果移动值小于一定值 直接移动到位
			self:ChangePosition(fixedStopPoint)
			-- 记录一次回旋起点
			self:SetFixedStopPoint(fixedStopPoint)
			-- 变换一次状态
			self:SetCausedDamage(WindStickState.STOP, true)

		else

			-- 还有一定距离 插值移动
			local lerpAlpha = math.min(1, 0.135)-- * G_BattleLogicMgr:GetCurrentTimeScale())
			local finalPos = cc.pLerp(
				self:GetLocation().po,
				fixedStopPoint,
				lerpAlpha
			)

			self:ChangePosition(finalPos)

		end

		--***---------- 刷新渲染层 ----------***--
		self:RefreshRenderViewPosition()
		--***---------- 刷新渲染层 ----------***--

	elseif WindStickState.BACK == currentTowardsState then

		-- 回的状态
		local deltaP = cc.pSub(oriLocation, self:GetLocation().po)
		local totalP = cc.pSub(oriLocation, self:GetFixedStopPoint())

		if (deltaP.x * deltaP.x + deltaP.y * deltaP.y) <= (0.0004 * (totalP.x * totalP.x + totalP.y * totalP.y)) then

			-- 如果移动值小于一定值 直接移动到位
			self:ChangePosition(oriLocation)
			-- 变换一次状态
			self:SetCausedDamage(WindStickState.OVER, true)

		else

			-- 还有一定距离 插值移动
			local lerpAlpha = math.min(1, 0.135)-- * G_BattleLogicMgr:GetCurrentTimeScale())
			local finalPos = cc.pLerp(
				self:GetLocation().po,
				oriLocation,
				lerpAlpha
			)

			self:ChangePosition(finalPos)

		end

		--***---------- 刷新渲染层 ----------***--
		self:RefreshRenderViewPosition()
		--***---------- 刷新渲染层 ----------***--

	end

end
--[[
获取朝向
@return _ BattleObjTowards 朝向
--]]
function SpineWindStickBulletModel:GetWindStickTowards()
	return self:GetTargetLocation().x - self:GetOriLocation().x < 0 and BattleObjTowards.NEGTIVE or BattleObjTowards.FORWARD
end
---------------------------------------------------
-- move end --
---------------------------------------------------

---------------------------------------------------
-- transform begin --
---------------------------------------------------
--[[
@override
修正一次初始的transform
--]]
function SpineWindStickBulletModel:FixBulletOriTransform()
	-- 修正初始的位置
	self:FixBulletOriLocation()
end
--[[
@override
修正一次子弹的初始位置
--]]
function SpineWindStickBulletModel:FixBulletOriLocation()
	-- 回旋镖类型始终是在battle root下的坐标
	self:ChangePosition(self:GetOriLocation())

	local zorder = BATTLE_E_ZORDER.BULLET
	if self:GetObjInfo().needHighlight then
		zorder = zorder + G_BattleLogicMgr:GetFixedHighlightZOrder()
	end
	-- 设置zorder
	self:SetZOrder(zorder)

	--***---------- 刷新渲染层 ----------***--
	self:RefreshRenderViewPosition()
	--***---------- 刷新渲染层 ----------***--
end
---------------------------------------------------
-- transform end --
---------------------------------------------------

---------------------------------------------------
-- animation control begin --
---------------------------------------------------
--[[
开始做子弹的spine动画
--]]
function SpineWindStickBulletModel:StartDoBulletAnimation()
	self:DoAnimation(
		true, nil,
		self:GetBulletActionAnimationName(), true
	)

	--***---------- 刷新渲染层 ----------***--
	self:RefreshRenderAnimation(
		true, nil,
		self:GetBulletActionAnimationName(), true
	)
	--***---------- 刷新渲染层 ----------***--
end
---------------------------------------------------
-- animation control end --
---------------------------------------------------

---------------------------------------------------
-- state logic begin --
---------------------------------------------------
--[[
所有动作是否完成
@return _ bool 
--]]
function SpineWindStickBulletModel:IsAllAnimationOver()
	return true == self:GetCausedDamage(WindStickState.OVER)
end
---------------------------------------------------
-- state logic end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
根据回旋镖状态类型获取回旋镖状态
@params windStickStateType WindStickState
@return _ bool 
--]]
function SpineWindStickBulletModel:GetCausedDamage(windStickStateType)
	return self.causedDamage[windStickStateType]
end
function SpineWindStickBulletModel:SetCausedDamage(windStickStateType, caused)
	self.causedDamage[windStickStateType] = caused or false
end
--[[
获取当前回旋镖的朝向状态
@return _ WindStickState
--]]
function SpineWindStickBulletModel:GetCurrentTowardsState()
	if true == self:GetCausedDamage(WindStickState.BACK) or true == self:GetCausedDamage(WindStickState.STOP) then
		return WindStickState.BACK
	else
		return WindStickState.GO
	end
end
--[[
回旋镖开始回旋的坐标
--]]
function SpineWindStickBulletModel:SetFixedStopPoint(pos)
	self.fixedStopPoint = pos
end
function SpineWindStickBulletModel:GetFixedStopPoint()
	return self.fixedStopPoint
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

---------------------------------------------------
-- collision begin --
---------------------------------------------------
--[[
获取原始位置
--]]
function SpineWindStickBulletModel:GetOriLocation()
	return self:GetObjInfo().oriLocation
end
--[[
获取目标location
@return _ cc.p
--]]
function SpineWindStickBulletModel:GetTargetLocation()
	return self.targetLocation
end
function SpineWindStickBulletModel:SetTargetLocation(location)
	self.targetLocation.x = location.x
	self.targetLocation.y = location.y
end
--[[
获取目标的碰撞框信息
@return _ cc.rect
--]]
function SpineWindStickBulletModel:GetTargetStaticCollisionBox()
	return self.targetCollisionBox
end
--[[
获取目标相对 battle root 的碰撞框信息
@return _ cc.rect
--]]
function SpineWindStickBulletModel:GetTargetStaticCollisionBoxInBattleRoot()
	local targetCollisionBox = self:GetTargetStaticCollisionBox()
	local targetCollisionBoxInBattleRoot = cc.rect(
		self:GetTargetLocation().x + targetCollisionBox.x,
		self:GetTargetLocation().y + targetCollisionBox.y,
		targetCollisionBox.width,
		targetCollisionBox.height
	)
	return targetCollisionBoxInBattleRoot
end
---------------------------------------------------
-- collision end --
---------------------------------------------------

return SpineWindStickBulletModel

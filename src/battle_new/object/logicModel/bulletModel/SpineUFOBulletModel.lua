--[[
spine直线投掷物子弹
@params {
	objinfo ObjectSendBulletData 子弹的构造数据
}
--]]
local BaseSpineBulletModel = __Require('battle.object.logicModel.bulletModel.BaseSpineBulletModel')
local SpineUFOBulletModel = class('SpineUFOBulletModel', BaseSpineBulletModel)

------------ import ------------
------------ import ------------

------------ define ------------
------------ define ------------

--[[
constructor
--]]
function SpineUFOBulletModel:ctor( ... )
	BaseSpineBulletModel.ctor(self, ...)
end

---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
初始化特有属性
--]]
function SpineUFOBulletModel:InitUnitProperty()
	BaseSpineBulletModel.InitUnitProperty(self)

	-- 是否已经造成过伤害
	self.causedDamage = false

	-- 初始化一次目标碰撞框 这里只计算静态碰撞框 只在这里记录一次
	self.targetCollisionBox = cc.rect(0, 0, 0, 0)
	local target = self:GetAttackTarget()
	if nil ~= target then
		self.targetCollisionBox = target:GetStaticCollisionBox()
	end

	-- 初始化一次目标位置
	self.targetLocation = cc.p(
		self:GetObjInfo().targetLocation.x,
		self:GetObjInfo().targetLocation.y
	)

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
function SpineUFOBulletModel:RegistViewModelEventHandler()
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
function SpineUFOBulletModel:AutoController(dt)
	-- 状态判断
	if OState.BATTLE == self:GetState() then

		-- 该类型不再update中处理是否能造成效果 由碰撞产生效果
		if self:IsAllAnimationOver() then
			-- 杀死自己
			self:Die()
			return
		else
			-- 动画未结束 判断一次攻击
			if true == self:CanAttack(self:GetAttackTargetTag(), dt) then
				-- 分段计数器增加
				self:SetPhaseCounter(self:GetPhaseCounter() + 1)

				-- 造成效果
				self:Attack(self:GetAttackTargetTag(), 1, self:GetPhaseCounter())
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
function SpineUFOBulletModel:CanAttack(targetTag, dt)
	if self:GetCausedDamage() then return false end

	self:UpdateTargetTransform()

	local selfCollisionBoxInBattleRoot = self:GetStaticCollisionBoxInBattleRoot()
	local targetCollisionBoxInBattleRoot = self:GetTargetStaticCollisionBoxInBattleRoot()

	if cc.rectIntersectsRect(selfCollisionBoxInBattleRoot, targetCollisionBoxInBattleRoot) then
		return true
	else
		-- 碰撞未满足 刷新一次运行轨迹
		self:Move(dt)
		return false
	end

end
--[[
刷新一次目标位置
--]]
function SpineUFOBulletModel:UpdateTargetTransform()
	local target = self:GetAttackTarget()
	if nil ~= target then
		self:SetTargetLocation(target:GetLocation().po)
	end
end
--[[
@override
攻击
@params targetTag int 攻击对象 tag
@params percent number 分段百分比
@params phaseCounter int 分段计数
--]]
function SpineUFOBulletModel:Attack(targetTag, percent, phaseCounter)
	self:SetCausedDamage(true)

	BaseSpineBulletModel.Attack(self, targetTag, percent, phaseCounter)

	self:AttackEnd()
end
--[[
@override
攻击结束
--]]
function SpineUFOBulletModel:AttackEnd()
	-- 判断是否存在xxx_end动作 如果存在在原本的动作上增加end动作 end动作中的事件不处理
	local endAnimationName = self:GetBulletEndAnimationName()

	if nil ~= endAnimationName then
		-- 判断展示层是否存在该动画
		if self:GetViewModel():HasAnimationByName(endAnimationName) then

			self:DoAnimation(
				true, nil,
				endAnimationName, false
			)

			--***---------- 刷新渲染层 ----------***--
			self:RefreshRenderAnimation(
				true, nil,
				endAnimationName, false
			)
			--***---------- 刷新渲染层 ----------***--

			return

		end
	end

	-- 如果不存在 xxx_end动作 直接销毁子弹
	self:Die()
end
--[[
运动轨迹
@params dt number delta time
--]]
function SpineUFOBulletModel:Move(dt)
	local targetCBInBattleRoot = self:GetTargetStaticCollisionBoxInBattleRoot()
	local centerPos = cc.p(
		targetCBInBattleRoot.x + targetCBInBattleRoot.width * 0.5,
		targetCBInBattleRoot.y + targetCBInBattleRoot.height * 0.5
	)

	-- 插值计算一个数
	local lerpAlpha = math.min(1, 0.2)-- * G_BattleLogicMgr:GetCurrentTimeScale())
	local finalPos = cc.pLerp(
		self:GetLocation().po,
		centerPos,
		lerpAlpha
	)
	self:ChangePosition(finalPos)

	--***---------- 刷新渲染层 ----------***--
	self:RefreshRenderViewPosition()
	--***---------- 刷新渲染层 ----------***--
end
---------------------------------------------------
-- attack end --
---------------------------------------------------

---------------------------------------------------
-- animation control begin --
---------------------------------------------------
--[[
开始做子弹的spine动画
--]]
function SpineUFOBulletModel:StartDoBulletAnimation()
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
-- transform begin --
---------------------------------------------------
--[[
@override
刷新一次逻辑物体的坐标信息
--]]
function SpineUFOBulletModel:UpdateLocation()
	BaseSpineBulletModel.UpdateLocation(self)

	-- 更新zorder
	------------ 真实zorder逻辑 ------------
	-- local zorder = G_BattleLogicMgr:GetObjZOrderInBattle(
	-- 	self:GetLocation().po, false, self:GetObjInfo().needHighlight
	-- )
	------------ 真实zorder逻辑 ------------

	------------ 置顶zorder逻辑 ------------
	local zorder = BATTLE_E_ZORDER.BULLET
	if self:GetObjInfo().needHighlight then
		zorder = zorder + G_BattleLogicMgr:GetFixedHighlightZOrder()
	end
	------------ 置顶zorder逻辑 ------------

	self:SetZOrder(zorder)
end
--[[
获取旋转
@override
--]]
function SpineUFOBulletModel:GetRotate()
	return self:GetViewModel():GetRotate()
end
--[[
设置旋转
@override
--]]
function SpineUFOBulletModel:SetRotate(angle)
	self:GetViewModel():SetRotate(angle)
end
--[[
@override
修正一次初始的transform
--]]
function SpineUFOBulletModel:FixBulletOriTransform()
	-- 修正初始的位置
	self:FixBulletOriLocation()

	-- 修正初始的动画速率
	self:FixBulletOriAnimationTimeScale()

	-- 修正初始的旋转
	self:FixBulletOriRotate()
end
--[[
修正一次子弹的初始位置
--]]
function SpineUFOBulletModel:FixBulletOriLocation()
	-- 设置位置
	local oriLocation = self:GetObjInfo().oriLocation
	self:ChangePosition(oriLocation)

	-- 朝向
	local deltaX = self:GetTargetLocation().x - oriLocation.x
	if 0 > deltaX then
		self:SetOrientation(BattleObjTowards.NEGTIVE)
	else
		self:SetOrientation(BattleObjTowards.FORWARD)
	end

	-- 设置zorder zorder在update location中自动更新

	--***---------- 刷新渲染层 ----------***--
	self:RefreshRenderViewPosition()
	self:RefreshRenderViewTowards()
	--***---------- 刷新渲染层 ----------***--
end
--[[
修正初始的动画速率
--]]
function SpineUFOBulletModel:FixBulletOriAnimationTimeScale()

end
--[[
修正初始的旋转
--]]
function SpineUFOBulletModel:FixBulletOriRotate()
	self:FixRotate(self:GetObjInfo().oriLocation, self:GetTargetLocation())
end
--[[
修正旋转
@params oriPos cc.p 原始坐标
@params targetPos cc.p 目标坐标
--]]
function SpineUFOBulletModel:FixRotate(oriPos, targetPos)
	local deltaVector = cc.pSub(targetPos, oriPos)
	local angle = math.deg(math.atan(math.abs(deltaVector.y) / math.abs(deltaVector.x)))
	if 0 < (deltaVector.x * deltaVector.y) then
		angle = -1 * angle
	end

	self:SetRotate(angle)

	--***---------- 刷新渲染层 ----------***--
	self:RefreshRenderViewRotate()
	--***---------- 刷新渲染层 ----------***--
end
---------------------------------------------------
-- transform end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
是否已经造成过效果
--]]
function SpineUFOBulletModel:GetCausedDamage()
	return self.causedDamage
end
function SpineUFOBulletModel:SetCausedDamage(caused)
	self.causedDamage = caused
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

---------------------------------------------------
-- collision begin --
---------------------------------------------------
--[[
获取目标location
@return _ cc.p
--]]
function SpineUFOBulletModel:GetTargetLocation()
	return self.targetLocation
end
function SpineUFOBulletModel:SetTargetLocation(location)
	self.targetLocation.x = location.x
	self.targetLocation.y = location.y
end
--[[
获取目标的碰撞框信息
@return _ cc.rect
--]]
function SpineUFOBulletModel:GetTargetStaticCollisionBox()
	return self.targetCollisionBox
end
--[[
获取目标相对 battle root 的碰撞框信息
@return _ cc.rect
--]]
function SpineUFOBulletModel:GetTargetStaticCollisionBoxInBattleRoot()
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

return SpineUFOBulletModel

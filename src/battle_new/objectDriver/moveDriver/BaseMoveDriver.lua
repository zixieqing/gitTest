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
	self:InitValue()	
end
--[[
初始化数据
--]]
function BaseMoveDriver:InitValue()
	---------- 普通移动 ----------
	-- 移动目标的物体tag
	self.moveTargetTag = nil

	-- 移动时的y轴朝向
	self.moveTowardsY = 0

	-- 初始化一个y轴的站位间隔
	self:InitStanceOff()
	---------- 普通移动 ----------

	---------- 逃跑 ----------
	-- 是否正在逃跑
	self.escaping = false

	-- 缓存逃跑的目标点
	self.escapeTargetPos = nil

	-- 逃跑后再次出现的波数 0为初始状态未逃跑过
	self.appearWaveAfterEscape = 0
	---------- 逃跑 ----------

	---------- 强制移动 ----------
	self.forceMoveTargetPos = nil
	self.forceMoveActionName = nil
	self.forceMoveOverCallback = nil
	---------- 强制移动 ----------
end
--[[
初始化y轴站位间隔
--]]
function BaseMoveDriver:InitStanceOff()
	self.stanceOffY = 0

	-- 根据初始的站位计算y轴的站位间隔
	local row = self:GetOwner():GetObjInfo().oriLocation.rc.r
	self:SetStanceOffY(row - (math.ceil(G_BattleLogicMgr:GetBConf().ROW * 0.5)))
end
---------------------------------------------------
-- init logic end --
---------------------------------------------------

---------------------------------------------------
-- common move begin --
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
	local target = G_BattleLogicMgr:IsObjAliveByTag(targetTag)

	if nil == target then return end

	-- 设置物体移动状态
	self:GetOwner():SetState(OState.MOVING)

	-- 设置物体移动目标的tag
	self:SetMoveTargetTag(targetTag)

	---------- 朝向 ----------
	local deltaPos = cc.pSub(
		target:GetLocation().po,
		self:GetOwner():GetLocation().po
	)

	if 0 < deltaPos.y then

		-- y轴正方向
		self:SetMoveTowardsY(BattleObjTowards.FORWARD)

	elseif 0 > deltaPos.y then

		-- y轴反方向
		self:SetMoveTowardsY(BattleObjTowards.NEGATIVE)

	elseif 0 == deltaPos.y then

		-- 如果在同一行 需要进行一些处理
		-- 首先预测target的移动方向
		local targetTowards = target.moveDriver:GetMoveTowardsY()

		if BattleObjTowards.BASE == targetTowards then
			-- 如果目标朝向为0 随机一个朝向
			local upper = 1000
			local random = G_BattleLogicMgr:GetRandomManager():GetRandomInt(upper)
			if upper * 0.5 < random then
				self:SetMoveTowardsY(BattleObjTowards.FORWARD)
			else
				self:SetMoveTowardsY(BattleObjTowards.NEGATIVE)
			end
		else
			-- 不为0 跟随目标的朝向
			self:SetMoveTowardsY(targetTowards)
		end

	end
	---------- 朝向 ----------

	---------- 物体动画 ----------
	if sp.AnimationName.run ~= self:GetOwner():GetCurrentAnimationName() then
		self:GetOwner():DoAnimation(true, nil, sp.AnimationName.run, true)

		--***---------- 刷新渲染层 ----------***--
		self:GetOwner():RefreshRenderAnimation(
			true, nil, sp.AnimationName.run, true
		)
		--***---------- 刷新渲染层 ----------***--
	end
	---------- 物体动画 ----------
end
--[[
结束动作
--]]
function BaseMoveDriver:OnActionExit()
	-- 移动结束 恢复上一个状态
	self:GetOwner():SetState(self:GetOwner():GetState(-1))

	-- 设置上一个状态为normal
	self:GetOwner():SetState(OState.NORMAL, -1)

	-- 置空移动目标
	self.moveTargetTag = nil

	-- 停止动作
	if sp.AnimationName.run == self:GetOwner():GetCurrentAnimationName() then
		self:GetOwner():DoAnimation(true, nil, sp.AnimationName.idle, true)

		--***---------- 插入刷新渲染层计时器 ----------***--
		self:GetOwner():RefreshRenderAnimation(
			true, nil, sp.AnimationName.idle, true
		)
		--***---------- 插入刷新渲染层计时器 ----------***--
	end
end
--[[
动作被打断
--]]
function BaseMoveDriver:OnActionBreak()
	-- 移动结束 恢复上一个状态
	self:GetOwner():SetState(self:GetOwner():GetState(-1))

	-- 设置上一个状态为normal
	self:GetOwner():SetState(OState.NORMAL, -1)
end
--[[
动作进行中
@params dt number delta time
@params targetTag int 移动目标对象tag
--]]
function BaseMoveDriver:OnActionUpdate(dt, targetTag)
	if nil == G_BattleLogicMgr:IsObjAliveByTag(targetTag) then
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
	-- 改变动画状态
	if sp.AnimationName.run ~= self:GetOwner():GetCurrentAnimationName() then
		self:GetOwner():DoAnimation(true, nil, sp.AnimationName.run, true)

		--***---------- 刷新渲染层 ----------***--
		self:GetOwner():RefreshRenderAnimation(
			true, nil, sp.AnimationName.run, true
		)
		--***---------- 刷新渲染层 ----------***--
	end

	local target = G_BattleLogicMgr:IsObjAliveByTag(targetTag)

	local targetPos = target:GetLocation().po
	local targetCollisionBox = target:GetStaticCollisionBox()

	local ownerPos = self:GetOwner():GetLocation().po
	local ownerCollisionBox = self:GetOwner():GetStaticCollisionBox()

	local deltaPos = cc.pSub(targetPos, ownerPos)

	-- 移动目标点
	local destinationPos = cc.p(0, 0)

	---------- 计算最终点 y轴 ----------
	-- 自身的y轴站位间隔
	local stanceOffYSelf = self:GetStanceOffY()
	-- 目标的y轴站位间隔
	local stanceOffYTarget = target.moveDriver:GetStanceOffY()
	-- 最终的
	destinationPos.y = targetPos.y + (stanceOffYSelf - stanceOffYTarget) * G_BattleLogicMgr:GetCellSize().height * MELEE_STANCE_OFF_Y
	---------- 计算最终点 y轴 ----------

	---------- 计算最终点 x轴 ----------
	-- 附加一个攻击距离修正值 移动目标物体在物体右侧时为负
	if 0 < deltaPos.x then

		-- 目标在右侧
		self:GetOwner():SetOrientation(BattleObjTowards.FORWARD)

		-- 计算目标横坐标理论值 碰撞框边界加上攻击距离
		destinationPos.x = targetPos.x + targetCollisionBox.x - (self:GetOwner():GetAttackRange() * G_BattleLogicMgr:GetCellSize().width - 1)

		-- 如果已经处于攻击距离范围内 则x轴不再移动
		if destinationPos.x < ownerPos.x + ownerCollisionBox.x + ownerCollisionBox.width then
			destinationPos.x = ownerPos.x
		end

	else

		-- 目标在左侧
		self:GetOwner():SetOrientation(BattleObjTowards.NEGATIVE)

		-- 计算目标横坐标理论值 碰撞框边界加上攻击距离
		destinationPos.x = targetPos.x + targetCollisionBox.x + targetCollisionBox.width + (self:GetOwner():GetAttackRange() * G_BattleLogicMgr:GetCellSize().width - 1)

		-- 如果已经处于攻击距离范围内 则x轴不再移动
		if destinationPos.x > ownerPos.x + ownerCollisionBox.x then
			destinationPos.x = ownerPos.x
		end

	end
	---------- 计算最终点 x轴 ----------

	---------- 根据时间修正最终位置 ----------
	-- 总距离
	local distance = cc.pGetDistance(destinationPos, ownerPos)
	local t = distance / self:GetOwner():GetMoveSpeed()
	local finalPos = cc.p(0, 0)

	if t <= dt then
		finalPos = destinationPos
	else
		finalPos = cc.pAdd(
			ownerPos,
			cc.pMul(cc.pSub(destinationPos, ownerPos), dt / t)
		)
	end

	-- 改变物体坐标
	self:GetOwner():ChangePosition(finalPos)
	---------- 根据时间修正最终位置 ----------

	--***---------- 刷新渲染层 ----------***--
	-- 刷新渲染层朝向
	self:GetOwner():RefreshRenderViewTowards()
	-- 刷新渲染层坐标
	self:GetOwner():RefreshRenderViewPosition()
	--***---------- 刷新渲染层 ----------***--

	---------- 判断是否需要结束移动 ----------
	local distanceJudge = self:GetOwner().attackDriver:CanAttackByDistance(targetTag)
	local targetJudge = (nil ~= target.attackDriver:GetAttackTargetTag() and self:GetOwner():GetOTag() == target.attackDriver:GetAttackTargetTag())

	if distanceJudge and (targetJudge or OState.MOVING ~= target:GetState()) then
		BattleUtils.BattleObjectActionLog(self:GetOwner(), '移动到位 结束移动状态')
		self:OnActionExit()
	end
	---------- 判断是否需要结束移动 ----------

end
---------------------------------------------------
-- common move end --
---------------------------------------------------

---------------------------------------------------
-- escape begin --
---------------------------------------------------
--[[
能否逃跑
@params currentWave int 当前波数
@return _ bool 是否能逃跑
--]]
function BaseMoveDriver:CanDoEscape(currentWave)
	return currentWave ~= self:GetAppearWaveAfterEscape()
end
--[[
是否正在逃跑
--]]
function BaseMoveDriver:IsEscaping()
	return self.escaping
end
function BaseMoveDriver:SetEscaping(escaping)
	self.escaping = escaping
end
--[[
获取逃跑的目标点
--]]
function BaseMoveDriver:GetEscapeTargetPosition()
	return self.escapeTargetPos
end
function BaseMoveDriver:SetEscapeTargetPosition(pos)
	self.escapeTargetPos = pos
end
--[[
进入逃跑
@params targetPos cc.p 逃跑的目标地点
@params escapeData table {
	escapeNpcId int 逃跑的npc card id
	escapeType ConfigEscapeType 逃跑类型
	appearWave int 出现的波数
	appearHpPercent number 出现时的生命百分比
	dialogueData table 对话信息
}
--]]
function BaseMoveDriver:OnEscapeEnter(targetPos, escapeData)
	-- 清buff
	self:GetOwner():ClearBuff()

	-- 将逃跑怪物设置全免疫
	self:GetOwner():SetAllImmune(true)

	-- 给对象加上1点血起死回生
	self:GetOwner():ForceUndeadOnce()

	-- 设置逃跑状态
	self:SetEscaping(true)

	local escapeType = escapeData.escapeType
	if ConfigEscapeType.ESCAPE == escapeType then

		-- 彻底逃跑

	elseif ConfigEscapeType.RETREAT == escapeType then

		-- 中场休息 后续波数继续
		-- 设置再次出现的波数
		self:SetAppearWaveAfterEscape(escapeData.appearWave)
		self:GetOwner():HpPercentChangeForce(escapeData.appearHpPercent)

	end

	-- 将物体加入休息区
	G_BattleLogicMgr:GetBData():AddALogicModelToRest(self:GetOwner())
	G_BattleLogicMgr:GetBData():RemoveABattleObjLogicModel(self:GetOwner())

	-- 缓存逃跑点
	self:SetEscapeTargetPosition(targetPos)
end
--[[
开始进行逃跑
@params targetPos cc.p 逃跑的目标地点
--]]
function BaseMoveDriver:StartEscape(targetPos)
	-- 切换成run动作
	local runActionTimeScale = 2
	self:GetOwner():DoAnimation(true, runActionTimeScale, sp.AnimationName.run, true)
	--***---------- 刷新渲染层 ----------***--
	self:GetOwner():RefreshRenderAnimation(
		true, runActionTimeScale, sp.AnimationName.run, true
	)
	--***---------- 刷新渲染层 ----------***--

	local ownerPos = self:GetOwner():GetLocation().po

	-- 更新朝向
	local towards = cc.pSub(targetPos, ownerPos).x > 0 and BattleObjTowards.FORWARD or BattleObjTowards.NEGATIVE
	self:GetOwner():SetOrientation(towards)
	--***---------- 刷新渲染层 ----------***--
	self:GetOwner():RefreshRenderViewTowards()
	--***---------- 刷新渲染层 ----------***--

	-- 逻辑层直接更新坐标
	self:GetOwner():ChangePosition(targetPos)

	--***---------- 刷新渲染层 ----------***--
	-- 开始进行逃跑
	G_BattleLogicMgr:AddRenderOperate(
		'G_BattleRenderMgr',
		'PhaseChangeEscape',
		self:GetOwner():GetViewModelTag(), self:GetOwner():GetOTag(),
		targetPos, self:GetOwner():GetMoveSpeed() * 2
	)
	--***---------- 刷新渲染层 ----------***--
end
--[[
逃跑完毕
--]]
function BaseMoveDriver:OnEscapeExit()
	-- 设置逃跑状态
	self:SetEscaping(false)

	-- 清空动画
	self:GetOwner():ClearAnimations()
	self:GetOwner():ClearRenderAnimations()

	--***---------- 刷新渲染层 ----------***--
	-- 逃跑结束
	G_BattleLogicMgr:AddRenderOperate(
		'G_BattleRenderMgr',
		'PhaseChangeEscapeOverAndDisappear',
		self:GetOwner():GetViewModelTag()
	)
	--***---------- 刷新渲染层 ----------***--
end
---------------------------------------------------
-- escape end --
---------------------------------------------------

---------------------------------------------------
-- blew off begin --
---------------------------------------------------
--[[
吹飞
@params distance number 吹飞多少横坐标 为空时自动修正距离
--]]
function BaseMoveDriver:OnBlewOffEnter(distance)
	local distance_ = distance or self:GetOwner():GetStaticViewBox().width * 0.5
	local designSize = G_BattleLogicMgr:GetDesignScreenSize()
	local oriPos = nil
	local targetPos = nil

	local ownerLocation = self:GetOwner():GetLocation().po

	if true == self:GetOwner():IsEnemy(true) then

		-- 敌人时向屏幕右侧吹飞
		oriPos = cc.p(
			designSize.width + distance_,
			ownerLocation.y
		)

		targetPos = cc.p(
			designSize.width - distance_,
			ownerLocation.y
		)

	else

		-- 友军时吹飞距离为负
		distance_ = -distance_
		-- 友军时向屏幕左侧吹飞
		oriPos = cc.p(
			distance_,
			ownerLocation.y
		)

		targetPos = cc.p(
			-distance_,
			ownerLocation.y
		)

	end

	-- 变换坐标
	self:GetOwner():ChangePosition(oriPos)

	-- 刷新渲染层坐标
	self:GetOwner():RefreshRenderViewPosition()

	-- 开始重新走进战场
	self:OnForceMoveEnter(targetPos, sp.AnimationName.run)
end
---------------------------------------------------
-- blew off end --
---------------------------------------------------

---------------------------------------------------
-- force move begin --
---------------------------------------------------
--[[
开始强制移动
@params targetPos cc.p 目标位置
@params moveActionName string 移动动作名
@params moveOverCallback function 移动结束回调
--]]
function BaseMoveDriver:OnForceMoveEnter(targetPos, moveActionName, moveOverCallback)
	if OState.MOVE_FORCE == self:GetOwner():GetState() then
		self:OnForceMoveBreak()
	end

	self:GetOwner():SetState(OState.MOVE_FORCE)

	-- 初始化一些状态
	self:SetForceMoveTargetPosition(targetPos)
	self:SetForceMoveActionName(moveActionName or sp.AnimationName.run)
	self:SetForceMoveOverCallback(moveOverCallback)

	-- 判断动作
	if moveActionName ~= self:GetOwner():GetCurrentAnimationName() then
		self:GetOwner():DoAnimation(true, nil, moveActionName, true)

		--***---------- 刷新渲染层 ----------***--
		self:GetOwner():RefreshRenderAnimation(
			true, nil, moveActionName, true
		)
		--***---------- 刷新渲染层 ----------***--
	end
end
--[[
强制移动进行中
--]]
function BaseMoveDriver:OnForceMoveUpdate(dt)
	local ownerPos = self:GetOwner():GetLocation().po
	local targetPos = self:GetForceMoveTargetPosition()
	local distance = cc.pGetDistance(targetPos, ownerPos)

	-- 刷新朝向
	local towards = targetPos.x - ownerPos.x > 0 and BattleObjTowards.FORWARD or BattleObjTowards.NEGATIVE
	self:GetOwner():SetOrientation(towards)

	local distanceJudge = false
	local t = distance / self:GetOwner():GetMoveSpeed()
	local finalPos = cc.p(0, 0)

	if t <= dt then
		distanceJudge = true
		finalPos = targetPos
	else
		finalPos = cc.pAdd(ownerPos, cc.pMul(cc.pSub(targetPos, ownerPos), dt / t))
	end

	-- 改变物体坐标
	self:GetOwner():ChangePosition(finalPos)

	--***---------- 刷新渲染层 ----------***--
	-- 刷新渲染层朝向
	self:GetOwner():RefreshRenderViewTowards()
	-- 刷新渲染层坐标
	self:GetOwner():RefreshRenderViewPosition()
	--***---------- 刷新渲染层 ----------***--

	-- 判断是否移动到位
	if true == distanceJudge then
		self:OnForceMoveExit()
	end
end
--[[
强制移动结束
--]]
function BaseMoveDriver:OnForceMoveExit()
	-- 判断动作
	if self:GetForceMoveActionName() == self:GetOwner():GetCurrentAnimationName() then
		self:GetOwner():DoAnimation(true, nil, sp.AnimationName.idle, true)

		--***---------- 刷新渲染层 ----------***--
		self:GetOwner():RefreshRenderAnimation(
			true, nil, sp.AnimationName.idle, true
		)
		--***---------- 刷新渲染层 ----------***--
	end

	-- 走回调
	local callback = self:GetForceMoveOverCallback()
	if nil ~= callback then
		callback()
	else
		self:GetOwner():SetState(OState.NORMAL)
	end

	self:ClearForceMoveState()
end
--[[
强制移动被打断
--]]
function BaseMoveDriver:OnForceMoveBreak()
	self:ClearForceMoveState()
end
--[[
清空强制移动的状态
--]]
function BaseMoveDriver:ClearForceMoveState()
	self:SetForceMoveTargetPosition(nil)
	self:SetForceMoveActionName(nil)
	self:SetForceMoveOverCallback(nil)
end
--[[
获取强制移动的目标点
@return _ cc.p 强制移动的目标点
--]]
function BaseMoveDriver:GetForceMoveTargetPosition()
	return self.forceMoveTargetPos
end
function BaseMoveDriver:SetForceMoveTargetPosition(targetPos)
	self.forceMoveTargetPos = targetPos
end
--[[
获取强制移动的动作名称
@return _ string 动作名称
--]]
function BaseMoveDriver:GetForceMoveActionName()
	return self.forceMoveActionName
end
function BaseMoveDriver:SetForceMoveActionName(actionName)
	self.forceMoveActionName = actionName
end
--[[
获取强制移动完成后的回调函数
@return _ function 回调
--]]
function BaseMoveDriver:GetForceMoveOverCallback()
	return self.forceMoveOverCallback
end
function BaseMoveDriver:SetForceMoveOverCallback(callback)
	self.forceMoveOverCallback = callback
end
---------------------------------------------------
-- force move end --
---------------------------------------------------



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
	return self.stanceOffY * G_BattleLogicMgr:GetCellSize().height * MELEE_STANCE_OFF_Y
end
--[[
获取逃跑后重返战场的波数
--]]
function BaseMoveDriver:GetAppearWaveAfterEscape()
	return self.appearWaveAfterEscape
end
function BaseMoveDriver:SetAppearWaveAfterEscape(wave)
	self.appearWaveAfterEscape = wave
end
---------------------------------------------------
-- get set begin --
---------------------------------------------------

return BaseMoveDriver


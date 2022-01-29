--[[
攻击驱动基类
@params table {
	owner BaseObject 挂载的战斗物体
}
--]]
local BaseActionDriver = __Require('battle.objectDriver.BaseActionDriver')
local BaseAttackDriver = class('BaseAttackDriver', BaseActionDriver)
--[[
constructor
--]]
function BaseAttackDriver:ctor( ... )
	BaseActionDriver.ctor(self, ...)

	self:Init()
end
---------------------------------------------------
-- init logic begin --
---------------------------------------------------
--[[
初始化逻辑
--]]
function BaseAttackDriver:Init()
	-- 攻击对象tag
	self.attackTargetTag = nil
	-- 初始化攻击行为触发器 攻击行为只有一个时间触发类型
	self.actionTrigger = 0
	-- 初始化分段伤害池
	self.damagePool = nil
	-- 当前分段
	self.phase = 0
	-- 攻击特效
	self.attackModifiers = {
		[TimeAxisConstants.TA_ENTER] 		= {}, -- 攻击前摇时未击中前起作用的攻击特效
		[TimeAxisConstants.TA_ACTION] 		= {}, -- 攻击击中时起作用的攻击特效
		[TimeAxisConstants.TA_EXIT] 		= {}, -- 攻击后摇时已击中后起作用的攻击特效
		id 									= {}  -- 以上三个保存id不保存指针
	}
	-- 攻击充能buff
	self.attackChargeBuffs = {}

	---------- 攻击索敌规则 ----------
	-- 攻击索敌规则
	self.oriAttackSeekRule = SeekRuleStruct.New(ConfigSeekTargetRule.T_OBJ_ENEMY, SeekSortRule.S_HATE_MAX, 1)
	self.attackSeekRuleInfo = {
		self.oriAttackSeekRule
	}
	---------- 攻击索敌规则 ----------

	---------- 多重相关 ----------
	self.multishotSeekRule = nil
	self.multishotTargets = nil
	self.multishotDamagePool = nil
	self.multishotDamageRatio = nil
	---------- 多重相关 ----------
end
---------------------------------------------------
-- init logic end --
---------------------------------------------------

---------------------------------------------------
-- control logic begin --
---------------------------------------------------
--[[
是否能进行动作
@return result bool 是否可以攻击
--]]
function BaseAttackDriver:CanDoAction()
	local result = false
	if self.actionTrigger <= 0 then
		-- 攻击间隔满足 返回
		result = true
	end
	return result
end
--[[
进入动作
@params targetTag int 攻击对象tag
--]]
function BaseAttackDriver:OnActionEnter(targetTag)
	---------- logic ----------
	-- 置为攻击状态
	self:GetOwner():setState(OState.ATTACKING)
	-- 重置攻击间隔
	self:CostActionResources()
	-- 开始进行攻击动作
	local aTarget = BMediator:IsObjAliveByTag(targetTag)

	if nil == aTarget then
		self:OnActionExit()
		return
	end

	self:SetAttackTargetTag(targetTag)

	-- 影响伤害的外部参数
	local externalDamageParameter = ObjectExternalDamageParameterStruct.New(
		false,
		0,
		{},
		{}
	)
	---------- attack modifier ----------
	-- 触发 TimeAxisConstants.TA_ENTER 类型的攻击特效
	local amTag = nil
	local attackModifier = nil
	for i = #self.attackModifiers[TimeAxisConstants.TA_ENTER], 1, -1 do
		amTag = self.attackModifiers[TimeAxisConstants.TA_ENTER][i]
		attackModifier = self:GetAttackModifierByTag(amTag)
		if attackModifier:CanEnterModifier() then
			-- 起效
			attackModifier:OnModifierEnter(1, 1, externalDamageParameter)
			-- 该类型作用后直接结束
			attackModifier:OnModifierExit()

			-- TODO -- 
			-- 是否需要移除???
			if attackModifier:IsInvalid() then
				self:RemoveAAttackModifier(attackModifier, TimeAxisConstants.TA_ENTER, true)
			end
		end
	end
	---------- attack modifier ----------

	---------- calculate damage ----------
	-- 如果没有暴击 再roll一次
	if not externalDamageParameter.isCritical then
		local critRate = self:GetOwner():getMainProperty():getCriticalRate()
		externalDamageParameter.isCritical = BMediator:GetRandomManager():GetRandomInt(100) <= critRate and true or false
		-- externalDamageParameter.isCritical = math.random(100) <= critRate and true or false
	end

	-- 检查一次buff
	local triggerBuffConfig = {
		ConfigBuffType.CRITICAL_COUNTER
	}
	for _, buffType in ipairs(triggerBuffConfig) do
		local targetBuffs = self:GetOwner():GetBuffsByBuffType(buffType, false)
		for i = #targetBuffs, 1, -1 do
			targetBuffs[i]:OnCauseEffectEnter(externalDamageParameter)
		end
	end

	-- 重置伤害池 做分段时处理
	self.damagePool = {
		damage = self:GetOwner():getMainProperty():getAttackDamage(self:GetOwner(), aTarget, externalDamageParameter),
		isCritical = externalDamageParameter.isCritical
	}
	---------- calculate damage ----------

	---------- 多重的逻辑 ----------
	self:OnMultishotEnter(targetTag, externalDamageParameter)
	---------- 多重的逻辑 ----------

	-- 重置攻击分段
	self.phase = 0

	---------- 触发器 ----------
	-- 攻击
	self:GetOwner().triggerDriver:OnActionEnter(ConfigObjectTriggerActionType.ATTACK)
	if externalDamageParameter.isCritical then
		-- 暴击
		self:GetOwner().triggerDriver:OnActionEnter(ConfigObjectTriggerActionType.ATTACK_CRITICAL)
	end
	---------- 触发器 ----------

	---------- logic ----------

	---------- view ----------
	-- 处理spine动画
	self:GetOwner():DoSpineAnimation(
		false, nil,
		self:GetOwner().spineActionData.attack.actionName, false,
		sp.AnimationName.idle, true
	)
	self:GetOwner():SetSpineTimeScale(self:GetOwner():getAvatarTimeScale())

	-- 更新朝向
	local deltaX = aTarget:getLocation().po.x - self:GetOwner():getLocation().po.x
	if deltaX > 0 then
		self:GetOwner():changeOrientation(true)
	elseif deltaX < 0 then
		self:GetOwner():changeOrientation(false)
	end
	---------- view ----------

	------------ sound effect ------------
	PlayBattleEffects(self:GetOwner().spineActionData.attack.actionSE)
	PlayBattleEffects(self:GetOwner().spineActionData.attack.actionVoice)
	------------ sound effect ------------
end
--[[
@override
结束动作
--]]
function BaseAttackDriver:OnActionExit()
	---------- logic ----------
	self:GetOwner():setState(self:GetOwner():getState(-1))
	self:GetOwner():setState(OState.NORMAL, -1)

	-- 刷新一次攻击特效充能计数 移除不合法的效果
	local attackModifierTag = nil
	local attackModifier = nil

	---------- attack modifier ----------
	-- 刷新一次攻击特效状态 将不需要的移除
	for i = #self.attackModifiers[TimeAxisConstants.TA_ACTION], 1, -1 do
		attackModifierTag = self.attackModifiers[TimeAxisConstants.TA_ACTION][i]
		attackModifier = self:GetAttackModifierByTag(attackModifierTag)
		if nil ~= attackModifier then
			attackModifier:OnModifierExit()

			-- TODO -- 
			-- 是否需要移除???
			if attackModifier:IsInvalid() then
				self:RemoveAAttackModifier(attackModifier, TimeAxisConstants.TA_ACTION, true)
			end
		end
	end

	-- 检查一次攻击充能buff是否需要移除
	local buff = nil
	for i = #self.attackChargeBuffs, 1, -1 do
		buff = self:GetOwner():getBuffByBuffId(self.attackChargeBuffs[i])
		if nil ~= buff then
			-- 检查buff
			buff:AutoRemoveSelf()
		end
	end
	---------- attack modifier ----------

	---------- logic ----------

	---------- view ----------
	-- !! 恢复动画速度 因为攻击动画可能会全局变速 !! --
	self:GetOwner():getSpineAvatar():setTimeScale(self:GetOwner():getAvatarTimeScale(true))
	---------- view ----------
end
--[[
@override
动作被打断
--]]
function BaseAttackDriver:OnActionBreak()
	self:OnActionExit()
end
--[[
动作进行中
@params dt number delta time
--]]
function BaseAttackDriver:OnActionUpdate(dt)

end
--[[
刷新触发器
@params dt number 差值时间
--]]
function BaseAttackDriver:UpdateActionTrigger(dt)
	self.actionTrigger = math.max(0, self.actionTrigger - dt)
end
--[[
消耗做出行为需要的资源
--]]
function BaseAttackDriver:CostActionResources()
	-- 攻击行为只消耗内置cd
	self.actionTrigger = self:GetOwner():getMainProperty():getATKCounter()

	-- 攻击回能量
	self:GetOwner():addEnergy((self:GetOwner():getMainProperty():getATKCounter() * ENERGY_PER_ATTACK))

	---------- attack modifier ----------
	self:CostAttackModifierResources()
	---------- attack modifier ----------
end
--[[
消耗攻击特效
--]]
function BaseAttackDriver:CostAttackModifierResources()
	local buff = nil
	local attackModifier = nil

	for i = #self.attackChargeBuffs, 1, -1 do

		-- 先检查buff
		buff = self:GetOwner():getBuffByBuffId(self.attackChargeBuffs[i])

		if nil ~= buff then
			-- 消耗攻击充能
			buff:AddCharge(-1)

			-- 为攻击特效充能
			attackModifier = self:GetAttackModifierByTag(buff:GetChargedAMTag())

			if nil ~= attackModifier then
				-- 消耗一层充能
				attackModifier:CostModifierResources()
			else
				BattleUtils.PrintBattleWaringLog('>>>>> here find logic error cannot find am in attack driver but buff now charge it')
			end
		else
			-- 检查光环
			buff = self:GetOwner():getHaloByBuffId(self.attackChargeBuffs[i])

			if nil ~= buff then
				-- 为攻击特效充能
				attackModifier = self:GetAttackModifierByTag(buff:GetChargedAMTag())

				if nil ~= attackModifier then
					-- 消耗一层充能
					attackModifier:SetCostTimeCanCauseEffect(true)
				else
					BattleUtils.PrintBattleWaringLog('>>>>> here find logic error cannot find am in attack driver but buff now charge it')
				end
			else
				BattleUtils.PrintBattleWaringLog('>>>>> here find logic error cannot find attack charge buff in object but in attackDriver')
			end
		end

	end
end
--[[
重置所有触发器
--]]
function BaseAttackDriver:ResetActionTrigger()
	self.actionTrigger = 0
end
--[[
获取触发器
@return _ number 触发器 实际上就是攻击内置cd
--]]
function BaseAttackDriver:GetActionTrigger()
	return self.actionTrigger
end
--[[
攻击行为
@params targetTag int 攻击对象tag
@params percent number 伤害占比 分段伤害用
--]]
function BaseAttackDriver:Attack(targetTag, percent)
	local ownerTag = self:GetOwner():getOTag()
	local target = BMediator:IsObjAliveByTag(targetTag)
	if nil == target then
		-- 如果对象为空 重新索敌
		self:GetOwner():setState(OState.NORMAL)
		return
	end
	-- 攻击分段+1
	local phase = self.phase + 1
	self.phase = phase

	-- 创建子弹 首先获取bullet骨骼 存在则是投掷物弹道型的攻击 统一传世界坐标
	local bulletOriPosition = self:GetOwner():getLocation().po
	local boneData = self:GetOwner():findBoneInWorldSpace(sp.CustomName.BULLET_BONE_NAME)
	if boneData then
		bulletOriPosition = cc.p(boneData.worldPosition.x, boneData.worldPosition.y)
	end

	local damageData = ObjectDamageStruct.New(
		targetTag,
		self.damagePool.damage * percent,
		DamageType.ATTACK_PHYSICAL,
		self.damagePool.isCritical,
		{attackerTag = ownerTag}
	)

	---------- 多重的逻辑 ----------
	local multiDamageDatas = {}
	if self:CanMultishot() then
		local multishotTargets = self:GetMultishotTargets()
		local multishotTargetTag = nil
		local multishotTarget = nil

		for i = #multishotTargets, 1, -1 do
			multishotTargetTag = multishotTargets[i]
			multishotTarget = BMediator:IsObjAliveByTag(multishotTargetTag)

			if nil ~= multishotTarget then
				local multishotDamageInfo = self:GetMultishotDamagePoolInfoByTag(multishotTargetTag)
				local multiDamageData = ObjectDamageStruct.New(
					multishotTargetTag,
					multishotDamageInfo.damage * percent,
					DamageType.ATTACK_PHYSICAL,
					multishotDamageInfo.isCritical,
					{attackerTag = ownerTag}
				)
				table.insert(multiDamageDatas, 1, multiDamageData)
			end
		end
	end
	---------- 多重的逻辑 ----------

	local bulletData = ObjectSendBulletData.New(
		------------ 基本信息 ------------
		nil,
		nil,
		self:GetOwner().spineActionData.attack.bulletType,
		self:GetOwner().spineActionData.attack.causeType or ConfigEffectCauseType.BASE,
		self:GetOwner():getOTag(),
		targetTag,
		false,
		------------ spine动画信息 ------------
		checkint(self:GetOwner().spineActionData.attack.effectId),
		self:GetOwner().spineActionData.attack.effectActionName,
		self:GetOwner().spineActionData.attack.effectZOrder,
		bulletOriPosition,
		target:getLocation().po,
		self:GetOwner().spineActionData.attack.effectScale,
		self:GetOwner().spineActionData.attack.effectPos,
		self:GetOwner():getOrientation(),
		false,
		false,
		------------ 数据信息 ------------
		damageData,
		nil,
		function (percent)
			local target = BMediator:IsObjAliveByTag(targetTag)
			if nil ~= target then

				local damageData_ = damageData:CloneStruct()
				damageData_:SetDamageValue(damageData_.damage * percent)

				------------ logic ------------
				-- 目标被攻击
				target:beAttacked(damageData_)

				---------- attack modifier ----------
				-- 触发 TimeAxisConstants.TA_ACTION 类型的攻击特效
				local owner = BMediator:IsObjAliveByTag(ownerTag)
				if nil ~= owner then
					local tag = nil
					local attackModifier = nil
					for i = #self.attackModifiers[TimeAxisConstants.TA_ACTION], 1, -1 do
						tag = self.attackModifiers[TimeAxisConstants.TA_ACTION][i]
						attackModifier = self:GetAttackModifierByTag(tag)
						if attackModifier:CanEnterModifier() then
							attackModifier:OnModifierEnter(phase, percent)
						end
					end
				end
				---------- attack modifier ----------

				---------- 触发器 ----------
				self:GetOwner().triggerDriver:OnActionEnter(ConfigObjectTriggerActionType.ATTACK_HIT)
				---------- 触发器 ----------

				------------ logic ------------

				------------ view ------------
				-- 显示被击特效
				target:showHurtEffect(self:GetOwner().spineActionData.attack.hurtEffectData)
				------------ view ------------

				---------- 多重的逻辑 ----------
				if self:CanMultishot() then
					for i = #multiDamageDatas, 1, -1 do
						local multishotDamageData_ = multiDamageDatas[i]:CloneStruct()
						multishotDamageData_:SetDamageValue(multishotDamageData_.damage * percent)

						local multishotTarget_ = BMediator:IsObjAliveByTag(multishotDamageData_.targetTag)
						if nil ~= multishotTarget_ then
							multishotTarget_:beAttacked(multishotDamageData_)
							multishotTarget_:showHurtEffect(self:GetOwner().spineActionData.attack.hurtEffectData)
						end
					end
				end
				---------- 多重的逻辑 ----------
			end
		end
	)

	------------ sound effect ------------
	PlayBattleEffects(self:GetOwner().spineActionData.attack.actionCauseSE)
	------------ sound effect ------------

	BMediator:sendBullet(bulletData)
end
--[[
为普通攻击索敌
@return _ int 结果 对象tag
--]]
function BaseAttackDriver:SeekAttackTarget()

	---------- logic ----------
	local targets = BattleExpression.GetTargets(self:GetOwner():isEnemy(), self:GetAttackSeekRule(), self:GetOwner())

	if nil ~= targets then
		local otag = nil
		for i, target in ipairs(targets) do
			otag = target:getOTag()
			if otag ~= self:GetOwner():getOTag() then
				self:SetAttackTargetTag(otag)
				break
			end
		end
	end

	if nil ~= self:GetAttackTargetTag() then
		self:GetOwner():setState(OState.BATTLE)
	else
		---------- view ----------
		-- 如果索不到可攻击目标并且处于移动中 停掉移动动作
		if nil == self:GetAttackTargetTag() and sp.AnimationName.run == self:GetOwner():GetCurrentSpineAnimationName() then
			self:GetOwner():DoSpineAnimation(true, nil, sp.AnimationName.idle, true)
		end
		---------- view ----------
	end
	---------- logic ----------

end
--[[
获取攻击的索敌规则
@return _ SeekRuleStruct 索敌规则
--]]
function BaseAttackDriver:GetAttackSeekRule()
	return self.attackSeekRuleInfo[1]
end
--[[
改变索敌规则
@params newSeekRule SeekRuleStruct 新的索敌规则
--]]
function BaseAttackDriver:GainAttackSeekRule(newSeekRule)
	-- 插入新的索敌规则
	table.insert(self.attackSeekRuleInfo, 1, newSeekRule)
	-- 重新索敌
	self:LostAttackTarget()
end
--[[
失去索敌规则
@params seekRule SeekRuleStruct 索敌规则
--]]
function BaseAttackDriver:LostAttackSeekRule(seekRule)
	local targetID = ID(seekRule)
	local needResearch = false
	for i = #self.attackSeekRuleInfo, 1, -1 do
		if targetID == ID(self.attackSeekRuleInfo[i]) then
			-- 移除当前索敌规则
			table.remove(self.attackSeekRuleInfo, i)
			if 1 == i then
				needResearch = true
			end
			break
		end
	end
	if needResearch and seekRule ~= self:GetAttackSeekRule() then
		-- 重新索敌
		self:LostAttackTarget()
	end
end
--[[
获取当前攻击对象tag
@return _ int 攻击对象tag
--]]
function BaseAttackDriver:GetAttackTargetTag()
	return self.attackTargetTag
end
--[[
设置当前攻击对象
@params aTargetTag int 攻击对象tag
--]]
function BaseAttackDriver:SetAttackTargetTag(aTargetTag)
	self.attackTargetTag = aTargetTag
end
--[[
是否可以攻击 距离判定
@params targetTag int 攻击对象tag
@return _ bool 距离上是否满足攻击条件
--]]
function BaseAttackDriver:CanAttackByDistance(targetTag)
	local target = BMediator:IsObjAliveByTag(targetTag)

	if nil == target then return false end

	local ownerCollisionBox = self:GetOwner():getStaticCollisionBox()
	local targetCollisionBox = target:getStaticCollisionBox()

	local judgeX = false
	local judgeY = false

	---------- 纵向判断 ----------
	--[[-------- tips ----------
	1 按照分隔原则 物体必须处于和站位分隔同向的相对位置
	2 物体间的距离在分隔距离之内
	---------- tips --------]]--
	local deltaPos = cc.pSub(target:getLocation().po, self:GetOwner():getLocation().po)
	local stanceOffYSelf = self:GetOwner().moveDriver:GetStanceOffY()
	local stanceOffYTarget = target.moveDriver:GetStanceOffY()
	if stanceOffYTarget == stanceOffYSelf then
		-- 若相对水平 错开距离
		judgeY = math.abs(deltaPos.y) <= BMediator:GetBConf().cellSize.height * MELEE_STANCE_OFF_Y * 0.5
	elseif deltaPos.y * (stanceOffYTarget - stanceOffYSelf) >= 0 then
		local fixedStanceOffY = math.abs(stanceOffYSelf - stanceOffYTarget) * BMediator:GetBConf().cellSize.height * MELEE_STANCE_OFF_Y
		judgeY = math.abs(deltaPos.y) >= fixedStanceOffY * 0.8 and math.abs(deltaPos.y) <= fixedStanceOffY * 1.2
	end
	---------- 纵向判断 ----------

	---------- 横向判断 ----------
	local ownerBorderX = nil
	local targetBorderX = nil

	if target:getLocation().po.x - self:GetOwner():getLocation().po.x > 0 then

		-- 目标在右侧
		ownerBorderX = self:GetOwner():getLocation().po.x + ownerCollisionBox.x + ownerCollisionBox.width
		targetBorderX = target:getLocation().po.x + targetCollisionBox.x
		judgeX = (ownerBorderX >= targetBorderX) or
			(self:GetOwner():getMainProperty().p.attackRange * BMediator:GetBConf().cellSize.width > math.abs(targetBorderX - ownerBorderX))

	else

		-- 目标在左侧
		ownerBorderX = self:GetOwner():getLocation().po.x + ownerCollisionBox.x
		targetBorderX = target:getLocation().po.x + targetCollisionBox.x + targetCollisionBox.width
		judgeX = (ownerBorderX <= targetBorderX) or
			(self:GetOwner():getMainProperty().p.attackRange * BMediator:GetBConf().cellSize.width > math.abs(targetBorderX - ownerBorderX))

	end
	---------- 横向判断 ----------
	
	-- print('here check can attack judge', judgeX, judgeY, self:GetOwner():getOCardName(), self:GetOwner():getLocation().po.y, target:getLocation().po.y + self:GetOwner().moveDriver:GetStanceOffY())
	return (judgeX and judgeY)
end
--[[
丢失攻击目标
--]]
function BaseAttackDriver:LostAttackTarget()
	self:SetAttackTargetTag(nil)
	if sp.AnimationName.run == self:GetOwner():GetCurrentSpineAnimationName() then
		self:GetOwner():DoSpineAnimation(true, nil, sp.AnimationName.idle, true)
	end
end
---------------------------------------------------
-- control logic end --
---------------------------------------------------

---------------------------------------------------
-- multishot begin --
---------------------------------------------------
--[[
开始多重的逻辑
@params mainTargetTag int 主要攻击对象tag
@params externalDamageParameter ObjectExternalDamageParameterStruct 伤害参数
--]]
function BaseAttackDriver:OnMultishotEnter(mainTargetTag, externalDamageParameter)
	-- 重置一些参数
	self:SetMultishotTargets(nil)

	if self:CanMultishot() then
		self:SetMultishotDamagePool({})

		local seekRule = self:GetMultishotSeekRule()

		------------ 如果主目标死亡 多重直接失效 ------------
		local mainTarget = BMediator:IsObjAliveByTag(mainTargetTag)
		if nil == mainTarget then return end
		------------ 如果主目标死亡 多重直接失效 ------------

		------------ 多重有效 进行索敌 ------------
		local targets = BattleExpression.GetTargets(mainTarget:isEnemy(true), seekRule, mainTarget)
		------------ 多重有效 进行索敌 ------------

		------------ 初始化多重目标信息 ------------
		local targetsTag = {}
		local multishotDamageRatio = self:GetMultishotDamageRatio()

		local tTag = nil
		for _, target in ipairs(targets) do
			tTag = target:getOTag()
			table.insert(targetsTag, 1, tTag)

			local damageInfo = {
				damage = self:GetOwner():getMainProperty():getAttackDamage(self:GetOwner(), target, externalDamageParameter) * multishotDamageRatio,
				isCritical = externalDamageParameter.isCritical
			}

			self:SetMultishotDamagePoolInfoByTag(tTag, damageInfo)
		end

		self:SetMultishotTargets(targetsTag)
		------------ 初始化多重目标信息 ------------		
	end
end
--[[
是否可以多重射击
@return _ bool 是否可以
--]]
function BaseAttackDriver:CanMultishot()
	return nil ~= self:GetMultishotSeekRule() and ConfigSeekTargetRule.BASE ~= self:GetMultishotSeekRule().ruleType
end
--[[
获得多重射击
@params seekRule SeekRuleStruct 多重的索敌规则
@params damageRatio number 多重的伤害倍率
--]]
function BaseAttackDriver:GainMultishot(seekRule, damageRatio)
	self:SetMultishotSeekRule(seekRule)
	self:SetMultishotDamageRatio(damageRatio)
end
--[[
失去多重射击
@params seekRule SeekRuleStruct 多重的索敌规则
--]]
function BaseAttackDriver:LostMultishot(seekRule, damageRatio)
	if nil ~= self:GetMultishotSeekRule() then
		if seekRule == self:GetMultishotSeekRule() and damageRatio == self:GetMultishotDamageRatio() then
			self:SetMultishotSeekRule(nil)
			self:SetMultishotTargets(nil)
			self:SetMultishotDamageRatio(0)
		end
	end
end
--[[
多重的索敌规则
--]]
function BaseAttackDriver:GetMultishotSeekRule()
	return self.multishotSeekRule
end
function BaseAttackDriver:SetMultishotSeekRule(seekRule)
	self.multishotSeekRule = seekRule
end
--[[
多重的攻击对象
--]]
function BaseAttackDriver:GetMultishotTargets()
	return self.multishotTargets
end
function BaseAttackDriver:SetMultishotTargets(targets)
	self.multishotTargets = targets
end
--[[
根据多重攻击对象的tag获取多重的伤害信息
@params targetTag int 攻击对象的tag
@return _ table 伤害信息 {
	damage number 伤害数值
	isCritical bool 是否暴击
}
--]]
function BaseAttackDriver:GetMultishotDamagePoolInfoByTag(targetTag)
	return self.multishotDamagePool[tostring(targetTag)]
end
function BaseAttackDriver:SetMultishotDamagePoolInfoByTag(targetTag, damageInfo)
	self.multishotDamagePool[tostring(targetTag)] = damageInfo
end
--[[
获取多重伤害池
--]]
function BaseAttackDriver:GetMultishotDamagePool()
	return self.multishotDamagePool
end
function BaseAttackDriver:SetMultishotDamagePool(damagePool)
	self.multishotDamagePool = damagePool
end
--[[
获取多重的伤害倍率
--]]
function BaseAttackDriver:GetMultishotDamageRatio()
	return self.multishotDamageRatio
end
function BaseAttackDriver:SetMultishotDamageRatio(value)
	self.multishotDamageRatio = value
end
---------------------------------------------------
-- multishot end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
添加一个攻击充能buff
@params buff BaseBuff buff指针
--]]
function BaseAttackDriver:AddAAttackChargeBuff(buff)
	table.insert(self.attackChargeBuffs, 1, buff:GetBuffId())
end
--[[
移除一个攻击充能buff
@params buff BaseBuff buff指针
--]]
function BaseAttackDriver:RemoveAAttackChargeBuff(buff)
	for i = #self.attackChargeBuffs, 1, -1 do
		if self.attackChargeBuffs[i] ==  buff:GetBuffId() then
			table.remove(self.attackChargeBuffs, i)
			break
		end
	end
end
--[[
添加一个攻击特效
@params attackModifier BaseAttackModifier 攻击特效模型
@params amtType TimeAxisConstants 攻击特效时间类型
--]]
function BaseAttackDriver:AddAAttackModifier(attackModifier, amtType)
	table.insert(self.attackModifiers[amtType], 1, attackModifier:GetAttackModifierTag())
	self.attackModifiers.id[tostring(attackModifier:GetAttackModifierTag())] = attackModifier
end
--[[
移除一个攻击特效
@params attackModifier BaseAttackModifier 攻击特效模型
@params amtType TimeAxisConstants 攻击特效时间类型
@params isDestroy bool 是否彻底销毁攻击特效驱动
--]]
function BaseAttackDriver:RemoveAAttackModifier(attackModifier, amtType, isDestroy)
	local tag = attackModifier:GetAttackModifierTag()

	for i = #self.attackModifiers[amtType], 1, -1 do
		if self.attackModifiers[amtType][i] == tag then
			table.remove(self.attackModifiers[amtType], i)
		end
	end

	if isDestroy then
		self.attackModifiers.id[tostring(tag)] = nil
	end
end
--[[
根据tag获取攻击特效指针
@params tag int 攻击特效tag
@return _ BaseAttackModifier 攻击特效模型
--]]
function BaseAttackDriver:GetAttackModifierByTag(tag)
	return self.attackModifiers.id[tostring(tag)]
end
--[[
根据类型获取攻击特效
@params amType AttackModifierType 攻击特效类型
--]]
function BaseAttackDriver:GetAttackModifierByType(amType)
	for k, v in pairs(self.attackModifiers.id) do
		if v:GetAttackModifierType() == amType then
			return v
		end
	end
	return nil
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

---------------------------------------------------
-- handler logic begin --
---------------------------------------------------
--[[
spine动画事件消息处理
--]]
function BaseAttackDriver:SpineAnimationEventHandler(event)

end
--[[
spine动画自定义事件消息处理
--]]
function BaseAttackDriver:SpineCustomEventHandler(event)

end
---------------------------------------------------
-- handler logic end --
---------------------------------------------------

return BaseAttackDriver

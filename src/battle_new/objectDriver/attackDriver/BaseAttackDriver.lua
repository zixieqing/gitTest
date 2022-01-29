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

	if 0 >= self:GetActionTrigger() then
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
	-- 置为攻击状态
	self:GetOwner():SetState(OState.ATTACKING)

	-- 重置一些攻击消耗的资源
	self:CostActionResources()

	-- 开始攻击动作
	local target = G_BattleLogicMgr:IsObjAliveByTag(targetTag)

	if nil == target then
		self:OnActionExit()
		return
	end

	-- 设置当前攻击目标
	self:SetAttackTargetTag(targetTag)

	-- 初始化影响伤害的外部参数
	local externalDamageParameter = ObjectExternalDamageParameterStruct.New(
		false,
		0,
		{},
		{}
	)

	-- 重置攻击分段
	self:ResetAttackPhase()

	---------- attack modifier ----------
	-- 触发 TimeAxisConstants.TA_ENTER 类型的攻击特效
	local amTag = nil
	local attackModifier = nil

	for i = #self.attackModifiers[TimeAxisConstants.TA_ENTER], 1, -1 do
		
		amTag = self.attackModifiers[TimeAxisConstants.TA_ENTER][i]
		attackModifier = self:GetAttackModifierByTag(amTag)
		
		if attackModifier:CanEnterModifier() then
			
			-- 生效
			attackModifier:OnModifierEnter(1, 1, externalDamageParameter)
			-- 该类型作用后直接结束
			attackModifier:OnModifierExit()

			if attackModifier:IsInvalid() then
				self:RemoveAAttackModifier(attackModifier, TimeAxisConstants.TA_ENTER, true)
			end

		end

	end
	---------- attack modifier ----------

	---------- calculate damage ----------
	-- 如果没有暴击 再roll一次
	if not externalDamageParameter.isCritical then
		local critRate = self:GetOwner():GetMainProperty():GetCriticalRate()
		externalDamageParameter.isCritical = G_BattleLogicMgr:GetRandomManager():GetRandomInt(100) <= critRate and true or false
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
	self:SetDamagePool(
		self:GetOwner():GetMainProperty():GetAttackDamage(self:GetOwner(), target, externalDamageParameter),
		externalDamageParameter.isCritical
	)
	---------- calculate damage ----------

	---------- 多重的逻辑 ----------
	self:OnMultishotEnter(targetTag, externalDamageParameter)
	---------- 多重的逻辑 ----------

	---------- 触发器 ----------
	-- 攻击
	self:GetOwner().triggerDriver:OnActionEnter(ConfigObjectTriggerActionType.ATTACK)
	if externalDamageParameter.isCritical then
		-- 暴击
		self:GetOwner().triggerDriver:OnActionEnter(ConfigObjectTriggerActionType.ATTACK_CRITICAL)
	end
	---------- 触发器 ----------

	---------- view ----------
	local animationData = self:GetOwner():GetActionAnimationConfigBySkillId(ATTACK_2_SKILL_ID)
	-- 处理spine动画
	self:GetOwner():DoAnimation(
		false, nil,
		animationData.actionName, false,
		sp.AnimationName.idle, true
	)
	-- 此处在设置完动画以后进行攻速的缩放
	local actionTimeScale = self:GetOwner():GetAvatarTimeScale()
	self:GetOwner():SetAnimationTimeScale(actionTimeScale)

	-- 更新朝向
	local deltaX = target:GetLocation().po.x - self:GetOwner():GetLocation().po.x
	if deltaX > 0 then
		self:GetOwner():SetOrientation(BattleObjTowards.FORWARD)
	elseif deltaX < 0 then
		self:GetOwner():SetOrientation(BattleObjTowards.NEGATIVE)
	end

	--***---------- 插入刷新渲染层计时器 ----------***--
	-- 刷新朝向
	self:GetOwner():RefreshRenderViewTowards()

	-- 动画
	self:GetOwner():RefreshRenderAnimation(
		false, nil,
		animationData.actionName, false,
		sp.AnimationName.idle, true
	)

	-- 缩放攻速
	G_BattleLogicMgr:AddRenderOperate(
		'G_BattleRenderMgr',
		'ObjectViewSetAnimationTimeScale',
		self:GetOwner():GetViewModelTag(),
		actionTimeScale
	)

	------------ sound effect ------------
	G_BattleLogicMgr:RenderPlayBattleSoundEffect(animationData.actionSE)
	G_BattleLogicMgr:RenderPlayBattleSoundEffect(animationData.actionVoice)
	------------ sound effect ------------
	--***---------- 插入刷新渲染层计时器 ----------***--
	---------- view ----------
end
--[[
@override
结束动作
--]]
function BaseAttackDriver:OnActionExit()
	-- 重置状态
	self:GetOwner():SetState(self:GetOwner():GetState(-1))
	self:GetOwner():SetState(OState.NORMAL, -1)

	---------- attack modifier ----------
	-- 刷新一次攻击特效充能计数 移除不合法的效果
	local attackModifierTag = nil
	local attackModifier = nil

	for i = #self.attackModifiers[TimeAxisConstants.TA_ACTION], 1, -1 do
		attackModifierTag = self.attackModifiers[TimeAxisConstants.TA_ACTION][i]
		attackModifier = self:GetAttackModifierByTag(attackModifierTag)
		if nil ~= attackModifier then
			attackModifier:OnModifierExit()

			if attackModifier:IsInvalid() then
				self:RemoveAAttackModifier(attackModifier, TimeAxisConstants.TA_ACTION, true)
			end
		end
	end

	-- 检查一次攻击充能buff是否需要移除
	local buff = nil
	for i = #self.attackChargeBuffs, 1, -1 do
		buff = self:GetOwner():GetBuffByBuffId(self.attackChargeBuffs[i])
		if nil ~= buff then
			-- 检查buff
			buff:AutoRemoveSelf()
		end
	end
	---------- attack modifier ----------

	---------- view ----------
	-- !! 恢复动画速度 因为攻击动画可能会全局变速 !! --
	local actionTimeScale = self:GetOwner():GetAvatarTimeScale(true)
	self:GetOwner():SetAnimationTimeScale(actionTimeScale)
	self:GetOwner():RefreshRenderAnimationTimeScale(actionTimeScale)
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
	self:SetActionTrigger(math.max(0, self:GetActionTrigger() - dt))
end
--[[
消耗做出行为需要的资源
--]]
function BaseAttackDriver:CostActionResources()
	-- 攻击行为只消耗内置cd
	self:SetActionTrigger(self:GetOwner():GetMainProperty():GetATKCounter())

	-- 攻击回能量
	self:GetOwner():AddEnergy((self:GetOwner():GetMainProperty():GetATKCounter() * ENERGY_PER_ATTACK))

	---------- attack modifier ----------
	self:CostAttackModifierResources()
	---------- attack modifier ----------
end
--[[
消耗攻击特效
--]]
function BaseAttackDriver:CostAttackModifierResources()
	local buffId = nil
	local buff = nil
	local attackModifier = nil

	for i = #self.attackChargeBuffs, 1, -1 do

		buffId = self.attackChargeBuffs[i]
		local buffs = self:GetOwner():GetBuffsByBuffId(buffId, false)

		for j = #buffs, 1, -1 do

			buff = buffs[j]

			-- 为攻击特效充能
			attackModifier = self:GetAttackModifierByTag(buff:GetChargedAMTag())

			if nil ~= attackModifier then

				if buff:IsHaloBuff() then
					-- 光环buff 设置可以生效
					attackModifier:SetCostTimeCanCauseEffect(true)
				else
					-- 非光环buff 消耗一些充能
					buff:AddCharge(-1)
					attackModifier:CostModifierResources()
				end

			else
				BattleUtils.PrintBattleWaringLog('>>>>> here find logic error cannot find am in attack driver but buff now charge it')
			end

		end

	end
end
--[[
重置所有触发器
--]]
function BaseAttackDriver:ResetActionTrigger()
	self:SetActionTrigger(0)
end
--[[
获取触发器
@return _ number 触发器 实际上就是攻击内置cd
--]]
function BaseAttackDriver:GetActionTrigger()
	return self.actionTrigger
end
function BaseAttackDriver:SetActionTrigger(value)
	self.actionTrigger = value
end
--[[
攻击行为
@params targetTag int 攻击对象tag
@params percent number 伤害占比 分段伤害用
--]]
function BaseAttackDriver:Attack(targetTag, percent)
	local target = G_BattleLogicMgr:IsObjAliveByTag(targetTag)

	if nil == target then
		
		-- 如果目标物体非法 重新索敌
		self:GetOwner():SetState(OState.NORMAL)
		return

	end

	local targetViewModelTag = target:GetViewModelTag()
	local ownerTag = self:GetOwner():GetOTag()

	-- 处理攻击分段
	self:SetAttackPhase(self:GetAttackPhase() + 1)
	
	--[[
	new logic todo

	--]]
	-- 创建子弹 首先获取bullet骨骼 存在则是投掷物弹道型的攻击 统一传世界坐标
	local bulletOriPosition = self:GetOwner():GetLocation().po
	local boneData = self:GetOwner():FineBoneInBattleRootSpace(sp.CustomName.BULLET_BONE_NAME)
	if boneData then
		bulletOriPosition = cc.p(boneData.worldPosition.x, boneData.worldPosition.y)
	end

	-- 创建伤害信息
	local damageData = ObjectDamageStruct.New(
		targetTag,
		self:GetDamagePool().damage * percent,
		DamageType.ATTACK_PHYSICAL,
		self:GetDamagePool().isCritical,
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
			multishotTarget = G_BattleLogicMgr:IsObjAliveByTag(multishotTargetTag)

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

	---------- 发射子弹 ----------
	local attackAnimationConfigInfo = self:GetOwner():GetActionAnimationConfigBySkillId(ATTACK_2_SKILL_ID)

	local bulletData = ObjectSendBulletData.New(
		------------ 基本信息 ------------
		nil,
		nil,
		attackAnimationConfigInfo.bulletType,
		attackAnimationConfigInfo.causeType or ConfigEffectCauseType.BASE,
		self:GetOwner():GetOTag(),
		self:GetOwner():GetViewModelTag(),
		targetTag,
		targetViewModelTag,
		false,
		------------ spine动画信息 ------------
		attackAnimationConfigInfo.effectId,
		attackAnimationConfigInfo.effectActionName,
		attackAnimationConfigInfo.effectZOrder,
		bulletOriPosition,
		target:GetLocation().po,
		attackAnimationConfigInfo.effectScale,
		attackAnimationConfigInfo.effectPos,
		self:GetOwner():GetOrientation(),
		false,
		false,
		------------ 数据信息 ------------
		damageData,
		nil,
		function (percent)

			-- 伤害作用回调
			local target = G_BattleLogicMgr:IsObjAliveByTag(targetTag)

			if nil ~= target then

				local damageData_ = damageData:CloneStruct()
				damageData_:SetDamageValue(damageData_.damage * percent)

				-- 目标被攻击
				target:BeAttacked(damageData_)

				---------- attack modifier ----------
				-- 触发 TimeAxisConstants.TA_ACTION 类型的攻击特效
				local owner = G_BattleLogicMgr:IsObjAliveByTag(ownerTag)

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

				---------- 多重的逻辑 ----------
				if self:CanMultishot() then

					for i = #multiDamageDatas, 1, -1 do
						local multishotDamageData_ = multiDamageDatas[i]:CloneStruct()
						multishotDamageData_:SetDamageValue(multishotDamageData_.damage * percent)

						local multishotTarget_ = G_BattleLogicMgr:IsObjAliveByTag(multishotDamageData_.targetTag)
						if nil ~= multishotTarget_ then
							multishotTarget_:BeAttacked(multishotDamageData_)


							------------ view ------------
							-- 显示被击特效
							multishotTarget_:ShowHurtEffect(self:GetOwner():GetActionAnimationConfigBySkillId(ATTACK_2_SKILL_ID).hurtEffectData)
							------------ view ------------
						end
					end

				end
				---------- 多重的逻辑 ----------

				------------ view ------------
				-- 显示被击特效
				target:ShowHurtEffect(self:GetOwner():GetActionAnimationConfigBySkillId(ATTACK_2_SKILL_ID).hurtEffectData)
				------------ view ------------

			end

		end
	)
	---------- 发射子弹 ----------

	------------ sound effect ------------
	local animationData = self:GetOwner():GetActionAnimationConfigBySkillId(ATTACK_2_SKILL_ID)
	G_BattleLogicMgr:RenderPlayBattleSoundEffect(animationData.actionCauseSE)
	------------ sound effect ------------

	G_BattleLogicMgr:SendBullet(bulletData)
end
--[[
为普通攻击索敌
@return _ int 结果 对象tag
--]]
function BaseAttackDriver:SeekAttackTarget()
	---------- logic ----------
	local targets = BattleExpression.GetTargets(self:GetOwner():IsEnemy(), self:GetAttackSeekRule(), self:GetOwner())

	if nil ~= targets then
		local otag = nil
		for _, target in ipairs(targets) do
			otag = target:GetOTag()
			if otag ~= self:GetOwner():GetOTag() then
				self:SetAttackTargetTag(otag)

				BattleUtils.BattleObjectActionLog(self:GetOwner(), '锁定攻击目标 ->', target:GetObjectName())
				break
			end
		end
	end

	if nil ~= self:GetAttackTargetTag() then
		-- 索敌成功 变化物体状态
		self:GetOwner():SetState(OState.BATTLE)
	else
		-- 没有目标
		if sp.AnimationName.run == self:GetOwner():GetCurrentAnimationName() then
			self:GetOwner():DoAnimation(true, nil, sp.AnimationName.idle, true)

			--***---------- 插入刷新渲染层计时器 ----------***--
			-- 动画
			self:GetOwner():RefreshRenderAnimation(
				true, nil, sp.AnimationName.idle, true
			)
			--***---------- 插入刷新渲染层计时器 ----------***--
		end

		BattleUtils.BattleObjectActionLog(self:GetOwner(), '尝试寻找攻击目标 但是未找到攻击目标')
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
	local target = G_BattleLogicMgr:IsObjAliveByTag(targetTag)

	if nil == target then return false end

	local ownerCollisionBox = self:GetOwner():GetStaticCollisionBox()
	local targetCollisionBox = target:GetStaticCollisionBox()

	local judgeX = false
	local judgeY = false

	---------- 纵向判断 ----------
	-- 1 按照分隔原则 物体必须处于和站位分隔同向的相对位置
	-- 2 物体间的距离在分隔距离之内

	local deltaPos = cc.pSub(target:GetLocation().po, self:GetOwner():GetLocation().po)
	local stanceOffYSelf = self:GetOwner().moveDriver:GetStanceOffY()
	local stanceOffYTarget = target.moveDriver:GetStanceOffY()

	if stanceOffYTarget == stanceOffYSelf then

		-- 若相对水平 错开距离
		judgeY = math.abs(deltaPos.y) <= G_BattleLogicMgr:GetCellSize().height * MELEE_STANCE_OFF_Y * 0.5

	elseif deltaPos.y * (stanceOffYTarget - stanceOffYSelf) >= 0 then

		local fixedStanceOffY = math.abs(stanceOffYSelf - stanceOffYTarget) * G_BattleLogicMgr:GetCellSize().height * MELEE_STANCE_OFF_Y
		judgeY = math.abs(deltaPos.y) >= fixedStanceOffY * 0.8 and math.abs(deltaPos.y) <= fixedStanceOffY * 1.2

	end
	---------- 纵向判断 ----------

	---------- 横向判断 ----------
	local ownerBorderX = nil
	local targetBorderX = nil

	if target:GetLocation().po.x - self:GetOwner():GetLocation().po.x > 0 then

		-- 目标在右侧
		ownerBorderX = self:GetOwner():GetLocation().po.x + ownerCollisionBox.x + ownerCollisionBox.width
		targetBorderX = target:GetLocation().po.x + targetCollisionBox.x

		judgeX = (ownerBorderX >= targetBorderX) or
			(self:GetOwner():GetMainProperty().p.attackRange * G_BattleLogicMgr:GetCellSize().width > math.abs(targetBorderX - ownerBorderX))

	else

		-- 目标在左侧
		ownerBorderX = self:GetOwner():GetLocation().po.x + ownerCollisionBox.x
		targetBorderX = target:GetLocation().po.x + targetCollisionBox.x + targetCollisionBox.width

		judgeX = (ownerBorderX <= targetBorderX) or
			(self:GetOwner():GetMainProperty().p.attackRange * G_BattleLogicMgr:GetCellSize().width > math.abs(targetBorderX - ownerBorderX))

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

	if sp.AnimationName.run == self:GetOwner():GetCurrentAnimationName() then
		self:GetOwner():DoAnimation(true, nil, sp.AnimationName.idle, true)

		--***---------- 插入刷新渲染层计时器 ----------***--
		-- 动画
		self:GetOwner():RefreshRenderAnimation(
			true, nil, sp.AnimationName.idle, true
		)
		--***---------- 插入刷新渲染层计时器 ----------***--
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
		local mainTarget = G_BattleLogicMgr:IsObjAliveByTag(mainTargetTag)
		if nil == mainTarget then return end
		------------ 如果主目标死亡 多重直接失效 ------------

		------------ 多重有效 进行索敌 ------------
		local targets = BattleExpression.GetTargets(mainTarget:IsEnemy(true), seekRule, mainTarget)
		------------ 多重有效 进行索敌 ------------

		------------ 初始化多重目标信息 ------------
		local targetsTag = {}
		local multishotDamageRatio = self:GetMultishotDamageRatio()

		local tTag = nil
		for _, target in ipairs(targets) do
			tTag = target:GetOTag()
			table.insert(targetsTag, 1, tTag)

			local damageInfo = {
				damage = self:GetOwner():GetMainProperty():GetAttackDamage(self:GetOwner(), target, externalDamageParameter) * multishotDamageRatio,
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
--[[
获取当前攻击分段
--]]
function BaseAttackDriver:GetAttackPhase()
	return self.phase
end
function BaseAttackDriver:SetAttackPhase(phase)
	self.phase = phase
end
function BaseAttackDriver:ResetAttackPhase()
	self:SetAttackPhase(0)
end
--[[
获取当前伤害池
--]]
function BaseAttackDriver:GetDamagePool()
	return self.damagePool
end
function BaseAttackDriver:SetDamagePool(damage, isCritical)
	self.damagePool = {damage = damage, isCritical = isCritical}
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

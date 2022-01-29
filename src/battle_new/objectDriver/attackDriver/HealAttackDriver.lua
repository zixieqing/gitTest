--[[
治疗攻击行为驱动
--]]
local BaseAttackDriver = __Require('battle.objectDriver.attackDriver.BaseAttackDriver')
local HealAttackDriver = class('HealAttackDriver', BaseAttackDriver)

---------------------------------------------------
-- override begin --
---------------------------------------------------
--[[
@override
初始化逻辑
--]]
function HealAttackDriver:Init()
	BaseAttackDriver.Init(self)

	-- 初始化分段治疗池
	self.healPool = nil

	---------- 治疗索敌规则 ----------
	-- 治疗索敌规则
	self.oriHealSeekRule = SeekRuleStruct.New(ConfigSeekTargetRule.T_OBJ_FRIEND, SeekSortRule.S_FOR_HEAL, 1)
	self.healSeekRuleInfo = {
		self.oriHealSeekRule
	}
	---------- 治疗索敌规则 ----------
end
--[[
是否能进行动作
@return result bool 是否可以攻击
--]]
function HealAttackDriver:CanDoAction()
	local result = false
	if 0 >= self:GetActionTrigger() then
		-- 攻击间隔满足 返回
		result = true
	end
	return result
end
--[[
为普通攻击索敌
@return _ int 结果 对象tag
--]]
function HealAttackDriver:SeekAttackTarget()
	local targets = BattleExpression.GetTargets(self:GetOwner():IsEnemy(), self:GetHealSeekRule(), self:GetOwner())

	if 1 >= G_BattleLogicMgr:GetBData():GetAliveObjectAmount(self:GetOwner():IsEnemy(true)) then
		-- 如果场上友方只剩自己 则走平a逻辑
		BaseAttackDriver.SeekAttackTarget(self)
	else
		---------- logic ----------
		local otag = nil
		for i, target in ipairs(targets) do
			otag = target:GetOTag()
			self:SetAttackTargetTag(otag)

			BattleUtils.BattleObjectActionLog(self:GetOwner(), '锁定治疗目标 ->', target:GetObjectName())
			break
		end

		if nil ~= self:GetAttackTargetTag() then
			self:GetOwner():SetState(OState.BATTLE)
		else
			BattleUtils.BattleObjectActionLog(self:GetOwner(), '尝试寻找治疗目标 但是未找到攻击目标')

			---------- view ----------
			-- 如果索不到可攻击目标并且处于移动中 停掉移动动作
			if nil == self:GetAttackTargetTag() and sp.AnimationName.run == self:GetOwner():GetCurrentAnimationName() then
				self:GetOwner():DoAnimation(true, nil, sp.AnimationName.idle, true)

				--***---------- 插入刷新渲染层计时器 ----------***--
				-- 动画
				self:GetOwner():RefreshRenderAnimation(
					true, nil, sp.AnimationName.idle, true
				)
				--***---------- 插入刷新渲染层计时器 ----------***--
			end
			---------- view ----------
		end
		---------- logic ----------
	end
end
--[[
进入动作
@params targetTag int 攻击对象tag
--]]
function HealAttackDriver:OnActionEnter(targetTag)
	---------- logic ----------
	-- 置为攻击状态
	self:GetOwner():SetState(OState.ATTACKING)

	-- 重置攻击间隔
	self:CostActionResources()

	-- 开始进行攻击动作
	local target = G_BattleLogicMgr:IsObjAliveByTag(targetTag)

	if nil == target then
		self:OnActionExit()
		return
	end

	-- 设置当前攻击目标
	self:SetAttackTargetTag(targetTag)

	-- 影响伤害的外部参数
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

	-- TODO --
	--[[
	此处存在问题 这里初始化伤害池和治疗池时判断的敌友性是瞬时的 在实际分段动画造成效果时会另外判断一次敌友性读取伤害池或者治疗池
	这里暂时同时初始化伤害池和治疗池
	--]] 
	-- 重置治疗池
	self:SetHealPool(
		self:GetOwner():GetMainProperty():GetFixedHealing(externalDamageParameter),
		externalDamageParameter.isCritical
	)

	-- 重置伤害池
	self:SetDamagePool(
		self:GetOwner():GetMainProperty():GetAttackDamage(self:GetOwner(), target, externalDamageParameter),
		externalDamageParameter.isCritical
	)
	-- TODO --
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

	---------- logic ----------

	---------- view ----------
	local animationData = self:GetOwner():GetActionAnimationConfigBySkillId(ATTACK_2_SKILL_ID)
	-- 处理spine动画
	self:GetOwner():DoAnimation(
		false, nil,
		animationData.actionName, false,
		sp.AnimationName.idle, true
	)
	local actionTimeScale = self:GetOwner():GetAvatarTimeScale()
	self:GetOwner():SetAnimationTimeScale(actionTimeScale)

	--***---------- 插入刷新渲染层计时器 ----------***--
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

	-- 更新朝向
	local deltaX = target:GetLocation().po.x - self:GetOwner():GetLocation().po.x
	if deltaX > 0 then
		self:GetOwner():SetOrientation(BattleObjTowards.FORWARD)
	elseif deltaX < 0 then
		self:GetOwner():SetOrientation(BattleObjTowards.NEGATIVE)
	end
	---------- view ----------
end
--[[
攻击行为
@params targetTag int 攻击对象tag
@params percent number 伤害占比 分段伤害用
--]]
function HealAttackDriver:Attack(targetTag, percent)
	local target = G_BattleLogicMgr:IsObjAliveByTag(targetTag)

	if nil == target then
		-- 如果对象为空 重新索敌
		self:GetOwner():SetState(OState.NORMAL)
		return
	end

	local targetViewModelTag = target:GetViewModelTag()

	local ownerTag = self:GetOwner():GetOTag()

	-- 如果target是敌方 走平A逻辑 如果是友方 走治疗逻辑
	if self:IsHealTarget(targetTag) then

		-- 创建子弹 首先获取bullet骨骼 存在则是投掷物弹道型的攻击
		local bulletOriPosition = self:GetOwner():GetLocation().po
		local boneData = self:GetOwner():FineBoneInBattleRootSpace(sp.CustomName.BULLET_BONE_NAME)
		if boneData then
			bulletOriPosition = cc.p(boneData.worldPosition.x, boneData.worldPosition.y)
		end

		local damageData = ObjectDamageStruct.New(
			targetTag,
			self:GetHealPool().damage * percent,
			DamageType.ATTACK_HEAL,
			self:GetHealPool().isCritical,
			{healerTag = ownerTag}
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
						DamageType.ATTACK_HEAL,
						multishotDamageInfo.isCritical,
						{healerTag = ownerTag}
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

				local target = G_BattleLogicMgr:IsObjAliveByTag(targetTag)

				if nil ~= target then

					local damageData_ = damageData:CloneStruct()
					damageData_:SetDamageValue(damageData_.damage * percent)

					------------ logic ------------
					-- 目标被治疗
					target:BeHealed(damageData_)

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

					---------- 触发器 ----------
					self:GetOwner().triggerDriver:OnActionEnter(ConfigObjectTriggerActionType.ATTACK_HIT)
					---------- 触发器 ----------
					
					------------ logic ------------

					---------- 多重的逻辑 ----------
					if self:CanMultishot() then

						for i = #multiDamageDatas, 1, -1 do
							local multishotDamageData_ = multiDamageDatas[i]:CloneStruct()
							multishotDamageData_:SetDamageValue(multishotDamageData_.damage * percent)

							local multishotTarget_ = G_BattleLogicMgr:IsObjAliveByTag(multishotDamageData_.targetTag)
							if nil ~= multishotTarget_ then
								multishotTarget_:BeHealed(multishotDamageData_)

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

	else
		BaseAttackDriver.Attack(self, targetTag, percent)
	end
end
--[[
@override
结束动作
--]]
function HealAttackDriver:OnActionExit()
	BaseAttackDriver.OnActionExit(self)

	-- 此处为治疗重新索敌
	-- self:GetOwner():setState(OState.NORMAL)
	self:SeekAttackTarget()
end
--[[
@override
是否可以攻击 距离判定
@params targetTag int 攻击对象tag
@return _ bool 距离上是否满足攻击条件
--]]
function HealAttackDriver:CanAttackByDistance(targetTag)
	local target = G_BattleLogicMgr:IsObjAliveByTag(targetTag)

	if nil == target then return false end

	local deltaC = math.abs(self:GetOwner():GetLocation().rc.c - target:GetLocation().rc.c)

	return deltaC <= self:GetOwner():GetMainProperty().p.attackRange
end
--[[
根据目标tag判断此次是治疗还是伤害
@params targetTag int 目标tag
@return _ bool 是否治疗
--]]
function HealAttackDriver:IsHealTarget(targetTag)
	local target = G_BattleLogicMgr:IsObjAliveByTag(targetTag)
	if nil == target then
		return false
	else
		return self:GetOwner():IsEnemy() == target:IsEnemy(true)
	end
end
--[[
获取治疗的索敌规则
@return _ SeekRuleStruct 索敌规则
--]]
function HealAttackDriver:GetHealSeekRule()
	return self.healSeekRuleInfo[1]
end
--[[
改变治疗索敌规则
@params newSeekRule SeekRuleStruct 新的索敌规则
--]]
function HealAttackDriver:GainHealSeekRule(newSeekRule)
	-- 插入新的索敌规则
	table.insert(self.healSeekRuleInfo, 1, newSeekRule)
	-- 重新索敌
	self:LostAttackTarget()
end
--[[
失去治疗索敌规则
@params seekRule SeekRuleStruct 索敌规则
--]]
function HealAttackDriver:LostHealSeekRule(seekRule)
	local targetID = ID(seekRule)
	local needResearch = false
	for i = #self.healSeekRuleInfo, 1, -1 do
		if targetID == ID(self.healSeekRuleInfo[i]) then
			-- 移除当前索敌规则
			table.remove(self.healSeekRuleInfo, i)
			if 1 == i then
				needResearch = true
			end
			break
		end
	end
	if needResearch and seekRule ~= self:GetHealSeekRule() then
		-- 重新索敌
		self:LostAttackTarget()
	end
end
---------------------------------------------------
-- override end --
---------------------------------------------------

---------------------------------------------------
-- multishot begin --
---------------------------------------------------
--[[
开始多重的逻辑
@params mainTargetTag int 主要攻击对象tag
@params externalDamageParameter ObjectExternalDamageParameterStruct 伤害参数
--]]
function HealAttackDriver:OnMultishotEnter(mainTargetTag, externalDamageParameter)
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

			-- 计算伤害
			local damage = nil
			if self:GetOwner():IsEnemy() == target:IsEnemy(true) then
				damage = self:GetOwner():GetMainProperty():GetFixedHealing(externalDamageParameter)
			else
				damage = self:GetOwner():GetMainProperty():GetAttackDamage(self:GetOwner(), target, externalDamageParameter)
			end

			local damageInfo = {
				damage = damage * multishotDamageRatio,
				isCritical = externalDamageParameter.isCritical
			}

			self:SetMultishotDamagePoolInfoByTag(tTag, damageInfo)
		end

		self:SetMultishotTargets(targetsTag)
		------------ 初始化多重目标信息 ------------		
	end
end
---------------------------------------------------
-- multishot end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
获取当前伤害池
--]]
function BaseAttackDriver:GetHealPool()
	return self.healPool
end
function BaseAttackDriver:SetHealPool(damage, isCritical)
	self.healPool = {damage = damage, isCritical = isCritical}
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return HealAttackDriver

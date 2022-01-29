--[[
战斗物体的基类
--]]
local BaseObjectModel = __Require('battle.object.logicModel.objectModel.BaseObjectModel')
local CardObjectModel = class('CardObjectModel', BaseObjectModel)

------------ import ------------
------------ import ------------

------------ define ------------
------------ define ------------

--[[
constructor
--]]
function CardObjectModel:ctor( ... )
	BaseObjectModel.ctor(self, ...)
end

---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
初始化
--]]
function CardObjectModel:Init()
	BaseObjectModel.Init(self)

	------------ 初始化物体监听事件 ------------
	self:RegisterObjectEventHandler()
	------------ 初始化物体监听事件 ------------
end
--[[
初始化数值
--]]
function CardObjectModel:InitValue()
	BaseObjectModel.InitValue(self)
end
--[[
初始化固有属性
--]]
function CardObjectModel:InitInnateProperty()
	BaseObjectModel.InitInnateProperty(self)
end
--[[
初始化特有属性
--]]
function CardObjectModel:InitUnitProperty()
	------------ location info ------------
	self.location = ObjectLocation.New(
		self:GetObjInfo().oriLocation.po.x,
		self:GetObjInfo().oriLocation.po.y,
		self:GetObjInfo().oriLocation.po.r,
		self:GetObjInfo().oriLocation.po.c
	)

	self.zorderInBattle = 0
	------------ location info ------------

	------------ energy info ------------
	self:InitEnergy()

	-- 刷新一次生命百分比
	self:GetMainProperty():UpdateCurHpPercent()
	------------ energy info ------------

	------------ other info ------------
	-- 仇恨
	self.hate = checkint(self:GetObjectConfig().threat or 0)
	------------ other info ------------
end
--[[
@override
初始化物体的动作动画信息
--]]
function CardObjectModel:InitActionAnimationConfig()
	BaseObjectModel.InitActionAnimationConfig(self)

	local effect = self:GetObjectEffectConfig()
	local attackAnimationConfig = BSCUtils.GetSkillSpineEffectStruct(ATTACK_2_SKILL_ID, effect, G_BattleLogicMgr:GetCurrentWave(), self:GetObjectSkinId())
	self:SetActionAnimationConfigBySkillId(ATTACK_2_SKILL_ID, attackAnimationConfig)
end
--[[
@override
初始化展示层模型
--]]
function CardObjectModel:InitViewModel()
	local skinId = self:GetObjectSkinId()
	local skinConfig = CardUtils.GetCardSkinConfig(skinId)

	local spineDataStruct = BattleUtils.GetAvatarSpineDataStructBySpineId(
		skinConfig.spineId,
		G_BattleLogicMgr:GetSpineAvatarScaleByCardId(self:GetObjectConfigId())
	)
	assert(spineDataStruct, '\n\t\t !!! conf by [cards.avatarSpine] is null >> ' .. tostring(skinConfig.spineId) .. ' !!!')

	local viewModel = __Require('battle.viewModel.SpineViewModel').new(
		ObjectViewModelConstructorStruct.New(
			G_BattleLogicMgr:GetBData():GetTagByTagType(BattleTags.BT_VIEW_MODEL),
			self:GetOTag(),
			self:GetObjInfo().avatarScale,
			spineDataStruct
		)
	)
	self:SetViewModel(viewModel)

	-- 注册spine事件
	self:RegistViewModelEventHandler()

	-- 向内存中添加一个展示层模型
	viewModel:Awake()

	-- 刷新初始坐标
	self:ChangePosition(self:GetObjInfo().oriLocation.po)

	-- 刷新初始朝向
	if self:IsEnemy(true) then
		self:SetOrientation(BattleObjTowards.NEGTIVE)
	else
		self:SetOrientation(BattleObjTowards.FORWARD)
	end
end
--[[
初始化驱动组件
--]]
function CardObjectModel:InitDrivers()
	-- 随机数驱动器
	self.randomDriver = __Require('battle.object.RandomDriver').new({
		ownerTag = self:GetOTag()
	})

	-- 攻击驱动器 移动启动器
	local attackDriverClassName = 'BaseAttackDriver'
	local moveDriverClassName = 'BaseMoveDriver'

	local objectFeature = self:GetObjectFeature()

	if BattleObjectFeature.REMOTE == objectFeature then

		attackDriverClassName = 'RemoteAttackDriver'
		moveDriverClassName = 'RemoteMoveDriver'

	elseif BattleObjectFeature.HEALER == objectFeature then

		attackDriverClassName = 'HealAttackDriver'
		moveDriverClassName = 'RemoteMoveDriver'

	end

	self.attackDriver = __Require(string.format('battle.objectDriver.attackDriver.%s', attackDriverClassName)).new({owner = self})
	self.moveDriver = __Require(string.format('battle.objectDriver.moveDriver.%s', moveDriverClassName)).new({owner = self})

	-- 施法驱动器
	self.castDriver = __Require('battle.objectDriver.castDriver.BaseCastDriver').new({owner = self})

	-- 传染驱动器
	self.infectDriver = __Require('battle.objectDriver.castDriver.BaseInfectDriver').new({owner = self})

	-- 触发驱动器
	self.triggerDriver = __Require('battle.objectDriver.castDriver.BaseTriggerDriver').new({owner = self})

	-- 阶段转换启动器
	self.phaseDriver = nil
	if nil ~= self:GetObjInfo().phaseChangeData then
		self.phaseDriver = __Require('battle.objectDriver.performanceDriver.BasePhaseDriver').new({owner = self, phaseChangeData = self:GetObjInfo().phaseChangeData})
	end
	self:GetObjInfo().phaseChangeData = nil

	-- 变色驱动器
	self.tintDriver = __Require('battle.objectDriver.performanceDriver.BaseTintDriver').new({owner = self})

	-- 神器天赋驱动器
	self.artifactTalentDriver = __Require('battle.objectDriver.castDriver.BaseArtifactTalentDriver').new({owner = self, talentData = self:GetObjInfo().talentData})

	-- 超能力驱动器
	self.exAbilityDriver = __Require('battle.objectDriver.performanceDriver.BaseEXAbilityDriver').new({owner = self, exAbilityData = self:GetObjInfo().exAbilityData})

	-- buff驱动器
	self.buffDriver = __Require('battle.objectDriver.buffDriver.BaseBuffDriver').new({owner = self})

	-- 激活一次驱动器
	self:ActivateDrivers()
end
--[[
激活一次驱动器
--]]
function CardObjectModel:ActivateDrivers()
	-- 激活一次神器天赋驱动器
	self.artifactTalentDriver:OnActionEnter()
end
--[[
初始化技能免疫
--]]
function CardObjectModel:InitInnerBuffImmune()
	local cardConfig = self:GetObjectConfig()
	if nil ~= cardConfig and nil ~= cardConfig.immunitySkillProperty then
		self:GetObjectExtraStateInfo():InitInnerBuffImmune(cardConfig.immunitySkillProperty)
	end
end
--[[
初始化天气免疫
--]]
function CardObjectModel:InitWeatherImmune()
	local cardConfig = self:GetObjectConfig()
	if nil ~= cardConfig and nil ~= cardConfig.weatherProperty then
		self:GetObjectExtraStateInfo():InitWeatherImmune(cardConfig.weatherProperty)
	end
end
--[[
初始化能量
--]]
function CardObjectModel:InitEnergy()
	self.energy = self:GetMainProperty():CalcFixedInitEnergy(self:GetObjInfo().isLeader)
	self.energyRecoverRate = 0
end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- state begin --
---------------------------------------------------
--[[
@override
唤醒物体
--]]
function CardObjectModel:AwakeObject()
	self:SetState(OState.NORMAL)

	---------- 触发器 ----------
	-- 物体被唤醒
	self.triggerDriver:OnActionEnter(ConfigObjectTriggerActionType.OBJECT_AWAKE)
	---------- 触发器 ----------
end
--[[
@override
暂停
--]]
function CardObjectModel:PauseLogic()
	BaseObjectModel.PauseLogic(self)

	local timeScale = self:GetAvatarTimeScale()

	self:SetAnimationTimeScale(timeScale)

	--***---------- 刷新渲染层 ----------***--
	G_BattleLogicMgr:AddRenderOperate(
		'G_BattleRenderMgr',
		'PauseAObjectView',
		self:GetViewModelTag(),
		timeScale
	)
	--***---------- 刷新渲染层 ----------***--
end
--[[
@override
恢复物体
--]]
function CardObjectModel:ResumeLogic()
	BaseObjectModel.ResumeLogic(self)

	local timeScale = self:GetAvatarTimeScale()

	self:SetAnimationTimeScale(timeScale)

	--***---------- 刷新渲染层 ----------***--
	G_BattleLogicMgr:AddRenderOperate(
		'G_BattleRenderMgr',
		'ResumeAObjectView',
		self:GetViewModelTag(),
		timeScale
	)
	--***---------- 刷新渲染层 ----------***--
end
--[[
@override
内部判断物体是否还存活
@return _ bool 是否存活
--]]
function CardObjectModel:IsAlive()
	return OState.DIE ~= self:GetState()
end
--[[
@override
使物体处于异常状态
@params abnormalState AbnormalState 异常状态
@params b bool 是否设置成异常状态
--]]
function CardObjectModel:SetObjectAbnormalState(abnormalState, b)
	BaseObjectModel.SetObjectAbnormalState(self, abnormalState, b)

	---------- 刷新连携技按钮状态 ----------
	self:RefreshConnectButtonsByState()
	---------- 刷新连携技按钮状态 ----------
end
--[[
打断当前状态
--]]
function CardObjectModel:BreakCurrentAction()
	if OState.CASTING == self:GetState() then
		self.castDriver:OnActionBreak()
	elseif OState.ATTACKING == self:GetState() then
		self.attackDriver:OnActionBreak()
	elseif OState.VIEW_TRANSFORM == self:GetState() then
		if nil ~= self.exAbilityDriver then
			self.exAbilityDriver:OnViewTransformBreak()
		end
	end
end
---------------------------------------------------
-- state end --
---------------------------------------------------

---------------------------------------------------
-- logic begin --
---------------------------------------------------
--[[
@override
主循环逻辑
--]]
function CardObjectModel:Update(dt)
	-- print('\n///////////////////////////////')
	-- 暂停直接返回
	if self:IsPause() then return end

	------------ 死亡判定 ------------
	local needReturnUpdate = self:DieJudge()
	if needReturnUpdate then
		return
	end
	------------ 死亡判定 ------------

	-- 刷新一些计时器
	self:UpdateCountdown(dt)

	-- 刷新驱动器
	self:UpdateDrivers(dt)

	-- 刷新一次所有buff和光环
	self:UpdateBuffs(dt)

	-- 自动行为逻辑
	self:AutoController(dt)
	-- print('\n\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\')
end
--[[
死亡判定
@return needReturnUpdate bool 是否需要直接阻塞update
--]]
function CardObjectModel:DieJudge()
	local needReturnUpdate = false

	if self:CanDie() then

		if nil ~= self.phaseDriver then

			local diePhaseChangeCounter = self.phaseDriver:GetDiePhaseChangeCounter()

			if nil == diePhaseChangeCounter then

				-- 第一次死亡 处理一些死亡触发的转阶段数据
				-- 刷新一次触发器
				self.phaseDriver:UpdateActionTrigger(ActionTriggerType.DIE, true)

				-- 查找可以触发的阶段转换信息
				local canChangePhaseIndexs = self.phaseDriver:CanDoActionWhenDie()
				self.phaseDriver:SetDiePhaseChangeCounter(#canChangePhaseIndexs)

				local pcdata = nil
				for i, canChangePhaseIndex in ipairs(canChangePhaseIndexs) do
					pcdata = self.phaseDriver:GetPCDataByIndex(canChangePhaseIndex)
					local phaseChangeInfo = ObjectPhaseSturct.New(
						self:GetOTag(), pcdata.phaseId, canChangePhaseIndex, true, pcdata.phaseTriggerDelayTime
					)
					local needPauselLogic = self.phaseDriver:NeedToPauseMainLogic(pcdata.phaseType)
					G_BattleLogicMgr:AddAPhaseChange(needPauselLogic, phaseChangeInfo)
					-- 插入准备序列中 将宿主转阶段信息移除
					self.phaseDriver:CostActionResources(canChangePhaseIndex)
				end

				return true


			elseif 0 < diePhaseChangeCounter then

				-- 存在剩余死亡触发的阶段转换 阻塞死亡
				return true

			end

		end

		-- 触发死亡触发器
		self.triggerDriver:OnActionEnter(ConfigObjectTriggerActionType.DEAD)
		-- 开始死亡
		self:DieBegin()

		needReturnUpdate = true

	end

	return needReturnUpdate
end
--[[
刷新一些计时器
--]]
function CardObjectModel:UpdateCountdown(dt)
	-- 刷新计时器
	for k,v in pairs(self.countdowns) do
		self.countdowns[k] = math.max(v - dt, 0)
	end

	------------ 检测计时器带来的变化 ------------
	if 0 >= self.countdowns.energy then
		-- 能量计时器 
		self.countdowns.energy = 1
		self:AddEnergy(self:GetEnergyRecoverRatePerS())
		BattleUtils.BattleObjectActionLog(self, 'UpdateCountdown --> AddEnergy', self:GetEnergyRecoverRatePerS(), G_BattleLogicMgr:GetBData():GetLogicFrameIndex() )
	end
	------------ 检测计时器带来的变化 ------------
end
--[[
刷新驱动器
--]]
function CardObjectModel:UpdateDrivers(dt)
	-- 变色驱动器
	self.tintDriver:OnActionUpdate(dt)

	-- 传染驱动器
	self.infectDriver:UpdateActionTrigger(ActionTriggerType.CD, dt)

	-- 攻击驱动器
	self.attackDriver:UpdateActionTrigger(dt)

	-- 施法驱动器
	self.castDriver:UpdateActionTrigger(ActionTriggerType.CD, dt)

	-- buff驱动器
	self.buffDriver:UpdateActionTrigger(ActionTriggerType.CD, dt)

	-- 阶段转换驱动器
	if self.phaseDriver then

		-- 刷新时间触发器
		self.phaseDriver:UpdateActionTrigger(ActionTriggerType.CD, dt)

		-- 查找可以进行的阶段转换数据
		local canChangePhaseIndex = self.phaseDriver:CanDoAction()
		if nil ~= canChangePhaseIndex then
			local pcdata = self.phaseDriver:GetPCDataByIndex(canChangePhaseIndex)
			local phaseChangeInfo = ObjectPhaseSturct.New(
				self:GetOTag(), pcdata.phaseId, canChangePhaseIndex, false, pcdata.phaseTriggerDelayTime
			)
			local needPauselLogic = self.phaseDriver:NeedToPauseMainLogic(pcdata.phaseType)
			G_BattleLogicMgr:AddAPhaseChange(needPauselLogic, phaseChangeInfo)
			-- 插入准备序列中 将宿主转阶段信息移除
			self.phaseDriver:CostActionResources(canChangePhaseIndex)
		end

	end
end
--[[
刷新一次所有buff和光环
--]]
function CardObjectModel:UpdateBuffs(dt)
	for i = #self.halos.idx, 1, -1 do
		self.halos.idx[i]:OnBuffUpdateEnter(dt)
	end

	for i = #self.buffs.idx, 1, -1 do
		if self.buffs.idx[i] then
			self.buffs.idx[i]:OnBuffUpdateEnter(dt)
		end
	end
end
--[[
自动行为逻辑
--]]
function CardObjectModel:AutoController(dt)
	-- 不能行动的情况直接返回
	if not self:CanAct() then return end

	if OState.NORMAL == self:GetState() then

		BattleUtils.BattleObjectActionLog(self, '正常状态 开始索敌')
		-- 正常状态 索敌一次
		self:SeekAttakTarget()

	elseif OState.BATTLE == self:GetState() then

		BattleUtils.BattleObjectActionLog(self, '战斗状态 进一步逻辑')
		-- 处于战斗状态 走战斗逻辑
		self:Battle(dt)

	elseif OState.MOVING == self:GetState() then

		-- 移动状态 判断是否满足可以攻击的距离
		if self.attackDriver:CanAttackByDistance(self.attackDriver:GetAttackTargetTag()) then

			BattleUtils.BattleObjectActionLog(self, '移动到位 结束移动状态')
			-- 结束移动动作
			self.moveDriver:OnActionExit()

		else

			BattleUtils.BattleObjectActionLog(self, '移动中.....')
			-- 继续移动
			self:Move(dt, self.attackDriver:GetAttackTargetTag())

		end

	elseif OState.MOVE_BACK == self:GetState() then

		-- 处于需要移动不可交战的状态 让obj走回战场
		self.moveDriver:OnMoveBackUpdate(dt)

	elseif OState.MOVE_FORCE == self:GetState() then

		-- 处于需要移动不可交战的状态 让obj走回战场
		self.moveDriver:OnForceMoveUpdate(dt)

	elseif 0 == self.castDriver:IsInChanting() then

		self.castDriver:OnChantExit(self.castDriver:GetCastingSkillId())

	else

		BattleUtils.BattleObjectActionLog(self, '其他状态 等待进一步处理', self:GetState())

	end
end
--[[
战斗逻辑
--]]
function CardObjectModel:Battle(dt)
	local canCastSkillId = nil

	-- 首先判断是否满足cd条件释放技能
	canCastSkillId = self.castDriver:CanDoAction(ActionTriggerType.CD)

	if nil ~= canCastSkillId then

		BattleUtils.BattleObjectActionLog(self, '寻找到了cd准备完成的技能 准备 [释放技能] ', canCastSkillId)

		self:Cast(canCastSkillId)

	else

		local attackTargetTag = self.attackDriver:GetAttackTargetTag()

		if nil == G_BattleLogicMgr:IsObjAliveByTag(attackTargetTag) then

			BattleUtils.BattleObjectActionLog(self, '之前的攻击对象失效 尝试重新 [寻找攻击对象] ')

			-- 如果攻击对象不存在 重新索敌
			self:SetState(OState.NORMAL)
			self:SeekAttakTarget()

		else

			-- 已经存在攻击对象 判断距离是否满足
			local canAttack = self.attackDriver:CanAttackByDistance(attackTargetTag)
			if true == canAttack then

				-- 距离满足 判断攻击cd
				canAttack = self.attackDriver:CanDoAction()

				if true == canAttack then

					-- 满足攻击条件
					canCastSkillId = self.castDriver:CanDoAction(ActionTriggerType.ATTACK)

					if nil ~= canCastSkillId then
						BattleUtils.BattleObjectActionLog(self, '满足攻击判定 但是触发了攻击技能 准备 [释放攻击技能] ')
						-- 释放攻击触发的技能
						self:Cast(canCastSkillId)
					else
						BattleUtils.BattleObjectActionLog(self, '满足攻击判定 准备进行 [普通攻击] ', attackTargetTag)
						-- 没有可以释放的技能 走平a逻辑
						self:Attack(attackTargetTag)
					end

				end

			else

				BattleUtils.BattleObjectActionLog(self, '攻击目标还未进入攻击射程内.......准备开始 [移动] ', attackTargetTag)
				-- 距离上不满足
				self.moveDriver:OnActionEnter(attackTargetTag)

			end


		end

	end
end
---------------------------------------------------
-- logic end --
---------------------------------------------------

---------------------------------------------------
-- attack logic begin --
---------------------------------------------------
--[[
@override
索敌
--]]
function CardObjectModel:SeekAttakTarget()
	self.attackDriver:SeekAttackTarget()
end
--[[
@override
失去攻击目标
--]]
function CardObjectModel:LostAttackTarget()
	self.attackDriver:LostAttackTarget()
end
--[[
@override
获取平a的射程
@return col int 单位列
--]]
function CardObjectModel:GetAttackRange()
	return self:GetMainProperty():GetCurrentAttackRange()
end
--[[
@override
攻击
@params targetTag int 攻击对象tag
--]]
function CardObjectModel:Attack(targetTag)
	self.attackDriver:OnActionEnter(targetTag)
end
--[[
@override
获取移动速度
@return _ number 像素
--]]
function CardObjectModel:GetMoveSpeed()
	return self:GetMainProperty():GetCurrentMoveSpeed()
end
--[[
@override
被攻击
@params damageData ObjectDamageStruct
@params noTrigger bool 不触发任何触发器
--]]
function CardObjectModel:BeAttacked(damageData, noTrigger)
	if not self:IsAlive() or 0 >= self:GetMainProperty():GetCurrentHp() then return end

	BattleUtils.BattleObjectActionLog(
		self,
		'从这个人那获得了伤害', damageData.attackerTag,
		'伤害值:',damageData.damage,
		'技能id:', damageData.skillInfo and damageData.skillInfo.skillId
	)

	-- 被攻击时增加能量
	self:AddEnergy(ENERGY_PER_HURT)

	local damage = damageData.damage
	local shieldEffect = 0

	if 0 < damage then

		-- 是否免疫伤害
		if self:DamageImmuneByDamageType(damageData.damageType) then
			return
		end

		---------- 根据护盾计算伤害抵消 ----------
		damage, shieldEffect = self:CalcFixedDamageByShield(damage)
		---------- 根据护盾计算伤害抵消 ----------

	else

		-- 暂不处理

	end

	---------- 修正最终减伤 ----------
	damage = self:CalcFixedDamageByObjPP(damage, damageData)
	---------- 修正最终减伤 ----------

	if 0 == damage then return end

	---------- 由buff效果产生的伤害抵消 ----------
	damage = self:CalcFixedDamageByBuff(damage, damageData)
	---------- 由buff效果产生的伤害抵消 ----------

	if 0 == damage then return end

	-- 重新记录一次经过各种减免效果以后的伤害值
	damageData:SetDamageValue(damage)

	---------- skada ----------
	local trueDamage = self:CalcObjectGotTrueDamage(damageData:GetDamageValue())

	-- 物体承受的伤害
	G_BattleLogicMgr:SkadaWork(
		SkadaType.GOT_DAMAGE,
		self:GetOTag(), damageData, trueDamage
	)

	-- 物体造成的伤害
	G_BattleLogicMgr:SkadaWork(
		SkadaType.DAMAGE,
		damageData:GetSourceObjTag(), damageData, (trueDamage + shieldEffect)
	)
	---------- skada ----------

	---------- 变化血量 ----------
	self:HpChange(damageData)
	---------- 变化血量 ----------

	---------- 刷新驱动 ----------
	-- 施法驱动
	self.castDriver:UpdateActionTrigger(ActionTriggerType.HP, self:GetMainProperty():GetCurHpPercent())

	-- 转阶段触发器
	if self.phaseDriver then
		self.phaseDriver:UpdateActionTrigger(ActionTriggerType.HP, self:GetMainProperty():GetCurHpPercent())
	end
	---------- 刷新驱动 ----------

	---------- 触发器 ----------
	if not noTrigger then
		local attackerTag = nil
		if not damageData:CausedBySkill() then
			-- 如果是技能造成的伤害 初始化一次攻击者的tag
			attackerTag = damageData.attackerTag
		end
		-- 受到伤害
		self.triggerDriver:OnActionEnter(ConfigObjectTriggerActionType.GOT_DAMAGE, ObjectTriggerParameterStruct.New(attackerTag))

		-- 受到暴击伤害触发器
		if damageData.isCritical then
			-- 受到暴击伤害
			self.triggerDriver:OnActionEnter(ConfigObjectTriggerActionType.GOT_DAMAGE_CRITICAL)
		end
	end
	---------- 触发器 ----------

	---------- view ----------
	-- 被击动画
	if sp.AnimationName.idle == self:GetCurrentAnimationName() and OState.VIEW_TRANSFORM ~= self:GetState() then
		self:DoAnimation(true, nil, sp.AnimationName.attacked, false, sp.AnimationName.idle, true)

		--***---------- 插入刷新渲染层计时器 ----------***--
		self:RefreshRenderAnimation(true, nil, sp.AnimationName.attacked, false, sp.AnimationName.idle, true)
		--***---------- 插入刷新渲染层计时器 ----------***--
	end

	-- 变色
	self.tintDriver:OnActionEnter(BattleObjTintPattern.BOTP_BLOOD)
	---------- view ----------

end
--[[
@override
生命值变化
@params damageData ObjectDamageStruct
--]]
function CardObjectModel:HpChange(damageData)
	-- 计算差值
	local delta = damageData.damage
	local causeDamageObjTag = damageData:GetSourceObjTag()
	local causeDamageObj = G_BattleLogicMgr:IsObjAliveByTag(causeDamageObjTag)

	local damageNumberStartPos = cc.p(0.5, 1)

	if damageData:IsHeal() then

		-- 治疗
		BattleUtils.BattleObjectActionLog(
			self,
			'获得了实际治疗，通过', damageData.healerTag,
			'治疗值:',damageData.damage,
			'技能id:', damageData.skillInfo and damageData.skillInfo.skillId
		)

	else

		BattleUtils.BattleObjectActionLog(
			self,
			'获得了实际伤害，通过', damageData.attackerTag,
			'伤害值:',damageData.damage,
			'技能id:', damageData.skillInfo and damageData.skillInfo.skillId
		)

		-- 伤害
		delta = -1 * delta

		-- 判断是否致死
		-- /***********************************************************************************************************************************\
		--  * !!!由于是在下一帧判断是否死亡 此处可能会触发多次!!!
		-- \***********************************************************************************************************************************/
		if self:GetMainProperty():IsDamageDeadly(delta) then
			---------- 击杀者回调 ----------
			if causeDamageObj then
				local slayData = SlayObjectStruct.New(
					self:GetOTag(),
					damageData,
					self:GetMainProperty():GetCurrentHp() + delta
				)
				causeDamageObj:ObjectEventSlayHandler(slayData)
			end
			---------- 击杀者回调 ----------

			-- 受到致死伤害
			self.triggerDriver:OnActionEnter(ConfigObjectTriggerActionType.GOT_DEADLY_DAMAGE)
		end

		damageNumberStartPos = cc.p(0.5, 0.8)

	end

	-- 变化血量
	self:GetMainProperty():Setp(ObjP.HP, self:GetMainProperty():GetCurrentHp() + delta)

	-- 不能超过血上限
	if self:GetMainProperty():GetOriginalHp() < self:GetMainProperty():GetCurrentHp() then

		self:GetMainProperty():Setp(ObjP.HP, self:GetMainProperty():GetOriginalHp())

	elseif 0 >= self:GetMainProperty():GetCurrentHp() then
		
		self:GetMainProperty():Setp(ObjP.HP, 0)

	end

	BattleUtils.BattleObjectActionLog(self,
		'血量变化后的当前生命百分比:', self:GetMainProperty():GetCurHpPercent()
	)

	self:UpdateHp()

	--***---------- 刷新渲染层 ----------***--
	-- 显示伤害数值
	G_BattleLogicMgr:AddRenderOperate(
		'G_BattleRenderMgr',
		'ShowDamageNumber',
		damageData,
		self:GetPosInBattleRootByCollisionBoxPos(damageNumberStartPos),
		self:GetOrientation(),
		self:IsHighlight()
	)
	--***---------- 刷新渲染层 ----------***--

	---------- 记录伤害 ----------
	local energy = nil
	if causeDamageObj then
		energy = causeDamageObj:GetEnergy()
	end
	G_BattleLogicMgr:GetBData():AddADamageStr(damageData, damageData.damage, energy)
	---------- 记录伤害 ----------
end
--[[
@override
强制变化生命值百分比 不触发触发器
@params percent number 百分比
--]]
function CardObjectModel:HpPercentChangeForce(percent)
	self:GetMainProperty():SetCurHpPercent(percent)
	self:UpdateHp()

	-- 更新一次阶段转换驱动器的触发器
	if nil ~= self.phaseDriver then
		self.phaseDriver:UpdateActionTrigger(ActionTriggerType.HP, percent)
	end
end
--[[
刷新一次血量相关的数据
--]]
function CardObjectModel:UpdateHp()
	-- 刷新一次血量百分比
	self:GetMainProperty():UpdateCurHpPercent()

	--***---------- 刷新渲染层 ----------***--
	-- 刷新血条
	self:UpdateHpBar()
	--***---------- 刷新渲染层 ----------***--
end
--[[
根据护盾效果计算一次伤害减免
@params damage number 伤害值
@return damage_, shieldEffect number 护盾见面后的伤害值, 护盾减少的伤害量
--]]
function CardObjectModel:CalcFixedDamageByShield(damage)
	-- 护盾抵消
	local damage_ = damage

	for i = #self.shield, 1, -1 do
		damage_ = damage_ - self.shield[i]:OnCauseEffectEnter(damage_)
	end

	return damage_, (damage - damage_)
end
--[[
根据属性系数计算一次伤害减免
@params damage number 伤害值
@params damageData ObjectDamageStruct 伤害信息
@params damage_ number 伤害值
--]]
function CardObjectModel:CalcFixedDamageByObjPP(damage, damageData)
	local damage_ = damage

	---------- 修正最终减伤 ----------
	damage_ = self:GetMainProperty():FixFinalGetDamage(damage_, damageData.damageType)
	---------- 修正最终减伤 ----------

	return damage_
end
--[[
根据特殊buff计算一次伤害减免
@params damage number 伤害值
@params damageData ObjectDamageStruct 伤害信息
@params damage_ number 伤害值
--]]
function CardObjectModel:CalcFixedDamageByBuff(damage, damageData)
	local damage_ = damage

	---------- 由buff效果产生的伤害抵消 ----------
	local damageReduceConfig = {
		ConfigBuffType.SACRIFICE, 			-- 牺牲
		ConfigBuffType.STAGGER 				-- 醉拳
	}

	for _, reduceBuffType in ipairs(damageReduceConfig) do
		if (nil == damageData.skillInfo) or (reduceBuffType ~= damageData.skillInfo.btype) then
			local targetBuffs = self:GetBuffsByBuffType(reduceBuffType, false)
			for i = #targetBuffs, 1, -1 do
				damage_ = damage_ - targetBuffs[i]:OnCauseEffectEnter(damage_, damageData)

				if 0 == damage_ then
					return damage_
				end
			end
		end
	end
	---------- 由buff效果产生的伤害抵消 ----------

	return damage_
end
--[[
@override
被治疗
@params healData ObjectDamageStruct 治疗信息
@params noTrigger bool 不触发任何触发器
--]]
function CardObjectModel:BeHealed(healData, noTrigger)
	if not self:IsAlive() or healData.damage == 0 then return end

	BattleUtils.BattleObjectActionLog(
		self,
		'从这个人那获得了治疗', healData.healerTag,
		'治疗值:',healData.damage,
		'技能id:', healData.skillInfo and healData.skillInfo.skillId
	)

	-- 是否免疫治疗
	if self:HealImmuneByHealType(healData.damageType) then
		return
	end

	local heal = healData.damage

	---------- 修正最终治疗 ----------
	heal = self:CalcFixedHealByObjPP(heal, healData)
	---------- 修正最终治疗 ----------

	healData:SetDamageValue(heal)

	---------- 治疗溢出 ----------
	local overflowHeal = self:GetMainProperty():GetCurrentHp() + healData.damage - self:GetMainProperty():GetOriginalHp()

	if 0 < overflowHeal then
		local overflowBuffs = {
			ConfigBuffType.OVERFLOW_HEAL_2_SHIELD,
			ConfigBuffType.OVERFLOW_HEAL_2_DAMAGE
		}

		for _, buffType in ipairs(overflowBuffs) do
			local targetBuffs = self:GetBuffsByBuffType(buffType, false)
			for i = #targetBuffs, 1, -1 do
				targetBuffs[i]:OnCauseEffectEnter(overflowHeal)
			end
		end
	end
	---------- 治疗溢出 ----------

	---------- skada ----------
	local trueHeal = self:CalcObjectGotTrueHeal(healData:GetDamageValue())

	-- 物体造成的治疗
	G_BattleLogicMgr:SkadaWork(
		SkadaType.HEAl,
		healData:GetSourceObjTag(), healData, trueHeal
	)
	---------- skada ----------

	---------- 变化血量 ----------
	self:HpChange(healData)
	---------- 变化血量 ----------

	---------- 刷新驱动 ----------
	-- 施法驱动
	self.castDriver:UpdateActionTrigger(ActionTriggerType.HP, self:GetMainProperty():GetCurHpPercent())

	-- 转阶段触发器
	if self.phaseDriver then
		self.phaseDriver:UpdateActionTrigger(ActionTriggerType.HP, self:GetMainProperty():GetCurHpPercent())
	end
	---------- 刷新驱动 ----------

	---------- 触发器 ----------
	if not noTrigger then
		-- 受到治疗
		self.triggerDriver:OnActionEnter(ConfigObjectTriggerActionType.GOT_HEAL)
		
		if healData.isCritical then
			-- 受到治疗暴击
			self.triggerDriver:OnActionEnter(ConfigObjectTriggerActionType.GOT_HEAL_CRITICAL)
		end
	end
	---------- 触发器 ----------
end
--[[
根据治疗类型判断是否免疫治疗
@params healType DamageType 伤害类型
@return _ bool 是否免疫伤害
--]]
function CardObjectModel:HealImmuneByHealType(healType)
	local result = self:GetObjectExtraStateInfo():GetDamageImmune(healType) or
		self:GetObjectExtraStateInfo():GetDamageImmune(DamageType.HEAL) or
		self:GetObjectExtraStateInfo():GetGlobalDamageImmune(healType) or
		self:GetObjectExtraStateInfo():GetGlobalDamageImmune(DamageType.HEAL)

	return result
end
--[[
根据属性系数计算一次治疗量变化
@params damage number 伤害值
@params damageData ObjectDamageStruct 伤害信息
@params damage_ number 伤害值
--]]
function CardObjectModel:CalcFixedHealByObjPP(damage, damageData)
	local damage_ = damage

	---------- 修正最终治疗量 ----------
	damage_ = self:GetMainProperty():FixFinalGetHeal(damage_, damageData.damageType)
	---------- 修正最终治疗量 ----------

	return damage_
end
--[[
@override
春哥一下
@params minHp number 最小血量
--]]
function CardObjectModel:ForceUndeadOnce(minHp)
	self:GetMainProperty():Setp(ObjP.HP, math.max(minHp or 1, self:GetMainProperty():GetCurrentHp()))
end
--[[
@override
修正由攻速变化产生的动画缩放
--]]
function CardObjectModel:FixAnimationScaleByATKRate()
	-- 刷新动画的缩放
	local avatarTimeScale = self:GetAvatarTimeScale()
	self:SetAnimationTimeScale(avatarTimeScale)
	if OState.ATTACKING == self:GetState() then
		-- 修正展示层的动画缩放
		self:RefreshRenderAnimationTimeScale(avatarTimeScale)
	end
end
--[[
根据伤害计算一次有效伤害
@params damage number
--]]
function CardObjectModel:CalcObjectGotTrueDamage(damage)
	if self:GetMainProperty():GetCurrentHp() < damage then
		return self:GetMainProperty():GetCurrentHp()
	else
		return damage
	end
end
--[[
根据治疗量计算一次有效治疗
@params heal number
--]]
function CardObjectModel:CalcObjectGotTrueHeal(heal)
	if self:GetMainProperty():GetCurrentHp() + heal > self:GetMainProperty():GetOriginalHp() then
		return self:GetMainProperty():GetOriginalHp() - self:GetMainProperty():GetCurrentHp()
	else
		return heal
	end
end
---------------------------------------------------
-- attack logic end --
---------------------------------------------------

---------------------------------------------------
-- cast logic begin --
---------------------------------------------------
--[[
@override
根据技能id释放一个技能
@params skillId int 技能id
--]]
function CardObjectModel:Cast(skillId)
	self.castDriver:OnActionEnter(skillId)
end
--[[
@override
被施法
@params buffInfo ObjectBuffConstructorStruct 构造buff的数据
@return _ bool 是否成功加上了该buff
--]]
function CardObjectModel:BeCasted(buffInfo)
	BattleUtils.BattleObjectActionLog(self, 'get buff effect -> fromTag', buffInfo.casterTag, buffInfo.btype)

	------------ 检查天气免疫 ------------
	if BattleElementType.BET_WEATHER == G_BattleLogicMgr:GetBattleElementTypeByTag(buffInfo.casterTag) then
		if true == self:GetObjectWeatherImmune(buffInfo.weatherId) then
			-- 显示免疫字样
			self:ShowImmune()
			return false
		end
	end
	------------ 检查天气免疫 ------------

	------------ 检查buff免疫 ------------
	if true == self:IsObjectImmuneBuff(buffInfo.btype) then
		-- 显示免疫字样
		self:ShowImmune()
		return false
	end
	------------ 检查buff免疫 ------------

	------------ 检查内部免疫 ------------
	if true == self:ImmuneAbnormalStateByBuffType(buffInfo.btype) then
		-- 显示免疫字样
		self:ShowImmune()
		return false
	end
	------------ 检查内部免疫 ------------

	-- 被施法逻辑
	if BuffCauseEffectTime.INSTANT == buffInfo.causeEffectTime then

		-- 瞬时起效类型 不加入缓存
		local buff = __Require(buffInfo.className).new(buffInfo)
		buff:OnCauseEffectEnter()

	else

		-- 其他类型
		if buffInfo.isHalo then
			-- 光环逻辑
			local buff = self:GetHaloByBuffId(buffInfo:GetStructBuffId())

			if nil == buff then

				-- 未找到buff 创建一个buff
				buff = __Require(buffInfo.className).new(buffInfo)
				self:AddHalo(buff)

				---------- 触发器 ----------
				-- add buff
				self.triggerDriver:OnActionEnter(ConfigObjectTriggerActionType.GOT_BUFF)
				---------- 触发器 ----------

			else

				-- buff已经存在 刷新buff
				buff:OnRefreshBuffEnter(buffInfo)

				---------- 触发器 ----------
				-- add buff
				self.triggerDriver:OnActionEnter(ConfigObjectTriggerActionType.REFRESH_BUFF)
				---------- 触发器 ----------

			end
		else
			-- buff逻辑
			local buff = self:GetBuffByBuffId(buffInfo:GetStructBuffId())

			if nil == buff then

				buff = __Require(buffInfo.className).new(buffInfo)
				self:AddBuff(buff)

				---------- 触发器 ----------
				-- add buff
				self.triggerDriver:OnActionEnter(ConfigObjectTriggerActionType.GOT_BUFF)
				---------- 触发器 ----------

			else

				-- buff已经存在 刷新buff
				buff:OnRefreshBuffEnter(buffInfo)

				---------- 触发器 ----------
				-- add buff
				self.triggerDriver:OnActionEnter(ConfigObjectTriggerActionType.REFRESH_BUFF)
				---------- 触发器 ----------

			end
		end

	end

	return true

end
--[[
刷一次物体的光环数据
--]]
function CardObjectModel:CastAllHalos()
	--[[
	new logic todo

	刷新光环时需要把老的光环buff数据移除
	--]]
	self.castDriver:CastAllHalos()
end
--[[
释放连携技
@params skillId int 连携技id
--]]
function CardObjectModel:CastConnectSkill(skillId)
	if true == self.castDriver:CanDoAction(ActionTriggerType.CONNECT, skillId) then
		-- 打断当前动作
		self:BreakCurrentAction()
		
		self.castDriver:OnActionEnter(skillId)
	else
		print('未满足释放连携技条件')
	end
end
--[[
@override
根据状态判断是否可以释放连携技
@return _ bool 
--]]
function CardObjectModel:CanCastConnectByAbnormalState()
	local result = self:InAbnormalState(AbnormalState.SILENT) or 
		-- self:InAbnormalState(AbnormalState.STUN) or
		-- self:InAbnormalState(AbnormalState.FREEZE) or
		self:InAbnormalState(AbnormalState.ENCHANTING)
	return not result
end
--[[
判断是否可以释放触发buff
@params skillId int 技能id
@params buffType ConfigBuffType buff类型
@params triggerActionType ConfigObjectTriggerActionType 物体行为触发类型
--]]
function CardObjectModel:CanTriggerBuff(skillId, buffType, triggerActionType)
	return self.buffDriver:CanTriggerBuff(skillId, buffType, triggerActionType)
end
--[[
消耗一些触发的buff的资源
@params skillId int 技能id
@params buffType ConfigBuffType buff类型
@params triggerActionType ConfigObjectTriggerActionType 物体行为触发类型
@params countdown number 触发的cd
--]]
function CardObjectModel:CostTriggerBuffResources(skillId, buffType, triggerActionType, cd)
	self.buffDriver:CostTriggerBuffResources(skillId, buffType, triggerActionType, cd)
end
---------------------------------------------------
-- cast logic end --
---------------------------------------------------

---------------------------------------------------
-- buff logic begin --
---------------------------------------------------
--[[
@override
对物体添加一个buff
@params buff BaseBuff buff
--]]
function CardObjectModel:AddBuff(buff)
	-- 检查一次是否需要添加buff icon
	local buffIconType = buff:GetBuffIconType()
	if BuffIconType.BASE ~= buffIconType and not self:HasBuffByBuffIconType(buffIconType, buff:GetBuffOriginValue()) then
		-- 没有本类型buff 添加一个buff icon
		self:AddBuffIcon(buffIconType, buff:GetBuffOriginValue())
	end

	BaseObjectModel.AddBuff(self, buff)
end
--[[
@override
移除物体身上的一个buff
@params buff BaseBuff buff
--]]
function CardObjectModel:RemoveBuff(buff)
	BaseObjectModel.RemoveBuff(self, buff)

	-- 检查一次是否需要移除buff icon
	local buffIconType = buff:GetBuffIconType()
	if BuffIconType.BASE ~= buffIconType and not self:HasBuffByBuffIconType(buffIconType, buff:GetBuffOriginValue()) then
		-- 没有本类型buff 移除buff icon
		self:RemoveBuffIcon(buffIconType, buff:GetBuffOriginValue())
	end
end
--[[
@override
对物体添加一个光环buff
@params buff BaseBuff buff
--]]
function CardObjectModel:AddHalo(buff)
	-- 检查一次是否需要添加buff icon
	local buffIconType = buff:GetBuffIconType()
	if BuffIconType.BASE ~= buffIconType and not self:HasBuffByBuffIconType(buffIconType, buff:GetBuffOriginValue()) then
		-- 没有本类型buff 添加一个buff icon
		self:AddBuffIcon(buffIconType, buff:GetBuffOriginValue())
	end

	BaseObjectModel.AddHalo(self, buff)
end
--[[
@override
移除物体身上的一个光环buff
@params buff BaseBuff buff
--]]
function CardObjectModel:RemoveHalo(buff)
	BaseObjectModel.RemoveHalo(self, buff)

	-- 检查一次是否需要移除buff icon
	local buffIconType = buff:GetBuffIconType()
	if BuffIconType.BASE ~= buffIconType and not self:HasBuffByBuffIconType(buffIconType, buff:GetBuffOriginValue()) then
		-- 没有本类型buff 移除buff icon
		self:RemoveBuffIcon(buffIconType, buff:GetBuffOriginValue())
	end
end
---------------------------------------------------
-- buff logic end --
---------------------------------------------------

---------------------------------------------------
-- qte buff begin --
---------------------------------------------------
--[[
@override
添加可点击物体qte
@params qteBuffsInfo QTEAttachObjectConstructStruct qte数据信息
--]]
function CardObjectModel:AddQTE(qteBuffsInfo)
	local skillId = qteBuffsInfo.skillId
	local qteAttachModel = self:GetQTEBySkillId(skillId)

	if nil == qteAttachModel then

		qteAttachModel = G_BattleLogicMgr:GetAQTEAttachObject(qteBuffsInfo)

		self.qteBuffs.id[tostring(skillId)] = qteAttachModel
		table.insert(self.qteBuffs.idx, 1, qteAttachModel)

		--***---------- 刷新渲染层 ----------***--
		-- 在渲染层创建一个qte层
		G_BattleLogicMgr:AddRenderOperate(
			'G_BattleRenderMgr',
			'CreateAAttachObjectView',
			self:GetOTag(), self:GetViewModelTag(), qteAttachModel:GetOTag(), skillId, qteAttachModel:GetAttachType()
		)
		--***---------- 刷新渲染层 ----------***--

	else

		-- 已经存在这个qte 刷新一次
		qteAttachModel:RefreshQTEBuffs(qteBuffsInfo)

	end

end
--[[
@override
移除可点击物体
@params skillId int 技能id
--]]
function CardObjectModel:RemoveQTE(skillId)
	local qteAttachModel = nil
	for i = #self.qteBuffs.idx, 1, -1 do
		qteAttachModel = self.qteBuffs.idx[i]
		if checkint(skillId) == checkint(qteAttachModel:GetSkillId()) then
			qteAttachModel:Die()
			table.remove(self.qteBuffs.idx, i)
			break
		end
	end
	self.qteBuffs.id[tostring(skillId)] = nil
end
--[[
@override
根据单个buff移除qte buff
@params skillId int 技能id
@params buffType ConfigBuffType buff 类型
--]]
function CardObjectModel:RemoveQTEBuff(skillId, buffType)
	local qteAttachModel = self:GetQTEBySkillId(skillId)
	if nil ~= qteAttachModel then
		qteAttachModel:RemoveQTEBuff(buffType)
	end
end
---------------------------------------------------
-- qte buff end --
---------------------------------------------------

---------------------------------------------------
-- buff infect logic begin --
---------------------------------------------------
--[[
@override
根据技能id判断物体是否已经被传染
@params skillId int 
@return _ bool 是否已经被传染
--]]
function CardObjectModel:IsInfectBySkillId(skillId)
	return nil ~= self.infectDriver:GetInfectInfoBySkillId(skillId)
end
--[[
@override
添加传染驱动器
@params infectInfo InfectTransmitStruct 传染信息
--]]
function CardObjectModel:AddInfectInfo(infectInfo)
	self.infectDriver:AddAInfectInfo(infectInfo)
end
--[[
@override
移除传染驱动器
@params skillId int 技能id
--]]
function CardObjectModel:RemoveInfecInfo(skillId)
	self.infectDriver:RemoveAInfectInfoBySkillId(skillId)
end
---------------------------------------------------
-- buff infect logic end --
---------------------------------------------------

---------------------------------------------------
-- move logic begin --
---------------------------------------------------
--[[
@override
移动
--]]
function CardObjectModel:Move(dt, targetTag)
	self.moveDriver:OnActionUpdate(dt, targetTag)
end
--[[
@override
强制移动 从一个点移动到另一个点 期间不处理战斗逻辑
@params targetPos cc.p
@params moveActionName string 移动的动作名
@params moveOverCallback function 移动完成后的回调函数
--]]
function CardObjectModel:ForceMove(targetPos, moveActionName, moveOverCallback)
	self.moveDriver:OnForceMoveEnter(targetPos, moveActionName, moveOverCallback)
end
---------------------------------------------------
-- move logic end --
---------------------------------------------------

---------------------------------------------------
-- hp logic begin --
---------------------------------------------------
--[[
@override
获取当前生命百分比
@return _ number
--]]
function CardObjectModel:GetHPPercent()
	return self:GetMainProperty():GetCurHpPercent()
end
--[[
@override
获取是否需要记录变化血量
@return _ ConfigMonsterRecordDeltaHP 是否需要记录血量变化
--]]
function CardObjectModel:GetRecordDeltaHp()
	return self:GetObjInfo().recordDeltaHp
end
---------------------------------------------------
-- hp logic end --
---------------------------------------------------

---------------------------------------------------
-- energy logic begin --
---------------------------------------------------
--[[
@override
增加能量
@params delta number 变化的能量
--]]
function CardObjectModel:AddEnergy(delta)
	BaseObjectModel.AddEnergy(self, delta)

	--***---------- 插入刷新渲染层计时器 ----------***--
	-- 刷新能量条
	self:UpdateEnergyBar()

	---------- 刷新连携技按钮状态 ----------
	self:RefreshConnectButtonsByEnergy()
	---------- 刷新连携技按钮状态 ----------
	--***---------- 插入刷新渲染层计时器 ----------***--
end
--[[
获取能量最大值
@override
@return _ number 获取能量
--]]
function  CardObjectModel:GetMaxEnergy()
	return self:GetMainProperty():GetMaxEnergy()
end
--[[
@override
获取能量秒回值
--]]
function CardObjectModel:GetEnergyRecoverRatePerS()
	return ENERGY_PER_S + self:GetEnergyRecoverRate()
end
--[[
@override
强制变化一次能量百分比
@params percent number 能量百分比
--]]
function CardObjectModel:EnergyPercentChangeForce(percent)
	BaseObjectModel.EnergyPercentChangeForce(self, percent)

	--***---------- 插入刷新渲染层计时器 ----------***--
	-- 刷新能量条
	self:UpdateEnergyBar()

	---------- 刷新连携技按钮状态 ----------
	self:RefreshConnectButtonsByEnergy()
	---------- 刷新连携技按钮状态 ----------
	--***---------- 插入刷新渲染层计时器 ----------***--
end
---------------------------------------------------
-- energy logic end --
---------------------------------------------------

---------------------------------------------------
-- obj shift logic begin --
---------------------------------------------------
--[[
是否能进入下一波
@return 是否能进入下一波
--]]
function CardObjectModel:CanEnterNextWave()
	local result = false

	if 1 == self.castDriver:IsInChanting() then
		-- 读条中 打断读条
		self.castDriver:OnChantBreak()
	end

	local currentAnimationName = self:GetCurrentAnimationName()

	if true == self.moveDriver:IsEscaping() then

		return false

	elseif nil == currentAnimationName or sp.AnimationName.idle == currentAnimationName then

		return true

	elseif self:InAbnormalState(AbnormalState.STUN) or self:InAbnormalState(AbnormalState.FREEZE) then

		-- 清一次buff
		self:ClearBuff()

	elseif sp.AnimationName.run == currentAnimationName then

		-- 移动中 直接停止
		self:DoAnimation(true, nil, sp.AnimationName.idle, true)

		--***---------- 插入刷新渲染层计时器 ----------***--
		self:RefreshRenderAnimation(true, nil, sp.AnimationName.idle, true)
		--***---------- 插入刷新渲染层计时器 ----------***--

	end

	return result
end
--[[
物体进入下一波的逻辑
@params nextWave int 下一波序号
--]]
function CardObjectModel:EnterNextWave(nextWave)
	BaseObjectModel.EnterNextWave(self, nextWave)

	---------- 触发器 ----------
	-- 进入下一波
	self.triggerDriver:OnActionEnter(ConfigObjectTriggerActionType.WAVE_SHIFT)
	---------- 触发器 ----------

	self:ClearBuff()

	self:SetState(OState.SLEEP)
	self:SetState(OState.SLEEP, -1)
	self:DoAnimation(true, nil, sp.AnimationName.idle, true)

	-- 重置站位
	self:ResetLocation()

	--***---------- 刷新渲染层 ----------***--
	-- 重置站位
	self:RefreshRenderViewPosition()
	-- 重置朝向
	self:RefreshRenderViewTowards()
	-- 重置动画
	self:RefreshRenderAnimation(true, nil, sp.AnimationName.idle, true)
	--***---------- 刷新渲染层 ----------***--

	---------- 触发器 ----------
	-- 进入下一波
	self.triggerDriver:OnActionEnter(ConfigObjectTriggerActionType.WAVE_SHIFT)
	---------- 触发器 ----------

	-- 重置计时器
	self.attackDriver:ResetActionTrigger()
	self.castDriver:ResetActionTrigger()
	self.countdowns.energy = 1
end
--[[
胜利
--]]
function CardObjectModel:Win()
	self:DoAnimation(
		true, 1, sp.AnimationName.win, true
	)

	--***---------- 刷新渲染层 ----------***--
	self:RefreshRenderAnimation(true, 1, sp.AnimationName.win, true)
	--***---------- 刷新渲染层 ----------***--
end
---------------------------------------------------
-- obj shift logic end --
---------------------------------------------------

---------------------------------------------------
-- escape logic begin --
---------------------------------------------------
--[[
@override
开始逃跑
--]]
function CardObjectModel:StartEscape()
	local targetPos = self.moveDriver:GetEscapeTargetPosition()
	if nil ~= targetPos then
		self.moveDriver:StartEscape(targetPos)
	end
end
--[[
@override
逃跑结束
--]]
function CardObjectModel:OverEscape()
	self.moveDriver:OnEscapeExit()
end
--[[
从休息区返回战场
@override
--]]
function CardObjectModel:AppearFromEscape()
	-- 恢复全免疫
	self:SetAllImmune(false)

	-- 显示渲染层
	--***---------- 刷新渲染层 ----------***--
	G_BattleLogicMgr:AddRenderOperate(
		'G_BattleRenderMgr',
		'PhaseChangeEscapeBack',
		self:GetViewModelTag()
	)
	--***---------- 刷新渲染层 ----------***--
end
--[[
@override
计算当前逃跑目标点
@return targetPos cc.p 逃跑目标点
--]]
function CardObjectModel:CalcEscapeTargetPosition()
	local designSize = G_BattleLogicMgr:GetDesignScreenSize()
	local targetPos = nil

	if true == self:IsEnemy(true) then
		-- 敌人时往右逃跑
		targetPos = cc.p(
			designSize.width + self:GetStaticViewBox().width * 1.25,
			self:GetLocation().po.y
		)
	else
		-- 友军时往左逃跑
		targetPos = cc.p(
			-1 * self:GetStaticViewBox().width * 1.25,
			self:GetLocation().po.y
		)
	end

	return targetPos
end
--[[
获取逃跑后重返战场的波数
@override
--]]
function CardObjectModel:GetAppearWaveAfterEscape()
	return self.moveDriver:GetAppearWaveAfterEscape()
end
function CardObjectModel:SetAppearWaveAfterEscape(wave)
	self.moveDriver:SetAppearWaveAfterEscape(wave)
end
---------------------------------------------------
-- escape logic end --
---------------------------------------------------

---------------------------------------------------
-- blew off logic begin --
---------------------------------------------------
--[[
@override
吹出场外 自动走回场内
@params distance number 吹飞多少横坐标 为空时自动修正距离
--]]
function CardObjectModel:BlewOff(distance)
	self.moveDriver:OnBlewOffEnter(distance)
end
---------------------------------------------------
-- blew off logic end --
---------------------------------------------------

---------------------------------------------------
-- die logic begin --
---------------------------------------------------
--[[
@override
判断物体是否满足死亡条件
@return result bool 死亡
--]]
function CardObjectModel:CanDie()
	local result = (not self:InAbnormalState(AbnormalState.UNDEAD)) and (0 >= self:GetMainProperty():GetCurrentHp())
	return result
end
--[[
死亡开始
--]]
function CardObjectModel:DieBegin()
	BattleUtils.BattleObjectActionLog(self, ' !!!!!!!!! 开始 [死亡] !!!!!!!!!')

	-- 清空动画
	self:ClearAnimations()

	-- 死亡逻辑
	self:Die()

	-- 做死亡动画
	self:DoAnimation(true, 1, sp.AnimationName.die, false)

	--***---------- 刷新渲染层 ----------***--
	self:RefreshRenderAnimation(true, 1, sp.AnimationName.die, false)
	--***---------- 刷新渲染层 ----------***--

	--***---------- 刷新渲染层 ----------***--
	-- 进入死亡
	G_BattleLogicMgr:AddRenderOperate(
		'G_BattleRenderMgr',
		'ObjectViewDieBegin',
		self:GetViewModelTag()
	)

	-- 如果是卡牌单位 播放死亡语音
	if not CardUtils.IsMonsterCard(self:GetObjectConfigId()) then
		G_BattleLogicMgr:AddRenderOperate(
			'G_BattleRenderMgr',
			'PlayCardSound',
			self:GetObjectConfigId(), SoundType.TYPE_BATTLE_DIE
		)
	end
	--***---------- 刷新渲染层 ----------***--
end
--[[
死亡
--]]
function CardObjectModel:Die()
	self:KillSelf(false)
end
--[[
死亡结束
--]]
function CardObjectModel:DieEnd()
	if nil ~= self:GetViewModel() then
		self:ClearAnimations()
		self:GetViewModel():Kill()
	end

	-- 重置高亮
	self:SetHighlight(false)

	--***---------- 刷新渲染层 ----------***--
	-- 死亡结束
	G_BattleLogicMgr:AddRenderOperate(
		'G_BattleRenderMgr',
		'KillObjectView',
		self:GetViewModelTag()
	)
	--***---------- 刷新渲染层 ----------***--
end
--[[
杀死自己
@params nature bool 是否是自然死亡 自然死亡不计入传给服务器的死亡列表
--]]
function CardObjectModel:KillSelf(nature)
	-- 打断技能
	self:BreakCurrentAction()

	-- 设置状态
	self:SetState(OState.DIE)

	-- 停掉除去动画以外所有的handler
	self:UnregistObjectEventHandler()

	-- 广播对象死亡事件
	G_BattleLogicMgr:SendObjEvent(
		ObjectEvent.OBJECT_DIE,
		{
			tag = self:GetOTag(), cardId = self:GetObjectConfigId(), isEnemy = self:IsEnemy(true)
		}
	)

	-- 清除所有qte
	for i = #self.qteBuffs.idx, 1, -1 do
		self.qteBuffs.idx[i]:Die()
	end

	-- 清除所有buff
	self:ClearBuff()

	-- 操作data数据
	G_BattleLogicMgr:GetBData():AddALogicModelToDust(self, nature)
	G_BattleLogicMgr:GetBData():RemoveABattleObjLogicModel(self)

	-- 清空能量
	self:AddEnergy(-self:GetEnergy())

	if nature then
		if nil ~= self:GetViewModel() then
			self:ClearAnimations()
			self:GetViewModel():Kill()
		end
	end

	---------- 刷新连携技按钮状态 ----------
	self:EnableConnectSkillButton(skillId, false)
	---------- 刷新连携技按钮状态 ----------

	-- 变回原色
	self.tintDriver:OnActionBreak()

	--***---------- 刷新渲染层 ----------***--
	-- 移除当前hold的ciscene
	G_BattleLogicMgr:AddRenderOperate(
		'G_BattleRenderMgr',
		'KillObjectCISceneByTag',
		self:GetOTag()
	)
	--***---------- 刷新渲染层 ----------***--
end
--[[
销毁
--]]
function CardObjectModel:Destroy()
	if OState.DIE ~= self:GetState() then

		self:SetState(OState.DIE)

	end

	if nil ~= self:GetViewModel() then
		self:ClearAnimations()
		self:GetViewModel():Kill()
	end

	self.buffs = {idx = {}, id = {}} -- idx 按倒序插入buff id 根据id保存buff
	self.halos = {idx = {}, id = {}} -- idx 按倒序插入buff id 根据id保存buff
	self.shield = {} -- 护盾计数器
end
---------------------------------------------------
-- die logic end --
---------------------------------------------------

---------------------------------------------------
-- revive logic begin --
---------------------------------------------------
--[[
@override
复活
@params reviveHpPercent number 复活时的血量百分比
@params reviveEnergyPercent number 复活时的能量百分比
@params healData ObjectDamageStruct 伤害数据
--]]
function CardObjectModel:Revive(reviveHpPercent, reviveEnergyPercent, healData)
	-- 恢复除去动画以外所有的handler
	self:RegisterObjectEventHandler()

	-- 唤醒展示层模型
	if nil ~= self:GetViewModel() then
		self:GetViewModel():Awake()
	end

	-- 操作data数据
	G_BattleLogicMgr:GetBData():AddABattleObjLogicModel(self)
	G_BattleLogicMgr:GetBData():RemoveALogicModelFromDust(self)

	-- 恢复血量 能量
	self:HpPercentChangeForce(reviveHpPercent) 
	self:EnergyPercentChangeForce(reviveEnergyPercent)
	local recoverHp = self:GetMainProperty():GetOriginalHp() * reviveHpPercent

	-- 记录一次伤害数据
	if nil ~= healData then
		local healer = G_BattleLogicMgr:IsObjAliveByTag(healData.healerTag)
		local attackerEnergy = nil
		if nil ~= healer and healer.GetEnergy then
			attackerEnergy = healer:GetEnergy()
		end

		healData.damage = recoverHp
		G_BattleLogicMgr:GetBData():AddADamageStr(healData, healData.damage, attackerEnergy)
	end

	-- 唤醒物体
	self:AwakeObject()

	--***---------- 刷新渲染层 ----------***--
	self:ReviveRender()
	--***---------- 刷新渲染层 ----------***--

	-- 恢复动作
	self:ClearAnimations()
	self:DoAnimation(true, nil, sp.AnimationName.idle, true)
	self:SetAnimationTimeScale(self:GetAnimationTimeScale())
	--***---------- 刷新渲染层 ----------***--
	self:ClearRenderAnimations()
	self:RefreshRenderAnimation(true, nil, sp.AnimationName.idle, true)
	self:RefreshRenderAnimationTimeScale(self:GetAnimationTimeScale())
	--***---------- 刷新渲染层 ----------***--

	-- 广播事件 在此复活
	G_BattleLogicMgr:SendObjEvent(
		ObjectEvent.OBJECT_REVIVE,
		{
			tag = self:GetOTag(), cardId = self:GetObjectConfigId(), isEnemy = self:IsEnemy(true)
		}
	)

	---------- 刷新连携技状态 ----------
	self:CheckConnectSkillState()
	---------- 刷新连携技状态 ----------

	------ 激活一次光环效果 ---------
	self:CastAllHalos()
	------ 激活一次光环效果 ---------
end
---------------------------------------------------
-- revive logic end --
---------------------------------------------------

---------------------------------------------------
-- view transform begin --
---------------------------------------------------
--[[
@override
变形
@params oriSkinId int 源皮肤id
@params oriActionName string 源皮肤变形的动作
@params targetSkinId int 目标皮肤id
@params targetActionName string 目标皮肤变形的衔接动作
--]]
function CardObjectModel:ViewTransform(oriSkinId, oriActionName, targetSkinId, targetActionName)
	if nil ~= self.exAbilityDriver then
		if true == self.exAbilityDriver:CanDoViewTransform(oriSkinId) then

			-- 开始变形 打断当前动作
			self:BreakCurrentAction()

			self.exAbilityDriver:OnViewTransformEnter(oriSkinId, oriActionName, targetSkinId, targetActionName)

		end
	end
end
--[[
@override
刷新变形后的展示层
@params spineDataStruct ObjectSpineDataStruct spine动画信息
@params avatarScale number avatar缩放
--]]
function CardObjectModel:RefreshViewModel(spineDataStruct, avatarScale)
	self:GetViewModel():InnerChangeViewModel(spineDataStruct, avatarScale)
end
---------------------------------------------------
-- view transform end --
---------------------------------------------------

---------------------------------------------------
-- abnormal state begin --
---------------------------------------------------
--[[
@override
眩晕
无法行动 重复播放被击动画
@params valid bool 是否有效
--]]
function CardObjectModel:Stun(valid)
	BaseObjectModel.Stun(self, valid)

	if true == valid then

		-- 眩晕状态 打断当前动作
		self:BreakCurrentAction()

		-- 如果没有死亡 做被击动作
		if self:IsAlive() then
			self:DoAnimation(true, nil, sp.AnimationName.attacked, true)
			self:SetAnimationTimeScale(self:GetAnimationTimeScale())

			--***---------- 刷新渲染层 ----------***--
			self:RefreshRenderAnimation(true, nil, sp.AnimationName.attacked, true)
			self:RefreshRenderAnimationTimeScale(self:GetAnimationTimeScale())
			--***---------- 刷新渲染层 ----------***--
		end

	else

		if self:IsAlive() then
			self:DoAnimation(true, nil, sp.AnimationName.idle, true)
			self:SetAnimationTimeScale(self:GetAnimationTimeScale())

			--***---------- 刷新渲染层 ----------***--
			self:RefreshRenderAnimation(true, nil, sp.AnimationName.idle, true)
			self:RefreshRenderAnimationTimeScale(self:GetAnimationTimeScale())
			--***---------- 刷新渲染层 ----------***--
		end

	end
end
--[[
@override
冻结
无法行动 动画暂停
@params valid bool 是否有效
--]]
function CardObjectModel:Freeze(valid)
	BaseObjectModel.Freeze(self, valid)

	if true == valid then

		-- 冻结状态 打断当前动作
		self:BreakCurrentAction()

		if self:IsAlive() then

			-- 冻结 动画暂停
			self:SetAnimationTimeScale(self:GetAvatarTimeScale())

			--***---------- 刷新渲染层 ----------***--
			self:RefreshRenderAnimationTimeScale(self:GetAnimationTimeScale())
			--***---------- 刷新渲染层 ----------***--

		end

	else

		 if self:IsAlive() then
		 	self:DoAnimation(true, nil, sp.AnimationName.idle, true)
			self:SetAnimationTimeScale(self:GetAvatarTimeScale())

			--***---------- 刷新渲染层 ----------***--
			self:RefreshRenderAnimation(true, nil, sp.AnimationName.idle, true)
			self:RefreshRenderAnimationTimeScale(self:GetAnimationTimeScale())
			--***---------- 刷新渲染层 ----------***--
		 end
		
	end
end
--[[
沉默
无法施法 打断当前施法
@params valid bool 是否有效
--]]
function CardObjectModel:Silent(valid)
	BaseObjectModel.Silent(self, valid)

	if true == valid then
		-- 打断正在释放的技能
		if OState.CASTING == self:GetState() then
			self.castDriver:OnActionBreak()
		end
	end
end
--[[
@override
魅惑 平a敌友性改变 无法释放连携技
@params valid bool 是否有效
--]]
function CardObjectModel:Enchanting(valid)
	BaseObjectModel.Enchanting(self, valid)

	if true == valid then
		-- 打断当前动作
		self:BreakCurrentAction()
	end
end
---------------------------------------------------
-- abnormal state end --
---------------------------------------------------

---------------------------------------------------
-- animation control begin --
---------------------------------------------------
--[[
@override
让物体做一个动画动作
@params setToSetupPose bool 是否恢复第一帧
@params timeScale int 动画速度缩放
@params setAnimationName string set的动画名字
@params setAnimationLoop bool set的动画是否循环
@params addAnimationName string add的动画名字
@params addAnimationLoop bool add的动画是否循环
--]]
function CardObjectModel:DoAnimation(setToSetupPose, timeScale, setAnimationName, setAnimationLoop, addAnimationName, addAnimationLoop)
	if true == setToSetupPose then
		self:GetViewModel():SetSpineToSetupPose()
	end

	if nil ~= setAnimationName then
		self:GetViewModel():SetSpineAnimation(setAnimationName, setAnimationLoop)
	end

	if nil ~= addAnimationName then
		self:GetViewModel():AddSpineAnimation(addAnimationName, addAnimationLoop)
	end

	if nil ~= timeScale then
		self:SetAnimationTimeScale(timeScale)
	end
end
--[[
@override
清空一个物体的动画动作
--]]
function CardObjectModel:ClearAnimations()
	self:GetViewModel():ClearSpineTracks()
end
--[[
@override
设置动画的时间缩放
@params timeScale number 时间缩放
--]]
function CardObjectModel:SetAnimationTimeScale(timeScale)
	self:GetViewModel():SetAnimationTimeScale(timeScale)
end
--[[
@override
获取动画的时间缩放
@return _ number 动画时间缩放
--]]
function CardObjectModel:GetAnimationTimeScale()
	return self:GetViewModel():GetAnimationTimeScale()
end
--[[
@override
获取当前正在进行的动作动画名
@return _ sp.AnimationName 动作动画名
--]]
function CardObjectModel:GetCurrentAnimationName()
	return self:GetViewModel():GetRunningSpineAniName()
end
---------------------------------------------------
-- animation control end --
---------------------------------------------------

---------------------------------------------------
-- performance begin --
---------------------------------------------------
--[[
@override
强制眩晕
@params valid bool 是否有效
--]]
function CardObjectModel:ForceStun(valid)
	BaseObjectModel.ForceStun(self, valid)

	if true == valid then

		-- 眩晕状态 打断当前动作
		self:BreakCurrentAction()

		self:DoAnimation(true, nil, sp.AnimationName.attacked, true)
		self:SetAnimationTimeScale(self:GetAnimationTimeScale())

		--***---------- 刷新渲染层 ----------***--
		self:RefreshRenderAnimation(true, nil, sp.AnimationName.attacked, true)
		self:RefreshRenderAnimationTimeScale(self:GetAnimationTimeScale())
		--***---------- 刷新渲染层 ----------***--
		
	else

		self:DoAnimation(true, nil, sp.AnimationName.idle, true)
		self:SetAnimationTimeScale(self:GetAnimationTimeScale())

		--***---------- 刷新渲染层 ----------***--
		self:RefreshRenderAnimation(true, nil, sp.AnimationName.idle, true)
		self:RefreshRenderAnimationTimeScale(self:GetAnimationTimeScale())
		--***---------- 刷新渲染层 ----------***--

	end
end
--[[
强制消失
@params actionName string 消失时的动作名
@params targetPos string 消失时的目标移动点
@params disappearCallback function 消失后的回调函数
--]]
function CardObjectModel:ForceDisappear(actionName, targetPos, disappearCallback)
	if nil ~= targetPos then
		-- 目标点不为空时 做强制移动
		self:ForceMove(actionName, targetPos, disappearCallback)
	else
		
	end
end
---------------------------------------------------
-- performance end --
---------------------------------------------------

---------------------------------------------------
-- transform begin --
---------------------------------------------------
--[[
@override
变化物体的坐标
@params p cc.p 坐标信息
--]]
function CardObjectModel:ChangePosition(p)
	self:GetViewModel():SetPositionX(p.x)
	self:GetViewModel():SetPositionY(p.y)

	BaseObjectModel.ChangePosition(self, p)
end
--[[
@override
刷新一次逻辑物体的坐标信息
--]]
function CardObjectModel:UpdateLocation()
	BaseObjectModel.UpdateLocation(self)

	-- pos
	self.location.po.x = self:GetViewModel():GetPositionX()
	self.location.po.y = self:GetViewModel():GetPositionY()

	-- rc
	local rc = G_BattleLogicMgr:GetRowColByPos(self:GetViewModel():GetPosition())

	self.location.rc.r = rc.r
	self.location.rc.c = rc.c

	-- 刷新zorder
	if self:IsHighlight() or -1 ~= self:GetDefaultZOrder() then
		self:SetZOrder(G_BattleLogicMgr:GetObjZOrderInBattle(self:GetLocation().po, self:IsEnemy(true), self:IsHighlight()))
	else
		self:SetZOrder(self:GetDefaultZOrder())
	end
end
--[[
重置物体的站位至初始站位
--]]
function CardObjectModel:ResetLocation()
	BaseObjectModel.ResetLocation(self)

	local oriPos = self:GetObjInfo().oriLocation.po

	-- 重置坐标
	self:ChangePosition(oriPos)

	-- 重置朝向
	if self:IsEnemy(true) then
		self:SetOrientation(BattleObjTowards.NEGTIVE)
	else
		self:SetOrientation(BattleObjTowards.FORWARD)
	end
end
--[[
@override
设置朝向
@params towards BattleObjTowards
--]]
function CardObjectModel:SetOrientation(towards)
	self:GetViewModel():SetTowards(towards)
end
--[[
@override
获取朝向
@return _ bool 是否朝向右
--]]
function CardObjectModel:GetOrientation()
	return BattleObjTowards.FORWARD == self:GetViewModel():GetTowards()
end
--[[
@override
获取物体的静态碰撞框信息
@return _ cc.rect 碰撞框信息
--]]
function CardObjectModel:GetStaticCollisionBox()
	return self:GetViewModel():GetStaticCollisionBox()
end
--[[
@override
获取物体静态碰撞框相对于 battle root 的rect信息
@return _ cc.rect 碰撞框信息
--]]
function CardObjectModel:GetStaticCollisionBoxInBattleRoot()
	local collisionBox = self:GetStaticCollisionBox()
	if nil ~= collisionBox then
		local location = self:GetLocation().po
		local fixedBox = cc.rect(
			location.x + collisionBox.x,
			location.y + collisionBox.y,
			collisionBox.width,
			collisionBox.height
		)
		return fixedBox
	else
		return nil
	end
end
--[[
@override
获取物体的静态ui框信息
@return _ cc.rect 碰撞框信息
--]]
function CardObjectModel:GetStaticViewBox()
	return self:GetViewModel():GetStaticViewBox()
end
--[[
@override
根据碰撞框中的坐标获取battleRoot坐标
@params pos cc.p
@return pos_ cc.p
--]]
function CardObjectModel:GetPosInBattleRootByCollisionBoxPos(pos)
	local collisionBox = self:GetStaticCollisionBox()
	local pos_ = cc.p(0, 0)

	pos_.x = self:GetLocation().po.x + collisionBox.x + collisionBox.width * pos.x
	pos_.y = self:GetLocation().po.y + collisionBox.y + collisionBox.height * pos.y

	return pos_
end
--[[
根据骨骼名查找骨骼信息
@params boneName string 骨骼名
@return _ 
--]]
function CardObjectModel:FindBone(boneName)
	return self:GetViewModel():GetBoneDataByBoneName(boneName)
end
--[[
根据骨骼名查找骨骼世界坐标信息
@params boneName string 骨骼名
@return _
--]]
function CardObjectModel:FineBoneInBattleRootSpace(boneName)
	local boneData = self:FindBone(boneName)
	if nil == boneData then return nil end

	return nil
end
---------------------------------------------------
-- transform end --
---------------------------------------------------

---------------------------------------------------
-- event handler begin --
---------------------------------------------------
--[[
注册物体监听事件
--]]
function CardObjectModel:RegisterObjectEventHandler()
	local eventHandlerInfo = {
		{member = 'objDieEventHandler_', 			eventType = ObjectEvent.OBJECT_DIE, 		handler = handler(self, self.ObjectEventDieHandler)},
		{member = 'objReviveEventHandler_', 		eventType = ObjectEvent.OBJECT_REVIVE, 		handler = handler(self, self.ObjectEventReviveHandler)},
		{member = 'objCastEventHandler_', 			eventType = ObjectEvent.OBJECT_CAST_ENTER, 	handler = handler(self, self.ObjectEventCastHandler)},
		{member = 'objLuckEventHandler_', 			eventType = ObjectEvent.OBJECT_LURK, 		handler = handler(self, self.ObjectEventLuckHandler)}
	}

	for _,v in ipairs(eventHandlerInfo) do
		if nil == self[v.member] then
			self[v.member] = v.handler
		end
		G_BattleLogicMgr:AddObjEvent(v.eventType, self, self[v.member])
	end
end
--[[
注销物体监听事件
--]]
function CardObjectModel:UnregistObjectEventHandler()
	local eventHandlerInfo = {
		{member = 'objDieEventHandler_', 			eventType = ObjectEvent.OBJECT_DIE, 		handler = handler(self, self.ObjectEventDieHandler)},
		{member = 'objReviveEventHandler_', 		eventType = ObjectEvent.OBJECT_REVIVE, 		handler = handler(self, self.ObjectEventReviveHandler)},
		{member = 'objCastEventHandler_', 			eventType = ObjectEvent.OBJECT_CAST_ENTER, 	handler = handler(self, self.ObjectEventCastHandler)},
		{member = 'objLuckEventHandler_', 			eventType = ObjectEvent.OBJECT_LURK, 		handler = handler(self, self.ObjectEventLuckHandler)}
	}

	for _,v in ipairs(eventHandlerInfo) do
		G_BattleLogicMgr:RemoveObjEvent(v.eventType, self)
	end
end
--[[
注册展示层的事件处理回调
--]]
function CardObjectModel:RegistViewModelEventHandler()
	if nil ~= self:GetViewModel() then
		-- 注册动作做完的回调
		self:GetViewModel():RegistEventListener(
			sp.EventType.ANIMATION_COMPLETE,
			handler(self, self.SpineEventCompleteHandler)
		)

		-- 注册自定义事件的回调
		self:GetViewModel():RegistEventListener(
			sp.EventType.ANIMATION_EVENT,
			handler(self, self.SpineEventCustomHandler)
		)
	end
end
--[[
注销展示层的事件处理回调
--]]
function CardObjectModel:UnregistViewModelEventHandler()

end
--[[
展示层模拟的spine动画事件处理 [sp.EventType.ANIMATION_COMPLETE]
@params eventType 事件类型
@params event 事件数据 {
	animation string 动画名
}
--]]
function CardObjectModel:SpineEventCompleteHandler(eventType, event)
	if not event then return end

	local eventName = event.animation

	if sp.AnimationName.attack == eventName or nil ~= string.find(eventName, sp.AnimationName.skill) then

		-- attack 和 skill动作需要做一些额外处理
		if OState.ATTACKING == self:GetState() then

			BattleUtils.BattleObjectActionLog(self, '攻击状态 攻击动作完整结束', event.animation)
			-- 攻击中 攻击动作结束
			self.attackDriver:OnActionExit()

		elseif OState.CASTING == self:GetState() then

			BattleUtils.BattleObjectActionLog(self, '施法状态 施法动作完整结束', event.animation)
			-- 施法动作结束 置为正常状态
			self.castDriver:OnActionExit()

		elseif OState.VIEW_TRANSFORM == self:GetState() then

			BattleUtils.BattleObjectActionLog(self, '变形状态 变形动作完整结束', event.animation)
			-- 变形动作结束 置为正常状态
			if nil ~= self.exAbilityDriver then
				self.exAbilityDriver:OnViewTransformExit()
			end

		end

	elseif OState.DIE == self:GetState() then

		BattleUtils.BattleObjectActionLog(self, '死亡动作完整结束', event.animation)

		-- 死亡 隔一帧调用结束回调
		self:DieEnd()

	end
end
--[[
展示层模拟的spine动画事件处理 [sp.EventType.ANIMATION_EVENT]
@params eventType 事件类型
@params event 事件数据 {
	animation string 动画名
	eventData table {
		
	}
}
--]]
function CardObjectModel:SpineEventCustomHandler(eventType, event)
	if GState.START ~= G_BattleLogicMgr:GetGState() or OState.DIE == self:GetState() then return end

	if sp.CustomEvent.cause_effect == event.eventData.name then

		---------- 处理接收到的事件 ----------
		if OState.ATTACKING == self:GetState() then

			BattleUtils.BattleObjectActionLog(self, '攻击状态 获得了spine事件', event.animation, event.eventData.name)
			-- 战斗状态 攻击事件
			local percent = event.eventData.intValue * 0.01
			if percent == 0 then percent = 1 end
			self.attackDriver:Attack(self.attackDriver:GetAttackTargetTag(), percent)

		elseif OState.CASTING == self:GetState() then

			BattleUtils.BattleObjectActionLog(self, '施法状态 获得了spine事件', event.animation, event.eventData.name)

			local percent = event.eventData.intValue * 0.01
			if percent == 0 then percent = 1 end
			self.castDriver:Cast(self.castDriver:GetCastingSkillId(), percent)

		elseif OState.VIEW_TRANSFORM == self:GetState() then

			BattleUtils.BattleObjectActionLog(self, '变形状态 获得了spine事件', event.animation, event.eventData.name)

			if nil ~= self.exAbilityDriver then
				self.exAbilityDriver:ViewTransform()
			end

		end
		---------- 处理接收到的事件 ----------
		
	end
end
--[[
死亡事件监听
@params ... 
	args table passed args
--]]
function CardObjectModel:ObjectEventDieHandler( ... )
	local args = unpack({...})

	local targetTag = args.tag

	local halo = nil
	for i = #self.halos.idx, 1, -1 do
		halo = self.halos.idx[i]
		if halo:HasHaloOuterPileByCasterTag(targetTag) then
			halo:OnRecoverEffectEnter(targetTag)
		end
	end

	if nil ~= self.attackDriver:GetAttackTargetTag() and (targetTag == checkint(self.attackDriver:GetAttackTargetTag())) then
		self:LostAttackTarget()
	end

	-- 如果连携人物死亡 熄灭连携按钮
	if args.cardId and (args.isEnemy == self:IsEnemy(true)) then
		self:ObjectDiedConnectSkillHandler(args.cardId)
	end

end
--[[
复活事件监听
@params ... 
	args table passed args
--]]
function CardObjectModel:ObjectEventReviveHandler( ... )
	local args = unpack({...})
	local targetTag = args.tag

	if targetTag == self:GetOTag() then return end

	-- 如果连携人物复活 恢复连携按钮
	if args.cardId and (args.isEnemy == self:IsEnemy(true)) then
		self:ObjectReviveConnectSkillHandler(args.cardId)
	end
end
--[[
施法事件监听
@params ... 
	args table passed args
--]]
function CardObjectModel:ObjectEventCastHandler( ... )
	local args = unpack({...})
	local targetTag = args.tag
	local obj = G_BattleLogicMgr:IsObjAliveByTag(targetTag)

	if nil ~= obj then
		if nil ~= self.phaseDriver then
			-- 更新一次阶段转换的触发器
			local cardId = obj:GetObjectConfigId()
			local skillId = args.skillId
			local isEnemy = args.isEnemy

			if self.phaseDriver then
				self.phaseDriver:UpdateActionTrigger(
					ActionTriggerType.SKILL,
					{
						npcId = cardId,
						npcCampType = isEnemy and ConfigCampType.ENEMY or ConfigCampType.FRIEND,
						skillId = skillId
					}
				)
			end
		end
	end
end
--[[
隐身事件监听
@params ... 
	args table passed args
--]]
function CardObjectModel:ObjectEventLuckHandler( ... )

end
--[[
@override
击杀事件监听
@params ...
	args table passed args {
		
	}
--]]
function CardObjectModel:ObjectEventSlayHandler( ... )
	local slayData = ...

	local damageBuffType = slayData.damageData:GetDamageBuffType()

	---------- 直接不处理的类型 ----------
	local ruleOutBuffType = {
		[ConfigBuffType.SPIRIT_LINK] = true
	}

	if true == ruleOutBuffType[damageBuffType] then return end
	---------- 直接不处理的类型 ----------

	---------- 击杀回复能量 ----------
	self:AddEnergy(ENERGY_PER_KILL)
	---------- 击杀回复能量 ----------

	---------- 触发触发器 ----------
	self.triggerDriver:OnActionEnter(
		ConfigObjectTriggerActionType.SLAY_OBJECT,
		slayData
	)
	---------- 触发触发器 ----------
end
--[[
人物死亡处理连携技逻辑
@params cardId int obj 卡牌id
--]]
function CardObjectModel:ObjectDiedConnectSkillHandler(cardId)
	self:ChangeConnectSkillStateByCardId(cardId, false)
end
--[[
人物复活处理连携技逻辑
@params cardId int obj 卡牌id
--]]
function CardObjectModel:ObjectReviveConnectSkillHandler(cardId)
	self:ChangeConnectSkillStateByCardId(cardId, true)
end
--[[
刷新一次连携技状态
@params cardId int 连携技成员卡牌id
@params enable bool 是否可用
--]]
function CardObjectModel:ChangeConnectSkillStateByCardId(cardId, enable)
	local connectSkills = self.castDriver:GetConnectSkills()
	if false == enable then

		-- 失效时有一个不满足直接禁用
		for _, skillId in ipairs(connectSkills) do
			-- 判断连携技对象卡牌id
			for _, connectCardId in ipairs(self.castDriver:GetSkillBySkillId(skillId).connectCardId) do
				if cardId == connectCardId then
					-- 将连携技替换为ci
					self.castDriver:InnerChangeConnectSkill(enable)

					---------- 刷新连携技按钮 ----------
					self:EnableConnectSkillButton(skillId, enable)
					---------- 刷新连携技按钮 ----------

					break
				end
			end
		end

	else

		-- 生效时检查所有的连携对象
		for _, skillId in ipairs(connectSkills) do
			local inConnectTeam, canEnable = false, true
			-- 判断连携技对象卡牌id
			for _, connectCardId in ipairs(self.castDriver:GetSkillBySkillId(skillId).connectCardId) do
				if cardId == connectCardId then
					-- 对应本连携技分组
					inConnectTeam = true
				else
					if not G_BattleLogicMgr:IsObjAliveByCardId(connectCardId, self:IsEnemy(true)) then
						-- 有别的对象死亡 无法启用
						canEnable = false
						break
					end
				end
			end
			if inConnectTeam and canEnable then
				-- 将ci替换为替换为连携技
				self.castDriver:InnerChangeConnectSkill(enable)

				---------- 刷新连携技按钮 ----------
				self:EnableConnectSkillButton(skillId, enable)
				---------- 刷新连携技按钮 ----------
			end
		end

	end
end
--[[
检查一次自己的连携技状态
@params enable bool 是否可用
--]]
function CardObjectModel:CheckConnectSkillState()
	local connectSkills = self.castDriver:GetConnectSkills()

	for _, skillId in ipairs(connectSkills) do

		local result = self.castDriver:CanUseConnectSkillByCardAlive(skillId)
		if result then
			-- 连携技可用 替换一次ci为连携技
			self.castDriver:InnerChangeConnectSkill(true)

			---------- 刷新连携技按钮 ----------
			self:EnableConnectSkillButton(skillId, true)
			---------- 刷新连携技按钮 ----------
		else
			-- 连携技可用 替换一次ci为连携技
			self.castDriver:InnerChangeConnectSkill(false)

			---------- 刷新连携技按钮 ----------
			self:EnableConnectSkillButton(skillId, false)
			---------- 刷新连携技按钮 ----------
		end

	end

end
---------------------------------------------------
-- event handler end --
---------------------------------------------------

---------------------------------------------------
-- base info get set begin --
---------------------------------------------------
--[[
获取物体名字
--]]
function CardObjectModel:GetObjectName()
	return 'Tag_'.. self:GetOTag() .. '_ID_' .. self:GetObjectConfigId() .. '_Name_' .. self:GetObjectConfig().name
end
--[[
@override
获取敌友性 是否是敌军
@params o bool 是否获取初始敌友性
@return _ bool 是否是敌军
--]]
function CardObjectModel:IsEnemy(o)
	if true == o then
		return self:GetObjInfo().isEnemy
	end

	-- 魅惑时返回相反的敌友性
	if self:InAbnormalState(AbnormalState.ENCHANTING) then
		return not self:GetObjInfo().isEnemy
	else
		return self:GetObjInfo().isEnemy
	end
end
--[[
获取是否是木桩
@return _ bool 是否是木桩
--]]
function CardObjectModel:IsScarecrow()
	if CardUtils.IsMonsterCard(self:GetObjectConfigId()) then

		local monsterType = checkint(self:GetObjectConfig().type)

		local isScarecrow = (ConfigMonsterType.SCARECROW_TANK == monsterType) or 
			(ConfigMonsterType.SCARECROW_DPS == monsterType) or 
			(ConfigMonsterType.SCARECROW_HEALER == monsterType)

		return isScarecrow

	else
		-- 卡牌默认不是木桩
		return false
	end
end
--[[
@override
获取物体等级
--]]
function CardObjectModel:GetObjectLevel()
	return self:GetMainProperty().level
end
--[[
@override
获取物体怪物类型(计算不同类型物体增伤用)
@return _ ConfigMonsterType
--]]
function CardObjectModel:GetObjectMosnterType()
	if not CardUtils.IsMonsterCard(self:GetObjectConfigId()) then
		return ConfigMonsterType.CARD
	else
		local cardConfig = self:GetObjectConfig()
		return checkint(cardConfig.type)
	end
end
---------------------------------------------------
-- base info get set end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
@override
获取主属性信息
--]]
function CardObjectModel:GetMainProperty()
	return self:GetObjInfo().property
end
--[[
获取物体当前动画的速度缩放
@params o bool 是否获取原始速度
@return timeScale number 速度缩放
--]]
function CardObjectModel:GetAvatarTimeScale(o)
	-- 暂停或者冻结 默认返回0
	if self:IsPause() or self:InAbnormalState(AbnormalState.FREEZE) then return 0 end

	local avatarTimeScale = 1

	if true == o then return avatarTimeScale end

	-- 如果处在攻击的动作中 根据攻速修正动画的缩放值
	if OState.ATTACKING == self:GetState() then
		local attackAniName = sp.AnimationName.attack
		local attackAniData = self:GetActionAnimationConfigBySkillId(ATTACK_2_SKILL_ID)
		if nil ~= attackAniData then
			attackAniName = attackAniData.actionName
		end
		avatarTimeScale = self:GetViewModel():CalcAnimationFixedTimeScale(
			self:GetMainProperty():GetATKCounter(),
			attackAniName
		)
	end

	return avatarTimeScale
end
--[[
获取物体的特效配置信息
--]]
function CardObjectModel:GetObjectEffectConfig()
	return CardUtils.GetCardEffectConfigBySkinId(self:GetObjectConfigId(), self:GetObjectSkinId())
end
--[[
@override
获取展示层tag
--]]
function CardObjectModel:GetViewModelTag()
	return self:GetViewModel():GetViewModelTag()
end
--[[
根据类型获取属性值
@override
@params propertyType ObjP
@params isOriginal bool 是否获取的初始值
@return _ number 加成后的属性
--]]
function CardObjectModel:GetPropertyByObjP(propertyType, isOriginal)
	if ObjP.ENERGY == propertyType then
		if isOriginal then
			return self:GetMaxEnergy()
		else
			return self:GetEnergy()
		end
	else
		if isOriginal then
			return self:GetMainProperty():GetCurrentP(propertyType)
		else
			return self:GetMainProperty():GetOriginalP(propertyType)
		end
	end
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

---------------------------------------------------
-- render refresh begin --
---------------------------------------------------
--[[
@override
同步一次坐标
--]]
function CardObjectModel:RefreshRenderViewPosition()
	--***---------- 刷新渲染层 ----------***--
	G_BattleLogicMgr:AddRenderOperate(
		'G_BattleRenderMgr',
		'SetObjectViewPosition',
		self:GetViewModelTag(),
		self:GetLocation().po.x,
		self:GetLocation().po.y
	)

	G_BattleLogicMgr:AddRenderOperate(
		'G_BattleRenderMgr',
		'SetObjectViewZOrder',
		self:GetViewModelTag(),
		self:GetZOrder()
	)
	--***---------- 刷新渲染层 ----------***--
end
--[[
@override
同步一次朝向
--]]
function CardObjectModel:RefreshRenderViewTowards()
	--***---------- 刷新渲染层 ----------***--
	G_BattleLogicMgr:AddRenderOperate(
		'G_BattleRenderMgr',
		'SetObjectViewTowards',
		self:GetViewModelTag(),
		self:GetTowards()
	)
	--***---------- 刷新渲染层 ----------***--
end
--[[
@override
做spine动画
@params setToSetupPose bool 是否恢复第一帧
@params timeScale int 动画速度缩放
@params setAnimationName string set的动画名字
@params setAnimationLoop bool set的动画是否循环
@params addAnimationName string add的动画名字
@params addAnimationLoop bool add的动画是否循环
--]]
function CardObjectModel:RefreshRenderAnimation(setToSetupPose, timeScale, setAnimationName, setAnimationLoop, addAnimationName, addAnimationLoop)
	--***---------- 刷新渲染层 ----------***--
	G_BattleLogicMgr:AddRenderOperate(
		'G_BattleRenderMgr',
		'ObjectViewDoAnimation',
		self:GetViewModelTag(),
		setToSetupPose, timeScale, setAnimationName, setAnimationLoop, addAnimationName, addAnimationLoop
	)
	--***---------- 刷新渲染层 ----------***--
end
--[[
@override
清除所有spine动画
--]]
function CardObjectModel:ClearRenderAnimations()
	--***---------- 刷新渲染层 ----------***--
	G_BattleLogicMgr:AddRenderOperate(
		'G_BattleRenderMgr',
		'ClearObjectViewAnimations',
		self:GetViewModelTag()
	)
	--***---------- 刷新渲染层 ----------***--
end
--[[
@override
设置动画的时间缩放
@params timeScale number 时间缩放
--]]
function CardObjectModel:RefreshRenderAnimationTimeScale(timeScale)
	--***---------- 刷新渲染层 ----------***--
	G_BattleLogicMgr:AddRenderOperate(
		'G_BattleRenderMgr',
		'ObjectViewSetAnimationTimeScale',
		self:GetViewModelTag(),
		timeScale
	)
	--***---------- 刷新渲染层 ----------***--
end
--[[
根据能量刷新所有连携技按钮
--]]
function CardObjectModel:RefreshConnectButtonsByEnergy()
	--***---------- 刷新渲染层 ----------***--
	G_BattleLogicMgr:AddRenderOperate(
		'G_BattleRenderMgr',
		'RefreshObjectConnectButtonsByEnergy',
		self:GetOTag(),
		self:GetEnergyPercent()
	)
	--***---------- 刷新渲染层 ----------***--
end
--[[
根据状态刷新所有连携技按钮
--]]
function CardObjectModel:RefreshConnectButtonsByState()
	--***---------- 刷新渲染层 ----------***--
	G_BattleLogicMgr:AddRenderOperate(
		'G_BattleRenderMgr',
		'RefreshObjectConnectButtonsByState',
		self:GetOTag(),
		self:CanAct(), self:GetState(), not self:CanCastConnectByAbnormalState()
	)
	--***---------- 刷新渲染层 ----------***--
end
--[[
点亮熄灭连携技按钮
@params skillId int 技能id
@params enable bool 是否可用
--]]
function CardObjectModel:EnableConnectSkillButton(skillId, enable)
	--***---------- 刷新渲染层 ----------***--
	G_BattleLogicMgr:AddRenderOperate(
		'G_BattleRenderMgr',
		'EnableConnectSkillButton',
		self:GetOTag(),
		skillId, enable
	)
	--***---------- 刷新渲染层 ----------***--
	self:RefreshConnectButtonsByState()
end
--[[
刷新渲染层血条
--]]
function CardObjectModel:UpdateHpBar()
	--***---------- 刷新渲染层 ----------***--
	G_BattleLogicMgr:AddRenderOperate(
		'G_BattleRenderMgr',
		'SetObjectViewHpPercent',
		self:GetViewModelTag(),
		self:GetHPPercent()
	)
	--***---------- 刷新渲染层 ----------***--
end
--[[
刷新渲染层能量条
--]]
function CardObjectModel:UpdateEnergyBar()
	--***---------- 刷新渲染层 ----------***--
	G_BattleLogicMgr:AddRenderOperate(
		'G_BattleRenderMgr',
		'SetObjectViewEnergyPercent',
		self:GetViewModelTag(),
		self:GetEnergyPercent()
	)
	--***---------- 刷新渲染层 ----------***--
end
--[[
显示免疫文字
--]]
function CardObjectModel:ShowImmune()
	--***---------- 刷新渲染层 ----------***--
	G_BattleLogicMgr:AddRenderOperate(
		'G_BattleRenderMgr',
		'ShowObjectViewImmune',
		self:GetViewModelTag()
	)
	--***---------- 刷新渲染层 ----------***--
end
--[[
添加个一个buff icon
@params iconType BuffIconType
@params value number 数值
--]]
function CardObjectModel:AddBuffIcon(iconType, value)
	--***---------- 刷新渲染层 ----------***--
	G_BattleLogicMgr:AddRenderOperate(
		'G_BattleRenderMgr',
		'ObjectViewAddABuffIcon',
		self:GetViewModelTag(),
		iconType, value
	)
	--***---------- 刷新渲染层 ----------***--
end
--[[
移除一个buff icon
@params iconType BuffIconType
@params value number 数值
--]]
function CardObjectModel:RemoveBuffIcon(iconType, value)
	--***---------- 刷新渲染层 ----------***--
	G_BattleLogicMgr:AddRenderOperate(
		'G_BattleRenderMgr',
		'ObjectViewRemoveABuffIcon',
		self:GetViewModelTag(),
		iconType, value
	)
	--***---------- 刷新渲染层 ----------***--
end
--[[
显示被击爆点
@params effectData HurtEffectStruct 被击特效数据
--]]
function CardObjectModel:ShowHurtEffect(effectData)
	--***---------- 刷新渲染层 ----------***--
	-- 特效
	G_BattleLogicMgr:AddRenderOperate(
		'G_BattleRenderMgr',
		'ObjectViewShowHurtEffect',
		self:GetViewModelTag(),
		effectData
	)
	--***---------- 刷新渲染层 ----------***--
end
--[[
显示附加特效
@params visible bool 是否可见
@params	buffId string buff id
@params effectData AttachEffectStruct 被击特效数据
--]]
function CardObjectModel:ShowAttachEffect(visible, buffId, effectData)
	--***---------- 刷新渲染层 ----------***--
	G_BattleLogicMgr:AddRenderOperate(
		'G_BattleRenderMgr',
		'ObjectViewShowAttachEffect',
		self:GetViewModelTag(),
		visible, buffId, effectData
	)
	--***---------- 刷新渲染层 ----------***--
end
--[[
@override
向渲染层发起初始化
--]]
function CardObjectModel:InitObjectRender()
	-- 初始化动作
	self:DoAnimation(false, nil, sp.AnimationName.idle, true)
	-- 刷新动画
	self:RefreshRenderAnimation(false, nil, sp.AnimationName.idle, true)

	-- 刷新坐标
	self:RefreshRenderViewPosition()
	-- 刷新朝向
	self:RefreshRenderViewTowards()
	-- 刷新血条
	self:UpdateHpBar()
	-- 刷新能量条
	self:UpdateEnergyBar()
end
--[[
@override
物体喊话对话框
@params dialogueFrameType int 对话框气泡类型
@params content string 对话内容
--]]
function CardObjectModel:Speak(dialogueFrameType, content)
	--***---------- 刷新渲染层 ----------***--
	G_BattleLogicMgr:AddRenderOperate(
		'G_BattleRenderMgr',
		'ObjectViewSpeak',
		self:GetViewModelTag(),
		dialogueFrameType, content
	)
	--***---------- 刷新渲染层 ----------***--
end
--[[
@override
强制显示或者隐藏自己
@params show bool 是否显示
--]]
function CardObjectModel:ForceShowSelf(show)
	--***---------- 刷新渲染层 ----------***--
	G_BattleLogicMgr:AddRenderOperate(
		'G_BattleRenderMgr',
		'SetObjectViewVisible',
		self:GetViewModelTag(),
		show
	)
	--***---------- 刷新渲染层 ----------***--
end
--[[
@override
显示目标mark
@params stageCompleteType ConfigStageCompleteType 过关类型
@params show bool 是否显示 
--]]
function CardObjectModel:ShowStageClearTargetMark(stageCompleteType, show)
	--***---------- 刷新渲染层 ----------***--
	G_BattleLogicMgr:AddRenderOperate(
		'G_BattleRenderMgr',
		'ObjectViewShowTargetMark',
		self:GetViewModelTag(),
		stageCompleteType, show
	)
	--***---------- 刷新渲染层 ----------***--
end
--[[
@override
隐藏所有目标mark
--]]
function CardObjectModel:HideAllStageClearTargetMark()
	--***---------- 刷新渲染层 ----------***--
	G_BattleLogicMgr:AddRenderOperate(
		'G_BattleRenderMgr',
		'ObjectViewHideAllTargetMark',
		self:GetViewModelTag()
	)
	--***---------- 刷新渲染层 ----------***--
end
--[[
@override
复活
--]]
function CardObjectModel:ReviveRender()
	--***---------- 刷新渲染层 ----------***--
	G_BattleLogicMgr:AddRenderOperate(
		'G_BattleRenderMgr',
		'ObjectViewRevive',
		self:GetViewModelTag()
	)
	--***---------- 刷新渲染层 ----------***--
end
---------------------------------------------------
-- render refresh end --
---------------------------------------------------

return CardObjectModel

--[[
卡牌物体模型
@params t table {
	tag int obj tag
	oname string obj name
	battleElementType BattleElementType 战斗元素大类型
	objInfo ObjectConstructorStruct 战斗物体构造函数
}
--]]
local BaseObject = __Require('battle.object.BaseObject')
local CardObject = class('CardObject', BaseObject)

------------ import ------------
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
------------ import ------------

--[[
@override
constructor
--]]
function CardObject:ctor( ... )
	local args = unpack({...})

	------------ 初始化id信息 ------------
	self.idInfo = {
		tag = args.tag,
		oname = args.oname,
		battleElementType = args.battleElementType
	}
	------------ 初始化id信息 ------------

	------------ 初始化卡牌基本信息 ------------
	self.objInfo = args.objInfo
	------------ 初始化卡牌基本信息 ------------
	
	------------ 初始化ui信息 ------------
	self.view = {
		viewComponent = nil,
		avatar = nil,
		animationsData = nil,
		hpBar = nil,
		energyBar = nil,
	}
	------------ 初始化ui信息 ------------

	self:init()
	self:registerObjEventHandler()

end
---------------------------------------------------
-- init logic begin --
---------------------------------------------------
--[[
@override
初始化逻辑
--]]
function CardObject:init()
	self:initValue()
	self:InitViewModel()
	self:initView()
	self:initDrivers()
	self:initSkillImmune()
	self:initWeatherImmune()
	self:initSpineCallback()
end
--[[
@override
初始化个体属性
--]]
function CardObject:initUnitProperty()
	------------ location info ------------
	self.location = ObjectLocation.New(
		self.objInfo.oriLocation.po.x,
		self.objInfo.oriLocation.po.y,
		self.objInfo.oriLocation.po.r,
		self.objInfo.oriLocation.po.c
	)
	------------ location info ------------

	------------ energy info ------------
	self.energy = self:getMainProperty():CalcFixedInitEnergy(self.objInfo.isLeader)
	self.energyRecoverRate = RBQN.New(0)
	------------ energy info ------------

	------------ view info ------------
	self.drawPathInfo = nil
	if nil ~= self:getOSkinId() then
		-- 初始化资源信息
		self.drawPathInfo = cardMgr.GetCardDrawPathInfoBySkinId(self:getOSkinId())
	end
	------------ view info ------------

	------------ other info ------------
	-- 仇恨
	self.hate = checkint(self:getObjectConfig().threat or 0)
	------------ other info ------------

	------------ effect info ------------
	local effect = CardUtils.GetCardEffectConfigBySkinId(self:getOCardId(), self:getOSkinId())
	self.spineActionData = {
		attack = SkillSpineEffectStruct.New(-1, effect)
	}
	------------ effect info ------------
end
--[[
@override
初始化技能免疫
--]]
function CardObject:initSkillImmune()
	-- 根据卡牌配置初始化内置的buff免疫
	local cardConf = self:getObjectConfig()
	if nil ~= cardConf.immunitySkillProperty then
		for _, buffType in ipairs(cardConf.immunitySkillProperty) do
			self:setInnerSkillBuffTypeImmune(buffType, true)
		end
	end
end
--[[
@override
初始化天气免疫
--]]
function CardObject:initWeatherImmune()
	local cardConf = self:getObjectConfig()
	if nil ~= cardConf.weatherProperty then
		for i,v in ipairs(cardConf.weatherProperty) do
			self.immune.weather[tostring(v)] = true
		end
	end
end
--[[
@override
初始化行为驱动器
--]]
function CardObject:initDrivers()
	------------ drivers ------------
	-- 随机数驱动器
	self.randomDriver = __Require('battle.object.RandomDriver').new({
		ownerTag = self:getOTag()
	})

	-- 攻击和移动驱动器
	local attackDriverClassName = 'BaseAttackDriver'
	local moveDriverClassName = 'BaseMoveDriver'
	if BattleObjectFeature.REMOTE == self:getOFeature() then
		attackDriverClassName = 'RemoteAttackDriver'
		moveDriverClassName = 'RemoteMoveDriver'
	elseif BattleObjectFeature.HEALER == self:getOFeature() then
		attackDriverClassName = 'HealAttackDriver'
		moveDriverClassName = 'RemoteMoveDriver'
	end
	self.attackDriver = __Require(string.format('battle.objectDriver.%s', attackDriverClassName)).new({owner = self})
	self.moveDriver = __Require(string.format('battle.objectDriver.%s', moveDriverClassName)).new({owner = self})

	-- 施法驱动器
	self.castDriver = __Require('battle.objectDriver.BaseCastDriver').new({owner = self})

	-- 阶段转换启动器
	self.phaseDriver = nil
	if nil ~= self.objInfo.phaseChangeData then
		self.phaseDriver = __Require('battle.objectDriver.BasePhaseDriver').new({owner = self, phaseChangeData = self.objInfo.phaseChangeData})
	end
	self.objInfo.phaseChangeData = nil

	-- 变色驱动器
	self.tintDriver = __Require('battle.objectDriver.BaseTintDriver').new({owner = self})

	-- 触发驱动器
	self.triggerDriver = __Require('battle.objectDriver.BaseTriggerDriver').new({owner = self})

	-- 神器天赋驱动器
	self.artifactTalentDriver = __Require('battle.objectDriver.BaseArtifactTalentDriver').new({owner = self, talentData = self.objInfo.talentData})

	-- buff驱动器
	self.buffDriver = __Require('battle.objectDriver.BaseBuffDriver').new({owner = self})
	------------ drivers ------------

	------------ drivers ------------
	self.synchronizeDriver = __Require('battle.objectDriver.BaseSynchronizeDriver').new({owner = self})
	------------ drivers ------------

	-- 激活一次驱动器
	self:activateDrivers()
end
--[[
@override
激活一次驱动器
--]]
function CardObject:activateDrivers()
	-- 激活一次神器天赋驱动器
	self.artifactTalentDriver:OnActionEnter()
end
--[[
@override
初始化展示层
--]]
function CardObject:initView()
	local viewClassName = 'battle.objectView.CardObjectView'
	if CardUtils.IsMonsterCard(self.objInfo.cardId) then
		viewClassName = 'battle.objectView.MonsterView'
		if ConfigMonsterType.BOSS == checkint(self:getObjectConfig().type) then
			viewClassName = 'battle.objectView.BossView'
		end
	end

	local viewInfo = ObjectViewConstructStruct.New(
		self:getOCardId(),
		self:getOSkinId(),
		self.objInfo.avatarScale,
		BMediator:GetSpineAvatarScale2CardByCardId(self:getOCardId()),
		self:isEnemy(true)
	)

	local view = __Require(viewClassName).new({
		tag = self:getOTag(),
		viewInfo = viewInfo
	})
	self.view.viewComponent = view
	self.view.avatar = view:getAvatar()
	self.view.animationsData = self.view.avatar:getAnimationsData()
	self.view.hpBar = view.viewData.hpBar
	self.view.energyBar = view.viewData.energyBar

	self:DoSpineAnimation(false, nil, sp.AnimationName.idle, true)

	-- 初始化朝向
	if self:isEnemy() then
		self:changeOrientation(false)
	else
		self:changeOrientation(true)
	end

	-- 设置血条数值
 	------------ 此处修正一次血量 大血量会超出范围 ------------
 	local maxValue = HP_BAR_MAX_VALUE
 	local hpPercent = math.max(0, math.ceil(self:getMainProperty():getCurrentHp() / self:getMainProperty():getOriginalHp() * 10000) * 0.0001)
 	local value = maxValue * hpPercent
 	------------ 此处修正一次血量 大血量会超出范围 ------------
	self.view.hpBar:setMaxValue(maxValue)
	self.view.hpBar:setValue(value)
	self:updateHpBar(true)

	-- 设置能量条数值
	self.view.energyBar:setMaxValue(MAX_ENERGY)
	self.view.energyBar:setValue(self:getEnergy():ObtainVal())

	-- 设置zorder
	self.view.viewComponent:setPosition(self.objInfo.oriLocation.po)
	self:updateLocation()

end
--[[
初始化spine动画触发的回调
--]]
function CardObject:initSpineCallback()
	-- 初始化spine事件
	if nil == self:GetViewModel() then
		self:getSpineAvatar():registerSpineEventHandler(handler(self, self.spineEventCompleteHandler), sp.EventType.ANIMATION_COMPLETE)
		self:getSpineAvatar():registerSpineEventHandler(handler(self, self.spineEventCustomHandler), sp.EventType.ANIMATION_EVENT)
	end
end
--[[
@override
注册战斗物体通信的回调函数
--]]
function CardObject:registerObjEventHandler()
	if nil == self.objDieEventHandler_ then
		self.objDieEventHandler_ = handler(self, self.objDieEventHandler)
	end
	BMediator:AddObjEvent(ObjectEvent.OBJECT_DIE, self, self.objDieEventHandler_)

	if nil == self.objReviveEventHandler_ then
		self.objReviveEventHandler_ = handler(self, self.objReviveEventHandler)
	end
	BMediator:AddObjEvent(ObjectEvent.OBJECT_REVIVE, self, self.objReviveEventHandler_)

	if nil == self.objCastEventHandler_ then
		self.objCastEventHandler_ = handler(self, self.objCastEventHandler)
	end
	BMediator:AddObjEvent(ObjectEvent.OBJECT_CAST_ENTER, self, self.objCastEventHandler_)

	if nil == self.objLuckEventHandler_ then
		self.objLuckEventHandler_ = handler(self, self.objLuckEventHandler)
	end
	BMediator:AddObjEvent(ObjectEvent.OBJECT_LURK, self, self.objLuckEventHandler_)
end
--[[
@override
销毁战斗物体通信的回调函数
--]]
function CardObject:unregisterObjEventHandler()
	BMediator:RemoveObjEvent(ObjectEvent.OBJECT_DIE, self)
	BMediator:RemoveObjEvent(ObjectEvent.OBJECT_REVIVE, self)
	BMediator:RemoveObjEvent(ObjectEvent.OBJECT_CAST_ENTER, self)
	BMediator:RemoveObjEvent(ObjectEvent.OBJECT_LURK, self)
end
--[[
@override
初始化展示层的逻辑
--]]
function CardObject:InitViewModel()
	local skinId = self:getOSkinId()
	local skinConfig = CardUtils.GetCardSkinConfig(skinId)

	local spineDataStruct = BattleUtils.GetAvatarSpineDataStructBySpineId(
		skinConfig.spineId,
		BMediator:GetSpineAvatarScaleByCardId(self:getOCardId())
	)
	local viewModel = __Require('battle.viewModel.SpineViewModel').new(
		ObjectViewModelConstructorStruct.New(
			self:getOTag(),
			self.objInfo.avatarScale,
			spineDataStruct
		)
	)
	self:SetViewModel(viewModel)

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

	-- 向内存中添加一个展示层模型
	viewModel:Awake()
end
---------------------------------------------------
-- init logic end --
---------------------------------------------------

---------------------------------------------------
-- state logic begin --
---------------------------------------------------
--[[
@override
awake logic
唤醒obj
--]]
function CardObject:awake()
	BaseObject.awake(self)
	---------- 刷新连携技按钮状态 ----------
	self:refreshConnectButtons()
	---------- 刷新连携技按钮状态 ----------
end
--[[
@override
sleep logic
睡眠obj
--]]
function CardObject:sleep()
	BaseObject.sleep(self)
	---------- 刷新连携技按钮状态 ----------
	self:refreshConnectButtons()
	---------- 刷新连携技按钮状态 ----------
end
--[[
@override
沉默
@params s bool 是否被沉默
--]]
function CardObject:silent(s)
	BaseObject.silent(self, s)

	if true == s then
		-- 打断技能
		if OState.CASTING == self:getState() then
			self.castDriver:OnActionBreak()
		end
	end
	
	---------- 刷新连携技按钮状态 ----------
	self:refreshConnectButtonsByState()
	---------- 刷新连携技按钮状态 ----------
end
--[[
@override
设置暂停
--]]
function CardObject:pauseObj()
	BaseObject.pauseObj(self)
	self:SetSpineTimeScale(0)
	self.view.viewComponent:pauseView()
end
--[[
@override
恢复暂停
--]]
function CardObject:resumeObj()
	BaseObject.resumeObj(self)
	self:SetSpineTimeScale(self:getAvatarTimeScale())
	self.view.viewComponent:resumeView()
end
--[[
是否活着
--]]
function CardObject:isAlive()
	return OState.DIE ~= self:getState() and 0 < self:getMainProperty():getCurrentHp():ObtainVal()
end
---------------------------------------------------
-- state logic end --
---------------------------------------------------

---------------------------------------------------
-- action logic begin --
---------------------------------------------------
--[[
@override
索敌行为
--]]
function CardObject:seekAttackTarget()
	self.attackDriver:SeekAttackTarget()
end
--[[
@override
移动
@params dt number delta time
@params targetTag int 移动对象tag
--]]
function CardObject:move(dt, targetTag)
	self.moveDriver:OnActionUpdate(dt, targetTag)
end
--[[
@override
攻击
@params targetTag int 攻击对象tag
--]]
function CardObject:attack(targetTag)
	self.attackDriver:OnActionEnter(targetTag)
end
--[[
@override
施法
@params skillId int 技能id
--]]
function CardObject:cast(skillId)
	self.castingSkillId = skillId
	self.castDriver:OnActionEnter(skillId)
end
--[[
释放连携技能
@params skillId int 连携技id
--]]
function CardObject:castConnectSkill(skillId)
	if true == self.castDriver:CanDoAction(ActionTriggerType.CONNECT, skillId) then
		-- 打断技能
		if OState.CASTING == self:getState() then
			self.castDriver:OnActionBreak()
		elseif OState.ATTACKING == self:getState() then
			self.attackDriver:OnActionBreak()
		end
		self.castingSkillId = skillId
		self.castDriver:OnActionEnter(skillId)
	else
		print('不能释放连携技能')
	end
end
--[[
@override
变化朝向
@params b bool if is towards to right
--]]
function CardObject:changeOrientation(b)
	if self:getOrientation() == b then
		return
	end
	local avatarScale = 1
	self.state.towards = b and 1 or -1
	self.view.avatar:setScaleX(math.abs(self.view.avatar:getScaleX()) * self.state.towards * avatarScale)
end
--[[
@override
受到伤害 攻击方传来的伤害 先检查无敌 后消耗护盾
@params damageData ObjectDamageStruct 伤害信息
@params noTrigger bool 不触发任何触发器
--]]
function CardObject:beAttacked(damageData, noTrigger)
	if not self:isAlive() then return end

	-- 被击增加能量
	self:addEnergy(ENERGY_PER_HURT)

	local damage = damageData.damage

	if 0 < damage:ObtainVal() then

		---------- 伤害为正 被击 ----------

		-- 判断伤害免疫
		if self:isDamageImmune(DamageType.PHYSICAL) or
			self:isDamageImmune(damageData.damageType) or 
			self:isGlobalDamageImmune(DamageType.PHYSICAL) or
			self:isGlobalDamageImmune(damageData.damageType) or 
			self:isImmune(BKIND.INSTANT) then

			return

		end

		---------- 根据护盾计算伤害抵消 ----------
		damage = self:CalcFixedDamageByShield(damage)
		---------- 根据护盾计算伤害抵消 ----------

	else

		---------- 伤害为负 被奶 ----------

		-- 被奶逻辑单独实现

	end

	---------- 修正最终减伤 ----------
	damage = self:CalcFixedDamageByObjPP(damage, damageData)
	---------- 修正最终减伤 ----------

	if 0 == damage:ObtainVal() then return end

	---------- 由buff效果产生的伤害抵消 ----------
	damage = self:CalcFixedDamageByBuff(damage, damageData)
	---------- 由buff效果产生的伤害抵消 ----------

	if 0 == damage:ObtainVal() then return end

	damageData:SetDamageValue(damage)

	---------- 变化血量 ----------
	self:hpChange(damageData)
	---------- 变化血量 ----------

	-- 刷新触发器
	self.castDriver:UpdateActionTrigger(ActionTriggerType.HP, self:getMainProperty():getCurHpPercent())
	-- 转阶段触发器
	if self.phaseDriver then
		self.phaseDriver:UpdateActionTrigger(ActionTriggerType.HP, self:getMainProperty():getCurHpPercent())
	end

	---------- 触发器 ----------
	if not noTrigger then
		local attackerTag = nil
		if not damageData:CausedBySkill() then
			attackerTag = damageData.attackerTag
		end
		-- 受到伤害
		self.triggerDriver:OnActionEnter(ConfigObjectTriggerActionType.GOT_DAMAGE, ObjectTriggerParameterStruct.New(attackerTag))
		if damageData.isCritical then
			-- 受到暴击伤害
			self.triggerDriver:OnActionEnter(ConfigObjectTriggerActionType.GOT_DAMAGE_CRITICAL, ObjectTriggerParameterStruct.New(attackerTag))
		end
	end
	---------- 触发器 ----------

	---------- view ----------
	-- 被击动画
	if sp.AnimationName.idle == self:GetCurrentSpineAnimationName() then
		self:DoSpineAnimation(true, nil, sp.AnimationName.attacked, false, sp.AnimationName.idle, true)
	end

	-- 变色
	self.tintDriver:OnActionEnter(BattleObjTintPattern.BOTP_BLOOD)
	---------- view ----------

end
--[[
根据护盾效果计算一次伤害减免
@params damage number 伤害值
@return damage number 伤害值
--]]
function CardObject:CalcFixedDamageByShield(damage)
	-- 护盾抵消
	local damage_ = RBQN.New(damage)

	for i = #self.shield, 1, -1 do
		damage_ = RBQN.New(damage_ - self.shield[i]:OnCauseEffectEnter(damage_))
	end

	return damage_
end
--[[
根据属性系数计算一次伤害减免
@params damage number 伤害值
@params damageData ObjectDamageStruct 伤害信息
@params damage number 伤害值
--]]
function CardObject:CalcFixedDamageByObjPP(damage, damageData)
	---------- 修正最终减伤 ----------
	damage = self:getMainProperty():fixFinalGetDamage(damage, damageData.damageType)
	---------- 修正最终减伤 ----------

	return damage
end
--[[
根据特殊buff计算一次伤害减免
@params damage number 伤害值
@params damageData ObjectDamageStruct 伤害信息
@params damage number 伤害值
--]]
function CardObject:CalcFixedDamageByBuff(damage, damageData)
	---------- 由buff效果产生的伤害抵消 ----------
	local damageReduceConfig = {
		ConfigBuffType.SACRIFICE, 			-- 牺牲
		ConfigBuffType.STAGGER 				-- 醉拳
	}

	for _, reduceBuffType in ipairs(damageReduceConfig) do
		if (nil == damageData.skillInfo) or (reduceBuffType ~= damageData.skillInfo.btype) then
			local targetBuffs = self:GetBuffsByBuffType(reduceBuffType, false)
			for i = #targetBuffs, 1, -1 do
				damage = damage - targetBuffs[i]:OnCauseEffectEnter(damage, damageData)

				if 0 == damage then
					return RBQN.New(damage)
				end
			end
		end
	end
	---------- 由buff效果产生的伤害抵消 ----------

	return RBQN.New(damage)
end
--[[
@override
受到治疗
@params healData ObjectDamageStruct 治疗信息
@params noTrigger bool 不触发任何触发器
--]]
function CardObject:beHealed(healData, noTrigger)
	if not self:isAlive() or healData.damage:ObtainVal() == 0 then return end

	---------- 判断治疗免疫 ----------
	if self:isDamageImmune(DamageType.HEAL) or 
		self:isDamageImmune(healData.damageType) or
		self:isGlobalDamageImmune(DamageType.HEAL) or 
		self:isGlobalDamageImmune(healData.damageType) then

		return

	end
	---------- 判断治疗免疫 ----------

	---------- 治疗溢出 ----------
	local overflowHeal = self:getMainProperty():getCurrentHp() + healData.damage - self:getMainProperty():getOriginalHp()
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

	---------- 变化血量 ----------
	self:hpChange(healData)
	---------- 变化血量 ----------

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
@override
最终血量变化 不计算减伤
@params damageData ObjectDamageStruct 伤害信息
--]]
function CardObject:hpChange(damageData)
	-- 计算差值
	local delta = damageData.damage
	local damageNumberStartPos = self:getPosInCollisionBoxWorldSpace(cc.p(0.5, 1))
	local causeDamageObj = nil

	if nil ~= damageData.attackerTag then

		delta = -1 * delta
		damageNumberStartPos = self:getPosInCollisionBoxWorldSpace(cc.p(0.5, 0.8))
		causeDamageObj = BMediator:IsObjAliveByTag(damageData.attackerTag)

		-- 判断是否致死
		-- /***********************************************************************************************************************************\
		--  * !!!由于是在下一帧判断是否死亡 此处可能会触发多次!!!
		-- \***********************************************************************************************************************************/
		if self:getMainProperty():isDamageDeadly(delta) then
			---------- 击杀者回调 ----------
			local attacker = BMediator:IsObjAliveByTag(damageData.attackerTag)
			if attacker then
				local slayData = SlayObjectStruct.New(
					self:getOTag(),
					damageData,
					self:getMainProperty():getCurrentHp() + delta
				)
				attacker:slayObjEventHandler(slayData)
			end
			---------- 击杀者回调 ----------

			-- 受到致死伤害
			self.triggerDriver:OnActionEnter(ConfigObjectTriggerActionType.GOT_DEADLY_DAMAGE)
		end

	elseif nil ~= damageData.healerTag then

		causeDamageObj = BMediator:IsObjAliveByTag(damageData.healerTag)

	end

	-- 变化血量
	self:getMainProperty():setp(ObjP.HP, self:getMainProperty():getCurrentHp() + delta)

	-- 不能超过血上限
	if self:getMainProperty():getOriginalHp() < self:getMainProperty():getCurrentHp() then

		self:getMainProperty():setp(ObjP.HP, self:getMainProperty():getOriginalHp())

	elseif 0 >= self:getMainProperty():getCurrentHp():ObtainVal() then

		self:getMainProperty():setp(ObjP.HP, 0)

	end

	-- 刷新一次血量百分比
	self:getMainProperty():updateCurHpPercent()

	-- 刷新血条
	self:updateHpBar()

	-- 伤害数字
	BMediator:ShowDamageNumber(
		damageData,
		damageNumberStartPos,
		self:getOrientation()
	)

	-- 记录战斗数据
	local energy = nil
	if causeDamageObj and causeDamageObj.getEnergy then
		energy = causeDamageObj:getEnergy():ObtainVal()
	end
	BMediator:GetBData():addADamageStr(damageData, damageData.damage:ObtainVal(), energy)
end
--[[
@override
被施法
@params buffInfo table buff信息
@return _ bool 是否成功加上了该buff
--]]
function CardObject:beCasted(buffInfo)
	
	------------ 天气免疫 ------------
	if BattleElementType.BET_WEATHER == BMediator:GetBattleElementTypeByTag(buffInfo.casterTag) then
		if true == self:isImmuneByWeatherId(buffInfo.weatherId) then
			self.view.viewComponent:showImmune(ImmuneType.IT_WEATHER)
			return false
		end
	end
	------------ 天气免疫 ------------

	------------ buff免疫 ------------
	-- 排除列表 在buff内部判断
	local ruleOutBuffType = {
		[ConfigBuffType.EXECUTE] = true
	}
	if true ~= ruleOutBuffType[buffInfo.btype] then
		if true == self:isBuffImmune(buffInfo.btype) then
			self.view.viewComponent:showImmune(ImmuneType.IT_SKILL)
			return false
		end
	end
	------------ buff免疫 ------------

	------------ 内部免疫 ------------
	if (ConfigBuffType.STUN == buffInfo.btype and true == self.immune.stun) or
		(ConfigBuffType.SILENT == buffInfo.btype and true == self.immune.silent) or
		(ConfigBuffType.FREEZE == buffInfo.btype and true == self.immune.freeze) or
		(ConfigBuffType.ENCHANTING == buffInfo.btype and true == self.immune.enchanting) then

		self.view.viewComponent:showImmune(ImmuneType.IT_SKILL)
		return false

	end
	------------ 内部免疫 ------------

	if BuffCauseEffectTime.INSTANT == buffInfo.causeEffectTime then

		-- 立刻起效buff 不加入缓存
		local buff = __Require(buffInfo.className).new(buffInfo)
		buff:OnCauseEffectEnter()

	else

		-- 需要加入buff缓存中的buff
		if buffInfo.isHalo then
			local buff = self:getHaloByBuffId(buffInfo.bid)
			if nil == buff then
				buff = __Require(buffInfo.className).new(buffInfo)
				self:addHalo(buff)

				---------- 触发器 ----------
				-- add buff
				self.triggerDriver:OnActionEnter(ConfigObjectTriggerActionType.GOT_BUFF)
				---------- 触发器 ----------
			else
				buff:OnRefreshBuffEnter(buffInfo)

				---------- 触发器 ----------
				-- add buff
				self.triggerDriver:OnActionEnter(ConfigObjectTriggerActionType.REFRESH_BUFF)
				---------- 触发器 ----------
			end
		else
			local buff = self:getBuffByBuffId(buffInfo.bid)
			if nil == buff then
				buff = __Require(buffInfo.className).new(buffInfo)
				self:addBuff(buff)

				---------- 触发器 ----------
				-- add buff
				self.triggerDriver:OnActionEnter(ConfigObjectTriggerActionType.GOT_BUFF)
				---------- 触发器 ----------
			else
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
判断是否可以释放触发buff
@params skillId int 技能id
@params buffType ConfigBuffType buff类型
@params triggerActionType ConfigObjectTriggerActionType 物体行为触发类型
--]]
function CardObject:CanTriggerBuff(skillId, buffType, triggerActionType)
	return self.buffDriver:CanTriggerBuff(skillId, buffType, triggerActionType)
end
--[[
消耗一些触发的buff的资源
@params skillId int 技能id
@params buffType ConfigBuffType buff类型
@params triggerActionType ConfigObjectTriggerActionType 物体行为触发类型
@params countdown number 触发的cd
--]]
function CardObject:CostTriggerBuffResources(skillId, buffType, triggerActionType, cd)
	self.buffDriver:CostTriggerBuffResources(skillId, buffType, triggerActionType, cd)
end

--[[
@override
加buff
@params buff BaseBuff buff实例
--]]
function CardObject:addBuff(buff)
	local buffIconType = buff:GetBuffIconType()
	-- buff 图标
	if BuffIconType.BASE ~= buffIconType and not self:isBuffExistByIconType(buffIconType, buff:GetBuffOriginValue()) then
		self.view.viewComponent:addBuff(buffIconType, buff:GetBuffOriginValue())
	end

	BaseObject.addBuff(self, buff)
end
--[[
@override
清buff
@params buff BaseBuff buff实例
--]]
function CardObject:removeBuff(buff)
	BaseObject.removeBuff(self, buff)

	local buffIconType = buff:GetBuffIconType()
	-- buff 图标
	if BuffIconType.BASE ~= buffIconType and not self:isBuffExistByIconType(buffIconType, buff:GetBuffOriginValue()) then
		self.view.viewComponent:removeBuff(buffIconType, buff:GetBuffOriginValue())
	end
end
--[[
@override
清除全部buff
--]]
function CardObject:clearBuff()
	for i = #self.buffs.idx, 1, -1 do
		local buff = self.buffs.idx[i]
		self.buffs.id[tostring(buff:GetBuffId())] = nil
		buff:OnRecoverEffectEnter()

		local buffIconType = buff:GetBuffIconType()
		-- buff 图标
		if BuffIconType.BASE ~= buffIconType and not self:isBuffExistByIconType(buffIconType, buff:GetBuffOriginValue()) then
			self.view.viewComponent:removeBuff(buffIconType, buff:GetBuffOriginValue())
		end
	end
end
--[[
@override
添加光环
@params buff BaseBuff buff实例
--]]
function CardObject:addHalo(buff)
	local buffIconType = buff:GetBuffIconType()
	-- buff 图标
	if BuffIconType.BASE ~= buffIconType and not self:isBuffExistByIconType(buffIconType, buff:GetBuffOriginValue()) then
		self.view.viewComponent:addBuff(buffIconType, buff:GetBuffOriginValue())
	end

	BaseObject.addHalo(self, buff)
end
--[[
@override
清光环
@params buff BaseBuff buff实例
--]]
function CardObject:removeHalo(buff)
	BaseObject.removeHalo(self, buff)

	local buffIconType = buff:GetBuffIconType()
	-- buff 图标
	if BuffIconType.BASE ~= buffIconType and not self:isBuffExistByIconType(buffIconType, buff:GetBuffOriginValue()) then
		self.view.viewComponent:removeBuff(buffIconType, buff:GetBuffOriginValue())
	end
end
--[[
@override
添加可点击物体
@params qteBuffsInfo table qte数据信息
--]]
function CardObject:addQTE(qteBuffsInfo)
	local qteObj = self.qteBuffs.id[tostring(qteBuffsInfo.skillId)]
	if not qteObj then
		qteObj = __Require('battle.attachObject.BaseAttachObj').new(qteBuffsInfo)
		self.view.viewComponent:addChild(qteObj:getViewComponent(), 20)
		self.qteBuffs.id[tostring(qteBuffsInfo.skillId)] = qteObj
		table.insert(self.qteBuffs.idx, 1, qteObj)
	else
		qteObj:refreshQTEBuffs(qteBuffsInfo)
	end
end
--[[
@override
移除可点击物体
@params skillId int 技能id
--]]
function CardObject:removeQTE(skillId)
	for i = #self.qteBuffs.idx, 1, -1 do
		if checkint(skillId) == checkint(self.qteBuffs.idx[i].skillId) then
			table.remove(self.qteBuffs.idx, i)
			break
		end
	end
	self.qteBuffs.id[tostring(skillId)] = nil
end
--[[
@override
根据技能id获取qte物体
@params skillId int 技能id
--]]
function CardObject:getQTEBySkillId(skillId)
	return self.qteBuffs.id[tostring(skillId)]
end
--[[
@override
是否存在qte物体
@return _ bool 是否存在qte物体
--]]
function CardObject:hasQTE()
	return 0 < #self.qteBuffs.idx
end
--[[
@override
根据单个buff移除qte buff
@params skillId int 技能id
@params btype ConfigBuffType buff 类型
--]]
function CardObject:removeQTEBuff(skillId, btype)
	if self.qteBuffs.id[tostring(skillId)] then
		self.qteBuffs.id[tostring(skillId)]:removeQTEBuff(btype)
	end
end
--[[
@override
施放所有光环
--]]
function CardObject:castAllHalos()
	self.castDriver:CastAllHalos()
end
--[[
@override
眩晕
@params s bool 是否被眩晕
--]]
function CardObject:stun(s)
	BaseObject.stun(self, s)

	if true == s then
		-- 打断技能
		if OState.CASTING == self:getState() then
			self.castDriver:OnActionBreak()
		elseif OState.ATTACKING == self:getState() then
			self.attackDriver:OnActionBreak()
		end
		
		if OState.DIE ~= self:getState() then
			self:DoSpineAnimation(true, nil, sp.AnimationName.attacked, true)
		end
		self:SetSpineTimeScale(self:getAvatarTimeScale())
	else
		if OState.DIE ~= self:getState() then
			self:DoSpineAnimation(true, nil, sp.AnimationName.idle, true)
		end
		self:SetSpineTimeScale(self:getAvatarTimeScale())
	end
	
	---------- 刷新连携技按钮状态 ----------
	self:refreshConnectButtonsByState()
	---------- 刷新连携技按钮状态 ----------
end
--[[
@override
冻结
@params s bool 是否被冻结
--]]
function CardObject:freeze(f)
	BaseObject.freeze(self, s)

	if true == f then
		-- 打断技能
		if OState.CASTING == self:getState() then
			-- 打断技能
			self.castDriver:OnActionExit()
		elseif OState.ATTACKING == self:getState() then
			self.attackDriver:OnActionExit()
		end
		-- 冻结 动画暂停
		self:SetSpineTimeScale(0)
		self.specialState.freeze = true
	else
		self.specialState.freeze = false
		if OState.DIE ~= self:getState() then
			self:DoSpineAnimation(true, nil, sp.AnimationName.idle, true)
		end
		self:SetSpineTimeScale(self:getAvatarTimeScale())
	end
	---------- 刷新连携技按钮状态 ----------
	self:refreshConnectButtonsByState()
	---------- 刷新连携技按钮状态 ----------
end
--[[
@override
魅惑
@params e bool 是否被魅惑
--]]
function CardObject:enchanting(e)
	BaseObject.enchanting(self, e)

	if true == e then
		-- 打断技能
		if OState.CASTING == self:getState() then
			-- 打断技能
			self.castDriver:OnActionBreak()
		elseif OState.ATTACKING == self:getState() then
			self.attackDriver:OnActionBreak()
		end
	end

	---------- 刷新连携技按钮状态 ----------
	self:refreshConnectButtonsByState()
	---------- 刷新连携技按钮状态 ----------
end
--[[
@override
死亡动作开始
--]]
function CardObject:dieBegin()
	if not CardUtils.IsMonsterCard(self.objInfo.cardId) then
		-- 卡牌死亡 出现语音
		CommonUtils.PlayCardSoundByCardId(self:getOCardId(), SoundType.TYPE_BATTLE_DIE)
	end

	self.view.viewComponent:killSelf()

	self:ClearSpineAnimation()
	self:DoSpineAnimation(true, 1, sp.AnimationName.die, false)

	self:die()
end
--[[
@override
死亡
--]]
function CardObject:die()
	self:killSelf(false)
end
--[[
@override
死亡结束
--]]
function CardObject:dieEnd()
	self.view.avatar:clearTracks()
	self.view.avatar:unregisterSpineEventHandler(sp.EventType.ANIMATION_COMPLETE)
	self.view.avatar:unregisterSpineEventHandler(sp.EventType.ANIMATION_EVENT)
	self.view.viewComponent:dieEnd()

	if nil ~= self:GetViewModel() then
		self:GetViewModel():ClearSpineTracks()
		self:GetViewModel():Kill()
	end

	self:setHighlight(false)
end
--[[
@override
销毁 不可逆！
--]]
function CardObject:destroy()
	if OState.DIE ~= self:getState() then
		self:setState(OState.DIE)
		self.view.avatar:clearTracks()
		self.view.avatar:unregisterSpineEventHandler(sp.EventType.ANIMATION_COMPLETE)
		self.view.avatar:unregisterSpineEventHandler(sp.EventType.ANIMATION_EVENT)
	end

	if nil ~= self:GetViewModel() then
		self:GetViewModel():ClearSpineTracks()
		self:GetViewModel():Kill()
	end

	self.buffs = {idx = {}, id = {}} -- idx 按倒序插入buff id 根据id保存buff
	self.halos = {idx = {}, id = {}} -- idx 按倒序插入buff id 根据id保存buff
	self.shield = {} -- 护盾计数器
	self.ciScene = nil
	self.view.viewComponent:destroy()
end
--[[
@override
杀死该对象 处理数据结构
@params nature bool 是否是自然死亡 自然死亡不计入传给服务器的死亡列表
--]]
function CardObject:killSelf(nature)
	---------- logic ----------
	-- 打断技能
	if OState.CASTING == self:getState() then
		self.castDriver:OnActionExit()
	elseif OState.ATTACKING == self:getState() then
		self.attackDriver:OnActionExit()
	end
	-- 设置状态
	self:setState(OState.DIE)
	-- 停掉除spine以外所有handler
	self:unregisterObjEventHandler()
	-- 对象死亡 广播事件
	BMediator:SendObjEvent(ObjectEvent.OBJECT_DIE, {tag = self:getOTag(), cardId = self:getOCardId(), isEnemy = self:isEnemy(true)})
	-- 清除所有qte
	for i = #self.qteBuffs.idx, 1, -1 do
		self.qteBuffs.idx[i]:die()
	end
	-- 清除所有buff
	self:clearBuff()
	-- 从存活的索敌对象中移除该物体
	BMediator:GetBData():addADeadObj(self, nature)
	BMediator:GetBData():removeABattleObj(self)
	-- 清空能量
	self:addEnergy(-self:getEnergy())

	if nature then
		if nil ~= self:GetViewModel() then
			self:GetViewModel():ClearSpineTracks()
			self:GetViewModel():Kill()
		end
	end
	---------- logic ----------

	---------- view ----------
	-- 变回原色
	self.tintDriver:OnActionBreak()

	-- 移除当前hold的ciscene
	if nil ~= self.ciScene then
		self.ciScene:die()
	end
	---------- view ----------

	---------- 刷新连携技按钮状态 ----------
	self:refreshConnectButtonsByState()
	---------- 刷新连携技按钮状态 ----------
end
--[[
自然死亡
--]]
function CardObject:KillByNature()
	self:killSelf(true)
	self:dieEnd()
end
--[[
@override
胜利
--]]
function CardObject:win()
	self:DoSpineAnimation(true, nil, sp.AnimationName.win, true)
end
--[[
@override
复活
@params reviveHpPercent number 复活时的血量百分比
@params reviveEnergyPercent number 复活时的能量百分比
@params healData ObjectDamageStruct 伤害数据
--]]
function CardObject:revive(reviveHpPercent, reviveEnergyPercent, healData)

	---------- logic ----------
	-- 恢复一些数据结构
	self.view.avatar:unregisterSpineEventHandler(sp.EventType.ANIMATION_COMPLETE)
	self.view.avatar:unregisterSpineEventHandler(sp.EventType.ANIMATION_EVENT)
	self:initSpineCallback()
	if nil == self.objEventHandler_ then
		self.objEventHandler_ = handler(self, self.objEventHandler)
	end
	self:registerObjEventHandler()
	BMediator:GetBData():addABattleObj(self)
	BMediator:GetBData():removeADeadObj(self)

	if nil ~= self:GetViewModel() then
		self:GetViewModel():Awake()
	end
	---------- logic ----------

	---------- view ----------
	self.view.viewComponent:stopAllActions()
	self.view.viewComponent:revive()
	---------- view ----------

	-- 恢复血量 能量
	local recoverHp = self:getMainProperty():getp(ObjP.HP, true) * reviveHpPercent
	self:getMainProperty():setp(ObjP.HP, recoverHp)

	-- 记录一次伤害数据
	if nil ~= healData then
		local healer = BMediator:IsObjAliveByTag(healData.healerTag)
		local attackerEnergy = nil
		if nil ~= healer and healer.getEnergy then
			attackerEnergy = healer:getEnergy():ObtainVal()
		end

		healData.damage = RBQN.New(recoverHp)
		BMediator:GetBData():addADamageStr(healData, healData.damage:ObtainVal(), attackerEnergy)
	end

	local recoverEnergy = MAX_ENERGY * reviveEnergyPercent
	self:addEnergy(recoverEnergy)

	self:getMainProperty():updateCurHpPercent()
	self:updateHpBar()
	self:updateEnergyBar()

	self:awake()

	-- 恢复动作
	self:ClearSpineAnimation()
	self:DoSpineAnimation(true, nil, sp.AnimationName.idle, true)

	-- 发送事件 在此复活
	BMediator:SendObjEvent(ObjectEvent.OBJECT_REVIVE, {tag = self:getOTag(), cardId = self:getOCardId(), isEnemy = self:isEnemy(true)})

	---------- 刷新连携技按钮状态 ----------
	self:refreshAllConnectSkillState()
	self:refreshConnectButtonsByState()
	---------- 刷新连携技按钮状态 ----------
	
end
--[[
@override
强制隐藏
--]]
function CardObject:forceHide()
	self.view.viewComponent:forceHide()
end
--[[
@override
强制显示
--]]
function CardObject:forceShow()
	self.view.viewComponent:forceShow()
end
---------------------------------------------------
-- action logic end --
---------------------------------------------------

---------------------------------------------------
-- controller logic begin --
---------------------------------------------------
--[[
战斗控制器
--]]
function CardObject:autoController(dt)
	-- 不能行动的情况直接返回
	if not self:canAct() then return end

	if OState.NORMAL == self:getState() then

		-- 处于正常状态 索敌一次
		self:seekAttackTarget()

	elseif OState.BATTLE == self:getState() then

		-- 处于战斗状态 走战斗逻辑	
		self:battle(dt)

	elseif OState.MOVING == self:getState() then

		-- 判断是否满足可以攻击的距离
		if self.attackDriver:CanAttackByDistance(self.attackDriver:GetAttackTargetTag()) then
			-- 结束移动动作
			self.moveDriver:OnActionExit()
		else
			-- 移动
			self:move(dt, self.attackDriver:GetAttackTargetTag())
		end
		
	elseif 0 == self.castDriver:IsInChanting() then

		-- 处于读条状态并且读条已经结束
		self.castDriver:OnChantExit(self.castingSkillId)

	elseif OState.MOVE_BACK == self:getState() then

		-- 处于需要移动不可交战的状态 让obj走回战场
		self.moveDriver:OnMoveBackUpdate(dt)

	elseif OState.MOVE_FORCE == self:getState() then

		-- 处于需要移动不可交战的状态 让obj走回战场
		self.moveDriver:OnMoveForceUpdate(dt)

	end

end
--[[
战斗行为 距离够时攻击 距离不够时跑路
@params dt number delta time
--]]
function CardObject:battle(dt)

	-- 首先判断是否可以释放cd技能
	local canCastSkillId = self.castDriver:CanDoAction(ActionTriggerType.CD)
	if nil ~= canCastSkillId then
		
		self:cast(canCastSkillId)

	else

		if nil == BMediator:IsObjAliveByTag(self.attackDriver:GetAttackTargetTag()) then
			-- 判断攻击对象 如果攻击对象为空 重新索敌
			self:setState(OState.NORMAL)
			self:seekAttackTarget()
		else
			-- 首先判断距离 距离满足 走攻击逻辑
			local canAttack = self.attackDriver:CanAttackByDistance(self.attackDriver:GetAttackTargetTag())
			if true == canAttack then
				-- 距离满足 判断攻击
				canAttack = self.attackDriver:CanDoAction()
				if true == canAttack then
					canCastSkillId = self.castDriver:CanDoAction(ActionTriggerType.ATTACK)
					if nil ~= canCastSkillId then
						-- 释放攻击触达的技能
						self:cast(canCastSkillId)
					else
						-- 没有可以触发的小技能 发起普通攻击
						self:attack(self.attackDriver:GetAttackTargetTag())
					end
				end
			else
				-- 距离上不满足条件 需要移动
				self.moveDriver:OnActionEnter(self.attackDriver:GetAttackTargetTag())
			end

			-- -- 判断是否可以攻击
			-- local canAttack = self.attackDriver:CanDoAction(self.attackDriver:GetAttackTargetTag())
			-- if true == canAttack then
			-- 	-- 可以攻击判断是否有可以触发的小技能
			-- 	canCastSkillId = self.castDriver:CanDoAction(ActionTriggerType.ATTACK)
			-- 	if nil ~= canCastSkillId then
			-- 		-- 释放攻击触发的技能
			-- 		self:cast(canCastSkillId)
			-- 	else
			-- 		-- 没有可以触发的小技能 发起普通攻击
			-- 		self:attack(self.attackDriver:GetAttackTargetTag())
			-- 	end

			-- elseif sp.AnimationName.run == canAttack then
			-- 	-- 需要移动
			-- 	self:move(dt, self.attackDriver:GetAttackTargetTag())
			-- end
		end

	end

end
--[[
@override
是否能进入下一波
@return 是否能进入下一波
--]]
function CardObject:canEnterNextWave()
	local result = false
	local current = self:GetCurrentSpineAnimationName()

	if 1 == self.castDriver:IsInChanting() then

		-- 读条中 打断读条
		self.castDriver:OnChantBreak()

	elseif true == self.moveDriver.escaping then

		-- 逃跑中 无法中断
		return false

	elseif nil == current or sp.AnimationName.idle == current or sp.AnimationName.chant == current then

		-- 可以直接无视的当前spine动作
		return true

	elseif self.specialState.stun or self.specialState.freeze then

		-- 恢复卡牌状态
		self:clearBuff()

	elseif sp.AnimationName.run == current then

		-- 技能中 没怪了直接打断动作 不接收事件
		self:DoSpineAnimation(true, nil, sp.AnimationName.idle, true)

	end

	return result
end
--[[
@override
进入下一波
@params nextWave int 下一波
--]]
function CardObject:enterNextWave(nextWave)
	BaseObject.enterNextWave(self, nextWave)

	self:clearBuff()
	self:setState(OState.SLEEP)
	self:setState(OState.SLEEP, -1)
	self:DoSpineAnimation(true, nil, sp.AnimationName.idle, true)
	
	-- 重置站位
	self:resetLocation()

	---------- 触发器 ----------
	-- 受到伤害
	self.triggerDriver:OnActionEnter(ConfigObjectTriggerActionType.WAVE_SHIFT)
	---------- 触发器 ----------

	-- 清空连携卡牌死亡带来的额外一次充能
	-- 复仇逻辑
	-- for k,v in pairs(self.castDriver.connectSkillChargeCounter) do
	-- 	if 0 < v then
	-- 		-- 如果存在这个额外充能 没有使用 置为不可再充能状态
	-- 		self.castDriver.connectSkillChargeCounter[k] = -1
	-- 	end
	-- end

	-- 重置计时器
	self.attackDriver:ResetActionTrigger()
	self.castDriver:ResetActionTrigger()
	self.countdowns.energy = 1
end
--[[
重置站位
--]]
function CardObject:resetLocation()
	self.view.viewComponent:setPosition(self.objInfo.oriLocation.po)
	self:updateLocation()
	if self:isEnemy() then
		self:changeOrientation(false)
	else
		self:changeOrientation(true)
	end
end
--[[
控制物体做一套动作
@params setToSetupPose bool 是否恢复第一帧
@params timeScale int 动画速度缩放参数
@params setAnimationName string set的动画名字
@params setAnimationLoop bool set的动画是否循环
@params addAnimationName string add的动画名字
@params addAnimationLoop bool add的动画是否循环
--]]
function CardObject:DoSpineAnimation(setToSetupPose, timeScale, setAnimationName, setAnimationLoop, addAnimationName, addAnimationLoop)
	local viewModel = self:GetViewModel()
	local avatarSpine = self:getSpineAvatar()

	-- debug new spine logic --
	if nil ~= viewModel then
		if true == setToSetupPose then
			viewModel:SetSpineToSetupPose()
		end

		viewModel:SetSpineAnimation(setAnimationName, setAnimationLoop)

		if nil ~= addAnimationName then
			viewModel:AddSpineAnimation(addAnimationName, addAnimationLoop)
		end
	end
	-- debug new spine logic --

	-- old spine logic --
	if true == setToSetupPose then
		avatarSpine:setToSetupPose()
	end

	avatarSpine:setAnimation(0, setAnimationName, setAnimationLoop)

	if nil ~= addAnimationName then
		avatarSpine:addAnimation(0, addAnimationName, addAnimationLoop)
	end
	-- old spine logic --

	self:SetSpineTimeScale(timeScale)

end
--[[
清空物体正要做的动作
--]]
function CardObject:ClearSpineAnimation()
	local viewModel = self:GetViewModel()
	local avatarSpine = self:getSpineAvatar()

	if nil ~= viewModel then
		viewModel:ClearSpineTracks()
	end

	avatarSpine:clearTracks()
end
--[[
设置spine动画的速度缩放
@params timeScale int 动画速度缩放参数
--]]
function CardObject:SetSpineTimeScale(timeScale)
	if nil == timeScale then return end

	local viewModel = self:GetViewModel()
	local avatarSpine = self:getSpineAvatar()

	if nil ~= viewModel then
		viewModel:SetSpineTimeScale(timeScale)
	end

	avatarSpine:setTimeScale(timeScale)
end
--[[
获取当前正在运行的spine动画动作名
@return _ string 动作名
--]]
function CardObject:GetCurrentSpineAnimationName()
	if nil ~= self:GetViewModel() then
		return self:GetViewModel():GetRunningSpineAniName()
	else
		return self:getSpineAvatar():getCurrent()
	end
end
---------------------------------------------------
-- controller logic end --
---------------------------------------------------

---------------------------------------------------
-- o update logic begin --
---------------------------------------------------
--[[
@override
main update
--]]
function CardObject:update(dt)
	-- dt = math.round(dt * TIME_ACCURACY) / TIME_ACCURACY
	local _dt = dt
	if self:isPause() then return end

	-- 传染驱动器
	for i = #self.timeInfectDrivers.idx, 1, -1 do
		self.timeInfectDrivers.idx[i]:Update(_dt)
	end

	-- 判断是否需要死亡
	if self:canDie() then
		---------- trigger ----------
		if self.phaseDriver then
			if nil == self.phaseDriver.diePhaseChangeCounter then
				-- 第一次死亡 判断触发的阶段转换
				self.phaseDriver:UpdateActionTrigger(ActionTriggerType.DIE, true)
				local canChangePhaseIndexs = self.phaseDriver:CanDoActionWhenDie()
				self.phaseDriver.diePhaseChangeCounter = #canChangePhaseIndexs

				local pcdata = nil
				local phaseChangeInfo = nil
				local needPauselLogic = false

				for i, canChangePhaseIndex in ipairs(canChangePhaseIndexs) do
					pcdata = self.phaseDriver:GetPCDataByIndex(canChangePhaseIndex)
					phaseChangeInfo = ObjectPhaseSturct.New(
						self:getOTag(), pcdata.phaseId, canChangePhaseIndex, true, pcdata.phaseTriggerDelayTime
					)
					needPauselLogic = self.phaseDriver:NeedToPauseMainLogic(pcdata.phaseType)
					BMediator:GetBData():addAPhaseChange(needPauselLogic, phaseChangeInfo)
					-- 插入准备序列中 将宿主转阶段信息移除
					self.phaseDriver:CostActionResources(canChangePhaseIndex)
				end

				return
			elseif 0 < self.phaseDriver.diePhaseChangeCounter then
				-- 存在剩余死亡触发的阶段转换 阻塞死亡
				return
			end
		end

		-- 死亡触发器
		self.triggerDriver:OnActionEnter(ConfigObjectTriggerActionType.DEAD)
		---------- trigger ----------
		print('here check die logic?>>>>>>>>>>', self:getOTag(), self:getOCardName())
		self:dieBegin()
		return
	end

	-- 攻击计时器
	for k,v in pairs(self.countdowns) do
		self.countdowns[k] = math.max(v - _dt, 0)
	end

	-- 普通攻击计时
	self.attackDriver:UpdateActionTrigger(_dt)
	-- 技能计时
	self.castDriver:UpdateActionTrigger(ActionTriggerType.CD, _dt)
	-- buff计时
	self.buffDriver:UpdateActionTrigger(ActionTriggerType.CD, _dt)
	-- 转阶段触发器
	if self.phaseDriver then
		self.phaseDriver:UpdateActionTrigger(ActionTriggerType.CD, _dt)
		local canChangePhaseIndex = self.phaseDriver:CanDoAction()
		if canChangePhaseIndex then
			local pcdata = self.phaseDriver:GetPCDataByIndex(canChangePhaseIndex)
			local phaseChangeInfo = ObjectPhaseSturct.New(
				self:getOTag(), pcdata.phaseId, canChangePhaseIndex, false, pcdata.phaseTriggerDelayTime
			)
			local needPauselLogic = self.phaseDriver:NeedToPauseMainLogic(pcdata.phaseType)
			BMediator:GetBData():addAPhaseChange(needPauselLogic, phaseChangeInfo)
			-- 插入准备序列中 将宿主转阶段信息移除
			self.phaseDriver:CostActionResources(canChangePhaseIndex)
		end
	end

	for i = #self.halos.idx, 1, -1 do
		self.halos.idx[i]:OnBuffUpdateEnter(_dt)
	end

	for i = #self.buffs.idx, 1, -1 do
		self.buffs.idx[i]:OnBuffUpdateEnter(_dt)
	end

	-- 自动回能量
	if 0 >= self.countdowns.energy then
		self.countdowns.energy = 1
		self:addEnergy(self:getEnergyRecoverRatePerS())
	end

	self:autoController(_dt)
end
--[[
@override
update location info
--]]
function CardObject:updateLocation()
	BaseObject.updateLocation(self)
	if self:isHighlight() or -1 ~= self:getODefaultZOrder() then
		self.view.viewComponent:setLocalZOrder(BMediator:GetObjZorder(self:getLocation().po, self:isEnemy(), self:isHighlight()))	
	else
		self.view.viewComponent:setLocalZOrder(self:getODefaultZOrder())
	end
	
end
---------------------------------------------------
-- o update logic end --
---------------------------------------------------

---------------------------------------------------
-- view update begin --
---------------------------------------------------
--[[
@override
刷新血条
@params all bool(nil) true时更新最大血量
--]]
function CardObject:updateHpBar(all)
	-- 更新一次百分比
	self:getMainProperty():updateCurHpPercent()
	local hpPercent = self:getMainProperty():getCurHpPercent()
	self.view.viewComponent:updateHpBar(hpPercent)

	-- if all then
	-- 	self.view.hpBar:setMaxValue(self:getMainProperty():getOriginalHp())
	-- end
	-- self.view.hpBar:setValue(self:getMainProperty():getCurrentHp())
	-- self.view.viewComponent:updateHpBar(self:getMainProperty():getCurHpPercent())
end
--[[
@override
刷新能量条
@params all bool(nil) true时更新最大能量
--]]
function CardObject:updateEnergyBar(all)
	self.view.energyBar:setValue(self:getEnergy():ObtainVal())
end
--[[
@override
显示被击特效
@params params table {
	hurtEffectId int 被击特效id
	hurtEffectPos cc.p 被击特效单位坐标
	hurtEffectZOrder int 被击特效层级
	hurtSEId string 被击爆点特效
}
--]]
function CardObject:showHurtEffect(params)
	------------ 动作作用时音效 ------------
	PlayBattleEffects(params.hurtSEId)
	------------ 动作作用时音效 ------------

	self.view.viewComponent:showHurtEffect(params)
end
--[[
@override
显示或隐藏附加在人物身上的特效
@params v bool 是否可见
@params bid string buff id
@params params table {
	attachEffectId int 特效id
	attachEffectPos cc.p 特效位置坐标
	attachEffectZOrder int 特效层级
}
--]]
function CardObject:showAttachEffect(v, bid, params)
	self.view.viewComponent:showAttachEffect(v, bid, params)
end
--[[
刷新所有连携技按钮全状态
--]]
function CardObject:refreshConnectButtons()
	local connectButton = nil
	for i, sid in ipairs(self.castDriver:GetConnectSkills()) do
		connectButton = BMediator:GetConnectButton(self:getOTag(), sid)
		if nil ~= connectButton then
			connectButton:RefreshButton(self:getEnergy():ObtainVal(), self:canAct(), self:getState(), self:isSilent(), self:isEnchanting())
		end
	end
end
--[[
根据能量刷新所有连携技按钮
--]]
function CardObject:refreshConnectButtonsByEnergy()
	local connectButton = nil
	for i, sid in ipairs(self.castDriver:GetConnectSkills()) do
		connectButton = BMediator:GetConnectButton(self:getOTag(), sid)
		if nil ~= connectButton then
			connectButton:RefreshButtonByEnergy(self:getEnergy():ObtainVal())
		end
	end
end
--[[
根据状态刷新所有连携技按钮
--]]
function CardObject:refreshConnectButtonsByState()
	local connectButton = nil
	for i, sid in ipairs(self.castDriver:GetConnectSkills()) do
		connectButton = BMediator:GetConnectButton(self:getOTag(), sid)
		if nil ~= connectButton then
			connectButton:RefreshButtonByState(self:canAct(), self:getState(), self:isSilent(), self:isEnchanting())
		end
	end
end
--[[
刷新一次所有连携技使用状态
--]]
function CardObject:refreshAllConnectSkillState()
	local connectButton = nil
	for i, sid in ipairs(self.castDriver:GetConnectSkills()) do

		connectButton = BMediator:GetConnectButton(self:getOTag(), sid)
		local result = self.castDriver:CanUseConnectSkillByCardAlive(sid)

		if connectButton then
			connectButton:SetCanUse(result)

			if result then
				-- 刷新一次按钮状态
				connectButton:RefreshButtonByState(self:canAct(), self:getState(), self:isSilent(), self:isEnchanting())

				-- 连携技可用 替换一次ci为连携技
				self.castDriver:InnerChangeConnectSkill(true)
			end
		end

	end
end
--[[
显示目标mark
@params stageCompleteType ConfigStageCompleteType 过关类型
@params show bool 是否显示 
--]]
function CardObject:ShowStageClearTargetMark(stageCompleteType, show)
	self.view.viewComponent:ShowStageClearTargetMark(stageCompleteType, show)
end
--[[
隐藏所有目标mark
--]]
function CardObject:HideAllStageClearTargetMark()
	self.view.viewComponent:HideAllStageClearTargetMark()
end
---------------------------------------------------
-- view update end --
---------------------------------------------------

---------------------------------------------------
-- handler logic begin --
---------------------------------------------------
--[[
spine动画事件回调 动画结束回调
@params event table {
	animation string 动画名
	loopCount int 循环次数
	trackIndex int 时间线序号
	type string 回调类型
}
--]]
function CardObject:spineEventCompleteHandler(event)
	if not event then return end

	local eventName = event.animation

	if sp.AnimationName.attack == eventName or nil ~= string.find(eventName, sp.AnimationName.skill) then
		-- attack 和 skill动作需要做一些额外处理
		if OState.ATTACKING == self:getState() then
			-- 战斗中 攻击动作结束
			self.attackDriver:OnActionExit()
		elseif OState.CASTING == self:getState() then
			-- 施法动作结束 置为正常状态
			self.castDriver:OnActionExit()
		end
	elseif OState.DIE == self:getState() then
		-- 死亡 隔一帧调用结束回调
		self.view.viewComponent:performWithDelay(
			function ()
				self:dieEnd()
			end,
			(1 * cc.Director:getInstance():getAnimationInterval())
		)
	end
end
--[[
spine动画事件回调 动画完整做完的回调
@params eventType 事件类型
@params event 事件数据 {
	animation string 动画名
}
--]]
function CardObject:SpineEventCompleteHandler(eventType, event)
	if not event then return end

	local eventName = event.animation

	if sp.AnimationName.attack == eventName or nil ~= string.find(eventName, sp.AnimationName.skill) then
		-- attack 和 skill动作需要做一些额外处理
		if OState.ATTACKING == self:getState() then
			-- 战斗中 攻击动作结束
			self.attackDriver:OnActionExit()
		elseif OState.CASTING == self:getState() then
			-- 施法动作结束 置为正常状态
			self.castDriver:OnActionExit()
		end
	elseif OState.DIE == self:getState() then
		-- 死亡 隔一帧调用结束回调
		self.view.viewComponent:performWithDelay(
			function ()
				self:dieEnd()
			end,
			(1 * cc.Director:getInstance():getAnimationInterval())
		)
	end
end
--[[
spine动画事件回调 用户自定义事件
@params event table {
	animation string 动画名
	loopCount int 循环次数
	trackIndex int 时间线序号
	type string 回调类型
	eventData {
		name string 事件名称
		intValue int 占比 1-100
	}
}
--]]
function CardObject:spineEventCustomHandler(event)
	if GState.START ~= BMediator:GetGState() or OState.DIE == self:getState() then return end

	if sp.CustomEvent.cause_effect == event.eventData.name then
		---------- 处理接收到的事件 ----------
		if OState.ATTACKING == self:getState() then

			-- 战斗状态 攻击事件
			local percent = event.eventData.intValue * 0.01
			if percent == 0 then percent = 1 end
			self.attackDriver:Attack(self.attackDriver:GetAttackTargetTag(), percent)

		elseif OState.CASTING == self:getState() then

			local percent = event.eventData.intValue * 0.01
			if percent == 0 then percent = 1 end
			self.castDriver:Cast(self.castingSkillId, percent)

		end
		---------- 处理接收到的事件 ----------
	end
end
--[[
spine动画事件回调 自定义事件的回调
@params eventType 事件类型
@params event 事件数据 {
	animation string 动画名
	eventData table {
		
	}
}
--]]
function CardObject:SpineEventCustomHandler(eventType, event)
	-- print('\n\nhere get a spine event -> custom<<<<<<<<<<<<<<<<<<<<<<<<<<<', self:getOCardName(), eventType)
	-- dump(eventType)
	-- dump(event)

	if GState.START ~= BMediator:GetGState() or OState.DIE == self:getState() then return end

	if sp.CustomEvent.cause_effect == event.eventData.name then
		---------- 处理接收到的事件 ----------
		if OState.ATTACKING == self:getState() then

			-- 战斗状态 攻击事件
			local percent = event.eventData.intValue * 0.01
			if percent == 0 then percent = 1 end
			self.attackDriver:Attack(self.attackDriver:GetAttackTargetTag(), percent)

		elseif OState.CASTING == self:getState() then

			local percent = event.eventData.intValue * 0.01
			if percent == 0 then percent = 1 end
			self.castDriver:Cast(self.castingSkillId, percent)

		end
		---------- 处理接收到的事件 ----------
	end
end
--[[
@override
死亡事件回调
@params ... 
	args table passed args
--]]
function CardObject:objDieEventHandler(...)
	local args = unpack({...})
	local tTag = checkint(args.tag)
	-- 检查光环
	local halo = nil
	for i = #self.halos.idx, 1, -1 do
		halo = self.halos.idx[i]
		if halo:HasHaloOuterPileByCasterTag(tTag) then
			halo:OnRecoverEffectEnter(tTag)
		end
	end
	if nil ~= self.attackDriver:GetAttackTargetTag() and (tTag == checkint(self.attackDriver:GetAttackTargetTag())) then
		self:lostAttackTarget()
	end

	-- 如果连携人物死亡 熄灭连携按钮
	if args.cardId and (args.isEnemy == self:isEnemy(true)) then
		self:objDiedConnectSkillHandler(args.cardId)
	end
end
--[[
@override
施法事件回调
@params ... 
	args table passed args
--]]
function CardObject:objCastEventHandler(...)
	local args = unpack({...})
	local tTag = checkint(args.tag)
	local obj = BMediator:IsObjAliveByTag(tTag)
	
	if obj and obj.getOCardId then
		local cardId = obj:getOCardId()
		local skillId = checkint(args.skillId)
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
--[[
@override
隐身事件回调
@params ... 
	args table passed args
--]]
function CardObject:objLuckEventHandler(...)
	local args = unpack({...})
	local tTag = checkint(args.tag)
	local luck = args.luck

	if luck and nil ~= self.attackDriver:GetAttackTargetTag() and (tTag == checkint(self.attackDriver:GetAttackTargetTag())) then
		self:lostAttackTarget()
	end
end
--[[
丢失攻击目标
--]]
function CardObject:lostAttackTarget()
	self.attackDriver:LostAttackTarget()
end
--[[
人物死亡处理连携技逻辑
@params cardId int obj 卡牌id
--]]
function CardObject:objDiedConnectSkillHandler(cardId)

	local connectButton = nil
	---------- 禁用机制 ----------
	for i, sid in ipairs(self.castDriver:GetConnectSkills()) do
		for i, cid in ipairs(self.castDriver:GetSkillBySkillId(sid).connectCardId) do
			if cid == checkint(cardId) then
				connectButton = BMediator:GetConnectButton(self:getOTag(), sid)
				if nil ~= connectButton then
					connectButton:SetCanUse(false)
					connectButton:DisableConnectButton()
				end
				-- 将连携技替换为ci
				self.castDriver:InnerChangeConnectSkill(false)
				break
			end
		end
	end
	---------- 禁用机制 ----------

	---------- 复仇机制 ----------
	-- for i, sid in ipairs(self.castDriver:GetConnectSkills()) do
	-- 	for i, cid in ipairs(self.castDriver:GetSkillBySkillId(sid).connectCardId) do
	-- 		if cid == checkint(cardId) then
	-- 			if -1 ~= self.connectSkillChargeCounter[tostring(sid)] then
	-- 				-- 连携人物首次死亡时添加一层连携技充能
	-- 				self.connectSkillChargeCounter[tostring(sid)] = 1
	-- 				BMediator:EnableConnectButtonByRevenge(self:getOTag(), sid)
	-- 			end
	-- 			break
	-- 		end
	-- 	end
	-- end
	---------- 复仇机制 ----------
end
--[[
@override
复活回调
@params ... 
	args table passed args
--]]
function CardObject:objReviveEventHandler( ... )
	local args = unpack({...})
	if args.tag == self:getOTag() then return end

	-- 如果连携人物复活 恢复连携按钮
	if args.cardId and (args.isEnemy == self:isEnemy(true)) then
		self:objReviveConnectSkillHandler(args.cardId)
	end

end
--[[
人物复活处理连携技逻辑
@params cardId int obj 卡牌id
--]]
function CardObject:objReviveConnectSkillHandler(cardId)

	local connectButton = nil
	---------- 刷新一次所有连携技状态 ----------
	self:refreshAllConnectSkillState()
	---------- 刷新一次所有连携技状态 ----------

	---------- 启用机制 ----------
	-- for i, sid in ipairs(self.castDriver:GetConnectSkills()) do
	-- 	for i, cid in ipairs(self.castDriver:GetSkillBySkillId(sid).connectCardId) do
	-- 		if cid == checkint(cardId) then
	-- 			connectButton = BMediator:GetConnectButton(self:getOTag(), sid)
	-- 			if nil ~= connectButton then
	-- 				connectButton:addConnectDiedCardCounter(-1)
	-- 				connectButton:RefreshButton(self:getEnergy(), self:canAct(), self:getState(), self:isSilent(), self:isEnchanting())
	-- 			end
	-- 		end
	-- 	end
	-- end
	---------- 启用机制 ----------

	---------- 复仇机制 ----------
	-- for i, sid in ipairs(self.castDriver:GetConnectSkills()) do
	-- 	for i, cid in ipairs(self.castDriver:GetSkillBySkillId(sid).connectCardId) do
	-- 		if cid == checkint(cardId) then
	-- 			if -1 ~= self.connectSkillChargeCounter[tostring(sid)] then
	-- 				-- 连携人物首次死亡时添加一层连携技充能
	-- 				self.connectSkillChargeCounter[tostring(sid)] = 1
	-- 				BMediator:EnableConnectButtonByRevenge(self:getOTag(), sid)
	-- 			end
	-- 			break
	-- 		end
	-- 	end
	-- end
	---------- 复仇机制 ----------
end
--[[
击杀事件回调
@params ... table {
	targetTag int 死亡目标的tag
	overflowDamage number 溢出的伤害值
	damageData numebr 致死的伤害数据
}
--]]
function CardObject:slayObjEventHandler( ... )
	local slayData = ...

	local damageBuffType = ConfigBuffType.BASE
	if nil ~= slayData.damageData.skillInfo then
		damageBuffType = slayData.damageData.skillInfo.btype
	end

	---------- 直接不处理的类型 ----------
	local ruleOutBuffType = {
		[ConfigBuffType.SPIRIT_LINK] = true
	}

	-- 由link杀死的单位直接不回调击杀
	if true == ruleOutBuffType[damageBuffType] then return end
	---------- 直接不处理的类型 ----------

	---------- 击杀回复能量 ----------
	self:addEnergy(ENERGY_PER_KILL)
	---------- 击杀回复能量 ----------

	---------- 触发触发器 ----------
	self.triggerDriver:OnActionEnter(
		ConfigObjectTriggerActionType.SLAY_OBJECT,
		slayData
	)
	---------- 触发触发器 ----------
end
---------------------------------------------------
-- handler logic end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
@override
获取是否是敌人
@params o bool 是否是原始敌友性
--]]
function CardObject:isEnemy(o)
	if true == o then
		return self.objInfo.isEnemy
	end
	if self:isEnchanting() then
		return not self.objInfo.isEnemy
	else
		return self.objInfo.isEnemy
	end
end
--[[
获取战斗物体主要6属性
--]]
function CardObject:getMainProperty()
	return self.objInfo.property
end
--[[
@override
获取战斗物体外部配置
@return _ table 卡牌配表信息
--]]
function CardObject:getObjectConfig()
	return CardUtils.GetCardConfig(self:getOCardId())
end
--[[
获取卡牌配表名称
--]]
function CardObject:getOCardName()
	return self:getObjectConfig().name
end
--[[
获取配置的卡牌id
--]]
function CardObject:getOCardId()
	return self.objInfo.cardId
end
--[[
获取spine动画指针
--]]
function CardObject:getSpineAvatar()
	return self.view.avatar
end
--[[
编队所处位置
--]]
function CardObject:getTeamPosition()
	return self.objInfo.teamPosition
end
--[[
@override
能量增加
--]]
function CardObject:addEnergy(delta)
	BaseObject.addEnergy(self, delta)
	self:updateEnergyBar()
	---------- 刷新连携技按钮状态 ----------
	self:refreshConnectButtonsByEnergy()
	---------- 刷新连携技按钮状态 ----------
end
--[[
获取动画变速系数
@params o bool 是否原始速度
@return timeScale number 动画变速
--]]
function CardObject:getAvatarTimeScale(o)
	if self:isPause() or self.specialState.freeze then return 0 end
	local avatarTimeScale = 1
	if o then return avatarTimeScale end

	local attackAnimationData = self:getSpineAnimationData(sp.AnimationName.attack)

	if nil == attackAnimationData then return avatarTimeScale end

	local atkCounter = self:getMainProperty():getATKCounter()

	if sp.AnimationName.attack == self:GetCurrentSpineAnimationName() and 
		attackAnimationData.duration > atkCounter then
		avatarTimeScale = attackAnimationData.duration / atkCounter
	end

	return avatarTimeScale
end
--[[
根据动作名获取动画信息
@params animationName string 动作名
--]]
function CardObject:getSpineAnimationData(animationName)
	if nil ~= self:GetViewModel() then
		return self:GetViewModel():GetSpineAnimationDataByName(animationName)
	else
		return self.view.animationsData[animationName]
	end
end
--[[
获取指定骨骼的信息 这里的worldX和worldY只是相对骨骼动画根节点的坐标
@params bname string 骨骼名字
@return result table 骨骼信息
--]]
function CardObject:findBone(bname)
	bname = bname or ''
	return self.view.avatar:findBone(bname)
end
--[[
获取指定骨骼信息 世界坐标
@params bname string 骨骼名字
@return result table 骨骼信息
--]]
function CardObject:findBoneInWorldSpace(bname)
	local result = self:findBone(bname)
	if nil == result then
		return nil
	end
	local wp = self.view.avatar:convertToWorldSpace(cc.p(result.worldX, result.worldY))
	result.worldPosition = wp
	return result
end
--[[
@override
获取obj碰撞方格 spine父节点坐标
--]]
function CardObject:getStaticCollisionBox()
	local cb = self.view.viewComponent:getAvatarStaticCollisionBox()
	return cb
end
--[[
获取obj碰撞方格 世界坐标
--]]
function CardObject:getCollisionBoxInWorldSpace()
	local cb = self.view.viewComponent:getAvatarBorderBox(sp.CustomName.COLLISION_BOX)
	if nil == cb then return nil end
	local p = self.view.viewComponent:convertToWorldSpace(cc.p(cb.x, cb.y))
	local p_ = self.view.viewComponent:convertToWorldSpace(cc.p(cb.x + cb.width, cb.y + cb.height))
	return cc.rect(p.x, p.y, p_.x - p.x, p_.y - p.y)
end
--[[
根据比例获取碰撞框中对应位置的世界坐标
@params fixedPos cc.p
@return p cc.p 世界坐标
--]]
function CardObject:getPosInCollisionBoxWorldSpace(fixedPos)
	local cb = self.view.viewComponent:getAvatarBorderBox(sp.CustomName.COLLISION_BOX)
	if nil == cb then return nil end

	local x = fixedPos.x or 0
	local y = fixedPos.y or 0

	local p = self.view.viewComponent:convertToWorldSpace(cc.p(
		cb.x + cb.width * x,
		cb.y + cb.height * y
	))

	return p
end
--[[
获取obj碰撞方格 战斗层坐标
--]]
function CardObject:getCollisionBoxInBattleSpace()
	local cb = self.view.viewComponent:getAvatarBorderBox(sp.CustomName.COLLISION_BOX)
	if nil == cb then return nil end
	local p = self.view.viewComponent:getParent():convertToNodeSpace(self.view.viewComponent:convertToWorldSpace(cc.p(cb.x, cb.y)))
	return cc.rect(p.x, p.y, cb.width, cb.height)
end
--[[
@override
设置血量百分比
@params percent number 百分比
--]]
function CardObject:setHpPercentForce(percent)
	BaseObject.setHpPercentForce(self, percent)
	self:getMainProperty():setCurHpPercent(percent)
	self:updateHpBar()
	if nil ~= self.phaseDriver then
		self.phaseDriver:UpdateActionTrigger(ActionTriggerType.HP, percent)
	end
end
--[[
获取obj等级
@return _ int 等级
--]]
function CardObject:getObjectLevel()
	return self:getMainProperty().level
end
--[[
@override
获取是否是木桩
@return _ bool 是否是木桩
--]]
function CardObject:isScarecrow()
	if CardUtils.IsMonsterCard(self:getOCardId()) then
		local monsterType = checkint(self:getObjectConfig().type)

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
设置隐匿
--]]
function CardObject:setLuck(b)
	BaseObject.setLuck(self, b)
	if self:isLuck() then
		BMediator:SendObjEvent(ObjectEvent.OBJECT_LURK, {tag = self:getOTag(), luck = self:isLuck()})
	end
end
--[[
@override
判断物体是否满足死亡条件
@return result bool 死亡
--]]
function CardObject:canDie()
	local result = (not self:isUndead()) and (0 >= self:getMainProperty():getCurrentHp():ObtainVal())
	return result
end
--[[
根据类型获取属性值
@params propertyType ObjP
@params isOriginal bool 是否获取的初始值
@return _ number 加成后的属性
--]]
function CardObject:getPropertyByObjP(propertyType, isOriginal)
	if ObjP.ENERGY == propertyType then
		if isOriginal then
			return MAX_ENERGY
		else
			return self:getEnergy()
		end
	else
		if isOriginal then
			return self:getMainProperty():getCurrentP(propertyType)
		else
			return self:getMainProperty():getOriginalP(propertyType)
		end
	end
end
--[[
@override
获取物体类型(计算不同类型物体增伤用)
@return _ ConfigMonsterType
--]]
function CardObject:getObjectMosnterType()
	if not CardUtils.IsMonsterCard(self:getOCardId()) then
		return ConfigMonsterType.CARD
	else
		local cardConfig = self:getObjectConfig()
		return checkint(cardConfig.type)
	end
end
--[[
@override
是否需要记录变化的血量
--]]
function CardObject:GetRecordDeltaHp()
	return self.objInfo.recordDeltaHp
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

---------------------------------------------------
-- force control begin --
---------------------------------------------------
--[[
@override
强制眩晕
@params s bool 眩晕或解除
--]]
function CardObject:forceStun(s)
	if true == s then
		-- 打断技能
		if OState.CASTING == self:getState() then
			self.castDriver:OnActionBreak()
		elseif OState.ATTACKING == self:getState() then
			self.attackDriver:OnActionBreak()
		end
		self:DoSpineAnimation(true, nil, sp.AnimationName.attacked, true)
	else
		self:DoSpineAnimation(true, nil, sp.AnimationName.idle, true)
	end
end
--[[
@override
吹出场外 自动走回场内
@params distance number 吹飞多少横坐标
--]]
function CardObject:blewOff(distance)
	local d = distance or self.view.viewComponent:getAvatarStaticViewBox().width * 0.5
	local oriPos = nil
	local battleRootSize = BMediator:GetBattleRoot():getContentSize()
	local targetPos = nil
	if true == self:isEnemy(true) then
		-- 敌人时吹飞距离为正
		oriPos = cc.p(
			(display.width + battleRootSize.width) * 0.5 + d,
			self.view.viewComponent:getPositionY()
		)

		targetPos = cc.p(
			(display.width + battleRootSize.width) * 0.5 - d,
			self.view.viewComponent:getPositionY()
		)
	else
		-- 友军时吹飞距离为负
		d = -d
		-- 敌人时吹飞距离为正
		oriPos = cc.p(
			d,
			self.view.viewComponent:getPositionY()
		)

		targetPos = cc.p(
			-d,
			self.view.viewComponent:getPositionY()
		)
	end

	self.view.viewComponent:setPosition(oriPos)
	self:updateLocation()
	-- 重置一次走回战场标识
	self.moveDriver:OnMoveBackEnter(targetPos)
end
--[[
@override
逃跑
--]]
function CardObject:escape()
	local targetPos = nil
	local battleRootSize = BMediator:GetBattleRoot():getContentSize()
	-- 此处查看原始敌友性
	if true == self.objInfo.isEnemy then
		-- 敌人时往右逃跑
		targetPos = cc.p(
			(display.width + battleRootSize.width) * 0.5 + self.view.viewComponent:getAvatarStaticViewBox().width * 1,
			self.view.viewComponent:getPositionY()
		)
	else
		-- 友军时往左逃跑
		targetPos = cc.p(
			-self.view.viewComponent:getAvatarStaticViewBox().width * 1,
			self.view.viewComponent:getPositionY()
		)
	end
	self.moveDriver:OnEscapeEnter(targetPos)
end
--[[
@override
逃跑结束
--]]
function CardObject:appearFromEscape()
	self:setAllImmune(false)
	self.view.viewComponent:escapeAppear()
end
--[[
进场 移动至某个点
@params targetPos cc.p
@params moveActionName string 移动的动作名
@params moveOverCallback function 移动完成后的回调函数
--]]
function CardObject:forceMove(targetPos, moveActionName, moveOverCallback)
	self.moveDriver:OnMoveForceEnter(targetPos, moveActionName, moveOverCallback)
end
--[[
强制消失
@params actionName string 消失时的动作名
@params targetPos string 消失时的目标移动点
@params disappearCallback function 消失后的回调函数
--]]
function CardObject:forceDisappear(actionName, targetPos, disappearCallback)
	if nil ~= targetPos then
		self:forceMove(targetPos, actionName, disappearCallback)
	else
		self:DoSpineAnimation(true, nil, actionName, false)

		local disappearTime = 0
		local animationData = self:getSpineAnimationData(actionName)
		if nil ~= animationData then
			disappearTime = animationData.duration
		end

		local disappearActionSeq = cc.Sequence:create(
			cc.DelayTime:create(disappearTime),
			cc.CallFunc:create(function ()
				if nil ~= disappearCallback then
					disappearCallback()
				end
			end)
		)
		self:runCocos2dxAction(disappearActionSeq)
	end
end
--[[
强制登场
@params actionName string 消失时的动作名
@params targetPos string 消失时的目标移动点
@params appearCallback function 消失后的回调函数
@params delayTime number 登场的延迟时间
--]]
function CardObject:forceAppear(actionName, targetPos, appearCallback, delayTime)
	if nil ~= targetPos then
		self:forceMove(targetPos, actionName, appearCallback)
	else
		local appearTime = 0
		local animationData = self:getSpineAnimationData(actionName)
		if nil ~= animationData then
			appearTime = animationData.duration
		end

		-- 先隐藏自己
		self:forceHide()

		local appearActionSeq = cc.Sequence:create(
			cc.DelayTime:create(delayTime or 0),
			cc.CallFunc:create(function ()
				self:forceShow()
				self:DoSpineAnimation(true, nil, actionName, false)
			end),
			cc.DelayTime:create(appearTime),
			cc.CallFunc:create(function ()
				if appearCallback then
					appearCallback()
				end
			end)
		)
		self:runCocos2dxAction(appearActionSeq)
	end
end
--[[
runaction
--]]
function CardObject:runCocos2dxAction(action)
	self.view.viewComponent:runAction(action)
end
---------------------------------------------------
-- force control end --
---------------------------------------------------

---------------------------------------------------
-- debug begin --
---------------------------------------------------

---------------------------------------------------
-- debug end --
---------------------------------------------------

return CardObject

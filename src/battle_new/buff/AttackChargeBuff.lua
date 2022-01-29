--[[
攻击充能buff
@params args ObjectBuffConstructorStruct
--]]
local BaseBuff = __Require('battle.buff.BaseBuff')
local AttackChargeBuff = class('AttackChargeBuff', BaseBuff)

------------ import ------------
------------ import ------------

------------ define ------------
------------ define ------------

---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
初始化特有属性
--]]
function AttackChargeBuff:InitUnitValue()
	BaseBuff.InitUnitValue(self)

	self.attackModifierTag = nil
end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- logic begin --
---------------------------------------------------
--[[
@override
造成效果
--]]
function AttackChargeBuff:CauseEffect()
	local owner = self:GetBuffOwner()

	if nil ~= owner and nil ~= owner.attackDriver then

		owner.attackDriver:AddAAttackChargeBuff(self)

		local btype = self:GetBuffType()
		local attackModifier = nil

		if ConfigBuffType.ATK_CR_RATE_CHARGE == btype then

			-- 必暴
			attackModifier = owner.attackDriver:GetAttackModifierByType(AttackModifierType.AMT_CERTAIN_CRITICAL)

			if nil == attackModifier then
				local tag = G_BattleLogicMgr:GetBData():GetTagByTagType(BattleTags.BT_ATTACK_MODIFIER)
				-- 创建攻击特效
				attackModifier = __Require('battle.attackModifier.CertainCriticalModifier').new({
					tag = tag,
					owner = owner
				})
				owner.attackDriver:AddAAttackModifier(attackModifier, TimeAxisConstants.TA_ENTER)
			end

		elseif ConfigBuffType.ATK_ATTACK_B_CHARGE == btype then

			-- 攻击力提升x点
			attackModifier = owner.attackDriver:GetAttackModifierByType(AttackModifierType.AMT_ATK_B)

			if nil == attackModifier then
				local tag = G_BattleLogicMgr:GetBData():GetTagByTagType(BattleTags.BT_ATTACK_MODIFIER)
				-- 创建攻击特效
				attackModifier = __Require('battle.attackModifier.ATKBModifier').new({
					tag = tag,
					owner = owner
				})
				owner.attackDriver:AddAAttackModifier(attackModifier, TimeAxisConstants.TA_ENTER)
			end

		elseif ConfigBuffType.ATK_ISD_CHARGE == btype then

			-- 最终伤害
			attackModifier = owner.attackDriver:GetAttackModifierByType(AttackModifierType.AMT_ULTIMATE_DAMAGE)

			if nil == attackModifier then
				local tag = G_BattleLogicMgr:GetBData():GetTagByTagType(BattleTags.BT_ATTACK_MODIFIER)
				-- 创建攻击特效
				attackModifier = __Require('battle.attackModifier.UltimateDamageModifier').new({
					tag = tag,
					owner = owner
				})
				owner.attackDriver:AddAAttackModifier(attackModifier, TimeAxisConstants.TA_ENTER)
			end

		elseif ConfigBuffType.ATK_HEAL_CHARGE == btype then

			-- 击中回复
			attackModifier = owner.attackDriver:GetAttackModifierByType(AttackModifierType.AMT_HIT_AND_HEAL)
			
			if nil == attackModifier then
				local tag = G_BattleLogicMgr:GetBData():GetTagByTagType(BattleTags.BT_ATTACK_MODIFIER)
				-- 创建攻击特效
				attackModifier = __Require('battle.attackModifier.HitAndHealModifier').new({
					tag = tag,
					owner = owner
				})
				owner.attackDriver:AddAAttackModifier(attackModifier, TimeAxisConstants.TA_ACTION)
			end
			
		elseif ConfigBuffType.ATK_ENERGY_CHARGE == btype then

			-- 击中回能
			attackModifier = owner.attackDriver:GetAttackModifierByType(AttackModifierType.AMT_HIT_GAIN_ENERGY)

			if nil == attackModifier then
				local tag = G_BattleLogicMgr:GetBData():GetTagByTagType(BattleTags.BT_ATTACK_MODIFIER)
				-- 创建攻击特效
				attackModifier = __Require('battle.attackModifier.HitAndGainEnergyModifier').new({
					tag = tag,
					owner = owner
				})
				owner.attackDriver:AddAAttackModifier(attackModifier, TimeAxisConstants.TA_ACTION)
			end

		end

		-- 添加充能效果
		attackModifier:AddEffect({
			value = self.p.value,
			times = self.p.countdown,
			bid = self:GetBuffId()
		})

		self.attackModifierTag = attackModifier:GetAttackModifierTag()

		self:AddView()

	end

	return 0
end
--[[
@override
恢复效果
@return result number 恢复效果以后的结果
--]]
function AttackChargeBuff:RecoverEffect()
	local owner = self:GetBuffOwner()

	if nil ~= owner and owner.attackDriver then

		local attackModifier = owner.attackDriver:GetAttackModifierByTag(self:GetChargedAMTag())

		if nil ~= attackModifier then
			-- 移除攻击特效驱动器
			attackModifier:RemoveEffectByBuffId(self:GetBuffId())
		end

		-- 为目标攻击驱动器移除充能buff
		owner.attackDriver:RemoveAAttackChargeBuff(self)

		BaseBuff.RecoverEffect(self)

	end

	return 0
end
--[[
@override
刷新buff
@params value number
@params time number
--]]
function AttackChargeBuff:RefreshBuffEffect(value, time)
	BaseBuff.RefreshBuffEffect(self, value, time)

	-- 刷新攻击特效
	local owner = self:GetBuffOwner()

	if nil ~= owner and nil ~= owner.attackDriver then

		local attackModifier = owner.attackDriver:GetAttackModifierByTag(self:GetChargedAMTag())

		if nil ~= attackModifier then

			attackModifier:RefreshEffect({
				value = self.p.value,
				times = self.p.countdown,
				bid = self:GetBuffId()
			})

		else

			BattleUtils.PrintBattleWaringLog('>>>>> here find logic error cannot find am in attack driver but buff now refresh it')

		end
	end

	print('refresh buff')
	-- print('refresh buff', self.p.value, self.p.countdown, self:GetBuffType(), self:GetSkillId())
end
--[[
@override
update logic
--]]
function AttackChargeBuff:OnBuffUpdateEnter(dt)
	if self:IsHaloBuff() then return end

	-- 攻击充能buff不再在update中移除自己
end
--[[
检查攻击充能buff是否需要移除
--]]
function AttackChargeBuff:AutoRemoveSelf()
	if self:IsHaloBuff() then return end

	if 0 >= self.p.countdown then
		self:OnRecoverEffectEnter()
	end
end
--[[
增加充能
@params times int 充能层数
--]]
function AttackChargeBuff:AddCharge(times)
	if self:IsHaloBuff() then return end

	self.p.countdown = math.max(0, self.p.countdown + times)
	-- print('here check attack charge countdown>>>>>>>.', self.p.countdown)
end
--[[
@override
被驱散时的逻辑
--]]
function AttackChargeBuff:OnBeDispeledEnter()
	self:OnRecoverEffectEnter()
end
---------------------------------------------------
-- logic end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
获取该buff充能的攻击特效tag
@return _ int 攻击特效tag
--]]
function AttackChargeBuff:GetChargedAMTag()
	return self.attackModifierTag
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return AttackChargeBuff

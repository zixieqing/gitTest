--[[
瞬时伤害buff
@params args ObjectBuffConstructorStruct
--]]
local BaseBuff = __Require('battle.buff.BaseBuff')
local InstantBuff = class('InstantBuff', BaseBuff)

------------ import ------------
------------ import ------------

------------ define ------------
------------ define ------------

---------------------------------------------------
-- logic begin --
---------------------------------------------------
--[[
@override
造成效果
@return result number 造成效果以后的结果
--]]
function InstantBuff:CauseEffect()
	local owner = self:GetBuffOwner()

	if nil ~= owner then
		local btype = self:GetBuffType()
		local ownerTag = self:GetBuffOwnerTag()
		local casterTag = self:GetBuffCasterTag()
		
		local damageData = ObjectDamageStruct.New(
			ownerTag,
			nil,
			DamageType.INVALID,
			false,
			nil,
			{skillId = self:GetSkillId(), btype = btype}
		)

		if ConfigBuffType.ISD == btype then

			damageData:SetDamageValue(self.p.value)
			damageData.damageType = DamageType.SKILL_PHYSICAL
			damageData.attackerTag = casterTag

			owner:beAttacked(damageData)

		elseif ConfigBuffType.ISD_LHP == btype then

			damageData:SetDamageValue((owner:getMainProperty():getOriginalHp() - owner:getMainProperty():getCurrentHp()) * self.p.value)
			damageData.damageType = DamageType.SKILL_PHYSICAL
			damageData.attackerTag = casterTag

			owner:beAttacked(damageData)

		elseif ConfigBuffType.ISD_CHP == btype then

			damageData:SetDamageValue(owner:getMainProperty():getCurrentHp() * self.p.value)
			damageData.damageType = DamageType.SKILL_PHYSICAL
			damageData.attackerTag = casterTag

			owner:beAttacked(damageData)

		elseif ConfigBuffType.ISD_OHP == btype then

			damageData:SetDamageValue(owner:getMainProperty():getOriginalHp() * self.p.value)
			damageData.damageType = DamageType.SKILL_PHYSICAL
			damageData.attackerTag = casterTag

			owner:beAttacked(damageData)

		elseif ConfigBuffType.HEAL == btype then

			damageData:SetDamageValue(self.p.value)
			damageData.damageType = DamageType.SKILL_HEAL
			damageData.healerTag = casterTag

			owner:beHealed(damageData)

		elseif ConfigBuffType.HEAL_LHP == btype then

			damageData:SetDamageValue((owner:getMainProperty():getOriginalHp() - owner:getMainProperty():getCurrentHp()) * self.p.value)
			damageData.damageType = DamageType.SKILL_HEAL
			damageData.healerTag = casterTag

			owner:beHealed(damageData)

		elseif ConfigBuffType.HEAL_OHP == btype then

			damageData:SetDamageValue(owner:getMainProperty():getOriginalHp() * self.p.value)
			damageData.damageType = DamageType.SKILL_HEAL
			damageData.healerTag = casterTag

			owner:beHealed(damageData)

		end

		self:OnRecoverEffectEnter()
		return damageData.damage
	end

	return 0
end
--[[
@override
主逻辑更新
--]]
function InstantBuff:OnBuffUpdateEnter(dt)

end
--[[
@override
恢复效果
@params casterTag int 施法者tag
@return result number 恢复效果以后的结果
--]]
function InstantBuff:OnRecoverEffectEnter(casterTag)
	return 0
end
--[[
@override
添加buff对应的展示
--]]
function InstantBuff:AddView()
	
end
--[[
@override
移除buff对应的展示
--]]
function InstantBuff:RemoveView()
	
end
---------------------------------------------------
-- logic end --
---------------------------------------------------

return InstantBuff

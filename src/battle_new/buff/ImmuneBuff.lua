--[[
免疫伤害buff
@params args ObjectBuffConstructorStruct
--]]
local BaseBuff = __Require('battle.buff.BaseBuff')
local ImmuneBuff = class('ImmuneBuff', BaseBuff)

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
--]]
function ImmuneBuff:CauseEffect()
	local owner = self:GetBuffOwner()

	if nil ~= owner then
		local btype = self:GetBuffType()

		------------ data ------------
		if ConfigBuffType.IMMUNE == btype then

			owner:SetDamageImmuneByDamageType(DamageType.PHYSICAL, true)

		elseif ConfigBuffType.IMMUNE_ATTACK_PHYSICAL == btype then

			owner:SetDamageImmuneByDamageType(DamageType.ATTACK_PHYSICAL, true)

		elseif ConfigBuffType.IMMUNE_SKILL_PHYSICAL == btype then

			owner:SetDamageImmuneByDamageType(DamageType.SKILL_PHYSICAL, true)

		elseif ConfigBuffType.IMMUNE_ATTACK_HEAL == btype then

			owner:SetDamageImmuneByDamageType(DamageType.ATTACK_HEAL, true)

		elseif ConfigBuffType.IMMUNE_SKILL_HEAL == btype then

			owner:SetDamageImmuneByDamageType(DamageType.SKILL_HEAL, true)

		elseif ConfigBuffType.IMMUNE_HEAL == btype then

			owner:SetDamageImmuneByDamageType(DamageType.HEAL, true)

		end
		------------ data ------------

		------------ view ------------
		self:AddView()
		------------ view ------------
	end

	return 0
end
--[[
@override
恢复效果
@return result number 恢复效果以后的结果
--]]
function ImmuneBuff:RecoverEffect()
	local owner = self:GetBuffOwner()

	if nil ~= owner then
		local btype = self:GetBuffType()

		------------ data ------------
		if ConfigBuffType.IMMUNE == btype then

			owner:SetDamageImmuneByDamageType(DamageType.PHYSICAL, false)

		elseif ConfigBuffType.IMMUNE_ATTACK_PHYSICAL == btype then

			owner:SetDamageImmuneByDamageType(DamageType.ATTACK_PHYSICAL, false)

		elseif ConfigBuffType.IMMUNE_SKILL_PHYSICAL == btype then

			owner:SetDamageImmuneByDamageType(DamageType.SKILL_PHYSICAL, false)

		elseif ConfigBuffType.IMMUNE_ATTACK_HEAL == btype then

			owner:SetDamageImmuneByDamageType(DamageType.ATTACK_HEAL, false)

		elseif ConfigBuffType.IMMUNE_SKILL_HEAL == btype then

			owner:SetDamageImmuneByDamageType(DamageType.SKILL_HEAL, false)

		elseif ConfigBuffType.IMMUNE_HEAL == btype then

			owner:SetDamageImmuneByDamageType(DamageType.HEAL, false)

		end
		------------ data ------------

		BaseBuff.RecoverEffect(self)
	end

	return 0
end
---------------------------------------------------
-- logic end --
---------------------------------------------------

return ImmuneBuff

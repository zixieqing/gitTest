--[[
全局影响能力的buff
--]]
local BaseGlobalBuff = __Require('battle.globalBuff.BaseGlobalBuff')
local GlobalImmuneBuff = class('GlobalImmuneBuff', BaseGlobalBuff)

---------------------------------------------------
-- control logic begin --
---------------------------------------------------
--[[
@overdide
产生效果
@params ownerTag int 被施法者tag
--]]
function GlobalImmuneBuff:CauseEffect(ownerTag)
	local btype = self:GetBuffInfo().btype
	local owner = BMediator:IsObjAliveByTag(ownerTag)

	if nil ~= owner then
		------------ logic ------------
		if ConfigGlobalBuffType.IMMUNE_ATTACK_PHYSICAL == btype then

			owner:setGlobalDamageImmune(DamageType.ATTACK_PHYSICAL, true)

		elseif ConfigGlobalBuffType.IMMUNE_SKILL_PHYSICAL == btype then

			owner:setGlobalDamageImmune(DamageType.SKILL_PHYSICAL, true)

		-- elseif ConfigBuffType.IMMUNE_SKILL_PHYSICAL == btype then

		-- 	owner:setDamageImmune(DamageType.SKILL_PHYSICAL, true)

		-- elseif ConfigBuffType.IMMUNE_ATTACK_HEAL == btype then

		-- 	owner:setDamageImmune(DamageType.ATTACK_HEAL, true)

		-- elseif ConfigBuffType.IMMUNE_SKILL_HEAL == btype then

		-- 	owner:setDamageImmune(DamageType.SKILL_HEAL, true)

		-- elseif ConfigBuffType.IMMUNE_HEAL == btype then

		-- 	owner:setDamageImmune(DamageType.HEAL, true)

		end
		------------ logic ------------
	end
end
--[[
@override
恢复效果
--]]
function GlobalImmuneBuff:RecoverEffect()

end
---------------------------------------------------
-- control logic end --
---------------------------------------------------

return GlobalImmuneBuff

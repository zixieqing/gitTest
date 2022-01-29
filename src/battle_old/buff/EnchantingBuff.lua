--[[
魅惑buff
@params args ObjectBuffConstructorStruct
--]]
local BaseBuff = __Require('battle.buff.BaseBuff')
local EnchantingBuff = class('EnchantingBuff', BaseBuff)

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
function EnchantingBuff:CauseEffect()
	local owner = self:GetBuffOwner()

	if nil ~= owner then
		------------ data ------------
		owner:enchanting(true)
		-- 为对象重新索敌
		owner:seekAttackTarget()
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
function EnchantingBuff:RecoverEffect()
	local owner = self:GetBuffOwner()

	if nil ~= owner then
		------------ data ------------
		owner:enchanting(false)
		--### 死亡时会清除所有buff 此处不能重新索敌改变状态 ###--
		if OState.DIE ~= owner:getState() then
			-- 为对象重新索敌
			owner:seekAttackTarget()
		end
		------------ data ------------

		BaseBuff.RecoverEffect(self)
	end

	return 0
end
---------------------------------------------------
-- logic end --
---------------------------------------------------

return EnchantingBuff

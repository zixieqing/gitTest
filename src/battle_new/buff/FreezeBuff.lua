--[[
冻结
@params args ObjectBuffConstructorStruct
--]]
local BaseBuff = __Require('battle.buff.BaseBuff')
local FreezeBuff = class('FreezeBuff', BaseBuff)

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
function FreezeBuff:CauseEffect()
	local owner = self:GetBuffOwner()

	if nil ~= owner then
		------------ data ------------
		owner:Freeze(true)
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
function FreezeBuff:RecoverEffect()
	local owner = self:GetBuffOwner()

	if nil ~= owner then
		------------ data ------------
		owner:Freeze(false)
		------------ data ------------

		BaseBuff.RecoverEffect(self)
	end

	return 0
end
---------------------------------------------------
-- logic end --
---------------------------------------------------

return FreezeBuff

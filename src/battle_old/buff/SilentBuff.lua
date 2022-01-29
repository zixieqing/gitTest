--[[
沉默buff
@params args ObjectBuffConstructorStruct
--]]
local BaseBuff = __Require('battle.buff.BaseBuff')
local SilentBuff = class('SilentBuff', BaseBuff)

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
function SilentBuff:CauseEffect()
	local owner = self:GetBuffOwner()

	if nil ~= owner then
		------------ data ------------
		owner:silent(true)
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
function SilentBuff:RecoverEffect()
	local owner = self:GetBuffOwner()

	if nil ~= owner then
		------------ data ------------
		owner:silent(false)
		------------ data ------------

		BaseBuff.RecoverEffect(self)
	end

	return 0
end
---------------------------------------------------
-- logic end --
---------------------------------------------------

return SilentBuff

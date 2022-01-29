--[[
影响能量恢复速度的buff
@params args ObjectBuffConstructorStruct
--]]
local BaseBuff = __Require('battle.buff.BaseBuff')
local EnergyRateBuff = class('EnergyRateBuff', BaseBuff)

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
function EnergyRateBuff:CauseEffect()
	local owner = self:GetBuffOwner()

	if nil ~= owner then
		------------ data ------------
		print('here cause energy rate<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<')
		owner:AddEnergyRecoverRate(self.p.value)
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
function EnergyRateBuff:RecoverEffect()
	local owner = self:GetBuffOwner()

	if nil ~= owner then
		print('here recover energy rate<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<')
		owner:AddEnergyRecoverRate(-self.p.value)

		BaseBuff.RecoverEffect(self)
	end

	return 0
end
--[[
@override
刷新buff效果
@params value number
@params time number
--]]
function EnergyRateBuff:RefreshBuffEffect(value, time)
	-- 移除一次原有的效果
	self:RecoverEffect()

	-- 刷新数据
	BaseBuff.RefreshBuffEffect(self, value, time)

	-- 重新生效一次
	self:CauseEffect()
end
---------------------------------------------------
-- logic end --
---------------------------------------------------

return EnergyRateBuff

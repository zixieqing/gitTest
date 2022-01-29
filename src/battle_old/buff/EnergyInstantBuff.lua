--[[
影响能量的buff
@params args ObjectBuffConstructorStruct
--]]
local BaseBuff = __Require('battle.buff.BaseBuff')
local EnergyInstantBuff = class('EnergyInstantBuff', BaseBuff)

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
function EnergyInstantBuff:CauseEffect()
	local owner = self:GetBuffOwner()
	if nil ~= owner then
		owner:addEnergy(self.p.value)
	end
	return 0
end
--[[
@override
主逻辑更新
--]]
function EnergyInstantBuff:OnBuffUpdateEnter(dt)

end
--[[
@override
恢复效果
@params casterTag int 施法者tag
@return result number 恢复效果以后的结果
--]]
function EnergyInstantBuff:OnRecoverEffectEnter(casterTag)
	return 0
end
--[[
@override
添加buff对应的展示
--]]
function EnergyInstantBuff:AddView()
	
end
--[[
@override
移除buff对应的展示
--]]
function EnergyInstantBuff:RemoveView()
	
end
---------------------------------------------------
-- logic end --
---------------------------------------------------

return EnergyInstantBuff

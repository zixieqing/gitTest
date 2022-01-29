--[[
保底暴击buff
@params args ObjectBuffConstructorStruct
--]]
local BaseBuff = __Require('battle.buff.BaseBuff')
local CriticalCounterBuff = class('CriticalCounterBuff', BaseBuff)

---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
@override
初始化特有属性
--]]
function CriticalCounterBuff:InitUnitValue()
	BaseBuff.InitUnitValue(self)

	self.noCriticalCounter = 0
end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- logic begin --
---------------------------------------------------
--[[
@override
保底暴击生效
@params externalDamageParameter ObjectExternalDamageParameterStruct
--]]
function CriticalCounterBuff:CauseEffect(externalDamageParameter)
	local owner = self:GetBuffOwner()
	if nil ~= owner then
		if externalDamageParameter.isCritical then
			-- 有暴击 重置计数器
			self:SetNoCriticalCounter(0)
		else
			if self:GetNoCriticalCounter() >= self:GetValue() then
				externalDamageParameter.isCritical = true
				-- 触发暴击 重置计数器
				self:SetNoCriticalCounter(0)
			else
				-- 未满足触发条件 计数器+1
				self:SetNoCriticalCounter(self:GetNoCriticalCounter() + 1)
			end
		end
	end

	return 0
end
---------------------------------------------------
-- logic end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
获取未暴击计数
--]]
function CriticalCounterBuff:GetNoCriticalCounter()
	return self.noCriticalCounter
end
function CriticalCounterBuff:SetNoCriticalCounter(counter)
	self.noCriticalCounter = counter
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return CriticalCounterBuff

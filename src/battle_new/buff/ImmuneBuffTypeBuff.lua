--[[
免疫buff的buff
@params args ObjectBuffConstructorStruct
--]]
local BaseBuff = __Require('battle.buff.BaseBuff')
local ImmuneBuffTypeBuff = class('ImmuneBuffTypeBuff', BaseBuff)

------------ import ------------
------------ import ------------

------------ define ------------
------------ define ------------

---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
@override
初始化特有属性
--]]
function ImmuneBuffTypeBuff:InitUnitValue()
	-- 初始化免疫信息
	self.immuneBuffs = {}

	BaseBuff.InitUnitValue(self)
end
--[[
@override
初始化buff特有的数据
--]]
function ImmuneBuffTypeBuff:InitExtraValue()
	-- 初始化免疫的buff类型
	self.immuneBuffs = {}

	local buffType = nil
	for _, buffType_ in ipairs(self:GetValue()) do
		buffType = checkint(buffType_)
		self.immuneBuffs[buffType] = true
	end
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
function ImmuneBuffTypeBuff:CauseEffect()
	local owner = self:GetBuffOwner()

	if nil ~= owner then
		------------ data ------------
		for buffType, immune in pairs(self:GetImmuneBuffType()) do
			owner:SetObjectBuffImmune(buffType, self:GetSkillId(), true)
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
function ImmuneBuffTypeBuff:RecoverEffect()
	local owner = self:GetBuffOwner()

	if nil ~= owner then
		------------ data ------------
		for buffType, immune in pairs(self:GetImmuneBuffType()) do
			owner:SetObjectBuffImmune(buffType, self:GetSkillId(), nil)
		end
		------------ data ------------

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
function ImmuneBuffTypeBuff:RefreshBuffEffect(value, time)
	-- 移除一次原有的效果
	self:RecoverEffect()

	-- 刷新数据
	BaseBuff.RefreshBuffEffect(self, value, time)
	self:InitExtraValue()
	
	-- 重新生效一次
	self:CauseEffect()
end
---------------------------------------------------
-- logic end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
获取免疫的buff类型
--]]
function ImmuneBuffTypeBuff:GetImmuneBuffType()
	return self.immuneBuffs
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return ImmuneBuffTypeBuff

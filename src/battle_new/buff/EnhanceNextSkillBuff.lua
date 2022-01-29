--[[
击杀buff传染buff
@params args ObjectBuffConstructorStruct
--]]
local BaseBuff = __Require('battle.buff.BaseBuff')
local EnhanceNextSkillBuff = class('EnhanceNextSkillBuff', BaseBuff)

------------ import ------------
------------ import ------------

------------ define ------------
------------ define ------------

---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
初始化
--]]
function EnhanceNextSkillBuff:Init()
	BaseBuff.Init(self)

	self:AddView()
end
--[[
@override
初始化固有属性
--]]
function EnhanceNextSkillBuff:InitUnitValue()
	BaseBuff.InitUnitValue(self)
end
--[[
初始化索敌规则信息
--]]
function EnhanceNextSkillBuff:InitExtraValue()
	self.chargeTimes = checkint(self.p.value[1])
	self.enhanceSkillType = {}
	for i = 4, #self.p.value do
		self.enhanceSkillType[checkint(self.p.value[i])] = true
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
@params skillType ConfigSkillType 杀死的目标单位tag
--]]
function EnhanceNextSkillBuff:CauseEffect(skillType)
	local owner = self:GetBuffOwner()
	local value = 0

	if nil ~= owner and 0 < self:GetChargeTimes() then
		
		if self:CanEnhanceBySkillType(skillType) then
			value = value + self:GetEnhanceValue()
			self:SetChargeTimes(self:GetChargeTimes() - 1)
		end

	end

	return value
end
--[[
@override
刷新buff效果
@params value number
@params time number
--]]
function EnhanceNextSkillBuff:RefreshBuffEffect(value, time)
	BaseBuff.RefreshBuffEffect(self, value, time)
	-- 刷新一次索敌数据
	self:InitExtraValue()
end
--[[
主逻辑更新
--]]
function EnhanceNextSkillBuff:OnBuffUpdateEnter(dt)
	if self:IsHaloBuff() then return end

	-- 更新buff计时
	self.p.countdown = math.max(0, self.p.countdown - dt)
	if 0 >= self.p.countdown or 0 >= self:GetChargeTimes() then
		self:OnRecoverEffectEnter()
	end
end
---------------------------------------------------
-- logic end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
获取下一次强化的伤害百分比
--]]
function EnhanceNextSkillBuff:GetEnhanceValue()
	return checknumber(self.p.value[2])
end
--[[
获取强化的伤害百分比
--]]
function EnhanceNextSkillBuff:GetEnhanceSkillType()
	return self.enhanceSkillType
end
--[[
根据技能类型判断是否可以增伤
@params skillType ConfigSkillType 技能类型
--]]
function EnhanceNextSkillBuff:CanEnhanceBySkillType(skillType)
	return true == self:GetEnhanceSkillType()[skillType]
end
--[[
是否已经消耗效果失效
--]]
function EnhanceNextSkillBuff:GetChargeTimes()
	return self.chargeTimes
end
function EnhanceNextSkillBuff:SetChargeTimes(value)
	self.chargeTimes = value
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return EnhanceNextSkillBuff

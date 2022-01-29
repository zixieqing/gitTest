--[[
改变技能触发规则的buff
@params args ObjectBuffConstructorStruct
--]]
local BaseBuff = __Require('battle.buff.BaseBuff')
local ChangeSkillTriggerBuff = class('ChangeSkillTriggerBuff', BaseBuff)

------------ import ------------
------------ import ------------

------------ define ------------
------------ define ------------

---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
@override
初始化索敌规则信息
--]]
function ChangeSkillTriggerBuff:InitExtraValue()
	-- 改变的技能id
	self.changeSkillId = checkint(self.p.value[1])

	-- 改变的触发信息
	self.changeSkillTriggerInfo = {}
	for i = 2, #self.p.value, 2 do
		local triggerType = checkint(self.p.value[i])
		local triggerValue = checknumber(self.p.value[i + 1])
		table.insert(self.changeSkillTriggerInfo, {
			triggerType = triggerType,
			triggerValue = triggerValue	
		})
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
function ChangeSkillTriggerBuff:CauseEffect()
	local owner = self:GetBuffOwner()

	if nil ~= owner then
		------------ data ------------
		if nil ~= owner.castDriver then
			owner.castDriver:AddSkillTriggerInfo(self:GetChangeSkillId(), self:GetChangeSkillTriggerInfo())
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
function ChangeSkillTriggerBuff:RecoverEffect()
	local owner = self:GetBuffOwner()

	if nil ~= owner then
		------------ data ------------
		if nil ~= owner.castDriver then
			owner.castDriver:RemoveSkillTriggerInfo(self:GetChangeSkillId(), self:GetChangeSkillTriggerInfo())
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
function ChangeSkillTriggerBuff:RefreshBuffEffect(value, time)
	-- 移除一次原有的索敌规则
	self:RecoverEffect()

	-- 刷新一次索敌数据
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
获取变更的技能id
@return _ int 技能id
--]]
function ChangeSkillTriggerBuff:GetChangeSkillId()
	return self.changeSkillId
end
--[[
获取变更的触发信息
@return _ table 触发信息
--]]
function ChangeSkillTriggerBuff:GetChangeSkillTriggerInfo()
	return self.changeSkillTriggerInfo
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return ChangeSkillTriggerBuff

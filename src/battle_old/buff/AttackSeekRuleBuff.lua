--[[
改变平a索敌规则的buff
@params args ObjectBuffConstructorStruct
--]]
local BaseBuff = __Require('battle.buff.BaseBuff')
local AttackSeekRuleBuff = class('AttackSeekRuleBuff', BaseBuff)

---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
@override
初始化索敌规则信息
--]]
function AttackSeekRuleBuff:InitExtraValue()
	self.targetSeekRule = SeekRuleStruct.New(
		checkint(self.p.value[1]),
		checkint(self.p.value[3]),
		checkint(self.p.value[2])
	)
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
function AttackSeekRuleBuff:CauseEffect()
	local owner = self:GetBuffOwner()

	if nil ~= owner then
		------------ data ------------
		owner.attackDriver:GainAttackSeekRule(self:GetTargetSeekRule())
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
function AttackSeekRuleBuff:RecoverEffect()
	local owner = self:GetBuffOwner()

	if nil ~= owner then
		------------ data ------------
		owner.attackDriver:LostAttackSeekRule(self:GetTargetSeekRule())
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
function AttackSeekRuleBuff:RefreshBuffEffect(value, time)
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
获取本buff的索敌规则
@return _ SeekRuleStruct 索敌规则
--]]
function AttackSeekRuleBuff:GetTargetSeekRule()
	return self.targetSeekRule
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return AttackSeekRuleBuff

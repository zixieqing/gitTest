--[[
不会触发触发器的治疗
@params args ObjectBuffConstructorStruct
--]]
local BaseBuff = __Require('battle.buff.BaseBuff')
local HealNoTriggerBuff = class('HealNoTriggerBuff', BaseBuff)

------------ import ------------
------------ import ------------

------------ define ------------
------------ define ------------

---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
@override
造成效果
@return result number 造成效果以后的结果
--]]
function HealNoTriggerBuff:CauseEffect()
	local owner = self:GetBuffOwner()

	if nil ~= owner then
		local btype = self:GetBuffType()
		local ownerTag = self:GetBuffOwnerTag()
		local casterTag = self:GetBuffCasterTag()

		local damageData = ObjectDamageStruct.New(
			ownerTag,
			0 * checknumber(self.p.value[1]) + checknumber(self.p.value[2]),
			DamageType.SKILL_HEAL,
			false,
			{healerTag = casterTag},
			{skillId = self:GetSkillId(), btype = btype}
		)

		owner:beHealed(damageData, true)
	end
end
--[[
@override
主逻辑更新
--]]
function HealNoTriggerBuff:OnBuffUpdateEnter(dt)

end
--[[
@override
恢复效果
@params casterTag int 施法者tag
@return result number 恢复效果以后的结果
--]]
function HealNoTriggerBuff:OnRecoverEffectEnter(casterTag)
	return 0
end
--[[
@override
添加buff对应的展示
--]]
function HealNoTriggerBuff:AddView()
	
end
--[[
@override
移除buff对应的展示
--]]
function HealNoTriggerBuff:RemoveView()
	
end
---------------------------------------------------
-- init end --
---------------------------------------------------

return HealNoTriggerBuff

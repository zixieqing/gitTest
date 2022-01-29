--[[
不会触发触发器的伤害
@params args ObjectBuffConstructorStruct
--]]
local BaseBuff = __Require('battle.buff.BaseBuff')
local DamageNoTriggerBuff = class('DamageNoTriggerBuff', BaseBuff)

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
function DamageNoTriggerBuff:CauseEffect()
	local owner = self:GetBuffOwner()

	if nil ~= owner then
		local btype = self:GetBuffType()
		local ownerTag = self:GetBuffOwnerTag()
		local casterTag = self:GetBuffCasterTag()

		local damageData = ObjectDamageStruct.New(
			ownerTag,
			0 * checknumber(self.p.value[1]) + checknumber(self.p.value[2]),
			DamageType.SKILL_PHYSICAL,
			false,
			{attackerTag = casterTag},
			{skillId = self:GetSkillId(), btype = btype}
		)

		owner:BeAttacked(damageData, true)
	end
end
--[[
@override
主逻辑更新
--]]
function DamageNoTriggerBuff:OnBuffUpdateEnter(dt)

end
--[[
@override
恢复效果
@params casterTag int 施法者tag
@return result number 恢复效果以后的结果
--]]
function DamageNoTriggerBuff:OnRecoverEffectEnter(casterTag)
	return 0
end
--[[
@override
添加buff对应的展示
--]]
function DamageNoTriggerBuff:AddView()
	
end
--[[
@override
移除buff对应的展示
--]]
function DamageNoTriggerBuff:RemoveView()
	
end
---------------------------------------------------
-- init end --
---------------------------------------------------

return DamageNoTriggerBuff

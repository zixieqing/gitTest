--[[
斩杀buff
@params args ObjectBuffConstructorStruct
--]]
local BaseBuff = __Require('battle.buff.BaseBuff')
local ExecuteBuff = class('ExecuteBuff', BaseBuff)

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
function ExecuteBuff:InitUnitValue()
	self.p = {
		value = self.buffInfo.value,
		countdown = self.buffInfo.time,
		percent = self.buffInfo.percent
	}
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
@return result number 造成效果以后的结果
--]]
function ExecuteBuff:CauseEffect()
	local owner = self:GetBuffOwner()

	if nil ~= owner then
		-- 伤害免疫时免疫斩杀
		if owner:isDamageImmune(DamageType.PHYSICAL) or
			owner:isDamageImmune(DamageType.SKILL_PHYSICAL) or
			owner:isGlobalDamageImmune(DamageType.PHYSICAL) or
			owner:isGlobalDamageImmune(DamageType.PHYSICAL) or
			owner:isImmune(BKIND.INSTANT) then
			return 0
		end

		local btype = self:GetBuffType()
		local ownerTag = self:GetBuffOwnerTag()
		local casterTag = self:GetBuffCasterTag()

		local damageData = ObjectDamageStruct.New(
			ownerTag,
			self.p.value,
			DamageType.SKILL_PHYSICAL,
			false,
			{attackerTag = casterTag},
			{skillId = self:GetSkillId(), btype = btype}
		)

		-- 判断受法者当前生命百分比是否低于斩杀线
		local targetHpPercent = owner:getMainProperty():getCurHpPercent()
		-- 如果免疫斩杀 则只产生基础的伤害
		if self.p.percent * 10000 >= math.ceil(targetHpPercent * 10000) and not owner:isBuffImmune(btype) then

			-- 满足斩杀条件
			damageData:SetDamageValue(math.max(owner:getMainProperty():getCurrentHp():ObtainVal(), owner:getMainProperty():getOriginalHp():ObtainVal()))
			owner:beAttacked(damageData)
			print('\n*****\n***    execute !!! ', casterTag, '------->', ownerTag, '\n*****\n')

		else

			-- 不满足斩杀条件
			owner:beAttacked(damageData)

		end

		self:OnRecoverEffectEnter()
		return damageData.damage

	end

	return 0
end
--[[
@override
主逻辑更新
--]]
function ExecuteBuff:OnBuffUpdateEnter(dt)

end
--[[
@override
恢复效果
@params casterTag int 施法者tag
@return result number 恢复效果以后的结果
--]]
function ExecuteBuff:OnRecoverEffectEnter(casterTag)
	return 0
end
--[[
@override
添加buff对应的展示
--]]
function ExecuteBuff:AddView()
	
end
--[[
@override
移除buff对应的展示
--]]
function ExecuteBuff:RemoveView()
	
end
---------------------------------------------------
-- logic end --
---------------------------------------------------

return ExecuteBuff

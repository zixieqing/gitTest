--[[
击杀伤害溢出buff
@params args ObjectBuffConstructorStruct
--]]
local BaseBuff = __Require('battle.buff.BaseBuff')
local SlayDamageSplashBuff = class('SlayDamageSplashBuff', BaseBuff)

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
function SlayDamageSplashBuff:Init()
	BaseBuff.Init(self)
	self:AddView()
end
--[[
@override
初始化索敌规则信息
--]]
function SlayDamageSplashBuff:InitExtraValue()
	self.damageValue = {
		checknumber(self.p.value[4]),
		checknumber(self.p.value[5])
	}
	self.splashSeekRule = SeekRuleStruct.New(
		checkint(self.p.value[1]),
		checkint(self.p.value[3]),
		checkint(self.p.value[2])
	)
end
--[[
@override
获取buff内部trigger信息
--]]
function SlayDamageSplashBuff:GetTriggerTypeConfig()
	return {
		ConfigObjectTriggerActionType.SLAY_OBJECT
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
@params slayTargetTag int 杀死的目标单位tag
@params damage numeber 伤害
--]]
function SlayDamageSplashBuff:CauseEffect(slayTargetTag, damage)
	local owner = self:GetBuffOwner()

	if nil ~= owner then
		local btype = self:GetBuffType()
		local ownerTag = self:GetBuffOwnerTag()

		local fixedDamage = self:GetFixedDamage(damage)

		local damageData = ObjectDamageStruct.New(
			nil,
			fixedDamage,
			DamageType.SKILL_PHYSICAL,
			false,
			{attackerTag = ownerTag},
			{skillId = self:GetSkillId(), btype = btype}
		)

		local slayTarget = G_BattleLogicMgr:GetObjByTagForce(slayTargetTag)

		---------- 为爆炸伤害索敌 ----------
		local targets = BattleExpression.GetTargets(slayTarget:IsEnemy(true), self:GetSplashSeekRule(), slayTarget, nil, {[tostring(slayTargetTag)] = true})
		---------- 为爆炸伤害索敌 ----------

		for _, target in ipairs(targets) do
			-- 触发溢出伤害的物体不再受到伤害
			if slayTargetTag ~= target:GetOTag() then
				local damageData_ = damageData:CloneStruct()
				-- 修改damage信息
				damageData_.targetTag = target:GetOTag()
				target:BeAttacked(damageData_)
			end
		end
	end

	return 0
end
--[[
@override
刷新buff效果
@params value number
@params time number
--]]
function SlayDamageSplashBuff:RefreshBuffEffect(value, time)
	BaseBuff.RefreshBuffEffect(self, value, time)
	-- 刷新一次索敌数据
	self:InitExtraValue()
end
--[[
@override
触发后的处理
@params triggerType ConfigObjectTriggerActionType 触发类型
@params slayData 击杀信息
--]]
function SlayDamageSplashBuff:TriggerHandler(triggerType, slayData)
	local slayBuffType = ConfigBuffType.BASE
	
	if nil ~= slayData.damageData.skillInfo then

		slayBuffType = slayData.damageData.skillInfo.btype
		local overflowDamage = slayData.overflowDamage

		if slayBuffType ~= self:GetBuffType() and 0 > overflowDamage then
			-- 触发效果
			self:OnCauseEffectEnter(slayData.targetTag, math.abs(overflowDamage))
		end

	end
end
---------------------------------------------------
-- logic end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
根据基础伤害值获取伤害配置信息
@params damage number 基础伤害值
@return _ number 修正的伤害值
--]]
function SlayDamageSplashBuff:GetFixedDamage(damage)
	return self.damageValue[1] * (damage or 0) + self.damageValue[2]
end
--[[
获取爆出伤害的索敌
@return _ SeekRuleStruct 索敌规则
--]]
function SlayDamageSplashBuff:GetSplashSeekRule()
	return self.splashSeekRule
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return SlayDamageSplashBuff

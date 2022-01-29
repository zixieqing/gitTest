--[[
dot hot
@params args ObjectBuffConstructorStruct
--]]
local BaseBuff = __Require('battle.buff.BaseBuff')
local OverTimeBuff = class('OverTimeBuff', BaseBuff)

------------ import ------------
------------ import ------------

------------ define ------------
------------ define ------------

---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
@override
初始化
--]]
function OverTimeBuff:Init()
	BaseBuff.Init(self)
	self:AddView()
end
--[[
@override
初始化特有属性
--]]
function OverTimeBuff:InitUnitValue()
	self.interval = 1

	self.p = {
		value = self.buffInfo.value,
		countdown = self.buffInfo.time,
		interval = self:GetCauseEffectInterval()
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
function OverTimeBuff:CauseEffect()
	local owner = self:GetBuffOwner()

	if nil ~= owner then
		local btype = self:GetBuffType()
		local ownerTag = self:GetBuffOwnerTag()
		local casterTag = self:GetBuffCasterTag()

		local damageData = ObjectDamageStruct.New(
			ownerTag,
			nil,
			DamageType.INVALID,
			false,
			nil,
			{skillId = self:GetSkillId(), btype = btype}
		)
		local damage = nil

		if ConfigBuffType.DOT == btype then

			damageData:SetDamageValue(self.p.value)
			damageData.damageType = DamageType.SKILL_PHYSICAL
			damageData.attackerTag = casterTag

			owner:BeAttacked(damageData)

		elseif ConfigBuffType.DOT_CHP == btype then

			damageData:SetDamageValue(owner:GetMainProperty():GetCurrentHp() * self.p.value)
			damageData.damageType = DamageType.SKILL_PHYSICAL
			damageData.attackerTag = casterTag

			owner:BeAttacked(damageData)

		elseif ConfigBuffType.DOT_OHP == btype then

			damageData:SetDamageValue(owner:GetMainProperty():GetOriginalHp() * self.p.value)
			damageData.damageType = DamageType.SKILL_PHYSICAL
			damageData.attackerTag = casterTag

			owner:BeAttacked(damageData)

		elseif ConfigBuffType.HOT == btype then

			damageData:SetDamageValue(self.p.value)
			damageData.damageType = DamageType.SKILL_HEAL
			damageData.healerTag = casterTag

			owner:BeHealed(damageData)

		elseif ConfigBuffType.HOT_LHP == btype then

			damageData:SetDamageValue((owner:GetMainProperty():GetOriginalHp() - owner:GetMainProperty():GetCurrentHp()) * self.p.value)
			damageData.damageType = DamageType.SKILL_HEAL
			damageData.healerTag = casterTag

			owner:BeHealed(damageData)

		elseif ConfigBuffType.HOT_OHP == btype then

			damageData:SetDamageValue(owner:GetMainProperty():GetOriginalHp() * self.p.value)
			damageData.damageType = DamageType.SKILL_HEAL
			damageData.healerTag = casterTag

			owner:BeHealed(damageData)

		end

		return damageData.damage
	end

	return 0
end
--[[
@override
update logic
--]]
function OverTimeBuff:OnBuffUpdateEnter(dt)
	self.p.interval = self.p.interval - dt
	if 0 >= self.p.interval and self.p.countdown >= 0 then
		self:OnCauseEffectEnter()
		self.p.interval = self.p.interval + self:GetCauseEffectInterval()
	end

	if self:IsHaloBuff() then return end

	-- 更新buff计时
	self.p.countdown = math.max(0, self.p.countdown - dt)
	if 0 >= self.p.countdown then
		self:OnRecoverEffectEnter()
	end
end
--[[
终结buff
@params enhanceRatio number 倍率
--]]
function OverTimeBuff:Finish(enhanceRatio)
	if self:IsHaloBuff() then return end

	local owner = self:GetBuffOwner()
	if nil == owner then return end

	local btype = self:GetBuffType()

	------------ 计算剩余的伤害 ------------
	local leftDamage = self:GetLeftValue() * enhanceRatio
	------------ 计算剩余的伤害 ------------

	local fromTag = nil
	local damageType = nil

	if ConfigBuffType.DOT == btype or 
		ConfigBuffType.DOT_CHP == btype or 
		ConfigBuffType.DOT_OHP == btype then

		fromTag = {
			attackerTag = self:GetBuffCasterTag()
		}
		damageType = DamageType.SKILL_PHYSICAL

	elseif ConfigBuffType.HOT == btype or 
		ConfigBuffType.HOT_LHP == btype or 
		ConfigBuffType.HOT_OHP == btype then

		fromTag = {
			healerTag = self:GetBuffCasterTag()	
		}
		damageType = DamageType.SKILL_HEAL

	end

	local damageData = ObjectDamageStruct.New(
		self:GetBuffOwnerTag(),
		leftDamage,
		damageType,
		false,
		fromTag,
		{skillId = self:GetSkillId(), btype}
	)

	if damageData and damageData.attackerTag then
		owner:BeAttacked(damageData)
	elseif damageData and damageData.healerTag then
		owner:BeHealed(damageData)
	end

	self:SetLeftCountdown(0)
	self:OnRecoverEffectEnter()

end
---------------------------------------------------
-- logic end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
获取dot作用间隔
--]]
function OverTimeBuff:GetCauseEffectInterval()
	return self.interval
end
function OverTimeBuff:SetCauseEffectInterval(interval)
	self.interval = interval
end
--[[
获取单跳伤害
--]]
function OverTimeBuff:GetValuePerS()
	return self.p.value
end
--[[
获取剩余的伤害
@return leftValue number 剩余的值
--]]
function OverTimeBuff:GetLeftValue()
	local owner = self:GetBuffOwner()

	if nil == owner then return 0 end

	local leftTime = self:GetLeftCountdown()
	local leftCauseTime = math.ceil(leftTime)
	local valuePerS = self:GetValuePerS()

	local leftValue = 0
	local btype = self:GetBuffType()

	if ConfigBuffType.DOT == btype or 
		ConfigBuffType.HOT == btype then

		-- 普通dot hot
		leftValue = valuePerS * leftCauseTime

	elseif ConfigBuffType.DOT_CHP == btype then

		-- 当前血量
		local targetHp = owner:GetMainProperty():GetCurrentHp()
		for i = 1, leftCauseTime do
			local deltaHp = targetHp * valuePerS
			leftValue = leftValue + deltaHp
			targetHp = targetHp - deltaHp
		end

	elseif ConfigBuffType.HOT_LHP == btype then

		-- 当前剩余血量
		local targetHp = owner:GetMainProperty():GetOriginalHp() - owner:GetMainProperty():GetCurrentHp()
		for i = 1, leftCauseTime do
			local deltaHp = targetHp * valuePerS
			leftValue = leftValue + deltaHp
			targetHp = targetHp - deltaHp
		end

	elseif ConfigBuffType.DOT_OHP == btype or 
		ConfigBuffType.HOT_OHP == btype then

		-- 最大血量
		leftValue = owner:GetMainProperty():GetOriginalHp() * valuePerS * leftCauseTime

	end

	return leftValue
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return OverTimeBuff

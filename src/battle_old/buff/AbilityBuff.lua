--[[
影响属性的buff
@params args ObjectBuffConstructorStruct
--]]
local BaseBuff = __Require('battle.buff.BaseBuff')
local AbilityBuff = class('AbilityBuff', BaseBuff)

------------ import ------------
------------ import ------------

------------ define ------------
------------ define ------------

---------------------------------------------------
-- logic begin --
---------------------------------------------------
--[[
@override
初始化特有属性
--]]
function AbilityBuff:InitUnitValue()
	BaseBuff.InitUnitValue(self)

	self.ptype = 0

	-- 初始化影响属性的参数
	local btype = self:GetBuffType()

	if ConfigBuffType.ATTACK_B == btype then

		self:SetPType(ObjPP.ATTACK_B)

	elseif ConfigBuffType.ATTACK_A == btype then

		self:SetPType(ObjPP.ATTACK_A)

	elseif ConfigBuffType.DEFENCE_B == btype then

		self:SetPType(ObjPP.DEFENCE_B)

	elseif ConfigBuffType.DEFENCE_A == btype then

		self:SetPType(ObjPP.DEFENCE_A)

	elseif ConfigBuffType.OHP_B == btype then

		self:SetPType(ObjPP.OHP_B)

	elseif ConfigBuffType.OHP_A == btype then

		self:SetPType(ObjPP.OHP_A)

	elseif ConfigBuffType.CR_RATE_B == btype then

		self:SetPType(ObjPP.CR_RATE_B)

	elseif ConfigBuffType.CR_RATE_A == btype then

		self:SetPType(ObjPP.CR_RATE_A)

	elseif ConfigBuffType.ATK_RATE_B == btype then

		self:SetPType(ObjPP.ATK_RATE_B)

	elseif ConfigBuffType.ATK_RATE_A == btype then

		self:SetPType(ObjPP.ATK_RATE_A)

	elseif ConfigBuffType.CR_DAMAGE_B == btype then

		self:SetPType(ObjPP.CR_DAMAGE_B)

	elseif ConfigBuffType.CR_DAMAGE_A == btype then

		self:SetPType(ObjPP.CR_DAMAGE_A)

	elseif ConfigBuffType.GET_DAMAGE_ATTACK == btype then

		self:SetPType(ObjPP.GET_DAMAGE_ATTACK)

	elseif ConfigBuffType.GET_DAMAGE_SKILL == btype then

		self:SetPType(ObjPP.GET_DAMAGE_SKILL)

	elseif ConfigBuffType.GET_DAMAGE_PHYSICAL == btype then

		self:SetPType(ObjPP.GET_DAMAGE_PHYSICAL)

	elseif ConfigBuffType.CAUSE_DAMAGE_ATTACK == btype then

		self:SetPType(ObjPP.CAUSE_DAMAGE_ATTACK)

	elseif ConfigBuffType.CAUSE_DAMAGE_SKILL == btype then

		self:SetPType(ObjPP.CAUSE_DAMAGE_SKILL)

	elseif ConfigBuffType.CAUSE_DAMAGE_PHYSICAL == btype then

		self:SetPType(ObjPP.CAUSE_DAMAGE_PHYSICAL)

	elseif ConfigBuffType.CDAMAGE_A == btype then

		if self.p.value >= 0 then
			self:SetPType(ObjPP.CDAMAGE_UP)
		else
			self:SetPType(ObjPP.CDAMAGE_DOWN)
		end

	elseif ConfigBuffType.GDAMAGE_A == btype then

		if self.p.value >= 0 then
			self:SetPType(ObjPP.GDAMAGE_UP)
		else
			self:SetPType(ObjPP.GDAMAGE_DOWN)
		end
		
	end
end
--[[
@override
造成效果
@return result number 造成效果以后的结果
--]]
function AbilityBuff:CauseEffect()
	local owner = self:GetBuffOwner()

	if nil ~= owner then
		local btype = self:GetBuffType()
		local ptype = self:GetPType()

		if ConfigBuffType.ATK_RATE_A == btype or
			ConfigBuffType.ATK_RATE_B == btype then

			-- 影响攻速时的buff需要改变一次攻击的cd和动画的变速
			------------ data ------------
			local percent = owner.attackDriver:GetActionTrigger() / owner:getMainProperty():getATKCounter()
			owner:getMainProperty():changepp(ptype, self.p.value)
			owner.attackDriver:SetActionTrigger(percent * owner:getMainProperty():getATKCounter())
			------------ data ------------

			------------ view ------------
			owner:SetSpineTimeScale(owner:getAvatarTimeScale())
			------------ view ------------

		elseif ConfigBuffType.OHP_A == btype or
			ConfigBuffType.OHP_B == btype then

			-- 影响最大血量时的buff需要根据血量百分比改变当前血量
			------------ data ------------
			-- 计算当前生命百分比
			owner:getMainProperty():updateCurHpPercent()
			local hpPercent = owner:getMainProperty():getCurHpPercent()
			-- 刷新系数
			owner:getMainProperty():changepp(ptype, self.p.value)
			-- 重置当前血量至之前的生命百分比
			local curHp = owner:getMainProperty():getOriginalHp() * hpPercent
			owner:getMainProperty():setp(ObjP.HP, curHp)
			owner:getMainProperty():updateCurHpPercent()
			------------ data ------------

			------------ view ------------
			owner:updateHpBar(true)
			------------ view ------------

		else

			-- 通用逻辑
			owner:getMainProperty():changepp(ptype, self.p.value)

		end

		self:AddView()

	end

	return 0
end
--[[
@override
恢复效果
@return result number 恢复效果以后的结果
--]]
function AbilityBuff:RecoverEffect()
	local owner = self:GetBuffOwner()

	if nil ~= owner then
		local btype = self:GetBuffType()
		local ptype = self:GetPType()

		-- 恢复物体的属性系数
		if ConfigBuffType.ATK_RATE_A == btype or
			ConfigBuffType.ATK_RATE_B == btype then

			-- 影响攻速时的buff需要恢复一次攻击的cd和动画的变速
			------------ data ------------
			local percent = owner.attackDriver:GetActionTrigger() / owner:getMainProperty():getATKCounter()
			owner:getMainProperty():changepp(ptype, -self.p.value)
			owner.attackDriver:SetActionTrigger(percent * owner:getMainProperty():getATKCounter())
			------------ data ------------

			------------ view ------------
			owner:SetSpineTimeScale(owner:getAvatarTimeScale())
			------------ view ------------

		elseif ConfigBuffType.OHP_A == btype or
			ConfigBuffType.OHP_B == btype then

			------------ data ------------
			owner:getMainProperty():changepp(ptype, -self.p.value)
			if owner:getMainProperty():getCurrentHp() > owner:getMainProperty():getOriginalHp() then
				owner:getMainProperty():setp(ObjP.HP, self:getMainProperty():getOriginalHp())
				owner:getMainProperty():updateCurHpPercent()
			end
			------------ data ------------

			------------ view ------------
			owner:updateHpBar(true)
			------------ view ------------

		else

			owner:getMainProperty():changepp(ptype, -self.p.value)

		end

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
function AbilityBuff:RefreshBuffEffect(value, time)
	-- 移除一次原有的效果
	self:RecoverEffect()

	-- 刷新数据
	BaseBuff.RefreshBuffEffect(self, value, time)

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
获取影响的属性参数值
--]]
function AbilityBuff:GetPType()
	return self.ptype
end
function AbilityBuff:SetPType(ptype)
	self.ptype = ptype
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return AbilityBuff

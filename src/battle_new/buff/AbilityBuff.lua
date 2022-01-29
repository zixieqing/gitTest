--[[
影响属性的buff
@params args ObjectBuffConstructorStruct
--]]
local BaseBuff = __Require('battle.buff.BaseBuff')
local AbilityBuff = class('AbilityBuff', BaseBuff)

------------ import ------------
------------ import ------------

------------ define ------------
-- buff类型->属性系数类型对照表
local BuffType2ObjPP = {
	[ConfigBuffType.ATTACK_B] 				= ObjPP.ATTACK_B,
	[ConfigBuffType.ATTACK_A] 				= ObjPP.ATTACK_A,
	[ConfigBuffType.DEFENCE_B] 				= ObjPP.DEFENCE_B,
	[ConfigBuffType.DEFENCE_A] 				= ObjPP.DEFENCE_A,
	[ConfigBuffType.OHP_B] 					= ObjPP.OHP_B,
	[ConfigBuffType.OHP_A] 					= ObjPP.OHP_A,
	[ConfigBuffType.CR_RATE_B] 				= ObjPP.CR_RATE_B,
	[ConfigBuffType.CR_RATE_A] 				= ObjPP.CR_RATE_A,
	[ConfigBuffType.ATK_RATE_B] 			= ObjPP.ATK_RATE_B,
	[ConfigBuffType.ATK_RATE_A] 			= ObjPP.ATK_RATE_A,
	[ConfigBuffType.CR_DAMAGE_B] 			= ObjPP.CR_DAMAGE_B,
	[ConfigBuffType.CR_DAMAGE_A] 			= ObjPP.CR_DAMAGE_A,

	[ConfigBuffType.GET_DAMAGE_ATTACK] 		= ObjPP.GET_DAMAGE_ATTACK,
	[ConfigBuffType.GET_DAMAGE_SKILL] 		= ObjPP.GET_DAMAGE_SKILL,
	[ConfigBuffType.GET_DAMAGE_PHYSICAL] 	= ObjPP.GET_DAMAGE_PHYSICAL,
	[ConfigBuffType.CAUSE_DAMAGE_ATTACK] 	= ObjPP.CAUSE_DAMAGE_ATTACK,
	[ConfigBuffType.CAUSE_DAMAGE_SKILL] 	= ObjPP.CAUSE_DAMAGE_SKILL,
	[ConfigBuffType.CAUSE_DAMAGE_PHYSICAL] 	= ObjPP.CAUSE_DAMAGE_PHYSICAL,

	[ConfigBuffType.CDAMAGE_A] = nil,
	[ConfigBuffType.GDAMAGE_A] = nil,

}
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

	if nil ~= BuffType2ObjPP[btype] then
		-- 通用逻辑
		self:SetPType(BuffType2ObjPP[btype])
	else
		-- 特殊处理的类型
		if ConfigBuffType.CDAMAGE_A == btype then

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
			local percent = owner.attackDriver:GetActionTrigger() / owner:GetMainProperty():GetATKCounter()
			owner:GetMainProperty():Changepp(ptype, self.p.value)
			owner.attackDriver:SetActionTrigger(percent * owner:GetMainProperty():GetATKCounter())
			------------ data ------------

			------------ view ------------
			owner:FixAnimationScaleByATKRate()
			------------ view ------------

		elseif ConfigBuffType.OHP_A == btype or
			ConfigBuffType.OHP_B == btype then

			-- 影响最大血量时的buff需要根据血量百分比改变当前血量
			------------ data ------------
			-- 计算当前生命百分比
			owner:GetMainProperty():UpdateCurHpPercent()
			local hpPercent = owner:GetMainProperty():GetCurHpPercent()
			-- 刷新系数
			owner:GetMainProperty():Changepp(ptype, self.p.value)
			-- 重置当前血量至之前的生命百分比
			local curHp = owner:GetMainProperty():GetOriginalHp() * hpPercent
			owner:GetMainProperty():Setp(ObjP.HP, curHp)
			owner:GetMainProperty():UpdateCurHpPercent()
			------------ data ------------

			------------ view ------------
			owner:UpdateHpBar()
			------------ view ------------

		else

			-- 通用逻辑
			owner:GetMainProperty():Changepp(ptype, self.p.value)

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
			local percent = owner.attackDriver:GetActionTrigger() / owner:GetMainProperty():GetATKCounter()
			owner:GetMainProperty():Changepp(ptype, -self.p.value)
			owner.attackDriver:SetActionTrigger(percent * owner:GetMainProperty():GetATKCounter())
			------------ data ------------

			------------ view ------------
			owner:FixAnimationScaleByATKRate()
			------------ view ------------

		elseif ConfigBuffType.OHP_A == btype or
			ConfigBuffType.OHP_B == btype then

			------------ data ------------
			owner:GetMainProperty():Changepp(ptype, -self.p.value)
			if owner:GetMainProperty():GetCurrentHp() > owner:GetMainProperty():GetOriginalHp() then
				owner:GetMainProperty():Setp(ObjP.HP, owner:GetMainProperty():GetOriginalHp())
				owner:GetMainProperty():UpdateCurHpPercent()
			end
			------------ data ------------

			------------ view ------------
			owner:UpdateHpBar()
			------------ view ------------

		else

			owner:GetMainProperty():Changepp(ptype, -self.p.value)

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

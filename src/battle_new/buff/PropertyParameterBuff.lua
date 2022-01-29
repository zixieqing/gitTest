--[[
变化属性的buff
@params args ObjectBuffConstructorStruct
--]]
local BaseBuff = __Require('battle.buff.BaseBuff')
local PropertyParameterBuff = class('PropertyParameterBuff', BaseBuff)

------------ import ------------
------------ import ------------

------------ define ------------
------------ define ------------

---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
@override
初始化属性系数信息
--]]
function PropertyParameterBuff:InitExtraValue()
	self.ptype = checknumber(self.p.value[1])
	self.pvalue = checknumber(self.p.value[2])
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
function PropertyParameterBuff:CauseEffect()
	local owner = self:GetBuffOwner()

	if nil ~= owner then

		local ptype = self:GetPType()
		local pvalue = self:GetPValue()

		if ObjPP.ATK_RATE_A == ptype or ObjPP.ATK_RATE_B == ptype then

			-- 影响攻速时的buff需要改变一次攻击的cd和动画的速率
			------------ data ------------
			local percent = owner.attackDriver:GetActionTrigger() / owner:GetMainProperty():GetATKCounter()
			owner:GetMainProperty():Changepp(ptype, pvalue)
			owner.attackDriver:SetActionTrigger(percent * owner:GetMainProperty():GetATKCounter())
			------------ data ------------

			------------ view ------------
			owner:FixAnimationScaleByATKRate()
			------------ view ------------

		elseif ObjPP.OHP_A == ptype or ObjPP.OHP_B == ptype then

			-- 影响最大血量时的buff需要根据血量百分比改变当前血量
			------------ data ------------
			-- 计算当前生命百分比
			owner:GetMainProperty():UpdateCurHpPercent()
			local hpPercent = owner:GetMainProperty():GetCurHpPercent()
			-- 刷新系数
			owner:GetMainProperty():Changepp(ptype, pvalue)
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
			owner:GetMainProperty():Changepp(ptype, pvalue)

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
function PropertyParameterBuff:RecoverEffect()
	local owner = self:GetBuffOwner()

	if nil ~= owner then

		local ptype = self:GetPType()
		local pvalue = self:GetPValue()

		-- 恢复物体的属性系数
		if ObjPP.ATK_RATE_A == ptype or ObjPP.ATK_RATE_B == ptype then

			-- 影响攻速时的buff需要改变一次攻击的cd和动画的速率
			------------ data ------------
			local percent = owner.attackDriver:GetActionTrigger() / owner:GetMainProperty():GetATKCounter()
			owner:GetMainProperty():Changepp(ptype, -pvalue)
			owner.attackDriver:SetActionTrigger(percent * owner:GetMainProperty():GetATKCounter())
			------------ data ------------

			------------ view ------------
			owner:FixAnimationScaleByATKRate()
			------------ view ------------

		elseif ObjPP.OHP_A == ptype or ObjPP.OHP_B == ptype then

			-- 影响最大血量时的buff需要根据血量百分比改变当前血量
			------------ data ------------
			owner:GetMainProperty():Changepp(ptype, -pvalue)
			if owner:GetMainProperty():GetCurrentHp() > owner:GetMainProperty():GetOriginalHp() then
				owner:GetMainProperty():Setp(ObjP.HP, owner:GetMainProperty():GetOriginalHp())
				owner:GetMainProperty():UpdateCurHpPercent()
			end
			------------ data ------------

			------------ view ------------
			owner:UpdateHpBar()
			------------ view ------------

		else

			-- 通用逻辑
			owner:GetMainProperty():Changepp(ptype, -pvalue)

		end

	end

	BaseBuff.RecoverEffect(self)

	return 0
end
--[[
@override
刷新buff效果
@params value number
@params time number
--]]
function PropertyParameterBuff:RefreshBuffEffect(value, time)
	-- 移除一次原有的效果
	self:RecoverEffect()

	-- 刷新数据
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
获取变化的属性参数类型
--]]
function PropertyParameterBuff:GetPType()
	return self.ptype
end
function PropertyParameterBuff:SetPType(ptype)
	self.ptype = ptype
end
--[[
获取属性参数的值
--]]
function PropertyParameterBuff:GetPValue()
	return self.pvalue
end
function PropertyParameterBuff:SetPValue(pvalue)
	self.pvalue = pvalue
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return PropertyParameterBuff

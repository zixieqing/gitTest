--[[
多重射击 溅射 狂战
@params args ObjectBuffConstructorStruct
--]]
local BaseBuff = __Require('battle.buff.BaseBuff')
local MultishotBuff = class('MultishotBuff', BaseBuff)

---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
@override
初始化多重数据
--]]
function MultishotBuff:InitExtraValue()
	-- 初始化多重的索敌规则和倍率
	self.multishotRatio = checknumber(self.p.value[4])
	self.multishotSeekRule = SeekRuleStruct.New(
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
多重射击生效
--]]
function MultishotBuff:CauseEffect()
	local owner = self:GetBuffOwner()
	if nil ~= owner then
		------------ data ------------
		owner.attackDriver:GainMultishot(
			self:GetMultishotSeekRule(),
			self:GetMultishotRatio()
		)
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
function MultishotBuff:RecoverEffect()
	local owner = self:GetBuffOwner()

	if nil ~= owner then
		------------ data ------------
		owner.attackDriver:LostMultishot(
			self:GetMultishotSeekRule(),
			self:GetMultishotRatio()
		)
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
function MultishotBuff:RefreshBuffEffect(value, time)
	-- 移除一次原有的效果
	self:RecoverEffect()

	-- 刷新一次多重数据
	BaseBuff.RefreshBuffEffect(self, value, time)
	self:InitExtraValue()

	-- 效果生效一次
	self:CauseEffect()
end
--[[
@override
叠加buff -> 叠加多重倍率 索敌不变
@params buffInfo ObjectBuffConstructorStruct buff数据
--]]
function MultishotBuff:OnInnerPileEnter(buffInfo)
	self:SetInnerPile(math.max(self:GetInnerPileMax(), self:GetInnerPile() + 1))
	self.multishotRatio = self.multishotRatio * self:GetInnerPile()
	self:CauseEffect()
end
---------------------------------------------------
-- logic end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
获取多重伤害倍率
@return _ number 多重射击的倍率
--]]
function MultishotBuff:GetMultishotRatio()
	return self.multishotRatio
end
--[[
获取多重的索敌规则
@return _ SeekRuleStruct 索敌规则
--]]
function MultishotBuff:GetMultishotSeekRule()
	return self.multishotSeekRule
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return MultishotBuff

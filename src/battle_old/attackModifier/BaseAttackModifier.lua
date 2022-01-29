--[[
攻击特效 抽象类
@params table {
	tag int 攻击特效驱动器唯一tag
	owner BaseObject 挂载的战斗物体
}
--]]
local BaseAttackModifier = class('BaseAttackModifier')
--[[
constructor
--]]
function BaseAttackModifier:ctor( ... )
	local args = unpack({...})

	self.tag = args.tag
	self.owner = args.owner
	self.value = 0

	self.amType = AttackModifierType.AMT_BASE

	---------- 攻击特效充能计数器 攻击特效可能会被充能buff触发 ----------
	self.effectCache = {}
	---------- 攻击特效充能计数器 攻击特效可能会被充能buff触发 ----------
end
---------------------------------------------------
-- init logic begin --
---------------------------------------------------
--[[
初始化逻辑
--]]
function BaseAttackModifier:Init()
	-- 是否扣掉了次数并且可以使攻击特效生效
	self.costTimeCanCauseEffect = false
end
---------------------------------------------------
-- init logic end --
---------------------------------------------------

---------------------------------------------------
-- control logic begin --
---------------------------------------------------
--[[
是否可以进入逻辑
--]]
function BaseAttackModifier:CanEnterModifier()
	-- if 0 == self:GetValue() then
	if self:IsInvalid() or (not self:GetCostTimeCanCauseEffect()) then
		return false
	else
		return true
	end
end
--[[
进入逻辑
--]]
function BaseAttackModifier:OnModifierEnter()

end
--[[
结束逻辑
--]]
function BaseAttackModifier:OnModifierExit()
	-- 检查效果
	self:SetCostTimeCanCauseEffect(false)
	local effect = nil
	for i = #self.effectCache, 1, -1 do
		effect = self.effectCache[i]
		if ValueConstants.V_NONE == effect.times then
			self:RemoveEffectByIndex(i)
		end
	end
	-- print('here check exit struct<<<<<<<<<<<', self:GetOwner():getOCardName(), self:GetValue())
	-- dump(self.effectCache)
end
--[[
消耗做出行为需要的资源
--]]
function BaseAttackModifier:CostModifierResources()
	local effect = nil
	for i = #self.effectCache, 1, -1 do
		effect = self.effectCache[i]
		if ValueConstants.V_NORMAL <= effect.times then
			self.effectCache[i].times = self.effectCache[i].times - 1
		end
	end
	self:SetCostTimeCanCauseEffect(true)
	-- print('here check cost struct>>>>>>>>>>>>>>>>', self:GetOwner():getOCardName(), self:GetValue())
	-- dump(self.effectCache)
end
---------------------------------------------------
-- control logic end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
获取效果值
--]]
function BaseAttackModifier:GetValue()
	return self.value
end
--[[
变化效果值
--]]
function BaseAttackModifier:AddValue(deltaValue)
	self.value = self.value + deltaValue
end
--[[
添加效果
@params effect table {
	value number 效果值
	times int 充能次数
	bid string buff id
}
--]]
function BaseAttackModifier:AddEffect(effect)
	if ValueConstants.V_NORMAL <= effect.times then
		table.insert(self.effectCache, 1, effect)
	end
	self:AddValue(effect.value)
end
--[[
刷新效果
@params effect table {
	value number 效果值
	times int 充能次数
	bid string buff id
}
--]]
function BaseAttackModifier:RefreshEffect(effect)
	local effect_ = nil
	for i = #self.effectCache, 1, -1 do
		effect_ = self.effectCache[i]
		if effect_.bid and effect_.bid == effect.bid then
			-- 找到了effect 刷新数据
			self.effectCache[i].value = effect.value
			self.effectCache[i].times = effect.times
			return
		end
	end
	-- 未找到 插入
	-- 插入为了做主动和被动的叠加
	self:AddEffect(effect)
end
--[[
根据index移除效果
@params idx int index
--]]
function BaseAttackModifier:RemoveEffectByIndex(idx)
	local effect = self.effectCache[idx]
	if nil ~= effect then
		table.remove(self.effectCache, idx)
		self:AddValue(-effect.value)
	end
end
--[[
根据buff id移除效果
@params bid string buff id
--]]
function BaseAttackModifier:RemoveEffectByBuffId(bid)
	local effect = nil
	for i = #self.effectCache, 1, -1 do
		effect = self.effectCache[i]
		if effect.bid and effect.bid == bid then
			self:RemoveEffectByIndex(i)
			break
		end
	end
end
--[[
获取id
--]]
function BaseAttackModifier:GetAttackModifierTag()
	return self.tag
end
--[[
获取战斗物体
--]]
function BaseAttackModifier:GetOwner()
	-- assert(nil ~= self.owner, "ActionDriver must have owner")
	return self.owner
end
--[[
获取攻击特效类型
--]]
function BaseAttackModifier:GetAttackModifierType()
	return self.amType
end
--[[
是否扣过次数并且可以生效
--]]
function BaseAttackModifier:SetCostTimeCanCauseEffect(value)
	self.costTimeCanCauseEffect = value
end
function BaseAttackModifier:GetCostTimeCanCauseEffect()
	return self.costTimeCanCauseEffect
end
--[[
是否已经失效
--]]
function BaseAttackModifier:IsInvalid()
	return false
end
---------------------------------------------------
-- get set end --
---------------------------------------------------


return BaseAttackModifier

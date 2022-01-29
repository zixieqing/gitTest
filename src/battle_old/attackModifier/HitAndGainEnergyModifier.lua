--[[
击中回复能量攻击特效
@params table {
	tag int 攻击特效驱动器唯一tag
	owner BaseObject 挂载的战斗物体
}
--]]
local BaseAttackModifier = __Require('battle.attackModifier.BaseAttackModifier')
local HitAndGainEnergyModifier = class('HitAndGainEnergyModifier', BaseAttackModifier)
--[[
constructor
--]]
function HitAndGainEnergyModifier:ctor( ... )
	BaseAttackModifier.ctor(self, ...)

	self.amType = AttackModifierType.AMT_HIT_GAIN_ENERGY

	self:Init()
end
---------------------------------------------------
-- init logic begin --
---------------------------------------------------

---------------------------------------------------
-- init logic end --
---------------------------------------------------

---------------------------------------------------
-- control logic begin --
---------------------------------------------------
--[[
进入逻辑
@params phase int 攻击分段计数
@params percent number 分段百分比
--]]
function HitAndGainEnergyModifier:OnModifierEnter(phase, percent)
	------------ logic ------------
	local energyValue = self:GetValue() * percent
	self:GetOwner():addEnergy(energyValue)
	------------ logic ------------
end
---------------------------------------------------
-- control logic end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
@override
是否已经失效
--]]
function HitAndGainEnergyModifier:IsInvalid()
	-- return ValueConstants.V_NONE == self:GetValue() and ValueConstants.V_NONE == #self.effectCache
	return ValueConstants.V_NONE == #self.effectCache
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return HitAndGainEnergyModifier

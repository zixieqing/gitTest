--[[
最终伤害攻击特效
@params table {
	tag int 攻击特效驱动器唯一tag
	owner BaseObject 挂载的战斗物体
}
--]]
local BaseAttackModifier = __Require('battle.attackModifier.BaseAttackModifier')
local UltimateDamageModifier = class('UltimateDamageModifier', BaseAttackModifier)
--[[
constructor
--]]
function UltimateDamageModifier:ctor( ... )
	BaseAttackModifier.ctor(self, ...)

	self.amType = AttackModifierType.AMT_ATK_B

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
@params  ObjectExternalDamageParameterStruct 影响伤害的外部参数
--]]
function UltimateDamageModifier:OnModifierEnter(phase, percent, externalDamageParameter)
	------------ logic ------------
	externalDamageParameter.ultimateDamage = externalDamageParameter.ultimateDamage + self:GetValue()
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
function UltimateDamageModifier:IsInvalid()
	-- return ValueConstants.V_NONE == self:GetValue() and ValueConstants.V_NONE == #self.effectCache
	return ValueConstants.V_NONE == #self.effectCache
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return UltimateDamageModifier

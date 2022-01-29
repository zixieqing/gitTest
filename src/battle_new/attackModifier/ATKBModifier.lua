--[[
提升 ConfigBuffType.ATTACK_B 系数的攻击特效
攻击力增加或减少X点
@params table {
	tag int 攻击特效驱动器唯一tag
	owner BaseObject 挂载的战斗物体
}
--]]
local BaseAttackModifier = __Require('battle.attackModifier.BaseAttackModifier')
local ATKBModifier = class('ATKBModifier', BaseAttackModifier)
--[[
constructor
--]]
function ATKBModifier:ctor( ... )
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
function ATKBModifier:OnModifierEnter(phase, percent, externalDamageParameter)
	------------ logic ------------
	if nil == externalDamageParameter.objppAttacker[ObjPP.ATTACK_B] then
		externalDamageParameter.objppAttacker[ObjPP.ATTACK_B] = 0
	end
	externalDamageParameter.objppAttacker[ObjPP.ATTACK_B] = externalDamageParameter.objppAttacker[ObjPP.ATTACK_B] + self:GetValue()
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
function ATKBModifier:IsInvalid()
	-- return ValueConstants.V_NONE == self:GetValue() and ValueConstants.V_NONE == #self.effectCache
	return ValueConstants.V_NONE == #self.effectCache
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return ATKBModifier

--[[
100%必暴攻击特效
@params table {
	tag int 攻击特效驱动器唯一tag
	owner BaseObject 挂载的战斗物体
}
--]]
local BaseAttackModifier = __Require('battle.attackModifier.BaseAttackModifier')
local CertainCriticalModifier = class('CertainCriticalModifier', BaseAttackModifier)
--[[
constructor
--]]
function CertainCriticalModifier:ctor( ... )
	BaseAttackModifier.ctor(self, ...)

	self.amType = AttackModifierType.AMT_CERTAIN_CRITICAL

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
function CertainCriticalModifier:OnModifierEnter(phase, percent, externalDamageParameter)
	------------ logic ------------
	externalDamageParameter.isCritical = true
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
变化效果值
--]]
function CertainCriticalModifier:AddValue(deltaValue)
	-- 该类型没有效果值
end
--[[
@override
是否已经失效
--]]
function CertainCriticalModifier:IsInvalid()
	return ValueConstants.V_NONE == #self.effectCache
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return CertainCriticalModifier

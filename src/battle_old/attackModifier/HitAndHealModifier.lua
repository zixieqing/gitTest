--[[
击中回复生命值攻击特效 -- 注意 这不是吸血 造成0伤害也会回复生命
@params table {
	tag int 攻击特效驱动器唯一tag
	owner BaseObject 挂载的战斗物体
}
--]]
local BaseAttackModifier = __Require('battle.attackModifier.BaseAttackModifier')
local HitAndHealModifier = class('HitAndHealModifier', BaseAttackModifier)
--[[
constructor
--]]
function HitAndHealModifier:ctor( ... )
	BaseAttackModifier.ctor(self, ...)

	self.amType = AttackModifierType.AMT_HIT_AND_HEAL

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
function HitAndHealModifier:OnModifierEnter(phase, percent)
	-- print('here should heal self!!!!!!!!!!!!<<<<<<<<<<<<<<<<<<<<<')
	------------ logic ------------
	local healValue = self:GetValue() * percent
	local damageData = ObjectDamageStruct.New(
		self:GetOwner():getOTag(),
		healValue,
		DamageType.ATTACK_HEAL,
		false,
		{healerTag = self:GetOwner():getOTag()}
	)
	self:GetOwner():beHealed(damageData)
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
function HitAndHealModifier:IsInvalid()
	-- return ValueConstants.V_NONE == self:GetValue() and ValueConstants.V_NONE == #self.effectCache
	return ValueConstants.V_NONE == #self.effectCache
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return HitAndHealModifier

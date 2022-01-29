--[[
护盾buff
@params args ObjectBuffConstructorStruct
--]]
local BaseBuff = __Require('battle.buff.BaseBuff')
local ShieldBuff = class('ShieldBuff', BaseBuff)

------------ import ------------
------------ import ------------

------------ define ------------
------------ define ------------

---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
@override
初始化
--]]
function ShieldBuff:Init()
	BaseBuff.Init(self)
	self:AddView()
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
@params damage number 伤害
@return result number 抵消的伤害值
--]]
function ShieldBuff:CauseEffect(damage)
	local damage_ = damage
	local effect = damage_

	if self.p.value <= damage_ then
		-- 护盾不足以抵挡本次攻击
		effect = self.p.value
		-- 将护盾剩余值置为0
		self.p.value = 0

		-- waring 现在不再此处移除护盾 此处移除护盾会导致object中update遍历buff得到空
		-- self:OnRecoverEffectEnter()
	else
		self.p.value = self.p.value - damage_
	end

	---------- skada ----------
	local trueHeal = effect

	-- 物体造成的治疗
	G_BattleLogicMgr:SkadaWork(
		SkadaType.HEAl,
		self:GetBuffCasterTag(), nil, trueHeal
	)
	---------- skada ----------

	return effect
end
--[[
@override
主逻辑更新
--]]
function ShieldBuff:OnBuffUpdateEnter(dt)
	if self:IsHaloBuff() then return end
	
	if 0 >= self.p.countdown then
		self:ShieldOverplus()
		self:OnRecoverEffectEnter()
		return
	end

	if 0 >= self.p.value then
		self:OnRecoverEffectEnter()
		return
	end

	self.p.countdown = self.p.countdown - dt
end
--[[
护盾过剩
--]]
function ShieldBuff:ShieldOverplus()
	local owner = self:GetBuffOwner()

	if nil ~= owner and owner.triggerDriver then
		owner.triggerDriver:OnActionEnter(ConfigObjectTriggerActionType.SHIELD_OVERPLUS)
	end
end
---------------------------------------------------
-- logic end --
---------------------------------------------------

return ShieldBuff

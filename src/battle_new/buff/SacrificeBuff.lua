--[[
牺牲
@params args ObjectBuffConstructorStruct
--]]
local BaseBuff = __Require('battle.buff.BaseBuff')
local SacrificeBuff = class('SacrificeBuff', BaseBuff)

---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
@override
初始化
--]]
function SacrificeBuff:Init()
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
醉拳生效 减伤
@params damage number 伤害
@params damageData ObjectDamageStruct 伤害信息
@params reduceDamage number 抵消的伤害值
--]]
function SacrificeBuff:CauseEffect(damage, damageData)
	local owner = self:GetBuffOwner()
	local caster = self:GetBuffCaster()

	if nil ~= owner and nil ~= caster then
		local ownerTag = self:GetBuffOwnerTag()
		local casterTag = self:GetBuffCasterTag()

		local reduceDamage = damage * math.max(0, math.min(1, self:GetValue()))
		-- 向施法者发送伤害
		local damageData = ObjectDamageStruct.New(
			casterTag,
			reduceDamage,
			damageData.damageType,
			false,
			{attackerTag = ownerTag},
			{skillId = self:GetSkillId(), btype = self:GetBuffType()}
		)
		caster:BeAttacked(damageData)

		return reduceDamage
	end

	return 0
end
---------------------------------------------------
-- logic end --
---------------------------------------------------

return SacrificeBuff

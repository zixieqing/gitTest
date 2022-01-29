--[[
复活buff
--]]
local BaseBuff = __Require('battle.buff.BaseBuff')
local ReviveBuff = class('ReviveBuff', BaseBuff)

------------ import ------------
------------ import ------------

------------ define ------------
------------ define ------------

---------------------------------------------------
-- logic begin --
---------------------------------------------------
--[[
@override
造成效果
@return result number 造成效果以后的结果
--]]
function ReviveBuff:CauseEffect()
	local owner = self:GetBuffOwner()
	print('----------------->here cause revive<-----------------', tostring(owner))

	if nil == owner then
		print('!!!!!\n 		waring you want to revive an alive obj, this is logic error\n!!!!!')
	else
		local btype = self:GetBuffType()
		local ownerTag = self:GetBuffOwnerTag()
		local casterTag = self:GetBuffCasterTag()

		local reviveHpPercent = checknumber(self.p.value[1])
		local reviveEnergyPercent = checknumber(self.p.value[2])

		local healData = ObjectDamageStruct.New(
			ownerTag,
			0,
			DamageType.SKILL_HEAL,
			false,
			{healerTag = casterTag},
			{skillId = self:GetSkillId(), btype = btype}
		)

		owner:Revive(reviveHpPercent, reviveEnergyPercent, healData)
		self:AddView()
	end
end
--[[
@override
添加buff对应的展示
--]]
function ReviveBuff:AddView()
	local owner = self:GetBuffOwner()
	if nil ~= owner then
		owner:ShowHurtEffect(self.buffInfo.hurtEffectData)
	end
end
---------------------------------------------------
-- logic end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
@override
获取buff施法物体的tag
@return _ BaseObject obj
--]]
function ReviveBuff:GetBuffOwner()
	return G_BattleLogicMgr:GetDeadObjByTag(self:GetBuffOwnerTag())
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return ReviveBuff

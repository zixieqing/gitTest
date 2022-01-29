--[[
全局影响能力的buff
--]]
local BaseGlobalBuff = __Require('battle.globalBuff.BaseGlobalBuff')
local GlobalAbilityBuff = class('GlobalAbilityBuff', BaseGlobalBuff)

---------------------------------------------------
-- init logic beign --
---------------------------------------------------
--[[
@override
初始化数据
--]]
function GlobalAbilityBuff:InitValue(args)
	BaseGlobalBuff.InitValue(self, args)

	-- 初始化影响的参数类型
	local btype = self:GetBuffInfo().btype
	self.ptype = 0
	if ConfigGlobalBuffType.OHP_A == btype then
		self.ptype = ObjPP.OHP_A
	elseif ConfigGlobalBuffType.ATTACK_A == btype then
		self.ptype = ObjPP.ATTACK_A
	elseif ConfigGlobalBuffType.DEFENCE_A == btype then
		self.ptype = ObjPP.DEFENCE_A
	elseif ConfigGlobalBuffType.CDAMAGE_A == btype then
		if self.value >= 0 then
			self.ptype = ObjPP.CDAMAGE_UP
		else
			self.ptype = ObjPP.CDAMAGE_DOWN
		end
	end
end
---------------------------------------------------
-- init logic end --
---------------------------------------------------

---------------------------------------------------
-- control logic begin --
---------------------------------------------------
--[[
@overdide
产生效果
@params ownerTag int 被施法者tag
--]]
function GlobalAbilityBuff:CauseEffect(ownerTag)
	local btype = self:GetBuffInfo().btype
	local owner = BMediator:IsObjAliveByTag(ownerTag)
	if nil ~= owner then
		if ConfigGlobalBuffType.OHP_A == btype then

			-- 计算当前生命百分比
			owner:getMainProperty():updateCurHpPercent()
			local hpPercent = owner:getMainProperty():getCurHpPercent()
			-- 刷新系数
			owner:getMainProperty():changepp(self.ptype, self.value)
			-- 重置当前血量至之前的生命百分比
			local curHp = owner:getMainProperty():getOriginalHp() * hpPercent
			owner:getMainProperty():setp(ObjP.HP, curHp)
			owner:getMainProperty():updateCurHpPercent()
			owner:updateHpBar(true)

		else

			owner:getMainProperty():changepp(self.ptype, self.value)

		end
	end
end
--[[
@override
恢复效果
--]]
function GlobalAbilityBuff:RecoverEffect(ownerTag)
	local btype = self.op.btype
	local owner = BMediator:IsObjAliveByTag(self.op.ownerTag)

	if nil ~= owner then
		if ConfigGlobalBuffType.OHP_A == btype then

			owner:getMainProperty():changepp(self.ptype, -self.value)
			if owner:getMainProperty():getCurrentHp() > owner:getMainProperty():getOriginalHp() then
				owner:getMainProperty():setp(ObjP.HP, self:getMainProperty():getOriginalHp())
				owner:getMainProperty():updateCurHpPercent()
			end
			owner:updateHpBar(true)

		else

			owner:getMainProperty():changepp(self.ptype, -self.value)

		end
	end
end
---------------------------------------------------
-- control logic end --
---------------------------------------------------

return GlobalAbilityBuff

--[[
驱散buff
@params args ObjectBuffConstructorStruct
--]]
local BaseBuff = __Require('battle.buff.BaseBuff')
local DispelBuff = class('DispelBuff', BaseBuff)

------------ import ------------
------------ import ------------

------------ define ------------
------------ define ------------

---------------------------------------------------
-- logic begin --
---------------------------------------------------
--[[
造成效果
--]]
function DispelBuff:CauseEffect()
	local owner = self:GetBuffOwner()

	if nil ~= owner then
		local btype = self:GetBuffType()

		if ConfigBuffType.DISPEL_QTE == btype then

			-- 驱散qte类的buff
			for i = table.nums(owner.buffs.idx), 1, -1 do
				local b = owner.buffs.idx[i]
				if b:HasQTE() and self:CanDispelBuff(b:GetSkillId(), b:GetBuffType()) then
					b:OnBeDispeledEnter()
				end
			end

		elseif ConfigBuffType.DISPEL_BECKON == btype then

			-- 一键驱散召唤物
			local objs = G_BattleLogicMgr:GetAliveBeckonObjs()
			local obj = nil
			for i = #objs, 1, -1 do
				obj = objs[i]
				obj:DieBegin()
			end

		else

			-- 正常驱散逻辑
			local removeDebuff = ConfigBuffType.DISPEL_DEBUFF == btype and true or false
			for i = table.nums(owner.buffs.idx), 1, -1 do
				local b = owner.buffs.idx[i]
				if (not b:HasQTE()) and self:CanDispelBuff(b:GetSkillId(), b:GetBuffType()) then
					-- 具备驱散普通 buff 的条件 做判断驱散的是 buff 还是 debuff
					if removeDebuff == b:IsDebuff() then
						b:OnBeDispeledEnter()
					end
				end
			end

		end
	end

	return 0
end
--[[
@override
主逻辑更新
--]]
function DispelBuff:OnBuffUpdateEnter(dt)

end
--[[
@override
恢复效果
@params casterTag int 施法者tag
@return result number 恢复效果以后的结果
--]]
function DispelBuff:OnRecoverEffectEnter(casterTag)
	return 0
end
--[[
@override
添加buff对应的展示
--]]
function DispelBuff:AddView()
	
end
--[[
@override
移除buff对应的展示
--]]
function DispelBuff:RemoveView()
	
end
---------------------------------------------------
-- logic end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
是否能移除对应ConfigBuffType的buff
@params targetskillId int 驱散目标技能id
@params targetbtype ConfigBuffType 驱散目标buff类型
@return _ bool 是否能移除
--]]
function DispelBuff:CanDispelBuff(targetskillId, targetbtype)
	if ConfigBuffType.DISPEL_QTE == targetbtype then

		-- 驱散qte 做判断
		for i,v in ipairs(self.p.value) do
			if targetbtype == checkint(v) then
				return true
			end
		end
		return false
		
	elseif ConfigBuffType.TRIGGER_BUFF == targetbtype then

		return false

	else

		-- 普通驱散 根据技能免疫驱散字段做处理
		local skillConf = CommonUtils.GetSkillConf(targetskillId)
		local immuneDispelConf = checktable(skillConf.immuneDispel)
		-- 由于配表的 immuneDispel 字段不是 map 结构，所以目前不做 skillType 的读取区分。
		for i,v in ipairs(immuneDispelConf) do
			for _, buffType in ipairs(string.split2(checkstr(v))) do
				if checkint(buffType) == self:GetBuffType() then
					return false
				end
			end
		end
		return true

	end
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return DispelBuff

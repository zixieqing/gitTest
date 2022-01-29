--[[
终结技 终结dot类buff
@params args ObjectBuffConstructorStruct
--]]
local BaseBuff = __Require('battle.buff.BaseBuff')
local DOTFinisherBuff = class('DOTFinisherBuff', BaseBuff)

---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
@override
初始化buff特有的数据
--]]
function StaggerBuff:InitExtraValue()
	-- 索敌规则
	self.seekRule = SeekRuleStruct.New(
		checkint(self.p.value[1]),
		checkint(self.p.value[3]),
		checkint(self.p.value[2])
	)

	-- 初始化终结技配置
	self.enhanceRatio = checknumber(self.p.value[5])
	self.canInfect = 1 == checkint(self.p.value[4])

	-- 初始化终结的buff类型
	self.finishBuffType = {}
	for i = 6, #self.p.value do
		table.insert(self.finishBuffType, checkint(self.p.value[i]))
	end
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
@return result number 造成效果以后的结果
--]]
function DOTFinisherBuff:CauseEffect()
	local owner = self:GetBuffOwner()

	if nil ~= owner then
		local buff = nil
		local buffTypes = self:GetFinishBuffType()

		for _, buffType in ipairs(buffTypes) do
			local buffs = owner:GetBuffsByBuffType(buffType, true)
			for i = #buffs, 1, -1 do
				buff = buffs[i]
				-- 无法终结光环产生的buff
				if not buff:IsHaloBuff() then

					if buff:GetBuffOriginCountdown() ~= buff:GetLeftCountdown() then

						local buffInfo = buff.buffInfo

						------------ 终结buff ------------
						local leftDamage = buff:Finish(self:GetEnhanceRatio())
						------------ 终结buff ------------

						if self:CanInfect() then
							------------ 传染 ------------
							local targets = BattleExpression.GetTargets(owner:isEnemy(true), self:GetSeekRule(), owner)
							for _, target in ipairs(targets) do
								local buffInfo_ = clone(buffInfo)
								-- 修改buffInfo信息
								buffInfo_.ownerTag = target:getOTag()
								target:beCasted(buffInfo_)
							end
							------------ 传染 ------------	
						end
						
					end

				end
			end
		end
	end	
end
--[[
@override
主逻辑更新
--]]
function DOTFinisherBuff:OnBuffUpdateEnter(dt)

end
--[[
@override
恢复效果
@params casterTag int 施法者tag
@return result number 恢复效果以后的结果
--]]
function DOTFinisherBuff:OnRecoverEffectEnter(casterTag)
	return 0
end
--[[
@override
添加buff对应的展示
--]]
function DOTFinisherBuff:AddView()
	
end
--[[
@override
移除buff对应的展示
--]]
function DOTFinisherBuff:RemoveView()
	
end
---------------------------------------------------
-- logic end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
放大倍数
--]]
function DOTFinisherBuff:GetEnhanceRatio()
	return self.enhanceRatio
end
--[[
是否可以传染
--]]
function DOTFinisherBuff:CanInfect()
	return self.canInfect
end
--[[
获取终结的buff类型
--]]
function DOTFinisherBuff:GetFinishBuffType()
	return self.finishBuffType
end
--[[
获取索敌规则
--]]
function DOTFinisherBuff:GetSeekRule()
	return self.seekRule
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return DOTFinisherBuff

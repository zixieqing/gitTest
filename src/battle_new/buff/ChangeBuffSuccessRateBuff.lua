--[[
变更技能buff释放成功率
@params args ObjectBuffConstructorStruct
--]]
local BaseBuff = __Require('battle.buff.BaseBuff')
local ChangeBuffSuccessRateBuff = class('ChangeBuffSuccessRateBuff', BaseBuff)

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
function ChangeBuffSuccessRateBuff:Init()
	BaseBuff.Init(self)

	self:AddView()
end
--[[
@override
初始化buff特有的数据
--]]
function ChangeBuffSuccessRateBuff:InitExtraValue()
	self.changeInfo = {}
	for i = 1, #self.p.value, 3 do
		local skillId = checkint(self.p.value[i])
		local buffType = checkint(self.p.value[i + 1])
		local deltaRate = checknumber(self.p.value[i + 2])

		if nil == self.changeInfo[tostring(skillId)] then
			self.changeInfo[tostring(skillId)] = {}
		end
		if nil == self.changeInfo[tostring(skillId)][buffType] then
			self.changeInfo[tostring(skillId)][buffType] = 0
		end
		self.changeInfo[tostring(skillId)][buffType] = self.changeInfo[tostring(skillId)][buffType] + deltaRate
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
@params skillId int 技能id
@params buffType ConfigBuffType buff类型
@params rate number 原始的释放概率
@return result number 造成效果以后的结果
--]]
function ChangeBuffSuccessRateBuff:CauseEffect(skillId, buffType, rate)
	local owner = self:GetBuffOwner()
	if nil ~= owner then
		
		local deltaRate = self:GetDeltaRate(skillId, buffType)
		if nil ~= deltaRate then

			-- 做一次过滤 概率在[0, 1]
			rate = math.min(1, math.max(0, rate + deltaRate))
			return rate

		else

			return rate

		end

	end
end
---------------------------------------------------
-- logic end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
根据技能id和buff类型获取变化的buff释放成功率
@params skillId int 技能id
@params buffType ConfigBuffType buff类型
@return deltaRate number 变化的成功率
--]]
function ChangeBuffSuccessRateBuff:GetDeltaRate(skillId, buffType)
	if nil == self.changeInfo[tostring(skillId)] then
		return nil
	else
		return self.changeInfo[tostring(skillId)][buffType]
	end
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return BuffEnhanceTimeBuff

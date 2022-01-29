--[[
使自身造成的buff增强
@params args ObjectBuffConstructorStruct
--]]
local BaseBuff = __Require('battle.buff.BaseBuff')
local EnhanceBuffTimeCauseBuff = class('EnhanceBuffTimeCauseBuff', BaseBuff)

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
function EnhanceBuffTimeCauseBuff:Init()
	BaseBuff.Init(self)

	self:AddView()
end
--[[
@override
初始化buff特有的数据
--]]
function EnhanceBuffTimeCauseBuff:InitExtraValue()
	self.enhanceInfo = {}
	for i = 1, #self.p.value, 2 do
		local buffType = checkint(self.p.value[i])
		local enhanceTime = checknumber(self.p.value[i + 1])

		self.enhanceInfo[buffType] = {enhanceTime = enhanceTime}
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
@params buffType ConfigBuffType buff类型
@params time number 原始时间
@return result number 造成效果以后的结果
--]]
function EnhanceBuffTimeCauseBuff:CauseEffect(buffType, time)
	local owner = self:GetBuffOwner()
	if nil ~= owner then
		
		-- 计算增益时间
		local enhanceInfo = self:GetEnhanceInfoByBuffType(buffType)
		if nil ~= enhanceInfo then

			time = time + enhanceInfo.enhanceTime
			return time

		else

			return time

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
根据buff类型获取增益时间
@params buffType ConfigBuffType
@return _ number
--]]
function EnhanceBuffTimeCauseBuff:GetEnhanceInfoByBuffType(buffType)
	return self.enhanceInfo[buffType]
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return BuffEnhanceTimeBuff

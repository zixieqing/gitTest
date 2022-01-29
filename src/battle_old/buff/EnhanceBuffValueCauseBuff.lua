--[[
使自身造成的buff增强
@params args ObjectBuffConstructorStruct
--]]
local BaseBuff = __Require('battle.buff.BaseBuff')
local EnhanceBuffValueCauseBuff = class('EnhanceBuffValueCauseBuff', BaseBuff)

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
function EnhanceBuffValueCauseBuff:Init()
	BaseBuff.Init(self)

	self:AddView()
end
--[[
@override
初始化buff特有的数据
--]]
function EnhanceBuffValueCauseBuff:InitExtraValue()
	self.enhanceInfo = {}
	for i = 1, #self.p.value, 3 do
		local buffType = checkint(self.p.value[i])
		local enhanceValueMulti = checknumber(self.p.value[i + 1])
		local enhanceValue = checknumber(self.p.value[i + 2])

		self.enhanceInfo[buffType] = {
			enhanceValueMulti = enhanceValueMulti,
			enhanceValue = enhanceValue
		}
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
@parmas value 原始数值
@return result number 造成效果以后的结果
--]]
function EnhanceBuffValueCauseBuff:CauseEffect(buffType, value)
	local owner = self:GetBuffOwner()
	if nil ~= owner then
		
		-- 计算增益效果值
		local enhanceInfo = self:GetEnhanceInfoByBuffType(buffType)
		if nil ~= enhanceInfo then

			if not BattleUtils.IsTable(v) then

				value = value * enhanceInfo.enhanceValueMulti + enhanceValue
				return value

			else
				-- TODO --
				-- 表结构的数据暂时不处理
				return value
				-- TODO --
			end

		else

			return value

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

return EnhanceBuffValueCauseBuff

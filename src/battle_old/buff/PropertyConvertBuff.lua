--[[
属性转换buff
@params args ObjectBuffConstructorStruct
--]]
local BaseBuff = __Require('battle.buff.BaseBuff')
local PropertyConvertBuff = class('PropertyConvertBuff', BaseBuff)

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
function PropertyConvertBuff:Init()
	BaseBuff.Init(self)

	self:AddView()
end
--[[
@override
初始化buff特有的数据
--]]
function PropertyConvertBuff:InitExtraValue()
	self.convertInfo = {}
	self.convertedInfo = {}

	for i = 1, #self.p.value, 4 do
		-- 转换的源属性
		local oriptype = checkint(self.p.value[i])
		-- 转换的目标属性
		local targetptype = checkint(self.p.value[i + 1])
		-- 转换源属性的百分比
		local convertPercent = checknumber(self.p.value[i + 2])
		-- 转换成目标属性的比例
		local convertRatio = checknumber(self.p.value[i + 3])

		table.insert(self.convertInfo, {
			oriptype = oriptype,
			targetptype = targetptype,
			convertPercent = convertPercent,
			convertRatio = convertRatio
		})
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
--]]
function PropertyConvertBuff:CauseEffect()
	local owner = self:GetBuffOwner()

	if nil ~= owner then
		
		for _,v in ipairs(self.convertInfo) do

			local oripCurrentValue = owner:getMainProperty():getp(v.oriptype)
			if 1 < oripCurrentValue then
				-- 属性不能为0
				local oripOriginalValue = owner:getMainProperty():getp(v.oriptype)

				local convertValue = math.max(oripCurrentValue - 1, math.min(oripOriginalValue, oripOriginalValue * v.convertPercent))
				local fixedConvertValue = convertValue * v.convertRatio

				local oripdelta = -1 * convertValue
				local targetpdelta = fixedConvertValue

				owner:getMainProperty():setp(v.oriptype, oripOriginalValue + oripdelta)
				owner:getMainProperty():setp(v.targetptype, owner:getMainProperty():getp(v.targetptype) + targetpdelta)

				table.insert(self.convertedInfo, {
					oriptype = v.oriptype,
					targetptype = v.targetptype,
					oripdelta = oripdelta,
					targetpdelta = targetpdelta
				})
			else
				print('\n\n>>>>>>>>>>>>> \nhere get error objp is lower than 1 in property convert buff calc', self:GetSkillId(), self:GetBuffType())
			end
		end

	end

	return 0
end
--[[
@override
恢复效果
@return result number 恢复效果以后的结果
--]]
function PropertyConvertBuff:RecoverEffect()
	local owner = self:GetBuffOwner()

	if nil ~= owner then
		
		for _,v in ipairs(self.convertedInfo) do
			-- 恢复源属性
			owner:getMainProperty():setp(
				v.oriptype,
				owner:getMainProperty():getp(v.oriptype) - v.oripdelta
			)
			-- 恢复目标属性
			owner:getMainProperty():setp(
				v.targetptype,
				owner:getMainProperty():getp(v.targetptype) - v.targetpdelta
			)
		end

		BaseBuff.RecoverEffect(self)

	end

	return 0
end
--[[
@override
刷新buff效果
@params value number
@params time number
--]]
function PropertyConvertBuff:RefreshBuffEffect(value, time)
	-- 移除一次原有的效果
	self:RecoverEffect()

	-- 刷新数据
	BaseBuff.RefreshBuffEffect(self, value, time)
	self:InitExtraValue()
	
	-- 重新生效一次
	self:CauseEffect()
end
---------------------------------------------------
-- logic end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------

---------------------------------------------------
-- get set end --
---------------------------------------------------

return PropertyConvertBuff

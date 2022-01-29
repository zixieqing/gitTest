--[[
属性变化导致属性系数变化的buff
@params args ObjectBuffConstructorStruct
--]]
local PropertyParameterBuff = __Require('battle.buff.PropertyParameterBuff')
local PropertyParameterByPropertyBuff = class('PropertyParameterByPropertyBuff', PropertyParameterBuff)

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
function PropertyParameterByPropertyBuff:Init()
	PropertyParameterBuff.Init(self)
	self:AddView()
end
--[[
@override
初始化特有属性
--]]
function PropertyParameterByPropertyBuff:InitUnitValue()
	PropertyParameterBuff.InitUnitValue(self)

	-- 初始化变化的属性值
	self.pvalue = 0
	self:UpdatePValue()
	self.interval = 1
	self.p.interval = self:GetCauseEffectInterval()
end
--[[
@override
初始化属性系数信息
--]]
function PropertyParameterByPropertyBuff:InitExtraValue()
	self.propertyType = checkint(self.p.value[1])
	self.ptype = checkint(self.p.value[2])
	self.ratio0Percent = checknumber(self.p.value[3])
	self.ratio100Percent = checknumber(self.p.value[4])
end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- logic begin --
---------------------------------------------------
--[[
@override
主逻辑更新
--]]
function PropertyParameterByPropertyBuff:OnBuffUpdateEnter(dt)
	if 0 >= self.p.interval and self.p.countdown >= 0 then
		self:UpdatePValue()
		self.p.interval = self.p.interval + self:GetCauseEffectInterval()
	end

	PropertyParameterBuff.OnBuffUpdateEnter(dt)
end
--[[
刷新一次属性系数的值
--]]
function PropertyParameterByPropertyBuff:UpdatePValue()
	local owner = self:GetBuffOwner()

	if nil ~= owner then

		local propertyType = self:GetPropertyType()
		local currentPropertyValue = owner:getPropertyByObjP(propertyType)
		local originalPropertyValue = owner:getPropertyByObjP(propertyType, true)

		if nil ~= currentPropertyValue and nil ~= originalPropertyValue then

			local fixedPValue = ((currentPropertyValue / originalPropertyValue) * (self.ratio100Percent - self.ratio0Percent)) + self.ratio0Percent

			-- 还原一次原有系数
			self:RecoverEffect()
			-- 修改系数值
			self:SetPValue(fixedPValue)
			-- 生效一次新系数值
			self:CauseEffect()

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
获取刷新系数的时间间隔
--]]
function PropertyParameterByPropertyBuff:GetCauseEffectInterval()
	return self.interval
end
function PropertyParameterByPropertyBuff:SetCauseEffectInterval(interval)
	self.interval = interval
end
--[[
获取触发变化的属性类型
--]]
function PropertyParameterByPropertyBuff:GetPropertyType()
	return self.propertyType
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return PropertyParameterByPropertyBuff

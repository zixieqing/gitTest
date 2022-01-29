--[[
物体状态基类
--]]
local BaseObjectState = class('BaseObjectState')

------------ import ------------
------------ import ------------

------------ define ------------
------------ define ------------

--[[
constructor
--]]
function BaseObjectState:ctor( ... )
	local args = unpack({...})

	self:Init()
end

---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
初始化
--]]
function BaseObjectState:Init()
	self:InitValue()
end
--[[
初始化数值
--]]
function BaseObjectState:InitValue()
	self:InitInnateState()
	self:InitUnitState()
end
--[[
初始化固有状态
--]]
function BaseObjectState:InitInnateState()
	self:InitAbnormalState()
	self:InitCommonImmune()
	self:InitDamageImmune()
	self:InitGlobalDamageImmune()
end
--[[
初始化特有状态
--]]
function BaseObjectState:InitUnitState()

end
--[[
初始化异常状态信息
--]]
function BaseObjectState:InitAbnormalState()
	self.specialState = {}
	for _, state_ in pairs(AbnormalState) do
		self.specialState[state_] = false
	end
end
--[[
初始化通用免疫信息
--]]
function BaseObjectState:InitCommonImmune()
	-- 异常状态免疫
	self.abnormalImmune = {}
	for _, state_ in pairs(AbnormalState) do
		self.abnormalImmune[state_] = false
	end

	-- 伤害开关
	self.damageSwitch = false

	-- 天气免疫
	self.weatherImmune = {}

	-- 技能免疫
	self.buffImmune = {}

	-- 物体内置buff免疫
	self.objectInnerBuffImmune = {}
end
--[[
初始化伤害免疫
--]]
function BaseObjectState:InitDamageImmune()
	self.damageImmune = {}
	for _, v in pairs(DamageType) do
		self.damageImmune[v] = false
	end
end
--[[
初始化全局伤害免疫
--]]
function BaseObjectState:InitGlobalDamageImmune()
	self.globalDamageImmune = {}
	for _, v in pairs(DamageType) do
		self.globalDamageImmune[v] = false
	end
end
--[[
根据buff免疫信息设置免疫
@params skillImmuneInfo list[ConfigBuffType]
--]]
function BaseObjectState:InitInnerBuffImmune(skillImmuneInfo)
	for _, buffType in pairs(skillImmuneInfo) do
		self:SetInnerBuffImmuneByBuffType(checkint(buffType), true)
	end
end
--[[
根据天气免疫信息设置免疫
@params weatherImmuneInfo list[weahterId]
--]]
function BaseObjectState:InitWeatherImmune(weatherImmuneInfo)
	for _, weatherProperty in pairs(weatherImmuneInfo) do
		self:SetWeatherImmuneByWeatherProperty(checkint(weatherProperty), true)
	end
end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
异常状态
[AbnormalState]
--]]
function BaseObjectState:SetAbnormalState(state, b)
	self.specialState[state] = b
end
function BaseObjectState:GetAbnormalState(state)
	return self.specialState[state]
end


--[[
异常状态免疫
[AbnormalState]
--]]
function BaseObjectState:SetAbnormalImmune(state, b)
	self.abnormalImmune[state] = b
end
function BaseObjectState:GetAbnormalImmune(state)
	return self.abnormalImmune[state]
end


--[[
天气免疫
[int] weatherProperty 天气属性
--]]
function BaseObjectState:SetWeatherImmuneByWeatherProperty(weatherProperty, b)
	self.weatherImmune[weatherProperty] = b
end
function BaseObjectState:GetWeatherImmuneByWeatherProperty(weatherProperty)
	return self.weatherImmune[weatherProperty]
end
function BaseObjectState:GetWeatherImmuneByWeatherId(weatherId)
	local weatherConfig = CommonUtils.GetConfig('quest', 'weather', weatherId)
	if nil ~= weatherConfig then
		return self:GetWeatherImmuneByWeatherProperty(checkint(weatherConfig.weatherProperty))
	end
	return false
end


--[[
技能buff免疫
[ConfigBuffType] buffType buff类型
@params buffType ConfigBuffType buff类型
@params skillId int 技能id
@params b bool 是否免疫
--]]
function BaseObjectState:SetBuffImmuneByBuffType(buffType, skillId, b)
	if nil == self.buffImmune[buffType] then
		self.buffImmune[buffType] = {}
	end
	self.buffImmune[buffType][tostring(skillId)] = b
end
function BaseObjectState:GetBuffImmuneByBuffType(buffType)
	if nil == self.buffImmune[buffType] then
		return false
	else
		local immune = false
		for skillId_, immune_ in pairs(self.buffImmune[buffType]) do
			if true == immune_ then
				immune = true
				break
			end
		end
		return immune
	end
end


--[[
物体内置技能buff免疫
[ConfigBuffType] buffType buff类型
--]]
function BaseObjectState:SetInnerBuffImmuneByBuffType(buffType, b)
	self.objectInnerBuffImmune[buffType] = b
end
function BaseObjectState:GetInnerBuffImmuneByBuffType(buffType)
	return self.objectInnerBuffImmune[buffType]
end


--[[
伤害开关
--]]
function BaseObjectState:SetDamageSwitch(b)
	self.damageSwitch = b
end
function BaseObjectState:GetDamageSwitch()
	return self.damageSwitch
end


--[[
伤害免疫
[DamageType] 伤害类型
--]]
function BaseObjectState:SetDamageImmune(damageType, b)
	self.damageImmune[damageType] = b
end
function BaseObjectState:GetDamageImmune(damageType)
	return self.damageImmune[damageType]
end


--[[
全局伤害免疫
[DamageType] 伤害类型
--]]
function BaseObjectState:SetGlobalDamageImmune(damageType, b)
	self.globalDamageImmune[damageType] = b
end
function BaseObjectState:GetGlobalDamageImmune(damageType)
	return self.globalDamageImmune[damageType]
end


--[[
是否可以行动
--]]
function BaseObjectState:CanAct()
	return not (self:GetAbnormalState(AbnormalState.STUN) or self:GetAbnormalState(AbnormalState.FREEZE))
end


--[[
根据buff类型判断是否免疫该buff对应的异常状态
@params buffType ConfigBuffType
@return _ bool 是否免疫
--]]
function BaseObjectState:ImmuneAbnormalStateByBuffType(buffType)
	local config = {
		[ConfigBuffType.SILENT] 			= AbnormalState.SILENT,
		[ConfigBuffType.STUN] 				= AbnormalState.STUN,
		[ConfigBuffType.FREEZE] 			= AbnormalState.FREEZE,
		[ConfigBuffType.ENCHANTING] 		= AbnormalState.ENCHANTING,
		[ConfigBuffType.UNDEAD] 			= AbnormalState.UNDEAD,
		-- [ConfigBuffType.?] 			= AbnormalState.LUCK
	}

	local abnormalStateType = config[buffType]
	if nil ~= abnormalStateType then
		return self:GetAbnormalImmune(abnormalStateType)
	end

	return false
end

---------------------------------------------------
-- get set end --
---------------------------------------------------










return BaseObjectState

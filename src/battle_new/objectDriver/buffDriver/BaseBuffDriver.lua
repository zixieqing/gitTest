--[[
buff驱动器基类
@params table {
	owner BaseObject 挂载的战斗物体
}
--]]
local BaseActionDriver = __Require('battle.objectDriver.BaseActionDriver')
local BaseBuffDriver = class('BaseBuffDriver', BaseActionDriver)

------------ import ------------
------------ import ------------

------------ define ------------
------------ define ------------

--[[
constructor
--]]
function BaseBuffDriver:ctor( ... )
	BaseActionDriver.ctor(self, ...)

	self:Init()
end

---------------------------------------------------
-- init logic begin --
---------------------------------------------------
--[[
初始化逻辑
--]]
function BaseBuffDriver:Init()
	self:InitInnateValue()
	self:InitUnitValue()
end
--[[
初始化固有属性
--]]
function BaseBuffDriver:InitInnateValue()
	-- buff的内置触发cd记录
	self.buffTriggerInsideCD = {}
end
--[[
初始化独有属性
--]]
function BaseBuffDriver:InitUnitValue()
	
end
---------------------------------------------------
-- init logic end --
---------------------------------------------------

---------------------------------------------------
-- control logic begin --
---------------------------------------------------
--[[
是否能进行动作
@params skillId int 技能id
@params buffType ConfigBuffType buff类型
@params triggerActionType ConfigObjectTriggerActionType 触发类型
@return _ bool 是否可以添加buff
--]]
function BaseBuffDriver:CanTriggerBuff(skillId, buffType, triggerActionType)
	------------ buff内置cd ------------
	local buffTriggerInsideCD = self:GetBuffTriggerInsideCD(skillId, buffType, triggerActionType)
	if nil ~= buffTriggerInsideCD and 0 < buffTriggerInsideCD then
		return false
	end
	return true
	------------ buff内置cd ------------
end
--[[
消耗做出行为需要的资源
@params skillId int 技能id
@params buffType ConfigBuffType buff类型
@params triggerActionType ConfigObjectTriggerActionType 物体行为触发类型
@params countdown number 触发的cd
--]]
function BaseBuffDriver:CostTriggerBuffResources(skillId, buffType, triggerActionType, cd)
	-- 刷新一次buff内置cd
	self:SetBuffTriggerInsideCD(skillId, buffType, triggerActionType, cd)
end
--[[
刷新触发器
@params actionTriggerType ActionTriggerType 触发类型
@params delta number 变化量
--]]
function BaseBuffDriver:UpdateActionTrigger(actionTriggerType, delta)
	if ActionTriggerType.CD == actionTriggerType then
		self:UpdateBuffTriggerInsideCD(delta)
	end
end
---------------------------------------------------
-- control logic end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
设置buff作用的内置cd
@params skillId int 技能id
@params buffType ConfigBuffType buff类型
@params triggerActionType ConfigObjectTriggerActionType 触发类型
@params cd number 冷却时间
--]]
function BaseBuffDriver:SetBuffTriggerInsideCD(skillId, buffType, triggerActionType, cd)
	if nil == self.buffTriggerInsideCD[tostring(skillId)] then
		self.buffTriggerInsideCD[tostring(skillId)] = {}
	end
	self.buffTriggerInsideCD[tostring(skillId)][buffType] = cd


	-- TODO --
	-- 暂时不考虑以触发行为类型分类
	-- if nil == self.buffTriggerInsideCD[tostring(skillId)] then
	-- 	self.buffTriggerInsideCD[tostring(skillId)] = {}
	-- end
	-- if nil == self.buffTriggerInsideCD[tostring(skillId)][buffType] then
	-- 	self.buffTriggerInsideCD[tostring(skillId)][buffType] = {}
	-- end
	-- self.buffTriggerInsideCD[tostring(skillId)][buffType][triggerActionType] = cd
	-- TODO --
end
--[[
获取buff作用的内置cd
@params skillId int 技能id
@params buffType ConfigBuffType buff类型
@params triggerActionType ConfigObjectTriggerActionType 触发类型
@return cd number 冷却时间
--]]
function BaseBuffDriver:GetBuffTriggerInsideCD(skillId, buffType, triggerActionType)
	if nil == self.buffTriggerInsideCD[tostring(skillId)] then
		return nil
	else
		return self.buffTriggerInsideCD[tostring(skillId)][buffType]
	end

	-- TODO --
	-- 暂时不考虑以触发行为类型分类
	-- if nil == self.buffTriggerInsideCD[tostring(skillId)] then
	-- 	return nil
	-- end
	-- if nil == self.buffTriggerInsideCD[tostring(skillId)][buffType] then
	-- 	return nil
	-- end
	-- return self.buffTriggerInsideCD[tostring(skillId)][buffType][triggerActionType]
	-- TODO --
end
--[[
根据delta刷新一次内置cd
@params delta number 差值
--]]
function BaseBuffDriver:UpdateBuffTriggerInsideCD(delta)
	for skillId_, buffs in pairs(self.buffTriggerInsideCD) do
		for buffType, cd in pairs(buffs) do
			if 0 < cd then
				self.buffTriggerInsideCD[skillId_][buffType] = math.max(0, cd - delta)
			end
		end
	end

	-- TODO --
	-- 暂时不考虑以触发行为类型分类
	-- for skillId_, buffs in pairs(self.buffTriggerInsideCD) do
	-- 	for buffType, triggerActions in pairs(buffs) do
	-- 		for triggerActionType, cd in pairs(triggerActions) do
	-- 			self.buffTriggerInsideCD[skillId_][buffType][triggerActionType] = math.max(0, cd - delta)
	-- 		end
	-- 	end
	-- end
	-- TODO --
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return BaseBuffDriver

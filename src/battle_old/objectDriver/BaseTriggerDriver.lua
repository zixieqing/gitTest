--[[
触发驱动基类
@params table {
	owner BaseObject 挂载的战斗物体
}
--]]
local BaseActionDriver = __Require('battle.objectDriver.BaseActionDriver')
local BaseTriggerDriver = class('BaseAttackDriver', BaseTriggerDriver)

------------ import ------------
------------ import ------------

------------ define ------------
------------ define ------------

--[[
@override
constructor
--]]
function BaseTriggerDriver:ctor( ... )
	BaseActionDriver.ctor(self, ...)

	self:Init()
end

---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
@override
初始化逻辑
--]]
function BaseTriggerDriver:Init()
	self:InitObjTriggers()
end
--[[
初始化物体触发器
--]]
function BaseTriggerDriver:InitObjTriggers()
	self.triggers = {
		idx = {},
		id = {}
	}
	for k,v in pairs(ConfigObjectTriggerActionType) do
		if ConfigObjectTriggerActionType.BASE ~= v then
			self.triggers.idx[v] = {}
		end
	end
end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- logic end --
---------------------------------------------------
--[[
@override
是否能进行动作
--]]
function BaseTriggerDriver:CanDoAction()

end
--[[
@override
进入动作
@params triggerType ConfigObjectTriggerActionType 触发类型
@params ... 变长参数
--]]
function BaseTriggerDriver:OnActionEnter(triggerType, ...)
	local triggers = self:GetTriggersByTriggerType(triggerType)
	
	if nil ~= triggers then
		for i = #triggers, 1, -1 do
			triggers[i]:OnTriggerEnter(...)
		end
	end

	self:OnActionExit()
end
--[[
@override
结束动作
--]]
function BaseTriggerDriver:OnActionExit()

end
--[[
@override
动作进行中
@params dt number delta time
--]]
function BaseTriggerDriver:OnActionUpdate(dt)

end
--[[
@override
动作被打断
--]]
function BaseTriggerDriver:OnActionBreak()
	
end
--[[
@override
消耗做出行为需要的资源
--]]
function BaseTriggerDriver:CostActionResources()

end
---------------------------------------------------
-- logic end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
添加一个触发器
@params trigger BaseTrigger
--]]
function BaseTriggerDriver:AddATrigger(trigger)
	table.insert(self.triggers.idx[trigger:GetTriggerType()], 1, trigger)
	self.triggers.id[tostring(trigger:GetTriggerTag())] = trigger
end
--[[
移除一个触发器
@params tag int 触发器tag
--]]
function BaseTriggerDriver:RemoveATrigger(tag)
	local trigger = self:GetATriggerByTag(tag)
	if nil ~= trigger then
		local triggers = self.triggers.idx[trigger:GetTriggerType()]
		for i = #triggers, 1, -1 do
			if tag == triggers[i]:GetTriggerTag() then
				table.remove(triggers, i)
				self.triggers.id[tostring(tag)] = nil
				break
			end
		end
	end
end
--[[
根据tag获取一个触发器
@params tag int 触发器tag
--]]
function BaseTriggerDriver:GetATriggerByTag(tag)
	return self.triggers.id[tostring(tag)]
end
--[[
根据类型获取所有该类型的触发器
@params triggerType ConfigObjectTriggerActionType 触发类型
@return _ list
--]]
function BaseTriggerDriver:GetTriggersByTriggerType(triggerType)
	return self.triggers.idx[triggerType]
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return BaseTriggerDriver

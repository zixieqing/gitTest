--[[
触发器基类
@params args ObjectTriggerConstructorStruct 触发器信息
--]]
local BaseTrigger = class('BaseTrigger')

------------ import ------------
------------ import ------------

------------ define ------------
------------ define ------------

--[[
constructor
--]]
function BaseTrigger:ctor( ... )
	local args = unpack({...})

	self.triggerInfo = args

	self:Init()
end

---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
初始化
--]]
function BaseTrigger:Init()

end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- logic begin --
---------------------------------------------------
--[[
触发事件
@params params ObjectTriggerParameterStruct 触发传参
--]]
function BaseTrigger:OnTriggerEnter(params)
	self:Trigger(params)
	self:OnTriggerExit()
end
--[[
触发
@params params ObjectTriggerParameterStruct 触发传参
--]]
function BaseTrigger:Trigger(params)
	if nil ~= self.triggerInfo.triggerCallback then
		self.triggerInfo.triggerCallback(self:GetTriggerType(), params)
	end
end
--[[
触发事件结束
--]]
function BaseTrigger:OnTriggerExit()

end
--[[
销毁
--]]
function BaseTrigger:Destroy()

end
---------------------------------------------------
-- logic end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
获取tag
--]]
function BaseTrigger:GetTriggerTag()
	return self.triggerInfo.tag
end
--[[
获取触发器类型
--]]
function BaseTrigger:GetTriggerType()
	return self.triggerInfo.triggerType
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return BaseTrigger

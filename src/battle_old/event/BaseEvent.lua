--[[
战斗触发事件基类
@params table {
	owner 宿主
}
--]]
local BaseEvent = class('BaseEvent')
--[[
constructor
--]]
function BaseEvent:ctor( ... )
	local args = unpack({...})

	self.owner = args.owner

	self:Init()
end
---------------------------------------------------
-- init logic begin --
---------------------------------------------------
--[[
init
--]]
function BaseEvent:Init()
	-- 是否在事件中
	self.isInEvent = false
end
---------------------------------------------------
-- init logic end --
---------------------------------------------------

---------------------------------------------------
-- control logic begin --
---------------------------------------------------
--[[
进入事件
--]]
function BaseEvent:OnEventEnter()

end
--[[
结束事件
--]]
function BaseEvent:OnEventExit()

end
--[[
刷新事件
--]]
function BaseEvent:OnEventUpdate()

end
--[[
意外中断事件
--]]
function BaseEvent:OnEventBreak()

end
---------------------------------------------------
-- control logic end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
获取战斗物体
--]]
function BaseEvent:GetOwner()
	return self.owner
end
--[[
是否在事件中
--]]
function BaseEvent:IsInEvent()
	return self.isInEvent
end
--[[
设置事件标识
--]]
function BaseEvent:SetIsInEvent(b)
	self.isInEvent = b
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return BaseEvent

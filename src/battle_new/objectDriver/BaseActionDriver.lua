--[[
行为驱动 抽象类
@params table {
	owner BaseObject 挂载的战斗物体
}
--]]
local BaseActionDriver = class('BaseActionDriver')
--[[
constructor
--]]
function BaseActionDriver:ctor( ... )
	local args = unpack({...})
	self.owner = args.owner
	self.actionTrigger = nil -- 行为触发器
end
---------------------------------------------------
-- init logic begin --
---------------------------------------------------
--[[
初始化逻辑
--]]
function BaseActionDriver:Init()

end
---------------------------------------------------
-- init logic end --
---------------------------------------------------

---------------------------------------------------
-- control logic begin --
---------------------------------------------------
--[[
是否能进行动作
--]]
function BaseActionDriver:CanDoAction()

end
--[[
进入动作
--]]
function BaseActionDriver:OnActionEnter()

end
--[[
结束动作
--]]
function BaseActionDriver:OnActionExit()

end
--[[
动作进行中
@params dt number delta time
--]]
function BaseActionDriver:OnActionUpdate(dt)

end
--[[
动作被打断
--]]
function BaseActionDriver:OnActionBreak()
	
end
--[[
消耗做出行为需要的资源
--]]
function BaseActionDriver:CostActionResources()

end
--[[
刷新触发器
--]]
function BaseActionDriver:UpdateActionTrigger()

end
--[[
重置所有触发器
--]]
function BaseActionDriver:ResetActionTrigger()

end
--[[
操作触发器
--]]
function BaseActionDriver:GetActionTrigger()

end
function BaseActionDriver:SetActionTrigger()
	
end
---------------------------------------------------
-- control logic end --
---------------------------------------------------

---------------------------------------------------
-- handler logic begin --
---------------------------------------------------
--[[
spine动画事件消息处理
--]]
function BaseActionDriver:SpineAnimationEventHandler(event)

end
--[[
spine动画自定义事件消息处理
--]]
function BaseActionDriver:SpineCustomEventHandler(event)

end
---------------------------------------------------
-- handler logic end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
获取战斗物体
--]]
function BaseActionDriver:GetOwner()
	-- assert(nil ~= self.owner, "ActionDriver must have owner")
	return self.owner
end
--[[
获取战斗物体动画本体
--]]
function BaseActionDriver:GetOwnerAvatar()
	return self:GetOwner():getSpineAvatar()
end
---------------------------------------------------
-- get set end --
---------------------------------------------------


return BaseActionDriver

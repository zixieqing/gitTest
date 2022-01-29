---@meta


---@class CWidgetWindow : cc.Node
local CWidgetWindow = {}


--- create and init default
---@return CWidgetWindow
function CWidgetWindow:create()
end

--- init default
function CWidgetWindow:init()
end


--- set modalable for window
---@param modalable boolean
function CWidgetWindow:setModalable(modalable)
end


--- is modalable
function CWidgetWindow:isModalable()
end


--- set touch enabled, if false it is not going to handle event
---@param isTouchEnabled boolean
function CWidgetWindow:setTouchEnabled(isTouchEnabled)
end


--- is touch enabled
---@return boolean
function CWidgetWindow:isTouchEnabled()
end


--- set multi touch enabeld
---@param isEnabled boolean
function CWidgetWindow:setMultiTouchEnabled(isEnabled)
end


--- is multi touch enabled
---@return boolean
function CWidgetWindow:isMultiTouchEnabled()
end


--- set touch priority from widget tree root
---@param touchPriority integer
function CWidgetWindow:setTouchPriority(touchPriority)
end


--- get touch priority, default is 0
---@return integer
function CWidgetWindow:getTouchPriority()
end


---@param touchArea cc.rect
function CWidgetWindow:setTouchArea(touchArea)
end


---@param isTouchAreaEnabled boolean
function CWidgetWindow:setTouchAreaEnabled(isTouchAreaEnabled)
end


---@param handler fun(sender:cc.Ref, touch:cc.Touch, duration:number):void
function CWidgetWindow:setOnTouchEndedAfterLongClickScriptHandler(handler)
end


---@param handler fun(sender:cc.Ref, touch:cc.Touch, duration:number):void
function CWidgetWindow:setOnTouchMovedAfterLongClickScriptHandler(handler)
end


---@param handler fun(sender:cc.Ref, touch:cc.Touch, duration:number):void
function CWidgetWindow:setOnTouchCancelledAfterLongClickScriptHandler(handler)
end


function CWidgetWindow:removeOnTouchMovedAfterLongClickScriptHandler()
end


function CWidgetWindow:removeOnTouchEndedAfterLongClickScriptHandler()
end


function CWidgetWindow:removeOnTouchCancelledAfterLongClickScriptHandler()
end


---@param sender cc.Ref
---@param touch cc.Touch
---@param duration? number
function CWidgetWindow:executeTouchEndedAfterLongClickHandler(sender, touch, duration)
end


---@param sender cc.Ref
---@param touch cc.Touch
---@param duration? number
function CWidgetWindow:executeTouchMovedAfterLongClickHandler(sender, touch, duration)
end


---@param sender cc.Ref
---@param touch cc.Touch
---@param duration? number
function CWidgetWindow:executeTouchCancelledAfterLongClickHandler(sender, touch, duration)
end

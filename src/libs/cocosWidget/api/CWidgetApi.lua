---@meta


---@class CWidget
local CWidget = {}


---@return CWidget
function CWidget:new()
end


--- set widget id
---@param id string
function CWidget:setId(id)
end


--- get widget id
---@return string
function CWidget:getId()
end


--- set user tag
---@param tag integer
function CWidget:setUserTag(tag)
end


--- get user tag, it's not relationship with tag
---@return integer
function CWidget:getUserTag()
end


--- set description for widget
---@param description string
function CWidget:setDescription(description)
end


--- get description of widget
---@return string
function CWidget:getDescription()
end


--- set enabled
---@param isEnabled boolean
function CWidget:setEnabled(isEnabled)
end


--- is widget enabled ? if not, this widget is not going to handle touch event
---@return boolean
function CWidget:isEnabled()
end


--- is touch interruptted
---@return boolean
function CWidget:isTouchInterrupted()
end


--- interrupt this widget's touch event and call on touch cancelled immediately
---@param touch cc.Touch
---@param duration number
function CWidget:interruptTouch(touch, duration)
end


--- interrupt touch event on this widget and beginning interrupt
---@param touch cc.Touch
---@param duration number
function CWidget:interruptTouchCascade(touch, duration)
end


---@param widget cc.Node
---@param id integer
function CWidget:setLongClickTouchHandlerWidget(widget, id)
end


--- set touch enabled
---@param isTouchEnabled boolean
function CWidget:setTouchEnabled(isTouchEnabled)
end


--- is widget touch enabled ? if not, this widget is not going to handle touch event
---@return boolean
function CWidget:isTouchEnabled()
end


--- for child the custom impl
---@param touch cc.Touch
---@return ccw.WIDGET_TOUCH_MODEL
function CWidget:onTouchBegan(touch)
end


--- set on touch began listener
---@param handler fun(sender:cc.Ref, touch:cc.Touch):ccw.WIDGET_TOUCH_MODEL
function CWidget:setOnTouchBeganScriptHandler(handler)
end


function CWidget:removeOnTouchBeganScriptHandler()
end


--- execute touch began handler, it will call listener's hanlder first, next it will call onTouchBegan
---@param touch cc.Touch
function CWidget:executeTouchBeganHandler(touch)
end


--- for child the custom impl
---@param touch cc.Touch
---@param duration number
function CWidget:onTouchMoved(touch, duration)
end


--- set on touch moved listener
---@param handler fun(sender:cc.Ref, touch:cc.Touch, duration:number):boolean
function CWidget:setOnTouchMovedScriptHandler(handler)
end


function CWidget:removeOnTouchMovedScriptHandler()
end


--- execute touch moved handle
---@param touch cc.Touch
---@param duration number
function CWidget:executeTouchMovedHandler(touch, duration)
end


--- for child the custom impl
---@param touch cc.Touch
---@param duration number
function CWidget:onTouchEnded(touch, duration)
end


--- set on touch ended listener
---@param handler fun(sender:cc.Ref, touch:cc.Touch, duration:number):boolean
function CWidget:setOnTouchEndedScriptHandler(handler)
end


function CWidget:removeOnTouchEndedScriptHandler()
end


--- execute touch ended handle
---@param touch cc.Touch
---@param duration number
function CWidget:executeTouchEndedHandler(touch, duration)
end


--- for child the custom impl
---@param touch cc.Touch
---@param duration number
function CWidget:onTouchCancelled(touch, duration)
end


--- set on touch cancelled listener
---@param handler fun(sender:cc.Ref, touch:cc.Touch, duration:number):boolean
function CWidget:setOnTouchCancelledScriptHandler(handler)
end


function CWidget:removeOnTouchCancelledScriptHandler()
end


--- execute touch cancelled handle
---@param touch cc.Touch
---@param duration number
function CWidget:executeTouchCancelledHandler(touch, duration)
end

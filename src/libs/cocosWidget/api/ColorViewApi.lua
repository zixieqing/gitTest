---@meta


---@class CColorView : cc.Node
local CColorView = {}


---@param color? cc.c4b
---@return CColorView
function CColorView:create(color)
end


---@return boolean
function CColorView:init()
end


---@param color cc.c4b
---@return boolean
function CColorView:initWithColor(color)
end


---@param contentSize cc.size
function CColorView:setContentSize(contentSize)
end


---@param color cc.c3b
function CColorView:setColor(color)
end


---@return cc.c3b
function CColorView:getColor()
end


---@param opacity integer @ vlaue range 0~255
function CColorView:setOpacity(opacity)
end


---@return integer
function CColorView:getOpacity()
end


---@param tag integer
function CColorView:setUserTag(tag)
end


---@return integer
function CColorView:getUserTag()
end


---@param isModify boolean
function CColorView:setOpacityModifyRGB(isModify)
end


---@return boolean
function CColorView:isOpacityModifyRGB()
end


---@param isEnabled boolean
function CColorView:setCascadeColorEnabled(isEnabled)
end


---@return boolean
function CColorView:isCascadeColorEnabled()
end


---@param isEnabled boolean
function CColorView:setCascadeOpacityEnabled(isEnabled)
end


---@return boolean
function CColorView:isCascadeOpacityEnabled()
end


---@param isTouchEnabled boolean
function CColorView:setTouchEnabled(isTouchEnabled)
end


---@param blendFunc cc.blendFunc
function CColorView:setBlendFunc(blendFunc)
end


---@return cc.blendFunc
function CColorView:getBlendFunc()
end


---@param parentColor cc.c3b
function CColorView:updateDisplayedColor(parentColor)
end


---@return cc.c3b
function CColorView:getDisplayedColor()
end


---@param parentOpacity integer @ value range 0~255
function CColorView:updateDisplayedOpacity(parentOpacity)
end


---@return integer
function CColorView:getDisplayedOpacity()
end


---@param renderer cc.Renderer
---@param transform cc.mat4
---@param flags integer
function CColorView:draw(renderer, transform, flags)
end


---@param touch cc.Touch
---@return ccw.WIDGET_TOUCH_MODEL
function CColorView:onTouchBegan(touch)
end


---@param handler fun(sender:cc.Ref, touch:cc.Touch):ccw.WIDGET_TOUCH_MODEL
function CColorView:setOnTouchBeganScriptHandler(handler)
end


---@param touch cc.Touch
---@param duration number
function CColorView:onTouchMoved(touch, duration)
end


---@param handler fun(sender:cc.Ref, touch:cc.Touch, duration:number):boolean
function CColorView:setOnTouchMovedScriptHandler(handler)
end


---@param touch cc.Touch
---@param duration number
function CColorView:onTouchEnded(touch, duration)
end


---@param handler fun(sender:cc.Ref, touch:cc.Touch, duration:number):boolean
function CColorView:setOnTouchEndedScriptHandler(handler)
end


---@param touch cc.Touch
---@param duration number
function CColorView:onTouchCancelled(touch, duration)
end


--- set on touch cancelled listener
---@param handler fun(sender:cc.Ref, touch:cc.Touch, duration:number):boolean
function CColorView:setOnTouchCancelledScriptHandler(handler)
end


---@param handler fun(sender:cc.Ref):void
function CColorView:setOnClickScriptHandler(handler)
end


---@param handler fun(sender:cc.Ref, touch:cc.Touch):boolean
function CColorView:setOnLongClickScriptHandler(handler)
end

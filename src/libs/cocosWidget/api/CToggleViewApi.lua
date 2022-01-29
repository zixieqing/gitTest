---@meta


---@class CToggleView : CButton
local CToggleView = {}


---@param normal? string
---@param selected? string
---@param disabled? string
---@return CToggleView
function CToggleView:create(normal, selected, disabled)
end


---@param size cc.size
---@param normal string
---@param selected? string
---@param disabled? string
---@return CToggleView
function CToggleView:createWith9Sprite(size, normal, selected, disabled)
end


---@param isChecked boolean
function CToggleView:setChecked(isChecked)
end


---@return boolean
function CToggleView:isChecked()
end


---@param tag integer
function CToggleView:setUserTag(tag)
end


---@return integer
function CToggleView:getUserTag()
end


---@param isEnabled boolean
function CToggleView:setEnabled(isEnabled)
end


---@param isTouchEnabled boolean
function CToggleView:setTouchEnabled(isTouchEnabled)
end


---@param isEnabled boolean
---@param padding? cc.size @ default is cc.size(50,30)
function CToggleView:setCascadeTextSizeEnabled(isEnabled, padding)
end


---@param touch cc.Touch
---@return ccw.WIDGET_TOUCH_MODEL
function CToggleView:onTouchBegan(touch)
end


---@param touch cc.Touch
---@param duration number
function CToggleView:onTouchMoved(touch, duration)
end


---@param touch cc.Touch
---@param duration number
function CToggleView:onTouchEnded(touch, duration)
end


---@param touch cc.Touch
---@param duration number
function CToggleView:onTouchCancelled(touch, duration)
end


---@param handler fun(sender:cc.Ref):void
function CToggleView:setOnClickScriptHandler(handler)
end


---@param handler fun(sender:cc.Ref, isChecked:boolean):void
function CToggleView:setOnCheckScriptHandler(handler)
end

---@meta


---@class CLabel : cc.Label
local CLabel = {}


---@return CLabel
function CLabel:create()
end


---@param text string
---@param fontFile string
---@param fontSize number
---@param dimensions? cc.size
---@param hAlignment? integer 
---|>cc.TEXT_ALIGNMENT_CENTER 
---| cc.TEXT_ALIGNMENT_LEFT 
---| cc.TEXT_ALIGNMENT_RIGHT
---@param vAlignment? integer 
---| cc.VERTICAL_TEXT_ALIGNMENT_CENTER 
---| cc.VERTICAL_TEXT_ALIGNMENT_BOTTOM 
---|>cc.VERTICAL_TEXT_ALIGNMENT_TOP
function CLabel:createWithSystemFont(text, fontFile, fontSize, dimensions, hAlignment, vAlignment)
end


---@param text string
---@param fontFile string
---@param fontSize number
---@param dimensions? cc.size
---@param hAlignment? integer 
---|>cc.TEXT_ALIGNMENT_CENTER 
---| cc.TEXT_ALIGNMENT_LEFT 
---| cc.TEXT_ALIGNMENT_RIGHT
---@param vAlignment? integer 
---| cc.VERTICAL_TEXT_ALIGNMENT_CENTER 
---| cc.VERTICAL_TEXT_ALIGNMENT_BOTTOM 
---|>cc.VERTICAL_TEXT_ALIGNMENT_TOP
function CLabel:createWithTTF(text, fontFile, fontSize, dimensions, hAlignment, vAlignment)
end


---@param isUnderLine boolean
function CLabel:setUnderLine(isUnderLine)
end


---@return boolean
function CLabel:getUnderLine()
end


---@param isMiddleLine boolean
function CLabel:setMiddleLine(isMiddleLine)
end


---@return boolean
function CLabel:getMiddleLine()
end


---@param isLine boolean
function CLabel:setIsSolidLine(isLine)
end


---@param isDetla boolean
function CLabel:setDrawSegmentDelta(isDetla)
end


---@param height number
function CLabel:setDrawLineHeight(height)
end


---@param color cc.c4f
function CLabel:setDrawLineColor(color)
end


---@param tag integer
function CLabel:setUserTag(tag)
end


---@return integer
function CLabel:getUserTag()
end


---@param isTouchEnabled boolean
function CLabel:setTouchEnabled(isTouchEnabled)
end


---@param renderer cc.Renderer
---@param transform cc.mat4
---@param flags integer
function CLabel:draw(renderer, transform, flags)
end


---@param touch cc.Touch
---@return ccw.WIDGET_TOUCH_MODEL
function CLabel:onTouchBegan(touch)
end


---@param touch cc.Touch
---@param duration number
function CLabel:onTouchMoved(touch, duration)
end


---@param touch cc.Touch
---@param duration number
function CLabel:onTouchEnded(touch, duration)
end


---@param touch cc.Touch
---@param duration number
function CLabel:onTouchCancelled(touch, duration)
end


---@param handler fun(sender:cc.Ref):void
function CLabel:setOnClickScriptHandler(handler)
end


---@param handler fun(sender:cc.Ref, touch:cc.Touch):void
function CLabel:setOnLongClickScriptHandler(handler)
end

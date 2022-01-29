---@meta


---@class CLabelBMFont : cc.Label
local CLabelBMFont = {}


---@param text? string
---@param bmfontFile? string
---@param alignment? integer 
---| cc.TEXT_ALIGNMENT_CENTER
---|>cc.TEXT_ALIGNMENT_LEFT
---| cc.TEXT_ALIGNMENT_RIGHT
---@param maxLineWidth? integer @ default is 0
---@param imageOffset? cc.p @ default is cc.p(0,0)
---@return CLabelBMFont
function CLabelBMFont:create(text, bmfontFile, alignment, maxLineWidth, imageOffset)
end


---@return boolean
function CLabelBMFont:init()
end


---@param touch cc.Touch
---@return ccw.WIDGET_TOUCH_MODEL
function CLabelBMFont:onTouchBegan(touch)
end


---@param touch cc.Touch
---@param duration number
function CLabelBMFont:onTouchMoved(touch, duration)
end


---@param touch cc.Touch
---@param duration number
function CLabelBMFont:onTouchEnded(touch, duration)
end


---@param touch cc.Touch
---@param duration number
function CLabelBMFont:onTouchCancelled(touch, duration)
end


---@param handler fun(sender:cc.Ref):void
function CLabelBMFont:setOnClickScriptHandler(handler)
end


---@param handler fun(sender:cc.Ref, touch:cc.Touch):void
function CLabelBMFont:setOnLongClickScriptHandler(handler)
end

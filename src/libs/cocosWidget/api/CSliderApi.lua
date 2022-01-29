---@meta


---@class CSlider : CProgressBar
local CSlider = {}


---@param slider? string
---@param progress? string
---@return CSlider
function CSlider:create(slider, progress)
end


---@param slider string
---@param progress string
---@return boolean
function CSlider:initWithSlider(slider, progress)
end


---@param value integer
function CSlider:setValue(value)
end


---@param file string
function CSlider:setSliderImage(file)
end


---@param texture cc.Texture2D
function CSlider:setSliderTexture(texture)
end


---@param frame cc.SpriteFrame
function CSlider:setSliderSpriteFrame(frame)
end


---@param frameName string
function CSlider:setSliderSpriteFrameName(frameName)
end


---@param contentSize cc.size
function CSlider:setContentSize(contentSize)
end


---@param touch cc.Touch
---@return ccw.WIDGET_TOUCH_MODEL
function CSlider:onTouchBegan(touch)
end


---@param touch cc.Touch
---@param duration number
function CSlider:onTouchMoved(touch, duration)
end


---@param touch cc.Touch
---@param duration number
function CSlider:onTouchEnded(touch, duration)
end


---@param touch cc.Touch
---@param duration number
function CSlider:onTouchCancelled(touch, duration)
end


---@param handler fun(sender:cc.Ref, value:integer):void
function CSlider:setOnValueChangedScriptHandler(handler)
end

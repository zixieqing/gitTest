---@meta


---@class CProgressBar : cc.Node
local CProgressBar = {}


---@param progress? string
---@return CProgressBar
function CProgressBar:create(progress)
end


---@return boolean
function CProgressBar:init()
end


---@param progress string
function CProgressBar:initWithFile(progress)
end


---@param text string
---@param fontFile string
---@param fontSize number
---@param dimensions cc.size
---@param color cc.c3b
function CProgressBar:initText(text, fontFile, fontSize, dimensions, color)
end


---@return CLabel
function CProgressBar:getLabel()
end


---@param labelFormat ccw.PROGRESS_BAR_LABEL_FORMAT
function CProgressBar:setLabelFormat(labelFormat)
end


---@return ccw.PROGRESS_BAR_LABEL_FORMAT
function CProgressBar:getLabelFormat()
end


---@param isShowLabel boolean
function CProgressBar:setShowValueLabel(isShowLabel)
end


---@param direction ccw.PROGRESS_BAR_DIRECTION
function CProgressBar:setDirection(direction)
end


---@return ccw.PROGRESS_BAR_DIRECTION
function CProgressBar:getDirection()
end


---@param value integer
function CProgressBar:setValue(value)
end


---@return integer
function CProgressBar:getValue()
end


---@param minValue integer
function CProgressBar:setMinValue(minValue)
end


---@return integer
function CProgressBar:getMinValue()
end


---@param maxValue integer
function CProgressBar:setMaxValue(maxValue)
end


---@return integer
function CProgressBar:getMaxValue()
end


---@param file string
function CProgressBar:setProgressImage(file)
end


---@param texture cc.Texture2D
function CProgressBar:setProgressTexture(texture)
end


---@param frame cc.SpriteFrame
function CProgressBar:setProgressSpriteFrame(frame)
end


---@param spriteFrame string
function CProgressBar:setProgressSpriteFrameName(spriteFrame)
end


---@param color cc.c4b
function CProgressBar:setBackgroundColor(color)
end


function CProgressBar:removeBackgroundColor()
end


---@param startColor cc.c4b
---@param endColor cc.c4b
---@param vector cc.p
function CProgressBar:setBackgroundGradient(startColor, endColor, Vector)
end


function CProgressBar:removeBackgroundGradient()
end


---@param opacity integer @ value range 0~255
function CProgressBar:setBackgroundOpacity(opacity)
end


---@param file string
function CProgressBar:setBackgroundImage(file)
end


---@param texture cc.Texture2D
function CProgressBar:setBackgroundTexture(texture)
end


---@param spriteFrame cc.SpriteFrame
function CProgressBar:setBackgroundSpriteFrame(spriteFrame)
end


---@param frameName string
function CProgressBar:setBackgroundSpriteFrameName(frameName)
end


---@return cc.Sprite
function CProgressBar:getBackgroundImage()
end


function CProgressBar:removeBackgroundImage()
end


---@param size cc.size
function CProgressBar:setContentSize(size)
end


---@param value integer
---@param duration number
function CProgressBar:startProgress(value, duration)
end


---@param fromValue integer
---@param toValue integer
---@param duration number
function CProgressBar:startProgressFromTo(fromValue, toValue, duration)
end


---@return number
function CProgressBar:getPercentage()
end


function CProgressBar:stopProgress()
end


---@return boolean
function CProgressBar:isProgressEnded()
end


---@param handler fun(sender:cc.Ref, value:integer):void
function CProgressBar:setOnValueChangedScriptHandler(handler)
end


---@param handler fun(sender:cc.Ref):void
function CProgressBar:setOnProgressEndedScriptHandler(handler)
end

---@meta


---@class CLayout : cc.Node
local CLayout = {}


---@param contentSize? cc.size
---@return CLayout
function CLayout:create(contentSize)
end


---@return boolean
function CLayout:init()
end


---@param contentSize cc.size
function CLayout:setContentSize(contentSize)
end


--- set user tag
---@param tag integer
function CLayout:setUserTag(tag)
end


--- get user tag, it's not relationship with tag
---@return integer
function CLayout:getUserTag()
end


---@param color cc.c4b
function CLayout:setBackgroundColor(color)
end


function CLayout:removeBackgroundColor()
end


---@param startColor cc.c4b
---@param endColor cc.c4b
---@param vector cc.p
function CLayout:setBackgroundGradient(startColor, endColor, Vector)
end


function CLayout:removeBackgroundGradient()
end


---@param opacity integer @ value range 0~255
function CLayout:setBackgroundOpacity(opacity)
end


---@param file string
function CLayout:setBackgroundImage(file)
end


---@param texture cc.Texture2D
function CLayout:setBackgroundTexture(texture)
end


---@param spriteFrame cc.SpriteFrame
function CLayout:setBackgroundSpriteFrame(spriteFrame)
end


---@param frameName string
function CLayout:setBackgroundSpriteFrameName(frameName)
end


---@return cc.Sprite
function CLayout:getBackgroundImage()
end


function CLayout:removeBackgroundImage()
end


--- find the first matching widget by id
---@param id string
---@return cc.Ref
function CLayout:findWidgetById(id)
end


--- for child the custom impl
---@param touch cc.Touch
---@return ccw.WIDGET_TOUCH_MODEL
function CLayout:onTouchBegan(touch)
end


--- set on touch began listener
---@param handler fun(sender:cc.Ref, touch:cc.Touch):ccw.WIDGET_TOUCH_MODEL
function CLayout:setOnTouchBeganScriptHandler(handler)
end


--- for child the custom impl
---@param touch cc.Touch
---@param duration number
function CLayout:onTouchMoved(touch, duration)
end


--- set on touch moved listener
---@param handler fun(sender:cc.Ref, touch:cc.Touch, duration:number):boolean
function CLayout:setOnTouchMovedScriptHandler(handler)
end


--- for child the custom impl
---@param touch cc.Touch
---@param duration number
function CLayout:onTouchEnded(touch, duration)
end


--- set on touch ended listener
---@param handler fun(sender:cc.Ref, touch:cc.Touch, duration:number):boolean
function CLayout:setOnTouchEndedScriptHandler(handler)
end


--- for child the custom impl
---@param touch cc.Touch
---@param duration number
function CLayout:onTouchCancelled(touch, duration)
end


--- set on touch cancelled listener
---@param handler fun(sender:cc.Ref, touch:cc.Touch, duration:number):boolean
function CLayout:setOnTouchCancelledScriptHandler(handler)
end

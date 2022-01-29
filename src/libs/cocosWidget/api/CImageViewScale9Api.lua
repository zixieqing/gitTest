---@meta


---@class CImageViewScale9 : CScale9Sprite
local CImageViewScale9 = {}


---@param file? string
---@param rect? cc.rect
---@return CImageViewScale9
function CImageViewScale9:create(file, rect)
end


---@param texture cc.Texture2D
---@param rect? cc.rect
---@return CImageViewScale9
function CImageViewScale9:createWithTexture(texture, rect)
end


---@param frame cc.SpriteFrame
---@return CImageViewScale9
function CImageViewScale9:createWithSpriteFrame(frame)
end


---@param frameName string
---@return CImageViewScale9
function CImageViewScale9:createWithSpriteFrameName(frameName)
end


---@return boolean
function CImageViewScale9:init()
end


---@param tag integer
function CImageViewScale9:setUserTag(tag)
end


---@return integer
function CImageViewScale9:getUserTag()
end


---@param isTouchEnabled boolean
function CImageViewScale9:setTouchEnabled(isTouchEnabled)
end


---@return boolean
function CImageViewScale9:isTouchEnabled()
end


---@param touch cc.Touch
---@return ccw.WIDGET_TOUCH_MODEL
function CImageViewScale9:onTouchBegan(touch)
end


---@param touch cc.Touch
---@param duration number
function CImageViewScale9:onTouchMoved(touch, duration)
end


---@param touch cc.Touch
---@param duration number
function CImageViewScale9:onTouchEnded(touch, duration)
end


---@param touch cc.Touch
---@param duration number
function CImageViewScale9:onTouchCancelled(touch, duration)
end


---@param handler fun(sender:cc.Ref):void
function CImageViewScale9:setOnClickScriptHandler(handler)
end


---@param handler fun(sender:cc.Ref, touch:cc.Touch):void
function CImageViewScale9:setOnLongClickScriptHandler(handler)
end

---@meta


---@class CImageView : cc.Sprite
local CImageView = {}


---@param file? string
---@param rect? cc.rect
---@return CImageView
function CImageView:create(file, rect)
end


---@param texture cc.Texture2D
---@param rect? cc.rect
---@return CImageView
function CImageView:createWithTexture(texture, rect)
end


---@param frame cc.SpriteFrame
---@return CImageView
function CImageView:createWithSpriteFrame(frame)
end


---@param frameName string
---@return CImageView
function CImageView:createWithSpriteFrameName(frameName)
end


---@return boolean
function CImageView:init()
end


---@param tag integer
function CImageView:setUserTag(tag)
end


---@return integer
function CImageView:getUserTag()
end


---@param isEnabled boolean
function CImageView:setEnabled(isEnabled)
end


---@param isTouchEnabled boolean
function CImageView:setTouchEnabled(isTouchEnabled)
end


---@param touch cc.Touch
---@return ccw.WIDGET_TOUCH_MODEL
function CImageView:onTouchBegan(touch)
end


---@param touch cc.Touch
---@param duration number
function CImageView:onTouchMoved(touch, duration)
end


---@param touch cc.Touch
---@param duration number
function CImageView:onTouchEnded(touch, duration)
end


---@param touch cc.Touch
---@param duration number
function CImageView:onTouchCancelled(touch, duration)
end


---@param handler fun(sender:cc.Ref):void
function CImageView:setOnClickScriptHandler(handler)
end


---@param handler fun(sender:cc.Ref, touch:cc.Touch):void
function CImageView:setOnLongClickScriptHandler(handler)
end

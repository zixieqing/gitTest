---@meta


---@class CCheckBox : cc.Node
local CCheckBox = {}


---@return CCheckBox
function CCheckBox:create()
end


---@return boolean
function CCheckBox:init()
end


---@param file string
function CCheckBox:setNormalImage(file)
end


---@param texture cc.Texture2D
function CCheckBox:setNormalTexture(texture)
end


---@param frame cc.SpriteFrame
function CCheckBox:setNormalSpriteFrame(frame)
end


---@param frameName string
function CCheckBox:setNormalSpriteFrameName(frameName)
end


---@param file string
function CCheckBox:setNormalPressImage(file)
end


---@param texture cc.Texture2D
function CCheckBox:setNormalPressTexture(texture)
end


---@param frame cc.SpriteFrame
function CCheckBox:setNormalPressSpriteFrame(frame)
end


---@param frameName string
function CCheckBox:setNormalPressSpriteFrameName(frameName)
end


---@param file string
function CCheckBox:setDisabledNormalImage(file)
end


---@param texture cc.Texture2D
function CCheckBox:setDisabledNormalTexture(texture)
end


---@param frame cc.SpriteFrame
function CCheckBox:setDisabledNormalSpriteFrame(frame)
end


---@param frameName string
function CCheckBox:setDisabledNormalSpriteFrameName(frameName)
end


---@param file string
function CCheckBox:setDisabledCheckedImage(file)
end


---@param texture cc.Texture2D
function CCheckBox:setDisabledCheckedTexture(texture)
end


---@param frame cc.SpriteFrame
function CCheckBox:setDisabledCheckedSpriteFrame(frame)
end


---@param frameName string
function CCheckBox:setDisabledCheckedSpriteFrameName(frameName)
end


---@param file string
function CCheckBox:setCheckedImage(file)
end


---@param texture cc.Texture2D
function CCheckBox:setCheckedTexture(texture)
end


---@param frame cc.SpriteFrame
function CCheckBox:setCheckedSpriteFrame(frame)
end


---@param frameName string
function CCheckBox:setCheckedSpriteFrameName(frameName)
end


---@param file string
function CCheckBox:setCheckedPressImage(file)
end


---@param texture cc.Texture2D
function CCheckBox:setCheckedPressTexture(texture)
end


---@param frame cc.SpriteFrame
function CCheckBox:setCheckedPressSpriteFrame(frame)
end


---@param frameName string
function CCheckBox:setCheckedPressSpriteFrameName(frameName)
end


---@param isChecked boolean
function CCheckBox:setChecked(isChecked)
end


---@return boolean
function CCheckBox:isChecked()
end


---@param tag integer
function CCheckBox:setUserTag(tag)
end


---@return integer
function CCheckBox:getUserTag()
end


---@param isEnabled boolean
function CCheckBox:setEnabled(isEnabled)
end


---@param contentSize cc.size
function CCheckBox:setContentSize(contentSize)
end


---@param touch cc.Touch
---@return ccw.WIDGET_TOUCH_MODEL
function CCheckBox:onTouchBegan(touch)
end


---@param touch cc.Touch
---@param duration number
function CCheckBox:onTouchMoved(touch, duration)
end


---@param touch cc.Touch
---@param duration number
function CCheckBox:onTouchEnded(touch, duration)
end


---@param touch cc.Touch
---@param duration number
function CCheckBox:onTouchCancelled(touch, duration)
end


---@param handler fun(sender:cc.Ref):void
function CCheckBox:setOnClickScriptHandler(handler)
end


---@param handler fun(sender:cc.Ref, touch:cc.Touch):void
function CCheckBox:setOnLongClickScriptHandler(handler)
end


---@param handler fun(sender:cc.Ref, isChecked:boolean):void
function CCheckBox:setOnCheckScriptHandler(handler)
end

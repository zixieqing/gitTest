---@meta


---@class CButton : cc.Node
local CButton = class('CButton')


---@param normal? string
---@param selected? string
---@param disabled? string
---@return CButton
function CButton:create(normal, selected, disabled)
end


---@param size cc.size
---@param normal string
---@param selected? string
---@param disabled? string
---@return CButton
function CButton:createWith9Sprite(size, normal, selected, disabled)
end


---@param size cc.size
---@param normal string
---@param selected? string
---@param disabled? string
---@return CButton
function CButton:createWith9SpriteFrameName(size, normal, selected, disabled)
end


---@return boolean
function CButton:init()
end


---@param normal string
---@param selected string
---@param disabled string
---@return boolean
function CButton:initWithFile(normal, selected, disabled)
end


---@param size cc.size
---@param normal string
---@param selected string
---@param disabled string
---@return boolean
function CButton:initWith9Sprite(size, normal, selected, disabled)
end


---@param text string
---@param fontFile string
---@param fontSize number
---@param dimensions? cc.size @ default is cc.size(0,0)
---@param color? cc.c3b @ default is cc.WHITE
function CButton:initText(text, fontFile, fontSize, dimensions, color)
end


---@return CLabel
function CButton:getLabel()
end


---@param offset cc.p
function CButton:setLabelOffset(offset)
end


---@param text string
function CButton:setText(text)
end


---@return string
function CButton:getText()
end


---@param file string
function CButton:setNormalImage(file)
end


---@param texture cc.Texture2D
function CButton:setNormalTexture(texture)
end


---@param frame cc.SpriteFrame
function CButton:setNormalSpriteFrame(frame)
end


---@param spriteName string
function CButton:setNormalSpriteFrameName(spriteName)
end


---@return cc.Node
function CButton:getNormalImage()
end


---@param file string
function CButton:setSelectedImage(file)
end


---@param texture cc.Texture2D
function CButton:setSelectedTexture(texture)
end


---@param frame cc.SpriteFrame
function CButton:setSelectedSpriteFrame(frame)
end


---@param spriteName string
function CButton:setSelectedSpriteFrameName(spriteName)
end


---@return cc.Node
function CButton:getSelectedImage()
end


---@param file string
function CButton:setDisabledImage(file)
end


---@param texture cc.Texture2D
function CButton:setDisabledTexture(texture)
end


---@param frame cc.SpriteFrame
function CButton:setDisabledSpriteFrame(frame)
end


---@param spriteName string
function CButton:setDisabledSpriteFrameName(spriteName)
end


---@return cc.Node
function CButton:getDisabledImage()
end


---@param tag integer
function CButton:setUserTag(tag)
end


---@return integer
function CButton:getUserTag()
end


---@param isEnabled boolean
function CButton:setScale9Enabled(isEnabled)
end


---@return boolean
function CButton:isScale9Enabled()
end


---@param isEnabled boolean
function CButton:setEnabled(isEnabled)
end


---@param isTouchEnabled boolean
function CButton:setTouchEnabled(isTouchEnabled)
end


---@param contentSize cc.size
function CButton:setContentSize(contentSize)
end


---@param isEnabled boolean
---@param padding? cc.size @ default is cc.size(50,30)
function CButton:setCascadeTextSizeEnabled(isEnabled, padding)
end


---@param touch cc.Touch
---@return ccw.WIDGET_TOUCH_MODEL
function CButton:onTouchBegan(touch)
end


---@param touch cc.Touch
---@param duration number
function CButton:onTouchMoved(touch, duration)
end


---@param touch cc.Touch
---@param duration number
function CButton:onTouchEnded(touch, duration)
end


---@param touch cc.Touch
---@param duration number
function CButton:onTouchCancelled(touch, duration)
end


---@param handler fun(sender:cc.Ref):void
function CButton:setOnClickScriptHandler(handler)
end


---@param handler fun(sender:cc.Ref, touch:cc.Touch):void
function CButton:setOnLongClickScriptHandler(handler)
end

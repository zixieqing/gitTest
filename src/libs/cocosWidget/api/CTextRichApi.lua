---@meta


---@class CTextRich : cc.Node
local CTextRich = {}


---@return CTextRich
function CTextRich:create()
end


---@return boolean
function CTextRich:init()
end


---@param fontName string
function CTextRich:setFontName(fontName)
end


---@return string
function CTextRich:getFontName()
end


---@param fontSize number
function CTextRich:setFontSize(fontSize)
end


---@return number
function CTextRich:getFontSize()
end


---@param length integer
function CTextRich:setMaxLineLength(length)
end


---@return integer
function CTextRich:getMaxLineLength()
end


---@param spacing number
function CTextRich:setVerticalSpacing(spacing)
end


---@return number
function CTextRich:getVerticalSpacing()
end


---@param string       string
---@param fontName?    string
---@param fontSize?    number
---@param color?       cc.c3b @ default is cc.WHITE
---@param description? string
---@overload fun(node:cc.Node, len:integer, description:string):void
function CTextRich:insertElement(string, fontName, fontSize, color, description)
end


---@param string       string
---@param fontName?    string
---@param fontSize?    number
---@param color?       cc.c3b @ default is cc.WHITE
---@param description? string
function CTextRich:insertElementWithTTF(string, fontName, fontSize, color, description)
end


---@param node         cc.Node
---@param length?      integer
---@param description? string
function CTextRich:removeAllElements(node, length, description)
end


function CTextRich:reloadData()
end


---@param touch cc.Touch
---@return ccw.WIDGET_TOUCH_MODEL
function CTextRich:onTouchBegan(touch)
end


---@param touch cc.Touch
---@param duration number
function CTextRich:onTouchMoved(touch, duration)
end


---@param touch cc.Touch
---@param duration number
function CTextRich:onTouchEnded(touch, duration)
end


---@param touch cc.Touch
---@param duration number
function CTextRich:onTouchCancelled(touch, duration)
end


---@param handler fun(sender:cc.Ref, description:string):void
function CTextRich:setOnTextRichClickScriptHandler(handler)
end

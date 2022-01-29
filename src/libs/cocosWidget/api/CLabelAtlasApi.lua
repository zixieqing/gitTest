---@meta


---@class CLabelAtlas : cc.LabelAtlas
local CLabelAtlas = {}


---@param pString string
---@param fntFile string
---@return CLabelAtlas
---@overload fun(pString:string, charMapFile:string, itemWidth:integer, itemHeight:integer, startCharMap:integer):CLabelAtlas
function CLabelAtlas:create(pString, fntFile)
end


---@return boolean
function CLabelAtlas:init()
end


---@param touch cc.Touch
---@return ccw.WIDGET_TOUCH_MODEL
function CLabelAtlas:onTouchBegan(touch)
end


---@param touch cc.Touch
---@param duration number
function CLabelAtlas:onTouchMoved(touch, duration)
end


---@param touch cc.Touch
---@param duration number
function CLabelAtlas:onTouchEnded(touch, duration)
end


---@param touch cc.Touch
---@param duration number
function CLabelAtlas:onTouchCancelled(touch, duration)
end


---@param handler fun(sender:cc.Ref):void
function CLabelAtlas:setOnClickScriptHandler(handler)
end


---@param handler fun(sender:cc.Ref, touch:cc.Touch):void
function CLabelAtlas:setOnLongClickScriptHandler(handler)
end

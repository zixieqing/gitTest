
--------------------------------
-- @module EventListenerKeyboard
-- @extend EventListener
-- @parent_module cc

---@class cc.EventListenerKeyboard:cc.EventListener
local EventListenerKeyboard = {}
cc.EventListenerKeyboard = EventListenerKeyboard
--------------------------------

--- 
---@return boolean
function EventListenerKeyboard:init()
end

--------------------------------

--- / Overrides
---@return cc.EventListenerKeyboard
function EventListenerKeyboard:clone()
end


---@return cc.EventListenerKeyboard
function EventListenerKeyboard:create()
end

--------------------------------

--- 
---@return boolean
function EventListenerKeyboard:checkAvailable()
end

--------------------------------

--- 
---@return cc.EventListenerKeyboard
function EventListenerKeyboard:EventListenerKeyboard()
end


-------------------------------------------------------------------------------
-- manual
-------------------------------------------------------------------------------


---registerScriptHandler
---@param handler fun(keyCode:number, event:cc.EventKeyboard)
---@param handlerType number @enum in cc.Handler, can be EVENT_KEYBOARD_PRESSED(38) or EVENT_KEYBOARD_RELEASED(39)
function EventListenerKeyboard:registerScriptHandler(handler, handlerType)
end


return nil

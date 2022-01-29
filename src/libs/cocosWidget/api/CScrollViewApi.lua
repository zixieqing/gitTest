---@meta


---@class CScrollViewContainer : CLayout
local CScrollViewContainer = {}


function CScrollViewContainer:reset()
end


-------------------------------------------------------------------------------
-- CScrollView
-------------------------------------------------------------------------------

---@class CScrollView : CLayout
local CScrollView = {}


---@param contentSize cc.size
---@return CScrollView
function CScrollView:create(contentSize)
end


---@return boolean
function CScrollView:init()
end


---@param size cc.size
---@return boolean
function CScrollView:initWithSize(size)
end


---@param contentSize cc.size
function CScrollView:setContentSize(contentSize)
end


---@param size cc.size
function CScrollView:setContainerSize(size)
end


---@return cc.size
function CScrollView:getContainerSize()
end


---@return CScrollViewContainer
function CScrollView:getContainer()
end


---@param direction ccw.SCROLL_VIEW_DIRECTION
function CScrollView:setDirection(direction)
end


---@return ccw.SCROLL_VIEW_DIRECTION
function CScrollView:getDirection()
end


---@param isDragable boolean
function CScrollView:setDragable(isDragable)
end


---@return boolean
function CScrollView:isDragable()
end


---@param isBounceable boolean
function CScrollView:setBounceable(isBounceable)
end


---@return boolean
function CScrollView:isBounceable()
end


---@param isDeaccelerateable boolean
function CScrollView:setDeaccelerateable(isDeaccelerateable)
end


---@return boolean
function CScrollView:isDeaccelerateable()
end


---@param offset cc.p
function CScrollView:setContentOffset(offset)
end


function CScrollView:setContentOffsetToTop()
end


function CScrollView:setContentOffsetToBottom()
end


function CScrollView:setContentOffsetToLeft()
end


function CScrollView:setContentOffsetToRight()
end


---@param offset cc.p
---@param duration number
function CScrollView:setContentOffsetInDuration(offset, duration)
end


---@param offset cc.p
---@param duration number
---@param rate number
function CScrollView:setContentOffsetEaseIn(offset, duration, rate)
end


---@param duration number
function CScrollView:setContentOffsetToTopInDuration(duration)
end


---@param duration number
---@param rate number
function CScrollView:setContentOffsetToTopEaseIn(duration, rate)
end


---@return cc.p
function CScrollView:getContentOffset()
end


---@return cc.p
function CScrollView:getMaxOffset()
end


---@return cc.p
function CScrollView:getMinOffset()
end


function CScrollView:stopContainerAnimation()
end


function CScrollView:relocateContainer()
end


function CScrollView:isTouchMoved()
end


function CScrollView:beforeDraw()
end


function CScrollView:onAfterDraw()
end


function CScrollView:afterDraw()
end


function CScrollView:onBeforeDraw()
end


---@param renderer cc.Renderer
---@param parentTransform cc.mat4
---@param parentFlags integer
function CScrollView:visit(renderer, parentTransform, parentFlags)
end


---@param touch cc.Touch
---@return ccw.WIDGET_TOUCH_MODEL
function CScrollView:onTouchBegan(touch)
end


---@param handler fun(sender:cc.Ref, touch:cc.Touch):ccw.WIDGET_TOUCH_MODEL
function CScrollView:setOnTouchBeganScriptHandler(handler)
end


---@param touch cc.Touch
---@param duration number
function CScrollView:onTouchMoved(touch, duration)
end


---@param handler fun(sender:cc.Ref, touch:cc.Touch, duration:number):boolean
function CScrollView:setOnTouchMovedScriptHandler(handler)
end


---@param touch cc.Touch
---@param duration number
function CScrollView:onTouchEnded(touch, duration)
end


---@param handler fun(sender:cc.Ref, touch:cc.Touch, duration:number):boolean
function CScrollView:setOnTouchEndedScriptHandler(handler)
end


---@param touch cc.Touch
---@param duration number
function CScrollView:onTouchCancelled(touch, duration)
end


---@param handler fun(sender:cc.Ref, touch:cc.Touch, duration:number):boolean
function CScrollView:setOnTouchCancelledScriptHandler(handler)
end


---@param handler fun(sender:cc.Ref):void
function CScrollView:setOnScrollingScriptHandler(handler)
end


function CScrollView:onExit()
end

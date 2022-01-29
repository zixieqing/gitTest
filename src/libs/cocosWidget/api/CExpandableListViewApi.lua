---@meta


---@class CExpandableNode : CLayout
local CExpandableNode = {}


---@return CExpandableNode
function CExpandableNode:create()
end


---@param isExpanded boolean
function CExpandableNode:setExpanded(isExpanded)
end


---@return boolean
function CExpandableNode:isExpanded()
end


---@param node cc.Node
function CExpandableNode:insertItemNodeAtFront(node)
end


---@param node cc.Node
function CExpandableNode:insertItemNodeAtLast(node)
end


---@param index integer
function CExpandableNode:getItemNodeAtIndex(index)
end


---@param index integer
function CExpandableNode:removeItemNodeAtIndex(index)
end


---@param node cc.Node
function CExpandableNode:removeItemNode(node)
end


function CExpandableNode:removeAllItemNodes()
end


---@param touch cc.Touch
---@return ccw.WIDGET_TOUCH_MODEL
function CExpandableNode:onTouchBegan(touch)
end


---@param touch cc.Touch
---@param duration number
function CExpandableNode:onTouchMoved(touch, duration)
end


---@param touch cc.Touch
---@param duration number
function CExpandableNode:onTouchEnded(touch, duration)
end


---@param touch cc.Touch
---@param duration number
function CExpandableNode:onTouchCancelled(touch, duration)
end


-------------------------------------------------------------------------------
-- CExpandableListView
-------------------------------------------------------------------------------

---@class CExpandableListView : CScrollView
local CExpandableListView = {}


---@return CExpandableListView
function CExpandableListView:create()
end


---@param node CExpandableNode
function CExpandableListView:insertExpandableNodeAtLast(node)
end


---@param node CExpandableNode
function CExpandableListView:insertExpandableNodeAtFront(node)
end


---@return integer
function CExpandableListView:getExpandableNodeCount()
end


---@param index integer
---@return CExpandableNode
function CExpandableListView:getExpandableNodeAtIndex(index)
end


---@return CExpandableNode[]
function CExpandableListView:getExpandableNodes()
end


---@param index integer
function CExpandableListView:removeExpandableNodeAtIndex(index)
end


---@param node CExpandableNode
function CExpandableListView:removeExpandableNode(node)
end


function CExpandableListView:removeLastExpandableNode()
end


function CExpandableListView:removeFrontExpandableNode()
end


function CExpandableListView:removeAllExpandableNodes()
end


---@param isExclude boolean
function CExpandableListView:setExcluded(isExclude)
end


--- expand a expandable node by idx
function CExpandableListView:expand()
end


--- collapse a expandable node by idx
function CExpandableListView:collapse()
end


function CExpandableListView:reloadData()
end

---@meta


---@class CListView : CScrollView
local CListView = {}


---@param contentSize cc.size
---@return CListView
function CListView:create(contentSize)
end


---@param node cc.Node
---@param index integer
---@overload fun(node:cc.Node, target:cc.Node):void
function CListView:insertNode(node, index)
end


---@param node cc.Node
function CListView:insertNodeAtFront(node)
end


---@param node cc.Node
function CListView:insertNodeAtLast(node)
end


---@param node cc.Node
function CListView:removeNode(node)
end


---@param index integer
function CListView:removeNodeAtIndex(index)
end


function CListView:removeAllNodes()
end


function CListView:removeLastNode()
end


function CListView:removeFrontNode()
end


---@return integer
function CListView:getNodeCount()
end


---@param index integer
---@return cc.Node
function CListView:getNodeAtIndex(index)
end


---@return cc.Node[]
function CListView:getNodes()
end


function CListView:reloadData()
end

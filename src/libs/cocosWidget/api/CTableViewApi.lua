---@meta


---@class CTableViewCell : CLayout
local CTableViewCell = {}


---@type nil @ undefined !! **do not use** !!
function CTableViewCell:create()
end


---@return CTableViewCell
function CTableViewCell:new()
end


---@param index integer
function CTableViewCell:setIdx(index)
end


---@return integer
function CTableViewCell:getIdx()
end


function CTableViewCell:reset()
end


-------------------------------------------------------------------------------
-- CTableView
-------------------------------------------------------------------------------

---@class CTableView : CScrollView
local CTableView = {}


---@param viewSize cc.size
---@param cellSize? cc.size
---@param cellCount? integer
---@param handler? fun(convertCell:cc.Ref, index:integer):cc.Ref
---@return CTableView
function CTableView:create(viewSize, cellSize, cellCount, handler)
end


---@param cellsSize cc.size
function CTableView:setSizeOfCell(cellsSize)
end


---@return cc.size
function CTableView:getSizeOfCell()
end


---@param cellsCount integer
function CTableView:setCountOfCell(cellsCount)
end


---@return integer
function CTableView:getCountOfCell()
end


---@param speed number
function CTableView:setAutoRelocateSpeed(speed)
end


---@return number
function CTableView:getAutoRelocateSpeed()
end


---@param isAuto boolean
function CTableView:setAutoRelocate(isAuto)
end


---@return boolean
function CTableView:isAutoRelocate()
end


---@return CTableViewCell
function CTableView:dequeueCell()
end


---@param index integer
---@return CTableViewCell
function CTableView:cellAtIndex(index)
end


---@return CTableViewCell[]
function CTableView:getCells()
end


function CTableView:reloadData()
end


---@param handler fun(convertCell:cc.Ref, index:integer):cc.Ref
function CTableView:setDataSourceAdapterScriptHandler(handler)
end

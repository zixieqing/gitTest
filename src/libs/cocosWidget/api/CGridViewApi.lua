---@meta


---@class CGridViewCell : CLayout
local CGridViewCell = {}


---@type nil @ undefined !! **do not use** !!
function CGridViewCell:create()
end


---@return CGridViewCell
function CGridViewCell:new()
end


---@param index integer
function CGridViewCell:setIdx(index)
end


---@return integer
function CGridViewCell:getIdx()
end


---@param row integer
function CGridViewCell:setRow(row)
end


---@return integer
function CGridViewCell:getRow()
end


function CGridViewCell:reset()
end


-------------------------------------------------------------------------------
-- CGridView
-------------------------------------------------------------------------------

---@class CGridView : CScrollView
local CGridView = {}


---@param viewSize cc.size
---@param cellSize? cc.size
---@param cellCount? integer
---@param handler? fun(convertCell:cc.Ref, index:integer):cc.Ref
---@return CGridView
function CGridView:create(viewSize, cellSize, cellCount, handler)
end


---@param cellsSize cc.size
function CGridView:setSizeOfCell(cellsSize)
end


---@return cc.size
function CGridView:getSizeOfCell()
end


---@param cellsCount integer
function CGridView:setCountOfCell(cellsCount)
end


---@return integer
function CGridView:getCountOfCell()
end


---@param columns integer
function CGridView:setColumns(columns)
end


---@return integer
function CGridView:getColumns()
end


---@return integer
function CGridView:getRows()
end


---@param isAuto boolean
function CGridView:setAutoRelocate(isAuto)
end


---@return boolean
function CGridView:isAutoRelocate()
end


---@return CGridViewCell
function CGridView:dequeueCell()
end


---@param index integer
---@return CGridViewCell
function CGridView:cellAtIndex(index)
end


---@return CGridViewCell[]
function CGridView:getCells()
end


function CGridView:reloadData()
end


---@param handler fun(convertCell:cc.Ref, index:integer):cc.Ref
function CGridView:setDataSourceAdapterScriptHandler(handler)
end

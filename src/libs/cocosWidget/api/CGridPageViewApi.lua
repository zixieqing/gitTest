---@meta


---@class CGridPageViewCell : CTableViewCell
local CGridPageViewCell = {}


---@type nil @ undefined !! **do not use** !!
function CGridPageViewCell:create()
end


---@return CGridPageViewCell
function CGridPageViewCell:new()
end


-------------------------------------------------------------------------------
-- CGridPageViewPage
-------------------------------------------------------------------------------

---@class CGridPageViewPage : CTableViewCell
local CGridPageViewPage = {}


---@type nil @ undefined !! **do not use** !!
function CGridPageViewPage:create()
end


---@type nil @ undefined !! **do not use** !!
function CGridPageViewPage:new()
end


-------------------------------------------------------------------------------
-- CGridPageView
-------------------------------------------------------------------------------

---@class CGridPageView : CTableView
local CGridPageView = {}


---@param viewSize cc.size
---@param cellSize? cc.size
---@param cellCount? integer
---@param handler? fun(convertCell:cc.Ref, index:integer):cc.Ref
---@return CGridPageView
function CGridPageView:create(viewSize, cellSize, cellCount, handler)
end


---@param cellsSize cc.size
function CGridPageView:setSizeOfCell(cellsSize)
end


---@return cc.size
function CGridPageView:getSizeOfCell()
end


---@param cellsCount integer
function CGridPageView:setCountOfCell(cellsCount)
end


---@return integer
function CGridPageView:getCountOfCell()
end


---@param columns integer
function CGridPageView:setColumns(columns)
end


---@return integer
function CGridPageView:getColumns()
end


---@param rows integer
function CGridPageView:setRows(rows)
end


---@return integer
function CGridPageView:getRows()
end


function CGridPageView:reloadData()
end


---@param handler fun(convertCell:cc.Ref, index:integer):cc.Ref
function CGridPageView:setDataSourceAdapterScriptHandler(handler)
end


---@param handler fun(sender:cc.Ref, pageIndex:integer):void
function CGridPageView:setOnPageChangedScriptHandler(handler)
end

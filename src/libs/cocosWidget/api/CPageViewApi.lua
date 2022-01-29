---@meta


---@class CPageViewCell : CTableViewCell
local CPageViewCell = {}


---@type nil @ undefined !! **do not use** !!
function CPageViewCell:create()
end


---@return CPageViewCell
function CPageViewCell:new()
end


-------------------------------------------------------------------------------
-- CPageView
-------------------------------------------------------------------------------

---@class CPageView : CTableView
local CPageView = {}


---@param pageSize cc.size
---@param pageCount? integer
---@param handler? fun(convertCell:cc.Ref, index:integer):cc.Ref
---@return CPageView
function CPageView:create(pageSize, pageCount, handler)
end


---@param handler fun(convertCell:cc.Ref, index:integer):cc.Ref
function CPageView:setDataSourceAdapterScriptHandler(handler)
end


---@param handler fun(sender:cc.Ref, pageIndex:integer):void
function CPageView:setOnPageChangedScriptHandler(handler)
end

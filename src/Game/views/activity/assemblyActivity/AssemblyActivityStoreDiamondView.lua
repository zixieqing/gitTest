--[[
 * author : liuzhipeng
 * descpt : 活动 组合活动 钻石商城View
--]]
local AssemblyActivityStoreDiamondView = class('AssemblyActivityStoreDiamondView', function ()
    local node = CLayout:create()
    node.name = 'activity.assemblyActivity.AssemblyActivityStoreDiamondView'
    node:enableNodeEvents()
    return node
end)
local PropsStoreGoodsNode = require('Game.views.stores.GamePropsStoreGoodsNode')
local RES_DICT = {

}
local CreateView      = nil
local CreateGoodsCell = nil

function AssemblyActivityStoreDiamondView:ctor( size )
    self:setContentSize(size)
    self:setPosition(cc.p(size.width / 2, size.height / 2))

    -- create view
    self.viewData_ = CreateView(size)
    self:addChild(self.viewData_.view)
end

CreateView = function(size)
    local view = display.newLayer(0, 0, {size = size})

    -- block layer
    view:addChild(display.newLayer(0, 0, {size = size, color = cc.r4b(0), enable = true}))

    -- goods gridView
    local goodsGridCols = 3
    local goodsFramePos = cc.p(size.width/2, size.height/2)
    local goodsGridSize = cc.size(size.width - 2, size.height - 2)
    local goodsGridView = CGridView:create(goodsGridSize)
    goodsGridView:setSizeOfCell(cc.size(PropsStoreGoodsNode.NODE_SIZE.width - 4, PropsStoreGoodsNode.NODE_SIZE.height))
    goodsGridView:setAnchorPoint(display.CENTER)
    goodsGridView:setPosition(goodsFramePos)
    goodsGridView:setColumns(goodsGridCols)
    view:addChild(goodsGridView)

    return {
        view          = view,
        goodsGridView = goodsGridView,
    }
end

CreateGoodsCell = function(size)
    local view = CGridViewCell:new()
    view:setContentSize(size)

    local goodsNode = PropsStoreGoodsNode.new()
    view:addChild(goodsNode)

    return {
        view       = view,
        goodsNode = goodsNode,
    }
end
function AssemblyActivityStoreDiamondView:getViewData()
    return self.viewData_
end


-------------------------------------------------
-- goods cell

function AssemblyActivityStoreDiamondView:createGoodsCell(size)
    return CreateGoodsCell(size)
end
return AssemblyActivityStoreDiamondView
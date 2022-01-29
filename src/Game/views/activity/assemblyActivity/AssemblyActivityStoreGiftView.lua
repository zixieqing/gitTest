--[[
 * author : liuzhipeng
 * descpt : 活动 组合活动 礼包商城View
--]]
local GiftsStoreGoodsNode = require('Game.views.stores.GameGiftsStoreGoodsNode')
local AssemblyActivityStoreGiftView = class('AssemblyActivityStoreGiftView', function ()
    local node = CLayout:create()
    node.name = 'activity.assemblyActivity.AssemblyActivityStoreGiftView'
    node:enableNodeEvents()
    return node
end)
local RES_DICT = {

}
local CreateView      = nil
local CreateGoodsCell = nil

function AssemblyActivityStoreGiftView:ctor( size )
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
    local goodsGridCols = 2
    local goodsFramePos = cc.p(size.width/2, size.height/2)
    local goodsGridSize = cc.size(size.width - 2, size.height - 2)
    local goodsGridView = CGridView:create(goodsGridSize)
    goodsGridView:setSizeOfCell(GiftsStoreGoodsNode.NODE_SIZE)
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

    local goodsNode = GiftsStoreGoodsNode.new({name = 'assemblyActivityStoreGift'})
    view:addChild(goodsNode)

    return {
        view       = view,
        goodsNode = goodsNode,
    }
end
function AssemblyActivityStoreGiftView:getViewData()
    return self.viewData_
end


-------------------------------------------------
-- goods cell

function AssemblyActivityStoreGiftView:createGoodsCell(size)
    return CreateGoodsCell(size)
end
return AssemblyActivityStoreGiftView
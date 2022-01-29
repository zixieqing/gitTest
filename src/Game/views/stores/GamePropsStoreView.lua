--[[
 * author : kaishiqi
 * descpt : 新游戏商店 - 道具商店视图
]]
local PropsStoreGoodsNode = require('Game.views.stores.GamePropsStoreGoodsNode')
local GamePropsStoreView  = class('GamePropsStoreView', function()
    return display.newLayer(0, 0, {name = 'Game.views.stores.GamePropsStoreView'})
end)

local RES_DICT = {
}

local CreateView      = nil
local CreateGoodsCell = nil


function GamePropsStoreView:ctor(size)
    self:setContentSize(size)

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
    goodsGridView:setSizeOfCell(PropsStoreGoodsNode.NODE_SIZE)
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


function GamePropsStoreView:getViewData()
    return self.viewData_
end


-------------------------------------------------
-- goods cell

function GamePropsStoreView:createGoodsCell(size)
    return CreateGoodsCell(size)
end


return GamePropsStoreView

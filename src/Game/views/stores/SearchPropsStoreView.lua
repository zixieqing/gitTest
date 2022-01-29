--[[
 * author : kaishiqi
 * descpt : 新游戏商店 - 道具搜索视图
]]
local GiftsStoreGoodsNode  = require('Game.views.stores.GameGiftsStoreGoodsNode')
local PropsStoreGoodsNode  = require('Game.views.stores.GamePropsStoreGoodsNode')
local SearchPropsStoreView = class('SearchPropsStoreView', function()
    return display.newLayer(0, 0, {name = 'Game.views.stores.SearchPropsStoreView'})
end)

local RES_DICT = {
    RESULT_TYPE_BAR    = _res('ui/stores/searchProp/shop_search_label_shopname.png'),
    EMPTY_RESULT_IMG   = _res('ui/stores/searchProp/shop_search_ico_empty.png'),
    EMPTY_RESULT_FRAME = _res('ui/common/common_bg_dialogue_tips.png'),
}

local CreateView = nil


function SearchPropsStoreView:ctor(size)
    self:setContentSize(size)

    -- create view
    self.viewData_ = CreateView(size)
    self:addChild(self.viewData_.view)
end


CreateView = function(size)
    local view = display.newLayer(0, 0, {size = size})

    -- block layer
    view:addChild(display.newLayer(0, 0, {size = size, color = cc.r4b(0), enable = true}))

    -- result list
    local resultList = CListView:create(size)
    resultList:setDirection(eScrollViewDirectionVertical)
    resultList:setPosition(cc.p(size.width/2, size.height/2))
    resultList:setAnchorPoint(display.CENTER)
    view:addChild(resultList)

    -------------------------------------------------
    -- empty layer
    local emptyLayer = display.newLayer()
    view:addChild(emptyLayer)

    local emptyLabel = display.newButton(size.width/2 - 150, size.height/2, {n = RES_DICT.EMPTY_RESULT_FRAME, enable = false})
    display.commonLabelParams(emptyLabel, fontWithColor(6, {text = __('好像卖完了……'), w = 320, hAlign = display.TAC}))
    emptyLayer:addChild(emptyLabel)
    emptyLayer:addChild(display.newImageView(RES_DICT.EMPTY_RESULT_IMG, size.width/2 + 200, size.height/2))

    return {
        view       = view,
        resultList = resultList,
        emptyLayer = emptyLayer,
    }
end


function SearchPropsStoreView:getViewData()
    return self.viewData_
end


function SearchPropsStoreView:createResultTypeBar(typeName)
    local resultList  = self:getViewData().resultList
    local listSize    = resultList:getContentSize()
    local typeBarSize = cc.size(listSize.width, 50)
    local typeBarView = display.newLayer(0, 0, {size = typeBarSize})
    typeBarView:addChild(display.newImageView(RES_DICT.RESULT_TYPE_BAR, typeBarSize.width/2, typeBarSize.height/2))
    typeBarView:addChild(display.newLabel(40, typeBarSize.height/2, fontWithColor(3, {fontSize = 28, text = tostring(typeName), ap = display.LEFT_CENTER})))
    return typeBarView
end


function SearchPropsStoreView:createGiftsGoodsLayer(giftsGoodsData, eachNodeCallback)
    local goodsCount = table.nums(giftsGoodsData or {})
    local goodsCols  = 2
    local goodsRows  = math.ceil(goodsCount / goodsCols)
    local goodsSize  = GiftsStoreGoodsNode.NODE_SIZE
    local layerSize  = cc.size(goodsSize.width * goodsCols, goodsSize.height * goodsRows)
    local goodsLayer = display.newLayer(0, 0, {size = layerSize})

    for row = 1, goodsRows do
        for col = 1, goodsCols do
            local goodsIndex = (row-1) * goodsCols + col
            if goodsIndex <= goodsCount then
                local goodsNode  = GiftsStoreGoodsNode.new()
                goodsNode:setPositionX((col-1) * goodsSize.width)
                goodsNode:setPositionY(layerSize.height - row * goodsSize.height)
                goodsNode:setTag(goodsIndex)
                goodsLayer:addChild(goodsNode)
                if eachNodeCallback then eachNodeCallback(goodsNode, goodsIndex) end
            end
        end
    end
    return goodsLayer
end


function SearchPropsStoreView:createPropsGoodsLayer(propsGoodsData, eachNodeCallback)
    local goodsCount = table.nums(propsGoodsData or {})
    local goodsCols  = 3
    local goodsRows  = math.ceil(goodsCount / goodsCols)
    local goodsSize  = PropsStoreGoodsNode.NODE_SIZE
    local layerSize  = cc.size(goodsSize.width * goodsCols, goodsSize.height * goodsRows)
    local goodsLayer = display.newLayer(0, 0, {size = layerSize})

    for row = 1, goodsRows do
        for col = 1, goodsCols do
            local goodsIndex = (row-1) * goodsCols + col
            if goodsIndex <= goodsCount then
                local goodsNode  = PropsStoreGoodsNode.new()
                goodsNode:setPositionX((col-1) * goodsSize.width)
                goodsNode:setPositionY(layerSize.height - row * goodsSize.height)
                goodsNode:setTag(goodsIndex)
                goodsLayer:addChild(goodsNode)
                if eachNodeCallback then eachNodeCallback(goodsNode, goodsIndex) end
            end
        end
    end
    return goodsLayer
end


return SearchPropsStoreView

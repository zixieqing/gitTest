--[[
 * author : kaishiqi
 * descpt : 打牌游戏 - 牌店 - 兑换视图
]]
local PropsStoreGoodsNode   = require('Game.views.stores.GamePropsStoreGoodsNode')
local TTGameShopComposeView = class('TripleTriadGameShopComposeView', function()
    return display.newLayer(0, 0, {name = 'Game.views.stores.TripleTriadGameShopComposeView'})
end)

local RES_DICT = {
    GOODS_FRAME       = _res('ui/ttgame/shop/cardgame_shop_bg_goods.png'),
    TITLE_BAR         = _res('ui/ttgame/shop/cardgame_shop_bg_up.png'),
    FILTER_TYPE_BTN_N = _res('ui/home/teamformation/choosehero/team_btn_selection_unused.png'),
    FILTER_TYPE_BTN_S = _res('ui/home/teamformation/choosehero/team_btn_selection_choosed.png'),
    FILTER_TYPE_ARROW = _res('ui/home/cardslistNew/card_ico_direction.png'),
}

local CreateView     = nil
local CreateCardCell = nil


function TTGameShopComposeView:ctor(size)
    self:setContentSize(size)

    -- create view
    self.viewData_ = CreateView(size)
    self:addChild(self.viewData_.view)

    -- update view
    self:updateFilterButtonLabel()
end


CreateView = function(size)
    local view = display.newLayer(0, 0, {size = size})

    -- block layer
    view:addChild(display.newLayer(0, 0, {size = size, color = cc.r4b(0), enable = true}))

    local CARD_COLUMNS = 5
    local cardGridSize = cc.size(size.width, size.height - 52)
    local cardGridView = CGridView:create(cardGridSize)
    cardGridView:setSizeOfCell(cc.size(math.floor(cardGridSize.width / CARD_COLUMNS), 283))
    cardGridView:setAnchorPoint(display.CENTER_BOTTOM)
    cardGridView:setPosition(size.width/2, 0)
    cardGridView:setColumns(CARD_COLUMNS)
    -- cardGridView:setBackgroundColor(cc.c4b(100,100,50,255))
    view:addChild(cardGridView)
    
    view:addChild(display.newImageView(RES_DICT.TITLE_BAR, size.width/2, size.height, {ap = display.CENTER_TOP}))

    -- type filter button
    local typeFilterBtn  = display.newToggleView(0, 0, {n = RES_DICT.FILTER_TYPE_BTN_N, s = RES_DICT.FILTER_TYPE_BTN_S, scale9 = true, size = cc.size(160, 45)})
    local typeFilterSize = typeFilterBtn:getContentSize()
    typeFilterBtn:setPositionX(size.width - typeFilterSize.width/2 - 15)
    typeFilterBtn:setPositionY(size.height - typeFilterSize.height/2 - 3)
    view:addChild(typeFilterBtn)
    
    local typeFilterNLabel = display.newLabel(typeFilterSize.width/2, typeFilterSize.height/2, fontWithColor(18, {color = '#FFFFFF'}))
    local typeFilterSLabel = display.newLabel(typeFilterSize.width/2, typeFilterSize.height/2, fontWithColor(18, {color = '#ffcf96'}))
    typeFilterBtn:addChild(display.newImageView(RES_DICT.FILTER_TYPE_ARROW, typeFilterSize.width - 22, typeFilterSize.height/2))
    typeFilterBtn:getNormalImage():addChild(typeFilterNLabel)
    typeFilterBtn:getSelectedImage():addChild(typeFilterSLabel)

    return {
        view             = view,
        cardGridView     = cardGridView,
        typeFilterBtn    = typeFilterBtn,
        typeFilterNLabel = typeFilterNLabel,
        typeFilterSLabel = typeFilterSLabel,
    }
end


CreateCardCell = function(size)
    local view = CGridViewCell:new()
    view:setContentSize(size)

    local bgFrame = display.newImageView(RES_DICT.GOODS_FRAME, size.width/2, size.height/2)
    view:addChild(bgFrame)

    local cardLayer = display.newLayer(size.width/2, size.height/2 + 20)
    view:addChild(cardLayer)

    local cardNode = TTGameUtils.GetBattleCardNode({zoomModel = 'l'})
    cardLayer:addChild(cardNode)


    local haveLayer = display.newLayer()
    view:addChild(haveLayer)

    local haveLabel = display.newLabel(size.width/2, 28, fontWithColor(6, {fontSize = 24, text = __('已获得')}))
    haveLayer:addChild(haveLabel)
    
    local lockLayer = display.newLayer()
    view:addChild(lockLayer)

    local priceLabel = cc.Label:createWithBMFont('font/small/common_text_num.fnt', '----')
    priceLabel:setAnchorPoint(display.RIGHT_CENTER)
    priceLabel:setPositionY(haveLabel:getPositionY())
    priceLabel:setPositionX(size.width/2 + 22)
    priceLabel:setBMFontSize(30)
    lockLayer:addChild(priceLabel)
    
    local cIconLayer = display.newLayer(size.width/2 + 28, haveLabel:getPositionY(), {ap = display.LEFT_BOTTOM})
    cIconLayer:setScale(0.2)
    lockLayer:addChild(cIconLayer)


    local hotspot = display.newLayer(0, 0, {size = size, color = cc.r4b(0), enable = true})
    view:addChild(hotspot)

    return {
        view       = view,
        hotspot    = hotspot,
        bgFrame    = bgFrame,
        cardNode   = cardNode,
        haveLayer  = haveLayer,
        lockLayer  = lockLayer,
        priceLabel = priceLabel,
        cIconLayer = cIconLayer,
    }
end


function TTGameShopComposeView:getViewData()
    return self.viewData_
end


function TTGameShopComposeView:updateFilterButtonLabel(buttonName)
    display.commonLabelParams(self:getViewData().typeFilterSLabel, {text = buttonName or __('组别')})
    display.commonLabelParams(self:getViewData().typeFilterNLabel, {text = buttonName or __('组别')})
end


-------------------------------------------------
-- card cell

function TTGameShopComposeView.CreateCardCell(size)
    return CreateCardCell(size)
end



return TTGameShopComposeView

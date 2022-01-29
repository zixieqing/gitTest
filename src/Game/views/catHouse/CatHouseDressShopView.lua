--[[
 * author : zhipeng
 * descpt : 猫屋 - 装饰商店 界面
]]
local CatHouseDressShopView = class('CatHouseDressShopView', function()
    return ui.layer({name = 'Game.views.catHouse.CatHouseDressShopView', enableEvent = true, ap = display.CENTER})
end)

-------------------------------------------------
-------------------- define ---------------------
local STORE_TAB_DEFINE = {
    {type = CatHouseUtils.AVATAR_STYLE_TYPE.IDENTITY},
    {type = CatHouseUtils.AVATAR_STYLE_TYPE.BUBBLE},
}

local RES_DICT = {
    BG_FRAME      = _res('ui/home/union/guild_shop_bg.png'),
    VIEW_FRAME    = _res('ui/home/union/guild_shop_bg_white.png'),
    LIST_BG       = _res("ui/common/common_bg_goods.png"), 
    TITLE_BG      = _res('ui/common/common_bg_title_2.png'),
    TAB_BG_N      = _res('ui/common/common_btn_tab_default.png'),
    TAB_BG_S      = _res('ui/common/common_btn_tab_select.png'),
    PRODUCT_BG    = _res('ui/home/commonShop/shop_btn_goods_default.png'),
}
local CreateGoodsListCell = nil
-------------------- define ---------------------
-------------------------------------------------

-------------------------------------------------
------------------ inheritance ------------------
function CatHouseDressShopView:ctor(args)
    self.args = args
    self:InitialUI()
end
------------------ inheritance ------------------
-------------------------------------------------

-------------------------------------------------
-------------------- private --------------------
function CatHouseDressShopView:InitialUI()
    local function CreateView()
        local bg = display.newImageView(RES_DICT.BG_FRAME, 0, 0)
        local size = bg:getContentSize()
        local view = display.newLayer(display.cx, display.cy - 20, {size = size, ap = display.CENTER})
        bg:setPosition(cc.p(size.width / 2, size.height / 2))
        view:addChild(bg, 1)
        -- mask
        local mask = display.newLayer(display.cx, display.cy, {size = size, ap = display.CENTER, enable = true, color = cc.c4b(0, 0, 0, 0)})
        view:addChild(mask, -1)
        -- CommonMoneyBar
        local moneyBar = require("common.CommonMoneyBar").new()
        self:addChild(moneyBar, 10)
        
        -- 标题
        local titleLabel = display.newButton(size.width / 2, size.height - 25, {n = RES_DICT.TITLE_BG})
        display.commonLabelParams(titleLabel, fontWithColor(3, {text = __('猫咪商店')}))
        view:addChild(titleLabel, 5)
        -- 道具背景
        local goodsBg = display.newImageView(RES_DICT.VIEW_FRAME, size.width / 2, size.height / 2 - 7)
        view:addChild(goodsBg, 2)
        -- 商店页签
        local tabList = {}
        for i, v in ipairs(STORE_TAB_DEFINE) do
            local tabBtn = display.newButton(175 + (i - 1) * 145, size.height - 94, {n = RES_DICT.TAB_BG_N})
            view:addChild(tabBtn, 5)
            tabBtn:setTag(v.type)
            display.commonLabelParams(tabBtn, fontWithColor(14, {text = CatHouseUtils.GetAvatarStyleTypeName(v.type), fontSize = 22}))
            table.insert(tabList, tabBtn)
        end
        -- 列表背景
        local listSize = cc.size(1044, 508)
        local listCellSize = cc.size((listSize.width - 8)/5, listSize.height*0.55)
        local listBg = display.newImageView(RES_DICT.LIST_BG, size.width / 2, size.height / 2 - 36, {size = listSize, scale9 = true})
        view:addChild(listBg, 2)
        -- 道具列表
        local goodsGridViewSize = cc.size(1044, 508)
        local goodsGridView = ui.gridView({x = size.width / 2, y = size.height / 2 - 36, size = goodsGridViewSize, cols = 3, csizeH = 280, auto = true})
        goodsGridView:setCellCreateHandler(CreateGoodsListCell)
        view:addChild(goodsGridView, 5)
        return {
            view          = view,
            moneyBar      = moneyBar,
            listCellSize  = listCellSize,
            goodsGridView = goodsGridView,
            tabList       = tabList,
        }
    end
    -- eaterLayer
    local eaterLayer = display.newLayer(display.cx, display.cy, {size = display.size, ap = display.CENTER, color = cc.c4b(0, 0, 0, 255 * 0.6), enable = true})
    self:addChild(eaterLayer, -1)
    self.eaterLayer = eaterLayer
    xTry(function ( )
        self.viewData = CreateView( )
        self:addChild(self.viewData.view)
	end, __G__TRACKBACK__)
end
--[[
初始化货币栏
--]]
function CatHouseDressShopView:InitMoneyBar( moneyIdMap )
    local viewData = self:GetViewData()
    viewData.moneyBar:reloadMoneyBar(moneyIdMap, false)
end
--[[
刷新列表
@params products list 商品列表
--]]
function CatHouseDressShopView:RefreshList( products )
    local viewData = self:GetViewData()
    viewData.goodsGridView:resetCellCount(#products)
end
--[[
刷新页签
--]]
function CatHouseDressShopView:RefreshTab( type )
    local viewData = self:GetViewData()
    local index = 1
    for i, v in ipairs(STORE_TAB_DEFINE) do
        if checkint(type) == checkint(v.type) then
            index = i
            break
        end
    end
    for i, v in ipairs(viewData.tabList) do
        if i == index then
            v:setNormalImage(RES_DICT.TAB_BG_S)
            v:setSelectedImage(RES_DICT.TAB_BG_S)
        else
            v:setNormalImage(RES_DICT.TAB_BG_N)
            v:setSelectedImage(RES_DICT.TAB_BG_N)
        end
    end
end

CreateGoodsListCell = function ( cellParent )
    local view = cellParent
    local size = cellParent:getContentSize()
    -- 背景按钮
    local bg = display.newButton(size.width / 2, size.height / 2, {n = RES_DICT.PRODUCT_BG, useS = false, scale9 = true, size = cc.size(336, 252)})
    view:addChild(bg, 1)

    local itemLayer = ui.layer({size = size})
    view:addChild(itemLayer, 1)
    -- 价格
    local priceLabel = cc.Label:createWithBMFont('font/small/common_text_num.fnt', '0')
	priceLabel:setAnchorPoint(display.CENTER)
	priceLabel:setHorizontalAlignment(display.TAR)
	priceLabel:setPosition(size.width/2, 38)
    view:addChild(priceLabel, 1)
    local currencyIcon = display.newImageView('', size.width/2, 38)
    currencyIcon:setScale(0.18)
    view:addChild(currencyIcon, 1)
    -- 已拥有
    local ownedLabel = display.newLabel(size.width/2, 38, {text = __('已拥有'), color = '#ffffff', fontSize = 26, ttf = true, font = TTF_GAME_FONT})
    view:addChild(ownedLabel, 1)
    return {
        size         = size,
        view         = view,
        bg           = bg,
        priceLabel   = priceLabel,
        currencyIcon = currencyIcon,
        ownedLabel   = ownedLabel,
        itemLayer    = itemLayer,
    }
end
-------------------- private --------------------
-------------------------------------------------

-------------------------------------------------
------------------- get / set -------------------
function CatHouseDressShopView:GetViewData()
    return self.viewData
end
------------------- get / set -------------------
-------------------------------------------------

return CatHouseDressShopView

--[[
 * author : kaishiqi
 * descpt : 2020周年庆 - 商店 视图
]]
local Anniversary20ShopView = class('Anniversary20ShopView', function()
    return ui.layer({name = 'Game.views.anniversary20.Anniversary20ShopView', enableEvent = true})
end)

local RES_DICT = {
    BG_FRAME    = _res('ui/home/union/guild_shop_bg.png'),
    VIEW_FRAME  = _res('ui/home/union/guild_shop_bg_white.png'),
    TITLE_BAR   = _res('ui/common/common_bg_title_2.png'),
    BTN_BATCH   = _res('ui/common/common_btn_orange.png'),
    BTN_REFRESH = _res('ui/home/commonShop/shop_btn_refresh.png'),
    GOODS_FRAME = _res('ui/common/common_bg_goods.png'),
    TYPE_TAB_D  = _res('ui/common/common_btn_tab_default.png'),
    TYPE_TAB_S  = _res('ui/common/common_btn_tab_select.png'),
    EMPTY_IMG   = _res('ui/common/common_bg_dialogue_tips.png'),
    --          = goods cell
    GOODS_BG_N  = _res('ui/home/commonShop/shop_btn_goods_default.png'),
    GOODS_BG_D  = _res('ui/home/commonShop/shop_btn_goods_sellout.png'),
}

local ACTION_ENUM = {
    RELOAD_PRODUCTS = 1,
}

local SHOP_TYPE_ENUM    = FOOD.ANNIV2020.SHOP.TYPE_ENUM
local SHOP_PROXY_NAME   = FOOD.ANNIV2020.SHOP.PROXY_NAME
local SHOP_PROXY_STRUCT = FOOD.ANNIV2020.SHOP.PROXY_STRUCT


function Anniversary20ShopView:ctor()
    self.productsIdList_ = {}
    self.productsIdxMap_ = {}

    -- bind model
    self.shopProxy_   = app:RetrieveProxy(SHOP_PROXY_NAME)
    self.viewBindMap_ = {
        [SHOP_PROXY_STRUCT.SELECT_TYPE]                                     = self.onUpdateSelectType_,
        [SHOP_PROXY_STRUCT.SHOP_HOME_TAKE.PRODUCTS]                         = self.onUpdateProductsGridView_,   -- clean all / update all
        [SHOP_PROXY_STRUCT.SHOP_HOME_TAKE.PRODUCTS.PRODUCT_DATA]            = self.onUpdateProductsGridView_,   -- add key / del key
        [SHOP_PROXY_STRUCT.SHOP_HOME_TAKE.PRODUCTS.PRODUCT_DATA.GOODS_NUM]  = self.onUpdateProductsGridCell_,
        [SHOP_PROXY_STRUCT.SHOP_HOME_TAKE.PRODUCTS.PRODUCT_DATA.STOCK_LEFT] = self.onUpdateProductsGridCell_,
    }
    
    -- create view
    local searchId = self.shopProxy_:get(SHOP_PROXY_STRUCT.SEARCH_GOODS_ID)
    self.viewData_ = Anniversary20ShopView.CreateView(searchId > 0)
    self:addChild(self.viewData_.view)

    -- init view
    self:getViewData().goodsGridView:setCellUpdateHandler(handler(self, self.onUpdateProductCellHandler_))

    -- update view
    local handlerList = VoProxy.EventBind(SHOP_PROXY_NAME, self.viewBindMap_, self)
    table.each(handlerList, function(_, v) v(self) end)
    self:updateShopTitle_()
end


function Anniversary20ShopView:onCleanup()
    VoProxy.EventUnbind(SHOP_PROXY_NAME, self.viewBindMap_, self)
end


function Anniversary20ShopView:getViewData()
    return self.viewData_
end


-------------------------------------------------
-- private

function Anniversary20ShopView:updateShopTitle_()
    local shopLevel = app.anniv2020Mgr:getShopLevel()
    self:getViewData().titleBar:updateLabel({text = string.fmt(__('_num_级商店'), {_num_ = shopLevel})})
end


-------------------------------------------------
-- handler

-- update selectType
function Anniversary20ShopView:onUpdateSelectType_(signal)
    local seletType = self.shopProxy_:get(SHOP_PROXY_STRUCT.SELECT_TYPE)

    -- update typeTabButtons
    for _, tButton in ipairs(self:getViewData().typeTabButtonList) do
        tButton:setChecked(checkint(tButton:getTag()) == seletType)
    end

    -- reload goodsGridView
    self:onUpdateProductsGridView_()
end


-- update productsGridView
function Anniversary20ShopView:onUpdateProductsGridView_(signal)
    -- reload goodsGridView （当同一时间填充多条数据时，会导致的连续触发刷新。所以action动作能保证在下一帧时直接刷新最终结果）
    if not self:getActionByTag(ACTION_ENUM.RELOAD_PRODUCTS) then
        self:runAction(cc.CallFunc:create(function()

            -- reset products idList/idxMap
            self.productsIdList_ = {}
            self.productsIdxMap_ = {}
            local cellDataIndex  = 1
            local searchGoodsId  = self.shopProxy_:get(SHOP_PROXY_STRUCT.SEARCH_GOODS_ID)
            local selectType     = self.shopProxy_:get(SHOP_PROXY_STRUCT.SELECT_TYPE)
            local CELL_STRUCT    = SHOP_PROXY_STRUCT.SHOP_HOME_TAKE.PRODUCTS.PRODUCT_DATA
            for productIndex = 1, self.shopProxy_:size(SHOP_PROXY_STRUCT.SHOP_HOME_TAKE.PRODUCTS) do
                local cellVoProxy  = self.shopProxy_:get(CELL_STRUCT, productIndex)
                local goodsId      = cellVoProxy:get(CELL_STRUCT.GOODS_ID)
                local isActivity   = cellVoProxy:get(CELL_STRUCT.ACTIVITY) == 1
                if (selectType == SHOP_TYPE_ENUM.ALL or 
                    (selectType == SHOP_TYPE_ENUM.ACTIVITY and isActivity)) or
                    (selectType == SHOP_TYPE_ENUM.COMMON and not isActivity) then
                    self.productsIdList_[cellDataIndex] = productIndex
                    self.productsIdxMap_[productIndex] = cellDataIndex
                    cellDataIndex = cellDataIndex + 1
                elseif selectType == SHOP_TYPE_ENUM.SEARCH then
                    if searchGoodsId == goodsId then
                        self.productsIdList_[cellDataIndex] = productIndex
                        self.productsIdxMap_[productIndex]  = cellDataIndex
                        break
                    end
                end
            end
            
            -- reload goodsGridView
            self:getViewData().goodsGridView:resetCellCount(#self.productsIdList_)
            self:getViewData().goodsEmptyLayer:setVisible(#self.productsIdList_ == 0)

        end)):setTag(ACTION_ENUM.RELOAD_PRODUCTS)
    end
end


-- update productsGridCell
function Anniversary20ShopView:onUpdateProductsGridCell_(signal)
    local updateCellIndex = signal and signal:GetBody().root:key() or 0
    local changedVoDefine = signal and signal:GetBody().voDefine or nil
    local cellDataIndex   = self.productsIdxMap_[updateCellIndex]
    self:getViewData().goodsGridView:updateCellViewData(cellDataIndex, nil, changedVoDefine)
end


-- update productCell （changedVoDefine = nil 表示刷新cell全部内容，否则表示刷新局部的内容）
function Anniversary20ShopView:onUpdateProductCellHandler_(cellIndex, cellViewData, changedVoDefine)
    if cellViewData == nil then return end

    -- get cell data
    local productsIndex = self.productsIdList_[cellIndex]
    local CELL_STRUCT   = SHOP_PROXY_STRUCT.SHOP_HOME_TAKE.PRODUCTS.PRODUCT_DATA
    local cellVoProxy   = self.shopProxy_:get(CELL_STRUCT, productsIndex)
    
    -- init cell status
    if changedVoDefine == nil then
        cellViewData.toggleView:setTag(productsIndex)
        cellViewData.leftTimesLabel:setTag(productsIndex)
    end

    -- update goods icon / name
    if changedVoDefine == nil or changedVoDefine == CELL_STRUCT.GOODS_ID then
        local goodsId = cellVoProxy:get(CELL_STRUCT.GOODS_ID)
        cellViewData.goodNode:setTouchEnabled(false)
        cellViewData.goodNode:RefreshSelf({goodsId = goodsId})
    end
    
    -- update goods number
    if changedVoDefine == nil or changedVoDefine == CELL_STRUCT.GOODS_NUM then
        local goodsNum = cellVoProxy:get(CELL_STRUCT.GOODS_NUM)
        cellViewData.goodNode:RefreshSelf({num = goodsNum})
    end

    -- update goods price
    if changedVoDefine == nil or changedVoDefine == CELL_STRUCT.PRICE_NUM then
        local goodsPrice = cellVoProxy:get(CELL_STRUCT.PRICE_NUM)
        cellViewData.numLabel:setString(tostring(goodsPrice))
    end

    -- update goods currency
    if changedVoDefine == nil or changedVoDefine == CELL_STRUCT.CURRENCY_ID then
        local currencyId = cellVoProxy:get(CELL_STRUCT.CURRENCY_ID)
        cellViewData.castIcon:setTexture(_res(CommonUtils.GetGoodsIconPathById(currencyId)))
        cellViewData.castIcon:setPositionX(cellViewData.numLabel:getPositionX() + cellViewData.numLabel:getBoundingBox().width/2 + 8)
    end

    -- update unlock level
    if changedVoDefine == nil or changedVoDefine == CELL_STRUCT.OPEN_LEVEL then
        local openLevel = cellVoProxy:get(CELL_STRUCT.OPEN_LEVEL)
        local shopLevel = app.anniv2020Mgr:getShopLevel()
        cellViewData.lockLabel:setVisible(shopLevel < openLevel)
        display.commonLabelParams(cellViewData.lockLabel, {text = string.fmt(__('_num_级商店解锁'), {_num_ = openLevel}), paddingH = 10})
    end

    -- update purchasedCount
    if changedVoDefine == nil or changedVoDefine == CELL_STRUCT.STOCK_LEFT then
        local purchasedCount = cellVoProxy:get(CELL_STRUCT.STOCK_LEFT)
        display.reloadRichLabel(cellViewData.leftTimesLabel, {c = {
            fontWithColor(8, {color = '#ac5a4a', text = string.fmt(__('剩余库存：_num_'), {_num_ = purchasedCount})})
        }})

        -- update purchased status
        local isPurchased = purchasedCount <= 0
        local cellBgImage = isPurchased and RES_DICT.GOODS_BG_D or RES_DICT.GOODS_BG_N
        cellViewData.sellLabel:setVisible(isPurchased)
        cellViewData.toggleView:setNormalImage(cellBgImage)
        cellViewData.toggleView:setSelectedImage(cellBgImage)
    end
end


-------------------------------------------------------------------------------
-- view struct
-------------------------------------------------------------------------------

function Anniversary20ShopView.CreateView(hasSearch)
    local view = ui.layer()
    local size = view:getContentSize()
    local cpos = cc.sizep(size, ui.cc)

    -- black layer
    view:add(ui.layer({color = cc.c4b(0,0,0,150)}))
    
    -- block layer
    local blockLayer = ui.layer({color = cc.r4b(0), enable = true})
    view:add(blockLayer)


    ------------------------------------------------- [top]
    local topLayer = ui.layer()
    view:add(topLayer)

    -- money bar
    local moneyBar = require('common.CommonMoneyBar').new({})
    moneyBar:reloadMoneyBar({ app.anniv2020Mgr:getShopCurrencyId() }, false, {
        [DIAMOND_ID] = {hidePlus = true, disable = true}
    })
    topLayer:add(moneyBar)


    ------------------------------------------------- [center]
    local centerLayer = ui.layer()
    view:add(centerLayer)

    centerLayer:addList(ui.image({img = RES_DICT.BG_FRAME})):alignTo(nil, ui.cc, {offsetY = -20})

    -- view frame
    local viewFrameNode = ui.layer({p = cc.rep(cpos, 0, -30), bg = RES_DICT.VIEW_FRAME, ap = ui.cc, enable = true})
    local viewFrameSize = viewFrameNode:getContentSize()
    centerLayer:add(viewFrameNode)

    -- title bar
    local titleBar = ui.title({img = RES_DICT.TITLE_BAR}):updateLabel({fnt = FONT.D3, text = __('周年庆商店'), paddingW = 60, safeW = 120, offset = cc.p(0,-2)})
    viewFrameNode:addList(titleBar):alignTo(nil, ui.ct, {offsetY = 37})


    -- type tab buttons
    local TYPE_TAB_DEFINES = {
        {type = SHOP_TYPE_ENUM.ACTIVITY, name = __('活动道具')},
        {type = SHOP_TYPE_ENUM.COMMON,   name = __('一般道具')},
    }
    if hasSearch then
        table.insert(TYPE_TAB_DEFINES, 1, {type = SHOP_TYPE_ENUM.SEARCH, name = __('搜索')})
    end
    local typeTabButtonList = {}
    for index, typeDefine in ipairs(TYPE_TAB_DEFINES) do
        local tButton = ui.tButton({n = RES_DICT.TYPE_TAB_D, s = RES_DICT.TYPE_TAB_S, tag = typeDefine.type})
        tButton:getNormalImage():addList(ui.label({fnt = FONT.TEXT20, color = '#E0BFB0', text = typeDefine.name})):alignTo(nil, ui.cc)
        tButton:getSelectedImage():addList(ui.label({fnt = FONT.TEXT20, color = '#C65825', text = typeDefine.name})):alignTo(nil, ui.cc)
        typeTabButtonList[index] = tButton
    end
    viewFrameNode:addList(typeTabButtonList)
    ui.flowLayout(cc.rep(cc.sizep(viewFrameSize, ui.lt), 40, -50), typeTabButtonList, {type = flowH, ap = ui.lc, gapW = 10})


    -- goods frame
    local goodsFrameSize = cc.resize(viewFrameSize, -24, -80)
    local goodsFrameGroup = viewFrameNode:addList({
        ui.image({img = RES_DICT.GOODS_FRAME, size = goodsFrameSize, scale9 = true}),
        ui.gridView({cols = 5, size = cc.resize(goodsFrameSize, -6, -6), csizeH = 285, dir = display.SDIR_V}),
        ui.layer({size = goodsFrameSize}),
    })
    ui.flowLayout(cc.rep(cc.sizep(viewFrameSize, ui.cc), 0, -30), goodsFrameGroup, {type = ui.flowC, ap = ui.cc})
    goodsFrameGroup[2]:setCellCreateClass(require('Game.views.CommonShopCell'))


    -- empty layer
    local goodsEmptyLayer = goodsFrameGroup[3]
    local goodsEmptyGroup = goodsEmptyLayer:addList({
        ui.title({img = RES_DICT.EMPTY_IMG, cut = cc.dir(135,10,65,92)}):updateLabel({fnt = FONT.D6, w = 220, text = __('暂无该道具'), paddingH = 40, hAlign = display.TAC}),
        ui.image({img = AssetsUtils.GetCartoonPath(3), scale = 0.45}),
    })
    ui.flowLayout(cc.sizep(goodsEmptyLayer, ui.cc), goodsEmptyGroup, {type = ui.flowH, ap = ui.cc})
    

    return {
        view              = view,
        blackLayer        = blackLayer,
        blockLayer        = blockLayer,
        --                = top
        topLayer          = topLayer,
        moneyBar          = moneyBar,
        --                = center
        titleBar          = titleBar,
        goodsGridView     = goodsFrameGroup[2],
        goodsEmptyLayer   = goodsFrameGroup[3],
        typeTabButtonList = typeTabButtonList,
    }
end


return Anniversary20ShopView

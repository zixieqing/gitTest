--[[
 * descpt : 新天成演武 - 商店视图
]]
local CommonMoneyBar   = require('common.CommonMoneyBar')
local NewKofArenaShopView = class('NewKofArenaShopView', function()
    return ui.layer({name = 'Game.views.tagMatchNew.NewKofArenaShopView', enableEvent = true})
end)

local RES_DICT = {
    BG_FRAME    = _res('ui/home/union/guild_shop_bg.png'),
    VIEW_FRAME  = _res('ui/home/union/guild_shop_bg_white.png'),
    TITLE_BAR   = _res('ui/common/common_bg_title_2.png'),
    BTN_BATCH   = _res('ui/common/common_btn_orange.png'),
    BTN_REFRESH = _res('ui/home/commonShop/shop_btn_refresh.png'),
    GOODS_FRAME = _res('ui/common/common_bg_goods.png'),
    --          = goods cell
    GOODS_BG_N  = _res('ui/home/commonShop/shop_btn_goods_default.png'),
    GOODS_BG_D  = _res('ui/home/commonShop/shop_btn_goods_sellout.png'),
}

local ACTION_ENUM = {
    RELOAD_PRODUCTS = 1,
}

local SHOP_PROXY_NAME   = FOOD.NEW_KOF.SHOP.PROXY_NAME
local SHOP_PROXY_STRUCT = FOOD.NEW_KOF.SHOP.PROXY_STRUCT


function NewKofArenaShopView:ctor()
    -- create view
    self.viewData_ = NewKofArenaShopView.CreateView()
    self:addChild(self.viewData_.view)

    -- init view
    self:getViewData().goodsGridView:setCellUpdateHandler(handler(self, self.onUpdateProductCellHandler_))

    -- bind model
    self.shopProxy_   = app:RetrieveProxy(SHOP_PROXY_NAME)
    self.viewBindMap_ = {
        [SHOP_PROXY_STRUCT.SHOP_HOME_TAKE.REFRESH_LEFT_SECONDS]             = self.onUpdateRefreshLeftSeconds_,
        [SHOP_PROXY_STRUCT.SHOP_HOME_TAKE.PRODUCTS]                         = self.onUpdateProductsGridView_,   -- clean all / update all
        [SHOP_PROXY_STRUCT.SHOP_HOME_TAKE.PRODUCTS.PRODUCT_DATA]            = self.onUpdateProductsGridView_,   -- add key / del key
        [SHOP_PROXY_STRUCT.SHOP_HOME_TAKE.PRODUCTS.PRODUCT_DATA.GOODS_NUM]  = self.onUpdateProductsGridCell_,
        [SHOP_PROXY_STRUCT.SHOP_HOME_TAKE.PRODUCTS.PRODUCT_DATA.STOCK_LEFT] = self.onUpdateProductsGridCell_,
    }

    -- update view
    local handlerList = VoProxy.EventBind(SHOP_PROXY_NAME, self.viewBindMap_, self)
    table.each(handlerList, function(_, v) v(self) end)
end


function NewKofArenaShopView:onCleanup()
    VoProxy.EventUnbind(SHOP_PROXY_NAME, self.viewBindMap_, self)
end


function NewKofArenaShopView:getViewData()
    return self.viewData_
end


-------------------------------------------------
-- handler

-- update refreshLeftSeconds
function NewKofArenaShopView:onUpdateRefreshLeftSeconds_(signal)
    local leftSeconds = signal and signal:GetBody().newValue or 0
    local refreshText = string.fmt(__('商品刷新倒计时：_time_'), {_time_ = CommonUtils.getTimeFormatByType(leftSeconds, 3)})
    self:getViewData().refreshTimeLabel:updateLabel({text = refreshText})
end


-- update productsGridView
function NewKofArenaShopView:onUpdateProductsGridView_(signal)
    -- reload goodsGridView （当同一时间填充多条数据时，会导致的连续触发刷新。所以action动作能保证在下一帧时直接刷新最终结果）
    if not self:getActionByTag(ACTION_ENUM.RELOAD_PRODUCTS) then
        self:runAction(cc.CallFunc:create(function()
            local productCount = self.shopProxy_:size(SHOP_PROXY_STRUCT.SHOP_HOME_TAKE.PRODUCTS)
            self:getViewData().goodsGridView:resetCellCount(productCount)
        end)):setTag(ACTION_ENUM.RELOAD_PRODUCTS)
    end
end


-- update productsGridCell
function NewKofArenaShopView:onUpdateProductsGridCell_(signal)
    local updateCellIndex = signal and signal:GetBody().root:key() or 0
    local changedVoDefine = signal and signal:GetBody().voDefine or nil
    self:getViewData().goodsGridView:updateCellViewData(updateCellIndex, nil, changedVoDefine)
end


-- update productCell （changedVoDefine = nil 表示刷新cell全部内容，否则表示刷新局部的内容）
function NewKofArenaShopView:onUpdateProductCellHandler_(cellIndex, cellViewData, changedVoDefine)
    if cellViewData == nil then return end

    -- get cell data
    local CELL_STRUCT = SHOP_PROXY_STRUCT.SHOP_HOME_TAKE.PRODUCTS.PRODUCT_DATA
    local cellVoProxy = self.shopProxy_:get(CELL_STRUCT, cellIndex)
    
    -- init cell status
    if changedVoDefine == nil then
        cellViewData.toggleView:setTag(cellIndex)
        cellViewData.leftTimesLabel:setTag(cellIndex)
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
        -- local openLevel = cellVoProxy:get(CELL_STRUCT.OPEN_LEVEL)
        -- cellViewData.lockLabel:setVisible(app.waterBarMgr:getBarLevel() < openLevel)  -- TODO 据说没有等级限制
        -- display.commonLabelParams(cellViewData.lockLabel, {text = string.fmt(__('_num_级演武解锁'), {_num_ = openLevel}), paddingH = 10})
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

function NewKofArenaShopView.CreateView()
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
    local moneyBar = CommonMoneyBar.new()
    moneyBar:reloadMoneyBar({FOOD.GOODS.DEFINE.NEW_KOF_CURRENCY_ID}, false, {
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
    local titleBar = ui.title({img = RES_DICT.TITLE_BAR}):updateLabel({fnt = FONT.D3, text = __('演武商店'), paddingW = 60, safeW = 120, offset = cc.p(0,-2)})
    viewFrameNode:addList(titleBar):alignTo(nil, ui.ct, {offsetY = 37})


    -- batch buy button
	local batchBuyBtn = ui.button({n = RES_DICT.BTN_BATCH, scale9 = true, ap = ui.lc}):updateLabel({fnt = FONT.D14, text = __('快速购买'), paddingW = 20, safeW = 100})
    viewFrameNode:addList(batchBuyBtn):alignTo(nil, ui.lt, {offsetX = 25, offsetY = -10})
    
    -- refresh time label
	local refreshTimeLabel = ui.label({fnt = FONT.D16, ap = ui.lc})
    viewFrameNode:addList(refreshTimeLabel):alignTo(batchBuyBtn, ui.rc, {offsetX = 20})
    
    
    -- goods grid
    local goodsFrameSize = cc.resize(viewFrameSize, -24, -85)
    local goodsGridGroup = viewFrameNode:addList({
        ui.image({img = RES_DICT.GOODS_FRAME, size = goodsFrameSize, scale9 = true}),
        ui.gridView({cols = 5, size = cc.resize(goodsFrameSize, -6, -6), csizeH = 260, dir = display.SDIR_V})
    })
    ui.flowLayout(cc.rep(cc.sizep(viewFrameSize, ui.cc), 0, -32), goodsGridGroup, {type = ui.flowC, ap = ui.cc})
    goodsGridGroup[2]:setCellCreateClass(require('Game.views.CommonShopCell'))
    

    return {
        view              = view,
        blockLayer        = blockLayer,
        --                = top
        topLayer          = topLayer,
        moneyBar          = moneyBar,
        --                = center
        batchBuyBtn       = batchBuyBtn,
        refreshTimeLabel  = refreshTimeLabel,
        goodsGridView     = goodsGridGroup[2],
    }
end


return NewKofArenaShopView

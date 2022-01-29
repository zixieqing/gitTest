--[[
 * author : kaishiqi
 * descpt : 武道会 - 商店视图
]]
local CommonMoneyBar       = require('common.CommonMoneyBar')
local ChampionshipShopView = class('ChampionshipShopView', function()
    return ui.layer({name = 'Game.views.championship.ChampionshipShopView', enableEvent = true})
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

local SHOP_PROXY_NAME   = FOOD.CHAMPIONSHIP.SHOP.PROXY_NAME
local SHOP_PROXY_STRUCT = FOOD.CHAMPIONSHIP.SHOP.PROXY_STRUCT


function ChampionshipShopView:ctor()
    -- create view
    self.viewData_ = ChampionshipShopView.CreateView()
    self:addChild(self.viewData_.view)

    -- init view
    self:getViewData().goodsGridView:setCellUpdateHandler(handler(self, self.onUpdateProductCellHandler_))

    -- bind model
    self.shopProxy_   = app:RetrieveProxy(SHOP_PROXY_NAME)
    self.viewBindMap_ = {
        [SHOP_PROXY_STRUCT.SHOP_HOME_TAKE.REFRESH_DIAMOND]                 = self.onUpdateRefreshCostDiamond_,
        [SHOP_PROXY_STRUCT.SHOP_HOME_TAKE.REFRESH_LEFT_TIEMS]              = self.onUpdateRefreshLeftTimes_,
        [SHOP_PROXY_STRUCT.SHOP_HOME_TAKE.REFRESH_LEFT_SECONDS]            = self.onUpdateRefreshLeftSeconds_,
        [SHOP_PROXY_STRUCT.SHOP_HOME_TAKE.PRODUCTS]                        = self.onUpdateProductsGridView_,   -- clean all / update all
        [SHOP_PROXY_STRUCT.SHOP_HOME_TAKE.PRODUCTS.PRODUCT_DATA]           = self.onUpdateProductsGridView_,   -- add key / del key
        [SHOP_PROXY_STRUCT.SHOP_HOME_TAKE.PRODUCTS.PRODUCT_DATA.GOODS_NUM] = self.onUpdateProductsGridCell_,
        [SHOP_PROXY_STRUCT.SHOP_HOME_TAKE.PRODUCTS.PRODUCT_DATA.PURCHASED] = self.onUpdateProductsGridCell_,
    }

    -- update view
    local handlerList = VoProxy.EventBind(SHOP_PROXY_NAME, self.viewBindMap_, self)
    table.each(handlerList, function(_, v) v(self) end)
end


function ChampionshipShopView:onCleanup()
    VoProxy.EventUnbind(SHOP_PROXY_NAME, self.viewBindMap_, self)
end


function ChampionshipShopView:getViewData()
    return self.viewData_
end


-------------------------------------------------
-- handler

-- update refreshLeftTimes
function ChampionshipShopView:onUpdateRefreshLeftTimes_(signal)
    local leftTimes   = signal and signal:GetBody().newValue or 0
    local refreshText = string.fmt(__('今日剩余刷新次数：_num_'), {_num_ = leftTimes})
    self:getViewData().refreshLeftLabel:updateLabel({text = refreshText})
end


-- update refreshCostDiamond
function ChampionshipShopView:onUpdateRefreshCostDiamond_(signal)
    local costDiamond = signal and signal:GetBody().newValue or 0
    self:getViewData().refreshCostRLabel:reload({
        {fnt = FONT.D16, text = tostring(costDiamond)},
        {img = CommonUtils.GetGoodsIconPathById(DIAMOND_ID), scale = 0.17}
    })
end


-- update refreshLeftSeconds
function ChampionshipShopView:onUpdateRefreshLeftSeconds_(signal)
    local leftSeconds = signal and signal:GetBody().newValue or 0
    local refreshText = string.fmt(__('系统刷新倒计时：_time_'), {_time_ = CommonUtils.getTimeFormatByType(leftSeconds, 3)})
    self:getViewData().refreshTimeLabel:updateLabel({text = refreshText})
end


-- update productsGridView
function ChampionshipShopView:onUpdateProductsGridView_(signal)
    -- reload goodsGridView （当同一时间填充多条数据时，会导致的连续触发刷新。所以action动作能保证在下一帧时直接刷新最终结果）
    if not self:getActionByTag(ACTION_ENUM.RELOAD_PRODUCTS) then
        self:runAction(cc.CallFunc:create(function()
            local productCount = self.shopProxy_:size(SHOP_PROXY_STRUCT.SHOP_HOME_TAKE.PRODUCTS)
            self:getViewData().goodsGridView:resetCellCount(productCount)
        end)):setTag(ACTION_ENUM.RELOAD_PRODUCTS)
    end
end


-- update productsGridCell
function ChampionshipShopView:onUpdateProductsGridCell_(signal)
    local updateCellIndex = signal and signal:GetBody().root:key() or 0
    local changedVoDefine = signal and signal:GetBody().voDefine or nil
    self:getViewData().goodsGridView:updateCellViewData(updateCellIndex, nil, changedVoDefine)
end


-- update productCell （changedVoDefine = nil 表示刷新cell全部内容，否则表示刷新局部的内容）
function ChampionshipShopView:onUpdateProductCellHandler_(cellIndex, cellViewData, changedVoDefine)
    if cellViewData == nil then return end

    -- get cell data
    local CELL_STRUCT = SHOP_PROXY_STRUCT.SHOP_HOME_TAKE.PRODUCTS.PRODUCT_DATA
    local cellVoProxy = self.shopProxy_:get(CELL_STRUCT, cellIndex)
    
    -- init cell status
    if changedVoDefine == nil then
        cellViewData.toggleView:setTag(cellIndex)
        cellViewData.leftTimesLabel:setTag(cellIndex)
        cellViewData.leftTimesLabel:setVisible(false)
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
    if changedVoDefine == nil then
        local goodsPrice = cellVoProxy:get(CELL_STRUCT.PRICE_NUM)
        cellViewData.numLabel:setString(tostring(goodsPrice))
    end

    -- update goods currency
    if changedVoDefine == nil then
        local currencyId = cellVoProxy:get(CELL_STRUCT.CURRENCY_ID)
        cellViewData.castIcon:setTexture(_res(CommonUtils.GetGoodsIconPathById(currencyId)))
        cellViewData.castIcon:setPositionX(cellViewData.numLabel:getPositionX() + cellViewData.numLabel:getBoundingBox().width/2 + 8)
    end

    -- update purchased status
    if changedVoDefine == nil or changedVoDefine == CELL_STRUCT.PURCHASED then
        local isPurchased = cellVoProxy:get(CELL_STRUCT.PURCHASED) == 1
        local cellBgImage = isPurchased and RES_DICT.GOODS_BG_D or RES_DICT.GOODS_BG_N
        cellViewData.sellLabel:setVisible(isPurchased)
        cellViewData.toggleView:setNormalImage(cellBgImage)
        cellViewData.toggleView:setSelectedImage(cellBgImage)
    end
end


-------------------------------------------------------------------------------
-- view struct
-------------------------------------------------------------------------------

function ChampionshipShopView.CreateView()
    local view = ui.layer()
    local size = view:getContentSize()
    local cpos = cc.sizep(size, ui.cc)

    -- black / block layer
    local backGroundGroup = view:addList({
        ui.layer({color = cc.c4b(0,0,0,150)}),
        ui.layer({color = cc.r4b(0), enable = true}),
    })


    ------------------------------------------------- [top]
    local topLayer = ui.layer()
    view:add(topLayer)

    -- money bar
    local moneyBar = CommonMoneyBar.new()
    moneyBar:reloadMoneyBar({FOOD.GOODS.DEFINE.CHAMPIONSHIP_CURRENCY_ID}, false, {
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
    local titleBar = ui.title({img = RES_DICT.TITLE_BAR}):updateLabel({fnt = FONT.D3, text = __('印记商店'), paddingW = 60, safeW = 120, offset = cc.p(0,-2)})
    viewFrameNode:addList(titleBar):alignTo(nil, ui.ct, {offsetY = 37})


    -- batch buy button
	local batchBuyBtn = ui.button({n = RES_DICT.BTN_BATCH, scale9 = true, ap = ui.lc}):updateLabel({fnt = FONT.D14, text = __('快速购买'), paddingW = 20, safeW = 100})
    viewFrameNode:addList(batchBuyBtn):alignTo(nil, ui.lt, {offsetX = 25, offsetY = -10})
    
    -- refresh time label
	local refreshTimeLabel = ui.label({fnt = FONT.D16, ap = ui.lc})
    viewFrameNode:addList(refreshTimeLabel):alignTo(batchBuyBtn, ui.rc, {offsetX = 20})
    
    
    -- refresh button
	local refreshBtn = ui.button({n = RES_DICT.BTN_REFRESH})
    viewFrameNode:addList(refreshBtn):alignTo(nil, ui.rt, {offsetX = -10, offsetY = 10})
    
    -- refresh left label
	local refreshLeftLabel = ui.label({fnt = FONT.D16, ap = ui.rc})
    viewFrameNode:addList(refreshLeftLabel):alignTo(refreshBtn, ui.lc, {offsetY = 10})
    
    -- refresh cost rlabel
	local refreshCostRLabel = ui.rLabel({ap = ui.rc})
    viewFrameNode:addList(refreshCostRLabel):alignTo(refreshBtn, ui.lc, {offsetY = -17})
    

    -- goods grid
    local goodsFrameSize = cc.resize(viewFrameSize, -24, -85)
    local goodsGridGroup = viewFrameNode:addList({
        ui.image({img = RES_DICT.GOODS_FRAME, size = goodsFrameSize, scale9 = true}),
        ui.gridView({cols = 5, size = cc.resize(goodsFrameSize, -6, -6), csizeH = 285, dir = display.SDIR_V})
    })
    ui.flowLayout(cc.rep(cc.sizep(viewFrameSize, ui.cc), 0, -32), goodsGridGroup, {type = ui.flowC, ap = ui.cc})
    goodsGridGroup[2]:setCellCreateClass(require('Game.views.CommonShopCell'))
    

    return {
        view              = view,
        blackLayer        = backGroundGroup[1],
        blockLayer        = backGroundGroup[2],
        --                = top
        topLayer          = topLayer,
        moneyBar          = moneyBar,
        --                = center
        batchBuyBtn       = batchBuyBtn,
        refreshBtn        = refreshBtn,
        refreshTimeLabel  = refreshTimeLabel,
        refreshLeftLabel  = refreshLeftLabel,
        refreshCostRLabel = refreshCostRLabel,
        goodsGridView     = goodsGridGroup[2],
    }
end


return ChampionshipShopView

--[[
 * author : kaishiqi
 * descpt : 水吧 - 市场视图
]]
local CommonMoneyBar     = require('common.CommonMoneyBar')
local WaterBarMarketView = class('WaterBarMarketView', function()
    return ui.layer({name = 'Game.views.waterBar.WaterBarMarketView', enableEvent = true})
end)

local RES_DICT = {
    BG_FRAME    = _res('ui/common/common_bg_13.png'),
    TITLE_BAR   = _res('ui/common/common_bg_title_2.png'),
    BTN_BATCH   = _res('ui/common/common_btn_orange.png'),
    BTN_REFRESH = _res('ui/common/common_btn_orange.png'),
    TYPE_TAB_D  = _res('ui/common/common_btn_tab_default.png'),
    TYPE_TAB_S  = _res('ui/common/common_btn_tab_select.png'),
    EMPTY_IMG   = _res('ui/common/common_bg_dialogue_tips.png'),
    --          = goods cell
    GOODS_BG    = _res('ui/waterBar/market/bar_bg_shop_list.png'),
    GOODS_FRAME = _res('ui/common/compose_frame_unused.png'),
    GOODS_WARD  = _res('ui/home/union/guild_shop_lock_wrod.png'),
}

local ACTION_ENUM = {
    RELOAD_PRODUCTS = 1,
}

local MARKET_PROXY_NAME   = FOOD.WATER_BAR.MARKET.PROXY_NAME
local MARKET_PROXY_STRUCT = FOOD.WATER_BAR.MARKET.PROXY_STRUCT


function WaterBarMarketView:ctor()
    self.productsIdList_ = {}
    self.productsIdxMap_ = {}

    -- bind model
    self.marketProxy_ = app:RetrieveProxy(MARKET_PROXY_NAME)
    self.viewBindMap_ = {
        [MARKET_PROXY_STRUCT.SELECT_MATERIAL_TYPE]                             = self.onUpdateSelectMaterialType_,
        [MARKET_PROXY_STRUCT.MARKET_CURRENCY_ID]                               = self.onUpdateMarketCurrencyId_,
        [MARKET_PROXY_STRUCT.MARKET_HOME_TAKE.REFRESH_DIAMOND]                 = self.onUpdateRefreshCostDiamond_,
        [MARKET_PROXY_STRUCT.MARKET_HOME_TAKE.REFRESH_LEFT_SECONDS]            = self.onUpdateRefreshLeftSeconds_,
        [MARKET_PROXY_STRUCT.MARKET_HOME_TAKE.PRODUCTS]                        = self.onUpdateProductsGridView_,   -- clean all / update all
        [MARKET_PROXY_STRUCT.MARKET_HOME_TAKE.PRODUCTS.PRODUCT_DATA]           = self.onUpdateProductsGridView_,   -- add key / del key
        [MARKET_PROXY_STRUCT.MARKET_HOME_TAKE.PRODUCTS.PRODUCT_DATA.GOODS_NUM] = self.onUpdateProductsGridCell_,
        [MARKET_PROXY_STRUCT.MARKET_HOME_TAKE.PRODUCTS.PRODUCT_DATA.PURCHASED] = self.onUpdateProductsGridCell_,
    }

    -- create view
    local searchId = self.marketProxy_:get(MARKET_PROXY_STRUCT.SEARCH_GOODS_ID)
    self.viewData_ = WaterBarMarketView.CreateView(searchId > 0)
    self:addChild(self.viewData_.view)

    -- init view
    self:getViewData().goodsGridView:setCellUpdateHandler(handler(self, self.onUpdateProductCellHandler_))

    -- update view
    local handlerList = VoProxy.EventBind(MARKET_PROXY_NAME, self.viewBindMap_, self)
    table.each(handlerList, function(_, v) v(self) end)
end


function WaterBarMarketView:onCleanup()
    VoProxy.EventUnbind(MARKET_PROXY_NAME, self.viewBindMap_, self)
end


function WaterBarMarketView:getViewData()
    return self.viewData_
end


-------------------------------------------------
-- handler

-- update refreshCostDiamond
function WaterBarMarketView:onUpdateRefreshCostDiamond_(signal)
    local costDiamond = signal and signal:GetBody().newValue or 0
    self:getViewData().refreshCostRLabel:reload({
        {fnt = FONT.D8, text = tostring(costDiamond)},
        {img = CommonUtils.GetGoodsIconPathById(DIAMOND_ID), scale = 0.15}
    })
end


-- update refreshLeftSeconds
function WaterBarMarketView:onUpdateRefreshLeftSeconds_(signal)
    local leftSeconds = signal and signal:GetBody().newValue or 0
    local refreshText = CommonUtils.getTimeFormatByType(leftSeconds, 3)
    self:getViewData().refreshTimeLabel:updateLabel({text = refreshText})
end


-- update selectMaterialType
function WaterBarMarketView:onUpdateSelectMaterialType_(signal)
    local seletType = signal and signal:GetBody().newValue or 0

    -- update typeTabButtons
    for _, tButton in ipairs(self:getViewData().typeTabButtonList) do
        tButton:setChecked(checkint(tButton:getTag()) == seletType)
    end

    -- reload goodsGridView
    self:onUpdateProductsGridView_()
end


-- udpate moneyBar
function WaterBarMarketView:onUpdateMarketCurrencyId_(signal)
    local currencyId = signal and signal:GetBody().newValue or 0
    self:getViewData().moneyBar:reloadMoneyBar(currencyId > 0 and {currencyId} or {})
end


-- update productsGridView
function WaterBarMarketView:onUpdateProductsGridView_(signal)
    -- reload goodsGridView （当同一时间填充多条数据时，会导致的连续触发刷新。所以action动作能保证在下一帧时直接刷新最终结果）
    if not self:getActionByTag(ACTION_ENUM.RELOAD_PRODUCTS) then
        self:runAction(cc.CallFunc:create(function()

            -- reset products idList/idxMap
            self.productsIdList_ = {}
            self.productsIdxMap_ = {}
            local cellDataIndex  = 1
            local searchGoodsId  = self.marketProxy_:get(MARKET_PROXY_STRUCT.SEARCH_GOODS_ID)
            local selectType     = self.marketProxy_:get(MARKET_PROXY_STRUCT.SELECT_MATERIAL_TYPE)
            local CELL_STRUCT    = MARKET_PROXY_STRUCT.MARKET_HOME_TAKE.PRODUCTS.PRODUCT_DATA
            for productIndex = 1, self.marketProxy_:size(MARKET_PROXY_STRUCT.MARKET_HOME_TAKE.PRODUCTS) do
                local cellVoProxy  = self.marketProxy_:get(CELL_STRUCT, productIndex)
                local materialId   = cellVoProxy:get(CELL_STRUCT.GOODS_ID)
                local materialConf = CONF.BAR.MATERIAL:GetValue(materialId)
                if selectType == FOOD.WATER_BAR.MATERIAL_TYPE.ALL or selectType == checkint(materialConf.materialType) then
                    self.productsIdList_[cellDataIndex] = productIndex
                    self.productsIdxMap_[productIndex] = cellDataIndex
                    cellDataIndex = cellDataIndex + 1
                elseif selectType == FOOD.WATER_BAR.MATERIAL_TYPE.SEARCH then
                    if searchGoodsId == materialId then
                        self.productsIdList_[cellDataIndex] = productIndex
                        self.productsIdxMap_[productIndex] = cellDataIndex
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
function WaterBarMarketView:onUpdateProductsGridCell_(signal)
    local updateCellIndex = signal and signal:GetBody().root:key() or 0
    local changedVoDefine = signal and signal:GetBody().voDefine or nil
    local cellDataIndex   = self.productsIdxMap_[updateCellIndex]
    self:getViewData().goodsGridView:updateCellViewData(cellDataIndex, nil, changedVoDefine)
end


-- update productCell （changedVoDefine = nil 表示刷新cell全部内容，否则表示刷新局部的内容）
function WaterBarMarketView:onUpdateProductCellHandler_(cellIndex, cellViewData, changedVoDefine)
    if cellViewData == nil then return end

    -- get cell data
    local productsIndex = self.productsIdList_[cellIndex]
    local CELL_STRUCT   = MARKET_PROXY_STRUCT.MARKET_HOME_TAKE.PRODUCTS.PRODUCT_DATA
    local cellVoProxy   = self.marketProxy_:get(CELL_STRUCT, productsIndex)
    
    -- init cell status
    if changedVoDefine == nil then
        -- update cell tag
        cellViewData.clickArea:setTag(productsIndex)

        -- update goods icon / name
        local goodsId = cellVoProxy:get(CELL_STRUCT.GOODS_ID)
        cellViewData.goodsNode:RefreshSelf({goodsId = goodsId})
        cellViewData.nameLabel:updateLabel({text = CommonUtils.GetCacheProductName(goodsId)})

        -- update goods price
        local goodsPrice = cellVoProxy:get(CELL_STRUCT.PRICE_NUM)
        cellViewData.priceLabel:updateLabel({text = tostring(goodsPrice), paddingW = 20, safeW = 60})

        -- update goods currency
        local currencyId = cellVoProxy:get(CELL_STRUCT.CURRENCY_ID)
        cellViewData.priceLayer:addAndClear(ui.goodsImg({goodsId = currencyId, scale = 0.27}))
    end

    -- update goods number
    if changedVoDefine == nil or changedVoDefine == CELL_STRUCT.GOODS_NUM then
        local goodsNum = cellVoProxy:get(CELL_STRUCT.GOODS_NUM)
        cellViewData.goodsNode:RefreshSelf({num = goodsNum})
    end

    -- update purchased status
    if changedVoDefine == nil or changedVoDefine == CELL_STRUCT.PURCHASED then
        local isPurchased = cellVoProxy:get(CELL_STRUCT.PURCHASED) == 1
        cellViewData.soldMark:setVisible(isPurchased)
    end
end


-------------------------------------------------------------------------------
-- view struct
-------------------------------------------------------------------------------

function WaterBarMarketView.CreateView(hasSearch)
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
    topLayer:add(moneyBar)


    ------------------------------------------------- [center]
    local centerLayer = ui.layer()
    view:add(centerLayer)

    -- view frame
    local viewFrameNode = ui.layer({p = cc.rep(cpos, 0, -30), bg = RES_DICT.BG_FRAME, ap = ui.cc, enable = true})
    local viewFrameSize = viewFrameNode:getContentSize()
    centerLayer:add(viewFrameNode)

    -- title bar
    local titleBar = ui.title({img = RES_DICT.TITLE_BAR}):updateLabel({fnt = FONT.D3, text = __('水吧市场'), paddingW = 60, safeW = 120, offset = cc.p(0,-2)})
    viewFrameNode:addList(titleBar):alignTo(nil, ui.ct, {offsetY = -11})


    -- batch buy button
	local batchBuyBtn = ui.button({n = RES_DICT.BTN_BATCH, scale9 = true}):updateLabel({fnt = FONT.D14, text = __('快速购买'), paddingW = 20, safeW = 100})
    viewFrameNode:addList(batchBuyBtn):alignTo(nil, ui.rb, {offsetX = -75, offsetY = 25})

    -- expire tips
    local expireTips = ui.label({fnt = FONT.D8, text = __('所有今天购买的食材隔日都将过期，系统会帮你自动清理掉。'), w = 330, hAlign = display.TAC})
    viewFrameNode:addList(expireTips):alignTo(nil, ui.cb, {offsetY = 35})
    
    
    -- refresh button
	local refreshBtn = ui.button({n = RES_DICT.BTN_REFRESH}):updateLabel({fnt = FONT.D14, fontSize = 18, text = __('立即刷新'), paddingW = 20, offset = cc.p(0,6)})
    viewFrameNode:addList(refreshBtn):alignTo(nil, ui.rt, {offsetX = -60, offsetY = -65})
    
    -- refresh cost rlabel
	local refreshCostRLabel = ui.rLabel({ap = ui.cc})
    refreshBtn:addList(refreshCostRLabel):alignTo(nil, ui.cc, {offsetY = -10})

    -- refresh time label
    local refreshTimeIntro = ui.label({fnt = FONT.D8, ap = ui.rc, text = __('系统刷新')})
    local refreshTimeLabel = ui.label({fnt = FONT.D8, ap = ui.rc, text = '--:--:--'})
    viewFrameNode:addList(refreshTimeIntro):alignTo(refreshBtn, ui.lc, {offsetX = -5, offsetY = 13})
    viewFrameNode:addList(refreshTimeLabel):alignTo(refreshBtn, ui.lc, {offsetX = -5, offsetY = -13})


    -- type tab buttons
    local TYPE_TAB_DEFINES = {
        {type = FOOD.WATER_BAR.MATERIAL_TYPE.BASIC,   name = __('基酒')},
        {type = FOOD.WATER_BAR.MATERIAL_TYPE.FLAVOUR, name = __('调味酒')},
        {type = FOOD.WATER_BAR.MATERIAL_TYPE.OTHER,   name = __('其他')},
    }
    if hasSearch then
        table.insert(TYPE_TAB_DEFINES, 1, {type = FOOD.WATER_BAR.MATERIAL_TYPE.SEARCH, name = __('搜索')})
    end
    local typeTabButtonList = {}
    for index, typeDefine in ipairs(TYPE_TAB_DEFINES) do
        local tButton = ui.tButton({n = RES_DICT.TYPE_TAB_D, s = RES_DICT.TYPE_TAB_S, tag = typeDefine.type})
        tButton:getNormalImage():addList(ui.label({fnt = FONT.TEXT20, color = '#E0BFB0', text = typeDefine.name})):alignTo(nil, ui.cc)
        tButton:getSelectedImage():addList(ui.label({fnt = FONT.TEXT20, color = '#C65825', text = typeDefine.name})):alignTo(nil, ui.cc)
        typeTabButtonList[index] = tButton
    end
    viewFrameNode:addList(typeTabButtonList)
    ui.flowLayout(cc.rep(cc.sizep(viewFrameSize, ui.lt), 70, -110), typeTabButtonList, {type = flowH, ap = ui.lc, gapW = 10})


    -- goods frame
    local goodsFrameSize = cc.resize(viewFrameSize, -120, -225)
    local goodsFrameGroup = viewFrameNode:addList({
        ui.image({img = RES_DICT.GOODS_FRAME, scale9 = true, size = goodsFrameSize}),
        ui.gridView({cols = 3, size = cc.resize(goodsFrameSize, -12, -6), csizeH = 130, dir = display.SDIR_V}),
        ui.layer({size = goodsFrameSize}),
    })
    ui.flowLayout(cc.rep(cc.sizep(viewFrameSize, ui.cc), 0, -18), goodsFrameGroup, {type = ui.flowC, ap = ui.cc})
    goodsFrameGroup[2]:setCellCreateHandler(WaterBarMarketView.CreateGoodsCell)

    local goodsEmptyLayer = goodsFrameGroup[3]
    local goodsEmptyGroup = goodsEmptyLayer:addList({
        ui.title({img = RES_DICT.EMPTY_IMG, cut = cc.dir(135,10,65,92)}):updateLabel({fnt = FONT.D6, w = 220, text = __('暂无该类食材'), paddingH = 40, hAlign = display.TAC}),
        ui.image({img = AssetsUtils.GetCartoonPath(3), scale = 0.45}),
    })
    ui.flowLayout(cc.sizep(goodsEmptyLayer, ui.cc), goodsEmptyGroup, {type = ui.flowH, ap = ui.cc})

    return {
        view              = view,
        blockLayer        = blockLayer,
        --                = top
        topLayer          = topLayer,
        moneyBar          = moneyBar,
        --                = center
        batchBuyBtn       = batchBuyBtn,
        refreshBtn        = refreshBtn,
        refreshTimeLabel  = refreshTimeLabel,
        refreshCostRLabel = refreshCostRLabel,
        goodsGridView     = goodsFrameGroup[2],
        goodsEmptyLayer   = goodsFrameGroup[3],
        typeTabButtonList = typeTabButtonList,
    }
end


function WaterBarMarketView.CreateGoodsCell(cellParent)
    local view = cellParent
    local size = view:getContentSize()
    local cpos = cc.sizep(size, ui.cc)
    view:add(ui.image({p = cpos, img = RES_DICT.GOODS_BG}))

    local goodsGroup = view:addList({
        ui.image({img = RES_DICT.GOODS_FRAME, scale = 0.9}),
        ui.goodsNode({showAmount = true, scale = 0.8}),
    })
    ui.flowLayout(cc.p(cpos.y+5, cpos.y), goodsGroup, {type = ui.flowC, ap = ui.cc})

    local soldMark = ui.title({n = RES_DICT.GOODS_WARD, cut = cc.dir(5,5,5,5)}):updateLabel({fnt = FONT.D14, text = __('已售罄'), paddingW = 8})
    view:addList(soldMark):alignTo(goodsGroup[2], ui.lc, {inside = true})

    local nameLabel = ui.label({fnt = FONT.TEXT24, color = '#B65D5F', ap = ui.lt, w = 170})
    view:addList(nameLabel):alignTo(goodsGroup[2], ui.rt, {offsetX = 15, offsetY = 0})

    local priceGrup = view:addList({
        ui.title({img = RES_DICT.GOODS_FRAME, cut = cc.dir(5,5,5,5), size = cc.size(30,30), ap = ui.rc}):updateLabel({fnt = FONT.D1, fontSize = 20}),
        ui.layer({size = cc.size(0,0), mr = -5}),
    })
    ui.flowLayout(cc.rep(cc.sizep(size, ui.rb), -40, 32), priceGrup, {type = ui.flowC, ap = ui.rc})

    local clickArea = ui.layer({size = size, color = cc.r4b(0), enable = true})
    view:add(clickArea)

    return {
        view       = view,
        nameLabel  = nameLabel,
        soldMark   = soldMark,
        goodsNode  = goodsGroup[2],
        priceLabel = priceGrup[1],
        priceLayer = priceGrup[2],
        clickArea  = clickArea,
    }
end


return WaterBarMarketView

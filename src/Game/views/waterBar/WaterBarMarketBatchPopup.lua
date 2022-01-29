--[[
 * author : kaishiqi
 * descpt : 水吧 - 市场批量购买弹窗
]]
local CommonDialog             = require('common.CommonDialog')
local WaterBarMarketBatchPopup = class('WaterBarMarketBatchPopup', CommonDialog)

local RES_DICT = {
    BG_FRAME      = _res('ui/common/common_bg_7.png'),
    TITLE_BAR     = _res('ui/common/common_bg_title_2.png'),
    BTN_CONFIRM_N = _res('ui/common/common_btn_orange.png'),
    BTN_CONFIRM_D = _res('ui/common/common_btn_orange_disable.png'),
    CUT_LINE_IMG  = _res('ui/home/market/market_choice_ico_line.png'),
    TYPE_BTN_D    = _res('ui/home/market/market_bg_choice_type_default.png'),
    TYPE_BTN_S    = _res('ui/home/market/market_bg_choice_type_selected.png'),
    PRICE_FRAME   = _res('ui/home/market/market_choice_bg_prizce.png'),
}

local MARKET_PROXY_NAME   = FOOD.WATER_BAR.MARKET.PROXY_NAME
local MARKET_PROXY_STRUCT = FOOD.WATER_BAR.MARKET.PROXY_STRUCT


function WaterBarMarketBatchPopup:InitialUI()
    -- init vars
    self.isControllable_  = true
    self.selectTypeMap_   = {}
    self.productIdList_   = {}
    self.confirmCallback_ = self.args.confirmCB

    -- init model
    self.marketProxy_ = app:RetrieveProxy(MARKET_PROXY_NAME)

    -- create view
    self.viewData = WaterBarMarketBatchPopup.CreateView()

    ui.bindClick(self:getViewData().confirmBtn, handler(self, self.onClickConfirmButtonHandler_))
    for index, typeTabBtn in ipairs(self:getViewData().typeTabBtnList) do
        ui.bindClick(typeTabBtn, handler(self, self.onClickTypeTabButtonHandler_), false)
    end

    -- update view
    self:updateSelectedStatus_()
end


function WaterBarMarketBatchPopup:onCleanup()
end


function WaterBarMarketBatchPopup:getViewData()
    return self.viewData
end


-------------------------------------------------
-- private

function WaterBarMarketBatchPopup:updateSelectedStatus_()
    local hasSelected   = false
    self.productIdList_ = {}
    
    -- update all typeTabBtn
    for index, typeTabBtn in ipairs(self:getViewData().typeTabBtnList) do
        local isSelected = self.selectTypeMap_[tostring(typeTabBtn:getTag())] == true
        typeTabBtn:setChecked(isSelected)
        if isSelected then
            hasSelected = true
        end
    end

    -- calculate totalPrice
    local totalPrice  = 0
    local CELL_STRUCT = MARKET_PROXY_STRUCT.MARKET_HOME_TAKE.PRODUCTS.PRODUCT_DATA
    for index = 1, self.marketProxy_:size(MARKET_PROXY_STRUCT.MARKET_HOME_TAKE.PRODUCTS) do
        local cellVoProxy  = self.marketProxy_:get(CELL_STRUCT, index)
        local productId    = cellVoProxy:get(CELL_STRUCT.PRODUCT_ID)
        local goodsPrice   = cellVoProxy:get(CELL_STRUCT.PRICE_NUM)
        local materialId   = cellVoProxy:get(CELL_STRUCT.GOODS_ID)
        local isPurchased  = cellVoProxy:get(CELL_STRUCT.PURCHASED) > 0 
        local materialConf = CONF.BAR.MATERIAL:GetValue(materialId)
        local isSelected   = self.selectTypeMap_[tostring(materialConf.materialType)] == true
        if not isPurchased and isSelected then
            totalPrice = totalPrice + goodsPrice
            table.insert(self.productIdList_, productId)
        end
    end
    
    -- updat priceRLabel
    local marketCurrencyId = self.marketProxy_:get(MARKET_PROXY_STRUCT.MARKET_CURRENCY_ID)
    self:getViewData().priceRLabel:reload({
        {fnt = FONT.D17, text = tostring(totalPrice)},
        {img = CommonUtils.GetGoodsIconPathById(marketCurrencyId), scale = 0.18}
    })

    -- update confirmBtn
    self:getViewData().confirmBtn:setEnabled(hasSelected and totalPrice > 0)
end


-------------------------------------------------
-- handler

function WaterBarMarketBatchPopup:onClickTypeTabButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    -- switch selct status
    local tabMaterialType = checkint(sender:getTag())
    if self.selectTypeMap_[tostring(tabMaterialType)] then
        self.selectTypeMap_[tostring(tabMaterialType)] = false
    else
        self.selectTypeMap_[tostring(tabMaterialType)] = true
    end

    -- update view
    self:updateSelectedStatus_()
end


function WaterBarMarketBatchPopup:onClickConfirmButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    if self.confirmCallback_ then
        self.confirmCallback_(self.productIdList_)
    end

    self:CloseHandler()
end


-------------------------------------------------------------------------------
-- view struct
-------------------------------------------------------------------------------

function WaterBarMarketBatchPopup.CreateView()
    local view = ui.layer({bg = RES_DICT.BG_FRAME})
    local size = view:getContentSize()
    local cpos = cc.sizep(size, ui.cc)

    -- title bar
    local titleBar = ui.title({img = RES_DICT.TITLE_BAR}):updateLabel({fnt = FONT.D3, text = __('选择类别'), paddingW = 60, safeW = 120, offset = cc.p(0,-2)})
    view:addList(titleBar):alignTo(nil, ui.ct, {offsetY = -4})

    -- select tips
    local selectTips = ui.label({fnt = FONT.D4, text = __('请选择需要购买的类别')})
    view:addList(selectTips):alignTo(nil, ui.ct, {offsetY = -60})


    -- bottom group
    local bottomGroup = view:addList({
        ui.image({img = RES_DICT.CUT_LINE_IMG, mb = 20}),
        ui.label({fnt = FONT.D4, text = __('总价')}),
        ui.image({img = RES_DICT.PRICE_FRAME, mb = 30}),
        ui.button({n = RES_DICT.BTN_CONFIRM_N, d = RES_DICT.BTN_CONFIRM_D}):updateLabel({fnt = FONT.D14, text = __('确认')})
    })
    ui.flowLayout(cc.p(cpos.x, 30), bottomGroup, {type = ui.flowV, ap = ui.ct, gapH = 5})

    -- price rLabel
    local priceRLabel = ui.rLabel({})
    view:addList(priceRLabel):alignTo(bottomGroup[3], ui.cc)


    -- type tab buttons
    local TYPE_TAB_DEFINES = {
        {type = FOOD.WATER_BAR.MATERIAL_TYPE.BASIC,   name = __('基酒')},
        {type = FOOD.WATER_BAR.MATERIAL_TYPE.FLAVOUR, name = __('调味酒')},
        {type = FOOD.WATER_BAR.MATERIAL_TYPE.OTHER,   name = __('其他')},
    }
    local TYPE_TAB_BTN_COLS = 2
    local TYPE_TAB_BTN_GAPW = 245
    local TYPE_TAB_BTN_GAPH = 100
    local TYPE_TAB_BTN_POSX = cpos.x - TYPE_TAB_BTN_GAPW/2
    local TYPE_TAB_BTN_POSY = size.height - 140
    local typeTabButtonList = {}
    for index, typeDefine in ipairs(TYPE_TAB_DEFINES) do
        local tButton = ui.tButton({n = RES_DICT.TYPE_BTN_D, s = RES_DICT.TYPE_BTN_S, tag = typeDefine.type})
        tButton:addList(ui.label({fnt = FONT.D14, text = typeDefine.name})):alignTo(nil, ui.cc)
        typeTabButtonList[index] = tButton

        local typeBtnCol = (index+1) % TYPE_TAB_BTN_COLS + 1
        local typeBtnRow = math.ceil(index/TYPE_TAB_BTN_COLS)
        tButton:setPositionX(TYPE_TAB_BTN_POSX + (typeBtnCol-1) * TYPE_TAB_BTN_GAPW)
        tButton:setPositionY(TYPE_TAB_BTN_POSY - (typeBtnRow-1) * TYPE_TAB_BTN_GAPH)
    end
    view:addList(typeTabButtonList)

    return {
        view           = view,
        typeTabBtnList = typeTabButtonList,
        priceRLabel    = priceRLabel,
        confirmBtn     = bottomGroup[4],
    }
end


return WaterBarMarketBatchPopup

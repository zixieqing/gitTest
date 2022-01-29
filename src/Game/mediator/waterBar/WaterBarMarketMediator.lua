--[[
 * author : kaishiqi
 * descpt : 水吧 - 市场中介者
]]
local WaterBarMarketView     = require('Game.views.waterBar.WaterBarMarketView')
local WaterBarMarketMediator = class('WaterBarMarketMediator', mvc.Mediator)

local MARKET_PROXY_NAME   = FOOD.WATER_BAR.MARKET.PROXY_NAME
local MARKET_PROXY_STRUCT = FOOD.WATER_BAR.MARKET.PROXY_STRUCT

function WaterBarMarketMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'WaterBarMarketMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end


-------------------------------------------------
-- inheritance

function WaterBarMarketMediator:Initial(key)
    self.super.Initial(self, key)

    -- init vars
    local defaultType    = self.ctorArgs_.initType or FOOD.WATER_BAR.MATERIAL_TYPE.BASIC
    local searchGoodsId  = checkint(self.ctorArgs_.goodsId)
    local initOpenType   = searchGoodsId > 0 and FOOD.WATER_BAR.MATERIAL_TYPE.SEARCH or defaultType
    self.isControllable_ = true

    -- init model
    self.marketProxy_ = regVoProxy(MARKET_PROXY_NAME, MARKET_PROXY_STRUCT)
    self.marketProxy_:set(MARKET_PROXY_STRUCT.SEARCH_GOODS_ID, searchGoodsId)

    -- create view
    self.viewNode_ = WaterBarMarketView.new()
    self:SetViewComponent(self:getViewNode())
    app.uiMgr:GetCurrentScene():AddDialog(self:getViewNode())

    -- add listener
    self.marketRefreshClocker_ = app.timerMgr.CreateClocker(handler(self, self.onMarketRefreshUpdateHandler_))
    ui.bindClick(self:getViewData().blockLayer, handler(self, self.onClickBackLayerHandler_), false)
    ui.bindClick(self:getViewData().refreshBtn, handler(self, self.onClickRefreshButtonHandler_))
    ui.bindClick(self:getViewData().batchBuyBtn, handler(self, self.onClicBatchBuyButtonHandler_))
    self:getViewData().goodsGridView:setCellInitHandler(function(cellViewData)
        ui.bindClick(cellViewData.clickArea, handler(self, self.onClickProductCellHandler_))
    end)
    for index, typeTabButton in ipairs(self:getViewData().typeTabButtonList) do
        ui.bindClick(typeTabButton, handler(self, self.onClickTypeTabButtonHandler_), false)
    end

    -- init status
    self.marketProxy_:set(MARKET_PROXY_STRUCT.SELECT_MATERIAL_TYPE, initOpenType)
end


function WaterBarMarketMediator:CleanupView()
    self.marketRefreshClocker_:stop()
    unregVoProxy(MARKET_PROXY_NAME)

    if self:getViewNode() and not tolua.isnull(self:getViewNode()) then
        self:getViewNode():removeFromParent()
        self.viewNode_ = nil
    end
end


function WaterBarMarketMediator:OnRegist()
    regPost(POST.WATER_BAR_MARKET_BUY)
    regPost(POST.WATER_BAR_MARKET_HOME)
    regPost(POST.WATER_BAR_MARKET_REFRESH)

    self:SendSignal(POST.WATER_BAR_MARKET_HOME.cmdName)
end


function WaterBarMarketMediator:OnUnRegist()
    unregPost(POST.WATER_BAR_MARKET_BUY)
    unregPost(POST.WATER_BAR_MARKET_HOME)
    unregPost(POST.WATER_BAR_MARKET_REFRESH)
end


function WaterBarMarketMediator:InterestSignals()
    return {
        POST.WATER_BAR_MARKET_BUY.sglName,
        POST.WATER_BAR_MARKET_HOME.sglName,
        POST.WATER_BAR_MARKET_REFRESH.sglName,
    }
end
function WaterBarMarketMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()

    -------------------------------------------------
    if name == POST.WATER_BAR_MARKET_HOME.sglName then
        -- update marketHome takeData
        self.marketProxy_:set(MARKET_PROXY_STRUCT.MARKET_HOME_TAKE, data)

        -- update marketCurrencyId
        if self.marketProxy_:size(MARKET_PROXY_STRUCT.MARKET_HOME_TAKE.PRODUCTS) > 0 then
            local CELL_STRUCT = MARKET_PROXY_STRUCT.MARKET_HOME_TAKE.PRODUCTS.PRODUCT_DATA
            local cellVoProxy = self.marketProxy_:get(CELL_STRUCT, 1)
            local currencyId  = cellVoProxy:get(CELL_STRUCT.CURRENCY_ID)
            self.marketProxy_:set(MARKET_PROXY_STRUCT.MARKET_CURRENCY_ID, currencyId)
        end

        -- update refreshTimestamp
        local refreshLeftSeconds = self.marketProxy_:get(MARKET_PROXY_STRUCT.MARKET_HOME_TAKE.REFRESH_LEFT_SECONDS)
        self.marketProxy_:set(MARKET_PROXY_STRUCT.REFRESH_TIMESTAMP, os.time() + math.max(refreshLeftSeconds, 1)) -- 防止返回0秒变成无限刷新

        -- start marketRefreshClocker
        self.marketRefreshClocker_:start()

        
    -------------------------------------------------
    elseif name == POST.WATER_BAR_MARKET_REFRESH.sglName then
        -- update marketRefresh takeData
        self.marketProxy_:set(MARKET_PROXY_STRUCT.MARKET_REFRESH_TAKE, data)

        -- update refresh leftTimes
        local refreshLeftTimes = self.marketProxy_:get(MARKET_PROXY_STRUCT.MARKET_HOME_TAKE.REFRESH_LEFT_TIEMS)
        self.marketProxy_:set(MARKET_PROXY_STRUCT.MARKET_HOME_TAKE.REFRESH_LEFT_TIEMS, refreshLeftTimes - 1)

        -- update marketHome products
        local newProducts = self.marketProxy_:get(MARKET_PROXY_STRUCT.MARKET_REFRESH_TAKE.PRODUCTS):getData()
        self.marketProxy_:set(MARKET_PROXY_STRUCT.MARKET_HOME_TAKE.PRODUCTS, newProducts)

        -- update player diamond
        local playerDiamond = self.marketProxy_:get(MARKET_PROXY_STRUCT.MARKET_REFRESH_TAKE.DIAMOND)
        app.gameMgr:GetUserInfo().diamond = playerDiamond
        app:DispatchObservers(SGL.CACHE_MONEY_UPDATE_UI)


    -------------------------------------------------
    elseif name == POST.WATER_BAR_MARKET_BUY.sglName then
        -- update marketBuy takeData
        self.marketProxy_:set(MARKET_PROXY_STRUCT.MARKET_BUY_TAKE, data)

        -- show rewards
        local goodsRewrads = self.marketProxy_:get(MARKET_PROXY_STRUCT.MARKET_BUY_TAKE.REWARDS):getData()
        app.uiMgr:AddDialog('common.RewardPopup', {rewards = goodsRewrads})

        -- update purchased status
        local useCurrencyNum = 0
        local SELECT_STRUCT  = MARKET_PROXY_STRUCT.SELECT_PRODUCT_MAP
        local selectVoProxy  = self.marketProxy_:get(SELECT_STRUCT)
        local PRODUCT_STRUCT = MARKET_PROXY_STRUCT.MARKET_HOME_TAKE.PRODUCTS.PRODUCT_DATA
        for i = 1, self.marketProxy_:size(MARKET_PROXY_STRUCT.MARKET_HOME_TAKE.PRODUCTS) do
            local productVoProxy = self.marketProxy_:get(PRODUCT_STRUCT, i)
            local productId      = productVoProxy:get(PRODUCT_STRUCT.PRODUCT_ID)
            local productPrice   = productVoProxy:get(PRODUCT_STRUCT.PRICE_NUM)
            if selectVoProxy:get(SELECT_STRUCT.SELECTED, tostring(productId)) then
                useCurrencyNum = useCurrencyNum + productPrice
                productVoProxy:set(PRODUCT_STRUCT.PURCHASED, 1)
            end
        end
        
        -- consume currency
        local marketCurrencyId = self.marketProxy_:get(MARKET_PROXY_STRUCT.MARKET_CURRENCY_ID)
        CommonUtils.DrawRewards({
            {goodsId = marketCurrencyId, num = -useCurrencyNum}
        })
    end
end


-------------------------------------------------
-- get / set

function WaterBarMarketMediator:getViewNode()
    return self.viewNode_
end
function WaterBarMarketMediator:getViewData()
    return self:getViewNode():getViewData()
end


-------------------------------------------------
-- public

function WaterBarMarketMediator:close()
    app:UnRegsitMediator(self:GetMediatorName())
end


function WaterBarMarketMediator:closePurchasePopup()
    app:UnRegsitMediator('MultiBuyMediator')
    app.uiMgr:GetCurrentScene():RemoveDialogByName('shopPurchasePopup')
end


-------------------------------------------------
-- private

function WaterBarMarketMediator:toPurchaseProducts_(productIdList)
    if #checktable(productIdList) == 0 then return end

    -- save select data
    local SELECT_STRUCT    = MARKET_PROXY_STRUCT.SELECT_PRODUCT_MAP
    local selectProductMap = {}
    for index, productId in ipairs(checktable(productIdList)) do
        selectProductMap[tostring(productId)] = true
    end
    self.marketProxy_:set(SELECT_STRUCT, selectProductMap)
    
    -- count total price
    local marketCurrencyId = self.marketProxy_:get(MARKET_PROXY_STRUCT.MARKET_CURRENCY_ID)
    local hasCurrencyNum   = app.gameMgr:GetAmountByIdForce(marketCurrencyId)
    local useCurrencyNum   = 0
    local PRODUCT_STRUCT   = MARKET_PROXY_STRUCT.MARKET_HOME_TAKE.PRODUCTS.PRODUCT_DATA
    for i = 1, self.marketProxy_:size(MARKET_PROXY_STRUCT.MARKET_HOME_TAKE.PRODUCTS) do
        local productVoProxy = self.marketProxy_:get(PRODUCT_STRUCT, i)
        local productId      = productVoProxy:get(PRODUCT_STRUCT.PRODUCT_ID)
        local productPrice   = productVoProxy:get(PRODUCT_STRUCT.PRICE_NUM)
        if selectProductMap[tostring(productId)] then
            useCurrencyNum = useCurrencyNum + productPrice
        end
    end

    -- check currency enough
    if hasCurrencyNum >= useCurrencyNum then
        local BUY_STRUCT = MARKET_PROXY_STRUCT.MARKET_BUY_SEND
        local buyVoProxy = self.marketProxy_:get(BUY_STRUCT)
        buyVoProxy:set(BUY_STRUCT.PRODUCT_IDS, table.concat(productIdList, ','))
        self:SendSignal(POST.WATER_BAR_MARKET_BUY.cmdName, buyVoProxy:getData())
        self:closePurchasePopup()

    else
        local currencyName = CommonUtils.GetCacheProductName(marketCurrencyId)
        app.uiMgr:ShowInformationTips(string.fmt(__('_des_不足'), {_des_ = currencyName}))
    end
end


-------------------------------------------------
-- handler

function WaterBarMarketMediator:onClickBackLayerHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end

    self:close()
end


function WaterBarMarketMediator:onClickTypeTabButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end
    sender:setChecked(true)

    local tabMaterialType = checkint(sender:getTag())
    if self.marketProxy_:get(MARKET_PROXY_STRUCT.SELECT_MATERIAL_TYPE) ~= tabMaterialType then
        self.marketProxy_:set(MARKET_PROXY_STRUCT.SELECT_MATERIAL_TYPE, tabMaterialType)
    end
end


function WaterBarMarketMediator:onMarketRefreshUpdateHandler_()
    local currentTime = os.time()
    local refreshTime = self.marketProxy_:get(MARKET_PROXY_STRUCT.REFRESH_TIMESTAMP)
    local leftSeconds = refreshTime - currentTime

    if leftSeconds >= 0 then
        self.marketProxy_:set(MARKET_PROXY_STRUCT.MARKET_HOME_TAKE.REFRESH_LEFT_SECONDS, leftSeconds)
    else
        self:closePurchasePopup()
        self.marketRefreshClocker_:stop()
        self:SendSignal(POST.WATER_BAR_MARKET_HOME.cmdName)
    end
end


function WaterBarMarketMediator:onClickRefreshButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local leftTimes   = self.marketProxy_:get(MARKET_PROXY_STRUCT.MARKET_HOME_TAKE.REFRESH_LEFT_TIEMS)
    local costDiamond = self.marketProxy_:get(MARKET_PROXY_STRUCT.MARKET_HOME_TAKE.REFRESH_DIAMOND)
    if leftTimes > 0 then
        local tipsDescr = string.fmt(__('是否使用_num_个幻晶石进行商店刷新？'), {_num_ = costDiamond})
        local extraText = string.fmt(__('（今日剩余_num_次刷新次数）'), {_num_ = leftTimes})
        app.uiMgr:AddNewCommonTipDialog({text = tipsDescr, extra = extraText, callback = function()
            self:SendSignal(POST.WATER_BAR_MARKET_REFRESH.cmdName)
        end})
        
    else
        app.uiMgr:ShowInformationTips(__('今日刷新次数已用完'))
    end
end


function WaterBarMarketMediator:onClicBatchBuyButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local selectedGoodList = {}
    local PRODUCT_STRUCT   = MARKET_PROXY_STRUCT.MARKET_HOME_TAKE.PRODUCTS.PRODUCT_DATA
    local selectType       = self.marketProxy_:get(MARKET_PROXY_STRUCT.SELECT_MATERIAL_TYPE)
    for goodsIndex = 1, self.marketProxy_:size(MARKET_PROXY_STRUCT.MARKET_HOME_TAKE.PRODUCTS) do
        local goodsVoProxy = self.marketProxy_:get(PRODUCT_STRUCT, goodsIndex)
        local goodsId      = goodsVoProxy:get(PRODUCT_STRUCT.GOODS_ID)
        local goodsConf    = CONF.BAR.MATERIAL:GetValue(goodsId)
        if goodsVoProxy:get(PRODUCT_STRUCT.PURCHASED) == 0 and (selectType == checkint(goodsConf.materialType) or (goodsId == self.marketProxy_:get(MARKET_PROXY_STRUCT.SEARCH_GOODS_ID) and selectType == FOOD.WATER_BAR.MATERIAL_TYPE.SEARCH)) then
            table.insert(selectedGoodList, clone(goodsVoProxy:getData()))
        end
    end

    if #selectedGoodList <= 0 then
        app.uiMgr:ShowInformationTips(__("货物已售罄"))
    else
        app:RegistMediator(require('Game.mediator.stores.MultiBuyMediator').new({products = selectedGoodList,
            customBuyHandler = handler(self, self.onClickMultiPurchaseButtonHandler_)
        }))
    end
end


function WaterBarMarketMediator:onClickMultiPurchaseButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local buyGoodsMediator = app:RetrieveMediator('MultiBuyMediator')
    if buyGoodsMediator then
        self:toPurchaseProducts_(buyGoodsMediator:getAllBuyProduct())
    end
end


function WaterBarMarketMediator:onClickProductCellHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local selectCellIndex = checkint(sender:getTag())
    local PRODUCT_STRUCT  = MARKET_PROXY_STRUCT.MARKET_HOME_TAKE.PRODUCTS.PRODUCT_DATA
    local productVoProxy  = self.marketProxy_:get(PRODUCT_STRUCT, selectCellIndex)

    -- check cardSkin type
    if CommonUtils.CheckIsOwnSkinById(productVoProxy:get(PRODUCT_STRUCT.GOODS_ID)) then
        app.uiMgr:ShowInformationTips(__('已经拥有该皮肤'))
        return
    end

    -- check purchased status
    if productVoProxy:get(PRODUCT_STRUCT.PURCHASED) == 0 then
        local shopPurchaseData  = clone(productVoProxy:getData())
        local shopPurchasePopup = require('Game.views.ShopPurchasePopup').new({data = shopPurchaseData})
        shopPurchasePopup:setPosition(display.center)
        shopPurchasePopup:setName('shopPurchasePopup')
        shopPurchasePopup.viewData.purchaseBtn:setTag(selectCellIndex)
        shopPurchasePopup.viewData.purchaseBtn:setOnClickScriptHandler(handler(self, self.onClickSinglePurchaseButtonHandler_))
        app.uiMgr:GetCurrentScene():AddDialog(shopPurchasePopup)
    else
        app.uiMgr:ShowInformationTips(__('该商品已售罄'))
    end
end


function WaterBarMarketMediator:onClickSinglePurchaseButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local selectCellIndex = checkint(sender:getTag())
    local PRODUCT_STRUCT  = MARKET_PROXY_STRUCT.MARKET_HOME_TAKE.PRODUCTS.PRODUCT_DATA
    local productVoProxy  = self.marketProxy_:get(PRODUCT_STRUCT, selectCellIndex)
    local selectProductId = productVoProxy:get(PRODUCT_STRUCT.PRODUCT_ID)
    self:toPurchaseProducts_({selectProductId})
end


return WaterBarMarketMediator

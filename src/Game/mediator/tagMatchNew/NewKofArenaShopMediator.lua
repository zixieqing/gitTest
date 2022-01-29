--[[
 * author : kaishiqi
 * descpt : 新天成演武 - 商店中介者
]]
local NewKofArenaShopView     = require('Game.views.tagMatchNew.NewKofArenaShopView')
local NewKofArenaShopMediator = class('NewKofArenaShopMediator', mvc.Mediator)

local SHOP_PROXY_NAME   = FOOD.NEW_KOF.SHOP.PROXY_NAME
local SHOP_PROXY_STRUCT = FOOD.NEW_KOF.SHOP.PROXY_STRUCT

function NewKofArenaShopMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'NewKofArenaShopMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end


-------------------------------------------------
-- inheritance

function NewKofArenaShopMediator:Initial(key)
    self.super.Initial(self, key)

    -- init vars
    self.isControllable_ = true

    -- init model
    self.shopProxy_ = regVoProxy(SHOP_PROXY_NAME, SHOP_PROXY_STRUCT)

    -- create view
    self.viewNode_ = NewKofArenaShopView.new()
    self:SetViewComponent(self:getViewNode())
    app.uiMgr:GetCurrentScene():AddDialog(self:getViewNode())

    -- add listener
    self.shopRefreshClocker_ = app.timerMgr.CreateClocker(handler(self, self.onShopRefreshUpdateHandler_))
    ui.bindClick(self:getViewData().blockLayer, handler(self, self.onClickBackLayerHandler_), false)
    ui.bindClick(self:getViewData().batchBuyBtn, handler(self, self.onClicBatchBuyButtonHandler_))
    self:getViewData().goodsGridView:setCellInitHandler(function(cellViewData)
        ui.bindClick(cellViewData.toggleView, handler(self, self.onClickProductCellHandler_))
        cellViewData.leftTimesLabel:setOnTextRichClickScriptHandler(handler(self, self.onClickProductCellHandler_))
    end)
end


function NewKofArenaShopMediator:CleanupView()
    self.shopRefreshClocker_:stop()
    unregVoProxy(SHOP_PROXY_NAME)

    if self:getViewNode() and not tolua.isnull(self:getViewNode()) then
        self:getViewNode():removeFromParent()
        self.viewNode_ = nil
    end
end


function NewKofArenaShopMediator:OnRegist()
    regPost(POST.NEW_TAG_MATCH_MALL_BUY_MULTI)
    regPost(POST.NEW_TAG_MATCH_BUY)
    regPost(POST.NEW_TAG_MATCH_MALL)

    self:SendSignal(POST.NEW_TAG_MATCH_MALL.cmdName)
end


function NewKofArenaShopMediator:OnUnRegist()
    unregPost(POST.NEW_TAG_MATCH_MALL_BUY_MULTI)
    unregPost(POST.NEW_TAG_MATCH_BUY)
    unregPost(POST.NEW_TAG_MATCH_MALL)
end


function NewKofArenaShopMediator:InterestSignals()
    return {
        POST.NEW_TAG_MATCH_MALL_BUY_MULTI.sglName,
        POST.NEW_TAG_MATCH_BUY.sglName,
        POST.NEW_TAG_MATCH_MALL.sglName,
    }
end
function NewKofArenaShopMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()

    -------------------------------------------------
    if name == POST.NEW_TAG_MATCH_MALL.sglName then
        -- update shopHome takeData
        self.shopProxy_:set(SHOP_PROXY_STRUCT.SHOP_HOME_TAKE, data)
        
        -- update refreshTimestamp
        local refreshLeftSeconds = self.shopProxy_:get(SHOP_PROXY_STRUCT.SHOP_HOME_TAKE.REFRESH_LEFT_SECONDS)
        self.shopProxy_:set(SHOP_PROXY_STRUCT.REFRESH_TIMESTAMP, os.time() + math.max(refreshLeftSeconds, 1)) -- 防止返回0秒变成无限刷新

        -- start shopRefreshClocker
        self.shopRefreshClocker_:start()

        
    -------------------------------------------------
    elseif name == POST.NEW_TAG_MATCH_BUY.sglName then
        -- update shopBuy takeData
        self.shopProxy_:set(SHOP_PROXY_STRUCT.SHOP_BUY_TAKE, data)

        -- show rewards
        local goodsRewrads = self.shopProxy_:get(SHOP_PROXY_STRUCT.SHOP_BUY_TAKE.REWARDS):getData()
        self:toPurchaseProductsCB_(goodsRewrads)


    -------------------------------------------------
    elseif name == POST.NEW_TAG_MATCH_MALL_BUY_MULTI.sglName then
        -- update shopBuy takeData
        self.shopProxy_:set(SHOP_PROXY_STRUCT.SHOP_MULTI_BUY_TAKE, data)

        -- show rewards
        local goodsRewrads = self.shopProxy_:get(SHOP_PROXY_STRUCT.SHOP_MULTI_BUY_TAKE.REWARDS):getData()
        self:toPurchaseProductsCB_(goodsRewrads)
    end
end


-------------------------------------------------
-- get / set

function NewKofArenaShopMediator:getViewNode()
    return self.viewNode_
end
function NewKofArenaShopMediator:getViewData()
    return self:getViewNode():getViewData()
end


-------------------------------------------------
-- public

function NewKofArenaShopMediator:close()
    app:UnRegsitMediator(self:GetMediatorName())
end


function NewKofArenaShopMediator:closePurchasePopup()
    local buyGoodsMediator = app:RetrieveMediator('MultiBuyMediator')
    if buyGoodsMediator then
        buyGoodsMediator:close()
    end

    app.uiMgr:GetCurrentScene():RemoveDialogByName('shopPurchasePopup')
end


-------------------------------------------------
-- private

function NewKofArenaShopMediator:toPurchaseProducts_(purchaseProductMap)
    if next(checktable(purchaseProductMap)) == nil then return end

    -- reset select products
    local SELECT_STRUCT = SHOP_PROXY_STRUCT.SELECT_PRODUCT_MAP
    local selectVoProxy = self.shopProxy_:get(SELECT_STRUCT)
    self.shopProxy_:set(SELECT_STRUCT, purchaseProductMap)

    -- count total price
    local productIdList  = {}
    local useCurrencyNum = 0
    local PRODUCT_STRUCT = SHOP_PROXY_STRUCT.SHOP_HOME_TAKE.PRODUCTS.PRODUCT_DATA
    for i = 1, self.shopProxy_:size(SHOP_PROXY_STRUCT.SHOP_HOME_TAKE.PRODUCTS) do
        local productVoProxy = self.shopProxy_:get(PRODUCT_STRUCT, i)
        local productId      = productVoProxy:get(PRODUCT_STRUCT.PRODUCT_ID)
        local productPrice   = productVoProxy:get(PRODUCT_STRUCT.PRICE_NUM)
        local purchasedNum   = selectVoProxy:get(SELECT_STRUCT.PURCHASED_NUM, tostring(productId))
        if purchasedNum > 0 then
            useCurrencyNum = useCurrencyNum + (productPrice * purchasedNum)
            table.insert(productIdList, productId)
        end
    end
    
    -- check currency enough
    local shopCurrencyId = FOOD.GOODS.DEFINE.NEW_KOF_CURRENCY_ID
    local hasCurrencyNum = app.gameMgr:GetAmountByIdForce(shopCurrencyId)
    if hasCurrencyNum >= useCurrencyNum then
        if #checktable(productIdList) > 1 then
            local BUY_STRUCT  = SHOP_PROXY_STRUCT.SHOP_MULTI_BUY_SEND
            local buyVoProxy  = self.shopProxy_:get(BUY_STRUCT)
            buyVoProxy:set(BUY_STRUCT.PRODUCT_IDS, table.concat(productIdList, ','))
            self:SendSignal(POST.NEW_TAG_MATCH_MALL_BUY_MULTI.cmdName, buyVoProxy:getData())
        else
            local BUY_STRUCT   = SHOP_PROXY_STRUCT.SHOP_BUY_SEND
            local buyVoProxy   = self.shopProxy_:get(BUY_STRUCT)
            local productId    = tostring(productIdList[1])
            local purchasedNum = selectVoProxy:get(SELECT_STRUCT.PURCHASED_NUM, productId)
            buyVoProxy:set(BUY_STRUCT.PRODUCT_ID, productId)
            buyVoProxy:set(BUY_STRUCT.PRODUCT_NUM, purchasedNum)
            self:SendSignal(POST.NEW_TAG_MATCH_BUY.cmdName, buyVoProxy:getData())
        end
        self:closePurchasePopup()

    else
        local currencyName = CommonUtils.GetCacheProductName(shopCurrencyId)
        app.uiMgr:ShowInformationTips(string.fmt(__('_des_不足'), {_des_ = currencyName}))
    end
end


function NewKofArenaShopMediator:toPurchaseProductsCB_(goodsRewrads)
    -- show rewards
    app.uiMgr:AddDialog('common.RewardPopup', {rewards = goodsRewrads})

    -- update purchased status
    local useCurrencyNum = 0
    local SELECT_STRUCT  = SHOP_PROXY_STRUCT.SELECT_PRODUCT_MAP
    local selectVoProxy  = self.shopProxy_:get(SELECT_STRUCT)
    local PRODUCT_STRUCT = SHOP_PROXY_STRUCT.SHOP_HOME_TAKE.PRODUCTS.PRODUCT_DATA
    for i = 1, self.shopProxy_:size(SHOP_PROXY_STRUCT.SHOP_HOME_TAKE.PRODUCTS) do
        local productVoProxy = self.shopProxy_:get(PRODUCT_STRUCT, i)
        local productId      = productVoProxy:get(PRODUCT_STRUCT.PRODUCT_ID)
        local productPrice   = productVoProxy:get(PRODUCT_STRUCT.PRICE_NUM)
        local purchasedNum   = selectVoProxy:get(SELECT_STRUCT.PURCHASED_NUM, tostring(productId))
        if purchasedNum > 0 then
            useCurrencyNum = useCurrencyNum + (productPrice * purchasedNum)
            productVoProxy:set(PRODUCT_STRUCT.STOCK_LEFT, productVoProxy:get(PRODUCT_STRUCT.STOCK_LEFT) - purchasedNum)
        end
    end
    
    -- consume currency
    local shopCurrencyId = FOOD.GOODS.DEFINE.NEW_KOF_CURRENCY_ID
    CommonUtils.DrawRewards({
        {goodsId = shopCurrencyId, num = -useCurrencyNum}
    })
end


-------------------------------------------------
-- handler

function NewKofArenaShopMediator:onClickBackLayerHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end

    self:close()
end


function NewKofArenaShopMediator:onShopRefreshUpdateHandler_()
    local currentTime = os.time()
    local refreshTime = self.shopProxy_:get(SHOP_PROXY_STRUCT.REFRESH_TIMESTAMP)
    local leftSeconds = refreshTime - currentTime

    if leftSeconds >= 0 then
        self.shopProxy_:set(SHOP_PROXY_STRUCT.SHOP_HOME_TAKE.REFRESH_LEFT_SECONDS, leftSeconds)
    else
        self:closePurchasePopup()
        self.shopRefreshClocker_:stop()
        self:SendSignal(POST.NEW_TAG_MATCH_MALL.cmdName)
    end
end


function NewKofArenaShopMediator:onClicBatchBuyButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    -- 因为是老界面，所以clone传数据过去避免污染这边的。
    -- 如果是 voProxy 实现的子界面，传入 PRODUCTS 的 voProxy 节点过去，子界面操作数据，外面就能及时得到事件做出更新。
    local allProductsData = {}
    local PRODUCT_STRUCT  = SHOP_PROXY_STRUCT.SHOP_HOME_TAKE.PRODUCTS.PRODUCT_DATA
    for i = 1, self.shopProxy_:size(SHOP_PROXY_STRUCT.SHOP_HOME_TAKE.PRODUCTS) do
        local productVoProxy = self.shopProxy_:get(PRODUCT_STRUCT, i)
        -- local barUnlockLevel = productVoProxy:get(PRODUCT_STRUCT.OPEN_LEVEL)
        -- if app.waterBarMgr:getBarLevel() >= barUnlockLevel then  -- TODO 等级取值不对
            table.insert(allProductsData, clone(productVoProxy:getData()))
        -- end
    end

    app:RegistMediator(require('Game.mediator.stores.MultiBuyMediator').new({products = allProductsData,
        customBuyHandler = handler(self, self.onClickMultiPurchaseButtonHandler_)
	}))
end


function NewKofArenaShopMediator:onClickProductCellHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local selectCellIndex = checkint(sender:getTag())
    local PRODUCT_STRUCT  = SHOP_PROXY_STRUCT.SHOP_HOME_TAKE.PRODUCTS.PRODUCT_DATA
    local productVoProxy  = self.shopProxy_:get(PRODUCT_STRUCT, selectCellIndex)
    local leftStockCount  = productVoProxy:get(PRODUCT_STRUCT.STOCK_LEFT)
    -- local barUnlockLevel  = productVoProxy:get(PRODUCT_STRUCT.OPEN_LEVEL)

    -- check cardSkin type
    if CommonUtils.CheckIsOwnSkinById(productVoProxy:get(PRODUCT_STRUCT.GOODS_ID)) then
        app.uiMgr:ShowInformationTips(__('已经拥有该皮肤'))
        return
    end

    -- check purchased status
    if leftStockCount > 0 then
        -- if app.waterBarMgr:getBarLevel() >= barUnlockLevel then  -- TODO 等级取值不对
            local shopPurchaseData  = clone(productVoProxy:getData())
            shopPurchaseData.todayLeftPurchasedNum = shopPurchaseData.leftPurchasedNum  -- show today left count

            local shopPurchasePopup = require('Game.views.ShopPurchasePopup').new({data = shopPurchaseData, showChooseUi = true})
            shopPurchasePopup:setPosition(display.center)
            shopPurchasePopup:setName('shopPurchasePopup')
            shopPurchasePopup.viewData.purchaseBtn:setTag(selectCellIndex)
            shopPurchasePopup.viewData.purchaseBtn:setOnClickScriptHandler(handler(self, self.onClickSinglePurchaseButtonHandler_))
            app.uiMgr:GetCurrentScene():AddDialog(shopPurchasePopup)
        -- else
        --     app.uiMgr:ShowInformationTips(__('该商品未解锁'))
        -- end
    else
        app.uiMgr:ShowInformationTips(__('该商品已售罄'))
    end
end


function NewKofArenaShopMediator:onClickMultiPurchaseButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local buyGoodsMediator = app:RetrieveMediator('MultiBuyMediator')
    if buyGoodsMediator then
        local leftPurchasedMap = {}
        local PRODUCT_STRUCT   = SHOP_PROXY_STRUCT.SHOP_HOME_TAKE.PRODUCTS.PRODUCT_DATA
        for i = 1, self.shopProxy_:size(SHOP_PROXY_STRUCT.SHOP_HOME_TAKE.PRODUCTS) do
            local productVoProxy = self.shopProxy_:get(PRODUCT_STRUCT, i)
            local productId      = productVoProxy:get(PRODUCT_STRUCT.PRODUCT_ID)
            local leftStock      = productVoProxy:get(PRODUCT_STRUCT.STOCK_LEFT)
            leftPurchasedMap[tostring(productId)] = leftStock
        end
        
        local purchaseProductMap = {}
        for index, productId in ipairs(buyGoodsMediator:getAllBuyProduct()) do
            purchaseProductMap[tostring(productId)] = leftPurchasedMap[tostring(productId)]
        end
        self:toPurchaseProducts_(purchaseProductMap)
    end
end


function NewKofArenaShopMediator:onClickSinglePurchaseButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local selectCellIndex = checkint(sender:getTag())
    local purchasedCount  = checkint(sender:getUserTag())
    local PRODUCT_STRUCT  = SHOP_PROXY_STRUCT.SHOP_HOME_TAKE.PRODUCTS.PRODUCT_DATA
    local productVoProxy  = self.shopProxy_:get(PRODUCT_STRUCT, selectCellIndex)
    local selectProductId = productVoProxy:get(PRODUCT_STRUCT.PRODUCT_ID)
    self:toPurchaseProducts_({
        [tostring(selectProductId)] = purchasedCount
    })
end


return NewKofArenaShopMediator

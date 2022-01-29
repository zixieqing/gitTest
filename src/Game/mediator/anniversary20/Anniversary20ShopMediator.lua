--[[
 * author : kaishiqi
 * descpt : 2020周年庆 - 商店 中介者
]]
local Anniversary20ShopView     = require('Game.views.anniversary20.Anniversary20ShopView')
local Anniversary20ShopMediator = class('Anniversary20ShopMediator', mvc.Mediator)

local SHOP_TYPE_ENUM    = FOOD.ANNIV2020.SHOP.TYPE_ENUM
local SHOP_PROXY_NAME   = FOOD.ANNIV2020.SHOP.PROXY_NAME
local SHOP_PROXY_STRUCT = FOOD.ANNIV2020.SHOP.PROXY_STRUCT

function Anniversary20ShopMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'Anniversary20ShopMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end


-------------------------------------------------
-- inheritance

function Anniversary20ShopMediator:Initial(key)
    self.super.Initial(self, key)

    -- init vars
    local defaultType    = self.ctorArgs_.initType or SHOP_TYPE_ENUM.ACTIVITY
    local searchGoodsId  = checkint(self.ctorArgs_.goodsId)
    local initShopType   = searchGoodsId > 0 and SHOP_TYPE_ENUM.SEARCH or defaultType
    self.isControllable_ = true

    -- init model
    self.shopProxy_ = regVoProxy(SHOP_PROXY_NAME, SHOP_PROXY_STRUCT)
    self.shopProxy_:set(SHOP_PROXY_STRUCT.SELECT_TYPE, initShopType)
    self.shopProxy_:set(SHOP_PROXY_STRUCT.SEARCH_GOODS_ID, searchGoodsId)

    -- create view
    self.viewNode_ = Anniversary20ShopView.new()
    self:SetViewComponent(self:getViewNode())
    app.uiMgr:GetCurrentScene():AddDialog(self:getViewNode())

    -- add listener
    ui.bindClick(self:getViewData().blockLayer, handler(self, self.onClickBackLayerHandler_), false)
    ui.bindClick(self:getViewData().batchBuyBtn, handler(self, self.onClicBatchBuyButtonHandler_))
    self:getViewData().goodsGridView:setCellInitHandler(function(cellViewData)
        ui.bindClick(cellViewData.toggleView, handler(self, self.onClickProductCellHandler_))
        cellViewData.leftTimesLabel:setOnTextRichClickScriptHandler(handler(self, self.onClickProductCellHandler_))
    end)
    for index, typeTabButton in ipairs(self:getViewData().typeTabButtonList) do
        ui.bindClick(typeTabButton, handler(self, self.onClickTypeTabButtonHandler_), false)
    end
end


function Anniversary20ShopMediator:CleanupView()
    unregVoProxy(SHOP_PROXY_NAME)

    if self:getViewNode() and not tolua.isnull(self:getViewNode()) then
        self:getViewNode():removeFromParent()
        self.viewNode_ = nil
    end
end


function Anniversary20ShopMediator:OnRegist()
    regPost(POST.ANNIV2020_SHOP_BUY)
    regPost(POST.ANNIV2020_SHOP_HOME)

    self:SendSignal(POST.ANNIV2020_SHOP_HOME.cmdName)
end


function Anniversary20ShopMediator:OnUnRegist()
    unregPost(POST.ANNIV2020_SHOP_BUY)
    unregPost(POST.ANNIV2020_SHOP_HOME)
end


function Anniversary20ShopMediator:InterestSignals()
    return {
        POST.ANNIV2020_SHOP_BUY.sglName,
        POST.ANNIV2020_SHOP_HOME.sglName,
    }
end
function Anniversary20ShopMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()

    -------------------------------------------------
    if name == POST.ANNIV2020_SHOP_HOME.sglName then
        -- update shopHome takeData
        self.shopProxy_:set(SHOP_PROXY_STRUCT.SHOP_HOME_TAKE, data)

        
    -------------------------------------------------
    elseif name == POST.ANNIV2020_SHOP_BUY.sglName then
        -- update shopBuy takeData
        self.shopProxy_:set(SHOP_PROXY_STRUCT.SHOP_BUY_TAKE, data)

        -- show rewards
        local goodsRewrads = self.shopProxy_:get(SHOP_PROXY_STRUCT.SHOP_BUY_TAKE.REWARDS):getData()
        self:toPurchaseProductsCB_(goodsRewrads)

    end
end


-------------------------------------------------
-- get / set

function Anniversary20ShopMediator:getViewNode()
    return self.viewNode_
end
function Anniversary20ShopMediator:getViewData()
    return self:getViewNode():getViewData()
end


-------------------------------------------------
-- public

function Anniversary20ShopMediator:close()
    app:UnRegsitMediator(self:GetMediatorName())
end


function Anniversary20ShopMediator:closePurchasePopup()
    local buyGoodsMediator = app:RetrieveMediator('MultiBuyMediator')
    if buyGoodsMediator then
        buyGoodsMediator:close()
    end

    app.uiMgr:GetCurrentScene():RemoveDialogByName('shopPurchasePopup')
end


-------------------------------------------------
-- private

function Anniversary20ShopMediator:toPurchaseProducts_(purchaseProductMap)
    if next(checktable(purchaseProductMap)) == nil then return end

    -- reset select products
    local SELECT_STRUCT = SHOP_PROXY_STRUCT.SELECT_PRODUCT_MAP
    local selectVoProxy = self.shopProxy_:get(SELECT_STRUCT)
    self.shopProxy_:set(SELECT_STRUCT, purchaseProductMap)

    -- count total price
    local productIdList  = {}
    local useCurrencyNum = 0
    local PRODUCT_STRUCT = SHOP_PROXY_STRUCT.SHOP_HOME_TAKE.PRODUCTS.PRODUCT_DATA
    for productIndex = 1, self.shopProxy_:size(SHOP_PROXY_STRUCT.SHOP_HOME_TAKE.PRODUCTS) do
        local productVoProxy = self.shopProxy_:get(PRODUCT_STRUCT, productIndex)
        local productId      = productVoProxy:get(PRODUCT_STRUCT.PRODUCT_ID)
        local productPrice   = productVoProxy:get(PRODUCT_STRUCT.PRICE_NUM)
        local purchasedNum   = selectVoProxy:get(SELECT_STRUCT.PURCHASED_NUM, tostring(productId))
        if purchasedNum > 0 then
            useCurrencyNum = useCurrencyNum + (productPrice * purchasedNum)
            table.insert(productIdList, productId)
        end
    end
    
    -- check currency enough
    local shopCurrencyId = app.anniv2020Mgr:getShopCurrencyId()
    local hasCurrencyNum = app.gameMgr:GetAmountByIdForce(shopCurrencyId)
    if hasCurrencyNum >= useCurrencyNum then
        if #checktable(productIdList) > 1 then
            local BUY_STRUCT  = SHOP_PROXY_STRUCT.SHOP_MULTI_BUY_SEND
            local buyVoProxy  = self.shopProxy_:get(BUY_STRUCT)
            buyVoProxy:set(BUY_STRUCT.PRODUCT_IDS, table.concat(productIdList, ','))
            self:SendSignal(POST.ANNIV2020_SHOP_MULTI_BUY.cmdName, buyVoProxy:getData())
        else
            local BUY_STRUCT   = SHOP_PROXY_STRUCT.SHOP_BUY_SEND
            local buyVoProxy   = self.shopProxy_:get(BUY_STRUCT)
            local productId    = tostring(productIdList[1])
            local purchasedNum = selectVoProxy:get(SELECT_STRUCT.PURCHASED_NUM, productId)
            buyVoProxy:set(BUY_STRUCT.PRODUCT_ID, productId)
            buyVoProxy:set(BUY_STRUCT.PRODUCT_NUM, purchasedNum)
            self:SendSignal(POST.ANNIV2020_SHOP_BUY.cmdName, buyVoProxy:getData())
        end
        self:closePurchasePopup()

    else
        local currencyName = CommonUtils.GetCacheProductName(shopCurrencyId)
        app.uiMgr:ShowInformationTips(string.fmt(__('_des_不足'), {_des_ = currencyName}))
    end
end


function Anniversary20ShopMediator:toPurchaseProductsCB_(goodsRewrads)
    -- show rewards
    app.uiMgr:AddDialog('common.RewardPopup', {rewards = goodsRewrads})

    -- update purchased status
    local useCurrencyNum = 0
    local SELECT_STRUCT  = SHOP_PROXY_STRUCT.SELECT_PRODUCT_MAP
    local selectVoProxy  = self.shopProxy_:get(SELECT_STRUCT)
    local PRODUCT_STRUCT = SHOP_PROXY_STRUCT.SHOP_HOME_TAKE.PRODUCTS.PRODUCT_DATA
    for productIndex = 1, self.shopProxy_:size(SHOP_PROXY_STRUCT.SHOP_HOME_TAKE.PRODUCTS) do
        local productVoProxy = self.shopProxy_:get(PRODUCT_STRUCT, productIndex)
        local productId      = productVoProxy:get(PRODUCT_STRUCT.PRODUCT_ID)
        local productPrice   = productVoProxy:get(PRODUCT_STRUCT.PRICE_NUM)
        local purchasedNum   = selectVoProxy:get(SELECT_STRUCT.PURCHASED_NUM, tostring(productId))
        if purchasedNum > 0 then
            useCurrencyNum = useCurrencyNum + (productPrice * purchasedNum)
            productVoProxy:set(PRODUCT_STRUCT.STOCK_LEFT, productVoProxy:get(PRODUCT_STRUCT.STOCK_LEFT) - purchasedNum)
        end
    end
    
    -- consume currency
    local shopCurrencyId = app.anniv2020Mgr:getShopCurrencyId()
    CommonUtils.DrawRewards({
        {goodsId = shopCurrencyId, num = -useCurrencyNum}
    })
end


-------------------------------------------------
-- handler

function Anniversary20ShopMediator:onClickBackLayerHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end

    self:close()
end


function Anniversary20ShopMediator:onClickTypeTabButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end
    sender:setChecked(true)

    local tabShopType = checkint(sender:getTag())
    if self.shopProxy_:get(SHOP_PROXY_STRUCT.SELECT_TYPE) ~= tabShopType then
        self.shopProxy_:set(SHOP_PROXY_STRUCT.SELECT_TYPE, tabShopType)
    end
end


function Anniversary20ShopMediator:onClicBatchBuyButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    -- 因为是老界面，所以clone传数据过去避免污染这边的。
    -- 如果是 voProxy 实现的子界面，传入 PRODUCTS 的 voProxy 节点过去，子界面操作数据，外面就能及时得到事件做出更新。
    local allProductsData = {}
    local PRODUCT_STRUCT  = SHOP_PROXY_STRUCT.SHOP_HOME_TAKE.PRODUCTS.PRODUCT_DATA
    local shopLevel       = app.anniv2020Mgr:getShopLevel()
    for productIndex = 1, self.shopProxy_:size(SHOP_PROXY_STRUCT.SHOP_HOME_TAKE.PRODUCTS) do
        local productVoProxy  = self.shopProxy_:get(PRODUCT_STRUCT, productIndex)
        local shopUnlockLevel = productVoProxy:get(PRODUCT_STRUCT.OPEN_LEVEL)
        if shopLevel >= shopUnlockLevel then
            table.insert(allProductsData, clone(productVoProxy:getData()))
        end
    end

    app:RegistMediator(require('Game.mediator.stores.MultiBuyMediator').new({products = allProductsData,
        customBuyHandler = handler(self, self.onClickMultiPurchaseButtonHandler_)
	}))
end


function Anniversary20ShopMediator:onClickProductCellHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local selectCellIndex = checkint(sender:getTag())
    local PRODUCT_STRUCT  = SHOP_PROXY_STRUCT.SHOP_HOME_TAKE.PRODUCTS.PRODUCT_DATA
    local productVoProxy  = self.shopProxy_:get(PRODUCT_STRUCT, selectCellIndex)
    local leftStockCount  = productVoProxy:get(PRODUCT_STRUCT.STOCK_LEFT)
    local shopUnlockLevel = productVoProxy:get(PRODUCT_STRUCT.OPEN_LEVEL)

    -- check cardSkin type
    if CommonUtils.CheckIsOwnSkinById(productVoProxy:get(PRODUCT_STRUCT.GOODS_ID)) then
        app.uiMgr:ShowInformationTips(__('已经拥有该皮肤'))
        return
    end

    -- check purchased status
    if leftStockCount > 0 then
        local shopLevel = app.anniv2020Mgr:getShopLevel()
        if shopLevel >= shopUnlockLevel then
            local shopPurchaseData  = clone(productVoProxy:getData())
            shopPurchaseData.todayLeftPurchasedNum = shopPurchaseData.leftPurchasedNum  -- show today left count

            local shopPurchasePopup = require('Game.views.ShopPurchasePopup').new({data = shopPurchaseData, showChooseUi = true})
            shopPurchasePopup:setPosition(display.center)
            shopPurchasePopup:setName('shopPurchasePopup')
            shopPurchasePopup.viewData.purchaseBtn:setTag(selectCellIndex)
            shopPurchasePopup.viewData.purchaseBtn:setOnClickScriptHandler(handler(self, self.onClickSinglePurchaseButtonHandler_))
            app.uiMgr:GetCurrentScene():AddDialog(shopPurchasePopup)
        else
            app.uiMgr:ShowInformationTips(__('该商品未解锁'))
        end
    else
        app.uiMgr:ShowInformationTips(__('该商品已售罄'))
    end
end


function Anniversary20ShopMediator:onClickMultiPurchaseButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local buyGoodsMediator = app:RetrieveMediator('MultiBuyMediator')
    if buyGoodsMediator then
        local leftPurchasedMap = {}
        local PRODUCT_STRUCT   = SHOP_PROXY_STRUCT.SHOP_HOME_TAKE.PRODUCTS.PRODUCT_DATA
        for productIndex = 1, self.shopProxy_:size(SHOP_PROXY_STRUCT.SHOP_HOME_TAKE.PRODUCTS) do
            local productVoProxy = self.shopProxy_:get(PRODUCT_STRUCT, productIndex)
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


function Anniversary20ShopMediator:onClickSinglePurchaseButtonHandler_(sender)
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


return Anniversary20ShopMediator

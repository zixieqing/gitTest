--[[
 * author : kaishiqi
 * descpt : 武道会 - 商店中介者
]]
local ChampionshipShopView     = require('Game.views.championship.ChampionshipShopView')
local ChampionshipShopMediator = class('ChampionshipShopMediator', mvc.Mediator)

local SHOP_PROXY_NAME   = FOOD.CHAMPIONSHIP.SHOP.PROXY_NAME
local SHOP_PROXY_STRUCT = FOOD.CHAMPIONSHIP.SHOP.PROXY_STRUCT

function ChampionshipShopMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'ChampionshipShopMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end


-------------------------------------------------
-- inheritance

function ChampionshipShopMediator:Initial(key)
    self.super.Initial(self, key)

    -- init vars
    self.isControllable_ = true

    -- init model
    self.shopProxy_ = regVoProxy(SHOP_PROXY_NAME, SHOP_PROXY_STRUCT)

    -- create view
    self.viewNode_ = ChampionshipShopView.new()
    self:SetViewComponent(self:getViewNode())
    app.uiMgr:GetCurrentScene():AddDialog(self:getViewNode())

    -- add listener
    self.shopRefreshClocker_ = app.timerMgr.CreateClocker(handler(self, self.onShopRefreshUpdateHandler_))
    ui.bindClick(self:getViewData().blockLayer, handler(self, self.onClickBackLayerHandler_), false)
    ui.bindClick(self:getViewData().refreshBtn, handler(self, self.onClickRefreshButtonHandler_))
    ui.bindClick(self:getViewData().batchBuyBtn, handler(self, self.onClicBatchBuyButtonHandler_))
    self:getViewData().goodsGridView:setCellInitHandler(function(cellViewData)
        ui.bindClick(cellViewData.toggleView, handler(self, self.onClickProductCellHandler_))
        cellViewData.leftTimesLabel:setOnTextRichClickScriptHandler(handler(self, self.onClickProductCellHandler_))
    end)
end


function ChampionshipShopMediator:CleanupView()
    self.shopRefreshClocker_:stop()
    unregVoProxy(SHOP_PROXY_NAME)

    if self:getViewNode() and not tolua.isnull(self:getViewNode()) then
        self:getViewNode():removeFromParent()
        self.viewNode_ = nil
    end
end


function ChampionshipShopMediator:OnRegist()
    regPost(POST.CHAMPIONSHIP_SHOP_MULTI_BUY)
    regPost(POST.CHAMPIONSHIP_SHOP_BUY)
    regPost(POST.CHAMPIONSHIP_SHOP_HOME)
    regPost(POST.CHAMPIONSHIP_SHOP_REFRESH)

    self:SendSignal(POST.CHAMPIONSHIP_SHOP_HOME.cmdName)
end


function ChampionshipShopMediator:OnUnRegist()
    unregPost(POST.CHAMPIONSHIP_SHOP_MULTI_BUY)
    unregPost(POST.CHAMPIONSHIP_SHOP_BUY)
    unregPost(POST.CHAMPIONSHIP_SHOP_HOME)
    unregPost(POST.CHAMPIONSHIP_SHOP_REFRESH)
end


function ChampionshipShopMediator:InterestSignals()
    return {
        POST.CHAMPIONSHIP_SHOP_MULTI_BUY.sglName,
        POST.CHAMPIONSHIP_SHOP_BUY.sglName,
        POST.CHAMPIONSHIP_SHOP_HOME.sglName,
        POST.CHAMPIONSHIP_SHOP_REFRESH.sglName,
    }
end
function ChampionshipShopMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()

    -------------------------------------------------
    if name == POST.CHAMPIONSHIP_SHOP_HOME.sglName then
        -- update shopHome takeData
        self.shopProxy_:set(SHOP_PROXY_STRUCT.SHOP_HOME_TAKE, data.championship)

        -- update refreshTimestamp
        local refreshLeftSeconds = self.shopProxy_:get(SHOP_PROXY_STRUCT.SHOP_HOME_TAKE.REFRESH_LEFT_SECONDS)
        self.shopProxy_:set(SHOP_PROXY_STRUCT.REFRESH_TIMESTAMP, os.time() + math.max(refreshLeftSeconds, 1)) -- 防止返回0秒变成无限刷新

        -- start shopRefreshClocker
        self.shopRefreshClocker_:start()

        
    -------------------------------------------------
    elseif name == POST.CHAMPIONSHIP_SHOP_REFRESH.sglName then
        -- update shopRefresh takeData
        self.shopProxy_:set(SHOP_PROXY_STRUCT.SHOP_REFRESH_TAKE, data)

        -- update leftTimes
        local refreshLeftTimes = self.shopProxy_:get(SHOP_PROXY_STRUCT.SHOP_HOME_TAKE.REFRESH_LEFT_TIEMS)
        self.shopProxy_:set(SHOP_PROXY_STRUCT.SHOP_HOME_TAKE.REFRESH_LEFT_TIEMS, refreshLeftTimes - 1)

        -- update shopHome products
        local newProducts = self.shopProxy_:get(SHOP_PROXY_STRUCT.SHOP_REFRESH_TAKE.PRODUCTS):getData()
        self.shopProxy_:set(SHOP_PROXY_STRUCT.SHOP_HOME_TAKE.PRODUCTS, newProducts)

        -- update player diamond
        local playerDiamond = self.shopProxy_:get(SHOP_PROXY_STRUCT.SHOP_REFRESH_TAKE.DIAMOND)
        app.gameMgr:GetUserInfo().diamond = playerDiamond
        app:DispatchObservers(SGL.CACHE_MONEY_UPDATE_UI)


    -------------------------------------------------
    elseif name == POST.CHAMPIONSHIP_SHOP_BUY.sglName then
        -- update shopBuy takeData
        self.shopProxy_:set(SHOP_PROXY_STRUCT.SHOP_BUY_TAKE, data)

        -- show rewards
        local goodsRewrads = self.shopProxy_:get(SHOP_PROXY_STRUCT.SHOP_BUY_TAKE.REWARDS):getData()
        self:toPurchaseProductsCB_(goodsRewrads)


    -------------------------------------------------
    elseif name == POST.CHAMPIONSHIP_SHOP_MULTI_BUY.sglName then
        -- update shopBuy takeData
        self.shopProxy_:set(SHOP_PROXY_STRUCT.SHOP_MULTI_BUY_TAKE, data)

        -- show rewards
        local goodsRewrads = self.shopProxy_:get(SHOP_PROXY_STRUCT.SHOP_MULTI_BUY_TAKE.REWARDS):getData()
        self:toPurchaseProductsCB_(goodsRewrads)
    end
end


-------------------------------------------------
-- get / set

function ChampionshipShopMediator:getViewNode()
    return self.viewNode_
end
function ChampionshipShopMediator:getViewData()
    return self:getViewNode():getViewData()
end


-------------------------------------------------
-- public

function ChampionshipShopMediator:close()
    app:UnRegsitMediator(self:GetMediatorName())
end


function ChampionshipShopMediator:closePurchasePopup()
    local buyGoodsMediator = app:RetrieveMediator('MultiBuyMediator')
    if buyGoodsMediator then
        buyGoodsMediator:close()
    end

    app.uiMgr:GetCurrentScene():RemoveDialogByName('shopPurchasePopup')
end


-------------------------------------------------
-- private

function ChampionshipShopMediator:toPurchaseProducts_(productIdList)
    if #checktable(productIdList) == 0 then return end

    -- reset select products
    local SELECT_STRUCT    = SHOP_PROXY_STRUCT.SELECT_PRODUCT_MAP
    local selectProductMap = {}
    for index, productId in ipairs(checktable(productIdList)) do
        selectProductMap[tostring(productId)] = true
    end
    self.shopProxy_:set(SELECT_STRUCT, selectProductMap)

    -- count total price
    local shopCurrencyId = FOOD.GOODS.DEFINE.CHAMPIONSHIP_CURRENCY_ID
    local hasCurrencyNum = app.gameMgr:GetAmountByIdForce(shopCurrencyId)
    local useCurrencyNum = 0
    local totalGoodsNum  = 0
    local PRODUCT_STRUCT = SHOP_PROXY_STRUCT.SHOP_HOME_TAKE.PRODUCTS.PRODUCT_DATA
    for i = 1, self.shopProxy_:size(SHOP_PROXY_STRUCT.SHOP_HOME_TAKE.PRODUCTS) do
        local productVoProxy = self.shopProxy_:get(PRODUCT_STRUCT, i)
        local productId      = productVoProxy:get(PRODUCT_STRUCT.PRODUCT_ID)
        local goodsNum       = productVoProxy:get(PRODUCT_STRUCT.GOODS_NUM)
        local productPrice   = productVoProxy:get(PRODUCT_STRUCT.PRICE_NUM)
        if selectProductMap[tostring(productId)] then
            useCurrencyNum = useCurrencyNum + productPrice
            totalGoodsNum  = totalGoodsNum + goodsNum
        end
    end

    -- check currency enough
    if hasCurrencyNum >= useCurrencyNum then
        if #checktable(productIdList) > 1 then
            local BUY_STRUCT  = SHOP_PROXY_STRUCT.SHOP_MULTI_BUY_SEND
            local buyVoProxy  = self.shopProxy_:get(BUY_STRUCT)
            buyVoProxy:set(BUY_STRUCT.PRODUCT_IDS, table.concat(productIdList, ','))
            self:SendSignal(POST.CHAMPIONSHIP_SHOP_MULTI_BUY.cmdName, buyVoProxy:getData())
        else
            local BUY_STRUCT  = SHOP_PROXY_STRUCT.SHOP_BUY_SEND
            local buyVoProxy  = self.shopProxy_:get(BUY_STRUCT)
            buyVoProxy:set(BUY_STRUCT.PRODUCT_ID, productIdList[1])
            buyVoProxy:set(BUY_STRUCT.PRODUCT_NUM, totalGoodsNum)
            self:SendSignal(POST.CHAMPIONSHIP_SHOP_BUY.cmdName, buyVoProxy:getData())
        end
        self:closePurchasePopup()

    else
        local currencyName = CommonUtils.GetCacheProductName(shopCurrencyId)
        app.uiMgr:ShowInformationTips(string.fmt(__('_des_不足'), {_des_ = currencyName}))
    end
end


function ChampionshipShopMediator:toPurchaseProductsCB_(goodsRewrads)
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
        if selectVoProxy:get(SELECT_STRUCT.SELECTED, tostring(productId)) then
            useCurrencyNum = useCurrencyNum + productPrice
            productVoProxy:set(PRODUCT_STRUCT.PURCHASED, 1)
        end
    end
    
    -- consume currency
    local shopCurrencyId = FOOD.GOODS.DEFINE.CHAMPIONSHIP_CURRENCY_ID
    CommonUtils.DrawRewards({
        {goodsId = shopCurrencyId, num = -useCurrencyNum}
    })
end


-------------------------------------------------
-- handler

function ChampionshipShopMediator:onClickBackLayerHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end

    self:close()
end


function ChampionshipShopMediator:onShopRefreshUpdateHandler_()
    local currentTime = os.time()
    local refreshTime = self.shopProxy_:get(SHOP_PROXY_STRUCT.REFRESH_TIMESTAMP)
    local leftSeconds = refreshTime - currentTime

    if leftSeconds >= 0 then
        self.shopProxy_:set(SHOP_PROXY_STRUCT.SHOP_HOME_TAKE.REFRESH_LEFT_SECONDS, leftSeconds)
    else
        self:closePurchasePopup()
        self.shopRefreshClocker_:stop()
        self:SendSignal(POST.CHAMPIONSHIP_SHOP_HOME.cmdName)
    end
end


function ChampionshipShopMediator:onClickRefreshButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local leftTimes   = self.shopProxy_:get(SHOP_PROXY_STRUCT.SHOP_HOME_TAKE.REFRESH_LEFT_TIEMS)
    local costDiamond = self.shopProxy_:get(SHOP_PROXY_STRUCT.SHOP_HOME_TAKE.REFRESH_DIAMOND)
    if leftTimes > 0 then
        local tipsDescr = string.fmt(__('是否使用_num_个幻晶石进行商店刷新？'), {_num_ = costDiamond})
        app.uiMgr:AddNewCommonTipDialog({text = tipsDescr, callback = function()
            self:SendSignal(POST.CHAMPIONSHIP_SHOP_REFRESH.cmdName)
        end})
        
    else
        app.uiMgr:ShowInformationTips(__('今日刷新次数已用完'))
    end
end


function ChampionshipShopMediator:onClicBatchBuyButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    -- 因为是老界面，所以clone传数据过去避免污染这边的。
    -- 如果是 voProxy 实现的子界面，传入 PRODUCTS 的 voProxy 节点过去，子界面操作数据，外面就能及时得到事件做出更新。
    local allProductsData = clone(self.shopProxy_:get(SHOP_PROXY_STRUCT.SHOP_HOME_TAKE.PRODUCTS):getData())
    app:RegistMediator(require('Game.mediator.stores.MultiBuyMediator').new({products = allProductsData,
        customBuyHandler = handler(self, self.onClickMultiPurchaseButtonHandler_)
	}))
end


function ChampionshipShopMediator:onClickProductCellHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local selectCellIndex = checkint(sender:getTag())
    local PRODUCT_STRUCT  = SHOP_PROXY_STRUCT.SHOP_HOME_TAKE.PRODUCTS.PRODUCT_DATA
    local productVoProxy  = self.shopProxy_:get(PRODUCT_STRUCT, selectCellIndex)

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


function ChampionshipShopMediator:onClickMultiPurchaseButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local buyGoodsMediator = app:RetrieveMediator('MultiBuyMediator')
    if buyGoodsMediator then
        local productList = buyGoodsMediator:getAllBuyProduct()
        self:toPurchaseProducts_(productList)
    end
end


function ChampionshipShopMediator:onClickSinglePurchaseButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local selectCellIndex = checkint(sender:getTag())
    local PRODUCT_STRUCT  = SHOP_PROXY_STRUCT.SHOP_HOME_TAKE.PRODUCTS.PRODUCT_DATA
    local productVoProxy  = self.shopProxy_:get(PRODUCT_STRUCT, selectCellIndex)
    local selectProductId = productVoProxy:get(PRODUCT_STRUCT.PRODUCT_ID)
    self:toPurchaseProducts_({selectProductId})
end


return ChampionshipShopMediator

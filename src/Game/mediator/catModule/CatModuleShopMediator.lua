--[[
 * author : panmeng
 * descpt : 猫咪市场
]]
local CatModuleShopView     = require('Game.views.catModule.CatModuleShopView')
local CatModuleShopMediator = class('CatModuleShopMediator', mvc.Mediator)

function CatModuleShopMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'CatModuleShopMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end


-------------------------------------------------
-- inheritance

function CatModuleShopMediator:Initial(key)
    self.super.Initial(self, key)

    -- init vars
    self.isControllable_ = true

    -- create view
    self.viewNode_ = CatModuleShopView.new()
    self:SetViewComponent(self:getViewNode())
    app.uiMgr:GetCurrentScene():AddDialog(self:getViewNode())

    -- add listener
    self.leftTimeRefreshClocker_ = app.timerMgr.CreateClocker(handler(self, self.onLeftTimeRefreshUpdateHandler_))
    ui.bindClick(self:getViewData().blockLayer, handler(self, self.onClickBackButtonHandler_), false)
    ui.bindClick(self:getViewData().batchBuyBtn, handler(self, self.onClickBatchBuyButtonHandler_))
    -- for _, btnNode in pairs(self:getViewData().tabBtns) do
    --     btnNode:setOnClickScriptHandler(handler(self, self.onClickTabButtonHandler_))
    -- end
    self:getViewData().goodsGridView:setCellInitHandler(function(cellViewData)
        cellViewData.toggleView:setOnClickScriptHandler(handler(self, self.onClickBuyButtonHandler_))
        cellViewData.goodNode:setTouchEnabled(false)
    end)
    self:getViewData().goodsGridView:setCellUpdateHandler(handler(self, self.onUpdateGoodsCellHandler_))

    -- self:setSelectedTabTag(1)
end


function CatModuleShopMediator:CleanupView()
    self.leftTimeRefreshClocker_:stop()
    if self:getViewNode() and not tolua.isnull(self:getViewNode()) then
        self:getViewNode():removeFromParent()
        self.viewNode_ = nil
    end
end


function CatModuleShopMediator:OnRegist()
    regPost(POST.HOUSE_CAT_MALL_HOME)
    regPost(POST.HOUSE_CAT_MALL_BUY)
    regPost(POST.HOUSE_CAT_MALL_BATCH_BUY)

    self:SendSignal(POST.HOUSE_CAT_MALL_HOME.cmdName)
end


function CatModuleShopMediator:OnUnRegist()
    unregPost(POST.HOUSE_CAT_MALL_HOME)
    unregPost(POST.HOUSE_CAT_MALL_BUY)
    unregPost(POST.HOUSE_CAT_MALL_BATCH_BUY)
end


function CatModuleShopMediator:InterestSignals()
    return {
        POST.HOUSE_CAT_MALL_HOME.sglName,
        POST.HOUSE_CAT_MALL_BUY.sglName,
        POST.HOUSE_CAT_MALL_BATCH_BUY.sglName,
    }
end
function CatModuleShopMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()

    if name == POST.HOUSE_CAT_MALL_HOME.sglName then
        self:setProductData(data.products)
        self:setLeftSecondsTime(data.refreshLeftSeconds)


    elseif name == POST.HOUSE_CAT_MALL_BUY.sglName then
        local goodsBuyNum = checkint(data.requestData.num)
        local goodsId     = checkint(data.requestData.productId)
        local goodData    = self:getSelectedGoodData()

        -- sub leftPurchasedNum
        goodData.leftPurchasedNum = goodData.leftPurchasedNum - goodsBuyNum

        -- consume currency
        local currencyId = checkint(goodData.currency)
        local consumeNum = checkint(goodData.price) * goodsBuyNum
        CommonUtils.DrawRewards({{goodsId = currencyId, num = -consumeNum}})

        -- close storePurchasePopup
        if self.purchasePopup_ and not tolua.isnull(self.purchasePopup_) then
            self.purchasePopup_:runAction(cc.RemoveSelf:create())
            self.purchasePopup_ = nil
        end
        
        -- draw rewards
        app.uiMgr:AddDialog('common.RewardPopup', {rewards = data.rewards})
        
        -- update goods cell
        for cellViewNode, cellViewData in pairs(self:getViewData().goodsGridView:getCellViewDataDict()) do
            if self:getSelectedGoodIdByCellIndex() == cellViewData.toggleView:getTag() then
                self:getViewData().goodsGridView:updateCellViewData(self:getSelectedGoodIdByCellIndex())
                break
            end
        end


    elseif name == POST.HOUSE_CAT_MALL_BATCH_BUY.sglName then
        -- draw rewards
        app.uiMgr:AddDialog('common.RewardPopup', {rewards = data.rewards})

        -- update data
        local boughtGoodsMap = {}
        local currencyMap    = {}
        for _, goodsData in pairs(data.rewards or {}) do
            boughtGoodsMap[checkint(goodsData.goodsId)] = checkint(goodsData.num)
        end
        for _, goodsData in pairs(self:getProductData()) do
            local boughtNum = checkint(boughtGoodsMap[checkint(goodsData.goodsId)])
            if boughtNum > 0 then
                goodsData.leftPurchasedNum = math.max(goodsData.leftPurchasedNum - boughtNum, 0)
                currencyMap[checkint(goodsData.currency)] = checkint(currencyMap[checkint(goodsData.currency)]) + goodsData.price * boughtNum
            end
        end

        -- convert map to list
        local currencyList = {}
        for currencyId, currencyData in pairs(currencyMap) do
            table.insert(currencyList, {goodsId = currencyId, num = -currencyData})
        end
        
        -- consume currency
        if #currencyList then
            CommonUtils.DrawRewards(currencyList)
        end

        -- update page
        self:getViewData().goodsGridView:resetCellCount(#self:getProductData())


    end
end


-------------------------------------------------
-- get / set

function CatModuleShopMediator:getViewNode()
    return  self.viewNode_
end
function CatModuleShopMediator:getViewData()
    return self:getViewNode():getViewData()
end


function CatModuleShopMediator:setProductData(productData)
    self.productData_ = checktable(productData)
    self:getViewData().goodsGridView:resetCellCount(#self:getProductData())
end
function CatModuleShopMediator:getProductData()
    return checktable(self.productData_)
end


function CatModuleShopMediator:setLeftSecondsTime(leftSeconds)
    self.refreshLeftSeconds_ = checkint(leftSeconds) + os.time()

    if leftSeconds > 0 then
        self.leftTimeRefreshClocker_:start()
    end
end
function CatModuleShopMediator:getLeftSecondsTime()
    return checkint(self.refreshLeftSeconds_)
end


function CatModuleShopMediator:getSelectedProductId()
    return checkint(self:getSelectedGoodData().productId)
end
function CatModuleShopMediator:getSelectedGoodData()
    return checktable(self.selectedGoodData_)
end


function CatModuleShopMediator:getSelectedGoodIdByCellIndex()
    return checkint(self.selectedGoodIdByCellIndex_)
end
function CatModuleShopMediator:setSelectedGoodIdByCellIndex(cellIndex)
    self.selectedGoodIdByCellIndex_ = checkint(cellIndex)
    self.selectedGoodData_ = self:getProductData()[cellIndex]
    
    local goodData = clone(self:getSelectedGoodData())
    goodData.todayLeftPurchasedNum = goodData.leftPurchasedNum
    self.purchasePopup_ = app.uiMgr:AddDialog('Game.views.ShopPurchasePopup', {data = goodData, showChooseUi = true})
    self.purchasePopup_.viewData.purchaseBtn:setOnClickScriptHandler(handler(self, self.onClickPurposeBtnHandler_))
end


-- function CatModuleShopMediator:setSelectedTabTag(tabTag)
--     self.selectedTabIndex = checkint(tabTag)

--     self:getViewNode():setSelectedTabIndex(self:getSelectedTabTag())
--     self:getViewData().goodsGridView:resetCellCount(15)
-- end
-- function CatModuleShopMediator:getSelectedTabTag()
--     return checkint(self.selectedTabIndex)
-- end


-- function CatModuleShopMediator:getGoodDatasByTabTag(tabTag)
--     local tabIndex = checkint(tabTag) > 0 and checkint(tabTag) or self:getSelectedTabTag()
-- end


-------------------------------------------------
-- public

function CatModuleShopMediator:close()
    app:UnRegsitMediator(self:GetMediatorName())
end


function CatModuleShopMediator:checkCurrencyIsFit(productIdList)
    local productIdMap = {}
    local currencyMap  = {}
    for _, productId in pairs(productIdList or {}) do
        productIdMap[checkint(productId)] = true
    end
    for _, goodsData in pairs(self:getProductData()) do
        if productIdMap[checkint(goodsData.productId)] == true then
            currencyMap[checkint(goodsData.currency)] = checkint(currencyMap[checkint(goodsData.currency)]) + goodsData.leftPurchasedNum * goodsData.price
        end
    end
    local currencyDataList = {}
    for currencyId, currencyNum in pairs(currencyMap) do
        table.insert(currencyDataList, {goodsId = currencyId, num = currencyNum})
    end

    return GoodsUtils.CheckMultipCosts(currencyDataList, true)
end

-------------------------------------------------
-- handler

function CatModuleShopMediator:onLeftTimeRefreshUpdateHandler_()
    local curTime = self:getLeftSecondsTime() - os.time()

    if curTime <= 0 then
        self.leftTimeRefreshClocker_:stop()
        self:SendSignal(POST.HOUSE_CAT_MALL_HOME.cmdName)
    else
        self:getViewNode():refershShopUpdateLeftTime(curTime)
    end
end


function CatModuleShopMediator:onUpdateGoodsCellHandler_(cellIndex, cellViewData)
    local goodData = self:getProductData()[cellIndex]
    self:getViewNode():setCellUpdateHandler(cellIndex, cellViewData, goodData)
end


function CatModuleShopMediator:onClickBackButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end

    self:close()
end


-- function CatModuleShopMediator:onClickTabButtonHandler_(sender)
--     PlayAudioByClickNormal()
--     if not self.isControllable_ then return end

--     self:setSelectedTabTag(sender:getTag())
-- end


function CatModuleShopMediator:onClickPurposeBtnHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local buyNum         = sender:getUserTag()
    local goodsData      = self:getSelectedGoodData()
    local goodsCurrency  = checkint(goodsData.currency)
	local hasCurrencyNum = app.gameMgr:GetAmountByIdForce(goodsCurrency)
	local useCurrencyNum = goodsData.price * checkint(buyNum)

 	if checkint(hasCurrencyNum) >= checkint(useCurrencyNum) then
 		self:SendSignal(POST.HOUSE_CAT_MALL_BUY.cmdName, {productId = self:getSelectedProductId(), num = buyNum})
	else
        local currencyName = CommonUtils.GetCacheProductName(goodsCurrency)
		app.uiMgr:ShowInformationTips(string.fmt(__('_des_不足'),{_des_ = currencyName}))
	end
end


function CatModuleShopMediator:onClickBuyButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    self:setSelectedGoodIdByCellIndex(sender:getTag())
end


function CatModuleShopMediator:onClickBatchBuyButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end


    app:RegistMediator(require('Game.mediator.stores.MultiBuyMediator').new({
        products = self:getProductData(),
        customBuyHandler = handler(self, self.onClickMultiPurchaseButtonHandler_)
    }))
end


function CatModuleShopMediator:onClickMultiPurchaseButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local buyGoodsMediator = app:RetrieveMediator('MultiBuyMediator')
    local productIdList = {}
    if buyGoodsMediator then
        productIdList = buyGoodsMediator:getAllBuyProduct()
        if self:checkCurrencyIsFit(productIdList) then
            self:SendSignal(POST.HOUSE_CAT_MALL_BATCH_BUY.cmdName, {products = table.concat(productIdList, ',')})
            app:UnRegsitMediator('MultiBuyMediator')
        end
    end
    
end

return CatModuleShopMediator

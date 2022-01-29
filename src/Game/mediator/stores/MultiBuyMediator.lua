--[[
 * author : kaishiqi
 * descpt : 多个购买 中介者
]]
local MultiBuyMediator = class('MultiBuyMediator', mvc.Mediator)

local RES_DICT = {
    BG_FRAME    = _res('ui/common/common_bg_2.png'),
    BG_GOODS    = _res('ui/common/common_bg_goods.png'),
    TITLE_BAR   = _res('ui/common/common_bg_title_2.png'),
    BTN_BUY_N   = _res('ui/common/common_btn_orange.png'),
    BTN_BUY_D   = _res('ui/common/common_btn_orange_disable.png'),
    BTN_CHECK_D = _res('ui/common/common_btn_check_default.png'),
    BTN_CHECK_S = _res('ui/common/common_btn_check_selected.png'),
}

local CreateView      = nil
local CreateGoodsCell = nil


function MultiBuyMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'MultiBuyMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end


-------------------------------------------------
-- inheritance

function MultiBuyMediator:Initial(key)
    self.super.Initial(self, key)

    -- init vars
    local allProducts   = self.ctorArgs_.products or {}
    self.buyAllPostCmd_ = self.ctorArgs_.postCmd
    self.refreshCB_     = self.ctorArgs_.refreshCB
    self.currencyId_    = checkint(checktable(allProducts[1]).currency)
    self.totalPrice_    = 0
    self.customBuyCB_   = self.ctorArgs_.customBuyHandler
    self.goodsCellDict_ = {}
    self.buyProductMap_ = {}
    
    -- create view
    self.commonBG_ = require('common.CloseBagNode').new({callback = function()
        PlayAudioByClickClose()
        self:close()
    end})
    self.commonBG_:setName('CLOSE_BAG') 
    self.commonBG_:setPosition(display.center)
    app.uiMgr:GetCurrentScene():AddDialog(self.commonBG_)
    
    self.viewData_ = CreateView()
    self.commonBG_:addContentView(self.viewData_.view)
    
    -- add listen
    display.commonUIParams(self:getViewData().buyAllBtn, {cb = self.customBuyCB_ or handler(self, self.onBuyAllButtonHandler_)})
    self:getViewData().goodsGridView:setDataSourceAdapterScriptHandler(handler(self, self.onGoodsGridDataAdapterHandler_))
    
    -- init status
    local productsData = {}
    for _, productData in ipairs(allProducts) do
        if not CommonUtils.CheckIsOwnSkinById(productData.goodsId) then
            if not CommonUtils.CheckLockCondition(productData.unlockType) then
                if productData.leftPurchasedNum and checkint(productData.leftPurchasedNum) > 0 then
                    table.insert(productsData, productData)
                elseif productData.purchased and checkint(productData.purchased) == 0 then
                    table.insert(productsData, productData)
                end
            end
        end
    end
    self:setStoreGoodsData(productsData)
    self:allBuyProduct()
end


function MultiBuyMediator:CleanupView()
    local rootView = self.commonBG_
    if rootView and (not tolua.isnull(rootView)) then
        rootView:runAction(cc.RemoveSelf:create())
        rootView = nil
    end
end


function MultiBuyMediator:OnRegist()
    if self.buyAllPostCmd_ then
        regPost(self.buyAllPostCmd_)
    end
end
function MultiBuyMediator:OnUnRegist()
    if self.buyAllPostCmd_ then
        unregPost(self.buyAllPostCmd_)
    end
end


function MultiBuyMediator:InterestSignals()
    local interestSignals = {}
    if self.buyAllPostCmd_ then
        table.insert(interestSignals, self.buyAllPostCmd_.sglName)
    end
    return interestSignals
end
function MultiBuyMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()

    if self.buyAllPostCmd_ and name == self.buyAllPostCmd_.sglName then
        -- update cache data
        for index, goodsData in ipairs(self:getStoreGoodsData()) do
            if self:hasBuyProduct(goodsData.productId) then
                if goodsData.purchased then
                    goodsData.purchased = 1
                end
                if goodsData.leftPurchasedNum then
                    goodsData.leftPurchasedNum = 0
                end
            end
        end

        if self.refreshCB_ then
            self.refreshCB_()
        end
        
        -- consume currency
        CommonUtils.DrawRewards({
            {goodsId = self.currencyId_, num = -self.totalPrice_}
        })
        
        -- show rewards
        app.uiMgr:AddDialog('common.RewardPopup', {rewards = data.rewards})

        -- close self
        self:close()
    end
end


-------------------------------------------------
-- view defines

CreateView = function()
    local size = cc.size(740, 520)
    local view = display.newLayer(0, 0, {size = size, bg = RES_DICT.BG_FRAME, scale9 = true})
    
    -- title bar
    local titleBar = display.newButton(size.width/2, size.height - 4, {n = RES_DICT.TITLE_BAR, ap = display.CENTER_TOP, enable = false})
    display.commonLabelParams(titleBar, fontWithColor(3, {text = __('快速购买'), paddingW = 60, safeW = 120, offset = cc.p(0,-1)}))
    view:addChild(titleBar)
    
    -- goodsBg
    local goodsBgSize = cc.size(size.width - 60, size.height - 190)
    local goodsBgPos  = cc.p(titleBar:getPositionX(), titleBar:getPositionY() - titleBar:getContentSize().height - 12)
    view:addChild(display.newImageView(RES_DICT.BG_GOODS, goodsBgPos.x, goodsBgPos.y, {ap = display.CENTER_TOP, scale9 = true, size = goodsBgSize}))
    
    -- goods gridView
    local goodsGridCols = 5
    local goodsGridSize = cc.size(goodsBgSize.width - 6, goodsBgSize.height - 6)
    local goodsFramePos = cc.p(goodsBgPos.x, goodsBgPos.y - goodsBgSize.height/2)
    local goodsCellSize = cc.size(math.floor(goodsGridSize.width/goodsGridCols), 150)
    local goodsGridView = CGridView:create(goodsGridSize)
    goodsGridView:setAnchorPoint(display.CENTER)
    goodsGridView:setSizeOfCell(goodsCellSize)
    goodsGridView:setPosition(goodsFramePos)
    goodsGridView:setColumns(goodsGridCols)
    -- goodsGridView:setBackgroundColor(cc.r4b(150))
    view:addChild(goodsGridView)

    -- buyAll button
    local buyAllBtn = display.newButton(size.width/2, 90, {n = RES_DICT.BTN_BUY_N, d = RES_DICT.BTN_BUY_D})
    display.commonLabelParams(buyAllBtn, fontWithColor(14, {text = __('购买')}))
    view:addChild(buyAllBtn)

    -- totalPrice info
    local totalPricePoint  = cc.p(size.width/2, buyAllBtn:getPositionY() - 55)
    local totalPriceBrand  = display.newLabel(totalPricePoint.x, totalPricePoint.y, fontWithColor(16, {text = __('总价'), ap = display.RIGHT_CENTER}))
    local totalPriceLabel  = display.newLabel(totalPricePoint.x, totalPricePoint.y, fontWithColor(14, {text = '----'}))
    local currencyImgLayer = display.newLayer(totalPricePoint.x, totalPricePoint.y, {ap = display.LEFT_BOTTOM})
    view:addChild(totalPriceBrand)
    view:addChild(totalPriceLabel)
    view:addChild(currencyImgLayer)

    return {
        view             = view,
        goodsGridView    = goodsGridView,
        totalPriceBrand  = totalPriceBrand,
        totalPriceLabel  = totalPriceLabel,
        currencyImgLayer = currencyImgLayer,
        buyAllBtn        = buyAllBtn,
    }
end


CreateGoodsCell = function(size)
    local view = CGridViewCell:new()
    view:setContentSize(size)

    -- name label
    -- local nameLabel = display.newLabel(size.width/2, 13, fontWithColor(16, {fontWize = 20}))
    -- view:addChild(nameLabel)

    -- icon node
    local iconNode = require('common.GoodNode').new({showAmount = true, showName = true})
    iconNode:setPosition(size.width/2, size.height/2 + 10)
    view:addChild(iconNode)

    -- buy cbox
    local buyCBox = display.newToggleView(size.width, size.height, {n = RES_DICT.BTN_CHECK_D, s = RES_DICT.BTN_CHECK_S, ap = display.RIGHT_TOP})
    view:addChild(buyCBox)

    -- hotspot
    local hotspot = display.newLayer(0, 0, {size = size, color = cc.r4b(0), enable = true})
    view:addChild(hotspot)
    
    return {
        view      = view,
        hotspot   = hotspot,
        buyCBox   = buyCBox,
        iconNode  = iconNode,
    }
end


-------------------------------------------------
-- get / set

function MultiBuyMediator:getViewData()
    return self.viewData_
end


function MultiBuyMediator:getStoreGoodsData()
    return self.storeGoodsData_ or {}
end
function MultiBuyMediator:setStoreGoodsData(goodsData)
    self.storeGoodsData_ = checktable(goodsData)
    self:updateGoodsGridView_()
end


function MultiBuyMediator:getCurrencyId()
    return checkint(self.currencyId_)
end


function MultiBuyMediator:hasBuyProduct(productId)
    return self.buyProductMap_[tostring(productId)] == true
end
function MultiBuyMediator:addBuyProduct(productId)
    self.buyProductMap_[tostring(productId)] = true
    self:updateTotalPriceInfo_()

    for index, goodsData in ipairs(self:getStoreGoodsData()) do
        if checkint(goodsData.productId) == checkint(productId) then
            self:updateGoodsCell_(index)
            break
        end
    end
end
function MultiBuyMediator:removeBuyProduct(productId)
    self.buyProductMap_[tostring(productId)] = nil
    self:updateTotalPriceInfo_()

    for index, goodsData in ipairs(self:getStoreGoodsData()) do
        if checkint(goodsData.productId) == checkint(productId) then
            self:updateGoodsCell_(index)
            break
        end
    end
end
function MultiBuyMediator:allBuyProduct()
    for index, goodsData in ipairs(self:getStoreGoodsData()) do
        self.buyProductMap_[tostring(goodsData.productId)] = true
    end
    for _, cellViewData in pairs(self.goodsCellDict_) do
        self:updateGoodsCell_(cellViewData.view:getTag(), cellViewData)
    end
    self:updateTotalPriceInfo_()
end


function MultiBuyMediator:getAllBuyProduct()
    return table.keys(self.buyProductMap_)
end


-------------------------------------------------
-- public

function MultiBuyMediator:close()
    self:GetFacade():UnRegsitMediator(self:GetMediatorName())
end


-------------------------------------------------
-- private

function MultiBuyMediator:updateTotalPriceInfo_()
    -- update price
    local totalPrice = 0
    local currencyId = self:getCurrencyId()
    local goodsPath  = CommonUtils.GetGoodsIconPathById(currencyId)
    for _, goodsData in ipairs(self:getStoreGoodsData()) do
        if self:hasBuyProduct(goodsData.productId) then
            if goodsData.leftPurchasedNum then
                totalPrice = totalPrice + checkint(goodsData.price) * math.max(checkint(goodsData.leftPurchasedNum), 1)
            else
                totalPrice = totalPrice + checkint(goodsData.price)
            end
        end
    end
    self.totalPrice_ = totalPrice
    
    -- update views
    local viewData = self:getViewData()
    viewData.buyAllBtn:setEnabled(self.totalPrice_ > 0)
    display.commonLabelParams(viewData.totalPriceLabel, {text = tostring(totalPrice)})
    
    local priceLabelPosX = viewData.totalPriceLabel:getPositionX()
    local priceLabelSize = display.getLabelContentSize(viewData.totalPriceLabel)
    viewData.totalPriceBrand:setPositionX(priceLabelPosX - priceLabelSize.width/2 - 10)
    viewData.currencyImgLayer:setPositionX(priceLabelPosX + priceLabelSize.width/2 + 10)
    viewData.currencyImgLayer:addChild(display.newImageView(_res(goodsPath), 0, 0, {scale = 0.25, ap = display.LEFT_CENTER}))
end


function MultiBuyMediator:updateGoodsGridView_()
    local goodsGridView = self:getViewData().goodsGridView
    goodsGridView:setCountOfCell(#self:getStoreGoodsData())
    goodsGridView:reloadData()
end


function MultiBuyMediator:updateGoodsCell_(index, cellViewData)
    local goodsGridView = self:getViewData().goodsGridView
    local cellViewData  = cellViewData or self.goodsCellDict_[goodsGridView:cellAtIndex(index - 1)]
    local goodsData     = self:getStoreGoodsData()[index]

    if cellViewData and goodsData then
        
        local nameLabelMaxW = cellViewData.view:getContentSize().width
        local allGoodsNum   = goodsData.goodsNum * math.max(checkint(goodsData.leftPurchasedNum), 1)
        cellViewData.iconNode:RefreshSelf({goodsId = goodsData.goodsId, amount = allGoodsNum, showName = true, nameMaxW = nameLabelMaxW})
        
        local hasBuyProduct = self:hasBuyProduct(goodsData.productId)
        cellViewData.buyCBox:setChecked(hasBuyProduct)
    end
end


-------------------------------------------------
-- handler

function MultiBuyMediator:onGoodsGridDataAdapterHandler_(cell, idx)
    local pCell = cell
    local index = idx + 1

    -- create cell
    if pCell == nil then
        local goodsGridView = self:getViewData().goodsGridView
        local goodsCellSize = goodsGridView:getSizeOfCell()
        local cellViewData  = CreateGoodsCell(goodsCellSize)

        display.commonUIParams(cellViewData.hotspot, {cb = handler(self, self.onClickGoodsCellHandler_)})

        pCell = cellViewData.view
        self.goodsCellDict_[pCell] = cellViewData
    end

    -- init cell
    local cellViewData = self.goodsCellDict_[pCell]
    if cellViewData then
        cellViewData.view:setTag(index)
        cellViewData.hotspot:setTag(index)
    end

    -- update cell
    self:updateGoodsCell_(index, cellViewData)

    return pCell
end


function MultiBuyMediator:onClickGoodsCellHandler_(sender)
    PlayAudioByClickNormal()

    local cellIndex = sender:getTag()
    local goodsData = self:getStoreGoodsData()[cellIndex]
    local productId = checkint(goodsData.productId)
    
    if self:hasBuyProduct(productId) then
        self:removeBuyProduct(productId)
    else
        self:addBuyProduct(productId)
    end
end


function MultiBuyMediator:onBuyAllButtonHandler_(sender)
    PlayAudioByClickNormal()

    local currencyId     = self.currencyId_
    local currencyConf   = CommonUtils.GetConfig('goods', 'goods', currencyId) or {}
    local currencyName   = currencyConf.name ~= nil and currencyConf.name or tostring(currencyId)
    local useCurrencyNum = self.totalPrice_
    local hasCurrencyNum = app.gameMgr:GetAmountByIdForce(currencyId)
    
    -- check enough
    if hasCurrencyNum >= useCurrencyNum then
        if self.buyAllPostCmd_ then
            local buyProductList = table.keys(self.buyProductMap_)
            app:DispatchSignal(self.buyAllPostCmd_.cmdName, {
                products = table.concat(buyProductList, ',')
            })
        end
    else
        app.uiMgr:ShowInformationTips(string.fmt(__('_des_不足'), {_des_ = currencyName}))
    end
end


return MultiBuyMediator

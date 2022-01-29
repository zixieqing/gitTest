--[[
 * author : kaishiqi
 * descpt : 新游戏商店 - 道具商店 - 商品节点
]]
local GamePropsStoreGoodsNode = class('GamePropsStoreGoodsNode', function()
    return display.newLayer(0, 0, {name = 'GamePropsStoreGoodsNode'})
end)

GamePropsStoreGoodsNode.NODE_SIZE = cc.size(358, 188)

local RES_DICT = {
    GOODS_FRAME       = _res('ui/stores/props/shop_btn_props_default.png'),
    GOODS_TIME_BAR    = _res('ui/stores/base/shop_gifts_label_time.png'),
    GOODS_TIME_ICON   = _res('ui/stores/base/shop_ico_time_dark.png'),
    GOODS_SEARCH_ICON = _res('ui/common/raid_boss_btn_search.png'),
}

local SOLD_OUT_COLOR = cc.c3b(150,150,150)
local NORMAL_COLOR   = cc.c3b(255,255,255)

local CreateView = nil


-------------------------------------------------
-- life cycle

function GamePropsStoreGoodsNode:ctor()
    self.isControllable_ = true
    self:setContentSize(GamePropsStoreGoodsNode.NODE_SIZE)

    -- create view
    self.viewData_ = CreateView(self:getContentSize())
    self:addChild(self.viewData_.view)

    -- add listen
    display.commonUIParams(self:getViewData().clickHotspot, {cb = handler(self, self.onClickGoodsNodeHandler_)})
    display.commonUIParams(self:getViewData().iconHotspot, {cb = handler(self, self.onClickGoodsDescrHandler_)})
end


CreateView = function(size)
    local view = display.newLayer(0, 0, {size = size})

    view:addChild(display.newImageView(RES_DICT.GOODS_FRAME, size.width/2, size.height/2 , {scale9 = true , size = cc.size(size.width -10 , size.height  )}) )

    -- name label
    local nameLabel = display.newLabel(size.width/2 + 65, size.height/2 + 25, fontWithColor(1, {fontSize = 22, color = '#660606', w = 185, hAlign = display.TAC}))
    view:addChild(nameLabel)

    -- count label
    local countLabel = display.newLabel(nameLabel:getPositionX(), nameLabel:getPositionY() - 45, fontWithColor(8, {color = '#79511f', w = 185, hAlign = display.TAC}))
    view:addChild(countLabel)

    -- price label
    local priceLabel = display.newLabel(nameLabel:getPositionX() + 20, 35, fontWithColor(19, {outline = '#5a3c27', ap = display.RIGHT_CENTER}))
    view:addChild(priceLabel)

    -- price icon
    local priceIcon = display.newLayer(priceLabel:getPositionX() + 25, priceLabel:getPositionY())
    view:addChild(priceIcon)
    priceIcon:setScale(0.24)

    -- icon node
    local iconNode = require('common.GoodNode').new({showAmount = true})
    iconNode:setPosition(80, size.height/2 - 2)
    view:addChild(iconNode)


    -------------------------------------------------
    -- time layer
    local timeLayer = display.newLayer()
    view:addChild(timeLayer)

    local timeFrame = display.newImageView(RES_DICT.GOODS_TIME_BAR, 5, size.height - 25, {ap = display.LEFT_CENTER})
    timeLayer:addChild(timeFrame)

    local timeIcon = display.newImageView(RES_DICT.GOODS_TIME_ICON, 30, size.height - 26)
    timeLayer:addChild(timeIcon)
    
    local timeLable = display.newLabel(timeIcon:getPositionX() + 30, timeIcon:getPositionY(), fontWithColor(8, {color = '#b92c2c', ap = display.LEFT_CENTER}))
    timeLayer:addChild(timeLable)
    

    -------------------------------------------------
    -- sell layer
    local sellLayer = display.newLayer(size.width - 5, size.height - 25)
    view:addChild(sellLayer)

    -- click hostpot
    local clickHotspot = display.newLayer(0, 0, {size = size, color = cc.r4b(0), enable = true})
    view:addChild(clickHotspot)

    -- icon hostpot
    local iconHotspot = display.newLayer(0, 0, {size = cc.size(150, size.height), color = cc.r4b(0), enable = true})
    view:addChild(iconHotspot)

    -- search icon
    local searchIcon = display.newImageView(RES_DICT.GOODS_SEARCH_ICON, iconNode:getPositionX() + 45, iconNode:getPositionY() + 45)
    iconHotspot:addChild(searchIcon)

    return {
        view         = view,
        nameLabel    = nameLabel,
        countLabel   = countLabel,
        priceLabel   = priceLabel,
        priceIcon    = priceIcon,
        iconNode     = iconNode,
        timeLayer    = timeLayer,
        timeLable    = timeLable,
        sellLayer    = sellLayer,
        clickHotspot = clickHotspot,
        iconHotspot  = iconHotspot,
    }
end


-------------------------------------------------
-- get / set

function GamePropsStoreGoodsNode:getViewData()
    return self.viewData_
end


function GamePropsStoreGoodsNode:getDataTimestamp()
    return checkint(self.dataTimestamp_)
end
function GamePropsStoreGoodsNode:setDataTimestamp(timestamp)
    self.dataTimestamp_ = checkint(timestamp)
    self:updateDiscountCountdown()
    self:updateLimitCountdown()
end


function GamePropsStoreGoodsNode:getGoodsIndex()
    return checkint(self.goodsIndex_)
end
function GamePropsStoreGoodsNode:setGoodsIndex(index)
    self.goodsIndex_ = checkint(index)
end


function GamePropsStoreGoodsNode:getGoodsData()
    return self.goodsData_ or {}
end
function GamePropsStoreGoodsNode:setGoodsData(data)
    self.goodsData_ = data or {}
    self:resetGoodsNode_()
end


-- about buy type
function GamePropsStoreGoodsNode:isOnceBuyType()
    return checkint(self:getGoodsData().type) == 1
end
function GamePropsStoreGoodsNode:isMutlBuyType()
    return checkint(self:getGoodsData().type) == 2
end


-- about limit time
function GamePropsStoreGoodsNode:isLimitTime()
    return self:getGoodsData().shelfLeftSeconds and checkint(self:getGoodsData().shelfLeftSeconds) >= 0
end
function GamePropsStoreGoodsNode:getLimitLeftTime()
    local targetTime = self:getDataTimestamp() + checkint(self:getGoodsData().shelfLeftSeconds)
    return checkint(targetTime - os.time())
end


-- about discount time
function GamePropsStoreGoodsNode:isLimitDiscount()
    return self:getGoodsData().discountLeftSeconds and checkint(self:getGoodsData().discountLeftSeconds) >= 0
end
function GamePropsStoreGoodsNode:getDiscountLeftTime()
    local targetTime = self:getDataTimestamp() + checkint(self:getGoodsData().discountLeftSeconds)
    return checkint(targetTime - os.time())
end


function GamePropsStoreGoodsNode:getGoodsPrice()
    local priceNumber = checkint(self:getGoodsData().price)
    if self:isLimitDiscount() and self:getDiscountLeftTime() > 0 then
        if checkint(self:getGoodsData().discount) < 100 and checkint(self:getGoodsData().discount) > 0 then
            priceNumber = priceNumber * checkint(self:getGoodsData().discount) / 100
        end
    end
    return priceNumber
end


-- about stock
function GamePropsStoreGoodsNode:getTotalStock()
    return self:getGoodsData().lifeStock and checkint(self:getGoodsData().lifeStock) or -1
end
function GamePropsStoreGoodsNode:getTodayStock()
    return self:getGoodsData().stock and checkint(self:getGoodsData().stock) or -1
end


-- about purchased
function GamePropsStoreGoodsNode:getTotalPurchased()
    return self:getGoodsData().lifeLeftPurchasedNum and checkint(self:getGoodsData().lifeLeftPurchasedNum) or -1
end
function GamePropsStoreGoodsNode:getTodayPurchased()
    return self:getGoodsData().todayLeftPurchasedNum and checkint(self:getGoodsData().todayLeftPurchasedNum) or -1
end


-------------------------------------------------
-- public

function GamePropsStoreGoodsNode:resetNodeData(nodeData)
    self:setGoodsData(nodeData.propsGoodsData)
    self:setGoodsIndex(nodeData.propsGoodsIndex)
    self:setDataTimestamp(nodeData.dataTimestamp)
    self.buyGoodsCmdName_ = nodeData.buyGoodsCmdName
    self.buyGoodsCmdParams_ = nodeData.buyGoodsCmdParams
    self.onGoodsDescrCB_  = nodeData.onGoodsDescrCB
    self.dotGameCallBack = nodeData.dotGameCallBack
    self:getViewData().iconHotspot:setVisible(self.onGoodsDescrCB_ ~= nil)
end


function GamePropsStoreGoodsNode:updateLimitCountdown()
    self:getViewData().timeLayer:setVisible(self:isLimitTime())
    
    if self:isLimitTime() then
        local leftTimeNum  = self:getLimitLeftTime()
        local hasLeftTime  = leftTimeNum >= 0
        local leftTimeText = hasLeftTime and CommonUtils.getTimeFormatByType(leftTimeNum) or __('已结束')
        display.commonLabelParams(self:getViewData().timeLable, {text = leftTimeText})
    end
end


function GamePropsStoreGoodsNode:updateDiscountCountdown()
    local priceNumber = self:getGoodsPrice()
    display.commonLabelParams(self:getViewData().priceLabel, {text = tostring(priceNumber)})
end


function GamePropsStoreGoodsNode:updatePurchasedCount()
    local purchasedDescr = ''
    local purchasedCount = math.max(math.min(self:getTodayPurchased(), self:getTotalPurchased()), -1)
    if self:getTodayStock() == self:getTotalStock() then
        if purchasedCount ~= -1 then
            purchasedDescr = string.fmt(__('限购_num_次'), {_num_ = purchasedCount})
        end
    else
        if purchasedCount ~= -1 then
            purchasedDescr = string.fmt(__('今日可购_num_次'), {_num_ = purchasedCount})
        end
    end
    display.commonLabelParams(self:getViewData().countLabel, {text = purchasedDescr, reqW = 185})

    local isSoldOut = self:getTodayPurchased() == 0 or self:getTotalPurchased() == 0
    self:getViewData().view:setColor(isSoldOut and SOLD_OUT_COLOR or NORMAL_COLOR)
end


-------------------------------------------------
-- private

function GamePropsStoreGoodsNode:resetGoodsNode_()
    self:updateDiscountCountdown()
    self:updateLimitCountdown()
    self:updatePurchasedCount()

    -- update goods name
    local goodsId   = checkint(self:getGoodsData().goodsId)
    local goodsConf = CommonUtils.GetConfig('goods', 'goods', goodsId) or {}
    local goodsName = goodsConf.name ~= nil and goodsConf.name or tostring(goodsId)
    display.commonLabelParams(self:getViewData().nameLabel, {text = goodsName})
    
    -- update goods icon
    self:getViewData().iconNode:RefreshSelf({goodsId = goodsId, amount = self:getGoodsData().goodsNum})
    
    -- update currency icon
    local currencyId = checkint(self:getGoodsData().currency)
    self:getViewData().priceIcon:removeAllChildren()
    self:getViewData().priceIcon:addChild(display.newImageView(CommonUtils.GetGoodsIconPathById(currencyId)))
    
    -- update sell info
    local sellIconName  = self:getGoodsData().icon
    local sellIconTitle = tostring(self:getGoodsData().iconTitle)
    local sellIconPath  = _res(string.fmt('ui/stores/base/%1.png', tostring(sellIconName)))
    self:getViewData().sellLayer:setVisible(sellIconName ~= nil)
    self:getViewData().sellLayer:removeAllChildren()

    if sellIconName and app.fileUtils:isFileExist(sellIconPath) then
        local sellBar = display.newButton(0, 0, {n = sellIconPath, ap = display.RIGHT_CENTER, scale9 = true})
        display.commonLabelParams(sellBar, fontWithColor(20, {fontSize = 22, outline = '#8f2318', text = sellIconTitle, paddingW = 30, safeW = 60}))
        self:getViewData().sellLayer:addChild(sellBar)
    end
end


-------------------------------------------------
-- handler

function GamePropsStoreGoodsNode:onClickGoodsNodeHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    -- check limit time
    if self:isLimitTime() and self:getLimitLeftTime() <= 0 then
        app.uiMgr:ShowInformationTips(__('道具剩余时间已结束'))
        return
    end
    
    -- -- check limit stock
    -- if self:getTotalStock() == 0 or self:getTodayStock() == 0 then
    --     app.uiMgr:ShowInformationTips(__('库存不足'))
    --     return
    -- end
    
    -- check limit purchased
    if self:getTotalPurchased() == 0 or self:getTodayPurchased() == 0 then
        app.uiMgr:ShowInformationTips(__('已售罄'))
        return
    end

    local purchasePopupData    = clone(self:getGoodsData())
    purchasePopupData.goodsNum = self:isMutlBuyType() and 1 or checkint(purchasePopupData.goodsNum)
    if self:isLimitTime() then
        purchasePopupData.shelfLeftSeconds = self:getLimitLeftTime()
    end
    if self:isLimitDiscount() then
        purchasePopupData.discountLeftSeconds = self:getDiscountLeftTime()
    end

    -- show purchase dialog
    local storePurchasePopup = require('Game.views.ShopPurchasePopup').new({tag = GAME_STORE_PURCHASE_DIALOG_TAG, data = purchasePopupData, showChooseUi = self:isMutlBuyType()})
    display.commonUIParams(storePurchasePopup.viewData.purchaseBtn, {cb = handler(self, self.onClickPurchaseButtonHandler_)})
    display.commonUIParams(storePurchasePopup, {ap = display.CENTER, po = display.center})
    app.uiMgr:GetCurrentScene():AddDialog(storePurchasePopup)
    if self.dotGameCallBack then
        self.dotGameCallBack(self.goodsData_.goodsId)
    end
end


function GamePropsStoreGoodsNode:onClickPurchaseButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end
    
    -- check limit time
    if self:isLimitTime() and self:getLimitLeftTime() <= 0 then
        app.uiMgr:ShowInformationTips(__('出售时间已结束'))
        return
    end
    
    -- currency info
    local buyGoodsNum     = checkint(sender:getUserTag())
    local currencyId      = checkint(self:getGoodsData().currency)
    local currencyConf    = CommonUtils.GetConfig('goods', 'goods', currencyId) or {}
    local currencyName    = currencyConf.name ~= nil and currencyConf.name or tostring(currencyId)
    local useCurrencyNum  = self:getGoodsPrice() * buyGoodsNum
    local hasCurrencyNum  = app.gameMgr:GetAmountByIdForce(currencyId)
    local buyGoodsCmdName = self.buyGoodsCmdName_ or POST.GAME_STORE_BUY.cmdName
    local buyGoodsCmdParams = self.buyGoodsCmdParams_ or {}
    -- check enough
    if hasCurrencyNum >= useCurrencyNum then
        local params = {
            productId        = self:getGoodsData().productId,
            num              = buyGoodsNum,
            currencyId       = currencyId,
            consumeNum       = useCurrencyNum,
            goodsIndex       = self:getGoodsIndex(),
            useDiscountGoods = 0,
        }
        table.merge(params, buyGoodsCmdParams)
        app:DispatchSignal(buyGoodsCmdName, params)
    else
        -- if checkint(currencyId) == DIAMOND_ID then
        --     app.uiMgr:showDiamonTips()
        -- else
            app.uiMgr:ShowInformationTips(string.fmt(__('_des_不足'), {_des_ = currencyName}))
        -- end
    end
end


function GamePropsStoreGoodsNode:onClickGoodsDescrHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    if self.onGoodsDescrCB_ then
        self.onGoodsDescrCB_(self:getGoodsIndex(), self:getGoodsData())
    end
end


return GamePropsStoreGoodsNode

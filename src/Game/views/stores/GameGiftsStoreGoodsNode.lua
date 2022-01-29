--[[
 * author : kaishiqi
 * descpt : 新游戏商店 - 礼包商店 - 商品节点
]]
local GameGiftsStoreGoodsNode = class('GameGiftsStoreGoodsNode', function()
    return display.newLayer(0, 0, {name = 'GameGiftsStoreGoodsNode'})
end)

GameGiftsStoreGoodsNode.NODE_SIZE = cc.size(538, 198)

local RES_DICT = {
    GOODS_FRAME       = _res('ui/stores/gifts/shop_btn_gifts_default.png'),
    GOODS_TIME_BAR    = _res('ui/stores/base/shop_gifts_label_time.png'),
    GOODS_TIME_ICON   = _res('ui/stores/base/shop_ico_time_dark.png'),
    GOODS_SEARCH_ICON = _res('ui/common/raid_boss_btn_search.png'),
    GOODS_DESCR_FRAME = _res('ui/stores/gifts/shop_gifts_label_descr.png'),
    PRICE_FRAME       = _res('ui/stores/gifts/shop_gifts_label_price_default.png'),
    SOLDOUT_FRAME     = _res('ui/stores/gifts/shop_gifts_label_price_soldout.png'),
}

local CreateView = nil


-------------------------------------------------
-- life cycle

function GameGiftsStoreGoodsNode:ctor( ... )
    local args = unpack({...}) or {}
    self.name = args.name
    self.isControllable_ = true
    self:setContentSize(GameGiftsStoreGoodsNode.NODE_SIZE)

    -- create view
    self.viewData_ = CreateView(self:getContentSize())
    self:addChild(self.viewData_.view)

    -- add listen
    display.commonUIParams(self:getViewData().clickHotspot, {cb = handler(self, self.onClickGoodsNodeHandler_)})
    display.commonUIParams(self:getViewData().payHotspot, {cb = handler(self, self.onClickPurchaseButtonHandler_)})
end


CreateView = function(size)
    local view = display.newLayer(0, 0, {size = size})

    view:addChild(display.newImageView(RES_DICT.GOODS_FRAME, size.width/2, size.height/2))

    -- search icon
    local searchIcon = display.newImageView(RES_DICT.GOODS_SEARCH_ICON, 30, size.height - 33, {scale = 0.8})
    view:addChild(searchIcon)

    -- name label
    local nameLabel = display.newLabel(searchIcon:getPositionX() + 25, searchIcon:getPositionY(), fontWithColor(20, {fontSize = 24, outline = '#83460d', ap = display.LEFT_CENTER}))
    view:addChild(nameLabel)

    -- descr bar
    local descrBar = display.newButton(size.width/2 + 95, size.height/2 + 18, {n = RES_DICT.GOODS_DESCR_FRAME, enable = false})
    display.commonLabelParams(descrBar, fontWithColor(20, {fontSize = 18, color = '#ffdb87', outline = '#924c00', w = 300, hAlign = display.TAC}))
    view:addChild(descrBar)

    -- icon node
    local iconLayer = display.newLayer(100, size.height/2 - 5)
    iconLayer:setScale(0.7)
    view:addChild(iconLayer)
    

    -------------------------------------------------
    -- purchase info
    local purchaseLayer = display.newLayer(size.width, 5, {bg = RES_DICT.PRICE_FRAME, ap = display.RIGHT_BOTTOM})
    local purchaseSize  = purchaseLayer:getContentSize()
    view:addChild(purchaseLayer)
    
    -- price label
    local priceLabel = display.newLabel(purchaseSize.width/2 - 20, purchaseSize.height/2, fontWithColor(20, {fontSize = 28, outline = '#8f2318'}))
    purchaseLayer:addChild(priceLabel)

    -- price2 label
    local price2Label = display.newLabel(priceLabel:getPositionX(), purchaseSize.height/2 + 12, fontWithColor(20, {fontSize = 28, outline = '#8f2318'}))
    purchaseLayer:addChild(price2Label)
    
    -- count label
    local countLabel = display.newLabel(priceLabel:getPositionX(), price2Label:getPositionY() - 26, fontWithColor(8, {fontSize = 18, color = '#631614'}))
    purchaseLayer:addChild(countLabel)


    -------------------------------------------------
    -- soldout info
    local soldoutLayer = display.newLayer(purchaseLayer:getPositionX(), purchaseLayer:getPositionY(), {bg = RES_DICT.SOLDOUT_FRAME, ap = display.RIGHT_BOTTOM})
    local soldoutSize  = soldoutLayer:getContentSize()
    view:addChild(soldoutLayer)

    -- soldout label
    local soldoutLabel = display.newLabel(soldoutSize.width/2 - 20, soldoutSize.height/2, fontWithColor(7))
    soldoutLayer:addChild(soldoutLabel)


    -------------------------------------------------
    -- time layer
    local timeLayer = display.newLayer()
    view:addChild(timeLayer)

    local timeFrame = display.newImageView(RES_DICT.GOODS_TIME_BAR, 12, 30, {ap = display.LEFT_CENTER})
    timeLayer:addChild(timeFrame)

    local timeIcon = display.newImageView(RES_DICT.GOODS_TIME_ICON, timeFrame:getPositionX() + 30, timeFrame:getPositionY())
    timeLayer:addChild(timeIcon)
    
    local timeLable = display.newLabel(timeIcon:getPositionX() + 30, timeIcon:getPositionY(), fontWithColor(8, {color = '#b92c2c', ap = display.LEFT_CENTER}))
    timeLayer:addChild(timeLable)
    

    -------------------------------------------------
    -- sell layer
    local sellLayer = display.newLayer(size.width - 5, size.height - 33)
    view:addChild(sellLayer)

    -- click hostpot
    local clickHotspot = display.newLayer(0, 0, {size = size, color = cc.r4b(0), enable = true})
    view:addChild(clickHotspot)

    -- pay hostpot
    local paySize = cc.size(size.width - 200, size.height)
    local payHotspot = display.newLayer(200, 0, {size = paySize, color = cc.r4b(0), enable = true})
    view:addChild(payHotspot)

    return {
        view          = view,
        nameLabel     = nameLabel,
        purchaseLayer = purchaseLayer,
        countLabel    = countLabel,
        priceLabel    = priceLabel,
        price2Label   = price2Label,
        soldoutLayer  = soldoutLayer,
        soldoutLabel  = soldoutLabel,
        iconLayer     = iconLayer,
        descrBar      = descrBar,
        timeLayer     = timeLayer,
        timeLable     = timeLable,
        sellLayer     = sellLayer,
        clickHotspot  = clickHotspot,
        payHotspot    = payHotspot,
    }
end


-------------------------------------------------
-- get / set

function GameGiftsStoreGoodsNode:getViewData()
    return self.viewData_
end


function GameGiftsStoreGoodsNode:getDataTimestamp()
    return checkint(self.dataTimestamp_)
end
function GameGiftsStoreGoodsNode:setDataTimestamp(timestamp)
    self.dataTimestamp_ = checkint(timestamp)
    self:updateLimitCountdown()
end


function GameGiftsStoreGoodsNode:getGoodsIndex()
    return checkint(self.goodsIndex_)
end
function GameGiftsStoreGoodsNode:setGoodsIndex(index)
    self.goodsIndex_ = checkint(index)
end


function GameGiftsStoreGoodsNode:getGoodsData()
    return self.goodsData_ or {}
end
function GameGiftsStoreGoodsNode:setGoodsData(data)
    self.goodsData_ = data or {}
    self:resetGoodsNode_()
end


-- about limit time
function GameGiftsStoreGoodsNode:isLimitTime()
    return self:getGoodsData().shelfLeftSeconds and checkint(self:getGoodsData().shelfLeftSeconds) >= 0
end
function GameGiftsStoreGoodsNode:getLimitLeftTime()
    local targetTime = self:getDataTimestamp() + checkint(self:getGoodsData().shelfLeftSeconds)
    return checkint(targetTime - os.time())
end


function GameGiftsStoreGoodsNode:getGoodsPrice()
    local cuurentPrice = tostring(self:getGoodsData().price)
    if CommonUtils.IsNeedExtraGetRealPriceData() then
        cuurentPrice = CommonUtils.GetCurrentAndOriginPriceDByPriceData(self:getGoodsData())
    elseif tonumber(cuurentPrice)  and  tonumber(cuurentPrice) > 0  then
        cuurentPrice =  string.fmt(__('￥_num1_'), {_num1_ = cuurentPrice})
    else
        cuurentPrice =  string.fmt(__('￥_num1_'), {_num1_ = "---"})
    end
    return cuurentPrice
end


-- about stock
function GameGiftsStoreGoodsNode:getTotalStock()
    return checkint(self:getGoodsData().lifeStock)
end
function GameGiftsStoreGoodsNode:getTodayStock()
    return checkint(self:getGoodsData().stock)
end


-- about purchased
function GameGiftsStoreGoodsNode:getTotalPurchased()
    return checkint(self:getGoodsData().lifeLeftPurchasedNum)
end
function GameGiftsStoreGoodsNode:getTodayPurchased()
    return checkint(self:getGoodsData().todayLeftPurchasedNum)
end


-------------------------------------------------
-- public

function GameGiftsStoreGoodsNode:resetNodeData(nodeData)
    self:setGoodsData(nodeData.giftsGoodsData)
    self:setGoodsIndex(nodeData.giftsGoodsIndex)
    self:setDataTimestamp(nodeData.dataTimestamp)
    self.dotGameCallBack = nodeData.dotGameCallBack
end


function GameGiftsStoreGoodsNode:updateLimitCountdown()
    self:getViewData().timeLayer:setVisible(self:isLimitTime())
    
    if self:isLimitTime() then
        local leftTimeNum  = self:getLimitLeftTime()
        local hasLeftTime  = leftTimeNum >= 0
        local leftTimeText = hasLeftTime and CommonUtils.getTimeFormatByType(leftTimeNum) or __('已结束')
        display.commonLabelParams(self:getViewData().timeLable, {text = leftTimeText})
    end
end


function GameGiftsStoreGoodsNode:updatePurchasedCount()
    -- update Purchased info
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
    local isLimitPurchased = string.len(purchasedDescr) > 0 
    self:getViewData().price2Label:setVisible(isLimitPurchased)
    self:getViewData().priceLabel:setVisible(not isLimitPurchased)
    display.commonLabelParams(self:getViewData().countLabel, {text = purchasedDescr})
    
    -- update soldout status
    local isSoldOut = self:getTodayPurchased() == 0 or self:getTotalPurchased() == 0
    self:getViewData().purchaseLayer:setVisible(not isSoldOut)
    self:getViewData().soldoutLayer:setVisible(isSoldOut)
    if isSoldOut then
        if self:getTodayStock() == self:getTotalStock() then
            display.commonLabelParams(self:getViewData().soldoutLabel, {text = __('已售罄')})
        else
            display.commonLabelParams(self:getViewData().soldoutLabel, {text = __('今日售罄')})
        end
    end
end


function GameGiftsStoreGoodsNode:updateGoodsPrice()
    local priceString = self:getGoodsPrice()
    display.commonLabelParams(self:getViewData().priceLabel, {text = priceString})
    display.commonLabelParams(self:getViewData().price2Label, {text = priceString})
end


-------------------------------------------------
-- private

function GameGiftsStoreGoodsNode:resetGoodsNode_()
    self:updateLimitCountdown()
    self:updatePurchasedCount()
    self:updateGoodsPrice()

    -- update goods name
    self:getViewData().nameLabel:setScale(self:getViewData().nameLabel.originalScale or 1)
    local goodsName = tostring(self:getGoodsData().name)
    display.commonLabelParams(self:getViewData().nameLabel, {reqW = 310 ,  text = goodsName})
    
    -- update goods icon
    local iconPath =_res(CommonUtils.GetGoodsIconPathById(self:getGoodsData().photo))
    self:getViewData().iconLayer:removeAllChildren()
    self:getViewData().iconLayer:addChild(display.newImageView(iconPath))
    
    -- update goods descr
    local goodsDescr = checkstr(self:getGoodsData().descr)
    self:getViewData().descrBar:setVisible(string.len(goodsDescr) > 0)
    display.commonLabelParams(self:getViewData().descrBar, {text = goodsDescr})
    
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

function GameGiftsStoreGoodsNode:onClickGoodsNodeHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local purchasePopupData    = clone(self:getGoodsData())
    purchasePopupData.callback = handler(self, self.onClickPurchaseButtonHandler_)

    -- show purchase dialog
    local showRewardsPopup = require('Game.views.ShowRewardsLayer').new(purchasePopupData)
    display.commonUIParams(showRewardsPopup, {ap = display.CENTER, po = display.center})
    app.uiMgr:GetCurrentScene():AddDialog(showRewardsPopup)
end


function GameGiftsStoreGoodsNode:onClickPurchaseButtonHandler_(sender)
    PlayAudioByClickNormal()
    if self.dotGameCallBack then
        self.dotGameCallBack(checkint(self:getGoodsData().productId))
    end
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

    if isJapanSdk() then
        local gameMgr = app.gameMgr
        local uiMgr = app.uiMgr
        local curData = self:getGoodsData()
        if 0 == checkint(gameMgr:GetUserInfo().jpAge) then
            local JapanAgeConfirmMediator = require( 'Game.mediator.JapanAgeConfirmMediator' )
            local mediator = JapanAgeConfirmMediator.new({cb = function (  )
                app:DispatchSignal(COMMANDS.COMMANDS_All_Shop_GetPayOrder, {
                    productId  = self:getGoodsData().productId,
                    goodsIndex = self:getGoodsIndex(),
                    name       = self.name
                })
            end})
            app:RegistMediator(mediator)
        else
            if tonumber(curData.price) < checkint(gameMgr:GetUserInfo().jpAgePaymentLimitLeft) or -1 == checkint(gameMgr:GetUserInfo().jpAgePaymentLimitLeft) then
                app:DispatchSignal(COMMANDS.COMMANDS_All_Shop_GetPayOrder, {
                    productId  = self:getGoodsData().productId,
                    goodsIndex = self:getGoodsIndex(),
                    name       = self.name
                })
            else
                uiMgr:ShowInformationTips(__('本月购买幻晶石数量已达上限'))
            end
        end
    else
        app:DispatchSignal(COMMANDS.COMMANDS_All_Shop_GetPayOrder, {
            productId  = self:getGoodsData().productId,
            goodsIndex = self:getGoodsIndex(),
            name       = self.name
        })
    end
end


return GameGiftsStoreGoodsNode

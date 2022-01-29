--[[
 * descpt : 新游戏商店 - 月卡商店  - 活动视图
]]
---@class MonthCardStoreActivityCell
local MonthCardStoreActivityCell = class('MonthCardStoreActivityCell', function()
    return display.newLayer(0, 0, {name = 'MonthCardStoreActivityCell'})
end)
local newImageView                 = display.newImageView
local newLabel                     = display.newLabel
local newLayer                     = display.newLayer
local RES_DICT                     = {
    SHOP_FRAME_AD_UP              = _res('ui/stores/base/shop_frame_ad_up.png'),
    TEMP_AD_CARD                  = _res("ui/stores/month/temp_ad_card.jpg"),
    SHOP_ICO_TIME                 = _res("ui/stores/base/shop_ico_time.png"),
    SHOP_DIAMOND_BG_TIMELEFT      = _res("ui/stores/base/shop_diamond_bg_timeleft.png"),
    SHOP_CARD_BTN_PRICE_SP        = _res("ui/stores/month/shop_card_btn_price_sp.png"),
    SALE_LINE_DISABELD            = _res('ui/common/line_delete_2.png')
}

local VIEW_SIZE = cc.size(1080, 144)

local CreateView = nil

function MonthCardStoreActivityCell:ctor(...)
    local args = unpack({...}) or {}
    self.isControllable_ = true

    self:setContentSize(args.size or VIEW_SIZE)

    self.viewData_ = CreateView(self:getContentSize())
    self:addChild(self.viewData_.actView)

    self:initView()
end

function MonthCardStoreActivityCell:initView()
    display.commonUIParams(self:getViewData().actPurchaseTouchView, {cb = handler(self, self.onClickPurchaseAction)})
end

function MonthCardStoreActivityCell:updateCell(data, dataTimestamp)
    self.data_ = data
    self.dataTimestamp_ = dataTimestamp
    local viewData = self:getViewData()

    --local activity = app.activityMgr:GetActivityDataByType(ACTIVITY_TYPE.STORE_MEMBER_PACK)
    --if activity and activity[1] and activity[1].image[i18n.getLang()]  then
    --    self:getViewData().adImg:setWebURL(activity[1].image[i18n.getLang()])
    --end


    local memberData = self:getData().memberData or {}
    --dump(memberData)
    local productData = app.gameMgr:GetProductDataByProductId(memberData.productId) or {}
    local  activity = productData.activity or {}
    if type(activity.image) == "string" then
        local image = json.decode(activity.image)
        self:getViewData().adImg:setWebURL(image[i18n.getLang()])
    end
    if activity.image and activity.image[i18n.getLang()] and  string.len(activity.image[i18n.getLang()] ) > 0   then
        print("activity.image[i18n.getLang()] " , activity.image[i18n.getLang()])
        self:getViewData().adImg:setWebURL( activity.image[i18n.getLang()])
    end
    self:updatePrice()
    local realLeftSeconds = self.dataTimestamp_ + checkint(memberData.purchaseLeftSeconds) - os.time()
    local leftSeconds = math.max(realLeftSeconds, 0)
    self:updateTimeLabel(leftSeconds)
end

function MonthCardStoreActivityCell:updateTimeLabel(leftSeconds)
    display.commonLabelParams(self:getViewData().timeLabel, {text = CommonUtils.getTimeFormatByType(leftSeconds)})
end

function MonthCardStoreActivityCell:updatePrice()
    local memberData = self:getData().memberData or {}
    local viewData = self:getViewData()
    local totalNum = checkint(memberData.lifeLeftPurchasedNum)
    local todayNum = checkint(memberData.todayLeftPurchasedNum)
    local canPurchase = false
    if checkint(memberData.lifeStock) == -1 or checkint(memberData.stock) > 0 then

        if memberData.todayLeftPurchasedNum then  -- 存在剩余购买次数
            canPurchase = true
            if todayNum >= totalNum then
                --限购次数显示
                if totalNum == 0 then
                    canPurchase = false
                end
            else
                if todayNum <= 0 then
                    canPurchase = false
                end
            end
        end
    else -- 不存在剩余购买次数
        canPurchase = false
    end

    viewData.originalPrice:setVisible(canPurchase)
    viewData.presentPrice:setVisible(canPurchase)
    viewData.lineDeleteImage:setVisible(canPurchase)
    viewData.purchaseStateLabel:setVisible(not canPurchase)

    if canPurchase then
        local cuurentPrice, originalPrice
        
        if isElexSdk() then
            cuurentPrice ,originalPrice = CommonUtils.GetCurrentAndOriginPriceDByPriceData(memberData)
        else
            cuurentPrice = string.format(__("￥ %s" ) , tostring(tonumber(memberData.price)))
            originalPrice = string.format(__("￥ %s" ) , tostring(tonumber(memberData.originalPrice)))
        end
    
        display.commonLabelParams(viewData.originalPrice, {text = originalPrice})
        display.commonLabelParams(viewData.presentPrice, {text = cuurentPrice})
        viewData.lineDeleteImage:setVisible(true)
    end

end

function MonthCardStoreActivityCell:onClickPurchaseAction()
    local memberData = self:getData().memberData or {}
    local totalNum = checkint(memberData.lifeLeftPurchasedNum)
    local todayNum = checkint(memberData.todayLeftPurchasedNum)
    if checkint(memberData.lifeStock) == -1 or checkint(memberData.stock) > 0 then
        if memberData.todayLeftPurchasedNum then  -- 存在剩余购买次数
            local canNext = 1
            if todayNum >= totalNum then
                --限购次数显示
                if totalNum == 0 then
                    app.uiMgr:ShowInformationTips(__('已售罄'))
                    canNext = 0
                end
            else
                if todayNum <= 0 then
                    app.uiMgr:ShowInformationTips(__('已售罄'))
                    canNext = 0
                end
            end
            if canNext == 0 then return end
        end
    else -- 不存在剩余购买次数
        app.uiMgr:ShowInformationTips(__('库存不足'))
        return
    end
    app:DispatchSignal(COMMANDS.COMMANDS_All_Shop_GetPayOrder, {
        productId = memberData.productId, 
        name = 'MonthCardStoreMediator', 
        price_ = memberData.price, 
        channelProductId_ = memberData.channelProductId
    })
end

CreateView = function (size)
    ------------------actView start-------------------
    local actViewSize = cc.size(size.width, 144)
    local actView = display.newLayer(actViewSize.width / 2, actViewSize.height / 2,
    {
        ap = display.CENTER,
        size = actViewSize,
    })

    local adFrameImg = display.newNSprite(RES_DICT.SHOP_FRAME_AD_UP, actViewSize.width / 2, actViewSize.height / 2, {ap = display.CENTER})
    actView:addChild(adFrameImg)

    local adImg = lrequire('root.WebSprite').new({url = '', hpath = '', tsize = cc.size(1062, 130), fill = true})
    adImg:setAnchorPoint(display.CENTER)
    adImg:setPosition(cc.p(actViewSize.width/2, actViewSize.height/2))
    actView:addChild(adImg)
    -- adImg:setVisible(false)
    -------------------timeBg start-------------------

    local timeBg = display.newNSprite(RES_DICT.SHOP_DIAMOND_BG_TIMELEFT, 2, actViewSize.height - 10, {ap = display.LEFT_TOP})
    actView:addChild(timeBg)

    local timeIcon = display.newNSprite(RES_DICT.SHOP_ICO_TIME, 15, 16, {ap = display.LEFT_CENTER})
    timeBg:addChild(timeIcon)

    local timeLabel = display.newLabel(59, 16,
    {
        ap = display.LEFT_CENTER,
        fontSize = 20,
        color = '#ffb143',
    })
    timeBg:addChild(timeLabel)

    --------------------timeBg end--------------------

    local priceBg = display.newNSprite(RES_DICT.SHOP_CARD_BTN_PRICE_SP, actViewSize.width - 2, actViewSize.height / 2, {ap = display.RIGHT_CENTER})
    actView:addChild(priceBg)

    local originalPrice = newLabel(120, 56,
                                   fontWithColor(14, { ap = display.CENTER, color = '#c9c9c9', fontSize = 20}))
    priceBg:addChild(originalPrice)
    originalPrice:setVisible(false)

    local lineDeleteImage = display.newImageView(RES_DICT.SALE_LINE_DISABELD, originalPrice:getPositionX(), originalPrice:getPositionY())
    priceBg:addChild(lineDeleteImage)
    -- lineDeleteImage:setScaleX(0.7)
    lineDeleteImage:setVisible(false)

    local presentPrice = newLabel(originalPrice:getPositionX(), 33,
                                  fontWithColor(14, { ap = display.CENTER, color = '#ffffff', fontSize = 24}))
    priceBg:addChild(presentPrice)
    presentPrice:setVisible(false)

    local purchaseStateLabel = display.newLabel(originalPrice:getPositionX(), 45, fontWithColor(18, {ap = display.CENTER, text = __('已售罄')}))
    priceBg:addChild(purchaseStateLabel)

    local actPurchaseTouchView = display.newLayer(actViewSize.width / 2, actViewSize.height / 2, {ap = display.CENTER, size = actViewSize, color = cc.c4b(0,0,0,0), enable = true})
    actView:addChild(actPurchaseTouchView)


    -------------------actView end--------------------
    
    return {
        actView              = actView,
        adImg                = adImg,
        timeIcon             = timeIcon,
        timeLabel            = timeLabel,
        originalPrice        = originalPrice,
        lineDeleteImage      = lineDeleteImage,
        presentPrice         = presentPrice,
        purchaseStateLabel   = purchaseStateLabel,        
        actPurchaseTouchView = actPurchaseTouchView,
    }
end


function MonthCardStoreActivityCell:getViewData()
    return self.viewData_
end

function MonthCardStoreActivityCell:getData()
    return self.data_ or {}
end

return MonthCardStoreActivityCell

--[[
 * author : liuzhipeng
 * descpt : 活动 新手福利 giftNode
--]]
local NoviceWelfareGiftNode = class('NoviceWelfareGiftNode', function()
    local node = CLayout:create()
    node:enableNodeEvents()
    node:setAnchorPoint(cc.p(0.5, 0.5))
    node.name = 'NoviceWelfareGiftNode'
    return node
end)
local NODE_SIZE = cc.size(224, 261)
local RES_DICT = {
    NODE_BG_N             = _res('ui/home/activity/noviceWelfare/gift_bag_bg_grey.png'),
    NODE_BG_L             = _res('ui/home/activity/noviceWelfare/gift_bag_bg_light.png'),
    DAY_BG                = _res('ui/home/activity/noviceWelfare/gifts_label_time.png'),
    TIME_BG               = _res('ui/home/activity/noviceWelfare/gifts_time_bg.png'),
    GIFT_ICON             = _res('ui/home/activity/noviceWelfare/gifts_icon_1_1.png'),
    CLOCK_ICON            = _res('ui/common/new_welfare_ico_making_2.png'),
    CLOCK_ICON_W          = _res('ui/home/activity/noviceWelfare/days_ico_time.png'),
    GRAY_MASK             = _res('ui/home/activity/noviceWelfare/gifts_lock_bg_grey.png'),
    LIMIT_BG              = _res('ui/home/activity/noviceWelfare/guild_shop_lock_wrod.png'),
    LOCK_ICON             = _res('ui/common/common_ico_lock.png'),
    PRICE_BG_GRAY         = _res('ui/home/activity/noviceWelfare/gifts_label_price_gray.png'),
    PRICE_BG_ORANGE       = _res('ui/home/activity/noviceWelfare/gifts_label_price_orange.png'),
    PRICE_BG_VIOLET       = _res('ui/home/activity/noviceWelfare/gifts_label_price_violet.png'),
    PRICE_LINE            = _res('ui/home/activity/noviceWelfare/gift_bag_line.png')
    
}
function NoviceWelfareGiftNode:ctor(...)
    local args = unpack({...})
    self.callback = nil 
    self:InitUI()
end
--[[
初始化UI
--]]
function NoviceWelfareGiftNode:InitUI()
    local CreateView = function (size)
        local view = CLayout:create(NODE_SIZE)
        -- 背
        local bgBtn = display.newButton(size.width / 2, size.height / 2, {n = RES_DICT.NODE_BG_N, useS = false})
        view:addChild(bgBtn, 1)
        local grayMask = display.newImageView(RES_DICT.GRAY_MASK, size.width / 2, size.height / 2 + 1, {n = RES_DICT.GRAY_MASK})
        view:addChild(grayMask, 5)
        -- 天数
        local dayBg = display.newImageView(RES_DICT.DAY_BG, 0, size.height - 20, {ap = display.LEFT_CENTER})
        view:addChild(dayBg, 3)
        local dayLabel = display.newLabel(10, dayBg:getContentSize().height / 2, {text = '', fontSize = 20, color = '#b92c2c', ttf = true, font = TTF_GAME_FONT, ap = display.LEFT_CENTER})
        dayBg:addChild(dayLabel, 1)
        -- 时间
        local timeBg = display.newImageView(RES_DICT.TIME_BG, 0, size.height - 20, {ap = display.LEFT_CENTER})
        view:addChild(timeBg, 3)
        local clockIcon = display.newImageView(RES_DICT.CLOCK_ICON, 25, timeBg:getContentSize().height / 2)
        timeBg:addChild(clockIcon, 1)
        local timeLabel = display.newLabel(100, timeBg:getContentSize().height / 2, {text = '', fontSize = 20, color = '#b92c2c', ttf = true, font = TTF_GAME_FONT})
        timeBg:addChild(timeLabel, 1)
        -- 礼包icon
        local giftIcon = display.newImageView(RES_DICT.GIFT_ICON, size.width / 2, size.height - 5, {ap = display.CENTER_TOP})
        view:addChild(giftIcon, 1)
        -- 锁定状态
        local limitBg = display.newImageView(RES_DICT.LIMIT_BG, size.width / 2, size.height / 2)
        view:addChild(limitBg, 5)
        local lockIcon = display.newImageView(RES_DICT.LOCK_ICON, limitBg:getContentSize().width / 2, limitBg:getContentSize().height / 2)
        limitBg:addChild(lockIcon, 1)
        local lockClockIcon = display.newImageView(RES_DICT.CLOCK_ICON_W, 50, limitBg:getContentSize().height / 2)
        limitBg:addChild(lockClockIcon, 1)
        local lockTimeLabel = display.newLabel(120, limitBg:getContentSize().height / 2, {text = '', fontSize = 20, color = '#ffffff', ttf = true, font = TTF_GAME_FONT})
        limitBg:addChild(lockTimeLabel, 1)
        -- 价格
        local priceBg = display.newImageView(RES_DICT.PRICE_BG_GRAY, size.width / 2, 45)
        view:addChild(priceBg, 3)
        local priceLabel = display.newLabel(priceBg:getContentSize().width / 2, priceBg:getContentSize().height / 2 + 5, {text = '', fontSize = 26, color = '#ffffff', ttf = true, font = TTF_GAME_FONT, outline = '#752d11', outlineSize = 2})
        priceBg:addChild(priceLabel, 1)
        local originalPriceLabel = display.newLabel(priceBg:getContentSize().width / 2, priceBg:getContentSize().height / 2 + 10, {text = '', fontSize = 18, color = '#702619'})
        priceBg:addChild(originalPriceLabel, 1)
        view:setVisible(false)
        return {
            view               = view,
            bgBtn              = bgBtn,
            grayMask           = grayMask,
            dayBg              = dayBg,
            dayLabel           = dayLabel,
            timeBg             = timeBg,
            timeLabel          = timeLabel,
            giftIcon           = giftIcon,
            limitBg            = limitBg,
            lockIcon           = lockIcon,
            lockClockIcon      = lockClockIcon,
            lockTimeLabel      = lockTimeLabel,
            priceBg            = priceBg,
            priceLabel         = priceLabel,
            originalPriceLabel = originalPriceLabel,
        }
    end
    xTry(function ( )
        self.viewData = CreateView(NODE_SIZE)
        self:setContentSize(NODE_SIZE)
        self.viewData.view:setPosition(utils.getLocalCenter(self))
        self:addChild(self.viewData.view)
        self.viewData.bgBtn:setOnClickScriptHandler(handler(self, self.ButtonCallback))
	end, __G__TRACKBACK__)
end  
--[[
初始化节点
@params index              int  礼包序号
@params giftData           map  礼包数据
@params today              int  当前天数
@params nextDayLeftSeconds int  距离下一天剩余秒数
@params callback           handler 点击回调
--]]
function NoviceWelfareGiftNode:RefreshNode( index, giftData, today, nextDayLeftSeconds, callback )
    local viewData = self:GetViewData()
    viewData.bgBtn:setTag(index)
    local dayLabelStr = nil
    if isChinaSdk() then
        dayLabelStr = string.fmt(__('第_num_天'), {['_num_'] = CommonUtils.GetChineseNumber(index)})
    else
        dayLabelStr = string.fmt(__('第_num_天'), {['_num_'] = index})
    end
    viewData.dayLabel:setString(dayLabelStr)
    viewData.grayMask:setVisible(index > today)
    viewData.limitBg:setVisible(index > today)
    viewData.priceBg:setVisible(index <= today)
    viewData.bgBtn:setEnabled(index <= today)
    viewData.originalPriceLabel:setVisible(false)
    viewData.priceLabel:setAnchorPoint(display.CENTER)
    viewData.priceLabel:setPositionX(viewData.priceBg:getContentSize().width / 2)
    if viewData.priceBg:getChildByName('line') then
        viewData.priceBg:getChildByName('line'):removeFromParent()
    end

    if today == index then
        viewData.bgBtn:setNormalImage(RES_DICT.NODE_BG_L)
        viewData.bgBtn:setSelectedImage(RES_DICT.NODE_BG_L)
        viewData.giftIcon:setTexture(string.format('ui/home/activity/noviceWelfare/gifts_icon_%d.png', giftData.photoId))
        if checkint(giftData.hasPurchased) == 1 then
            viewData.dayBg:setVisible(true)
            viewData.timeBg:setVisible(false)
            viewData.priceBg:setTexture(RES_DICT.PRICE_BG_GRAY)
            viewData.priceLabel:setPosition(cc.p(viewData.priceBg:getContentSize().width / 2 - 10, viewData.priceBg:getContentSize().height / 2 + 3))
            display.commonLabelParams(viewData.priceLabel, {text = __('已购买')})
        else
            viewData.dayBg:setVisible(false)
            viewData.timeBg:setVisible(true)
            viewData.timeLabel:setString(CommonUtils.GetFormattedTimeBySecond(nextDayLeftSeconds, ':'))
            viewData.priceBg:setTexture(RES_DICT.PRICE_BG_ORANGE)
            viewData.priceLabel:setPosition(cc.p(viewData.priceBg:getContentSize().width / 2 - 60, viewData.priceBg:getContentSize().height / 2))
            display.commonLabelParams(viewData.priceLabel, {text = __("￥") .. tostring(giftData.discountPrice)})
            viewData.originalPriceLabel:setVisible(true)
            display.commonLabelParams(viewData.originalPriceLabel, {text = '(' .. __("￥") .. tostring(giftData.originalPrice) .. ')'})
            -- 计算位置
            local discountPriceW = display.getLabelContentSize(viewData.priceLabel).width
            local originalPriceW = display.getLabelContentSize(viewData.originalPriceLabel).width
            viewData.priceLabel:setAnchorPoint(display.LEFT_CENTER)
            viewData.originalPriceLabel:setAnchorPoint(display.RIGHT_CENTER)
            viewData.priceLabel:setPositionX(viewData.priceBg:getContentSize().width / 2 - (discountPriceW + originalPriceW ) / 2 - 25)
            viewData.originalPriceLabel:setPositionX(viewData.priceBg:getContentSize().width / 2 + (discountPriceW + originalPriceW ) / 2 - 15)
            local line = display.newImageView(RES_DICT.PRICE_LINE, viewData.priceBg:getContentSize().width / 2 + (discountPriceW + originalPriceW ) / 2 - 15, viewData.originalPriceLabel:getPositionY(), {scale9 = true, size = cc.size(originalPriceW, 2), ap = display.RIGHT_CENTER})
            line:setName('line')
            viewData.priceBg:addChild(line, 5)
        end
    else
        viewData.dayBg:setVisible(true)
        viewData.timeBg:setVisible(false)
        viewData.bgBtn:setNormalImage(RES_DICT.NODE_BG_N)
        viewData.bgBtn:setSelectedImage(RES_DICT.NODE_BG_N)
        viewData.giftIcon:setTexture(string.format('ui/home/activity/noviceWelfare/gifts_icon_%d_1.png', giftData.photoId))
        viewData.priceLabel:setPosition(cc.p(viewData.priceBg:getContentSize().width / 2 - 10, viewData.priceBg:getContentSize().height / 2 + 3))
        if checkint(giftData.hasPurchased) == 1 then
            viewData.priceBg:setTexture(RES_DICT.PRICE_BG_GRAY)
            display.commonLabelParams(viewData.priceLabel, {text = __('已购买')})
        else
            viewData.priceBg:setTexture(RES_DICT.PRICE_BG_VIOLET)
            display.commonLabelParams(viewData.priceLabel, {text = __("￥") .. tostring(giftData.originalPrice)})
        end
        if index == today + 1 then
            viewData.lockIcon:setVisible(false)
            viewData.lockClockIcon:setVisible(true)
            viewData.lockTimeLabel:setVisible(true)
            viewData.lockTimeLabel:setString(CommonUtils.GetFormattedTimeBySecond(nextDayLeftSeconds, ':'))
        else
            viewData.lockIcon:setVisible(true)
            viewData.lockClockIcon:setVisible(false)
            viewData.lockTimeLabel:setVisible(false)
        end
    end
    if callback then
        self.callback = callback
    end
    viewData.view:setVisible(true)
end
--[[
领取按钮点击回调
--]]
function NoviceWelfareGiftNode:ButtonCallback( sender )
    if self.callback then
        self.callback(sender)
    end
end
--[[
刷新剩余时间
--]]
function NoviceWelfareGiftNode:RefreshTimeLabel( leftSeconds )
    local viewData = self:GetViewData()
    viewData.timeLabel:setString(CommonUtils.GetFormattedTimeBySecond(leftSeconds, ':'))
    viewData.lockTimeLabel:setString(CommonUtils.GetFormattedTimeBySecond(leftSeconds, ':'))
end
--[[
获取viewData
--]]
function NoviceWelfareGiftNode:GetViewData()
    return self.viewData
end
return NoviceWelfareGiftNode
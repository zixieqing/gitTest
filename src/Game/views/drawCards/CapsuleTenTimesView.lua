--[[
新卡池 十连抽卡 view
--]]
local CapsuleTenTimesView = class('CapsuleTenTimesView', function ()
    local node = CLayout:create()
    node.name = 'home.CapsuleTenTimesView'
    node:enableNodeEvents()
    return node
end)
local RES_DICT = {
    BOTTOM_BG         = _res("ui/home/capsuleNew/common/summon_activity_bg_.png"),
    BOTTOM_TEXT_BG    = _res('ui/home/capsuleNew/tenTimes/summon_10_series_bg_text.png'),
    PROGRESS_BG       = _res('ui/home/capsuleNew/tenTimes/unni_activity_bg_loading_login_get_1.png'),
    PROGRESS_IMG      = _res('ui/home/capsuleNew/tenTimes/unni_activity_bg_loading_login_get_2.png'),
    COMMON_BTN        = _res('ui/common/common_btn_big_orange_2.png'),
    TIPS_BG           = _res('ui/home/capsuleNew/tenTimes/summon_10_series_bg_sale_tips.png'),
    SALE_BG           = _res('ui/home/capsuleNew/tenTimes/summon_10_series_bg_prize_sale.png'),
    CARD_TEXT_BG      = _res('ui/home/capsuleNew/tenTimes/summon_goods_bg_text.png'),
    CARD_SHADOW       = _res('ui/home/capsuleNew/tenTimes/summon_bg_goods_button.png'),
    PRIZE_GOODS_BG    = _res('ui/home/capsuleNew/tenTimes/summon_prize_goods_bg.png'),
    PRIZE_GOODS_LIGHT = _res('ui/home/capsuleNew/tenTimes/summon_prize_goods_bg_light.png'),
    SALE_LINE         = _res('ui/home/capsuleNew/tenTimes/summon_img_line_sale.png'),

}
function CapsuleTenTimesView:ctor( ... )
	local args = unpack({...})
    self.size = args.size
    self:InitUI()
end

function CapsuleTenTimesView:InitUI()
    local size = self.size
    self:setContentSize(size)
    local function CreateView()
        local view = CLayout:create(size)
        -- bottomLayout
        local bottomLayoutSize = cc.size(1076, 250)
        local bottomLayout = CLayout:create(bottomLayoutSize)
        bottomLayout:setAnchorPoint(cc.p(0.5, 0))
        bottomLayout:setPosition(cc.p(size.width / 2, 15))
        view:addChild(bottomLayout, 1)
        local bottomBg = display.newImageView(RES_DICT.BOTTOM_BG, bottomLayoutSize.width / 2, 0, {ap = cc.p(0.5, 0)})
        bottomLayout:addChild(bottomBg, 1)
        local titleBg = display.newImageView(RES_DICT.BOTTOM_TEXT_BG, bottomLayoutSize.width / 2 - 10, 163, {scale9 = true, size = cc.size(966, 32)})
        bottomLayout:addChild(titleBg, 4)
        local titleLabel = display.newLabel(50, 163, fontWithColor(18, {text = __('完成一定数量十连可领取对应限定奖励'), ap = cc.p(0, 0.5)}))
        bottomLayout:addChild(titleLabel, 5)
        
        -- 进度条
        local progressBar = CProgressBar:create(RES_DICT.PROGRESS_IMG)
        progressBar:setBackgroundImage(RES_DICT.PROGRESS_BG)
        progressBar:setDirection(eProgressBarDirectionLeftToRight)
        progressBar:setAnchorPoint(cc.p(0, 0.5))
        progressBar:setPosition(cc.p(50, 70))
        bottomLayout:addChild(progressBar, 2)
        local rewardLayoutSize = cc.size(700, 150)
        local rewardLayout = CLayout:create(rewardLayoutSize)
        rewardLayout:setAnchorPoint(cc.p(0, 0.5))
        rewardLayout:setPosition(cc.p(50, 70))
        bottomLayout:addChild(rewardLayout, 3)
        -- 抽奖按钮
        local capsuleBtn = display.newButton(900, 90, {n = RES_DICT.COMMON_BTN})
        bottomLayout:addChild(capsuleBtn, 10)
        local btnLabel = display.newLabel(capsuleBtn:getContentSize().width / 2, capsuleBtn:getContentSize().height / 2, fontWithColor(14, {text = __('10连召唤')}))
        capsuleBtn:addChild(btnLabel, 1)
        local consumeText = display.newLabel(900, 30, {text = __('消耗'), fontSize = 22, color = '#ffffff', ap = cc.p(0, 0.5)})
        bottomLayout:addChild(consumeText, 5)
        consumeText:setVisible(false)
        local consumeNum = cc.Label:createWithBMFont('font/small/common_text_num.fnt', '')
        consumeNum:setHorizontalAlignment(display.TAR)
        consumeNum:setPosition(cc.p(885, 30))
        bottomLayout:addChild(consumeNum, 5)
        consumeNum:setVisible(false)
        consumeNum:setAnchorPoint(cc.p(0, 0.5))
        local consumeGoods = display.newImageView(_res(CommonUtils.GetGoodsIconPathById(DIAMOND_ID)), 900, 30, {ap = cc.p(0, 0.5)})
        consumeGoods:setScale(0.2)
        bottomLayout:addChild(consumeGoods, 5)
        consumeGoods:setVisible(false)
        local saleLine = display.newImageView(RES_DICT.SALE_LINE, 900 + display.getLabelContentSize(consumeText).width / 2, 30, {})
        saleLine:setVisible(false)
        bottomLayout:addChild(saleLine, 5)
        -- tips
        local tipsBg = display.newImageView(RES_DICT.TIPS_BG, 900, 115, {ap = cc.p(0.5, 0)})
        tipsBg:setVisible(false)
        bottomLayout:addChild(tipsBg, 10)
        local tipsLabel = display.newLabel(tipsBg:getContentSize().width / 2, 90, {text = __('首次召唤'), fontSize = 26, color = 'ffcf5b', font = TTF_GAME_FONT, ttf = true, outline = '#694343', outlineSize = 2})
        tipsBg:addChild(tipsLabel, 1)
        local saleBg = display.newImageView(RES_DICT.SALE_BG, tipsBg:getContentSize().width / 2, 50)
        tipsBg:addChild(saleBg, 3)
        local saleConsumeText = display.newLabel(tipsBg:getContentSize().width / 2, 90, {text = __('消耗'), fontSize = 22, color = '#ffffff', ap = cc.p(0, 0.5)})
        tipsBg:addChild(saleConsumeText, 5)
        local saleConsumeNum = cc.Label:createWithBMFont('font/small/common_text_num.fnt', '')
        saleConsumeNum:setHorizontalAlignment(display.TAR)
        saleConsumeNum:setPosition(cc.p(0, 0.5))
        saleConsumeNum:setPosition(cc.p(tipsBg:getContentSize().width / 2 - 15, 50))
        tipsBg:addChild(saleConsumeNum, 5)
        local saleConsumeGoods = display.newImageView(_res(CommonUtils.GetGoodsIconPathById(DIAMOND_ID)), tipsBg:getContentSize().width / 2, 50, {ap = cc.p(0, 0.5)})
        saleConsumeGoods:setScale(0.2)
        tipsBg:addChild(saleConsumeGoods, 5)
        return {
            view             = view,
            capsuleBtn       = capsuleBtn,
            tipsBg           = tipsBg,
            saleBg           = saleBg,
            consumeText      = consumeText,
            consumeNum       = consumeNum,
            consumeGoods     = consumeGoods,
            saleConsumeText  = saleConsumeText,
            saleConsumeNum   = saleConsumeNum,
            saleConsumeGoods = saleConsumeGoods,
            rewardLayout     = rewardLayout,
            progressBar      = progressBar,
            saleLine         = saleLine,
        }
    end
    xTry(function ( )
        self.viewData = CreateView()
        self.viewData.view:setPosition(utils.getLocalCenter(self))
        self:addChild(self.viewData.view, 1)
	end, __G__TRACKBACK__)
end
--[[
刷新价格
@params data map {
    consume map 抽卡消耗 {
        goodsId int 道具id
        num     int 道具数量
    }
    discountConsume map 折扣消耗 {
        goodsId int 道具id
        num     int 道具数量
    }
    isDiscount int 当前次数是否打折(1:打折, 0:不打折)
}
--]]
function CapsuleTenTimesView:RefreshPrice( data )
    if not data then return end
    local consume = checktable(data.consume)
    local discountConsume = checktable(data.discountConsume)
    local isDiscount = checkint(data.isDiscount)
    local viewData = self.viewData
    -- 原价
    
    viewData.consumeNum:setString(consume.num)
    viewData.consumeGoods:setTexture(CommonUtils.GetGoodsIconPathById(consume.goodsId))
    local w1 = display.getLabelContentSize(viewData.consumeText).width
    local w2 = viewData.consumeNum:getContentSize().width
    local w3 = 30
    viewData.consumeText:setPositionX(900 - (w1 + w2 + w3) / 2)
    viewData.consumeNum:setPositionX(900 - (w1 + w2 + w3) / 2 + w1)
    viewData.consumeGoods:setPositionX(900 - (w1 + w2 + w3) / 2 + w1 + w2)
    viewData.consumeText:setVisible(true)
    viewData.consumeNum:setVisible(true)
    viewData.consumeGoods:setVisible(true)
    if isJapanSdk() then
        viewData.consumeText:setVisible(false)
        display.setNodesToNodeOnCenter(viewData.capsuleBtn, {viewData.consumeGoods, viewData.consumeNum}, {y = -18})
    end
    if isDiscount == 1 then
        viewData.tipsBg:setVisible(true)
        viewData.saleConsumeNum:setString(discountConsume.num)
        viewData.saleConsumeGoods:setTexture(CommonUtils.GetGoodsIconPathById(discountConsume.goodsId))
        local centerX = viewData.tipsBg:getContentSize().width / 2
        local w1 = display.getLabelContentSize(viewData.saleConsumeText).width
        local w2 = viewData.saleConsumeNum:getContentSize().width
        local w3 = 30
        viewData.saleConsumeText:setPositionX(centerX - (w1 + w2 + w3) / 2)
        viewData.saleConsumeNum:setPositionX(centerX - (w1 + w2 + w3) / 2 + w1)
        viewData.saleConsumeGoods:setPositionX(centerX - (w1 + w2 + w3) / 2 + w1 + w2)
        viewData.saleLine:setPosition(900 + display.getLabelContentSize(viewData.consumeText).width / 2, 30)
        viewData.saleLine:setScaleX((viewData.consumeNum:getContentSize().width + 50) / 98)
        viewData.saleLine:setVisible(true)
    else
        viewData.tipsBg:setVisible(false)
        viewData.saleLine:setVisible(false)
    end
end
--[[
刷新限定奖励列表
@params stapData list {
    hasDrawn int 是否领取(1:已领取, 0:未领取)
    highlight int 是否高亮(1:高亮, 0:不高亮)
}
--]]
function CapsuleTenTimesView:RefreshRewardList( stapData )
    if not stapData then return end
    local viewData = self.viewData
    local rewardLayout = viewData.rewardLayout
    local progress = checkint(stapData[#stapData].progress)
    local maxValue = checkint(stapData[#stapData].targetNum)
    viewData.progressBar:setMaxValue(maxValue)
    viewData.progressBar:setValue(progress)
    rewardLayout:removeAllChildren()
    for i, v in ipairs(checktable(stapData)) do
        local goodsId = v.rewards[1].goodsId
        local cardHeadIcon = require('common.GoodNode').new({
            id = goodsId,
            showAmount = true,
            num = v.rewards[1].num,
            callBack = function (sender)
                local goodsType = CommonUtils.GetGoodTypeById(goodsId)
                if goodsType == GoodsType.TYPE_CARD then
                    -- 显示卡牌预览
                    local cardPreviewView = require('common.CardPreviewView').new({
                        confId = goodsId
                    })
                    display.commonUIParams(cardPreviewView, {ap = display.CENTER, po = display.center})
                    app.uiMgr:GetCurrentScene():AddDialog(cardPreviewView)
                else
                    app.uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = goodsId, type = 1})
                end
            end,
            highlight = i == #stapData and v.highlight or 0
        })
        local posX = (592 * checkint(v.targetNum) / maxValue) - 10
        local cardW = cardHeadIcon:getContentSize().width
        local cardH = cardHeadIcon:getContentSize().height
        if i ~= #stapData then
            cardHeadIcon:setScale(0.8)
            cardW = cardW * 0.8
            cardH = cardH * 0.8
        end
        display.commonUIParams(cardHeadIcon, {ap = cc.p(0, 0), po = cc.p(posX, 45)})
        rewardLayout:addChild(cardHeadIcon, 5)
        if checkint(v.hasDrawn) == 1 then
            local hasDrawnBg = display.newImageView(RES_DICT.CARD_TEXT_BG, cardHeadIcon:getContentSize().width / 2, cardHeadIcon:getContentSize().height / 2)
            cardHeadIcon:addChild(hasDrawnBg, 10)
            local hasDrawnLabel = display.newLabel(hasDrawnBg:getContentSize().width / 2, hasDrawnBg:getContentSize().height / 2, fontWithColor(18, {text = __('已领取')}))
            hasDrawnBg:addChild(hasDrawnLabel, 1)
        end
        if checkint(v.highlight) == 1 and i ~= #stapData then
            local lightBg = display.newImageView(RES_DICT.PRIZE_GOODS_BG, posX + cardW / 2, 45 + cardH / 2)
            rewardLayout:addChild(lightBg, 1)
            local light = display.newImageView(RES_DICT.PRIZE_GOODS_LIGHT, posX + cardW / 2, 45 + cardH / 2)
            rewardLayout:addChild(light, 2)
            light:runAction(cc.RepeatForever:create(
                cc.RotateBy:create(1, 30)
            ))
        end
        local shadow = display.newImageView(RES_DICT.CARD_SHADOW, posX + cardW / 2, 45)
        rewardLayout:addChild(shadow, 4)
        local progressBg = display.newImageView(RES_DICT.CARD_TEXT_BG, posX + cardH / 2, 20)
        rewardLayout:addChild(progressBg, 5)
        local progressLabel = display.newLabel(progressBg:getContentSize().width / 2, progressBg:getContentSize().height / 2, fontWithColor(9, {
            text = string.format('%d/%d', math.min(checkint(v.progress), checkint(v.targetNum)), checkint(v.targetNum))
        }))
        progressBg:addChild(progressLabel, 5)
    end


end
return CapsuleTenTimesView

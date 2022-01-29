--[[
幸运字符活动view
--]]
local VIEW_SIZE = cc.size(1035, 637)
local ActivityLuckNumberView = class('ActivityLuckNumberView', function ()
    local node = CLayout:create(VIEW_SIZE)
    node.name = 'Game.views.activity.luckNumber.ActivityLuckNumberView'
    node:enableNodeEvents()
    return node
end)

local CreateView     = nil
local CreateNumCell  = nil
local CreateCell     = nil

local display = display

local RES_DICT = {
    ACTIVITY_BG_CARD                     = _res('ui/home/activity/luckNumber/activity_bg_card.png'),
    ACTIVITY_LUCK_BTN_CHARGE             = _res('ui/home/activity/luckNumber/activity_luck_btn_charge.png'),
    ACTIVITY_LUCK_NUM_BG_GIFT_ACTIVE     = _res('ui/home/activity/luckNumber/activity_luck_num_bg_gift_active.png'),
    ACTIVITY_LUCK_NUM_BG_GIFT_UNACTIVE   = _res('ui/home/activity/luckNumber/activity_luck_num_bg_gift_unactive.png'),
    ACTIVITY_LUCK_NUM_BG_TITLE           = _res('ui/home/activity/luckNumber/activity_luck_num_bg_title.png'),
    ACTIVITY_LUCK_NUM_BG_TOTAL           = _res('ui/home/activity/luckNumber/activity_luck_num_bg_total.png'),
    ACTIVITY_LUCK_NUM_EFFECT_IGHT        = _res('ui/home/activity/luckNumber/activity_luck_num_effect_ight.png'),
    ACTIVITY_LUCK_NUM_PIC_NO_GET         = _res('ui/home/activity/luckNumber/activity_luck_num_pic_no_get.png'),
    ACTIVITY_LUCK_NUM_PIC                = _res('ui/home/activity/luckNumber/activity_luck_num_pic.png'),
    ACTIVITY_LUCKY_NUM_BG_GIFT_NAME      = _res('ui/home/activity/luckNumber/activity_lucky_num_bg_gift_name.png'),
    ACTIVITY_LUCKY_NUM_BG_GOODS_ACTIVE   = _res('ui/home/activity/luckNumber/activity_lucky_num_bg_goods_active.png'),
    ACTIVITY_LUCKY_NUM_BG_GOODS_UNACTIVE = _res('ui/home/activity/luckNumber/activity_lucky_num_bg_goods_unactive.png'),
    ACTIVITY_LUCKY_NUM_BG_NUM            = _res('ui/home/activity/luckNumber/activity_lucky_num_bg_num.png'),
    ACTIVITY_LUCKY_NUM_BG_TIME           = _res('ui/home/activity/luckNumber/activity_lucky_num_bg_time.png'),
    ACTIVITY_LUCKY_NUM_BG                = _res('ui/home/activity/luckNumber/activity_lucky_num_bg.jpg'),
    TIME_BG                              = _res('ui/home/activity/activity_time_bg.png'),
    COMMON_BTN_BIG_ORANGE_2              = _res('ui/common/common_btn_big_orange_2.png'),

    COMMON_FRAME_YANHUA                  = _spn('ui/home/activity/luckNumber/effect/common_frame_yanhua'),
    ZHOUNIANQING_BIANKUANG               = _spn('ui/home/activity/luckNumber/effect/zhounianqing_biankuang'),
}

function ActivityLuckNumberView:ctor( ... )
    self.args = unpack({...})

    self:InitUI()
end
--[[
init ui
--]]
function ActivityLuckNumberView:InitUI()
    xTry(function ( )
        self.viewData_ = CreateView(VIEW_SIZE)
        self:addChild(self.viewData_.view)
	end, __G__TRACKBACK__)
    
end

CreateView = function (size)
    local middleX, middleY = size.width * 0.5, size.height * 0.5
    local view = display.newLayer(middleX, middleY, {size = size, ap = display.CENTER})
    
    -- 背景
	local bg = lrequire('root.WebSprite').new({url = '', hpath = _res('ui/home/activity/activity_bg_loading.jpg'), tsize = cc.size(1028,630)})
    bg:setAnchorPoint(display.CENTER)
    bg:setPosition(cc.p(middleX, middleY))
	view:addChild(bg)

    local titleNameLabel = display.newLabel(20, size.height - 10, {
        ap = display.LEFT_TOP, fontSize = 50, color = '#ffe16a', font = TTF_GAME_FONT, ttf = true, outline = '#472723', outlineSize = 4})
    view:addChild(titleNameLabel)

    local ruleBtn = display.newButton(160, size.height - 41, {n = _res('ui/common/common_btn_tips.png')})
    ruleBtn:setVisible(false)
    view:addChild(ruleBtn)

    local timeBg = display.newImageView(RES_DICT.TIME_BG, 1030, 600, {
        ap = display.RIGHT_CENTER , scale9 = true , size = cc.size(320 , 47)
    })
	local timeBgSize = timeBg:getContentSize()
	view:addChild(timeBg)
	local timeTitleLabel = display.newLabel(135, timeBgSize.height * 0.5, fontWithColor(18, {text = __('剩余时间:'), ap = display.RIGHT_CENTER}))
	timeBg:addChild(timeTitleLabel)
	local timeLabel = display.newLabel(timeTitleLabel:getPositionX() + 5, timeTitleLabel:getPositionY(), {text = '', ap = cc.p(0, 0.5), fontSize = 22, color = '#ffe9b4', font = TTF_GAME_FONT, ttf = true, outline = '#3c1e0e', outlineSize = 1})
    timeBg:addChild(timeLabel)

    local curNumTitle = display.newNSprite(RES_DICT.ACTIVITY_LUCK_NUM_BG_TITLE, middleX - 24, size.height - 170)
    view:addChild(curNumTitle)
    local curNumTitleLabel = display.newLabel(227, 18, {text = __('当前拥有的幸运字符'), fontSize = 22, color = '#ffd9a2'})
    curNumTitle:addChild(curNumTitleLabel)

    ----------------------------------------------
    --- 获得的幸运字符相关UI
    local luckNumLayerSize = cc.size(463, 142)
    local luckNumLayer = display.newLayer(curNumTitle:getPositionX(), size.height - 186, {size = luckNumLayerSize, ap = display.CENTER_TOP})
    view:addChild(luckNumLayer)
    local luckNumLayerMiddleX, luckNumLayerMiddleY = luckNumLayerSize.width * 0.5, luckNumLayerSize.height * 0.5

    local luckNumBg = display.newNSprite(RES_DICT.ACTIVITY_BG_CARD, luckNumLayerMiddleX, luckNumLayerMiddleY)
    luckNumLayer:addChild(luckNumBg)
        
    local luckNumCells = {}
    local luckNumCardCount = 5
    local startX = 5
    local luckNumCellSize = cc.size((luckNumLayerSize.width - startX) / luckNumCardCount, luckNumLayerSize.height)
    for i = 1, luckNumCardCount do
        local luckNumCell = CreateNumCell(luckNumCellSize)
        display.commonUIParams(luckNumCell, {ap = display.LEFT_BOTTOM, po = cc.p(startX + (i-1) * luckNumCellSize.width, 0)})
        luckNumLayer:addChild(luckNumCell)

        table.insert(luckNumCells, luckNumCell)
    end
    --- 获得的幸运字符相关UI
    ----------------------------------------------

    local exchangeBtnLayerSize = cc.size(343, 78)
    local exchangeBtnLayer = display.newLayer(curNumTitle:getPositionX(), middleY - 60, {ap = display.CENTER, size = exchangeBtnLayerSize})
    view:addChild(exchangeBtnLayer)

    local lightImg = display.newImageView(RES_DICT.ACTIVITY_LUCK_NUM_EFFECT_IGHT, exchangeBtnLayerSize.width * 0.5, exchangeBtnLayerSize.height * 0.5)
    exchangeBtnLayer:addChild(lightImg)
    
    -- 兑换按钮
    local exchangeBtn = display.newButton(lightImg:getPositionX(), lightImg:getPositionY(), {n = RES_DICT.ACTIVITY_LUCK_BTN_CHARGE})
    display.commonLabelParams(exchangeBtn, fontWithColor(14, {text = __('幸运字符兑换')}))
    exchangeBtnLayer:addChild(exchangeBtn)

    local deltaTime = 0.8
    exchangeBtnLayer:runAction(cc.RepeatForever:create(cc.Sequence:create({
        cc.ScaleTo:create(deltaTime, 1.1, 1.1),
        cc.ScaleTo:create(deltaTime, 1),
        cc.ScaleTo:create(deltaTime, 1.1, 1.1),
        cc.ScaleTo:create(deltaTime, 1)
    })))

    ----------------------------------------------
    --- 礼包相关UI
    local giftInfoLayerSize = cc.size(965, 173)
    local giftInfoLayerMiddleX, giftInfoLayerMiddleY = giftInfoLayerSize.width * 0.5, giftInfoLayerSize.height * 0.5
    local giftInfoLayer = display.newLayer(middleX, 10, {ap = display.CENTER_BOTTOM, size = giftInfoLayerSize})
    view:addChild(giftInfoLayer)

    -- 未开启秒杀时的背景
    local giftInfoUnactiveBg = display.newImageView(RES_DICT.ACTIVITY_LUCK_NUM_BG_GIFT_UNACTIVE, giftInfoLayerMiddleX, giftInfoLayerMiddleY, {scale9 = true, size = giftInfoLayerSize})
    giftInfoLayer:addChild(giftInfoUnactiveBg)
    giftInfoUnactiveBg:setVisible(false)
    
    -- 开启秒杀时的背景
    local giftInfoActiveBg = display.newImageView(RES_DICT.ACTIVITY_LUCK_NUM_BG_GIFT_ACTIVE, giftInfoLayerMiddleX, giftInfoLayerMiddleY, {scale9 = true, size = giftInfoLayerSize})
    giftInfoLayer:addChild(giftInfoActiveBg)
    giftInfoActiveBg:setVisible(false)

    local spineFrame = sp.SkeletonAnimation:create(RES_DICT.ZHOUNIANQING_BIANKUANG.json, RES_DICT.ZHOUNIANQING_BIANKUANG.atlas, 1)
    spineFrame:update(0)
    spineFrame:setPosition(cc.p(giftInfoLayerMiddleX + 0.5, giftInfoLayerMiddleY + 2))
    spineFrame:setAnimation(0, 'idle', true)
    spineFrame:setVisible(false)
    giftInfoLayer:addChild(spineFrame)

    local tipLabel = display.newLabel(220, giftInfoLayerSize.height - 10, {
        ap = display.LEFT_TOP, text = __('超值秒杀，集幸运字符还可获得超稀有奖励！'),   reqW = 500  ,  fontSize = 22, color = '#fff0a8'})
    giftInfoLayer:addChild(tipLabel)

    local giftRewardsBg = display.newNSprite(RES_DICT.ACTIVITY_LUCKY_NUM_BG_GOODS_UNACTIVE, 150, giftInfoLayerMiddleY - 8, {ap = display.LEFT_CENTER})
    giftInfoLayer:addChild(giftRewardsBg)

    -- 礼包图标
    local giftIcon = display.newButton(120, giftInfoLayerMiddleY + 25, {n = CommonUtils.GetGoodsIconPathById(701023), ap = display.CENTER})
    -- display.commonUIParams(giftIcon, fontWithColor(20, {text = __('数字礼包'), fontSize = 27, color = '#b21415', outline = '#fffda1'}))
    giftInfoLayer:addChild(giftIcon)

    local giftNameBg = display.newNSprite(RES_DICT.ACTIVITY_LUCKY_NUM_BG_GIFT_NAME, 80, 10, {ap = display.CENTER})
    giftIcon:addChild(giftNameBg)

    -- 礼包名称
    local giftName = display.newLabel(82, 35, fontWithColor(7, {text = __('超值礼包'), fontSize = 26, color = '#b21415'}))
    giftNameBg:addChild((giftName))

    -- 礼包道具层
    local tableViewSize = cc.size(460, 100)
    local tableView = CTableView:create(tableViewSize)
    display.commonUIParams(tableView, {po = cc.p(220, giftRewardsBg:getPositionY()), ap = display.LEFT_CENTER})
    tableView:setDirection(eScrollViewDirectionHorizontal)
    -- tableView:setBackgroundColor(cc.c4b(23, 67, 128, 128))
    tableView:setSizeOfCell(cc.size(100, 100))
    giftInfoLayer:addChild(tableView)
    
    local totalStockBg = display.newNSprite(RES_DICT.ACTIVITY_LUCK_NUM_BG_TOTAL, giftInfoLayerSize.width + 22, giftInfoLayerSize.height - 13, {ap = display.RIGHT_CENTER})
    giftInfoLayer:addChild(totalStockBg)
    totalStockBg:setVisible(false)

    -- 总库存标签
    local totalStockLabel = display.newRichLabel(230, 38, {ap = display.RIGHT_CENTER})
    totalStockBg:addChild(totalStockLabel)
    
    local buyButton = display.newButton(giftInfoLayerSize.width - 20, giftInfoLayerMiddleY, {n = RES_DICT.COMMON_BTN_BIG_ORANGE_2, ap = display.RIGHT_CENTER})
    display.commonLabelParams(buyButton, fontWithColor(20, {fontSize = 40, outline = '#5d413d'}))
    giftInfoLayer:addChild(buyButton)
    buyButton:setVisible(false)

    local buyTimesLabel = display.newRichLabel(giftInfoLayerSize.width - 110, 30, {ap = display.CENTER})
    giftInfoLayer:addChild(buyTimesLabel)
    buyTimesLabel:setVisible(false)

    -- 活动开始倒计时
    local startTimeBg = display.newNSprite(RES_DICT.ACTIVITY_LUCKY_NUM_BG_TIME, giftInfoLayerSize.width - 20, giftInfoLayerMiddleY - 10, {ap = display.RIGHT_CENTER})
    giftInfoLayer:addChild(startTimeBg)
    startTimeBg:setVisible(false)

    local startTipLabel = display.newLabel(100, 50, {ap = display.CENTER, fontSize = 20, color = '#e7cfa8', text = __('开始倒计时')})
    startTimeBg:addChild(startTipLabel)

    local startLeftTimeLabel = display.newLabel(100, 20, fontWithColor(14, {ap = display.CENTER, text = '00:00:00'}))
    startTimeBg:addChild(startLeftTimeLabel)

    --- 获得的幸运字符相关UI
    ----------------------------------------------

    local spine = sp.SkeletonAnimation:create(RES_DICT.COMMON_FRAME_YANHUA.json, RES_DICT.COMMON_FRAME_YANHUA.atlas, 1)
    spine:update(0)
    spine:setAnimation(0, 'idle2', true)
    spine:setPosition(cc.p(middleX, middleY))
    view:addChild(spine)

    return {
        view               = view,
        bg                 = bg,
        timeLabel          = timeLabel,
        titleNameLabel     = titleNameLabel,
        ruleBtn            = ruleBtn,
        luckNumCells       = luckNumCells,
        exchangeBtnLayer   = exchangeBtnLayer,
        exchangeBtn        = exchangeBtn,
        giftInfoUnactiveBg = giftInfoUnactiveBg,
        giftInfoActiveBg   = giftInfoActiveBg,
        spineFrame         = spineFrame,
        giftIcon           = giftIcon,
        giftName           = giftName,
        totalStockLabel    = totalStockLabel,
        tableView          = tableView,
        totalStockBg       = totalStockBg,
        buyButton          = buyButton,
        buyTimesLabel      = buyTimesLabel,
        startTimeBg        = startTimeBg,
        startLeftTimeLabel = startLeftTimeLabel,
    }
end

CreateNumCell = function (size)
    local cell = display.newLayer(0, 0, {size = size})
    local middleX, middleY = size.width * 0.5, size.height * 0.5
    local numBg = display.newNSprite(RES_DICT.ACTIVITY_LUCK_NUM_PIC_NO_GET, middleX, size.height - 6, {ap = display.CENTER_TOP})
    cell:addChild(numBg)

    local numLabel = display.newLabel(38, 50, {ap = display.CENTER, fontSize = 40, color = '#b21415'})
    numBg:addChild(numLabel)

    local numCount = display.newButton(middleX, 8, {enable = false, ap = display.CENTER_BOTTOM, n = RES_DICT.ACTIVITY_LUCKY_NUM_BG_NUM})
    display.commonLabelParams(numCount, {fontSize = 22, color = '#987e7e'})
    cell:addChild(numCount)

    cell.viewData = {
        numBg         = numBg,
        numLabel      = numLabel,
        numCount      = numCount,
    }
    return cell
end

CreateCell_ = function (size)
    local cell = CTableViewCell:new()
    cell:setContentSize(size)

    local goodNode = require('common.GoodNode').new({
        showAmount = true,
        -- highlight = 1,
        callBack = function (sender)
            app.uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = sender.goodId, type = 1})
        end
    })
    display.commonUIParams(goodNode, {ap = display.CENTER, po = cc.p(size.width * 0.5, size.height * 0.5)})
    cell:addChild(goodNode)
    goodNode:setScale(0.9)
    cell.goodNode = goodNode

    return cell
end

function ActivityLuckNumberView:UpdateBg(posterImage)
    local viewData = self:GetViewData()
    viewData.bg:setWebURL(posterImage)
end

function ActivityLuckNumberView:CreateCell(size)
    return CreateCell_(size)
end

function ActivityLuckNumberView:GetViewData()
    return self.viewData_
end

return ActivityLuckNumberView
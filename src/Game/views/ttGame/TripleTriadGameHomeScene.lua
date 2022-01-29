--[[
 * author : kaishiqi
 * descpt : 打牌游戏 - 主页场景
]]
local GoodPurchaseNode = require('common.GoodPurchaseNode')
local TTGameHomeScene  = class('TripleTriadGameHomeScene', require('Frame.GameScene'))

local RES_DICT = {
    COM_TITLE_BAR     = _res('ui/common/common_title.png'),
    COM_TIPS_ICON     = _res('ui/common/common_btn_tips.png'),
    COM_BACK_BTN      = _res('ui/common/common_btn_back.png'),
    MONEY_INFO_BAR    = _res('ui/home/nmain/main_bg_money.png'),
    BTN_GUIDE         = _res('guide/guide_ico_book.png'),
    BG_IMAGE          = _res('arts/stage/bg/main_bg_69.jpg'),
    RULE_BG_FRAME     = _res('ui/ttgame/common/cardgame_common_bg_1.png'),
    BATTLE_BG_FRAME   = _res('ui/ttgame/common/cardgame_common_bg_2.png'),
    RULE_CUTTING_LINE = _res('ui/ttgame/common/cardgame_common_line_1.png'),
    COMMON_BTN_N      = _res('ui/ttgame/common/cardgame_main_btn_common_1.png'),
    ALBUM_ICON        = _res('ui/ttgame/home/cardgame_main_ico_collection.png'),
    SHOP_ICON         = _res('ui/ttgame/home/cardgame_main_ico_store.png'),
    NUM_FRAME         = _res('ui/ttgame/home/cardgame_main_label_btn_num.png'),
    REPORT_BTN        = _res('ui/ttgame/home/cardgame_main_ico_report.png'),
    FRIEND_ICON       = _res('ui/ttgame/home/cardgame_main_ico_friend.png'),
    PVP_ICON          = _res('ui/ttgame/home/cardgame_main_ico_pvp.png'),
    FRIEND_TITLE      = _res('ui/ttgame/home/cardgame_main_label_friend.png'),
    PVP_TITLE         = _res('ui/ttgame/home/cardgame_main_label_pvp.png'),
    COMMON_BTN2_D     = _res('ui/ttgame/common/cardgame_main_btn_common_2_disable.png'),
    COMMON_BTN2_N     = _res('ui/ttgame/common/cardgame_main_btn_common_2.png'),
    SEARCH_BTN_N      = _res('ui/ttgame/home/cardgame_main_btn_search.png'),
    PVP_DATE_BTN_N    = _res('ui/ttgame/common/cardgame_main_ico_date.png'),
    PVP_TIME_FRAME    = _res('ui/ttgame/home/cardgame_main_bg_pvp_text.png'),
    PVP_CUTTING_LINE  = _res('ui/ttgame/home/cardgame_main_line_pvp.png'),
    SHOP_ICO_TIME_N   = _res("ui/stores/base/shop_ico_time.png"),
    PVE_TITLE_FRAME   = _res('ui/ttgame/home/cardgame_main_pve_btn_enter.png'),
    SHOP_ICO_TIME_D   = _res("ui/stores/base/shop_ico_time_dark.png"),
    PVE_BTN_FRAME     = _res('ui/ttgame/home/cardgame_main_pve_frame_default.png'),
    PVE_TIPS_ICON     = _res('ui/ttgame/home/cardgame_main_pve_ico_tip.png'),
    PVE_TIME_TITLE    = _res('ui/ttgame/home/cardgame_main_pve_label_limit.png'),
    PVE_TIME_BAR      = _res('ui/ttgame/home/cardgame_main_pve_label_timer.png'),
    PVE_TIPS_BAR      = _res('ui/ttgame/home/cardgame_main_pve_label_tip.png'),
}

local MoneyListDefine = {
    {disable = true,  id = TTGAME_DEFINE.CURRENCY_ID},
    {disable = false, id = GOLD_ID},
    {disable = false, id = DIAMOND_ID},
}

local CreateView = nil


function TTGameHomeScene:ctor(args)
    self.super.ctor(self, 'Game.views.ttGame.TripleTriadGameHomeScene')

    -- create view
    self.viewData_ = CreateView()
    self:addChild(self.viewData_.view)

    -- update views
    self:updateMoneyBar()
end


CreateView = function()
    local view = display.newLayer()
    local size = view:getContentSize()

    -- block layer
    view:addChild(display.newImageView(RES_DICT.BG_IMAGE, size.width/2, size.height/2))
    view:addChild(display.newLayer(0, 0, {color = cc.c4b(0,0,0,100), enable = true}))

    ------------------------------------------------- [top]
    local topLayer = display.newLayer()
    view:addChild(topLayer)

    -- back button
    local backBtn = display.newButton(display.SAFE_L + 75, size.height - 52, {n = RES_DICT.COM_BACK_BTN})
    topLayer:addChild(backBtn)

    -- title button
    local titleBtn = display.newButton(display.SAFE_L + 120, size.height, {n = RES_DICT.COM_TITLE_BAR, ap = display.LEFT_TOP})
    display.commonLabelParams(titleBtn, fontWithColor(1, {reqW = 190 ,  text = __('战牌室'), offset = cc.p(-20,-10)}))
    topLayer:addChild(titleBtn)

    local titleSize = titleBtn:getContentSize()
    titleBtn:addChild(display.newImageView(RES_DICT.COM_TIPS_ICON, titleSize.width - 50, titleSize.height/2 - 10))

    -- guide button 
    local guideBtn = display.newButton(display.SAFE_L + 480, display.height - 42, {n = RES_DICT.BTN_GUIDE})
    display.commonLabelParams(guideBtn, fontWithColor(14, {text = __('指南'), fontSize = 28, offset = cc.p(10,-18)}))
    topLayer:addChild(guideBtn)

    -- money barBg
    local moneyBarBg = display.newImageView(_res(RES_DICT.MONEY_INFO_BAR), display.width, display.height, {ap = display.RIGHT_TOP, scale9 = true, size = cc.size(1, 54)})
    topLayer:addChild(moneyBarBg)

    -- money layer
    local moneyLayer = display.newLayer()
    topLayer:addChild(moneyLayer)

    -- update moneyLayer
    local MONEY_NODE_GAP = 16
    local moneyLayerSize = moneyLayer:getContentSize()
    local moneryBarSize  = cc.size(20, moneyBarBg:getContentSize().height)
    for i = #MoneyListDefine, 1, -1 do
        local moneyId   = checkint(MoneyListDefine[i].id)
        local isDisable = MoneyListDefine[i].disable == true
        local moneyNode = GoodPurchaseNode.new({id = moneyId, animate = true, disable = isDisable})
        moneyNode:setPosition(display.SAFE_R - moneryBarSize.width, moneyLayerSize.height - 26)
        moneyNode:setAnchorPoint(display.RIGHT_CENTER)
        moneyNode:setName(moneyId)
        moneyNode.viewData.touchBg:setTag(checkint(moneyId))
        moneyLayer:addChild(moneyNode)

        moneryBarSize.width = moneryBarSize.width + moneyNode:getContentSize().width + MONEY_NODE_GAP
    end

    -- update moneyBarBg
    moneryBarSize.width = 40 + moneryBarSize.width + (display.width - display.SAFE_R)
    moneyBarBg:setContentSize(moneryBarSize)


    ------------------------------------------------- [center]
    local centerLayer = display.newLayer()
    view:addChild(centerLayer)

    local pveOnLayer  = display.newLayer()
    local pveOffLayer = display.newLayer()
    centerLayer:addChild(pveOffLayer)
    centerLayer:addChild(pveOnLayer)
    

    -- default pveImage
    local defaultPveImg = AssetsUtils.GetCardDrawNode(200011)
    defaultPveImg:setPositionX(display.cx - 25)
    defaultPveImg:setPositionY(display.cy - 220)
    pveOffLayer:addChild(defaultPveImg)
    
    
    -- pveEnter layer
    local pveEnterSize  = cc.size(420, 600)
    local pveEnterLayer = display.newLayer(display.cx - 70, display.cy - 40, {size = pveEnterSize, ap = display.CENTER, color = cc.c4b(50,50,50,255), enable = true})
    pveOnLayer:addChild(pveEnterLayer)
    -- enter iamge
    local pveEnterImgLayer = display.newLayer(pveEnterSize.width/2, pveEnterSize.height/2)
    pveEnterLayer:addChild(pveEnterImgLayer)
    -- enter title
    pveEnterLayer:addChild(display.newImageView(RES_DICT.PVE_TITLE_FRAME, pveEnterSize.width/2, 85))
    pveEnterLayer:addChild(display.newLabel(pveEnterSize.width/2, 85, fontWithColor(7, {fontSize = 38, text = __('挑战牌王')})))
    -- enter tips
    pveEnterLayer:addChild(display.newImageView(RES_DICT.PVE_TIPS_ICON, pveEnterSize.width, 150, {ap = display.RIGHT_BOTTOM}))
    pveEnterLayer:addChild(display.newImageView(RES_DICT.PVE_TIPS_BAR, pveEnterSize.width, 160, { scale9 = true , size = cc.size(450,52), ap = display.RIGHT_CENTER}))
    pveEnterLayer:addChild(display.newLabel(pveEnterSize.width - 10, 160, fontWithColor(9, {ap = display.RIGHT_CENTER, text = __('挑战厉害的NPC获得奖励！')})))
    -- limit time
    pveEnterLayer:addChild(display.newImageView(RES_DICT.PVE_TIME_BAR, 0, pveEnterSize.height - 62, {ap = display.LEFT_CENTER}))
    pveEnterLayer:addChild(display.newImageView(RES_DICT.SHOP_ICO_TIME_D, 10, pveEnterSize.height - 62, {ap = display.LEFT_CENTER}))
    -- time label
    local pveTimeLabel = display.newLabel(45, pveEnterSize.height - 62, fontWithColor(5, {color = '#e4654b', ap = display.LEFT_CENTER, text = '--/--/--'}))
    pveEnterLayer:addChild(pveTimeLabel)
    -- enter frame
    pveEnterLayer:addChild(display.newImageView(RES_DICT.PVE_BTN_FRAME, pveEnterSize.width/2, pveEnterSize.height/2))
    -- enter limit

    local openLimitLabel = display.newLabel(10, pveEnterSize.height - 28, fontWithColor(3, {ap = display.LEFT_CENTER, text = __('限时开启')}))
    local openLimitLabelSize = display.getLabelContentSize(openLimitLabel)
    local width = 194
    width = openLimitLabelSize.width + 40 > width and  openLimitLabelSize.width + 40 or width
    pveEnterLayer:addChild(display.newImageView(RES_DICT.PVE_TIME_TITLE, -15, pveEnterSize.height - 30, {size = cc.size(width, 39 ) , scale9 = true ,  ap = display.LEFT_CENTER}))
    pveEnterLayer:addChild(openLimitLabel)


    ------------------------------------------------- [left]
    local leftAxisX = display.cx - 475
    local leftLayer = display.newLayer()
    view:addChild(leftLayer)
    

    -- album button
    local albumBtn = display.newButton(leftAxisX + 20, display.cy - 255, {n = RES_DICT.COMMON_BTN_N})
    display.commonLabelParams(albumBtn, fontWithColor(20, {fontSize = 26, outline = '#3b1010', text = __('牌册'), offset = cc.p(0,14)}))
    albumBtn:addChild(display.newImageView(RES_DICT.ALBUM_ICON, 20, utils.getLocalCenter(albumBtn).y))
    leftLayer:addChild(albumBtn)
    
    local collectLabel = display.newLabel(albumBtn:getPositionX(), albumBtn:getPositionY() - 18, fontWithColor(3, {fontSize = 26, text = '--/--'}))
    leftLayer:addChild(display.newImageView(RES_DICT.NUM_FRAME, collectLabel:getPositionX(), collectLabel:getPositionY()))
    leftLayer:addChild(collectLabel)
    

    -- shop button
    local shopBtn = display.newButton(albumBtn:getPositionX(), albumBtn:getPositionY() + 135, {n = RES_DICT.COMMON_BTN_N})
    display.commonLabelParams(shopBtn, fontWithColor(20, {fontSize = 26, outline = '#3b1010', text = __('牌店')}))
    shopBtn:addChild(display.newImageView(RES_DICT.SHOP_ICON, 20, utils.getLocalCenter(shopBtn).y))
    leftLayer:addChild(shopBtn)


    -- rule layer
    local ruleSize  = cc.size(320, 200)
    local ruleLayer = display.newImageView(RES_DICT.RULE_BG_FRAME, leftAxisX, display.cy - 15, {size = ruleSize, scale9 = true, ap = display.CENTER_BOTTOM, enable = true})
    leftLayer:addChild(ruleLayer)
    
    local ruleIntro = display.newLabel(ruleSize.width/2, ruleSize.height - 20, fontWithColor(15, {color = '#ffd9b1', text = __('今日规则')}))
    ruleLayer:addChild(ruleIntro)

    ruleLayer:addChild(display.newImageView(RES_DICT.RULE_CUTTING_LINE, ruleSize.width/2, ruleSize.height - 38, {size = cc.size(ruleSize.width - 30, 2), scale9 = true}))
    
    local ruleIconLayer = display.newLayer(0, 0, {size = cc.size(ruleSize.width, ruleSize.height - 40), color1 = cc.r4b(150)})
    ruleLayer:addChild(ruleIconLayer)


    ------------------------------------------------- [right]
    local rightAxisX = display.cx + 425
    local rightLayer = display.newLayer()
    view:addChild(rightLayer)

    local rightFrameSize  = cc.size(440, 640)
    local rightFrameLayer = display.newLayer(rightAxisX, display.cy - 35, {size = rightFrameSize, ap = display.CENTER, scale9 = true, bg = RES_DICT.RULE_BG_FRAME})
    rightLayer:addChild(rightFrameLayer)

    local reportBtn = display.newButton(rightFrameSize.width - 10, rightFrameSize.height - 18, {n = RES_DICT.REPORT_BTN, ap = display.RIGHT_CENTER})
    display.commonLabelParams(reportBtn, fontWithColor(14, {text = __('战报'), offset = cc.p(0,-3)}))
    rightFrameLayer:addChild(reportBtn)
    
    
    -- friend frame
    local friendFrameSize  = cc.size(396, 200)
    local friendFrameLayer = display.newLayer(rightFrameSize.width/2, rightFrameSize.height/2 + 45, {size = friendFrameSize, ap = display.CENTER_BOTTOM, scale9 = true, bg = RES_DICT.BATTLE_BG_FRAME})
    rightFrameLayer:addChild(friendFrameLayer)

    local friendTitleBar = display.newButton(friendFrameSize.width/2, friendFrameSize.height + 5, {n = RES_DICT.FRIEND_TITLE, ap = display.CENTER_TOP, enable = false})
    display.commonLabelParams(friendTitleBar, fontWithColor(20, {fontSize = 28, outline = '#b85242', text = __('好友切磋')}))
    friendTitleBar:addChild(display.newImageView(RES_DICT.FRIEND_ICON, 45, utils.getLocalCenter(friendTitleBar).y + 15))
    friendFrameLayer:addChild(friendTitleBar)

    local roomCreateBtn = display.newButton(friendFrameSize.width - 122, friendFrameSize.height/2 - 20, {n = RES_DICT.COMMON_BTN2_N, d = RES_DICT.COMMON_BTN2_D, scale9 = true, size = cc.size(218,130), capInsets = cc.rect(30,30,70,70)})
    display.commonLabelParams(roomCreateBtn, fontWithColor(20, {fontSize = 30, outline = '#80532d', text = __('创建')}))
    friendFrameLayer:addChild(roomCreateBtn)
    
    local roomFindBtn = display.newButton(85, roomCreateBtn:getPositionY() + 15, {n = RES_DICT.SEARCH_BTN_N})
    display.commonLabelParams(roomFindBtn, fontWithColor(12, {fontSize =19 ,  text = __('输入牌室号'), w = 180,ap = display.CENTER_BOTTOM, hAlign = display.TAC , offset = cc.p(0,-90)}))
    friendFrameLayer:addChild(roomFindBtn)


    -- pvp frame
    local pvpFrameSize  = cc.size(396, 304)
    local pvpFrameLayer = display.newLayer(rightFrameSize.width/2, rightFrameSize.height/2 + 10, {size = pvpFrameSize, ap = display.CENTER_TOP, scale9 = true, bg = RES_DICT.BATTLE_BG_FRAME})
    rightFrameLayer:addChild(pvpFrameLayer)

    local pvpTitleBar = display.newButton(pvpFrameSize.width/2, pvpFrameSize.height + 5, {n = RES_DICT.PVP_TITLE, ap = display.CENTER_TOP, enable = false})
    display.commonLabelParams(pvpTitleBar, fontWithColor(20, {fontSize = 28, outline = '#463951', text = __('在线对战')}))
    pvpTitleBar:addChild(display.newImageView(RES_DICT.PVP_ICON, 45, utils.getLocalCenter(pvpTitleBar).y + 15))
    pvpFrameLayer:addChild(pvpTitleBar)

    local pvpDateBtn = display.newButton(pvpFrameSize.width - 50, pvpFrameSize.height - 85, {n = RES_DICT.PVP_DATE_BTN_N})
    display.commonLabelParams(pvpDateBtn, fontWithColor(9, {text = __('排期'), offset = cc.p(0,-38)}))
    pvpFrameLayer:addChild(pvpDateBtn)
    
    local pvpBattleBtn = display.newButton(pvpFrameSize.width/2, 78, {n = RES_DICT.COMMON_BTN2_N, d = RES_DICT.COMMON_BTN2_D, scale9 = true, size = cc.size(368,130), capInsets = cc.rect(30,30,70,70)})
    pvpBattleBtn:getNormalImage():addChild(display.newLabel(utils.getLocalCenter(pvpBattleBtn).x, utils.getLocalCenter(pvpBattleBtn).y, fontWithColor(20, {fontSize = 30, outline = '#80532d', text = __('匹配')})))
    pvpBattleBtn:getSelectedImage():addChild(display.newLabel(utils.getLocalCenter(pvpBattleBtn).x, utils.getLocalCenter(pvpBattleBtn).y, fontWithColor(20, {fontSize = 30, outline = '#80532d', text = __('匹配')})))
    pvpBattleBtn:getDisabledImage():addChild(display.newLabel(utils.getLocalCenter(pvpBattleBtn).x, utils.getLocalCenter(pvpBattleBtn).y, fontWithColor(7, {fontSize = 30, w = 320 ,hAlign = display.TAC , text = __('不在开放时间')})))
    pvpFrameLayer:addChild(pvpBattleBtn)
    
    -- pvp time
    local pvpOnLayer  = display.newLayer()
    local pvpOffLayer = display.newLayer()
    pvpFrameLayer:addChild(pvpOffLayer)
    pvpFrameLayer:addChild(pvpOnLayer)

    local pvpTimeInfoPos = cc.p(150, pvpFrameSize.height - 100)
    pvpOnLayer:addChild(display.newImageView(RES_DICT.PVP_TIME_FRAME, 0, pvpFrameSize.height - 50, {ap = display.LEFT_TOP}))
    pvpOnLayer:addChild(display.newLabel(pvpTimeInfoPos.x, pvpTimeInfoPos.y + 20, fontWithColor(3, {color = '#FFFFFF', text = __('对战模式火热进行中！')})))
    pvpOffLayer:addChild(display.newLabel(pvpTimeInfoPos.x, pvpTimeInfoPos.y + 20, fontWithColor(5, {color = '#fbdfbc',w = 330 ,hAlign = display.TAC ,  text = __('距离下次对战开放')})))
    pvpOnLayer:addChild(display.newImageView(RES_DICT.SHOP_ICO_TIME_N, pvpTimeInfoPos.x - 100, pvpTimeInfoPos.y - 30))
    pvpFrameLayer:addChild(display.newImageView(RES_DICT.PVP_CUTTING_LINE, pvpTimeInfoPos.x, pvpTimeInfoPos.y - 10))

    local pvpOnTimeLabel  = display.newLabel(pvpTimeInfoPos.x - 70, pvpTimeInfoPos.y - 30, fontWithColor(3, {ap = display.LEFT_CENTER, color = '#ffd89c', text = '--/--/--'}))
    local pvpOffTimeLabel = display.newLabel(pvpTimeInfoPos.x - 70, pvpTimeInfoPos.y - 30, fontWithColor(3, {ap = display.LEFT_CENTER, color = '#ffffff', text = '--/--/--'}))
    pvpOnLayer:addChild(pvpOnTimeLabel)
    pvpOffLayer:addChild(pvpOffTimeLabel)


    return {
        view             = view,
        topLayer         = topLayer,
        topLayerHidePos  = cc.p(topLayer:getPositionX(), 100),
        topLayerShowPos  = cc.p(topLayer:getPosition()),
        titleBtn         = titleBtn,
        titleBtnHidePos  = cc.p(titleBtn:getPositionX(), titleBtn:getPositionY() + 190),
        titleBtnShowPos  = cc.p(titleBtn:getPosition()),
        backBtn          = backBtn,
        guideBtn         = guideBtn,
        moneyLayer       = moneyLayer,
        --               = left
        leftLayer        = leftLayer,
        ruleLayer        = ruleLayer,
        ruleIconLayer    = ruleIconLayer,
        albumBtn         = albumBtn,
        shopBtn          = shopBtn,
        collectLabel     = collectLabel,
        --               = right
        rightLayer       = rightLayer,
        reportBtn        = reportBtn,
        roomFindBtn      = roomFindBtn,
        roomCreateBtn    = roomCreateBtn,
        pvpOnLayer       = pvpOnLayer,
        pvpOffLayer      = pvpOffLayer,
        pvpDateBtn       = pvpDateBtn,
        pvpBattleBtn     = pvpBattleBtn,
        pvpOnTimeLabel   = pvpOnTimeLabel,
        pvpOffTimeLabel  = pvpOffTimeLabel,
        --               = center
        centerLayer      = centerLayer,
        pveOnLayer       = pveOnLayer,
        pveOffLayer      = pveOffLayer,
        pveTimeLabel     = pveTimeLabel,
        pveEnterLayer    = pveEnterLayer,
        pveEnterImgLayer = pveEnterImgLayer,
    }
end


function TTGameHomeScene:getViewData()
    return self.viewData_
end


function TTGameHomeScene:updateMoneyBar()
    for _, moneyNode in ipairs(self:getViewData().moneyLayer:getChildren()) do
        local moneyId = checkint(moneyNode:getName())
        moneyNode:updataUi(moneyId)
    end
end


function TTGameHomeScene:updateRuleList(ruleList)
    local ruleIconLayer = self:getViewData().ruleIconLayer
    ruleIconLayer:removeAllChildren()
    local ruleIdList      = checktable(ruleList)
    local iconLayerSize   = ruleIconLayer:getContentSize()
    local RULE_NODE_COLS  = 3
    local RULE_NODE_ROWS  = math.ceil(#ruleIdList / RULE_NODE_COLS)
    local RULE_NODE_SIZE  = cc.size(72, 76)
    local RULE_NODE_GAP_H = (iconLayerSize.height - RULE_NODE_ROWS * RULE_NODE_SIZE.height) / 2
    for index, ruleId in ipairs(ruleIdList) do
        local colNum   = (index - 1) % RULE_NODE_COLS + 1
        local rowNum   = math.ceil(index / RULE_NODE_COLS)
        local colMax   = math.min(#ruleIdList - (rowNum-1) * RULE_NODE_COLS, RULE_NODE_COLS)
        local offsetX  = iconLayerSize.width/2 - (colMax-1) * RULE_NODE_SIZE.width/2
        local ruleNode = TTGameUtils.GetRuleIconNode(ruleId)
        ruleNode:setPositionX(offsetX + (colNum-1) * RULE_NODE_SIZE.width)
        ruleNode:setPositionY(RULE_NODE_GAP_H + (RULE_NODE_ROWS - rowNum + 0.5) * RULE_NODE_SIZE.height)
        ruleIconLayer:addChild(ruleNode)
    end
end


function TTGameHomeScene:updatePveSwitchStatus(isSwitchOn)
    local isOpening = isSwitchOn == true
    self:getViewData().pveOnLayer:setVisible(isOpening)
    self:getViewData().pveOffLayer:setVisible(not isOpening)
end


function TTGameHomeScene:updatePveLeftSeconds(seconds)
    local leftSeconds = checkint(seconds)
    local timeString = leftSeconds >= 0 and CommonUtils.getTimeFormatByType(leftSeconds, 3) or '--:--:--'
    display.commonLabelParams(self:getViewData().pveTimeLabel, {text = timeString})
end


function TTGameHomeScene:updatePveEnterImage(imageId)
    local enterImgPath = _res(string.fmt('ui/ttgame/arts/pveEnter/cardgame_main_pve_bg_%1.jpg', checkint(imageId)))
    self:getViewData().pveEnterImgLayer:removeAllChildren()
    self:getViewData().pveEnterImgLayer:addChild(display.newImageView(enterImgPath))
end


function TTGameHomeScene:updatePvpSwitchStatus(isSwitchOn)
    local isOpening = isSwitchOn == true
    self:getViewData().pvpOnLayer:setVisible(isOpening)
    self:getViewData().pvpOffLayer:setVisible(not isOpening)
    self:getViewData().pvpBattleBtn:setEnabled(isOpening)
end


function TTGameHomeScene:updatePvpLeftSeconds(seconds)
    local leftSeconds = checkint(seconds)
    local timeString = leftSeconds >= 0 and CommonUtils.getTimeFormatByType(leftSeconds, 3) or '--:--:--'
    display.commonLabelParams(self:getViewData().pvpOffTimeLabel, {text = timeString})
    display.commonLabelParams(self:getViewData().pvpOnTimeLabel, {text = timeString})
end


function TTGameHomeScene:updateBattleCardNum(current, total)
    display.commonLabelParams(self:getViewData().collectLabel, {text = string.fmt('%1 / %2', tostring(current), tostring(total))})
end


return TTGameHomeScene

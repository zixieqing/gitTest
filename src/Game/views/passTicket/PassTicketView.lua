--[[
 * descpt : pass ticket 界面
]]
local VIEW_SIZE = display.size
---@class PassTicketView :CLayout
local PassTicketView = class("PassTicketView", function ()
	local node = CLayout:create(VIEW_SIZE)
	node.name = 'passTicket.PassTicketView'
	node:enableNodeEvents()
	return node
end)

local CreateView = nil

local RES_DICT = {
    GOODS_ICON_900024               = _res('arts/goods/goods_icon_900024.png'),
    COMMON_BTN_ORANGE               = _res('ui/common/common_btn_orange.png'),
    ACTIVITY_DIARY_BTN_LOCK         = _res('ui/common/activity_diary_btn_lock.png'),
    ACTIVITY_MIFAN_BY_ICO           = _res('ui/common/activity_mifan_by_ico.png'),
    COMMON_BTN_TIPS                 = _res('ui/common/common_btn_tips.png'),
    COMMON_ICO_LOCK                 = _res('ui/common/common_ico_lock.png'),
    COMMON_LIGHT                    = _res('ui/common/common_light.png'),
    -- COMMON_BG_GOODS                 = _res('ui/common/common_bg_goods.png'),
    ACTIVITY_DIARY_LEVEL_BG_LOCK    = _res('ui/home/activity/passTicket/activity_diary_level_bg_lock.png'),
    ACTIVITY_DIARY_BG_GOODS         = _res('ui/home/activity/passTicket/activity_diary_bg_goods.png'),
    ACTIVITY_DIARY_BG_LOCK          = _res('ui/home/activity/passTicket/activity_diary_bg_lock.png'),
    ACTIVITY_DIARY_BTN_RECHARGE     = _res('ui/home/activity/passTicket/activity_diary_btn_recharge.png'),
    ACTIVITY_DIARY_TAB_RECHARGE_GET = _res('ui/home/activity/passTicket/activity_diary_tab_recharge_get.png'),
    ACTIVITY_DIARY_CARD             = _res('ui/home/activity/passTicket/activity_diary_card.png'),
    ACTIVITY_DIARY_CHEST_BG         = _res('ui/home/activity/passTicket/activity_diary_chest_bg.png'),
    ACTIVITY_DIARY_CHEST_MONEY_BG   = _res('ui/home/activity/passTicket/activity_diary_chest_money_bg.png'),
    ACTIVITY_DIARY_FARME_ASH        = _res('ui/home/activity/passTicket/activity_diary_farme_ash.png'),
    ACTIVITY_DIARY_LEVEL_BG         = _res('ui/home/activity/passTicket/activity_diary_level_bg.png'),
    ACTIVITY_DIARY_MAIN_BG          = _res('ui/home/activity/passTicket/activity_diary_main_bg.png'),
    ACTIVITY_DIARY_TAB              = _res('ui/home/activity/passTicket/activity_diary_tab.png'),
    ACTIVITY_DIARY_TIPS_SALE        = _res('ui/home/activity/passTicket/activity_diary_tips_sale.png'),
    ACTIVITY_DIARY_TITLE_WORDS      = _res('ui/home/activity/passTicket/activity_diary_title_words.png'),
    ACTIVITY_DIARY_BOUNS            = _res('ui/home/activity/passTicket/activity_diary_bouns.png'),
    ACTIVITY_DIARY_REWORD_BG        = _res('ui/home/activity/passTicket/activity_diary_reword_bg.png'),
    ACTIVITY_DIARY_TIME_BG          = _res('ui/home/activity/passTicket/activity_diary_time_bg.png'),
    PET_PROMOTE_BG_LOADING          = _res('ui/pet/pet_promote_bg_loading.png'),
    SHOP_RECHARGE_LIGHT_RED         = _res('ui/home/commonShop/shop_recharge_light_red.png'),
    ALLROUND_BG_BAR_ACTIVE          = _res('ui/home/allround/allround_bg_bar_active.png'),
    ALLROUND_BG_BAR_GREY            = _res('ui/home/allround/allround_bg_bar_grey.png'),

    SPINE_CJJL_KUANG                = _spn('ui/home/activity/passTicket/spine/cjjl_kuang'),
    SPINE_CJJL_LINGHUOZHONG         = _spn('ui/home/activity/passTicket/spine/cjjl_linghuozhong'),
    SPINE_CJJL                      = _spn('ui/home/activity/passTicket/spine/cjjl'),
}


function PassTicketView:ctor( ... ) 
    
    self.args = unpack({...})
    self:initialUI()
end

function PassTicketView:initialUI()
    xTry(function ( )
        self.viewData_ = CreateView()
        self:addChild(self.viewData_.view)
	end, __G__TRACKBACK__)
end

function PassTicketView:refreshUI(homeData)
    local viewData  = self:getViewData()
    local curLevel  = checkint(homeData.curLevel)
    local curLvExp  = checkint(homeData.curLvExp)
    local isMaxLv   = curLevel <= 0
    local levelList = homeData.level or {}

    self:updateTableView(viewData, levelList)
    self:updateLevel(viewData, curLevel, isMaxLv)
    self:updateLevelProgress(viewData, isMaxLv, curLvExp, homeData.lvMaxExp)
    self:updateOverflowConsume(viewData, homeData.overflowCircle)
    self:updatePassTickePurchaseState(viewData, homeData.hasPurchasePassTicket)
    self:updateOneKeyDrawBtnShowState(viewData, levelList, curLevel, homeData.hasPurchasePassTicket)
end

function PassTicketView:updateTableView(viewData, levelList)
    local tableView = viewData.tableView
    tableView:setCountOfCell(#levelList)
    tableView:reloadData()
end

function PassTicketView:updateLevel(viewData, lv, isMaxLv)
    local maxLvTipLabel = viewData.maxLvTipLabel
    maxLvTipLabel:setVisible(isMaxLv)
    
    local lvBg = viewData.lvBg
    lvBg:setTexture(isMaxLv and RES_DICT.ACTIVITY_DIARY_LEVEL_BG_LOCK or RES_DICT.ACTIVITY_DIARY_LEVEL_BG)

    local lvLabel = viewData.lvLabel
    if isMaxLv then
        local levelConf = app.passTicketMgr:GetLevelConf(app.passTicketMgr:GetPassTicketId())
        local maxLv = 0
        for i, v in orderedPairs(levelConf) do
            maxLv = math.max( maxLv, checkint(v.level) )
        end
        display.commonLabelParams(lvLabel, {text = maxLv})
        local lvLabelSize = display.getLabelContentSize(lvLabel)
        local maxLvTipLabelSize = display.getLabelContentSize(maxLvTipLabel)

        lvLabel:setPositionX(85 - maxLvTipLabelSize.width / 2)
        maxLvTipLabel:setPositionX(85 + lvLabelSize.width / 2)
    else
        display.commonLabelParams(lvLabel, {text = checkint(lv) - 1})
    end
    
end

function PassTicketView:updateLevelProgress(viewData, isMaxLv, curLvExp, lvMaxExp)
    local loadingBar       = viewData.loadingBar
    local overflowNumLabel = viewData.overflowNumLabel
    local titleIcon        = viewData.titleIcon

    overflowNumLabel:setVisible(isMaxLv)
    loadingBar:setVisible(not isMaxLv)
    local titleIconPosX = 0
    if isMaxLv then
        titleIconPosX = overflowNumLabel:getPositionX() + 35
        display.commonLabelParams(overflowNumLabel, {text = tostring(curLvExp)})
    else
        titleIconPosX = 40
        loadingBar:setMaxValue(checkint(lvMaxExp))
        loadingBar:setValue(checkint(curLvExp))
        -- display.commonLabelParams(loadingBar:getLabel(), {text = string.format("%s/%s", tostring(curLvExp), tostring(lvMaxExp))})
    end
    titleIcon:setPositionX(titleIconPosX)
end

function PassTicketView:updateOverflowConsume(viewData, overflowCircle)
    local numLabel = viewData.numLabel
    display.commonLabelParams(numLabel, {text = tostring(overflowCircle)})

    local goodsIcon = viewData.goodsIcon
    local numLabelSize = display.getLabelContentSize(numLabel)
    local goodsIconSize = goodsIcon:getContentSize()
    numLabel:setPositionX(66 - goodsIconSize.width / 2 * goodsIcon:getScale())
    goodsIcon:setPositionX(66 + numLabelSize.width / 2)
end

function PassTicketView:updatePassTickePurchaseState(viewData, hasPurchasePassTicket)
    local bounsShadowBg = viewData.bounsShadowBg
    local isPurchase = checkint(hasPurchasePassTicket) > 0 
    bounsShadowBg:setVisible(not isPurchase)

    local superRewardTitle      = viewData.superRewardTitle
    local superRewardTitleLabel = viewData.superRewardTitleLabel
    local superTipLabel         = viewData.superTipLabel
    local superRewardFrameSpine = viewData.superRewardFrameSpine

    local superRewardTitleSize = superRewardTitle:getContentSize()
    superTipLabel:setVisible(not isPurchase)
    superRewardFrameSpine:setVisible(not isPurchase)
    local img = nil
    if isPurchase then
        img = RES_DICT.ACTIVITY_DIARY_TAB_RECHARGE_GET
        superRewardTitleLabel:setPosition(cc.p(superRewardTitleSize.width / 2, superRewardTitleSize.height / 2))
    else
        img = RES_DICT.ACTIVITY_DIARY_BTN_RECHARGE
        superRewardTitleLabel:setPosition(cc.p(superRewardTitleSize.width / 2, superRewardTitleSize.height / 2 + 12))
    end
    superRewardTitle:setNormalImage(img)
    superRewardTitle:setSelectedImage(img)
    superRewardTitleLabel:setVisible(true)
end

function PassTicketView:updateOneKeyDrawBtnShowState(viewData, levelList, curLevel, hasPurchasePassTicket)
    local state = 0
    local isHasPurchasePassTicket = checkint(hasPurchasePassTicket) > 0
    for i, levelData in ipairs(levelList) do
        local hasDrawn = checkint(levelData.hasDrawn)
        local isOwnSuperRewards = next(levelData.additionalRewards or {}) ~= nil
        -- 没有领取过 或者 
        local levelCondition = (curLevel == 0 or curLevel > checkint(levelData.level))
        local drawnCondition = (hasDrawn <= 0 or (isHasPurchasePassTicket and hasDrawn == 1 and isOwnSuperRewards))
        if levelCondition and drawnCondition then
            state = 1
            break
        end
    end

    local oneKeyDrawBtn = viewData.oneKeyDrawBtn

    local img = state > 0 and RES_DICT.COMMON_BTN_ORANGE or RES_DICT.ACTIVITY_DIARY_BTN_LOCK
    oneKeyDrawBtn:setNormalImage(img)
    oneKeyDrawBtn:setSelectedImage(img)
    oneKeyDrawBtn:setTag(state)
end

function PassTicketView:updateActTimeLabel(viewData, seconds)
    local viewData = self:getViewData()
    if viewData and viewData.actTimeLabel then
        display.commonLabelParams(viewData.actTimeLabel, {text = CommonUtils.getTimeFormatByType(seconds)})
    end
end

function PassTicketView:updateCardImg(cardId)
    if cardId then
        self:getViewData().cardImg:setVisible(true)
        local path = string.format( "ui/home/activity/passTicket/activity_diary_card_%s.png", cardId)
        if not utils.isExistent(path) then
            path = RES_DICT.ACTIVITY_DIARY_CARD
        end
        self:getViewData().cardImg:setTexture(_res(path))
    else
        self:getViewData().cardImg:setVisible(false)
    end
end

------------------------------------------------
-- update cell
function PassTicketView:updateCell(cell, data, curLevel, hasPurchasePassTicket)
    display.commonLabelParams(cell.cellLv, {text = tostring(data.level)})
    
    cell:updateBaseReward(data)
    cell:updateAdditionalReward(data.additionalRewards or {})
    self:updateCellDrawBtn(cell, data, curLevel, hasPurchasePassTicket)
end

function PassTicketView:updateCellDrawBtn(cell, data, curLevel, hasPurchasePassTicket)
    local hasDrawn  = checkint(data.hasDrawn)
    local level     = checkint(data.level)
    local drawBtn   = cell.drawBtn
    local numLabel  = cell.numLabel
    local goodsIcon = cell.goodsIcon
    local receivedLabel = cell.receivedLabel
    local drawBtnLabel = drawBtn:getLabel()
    local img = nil
    local enable = true
    local text = nil

    numLabel:setVisible(false)
    goodsIcon:setVisible(false)
    receivedLabel:setVisible(false)
    drawBtnLabel:setVisible(false)

    local btnSpine = cell.btnSpine
    if btnSpine then
        btnSpine:setVisible(false)
    end

    -- 显示已领取状态条件： 基础和pass卡奖励都领过 或者 只有基础奖励领过并且 (没pass卡 或者 有pass卡但是没有pass卡奖励)
    if (hasDrawn > 1) or (hasDrawn == 1 and (hasPurchasePassTicket == 0 or (hasPurchasePassTicket > 0 and (next(data.additionalRewards or {}) == nil))) ) then
        enable = false
        img = RES_DICT.ACTIVITY_MIFAN_BY_ICO
        receivedLabel:setVisible(true)
    elseif level == curLevel then
        img = RES_DICT.COMMON_BTN_ORANGE
        
        local skipConsume = CommonUtils.GetCapsuleConsume( data.skipConsume or {} )
        display.commonLabelParams(numLabel, {text = tostring(skipConsume.num)})
        goodsIcon:setTexture(CommonUtils.GetGoodsIconPathById(skipConsume.goodsId))
        local centerPosX = drawBtn:getContentSize().width / 2
        numLabel:setPositionX(centerPosX - goodsIcon:getContentSize().width / 2 * goodsIcon:getScale())
        goodsIcon:setPositionX(centerPosX + display.getLabelContentSize(numLabel).width / 2)

        numLabel:setVisible(true)
        goodsIcon:setVisible(true)

        if btnSpine == nil then
            local btnSpine = sp.SkeletonAnimation:create(RES_DICT.SPINE_CJJL_LINGHUOZHONG.json, RES_DICT.SPINE_CJJL_LINGHUOZHONG.atlas, 1)
            btnSpine:update(0)
            btnSpine:addAnimation(0, 'idle', true)
            btnSpine:setPosition(utils.getLocalCenter(drawBtn))
            drawBtn:addChild(btnSpine, 5)
            cell.btnSpine = btnSpine
        else
            btnSpine:setVisible(true)
        end

    elseif curLevel == 0 or level < curLevel then
        img = RES_DICT.COMMON_BTN_ORANGE
        text = __('领取')
    else
        img = RES_DICT.ACTIVITY_DIARY_BTN_LOCK
        text = __('领取')
    end

    drawBtnLabel:setVisible(text ~= nil)
    if text then
        display.commonLabelParams(drawBtn, {text = text})
    end
    drawBtn:setTouchEnabled(enable)
    drawBtn:setNormalImage(img)
    drawBtn:setSelectedImage(img)
end
-- update cell
------------------------------------------------

CreateView = function ()
    local view = display.newLayer()
    local size = view:getContentSize()

    local shadowLayer = display.newLayer(0, 0, {color = cc.c4b(0, 0, 0, 150), enable = true})
    view:addChild(shadowLayer)

    local cardImg = display.newNSprite(RES_DICT.ACTIVITY_DIARY_CARD, display.cx, display.cy,
    {
        ap = display.CENTER,
    })
    view:addChild(cardImg)
    cardImg:setVisible(false)

    local lightImg = display.newNSprite(RES_DICT.COMMON_LIGHT, display.cx - 448, display.cy - 102)
    lightImg:setScale(0.6)
    view:addChild(lightImg)

    local diaryTitleWordsImg = display.newNSprite(RES_DICT.ACTIVITY_DIARY_TITLE_WORDS, display.cx - 448, display.cy - 102,
    {
        ap = display.CENTER,
    })
    view:addChild(diaryTitleWordsImg)

    ------------------mainView start------------------
    local mainViewSize = cc.size(668, 704)
    local mainView = display.newLayer(display.cx + 120, display.cy - 19,
    {
        ap = display.CENTER,
        size = mainViewSize,
    })
    view:addChild(mainView)

    mainView:addChild(display.newLayer(0, 0, { ap = display.LEFT_BOTTOM, size = mainViewSize, enable = true, color = cc.c4b(0,0,0,0)}))

    local mainBg = display.newNSprite(RES_DICT.ACTIVITY_DIARY_MAIN_BG, mainViewSize.width / 2, mainViewSize.height / 2,
    {
        ap = display.CENTER,
    })
    mainView:addChild(mainBg)

    ------------------lvBg start------------------
    local lvBg = display.newNSprite(RES_DICT.ACTIVITY_DIARY_LEVEL_BG, 30, mainViewSize.height - 100,
    {
        ap = display.LEFT_CENTER,
    })
    mainView:addChild(lvBg)

    local lvTextLabel = display.newLabel(85, 96, fontWithColor(16, {text = __('等级'), ap = display.CENTER}))
    lvBg:addChild(lvTextLabel)

    local lvLabel = display.newLabel(85, 32, fontWithColor(7, {ap = display.CENTER, fontSize = 30, color = '#ba561a'}))
    lvBg:addChild(lvLabel)

    local maxLvTipLabel = display.newLabel(85, 32, fontWithColor(7, {ap = display.CENTER, text = __('已满'), fontSize = 22, color = '#ba561a'}))
    maxLvTipLabel:setVisible(false)
    lvBg:addChild(maxLvTipLabel)
    ------------------lvBg end------------------
    
    local spineView = display.newLayer(display.cx + 120, display.cy - 19,
    {
        ap = display.CENTER,
        size = mainViewSize,
    })
    view:addChild(spineView)

    
    ------------------experienceLayer start------------------
    local experienceLayerSize = cc.size(298, 128)
    local experienceLayer = display.newLayer(205, lvBg:getPositionY(), {ap = display.LEFT_CENTER, size = experienceLayerSize})
    mainView:addChild(experienceLayer)

    experienceLayer:addChild( display.newNSprite(RES_DICT.ACTIVITY_DIARY_LEVEL_BG, experienceLayerSize.width / 2, experienceLayerSize.height / 2, {scale9 = true, size = experienceLayerSize, ap = display.CENTER}) )

    local expTextLabel = display.newLabel(experienceLayerSize.width / 2, 96, fontWithColor(16, {text = __('阅历经验'), ap = display.CENTER}))
    experienceLayer:addChild(expTextLabel)

    local titleIcon = display.newNSprite(RES_DICT.GOODS_ICON_900024, 40, 32,
    {
        ap = display.CENTER,
    })
    titleIcon:setScale(0.3)
    experienceLayer:addChild(titleIcon)

    local loadingBar = CProgressBar:create(RES_DICT.ALLROUND_BG_BAR_ACTIVE)
    loadingBar:setBackgroundImage(RES_DICT.ALLROUND_BG_BAR_GREY)
    loadingBar:setAnchorPoint(display.LEFT_CENTER)
    loadingBar:setMaxValue(100)
    loadingBar:setValue(0)
    loadingBar:setDirection(eProgressBarDirectionLeftToRight)
    loadingBar:setPosition(cc.p(70, 32))
    loadingBar:setShowValueLabel(true)
    display.commonLabelParams(loadingBar:getLabel(), fontWithColor(18))
    experienceLayer:addChild(loadingBar)

    local overflowNumLabel = display.newLabel(experienceLayerSize.width / 2 + 20, titleIcon:getPositionY(), fontWithColor(7, {ap = display.RIGHT_CENTER, fontSize = 30, color = '#ba561a'}))
    experienceLayer:addChild(overflowNumLabel)
    overflowNumLabel:setVisible(false)
    ------------------experienceLayer end ------------------

    --------------overflowBtn start--------------
    local overflowBtnSize = cc.size(132, 131)
    local overflowBtn = display.newButton(mainViewSize.width - 92, lvBg:getPositionY(),
    {
        ap = display.CENTER,
        n = RES_DICT.ACTIVITY_DIARY_CHEST_BG,
        scale9 = true, size = overflowBtnSize
    })
    mainView:addChild(overflowBtn)
    -- logInfo.add(5, tableToString(overflowBtn:getContentSize()))
    -- 
    local lightImage = display.newNSprite(RES_DICT.SHOP_RECHARGE_LIGHT_RED, overflowBtnSize.width / 2, overflowBtnSize.height / 2)
    lightImage:setScale(0.8)
    overflowBtn:addChild(lightImage)

    local boxImg = display.newNSprite(CommonUtils.GetGoodsIconPathById(701024), overflowBtnSize.width / 2, overflowBtnSize.width / 2 + 8)
    boxImg:setScale(0.8)
    overflowBtn:addChild(boxImg)

    overflowBtn:addChild(display.newNSprite(RES_DICT.ACTIVITY_DIARY_CHEST_MONEY_BG, overflowBtnSize.width / 2, 17, {ap = display.CENTER}))

    local numLabel = display.newLabel(overflowBtnSize.width / 2, 17, fontWithColor(18, {ap = display.CENTER}))
    overflowBtn:addChild(numLabel)

    local goodsIcon = display.newNSprite(RES_DICT.GOODS_ICON_900024, overflowBtnSize.width / 2, 17,
    {
        ap = display.CENTER,
    })
    goodsIcon:setScale(0.2)
    overflowBtn:addChild(goodsIcon)

    ---------------overflowBtn end---------------

    local tipsImg = display.newButton(67, mainViewSize.height - 204,
    {
        n = RES_DICT.COMMON_BTN_TIPS, 
        ap = display.CENTER,
    })
    mainView:addChild(tipsImg)

    local descrViewSize  = cc.size(525, 58)
	local descrContainer = cc.ScrollView:create()
    descrContainer:setPosition(cc.p(tipsImg:getPositionX() + 30, mainViewSize.height - 235))
	descrContainer:setDirection(eScrollViewDirectionVertical)
	descrContainer:setAnchorPoint(display.LEFT_BOTTOM)
    descrContainer:setViewSize(descrViewSize)
    mainView:addChild(descrContainer)

    local moduleExplainConf = checktable(CommonUtils.GetConfigAllMess('moduleExplain'))['-24'] or {}
    local ruleLabel = display.newLabel(0, 0, fontWithColor(16, {fontSize = 20, w = descrViewSize.width, text = tostring(moduleExplainConf.descr)}))
    descrContainer:setContainer(ruleLabel)
    local descrScrollTop = descrViewSize.height - display.getLabelContentSize(ruleLabel).height
	descrContainer:setContentOffset(cc.p(0, descrScrollTop))

    local lvTitle = display.newButton(27, mainViewSize.height - 275,
    {
        ap = display.LEFT_CENTER,
        n = RES_DICT.ACTIVITY_DIARY_TAB,
        scale9 = true, size = cc.size(85, 62),
        enable = false,
    })
    display.commonLabelParams(lvTitle, fontWithColor(18, {text = __('等级')}))
    lvTitle:setOpacity(255 * 0.75)
    mainView:addChild(lvTitle)

    local rewardTitle = display.newButton(lvTitle:getPositionX() + 88.5 , lvTitle:getPositionY(),
    {
        ap = display.LEFT_CENTER,
        n = RES_DICT.ACTIVITY_DIARY_TAB,
        scale9 = true, size = cc.size(108, 62),
        enable = false,
    })
    display.commonLabelParams(rewardTitle, fontWithColor(18, {text = __('奖励')}))
    rewardTitle:setOpacity(255 * 0.75)
    mainView:addChild(rewardTitle)


    local bounsImg = display.newNSprite(RES_DICT.ACTIVITY_DIARY_BOUNS, rewardTitle:getPositionX() + 241, lvTitle:getPositionY() + 50, {ap = display.CENTER_TOP})
    mainView:addChild(bounsImg, 1)
    -- bounsImg:setVisible(false)

    local spine = sp.SkeletonAnimation:create(RES_DICT.SPINE_CJJL_KUANG.json, RES_DICT.SPINE_CJJL_KUANG.atlas, 1)
    spine:update(0)
    spine:addAnimation(0, 'idle', true)
    spine:setPosition(utils.getLocalCenter(bounsImg))
    bounsImg:addChild(spine, 5)

    local bounsShadowBg = display.newNSprite(RES_DICT.ACTIVITY_DIARY_BG_LOCK, 146, 383, {ap = display.CENTER_TOP})
    bounsImg:addChild(bounsShadowBg)

    local lockIcon = display.newNSprite(RES_DICT.COMMON_ICO_LOCK, 60, 218,
    {
        ap = display.CENTER,
    })
    bounsShadowBg:addChild(lockIcon)

    local lockTipsLabel = display.newLabel(lockIcon:getPositionX() + 25, lockIcon:getPositionY() - 5, fontWithColor(14, {
        text = __('当前未解除'),
        ap = display.LEFT_CENTER,
        fontSize = 22,
        outline = '#5b3c25', outlineSize = 1
    }))
    bounsShadowBg:addChild(lockTipsLabel)

    --------------superRewardTitle start--------------
    local superRewardTitle = display.newButton(rewardTitle:getPositionX() + 113, lvTitle:getPositionY(),
    {
        ap = display.LEFT_CENTER,
        n = RES_DICT.ACTIVITY_DIARY_BTN_RECHARGE,
        scale9 = true, size = cc.size(254, 62),
        enable = true,
    })
    local superRewardTitleLabel = superRewardTitle:getLabel()
    display.commonLabelParams(superRewardTitleLabel, fontWithColor(16, {text = __('超级奖励')}))
    superRewardTitleLabel:setVisible(false)
    mainView:addChild(superRewardTitle, 1)

    local superRewardFrameSpine = sp.SkeletonAnimation:create(RES_DICT.SPINE_CJJL.json, RES_DICT.SPINE_CJJL.atlas, 1)
    superRewardFrameSpine:update(0)
    superRewardFrameSpine:addAnimation(0, 'idle', true)
    superRewardFrameSpine:setPosition(utils.getLocalCenter(superRewardTitle))
    superRewardTitle:addChild(superRewardFrameSpine, 5)
    superRewardFrameSpine:setVisible(false)

    local superTipLabel = display.newLabel(126, 19, fontWithColor(20, {
        text = __('解除封印'),
        ap = display.CENTER,
        fontSize = 21,
        color = '#ffdf70',
        outline = '#9b2400', outlineSize = 2
    }))
    superTipLabel:setVisible(false)
    superRewardTitle:addChild(superTipLabel)

    ---------------superRewardTitle end---------------

    local stateTitle = display.newButton(superRewardTitle:getPositionX() + 260, lvTitle:getPositionY(),
    {
        ap = display.LEFT_CENTER,
        n = RES_DICT.ACTIVITY_DIARY_TAB,
        scale9 = true, size = cc.size(152, 62),
        enable = false,
    })
    display.commonLabelParams(stateTitle, fontWithColor(18, {text = __('状态')}))
    mainView:addChild(stateTitle)
    stateTitle:setOpacity(255 * 0.75)

    local listBgSize = cc.size(625, 360)
    local listBg = display.newNSprite(RES_DICT.ACTIVITY_DIARY_BG_GOODS, mainViewSize.width / 2, 400, {scale9 = true, size = listBgSize, ap = display.CENTER_TOP})
    mainView:addChild(listBg)

    local tableView = CTableView:create(cc.size(listBgSize.width, listBgSize.height - 62))
    display.commonUIParams(tableView, {po = cc.p(listBg:getPositionX(), listBg:getPositionY()), ap = display.CENTER_TOP})
    tableView:setDirection(eScrollViewDirectionVertical)
    tableView:setSizeOfCell(cc.size(620, 104))
    mainView:addChild(tableView)

    -- 
    local timebgLayerSize = cc.size(634, 87)
    local timebgLayer = display.newLayer(mainViewSize.width / 2, 28, {ap = display.CENTER_BOTTOM, size = timebgLayerSize})
    mainView:addChild(timebgLayer, 1)

    local timebg = display.newNSprite(RES_DICT.ACTIVITY_DIARY_TIME_BG, timebgLayerSize.width / 2, 0, {ap = display.CENTER_BOTTOM})
    timebgLayer:addChild(timebg)

    local actEndTipsLabel = display.newLabel(22, 52, fontWithColor(16, {
        text = __('活动剩余时间:'),
        ap = display.LEFT_CENTER,
    }))
    timebgLayer:addChild(actEndTipsLabel)

    local actTimeLabel = display.newLabel(22, 30,
    {
        ap = display.LEFT_CENTER,
        fontSize = 22,
        color = '#d05817',
    })
    timebgLayer:addChild(actTimeLabel)

    local oneKeyDrawBtn = display.newButton(559, 40,
    {
        ap = display.CENTER,
        n = RES_DICT.COMMON_BTN_ORANGE,
        scale9 = true, size = cc.size(123, 62),
        enable = true,
    })
    display.commonLabelParams(oneKeyDrawBtn, fontWithColor(14, {text = __('一键领取')}))
    oneKeyDrawBtn:setScale(0.9)
    timebgLayer:addChild(oneKeyDrawBtn)

    -------------------mainView end-------------------
    --------------------view end--------------------
    return {
        view                    = view,
        shadowLayer             = shadowLayer,
        cardImg                 = cardImg,
        diaryTitleWordsImg      = diaryTitleWordsImg,
        mainView                = mainView,
        mainBg                  = mainBg,
        lvBg                    = lvBg,
        lvTextLabel             = lvTextLabel,
        lvLabel                 = lvLabel,
        maxLvTipLabel           = maxLvTipLabel,
        expTextLabel            = expTextLabel,
        loadingBar              = loadingBar,
        overflowNumLabel        = overflowNumLabel,
        titleIcon               = titleIcon,
        overflowBtn             = overflowBtn,
        numLabel                = numLabel,
        goodsIcon               = goodsIcon,
        tipsImg                 = tipsImg,
        ruleLabel               = ruleLabel,
        lvTitle                 = lvTitle,
        rewardTitle             = rewardTitle,
        stateTitle              = stateTitle,
        superRewardTitle        = superRewardTitle,
        superRewardTitleLabel   = superRewardTitleLabel,
        superRewardFrameSpine   = superRewardFrameSpine,
        superTipLabel           = superTipLabel,
        tableView               = tableView,
        bounsShadowBg           = bounsShadowBg,
        lockIcon                = lockIcon,
        lockTipsLabel           = lockTipsLabel,
        actEndTipsLabel         = actEndTipsLabel,
        actTimeLabel            = actTimeLabel,
        oneKeyDrawBtn           = oneKeyDrawBtn,
    }
end


function PassTicketView:getViewData()
	return self.viewData_
end

return PassTicketView
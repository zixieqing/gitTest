--[[
 * author : kaishiqi
 * descpt : 打牌游戏 - 基础房间视图
]]
local TTGameBaseRoomView = class('TripleTriadGameRoomBaseView', function()
    return display.newLayer(0, 0, {name = 'TripleTriadGameRoomBaseView'})
end)

local RES_DICT = {
    BG_IMAGE          = _res('arts/stage/bg/main_bg_69.jpg'),
    COM_BACK_BTN      = _res('ui/common/common_btn_back.png'),
    --                = rule
    COM_TIPS_ICON     = _res('ui/common/common_btn_tips.png'),
    RULE_BG_FRAME     = _res('ui/ttgame/common/cardgame_common_bg_1.png'),
    RULE_CUTTING_LINE = _res('ui/ttgame/common/cardgame_common_line_1.png'),
    RULE_PVE_FRAME    = _res('ui/ttgame/common/cardgame_common_label_kingsrule.png'),
    --                = right
    RIGHT_BG_FRAME    = _res('ui/ttgame/room/cardgame_prepare_bg_deck.png'),
    RIGHT_DECK_FRAME  = _res('ui/ttgame/room/cardgame_prepare_bg_deck_edit.png'),
    DECK_ADD_ICON     = _res('ui/common/maps_fight_btn_pet_add.png'),
    DECK_TAB_S        = _res('ui/ttgame/room/cardgame_prepare_tab_active.png'),
    DECK_TAB_N        = _res('ui/ttgame/room/cardgame_prepare_tab_default.png'),
    START_BTN_D       = _res('ui/ttgame/room/cardgame_prepare_btn_fight_disable.png'),
    START_BTN_N       = _res('ui/ttgame/room/cardgame_prepare_btn_fight.png'),
    START_NAME_BAR    = _res('ui/ttgame/room/cardgame_prepare_label_fight.png'),
    --                = rewards
    TIMES_ADD_ICON    = _res('ui/common/common_btn_add.png'),
    REWARDS_NUM_BAR   = _res('ui/ttgame/room/cardgame_prepare_label_num.png'),
    REWARDS_EMPTY_BAR = _res('ui/home/materialScript/material_label_warning_2'),
    
}

local CreateView = nil


function TTGameBaseRoomView:ctor(args)
    -- block layer
    self:addChild(display.newLayer(0, 0, {color = cc.c4b(0,0,0,0), enable = true}))

    -- create view
    self.viewData_ = CreateView()
    self:addChild(self.viewData_.view)

    self:initAllLayer()
    self:updateRuleMode(false)
    self:updateGameButtonStatus(true)
    self:updateDeckSelectIndex(0)
    self:updateDeckCardNodeList(nil)
    self:updateRewardGoodsList(nil)
    self:updateRewardBuyStatus(false)
    self:updateRewardLeftTimes(0)
end


CreateView = function()
    local view = display.newLayer()
    local size = view:getContentSize()
    view:addChild(display.newImageView(RES_DICT.BG_IMAGE, size.width/2, size.height/2))

    ------------------------------------------------- [bg]
    local bgLayer = display.newLayer()
    view:addChild(bgLayer)

    ------------------------------------------------- [top]
    local topLayer = display.newLayer()
    view:addChild(topLayer)
    
    -- rule layer
    local ruleLayer = display.newLayer(size.width/2 - 250, size.height, {ap = display.CENTER_TOP, size = cc.size(420, 110), color = cc.r4b(0), enable = true})
    view:addChild(ruleLayer)

    ------------------------------------------------- [right]
    local rightLayer = display.newLayer(size.width, size.height/2, {size = cc.size(540 + display.SAFE_L, size.height), ap = display.RIGHT_CENTER})
    -- rightLayer:setBackgroundColor(cc.c4b(200, 150, 50, 255))
    view:addChild(rightLayer)

    ------------------------------------------------- [center]
    local centerLayer = display.newLayer()
    view:addChild(centerLayer)

    -- rewards layer
    local rewardsLayer = display.newLayer(ruleLayer:getPositionX(), 20, {ap = display.CENTER_BOTTOM, size = cc.size(600, 210)})
    view:addChild(rewardsLayer)

    return {
        view            = view,
        bgLayer         = bgLayer,
        topLayer        = topLayer,
        topLayerHidePos = cc.p(topLayer:getPositionX(), 100),
        topLayerShowPos = cc.p(topLayer:getPosition()),
        ruleLayer       = ruleLayer,
        rightLayer      = rightLayer,
        centerLayer     = centerLayer,
        rewardsLayer    = rewardsLayer,
    }
end


function TTGameBaseRoomView:getViewData()
    return self.viewData_
end


function TTGameBaseRoomView:initAllLayer()
    table.merge(self:getViewData(), self:initBgLayer(self:getViewData().bgLayer))
    table.merge(self:getViewData(), self:initTopLayer(self:getViewData().topLayer))
    table.merge(self:getViewData(), self:initRuleLayer(self:getViewData().ruleLayer))
    table.merge(self:getViewData(), self:initRightLayer(self:getViewData().rightLayer))
    table.merge(self:getViewData(), self:initCenterLayer(self:getViewData().centerLayer))
    table.merge(self:getViewData(), self:initRewardsLayer(self:getViewData().rewardsLayer))
end


function TTGameBaseRoomView:initBgLayer(ownerLayer)
    return {}
end


function TTGameBaseRoomView:initTopLayer(ownerLayer)
    -- back button
    local backBtn = display.newButton(display.SAFE_L + 75, display.height - 52, {n = RES_DICT.COM_BACK_BTN})
    ownerLayer:addChild(backBtn)

    return {
        backBtn = backBtn,
    }
end


function TTGameBaseRoomView:initRuleLayer(ownerLayer)
    local ownerSize = ownerLayer:getContentSize()
    ownerLayer:addChild(display.newImageView(RES_DICT.RULE_BG_FRAME, 0, 0, {size = ownerSize, scale9 = true, ap = display.LEFT_BOTTOM}))

    -- todayRule layer
    local todayRuleTipsSize  = cc.size(ownerSize.width, 34)
    local todayRuleTipsLayer = display.newLayer(ownerSize.width/2, 0, {size = todayRuleTipsSize})
    ownerLayer:addChild(todayRuleTipsLayer)
    
    -- ruleIcon layer
    local ruleIconLayer = display.newLayer(0, ownerSize.height, {size = cc.size(ownerSize.width, ownerSize.height - todayRuleTipsSize.height), ap = display.LEFT_TOP})
    ownerLayer:addChild(ruleIconLayer)

    -- today ruleIntro
    local todayRuleIntro = display.newLabel(ownerSize.width/2, todayRuleTipsSize.height/2, fontWithColor(12, {text = __('今日规则')}))
    ownerLayer:addChild(display.newImageView(RES_DICT.RULE_CUTTING_LINE, ownerSize.width/2, todayRuleTipsSize.height, {size = cc.size(ownerSize.width - 50, 2), scale9 = true}))
    ownerLayer:addChild(todayRuleIntro)

    -- tips icon
    ownerLayer:addChild(display.newImageView(RES_DICT.COM_TIPS_ICON, ownerSize.width - 20, todayRuleIntro:getPositionY()))


    -- pveRule layer
    local pveRuleTipsSize  = cc.size(ownerSize.width, 36)
    local pveRuleTipsLayer = display.newImageView(RES_DICT.RULE_PVE_FRAME, ownerSize.width/2, 0, {ap = display.CENTER_BOTTOM, size = pveRuleTipsSize, scale9 = true})
    pveRuleTipsLayer:addChild(display.newLabel(pveRuleTipsSize.width/2, pveRuleTipsSize.height/2, fontWithColor(12, {text = __('牌王规则')})))
    ownerLayer:addChild(pveRuleTipsLayer)
    
    return {
        ruleIconLayer      = ruleIconLayer,
        pveRuleTipsLayer   = pveRuleTipsLayer,
        todayRuleTipsLayer = todayRuleTipsLayer,
    }
end


function TTGameBaseRoomView:initRightLayer(ownerLayer, gameBtnName)
    local ownerSize      = ownerLayer:getContentSize()
    local rightCenterPos = cc.p((ownerSize.width - display.SAFE_L)/2 + 14, ownerSize.height/2)
    ownerLayer:addChild(display.newImageView(RES_DICT.RIGHT_BG_FRAME, 0, rightCenterPos.y, {ap = display.LEFT_CENTER}))

    -------------------------------------------------
    -- deck info
    local deckInfoSize  = cc.size(450, 445)
    local deckInfoLayer = display.newLayer(rightCenterPos.x, rightCenterPos.y - 85, {size = deckInfoSize, ap = display.CENTER_BOTTOM, color1 = cc.r4b(150)})
    ownerLayer:addChild(deckInfoLayer)

    deckInfoLayer:addChild(display.newLabel(20, deckInfoSize.height - 15, fontWithColor(7, {fontSize = 24, ap = display.LEFT_TOP, text = __('出战牌组')})))


    local DECK_CARD_COLS   = 3
    local DECK_CARD_ROWS   = math.ceil(TTGAME_DEFINE.DECK_CARD_NUM / DECK_CARD_COLS)
    local DECK_CARD_SIZE   = cc.size(140, 155)
    local DECK_CARD_MAX_H  = DECK_CARD_ROWS * DECK_CARD_SIZE.height + 15
    local deckCardNodeList = {}
    for cardIndex = 1, TTGAME_DEFINE.DECK_CARD_NUM do
        local colNum   = (cardIndex - 1) % DECK_CARD_COLS + 1
        local rowNum   = math.ceil(cardIndex / DECK_CARD_COLS)
        local colMax   = math.min(TTGAME_DEFINE.DECK_CARD_NUM - (rowNum-1) * DECK_CARD_COLS, DECK_CARD_COLS)
        local offsetX  = deckInfoSize.width/2 - (colMax-1) * DECK_CARD_SIZE.width/2
        local cardNode = TTGameUtils.GetBattleCardNode({zoomModel = 's'})
        cardNode:setPositionX(offsetX + (colNum-1) * DECK_CARD_SIZE.width)
        cardNode:setPositionY(DECK_CARD_MAX_H - (rowNum-0.5) * DECK_CARD_SIZE.height)
        deckInfoLayer:addChild(cardNode, 1)
        table.insert(deckCardNodeList, cardNode)
    end


    local deckFrameImage = display.newImageView(RES_DICT.RIGHT_DECK_FRAME, deckInfoSize.width/2, 0, {ap = display.CENTER_BOTTOM, enable = true})
    local deckFrameSize  = deckFrameImage:getContentSize()
    deckInfoLayer:addChild(deckFrameImage)

    local DECK_INDEX_SIZE  = cc.size(100, 74)
    local DECK_INDEX_SPACE = DECK_INDEX_SIZE.width
    local DECK_INDEX_OFF_X = deckInfoSize.width/2 - (TTGAME_DEFINE.DECK_MAXIMUM-1) * DECK_INDEX_SPACE/2
    local DECK_INDEX_OFF_Y = deckFrameSize.height - 12
    local deckIndexBtnList = {}
    for deckIndex = 1, TTGAME_DEFINE.DECK_MAXIMUM do
        local indexBtn = display.newToggleView(0, 0, {scale9 = true, size = DECK_INDEX_SIZE, n = RES_DICT.DECK_TAB_N, s = RES_DICT.DECK_TAB_S, ap = display.CENTER_BOTTOM})
        display.commonLabelParams(indexBtn, fontWithColor(2, {color = '#FFFFFF', text = tostring(deckIndex)}))
        indexBtn:setPositionX(DECK_INDEX_OFF_X + (deckIndex-1) * DECK_INDEX_SPACE)
        indexBtn:setPositionY(DECK_INDEX_OFF_Y)
        indexBtn:setTag(deckIndex)
        deckInfoLayer:addChild(indexBtn)
        table.insert(deckIndexBtnList, indexBtn)
    end
    

    local deckEmptyLayer = display.newLayer()
    deckInfoLayer:addChild(deckEmptyLayer)

    local deckEmptyIcon = display.newImageView(RES_DICT.DECK_ADD_ICON, deckFrameImage:getPositionX(), deckFrameImage:getPositionY() + deckFrameSize.height/2)
    deckEmptyLayer:addChild(deckEmptyIcon)

    local deckEmptyIntro = display.newLabel(deckEmptyIcon:getPositionX(), deckEmptyIcon:getPositionY() - 70, fontWithColor(5, {color = '#d1ada3', text = __('牌组是空的，去编辑一下吧')}))
    deckEmptyLayer:addChild(deckEmptyIntro)
    

    -------------------------------------------------
    -- start btn

    local playGameBtn = display.newButton(rightCenterPos.x, deckInfoLayer:getPositionY() - 128, {n = RES_DICT.START_BTN_N, d = RES_DICT.START_BTN_D})
    ownerLayer:addChild(playGameBtn)
    
    local playGameNameBar  = display.newButton(playGameBtn:getPositionX(), playGameBtn:getPositionY() - 80, {n = RES_DICT.START_NAME_BAR, enable = false})
    display.commonLabelParams(playGameNameBar, fontWithColor(20, {fontSize = 36, text = gameBtnName or __('挑战')}))
    ownerLayer:addChild(playGameNameBar)


    return {
        rightCenterPos   = rightCenterPos,
        deckCardNodeList = deckCardNodeList,
        deckIndexBtnList = deckIndexBtnList,
        deckFrameImage   = deckFrameImage,
        deckEmptyLayer   = deckEmptyLayer,
        playGameBtn      = playGameBtn,
        playGameNameBar  = playGameNameBar,
    }
end


function TTGameBaseRoomView:initCenterLayer(ownerLayer)
    return {}
end


function TTGameBaseRoomView:initRewardsLayer(ownerLayer)
    local ownerSize = ownerLayer:getContentSize()
    ownerLayer:addChild(display.newImageView(RES_DICT.RULE_BG_FRAME, 0, 0, {size = ownerSize, scale9 = true, ap = display.LEFT_BOTTOM}))
    
    local rewardsIntro = display.newLabel(35, ownerSize.height - 12, fontWithColor(8, {color = '#FFE6C8', text = __('获胜奖励可能掉落：'), ap = display.LEFT_TOP}))
    ownerLayer:addChild(rewardsIntro)

    ownerLayer:addChild(display.newImageView(RES_DICT.RULE_CUTTING_LINE, ownerSize.width/2, ownerSize.height - 40, {size = cc.size(ownerSize.width - 100, 2), scale9 = true}))
    
    local rewardGoodsLayer = display.newLayer(ownerSize.width/2, ownerSize.height/2 + 5, {size = cc.size(ownerSize.width - 70, ownerSize.height), ap = display.CENTER, color1 = cc.r4b(150)})
    ownerLayer:addChild(rewardGoodsLayer)


    local rewardsTimesCountBar  = display.newButton(ownerSize.width - 45, 15, {n = RES_DICT.REWARDS_NUM_BAR, ap = display.RIGHT_BOTTOM})
    local rewardsTimesCountSize = rewardsTimesCountBar:getContentSize()
    display.commonLabelParams(rewardsTimesCountBar, fontWithColor(12, {ap = display.RIGHT_CENTER}))
    ownerLayer:addChild(rewardsTimesCountBar)

    local rewardsTimesAddIcon = display.newImageView(RES_DICT.TIMES_ADD_ICON, rewardsTimesCountBar:getPositionX(), rewardsTimesCountBar:getPositionY() + rewardsTimesCountSize.height/2, {ap = display.CENTER_RIGHT})
    ownerLayer:addChild(rewardsTimesAddIcon)
    

    local rewardsTimesEmptySize = cc.size(ownerSize.width - 60, 50)
    local rewardsTimesEmptyBar  = display.newButton(ownerSize.width/2, ownerSize.height/2, {n = RES_DICT.REWARDS_EMPTY_BAR, enable = false, scale9 = true, size = rewardsTimesEmptySize})
    display.commonLabelParams(rewardsTimesEmptyBar, fontWithColor(12, {text = __('奖励次数已用完')}))
    ownerLayer:addChild(rewardsTimesEmptyBar)

    return {
        rewardGoodsLayer     = rewardGoodsLayer,
        rewardsTimesEmptyBar = rewardsTimesEmptyBar,
        rewardsTimesCountBar = rewardsTimesCountBar,
        rewardsTimesAddIcon  = rewardsTimesAddIcon,
    }
end


-------------------------------------------------

function TTGameBaseRoomView:updateRuleMode(isPveRule)
    self:getViewData().pveRuleTipsLayer:setVisible(isPveRule == true)
    self:getViewData().todayRuleTipsLayer:setVisible(isPveRule ~= true)
end


function TTGameBaseRoomView:updateRuleList(ruleList)
    local ruleIconLayer = self:getViewData().ruleIconLayer
    if ruleIconLayer then
        ruleIconLayer:removeAllChildren()
        local SPACE_W = 70
        local offsetX = ruleIconLayer:getContentSize().width/2 - ((#ruleList-1) * SPACE_W)/2
        for index, ruleId in ipairs(ruleList or {}) do
            local ruleNode = TTGameUtils.GetRuleIconNode(ruleId)
            ruleNode:setPositionX(offsetX + (index-1) * SPACE_W)
            ruleNode:setPositionY(ruleIconLayer:getContentSize().height/2)
            ruleNode:setAnchorPoint(display.CENTER)
            ruleIconLayer:addChild(ruleNode)
        end
    end
end


function TTGameBaseRoomView:updateGameButtonStatus(isEnable)
    self:getViewData().playGameBtn:setEnabled(isEnable == true)
end


function TTGameBaseRoomView:updateDeckSelectIndex(selectIndex)
    for deckIndex, indexBtn in ipairs(self:getViewData().deckIndexBtnList) do
        local isSelected = deckIndex == checkint(selectIndex)
        indexBtn:setChecked(isSelected)
    end
end


function TTGameBaseRoomView:updateDeckCardNodeList(cardIdList)
    local deckCardIdList = checktable(cardIdList)
    for cardIndex, cardNode in ipairs(self:getViewData().deckCardNodeList) do
        local cardId = checkint(deckCardIdList[cardIndex])
        cardNode:setVisible(cardId > 0)
        cardNode:setCardId(cardId)
    end
    self:getViewData().deckEmptyLayer:setVisible(#deckCardIdList == 0)
end


function TTGameBaseRoomView:updateRewardGoodsList(goodsList)
    local rewardGoodsList     = checktable(goodsList)
    local rewardGoodsLayer    = self:getViewData().rewardGoodsLayer
    local GOODS_NODE_SAPCE_W  = 106
    local GOODS_NODE_OFFSET_X = 0
    local GOODS_NODE_OFFSET_Y = rewardGoodsLayer:getContentSize().height/2
    rewardGoodsLayer:removeAllChildren()
    for goodsIndex, goodsData in ipairs(rewardGoodsList) do
        local goodNode = require('common.GoodNode').new({ id = goodsData.goodsId, amount = goodsData.num, showAmount = true, callBack = function(sender)
            app.uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = sender.goodId, type = 1})
        end})
        goodNode:setPositionX(GOODS_NODE_OFFSET_X + (goodsIndex-0.5) * GOODS_NODE_SAPCE_W)
        goodNode:setPositionY(GOODS_NODE_OFFSET_Y)
        goodNode:setScale(0.9)
        rewardGoodsLayer:addChild(goodNode)
    end
end


function TTGameBaseRoomView:updateRewardLeftTimes(number, descr)
    local leftRewardTimes = checkint(number)
    local leftTimesDescr  = descr or __('剩余奖励次数：')
    self:getViewData().rewardsTimesEmptyBar:setVisible(leftRewardTimes <= 0)
    display.commonLabelParams(self:getViewData().rewardsTimesCountBar, {text = leftTimesDescr .. leftRewardTimes})
    self:getViewData().rewardsTimesCountBar:getLabel():setPositionX(self:getViewData().rewardsTimesCountBar:getContentSize().width - 40)
end


function TTGameBaseRoomView:updateRewardBuyStatus(isEnable)
    self:getViewData().rewardsTimesCountBar:setEnabled(isEnable == true)
    self:getViewData().rewardsTimesAddIcon:setVisible(isEnable == true)
end


return TTGameBaseRoomView

--[[
 * author : kaishiqi
 * descpt : 打牌游戏 - 战斗视图
]]
local TTGameBattleView = class('TripleTriadGameBattleView', function()
    return display.newLayer(0, 0, {name = 'TripleTriadGameBattleView'})
end)

local RES_DICT = {
    BG_IMAGE             = _res('ui/ttgame/battle/cardgame_battle_bg.jpg'),
    --                   = left
    ABANDON_BTN_N        = _res('ui/ttgame/battle/cardgame_battle_btn_quit.png'),
    OPERATOR_INFO_RAME   = _res('ui/ttgame/battle/cardgame_battle_bg_name_blue.png'),
    OPPONENT_INFO_RAME   = _res('ui/ttgame/battle/cardgame_battle_bg_name_red.png'),
    SPECIAL_INFO_RAME    = _res('ui/ttgame/battle/cardgame_battle_bg_name_npc.png'),
    SPECIAL_INFO_TITLE   = _res('ui/ttgame/battle/cardgame_battle_label_title_npc.png'),
    OPERATOR_SOURCE_ICON = _res('ui/ttgame/battle/cardgame_battle_btn_score_blue.png'),
    OPPONENT_SOURCE_ICON = _res('ui/ttgame/battle/cardgame_battle_btn_score_red.png'),
    ROUND_PROGRESS_BAR   = _res('ui/ttgame/battle/cardgame_battle_timer_bar.png'),
    ROUND_PROGRESS_SLOT  = _res('ui/ttgame/battle/cardgame_battle_timer_slot.png'),
    ROUND_ICON_OPERATOR  = _res('ui/ttgame/battle/cardgame_battle_ico_turn_blue.png'),
    ROUND_ICON_OPPONENT  = _res('ui/ttgame/battle/cardgame_battle_ico_turn_red.png'),
    ROUND_LABEL_OPERATOR = _res('ui/ttgame/battle/cardgame_battle_label_turn_blue.png'),
    ROUND_LABEL_OPPONENT = _res('ui/ttgame/battle/cardgame_battle_label_turn_red.png'),
    ROUND_POINTER_SPINE  = _spn('ui/ttgame/battle/cardgame_battle_pointer'),
    MOOD_TALK_BTN        = _res('ui/common/raid_btn_talk.png'),
    --                   = right
    CARD_SLOT_SHADOW     = _res('ui/ttgame/battle/cardgame_battle_team_slot.png'),
    ALPHA_IMG            = _res('ui/common/story_tranparent_bg.png'),
    --                   = center
    DESK_DEFAULT_FRAME   = _res('ui/ttgame/battle/cardgame_battle_table_slot_default.png'),
    DESK_OPERATOR_FRAME  = _res('ui/ttgame/battle/cardgame_battle_table_slot_blue.png'),
    DESK_OPPONENT_FRAME  = _res('ui/ttgame/battle/cardgame_battle_table_slot_red.png'),
    DESK_SELECTED_FRAME  = _res('ui/ttgame/battle/cardgame_battle_table_slot_selected.png'),
    --                   = rule
    INIT_RULE_FRAME      = _res('ui/ttgame/battle//cardgame_battle_start_bg_rule.png'),
    INIT_RULE_TITLE      = _res('ui/ttgame/battle//cardgame_battle_start_label_rule.png'),
    INIT_RULE_LINE       = _res('ui/ttgame/battle//cardgame_battle_start_line_rule.png'),
    INIT_RULE_UNDER      = _res('ui/ttgame/common/cardgame_rule_label_name.png'),
}

local CreateView     = nil
local CreateDeskCell = nil
local CreateRuleView = nil


function TTGameBattleView:ctor(args)
    self.oldDeskDatas_ = {}
    self.newDeskDatas_ = {}

    -- create view
    self.viewData_ = CreateView(args.specialMode == true)
    self:addChild(self.viewData_.view)

    self.ruleViewData_ = CreateRuleView()
    self:addChild(self.ruleViewData_.view)

    local DESK_CELL_SIZE = cc.size(200, 230)
    local DESK_CELL_GAPW = 0
    local DESK_CELL_GAPH = 0
    local cellsLayerSize = self:getViewData().cellsLayer:getContentSize()
    local deskCellOffX   = cellsLayerSize.width/2 - (TTGAME_DEFINE.DESK_ELEM_COLS-1)/2 * (DESK_CELL_SIZE.width + DESK_CELL_GAPW)
    local deskCellOffY   = cellsLayerSize.height/2 + (TTGAME_DEFINE.DESK_ELEM_ROWS-1)/2 * (DESK_CELL_SIZE.height + DESK_CELL_GAPH)
    self.deskCellVDList_ = {}
    for row = 1, TTGAME_DEFINE.DESK_ELEM_ROWS do
        for col = 1, TTGAME_DEFINE.DESK_ELEM_COLS do
            local deskCellVD = CreateDeskCell(DESK_CELL_SIZE)
            deskCellVD.view:setPositionX(deskCellOffX + (col-1) * (DESK_CELL_SIZE.width + DESK_CELL_GAPW))
            deskCellVD.view:setPositionY(deskCellOffY - (row-1) * (DESK_CELL_SIZE.height + DESK_CELL_GAPH))
            deskCellVD.clickHotspot:setTag(#self.deskCellVDList_ + 1)
            self:getViewData().cellsLayer:addChild(deskCellVD.view)
            table.insert(self.deskCellVDList_, deskCellVD)
        end
    end
end


CreateView = function(isSpecial)
    local view = display.newLayer()
    local size = view:getContentSize()

    -- block layer
    view:addChild(display.newLayer(0, 0, {color = cc.c4b(65,50,65,0), enable = true}))
    view:addChild(display.newImageView(RES_DICT.BG_IMAGE, size.width/2, size.height/2))


    -------------------------------------------------[center]
    local CENTER_CPOS = cc.p(size.width/2 - 76, size.height/2)
    local centerLayer = display.newLayer()
    view:addChild(centerLayer)

    -- local DESK_SIZE = cc.size(600, 690)
    -- local deskFrame = display.newLayer(CENTER_CPOS.x, CENTER_CPOS.y, {ap = display.CENTER, size = DESK_SIZE, color = cc.c4b(100,50,25,155)})
    -- centerLayer:addChild(deskFrame)

    local cellsLayer = display.newLayer(CENTER_CPOS.x, CENTER_CPOS.y, {ap = display.CENTER})
    centerLayer:addChild(cellsLayer)


    -------------------------------------------------[left]
    local LEFT_CPOS = cc.p(display.cx - 545, size.height/2 + 18)
    local leftLayer = display.newLayer()
    view:addChild(leftLayer)
    
    -- abandon button
    local abandonBtn = display.newButton(LEFT_CPOS.x + 10, LEFT_CPOS.y - 345, {n = RES_DICT.ABANDON_BTN_N})
    display.commonLabelParams(abandonBtn, fontWithColor(7, {fontSize = 26, text = __('认输')}))
    leftLayer:addChild(abandonBtn)
    

    -- operator layer
    local operatorInfoLayer = display.newLayer(LEFT_CPOS.x, LEFT_CPOS.y - 220, {ap = display.CENTER, bg = RES_DICT.OPERATOR_INFO_RAME})
    local operatorInfoSize  = operatorInfoLayer:getContentSize()
    leftLayer:addChild(operatorInfoLayer)

    local operatorNameLabel = display.newLabel(25, 25, fontWithColor(18, {ap = display.LEFT_CENTER, text = '----'}))
    operatorInfoLayer:addChild(operatorNameLabel)
    
    local operatorHeadNode = require('common.PlayerHeadNode').new()
    operatorHeadNode:setPositionY(operatorInfoSize.height - 52)
    operatorHeadNode:setPositionX(70)
    operatorHeadNode:setScale(0.58)
    operatorInfoLayer:addChild(operatorHeadNode)

    local moodTalkBtn = display.newLayer(0, 0, {color = cc.r4b(0), size = operatorInfoSize, enable = true})
    operatorInfoLayer:addChild(display.newImageView(RES_DICT.MOOD_TALK_BTN, operatorHeadNode:getPositionX() + 25, operatorHeadNode:getPositionY() - 25, {scale = 0.5}))
    operatorInfoLayer:addChild(moodTalkBtn)
    
    local operatorScoreFrame = display.newImageView(RES_DICT.OPERATOR_SOURCE_ICON, operatorInfoSize.width - 75, operatorHeadNode:getPositionY(), {scale = 0.5, enable = true})
    operatorInfoLayer:addChild(operatorScoreFrame)
    
    local operatorScoreLabel = display.newLabel(operatorScoreFrame:getPositionX(), operatorScoreFrame:getPositionY(), fontWithColor(3, {fontSize = 60, text = '-'}))
    operatorInfoLayer:addChild(operatorScoreLabel)
    
    
    -- opponent layer
    local opponentInfoLayer = display.newLayer(LEFT_CPOS.x, LEFT_CPOS.y + 220, {ap = display.CENTER, bg = isSpecial and RES_DICT.SPECIAL_INFO_RAME or RES_DICT.OPPONENT_INFO_RAME})
    local opponentInfoSize  = opponentInfoLayer:getContentSize()
    leftLayer:addChild(opponentInfoLayer)
    
    local opponentNameLabel = display.newLabel(opponentInfoSize.width - 25, opponentInfoSize.height - 15, fontWithColor(18, {ap = display.RIGHT_CENTER, text = '----'}))
    opponentInfoLayer:addChild(opponentNameLabel)

    local opponentHeadNode = require('common.PlayerHeadNode').new()
    opponentHeadNode:setPositionX(operatorScoreFrame:getPositionX())
    opponentHeadNode:setPositionY(65)
    opponentHeadNode:setScale(0.58)
    opponentInfoLayer:addChild(opponentHeadNode)
    
    local opponentScoreFrame = display.newImageView(RES_DICT.OPPONENT_SOURCE_ICON, operatorHeadNode:getPositionX(), opponentHeadNode:getPositionY(), {scale = 0.5, enable = true})
    opponentInfoLayer:addChild(opponentScoreFrame)
    
    local opponentScoreLabel = display.newLabel(opponentScoreFrame:getPositionX(), opponentScoreFrame:getPositionY(), fontWithColor(3, {fontSize = 60, text = '-'}))
    opponentInfoLayer:addChild(opponentScoreLabel)

    if isSpecial then
        local specialTitleBar = display.newImageView(RES_DICT.SPECIAL_INFO_TITLE, opponentInfoSize.width - 5, opponentInfoSize.height + 25, {ap = display.LEFT_CENTER, scaleX = -1})
        opponentInfoLayer:addChild(specialTitleBar)
        opponentInfoLayer:addChild(display.newLabel(specialTitleBar:getPositionX() - 60, specialTitleBar:getPositionY(), fontWithColor(2, {color = '#f6c886', text = __('牌王'), ap = display.RIGHT_CENTER})))
    end


    -- round frame
    local roundFramePoint    = cc.p(LEFT_CPOS.x + 100, LEFT_CPOS.y)
    local roundOperatorFrame = display.newImageView(RES_DICT.ROUND_LABEL_OPERATOR, roundFramePoint.x, roundFramePoint.y, {ap = display.LEFT_CENTER})
    local roundOpponentFrame = display.newImageView(RES_DICT.ROUND_LABEL_OPPONENT, roundFramePoint.x, roundFramePoint.y, {ap = display.LEFT_CENTER})
    roundOperatorFrame:addChild(display.newLabel(35, utils.getLocalCenter(roundOperatorFrame).y, fontWithColor(7, {ap = display.LEFT_CENTER, fontSize = 46, text = __('我的回合')})))
    roundOpponentFrame:addChild(display.newLabel(35, utils.getLocalCenter(roundOpponentFrame).y, fontWithColor(7, {ap = display.LEFT_CENTER, fontSize = 46, text = __('对手回合')})))
    leftLayer:addChild(roundOperatorFrame)
    leftLayer:addChild(roundOpponentFrame)
    roundOperatorFrame:setScaleX(0)
    roundOpponentFrame:setScaleX(0)

    -- roundInfo layer
    local ROUND_WHEEL_SIZE = cc.size(260, 260)
    local roundInfoLayer   = display.newLayer(LEFT_CPOS.x + 10, LEFT_CPOS.y, {ap = display.CENTER, size = ROUND_WHEEL_SIZE, color1 = cc.c4b(100,150,125,155)})
    leftLayer:addChild(roundInfoLayer)

    local roundPointerSpine = TTGameUtils.CreateSpine(RES_DICT.ROUND_POINTER_SPINE)
    roundPointerSpine:setPosition(cc.p(ROUND_WHEEL_SIZE.width/2, ROUND_WHEEL_SIZE.height/2))
    roundPointerSpine:setAnimation(0, 'idle_start', false)
    roundInfoLayer:addChild(roundPointerSpine)

    local roundTimeSlot = display.newImageView(RES_DICT.ROUND_PROGRESS_SLOT, ROUND_WHEEL_SIZE.width/2, ROUND_WHEEL_SIZE.height/2)
    roundInfoLayer:addChild(roundTimeSlot)
    
    local roundTimePBar = cc.ProgressTimer:create(cc.Sprite:create(RES_DICT.ROUND_PROGRESS_BAR))
    roundTimePBar:setPosition(ROUND_WHEEL_SIZE.width/2, ROUND_WHEEL_SIZE.height/2)
    roundTimePBar:setType(cc.PROGRESS_TIMER_TYPE_RADIAL)
    roundTimePBar:setMidpoint(display.CENTER)
    roundTimePBar:setReverseDirection(true)
    roundTimePBar:setPercentage(100)
    roundInfoLayer:addChild(roundTimePBar)

    -- round icon
    local roundIconPoint    = cc.p(ROUND_WHEEL_SIZE.width/2, ROUND_WHEEL_SIZE.height/2)
    local roundOperatorIcon = display.newImageView(RES_DICT.ROUND_ICON_OPERATOR, roundIconPoint.x, roundIconPoint.y)
    local roundOpponentIcon = display.newImageView(RES_DICT.ROUND_ICON_OPPONENT, roundIconPoint.x, roundIconPoint.y)
    roundInfoLayer:addChild(roundOperatorIcon)
    roundInfoLayer:addChild(roundOpponentIcon)
    roundOperatorIcon:setScaleX(0)
    roundOpponentIcon:setScaleX(0)


    -------------------------------------------------[right]
    local RIGHT_CPOS = cc.p(display.cx + 459, size.height/2)
    local rightLayer = display.newLayer()
    view:addChild(rightLayer)

    -- rule layer
    local ruleLayer = display.newImageView(RES_DICT.ALPHA_IMG, RIGHT_CPOS.x - 7, RIGHT_CPOS.y + 18, {scale9 = true, size = cc.size(360, 70), enable = true})
    ruleLayer:setCascadeOpacityEnabled(true)
    rightLayer:addChild(ruleLayer)

    local ruleIconLayer = display.newLayer(0, 0, {size = ruleLayer:getContentSize()})
    ruleLayer:addChild(ruleIconLayer)

    
    -- operator cardsLayer
    local OPERATOR_LAYER_SIZE = cc.size(372, 310)
    local operatorCardsLayer  = display.newLayer(RIGHT_CPOS.x, RIGHT_CPOS.y - 195, {ap = display.CENTER, size = OPERATOR_LAYER_SIZE})
    -- operatorCardsLayer:setBackgroundColor(cc.c4b(200,0,50,155))
    -- operatorCardsLayer:setBackgroundColor(cc.c4b(50,100,200,255))
    rightLayer:addChild(operatorCardsLayer)

    local DECK_CARD_COLS     = 3
    local DECK_CARD_ROWS     = math.ceil(TTGAME_DEFINE.DECK_CARD_NUM / DECK_CARD_COLS)
    local DECK_CARD_SIZE     = cc.size(125, 150)
    local DECK_CARD_MAX_H    = DECK_CARD_ROWS * DECK_CARD_SIZE.height
    local operatorCardNodes  = {}
    local operatorCardAreas  = {}
    local operatorCardSPList = {}
    local operatorCardHPList = {}
    for cardIndex = 1, TTGAME_DEFINE.DECK_CARD_NUM do
        local colNum   = (cardIndex - 1) % DECK_CARD_COLS + 1
        local rowNum   = math.ceil(cardIndex / DECK_CARD_COLS)
        local colMax   = math.min(TTGAME_DEFINE.DECK_CARD_NUM - (rowNum-1) * DECK_CARD_COLS, DECK_CARD_COLS)
        local offsetX  = OPERATOR_LAYER_SIZE.width/2 - (colMax-1) * DECK_CARD_SIZE.width/2
        local offsetY  = OPERATOR_LAYER_SIZE.height/2 - DECK_CARD_MAX_H/2
        local cardNode = TTGameUtils.GetBattleCardNode({zoomModel = 'ss'})
        cardNode:setPositionX(offsetX + (colNum-1) * DECK_CARD_SIZE.width)
        cardNode:setPositionY(offsetY - (rowNum-0.5) * DECK_CARD_SIZE.height + DECK_CARD_MAX_H)
        cardNode:showOperatorUnderFrame()
        operatorCardsLayer:addChild(cardNode, 1)
        table.insert(operatorCardNodes, cardNode)

        local cardShadow = display.newImageView(RES_DICT.CARD_SLOT_SHADOW, cardNode:getPositionX(), cardNode:getPositionY())
        operatorCardsLayer:addChild(cardShadow)

        local clickArea = display.newLayer(cardNode:getPositionX(), cardNode:getPositionY(), {ap = display.CENTER, size = DECK_CARD_SIZE, color = cc.r4b(0), enable = true})
        table.insert(operatorCardAreas, clickArea)
        operatorCardsLayer:addChild(clickArea, 2)
        clickArea:setTag(cardIndex)

        table.insert(operatorCardSPList, cc.p(cardNode:getPosition()))
        table.insert(operatorCardHPList, cc.p(cardNode:getPositionX() + 250, cardNode:getPositionY() + 200))
    end

    local operatorDeckArea = display.newLayer(0, 0, {color = cc.c4b(255,255,255,50), size = OPERATOR_LAYER_SIZE})
    operatorCardsLayer:addChild(operatorDeckArea)
    operatorDeckArea:setVisible(false)
    operatorDeckArea:runAction(cc.RepeatForever:create(cc.Sequence:create(
        cc.FadeTo:create(0.5, 55),
        cc.FadeOut:create(0.5)
    )))


    -- opponent cardsLayer
    local OPPONENT_LAYER_SIZE = cc.size(OPERATOR_LAYER_SIZE.width, OPERATOR_LAYER_SIZE.height - 28)
    local opponentCardsLayer  = display.newLayer(RIGHT_CPOS.x, RIGHT_CPOS.y + 216, {ap = display.CENTER, size = OPPONENT_LAYER_SIZE})
    -- opponentCardsLayer:setBackgroundColor(cc.c4b(200,0,50,255))
    -- opponentCardsLayer:setBackgroundColor(cc.c4b(50,100,200,155))
    rightLayer:addChild(opponentCardsLayer)

    local DECK_CARD_SIZE     = cc.size(125, 150-10)
    local DECK_CARD_MAX_H    = DECK_CARD_ROWS * DECK_CARD_SIZE.height
    local CARD_SHADOW_SIZE   = cc.size(DECK_CARD_SIZE.width - 2, DECK_CARD_SIZE.height - 2)
    local opponentCardNodes  = {}
    local opponentCardAreas  = {}
    local opponentCardSPList = {}
    local opponentCardHPList = {}
    for cardIndex = 1, TTGAME_DEFINE.DECK_CARD_NUM do
        local colNum   = (cardIndex - 1) % DECK_CARD_COLS + 1
        local rowNum   = math.ceil(cardIndex / DECK_CARD_COLS)
        local colMax   = math.min(TTGAME_DEFINE.DECK_CARD_NUM - (rowNum-1) * DECK_CARD_COLS, DECK_CARD_COLS)
        local offsetX  = OPPONENT_LAYER_SIZE.width/2 - (colMax-1) * DECK_CARD_SIZE.width/2
        local offsetY  = OPPONENT_LAYER_SIZE.height/2 - DECK_CARD_MAX_H/2
        local cardNode = TTGameUtils.GetBattleCardNode({zoomModel = 'ss'})
        cardNode:setPositionX(offsetX + (colNum-1) * DECK_CARD_SIZE.width)
        cardNode:setPositionY(offsetY - (rowNum-0.5) * DECK_CARD_SIZE.height + DECK_CARD_MAX_H)
        cardNode:showOpponentUnderFrame()
        opponentCardsLayer:addChild(cardNode, 1)
        table.insert(opponentCardNodes, cardNode)
        cardNode:toCardBackStatus()
        
        local cardShadow = display.newImageView(RES_DICT.CARD_SLOT_SHADOW, cardNode:getPositionX(), cardNode:getPositionY())
        opponentCardsLayer:addChild(cardShadow)
        
        local clickArea = display.newLayer(cardNode:getPositionX(), cardNode:getPositionY(), {ap = display.CENTER, size = DECK_CARD_SIZE, color = cc.r4b(0), enable = true})
        table.insert(opponentCardAreas, clickArea)
        opponentCardsLayer:addChild(clickArea, 2)
        clickArea:setTag(cardIndex)

        table.insert(opponentCardSPList, cc.p(cardNode:getPosition()))
        table.insert(opponentCardHPList, cc.p(cardNode:getPositionX() + 250, cardNode:getPositionY() + 200))
    end

    local opponentDeckArea = display.newLayer(0, 0, {color = cc.r4b(0), size = OPPONENT_LAYER_SIZE, enable = true})
    opponentCardsLayer:addChild(opponentDeckArea, 3)


    return {
        view               = view,
        --                 = 
        centerLayer        = centerLayer,
        cellsLayer         = cellsLayer,
        --                 = 
        leftLayer          = leftLayer,
        abandonBtn         = abandonBtn,
        roundInfoLayer     = roundInfoLayer,
        roundTimePBar      = roundTimePBar,
        roundPointerSpine  = roundPointerSpine,
        roundOperatorIcon  = roundOperatorIcon,
        roundOpponentIcon  = roundOpponentIcon,
        roundOperatorFrame = roundOperatorFrame,
        roundOpponentFrame = roundOpponentFrame,
        operatorInfoLayer  = operatorInfoLayer,
        operatorInfoSPos   = cc.p(operatorInfoLayer:getPosition()),
        operatorInfoHPos   = cc.p(operatorInfoLayer:getPositionX(), operatorInfoLayer:getPositionY() - display.cy),
        operatorNameLabel  = operatorNameLabel,
        operatorHeadNode   = operatorHeadNode,
        operatorScoreLabel = operatorScoreLabel,
        operatorScoreFrame = operatorScoreFrame,
        opponentInfoLayer  = opponentInfoLayer,
        opponentInfoSPos   = cc.p(opponentInfoLayer:getPosition()),
        opponentInfoHPos   = cc.p(opponentInfoLayer:getPositionX(), opponentInfoLayer:getPositionY() + display.cy),
        opponentNameLabel  = opponentNameLabel,
        opponentHeadNode   = opponentHeadNode,
        opponentScoreLabel = opponentScoreLabel,
        opponentScoreFrame = opponentScoreFrame,
        moodTalkBtn        = moodTalkBtn,
        --                 = 
        rightLayer         = rightLayer,
        ruleLayer          = ruleLayer,
        ruleIconLayer      = ruleIconLayer,
        operatorCardNodes  = operatorCardNodes,
        opponentCardNodes  = opponentCardNodes,
        operatorCardAreas  = operatorCardAreas,
        opponentCardAreas  = opponentCardAreas,
        operatorCardSPList = operatorCardSPList,
        operatorCardHPList = operatorCardHPList,
        opponentCardSPList = opponentCardSPList,
        opponentCardHPList = opponentCardHPList,
        operatorDeckArea   = operatorDeckArea,
        opponentDeckArea   = opponentDeckArea,
    }
end


CreateDeskCell = function(size)
    local view = display.newLayer(0, 0, {size = size, ap = display.CENTER, color1 = cc.r4b(255)})

    local centerPoint     = cc.p(size.width/2, size.height/2)
    local defaultBgLayer  = display.newImageView(RES_DICT.DESK_DEFAULT_FRAME, centerPoint.x, centerPoint.y)
    local operatorBgLayer = display.newImageView(RES_DICT.DESK_OPERATOR_FRAME, centerPoint.x, centerPoint.y)
    local opponentBgLayer = display.newImageView(RES_DICT.DESK_OPPONENT_FRAME, centerPoint.x, centerPoint.y)
    local selectedBgLayer = display.newImageView(RES_DICT.DESK_SELECTED_FRAME, centerPoint.x, centerPoint.y)
    view:addChild(defaultBgLayer)
    view:addChild(operatorBgLayer)
    view:addChild(opponentBgLayer)
    view:addChild(selectedBgLayer)

    local deskCardNode = TTGameUtils.GetBattleCardNode({zoomModel = 'm'})
    deskCardNode:setPositionX(centerPoint.x)
    deskCardNode:setPositionY(centerPoint.y)
    view:addChild(deskCardNode)

    local clickHotspot = display.newLayer(0, 0, {size = size, color = cc.r4b(0), enable = true})
    view:addChild(clickHotspot)

    deskCardNode:setScale(0)
    operatorBgLayer:setOpacity(0)
    opponentBgLayer:setOpacity(0)
    selectedBgLayer:setVisible(false)
    selectedBgLayer:runAction(cc.RepeatForever:create(cc.Sequence:create(
        cc.FadeOut:create(1),
        cc.FadeIn:create(1)
    )))
    return {
        view             = view,
        defaultBgLayer   = defaultBgLayer,
        operatorBgLayer  = operatorBgLayer,
        opponentBgLayer  = opponentBgLayer,
        selectedBgLayer  = selectedBgLayer,
        deskCardNode     = deskCardNode,
        deskCardNodeSPos = cc.p(deskCardNode:getPosition()),
        deskCardNodeHPos = cc.p(deskCardNode:getPositionX() - 200, deskCardNode:getPositionY() + 500),
        clickHotspot     = clickHotspot,
    }
end


CreateRuleView = function()
    local view = display.newLayer()
    local size = view:getContentSize()
    
    local ruleLayerNode = display.newLayer(size.width/2 - 70, size.height/2, {size = size, ap = display.CENTER})
    local ruleLayerSize = ruleLayerNode:getContentSize()
    view:addChild(ruleLayerNode)
    ruleLayerNode:setScale(0)

    local ruleLayerFrame = display.newImageView(RES_DICT.INIT_RULE_FRAME, 0, 0, {size = size, scale9 = true, ap = display.LEFT_BOTTOM, capInsets = cc.rect(20,20,420,250)})
    ruleLayerNode:addChild(ruleLayerFrame)

    local ruleTitleBar = display.newImageView(RES_DICT.INIT_RULE_TITLE, 10, ruleLayerSize.height - 30, {ap = display.LEFT_CENTER})
    ruleLayerNode:addChild(ruleTitleBar)

    local ruleTitleIntro = display.newLabel(15, utils.getLocalCenter(ruleTitleBar).y, fontWithColor(1, {fontSize = 24, color = '#efb67f', text = __('规则'), ap = display.LEFT_CENTER}))
    ruleTitleBar:addChild(ruleTitleIntro)

    local ruleListLayer = display.newLayer()
    ruleLayerNode:addChild(ruleListLayer)

    return {
        view           = view,
        ruleLayerNode  = ruleLayerNode,
        ruleLayerFrame = ruleLayerFrame,
        ruleListLayer  = ruleListLayer,
        ruleTitleBar   = ruleTitleBar,
    }
end


function TTGameBattleView:getViewData()
    return self.viewData_
end


function TTGameBattleView:getRuleViewData()
    return self.ruleViewData_
end


function TTGameBattleView:show(finishCB)
    -- init 
    self:getViewData().view:setOpacity(0)
    self:getViewData().roundTimePBar:setVisible(false)
    self:getViewData().operatorHeadNode:setVisible(false)
    self:getViewData().opponentHeadNode:setVisible(false)
    self:getViewData().operatorInfoLayer:setPosition(self:getViewData().operatorInfoHPos)
    self:getViewData().opponentInfoLayer:setPosition(self:getViewData().opponentInfoHPos)
    for index, cardNode in ipairs(self:getViewData().operatorCardNodes) do
        cardNode:setPositionY(self:getViewData().operatorCardSPList[index].y - display.cy)
    end
    for index, cardNode in ipairs(self:getViewData().opponentCardNodes) do
        cardNode:setPositionY(self:getViewData().opponentCardSPList[index].y + display.cy)
    end

    -- run
    self:getViewData().view:runAction(cc.Sequence:create(
        cc.DelayTime:create(0.3), -- waiting for matchedPopup
        cc.CallFunc:create(function()
            self:getViewData().view:setOpacity(255)
            self:getViewData().roundTimePBar:setVisible(true)
            self:getViewData().operatorHeadNode:setVisible(true)
            self:getViewData().opponentHeadNode:setVisible(true)
            if finishCB then finishCB() end
        end)
    ))
end
function TTGameBattleView:showUI(finishCB)
    local showCardNodeActList = {}
    for index, cardNode in ipairs(self:getViewData().operatorCardNodes) do
        table.insert(showCardNodeActList, cc.TargetedAction:create(cardNode, cc.Sequence:create(
            cc.DelayTime:create(index * 0.05),
            cc.EaseCubicActionOut:create(cc.MoveTo:create(0.2, self:getViewData().operatorCardSPList[index]))
        )))
    end
    for index, cardNode in ipairs(self:getViewData().opponentCardNodes) do
        table.insert(showCardNodeActList, cc.TargetedAction:create(cardNode, cc.Sequence:create(
            cc.DelayTime:create((#self:getViewData().opponentCardNodes - index + 1) * 0.05),
            cc.EaseCubicActionOut:create(cc.MoveTo:create(0.2, self:getViewData().opponentCardSPList[index]))
        )))
    end

    -- run
    self:getViewData().view:runAction(cc.Sequence:create(
        cc.Spawn:create(
            cc.TargetedAction:create(self:getViewData().operatorInfoLayer, cc.EaseCubicActionOut:create(cc.MoveTo:create(0.3, self:getViewData().operatorInfoSPos))),
            cc.TargetedAction:create(self:getViewData().opponentInfoLayer, cc.EaseCubicActionOut:create(cc.MoveTo:create(0.3, self:getViewData().opponentInfoSPos))),
            unpack(showCardNodeActList)
        ),
        cc.CallFunc:create(function()
            if finishCB then finishCB() end
        end)
    ))
end


function TTGameBattleView:updateOperatorInfo(name, avatar, frame)
    display.commonLabelParams(self:getViewData().operatorNameLabel, {text = tostring(name)})
    self:getViewData().operatorHeadNode:RefreshUI({avatar = avatar, avatarFrame = frame})
end


function TTGameBattleView:updateOpponentInfo(name, avatar, frame)
    display.commonLabelParams(self:getViewData().opponentNameLabel, {reqW = 190 ,  text = tostring(name)})
    self:getViewData().opponentHeadNode:RefreshUI({avatar = avatar, avatarFrame = frame})
end


function TTGameBattleView:updateRoundSeconds(totalSeconds, leftSeconds)
    local timePercentage = math.max(0, math.min(leftSeconds / totalSeconds * 100, 100))
    self:getViewData().roundTimePBar:setPercentage(timePercentage)
end


function TTGameBattleView:updateRoundTurn(isOperator)
    local isChangedRound  = self.isOperatorRound_ ~= isOperator
    local isFirstRound    = self.isOperatorRound_ == nil
    self.isOperatorRound_ = isOperator == true

    -- init
    self:getViewData().roundInfoLayer:stopAllActions()
    self:getViewData().roundOperatorFrame:setScaleX(0)
    self:getViewData().roundOpponentFrame:setScaleX(0)
    self:getViewData().roundOperatorIcon:setScaleX(0)
    self:getViewData().roundOpponentIcon:setScaleX(0)

    local FLIP_ROUND_ICON_TIME = 0.3
    local flipPrevRoundIconAct = cc.EaseQuinticActionIn:create(cc.ScaleTo:create(FLIP_ROUND_ICON_TIME, 0, 1))
    local flipNextRoundIconAct = cc.Sequence:create(
        cc.DelayTime:create(FLIP_ROUND_ICON_TIME),
        cc.EaseQuinticActionOut:create(cc.ScaleTo:create(FLIP_ROUND_ICON_TIME, 1.0, 1))
    )

    local showRoundFrameAct = cc.Sequence:create(
        cc.DelayTime:create(FLIP_ROUND_ICON_TIME * 1.5),
        cc.EaseQuinticActionOut:create(cc.ScaleTo:create(0.2, 1.0, 1)),
        cc.ScaleTo:create(1, 1.05, 1),
        cc.EaseQuinticActionOut:create(cc.ScaleTo:create(0.2, 0.0, 1))
    )

    -- run
    if isChangedRound then
        local roundTurnActList = {}
        if self.isOperatorRound_ then
            if not isFirstRound then self:getViewData().roundOpponentIcon:setScale(1) end
            table.insert(roundTurnActList, cc.TargetedAction:create(self:getViewData().roundOpponentIcon, flipPrevRoundIconAct))
            table.insert(roundTurnActList, cc.TargetedAction:create(self:getViewData().roundOperatorIcon, flipNextRoundIconAct))
            table.insert(roundTurnActList, cc.TargetedAction:create(self:getViewData().roundOperatorFrame, showRoundFrameAct))
            table.insert(roundTurnActList, cc.CallFunc:create(function()
                if isFirstRound then
                    self:getViewData().roundPointerSpine:setAnimation(0, 'start_blue', false)
                else
                    self:getViewData().roundPointerSpine:setAnimation(0, 'change_blue', false)
                end
            end))
        else
            if not isFirstRound then self:getViewData().roundOperatorIcon:setScale(1) end
            table.insert(roundTurnActList, cc.TargetedAction:create(self:getViewData().roundOperatorIcon, flipPrevRoundIconAct))
            table.insert(roundTurnActList, cc.TargetedAction:create(self:getViewData().roundOpponentIcon, flipNextRoundIconAct))
            table.insert(roundTurnActList, cc.TargetedAction:create(self:getViewData().roundOpponentFrame, showRoundFrameAct))
            table.insert(roundTurnActList, cc.CallFunc:create(function()
                if isFirstRound then
                    self:getViewData().roundPointerSpine:setAnimation(0, 'start_red', false)
                else
                    self:getViewData().roundPointerSpine:setAnimation(0, 'change_red', false)
                end
            end))
        end
        self:getViewData().roundInfoLayer:runAction(cc.Spawn:create(roundTurnActList))

    else
        if self.isOperatorRound_ then
            self:getViewData().roundOperatorIcon:setScale(1)
            self:getViewData().roundPointerSpine:setAnimation(0, 'idle_blue', false)
        else
            self:getViewData().roundOpponentIcon:setScale(1)
            self:getViewData().roundPointerSpine:setAnimation(0, 'idle_red', false)
        end
    end
end


function TTGameBattleView:updatePlayersScore(operatorScore, opponentScore)
    display.commonLabelParams(self:getViewData().operatorScoreLabel, {text = tostring(operatorScore)})
    display.commonLabelParams(self:getViewData().opponentScoreLabel, {text = tostring(opponentScore)})
end


function TTGameBattleView:updateRuleList(ruleList)
    local ruleNodeList  = {}
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
            ruleNode.showPos = cc.p(ruleNode:getPosition())
            ruleIconLayer:addChild(ruleNode)
            table.insert(ruleNodeList, ruleNode)
        end
    end

    -------------------------------------------------
    local RULE_LAYER_GAP_T = 50
    local RULE_LAYER_GAP_B = 15
    local INIT_RULE_CELL_H = 44
    local INIT_RULE_LIST_H = #checktable(ruleList) * INIT_RULE_CELL_H
    local RULE_LAYER_SIZE  = cc.size(400, RULE_LAYER_GAP_T + RULE_LAYER_GAP_B + INIT_RULE_LIST_H)
    local RULE_UNDER_SIZE  = cc.size(RULE_LAYER_SIZE.width - 18, INIT_RULE_CELL_H - 6)
    self:getRuleViewData().ruleTitleBar:setPositionY(RULE_LAYER_SIZE.height - 30)
    self:getRuleViewData().ruleLayerFrame:setContentSize(RULE_LAYER_SIZE)
    self:getRuleViewData().ruleLayerNode:setContentSize(RULE_LAYER_SIZE)
    self:getRuleViewData().ruleListLayer:removeAllChildren()

    local ruleListLayerWPos = cc.p(self:getRuleViewData().ruleListLayer:convertToWorldSpaceAR(PointZero))
    for index, ruleId in ipairs(ruleList or {}) do
        local ruleConfInfo   = TTGameUtils.GetConfAt(TTGAME_DEFINE.CONF_TYPE.RULE_DEFINE, ruleId)
        local ruleIconNode   = TTGameUtils.GetRuleIconNode(ruleId)
        local ruleNameLabel  = display.newLabel(0, 0, fontWithColor(3, {text = tostring(ruleConfInfo.name), ap = display.LEFT_CENTER}))
        local ruleLineImage  = display.newImageView(RES_DICT.INIT_RULE_LINE, 0, 0, {ap = display.LEFT_CENTER, scale9 = true})
        local ruleUnderFrame = display.newImageView(RES_DICT.INIT_RULE_UNDER, 0, 0, {size = RULE_UNDER_SIZE, scale9 = true})
        ruleIconNode:setScale(0.5)
        ruleIconNode:setPositionX(60)
        ruleIconNode:setPositionY(RULE_LAYER_GAP_B + INIT_RULE_LIST_H - (index-0.5) * INIT_RULE_CELL_H)
        ruleNameLabel:setPositionX(ruleIconNode:getPositionX() + 25)
        ruleNameLabel:setPositionY(ruleIconNode:getPositionY())
        ruleLineImage:setPositionX(ruleIconNode:getPositionX() - 25)
        ruleLineImage:setPositionY(ruleIconNode:getPositionY() - INIT_RULE_CELL_H/2)
        ruleUnderFrame:setPositionX(RULE_LAYER_SIZE.width/2)
        ruleUnderFrame:setPositionY(ruleIconNode:getPositionY())
        ruleLineImage:setContentSize(cc.size(RULE_LAYER_SIZE.width - 70, 2))
        self:getRuleViewData().ruleListLayer:addChild(ruleUnderFrame)
        self:getRuleViewData().ruleListLayer:addChild(ruleIconNode)
        self:getRuleViewData().ruleListLayer:addChild(ruleNameLabel)
        self:getRuleViewData().ruleListLayer:addChild(ruleLineImage)
        ruleUnderFrame:setName('ruleUnderFrame_' .. tostring(ruleId))
        ruleNameLabel:setName('ruleNameLabel_' .. tostring(ruleId))
        ruleIconNode:setName('ruleIconNode_' .. tostring(ruleId))
        ruleLineImage:setVisible(index ~= #ruleList)

        ruleUnderFrame:setVisible(false)
        ruleUnderFrame:runAction(cc.RepeatForever:create(cc.Sequence:create(
            cc.FadeTo:create(0.2, 55),
            cc.FadeTo:create(0.2, 255)
        )))

        local ruleNode   = ruleNodeList[index]
        local parentNPos = cc.p(ruleNode:getParent():convertToNodeSpaceAR(ruleListLayerWPos))
        ruleNode:setPosition(cc.p(
            parentNPos.x + ruleIconNode:getPositionX() - RULE_LAYER_SIZE.width/2, 
            parentNPos.y + ruleIconNode:getPositionY() - RULE_LAYER_SIZE.height/2
        ))
        ruleNode:setScale(0.5)
        ruleNode:setVisible(false)
        ruleNode:setGlobalZOrder(1)
        ruleNode.hidePos = cc.p(ruleNode:getPosition())
    end
end


function TTGameBattleView:updateHandCardsStatus(cardNodes, showPList, hidePList, usedCardIndexList)
    -- dump usedCardIndex
    local usedCardIndexMap = {}
    for _, cardIndex in ipairs(usedCardIndexList) do
        usedCardIndexMap[tostring(cardIndex)] = true
    end

    -- update all handCards
    local SHOW_CARD_TIME = 0.4
    for handIndex, cardNode in ipairs(cardNodes) do
        local showPos = showPList[handIndex]
        local hidePos = hidePList[handIndex]
        local isUsed  = usedCardIndexMap[tostring(handIndex)] == true
        
        if isUsed then
            if not cardNode.isUsed then
                cardNode.isUsed = true

                -- init views
                cardNode:stopAllActions()
                cardNode:setPosition(showPos)
                cardNode:setRotation(0)
                cardNode:setOpacity(255)
                cardNode:setScale(1)

                -- run action
                cardNode:runAction(cc.Spawn:create(
                    cc.EaseQuinticActionOut:create(cc.RotateTo:create(SHOW_CARD_TIME, 30)),
                    cc.EaseQuinticActionOut:create(cc.ScaleTo:create(SHOW_CARD_TIME, 2)),
                    cc.EaseQuinticActionOut:create(cc.FadeOut:create(SHOW_CARD_TIME)),
                    cc.EaseQuinticActionOut:create(cc.BezierTo:create(SHOW_CARD_TIME, {
                        cc.p(showPos.x, hidePos.y), -- start con pos
                        cc.p(showPos.x, hidePos.y), -- end con pos
                        hidePos,  -- end pos
                    }))
                ))
            end

        else
            if cardNode.isUsed then
                cardNode.isUsed = false
                
                -- init views
                cardNode:stopAllActions()
                cardNode:setPosition(hidePos)
                cardNode:setRotation(30)
                cardNode:setOpacity(0)
                cardNode:setScale(2)

                -- run action
                cardNode:runAction(cc.Spawn:create(
                    cc.EaseQuinticActionOut:create(cc.RotateTo:create(SHOW_CARD_TIME, 0)),
                    cc.EaseQuinticActionOut:create(cc.ScaleTo:create(SHOW_CARD_TIME, 1)),
                    cc.EaseQuinticActionOut:create(cc.FadeIn:create(SHOW_CARD_TIME)),
                    cc.EaseQuinticActionOut:create(cc.BezierTo:create(SHOW_CARD_TIME, {
                        cc.p(showPos.x, hidePos.y), -- start con pos
                        cc.p(showPos.x, hidePos.y), -- end con pos
                        showPos,  -- end pos
                    }))
                ))
            end
        end

    end
end


function TTGameBattleView:updateHandCardsAttrs(cardNodes, typeAttrMap, initAttrMap)
    for index, cardNode in ipairs(cardNodes) do
        local cardId      = cardNode:getCardId()
        local cardConf    = TTGameUtils.GetConfAt(TTGAME_DEFINE.CONF_TYPE.CARD_DEFINE, cardId)
        local cardType    = checkint(cardConf.type)
        local presetNum   = checkint(initAttrMap[tostring(cardType)])
        local offsetNum   = checkint(typeAttrMap[tostring(cardType)])
        local lastAttrMap = {}
        for index, value in ipairs(cardNode:getInitAttrList()) do
            lastAttrMap[tostring(index)] = math.max(1, value + offsetNum + presetNum)
        end
        cardNode:updateAttrs(lastAttrMap)
    end
end


-------------------------------------------------
-- operator cardNodes

function TTGameBattleView:getOperatorHandCardNodes()
    return self:getViewData().operatorCardNodes
end
function TTGameBattleView:getOperatorHandCardAreas()
    return self:getViewData().operatorCardAreas
end

function TTGameBattleView:initOperatorHandCard(cardNode, cardId)
    if cardNode then
        cardNode:setCardId(checkint(cardId))
    end
end
function TTGameBattleView:initOperatorHandCards(handCards)
    for index, cardNode in ipairs(self:getOperatorHandCardNodes()) do
        self:initOperatorHandCard(cardNode, checktable(handCards)[index])
    end
end

function TTGameBattleView:updateOperatorPlayCards(usedCardIndexList)
    self:updateHandCardsStatus(
        self:getOperatorHandCardNodes(),
        self:getViewData().operatorCardSPList,
        self:getViewData().operatorCardHPList,
        usedCardIndexList
    )
end
function TTGameBattleView:updateOperatorHandCard(typeAttrMap, initAttrMap)
    self:updateHandCardsAttrs(self:getOperatorHandCardNodes(), typeAttrMap, initAttrMap)
end


-------------------------------------------------
-- opponent cardNodes

function TTGameBattleView:getOpponentHandCardNodes()
    return self:getViewData().opponentCardNodes
end
function TTGameBattleView:getOpponentHandAreaNodes()
    return self:getViewData().opponentCardAreas
end

function TTGameBattleView:initOpponentHandCard(cardNode, cardId)
    if cardNode then
        cardNode:setCardId(checkint(cardId))
    end
end
function TTGameBattleView:initOpponentHandCards(handCards)
    for index, cardNode in ipairs(self:getOpponentHandCardNodes()) do
        self:initOpponentHandCard(cardNode, checktable(handCards)[index])
    end
end

function TTGameBattleView:updateOpponentPlayCards(usedCardIndexList)
    self:updateHandCardsStatus(
        self:getOpponentHandCardNodes(), 
        self:getViewData().opponentCardSPList,
        self:getViewData().opponentCardHPList,
        usedCardIndexList
    )
end
function TTGameBattleView:updateOpponentHandCard(typeAttrMap, initAttrMap)
    self:updateHandCardsAttrs(self:getOpponentHandCardNodes(), typeAttrMap, initAttrMap)
end


-------------------------------------------------
-- desk cell

function TTGameBattleView:getDeskCellVDList()
    return self.deskCellVDList_
end


function TTGameBattleView:showEmptyDeskCellStatus()
    for index, deskCellVD in ipairs(self:getDeskCellVDList()) do
        if checkint(deskCellVD.deskCardNode:getCardId()) == 0 then
            deskCellVD.selectedBgLayer:setVisible(true)
        end
    end
end
function TTGameBattleView:hideEmptyDeskCellStatus()
    for index, deskCellVD in ipairs(self:getDeskCellVDList()) do
        deskCellVD.selectedBgLayer:setVisible(false)
    end
end


function TTGameBattleView:updateDeskCellStatus(siteId, deskData, operatorId, finishCB)
    self.oldDeskDatas_[tostring(siteId)] = self.newDeskDatas_[tostring(siteId)] or {}
    self.newDeskDatas_[tostring(siteId)] = clone(deskData)

    local deskCellVD      = self:getDeskCellVDList()[siteId]
    local oldDeskData     = checktable(self.oldDeskDatas_[tostring(siteId)])
    local newDeskData     = checktable(self.newDeskDatas_[tostring(siteId)])
    local oldDeskCardId   = checkint(oldDeskData.battleCardId)
    local newDeskCardId   = checkint(newDeskData.battleCardId)
    local oldDeskOwnerId  = tostring(oldDeskData.ownerId)
    local newDeskOwnerId  = tostring(newDeskData.ownerId)
    local isAddNewCard    = oldDeskCardId <= 0 and newDeskCardId > 0
    local isRemoveCard    = oldDeskCardId > 0 and newDeskCardId <= 0
    local isChangeCard    = oldDeskCardId ~= newDeskCardId
    local isChangeOwner   = oldDeskOwnerId ~= newDeskOwnerId
    local isPriorAction   = isAddNewCard or isRemoveCard
    local isOperatorOwner = tostring(operatorId) == newDeskOwnerId

    if deskCellVD then
        local SHOW_CARD_TIME = 0.6
        local FLIP_CARD_TIME = 0.3
        local cardNodeAction = nil
        local bgFrameActions = nil

        -- update cardNode
        do
            -------------------------------------------------
            -- show card
            if isAddNewCard then
                -- update data
                deskCellVD.deskCardNode:setCardId(newDeskCardId)
                if deskData.initAttrMap then
                    deskCellVD.deskCardNode:updateAttrs(newDeskData.initAttrMap, true)
                end

                -- init views
                deskCellVD.deskCardNode:setPosition(deskCellVD.deskCardNodeHPos)
                deskCellVD.deskCardNode:setRotation(-30)
                deskCellVD.deskCardNode:setOpacity(0)
                deskCellVD.deskCardNode:setScale(2)
                
                if isOperatorOwner then
                    deskCellVD.deskCardNode:hideOpponentUnderFrame()
                    deskCellVD.deskCardNode:showOperatorUnderFrame()
                else
                    deskCellVD.deskCardNode:hideOperatorUnderFrame()
                    deskCellVD.deskCardNode:showOpponentUnderFrame()
                end

                -- run action
                cardNodeAction = cc.TargetedAction:create(deskCellVD.deskCardNode, cc.Sequence:create(
                    cc.Spawn:create(
                        cc.EaseQuinticActionOut:create(cc.RotateTo:create(SHOW_CARD_TIME, 0)),
                        cc.EaseQuinticActionOut:create(cc.ScaleTo:create(SHOW_CARD_TIME, 1)),
                        cc.EaseQuinticActionOut:create(cc.FadeIn:create(SHOW_CARD_TIME)),
                        cc.EaseQuinticActionOut:create(cc.BezierTo:create(SHOW_CARD_TIME, {
                            cc.p(deskCellVD.deskCardNodeSPos.x, deskCellVD.deskCardNodeHPos.y), -- start con pos
                            cc.p(deskCellVD.deskCardNodeSPos.x, deskCellVD.deskCardNodeHPos.y), -- end con pos
                            deskCellVD.deskCardNodeSPos,  -- end pos
                        }))
                    ),
                    cc.CallFunc:create(function()
                        deskCellVD.deskCardNode:updateAttrs(newDeskData.cardAttrs)
                    end)
                ))
                
            -------------------------------------------------
            -- remove card
            elseif isRemoveCard then
                -- init views
                deskCellVD.deskCardNode:setPosition(deskCellVD.deskCardNodeSPos)
                deskCellVD.deskCardNode:setRotation(0)
                deskCellVD.deskCardNode:setOpacity(255)
                deskCellVD.deskCardNode:setScale(1)

                -- run action
                cardNodeAction = cc.TargetedAction:create(deskCellVD.deskCardNode, cc.Sequence:create(
                    Spawn:create(
                        cc.EaseQuinticActionOut:create(cc.RotateTo:create(SHOW_CARD_TIME, -30)),
                        cc.EaseQuinticActionOut:create(cc.ScaleTo:create(SHOW_CARD_TIME, 2)),
                        cc.EaseQuinticActionOut:create(cc.FadeOut:create(SHOW_CARD_TIME)),
                        cc.EaseQuinticActionOut:create(cc.BezierTo:create(SHOW_CARD_TIME, {
                            cc.p(deskCellVD.deskCardNodeSPos.x, deskCellVD.deskCardNodeHPos.y), -- start con pos
                            cc.p(deskCellVD.deskCardNodeSPos.x, deskCellVD.deskCardNodeHPos.y), -- end con pos
                            deskCellVD.deskCardNodeHPos,  -- end pos
                        }))
                    ),
                    cc.CallFunc:create(function()
                        -- update data
                        deskCellVD.deskCardNode:setCardId(0)
                        deskCellVD.deskCardNode:updateAttrs(nil, true)
                    end)
                ))

            -------------------------------------------------
            -- change card
            elseif isChangeCard or isChangeOwner then
                cardNodeAction = cc.TargetedAction:create(deskCellVD.deskCardNode, cc.Sequence:create(
                    cc.CallFunc:create(function()
                        -- reset views
                        deskCellVD.deskCardNode:setPosition(deskCellVD.deskCardNodeSPos)
                        deskCellVD.deskCardNode:setRotation(0)
                        deskCellVD.deskCardNode:setOpacity(255)
                        deskCellVD.deskCardNode:setScale(1)
                    end),
                    cc.EaseQuinticActionOut:create(cc.ScaleTo:create(FLIP_CARD_TIME, 0, 1)),
                    cc.CallFunc:create(function()
                        -- update data
                        if isChangeCard then
                            deskCellVD.deskCardNode:setCardId(newDeskCardId)
                            deskCellVD.deskCardNode:updateAttrs(newDeskData.cardAttrs, true)
                        end
                        if isChangeOwner then
                            if isOperatorOwner then
                                deskCellVD.deskCardNode:hideOpponentUnderFrame()
                                deskCellVD.deskCardNode:showOperatorUnderFrame()
                            else
                                deskCellVD.deskCardNode:hideOperatorUnderFrame()
                                deskCellVD.deskCardNode:showOpponentUnderFrame()
                            end
                        end
                    end),
                    cc.EaseQuinticActionOut:create(cc.ScaleTo:create(FLIP_CARD_TIME, 1, 1)),
                    cc.CallFunc:create(function()
                        if isChangeOwner then
                            deskCellVD.deskCardNode:updateAttrs(newDeskData.cardAttrs)
                        end
                    end)
                ))

            -------------------------------------------------
            -- update attr
            else
                cardNodeAction = cc.CallFunc:create(function()
                    if deskCellVD.deskCardNode:getCardId() > 0 then
                        -- reset views
                        deskCellVD.deskCardNode:setPosition(deskCellVD.deskCardNodeSPos)
                        deskCellVD.deskCardNode:setRotation(0)
                        deskCellVD.deskCardNode:setOpacity(255)
                        deskCellVD.deskCardNode:setScale(1)
                        -- update data
                        deskCellVD.deskCardNode:updateAttrs(newDeskData.cardAttrs)
                    end
                end)
            end
        end


        -- update bgFrame
        do
            local updatedBgFrame = isOperatorOwner and deskCellVD.operatorBgLayer or deskCellVD.opponentBgLayer
            local reverseBgFrame = isOperatorOwner and deskCellVD.opponentBgLayer or deskCellVD.operatorBgLayer

            -------------------------------------------------
            -- show bgFrame
            if isAddNewCard then
                updatedBgFrame:setOpacity(0)
                reverseBgFrame:setOpacity(0)

                bgFrameActions = {
                    cc.TargetedAction:create(updatedBgFrame, cc.Sequence:create(
                        cc.DelayTime:create(SHOW_CARD_TIME/2),
                        cc.FadeIn:create(SHOW_CARD_TIME/2)
                    ))
                }

            -------------------------------------------------
            -- remove bgFrame
            elseif isRemoveCard then
                updatedBgFrame:setOpacity(255)
                reverseBgFrame:setOpacity(0)

                bgFrameActions = {
                    cc.TargetedAction:create(updatedBgFrame, cc.Sequence:create(
                        cc.DelayTime:create(SHOW_CARD_TIME/2),
                        cc.FadeOut:create(SHOW_CARD_TIME/2)
                    ))
                }

            -------------------------------------------------
            -- change owner
            elseif isChangeOwner then
                bgFrameActions = {
                    cc.CallFunc:create(function()
                        reverseBgFrame:setOpacity(255)
                        updatedBgFrame:setOpacity(0)
                    end),
                    cc.TargetedAction:create(reverseBgFrame, cc.Sequence:create(
                        cc.DelayTime:create(FLIP_CARD_TIME),
                        cc.FadeOut:create(FLIP_CARD_TIME)
                    )),
                    cc.TargetedAction:create(updatedBgFrame, cc.Sequence:create(
                        cc.DelayTime:create(FLIP_CARD_TIME),
                        cc.FadeIn:create(FLIP_CARD_TIME)
                    ))
                }
            end
        end


        -- deskCell runAction
        local deckActionList = {}
        if cardNodeAction then
            table.insert(deckActionList, cardNodeAction)
        end
        for _, bgFrameAction in ipairs(bgFrameActions or {}) do
            table.insert(deckActionList, bgFrameAction)
        end

        if #deckActionList > 0 then
            deskCellVD.view:stopAllActions()
            if isPriorAction then
                deskCellVD.view:runAction(cc.Sequence:create(
                    cc.Spawn:create(deckActionList),
                    cc.DelayTime:create(0.2),
                    cc.CallFunc:create(function()
                        if finishCB then finishCB() end
                    end)
                ))
            else
                deskCellVD.view:runAction(cc.Sequence:create(
                    cc.DelayTime:create(SHOW_CARD_TIME),
                    cc.Spawn:create(deckActionList),
                    cc.DelayTime:create(0.2),
                    cc.CallFunc:create(function()
                        if finishCB then finishCB() end
                    end)
                ))
            end
        end

    end
end


-------------------------------------------------
-- rule view

function TTGameBattleView:showInitRuleView(finishCB)
    self:getRuleViewData().ruleLayerNode:setScaleX(1)
    self:getRuleViewData().ruleLayerNode:setScaleY(0)

    self:getRuleViewData().view:stopAllActions()
    self:getRuleViewData().view:runAction(cc.Sequence:create(
        cc.TargetedAction:create(self:getRuleViewData().ruleLayerNode, cc.EaseQuinticActionOut:create(cc.ScaleTo:create(0.4, 1, 1))),
        cc.CallFunc:create(function()
            if finishCB then finishCB() end
        end)
    ))
end
function TTGameBattleView:hideInitRuleView(finishCB)
    self:getRuleViewData().ruleLayerNode:setScaleX(1)
    self:getRuleViewData().ruleLayerNode:setScaleY(1)

    local PANEL_CLOSE_TIME = 0.4
    local RULE_ICON_TIME   = 0.4
    local ruleNodeActList  = {
        cc.TargetedAction:create(self:getRuleViewData().ruleLayerNode, cc.EaseCubicActionIn:create(cc.ScaleTo:create(PANEL_CLOSE_TIME, 1, 0)))
    }
    local ruleIconCount = self:getViewData().ruleIconLayer:getChildrenCount()
    for index, ruleNode in ipairs(self:getViewData().ruleIconLayer:getChildren()) do
        table.insert(ruleNodeActList, cc.TargetedAction:create(ruleNode, cc.Sequence:create(
            cc.Show:create(),
            cc.DelayTime:create(PANEL_CLOSE_TIME + (ruleIconCount-index+1) * 0.05),
            cc.Spawn:create(
                cc.EaseQuinticActionOut:create(cc.MoveTo:create(RULE_ICON_TIME, ruleNode.showPos)),
                cc.EaseQuinticActionOut:create(cc.ScaleTo:create(RULE_ICON_TIME, 1))
            ),
            cc.CallFunc:create(function()
                ruleNode:setGlobalZOrder(0)
            end)
        )))
    end

    self:getRuleViewData().view:stopAllActions()
    self:getRuleViewData().view:runAction(cc.Sequence:create(
        cc.Spawn:create(ruleNodeActList),
        cc.CallFunc:create(function()
            if finishCB then finishCB() end
        end)
    ))
end
function TTGameBattleView:hintInitRuleNode(ruleId)
    local ruleUnderName = 'ruleUnderFrame_' .. tostring(ruleId)
    local ruleUnderNode = self:getRuleViewData().ruleListLayer:getChildByName(ruleUnderName)

    for _, childNode in ipairs(self:getRuleViewData().ruleListLayer:getChildren()) do
        local childName = tostring(childNode:getName())
        if string.find(childName, 'ruleUnderFrame_') then
            childNode:setVisible(false)
        end
    end

    if ruleUnderNode and not tolua.isnull(ruleUnderNode) then
        ruleUnderNode:setVisible(true)
    end
end


return TTGameBattleView

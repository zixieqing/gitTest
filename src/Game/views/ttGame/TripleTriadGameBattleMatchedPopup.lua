--[[
 * author : kaishiqi
 * descpt : 打牌游戏 - 战斗匹配弹窗
]]
local TTGameBattleMatchedPopup = class('TripleTriadGameBattleMatchedPopup', function()
    return display.newLayer(0, 0, {name = 'TripleTriadGameBattleMatchedPopup'})
end)

local RES_DICT = {
    OPERATOR_CARD_FRAME = _res('ui/ttgame/battle/cardgame_battle_bg_show_blue.png'),
    OPPONENT_CARD_FRAME = _res('ui/ttgame/battle/cardgame_battle_bg_show_red.png'),
    SPECIAL_CARD_FRAME  = _res('ui/ttgame/battle/cardgame_battle_bg_show_npc.png'),
    OPERATOR_NAME_BAR   = _res('ui/ttgame/battle/cardgame_battle_label_show_blue.png'),
    OPPONENT_NAME_BAR   = _res('ui/ttgame/battle/cardgame_battle_label_show_red.png'),
    SPECIAL_NAME_BAR    = _res('ui/ttgame/battle/cardgame_battle_label_show_npc.png'),
    SPECIAL_TITLE_BAR   = _res('ui/ttgame/battle/cardgame_battle_label_title_npc.png'),
    MATCHED_VS_SPINE    = _spn('ui/ttgame/battle/starplan_vs'),
}

local CreateView = nil


function TTGameBattleMatchedPopup:ctor(args)
    self:setAnchorPoint(display.CENTER)

    -- init vars
    self.isUsedPveRule_  = args.isUsedPveRule == true
    self.operatorModel_  = args.operatorModel
    self.opponentModel_  = args.opponentModel
    self.closeCallback_  = args.closeCB
    self.isControllable_ = true

    -- create view
    self.viewData_ = CreateView(self.isUsedPveRule_)
    self:addChild(self.viewData_.view)

    -- update view
    self:updateBgImage_()
    display.commonLabelParams(self:getViewData().operatorNameLabel, {text = self.operatorModel_ and self.operatorModel_:getName() or '???'})
    display.commonLabelParams(self:getViewData().opponentNameLabel, {text = self.opponentModel_ and self.opponentModel_:getName() or '???'})
    
    for index, cardNode in ipairs(self:getViewData().operatorCardNodes) do
        local cardId = checkint(self.operatorModel_ and self.operatorModel_:getCards()[index] or 0)
        cardNode:setVisible(cardId > 0)
        cardNode:setCardId(cardId)
    end
    
    for index, cardNode in ipairs(self:getViewData().opponentCardNodes) do
        local cardId = checkint(self.opponentModel_ and self.opponentModel_:getCards()[index] or 0)
        cardNode:setVisible(cardId > 0)
        cardNode:setCardId(cardId)
    end
    
    self:show()
end


CreateView = function(isSpecial)
    local view = display.newLayer()
    local size = view:getContentSize()

    -- block layer
    view:addChild(display.newLayer(0, 0, {size = size, color = cc.c4b(0,0,0,0), enable = true}))

    local bgImgLayer = display.newLayer(size.width/2, size.height/2)
    view:addChild(bgImgLayer)

    local blackLayer = display.newLayer(0, 0, {color = cc.c4b(0,0,0,150)})
    view:addChild(blackLayer)


    -------------------------------------------------[operator]
    local FRAME_OFFSET_X = 35
    local CENTER_DIST_X  = 80
    local CENTER_DIST_Y  = 180
    local matchCardSize  = cc.size(202, 230)
    local operatorLayer  = display.newLayer()
    view:addChild(operatorLayer) 

    -- operator frame
    local operatorCardCPos   = cc.p(size.width/2 - CENTER_DIST_X, size.height/2 - CENTER_DIST_Y)
    local operatorCardsFrame = display.newImageView(RES_DICT.OPERATOR_CARD_FRAME, 0, 0, {ap = display.RIGHT_BOTTOM})
    local operatorCardsFSize = operatorCardsFrame:getContentSize()
    operatorCardsFrame:setPositionX(operatorCardCPos.x + operatorCardsFSize.width/2)
    operatorCardsFrame:setPositionY(operatorCardCPos.y - matchCardSize.height/2 - FRAME_OFFSET_X)
    operatorLayer:addChild(operatorCardsFrame)
    
    -- operator cards
    local operatorCardNodes   = {}
    local operatorCardSPList  = {}
    local operatorCardHPList  = {}
    local operatorCardOffsetX = -matchCardSize.width * (TTGAME_DEFINE.DECK_CARD_NUM/2-0.5)
    for i = 1, TTGAME_DEFINE.DECK_CARD_NUM do
        local cardNode = TTGameUtils.GetBattleCardNode({zoomModel1 = 'm'})
        cardNode:setPositionX(operatorCardCPos.x + operatorCardOffsetX + (i-1) * matchCardSize.width)
        cardNode:setPositionY(operatorCardCPos.y)
        cardNode:showOperatorUnderFrame()
        table.insert(operatorCardHPList, cc.p(cardNode:getPositionX() - display.width, cardNode:getPositionY()))
        table.insert(operatorCardSPList, cc.p(cardNode:getPosition()))
        table.insert(operatorCardNodes, cardNode)
        operatorLayer:addChild(cardNode)
    end

    -- operator name
    local operatorNameBar = display.newImageView(RES_DICT.OPERATOR_NAME_BAR, operatorCardCPos.x + operatorCardsFSize.width/2 - 5, operatorCardCPos.y + matchCardSize.height/2 + 20, {ap = display.RIGHT_CENTER})
    operatorLayer:addChild(operatorNameBar)

    local operatorNameLabel = display.newLabel(operatorNameBar:getContentSize().width - 10, operatorNameBar:getContentSize().height/2, fontWithColor(18, {ap = display.RIGHT_CENTER, text = '----'}))
    operatorNameBar:addChild(operatorNameLabel)
    

    -------------------------------------------------[opponent]
    local opponentLayer = display.newLayer()
    view:addChild(opponentLayer)

    -- opponent frame
    local opponentCardCPos   = cc.p(size.width/2 + CENTER_DIST_X, size.height/2 + CENTER_DIST_Y)
    local opponentCardsFrame = display.newImageView(isSpecial and RES_DICT.SPECIAL_CARD_FRAME or RES_DICT.OPPONENT_CARD_FRAME, 0, 0, {ap = display.LEFT_BOTTOM})
    local opponentCardsFSize = opponentCardsFrame:getContentSize()
    opponentCardsFrame:setPositionX(opponentCardCPos.x - opponentCardsFSize.width/2)
    opponentCardsFrame:setPositionY(opponentCardCPos.y - matchCardSize.height/2 - FRAME_OFFSET_X)
    opponentLayer:addChild(opponentCardsFrame)
    
    -- opponent cards
    local opponentCardNodes   = {}
    local opponentCardSPList  = {}
    local opponentCardHPList  = {}
    local opponentCardOffsetX = -operatorCardOffsetX
    for i = 1, TTGAME_DEFINE.DECK_CARD_NUM do
        local cardNode = TTGameUtils.GetBattleCardNode({zoomModel1 = 'm'})
        cardNode:setPositionX(opponentCardCPos.x + opponentCardOffsetX - (i-1) * matchCardSize.width)
        cardNode:setPositionY(opponentCardCPos.y)
        cardNode:showOpponentUnderFrame()
        table.insert(opponentCardHPList, cc.p(cardNode:getPositionX() + display.width, cardNode:getPositionY()))
        table.insert(opponentCardSPList, cc.p(cardNode:getPosition()))
        table.insert(opponentCardNodes, cardNode)
        opponentLayer:addChild(cardNode)
        cardNode:toCardBackStatus()
    end

    -- opponent name
    local opponentNameBar = display.newImageView(isSpecial and RES_DICT.SPECIAL_NAME_BAR or RES_DICT.OPPONENT_NAME_BAR, opponentCardCPos.x - opponentCardsFSize.width/2 + 10, opponentCardCPos.y - matchCardSize.height/2 - 38, {ap = display.LEFT_CENTER})
    opponentLayer:addChild(opponentNameBar)

    local opponentNameLabel = display.newLabel(10, opponentNameBar:getContentSize().height/2, fontWithColor(18, {ap = display.LEFT_CENTER, text = '----'}))
    opponentNameBar:addChild(opponentNameLabel)

    -- opponent title
    local opponentTitleBar = display.newImageView(RES_DICT.SPECIAL_TITLE_BAR, opponentNameBar:getPositionX(), opponentCardCPos.y + matchCardSize.height/2 + 20, {ap = display.LEFT_CENTER})
    opponentLayer:addChild(opponentTitleBar)
    opponentTitleBar:setVisible(isSpecial)
    
    local opponentTitleLabel = display.newLabel(60, opponentTitleBar:getContentSize().height/2, fontWithColor(2, {color = '#f6c886', ap = display.LEFT_CENTER, text = __('牌王')}))
    opponentTitleBar:addChild(opponentTitleLabel)


    -------------------------------------------------[vs]
    local vsTypeLayer = display.newLayer(size.width/2, size.height/2 - 15)
    view:addChild(vsTypeLayer)

    local matchVsSpine = TTGameUtils.CreateSpine(RES_DICT.MATCHED_VS_SPINE)
    vsTypeLayer:addChild(matchVsSpine)


    return {
        view               = view,
        bgImgLayer         = bgImgLayer,
        blackLayer         = blackLayer,
        vsTypeLayer        = vsTypeLayer,
        matchVsSpine       = matchVsSpine,
        --                 = operator
        operatorLayer      = operatorLayer,
        operatorLayerSPos  = cc.p(operatorLayer:getPosition()),
        operatorLayerIPos  = cc.p(operatorLayer:getPositionX() - display.cx, operatorLayer:getPositionY()),
        operatorLayerHPos  = cc.p(operatorLayer:getPositionX() + display.width, operatorLayer:getPositionY()),
        operatorCardNodes  = operatorCardNodes,
        operatorNameLabel  = operatorNameLabel,
        operatorCardsFrame = operatorCardsFrame,
        operatorCardSPList = operatorCardSPList,
        operatorCardHPList = operatorCardHPList,
        --                 = opponent
        opponentLayer      = opponentLayer,
        opponentLayerSPos  = cc.p(opponentLayer:getPosition()),
        opponentLayerIPos  = cc.p(opponentLayer:getPositionX() + display.cx, opponentLayer:getPositionY()),
        opponentLayerHPos  = cc.p(opponentLayer:getPositionX() - display.width, opponentLayer:getPositionY()),
        opponentCardNodes  = opponentCardNodes,
        opponentNameLabel  = opponentNameLabel,
        opponentCardsFrame = opponentCardsFrame,
        opponentCardSPList = opponentCardSPList,
        opponentCardHPList = opponentCardHPList,
    }
end


function TTGameBattleMatchedPopup:getViewData()
    return self.viewData_
end


-------------------------------------------------
-- public

function TTGameBattleMatchedPopup:show()
    -- init
    self:stopAllActions()
    self:getViewData().bgImgLayer:setOpacity(0)
    self:getViewData().blackLayer:setOpacity(0)
    self:getViewData().matchVsSpine:setVisible(false)
    self:getViewData().operatorLayer:setPosition(self:getViewData().operatorLayerIPos)
    self:getViewData().opponentLayer:setPosition(self:getViewData().opponentLayerIPos)
    self:getViewData().operatorCardsFrame:setSkewX(-30)
    self:getViewData().opponentCardsFrame:setSkewX(30)

    local SHOW_CARDS_TIME = 0.2
    local SHOW_FRAME_TIME = 0.2
    local MATCH_VS_TIME   = 1.0
    local ALL_HIDE_TIME   = 0.3
    local showCardActList = {}
    for index, cardNode in ipairs(self:getViewData().operatorCardNodes) do
        cardNode:setPosition(self:getViewData().operatorCardHPList[index])
        cardNode:setRotation(-45)
        
        table.insert(showCardActList, cc.TargetedAction:create(cardNode, cc.Sequence:create(
            cc.DelayTime:create((#self:getViewData().operatorCardNodes-index+1) * 0.05),
            cc.Spawn:create(
                cc.MoveTo:create(SHOW_CARDS_TIME, self:getViewData().operatorCardSPList[index]),
                cc.RotateTo:create(SHOW_CARDS_TIME, 0)
            )
        )))
    end
    for index, cardNode in ipairs(self:getViewData().opponentCardNodes) do
        cardNode:setPosition(self:getViewData().opponentCardHPList[index])
        cardNode:setRotation(45)

        table.insert(showCardActList, cc.TargetedAction:create(cardNode, cc.Sequence:create(
            cc.DelayTime:create((#self:getViewData().opponentCardNodes-index+1) * 0.05),
            cc.Spawn:create(
                cc.MoveTo:create(SHOW_CARDS_TIME, self:getViewData().opponentCardSPList[index]),
                cc.RotateTo:create(SHOW_CARDS_TIME, 0)
            )
        )))
    end

    -- run
    self:runAction(cc.Sequence:create(
        cc.Spawn:create(
            cc.TargetedAction:create(self:getViewData().bgImgLayer, cc.FadeIn:create(SHOW_FRAME_TIME)),
            cc.TargetedAction:create(self:getViewData().blackLayer, cc.FadeTo:create(SHOW_FRAME_TIME, 150)),
            cc.TargetedAction:create(self:getViewData().operatorLayer, cc.EaseCubicActionOut:create(cc.MoveTo:create(SHOW_FRAME_TIME, self:getViewData().operatorLayerSPos))),
            cc.TargetedAction:create(self:getViewData().opponentLayer, cc.EaseCubicActionOut:create(cc.MoveTo:create(SHOW_FRAME_TIME, self:getViewData().opponentLayerSPos)))
        ),
        cc.Spawn:create(
            cc.TargetedAction:create(self:getViewData().operatorCardsFrame, cc.EaseBackOut:create(cc.SkewTo:create(SHOW_CARDS_TIME, 0, 0))),
            cc.TargetedAction:create(self:getViewData().opponentCardsFrame, cc.EaseBackOut:create(cc.SkewTo:create(SHOW_CARDS_TIME, 0, 0))),
            unpack(showCardActList)
        ),
        cc.CallFunc:create(function()
            self:getViewData().matchVsSpine:setVisible(true)
            self:getViewData().matchVsSpine:setAnimation(0, 'play2', false)
            self:getViewData().matchVsSpine:addAnimation(0, 'idle', true)
        end),
        cc.Spawn:create(
            cc.TargetedAction:create(self:getViewData().operatorLayer, cc.MoveBy:create(MATCH_VS_TIME, cc.p(MATCH_VS_TIME*8, 0))),
            cc.TargetedAction:create(self:getViewData().opponentLayer, cc.MoveBy:create(MATCH_VS_TIME, cc.p(-MATCH_VS_TIME*8, 0)))
        ),
        cc.Spawn:create(
            cc.TargetedAction:create(self:getViewData().bgImgLayer, cc.FadeOut:create(ALL_HIDE_TIME)),
            cc.TargetedAction:create(self:getViewData().blackLayer, cc.FadeOut:create(ALL_HIDE_TIME)),
            cc.TargetedAction:create(self:getViewData().matchVsSpine, cc.EaseCubicActionIn:create(cc.FadeOut:create(ALL_HIDE_TIME))),
            cc.TargetedAction:create(self:getViewData().matchVsSpine, cc.EaseCubicActionIn:create(cc.ScaleTo:create(ALL_HIDE_TIME, 0))),
            cc.TargetedAction:create(self:getViewData().operatorLayer, cc.EaseCubicActionIn:create(cc.MoveBy:create(ALL_HIDE_TIME, self:getViewData().operatorLayerHPos))),
            cc.TargetedAction:create(self:getViewData().opponentLayer, cc.EaseCubicActionIn:create(cc.MoveBy:create(ALL_HIDE_TIME, self:getViewData().opponentLayerHPos)))
        ),
        cc.CallFunc:create(function()
            self:close()
        end)
    ))
end


function TTGameBattleMatchedPopup:close()
    if self.closeCallback_ then
        self.closeCallback_()
    end
    self:runAction(cc.RemoveSelf:create())
end


-------------------------------------------------
-- private

function TTGameBattleMatchedPopup:updateBgImage_()
    local bgImageName = 'main_bg_69'
    if self.isUsedPveRule_ then
        local activityConfInfo = TTGameUtils.GetConfAt(TTGAME_DEFINE.CONF_TYPE.ACTIVITY, app.ttGameMgr:getSummaryId())
        bgImageName = activityConfInfo.picture
    end
    local bgImagePath = _res(string.fmt('arts/stage/bg/%1.jpg', bgImageName))
    self:getViewData().bgImgLayer:removeAllChildren()
    self:getViewData().bgImgLayer:addChild(display.newImageView(bgImagePath))
end


return TTGameBattleMatchedPopup

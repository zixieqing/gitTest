--[[
 * author : kaishiqi
 * descpt : 打牌游戏 - 战斗结果弹窗
]]
local TTGameBattleResultPopup = class('TripleTriadGameBattleResultPopup', function()
    return display.newLayer(0, 0, {name = 'TripleTriadGameBattleResultPopup'})
end)

local RES_DICT = {
    COMMON_BTN_N         = _res('ui/common/common_btn_orange.png'),
    OPERATOR_SCORE_FRAME = _res('ui/ttgame/battle/cardgame_battle_btn_score_blue.png'),
    OPPONENT_SCORE_FRAME = _res('ui/ttgame/battle/cardgame_battle_btn_score_red.png'),
    RESULT_SPINE         = _spn('ui/ttgame/battle/cardgame_battle_result'),
}

local CreateView = nil


function TTGameBattleResultPopup:ctor(args)
    self:setAnchorPoint(display.CENTER)

    -- init vars
    self.battleResult_   = checkint(args.result)
    self.totalRewards_   = checktable(args.rewards)
    self.rewardIndex_    = checkint(args.rewardIndex)
    self.operatorScore_  = checkint(args.operatorScore)
    self.opponentScore_  = checkint(args.opponentScore)
    self.closeCallback_  = args.closeCB
    self.isControllable_ = true

    -- create view
    self.viewData_ = CreateView()
    self:addChild(self.viewData_.view)

    -- add listener
    display.commonUIParams(self:getViewData().closeBtn, {cb = handler(self, self.onClickCloseButtonHandler_)})

    -- update view
    display.commonLabelParams(self:getViewData().operatorScoreLabel, {text = tostring(self.operatorScore_)})
    display.commonLabelParams(self:getViewData().opponentScoreLabel, {text = tostring(self.opponentScore_)})

    self:show()
end


CreateView = function()
    local view = display.newLayer()
    local size = view:getContentSize()

    -- block layer
    view:addChild(display.newLayer(0, 0, {size = size, color = cc.c4b(0,0,0,0), enable = true}))

    local blackBgLayer = display.newLayer(0, 0, {size = size, color = cc.c4b(0,0,0,150)})
    view:addChild(blackBgLayer)


    -------------------------------------------------[result]
    local allResultLayer = display.newLayer()
    view:addChild(allResultLayer)

    -- result spine
    local resultSpine = TTGameUtils.CreateSpine(RES_DICT.RESULT_SPINE)
    resultSpine:setPositionX(display.cx)
    resultSpine:setPositionY(display.cy)
    allResultLayer:addChild(resultSpine)
    

    -- result layer
    local winLayer  = display.newLayer(size.width/2, size.height/2)
    local drawLayer = display.newLayer(size.width/2, size.height/2)
    local failLayer = display.newLayer(size.width/2, size.height/2)
    allResultLayer:addChild(failLayer)
    allResultLayer:addChild(drawLayer)
    allResultLayer:addChild(winLayer)
    
    -- result text
    local winLabel  = display.newLabel(0, 0, fontWithColor(20, {fontSize = 80, outline = '#2b1f74', outlineSize = 5, text = __('胜利')}))
    local drawLabel = display.newLabel(0, 0, fontWithColor(20, {fontSize = 80, outline = '#896d23', outlineSize = 5, text = __('平局')}))
    local failLabel = display.newLabel(0, 0, fontWithColor(20, {fontSize = 80, outline = '#372a2a', outlineSize = 5, text = __('失败')}))
    winLayer:addChild(winLabel)
    drawLayer:addChild(drawLabel)
    failLayer:addChild(failLabel)


    -- score layer
    local operatorScoreLayer = display.newLayer(size.width/2 + 350, size.height/2)
    local opponentScoreLayer = display.newLayer(size.width/2 - 350, size.height/2)
    allResultLayer:addChild(operatorScoreLayer)
    allResultLayer:addChild(opponentScoreLayer)

    -- score frame
    local operatorScoreFrame = display.newImageView(RES_DICT.OPERATOR_SCORE_FRAME)
    local opponentScoreFrame = display.newImageView(RES_DICT.OPPONENT_SCORE_FRAME)
    operatorScoreLayer:addChild(operatorScoreFrame)
    opponentScoreLayer:addChild(opponentScoreFrame)
    
    -- score label
    local operatorScoreLabel = display.newLabel(0, 0, fontWithColor(7, {fontSize = 96, text = '-'}))
    local opponentScoreLabel = display.newLabel(0, 0, fontWithColor(7, {fontSize = 96, text = '-'}))
    operatorScoreLayer:addChild(operatorScoreLabel)
    opponentScoreLayer:addChild(opponentScoreLabel)


    -------------------------------------------------[rewards]
    local closeBtn = display.newButton(size.width/2, size.height/5, {n = RES_DICT.COMMON_BTN_N})
    display.commonLabelParams(closeBtn, fontWithColor(14, {text = __('返回')}))
    view:addChild(closeBtn)


    return {
        view                   = view,
        blackBgLayer           = blackBgLayer,
        allResultLayer         = allResultLayer,
        resultSpine            = resultSpine,
        winLayer               = winLayer,
        drawLayer              = drawLayer,
        failLayer              = failLayer,
        winLabel               = winLabel,
        drawLabel              = drawLabel,
        failLabel              = failLabel,
        operatorScoreLayer     = operatorScoreLayer,
        opponentScoreLayer     = opponentScoreLayer,
        operatorScoreLabel     = operatorScoreLabel,
        opponentScoreLabel     = opponentScoreLabel,
        winScoreScaleScale1    = 1.5,
        winScoreScaleScale2    = 1.2,
        drawScoreScaleScale    = 1,
        failScoreScaleScale    = 0.8,
        operatorScoreLayerSPos = cc.p(operatorScoreLayer:getPosition()),
        operatorScoreLayerHPos = cc.p(operatorScoreLayer:getPositionX(), operatorScoreLayer:getPositionY() - display.cy - 100),
        opponentScoreLayerSPos = cc.p(opponentScoreLayer:getPosition()),
        opponentScoreLayerHPos = cc.p(opponentScoreLayer:getPositionX(), opponentScoreLayer:getPositionY() + display.cy + 100),
        closeBtn               = closeBtn,
    }
end


function TTGameBattleResultPopup:getViewData()
    return self.viewData_
end


-------------------------------------------------
-- public

function TTGameBattleResultPopup:show()
    -- init
    self:getViewData().blackBgLayer:setOpacity(0)
    self:getViewData().resultSpine:setVisible(false)
    self:getViewData().closeBtn:setVisible(false)
    self:getViewData().winLayer:setVisible(false)
    self:getViewData().drawLayer:setVisible(false)
    self:getViewData().failLayer:setVisible(false)
    self:getViewData().operatorScoreLayer:setPosition(self:getViewData().operatorScoreLayerHPos)
    self:getViewData().opponentScoreLayer:setPosition(self:getViewData().opponentScoreLayerHPos)

    local SHOW_TIME    = 0.4
    local SCALE_TIME   = 0.6
    local RESULT_TIME  = 0.4
    local drawScoreAct = cc.EaseCubicActionOut:create(cc.ScaleTo:create(SCALE_TIME, self:getViewData().drawScoreScaleScale))
    local loseScoreAct = cc.EaseCubicActionOut:create(cc.ScaleTo:create(SCALE_TIME, self:getViewData().failScoreScaleScale))
    local winScoreAct  = cc.Sequence:create(
        cc.EaseCubicActionOut:create(cc.ScaleTo:create(SCALE_TIME/2, self:getViewData().winScoreScaleScale1)),
        cc.EaseCubicActionOut:create(cc.ScaleTo:create(SCALE_TIME/2, self:getViewData().winScoreScaleScale2))
    )
    local operatorScoreLayerScaleAct = drawScoreAct
    local opponentScoreLayerScaleAct = drawScoreAct
    if self.battleResult_ == TTGAME_DEFINE.RESULT_TYPE.WIN then
        self:getViewData().resultLayer = self:getViewData().winLayer
        operatorScoreLayerScaleAct = winScoreAct
        opponentScoreLayerScaleAct = loseScoreAct
    elseif self.battleResult_ == TTGAME_DEFINE.RESULT_TYPE.DRAW then
        self:getViewData().resultLayer = self:getViewData().drawLayer
    else
        self:getViewData().resultLayer = self:getViewData().failLayer
        operatorScoreLayerScaleAct = loseScoreAct
        opponentScoreLayerScaleAct = winScoreAct
    end
    self:getViewData().resultLayer:setVisible(true)
    self:getViewData().resultLayer:setRotation(-30)
    self:getViewData().resultLayer:setOpacity(0)
    self:getViewData().resultLayer:setScale(5)

    -- run
    self:runAction(cc.Sequence:create(
        cc.DelayTime:create(1.5),
        cc.Spawn:create(
            cc.TargetedAction:create(self:getViewData().operatorScoreLayer, cc.Spawn:create(
                cc.EaseBackOut:create(cc.MoveTo:create(SHOW_TIME, self:getViewData().operatorScoreLayerSPos)),
                cc.EaseBackOut:create(cc.RotateBy:create(SHOW_TIME, -360))
            )),
            cc.TargetedAction:create(self:getViewData().opponentScoreLayer, cc.Spawn:create(
                cc.EaseBackOut:create(cc.MoveTo:create(SHOW_TIME, self:getViewData().opponentScoreLayerSPos)),
                cc.EaseBackOut:create(cc.RotateBy:create(SHOW_TIME, 360))
            )),
            cc.TargetedAction:create(self:getViewData().blackBgLayer, cc.FadeTo:create(SHOW_TIME, 150))
        ),
        cc.DelayTime:create(0.2),
        cc.CallFunc:create(function()
            self:getViewData().resultSpine:setVisible(true)
            if self.battleResult_ == TTGAME_DEFINE.RESULT_TYPE.WIN then
                self:getViewData().resultSpine:setAnimation(0, 'win', false)
            elseif self.battleResult_ == TTGAME_DEFINE.RESULT_TYPE.DRAW then
                self:getViewData().resultSpine:setAnimation(0, 'draw', false)
            else
                self:getViewData().resultSpine:setAnimation(0, 'lose', false)
            end
        end),
        cc.Spawn:create(
            cc.TargetedAction:create(self:getViewData().operatorScoreLayer, operatorScoreLayerScaleAct),
            cc.TargetedAction:create(self:getViewData().opponentScoreLayer, opponentScoreLayerScaleAct)
        ),
        cc.TargetedAction:create(self:getViewData().resultLayer, cc.Spawn:create(
            cc.EaseBackOut:create(cc.RotateTo:create(RESULT_TIME, 0)),
            cc.EaseBackOut:create(cc.ScaleTo:create(RESULT_TIME, 1)),
            cc.FadeIn:create(RESULT_TIME)
        )),
        cc.DelayTime:create(0.5),
        cc.CallFunc:create(function()
            local rewardData = self.totalRewards_[math.max(self.rewardIndex_, 1)] or {}
            if next(rewardData) ~= nil then
                app.uiMgr:AddDialog('Game.views.ttGame.TripleTriadGameResultRewardsPopup', {
                    totalRewards = self.totalRewards_,
                    rewardIndex  = self.rewardIndex_,
                    closeCB      = function()
                        self:close()
                    end
                })
            else
                self:getViewData().closeBtn:setVisible(true)
            end
        end)
    ))
end


function TTGameBattleResultPopup:close()
    if self.closeCallback_ then
        self.closeCallback_()
    end
    self:runAction(cc.RemoveSelf:create())
end


function TTGameBattleResultPopup:onClickCloseButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end

    self:close()
end


return TTGameBattleResultPopup

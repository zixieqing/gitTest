--[[
 * author : kaishiqi
 * descpt : 打牌游戏 - 战斗中介者
]]
local TTGameMoodLayer      = require('Game.views.ttGame.TripleTriadGameMoodEmoticonLayer')
local TTGameBattleView     = require('Game.views.ttGame.TripleTriadGameBattleView')
local TTGameAnimatePopup   = require('Game.views.ttGame.TripleTriadGameBattleAnimatePopup')
local TTGameBattleMediator = class('TripleTriadGameBattleMediator', mvc.Mediator)

local PLAY_ORDER_RULE_ID    = 8 -- 秩序规则id
local TYPE_INCREASE_RULE_ID = 6 -- 强化规则id
local TYPE_DECREASE_RULE_ID = 10 -- 弱化规则id

local FLIP_CARDS_DEFINE = {
    ['1'] = 2, -- 二明牌
    ['2'] = 3, -- 三明牌
    ['3'] = 5, -- 全明牌
}


function TTGameBattleMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'TripleTriadGameBattleMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end


-------------------------------------------------
-- inheritance

function TTGameBattleMediator:Initial(key)
    self.super.Initial(self, key)
    
    -- init vars
    self.initRuleIndex_       = 1
    self.isControllable_      = true
    self.delaySignalList_     = {}
    self.isBattleGameOver_    = false
    self.isAnimateRunning_    = false
    self.battleModel_         = self.ctorArgs_.battleModel
    self.closeCallback_       = self.ctorArgs_.closeCB
    self.customCloseCallback_ = self.ctorArgs_.customCloseCB
    self.battleRuleMap_       = {}
    table.insert(self:getBattleModel():getInitRuleEffects(), {order      = true}) -- 秩序
    table.insert(self:getBattleModel():getInitRuleEffects(), {reveal     = true}) -- 明牌
    table.insert(self:getBattleModel():getInitRuleEffects(), {halloween1 = true}) -- 万圣节+1
    table.insert(self:getBattleModel():getInitRuleEffects(), {halloween2 = true}) -- 万圣节+2
    table.insert(self:getBattleModel():getInitRuleEffects(), {swimwear1  = true}) -- 泳装+1
    table.insert(self:getBattleModel():getInitRuleEffects(), {swimwear2  = true}) -- 泳装+2
    table.insert(self:getBattleModel():getInitRuleEffects(), {wedding1   = true}) -- 花嫁+1
    table.insert(self:getBattleModel():getInitRuleEffects(), {wedding2   = true}) -- 花嫁+2
    table.insert(self:getBattleModel():getInitRuleEffects(), {daily1     = true}) -- 日常+1
    table.insert(self:getBattleModel():getInitRuleEffects(), {daily2     = true}) -- 日常+2
    for _, ruleId in ipairs(self:getBattleModel():getBattleRuleList()) do
        self.battleRuleMap_[tostring(ruleId)] = true
    end
    self.hasTypeIncreaseRule_ = self.battleRuleMap_[tostring(TYPE_INCREASE_RULE_ID)] == true
    self.hasTypeDecreaseRule_ = self.battleRuleMap_[tostring(TYPE_DECREASE_RULE_ID)] == true
    self.handCardDeskAttrMap_ = {}
    self.handCardInitAttrMap_ = {}
    
    -- create view
    self.battleView_ = TTGameBattleView.new({specialMode = self:getBattleModel():isUsedPveRule()})
    self.ownerScene_ = app.uiMgr:GetCurrentScene()
    self:getOwnerScene():AddGameLayer(self:getBattleView())
    self:SetViewComponent(self:getBattleView())

    self.moodEmoticonLayer_ = TTGameMoodLayer.new()
    self:getOwnerScene():AddDialog(self:getMoodEmoticonLayer())

    self.operatorMoodEntryVD_ = TTGameMoodLayer.CreateMoodEntry('l')
    self.opponentMoodEntryVD_ = TTGameMoodLayer.CreateMoodEntry('l')
    self:getOwnerScene():AddGameLayer(self.operatorMoodEntryVD_.view)
    self:getOwnerScene():AddGameLayer(self.opponentMoodEntryVD_.view)
    self.operatorMoodEntryVD_.view:setAnchorPoint(display.LEFT_CENTER)
    self.opponentMoodEntryVD_.view:setAnchorPoint(display.LEFT_CENTER)
    self.operatorMoodEntryVD_.view:setPosition(cc.pAdd(self:getViewData().operatorInfoLayer:convertToWorldSpaceAR(PointZero), cc.p(145,0)))
    self.opponentMoodEntryVD_.view:setPosition(cc.pAdd(self:getViewData().opponentInfoLayer:convertToWorldSpaceAR(PointZero), cc.p(145,0)))

    -- add listener
    display.commonUIParams(self:getViewData().abandonBtn, {cb = handler(self, self.onClickAbandonButtonHandler_)})
    display.commonUIParams(self:getViewData().opponentDeckArea, {cb = handler(self, self.onClickOpponentDeckAreaHandler_)})
    display.commonUIParams(self:getViewData().ruleLayer, {cb = handler(self, self.onClickRuleLayerHandler_), animate = false})
    display.commonUIParams(self:getViewData().operatorScoreFrame, {cb = handler(self, self.onClickOperatorScoreFrameHandler_), animate = false})
    display.commonUIParams(self:getViewData().opponentScoreFrame, {cb = handler(self, self.onClickOpponentScoreFrameHandler_), animate = false})
    display.commonUIParams(self:getViewData().moodTalkBtn, {cb = handler(self, self.onClickMoodTalkButtonHandler_)})
    self:getMoodEmoticonLayer():setClickMoodCellCB(handler(self, self.onClickMoodEmoticonCellHandler_))
    
    for _, handCardClickArea in ipairs(self:getBattleView():getOperatorHandCardAreas()) do
        display.commonUIParams(handCardClickArea, {cb = handler(self, self.onClickOperatorHandCardHandler_)})
    end
    for _, deskCellVD in ipairs(self:getBattleView():getDeskCellVDList()) do
        display.commonUIParams(deskCellVD.clickHotspot, {cb = handler(self, self.onClickDeskCellHandler_)})
    end

    -- update views
    local operatorModel = self:getBattleModel():getOperatorModel()
    local opponentModel = self:getBattleModel():getOpponentModel()
    self:getBattleView():initOperatorHandCards(operatorModel:getCards())
    self:getBattleView():initOpponentHandCards(opponentModel:getCards())
    self:getBattleView():updateRuleList(self:getBattleModel():getBattleRuleList())
    self:getBattleView():updateOperatorInfo(operatorModel:getName(), operatorModel:getAvatar(), operatorModel:getFrame())
    self:getBattleView():updateOpponentInfo(opponentModel:getName(), opponentModel:getAvatar(), opponentModel:getFrame())
    self:getBattleView():updatePlayersScore(self:getBattleModel():getOperatorScore(), self:getBattleModel():getOpponentScore())
    self:startRoundCountdownUpdate_()

    self:getMoodEmoticonLayer():getMoodCellLayer():setPosition(cc.pAdd(self:getViewData().operatorInfoLayer:convertToWorldSpaceAR(PointZero), cc.p(-140,65)))
    self:getMoodEmoticonLayer():getMoodCellLayer():setAnchorPoint(display.LEFT_BOTTOM)
    self:getMoodEmoticonLayer():closeMoodEmoticonView()

    -- show view
    self.isControllable_   = false
    self.isAnimateRunning_ = true
    self:getBattleView():show()
    self:getOwnerScene():AddViewForNoTouch()

    -- initRuleEffects
    local startInitRuleFunc = function()
        if #self:getBattleModel():getInitRuleEffects() > 0 then
            self:checkInitRuleEffects_()
        else
            self:stopInitRuleEffects_()
        end
    end

    -- show matched
    app.uiMgr:AddDialog('Game.views.ttGame.TripleTriadGameBattleMatchedPopup', {
        battleType    = self:getBattleModel():getBattleType(),
        isUsedPveRule = self:getBattleModel():isUsedPveRule(),
        operatorModel = operatorModel, 
        opponentModel = opponentModel,
        closeCB       = function()
            self:getBattleView():showUI(function()
                if #self:getBattleModel():getBattleRuleList() > 0 then
                    self:getBattleView():showInitRuleView(function()
                        startInitRuleFunc()
                    end)
                else
                    startInitRuleFunc()
                end
            end)
        end
    })
end


function TTGameBattleMediator:CleanupView()
    local viewComponent = self:GetViewComponent()
    if self.ownerScene_ and viewComponent and not tolua.isnull(viewComponent) then
        self.ownerScene_:RemoveDialogByName('Game.views.ttGame.TripleTriadGameCardRulePopup')
        self.ownerScene_:RemoveGameLayer(viewComponent)
        self.ownerScene_ = nil
    end

    if self.confirmAbandonDialog_ and not tolua.isnull(self.confirmAbandonDialog_) then
        self.confirmAbandonDialog_:removeFromParent()
        self.confirmAbandonDialog_ = nil
    end

    if self:getMoodEmoticonLayer() and not tolua.isnull(self:getMoodEmoticonLayer()) then
        self:getMoodEmoticonLayer():close()
        self.moodEmoticonLayer_ = nil
    end

    if self.operatorMoodEntryVD_ and self.operatorMoodEntryVD_.view and not tolua.isnull(self.operatorMoodEntryVD_.view) then
        self.operatorMoodEntryVD_.view:removeFromParent()
        self.operatorMoodEntryVD_ = nil
    end
    if self.opponentMoodEntryVD_ and self.opponentMoodEntryVD_.view and not tolua.isnull(self.opponentMoodEntryVD_.view) then
        self.opponentMoodEntryVD_.view:removeFromParent()
        self.opponentMoodEntryVD_ = nil
    end
end


function TTGameBattleMediator:OnRegist()
end


function TTGameBattleMediator:OnUnRegist()
end


function TTGameBattleMediator:InterestSignals()
    return {
        SGL.TTGAME_SOCKET_GAME_PLAY_CARD,
        SGL.TTGAME_SOCKET_GAME_PLAY_CARD_NOTICE,
        SGL.TTGAME_SOCKET_GAME_ABANDON,
        SGL.TTGAME_SOCKET_GAME_RESULT_NOTICE,
        SGL.TTGAME_SOCKET_ROOM_MOOD_NOTICE,
        SGL.TTGAME_SOCKET_NET_SYNC,
        SGL.TTGAME_BATTLE_INVALID,
    }
end
function TTGameBattleMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()

    -------------------------------------------------
    -- 比赛已失效
    if name == SGL.TTGAME_BATTLE_INVALID then
        self:getBattleView():stopAllActions()
        self:stopRoundCountdownUpdate_()
        
        app.ttGameMgr:setLastBattleResult(nil)
        app.ttGameMgr:setBattleModel(nil)
        
        self.isBattleGameOver_ = true
        self.delaySignalList_  = {}
        self:close()


    -------------------------------------------------
    -- 10017 : 主动认输
    elseif name == SGL.TTGAME_SOCKET_GAME_ABANDON then
        if self:getBattleModel():getBattleRoomId() == checkint(data.roomNo) then
            self:getBattleView():stopAllActions()
            self:stopRoundCountdownUpdate_()
            
            app.ttGameMgr:setLastBattleResult(TTGAME_DEFINE.RESULT_TYPE.FAIL)
            app.ttGameMgr:setBattleModel(nil)
            
            self.isBattleGameOver_ = true
            self.delaySignalList_  = {}
            self:close()
        end


    -------------------------------------------------
    -- 10016 : 结果通知
    elseif name == SGL.TTGAME_SOCKET_GAME_RESULT_NOTICE then
        if self:getBattleModel():getBattleRoomId() == checkint(data.roomNo) then
            if self.isAnimateRunning_ then
                table.insert(self.delaySignalList_, mvc.Signal.new(SGL.TTGAME_SOCKET_GAME_RESULT_NOTICE, data))
            else
                if self.isBattleGameOver_ then
                else
                    self:getViewData().operatorDeckArea:setVisible(false)
                    self:stopRoundCountdownUpdate_()
        
                    -- show result
                    app.uiMgr:AddDialog('Game.views.ttGame.TripleTriadGameBattleResultPopup', {
                        result        = data.result,
                        rewards       = data.rewards,
                        rewardIndex   = data.rewardIndex,
                        operatorScore = self:getBattleModel():getOperatorScore(),
                        opponentScore = self:getBattleModel():getOpponentScore(),
                        closeCB       = function()
                            app.ttGameMgr:setBattleModel(nil)
                            self:close()
                        end,
                    })
        
                    -- save resultType
                    app.ttGameMgr:setLastBattleResult(data.result)
                end
            end
        end
        

    -------------------------------------------------
    -- 10014 : 出牌操作
    elseif name == SGL.TTGAME_SOCKET_GAME_PLAY_CARD then
        if self:getBattleModel():getBattleRoomId() == checkint(data.roomNo) then
            self:setSelectOperatorHandCardIndex(-1)
        end
        
        
    -------------------------------------------------
    -- 10015 : 出牌通知
    elseif name == SGL.TTGAME_SOCKET_GAME_PLAY_CARD_NOTICE then
        if self:getBattleModel():getBattleRoomId() == checkint(data.roomNo) then
            if self.isAnimateRunning_ then
                table.insert(self.delaySignalList_, mvc.Signal.new(SGL.TTGAME_SOCKET_GAME_PLAY_CARD_NOTICE, data))
            else
                self:setSelectOperatorHandCardIndex(-1)

                -- switch roundPlayer & append playsCard
                local battleCardNode = nil
                local nextRoundUuid  = ''
                local operatorModel  = self:getBattleModel():getOperatorModel()
                local opponentModel  = self:getBattleModel():getOpponentModel()
                if tostring(data.uuid) == operatorModel:getPlayerId() then
                    nextRoundUuid  = tostring(opponentModel:getPlayerId())
                    battleCardNode = self:getBattleView():getOperatorHandCardNodes()[checkint(data.battleCardIndex)]
                    table.insert(operatorModel:getPlays(), checkint(data.battleCardIndex))
                    self:getBattleView():updateOperatorPlayCards(operatorModel:getPlays())

                elseif tostring(data.uuid) == opponentModel:getPlayerId() then
                    nextRoundUuid  = tostring(operatorModel:getPlayerId())
                    battleCardNode = self:getBattleView():getOpponentHandCardNodes()[checkint(data.battleCardIndex)]
                    table.insert(opponentModel:getPlays(), checkint(data.battleCardIndex))
                    self:getBattleView():updateOpponentPlayCards(opponentModel:getPlays())
                end

                -- update deskDatas
                self:updateDeskStatus_(data.map, data.position, battleCardNode)

                -- update playersScore
                self:getBattleView():updatePlayersScore(self:getBattleModel():getOperatorScore(), self:getBattleModel():getOpponentScore())
            
                -- check gameOver
                if self:getBattleModel():isFilledDeskCard() then
                    self:stopRoundCountdownUpdate_()
                else
                    -- switch roundPlayer
                    self:getBattleModel():setRoundPlayerId(nextRoundUuid)

                    -- reset roundSeconds
                    self:getBattleModel():updateRoundSeconds(TTGAME_DEFINE.ROUND_SECONDS)

                    -- update round views
                    self:updateRoundSwitch_()
                end
            end
        end


    -------------------------------------------------
    -- 10021 : 网络同步
    elseif name == SGL.TTGAME_SOCKET_NET_SYNC then
        if self:getBattleModel():getBattleRoomId() == checkint(data.roomNo) then
            if self.isAnimateRunning_ then
                self.delaySignalList_ = { mvc.Signal.new(SGL.TTGAME_SOCKET_NET_SYNC, data) }
            else
                if self.initRuleIndex_ <= #self:getBattleModel():getInitRuleEffects() then
                    app.uiMgr:ShowInformationTips(__('由于网络异常，初始化已中断'))
                    self:stopInitRuleEffects_()
                end
                self:setSelectOperatorHandCardIndex(-1)

                -- update operatorModel & opponentModel
                local operatorModel = self:getBattleModel():getOperatorModel()
                local opponentModel = self:getBattleModel():getOpponentModel()
                operatorModel:setCards(checktable(data.myBattleCards))
                operatorModel:setPlays(checktable(data.myPlayBattleCards))
                opponentModel:setCards(checktable(data.opponentBattleCards))
                opponentModel:setPlays(checktable(data.opponentPlayBattleCards))
                self:getBattleView():initOperatorHandCards(operatorModel:getCards())
                self:getBattleView():initOpponentHandCards(opponentModel:getCards())
                self:getBattleView():updateOperatorPlayCards(operatorModel:getPlays())
                self:getBattleView():updateOpponentPlayCards(opponentModel:getPlays())

                -- update deskDatas
                self:updateDeskStatus_(data.map)

                -- update playersScore
                self:getBattleView():updatePlayersScore(self:getBattleModel():getOperatorScore(), self:getBattleModel():getOpponentScore())

                -- check gameOver
                if self:getBattleModel():isFilledDeskCard() then
                    self:stopRoundCountdownUpdate_()
                else
                    -- switch roundPlayer
                    self:getBattleModel():setRoundPlayerId(tostring(data.currentHandMemberUuid))

                    -- update roundSeconds
                    self:getBattleModel():updateLeftRoundSeconds(data.currentRoundLeftSeconds)

                    -- update round views
                    self:updateRoundSwitch_()
                end

                app.uiMgr:ShowInformationTips(__('由于网络异常，战牌数据已同步'))
            end
        end


    -------------------------------------------------
    -- 10010 房间心情通知
    elseif name == SGL.TTGAME_SOCKET_ROOM_MOOD_NOTICE then
        if self:getBattleModel():getBattleRoomId() == checkint(data.roomNo) then 
            TTGameMoodLayer.UpdateMoodEntry(self.opponentMoodEntryVD_, data.messageId)
        end

    end
end


-------------------------------------------------
-- get / set

function TTGameBattleMediator:getOwnerScene()
    return self.ownerScene_
end


function TTGameBattleMediator:getBattleView()
    return self.battleView_
end
function TTGameBattleMediator:getViewData()
    return self:getBattleView():getViewData()
end


function TTGameBattleMediator:getBattleModel()
    return self.battleModel_
end


function TTGameBattleMediator:isRewardsBattle()
    return self:getBattleModel():getBattleType() == TTGAME_DEFINE.BATTLE_TYPE.PVE or 
           self:getBattleModel():getBattleType() == TTGAME_DEFINE.BATTLE_TYPE.PVP
end


function TTGameBattleMediator:getSelectOperatorHandCardIndex()
    return checkint(self.selectOperatorHandCardIndex_)
end
function TTGameBattleMediator:setSelectOperatorHandCardIndex(index)
    self.selectOperatorHandCardIndex_ = checkint(index)
    local operatorModel = self:getBattleModel():getOperatorModel()
    local hasPlayOrder  = operatorModel:hasPlayOrder()
    local isSelectCard  = self:getSelectOperatorHandCardIndex() > 0

    -- update all handCard
    for index, handCardNode in ipairs(self:getBattleView():getOperatorHandCardNodes()) do
        handCardNode:stopAllActions()
        handCardNode:setPosition(self:getViewData().operatorCardSPList[index])

        if index == self:getSelectOperatorHandCardIndex() then
            handCardNode:setScale(1.4)
            handCardNode:setLocalZOrder(2)
            handCardNode:showCardShadow()
            handCardNode:runAction(cc.RepeatForever:create(cc.Sequence:create(
                cc.MoveBy:create(1, cc.p(0,10)),
                cc.MoveBy:create(1, cc.p(0,-10))
            )))
        else
            handCardNode:setScale(1)
            handCardNode:setLocalZOrder(1)
            handCardNode:hideCardShadow()
            if isSelectCard then
                if hasPlayOrder then
                    handCardNode:toDisableStatus()
                else
                    handCardNode:toNormalStatus()
                end
            else
                handCardNode:toNormalStatus()
            end
        end
    end

    -- switch deskStatus
    if isSelectCard then
        self:getBattleView():showEmptyDeskCellStatus()
        self:getViewData().operatorDeckArea:setVisible(false)
    else
        self:getBattleView():hideEmptyDeskCellStatus()
    end
end


function TTGameBattleMediator:getMoodEmoticonLayer()
    return self.moodEmoticonLayer_
end
function TTGameBattleMediator:getMoodLayerViewData()
    return self:getMoodEmoticonLayer():getViewData()
end


-------------------------------------------------
-- public

function TTGameBattleMediator:close()
    self:stopRoundCountdownUpdate_()

    if self.customCloseCallback_ then
        self.customCloseCallback_()
    else
        if self.closeCallback_ then
            self.closeCallback_()
        end
        app:UnRegsitMediator(self:GetMediatorName())
    end
end


-------------------------------------------------
-- private

function TTGameBattleMediator:executeDelaySignal_()
    self.isAnimateRunning_ = false
    if #self.delaySignalList_ > 0 then
        local nextSignal = table.remove(self.delaySignalList_, 1)
        self:ProcessSignal(nextSignal)
    end
end


function TTGameBattleMediator:stopInitRuleEffects_()
    -- stop initRuleEffects action
    self:getBattleView():stopAllActions()
    
    local finishInitRuleFunc = function()
        TTGameAnimatePopup.new({aniType = 'start', closeCB  = function()
            self.isControllable_ = true
            self:updateRoundSwitch_()
            self:executeDelaySignal_()
            self:getBattleView():runAction(cc.Sequence:create(
                cc.DelayTime:create(0.1),
                cc.CallFunc:create(function()
                    self:getOwnerScene():RemoveViewForNoTouch()
                end)
            ))
        end})
    end

    if #self:getBattleModel():getBattleRuleList() > 0 then
        self:getBattleView():hintInitRuleNode(0)
        self:getBattleView():hideInitRuleView(function()
            finishInitRuleFunc()
        end)
    else
        finishInitRuleFunc()
    end
end


function TTGameBattleMediator:checkInitRuleEffects_()
    local initRuleActionList = {}
    local initRuleEffectData = self:getBattleModel():getInitRuleEffects()[self.initRuleIndex_]
    if initRuleEffectData.chaos then  -- 混乱
        table.insert(initRuleActionList, self:createChaosRuleActList_(initRuleEffectData.chaos))
    elseif initRuleEffectData.swap then  -- 交换
        table.insert(initRuleActionList, self:createSwapRuleActList_(initRuleEffectData.swap))
    elseif initRuleEffectData.order then -- 秩序
        table.insert(initRuleActionList, self:createOrderRuleEffects_())
    elseif initRuleEffectData.reveal then -- 明牌
        table.insert(initRuleActionList, self:createRevealRuleEffects_())
    elseif initRuleEffectData.halloween1 then -- 万圣节+1
        table.insert(initRuleActionList, self:createInitAttrRuleEffects_(11))
    elseif initRuleEffectData.halloween2 then -- 万圣节+2
        table.insert(initRuleActionList, self:createInitAttrRuleEffects_(12))
    elseif initRuleEffectData.swimwear1 then -- 泳装+1
        table.insert(initRuleActionList, self:createInitAttrRuleEffects_(13))
    elseif initRuleEffectData.swimwear2 then -- 泳装+2
        table.insert(initRuleActionList, self:createInitAttrRuleEffects_(14))
    elseif initRuleEffectData.wedding1 then -- 花嫁+1
        table.insert(initRuleActionList, self:createInitAttrRuleEffects_(15))
    elseif initRuleEffectData.wedding2 then -- 花嫁+2
        table.insert(initRuleActionList, self:createInitAttrRuleEffects_(16))
    elseif initRuleEffectData.daily1 then -- 日常+1
        table.insert(initRuleActionList, self:createInitAttrRuleEffects_(17))
    elseif initRuleEffectData.daily2 then -- 日常+2
        table.insert(initRuleActionList, self:createInitAttrRuleEffects_(18))
    end

    table.insert(initRuleActionList, cc.CallFunc:create(function()
        self.initRuleIndex_ = self.initRuleIndex_ + 1
        if self.initRuleIndex_ <= #self:getBattleModel():getInitRuleEffects() then
            self:checkInitRuleEffects_()
        else
            self:stopInitRuleEffects_()
        end
    end))
    self:getBattleView():runAction(cc.Sequence:create(initRuleActionList))
end


function TTGameBattleMediator:createRevealRuleEffects_()
    local flipCardNum = 0
    for _, ruleId in ipairs(self:getBattleModel():getBattleRuleList()) do
        flipCardNum = math.max(checkint(FLIP_CARDS_DEFINE[tostring(ruleId)]), flipCardNum)
    end

    local FLIP_ACT_TIME   = 0.2
    local DELAY_ACT_TIME  = 0.2
    local flipRuleActList = {}
    for i = 1, flipCardNum do
        local operatorCardNode = self:getBattleView():getOperatorHandCardNodes()[i]
        table.insert(flipRuleActList, cc.TargetedAction:create(operatorCardNode, cc.Sequence:create(
            cc.DelayTime:create(FLIP_ACT_TIME),
            cc.CallFunc:create(function()
                operatorCardNode:showRevealMark()
            end),
            cc.DelayTime:create(FLIP_ACT_TIME),
            cc.DelayTime:create(DELAY_ACT_TIME)
        )))

        local opponentCardNode = self:getBattleView():getOpponentHandCardNodes()[i]
        table.insert(flipRuleActList, cc.TargetedAction:create(opponentCardNode, cc.Sequence:create(
            cc.Spawn:create(
                cc.ScaleTo:create(FLIP_ACT_TIME, 0, 1),
                cc.MoveBy:create(FLIP_ACT_TIME, cc.p(0, 20))
            ),
            cc.CallFunc:create(function()
                opponentCardNode:toCardFrontStatus()
            end),
            cc.Spawn:create(
                cc.ScaleTo:create(FLIP_ACT_TIME, 1, 1),
                cc.MoveBy:create(FLIP_ACT_TIME, cc.p(0, -20))
            ),
            cc.DelayTime:create(DELAY_ACT_TIME)
        )))
    end

    if flipCardNum > 0 then
        table.insert(flipRuleActList, cc.CallFunc:create(function()
            local revealRuldId = 0
            for ruleId, value in pairs(FLIP_CARDS_DEFINE) do
                if flipCardNum == value then
                    revealRuldId = ruleId
                    break
                end
            end
            self:getBattleView():hintInitRuleNode(revealRuldId)  -- 1,2,3 : 明牌
        end))
        return cc.Spawn:create(flipRuleActList)

    else
        return cc.DelayTime:create(0.02)
    end
end


function TTGameBattleMediator:createOrderRuleEffects_()
    self.hasOrderRuleEffects_ = self.battleRuleMap_[tostring(PLAY_ORDER_RULE_ID)] == true
    if self.hasOrderRuleEffects_ then
        local operatorOrder = {}
        local operatorModel = self:getBattleModel():getOperatorModel()
        for index = 1, TTGAME_DEFINE.DECK_CARD_NUM do
            table.insert(operatorOrder, index)
        end
        operatorModel:setPlayOrder(operatorOrder)

        local CARD_SCALE_TIME = 0.2
        local DELAY_ACT_TIME  = 0.2
        local tipsRuleActList = {}
        for orderIndex, cardIndex in ipairs(operatorOrder) do
            local operatorCardNode = self:getBattleView():getOperatorHandCardNodes()[cardIndex]
            table.insert(tipsRuleActList, cc.TargetedAction:create(operatorCardNode, cc.Sequence:create(
                cc.DelayTime:create(orderIndex * 0.2),
                cc.EaseCubicActionOut:create(cc.ScaleTo:create(CARD_SCALE_TIME, 1.2)),
                cc.EaseCubicActionOut:create(cc.ScaleTo:create(CARD_SCALE_TIME, 1)),
                cc.DelayTime:create(DELAY_ACT_TIME)
            )))
        end

        table.insert(tipsRuleActList, cc.CallFunc:create(function()
            self:getBattleView():hintInitRuleNode(PLAY_ORDER_RULE_ID)  -- 8 : 秩序
        end))
        return cc.Spawn:create(tipsRuleActList)
    else
        return cc.DelayTime:create(0.02)
    end
end


function TTGameBattleMediator:createSwapRuleActList_(swapData)
    if next(checktable(swapData)) == nil then
        return cc.DelayTime:create(0.02)
    end
    local operatorModel    = self:getBattleModel():getOperatorModel()
    local opponentModel    = self:getBattleModel():getOpponentModel()
    local operatorIndex    = checkint(swapData[tostring(operatorModel:getPlayerId())])
    local opponentIndex    = checkint(swapData[tostring(opponentModel:getPlayerId())])
    local operatorCardId   = checkint(operatorModel:getCards()[operatorIndex])
    local opponentCardId   = checkint(opponentModel:getCards()[opponentIndex])
    local operatorCardNode = self:getBattleView():getOperatorHandCardNodes()[operatorIndex]
    local opponentCardNode = self:getBattleView():getOpponentHandCardNodes()[opponentIndex]

    local HALF_ACT_TIME   = 0.2
    local DELAY_ACT_TIME  = 0.2
    local swapRuleActList = {}
    if operatorCardNode and opponentCardNode then
        table.insert(swapRuleActList, cc.Sequence:create(
            cc.Spawn:create(
                cc.TargetedAction:create(operatorCardNode, cc.ScaleTo:create(HALF_ACT_TIME, 0)),
                cc.TargetedAction:create(operatorCardNode, cc.RotateTo:create(HALF_ACT_TIME, 180))
            ),
            cc.CallFunc:create(function()
                operatorModel:getCards()[operatorIndex] = opponentCardId
                self:getBattleView():initOperatorHandCard(operatorCardNode, opponentCardId)
            end),
            cc.Spawn:create(
                cc.TargetedAction:create(operatorCardNode, cc.ScaleTo:create(HALF_ACT_TIME, 1)),
                cc.TargetedAction:create(operatorCardNode, cc.RotateTo:create(HALF_ACT_TIME, 0))
            ),
            cc.DelayTime:create(DELAY_ACT_TIME)
        ))

        table.insert(swapRuleActList, cc.Sequence:create(
            cc.Spawn:create(
                cc.TargetedAction:create(opponentCardNode, cc.ScaleTo:create(HALF_ACT_TIME, 0)),
                cc.TargetedAction:create(opponentCardNode, cc.RotateTo:create(HALF_ACT_TIME, 180))
            ),
            cc.CallFunc:create(function()
                opponentModel:getCards()[opponentIndex] = operatorCardId
                self:getBattleView():initOpponentHandCard(opponentCardNode, operatorCardId)
            end),
            cc.Spawn:create(
                cc.TargetedAction:create(opponentCardNode, cc.ScaleTo:create(HALF_ACT_TIME, 1)),
                cc.TargetedAction:create(opponentCardNode, cc.RotateTo:create(HALF_ACT_TIME, 0))
            ),
            cc.DelayTime:create(DELAY_ACT_TIME)
        ))

        table.insert(swapRuleActList, cc.CallFunc:create(function()
            self:getBattleView():hintInitRuleNode(7)  -- 7 : 交换
        end))
        return cc.Spawn:create(swapRuleActList)
        
    else
        return cc.DelayTime:create(0.01)
    end
end


function TTGameBattleMediator:createChaosRuleActList_(chaosData)
    if next(checktable(chaosData)) == nil then
        return cc.DelayTime:create(0.02)
    end
    local operatorModel  = self:getBattleModel():getOperatorModel()
    local opponentModel  = self:getBattleModel():getOpponentModel()
    local operatorOrder  = checktable(chaosData[tostring(operatorModel:getPlayerId())])
    local opponentOrder  = checktable(chaosData[tostring(opponentModel:getPlayerId())])
    operatorModel:setPlayOrder(operatorOrder)
    opponentModel:setPlayOrder(opponentOrder)
    self.hasChaosRuleEffects_ = true

    local CARD_SCALE_TIME = 0.2
    local DELAY_ACT_TIME  = 0.2
    local tipsRuleActList = {}
    for orderIndex, cardIndex in ipairs(operatorOrder) do
        local operatorCardNode = self:getBattleView():getOperatorHandCardNodes()[cardIndex]
        table.insert(tipsRuleActList, cc.TargetedAction:create(operatorCardNode, cc.Sequence:create(
            cc.DelayTime:create(orderIndex * 0.2),
            cc.EaseCubicActionOut:create(cc.ScaleTo:create(CARD_SCALE_TIME, 1.2)),
            cc.EaseCubicActionOut:create(cc.ScaleTo:create(CARD_SCALE_TIME, 1)),
            cc.DelayTime:create(DELAY_ACT_TIME)
        )))
    end

    table.insert(tipsRuleActList, cc.CallFunc:create(function()
        self:getBattleView():hintInitRuleNode(4)  -- 4 : 混乱
    end))
    return cc.Spawn:create(tipsRuleActList)
end


function TTGameBattleMediator:createInitAttrRuleEffects_(ruleId)
    local hasInitAttrRuleEffects = self.battleRuleMap_[tostring(ruleId)] == true
    if hasInitAttrRuleEffects then
        local ruleConfInfo  = TTGameUtils.GetConfAt(TTGAME_DEFINE.CONF_TYPE.RULE_DEFINE, ruleId)
        local cardTypeText  = tostring(ruleConfInfo.targetId)
        local offsetAttrNum = checkint(ruleConfInfo.targetNum)
        self.handCardInitAttrMap_[cardTypeText] = checkint(self.handCardInitAttrMap_[cardTypeText]) + offsetAttrNum
        
        local initAttrActList = {
            cc.DelayTime:create(1)
        }
        table.insert(initAttrActList, cc.CallFunc:create(function()
            self:getBattleView():updateOperatorHandCard(self.handCardDeskAttrMap_, self.handCardInitAttrMap_)
            self:getBattleView():updateOpponentHandCard(self.handCardDeskAttrMap_, self.handCardInitAttrMap_)
            self:getBattleView():hintInitRuleNode(ruleId)
        end))
        return cc.Spawn:create(initAttrActList)
    else
        return cc.DelayTime:create(0.02)
    end
end


function TTGameBattleMediator:startRoundCountdownUpdate_()
    if self.roundCountdownHandler_ then return end
    self.roundCountdownHandler_ = scheduler.scheduleGlobal(function()
        local totalSeconds = checknumber(self:getBattleModel():getRoundSeconds())
        local leftSeconds  = checknumber(self:getBattleModel():getLeftRoundSeconds())
        if self:getBattleView().updateRoundSeconds then
            self:getBattleView():updateRoundSeconds(totalSeconds, leftSeconds)
        end
    end, 0)
end
function TTGameBattleMediator:stopRoundCountdownUpdate_()
    if self.roundCountdownHandler_ then
        scheduler.unscheduleGlobal(self.roundCountdownHandler_)
        self.roundCountdownHandler_ = nil
    end
end


function TTGameBattleMediator:updateRoundSwitch_()
    local operatorId    = self:getBattleModel():getOperatorModel():getPlayerId()
    local opponentId    = self:getBattleModel():getOpponentModel():getPlayerId()
    local roundPlayerId = self:getBattleModel():getRoundPlayerId()
    self:getBattleView():updateRoundTurn(roundPlayerId == operatorId)

    -- auto select handCard
    local operatorModel = self:getBattleModel():getOperatorModel()
    if roundPlayerId == operatorId then
        if operatorModel:hasPlayOrder() then
            local usedIndexMap = {}
            for _, value in ipairs(operatorModel:getPlays()) do
                usedIndexMap[tostring(value)] = true
            end
    
            local forwardCardIndex = -1
            for orderIndex, cardIndex in ipairs(operatorModel:getPlayOrder()) do
                if not usedIndexMap[tostring(cardIndex)] then
                    forwardCardIndex = checkint(cardIndex)
                    break
                end
            end
    
            if forwardCardIndex > 0 then
                self:setSelectOperatorHandCardIndex(forwardCardIndex)
            end
            
        else
            self:getViewData().operatorDeckArea:setVisible(true)
        end
    else
        self:getViewData().operatorDeckArea:setVisible(false)
    end
end


function TTGameBattleMediator:updateDeskStatus_(deskDataMap, battleSiteId, battleCardNode)
    self.isAnimateRunning_ = true
    local totalAnimateNum  = 0
    local finishAnimateNum = 0
    local operatorPlayerId = self:getBattleModel():getOperatorModel():getPlayerId()
    local deskCellDataMap  = checktable(deskDataMap)
    
    self.handCardDeskAttrMap_ = {}
    for siteId, deskElemModel in ipairs(self:getBattleModel():getDeskElemList()) do
        
        -- update model
        local deskCellData = checktable(deskCellDataMap[tostring(siteId)])
        local cardConfInfo = TTGameUtils.GetConfAt(TTGAME_DEFINE.CONF_TYPE.CARD_DEFINE, deskCellData.battleCardId)
        local cardTypeText = tostring(cardConfInfo.type)
        
        if next(deskCellData) ~= nil then
            deskElemModel:setOwnerId(tostring(deskCellData.ownerId))
            deskElemModel:setCardId(checkint(deskCellData.battleCardId))
        else
            deskElemModel:setOwnerId('')
            deskElemModel:setCardId(0)
        end

        if checkint(cardConfInfo.type) > 0 then
            if self.hasTypeIncreaseRule_ then
                self.handCardDeskAttrMap_[cardTypeText] = checkint(self.handCardDeskAttrMap_[cardTypeText]) + 1
            end
            if self.hasTypeDecreaseRule_ then
                self.handCardDeskAttrMap_[cardTypeText] = checkint(self.handCardDeskAttrMap_[cardTypeText]) - 1
            end
        end

        if checkint(battleSiteId) == siteId and battleCardNode then
            local battleCardAttrMap  = {}
            local battleCardAttrList = battleCardNode:getAttrList()
            for index, value in ipairs(battleCardAttrList) do
                battleCardAttrMap[tostring(index)] = value
            end
            deskCellData.initAttrMap = battleCardAttrMap
        end

        -- update views
        totalAnimateNum = totalAnimateNum + 1
        self:getBattleView():updateDeskCellStatus(siteId, deskCellData, operatorPlayerId, function()
            finishAnimateNum = finishAnimateNum + 1
            if finishAnimateNum >= totalAnimateNum then
                self:getBattleView():updateOperatorHandCard(self.handCardDeskAttrMap_, self.handCardInitAttrMap_)
                self:getBattleView():updateOpponentHandCard(self.handCardDeskAttrMap_, self.handCardInitAttrMap_)
                self:executeDelaySignal_()
            end
        end)
    end
end


-------------------------------------------------
-- handler

function TTGameBattleMediator:onClickAbandonButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end
    if self.isAnimateRunning_ then return end
    if self:getBattleModel():isFilledDeskCard() then return end

    local tipString = __('确定要中途放弃比赛吗？')
    local extraText = self:isRewardsBattle() and __('认输不消耗奖励次数') or nil
    local commonTip = require('common.NewCommonTip').new({text = tipString, extra = extraText, callback = function()
        app.ttGameMgr:socketSendData(NetCmd.TTGAME_GAME_ABANDON, {uuid = self:getBattleModel():getOperatorModel():getPlayerId()})
        -- app.ttGameMgr:socketSendData(NetCmd.TTGAME_NET_SYNC) -- debug use
    end})
    commonTip:setPosition(display.center)
    app.uiMgr:GetCurrentScene():AddDialog(commonTip)
    self.confirmAbandonDialog_ = commonTip
end


function TTGameBattleMediator:onClickRuleLayerHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local ruleList = self:getBattleModel():getBattleRuleList()
    if #ruleList > 0 then
        app.uiMgr:AddDialog('Game.views.ttGame.TripleTriadGameCardRulePopup', {ruleList = ruleList})
    else
        app.uiMgr:ShowInformationTips(__('今日暂无规则'))
    end
end


function TTGameBattleMediator:onClickOperatorHandCardHandler_(sender)
    if not self.isControllable_ then return end

    local operatorModel = self:getBattleModel():getOperatorModel()
    if self:getBattleModel():getRoundPlayerId() == operatorModel:getPlayerId() then

        local usedIndexMap = {}
        for _, value in ipairs(operatorModel:getPlays()) do
            usedIndexMap[tostring(value)] = true
        end

        local idleIndexList = {}
        for headIndex, handCardId in ipairs(operatorModel:getCards()) do
            if not usedIndexMap[tostring(headIndex)] then
                table.insert(idleIndexList, handCardId)
            end
        end
        
        -- check click idle card
        local clickCardIdx = checkint(sender:getTag())
        local isUsedCard   = usedIndexMap[tostring(clickCardIdx)] == true
        if not isUsedCard then
            PlayAudioByClickNormal()

            -- check orderRule
            if operatorModel:hasPlayOrder() then
                local forwardCardIndex = -1
                for orderIndex, cardIndex in ipairs(operatorModel:getPlayOrder()) do
                    if not usedIndexMap[tostring(cardIndex)] then
                        forwardCardIndex = checkint(cardIndex)
                        break
                    end
                end
                
                if forwardCardIndex == clickCardIdx then
                    self:setSelectOperatorHandCardIndex(clickCardIdx)
                else
                    if self.hasOrderRuleEffects_ then
                        app.uiMgr:ShowInformationTips(__('在【秩序】规则下，请按照顺序出牌'))
                    elseif self.hasChaosRuleEffects_ then
                        app.uiMgr:ShowInformationTips(__('在【混乱】规则下，无法任意出牌'))
                    end
                end
            else
                self:setSelectOperatorHandCardIndex(clickCardIdx)
            end
        end
    else
        app.uiMgr:ShowInformationTips(__('当前为对手回合，请稍安勿躁'))
    end
end


function TTGameBattleMediator:onClickDeskCellHandler_(sender)
    if not self.isControllable_ then return end
    if self.isAnimateRunning_ then return end
    if self:getBattleModel():isFilledDeskCard() then return end
    if self:getSelectOperatorHandCardIndex() > 0 then
        
        local deskCellSiteId = checkint(sender:getTag())
        local deskCellSiteVD = self:getBattleView():getDeskCellVDList()[deskCellSiteId]
        local operatorModel  = self:getBattleModel():getOperatorModel()
        if deskCellSiteVD.deskCardNode:getCardId() == 0 then
            -- send playCard : 10014
            PlayAudioByClickNormal()
            app.ttGameMgr:socketSendData(NetCmd.TTGAME_GAME_PLAY_CARD, {
                uuid            = operatorModel:getPlayerId(),
                position        = deskCellSiteId,
                battleCardIndex = self:getSelectOperatorHandCardIndex(),
            })

            self.isControllable_ = false
            transition.execute(self:getBattleView(), nil, {delay = 0.3, complete = function()
                self.isControllable_ = true
            end})
        end
    end
end


function TTGameBattleMediator:onClickMoodTalkButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    self:getMoodEmoticonLayer():showMoodEmoticonView()
end


function TTGameBattleMediator:onClickMoodEmoticonCellHandler_(moodId)
    self:getMoodEmoticonLayer():closeMoodEmoticonView()
    
    TTGameMoodLayer.UpdateMoodEntry(self.operatorMoodEntryVD_, moodId)
    app.ttGameMgr:socketSendData(NetCmd.TTGAME_ROOM_MOOD, {
        uuid      = app.gameMgr:GetUserInfo().playerId,
        messageId = moodId,
    })
end


function TTGameBattleMediator:onClickOpponentDeckAreaHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    app.uiMgr:ShowInformationTipsBoard({targetNode = sender, isOnlyDescr = true, descr = __('对手卡组'), type = 5})
end


function TTGameBattleMediator:onClickOperatorScoreFrameHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end
    
    for index, handCardNode in ipairs(self:getBattleView():getOperatorHandCardNodes()) do
        handCardNode:showScoreTips()
    end
    
    local operatorId = tostring(self:getBattleModel():getOperatorModel():getPlayerId())
    for siteId, deskElemModel in ipairs(self:getBattleModel():getDeskElemList()) do
        if operatorId == tostring(deskElemModel:getOwnerId()) then
            local deskCellSiteVD = self:getBattleView():getDeskCellVDList()[siteId]
            if deskCellSiteVD and deskCellSiteVD.deskCardNode then
                deskCellSiteVD.deskCardNode:showScoreTips()
            end
        end
    end
end


function TTGameBattleMediator:onClickOpponentScoreFrameHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    for index, handCardNode in ipairs(self:getBattleView():getOpponentHandCardNodes()) do
        handCardNode:showScoreTips()
    end
    
    local opponentId = tostring(self:getBattleModel():getOpponentModel():getPlayerId())
    for siteId, deskElemModel in ipairs(self:getBattleModel():getDeskElemList()) do
        if opponentId == tostring(deskElemModel:getOwnerId()) then
            local deskCellSiteVD = self:getBattleView():getDeskCellVDList()[siteId]
            if deskCellSiteVD and deskCellSiteVD.deskCardNode then
                deskCellSiteVD.deskCardNode:showScoreTips()
            end
        end
    end
end


return TTGameBattleMediator

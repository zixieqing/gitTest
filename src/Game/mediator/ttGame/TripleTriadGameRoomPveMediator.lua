--[[
 * author : kaishiqi
 * descpt : 打牌游戏 - PVE房间中介者
]]
local TTGameModelFactory     = require('Game.models.TTGameModelFactory')
local TTGameBattleModel      = TTGameModelFactory.getModelType('Battle')
local TTGamePlayerModel      = TTGameModelFactory.getModelType('Player')
local TTGamePveRoomView      = require('Game.views.ttGame.TripleTriadGameRoomPveView')
local TTGameBaseRoomMediator = require('Game.mediator.ttGame.TripleTriadGameRoomBaseMediator')
local TTGamePveRoomMediator  = class('TripleTriadGameRoomPveMediator', TTGameBaseRoomMediator)

function TTGamePveRoomMediator:ctor(params, viewComponent)
    self.super.super.ctor(self.super, 'TripleTriadGameRoomPveMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end


-------------------------------------------------
-- inheritance

function TTGamePveRoomMediator:Initial(key)
    self.super.super.Initial(self.super, key)
    
    -- init vars
    self.roomId_ = 0
    self:setNpcId(self.ctorArgs_.npcId)
    self.customCloseCallback_ = self.ctorArgs_.customcloseCB
    
    -- create view
    self:InitialView(TTGamePveRoomView)

    -- add listener
    display.commonUIParams(self:getViewData().rewardsTimesCountBar, {cb = handler(self, self.onClickRewardsTimesBarHandler_)})

    -- update views
    local activityConfInfo = TTGameUtils.GetConfAt(TTGAME_DEFINE.CONF_TYPE.ACTIVITY, app.ttGameMgr:getSummaryId())
    self:getRoomView():updateBgImage(activityConfInfo.picture)
    self:getRoomView():updateNpcImage(self:getNpcConf().draw)
    self:getRoomView():updateRuleMode(self:hasNpcRule())
    self:getRoomView():updateRewardBuyStatus(checkint(self:getNpcData().leftRewardBuyTimes) > 0)

    if self.ctorArgs_.anniMode then
        self:getViewData().rewardsLayer:setVisible(false)
    end
end


function TTGamePveRoomMediator:CleanupView()
    self.super.CleanupView(self)
end


function TTGamePveRoomMediator:OnRegist()
    self.super.OnRegist(self)
    regPost(POST.TTGAME_BUY_TIMES)
end


function TTGamePveRoomMediator:OnUnRegist()
    self.super.OnUnRegist(self)
    unregPost(POST.TTGAME_BUY_TIMES)
end


function TTGamePveRoomMediator:InterestSignals()
    local interestSignals = self.super.InterestSignals(self)
    table.insertto(interestSignals, {
        POST.TTGAME_BUY_TIMES.sglName,
        SGL.TTGAME_BATTLE_CONNECTED,
        SGL.TTGAME_SOCKET_PVE_ENTER,
        SGL.TTGAME_SOCKET_GAME_MATCHED_NOTICE,
    })
    return interestSignals
end
function TTGamePveRoomMediator:ProcessSignal(signal)
    self.super.ProcessSignal(self, signal)
    local name = signal:GetName()
    local data = signal:GetBody()

    if name == POST.TTGAME_BUY_TIMES.sglName then
        -- sync diamond
        app.gameMgr:GetUserInfo().diamond = checkint(data.diamond)
        self:GetFacade():DispatchObservers(SGL.CACHE_MONEY_UPDATE_UI)
        
        local pveNpcData = self:getNpcData()
        local addTimes   = checkint(self:getNpcConf().buyAdditionTimes)

        -- update rewardTimes
        pveNpcData.leftRewardTimes = checkint(pveNpcData.leftRewardTimes) + addTimes
        self:getRoomView():updateRewardLeftTimes(pveNpcData.leftRewardTimes)

        -- update buyTimes
        pveNpcData.leftRewardBuyTimes = checkint(pveNpcData.leftRewardBuyTimes) - 1
        self:getRoomView():updateRewardBuyStatus(pveNpcData.leftRewardBuyTimes > 0)


    elseif name == SGL.TTGAME_BATTLE_CONNECTED then
        app.ttGameMgr:socketSendData(NetCmd.TTGAME_PVE_ENTER, {npcId = self:getNpcId(), deckId = self:getDeckSelectIndex()})
        
    
    -- 10001 打牌游戏 pve匹配
    elseif name == SGL.TTGAME_SOCKET_PVE_ENTER then
        if errcode == 0 then
        else
            self.isControllable_ = false
            self.roomId_ = checkint(data.roomNo)
            app.ttGameMgr:setBattleModel(TTGameBattleModel.new(TTGAME_DEFINE.BATTLE_TYPE.PVE, self.roomId_))
            app.ttGameMgr:setLastBattleResult(nil)
        end
        

    -- 10008 进入战斗
    elseif name == SGL.TTGAME_SOCKET_GAME_MATCHED_NOTICE then
        if self.roomId_ == checkint(data.roomNo) then 
            self.isControllable_ = true

            local battleModel = app.ttGameMgr:getBattleModel()
            if battleModel then

                -- operator playr
                local operatorModel = TTGamePlayerModel.new()
                operatorModel:setPlayerId(tostring(app.gameMgr:GetUserInfo().playerId))
                operatorModel:setName(app.gameMgr:GetUserInfo().playerName)
                operatorModel:setAvatar(app.gameMgr:GetUserInfo().avatar)
                operatorModel:setFrame(app.gameMgr:GetUserInfo().avatarFrame)
                operatorModel:setCards(clone(app.ttGameMgr:getDeckCardsAt(self:getDeckSelectIndex())))
                operatorModel:setDeckId(self:getDeckSelectIndex())
                
                -- opponent playr
                local opponentModel = TTGamePlayerModel.new()
                opponentModel:setPlayerId(tostring(data.opponentUuid))
                opponentModel:setName(tostring(self:getNpcConf().name))
                opponentModel:setAvatar(CardUtils.GetCardHeadPathBySkinId(self:getNpcConf().draw))
                opponentModel:setFrame(checkint(self:getNpcConf().headFrame))
                opponentModel:setCards(checktable(data.opponentBattleCards))
                
                -- init battleModel
                battleModel:setUsedPveRule(self:hasNpcRule())
                battleModel:setOperatorModel(operatorModel)
                battleModel:setOpponentModel(opponentModel)
                battleModel:setBattleRuleList(self:getRuleList())
                battleModel:updateRoundSeconds(TTGAME_DEFINE.ROUND_SECONDS)
                battleModel:setRoundPlayerId(tostring(data.firstHandMemberUuid))
                battleModel:setInitRuleEffects(checktable(data.initialRuleEffects))
                
                -- battleMdt
                local ttGameBattleMdt = require('Game.mediator.ttGame.TripleTriadGameBattleMediator').new({
                    battleModel   = battleModel,
                    customCloseCB = self.customCloseCallback_,
                    closeCB       = function()
                        if app.ttGameMgr:getLastBattleResult() == TTGAME_DEFINE.RESULT_TYPE.WIN then
                            self:setRewardTimes(math.max(self:getRewardTimes() - 1, 0))
                        end
                        self:getRoomView():updateRewardLeftTimes(self:getRewardTimes())

                        app.ttGameMgr:socketDestroy()
                    end,
                })
                app:RegistMediator(ttGameBattleMdt)
            else
                app.uiMgr:ShowInformationTips(__('PVE进入战斗时，未找到数据模型'))
            end
        end

    end
end


-------------------------------------------------
-- get / set

function TTGamePveRoomMediator:getNpcId()
    return checkint(self.pveNpcId_)
end
function TTGamePveRoomMediator:setNpcId(npcId)
    self.pveNpcId_   = checkint(npcId)
    self.pveNpcConf_ = TTGameUtils.GetConfAt(TTGAME_DEFINE.CONF_TYPE.NPC_DEFINE, self:getNpcId())
end


function TTGamePveRoomMediator:getNpcConf()
    return self.pveNpcConf_ or {}
end


function TTGamePveRoomMediator:getNpcData()
    return app.ttGameMgr:getPveNpcData(self:getNpcId())
end


function TTGamePveRoomMediator:getNpcRuleList()
    return self:getNpcConf().rules or {}
end
function TTGamePveRoomMediator:hasNpcRule()
    return #self:getNpcRuleList() > 0
end


function TTGamePveRoomMediator:getRuleList()
    return self:hasNpcRule() and self:getNpcRuleList() or self.super.getRuleList(self)
end


function TTGamePveRoomMediator:getRewardList()
    return app.ttGameMgr:getPveTodayRewardListAt(self:getNpcId())
end


function TTGamePveRoomMediator:getRewardTimes()
    return app.ttGameMgr:getPveTodayRewardTimesAt(self:getNpcId())
end
function TTGamePveRoomMediator:setRewardTimes(rewardTimes)
    return app.ttGameMgr:setPveTodayRewardTimesAt(self:getNpcId(), rewardTimes)
end


-------------------------------------------------
-- public

function TTGamePveRoomMediator:close()
    app.ttGameMgr:setBattleModel(nil)
    app.ttGameMgr:socketDestroy()
    self.super.close(self)
end


-------------------------------------------------
-- private


-------------------------------------------------
-- handler

function TTGamePveRoomMediator:onClickBackButtonHandler_(sender)
    if self.customCloseCallback_ then
        self.customCloseCallback_()
    else
        self.super.onClickBackButtonHandler_(self, sender)
    end
end


function TTGamePveRoomMediator:onClickRuleLayerHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end
    
    local ruleList = self:getRuleList()
    if #ruleList > 0 then
        app.uiMgr:AddDialog('Game.views.ttGame.TripleTriadGameCardRulePopup', {ruleList = ruleList, isPveRule = self:hasNpcRule()})
    else
        app.uiMgr:ShowInformationTips(__('今日暂无规则'))
    end
end


function TTGamePveRoomMediator:onClickRewardsTimesBarHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local pveNpcBuyTimes = checkint(self:getNpcData().leftRewardBuyTimes)
    local comsumeDiamond = checkint(self:getNpcConf().diamond)
    local addRewardTimes = checkint(self:getNpcConf().buyAdditionTimes)
    if pveNpcBuyTimes > 0 then

        local tipsString = string.fmt(__('是否花费_diamond_幻晶石追加_times_个奖励次数？\n（剩余_num_次购买机会）'), {
            _diamond_ = comsumeDiamond,
            _times_   = addRewardTimes,
            _num_     = pveNpcBuyTimes,
        })
        local commonTip = require('common.NewCommonTip').new({text = tipsString, callback = function()
            -- check diamond
            if CommonUtils.GetCacheProductNum(DIAMOND_ID) < comsumeDiamond then
                if GAME_MODULE_OPEN.NEW_STORE then
                    app.uiMgr:showDiamonTips()
                else
                    app.uiMgr:ShowInformationTips(__('幻晶石不足'))
                end

            else
                self:SendSignal(POST.TTGAME_BUY_TIMES.cmdName, {npcId = self:getNpcId()})
            end
        end})
        commonTip:setPosition(display.center)
        app.uiMgr:GetCurrentScene():AddDialog(commonTip)

    else
        app.uiMgr:ShowInformationTips(__('购买次数机会已用光'))
    end
end


function TTGamePveRoomMediator:onClickPlayGameButtonHandler_(sender)
    if self.super.onClickPlayGameButtonHandler_(self, sender) then
        app.ttGameMgr:socketDestroy()
        app.ttGameMgr:socketLaunch()
    end
end


return TTGamePveRoomMediator

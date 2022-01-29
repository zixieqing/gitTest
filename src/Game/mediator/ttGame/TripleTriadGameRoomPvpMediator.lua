--[[
 * author : kaishiqi
 * descpt : 打牌游戏 - PVP房间中介者
]]
local TTGameModelFactory     = require('Game.models.TTGameModelFactory')
local TTGameBattleModel      = TTGameModelFactory.getModelType('Battle')
local TTGamePlayerModel      = TTGameModelFactory.getModelType('Player')
local TTGamePvpRoomView      = require('Game.views.ttGame.TripleTriadGameRoomPvpView')
local TTGameBaseRoomMediator = require('Game.mediator.ttGame.TripleTriadGameRoomBaseMediator')
local TTGamePvpRoomMediator  = class('TripleTriadGameRoomPvpMediator', TTGameBaseRoomMediator)

function TTGamePvpRoomMediator:ctor(params, viewComponent)
    self.super.super.ctor(self.super, 'TripleTriadGameRoomPvpMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end


-------------------------------------------------
-- inheritance

function TTGamePvpRoomMediator:Initial(key)
    self.super.super.Initial(self.super, key)
    
    -- init vars
    self.roomId_ = 0
    
    -- create view
    self:InitialView(TTGamePvpRoomView)

    self.pvpMatchViewData_ = TTGamePvpRoomView.CreateMatchView()
    self:getOwnerScene():AddDialog(self:getPvpMatchViewData().view)

    -- add listener
    display.commonUIParams(self:getPvpMatchViewData().cancelMatchBtn, {cb = handler(self, self.onClickCancelMatchButtonHandler_)})

    -- update views
    self:closePvpMatchViewView()
end


function TTGamePvpRoomMediator:CleanupView()
    self.super.CleanupView(self)

    if self:getPvpMatchViewData() and not tolua.isnull(self:getPvpMatchViewData().view) then
        self:getPvpMatchViewData().view:removeFromParent()
        self.pvpMatchViewData_ = nil
    end
end


function TTGamePvpRoomMediator:OnRegist()
    self.super.OnRegist(self)
end


function TTGamePvpRoomMediator:OnUnRegist()
    self.super.OnUnRegist(self)
end


function TTGamePvpRoomMediator:InterestSignals()
    local interestSignals = self.super.InterestSignals(self)
    table.insertto(interestSignals, {
        SGL.TTGAME_BATTLE_CONNECTED,
        SGL.TTGAME_SOCKET_PVP_MATCH,
        SGL.TTGAME_SOCKET_ROOM_ENTER_NOTICE,
        SGL.TTGAME_SOCKET_GAME_MATCHED_NOTICE,
    })
    return interestSignals
end
function TTGamePvpRoomMediator:ProcessSignal(signal)
    self.super.ProcessSignal(self, signal)
    local name    = tostring(signal:GetName())
    local data    = checktable(signal:GetBody())
    local errcode = checkint(data.errcode)
    local errmsg  = tostring(data.errmsg)

    if name == SGL.TTGAME_BATTLE_CONNECTED then
        self.isToMatchConnect_ = true
        app.ttGameMgr:socketSendData(NetCmd.TTGAME_PVP_MATCH, {match = 1, deckId = self:getDeckSelectIndex()})


    -- 10007 PVP匹配
    elseif name == SGL.TTGAME_SOCKET_PVP_MATCH then
        if self.isToMatchConnect_ then
            if errcode == 0 then
                self:showPvpMatchViewView()
                self:switchPvpToMatchingMode()
            end
        else
            if errcode == 0 then
                app.ttGameMgr:socketDestroy()
                self:closePvpMatchViewView()
            end
        end


    -- 10004 进入房间通知
    elseif name == SGL.TTGAME_SOCKET_ROOM_ENTER_NOTICE then
        self:switchPvpToMatchedMode()
        self.roomId_ = checkint(data.roomNo)
        app.ttGameMgr:setBattleModel(TTGameBattleModel.new(TTGAME_DEFINE.BATTLE_TYPE.PVP, self.roomId_))
        app.ttGameMgr:setLastBattleResult(nil)


    -- 10008 进入战斗
    elseif name == SGL.TTGAME_SOCKET_GAME_MATCHED_NOTICE then
        if self.roomId_ == checkint(data.roomNo) then
            self:closePvpMatchViewView()
            
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
                opponentModel:setName(tostring(data.opponentName))
                opponentModel:setAvatar(checkint(data.opponentAvatar))
                opponentModel:setFrame(checkint(data.opponentAvatarFrame))
                opponentModel:setCards(checktable(data.opponentBattleCards))
                
                -- init battleModel
                battleModel:setOperatorModel(operatorModel)
                battleModel:setOpponentModel(opponentModel)
                battleModel:setBattleRuleList(self:getRuleList())
                battleModel:updateRoundSeconds(TTGAME_DEFINE.ROUND_SECONDS)
                battleModel:setRoundPlayerId(tostring(data.firstHandMemberUuid))
                battleModel:setInitRuleEffects(checktable(data.initialRuleEffects))
                
                -- battleMdt
                local ttGameBattleMdt = require('Game.mediator.ttGame.TripleTriadGameBattleMediator').new({
                    battleModel = battleModel,
                    closeCB     = function()
                        if app.ttGameMgr:getLastBattleResult() == TTGAME_DEFINE.RESULT_TYPE.WIN then
                            self:setRewardTimes(math.max(self:getRewardTimes() - 1, 0))
                        end
                        self:getRoomView():updateRewardLeftTimes(self:getRewardTimes())
                        
                        app.ttGameMgr:socketDestroy()
                    end,
                })
                app:RegistMediator(ttGameBattleMdt)
            else
                app.uiMgr:ShowInformationTips(__('PVP进入战斗时，未找到数据模型'))
            end
        end

    end

end


-------------------------------------------------
-- get / set


function TTGamePvpRoomMediator:getRewardList()
    return app.ttGameMgr:getPvpTodayRewardList()
end


function TTGamePvpRoomMediator:getRewardTimes()
    return app.ttGameMgr:getPvpTodayRewardTimes()
end
function TTGamePvpRoomMediator:setRewardTimes(rewardTimes)
    app.ttGameMgr:setPvpTodayRewardTimes(rewardTimes)
end


function TTGamePvpRoomMediator:getPvpMatchViewData()
    return self.pvpMatchViewData_
end


-------------------------------------------------
-- public

function TTGamePvpRoomMediator:close()
    app.ttGameMgr:setBattleModel(nil)
    app.ttGameMgr:socketDestroy()
    self.super.close(self)
end


function TTGamePvpRoomMediator:showPvpMatchViewView()
    self:getPvpMatchViewData().view:setVisible(true)
    self:getViewData().playGameNameBar:setVisible(false)
end
function TTGamePvpRoomMediator:closePvpMatchViewView()
    self:getPvpMatchViewData().view:setVisible(false)
    self:getViewData().playGameNameBar:setVisible(true)
end


function TTGamePvpRoomMediator:switchPvpToMatchingMode()
    self:getPvpMatchViewData().matchedLayer:setVisible(false)
    self:getPvpMatchViewData().matchingLayer:setVisible(true)
end
function TTGamePvpRoomMediator:switchPvpToMatchedMode()
    self:getPvpMatchViewData().matchedLayer:setVisible(true)
    self:getPvpMatchViewData().matchingLayer:setVisible(false)
end


-------------------------------------------------
-- private


-------------------------------------------------
-- handler

function TTGamePvpRoomMediator:onClickPlayGameButtonHandler_(sender)
    if self.super.onClickPlayGameButtonHandler_(self, sender) then
        app.ttGameMgr:socketDestroy()
        app.ttGameMgr:socketLaunch()
    end
end


function TTGamePvpRoomMediator:onClickCancelMatchButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    self.isControllable_ = false
    self:getRoomView():stopAllActions()
    self:getRoomView():runAction(cc.Sequence:create(
        cc.DelayTime:create(0.3),
        cc.CallFunc:create(function()
            self.isControllable_ = true
        end)
    ))
    
    self.isToMatchConnect_ = false
    app.ttGameMgr:socketSendData(NetCmd.TTGAME_PVP_MATCH, {match = 0})
end


return TTGamePvpRoomMediator

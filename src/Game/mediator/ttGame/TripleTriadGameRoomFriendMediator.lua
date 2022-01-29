--[[
 * author : kaishiqi
 * descpt : 打牌游戏 - 好友房间中介者
]]
local TTGameModelFactory       = require('Game.models.TTGameModelFactory')
local TTGameBattleModel        = TTGameModelFactory.getModelType('Battle')
local TTGamePlayerModel        = TTGameModelFactory.getModelType('Player')
local TTGameMoodLayer          = require('Game.views.ttGame.TripleTriadGameMoodEmoticonLayer')
local TTGameFriendRoomView     = require('Game.views.ttGame.TripleTriadGameRoomFriendView')
local TTGameBaseRoomMediator   = require('Game.mediator.ttGame.TripleTriadGameRoomBaseMediator')
local TTGameRoomFriendMediator = class('TripleTriadGameRoomFriendMediator', TTGameBaseRoomMediator)

function TTGameRoomFriendMediator:ctor(params, viewComponent)
    self.super.super.ctor(self.super, 'TripleTriadGameRoomFriendMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end


-------------------------------------------------
-- inheritance

function TTGameRoomFriendMediator:Initial(key)
    self.super.super.Initial(self.super, key)
    
    -- init vars
    self.roomId_ = checkint(self.ctorArgs_.roomId)
    
    -- create view
    self:InitialView(TTGameFriendRoomView)

    self.moodEmoticonLayer_ = TTGameMoodLayer.new()
    self:getOwnerScene():AddDialog(self:getMoodEmoticonLayer())

    self.operatorMoodEntryVD_ = TTGameMoodLayer.CreateMoodEntry('r')
    self.opponentMoodEntryVD_ = TTGameMoodLayer.CreateMoodEntry('l')
    self:getOwnerScene():AddGameLayer(self.operatorMoodEntryVD_.view)
    self:getOwnerScene():AddGameLayer(self.opponentMoodEntryVD_.view)
    self.operatorMoodEntryVD_.view:setAnchorPoint(display.RIGHT_CENTER)
    self.opponentMoodEntryVD_.view:setAnchorPoint(display.LEFT_CENTER)
    self.operatorMoodEntryVD_.view:setPosition(cc.pAdd(self:getViewData().moodTalkBtn:convertToWorldSpaceAR(PointZero), cc.p(-50,0)))
    self.opponentMoodEntryVD_.view:setPosition(cc.pAdd(self:getViewData().roomerHeadNode:convertToWorldSpaceAR(PointZero), cc.p(90,20)))

    -- add listener
    display.commonUIParams(self:getViewData().moodTalkBtn, {cb = handler(self, self.onClickMoodTalkButtonHandler_)})
    display.commonUIParams(self:getViewData().canclelReadyBtn, {cb = handler(self, self.onClickCancelReadyButtonHandler_)})
    self:getMoodEmoticonLayer():setClickMoodCellCB(handler(self, self.onClickMoodEmoticonCellHandler_))

    -- update views
    self:getMoodEmoticonLayer():getMoodCellLayer():setPosition(cc.pAdd(self:getViewData().moodTalkBtn:convertToWorldSpaceAR(PointZero), cc.p(-45,-45)))
    self:getMoodEmoticonLayer():getMoodCellLayer():setAnchorPoint(display.RIGHT_BOTTOM)
    self:getMoodEmoticonLayer():closeMoodEmoticonView()

    self:setOpponentData(nil)
    self:getRoomView():hideReadyedMaskLayer()
    self:getViewData().view:setVisible(false)
end


function TTGameRoomFriendMediator:CleanupView()
    self.super.CleanupView(self)

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


function TTGameRoomFriendMediator:OnRegist()
    self.super.OnRegist(self)

    app.ttGameMgr:socketDestroy()
    app.ttGameMgr:socketLaunch()
end


function TTGameRoomFriendMediator:OnUnRegist()
    self.super.OnUnRegist(self)
end


function TTGameRoomFriendMediator:InterestSignals()
    local interestSignals = self.super.InterestSignals(self)
    table.insertto(interestSignals, {
        SGL.TTGAME_BATTLE_CONNECTED,
        SGL.TTGAME_SOCKET_ROOM_CREATE,
        SGL.TTGAME_SOCKET_ROOM_ENTER,
        SGL.TTGAME_SOCKET_ROOM_ENTER_NOTICE,
        SGL.TTGAME_SOCKET_ROOM_READY,
        SGL.TTGAME_SOCKET_ROOM_READY_NOTICE,
        SGL.TTGAME_SOCKET_ROOM_LEAVE,
        SGL.TTGAME_SOCKET_ROOM_LEAVE_NOTICE,
        SGL.TTGAME_SOCKET_GAME_MATCHED_NOTICE,
        SGL.TTGAME_SOCKET_ROOM_MOOD_NOTICE,
    })
    return interestSignals
end
function TTGameRoomFriendMediator:ProcessSignal(signal)
    self.super.ProcessSignal(self, signal)
    local name    = tostring(signal:GetName())
    local data    = checktable(signal:GetBody())
    local errcode = checkint(data.errcode)
    local errmsg  = tostring(data.errmsg)

    if name == SGL.TTGAME_BATTLE_CONNECTED then
        if self.roomId_ > 0 then
            self:getRoomView():updateRoomNumber(self.roomId_)
            app.ttGameMgr:socketSendData(NetCmd.TTGAME_ROOM_ENTER, {roomNo = self.roomId_})
        else
            app.ttGameMgr:socketSendData(NetCmd.TTGAME_ROOM_CREATE)
        end


    -- 10002 创建房间
    elseif name == SGL.TTGAME_SOCKET_ROOM_CREATE then
        if errcode == 0 then
            self.roomId_ = checkint(data.roomNo)
            self:getRoomView():updateRoomNumber(self.roomId_)

            if self:getViewData().chatPanel then
                self:getViewData().chatPanel:delayInit()
            end
            self:getViewData().view:setVisible(true)
        else
            self:close()
        end


    -- 10003 进入房间
    elseif name == SGL.TTGAME_SOCKET_ROOM_ENTER then
        if errcode == 0 then
            if self.roomId_ == checkint(data.roomNo) then 
                if self:getViewData().chatPanel then
                    self:getViewData().chatPanel:delayInit()
                end
                self:getViewData().view:setVisible(true)
                self:setOpponentData(data)
            end
        else
            self:close()
        end


    -- 10004 进入房间通知
    elseif name == SGL.TTGAME_SOCKET_ROOM_ENTER_NOTICE then
        if self.roomId_ == checkint(data.roomNo) then 
            self:setOpponentData(data)
        end


    -- 10005 房间准备
    elseif name == SGL.TTGAME_SOCKET_ROOM_READY then
        if self.roomId_ == checkint(data.roomNo) then 
            if errcode == 0 then
                if self.isToReadyConnect_ then
                    self:getRoomView():showReadyedMaskLayer()
                else
                    self:getRoomView():hideReadyedMaskLayer()
                end
            end
        end


    -- 10006 准备通知
    elseif name == SGL.TTGAME_SOCKET_ROOM_READY_NOTICE then
        if self.roomId_ == checkint(data.roomNo) then 
            if self:getOpponentData() then
                self:getOpponentData().opponentReady = checkint(data.ready) -- 0:取消准备 1: 准备
            end
            self:updateOpponentReadyStatus_()
        end


    -- 10003 房间离开
    elseif name == SGL.TTGAME_SOCKET_ROOM_LEAVE then
        if self.roomId_ == checkint(data.roomNo) then 
            self:close()
        end


    -- 10004 离开通知
    elseif name == SGL.TTGAME_SOCKET_ROOM_LEAVE_NOTICE then
        if self.roomId_ == checkint(data.roomNo) then 
            self.isToReadyConnect_ = false
            self:getRoomView():hideReadyedMaskLayer()
            self:setOpponentData(nil)
        end


    -- 10008 进入战斗
    elseif name == SGL.TTGAME_SOCKET_GAME_MATCHED_NOTICE then
        if self.roomId_ == checkint(data.roomNo) then 
            -- cancel opponentReady
            self:getOpponentData().opponentReady = 0
            self:updateOpponentReadyStatus_()

            -- cancel myReady
            self.isToReadyConnect_ = false
            self:getRoomView():hideReadyedMaskLayer()

            -- close chatPanel
            if self:getViewData().chatPanel then
                self:getViewData().chatPanel:removeChatView()
            end

            -- create battleModel
            local battleModel = TTGameBattleModel.new(TTGAME_DEFINE.BATTLE_TYPE.FRIEND, self.roomId_)
            app.ttGameMgr:setBattleModel(battleModel)
            app.ttGameMgr:setLastBattleResult(nil)

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
                end,
            })
            app:RegistMediator(ttGameBattleMdt)
        end


    -- 10010 房间心情通知
    elseif name == SGL.TTGAME_SOCKET_ROOM_MOOD_NOTICE then
        if self.roomId_ == checkint(data.roomNo) then 
            TTGameMoodLayer.UpdateMoodEntry(self.opponentMoodEntryVD_, data.messageId)
        end

    end
end


-------------------------------------------------
-- get / set

function TTGameRoomFriendMediator:getMoodEmoticonLayer()
    return self.moodEmoticonLayer_
end
function TTGameRoomFriendMediator:getMoodLayerViewData()
    return self:getMoodEmoticonLayer():getViewData()
end


function TTGameRoomFriendMediator:getOpponentData()
    return self.opponentData_
end
function TTGameRoomFriendMediator:setOpponentData(data)
    if data then
        self.opponentData_ = {
            opponentUuid   = tostring(data.opponentUuid),        -- 对手唯一ID
            opponentName   = tostring(data.opponentName),        -- 对手名称
            opponentAvatar = checkint(data.opponentAvatar),      -- 对手头像
            opponentAFrame = checkint(data.opponentAvatarFrame), -- 对手头像框
            opponentReady  = checkint(data.opponentReady),       -- 0:对手未准备 1:对手已准备
        }
        self:getRoomView():updateRoomerName(self:getOpponentData().opponentName)
        self:getRoomView():updateRoomerFrame(self:getOpponentData().opponentAvatar, self:getOpponentData().opponentAFrame)
    else
        self.opponentData_ = nil
    end
    self:updateOpponentReadyStatus_()
end


-------------------------------------------------
-- public

function TTGameRoomFriendMediator:close()
    app.ttGameMgr:setBattleModel(nil)
    app.ttGameMgr:socketDestroy()
    self.super.close(self)
end


-------------------------------------------------
-- private

function TTGameRoomFriendMediator:updateOpponentReadyStatus_()
    if self:getOpponentData() then
        if checkint(self:getOpponentData().opponentReady) == 1 then
            self:getRoomView():showRoomerConfirmLayer()
        else
            self:getRoomView():showRoomerReadyLayer()
        end
        self:getViewData().playGameBtn:setEnabled(true)
    else
        self:getRoomView():showWaitingRoomerLayer()
        self:getViewData().playGameBtn:setEnabled(false)
    end
end


-------------------------------------------------
-- handler

function TTGameRoomFriendMediator:onClickBackButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end

    app.ttGameMgr:socketSendData(NetCmd.TTGAME_ROOM_LEAVE, {uuid = app.gameMgr:GetUserInfo().playerId})
end


function TTGameRoomFriendMediator:onClickPlayGameButtonHandler_(sender)
    if self.super.onClickPlayGameButtonHandler_(self, sender) then

        if self:getOpponentData() then
            self.isControllable_ = false
            self:getRoomView():stopAllActions()
            self:getRoomView():runAction(cc.Sequence:create(
                cc.DelayTime:create(0.3),
                cc.CallFunc:create(function()
                    self.isControllable_ = true
                end)
            ))
    
            self.isToReadyConnect_ = true
            app.ttGameMgr:socketSendData(NetCmd.TTGAME_ROOM_READY, {ready = 1, deckId = self:getDeckSelectIndex()})
        else
            app.uiMgr:ShowInformationTips(__('对手不存在，无法进行准备'))
        end

    end
end


function TTGameRoomFriendMediator:onClickCancelReadyButtonHandler_(sender)
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

    self.isToReadyConnect_ = false
    app.ttGameMgr:socketSendData(NetCmd.TTGAME_ROOM_READY, {ready = 0})
end


function TTGameRoomFriendMediator:onClickMoodTalkButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    self:getMoodEmoticonLayer():showMoodEmoticonView()
end


function TTGameRoomFriendMediator:onClickMoodEmoticonCellHandler_(moodId)
    self:getMoodEmoticonLayer():closeMoodEmoticonView()
    
    TTGameMoodLayer.UpdateMoodEntry(self.operatorMoodEntryVD_, moodId)
    app.ttGameMgr:socketSendData(NetCmd.TTGAME_ROOM_MOOD, {
        uuid      = app.gameMgr:GetUserInfo().playerId,
        messageId = moodId,
    })
end


return TTGameRoomFriendMediator

--[[
 * author : kaishiqi
 * descpt : 打牌游戏 - 主页中介者
]]
local TTGameHomeMediator = class('TripleTriadGameHomeMediator', mvc.Mediator)

function TTGameHomeMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'TripleTriadGameHomeMediator', viewComponent)

    local initArgs = checktable(params)
    self.ctorArgs_ = initArgs.requestData or {}
    self.homeArgs_ = initArgs
    self.homeArgs_.requestData = nil
end


-------------------------------------------------
-- inheritance method

function TTGameHomeMediator:Initial(key)
    self.super.Initial(self, key)

    -- init vars
    self.isControllable_  = true
    self.backToMdtName_   = self.ctorArgs_.backMdt or 'HomeMediator'
    self.resultSglName_   = self.ctorArgs_.resultSglName
    self.initBattleType_  = checkint(self.ctorArgs_.battleType)
    self.initBattleNpcId_ = checkint(self.ctorArgs_.battleNpdId)
    
    -- create view
    self.homeScene_ = app.uiMgr:SwitchToTargetScene('Game.views.ttGame.TripleTriadGameHomeScene')
    self:SetViewComponent(self.homeScene_)
    
    -- add listener
    local homeViewData = self:getViewData()
    display.commonUIParams(homeViewData.backBtn, {cb = handler(self, self.onClickBackButtonHandler_)})
    display.commonUIParams(homeViewData.titleBtn, {cb = handler(self, self.onClickTitleButtonHandler_)})
    display.commonUIParams(homeViewData.guideBtn, {cb = handler(self, self.onClickGuideButtonHandler_)})
    display.commonUIParams(homeViewData.ruleLayer, {cb = handler(self, self.onClickRuleLayerHandler_)})
    display.commonUIParams(homeViewData.reportBtn, {cb = handler(self, self.onClickReportButtonHandler_)})
    display.commonUIParams(homeViewData.albumBtn, {cb = handler(self, self.onClickAlbumButtonHandler_)})
    display.commonUIParams(homeViewData.shopBtn, {cb = handler(self, self.onClickShopButtonHandler_)})
    display.commonUIParams(homeViewData.pvpDateBtn, {cb = handler(self, self.onClickPvpDateButtonHandler_)})
    display.commonUIParams(homeViewData.pvpBattleBtn, {cb = handler(self, self.onClickPvpBattleButtonHandler_)})
    display.commonUIParams(homeViewData.pveEnterLayer, {cb = handler(self, self.onClickPveBattleButtonHandler_)})
    display.commonUIParams(homeViewData.roomFindBtn, {cb = handler(self, self.onClickRoomFindButtonHandler_)})
    display.commonUIParams(homeViewData.roomCreateBtn, {cb = handler(self, self.onClickRoomCreateButtonHandler_)})
    homeViewData.pvpBattleBtn:setOnClickScriptHandler(handler(self, self.onClickPvpBattleButtonHandler_))
    
    -- update views
    self:initHomeData_(self.homeArgs_)

    if isGuideOpened('ttGame') then
        app.uiMgr:showModuleGuide('ttGame')
    end
end


function TTGameHomeMediator:CleanupView()
    self:stopLeftTimeCountdownUpdate_()
end


function TTGameHomeMediator:OnRegist()
    app:DispatchObservers(HomeScene_ChangeCenterContainer, "rightHide")
    app:DispatchObservers(HomeScene_ChangeCenterContainer, "allhide")
    regPost(POST.TTGAME_HOME)
end


function TTGameHomeMediator:OnUnRegist()
    app:DispatchObservers(HomeScene_ChangeCenterContainer, "rightShow")
    app:DispatchObservers(HomeScene_ChangeCenterContainer, "hide")
    unregPost(POST.TTGAME_HOME)
end


function TTGameHomeMediator:InterestSignals()
    return {
        POST.TTGAME_HOME.sglName,
        SGL.CACHE_MONEY_UPDATE_UI,
        SGL.TTGAME_SOCKET_CONNECTED,
        SGL.TTGAME_SOCKET_UNEXPECTED,
        SGL.TTGAME_SOCKET_NET_LINK,
        SGL.TTGAME_BATTLE_CARD_ADD,
    }
end
function TTGameHomeMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()

    if name == POST.TTGAME_HOME.sglName then
        self:initHomeData_(data)


    elseif name == SGL.CACHE_MONEY_UPDATE_UI then
        self:getTTGameScene():updateMoneyBar()


    elseif name == SGL.TTGAME_SOCKET_UNEXPECTED then
        local errText = tostring(data.errText)
        local errcode = checkint(data.errcode)
        if errcode == -100 then
            app.gameMgr:ShowGameAlertView({
                text     = __('该局打牌已经结束'),
                isOnlyOK = true,
                callback = function()
                    self:GetFacade():DispatchObservers(SGL.TTGAME_BATTLE_INVALID)
                end
            })
        elseif errcode == -99 then
            app.gameMgr:ShowGameAlertView({
                text     = __('由于超时，您已离开房间'),
                isOnlyOK = true,
                callback = function()
                    local roomNo = app.ttGameMgr:getBattleModel():getBattleRoomId()
                    self:GetFacade():DispatchObservers(SGL.TTGAME_BATTLE_INVALID)
                    self:GetFacade():DispatchObservers(SGL.TTGAME_SOCKET_ROOM_LEAVE, {roomNo = roomNo})
                end
            })
        else
            app.gameMgr:ShowGameAlertView({
                text     = __('打牌遇到了一点意外，原因：') .. errText,
                isOnlyOK = true,
                callback = function()
                    self:GetFacade():DispatchObservers(SGL.TTGAME_BATTLE_UNEXPECTED)
                end
            })
        end


    elseif name == SGL.TTGAME_SOCKET_CONNECTED then
        app.ttGameMgr:socketSendData(NetCmd.TTGAME_NET_LINK)


    elseif name == SGL.TTGAME_SOCKET_NET_LINK then
        if app.ttGameMgr:getBattleModel() then
            app.ttGameMgr:socketSendData(NetCmd.TTGAME_NET_SYNC, {roomNo = app.ttGameMgr:getBattleModel():getBattleRoomId()})
        else
            self:GetFacade():DispatchObservers(SGL.TTGAME_BATTLE_CONNECTED)
        end


    elseif name == SGL.TTGAME_BATTLE_CARD_ADD then
        self:getTTGameScene():updateBattleCardNum(app.ttGameMgr:getBattleCardNum(), app.ttGameMgr:getBattleCardTotal())

    end
end


-------------------------------------------------
-- get / set

function TTGameHomeMediator:getTTGameScene()
    return self.homeScene_
end

function TTGameHomeMediator:getViewData()
    return self:getTTGameScene():getViewData()
end


-------------------------------------------------
-- public

function TTGameHomeMediator:close()
    TTGameUtils.CleanSpineCache()
    app.ttGameMgr:setLastBattleResult(nil)
    app.router:Dispatch({name = self:GetMediatorName()}, {name = self.backToMdtName_, params = self.ctorArgs_})
end


-------------------------------------------------
-- private

function TTGameHomeMediator:initHomeData_(initData)
    -- init homeData
    app.ttGameMgr:setHomeData(initData)

    -- update views
    self:getTTGameScene():updateRuleList(app.ttGameMgr:getTodayRuleList())
    self:getTTGameScene():updatePveSwitchStatus(app.ttGameMgr:isOpeningPve())
    self:getTTGameScene():updatePvpSwitchStatus(app.ttGameMgr:isOpeningPvp())
    self:getTTGameScene():updatePveLeftSeconds(app.ttGameMgr:getPveLeftSeconds())
    self:getTTGameScene():updatePvpLeftSeconds(app.ttGameMgr:getPvpLeftSeconds())
    self:getTTGameScene():updateBattleCardNum(app.ttGameMgr:getBattleCardNum(), app.ttGameMgr:getBattleCardTotal())
    self:startLeftTimeCountdownUpdate_()

    local activityConfInfo = TTGameUtils.GetConfAt(TTGAME_DEFINE.CONF_TYPE.ACTIVITY, app.ttGameMgr:getSummaryId())
    self:getTTGameScene():updatePveEnterImage(activityConfInfo.titlePicture)

    if self.initBattleType_ == TTGAME_DEFINE.BATTLE_TYPE.ANNIVERSARY and self.initBattleNpcId_ > 0 then
        local ttGameRoomPveMdt = require('Game.mediator.ttGame.TripleTriadGameRoomPveMediator').new({
            npcId         = self.initBattleNpcId_, 
            anniMode      = true,
            customcloseCB = function()
                if self.resultSglName_ and app.ttGameMgr:getLastBattleResult() then
                    app:DispatchObservers(self.resultSglName_, {result = app.ttGameMgr:getLastBattleResult()})
                end
                self:close()
            end
        })
        app:RegistMediator(ttGameRoomPveMdt)
    end
end


function TTGameHomeMediator:startLeftTimeCountdownUpdate_()
    if self.leftTimeCountdownHandler_ then return end
    self.leftTimeCountdownHandler_ = scheduler.scheduleGlobal(function()
        local pveLeftSeconds = app.ttGameMgr:getPveLeftSeconds()
        local pvpLeftSeconds = app.ttGameMgr:getPvpLeftSeconds()
        if ((pveLeftSeconds < 0 and pveLeftSeconds > -100) or 
            (pvpLeftSeconds < 0 and pvpLeftSeconds > -100)) then
            self:stopLeftTimeCountdownUpdate_()
            self:SendSignal(POST.TTGAME_HOME.cmdName)
        else
            self:getTTGameScene():updatePveLeftSeconds(pveLeftSeconds)
            self:getTTGameScene():updatePvpLeftSeconds(pvpLeftSeconds)
        end
    end, 1)
end
function TTGameHomeMediator:stopLeftTimeCountdownUpdate_()
    if self.leftTimeCountdownHandler_ then
        scheduler.unscheduleGlobal(self.leftTimeCountdownHandler_)
        self.leftTimeCountdownHandler_ = nil
    end
end


-------------------------------------------------
-- handler

function TTGameHomeMediator:onClickBackButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end

    self:close()
end


function TTGameHomeMediator:onClickTitleButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    app.uiMgr:ShowIntroPopup({moduleId = MODULE_DATA[tostring(RemindTag.TTGAME)]})
end


function TTGameHomeMediator:onClickGuideButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    app.uiMgr:showModuleGuide('ttGame')
end


function TTGameHomeMediator:onClickAlbumButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end
    
    local ttGameAlbumMdt = require('Game.mediator.ttGame.TripleTriadGameAlbumMediator').new()
    app:RegistMediator(ttGameAlbumMdt)
end


function TTGameHomeMediator:onClickShopButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end
    
    local ttGameShopMdt = require('Game.mediator.ttGame.TripleTriadGameShopMediator').new()
    app:RegistMediator(ttGameShopMdt)
end


function TTGameHomeMediator:onClickReportButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local ttGameReportMdt = require('Game.mediator.ttGame.TripleTriadGameReportMediator').new()
    app:RegistMediator(ttGameReportMdt)
end


function TTGameHomeMediator:onClickRuleLayerHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local ruleList = app.ttGameMgr:getTodayRuleList()
    if #ruleList > 0 then
        app.uiMgr:AddDialog('Game.views.ttGame.TripleTriadGameCardRulePopup', {ruleList = ruleList})
    else
        app.uiMgr:ShowInformationTips(__('今日暂无规则'))
    end
end


function TTGameHomeMediator:onClickRoomFindButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

	app:RegistMediator(require('Game.mediator.NumKeyboardMediator').new({
        titleText = __('请输入牌室号码'),
        model     = NumboardModel.freeModel,
        nums      = TTGAME_DEFINE.ROOM_ID_LEN,
        callback  = handler(self, self.onEnterFriendRoomCallback_),
    }))
end


function TTGameHomeMediator:onClickRoomCreateButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    self:onCreateFriendRoomCallback_()
end


function TTGameHomeMediator:onClickPvpDateButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local scheduleIdList = TTGameUtils.GetScheduleIdList(app.ttGameMgr:getSummaryId())
    app.uiMgr:AddDialog('Game.views.ttGame.TripleTriadGamePvpOpenDatePopup', {scheduleIdList = scheduleIdList})
end


function TTGameHomeMediator:onClickPvpBattleButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local ttGameRoomPvpMdt = require('Game.mediator.ttGame.TripleTriadGameRoomPvpMediator').new()
    app:RegistMediator(ttGameRoomPvpMdt)
end


function TTGameHomeMediator:onClickPveBattleButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local ttGamePveListMdt = require('Game.mediator.ttGame.TripleTriadGamePveListMediator').new()
    app:RegistMediator(ttGamePveListMdt)
end


function TTGameHomeMediator:onEnterFriendRoomCallback_(roomId)
    local enterFriendRoomId   = checkint(roomId)
    if enterFriendRoomId > 0 then
        local ttGameRoomFriendMdt = require('Game.mediator.ttGame.TripleTriadGameRoomFriendMediator').new({
            roomId = enterFriendRoomId
        })
        app:RegistMediator(ttGameRoomFriendMdt)
    else
        app.uiMgr:ShowInformationTips(__('请输入有效的牌室号'))
    end
end


function TTGameHomeMediator:onCreateFriendRoomCallback_(roomId)
    local ttGameRoomFriendMdt = require('Game.mediator.ttGame.TripleTriadGameRoomFriendMediator').new()
    app:RegistMediator(ttGameRoomFriendMdt)
end


return TTGameHomeMediator

--[[
 * author : kaishiqi
 * descpt : 打牌游戏 - 基础房间中介者
]]
local TTGameBaseRoomView     = require('Game.views.ttGame.TripleTriadGameRoomBaseView')
local TTGameBaseRoomMediator = class('TripleTriadGameRoomBaseMediator', mvc.Mediator)

function TTGameBaseRoomMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'TripleTriadGameRoomBaseMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end


-------------------------------------------------
-- inheritance

function TTGameBaseRoomMediator:Initial(key)
    self.super.Initial(self, key)
    self:InitialView(TTGameBaseRoomView)
end


function TTGameBaseRoomMediator:InitialView(TTGameRoomViewClass)
    -- init vars
    self.isControllable_ = true

    -- create view
    self.roomView_   = TTGameRoomViewClass.new()
    self.ownerScene_ = app.uiMgr:GetCurrentScene()
    self:getOwnerScene():AddGameLayer(self:getRoomView())
    self:SetViewComponent(self:getRoomView())

    -- add listener
    display.commonUIParams(self:getViewData().backBtn, {cb = handler(self, self.onClickBackButtonHandler_)})
    display.commonUIParams(self:getViewData().ruleLayer, {cb = handler(self, self.onClickRuleLayerHandler_), animate = false})
    display.commonUIParams(self:getViewData().playGameBtn, {cb = handler(self, self.onClickPlayGameButtonHandler_)})
    display.commonUIParams(self:getViewData().deckFrameImage, {cb = handler(self, self.onClickDeckFrameImageHandler_), animate = false})
    
    for deckIndex, indexBtn in ipairs(self:getViewData().deckIndexBtnList) do
        display.commonUIParams(indexBtn, {cb = handler(self, self.onClickDeckIndexButtonHandler_), animate = false})
    end

    -- update views
    self:getRoomView():updateRewardGoodsList(self:getRewardList())
    self:getRoomView():updateRewardLeftTimes(self:getRewardTimes())
    self:getRoomView():updateRuleList(self:getRuleList())
    self:setDeckSelectIndex(1)
end


function TTGameBaseRoomMediator:CleanupView()
    local viewComponent = self:GetViewComponent()
    if self.ownerScene_ and viewComponent and not tolua.isnull(viewComponent) then
        self.ownerScene_:RemoveDialog(viewComponent)
        self.ownerScene_ = nil
    end
end


function TTGameBaseRoomMediator:OnRegist()
end


function TTGameBaseRoomMediator:OnUnRegist()
end


function TTGameBaseRoomMediator:InterestSignals()
    return {
    }
end
function TTGameBaseRoomMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()
end


-------------------------------------------------
-- get / set

function TTGameBaseRoomMediator:getOwnerScene()
    return self.ownerScene_
end


function TTGameBaseRoomMediator:getRoomView()
    return self.roomView_  
end
function TTGameBaseRoomMediator:getViewData()
    return self:getRoomView():getViewData()
end


function TTGameBaseRoomMediator:getRuleList()
    return app.ttGameMgr:getTodayRuleList()
end


function TTGameBaseRoomMediator:getRewardList()
    return nil
end


function TTGameBaseRoomMediator:getRewardTimes()
    return 0
end


function TTGameBaseRoomMediator:getDeckSelectIndex()
    return self.deckSelectIndex_
end
function TTGameBaseRoomMediator:setDeckSelectIndex(deckIndex)
    self.deckSelectIndex_ = checkint(deckIndex)
    local deckCardList = app.ttGameMgr:getDeckCardsAt(self:getDeckSelectIndex())
    self:getRoomView():updateDeckCardNodeList(deckCardList)
    self:getRoomView():updateDeckSelectIndex(self:getDeckSelectIndex())
end


-------------------------------------------------
-- public

function TTGameBaseRoomMediator:close()
    app:UnRegsitMediator(self:GetMediatorName())
    if app:RetrieveMediator('TripleTriadGameDeckMediator') then
        app:UnRegsitMediator('TripleTriadGameDeckMediator')
    end
end


-------------------------------------------------
-- private


-------------------------------------------------
-- handler

function TTGameBaseRoomMediator:onClickBackButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end

    self:close()
end


function TTGameBaseRoomMediator:onClickRuleLayerHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local ruleList = self:getRuleList()
    if #ruleList > 0 then
        app.uiMgr:AddDialog('Game.views.ttGame.TripleTriadGameCardRulePopup', {ruleList = ruleList})
    else
        app.uiMgr:ShowInformationTips(__('今日暂无规则'))
    end
end


function TTGameBaseRoomMediator:onClickDeckIndexButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local deckSelectIndex = checkint(sender:getTag())
    if deckSelectIndex ~= self:getDeckSelectIndex() then
        self:setDeckSelectIndex(deckSelectIndex)
    else
        sender:setChecked(true)
    end
end


function TTGameBaseRoomMediator:onClickDeckFrameImageHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local ttGameDeckMdt = require('Game.mediator.ttGame.TripleTriadGameDeckMediator').new({deckIndex = self:getDeckSelectIndex(), savedCB = function()
        local deckCardList = app.ttGameMgr:getDeckCardsAt(self:getDeckSelectIndex())
        self:getRoomView():updateDeckCardNodeList(deckCardList)
    end})
    app:RegistMediator(ttGameDeckMdt)
end


function TTGameBaseRoomMediator:onClickPlayGameButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local deckCardList = app.ttGameMgr:getDeckCardsAt(self:getDeckSelectIndex())
    if #deckCardList <= 0 then
        app.uiMgr:ShowInformationTips(__('空卡组不可以出战'))
        return false
    end
    return true
end


return TTGameBaseRoomMediator

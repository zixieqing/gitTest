--[[
 * author : kaishiqi
 * descpt : 打牌游戏 - PVE列表中介者
]]
local TTGamePveListView     = require('Game.views.ttGame.TripleTriadGamePveListView')
local TTGamePveListMediator = class('TripleTriadGamePveListMediator', mvc.Mediator)

function TTGamePveListMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'TripleTriadGamePveListMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end


-------------------------------------------------
-- inheritance

function TTGamePveListMediator:Initial(key)
    self.super.Initial(self, key)

    -- init vars
    self.pveListCellDict_  = {}
    self.isControllable_   = true
    self.hasBattleCardNum_ = app.ttGameMgr:getHasBattleCardNum()

    -- create view
    self.pveListView_ = TTGamePveListView.new()
    self.ownerScene_  = app.uiMgr:GetCurrentScene()
    self:getOwnerScene():AddGameLayer(self:getPveListView())
    self:SetViewComponent(self:getPveListView())

    -- add listener
    display.commonUIParams(self:getViewData().backBtn, {cb = handler(self, self.onClickBackButtonHandler_)})
    display.commonUIParams(self:getViewData().titleBtn, {cb = handler(self, self.onClickTitleButtonHandler_)})
    self:getViewData().pveGridView:setDataSourceAdapterScriptHandler(handler(self, self.onLibPveGridDataAdapterHandler_))

    -- update views
    local activityConfInfo = TTGameUtils.GetConfAt(TTGAME_DEFINE.CONF_TYPE.ACTIVITY, app.ttGameMgr:getSummaryId())
    self:getPveListView():updateBgImage(activityConfInfo.picture)
    
    local scheduleConfInfo  = TTGameUtils.GetConfAt(TTGAME_DEFINE.CONF_TYPE.SCHEDULE, app.ttGameMgr:getScheduleId())
    local npcDefineConfFile = TTGameUtils.GetConf(TTGAME_DEFINE.CONF_TYPE.NPC_DEFINE)
    local pveNpcListData    = {}
    for _, npcId in ipairs(scheduleConfInfo.npc or {}) do
        table.insert(pveNpcListData, npcDefineConfFile[tostring(npcId)])
    end
    self:setPveNpcListData(pveNpcListData)
end


function TTGamePveListMediator:CleanupView()
    local viewComponent = self:GetViewComponent()
    if self.ownerScene_ and viewComponent and not tolua.isnull(viewComponent) then
        self.ownerScene_:RemoveDialog(viewComponent)
        self.ownerScene_ = nil
    end
end


function TTGamePveListMediator:OnRegist()
end


function TTGamePveListMediator:OnUnRegist()
end


function TTGamePveListMediator:InterestSignals()
    return {
        SGL.CACHE_MONEY_UPDATE_UI,
        SGL.TTGAME_BATTLE_CARD_ADD,
    }
end
function TTGamePveListMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()

    if name == SGL.CACHE_MONEY_UPDATE_UI then
        self:getPveListView():updateMoneyBar()


    elseif name == SGL.TTGAME_BATTLE_CARD_ADD then
        for _, cellViewData in pairs(self.pveListCellDict_) do
            self:updateLibraryCardCell_(cellViewData.view:getTag(), cellViewData)
        end
    end
end


-------------------------------------------------
-- get / set

function TTGamePveListMediator:getOwnerScene()
    return self.ownerScene_
end


function TTGamePveListMediator:getPveListView()
    return self.pveListView_
end
function TTGamePveListMediator:getViewData()
    return self:getPveListView():getViewData()
end


function TTGamePveListMediator:getPveNpcListData()
    return self.pveNpcListData_
end
function TTGamePveListMediator:setPveNpcListData(data)
    self.pveNpcListData_ = checktable(data)
    self:getViewData().pveGridView:setCountOfCell(#self:getPveNpcListData())
    self:getViewData().pveGridView:reloadData()
end


-------------------------------------------------
-- public

function TTGamePveListMediator:close()
    app:UnRegsitMediator(self:GetMediatorName())
end


-------------------------------------------------
-- private

function TTGamePveListMediator:updateLibraryCardCell_(cellIndex, viewData)
    local pveGridView  = self:getViewData().pveGridView
    local cellViewData = viewData or self.pveListCellDict_[pveGridView:cellAtIndex(cellIndex - 1)]
    local npcConfInfo  = self:getPveNpcListData()[checkint(cellIndex)] or {}

    if cellViewData then
        local unlockCardNum = checkint(npcConfInfo.unlockCollectNum)
        local hasUnlockNpc  = self.hasBattleCardNum_ >= unlockCardNum
        cellViewData.unlockLayer:setVisible(hasUnlockNpc)
        cellViewData.lockLayer:setVisible(not hasUnlockNpc)

        -- update name
        display.commonLabelParams(cellViewData.nameLabel, {reqW = 180 ,  text = tostring(npcConfInfo.name)})
        cellViewData.nameLabel:setPositionX(20)
        -- update cards
        display.commonLabelParams(cellViewData.cardsLabel, { text = string.fmt('%1 / %2', self.hasBattleCardNum_, unlockCardNum)})

        -- update unlockTips
        display.commonLabelParams(cellViewData.unlockLabel, {text = string.fmt(__('收集_num_张战牌解锁挑战'), {_num_ = unlockCardNum})})

        -- update ruleTips
        cellViewData.ruleTipsLayer:setVisible(#checktable(npcConfInfo.rules) > 0)

        -- update rewards
        local showCardIdList = checktable(npcConfInfo.showReward)
        for index, cardNode in ipairs(cellViewData.rewardCardList) do
            if showCardIdList[index] then
                cardNode:setVisible(true)
                cardNode:setCardId(showCardIdList[index])
                if app.ttGameMgr:hasBattleCardId(cardNode:getCardId()) then
                    cardNode:showHaveCardMark()
                else
                    cardNode:hideHaveCardMark()
                end
            else
                cardNode:setVisible(false)
            end
        end

        -- update npcImage
        cellViewData.npcImgLayer:removeAllChildren()
        cellViewData.npcImgLayer:addChild(TTGameUtils.GetNpcDrawNode(npcConfInfo.id))
    end
end


-------------------------------------------------
-- handler

function TTGamePveListMediator:onClickBackButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end

    self:close()
end


function TTGamePveListMediator:onClickTitleButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    app.uiMgr:ShowIntroPopup({moduleId = MODULE_DATA.TTGAME_PVE})
end


function TTGamePveListMediator:onLibPveGridDataAdapterHandler_(cell, idx)
    local pCell = cell
    local index = idx + 1

    if pCell == nil then
        local cellNodeSize = self:getViewData().pveGridView:getSizeOfCell()
        local cellViewData = TTGamePveListView.CreatePveCell(cellNodeSize)
        display.commonUIParams(cellViewData.hotspot, {cb = handler(self, self.onClickPveGridCellHandler_)})

        pCell = cellViewData.view
        self.pveListCellDict_[pCell] = cellViewData
    end
    
    local cellViewData = self.pveListCellDict_[pCell]
    cellViewData.view:setTag(index)
    cellViewData.hotspot:setTag(index)
    self:updateLibraryCardCell_(index, cellViewData)
    return pCell
end


function TTGamePveListMediator:onClickPveGridCellHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local pveDataIndex  = checkint(sender:getTag())
    local npcConfInfo   = self:getPveNpcListData()[pveDataIndex] or {}
    local unlockCardNum = checkint(npcConfInfo.unlockCollectNum)
    local hasUnlockNpc  = self.hasBattleCardNum_ >= unlockCardNum
    if hasUnlockNpc then
        local ttGameRoomPveMdt = require('Game.mediator.ttGame.TripleTriadGameRoomPveMediator').new({npcId = tostring(npcConfInfo.id)})
        app:RegistMediator(ttGameRoomPveMdt)
    end
end


return TTGamePveListMediator

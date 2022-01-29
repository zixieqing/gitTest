--[[
 * author : kaishiqi
 * descpt : 打牌游戏 - 牌册中介者
]]
local TTGameAlbumView     = require('Game.views.ttGame.TripleTriadGameAlbumView')
local TTGameAlbumMediator = class('TripleTriadGameAlbumMediator', mvc.Mediator)

function TTGameAlbumMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'TripleTriadGameAlbumMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end


-------------------------------------------------
-- inheritance

function TTGameAlbumMediator:Initial(key)
    self.super.Initial(self, key)

    -- init vars
    self.albumCellDict_  = {}
    self.albumConfFile_  = TTGameUtils.GetConf(TTGAME_DEFINE.CONF_TYPE.CARD_ALBUM)
    self.isControllable_ = true

    -- create view
    self.albumView_  = TTGameAlbumView.new()
    self.ownerScene_ = app.uiMgr:GetCurrentScene()
    self:getOwnerScene():AddGameLayer(self:getAlbumView())
    self:SetViewComponent(self:getAlbumView())

    -- add listener
    local albumViewData = self:getViewData()
    display.commonUIParams(albumViewData.backBtn, {cb = handler(self, self.onClickBackButtonHandler_)})
    display.commonUIParams(albumViewData.titleBtn, {cb = handler(self, self.onClickTitleButtonHandler_)})
    
    -- update views
    for deckIndex, cellViewData in ipairs(self:getAlbumView():getDeckList()) do
        local hasDeckList = not app.ttGameMgr:isEmptyDeckAt(deckIndex)
        self:getAlbumView():updateDeckCellStatue(deckIndex, hasDeckList)

        cellViewData.hotspot:setTag(deckIndex)
        display.commonUIParams(cellViewData.hotspot, {cb = handler(self, self.onClickDeckCellHandler_)})
    end
    
    albumViewData.albumListView:setDataSourceAdapterScriptHandler(handler(self, self.onAlbumListDataAdapterHandler_))
    albumViewData.albumListView:setCountOfCell(table.nums(self:getAlbumConfFile()))
    albumViewData.albumListView:reloadData()
end


function TTGameAlbumMediator:CleanupView()
    local viewComponent = self:GetViewComponent()
    if self.ownerScene_ and viewComponent and not tolua.isnull(viewComponent) then
        self.ownerScene_:RemoveGameLayer(viewComponent)
        self.ownerScene_ = nil
    end
end


function TTGameAlbumMediator:OnRegist()
    regPost(POST.TTGAME_DRAW_COLLECT)
end


function TTGameAlbumMediator:OnUnRegist()
    unregPost(POST.TTGAME_DRAW_COLLECT)
end


function TTGameAlbumMediator:InterestSignals()
    return {
        POST.TTGAME_DRAW_COLLECT.sglName
    }
end
function TTGameAlbumMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()

    if name == POST.TTGAME_DRAW_COLLECT.sglName then
        local albumId = checkint(data.requestData.collectId)
        app.ttGameMgr:addCollectAlbumId(albumId)
        app.uiMgr:AddDialog('common.RewardPopup', {
            rewards       = checktable(data.rewards),
            closeCallback = function()
                self:updateAlbumCell_(albumId)
            end
        })
    end
end


-------------------------------------------------
-- get / set

function TTGameAlbumMediator:getOwnerScene()
    return self.ownerScene_
end


function TTGameAlbumMediator:getAlbumView()
    return self.albumView_
end
function TTGameAlbumMediator:getViewData()
    return self:getAlbumView():getViewData()
end


function TTGameAlbumMediator:getAlbumConfFile()
    return self.albumConfFile_
end


-------------------------------------------------
-- public

function TTGameAlbumMediator:close()
    app:UnRegsitMediator(self:GetMediatorName())
end


-------------------------------------------------
-- private

function TTGameAlbumMediator:initAlbumCell_(cellIndex, viewData)
    display.commonUIParams(viewData.lockingLayer, {cb = handler(self, self.onClickAlbumRewardLockingLayerHandler_)})
    display.commonUIParams(viewData.disableLayer, {cb = handler(self, self.onClickAlbumRewardDisableLayerHandler_)})
    display.commonUIParams(viewData.drawableLayer, {cb = handler(self, self.onClickAlbumRewardDrawableLayerHandler_)})
end


function TTGameAlbumMediator:updateAlbumCell_(cellIndex, viewData)
    local albumListView = self:getViewData().albumListView
    local cellViewData  = viewData or self.albumCellDict_[albumListView:cellAtIndex(cellIndex - 1)]
    local albumConfInfo = self:getAlbumConfFile()[tostring(cellIndex)] or {}

    if cellViewData then
        local collectCards   = albumConfInfo.cards or {}
        local collectTarget  = #collectCards
        local collectCurrent = 0
        for index, cardNode in ipairs(cellViewData.cardNodeList) do
            local cardId = checkint(collectCards[index])
            cardNode:setVisible(cardId ~= 0)
            cardNode:setCardId(cardId)

            if cardId > 0 and app.ttGameMgr:hasBattleCardId(cardId) then
                collectCurrent = collectCurrent + 1
                cardNode:toNormalStatus()
            else
                cardNode:toBlockedStatus()
            end
        end
        
        -- update rewards icon
        self:getAlbumView():updateAlbumCellRewardIcon(cellViewData, albumConfInfo.picture)

        -- update rewards status
        cellViewData.lockingLayer:setTag(cellIndex)
        cellViewData.disableLayer:setTag(cellIndex)
        cellViewData.drawableLayer:setTag(cellIndex)
        local collectAlbumId = checkint(albumConfInfo.id)
        if app.ttGameMgr:hasCollecAlbumId(collectAlbumId) then
            self:getAlbumView():updateAlbumCellTodisableStatue(cellViewData)
        else
            if collectCurrent >= collectTarget then
                self:getAlbumView():updateAlbumCellToDrawbleStatue(cellViewData)
            else
                self:getAlbumView():updateAlbumCellToLockingStatue(cellViewData)
            end
        end
        
        -- update labels info
        display.commonLabelParams(cellViewData.albumNameLabel, {text = tostring(albumConfInfo.name)})
        display.commonLabelParams(cellViewData.collectNumLabel, {text = string.fmt('%1 / %2', collectCurrent, collectTarget)})
    end
end


-------------------------------------------------
-- handler

function TTGameAlbumMediator:onClickBackButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end

    self:close()
end


function TTGameAlbumMediator:onClickTitleButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    app.uiMgr:ShowIntroPopup({moduleId = MODULE_DATA.TTGAME_ALBUM})
end


function TTGameAlbumMediator:onClickDeckCellHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local clickDeckIndex = checkint(sender:getTag())
    local ttGameDeckMdt  = require('Game.mediator.ttGame.TripleTriadGameDeckMediator').new({deckIndex = clickDeckIndex, savedCB = function()
        local hasDeckList = not app.ttGameMgr:isEmptyDeckAt(clickDeckIndex)
        self:getAlbumView():updateDeckCellStatue(clickDeckIndex, hasDeckList)
    end})
    app:RegistMediator(ttGameDeckMdt)
end


function TTGameAlbumMediator:onAlbumListDataAdapterHandler_(cell, idx)
    local pCell = cell
    local index = idx + 1

    if pCell == nil then
        local cellNodeSize = self:getViewData().albumListView:getSizeOfCell()
        local cellViewData = TTGameAlbumView.createAlbumCell(cellNodeSize)
        self.albumCellDict_[cellViewData.view] = cellViewData
        self:initAlbumCell_(index, cellViewData)
        pCell = cellViewData.view
    end
    
    local cellViewData = self.albumCellDict_[pCell]
    self:updateAlbumCell_(index, cellViewData)
    return pCell
end


function TTGameAlbumMediator:onClickAlbumRewardLockingLayerHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local albumCellIndex = sender:getTag()
    local albumConfInfo  = self:getAlbumConfFile()[tostring(albumCellIndex)] or {}
    local albumRewards   = checktable(albumConfInfo.rewards)
    local albumTitle     = string.fmt(__('集齐 “_name_” 内所有战牌可领取：'), {_name_ = tostring(albumConfInfo.name)})
    app.uiMgr:ShowInformationTipsBoard({targetNode = sender, iconIds = albumRewards, type = 4, title = albumTitle})
end


function TTGameAlbumMediator:onClickAlbumRewardDrawableLayerHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    self.isControllable_ = false
    transition.execute(self:getAlbumView(), nil, {delay = 0.3, complete = function()
        self.isControllable_ = true
    end})
    self:SendSignal(POST.TTGAME_DRAW_COLLECT.cmdName, {collectId = sender:getTag()})
end


function TTGameAlbumMediator:onClickAlbumRewardDisableLayerHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end
end


return TTGameAlbumMediator

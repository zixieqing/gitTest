--[[
 * author : kaishiqi
 * descpt : 打牌游戏 - 卡组中介者
]]
local TTGameDeckView     = require('Game.views.ttGame.TripleTriadGameDeckView')
local TTGameTypeLayer    = require('Game.views.ttGame.TripleTriadGameTypeFilterLayer')
local TTGameDeckMediator = class('TripleTriadGameDeckMediator', mvc.Mediator)

local TYPE_ALL = TTGAME_DEFINE.FILTER_TYPE_ALL

function TTGameDeckMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'TripleTriadGameDeckMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end


-------------------------------------------------
-- inheritance

function TTGameDeckMediator:Initial(key)
    self.super.Initial(self, key)

    -- init vars
    self.deckIndex_       = checkint(self.ctorArgs_.deckIndex)
    self.savedCallback_   = self.ctorArgs_.savedCB
    self.deckCardIdList_  = {}
    self.deckCardIdDict_  = {}
    self.freeCardIdDict_  = {}
    self.libCardCellDict_ = {}
    self.isControllable_  = true

    self.filterCardStar_ = 1
    self.filterCardType_ = TYPE_ALL
    self.libraryCardMap_ = {}
    self.starCardNumMap_ = {}
    local cardConfFile   = TTGameUtils.GetConf(TTGAME_DEFINE.CONF_TYPE.CARD_DEFINE)
    for _, cardId in ipairs(app.ttGameMgr:getBattleCardList()) do
        local cardConf = cardConfFile[tostring(cardId)] or {}
        local cardStar = checkint(cardConf.star)
        local cardType = checkint(cardConf.type)
        local cardData = {cardId = cardId, cardConf = cardConf}

        self.libraryCardMap_[tostring(cardStar)] = self.libraryCardMap_[tostring(cardStar)] or {}
        self.libraryCardMap_[tostring(cardStar)][tostring(TYPE_ALL)] = self.libraryCardMap_[tostring(cardStar)][tostring(TYPE_ALL)] or {}
        self.libraryCardMap_[tostring(cardStar)][tostring(cardType)] = self.libraryCardMap_[tostring(cardStar)][tostring(cardType)] or {}
        table.insert(self.libraryCardMap_[tostring(cardStar)][tostring(TYPE_ALL)], cardData)
        if cardType ~= TYPE_ALL then
            table.insert(self.libraryCardMap_[tostring(cardStar)][tostring(cardType)], cardData)
        end
    end

    -- create view
    self.shopView_    = TTGameDeckView.new()
    self.ownerScene_  = app.uiMgr:GetCurrentScene()
    self:getOwnerScene():AddGameLayer(self:getDeckView())
    self:SetViewComponent(self:getDeckView())

    self.typeFilterLayer_ = TTGameTypeLayer.new({closeCB = function()
        self:getViewData().typeFilterBtn:setChecked(false)
    end})
    self:getOwnerScene():AddDialog(self:getTypeFilterLayer())

    -- add listener
    local deckViewData = self:getViewData()
    display.commonUIParams(deckViewData.backBtn, {cb = handler(self, self.onClickBackButtonHandler_)})
    display.commonUIParams(deckViewData.saveBtn, {cb = handler(self, self.onClickSaveButtonHandler_)})
    display.commonUIParams(deckViewData.unlockLayer, {cb = handler(self, self.onClickUnlockLayerHandler_)})
    display.commonUIParams(deckViewData.typeFilterBtn, {cb = handler(self, self.onClickTypeFilterButtonHandler_), animate = false})
    deckViewData.cardGridView:setDataSourceAdapterScriptHandler(handler(self, self.onLibCardGridDataAdapterHandler_))
    self:getTypeFilterLayer():setClickTypeCellCB(handler(self, self.onClickFilterTypeCellHandler_))

    for _, cellViewData in ipairs(self:getDeckView():getStarCellViewDataList()) do
        display.commonUIParams(cellViewData.hotspot, {cb = handler(self, self.onClickStarFilterCellHandler_)})
    end
    for _, cellViewData in ipairs(self:getDeckView():getDeckCardViewDataList()) do
        display.commonUIParams(cellViewData.hotspot, {cb = handler(self, self.onClickDeckCardCellHandler_)})
    end

    -- update views
    self:getTypeFilterLayer():getTypeCellLayer():setPosition(cc.pAdd(deckViewData.typeFilterBtn:convertToWorldSpaceAR(PointZero), cc.p(-90,-25)))
    self:getTypeFilterLayer():getTypeCellLayer():setAnchorPoint(display.LEFT_TOP)
    self:getTypeFilterLayer():setSelectFilterType(self:getFilterCardType())
    self:getTypeFilterLayer():closeTypeFilterView()

    self:getDeckView():updateUnlockLevel(app.ttGameMgr:getCurrentStarLimit())
    self:getDeckView():updateDeckIndex(self:getDeckIndex())
    self:updateLibraryCardGridData_()
    
    for _, cardId in ipairs(app.ttGameMgr:getDeckCardsAt(self:getDeckIndex())) do
        self:appendDeckCardIdAt(cardId)
    end
end


function TTGameDeckMediator:CleanupView()
    local viewComponent = self:GetViewComponent()
    if self.ownerScene_ and viewComponent and not tolua.isnull(viewComponent) then
        self.ownerScene_:RemoveGameLayer(viewComponent)
        self.ownerScene_ = nil
    end

    if self:getTypeFilterLayer() and not tolua.isnull(self:getTypeFilterLayer()) then
        self:getTypeFilterLayer():close()
        self.typeFilterLayer_ = nil
    end
end


function TTGameDeckMediator:OnRegist()
    regPost(POST.TTGAME_DECK_SAVE)
end


function TTGameDeckMediator:OnUnRegist()
    unregPost(POST.TTGAME_DECK_SAVE)
end


function TTGameDeckMediator:InterestSignals()
    return {
        POST.TTGAME_DECK_SAVE.sglName
    }
end
function TTGameDeckMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()

    if name == POST.TTGAME_DECK_SAVE.sglName then
        -- update ttGameMgr cacheData
        app.ttGameMgr:setDeckCardsAt(self:getDeckIndex(), self.deckCardIdList_)
        
        app.uiMgr:ShowInformationTips(string.fmt(__('_num_号卡组保存成功'), {_num_ = self:getDeckIndex()}))

        if self.savedCallback_ then
            self.savedCallback_()
        end
        self:close()
    end
end


-------------------------------------------------
-- get / set

function TTGameDeckMediator:getOwnerScene()
    return self.ownerScene_
end


function TTGameDeckMediator:getDeckView()
    return self.shopView_
end
function TTGameDeckMediator:getViewData()
    return self:getDeckView():getViewData()
end


function TTGameDeckMediator:getTypeFilterLayer()
    return self.typeFilterLayer_
end
function TTGameDeckMediator:getTypeLayerViewData()
    return self:getTypeFilterLayer():getViewData()
end


function TTGameDeckMediator:getDeckIndex()
    return self.deckIndex_
end


function TTGameDeckMediator:hasDeckCardIdAt(cardId)
    return self.deckCardIdDict_[tostring(cardId)] ~= nil
end
function TTGameDeckMediator:getDeckCardIndexAt(cardId)
    return checkint(self.deckCardIdDict_[tostring(cardId)])
end
function TTGameDeckMediator:getDeckCardIdAt(index)
    return checkint(self.deckCardIdList_[tostring(index)])
end
function TTGameDeckMediator:isDeckCardFull()
    return #self.deckCardIdList_ >= TTGAME_DEFINE.DECK_CARD_NUM
end


function TTGameDeckMediator:getFilterCardDatas()
    return self.filterCardDatas_
end
function TTGameDeckMediator:setFilterCardDatas(data)
    self.filterCardDatas_ = checktable(data)
    self:updateLibraryCardGridView_()
end


function TTGameDeckMediator:getFilterCardStar()
    return self.filterCardStar_
end
function TTGameDeckMediator:setFilterCardStar(star)
    self.filterCardStar_ = checkint(star)
    self:updateLibraryCardGridData_()
    self:updateLibraryCardGridView_()
end


function TTGameDeckMediator:getFilterCardType()
    return self.filterCardType_
end
function TTGameDeckMediator:setFilterCardType(type)
    self.filterCardType_ = checkint(type)
    self:updateLibraryCardGridData_()
    self:updateLibraryCardGridView_()
end


-------------------------------------------------
-- public

function TTGameDeckMediator:close()
    app:UnRegsitMediator(self:GetMediatorName())
end


function TTGameDeckMediator:isExistsDeckCardIdAt(index)
    return self.deckCardIdList_[checkint(index)] ~= nil
end
function TTGameDeckMediator:appendDeckCardIdAt(cardId)
    local index = #self.deckCardIdList_ + 1
    self.deckCardIdList_[checkint(index)]  = checkint(cardId)
    self.deckCardIdDict_[tostring(cardId)] = index

    local cardConInfo = TTGameUtils.GetConfAt(TTGAME_DEFINE.CONF_TYPE.CARD_DEFINE, cardId)
    if checkint(cardConInfo.star) > app.ttGameMgr:getCurrentStarLimit() then
        self.freeCardIdDict_[tostring(cardId)] = true
    end

    -- update deckCard
    for cardIndex, cellViewData in ipairs(self:getDeckView():getDeckCardViewDataList()) do
        local deckCardId = checkint(self.deckCardIdList_[cardIndex])
        if cellViewData.cardNode:getCardId() ~= deckCardId then
            cellViewData.cardNode:setCardId(deckCardId)
        end
        cellViewData.cardNode:setVisible(deckCardId > 0)
    end

    -- update libraryCard
    for _, cellViewData in pairs(self.libCardCellDict_) do
        if cellViewData.cardNode:getCardId() == checkint(cardId) then
            cellViewData.cardNode:toSelectStatus()
        end
    end
end
function TTGameDeckMediator:removeDeckCardIdAt(index)
    local cardId = checkint(table.remove(self.deckCardIdList_, index))
    self.deckCardIdDict_[tostring(cardId)] = nil
    self.freeCardIdDict_[tostring(cardId)] = nil
    for index, cardId in ipairs(self.deckCardIdList_) do
        self.deckCardIdDict_[tostring(cardId)] = index
    end

    -- update deckCard
    for cardIndex, cellViewData in ipairs(self:getDeckView():getDeckCardViewDataList()) do
        local deckCardId = checkint(self.deckCardIdList_[cardIndex])
        if cellViewData.cardNode:getCardId() ~= deckCardId then
            cellViewData.cardNode:setCardId(deckCardId)
        end
        cellViewData.cardNode:setVisible(deckCardId > 0)
    end

    -- update libraryCard
    for _, cellViewData in pairs(self.libCardCellDict_) do
        if cellViewData.cardNode:getCardId() == cardId then
            cellViewData.cardNode:toNormalStatus()
        end
    end
end


-------------------------------------------------
-- private

function TTGameDeckMediator:updateLibraryCardGridData_()
    self.starCardNumMap_ = {}
    for starNum = 1, TTGAME_DEFINE.STAR_MAXIMUM do
        local starCardMap  = self.libraryCardMap_[tostring(starNum)] or {}
        local typeCardList = starCardMap[tostring(self:getFilterCardType())] or {}
        self.starCardNumMap_[tostring(starNum)] = #typeCardList
    end
    
    local starCardMap = self.libraryCardMap_[tostring(self:getFilterCardStar())] or {}
    self:setFilterCardDatas(starCardMap[tostring(self:getFilterCardType())])
end
function TTGameDeckMediator:updateLibraryCardGridView_()
    self:getDeckView():updateFilterStarStatus(self:getFilterCardStar(), self.starCardNumMap_)
    self:getViewData().cardGridView:setCountOfCell(#self:getFilterCardDatas())
    self:getViewData().cardGridView:reloadData()
end


function TTGameDeckMediator:updateLibraryCardCell_(cellIndex, viewData)
    local cardGridView   = self:getViewData().cardGridView
    local cellViewData   = viewData or self.libCardCellDict_[cardGridView:cellAtIndex(cellIndex - 1)]
    local filterCardData = self:getFilterCardDatas()[checkint(cellIndex)] or {}

    if cellViewData then
        if self:hasDeckCardIdAt(filterCardData.cardId) then
            cellViewData.cardNode:toSelectStatus()
        else
            cellViewData.cardNode:toNormalStatus()
        end
        cellViewData.cardNode:setCardId(filterCardData.cardId)
    end
end


-------------------------------------------------
-- handler

function TTGameDeckMediator:onClickBackButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end

    local cacheDeckCardList  = app.ttGameMgr:getDeckCardsAt(self:getDeckIndex())
    local editedDeckCardList = self.deckCardIdList_
    local isChangedDeckCard  = #cacheDeckCardList ~= #editedDeckCardList
    if not isChangedDeckCard then
        for i = 1, #cacheDeckCardList do
            local cacheCardId  = checkint(cacheDeckCardList[i])
            local editedcardId = checkint(editedDeckCardList[i])
            if cacheCardId ~= editedcardId then
                isChangedDeckCard = true
                break
            end
        end
    end
        
    if isChangedDeckCard then
        local tipString = __('编辑的卡组尚未保存，是否依然关闭？')
        local commonTip = require('common.NewCommonTip').new({text = tipString, callback = function()
            self:close()
        end})
        commonTip:setPosition(display.center)
        app.uiMgr:GetCurrentScene():AddDialog(commonTip)
    else
        self:close()
    end
end


function TTGameDeckMediator:onClickSaveButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    if #self.deckCardIdList_ > 0 then
        self.isControllable_ = false
        transition.execute(self:getDeckView(), nil, {delay = 0.3, complete = function()
            self.isControllable_ = true
        end})
        if self:isDeckCardFull() then
            self:SendSignal(POST.TTGAME_DECK_SAVE.cmdName, {deckId = self:getDeckIndex(), battleCards = table.concat(self.deckCardIdList_, ',')})
        else
            app.uiMgr:ShowInformationTips(__('卡组需要填满才可以保存'))
        end
    else
       app.uiMgr:ShowInformationTips(__('空卡组不能保存'))
    end
end


function TTGameDeckMediator:onClickUnlockLayerHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    app.uiMgr:AddDialog('Game.views.ttGame.TripleTriadGameStarUnlockPopup')
end


function TTGameDeckMediator:onLibCardGridDataAdapterHandler_(cell, idx)
    local pCell = cell
    local index = idx + 1

    if pCell == nil then
        local cellNodeSize = self:getViewData().cardGridView:getSizeOfCell()
        local cellViewData = TTGameDeckView.CreateLibraryCardCell(cellNodeSize)
        display.commonUIParams(cellViewData.hotspot, {cb = handler(self, self.onClickLibraryCardCellHandler_)})

        pCell = cellViewData.view
        self.libCardCellDict_[pCell] = cellViewData
    end
    
    local cellViewData = self.libCardCellDict_[pCell]
    cellViewData.view:setTag(index)
    cellViewData.hotspot:setTag(index)
    self:updateLibraryCardCell_(index, cellViewData)
    return pCell
end


function TTGameDeckMediator:onClickStarFilterCellHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    if self:getFilterCardStar() ~= sender:getTag() then
        self:setFilterCardStar(sender:getTag())
    end
end


function TTGameDeckMediator:onClickTypeFilterButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    self:getViewData().typeFilterBtn:setChecked(true)
    self:getTypeFilterLayer():showTypeFilterView()
end


function TTGameDeckMediator:onClickFilterTypeCellHandler_(typeId)
    self:getTypeFilterLayer():setSelectFilterType(typeId)
    self:getTypeFilterLayer():closeTypeFilterView()

    local typeConfInfo = TTGameUtils.GetConfAt(TTGAME_DEFINE.CONF_TYPE.CARD_CAMP, typeId)
    self:getDeckView():updateFilterButtonLabel(typeConfInfo.name)
    self:setFilterCardType(typeId)
end


function TTGameDeckMediator:onClickDeckCardCellHandler_(sender)
    if not self.isControllable_ then return end
    
    local deckCardIndex = checkint(sender:getTag())
    if self:isExistsDeckCardIdAt(deckCardIndex) then
        PlayAudioByClickNormal()
        self:removeDeckCardIdAt(deckCardIndex)
    end
end


function TTGameDeckMediator:onClickLibraryCardCellHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local cardDataIndex  = checkint(sender:getTag())
    local filterCardData = self:getFilterCardDatas()[cardDataIndex] or {}
    local clickLibCardId = checkint(filterCardData.cardId)
    local clickCardConf  = checktable(filterCardData.cardConf)
    if clickLibCardId > 0 then

        -- check same deckCard : to remove
        if self:hasDeckCardIdAt(clickLibCardId) then
            local deckCardIndex = self:getDeckCardIndexAt(clickLibCardId)
            self:removeDeckCardIdAt(deckCardIndex)

        else
            -- check full deckCard : to tips
            if self:isDeckCardFull() then
                app.uiMgr:ShowInformationTips(__('卡组已满，请卸下其他卡牌再尝试'))
            else
                -- check star limit
                if checkint(clickCardConf.star) > app.ttGameMgr:getCurrentStarLimit() then

                    -- check freeCard count : to tips
                    if table.nums(self.freeCardIdDict_) >= TTGAME_DEFINE.DECK_FREE_NUM then
                        app.uiMgr:ShowInformationTips(string.fmt(__('已存在_num_张任意等级卡牌\n其余卡牌需遵从等级解锁限制'), {_num_ = TTGAME_DEFINE.DECK_FREE_NUM}))
    
                        -- tips all freeCard
                        for cardId, _ in pairs(self.freeCardIdDict_) do
                            local deckCardIndex = checkint(self.deckCardIdDict_[cardId])
                            local cellViewData  = self:getDeckView():getDeckCardViewDataList()[deckCardIndex]
                            if cellViewData then
                                cellViewData.cardNode:showStarLimitTips()
                            end
                        end

                    else
                        self:appendDeckCardIdAt(clickLibCardId)
                    end

                else
                    self:appendDeckCardIdAt(clickLibCardId)
                end
            end
        end
    end
end


return TTGameDeckMediator

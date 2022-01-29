--[[
 * author : kaishiqi
 * descpt : 爬塔 - 牌库编辑界面中介者
]]
local TowerModelFactory                 = require('Game.models.TowerQuestModelFactory')
local TowerQuestModel                   = TowerModelFactory.getModelType('TowerQuest')
local TowerQuestEditCardLibraryView     = require('Game.views.TowerQuestEditCardLibraryView')
local TowerQuestEditCardLibraryMediator = class('TowerQuestEditCardLibraryMediator', mvc.Mediator)

function TowerQuestEditCardLibraryMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'TowerQuestEditCardLibraryMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end


-------------------------------------------------
-- inheritance method

function TowerQuestEditCardLibraryMediator:Initial(key)
    self.super.Initial(self, key)

    local isIgnoreShowView     = self.ctorArgs_.isIgnoreShowView == true
    self.towerHomeMdt_         = self:GetFacade():RetrieveMediator('TowerQuestHomeMediator')
    self.isControllable_       = true
    self.isFirstToEditStatus_  = true
    self.prevLibraryCardList_  = checktable(self.ctorArgs_.selectedCards)
    self.libraryCardGuidList_  = {}
    self.libraryCardCellList_  = {}
    self.privateCardCellDict_  = {}
    self.privateCardFilterMap_ = self:createPrivateCardFilterMap_()

    -- create view
    local homeScene = self.towerHomeMdt_:getHomeScene()
    self.editView_  = TowerQuestEditCardLibraryView.new()
	homeScene:AddDialog(self.editView_)

    -- init view
    local editViewData = self.editView_:getViewData()
    display.commonUIParams(editViewData.backBtn, {cb = handler(self, self.onClickBackButtonHandler_)})
    display.commonUIParams(editViewData.comboBtn, {cb = handler(self, self.onClickComboButtonHandler_), animate = false})
    display.commonUIParams(editViewData.cleanBtn, {cb = handler(self, self.onClickCleanButtonHandler_)})
    display.commonUIParams(editViewData.confirmBtn, {cb = handler(self, self.onClickConfirmButtonHandler_), animate = false})
    display.commonUIParams(editViewData.editLibraryBtn, {cb = handler(self, self.onClickEditLibrarayButtonHandler_), animate = false})
    editViewData.privateCardGridView:setDataSourceAdapterScriptHandler(handler(self, self.onPrivateCardGridDataAdapterHandler_))
    for _, filterBtn in ipairs(editViewData.filterBtnList) do
        display.commonUIParams(filterBtn, {cb = handler(self, self.onClickPrivateCardFilterButtonHandler_), animate = false})
    end

    -- update view
    self:updateLibraryCardNum_()
    self:setCheckedCSkillStatus(false)

    for i, cardGuid in ipairs(self.prevLibraryCardList_) do
        self:appendLibraryCardAt_(cardGuid)
    end

    -- show ui
    self.isControllable_ = false
    if not isIgnoreShowView then
        self:showUI()
    end
end


function TowerQuestEditCardLibraryMediator:CleanupView()
    if self.editView_ then
        local homeScene = self.towerHomeMdt_:getHomeScene()
        homeScene:RemoveDialog(self.editView_)
        self.editView_ = nil
    end
end


function TowerQuestEditCardLibraryMediator:OnRegist()
    regPost(POST.TOWER_SET_CARD_LIBRARY)
end
function TowerQuestEditCardLibraryMediator:OnUnRegist()
    unregPost(POST.TOWER_SET_CARD_LIBRARY)
end


function TowerQuestEditCardLibraryMediator:InterestSignals()
    return {
        POST.TOWER_SET_CARD_LIBRARY.sglName,
        SGL.PRESET_TEAM_SELECT_CARDS,
    }
end
function TowerQuestEditCardLibraryMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()

    if name == POST.TOWER_SET_CARD_LIBRARY.sglName then
        
        self:GetFacade():DispatchObservers(SGL.TOWER_QUEST_SET_CARD_LIBRARY, {cardList = clone(self.libraryCardGuidList_)})
        self.isControllable_      = true
        self.prevLibraryCardList_ = clone(self.libraryCardGuidList_)

        local requestData = data.requestData or {}
        if checkint(requestData.toEdit) > 0 then
            self:toEditStatus()
        else
            self:toTeamStatus()
        end
    elseif name == SGL.PRESET_TEAM_SELECT_CARDS then
        local presetTeamData = data.presetTeamData
        local towerModel    = self.towerHomeMdt_:getTowerModel()
        local teamId = checkint(presetTeamData.teamId)
        towerModel:setTeamCustomId(teamId)

        local cardIds = presetTeamData.cardIds or {}
        local cardList = {}
        for _, v in pairs(cardIds) do
            for _, playerCardId in pairs(v) do
                table.insert(cardList, playerCardId)
            end
        end

        self:reloadLibraryCards(cardList)
        --
        self:SendSignal(POST.TOWER_SET_CARD_LIBRARY.cmdName, {teamCustomId = teamId, teamCards = table.concat(cardList, ',')})
    end
end


-------------------------------------------------
-- get / set

function TowerQuestEditCardLibraryMediator:getPrivateCardFilterType()
    return checkint(self.privateCardFilterType_)
end
function TowerQuestEditCardLibraryMediator:setPrivateCardFilterType(filterType)
    self.privateCardFilterType_ = checkint(filterType)
    self:updatePrivateCardFilterList_()
end


function TowerQuestEditCardLibraryMediator:isCheckedCSkillStatus()
    return self.isCheckedCSkillStatus_ == true
end
function TowerQuestEditCardLibraryMediator:setCheckedCSkillStatus(isChecked)
    self.isCheckedCSkillStatus_ = isChecked == true
    self:updateCheckedCSkillStatus_()
end


-------------------------------------------------
-- public method

function TowerQuestEditCardLibraryMediator:close()
    self:GetFacade():UnRegsitMediator(self:GetMediatorName())
end


function TowerQuestEditCardLibraryMediator:showUI()
    self.editView_:showView(#self.prevLibraryCardList_ > 0, function()
        self.isControllable_ = true
    end)
end


function TowerQuestEditCardLibraryMediator:toNoneStatus()
    if not self.isControllable_ then return end
    self.isControllable_ = false

    if #self.libraryCardGuidList_ > 0 then
        self.editView_:showLibraryHide(function()
            self.isControllable_ = true
        end)
    else
        self.editView_:showLibraryCards(function()
            self.editView_:showLibraryHide(function()
                self.isControllable_ = true
            end)
        end)
    end
end
function TowerQuestEditCardLibraryMediator:toTeamStatus()
    if not self.isControllable_ then return end

    self.isControllable_ = false
    self.editView_:showLibraryCards(function()
        self.isControllable_ = true
    end)

    if self:isCheckedCSkillStatus() then
        self:setCheckedCSkillStatus(false)
    end
end
function TowerQuestEditCardLibraryMediator:toEditStatus()
    if not self.isControllable_ then return end
    self.isControllable_ = false

    local checkFirstFunc = function()
        if self.isFirstToEditStatus_ then
            self:setPrivateCardFilterType(TowerQuestEditCardLibraryView.FILTER_TYPE[1].type)
            self.isFirstToEditStatus_ = false
        end
    end

    if #self.libraryCardGuidList_ > 0 then
        if self.editView_  and (not tolua.isnull(self.editView_) ) then
            self.editView_:showLibraryEdit(function()
                self.isControllable_ = true
                checkFirstFunc()
            end)
        end
    else
        self.editView_:showLibraryCards(function()
            self.editView_:showLibraryEdit(function()
                self.isControllable_ = true
                checkFirstFunc()
            end)
        end)
    end
end


-------------------------------------------------
-- private method

function TowerQuestEditCardLibraryMediator:createPrivateCardFilterMap_()
    local gameManager   = self:GetFacade():GetManager('GameManager')
    local cardsDataMap  = gameManager:GetUserInfo().cards or {}
    local cardFilterMap = {}

    -- filter card data
    for cardGuid, cardData in pairs(cardsDataMap) do
        local cardConf = CommonUtils.GetConfig('cards', 'card', cardData.cardId) or {}
        local cardType = checkint(cardConf.career)
        cardFilterMap[tostring(cardType)] = cardFilterMap[tostring(cardType)] or {}
        table.insert(cardFilterMap[tostring(cardType)], cardGuid)
    end
    cardFilterMap[tostring(CARD_FILTER_TYPE_ALL)] = table.keys(cardsDataMap)

    -- sort card data
    for filterType, cardGuidList in pairs(cardFilterMap) do
        table.sort(cardGuidList, function(a, b)
            local aCardData = gameManager:GetCardDataById(a) or {}
            local bCardData = gameManager:GetCardDataById(b) or {}
            local aCardConf = CommonUtils.GetConfig('cards', 'card', aCardData.cardId) or {}
            local bCardConf = CommonUtils.GetConfig('cards', 'card', bCardData.cardId) or {}

            local sortResult = true
            if checkint(aCardConf.qualityId) == checkint(bCardConf.qualityId) then
                if checkint(aCardData.breakLevel) == checkint(bCardData.breakLevel) then
                    if checkint(aCardData.level) == checkint(bCardData.level) then
                        sortResult = checkint(aCardData.cardId) > checkint(bCardData.cardId)  -- 卡牌cardId升序
                    else
                        sortResult = checkint(aCardData.level) > checkint(bCardData.level)  -- 卡牌等级降序
                    end
                else
                    sortResult = checkint(aCardData.breakLevel) > checkint(bCardData.breakLevel)  -- 卡牌突破等级降序
                end
            else
                sortResult = checkint(aCardConf.qualityId) > checkint(bCardConf.qualityId)  -- 卡牌质量等级降序
            end
            return sortResult
        end)
    end
    return cardFilterMap
end


function TowerQuestEditCardLibraryMediator:getGridCellAtIndex_(gridPageView, cellIndex)
    if not gridPageView then return nil end
    local gridPages = gridPageView:getContainer():getChildren()
    for _, gridPage in ipairs(gridPages) do
        local gridCells = gridPage:getChildren()
        for _, gridCell in ipairs(gridCells) do
            if gridCell:getIdx() == cellIndex then
                return gridCell
            end
        end
    end
    return nil
end


function TowerQuestEditCardLibraryMediator:updateLibraryCardNum_()
    local editViewData = self.editView_:getViewData()
    display.commonLabelParams(editViewData.numberBar, {text = string.fmt('%1 / %2', #self.libraryCardGuidList_, TowerQuestModel.LIBRARY_CARD_MAX)})
end


function TowerQuestEditCardLibraryMediator:updateCheckedCSkillStatus_(isFast)
    -- update combo button status
    local editViewData = self.editView_:getViewData()
    editViewData.comboBtn:setChecked(self:isCheckedCSkillStatus())
    
    -- update library cards status
    for i, cellViewData in ipairs(self.libraryCardCellList_) do
        self:updateLibraryCardCellCSkillStatus_(cellViewData, isFast)
    end
end
function TowerQuestEditCardLibraryMediator:updateLibraryCardCellCSkillStatus_(cellViewData, isFast)
    if self:isCheckedCSkillStatus() then
        self.editView_:showLibraryCardCellCSkill(cellViewData, isFast)
    else
        self.editView_:hideLibraryCardCellCSkill(cellViewData, isFast)
    end
end
function TowerQuestEditCardLibraryMediator:updateAllLibraryCSkillActivateStatus_()
    local gameManager = self:GetFacade():GetManager('GameManager')
    local cardManager = self:GetFacade():GetManager('CardManager')

    local formationData = {}
    for i, cardGuid in ipairs(self.libraryCardGuidList_) do
        local cardData   = gameManager:GetCardDataById(cardGuid) or {}
        formationData[i] = {cardId = cardData.cardId}
    end

    for i, v in ipairs(formationData) do
        local cellViewData   = self.libraryCardCellList_[i]
        local isEnableCSkill = CardUtils.IsConnectSkillEnable(v.cardId, formationData) == true
        if cellViewData then
            if isEnableCSkill then
                cellViewData.skillLayer:setColor(cc.c3b(255, 255, 255))
            else
                cellViewData.skillLayer:setColor(cc.c3b(100, 100, 100))
            end
        end
    end
end


function TowerQuestEditCardLibraryMediator:updatePrivateCardFilterList_()
    local editViewData = self.editView_ and self.editView_:getViewData() or nil
    if editViewData then
        -- update filter buttons bar
        for i, filterBtn in ipairs(editViewData.filterBtnList) do
            local filterData = TowerQuestEditCardLibraryView.FILTER_TYPE[i] or {}
            filterBtn:setChecked(filterData.type == self:getPrivateCardFilterType())
        end

        -- update filter card list
        local filterCardList = self.privateCardFilterMap_[tostring(self:getPrivateCardFilterType())] or {}
        editViewData.privateCardGridView:setCountOfCell(#filterCardList)
        editViewData.privateCardGridView:reloadData()
    end
end
function TowerQuestEditCardLibraryMediator:updatePrivateCardCell_(index, cellViewData)
    if not self.editView_ then return end
    local cardGridView = self.editView_:getViewData().privateCardGridView
    local cellViewData = cellViewData or self.privateCardCellDict_[cardGridView:cellAtIndex(index - 1)]
    -- local cellViewData = cellViewData or self.privateCardCellDict_[self:getGridCellAtIndex_(cardGridView, index - 1)]
    
    if cellViewData then
        local filterCardList  = self.privateCardFilterMap_[tostring(self:getPrivateCardFilterType())] or {}
        local privateCardGuid = checkint(filterCardList[index])
        
        if privateCardGuid > 0 then
            cellViewData.selectLayer:setVisible(self:isInLibraryCardAt_(privateCardGuid))
        else
            cellViewData.selectLayer:setVisible(false)
        end
    end
end


function TowerQuestEditCardLibraryMediator:isInLibraryCardAt_(cardGuid)
    local isInLibraryCard = false
    for i, v in ipairs(self.libraryCardGuidList_) do
        if cardGuid == v then
            isInLibraryCard = true
            break
        end
    end
    return isInLibraryCard
end
function TowerQuestEditCardLibraryMediator:appendLibraryCardAt_(cardGuid, fromWorldPos)
    -- append for data
    table.insert(self.libraryCardGuidList_, checkint(cardGuid))

    -- appeend for cell
    self:appendLibraryCellAt_(#self.libraryCardGuidList_, cardGuid, fromWorldPos)

    -- udpate views
    self:updateLibraryCardNum_()
    self:updateAllLibraryCSkillActivateStatus_()
end
function TowerQuestEditCardLibraryMediator:removeLibraryCardAt_(cardGuid)
    -- remove for data
    local removeCardIndex = -1
    for i = #self.libraryCardGuidList_, 1, -1 do
        if self.libraryCardGuidList_[i] == checkint(cardGuid) then
            table.remove(self.libraryCardGuidList_, i)
            removeCardIndex = i
            break
        end
    end

    -- adjust latter cells
    local actionTime = 0.15
    for i = #self.libraryCardCellList_, removeCardIndex + 1, -1 do
        local currCellViewData = self.libraryCardCellList_[i]
        local prevCellViewData = self.libraryCardCellList_[i-1]
        if currCellViewData and prevCellViewData then
            currCellViewData.clickArea:setTag(prevCellViewData.clickArea:getTag())
            currCellViewData.view:stopAllActions()
            currCellViewData.view:runAction(cc.MoveTo:create(actionTime, cc.p(prevCellViewData.view:getPosition())))
        end
    end

    -- remove for cell
    self:removeLibraryCellAt_(removeCardIndex, cardGuid)

    -- update views
    self:updateLibraryCardNum_()
    self:updateAllLibraryCSkillActivateStatus_()
end
function TowerQuestEditCardLibraryMediator:cleanAllLibraryCard_()
    -- clean for data
    local oldLibraryCardGuidList = clone(self.libraryCardGuidList_)
    self.libraryCardGuidList_    = {}

    -- clean for view
    for i = #oldLibraryCardGuidList, 1, -1 do
        self:removeLibraryCellAt_(i, oldLibraryCardGuidList[i])
    end

    -- updat view
    self:updateLibraryCardNum_()
end


function TowerQuestEditCardLibraryMediator:appendLibraryCellAt_(libraryCellIndex, cardGuid, fromWorldPos)
    local editViewData = self.editView_ and self.editView_:getViewData() or nil
    if editViewData == nil then return end
    -- local libraryCellRow = math.ceil(libraryCellIndex / TowerQuestEditCardLibraryView.LIBRARY_COLS)
    -- local libraryCellCol = (libraryCellIndex - 1) % TowerQuestEditCardLibraryView.LIBRARY_COLS + 1

    -- create cell
    local libraryFrame = editViewData.libraryCardFrameList[libraryCellIndex]
    local cardFramePos = libraryFrame and cc.p(libraryFrame:getPosition()) or cc.p(0,0)
    local cellViewData = self.editView_:createLibraryCardCell()
    editViewData.libraryCardLayer:addChild(cellViewData.view)
    display.commonUIParams(cellViewData.clickArea, {cb = handler(self, self.onClickLibraryCardCellHandler_)})
    self.libraryCardCellList_[libraryCellIndex] = cellViewData

    -- init cell
    cellViewData.clickArea:setTag(libraryCellIndex)

    local cardCellSize = cellViewData.view:getContentSize()
    local cardHeadNode = require('common.CardHeadNode').new({id = cardGuid, showActionState = false})
    cardHeadNode:setPosition(cc.p(cardCellSize.width/2, cardCellSize.height/2))
    cardHeadNode:setAnchorPoint(display.CENTER)
    cardHeadNode:setScale(0.8)
    cellViewData.headLayer:addChild(cardHeadNode)
    cellViewData.cardHeadNode = cardHeadNode

    local gameMgr  = self:GetFacade():GetManager('GameManager')
    local cardMgr  = self:GetFacade():GetManager('CardManager')
    local cardData = gameMgr:GetCardDataById(cardGuid) or {}
    local cSkillId = checkint(CardUtils.GetCardConnectSkillId(cardData.cardId))
    if cSkillId > 0 then
        local skillIconPath = CommonUtils.GetSkillIconPath(checktable(CardUtils.GetSkillConfigBySkillId(cSkillId)).id)
        cellViewData.skillLayer:removeAllChildren()
        cellViewData.skillLayer:addChild(display.newImageView(_res(skillIconPath), 0, 0, {scale = 0.5}))
    else
        cellViewData.comboLayer:setVisible(false)
    end

    self:updateLibraryCardCellCSkillStatus_(cellViewData, true)

    -- update position
    if fromWorldPos then
        local actionTime   = 0.15
        local fromeNodePos = cellViewData.view:getParent():convertToNodeSpace(fromWorldPos)
        cellViewData.view:setPosition(fromeNodePos)
        cellViewData.view:setScale(0)
        cellViewData.view:runAction(cc.Spawn:create({
            cc.MoveTo:create(actionTime, cardFramePos),
            cc.ScaleTo:create(actionTime, 1)
        }))
    else
        cellViewData.view:setPosition(cardFramePos)
    end
end
function TowerQuestEditCardLibraryMediator:removeLibraryCellAt_(libraryCellIndex, cardGuid)
    local cellViewData = self.libraryCardCellList_[libraryCellIndex]
    if cellViewData then

        -- do remove action
        local actionTime = 0.15
        cellViewData.view:stopAllActions()
        cellViewData.view:runAction(cc.Sequence:create({
            cc.Spawn:create({
                cc.TargetedAction:create(cellViewData.blackBg, cc.FadeTo:create(actionTime, 0)),
                cc.FadeTo:create(actionTime, 0),
                cc.ScaleTo:create(actionTime, 1.5)
            }),
            cc.RemoveSelf:create()
        }))

        -- remove for view
        table.remove(self.libraryCardCellList_, libraryCellIndex)
    end

    -- update private card cell
    local filterCardList  = self.privateCardFilterMap_[tostring(self:getPrivateCardFilterType())] or {}
    for _, cellViewData in pairs(self.privateCardCellDict_) do
        local privateCardIndex = cellViewData.clickArea:getTag()
        local privateCardGuid  = checkint(filterCardList[privateCardIndex])
        if cardGuid == privateCardGuid then
            self:updatePrivateCardCell_(privateCardIndex, cellViewData)
        end
    end
end

function TowerQuestEditCardLibraryMediator:reloadLibraryCards(cardList)
    self:cleanAllLibraryCard_()

    self.prevLibraryCardList_  = checktable(cardList)
    for i, cardGuid in ipairs(self.prevLibraryCardList_) do
        self:appendLibraryCardAt_(cardGuid)
    end

end

-------------------------------------------------
-- handler

function TowerQuestEditCardLibraryMediator:onClickBackButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end

    -- check modify for prev library
    local isModify = #self.libraryCardGuidList_ ~= #self.prevLibraryCardList_
    if not isModify then
        for i = 1, #self.libraryCardGuidList_ do
            if checkint(self.libraryCardGuidList_[i]) ~= checkint(self.prevLibraryCardList_[i]) then
                isModify = true
                break
            end
        end
    end

    local closeFunc = function()
        if #self.libraryCardGuidList_ > 0 then
            self:toTeamStatus()
        else
            self:toNoneStatus()
        end
    end

    if isModify then
        local gameManager = self:GetFacade():GetManager('GameManager')
        gameManager:ShowGameAlertView({text = __('预备队伍发生改变，是否放弃当前的修改？'), callback = function()
            -- clean current library
            self:cleanAllLibraryCard_()

            -- recover prev library
            for i, cardGuid in ipairs(self.prevLibraryCardList_) do
                self:appendLibraryCardAt_(cardGuid)

                -- update private card cell
                local filterCardList  = self.privateCardFilterMap_[tostring(self:getPrivateCardFilterType())] or {}
                for _, cellViewData in pairs(self.privateCardCellDict_) do
                    local privateCardIndex = cellViewData.clickArea:getTag()
                    local privateCardGuid  = checkint(filterCardList[privateCardIndex])
                    if cardGuid == privateCardGuid then
                        self:updatePrivateCardCell_(privateCardIndex, cellViewData)
                    end
                end
            end

            closeFunc()
        end})
    else
        closeFunc()
    end
end


function TowerQuestEditCardLibraryMediator:onClickComboButtonHandler_(sender)
    PlayAudioByClickClose()
    sender:setChecked(not sender:isChecked())
    if not self.isControllable_ then return end
    if not self.editView_ then return end
    
    self.isControllable_ = false
    transition.execute(self.editView_, nil, {delay = 0.3, complete = function()
        self.isControllable_ = true
    end})

    self:setCheckedCSkillStatus(not self:isCheckedCSkillStatus())
end


function TowerQuestEditCardLibraryMediator:onClickCleanButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end
    if not self.editView_ then return end

    self.isControllable_ = false
    transition.execute(self.editView_, nil, {delay = 0.3, complete = function()
        self.isControllable_ = true
    end})

    self:cleanAllLibraryCard_()
end


function TowerQuestEditCardLibraryMediator:onClickConfirmButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end
    if not self.editView_ then return end
    
    if #self.libraryCardGuidList_ < TowerQuestModel.LIBRARY_CARD_MIN then
        local uiMgr = self:GetFacade():GetManager('UIManager')
        uiMgr:ShowInformationTips(string.fmt(__('预备队伍不能少于%1人'), TowerQuestModel.LIBRARY_CARD_MIN))
        return
    end
    
    self.isControllable_ = false
    transition.execute(self.editView_, nil, {delay = 0.3, complete = function()
        self.isControllable_ = true
    end})

    self:SendSignal(POST.TOWER_SET_CARD_LIBRARY.cmdName, {teamCards = table.concat(self.libraryCardGuidList_, ',')})
end


function TowerQuestEditCardLibraryMediator:onClickPrivateCardFilterButtonHandler_(sender)
    PlayAudioByClickClose()
    sender:setChecked(not sender:isChecked())
    if not self.isControllable_ then return end
    if not self.editView_ then return end

    local filterIndex = checkint(sender:getTag())
    local filterData  = TowerQuestEditCardLibraryView.FILTER_TYPE[filterIndex]
    if filterData and self:getPrivateCardFilterType() ~= filterData.type then
        self:setPrivateCardFilterType(filterData.type)

        self.isControllable_ = false
        transition.execute(self.editView_, nil, {delay = 0.3, complete = function()
            self.isControllable_ = true
        end})
    end
end


function TowerQuestEditCardLibraryMediator:onPrivateCardGridDataAdapterHandler_(cell, idx)
    local pCell = cell
    local index = idx + 1

    if not self.editView_ then
        return pCell
    end

    local editViewData = self.editView_:getViewData()
    local cardGridView = editViewData.privateCardGridView
    local cardCellSize = cardGridView:getSizeOfCell()

    -- create cell
    if pCell == nil then
        local cellViewData = self.editView_:createPrivateCardCell(cardCellSize)
        display.commonUIParams(cellViewData.clickArea, {cb = handler(self, self.onClickPrivateCardCellHandler_)})

        pCell = cellViewData.view
        self.privateCardCellDict_[pCell] = cellViewData
    end

    -- init cell
    local cellViewData = self.privateCardCellDict_[pCell]
    cellViewData.clickArea:setTag(index)

    local filterCardList  = self.privateCardFilterMap_[tostring(self:getPrivateCardFilterType())] or {}
    local privateCardGuid = checkint(filterCardList[index])
    if privateCardGuid > 0 then
        cellViewData.view:setVisible(true)

        if not cellViewData.cardHeadNode then
            -- delay create, optimize showing speed
            local createHeadFunc = function(cellViewData, privateCardGuid)
                local cardHeadNode = require('common.CardHeadNode').new({id = privateCardGuid, showActionState = false})
                cardHeadNode:setPosition(cc.p(cardCellSize.width/2, cardCellSize.height/2))
                cardHeadNode:setScale(0.65)
                cellViewData.headLayer:addChild(cardHeadNode)
                cellViewData.cardHeadNode = cardHeadNode
            end

            -- cellViewData.headLayer:runAction(cc.Sequence:create({
            --     cc.DelayTime:create(0.01 + index * 0.04),
            --     cc.CallFunc:create(function()
                    createHeadFunc(cellViewData, privateCardGuid)
            --     end)
            -- }))
        else
            cellViewData.cardHeadNode:RefreshUI({id = privateCardGuid, showActionState = false})
        end

        self:updatePrivateCardCell_(index, cellViewData)

        -- if self.isFirstToEditStatus_ then
        --     cellViewData.view:setScale(0)
        --     cellViewData.view:runAction(cc.Sequence:create({
        --         cc.DelayTime:create((index-1) * 0.02),
        --         cc.ScaleTo:create(0.1, 1)
        --     }))
        -- end
    else
        cellViewData.view:setVisible(false)
    end
    return pCell
end


function TowerQuestEditCardLibraryMediator:onClickPrivateCardCellHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end
    if not self.editView_ then return end

    local clickCardIndex  = checkint(sender:getTag())
    local filterCardList  = self.privateCardFilterMap_[tostring(self:getPrivateCardFilterType())] or {}
    local privateCardGuid = checkint(filterCardList[clickCardIndex])

    -- add / remove library card
    if self:isInLibraryCardAt_(privateCardGuid) then
        self:removeLibraryCardAt_(privateCardGuid)
    else
        if #self.libraryCardGuidList_ < TowerQuestModel.LIBRARY_CARD_MAX then
            local senderCenterWorldPos = sender:convertToWorldSpace(cc.p(sender:getContentSize().width/2, sender:getContentSize().height/2))
            self:appendLibraryCardAt_(privateCardGuid, senderCenterWorldPos)
        else
            local uiMgr = self:GetFacade():GetManager('UIManager')
            uiMgr:ShowInformationTips(__('预备队伍已满员'))
        end
    end

    self.isControllable_ = false
    transition.execute(self.editView_, nil, {delay = 0.3, complete = function()
        self.isControllable_ = true
    end})

    -- update private card cell
    self:updatePrivateCardCell_(clickCardIndex)
end


function TowerQuestEditCardLibraryMediator:onClickLibraryCardCellHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end
    if not self.editView_ then return end

    local clickCardIndex  = checkint(sender:getTag())
    local libraryCardGuid = checkint(self.libraryCardGuidList_[clickCardIndex])

    if self:isCheckedCSkillStatus() then
        local uiMgr    = self:GetFacade():GetManager('UIManager')
        local gameMgr  = self:GetFacade():GetManager('GameManager')
        local cardMgr  = self:GetFacade():GetManager('CardManager')
        local cardData = gameMgr:GetCardDataById(libraryCardGuid) or {}
        local cSkillId = checkint(CardUtils.GetCardConnectSkillId(cardData.cardId))

        -- check have cSkill
        if cSkillId > 0 then
            local showCSkillData = {
                cardId = cardData.cardId,
                id     = libraryCardGuid,
                tag    = 1234,
            }

            -- show CSkill layer
            local cardCSkillLayer = require('Game.views.ShowConcertSkillMes').new(showCSkillData)
            display.commonUIParams(cardCSkillLayer, {ap = display.CENTER, po = display.center, tag = showCSkillData.tag})
            uiMgr:GetCurrentScene():AddDialog(cardCSkillLayer)

        else
            uiMgr:ShowInformationTips(__('该卡牌没有连携技'))
        end

    else
        -- remove library card
        self:removeLibraryCardAt_(libraryCardGuid)

        self.isControllable_ = false
        transition.execute(self.editView_, nil, {delay = 0.3, complete = function()
            self.isControllable_ = true
        end})
    end
end


function TowerQuestEditCardLibraryMediator:onClickEditLibrarayButtonHandler_(snder)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end
    local towerModel = self.towerHomeMdt_:getTowerModel()
    if checkint(towerModel:getTeamCustomId()) > 0 then
        app.uiMgr:AddNewCommonTipDialog({
            text = __('使用预设编队不能进行单独修改，是否使用普通编队？'),
            callback = function()
                self:cleanAllLibraryCard_()
                --self:reloadLibraryCards({})
                --- 清除 预设编队id
                towerModel:setTeamCustomId(0)
                --app:DispatchObservers(POST.TOWER_SET_CARD_LIBRARY.sglName, {
                --    requestData = {teamCards = table.concat({}, ','), toEdit = true}
                --})
                self:SendSignal(POST.TOWER_SET_CARD_LIBRARY.cmdName, {teamCards = '', clear = 1, toEdit = 1})
            end
        })

        return
    end
    self:toEditStatus()
end


return TowerQuestEditCardLibraryMediator

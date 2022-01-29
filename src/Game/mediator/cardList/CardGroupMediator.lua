--[[
 * author : panmeng
 * descpt : 卡牌自定义分组
]]
local CardGroupView     = require('Game.views.cardList.CardGroupView')
local CardGroupMediator = class('CardGroupMediator', mvc.Mediator)

function CardGroupMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'CardGroupMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end

local SORT_TYPE_TAG = CardGroupView.SORT_TYPE_TAG
local SORT_DEFINE   = CardGroupView.SORT_TYPE_DEFINE

-------------------------------------------------
-- inheritance

function CardGroupMediator:Initial(key)
    self.super.Initial(self, key)

    -- init vars
    self.isControllable_ = true

    -- create view
    self.viewNode_ = CardGroupView.new()
    self:SetViewComponent(self:getViewNode())
    app.uiMgr:GetCurrentScene():AddDialog(self:getViewNode())

    -- initView
    self:getViewData().groupGridView:setCellInitHandler(function(cellViewData)
        ui.bindClick(cellViewData.view, handler(self, self.onClickGroupCellNodeHandler_))
    end)
    self:getViewData().groupGridView:setCellUpdateHandler(handler(self, self.onUpdateGroupCellHandler_))

    self:getViewData().cardGridView:setCellInitHandler(function(cellViewData)
        ui.bindClick(cellViewData.view, handler(self, self.onClickCardCellNodeHandler_))
    end)
    self:getViewData().cardGridView:setCellUpdateHandler(handler(self, self.onUpdateCardCellHandler_))


    -- add listener
    ui.bindClick(self:getViewData().backBtn, handler(self, self.onClickBackButtonHandler_))
    ui.bindClick(self:getViewData().btnLeft, handler(self, self.onClickleftBtnHandler_))
    ui.bindClick(self:getViewData().btnRigth, handler(self, self.onClickRightBtnHandler_))
    ui.bindClick(self:getViewData().groupNameBtn, handler(self, self.onClickChangeNameBthHandler_))
    ui.bindClick(self:getViewData().emptyAddBtn, handler(self, self.onClickEmptyAddBthHandler_))
    ui.bindClick(self:getViewData().siftBtn, handler(self, self.onClickSiftBthHandler_), false)
    ui.bindClick(self:getViewData().sortBtn, handler(self, self.onClickSortBtnHandler_), false)
    ui.bindClick(self:getViewData().cleanAllBtn, handler(self, self.onClickCleanAllBtnHandler_))
    ui.bindClick(self:getViewData().confirmBtn, handler(self, self.onClickConirmBtnHandler_))
    ui.bindClick(self:getViewData().btnDown, handler(self, self.onClickDownBtnHandler_))
    ui.bindClick(self:getViewData().blackLayer, handler(self, self.onClickDownBtnHandler_), false)
    ui.bindClick(self:getViewData().btnUp, handler(self, self.onClickUpBtnHandler_))


    -- update view
    self:initAllCardData_()
    self:setIsSelectingMode(false, false)
    self:setSelectedGroupId(self.ctorArgs_.groupId or 1)
    self:getViewNode():updateSortViewVisible(false, function()
        self:getViewData().sortBtn:setChecked(false)
    end, handler(self, self.onClickSortCellHandler_))
    self:setSelectedSortType(SORT_TYPE_TAG.ALL)

    self:getViewNode():updateScreenViewVisible(false, function()
        self:getViewData().siftBtn:setChecked(false)
    end, handler(self, self.onClickSiftCellHandler_))
    self:setSelectedScreenType(CardUtils.CAREER_TYPE.BASE)
end


function CardGroupMediator:CleanupView()
    if self:getViewNode() and not tolua.isnull(self:getViewNode()) then
        self:getViewNode():removeFromParent()
        self.viewNode_ = nil
    end
end


function CardGroupMediator:OnRegist()
    regPost(POST.SAVE_CARD_CUSTOM_GROUP)
end


function CardGroupMediator:OnUnRegist()
    unregPost(POST.SAVE_CARD_CUSTOM_GROUP)
end


function CardGroupMediator:InterestSignals()
    return {
        POST.SAVE_CARD_CUSTOM_GROUP.sglName,
    }
end
function CardGroupMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()

    if name == POST.SAVE_CARD_CUSTOM_GROUP.sglName then

        if self:isChangeNameMode() then
            local groupData = app.gameMgr:getCustomGroupInfoByGroupId(data.requestData.groupId)
            groupData.name = data.requestData.name
            app.gameMgr:saveCustomGroupInfo(groupData)

            self:setGroupName(data.requestData.name)
            self:setIsChangeNameMode(false)

        else
            local groupData = clone(data.requestData)
            if groupData.playerCardIds == "" then
                groupData.playerCardIds = {}
            else
                groupData.playerCardIds = string.split(groupData.playerCardIds, ",")
            end
            app.gameMgr:saveCustomGroupInfo(groupData)

            self:setIsSelectingMode(false, true)
        end

        app.uiMgr:ShowInformationTips(__("保存成功"))


    end
end


-------------------------------------------------
-- get / set

---@return CardGroupView 
function CardGroupMediator:getViewNode()
    return  self.viewNode_
end
function CardGroupMediator:getViewData()
    return self:getViewNode():getViewData()
end


-- selected screen type
function CardGroupMediator:getSelectedScreenType()
    return checkint(self.selectedScreenType_)
end
function CardGroupMediator:setSelectedScreenType(screenType)
    self.selectedScreenType_ = checkint(screenType)
    self:getViewNode():updateScreenCellSelected(self:getSelectedScreenType())
    self:refreshCardListView_()
end


-- selcted sort type
function CardGroupMediator:getSelectedSortType()
    return checkint(self.selectedSortType_)
end
function CardGroupMediator:setSelectedSortType(sortType)
    if self:getSelectedSortType() == checkint(sortType) then
        self.isSortUP_ = not self:getIsSortUp()
    end
    self.selectedSortType_ = checkint(sortType)
    self:getViewNode():updateSortCellSelected(self:getSelectedSortType(), self:getIsSortUp())
    self:refreshCardListView_()
end
function CardGroupMediator:getIsSortUp()
    return checkbool(self.isSortUP_)
end


-- selected group id
function CardGroupMediator:setSelectedGroupId(groupId)
    self.selectedGroupId_ = checkint(groupId)
    self.groupData_       = clone(app.gameMgr:getCustomGroupInfoByGroupId(self:getSelectedGroupId()))

    self.groupCardIdMap_  = {}
    for _, playerCardId in pairs(self:getGroupData().playerCardIds) do
        self.groupCardIdMap_[checkint(playerCardId)] = true
    end

    if self:isSelectingMode() then
        self:setIsSelectingMode(false, false)
    end

    self:getViewNode():updateEmptyViewVisible(next(self:getGroupData().playerCardIds) == nil)
    self:refreshGroupView_()
    self:getViewNode():updateTitleNameStr(self:getGroupName())
end
function CardGroupMediator:getSelectedGroupId()
    return checkint(self.selectedGroupId_)
end

function CardGroupMediator:getGroupData()
    return checktable(self.groupData_)
end

function CardGroupMediator:isCardSelected(playerCardId)
    return checkbool(checktable(self.groupCardIdMap_)[checkint(playerCardId)])
end


-- selected group name
function CardGroupMediator:setGroupName(name)
    self:getGroupData().name = tostring(name)
    self:getViewNode():updateTitleNameStr(self:getGroupName())
end
function CardGroupMediator:getGroupName()
    return tostring(self:getGroupData().name)
end


function CardGroupMediator:isHidingCardListMode()
    return checkbool(self.isHidingCardList_)
end
function CardGroupMediator:setCardListVisible(visible)
    if self.isHidingCardList_ and self:isHidingCardListMode() == not checkbool(visible) then
        return
    end
    self.isHidingCardList_ = not checkbool(visible)
    self:getViewNode():updateCardListP(not self:isHidingCardListMode(), true)
end


function CardGroupMediator:isSelectingMode()
    return checkbool(self.isSelectingMode_)
end
function CardGroupMediator:setIsSelectingMode(isSelectingMode, needAnim)
    if self.isSelectingMode_ and checkbool(isSelectingMode) == self:isSelectingMode() then
        return
    end
    self.isSelectingMode_  = checkbool(isSelectingMode)
    self.isHidingCardList_ = not isSelectingMode
    self:getViewNode():goToChoosingMode(self:isSelectingMode(), needAnim)
end


function CardGroupMediator:isChangeNameMode()
    return checkbool(self.isChangeNameMode_)
end
function CardGroupMediator:setIsChangeNameMode(isChangeName)
    self.isChangeNameMode_ = checkbool(isChangeName)
end


-------------------------------------------------
-- public

function CardGroupMediator:close()
    if self.ctorArgs_.closeCB_ then
        self.ctorArgs_.closeCB_()
    end
    app:UnRegsitMediator(self:GetMediatorName())
end


-------------------------------------------------
-- private

function CardGroupMediator:initAllCardData_()
    self.allCardDataMap_         = {}
    self.cardIdListSortByCareer_ = {[CardUtils.CAREER_TYPE.BASE] = {}}
    local allCardsData           = clone(app.gameMgr:GetUserInfo().cards)
    for i, cardData in pairs(allCardsData) do
		if cardData.id then
			cardData.battlePoint = app.cardMgr.GetCardStaticBattlePointById(checkint(cardData.id))
		else
			cardData.battlePoint = 0
			cardData.favorabilityLevel = 0
		end
		cardData.id                = checkint(cardData.id)
		cardData.favorabilityLevel = checkint(cardData.favorabilityLevel)
		cardData.battlePoint       = checkint(cardData.battlePoint)
		cardData.level             = checkint(cardData.level)
		cardData.breakLevel        = checkint(cardData.breakLevel)
		cardData.cardId            = checkint(cardData.cardId)

        local cardConf     = CONF.CARD.CARD_INFO:GetValue(cardData.cardId)
        cardData.career    = checkint(cardConf.career)
        cardData.qualityId = checkint(cardConf.qualityId)

        local places    = app.gameMgr:GetCardPlace({id = cardData.id})
        local teamIndex = 99
        if places[tostring(CARDPLACE.PLACE_TEAM)] then
            local teamInfo = app.gameMgr:GetTeamInfo({id = cardData.id},true)
            if teamInfo then
                teamIndex = teamInfo.teamId or 1
            end
        end
        cardData.teamIndex = teamIndex

        self.allCardDataMap_[checkint(cardData.id)] = cardData
        table.insert(self.cardIdListSortByCareer_[CardUtils.CAREER_TYPE.BASE], cardData.id)
	end
end


function CardGroupMediator:getCardListDataByCareerId(careerId)
    local cardListId = self.cardIdListSortByCareer_[self:getSelectedScreenType()]
    if not cardListId then
        cardListId = {}
        for _, cardData in pairs(self.allCardDataMap_) do
            if checkint(cardData.career) == careerId then
                table.insert(cardListId, cardData.id)
            end
        end
    end
    self.cardIdListSortByCareer_[checkint(careerId)] = cardListId

    return cardListId
end


function CardGroupMediator:refreshCardListView_()
    self.displayCardList_ = self:getCardListDataByCareerId(self:getSelectedScreenType())

    local sortDefine     = SORT_DEFINE[self:getSelectedSortType()]
    local sortTagDefines = sortDefine.sort
    local ignoreLowUp    = sortDefine.ignoreLowUp

    local isSortUp = ignoreLowUp and true or self:getIsSortUp()
    if self:getSelectedSortType() == SORT_TYPE_TAG.FROMATION then
        isSortUp = false
    end
	table.sort(self.displayCardList_, function(cardIdA, cardIdB)
        local cardDataA  = self.allCardDataMap_[checkint(cardIdA)]
        local cardDataB  = self.allCardDataMap_[checkint(cardIdB)]
        local sortResult = false
        for sortIndex, sortTag in ipairs(sortTagDefines) do
            if cardDataA[sortTag] ~= cardDataB[sortTag] then
                sortResult = cardDataA[sortTag] > cardDataB[sortTag]
                if (sortIndex == 1 and not isSortUp) or sortTag == "cardId" then
                    sortResult = not sortResult
                end
                break
            end
        end
        return sortResult
	end)

    self:getViewData().cardGridView:resetCellCount(#self.displayCardList_)
end


function CardGroupMediator:refreshGroupView_()
    self:getViewData().groupGridView:resetCellCount(#self:getGroupData().playerCardIds + 1)
    self:refreshCardListView_()
end


function CardGroupMediator:removeGroupCardId(playerCardId)
    for index, cardId in pairs(self:getGroupData().playerCardIds) do
        if checkint(cardId) == checkint(playerCardId) then
            table.remove(self:getGroupData().playerCardIds, index)
            break
        end
    end
    self.groupCardIdMap_[checkint(playerCardId)] = false
    self:updateCardStateByCardId(playerCardId, false)
end


function CardGroupMediator:addGroupCardId(playerCardId)
    table.insert(self:getGroupData().playerCardIds, 1, playerCardId)
    self.groupCardIdMap_[checkint(playerCardId)] = true
    self:updateCardStateByCardId(playerCardId, true)
end


function CardGroupMediator:updateCardStateByCardId(playerCardId, visible)
    for _, cellViewData in pairs(self:getViewData().cardGridView:getCellViewDataDict()) do
        if cellViewData.view:getTag() == checkint(playerCardId) then
            cellViewData.cardNode:setChecked(visible)
            break
        end
    end
    self:getViewData().groupGridView:resetCellCount(#self:getGroupData().playerCardIds + 1)
end


-------------------------------------------------
-- handler

function CardGroupMediator:onClickBackButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end

    self:close()
end


function CardGroupMediator:onClickleftBtnHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local preGroupId = self:getSelectedGroupId() - 1
    if preGroupId <= 0 then
        preGroupId = CardUtils.PARAMETER_FUNC.MAX_GROUP_NUM()
    end
    self:setSelectedGroupId(preGroupId)
end


function CardGroupMediator:onClickRightBtnHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local nextGroupId = self:getSelectedGroupId() + 1
    if nextGroupId > CardUtils.PARAMETER_FUNC.MAX_GROUP_NUM() then
        nextGroupId = 1
    end
    self:setSelectedGroupId(nextGroupId)
end


function CardGroupMediator:onClickChangeNameBthHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    app.uiMgr:AddChangeNamePopup({
        renameCB  = function(newName)
            self:setIsChangeNameMode(true)
            self:SendSignal(POST.SAVE_CARD_CUSTOM_GROUP.cmdName, {
                groupId       = self:getSelectedGroupId(),
                name          = newName,
                playerCardIds = table.concat(self:getGroupData().playerCardIds, ","),
            })
        end,
        title        = __("组名称"),
        preName      = self:getGroupData().name,
    })
end


function CardGroupMediator:onClickEmptyAddBthHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    self:setIsSelectingMode(true, true)
end


function CardGroupMediator:onClickSiftBthHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    self:getViewNode():updateScreenViewVisible(true)
end


function CardGroupMediator:onClickSortBtnHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    self:getViewNode():updateSortViewVisible(true)
end


function CardGroupMediator:onClickCleanAllBtnHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    if next(self:getGroupData().playerCardIds) ~= nil then
        self:getGroupData().playerCardIds = {}
        self.groupCardIdMap_ = {}

        self:getViewData().cardGridView:resetCellCount(#self.displayCardList_)
        self:getViewData().groupGridView:resetCellCount(1)
    end
end


function CardGroupMediator:onClickConirmBtnHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    if next(self:getGroupData().playerCardIds) == nil and next(app.gameMgr:getCustomGroupInfoByGroupId(self:getSelectedGroupId()).playerCardIds) == nil then
        self:setIsSelectingMode(false, true)
        -- self:getViewNode():updateEmptyViewVisible(true)
    else
        self:SendSignal(POST.SAVE_CARD_CUSTOM_GROUP.cmdName, {
            groupId = self:getSelectedGroupId(), 
            name = self:getGroupName(),
            playerCardIds = table.concat(self:getGroupData().playerCardIds, ",")
        })
    end
end


function CardGroupMediator:onClickSortCellHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    sender:setChecked(true)
    self:setSelectedSortType(sender:getTag())
    self:getViewNode():updateSortViewVisible(false)
end


function CardGroupMediator:onClickSiftCellHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    sender:setChecked(true)
    self:setSelectedScreenType(sender:getTag())
    self:getViewNode():updateScreenViewVisible(false)
end


function CardGroupMediator:onClickGroupCellNodeHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local playerCardId = checkint(sender:getTag())
    if playerCardId == 0 then
        if not self:isSelectingMode() then
            self:setIsSelectingMode(true, true)
        else
            self:setCardListVisible(true)
        end
    else
        if self:isSelectingMode() then
            self:removeGroupCardId(playerCardId)
        end
    end
end


function CardGroupMediator:onClickCardCellNodeHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local playerCardId = checkint(sender:getTag())
    if not self:isCardSelected(playerCardId) then
        self:addGroupCardId(playerCardId)
    end
end


function CardGroupMediator:onClickDownBtnHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    self:setCardListVisible(false)
end


function CardGroupMediator:onClickUpBtnHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    if not self:isSelectingMode() then
        self:setIsSelectingMode(true, true)
    else
        self:setCardListVisible(true)
    end
end


function CardGroupMediator:onUpdateGroupCellHandler_(cellIndex, cellViewData)
    cellViewData.addImg:setVisible(cellIndex == 1)
    cellViewData.cardNode:setVisible(cellIndex ~= 1)
    local cardId = checkint(self:getGroupData().playerCardIds[cellIndex - 1])
    cellViewData.view:setTag(cardId)
    if cellIndex ~= 1 then
        local cardId = checkint(self:getGroupData().playerCardIds[cellIndex - 1])
        local cardData = self.allCardDataMap_[cardId]
        cellViewData.cardNode:RefreshUI(cardData)
    end
end


function CardGroupMediator:onUpdateCardCellHandler_(cellIndex, cellViewData)
    local playerCardId = checkint(self.displayCardList_[cellIndex])
    local playerCardData = self.allCardDataMap_[playerCardId]
    local isSelected   = self:isCardSelected(playerCardId)
    cellViewData.view:setTag(playerCardId)
    cellViewData.cardNode:setChecked(isSelected)
    cellViewData.cardNode:RefreshUI(playerCardData)
end


return CardGroupMediator

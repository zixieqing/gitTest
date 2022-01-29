--[[
 * author : panmeng
 * descpt : 皮肤收集 - 主界面
]]
local SkinCollectionMainScene    = require('Game.views.collection.skinCollection.SkinCollectionMainScene')
local SkinCollectionMainMediator = class('SkinCollectionMainMediator', mvc.Mediator)

function SkinCollectionMainMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'SkinCollectionMainMediator', viewComponent)
    local initArgs = checktable(params)
    self.ctorArgs_ = initArgs.requestData or {}
    self.homeArgs_ = initArgs
    self.homeArgs_.requestData = nil
end

local DISPLAY_TYPE = SkinCollectionMainScene.DISPLAY_TYPE
local SKIN_STATE   = SkinCollectionMainScene.SKIN_STATE
local TYPE_NONE    = SkinCollectionMainScene.TYPE_NONE

local ACTION_ENUM = {
    RELOAD_SKIN_DATAS = 1,
}


-------------------------------------------------
-- life cycle
function SkinCollectionMainMediator:Initial(key)
    self.super.Initial(self, key)

    -- init vars
    self.isControllable_ = true
    self.displaySkinData = {}

    -- create view
    self.ownerScene_ = app.uiMgr:SwitchToTargetScene('Game.views.collection.skinCollection.SkinCollectionMainScene')
    self:SetViewComponent(self.ownerScene_)

    -- add listener
    ui.bindClick(self:getViewData().backBtn, handler(self, self.onClickBackButtonHandler_))
    -- ui.bindClick(self:getViewData().titleBtn, handler(self, self.onClickTitleButtonHandler_))
    self:getViewData().gridView:setCellUpdateHandler(handler(DISPLAY_TYPE.SKIN_HEAD, handler(self, self.updateCellHandler_)))
    self:getViewData().gridView:setCellInitHandler(function(cellViewData)
        ui.bindClick(cellViewData.cellNode, handler(self, self.onClickSkinBtnHandler_), false)
    end)
    self:getViewData().tableView:setCellUpdateHandler(handler(DISPLAY_TYPE.SKIN_HALF_BODY, handler(self, self.updateCellHandler_)))
    self:getViewData().tableView:setCellInitHandler(function(cellViewData)
        ui.bindClick(cellViewData.cellNode, handler(self, self.onClickSkinBtnHandler_), false)
    end)
    self:getViewData().commonEditView:registerScriptEditBoxHandler(handler(self, self.onEditBoxStateChangeHandler_))
    ui.bindClick(self:getViewData().searchBtn, handler(self, self.onClickSearchSkinBtnHandler_))
    ui.bindClick(self:getViewData().resetBtn, handler(self, self.onClickResetSearchTypeBtnHandler_))

    self:getViewData().typeBtn:setOnClickScriptHandler(handler(self, self.onClickSkinTypeBtnHandler_))
    self:getViewData().stateBtn:setOnClickScriptHandler(handler(self, self.onClickSkinStateBtnHandler_))
    ui.bindClick(self:getViewData().displayBtn, handler(self, self.onClickChangeSkinCellTypeBtnHandler_))
    ui.bindClick(self:getViewData().rewardBtn, handler(self, self.onClickCollectTaskBtnHandler_))

    -- update views
    self.isControllable_ = false
    self:getViewNode():showUI(function()
        self:initHomeData_(self.homeArgs_)
        self.isControllable_ = true
    end)
end


function SkinCollectionMainMediator:CleanupView()
end


function SkinCollectionMainMediator:OnRegist()
    app:DispatchObservers(HomeScene_ChangeCenterContainer, 'rightHide')
    app:DispatchObservers(HomeScene_ChangeCenterContainer, 'allhide')

    regPost(POST.CARD_SKIN_COLLECT_COMPLETED_TASK)
end


function SkinCollectionMainMediator:OnUnRegist()
    app:DispatchObservers(HomeScene_ChangeCenterContainer, 'rightShow')
    app:DispatchObservers(HomeScene_ChangeCenterContainer, 'hide')

    unregPost(POST.CARD_SKIN_COLLECT_COMPLETED_TASK)
end


function SkinCollectionMainMediator:InterestSignals()
    return {
        POST.CARD_SKIN_COLLECT_COMPLETED_TASK.sglName,
    }
end
function SkinCollectionMainMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()

    if name == POST.CARD_SKIN_COLLECT_COMPLETED_TASK.sglName then
        self:initHomeData_(data)
    end
end


-------------------------------------------------
-- get / set

function SkinCollectionMainMediator:getViewNode()
    return self.ownerScene_
end
function SkinCollectionMainMediator:getViewData()
    return self:getViewNode():getViewData()
end


-- @see DISPLAY_TYPE
function SkinCollectionMainMediator:getDisplayType()
    return self.displayType_
end
function SkinCollectionMainMediator:setDisplayType(displayType)
    self.displayType_ = displayType
    self:getViewNode():setDisplaySkinCellType(self:getDisplayType())

    if not self.isViewInitOverMap[self:getDisplayType()] and next(self.displaySkinData) ~= nil then
        if self:getDisplayType() == DISPLAY_TYPE.SKIN_HEAD then
            self:getViewData().gridView:resetCellCount(#self.displaySkinData)
        else
            self:getViewData().tableView:resetCellCount(#self.displaySkinData)
        end
        self.isViewInitOverMap[self:getDisplayType()] = true
    end
end


-- @see TYPE_NONE
-- @see CONF.CARD.SKIN_COLL_TYPE
function SkinCollectionMainMediator:getSelectedType()
    return self.selectedType_
end
function SkinCollectionMainMediator:setSelectedType(skinType)
    self.selectedType_ = checkint(skinType)
    self:getViewNode():updateTypeBtnTitle(self:getSelectedType())
    self:getViewNode():udpateSkinTypeCellSelectState(self:getSelectedType())
    self:updateSelectedSkinCondition_()
end


-- @see SKIN_STATE
function SkinCollectionMainMediator:getSelectedState()
    return self.selectedState_
end
function SkinCollectionMainMediator:setSelectedState(state)
    self.selectedState_ = checkint(state)
    self:getViewNode():updateStateBtnTitle(self:getSelectedState())
    self:getViewNode():udpateSkinStateCellSelectState(self:getSelectedState())
    self:updateSelectedSkinCondition_()
end


function SkinCollectionMainMediator:getSearchCardName()
    return self.searchCardName_
end
function SkinCollectionMainMediator:setSearchCardName(cardName)
    self.searchCardName_ = checkstr(cardName)
    self:getViewNode():setSeachNameBoxText(self:getSearchCardName())
    self:updateSelectedSkinCondition_()
end


function SkinCollectionMainMediator:getSkinDataBySkinId_(skinId)
    return checktable(self.allOnlineSkinMap[checkint(skinId)])
end


function SkinCollectionMainMediator:getSkinMapBySkinState_(skinState)
    if skinState == 0 then
        return checktable(self.allOnlineSkinMap)
    end
    return checktable(self.skinStatePartitionMap[skinState])
end


function SkinCollectionMainMediator:getSkinMapBySkinType_(skinType)
    if skinType == 0 then
        return checktable(self.allOnlineSkinMap)
    end
    return checktable(self.skinTypePartitionMap[skinType])
end


-------------------------------------------------
-- public

function SkinCollectionMainMediator:close()
    -- back to homeMdt
    AppFacade.GetInstance():BackHomeMediator({showHandbook = true})
end


-------------------------------------------------
-- private

function SkinCollectionMainMediator:initHomeData_(homeData)
    local skinTimeMap = checktable(homeData.cardSkins)

    self.isViewInitOverMap = {} --一上来未避免卡顿，分开加载tableView， gridView
    self:setDisplayType(DISPLAY_TYPE.SKIN_HALF_BODY)

    self.allOnlineSkinMap      = {} -- 所有上线的飨灵皮肤表
    self.skinTypePartitionMap  = {} -- 飨灵皮肤类型分割表
    self.skinStatePartitionMap = {} -- 飨灵皮肤状态分割表

    for skinId, skinCollInfo in pairs(app.cardMgr:getOpenedSkinIdsMap()) do
        local skinConf = checktable(CardUtils.GetCardSkinConfig(skinId))
        if checkint(skinConf.skinAtlas) == 1 then
            skinId = checkint(skinId)
            local skinType = CardUtils.GetSkinTypeBySkinId(skinId)

            -- append typeMap
            if not self.skinTypePartitionMap[skinType] then
                self.skinTypePartitionMap[skinType] = {}
            end
            self.skinTypePartitionMap[skinType][skinId] = true

            -- append stateMap
            local isHaveSkin = app.cardMgr.IsHaveCardSkin(skinId)
            local stateIndex = isHaveSkin and SKIN_STATE.OWNED or SKIN_STATE.NOT_OWNED
            if not self.skinStatePartitionMap[stateIndex] then
                self.skinStatePartitionMap[stateIndex] = {}
            end
            self.skinStatePartitionMap[stateIndex][skinId] = true

            -- find skin all need data
            local cardConf = checktable(CONF.CARD.CARD_INFO:GetValue(skinConf.cardId))
            local skinData = {
                skinId     = skinId,
                cardId     = checkint(skinConf.cardId),
                skinType   = skinType,
                isHaveSkin = isHaveSkin,
                cardName   = tostring(cardConf.name),
                skinName   = tostring(skinConf.name),
                getTime    = checkint(skinTimeMap[tostring(skinId)]),
                isNew      = app.badgeMgr:checkCardSkinIsNew(skinId),
            }
            self.allOnlineSkinMap[skinId] = skinData
        end
    end

    -- update collectionProgress
    self:getViewNode():updateProgress(table.nums(self.skinStatePartitionMap[SKIN_STATE.OWNED]), table.nums(self.allOnlineSkinMap))

    -- set default filter condition
    self:setSelectedType(TYPE_NONE)
    self:setSelectedState(SKIN_STATE.NONE)

    app.cardMgr:initCardSkinCollTaskData(homeData.rewardIds)
end


function SkinCollectionMainMediator:updateSelectedSkinCondition_()
    if not self:getViewNode():getActionByTag(ACTION_ENUM.RELOAD_SKIN_DATAS) then
        self:getViewNode():runAction(cc.CallFunc:create(function()
            local skinType  = self:getSelectedType()
            local skinState = self:getSelectedState()
            local cardName  = self:getSearchCardName()

            -- getAllData
            self.displaySkinData = self:getSkinDataByRequireMent_(skinType, skinState, cardName)

            -- reload views
            if not self.isViewInitOverMap[self:getDisplayType()] then
                if self:getDisplayType() == DISPLAY_TYPE.SKIN_HEAD then
                    self:getViewData().gridView:resetCellCount(#self.displaySkinData)
                else
                    self:getViewData().tableView:resetCellCount(#self.displaySkinData)
                end
                self.isViewInitOverMap[self:getDisplayType()] = true
            else
                self:getViewData().gridView:resetCellCount(#self.displaySkinData)
                self:getViewData().tableView:resetCellCount(#self.displaySkinData)
            end
            self:getViewNode():updateEmptySkinViewVisible(#self.displaySkinData <= 0)

        end)):setTag(ACTION_ENUM.RELOAD_SKIN_DATAS)
    end
end


function SkinCollectionMainMediator:getSkinDataByRequireMent_(skinType, skinState, cardName)
    local skinTypeMap  = self:getSkinMapBySkinType_(skinType)
    local skinStateMap = self:getSkinMapBySkinState_(skinState)

    -- If one of the conditions is not met
    if next(skinTypeMap) == nil or next(skinStateMap) == nil then
        return {}
    end


    -- filter result
    local resultTwoTabMetSkinDatas = {}
    if skinType == TYPE_NONE or skinState == SKIN_STATE.NONE then
        -- if one of the condition is all ,then not need to compare two table
        local sortDataMap = skinType == TYPE_NONE and skinStateMap or skinTypeMap
        for skinId, _ in pairs(sortDataMap) do
            table.insert(resultTwoTabMetSkinDatas, checkint(skinId))
        end
    else
        -- need to compare two table, find all met data
        for skinId, _ in pairs(skinTypeMap) do
            if skinStateMap[checkint(skinId)] then
                table.insert(resultTwoTabMetSkinDatas, checkint(skinId))
            end
        end
    end


    -- calculate searchCardName is useful
    local resultSkinDatas = {}
    if checkstr(cardName) == "" then
        resultSkinDatas = resultTwoTabMetSkinDatas
    else
        for _, skinId in ipairs(resultTwoTabMetSkinDatas) do
            local skinData = self:getSkinDataBySkinId_(skinId)
            if string.find(skinData.cardName, cardName) then
                table.insert(resultSkinDatas, skinId)
            end
        end
    end

    -- sortResultData
    self:sortCardSkinCollData(resultSkinDatas)

    return resultSkinDatas
end

function SkinCollectionMainMediator:sortCardSkinCollData(cardSkinCollData)
    table.sort(cardSkinCollData, function(skinIdA, skinIdB)
        local skinDataA = self:getSkinDataBySkinId_(skinIdA)
        local skinDataB = self:getSkinDataBySkinId_(skinIdB)
        if skinDataA.isNew ~= skinDataB.isNew then
            return skinDataA.isNew == true
        elseif skinDataA.isHaveSkin ~= skinDataB.isHaveSkin then
            return skinDataA.isHaveSkin == true
        else
            if skinDataA.isHaveSkin == true then
                return skinDataA.getTime > skinDataB.getTime
            else
                return skinIdA > skinIdB
            end
        end
    end)
end


-------------------------------------------------
-- handler

function SkinCollectionMainMediator:onClickBackButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end

    self:close()
end


function SkinCollectionMainMediator:onClickTitleButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    app.uiMgr:ShowIntroPopup({moduleId = MODULE_DATA.TTGAME_ALBUM})
end


function SkinCollectionMainMediator:onClickCollectTaskBtnHandler_()
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local collectTaskArgs = {taskData = self.homeArgs_.rewardIds, closeCb = function()
        self:getViewNode():updateSeachNameBoxEnabled(true)
    end}
    local collectTaskMdt  = require('Game.mediator.collection.skinCollection.SkinCollectionTaskMediator').new(collectTaskArgs)
    self:getViewNode():updateSeachNameBoxEnabled(false)
    app:RegistMediator(collectTaskMdt)
end


function SkinCollectionMainMediator:onEditBoxStateChangeHandler_(eventType, sender)
    if eventType == "return" then
        local text = string.trim(sender:getText())
        sender:setText(tostring(text))
    end
end


function SkinCollectionMainMediator:onClickSearchSkinBtnHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    self:setSelectedType(TYPE_NONE)
    self:setSelectedState(SKIN_STATE.NONE)
    self:setSearchCardName(self:getViewNode():getSeachNameBoxText())
end


function SkinCollectionMainMediator:onClickResetSearchTypeBtnHandler_()
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    self:setSelectedType(TYPE_NONE)
    self:setSelectedState(SKIN_STATE.NONE)
    self:setSearchCardName('')
end


----------------------- choose display type
function SkinCollectionMainMediator:onClickChangeSkinCellTypeBtnHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local showTag = 3 - self:getDisplayType()
    self:setDisplayType(showTag)
end


----------------------- choose skin type
function SkinCollectionMainMediator:onClickSkinTypeBtnHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    self:getViewNode():setSkinTypeViewVisible(true, {
        typeClickCB  = handler(self, self.onClickSubSkinTypeBtnHandler_), 
        closeClickCB = function()
            self:getViewNode():setSkinTypeViewVisible(false)
            sender:setChecked(false)
        end
    })
end


function SkinCollectionMainMediator:onClickSubSkinTypeBtnHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local typeId = checkint(sender:getTag())
    self:setSelectedType(typeId)
end


------------------------- choose skin state
function SkinCollectionMainMediator:onClickSkinStateBtnHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    self:getViewNode():setSkinStateViewVisible(true, {
        stateClickCB = handler(self, self.onClickSubSkinStateBtnHandler_), 
        closeClickCB = function()
            self:getViewNode():setSkinStateViewVisible(false)
            sender:setChecked(false)
        end
    })
end


function SkinCollectionMainMediator:onClickSubSkinStateBtnHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local stateIndex = checkint(sender:getTag())
    self:setSelectedState(stateIndex)
end


-------------------------- cell handler
function SkinCollectionMainMediator:updateCellHandler_(displayType, cellIndex, cellViewData)
    if not self.displaySkinData or next(self.displaySkinData) == nil then return end
    local skinId   = checkint(self.displaySkinData[checkint(cellIndex)])
    local skinData = self:getSkinDataBySkinId_(skinId)
    
    if displayType == DISPLAY_TYPE.SKIN_HEAD then
        self:getViewNode():updateSkinGridCell(cellIndex, cellViewData, skinData)
    else
        self:getViewNode():updateSkinTableCell(cellIndex, cellViewData, skinData)
    end
end


function SkinCollectionMainMediator:onClickSkinBtnHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local skinId   = checkint(sender:getTag())
    local skinData = self:getSkinDataBySkinId_(skinId)

    if checkbool(skinData.isHaveSkin) then
        local skinPopupArgs  = {skinId = skinData.skinId, getTime = skinData.getTime, skinType = skinData.skinType}
        local skinPopupLayer = require('Game.views.collection.skinCollection.SkinDisplayPopup').new(skinPopupArgs)
        app.uiMgr:GetCurrentScene():AddDialog(skinPopupLayer)

        if skinData.isNew then
            self:GetFacade():DispatchObservers(SGL.CARD_SKIN_NEW_GET, {skinId = skinId, statue = false})
            --skinData.isNew = false
        end

        -- self:sortCardSkinCollData(self.displaySkinData)
        -- if not self.isViewInitOverMap[3 - self:getDisplayType()] then
        --     if self:getDisplayType() == DISPLAY_TYPE.SKIN_HEAD then
        --         self:getViewData().gridView:resetCellCount(#self.displaySkinData)
        --     else
        --         self:getViewData().tableView:resetCellCount(#self.displaySkinData)
        --     end
        -- else
        --     self:getViewData().gridView:resetCellCount(#self.displaySkinData)
        --     self:getViewData().tableView:resetCellCount(#self.displaySkinData)
        -- end
    else
        app.uiMgr:AddDialog("common.GainPopup", {goodId = skinId})
    end
end


return SkinCollectionMainMediator

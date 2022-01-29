--[[
 * author : kaishiqi
 * descpt : 猫屋 - 主界面 中介者
]]
local CatHouseHomeMediator = class('CatHouseHomeMediator', mvc.Mediator)

function CatHouseHomeMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'CatHouseHomeMediator', viewComponent)
    local initArgs = checktable(params)
    self.ctorArgs_ = initArgs.requestData or {}
    self.homeArgs_ = initArgs
    self.homeArgs_.requestData = nil
end


-------------------------------------------------
-- life cycle
function CatHouseHomeMediator:Initial(key)
    self.super.Initial(self, key)

    -- init vars
    self.eventDataMap_   = {}
    self.isControllable_ = true

    -- create view
    self.ownerScene_ = app.uiMgr:SwitchToTargetScene('Game.views.catHouse.CatHouseHomeScene')
    self:SetViewComponent(self.ownerScene_)

    -- add listener
    ui.bindClick(self:getViewData().backBtn, handler(self, self.onClickBackButtonHandler_))
    ui.bindClick(self:getViewData().titleBtn, handler(self, self.onClickTitleButtonHandler_))
    ui.bindClick(self:getViewData().showBtn, handler(self, self.onClickShowButtonHandler_))
    ui.bindClick(self:getViewData().infoBtn, handler(self, self.onClickInfoButtonHandler_))
    ui.bindClick(self:getViewData().shopBtn, handler(self, self.onClickShopButtonHandler_))
    ui.bindClick(self:getViewData().collBtn, handler(self, self.onClickCollButtonHandler_))
    ui.bindClick(self:getViewData().catBtn, handler(self, self.onClickCatButtonHandler_))
    ui.bindClick(self:getViewData().decorBtn, handler(self, self.onClickDecorButtonHandler_))
    ui.bindClick(self:getViewData().eventBtn, handler(self, self.onClickEventButtonHandler_))
    ui.bindClick(self:getViewData().skinHeadLayer, handler(self, self.onClickSkinButtonHandler_))
    ui.bindClick(self:getViewData().skinHeadDetailBlock, handler(self, self.onClickSkinHeadDetailBlockBtnHandler_))
    ui.bindClick(self:getViewData().skinHeadBtn, handler(self, self.onClickSkinHeadBtnHandler_))
    ui.bindClick(self:getViewData().skinIdentityBtn, handler(self, self.onClickSkinIdentityBtnHandler_))
    ui.bindClick(self:getViewData().skinBubbleBtn, handler(self, self.onClickSkinBubbleHandler_))
    ui.bindClick(self:getViewData().rankBtn, handler(self, self.onClickRankButtonHandler_))
    ui.bindClick(self:getViewData().friendBtn, handler(self, self.onClickFirendButtonHandler_))
    ui.bindClick(self:getEventViewData().eventBlock, handler(self, self.onClickEventBlockLayerHandler_))

    self:getViewData().uiButton:setOnClickScriptHandler(handler(self, self.onClickUIButtonHandler_))

    self:getEventViewData().tableView:setCellUpdateHandler(handler(self, self.onEventCellUpdateHandler_))
    self:getEventViewData().tableView:setCellInitHandler(function(cellViewData)
        ui.bindClick(cellViewData.view, handler(self, self.onClickEventCellHandler_))
    end)

    for _, eventPageBtn in pairs(self:getEventViewData().eventTabGroup) do
        eventPageBtn:setOnClickScriptHandler(handler(self, self.onClickEventTypePageBtnHandler_))
    end

    self.avatarMdt_ = require('Game.mediator.catHouse.CatHouseAvatarMediator').new(nil, self:getViewData().avatarLayer)
    self.decorMdt_  = require('Game.mediator.catHouse.CatHouseDecorateMediator').new(nil, self:getViewData().decorLayer)
    self.friendMdt_ = require('Game.mediator.catHouse.CatHouseFriendMediator').new(nil, self:getViewData().friendLayer)
    app:RegistMediator(self.avatarMdt_)
    app:RegistMediator(self.decorMdt_)
    app:RegistMediator(self.friendMdt_)
end


function CatHouseHomeMediator:CleanupView()
    app:UnRegistMediator(self.decorMdt_:GetMediatorName())
    app:UnRegistMediator(self.avatarMdt_:GetMediatorName())
    app:UnRegistMediator(self.friendMdt_:GetMediatorName())
end


function CatHouseHomeMediator:OnRegist()
    app:DispatchObservers(HomeScene_ChangeCenterContainer, 'rightHide')
    app:DispatchObservers(HomeScene_ChangeCenterContainer, 'allhide')

    regPost(POST.HOUSE_HOME_ENTER)
    regPost(POST.HOUSE_HOME_QUITE)
    regPost(POST.HOUSE_CHANGE_HEAD)
    regPost(POST.HOUSE_CHANGE_BUBBLE)
    regPost(POST.HOUSE_CHANGE_IDENTITY)
    regPost(POST.HOUSE_CAT_HOME)
    regPost(POST.HOUSE_PLACE_CATS)
    regPost(POST.HOUSE_CAT_EQUIP_CAT)

    -- init data
    self:initHomeData_(self.homeArgs_)
    app.catHouseMgr:onHomeEnter()

    -- update views
    self.decorMdt_:setDisplayTypeId_(CatHouseUtils.ALL)
    self.friendMdt_:hideFriendList()
    self:getViewNode():initChatPanel()
    self:getViewNode():setDecortingStatue(false)
    
    self.isControllable_ = false
    self:getViewNode():showUI(function()
        self.isControllable_ = true
    end)
end


function CatHouseHomeMediator:OnUnRegist()
    app:DispatchObservers(HomeScene_ChangeCenterContainer, 'rightShow')
    app:DispatchObservers(HomeScene_ChangeCenterContainer, 'hide')

    unregPost(POST.HOUSE_HOME_ENTER)
    unregPost(POST.HOUSE_HOME_QUITE)
    unregPost(POST.HOUSE_CHANGE_HEAD)
    unregPost(POST.HOUSE_CHANGE_BUBBLE)
    unregPost(POST.HOUSE_CHANGE_IDENTITY)
    unregPost(POST.HOUSE_CAT_HOME)
    unregPost(POST.HOUSE_PLACE_CATS)
    unregPost(POST.HOUSE_CAT_EQUIP_CAT)
    
    app.catHouseMgr:onHomeLeave()
end


function CatHouseHomeMediator:InterestSignals()
    return {
        POST.HOUSE_HOME_ENTER.sglName,
        POST.HOUSE_HOME_QUITE.sglName,
        POST.HOUSE_CHANGE_HEAD.sglName,
        POST.HOUSE_CHANGE_BUBBLE.sglName,
        POST.HOUSE_CHANGE_IDENTITY.sglName,
        SGL.CAT_HOUSE_MEMBER_LEAVE,
        SGL.CAT_HOUSE_GET_FRIEND_AVATAR_DATA,
        SGL.CAT_HOUSE_ON_UPDATE_EVENT_DATA,
        SGL.CAT_HOUSE_INVITE_NOTICE,
        POST.HOUSE_CAT_HOME.sglName,
        POST.HOUSE_PLACE_CATS.sglName,
        SGL.CAT_MODEL_UPDATE_OUT_TIMESTAMP,
        POST.HOUSE_CAT_EQUIP_CAT.sglName,
    }
end
function CatHouseHomeMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()

    if name == POST.HOUSE_HOME_ENTER.sglName then
        self.isControllable_ = false
        self:getViewNode():closeSwitchDoor(function()
            self:initHomeData_(data)
            self:getViewNode():openSwitchDoor(function()
                self.isControllable_ = true
            end)
        end)
        

    elseif name == POST.HOUSE_HOME_QUITE.sglName then
        app.catHouseMgr:setHouseOwnerId(0)
        self:close()
        

    elseif name == POST.HOUSE_CHANGE_HEAD.sglName then
        self:setDefaultHeadId(data.requestData.cardSkinId)


    elseif name == POST.HOUSE_CHANGE_BUBBLE.sglName then
        self:setDefaultBubbleId(data.requestData.goodsId)


    elseif name == POST.HOUSE_CHANGE_IDENTITY.sglName then
        self:setDefaultIdentityId(data.requestData.goodsId)


    elseif name == SGL.CAT_HOUSE_MEMBER_LEAVE then
        if app.gameMgr:IsPlayerSelf(data.memberId) then
            if not app.gameMgr:IsPlayerSelf(app.catHouseMgr:getHouseOwnerId()) then
                app.uiMgr:ShowInformationTips(__('你已被踢出好友御屋'))
                self:SendSignal(POST.HOUSE_HOME_ENTER.cmdName)
            end
        else
            self.avatarMdt_:removeMemberCell(CatHouseUtils.MEMBER_TYPE.ROLE, data.memberId)
        end


    elseif name == SGL.CAT_HOUSE_GET_FRIEND_AVATAR_DATA then
        self.isControllable_ = false
        self:getViewNode():closeSwitchDoor(function()
            self:initAvatarHomeData_(app.catHouseMgr:getVisitFriendHouseData())
            self:getViewNode():openSwitchDoor(function()
                self.isControllable_ = true
            end)
        end)


    elseif name == SGL.CAT_HOUSE_ON_UPDATE_EVENT_DATA then
        local updateEventType = checkint(data.eventType)
        -- clean data cache
        self.eventDataMap_[updateEventType] = nil
        -- check update view
        if self:getSelectedEventType() == updateEventType then
            self:updateEventListView_()
        end
        -- update event red
        self:upateEventRedStatue_()


    elseif name == SGL.CAT_HOUSE_INVITE_NOTICE then
        app.catHouseMgr:addEventData(data)
        if self:getViewNode():isEventViewVisible() then
            self:getViewNode():updateEventView(app.catHouseMgr:getEventCount())
        end


    elseif name == POST.HOUSE_CAT_HOME.sglName then
        app.catHouseMgr:setCatHomeData(data)


    elseif name == POST.HOUSE_PLACE_CATS.sglName then
        local oldPlaceCatIdList = app.catHouseMgr:getPlaceCatIdList()
        local newPlaceCatIdList = table.split(data.requestData.cats, ',')
        app.catHouseMgr:setPlaceCatIdList(newPlaceCatIdList)
        self:updateHousePlaceCats_(app.catHouseMgr:getPlaceCatIdList(), oldPlaceCatIdList)


    elseif name == SGL.CAT_MODEL_UPDATE_OUT_TIMESTAMP then
        if app.catHouseMgr:isPlaceCatInHouse(data.catUuid) then
            if data.catModel:isPlaceableToShow() then
                self:updateHousePlaceCats_({data.catUuid})
            else
                self:updateHousePlaceCats_(nil, {data.catUuid})
            end
        end
    elseif name == POST.HOUSE_CAT_EQUIP_CAT.sglName then    
        if checkint(data.requestData.playerCatId) == 0 then
            app.gameMgr:GetUserInfo().equippedHouseCat = {}
            app.gameMgr:GetUserInfo().equippedHouseCatTimeStamp = 0
        else
            local catUuid = CatHouseUtils.BuildCatUuid(app.gameMgr:GetPlayerId(), data.requestData.playerCatId)
            app.catHouseMgr:equipCat(catUuid)
        end
    end
end


-------------------------------------------------
-- get / set

function CatHouseHomeMediator:getViewNode()
    return self.ownerScene_
end
function CatHouseHomeMediator:getViewData()
    return self:getViewNode():getViewData()
end
function CatHouseHomeMediator:getEventViewData()
    return self:getViewNode():getEventViewData()
end


-- default headId
function CatHouseHomeMediator:isHideUI()
    return checkbool(self.isHideUI_)
end
function CatHouseHomeMediator:setUIVisible(visible)
    self.isHideUI_ = not checkbool(visible)
    self:getViewNode():updateUIVisible(not self:isHideUI())
end


-- default headId
function CatHouseHomeMediator:getDefaultHeadId()
    return app.catHouseMgr:getPlayerHouseHeadId()
end
function CatHouseHomeMediator:setDefaultHeadId(headId)
    app.catHouseMgr:setPlayerHouseHeadId(headId)
    self:getViewNode():setDisplayHeadId(headId)

    app:DispatchObservers(SGL.CAT_HOUSE_MEMBER_HEAD, {memberId = app.gameMgr:GetPlayerId(), head = self:getDefaultHeadId()})
end


-- default identityId
function CatHouseHomeMediator:getDefaultIdentityId()
    return app.catHouseMgr:getPlayerHouseIdentityId()
end
function CatHouseHomeMediator:setDefaultIdentityId(identityId)
    app.catHouseMgr:setPlayerHouseIdentityId(identityId)

    app:DispatchObservers(SGL.CAT_HOUSE_MEMBER_IDENTITY, {memberId = app.gameMgr:GetPlayerId(), businessCard = self:getDefaultIdentityId()})
end


-- default bubbleId
function CatHouseHomeMediator:getDefaultBubbleId()
    return app.catHouseMgr:getPlayerHouseBubbleId()
end
function CatHouseHomeMediator:setDefaultBubbleId(bubbleId)
    app.catHouseMgr:setPlayerHouseBubbleId(bubbleId)

    app:DispatchObservers(SGL.CAT_HOUSE_MEMBER_BUBBLE, {memberId = app.gameMgr:GetPlayerId(), bubble = self:getDefaultBubbleId()})
end


-- selected eventType
-- @see CatHouseUtils.HOUSE_EVENT_TYPE
function CatHouseHomeMediator:getSelectedEventType()
    return checkint(self.selectedEventType_)
end
function CatHouseHomeMediator:setSelectedEventType(eventType)
    local oldEventType = self:getSelectedEventType()
    local newEventType = checkint(eventType)
    if oldEventType == newEventType then
        return
    end

    -- unchecked oldEventTab
    if oldEventType > 0 then
        self:getEventViewData().eventTabGroup[oldEventType]:setChecked(false)
    end
    
    -- checked newEventTab
    self:getEventViewData().eventTabGroup[newEventType]:setChecked(true)
    
    -- update data && view
    self.selectedEventType_ = newEventType
    self:updateEventListView_()
end


-- @see CatHouseUtils.HOUSE_EVENT_TYPE
function CatHouseHomeMediator:getDisplayEventDatasByEventType(eventType)
    local eventDatas = {}
    if self.eventDataMap_[eventType] then
        eventDatas = self.eventDataMap_[eventType]
    else
        -- update data cache
        if eventType == CatHouseUtils.HOUSE_EVENT_TYPE.INVITE then
            eventDatas = app.catHouseMgr:getEventList()
        elseif eventType == CatHouseUtils.HOUSE_EVENT_TYPE.BREED then
            eventDatas = app.catHouseMgr:getValidBreedIdList()
        end
        self.eventDataMap_[eventType] = eventDatas
    end
    return eventDatas
end


-------------------------------------------------
-- public

function CatHouseHomeMediator:close()
    app:UnRegsitMediator(self:GetMediatorName())

    -- back to homeMdt
    local backMdtName = self.ctorArgs_.backMediatorName or 'HomelandMediator'
    app.router:Dispatch({name = 'catHouse.CatHouseHomeMediator'}, {name = backMdtName})
end


-------------------------------------------------
-- private

function CatHouseHomeMediator:initHomeData_(homeData)
    -- update manager data
    app.catHouseMgr:setHomeData(homeData)
    app.catHouseMgr:setHouseOwnerId(app.gameMgr:GetPlayerId())

    -- init catsData
    if app.catHouseMgr:isInitedCatModule() then
        self:SendSignal(POST.HOUSE_CAT_HOME.cmdName)
    end

    -- update views
    self:setDefaultBubbleId(homeData.bubble)
    self:setDefaultHeadId(homeData.head)
    self:setDefaultIdentityId(homeData.businessCard)
    self:initAvatarHomeData_(homeData)
    self:upateEventRedStatue_()
    self.decorMdt_:reloadAvatarsSuit()
end


function CatHouseHomeMediator:initAvatarHomeData_(homeData)
    self:getViewNode():setSceneDisplayType(app.catHouseMgr:getHouseOwnerId())
    self.avatarMdt_:initAvatarMemberView(homeData)
    self.avatarMdt_:initTriggerEventView(homeData.catTriggerEvent)
    self.avatarMdt_:initHomeData(homeData.location)
    app.socketMgr:SendPacket(NetCmd.HOUSE_MEMBER_LIST, {ownerId = app.catHouseMgr:getHouseOwnerId()})
end


function CatHouseHomeMediator:upateEventRedStatue_()
    local isHasRed = false
    for _, eventType in pairs(CatHouseUtils.HOUSE_EVENT_TYPE) do
        if #self:getDisplayEventDatasByEventType(eventType) > 0 then
            isHasRed = true
            break
        end
    end
    self:getViewNode():updateEventRedVisible(isHasRed)
end


function CatHouseHomeMediator:updateEventListView_()
    local currentEventDatas = self:getDisplayEventDatasByEventType(self:getSelectedEventType())
    self:getViewNode():updateEventView(#currentEventDatas)
end


function CatHouseHomeMediator:updateHousePlaceCats_(newPlaceCatList, oldPlaceCatList)
    local holdPlaceCatUuidMap = {}
    for _, catUuid in ipairs(newPlaceCatList or {}) do
        local catModel = app.catHouseMgr:getCatModel(catUuid)
        if self.avatarMdt_:hasMemberCell(CatHouseUtils.MEMBER_TYPE.CAT, catUuid) then
            holdPlaceCatUuidMap[catUuid] = true
        else
            if catModel and catModel:isPlaceableToShow() then
                self.avatarMdt_:appendMemberCell(CatHouseUtils.MEMBER_TYPE.CAT, {memberId = catUuid})
                holdPlaceCatUuidMap[catUuid] = true
            end
        end
    end
    for _, catUuid in ipairs(oldPlaceCatList or {}) do
        if not holdPlaceCatUuidMap[catUuid] then
            self.avatarMdt_:removeMemberCell(CatHouseUtils.MEMBER_TYPE.CAT, catUuid)
        end
    end
end


-------------------------------------------------
-- handler

function CatHouseHomeMediator:onClickBackButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end

    if self:getViewNode():isEventViewVisible() then
        self:getViewNode():setEventViewVisible(false)
    end

    if app.catHouseMgr:isDecoratingMode() then
        if self.decorMdt_:isPresetViewVisible() then
            self.decorMdt_:updatePresetViewVisible(false)
            self.avatarMdt_:onClosePresetModeCallBack()
        else
            self.avatarMdt_:onCloseDecoratingModeCallback()
            self:GetViewComponent():setDecortingStatue(false)
        end

    elseif app.gameMgr:IsPlayerSelf(app.catHouseMgr:getHouseOwnerId()) then
        self:SendSignal(POST.HOUSE_HOME_QUITE.cmdName)
    else
        -- back to myHouse
        self:SendSignal(POST.HOUSE_HOME_ENTER.cmdName)
    end
end


function CatHouseHomeMediator:onClickTitleButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    app.uiMgr:ShowIntroPopup({moduleId = MODULE_DATA[tostring(RemindTag.CAT_HOUSE)]})
end


function CatHouseHomeMediator:onClickShowButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    if table.nums(app.catHouseMgr:getCatsModelMap()) <= 0 then
        app.uiMgr:ShowInformationTips(__("您当前暂无猫咪"))
        return
    end

    local chooseCatPopup = require('Game.views.catModule.CatModuleChooseCatPopup').new({
        selectedCatIdList = app.catHouseMgr:getPlaceCatIdList(),
        choosePopupType   = CatHouseUtils.CAT_CHOOSE_POPUP_TYPE.HOUSE_PLACE,
        multipChooseMax   = CatHouseUtils.HOUSE_PARAM_FUNCS.PLACE_CAT_MAX(),
        multipChooseMix   = 0,
        confirmCB         = function(catUuIdList)
            local playerIdArray = {}
            for _, catUuid in pairs(catUuIdList) do
                table.insert(playerIdArray, string.split(catUuid, "_")[2])
            end
            self:SendSignal(POST.HOUSE_PLACE_CATS.cmdName, {cats = table.concat(playerIdArray, ',')})
        end,
        equipConfirmCB   = function(catUuid)
            local playerCatId = catUuid and string.split(catUuid, "_")[2] or 0
            self:SendSignal(POST.HOUSE_CAT_EQUIP_CAT.cmdName, {playerCatId = playerCatId})
        end,
    })
    app.uiMgr:GetCurrentScene():AddDialog(chooseCatPopup)
end


function CatHouseHomeMediator:onClickInfoButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local houseData = app.gameMgr:IsPlayerSelf(app.catHouseMgr:getHouseOwnerId()) and app.catHouseMgr:getHomeData() or app.catHouseMgr:getVisitFriendHouseData()
    local infoMdt   = require('Game.mediator.catHouse.CatHouseInfoMediator').new({friendId = app.catHouseMgr:getHouseOwnerId() , houseData = houseData})
    app:RegistMediator(infoMdt)
end


function CatHouseHomeMediator:onClickShopButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local dressShopMdt = require('Game.mediator.catHouse.CatHouseDressShopMediator').new()
    app:RegistMediator(dressShopMdt)
end


function CatHouseHomeMediator:onClickCollButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local houseData = app.gameMgr:IsPlayerSelf(app.catHouseMgr:getHouseOwnerId()) and app.catHouseMgr:getHomeData() or app.catHouseMgr:getVisitFriendHouseData()
    local collMdt   = require('Game.mediator.catHouse.CatHouseCollMediator').new({friendId = app.catHouseMgr:getHouseOwnerId() , houseData = houseData})
    app:RegistMediator(collMdt)
end


function CatHouseHomeMediator:onClickCatButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local catMediator = nil
    if app.catHouseMgr:isInitedCatModule() then
        catMediator = require('Game.mediator.catModule.CatModuleMainMediator').new()
    else
        catMediator = require('Game.mediator.catModule.CatModuleChoiceMediator').new()
    end
    app:RegistMediator(catMediator)
end


function CatHouseHomeMediator:onClickDecorButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    self:GetViewComponent():setDecortingStatue(true)
end


function CatHouseHomeMediator:onClickEventButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    self:getViewNode():setEventViewVisible(true)
    self:setSelectedEventType(CatHouseUtils.HOUSE_EVENT_TYPE.INVITE) 
end


function CatHouseHomeMediator:onClickEventBlockLayerHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    self:getViewNode():setEventViewVisible(false)
end


function CatHouseHomeMediator:onClickEventTypePageBtnHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    sender:setChecked(true)
    self:setSelectedEventType(sender:getTag())
end


function CatHouseHomeMediator:onClickEventCellHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local cellIndex = checkint(sender:getTag())
    local eventType = self:getSelectedEventType()
    local eventData = self:getDisplayEventDatasByEventType(eventType)[cellIndex]
    if eventType == CatHouseUtils.HOUSE_EVENT_TYPE.BREED then
        eventData = app.catHouseMgr:getFriendBreedData(eventData)
    end

    local catHouseEventPopup = require('Game.views.catHouse.CatHouseEventPopupView').new({
        eventData       = eventData,
        eventType       = eventType,
        confirmCallback = function()
            if eventType == CatHouseUtils.HOUSE_EVENT_TYPE.INVITE then
                if app.catHouseMgr:checkCanGoToFriendHouse(eventData.refId) then
                    app.catHouseMgr:goToFriendHouse(eventData.refId)
                end
                self:getViewNode():setEventViewVisible(false)
            elseif eventType == CatHouseUtils.HOUSE_EVENT_TYPE.BREED then
                local breedData = {
                    state = CatHouseUtils.CAT_BREED_STATE.INVITED,
                    inviterData = eventData
                }
                local mediator = require("Game.mediator.catHouse.CatHouseBreedChoiceMediator").new({breedData = breedData})
                app:RegistMediator(mediator)
            else
                -- local rankMdt = require('Game.mediator.catHouse.CatHouseMatingEventMediator').new({beInvitedData = eventData})
                -- app:RegistMediator(rankMdt)
            end
        end, 
        ignoreCallback = function()
            if eventType == CatHouseUtils.HOUSE_EVENT_TYPE.INVITE then
                app.catHouseMgr:removeEventDataByEventId(eventData.eventId)
            elseif eventType == CatHouseUtils.HOUSE_EVENT_TYPE.BREED then
                app.catHouseMgr:replyCatMatingRequest(eventData.friendCatId)
            end
        end
    })
    app.uiMgr:GetCurrentScene():AddDialog(catHouseEventPopup)
end


function CatHouseHomeMediator:onEventCellUpdateHandler_(cellIndex, cellViewData)
    local eventConf = CONF.CAT_HOUSE.EVENT_TYPE:GetValue(self:getSelectedEventType())
    cellViewData.title:updateLabel({text = tostring(eventConf.name), reqW = 200})
    cellViewData.view:setTag(cellIndex)
end


function CatHouseHomeMediator:onClickSkinButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    self:getViewNode():updateHeadDetailViewVisible(true)
end


function CatHouseHomeMediator:onClickSkinHeadDetailBlockBtnHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    self:getViewNode():updateHeadDetailViewVisible(false)
end


function CatHouseHomeMediator:onClickSkinHeadBtnHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local selfHouseCardData    = app.gameMgr:GetCardDataByCardId(CardUtils.GetCardIdBySkinId(self:getDefaultHeadId())) or {}
    local chooseCardsHouseView = require('Game.views.ChooseCardsHouseView').new({
        type          = 2,
        isAutonClose  = true,
        cardHouseData = {
            [tostring(selfHouseCardData.id)] = true
        },
        callback = function(data)
            local skinId = checkint(data.skinId)
            if skinId ~= self:getDefaultHeadId() then
                self:SendSignal(POST.HOUSE_CHANGE_HEAD.cmdName, {cardSkinId = skinId})
            end
        end
    })
    chooseCardsHouseView:RefreshUI()
    chooseCardsHouseView:setPosition(display.center)
    app.uiMgr:GetCurrentScene():AddDialog(chooseCardsHouseView)
    self:getViewNode():updateHeadDetailViewVisible(false)
end


function CatHouseHomeMediator:onClickSkinIdentityBtnHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local chooseCardsHouseView = require('Game.views.catHouse.CatHouseChooseStyleView').new({
        disGoodsType   = CatHouseUtils.AVATAR_STYLE_TYPE.IDENTITY,
        selectedItemId = self:getDefaultIdentityId(),
        callback       = function(itemId)
            if not itemId or self:getDefaultIdentityId() == itemId then
                return
            end
            self:SendSignal(POST.HOUSE_CHANGE_IDENTITY.cmdName, {goodsId = itemId})
        end
    })
    app.uiMgr:GetCurrentScene():AddDialog(chooseCardsHouseView)
    self:getViewNode():updateHeadDetailViewVisible(false)
end


function CatHouseHomeMediator:onClickSkinBubbleHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local chooseCardsHouseView = require('Game.views.catHouse.CatHouseChooseStyleView').new({
        disGoodsType   = CatHouseUtils.AVATAR_STYLE_TYPE.BUBBLE,
        selectedItemId = self:getDefaultBubbleId(),
        callback       = function(itemId)
            if not itemId or self:getDefaultBubbleId() == itemId then
                return
            end
            self:SendSignal(POST.HOUSE_CHANGE_BUBBLE.cmdName, {goodsId = itemId})
        end
    })
    app.uiMgr:GetCurrentScene():AddDialog(chooseCardsHouseView)
    self:getViewNode():updateHeadDetailViewVisible(false)
end


function CatHouseHomeMediator:onClickRankButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local rankMdt = require('Game.mediator.catHouse.CatHouseRankMediator').new()
    app:RegistMediator(rankMdt)
end


function CatHouseHomeMediator:onClickFirendButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    self.friendMdt_:showFriendList()
end


function CatHouseHomeMediator:onClickUIButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    self:setUIVisible(self:isHideUI())
end


return CatHouseHomeMediator

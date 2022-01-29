--[[
 * author : kaishiqi
 * descpt : 好友餐厅中介者
]]
local FriendAvatarView     = require('Game.views.FriendAvatarView')
local FriendAvatarMediator = class('FriendAvatarMediator', mvc.Mediator)

function FriendAvatarMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'FriendAvatarMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end


-------------------------------------------------
-- inheritance method

function FriendAvatarMediator:Initial(key)
    self.super.Initial(self, key)

    local ctorArgs       = checktable(self.ctorArgs_)
    local uiManager      = AppFacade.GetInstance():GetManager('UIManager')
    self.avatarMdt_      = self:GetFacade():RetrieveMediator('AvatarMediator')
    self.currentScene_   = uiManager:GetCurrentScene()
    self.initFriendId_   = checkint(ctorArgs.friendId)
    self.isControllable_ = true

    if not self.avatarMdt_ then
        require('Game.mediator.AvatarMediator')
    end

    -- create view
    self.friendAvatarView_ = FriendAvatarView.new()
    if not self.avatarMdt_ then
        self.currentScene_:AddDialog(self.friendAvatarView_)
    else
        self.currentScene_:AddGameLayer(self.friendAvatarView_)
    end

    self.switchDoorView_ = self.friendAvatarView_.CreateDoorView()
    self.currentScene_:AddDialog(self.switchDoorView_.view)
    self.switchDoorView_.view:setVisible(false)

    -- init view
    local friendViewData = self.friendAvatarView_:getViewData()
    display.commonUIParams(friendViewData.backBtn, {cb = handler(self, self.onClickBackButtonHandler_)})
    friendViewData.moneysBar:setVisible(false)

    friendViewData.friendHeaderNode:setClickCallback(handler(self, self.onClickFriendHeaderHandler_))
    
    -- update view
    self:updateFriendInfo()
end


function FriendAvatarMediator:CleanupView()
    if self.currentScene_ then
        if not self.avatarMdt_ then
            self.currentScene_:RemoveDialog(self.friendAvatarView_)
        else
            self.currentScene_:RemoveGameLayer(self.friendAvatarView_)
        end
        self.currentScene_ = nil
    end
end


function FriendAvatarMediator:OnRegist()
    regPost(POST.RESTAURANT_VISIT_FRIEND)
    self:setCurrentFriendId(self.initFriendId_)
    self:GetFacade():DispatchObservers(AvatarScene_ChangeCenterContainer, "hide")
end
function FriendAvatarMediator:OnUnRegist()
    unregPost(POST.RESTAURANT_VISIT_FRIEND)
    self:GetFacade():DispatchObservers(AvatarScene_ChangeCenterContainer, "show")
end


function FriendAvatarMediator:InterestSignals()
    return {
        RESTAURANT_EVENTS.EVENT_CLICK_DESK,
        POST.RESTAURANT_VISIT_FRIEND.sglName,
        SIGNALNAMES.CACHE_MONEY_UPDATE_UI,
        SIGNALNAMES.SIGNALNAME_FRIEND_AVATAR_STATE,
    }
end
function FriendAvatarMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()
    
    if name == POST.RESTAURANT_VISIT_FRIEND.sglName then
        self:setFriendCacheData(self:getCurrentFriendId(), data)
        self:checkPreloadRes_(data)


    elseif name == SIGNALNAMES.SIGNALNAME_FRIEND_AVATAR_STATE then
        local friendId        = checkint(data.friendId)
        local commandId       = checkint(data.cmd)
        local commandData     = checktable(data.cmdData)
        local gameManager     = self:GetFacade():GetManager('GameManager')
        local friendCacheData = self:getFriendCacheData(friendId)
        
        if friendId ~= checkint(gameManager:GetUserInfo().playerId) and friendCacheData then

            -- 2024 好友帮忙清除了虫子
            if commandId == NetCmd.RequestRestaurantBugClear then
                -- 虫子区域ID, 为0表示全部清除
                local bugAreaId = checkint(commandData.bugId)                
                if bugAreaId > 0 then
                    for i = #checktable(friendCacheData.bug or {}), 1, -1 do
                        if checkint(friendCacheData.bug[i]) == bugAreaId then
                            -- clean data
                            table.remove(friendCacheData.bug, i)
                            -- clean view
                            if friendId == self:getCurrentFriendId() then
                                self.friendAvatarView_:removeBugAt(bugAreaId)
                            end
                            break
                        end
                    end
                else
                    -- clean data
                    friendCacheData.bug = {}
                    -- clean views
                    if friendId == self:getCurrentFriendId() then
                        self.friendAvatarView_:cleanBugs()
                    end
                end

            -- 2027 餐厅霸王餐战斗胜利
            elseif commandId == NetCmd.Request2027 then
                for seatKey, customerData in pairs(friendCacheData.seat or {}) do
                    if checkint(customerData.questEventId) > 0 then
                        -- clean data
                        for k,v in pairs(customerData) do
                            customerData[k] = nil
                        end
                        -- clean view
                        if friendId == self:getCurrentFriendId() then
                            local dragNode    = self.friendAvatarView_:getDragNode(seatKey)
                            local visitorNode = dragNode and dragNode:getChildByName(seatKey) or nil
                            if visitorNode then
                                visitorNode:runAction(cc.RemoveSelf:create())
                            end
                        end
                        break
                    end
                end
            end
            
        end


    elseif name == RESTAURANT_EVENTS.EVENT_CLICK_DESK then
        if not self.avatarMdt_ then
            local AvatarFeedMediator = require('Game.mediator.AvatarFeedMediator')
            local delegate = AvatarFeedMediator.new({id = data.avatarId, type = data.type, data = data, friendData = data.friendData})
            AppFacade.GetInstance():RegistMediator(delegate)
        end


    elseif name == SIGNALNAMES.CACHE_MONEY_UPDATE_UI then
        if not self.avatarMdt_ then
            self.friendAvatarView_:updateMoneyBar()
        end


    end
end


-------------------------------------------------
-- get / set

function FriendAvatarMediator:getCurrentFriendId()
    return checkint(self.currentFriendId_)
end
function FriendAvatarMediator:setCurrentFriendId(friendId)
    if self:getCurrentFriendId() ~= checkint(friendId) then
        self:closeSwitchDoor(function()
            self.currentFriendId_ = checkint(friendId)
            self:requestFriendAvatar_(self.currentFriendId_)
        end)
    end
end


function FriendAvatarMediator:getCurrentFriendData()
    return self.currentFriendData_
end
function FriendAvatarMediator:setCurrentFriendData(friendData)
    self.currentFriendData_ = friendData
    self:updateFriendData_(self.currentFriendData_)
end


function FriendAvatarMediator:getFriendCacheData(friendId)
    if self.avatarMdt_ and self.avatarMdt_.friendAvatarCacheMap and self.avatarMdt_.friendAvatarCacheMap[tostring(friendId)] then
        return self.avatarMdt_.friendAvatarCacheMap[tostring(friendId)]
    else
        return nil
    end
end
function FriendAvatarMediator:setFriendCacheData(friendId, friendData)
    if self.avatarMdt_ then
        self.avatarMdt_.friendAvatarCacheMap = self.avatarMdt_.friendAvatarCacheMap or {}
        self.avatarMdt_.friendAvatarCacheMap[tostring(friendId)] = friendData
    end
end
function FriendAvatarMediator:hasFriendCacheData(friendId)
    return self:getFriendCacheData(friendId) ~= nil
end


-------------------------------------------------
-- public method

function FriendAvatarMediator:close()
    local mdtName = self:GetMediatorName()
    if self:GetFacade():HasMediator(mdtName) then
        self:GetFacade():UnRegsitMediator(mdtName)
    end
end


function FriendAvatarMediator:openSwitchDoor(endCb)
    self.switchDoorView_.view:setVisible(true)
    self.switchDoorView_.doorL:setPositionX(display.cx)
    self.switchDoorView_.doorR:setPositionX(display.cx)

    local actionTime = 0.25
    self.switchDoorView_.view:stopAllActions()
    self.switchDoorView_.view:runAction(cc.Sequence:create({
        cc.Spawn:create({
            cc.TargetedAction:create(self.switchDoorView_.doorL, cc.MoveTo:create(actionTime, cc.p(0, display.cy))),
            cc.TargetedAction:create(self.switchDoorView_.doorR, cc.MoveTo:create(actionTime, cc.p(display.width, display.cy)))
        }),
        cc.DelayTime:create(0.2),
        cc.CallFunc:create(function()
            self.switchDoorView_.view:setVisible(false)
            if endCb then endCb() end
        end)
    }))
end
function FriendAvatarMediator:closeSwitchDoor(endCb)
    self.switchDoorView_.view:setVisible(true)
    self.switchDoorView_.doorL:setPositionX(0)
    self.switchDoorView_.doorR:setPositionX(display.width)
    PlayAudioClip(AUDIOS.UI.ui_restaurant_enter.id)

    local actionTime = 0.25
    self.switchDoorView_.view:stopAllActions()
    self.switchDoorView_.view:runAction(cc.Sequence:create({
        cc.Spawn:create({
            cc.TargetedAction:create(self.switchDoorView_.doorL, cc.MoveTo:create(actionTime, display.center)),
            cc.TargetedAction:create(self.switchDoorView_.doorR, cc.MoveTo:create(actionTime, display.center))
        }),
        cc.DelayTime:create(0.2),
        cc.CallFunc:create(function()
            if endCb then endCb() end
        end)
    }))
end


function FriendAvatarMediator:updateFriendInfo()
    local gameManager    = self:GetFacade():GetManager('GameManager')
    local gameUserInfo   = gameManager:GetUserInfo()
    local friendViewData = self.friendAvatarView_:getViewData()
    display.commonLabelParams(friendViewData.helpBugCountLable, {text = tostring(gameUserInfo.restaurantCleaningLeftTimes)})
    display.commonLabelParams(friendViewData.helpQuestCountLable, {text = tostring(gameUserInfo.restaurantEventHelpLeftTimes)})
end


function FriendAvatarMediator:removeBugAt(bugAreaId)
    local bugList = checktable(self:getCurrentFriendData()).bug or {}
    for i = #bugList, 1, -1 do
        if checkint(bugAreaId) == checkint(bugList[i]) then
            table.remove(bugList, i)
            break
        end
    end

    self.friendAvatarView_:removeBugAt(bugAreaId)
end


-------------------------------------------------
-- private method

function FriendAvatarMediator:requestFriendAvatar_(friendId)
    local isOfficialAvatar = checkint(friendId) == -1
    if self:hasFriendCacheData(friendId) then
        self:checkPreloadRes_(self:getFriendCacheData(friendId))
    else
        if isOfficialAvatar then
            local officialConfs = CommonUtils.GetConfigAllMess('show', 'restaurant') or {}
            self:ProcessSignal(mvc.Signal.new(POST.RESTAURANT_VISIT_FRIEND.sglName, officialConfs))
        else
            self:SendSignal(POST.RESTAURANT_VISIT_FRIEND.cmdName, {friendId = checkint(friendId)})
        end
    end

    local friendData     = nil
    local gameManager    = self:GetFacade():GetManager('GameManager')
    local friendViewData = self.friendAvatarView_:getViewData()
    if isOfficialAvatar then
        local officialConfs = CommonUtils.GetConfigAllMess('show', 'restaurant') or {}
        friendData = {
            avatar          = checkstr(officialConfs.avatar),
            name            = checkstr(officialConfs.name),
            level           = checkint(officialConfs.level),
            restaurantLevel = checkint(officialConfs.restaurantLevel),
            avatarFrame     = checkstr(officialConfs.avatarFrame),
        }
    else
        for _, friend in ipairs(gameManager:GetUserInfo().friendList or {}) do
            if checkint(friend.friendId) == checkint(friendId) then
                friendData = friend
                break
            end
        end
    end

    if friendData then
        friendViewData.friendHeaderNode.headerSprite:setWebURL(friendData.avatar)
        friendViewData.friendHeaderNode:SetPreImageTexture(CommonUtils.GetGoodsIconPathById(CommonUtils.GetAvatarFrame(friendData.avatarFrame)))
        local nameText = string.fmt(__('_name_的_level_级餐厅'), {_name_ = friendData.name, _level_ = friendData.restaurantLevel})
        display.commonLabelParams(friendViewData.friendRNameBar, {text = nameText, paddingW = 30, safeW = 160})
        friendViewData.friendRNameBar:setPositionX(friendViewData.friendRNameBar:getContentSize().width/2 + 80)
        display.commonLabelParams(friendViewData.friendLevelLable, {text = tostring(friendData.level)})
    else
        friendViewData.friendHeaderNode.headerSprite:setWebURL('')
        friendViewData.friendHeaderNode:SetPreImageTexture(CommonUtils.GetGoodsIconPathById(CommonUtils.GetAvatarFrame('')))
        display.commonLabelParams(friendViewData.friendRNameBar, {text = '', paddingW = 30, safeW = 160})
        display.commonLabelParams(friendViewData.friendLevelLable, {text = ''})
    end
end


function FriendAvatarMediator:updateFriendData_(friendData)
    self.friendAvatarView_:hideBlackBg()
    self.friendAvatarView_:cleanAvatars()
    self.friendAvatarView_:cleanWaiters()
    self.friendAvatarView_:cleanBugs()
    
    if friendData then
        self.friendAvatarView_:showBlackBg()
        self.friendAvatarView_:reloadAvatars(friendData.location)
        self.friendAvatarView_:reloadWaiters(friendData.waiter)
        self.friendAvatarView_:reloadCustomers(friendData.seat, friendData.location, self:getCurrentFriendId())
        if CommonUtils.GetModuleAvailable(MODULE_SWITCH.PERISH_BUG) then
            self.friendAvatarView_:reloadBugs(friendData.bug, self:getCurrentFriendId())
            if table.nums(friendData.bug or {}) > 0 then
                PlayAudioClip(AUDIOS.UI.ui_lubi_appear.id)
            end
        end
    end
end


function FriendAvatarMediator:checkPreloadRes_(friendData)
    local resDatas  = {}

    -- check avatar res
    local avatarMap = checktable(friendData.location)
    for _, avatarData in pairs(avatarMap or {}) do
        local avatarId     = checkint(avatarData.goodsId)
        local avatarConf   = CommonUtils.GetConfigNoParser('restaurant', 'avatar', avatarId) or {}
        local locationConf = CommonUtils.GetConfigNoParser('restaurant', 'avatarLocation', avatarId) or {}
        local animationConf = CommonUtils.GetConfigNoParser('restaurant', 'avatarAnimation', avatarId) or {}

        if next(animationConf) == nil then
            local avatarPath = AssetsUtils.GetRestaurantBigAvatarPath(avatarId)
            if app.gameResMgr:isExistent(avatarPath) then
                table.insert(resDatas, avatarPath)
            end
        else
            local spinePath = AssetsUtils.GetRestaurantAvatarSpinePath(avatarId)
            if not app.gameResMgr:verifySpine(spinePath) then
                table.insert(resDatas, _spn(spinePath))
            end
        end
        
        local avatarType = RestaurantUtils.GetAvatarSubType(avatarConf.mainType, avatarConf.subType)
        if avatarType >= RESTAURANT_AVATAR_TYPE.CHAIR_SIGNLE then
            -- chair
            if checkint(locationConf.hasAddition) == 1 then
                for i=1, checkint(locationConf.additionNum) do
                    local addAvatarPath = AssetsUtils.GetRestaurantBigAvatarPath(string.format('%s_%d', avatarId, i))
                    if app.gameResMgr:isExistent(addAvatarPath) then
                        table.insert(resDatas, addAvatarPath)
                    end
                end
            end
            -- plate
            if checkint(locationConf.canPut) == 1 then
                for i,v in ipairs(locationConf.putThings) do
                    local putAvatarPath = AssetsUtils.GetRestaurantBigAvatarPath(v.thingId)
                    if app.gameResMgr:isExistent(putAvatarPath) then
                        table.insert(resDatas, putAvatarPath)
                    end
                end
            end
        end
    end

	local finishCB = function()
		self:setCurrentFriendData(friendData)
        self:openSwitchDoor()
	end

	if DYNAMIC_LOAD_MODE then
		app.uiMgr:showDownloadResPopup({
			resDatas = resDatas,
			finishCB = finishCB,
		})
	else
		finishCB()
	end
end


-------------------------------------------------
-- handler method

function FriendAvatarMediator:onClickBackButtonHandler_(sender)
    PlayAudioByClickClose()
    
    if self.avatarMdt_ then
        self.avatarMdt_:uploadFriendVisitLog()

        local gameManager = self:GetFacade():GetManager('GameManager')
        gameManager:GetUserInfo().avatarFriendId_ = nil
    end

    local LobbyFriendMediator = self:GetFacade():RetrieveMediator('LobbyFriendMediator')
    if LobbyFriendMediator then
        LobbyFriendMediator:initFriendIndexState()
    end
    self:close()
end

function FriendAvatarMediator:onClickFriendHeaderHandler_()
    PlayAudioByClickNormal()
    local friendId = self:getCurrentFriendId()
    
    if friendId > 0 then
        -- local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
        -- uiMgr:AddDialog('common.PlayerHeadPopup', {playerId = friendId, type = HeadPopupType.RESTAURANT_FRIEND})
        local mediator = require("Game.mediator.PersonInformationMediator").new({playerId = friendId})
        AppFacade.GetInstance():RegistMediator(mediator)
    end
end


return FriendAvatarMediator

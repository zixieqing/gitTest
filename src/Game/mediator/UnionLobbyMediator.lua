--[[
 * author : kaishiqi
 * descpt : 工会大厅 中介者
]]
local labelparser        = require('Game.labelparser')
local SocketManager      = require('Frame.Manager.SocketManager')
local UnionConfigParser  = require('Game.Datas.Parser.UnionConfigParser')
local UnionRoomConfs     = CommonUtils.GetConfigAllMess(UnionConfigParser.TYPE.ROOM, 'union') or {}
local AnimationMediator  = require('Game.mediator.union.UnionPartyAnimationMediator')
local UnionLobbyMediator = class('UnionLobbyMediator', mvc.Mediator)

local CHAT_MESSAGE_MAX  = 60
local AVATAR_MOVE_SPEED = 5

function UnionLobbyMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'UnionLobbyMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
    
end


-------------------------------------------------
-- inheritance method

function UnionLobbyMediator:Initial(key)
    self.super.Initial(self, key)
    self:setUnionData(self.ctorArgs_)
    
    self.isControllable_  = true
    self.channelCellDict_ = {}
    self.avatarCellDict_  = {}
    self.spineLoadList_   = {}

    local gameManager  = self:GetFacade():GetManager('GameManager')
    self.selfPlayerId_ = gameManager:GetUserInfo().playerId
    
    local socketManager = self:GetFacade():GetManager('SocketManager')
    socketManager:setPingDelta(1)

    -- create view
    local uiManager  = self:GetFacade():GetManager('UIManager')
    self.lobbyScene_ = uiManager:SwitchToTargetScene('Game.views.UnionLobbyScene')
    self:SetViewComponent(self.lobbyScene_)

    -- init view
    local lobbyViewData        = self:getLobbyScene():getViewData()
    local lobbyUIViewData      = self:getLobbyScene():getUIViewData()
    local lobbyChannelViewData = self:getLobbyScene():getChannelViewData()
    display.commonUIParams(lobbyUIViewData.titleBtn, {cb = handler(self, self.onClickTitleButtonHandler_)})
    display.commonUIParams(lobbyUIViewData.backBtn, {cb = handler(self, self.onClickBackButtonHandler_), animate = false})
    display.commonUIParams(lobbyUIViewData.infoBtn, {cb = handler(self, self.onClickInfoButtonHandler_)})
    display.commonUIParams(lobbyUIViewData.taskBtn, {cb = handler(self, self.onClickTaskButtonHandler_)})
    display.commonUIParams(lobbyUIViewData.shopBtn, {cb = handler(self, self.onClickShopButtonHandler_)})
    display.commonUIParams(lobbyUIViewData.buildBtn, {cb = handler(self, self.onClickBuildButtonHandler_)})
    display.commonUIParams(lobbyUIViewData.battleBtn, {cb = handler(self, self.onClickBattleButtonHandler_)})
    display.commonUIParams(lobbyUIViewData.monsterBtn, {cb = handler(self, self.onClickMonsterButtonHandler_)})
    display.commonUIParams(lobbyUIViewData.activityBtn, {cb = handler(self, self.onClickActivityButtonHandler_)})
    display.commonUIParams(lobbyChannelViewData.blockBg, {cb = handler(self, self.onClickChannelBlockBgHandler_)})
    display.commonUIParams(lobbyUIViewData.channelBtn, {cb = handler(self, self.onClickChannelButtonHandler_), animate = false})
    display.commonUIParams(lobbyUIViewData.skinHeadLayer, {cb = handler(self, self.onClickSkinHeadLayerHandler_), animate = false})
    display.commonUIParams(lobbyViewData.avatarRangeLayer, {cb = handler(self, self.onClickAvatarRangeLayerHandler_), animate = false})
    display.commonUIParams(lobbyUIViewData.impeachmentTouchView, {cb = handler(self, self.onClickImpeachmentTouchViewHandler_), animate = false})
    display.commonUIParams(lobbyUIViewData.impeachmentTipsIcon, {cb = handler(self, self.onClickImpeachmentTipsIconHandler_), animate = false})
    lobbyChannelViewData.channelTableView:setDataSourceAdapterScriptHandler(handler(self, self.onChannelTableDataSourceHandler_))
    lobbyUIViewData.monsterBtn:setVisible(CommonUtils.GetModuleAvailable(MODULE_SWITCH.UNION_HUNT))

    self.touchEventListener_ = cc.EventListenerTouchOneByOne:create()
    self.touchEventListener_:registerScriptHandler(handler(self, self.onTouchBegan_), cc.Handler.EVENT_TOUCH_BEGAN)
    self.touchEventListener_:registerScriptHandler(handler(self, self.onTouchMoved_), cc.Handler.EVENT_TOUCH_MOVED)
    self.touchEventListener_:registerScriptHandler(handler(self, self.onTouchEnded_), cc.Handler.EVENT_TOUCH_ENDED)
    cc.Director:getInstance():getEventDispatcher():addEventListenerWithSceneGraphPriority(self.touchEventListener_, lobbyViewData.view)

    -- update view
    self:reloadCurrentRoom_()
    self:updateCurrentChannelInfo_()
    self:getLobbyScene():setTitleText(self:getUnionData().name)
    if self:getLobbyScene():getUIViewData().chatPanel then
        self:getLobbyScene():getUIViewData().chatPanel:delayInit()
    end
    self:startLobbyAvatarAutoMove_()
    self:startLobbyAvatarMove_()
    self:reloadSelfSkinHead_()
    self:updateUnionImpeachmentState_()

    -- check party in workflow
    if self:isPartyInWorkflow() then
        local unionPartyMdt = require('Game.mediator.UnionPartyMediator').new()
        self:GetFacade():RegistMediator(unionPartyMdt)
    else
        -- check continue function
        local initArgs   = checktable(self.initArgs)
        local isFromHunt = initArgs.isFromHunt
        if isFromHunt then
            local unionActivityMdt = require('Game.mediator.UnionActivityMediator').new({autoActivityId = 1, autoInitArgs = initArgs.huntData})
            self:GetFacade():RegistMediator(unionActivityMdt)
        end
    end

    -- check impeachment state
    self:checkImpeachmentState()
end

function UnionLobbyMediator:CleanupView()
    local socketManager = self:GetFacade():GetManager('SocketManager')
    socketManager:setPingDelta(SocketManager.DEFAULT_DELTA)
    
    self:GetFacade():UnRegsitMediator(self.partyPreAnimationMdt_)
    self:endedCheckAvatarSpineLoad_()
    self:stopLobbyAvatarAutoMove_()
    self:stopLobbyAvatarMove_()
end


function UnionLobbyMediator:OnRegist()
    app:DispatchObservers(HomeScene_ChangeCenterContainer, 'rightHide')
    app:DispatchObservers(HomeScene_ChangeCenterContainer, "allhide")
    
    regPost(POST.UNION_HOME)
    regPost(POST.UNION_QUIT_HOME)
    regPost(POST.UNION_SWITCH_ROOM)
    regPost(POST.UNION_CHANGEINFO)
    regPost(POST.UNION_CHANGE_AVATAR)
    regPost(POST.UNION_IMPEACHMENT)
end
function UnionLobbyMediator:OnUnRegist()
    app:DispatchObservers(HomeScene_ChangeCenterContainer, 'rightShow')
    app:DispatchObservers(HomeScene_ChangeCenterContainer, 'hide')

    unregPost(POST.UNION_HOME)
    unregPost(POST.UNION_QUIT_HOME)
    unregPost(POST.UNION_SWITCH_ROOM)
    unregPost(POST.UNION_CHANGEINFO)
    unregPost(POST.UNION_CHANGE_AVATAR)
    unregPost(POST.UNION_IMPEACHMENT)
end


function UnionLobbyMediator:InterestSignals()
    return {
        UNION_KICK_OUT_EVENT,
        POST.UNION_HOME.sglName,
        POST.UNION_QUIT_HOME.sglName,
        POST.UNION_SWITCH_ROOM.sglName,
        POST.UNION_CHANGEINFO.sglName,
        POST.UNION_CHANGE_AVATAR.sglName,
        POST.UNION_IMPEACHMENT.sglName,
        SGL.UNION_CURRENT_ROOM_MEMBER_ENTER,
		SGL.UNION_OTHER_ROOM_MEMBERS_CHANGE,
        SGL.UNION_CURRENT_ROOM_MEMBER_LEAVE,
        SGL.UNION_AVATAR_LOBBY_STATUS_CHANGE,
        SGL.UNION_LOBBY_AVATAR_MOVE_SEND,
        SGL.UNION_LOBBY_AVATAR_MOVE_TAKE,
        SGL.UNION_LOBBY_AVATAR_CHANGE,
        SGL.UNION_PARTY_PRE_OPENING,
        SGL.UNION_PARTY_STEP_CHANGE,
        SGL.Chat_GetMessage_Callback,
        SGL.UNION_IMPEACHMENT_TIMES_RESULT_UPDATE,
    }
end
function UnionLobbyMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()

    if name == UNION_KICK_OUT_EVENT then -- 收到通知把玩家强制踢到主界面
        self:backToHome()

    -- union home
    elseif name == POST.UNION_HOME.sglName then
        self:setUnionData(data)
        self:getLobbyScene():runAction(cc.Sequence:create(
            cc.DelayTime:create(0.1),
            cc.CallFunc:create(function()
                self:checkImpeachmentState()
            end)
        ))
        
    -- union change name
    elseif name == POST.UNION_CHANGEINFO.sglName then
        if checktable(data.requestData).name then
            local newUnionName = tostring(checktable(data.requestData).name)
            self:getLobbyScene():setTitleText(newUnionName)
        end


    -- union change avatar
    elseif name == POST.UNION_CHANGE_AVATAR.sglName then
        local requestData = checktable(data.requestData)
        self:updateRoomAvatarData_(self.selfPlayerId_, requestData.defaultCardId, requestData.defaultCardSkin)


    -- avatar change (7013)
    elseif name == SGL.UNION_LOBBY_AVATAR_CHANGE then
        self:updateRoomAvatarData_(data.memberId, data.defaultCardId, data.defaultCardSkin)


    -- quit union home
    elseif name == POST.UNION_QUIT_HOME.sglName then
        self:backToHome()


    -- switch lobby room
    elseif name == POST.UNION_SWITCH_ROOM.sglName then
        local newRoomId  = checkint(self.switchRoomId_)
        local oldRoomId  = self:getLobbyRoomId()
        local oldMembers = checkint(self:getUnionData().roomMemberNumber[tostring(oldRoomId)])
        self:getUnionData().roomId     = newRoomId
        self:getUnionData().roomMember = checktable(data.roomMember)
        self:getUnionData().roomMemberNumber[tostring(oldRoomId)] = oldMembers - 1
        self:getUnionData().roomMemberNumber[tostring(newRoomId)] = table.nums(self:getUnionData().roomMember)

        self:getLobbyScene():closeSwitchDoor(function()
            self:updateCurrentChannelInfo_()
            self:reloadChannelData_(true)
            self:reloadCurrentRoom_()

            self:getLobbyScene():openSwitchDoor()
        end)
    
    elseif name == POST.UNION_IMPEACHMENT.sglName or name == SGL.UNION_IMPEACHMENT_TIMES_RESULT_UPDATE then
        -- update impeachment times
        local unionData                       = self:getUnionData()
        local impeachmentData                 = unionData.impeachmentData or {}
        local impeachmentTimes                = data.impeachmentTimes
        local impeachmentTotalTimes           = data.impeachmentTotalTimes
        impeachmentData.impeachmentTimes      = impeachmentTimes
        impeachmentData.impeachmentTotalTimes = impeachmentTotalTimes

        -- update is impeachment
        local requestData                     = data.requestData or {}
        local isUnionImpeachment              = requestData.isUnionImpeachment
        if isUnionImpeachment then
            impeachmentData.isUnionImpeachment = isUnionImpeachment
        end
        unionData.impeachmentData             = impeachmentData

        -- impeachment success Re-request union home
        if impeachmentTimes and impeachmentTotalTimes then
            if checkint(impeachmentTimes) >= checkint(impeachmentTotalTimes) then
                self:SendSignal(POST.UNION_HOME.cmdName)
            else
                self:checkImpeachmentState()
            end
        end

    -- enter to other room (7003)
    elseif name == SGL.UNION_OTHER_ROOM_MEMBERS_CHANGE then
        local currentRoomId = self:getLobbyRoomId()
        local udpateRoomId = checkint(data.roomId)
        local updateMember = checkint(data.memberNum)
        self:getUnionData().roomMemberNumber[tostring(udpateRoomId)] = updateMember
        self:reloadChannelData_(true)

        if currentRoomId == udpateRoomId then
            logInfo.add(5, '!! 7003 to enter current room !!')
        end


    -- enter to current room (7002)
    elseif name == SGL.UNION_CURRENT_ROOM_MEMBER_ENTER then
        local enterRoomId    = checkint(data.roomId)
        local currentRoomId  = self:getLobbyRoomId()
        local isSamePosition = false

        if enterRoomId == currentRoomId then
            local roomMemberData = {
                position        = data.position,
                playerId        = data.memberId,
                playerName      = data.memberName,
                defaultCardId   = data.defaultCardId,
                defaultCardSkin = data.defaultCardSkin,
                isInUnionLobby  = data.isInUnionLobby,
            }

            -- check same position has member
            local roomMembers = table.nums(self:getUnionData().roomMember)
            for i = roomMembers, 1, -1 do
                local memberData = self:getUnionData().roomMember[i] or {}
                if checkint(memberData.position) == checkint(roomMemberData.position) then
                    table.remove(self:getUnionData().roomMember, i)
                    self:removeRoomMember_(memberData.playerId)
                    isSamePosition = true
                    break
                end
            end

            -- add room member data
            table.insert(self:getUnionData().roomMember, roomMemberData)
            self:updateCurrentChannelInfo_()
            
            -- add room member cell
            self:appendRoomMember_(roomMemberData)
            self:getLobbyScene():reorderAvatarLayer()
        else
            logInfo.add(5, '!! 7002 to other room enter !!')
        end

        -- update member count
        local roomMember = checkint(self:getUnionData().roomMemberNumber[tostring(enterRoomId)])
        self:getUnionData().roomMemberNumber[tostring(enterRoomId)] = roomMember + (isSamePosition and 0 or 1)
        self:reloadChannelData_(true)


    -- leave to current room (7007)
    elseif name == SGL.UNION_CURRENT_ROOM_MEMBER_LEAVE then
        local leaveRoomId   = checkint(data.roomId)
        local currentRoomId = self:getLobbyRoomId()
        local isExistMember = false
        if leaveRoomId == currentRoomId then
            -- remove room member
            local roomMembers = table.nums(self:getUnionData().roomMember)
            for i = roomMembers, 1, -1 do
                local memberData = self:getUnionData().roomMember[i] or {}
                if checkint(memberData.playerId) == checkint(data.memberId) then
                    table.remove(self:getUnionData().roomMember, i)
                    self:removeRoomMember_(memberData.playerId)
                    isExistMember = true
                    break
                end
            end
            self:updateCurrentChannelInfo_()
        else
            logInfo.add(5, '!! 7007 to other room leave !!')
        end

        -- update member count
        local roomMember = checkint(self:getUnionData().roomMemberNumber[tostring(leaveRoomId)])
        self:getUnionData().roomMemberNumber[tostring(leaveRoomId)] = roomMember - (isExistMember and 1 or 0)
        self:reloadChannelData_(true)


    -- lobby status change (7016)
    elseif name == SGL.UNION_AVATAR_LOBBY_STATUS_CHANGE then
        local roomId   = checkint(data.roomId)
        local memberId = checkint(data.memberId)
        for _, memberData in ipairs(self:getUnionData().roomMember or {}) do
            if checkint(memberData.playerId) == memberId then
                memberData.isInUnionLobby = data.isInUnionLobby
                break
            end
        end


    -- take chat message (5003)
    elseif name == SGL.Chat_GetMessage_Callback then
        local messageData    = checktable(data)
        local messageText    = checkstr(messageData.message)
        local messageType    = checkint(messageData.messagetype)
        local messageChannel = checkint(messageData.channel)

        if messageChannel == CHAT_CHANNELS.CHANNEL_UNION and messageType == CHAT_MSG_TYPE.TEXT then
            local parsedList   = {}
            local parsedResult = labelparser.parse(messageText)
            for _, result in ipairs(parsedResult) do
                if FILTERS[result.labelname] then
                    table.insert(parsedList, result)
                end
            end

            for _, v in ipairs(parsedList) do
                if v.labelname == FILTERS.desc then
                    local chatData = {
                        playerId = checkint(messageData.playerId),
                        message  = nativeSensitiveWords(v.content)
                    }
                    self:bubblingAvatarDialogueBubble_(chatData)
                    break
                end
            end
        end

    
    -- send avatar move send (7009)
    elseif name == SGL.UNION_LOBBY_AVATAR_MOVE_SEND then
        if self.sendMoveToPoint_ then
            self:runAvatarMoveToPoint_(self.selfPlayerId_, self.sendMoveToPoint_.x, self.sendMoveToPoint_.y)
            self.sendMoveToPoint_ = nil
        end
    -- take avatar move take (7010)
    elseif name == SGL.UNION_LOBBY_AVATAR_MOVE_TAKE then
        self:runAvatarMoveToPoint_(data.memberId, data.pointX, data.pointY)

    
    -- party pre-opening
    elseif name == SGL.UNION_PARTY_PRE_OPENING then
        if self:isEnableParty() then
            self:cleanUnionLobby_()

            -- pre-opening animation
            self.partyPreAnimationMdt_ = AnimationMediator.new({spinePath = 'effects/union/party/daojishi'})
            self:GetFacade():RegistMediator(self.partyPreAnimationMdt_)
            self.partyPreAnimationMdt_:playAnimation('play')
        end


    -- party step change
    elseif name == SGL.UNION_PARTY_STEP_CHANGE then
        if self:isEnableParty() then
            if data.stepId == UNION_PARTY_STEPS.OPENING then
                self:cleanUnionLobby_()
            end
            
            if self:isPartyInWorkflow() and self:GetFacade():RetrieveMediator('UnionPartyMediator') == nil then
                self:getLobbyScene():runAction(cc.Sequence:create(
                    cc.DelayTime:create(0.1),
                    cc.CallFunc:create(function()
                        local unionPartyMdt = require('Game.mediator.UnionPartyMediator').new()
                        self:GetFacade():RegistMediator(unionPartyMdt)
                    end)
                ))
            end
        end

        
    end
end


-------------------------------------------------
-- get / set

function UnionLobbyMediator:getLobbyScene()
    return self.lobbyScene_
end


function UnionLobbyMediator:getUnionData()
    local unionManager = self:GetFacade():GetManager('UnionManager')
    return unionManager:getUnionData() or {}
end
function UnionLobbyMediator:setUnionData(unionData)
    local unionManager = self:GetFacade():GetManager('UnionManager')
    unionManager:setUnionData(unionData or {})
end


function UnionLobbyMediator:getLobbyRoomId()
    return checkint(self:getUnionData().roomId)
end
function UnionLobbyMediator:setLobbyRoomId(roomId)
    self:getUnionData().roomId = checkint(roomId)
end


function UnionLobbyMediator:getSelfRoomMemberData()
    local selfRoomMemberData = nil
    for _, memberData in ipairs(self:getUnionData().roomMember or {}) do
        if checkint(memberData.playerId) == self.selfPlayerId_ then
            selfRoomMemberData = memberData
            break
        end
    end
    return selfRoomMemberData
end


function UnionLobbyMediator:isEnableParty()
    local unionManager = self:GetFacade():GetManager('UnionManager')
    return unionManager:getPartyLevel() > 0
end


function UnionLobbyMediator:isPartyInWorkflow()
    local unionManager = self:GetFacade():GetManager('UnionManager')
    return self:isEnableParty() and unionManager:isPartyInWorkflow()
end


-------------------------------------------------
-- public method

function UnionLobbyMediator:backToHome()
    SpineCache(SpineCacheName.UNION):clearCache()

    local routeMediator = self:GetFacade():RetrieveMediator('Router')
    routeMediator:Dispatch({name = self:GetMediatorName()}, {name = 'HomeMediator'})
end


function UnionLobbyMediator:reloadRoomBackground()
    if self:isPartyInWorkflow() then
        self:getLobbyScene():setBackgroundImg('guild_bg_party')
    else
        local currentRoomId = self:getLobbyRoomId() == 0 and 1 or self:getLobbyRoomId()
        local unionRoomConf = UnionRoomConfs[tostring(currentRoomId)] or {}
        self:getLobbyScene():setBackgroundImg(unionRoomConf.background)
    end
end

function UnionLobbyMediator:checkImpeachmentState()
    local unionData              = self:getUnionData()
    local impeachmentData        = unionData.impeachmentData or {}
    local impeachmentTimes       = impeachmentData.impeachmentTimes
    local impeachmentTotalTimes  = impeachmentData.impeachmentTotalTimes
    local unionPresidentPlayerId = impeachmentData.unionPresidentPlayerId
    local isNewImpeachment       = impeachmentData.isNewImpeachment
    local scene                  = self:getLobbyScene()

    local notIsPartyInWorkflow = not self:isPartyInWorkflow()
    if notIsPartyInWorkflow then
        if unionPresidentPlayerId then
            scene:showImpeachmentSuccessPopup(unionData)
            impeachmentData.unionPresidentPlayerId = nil
        elseif isNewImpeachment and checkint(isNewImpeachment) > 0 then
            impeachmentData.isNewImpeachment = nil

            local commonTip = require('common.NewCommonTip').new({
                extra = __('上一轮弹劾未通过'), isForced = true, isOnlyOK = true
            })
            display.commonLabelParams(commonTip.extra, {hAlign = display.TAC})
            commonTip:setPosition(display.center)
            app.uiMgr:GetCurrentScene():AddDialog(commonTip)
        end
    elseif isNewImpeachment and checkint(isNewImpeachment) > 0 then
        impeachmentData.isNewImpeachment = nil
        app.uiMgr:ShowInformationTips(__('上一轮弹劾未通过'))
    end

    if  next(impeachmentData) == nil then
        scene:hideImpeachmentView()

    elseif impeachmentTimes and impeachmentTotalTimes and checkint(impeachmentTimes) < checkint(impeachmentTotalTimes) then
        scene:updateImpeachmentTimes(impeachmentTimes, impeachmentTotalTimes)
    end

end

-------------------------------------------------
-- private method

function UnionLobbyMediator:updateCurrentChannelInfo_()
    local roomMemberList = self:getUnionData().roomMember or {}
    local currentNumber  = table.nums(roomMemberList)
    local currentRoomId  = self:getLobbyRoomId()
    local unionRoomConf  = UnionRoomConfs[tostring(currentRoomId)] or {}
    self:getLobbyScene():setCurrentChannelTitle(tostring(unionRoomConf.name), currentNumber)
end


function UnionLobbyMediator:reloadChannelData_(isLockOffset)
    local channelMapData = self:getUnionData().roomMemberNumber or {}
    self:getLobbyScene():reloadChannelTable(channelMapData, isLockOffset)
end


function UnionLobbyMediator:updateChannelCell_(index, channelCell)
    local cellRoomId     = checkint(index)
    local unionRoomConf  = UnionRoomConfs[tostring(cellRoomId)] or {}
    local channelTable   = self:getLobbyScene():getChannelViewData().channelTableView
    local channelCell    = channelCell or self.channelCellDict_[channelTable:cellAtIndex(index - 1)]
    local channelMapData = self:getUnionData().roomMemberNumber or {}
    local channelMembers = checkint(channelMapData[tostring(cellRoomId)])
    local isSelfRoomId   = checkint(self:getLobbyRoomId()) == checkint(cellRoomId)

    if channelCell and channelMapData then
        channelCell.selectBg:setVisible(isSelfRoomId)
        channelCell.normalBg:setVisible(not isSelfRoomId)
        display.commonLabelParams(channelCell.nameLabel , {text = unionRoomConf.name , reqW = 175})
        channelCell.numberLabel:setString(string.fmt('(%1/%2)', channelMembers, UNION_ROOM_MEMBERS))
    end
end


--------------------
-- about room member
--------------------

function UnionLobbyMediator:reloadCurrentRoom_()
    self:reloadRoomBackground()

    -- clean old room member
    self.avatarCellDict_ = {}
    self:getLobbyScene():cleanAvatarLayer()

    -- create room member
    for _, memberData in ipairs(self:getUnionData().roomMember) do
        self:appendRoomMember_(memberData)
    end

    -- reorder all member
    self:getLobbyScene():reorderAvatarLayer()
end
function UnionLobbyMediator:appendRoomMember_(roomMemberData)
    local memberData    = checktable(roomMemberData)
    local memberId      = checkint(memberData.playerId)
    local memberPosId   = checkint(memberData.position)
    local oldAvatarCell = self.avatarCellDict_[tostring(memberId)]
    if oldAvatarCell then
        self:getLobbyScene():removeAvatarCell(oldAvatarCell)
    end

    -- create avatar cell
    local avatarCell  = self:getLobbyScene():appendAvatarCell(memberPosId, roomMemberData.playerName)
    avatarCell.clickArea:setOnClickScriptHandler(handler(self, self.onClickAvatarCellHandler_))
    avatarCell.clickArea:setTag(memberId)
    self.avatarCellDict_[tostring(memberId)] = avatarCell

    -- load avatar spine
    self:reloadRoomAvatar_(memberId, checkint(roomMemberData.defaultCardId), checkint(roomMemberData.defaultCardSkin))
end
function UnionLobbyMediator:removeRoomMember_(memberId)
    local avatarCell = self.avatarCellDict_[tostring(memberId)]
    self:getLobbyScene():removeAvatarCell(avatarCell)
    self.avatarCellDict_[tostring(memberId)] = nil
end


----------------------
-- about avatar update
----------------------

function UnionLobbyMediator:reloadSelfSkinHead_()
    local selfRoomMemberData = self:getSelfRoomMemberData() or {}
    self:getLobbyScene():setSkinHeadIcon(selfRoomMemberData.defaultCardSkin)
end


function UnionLobbyMediator:reloadRoomAvatar_(playerId, cardId, cardSkinId)
    -- load avatar spine
    local spineLoadData = {
        playerId   = playerId,
        cardId     = cardId,
        cardSkinId = cardSkinId,
    }
    table.insert(self.spineLoadList_, spineLoadData)
    self:begainCheckAvatarSpineLoad_()
end


function UnionLobbyMediator:updateRoomAvatarData_(memberId, cardId, skinId)
    -- update room avatar data
    for _, memberData in ipairs(self:getUnionData().roomMember or {}) do
        if checkint(memberData.playerId) == checkint(memberId) then
            memberData.defaultCardId   = checkint(cardId)
            memberData.defaultCardSkin = checkint(skinId)
            break
        end
    end

    -- check is self
    if checkint(memberId) == self.selfPlayerId_ then
        self:reloadSelfSkinHead_()
    end

    -- update room avatar
    self:reloadRoomAvatar_(memberId, cardId, skinId)
end


function UnionLobbyMediator:begainCheckAvatarSpineLoad_()
    if self.checkAvatarSpineLoadHandler_ then return end
    self.checkAvatarSpineLoadHandler_ = scheduler.scheduleGlobal(function()
        if #self.spineLoadList_ > 0 then
            local cardManager    = self:GetFacade():GetManager('CardManager')
            local spineLoadData  = table.remove(self.spineLoadList_, 1)
            local loadCardId     = checkint(spineLoadData.cardId)
            local loadPlayerId   = checkint(spineLoadData.playerId)
            local loadCardSkinId = checkint(spineLoadData.cardSkinId)
            if loadCardSkinId <= 0 then
                loadCardSkinId = checkint(CardUtils.GetCardDefaultSkinIdByCardId(loadCardId))
            end

            -- create spine
            local avatarCell = self.avatarCellDict_[tostring(loadPlayerId)]
            local spineLayer = avatarCell and avatarCell.avatarLayer or nil
            if spineLayer then
                local cardSpine = AssetsUtils.GetCardSpineNode({skinId = loadCardSkinId, scale = 0.45, cacheName = SpineCacheName.UNION, spineName = loadCardSkinId})
                cardSpine:update(0)
                cardSpine:setAnimation(0, 'idle', true)
                spineLayer:addChild(cardSpine)

                -- check has old spine
                local oldCardSpine = avatarCell.cardSpine
                if oldCardSpine then
                    oldCardSpine:stopAllActions()
                    oldCardSpine:runAction(cc.Sequence:create(
                        cc.FadeOut:create(0.2),
                        cc.RemoveSelf:create()
                    ))

                    --avatar switch spine
                    local chestEffectPath  = 'ui/union/lobby/yan'
                    if not SpineCache(SpineCacheName.UNION):hasSpineCacheData(chestEffectPath) then
                        SpineCache(SpineCacheName.UNION):addCacheData(chestEffectPath, chestEffectPath, 0.5)
                    end
                    local chestEffectSpine = SpineCache(SpineCacheName.UNION):createWithName(chestEffectPath)
                    spineLayer:addChild(chestEffectSpine)
                    
                    chestEffectSpine:setToSetupPose()
                    chestEffectSpine:setAnimation(0, 'go', false)

                    PlayAudioClip(AUDIOS.UI.ui_union_change.id)
                end

                cardSpine:setOpacity(0)
                cardSpine:runAction(cc.FadeIn:create(0.2))
                
                avatarCell.cardSpine = cardSpine
            end
        else
            self:endedCheckAvatarSpineLoad_()
        end
    end, 0.25)
end
function UnionLobbyMediator:endedCheckAvatarSpineLoad_()
    if self.checkAvatarSpineLoadHandler_ then
        scheduler.unscheduleGlobal(self.checkAvatarSpineLoadHandler_)
        self.checkAvatarSpineLoadHandler_ = nil
    end
end


function UnionLobbyMediator:bubblingAvatarDialogueBubble_(chatData)
    local chatData   = checktable(chatData)
    local playerId   = checkint(chatData.playerId)
    local message    = checkstr(chatData.message)
    local avatarCell = self.avatarCellDict_[tostring(playerId)]

    if avatarCell and avatarCell.cardSpine then
        local uiManager   = AppFacade.GetInstance():GetManager('UIManager')
        -- local chatMessage = utf8len(message) > CHAT_MESSAGE_MAX and utf8sub(message, 1, CHAT_MESSAGE_MAX) .. '...' or message
        uiManager:ShowDialogueBubble({
            parentNode     = avatarCell.avatarLayer,
            targetPosition = avatarCell.avatarLayer:convertToWorldSpace(cc.p(0, 180)),
            ignoreOutside  = true,
            alwaysOnCenter = true,
            alwaysOnTop    = true,
            descr          = message,
        })
    end
end


--------------------
-- about avatar move
--------------------

function UnionLobbyMediator:runAvatarMoveToPoint_(playerId, targetX, targetY)
    local avatarCell = self.avatarCellDict_[tostring(playerId)]
    if avatarCell then
        avatarCell.targetPoint = cc.p(checkint(targetX), checkint(targetY))

        local avatarX = avatarCell.view:getPositionX()
        local targetX = checkint(avatarCell.targetPoint.x)
        if avatarCell.cardSpine then
            avatarCell.cardSpine:setScaleX(avatarX <= targetX and 1 or -1)
            if avatarCell.cardSpine:getCurrent() ~= 'run' then
                avatarCell.cardSpine:setToSetupPose()
                avatarCell.cardSpine:setAnimation(0, 'run', true)
            end
        end
    end
end
function UnionLobbyMediator:startLobbyAvatarMove_()
    if self.lobbyAvatarMoveHandler_ then return end
    self.lobbyAvatarMoveHandler_ = scheduler.scheduleUpdateGlobal(function()
        local hasUpdateAvatar = false
        for memberId, avatarCell in pairs(self.avatarCellDict_) do
            if avatarCell.targetPoint and avatarCell.view then
                local avatarX = avatarCell.view:getPositionX()
                local avatarY = avatarCell.view:getPositionY()
                local targetX = checkint(avatarCell.targetPoint.x)
                local targetY = checkint(avatarCell.targetPoint.y)

                if avatarX > targetX then
                    avatarCell.view:setPositionX(math.max(avatarX - AVATAR_MOVE_SPEED, targetX))
                elseif avatarX < targetX then
                    avatarCell.view:setPositionX(math.min(avatarX + AVATAR_MOVE_SPEED, targetX))
                end

                if avatarY > targetY then
                    avatarCell.view:setPositionY(math.max(avatarY - AVATAR_MOVE_SPEED, targetY))
                elseif avatarY < targetY then
                    avatarCell.view:setPositionY(math.min(avatarY + AVATAR_MOVE_SPEED, targetY))
                end

                if avatarX == targetX and avatarY == targetY then
                    if avatarCell.cardSpine then
                        avatarCell.cardSpine:setToSetupPose()
                        avatarCell.cardSpine:setAnimation(0, 'idle', true)
                    end
                    avatarCell.targetPoint = nil
                end

                hasUpdateAvatar = true
            end
        end
        if hasUpdateAvatar then
            self:getLobbyScene():reorderAvatarLayer()
        end
    end)
end
function UnionLobbyMediator:stopLobbyAvatarMove_()
    if self.lobbyAvatarMoveHandler_ then
        scheduler.unscheduleGlobal(self.lobbyAvatarMoveHandler_)
        self.lobbyAvatarMoveHandler_ = nil
    end
end


function UnionLobbyMediator:startLobbyAvatarAutoMove_()
    if self.lobbyAvatarAutoMoveHandler_ then return end
    self.lobbyAvatarAutoMoveHandler_ = scheduler.scheduleGlobal(function()
        local outsideLobbyMemberList = {}
        for _, memberData in ipairs(self:getUnionData().roomMember or {}) do
            if memberData.isInUnionLobby ~= nil and memberData.isInUnionLobby == 0 then
                if checkint(memberData.playerId) ~= self.selfPlayerId_ then
                    table.insert(outsideLobbyMemberList, memberData.playerId)
                end
            end
        end
        if #outsideLobbyMemberList > 0 then
            local lobbyViewData  = self:getLobbyScene():getViewData()
            local randomMemberId = outsideLobbyMemberList[math.random(#outsideLobbyMemberList)]
            self:GetFacade():DispatchObservers(SGL.UNION_LOBBY_AVATAR_MOVE_TAKE, {
                memberId = randomMemberId,
                pointX   = lobbyViewData.avatarLayerOrigin.x + math.random(lobbyViewData.avatarLayerSize.width),
                pointY   = lobbyViewData.avatarLayerOrigin.y + math.random(lobbyViewData.avatarLayerSize.height),
            })
        end
    end, 5)
end
function UnionLobbyMediator:stopLobbyAvatarAutoMove_()
    if self.lobbyAvatarAutoMoveHandler_ then
        scheduler.unscheduleGlobal(self.lobbyAvatarAutoMoveHandler_)
        self.lobbyAvatarAutoMoveHandler_ = nil
    end
end


--------------------
-- about union party
--------------------


function UnionLobbyMediator:updateUnionImpeachmentState_()
    local unionData = self:getUnionData()
    -- 
    local unionPresidentPlayerId = unionData.unionPresidentPlayerId
    if unionPresidentPlayerId then
        
        return
    end
    local impeachmentTimes = unionData.impeachmentTimes
    local impeachmentTotalTimes = unionData.impeachmentTotalTimes
end

function UnionLobbyMediator:cleanUnionLobby_()
    -- popup other mediator
    self:GetFacade():BackMediator(self:GetMediatorName())

    -- remove other views
    local cleanViewsList = {
        'ChooseCardsHouseView',
        'common.PlayerHeadPopup',
        'Game.views.chat.ChatView',
    }
    for _, v in ipairs(cleanViewsList) do
        local dialogNode = sceneWorld:getChildByName(v)
        if dialogNode then
            sceneWorld:removeChild(dialogNode)
        else
            self:getLobbyScene():RemoveDialogByName(v)
        end
    end
    self:GetFacade():DispatchObservers(SGL.Battle_UI_Destroy_Battle_Ready)

    -- hide channel popup
    self:getLobbyScene():hideChannelPopup()
end


function UnionLobbyMediator:checkInPartyWorkflowTips_()
    if self:isPartyInWorkflow() then
        local uiMgr = AppFacade.GetInstance():GetManager('UIManager')
        uiMgr:ShowInformationTips(__('工会派对正在进行中，请稍候再试'))
        return true
    end
    return false
end


-------------------------------------------------
-- handler

function UnionLobbyMediator:onClickBackButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end

    self:SendSignal(POST.UNION_QUIT_HOME.cmdName)

    self.isControllable_ = false
    transition.execute(self:getLobbyScene(), nil, {delay = 0.3, complete = function()
        self.isControllable_ = true
    end})
end


function UnionLobbyMediator:onClickTitleButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ or self:checkInPartyWorkflowTips_() then return end

    local uiMgr = self:GetFacade():GetManager('UIManager')
    uiMgr:ShowIntroPopup({moduleId = MODULE_DATA[tostring(RemindTag.UNION)]})
end


-- function: monster
function UnionLobbyMediator:onClickMonsterButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ or self:checkInPartyWorkflowTips_() then return end

    local mediator = require("Game.mediator.UnionBeastBabyDevMediator").new()
    self:GetFacade():RegistMediator(mediator)
end


-- function: info
function UnionLobbyMediator:onClickInfoButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ or self:checkInPartyWorkflowTips_() then return end
    
    local mediator = require("Game.mediator.UnionInforMediator").new()
    self:GetFacade():RegistMediator(mediator)
end


-- function: task
function UnionLobbyMediator:onClickTaskButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ or self:checkInPartyWorkflowTips_() then return end

    local mediator = require("Game.mediator.task.TaskHomeMediator").new({clickTag = 1003})
    self:GetFacade():RegistMediator(mediator)

end


-- function: show
function UnionLobbyMediator:onClickShopButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ or self:checkInPartyWorkflowTips_() then return end

    local mediator = require("Game.mediator.UnionShopMediator").new()
    self:GetFacade():RegistMediator(mediator)
end


-- function: build
function UnionLobbyMediator:onClickBuildButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ or self:checkInPartyWorkflowTips_() then return end

    local mediator = require("Game.mediator.UnionBuildMediator").new()
    self:GetFacade():RegistMediator(mediator)
end


-- function: activity
function UnionLobbyMediator:onClickActivityButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ or self:checkInPartyWorkflowTips_() then return end

    local mediator = require("Game.mediator.UnionActivityMediator").new()
    self:GetFacade():RegistMediator(mediator)
end


-- function: battle
function UnionLobbyMediator:onClickBattleButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ or self:checkInPartyWorkflowTips_() then return end

    local uiMgr = AppFacade.GetInstance():GetManager('UIManager')
    uiMgr:ShowInformationTips('工会战斗')
end


function UnionLobbyMediator:onClickChannelBlockBgHandler_(sender)
    if not self.isControllable_ or self:checkInPartyWorkflowTips_() then return end

    self.isControllable_ = false
    self:getLobbyScene():hideChannelPopup(function()
        self.isControllable_ = true
    end)
end
function UnionLobbyMediator:onClickChannelButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ or self:checkInPartyWorkflowTips_() then return end

    self.isControllable_ = false
    self:reloadChannelData_()
    self:getLobbyScene():showChannelPopup(function()
        self.isControllable_ = true
    end)
end


function UnionLobbyMediator:onChannelTableDataSourceHandler_(cell, idx)
    local pCell = cell
    local index = idx + 1

	-- create cell
    if pCell == nil then
    	local cellViewData  = self:getLobbyScene():createChannelCell()
    	cellViewData.clickArea:setOnClickScriptHandler(handler(self, self.onClickChannelCellHandler_))
    	pCell = cellViewData.view
    	self.channelCellDict_[pCell] = cellViewData
    end

    -- init cell
	local cellViewData = self.channelCellDict_[pCell]
    cellViewData.clickArea:setTag(index)
    
    -- update cell
    self:updateChannelCell_(index, cellViewData)
    return pCell
end
function UnionLobbyMediator:onClickChannelCellHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end

    self.switchRoomId_  = checkint(sender:getTag())
    local currentRoomId = self:getLobbyRoomId()
    local uiManager     = AppFacade.GetInstance():GetManager('UIManager')

    -- check same room
    if currentRoomId == self.switchRoomId_ then
        uiManager:ShowInformationTips(__('当前已处于该区域'))

    else
        local channelMapData = self:getUnionData().roomMemberNumber or {}
        local channelMembers = checkint(channelMapData[tostring(self.switchRoomId_)])

        -- check member number
        if channelMembers >= UNION_ROOM_MEMBERS then
            uiManager:ShowInformationTips(__('该区域人数已满'))

        else
            self:SendSignal(POST.UNION_SWITCH_ROOM.cmdName, {roomId = self.switchRoomId_})
    
            self.isControllable_ = false
            transition.execute(self:getLobbyScene(), nil, {delay = 0.3, complete = function()
                self.isControllable_ = true
            end})
        end
    end
end

function UnionLobbyMediator:onClickImpeachmentTouchViewHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ or self:checkInPartyWorkflowTips_() then return end

    local unionData                       = self:getUnionData()
    local impeachmentData                 = unionData.impeachmentData or {}
    if checkint(impeachmentData.isUnionImpeachment) > 0 then
        app.uiMgr:ShowInformationTips(__('已弹劾过'))
        return
    end
    local scene = app.uiMgr:GetCurrentScene()
    local CommonTip  = require( 'common.NewCommonTip' ).new({text = __('投票后不可取消，确定要弹劾当前会长吗？'),
        isOnlyOK = false, callback = function ()
            self:SendSignal(POST.UNION_IMPEACHMENT.cmdName, {isUnionImpeachment = 1})
    end})
    CommonTip:setPosition(display.center)
    scene:AddDialog(CommonTip)
end

function UnionLobbyMediator:onClickImpeachmentTipsIconHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ or self:checkInPartyWorkflowTips_() then return end

    app.uiMgr:ShowIntroPopup({moduleId = MODULE_DATA[tostring(RemindTag.UNION_IMPEACHMENT)]})
end


function UnionLobbyMediator:onClickAvatarCellHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ or self:isPartyInWorkflow() then return end
    
    local playerId  = checkint(sender:getTag())
    local uiManager = AppFacade.GetInstance():GetManager('UIManager')
    uiManager:AddDialog('common.PlayerHeadPopup', {playerId = playerId, type = CommonUtils.GetHeadPopupTypeByPlayerId(playerId)})
end


function UnionLobbyMediator:onTouchBegan_(touch, event)
    local touchPoint = touch:getLocation()
    self.touchPoint_ = cc.p(checkint(touchPoint.x), checkint(touchPoint.y))
    return true
end
function UnionLobbyMediator:onTouchMoved_(touch, event)
end
function UnionLobbyMediator:onTouchEnded_(touch, event)
    local touchPoint = touch:getLocation()
    if self.touchPoint_ then
        -- check is click
        local offsetX = math.abs(self.touchPoint_.x - touchPoint.x)
        local offsetY = math.abs(self.touchPoint_.y - touchPoint.y)
        if offsetX > 10 or offsetY > 10 then
            self.touchPoint_ = nil
        end
    end
end


function UnionLobbyMediator:onClickAvatarRangeLayerHandler_(sender)
    if self.touchPoint_ then
        local socketManager   = self:GetFacade():GetManager('SocketManager')
        self.sendMoveToPoint_ = self.touchPoint_
        socketManager:SendPacket(NetCmd.UNION_AVATAR_MOVE_SEND, {
            pointX = self.sendMoveToPoint_.x,
            pointY = self.sendMoveToPoint_.y,
        })
    end
end


function UnionLobbyMediator:onClickSkinHeadLayerHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ or self:checkInPartyWorkflowTips_() then return end
    
    local gameManager          = self:GetFacade():GetManager('GameManager')
    local selfRoomMemberData   = self:getSelfRoomMemberData() or {}
    local selfRoomCardData     = gameManager:GetCardDataByCardId(selfRoomMemberData.defaultCardId) or {}
    local chooseCardsHouseView = require('Game.views.ChooseCardsHouseView').new({
        type          = 2,
        isAutonClose  = true,
        cardHouseData = {
            [tostring(selfRoomCardData.id)] = true
        },
        callback = function(data)
            self:SendSignal(POST.UNION_CHANGE_AVATAR.cmdName, {defaultCardId = data.cardId, defaultCardSkin = data.skinId})

            self.isControllable_ = false
            transition.execute(self:getLobbyScene(), nil, {delay = 0.3, complete = function()
                self.isControllable_ = true
            end})
        end
    })

    chooseCardsHouseView:RefreshUI()
    chooseCardsHouseView:setPosition(display.center)
    self:getLobbyScene():AddDialog(chooseCardsHouseView)
end


return UnionLobbyMediator

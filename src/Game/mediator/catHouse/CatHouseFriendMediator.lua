--[[
 * author : panmeng
 * descpt : 猫屋 好友 管理者
]]
local CatHouseFriendView     = require('Game.views.catHouse.CatHouseFriendView')
local CatHouseFriendMediator = class('CatHouseFriendMediator', mvc.Mediator)

function CatHouseFriendMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'CatHouseFriendMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end


-------------------------------------------------
-- inheritance

function CatHouseFriendMediator:Initial(key)
    self.super.Initial(self, key)

    -- init vars
    self.isControllable_ = true

    ui.bindClick(self:getViewData().touchLayer, handler(self, self.onClickBackButtonHandler_), false)
    self:getViewData().friendTableView:setCellInitHandler(function(cellViewData)
        cellViewData.toggleFrameBtn:setOnClickScriptHandler(handler(self, self.onClickFriendCellHandler_))
        ui.bindClick(cellViewData.visitBtn, handler(self, self.onClickVisitBtnHandler_))
        ui.bindClick(cellViewData.inviteBtn, handler(self, self.onClickInviteBtnHandler_))
        ui.bindClick(cellViewData.toTravelBtn, handler(self, self.onClickToTravelBtnHandler_))
    end)
    self:getViewData().friendTableView:setCellUpdateHandler(handler(self, self.onUpdateFriendCellHandler_))
end


function CatHouseFriendMediator:CleanupView()
end


function CatHouseFriendMediator:OnRegist()
    local FriendCommand = require('Game.command.FriendCommand')
    self:GetFacade():RegistSignal(CMD.COMMAND_Friend_List, FriendCommand)
    regPost(POST.HOUSE_FRIEND_INVITE)
    regPost(POST.HOUSE_CAT_ACT_OUTING)
    
    self:SendSignal(CMD.COMMAND_Friend_List)
end


function CatHouseFriendMediator:OnUnRegist()
    self:GetFacade():UnRegsitSignal(CMD.COMMAND_Friend_List)
    unregPost(POST.HOUSE_FRIEND_INVITE)
    unregPost(POST.HOUSE_CAT_ACT_OUTING)
end


function CatHouseFriendMediator:InterestSignals()
    return {
        SGL.Friend_List_Callback,
        SGL.CAT_HOUSE_FRIEND_UPDATE_OWNER,
        SGL.CAT_MODEL_UPDATE_OUT_TIMESTAMP,
        POST.HOUSE_FRIEND_INVITE.sglName,
        POST.HOUSE_CAT_ACT_OUTING.sglName,
    }
end
function CatHouseFriendMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()

    if name == SGL.Friend_List_Callback then
        app.gameMgr:GetUserInfo().friendList = data.friendList
        self:initHomeData_(data)

    elseif name == SGL.CAT_HOUSE_FRIEND_UPDATE_OWNER then
        self:getViewNode():updateCellSelctedStatue(app.catHouseMgr:getHouseOwnerId())

    elseif name == POST.HOUSE_FRIEND_INVITE.sglName then
        app.uiMgr:ShowInformationTips(__('邀请发送成功'))

    elseif name == POST.HOUSE_CAT_ACT_OUTING.sglName then
        app.uiMgr:ShowInformationTips(__('派遣成功'))
        local friendId    = checkint(data.requestData.friendId)
        local friendIdx   = self.friendIndexMap_[friendId]
        local playerCatId = checkint(data.requestData.playerCatId)
        local catModel    = app.catHouseMgr:getCatModel(CatHouseUtils.BuildCatUuid(app.gameMgr:GetPlayerId(), playerCatId))
        -- update my catModel
        catModel:setOutFriendId(friendId)
        catModel:setOutLeftSeconds(data.leftSeconds)
        catModel:setOutCountLeft(catModel:getOutCountLeft() - 1)
        -- update table cell
        self:getViewData().friendTableView:updateCellViewData(friendIdx)

    elseif name == SGL.CAT_MODEL_UPDATE_OUT_TIMESTAMP then
        for _, cellViewData in pairs(self:getViewData().friendTableView:getCellViewDataDict()) do
            if data.catUuid == cellViewData.onTravelBtn.outCatUuid or data.outFriendId == cellViewData.buttonLayer:getTag() then
                self:getViewData().friendTableView:updateCellViewData(cellViewData.view:getTag())
                break
            end
        end    
    end
end


-------------------------------------------------
-- get / set

function CatHouseFriendMediator:getViewNode()
    return self:GetViewComponent()
end
function CatHouseFriendMediator:getViewData()
    return self:GetViewComponent():getViewData()
end


-------------------------------------------------
-- public

function CatHouseFriendMediator:close()
    app:UnRegsitMediator(self:GetMediatorName())
end


function CatHouseFriendMediator:hideFriendList()
    self:GetViewComponent():setVisible(false)
end


function CatHouseFriendMediator:showFriendList()
    self:GetViewComponent():setVisible(true)
end


function CatHouseFriendMediator:checkIsFriendUnlockCatHouse(friendId)
    local friendData      = CommonUtils.GetFriendData(friendId)
    if not friendData then
        return false
    end
    local isLevelOpen     = CommonUtils.GetModuleOpenLevel(MODULE_DATA[tostring(RemindTag.CAT_HOUSE)]) <= checkint(friendData.level)
    local isHallLevelOpen = CommonUtils.GetModuleOpenRestaurantLevel(MODULE_DATA[tostring(RemindTag.CAT_HOUSE)]) <= checkint(friendData.restaurantLevel)
    return isLevelOpen and isHallLevelOpen
end

-------------------------------------------------
-- private

function CatHouseFriendMediator:initHomeData_(homeData)
    app.gameMgr:GetUserInfo().firendList = homeData.friendList
    self.friendListData_ = homeData.friendList or {}
    self.friendIndexMap_ = {}

    if #self.friendListData_ > 1 then
        table.sort(self.friendListData_, function(firendDataA, friendDataB)
            if checkint(firendDataA.houseLevel) ~= checkint(friendDataB.houseLevel) then
                return checkint(firendDataA.houseLevel) > checkint(friendDataB.houseLevel)
            else
                return checkint(firendDataA.friendId) < checkint(friendDataB.friendId)
            end
        end)
        for friendIndex, friendData in ipairs(self.friendListData_) do
            self.friendIndexMap_[checkint(friendData.friendId)] = friendIndex
        end
    end
    self:getViewData().friendTableView:resetCellCount(#self.friendListData_)
    self:getViewData().friendCountLb:setString(string.format(__("好友人数: %s/%s"), CommonUtils.GetOnlineFriendNum(), #self.friendListData_))
end


-------------------------------------------------
-- handler

function CatHouseFriendMediator:onClickBackButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end

    self:hideFriendList()
end


function CatHouseFriendMediator:onClickFriendCellHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local friendId = checkint(sender:getTag())
    if friendId == app.catHouseMgr:getHouseOwnerId() then
        sender:setChecked(true)
    else
        sender:setChecked(false)
        if self:checkIsFriendUnlockCatHouse(friendId) then
            if app.catHouseMgr:checkCanGoToFriendHouse(friendId) then
                app.catHouseMgr:goToFriendHouse(friendId)
            end
        else
            app.uiMgr:ShowInformationTips(__("该好友暂未开启猫屋"))
        end
    end
end


function CatHouseFriendMediator:onUpdateFriendCellHandler_(cellIndex, cellViewData)
    local friendData = self.friendListData_[cellIndex]
    self:GetViewComponent():updateFriendCellViewData(cellIndex, cellViewData, friendData)
end


function CatHouseFriendMediator:onClickInviteBtnHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local friendId = checkint(sender:getParent():getTag())
    if self:checkIsFriendUnlockCatHouse(friendId) then
        self:SendSignal(POST.HOUSE_FRIEND_INVITE.cmdName, {friendIds = tostring(friendId)})
    else
        app.uiMgr:ShowInformationTips(__("该好友暂未开启猫屋"))
    end
end


function CatHouseFriendMediator:onClickVisitBtnHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end

    local friendId = checkint(sender:getParent():getTag())
    if self:checkIsFriendUnlockCatHouse(friendId) then
        if app.catHouseMgr:checkCanGoToFriendHouse(friendId) then
            app.catHouseMgr:goToFriendHouse(friendId)
        end
    else
        app.uiMgr:ShowInformationTips(__("该好友暂未开启猫屋"))
    end
end


function CatHouseFriendMediator:onClickToTravelBtnHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end

    local friendId = checkint(sender:getParent():getTag())
    if not self:checkIsFriendUnlockCatHouse(friendId) then
        app.uiMgr:ShowInformationTips(__("该好友暂未开启猫屋"))
    elseif table.nums(app.catHouseMgr:getCatsModelMap()) <= 0 then
        app.uiMgr:ShowInformationTips(__("您当前暂无猫咪"))
    else
        local chooseCatPopup = require('Game.views.catModule.CatModuleChooseCatPopup').new({
            choosePopupType = CatHouseUtils.CAT_CHOOSE_POPUP_TYPE.OUT_GOING,
            multipChooseMix = 1,
            multipChooseMax = 1,
            confirmStr      = __("外出"),
            confirmCB       = function(catIdList)
                self:SendSignal(POST.HOUSE_CAT_ACT_OUTING.cmdName, {friendId = friendId, playerCatId = string.split(catIdList[1], "_")[2]})
            end,
        })
        app.uiMgr:GetCurrentScene():AddDialog(chooseCatPopup)
    end
end


return CatHouseFriendMediator

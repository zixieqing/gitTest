--[[
 * author : panmeng
 * descpt : 好友猫屋 预览功能
]]
local CatHouseFriendAvatarView     = require('Game.views.catHouse.CatHouseFriendAvatarView')
local CatHouseFriendAvatarMediator = class('CatHouseFriendAvatarMediator', mvc.Mediator)

function CatHouseFriendAvatarMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'CatHouseFriendAvatarMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end


-------------------------------------------------
-- inheritance

function CatHouseFriendAvatarMediator:Initial(key)
    self.super.Initial(self, key)

    -- init vars
    self.isControllable_ = true

    -- create view
    self.viewNode_ = CatHouseFriendAvatarView.new()
    self:SetViewComponent(self:getViewNode())
    app.uiMgr:GetCurrentScene():AddGameLayer(self:getViewNode())

    -- add listener
    ui.bindClick(self:getViewData().backBtn, handler(self, self.onClickBackButtonHandler_))
    ui.bindClick(self:getViewData().infoBtn, handler(self, self.onClickInfoButtonHandler_))
    ui.bindClick(self:getViewData().collBtn, handler(self, self.onClickCollButtonHandler_))

    self.avatarMdt_ = require('Game.mediator.catHouse.CatHouseAvatarMediator').new({isPreviewMode = true}, self:getViewData().avatarLayer)
    app:RegistMediator(self.avatarMdt_)
end


function CatHouseFriendAvatarMediator:CleanupView()
    if self:getViewNode() and not tolua.isnull(self:getViewNode()) then
        self:getViewNode():removeFromParent()
        self.viewNode_ = nil
    end
end


function CatHouseFriendAvatarMediator:OnRegist()
    regPost(POST.HOUSE_HOME_QUITE)

    app.catHouseMgr:goToFriendHouse(self.ctorArgs_.friendId)
end


function CatHouseFriendAvatarMediator:OnUnRegist()
    unregPost(POST.HOUSE_HOME_QUITE)
end


function CatHouseFriendAvatarMediator:InterestSignals()
    return {
        POST.HOUSE_HOME_QUITE.sglName,
        SGL.CAT_HOUSE_GET_FRIEND_AVATAR_DATA,
        SGL.CAT_HOUSE_MEMBER_LEAVE,
    }
end
function CatHouseFriendAvatarMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()

    if name == POST.HOUSE_HOME_QUITE.sglName then
        self:close()

    elseif name == SGL.CAT_HOUSE_GET_FRIEND_AVATAR_DATA then
        self.avatarMdt_:initHomeData(app.catHouseMgr:getVisitFriendHouseData().location)

    elseif name == SGL.CAT_HOUSE_MEMBER_LEAVE then
        if app.gameMgr:IsPlayerSelf(data.memberId) then
            app.uiMgr:ShowInformationTips(__('你已被踢出好友御屋'))
            self:close()
        end

    end
end


-------------------------------------------------
-- get / set

function CatHouseFriendAvatarMediator:getViewNode()
    return  self.viewNode_
end
function CatHouseFriendAvatarMediator:getViewData()
    return self:getViewNode():getViewData()
end


-------------------------------------------------
-- public

function CatHouseFriendAvatarMediator:close()
    app.catHouseMgr:setHouseOwnerId(0)
    self.avatarMdt_:close()
    app:UnRegsitMediator(self:GetMediatorName())
end


-------------------------------------------------
-- private

function CatHouseFriendAvatarMediator:initHomeData_(homeData)
    self.avatarMdt_:initHomeData(homeData.location)
end


-------------------------------------------------
-- handler

function CatHouseFriendAvatarMediator:onClickBackButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end

    self:SendSignal(POST.HOUSE_HOME_QUITE.cmdName)
end


function CatHouseFriendAvatarMediator:onClickInfoButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local houseData = app.catHouseMgr:getVisitFriendHouseData()
    local infoMdt   = require('Game.mediator.catHouse.CatHouseInfoMediator').new({friendId = app.catHouseMgr:getHouseOwnerId() , houseData = houseData})
    app:RegistMediator(infoMdt)
end


function CatHouseFriendAvatarMediator:onClickCollButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local houseData = app.catHouseMgr:getVisitFriendHouseData()
    local collMdt   = require('Game.mediator.catHouse.CatHouseCollMediator').new({friendId = app.catHouseMgr:getHouseOwnerId() , houseData = houseData})
    app:RegistMediator(collMdt)
end


return CatHouseFriendAvatarMediator

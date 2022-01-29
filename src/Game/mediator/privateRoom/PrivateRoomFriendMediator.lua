--[[
包厢好友mediator    
--]]
local Mediator = mvc.Mediator
local PrivateRoomFriendMediator = class("PrivateRoomFriendMediator", Mediator)
local NAME = "PrivateRoomFriendMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager('GameManager')
function PrivateRoomFriendMediator:ctor( params, viewComponent )
	self.super:ctor(NAME, viewComponent)
	self.ctorArgs_ = checktable(params)
end

function PrivateRoomFriendMediator:InterestSignals()
	local signals = {
	}
	return signals
end

function PrivateRoomFriendMediator:ProcessSignal( signal )
	local name = signal:GetName()
	print(name)
end

function PrivateRoomFriendMediator:Initial( key )
	self.super.Initial(self, key)
	local ctorArgs = checktable(self.ctorArgs_)
	self.currentFriendId_ = nil 
	self.switchDoorView_ = nil 
	self.currentScene_   = app.uiMgr:GetCurrentScene()
	self.initFriendId_   = checkint(ctorArgs.friendId)
	-- 创建CarnieCapsulePoolView
	local viewComponent = require( 'Game.views.privateRoom.PrivateRoomFriendView' ).new()
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	local scene = uiMgr:GetCurrentScene()
	scene:AddGameLayer(viewComponent)
	self.switchDoorView_ = viewComponent:CreateDoorView()
    self.currentScene_:AddDialog(self.switchDoorView_.view)
	self.switchDoorView_.view:setVisible(false)
	local friendViewData = viewComponent.viewData
    friendViewData.friendHeaderNode:setClickCallback(handler(self, self.onClickFriendHeaderHandler_))
    friendViewData.backBtn:setOnClickScriptHandler(handler(self, self.BackAction))
end
function PrivateRoomFriendMediator:SetCurrentFriendId( friendId )
    if self:GetCurrentFriendId() ~= checkint(friendId) then
        self:CloseSwitchDoor(function()
			self.currentFriendId_ = checkint(friendId)
			self:RefreshView()
        end)
	end
end
function PrivateRoomFriendMediator:RefreshView()
	local friendData = {}
	local friendId = self:GetCurrentFriendId()
	for _, friend in ipairs(app.gameMgr:GetUserInfo().friendList or {}) do
		if checkint(friend.friendId) == checkint(friendId) then
			friendData = friend
			break
		end
	end
	if friendId == -1 then
        local officialConfs = CommonUtils.GetConfigAllMess('show', 'privateRoom') or {}
        friendData = {
			themeId         = officialConfs.themeId,
            name            = checkstr(officialConfs.name),
            level           = checkint(officialConfs.level),
            restaurantLevel = checkint(officialConfs.restaurantLevel),
			avatarFrame     = checkstr(officialConfs.avatarFrame),
			assistantCardId = checkint(officialConfs.assistantCardId)
        }
	end
    local viewComponent = self:GetViewComponent()
	viewComponent:RefreshView(friendData)
	self:OpenSwitchDoor()
end
function PrivateRoomFriendMediator:CloseSwitchDoor(endCb)
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
function PrivateRoomFriendMediator:OpenSwitchDoor(endCb)
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
function PrivateRoomFriendMediator:GetCurrentFriendId()
    return checkint(self.currentFriendId_)
end
function PrivateRoomFriendMediator:BackAction()
    PlayAudioByClickClose()
    local LobbyFriendMediator = self:GetFacade():RetrieveMediator('LobbyFriendMediator')
    if LobbyFriendMediator then
        LobbyFriendMediator:initFriendIndexState()
    end
    self:GetFacade():UnRegsitMediator(NAME)
end

function PrivateRoomFriendMediator:onClickFriendHeaderHandler_()
    PlayAudioByClickNormal()
    local friendId = self:GetCurrentFriendId()
    
    if friendId > 0 then
        local mediator = require("Game.mediator.PersonInformationMediator").new({playerId = friendId})
        AppFacade.GetInstance():RegistMediator(mediator)
    end
end
function PrivateRoomFriendMediator:OnRegist(  )
    -- self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "rightHide")
    app.uiMgr:UpdatePurchageNodeState(false)
    self:SetCurrentFriendId(self.initFriendId_)
end

function PrivateRoomFriendMediator:OnUnRegist(  )
    -- self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "rightShow")
    app.uiMgr:UpdatePurchageNodeState(true)
	-- 移除界面
	local scene = uiMgr:GetCurrentScene()
	scene:RemoveGameLayer(self:GetViewComponent())
end
return PrivateRoomFriendMediator
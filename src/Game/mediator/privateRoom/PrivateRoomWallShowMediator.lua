--[[
包厢主题mediator    
--]]
local Mediator = mvc.Mediator
local PrivateRoomWallShowMediator = class("PrivateRoomWallShowMediator", Mediator)
local NAME = "privateRoom.PrivateRoomWallShowMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager('GameManager')
function PrivateRoomWallShowMediator:ctor( params, viewComponent )
	self.wallData = params.wallData or {}
    self.super:ctor(NAME, viewComponent)
end

function PrivateRoomWallShowMediator:InterestSignals()
	local signals = {
	}
	return signals
end

function PrivateRoomWallShowMediator:ProcessSignal( signal )
	local name = signal:GetName()
	print(name)
end

function PrivateRoomWallShowMediator:Initial( key )
	self.super.Initial(self, key)
	-- 创建CarnieCapsulePoolView
	local viewComponent = require( 'Game.views.privateRoom.PrivateRoomWallShowView' ).new()
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	local scene = uiMgr:GetCurrentScene()
	scene:AddDialog(viewComponent)
	viewComponent.viewData.wallView:SetSouvenirNodeOnClick(handler(self, self.SouvenirCallback))
	viewComponent.eaterLayer:setOnClickScriptHandler(handler(self, self.BackAction))
	viewComponent.viewData.backBtn:setOnClickScriptHandler(handler(self, self.BackAction))
    self:InitView()
end
--[[
初始化页面
--]]
function PrivateRoomWallShowMediator:InitView()
	local wallData = self.wallData
	self:GetViewComponent().viewData.wallView:RefreshWall(wallData)
end
--[[
纪念品点击回调
--]]
function PrivateRoomWallShowMediator:SouvenirCallback( sender )
	PlayAudioByClickNormal()
	local tag = sender:getTag()
	local goodsId = self.wallData[tostring(tag)]
	if goodsId and goodsId ~= '' then
		uiMgr:AddDialog("Game.views.privateRoom.PrivateRoomSouvenirDetailPopup", {goodsId = goodsId})
	end
end
function PrivateRoomWallShowMediator:BackAction()
	PlayAudioByClickClose()
	AppFacade.GetInstance():UnRegsitMediator("privateRoom.PrivateRoomWallShowMediator")
end
function PrivateRoomWallShowMediator:EnterAction()
	local viewComponent = self:GetViewComponent()
	viewComponent.viewData.view:setScale(0.8)
	viewComponent.viewData.view:runAction(
		cc.Sequence:create(
			cc.EaseBackOut:create(
				cc.ScaleTo:create(0.3, 1)
			)
		)
	)
end
function PrivateRoomWallShowMediator:OnRegist(  )
	self:EnterAction()
end

function PrivateRoomWallShowMediator:OnUnRegist(  )
	-- 移除界面
	local scene = uiMgr:GetCurrentScene()
	scene:RemoveGameLayer(self:GetViewComponent())
end
return PrivateRoomWallShowMediator
--[[
活动弹出页 首充 mediator    
--]]
local Mediator = mvc.Mediator
local ActivityFirstTopupPopupMediator = class("ActivityFirstTopupPopupMediator", Mediator)
local NAME = "ActivityFirstTopupPopupMediator"
function ActivityFirstTopupPopupMediator:ctor( params, viewComponent )
    self.super:ctor(NAME, viewComponent)
    self.showSpine = false
end

function ActivityFirstTopupPopupMediator:InterestSignals()
	local signals = {
	}
	return signals
end

function ActivityFirstTopupPopupMediator:ProcessSignal( signal )
    local name = signal:GetName()
    local body = signal:GetBody()
    print(name)
end

function ActivityFirstTopupPopupMediator:Initial( key )
    self.super.Initial(self, key)
    local viewComponent = require( 'Game.views.activity.popup.ActivityFirstTopupPopupView' ).new()
    viewComponent:setPosition(cc.p(display.cx, display.cy))
    app.uiMgr:GetCurrentScene():AddDialog(viewComponent)
    self:SetViewComponent(viewComponent)
    local viewData = viewComponent:GetViewData()
    viewData.jumpBtn:setOnClickScriptHandler(handler(self, self.JumpButtonCallback))
    viewComponent.eaterLayer:setOnClickScriptHandler(handler(self, self.BackButtonCallback))
end

---------------------------------------------
----------------- method --------------------

----------------- method --------------------
---------------------------------------------

---------------------------------------------
---------------- callback -------------------
--[[
跳转按钮回调
--]]
function ActivityFirstTopupPopupMediator:JumpButtonCallback( sender )
    PlayAudioByClickNormal()
    if GAME_MODULE_OPEN.NEW_STORE then
		app.uiMgr:showGameStores({storeType = GAME_STORE_TYPE.DIAMOND})
    else
        app.router:Dispatch({name = "HomeMediator"}, {name = "ShopMediator"})
	end
    AppFacade.GetInstance():UnRegsitMediator("ActivityFirstTopupPopupMediator")
end
--[[
返回按钮回调
--]]
function ActivityFirstTopupPopupMediator:BackButtonCallback( sender )
    PlayAudioByClickClose()
    AppFacade.GetInstance():UnRegsitMediator("ActivityFirstTopupPopupMediator")
end
---------------- callback -------------------
---------------------------------------------

---------------------------------------------
---------------- get / set ------------------

---------------- get / set ------------------
---------------------------------------------
function ActivityFirstTopupPopupMediator:OnRegist(  )
end

function ActivityFirstTopupPopupMediator:OnUnRegist(  )
    app.uiMgr:GetCurrentScene():RemoveDialog(self:GetViewComponent())
end
return ActivityFirstTopupPopupMediator
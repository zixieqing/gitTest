local Mediator = mvc.Mediator
---@class ReturnWelfareDoubleMediator:Mediator
local ReturnWelfareDoubleMediator = class("ReturnWelfareDoubleMediator", Mediator)

local NAME = "ReturnWelfareDoubleMediator"
local app = app
local uiMgr = app.uiMgr

function ReturnWelfareDoubleMediator:ctor( params, viewComponent )
	self.super:ctor(NAME,viewComponent)
    self.datas = checktable(params) or {}
end

function ReturnWelfareDoubleMediator:InterestSignals()
	local signals = { 
	}

	return signals
end

function ReturnWelfareDoubleMediator:ProcessSignal( signal )
	local name = signal:GetName() 
	local body = signal:GetBody()
	-- dump(body, name)
end

function ReturnWelfareDoubleMediator:Initial( key )
	self.super.Initial(self, key)
	-- local scene = uiMgr:GetCurrentScene()
	local viewComponent  = require('Game.views.returnWelfare.ReturnWelfareDoubleView').new()
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
    -- scene:AddDialog(viewComponent)
    self.datas.parent:addChild(viewComponent)
    
    self:RefreshUI()
    local viewData = viewComponent.viewData
    viewData.gotoBtn1:setOnClickScriptHandler(handler(self, self.SupplyBtnClickHandler))
    viewData.gotoBtn2:setOnClickScriptHandler(handler(self, self.ShopBtnClickHandler))
    viewData.gotoBtn3:setOnClickScriptHandler(handler(self, self.ExtBtnClickHandler))
end

function ReturnWelfareDoubleMediator:RefreshUI(  )
    local viewData = self.viewComponent.viewData
end

function ReturnWelfareDoubleMediator:ResetMdt( data )
    self.datas.data = checktable(data) or {}
    self:RefreshUI()
end

function ReturnWelfareDoubleMediator:SupplyBtnClickHandler(sender)
	PlayAudioByClickNormal()
    app.router:Dispatch({name = 'ReturnWelfareMediator'}, {name = 'MaterialTranScriptMediator'})
end

function ReturnWelfareDoubleMediator:ShopBtnClickHandler(sender)
	PlayAudioByClickNormal()
	app.uiMgr:showGameStores({storeType = GAME_STORE_TYPE.GIFTS})
end

function ReturnWelfareDoubleMediator:ExtBtnClickHandler(sender)
	PlayAudioByClickNormal()
	local node = require('common.ExpDesrPopUp').new()
	uiMgr:GetCurrentScene():AddDialog(node)
end

function ReturnWelfareDoubleMediator:OnRegist(  )
end

function ReturnWelfareDoubleMediator:OnUnRegist(  )
	-- local scene = uiMgr:GetCurrentScene()
	-- scene:RemoveGameLayer(self.viewComponent)
end

return ReturnWelfareDoubleMediator
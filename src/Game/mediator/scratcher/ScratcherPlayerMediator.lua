local Mediator = mvc.Mediator
---@class ScratcherPlayerMediator:Mediator
---@field viewComponent ScratcherPlayerView
local ScratcherPlayerMediator = class("ScratcherPlayerMediator", Mediator)

local NAME = "ScratcherPlayerMediator"

function ScratcherPlayerMediator:ctor( params, viewComponent )
	self.super:ctor(NAME,viewComponent)
	self.data = checktable(params) or {}
end

function ScratcherPlayerMediator:InterestSignals()
	local signals = { 
        POST.FOOD_COMPARE_VOTE.sglName,
	}

	return signals
end

function ScratcherPlayerMediator:ProcessSignal( signal )
	local name = signal:GetName() 
	local body = signal:GetBody()
	-- dump(body, name)
	if POST.FOOD_COMPARE_VOTE.sglName == name then
		local mediator = require('Game.mediator.scratcher.ScratcherTaskMediator').new(self.data)
		AppFacade.GetInstance():RegistMediator(mediator)

		app:UnRegsitMediator("ScratcherPlatformMediator")
		app:UnRegsitMediator(NAME)
	end
end

function ScratcherPlayerMediator:Initial( key )
	self.super.Initial(self, key)
	local scene = app.uiMgr:GetCurrentScene()
	local viewComponent  = require('Game.views.scratcher.ScratcherPlayerView').new(self.data)
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	scene:AddDialog(viewComponent)
    local viewData = viewComponent.viewData
    
	viewData.cancelBtn:setOnClickScriptHandler(handler(self, self.OnCancelBtnClickHandler))
	viewData.supportBtn:setOnClickScriptHandler(handler(self, self.SupportBtnClickHandler))
	for k, v in pairs(viewData.goodsIcons) do
		v:setOnClickScriptHandler(handler(self, self.OnGoodsBtnClickHandler))
	end
end

function ScratcherPlayerMediator:OnRegist(  )
	regPost(POST.FOOD_COMPARE_VOTE)
end

function ScratcherPlayerMediator:OnUnRegist(  )
    unregPost(POST.FOOD_COMPARE_VOTE)
	local scene = app.uiMgr:GetCurrentScene()
	scene:RemoveGameLayer(self.viewComponent)
end

function ScratcherPlayerMediator:SupportBtnClickHandler( sender )
	PlayAudioByClickNormal()
	
	self:SendSignal(POST.FOOD_COMPARE_VOTE.cmdName, {activityId = self.data.requestData.activityId, cardId = self.data.myChoice})
end

function ScratcherPlayerMediator:OnCancelBtnClickHandler( sender )
	PlayAudioByClickClose()
	
    app:UnRegsitMediator(NAME)
end

function ScratcherPlayerMediator:OnGoodsBtnClickHandler(sender)
	app.uiMgr:ShowInformationTipsBoard({
		targetNode = sender, iconId = checkint(sender.goodId), type = 1
	})
end

return ScratcherPlayerMediator
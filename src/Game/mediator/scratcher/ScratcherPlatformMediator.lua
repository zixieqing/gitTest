local Mediator = mvc.Mediator
---@class ScratcherPlatformMediator:Mediator
---@field viewComponent ScratcherPlatformView
local ScratcherPlatformMediator = class("ScratcherPlatformMediator", Mediator)

local NAME = "ScratcherPlatformMediator"

function ScratcherPlatformMediator:ctor( params, viewComponent )
	self.super:ctor(NAME,viewComponent)
	self.data = checktable(params) or {}
end

function ScratcherPlatformMediator:InterestSignals()
	local signals = { 
		"SCRATCHER_COUNT_DOWN"
	}

	return signals
end

function ScratcherPlatformMediator:ProcessSignal( signal )
	local name = signal:GetName() 
	local body = signal:GetBody()
	-- dump(body, name)
	if "SCRATCHER_COUNT_DOWN" == name then
		self.data.countDown = body.countdown
		self:UpdateCountDown(self.data.countDown)
	end
end

function ScratcherPlatformMediator:Initial( key )
	self.super.Initial(self, key)
	local scene = app.uiMgr:GetCurrentScene()
	local viewComponent  = require('Game.views.scratcher.ScratcherPlatformView').new()
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	scene:AddDialog(viewComponent)
    local viewData = viewComponent.viewData
    
	viewData.backBtn:setOnClickScriptHandler(handler(self, self.OnBackBtnClickHandler))
	viewData.leftSpoon:setVisible(false)
	viewData.rightSpoon:setVisible(false)
	viewData.supportTipViewL:setVisible(false)
	viewData.supportTipViewR:setVisible(false)
	viewData.leftSupportBtn:setVisible(false)
	viewData.rightSupportBtn:setVisible(false)

    local cardConf = CommonUtils.GetConfigAllMess('card', 'cards') or {}
	display.commonLabelParams(viewData.leftLayout.nameLabel, {text = cardConf[tostring(self.data.cards[1])].name})
	display.commonLabelParams(viewData.rightLayout.nameLabel, {text = cardConf[tostring(self.data.cards[2])].name})

	viewComponent:setLeftBgImg(self.data.cards[1])
	viewComponent:setRightBgImg(self.data.cards[2])
	viewComponent:ShowEnterAni(handler(self, self.OnAniEnd))
	self:UpdateCountDown(self.data.countDown)
end

function ScratcherPlatformMediator:OnAniEnd(  )
    local viewData = self.viewComponent.viewData
    
    viewData.leftSpoon:setVisible(true)
    viewData.leftSpoon:setOpacity(0)
    viewData.leftSpoon:runAction(cc.FadeIn:create(0.3))
    viewData.rightSpoon:setVisible(true)
    viewData.rightSpoon:setOpacity(0)
    viewData.rightSpoon:runAction(cc.FadeIn:create(0.3))
    viewData.supportTipViewL:setVisible(true)
    viewData.supportTipViewR:setVisible(true)
    viewData.leftSupportBtn:setVisible(true)
    viewData.rightSupportBtn:setVisible(true)
    viewData.leftSupportBtn:setOnClickScriptHandler(handler(self, self.SupportBtnClickHandler))
    viewData.rightSupportBtn:setOnClickScriptHandler(handler(self, self.SupportBtnClickHandler))
	viewData.tipsBtn:setOnClickScriptHandler(handler(self, self.OnTipsBtnClickHandler))
end

function ScratcherPlatformMediator:OnRegist(  )
end

function ScratcherPlatformMediator:OnUnRegist(  )
	local scene = app.uiMgr:GetCurrentScene()
	scene:RemoveGameLayer(self.viewComponent)
end

function ScratcherPlatformMediator:OnBackBtnClickHandler( sender )
	PlayAudioByClickClose()
	
	app.timerMgr:RemoveTimer('scratcher')
    app:UnRegsitMediator(NAME)
end

function ScratcherPlatformMediator:SupportBtnClickHandler( sender )
	PlayAudioByClickNormal()

	if self:IsActivityEnd() then
		app.uiMgr:ShowInformationTips(__('活动已结束'))
		return
	end

	local tag = sender:getTag()
	self.data.myChoice = self.data.cards[tag]
	
	local mediator = require('Game.mediator.scratcher.ScratcherPlayerMediator').new(self.data)
	AppFacade.GetInstance():RegistMediator(mediator)
end

function ScratcherPlatformMediator:OnTipsBtnClickHandler( sender )
    PlayAudioByClickNormal()
    
	app.uiMgr:ShowIntroPopup({moduleId = '-50'})
end

function ScratcherPlatformMediator:UpdateCountDown( countdown )
	local viewData = self.viewComponent.viewData
	if countdown <= 0 then
		viewData.timeLabel:setString(__('已结束'))
	else
		if checkint(countdown) <= 86400 then
			viewData.timeLabel:setString(string.formattedTime(checkint(countdown),'%02i:%02i:%02i'))
		else
			local day = math.floor(checkint(countdown)/86400)
			local hour = math.floor((countdown - day * 86400) / 3600)
			viewData.timeLabel:setString(string.fmt(__('_day_天_hour_小时'),{_day_ = day, _hour_ = hour}))
		end
	end
end

function ScratcherPlatformMediator:IsActivityEnd()
	return self.data.countDown <= 0
end

return ScratcherPlatformMediator
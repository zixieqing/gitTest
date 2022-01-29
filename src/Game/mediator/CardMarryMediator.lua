local Mediator = mvc.Mediator

local CardMarryMediator = class("CardMarryMediator", Mediator)

local NAME = "CardMarryMediator"


--[[
@param cb string 结婚结束后跳转的mediator
--]]
function CardMarryMediator:ctor(param, viewComponent )
	self.super:ctor(NAME,viewComponent)
	self.touchListener = nil
	self.isTouchMovingOut = false
	self.cardData = {}
	self.cb = nil
	self.lastWords = nil
	self.playVoice = false
	if param and checktable(param) then
		self.cardData = param.data or {}
		self.cb = param.cb or nil
		self.lastWords = param.lastWords or nil
	end
end


function CardMarryMediator:InterestSignals()
	local signals = {
	}

	return signals
end

function CardMarryMediator:ProcessSignal(signal )
	local name = signal:GetName()
	-- print(name)
	-- dump(signal:GetBody())
end

function CardMarryMediator:Initial( key )
	self.super.Initial(self,key)
	local scene = app.uiMgr:GetCurrentScene()
	local viewComponent  = require( 'Game.views.CardMarryView' ).new(self.cardData)
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	scene:AddDialog(viewComponent)

	local viewData = self.viewComponent.viewData
	local mainCardNode = viewData.mainCardNode

	if self.cb ~= 'CardMarrySuccessMediator' then
		viewData.backBtn:setVisible(true)
		viewData.backBtn:setOnClickScriptHandler(function(sender)
			if self.cb then
				local desMediator = 'Game.mediator.' .. self.cb
				local mediator = require( desMediator ).new({data = self.cardData})
				AppFacade.GetInstance():RegistMediator(mediator)
			end

			if self.playVoice then
				if self.lastWords.acbFile then
					local cueSheet = self.lastWords.cueSheet
					app.audioMgr:StopAudioClip(cueSheet, true)
				end
				self.playVoice = false
			end

			app.audioMgr:StopAudioClip(AUDIOS.UI.name)
			AppFacade.GetInstance():UnRegsitMediator(NAME)
		end)
	else
		viewData.backBtn:setVisible(false)
	end

	local fazhenSpine = viewData.fazhenSpine
	viewData.fazhenSpine:registerSpineEventHandler(
		function (event)
			if event.animation == 'play2' then
				if self.touchListener then
					PlayAudioClip(AUDIOS.UI.ui_vow_end.id)

					self.viewComponent.viewData.backBtn:setVisible(false)
					
					cc.Director:getInstance():getEventDispatcher():removeEventListener(self.touchListener)
					self.touchListener = nil
					-- mainCardNode:runAction(cc.FadeOut:create(2))
					if self.cb then
						if 'CardContractCompleteMediator' == self.cb then
							local bg = display.newImageView(_res('ui/cards/marry/card_contract_bg_max'), display.cx, display.cy, {isFull = true})
							viewData.view:addChild(bg, -2)
							viewData.bg:runAction(cc.FadeOut:create(1.4))
						end
					end
				end
			elseif event.animation == 'idle' then
				if not self.touchListener then

					PlayAudioClip(AUDIOS.UI.ui_vow_idle.id)
					------------ 初始化触摸 ------------
					local touchListener = cc.EventListenerTouchOneByOne:create()
					touchListener:registerScriptHandler(handler(self, self.onTouchBegan), cc.Handler.EVENT_TOUCH_BEGAN)
					touchListener:registerScriptHandler(handler(self, self.onTouchMoved), cc.Handler.EVENT_TOUCH_MOVED)
					touchListener:registerScriptHandler(handler(self, self.onTouchEnded), cc.Handler.EVENT_TOUCH_ENDED)
					touchListener:registerScriptHandler(handler(self, self.onTouchCanceled), cc.Handler.EVENT_TOUCH_CANCELLED)
					cc.Director:getInstance():getEventDispatcher():addEventListenerWithSceneGraphPriority(touchListener, viewComponent)
					self.touchListener = touchListener
				end
			end
		end,
		sp.EventType.ANIMATION_EVENT
	)
	viewData.fazhenSpine:registerSpineEventHandler(
		function (event)
			if event.animation == 'play2' then
				if self.cb then
					local desMediator = 'Game.mediator.' .. self.cb
					local mediator = require( desMediator ).new({data = self.cardData})
					AppFacade.GetInstance():RegistMediator(mediator)
				end
				AppFacade.GetInstance():UnRegsitMediator(NAME)
			end
		end,
		sp.EventType.ANIMATION_COMPLETE
	)

	local touchGuideLabel = viewData.touchGuideLabel
	local dialogueBG = viewData.dialogueBG
	local dialogLabel = viewData.dialogLabel
	local dialogueLayer = viewData.dialogueLayer

	local duration = self:getSoundTime()

	viewData.mainCardNode:runAction(cc.Sequence:create(
		cc.FadeIn:create(1),
		cc.CallFunc:create(function ()
			if self.lastWords and '0' ~= self.lastWords.dialog then
				dialogueLayer:setOpacity(255)
				dialogLabel:setString(self.lastWords.dialog)
				local descrLabelSize = display.getLabelContentSize(dialogLabel)
				if 210 < descrLabelSize.height then
					dialogLabel:setVisible(false)
					viewData.descrLabel:setString(self.lastWords.dialog)
					viewData.descrLabelLayout:setContentSize(descrLabelSize)
					viewData.descrLabel:setPosition(cc.p(descrLabelSize.width/2 , descrLabelSize.height/2))
					viewData.descrContainer:reloadData()
					viewData.descrContainer:setVisible(true)
					dialogueBG:setScaleY((display.getLabelContentSize(dialogLabel).height + 100) / 207)
				elseif 100 < display.getLabelContentSize(dialogLabel).height then
					dialogueBG:setScaleY((display.getLabelContentSize(dialogLabel).height + 124) / 207)
				end
				dialogueLayer:setScale(0.5)
				dialogueLayer:runAction(
					cc.Sequence:create(
						cc.Show:create(),
						cc.EaseBackOut:create(cc.ScaleTo:create(0.3, 1)),
						cc.CallFunc:create(function ()
							self.playVoice = true
							self:playLastWords()
							viewData.mainCardNode:setClickCallback(handler(self, self.onClickMainCardNodeCallback_))
						end),
						cc.DelayTime:create(duration),
						cc.CallFunc:create(function ()
							self.playVoice = false
						end),
						cc.FadeOut:create(1),
						cc.Hide:create()
					)
				)
			end


			PlayAudioClip(AUDIOS.UI.ui_vow_start.id)
			fazhenSpine:setVisible(true)
			fazhenSpine:setAnimation(0, 'star', false)
			fazhenSpine:setMix("star", "idle", 0.2)
			fazhenSpine:addAnimation(0, "idle", true)
			-- fazhenSpine:setTimeScale(2.0 / 3.0)
			fazhenSpine:update(0)
			fazhenSpine:setToSetupPose()

			touchGuideLabel:runAction(cc.FadeIn:create(1))
		end)
	))
	-- viewData.touchNode:setOnClickScriptHandler(function (sender)
	-- 	self:OathSuccess()
	-- end)
end

function CardMarryMediator:getSoundTime()
	local duration = 2
	if self.lastWords then
		if '0' ~= self.lastWords.dialog then
			local cueSheet = self.lastWords.cueSheet
			local cueName = self.lastWords.cueName
			local acbFile = self.lastWords.acbFile
			-- 获取cue时长
			if acbFile and utils.isExistent(acbFile) then
				app.audioMgr:AddCueSheet(cueSheet, acbFile)
				local time = app.audioMgr:GetPlayerCueTime(cueSheet, cueName)
				if time > 0 then
					duration = time
				end
			end
		end
	end
	return duration
end

function CardMarryMediator:playLastWords()
	if self.lastWords then
		if '0' ~= self.lastWords.dialog then
			local cueSheet = self.lastWords.cueSheet
			local cueName = self.lastWords.cueName
			local acbFile = self.lastWords.acbFile
			-- 播放音频
			if acbFile or utils.isExistent(acbFile) then
				app.audioMgr:AddCueSheet(cueSheet, acbFile)
				app.audioMgr:PlayAudioClip(cueSheet, cueName)
			end
		end
	end
end

function CardMarryMediator:onClickMainCardNodeCallback_(cardId)
	local viewData = self.viewComponent.viewData
	local dialogueLayer = viewData.dialogueLayer
    if not dialogueLayer:isVisible() then
		if self.lastWords and '0' ~= self.lastWords.dialog then
			local duration = self:getSoundTime()
			dialogueLayer:setOpacity(255)
			dialogueLayer:setScale(0.5)
			dialogueLayer:runAction(
				cc.Sequence:create(
					cc.Show:create(),
					cc.EaseBackOut:create(cc.ScaleTo:create(0.3, 1)),
					cc.CallFunc:create(function ()
						self.playVoice = true
						self:playLastWords()
					end),
					cc.DelayTime:create(duration),
					cc.CallFunc:create(function ()
						self.playVoice = false
					end),
					cc.FadeOut:create(1),
					cc.Hide:create()
				)
			)
		end
	end
end

function CardMarryMediator:onTouchBegan(touch, event)
	self.isTouchMovingOut = false
	local touchNode = self.viewComponent.viewData.touchNode
	local pos = touchNode:getParent():convertToNodeSpace(touch:getLocation())
	local boundingBox = touchNode:getBoundingBox()
	if cc.rectContainsPoint(boundingBox, pos) then
		if self.playVoice then
			if self.lastWords.acbFile then
				local cueSheet = self.lastWords.cueSheet
				app.audioMgr:StopAudioClip(cueSheet, true)
			end
			self.playVoice = false
		end
		self.viewComponent.viewData.dialogueLayer:setVisible(false)
		self.viewComponent.viewData.dialogueLayer:stopAllActions()

		PlayAudioClip(AUDIOS.UI.stop_ui_vow_idle.id)

		local fazhenSpine = self.viewComponent.viewData.fazhenSpine
		fazhenSpine:setAnimation(0, 'play1', false)
		fazhenSpine:setMix("play1", "play2", 0.2)
		fazhenSpine:addAnimation(0, "play2", false)
		fazhenSpine:update(0)
		fazhenSpine:setToSetupPose()

		local touchGuideLabel = self.viewComponent.viewData.touchGuideLabel
		touchGuideLabel:setVisible(false)

		local mainCardNode = self.viewComponent.viewData.mainCardNode
		mainCardNode:runAction(cc.FadeOut:create(3))
		-- mainCardNode:runAction(cc.TintTo:create(4, 0, 0, 0))
		return true
	end

	return false
end

function CardMarryMediator:onTouchMoved(touch, event)
	if not self.isTouchMovingOut then
		local touchNode = self.viewComponent.viewData.touchNode
		local pos = touchNode:getParent():convertToNodeSpace(touch:getLocation())
		local boundingBox = touchNode:getBoundingBox()
		if cc.rectContainsPoint(boundingBox, pos) then
		else
			self.isTouchMovingOut = true
			local fazhenSpine = self.viewComponent.viewData.fazhenSpine
			if 'play2' ~= fazhenSpine:getCurrent() then
				fazhenSpine:setAnimation(0, "idle", true)
				fazhenSpine:update(0)
				fazhenSpine:setToSetupPose()

				local touchGuideLabel = self.viewComponent.viewData.touchGuideLabel
				touchGuideLabel:setVisible(true)

				local mainCardNode = self.viewComponent.viewData.mainCardNode
				mainCardNode:stopAllActions()
				mainCardNode:setOpacity(255)
				mainCardNode:setColor(cc.c3b(255, 255, 255))

				app.audioMgr:StopAudioClip(AUDIOS.UI.name)
				PlayAudioClip(AUDIOS.UI.ui_vow_idle.id)
			end
		end
	end
end

function CardMarryMediator:onTouchEnded(touch, event)
	if self.isTouchMovingOut then
	else
		local fazhenSpine = self.viewComponent.viewData.fazhenSpine
		if 'play2' ~= fazhenSpine:getCurrent() then
			fazhenSpine:setAnimation(0, "idle", true)
			fazhenSpine:update(0)
			fazhenSpine:setToSetupPose()

			local touchGuideLabel = self.viewComponent.viewData.touchGuideLabel
			touchGuideLabel:setVisible(true)

			local mainCardNode = self.viewComponent.viewData.mainCardNode
			mainCardNode:stopAllActions()
			mainCardNode:setOpacity(255)
			mainCardNode:setColor(cc.c3b(255, 255, 255))

			app.audioMgr:StopAudioClip(AUDIOS.UI.name)
			PlayAudioClip(AUDIOS.UI.ui_vow_idle.id)
		end
	end
end

function CardMarryMediator:onTouchCanceled(touch, event)
	self:onTouchEnded(touch, event)
end

function CardMarryMediator:OnRegist(  )
end

function CardMarryMediator:OnUnRegist(  )
	local scene = app.uiMgr:GetCurrentScene()
	scene:RemoveGameLayer(self.viewComponent)
end

return CardMarryMediator

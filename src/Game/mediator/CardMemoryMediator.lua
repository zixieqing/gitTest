local Mediator = mvc.Mediator

local CardMemoryMediator = class("CardMemoryMediator", Mediator)

local NAME = "CardMemoryMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")

--[[
@param cb string 结婚结束后跳转的mediator
--]]
function CardMemoryMediator:ctor(param, viewComponent )
	self.super:ctor(NAME,viewComponent)
	self.cardData = {}
	self.cb = nil
	self.LastWords = nil
	if param and checktable(param) then
		self.cardData = param.data or {}
		self.cb = param.cb or nil
	end
end


function CardMemoryMediator:InterestSignals()
	local signals = {
	}

	return signals
end

function CardMemoryMediator:ProcessSignal(signal )
	local name = signal:GetName()
	-- print(name)
	-- dump(signal:GetBody())
end

function CardMemoryMediator:Initial( key )
	self.super.Initial(self,key)
	local scene = uiMgr:GetCurrentScene()
	local viewComponent = require('Game.views.CardMemoryView').new(self.cardData)
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	scene:AddDialog(viewComponent)

	local viewData = viewComponent.viewData
	-- viewData.endBtn:setOnClickScriptHandler(function(sender)
	-- 	PlayAudioByClickNormal()
	-- 	local mediator = require( 'Game.mediator.CardMarryMediator' ).new({data = self.cardData, cb = self.cb})
	-- 	AppFacade.GetInstance():RegistMediator(mediator)

	-- 	AppFacade.GetInstance():UnRegsitMediator(NAME)
	-- end)

	if self.cb ~= 'CardMarrySuccessMediator' then
		viewData.backBtn:setVisible(true)
		viewData.backBtn:setOnClickScriptHandler(function(sender)
			PlayAudioByClickClose()

			for k, v in pairs(viewComponent.updateHandler) do
				if v then
					scheduler.unscheduleGlobal(v)
				end
			end

			if viewComponent.cueSheet then
				app.audioMgr:StopAudioClip(viewComponent.cueSheet, true)
			end

			if self.cb then
				local desMediator = 'Game.mediator.' .. self.cb
				local mediator = require( desMediator ).new({data = self.cardData})
				AppFacade.GetInstance():RegistMediator(mediator)
			end

			AppFacade.GetInstance():UnRegsitMediator(NAME)
		end)

		viewData.headset:setVisible(false)
		viewData.playerTipsLabel:setVisible(false)
	else
		viewData.backBtn:setVisible(false)
		viewComponent:runAction(cc.Sequence:create(
			cc.DelayTime:create(10),
			cc.CallFunc:create(function ()
				viewData.headset:runAction(cc.FadeOut:create(1))
				viewData.playerTipsLabel:runAction(cc.FadeOut:create(1))
			end)
		))
	end

	local startSpine = viewData.startSpine
	startSpine:registerSpineEventHandler(
		function (event)
			if event.animation == 'star' then
				startSpine:setAnimation(0, 'idle', true)
				utils.newrandomseed()
				self:StartAnimation(1)
				end
		end,
		sp.EventType.ANIMATION_COMPLETE
	)

	local chairWordsData = CommonUtils.GetConfigAllMess('favorabilityGuide', 'card')
	local words = {}
	for k, v in pairs(chairWordsData) do
		local name = CommonUtils.GetConfig('cards', 'card', gameMgr:GetCardDataById(self.cardData.id).cardId).name
		words[k] = string.fmt(v.words, {_target_id_ = name})
	end
	viewComponent:PreLoadLabel(words, self.cb == 'CardMarrySuccessMediator')

end

function CardMemoryMediator:StartAnimation(cur)
	local viewComponent = self:GetViewComponent()
	local voiceData = CommonUtils.GetConfigNoParser('card', 'favorabilityAnimationVoice', tostring(self.cardData.cardId))
	if not next(voiceData) then
		voiceData = CommonUtils.GetConfigNoParser('card', 'favorabilityAnimationVoice', '200021')
	end
	local stageData = CommonUtils.GetConfigAllMess('favorabilityAnimationMoment', 'card')
	local chairWordsData = CommonUtils.GetConfigAllMess('favorabilityGuide', 'card')

	local lastChairID = 0
	local intervalTime = 0
	viewComponent:ShowStageText(stageData[tostring(cur)].moments)
	for k, v in pairs(voiceData[tostring(cur)]) do
		if lastChairID ~= chairWordsData[v.words].id then
			-- local chairWords = chairWordsData[v.words].words
			intervalTime = viewComponent:ShowChairWords(
				v.words,
				2,
				intervalTime
			) + intervalTime

			-- intervalTime = intervalTime - 0.4
			lastChairID = chairWordsData[v.words].id
		end
		
		local dialog = v.desk_cn
		local cueSheet = v.roleId_cn
		local cueName = v.voiceCode_cn
		local acbFile = nil
		if PLAY_VOICE_TYPE.JAPANESE == app.audioMgr:GetVoiceType() then
			dialog = v.desk_jp
			cueSheet = v.roleId_jp
			cueName = v.voiceCode_jp
			if '0' ~= cueSheet then
				acbFile = app.audioMgr:GetVoicePathByName(cueSheet, PLAY_VOICE_TYPE.JAPANESE)
			end
		else
			cueName = v.voiceCode_jp
			if '0' ~= cueSheet then
				acbFile = app.audioMgr:GetVoicePathByName(cueSheet, PLAY_VOICE_TYPE.CHINESE)
			end
		end
		if '0' ~= dialog and '6' ~= v.words then
			if 0 > intervalTime then
				intervalTime = 0
			end
			local designSize = cc.size(1334, 750)
			local contentSize = cc.size(628, 207)
			local minX = 38 + display.SAFE_L
			local maxX = display.width - 30 - contentSize.width
			local minY = 0
			local maxY = display.height - 31 - contentSize.height
			local posX = math.random() * (maxX - minX) + minX
			local posY = math.random() * (maxY - minY) + minY
			intervalTime = intervalTime + viewComponent:ShowDialog(dialog, intervalTime, cc.p(posX,posY), cueSheet, cueName, acbFile)
		end
		if '6' == v.words then
			self.LastWords = {dialog = dialog, cueSheet = cueSheet, cueName = cueName, acbFile = acbFile}
		end
	end

	viewComponent:runAction(cc.Sequence:create(
		cc.DelayTime:create(intervalTime),
		cc.CallFunc:create(function ()
			viewComponent:HideStageText(1)
		end)
	))
	if table.nums(voiceData) > cur then
		viewComponent:runAction(cc.Sequence:create(
			cc.DelayTime:create(intervalTime + 1),
			cc.CallFunc:create(function ()
				self:StartAnimation(cur + 1)
			end)
		))
	else
		viewComponent:runAction(cc.Sequence:create(
			cc.DelayTime:create(intervalTime + 1),
			cc.CallFunc:create(function ()
				local mediator = require( 'Game.mediator.CardMarryMediator' ).new({data = self.cardData, cb = self.cb, lastWords = self.LastWords})
				AppFacade.GetInstance():RegistMediator(mediator)

				AppFacade.GetInstance():UnRegsitMediator(NAME)
			end)
		))
	end
end

function CardMemoryMediator:OnRegist(  )
	PlayBGMusic(AUDIOS.BGM.Food_Vow.id)
end

function CardMemoryMediator:OnUnRegist(  )
	local scene = uiMgr:GetCurrentScene()
	scene:RemoveGameLayer(self.viewComponent)
end

return CardMemoryMediator

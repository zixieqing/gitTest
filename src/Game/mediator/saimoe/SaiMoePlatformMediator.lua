--[[
    燃战擂台Mediator
--]]
local Mediator = mvc.Mediator
---@class SaiMoePlatformMediator:Mediator
local SaiMoePlatformMediator = class("SaiMoePlatformMediator", Mediator)

local NAME = "SaiMoePlatformMediator"

local shareFacade = AppFacade.GetInstance()
local uiMgr = shareFacade:GetManager("UIManager")
local gameMgr = shareFacade:GetManager("GameManager")
local socketMgr = shareFacade:GetManager('SocketManager')
local cardMgr = shareFacade:GetManager("CardManager")
local timerMgr = shareFacade:GetManager("TimerManager")
local scheduler = require('cocos.framework.scheduler')

function SaiMoePlatformMediator:ctor( params, viewComponent )
	self.super:ctor(NAME,viewComponent)
	self.datas = checktable(params) or {}
end

function SaiMoePlatformMediator:InterestSignals()
	local signals = { 
        COUNT_DOWN_ACTION,
	}

	return signals
end

function SaiMoePlatformMediator:ProcessSignal( signal )
	local name = signal:GetName() 
	local body = signal:GetBody()
	-- dump(body, name)
	if name == COUNT_DOWN_ACTION then
		local timerName = body.timerName
        if timerName == 'SAIMOE' then
			self:UpdateCountDown(body.countdown)
        end
	end
end

function SaiMoePlatformMediator:Initial( key )
	self.super.Initial(self, key)
	local scene = uiMgr:GetCurrentScene()
	local viewComponent  = require('Game.views.saimoe.SaiMoePlatformView').new()
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	scene:AddDialog(viewComponent)
	local viewData = viewComponent.viewData
	self:UpdateCountDown(gameMgr:GetUserInfo().comparisonActivityTime)
	local playerConf = CommonUtils.GetConfigAllMess('comparisonInfo', 'cardComparison')
	
	viewData.leftSupportBtn:setVisible(false)
	viewData.rightSupportBtn:setVisible(false)
	viewData.leftSpoon:setVisible(false)
	viewData.rightSpoon:setVisible(false)
	viewData.supportTipViewL:setVisible(false)
	viewData.supportTipViewR:setVisible(false)
	viewData.previewBtn:setVisible(false)
	viewData.rankingBtn:setOnClickScriptHandler(handler(self, self.RankingBtnClickHandle))

	viewData.tipsBtn:setOnClickScriptHandler(function( sender )
		PlayAudioClip(AUDIOS.UI.ui_window_open.id)

		uiMgr:ShowIntroPopup({moduleId = INTRODUCE_MODULE_ID.SAIMOE_MAIN})
	end)

	display.commonLabelParams(viewData.leftLayout.nameLabel, {text = playerConf['1'].message})
	display.commonLabelParams(viewData.rightLayout.nameLabel, {text = playerConf['2'].message})

	viewData.leftLayout.votesLabel:setString(self.datas.groupScore[tostring(1)] or 0)
	viewData.rightLayout.votesLabel:setString(self.datas.groupScore[tostring(2)] or 0)

	viewData.leftLayout.peopleLabel:setString(self.datas.groupSupportNum[tostring(1)] or 0)
	viewData.rightLayout.peopleLabel:setString(self.datas.groupSupportNum[tostring(2)] or 0)

	viewData.leftLayout.interviewBtn:setOnClickScriptHandler(handler(self, self.InterviewBtnClickHandler))
	viewData.rightLayout.interviewBtn:setOnClickScriptHandler(handler(self, self.InterviewBtnClickHandler))

	viewComponent:ShowEnterAni(handler(self, self.OnAniEnd))
end

function SaiMoePlatformMediator:RankingBtnClickHandle(sender)
	PlayAudioByClickNormal()

	shareFacade:RetrieveMediator("Router"):Dispatch({name = 'HomeMediator'}, {name = 'saimoe.SaiMoeRankMediator'})
end

function SaiMoePlatformMediator:SupportBtnClickHandler( sender )
	PlayAudioByClickNormal()
	
	if gameMgr:GetUserInfo().comparisonActivityTime <= 0 then
        uiMgr:ShowInformationTips(__('活动已结束'))
        return
	end
	
	local tag = sender:getTag()
	self.datas.supportGroupId = tag
	local SaiMoePlayerMediator = require( 'Game.mediator.saimoe.SaiMoePlayerMediator')
	local mediator = SaiMoePlayerMediator.new(self.datas)
	self:GetFacade():RegistMediator(mediator)
end

function SaiMoePlatformMediator:InterviewBtnClickHandler( sender )
	PlayAudioByClickNormal()
	local viewData = self.viewComponent.viewData

	local tag = sender:getTag()
	local interviewBtnSpine
	if 1 == tag then
		interviewBtnSpine = viewData.leftLayout.interviewBtnSpine
	else
		interviewBtnSpine = viewData.rightLayout.interviewBtnSpine
	end
	interviewBtnSpine:setAnimation(0, 'attack', false)
	interviewBtnSpine:addAnimation(0, 'idle', true)
	local callback = function ()
	end
	local path = string.format("conf/%s/cardComparison/comparisonStory.json",i18n.getLang())
	local stage = require( "Frame.Opera.OperaStage" ).new({id = tag+1, path = path, guide = true, isHideBackBtn = true, cb = callback})
	stage:setPosition(cc.p(display.cx,display.cy))
	sceneWorld:addChild(stage, GameSceneTag.Dialog_GameSceneTag)
end

function SaiMoePlatformMediator:UpdateCountDown( countdown )
	local viewData = self.viewComponent.viewData
	if countdown <= 0 then
		--viewData.timeLabel:setString(__('已结束'))
		display.reloadRichLabel(viewData.timeLabel , {c= {
			{
			    text = __('已结束：'),
			    ap = display.RIGHT_CENTER,
			    fontSize = 28,
			    color = '#ffd042',
			}
		}})
	else
		if checkint(countdown) <= 86400 then
			display.reloadRichLabel(viewData.timeLabel , {c= {
				{
				    text = __('比赛剩余时间：'),
				    ap = display.RIGHT_CENTER,
				    fontSize = 22,
				    color = '#ffffff',
				}
				,{
					text = string.formattedTime(checkint(countdown),'%02i:%02i:%02i'),
					ap = display.RIGHT_CENTER,
					fontSize = 28,
					color = '#ffd042',
				}
			}})
			--viewData.timeLabel:setString(string.formattedTime(checkint(countdown),'%02i:%02i:%02i'))
		else
			local day = math.floor(checkint(countdown)/86400)
			local hour = math.floor((countdown - day * 86400) / 3600)
			display.reloadRichLabel(viewData.timeLabel , {c= {
				{
					text = __('比赛剩余时间：'),
					ap = display.RIGHT_CENTER,
					fontSize = 22,
					color = '#ffffff',
				}
			,{
					text = string.fmt(__('_day_天_hour_小时'),{_day_ = day, _hour_ = hour}),
					ap = display.RIGHT_CENTER,
					fontSize = 28,
					color = '#ffd042',
				}
			}})
			--viewData.timeLabel:setString(string.fmt(__('_day_天_hour_小时'),{_day_ = day, _hour_ = hour}))
		end
		CommonUtils.SetNodeScale(viewData.timeLabel, {width = 350 })
	end
end

function SaiMoePlatformMediator:OnAniEnd(  )
	local viewData = self.viewComponent.viewData
	local playerConf = CommonUtils.GetConfigAllMess('comparisonInfo', 'cardComparison')
	if self.datas.supportGroupId then
		viewData.previewBtn:setVisible(true)
		viewData.previewBtn:setOnClickScriptHandler(function ( sender )
			PlayAudioByClickNormal()

            uiMgr:ShowInformationTipsBoard({targetNode = sender, iconIds = playerConf[tostring(self.datas.supportGroupId)].rewards, type = 4 , goodAddHeight = 18 })
		end)

		viewData.leftSpoon:setVisible(false)
		viewData.rightSpoon:setVisible(false)
		viewData.leftSupportBtn:setVisible(false)
		viewData.rightSupportBtn:setVisible(false)
		viewData.supportTipViewL:setVisible(false)
		viewData.supportTipViewR:setVisible(false)
	else	
		viewData.previewBtn:setVisible(false)

		viewData.leftSpoon:setVisible(true)
		viewData.leftSpoon:setOpacity(0)
		viewData.leftSpoon:runAction(cc.FadeIn:create(0.3))
		viewData.rightSpoon:setVisible(true)
		viewData.rightSpoon:setOpacity(0)
		viewData.rightSpoon:runAction(cc.FadeIn:create(0.3))
		viewData.leftSupportBtn:setVisible(true)
		viewData.rightSupportBtn:setVisible(true)
		viewData.supportTipViewL:setVisible(true)
		viewData.supportTipViewR:setVisible(true)
		viewData.leftSupportBtn:setOnClickScriptHandler(handler(self, self.SupportBtnClickHandler))
		viewData.rightSupportBtn:setOnClickScriptHandler(handler(self, self.SupportBtnClickHandler))
	end
end

function SaiMoePlatformMediator:OnRegist(  )
end

function SaiMoePlatformMediator:OnUnRegist(  )
	local scene = uiMgr:GetCurrentScene()
	scene:RemoveGameLayer(self.viewComponent)
end

return SaiMoePlatformMediator
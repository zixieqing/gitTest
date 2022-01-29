--[[
    燃战角色详情Mediator
--]]
local Mediator = mvc.Mediator
---@class SaiMoePlayerMediator:Mediator
local SaiMoePlayerMediator = class("SaiMoePlayerMediator", Mediator)

local NAME = "SaiMoePlayerMediator"

local shareFacade = AppFacade.GetInstance()
local uiMgr = shareFacade:GetManager("UIManager")
local gameMgr = shareFacade:GetManager("GameManager")
local socketMgr = shareFacade:GetManager('SocketManager')
local cardMgr = shareFacade:GetManager("CardManager")
local timerMgr = shareFacade:GetManager("TimerManager")
local scheduler = require('cocos.framework.scheduler')

function SaiMoePlayerMediator:ctor( params, viewComponent )
	self.super:ctor(NAME,viewComponent)
	self.datas = checktable(params) or {}
end

function SaiMoePlayerMediator:InterestSignals()
	local signals = { 
        POST.SAIMOE_SUPPORT.sglName ,
	}

	return signals
end

function SaiMoePlayerMediator:ProcessSignal( signal )
	local name = signal:GetName() 
	local body = signal:GetBody()
	-- dump(body, name)
	if name == POST.SAIMOE_SUPPORT.sglName then
		self.datas.groupSupportNum[tostring(self.datas.supportGroupId)] = checkint(self.datas.groupSupportNum[tostring(self.datas.supportGroupId)]) + 1
		local callback = function ()
			local SaiMoeSupportMediator = require( 'Game.mediator.saimoe.SaiMoeSupportMediator')
			local mediator = SaiMoeSupportMediator.new(self.datas)
			self:GetFacade():RegistMediator(mediator)

			shareFacade:UnRegsitMediator("SaiMoePlayerMediator")
			shareFacade:UnRegsitMediator("SaiMoePlatformMediator")
		end
		local path = string.format("conf/%s/cardComparison/comparisonStory.json",i18n.getLang())
		local stage = require( "Frame.Opera.OperaStage" ).new({id = self.datas.supportGroupId+3, path = path, guide = true, isHideBackBtn = true, cb = callback})
		stage:setPosition(cc.p(display.cx,display.cy))
		sceneWorld:addChild(stage, GameSceneTag.Dialog_GameSceneTag)
	end
end

function SaiMoePlayerMediator:Initial( key )
	self.super.Initial(self, key)
	local scene = uiMgr:GetCurrentScene()
	local viewComponent  = require('Game.views.saimoe.SaiMoePlayerView').new()
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	scene:AddDialog(viewComponent)
	local viewData = viewComponent.viewData
	
	local supportGroupId = self.datas.supportGroupId
	local playerConf = CommonUtils.GetConfigAllMess('comparisonInfo', 'cardComparison')[tostring(supportGroupId)]
    viewData.drawNode:RefreshAvatar({ skinId = CardUtils.GetCardSkinId(playerConf.cardId) })
	-- viewData.drawNode:RefreshAvatar(playerConf)
	local count = table.nums(playerConf.rewards)
	for i,v in ipairs(playerConf.rewards) do
		local goodsIcon = require('common.GoodNode').new({id = v.goodsId, amount = v.num, showAmount = true})
		goodsIcon:setPosition(cc.p(289 - (count-1)/2*134 + (i-1)*134, 251))
		viewData.rightView:addChild(goodsIcon)
		display.commonUIParams(goodsIcon, {animate = false, cb = function (sender)
			uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = v.goodsId, type = 1})
		end})
	end

	for i,v in ipairs(playerConf.cookBook) do
		local goodsIcon = require('common.GoodNode').new({id = v, showAmount = false})
		goodsIcon:setPosition(cc.p(289 - (count-1)/2*134 + (i-1)*134, 493))
		viewData.rightView:addChild(goodsIcon)
		display.commonUIParams(goodsIcon, {animate = false, cb = function (sender)
			uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = v, type = 1})
		end})
	end

	viewData.supportBtn:setOnClickScriptHandler(handler(self, self.SupportBtnClickHandler))
end

function SaiMoePlayerMediator:SupportBtnClickHandler( sender )
	PlayAudioByClickNormal()
	
	self:SendSignal(POST.SAIMOE_SUPPORT.cmdName,{groupId = checkint(self.datas.supportGroupId)})
end

function SaiMoePlayerMediator:OnRegist(  )
    regPost(POST.SAIMOE_SUPPORT)
end

function SaiMoePlayerMediator:OnUnRegist(  )
	unregPost(POST.SAIMOE_SUPPORT)
	local scene = uiMgr:GetCurrentScene()
	scene:RemoveGameLayer(self.viewComponent)
end

return SaiMoePlayerMediator
--[[
公告系统Mediator
--]]
local Mediator = mvc.Mediator
---@class NoticeMediator :Mediator
local NoticeMediator = class("NoticeMediator", Mediator)

local NAME = "NoticeMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance('AppFacade'):GetManager("GameManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")

function NoticeMediator:ctor( params, viewComponent )
	self.super:ctor(NAME,viewComponent)
	self.args = checktable(params) or {}
	self.showLayer = {} 
	self.rightClickTag = checkint(self.args.noticeType or NoticeType.MAIL)  --右边好友列表tag
	if checkint(NoticeType.ANNOUNCEMENT) == self.rightClickTag then
		if not CommonUtils.GetModuleAvailable(MODULE_SWITCH.ANNOUNCE) then
			self.rightClickTag = checkint(NoticeType.MAIL)
		end
	end
end
function NoticeMediator:InterestSignals()
	local signals = { 
	}

	return signals
end
function NoticeMediator:ProcessSignal( signal )
	local name = signal:GetName() 
	print(name)
	-- if name == SIGNALNAMES.Friend_List_Callback then
	-- end
end
function NoticeMediator:Initial( key )
	self.super.Initial(self,key)
	local scene = uiMgr:GetCurrentScene()
	local viewComponent  = require( 'Game.views.NoticeView' ).new()
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	scene:AddGameLayer(viewComponent)
	--绑定相关的事件
	local viewData = viewComponent.viewData_
	for k, v in pairs( viewData.buttons ) do
		v:setOnClickScriptHandler(handler(self,self.RightButtonActions))
	end
	self:RightButtonActions(self.rightClickTag)	
end
--[[
右边不同类型model按钮的事件处理逻辑
@param sender button对象
--]]
function NoticeMediator:RightButtonActions( sender )
	local tag = 0
	local temp_data = {}
	if type(sender) == 'number' then
		tag = sender
	else
		tag = sender:getTag()
		PlayAudioClip(AUDIOS.UI.ui_depot_tabchange.id)
		if self.rightClickTag == tag then
			return
		end
	end
	
	local viewData = self:GetViewComponent().viewData_
	for k, v in pairs( viewData.buttons ) do
		local curTag = v:getTag()
		if tag == curTag then
			v:setChecked(true)
			v:setEnabled(false)
			v:getChildByName('title'):setColor(cc.c3b(233, 73, 26))
		else
			v:setChecked(false)
			v:setEnabled(true)
			v:getChildByName('title'):setColor(cc.c3b(92, 92, 92))
		end
	end

	local prePanel = self.showLayer[tostring(self.rightClickTag)]
	if prePanel then
		prePanel:setVisible(false)
	end

	self.rightClickTag = tag
	local viewData = self.viewComponent.viewData_
	local modelLayout = viewData.modelLayout
	local modelSize = modelLayout:getContentSize()
	if tag == NoticeType.MAIL then -- 邮箱
		if self.showLayer[tostring(tag)] then
			self.showLayer[tostring(tag)]:setVisible(true)
		else
			local MailMediator = require( 'Game.mediator.MailMediator')
			local mediator = MailMediator.new()
			self:GetFacade():RegistMediator(mediator)
	    	modelLayout:addChild(mediator:GetViewComponent())
	    	mediator:GetViewComponent():setAnchorPoint(cc.p(0,0))
			mediator:GetViewComponent():setPosition(cc.p(0,0))
			self.showLayer[tostring(tag)] = mediator:GetViewComponent()
		end
	elseif tag == NoticeType.ANNOUNCEMENT then -- 公告
		if self.showLayer[tostring(tag)] then
			self.showLayer[tostring(tag)]:setVisible(true)
		else
			local AnnouncementMediator = require( 'Game.mediator.AnnouncementMediator' )
			local mediator = AnnouncementMediator.new()
			self:GetFacade():RegistMediator(mediator)
	    	modelLayout:addChild(mediator:GetViewComponent())
	    	mediator:GetViewComponent():setAnchorPoint(cc.p(0,0))
			mediator:GetViewComponent():setPosition(cc.p(0,0))
			self.showLayer[tostring(tag)] = mediator:GetViewComponent() -- mediator:GetViewComponent()
		end
	elseif tag == NoticeType.COLLECTION then -- 收藏
		if self.showLayer[tostring(tag)] then
			self.showLayer[tostring(tag)]:setVisible(true)
			self:SendSignal(POST.PRIZE_ENTER_COLLECT.cmdName , {})
		else
			local MailMediator = require( 'Game.mediator.MailCollectionMediator')
			local mediator = MailMediator.new()
			self:GetFacade():RegistMediator(mediator)
			modelLayout:addChild(mediator:GetViewComponent())
			mediator:GetViewComponent():setAnchorPoint(cc.p(0,0))
			mediator:GetViewComponent():setPosition(cc.p(0,0))
			self.showLayer[tostring(tag)] = mediator:GetViewComponent()
		end
	end
end

function NoticeMediator:OnRegist(  )
	local FriendCommand = require('Game.command.FriendCommand')
	self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "allhide")
end

function NoticeMediator:OnUnRegist(  )
	local scene = uiMgr:GetCurrentScene()
	scene:RemoveGameLayer(self.viewComponent)
	self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "hide")
	AppFacade.GetInstance():UnRegsitMediator('MailMediator')
	AppFacade.GetInstance():UnRegsitMediator('AnnouncementMediator')
end

return NoticeMediator
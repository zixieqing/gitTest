--[[
市场功能Mediator
--]]
local Mediator = mvc.Mediator

local MarketMediator = class("MarketMediator", Mediator)

local NAME = "MarketMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance('AppFacade'):GetManager("GameManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
function MarketMediator:ctor( viewComponent )
	self.super:ctor(NAME,viewComponent)
	self.selectTabTag  = 1001 -- 选中页签的tag
	self.showLayer     = {} -- 页签对应的页面
end

function MarketMediator:InterestSignals()
	local signals = {
		SIGNALNAMES.Market_Close_Callback,
	}
	return signals
end

function MarketMediator:ProcessSignal( signal )
	local name = signal:GetName()
	print(name)
	if name == SIGNALNAMES.Market_Close_Callback then -- 关闭市场
	end
end


function MarketMediator:Initial( key )
	self.super.Initial(self,key)
	local viewComponent  = require( 'Game.views.MarketView' ).new()
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	local scene = uiMgr:GetCurrentScene()
	scene:AddDialog(viewComponent)
	-- 绑定相关事件
	local viewData = viewComponent.viewData_
	for k, v in pairs( viewData.buttons ) do
		v:setOnClickScriptHandler(handler(self,self.TabsActions))
	end
	self:TabsActions(self.selectTabTag)
end

--[[
右侧页签点击事件回调
@param sender button对象
--]]
function MarketMediator:TabsActions( sender )
	local tag = 0
	if type(sender) == 'number' then
		tag = sender
	else
		tag = sender:getTag()
		-- 添加点击音效
		PlayAudioClip(AUDIOS.UI.ui_depot_tabchange.id) 
		if self.selectTabTag == tag then
			return
		end
	end

	local viewData = self:GetViewComponent().viewData_
	for k, v in pairs( viewData.buttons ) do
		local curTag = v:getTag()
		if tag == curTag then
			v:setChecked(true)
			v:setEnabled(false)
		else
			v:setChecked(false)
			v:setEnabled(true)
		end
	end

	local viewData = self.viewComponent.viewData_
	local modelLayout = viewData.modelLayout

	viewData.tabNameLabels[tostring(self.selectTabTag)]:setColor(cc.c3b(43, 32, 23))

	local prePanel = self.showLayer[tostring(self.selectTabTag)]
	if prePanel then
		prePanel:setVisible(false)
	end

	self.selectTabTag = tag



	local function switchLayer ( tag, mediatorName )
		viewData.tabNameLabels[tostring(tag)]:setColor(cc.c3b(233, 73, 26))
		if self.showLayer[tostring(tag)] then
			if tag == 1002 then
				local mediator = AppFacade.GetInstance():RetrieveMediator(mediatorName)
				mediator:SwitchLayerUpdate()
			elseif tag == 1003 then
				local mediator = AppFacade.GetInstance():RetrieveMediator(mediatorName)
				mediator:SwitchLayerUpdate()
			end
			self.showLayer[tostring(tag)]:setVisible(true)
		else
			local selectMediator = require( 'Game.mediator.' .. mediatorName)
			local mediator = selectMediator.new()
			self:GetFacade():RegistMediator(mediator)
	    	modelLayout:addChild(mediator:GetViewComponent())
	    	mediator:GetViewComponent():setAnchorPoint(cc.p(0, 0))
			mediator:GetViewComponent():setPosition(cc.p(0, 0))
			self.showLayer[tostring(tag)] = mediator:GetViewComponent()
		end
	end
	if tag == 1001 then -- 购买页面
		switchLayer(tag, 'MarketPurchaseMediator')
	elseif tag == 1002 then -- 出售页面
		switchLayer(tag, 'MarketSaleMediator')
	elseif tag == 1003 then -- 售后页面
		switchLayer(tag, 'MarketRecordMediator')
	end
end
function MarketMediator:OnRegist(  )
	local MarketCommand = require('Game.command.MarketCommand')
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Market_Close, MarketCommand)
    --引导的下一步的逻辑
    GuideUtils.DispatchStepEvent()
end

function MarketMediator:OnUnRegist(  )
	self:SendSignal(COMMANDS.COMMAND_Market_Close)
	self:GetFacade():UnRegsitMediator("MarketPurchaseMediator")
    self:GetFacade():UnRegsitMediator("MarketRecordMediator")
    self:GetFacade():UnRegsitMediator("MarketSaleMediator")
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Market_Close)
	local scene = uiMgr:GetCurrentScene()
	scene:RemoveGameLayer(self.viewComponent)

end
return MarketMediator

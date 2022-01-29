--[[
抽卡动画mediator
--]]
local Mediator = mvc.Mediator
---@class PrivateMediator : Mediator
local PrivateMediator = class("PrivateMediator", Mediator)
---@type UIManager
local uiMgr = app.uiMgr
local NAME = "PrivateMediator"
---@type TakeawayManager
local takeawayInstance = AppFacade.GetInstance():GetManager('TakeawayManager')
function PrivateMediator:ctor( params, viewComponent )
	self.super:ctor(NAME, viewComponent)
	local orderDatas = app.takeawayMgr.orderDatas
	local privateOrder = orderDatas.privateOrder or {}
	self.privateOrder = self:GetOrderData(privateOrder)
end

function PrivateMediator:InterestSignals()
	local signals = {
		FRESH_TAKEAWAY_POINTS ,
		FRESH_TAKEAWAY_ORDER_POINTS
	}
	return signals
end

function PrivateMediator:ProcessSignal( signal )
	local name = signal:GetName()
	if FRESH_TAKEAWAY_POINTS == name  or FRESH_TAKEAWAY_ORDER_POINTS == name  then
		local orderDatas = app.takeawayMgr.orderDatas
		local privateOrder = orderDatas.privateOrder or {}
		self.privateOrder = self:GetOrderData(privateOrder)
		self:ReloadData()
	end
end

function PrivateMediator:GetOrderData(privateOrder)
	local noDistributionOrder = {}
	for i, v in pairs(privateOrder) do
		if checkint(v.status) == 1 then
			noDistributionOrder[#noDistributionOrder+1] = v
		end
	end
	return noDistributionOrder
end

function PrivateMediator:Initial( key )
	self.super.Initial(self, key)
	---@type PrivateOrderView
	local PrivateOrderView = require("Game.views.order.PrivateOrderView").new()
	self.viewComponent = PrivateOrderView
	---@type OrderMediator
	local mediator = AppFacade.GetInstance():RetrieveMediator("OrderMediator")
	---@type OrderView
	local orderView = mediator:GetViewComponent()
	orderView.viewData.bgLayer:addChild(PrivateOrderView)
	PrivateOrderView.viewData.gridView:setDataSourceAdapterScriptHandler(handler(self, self.PriDataSource))
	self:ReloadData()
	self:EnterAction()
end

function PrivateMediator:ReloadData()
	---@type PrivateOrderView
	local viewComponent = self:GetViewComponent()
	local viewData = viewComponent.viewData
	viewData.gridView:setCountOfCell(table.nums(self.privateOrder))
	viewData.gridView:reloadData()

	if table.nums(self.privateOrder) == 0 then
		if viewData.lrightLayout then
			viewData.lrightLayout:setVisible(true)
		else
			viewComponent:CreateLFuturesEmpty()
		end
	else
		if viewData.lrightLayout then
			viewData.lrightLayout:setVisible(false)
		end
	end
end
function PrivateMediator:PriDataSource(p_convertview, idx )
	local index = idx +1
	---@type OrderCell
	local pcell = p_convertview
	xTry(function ()
		if not  pcell then
			pcell = require("Game.views.order.OrderCell").new()
			display.commonUIParams(pcell.viewData.button , { cb = handler(self, self.CellButtonClick)})
		end
		pcell.viewData.button:setTag(index)
		pcell:UpdatePrivateOrder(self.privateOrder[index])
	end, __G__TRACKBACK__)
	return pcell
end
function PrivateMediator:CellButtonClick(sender)
	local index = sender:getTag()
	local LargeAndOrdinaryMediator = require( 'Game.mediator.LargeAndOrdinaryMediator')
	local orderInfo = self.privateOrder[index]
	orderInfo.orderType = Types.TYPE_TAKEAWAY_PRIVATE
	local mediator = LargeAndOrdinaryMediator.new(orderInfo)
	app:RegistMediator(mediator)
end
function PrivateMediator:EnterAction()
	---@type PrivateOrderView
	local viewComponent = self:GetViewComponent()
	viewComponent:stopAllActions()
	viewComponent:runAction(
		cc.RepeatForever:create(
			cc.Sequence:create(
				cc.CallFunc:create(function()
					local orderDatas = app.takeawayMgr:GetDatas()
					local nextPrivateOrderRefreshTime = checkint(orderDatas.nextPrivateOrderRefreshTime)
					viewComponent:UpdateTimeLabel(nextPrivateOrderRefreshTime)
				end),
				cc.DelayTime:create(1)
			)
		)
	)
end
function PrivateMediator:SetVisible(isVisible)
	local viewComponent = self.viewComponent
	viewComponent:setVisible(isVisible)
	
end
function PrivateMediator:UnRegsitMediator()
	AppFacade.GetInstance():UnRegsitMediator(NAME)
end
function PrivateMediator:OnRegist()
	-- 开启背景音乐
end

function PrivateMediator:OnUnRegist()
	local viewComponent = self:GetViewComponent()
	if viewComponent and (not tolua.isnull(viewComponent)) then
		viewComponent:stopAllActions()
	end
end

return PrivateMediator
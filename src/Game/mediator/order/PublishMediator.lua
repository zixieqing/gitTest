--[[
抽卡动画mediator
--]]
local Mediator = mvc.Mediator
---@class PublishMediator : Mediator
local PublishMediator = class("PublishMediator", Mediator)
---@type UIManager
local uiMgr = app.uiMgr
local NAME = "PublishMediator"
---@type TakeawayManager
local takeawayInstance = AppFacade.GetInstance():GetManager('TakeawayManager')
function PublishMediator:ctor( params, viewComponent )
	self.super:ctor(NAME, viewComponent)
	local orderDatas = app.takeawayMgr.orderDatas

	local publicOrder = orderDatas.publicOrder or {}
	self.publicOrder = self:GetOrderData(publicOrder)
end

function PublishMediator:InterestSignals()
	local signals = {
		FRESH_TAKEAWAY_POINTS ,
		FRESH_TAKEAWAY_ORDER_POINTS
	}
	return signals
end

function PublishMediator:ProcessSignal( signal )
	local name = signal:GetName()
	if name == FRESH_TAKEAWAY_POINTS or
	FRESH_TAKEAWAY_ORDER_POINTS == name  then
		local orderDatas = app.takeawayMgr.orderDatas
		local publicOrder = orderDatas.publicOrder or {}
		self.publicOrder = self:GetOrderData(publicOrder)
		self:ReloadData()
	end
end

function PublishMediator:GetOrderData(privateOrder)
	local noDistributionOrder = {}
	for i, v in pairs(privateOrder) do
		if checkint(v.status) == 1  then
			noDistributionOrder[#noDistributionOrder+1] = v
		end
	end
	return noDistributionOrder
end

function PublishMediator:Initial( key )
	self.super.Initial(self, key)
	---@type PrivateOrderView
	local PrivateOrderView = require("Game.views.order.PublishOrderView").new()
	self.viewComponent = PrivateOrderView
	---@type OrderMediator
	local mediator = AppFacade.GetInstance():RetrieveMediator("OrderMediator")
	---@type OrderView
	local orderView = mediator:GetViewComponent()
	orderView.viewData.bgLayer:addChild(PrivateOrderView)
	PrivateOrderView.viewData.gridView:setDataSourceAdapterScriptHandler(handler(self, self.PubDataSource))
	self:ReloadData()
	self:EnterAction()
end

function PublishMediator:ReloadData()
	---@type PrivateOrderView
	local viewComponent = self:GetViewComponent()
	local viewData = viewComponent.viewData
	viewData.gridView:setCountOfCell(table.nums(self.publicOrder))
	viewData.gridView:reloadData()
	if table.nums(self.publicOrder)  == 0 then
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
function PublishMediator:PubDataSource(p_convertview, idx )
	local index = idx +1
	---@type OrderCell
	local pcell = p_convertview
	xTry(function ()
		if not  pcell then
			pcell = require("Game.views.order.OrderCell").new()
			display.commonUIParams(pcell.viewData.button , { cb = handler(self, self.CellButtonClick)})
		end
		pcell.viewData.button:setTag(index)
		pcell:UpdatePublishOrder(self.publicOrder[index])
	end, __G__TRACKBACK__)
	return pcell
end
function PublishMediator:CellButtonClick(sender)
	local index = sender:getTag()
	local LargeAndOrdinaryMediator = require( 'Game.mediator.LargeAndOrdinaryMediator')
	local orderInfo = self.publicOrder[index]
	orderInfo.orderType = Types.TYPE_TAKEAWAY_PUBLIC
	local mediator = LargeAndOrdinaryMediator.new(orderInfo)
	app:RegistMediator(mediator)
end
function PublishMediator:SetVisible(isVisible)
	local viewComponent = self.viewComponent
	viewComponent:setVisible(isVisible)
end
function PublishMediator:EnterAction()
	---@type PublishOrderView
	local viewComponent = self:GetViewComponent()
	local viewData = viewComponent.viewData
	viewComponent:stopAllActions()
	viewComponent:runAction(
		cc.RepeatForever:create(
			cc.Sequence:create(
				cc.CallFunc:create(function()
					local orderDatas = app.takeawayMgr:GetDatas()
					local nextPublicOrderRefreshTime = checkint(orderDatas.nextPublicOrderRefreshTime)
					viewComponent:UpdateTimeLabel(nextPublicOrderRefreshTime)

					local num =  viewData.gridView:getCountOfCell()
					for i = 1 , num do
						---@type OrderCell
						local cell = viewData.gridView:cellAtIndex(i-1)
						if cell and ( not tolua.isnull(cell)) then
							cell:UpdatePublishTime(self.publicOrder[i])
						end
					end

				end),
				cc.DelayTime:create(1)
			)
		)
	)
end
function PublishMediator:UnRegsitMediator()
	AppFacade.GetInstance():UnRegsitMediator(NAME)
end
function PublishMediator:OnRegist(  )
	-- 开启背景音乐
end

function PublishMediator:OnUnRegist()
	local viewComponent = self:GetViewComponent()
	if viewComponent and (not tolua.isnull(viewComponent)) then
		viewComponent:stopAllActions()
	end
end
return PublishMediator
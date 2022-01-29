--[[
抽卡动画mediator
--]]
local Mediator = mvc.Mediator
---@class OrderMediator : Mediator
local OrderMediator = class("OrderMediator", Mediator)
local uiMgr = app.uiMgr
local NAME = "OrderMediator"
---@type TakeawayManager
local takeawayInstance = AppFacade.GetInstance():GetManager('TakeawayManager')
local MODULE_TAG = {
	PRIVATE_ORDER = 1001 ,
	PUBLISH_ORDER = 1002 ,
	TAKEAWAY_ORDER= RemindTag.ORDER ,
}
function OrderMediator:ctor( params, viewComponent )
	self.super:ctor(NAME, viewComponent)
	self.chestsModuleData = app.activityMgr:GetChestTypeTablesByModuleId(JUMP_MODULE_DATA.TAKEWAY)
	self.freshSuccess = takeawayInstance.freshSuccess
	self.mediators = {}
end
function OrderMediator:InterestSignals()
	local signals = {
		FRESH_TAKEAWAY_POINTS ,
		FRESH_TAKEAWAY_ORDER_POINTS ,
	}
	return signals
end

function OrderMediator:ProcessSignal( signal )
	local name = signal:GetName()
	if name ==  FRESH_TAKEAWAY_ORDER_POINTS
	or name == FRESH_TAKEAWAY_POINTS  then
		if not  self.freshSuccess then
			self:DirectirModuleBtn(MODULE_TAG.TAKEAWAY_ORDER)
		end
		self.freshSuccess = takeawayInstance.freshSuccess
	end
end

local MODULE_TAG = {
	PRIVATE_ORDER = 1001 ,
	PUBLISH_ORDER = 1002 ,
	TAKEAWAY_ORDER= RemindTag.ORDER ,
	ORDER_CHEST = 1103 ,
}
local MEDIATOR_NAMES = {
	[tostring(MODULE_TAG.PRIVATE_ORDER)]  = "order.PrivateMediator",
	[tostring(MODULE_TAG.PUBLISH_ORDER)]  = "order.PublishMediator",
	[tostring(MODULE_TAG.TAKEAWAY_ORDER)] = "order.DeliveryAndExploreMediator",

}


function OrderMediator:Initial( key )
	self.super.Initial(self, key)
	---@type OrderView
	local view = require("Game.views.order.OrderView").new()
	view:setPosition(display.center)
	self:SetViewComponent(view)
	local scene = uiMgr:GetCurrentScene()
	scene:AddDialog(view)
	local viewComponent = self:GetViewComponent()
	viewComponent.viewData.closeLayer:setOnClickScriptHandler(function (sender)
		if self.isAction then
			if self.mediators then
				for i, v in pairs(self.mediators) do
					v:UnRegsitMediator()
				end
			end
			AppFacade.GetInstance():UnRegsitMediator(NAME)
		end
	end)
	for tag , btn  in pairs(view.viewData.modulesBtn) do
		display.commonUIParams(btn , {cb = handler(self, self.ButtonAction)})
	end
	if self.freshSuccess  then

	end
	self:EnterAction()
end

function OrderMediator:EnterAction()
	local viewComponent = self:GetViewComponent()
	viewComponent.viewData.bgLayer:setPosition(cc.p(display.width+ 555, display.height/2))
	viewComponent.viewData.bgLayer:runAction(cc.Sequence:create(
			cc.CallFunc:create(function()
				self:CreateOrderChestMediator()
				if self.freshSuccess then
					self:DirectirModuleBtn(MODULE_TAG.TAKEAWAY_ORDER)
				end
			end),
			cc.MoveTo:create( 0.25 , cc.p(display.SAFE_R , display.height/2)),
			cc.CallFunc:create(function ()
				self.isAction = true
			end)
	))
end

function OrderMediator:ButtonAction(sender)
	self.freshSuccess = takeawayInstance.freshSuccess
	local tag = sender:getTag()
	if not  self.freshSuccess then
		app.uiMgr:ShowInformationTips(__('暂无数据，稍等片刻'))
		return
	end
	self:DirectirModuleBtn(tag)
end

function OrderMediator:DirectirModuleBtn(tag)

	if not  self.mediators[tostring(tag)] then
		local mediator = require("Game.mediator." .. MEDIATOR_NAMES[tostring(tag)]).new()
		AppFacade.GetInstance():RegistMediator(mediator)
		self.mediators[tostring(tag)] = mediator
	end
	---@type OrderView
	local viewComponent = self:GetViewComponent()
	local viewData = viewComponent.viewData
	for i , btn  in pairs(viewData.modulesBtn) do
		btn:setEnabled(true)
		btn:getLabel():setColor(ccc3FromInt("#ffffff"))
		if self.mediators[tostring(i)] then
			self.mediators[tostring(i)]:SetVisible(false)
		end
	end
	self.mediators[tostring(tag)]:SetVisible(true)
	viewData.modulesBtn[tostring(tag)]:setEnabled(false)
	viewData.modulesBtn[tostring(tag)]:getLabel():setColor(ccc3FromInt("#5c5c5c"))
	local mediator = AppFacade.GetInstance():RetrieveMediator("TakeawayCarUpgradeMediator")
	if mediator then
		app:UnRegsitMediator("TakeawayCarUpgradeMediator")
	end
	if tag == MODULE_TAG.TAKEAWAY_ORDER then
		app:DispatchObservers("CHEST_TITLE_UPDATE_EVENT" , {posIndex = 1})
	elseif tag == MODULE_TAG.PRIVATE_ORDER then
		app:DispatchObservers("CHEST_TITLE_UPDATE_EVENT" , {posIndex = 2})
	elseif tag == MODULE_TAG.PUBLISH_ORDER then	
		app:DispatchObservers("CHEST_TITLE_UPDATE_EVENT" , {posIndex = 3})
	end
end

function OrderMediator:CreateOrderChestMediator()
	if table.nums(self.chestsModuleData) > 0 then
		local mediator = require("Game.mediator.order.OrderChestMediator").new({
			chestsModuleData = self.chestsModuleData
		})
		app:RegistMediator(mediator)
		self.mediators[tostring(MODULE_TAG.ORDER_CHEST)] = mediator
	end

end

function OrderMediator:OnRegist(  )
	-- 开启背景音乐
end


function OrderMediator:OnUnRegist(  )
	local viewComponent = self:GetViewComponent()
	if viewComponent and (not tolua.isnull(viewComponent)) then
		viewComponent:runAction(cc.RemoveSelf:create())
	end
end
return OrderMediator
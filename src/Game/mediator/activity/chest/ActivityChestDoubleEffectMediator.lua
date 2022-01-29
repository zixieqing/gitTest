--[[
奖励mediator
--]]
local Mediator = mvc.Mediator
---@class ActivityChestDoubleEffectMediator :Mediator
local ActivityChestDoubleEffectMediator = class("ActivityChestDoubleEffectMediator", Mediator)
local NAME = "Game.mediator.activity.chest.ActivityChestDoubleEffectMediator"
ActivityChestDoubleEffectMediator.NAME = NAME
local CHEST_DOUBLE_EFFECT = "CHEST_DOUBLE_EFFECT"
local CHEST_DOUBLE_BUY_SUCCESS_EVENT =  "CHEST_DOUBLE_BUY_SUCCESS_EVENT"
function ActivityChestDoubleEffectMediator:ctor(params, viewComponent)
	self.super.ctor(self, NAME, viewComponent)
	self.datas = params
	self.orderNo = nil
end
function ActivityChestDoubleEffectMediator:InterestSignals()
	return {
		SIGNALNAMES.Restaurant_Shop_GetPayOrder_Callback,
		EVENT_PAY_MONEY_SUCCESS_UI,
	}
end

function ActivityChestDoubleEffectMediator:ProcessSignal(signal)
	local name = signal:GetName()
	local data = signal:GetBody()
	if name == SIGNALNAMES.Restaurant_Shop_GetPayOrder_Callback then
		if signal:GetBody().requestData.name ~= CHEST_DOUBLE_EFFECT then return end
		if data.orderNo then
			self.orderNo = data.orderNo
			if device.platform == 'android' or device.platform == 'ios' then
				local AppSDK = require('root.AppSDK')
				local price =  checkint(self.datas.price)
				AppSDK.GetInstance():InvokePay({amount =  price  , property = data.orderNo, goodsId = tostring(self.datas.channelProductId), goodsName = __('幻晶石'), quantifier = __('个'),price = 0.1, count = 1})
			end
		end
	elseif name == EVENT_PAY_MONEY_SUCCESS_UI then
		if self.datas.hasPurchased ~= 1 then
			app:DispatchObservers(CHEST_DOUBLE_BUY_SUCCESS_EVENT , {hasPurchased  = 1})
			self.datas.hasPurchased = 1
			local viewComponent = self:GetViewComponent()
			viewComponent:UpdateBuyBtn(self.datas.hasPurchased , self.datas.price)
		end
	end
end

-- inheritance method
function ActivityChestDoubleEffectMediator:Initial(key)
	self.super.Initial(self, key)
	---@type ActivityChestDoubleEffectView
	local viewComponent =  require("Game.views.activity.chest.ActivityChestDoubleEffectView").new()
	viewComponent:setPosition(display.center)
	app.uiMgr:GetCurrentScene():AddDialog(viewComponent)
	self:SetViewComponent(viewComponent)
	local viewData = viewComponent.viewData
	display.commonUIParams(viewData.closeLayer , {cb = handler(self, self.CloseClick) , animate = false})
	display.commonUIParams(viewData.buyBtn , {cb = handler(self, self.BuyClick) , animate = false})
	viewComponent:UpdateEffectLabel()
	viewComponent:UpdateBuyBtn(self.datas.hasPurchased , self.datas.price)
end

function ActivityChestDoubleEffectMediator:BuyClick(sender)
	if checkint(self.datas.hasPurchased) == 1 then
		app.uiMgr:ShowInformationTips(__('双倍特权已经购买'))
		return
	end
	PlayAudioByClickNormal()
	self:SendSignal(COMMANDS.COMMANDS_All_Shop_GetPayOrder,{productId = self.datas.productId , name = CHEST_DOUBLE_EFFECT})
end

function ActivityChestDoubleEffectMediator:CloseClick()
	self:GetFacade():UnRegistMediator(NAME)
end

function ActivityChestDoubleEffectMediator:OnRegist()

end

function ActivityChestDoubleEffectMediator:OnUnRegist()
	local viewComponent = self:GetViewComponent()
	if viewComponent and (not tolua.isnull(viewComponent)) then
		viewComponent:runAction(cc.RemoveSelf:create())
	end
end

return ActivityChestDoubleEffectMediator

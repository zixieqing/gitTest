--[[
扭蛋系统mediator
--]]
local Mediator = mvc.Mediator
---@class BlackGoldThisGoodsMediator :Mediator
local BlackGoldThisGoodsMediator = class("BlackGoldInvestMentMediator", Mediator)
local NAME = "BlackGoldInvestMentMediator"
local PRECIOUS_TYPES = {
	SKIN_TYPE = 1  ,
	CHEST_TYPE = 2
}
local BUTTON_TAG = {
	CLOSE_BTN          = 1001 ,
	COMMMON_GOODS_BTN  = 1002,
	PRECIOUS_GOODS_BTN = 1003,
	LOTTERY_BTN = 1004,
	DIRECTLY_BTN = 1005,
	LOG_BTN = 1006,
	TIP_BTN            = 1010,
}
local END_ACTION_EVENT = "END_ACTION_EVENT"   -- 完成事件的回调
local RIGHT_LAYOUT_SHOW_EVENT = "RIGHT_LAYOUT_SHOW_EVENT"
function BlackGoldThisGoodsMediator:ctor(param ,  viewComponent )
	self.super:ctor(NAME,viewComponent)
	self.goodsData ={}
	self.preciousView = nil
end

function BlackGoldThisGoodsMediator:InterestSignals()
	local signals = {
		POST.COMMERCE_MALL.sglName,
		POST.COMMERCE_MALL_BUY.sglName,
		POST.COMMERCE_PRECIOUS_MALL_BUY.sglName,
		POST.COMMERCE_PRECIOUS_LOTTERY.sglName,

		POST.COMMERCE_PRECIOUS_LOTTERY_LIST.sglName,
		END_ACTION_EVENT
	}
	return signals
end

function BlackGoldThisGoodsMediator:ProcessSignal( signal )
	local name = signal:GetName()
	local data = signal:GetBody()
	if name == POST.COMMERCE_MALL.sglName  then
		self.goodsData = data
		local commonData = self.goodsData.normal
		self.goodsData.precious.recordTime = os.time()
		---@type BlackGoldThisGoodsView
		local viewComponent = self:GetViewComponent()
		local viewData =  viewComponent.viewData
		viewData.cgridView:setCountOfCell(#commonData)
		viewData.cgridView:reloadData()
		viewComponent:EnterAction()
	elseif name == POST.COMMERCE_PRECIOUS_MALL_BUY.sglName then

		local preciousData =  self.goodsData.precious
		preciousData.hasPurchased  = 1
		preciousData.leftPurchasedNum = preciousData.leftPurchasedNum - 1
		CommonUtils.DrawRewards({{ goodsId = REPUTATION_ID , num = - preciousData.price }})
		local rewards = data.rewards
		app.uiMgr:AddDialog("common.RewardPopup" , { rewards = rewards})
		self.preciousView:UpdateView(preciousData)
	elseif name == POST.COMMERCE_PRECIOUS_LOTTERY_LIST.sglName then
		local view = require("Game.views.blackGold.BlackGoldPreciousLotteryLogView").new({data = data })
		app.uiMgr:GetCurrentScene():AddDialog(view)
		view:setPosition(display.center)
	elseif name == END_ACTION_EVENT then
		local viewComponent = self:GetViewComponent()
		local viewData = viewComponent.viewData
		viewData.closeLayer:setOnClickScriptHandler(handler(self, self.ButtonAction))
	elseif name == POST.COMMERCE_PRECIOUS_LOTTERY.sglName then
		local preciousData =  self.goodsData.precious
		preciousData.hasLottery = 1
		CommonUtils.DrawRewards({{ goodsId = REPUTATION_ID , num =   - preciousData.lotteryPrice  }})
		self.preciousView:UpdateView(preciousData)

	elseif name == POST.COMMERCE_MALL_BUY.sglName then
		local requestData = data.requestData
		local index = requestData.index
		local price = requestData.price
		local num = requestData.num
		self.goodsData.normal[index].leftPurchasedNum = self.goodsData.normal[index].leftPurchasedNum - num
		local rewards = data.rewards
		CommonUtils.DrawRewards({{ goodsId =  REPUTATION_ID , num = - price }})
		app.uiMgr:AddDialog("common.RewardPopup" , { rewards = rewards})
		---@type BlackGoldThisGoodsView
		local viewComponent = self:GetViewComponent()
		---@type BlackGoldLInvestMentCell
		local cell =  viewComponent.viewData.cgridView:cellAtIndex(index-1)
		if cell and (not (tolua.isnull(cell))) then
			cell:UpdateView(self.goodsData.normal[index])
		end
	end
end


function BlackGoldThisGoodsMediator:Initial( key )
	self.super.Initial(self, key)
	---@type BlackGoldThisGoodsView
	local viewComponent = require("Game.views.blackGold.BlackGoldThisGoodsView").new()
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	app.uiMgr:GetCurrentScene():AddDialog(viewComponent)
	local viewData = viewComponent.viewData
	viewData.preicousGoodstBtn:setOnClickScriptHandler(handler(self, self.ButtonAction))
	viewData.tipBtn:setOnClickScriptHandler(handler(self, self.ButtonAction))
	viewData.commonGoodsBtn:setOnClickScriptHandler(handler(self, self.ButtonAction))
	viewData.cgridView:setDataSourceAdapterScriptHandler(handler(self, self.CDataSource))
	self:DealWithBtnClick(BUTTON_TAG.COMMMON_GOODS_BTN)
end
function BlackGoldThisGoodsMediator:ButtonAction(sender)
	PlayAudioByClickNormal()
	local tag = sender:getTag()
	if tag == BUTTON_TAG.CLOSE_BTN then
		AppFacade.GetInstance():UnRegsitMediator(NAME)
	elseif tag == BUTTON_TAG.LOG_BTN then -- 珍贵货物
		self:SendSignal(POST.COMMERCE_PRECIOUS_LOTTERY_LIST.cmdName,{})
	elseif tag == BUTTON_TAG.TIP_BTN then -- 商船货物说明
		app.uiMgr:ShowIntroPopup({moduleId = -38 })
	elseif tag == BUTTON_TAG.PRECIOUS_GOODS_BTN then -- 珍贵货物
		self:DealWithBtnClick(BUTTON_TAG.PRECIOUS_GOODS_BTN)
	elseif tag == BUTTON_TAG.DIRECTLY_BTN then -- 直接购买
		self:DirectlyBuyClick()
	elseif tag == BUTTON_TAG.LOTTERY_BTN then -- 预约购买
		self:LotteryBuyClick()
	elseif tag == BUTTON_TAG.COMMMON_GOODS_BTN then -- 普通货物
		self:DealWithBtnClick(BUTTON_TAG.COMMMON_GOODS_BTN)
	end
end

function BlackGoldThisGoodsMediator:DealWithBtnClick(tag)
	---@type BlackGoldThisGoodsView
	local viewComponent = self:GetViewComponent()
	local viewData = viewComponent.viewData
	local curbtn = nil
	local prebtn = nil
	local curView = nil
	local preView = nil
	if tag == BUTTON_TAG.PRECIOUS_GOODS_BTN then
		curbtn = viewData.preicousGoodstBtn
		prebtn = viewData.commonGoodsBtn
		curView = viewData.preicousGoodsLayout
		preView = viewData.commonGoodsLayout
		local children =  curView:getChildren()
		-- 没有刷刷新过
		if #children == 0  then -- 刷新界面
			if checkint(self.goodsData.precious.type) == PRECIOUS_TYPES.CHEST_TYPE  then
				---@type BlackGoldPrciousChestView
				local view = require("Game.views.blackGold.BlackGoldPrciousChestView").new()
				viewData.preicousGoodsLayout:addChild(view)
				view:setPosition(689/2 , 527/2)
				view:UpdateView(self.goodsData.precious)
				self.preciousView = view
			else
				---@type BlackGoldPrciousSkinView
				local view = require("Game.views.blackGold.BlackGoldPrciousSkinView").new()
				viewData.preicousGoodsLayout:addChild(view)
				view:setPosition(689/2 , 527/2)
				view:UpdateView(self.goodsData.precious)
				self.preciousView = view
			end
			local viewData = self.preciousView.viewData
			viewData.makeDrawBtn:setOnClickScriptHandler(handler(self, self.ButtonAction))
			viewData.buyBtn:setOnClickScriptHandler(handler(self, self.ButtonAction))
			viewData.logBtn:setOnClickScriptHandler(handler(self, self.ButtonAction))
		end
	elseif  tag == BUTTON_TAG.COMMMON_GOODS_BTN then
		curbtn = viewData.commonGoodsBtn
		prebtn = viewData.preicousGoodstBtn
		preView	 = viewData.preicousGoodsLayout
		curView = viewData.commonGoodsLayout
	end
	curView:setVisible(true)
	preView:setVisible(false)
	prebtn:setEnabled(true)
	curbtn:setEnabled(false)
	curbtn:getLabel():setColor(ccc3FromInt("#d23d3d"))
	prebtn:getLabel():setColor(ccc3FromInt("#ffffff"))
end

function BlackGoldThisGoodsMediator:EnterLayer()
	self:SendSignal(POST.COMMERCE_MALL.cmdName , {})
end

function BlackGoldThisGoodsMediator:CDataSource( p_convertview,idx )
	---@type BlackGoldCommonGoodsCell
	local pCell = p_convertview
	local index = idx + 1
	xTry(function ( )
		if not pCell then
			pCell = require("Game.views.blackGold.BlackGoldCommonGoodsCell").new()
		end
		pCell.viewData.buyBtn:setTag(index)
		display.commonUIParams(pCell.viewData.buyBtn , {cb = handler(self , self.BuyMallClick)})
		pCell:UpdateView(self.goodsData.normal[index])
	end, __G__TRACKBACK__)
	return pCell
end

function BlackGoldThisGoodsMediator:LotteryBuyClick()
	if not  app.blackGoldMgr:GetIsTrade() then
		app.uiMgr:ShowInformationTips(__('商船已经出海，不能预约'))
		return
	end
	local preciousData = self.goodsData.precious
	local hasLottery = checkint(preciousData.hasLottery)
	if hasLottery == 1 then
		app.uiMgr:ShowInformationTips(__('不可重复预约'))
		return
	end
	local currentTime = os.time()
	local recordTime = preciousData.recordTime
	local distanceTime = currentTime - recordTime
	if distanceTime > checkint(preciousData.lotteryLeftSeconds) then
		app.uiMgr:ShowInformationTips(__('预约抽奖已结束'))
		return
	end
	local ownerNum = CommonUtils.GetCacheProductNum(REPUTATION_ID)
	local price = checkint(preciousData.lotteryPrice)
	if ownerNum  <  price then
		app.uiMgr:ShowInformationTips(__('商团声望不足'))
		return
	end
	self:SendSignal(POST.COMMERCE_PRECIOUS_LOTTERY.cmdName , {})
end

function BlackGoldThisGoodsMediator:DirectlyBuyClick()
	if not  app.blackGoldMgr:GetIsTrade() then
		app.uiMgr:ShowInformationTips(__('商船已经出海，不能购买'))
		return
	end

	local preciousData = self.goodsData.precious
	local hasPurchased = checkint(preciousData.hasPurchased)
	if hasPurchased == 1 then
		app.uiMgr:ShowInformationTips(__('已经购买过了'))
		return
	end
	local ownerNum = CommonUtils.GetCacheProductNum(REPUTATION_ID)
	local price = checkint(preciousData.price)
	if ownerNum  <  price then
		app.uiMgr:ShowInformationTips(__('商团声望不足'))
		return
	end
	local leftPurchasedNum = checkint(preciousData.leftPurchasedNum)
	if leftPurchasedNum  <= 0  then
		app.uiMgr:ShowInformationTips(__('已售罄'))
		return
	end
	self:SendSignal(POST.COMMERCE_PRECIOUS_MALL_BUY.cmdName , {})
end

function BlackGoldThisGoodsMediator:BuyMallClick(sender)
	if not  app.blackGoldMgr:GetIsTrade() then
		app.uiMgr:ShowInformationTips(__('商船已经出海，不能购买道具'))
		return
	end
	local index = sender:getTag()
	local commonData = self.goodsData.normal[index]
	local price = checkint(commonData.price)
	local ownerNum = CommonUtils.GetCacheProductNum(REPUTATION_ID)
	local titleGrade = app.blackGoldMgr:GetTitleGrade()
	if titleGrade  < checkint(commonData.unlockGrade)  then
		app.uiMgr:ShowInformationTips(string.fmt(__('商会等级 _level_ 级解锁') , { _level_ = commonData.unlockGrade }) )
		return
	end

	if ownerNum  <  price then
		app.uiMgr:ShowInformationTips(__('商团声望不足'))
		return
	end

	if  checkint(commonData.leftPurchasedNum) <=  0   then
		app.uiMgr:ShowInformationTips(__('已售罄'))
		return
	end
	local storePurchasePopup = require('Game.views.ShopPurchasePopup').new({
		data = {
			goodsId = commonData.goodsId ,
			price = commonData.price ,
			stock = commonData.stock ,
			lifeLeftPurchasedNum = commonData.leftPurchasedNum ,
			todayLeftPurchasedNum = commonData.leftPurchasedNum ,
			currency = REPUTATION_ID ,
			sale = { [tostring(REPUTATION_ID)] =commonData.goodsNum }
		},
		mediatorName = "UnionShopMediator",
		tag = 5001,
		btnTag = 5001,
		showChooseUi = true ,
	})
	display.commonUIParams(storePurchasePopup.viewData.purchaseBtn, {cb = function(sender)
		local purchaseNum = sender:getUserTag()
		if ownerNum  <  commonData.price * purchaseNum then
			app.uiMgr:ShowInformationTips(__('商团声望不足'))
			return
		end
		self:SendSignal(POST.COMMERCE_MALL_BUY.cmdName ,{productId = commonData.productId , num = purchaseNum , index  = index  ,price =  commonData.price * purchaseNum  })
		local viewComponent = self:GetViewComponent()
		viewComponent:runAction(cc.TargetedAction:create(storePurchasePopup , cc.RemoveSelf:create()))
	end})
	display.commonUIParams(storePurchasePopup, {ap = display.CENTER, po = display.center})
	storePurchasePopup:setTag(5001)
	app.uiMgr:GetCurrentScene():AddDialog(storePurchasePopup)
end

function BlackGoldThisGoodsMediator:OnRegist()
	regPost(POST.COMMERCE_MALL)
	regPost(POST.COMMERCE_MALL_BUY)
	regPost(POST.COMMERCE_PRECIOUS_LOTTERY)
	regPost(POST.COMMERCE_PRECIOUS_MALL_BUY)
	regPost(POST.COMMERCE_PRECIOUS_LOTTERY_LIST)
	self:EnterLayer()
end
function BlackGoldThisGoodsMediator:OnUnRegist()
	unregPost(POST.COMMERCE_MALL)
	unregPost(POST.COMMERCE_MALL_BUY)
	unregPost(POST.COMMERCE_PRECIOUS_LOTTERY)
	unregPost(POST.COMMERCE_PRECIOUS_MALL_BUY)
	unregPost(POST.COMMERCE_PRECIOUS_LOTTERY_LIST)
	AppFacade.GetInstance():DispatchObservers(RIGHT_LAYOUT_SHOW_EVENT , {})
	local viewComponent = self:GetViewComponent()
	if viewComponent and (not tolua.isnull(viewComponent)) then
		viewComponent:runAction(cc.RemoveSelf:create())
	end
end

return BlackGoldThisGoodsMediator

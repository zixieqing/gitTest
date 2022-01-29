--[[
扭蛋系统mediator
--]]
local Mediator = mvc.Mediator
---@class BlackGoldTradeMediator :Mediator
local BlackGoldTradeMediator = class("BlackGoldInvestMentMediator", Mediator)
local NAME = "BlackGoldTradeMediator"
local blackGoldMgr = app.blackGoldMgr
----@type CommerceConfigParser
local CommerceConfigParser = require("Game.Datas.Parser.CommerceConfigParser")
local futuresConf = CommonUtils.GetConfigAllMess(CommerceConfigParser.TYPE.FUTURES , 'commerce')
local warehouseConf = CommonUtils.GetConfigAllMess(CommerceConfigParser.TYPE.WAREHOUSE , 'commerce')
function BlackGoldTradeMediator:ctor(param ,  viewComponent )
	self.super:ctor(NAME,viewComponent)
	self.futuresData  = {}
	self.backpackCount = 0 -- 背包的数量
	self.status = 0  -- 1、动画完场 2、 请求完成
end

local BUTTON_TAG = {
	BACK_BTN         = 1003, -- 返回按钮
	LTRADE_BTN       = 1004, -- 上期交易
	CTRADE_BTN       = 1005, -- 本期交易
	ADD_CAPACITY_BTN = 1006, -- 扩容背包
	TRADE_EVENT_BTN  = 1007, -- 港口贸易
	TIP_BTN          = 1008, -- 交易规则

}
function BlackGoldTradeMediator:InterestSignals()
	local signals = {
		POST.COMMERCE_WARE_HOUSE.sglName,
		POST.COMMERCE_FUTURES_BUY.sglName,
		POST.COMMERCE_FUTURES_SELL.sglName,
		POST.COMMERCE_WARE_HOUSE_EXTEND.sglName
	}
	return signals
end

function BlackGoldTradeMediator:ProcessSignal( signal )
	local name = signal:GetName()
	local data = signal:GetBody()
	if name == POST.COMMERCE_WARE_HOUSE.sglName  then
		self.futuresData = data
		local goodData = {}
		local current = {}
		local futuresPrices = {}

		for i, v in pairs(data.current or {}) do
			local stock = checkint(futuresConf[tostring(v.futuresId)].stock)
			local leftPurchase = stock - checkint(v.stock)
			goodData[#goodData+1] = {
				stock = stock ,
				leftPurchase = leftPurchase  ,
				price = v.price ,
				futuresId = v.futuresId ,
			}
			futuresPrices[tostring(v.futuresId)] = checkint(v.price)
			if checkint(v.stock) > 0  then
				current[#current+1] = v
			end
		end
		for index, goodData in pairs(self.futuresData.current) do
			self.backpackCount  = self.backpackCount + goodData.stock
		end
		for index, goodData in pairs(self.futuresData.previous) do
			self.backpackCount  = self.backpackCount + goodData.stock
		end
		if blackGoldMgr:GetStatus() == 2 then
			for i, v in pairs(self.futuresData.previous) do
				v.profit = checkint(futuresPrices[tostring(v.futuresId)])  -  v.price
			end
		end
		self.futuresData.current = current
		self.futuresData.goodsData = goodData
		-- 扣除消耗
		local viewComponent = self:GetViewComponent()
		local viewData = viewComponent.viewData
		local children =  viewData.crightLayout:getChildren()
		-- 没有刷刷新过
		local capacity =  warehouseConf[tostring(app.blackGoldMgr:GetWarehouseGrade())].capacity
		viewComponent:UpdateCapacity(self.backpackCount , capacity )
		self:GetViewComponent().viewData.crightLayout:setVisible(false)
		if #children == 1  then -- 刷新界面
			if #self.futuresData.current > 0  then
				self:CFuturesReloadData()
			else
				viewComponent:CreateCFuturesEmpty()
			end
		end
		self:FuturesReloadData()

	elseif name == POST.COMMERCE_FUTURES_BUY.sglName  then
		local requestData = data.requestData
		local futuresId = checkint(requestData.futuresId)

		local num = requestData.num
		self.backpackCount = num + self.backpackCount
		local price = requestData.price
		---@type BlackGoldTradeView
		local viewComponent = self:GetViewComponent()
		local viewData = viewComponent.viewData
		local current =  self.futuresData.current
		if #current > 0  then
			local cgoodData = nil
			local cIndex = nil
			for index , goodData in pairs(self.futuresData.current) do
				if checkint(goodData.futuresId)  == futuresId then
					goodData.stock = goodData.stock + num
					cgoodData = goodData
					cIndex = index
					break
				end
			end
			-- 判断道具是否存在 存在直接刷新即可
			if cgoodData then
				---@type TradeFuturesBuyCell
				local cell =  viewData.cgridView:cellAtIndex(cIndex-1)
				if cell and ( not tolua.isnull(cell)) and cell.UpdateView then
					cell:UpdateView(cgoodData)
				end
			else
				current[#current+1] = {futuresId = futuresId , stock = num}
				self:CFuturesReloadData()
			end
		else
			viewComponent:RemoveCRightLayoutChildOutGrideView()
			-- 更新自己背包的库存
			current[#current+1] = {futuresId = futuresId , stock = num}
			self:CFuturesReloadData()
		end
		-- 更新贸易的库存
		local fcellIndex = 1
		local fgoodData = nil 
		for index , goodData in pairs(self.futuresData.goodsData) do
			if checkint(goodData.futuresId)  == futuresId then
				goodData.leftPurchase = goodData.leftPurchase - num
				fcellIndex = index
				fgoodData = goodData
				break
			end
		end
		if fgoodData then
			---@type TradeFuturesCell
			local cell =  viewData.fgridView:cellAtIndex(fcellIndex-1)
			cell:UpdateView(fgoodData)
		end
		CommonUtils.DrawRewards({{
									 goodsId = REPUTATION_ID , num = -num * price
								 }})
		local capacity =  warehouseConf[tostring(app.blackGoldMgr:GetWarehouseGrade())].capacity
		viewComponent:UpdateCapacity(self.backpackCount , capacity )

	elseif name == POST.COMMERCE_FUTURES_SELL.sglName  then
		local requestData = data.requestData
		local futuresId = checkint(requestData.futuresId)
		local num = checkint(requestData.num)
		self.backpackCount =  self.backpackCount - num
		local index = checkint(requestData.index)
		local fgoodData = nil
		for index , goodData in pairs(self.futuresData.goodsData) do
			if checkint(goodData.futuresId)  == futuresId then
				fgoodData = goodData
				break
			end
		end
		local stock = self.futuresData.previous[index].stock
		stock = stock - num
		self.futuresData.previous[index].stock = stock
		---@type BlackGoldTradeView
		local viewComponent = self:GetViewComponent()
		local viewData = viewComponent.viewData
		if stock == 0 then
			table.remove(self.futuresData.previous , index )
			-- 刷新列表
			self:LFuturesReloadData()
			if #self.futuresData.previous == 0  then
				viewComponent:CreateLFuturesEmpty()
			end
		else
			---@type TradeFuturesSellCell
			local cell = viewData.lgridView:cellAtIndex(index -1)
			if cell and (not tolua.isnull(cell)) then
				cell:UpdateView(self.futuresData.previous[index])
			end
		end
		-- 更新获取数据
		app.uiMgr:AddDialog("common.RewardPopup" , {rewards = {
			{ goodsId = REPUTATION_ID , num = num * fgoodData.price }
		}})

		local capacity =  warehouseConf[tostring(app.blackGoldMgr:GetWarehouseGrade())].capacity
		viewComponent:UpdateCapacity(self.backpackCount , capacity )

	elseif name == POST.COMMERCE_WARE_HOUSE_EXTEND.sglName  then
		-- 更新仓库容量
		local warehouseGrade = checkint(data.warehouseGrade)
		blackGoldMgr:SetWarehouseGrade(warehouseGrade)
		local consume = warehouseConf[tostring(warehouseGrade)].consume
		local consumeData = {}
		for goodsId, num  in pairs(consume) do
			consumeData[#consumeData+1] = {goodsId = goodsId , num = -num }
		end
		consumeData[#consumeData+1] = {goodsId =REPUTATION_ID  ,num = - warehouseConf[tostring(warehouseGrade)].reputation    }
		CommonUtils.DrawRewards(consumeData)
		-- 显示升级成功
		local view = require("Game.views.blackGold.BlackGoldUpgradeSuccessPopUp").new()
		view:setPosition(display.center)
		app.uiMgr:GetCurrentScene():AddDialog(view)
		local viewComponent = self:GetViewComponent()
		local capacity =  warehouseConf[tostring(app.blackGoldMgr:GetWarehouseGrade())].capacity
		viewComponent:UpdateCapacity(self.backpackCount , capacity )
		viewComponent:CheckCapacityBtnIsVisible()
	end

end

function BlackGoldTradeMediator:Initial( key )
	self.super.Initial(self, key)
	---@type BlackGoldTradeView
	local viewComponent = require("Game.views.blackGold.BlackGoldTradeView").new()
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	app.uiMgr:GetCurrentScene():AddDialog(viewComponent)
	local viewData = viewComponent.viewData
	viewData.backBtn:setOnClickScriptHandler(handler(self, self.ButtonAction))
	viewData.capacityBtn:setOnClickScriptHandler(handler(self, self.ButtonAction))
	viewData.tradeCloseBtn:setOnClickScriptHandler(handler(self, self.ButtonAction))
	viewData.lastBtn:setOnClickScriptHandler(handler(self, self.ButtonAction))
	viewData.currentBtn:setOnClickScriptHandler(handler(self, self.ButtonAction))
	viewData.tabNameLabel:setOnClickScriptHandler(handler(self, self.ButtonAction))
	viewData.cgridView:setDataSourceAdapterScriptHandler(handler(self, self.CDataSource))
	viewData.fgridView:setDataSourceAdapterScriptHandler(handler(self, self.FDataSource))
	viewData.lgridView:setDataSourceAdapterScriptHandler(handler(self, self.LDataSource))
	self:DealWithBtnClick(BUTTON_TAG.CTRADE_BTN)
	if app.blackGoldMgr:GetIsTrade() then
		viewComponent:CheckCapacityBtnIsVisible()
		viewData.tradeBarSpine:setAnimation(0,'play1' , false)
	else
		viewData.tradeBarSpine:setAnimation(0,'play2' , false)
		viewComponent:CheckCapacityBtnIsVisible()
	end

	viewData.tradeBarSpine:registerSpineEventHandler(function(event)
		if event.animation == "play1" then
			viewData.fgridView:setVisible(true)
		else
			viewData.tradeCloseBtn:setVisible(true)
			viewData.fgridView:setVisible(false)
		end
	end, sp.EventType.ANIMATION_COMPLETE)
	
	viewData.tradeParper:setAnimation(0, 'play' , false )
	viewData.tradeParper:registerSpineEventHandler(function()
		viewData.crightLayout:setVisible(true)
		viewData.currentBtn:setVisible(true)
		viewData.lastBtn:setVisible(true)
	end, sp.EventType.ANIMATION_COMPLETE)
	viewData.tradeBarSpine:setVisible(true)
	viewData.tradeParper:setVisible(true)

end

function BlackGoldTradeMediator:DealWithBtnClick(tag)
	---@type BlackGoldTradeView
	local viewComponent = self:GetViewComponent()
	local viewData = viewComponent.viewData
	local curbtn = nil
	local prebtn = nil
	local curView = nil
	local preView = nil
	if tag == BUTTON_TAG.LTRADE_BTN then
		curbtn = viewData.lastBtn
		prebtn = viewData.currentBtn
		curView = viewData.lrightLayout
		preView = viewData.crightLayout
		local children =  curView:getChildren()
		-- 没有刷刷新过
		if #children == 1  then -- 刷新界面
			if #self.futuresData.previous > 0  then
				viewData.lgridView:setCountOfCell(#self.futuresData.previous)
				viewData.lgridView:reloadData()
			else
				viewComponent:CreateLFuturesEmpty()
			end
		end
	elseif tag == BUTTON_TAG.CTRADE_BTN then
		curbtn = viewData.currentBtn
		prebtn = viewData.lastBtn
		preView	 = viewData.lrightLayout
		curView = viewData.crightLayout
	end
	curView:setVisible(true)
	preView:setVisible(false)
	prebtn:setEnabled(true)
	curbtn:setEnabled(false)
end
function BlackGoldTradeMediator:FuturesReloadData()
	---@type BlackGoldTradeView
	local viewComponent = self:GetViewComponent()
	local viewData = viewComponent.viewData

	viewData.fgridView:setCountOfCell(#self.futuresData.goodsData)
	viewData.fgridView:reloadData()
end

function BlackGoldTradeMediator:LFuturesReloadData()
	---@type BlackGoldTradeView
	local viewComponent = self:GetViewComponent()
	local viewData = viewComponent.viewData
	viewData.lgridView:setCountOfCell(#self.futuresData.previous)
	viewData.lgridView:reloadData()
end
function BlackGoldTradeMediator:CFuturesReloadData()
	---@type BlackGoldTradeView
	local viewComponent = self:GetViewComponent()
	local viewData = viewComponent.viewData
	viewData.cgridView:setCountOfCell(#self.futuresData.current)
	viewData.cgridView:reloadData()
end

function BlackGoldTradeMediator:ButtonAction(sender)
	PlayAudioByClickNormal()
	local tag = sender:getTag()
	if tag == BUTTON_TAG.BACK_BTN then
		app:UnRegsitMediator(NAME)
	elseif tag == BUTTON_TAG.CTRADE_BTN then
		self:DealWithBtnClick( BUTTON_TAG.CTRADE_BTN)
	elseif tag == BUTTON_TAG.TRADE_EVENT_BTN then
		app.uiMgr:ShowInformationTips(__('离港期间交易关闭'))
	elseif tag == BUTTON_TAG.LTRADE_BTN then
		self:DealWithBtnClick( BUTTON_TAG.LTRADE_BTN)
	elseif tag == BUTTON_TAG.TIP_BTN then
		app.uiMgr:ShowIntroPopup({moduleId = -37 })
	elseif tag == BUTTON_TAG.ADD_CAPACITY_BTN then
		local view = require("Game.views.blackGold.BlackGoldUpgradeBackpackView").new()
		view:setPosition(display.center)
		app.uiMgr:GetCurrentScene():AddDialog(view)
		view:setName("Game.views.blackGold.BlackGoldUpgradeBackpackView")
	end
end

function BlackGoldTradeMediator:CDataSource( p_convertview,idx )
	---@type TradeFuturesBuyCell
	local pCell = p_convertview
	local index = idx + 1
	xTry(function ( )
		if not pCell then
			pCell = require("Game.views.blackGold.tradeCell.TradeFuturesBuyCell").new()
		end
		pCell:UpdateView(self.futuresData.current[index])
	end, __G__TRACKBACK__)
	return pCell
end

function BlackGoldTradeMediator:FDataSource( p_convertview,idx )
	---@type TradeFuturesCell
	local pCell = p_convertview
	local index = idx + 1
	xTry(function ( )
		if not pCell then
			pCell = require("Game.views.blackGold.tradeCell.TradeFuturesCell").new()
		end
		pCell.viewData.futuresLayout:setTag(index)
		display.commonUIParams(pCell.viewData.futuresLayout , {cb = handler(self , self.BuyFuturesClick)})
		pCell:UpdateView(self.futuresData.goodsData[index])
	end, __G__TRACKBACK__)
	return pCell
end

function BlackGoldTradeMediator:LDataSource( p_convertview,idx )
	---@type TradeFuturesSellCell
	local pCell = p_convertview
	local index = idx + 1
	xTry(function ( )
		if not pCell then
			pCell = require("Game.views.blackGold.tradeCell.TradeFuturesSellCell").new()
		end
		pCell.viewData.futuresLayout:setTag(index)
		display.commonUIParams(pCell.viewData.futuresLayout , {cb = handler(self , self.SellFuturesClick)})
		pCell:UpdateView(self.futuresData.previous[index])
	end, __G__TRACKBACK__)
	return pCell
end

function BlackGoldTradeMediator:BuyFuturesClick(sender)
	local index = sender:getTag()
	if not blackGoldMgr:GetIsTrade() then
		app.uiMgr:ShowInformationTips(__('商船离港期间交易关闭'))
		return
	end
	local goodData = self.futuresData.goodsData[index]
	---@type BlackGoldFuturesPopUp
	local view = require("Game.views.blackGold.BlackGoldFuturesPopUp").new({
		callback = function(num)
			local count = self.backpackCount + num
			local capacityNum = checkint(warehouseConf[tostring(app.blackGoldMgr:GetWarehouseGrade())].capacity)
			if count >  capacityNum then
				app.uiMgr:ShowInformationTips(__('仓储容量不足，请先扩充'))
				return
			end
			local needNum = num * goodData.price
			local ownerNum = CommonUtils.GetCacheProductNum(REPUTATION_ID)
			if needNum > ownerNum then
				app.uiMgr:ShowInformationTips(__('商团声望不足'))
				return
			end
			self:SendSignal(POST.COMMERCE_FUTURES_BUY.cmdName , { futuresId = goodData.futuresId , num = num , price = goodData.price , index = index })
		end
	})
	app.uiMgr:GetCurrentScene():AddDialog(view)
	view:setPosition(display.center)
	local cloneData =clone(goodData)
	cloneData.count = self.backpackCount
	view:UpdateBuyFutures(cloneData)
end

function BlackGoldTradeMediator:SellFuturesClick(sender)
	local index = sender:getTag()
	if not blackGoldMgr:GetIsTrade() then
		app.uiMgr:ShowInformationTips(__('商船离港期间交易关闭'))
		return
	end
	local goodData = self.futuresData.previous[index]
	---@type BlackGoldFuturesPopUp
	local view = require("Game.views.blackGold.BlackGoldFuturesPopUp").new({ callback = function(num)
		self:SendSignal(POST.COMMERCE_FUTURES_SELL.cmdName , { futuresId = goodData.futuresId , num = num , index = index })
	end})
	app.uiMgr:GetCurrentScene():AddDialog(view)
	view:setPosition(display.center)

	view:UpdateSellFutures(goodData)
end


function BlackGoldTradeMediator:EnterLayer()
	self:SendSignal(POST.COMMERCE_WARE_HOUSE.cmdName , {})
end

function BlackGoldTradeMediator:OnRegist()
	regPost(POST.COMMERCE_WARE_HOUSE)
	regPost(POST.COMMERCE_FUTURES_BUY)
	regPost(POST.COMMERCE_FUTURES_SELL)
	regPost(POST.COMMERCE_WARE_HOUSE_EXTEND)
	self:EnterLayer()
end
function BlackGoldTradeMediator:OnUnRegist()
	unregPost(POST.COMMERCE_WARE_HOUSE)
	unregPost(POST.COMMERCE_FUTURES_BUY)
	unregPost(POST.COMMERCE_FUTURES_SELL)
	unregPost(POST.COMMERCE_WARE_HOUSE_EXTEND)
	AppFacade.GetInstance():DispatchObservers("RIGHT_LAYOUT_SHOW_EVENT" , {})
	local viewComponent = self:GetViewComponent()
	if viewComponent and (not tolua.isnull(viewComponent)) then
		viewComponent:stopAllActions()
		viewComponent:runAction(cc.RemoveSelf:create())
	end
end

return BlackGoldTradeMediator

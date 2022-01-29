--[[
市场售后模块Mediator
--]]
local Mediator = mvc.Mediator

local MarketRecordMediator = class("MarketRecordMediator", Mediator)

local NAME = "MarketRecordMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance('AppFacade'):GetManager("GameManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
local marketRecordCell = require('home.MarketRecordCell')
local scheduler = require('cocos.framework.scheduler')
function MarketRecordMediator:ctor( params, viewComponent )
	self.super:ctor(NAME,viewComponent)
	self.myMarketDatas = {}
	self.saleMax = nil -- 最大寄售数量
	self.saleLeftNum = nil -- 剩余寄售数量

end

function MarketRecordMediator:InterestSignals()
	local signals = { 
		SIGNALNAMES.Market_MyMarket_Callback,
		SIGNALNAMES.Market_CancelConSignment_Callback,
		SIGNALNAMES.Market_Draw_Callback,
		SIGNALNAMES.Market_GetGoodsBack_Callback,
		SIGNALNAMES.Market_ConsignmentAgain_Callback,
	}
	return signals
end

function MarketRecordMediator:ProcessSignal( signal )
	local name = signal:GetName() 
	print(name)
	if name == SIGNALNAMES.Market_MyMarket_Callback then -- 获取寄售信息
		local datas = checktable(signal:GetBody())
		self.myMarketDatas = {}
		for k,v in pairs(datas.myMarket) do
			if v.cdTime and v.cdTime == 0 then
				v.cdTime = nil
			end
			if v.cdTime and v.cdTime < 500 then
				v.cdTime = v.cdTime + 2
			end
			v.id = tonumber(k)
			table.insert(self.myMarketDatas, v)
		end
		self.saleLeftNum = checkint(datas.consignmentNum)
		self:UpdateUI()
	elseif name == SIGNALNAMES.Market_CancelConSignment_Callback then -- 取消寄售
		local datas = checktable(signal:GetBody())
		for i,v in pairs(self.myMarketDatas) do
			if v.id == datas.requestData.marketId then
				local viewData = self:GetViewComponent().viewData_
				local cell = viewData.consignmentGridView:cellAtIndex(i-1)
				if cell then
					v.cdTime = nil 
					v.status = 3
					cell.consignmentAgainBtn:setVisible(true)
					cell.consignmentBtn:getLabel():setString(__('取回背包'))
					cell.timeLabel:setString(__('时间结束'))
				end
				break
			end
		end

	elseif name == SIGNALNAMES.Market_Draw_Callback then -- 领取
		local datas = checktable(signal:GetBody())
		gameMgr:GetUserInfo().gold = checkint(datas.gold)
		self:GetFacade():DispatchObservers(SIGNALNAMES.CACHE_MONEY_UPDATE_UI, {gold = datas.gold})
		for i,v in pairs(self.myMarketDatas) do
			if v.id == datas.requestData.marketId then
				table.remove(self.myMarketDatas, i)
				break
			end
		end
		self:UpdateUI()
	elseif name == SIGNALNAMES.Market_GetGoodsBack_Callback then -- 返回背包
		local datas = checktable(signal:GetBody())
		CommonUtils.DrawRewards({{goodsId = datas.goodsId, num = datas.num}})

		for i,v in pairs(self.myMarketDatas) do
			if v.id == datas.requestData.marketId then
				table.remove(self.myMarketDatas, i)
				break
			end
		end
		self:UpdateUI()
	elseif name == SIGNALNAMES.Market_ConsignmentAgain_Callback then -- 再次寄售
		local datas = checktable(signal:GetBody())
		local scene = uiMgr:GetCurrentScene() 
		if scene:GetDialogByTag(4001) then
			scene:GetDialogByTag(4001):runAction(cc.RemoveSelf:create())
		end
		for i,v in ipairs(self.myMarketDatas) do
			if v.id == datas.requestData.marketId then
				table.remove(self.myMarketDatas, i)
				break
			end
		end
		table.insert(self.myMarketDatas, datas.market)
		local viewData = self.viewComponent.viewData_
		viewData.consignmentGridView:setCountOfCell(table.nums(self.myMarketDatas))
		viewData.consignmentGridView:reloadData()
		uiMgr:ShowInformationTips(__('寄售成功'))
		self.saleLeftNum = self.saleLeftNum - 1
	end
end


function MarketRecordMediator:Initial( key )
	self.super.Initial(self,key)
	local viewComponent  = require( 'Game.views.MarketRecordView' ).new()
	self:SetViewComponent(viewComponent)
	local viewData = viewComponent.viewData_
	viewData.consignmentGridView:setDataSourceAdapterScriptHandler(handler(self, self.OnDataSourceAction))
	self.scheduler = scheduler.scheduleGlobal(handler(self, self.scheduleCallback), 1)
	viewData.consignmentGridView:setCountOfCell(table.nums(self.myMarketDatas))
	viewData.consignmentGridView:reloadData()
end

function MarketRecordMediator:OnDataSourceAction( p_convertview, idx )
	local pCell = p_convertview
    local index = idx + 1
    local viewData = self.viewComponent.viewData_
    local bg = viewData.gridView
    local cSize = cc.size(966, 108)
	-- if self.datas and index <= table.nums(self.datas) then
		if pCell == nil then
			pCell = marketRecordCell.new(cSize)
			pCell.consignmentAgainBtn:setOnClickScriptHandler(handler(self, self.ConsignmentAgainBtnCallback))
			pCell.consignmentBtn:setOnClickScriptHandler(handler(self, self.ConsignmentBtnCallback))
		end
		xTry(function()
			local data = self.myMarketDatas[index]
			local goodsData = CommonUtils.GetConfig('goods', 'goods', data.goodsId)
			pCell.goodsBg:setTexture('ui/common/common_frame_goods_' .. goodsData.quality .. '.png')
			pCell.goodsIcon:setTexture(CommonUtils.GetGoodsIconPathById(data.goodsId))
			pCell.goodsName:setString(goodsData.name)
			display.commonLabelParams(pCell.goodsName ,{reqW = 270})
			pCell.goodsNumLabel:setString(tostring(data.num))
			pCell.priceLabel:setString(tostring(data.price))
			if data.cdTime then
				pCell.timeLabel:setString(self:TimeChange(data.cdTime))
			else
				pCell.timeLabel:setString(__('时间结束'))
			end
			display.commonLabelParams(pCell.timeLabel , {reqW = 120})
			display.commonLabelParams(pCell.consignmentBtn:getLabel() , {text = __('取消寄售') ,reqW =105})
			if checkint(data.status) == 1 then -- 未出售
				pCell.consignmentAgainBtn:setVisible(false)
				pCell.timeBg:setVisible(false)
				pCell.consignmentBtn:getLabel():setString(__('取消寄售'))

				pCell.priceLabel:setString(tostring(data.price))
			elseif checkint(data.status) == 2 then -- 已出售
				pCell.consignmentAgainBtn:setVisible(false)
				pCell.timeBg:setVisible(true)
				pCell.consignmentBtn:getLabel():setString(__('领取'))
				pCell.priceLabel:setString(tostring(data.price * 0.7))
				pCell.timeLabel:setString(__('已售出'))	
			elseif checkint(data.status) == 3 then -- 可取回背包
				pCell.consignmentAgainBtn:setVisible(true)
				pCell.timeBg:setVisible(false)
				pCell.priceLabel:setString(tostring(data.price))
				pCell.consignmentBtn:getLabel():setString(__('取回背包'))
			end
			pCell.consignmentAgainBtn:setTag(index)
			pCell.consignmentBtn:setTag(index)
			display.commonLabelParams(pCell.consignmentBtn:getLabel(), {reqW =105})
			pCell:setTag(index)
		end,__G__TRACKBACK__)
        return pCell
	-- end
end
--[[
更新UI
--]]
function MarketRecordMediator:UpdateUI()
	local viewData = self:GetViewComponent().viewData_
	viewData.consignmentGridView:setCountOfCell(table.nums(self.myMarketDatas))
	viewData.consignmentGridView:reloadData()
end
--[[
再次寄售按钮回调
--]]
function MarketRecordMediator:ConsignmentAgainBtnCallback( sender )
	PlayAudioByClickNormal()
	local tag = sender:getTag()
	if self.saleLeftNum > 0 then
		local scene = uiMgr:GetCurrentScene() 
		local marketSalePopup  = require('Game.views.MarketSalePopup').new({tag = 4001, mediatorName = "MarketRecordMediator", data = self.myMarketDatas[tag]})
		display.commonUIParams(marketSalePopup, {ap = cc.p(0.5, 0.5), po = cc.p(display.width * 0.5, display.height * 0.5)})
		marketSalePopup:setTag(4001)
		scene:AddDialog(marketSalePopup)
	else
		uiMgr:ShowInformationTips(__('今日寄售次数已耗尽'))
	end
end
--[[
右侧按钮回调
--]]
function MarketRecordMediator:ConsignmentBtnCallback( sender )
	PlayAudioByClickNormal()
	local tag = sender:getTag()
	local data = self.myMarketDatas[tag]
	if checkint(data.status) == 1 then -- 取消寄售
		self:SendSignal(COMMANDS.COMMAND_Market_Cancel, {marketId = data.id})
	elseif checkint(data.status) == 2 then -- 领取
		self:SendSignal(COMMANDS.COMMAND_Market_Draw, {marketId = data.id})
	elseif checkint(data.status) == 3 then -- 取回背包
		self:SendSignal(COMMANDS.COMMAND_Market_GetGoodsBack, {marketId = data.id})
	end

end
--[[
页面切换后刷新ui
--]]
function MarketRecordMediator:SwitchLayerUpdate()
	self:SendSignal(COMMANDS.COMMAND_Market_MyMarket)
end
function MarketRecordMediator:TimeChange( time )
	local hour   = math.floor(time / 3600)
	local minute = math.floor((time - hour*3600) / 60)
	local sec    = (time - hour*3600 - minute*60)
	return string.format("%.2d:%.2d:%.2d", hour, minute, sec)
end
--[[
定时器回调
--]]
function MarketRecordMediator:scheduleCallback()
	for i,v in ipairs(self.myMarketDatas) do
		if v.cdTime and v.cdTime > 0 then
			v.cdTime = v.cdTime - 1
			local viewData = self:GetViewComponent().viewData_
			local cell = viewData.consignmentGridView:cellAtIndex(i-1)
			if cell then
				cell.timeLabel:setString(self:TimeChange(v.cdTime))
			end
			if v.cdTime == 0 then
				v.cdTime = nil 
				v.status = 3
				cell.consignmentAgainBtn:setVisible(true)
				cell.consignmentBtn:getLabel():setString(__('取回背包'))
				cell.timeLabel:setString(__('时间结束'))
			end
		end
	end
end
function MarketRecordMediator:OnRegist(  )
	local MarketRecordCommand = require('Game.command.MarketRecordCommand')
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Market_MyMarket, MarketRecordCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Market_Cancel, MarketRecordCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Market_Draw, MarketRecordCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Market_GetGoodsBack, MarketRecordCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Market_ConsignmentAgain, MarketRecordCommand)

	self:SendSignal(COMMANDS.COMMAND_Market_MyMarket)
end

function MarketRecordMediator:OnUnRegist(  )
	print( "OnUnRegist" )
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Market_MyMarket)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Market_Cancel)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Market_Draw)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Market_GetGoodsBack)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Market_ConsignmentAgain)
	if self.scheduler then
		scheduler.unscheduleGlobal(self.scheduler)
	end
end
return MarketRecordMediator
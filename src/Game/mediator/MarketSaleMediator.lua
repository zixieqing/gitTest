--[[
市场出售模块Mediator
--]]
local Mediator = mvc.Mediator

local MarketSaleMediator = class("MarketSaleMediator", Mediator)

local NAME = "MarketSaleMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance('AppFacade'):GetManager("GameManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
local MarketSaleCell = require('home.MarketSaleCell')
local SALE_TIME_MAX = 20
local MAX_SALE_NUM = 99
function MarketSaleMediator:ctor( viewComponent )
	self.super:ctor(NAME,viewComponent)
	self.selectType = 1
	self.preIndex = 1
	self.saleMax = nil -- 最大寄售数量
	self.saleNum = nil -- 寄售数量
	self.saleLeftNum = nil -- 剩余寄售数量
	self.touPos = cc.p(0,0)
	if isJapanSdk() or isFuntoySdk() or isElexSdk() or isEfunSdk() then
		SALE_TIME_MAX = CommonUtils.getVipTotalLimitByField('sellMaxTime')
		MAX_SALE_NUM = CommonUtils.getVipTotalLimitByField('sellMaxNum')
	end
	self.typeDatas = {
		{name = __('全部'), goodsType = -1}
	}
	local data = CommonUtils.GetConfigAllMess('type', 'goods')
	for k,v in pairs(data) do
		if tonumber(v.canAuction) == 1 then
			table.insert(self.typeDatas, {name = v.type, goodsType = tostring(k)})
		end
	end
	self.selectDatas = {}
end

function MarketSaleMediator:InterestSignals()
	local signals = { 
		SIGNALNAMES.Market_Consignment_Callback,
		SIGNALNAMES.Market_MyMarket_Callback,
		SGL.NEXT_TIME_DATE, 
	}
	return signals
end

function MarketSaleMediator:ProcessSignal( signal )
	local name = signal:GetName() 
	print(name)
	if name == SIGNALNAMES.Market_Consignment_Callback then -- 市场信息
		local datas = checktable(signal:GetBody())
		CommonUtils.DrawRewards({{goodsId = datas.requestData.goodsId, num = -datas.requestData.num}})
		self.saleNum = self.saleNum + 1
		self.saleLeftNum = self.saleLeftNum - 1
		self:GetBackpackDatas()
		self:UpdateUI()
		uiMgr:ShowInformationTips(__('寄售成功'))
	elseif name == SIGNALNAMES.Market_MyMarket_Callback then -- 获取寄售信息
		local datas = checktable(signal:GetBody())
		self.selectType = 1
		self.preIndex = 1
		self.saleMax = datas.sellMax
		self.saleNum = table.nums(datas.myMarket)
		self.saleLeftNum = checkint(datas.consignmentNum)
		
		self:GetBackpackDatas()
		self:UpdateUI()
	elseif name == SGL.NEXT_TIME_DATE then 
		self:SendSignal(COMMANDS.COMMAND_Market_MyMarket)
	end

end


function MarketSaleMediator:Initial( key )
	self.super.Initial(self,key)
	local viewComponent  = require( 'Game.views.MarketSaleView' ).new()
	self:SetViewComponent(viewComponent)
	local viewData = viewComponent.viewData_
	viewData.gridView:setDataSourceAdapterScriptHandler(handler(self, self.GridViewDataSource))
	viewData.selectBtn:setOnClickScriptHandler(handler(self, self.ButtonCallback))
	viewData.minusBtnL:setOnClickScriptHandler(handler(self, self.ButtonCallback))
	viewData.plusBtnR:setOnClickScriptHandler(handler(self, self.ButtonCallback))
	viewData.univalentSelectBtn:setOnClickScriptHandler(handler(self, self.ButtonCallback))
	viewData.consignmentBtn:setOnClickScriptHandler(handler(self, self.ButtonCallback))
	-- 添加触摸事件
	self.touchListener_ = cc.EventListenerTouchOneByOne:create()
    self.touchListener_:registerScriptHandler(handler(self, self.onTouchBegan), cc.Handler.EVENT_TOUCH_BEGAN)
    self.touchListener_:registerScriptHandler(handler(self, self.onTouchMoved), cc.Handler.EVENT_TOUCH_MOVED)
    self.touchListener_:registerScriptHandler(handler(self, self.onTouchEnded), cc.Handler.EVENT_TOUCH_ENDED)
    viewComponent:getEventDispatcher():addEventListenerWithFixedPriority(self.touchListener_, 1)

end

function MarketSaleMediator:GridViewDataSource( p_convertview, idx )
	local pCell = p_convertview
    local index = idx + 1
    if not pCell then
    	local cSize = self:GetViewComponent().viewData_.cellSize
		pCell = MarketSaleCell.new(cSize)
		pCell.toggleView:setOnClickScriptHandler(handler(self, self.GridViewCellCallback))
    end
	xTry(function()
		local data = self.selectDatas[self.selectType][index]
		local goodsData = CommonUtils.GetConfig('goods', 'goods', data.goodsId)
		pCell.goodsIcon:setTexture(CommonUtils.GetGoodsIconPathById(data.goodsId))
		pCell.toggleView:setNormalImage('ui/common/common_frame_goods_' .. goodsData.quality .. '.png')
		pCell.toggleView:setSelectedImage('ui/common/common_frame_goods_' .. goodsData.quality .. '.png')
		pCell.numLabel:setString(tostring(data.amount))
		pCell.toggleView:setTag(index)
		-- 判断是否为卡牌碎片
		if tostring(goodsData.type) == GoodsType.TYPE_CARD_FRAGMENT then
			pCell.fragmentImg:setVisible(true)
		else
			pCell.fragmentImg:setVisible(false)
		end
		-- 判断是否显示选中框
		if index == self.preIndex then
			pCell.selectImg:setVisible(true)
		else
			pCell.selectImg:setVisible(false)
		end
	end,__G__TRACKBACK__)	
	return pCell
end
--[[
更新UI
--]]
function MarketSaleMediator:UpdateUI()
	local viewData = self:GetViewComponent().viewData_
	if viewData.view:getChildByTag(5555) then
		viewData.view:getChildByTag(5555):runAction(cc.RemoveSelf:create())
	end
	if viewData.view:getChildByTag(6666) then
		viewData.view:getChildByTag(6666):runAction(cc.RemoveSelf:create())
	end
	viewData.selectBtn:getLabel():setString(self.typeDatas[self.selectType].name)
	viewData.lastNumLabel:setString(tostring(self.saleLeftNum) .. '/' .. tostring(SALE_TIME_MAX))
	-- 判断商品是否为空
	if table.nums(self.selectDatas[self.selectType]) <= 0 then
		viewData.goodsLayout:setVisible(false)
		viewData.emptyLayout:setVisible(true)
	else
		viewData.goodsLayout:setVisible(true)
		viewData.emptyLayout:setVisible(false)
		viewData.gridView:setCountOfCell(table.nums(self.selectDatas[self.selectType]))
		viewData.gridView:reloadData()
		self:UpdateDescription()
	end
end
--[[
更新物品描述
--]]
function MarketSaleMediator:UpdateDescription( )
	local viewData = self.viewComponent.viewData_
	local data = self.selectDatas[self.selectType][self.preIndex]
	if data then 
		local goodsData = CommonUtils.GetConfig('goods', 'goods', data.goodsId)
		viewData.goodsName:setString(goodsData.name)
		display.commonLabelParams(viewData.goodsName, {text = goodsData.name, reqW = 200})
		viewData.soldNumLabel:setString('1')
		viewData.univalentNumLabel:setString(goodsData.baseAuctionPrice)
		viewData.goodsBg:setTexture('ui/common/common_frame_goods_' .. goodsData.quality .. '.png')
		viewData.goodsIcon:setTexture(CommonUtils.GetGoodsIconPathById(data.goodsId))
		self:UpdateTotalLabel()
	end

end
--[[
列表点击回调
--]]
function MarketSaleMediator:GridViewCellCallback( sender )
	PlayAudioByClickNormal()
	local viewData = self.viewComponent.viewData_
	local gridView = viewData.gridView
    local index = sender:getTag()
	if viewData.view:getChildByTag(6666) then
		viewData.view:getChildByTag(6666):runAction(cc.RemoveSelf:create())
	end
    local cell = gridView:cellAtIndex(index - 1)
    if cell then
        cell.selectImg:setVisible(true)
    end 
    if index == self.preIndex then return end
    --更新按钮状态
    local cell = gridView:cellAtIndex(self.preIndex - 1)
    if cell then
        cell.selectImg:setVisible(false)
    end
    self.preIndex = index
    self.gridContentOffset = gridView:getContentOffset()
    self:UpdateDescription(self.preIndex)
end
--[[
按钮回调
tag {
	2001 -- 类别切换
	2002 -- 数量减
	2003 -- 数量加
	2004 -- 价格选择
	2005 -- 寄售		
}
--]]
function MarketSaleMediator:ButtonCallback( sender )
	PlayAudioByClickNormal()
	local viewData = self.viewComponent.viewData_
	local data = self.selectDatas[self.selectType][self.preIndex]
	-- local goodsData = CommonUtils.GetConfig('goods', 'goods', data.goodsId)
	local tag = sender:getTag()
	if tag == 2001 then
		if viewData.view:getChildByTag(5555) then
			viewData.view:getChildByTag(5555):runAction(cc.RemoveSelf:create())
		else
			local size = cc.size(130, #self.typeDatas * 50)
			local layout = CLayout:create(size)
			viewData.view:addChild(layout, 15)
			layout:setAnchorPoint(cc.p(0, 1))
			layout:setPosition(50, 530)
			layout:setTag(5555)
			local bg = display.newImageView(_res('ui/home/market/market_sold_selection_frame_1.png'), 0, 0, {ap = cc.p(0, 0), scale9 = true, size = size})
			layout:addChild(bg)
			for i,v in ipairs(self.typeDatas) do
				local btn = display.newButton(layout:getContentSize().width/2, layout:getContentSize().height- 50*(i-1), {tag = i, ap = cc.p(0.5, 1), scale9 = true, size = cc.size(130, 50)})
				display.commonLabelParams(btn, fontWithColor(16, {text = self.typeDatas[i].name}))
				layout:addChild(btn)
				btn:setOnClickScriptHandler(handler(self, self.SelectTypeBtnCallback))
				if i < #self.typeDatas then
					local line = display.newImageView(_res('ui/home/cardslistNew/tujian_selection_line.png'), layout:getContentSize().width/2, layout:getContentSize().height - 50*i+25)
					layout:addChild(line)
				end
			end
			layout:setScaleY(0)
			layout:runAction(cc.ScaleTo:create(0.1, 1))
		end
	elseif tag == 2002 then
		local num = tonumber(viewData.soldNumLabel:getString())
		if num > 1 then
			num = num - 1
		end
		viewData.soldNumLabel:setString(tostring(num))
		self:UpdateTotalLabel()
	elseif tag == 2003 then
		local num = tonumber(viewData.soldNumLabel:getString())
		if num < data.amount then
			if num < MAX_SALE_NUM then
				num = num + 1
			else
				uiMgr:ShowInformationTips(string.fmt(__('单次寄售数量不能超过_num_个'), {['_num_'] = MAX_SALE_NUM}))
			end
		end
		viewData.soldNumLabel:setString(tostring(num))
		self:UpdateTotalLabel()
	elseif tag == 2004 then
		local goodsData = CommonUtils.GetConfig('goods', 'goods', data.goodsId)
		local auctionPrice = goodsData.auctionPrice
		if viewData.view:getChildByTag(6666) then
			viewData.view:getChildByTag(6666):runAction(cc.RemoveSelf:create())
		else
			local size = cc.size(190, #auctionPrice * 40)
			local layout = CLayout:create(size)
			viewData.view:addChild(layout, 15)
			layout:setAnchorPoint(cc.p(0, 0))
			layout:setPosition(555, 100)
			layout:setTag(6666)
			local bg = display.newImageView(_res('ui/home/market/market_sold_selection_frame_1.png'), 0, 0, {ap = cc.p(0, 0), scale9 = true, size = size})
			layout:addChild(bg)
			for i,v in ipairs(auctionPrice) do
				local btn = display.newButton(layout:getContentSize().width/2, 40*(i), {tag = i, ap = cc.p(0.5, 1), scale9 = true, size = cc.size(130, 40)})
				display.commonLabelParams(btn, fontWithColor(16, {text = tostring(v)}))
				layout:addChild(btn)
				btn:setOnClickScriptHandler(handler(self, self.SelectPriceBtnCallback))
				if i < #auctionPrice then
					local line = display.newImageView(_res('ui/home/cardslistNew/tujian_selection_line.png'), layout:getContentSize().width/2, 40*i+25)
					layout:addChild(line, 10)
				end
			end
			layout:setScaleY(0)
			layout:runAction(cc.ScaleTo:create(0.1, 1))
		end
	elseif tag == 2005 then
		if self.saleNum < self.saleMax then
			if self.saleLeftNum > 0  then
				local viewData = self.viewComponent.viewData_
				local data = self.selectDatas[self.selectType][self.preIndex]
				local num = tonumber(viewData.soldNumLabel:getString())
				local price = tonumber(viewData.univalentNumLabel:getString())
				if data then
					self:SendSignal(COMMANDS.COMMAND_Market_Consignment, {goodsId = data.goodsId, num = num, price = price, time = 4})
				end
			else
				uiMgr:ShowInformationTips(__('今日寄售次数已耗尽'))
			end
		else
			uiMgr:ShowInformationTips(__('寄售栏位已达上限，请前往售后清理栏位。'))
		end
	end
end
--[[
筛选类别按钮回调
--]]
function MarketSaleMediator:SelectTypeBtnCallback( sender )
	PlayAudioByClickNormal()
	local tag = sender:getTag()
	self.selectType = tag
	self:UpdateUI()
	-- local viewData = self:GetViewComponent().viewData_
	-- viewData.view:getChildByTag(5555):runAction(cc.RemoveSelf:create())
	-- if viewData.view:getChildByTag(6666) then
	-- 	viewData.view:getChildByTag(6666):runAction(cc.RemoveSelf:create())
	-- end
end
--[[
选择价格按钮回调
--]]
function MarketSaleMediator:SelectPriceBtnCallback( sender )
	PlayAudioByClickNormal()
	local tag = sender:getTag()
	local data = self.selectDatas[self.selectType][self.preIndex]
	local goodsData = CommonUtils.GetConfig('goods', 'goods', data.goodsId)
	local viewData = self:GetViewComponent().viewData_
	viewData.univalentNumLabel:setString(tostring(goodsData.auctionPrice[tag]))
	self:UpdateTotalLabel()
	viewData.view:getChildByTag(6666):runAction(cc.RemoveSelf:create())
end
function MarketSaleMediator:GetBackpackDatas()
	self.selectDatas = {}
	for i,v in ipairs(self.typeDatas) do
		table.insert(self.selectDatas, {})
	end
	for _,v in ipairs(gameMgr:GetUserInfo().backpack) do
		if checkint(v.amount) > 0 then
			local goodsData = CommonUtils.GetConfig('goods', 'goods', v.goodsId)
			if goodsData and checkint(goodsData.openLevel) > 0 then
				for i, data in ipairs(self.typeDatas) do
					if data.goodsType == tostring(goodsData.type) then
						table.insert(self.selectDatas[1], v)
						table.insert(self.selectDatas[i], v)
						break
					end
				end
			end
		end
	end
	-- 物品排序
	table.sort(self.selectDatas[1], function (a, b)
		local typeA = nil
		local typeB = nil
		for i,v in ipairs(self.typeDatas) do
			if tostring(CommonUtils.GetConfig('goods', 'goods', a.goodsId).type) == tostring(v.goodsType) then
				typeA = i
			end
			if tostring(CommonUtils.GetConfig('goods', 'goods', b.goodsId).type) == tostring(v.goodsType) then
				typeB = i
			end
		end
		if typeA < typeB then
			return true
		elseif typeA == typeB then
			local qualityA = checkint(CommonUtils.GetConfig('goods', 'goods', a.goodsId).quality)
			local qualityB = checkint(CommonUtils.GetConfig('goods', 'goods', b.goodsId).quality)
			if qualityA	> qualityB then
				return true
			else
				return false
			end
		else
			return false
		end
	end)
	for i,v in ipairs(self.selectDatas) do
		if i > 1 then
			table.sort(v, function (a, b)
				local qualityA = checkint(CommonUtils.GetConfig('goods', 'goods', a.goodsId).quality)
				local qualityB = checkint(CommonUtils.GetConfig('goods', 'goods', b.goodsId).quality)
				if qualityA	> qualityB then
					return true
				else
					return false
				end
			end)
		end
	end
end
--[[
页面切换后刷新ui
--]]
function MarketSaleMediator:SwitchLayerUpdate()
	self:SendSignal(COMMANDS.COMMAND_Market_MyMarket)
end
function MarketSaleMediator:UpdateTotalLabel()
	local viewData = self:GetViewComponent().viewData_
	local total = tonumber(viewData.soldNumLabel:getString()) * tonumber(viewData.univalentNumLabel:getString())
	display.commonLabelParams(viewData.totalPriceLabel ,{text =string.fmt(__('总价:_num_'), {['_num_'] = tostring(total)}) , reqW = 210 })
end

function MarketSaleMediator:onTouchBegan(touch, event)
	local viewData = self:GetViewComponent().viewData_
	local point = touch:getLocation()
	self.touPos = point
	for i,btn in ipairs(viewData.changeNumBtn) do
		local btnAddRect = btn:getBoundingBox()
		if cc.rectContainsPoint(btnAddRect,viewData.view:convertToNodeSpace(point))then
			local actionSeq = cc.Sequence:create(
			cc.DelayTime:create(0.5),
			cc.CallFunc:create(function ()
				if cc.rectContainsPoint(btnAddRect,viewData.view:convertToNodeSpace(self.touPos))then
					self:GetViewComponent():stopAllActions()
    				local action = cc.Sequence:create(
						cc.CallFunc:create(function ()
							local data = self.selectDatas[self.selectType][self.preIndex]
							local num = tonumber(viewData.soldNumLabel:getString())
							if i == 1 then
								-- 减
								if num > 1 then
									num = num - 1
									viewData.soldNumLabel:setString(tostring(num))
									self:UpdateTotalLabel()
								end
							elseif i == 2 then
								-- 加
								if num < data.amount then
									if num < MAX_SALE_NUM then
										num = num + 1
										viewData.soldNumLabel:setString(tostring(num))
										self:UpdateTotalLabel()
									else
										uiMgr:ShowInformationTips(string.fmt(__('单次寄售数量不能超过_num_个'), {['_num_'] = MAX_SALE_NUM}))
									end
								end
							end
						end),
						cc.DelayTime:create(0.05)
					)
					self:GetViewComponent():runAction(cc.RepeatForever:create(action))
				else

				end
			end))
			self:GetViewComponent():runAction( actionSeq ) 
			return true
		end
	end
end

function MarketSaleMediator:onTouchMoved(touch, event)
	local point = touch:getLocation()
	self.touPos = point
end

function MarketSaleMediator:onTouchEnded(touch, event)
	self:GetViewComponent():stopAllActions()
	
end
function MarketSaleMediator:OnRegist(  )
	local MarketSaleCommand = require('Game.command.MarketSaleCommand')
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Market_Consignment, MarketSaleCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Market_MyMarket, MarketSaleCommand)
	self:SendSignal(COMMANDS.COMMAND_Market_MyMarket)
end

function MarketSaleMediator:OnUnRegist(  )
	print( "OnUnRegist" )
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Market_Consignment)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Market_MyMarket)
	if self.touchListener_ then
		self:GetViewComponent():getEventDispatcher():removeEventListener(self.touchListener_)
		self.touchListener_ = nil
	end
end
return MarketSaleMediator
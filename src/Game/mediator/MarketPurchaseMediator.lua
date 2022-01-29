--[[
市场购买模块Mediator
--]]
local Mediator = mvc.Mediator

local MarketPurchaseMediator = class("MarketPurchaseMediator", Mediator)

local NAME = "MarketPurchaseMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance('AppFacade'):GetManager("GameManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
local marketPurchaseCell = require('home.MarketPurchaseCell')
local marketPageViewCell = require('home.MarketPageViewCell')
local scheduler = require('cocos.framework.scheduler')

function MarketPurchaseMediator:ctor( params, viewComponent )
	self.super:ctor(NAME,viewComponent)
	self.pageSize = nil
	self.currentpage = 1
	-- self.marketDatas = {} -- 所有数据
	self.selectDatas = {} -- 筛选数据
	self.selectType = 1 -- 筛选类型
	self.findDatas = {} -- 查找数据
	self.isFind = false -- 是否查找
	self.findStr = nil -- 查找内容
	self.refreshCD = nil -- 自动刷新cd
	self.refreshTimes = nil -- 剩余刷新次数
	self.maxPages = 0 -- 最大页数

	self.typeDatas = {
		{name = __('全部'), goodsType = -1}
	}
	local data = CommonUtils.GetConfigAllMess('type', 'goods')
	for k,v in pairs(data) do
		if tonumber(v.canAuction) == 1 then
			table.insert(self.typeDatas, {name = v.type, goodsType = tostring(k)})
		end
	end
end

function MarketPurchaseMediator:InterestSignals()
	local signals = {
		SIGNALNAMES.Market_Market_Callback,
		SIGNALNAMES.Market_Purchase_Callback,
		SIGNALNAMES.Market_Refresh_Callback,
		MARKET_GOODSSALE,
		"MARKET_ONE_KEY_PURCHASE"
	}
	return signals
end

function MarketPurchaseMediator:ProcessSignal( signal )
	local name = signal:GetName()
	print(name)
	if name == SIGNALNAMES.Market_Market_Callback then -- 市场信息
		local datas = checktable(signal:GetBody())
		local marketDatas = {}
		self.selectDatas = {}
		-- 分类
		for i,v in ipairs(self.typeDatas) do
			table.insert(self.selectDatas, {})
		end

		for k,v in pairs(datas.market) do
			for _,v2 in pairs(v) do
				local temp = string.split(v2, ',')
				table.insert(marketDatas, {
					id = tonumber(temp[1]),
					goodsId = tonumber(temp[2]),
					num = tonumber(temp[3]),
					price = tonumber(temp[4]),
					marketType = temp[5],
					status = tonumber(temp[6])
				})
			end
		end
		self.selectDatas[1] = marketDatas
		for i, v in ipairs(marketDatas) do
			for i2, v2 in ipairs(self.typeDatas) do
				if tostring(v.marketType) == v2.goodsType then
					table.insert(self.selectDatas[i2], v)
				end
			end
		end
		self.refreshCD = datas.refreshCD
		self.refreshTimes = checkint(datas.refreshTimes)
		self:UpdateUI()

		app:DispatchObservers("MARKET_GOOD_CHANGE", self.selectDatas)
	elseif name == SIGNALNAMES.Market_Purchase_Callback then -- 购买
		local datas = checktable(signal:GetBody())
		local deltaGold = checkint(datas.gold) - checkint(gameMgr:GetUserInfo().gold)
		CommonUtils.DrawRewards({{goodsId = GOLD_ID, num = deltaGold}})

		local markets = datas.markets or {}
		local marketType = datas.requestData.marketType
		local marketTypeList = string.split(marketType, ',') or {}
		
		local marketTypeMap = {}
		for index, value in ipairs(marketTypeList) do
			marketTypeMap[tostring(value)] = value
		end

		local marketId = checkint(datas.requestData.marketId)
		local goodList = {}
		-- 如果是一键购买
		if marketId == 0 then
			-- 一键购买的话 请求时传入的寄售类型 必被全部购买
			for i,v in ipairs(self.selectDatas[1]) do
				if marketTypeMap[tostring(v.marketType)] then
					v.status = 2
				end
			end
		else
			for i,v in ipairs(self.selectDatas[1]) do
				if marketTypeMap[tostring(v.marketType)] and marketId == v.id then
					v.status = 2
				end
			end
		end

		-- 购买失败个数
		local failCount = 0
		-- 遍历传入的类型
		for index, value in ipairs(marketTypeList) do
			local marketIdList = markets[value]
			if marketIdList and next(marketIdList) ~= nil then
				for t, typeData in ipairs(self.typeDatas) do
					if checkint(typeData.goodsType) == checkint(value) then
						for _, marketData in ipairs(self.selectDatas[t]) do
							local purchaseSucess = false
							for _, marketId_ in ipairs(marketIdList) do
								if checkint(marketData.id) == checkint(marketId_) then
									table.insert(goodList, {goodsId = marketData.goodsId, num = marketData.num})
									purchaseSucess = true
									break
								end	
							end

							if marketId == 0 or purchaseSucess then
								marketData.status = 2
							end
							-- 如果是单独购买的话 购买成功直接退出循环
							if marketId > 0 and purchaseSucess then
								break
							end
						end
						break
					end
				end
			else
				failCount = failCount + 1
				-- 不存在或者列表没数据 即为 购买失败  则把该类型的所有道具状态改变为2
				for t, typeData in ipairs(self.typeDatas) do
					if checkint(typeData.goodsType) == checkint(value) then
						for _, marketData in ipairs(self.selectDatas[t]) do
							if marketId == 0 then
								marketData.status = 2
							elseif checkint(marketData.id) == marketId then
								marketData.status = 2
								break
							end
						end
						break
					end
				end
			end
		end

		if next(goodList) then
			uiMgr:AddDialog('common.RewardPopup', {rewards = goodList})
		-- 购买失败的个数 等于 请求类型列表数
		elseif failCount == table.nums(marketTypeList) then
			uiMgr:ShowInformationTips(__("所选商品已售出，无法购买。"))
		end

		-- 更新ui
		local viewData = self:GetViewComponent().viewData_
		viewData.pageView:reloadData()

	elseif name == SIGNALNAMES.Market_Refresh_Callback then -- 刷新
		self.refreshTimes = self.refreshTimes - 1
		-- 刷新本地数据
		CommonUtils.DrawRewards({{goodsId = DIAMOND_ID, num = -10}})
		self:GetFacade():DispatchObservers(SIGNALNAMES.CACHE_MONEY_UPDATE_UI,{diamond = gameMgr:GetUserInfo().diamond})
		local datas = checktable(signal:GetBody())
		local marketDatas = {}
		self.selectDatas = {}
		-- 分类
		for i,v in ipairs(self.typeDatas) do
			table.insert(self.selectDatas, {})
		end

		for k,v in pairs(datas.newMarket) do
			for _,v2 in pairs(v) do
				local temp = string.split(v2, ',')
				table.insert(marketDatas, {
					id = tonumber(temp[1]),
					goodsId = tonumber(temp[2]),
					num = tonumber(temp[3]),
					price = tonumber(temp[4]),
					marketType = temp[5],
					status = tonumber(temp[6])
				})
			end
		end
		self.selectDatas[1] = marketDatas
		for i, v in ipairs(marketDatas) do
			for i2, v2 in ipairs(self.typeDatas) do
				if tostring(v.marketType) == v2.goodsType then
					table.insert(self.selectDatas[i2], v)
				end
			end
		end
		self.selectType = 1
		self:UpdateUI()

	elseif name == MARKET_GOODSSALE then -- 食物售出的通知
		local datas = checktable(signal:GetBody())
		if next(checktable(self.selectDatas)) == nil then
			return
		end

		local markets = datas.markets or {}
		for i,v in ipairs(self.selectDatas[1]) do
			for key, value in ipairs(markets) do
				local marketId = tonumber(value.marketId)
				local marketType = tonumber(value.marketType)
				if v.id == marketId and tonumber(v.marketType) == marketType then
					-- 修改分类中的status
					for t, typeData in ipairs(self.typeDatas) do
						if tonumber(typeData.goodsType) == marketType then
							for _, marketData in ipairs(self.selectDatas[t]) do
								if tonumber(marketData.id) == marketId then
									marketData.status = 2
									break
								end
							end
							break
						end
					end
					v.status = 2
					break
				end
			end
		end

		app:DispatchObservers("MARKET_GOOD_CHANGE", self.selectDatas)

	elseif name == "MARKET_ONE_KEY_PURCHASE" then
		local datas = checktable(signal:GetBody())
		local selectIndexs = datas.selectIndexs
		local marketTypeList = {}
		for index, value in pairs(selectIndexs) do
			table.insert(marketTypeList, self.typeDatas[index].goodsType)
		end
	
		self:SendSignal(COMMANDS.COMMAND_Market_Purchase, {marketId = 0, marketType = table.concat(marketTypeList, ',')})
	end
	-- 更新ui
	local viewData = self:GetViewComponent().viewData_
	viewData.pageView:reloadData()
end


function MarketPurchaseMediator:Initial( key )
	self.super.Initial(self,key)
	local viewComponent  = require( 'Game.views.MarketPurchaseView' ).new()
	self:SetViewComponent(viewComponent)
	local viewData = viewComponent.viewData_
	self.pageSize = viewData.pageSize
	viewData.pageView:setOnPageChangedScriptHandler(handler(self,self.PurchasePageViewChangedHandler))
	viewData.pageView:setDataSourceAdapterScriptHandler(handler(self, self.PurchasePageViewDataSource))

	viewData.pageUpBtn:setOnClickScriptHandler(handler(self, self.PageChangeBtnCallback))
	viewData.pageDownBtn:setOnClickScriptHandler(handler(self, self.PageChangeBtnCallback))
	viewData.refreshBtn:setOnClickScriptHandler(handler(self, self.RefreshBtnCallback))
	viewData.selectBtn:setOnClickScriptHandler(handler(self, self.SelectBtnCallback))
	viewData.editBox:registerScriptEditBoxHandler(handler(self, self.EditboxEventHandler))
	viewData.deleteBtn:setOnClickScriptHandler(handler(self, self.DeleteBtnCallback))
	viewData.oneKeyPurchaseBtn:setOnClickScriptHandler(handler(self, self.OneKeyPurchaseBtnCallback))
	self.scheduler = scheduler.scheduleGlobal(handler(self, self.scheduleCallback), 1)
end
--[[
更新ui
--]]
function MarketPurchaseMediator:UpdateUI()
	local viewData = self:GetViewComponent().viewData_
	if self.isFind then
		self.findDatas = {}
		for i,v in ipairs(self.selectDatas[self.selectType]) do
			local goodsData = CommonUtils.GetConfig('goods', 'goods', v.goodsId)
			if string.find(goodsData.name, self.findStr) then
				table.insert(self.findDatas, v)
			end
		end
		self.maxPages = math.ceil(table.nums(self.findDatas) / 12)
		viewData.deleteBtn:setVisible(true)
	else
		self.maxPages = math.ceil(table.nums(self.selectDatas[self.selectType]) / 12)
		viewData.deleteBtn:setVisible(false)
	end
	viewData.pageView:setCountOfCell(self.maxPages)
	viewData.pageView:reloadData()
	viewData.pageLabel:setString('1/' .. tostring(self.maxPages))
	viewData.refreshTimeLabel:setString(self:TimeChange(self.refreshCD))
	--viewData.selectBtn:getLabel():setString(self.typeDatas[self.selectType].name)
	display.commonLabelParams(viewData.selectBtn:getLabel() , {text = self.typeDatas[self.selectType].name , w = 120 , reqW =110,  hAlign= display.TAC })
	self.currentpage = 1
	viewData.pageView:setContentOffset(cc.p(0, 0))
end
function MarketPurchaseMediator:PurchasePageViewChangedHandler( sender, idx )
	-- self.currentpage = idx
	local viewData = self:GetViewComponent().viewData_
	-- 翻页限制
	viewData.pageUpBtn:setEnabled(true)
	viewData.pageDownBtn:setEnabled(true)
	if idx == 0 then
		viewData.pageUpBtn:setEnabled(false)
	elseif idx == self.maxPages-1 then
		viewData.pageDownBtn:setEnabled(false)
	end
	-- 更改页码
	viewData.pageLabel:setString(tostring(idx+1) .. '/' .. tostring(self.maxPages))
end

function MarketPurchaseMediator:PurchasePageViewDataSource( p_convertview, idx )
	local pCell = p_convertview
    local index = idx + 1
    if not pCell then
        pCell = marketPageViewCell.new(self.pageSize)
	end
    xTry(function()
		-- 确定
		local gridViewDatas = {}
		if index < self.maxPages then
			for i=(index-1)*12+1, index*12, 1 do
				if self.isFind then
					table.insert(gridViewDatas, self.findDatas[i])
				else
					table.insert(gridViewDatas, self.selectDatas[self.selectType][i])
				end
			end
		else
			if self.isFind then
				for i=(index-1)*12+1, table.nums(self.findDatas), 1 do
					table.insert(gridViewDatas, self.findDatas[i])
				end
			else
				for i=(index-1)*12+1, table.nums(self.selectDatas[self.selectType]), 1 do
					table.insert(gridViewDatas, self.selectDatas[self.selectType][i])
				end
			end

		end
		pCell:ReloadGridView(gridViewDatas)

    end,__G__TRACKBACK__)
    return pCell
end
--[[
页面切换按钮回调
--]]
function MarketPurchaseMediator:PageChangeBtnCallback( sender )
	PlayAudioByClickNormal()
	local tag = sender:getTag()
	local viewData = self:GetViewComponent().viewData_
	local pageView = viewData.pageView
	if tag == 1101 then -- 上翻
		if self.currentpage > 1 then
			self.currentpage = self.currentpage - 1
			pageView:getContainer():stopAllActions()
			pageView:setContentOffsetInDuration({x = -self.pageSize.width*(self.currentpage - 1), y = 0}, 0.3)
		end
	elseif tag == 1102 then -- 下翻
		if self.currentpage < self.maxPages then
			self.currentpage = self.currentpage + 1
			pageView:getContainer():stopAllActions()
			pageView:setContentOffsetInDuration({x = -self.pageSize.width*(self.currentpage - 1), y = 0}, 0.3)
		end
	end
end
function MarketPurchaseMediator:PurchaseEvent( data )
	dump(data)
    local needGoldNum = checkint(checktable(data.price))
    if checkint(gameMgr:GetUserInfo().gold) >= needGoldNum then
        self:SendSignal(COMMANDS.COMMAND_Market_Purchase, {marketId = data.id, marketType = data.marketType})
        local scene = uiMgr:GetCurrentScene()
        if scene:GetDialogByTag( 5001 ) then
            scene:GetDialogByTag( 5001 ):runAction(cc.RemoveSelf:create())
        end
    else
        uiMgr:ShowInformationTips(__('您的当前金币不足，请保证金币充足再进行尝试'))
    end
end
--[[
筛选按钮回调
--]]
function MarketPurchaseMediator:SelectBtnCallback( sender )
	PlayAudioByClickNormal()
	local viewData = self:GetViewComponent().viewData_
	if viewData.view:getChildByTag(5555) then
		viewData.view:getChildByTag(5555):runAction(cc.RemoveSelf:create())
	else
		local size = cc.size(180, #self.typeDatas * 50)
		local layout = CLayout:create(size)
		viewData.view:addChild(layout, 15)
		layout:setAnchorPoint(cc.p(0.5, 1))
		layout:setPosition(145, 530)
		layout:setTag(5555)
		local bg = display.newImageView(_res('ui/home/market/market_sold_selection_frame_1.png'), 0, 0, {ap = cc.p(0, 0), scale9 = true, size = size})
		layout:addChild(bg)
		for i,v in ipairs(self.typeDatas) do
			local btn = display.newButton(layout:getContentSize().width/2, layout:getContentSize().height - 50*(i-1), {tag = i, ap = cc.p(0.5, 1), scale9 = true, size = cc.size(130, 50)})
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

end
--[[
筛选类别按钮回调
--]]
function MarketPurchaseMediator:SelectTypeBtnCallback( sender )
	PlayAudioByClickNormal()
	local tag = sender:getTag()
	self.selectType = tag
	self:UpdateUI()
	local viewData = self:GetViewComponent().viewData_
	viewData.view:getChildByTag(5555):runAction(cc.RemoveSelf:create())
end
--[[
清空按钮回调
--]]
function MarketPurchaseMediator:DeleteBtnCallback( sender )
	PlayAudioByClickNormal()
	self.findStr = nil
	self.isFind = false
	local viewData = self:GetViewComponent().viewData_
	viewData.editBox:setText('')
	viewData.deleteBtn:setVisible(false)
	self:UpdateUI()
end
--[[
输入框事件回调
--]]
function MarketPurchaseMediator:EditboxEventHandler( eventType )
	if eventType == 'ended' then
		local viewData = self:GetViewComponent().viewData_
		local str = viewData.editBox:getText()
		if str == '' then
			self.isFind = false
			self.findStr = nil
			viewData.deleteBtn:setVisible(false)
		else -- 搜索
			self.isFind = true
			self.findStr = str
			viewData.deleteBtn:setVisible(true)
		end
		self:UpdateUI()
	end
end
--[[
刷新按钮事件回调
--]]
function MarketPurchaseMediator:RefreshBtnCallback( sender )
	-- PlayAudioByClickNormal()
	if gameMgr:GetUserInfo().diamond >= 10 then
		if self.refreshTimes > 0 then
			local CommonTip  = require( 'common.NewCommonTip' ).new({text = __('确定消耗10幻晶石刷新吗？'),
				extra = string.fmt(__('      (今日还有_num_次刷新次数)'), {['_num_'] = self.refreshTimes}),
 				isOnlyOK = false, callback = function ()
					self:SendSignal(COMMANDS.COMMAND_Market_Refresh)
				end,
				cancelBack = function ()
				end
			})

			CommonTip:setPosition(display.center)
			CommonTip.tip:setPosition(CommonTip.size.width /2 , CommonTip.size.height - 50 )
			if CommonTip.extra then
				CommonTip.extra:setPosition(CommonTip.size.width /2 , CommonTip.size.height - 150)
			end
			local scene = uiMgr:GetCurrentScene()
			scene:AddDialog(CommonTip)
		else
			uiMgr:ShowInformationTips(__('今天的刷新次数已用完'))
		end
	else
		if GAME_MODULE_OPEN.NEW_STORE then
			app.uiMgr:showDiamonTips()
		else
			local CommonTip  = require( 'common.NewCommonTip' ).new({text = __('幻晶石不足是否去商城购买？'),
				isOnlyOK = false, callback = function ()
					app.router:Dispatch({name = "HomeMediator"}, {name = "ShopMediator"})
				end})
			CommonTip:setPosition(display.center)
			app.uiMgr:GetCurrentScene():AddDialog(CommonTip)
		end
	end
end
function MarketPurchaseMediator:TimeChange( time )
	local hour   = math.floor(time / 3600)
	local minute = math.floor((time - hour*3600) / 60)
	local sec    = (time - hour*3600 - minute*60)
	return string.format("%.2d:%.2d:%.2d", hour, minute, sec)
end
--[[
定时器回调
--]]
function MarketPurchaseMediator:scheduleCallback()
	if self.refreshCD and self.refreshCD > 0 then
		self.refreshCD = self.refreshCD - 1
		local viewData = self:GetViewComponent().viewData_
		viewData.refreshTimeLabel:setString(self:TimeChange(self.refreshCD))
	end
	if self.refreshCD and self.refreshCD <= 0 then
		self:SendSignal(COMMANDS.COMMAND_Market_Market)
	end
end

--[[
	一键购买按钮回调
--]]
function MarketPurchaseMediator:OneKeyPurchaseBtnCallback( sender )
	PlayAudioByClickNormal()
	
	local scene = uiMgr:GetCurrentScene() 
	local marketPurchasePopup  = require('Game.views.MarketOneKeyPurchasePopup').new({
		tag = 5001, mediatorName = "MarketPurchaseMediator", typeDatas = self.typeDatas, categoryDatas = self.selectDatas})
	display.commonUIParams(marketPurchasePopup, {ap = cc.p(0.5, 0.5), po = cc.p(display.width * 0.5, display.height * 0.5)})
	marketPurchasePopup:setTag(5001)
	scene:AddDialog(marketPurchasePopup)
end

function MarketPurchaseMediator:GoodsSale()

end
function MarketPurchaseMediator:OnRegist(  )
	local MarketPurchaseCommand = require('Game.command.MarketPurchaseCommand')
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Market_Market, MarketPurchaseCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Market_Purchase, MarketPurchaseCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Market_Refresh, MarketPurchaseCommand)
	self:SendSignal(COMMANDS.COMMAND_Market_Market)

end

function MarketPurchaseMediator:OnUnRegist(  )
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Market_Market)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Market_Purchase)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Market_Refresh)
	if self.scheduler then
		scheduler.unscheduleGlobal(self.scheduler)
	end
	AppFacade.GetInstance():DispatchObservers(SGL.BREAK_TO_HOME_MEDIATOR)
end
return MarketPurchaseMediator

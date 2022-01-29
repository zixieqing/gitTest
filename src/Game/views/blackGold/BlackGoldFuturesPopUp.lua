--[[
活动每日签到Cell
--]]
---@class BlackGoldFuturesPopUp
local BlackGoldFuturesPopUp = class('BlackGoldFuturesPopUp', function ()
	local BlackGoldFuturesPopUp = CLayout:create(display.size)
	BlackGoldFuturesPopUp.name = 'home.BlackGoldFuturesPopUp'
	BlackGoldFuturesPopUp:enableNodeEvents()
	return BlackGoldFuturesPopUp
end)
local newImageView = display.newImageView
local newLabel = display.newLabel
local newButton = display.newButton
local newLayer = display.newLayer
----@type CommerceConfigParser
local CommerceConfigParser = require("Game.Datas.Parser.CommerceConfigParser")
local futuresConf = CommonUtils.GetConfigAllMess(CommerceConfigParser.TYPE.FUTURES , 'commerce')
local RES_DICT = {
	MARKET_SOLD_BG_GOODS_INFO     = _res('ui/home/commonShop/market_sold_bg_goods_info.png'),
	COMMON_BG_TITLE_2             = _res('ui/common/common_bg_title_2.png'),
	MARKET_SOLD_BTN_PLUS          = _res('avatar/ui/market_sold_btn_plus.png'),
	GOODS_ICON_900026             = _res('arts/goods/goods_icon_900026.png'),
	MARKET_SOLD_BTN_SUB           = _res('avatar/ui/market_sold_btn_sub.png'),
	KITCHEN_TOOL_SPLIT_LINE       = _res('ui/common/kitchen_tool_split_line.png'),
	COMMON_BG_7                   = _res('ui/common/common_bg_7.png'),
	COMMON_BTN_ORANGE             = _res('ui/common/common_btn_orange.png'),
	GOLD_TRADE_WARE_BUY_KUANG     = _res('ui/home/blackShop/gold_trade_ware_buy_kuang.png'),
}

function BlackGoldFuturesPopUp:ctor(param)
	local param = param or {}
	self.callback = param.callback
	self.limitNum = 100 -- 上限
	local view = newLayer(display.cx, display.cy,{ap = display.CENTER, size = display.size})
	local closeLayer = newLayer(667, 375,
			{ ap = display.CENTER, color = cc.c4b(0 ,0,0,175), size = cc.size(display.width, display.height), enable = true , cb = function()
			  self:removeFromParent()
	end })
	closeLayer:setPosition(display.cx + 0, display.cy + 0)
	view:addChild(closeLayer)
	self:addChild(view)

	local contentLayer = newLayer(666, 359,
			{ ap = display.CENTER, size = cc.size(558, 539) })
	contentLayer:setPosition(display.cx + -1, display.cy + -16)
	view:addChild(contentLayer)

	local bgImage = newImageView(RES_DICT.COMMON_BG_7, 0, 0,
			{ ap = display.LEFT_BOTTOM, tag = 164, enable = false })
	contentLayer:addChild(bgImage)

	local lineImage = newImageView(RES_DICT.KITCHEN_TOOL_SPLIT_LINE, 278, 277,
			{ ap = display.CENTER, tag = 175, enable = false })
	contentLayer:addChild(lineImage)
	lineImage:setScale(0.82)

	local swallowLayer = newLayer(1, 0,
			{ ap = display.LEFT_BOTTOM, color = cc.r4b(0), size = cc.size(558, 539), enable = true })
	contentLayer:addChild(swallowLayer)

	local titleBtn = newButton(278, 517, { ap = display.CENTER ,  n = RES_DICT.COMMON_BG_TITLE_2, d = RES_DICT.COMMON_BG_TITLE_2, s = RES_DICT.COMMON_BG_TITLE_2, scale9 = true, size = cc.size(256, 36), tag = 166 })
	display.commonLabelParams(titleBtn, {text = '', fontSize = 24, color = '#ffffff'})
	contentLayer:addChild(titleBtn)

	local goodsImage = newImageView(RES_DICT.GOODS_ICON_900026, 113, 400,
			{ ap = display.CENTER, tag = 167, enable = false })
	contentLayer:addChild(goodsImage)
	goodsImage:setScale(0.8)

	local goodName = newLabel(113, 316,
			{ ap = display.CENTER, color = '#6c4a31', text = "", fontSize = 24, tag = 168 })
	contentLayer:addChild(goodName)

	local oneLabel = newLabel(190, 202,
			{ ap = display.RIGHT_CENTER, color = '#6c4a31', text = "", fontSize = 24, tag = 169 })
	contentLayer:addChild(oneLabel)

	local numBgImage = newImageView(RES_DICT.GOLD_TRADE_WARE_BUY_KUANG, 317, 206,
			{ ap = display.CENTER, tag = 181, enable = false })
	contentLayer:addChild(numBgImage)
	numBgImage:setScaleX(0.81)
	numBgImage:setScaleY(0.88)

	local kuangNum_0 = cc.Label:createWithBMFont('font/common_num_1.fnt', 0)
	kuangNum_0:setAnchorPoint(display.LEFT_CENTER)
	kuangNum_0:setHorizontalAlignment(display.TAR)
	kuangNum_0:setPosition(215, 206)
	contentLayer:addChild(kuangNum_0)


	local twoLabel = newLabel(190, 141,
			{ ap = display.RIGHT_CENTER, color = '#6c4a31', text = "", fontSize = 24, tag = 170 })
	contentLayer:addChild(twoLabel)

	local priceImage = newImageView(RES_DICT.GOODS_ICON_900026, 399, 206,
			{ ap = display.CENTER, tag = 182, enable = false })
	contentLayer:addChild(priceImage)
	priceImage:setScale(0.2)

	local cells = {}
	for i = 1 , 3 do
		local oneCell = newImageView(RES_DICT.GOLD_TRADE_WARE_BUY_KUANG, 342 , 431-(i - 1) * 50,
				{ ap = display.CENTER, tag = 171, enable = false })
		contentLayer:addChild(oneCell)

		local leftLabel = newLabel(12, 22,
				{ ap = display.LEFT_CENTER, color = '#6c4a31', text = "", fontSize = 24, tag = 1 })
		oneCell:addChild(leftLabel)

		local rightLabel = newLabel(274, 22,
				{ ap = display.RIGHT_CENTER, color = '#6c4a31', text = "", fontSize = 24, tag = 2 })
		oneCell:addChild(rightLabel)

		local iconImage = newImageView(RES_DICT.GOODS_ICON_900026, 300, 21,
				{ ap = display.CENTER, tag = 3, enable = false })
		oneCell:addChild(iconImage)
		iconImage:setScale(0.2)
		iconImage:setVisible(false)
		cells[#cells+1] = oneCell
	end
	local kuangBtn = newButton(317, 143, { ap = display.CENTER ,  n = RES_DICT.MARKET_SOLD_BG_GOODS_INFO, d = RES_DICT.MARKET_SOLD_BG_GOODS_INFO, s = RES_DICT.MARKET_SOLD_BG_GOODS_INFO, scale9 = true, size = cc.size(184, 49), tag = 177 })
	display.commonLabelParams(kuangBtn, {text = "", fontSize = 22, color = '#ec1818'})
	contentLayer:addChild(kuangBtn)
	kuangBtn:setScaleX(0.73)

	local addBtn = newButton(407, 141, { ap = display.CENTER ,  n = RES_DICT.MARKET_SOLD_BTN_PLUS, d = RES_DICT.MARKET_SOLD_BTN_PLUS, s = RES_DICT.MARKET_SOLD_BTN_PLUS, scale9 = true, size = cc.size(52, 53), tag = 178 })
	display.commonLabelParams(addBtn, {text = "", fontSize = 22, color = '#ec1818'})
	contentLayer:addChild(addBtn)

	local subBtn = newButton(226, 142, { ap = display.CENTER ,  n = RES_DICT.MARKET_SOLD_BTN_SUB, d = RES_DICT.MARKET_SOLD_BTN_SUB, s = RES_DICT.MARKET_SOLD_BTN_SUB, scale9 = true, size = cc.size(52, 53), tag = 179 })
	display.commonLabelParams(subBtn, {text = "", fontSize = 22, color = '#ec1818'})
	contentLayer:addChild(subBtn)

	local kuangNum = cc.Label:createWithBMFont('font/common_num_1.fnt', 0)
	kuangNum:setAnchorPoint(display.CENTER)
	kuangNum:setHorizontalAlignment(display.TAR)
	kuangNum:setPosition(314, 143)
	contentLayer:addChild(kuangNum)

	local doBtn = newButton(275, 62, { ap = display.CENTER ,  n = RES_DICT.COMMON_BTN_ORANGE, d = RES_DICT.COMMON_BTN_ORANGE, s = RES_DICT.COMMON_BTN_ORANGE, scale9 = true, size = cc.size(123, 62), tag = 184 })
	display.commonLabelParams(doBtn, fontWithColor(14,{ text = "", fontSize = 24, color = '#ffffff'}))
	display.commonUIParams(doBtn , {cb = handler(self, self.DoBack)})
	contentLayer:addChild(doBtn)
	self.viewData = {
		closeLayer              = closeLayer,
		contentLayer            = contentLayer,
		bgImage                 = bgImage,
		lineImage               = lineImage,
		swallowLayer            = swallowLayer,
		titleBtn                = titleBtn,
		goodsImage              = goodsImage,
		goodName                = goodName,
		oneLabel                = oneLabel,
		numBgImage              = numBgImage,
		kuangNum_0              = kuangNum_0,
		twoLabel                = twoLabel,
		priceImage              = priceImage,
		kuangBtn                = kuangBtn,
		cells                = cells,
		addBtn                  = addBtn,
		subBtn                  = subBtn,
		kuangNum                = kuangNum,
		doBtn                   = doBtn,
	}
end

function BlackGoldFuturesPopUp:UpdateBuyFutures(data)
	self.data = data
	self.limitNum =checkint(data.leftPurchase)
	local wareHouseGrade = app.blackGoldMgr:GetWarehouseGrade()
	local wareHouseGradeConf = CommonUtils.GetConfigAllMess(CommerceConfigParser.TYPE.WAREHOUSE , 'commerce')
	local capacity = checkint(wareHouseGradeConf[tostring(wareHouseGrade)].capacity)
	local cellTable = {
		{ text = __('库存：') , num = data.leftPurchase , iconVisible = false  } ,
		{ text = __('仓储：') , num = data.count ..  "/" .. capacity  , iconVisible = false  } ,
		{ text = __('单价：') , num = data.price , iconVisible = true  } ,
	}
	local viewData = self.viewData
	local cells = viewData.cells
	for i = 1 , #cells do
		local cell = cells[i]
		local leftLabel = cell:getChildByTag(1)
		local rightLabel = cell:getChildByTag(2)
		local iconImage = cell:getChildByTag(3)
		leftLabel:setString(cellTable[i].text)
		rightLabel:setString(cellTable[i].num)
		iconImage:setVisible(cellTable[i].iconVisible)
	end
	viewData.oneLabel:setString(__('售价'))
	viewData.twoLabel:setString(__('购买数量'))
	viewData.kuangNum:setString("1")
	viewData.kuangNum_0:setString(tostring(data.price ))
	viewData.titleBtn:getLabel():setString(__('购买'))
	viewData.doBtn:getLabel():setString(__('购买'))
	viewData.goodsImage:setTexture(app.blackGoldMgr:GetFuturesPtahByFutureId(data.futuresId))
	local name = futuresConf[tostring(data.futuresId)].name
	viewData.goodName:setString(name)
	display.commonUIParams(viewData.addBtn, { cb = function(sender)
		local num = checkint(viewData.kuangNum:getString())
		num = num +1
		if num > checkint(self.limitNum) then
			app.uiMgr:ShowInformationTips(__('已经超过了购买上限！！！'))
			return
		end
		local count = data.count + 1
		if count > checkint(capacity) then
			app.uiMgr:ShowInformationTips(__('已达仓库容量上限'))
			return
		end
		data.count = count
		viewData.kuangNum:setString(tostring(num))
		self:UpdatePriceLabel(data.price , num)
		self:UpdateWareHouseLabel(data.count , capacity)
	end})
	display.commonUIParams(viewData.subBtn , {cb = function(sender)
		local num = checkint(viewData.kuangNum:getString())
		num = num - 1
		if num <= 0  then
			app.uiMgr:ShowInformationTips(__('最少购买一个！！！'))
			return
		end
		data.count = data.count - 1
		viewData.kuangNum:setString(tostring(num))
		self:UpdatePriceLabel(data.price , num)
		self:UpdateWareHouseLabel(data.count , capacity)
	end})
	display.commonUIParams(viewData.kuangBtn , {cb = function(sender)
		local tempData = {}
		tempData.callback = function(num)
			if checkint(num) > checkint(self.limitNum)  then
				app.uiMgr:ShowInformationTips(__('已经超过了购买上限！！！'))
				return
			end
			local count = data.count + num
			if count > checkint(capacity) then
				app.uiMgr:ShowInformationTips(__('已达仓库容量上限'))
				return
			end
			data.count = data.count + num
			viewData.kuangNum:setString(tostring(num))
			self:UpdatePriceLabel(data.price , num)
			self:UpdateWareHouseLabel(data.count , capacity)
		end
		tempData.titleText = __('请输入买入材料的数量')
		tempData.nums = 3
		tempData.model = NumboardModel.freeModel

		local NumKeyboardMediator = require( 'Game.mediator.NumKeyboardMediator' )
		local mediator = NumKeyboardMediator.new(tempData)
		app:RegistMediator(mediator)
	end})
end

function BlackGoldFuturesPopUp:UpdateSellFutures(data)
	self.data = data
	self.limitNum = checkint(data.stock)
	local cellTable = {
		{ text = __('库存：') , num = data.stock , iconVisible = false  } ,
		{ text = __('单价：') , num = data.price + data.profit    , iconVisible = true  } ,
		{ text = __('利润：') , num = data.profit  , iconVisible = true  } ,
	}
	local viewData = self.viewData
	local cells = viewData.cells
	for i = 1 , #cells do
		local cell = cells[i]
		local leftLabel = cell:getChildByTag(1)
		local rightLabel = cell:getChildByTag(2)
		local iconImage = cell:getChildByTag(3)
		leftLabel:setString(cellTable[i].text)
		rightLabel:setString(cellTable[i].num)
		iconImage:setVisible(cellTable[i].iconVisible)
	end
	viewData.oneLabel:setString(__('卖出获得'))
	viewData.twoLabel:setString(__('卖出数量'))
	viewData.kuangNum:setString("1")
	viewData.kuangNum_0:setString(tostring(data.price + data.profit ))
	viewData.titleBtn:getLabel():setString(__('卖出'))
	viewData.doBtn:getLabel():setString(__("卖出"))
	viewData.goodsImage:setTexture(app.blackGoldMgr:GetFuturesPtahByFutureId(data.futuresId))
	local name = futuresConf[tostring(data.futuresId)].name
	viewData.goodName:setString(name)
	self:UpdateProFitLabel(data.profit, 1)
	display.commonUIParams(viewData.addBtn, { cb = function(sender)
		local num = checkint(viewData.kuangNum:getString())
		num = num +1
		if num > self.limitNum then
			app.uiMgr:ShowInformationTips(__('期货储备数量不足'))
			return
		end
		viewData.kuangNum:setString(tostring(num) )
		self:UpdatePriceLabel(data.price + data.profit , num)
		self:UpdateProFitLabel(data.profit , num)
	end})
	display.commonUIParams(viewData.subBtn , {cb = function(sender)
		local num = checkint(viewData.kuangNum:getString())
		num = num - 1
		if num <= 0  then
			app.uiMgr:ShowInformationTips(__('最少购卖一个！！！'))
			return
		end
		viewData.kuangNum:setString(tostring(num ) )
		self:UpdatePriceLabel(data.price + data.profit , num)
		self:UpdateProFitLabel(data.profit , num)
	end})
	display.commonUIParams(viewData.kuangBtn , {cb = function(sender)
		local tempData = {}
		tempData.callback = function(num)
			if checkint(num) > checkint(self.limitNum)  then
				app.uiMgr:ShowInformationTips(__('期货储备数量不足'))
				return
			end
			viewData.kuangNum:setString(tostring(num) )
			self:UpdatePriceLabel(data.price + data.profit , num)
			self:UpdateProFitLabel(data.profit , num)
		end
		tempData.titleText = __('请输入卖出材料的数量')
		tempData.nums = 3
		tempData.model = NumboardModel.freeModel
		local NumKeyboardMediator = require( 'Game.mediator.NumKeyboardMediator' )
		local mediator = NumKeyboardMediator.new(tempData)
		app:RegistMediator(mediator)
	end})
end
function BlackGoldFuturesPopUp:UpdatePriceLabel(price , num)
	self.viewData.kuangNum_0:setString(tostring(price * num))
end

function BlackGoldFuturesPopUp:UpdateProFitLabel(profit , num)
	local cells = self.viewData.cells
	local cell = cells[3]
	local rightLabel = cell:getChildByTag(2)
	if checkint(profit) > 0  then
		rightLabel:setString("+" ..  tostring(profit * num))
		rightLabel:setColor(ccc3FromInt("#D20000"))
	else
		rightLabel:setString(tostring(profit * num))
		rightLabel:setColor(ccc3FromInt("#439c02"))
	end
end

function BlackGoldFuturesPopUp:UpdateWareHouseLabel(num  , capacity)
	local cells = self.viewData.cells
	local cell = cells[2]
	local rightLabel = cell:getChildByTag(2)
	rightLabel:setString(num .. '/' .. capacity )
end
function BlackGoldFuturesPopUp:DoBack(sender)
	if self.callback then
		local num =  checkint(self.viewData.kuangNum:getString())
		self.callback(num)
	end
	self:removeFromParent()
end
return BlackGoldFuturesPopUp
--[[
活动每日签到Cell
--]]
---@class BlackGoldTradeView
local BlackGoldTradeView = class('BlackGoldTradeView', function ()
	local BlackGoldTradeView = CLayout:create(display.size)
	BlackGoldTradeView.name = 'home.BlackGoldTradeView'
	BlackGoldTradeView:enableNodeEvents()
	return BlackGoldTradeView
end)
local newImageView = display.newImageView
local newLabel = display.newLabel
local newButton = display.newButton
local newLayer = display.newLayer
local RES_DICT = {
	COMMON_BTN_ADD                = _res('ui/common/common_btn_add.png'),
	GOLD_TRADE_WARE_INPUT_BUY_BG  = _res('ui/home/blackShop/gold_trade_ware_input_buy_bg.png'),
	COMMON_BG_TITLE_2             = _res('ui/common/common_bg_title_2.png'),
	GOLD_TRADE_WARE_BTN_LATER     = _res('ui/home/blackShop/gold_trade_ware_btn_later.png'),
	GOLD_TRADE_WARE_BTN_FRONTI     = _res('ui/home/blackShop/gold_trade_ware_btn_fronti.png'),
	GOLD_TRADE_WARE_BG_LATER      = _res('ui/home/blackShop/gold_trade_ware_bg_later.png'),
	COMMON_TITLE_5                = _res('ui/common/common_title_5.png'),
	GOLD_TRADE_WARE_LIST_JIAOB    = _res('ui/home/blackShop/gold_trade_ware_list_jiaob.png'),
	GOLD_TRADE_WARE_BG_FRONT      = _res('ui/home/blackShop/gold_trade_ware_bg_front.png'),
	GOLD_BINGO_PIC_WQ_KONG       = _res('ui/home/blackShop/gold_bingo_pic_wq_kong.png'),
}
local BUTTON_TAG = {
	BACK_BTN         = 1003, -- 返回按钮
	LTRADE_BTN       = 1004, -- 上期交易
	CTRADE_BTN       = 1005, -- 本期交易
	ADD_CAPACITY_BTN = 1006, -- 扩容背包
	TRADE_EVENT_BTN  = 1007, -- 港口贸易
	TIP_BTN          = 1008, -- 交易规则

}
function BlackGoldTradeView:ctor()
	local shareSpineCache = SpineCache(SpineCacheName.BLACK_GOLD)
	local view = newLayer(display.cx, display.cy,{ap = display.CENTER, size = display.size})

	self:addChild(view)
	local swallowLayer = newLayer(display.cx, display.cy,{ap = display.CENTER, size = display.size , color = cc.c4b(0,0,0,175) , enable = true })
	view:addChild(swallowLayer)

	local leftLayout = newLayer( display.SAFE_L -1, display.cy +2,
			{ ap = display.LEFT_CENTER ,size = cc.size(603, 714)})
	view:addChild(leftLayout)


	local backBtn = display.newButton(0, 0, {n = _res("ui/common/common_btn_back.png")})
	backBtn:setPosition(cc.p(display.SAFE_L + backBtn:getContentSize().width * 0.5 + 20, display.height - 35))
	view:addChild(backBtn, 20)
	backBtn:setTag(BUTTON_TAG.BACK_BTN)


	local tabNameLabel = display.newButton(display.SAFE_L + 100, display.height+15,{n = _res('ui/common/common_title_new.png'),enable = true,tag = BUTTON_TAG.TIPS_TAG , ap = cc.p(0, 1)})
	display.commonLabelParams(tabNameLabel, {ttf = true, font = TTF_GAME_FONT, text = __('港口贸易'), fontSize = 30, color = '473227',offset = cc.p(0,-8)})
	view:addChild(tabNameLabel, 10)

	local tipsBtn = display.newButton(tabNameLabel:getContentSize().width - 50, tabNameLabel:getContentSize().height/2 - 10, {n = _res('ui/common/common_btn_tips.png')})
	tabNameLabel:addChild(tipsBtn, 10)
	tabNameLabel:setTag(BUTTON_TAG.TIP_BTN)

	local tradeBarSpine = shareSpineCache:createWithName(app.blackGoldMgr.spineTable.GOLD_TRADE_BARD)
	tradeBarSpine:setName("tradeBarSpine")
	leftLayout:addChild(tradeBarSpine)
	tradeBarSpine:setPosition(510/2 , 620/2)
	tradeBarSpine:setVisible(false)
	--tradeBarSpine:setAnimation(0,'play1' , false)

	local titleBtn = newButton(250, 640, { ap = display.CENTER ,  n = RES_DICT.COMMON_BG_TITLE_2, d = RES_DICT.COMMON_BG_TITLE_2, s = RES_DICT.COMMON_BG_TITLE_2, scale9 = true, size = cc.size(256, 36), tag = 131 })
	display.commonLabelParams(titleBtn, {text = __('购买'), fontSize = 24, color = '#ffffff'})
	leftLayout:addChild(titleBtn)

	local titleOneLabel = newLabel(251, 579,
			{ ap = display.CENTER, color = '#ffffff', text = "", fontSize = 20, tag = 132 })
	leftLayout:addChild(titleOneLabel)

	local titleTwoLabel = newLabel(253, 601,
			{ ap = display.CENTER, color = '#ffffff', text = "", fontSize = 20, tag = 133 })
	leftLayout:addChild(titleTwoLabel)

	local tradeCloseSize = cc.size(300, 150)
	local tradeCloseBtn = newLayer(255 , 250 , {ap = display.CENTER , size = tradeCloseSize  ,enable = true , color = cc.c4b(0,0,0,0)})
	leftLayout:addChild(tradeCloseBtn)
	tradeCloseBtn:setTag(BUTTON_TAG.TRADE_EVENT_BTN)

	local tradeCloseLabel = display.newLabel(tradeCloseSize.width/2 , tradeCloseSize.height/2 , fontWithColor(14,{fontSize =  48 , text = __('关闭'), color = "#FFFFFF" , outline = "#2E170A" , outlineSize = 2}))
	tradeCloseBtn:addChild(tradeCloseLabel)
	tradeCloseBtn:setVisible(false)
	local rightLayout = newLayer(963, 363,
			{ ap = display.CENTER, size = cc.size(725, 728)})
	rightLayout:setPosition(display.SAFE_R + -371, display.cy + -12)
	view:addChild(rightLayout)

	local wareBgImage = newImageView(RES_DICT.GOLD_TRADE_WARE_BG_LATER, 5, 1,
			{ ap = display.LEFT_BOTTOM, tag = 148, enable = false })
	rightLayout:addChild(wareBgImage)

	local tradeParper = shareSpineCache:createWithName(app.blackGoldMgr.spineTable.GOLD_TRADE_PAPER)
	tradeParper:setName("tradeParper")
	rightLayout:addChild(tradeParper)
	tradeParper:setAnchorPoint(display.CENTER)
	tradeParper:setPosition(720/2,690/2)
	tradeParper:setVisible(false)
	--

	local currentBtn = newButton(664, 503, { ap = display.CENTER ,  n = RES_DICT.GOLD_TRADE_WARE_BTN_LATER, d = RES_DICT.GOLD_TRADE_WARE_BTN_FRONTI, s = RES_DICT.GOLD_TRADE_WARE_BTN_LATER, scale9 = true, size = cc.size(144, 85), tag = 149 })
	display.commonLabelParams(currentBtn, fontWithColor(14,{text = __('本期'), fontSize = 24, color = '#ffffff'}))
	rightLayout:addChild(currentBtn)
	currentBtn:setVisible(false)
	currentBtn:setTag(BUTTON_TAG.CTRADE_BTN)
	local titleWareBtn = newButton(329, 664, { ap = display.CENTER ,  n = RES_DICT.COMMON_TITLE_5, d = RES_DICT.COMMON_TITLE_5, s = RES_DICT.COMMON_TITLE_5, scale9 = true, size = cc.size(186, 31), tag = 157 })
	display.commonLabelParams(titleWareBtn, {text = __('仓库'), fontSize = 22, color = '#414146'})
	rightLayout:addChild(titleWareBtn)

	local lastBtn = newButton(664, 400, { ap = display.CENTER ,  n = RES_DICT.GOLD_TRADE_WARE_BTN_LATER, d = RES_DICT.GOLD_TRADE_WARE_BTN_FRONTI, s = RES_DICT.GOLD_TRADE_WARE_BTN_LATER, scale9 = true, size = cc.size(144, 85), tag = 150 })
	display.commonLabelParams(lastBtn, fontWithColor(14,{text = __('往期'), fontSize = 24, color = '#ffffff'}))
	rightLayout:addChild(lastBtn)
	lastBtn:setTag(BUTTON_TAG.LTRADE_BTN)
	lastBtn:setVisible(false)
	local capacityLayout = newLayer(451, 586,
			{ ap = display.LEFT_BOTTOM, size = cc.size(280, 154)})
	rightLayout:addChild(capacityLayout)

	local capacityLabel = newLabel(151, 88,
			fontWithColor(14, { ap = display.CENTER, color = '#ffffff', text = __('仓储容量：'), fontSize = 22, tag = 153 }))
	capacityLayout:addChild(capacityLabel)
	capacityLayout:setVisible(false)

	local capacityNum = newButton(152, 50, { ap = display.CENTER ,  n = RES_DICT.GOLD_TRADE_WARE_INPUT_BUY_BG, d = RES_DICT.GOLD_TRADE_WARE_INPUT_BUY_BG, s = RES_DICT.GOLD_TRADE_WARE_INPUT_BUY_BG, scale9 = true, size = cc.size(170, 31), tag = 154 })
	display.commonLabelParams(capacityNum, fontWithColor(14,{text = "", fontSize = 24, color = '#ffffff'}))
	capacityLayout:addChild(capacityNum)

	local capacityBtn = newButton(233, 51, { ap = display.CENTER ,  n = RES_DICT.COMMON_BTN_ADD, d = RES_DICT.COMMON_BTN_ADD, s = RES_DICT.COMMON_BTN_ADD, scale9 = true, size = cc.size(60, 60), tag = 155 })
	display.commonLabelParams(capacityBtn, {text = "", fontSize = 14, color = '#414146'})
	capacityLayout:addChild(capacityBtn)
	capacityBtn:setTag(BUTTON_TAG.ADD_CAPACITY_BTN)
	capacityBtn:setVisible(false)
	local tabNameLabelPos = cc.p(tabNameLabel:getPosition())
	tabNameLabel:setPositionY(display.height + 100)

	local action = cc.EaseBounceOut:create(cc.MoveTo:create(1, tabNameLabelPos))
	tabNameLabel:runAction( action )

	local crightLayout = newLayer(725/2, 728/2,
			{ ap = display.CENTER, size = cc.size(725, 728)})
	rightLayout:addChild(crightLayout)
	local lrightLayout = newLayer(725/2, 728/2,
			{ ap = display.CENTER, size = cc.size(725, 728)})
	rightLayout:addChild(lrightLayout)
	crightLayout:setVisible(false)

	local cgrideCellSize = cc.size(180, 194)
	local cgridView      = CGridView:create(cc.size(550, 560))
	cgridView:setSizeOfCell(cgrideCellSize)
	cgridView:setColumns(3)
	cgridView:setAutoRelocate(true)
	cgridView:setAnchorPoint(display.CENTER)
	cgridView:setPosition(689 / 2 -10, 525 / 2 + 60)
	crightLayout:addChild(cgridView)
	cgridView:setTag(10)


	local lgrideCellSize = cc.size(181, 240)
	local lgridView      = CGridView:create(cc.size(550, 560))
	lgridView:setSizeOfCell(lgrideCellSize)
	lgridView:setColumns(3)
	lgridView:setAutoRelocate(true)
	lgridView:setAnchorPoint(display.CENTER)
	lgridView:setPosition(689 / 2 -25, 525 / 2 + 60)
	lrightLayout:addChild(lgridView)
	lrightLayout:setVisible(false)
	
	local fgrideCellSize = cc.size(208, 240)
	local fgridView      = CGridView:create(cc.size(416, 560))
	fgridView:setSizeOfCell(fgrideCellSize)
	fgridView:setColumns(2)
	fgridView:setAutoRelocate(true)
	fgridView:setAnchorPoint(display.CENTER)
	fgridView:setPosition(689 / 2 -90, 525 / 2 + 60-10)
	leftLayout:addChild(fgridView)
	fgridView:setVisible(false)
	self.viewData =  {
		leftLayout     = leftLayout,
		titleBtn       = titleBtn,
		titleOneLabel  = titleOneLabel,
		titleTwoLabel  = titleTwoLabel,
		rightLayout    = rightLayout,
		wareBgImage    = wareBgImage,
		tabNameLabel   = tabNameLabel,
		backBtn        = backBtn,
		tradeParper    = tradeParper,
		tradeBarSpine  = tradeBarSpine,
		currentBtn     = currentBtn,
		tradeCloseBtn  = tradeCloseBtn,
		titleWareBtn   = titleWareBtn,
		lastBtn        = lastBtn,
		capacityLayout = capacityLayout,
		capacityLabel  = capacityLabel,
		capacityNum    = capacityNum,
		capacityBtn    = capacityBtn,
		cgridView      = cgridView,
		fgridView      = fgridView,
		lgridView      = lgridView,
		lrightLayout   = lrightLayout,
		crightLayout   = crightLayout,
		tipsBtn        = tipsBtn,
	}
end
function BlackGoldTradeView:UpdateCapacity(backpackCount , capacity  )
	self.viewData.capacityLayout:setVisible(true)
	display.commonLabelParams(self.viewData.capacityNum , { text = tostring( backpackCount)   .. "/".. tostring(capacity) })
end

function BlackGoldTradeView:CreateLFuturesEmpty()
	local image = display.newImageView(RES_DICT.GOLD_BINGO_PIC_WQ_KONG ,689/2 , 527/2  )
	self.viewData.lrightLayout:addChild(image)
	local label  = display.newLabel(689/2 , 527  , {fontSize = 22, color = "#515151" , text = __('本周购买的期货会在商船离港后被收纳到这里')})
	self.viewData.lrightLayout:addChild(label)
end

function BlackGoldTradeView:CheckCapacityBtnIsVisible()
	----@type CommerceConfigParser
	local CommerceConfigParser = require("Game.Datas.Parser.CommerceConfigParser")
	local capacityConf = CommonUtils.GetConfigAllMess(CommerceConfigParser.TYPE.WAREHOUSE, 'commerce')
	local count = table.nums(capacityConf)
	local wareGradeHouse = app.blackGoldMgr:GetWarehouseGrade()
	self.viewData.capacityBtn:setVisible(wareGradeHouse < count )
end
function BlackGoldTradeView:CreateCFuturesEmpty()
	local image = display.newImageView(RES_DICT.GOLD_BINGO_PIC_WQ_KONG ,689/2 , 527/2 )
	self.viewData.crightLayout:addChild(image)
	local label  = display.newLabel(689/2 , 527 , {fontSize = 22, color = "#515151" , text = __('本期还未购买任何期货')})
	self.viewData.crightLayout:addChild(label)
end
--[[
	删除crightLayout 的除 cgridView 以外的所有子节点
--]]
function BlackGoldTradeView:RemoveCRightLayoutChildOutGrideView()
	local crightLayout = self.viewData.crightLayout
	local children = crightLayout:getChildren()
	for index, child in pairs(children) do
		local tag = child:getTag()
		if tag ~= 10 then
			child:removeFromParent()
		end
	end
end

return BlackGoldTradeView
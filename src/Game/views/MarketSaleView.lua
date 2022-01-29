--[[
市场出售模块view
--]]
local MarketSaleView = class('MarketSaleView', function ()
	local node = CLayout:create(cc.size(1082, 641))
	node:setAnchorPoint(cc.p(0, 0))
	node.name = 'home.MarketSaleView'
	node:enableNodeEvents()
	return node
end)

local function CreateView( )
	local size = cc.size(1082, 641)
	local view = CLayout:create(size)
	view:setAnchorPoint(0, 0)
	-- 筛选按钮
	local selectBtn = display.newButton(56, 533, {tag = 2001, ap = cc.p(0, 0), n = _res('ui/home/teamformation/choosehero/team_btn_selection_unused.png')})
	view:addChild(selectBtn)
	display.commonLabelParams(selectBtn, {text = __('全部'), fontSize = 22, color = '#ffffff'})
	-- local directIcon = display.newImageView(_res('ui/common/common_bg_direct_s'), 97, selectBtn:getContentSize().height/2)
	-- selectBtn:addChild(directIcon)
	-- directIcon:setRotation(90)
	-- directIcon:setScale(0.2)
	-- tips
	local tipsLabel = display.newLabel(196, 555, {ap = cc.p(0, 0.5), text = __('tips:物品出售成功后会收取30%的手续费'), fontSize = fontWithColor('6').fontSize, color = fontWithColor('6').color, w = 400})
	view:addChild(tipsLabel)
	-- 剩余栏位
	local lastLabel = display.newLabel(1022, 570, {ap = cc.p(1, 0.5), text = __('今日剩余寄售次数'),  fontSize = fontWithColor('16').fontSize, color = fontWithColor('16').color, reqW = 315})
	view:addChild(lastLabel)
	local lastBg = display.newImageView(_res('ui/home/market/market_sold_bg_num_sold.png'), 916, 540, {ap = cc.p(0, 0.5)})
	view:addChild(lastBg)
	local lastNumLabel = display.newLabel(lastBg:getContentSize().width/2, lastBg:getContentSize().height/2, {text = '', fontSize = fontWithColor('9').fontSize, color = fontWithColor('9').color})
	lastBg:addChild(lastNumLabel)
    -- 物品列表
    local goodsLayout = CLayout:create(size)
    view:addChild(goodsLayout, 10)
    goodsLayout:setPosition(utils.getLocalCenter(view))
    local gridViewSize = cc.size(970, 340)
    local goodsListBg = display.newImageView(_res('ui/common/common_bg_goods.png'), 54, 181, {ap = cc.p(0, 0), scale9 = true, size = gridViewSize})
    goodsLayout:addChild(goodsListBg)

	local cellSize = cc.size((gridViewSize.width-10)/8, (gridViewSize.height+10)/3)
	local gridView = CGridView:create(cc.size(gridViewSize.width-2, gridViewSize.height-2))
	gridView:setAnchorPoint(cc.p(0, 0))
	gridView:setPosition(cc.p(59, 183))
	goodsLayout:addChild(gridView, 10)
	gridView:setSizeOfCell(cellSize)
	gridView:setColumns(8)
    -- 底部物品icon
    local soldBg = display.newImageView(_res('ui/home/market/market_sold_bg_info.png'), 42, 8, {ap = cc.p(0, 0)})
    goodsLayout:addChild(soldBg)
    local goodsBg = display.newImageView(_res('ui/common/common_frame_goods_1'), 105, 50, {ap = cc.p(0, 0)})
    goodsBg:setScale(0.85)
    goodsLayout:addChild(goodsBg)
    local goodsIcon = display.newImageView(_res('arts/goods/goods_icon_150001.png'), goodsBg:getContentSize().width/2, goodsBg:getContentSize().height/2)
    goodsBg:addChild(goodsIcon)
    goodsIcon:setScale(0.5)
    local goodsName = display.newLabel(158, 33, {text = '', fontSize = fontWithColor('5').fontSize, color = fontWithColor('5').color})
    goodsLayout:addChild(goodsName)
    -- local knifeImage = display.newImageView(_res('ui/home/market/common_decorate_knife.png'), 60, 20, {ap = cc.p(0, 0)})
    -- goodsLayout:addChild(knifeImage)
    -- local forkImage = display.newImageView(_res('ui/home/market/market_decorate_ico_fork.png'), 235, 20 , {ap = cc.p(0, 0)})
    -- goodsLayout:addChild(forkImage)
    -- 出售栏
    local soldLabel = display.newLabel(380, 112, {ap = display.CENTER_BOTTOM, text = __('出售数量'), fontSize = fontWithColor('16').fontSize, color = fontWithColor('16').color})
    goodsLayout:addChild(soldLabel)
    local soldLine = display.newImageView(_res('ui/home/market/market_sold_ico_line.png'), 286, 109, {ap = cc.p(0, 0)})
    goodsLayout:addChild(soldLine)
    local soldNumBg = display.newImageView(_res('ui/home/market/market_buy_bg_info.png'), 282, 53, {ap = cc.p(0, 0), scale9 = true, size = cc.size(180, 44), capInsets = cc.rect(10, 10, 192, 8)})
    goodsLayout:addChild(soldNumBg)
    local changeNumBtn = {}
    local minusBtnL = display.newButton(282, 51, {tag = 2002, n = _res('ui/home/market/market_sold_btn_sub.png'), ap = cc.p(0, 0), scale9 = true, size = cc.size(50, 46)})
    goodsLayout:addChild(minusBtnL)
    local plusBtnR = display.newButton(428, 51, {tag = 2003, n = _res('ui/home/market/market_sold_btn_plus.png'), ap = cc.p(0, 0), scale9 = true, size = cc.size(50, 46)})
    goodsLayout:addChild(plusBtnR)
    table.insert(changeNumBtn, minusBtnL)
    table.insert(changeNumBtn, plusBtnR)
    local soldNumLabel = cc.Label:createWithBMFont('font/common_num_1.fnt', '')
	soldNumLabel:setAnchorPoint(cc.p(0.5, 0.5))
	soldNumLabel:setHorizontalAlignment(display.TAR)
	soldNumLabel:setPosition(380, 75)
	goodsLayout:addChild(soldNumLabel)
	soldNumLabel:setScale(1)
	local priceLabel = display.newLabel(650, 112, {ap = display.CENTER_BOTTOM, text = __('单价'), fontSize = fontWithColor('16').fontSize, color = fontWithColor('16').color})
    goodsLayout:addChild(priceLabel)
    local univalentLine = display.newImageView(_res('ui/home/market/market_sold_ico_line.png'), 560, 109, {ap = cc.p(0, 0)})
    goodsLayout:addChild(univalentLine)
    local univalentNumBg = display.newImageView(_res('ui/home/market/market_buy_bg_info.png'), 556, 53, {ap = cc.p(0, 0), scale9 = true, size = cc.size(190, 44), capInsets = cc.rect(10, 10, 192, 8)})
    goodsLayout:addChild(univalentNumBg)
    local univalentNumLabel = cc.Label:createWithBMFont('font/common_num_1.fnt', '')
	univalentNumLabel:setAnchorPoint(cc.p(0.5, 0.5))
	univalentNumLabel:setHorizontalAlignment(display.TAR)
	univalentNumLabel:setPosition(630, 75)
	goodsLayout:addChild(univalentNumLabel)
	univalentNumLabel:setScale(1)
	local timeLabel = display.newLabel(650, 35, {text = __('出售时间:4小时'), fontSize = fontWithColor('16').fontSize, color = fontWithColor('16').color})
	goodsLayout:addChild(timeLabel)
	local univalentSelectBtn = display.newButton(722, 75, {tag = 2004, n = _res('ui/home/market/market_sold_btn_up_info.png'), scale9 = true, size = cc.size(44, 42)})
	goodsLayout:addChild(univalentSelectBtn)
	local consignmentBtn = display.newButton(930, 80, {tag = 2005, n = _res('ui/common/common_btn_orange.png'),scale9 = true })
	goodsLayout:addChild(consignmentBtn)
	display.commonLabelParams(consignmentBtn, {text = __('寄售'), reqW = 100 ,  fontSize = fontWithColor('14').fontSize, color = fontWithColor('14').color , paddingW  = 10 })
	local totalPriceLabel = display.newLabel(930, 35, {text = '', fontSize = 22, color = '#ffffff'})
	goodsLayout:addChild(totalPriceLabel)
	-- 列表为空时的背景
	local emptyLayout = CLayout:create(size)
	emptyLayout:setPosition(utils.getLocalCenter(view))
	view:addChild(emptyLayout, 15)
	local dialogue_tips = display.newButton(0, 0, {ap = display.CENTER,n = _res('ui/common/common_bg_dialogue_tips.png')})
	display.commonUIParams(dialogue_tips, {ap = cc.p(0,0.5),po = cc.p(120,size.height * 0.4)})
	display.commonLabelParams(dialogue_tips,{text = __('背包暂无此类商品'), w = 350, hAlign = display.TAC,  fontSize = 24, color = '#4c4c4c'})
    emptyLayout:addChild(dialogue_tips, 6)
    -- 中间小人
	local loadingCardQ = AssetsUtils.GetCartoonNode(3, dialogue_tips:getContentSize().width + 270, size.height * 0.4)
	emptyLayout:addChild(loadingCardQ, 6)
	loadingCardQ:setScale(0.7)

	emptyLayout:setVisible(false)
	goodsLayout:setVisible(false)

	return {
		view          	   = view,
		selectBtn     	   = selectBtn,
		tipsLabel     	   = tipsLabel,
		gridView      	   = gridView,
		cellSize      	   = cellSize,
		goodsName     	   = goodsName,
		soldNumLabel  	   = soldNumLabel,
		univalentNumLabel  = univalentNumLabel,
		goodsBg      	   = goodsBg,
		goodsIcon          = goodsIcon,
		totalPriceLabel    = totalPriceLabel,
		minusBtnL          = minusBtnL,
		plusBtnR           = plusBtnR,
		univalentSelectBtn = univalentSelectBtn,
		consignmentBtn     = consignmentBtn,
		lastNumLabel       = lastNumLabel,
		changeNumBtn 	   = changeNumBtn,
		goodsLayout        = goodsLayout,
		emptyLayout		   = emptyLayout
	}
end

function MarketSaleView:ctor( ... )
	self.viewData_ = CreateView()
	self:addChild(self.viewData_.view, 1)
	self.viewData_.view:setPosition(cc.p(0, 0))
end

return MarketSaleView

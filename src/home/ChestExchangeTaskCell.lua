--[[
宝箱兑换活动任务Cell
--]]
local ChestExchangeTaskCell = class('ChestExchangeTaskCell', function ()
	local ChestExchangeTaskCell = CLayout:new()
	ChestExchangeTaskCell.name = 'home.ChestExchangeTaskCell'
	ChestExchangeTaskCell:enableNodeEvents()
	return ChestExchangeTaskCell
end)

function ChestExchangeTaskCell:ctor( ... )
	local arg = { ... }
	local size = arg[1] or cc.size(400, 574)
	self.exchangeNum = 1 -- 兑换数目
	self:setContentSize(size)
    local mask = CColorView:create(cc.c4b(0, 0, 0, 0))
    mask:setPosition(cc.p(size.width/2, size.height/2))
    mask:setAnchorPoint(cc.p(0.5, 0.5))
    mask:setTouchEnabled(true)
    mask:setContentSize(size)
    self:addChild(mask, -1)
	self.bg = display.newImageView(_res('ui/home/activity/seasonlive/season_battle_bg_card_s'), size.width/2, (size.height)/2 + 80)
	self:addChild(self.bg, 1)
	self.goodsBg = display.newImageView(_res('ui/home/activity/chestExchange/season_battle_ico_1'), size.width/2, size.height - 110)
	self:addChild(self.goodsBg, 3)
	self.goodsIcon = display.newImageView('', size.width/2, size.height - 80)
	self:addChild(self.goodsIcon, 10)
	self.goodsName = display.newLabel(size.width/2, size.height - 160, fontWithColor(19, {text = '', w = 220, hAlign = display.TAC}))
	self:addChild(self.goodsName, 10)
	self.materialBg = display.newImageView(_res('ui/home/activity/chestExchange/activity_laba_bg_goods.png'), size.width/2, size.height/2)
	self:addChild(self.materialBg, 3)
	self.materialLabel = display.newLabel(0, 0, fontWithColor(5, {text = __('所需食材')}))
	local materialLabelSize = cc.size(math.max(186, display.getLabelContentSize(self.materialLabel).width + 40), 31)
	self.materialTitle = display.newButton(size.width/2, size.height/2 + 58, {n = _res('ui/common/common_title_3.png'), scale9 = true, size = materialLabelSize, enable = false})
	self.materialTitle:addChild(self.materialLabel, 1)
	self.materialLabel:setPosition(materialLabelSize.width / 2, materialLabelSize.height / 2)
	self:addChild(self.materialTitle, 10)
	
	-- 材料
	self.goodsTable = {}
	for i=1, 2 do
		local goodsNode = require('common.GoodNode').new({id = 0, showAmount = false, callBack = function(sender)end})
		self:addChild(goodsNode, 10)
		goodsNode:setPosition(cc.p(size.width/2 + 60*math.pow(-1, i), size.height/2 - 5))
		goodsNode:setScale(0.8)
		goodsNode:setVisible(false)
		local goodsNum = cc.Label:createWithBMFont('font/small/common_text_num.fnt', '')
		goodsNum:setPosition(cc.p(size.width/2 + 60*math.pow(-1, i), size.height/2 - 64))
		self:addChild(goodsNum, 10)
		table.insert(self.goodsTable, {goodsNode = goodsNode, goodsNum = goodsNum})
	end
	-- 数目调整
	self.numTitleLabel = display.newLabel(0, 0, {text = __('煮粥数量'), fontSize = 20, color = '#966746'})
	local numTitleLabelSize = cc.size(math.max(186, display.getLabelContentSize(self.numTitleLabel).width + 40), 31)
	self.numTitle = display.newButton(size.width/2, 180, {n = _res('ui/common/common_title_3.png'), scale9 = true, size = numTitleLabelSize, enable = false})
	self.numTitle:addChild(self.numTitleLabel, 1)
	self.numTitleLabel:setPosition(numTitleLabelSize.width / 2, numTitleLabelSize.height / 2)
	self:addChild(self.numTitle, 10)
	self.exchangeLabel = display.newLabel(0, 0, fontWithColor(14, {text = __('煮粥')}))
	local exchangeLabelSize = cc.size(math.max(123, display.getLabelContentSize(self.exchangeLabel).width + 30), 62)
	self.exchangeBtn = display.newButton(size.width/2, 45, {n = _res('ui/common/common_btn_orange.png'), size = exchangeLabelSize, scale9 = true})
	self.exchangeBtn:addChild(self.exchangeLabel, 1)
	self.exchangeLabel:setPosition(cc.p(exchangeLabelSize.width / 2, exchangeLabelSize.height / 2))
	self:addChild(self.exchangeBtn, 10)
	self.numBtn = display.newButton(size.width/2, 132, {n = _res('ui/home/market/market_buy_bg_info.png'),scale9 = true, size = cc.size(180, 44)})
	self:addChild(self.numBtn, 10)
    self.exchangeNumLabel = cc.Label:createWithBMFont('font/common_num_1.fnt', '1')
	self.exchangeNumLabel:setAnchorPoint(cc.p(0.5, 0.5))
	self.exchangeNumLabel:setPosition(size.width/2, 132)
	self:addChild(self.exchangeNumLabel, 10)
	self.minusBtn = display.newButton(size.width/2 - 80, 132, {n = _res('ui/home/market/market_sold_btn_sub.png')})
	self:addChild(self.minusBtn, 10)
	self.addBtn = display.newButton(size.width/2 + 80, 132, {n = _res('ui/home/market/market_sold_btn_plus.png')})
	self:addChild(self.addBtn, 10)
end
return ChestExchangeTaskCell
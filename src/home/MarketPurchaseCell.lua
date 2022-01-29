--[[
市场购买列表cell
--]]
local MarketPurchaseCell = class('MarketPurchaseCell', function ()
	local marketPurchaseCell = CGridViewCell:new()
	marketPurchaseCell.name = 'home.MarketPurchaseCell'
	marketPurchaseCell:enableNodeEvents()
	return marketPurchaseCell
end)

function MarketPurchaseCell:ctor( ... )
	local arg = { ... }
	local size = arg[1]
	self:setContentSize(size)
	local eventNode = CLayout:create(size)
	eventNode:setPosition(utils.getLocalCenter(self))
	self:addChild(eventNode)
	self.eventNode = eventNode
	-- bg
	self.bg = display.newButton(size.width/2, size.height/2, {d = _res('ui/common/common_bg_list_active.png'), n = _res('ui/home/market/market_main_bg_goods_sold.png'), scale9 = true, size = cc.size(size.width-6, size.height-6)})
	self.eventNode:addChild(self.bg)
	-- 物品
	self.goodsBg = display.newImageView(_res('ui/home/market/market_main_bg_goods.png'), 12, size.height/2, {ap = cc.p(0, 0.5)})
	self.eventNode:addChild(self.goodsBg, 3)
	self.goodsFrame = display.newImageView(_res('ui/common/common_frame_goods_1.png'), self.goodsBg:getContentSize().width/2, self.goodsBg:getContentSize().height/2)
	self.goodsFrame:setScale(0.78)
	self.goodsBg:addChild(self.goodsFrame, 5)
	self.goodsIcon = display.newImageView(_res('arts/goods/goods_icon_150001.png'), self.goodsBg:getContentSize().width/2, self.goodsBg:getContentSize().height/2)
	self.goodsIcon:setScale(0.5)
	self.goodsBg:addChild(self.goodsIcon, 10)
	-- 数量
	self.numLabel = display.newLabel(84, 5, fontWithColor(9, {ap = cc.p(1, 0)}))
	self.goodsBg:addChild(self.numLabel, 10)
	-- 名称
	self.nameLabel = display.newLabel(200, size.height - 20, fontWithColor(7,{ap = cc.p(0.5, 1), text = '', fontSize = 20, color = '#2273b1', w = 190}))
    self.nameLabel:setAlignment(cc.TEXT_ALIGNMENT_CENTER)
	self.eventNode:addChild(self.nameLabel, 10)
	-- 售价
	self.priceLabel = display.newRichLabel(size.width - 10, 10, {ap = cc.p(1, 0)})
	self.eventNode:addChild(self.priceLabel, 10)
	-- 售出
	self.saleImg = display.newButton(3, size.height/2, {n = _res('ui/home/market/market_main_bg_sold.png'), ap = cc.p(0, 0.5), enable = false})
	self.eventNode:addChild(self.saleImg, 15)
	display.commonLabelParams(self.saleImg, {text = __('已售出'), fontSize = 22, color = '#ffffff'})
end
return MarketPurchaseCell

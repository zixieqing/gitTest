--[[
市场售后页面寄售列表cell
--]]
local MarketRecordCell = class('MarketRecordCell', function ()
	local marketRecordCell = CGridViewCell:new()
	marketRecordCell.name = 'home.MarketRecordCell'
	marketRecordCell:enableNodeEvents()
	return marketRecordCell
end)

function MarketRecordCell:ctor( ... )
	local arg = { ... }
	local size = arg[1]
	self:setContentSize(size)
	local eventNode = CLayout:create(size)
	eventNode:setPosition(utils.getLocalCenter(self))
	self:addChild(eventNode)
	self.eventNode = eventNode
	-- bg
	self.bg = display.newImageView(_res('ui/common/common_bg_list.png'), size.width/2, -2, {ap = cc.p(0.5, 0), scale9 = true, size = cc.size(960, 103)})
	self.eventNode:addChild(self.bg)
	-- 菜品
	self.goodsBg = display.newImageView(_res('ui/common/common_frame_goods_1.png'), 70, 50, {ap = cc.p(0.5, 0.5)})
	self.goodsBg:setScale(0.8)
	self.eventNode:addChild(self.goodsBg)
	self.goodsIcon = display.newImageView(_res('arts/goods/goods_icon_150001.png'), self.goodsBg:getContentSize().width/2, self.goodsBg:getContentSize().height/2)
	self.goodsBg:addChild(self.goodsIcon)
	self.goodsIcon:setScale(0.55)
	self.goodsNumLabel = display.newLabel(self.goodsBg:getContentSize().width - 5, 3, {ap = cc.p(1, 0), text = '40', fontSize = fontWithColor('9').fontSize, color = fontWithColor('9').color})
	self.goodsBg:addChild(self.goodsNumLabel)
	self.goodsName = display.newLabel(70 + self.goodsBg:getContentSize().width * 0.5 + 2, 49, {ap = display.LEFT_CENTER,text = '',reqW = 270, fontSize = fontWithColor('4').fontSize, color = fontWithColor('4').color})
	self.eventNode:addChild(self.goodsName)
	-- 物品价格
	self.priceLabel = display.newLabel(465, 49, {ap = cc.p(1, 0.5), text = '', fontSize = fontWithColor('4').fontSize, color = fontWithColor('4').color})
	self.eventNode:addChild(self.priceLabel)
	self.goldIcon = display.newImageView(_res(CommonUtils.GetGoodsIconPathById(GOLD_ID)), 485, 49, {scale = 0.25})
	self.eventNode:addChild(self.goldIcon)
	-- 剩余时间
	self.timeBg = display.newImageView(_res('ui/home/market/market_main_bg_sold_2.png'),607, 49)
	self.eventNode:addChild(self.timeBg)
	self.timeBg:setVisible(false)
	self.timeLabel = display.newLabel(608, 49, {ap = display.CENTER , text = ' ', fontSize = fontWithColor('4').fontSize, color = fontWithColor('4').color})
	self.eventNode:addChild(self.timeLabel)
	-- 按钮
	self.consignmentAgainBtn = display.newButton(729, 49, {n = _res('ui/common/common_btn_orange.png'), tag  = 3001})
	self.eventNode:addChild(self.consignmentAgainBtn)
	display.commonLabelParams(self.consignmentAgainBtn, {text = __('再次寄售'), w = 90, hAlign = display.TAC, fontSize = 20, color = '#ffffff'})
	self.consignmentBtn = display.newButton(863, 49, {n = _res('ui/common/common_btn_orange.png'), tag = 3002})
	self.eventNode:addChild(self.consignmentBtn)
	display.commonLabelParams(self.consignmentBtn, {text = __('取消寄售'), w = 100,hAlign = display.TAC, fontSize = 20, color = '#ffffff'})
end
return MarketRecordCell

--[[
市场购买列表cell
--]]
local MarketSaleCell = class('MarketSaleCell', function ()
	local marketSaleCell = CGridViewCell:new()
	marketSaleCell.name = 'home.MarketSaleCell'
	marketSaleCell:enableNodeEvents()
	return marketSaleCell
end)

function MarketSaleCell:ctor( ... )
	local arg = { ... }
	local size = arg[1]
	self:setContentSize(size)
	local eventNode = CLayout:create(size)
	eventNode:setPosition(utils.getLocalCenter(self))
	self:addChild(eventNode)
	self.eventNode = eventNode
	-- bg
	self.toggleView = display.newButton(size.width * 0.5, 0,{--
        n = _res('ui/common/common_frame_goods_1.png'),
        scale9 = true, size = cc.size(size.width - 10, size.height - 10), ap = cc.p(0.5, 0)
    })
    self.eventNode:addChild(self.toggleView)
	self.goodsIcon = display.newImageView(_res('arts/goods/goods_icon_150001.png'), self.toggleView:getContentSize().width/2, self.toggleView:getContentSize().height/2)
	self.toggleView:addChild(self.goodsIcon)
	self.goodsIcon:setScale(0.5)

    local fragmentImg = display.newImageView(_res('ui/common/common_ico_fragment_1.png'), size.width * 0.5, 0,{as = false, ap = cc.p(0.5, 0), scale9 = true, size = cc.size(size.width-10, size.height-10)})
    self.eventNode:addChild(fragmentImg)
    self.fragmentImg = fragmentImg
    self.fragmentImg:setVisible(false)

    local selectImg = display.newImageView(_res('ui/common/common_bg_frame_goods_elected.png'), size.width * 0.5, -8,{as = false, ap = cc.p(0.5, 0), scale9 = true, size = cc.size(size.width+6, size.height+6)})
    self.eventNode:addChild(selectImg)
    self.selectImg = selectImg
    self.selectImg:setVisible(false)

    local fight_num = cc.Label:createWithBMFont('font/small/common_text_num.fnt', '')
    fight_num:setAnchorPoint(cc.p(1, 0))
    fight_num:setHorizontalAlignment(display.TAR)
    fight_num:setPosition(size.width - 12 , 3)
    self.eventNode:addChild(fight_num)
    self.numLabel = fight_num
end
return MarketSaleCell
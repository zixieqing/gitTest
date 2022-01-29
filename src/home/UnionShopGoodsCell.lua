--[[
工会商店商品Cell
--]]
---@class UnionShopGoodsCell:Node
local UnionShopGoodsCell = class('UnionShopGoodsCell', function ()
	local UnionShopGoodsCell = CGridViewCell:new()
	UnionShopGoodsCell.name = 'home.UnionShopGoodsCell'
	UnionShopGoodsCell:enableNodeEvents()
	return UnionShopGoodsCell
end)

function UnionShopGoodsCell:ctor( ... )
	local arg = { ... }
	local size = arg[1]
	self:setContentSize(size)
	local eventNode = CLayout:create(size)
	eventNode:setPosition(utils.getLocalCenter(self))
	self:addChild(eventNode)
	self.eventNode = eventNode

	self.bgBtn = display.newButton(size.width/2, size.height/2, {n = _res('ui/home/commonShop/shop_btn_goods_default.png')})
	self.eventNode:addChild(self.bgBtn, 1)
	self.sellOut = display.newLabel(42, size.height - 36, {text = __('售罄'), fontSize = 22, color = '#d23d3d', font = TTF_GAME_FONT, reqW=170 ,ttf = true})
	self.eventNode:addChild(self.sellOut, 7)
	self.stockLabel = display.newLabel(size.width/2, size.height - 36, {text = '', fontSize = 22, color = '#895a5a'})
	self.eventNode:addChild(self.stockLabel, 7)
	self.goodsIcon = require('common.GoodNode').new({id = 160001, amount = 1, showAmount = true})
	self.goodsIcon:setTouchEnabled(false)
	self.eventNode:addChild(self.goodsIcon, 7)
	self.goodsIcon:setPosition(size.width/2, size.height*0.65)
	self.goodsName = display.newLabel(size.width/2, 85, fontWithColor(16, {fontSize = 20 ,  text = '', w = 150}))
	self.goodsName:setAlignment(cc.TEXT_ALIGNMENT_CENTER)
	self.eventNode:addChild(self.goodsName, 7)
	self.priceLabel = display.newRichLabel(size.width/2, 25, {})
	self.eventNode:addChild(self.priceLabel, 10)
	CommonUtils.AddRichLabelTraceEffect(self.priceLabel , '#5b3c25' , 1)
	self.lockLabel = display.newButton(size.width/2, size.height*0.6, {n = _res('ui/home/union/guild_shop_lock_wrod.png')})
	self.eventNode:addChild(self.lockLabel, 10)
	self.lockLabel:setEnabled(false)
	self.lockLabel:setVisible(false)
	display.commonLabelParams(self.lockLabel, {text = '',fontSize = 24, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#5b3c25', outlineSize = 1})
	self.lockMask = display.newImageView(_res('ui/home/union/guild_shop_black_bg.png'), size.width/2, size.height/2, {scale9 = true, size = size})
	self.eventNode:addChild(self.lockMask, 9)
end
return UnionShopGoodsCell

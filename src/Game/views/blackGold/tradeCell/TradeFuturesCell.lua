--[[
活动每日签到Cell
--]]
---@class TradeFuturesCell
local TradeFuturesCell = class('TradeFuturesCell', function ()
	local TradeFuturesCell = CGridViewCell:new()
	TradeFuturesCell.name = 'home.TradeFuturesCell'
	TradeFuturesCell:enableNodeEvents()
	return TradeFuturesCell
end)
----@type CommerceConfigParser
local CommerceConfigParser = require("Game.Datas.Parser.CommerceConfigParser")
local futuresConf = CommonUtils.GetConfigAllMess(CommerceConfigParser.TYPE.FUTURES , 'commerce')
local blackGoldMgr = app.blackGoldMgr
local newImageView = display.newImageView
local newLabel = display.newLabel
local newLayer = display.newLayer
local RES_DICT = {
	GOLD_TRADE_BUY_BG_LIST        = _res('ui/home/blackShop/gold_trade_buy_bg_list.png'),
	GOLD_TRADE_WARE_LIST_JIAOB    = _res('ui/home/blackShop/gold_trade_ware_list_jiaob.png'),
	GOODS_ICON_900026             = _res('arts/goods/goods_icon_900026.png'),
}
function TradeFuturesCell:ctor()
	self:setContentSize(cc.size(208, 240))
	local futuresLayout = newLayer(208/2, 240/2 ,
			{ ap = display.CENTER, color = cc.r4b(0), size = cc.size(175, 237), enable = true })
	self:addChild(futuresLayout)
	local cellBgImage = FilteredSpriteWithOne:create(RES_DICT.GOLD_TRADE_BUY_BG_LIST)
	cellBgImage:setAnchorPoint(display.LEFT_BOTTOM)
	cellBgImage:setPosition(0, -2)
	futuresLayout:addChild(cellBgImage)
	local goodImage = newImageView(RES_DICT.GOODS_ICON_900026, 175/2, 237/2+20,
			{ ap = display.CENTER, tag = 214, enable = false })
	futuresLayout:addChild(goodImage)
	goodImage:setScale(0.8)


	local goodsName = newLabel(86, 53,
			{ ap = display.CENTER, color = '#53341d', text = "", fontSize = 22, tag = 215 })
	futuresLayout:addChild(goodsName)

	local priceLabel = newLabel(87.5, 24,
			{ ap = cc.p(0.633700 ,0.615400) , color = '#53341d', text = "", fontSize = 22, tag = 216 })
	futuresLayout:addChild(priceLabel)

	local soldImage = newImageView(RES_DICT.GOLD_TRADE_WARE_LIST_JIAOB, -6, 176,
			{ ap = display.LEFT_BOTTOM, tag = 217, enable = false , scale9 = true , size = cc.size(100 , 40) })
	futuresLayout:addChild(soldImage)

	local soldLabel = newLabel(10, 18,
			{ ap = display.LEFT_CENTER, color = '#ffffff', text = "", fontSize = 22, tag = 218 })
	soldImage:addChild(soldLabel)
	soldImage:setVisible(false)

	local iconImage = newImageView(RES_DICT.GOODS_ICON_900026, 132, 4,
			{ ap = display.LEFT_BOTTOM, tag = 219, enable = false })
	futuresLayout:addChild(iconImage)
	iconImage:setScale(0.2)

	local soldOutLabel = newLabel(16, 196,
			fontWithColor(14,{ ap = display.LEFT_CENTER, outline = false,  color = '#d43b38', text = __('售罄'), fontSize = 22, tag = 220 }))
	futuresLayout:addChild(soldOutLabel)
	soldOutLabel:setVisible(false)

	self.viewData =  {
		futuresLayout           = futuresLayout,
		cellBgImage             = cellBgImage,
		goodImage               = goodImage,
		goodsName               = goodsName,
		priceLabel              = priceLabel,
		soldImage               = soldImage,
		soldLabel               = soldLabel,
		iconImage               = iconImage,
		soldOutLabel            = soldOutLabel,
	}
end
function TradeFuturesCell:UpdateView(data)
	local viewData = self.viewData
	local name = futuresConf[tostring(data.futuresId)].name
	local stock = checkint(data.stock)
	local futuresPath = blackGoldMgr:GetFuturesPtahByFutureId(data.futuresId)
	viewData.soldLabel:setString(  data.leftPurchase .. "/"..  tostring(stock))
	viewData.goodImage:setTexture(futuresPath)
	viewData.goodsName:setString(name)
	viewData.priceLabel:setString(data.price)
	if data.leftPurchase > 0  then
		viewData.cellBgImage:clearFilter()
		viewData.soldImage:setVisible(true)
		viewData.soldOutLabel:setVisible(false)
		viewData.goodsName:setColor(ccc3FromInt("#53341d"))
		viewData.priceLabel:setColor(ccc3FromInt("#53341d"))
	else
		viewData.goodsName:setColor(ccc3FromInt("#525252"))
		viewData.priceLabel:setColor(ccc3FromInt("#525252"))
		viewData.soldImage:setVisible(false)
		viewData.soldOutLabel:setVisible(true)
		viewData.cellBgImage:setFilter(GrayFilter:create())
	end
end



return TradeFuturesCell
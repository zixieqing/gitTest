--[[
活动每日签到Cell
--]]
---@class TradeFuturesBuyCell
local TradeFuturesBuyCell = class('TradeFuturesBuyCell', function ()
	local TradeFuturesBuyCell = CGridViewCell:new()
	TradeFuturesBuyCell.name = 'home.TradeFuturesBuyCell'
	TradeFuturesBuyCell:enableNodeEvents()
	return TradeFuturesBuyCell
end)
----@type CommerceConfigParser
local CommerceConfigParser = require("Game.Datas.Parser.CommerceConfigParser")
local futuresConf = CommonUtils.GetConfigAllMess(CommerceConfigParser.TYPE.FUTURES , 'commerce')
local blackGoldMgr = app.blackGoldMgr
local newImageView = display.newImageView
local newLabel = display.newLabel
local newLayer = display.newLayer
local RES_DICT = {
	GOLD_TRADE_WARE_BG_LIST_BQ        = _res('ui/home/blackShop/gold_trade_ware_bg_list_bq.png'),
	GOLD_TRADE_WARE_LIST_JIAOB    = _res('ui/home/blackShop/gold_trade_ware_list_jiaob.png'),
	GOODS_ICON_900026             = _res('arts/goods/goods_icon_900026.png'),
}
function TradeFuturesBuyCell:ctor()
	self:setContentSize(cc.size(180, 194))
	local futuresLayout = newLayer(90, 92 ,
			{ ap = display.CENTER, color = cc.r4b(0), size = cc.size(172, 174), enable = true })
	self:addChild(futuresLayout)
	local cellBgImage = newImageView(RES_DICT.GOLD_TRADE_WARE_BG_LIST_BQ, 0, -2,
			{ ap = display.LEFT_BOTTOM, tag = 213, enable = false })
	futuresLayout:addChild(cellBgImage)

	local goodImage = newImageView(RES_DICT.GOODS_ICON_900026, 86, 90,
			{ ap = display.CENTER, tag = 214, enable = false })
	futuresLayout:addChild(goodImage)
	goodImage:setScale(0.8)

	local goodsName = newLabel(86, 20,
			{ ap = display.CENTER, color = '#53341d', text = "111", fontSize = 22, tag = 215 })
	futuresLayout:addChild(goodsName)


	local soldImage = newImageView(RES_DICT.GOLD_TRADE_WARE_LIST_JIAOB, -6, 121,
			{ ap = display.LEFT_BOTTOM, tag = 217, enable = false })
	futuresLayout:addChild(soldImage)

	local soldLabel = newLabel(26, 18,
			{ ap = display.CENTER, color = '#ffffff', text = "", fontSize = 20, tag = 218 })
	soldImage:addChild(soldLabel)
	self.viewData = {
		futuresLayout           = futuresLayout,
		cellBgImage             = cellBgImage,
		goodImage               = goodImage,
		goodsName               = goodsName,
		soldImage               = soldImage,
		soldLabel               = soldLabel,
	}
end
function TradeFuturesBuyCell:UpdateView(data)
	local viewData = self.viewData
	local name = futuresConf[tostring(data.futuresId)].name
	local stock = checkint(data.stock)
	local futuresPath = blackGoldMgr:GetFuturesPtahByFutureId(data.futuresId)
	viewData.soldLabel:setString(tostring(stock))
	viewData.goodImage:setTexture(futuresPath)
	viewData.goodsName:setString(name)
end



return TradeFuturesBuyCell
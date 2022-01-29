--[[
活动每日签到Cell
--]]
---@class TradeFuturesSellCell
local TradeFuturesSellCell = class('TradeFuturesSellCell', function ()
	local TradeFuturesSellCell = CGridViewCell:new()
	TradeFuturesSellCell.name = 'home.TradeFuturesSellCell'
	TradeFuturesSellCell:enableNodeEvents()
	return TradeFuturesSellCell
end)
----@type CommerceConfigParser
local CommerceConfigParser = require("Game.Datas.Parser.CommerceConfigParser")
local futuresConf = CommonUtils.GetConfigAllMess(CommerceConfigParser.TYPE.FUTURES , 'commerce')

local newImageView = display.newImageView
local newLabel = display.newLabel
local newLayer = display.newLayer
local RES_DICT = {
	GOLD_TRADE_WARE_BG_LIST_RED        = _res('ui/home/blackShop/gold_trade_ware_bg_list_red.png'),
	GOLD_TRADE_WARE_LIST_JIAOB    = _res('ui/home/blackShop/gold_trade_ware_list_jiaob.png'),
	GOLD_TRADE_WARE_BG_LIST_GREEN = _res('ui/home/blackShop/gold_trade_ware_bg_list_green.png'),
	GOODS_ICON_900026             = _res('arts/goods/goods_icon_900026.png'),
}
local blackGoldMgr = app.blackGoldMgr
function TradeFuturesSellCell:ctor()
	self:setContentSize(cc.size(208, 240))

	local futuresLayout = newLayer(208/2, 237/2 ,
	{ ap = display.CENTER, color = cc.r4b(0), size = cc.size(173, 209), enable = true })
	self:addChild(futuresLayout)

	local cellBgImage = newImageView(RES_DICT.GOLD_TRADE_WARE_BG_LIST_RED, 0, -2,
	{ ap = display.LEFT_BOTTOM, tag = 213, enable = false })
	futuresLayout:addChild(cellBgImage)

	local goodImage = newImageView(RES_DICT.GOODS_ICON_900026, 22, 61,
	{ ap = display.LEFT_BOTTOM, tag = 214, enable = false })
	futuresLayout:addChild(goodImage)
	goodImage:setScale(0.8)

	local goodsName = newLabel(173/2, 53,
	{ ap = display.CENTER, color = '#53341d', text = "111", fontSize = 22, tag = 215 })
	futuresLayout:addChild(goodsName)

	local priceLabel = newLabel(173/2, 20,
			{ ap = display.CENTER , color = '#53341d', text = "1111", fontSize = 22, tag = 216 })
	futuresLayout:addChild(priceLabel)

	local soldImage = newImageView(RES_DICT.GOLD_TRADE_WARE_LIST_JIAOB, -9, 151,
			{ ap = display.LEFT_BOTTOM, tag = 217, enable = false })
	futuresLayout:addChild(soldImage)

	local soldLabel = newLabel(26, 18,
			{ ap = display.CENTER, color = '#ffffff', text = "111", fontSize = 20, tag = 218 })
	soldImage:addChild(soldLabel)

	local iconImage = newImageView(RES_DICT.GOODS_ICON_900026, 132, 4,
			{ ap = display.LEFT_BOTTOM, tag = 219, enable = false })
	futuresLayout:addChild(iconImage)
	iconImage:setScale(0.2)

	self.viewData = {
		futuresLayout           = futuresLayout,
		cellBgImage             = cellBgImage,
		goodImage               = goodImage,
		goodsName               = goodsName,
		priceLabel              = priceLabel,
		soldImage               = soldImage,
		soldLabel               = soldLabel,
		iconImage               = iconImage
	}

end


function TradeFuturesSellCell:UpdateView(data)
	local status = blackGoldMgr:GetStatus()
	local text = ""
	local color = "#D20000"
	local texture = RES_DICT.GOLD_TRADE_WARE_BG_LIST_RED
	if status == 1 then -- 出海中
		text = "---"
		color ="#53341d"
	else  -- 靠岸

		text = data.profit
		if  data.profit < 0  then
			color = "#439c02"
			texture =  RES_DICT.GOLD_TRADE_WARE_BG_LIST_GREEN
		end
	end

	local viewData = self.viewData
	local name = futuresConf[tostring(data.futuresId)].name
	local stock = checkint(data.stock)
	local futuresPath = blackGoldMgr:GetFuturesPtahByFutureId(data.futuresId)
	viewData.soldLabel:setString(tostring(stock))
	viewData.goodImage:setTexture(futuresPath)
	viewData.goodsName:setString(name)
	viewData.priceLabel:setString(text)
	viewData.priceLabel:setColor(ccc3FromInt(color))
	viewData.cellBgImage:setTexture(texture)
end



return TradeFuturesSellCell
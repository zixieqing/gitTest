--[[
活动每日签到Cell
--]]
---@class OrderCell
local OrderCell = class('OrderCell', function ()
	local OrderCell = CGridViewCell:new()
	OrderCell.name = 'home.OrderCell'
	OrderCell:enableNodeEvents()
	return OrderCell
end)

local RES_DICT = {
	ORDER_BG_PUBLIC_NAME  = _res("ui/home/carexplore/order_bg_public_name.png"),
	ORDER_BG_PRIVATE_NAME = _res("ui/home/carexplore/order_bg_private_name.png"),
	ORDER_BG_SEND_TIME    = _res("ui/home/carexplore/order_bg_send_time.png"),
	ORDER_BG_REST_2    = _res("ui/home/carexplore/order_bg_rest_2.png"),
	COMMON_BG_GOODS       = _res("ui/common/common_bg_goods.png")
}
function OrderCell:ctor()
	local bgSize = cc.size(525, 150)
	self:setContentSize(bgSize)
	self:setCascadeOpacityEnabled(true)
	local bgImage = display.newImageView(RES_DICT.ORDER_BG_REST_2 ,bgSize.width/2+2 , bgSize.height/2 , {
		size = bgSize , scale9 = true
	})
	self:addChild(bgImage)

	local button = display.newButton(525/2 , 150/2 , {size = bgSize , enable = true })
	self:addChild(button)

	local orderImage = display.newImageView(RES_DICT.ORDER_BG_PUBLIC_NAME ,-2 , bgSize.height-1 , {ap =display.LEFT_TOP}  )
	self:addChild(orderImage)
	local orderImageSize = orderImage:getContentSize()
	local orderName = display.newLabel(10 , orderImageSize.height /2 , {ap = display.LEFT_CENTER ,  fontSize = 24 , color = "#ffffff", text = "" })
	orderImage:addChild(orderName)


	local sendTimeSize = cc.size(180 , 70 )
	local sendTimeImage = display.newImageView(RES_DICT.ORDER_BG_SEND_TIME , sendTimeSize.width/2 , sendTimeSize.height/2 )
	local sendTimeLayout = display.newLayer(426 , 70,  {size  = sendTimeSize , ap = display.CENTER})
	sendTimeLayout:addChild(sendTimeImage)

	local sendLabel = display.newLabel(sendTimeSize.width /2 , sendTimeSize.height * 3/4 ,fontWithColor('6',{text = __('配送时间：')}))
	sendTimeLayout:addChild(sendLabel)

	local sendTimeLabel = display.newLabel(sendTimeSize.width/2 , sendTimeSize.height /4 , fontWithColor(10,{text = "11111" }))
	sendTimeLayout:addChild(sendTimeLabel)
	self:addChild(sendTimeLayout)
	local goodNodes = {}

	local width = 100
	for i = 1 , 3 do
		local goodNode = require('common.GoodNode').new({goodsId = DIAMOND_ID})
		goodNode:setPosition(60 + (i - 1) * width , bgSize.height /2 - 7 )
		goodNode:setScale(0.83)
		local label = display.newLabel(60 , -13 , fontWithColor(6, {fontSize = 24 ,  text = ""}))
		label:setTag(100001)
		goodNode:addChild(label)
		goodNodes[#goodNodes+1] = goodNode
		self:addChild(goodNode)
	end
	self.viewData = {
		bgImage        = bgImage,
		orderImage     = orderImage,
		sendLabel      = sendLabel,
		goodNodes      = goodNodes,
		orderName      = orderName,
		sendTimeLayout = sendTimeLayout,
		sendTimeLabel  = sendTimeLabel,
		button         = button,

	}
end

function OrderCell:UpdatePrivateOrder(data)
	local viewData = self.viewData
	local takeawayId = data.takeawayId
	local privateOrderConf = CommonUtils.GetConfigAllMess('privateOrder','takeaway')
	local privateOrderOneConf = privateOrderConf[tostring(takeawayId)]
	local foods = privateOrderOneConf.foods
	local orderKeys = table.keys(foods)
	for i = 1,  #viewData.goodNodes do
		---@type GoodNode
		local goodNode = viewData.goodNodes[i]
		if orderKeys[i] then
			goodNode:setVisible(true)
			goodNode:RefreshSelf({ goodsId = orderKeys[i]})
			local label = goodNode:getChildByTag(100001)
			local num = CommonUtils.GetCacheProductNum(orderKeys[i])
			label:setString( num .."/" ..foods[tostring(orderKeys[i])] )
		else
			goodNode:setVisible(false)
		end

	end
	local deliveryTime =  (checkint(data.deliveryTime)  +  150) *2
	local leftSecondsStr = string.formattedTime(deliveryTime ,"%02i:%02i:%02i")
	display.commonLabelParams(viewData.sendTimeLabel , {text = leftSecondsStr})
	display.commonLabelParams(viewData.orderName , {text = privateOrderOneConf.name or "" })
	viewData.orderImage:setTexture(RES_DICT.ORDER_BG_PRIVATE_NAME)
end


function OrderCell:UpdatePublishOrder(data)
	local viewData            = self.viewData
	local takeawayId          = data.takeawayId
	local publishOrderConf    = CommonUtils.GetConfigAllMess('publicOrder','takeaway')
	local publishOrderOneConf = publishOrderConf[tostring(takeawayId)]
	local foods               = publishOrderOneConf.foods
	local orderKeys           = table.keys(foods)
	for i = 1,  #viewData.goodNodes do
		---@type GoodNode
		local goodNode = viewData.goodNodes[i]
		if orderKeys[i] then
			goodNode:setVisible(true)
			goodNode:RefreshSelf({ goodsId = orderKeys[i]})
			local label = goodNode:getChildByTag(100001)
			local num = CommonUtils.GetCacheProductNum(orderKeys[i])
			label:setString( num .."/" ..foods[tostring(orderKeys[i])] )
		else
			goodNode:setVisible(false)
		end
	end
	display.commonLabelParams(viewData.sendLabel , {text = __('订单消失时间：')})
	display.commonLabelParams(viewData.orderName , {text = publishOrderOneConf.name or "" })
	viewData.sendTimeLayout:setVisible(true)
	local endLeftSeconds = data.endLeftSeconds
	local leftSecondsStr = string.formattedTime(endLeftSeconds ,"%02i:%02i:%02i")
	display.commonLabelParams(viewData.sendTimeLabel , {text = leftSecondsStr})
	viewData.orderImage:setTexture(RES_DICT.ORDER_BG_PUBLIC_NAME)
end
function OrderCell:UpdatePublishTime(data)
	local viewData = self.viewData
	viewData.sendTimeLayout:setVisible(true)
	local endLeftSeconds = data.endLeftSeconds
	local leftSecondsStr = string.formattedTime(endLeftSeconds ,"%02i:%02i:%02i")
	display.commonLabelParams(viewData.sendTimeLabel , {text = leftSecondsStr})
end
return OrderCell
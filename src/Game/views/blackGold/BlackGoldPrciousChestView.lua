---@class BlackGoldPrciousChestView
local BlackGoldPrciousChestView = class('BlackGoldPrciousChestView', function()
	local layout = CLayout:create(cc.size(689, 527))
	return layout
end)
local newImageView = display.newImageView
local newButton = display.newButton
local newLayer = display.newLayer
local newLabel = display.newLabel
local BUTTON_TAG = {
	LOTTERY_BTN = 1004,
	DIRECTLY_BTN = 1005,
	LOG_BTN = 1006,
}
local RES_DICT = {
	COMMON_DECORATE_KNIFE     = _res('ui/common/common_decorate_knife_3.png'),
	GOLD_CARGO_BTN_GIFT       = _res('ui/home/blackShop/gold_cargo_btn_gift.png'),
	GOLD_CARGO_BG_LIBAO       = _res('ui/home/blackShop/gold_cargo_bg_libao.png'),
	GOLD_CARGO_BG_BUTTON      = _res('ui/home/blackShop/gold_cargo_bg_button.png'),
	GOLD_CARGO_BG_BUTTON_GREY = _res('ui/home/blackShop/gold_cargo_bg_button_grey.png'),
	COMMON_BTN_BIG_ORANGE     = _res('ui/common/common_btn_big_orange.png'),
	GOODS_ICON_880009         = _res('arts/goods/goods_icon_900026.png'),
	ACTIVITY_MIFAN_BY_ICO     = _res('ui/common/activity_mifan_by_ico.png'),
	GOLD_BINGO_TZ_XIAN        = _res('ui/home/blackShop/gold_bingo_tz_xian.png'),
	COMMON_BTN_TIPS           = _res('ui/common/common_btn_tips.png'),
}
function BlackGoldPrciousChestView:ctor(params )
	self:InitUI()
end

function BlackGoldPrciousChestView:InitUI()
	local rarityGoodsLayout = newLayer(689/2, 527/2,
			{ ap = display.CENTER,  size = cc.size(689, 527)})
	self:addChild(rarityGoodsLayout)

	local lineImage = newImageView(RES_DICT.COMMON_DECORATE_KNIFE, 343, 465,
			{ ap = display.CENTER, tag = 433, enable = false })
	rarityGoodsLayout:addChild(lineImage)

	local logBtn = newButton(655, 498, { enable = true ,  ap = display.CENTER ,  n = RES_DICT.GOLD_CARGO_BTN_GIFT, d = RES_DICT.GOLD_CARGO_BTN_GIFT, s = RES_DICT.GOLD_CARGO_BTN_GIFT, scale9 = true, size = cc.size(70, 70), tag = 434 })
	display.commonLabelParams(logBtn, {text = "", fontSize = 14, color = '#414146'})
	rarityGoodsLayout:addChild(logBtn)
	logBtn:setTag(BUTTON_TAG.LOG_BTN)


	local skinTitle = newLabel(343, 488,
			fontWithColor(14, { ap = display.CENTER, color = '#ffcb69', text = "", outline = "#402008" , outlineSize = 2,  fontSize = 22, tag = 435 }))
	rarityGoodsLayout:addChild(skinTitle)

	local goodContentLayout = newLayer(0, 0,
			{ ap = display.LEFT_BOTTOM, size = cc.size(679, 442) })
	rarityGoodsLayout:addChild(goodContentLayout)

	local goodContentBgImage = newImageView(RES_DICT.GOLD_CARGO_BG_LIBAO, 0, 0,
			{ ap = display.LEFT_BOTTOM, tag = 436, enable = false })
	goodContentLayout:addChild(goodContentBgImage)

	local cargoImage = newImageView(RES_DICT.GOLD_CARGO_BG_BUTTON, 192, 131,
			{ ap = display.CENTER, tag = 438, enable = false })
	goodContentLayout:addChild(cargoImage)


	local makeDrawBtn = newButton(194, 140, { ap = display.CENTER ,  n = RES_DICT.COMMON_BTN_BIG_ORANGE, d = RES_DICT.COMMON_BTN_BIG_ORANGE, s = RES_DICT.COMMON_BTN_BIG_ORANGE, scale9 = true, size = cc.size(148, 71), tag = 439 })
	display.commonLabelParams(makeDrawBtn, fontWithColor(14,{text = "", outline = false,  fontSize = 24, color = '#ffffff'}))
	goodContentLayout:addChild(makeDrawBtn)
	makeDrawBtn:setTag(BUTTON_TAG.LOTTERY_BTN)

	local goodIcon = newImageView(RES_DICT.GOODS_ICON_880009, 241, 86,
			{ ap = display.CENTER, tag = 440, enable = false })
	goodContentLayout:addChild(goodIcon)
	goodIcon:setScale(0.25)

	local goodNum = newLabel(219, 89,
			{ ap = display.RIGHT_CENTER, color = '#53341D', text = "", fontSize = 22, tag = 441 })
	goodContentLayout:addChild(goodNum)

	local openPrizeTime = newLabel(197, 43,
			{ ap = display.LEFT_CENTER, color = '#a35800', text = "", fontSize = 22, tag = 443 })
	goodContentLayout:addChild(openPrizeTime)

	local openPrizeLabel = newLabel(176, 43,
			{ ap = display.RIGHT_CENTER, color = '#53341d', text = __('开奖倒计时:'), fontSize = 22, tag = 444 })
	goodContentLayout:addChild(openPrizeLabel)

	local buyBtnBgImage = display.newImageView(RES_DICT.GOLD_CARGO_BG_BUTTON_GREY ,513, 133 )
	goodContentLayout:addChild(buyBtnBgImage)
	local fullSerLimitNum = newLabel(527, 43,
			{ ap = display.LEFT_CENTER, color = '#a35800', text = "", fontSize = 20, tag = 442 })
	goodContentLayout:addChild(fullSerLimitNum)

	local fullSerLimitLabel = newLabel(506, 43,
			{ ap = display.RIGHT_CENTER, color = '#53341d', text = __('全服限量:'), fontSize = 22, tag = 445 })
	goodContentLayout:addChild(fullSerLimitLabel)

	local buyBtn = newButton(513, 139, { ap = display.CENTER ,  n = RES_DICT.ACTIVITY_MIFAN_BY_ICO, d = RES_DICT.ACTIVITY_MIFAN_BY_ICO, s = RES_DICT.ACTIVITY_MIFAN_BY_ICO, scale9 = true, size = cc.size(135, 68), tag = 446 })
	display.commonLabelParams(buyBtn, fontWithColor(14,{text = "", fontSize = 24, color = '#ffffff'}))
	goodContentLayout:addChild(buyBtn)
	buyBtn:setTag(BUTTON_TAG.DIRECTLY_BTN)

	local lineImage_1 = newImageView(RES_DICT.GOLD_BINGO_TZ_XIAN, 284, 298,
			{ ap = display.CENTER, tag = 447, enable = false })
	goodContentLayout:addChild(lineImage_1)

	local goodsImage = newImageView(RES_DICT.GOODS_ICON_880009, 150, 320,
			{ ap = display.CENTER, tag = 433, enable = false })
	rarityGoodsLayout:addChild(goodsImage)


	local oneKeyImage = newImageView(RES_DICT.GOODS_ICON_880009, 241+ 334, 86,
			{ ap = display.CENTER, tag = 440, enable = false })
	goodContentLayout:addChild(oneKeyImage)
	oneKeyImage:setScale(0.25)

	local oneKeyGoodNum = newLabel(219+ 334, 89,
			{ ap = display.RIGHT_CENTER, color = '#53341D', text = "", fontSize = 22, tag = 441 })
	goodContentLayout:addChild(oneKeyGoodNum)

	self.viewData = {
		rarityGoodsLayout  = rarityGoodsLayout,
		lineImage          = lineImage,
		logBtn             = logBtn,
		skinTitle          = skinTitle,
		goodContentLayout  = goodContentLayout,
		goodContentBgImage = goodContentBgImage,
		cargoImage         = cargoImage,
		makeDrawBtn        = makeDrawBtn,
		goodIcon           = goodIcon,
		goodNum            = goodNum,
		openPrizeTime      = openPrizeTime,
		openPrizeLabel     = openPrizeLabel,
		fullSerLimitNum    = fullSerLimitNum,
		fullSerLimitLabel  = fullSerLimitLabel,
		buyBtn             = buyBtn,
		oneKeyImage        = oneKeyImage,
		oneKeyGoodNum      = oneKeyGoodNum,
		goodsImage         = goodsImage,
		lineImage_1        = lineImage_1,
	}
end
function BlackGoldPrciousChestView:UpdateView(data)
	local viewData = self.viewData
	local goodsId = data.goodsId
	local goodOneConf = CommonUtils.GetConfig('goods','goods' , goodsId) or {}
	local name = goodOneConf.name or ""
	local goodsPth = CommonUtils.GetGoodsIconPathById(data.goodsId)
	local price = data.price
	local lotteryPrice = data.lotteryPrice
	local lotteryLeftSeconds = checkint(data.lotteryLeftSeconds)

	local goodsSize = cc.size(93, 93 )
	local pos = cc.p(330, 355 )
	local count = #data.chestRewards
	for i = 1, count do
		data.chestRewards[i].showAmount = true
		local numBei = math.floor((i - 0.5)/3)
		local mod = (i - 0.5) % 3
		local chestPos = cc.p( pos.x + mod  * goodsSize.width ,pos.y - (numBei * goodsSize.height) )
		local goodNode = require("common.GoodNode").new(data.chestRewards[i])
		goodNode:setPosition(chestPos)
		goodNode:setScale(0.8)
		viewData.rarityGoodsLayout:addChild(goodNode)
		display.commonUIParams(goodNode , {animate = false , cb = function(sender)
			app.uiMgr:ShowInformationTipsBoard({ targetNode = sender, iconId = data.chestRewards[i].goodsId, type = 1 })
		end})
	end
	viewData.goodsImage:setTexture(goodsPth)
	display.commonLabelParams(viewData.skinTitle , {text = name })
	-- 已购买
	if  checkint(data.hasPurchased) == 1  then
		display.commonLabelParams(viewData.buyBtn,fontWithColor(14,{text = __('已购买'), color  ="#53341D"  , outline = false, outlineSize = 0  }))
		viewData.buyBtn:setNormalImage(RES_DICT.ACTIVITY_MIFAN_BY_ICO)
		viewData.buyBtn:setSelectedImage(RES_DICT.ACTIVITY_MIFAN_BY_ICO)
		viewData.fullSerLimitNum:setVisible(false)
		viewData.fullSerLimitLabel:setVisible(false)
	else
		display.commonLabelParams(viewData.buyBtn,fontWithColor(14,{text = __('购买')}))
		viewData.buyBtn:setNormalImage(RES_DICT.COMMON_BTN_BIG_ORANGE)
		viewData.buyBtn:setSelectedImage(RES_DICT.COMMON_BTN_BIG_ORANGE)
		viewData.fullSerLimitNum:setString(data.leftPurchasedNum .. '/' .. data.stock)
	end

	if  checkint(data.hasLottery) == 1  then
		display.commonLabelParams(viewData.makeDrawBtn,fontWithColor(14,{text = __('已预约'), color  ="#53341D"  , outline = false , outlineSize = 0 }))
		viewData.makeDrawBtn:setNormalImage(RES_DICT.ACTIVITY_MIFAN_BY_ICO)
		viewData.makeDrawBtn:setSelectedImage(RES_DICT.ACTIVITY_MIFAN_BY_ICO)
	else
		display.commonLabelParams(viewData.makeDrawBtn,fontWithColor(14,{text = __('预约抽奖')  , outlineSize = 0  }))
		viewData.makeDrawBtn:setNormalImage(RES_DICT.COMMON_BTN_BIG_ORANGE)
		viewData.makeDrawBtn:setSelectedImage(RES_DICT.COMMON_BTN_BIG_ORANGE)
	end


	viewData.goodNum:setString(lotteryPrice)
	viewData.oneKeyGoodNum:setString(price)
	viewData.openPrizeTime:stopAllActions()
	viewData.openPrizeTime:runAction(
		cc.RepeatForever:create(
			cc.Sequence:create(
				cc.CallFunc:create(function()
					local currentTime = os.time()
					local recordTime = data.recordTime
					local distanceTime  = currentTime -  recordTime
					local time = lotteryLeftSeconds - distanceTime
					if time >= 0  then
						local str = string.formattedTime(time , "%02i:%02i:%02i")
						viewData.openPrizeTime:setString(str)
					else
						viewData.openPrizeTime:setString("00:00:00")
					end
				end),
				cc.DelayTime:create(1)
			)
		)
	)
end

function BlackGoldPrciousChestView:onClean()

end
return BlackGoldPrciousChestView

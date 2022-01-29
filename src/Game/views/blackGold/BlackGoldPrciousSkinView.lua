---@class BlackGoldPrciousSkinView
local BlackGoldPrciousSkinView = class('BlackGoldPrciousSkinView', function()
	local layout = CLayout:create(cc.size(689, 527))
	return layout
end)
local newImageView = display.newImageView
local newLabel = display.newLabel
local newButton = display.newButton
local newLayer = display.newLayer
local RES_DICT = {
	ACTIVITY_MIFAN_BY_ICO         = _res('ui/common/activity_mifan_by_ico.png'),
	COMMON_DECORATE_KNIFE_2       = _res('ui/common/common_decorate_knife_2.png'),
	GOODS_ICON_880009             = _res('arts/goods/goods_icon_900026.png'),
	GOLD_CARGO_BG_BUTTON          = _res('ui/home/blackShop/gold_cargo_bg_button.png'),
	COMMON_BTN_BIG_ORANGE         = _res('ui/common/common_btn_big_orange.png'),
	GOLD_CARGO_BTN_GIFT           = _res('ui/home/blackShop/gold_cargo_btn_gift.png'),
	GOLD_CARGO_BG_PIFU            = _res('ui/home/blackShop/gold_cargo_bg_pifu.png'),
	GOLD_CARGO_BG_BUTTON_GREY          = _res('ui/home/blackShop/gold_cargo_bg_button_grey.png'),
}
local BUTTON_TAG = {
	LOTTERY_BTN = 1004,
	DIRECTLY_BTN = 1005,
	LOG_BTN = 1006,
}
function BlackGoldPrciousSkinView:ctor(params )
	self:InitUI()
end

function BlackGoldPrciousSkinView:InitUI()

	local rarityGoodsLayout = newLayer(689/2, 527/2,
			{ ap = display.CENTER, size = cc.size(689, 527) })
	self:addChild(rarityGoodsLayout)

	local logBtn = newButton(655, 498, {enable = true ,  ap = display.CENTER ,  n = RES_DICT.GOLD_CARGO_BTN_GIFT, d = RES_DICT.GOLD_CARGO_BTN_GIFT, s = RES_DICT.GOLD_CARGO_BTN_GIFT, scale9 = true, size = cc.size(70, 70), tag = 106 })
	display.commonLabelParams(logBtn, {text = "", fontSize = 14, color = '#414146'})

	rarityGoodsLayout:addChild(logBtn)
	logBtn:setTag(BUTTON_TAG.LOG_BTN)


	local goodContentBgImage = newImageView(RES_DICT.GOLD_CARGO_BG_PIFU, 263, 9,
			{ ap = display.LEFT_BOTTOM, tag = 109, enable = false })
	rarityGoodsLayout:addChild(goodContentBgImage)

	local cargoImage = newImageView(RES_DICT.GOLD_CARGO_BG_BUTTON, 442, 300,
			{ ap = display.CENTER, tag = 110, enable = false })
	rarityGoodsLayout:addChild(cargoImage)
	local buyBtnBgImage = display.newImageView(RES_DICT.GOLD_CARGO_BG_BUTTON_GREY ,435, 120 )
	rarityGoodsLayout:addChild(buyBtnBgImage)
	local oneKeyGoodNum = newLabel(457, 79,
			{ ap = display.RIGHT_CENTER,  color = '#53341D', text = "", fontSize = 22, tag = 122 })
	rarityGoodsLayout:addChild(oneKeyGoodNum)

	local oneKeyImage = newImageView(RES_DICT.GOODS_ICON_880009, 479, 76,
			{ ap = display.CENTER, tag = 121, enable = false })
	rarityGoodsLayout:addChild(oneKeyImage)
	oneKeyImage:setScale(0.3)

	local buyBtn = newButton(435, 131, { ap = display.CENTER ,  n = RES_DICT.ACTIVITY_MIFAN_BY_ICO, d = RES_DICT.ACTIVITY_MIFAN_BY_ICO, s = RES_DICT.ACTIVITY_MIFAN_BY_ICO, scale9 = true, size = cc.size(135, 68), tag = 118 })
	display.commonLabelParams(buyBtn, fontWithColor(14,{text = '预约抽奖', fontSize = 24, color = '#ffffff'}))
	rarityGoodsLayout:addChild(buyBtn,2)
	buyBtn:setTag(BUTTON_TAG.DIRECTLY_BTN)

	local fullSerLimitLabel = newLabel(433, 31,
			{ ap = display.RIGHT_CENTER,  color = '#53341d', text = __('全服限量:'), fontSize = 22, tag = 117 })
	rarityGoodsLayout:addChild(fullSerLimitLabel)

	local fullSerLimitNum = newLabel(454, 31,
			{ ap = display.LEFT_CENTER, color = '#a35800', text = "", fontSize = 22, tag = 116 })
	rarityGoodsLayout:addChild(fullSerLimitNum)

	local openPrizeLabel = newLabel(429, 214,
			{ ap = display.RIGHT_CENTER, color = '#53341d', text = __('开奖倒计时:'), fontSize = 22, tag = 115 })
	rarityGoodsLayout:addChild(openPrizeLabel)

	local openPrizeTime = newLabel(450, 214,
			{ ap = display.LEFT_CENTER, color = '#a35800', text = "", fontSize = 22, tag = 114 })
	rarityGoodsLayout:addChild(openPrizeTime)

	local goodNum = newLabel(469, 262,
			{ ap = display.RIGHT_CENTER, color = '#53341D', text = "", fontSize = 22, tag = 113 })
	rarityGoodsLayout:addChild(goodNum)

	local goodIcon = newImageView(RES_DICT.GOODS_ICON_880009, 491, 259,
			{ ap = display.CENTER, tag = 112, enable = false })
	rarityGoodsLayout:addChild(goodIcon)
	goodIcon:setScale(0.3)

	local makeDrawBtn = newButton(444, 316, { ap = display.CENTER ,  n = RES_DICT.COMMON_BTN_BIG_ORANGE, d = RES_DICT.COMMON_BTN_BIG_ORANGE, s = RES_DICT.COMMON_BTN_BIG_ORANGE, scale9 = true, size = cc.size(148, 71), tag = 111 })
	display.commonLabelParams(makeDrawBtn, fontWithColor(14,{text = '预约抽奖', fontSize = 24, color = '#ffffff'}))
	rarityGoodsLayout:addChild(makeDrawBtn)
	makeDrawBtn:setTag(BUTTON_TAG.LOTTERY_BTN)

	local skinTitle = newLabel(431, 481,
			fontWithColor(14,{ ap = display.CENTER, color = '#ffcb69', text = "", outline = "#402008" , outlineSize = 2, fontSize = 22, tag = 107 }))
	rarityGoodsLayout:addChild(skinTitle)

	local cardNameOne = newLabel(431, 435,
			fontWithColor(14,{ ap = display.CENTER,  outline = "#402008" ,text = "", fontSize = 24, tag = 123 }))
	rarityGoodsLayout:addChild(cardNameOne)

	local lineImage = newImageView(RES_DICT.COMMON_DECORATE_KNIFE_2, 438, 398,
			{ ap = display.CENTER, tag = 105, enable = false })
	rarityGoodsLayout:addChild(lineImage)
	local size =  cc.size(234 , 558)
	local eventNode = CLayout:create(cc.size(230, 558))
	--eventNode:setPosition(utils.getLocalCenter(self))
	eventNode:setAnchorPoint(display.LEFT_BOTTOM )
	self:addChild(eventNode)
	eventNode:setScale(0.9)
	eventNode:setPosition(20,8)
	local toggleView = display.newButton(size.width * 0.5 ,size.height * 0.5,{--
		n = _res('ui/stores/cardSkin/shop_btn_skin_default.png'),
		s = _res('ui/stores/cardSkin/shop_btn_skin_default.png')
	})
	eventNode:addChild(toggleView,10)
	local lsize = cc.size(200 , 550)
	local roleClippingNode = cc.ClippingNode:create()
	roleClippingNode:setContentSize(cc.size(lsize.width , lsize.height -10))
	roleClippingNode:setAnchorPoint(0.5, 1)
	roleClippingNode:setPosition(cc.p(lsize.width / 2 + 10, lsize.height))
	roleClippingNode:setInverted(false)
	eventNode:addChild(roleClippingNode, 1)
	local cutLayer = display.newLayer(
			0,
			0,
			{
				size = roleClippingNode:getContentSize(),
				ap = cc.p(0, 0),
				color = '#ffcc00'
			})


	local imgHero = AssetsUtils.GetCardDrawNode()
	imgHero:setAnchorPoint(display.LEFT_BOTTOM)

	local imgBg = AssetsUtils.GetCardTeamBgNode(0, 0, 0)
	imgBg:setAnchorPoint(display.LEFT_BOTTOM)
	roleClippingNode:setStencil(cutLayer)
	roleClippingNode:addChild(imgHero,1)
	roleClippingNode:addChild(imgBg)

	local isHasImg = display.newImageView(_res('ui/stores/cardSkin/shop_skin_bg_black.png'),size.width*0.5, size.height*0.5)
	isHasImg:setAnchorPoint(cc.p(0.5,0.5))
	eventNode:addChild(isHasImg,10)


	self.viewData =  {
		rarityGoodsLayout       = rarityGoodsLayout,
		logBtn                  = logBtn,
		goodContentBgImage      = goodContentBgImage,
		cargoImage              = cargoImage,
		oneKeyGoodNum           = oneKeyGoodNum,
		oneKeyImage             = oneKeyImage,
		buyBtn                  = buyBtn,
		fullSerLimitLabel       = fullSerLimitLabel,
		fullSerLimitNum         = fullSerLimitNum,
		openPrizeLabel          = openPrizeLabel,
		openPrizeTime           = openPrizeTime,
		goodNum                 = goodNum,
		goodIcon                = goodIcon,
		makeDrawBtn             = makeDrawBtn,
		skinTitle               = skinTitle,
		cardNameOne             = cardNameOne,
		lineImage               = lineImage,
		imgHero               = imgHero,
		imgBg               = imgBg,
	}
end
function BlackGoldPrciousSkinView:UpdateView(data)
	local viewData = self.viewData
	local goodsId = data.goodsId
	local goodOneConf = CommonUtils.GetConfig('goods','goods' , goodsId) or {}
	local cardId = goodOneConf.cardId
	local cardOneCardConf =  CommonUtils.GetConfig('goods','goods' , cardId) or {}
	local cardName = cardOneCardConf.name or ""
	local name = goodOneConf.name or ""
	local skinConf  = CardUtils.GetCardSkinConfig(goodsId) or {}
	local drawPath = CardUtils.GetCardDrawPathBySkinId(goodsId)
	local imgHero = viewData.imgHero
	local imgBg = viewData.imgBg
	imgHero:setTexture(drawPath)
	local cardDrawName = ""
	if skinConf then
		cardDrawName = skinConf.photoId
	end
	local locationInfo = CommonUtils.GetConfig('cards', 'coordinate', cardDrawName)
	if nil == locationInfo or not locationInfo[COORDINATE_TYPE_TEAM] then
		print('\n**************\n', '立绘坐标信息未找到', cardDrawName, '\n**************\n')
		locationInfo = {x = 0, y = 0, scale = 50, rotate = 0}
	else
		locationInfo = locationInfo[COORDINATE_TYPE_TEAM]
	end
	imgHero:setScale(locationInfo.scale/100)
	imgHero:setRotation((locationInfo.rotate))
	imgHero:setPosition(cc.p(locationInfo.x ,(-1)*(locationInfo.y-540) - 148))
	imgBg:setTexture(CardUtils.GetCardTeamBgPathBySkinId(goodsId))

	local price = data.price
	local lotteryPrice = data.lotteryPrice
	local lotteryLeftSeconds = checkint(data.lotteryLeftSeconds)
	cardName = string.format("<%s>" , cardName)
	display.commonLabelParams(viewData.skinTitle , {text = name })
	display.commonLabelParams(viewData.cardNameOne , {text = cardName })
	-- 已购买
	if  checkint(data.hasPurchased) == 1  then
		display.commonLabelParams(viewData.buyBtn,fontWithColor(14,{text = __('已购买'), color  ="#53341D"  , outline = false}))
		viewData.buyBtn:setNormalImage(RES_DICT.ACTIVITY_MIFAN_BY_ICO)
		viewData.buyBtn:setSelectedImage(RES_DICT.ACTIVITY_MIFAN_BY_ICO)
		viewData.fullSerLimitNum:setVisible(false)
		viewData.fullSerLimitLabel:setVisible(false)
	else
		display.commonLabelParams(viewData.buyBtn,fontWithColor(14,{text = __('购买')}))
		viewData.buyBtn:setNormalImage(RES_DICT.COMMON_BTN_BIG_ORANGE)
		viewData.buyBtn:setSelectedImage(RES_DICT.COMMON_BTN_BIG_ORANGE)
	end
	if  checkint(data.hasLottery) == 1  then
		display.commonLabelParams(viewData.makeDrawBtn,fontWithColor(14,{text = __('已预约'), color  ="#53341D"  , outline = false}))
		viewData.makeDrawBtn:setNormalImage(RES_DICT.ACTIVITY_MIFAN_BY_ICO)
		viewData.makeDrawBtn:setSelectedImage(RES_DICT.ACTIVITY_MIFAN_BY_ICO)
	else
		display.commonLabelParams(viewData.makeDrawBtn,fontWithColor(14,{text = __('预约抽奖') }))
		viewData.makeDrawBtn:setNormalImage(RES_DICT.COMMON_BTN_BIG_ORANGE)
		viewData.makeDrawBtn:setSelectedImage(RES_DICT.COMMON_BTN_BIG_ORANGE)
	end
	viewData.fullSerLimitNum:setString(data.leftPurchasedNum .. '/' .. data.stock)
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
function BlackGoldPrciousSkinView:onClean()

end
return BlackGoldPrciousSkinView

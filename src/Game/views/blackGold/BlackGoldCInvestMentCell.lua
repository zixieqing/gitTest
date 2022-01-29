--[[
活动每日签到Cell
--]]
---@class BlackGoldCInvestMentCell
local BlackGoldCInvestMentCell = class('BlackGoldCInvestMentCell', function ()
	local BlackGoldCInvestMentCell = CGridViewCell:new()
	BlackGoldCInvestMentCell.name = 'home.BlackGoldCInvestMentCell'
	BlackGoldCInvestMentCell:enableNodeEvents()
	return BlackGoldCInvestMentCell
end)
local newImageView = display.newImageView
local newLabel = display.newLabel
local newButton = display.newButton
local newLayer = display.newLayer
---@type CommerceConfigParser
local CommerceConfigParser = require("Game.Datas.Parser.CommerceConfigParser")
local InvestMentConf = CommonUtils.GetConfigAllMess(CommerceConfigParser.TYPE.INVESTMENT , 'commerce')
local RES_DICT = {
	COMMON_BTN_ORANGE            = _res('ui/common/common_btn_orange.png'),
	GOLD_BINGO_BG_TZ             = _res('ui/home/blackShop/gold_bingo_bg_tz.png'),
	GOLD_BINGO_BG_TITLE_TZ_GREY  = _res('ui/home/blackShop/gold_bingo_bg_title_tz_grey.png'),
	GOLD_BINGO_BG_TITLE_TZ       = _res('ui/home/blackShop/gold_bingo_bg_title_tz.png'),
	GOLD_BINGO_TZ_XIAN_GREY      = _res('ui/home/blackShop/gold_bingo_tz_xian_grey.png'),
	GOLD_BINGO_TZ_BG_NUMBER      = _res('ui/home/blackShop/gold_bingo_tz_bg_number.png'),
	GOLD_BINGO_TZ_ICO_HG_COPPERY = _res('ui/home/blackShop/gold_bingo_tz_ico_hg_coppery.png'),
	GOLD_BINGO_TZ_ICO_HG_GOLDEN  = _res('ui/home/blackShop/gold_bingo_tz_ico_hg_golden.png'),
	GOLD_BINGO_BG_TZ_GREY        = _res('ui/home/blackShop/gold_bingo_bg_tz_grey.png'),
	GOLD_BINGO_TZ_ICO_HG_SILVER  = _res('ui/home/blackShop/gold_bingo_tz_ico_hg_silver.png'),
	ALLROUND_ICO_COMPLETED       = _res('ui/home/allround/allround_ico_completed.png'),
	GOODS_ICON_190001            = _res('arts/goods/goods_icon_900002'),
}
function BlackGoldCInvestMentCell:ctor()
	self:setContentSize(cc.size(686, 238))
	self:setCascadeOpacityEnabled(true)
	local cGrideLayout = newLayer(686/2, 238/2,
			{ ap = display.CENTER, size = cc.size(686, 238) })
	self:addChild(cGrideLayout)

	local cgrideimage = newImageView(RES_DICT.GOLD_BINGO_BG_TZ, 342, 97,
			{ ap = display.CENTER, tag = 381})
	cGrideLayout:addChild(cgrideimage)

	local joinInvestBtn = newButton(581, 107, { enable = true , ap = display.CENTER ,  n = RES_DICT.COMMON_BTN_ORANGE, d = RES_DICT.COMMON_BTN_ORANGE, s = RES_DICT.COMMON_BTN_ORANGE })
	display.commonLabelParams(joinInvestBtn, fontWithColor(14,{text = __('参与投资'), fontSize = 24, color = '#ffffff'}))
	cGrideLayout:addChild(joinInvestBtn,10)

	local ctitleImage = newImageView(RES_DICT.GOLD_BINGO_BG_TITLE_TZ_GREY, 148, 213,
			{ ap = display.CENTER, tag = 384, enable = false })
	cGrideLayout:addChild(ctitleImage)

	local ctitleLabel = newLabel(20, 10,
			{ ap = display.LEFT_BOTTOM, color = '#805743', text = "", fontSize = 22, tag = 386 })
	ctitleImage:addChild(ctitleLabel)

	local rInvestImage = newImageView(RES_DICT.ALLROUND_ICO_COMPLETED, 581, 107,
			{ ap = display.CENTER, tag = 387, enable = false })
	cGrideLayout:addChild(rInvestImage)
	rInvestImage:setVisible(false)
	local rJoinLabel = newLabel(55, 1,
			fontWithColor(14, { outline = "854847", ap = display.CENTER, color = '#ffffff', text = __('已参与'), fontSize = 24, tag = 388 }))
	rInvestImage:addChild(rJoinLabel)

	local goodImage = newImageView(RES_DICT.GOODS_ICON_190001, 640, 51,
			{ ap = display.CENTER, tag = 390, enable = false })
	cGrideLayout:addChild(goodImage)
	goodImage:setScale(0.2)

	local goodNum = cc.Label:createWithBMFont('font/small/common_text_num.fnt', '')
	goodNum:setHorizontalAlignment(display.TAC)
	goodNum:setAnchorPoint(display.RIGHT_CENTER)
	goodNum:setPosition(622, 51)
	cGrideLayout:addChild(goodNum)
	local width = 165
	local lineImages = {}
	for i = 1 ,3 do
		local lineImage = display.newImageView(RES_DICT.GOLD_BINGO_TZ_XIAN_GREY , 150 + ( i - 1) * width , 107  )
		cGrideLayout:addChild(lineImage)
		lineImages[i] = lineImage
	end

	local goodNodes = {}
	local imagePath = {
		RES_DICT.GOLD_BINGO_TZ_ICO_HG_COPPERY,
		RES_DICT.GOLD_BINGO_TZ_ICO_HG_SILVER ,
		RES_DICT.GOLD_BINGO_TZ_ICO_HG_GOLDEN ,
	}

	for i = 1, 3 do
		local goodNode = require("common.GoodNode").new({goodsId = REPUTATION_ID })
		goodNode:setPosition(70 + (i - 1) * width ,117 )
		cGrideLayout:addChild(goodNode)
		goodNodes[#goodNodes+1] = goodNode
		local image = display.newImageView(imagePath[i] , 100, 100)
		goodNode:addChild(image,20)
	end
	local goodLabels = {}
	local goodNumImages = {}
	for i = 1, 3 do
		local goodImage = display.newImageView(RES_DICT.GOLD_BINGO_TZ_BG_NUMBER ,70 + (i - 1) * width ,90 )
		cGrideLayout:addChild(goodImage)
		goodNumImages[i] = goodImage
	end
	for i = 1, 3 do
		local pointNum = cc.Label:createWithBMFont('font/small/common_text_num.fnt', '')
		pointNum:setHorizontalAlignment(display.TAC)
		pointNum:setAnchorPoint(display.CENTER)
		pointNum:setPosition(70 + (i - 1) * 165 ,90 )
		cGrideLayout:addChild(pointNum)
		goodLabels[#goodLabels+1] = pointNum
	end
	local rateLabels = {}
	local prizeLabels = {}
	for i = 1, 3 do
		local rateLabel = display.newLabel(75 + (i - 1) * width ,25 , {fontSize = 22 , color = "#FF5A00" , text = "20%"})
		cGrideLayout:addChild(rateLabel)
		rateLabels[#rateLabels+1] = rateLabel

		local prizeLabel = display.newLabel(75 + (i - 1) * width ,50 , {text = __('回报可能'), fontSize = 22 , color = "#805743"})
		cGrideLayout:addChild(prizeLabel)
		prizeLabels[#prizeLabels+1] = prizeLabel
	end
	self.viewData = {
		cGrideLayout            = cGrideLayout,
		cgrideimage             = cgrideimage,
		joinInvestBtn           = joinInvestBtn,
		ctitleImage             = ctitleImage,
		ctitleLabel             = ctitleLabel,
		rInvestImage            = rInvestImage,
		rateLabels              = rateLabels,
		goodNodes            	= goodNodes,
		lineImages            	= lineImages,
		prizeLabels            	= prizeLabels,
		goodNumImages           = goodNumImages,
		rJoinLabel              = rJoinLabel,
		goodImage               = goodImage,
		goodLabels               = goodLabels,
		goodNum                 = goodNum,
	}
end

function BlackGoldCInvestMentCell:UpdateView(data)
	local viewData = self.viewData
	local investmentId = data.investmentId
	print("investmentId = " , investmentId)
	local investmentOneConf = InvestMentConf[tostring(investmentId)]
	local sortKeys = table.keys(investmentOneConf.reputation)
	local hasAttend = checkint(data.hasAttend)
	local name = investmentOneConf.name
	table.sort(sortKeys , function(a, b )
		 return checkint(a )< checkint(b)
	end)
	--分母
	local colors = {
		"#FFFFFF",
		"#5D5D5D",
		"#5D5D5D"
	}
	if hasAttend == 0  then
		colors = {
			"#805743",
			"#805743",
			'#FF5A00'
		}
		viewData.goodImage:setVisible(true)
		viewData.goodNum:setVisible(true)
		viewData.joinInvestBtn:setVisible(true)
		viewData.rInvestImage:setVisible(false)
		viewData.cgrideimage:setTexture(RES_DICT.GOLD_BINGO_BG_TZ)
		viewData.ctitleImage:setTexture(RES_DICT.GOLD_BINGO_BG_TITLE_TZ)
		viewData.goodNum:setString(tostring(investmentOneConf.gold))
	else
		viewData.goodImage:setVisible(false)
		viewData.goodNum:setVisible(false)
		viewData.joinInvestBtn:setVisible(false)
		viewData.rInvestImage:setVisible(true)
		viewData.cgrideimage:setTexture(RES_DICT.GOLD_BINGO_BG_TZ_GREY)
		viewData.ctitleImage:setTexture(RES_DICT.GOLD_BINGO_BG_TITLE_TZ_GREY)
	end
	local count = #sortKeys
	for i = 1, 3 do
		if count >=i  then
			viewData.rateLabels[i]:setVisible(true)
			viewData.goodNodes[i]:setVisible(true)
			viewData.goodLabels[i]:setVisible(true)
			viewData.lineImages[i]:setVisible(true)
			viewData.goodNumImages[i]:setVisible(true)
			viewData.prizeLabels[i]:setVisible(true)
			viewData.prizeLabels[i]:setColor(ccc3FromInt(colors[2]))
			viewData.rateLabels[i]:setColor(ccc3FromInt(colors[3]))
			local rateData =  investmentOneConf.reputation[tostring(sortKeys[i])] or {}
			local rete =  (rateData[2] - rateData[1] +1) /10
			viewData.rateLabels[i]:setString(rete .. "%")
			viewData.goodLabels[i]:setString(sortKeys[i])
		else
			viewData.rateLabels[i]:setVisible(false)
			viewData.goodLabels[i]:setVisible(false)
			viewData.goodNumImages[i]:setVisible(false)
			viewData.lineImages[i]:setVisible(false)
			viewData.prizeLabels[i]:setVisible(false)
			viewData.goodNodes[i]:setVisible(false)
		end

	end
	viewData.ctitleLabel:setColor(ccc3FromInt(colors[1]))
	viewData.ctitleLabel:setString(name)
end



return BlackGoldCInvestMentCell
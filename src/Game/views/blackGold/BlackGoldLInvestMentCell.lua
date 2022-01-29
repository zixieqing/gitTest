--[[
活动每日签到Cell
--]]
---@class BlackGoldLInvestMentCell
local BlackGoldLInvestMentCell = class('BlackGoldLInvestMentCell', function ()
	local BlackGoldLInvestMentCell = CGridViewCell:new()
	BlackGoldLInvestMentCell.name = 'home.BlackGoldLInvestMentCell'
	BlackGoldLInvestMentCell:enableNodeEvents()
	return BlackGoldLInvestMentCell
end)
---@type CommerceConfigParser
local CommerceConfigParser = require("Game.Datas.Parser.CommerceConfigParser")
local InvestMentConf = CommonUtils.GetConfigAllMess(CommerceConfigParser.TYPE.INVESTMENT , 'commerce')
local ScheduleConf = CommonUtils.GetConfigAllMess(CommerceConfigParser.TYPE.SCHEDULE , 'commerce')
local newImageView = display.newImageView
local newLabel = display.newLabel
local newButton = display.newButton
local newLayer = display.newLayer
local RES_DICT = {
	COMMON_BTN_ORANGE             = _res('ui/common/common_btn_orange.png'),
	ACTIVITY_MIFAN_BY_ICO             = _res('ui/common/activity_mifan_by_ico.png'),
	GOLD_BINGO_TZ_ICO_HG_SILVER   = _res('ui/home/blackShop/gold_bingo_tz_ico_hg_silver.png'),
	GOLD_BINGO_WQ_ICO_JIAOB_GREY  = _res('ui/home/blackShop/gold_bingo_wq_ico_jiaob_grey.png'),
	GOLD_BINGO_BG_WQ_GREY         = _res('ui/home/blackShop/gold_bingo_bg_wq_grey.png'),
	GOLD_BINGO_BG_WQ         = _res('ui/home/blackShop/gold_bingo_bg_wq.png'),
	GOLD_BINGO_TZ_BG_NUMBER      = _res('ui/home/blackShop/gold_bingo_tz_bg_number.png'),
}
function BlackGoldLInvestMentCell:ctor()
	self:setContentSize(cc.size(227, 282))
	local lGrideLayout = newLayer(227/2, 282/2,
			{ ap = display.CENTER,  size = cc.size(227, 282)})
	self:addChild(lGrideLayout)

	local lgrideimage = newImageView(RES_DICT.GOLD_BINGO_BG_WQ_GREY, 113, 141,
			{ ap = display.CENTER, tag = 372, enable = false })
	lGrideLayout:addChild(lgrideimage)

	local rewardBtn = newButton(111, 71, { ap = display.CENTER ,  n = RES_DICT.COMMON_BTN_ORANGE, d = RES_DICT.ACTIVITY_MIFAN_BY_ICO, s = RES_DICT.COMMON_BTN_ORANGE, scale9 = true, size = cc.size(123, 62), tag = 367 })
	display.commonLabelParams(rewardBtn, fontWithColor(14,{text = __('领取'), fontSize = 24, color = '#ffffff'}))
	lGrideLayout:addChild(rewardBtn)

	local linvestName = newLabel(111, 247,
			{ ap = display.CENTER, color = '#ffffff', text = "", fontSize = 22, tag = 373 })
	lGrideLayout:addChild(linvestName)

	local leftGrideImage = newImageView(RES_DICT.GOLD_BINGO_WQ_ICO_JIAOB_GREY, 22, 202,
			{ ap = display.CENTER, tag = 374, enable = false })
	lGrideLayout:addChild(leftGrideImage)

	local icoImage = newImageView(RES_DICT.GOLD_BINGO_TZ_ICO_HG_SILVER, 25, 187,
			{ ap = display.CENTER, tag = 377, enable = false })
	lGrideLayout:addChild(icoImage)

	local dateLabel = newLabel(114, 23,
			{ ap = display.CENTER, color = '#ffffff', text = "", fontSize = 20, tag = 378 })
	lGrideLayout:addChild(dateLabel)

	local goodNode = require("common.GoodNode").new({goodsId = REPUTATION_ID   })
	lGrideLayout:addChild(goodNode)
	goodNode:setPosition(227/2, 282/2+20)

	local goodNumImage = display.newImageView(RES_DICT.GOLD_BINGO_TZ_BG_NUMBER ,55 , 25 )
	goodNode:addChild(goodNumImage,20)

	local goodNum = cc.Label:createWithBMFont('font/small/common_text_num.fnt', '')
	goodNum:setHorizontalAlignment(display.TAC)
	goodNum:setAnchorPoint(display.CENTER)
	goodNum:setPosition(55 , 25 )
	goodNode:addChild(goodNum,20)
	goodNum:setString("999")
	self.viewData = {
		lGrideLayout   = lGrideLayout,
		lgrideimage    = lgrideimage,
		rewardBtn      = rewardBtn,
		linvestName    = linvestName,
		leftGrideImage = leftGrideImage,
		goodNum        = goodNum,
		icoImage       = icoImage,
		dateLabel      = dateLabel,
	}
end


function BlackGoldLInvestMentCell:UpdateView(data)
	local viewData = self.viewData
	local investmentId = data.investmentId
	local investmentOneConf = InvestMentConf[tostring(investmentId)]
	local hasDrawn = checkint(data.hasDrawn)
	local name = investmentOneConf.name
	local grade  = checkint(data.grade)
	local dateStr = ScheduleConf[tostring(data.scheduleId)].startDay or ""
	local iconTable = {
		_res('ui/home/blackShop/gold_bingo_tz_ico_hg_coppery.png'),
		_res('ui/home/blackShop/gold_bingo_tz_ico_hg_silver.png'),
		_res('ui/home/blackShop/gold_bingo_tz_ico_hg_golden.png')
	}
	local goodNum = 0
	for i, v in pairs(investmentOneConf.reputationGrade) do
		if checkint(v) == grade  then
			goodNum = i
			break
		end
	end

	local colors = {
		"#FFFFFF",
		"#515151",

	}
	if hasDrawn == 0  then
		colors = {
			"#805743",
			"#805743",
		}
		viewData.lgrideimage:setTexture(RES_DICT.GOLD_BINGO_BG_WQ)
		viewData.rewardBtn:setNormalImage(RES_DICT.COMMON_BTN_ORANGE)
		viewData.rewardBtn:setSelectedImage(RES_DICT.COMMON_BTN_ORANGE)
		display.commonLabelParams(viewData.rewardBtn, fontWithColor(14, {text =__('领取')}))

	else
		viewData.rewardBtn:setNormalImage(RES_DICT.ACTIVITY_MIFAN_BY_ICO)
		viewData.rewardBtn:setSelectedImage(RES_DICT.ACTIVITY_MIFAN_BY_ICO)
		viewData.lgrideimage:setTexture(RES_DICT.GOLD_BINGO_BG_WQ_GREY)
		display.commonLabelParams(viewData.rewardBtn, fontWithColor(14, {text =__('已领取') , outline = false ,color = "#7e2b1a" }))
	end
	display.commonLabelParams(viewData.linvestName , {text = name  , color = colors[1]})
	display.commonLabelParams(viewData.dateLabel, {text = dateStr  , color = colors[2]})
	viewData.goodNum:setString(goodNum)
	viewData.icoImage:setTexture(iconTable[grade])
end

return BlackGoldLInvestMentCell
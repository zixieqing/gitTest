---@class BlackGoldInvestMentView
local BlackGoldInvestMentView = class('BlackGoldInvestMentView', function()
	local layout = CLayout:create(display.size)
	return layout
end)
local newImageView = display.newImageView
local newButton = display.newButton
local newLayer = display.newLayer
local BUTTON_TAG = {
	CLOSE_BTN = 1001 ,
	CINVESTMENT_BTN = 1002,
	LINVESTMENT_BTN = 1003,
	TIP_BTN         = 1004,

}
local RES_DICT = {
	COMMON_BTN_ORANGE             = _res('ui/common/common_btn_orange.png'),
	COMMON_BTN_TAB_SELECT             = _res('ui/common/common_btn_tab_select.png'),
	COMMCON_BG_TEXT               = _res('ui/common/commcon_bg_text.png'),
	COMMON_BG_TITLE_2             = _res('ui/common/common_bg_title_2.png'),
	GOLD_BINGO_WQ_ICO_JIAOB_GREY  = _res('ui/home/blackShop/gold_bingo_wq_ico_jiaob_grey.png'),
	COMMON_BTN_TIPS               = _res('ui/common/common_btn_tips.png'),
	GOODS_ICON_880026             = _res('arts/goods/goods_icon_880026.png'),
	ALLROUND_ICO_COMPLETED        = _res('ui/home/allround/allround_ico_completed.png'),
	GOLD_BINGO_BG_TZ              = _res('ui/home/blackShop/gold_bingo_bg_tz.png'),
	GOLD_BINGO_BG_WQ_GREY         = _res('ui/home/blackShop/gold_bingo_bg_wq_grey.png'),
	GOLD_BINGO_BG_TITLE_TZ_GREY   = _res('ui/home/blackShop/gold_bingo_bg_title_tz_grey.png'),
	COMMON_BTN_TAB_DEFAULT        = _res('ui/common/common_btn_tab_default.png'),
	COMMON_BG_2                   = _res('ui/common/common_bg_2.png'),
	GOLD_BINGO_TZ_ICO_HG_SILVER   = _res('ui/home/blackShop/gold_bingo_tz_ico_hg_silver.png'),
	GOLD_BINGO_PIC_WQ_KONG   = _res('ui/home/blackShop/gold_bingo_pic_wq_kong.png'),
}
function BlackGoldInvestMentView:ctor(params )
	self:InitUI()
end

function BlackGoldInvestMentView:InitUI()
	local view = newLayer(display.cx, display.cy,{ap = display.CENTER, size = display.size})
	local closeLayer = display.newLayer(display.cx, display.cy, { ap = display.CENTER , color = cc.c4b(0,0,0,175) , enable = true})
	view:addChild(closeLayer)
	closeLayer:setTag(BUTTON_TAG.CLOSE_BTN)
	local investLayout = newLayer(1319, 359,
			{ ap = display.RIGHT_CENTER, size = cc.size(738, 639) })
	investLayout:setPosition(display.SAFE_R + -15, display.cy + -16)
	view:addChild(investLayout)
	self:addChild(view)

	local swallowLayer = newLayer(0, 0,
			{ ap = display.LEFT_BOTTOM, color = cc.r4b(0), size = cc.size(738, 639), enable = true })
	investLayout:addChild(swallowLayer)
	investLayout:setVisible(false)

	local bgImage = newImageView(RES_DICT.COMMON_BG_2, 0, 0,
			{ ap = display.LEFT_BOTTOM, tag = 348, enable = false })
	investLayout:addChild(bgImage)

	local commonTextImage = newImageView(RES_DICT.COMMCON_BG_TEXT, 372, 277,
			{ ap = display.CENTER, tag = 370, enable = false, scale9 = true, size = cc.size(689, 528) })
	investLayout:addChild(commonTextImage)

	local titleBtn = newButton(372, 618, { ap = display.CENTER ,  n = RES_DICT.COMMON_BG_TITLE_2, d = RES_DICT.COMMON_BG_TITLE_2, s = RES_DICT.COMMON_BG_TITLE_2, scale9 = true, size = cc.size(256, 36), tag = 349 })
	display.commonLabelParams(titleBtn, fontWithColor(14, {text = __('投资盈利'), fontSize = 24, color = '#ffffff'}))
	investLayout:addChild(titleBtn)

	local cuurentInvestBtn = newButton(115, 565, { ap = display.CENTER ,  n = RES_DICT.COMMON_BTN_TAB_DEFAULT, d = RES_DICT.COMMON_BTN_TAB_SELECT, s = RES_DICT.COMMON_BTN_TAB_DEFAULT, scale9 = true, size = cc.size(140, 48), tag = 375 })
	display.commonLabelParams(cuurentInvestBtn, {text = __('投资计划'), fontSize = 24, color = '#ffffff'})
	investLayout:addChild(cuurentInvestBtn)
	cuurentInvestBtn:setTag(BUTTON_TAG.CINVESTMENT_BTN)
	local lastInvestBtn = newButton(265, 565, { ap = display.CENTER ,  n = RES_DICT.COMMON_BTN_TAB_DEFAULT, d = RES_DICT.COMMON_BTN_TAB_SELECT, s = RES_DICT.COMMON_BTN_TAB_DEFAULT, scale9 = true, size = cc.size(140, 48), tag = 376 })
	display.commonLabelParams(lastInvestBtn, {text = __('往期投资'), fontSize = 24, color = '#ffffff'})
	investLayout:addChild(lastInvestBtn)
	lastInvestBtn:setTag(BUTTON_TAG.LINVESTMENT_BTN)
	local currentInvestLayout = newLayer(29, 16,
			{ ap = display.LEFT_BOTTOM, size = cc.size(689, 527)})
	investLayout:addChild(currentInvestLayout,10)
	local tipBtn = newButton(524, 614, { ap = display.CENTER ,  n = RES_DICT.COMMON_BTN_TIPS, d = RES_DICT.COMMON_BTN_TIPS, s = RES_DICT.COMMON_BTN_TIPS, scale9 = true, size = cc.size(61, 61), tag = 389 })
	display.commonLabelParams(tipBtn, {text = "", fontSize = 14, color = '#414146'})
	investLayout:addChild(tipBtn)
	tipBtn:setTag(BUTTON_TAG.TIP_BTN)
	local LastInvestLayout = newLayer(29, 16,
			{ ap = display.LEFT_BOTTOM, size = cc.size(689, 527) })
	investLayout:addChild(LastInvestLayout)
	local lgrideSize = cc.size(687, 527)
	local lgrideCellSize = cc.size(229, 285)
	local lgridView = CGridView:create(lgrideSize)
	lgridView:setSizeOfCell(lgrideCellSize)
	lgridView:setColumns(3)
	lgridView:setAutoRelocate(true)
	lgridView:setAnchorPoint(display.CENTER)
	lgridView:setPosition(689/2+2,527/2-2)
	LastInvestLayout:addChild(lgridView)
	LastInvestLayout:setVisible(false)

	local cgrideCellSize = cc.size(686, 238)
	local cgridView = CGridView:create(lgrideSize)
	cgridView:setSizeOfCell(cgrideCellSize)
	cgridView:setColumns(1)
	cgridView:setCascadeOpacityEnabled(true)
	cgridView:setAutoRelocate(true)
	cgridView:setAnchorPoint(display.CENTER)
	cgridView:setPosition(689/2,527/2-2)
	currentInvestLayout:addChild(cgridView)
	self.viewData = {
		investLayout            = investLayout,
		swallowLayer            = swallowLayer,
		closeLayer              = closeLayer,
		bgImage                 = bgImage,
		cgridView               = cgridView,
		commonTextImage         = commonTextImage,
		titleBtn                = titleBtn,
		cuurentInvestBtn        = cuurentInvestBtn,
		lgridView               = lgridView,
		lastInvestBtn           = lastInvestBtn,
		currentInvestLayout     = currentInvestLayout,
		LastInvestLayout        = LastInvestLayout,
		tipBtn                  = tipBtn,
	}
end

function BlackGoldInvestMentView:EnterAction()
	local viewData = self.viewData
	local investLayout = viewData.investLayout
	investLayout:setOpacity(0)
	local endPos = cc.p(investLayout:getPosition())
	investLayout:runAction(
		cc.Sequence:create(
			cc.MoveTo:create(0, cc.p(endPos.x + 600 ,endPos.y)) ,
			cc.Show:create(),
			cc.Spawn:create(
				cc.FadeIn:create(0.8),
				cc.EaseBackOut:create(
					cc.MoveTo:create(0.8 ,endPos )
				)
			),
			cc.CallFunc:create(
				function()
					AppFacade.GetInstance():DispatchObservers( "END_ACTION_EVENT", {})
				end
			)

		)
	)
end
function BlackGoldInvestMentView:CreateLInvestmentEmpty()
	local image = display.newImageView(RES_DICT.GOLD_BINGO_PIC_WQ_KONG ,689/2 , 527/2 -50 )
	self.viewData.LastInvestLayout:addChild(image)
	local label  = display.newLabel(689/2 , 527 - 80 , {fontSize = 22, color = "#515151" , text = __('无已完成投资信息\n')})
	self.viewData.LastInvestLayout:addChild(label)
end

function BlackGoldInvestMentView:CreateCInvestmentEmpty()
	local image = display.newImageView(RES_DICT.GOLD_BINGO_PIC_WQ_KONG ,689/2 , 527/2 -50 )
	self.viewData.currentInvestLayout:addChild(image)
	local label  = display.newLabel(689/2 , 527 - 80 , {fontSize = 22, color = "#515151" , hAlign = display.TAC ,  text = __('投资清单空空如也\n记得在商船返港后参与投资获取商会声望')})
	self.viewData.currentInvestLayout:addChild(label)
end

function BlackGoldInvestMentView:onClean()

end
return BlackGoldInvestMentView

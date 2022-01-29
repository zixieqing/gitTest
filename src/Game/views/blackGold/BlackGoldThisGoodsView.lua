---@class BlackGoldThisGoodsView
local BlackGoldThisGoodsView = class('BlackGoldThisGoodsView', function()
	local layout = CLayout:create(display.size)
	return layout
end)
local newImageView           = display.newImageView
local newButton              = display.newButton
local newLayer               = display.newLayer
local BUTTON_TAG             = {
	CLOSE_BTN          = 1001,
	COMMMON_GOODS_BTN  = 1002,
	PRECIOUS_GOODS_BTN = 1003,
	TIP_BTN            = 1010,

}

local RES_DICT               = {
	COMMON_BTN_ORANGE            = _res('ui/common/common_btn_orange.png'),
	COMMON_BTN_TAB_SELECT        = _res('ui/common/common_btn_tab_select.png'),
	COMMCON_BG_TEXT              = _res('ui/common/commcon_bg_text.png'),
	COMMON_BG_TITLE_2            = _res('ui/common/common_bg_title_2.png'),
	GOLD_BINGO_WQ_ICO_JIAOB_GREY = _res('ui/home/blackShop/gold_bingo_wq_ico_jiaob_grey.png'),
	COMMON_BTN_TIPS              = _res('ui/common/common_btn_tips.png'),
	GOODS_ICON_880026            = _res('arts/goods/goods_icon_880026.png'),
	ALLROUND_ICO_COMPLETED       = _res('ui/home/allround/allround_ico_completed.png'),
	GOLD_BINGO_BG_TZ             = _res('ui/home/blackShop/gold_bingo_bg_tz.png'),
	GOLD_BINGO_BG_WQ_GREY        = _res('ui/home/blackShop/gold_bingo_bg_wq_grey.png'),
	GOLD_BINGO_BG_TITLE_TZ_GREY  = _res('ui/home/blackShop/gold_bingo_bg_title_tz_grey.png'),
	COMMON_BTN_TAB_DEFAULT       = _res('ui/common/common_btn_tab_default.png'),
	COMMON_BG_2                  = _res('ui/common/common_bg_2.png'),
	GOLD_BINGO_TZ_ICO_HG_SILVER  = _res('ui/home/blackShop/gold_bingo_tz_ico_hg_silver.png'),
}
function BlackGoldThisGoodsView:ctor(params)
	self:InitUI()
end

function BlackGoldThisGoodsView:InitUI()
	local view       = newLayer(display.cx, display.cy, { ap = display.CENTER, size = display.size })
	local closeLayer = display.newLayer(display.cx, display.cy, { ap = display.CENTER, color = cc.c4b(0, 0, 0, 175), enable = true })
	view:addChild(closeLayer)
	closeLayer:setTag(BUTTON_TAG.CLOSE_BTN)
	local goodsLayout = newLayer(1319, 359,
			{ ap = display.RIGHT_CENTER, size = cc.size(738, 639) })
	goodsLayout:setPosition(display.SAFE_R + -15, display.cy + -16)
	view:addChild(goodsLayout)
	self:addChild(view)
	goodsLayout:setVisible(false)

	local swallowLayer = newLayer(0, 0,
			{ ap = display.LEFT_BOTTOM, color = cc.r4b(0), size = cc.size(738, 639), enable = true })
	goodsLayout:addChild(swallowLayer)

	local bgImage = newImageView(RES_DICT.COMMON_BG_2, 0, 0,
			{ ap = display.LEFT_BOTTOM, tag = 348, enable = false })
	goodsLayout:addChild(bgImage)

	local commonTextImage = newImageView(RES_DICT.COMMCON_BG_TEXT, 372, 277,
			{ ap = display.CENTER, tag = 370, enable = false, scale9 = true, size = cc.size(692, 528) })
	goodsLayout:addChild(commonTextImage)

	local titleBtn = newButton(372, 618, { ap = display.CENTER, n = RES_DICT.COMMON_BG_TITLE_2, d = RES_DICT.COMMON_BG_TITLE_2, s = RES_DICT.COMMON_BG_TITLE_2, scale9 = true, size = cc.size(256, 36), tag = 349 })
	display.commonLabelParams(titleBtn, fontWithColor(14, { text = __('本期货物'), fontSize = 24, color = '#ffffff' }))
	goodsLayout:addChild(titleBtn)

	local commonGoodsBtn = newButton(115, 565, { ap = display.CENTER, n = RES_DICT.COMMON_BTN_TAB_DEFAULT, d = RES_DICT.COMMON_BTN_TAB_SELECT, s = RES_DICT.COMMON_BTN_TAB_DEFAULT, scale9 = true, size = cc.size(140, 48), tag = 375 })
	display.commonLabelParams(commonGoodsBtn, { text = __('普通货物'), fontSize = 24, color = '#ffffff' })
	goodsLayout:addChild(commonGoodsBtn)
	commonGoodsBtn:setTag(BUTTON_TAG.COMMMON_GOODS_BTN)
	local preicousGoodstBtn = newButton(265, 565, { ap = display.CENTER, n = RES_DICT.COMMON_BTN_TAB_DEFAULT, d = RES_DICT.COMMON_BTN_TAB_SELECT, s = RES_DICT.COMMON_BTN_TAB_DEFAULT, scale9 = true, size = cc.size(140, 48), tag = 376 })
	display.commonLabelParams(preicousGoodstBtn, { text = __('珍贵货物'), fontSize = 24, color = '#ffffff' })
	goodsLayout:addChild(preicousGoodstBtn)
	preicousGoodstBtn:setTag(BUTTON_TAG.PRECIOUS_GOODS_BTN)
	local commonGoodsLayout = newLayer(28, 16,
			{ ap = display.LEFT_BOTTOM, size = cc.size(689, 527) })
	goodsLayout:addChild(commonGoodsLayout, 10)
	local tipBtn = newButton(524, 614, { ap = display.CENTER, n = RES_DICT.COMMON_BTN_TIPS, d = RES_DICT.COMMON_BTN_TIPS, s = RES_DICT.COMMON_BTN_TIPS, scale9 = true, size = cc.size(61, 61), tag = 389 })
	display.commonLabelParams(tipBtn, { text = "", fontSize = 14, color = '#414146' })
	goodsLayout:addChild(tipBtn)
	tipBtn:setTag(BUTTON_TAG.TIP_BTN)
	local preicousGoodsLayout = newLayer(29, 16,
			{ ap = display.LEFT_BOTTOM, size = cc.size(689, 527) })
	goodsLayout:addChild(preicousGoodsLayout)
	preicousGoodsLayout:setVisible(false)

	local cgrideCellSize = cc.size(172, 235)
	local cgridView      = CGridView:create(cc.size(687, 525))
	cgridView:setSizeOfCell(cgrideCellSize)
	cgridView:setColumns(4)
	cgridView:setAutoRelocate(true)
	cgridView:setAnchorPoint(display.CENTER)
	cgridView:setCascadeOpacityEnabled(true)
	cgridView:setPosition(689 / 2, 525 / 2 - 2)
	commonGoodsLayout:addChild(cgridView)
	self.viewData = {
		goodsLayout         = goodsLayout,
		swallowLayer        = swallowLayer,
		closeLayer          = closeLayer,
		bgImage             = bgImage,
		cgridView           = cgridView,
		commonTextImage     = commonTextImage,
		titleBtn            = titleBtn,
		commonGoodsBtn      = commonGoodsBtn,
		preicousGoodstBtn   = preicousGoodstBtn,
		commonGoodsLayout   = commonGoodsLayout,
		preicousGoodsLayout = preicousGoodsLayout,
		tipBtn              = tipBtn,
	}

end


function BlackGoldThisGoodsView:EnterAction()
	local viewData = self.viewData
	local goodsLayout = viewData.goodsLayout
	goodsLayout:setOpacity(0)
	local endPos = cc.p(goodsLayout:getPosition())
	goodsLayout:runAction(
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
function BlackGoldThisGoodsView:onClean()


end
return BlackGoldThisGoodsView

---@class BlackGoldPreciousLotteryLogView
local BlackGoldPreciousLotteryLogView = class('BlackGoldPreciousLotteryLogView', function()
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
	COMMON_BG_2                  = _res('ui/common/common_bg_3.png'),
	GOLD_BINGO_TZ_ICO_HG_SILVER  = _res('ui/home/blackShop/gold_bingo_tz_ico_hg_silver.png'),
	GOLD_NOW_FEW_WIN_XIAN  = _res('ui/home/blackShop/gold_now_few_win_xian.png'),
}
function BlackGoldPreciousLotteryLogView:ctor(params)
	self.data = params.data  or {}
	self.selectData = {}
	self:InitUI()
	self:BindClick()
end

function BlackGoldPreciousLotteryLogView:InitUI()
	local view       = newLayer(display.cx, display.cy, { ap = display.CENTER, size = display.size })
	local closeLayer = display.newLayer(display.cx, display.cy, { ap = display.CENTER, color = cc.c4b(0, 0, 0, 175), enable = true , cb = function()
		self:removeFromParent()
	end })
	view:addChild(closeLayer)
	closeLayer:setTag(BUTTON_TAG.CLOSE_BTN)
	local goodsSize =  cc.size(558, 639)
	local goodsLayout = newLayer(display.cx , display.cy ,
			{ ap = display.CENTER, size = goodsSize })
	view:addChild(goodsLayout)
	self:addChild(view)

	local swallowLayer = newLayer(0, 0,
			{ ap = display.LEFT_BOTTOM, color = cc.r4b(0), size = goodsSize, enable = true })
	goodsLayout:addChild(swallowLayer)

	local bgImage = newImageView(RES_DICT.COMMON_BG_2, 0, 0,
			{ ap = display.LEFT_BOTTOM, tag = 348, enable = false })
	goodsLayout:addChild(bgImage)

	local commonTextImage = newImageView(RES_DICT.COMMCON_BG_TEXT, goodsSize.width/2, 277,
			{ ap = display.CENTER, tag = 370, enable = false, scale9 = true, size = cc.size(505, 528) })
	goodsLayout:addChild(commonTextImage)

	local titleBtn = newButton(goodsSize.width/2 , 618, { ap = display.CENTER, n = RES_DICT.COMMON_BG_TITLE_2, d = RES_DICT.COMMON_BG_TITLE_2, s = RES_DICT.COMMON_BG_TITLE_2, scale9 = true, size = cc.size(256, 36), tag = 349 })
	display.commonLabelParams(titleBtn, fontWithColor(14, { text = __('中奖名单'), fontSize = 24, color = '#ffffff' }))
	goodsLayout:addChild(titleBtn)

	local commonGoodsBtn = newButton(115, 565, { ap = display.CENTER, n = RES_DICT.COMMON_BTN_TAB_DEFAULT, d = RES_DICT.COMMON_BTN_TAB_SELECT, s = RES_DICT.COMMON_BTN_TAB_DEFAULT, scale9 = true, size = cc.size(140, 48), tag = 375 })
	display.commonLabelParams(commonGoodsBtn, { text = __('本期'), fontSize = 24, color = '#ffffff' })
	goodsLayout:addChild(commonGoodsBtn)
	commonGoodsBtn:setTag(BUTTON_TAG.COMMMON_GOODS_BTN)
	local preicousGoodstBtn = newButton(265, 565, { ap = display.CENTER, n = RES_DICT.COMMON_BTN_TAB_DEFAULT, d = RES_DICT.COMMON_BTN_TAB_SELECT, s = RES_DICT.COMMON_BTN_TAB_DEFAULT, scale9 = true, size = cc.size(140, 48), tag = 376 })
	display.commonLabelParams(preicousGoodstBtn, { text = __('上期'), fontSize = 24, color = '#ffffff' })
	goodsLayout:addChild(preicousGoodstBtn)
	preicousGoodstBtn:setTag(BUTTON_TAG.PRECIOUS_GOODS_BTN)

	local cgrideCellSize = cc.size(500, 78)
	local cgridView      = CGridView:create(cc.size(500, 520))
	cgridView:setSizeOfCell(cgrideCellSize)
	cgridView:setColumns(1)
	cgridView:setAutoRelocate(true)
	cgridView:setAnchorPoint(display.CENTER)
	cgridView:setCascadeOpacityEnabled(true)
	cgridView:setAnchorPoint(display.LEFT_BOTTOM )
	cgridView:setPosition(20,15 )

	goodsLayout:addChild(cgridView)
	self.viewData = {
		goodsLayout         = goodsLayout,
		swallowLayer        = swallowLayer,
		closeLayer          = closeLayer,
		bgImage             = bgImage,
		cgridView           = cgridView,
		commonTextImage     = commonTextImage,
		titleBtn            = titleBtn,
		commonGoodsBtn      = commonGoodsBtn,
		preicousGoodstBtn   = preicousGoodstBtn
	}

end

function BlackGoldPreciousLotteryLogView:CDataSource( p_convertview,idx )
	local pCell = p_convertview
	local index = idx + 1
	xTry(function ( )
		if not pCell then
			pCell = CGridViewCell:new()
			pCell:setContentSize(cc.size(500, 78))
			local label = display.newLabel(250 , 39 , fontWithColor(8, {text = "" }))
			pCell:addChild(label)
			pCell.label = label
			local image = display.newImageView(RES_DICT.GOLD_NOW_FEW_WIN_XIAN ,  250 , 0 )
			pCell:addChild(image)
		end
		display.commonLabelParams(pCell.label , {text = self.selectData[index] or "" })
	end, __G__TRACKBACK__)
	return pCell
end
function BlackGoldPreciousLotteryLogView:BindClick()
	local viewData = self.viewData
	viewData.preicousGoodstBtn:setOnClickScriptHandler(handler(self, self.ButtonAction))
	viewData.commonGoodsBtn:setOnClickScriptHandler(handler(self, self.ButtonAction))
	viewData.cgridView:setDataSourceAdapterScriptHandler(handler(self, self.CDataSource))
	self:DealWithBtnClick(BUTTON_TAG.COMMMON_GOODS_BTN)
end

function BlackGoldPreciousLotteryLogView:ButtonAction(sender)
	PlayAudioByClickNormal()
	local tag = sender:getTag()
	if tag == BUTTON_TAG.CLOSE_BTN then
		--AppFacade.GetInstance():UnRegsitMediator(NAME)
	elseif tag == BUTTON_TAG.LOG_BTN then -- 珍贵货物
		self:SendSignal(POST.COMMERCE_PRECIOUS_LOTTERY_LIST.cmdName,{})
	elseif tag == BUTTON_TAG.PRECIOUS_GOODS_BTN then -- 珍贵货物
		self:DealWithBtnClick(BUTTON_TAG.PRECIOUS_GOODS_BTN)
	elseif tag == BUTTON_TAG.COMMMON_GOODS_BTN then -- 普通货物
		self:DealWithBtnClick(BUTTON_TAG.COMMMON_GOODS_BTN)
	end
end

function BlackGoldPreciousLotteryLogView:DealWithBtnClick(tag)

	local viewData = self.viewData
	local curbtn = nil
	local prebtn = nil
	if tag == BUTTON_TAG.PRECIOUS_GOODS_BTN then
		curbtn = viewData.preicousGoodstBtn
		prebtn = viewData.commonGoodsBtn
		self.selectData =  self.data.previous or {}
	elseif  tag == BUTTON_TAG.COMMMON_GOODS_BTN then
		curbtn = viewData.commonGoodsBtn
		prebtn = viewData.preicousGoodstBtn
		self.selectData =  self.data.current or {}
	end
	prebtn:setEnabled(true)
	curbtn:setEnabled(false)
	curbtn:getLabel():setColor(ccc3FromInt("#d23d3d"))
	prebtn:getLabel():setColor(ccc3FromInt("#ffffff"))
	viewData.cgridView:setCountOfCell(#self.selectData)
	viewData.cgridView:reloadData()
end


function BlackGoldPreciousLotteryLogView:onClean()


end
return BlackGoldPreciousLotteryLogView

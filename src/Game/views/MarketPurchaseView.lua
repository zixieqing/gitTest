--[[
市场购买模块view
--]]
local MarketPurchaseView = class('MarketPurchaseView', function ()
	local node = CLayout:create(cc.size(1082, 641))
	node:setAnchorPoint(cc.p(0, 0))
	node.name = 'home.MarketPurchaseView'
	node:enableNodeEvents()
	return node
end)

local function CreateView( )
	local size = cc.size(1082, 641)
	local view = CLayout:create(size)
	view:setAnchorPoint(0, 0)
	-- view:addChild(display.newLayer(0,0, {ap = cc.p(0,0), size = size, color = cc.c4b(0,0,0,130)}))
	-- 筛选按钮
	local selectBtn = display.newButton(79, 533, {ap = cc.p(0, 0), n = _res('ui/home/teamformation/choosehero/team_btn_selection_unused.png')})
	view:addChild(selectBtn)
	display.commonLabelParams(selectBtn, {text = __('全部'), fontSize = 22, color = '#ffffff'})
	-- local directIcon = display.newImageView(_res('ui/common/common_bg_direct_s'), 97, selectBtn:getContentSize().height/2)
	-- selectBtn:addChild(directIcon)
	-- directIcon:setRotation(90)
	-- directIcon:setScale(0.2)
	-- 输入框
	local editBoxBg = display.newImageView(_res('ui/home/market/market_main_bg_research.png'), 220, 533, {ap = cc.p(0, 0)})
	view:addChild(editBoxBg)
	local editBox = ccui.EditBox:create(cc.size(194, 40), 'empty')
	display.commonUIParams(editBox, {po = cc.p(280, 533),ap = cc.p(0,0)})
	view:addChild(editBox)
	editBox:setFontSize(22)
	editBox:setFontColor(ccc3FromInt('#4c4c4c'))
	editBox:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
	editBox:setPlaceHolder(__('输入关键字'))
	editBox:setPlaceholderFontSize(20)
	editBox:setPlaceholderFontColor(ccc3FromInt('#4c4c4c'))
	editBox:setReturnType(cc.KEYBOARD_RETURNTYPE_DONE)
	editBox:setMaxLength(10)

	local researchIcon = display.newImageView(_res('ui/home/market/market_main_ico_research.png'), 30, editBoxBg:getContentSize().height/2)
	editBoxBg:addChild(researchIcon)
	local deleteBtn = display.newButton(500, 555, {n = _res('ui/home/market/market_main_btn_research_delete.png')})
	deleteBtn:setVisible(false)
	view:addChild(deleteBtn, 100)
	-- 刷新时间
	local refreshLabel = display.newLabel(810, 570, {text = __('系统刷新'), fontSize = 22, color = '#5b3c25',reqW =230 , ap = display.RIGHT_CENTER})
	view:addChild(refreshLabel)
	local refreshTimeLabel = display.newLabel(810, 540, {text = '', fontSize = 22, color = '#5b3c25', ap = display.RIGHT_CENTER})
	view:addChild(refreshTimeLabel)
	-- 刷新按钮
	local refreshBtn = display.newButton(1020, 553,  {ap = display.RIGHT_CENTER ,  n = _res('ui/common/common_btn_orange.png'),  scale9 = true, size = cc.size(120, 56)})
	view:addChild(refreshBtn)
	local refreshBtnSize = refreshBtn:getContentSize()
	local refreshBtnLabel = display.newLabel(0, 0, {text = __("立即刷新"), fontSize = fontWithColor('14').fontSize,reqW = 180, color = fontWithColor('14').color})
	refreshBtn:addChild(refreshBtnLabel)
	local refreshBtnLabelSize = display.getLabelContentSize(refreshBtnLabel)
	local refW = refreshBtnLabelSize.width +20
	if refreshBtnLabelSize.width > 180 then
		refW = 180 + 20
	end
	if not isJapanSdk() then 
		refreshBtn:setContentSize(cc.size(refW , refreshBtnSize.height)) 
		refreshBtnLabel:setPosition(refW /2 , refreshBtn:getContentSize().height*0.7)
	else
		refreshBtnLabel:setPosition(refreshBtn:getContentSize().width / 2 , refreshBtn:getContentSize().height*0.7)
	end
	local diamondCostLabel = display.newRichLabel(refreshBtn:getContentSize().width/2, refreshBtn:getContentSize().height*0.35, {r = true, c =
		{
			{text = '10', fontSize = 20, color = '#ffffff'},
			{img = _res('arts/goods/goods_icon_' .. DIAMOND_ID .. '.png'), scale = 0.15}
		}
	})
	refreshBtn:addChild(diamondCostLabel)
	-- 商品列表
	local pageSize = cc.size(954, 463)
	local goodsListBg = display.newImageView(_res('ui/common/common_bg_goods.png'), 64, 58, {ap = cc.p(0, 0), scale9 = true, size = pageSize})
	view:addChild(goodsListBg)

	local pageView = CPageView:create(pageSize)
	pageView:setAnchorPoint(cc.p(0, 0))
	pageView:setPosition(cc.p(64, 58))
	pageView:setDirection(eScrollViewDirectionHorizontal)
	pageView:setSizeOfCell(pageSize)
	view:addChild(pageView)
	pageView:setDragable(false)
	-- 页码
	local pageIamge = display.newImageView(_res('ui/home/market/market_main_bg_page.png'), 541, 39)
	view:addChild(pageIamge)
	local pageLabel = display.newLabel(pageIamge:getContentSize().width/2, pageIamge:getContentSize().height/2, {text = '', fontSize = fontWithColor('9').fontSize, color = fontWithColor('9').color})
	pageIamge:addChild(pageLabel)
	-- 切换按钮
	local pageUpBtn_Bg = display.newImageView(_res('ui/common/common_bg_direct_s.png'), 31.5, 170.5)
	view:addChild(pageUpBtn_Bg)
	pageUpBtn_Bg:setScaleX(-1)
	local pageUpBtn = display.newButton(31.5, 170.5, {n = 'ui/common/common_btn_direct_s.png', tag = 1101})
	view:addChild(pageUpBtn)
	pageUpBtn:setScaleX(-1)
	local pageDownBtn_Bg = display.newImageView(_res('ui/common/common_bg_direct_s.png'), 1050.5, 170.5)
	view:addChild(pageDownBtn_Bg)
	local pageDownBtn = display.newButton(1050.5, 170.5, {n = 'ui/common/common_btn_direct_s.png', tag = 1102})
	view:addChild(pageDownBtn)

	local oneKeyPurchaseBg = display.newNSprite(_res('ui/home/market/market_bg_button_quick.png'), 950, 10, {ap = display.CENTER_TOP})
	view:addChild(oneKeyPurchaseBg)
	-- 一键购买按钮
	local oneKeyPurchaseBtn = display.newButton(890, 16, {n = _res('ui/common/common_btn_orange.png'), ap = cc.p(0, 0.5), scale9 = true, size = cc.size(120, 56)})
	display.commonLabelParams(oneKeyPurchaseBtn, fontWithColor(14, {text = __("一键购买")}))
	view:addChild(oneKeyPurchaseBtn)

	return {
		view 			 	= view,
		pageView 		 	= pageView,
		pageSize 		 	= pageSize,
		pageUpBtn 		 	= pageUpBtn,
		pageDownBtn 	 	= pageDownBtn,
		pageLabel 		 	= pageLabel,
		refreshBtn  	 	= refreshBtn,
		refreshTimeLabel 	= refreshTimeLabel,
		selectBtn        	= selectBtn,
		editBox          	= editBox,
		deleteBtn        	= deleteBtn,
		oneKeyPurchaseBtn   = oneKeyPurchaseBtn,
	}
end

function MarketPurchaseView:ctor( ... )
	self.viewData_ = CreateView()
	self:addChild(self.viewData_.view, 1)
	self.viewData_.view:setPosition(cc.p(0, 0))
end

return MarketPurchaseView

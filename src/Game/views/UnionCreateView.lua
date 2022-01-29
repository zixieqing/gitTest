--[[
 * descpt : 创建工会 界面
 ]]

local size = cc.size(1089, 588)
local UnionCreateView = class('UnionCreateView', function ()
	local node = CLayout:create(size)
	node.name = 'Game.views.UnionCreateView'
	node:enableNodeEvents()
	return node
end)

local CreateView      = nil

local RES_DIR = {
	BG                = _res('ui/union/create/guild_found_bg1.png'),
	NPC               = _res('ui/union/create/guild_found_npc.png'),
	FOUND_BG          = _res('ui/union/guild_found_bg.png'),
	HEAD_FRAME_BG     = _res('ui/union/guild_head_frame_default.png'),
	UNION_NAME_BG     = _res('ui/union/guild_establish_information_search_bg.png'), 
	DESC_BG           = _res('ui/union/guild_declaration_bg.png'),
	BTN_ORANGE        = _res('ui/common/common_btn_orange'),
}

local BTN_TAG = {
	TAG_HEAD       = 100,
	TAG_CREATE     = 101,
}

function UnionCreateView:ctor(...)
    self.args = unpack({...})
    self:initialUI()
end

function UnionCreateView:initialUI()
	xTry(function ( )
		self.viewData_ = CreateView()
		self:addChild(self:getViewData().view)
	end, __G__TRACKBACK__)
end

CreateView = function ()
	local actionButtons = {}
    local view = display.newLayer(size.width / 2, size.height / 2, {ap = display.CENTER, size = size})
	
	local bg = display.newImageView(RES_DIR.BG, 0, 0, {ap = display.LEFT_BOTTOM})
	view:addChild(bg)
	
	local npc = display.newImageView(RES_DIR.NPC, 100, 0, {ap = display.LEFT_BOTTOM})
	view:addChild(npc)
	
	local foundBg = display.newImageView(RES_DIR.FOUND_BG, 0, 0, {ap = display.LEFT_BOTTOM})
	local foundBgSize = foundBg:getContentSize()
	local foundLayer = display.newLayer(size.width / 2 - 15, size.height / 2, {ap = display.LEFT_CENTER, size = foundBgSize})
	foundLayer:addChild(foundBg)
	view:addChild(foundLayer)
	
	local headBg = display.newButton(foundBgSize.width / 2, foundBgSize.height - 100, {ap = display.CENTER, n = RES_DIR.HEAD_FRAME_BG})
	local headBgSize = headBg:getContentSize()
	display.commonLabelParams(headBg, {fontSize = 24, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#5b3c25', outlineSize = 1, text = __('更换'), offset = cc.p(0, -headBgSize.height / 2)})
	headBg:setTag(BTN_TAG.TAG_HEAD)
	headBg:setScale(0.85)
	foundLayer:addChild(headBg, 1)
	local head = display.newImageView(_res(), foundBgSize.width / 2, foundBgSize.height - 100, {ap = display.CENTER})
	head:setScale(0.85)
	foundLayer:addChild(head)

	actionButtons[tostring(BTN_TAG.TAG_HEAD)] = headBg

	local unionNameLabel = display.newLabel(140, foundBgSize.height - 215, {ap = display.RIGHT_CENTER, fontSize = 24,reqW = 130 , color = '#5b3c25', font = TTF_GAME_FONT, ttf = true, text = __('工会名字')})
	foundLayer:addChild(unionNameLabel)


	local unionNameBoxSize = cc.size(300, 46)
	local unionNameBox = ccui.EditBox:create(unionNameBoxSize, RES_DIR.UNION_NAME_BG)
	unionNameBox:setFontSize(fontWithColor('M2PX').fontSize)
	unionNameBox:setFontColor(ccc3FromInt('#5b3c25'))
	unionNameBox:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
	unionNameBox:setPlaceHolder(__('请输入工会名字'))
	unionNameBox:setPlaceholderFontSize(20)
	unionNameBox:setAnchorPoint(display.LEFT_CENTER)
	unionNameBox:setPlaceholderFontColor(ccc3FromInt('#9c9c9c'))
	unionNameBox:setReturnType(cc.KEYBOARD_RETURNTYPE_DONE)
	-- unionNameBox:setMaxLength(6)
	display.commonUIParams(unionNameBox, {po = cc.p(450, unionNameLabel:getPositionY()), ap = display.RIGHT_CENTER})
	foundLayer:addChild(unionNameBox)

	-- local unionNameErrorTip = display.newLabel(unionNameBox:getPositionX() + 10, unionNameBox:getPositionY() - unionNameBoxSize.height / 2 - 5, fontWithColor(10, {ap = display.LEFT_TOP, text = '工会名被占用！'}))
	-- local unionNameErrorTipSize = display.getLabelContentSize(unionNameErrorTip)
	-- foundLayer:addChild(unionNameErrorTip)
	-- unionNameErrorTip:setVisible(false)

	local unionIntroduceLabel = display.newLabel(headBg:getPositionX(), unionNameBox:getPositionY() - unionNameBoxSize.height / 2 - 25, {ap = display.CENTER_TOP, fontSize = 20, color = '#5b3c25', text = __('工会宣言')})
	local unionIntroduceLabelSize = display.getLabelContentSize(unionIntroduceLabel)
	foundLayer:addChild(unionIntroduceLabel)

	local commonEditView = require('common.CommonEditView').new({placeHolder = __('请输入工会描述'), maxLength = 70})
	display.commonUIParams(commonEditView, {po = cc.p(headBg:getPositionX(), unionIntroduceLabel:getPositionY() - unionIntroduceLabelSize.height - 3), ap = display.CENTER_TOP})
	foundLayer:addChild(commonEditView)

	local createUnionBtn = display.newButton(headBg:getPositionX(), 125, {ap = display.CENTER_TOP, n = RES_DIR.BTN_ORANGE , scale9 = true })
	if isJapanSdk() then
		display.commonLabelParams(createUnionBtn, fontWithColor(14, {text = __('创建工会')}))
	else
		display.commonLabelParams(createUnionBtn, fontWithColor(14, {text = __('创建工会') , paddingW = 20 }))
	end
	createUnionBtn:setTag(BTN_TAG.TAG_CREATE)
	foundLayer:addChild(createUnionBtn)
	actionButtons[tostring(BTN_TAG.TAG_CREATE)] = createUnionBtn

	local priceLabel = display.newLabel(0, 42, fontWithColor(16, {text = __('消耗200'), {ap = display.CENTER}}))
	foundLayer:addChild(priceLabel)

	local diamondImg = display.newImageView(CommonUtils.GetGoodsIconPathById(DIAMOND_ID), 0, 42, {ap = display.CENTER})
	diamondImg:setScale(0.2)
	foundLayer:addChild(diamondImg)

	local priceLabelSize = display.getLabelContentSize(priceLabel)
	local diamondImgSize = diamondImg:getContentSize()

	priceLabel:setPositionX(foundBgSize.width / 2 - diamondImgSize.width / 2 * 0.2)
	diamondImg:setPositionX(foundBgSize.width / 2 + priceLabelSize.width / 2)

    return {
		view              = view,
		head              = head,
		unionNameBox      = unionNameBox,
		-- unionNameErrorTip = unionNameErrorTip,
		commonEditView    = commonEditView,
		actionButtons     = actionButtons,
    }
end

function UnionCreateView:getViewData()
	return self.viewData_
end

return UnionCreateView
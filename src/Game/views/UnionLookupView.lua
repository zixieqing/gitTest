--[[
 * descpt : 查找工会 界面
 ]]
local size = cc.size(1089, 588)
-- local size = cc.size(1095, 597)
local UnionLookupView = class('UnionLookupView', function ()
	local node = CLayout:create(size)
	node.name = 'Game.views.UnionLookupView'
	node:enableNodeEvents()
	return node
end)

local CreateView      = nil
local CreateUnionList = nil
local CreateUnionInfo = nil

local CreateCell_      = nil

local RES_DIR = {
	TITLE_BG      		= _res('ui/union/lookup/guild_establish_information_title2.png'),
	LIST_BG       		= _res('ui/union/guild_establish_information_search_list_bg.png'),
	INFO_BG       		= _res('ui/union/guild_establish_information_bg.png'),
	HEAD_FRAME_BG       = _res('ui/union/guild_head_frame_default.png'),
	DESC_BG       		= _res('ui/union/guild_declaration_bg.png'),
	SEARCH_BG     		= _res('ui/union/guild_establish_information_search_bg.png'), 
	BTN_WHITE     		= _res('ui/common/common_btn_white_default.png'),
	BTN_ORANGE    		= _res('ui/common/common_btn_orange'),
	BTN_DISABLE   		= _res('ui/common/common_btn_orange_disable'),
	BTN_SEARCH_BG 		= _res('ui/home/kitchen/cooking_btn_pokedex_2.png'),

	CELL_SELECT_FRAME   = _res('ui/union/guild_establish_bg_list.png'),
	CELL_BG_DEFAULT     = _res('ui/union/guild_establish_list_frame_default.png'),
	CELL_BG_SELECT      = _res('ui/union/guild_establish_list_frame_select.png'),

	ROLE_IMG            = _res('ui/home/infor/personal_information_ico_reply.png'),
}

local BTN_TAG = {
	BTN_SHAKE     = 100,
	BTN_SEARCH    = 101,
	BTN_APPLY     = 102,
}

function UnionLookupView:ctor(...)
    self.args = unpack({...})
    self:initialUI()
end

function UnionLookupView:initialUI()
	xTry(function ( )
		self.viewData_ = CreateView()
		self:addChild(self:getViewData().view)
	end, __G__TRACKBACK__)
end

CreateView = function ()
	local view = display.newLayer(size.width / 2, size.height / 2, {ap = display.CENTER, size = size})
	
	local listViewData = CreateUnionList(view, size)

	local infoViewData = CreateUnionInfo(view, size)
	
	return {
		view         = view,
		listViewData = listViewData,
		infoViewData = infoViewData,
	}
end

CreateUnionList = function (parent, size)
	local titleBg = display.newImageView(RES_DIR.TITLE_BG, 10, size.height - 6, {ap = display.LEFT_TOP})
	local titleBgSize = titleBg:getContentSize()
	parent:addChild(titleBg, 1)
	
	local titleConf = {
		{__('工会ID'), cc.p(70, titleBgSize.height * 0.5)},
		{__('工会名字'), cc.p(220, titleBgSize.height * 0.5)},
		{__('工会等级'), cc.p(420, titleBgSize.height * 0.5)},
		{__('工会人数'), cc.p(590, titleBgSize.height * 0.5)},
	}

	for i,v in ipairs(titleConf) do
		local name, pos = unpack(v)
		local reqW = 160
		if i == 1 then
			reqW = 120
		end
		local label =  display.newLabel(pos.x, pos.y, {fontSize = 24, color = '#ffffff',text = name ,w = 130 , hAlign= display.TAC  })
		titleBg:addChild(label)
		if display.getLabelContentSize(label).width > 70  then
			display.commonLabelParams(label ,{fontSize = 20, color = '#ffffff',text = name ,w = 130 , hAlign= display.TAC  })
		end
	end

	local listBgSize = cc.size(677, 439)
	local listBg = display.newImageView(RES_DIR.LIST_BG, titleBg:getPositionX(), titleBg:getPositionY() - titleBgSize.height, {ap = display.LEFT_TOP, scale9 = true, size = listBgSize})
	parent:addChild(listBg)

	local gridViewSize = cc.size(listBgSize.width, listBgSize.height - 2)
    local gridViewCellSize = cc.size(gridViewSize.width, 86)
    local gridView = CGridView:create(gridViewSize)
    gridView:setSizeOfCell(gridViewCellSize)
    gridView:setColumns(1)
    -- gridView:setAutoRelocate(true)
    -- gridView:setBackgroundColor(cc.c3b(100,100,200))
    gridView:setAnchorPoint(display.LEFT_TOP)
    gridView:setPosition(cc.p(listBg:getPositionX(), listBg:getPositionY() - 1))
    parent:addChild(gridView)

	local shakeBtn = display.newButton(titleBg:getPositionX(), 33, {ap = display.LEFT_CENTER, n = RES_DIR.BTN_WHITE})
	local shakeBtnSize = shakeBtn:getContentSize()
	display.commonLabelParams(shakeBtn, fontWithColor(14, {text = __('换一批') , reqW = 105}))
	shakeBtn:setTag(BTN_TAG.BTN_SHAKE)
	parent:addChild(shakeBtn)

	local searchBoxSize = cc.size(480, shakeBtnSize.height - 10)
	local searchBox = ccui.EditBox:create(searchBoxSize, RES_DIR.SEARCH_BG)
	searchBox:setFontSize(fontWithColor('M2PX').fontSize)
	searchBox:setFontColor(ccc3FromInt('#5b3c25'))
	searchBox:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
	searchBox:setPlaceHolder(__('请输入工会名字或工会ID'))
	searchBox:setPlaceholderFontSize(19)
	searchBox:setPlaceholderFontColor(ccc3FromInt('#9c9c9c'))
	searchBox:setReturnType(cc.KEYBOARD_RETURNTYPE_DONE)
	-- searchBox:setMaxLength(6)
	display.commonUIParams(searchBox, {po = cc.p(shakeBtn:getPositionX() + shakeBtnSize.width + 10, shakeBtn:getPositionY()), ap = display.LEFT_CENTER})
	parent:addChild(searchBox)

	local searchBtn = display.newButton(titleBgSize.width + 25, shakeBtn:getPositionY(), {ap = display.RIGHT_CENTER, n = RES_DIR.BTN_SEARCH_BG})
	searchBtn:setTag(BTN_TAG.BTN_SEARCH)
	parent:addChild(searchBtn)

	return {
		gridView = gridView,
		shakeBtn = shakeBtn,
		searchBox = searchBox,
		searchBtn = searchBtn,
	}
end

CreateUnionInfo = function (parent, size)
	local infoBg = display.newImageView(RES_DIR.INFO_BG, 0, 0, {ap = display.LEFT_BOTTOM})
	local infoBgSize = infoBg:getContentSize()
	local infoLayer = display.newLayer(size.width - 8, size.height - 6, {ap = display.RIGHT_TOP, size = infoBgSize})
	infoLayer:addChild(infoBg)
	parent:addChild(infoLayer)

	-- 没有工会列表展示
	local unionInfoTipLayer = display.newLayer(0, 0, {ap = display.LEFT_BOTTOM, size = infoBgSize})
	unionInfoTipLayer:setVisible(false)
	infoLayer:addChild(unionInfoTipLayer)

	local roleImg = display.newImageView(RES_DIR.ROLE_IMG, infoBgSize.width / 2, infoBgSize.height / 2 + 50, {ap = display.CENTER})
	local roleImgSize = roleImg:getContentSize()
	unionInfoTipLayer:addChild(roleImg)
	
	local tipLabel = display.newLabel(roleImg:getPositionX(), roleImg:getPositionY() - roleImgSize.height / 2 - 30, {ap = display.CENTER, text = __('当前尚无工会成立'), fontSize = 22, color = '#5c5c5c'})
	unionInfoTipLayer:addChild(tipLabel)

	-- 工会信息展示
	local unionInfoLayer = display.newLayer(0, 0, {ap = display.LEFT_BOTTOM, size = infoBgSize})
	infoLayer:addChild(unionInfoLayer)
	unionInfoLayer:setVisible(false)
	
	local headBg = display.newImageView(RES_DIR.HEAD_FRAME_BG, infoBgSize.width / 2, infoBgSize.height - 80, {ap = display.CENTER})
	local headBgSize = headBg:getContentSize()
	headBg:setScale(0.85)
	unionInfoLayer:addChild(headBg, 1)

	local head = display.newImageView(_res(), infoBgSize.width / 2, infoBgSize.height - 80, {ap = display.CENTER})
	head:setScale(0.85)
	unionInfoLayer:addChild(head)
	
	local unionNameLabel = display.newLabel(headBg:getPositionX(), headBg:getPositionY() - headBgSize.height / 2-10, {text = '', fontSize = 24, color = '#a74700'})
	unionInfoLayer:addChild(unionNameLabel)

	local unionInfoConf = {
		__('会长:'), __('等级:'), __('人数:'),
	}

	local labels = {}
	for i,v in ipairs(unionInfoConf) do
		local nameLabel = display.newLabel(headBg:getPositionX() - 50, unionNameLabel:getPositionY() - 46 - (i - 1) * 35, {text = v, fontSize = 22, color = '#5b3c25'})
		local nameLabelSize = display.getLabelContentSize(nameLabel)
		unionInfoLayer:addChild(nameLabel)

		local laebl = display.newLabel(nameLabel:getPositionX() + nameLabelSize.width / 2 + 10, nameLabel:getPositionY(), fontWithColor(6, {text = '', ap = display.LEFT_CENTER}))
		unionInfoLayer:addChild(laebl)
		table.insert(labels, laebl)
	end

	local unionIntroduceLabel = display.newLabel(headBg:getPositionX(), 270, {ap = display.CENTER_TOP, fontSize = 20, color = '#5b3c25', text = __('工会宣言')})
	local unionIntroduceLabelSize = display.getLabelContentSize(unionIntroduceLabel)
	unionInfoLayer:addChild(unionIntroduceLabel)
	
	local unionDescBg = display.newImageView(RES_DIR.DESC_BG, headBg:getPositionX(), unionIntroduceLabel:getPositionY() - unionIntroduceLabelSize.height - 3, {ap = display.CENTER_TOP , scale9 = true })
	unionInfoLayer:addChild(unionDescBg)


	-- local scrollViewSize = unionDescBg:getContentSize()
	-- -- local unionDescLabel = display.newLabel(scrollViewSize.width / 2, scrollViewSize.height - 10, fontWithColor(6, {ap = display.CENTER_TOP, text = '', w = 22 * 14}))
	-- local unionDescLabel = display.newRichLabel(scrollViewSize.width / 2, scrollViewSize.height - 10,{ap = display.CENTER_TOP, r = true, w = 23, c = {fontWithColor('6', { text = "fhwihf我客户上岛咖啡hawk你ikk hh我客户上岛咖啡hawk你fkas我客户上岛咖啡hawk你fhhfkasfhhfkasf 我客户上岛咖啡hawk你 伤口恢复可维护客户手机就能接啊哈金山毒霸我会帮你把此阿武" })}})

 	-- local scrollView = CScrollView:create(scrollViewSize)
	-- scrollView:setDirection(eScrollViewDirectionVertical)
	-- scrollView:setAnchorPoint(display.CENTER_TOP)
	-- scrollView:setPosition(cc.p(unionDescBg:getPositionX(), unionDescBg:getPositionY()))
	-- -- scrollView:setBackgroundColor(cc.c3b(100,100,200))
	-- unionInfoLayer:addChild(scrollView)
	-- scrollView:setContainerSize(cc.size(scrollViewSize.width, scrollViewSize.height-10))
	-- -- scrollView:setContentOffset(cc.p(0, 0))
	-- scrollView:getContainer():addChild(unionDescLabel)
	local commonEditView = require('common.CommonEditView').new({isEnableEditBox = false})
	display.commonUIParams(commonEditView, {po = cc.p(unionDescBg:getPositionX(), unionDescBg:getPositionY()), ap = display.CENTER_TOP})
	unionInfoLayer:addChild(commonEditView)
	
	local applyBtn = display.newButton(headBg:getPositionX(), 75, {ap = display.CENTER_TOP, n = RES_DIR.BTN_ORANGE, scale9= true  })
	display.commonLabelParams(applyBtn, fontWithColor(14, {text = __('申请加入') , paddingW = 20 }))
	applyBtn:setTag(BTN_TAG.BTN_APPLY)
	unionInfoLayer:addChild(applyBtn)

	
	return {
		unionInfoTipLayer     = unionInfoTipLayer,
		unionInfoLayer        = unionInfoLayer,
		headBg                = headBg,
		head                  = head,
		unionNameLabel        = unionNameLabel,
		labels                = labels,
		commonEditView        = commonEditView,
		applyBtn              = applyBtn,
		
	}

end

CreateCell_ = function ()
	local cell = CGridViewCell:new()
	local frame = display.newImageView(RES_DIR.CELL_SELECT_FRAME, 0, 0, {ap = display.CENTER})
	local size = frame:getContentSize()
	display.commonUIParams(frame, {po = cc.p(size.width / 2 + 3, size.height / 2)})
	cell:addChild(frame, 1)
	frame:setVisible(false)

	local defaultBg = display.newImageView(RES_DIR.CELL_BG_DEFAULT, size.width / 2 + 3, size.height / 2, {ap = display.CENTER})
	cell:addChild(defaultBg)

	local selectBg = display.newImageView(RES_DIR.CELL_BG_SELECT, size.width / 2 + 3, size.height / 2, {ap = display.CENTER})
	cell:addChild(selectBg)
	selectBg:setVisible(false)

	local touchLayer = display.newLayer(size.width / 2 + 3, size.height / 2, {ap = display.CENTER, enable = true, color = cc.c4b(0, 0, 0, 0)})
	cell:addChild(touchLayer)

	local unionInfoLabels = {}
	local unionInfoPosConf   = {
		cc.p(70, size.height * 0.5),
		cc.p(220, size.height * 0.5),
		cc.p(420, size.height * 0.5),
		cc.p(590, size.height * 0.5)
	}
	for i,v in ipairs(unionInfoPosConf) do
		local label = display.newLabel(v.x, v.y, {fontSize = 22, color = '#5b3c25'})
		cell:addChild(label)
		table.insert(unionInfoLabels, label)
	end

	cell.viewData = {
		frame        = frame,
		defaultBg    = defaultBg,
		selectBg     = selectBg,
		touchLayer   = touchLayer,
		unionInfoLabels = unionInfoLabels,
	}
	return cell
end

function UnionLookupView:CreateCell()
	return CreateCell_()
end

function UnionLookupView:getViewData()
	return self.viewData_
end

return UnionLookupView
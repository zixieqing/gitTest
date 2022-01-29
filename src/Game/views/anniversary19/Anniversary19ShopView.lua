--[[
工会商店View
--]]
local Anniversary19ShopView = class('Anniversary19ShopView', function ()
	local node = CLayout:create(display.size)
	node.name = 'Game.views.anniversary19.Anniversary19ShopView'
	node:enableNodeEvents()
	return node
end)

local display = display

local RES_DICT = {
	GUILD_SHOP_BG_WHITE    = app.anniversary2019Mgr:GetResPath('ui/home/union/guild_shop_bg_white.png'),
	GUILD_SHOP_BG          = app.anniversary2019Mgr:GetResPath('ui/home/union/guild_shop_bg.png'),
	GUILD_SHOP_TITLE       = app.anniversary2019Mgr:GetResPath('ui/home/union/guild_shop_title.png'),
	SELECT_BTN             = app.anniversary2019Mgr:GetResPath("ui/common/common_btn_tab_select.png"),
	NORMAL_BTN             = app.anniversary2019Mgr:GetResPath("ui/common/common_btn_tab_default.png"),
	COMMON_BG_GOODS        = app.anniversary2019Mgr:GetResPath('ui/common/common_bg_goods.png'),
	SHOP_BTN_GOODS_DEFAULT = app.anniversary2019Mgr:GetResPath('ui/home/commonShop/shop_btn_goods_default.png'),
	SHOP_BTN_GOODS_SELLOUT = app.anniversary2019Mgr:GetResPath('ui/home/commonShop/shop_btn_goods_sellout.png'),
}

local CreateView, CreateTabCell


function Anniversary19ShopView:ctor( ... )
	local activityDatas = unpack({...}) or {}
	local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 255 * 0.6))
	eaterLayer:setTouchEnabled(true)
	eaterLayer:setContentSize(display.size)
	eaterLayer:setPosition(utils.getLocalCenter(self))
	eaterLayer:setOnClickScriptHandler(function () 
		AppFacade.GetInstance():UnRegsitMediator(activityDatas.mdtName)
	end)
	self.eaterLayer = eaterLayer
	self:addChild(eaterLayer, -1)
	self.viewData_ = CreateView()
	self:addChild(self.viewData_.view, 1)
	self.viewData_.view:setPosition(cc.p(display.cx, display.cy - 25))

	self:addChild(self.viewData_.moneyBar)
end

function Anniversary19ShopView:UpdateMoneyBarGoodList(moneyIdList)
    local args = {
		hideDefault = true,
		isEnableGain = true,
		moneyIdList = moneyIdList
	}
	local viewData = self:GetViewData()
    viewData.moneyBar:RefreshUI(args)
end

function Anniversary19ShopView:UpdateTabSelectState(tabCel, isSelect)
	local toggleView = tabCel:getChildByName('toggleView')
	local curreryName = tabCel:getChildByName('curreryName')
	toggleView:setChecked(isSelect)
	toggleView:setEnabled(not isSelect)
	display.commonLabelParams(curreryName ,{color = isSelect and "#df6428" or "#dbc5b8"})
end

function Anniversary19ShopView:UpdateMoneyBarGoodNum()
    self:GetViewData().moneyBar:updateMoneyBar()
end

function Anniversary19ShopView:UpdateGrideView(datas)
	local gridView = self:GetViewData().gridView
	gridView:setCountOfCell(table.nums(datas))
    gridView:reloadData()
end

function Anniversary19ShopView:GetViewData()
	return self.viewData_
end

function Anniversary19ShopView:CreateTabCell(size, name)
	return CreateTabCell(size, name)
end

function Anniversary19ShopView:UpdateCell(cell, datas)
	local goodsDatas = CommonUtils.GetConfig('goods', 'goods', datas.goodsId) or {}
	cell.goodsIcon:RefreshSelf({goodsId = datas.goodsId, num = datas.goodsNum, showAmount = true})
	cell.goodsName:setString(tostring(goodsDatas.name))
	cell.stockLabel:setString(string.fmt(app.anniversary2019Mgr:GetPoText(__('库存:_num_')), {['_num_'] = tostring(datas.leftPurchasedNum)}))
	display.reloadRichLabel(cell.priceLabel, { c = {
		{text = tostring(datas.price) .. '  ',fontSize = 22, color = '#ffffff', font = TTF_GAME_FONT, ttf = true},
		{img = CommonUtils.GetGoodsIconPathById(checkint(datas.currency)), scale = 0.18}
	}})

	if checkint(datas.leftPurchasedNum) < 0 then
		cell.bgBtn:setNormalImage(RES_DICT.SHOP_BTN_GOODS_DEFAULT)
		cell.bgBtn:setSelectedImage(RES_DICT.SHOP_BTN_GOODS_DEFAULT)
		cell.bgBtn:setEnabled(true)
		cell.sellOut:setVisible(false)
		cell.lockMask:setVisible(false)
		cell.stockLabel:setVisible(false)
	elseif checkint(datas.leftPurchasedNum) > 0 then
		cell.bgBtn:setNormalImage(RES_DICT.SHOP_BTN_GOODS_DEFAULT)
		cell.bgBtn:setSelectedImage(RES_DICT.SHOP_BTN_GOODS_DEFAULT)
		cell.bgBtn:setEnabled(true)
		cell.sellOut:setVisible(false)
		cell.lockMask:setVisible(false)
		cell.stockLabel:setVisible(true)
	else
		cell.bgBtn:setNormalImage(RES_DICT.SHOP_BTN_GOODS_SELLOUT)
		cell.bgBtn:setSelectedImage(RES_DICT.SHOP_BTN_GOODS_SELLOUT)
		cell.bgBtn:setEnabled(false)
		cell.sellOut:setVisible(true)
		cell.lockMask:setVisible(true)
		cell.stockLabel:setVisible(false)
	end
end

CreateView = function()

	local bg = display.newImageView(RES_DICT.GUILD_SHOP_BG_WHITE, 0, 0)
	local bgSize = bg:getContentSize()
	local middleX, middleY = bgSize.width * 0.5, bgSize.height * 0.5
	
	local view = CLayout:create(bgSize)
	bg:setPosition(middleX, middleY - 5)
	
	local bgFrame = display.newImageView(RES_DICT.GUILD_SHOP_BG, middleX,  middleY)
	view:addChild(bgFrame, 1)
	view:addChild(bg, 1)

	local mask = display.newLayer(middleX, middleY, {ap = display.CENTER, size = bgSize, enable = true, color = cc.c4b(0,0,0,0)})
	view:addChild(mask, -1)

	local titleBg = display.newButton(middleX, bgSize.height + 16, {n = RES_DICT.GUILD_SHOP_TITLE, enable = false})
	view:addChild(titleBg, 10)
	display.commonLabelParams(titleBg, fontWithColor(18, {text = app.anniversary2019Mgr:GetPoText(__('商店'))}))

	-- tabListView
	local tabListView = CListView:create(cc.size(1060, 50))
	tabListView:setBounceable(false)
	tabListView:setDirection(eScrollViewDirectionHorizontal)
	display.commonUIParams(tabListView, {po = cc.p(15, 515), ap = display.LEFT_BOTTOM})
	-- tabListView:setBackgroundColor(cc.c4b(0, 0, 0, 150))
	view:addChild(tabListView, 10)

	-- listView
	local listSize = cc.size(bgSize.width - 24, 510)
	local listCellSize = cc.size((listSize.width - 8)/5, listSize.height*0.55)
	local listBg = display.newImageView(RES_DICT.COMMON_BG_GOODS, middleX, 6, {ap = cc.p(0.5, 0), scale9 = true, size = listSize, capInsets = cc.rect(10, 10, 487, 113)})
	view:addChild(listBg, 3)

	local gridView = CGridView:create(cc.size(listSize.width - 8, listSize.height))
	gridView:setSizeOfCell(listCellSize)
	gridView:setColumns(5)
	view:addChild(gridView, 10)
	gridView:setAnchorPoint(cc.p(0.5, 0))
	gridView:setPosition(cc.p(middleX, listBg:getPositionY()))
	
	-- CommonMoneyBar
	local moneyBar = require("common.CommonMoneyBar").new()

	return {
		view             = view,
		bgSize			 = bgSize,
		tabListView      = tabListView,
		listSize 	     = listSize,
		listCellSize 	 = listCellSize,
		gridView 	   	 = gridView,
		moneyBar         = moneyBar,
	}
end

CreateTabCell = function (size, name)
	
	local middleX, middleY = size.width * 0.5, size.height * 0.5
	local cell = display.newLayer(0, 0, {size = size})

	local toggleView = display.newToggleView(middleX, middleY, {n = RES_DICT.NORMAL_BTN, d = RES_DICT.SELECT_BTN, s = RES_DICT.SELECT_BTN})
	toggleView:setName('toggleView')
	cell:addChild(toggleView)
	
	local curreryName = display.newLabel(middleX, middleY,
		fontWithColor(10, {color = "#dbc5b8", text = name}))
	curreryName:setName("curreryName")
	cell:addChild(curreryName)

	return cell
end

return Anniversary19ShopView

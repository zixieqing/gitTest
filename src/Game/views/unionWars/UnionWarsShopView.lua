--[[
工会商店View
--]]
local UnionWarsShopView = class('UnionWarsShopView', function ()
	local node = CLayout:create(display.size)
	node.name = 'Game.views.unionWars.UnionWarsShopView'
	node:enableNodeEvents()
	return node
end)

local GoodPurchaseNode = require('common.GoodPurchaseNode')

local CreateView = nil
local RES_DICT = {
	GUILD_SHOP_BG_WHITE    = _res('ui/home/union/guild_shop_bg_white.png'),
	GUILD_SHOP_BG          = _res('ui/home/union/guild_shop_bg.png'),
	GUILD_SHOP_TITLE       = _res('ui/home/union/guild_shop_title.png'),
	SHOP_BTN_REFRESH       = _res('ui/home/commonShop/shop_btn_refresh.png'),
	COMMON_BG_GOODS        = _res('ui/common/common_bg_goods.png'),
	MAIN_BG_MONEY          = _res('ui/home/nmain/main_bg_money.png'),
}

function UnionWarsShopView:ctor( ... )
	self.activityDatas = unpack({...}) or {}
	local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 255 * 0.6))
	eaterLayer:setTouchEnabled(true)
	eaterLayer:setContentSize(display.size)
	eaterLayer:setPosition(utils.getLocalCenter(self))
	self.eaterLayer = eaterLayer
	self:addChild(eaterLayer, -1)
	self.viewData_ = CreateView()
	self:addChild(self.viewData_.moneyBar, 100)	
	self:addChild(self.viewData_.view, 1)
	self.viewData_.view:setPosition(cc.p(display.cx, display.cy - 25))
end

function UnionWarsShopView:UpdateMoneyBarGoodList(args)
    local viewData = self:GetViewData()
    viewData.moneyBar:RefreshUI(args)
end

function UnionWarsShopView:UpdateMoneyBarGoodNum()
    local viewData = self:GetViewData()
    viewData.moneyBar:updateMoneyBar()
end

CreateView = function()

	local bg = display.newImageView(RES_DICT.GUILD_SHOP_BG_WHITE, 0, 0)
	local bgSize = bg:getContentSize()
	local view = CLayout:create(bgSize)
	bg:setPosition(bgSize.width/2, bgSize.height/2 - 5)
	view:addChild(bg, 2)
	local bgFrame = display.newImageView(RES_DICT.GUILD_SHOP_BG, bgSize.width/2,  bgSize.height/2)
	view:addChild(bgFrame, 1)
	local mask = display.newLayer(bgSize.width/2, bgSize.height/2, {ap = display.CENTER, size = bgSize, enable = true, color = cc.c4b(0,0,0,0)})
	view:addChild(mask, -1)

	local titleBg = display.newButton(bgSize.width/2, bgSize.height + 16, {n = RES_DICT.GUILD_SHOP_TITLE, enable = false})
	view:addChild(titleBg, 10)
	display.commonLabelParams(titleBg, fontWithColor(18, {text = __('工会竞赛商店')}))

	-- 批量购买
	local batchBuyBtn = display.newButton(25, 548, {n = _res('ui/common/common_btn_orange.png'), scale9 = true, ap = display.LEFT_CENTER})
	display.commonLabelParams(batchBuyBtn, fontWithColor(14, {text = __('快速购买'), paddingW = 20, safeW = 100}))
	view:addChild(batchBuyBtn, 10)

	-- time label
	local timeLabelX = batchBuyBtn:getPositionX() + batchBuyBtn:getContentSize().width + 20
	local timeLabelY = batchBuyBtn:getPositionY()
	local timeLabel  = display.newLabel(timeLabelX, timeLabelY, fontWithColor(16, {text = '', ap = cc.p(0, 0.5)}))
	view:addChild(timeLabel, 10)

	-- 刷新按钮
	local refreshBtn = display.newButton(bgSize.width - 38, bgSize.height - 40, {n = RES_DICT.SHOP_BTN_REFRESH})
	view:addChild(refreshBtn, 10)
	local  leftRefreshTime = display.newLabel(bgSize.width - 75, bgSize.height - 31, fontWithColor(16, {ap = cc.p(1, 0.5), text = ''}))
	view:addChild(leftRefreshTime, 10)
	local refreshCostLabel = display.newRichLabel(bgSize.width - 75, bgSize.height - 60, {ap = cc.p(1, 0.5)})
	view:addChild(refreshCostLabel, 10)
	-- listView
	local listSize = cc.size(bgSize.width - 24, 510)
	local listCellSize = cc.size((listSize.width - 8)/5, listSize.height*0.55)
	local listBg = display.newImageView(RES_DICT.COMMON_BG_GOODS, bgSize.width/2, 6, {ap = cc.p(0.5, 0), scale9 = true, size = listSize, capInsets = cc.rect(10, 10, 487, 113)})
	view:addChild(listBg, 3)
	local gridView = CGridView:create(cc.size(listSize.width - 8, listSize.height))
	gridView:setSizeOfCell(listCellSize)
	gridView:setColumns(5)
	view:addChild(gridView, 10)
	gridView:setAnchorPoint(cc.p(0.5, 0))
	gridView:setPosition(cc.p(bgSize.width/2, listBg:getPositionY()))

	local moneyBar = require("common.CommonMoneyBar").new()
	-- view:addChild(moneyBar)

	return {
		view             = view,
		bgSize			 = bgSize,
		listSize 	     = listSize,
		listCellSize 	 = listCellSize,
		gridView 	   	 = gridView,
		timeLabel	     = timeLabel,
		batchBuyBtn      = batchBuyBtn,
		refreshBtn  	 = refreshBtn,
		leftRefreshTime	 = leftRefreshTime,
		refreshCostLabel = refreshCostLabel,
		-- moneyNode	     = moneyNode,
		-- moneyNods 	     = moneyNods
		moneyBar         = moneyBar,
	}
end

function UnionWarsShopView:GetViewData()
	return self.viewData_
end

return UnionWarsShopView

--[[
工会商店View
--]]
local UnionShopView = class('UnionShopView', function ()
	local node = CLayout:create(display.size)
	node.name = 'Game.views.UnionShopView'
	node:enableNodeEvents()
	return node
end)
local GoodPurchaseNode = require('common.GoodPurchaseNode')
local function CreateView( )

	local bg = display.newImageView(_res('ui/home/union/guild_shop_bg_white.png'), 0, 0)
	local bgSize = bg:getContentSize()
	local view = CLayout:create(bgSize)
	bg:setPosition(bgSize.width/2, bgSize.height/2 - 5)
	view:addChild(bg, 2)
	local bgFrame = display.newImageView(_res('ui/home/union/guild_shop_bg.png'), bgSize.width/2,  bgSize.height/2)
	view:addChild(bgFrame, 1)
	local mask = display.newLayer(bgSize.width/2, bgSize.height/2, {ap = display.CENTER, size = bgSize, enable = true, color = cc.c4b(0,0,0,0)})
	view:addChild(mask, -1)

	local titleBg = display.newButton(bgSize.width/2, bgSize.height + 16, {n = _res('ui/home/union/guild_shop_title.png'), enable = false})
	view:addChild(titleBg, 10)
	display.commonLabelParams(titleBg, fontWithColor(18, {text = __('工会商店')}))

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
	local refreshBtn = display.newButton(bgSize.width - 38, bgSize.height - 40, {n = _res('ui/home/commonShop/shop_btn_refresh.png')})
	view:addChild(refreshBtn, 10)
	local  leftRefreshTime = display.newLabel(bgSize.width - 75, bgSize.height - 31, fontWithColor(16, {ap = cc.p(1, 0.5), text = ''}))
	view:addChild(leftRefreshTime, 10)
	local refreshCostLabel = display.newRichLabel(bgSize.width - 75, bgSize.height - 60, {ap = cc.p(1, 0.5)})
	view:addChild(refreshCostLabel, 10)
	-- listView
	local listSize = cc.size(bgSize.width - 24, 510)
	-- local listCellSize = cc.size((listSize.width - 8)/5, listSize.height*0.55)
	local listCellSize = cc.size((listSize.width - 8)/5, 290)
	local listBg = display.newImageView(_res('ui/common/common_bg_goods.png'), bgSize.width/2, 6, {ap = cc.p(0.5, 0), scale9 = true, size = listSize, capInsets = cc.rect(10, 10, 487, 113)})
	view:addChild(listBg, 3)
	local gridView = CGridView:create(cc.size(listSize.width - 8, listSize.height))
	gridView:setSizeOfCell(listCellSize)
	gridView:setColumns(5)
	view:addChild(gridView, 10)
	gridView:setAnchorPoint(cc.p(0.5, 0))
	gridView:setPosition(cc.p(bgSize.width/2, listBg:getPositionY()))
	-- 重写顶部状态条
    local topLayoutSize = cc.size(display.width, 80)
    local moneyNode = CLayout:create(topLayoutSize)
    moneyNode:setName('TOP_LAYOUT')
    display.commonUIParams(moneyNode, {ap = display.CENTER_TOP, po = cc.p(display.cx, display.height)})
    -- top icon
    local imageImage = display.newImageView(_res('ui/home/nmain/main_bg_money.png'),0,0,{enable = false,
    scale9 = true, size = cc.size(900,54)})
    display.commonUIParams(imageImage,{ap = cc.p(1.0,1.0), po = cc.p(display.width,80)})
    moneyNode:addChild(imageImage)
    local moneyNods = {}
    local iconData = {UNION_POINT_ID, HP_ID, GOLD_ID, DIAMOND_ID}
    for i,v in ipairs(iconData) do
		local isShowHpTips = (v == HP_ID) and 1 or -1
		local isDisable = v == DIAMOND_ID and true or (v ~= GOLD_ID and isDisableGain)
		if v == UNION_POINT_ID then isDisable = true end
        local purchaseNode = GoodPurchaseNode.new({id = v, disable = isDisable,isShowHpTips = isShowHpTips})
        -- local purchaseNode = GoodPurchaseNode.new({id = v, isShowHpTips = isShowHpTips})
        display.commonUIParams(purchaseNode,
        {ap = cc.p(1, 0.5), po = cc.p(topLayoutSize.width  - display.SAFE_L - 20 - (( 4 - i) * (purchaseNode:getContentSize().width + 16)), imageImage:getPositionY()- 26)})
        moneyNode:addChild(purchaseNode, 5)
        purchaseNode:setName('purchaseNode' .. i)
        purchaseNode.viewData.touchBg:setTag(checkint(v))
        purchaseNode:setControllable(v ~= DIAMOND_ID)
        moneyNods[tostring( v )] = purchaseNode
    end
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
		moneyNode	     = moneyNode,
		moneyNods 	     = moneyNods


	}
end
function UnionShopView:ctor( ... )
	self.activityDatas = unpack({...}) or {}
	local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 255 * 0.6))
	eaterLayer:setTouchEnabled(true)
	eaterLayer:setContentSize(display.size)
	eaterLayer:setPosition(utils.getLocalCenter(self))
	eaterLayer:setOnClickScriptHandler(function ()
		AppFacade.GetInstance():UnRegsitMediator('UnionShopMediator')
	end)
	self.eaterLayer = eaterLayer
	self:addChild(eaterLayer, -1)
	self.viewData_ = CreateView()
	self:addChild(self.viewData_.moneyNode, 100)
	self:addChild(self.viewData_.view, 1)
	self.viewData_.view:setPosition(cc.p(display.cx, display.cy - 25))
end
return UnionShopView

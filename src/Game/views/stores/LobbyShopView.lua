--[[
小费商店View
--]]
local LobbyShopView = class('LobbyShopView', function ()
	local node = CLayout:create(display.size)
	node.name = 'Game.views.stores.LobbyShopView'
	node:enableNodeEvents()
	return node
end)

local GoodPurchaseNode = require('common.GoodPurchaseNode')

local function CreateView( )

	local abg = display.newImageView(_res('ui/home/union/guild_shop_bg_white.png'), 0, 0)
	local abgSize = abg:getContentSize()
	local view = CLayout:create(abgSize)
	abg:setPosition(abgSize.width/2, abgSize.height/2 - 5)
	view:addChild(abg, 2)
	local bgFrame = display.newImageView(_res('ui/home/union/guild_shop_bg.png'), abgSize.width/2,  abgSize.height/2)
	view:addChild(bgFrame, 1)
	local mask = display.newLayer(abgSize.width/2, abgSize.height/2, {ap = display.CENTER, size = abgSize, enable = true, color = cc.c4b(0,0,0,0)})
	view:addChild(mask, -1)

	local titleBg = display.newButton(abgSize.width/2, abgSize.height + 16, {n = _res('ui/home/union/guild_shop_title.png'), enable = false})
	view:addChild(titleBg, 10)
	display.commonLabelParams(titleBg, fontWithColor(18, {text = __('小费商店')}))
	
	local size = cc.size(1088, 580)
	local cview = CLayout:create(size)
	cview:setAnchorPoint( 0.5, 0)
	cview:setPosition(abgSize.width * 0.5, 0)
	view:addChild(cview,20)
	-- 商城相关的逻辑

	-- local bg = display.newImageView(_res('ui/home/commonShop/shop_bg.png'), 0, 0, {ap = cc.p(0, 0)})
	-- cview:addChild(bg)
	--- 获取背景图片的Size
	local bgSize  = size
	-- 筛选按钮
	local selectBtn = display.newButton(10, 522, {ap = cc.p(0, 0), n = _res('ui/home/teamformation/choosehero/team_btn_selection_unused.png')})
	cview:addChild(selectBtn)
	selectBtn:setVisible(false)
	display.commonLabelParams(selectBtn, {text = __('全部'), fontSize = fontWithColor('18').fontSize, color = fontWithColor('18').color})


	-- local hasNumsLabel = display.newLabel(10, 522, {ap = cc.p(0,0),text = ('当前__数量：100'), fontSize = fontWithColor('16').fontSize, color = fontWithColor('16').color})
	-- cview:addChild(hasNumsLabel)

	-- 批量购买
	local batchBuyBtn = display.newButton(25, 548, {n = _res('ui/common/common_btn_orange.png'), scale9 = true, ap = display.LEFT_CENTER})
	display.commonLabelParams(batchBuyBtn, fontWithColor(14, {text = __('快速购买'), paddingW = 20, safeW = 100}))
	cview:addChild(batchBuyBtn)

	-- 刷新时间
	local refreshLabelX = batchBuyBtn:getPositionX() + batchBuyBtn:getContentSize().width + 20
	local refreshLabelY = batchBuyBtn:getPositionY()
	local refreshLabel  = display.newLabel(refreshLabelX, refreshLabelY, {text = __('系统刷新倒计时'), fontSize = fontWithColor('16').fontSize, color = fontWithColor('16').color, ap = display.LEFT_CENTER})
	cview:addChild(refreshLabel)

	local refreshTimeLabelX = refreshLabel:getPositionX() + display.getLabelContentSize(refreshLabel).width + 10
	local refreshTimeLabelY = refreshLabel:getPositionY()
	local refreshTimeLabel  = display.newLabel(refreshTimeLabelX, refreshTimeLabelY, {text = '00:00:00', fontSize = fontWithColor('16').fontSize, color = fontWithColor('16').color, ap = display.LEFT_CENTER})
	cview:addChild(refreshTimeLabel)
	-- 刷新按钮
	local refreshBtn = display.newButton(size.width+4, 506, {n = _res('ui/home/commonShop/shop_btn_refresh.png'), ap = cc.p(1, 0)})
	cview:addChild(refreshBtn)

	local refreshBtnLabel = display.newLabel(8, refreshBtn:getContentSize().height*0.60- 5, {text = __("今日刷新次数：1"), fontSize = 22, color = '5b3c25'})
	refreshBtn:addChild(refreshBtnLabel)
	refreshBtnLabel:setAnchorPoint(cc.p(1,0.5))
	local diamondCostLabel = display.newRichLabel(12, refreshBtn:getContentSize().height*0.35 - 7, {ap = cc.p(1,0.5),r = true, c =
	{
		{text = '20', fontSize = 20, color = '#5b3c25'},
		{img = _res('arts/goods/goods_icon_' .. DIAMOND_ID .. '.png'), scale = 0.15}
	}
	})
	refreshBtn:addChild(diamondCostLabel)

	local promoterBtn = display.newButton(size.width - 10, 522, {ap = cc.p(1, 0), n = _res('ui/home/teamformation/choosehero/team_btn_selection_unused.png')})
	promoterBtn:setVisible(false)
	display.commonLabelParams(promoterBtn, fontWithColor(18, {text = __('推广员')}))
	cview:addChild(promoterBtn)

	local listBg = display.newImageView(_res('ui/common/common_bg_goods.png'), size.width/2, 12,
	{scale9 = true, size = cc.size(bgSize.width - 24,502),ap = cc.p(0.5,0)}
	)
	cview:addChild(listBg,1)

	local ListBgFrameSize = listBg:getContentSize()
	--添加列表功能
	local taskListSize = cc.size(ListBgFrameSize.width, ListBgFrameSize.height - 4)
	local taskListCellSize = cc.size(ListBgFrameSize.width/5 , 280)

	local gridView = CGridView:create(taskListSize)
	gridView:setSizeOfCell(taskListCellSize)
	gridView:setColumns(5)
	gridView:setAutoRelocate(true)
	cview:addChild(gridView,2)
	gridView:setAnchorPoint(cc.p(0.5, 0))
	gridView:setPosition(cc.p(listBg:getPositionX() , listBg:getPositionY()  ))

    -- local idolImg = CommonUtils.GetRoleNodeById('role_48', 1)
    -- -- idolImg:setScale(0.8)
    -- idolImg:setAnchorPoint(display.RIGHT_TOP)
    -- idolImg:setPosition(cc.p(size.width - 120, size.height + 140))
    -- idolImg:setScaleX(-1)
    -- view:addChild(idolImg, 10)
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
    local iconData = {TIPPING_ID, HP_ID, GOLD_ID, DIAMOND_ID}
    for i,v in ipairs(iconData) do
		local isShowHpTips = (v == HP_ID) and 1 or -1
		local isDisable = v == DIAMOND_ID and true or (v ~= GOLD_ID and isDisableGain)
        local purchaseNode = GoodPurchaseNode.new({id = v, disable = isDisable,isShowHpTips = isShowHpTips})
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
		cview 			 = cview,
		batchBuyBtn      = batchBuyBtn,
		refreshLabel     = refreshLabel,
		refreshBtn  	 = refreshBtn,
		refreshTimeLabel = refreshTimeLabel,
		refreshBtnLabel  = refreshBtnLabel,
		selectBtn        = selectBtn,
		-- hasNumsLabel	 = hasNumsLabel,
		promoterBtn      = promoterBtn,
		listBg 			 = listBg,
		gridView		 = gridView,
		-- idolImg 		 = idolImg,
		diamondCostLabel = diamondCostLabel,
		titleBtn  = titleBtn ,
		moneyNode	     = moneyNode,
		moneyNods 	     = moneyNods

	}
end

function LobbyShopView:ctor( ... )
	local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 255 * 0.6))
	eaterLayer:setTouchEnabled(true)
	eaterLayer:setContentSize(display.size)
	eaterLayer:setPosition(utils.getLocalCenter(self))
	eaterLayer:setOnClickScriptHandler(function () 
		AppFacade.GetInstance():UnRegsitMediator('LobbyShopViewMediator')
	end)
	self.eaterLayer = eaterLayer
	self:addChild(eaterLayer, -1)
	self.viewData = CreateView()
	self:addChild(self.viewData.moneyNode, 100)	
	self:addChild(self.viewData.view, 1)
	self.viewData.view:setPosition(cc.p(display.cx, display.cy - 25))

end



--[[
layoutData = {
	shopData       --商品数据
	isShowTopUI,   --是否显示顶部信息
	isUseGridView, --是否使用滑动层
	showTopUiType，--顶部信息显示不同需求组合
}
]]--

function LobbyShopView:InitShowUiAndTopUi(layoutData)
	-- dump(showTopUiType)
	local refreshLabel     = self.viewData.refreshLabel
	local refreshBtn  	   = self.viewData.refreshBtn
	local refreshTimeLabel = self.viewData.refreshTimeLabel
	local selectBtn        = self.viewData.selectBtn
	-- local hasNumsLabel     = self.viewData.hasNumsLabel
	local diamondCostLabel = self.viewData.diamondCostLabel
	local refreshBtnLabel  = self.viewData.refreshBtnLabel
	local promoterBtn      = self.viewData.promoterBtn
	local listBg 		   = self.viewData.listBg
	local gridView 		   = self.viewData.gridView

	refreshLabel:setVisible(false)
	refreshBtn:setVisible(false)
	refreshTimeLabel:setVisible(false)
	selectBtn:setVisible(false)
	-- hasNumsLabel:setVisible(false)

	if layoutData.isShowTopUI then
		if layoutData.showTopUiType == 1 then
			-- hasNumsLabel:setVisible(true)
			refreshLabel:setVisible(true)
			refreshBtn:setVisible(true)
			refreshTimeLabel:setVisible(true)
			display.reloadRichLabel(diamondCostLabel, {c = {
				{text = layoutData.shopData.refreshDiamond or 1, fontSize = 20, color = '#5b3c25'},
				{img = _res('arts/goods/goods_icon_' .. DIAMOND_ID .. '.png'), scale = 0.15}
			}})

			-- refreshBtn:setOnClickScriptHandler(handler(self,self.RefreshButtonAction))
			refreshBtnLabel:setString(string.fmt(__('今日刷新次数:_num_'),{_num_ = layoutData.shopData.refreshLeftTimes or 2}))
		elseif layoutData.showTopUiType == 2 then
			-- hasNumsLabel:setVisible(true)
		elseif layoutData.showTopUiType == 3 then
			selectBtn:setVisible(true)
		elseif layoutData.showTopUiType == 4 then
			-- moneyView:setVisible(true)
			refreshLabel:setVisible(true)
			refreshBtn:setVisible(true)
			refreshTimeLabel:setVisible(true)
			display.reloadRichLabel(diamondCostLabel, {c = {
				{text = layoutData.shopData.refreshDiamond, fontSize = 20, color = '#5b3c25'},
				{img = _res('arts/goods/goods_icon_' .. DIAMOND_ID .. '.png'), scale = 0.15}
			}})
			-- amountLabel:setString(gameMgr:GetUserInfo().tip)
			-- refreshBtn:setOnClickScriptHandler(handler(self,self.RefreshButtonAction))
			refreshBtnLabel:setString(string.fmt(__('今日刷新次数:_num_'),{_num_ = layoutData.shopData.refreshLeftTimes}))

		elseif layoutData.showTopUiType == 5 then

		elseif layoutData.showTopUiType == 6 then
			promoterBtn:setVisible(true)
		end
	else
		listBg:setContentSize(cc.size(832,560))
		gridView:setContentSize(cc.size(832,556))
		if not layoutData.isUseGridView then
			gridView:setVisible(false)
		end
	end
end

return LobbyShopView
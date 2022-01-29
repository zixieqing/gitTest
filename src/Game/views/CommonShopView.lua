--[[

--]]
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local CommonShopView = class('CommonShopView', function ()
	local node = CLayout:create(cc.size(852, 580))
	node:setAnchorPoint(cc.p(0, 0))
	-- node:setBackgroundColor(cc.c4b(200, 0, 0, 100))
	node.name = 'home.CommonShopView'
	node:enableNodeEvents()
	return node
end)
local ShopConfig = {
	['1'] = { mediatorName = 'ChestShopViewMediator' 		,shopName = __('礼包商城') ,tag = 1 ,key = 'chest'},
	['2'] = { mediatorName = 'GoodsShopViewMediator' 		,shopName = __('道具商城') ,tag = 2 ,key = 'goods'},
	['3'] = { mediatorName = 'CardSkinShopViewMediator' 	,shopName = __('皮肤商城') ,tag = 3 ,key = 'cardSkin'},
	['4'] = { mediatorName = 'LobbyShopViewMediator' 		,shopName = __('餐厅商城') ,tag = 4 ,key = 'restaurant'},
	['5'] = { mediatorName = 'DiamondShopViewMediator' 		,shopName = __('幻晶石商城') ,tag = 5 ,key = 'diamond'},
	['6'] = { mediatorName = 'MemberShopViewMediator' 		,shopName = __('月卡商城') ,tag = 6 ,key = 'member'},
	['7'] = { mediatorName = 'KOFShopViewMediator' 			,shopName = __('通宝商店') ,tag = 7 ,key = 'kofArena'},
	-- ['7'] = { mediatorName = 'LobbyShopViewMediator'   		,shopName = __('餐厅avatar商城') ,tag = 7 ,key = 'restaurantAvatar'},
}
local ShopType = {
	CHEST_SHOP     = 1,     ---礼包商城
	GOODS_SHOP     = 2,		---道具商城
	CARD_SKIN_SHOP = 3, ---皮肤商城
	LOBBY_SHOP     = 4,		---餐厅商城
	DIAMOND_SHOP   = 5,	---幻晶石商城
	MEMBER_SHOP    = 6,	---月卡商城
	KOF_SHOP       = 7,	---拳皇商城
}

local function CreateView(data)
	data = data or {}
	local size = cc.size(852, 580)
	local view = CLayout:create(size)
	view:setAnchorPoint(0, 0)
	if checkint(data.type) == ShopType.DIAMOND_SHOP then
		local bg = display.newImageView(_res('ui/home/commonShop/shop_bg.png'), 0, 0, {ap = cc.p(0, 0)})
		view:addChild(bg)
		--- 获取背景图片的Size
		local bgSize  = bg:getContentSize()
		local listBg = display.newImageView(_res('ui/common/common_bg_goods.png'), size.width/2, 12,
		{scale9 = true, size = cc.size(832,532),ap = cc.p(0.5,0.5)}
		)
		local listSize = listBg:getContentSize()

		local listLayout   = display.newLayer(size.width/2,size.height/2 ,{ size =  listSize , ap = display.CENTER})
		listBg:setPosition(cc.p(listSize.width/2 , listSize.height/2))
		listLayout:addChild(listBg)
		view:addChild(listLayout)
		local taskListSize = listSize
		if data.isAnyDouble and data.isForeign then  -- 国外并且是首冲翻倍显示
			local titleBtn = display.newButton(listSize.width/2, listSize.height , { n = "ui/home/commonShop/shop_diamonds_bg_tips.png" ,s = "ui/home/commonShop/shop_diamonds_bg_tips.png" , ap = display.CENTER_TOP ,enable = false  })
			display.commonLabelParams(titleBtn, fontWithColor('3', { text = __('首冲任意档位可获得双倍幻晶石')} ))
			listLayout:addChild(titleBtn)
			--titleBtn:setVisible(false)
			local titleSize = titleBtn:getContentSize()
			taskListSize.height =  taskListSize.height - titleSize.height
		end



		-- local idolImg = display.newImageView(_res('ui/home/commonShop/shop_idol.png'),0, -100)
		-- view:addChild(idolImg,10)
		-- idolImg:setPositionX(size.width - 20)
		-- idolImg:setAnchorPoint(cc.p(0,0))
        local idolImg = CommonUtils.GetRoleNodeById('role_48', 1)
        idolImg:setAnchorPoint(display.RIGHT_TOP)
        idolImg:setPosition(cc.p(size.width - 120, size.height + 140))
        idolImg:setScaleX(-1)
        view:addChild(idolImg, 10)



		local taskListCellSize =cc.size(208, 256)
		local gridView = CGridView:create(taskListSize)
		gridView:setSizeOfCell(taskListCellSize)
		gridView:setColumns(4)
		--gridView:setAutoRelocate(true)
		listLayout:addChild(gridView,2)
		gridView:setAnchorPoint(cc.p(0.5, 1))
		gridView:setPosition(cc.p(taskListSize.width/2 , taskListSize.height))
		return {
			view 			 = view,
			listBg 			 = listBg,
			gridView		 = gridView,
			titleBtn  = titleBtn,
		}
	else
		local bg = display.newImageView(_res('ui/home/commonShop/shop_bg.png'), 0, 0, {ap = cc.p(0, 0)})
		view:addChild(bg)
		--- 获取背景图片的Size
		local bgSize  = bg:getContentSize()


		-- 筛选按钮
		local selectBtn = display.newButton(10, 522, {ap = cc.p(0, 0), n = _res('ui/home/teamformation/choosehero/team_btn_selection_unused.png')})
		view:addChild(selectBtn)
		display.commonLabelParams(selectBtn, {text = __('全部'), fontSize = fontWithColor('18').fontSize, color = fontWithColor('18').color})


		local hasNumsLabel = display.newLabel(10, 522, {ap = cc.p(0,0),text = ('当前__数量：100'), fontSize = fontWithColor('16').fontSize, color = fontWithColor('16').color})
		view:addChild(hasNumsLabel)


		-- 刷新时间
		local refreshLabel = display.newLabel(20, 562, {ap = cc.p(0,0.5) ,  text = __('系统刷新倒计时'), fontSize = fontWithColor('16').fontSize, color = fontWithColor('16').color , reqW = 400})
		view:addChild(refreshLabel)
		local refreshTimeLabel = display.newLabel(20, 532, {ap = cc.p(0,0.5),text = '00:00:00', fontSize = fontWithColor('16').fontSize, color = fontWithColor('16').color})
		view:addChild(refreshTimeLabel)
		-- 刷新按钮
		local refreshBtn = display.newButton(size.width+4, 506, {n = _res('ui/home/commonShop/shop_btn_refresh.png'), ap = cc.p(1, 0)})
		view:addChild(refreshBtn)

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
		view:addChild(promoterBtn)

		local listBg = display.newImageView(_res('ui/common/common_bg_goods.png'), size.width/2, 12,
		{scale9 = true, size = cc.size(832,502),ap = cc.p(0.5,0)}
		)
		view:addChild(listBg,1)

		local ListBgFrameSize = listBg:getContentSize()
		--添加列表功能
		local taskListSize = cc.size(ListBgFrameSize.width, ListBgFrameSize.height - 4)
		local taskListCellSize = cc.size(ListBgFrameSize.width/4 , 290)

		local gridView = CGridView:create(taskListSize)
		gridView:setSizeOfCell(taskListCellSize)
		gridView:setColumns(4)
		gridView:setAutoRelocate(true)
		view:addChild(gridView,2)
		gridView:setAnchorPoint(cc.p(0.5, 0))
		gridView:setPosition(cc.p(listBg:getPositionX() , listBg:getPositionY()  ))
		-- gridView:setBackgroundColor(cc.c4b(200, 0, 0, 100))


        local idolImg = CommonUtils.GetRoleNodeById('role_48', 1)
        -- idolImg:setScale(0.8)
        idolImg:setAnchorPoint(display.RIGHT_TOP)
        idolImg:setPosition(cc.p(size.width - 120, size.height + 140))
        idolImg:setScaleX(-1)
        view:addChild(idolImg, 10)

        --[[
		local moneyView = CLayout:create(cc.size(190, 40))
		moneyView:setAnchorPoint(cc.p(1,1))
		-- moneyView:setPosition(cc.p(display.width*0.5,display.height))
		moneyView:setPosition(cc.p(size.width* 0.61,size.height + TOP_HEIGHT + 33))
		view:addChild(moneyView,100)
		moneyView:setVisible(false)

		local bg = display.newImageView(_res('ui/home/commonShop/lobby_btn_huobi.png'), 0, 0)
		display.commonUIParams(bg, {ap = cc.p(0,0)})
		moneyView:addChild(bg)


		local amountLabel = display.newLabel(20,moneyView:getContentSize().height * 0.5,
			{ttf = true, font = TTF_GAME_FONT, text = "100000", fontSize = 21, color = '#ffffff'})
		display.commonUIParams(amountLabel, {ap = display.LEFT_CENTER})
		moneyView:addChild(amountLabel, 6)


		local goodIconPath = CommonUtils.GetGoodsIconPathById(TIPPING_ID)
		local goodIcon = display.newImageView(goodIconPath, 0, moneyView:getContentSize().height * 0.5, {enable = true, cb = function (sender)
			uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = TIPPING_ID, type = 1})
		end})
		goodIcon:setScale(0.26)
		moneyView:addChild(goodIcon)

        --]]


		return {
			view 			 = view,
			refreshLabel     = refreshLabel,
			refreshBtn  	 = refreshBtn,
			refreshTimeLabel = refreshTimeLabel,
			refreshBtnLabel  = refreshBtnLabel,
			selectBtn        = selectBtn,
			hasNumsLabel	 = hasNumsLabel,
			promoterBtn      = promoterBtn,
			listBg 			 = listBg,
			gridView		 = gridView,
			idolImg 		 = idolImg,
			diamondCostLabel = diamondCostLabel,
			-- bg = bg ,
			titleBtn  = titleBtn ,
			-- moneyView = moneyView,
			-- amountLabel= amountLabel,
		}
	end

end

function CommonShopView:ctor( param )
	local data = param or {}
	print("CommonShopView:ctor ==   ")
	-- dump(data)
	self.viewData = CreateView(data)
	self:addChild(self.viewData.view, 1)
	self.viewData.view:setPosition(cc.p(0, 0))
end

--[[
layoutData = {
	shopData       --商品数据
	isShowTopUI,   --是否显示顶部信息
	isUseGridView, --是否使用滑动层
	showTopUiType，--顶部信息显示不同需求组合
}
]]--

function CommonShopView:InitShowUiAndTopUi(layoutData)
	-- dump(showTopUiType)
	local refreshLabel     = self.viewData.refreshLabel
	local refreshBtn  	   = self.viewData.refreshBtn
	local refreshTimeLabel = self.viewData.refreshTimeLabel
	local selectBtn        = self.viewData.selectBtn
	local hasNumsLabel     = self.viewData.hasNumsLabel
	local diamondCostLabel = self.viewData.diamondCostLabel
	local refreshBtnLabel  = self.viewData.refreshBtnLabel
	local promoterBtn      = self.viewData.promoterBtn
	local listBg 		   = self.viewData.listBg
	local gridView 		   = self.viewData.gridView
	-- local moneyView 	   = self.viewData.moneyView
	-- local amountLabel      = self.viewData.amountLabel
	if  checkint(layoutData.isShowTopUI) == ShopType.DIAMOND_SHOP  then

	else
		refreshLabel:setVisible(false)
		refreshBtn:setVisible(false)
		refreshTimeLabel:setVisible(false)
		selectBtn:setVisible(false)
		hasNumsLabel:setVisible(false)
		-- moneyView:setVisible(false)
	end

	if layoutData.isShowTopUI then
		if layoutData.showTopUiType == 1 then
			hasNumsLabel:setVisible(true)
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
			hasNumsLabel:setVisible(true)
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
	--local refreshTimeLabelSize = display.getLabelContentSize(refreshTimeLabel)
	--local refreshLabelSize =  display.getLabelContentSize(refreshLabel)
	--local countWidth = refreshLabelSize.width + refreshTimeLabelSize.width
	--if countWidth > 390 then
    --
	--	local shoulderScale = 390 / countWidth
	--	local currentScale = refreshTimeLabel:getScale()
	--	refreshLabel:setScale(shoulderScale* currentScale)
	--	refreshTimeLabel:setScale(shoulderScale* currentScale)
	--	refreshLabel:setPosition(cc.p(20, 542))
	--	refreshTimeLabel:setPosition(cc.p(refreshLabelSize.width * shoulderScale + 30 , 542  ))
    --
	--end
end

function CommonShopView:onCleanup()
    display.removeUnusedSpriteFrames()
end

return CommonShopView

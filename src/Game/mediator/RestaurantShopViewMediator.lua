local Mediator = mvc.Mediator

local RestaurantShopViewMediator = class("RestaurantShopViewMediator", Mediator)


local NAME = "RestaurantShopViewMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local CommonShopCell = require('Game.views.CommonShopCell')

function RestaurantShopViewMediator:ctor(params, viewComponent )
	self.super:ctor(NAME,viewComponent)
	self.str = ''
	self.clickShopType = nil
	self.showTopUiType = 1
	self.shopData = {}
	if params then
		if params.type then
			self.showTopUiType = params.type
		end
		if params.data then
			self.shopData = params.data
		end
	end
	dump(self.shopData)
end

function RestaurantShopViewMediator:InterestSignals()
	local signals = {
		SIGNALNAMES.Restaurant_Shop_Home_Callback,
		SIGNALNAMES.Restaurant_Shop_Buy_Callback,
		SIGNALNAMES.Restaurant_Shop_Refresh_Callback,
	}

	return signals
end

function RestaurantShopViewMediator:ProcessSignal(signal )
	local name = signal:GetName() 
	print(name)
	-- local body = signal:GetBody()
	-- if name == SIGNALNAMES.Restaurant_Shop_Home_Callback then
	-- 	self.shopData = {}
	-- 	self.shopData = body
	-- elseif name == SIGNALNAMES.Restaurant_Shop_Buy_Callback then
	-- 	uiMgr:AddDialog('common.RewardPopup', {rewards = body.rewards})
	-- 	local data = {}
	-- 	for i,v in ipairs(self.shopData.products) do
	-- 		if checkint(v.productId) == checkint(body.requestData.productId) then
	-- 			v.purchased = 1
	-- 			data = clone(v)
	-- 			break
	-- 		end
	-- 	end
	-- 	local Trewards = {}
	-- 	if next(data) ~= nil then
	-- 		if checkint(data.currency) == checkint(GOLD_ID) then
	-- 			local goldNum = -data.price
	-- 			table.insert(Trewards,{goodsId = GOLD_ID, num = goldNum})
	-- 		elseif checkint(data.currency) == checkint(DIAMOND_ID) then
	-- 			local diamondNum = -data.price 
	-- 			table.insert(Trewards,{goodsId = DIAMOND_ID, num = diamondNum})
	-- 		elseif checkint(data.currency) == checkint(TIPPING_ID) then
	-- 			local tipNum = -data.price 
	-- 			table.insert(Trewards,{goodsId = TIPPING_ID, num = tipNum})
	-- 		end
	-- 	end
	-- 	dump(Trewards)
	-- 	CommonUtils.DrawRewards(Trewards)

	-- 	local scene = uiMgr:GetCurrentScene() 
	-- 	if scene:GetDialogByTag( 5001 ) then
	-- 		scene:GetDialogByTag( 5001 ):runAction(cc.RemoveSelf:create())--购买详情弹出框
	-- 	end
	-- elseif name == SIGNALNAMES.Restaurant_Shop_Refresh_Callback then
	-- 	if body.products then
	-- 		self.shopData.products = {}
	-- 		self.shopData.products = body.products
	-- 	end
	-- 	if body.diamond then
	-- 		local Trewards = {}
	-- 		local diamondNum = body.diamond - gameMgr:GetUserInfo().diamond
	-- 		table.insert(Trewards,{goodsId = DIAMOND_ID, num = diamondNum})
	-- 		CommonUtils.DrawRewards(Trewards)
	-- 	end
	-- end
	-- self:UpDataUI()
end


function RestaurantShopViewMediator:Initial( key )
	self.super.Initial(self,key)

	local viewComponent  = require( 'Game.views.CommonShopView' ).new()
	self:SetViewComponent(viewComponent)
	local data = {
		shopData = self.shopData,   --商品数据
		isShowTopUI = true,         --是否显示顶部信息
		isUseGridView = true,       --是否使用滑动层
		showTopUiType = 5,	       --顶部信息显示不同需求组合
	}
	viewComponent:InitShowUiAndTopUi(data)


	self.viewData = nil
	self.viewData = viewComponent.viewData

	-- self:InitTopUI()

	local gridView = self.viewData.gridView

    gridView:setDataSourceAdapterScriptHandler(handler(self,self.OnDataSourceAction))

    gridView:setCountOfCell(table.nums(self.shopData))
    gridView:reloadData()


end

function RestaurantShopViewMediator:UpDataUI()
	-- dump(self.shopData.products)
	self:InitTopUI()
    self.viewData.gridView:setCountOfCell(table.nums(self.shopData))
    self.viewData.gridView:reloadData()
end


function RestaurantShopViewMediator:InitTopUI()
	local refreshLabel     = self.viewData.refreshLabel
	local refreshBtn  	   = self.viewData.refreshBtn
	local refreshTimeLabel = self.viewData.refreshTimeLabel
	local selectBtn        = self.viewData.selectBtn
	local hasNumsLabel     = self.viewData.hasNumsLabel
	local diamondCostLabel = self.viewData.diamondCostLabel
	local refreshBtnLabel = self.viewData.refreshBtnLabel
	
	
	refreshLabel:setVisible(false)
	refreshBtn:setVisible(false)	  
	refreshTimeLabel:setVisible(false)
	selectBtn:setVisible(false)       
	hasNumsLabel:setVisible(false) 

	-- if self.showTopUiType == 1 then
	-- 	hasNumsLabel:setVisible(true)
	-- 	refreshLabel:setVisible(true)
	-- 	refreshBtn:setVisible(true)	  
	-- 	refreshTimeLabel:setVisible(true)
	-- 	display.reloadRichLabel(diamondCostLabel, {c = {
	-- 		{text = self.shopData.refreshDiamond, fontSize = 20, color = '#5b3c25'},
	-- 		{img = _res('arts/goods/goods_icon_' .. DIAMOND_ID .. '.png'), scale = 0.15}
	-- 	}})

	-- 	refreshBtn:setOnClickScriptHandler(handler(self,self.RefreshButtonAction))
	-- 	refreshBtnLabel:setString(string.fmt(__('今日刷新次数：_num_'),{_num_ = self.shopData.refreshLeftTimes}))
	-- elseif self.showTopUiType == 2 then
	-- 	hasNumsLabel:setVisible(true)
	-- elseif self.showTopUiType == 3 then
	-- 	selectBtn:setVisible(true)
	-- elseif self.showTopUiType == 4 then
	-- 	selectBtn:setVisible(true)
	-- 	refreshLabel:setVisible(true)
	-- 	refreshBtn:setVisible(true)	  
	-- 	refreshTimeLabel:setVisible(true)
	-- 	display.reloadRichLabel(diamondCostLabel, {c = {
	-- 		{text = self.shopData.refreshDiamond, fontSize = 20, color = '#5b3c25'},
	-- 		{img = _res('arts/goods/goods_icon_' .. DIAMOND_ID .. '.png'), scale = 0.15}
	-- 	}})

	-- 	refreshBtn:setOnClickScriptHandler(handler(self,self.RefreshButtonAction))
	-- 	refreshBtnLabel:setString(string.fmt(__('今日刷新次数：_num_'),{_num_ = self.shopData.refreshLeftTimes}))
		
	-- elseif self.showTopUiType == 5 then
	-- 	refreshLabel:setVisible(true)
	-- 	refreshBtn:setVisible(true)	  
	-- 	refreshTimeLabel:setVisible(true)
	-- 	display.reloadRichLabel(diamondCostLabel, {c = {
	-- 		{text = self.shopData.refreshDiamond, fontSize = 20, color = '#5b3c25'},
	-- 		{img = _res('arts/goods/goods_icon_' .. DIAMOND_ID .. '.png'), scale = 0.15}
	-- 	}})

	-- 	refreshBtn:setOnClickScriptHandler(handler(self,self.RefreshButtonAction))
	-- 	refreshBtnLabel:setString(string.fmt(__('今日刷新次数：_num_'),{_num_ = self.shopData.refreshLeftTimes}))
	-- end
end


function RestaurantShopViewMediator:OnDataSourceAction(p_convertview,idx)
    local pCell = p_convertview
    local pButton = nil
    local index = idx + 1
    local sizee = cc.size(202 , 200)
    local tempData = self.shopData[index]
   	if pCell == nil then
        pCell = CommonShopCell.new(sizee)
        pCell.toggleView:setOnClickScriptHandler(handler(self,self.CellButtonAction))

    else

    end
	xTry(function()
		pCell.goodNode:setTouchEnabled(false)
		pCell.goodNode:RefreshSelf({goodsId = tempData.goodsId,amount = tempData.goodsNum})
		pCell.toggleView:setTag(index)
		pCell:setTag(index)

		pCell.numLabel:setString(tempData.price)
		pCell.castIcon:setTexture(_res(CommonUtils.GetGoodsIconPathById(tempData.currency)))
		pCell.castIcon:setPositionX(pCell.numLabel:getPositionX()+pCell.numLabel:getBoundingBox().width*0.5 + 4)
		if tempData.purchased == 0 then
			pCell.sellLabel:setVisible(false)
			pCell.toggleView:setNormalImage(_res('ui/home/commonShop/shop_btn_goods_default.png'))
			pCell.toggleView:setSelectedImage(_res('ui/home/commonShop/shop_btn_goods_default.png'))
		else
			pCell.sellLabel:setVisible(true)
			pCell.toggleView:setNormalImage(_res('ui/home/commonShop/shop_btn_goods_sellout.png'))
			pCell.toggleView:setSelectedImage(_res('ui/home/commonShop/shop_btn_goods_sellout.png'))
		end

	end,__G__TRACKBACK__)
    return pCell

end

function RestaurantShopViewMediator:CellButtonAction(sender)
	local tag = sender:getTag()
	dump(tag)
	local data = self.shopData[tag]
	if data.purchased == 0 then
		local scene = uiMgr:GetCurrentScene() 
		local marketPurchasePopup  = require('Game.views.MarketPurchasePopup').new({tag = 5001, mediatorName = "RestaurantShopViewMediator", data = data, btnTag = tag})
		display.commonUIParams(marketPurchasePopup, {ap = cc.p(0.5, 0.5), po = cc.p(display.width * 0.5, display.height * 0.5)})
		marketPurchasePopup:setTag(5001)
		scene:AddDialog(marketPurchasePopup)
		marketPurchasePopup.viewData.purchaseBtn:setOnClickScriptHandler(handler(self, self.PurchaseBtnCallback))
		marketPurchasePopup.viewData.purchaseBtn:setTag(tag)
	end
	
end

function RestaurantShopViewMediator:PurchaseBtnCallback( sender )
	local tag = sender:getTag()
	local data = self.shopData[tag]
	local money = 0
	local des = __('货币')
	if checkint(data.currency) == GOLD_ID then --金币
		des = __('金币')
		money = gameMgr:GetUserInfo().gold
	elseif checkint(data.currency) == DIAMOND_ID then -- 幻晶石
		des = __('幻晶石')
		money = gameMgr:GetUserInfo().diamond
	elseif checkint(data.currency) == TIPPING_ID then -- 小费
		des = __('小费')
		money = gameMgr:GetUserInfo().tip
	end
 	if checkint(money) >= checkint(data.price) then
 		self:SendSignal(COMMANDS.COMMANDS_Restaurant_Shop_Buy,{productId = data.productId})

		-- self:GetFacade():DispatchObservers(SureBuyItem_Callback,data.productId)
	else
		if GAME_MODULE_OPEN.NEW_STORE and checkint(data.currency) == DIAMOND_ID then
			app.uiMgr:showDiamonTips()
		else
			uiMgr:ShowInformationTips(string.fmt(__('_des_不足'),{_des_ = des}))
		end
	end
end

function RestaurantShopViewMediator:OnRegist(  )
	self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "show")
	-- local ShopCommand = require( 'Game.command.ShopCommand')
	-- self:GetFacade():RegistSignal(COMMANDS.COMMANDS_Restaurant_Shop_Home, ShopCommand)
	-- self:GetFacade():RegistSignal(COMMANDS.COMMANDS_Restaurant_Shop_Buy, ShopCommand)
	-- self:GetFacade():RegistSignal(COMMANDS.COMMANDS_Restaurant_Shop_Refresh, ShopCommand)

end

function RestaurantShopViewMediator:OnUnRegist(  )
	--称出命令
	self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "hide")
	local scene = uiMgr:GetCurrentScene()
	scene:RemoveDialog(self.viewComponent)

	-- self:GetFacade():UnRegsitSignal(COMMANDS.COMMANDS_Restaurant_Shop_Home)
	-- self:GetFacade():UnRegsitSignal(COMMANDS.COMMANDS_Restaurant_Shop_Buy)
	-- self:GetFacade():UnRegsitSignal(COMMANDS.COMMANDS_Restaurant_Shop_Refresh)

end

return RestaurantShopViewMediator

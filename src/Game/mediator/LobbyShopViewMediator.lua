local Mediator = mvc.Mediator

local LobbyShopViewMediator = class("LobbyShopViewMediator", Mediator)


local NAME = "LobbyShopViewMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local CommonShopCell = require('Game.views.CommonShopCell')

function LobbyShopViewMediator:ctor(params, viewComponent )
	self.super:ctor(NAME,viewComponent)
	self.str = ''
	self.clickShopType = nil
	self.showTopUiType = 4
	self.shopData = {}
	self.preTime = nil
	if params then
		if params.type then
			self.showTopUiType = params.type
		end
		if params.data then
			self.shopData = params.data
		end
	end
	-- dump(self.shopData)
end

function LobbyShopViewMediator:InterestSignals()
	local signals = {
		SIGNALNAMES.Restaurant_Shop_Home_Callback,
		SIGNALNAMES.All_Shop_Buy_Callback,
		SIGNALNAMES.Restaurant_Shop_Refresh_Callback,
	}

	return signals
end

function LobbyShopViewMediator:ProcessSignal(signal )
	local name = signal:GetName()
	print(name)
	local body = signal:GetBody()
	if name == SIGNALNAMES.Restaurant_Shop_Home_Callback then
		-- dump(body.restaurant)
		self.shopData = {}
		self.shopData = body.restaurant
	elseif name == SIGNALNAMES.All_Shop_Buy_Callback then
		if signal:GetBody().requestData.name ~= 'LobbyShopView' then return end
		uiMgr:AddDialog('common.RewardPopup', {rewards = body.rewards})
		local data = {}
		for i,v in ipairs(self.shopData.products) do
			if checkint(v.productId) == checkint(body.requestData.productId) then
				v.purchased = 1
				data = clone(v)
				break
			end
		end
		local Trewards = {}
		if next(data) ~= nil then
			if checkint(data.currency) == checkint(GOLD_ID) then
				local goldNum = -data.price * checkint(body.requestData.num or 1)
				table.insert(Trewards,{goodsId = GOLD_ID, num = goldNum})
			elseif checkint(data.currency) == checkint(DIAMOND_ID) then
				local diamondNum = -data.price * checkint(body.requestData.num or 1)
				table.insert(Trewards,{goodsId = DIAMOND_ID, num = diamondNum})
			elseif checkint(data.currency) == checkint(TIPPING_ID) then
				local tipNum = -data.price * checkint(body.requestData.num or 1)
				table.insert(Trewards,{goodsId = TIPPING_ID, num = tipNum})
			end
		end
		-- dump(Trewards)
		CommonUtils.DrawRewards(Trewards)

		local scene = uiMgr:GetCurrentScene()
		if scene:GetDialogByTag( 5001 ) then
			scene:GetDialogByTag( 5001 ):runAction(cc.RemoveSelf:create())--?????????????????????
		end
	elseif name == SIGNALNAMES.Restaurant_Shop_Refresh_Callback then
		if body.products then
			self.shopData.products = {}
			self.shopData.products = body.products
		end
		if body.diamond then
			local Trewards = {}
			local diamondNum = body.diamond - gameMgr:GetUserInfo().diamond
			table.insert(Trewards,{goodsId = DIAMOND_ID, num = diamondNum})
			CommonUtils.DrawRewards(Trewards)
		end
	end
	self:UpDataUI()
end


function LobbyShopViewMediator:Initial( key )
	self.super.Initial(self,key)

	local viewComponent  = require( 'Game.views.CommonShopView' ).new()
	self:SetViewComponent(viewComponent)

	local data = {
		shopData = self.shopData,   --????????????
		isShowTopUI = true,         --????????????????????????
		isUseGridView = true,       --?????????????????????
		showTopUiType = 4,	       	--????????????????????????????????????
	}
	viewComponent:InitShowUiAndTopUi(data)

	self.viewData = nil
	self.viewData = viewComponent.viewData

	-- self:InitTopUI()

	self.viewData.refreshBtn:setOnClickScriptHandler(handler(self,self.RefreshButtonAction))

	local gridView = self.viewData.gridView

    gridView:setDataSourceAdapterScriptHandler(handler(self,self.OnDataSourceAction))
    if self.shopData.products then
	    gridView:setCountOfCell(table.nums(self.shopData.products or 0))
	    gridView:reloadData()
	end
	if self.shopData.nextRefreshLeftSeconds and self.shopData.nextRefreshLeftSeconds > 0 then
		self.shopData.nextRefreshLeftSeconds =  self.shopData.nextRefreshLeftSeconds + 3
	end

	self.scheduler = nil
	self.preTime = os.time()
    self.scheduler = scheduler.scheduleGlobal(handler(self, self.scheduleCallback), 1)

end

function LobbyShopViewMediator:UpDataUI()
	-- dump(self.shopData.products)
	if self.isRefresh == true then
		self.isRefresh = false
		self.shopData.refreshLeftTimes = self.shopData.refreshLeftTimes - 1
	end
	self:InitTopUI()
    self.viewData.gridView:setCountOfCell(table.nums(self.shopData.products))
    self.viewData.gridView:reloadData()
	if self.scheduler then
		scheduler.unscheduleGlobal(self.scheduler)
	end
	self.preTime = os.time()
    self.scheduler = scheduler.scheduleGlobal(handler(self, self.scheduleCallback), 1)
end

--[[
???????????????
--]]
function LobbyShopViewMediator:scheduleCallback()
	if self.shopData.nextRefreshLeftSeconds and self.shopData.nextRefreshLeftSeconds >= 0 then
		local curTime = os.time()
		self.shopData.nextRefreshLeftSeconds = self.shopData.nextRefreshLeftSeconds - (curTime - checkint(self.preTime))
		self.preTime = curTime

		local viewData = self:GetViewComponent().viewData
		if self.shopData.nextRefreshLeftSeconds > 0 then
			viewData.refreshTimeLabel:setString(string.formattedTime(checkint(self.shopData.nextRefreshLeftSeconds),'%02i:%02i:%02i'))
		else
			viewData.refreshTimeLabel:setString(__('?????????'))
		end
	end

	if self.shopData.nextRefreshLeftSeconds and self.shopData.nextRefreshLeftSeconds < 0 then
		self:SendSignal(COMMANDS.COMMANDS_Restaurant_Shop_Home)
		-- self:GetFacade():DispatchObservers(CastMoneyInitUI_Callback)
		self.preTime = nil
		scheduler.unscheduleGlobal(self.scheduler)
	end
end

function LobbyShopViewMediator:InitTopUI()
	local refreshLabel     = self.viewData.refreshLabel
	local refreshBtn  	   = self.viewData.refreshBtn
	local refreshTimeLabel = self.viewData.refreshTimeLabel
	local selectBtn        = self.viewData.selectBtn
	local hasNumsLabel     = self.viewData.hasNumsLabel
	local diamondCostLabel = self.viewData.diamondCostLabel
	local refreshBtnLabel = self.viewData.refreshBtnLabel
	-- local moneyView 	   = self.viewData.moneyView
	-- local amountLabel      = self.viewData.amountLabel


	selectBtn:setVisible(false)
	hasNumsLabel:setVisible(false)
	-- moneyView:setVisible(true)
	refreshLabel:setVisible(true)
	refreshBtn:setVisible(true)
	refreshTimeLabel:setVisible(true)
	display.reloadRichLabel(diamondCostLabel, {c = {
		{text = self.shopData.refreshDiamond, fontSize = 20, color = '#5b3c25'},
		{img = _res('arts/goods/goods_icon_' .. DIAMOND_ID .. '.png'), scale = 0.15}
	}})

	refreshBtn:setOnClickScriptHandler(handler(self,self.RefreshButtonAction))
	refreshBtnLabel:setString(string.fmt(__('??????????????????:_num_'),{_num_ = self.shopData.refreshLeftTimes}))
	-- amountLabel:setString(gameMgr:GetUserInfo().tip)

end

function LobbyShopViewMediator:RefreshButtonAction(sender)
    if self.shopData.refreshLeftTimes > 0 then
    	self.isRefresh = true
		-- self:GetFacade():DispatchObservers(CastMoneyRefreshUI_Callback)
		local CommonTip  = require( 'common.NewCommonTip' ).new({text = string.format(__('????????????%s???????????????????????????????'), self.shopData.refreshDiamond),
            isOnlyOK = false, callback = function ()
				self:SendSignal(COMMANDS.COMMANDS_Restaurant_Shop_Refresh)
			end})
		CommonTip:setPosition(display.center)
		local scene = uiMgr:GetCurrentScene()
		scene:AddDialog(CommonTip)
    	
    else
    	uiMgr:ShowInformationTips(__('?????????????????????'))
	end
end


function LobbyShopViewMediator:OnDataSourceAction(p_convertview,idx)
    local pCell = p_convertview
    local pButton = nil
    local index = idx + 1
    local sizee = cc.size(202 , 278)
    local tempData = self.shopData.products[index]
   	if pCell == nil then
        pCell = CommonShopCell.new(sizee)
        pCell.toggleView:setOnClickScriptHandler(handler(self,self.CellButtonAction))
		pCell.goodNode:setPositionY(130)
    else

    end
	xTry(function()
		pCell.goodNode:setTouchEnabled(false)
		pCell.goodNode:RefreshSelf({goodsId = tempData.goodsId,amount = tempData.goodsNum})
		pCell.toggleView:setTag(index)
		pCell:setTag(index)
		pCell.leftTimesLabel:setTag(index)
		pCell.numLabel:setString(tostring(tempData.price))
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

		if tempData.leftPurchasedNum then
			pCell.leftTimesLabel:setVisible(true)
	        display.reloadRichLabel(pCell.leftTimesLabel, { c = {fontWithColor('8', { color = "ae8668" ,fontSize = 20 , text = __('??????????????????')}) ,
	        	fontWithColor('8', { color = "ac5a4a" ,fontSize = 20 , text = tostring(tempData.leftPurchasedNum)}),
	        	fontWithColor('8', { color = "ae8668" ,fontSize = 20 , text = __('??????')}) }})
	        pCell.leftTimesLabel:setOnTextRichClickScriptHandler(handler(self,self.CellButtonAction))
	    else
	    	pCell.leftTimesLabel:setVisible(false)
    	end
	end,__G__TRACKBACK__)
    return pCell

end

function LobbyShopViewMediator:CellButtonAction(sender)
	local tag = sender:getTag()
	-- dump(tag)
	local data = self.shopData.products[tag]
	-- ?????? ??????ID??? ??????id??????  ???????????????????????????
	if CommonUtils.CheckIsOwnSkinById(data.goodsId) then
		uiMgr:ShowInformationTips('??????????????????')
		return
	end
	if data.purchased == 0 then
		local scene = uiMgr:GetCurrentScene()  --MarketPurchasePopup
		local marketPurchasePopup  = require('Game.views.ShopPurchasePopup').new({tag = 5001, mediatorName = "LobbyShopViewMediator", data = data, btnTag = tag})
		display.commonUIParams(marketPurchasePopup, {ap = cc.p(0.5, 0.5), po = cc.p(display.width * 0.5, display.height * 0.5)})
		marketPurchasePopup:setTag(5001)
		scene:AddDialog(marketPurchasePopup)
		marketPurchasePopup.viewData.purchaseBtn:setOnClickScriptHandler(handler(self, self.PurchaseBtnCallback))
		marketPurchasePopup.viewData.purchaseBtn:setTag(tag)
	end

end

function LobbyShopViewMediator:PurchaseBtnCallback( sender )
	local tag = sender:getTag()
	local data = self.shopData.products[tag]
	local num = sender:getUserTag()
	-- dump(num)
	local money = 0
	local des = __('??????')
	if checkint(data.currency) == GOLD_ID then --??????
		des = __('??????')
		money = gameMgr:GetUserInfo().gold
	elseif checkint(data.currency) == DIAMOND_ID then -- ?????????
		des = __('?????????')
		money = gameMgr:GetUserInfo().diamond
	elseif checkint(data.currency) == TIPPING_ID then -- ??????
		des = __('??????')
		money = gameMgr:GetUserInfo().tip
	end
 	if checkint(money) >= checkint(data.price)*num then
 		self:SendSignal(COMMANDS.COMMANDS_All_Shop_Buy,{productId = data.productId,num = num,name = 'LobbyShopView'})

		-- self:GetFacade():DispatchObservers(SureBuyItem_Callback,data.productId)
	else
		if GAME_MODULE_OPEN.NEW_STORE and checkint(data.currency) == DIAMOND_ID then
			app.uiMgr:showDiamonTips()
		else
			uiMgr:ShowInformationTips(string.fmt(__('_des_??????'),{_des_ = des}))
		end
	end
end

function LobbyShopViewMediator:OnRegist(  )
	-- self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "show")
	local ShopCommand = require( 'Game.command.ShopCommand')
	self:GetFacade():RegistSignal(COMMANDS.COMMANDS_Restaurant_Shop_Home, ShopCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMANDS_All_Shop_Buy, ShopCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMANDS_Restaurant_Shop_Refresh, ShopCommand)
end

function LobbyShopViewMediator:OnUnRegist(  )
	--????????????
	if self.scheduler then
		scheduler.unscheduleGlobal(self.scheduler)
		self.scheduler = nil
	end

	-- self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "hide")
	-- local scene = uiMgr:GetCurrentScene()
	-- scene:RemoveDialog(self.viewComponent)

	self:GetFacade():UnRegsitSignal(COMMANDS.COMMANDS_Restaurant_Shop_Home)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMANDS_All_Shop_Buy)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMANDS_Restaurant_Shop_Refresh)

end

return LobbyShopViewMediator

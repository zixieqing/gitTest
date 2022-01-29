local Mediator = mvc.Mediator

local KOFShopViewMediator = class("KOFShopViewMediator", Mediator)

local NAME = "KOFShopViewMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local CommonShopCell = require('Game.views.CommonShopCell')

function KOFShopViewMediator:ctor(params, viewComponent )
	self.super:ctor(NAME,viewComponent)

	if params then
		if params.type then
			self.showTopUiType = params.type
		end
		if params.data then
			self.shopData = params.data
		end
	end
end

function KOFShopViewMediator:InterestSignals()
	local signals = {
		SIGNALNAMES.Restaurant_Shop_Home_Callback,
		SIGNALNAMES.All_Shop_Buy_Callback,
		SIGNALNAMES.KOF_Shop_Refresh_Callback,
	}

	return signals
end

function KOFShopViewMediator:ProcessSignal(signal )
	local name = signal:GetName()
	local body = signal:GetBody()
	if name == SIGNALNAMES.Restaurant_Shop_Home_Callback then
		self.shopData = {}
		self.shopData = body.kofArena
	elseif name == SIGNALNAMES.All_Shop_Buy_Callback then
		if signal:GetBody().requestData.name ~= 'KOFShopView' then return end
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
			elseif checkint(data.currency) == checkint(KOF_CURRENCY_ID) then
				local tipNum = -data.price * checkint(body.requestData.num or 1)
				table.insert(Trewards,{goodsId = KOF_CURRENCY_ID, num = tipNum})
			end
		end
		-- dump(Trewards)
		CommonUtils.DrawRewards(Trewards)

		local scene = uiMgr:GetCurrentScene()
		if scene:GetDialogByTag( 5001 ) then
			scene:GetDialogByTag( 5001 ):runAction(cc.RemoveSelf:create())--购买详情弹出框
		end
	elseif name == SIGNALNAMES.KOF_Shop_Refresh_Callback then
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

function KOFShopViewMediator:Initial( key )
	self.super.Initial(self,key)

	local viewComponent  = require( 'Game.views.CommonShopView' ).new()
	self:SetViewComponent(viewComponent)

	local data = {
		shopData = self.shopData,   --商品数据
		isShowTopUI = true,         --是否显示顶部信息
		isUseGridView = true,       --是否使用滑动层
		showTopUiType = 4,	       	--顶部信息显示不同需求组合
	}
	viewComponent:InitShowUiAndTopUi(data)

	self.viewData = nil
	self.viewData = viewComponent.viewData

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

function KOFShopViewMediator:UpDataUI()
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
定时器回调
--]]
function KOFShopViewMediator:scheduleCallback()
	if self.shopData.nextRefreshLeftSeconds and self.shopData.nextRefreshLeftSeconds >= 0 then
		local curTime = os.time()
		self.shopData.nextRefreshLeftSeconds = self.shopData.nextRefreshLeftSeconds - (curTime - checkint(self.preTime))
		self.preTime = curTime

		local viewData = self:GetViewComponent().viewData
		if self.shopData.nextRefreshLeftSeconds > 0 then
			viewData.refreshTimeLabel:setString(string.formattedTime(checkint(self.shopData.nextRefreshLeftSeconds),'%02i:%02i:%02i'))
		else
			viewData.refreshTimeLabel:setString(__('已结束'))
		end
	end

	if self.shopData.nextRefreshLeftSeconds and self.shopData.nextRefreshLeftSeconds < 0 then
		self:SendSignal(COMMANDS.COMMANDS_Restaurant_Shop_Home)
		-- self:GetFacade():DispatchObservers(CastMoneyInitUI_Callback)
		self.preTime = nil
		scheduler.unscheduleGlobal(self.scheduler)
	end
end

function KOFShopViewMediator:InitTopUI()
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
	refreshBtnLabel:setString(string.fmt(__('今日刷新次数:_num_'),{_num_ = self.shopData.refreshLeftTimes}))
	-- amountLabel:setString(gameMgr:GetUserInfo().tip)

end

function KOFShopViewMediator:RefreshButtonAction(sender)
    if self.shopData.refreshLeftTimes > 0 then
    	self.isRefresh = true
		-- self:GetFacade():DispatchObservers(CastMoneyRefreshUI_Callback)
		local CommonTip  = require( 'common.NewCommonTip' ).new({text = string.format(__('是否使用%s个幻晶石进行商店刷新?'), self.shopData.refreshDiamond),
            isOnlyOK = false, callback = function ()
				self:SendSignal(COMMANDS.COMMANDS_KOF_Shop_Refresh)
			end})
		CommonTip:setPosition(display.center)
		local scene = uiMgr:GetCurrentScene()
		scene:AddDialog(CommonTip)
    else
    	uiMgr:ShowInformationTips(__('刷新次数已用完'))
	end
end


function KOFShopViewMediator:OnDataSourceAction(p_convertview,idx)
    local pCell = p_convertview
    local pButton = nil
    local index = idx + 1
    local sizee = cc.size(202 , 252)
    local tempData = self.shopData.products[index]
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
	        display.reloadRichLabel(pCell.leftTimesLabel, { c = {fontWithColor('8', { color = "ae8668" ,fontSize = 20 , text = __('今日剩余购买')}) ,
	        	fontWithColor('8', { color = "ac5a4a" ,fontSize = 20 , text = tostring(tempData.leftPurchasedNum)}),
	        	fontWithColor('8', { color = "ae8668" ,fontSize = 20 , text = __('次数')}) }})
	        pCell.leftTimesLabel:setOnTextRichClickScriptHandler(handler(self,self.CellButtonAction))
	    else
	    	pCell.leftTimesLabel:setVisible(false)
    	end
	end,__G__TRACKBACK__)
    return pCell

end

function KOFShopViewMediator:CellButtonAction(sender)
	local tag = sender:getTag()
	-- dump(tag)
	local data = self.shopData.products[tag]
	-- 如果 道具ID为 皮肤id的话  检查是否拥有该皮肤
	if CommonUtils.CheckIsOwnSkinById(data.goodsId) then 
		uiMgr:ShowInformationTips(__('已拥有该皮肤')) 
		return 
	end
	if data.purchased == 0 then
		local scene = uiMgr:GetCurrentScene()  --MarketPurchasePopup
		local marketPurchasePopup  = require('Game.views.ShopPurchasePopup').new({tag = 5001, mediatorName = "KOFShopViewMediator", data = data, btnTag = tag})
		display.commonUIParams(marketPurchasePopup, {ap = cc.p(0.5, 0.5), po = cc.p(display.width * 0.5, display.height * 0.5)})
		marketPurchasePopup:setTag(5001)
		scene:AddDialog(marketPurchasePopup)
		marketPurchasePopup.viewData.purchaseBtn:setOnClickScriptHandler(handler(self, self.PurchaseBtnCallback))
		marketPurchasePopup.viewData.purchaseBtn:setTag(tag)
	end

end

function KOFShopViewMediator:PurchaseBtnCallback( sender )
	local tag = sender:getTag()
	local data = self.shopData.products[tag]
	local num = sender:getUserTag()
	-- dump(num)
	local money = 0
	local des = __('货币')
	if checkint(data.currency) == GOLD_ID then --金币
		des = __('金币')
		money = gameMgr:GetUserInfo().gold
	elseif checkint(data.currency) == DIAMOND_ID then -- 幻晶石
		des = __('幻晶石')
		money = gameMgr:GetUserInfo().diamond
	elseif checkint(data.currency) == KOF_CURRENCY_ID then -- 通宝
		des = __('通宝')
		money = gameMgr:GetAmountByGoodId(KOF_CURRENCY_ID)
	end
 	if checkint(money) >= checkint(data.price) then
 		self:SendSignal(COMMANDS.COMMANDS_All_Shop_Buy,{productId = data.productId,num = num,name = 'KOFShopView'})

		-- self:GetFacade():DispatchObservers(SureBuyItem_Callback,data.productId)
	else
		if GAME_MODULE_OPEN.NEW_STORE and checkint(data.currency) == DIAMOND_ID then
			app.uiMgr:showDiamonTips()
		else
			uiMgr:ShowInformationTips(string.fmt(__('_des_不足'),{_des_ = des}))
		end
	end
end

function KOFShopViewMediator:OnRegist(  )
	local ShopCommand = require( 'Game.command.ShopCommand')
	self:GetFacade():RegistSignal(COMMANDS.COMMANDS_Restaurant_Shop_Home, ShopCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMANDS_All_Shop_Buy, ShopCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMANDS_KOF_Shop_Refresh, ShopCommand)
end

function KOFShopViewMediator:OnUnRegist(  )
	if self.scheduler then
		scheduler.unscheduleGlobal(self.scheduler)
		self.scheduler = nil
	end
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMANDS_Restaurant_Shop_Home)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMANDS_All_Shop_Buy)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMANDS_KOF_Shop_Refresh)
end

return KOFShopViewMediator

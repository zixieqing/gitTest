local Mediator = mvc.Mediator

local NAME = "ShopMediator"
---@class ShopMediator
local ShopMediator = class(NAME, Mediator)

SureBuyItem_Callback = 'SureBuyItem_Callback'
CastMoneyRefreshUI_Callback = 'CastMoneyRefreshUI_Callback'
CastMoneyInitUI_Callback = 'CastMoneyInitUI_Callback'

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
-- ['1'] =
-- ['2'] =
-- ['3'] =
-- ['4'] =
-- ['5'] =
local ShopConfig = {
	{ mediatorName = 'DiamondShopViewMediator' 		,shopName = __('幻晶石商城') ,tag = 1 ,key = 'diamond'			, topCurrencyId = nil},
	{ mediatorName = 'ChestShopViewMediator' 		,shopName = __('礼包商城') ,tag = 2 ,key = 'chest' 				, topCurrencyId = nil},
	{ mediatorName = 'GoodsShopViewMediator' 		,shopName = __('道具商城') ,tag = 3 ,key = 'goods' 				, topCurrencyId = nil},
	{ mediatorName = 'CardSkinShopViewMediator' 	,shopName = __('皮肤商城') ,tag = 4 ,key = 'cardSkin' 			, topCurrencyId = SKIN_COUPON_ID},
	{ mediatorName = 'LobbyShopViewMediator' 		,shopName = __('小费商城') ,tag = 5 ,key = 'restaurant' 		, topCurrencyId = TIPPING_ID, 		switch = MODULE_SWITCH.RESTAURANT},
	{ mediatorName = 'PVCShopViewMediator' 			,shopName = __('勋章商城') ,tag = 6 ,key = 'arena' 				, topCurrencyId = PVC_MEDAL_ID,		switch = MODULE_SWITCH.PVC_ROYAL_BATTLE},
	{ mediatorName = 'KOFShopViewMediator' 			,shopName = __('通宝商店') ,tag = 7 ,key = 'kofArena' 			, topCurrencyId = KOF_CURRENCY_ID,	switch = MODULE_SWITCH.TAG_MATCH},

	-- ['6'] = { mediatorName = 'MemberShopViewMediator' 		,shopName = __('月卡商城') ,tag = 6 ,key = 'member'},
	-- ['7'] = { mediatorName = 'LobbyShopViewMediator'   		,shopName = __('餐厅avatar商城') ,tag = 7 ,key = 'restaurantAvatar'},
}

function ShopMediator:ctor(params, viewComponent )
	self.super:ctor(NAME,viewComponent)
	self.str = ''
	self.clickShopType = 0
	self.shopData = {}
	if params then
		self.shopData = params
		-- 刷新钻石数量
		CommonUtils.RefreshDiamond(self.shopData)
		for i= #self.shopData.member ,1 , -1 do
			self.shopData.member[i].ismember = true
			table.insert(self.shopData.diamond , 1, self.shopData.member[i])
		end
	end
    --请求home接口数据时记录下当前时间
    local shareUserDefault = cc.UserDefault:getInstance()
    shareUserDefault:setIntegerForKey("DIAMOND_KEY_ID", os.time())
    shareUserDefault:flush()
end

function ShopMediator:InterestSignals()
	local signals = {
		-- CastMoneyInitUI_Callback,
		-- SureBuyItem_Callback,
		-- CastMoneyRefreshUI_Callback,
		-- SIGNALNAMES.Restaurant_Shop_Home_Callback,
		-- SIGNALNAMES.Restaurant_Shop_Buy_Callback,
		-- SIGNALNAMES.Restaurant_Shop_Refresh_Callback,
		SIGNALNAMES.CACHE_MONEY_UPDATE_UI,
        "SHOP_HIDDEN_BACK",
	}

	return signals
end

function ShopMediator:ProcessSignal(signal )
	local name = signal:GetName()
	-- print(name)
	if name == SIGNALNAMES.CACHE_MONEY_UPDATE_UI then
        --更新界面显示
        self:UpdateCountUI()
    elseif name == 'SHOP_HIDDEN_BACK' then
        local isShow = checkbool(checktable(signal:GetBody()).isShow)
        self.viewData.backBtn:setVisible(isShow)
    end
end

--更新数量ui值
function ShopMediator:UpdateCountUI()
	local viewData = self.viewData
	if viewData.moneyNods then
		for id,v in pairs(viewData.moneyNods) do
			v:updataUi(checkint(id)) --刷新每一个金币数量
		end
	end
end

function ShopMediator:Initial( key )
	self.super.Initial(self,key)
	local scene = uiMgr:GetCurrentScene()
	local viewComponent  = require( 'Game.views.ShopView' ).new()
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	scene:AddDialog(viewComponent)
	-- self:UpdateCountUI()
	-- scene:AddGameLayer(viewComponent)
	-- backBtn
	viewComponent.viewData.backBtn:setOnClickScriptHandler(function( sender )
		PlayAudioByClickNormal()
		self:GetFacade():UnRegsitMediator(NAME)
	end)
	self.viewData = nil
	self.viewData = viewComponent.viewData

	self.commonLayout = nil
	self.commonLayout = self.viewData.commonLayout

	self.selectMediator = {}

	local gridView = self.viewData.gridView

    gridView:setDataSourceAdapterScriptHandler(handler(self,self.OnDataSourceAction))

    local tempData = {}
	for i=#ShopConfig,1,-1 do
		if ShopConfig[i].switch and not CommonUtils.GetModuleAvailable(ShopConfig[i].switch) then
			table.remove(ShopConfig,i)
		elseif self.shopData[ShopConfig[i].key] then
	    	if next(self.shopData[ShopConfig[i].key]) ~= nil then
	    		-- tempData[k] = ShopConfig[i]
	    		table.insert(tempData,ShopConfig[i])
	    	else
	    		table.remove(ShopConfig,i)
	    	end
	    else
	    	table.remove(ShopConfig,i)
	    end
	end

    gridView:setCountOfCell(table.nums(tempData))
    gridView:reloadData()

    local showIndex = 1
    if self.initLayerData then
	    for i,v in ipairs(ShopConfig) do
	    	if v.key == self.initLayerData.goShopIndex then
	    		showIndex = i
	    		break
	    	end
	    end
    end
    local cell = gridView:cellAtIndex(showIndex-1)
    if cell then
        local sender = cell:getChildByTag(2345)
        sender:setNormalImage(_res('ui/home/commonShop/shop_btn_tab_select.png'))
        sender:setSelectedImage(_res('ui/home/commonShop/shop_btn_tab_select.png'))
        self:cellCallBackActions(cell:getTag())
    end

    self:UpdateCountUI()
end

function ShopMediator:OnDataSourceAction(p_convertview,idx)
    local pCell = p_convertview
    local pButton = nil
    local index = idx + 1
    local sizee = cc.size(140, 92)

    if pCell == nil then
   		pCell = CGridViewCell:new()
   		pButton = display.newButton( sizee.width*0.5, sizee.height*0.5 ,{n = _res('ui/home/commonShop/shop_btn_tab_default.png'),s = _res('ui/home/commonShop/shop_btn_tab_select.png'),ap = cc.p(0.5, 0.5)})
        display.commonLabelParams(pButton, {ttf = true, font = TTF_GAME_FONT, hAlign =display.TAC , w = 130 , text = ShopConfig[index].shopName or '商城', fontSize = 24, color = 'ffffff'})
		if display.getLabelContentSize(pButton:getLabel()).height > 80 then
			display.commonLabelParams(pButton, {ttf = true, font = TTF_GAME_FONT, hAlign =display.TAC , w = 140, text = ShopConfig[index].shopName or '商城', fontSize = 24, color = 'ffffff'})
		end
        pCell:addChild(pButton,5)
        pButton:setTag(2345)
        pCell:setContentSize(sizee)
        pButton:setOnClickScriptHandler(handler(self,self.cellCallBackActions))
    else
    	pButton = pCell:getChildByTag(2345)
    	display.commonLabelParams(pButton, {ttf = true, font = TTF_GAME_FONT, text = ShopConfig[index].shopName or '商城', fontSize = 24, color = 'ffffff'})
    end
	xTry(function()
		pCell:setTag(index)
    	if self.clickShopType and self.clickShopType == index then
    		pButton:setNormalImage(_res('ui/home/commonShop/shop_btn_tab_select.png'))
			pButton:setSelectedImage(_res('ui/home/commonShop/shop_btn_tab_select.png'))
			-- pButton:getLabel():setString(__('餐厅商城'..index))
    	else
    		pButton:setNormalImage(_res('ui/home/commonShop/shop_btn_tab_default.png'))
			pButton:setSelectedImage(_res('ui/home/commonShop/shop_btn_tab_select.png'))
			-- pButton:getLabel():setString(__('餐厅商城'..index))
    	end
	end,__G__TRACKBACK__)
    return pCell

end

function ShopMediator:cellCallBackActions(sender)
    local tag = 1
    if type(sender) == 'number' then
        tag = sender
    else
        PlayAudioByClickNormal()
        tag = sender:getParent():getTag()
        sender:setNormalImage(_res('ui/home/commonShop/shop_btn_tab_select.png'))
        sender:setSelectedImage(_res('ui/home/commonShop/shop_btn_tab_select.png'))
    end
	-- sender:setNormalImage(_res('ui/home/commonShop/shop_btn_tab_select.png'))
	-- sender:setSelectedImage(_res('ui/home/commonShop/shop_btn_tab_select.png'))

	if self.clickShopType and self.clickShopType == tag then
		return
	end
	if self.clickShopType then
        local gridView = self.viewData.gridView
		local cell = gridView:cellAtIndex(self.clickShopType - 1)
		if cell then
			local pButton = cell:getChildByTag(2345)
			if pButton then
				pButton:setNormalImage(_res('ui/home/commonShop/shop_btn_tab_default.png'))
				pButton:setSelectedImage(_res('ui/home/commonShop/shop_btn_tab_select.png'))
			end
		end
	end
	self.clickShopType = tag

	for k,v in pairs(self.selectMediator) do
		v:GetViewComponent():setVisible(false)
	end
	if not self.selectMediator[tostring(self.clickShopType)] then
		local str = ''
		str = ShopConfig[tag].mediatorName
		local selectMediator = require( string.fmt(('Game.mediator._name_'),{_name_ = str}))
		if selectMediator then
			local mediator = selectMediator.new({data = self.shopData[ShopConfig[tag].key],type = 5})
			self:GetFacade():RegistMediator(mediator)
			self.commonLayout:addChild(mediator:GetViewComponent())
			mediator:GetViewComponent():setAnchorPoint(cc.p(0, 0))
			mediator:GetViewComponent():setPosition(cc.p(20, 0))
			self.selectMediator[tostring(self.clickShopType)] = {}
			self.selectMediator[tostring(self.clickShopType)] = mediator
		end
	else
		self.selectMediator[tostring(self.clickShopType)]:GetViewComponent():setVisible(true)
	end

	-- 刷新顶部3+1货币
	self:GetViewComponent():RefreshTopGoodsPurchaseNode(ShopConfig[tag].topCurrencyId)
end


function ShopMediator:OnRegist(  )
	self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "shopAllhide")
end

function ShopMediator:OnUnRegist(  )
	--称出命令
	for k,v in ipairs(ShopConfig) do
		self:GetFacade():UnRegsitMediator(v.mediatorName)
	end

	self.commonLayout:removeAllChildren()

	if gameMgr:GetUserInfo().topUIShowType then
		self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer,gameMgr:GetUserInfo().topUIShowType)
	end

	local scene = uiMgr:GetCurrentScene()
	scene:RemoveDialog(self.viewComponent)

    self.viewComponent = nil
	self.shopData = nil
	AppFacade.GetInstance():DispatchObservers(SGL.BREAK_TO_HOME_MEDIATOR)
end

return ShopMediator

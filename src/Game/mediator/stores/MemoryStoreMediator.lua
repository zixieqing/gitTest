--[[
 * author : liuzhipeng
 * descpt : 新游戏商店 - 记忆商店Mediator
]]
local MemoryStoreMediator = class('MemoryStoreMediator', mvc.Mediator)
local NAME = "stores.MemoryStoreMediator"
local ShopGoodsCell = require('home.UnionShopGoodsCell')
local MOMERY_STORE_COUNTDOWN = 'MOMERY_STORE_COUNTDOWN'
function MemoryStoreMediator:ctor(params, viewComponent)
    self.super.ctor(self, NAME, viewComponent)
    self.selctedTabIndex = CardUtils.QUALITY_TYPE.N

end
-------------------------------------------------
------------------ inheritance ------------------
function MemoryStoreMediator:Initial( key )
    self.super.Initial(self, key)
    
	local viewComponent  = require('Game.views.stores.MemoryStoreView').new()
	viewComponent:setPosition(display.center)
	app.uiMgr:GetCurrentScene():AddDialog(viewComponent)
    self:SetViewComponent(viewComponent)
    local viewData = viewComponent.viewData
    -- 绑定
    viewComponent.eaterLayer:setOnClickScriptHandler(handler(self, self.CloseButtonCallback))
    viewComponent.viewData.gridView:setDataSourceAdapterScriptHandler(handler(self,self.GoodsListDataSource))
    viewComponent.viewData.fusionBtn:setOnClickScriptHandler(handler(self,self.FusionButtonCallback))
    viewComponent.viewData.batchBuyBtn:setOnClickScriptHandler(handler(self, self.BatchBuyButtonCallback))
    for i, v in ipairs(viewComponent.viewData.tabList) do
        v:setOnClickScriptHandler(handler(self, self.TabButtonCallback))
    end
end

function MemoryStoreMediator:InterestSignals()
    local signals = {
        POST.MEMORY_STORE_HOME.sglName,
        POST.MEMORY_STORE_BUY.sglName,
	}
	return signals
end
function MemoryStoreMediator:ProcessSignal( signal )
    local name = signal:GetName()
    local body = signal:GetBody()
    if name == POST.MEMORY_STORE_HOME.sglName then -- home
        local homeData = self:InitHomeData(body)
        self:SetHomeData(homeData)
        self:InitView()
    elseif name == POST.MEMORY_STORE_BUY.sglName then -- 记忆商店购买
        self:StorePurchase(body)
    end
end

function MemoryStoreMediator:OnRegist()
    regPost(POST.MEMORY_STORE_HOME)
    regPost(POST.MEMORY_STORE_BUY)
    self:EnterLayer()
end
function MemoryStoreMediator:OnUnRegist()
    unregPost(POST.MEMORY_STORE_HOME)
    unregPost(POST.MEMORY_STORE_BUY)
    app.timerMgr:RemoveTimer(MOMERY_STORE_COUNTDOWN)
    -- 移除界面
	local scene = app.uiMgr:GetCurrentScene()
	scene:RemoveDialog(self:GetViewComponent())
end
------------------ inheritance ------------------
-------------------------------------------------

-------------------------------------------------
-------------------- handler --------------------
--[[
关闭按钮点击回调
--]]
function MemoryStoreMediator:CloseButtonCallback( sender )
	PlayAudioByClickClose()
	app:UnRegsitMediator(NAME)
end
--[[
页签按钮点击回调
--]]
function MemoryStoreMediator:TabButtonCallback( sender ) 
    PlayAudioByClickNormal()
    local tag = sender:getTag()
    if tag ~= self:GetSelectedTabIndex() then
        self:SetSelectedTabIndex(tag)
        self:RefreshTab()
    end
end
--[[
列表处理
--]]
function MemoryStoreMediator:GoodsListDataSource( p_convertview, idx )
    local pCell = p_convertview
    local index = idx + 1
    local cSize = self:GetViewComponent().viewData.listCellSize
    if pCell == nil then
        pCell = ShopGoodsCell.new(cSize)
        pCell.bgBtn:setOnClickScriptHandler(handler(self, self.CommodityCallback))
    end
    xTry(function()
        local datas = self:GetCurrentProducts()[index]
        local goodsDatas = CommonUtils.GetConfig('goods', 'goods', datas.goodsId) or {}
        pCell.goodsIcon:RefreshSelf({goodsId = datas.goodsId, num = datas.goodsNum, showAmount = true})
        pCell.goodsName:setString(tostring(goodsDatas.name))
        pCell.stockLabel:setString(string.fmt(__('库存:_num_'), {['_num_'] = tostring(datas.leftPurchasedNum)}))
        display.reloadRichLabel(pCell.priceLabel, { c = {
            {text = tostring(datas.price) .. '  ',fontSize = 22, color = '#ffffff', font = TTF_GAME_FONT, ttf = true},
            {img = CommonUtils.GetGoodsIconPathById(checkint(datas.currency)), scale = 0.18}
        }})
        if checkint(datas.leftPurchasedNum) < 0 then
            pCell.bgBtn:setNormalImage(_res('ui/home/commonShop/shop_btn_goods_default.png'))
            pCell.bgBtn:setSelectedImage(_res('ui/home/commonShop/shop_btn_goods_default.png'))
            pCell.bgBtn:setEnabled(true)
            pCell.sellOut:setVisible(false)
            pCell.lockMask:setVisible(false)
            pCell.stockLabel:setVisible(false)
        elseif checkint(datas.leftPurchasedNum) > 0 then
            pCell.bgBtn:setNormalImage(_res('ui/home/commonShop/shop_btn_goods_default.png'))
            pCell.bgBtn:setSelectedImage(_res('ui/home/commonShop/shop_btn_goods_default.png'))
            pCell.bgBtn:setEnabled(true)
            pCell.sellOut:setVisible(false)
            pCell.lockMask:setVisible(false)
            pCell.stockLabel:setVisible(true)
        else
            pCell.bgBtn:setNormalImage(_res('ui/home/commonShop/shop_btn_goods_sellout.png'))
            pCell.bgBtn:setSelectedImage(_res('ui/home/commonShop/shop_btn_goods_sellout.png'))
            pCell.bgBtn:setEnabled(false)
            pCell.sellOut:setVisible(true)
            pCell.lockMask:setVisible(true)
            pCell.stockLabel:setVisible(false)
        end
        pCell.bgBtn:setTag(index)
    end,__G__TRACKBACK__)
    return pCell
end
--[[
商品点击回调
--]]
function MemoryStoreMediator:CommodityCallback( sender )
    PlayAudioByClickNormal()
    local tag = sender:getTag()
    local tempdata  = clone(self:GetCurrentProducts()[tag])
    if checkint(tempdata.leftPurchasedNum) < 0 or checkint(tempdata.stock) < 0 then
        tempdata.leftPurchasedNum = - 1
        tempdata.stock = - 1
    end
    if CommonUtils.CheckIsOwnSkinById(tempdata.goodsId) then
        app.uiMgr:ShowInformationTips(__('已经拥有该皮肤'))
        return
    end
    tempdata.todayLeftPurchasedNum = tempdata.leftPurchasedNum
    local scene = app.uiMgr:GetCurrentScene()
    local marketPurchasePopup  = require('Game.views.ShopPurchasePopup').new({tag = 5001, mediatorName = "MemoryStoreMediator", data = tempdata, btnTag = tag,showChooseUi = true,})
    display.commonUIParams(marketPurchasePopup, {ap = cc.p(0.5, 0.5), po = cc.p(display.width * 0.5, display.height * 0.5)})
    marketPurchasePopup:setTag(5001)
    scene:AddDialog(marketPurchasePopup)
    marketPurchasePopup.viewData.purchaseBtn:setOnClickScriptHandler(handler(self, self.PurchaseBtnCallback))
    marketPurchasePopup.viewData.purchaseBtn:setTag(tag)
end
--[[
购买按钮点击回调
--]]
function MemoryStoreMediator:PurchaseBtnCallback( sender )
    PlayAudioByClickNormal()
    local tag = sender:getTag()
    local purchaseNum = sender:getUserTag()
    local datas = self:GetCurrentProducts()[tag]
    local money = 0
    local goodsConf = CommonUtils.GetConfig('goods', 'goods', datas.currency)
    local des = goodsConf.name or __('货币')
    if checkint(datas.currency) == GOLD_ID then --金币
        des = __('金币')
        money = app.gameMgr:GetUserInfo().gold
    elseif checkint(datas.currency) == DIAMOND_ID then -- 幻晶石
        des = __('幻晶石')
        money = app.gameMgr:GetUserInfo().diamond
    elseif checkint(datas.currency) == TIPPING_ID then -- 小费
        des = __('小费')
        money = app.gameMgr:GetUserInfo().tip
    elseif checkint(datas.currency) == UNION_POINT_ID then
        des = __('工会徽章')
        money = checkint(app.gameMgr:GetUserInfo().unionPoint)
    else
        money = app.gameMgr:GetAmountByIdForce(datas.currency)
    end

    local price = datas.price * checkint(purchaseNum)
    if datas.discount  then--有折扣价格
        if checkint(datas.discount) < 100 and checkint(datas.discount) > 0 then
            price = datas.discount * data.price / 100 * checkint(purchaseNum)
        end
    end
    if checkint(money) >= checkint(price) then
        self:SendSignal(POST.MEMORY_STORE_BUY.cmdName,{productId = datas.productId,num = checkint(purchaseNum)})
    else
        if GAME_MODULE_OPEN.NEW_STORE and checkint(datas.currency) == DIAMOND_ID then
            app.uiMgr:showDiamonTips()
        else
            app.uiMgr:ShowInformationTips(string.fmt(__('_des_不足'),{_des_ = des}))
        end
    end
end
--[[
批量购买按钮点击回调
--]]
function MemoryStoreMediator:BatchBuyButtonCallback( sender )
    PlayAudioByClickNormal()
    local products = self:GetCurrentProducts()
	app:RegistMediator(require('Game.mediator.stores.MultiBuyMediator').new({
		products  = products,
		postCmd   = POST.MEMORY_STORE_BUY_MULTI,
        refreshCB = function()
            self:GetViewComponent():GridViewReload()
        end
	}))
end
function MemoryStoreMediator:FusionButtonCallback( sender )
    PlayAudioByClickNormal()
    local fusionMdt = require("Game.mediator.stores.MemoryStoreFusionMediator").new({qualityId = self.selctedTabIndex, currency = self:GetCurrentProducts()[1].currency})
    app:RegistMediator(fusionMdt)
end
--[[
定时器回调逻辑
--]]
function MemoryStoreMediator:OnShopRefreshUpdateHandler( countdown )
    if countdown > 0 then
        self:UpdateLeftSeconds(countdown)
    else
        app.timerMgr:RemoveTimer(MOMERY_STORE_COUNTDOWN)
        self:SendSignal(POST.MEMORY_STORE_HOME.cmdName)
    end
end
-------------------- handler --------------------
-------------------------------------------------

-------------------------------------------------
-------------------- private --------------------
--[[
初始化homeData
--]]
function MemoryStoreMediator:InitHomeData( data )
    local homeData_ = {}
    homeData_.nextRefreshLeftSeconds = checkint(data.nextRefreshLeftSeconds)
    homeData_.products = {}
    -- 将商品通过商品类型进行分类
    for i, v in ipairs(checktable(data.products)) do
        if homeData_.products[tostring(v.storeType)] then
            table.insert(homeData_.products[tostring(v.storeType)], v)
        else
            homeData_.products[tostring(v.storeType)] = {v}
        end
    end
    return homeData_
end
--[[
初始化view
--]]
function MemoryStoreMediator:InitView()
    -- 开启定时器
    self:StartTimer()
    -- 刷新页签
    self:RefreshTab()
end
--[[
开启定时器
--]]
function MemoryStoreMediator:StartTimer()
    local homeData = self:GetHomeData()
    app.timerMgr:AddTimer({name = MOMERY_STORE_COUNTDOWN, callback = handler(self, self.OnShopRefreshUpdateHandler), countdown = homeData.nextRefreshLeftSeconds, autoDelete = true})
    self:UpdateLeftSeconds(homeData.nextRefreshLeftSeconds)
end
--[[
初始化顶部货币栏
--]]
function MemoryStoreMediator:InitMoneyBar()
    local viewComponent = self:GetViewComponent()
    local currency = checkint(self:GetCurrentProducts()[1].currency)
    local moneyIdMap = {currency}
    viewComponent:InitMoneyBar(moneyIdMap)
end
--[[
刷新tab
--]]
function MemoryStoreMediator:RefreshTab()
    local viewComponent = self:GetViewComponent()
    viewComponent:RefreshTab(self:GetSelectedTabIndex())
    -- 更新顶部货币栏
    self:InitMoneyBar()
    -- 刷新列表
    self:RefreshList()
end
--[[
刷新列表
--]]
function MemoryStoreMediator:RefreshList()
    local products = self:GetCurrentProducts()
    local viewComponent = self:GetViewComponent()
    viewComponent:RefreshList(products)
end
--[[
商城购买
--]]
function MemoryStoreMediator:StorePurchase( datas )
    app.uiMgr:AddDialog('common.RewardPopup', {rewards = datas.rewards})
    local data = {}
    for i,v in ipairs(self:GetCurrentProducts()) do
        if checkint(v.productId) == checkint(datas.requestData.productId) then
            v.leftPurchasedNum = v.leftPurchasedNum - datas.requestData.num
            data = clone(v)
            break
        end
    end
    local Trewards = {}
    if next(data) ~= nil then
        if data.discount  then--说明有折扣。价格根据折扣价格走
            if checkint(data.discount) < 100 and checkint(data.discount) > 0 then
                data.price = data.price * data.discount / 100
            end
        end
        local consumeCurrencyNum = -data.price * checkint(datas.requestData.num or 1)
        table.insert(Trewards,{goodsId = data.currency, num = consumeCurrencyNum})
    end
    CommonUtils.DrawRewards(Trewards)
    self:GetViewComponent():GridViewReload()
    self:ClosePurchasePopup()
end
--[[
关闭购买页面
--]]
function MemoryStoreMediator:ClosePurchasePopup()
    local buyGoodsMediator = app:RetrieveMediator('MultiBuyMediator')
    if buyGoodsMediator then
        buyGoodsMediator:close()
    end
    app.uiMgr:GetCurrentScene():RemoveDialogByTag(5001)
end
--[[
更新剩余时间
--]]
function MemoryStoreMediator:UpdateLeftSeconds( leftSeconds )
    local viewComponent = self:GetViewComponent()
    viewComponent:RefreshCountDownLabel(leftSeconds)
end
--[[
进入页面
--]]
function MemoryStoreMediator:EnterLayer()
    self:SendSignal(POST.MEMORY_STORE_HOME.cmdName)
end
-------------------- private --------------------
-------------------------------------------------

-------------------------------------------------
------------------- get / set -------------------
--[[
设置homeData
--]]
function MemoryStoreMediator:SetHomeData( homeData )
    self.homeData = homeData
end
--[[
获取homeData
--]]
function MemoryStoreMediator:GetHomeData()
    return self.homeData or {}
end
--[[
设置选中的标签
--]]
function MemoryStoreMediator:SetSelectedTabIndex( selctedTabIndex )
    if not selctedTabIndex then return end
    self.selctedTabIndex = checkint(selctedTabIndex)
end
--[[
获取选中的标签
--]]
function MemoryStoreMediator:GetSelectedTabIndex()
    return self.selctedTabIndex
end
--[[
获取当前所选页面的商品
--]]
function MemoryStoreMediator:GetCurrentProducts()
    local homeData = self:GetHomeData()
    return checktable(homeData.products)[tostring(self:GetSelectedTabIndex())]
end
------------------- get / set -------------------
-------------------------------------------------
return MemoryStoreMediator

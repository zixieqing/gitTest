--[[
 * author : zhipeng
 * descpt : 猫屋 - 装饰商店 中介者
]]
local CatHouseDressShopView     = require('Game.views.catHouse.CatHouseDressShopView')
local CatHouseDressShopMediator = class('CatHouseDressShopMediator', mvc.Mediator)
local NAME = "CatHouseDressShopMediator"
function CatHouseDressShopMediator:ctor(params, viewComponent)
    self.super.ctor(self, NAME, viewComponent)
    self.ctorArgs_ = checktable(params)
    self:SetSelectedTabIndex(CatHouseUtils.AVATAR_STYLE_TYPE.IDENTITY)
end

-------------------------------------------------
------------------ inheritance ------------------

function CatHouseDressShopMediator:Initial(key)
    self.super.Initial(self, key)
    -- init vars
    self.isControllable_ = true

    local viewComponent  = require('Game.views.catHouse.CatHouseDressShopView').new()
	viewComponent:setPosition(display.center)
    app.uiMgr:GetCurrentScene():AddDialog(viewComponent)
    self:SetViewComponent(viewComponent)
    
    local viewData = viewComponent:GetViewData()
    viewComponent.eaterLayer:setOnClickScriptHandler(handler(self, self.CloseButtonCallback))
    viewData.goodsGridView:setCellUpdateHandler(handler(self, self.OnUpdateGoodsListCellHandler))
    viewData.goodsGridView:setCellInitHandler(handler(self, self.OnInitGoodsListCellHandler))
    for i, v in ipairs(viewComponent.viewData.tabList) do
        v:setOnClickScriptHandler(handler(self, self.TabButtonCallback))
    end
    self:InitView()
end


function CatHouseDressShopMediator:CleanupView()
    self:ClosePurchasePopup()
    local scene = app.uiMgr:GetCurrentScene()
    scene:RemoveDialog(self:GetViewComponent())
end


function CatHouseDressShopMediator:OnRegist()
    regPost(POST.HOUSE_MALL_BUY)
end


function CatHouseDressShopMediator:OnUnRegist()
    regPost(POST.HOUSE_MALL_BUY)
end


function CatHouseDressShopMediator:InterestSignals()
    return {
        POST.HOUSE_MALL_BUY.sglName,
    }
end
function CatHouseDressShopMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()
    if name == POST.HOUSE_MALL_BUY.sglName then -- 家具购买
        self:MallBuyResponseHandler(data)
    end
end
------------------ inheritance ------------------
-------------------------------------------------

-------------------------------------------------
-------------------- handler --------------------
--[[
关闭按钮点击回调
--]]
function CatHouseDressShopMediator:CloseButtonCallback( sender )
    PlayAudioByClickClose()
    app:UnRegistMediator(NAME)
end
--[[
页签按钮点击回调
--]]
function CatHouseDressShopMediator:TabButtonCallback( sender ) 
    PlayAudioByClickNormal()
    local tag = checkint(sender:getTag())
    if tag ~= self:GetSelectedTabIndex() then
        self:SetSelectedTabIndex(tag)
        self:RefreshTab()
    end
end
--[[
道具列表刷新
--]]
function CatHouseDressShopMediator:OnUpdateGoodsListCellHandler( cellIndex, cellViewData )
    local goodsData = self:GetCurrentProducts()[cellIndex]
    cellViewData.bg:setTag(cellIndex)

    cellViewData.itemLayer:removeAllChildren()
    local itemNode = nil
    if self:GetSelectedTabIndex() == checkint(CatHouseUtils.AVATAR_STYLE_TYPE.IDENTITY) then
        itemNode = CatHouseUtils.GetBusinessCardNode(goodsData.id, app.gameMgr:GetUserInfo().playerName)
    else
        itemNode = CatHouseUtils.GetBubbleNode(goodsData.id, __("请输入文字"))
    end
    cellViewData.itemLayer:addList(itemNode):alignTo(nil, ui.cc, {offsetY = 20})

    if app.goodsMgr:getGoodsNum(goodsData.id) >= 1 then
        -- 已拥有道具
        cellViewData.priceLabel:setVisible(false)
        cellViewData.currencyIcon:setVisible(false)
        cellViewData.ownedLabel:setVisible(true)
        return 
    end
    cellViewData.priceLabel:setVisible(true)
    cellViewData.currencyIcon:setVisible(true)
    cellViewData.ownedLabel:setVisible(false)
    local currency = CatHouseUtils.GetCurrencyByPayType(goodsData.payType)
    cellViewData.priceLabel:setString(goodsData.payPrice)
    cellViewData.currencyIcon:setTexture(GoodsUtils.GetIconPathById(currency))
    ui.flowLayout(cc.p(cellViewData.size.width / 2, 38), {cellViewData.priceLabel, cellViewData.currencyIcon}, {ap = display.CENTER, gapW = 5})
end
--[[
道具按钮点击回调
--]]
function CatHouseDressShopMediator:GoodsButtonCallBack( sender )
    local tag = sender:getTag()
    local goodsData = self:GetCurrentProducts()[tag]
    if app.goodsMgr:getGoodsNum(goodsData.id) >= 1 then
        return
    end
    PlayAudioByClickNormal()
    local currency = CatHouseUtils.GetCurrencyByPayType(goodsData.payType)
    -- 购买弹窗
    local shopPurchaseData = {
        currency = currency,
        price    = checkint(goodsData.payPrice),
        goodsId  = goodsData.id, 
        goodsNum = 1,
    }
    local shopPurchasePopup = require('Game.views.ShopPurchasePopup').new({data = shopPurchaseData})
    shopPurchasePopup:setPosition(display.center)
    shopPurchasePopup:setName('shopPurchasePopup')
    shopPurchasePopup.viewData.purchaseBtn:setTag(tag)
    shopPurchasePopup.viewData.purchaseBtn:setOnClickScriptHandler(handler(self, self.PurchaseButtonCallback))
    app.uiMgr:GetCurrentScene():AddDialog(shopPurchasePopup)
end
--[[
购买按钮点击回调
--]]
function CatHouseDressShopMediator:PurchaseButtonCallback( sender )
    PlayAudioByClickNormal()
    local tag = sender:getTag()
    local goodsData = self:GetCurrentProducts()[tag]
    local currency = CatHouseUtils.GetCurrencyByPayType(goodsData.payType)
    -- 检查货币是否满足
    local totalPrice = checkint(goodsData.payPrice)
    if currency == DIAMOND_ID then
        if app.uiMgr:showDiamonTips(totalPrice) then return end
    else
        if totalPrice > app.goodsMgr:getGoodsNum(currency) then
            app.uiMgr:ShowInformationTips(string.fmt(__('_name_不足'),{_name_ = tostring(GoodsUtils.GetGoodsNameById(currency))}))
            return
        end
    end
    self:SendSignal(POST.HOUSE_MALL_BUY.cmdName, {productId = goodsData.id, index = tag})
end
--[[
道具列表cell初始化
--]]
function CatHouseDressShopMediator:OnInitGoodsListCellHandler( cellViewData )
    cellViewData.bg:setOnClickScriptHandler(handler(self, self.GoodsButtonCallBack))
end
-------------------- handler --------------------
-------------------------------------------------

-------------------------------------------------
-------------------- private --------------------
--[[
初始化页面
--]]
function CatHouseDressShopMediator:InitView()
    local viewComponent = self:GetViewComponent()
    local viewData = viewComponent:GetViewData()
    -- 初始化商城数据
    self:InitHomeData()
    -- 初始化顶部货币栏
    self:InitMoneyBar()
    -- 刷新页签
    self:RefreshTab()
end
--[[
初始化顶部货币栏
--]]
function CatHouseDressShopMediator:InitMoneyBar()
    local viewComponent = self:GetViewComponent()
    local moneyIdMap = {}
    viewComponent:InitMoneyBar(moneyIdMap)
end
--[[
初始化homeData
--]]
function CatHouseDressShopMediator:InitHomeData()
    local homeData = {}
    local mallConf = CONF.CAT_HOUSE.MALL_INFO:GetAll()
    -- 将商品通过商品类型进行分类
    for i, v in pairs(mallConf) do
        local dressType = CatHouseUtils.GetDressTypeByGoodsId(v.id)
        if homeData[tostring(dressType)] then
            table.insert(homeData[tostring(dressType)], v)
        else
            homeData[tostring(dressType)] = {v}
        end
    end

    self:SetHomeData(homeData)
end
--[[
刷新tab
--]]
function CatHouseDressShopMediator:RefreshTab()
    local viewComponent = self:GetViewComponent()
    viewComponent:RefreshTab(self:GetSelectedTabIndex())
    -- 刷新列表
    self:RefreshList()
end
--[[
刷新列表
--]]
function CatHouseDressShopMediator:RefreshList()
    local products = self:GetCurrentProducts()
    local viewComponent = self:GetViewComponent()
    viewComponent:RefreshList(products)
end
--[[
商城购买返回处理
--]]
function CatHouseDressShopMediator:MallBuyResponseHandler( responseData )
    local goodsData = self:GetCurrentProducts()[responseData.requestData.index]
    local needUpdateData = {
        {goodsId = CatHouseUtils.GetCurrencyByPayType(goodsData.payType), num = -checkint(goodsData.payPrice)},
        {goodsId = responseData.requestData.productId, num = 1}
    }
    CommonUtils.DrawRewards(needUpdateData)
    -- 刷新页面
    local viewComponent = self:GetViewComponent()
    local viewData = viewComponent:GetViewData()
    local contentOffset = viewData.goodsGridView:getContentOffset()
    viewData.goodsGridView:reloadData()
    viewData.goodsGridView:setContentOffset(contentOffset)
    self:ClosePurchasePopup()
    app.uiMgr:ShowInformationTips(__('购买成功'))
end
--[[
关闭购买弹窗
--]]
function CatHouseDressShopMediator:ClosePurchasePopup()
    app.uiMgr:GetCurrentScene():RemoveDialogByName('shopPurchasePopup')
end
-------------------- private --------------------
-------------------------------------------------

-------------------------------------------------
------------------- get / set -------------------
--[[
设置homeData
--]]
function CatHouseDressShopMediator:SetHomeData( homeData )
    self.homeData = homeData
end
--[[
获取homeData
--]]
function CatHouseDressShopMediator:GetHomeData()
    return self.homeData or {}
end
--[[
设置选中的标签
--]]
function CatHouseDressShopMediator:SetSelectedTabIndex( selctedTabIndex )
    if not selctedTabIndex then return end
    self.selctedTabIndex = checkint(selctedTabIndex)
end
--[[
获取选中的标签
--]]
function CatHouseDressShopMediator:GetSelectedTabIndex()
    return checkint(self.selctedTabIndex)
end
--[[
获取当前所选页面的商品
--]]
function CatHouseDressShopMediator:GetCurrentProducts()
    local homeData = self:GetHomeData()
    return checktable(homeData)[tostring(self:GetSelectedTabIndex())]
end
------------------- get / set -------------------
-------------------------------------------------
return CatHouseDressShopMediator

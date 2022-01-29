--[[
 * author : zhipeng
 * descpt : 猫屋 - 家具商店 中介者
]]
local CatHouseAvatarShopView     = require('Game.views.catHouse.CatHouseAvatarShopView')
local CatHouseAvatarShopMediator = class('CatHouseAvatarShopMediator', mvc.Mediator)
local NAME = "CatHouseAvatarShopMediator"
-------------------------------------------------
-------------------- define ---------------------

local TAB_INFOS = {
    CatHouseUtils.AVATAR_TAB_TYPE.LIVING_ROOM,
    CatHouseUtils.AVATAR_TAB_TYPE.BEDROOM,
    CatHouseUtils.AVATAR_TAB_TYPE.HALL,
    CatHouseUtils.AVATAR_TAB_TYPE.CATTERY,
    CatHouseUtils.AVATAR_TAB_TYPE.FLOOR,
    CatHouseUtils.AVATAR_TAB_TYPE.WALL,
    CatHouseUtils.AVATAR_TAB_TYPE.CELLING,
}
-------------------- define ---------------------
-------------------------------------------------

-------------------------------------------------
------------------ inheritance ------------------
function CatHouseAvatarShopMediator:ctor(params, viewComponent)
    self.super.ctor(self, NAME, viewComponent)
    self.ctorArgs_ = checktable(params)
    self.isControllable_ = true
    self.selectedTab = 1
    self.selectedGoods = 1
    self.purchaseAmount = 1
end
function CatHouseAvatarShopMediator:Initial(key)
    self.super.Initial(self, key)

    -- init vars
    self.isControllable_ = true

    local viewComponent  = require('Game.views.catHouse.CatHouseAvatarShopView').new()
	viewComponent:setPosition(display.center)
    app.uiMgr:GetCurrentScene():AddDialog(viewComponent)
    self:SetViewComponent(viewComponent)
    
    local viewData = viewComponent:GetViewData()
    viewComponent.eaterLayer:setOnClickScriptHandler(handler(self, self.CloseButtonCallback))
    viewData.tabTableView:setCellUpdateHandler(handler(self, self.OnUpdateTabListCellHandler))
    viewData.tabTableView:setCellInitHandler(handler(self, self.OnInitTabListCellHandler))
    viewData.goodsGridView:setCellUpdateHandler(handler(self, self.OnUpdateGoodsListCellHandler))
    viewData.goodsGridView:setCellInitHandler(handler(self, self.OnInitGoodsListCellHandler))
    viewData.btnSub:setOnClickScriptHandler(handler(self, self.SubButtonCallback))
    viewData.btnAdd:setOnClickScriptHandler(handler(self, self.AddButtonCallback))
    viewData.buyBtn:setOnClickScriptHandler(handler(self, self.BuyButtonCallback))
    self:InitMallData()
    self:InitView()
end

function CatHouseAvatarShopMediator:OnRegist()
    regPost(POST.HOUSE_AVATAR_BUY)
end


function CatHouseAvatarShopMediator:OnUnRegist()
    unregPost(POST.HOUSE_AVATAR_BUY)
end

function CatHouseAvatarShopMediator:CleanupView()
    local scene = app.uiMgr:GetCurrentScene()
    scene:RemoveDialog(self:GetViewComponent())
end

function CatHouseAvatarShopMediator:InterestSignals()
    return {
        POST.HOUSE_AVATAR_BUY.sglName,
    }
end
function CatHouseAvatarShopMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()
    if name == POST.HOUSE_AVATAR_BUY.sglName then -- 家具购买
        self:BuyAvatarResponseHandler(data)
    end
end
------------------ inheritance ------------------
-------------------------------------------------

-------------------------------------------------
-------------------- handler --------------------
--[[
关闭按钮点击回调
--]]
function CatHouseAvatarShopMediator:CloseButtonCallback( sender )
    PlayAudioByClickClose()
    app:UnRegistMediator(NAME)
end
--[[
页签列表刷新
--]]
function CatHouseAvatarShopMediator:OnUpdateTabListCellHandler( cellIndex, cellViewData )
    cellViewData.button:setTag(cellIndex)
    local tabTypeId = TAB_INFOS[cellIndex]
    local name      = CatHouseUtils.GetAvatarTabTypeName(tabTypeId)

    if cellIndex == self:GetSelectedTab() then
        cellViewData.sBg:setVisible(true)
        cellViewData.nTitle:setVisible(false)
        cellViewData.sTitle:setString(name)
        cellViewData.sImg:setTexture(CatHouseUtils.GetAvatarTabTypeIcon(tabTypeId))
    else
        cellViewData.sBg:setVisible(false)
        cellViewData.nTitle:setVisible(true)
        cellViewData.nTitle:setString(name)
    end
end
--[[
页签列表cell初始化
--]]
function CatHouseAvatarShopMediator:OnInitTabListCellHandler( cellViewData )
    cellViewData.button:setOnClickScriptHandler(handler(self, self.TabButtonCallBack))
end
--[[
页签按钮点击回调
--]]
function CatHouseAvatarShopMediator:TabButtonCallBack( sender )
    if sender:getTag() == self:GetSelectedTab() then return end
    self:RefreshTab(sender:getTag())
end
--[[
道具列表刷新
--]]
function CatHouseAvatarShopMediator:OnUpdateGoodsListCellHandler( cellIndex, cellViewData )
    local goodsData = self:GetMallData()[self:GetSelectedTab()][cellIndex]
    cellViewData.bg:setTag(cellIndex)
    cellViewData.goodsFrame:setVisible(cellIndex == self:GetSelectedGoods())
    if app.goodsMgr:getGoodsNum(goodsData.id) > 0 then
        cellViewData.ownNumLabel:setVisible(true)
        cellViewData.ownNumLabel:setString(string.format(__('拥有:%s'), app.goodsMgr:getGoodsNum(goodsData.id)))
    else
        cellViewData.ownNumLabel:setVisible(false)
    end
    cellViewData.goodIcon:setVisible(true)
    cellViewData.goodIcon:setTexture(AssetsUtils.GetCatHouseSmallAvatarPath(goodsData.id))
    cellViewData.goodName:setString(tostring(goodsData.name))
    cellViewData.priceNum:setString(goodsData.price)
    local currency = checkint(goodsData.currency)
    cellViewData.castIcon:setTexture(GoodsUtils.GetIconPathById(currency))
    ui.flowLayout(cc.p(cellViewData.size.width / 2, 28), {cellViewData.priceNum, cellViewData.castIcon}, {ap = display.CENTER, gapW = 5})
end
--[[
道具按钮点击回调
--]]
function CatHouseAvatarShopMediator:GoodsButtonCallBack( sender )
    local tag = sender:getTag()
    if tag == self:GetSelectedGoods() then return end
    local viewComponent = self:GetViewComponent()
    local viewData = viewComponent:GetViewData()
    local oldCell = viewData.goodsGridView:cellAtIndex(self:GetSelectedGoods() - 1)
    if oldCell then
        viewComponent:UpdateGoodsCellSelectState(oldCell, false)
    end
    local cell = viewData.goodsGridView:cellAtIndex(tag - 1)
    if cell then
        viewComponent:UpdateGoodsCellSelectState(cell, true)
    end
    self:SetSelectedGoods(tag)
    self:SetPurchaseAmount(1)
    self:RefreshGoodsPreview()
end
--[[
道具列表cell初始化
--]]
function CatHouseAvatarShopMediator:OnInitGoodsListCellHandler( cellViewData )
    cellViewData.bg:setOnClickScriptHandler(handler(self, self.GoodsButtonCallBack))
end
--[[
减少数量按钮点击回调
--]]
function CatHouseAvatarShopMediator:SubButtonCallback( sender )
    PlayAudioByClickNormal()
    local purchaseAmount = self:GetPurchaseAmount()
    if purchaseAmount == 1 then return end
    purchaseAmount = purchaseAmount - 1
    self:SetPurchaseAmount(purchaseAmount)
    self:RefreshGoodsPreview()
end
--[[
增加数量按钮点击回调
--]]
function CatHouseAvatarShopMediator:AddButtonCallback( sender )
    PlayAudioByClickNormal()
    local purchaseAmount = self:GetPurchaseAmount()
    local goodsData = self:GetCurrentGoodsData()
    local max = checkint(goodsData.max) - app.goodsMgr:getGoodsNum(goodsData.id)
    if purchaseAmount >= max then 
        app.uiMgr:ShowInformationTips(string.fmt(__('_name_最多购买_num_个'),{_name_ = goodsData.name, _num_ = max}))
        return 
    end
    purchaseAmount = purchaseAmount + 1
    self:SetPurchaseAmount(purchaseAmount)
    self:RefreshGoodsPreview()
end
--[[
购买按钮点击回调
--]]
function CatHouseAvatarShopMediator:BuyButtonCallback( sender )
    PlayAudioByClickNormal()
    local goodsData = self:GetCurrentGoodsData()
    local purchaseAmount = self:GetPurchaseAmount()
    -- 判断道具是否还可以购买
    if app.goodsMgr:getGoodsNum(goodsData.id) >= checkint(goodsData.max) then
        app.uiMgr:ShowInformationTips(string.fmt(__('_name_最多拥有_num_'),{_name_ = goodsData.name, _num_ = goodsData.max}))
        return 
    end
    -- 检查货币是否满足
    local totalPrice = checkint(goodsData.price) * purchaseAmount
    local  currency = checkint(goodsData.currency)
    if currency == DIAMOND_ID then
        if app.uiMgr:showDiamonTips(totalPrice) then return end
    else
        if totalPrice > app.goodsMgr:getGoodsNum(currency) then
            app.uiMgr:ShowInformationTips(string.fmt(__('_name_不足'),{_name_ = tostring(GoodsUtils.GetGoodsNameById(currency))}))
            return
        end
    end
    -- 请求购买道具
    local buyCallBack = function ()
        self:SendSignal(POST.HOUSE_AVATAR_BUY.cmdName, {goodsId = goodsData.id, num = purchaseAmount})
    end
    if currency == DIAMOND_ID then
        local CommonTip  = require( 'common.NewCommonTip' ).new({text = string.format(__('是否花费%s幻晶石购买%s%s个'), totalPrice, goodsData.name, purchaseAmount),
        isOnlyOK = false, callback = buyCallBack})
        CommonTip:setPosition(display.center)
        local scene = app.uiMgr:GetCurrentScene()
        scene:AddDialog(CommonTip)
    else
        buyCallBack()
    end
end
-------------------- handler --------------------
-------------------------------------------------

-------------------------------------------------
-------------------- private --------------------
--[[
初始化商城数据
--]]
function CatHouseAvatarShopMediator:InitMallData()
    local avatarConf = CONF.CAT_HOUSE.AVATAR_INFO:GetAll()
    local mallData = {}
    for _, v in pairs(avatarConf) do
        for _, type in ipairs(v.category) do
            if mallData[checkint(type)] then
                table.insert(mallData[checkint(type)], v)
            else
                mallData[checkint(type)] = {v}
            end
        end
    end
    for i, v in ipairs(mallData) do
        table.sort(v, function (a, b)
            return checkint(a.id) < checkint(b.id)
        end)
    end
    self:SetMallData(mallData)
end
--[[
初始化页面
--]]
function CatHouseAvatarShopMediator:InitView()
    local viewComponent = self:GetViewComponent()
    local viewData = viewComponent:GetViewData()
    viewData.tabTableView:resetCellCount(#TAB_INFOS)
    self:InitMoneyBar()
    self:RefreshTab(self:GetSelectedTab())
end
--[[
初始化顶部货币栏
--]]
function CatHouseAvatarShopMediator:InitMoneyBar()
    local viewComponent = self:GetViewComponent()
    local moneyIdMap = {CAT_SILVER_COIN_ID, CAT_GOLD_COIN_ID}
    viewComponent:InitMoneyBar(moneyIdMap)
end
--[[
刷新页签
@params selectedTab int 选中页签序号
--]]
function CatHouseAvatarShopMediator:RefreshTab( selectedTab )
    self:SetSelectedTab(selectedTab)
    local viewComponent = self:GetViewComponent()
    local viewData = viewComponent:GetViewData()
    viewData.tabTableView:reloadData()
    self:RefreshGoodsList()
end
--[[
刷新道具列表
--]]
function CatHouseAvatarShopMediator:RefreshGoodsList()
    local viewComponent = self:GetViewComponent()
    local viewData = viewComponent:GetViewData()
    local goodsData = self:GetMallData()[self:GetSelectedTab()] or {}
    self:SetSelectedGoods(1)
    self:SetPurchaseAmount(1)
    viewData.goodsGridView:resetCellCount(#goodsData)
    self:RefreshGoodsPreview()
end
--[[
刷新道具预览
--]]
function CatHouseAvatarShopMediator:RefreshGoodsPreview()
    local viewComponent = self:GetViewComponent()
    local viewData = viewComponent:GetViewData()
    local goodsData = self:GetCurrentGoodsData()
    viewComponent:RefreshGoodsPreview(goodsData, self:GetPurchaseAmount())
end
--[[
购买avatar返回处理
--]]
function CatHouseAvatarShopMediator:BuyAvatarResponseHandler( responseData )
    local goodsData = self:GetCurrentGoodsData()
    local price = responseData.requestData.num * checkint(goodsData.price)
    local needUpdateData = {
        {goodsId = checkint(goodsData.currency), num = -price},
        {goodsId = responseData.requestData.goodsId, num = responseData.requestData.num}
    }
    CommonUtils.DrawRewards(needUpdateData)
    -- 刷新页面
    local viewComponent = self:GetViewComponent()
    local viewData = viewComponent:GetViewData()
    local contentOffset = viewData.goodsGridView:getContentOffset()
    viewData.goodsGridView:reloadData()
    viewData.goodsGridView:setContentOffset(contentOffset)
    self:SetPurchaseAmount(1)
    self:RefreshGoodsPreview()
    app.uiMgr:ShowInformationTips(__('购买成功'))
end
-------------------- private --------------------
-------------------------------------------------

-------------------------------------------------
------------------- get / set -------------------
--[[
设置商城数据
--]]
function CatHouseAvatarShopMediator:SetMallData( mallData )
    self.mallData = mallData
end
--[[
获取商城数据
--]]
function CatHouseAvatarShopMediator:GetMallData()
    return checktable(self.mallData)
end
--[[
设置选中的页签
--]]
function CatHouseAvatarShopMediator:SetSelectedTab( index )
    self.selectedTab = index
end
--[[
获取选中的页签
--]]
function CatHouseAvatarShopMediator:GetSelectedTab()
    return self.selectedTab
end
--[[
设置选中的道具
--]]
function CatHouseAvatarShopMediator:SetSelectedGoods( index )
    self.selectedGoods = index
end
--[[
获取选中的道具
--]]
function CatHouseAvatarShopMediator:GetSelectedGoods()
    return self.selectedGoods
end
--[[
设置购买数量
--]]
function CatHouseAvatarShopMediator:SetPurchaseAmount( amount )
    self.purchaseAmount = amount
end
--[[
获取购买数量
--]]
function CatHouseAvatarShopMediator:GetPurchaseAmount()
    return self.purchaseAmount
end
--[[
获取当前选中道具的数据
--]]
function CatHouseAvatarShopMediator:GetCurrentGoodsData()
    local tabDataMap = checktable(self:GetMallData()[self:GetSelectedTab()])
    return tabDataMap[self:GetSelectedGoods()] or {}
end
------------------- get / set -------------------
-------------------------------------------------

-------------------------------------------------
-------------------- pbulic ---------------------

-------------------- pbulic ---------------------
-------------------------------------------------
return CatHouseAvatarShopMediator

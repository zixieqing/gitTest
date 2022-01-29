--[[
仙境梦游商店Mediator
--]]
local Mediator = mvc.Mediator

local Anniversary19ShopMeditaor = class("Anniversary19ShopMeditaor", Mediator)

local NAME = "anniversary19.Anniversary19ShopMeditaor"

local app                = app
local uiMgr              = app:GetManager("UIManager")
local gameMgr            = app:GetManager("GameManager")
local cardMgr            = app:GetManager("CardManager")
local unionMgr           = app:GetManager("UnionManager")
local UnionShopGoodsCell = require('home.UnionShopGoodsCell')

function Anniversary19ShopMeditaor:ctor( params, viewComponent )
    self.super:ctor(NAME,viewComponent)
    self.args = checktable(params) or {}

    self.curSelectTabIndex = 1
end
function Anniversary19ShopMeditaor:InterestSignals()
    return { 
        POST.ANNIVERSARY2_MALL_BUY.sglName,
        SGL.REFRESH_NOT_CLOSE_GOODS_EVENT,
        SGL.CACHE_MONEY_UPDATE_UI
    }
end
function Anniversary19ShopMeditaor:ProcessSignal( signal )
    local name = signal:GetName() 
    local body = signal:GetBody() or {}
    
    if name == POST.ANNIVERSARY2_MALL_BUY.sglName then

        uiMgr:AddDialog('common.RewardPopup', {rewards = body.rewards})

        local requestData  = body.requestData or {}
        local productId    = requestData.productId
        local purchasedNum = requestData.num or 1

        local data = {}
        local shopDatas = self:GetCurGoodsDatas()
        local index = 0
        for i,v in ipairs(shopDatas) do
            if checkint(v.productId) == checkint(productId) then
                shopDatas[i].leftPurchasedNum = v.leftPurchasedNum - purchasedNum
                data = clone(v)
                index = i
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

            local consumeNum = -data.price * purchasedNum
            table.insert(Trewards, {goodsId = checkint(data.currency), num = consumeNum})
        end
        CommonUtils.DrawRewards(Trewards)

        -- 更新home data mallBuy商店已购买数据 （键为商品ID，值为已购买数）
        local mgr          = app.anniversary2019Mgr
        local homeData     = mgr:GetHomeData()
        local mallBuy      = homeData.mallBuy or {}
        mallBuy[tostring(productId)] = (mallBuy[tostring(productId)] or 0) + purchasedNum
        homeData.mallBuy = mallBuy 

        -- 更新cell
        local gridView      = self:GetViewData().gridView
        local cell = gridView:cellAtIndex(index - 1)
        if cell then
            self:GetViewComponent():UpdateCell(cell, shopDatas[index])
        end
        
        local scene = uiMgr:GetCurrentScene()
        if scene:GetDialogByTag( 5001 ) then
            scene:GetDialogByTag( 5001 ):runAction(cc.RemoveSelf:create())--购买详情弹出框
        end

    elseif name == SGL.REFRESH_NOT_CLOSE_GOODS_EVENT or 
           name == SGL.CACHE_MONEY_UPDATE_UI then
        self:GetViewComponent():UpdateMoneyBarGoodNum()
    end
end

function Anniversary19ShopMeditaor:Initial( key )
    self.super.Initial(self,key)
    local scene = uiMgr:GetCurrentScene()
    local viewComponent  = require( 'Game.views.anniversary19.Anniversary19ShopView' ).new({mdtName = NAME})
    self:SetViewComponent(viewComponent)
    viewComponent:setPosition(display.center)
    scene:AddDialog(viewComponent)

    self.viewData_ = viewComponent:GetViewData()
    
    viewComponent:GetViewData().gridView:setDataSourceAdapterScriptHandler(handler(self,self.GoodsListDataSource))

    self:InitData()
    self:InitUI()
end

function Anniversary19ShopMeditaor:InitData()
    local shopConfDatas = CommonUtils.GetConfigAllMess('shop', 'anniversary2') or {}

    local mgr          = app.anniversary2019Mgr
    local homeData     = mgr:GetHomeData()
    local mallBuy      = homeData.mallBuy or {}

    local tempDatas = {}
    local currencys = {}
    for key, confData in orderedPairs(shopConfDatas) do
        local id               = confData.id
        local consumeData      = checktable(confData.consume)[1] or {}
        local currency         = consumeData.goodsId
        local price            = consumeData.num
        local rewardData       = checktable(confData.rewards)[1] or {}
        local goodsId          = rewardData.goodsId
        local goodsNum         = rewardData.num
        local leftPurchasedNum = checkint(confData.exchangeLimit)
        local stock            = leftPurchasedNum
        if mallBuy[tostring(id)] and stock ~= -1 then
            leftPurchasedNum = leftPurchasedNum - checkint(mallBuy[tostring(id)])
            stock = leftPurchasedNum
        end

        if tempDatas[tostring(currency)] == nil then
            tempDatas[tostring(currency)] = {}
            table.insert(currencys, checkint(currency))
        end

        table.insert(tempDatas[tostring(currency)], {
            productId        = id,
            currency         = currency,
            price            = price,
            exchangeLimit    = confData.exchangeLimit,
            rewards          = confData.rewards,
            leftPurchasedNum = leftPurchasedNum,
            stock            = stock,
            goodsId          = goodsId,
            goodsNum         = goodsNum,
        })
    end

    table.sort(currencys)

    local shopDatas = {}
    for index, currency in ipairs(currencys) do
        table.insert(shopDatas, tempDatas[tostring(currency)])
    end

    self.currencys = currencys
    self.shopDatas = shopDatas
end

function Anniversary19ShopMeditaor:InitUI()
    local viewComponent = self:GetViewComponent()
    
    self:InitTabListView()

    -- 更新
    viewComponent:UpdateMoneyBarGoodList(self.currencys)

    local shopData = self:GetCurGoodsDatas()
    viewComponent:UpdateGrideView(shopData)
end

function Anniversary19ShopMeditaor:InitTabListView()
    local viewData      = self:GetViewData()
    local tabListView   = viewData.tabListView
    local viewComponent = self:GetViewComponent()
    local GetConfig     = CommonUtils.GetConfig
    
    local size = cc.size(160, 50)
    for index, currency in ipairs(self.currencys) do
        local name = GetConfig('goods', 'goods', currency).name
        local goodsId = currency
        
        local cell = viewComponent:CreateTabCell(size, name)
        local toggleView = cell:getChildByName('toggleView')
        display.commonUIParams(toggleView , {cb = handler(self ,self.OnClickTabAction)})
        toggleView:setTag(index)

        if index == self.curSelectTabIndex then
            viewComponent:UpdateTabSelectState(cell, true)
        end

        tabListView:insertNodeAtLast(cell)
    end

    tabListView:reloadData()

end

function Anniversary19ShopMeditaor:GetCurGoodsDatas()
    return self.shopDatas[self.curSelectTabIndex]
end

function Anniversary19ShopMeditaor:GetViewData()
    return self.viewData_
end

--[[
列表处理
--]]
function Anniversary19ShopMeditaor:GoodsListDataSource( p_convertview, idx )
    local pCell = p_convertview
    local index = idx + 1
    local viewComponent = self:GetViewComponent()
    if pCell == nil then
        local cSize = viewComponent.viewData_.listCellSize
        pCell = UnionShopGoodsCell.new(cSize)
        pCell.bgBtn:setOnClickScriptHandler(handler(self, self.CommodityCallback))
        pCell.lockMask:setVisible(false)
        pCell.lockLabel:setVisible(false)
    end
    xTry(function()

        local shopDatas = self:GetCurGoodsDatas()
        viewComponent:UpdateCell(pCell, shopDatas[index] or {})
        
        pCell.bgBtn:setTag(index)
    end,__G__TRACKBACK__)
    return pCell
end

function Anniversary19ShopMeditaor:OnClickTabAction(sender)
   local clickIndex = sender:getTag()
   if clickIndex == self.curSelectTabIndex then
       return
   end

   local viewData      = self:GetViewData()
   local tabListView   = viewData.tabListView
   local viewComponent = self:GetViewComponent()
   local oldCell = tabListView:getNodeAtIndex(self.curSelectTabIndex - 1)
   viewComponent:UpdateTabSelectState(oldCell, false)

   local cell = tabListView:getNodeAtIndex(clickIndex - 1)
   viewComponent:UpdateTabSelectState(cell, true)

   self.curSelectTabIndex = clickIndex

   viewComponent:UpdateGrideView(self:GetCurGoodsDatas())
end

--[[
商品点击回调
--]]
function Anniversary19ShopMeditaor:CommodityCallback( sender )
    PlayAudioByClickNormal()
    local tag = sender:getTag()
    local shopDatas = self:GetCurGoodsDatas()
    local tempdata  = clone(shopDatas[tag])
    if CommonUtils.CheckIsOwnSkinById(tempdata.goodsId) then
        uiMgr:ShowInformationTips(app.anniversary2019Mgr:GetPoText(__('已经拥有该皮肤')))
        return
    end
    tempdata.todayLeftPurchasedNum = tempdata.leftPurchasedNum
    local scene = uiMgr:GetCurrentScene()
    local marketPurchasePopup  = require('Game.views.ShopPurchasePopup').new({tag = 5001, mediatorName = "Anniversary19ShopMeditaor", data = tempdata, btnTag = tag,showChooseUi = true,})
    display.commonUIParams(marketPurchasePopup, {ap = cc.p(0.5, 0.5), po = cc.p(display.width * 0.5, display.height * 0.5)})
    marketPurchasePopup:setTag(5001)
    scene:AddDialog(marketPurchasePopup)
    marketPurchasePopup.viewData.purchaseBtn:setOnClickScriptHandler(handler(self, self.PurchaseBtnCallback))
    marketPurchasePopup.viewData.purchaseBtn:setTag(tag)
end

--[[
购买按钮点击回调
--]]
function Anniversary19ShopMeditaor:PurchaseBtnCallback( sender )
    PlayAudioByClickNormal()
    local tag = sender:getTag()
    local purchaseNum = sender:getUserTag()
    local shopDatas = self:GetCurGoodsDatas()
    local datas = shopDatas[tag] or {}
    
    local money = gameMgr:GetAmountByGoodId(checkint(datas.currency))
    local price = datas.price * checkint(purchaseNum)
    if datas.discount then--有折扣价格
        if checkint(datas.discount) < 100 and checkint(datas.discount) > 0 then
            price = datas.discount * data.price / 100 * checkint(purchaseNum)
        end
    end
    if checkint(money) >= checkint(price) then
        self:SendSignal(POST.ANNIVERSARY2_MALL_BUY.cmdName, {productId = datas.productId, num = checkint(purchaseNum)})
        -- app:DispatchObservers(POST.ANNIVERSARY2_MALL_BUY.sglName, {
        --     requestData = {productId = datas.productId, num = checkint(purchaseNum)},
        --     rewards = datas.rewards
        -- })
    else
        local currency = checkint(datas.currency)
        if GAME_MODULE_OPEN.NEW_STORE and currency == DIAMOND_ID then
            app.uiMgr:showDiamonTips()
        else
            local goodsConfig = CommonUtils.GetConfig('goods', 'goods', currency) or {}
            app.uiMgr:ShowInformationTips(string.format(app.anniversary2019Mgr:GetPoText(__('%s不足')), tostring(goodsConfig.name)))
        end
    end
end

function Anniversary19ShopMeditaor:OnRegist(  )
    regPost(POST.ANNIVERSARY2_MALL_BUY)
end

function Anniversary19ShopMeditaor:OnUnRegist(  )
    
    unregPost(POST.ANNIVERSARY2_MALL_BUY)

    local scene = uiMgr:GetCurrentScene()
    scene:RemoveDialog(self:GetViewComponent())
    
end

return Anniversary19ShopMeditaor

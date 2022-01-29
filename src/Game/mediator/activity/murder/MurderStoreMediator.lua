--[[
 * author : liuzhipeng
 * descpt : 杀人案（19夏活）商店（交换）Mediator
--]]
local Mediator = mvc.Mediator

local MurderStoreMediator = class("MurderStoreMediator", Mediator)

local NAME = "MurderStoreMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance('AppFacade'):GetManager("GameManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
local UnionShopGoodsCell = require('home.UnionShopGoodsCell')

function MurderStoreMediator:ctor( params, viewComponent )
    self.super:ctor(NAME,viewComponent)
    self.shopData = app.murderMgr:GetStoreData() 
end
-------------------------------------------------
-- inheritance method
function MurderStoreMediator:Initial( key )
    self.super.Initial(self,key)
    local scene = uiMgr:GetCurrentScene()
    local viewComponent  = require( 'Game.views.activity.murder.MurderStoreView' ).new()
    self:SetViewComponent(viewComponent)
    viewComponent:setPosition(display.center)
    scene:AddDialog(viewComponent)
    viewComponent:GetViewData().gridView:setDataSourceAdapterScriptHandler(handler(self,self.GoodsListDataSource))
	viewComponent:ReloadMoneyBar(app.murderMgr:GetStoreCurrency(), false)
    self:InitUi()
end

function MurderStoreMediator:InterestSignals()
    local signals = { 
        POST.MURDER_MALL_BUY.sglName,
        SIGNALNAMES.CACHE_MONEY_UPDATE_UI,
        SGL.REFRESH_NOT_CLOSE_GOODS_EVENT
    }

    return signals
end
function MurderStoreMediator:ProcessSignal( signal )
    local name = signal:GetName() 
    print(name)
    local data = signal:GetBody()
    if name == POST.MURDER_MALL_BUY.sglName then
        uiMgr:AddDialog('common.RewardPopup', {rewards = data.rewards})
        local itemData = {}
        for i,v in ipairs(self.shopData) do
            if checkint(v.id) == checkint(data.requestData.shopId) then
                self.shopData[i].leftPurchasedNum = v.leftPurchasedNum - data.requestData.num
                itemData = clone(v)
                break
            end
        end
        local consume = {}
        if checkint(itemData.discount) < 100 and checkint(itemData.discount) > 0 then
            itemData.price = itemData.price * itemData.discount / 100
        end
        local consumeNum = -itemData.price * checkint(data.requestData.num or 1)
        table.insert(consume,{goodsId = itemData.currency, num = consumeNum})
        CommonUtils.DrawRewards(consume)
        app.murderMgr:StoreBuyItems(data.requestData.shopId, data.requestData.num)
        self:GetViewComponent():GetViewData().gridView:reloadData()
        local scene = uiMgr:GetCurrentScene()
        if scene:GetDialogByTag( 5001 ) then
            scene:GetDialogByTag( 5001 ):runAction(cc.RemoveSelf:create())--购买详情弹出框
        end
    elseif name == SIGNALNAMES.CACHE_MONEY_UPDATE_UI then
        self:UpdateMoneyBar()
    elseif name == SGL.REFRESH_NOT_CLOSE_GOODS_EVENT then
        self:UpdateMoneyBar()
    end
end
function MurderStoreMediator:OnRegist(  )
    regPost(POST.MURDER_MALL_BUY)
end

function MurderStoreMediator:OnUnRegist(  )
    -- 移除界面
	local scene = app.uiMgr:GetCurrentScene()
    scene:RemoveDialog(self:GetViewComponent())
    unregPost(POST.MURDER_MALL_BUY)
end
-------------------------------------------------
-- handler method
--[[
商品点击回调
--]]
function MurderStoreMediator:CommodityCallback( sender )
    PlayAudioByClickNormal()
    local tag = sender:getTag()
    local tempdata  = clone(self.shopData[tag])
    if tempdata.leftPurchasedNum < 0 or tempdata.stock < 0 then
        tempdata.leftPurchasedNum = - 1
        tempdata.stock = - 1
    end
    if CommonUtils.CheckIsOwnSkinById(tempdata.goodsId) then
        uiMgr:ShowInformationTips(app.murderMgr:GetPoText(__('已经拥有该皮肤')))
        return
    end
    tempdata.todayLeftPurchasedNum = tempdata.leftPurchasedNum
    local scene = uiMgr:GetCurrentScene()
    local marketPurchasePopup  = require('Game.views.ShopPurchasePopup').new({tag = 5001, mediatorName = "MurderStoreMediator", data = tempdata, btnTag = tag,showChooseUi = true,})
    display.commonUIParams(marketPurchasePopup, {ap = cc.p(0.5, 0.5), po = cc.p(display.width * 0.5, display.height * 0.5)})
    marketPurchasePopup:setTag(5001)
    scene:AddDialog(marketPurchasePopup)
    marketPurchasePopup.viewData.purchaseBtn:setOnClickScriptHandler(handler(self, self.PurchaseBtnCallback))
    marketPurchasePopup.viewData.purchaseBtn:setTag(tag)
end
--[[
购买按钮点击回调
--]]
function MurderStoreMediator:PurchaseBtnCallback( sender )
    PlayAudioByClickNormal()
    local tag = sender:getTag()
    local purchaseNum = sender:getUserTag()
    local datas = self.shopData[tag]
    local money = 0
    local des = app.murderMgr:GetPoText(__('货币'))
    if checkint(datas.currency) == GOLD_ID then --金币
        des = app.murderMgr:GetPoText(__('金币'))
        money = gameMgr:GetUserInfo().gold
    elseif checkint(datas.currency) == DIAMOND_ID then -- 幻晶石
        des = app.murderMgr:GetPoText(__('幻晶石'))
        money = gameMgr:GetUserInfo().diamond
    elseif checkint(datas.currency) == TIPPING_ID then -- 小费
        des = app.murderMgr:GetPoText(__('小费'))
        money = gameMgr:GetUserInfo().tip
    elseif checkint(datas.currency) == UNION_POINT_ID then
        des = app.murderMgr:GetPoText(__('工会徽章'))
        money = checkint(gameMgr:GetUserInfo().unionPoint)
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
        self:SendSignal(POST.MURDER_MALL_BUY.cmdName,{shopId = datas.id,num = checkint(purchaseNum)})
    else
        if GAME_MODULE_OPEN.NEW_STORE and checkint(datas.currency) == DIAMOND_ID then
            app.uiMgr:showDiamonTips()
        else
            uiMgr:ShowInformationTips(string.fmt(app.murderMgr:GetPoText(__('_des_不足')),{_des_ = des}))
        end
    end
end
-------------------------------------------------
-- get /set

-------------------------------------------------
-- private method
--[[
初始化ui
--]]
function MurderStoreMediator:InitUi()
    local viewData = self:GetViewComponent():GetViewData()
    viewData.gridView:setCountOfCell(table.nums(self.shopData))
    viewData.gridView:reloadData()
end
--[[
列表处理
--]]
function MurderStoreMediator:GoodsListDataSource( p_convertview, idx )
    local pCell = p_convertview
    local index = idx + 1
    local cSize = self:GetViewComponent():GetViewData().listCellSize
    if pCell == nil then
        pCell = UnionShopGoodsCell.new(cSize)
        pCell.bgBtn:setOnClickScriptHandler(handler(self, self.CommodityCallback))
    end
    xTry(function()
        local datas = self.shopData[index]
        local goodsDatas = CommonUtils.GetConfig('goods', 'goods', datas.goodsId) or {}
        pCell.goodsIcon:RefreshSelf({goodsId = datas.goodsId, num = datas.goodsNum, showAmount = true})
        pCell.goodsName:setString(tostring(goodsDatas.name))
        pCell.stockLabel:setString(string.fmt(app.murderMgr:GetPoText(__('库存:_num_')), {['_num_'] = tostring(datas.leftPurchasedNum)}))
        display.reloadRichLabel(pCell.priceLabel, { c = {
            {text = tostring(datas.price) .. '  ',fontSize = 22, color = '#ffffff', font = TTF_GAME_FONT, ttf = true},
            {img = CommonUtils.GetGoodsIconPathById(checkint(datas.currency)), scale = 0.18}
        }})
        if checkint(datas.leftPurchasedNum) < 0 then
            pCell.bgBtn:setNormalImage(app.murderMgr:GetResPath('ui/home/commonShop/shop_btn_goods_default.png'))
            pCell.bgBtn:setSelectedImage(app.murderMgr:GetResPath('ui/home/commonShop/shop_btn_goods_default.png'))
            pCell.bgBtn:setEnabled(true)
            pCell.sellOut:setVisible(false)
            pCell.lockMask:setVisible(false)
            pCell.stockLabel:setVisible(false)
        elseif checkint(datas.leftPurchasedNum) > 0 then
            pCell.bgBtn:setNormalImage(app.murderMgr:GetResPath('ui/home/commonShop/shop_btn_goods_default.png'))
            pCell.bgBtn:setSelectedImage(app.murderMgr:GetResPath('ui/home/commonShop/shop_btn_goods_default.png'))
            pCell.bgBtn:setEnabled(true)
            pCell.sellOut:setVisible(false)
            pCell.lockMask:setVisible(false)
            pCell.stockLabel:setVisible(true)
        else
            pCell.bgBtn:setNormalImage(app.murderMgr:GetResPath('ui/home/commonShop/shop_btn_goods_sellout.png'))
            pCell.bgBtn:setSelectedImage(app.murderMgr:GetResPath('ui/home/commonShop/shop_btn_goods_sellout.png'))
            pCell.bgBtn:setEnabled(false)
            pCell.sellOut:setVisible(true)
            pCell.lockMask:setVisible(true)
            pCell.stockLabel:setVisible(false)
        end
        pCell.bgBtn:setTag(index)
    end,__G__TRACKBACK__)
    return pCell
end

--更新货币栏
function MurderStoreMediator:UpdateMoneyBar()
    if not self:GetViewComponent() then return end
    self:GetViewComponent():UpdateMoneyBar()
end
-------------------------------------------------
-- public method


return MurderStoreMediator

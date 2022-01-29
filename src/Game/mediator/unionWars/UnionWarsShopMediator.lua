--[[
工会商店Mediator
--]]
local Mediator = mvc.Mediator

local UnionWarsShopMediator = class("UnionWarsShopMediator", Mediator)

local NAME = "unionWars.UnionWarsShopMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance('AppFacade'):GetManager("GameManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
local unionMgr = AppFacade.GetInstance():GetManager("UnionManager")
local scheduler = require('cocos.framework.scheduler')
local UnionShopGoodsCell = require('home.UnionShopGoodsCell')

function UnionWarsShopMediator:ctor( params, viewComponent )
    self.super:ctor(NAME,viewComponent)
    self.args = checktable(params) or {}
end

function UnionWarsShopMediator:InterestSignals()
    local signals = { 
        POST.UNION_WARS_MALL.sglName,
        POST.UNION_WARS_MALL_BUY.sglName,
        POST.UNION_WARS_MALL_REFRESH.sglName,
        SGL.REFRESH_NOT_CLOSE_GOODS_EVENT,
        SIGNALNAMES.CACHE_MONEY_UPDATE_UI
    }

    return signals
end

function UnionWarsShopMediator:ProcessSignal( signal )
    local name = signal:GetName() 
    print(name)
    local datas = signal:GetBody()
    if name == POST.UNION_WARS_MALL.sglName then
        self.shopDatas = datas
        self:InitUi()
    elseif name == POST.UNION_WARS_MALL_BUY.sglName then
        uiMgr:AddDialog('common.RewardPopup', {rewards = datas.rewards})
        local data = {}
        for i,v in ipairs(self.shopDatas.products) do
            if checkint(v.productId) == checkint(datas.requestData.productId) then
                self.shopDatas.products[i].leftPurchasedNum = v.leftPurchasedNum - datas.requestData.num
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
        self:GetViewComponent().viewData_.gridView:reloadData()
        local scene = uiMgr:GetCurrentScene()
        if scene:GetDialogByTag( 5001 ) then
            scene:GetDialogByTag( 5001 ):runAction(cc.RemoveSelf:create())--购买详情弹出框
        end
    elseif name == POST.UNION_WARS_MALL_REFRESH.sglName then
        gameMgr:GetUserInfo().diamond = signal:GetBody().diamond
        self:GetFacade():DispatchObservers(SIGNALNAMES.CACHE_MONEY_UPDATE_UI,{gold = signal:GetBody().gold,diamond = signal:GetBody().diamond})
        self.shopDatas.refreshLeftTimes = checkint(self.shopDatas.refreshLeftTimes) - 1
        self:GetViewComponent().viewData_.leftRefreshTime:setString(string.fmt(__('今日剩余刷新次数:_num_'), {['_num_'] = self.shopDatas.refreshLeftTimes}))
        self:RefreshGoodsStock()
    elseif name == SGL.REFRESH_NOT_CLOSE_GOODS_EVENT then
        self:UpdateCountUI()
    elseif name == SIGNALNAMES.CACHE_MONEY_UPDATE_UI then
        self:UpdateCountUI()
    end
end
function UnionWarsShopMediator:Initial( key )
    self.super.Initial(self,key)
    local scene = uiMgr:GetCurrentScene()
    local viewComponent  = require( 'Game.views.unionWars.UnionWarsShopView' ).new()
    self:SetViewComponent(viewComponent)
    viewComponent:setPosition(display.center)
    -- scene:AddGameLayer(viewComponent)
    scene:AddDialog(viewComponent)
    viewComponent.viewData_.gridView:setDataSourceAdapterScriptHandler(handler(self,self.GoodsListDataSource))
    viewComponent.viewData_.refreshBtn:setOnClickScriptHandler(handler(self, self.RefreshButtonCallback))
    display.commonUIParams(viewComponent.viewData_.batchBuyBtn, {cb = handler(self, self.onClickBatchBuyButtonHandler_)})
    display.commonUIParams(viewComponent.eaterLayer, {cb = handler(self, self.OnClickEaterLayerAction), animate = false})
    self:UpdateCountUI()
end
function UnionWarsShopMediator:InitUi()
    local viewData = self:GetViewComponent().viewData_
    viewData.timeLabel:setString(string.fmt(__('系统刷新倒计时:_time_'), {['_time_'] = string.formattedTime(self.shopDatas.nextRefreshLeftSeconds,'%02i:%02i:%02i')}))
    viewData.leftRefreshTime:setString(string.fmt(__('今日剩余刷新次数:_num_'), {['_num_'] = self.shopDatas.refreshLeftTimes}))
    display.reloadRichLabel(viewData.refreshCostLabel, {c = {
        fontWithColor(16, {text = tostring(self.shopDatas.refreshDiamond)}),
        {img = CommonUtils.GetGoodsIconPathById(DIAMOND_ID), scale = 0.18}
    }})
    self:UpdateLeftTimeScheduler()

    local products = self.shopDatas.products
    viewData.gridView:setCountOfCell(#products)
    viewData.gridView:reloadData()

    local tempData = products[1] or {}
    local currency = checkint(tempData.currency)
    local args = {}
    if currency > 0 then
        args.moneyIdMap = {}
        args.moneyIdMap[tostring(HP_ID)] = HP_ID
        args.moneyIdMap[tostring(currency)] = currency
    end
    self:GetViewComponent():UpdateMoneyBarGoodList(args)
end
--[[
创建倒计时定时器
--]]
function UnionWarsShopMediator:UpdateLeftTimeScheduler()
    local startTime = checkint(os.time())
    if self.leftTimeScheduler then
        scheduler.unscheduleGlobal(self.leftTimeScheduler)
    end
    self.leftTimeScheduler = scheduler.scheduleGlobal(function()
        local curTime =  os.time()
        local distance = curTime - startTime
        local curLeftTime = self.shopDatas.nextRefreshLeftSeconds
        startTime = curTime
        if checkint(self.shopDatas.nextRefreshLeftSeconds) > 0 then
            self.shopDatas.nextRefreshLeftSeconds  =  checkint(self.shopDatas.nextRefreshLeftSeconds) - distance
        end
        self:GetViewComponent().viewData_.timeLabel:setString(string.fmt(__('系统刷新倒计时:_time_'), {['_time_'] = string.formattedTime(self.shopDatas.nextRefreshLeftSeconds,'%02i:%02i:%02i')}))
        if self.shopDatas.nextRefreshLeftSeconds <= 0 then
            self:SendSignal(POST.UNION_WARS_MALL.cmdName)

            if app:RetrieveMediator('MultiBuyMediator') then
                app:RetrieveMediator('MultiBuyMediator'):close()
            end    
        end
    end, 1, false)
end

--[[
列表处理
--]]
function UnionWarsShopMediator:GoodsListDataSource( p_convertview, idx )
    local pCell = p_convertview
    local index = idx + 1
    local cSize = self:GetViewComponent().viewData_.listCellSize
    if pCell == nil then
        pCell = UnionShopGoodsCell.new(cSize)
        pCell.bgBtn:setOnClickScriptHandler(handler(self, self.CommodityCallback))
    end
    xTry(function()
        local datas = self.shopDatas.products[index]
        local goodsDatas = CommonUtils.GetConfig('goods', 'goods', datas.goodsId) or {}
        pCell.goodsIcon:RefreshSelf({goodsId = datas.goodsId, num = datas.goodsNum, showAmount = true})
        pCell.goodsName:setString(tostring(goodsDatas.name))
        pCell.stockLabel:setString(string.fmt(__('库存:_num_'), {['_num_'] = tostring(datas.leftPurchasedNum)}))
        display.reloadRichLabel(pCell.priceLabel, { c = {
            fontWithColor(7, {text = tostring(datas.price) .. '  ',fontSize = 22}),
            {img = CommonUtils.GetGoodsIconPathById(checkint(datas.currency)), scale = 0.18}
        }})
        
        if checkint(datas.leftPurchasedNum) > 0 then
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
        -- 判断是否解锁
        local unionHomeData = checktable(unionMgr:getUnionData())
        local unlockTypeDatas = CommonUtils.GetConfigAllMess('unlockType')
        if datas.unlockType then
            -- if datas.unlockType[tostring(UnlockTypes.UNION_PLAYER_CONTRIBUTIONPOINT)] then
            --     local targetNum = checkint(datas.unlockType[tostring(UnlockTypes.UNION_PLAYER_CONTRIBUTIONPOINT)].targetNum)
            --     local unlockDescr = tostring(unlockTypeDatas[tostring(UnlockTypes.UNION_PLAYER_CONTRIBUTIONPOINT)])
            --     if targetNum > checkint(unionHomeData.playerContributionPoint) then
            --         pCell.bgBtn:setEnabled(false)
            --         local lockStr = string.gsub(unlockDescr, '_target_num_', tostring(targetNum))
            --         display.reloadRichLabel(pCell.priceLabel, { c = {
            --             {text = __('需要'),fontSize = 22, color = '#ffffff', font = TTF_GAME_FONT, ttf = true},
            --             {text = lockStr,fontSize = 22, color = '#ffd987', font = TTF_GAME_FONT, ttf = true, outline = '#5b3c25', outlineSize = 1},
            --         }})
            --     end
            -- end
            if datas.unlockType[tostring(UnlockTypes.UNION_LEVEL)] then
                local targetNum = checkint(datas.unlockType[tostring(UnlockTypes.UNION_LEVEL)].targetNum)
                local unlockDescr = tostring(unlockTypeDatas[tostring(UnlockTypes.UNION_LEVEL)])
                if targetNum > checkint(unionHomeData.level) then
                    pCell.lockMask:setVisible(true)
                    pCell.lockLabel:setVisible(true)
                    pCell.bgBtn:setEnabled(false)
                    local lockStr = string.gsub(unlockDescr, '_target_num_', tostring(targetNum))
                    pCell.lockLabel:getLabel():setString(lockStr)
                else
                    pCell.lockMask:setVisible(false)
                    pCell.lockLabel:setVisible(false)
                end
            end
        else
            pCell.lockMask:setVisible(false)
            pCell.lockLabel:setVisible(false)
        end
        pCell.bgBtn:setTag(index)
    end,__G__TRACKBACK__)
    return pCell
end
--[[
刷新按钮点击回调
--]]
function UnionWarsShopMediator:RefreshButtonCallback( sender )
    PlayAudioByClickNormal()
    if checkint(self.shopDatas.refreshLeftTimes) > 0 then
        local CommonTip  = require( 'common.NewCommonTip' ).new({text = string.format(__('是否使用%s个幻晶石进行商店刷新?'), self.shopDatas.refreshDiamond),
            isOnlyOK = false, callback = function ()
				self:SendSignal(POST.UNION_WARS_MALL_REFRESH.cmdName)
			end})
		CommonTip:setPosition(display.center)
		local scene = uiMgr:GetCurrentScene()
		scene:AddDialog(CommonTip)
    else
        uiMgr:ShowInformationTips(__('刷新次数已用完'))
    end
end

function UnionWarsShopMediator:onClickBatchBuyButtonHandler_(sender)
	PlayAudioByClickNormal()
    app:RegistMediator(require('Game.mediator.stores.MultiBuyMediator').new({
		products = self.shopDatas.products,
        postCmd  = POST.UNION_WARS_MALL_BUY_MULTI,
        refreshCB = function()
            local viewData = self:GetViewComponent().viewData_
            viewData.gridView:reloadData()
        end
	}))
end

function UnionWarsShopMediator:OnClickEaterLayerAction(sender)
    app:UnRegsitMediator(NAME)
end

--[[
刷新商品库存
--]]
function UnionWarsShopMediator:RefreshGoodsStock()
    local viewData = self:GetViewComponent().viewData_
    for i,v in ipairs(self.shopDatas.products) do
        v.leftPurchasedNum = v.stock
    end
    viewData.gridView:reloadData()
end
--[[
商品点击回调
--]]
function UnionWarsShopMediator:CommodityCallback( sender )
    PlayAudioByClickNormal()
    local tag = sender:getTag()
    local tempdata  = clone(self.shopDatas.products[tag])
    if CommonUtils.CheckIsOwnSkinById(tempdata.goodsId) then
        uiMgr:ShowInformationTips(__('已经拥有该皮肤'))
        return
    end
    tempdata.todayLeftPurchasedNum = tempdata.leftPurchasedNum
    local scene = uiMgr:GetCurrentScene()
    local marketPurchasePopup  = require('Game.views.ShopPurchasePopup').new({tag = 5001, mediatorName = "UnionWarsShopMediator", data = tempdata, btnTag = tag,showChooseUi = true,})
    display.commonUIParams(marketPurchasePopup, {ap = cc.p(0.5, 0.5), po = cc.p(display.width * 0.5, display.height * 0.5)})
    marketPurchasePopup:setTag(5001)
    scene:AddDialog(marketPurchasePopup)
    marketPurchasePopup.viewData.purchaseBtn:setOnClickScriptHandler(handler(self, self.PurchaseBtnCallback))
    marketPurchasePopup.viewData.purchaseBtn:setTag(tag)
end
--[[
购买按钮点击回调
--]]
function UnionWarsShopMediator:PurchaseBtnCallback( sender )
    PlayAudioByClickNormal()
    local tag = sender:getTag()
    local purchaseNum = sender:getUserTag()
    local datas = self.shopDatas.products[tag]
    local currency = datas.currency
    local goodsConfig = CommonUtils.GetConfig('goods', 'goods', currency) or {}
    local des = goodsConfig.name or __('货币')
    local money = gameMgr:GetAmountByIdForce(currency)
    
    local price = datas.price * checkint(purchaseNum)
    if datas.discount  then--有折扣价格
        if checkint(datas.discount) < 100 and checkint(datas.discount) > 0 then
            price = datas.discount * data.price / 100 * checkint(purchaseNum)
        end
    end
    if checkint(money) >= checkint(price) then
        self:SendSignal(POST.UNION_WARS_MALL_BUY.cmdName,{productId = datas.productId, num = checkint(purchaseNum)})
    else
        if GAME_MODULE_OPEN.NEW_STORE and checkint(datas.currency) == DIAMOND_ID then
            app.uiMgr:showDiamonTips()
        else
            uiMgr:ShowInformationTips(string.fmt(__('_des_不足'),{_des_ = des}))
        end
    end
end
--更新数量ui值
function UnionWarsShopMediator:UpdateCountUI()
    local viewComponent = self:GetViewComponent()
    if not viewComponent then return end
    viewComponent:UpdateMoneyBarGoodNum()
end
function UnionWarsShopMediator:EnterLayer()
    self:SendSignal(POST.UNION_WARS_MALL.cmdName)
end
function UnionWarsShopMediator:OnRegist(  )
    regPost(POST.UNION_WARS_MALL)
    regPost(POST.UNION_WARS_MALL_BUY)
    regPost(POST.UNION_WARS_MALL_REFRESH)
    self:EnterLayer()
end

function UnionWarsShopMediator:OnUnRegist(  )
    if self.leftTimeScheduler then
        scheduler.unscheduleGlobal(self.leftTimeScheduler)
        self.leftTimeScheduler = nil
    end
    
    unregPost(POST.UNION_WARS_MALL)
    unregPost(POST.UNION_WARS_MALL_BUY)
    unregPost(POST.UNION_WARS_MALL_REFRESH)
    if self.viewComponent then
        self.viewComponent:runAction(cc.RemoveSelf:create())
        self.viewComponent = nil
    end
end

return UnionWarsShopMediator

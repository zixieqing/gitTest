--[[
工会商店Mediator
--]]
local Mediator = mvc.Mediator

local UnionShopMediator = class("UnionShopMediator", Mediator)

local NAME = "UnionShopMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance('AppFacade'):GetManager("GameManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
local unionMgr = AppFacade.GetInstance():GetManager("UnionManager")
local scheduler = require('cocos.framework.scheduler')
local UnionShopGoodsCell = require('home.UnionShopGoodsCell')

function UnionShopMediator:ctor( params, viewComponent )
    self.super:ctor(NAME,viewComponent)
    self.args = checktable(params) or {}
end
function UnionShopMediator:InterestSignals()
    local signals = {
        POST.UNION_MALL.sglName,
        POST.UNION_MALL_BUY.sglName,
        POST.UNION_MALL_REFRESH.sglName,
        SGL.REFRESH_NOT_CLOSE_GOODS_EVENT,
        SIGNALNAMES.CACHE_MONEY_UPDATE_UI
    }

    return signals
end
function UnionShopMediator:ProcessSignal( signal )
    local name = signal:GetName()
    print(name)
    local datas = signal:GetBody()
    if name == POST.UNION_MALL.sglName then
        self.shopDatas = datas
        if datas.unionPoint then
            gameMgr:GetUserInfo().unionPoint = checkint(datas.unionPoint)
            self:UpdateCountUI()
        end
        self:InitUi()
    elseif name == POST.UNION_MALL_BUY.sglName then
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
            if checkint(data.currency) == checkint(GOLD_ID) then
                local goldNum = -data.price * checkint(datas.requestData.num or 1)
                table.insert(Trewards,{goodsId = GOLD_ID, num = goldNum})
            elseif checkint(data.currency) == checkint(DIAMOND_ID) then
                local diamondNum = -data.price * checkint(datas.requestData.num or 1)
                table.insert(Trewards,{goodsId = DIAMOND_ID, num = diamondNum})
            elseif checkint(data.currency) == checkint(TIPPING_ID) then
                local tipNum = -data.price * checkint(datas.requestData.num or 1)
                table.insert(Trewards,{goodsId = TIPPING_ID, num = tipNum})
            elseif checkint(data.currency) == checkint(UNION_POINT_ID) then
                local unionPointNum = -data.price * checkint(datas.requestData.num or 1)
                table.insert(Trewards, {goodsId = UNION_POINT_ID, num = unionPointNum})
            end
        end
        CommonUtils.DrawRewards(Trewards)
        self:GetViewComponent().viewData_.gridView:reloadData()
        local scene = uiMgr:GetCurrentScene()
        if scene:GetDialogByTag( 5001 ) then
            scene:GetDialogByTag( 5001 ):runAction(cc.RemoveSelf:create())--购买详情弹出框
        end
    elseif name == POST.UNION_MALL_REFRESH.sglName then
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
function UnionShopMediator:Initial( key )
    self.super.Initial(self,key)
    local scene = uiMgr:GetCurrentScene()
    local viewComponent  = require( 'Game.views.UnionShopView' ).new()
    self:SetViewComponent(viewComponent)
    viewComponent:setPosition(display.center)
    -- scene:AddGameLayer(viewComponent)
    scene:AddDialog(viewComponent)
    viewComponent.viewData_.gridView:setDataSourceAdapterScriptHandler(handler(self,self.GoodsListDataSource))
    viewComponent.viewData_.refreshBtn:setOnClickScriptHandler(handler(self, self.RefreshButtonCallback))
    display.commonUIParams(viewComponent.viewData_.batchBuyBtn, {cb = handler(self, self.onClickBatchBuyButtonHandler_)})
    self:UpdateCountUI()
end
function UnionShopMediator:InitUi()
    local viewData = self:GetViewComponent().viewData_
    viewData.timeLabel:setString(string.fmt(__('系统刷新倒计时:_time_'), {['_time_'] = string.formattedTime(self.shopDatas.nextRefreshLeftSeconds,'%02i:%02i:%02i')}))
    viewData.leftRefreshTime:setString(string.fmt(__('今日剩余刷新次数:_num_'), {['_num_'] = self.shopDatas.refreshLeftTimes}))
    display.reloadRichLabel(viewData.refreshCostLabel, {c = {
        fontWithColor(16, {text = tostring(self.shopDatas.refreshDiamond)}),
        {img = CommonUtils.GetGoodsIconPathById(DIAMOND_ID), scale = 0.18}
    }})
    self:UpdateLeftTimeScheduler()
    viewData.gridView:setCountOfCell(table.nums(self.shopDatas.products))
    viewData.gridView:reloadData()

end
--[[
创建倒计时定时器
--]]
function UnionShopMediator:UpdateLeftTimeScheduler()
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
            self:SendSignal(POST.UNION_MALL.cmdName)
            
            if app:RetrieveMediator('MultiBuyMediator') then
                app:RetrieveMediator('MultiBuyMediator'):close()
            end    
        end
    end, 1, false)
end

--[[
列表处理
--]]
function UnionShopMediator:GoodsListDataSource( p_convertview, idx )
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
            {text = tostring(datas.price) .. '  ',fontSize = 22, color = '#ffffff', font = TTF_GAME_FONT, ttf = true},
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
            if datas.unlockType[tostring(UnlockTypes.UNION_PLAYER_CONTRIBUTIONPOINT)] then
                local targetNum = checkint(datas.unlockType[tostring(UnlockTypes.UNION_PLAYER_CONTRIBUTIONPOINT)].targetNum)
                local unlockDescr = tostring(unlockTypeDatas[tostring(UnlockTypes.UNION_PLAYER_CONTRIBUTIONPOINT)])
                if targetNum > checkint(unionHomeData.playerContributionPoint) then
                    pCell.bgBtn:setEnabled(false)
                    local lockStr = string.gsub(unlockDescr, '_target_num_', tostring(targetNum))
                    display.reloadRichLabel(pCell.priceLabel, { c = {
                        {text = __('需要'),fontSize = 22, color = '#ffffff', font = TTF_GAME_FONT, ttf = true},
                        {text = lockStr,fontSize = 22, color = '#ffd987', font = TTF_GAME_FONT, ttf = true, outline = '#5b3c25', outlineSize = 1},
                    }})
                end
            end
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
        display.commonLabelParams(pCell.lockLabel , {reqW =170})
    end,__G__TRACKBACK__)
    return pCell
end
--[[
刷新按钮点击回调
--]]
function UnionShopMediator:RefreshButtonCallback( sender )
    PlayAudioByClickNormal()
    if checkint(self.shopDatas.refreshLeftTimes) > 0 then
        local CommonTip  = require( 'common.NewCommonTip' ).new({text = string.format(__('是否使用%s个幻晶石进行商店刷新?'), self.shopDatas.refreshDiamond),
            isOnlyOK = false, callback = function ()
				self:SendSignal(POST.UNION_MALL_REFRESH.cmdName)
			end})
		CommonTip:setPosition(display.center)
		local scene = uiMgr:GetCurrentScene()
		scene:AddDialog(CommonTip)
    else
        uiMgr:ShowInformationTips(__('刷新次数已用完'))
    end
end

function UnionShopMediator:onClickBatchBuyButtonHandler_(sender)
	PlayAudioByClickNormal()
    app:RegistMediator(require('Game.mediator.stores.MultiBuyMediator').new({
		products  = self.shopDatas.products,
        postCmd   = POST.UNION_MALL_BUY_MULTI,
        refreshCB = function()
            local viewData = self:GetViewComponent().viewData_
            viewData.gridView:reloadData()
        end
	}))
end

--[[
刷新商品库存
--]]
function UnionShopMediator:RefreshGoodsStock()
    local viewData = self:GetViewComponent().viewData_
    for i,v in ipairs(self.shopDatas.products) do
        v.leftPurchasedNum = v.stock
    end
    viewData.gridView:reloadData()
end
--[[
商品点击回调
--]]
function UnionShopMediator:CommodityCallback( sender )
    PlayAudioByClickNormal()
    local tag = sender:getTag()
    local tempdata  = clone(self.shopDatas.products[tag])
    if CommonUtils.CheckIsOwnSkinById(tempdata.goodsId) then
        uiMgr:ShowInformationTips(__('已经拥有该皮肤'))
        return
    end
    tempdata.todayLeftPurchasedNum = tempdata.leftPurchasedNum
    local scene = uiMgr:GetCurrentScene()
    local marketPurchasePopup  = require('Game.views.ShopPurchasePopup').new({tag = 5001, mediatorName = "UnionShopMediator", data = tempdata, btnTag = tag,showChooseUi = true,})
    display.commonUIParams(marketPurchasePopup, {ap = cc.p(0.5, 0.5), po = cc.p(display.width * 0.5, display.height * 0.5)})
    marketPurchasePopup:setTag(5001)
    scene:AddDialog(marketPurchasePopup)
    marketPurchasePopup.viewData.purchaseBtn:setOnClickScriptHandler(handler(self, self.PurchaseBtnCallback))
    marketPurchasePopup.viewData.purchaseBtn:setTag(tag)
end
--[[
购买按钮点击回调
--]]
function UnionShopMediator:PurchaseBtnCallback( sender )
    PlayAudioByClickNormal()
    local tag = sender:getTag()
    local purchaseNum = sender:getUserTag()
    local datas = self.shopDatas.products[tag]
    local money = 0
    local des = __('货币')
    if checkint(datas.currency) == GOLD_ID then --金币
        des = __('金币')
        money = gameMgr:GetUserInfo().gold
    elseif checkint(datas.currency) == DIAMOND_ID then -- 幻晶石
        des = __('幻晶石')
        money = gameMgr:GetUserInfo().diamond
    elseif checkint(datas.currency) == TIPPING_ID then -- 小费
        des = __('小费')
        money = gameMgr:GetUserInfo().tip
    elseif checkint(datas.currency) == UNION_POINT_ID then
        des = __('工会徽章')
        money = checkint(gameMgr:GetUserInfo().unionPoint)
    end
    local price = datas.price * checkint(purchaseNum)
    if datas.discount  then--有折扣价格
        if checkint(datas.discount) < 100 and checkint(datas.discount) > 0 then
            price = datas.discount * data.price / 100 * checkint(purchaseNum)
        end
    end
    if checkint(money) >= checkint(price) then
        self:SendSignal(POST.UNION_MALL_BUY.cmdName,{productId = datas.productId,num = checkint(purchaseNum)})
    else
        if GAME_MODULE_OPEN.NEW_STORE and checkint(datas.currency) == DIAMOND_ID then
            app.uiMgr:showDiamonTips()
        else
            uiMgr:ShowInformationTips(string.fmt(__('_des_不足'),{_des_ = des}))
        end
    end
end
--更新数量ui值
function UnionShopMediator:UpdateCountUI()
    if not self:GetViewComponent() then return end
    local viewData = self:GetViewComponent().viewData_
    if viewData.moneyNods then
        for id,v in pairs(viewData.moneyNods) do
            v:updataUi(checkint(id)) --刷新每一个金币数量
            v:setControllable(checkint(id) ~= DIAMOND_ID)
        end
    end
end
function UnionShopMediator:EnterLayer()
    self:SendSignal(POST.UNION_MALL.cmdName)
end
function UnionShopMediator:OnRegist(  )
    regPost(POST.UNION_MALL)
    regPost(POST.UNION_MALL_BUY)
    regPost(POST.UNION_MALL_REFRESH)
    self:EnterLayer()
end

function UnionShopMediator:OnUnRegist(  )
    local scene = uiMgr:GetCurrentScene()
    scene:RemoveGameLayer(self.viewComponent)
    --local mediator = AppFacade.GetInstance():RetrieveMediator("UnionLobbyMediator")
    --if not  mediator then
    --    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "show")
    --    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "rightHide")
    --end
    if self.leftTimeScheduler then
        scheduler.unscheduleGlobal(self.leftTimeScheduler)
    end
    unregPost(POST.UNION_MALL)
    unregPost(POST.UNION_MALL_BUY)
    unregPost(POST.UNION_MALL_REFRESH)
    self:GetViewComponent():runAction(cc.RemoveSelf:create())
end

return UnionShopMediator

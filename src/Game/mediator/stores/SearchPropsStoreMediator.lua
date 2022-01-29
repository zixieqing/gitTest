--[[
 * author : kaishiqi
 * descpt : 新游戏商店 - 搜索道具中介者
]]
local SearchPropsStoreView     = require('Game.views.stores.SearchPropsStoreView')
local SearchPropsStoreMediator = class('SearchPropsStoreMediator', mvc.Mediator)

function SearchPropsStoreMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'SearchPropsStoreMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end


-------------------------------------------------
-- inheritance method

function SearchPropsStoreMediator:Initial(key)
    self.super.Initial(self, key)

    -- init vars
    self.ownerNode_          = self.ctorArgs_.ownerNode
    self.giftsGoodsNodeList_ = {}
    self.propsGoodsNodeList_ = {}
    self.isControllable_     = true

    -- create view
    if self.ownerNode_ then
        self.storesView_ = SearchPropsStoreView.new(self.ownerNode_:getContentSize())
        self.ownerNode_:addChild(self.storesView_)
    end
end


function SearchPropsStoreMediator:CleanupView()
    if self.storesView_  and (not tolua.isnull(self.storesView_)) then
        self.storesView_:runAction(cc.RemoveSelf:create())
        self.storesView_ = nil
    end
end


function SearchPropsStoreMediator:OnRegist()
    regPost(POST.GAME_STORE_BUY)
end


function SearchPropsStoreMediator:OnUnRegist()
    unregPost(POST.GAME_STORE_BUY)
    self:stopGiftsCountdownUpdate_()
    self:stopPropsCountdownUpdate_()
end


function SearchPropsStoreMediator:InterestSignals()
    return {
        SGL.Restaurant_Shop_GetPayOrder_Callback,
        EVENT_PAY_MONEY_SUCCESS_UI,
        POST.GAME_STORE_BUY.sglName,
    }
end
function SearchPropsStoreMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()

    if name == POST.GAME_STORE_BUY.sglName then

        -- update purchase num
        local goodsBuyNum    = checkint(data.requestData.num)
        local goodsIndex     = checkint(data.requestData.goodsIndex)
        local goodsData      = self:getPropsGoodsData()[goodsIndex] or {}
        local totalPurchased = checkint(goodsData.lifeLeftPurchasedNum)
        local todayPurchased = checkint(goodsData.todayLeftPurchasedNum)
        if totalPurchased > 0 then
            goodsData.lifeLeftPurchasedNum = math.max(totalPurchased - goodsBuyNum, 0)
        end
        if todayPurchased > 0 then
            goodsData.todayLeftPurchasedNum = math.max(todayPurchased - goodsBuyNum, 0)
        end

        -- consume currency
        local currencyId = checkint(data.requestData.currencyId)
        local consumeNum = checkint(data.requestData.consumeNum)
        CommonUtils.DrawRewards({{goodsId = currencyId, num = -consumeNum}})

        -- close storePurchasePopup
        local storePurchasePopup = app.uiMgr:GetCurrentScene():GetDialogByTag(GAME_STORE_PURCHASE_DIALOG_TAG)
        if storePurchasePopup and not tolua.isnull(storePurchasePopup) then
            storePurchasePopup:runAction(cc.RemoveSelf:create())
        end
        
        -- draw rewards
        app.uiMgr:AddDialog('common.RewardPopup', {rewards = data.rewards})
        
        -- update cache count
        app:DispatchObservers(EVENT_GOODS_COUNT_UPDATE, data.rewards)

        -- update goods cell
        self:updatePropsGoodsNode_(goodsIndex)
        

    elseif name == SGL.Restaurant_Shop_GetPayOrder_Callback then
        if data.orderNo then
            local goodsIndex    = checkint(data.requestData.goodsIndex)
            local goodsData     = self:getGiftsGoodsData()[goodsIndex] or {}
            self.payGoodsIndex_ = goodsIndex

            if device.platform == 'android' or device.platform == 'ios' then
                if DEBUG > 0 and checkint(Platform.id) <= 1002 then
                    --mac机器上点击直接成功的逻辑
                    app:DispatchObservers(EVENT_PAY_MONEY_SUCCESS, {type = PAY_TYPE.PT_GIFT, rewards = {{goodsId = GOLD_ID, num = 10}} })
                else
                    require('root.AppSDK').GetInstance():InvokePay({
                        property   = data.orderNo,
                        amount     = checkint(goodsData.price),
                        goodsId    = tostring(goodsData.channelProductId),
                        goodsName  = __('幻晶石'),
                        quantifier = __('个'),
                        price      = 0.1,
                        count      = 1
                    })
                end
			else
                --mac机器上点击直接成功的逻辑
                app:DispatchObservers(EVENT_PAY_MONEY_SUCCESS, {type = PAY_TYPE.PT_GIFT, rewards = {{goodsId = GOLD_ID, num = 10}} })
            end
        else
            app.uiMgr:ShowInformationTips('pay/order callback orderNo is null !!')
        end


    elseif name == EVENT_PAY_MONEY_SUCCESS_UI then
        if checkint(data.type) == PAY_TYPE.PT_GIFT then
            local goodsData = self:getGiftsGoodsData()[self.payGoodsIndex_] or {}
            local totalPurchased = checkint(goodsData.lifeLeftPurchasedNum)
            local todayPurchased = checkint(goodsData.todayLeftPurchasedNum)
            if totalPurchased > 0 then
                goodsData.lifeLeftPurchasedNum = math.max(totalPurchased - 1, 0)
            end
            if todayPurchased > 0 then
                goodsData.todayLeftPurchasedNum = math.max(todayPurchased - 1, 0)
            end

            -- update goods cell
            self:updateGiftsGoodsNode_(self.payGoodsIndex_)
        end
    end
end


-------------------------------------------------
-- get / set

function SearchPropsStoreMediator:getStoresView()
    return self.storesView_
end
function SearchPropsStoreMediator:getStoresViewData()
    return self:getStoresView() and self:getStoresView():getViewData() or {}
end


-- gifts goodsData
function SearchPropsStoreMediator:getGiftsGoodsData()
    return self.giftsGoodsData_ or {}
end
function SearchPropsStoreMediator:setGiftsGoodsData(goodsData)
    self.giftsGoodsData_ = checktable(goodsData)
end


-- props goodsData
function SearchPropsStoreMediator:getPropsGoodsData()
    return self.propsGoodsData_ or {}
end
function SearchPropsStoreMediator:setPropsGoodsData(goodsData)
    self.propsGoodsData_ = checktable(goodsData)
end


-------------------------------------------------
-- public

function SearchPropsStoreMediator:close()
    self:GetFacade():UnRegsitMediator(self:GetMediatorName())
end


function SearchPropsStoreMediator:setStoreData(storeData)
    local searchStoreData = checktable(storeData)
    local giftsStoreData  = checktable(searchStoreData.giftsStoreData)
    local propsStoreData  = checktable(searchStoreData.propsStoreData)
    self.dataTimestamp_   = checkint(searchStoreData.dataTimestamp)
    self.searchGoodsId_   = checkint(searchStoreData.searchGoodsId)
    
    -- search gifts store
    local giftsGoodsData = {}
    for i, giftsData in ipairs(giftsStoreData) do
        local hasSearchGoods = false
        for i, rewardData in ipairs(giftsData.rewards or {}) do
            if checkint(rewardData.goodsId) == self.searchGoodsId_ then
                hasSearchGoods = true
                break
            end
        end
        if hasSearchGoods then
            table.insert(giftsGoodsData, giftsData)
        end
    end
    self:setGiftsGoodsData(giftsGoodsData)
    
    -- search props store
    local propsGoodsData = {}
    for i, propsData in ipairs(propsStoreData) do
        if checkint(propsData.goodsId) == self.searchGoodsId_ then
            table.insert(propsGoodsData, propsData)
        end
    end
    self:setPropsGoodsData(propsGoodsData)

    -- update result
    self:updateResultListView_()
end


-------------------------------------------------
-- private

function SearchPropsStoreMediator:updateResultListView_()
    local resultList = self:getStoresViewData().resultList
    resultList:removeAllNodes()
    
    local resultListSize     = resultList:getContentSize()
    local hasGiftsGoodsData  = #self:getGiftsGoodsData() > 0
    local hasPropsGoodsData  = #self:getPropsGoodsData() > 0
    self.giftsGoodsNodeList_ = {}
    self.propsGoodsNodeList_ = {}

    if hasGiftsGoodsData then
        resultList:insertNodeAtLast(self:getStoresView():createResultTypeBar(__('礼包')))
        resultList:insertNodeAtLast(self:getStoresView():createGiftsGoodsLayer(self:getGiftsGoodsData(), function(goodsNode, goodsIndex)
            self.giftsGoodsNodeList_[goodsIndex] = goodsNode
            self:updateGiftsGoodsNode_(goodsIndex)
        end))
    end

    if hasPropsGoodsData then
        resultList:insertNodeAtLast(self:getStoresView():createResultTypeBar(__('道具')))
        resultList:insertNodeAtLast(self:getStoresView():createPropsGoodsLayer(self:getPropsGoodsData(), function(goodsNode, goodsIndex)
            self.propsGoodsNodeList_[goodsIndex] = goodsNode
            self:updatePropsGoodsNode_(goodsIndex)
        end))
    end
    
    resultList:reloadData()

    -- start countdown
    self:stopGiftsCountdownUpdate_()
    self:stopPropsCountdownUpdate_()
    if hasGiftsGoodsData then
        self:startGiftsCountdownUpdate_()
    end
    if hasPropsGoodsData then
        self:startPropsCountdownUpdate_()
    end
    
    -- check is empty
    local isEmptyResult = not hasGiftsGoodsData and not hasPropsGoodsData
    self:getStoresViewData().emptyLayer:setVisible(isEmptyResult)
end


function SearchPropsStoreMediator:updateGiftsGoodsNode_(cellIndex)
    local goodsNode = self.giftsGoodsNodeList_[cellIndex]
    local goodsData = self:getGiftsGoodsData()[cellIndex]

    if goodsNode and goodsData then
        goodsNode:resetNodeData({
            dataTimestamp   = self.dataTimestamp_,
            giftsGoodsData  = goodsData,
            giftsGoodsIndex = cellIndex,
        })
    end
end


function SearchPropsStoreMediator:updatePropsGoodsNode_(cellIndex)
    local goodsNode = self.propsGoodsNodeList_[cellIndex]
    local goodsData = self:getPropsGoodsData()[cellIndex]

    if goodsNode and goodsData then
        goodsNode:resetNodeData({
            dataTimestamp   = self.dataTimestamp_,
            propsGoodsData  = goodsData,
            propsGoodsIndex = cellIndex,
        })
    end
end


function SearchPropsStoreMediator:stopGiftsCountdownUpdate_()
    if self.giftsCountdownUpdateHandler_ then
        scheduler.unscheduleGlobal(self.giftsCountdownUpdateHandler_)
        self.giftsCountdownUpdateHandler_ = nil
    end
end
function SearchPropsStoreMediator:startGiftsCountdownUpdate_()
    if self.giftsCountdownUpdateHandler_ then return end
    self.giftsCountdownUpdateHandler_ = scheduler.scheduleGlobal(function()
        for _, goodsNode in pairs(self.giftsGoodsNodeList_) do
            -- update limit time
            if goodsNode:isLimitTime() then
                goodsNode:updateLimitCountdown()
            end
        end
    end, 1)
end


function SearchPropsStoreMediator:stopPropsCountdownUpdate_()
    if self.propsCountdownUpdateHandler_ then
        scheduler.unscheduleGlobal(self.propsCountdownUpdateHandler_)
        self.propsCountdownUpdateHandler_ = nil
    end
end
function SearchPropsStoreMediator:startPropsCountdownUpdate_()
    if self.propsCountdownUpdateHandler_ then return end
    self.propsCountdownUpdateHandler_ = scheduler.scheduleGlobal(function()
        for _, goodsNode in pairs(self.propsGoodsNodeList_) do
            -- update limit time
            if goodsNode:isLimitTime() then
                goodsNode:updateLimitCountdown()
            end
            -- update discount time
            if goodsNode:isLimitDiscount() then
                goodsNode:updateDiscountCountdown()
            end
        end
    end, 1)
end


-------------------------------------------------
-- handler


return SearchPropsStoreMediator

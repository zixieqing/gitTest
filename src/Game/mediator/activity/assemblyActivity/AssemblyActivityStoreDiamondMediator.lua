--[[
 * author : liuzhipeng
 * descpt : 活动 组合活动 钻石商城Mediator
--]]
local AssemblyActivityStoreDiamondView     = require('Game.views.activity.assemblyActivity.AssemblyActivityStoreDiamondView')
local AssemblyActivityStoreDiamondMediator = class('AssemblyActivityStoreDiamondMediator', mvc.Mediator)
local NAME = 'activity.assemblyActivity.AssemblyActivityStoreDiamondMediator'
function AssemblyActivityStoreDiamondMediator:ctor(params, viewComponent)
    self.super.ctor(self, NAME, viewComponent)
    self.ctorArgs_ = checktable(params)
    self.activityId = self.ctorArgs_.activityId
end
-------------------------------------------------
------------------ inheritance ------------------
function AssemblyActivityStoreDiamondMediator:Initial( key )
    self.super.Initial(self, key)

    -- init vars
    self.ownerNode_      = self.ctorArgs_.ownerNode
    self.goodsCellDict_  = {}
    self.storeGoodsData_ = {}
    self.isControllable_ = true

    -- create view
    if self.ownerNode_ then
        self.storesView_ = AssemblyActivityStoreDiamondView.new(self.ownerNode_:getContentSize())
        self.ownerNode_:addChild(self.storesView_)

        -- add listen
        self:getStoresViewData().goodsGridView:setDataSourceAdapterScriptHandler(handler(self, self.onGoodsGridDataAdapterHandler_))
    end
end
    
function AssemblyActivityStoreDiamondMediator:InterestSignals()
    local signals = {
        POST.ASSEMBLY_ACTIVITY_MALL_BUY.sglName,
    }
    return signals
end
function AssemblyActivityStoreDiamondMediator:ProcessSignal( signal )
    local name = signal:GetName()
    local data = signal:GetBody()

    if name == POST.ASSEMBLY_ACTIVITY_MALL_BUY.sglName then

        -- update purchase num
        local goodsBuyNum    = checkint(data.requestData.num)
        local goodsIndex     = checkint(data.requestData.goodsIndex)
        local goodsData      = self:getStoreGoodsData()[goodsIndex] or {}
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
        self:updateGoodsCell_(goodsIndex)
        DotGameEvent.SendEvent(DotGameEvent.EVENTS.RETURN_DIAMOND_PAY_1)
    end
end

function AssemblyActivityStoreDiamondMediator:OnRegist()
    regPost(POST.ASSEMBLY_ACTIVITY_MALL_BUY)
end
function AssemblyActivityStoreDiamondMediator:OnUnRegist()
    unregPost(POST.ASSEMBLY_ACTIVITY_MALL_BUY)
    self:stopGoodsCountdownUpdate_()
end
function AssemblyActivityStoreDiamondMediator:CleanupView()
    if self.storesView_  and (not tolua.isnull(self.storesView_)) then
        self.storesView_:runAction(cc.RemoveSelf:create())
        self.storesView_ = nil
    end
end
------------------ inheritance ------------------
-------------------------------------------------

-------------------------------------------------
-------------------- handler --------------------
function AssemblyActivityStoreDiamondMediator:onGoodsGridDataAdapterHandler_(cell, idx)
    local pCell = cell
    local index = idx + 1

    -- create cell
    if pCell == nil then
        local goodsGridView = self:getStoresViewData().goodsGridView
        local goodsCellSize = goodsGridView:getSizeOfCell()
        local cellViewData  = self:getStoresView():createGoodsCell(goodsCellSize)

        pCell = cellViewData.view
        self.goodsCellDict_[pCell] = cellViewData
    end

    -- init cell
    local cellViewData = self.goodsCellDict_[pCell]
    if cellViewData then
        cellViewData.view:setTag(index)
        cellViewData.goodsNode:setTag(index)
    end

    -- update cell
    self:updateGoodsCell_(index, cellViewData)

    return pCell
end
-------------------- handler --------------------
-------------------------------------------------

-------------------------------------------------
-------------------- private --------------------

function AssemblyActivityStoreDiamondMediator:stopGoodsCountdownUpdate_()
    if self.goodsCountdownUpdateHandler_ then
        scheduler.unscheduleGlobal(self.goodsCountdownUpdateHandler_)
        self.goodsCountdownUpdateHandler_ = nil
    end
end
function AssemblyActivityStoreDiamondMediator:startGoodsCountdownUpdate_()
    if self.goodsCountdownUpdateHandler_ then return end
    self.goodsCountdownUpdateHandler_ = scheduler.scheduleGlobal(function()
        for _, cellViewData in pairs(self.goodsCellDict_) do
            local goodsNode = cellViewData.goodsNode
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


function AssemblyActivityStoreDiamondMediator:updateGoodsGridView_()
    local goodsGridView = self:getStoresViewData().goodsGridView
    goodsGridView:setCountOfCell(#self:getStoreGoodsData())
    goodsGridView:reloadData()
end


function AssemblyActivityStoreDiamondMediator:updateGoodsCell_(index, cellViewData)
    local propsGoodsIndex = checkint(index)
    local goodsGridView = self:getStoresViewData().goodsGridView
    local cellViewData  = cellViewData or self.goodsCellDict_[goodsGridView:cellAtIndex(propsGoodsIndex - 1)]
    local goodsData     = self:getStoreGoodsData()[propsGoodsIndex]

    if cellViewData and goodsData then
        cellViewData.goodsNode:resetNodeData({
            dataTimestamp   = self.dataTimestamp_,
            propsGoodsData  = goodsData,
            propsGoodsIndex = propsGoodsIndex,
            buyGoodsCmdName = POST.ASSEMBLY_ACTIVITY_MALL_BUY.cmdName,
            buyGoodsCmdParams = {activityId = self.activityId},
            dotGameCallBack = function ()
                DotGameEvent.SendEvent(DotGameEvent.EVENTS.RETURN_DIAMOND_PAY_0)
            end
        })
    end
end
-------------------- private --------------------
-------------------------------------------------

-------------------------------------------------
-------------------- public ---------------------
function AssemblyActivityStoreDiamondMediator:close()
    self:GetFacade():UnRegsitMediator(self:GetMediatorName())
end


function AssemblyActivityStoreDiamondMediator:setStoreData(storeData)
    local propsStoreData = checktable(storeData)
    self.dataTimestamp_  = checkint(propsStoreData.dataTimestamp)
    self:setStoreGoodsData(propsStoreData.storeData)

    -- start goods countdown
    self:stopGoodsCountdownUpdate_()
    self:startGoodsCountdownUpdate_()
end
-------------------- public ---------------------
-------------------------------------------------

-------------------------------------------------
------------------- get / set -------------------
function AssemblyActivityStoreDiamondMediator:getStoresView()
    return self.storesView_
end
function AssemblyActivityStoreDiamondMediator:getStoresViewData()
    return self:getStoresView() and self:getStoresView():getViewData() or {}
end


function AssemblyActivityStoreDiamondMediator:getStoreGoodsData()
    return self.storeGoodsData_ or {}
end
function AssemblyActivityStoreDiamondMediator:setStoreGoodsData(goodsData)
    self.storeGoodsData_ = checktable(goodsData)
    self:updateGoodsGridView_()
end
------------------- get / set -------------------
-------------------------------------------------
return AssemblyActivityStoreDiamondMediator
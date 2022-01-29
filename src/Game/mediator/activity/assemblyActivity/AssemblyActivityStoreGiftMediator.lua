--[[
 * author : liuzhipeng
 * descpt : 活动 组合活动 礼包商城Mediator
--]]
local AssemblyActivityStoreGiftView     = require('Game.views.activity.assemblyActivity.AssemblyActivityStoreGiftView')
local AssemblyActivityStoreGiftMediator = class('AssemblyActivityStoreGiftMediator', mvc.Mediator)
local NAME = 'activity.assemblyActivity.AssemblyActivityStoreGiftMediator'
function AssemblyActivityStoreGiftMediator:ctor(params, viewComponent)
    self.super.ctor(self, NAME, viewComponent)
    self.ctorArgs_ = checktable(params)
    self.activityId = self.ctorArgs_.activityId
end
-------------------------------------------------
------------------ inheritance ------------------
function AssemblyActivityStoreGiftMediator:Initial( key )
    self.super.Initial(self, key)

    -- init vars
    self.ownerNode_      = self.ctorArgs_.ownerNode
    self.goodsCellDict_  = {}
    self.storeGoodsData_ = {}
    self.isControllable_ = true

    -- create view
    if self.ownerNode_ then
        self.storesView_ = AssemblyActivityStoreGiftView.new(self.ownerNode_:getContentSize())
        self.ownerNode_:addChild(self.storesView_)

        -- add listen
        self:getStoresViewData().goodsGridView:setDataSourceAdapterScriptHandler(handler(self, self.onGoodsGridDataAdapterHandler_))
    end
end
    
function AssemblyActivityStoreGiftMediator:InterestSignals()
    local signals = {
        SGL.Restaurant_Shop_GetPayOrder_Callback,
        EVENT_PAY_MONEY_SUCCESS_UI,
        EVENT_APP_STORE_PRODUCTS,
    }
    return signals
end
function AssemblyActivityStoreGiftMediator:ProcessSignal( signal )
    local name = signal:GetName()
    local data = signal:GetBody()
    if name == SGL.Restaurant_Shop_GetPayOrder_Callback then
        if data.requestData.name ~= 'assemblyActivityStoreGift' then return end
        if data.orderNo then
            local goodsIndex    = checkint(data.requestData.goodsIndex)
            local goodsData     = self:getStoreGoodsData()[goodsIndex] or {}
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
        if checkint(data.type) == PAY_TYPE.ASSEMBLY_ACTIVITY_GIFT then
            local goodsData = self:getStoreGoodsData()[self.payGoodsIndex_] or {}
            local totalPurchased = checkint(goodsData.lifeLeftPurchasedNum)
            local todayPurchased = checkint(goodsData.todayLeftPurchasedNum)
            if totalPurchased > 0 then
                goodsData.lifeLeftPurchasedNum = math.max(totalPurchased - 1, 0)
            end
            if todayPurchased > 0 then
                goodsData.todayLeftPurchasedNum = math.max(todayPurchased - 1, 0)
            end

            -- update goods cell
            self:updateGoodsCell_(self.payGoodsIndex_)
        end


    elseif name == EVENT_APP_STORE_PRODUCTS then
        for _, cellViewData in pairs(self.goodsCellDict_) do
            local goodsNode = cellViewData.goodsNode
            goodsNode:updateGoodsPrice()
        end
    end
end

function AssemblyActivityStoreGiftMediator:OnRegist()
end
function AssemblyActivityStoreGiftMediator:OnUnRegist()
    self:stopGoodsCountdownUpdate_()
end
function AssemblyActivityStoreGiftMediator:CleanupView()
    if self.storesView_  and (not tolua.isnull(self.storesView_)) then
        self.storesView_:runAction(cc.RemoveSelf:create())
        self.storesView_ = nil
    end
end
------------------ inheritance ------------------
-------------------------------------------------

-------------------------------------------------
-------------------- handler --------------------
function AssemblyActivityStoreGiftMediator:onGoodsGridDataAdapterHandler_(cell, idx)
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

function AssemblyActivityStoreGiftMediator:stopGoodsCountdownUpdate_()
    if self.goodsCountdownUpdateHandler_ then
        scheduler.unscheduleGlobal(self.goodsCountdownUpdateHandler_)
        self.goodsCountdownUpdateHandler_ = nil
    end
end
function AssemblyActivityStoreGiftMediator:startGoodsCountdownUpdate_()
    if self.goodsCountdownUpdateHandler_ then return end
    self.goodsCountdownUpdateHandler_ = scheduler.scheduleGlobal(function()
        for _, cellViewData in pairs(self.goodsCellDict_) do
            local goodsNode = cellViewData.goodsNode
            -- update limit time
            if goodsNode:isLimitTime() then
                goodsNode:updateLimitCountdown()
            end
        end
    end, 1)
end


function AssemblyActivityStoreGiftMediator:updateGoodsGridView_()
    local goodsGridView = self:getStoresViewData().goodsGridView
    goodsGridView:setCountOfCell(#self:getStoreGoodsData())
    goodsGridView:reloadData()
end


function AssemblyActivityStoreGiftMediator:updateGoodsCell_(index, cellViewData)
    local giftsGoodsIndex = checkint(index)
    local goodsGridView = self:getStoresViewData().goodsGridView
    local cellViewData  = cellViewData or self.goodsCellDict_[goodsGridView:cellAtIndex(giftsGoodsIndex - 1)]
    local goodsData     = self:getStoreGoodsData()[giftsGoodsIndex]

    if cellViewData and goodsData then
        cellViewData.goodsNode:resetNodeData({
            dataTimestamp   = self.dataTimestamp_,
            giftsGoodsData  = goodsData,
            giftsGoodsIndex = giftsGoodsIndex,
            dotGameCallBack = function (goodsId)
                goodsId = checkint(goodsId)
                DotGameEvent.DynamicSendEvent({
                                                  event_id = table.concat({"2_" , "money_",goodsId , "_0"},""),
                    event_content = "money_pay",
                    game_uuid = DotGameEvent.GAME_UUIDS.RETURN_FACTORY
                })
            end
        })
    end
end
-------------------- private --------------------
-------------------------------------------------

-------------------------------------------------
-------------------- public ---------------------
function AssemblyActivityStoreGiftMediator:close()
    self:GetFacade():UnRegsitMediator(self:GetMediatorName())
end


function AssemblyActivityStoreGiftMediator:setStoreData(storeData)
    local giftsStoreData = checktable(storeData)
    self.dataTimestamp_  = checkint(giftsStoreData.dataTimestamp)
    self:setStoreGoodsData(giftsStoreData.storeData)

    -- start goods countdown
    self:stopGoodsCountdownUpdate_()
    self:startGoodsCountdownUpdate_()
end
-------------------- public ---------------------
-------------------------------------------------

-------------------------------------------------
------------------- get / set -------------------
function AssemblyActivityStoreGiftMediator:getStoresView()
    return self.storesView_
end
function AssemblyActivityStoreGiftMediator:getStoresViewData()
    return self:getStoresView() and self:getStoresView():getViewData() or {}
end


function AssemblyActivityStoreGiftMediator:getStoreGoodsData()
    return self.storeGoodsData_ or {}
end
function AssemblyActivityStoreGiftMediator:setStoreGoodsData(goodsData)
    self.storeGoodsData_ = checktable(goodsData)
    self:updateGoodsGridView_()

    if CommonUtils.IsNeedExtraGetRealPriceData() then
        local goodsChannelPIdList = {}
        for i, goodsData in ipairs(self:getStoreGoodsData()) do
            table.insert(goodsChannelPIdList, goodsData.channelProductId)
        end
        require('root.AppSDK').GetInstance():QueryProducts(goodsChannelPIdList)
    end
end
------------------- get / set -------------------
-------------------------------------------------
return AssemblyActivityStoreGiftMediator
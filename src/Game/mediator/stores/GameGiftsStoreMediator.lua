--[[
 * author : kaishiqi
 * descpt : 新游戏商店 - 礼包商店中介者
]]
local GameGiftsStoreView     = require('Game.views.stores.GameGiftsStoreView')
local GameGiftsStoreMediator = class('GameGiftsStoreMediator', mvc.Mediator)

function GameGiftsStoreMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'GameGiftsStoreMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end


-------------------------------------------------
-- inheritance method

function GameGiftsStoreMediator:Initial(key)
    self.super.Initial(self, key)

    -- init vars
    self.ownerNode_      = self.ctorArgs_.ownerNode
    self.goodsCellDict_  = {}
    self.storeGoodsData_ = {}
    self.isControllable_ = true

    -- create view
    if self.ownerNode_ then
        self.storesView_ = GameGiftsStoreView.new(self.ownerNode_:getContentSize())
        self.ownerNode_:addChild(self.storesView_)

        -- add listen
        self:getStoresViewData().goodsGridView:setDataSourceAdapterScriptHandler(handler(self, self.onGoodsGridDataAdapterHandler_))
    end
end


function GameGiftsStoreMediator:CleanupView()
    if self.storesView_  and (not tolua.isnull(self.storesView_)) then
        self.storesView_:runAction(cc.RemoveSelf:create())
        self.storesView_ = nil
    end
end


function GameGiftsStoreMediator:OnRegist()
end


function GameGiftsStoreMediator:OnUnRegist()
    self:stopGoodsCountdownUpdate_()
end


function GameGiftsStoreMediator:InterestSignals()
    return {
        SGL.Restaurant_Shop_GetPayOrder_Callback,
        EVENT_PAY_MONEY_SUCCESS_UI,
        EVENT_APP_STORE_PRODUCTS,
    }
end
function GameGiftsStoreMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()

    if name == SGL.Restaurant_Shop_GetPayOrder_Callback then
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
        if checkint(data.type) == PAY_TYPE.PT_GIFT then
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


-------------------------------------------------
-- get / set

function GameGiftsStoreMediator:getStoresView()
    return self.storesView_
end
function GameGiftsStoreMediator:getStoresViewData()
    return self:getStoresView() and self:getStoresView():getViewData() or {}
end


function GameGiftsStoreMediator:getStoreGoodsData()
    return self.storeGoodsData_ or {}
end
function GameGiftsStoreMediator:setStoreGoodsData(goodsData)
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


-------------------------------------------------
-- public

function GameGiftsStoreMediator:close()
    self:GetFacade():UnRegsitMediator(self:GetMediatorName())
end


function GameGiftsStoreMediator:setStoreData(storeData)
    local giftsStoreData = checktable(storeData)
    self.dataTimestamp_  = checkint(giftsStoreData.dataTimestamp)
    self:setStoreGoodsData(giftsStoreData.storeData)

    -- start goods countdown
    self:stopGoodsCountdownUpdate_()
    self:startGoodsCountdownUpdate_()
end


-------------------------------------------------
-- private

function GameGiftsStoreMediator:stopGoodsCountdownUpdate_()
    if self.goodsCountdownUpdateHandler_ then
        scheduler.unscheduleGlobal(self.goodsCountdownUpdateHandler_)
        self.goodsCountdownUpdateHandler_ = nil
    end
end
function GameGiftsStoreMediator:startGoodsCountdownUpdate_()
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


function GameGiftsStoreMediator:updateGoodsGridView_()
    local goodsGridView = self:getStoresViewData().goodsGridView
    goodsGridView:setCountOfCell(#self:getStoreGoodsData())
    goodsGridView:reloadData()
end


function GameGiftsStoreMediator:updateGoodsCell_(index, cellViewData)
    local giftsGoodsIndex = checkint(index)
    local goodsGridView = self:getStoresViewData().goodsGridView
    local cellViewData  = cellViewData or self.goodsCellDict_[goodsGridView:cellAtIndex(giftsGoodsIndex - 1)]
    local goodsData     = self:getStoreGoodsData()[giftsGoodsIndex]

    if cellViewData and goodsData then
        cellViewData.goodsNode:resetNodeData({
            dataTimestamp   = self.dataTimestamp_,
            giftsGoodsData  = goodsData,
            giftsGoodsIndex = giftsGoodsIndex,
        })
    end
end


-------------------------------------------------
-- handler

function GameGiftsStoreMediator:onGoodsGridDataAdapterHandler_(cell, idx)
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


return GameGiftsStoreMediator

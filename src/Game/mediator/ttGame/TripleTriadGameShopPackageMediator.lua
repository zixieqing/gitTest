--[[
 * author : kaishiqi
 * descpt : 打牌游戏 - 牌店 - 卡包中介者
]]
local TTGameShopPackageView     = require('Game.views.ttGame.TripleTriadGameShopPackageView')
local TTGameShopPackageMediator = class('TripleTriadGameShopPackageMediator', mvc.Mediator)


function TTGameShopPackageMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'TripleTriadGameShopPackageMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end


-------------------------------------------------
-- inheritance

function TTGameShopPackageMediator:Initial(key)
    self.super.Initial(self, key)

    -- init vars
    self.ownerNode_      = self.ctorArgs_.ownerNode
    self.goodsCellDict_  = {}
    self.storeGoodsData_ = {}
    self.isControllable_ = true

    if self.ownerNode_ then
        -- create view
        self.shopView_ = TTGameShopPackageView.new(self.ownerNode_:getContentSize())
        self.ownerNode_:addChild(self:getShopView())
        self:SetViewComponent(self:getShopView())

        -- add listen
        self:getViewData().goodsGridView:setDataSourceAdapterScriptHandler(handler(self, self.onGoodsGridDataAdapterHandler_))
    end
end


function TTGameShopPackageMediator:CleanupView()
end


function TTGameShopPackageMediator:OnRegist()
    regPost(POST.TTGAME_SHOP_PACK)
    regPost(POST.TTGAME_BUY_PACK)

    self:SendSignal(POST.TTGAME_SHOP_PACK.cmdName)
end


function TTGameShopPackageMediator:OnUnRegist()
    unregPost(POST.TTGAME_SHOP_PACK)
    unregPost(POST.TTGAME_BUY_PACK)
end


function TTGameShopPackageMediator:InterestSignals()
    return {
        POST.TTGAME_SHOP_PACK.sglName,
        POST.TTGAME_BUY_PACK.sglName,
    }
end
function TTGameShopPackageMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()

    if name == POST.TTGAME_SHOP_PACK.sglName then
        self:setStoreGoodsData(data.mall)


    elseif name == POST.TTGAME_BUY_PACK.sglName then
        -- update purchase num
        local goodsBuyNum    = checkint(data.requestData.num)
        local goodsIndex     = checkint(data.requestData.goodsIndex)
        local goodsData      = self:getStoreGoodsData()[goodsIndex] or {}

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
        app.uiMgr:AddDialog('Game.views.ttGame.TripleTriadGamePackageRewardsPopup', {rewards = data.rewards})

        -- update goods cell
        self:updateGoodsCell_(goodsIndex)
    end
end


-------------------------------------------------
-- get / set

function TTGameShopPackageMediator:getShopView()
    return self.shopView_
end
function TTGameShopPackageMediator:getViewData()
    return self:getShopView():getViewData()
end


function TTGameShopPackageMediator:getStoreGoodsData()
    return self.storeGoodsData_ or {}
end
function TTGameShopPackageMediator:setStoreGoodsData(goodsData)
    self.storeGoodsData_ = checktable(goodsData)
    self:updateGoodsGridView_()
end


-------------------------------------------------
-- public

function TTGameShopPackageMediator:hide()
    local viewComponent = self:GetViewComponent()
    if viewComponent then
        viewComponent:setVisible(false)
    end
end
function TTGameShopPackageMediator:show()
    local viewComponent = self:GetViewComponent()
    if viewComponent then
        viewComponent:setVisible(true)
    end
end


-------------------------------------------------
-- private

function TTGameShopPackageMediator:updateGoodsGridView_()
    local goodsGridView = self:getViewData().goodsGridView
    goodsGridView:setCountOfCell(#self:getStoreGoodsData())
    goodsGridView:reloadData()
end


function TTGameShopPackageMediator:updateGoodsCell_(index, cellViewData)
    local propsGoodsIndex = checkint(index)
    local goodsGridView = self:getViewData().goodsGridView
    local cellViewData  = cellViewData or self.goodsCellDict_[goodsGridView:cellAtIndex(propsGoodsIndex - 1)]
    local goodsData     = self:getStoreGoodsData()[propsGoodsIndex]

    if cellViewData and goodsData then
        cellViewData.goodsNode:resetNodeData({
            propsGoodsData  = goodsData,
            propsGoodsIndex = propsGoodsIndex,
            buyGoodsCmdName = POST.TTGAME_BUY_PACK.cmdName,
            onGoodsDescrCB  = function(goodsIndex, goodsData)
                app.uiMgr:AddDialog('Game.views.ttGame.TripleTriadGamePackageInfoPopup', {cardPackId = goodsData.goodsId})
            end,
        })
    end
end


-------------------------------------------------
-- handler

function TTGameShopPackageMediator:onGoodsGridDataAdapterHandler_(cell, idx)
    local pCell = cell
    local index = idx + 1

    -- create cell
    if pCell == nil then
        local goodsGridView = self:getViewData().goodsGridView
        local goodsCellSize = goodsGridView:getSizeOfCell()
        local cellViewData  = TTGameShopPackageView.createGoodsCell(goodsCellSize)

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


return TTGameShopPackageMediator

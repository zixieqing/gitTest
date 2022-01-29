--[[
    抽卡皮肤商店mediator
--]]
local Mediator = mvc.Mediator
local CapsuleMallOrnamentMediator = class("CapsuleMallOrnamentMediator", Mediator)
local NAME = "drawCards.CapsuleMallOrnamentMediator"

local CommonShopCell = require('Game.views.CommonShopCell')
local CapsuleMallOrnamentView = require('Game.views.drawCards.CapsuleMallOrnamentView')

local uiMgr    = app.uiMgr
local gameMgr  = app.gameMgr

local SHOP_PURCHASE_POPUP_TAG = 5002

function CapsuleMallOrnamentMediator:ctor( params, viewComponent )
    self.super.ctor(self, NAME, viewComponent)
    self.ctorArgs_ = checktable(params)
end

function CapsuleMallOrnamentMediator:InterestSignals()
	local signals = {
        POST.GAMBLING_SKIN_MALL_BUY.sglName,
	}
	return signals
end

function CapsuleMallOrnamentMediator:ProcessSignal( signal )
	local name = signal:GetName()
    local body = signal:GetBody()
    
    if name == POST.GAMBLING_SKIN_MALL_BUY.sglName then
        local scene = uiMgr:GetCurrentScene()
        local view = scene:GetDialogByTag(SHOP_PURCHASE_POPUP_TAG)
        if view then
            view:setVisible(false)
            view:runAction(cc.RemoveSelf:create())--兑换详情弹出框
        end
    end
end

function CapsuleMallOrnamentMediator:Initial( key )
    self.super.Initial(self, key)

    local viewComponent = CapsuleMallOrnamentView.new()
    self.viewData_      = viewComponent:getViewData()
    self:SetViewComponent(viewComponent)
    
    self:initData()
    self:initView()
end

function CapsuleMallOrnamentMediator:initData()
    self.mdtData = self.ctorArgs_.mdtData or {}
end

function CapsuleMallOrnamentMediator:initView()
    local viewData = self:getViewData()
    local gridView = viewData.gridView
    gridView:setDataSourceAdapterScriptHandler(handler(self,self.onGridViewDataAdapter))
end

-------------------------------------------------
-- get / set
function CapsuleMallOrnamentMediator:getViewData()
    return self.viewData_
end

-------------------------------------------------
-- public method

function CapsuleMallOrnamentMediator:refreshUI()
    local viewComponent = self:GetViewComponent()
    viewComponent:updateGridView(self.mdtData)
end

function CapsuleMallOrnamentMediator:updateData(params)
    local productIndex = params.productIndex
    self.mdtData = params.mdtData

    local mallData = self.mdtData[productIndex]

    local viewData = self:getViewData()
    local gridView = viewData.gridView
    local cell = gridView:cellAtIndex(productIndex - 1)
    if cell then
        self:GetViewComponent():updateCell(cell, mallData)
    end
end


-------------------------------------------------
-- private method
function CapsuleMallOrnamentMediator:onGridViewDataAdapter(p_convertview, idx)
    local pCell = p_convertview
    local index = idx + 1

    if pCell == nil then
        local gridView = self:getViewData().gridView
        local size = gridView:getSizeOfCell()
        pCell = CommonShopCell.new(size)
        display.commonUIParams(pCell.toggleView, {cb = handler(self, self.onClickCellAction)})
        pCell.ownLabel = display.newLabel(size.width / 2, 27, fontWithColor(14,{text = __('已拥有'),color = '#ffcb2b',outline = '#361e11',outlineSize = 1}))
        pCell.eventnode:addChild(pCell.ownLabel)
        pCell.ownLabel:setVisible(false)
        -- pCell.goodNode:RefreshSelf({showAmount = false})
        display.commonLabelParams(pCell.sellLabel, {color = '#000000'})
        display.commonUIParams(pCell.sellLabel, {po = cc.p(10, size.height - 18)})
        pCell.sellLabel:setVisible(false)
        pCell.leftTimesLabel:setVisible(false)
        pCell.numLabel:setPositionY(12)
        pCell.castIcon:setPositionY(12)
    end

    xTry(function()
       
        local mallData = self.mdtData[index]
        self:GetViewComponent():updateCell(pCell, mallData)

        pCell.toggleView:setTag(index)
    end,__G__TRACKBACK__)

    return pCell
end

function CapsuleMallOrnamentMediator:onClickCellAction(sender)
    local index = sender:getTag()
    local mallData = self.mdtData[index]

    local leftPurchaseNum = checkint(mallData.leftPurchaseNum)
    if leftPurchaseNum ~= -1 and leftPurchaseNum <= 0 then
        uiMgr:ShowInformationTips(__('兑换次数不足!!!'))
        return
    end

    local scene = uiMgr:GetCurrentScene()
    local marketPurchasePopup  = require('Game.views.ShopPurchasePopup').new({tag = SHOP_PURCHASE_POPUP_TAG, mediatorName = NAME, data = mallData, btnTag = index, showChooseUi = true,})
    display.commonUIParams(marketPurchasePopup, {ap = cc.p(0.5, 0.5), po = display.center})
    local popupViewData = marketPurchasePopup.viewData
    if leftPurchaseNum > 0 then
        local chooseNumLayout = popupViewData.chooseNumLayout
        local stockLabel = display.newLabel(chooseNumLayout:getPositionX() + chooseNumLayout:getContentSize().width / 2 + 15, 138, fontWithColor(6, {ap = display.LEFT_BOTTOM, text = string.fmt(__('库存:_num_'), {['_num_'] = leftPurchaseNum})}))
        popupViewData.view:addChild(stockLabel,11)
        popupViewData.stockLabel = stockLabel
    end
    local purchaseBtn = popupViewData.purchaseBtn

    display.commonLabelParams(popupViewData.titleBg, {text = __('兑换')})
    display.commonLabelParams(popupViewData.purchaseNumLabel, {text = __('兑换数量')})
    display.commonLabelParams(purchaseBtn, {text = __('兑换')})

    marketPurchasePopup:setTag(SHOP_PURCHASE_POPUP_TAG)
    scene:AddDialog(marketPurchasePopup)
    popupViewData.purchaseBtn:setOnClickScriptHandler(handler(self, self.onClickPurchaseBtnAction))
    popupViewData.purchaseBtn:setTag(index)
end

function CapsuleMallOrnamentMediator:onClickPurchaseBtnAction(sender)
    local index = sender:getTag()
    local num   = sender:getUserTag()
    
    local mallData = self.mdtData[index]

    ------------ 检查商品是否可以兑换 ------------
	-- 库存
    local stock = checkint(mallData.stock)
	if (-1 ~= stock and 0 >= stock) then
		uiMgr:ShowInformationTips(__('库存不足!!!'))
		return
    end

    local ownNum = gameMgr:GetAmountByIdForce(mallData.goodsId)
    if ownNum >= stock then
        local goodConf = CommonUtils.GetConfig('goods', 'goods', mallData.goodsId) or {}
		uiMgr:ShowInformationTips(string.fmt(__('_name_最多拥有_num_个'),{_name_ = tostring(goodConf.name), _num_ = stock}))
        return
    end
    
    local currency = mallData.currency
    local price    = checknumber(mallData.price) * num
    local ownCurrency = gameMgr:GetAmountByIdForce(currency)
    local consumeGoodsConfig = CommonUtils.GetConfig('goods', 'goods', currency) or {}
    local currencyName = tostring(consumeGoodsConfig.name)
    if price > ownCurrency then
        uiMgr:ShowInformationTips(string.format(__('%s不足!!!'), currencyName))
		uiMgr:AddDialog("common.GainPopup", {goodId = checkint(currency)})
		return
    end

    local CommonTip  = require( 'common.NewCommonTip' ).new({text = string.format(__('是否花费%s%s兑换'), price, currencyName),
    isOnlyOK = false, callback = function ()
        local params = {productId = mallData.productId, productNum = num, currency = mallData.currency, price = mallData.price, goodsId = mallData.goodsId}
        app:DispatchObservers('CAPSULE_MALL_GOOD_BUY', params)
    end})
    CommonTip:setPosition(display.center)
    local scene = uiMgr:GetCurrentScene()
    scene:AddDialog(CommonTip)

    
end

function CapsuleMallOrnamentMediator:OnRegist()
end

function CapsuleMallOrnamentMediator:OnUnRegist()
    self:cleanupView()
end

function CapsuleMallOrnamentMediator:cleanupView()
    local viewComponent = self:GetViewComponent()
    if viewComponent and not tolua.isnull(viewComponent) then
        viewComponent:setVisible(false)
        viewComponent:stopAllActions()
        viewComponent:runAction(cc.RemoveSelf:create())
    end
end

return CapsuleMallOrnamentMediator

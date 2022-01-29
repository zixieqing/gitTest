--[[
    抽卡皮肤商店mediator
--]]
local Mediator = mvc.Mediator
local CapsuleMallPartsMediator = class("CapsuleMallPartsMediator", Mediator)
local NAME = "drawCards.CapsuleMallPartsMediator"

local ThemePartCell        = require('Game.views.restaurant.ThemePartCell')
local CapsuleMallPartsView = require('Game.views.drawCards.CapsuleMallPartsView')



local uiMgr    = app.uiMgr
local gameMgr  = app.gameMgr


function CapsuleMallPartsMediator:ctor( params, viewComponent )
    self.super.ctor(self, NAME, viewComponent)
    self.ctorArgs_ = checktable(params)
end

function CapsuleMallPartsMediator:InterestSignals()
	local signals = {
        POST.GAMBLING_SKIN_MALL_BUY.sglName,
        POST.GAMBLING_BASE_CARDSKIN_MALL_BUY.sglName
	}
	return signals
end

function CapsuleMallPartsMediator:ProcessSignal( signal )
	local name = signal:GetName()
    local body = signal:GetBody()
    
    if name == POST.GAMBLING_SKIN_MALL_BUY.sglName 
    or name == POST.GAMBLING_BASE_CARDSKIN_MALL_BUY.sglName then
        local scene = uiMgr:GetCurrentScene()
        local view = scene:GetDialogByTag(5001)
        if view then
            view:setVisible(false)
            view:runAction(cc.RemoveSelf:create())--兑换详情弹出框
        end
    end
end

function CapsuleMallPartsMediator:Initial( key )
    self.super.Initial(self, key)

    local viewComponent = CapsuleMallPartsView.new()
    self.viewData_      = viewComponent:getViewData()
    self:SetViewComponent(viewComponent)
    
    self:initData()
    self:initView()
end

function CapsuleMallPartsMediator:initData()
    self.mdtData = self.ctorArgs_.mdtData or {}
end

function CapsuleMallPartsMediator:initView()
    local viewData = self:getViewData()
    local gridView = viewData.gridView
    gridView:setDataSourceAdapterScriptHandler(handler(self,self.onGridViewDataAdapter))
end

-------------------------------------------------
-- get / set
function CapsuleMallPartsMediator:getViewData()
    return self.viewData_
end

-------------------------------------------------
-- public method

function CapsuleMallPartsMediator:refreshUI()
    local viewComponent = self:GetViewComponent()
    viewComponent:updateGridView(self.mdtData)
end

function CapsuleMallPartsMediator:updateData(params)
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
function CapsuleMallPartsMediator:onGridViewDataAdapter(p_convertview, idx)
    local pCell = p_convertview
    local index = idx + 1

    if pCell == nil then
        local gridView = self:getViewData().gridView
        local size = gridView:getSizeOfCell()
        pCell = CGridViewCell:new()
        pCell:setContentSize(size)
        local layer = ThemePartCell.new(size)
        layer:setName('layer')
        display.commonUIParams(layer, {ap = display.CENTER, po = cc.p(size.width / 2, size.height / 2)})
        pCell:addChild(layer)

        display.commonUIParams(layer.touchView, {cb = handler(self, self.onClickCellAction)})
    end

    xTry(function()
       
        local mallData = self.mdtData[index]
        self:GetViewComponent():updateCell(pCell, mallData)
        pCell:getChildByName('layer').touchView:setTag(index)

    end,__G__TRACKBACK__)

    return pCell
end

function CapsuleMallPartsMediator:onClickCellAction(sender)
    local index = sender:getTag()
    local mallData = self.mdtData[index] or {}

    local leftPurchaseNum = checkint(mallData.leftPurchaseNum)
    if leftPurchaseNum ~= -1 and leftPurchaseNum <= 0 then
        uiMgr:ShowInformationTips(__('兑换次数不足!!!'))
        return
    end

    local scene = uiMgr:GetCurrentScene()
    local ownNum = gameMgr:GetAmountByIdForce(mallData.goodsId)
    local marketPurchasePopup  = require('common.AvatarPurchasePopup').new({tag = 5001, maxSelectNum = math.max( 0, leftPurchaseNum ), mediatorName = NAME, data = mallData, btnTag = index, showChooseUi = true})
    display.commonUIParams(marketPurchasePopup, {ap = cc.p(0.5, 0.5), po = display.center})
    marketPurchasePopup:setTag(5001)
    scene:AddDialog(marketPurchasePopup)

    local purchaseBtn = marketPurchasePopup.viewData.purchaseBtn
    display.commonUIParams(purchaseBtn, {cb = handler(self, self.onClickPurchaseBtnAction)})
    purchaseBtn:setTag(index)

end

function CapsuleMallPartsMediator:onClickPurchaseBtnAction(sender)
    local index    = sender:getTag()
    local num      = sender:getUserTag()

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

function CapsuleMallPartsMediator:OnRegist()
end

function CapsuleMallPartsMediator:OnUnRegist()
    self:cleanupView()
end

function CapsuleMallPartsMediator:cleanupView()
    local viewComponent = self:GetViewComponent()
    if viewComponent and not tolua.isnull(viewComponent) then
        viewComponent:setVisible(false)
        viewComponent:stopAllActions()
        viewComponent:runAction(cc.RemoveSelf:create())
    end
end

return CapsuleMallPartsMediator

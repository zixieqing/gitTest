--[[
    抽卡皮肤商店mediator
--]]
local Mediator = mvc.Mediator
local CapsuleMallThemeMediator = class("CapsuleMallThemeMediator", Mediator)
local NAME = "drawCards.CapsuleMallThemeMediator"

local CapsuleMallThemeView         = require('Game.views.drawCards.CapsuleMallThemeView')
local CapsuleThemePartsPreviewView = require('Game.views.drawCards.CapsuleThemePartsPreviewView')

local uiMgr    = app.uiMgr
local gameMgr  = app.gameMgr

local BUTTON_TAG = {
    PARTS_PREVIEW  = 100,
    NEXT           = 101,
    PRE            = 102,
    BUY            = 103,
}

function CapsuleMallThemeMediator:ctor( params, viewComponent )
    self.super.ctor(self, NAME, viewComponent)
    self.ctorArgs_ = checktable(params)
end

function CapsuleMallThemeMediator:InterestSignals()
	local signals = {
	}
	return signals
end

function CapsuleMallThemeMediator:ProcessSignal( signal )
	local name = signal:GetName()
	local body = signal:GetBody()
end

function CapsuleMallThemeMediator:Initial( key )
    self.super.Initial(self, key)

    local viewComponent = CapsuleMallThemeView.new()
    self.viewData_      = viewComponent:getViewData()
    self:SetViewComponent(viewComponent)

    self:initData()
    self:initView()
end

-------------------------------------------------
-- init

function CapsuleMallThemeMediator:initData()
    self.mdtData = self.ctorArgs_.mdtData or {}
    self.curIndex = 1
    
    self.maxIndex = #self.mdtData
    self.curThemeId = self.mdtData[self.curIndex].goodsId
end

function CapsuleMallThemeMediator:initView()
    local viewData   = self:getViewData()
    local actionBtns = viewData.actionBtns

    for tag, btn in pairs(actionBtns) do
        display.commonUIParams(btn, {cb = handler(self, self.onBtnAction)})
        btn:setTag(checkint(tag))
    end

end

-------------------------------------------------
-- get / set
function CapsuleMallThemeMediator:getViewData()
    return self.viewData_
end

-------------------------------------------------
-- public method

function CapsuleMallThemeMediator:refreshUI()
    local data = self.mdtData[self.curIndex]

    self:GetViewComponent():RefreshUI(data, self.curIndex, self.maxIndex)
end

function CapsuleMallThemeMediator:updateData(params)
    local productIndex = params.productIndex
    self.mdtData = params.mdtData

    self:refreshUI()
end

-------------------------------------------------
-- private method
function CapsuleMallThemeMediator:showPartsPreview()
    local view = CapsuleThemePartsPreviewView.new({themeId = self.curThemeId})
    view:setPosition(display.center)
	uiMgr:GetCurrentScene():AddDialog(view)
end

function CapsuleMallThemeMediator:handlerBuyTheme()
    local mallData = self.mdtData[self.curIndex] or {}
    local goodsId = mallData.goodsId
    if app.restaurantMgr:IsHaveTheme(mallData.goodsId) then
        uiMgr:ShowInformationTips(__('已经拥有该主题'))
        return 
    end

    local leftPurchaseNum = checkint(mallData.leftPurchaseNum)
    if leftPurchaseNum ~= -1 and leftPurchaseNum <= 0 then
        uiMgr:ShowInformationTips(__('兑换次数不足!!!'))
        return
    end

    local currency = mallData.currency
    local price    = checknumber(mallData.price)
    local ownCurrency = gameMgr:GetAmountByIdForce(currency)
    local consumeGoodsConfig = CommonUtils.GetConfig('goods', 'goods', currency) or {}
    local currencyName = tostring(consumeGoodsConfig.name)
    if price > ownCurrency then
        uiMgr:ShowInformationTips(string.format(__('%s不足!!!'), currencyName))
		uiMgr:AddDialog("common.GainPopup", {goodId = checkint(currency)})
		return
    end

    local CommonTip  = require( 'common.NewCommonTip' ).new({text = string.format(__('是否花费%s%s兑换'), price, currencyName),
    isOnlyOK = false, btnTextR = __('兑换'), callback = function ()
        local params = {productId = mallData.productId, productNum = 1, currency = currency, price = price, goodsId = goodsId}
        app:DispatchObservers('CAPSULE_MALL_GOOD_BUY', params)
    end})
    CommonTip:setPosition(display.center)
    local scene = uiMgr:GetCurrentScene()
    scene:AddDialog(CommonTip)
end

function CapsuleMallThemeMediator:updateCurIndex(index)
    self.curIndex = self:checkCurIndex(index)
    self.curThemeId = self.mdtData[self.curIndex].goodsId
    self:refreshUI()
end

function CapsuleMallThemeMediator:checkCurIndex(index)
    return math.max(math.min(index, self.maxIndex), 1)
end

-------------------------------------------------
-- handler
function CapsuleMallThemeMediator:onBtnAction(sender)
    local tag = sender:getTag()

    if tag == BUTTON_TAG.PARTS_PREVIEW then
        self:showPartsPreview()
    elseif tag == BUTTON_TAG.NEXT then
        self:updateCurIndex(self.curIndex + 1)
    elseif tag == BUTTON_TAG.PRE then
        self:updateCurIndex(self.curIndex - 1)
    elseif tag == BUTTON_TAG.BUY then
        self:handlerBuyTheme()
    end
end


function CapsuleMallThemeMediator:OnRegist()
end

function CapsuleMallThemeMediator:OnUnRegist()
    self:cleanupView()
end

function CapsuleMallThemeMediator:cleanupView()
    local viewComponent = self:GetViewComponent()
    if viewComponent and not tolua.isnull(viewComponent) then
        viewComponent:setVisible(false)
        viewComponent:stopAllActions()
        viewComponent:runAction(cc.RemoveSelf:create())
    end
end

return CapsuleMallThemeMediator

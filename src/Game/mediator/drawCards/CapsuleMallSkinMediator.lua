--[[
    抽卡皮肤商店mediator
--]]
local Mediator = mvc.Mediator
local CapsuleMallSkinMediator = class("CapsuleMallSkinMediator", Mediator)
local NAME = "drawCards.CapsuleMallSkinMediator"

---@type CapsuleMallSkinView
local CapsuleMallSkinView = require('Game.views.drawCards.CapsuleMallSkinView')
---@type CardSkinShopCell
local CardSkinShopCell = require('Game.views.CardSkinShopCell')

local uiMgr    = app.uiMgr
local gameMgr  = app.gameMgr
local cardMgr  = app.cardMgr

function CapsuleMallSkinMediator:ctor( params, viewComponent )
    self.super.ctor(self, NAME, viewComponent)
    self.ctorArgs_ = checktable(params)
end

function CapsuleMallSkinMediator:InterestSignals()
	local signals = {
        POST.GAMBLING_SKIN_MALL_BUY.sglName,
	}
	return signals
end

function CapsuleMallSkinMediator:ProcessSignal( signal )
	local name = signal:GetName()
    local body = signal:GetBody()
    
    -- if name == POST.GAMBLING_SKIN_MALL_BUY.sglName then
    --     local requ
    -- end
end

function CapsuleMallSkinMediator:Initial( key )
    self.super.Initial(self, key)

    local viewComponent = CapsuleMallSkinView.new()
    self.viewData_      = viewComponent:getViewData()
    self:SetViewComponent(viewComponent)

    self:initData()
    self:initView()
end

-------------------------------------------------
-- init
function CapsuleMallSkinMediator:initData()
    self.mdtData = self.ctorArgs_.mdtData or {}
end

function CapsuleMallSkinMediator:initView()
    local viewData = self:getViewData()
    local gridView = viewData.gridView
    gridView:setDataSourceAdapterScriptHandler(handler(self,self.onGridViewDataAdapter))
end

-------------------------------------------------
-- get / set
function CapsuleMallSkinMediator:getViewData()
    return self.viewData_
end

-------------------------------------------------
-- public method
function CapsuleMallSkinMediator:refreshUI()
    local viewComponent = self:GetViewComponent()
    viewComponent:updateGridView(self.mdtData)
end

function CapsuleMallSkinMediator:updateData(params)
    local productIndex = params.productIndex
    self.mdtData = params.mdtData

    local mallData = self.mdtData[productIndex]
    if mallData then
        self:BuyCardSkinCallback(checkint(mallData.goodsId))
    end

    local viewData = self:getViewData()
    local gridView = viewData.gridView
    local cell = gridView:cellAtIndex(productIndex - 1)
    if cell then
        self:GetViewComponent():updateCell(cell, mallData)
    end
end

-------------------------------------------------
-- private method
function CapsuleMallSkinMediator:onGridViewDataAdapter(p_convertview, idx)
    local pCell = p_convertview
    local index = idx + 1

    if pCell == nil then
        local gridView = self:getViewData().gridView
        pCell = CardSkinShopCell.new(gridView:getSizeOfCell())
        pCell.discountLine:setVisible(false)
        display.commonUIParams(pCell.toggleView, {animate = false, cb = handler(self, self.onClickCellAction)})
        pCell.markerBtn:setVisible(false)
        -- pCell.skinNameLabel:setPositionY(102)
        -- pCell.cardNameLabel:setPositionY(60)
    end

    xTry(function()
       
        local mallData = self.mdtData[index]
        self:GetViewComponent():updateCell(pCell, mallData)
        -- pCell:setTag(index)
        pCell.toggleView:setTag(index)
    end,__G__TRACKBACK__)

    return pCell
end

-------------------------------------------------
-- handler
function CapsuleMallSkinMediator:onClickCellAction(sender)
    local index    = sender:getTag()
    local mallData = self.mdtData[index]
    local skinId   = mallData.goodsId
    if cardMgr.IsHaveCardSkin(skinId) then
		uiMgr:ShowInformationTips(__('已经拥有该皮肤'))
		return
    end
    if mallData.leftPurchaseNum then
        local leftPurchaseNum = checkint(mallData.leftPurchaseNum)
        if leftPurchaseNum ~= -1 and leftPurchaseNum <= 0 then
            uiMgr:ShowInformationTips(__('购买次数不足!!!'))
            return
        end
    end
    local priceTable = {}
    priceTable[tostring(mallData.currency)] = mallData.price
    local ShowCardSkinLayer = require('common.CommonCardGoodsDetailView').new({
        goodsId = skinId,
        consumeConfig = {
            priceTable = priceTable,
        },
        confirmCallback = handler(self, self.purchaseBtnClickHandler),
        cancelCallback = function ()
            self.ShowCardSkinLayer = nil
        end,
    })
    ShowCardSkinLayer:setTag(index)
    self.ShowCardSkinLayer = ShowCardSkinLayer

    -- local mediator = app:RetrieveMediator("drawCards.CapsuleMallMediaor")
    -- if mediator then
        -- mediator:GetViewComponent():getViewData().view:addChild(ShowCardSkinLayer, 1)
        ShowCardSkinLayer:setPosition(display.center)
        app.uiMgr:GetCurrentScene():AddDialog(ShowCardSkinLayer)
    -- else

    -- end

    -- app:DispatchObservers('CAPSULE_MALL_GOOD_BUY', {})
end

function CapsuleMallSkinMediator:purchaseBtnClickHandler()
    local index = self.ShowCardSkinLayer:getTag()
    local mallData = self.mdtData[index]
    if mallData == nil then return end

	------------ 检查商品是否可以购买 ------------
	-- 库存
	if (-1 ~= checkint(mallData.stock) and 0 >= checkint(mallData.stock)) then
		uiMgr:ShowInformationTips(__('库存不足!!!'))
		return

	end

    -- 购买次数
    if mallData.leftPurchaseNum then
	    if (-1 ~= checkint(mallData.leftPurchaseNum) and 0 >= checkint(mallData.leftPurchaseNum)) then
	    	uiMgr:ShowInformationTips(__('购买次数不足!!!'))
	    	return
        end
    end
    
    local currency = mallData.currency
    local price    = checknumber(mallData.price)
    local ownCurrency = gameMgr:GetAmountByIdForce(currency)
    if price > ownCurrency then
        local consumeGoodsConfig = CommonUtils.GetConfig('goods', 'goods', currency) or {}
        uiMgr:ShowInformationTips(string.format(__('%s不足!!!'), tostring(consumeGoodsConfig.name)))
		uiMgr:AddDialog("common.GainPopup", {goodId = checkint(currency)})
		return
    end

    local skinId   = mallData.goodsId
    ------------ 检查商品是否可以购买 ------------

	-- 可以购买 弹出确认框
	local commonTip = require('common.CommonTip').new({
		text = __('确认购买?'),
		descrRich = {fontWithColor('8',{ text =__('购买前请再次确认价格') .. "\n" }) ,
					 fontWithColor('14',{ text = price}) ,
					 { img = CommonUtils.GetGoodsIconPathById(currency) , scale = 0.2 }
		} ,
		descrRichOutLine = {price},
        callback = function ()
            local params = {productId = mallData.productId, productNum = 1, currency = currency, price = price, goodsId = skinId}
			app:DispatchObservers('CAPSULE_MALL_GOOD_BUY', params)
		end
	})
    CommonUtils.AddRichLabelTraceEffect(commonTip.descrTip , nil , nil ,{2})
	commonTip:setPosition(display.center)
	uiMgr:GetCurrentScene():AddDialog(commonTip)
end

function CapsuleMallSkinMediator:BuyCardSkinCallback(skinId)
    local scene = uiMgr:GetCurrentScene()
    if scene == nil  or tolua.isnull(scene) then
        return
    end
    scene:AddViewForNoTouch()
    -- 关闭购买界面
	if nil ~= self.ShowCardSkinLayer then
		self.ShowCardSkinLayer:setVisible(false)
		self.ShowCardSkinLayer:runAction(cc.RemoveSelf:create())
        self.ShowCardSkinLayer = nil
        
        uiMgr:ShowInformationTips(__('购买成功!!!'))
    
        local layerTag = 7218
        local getCardSkinView = require('common.CommonCardGoodsShareView').new({
            goodsId = skinId,
            confirmCallback = function (sender)
                -- 确认按钮 关闭此界面
                local layer = scene:GetDialogByTag(layerTag)
                if nil ~= layer then
                    layer:setVisible(false)
                    layer:runAction(cc.RemoveSelf:create())
                end
            end
        })
        display.commonUIParams(getCardSkinView, {ap = cc.p(0.5, 0.5), po = display.center})
        scene:AddDialog(getCardSkinView)
        getCardSkinView:setTag(layerTag)
	end
    scene:RemoveViewForNoTouch()
end

function CapsuleMallSkinMediator:OnRegist()
end

function CapsuleMallSkinMediator:OnUnRegist()
    self.ShowCardSkinLayer = nil
    self:cleanupView()
end

function CapsuleMallSkinMediator:cleanupView()
    local viewComponent = self:GetViewComponent()
    if viewComponent and not tolua.isnull(viewComponent) then
        viewComponent:setVisible(false)
        viewComponent:stopAllActions()
        viewComponent:runAction(cc.RemoveSelf:create())
    end
end

return CapsuleMallSkinMediator

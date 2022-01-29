--[[
    燃战黑店Mediator
--]]
local Mediator = mvc.Mediator
---@class SaiMoeShopMediator:Mediator
local SaiMoeShopMediator = class("SaiMoeShopMediator", Mediator)

local NAME = "SaiMoeShopMediator"

local shareFacade = AppFacade.GetInstance()
local uiMgr = app.uiMgr
local gameMgr = app.gameMgr
local cardMgr = app.cardMgr

function SaiMoeShopMediator:ctor( params, viewComponent )
	self.super:ctor(NAME,viewComponent)
	self.datas = checktable(params) or {}
end

function SaiMoeShopMediator:InterestSignals()
	local signals = {
		POST.SAIMOE_SHOPPING.sglName ,
		SIGNALNAMES.CACHE_MONEY_UPDATE_UI,
        EVENT_PAY_MONEY_SUCCESS_UI,
	}

	return signals
end

function SaiMoeShopMediator:ProcessSignal( signal )
	local name = signal:GetName() 
	local body = signal:GetBody()
	-- dump(body, name)
	if name == POST.SAIMOE_SHOPPING.sglName then
		local rewardId = body.requestData.rewardId
        self.datas.shopList[tostring(rewardId)] = self.datas.shopList[tostring(rewardId)] - 1
        uiMgr:AddDialog('common.RewardPopup', body)

		-- 扣除道具
		local shop = CommonUtils.GetConfigAllMess('shop', 'cardComparison')[tostring(rewardId)]
		local currency = shop.consume[1].goodsId
		local diamonNum           = shop.consume[1].num
		CommonUtils.DrawRewards({ { goodsId = currency, num = (-diamonNum) } })

		local viewData = self:GetViewComponent().viewData
		if viewData.moneyNodes[tostring(currency)] then
			viewData.moneyNodes[tostring(currency)]:updataUi(currency)
		end

		local cell = self.cells[tostring(rewardId)]
		cell:setLeftPurchaseCount(self.datas.shopList[tostring(rewardId)])

		local shopEmpty = true
		for i, v in pairs(self.datas.shopList) do
			if checkint(v) ~= 0 then
				shopEmpty = false
			end
		end
		if shopEmpty then
			self:SendSignal(POST.SAIMOE_CLOSE_SHOP.cmdName)
		end
        shareFacade:DispatchObservers('SAIMOE_SHOPPING', body)
	elseif name == SIGNALNAMES.CACHE_MONEY_UPDATE_UI then
		local viewData = self:GetViewComponent().viewData
		if viewData.moneyNodes[tostring(GOLD_ID)] then
			viewData.moneyNodes[tostring(GOLD_ID)]:updataUi(GOLD_ID)
		end
		if viewData.moneyNodes[tostring(DIAMOND_ID)] then
			viewData.moneyNodes[tostring(DIAMOND_ID)]:updataUi(DIAMOND_ID)
		end
    elseif name == EVENT_PAY_MONEY_SUCCESS_UI then
		local viewData = self:GetViewComponent().viewData
        viewData.moneyNodes[tostring(DIAMOND_ID)]:updataUi(DIAMOND_ID)
	end
end

function SaiMoeShopMediator:Initial( key )
	self.super.Initial(self, key)
	local scene = uiMgr:GetCurrentScene()
	local viewComponent  = require('Game.views.saimoe.SaiMoeShopView').new(self.datas)
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	scene:AddDialog(viewComponent)

	local supportGroupId = self.datas.supportGroupId
	local playerConf = CommonUtils.GetConfigAllMess('comparisonInfo', 'cardComparison')[tostring(supportGroupId)]

	local bossReward = CommonUtils.GetConfigAllMess('quest', 'cardComparison')[tostring(playerConf.bossQuestId)]

    local viewData = viewComponent.viewData
	viewData.drawNode:RefreshAvatar({confId = bossReward.showMonster[1], coordinateType = COORDINATE_TYPE_CAPSULE})
	local locationConf    = CommonUtils.GetConfig('cards', 'coordinate', viewData.drawNode.drawName)
	local cardLocationDef = locationConf[COORDINATE_TYPE_CAPSULE]
	viewData.drawNode.avatar:setPosition(cc.p(cardLocationDef.x - 378, 435 - cardLocationDef.y))
	viewData.drawNode.avatar:setScale(0.83)
	viewData.drawNode:GetAvatar():runAction(cc.RepeatForever:create(cc.Sequence:create(
			cc.MoveBy:create(2, cc.p(0, 15)),
			cc.MoveBy:create(2, cc.p(0, -15))
	)))

	viewData.temporaryLeaveBtn:setOnClickScriptHandler(handler(self, self.TemporaryLeaveBtnClickHandler))
	viewData.permanentLeaveBtn:setOnClickScriptHandler(handler(self, self.PermanentLeaveBtnClickHandler))

	local index = 0
	local shop = CommonUtils.GetConfigAllMess('shop', 'cardComparison')
	self.cells = {}
	local time = 0.2

	local requestData = self.datas.requestData or {}
	local openShop = requestData.openShop or 0
	local function AnimationEnd(  )
		for k, v in pairs(self.datas.shopList) do
			local cell = require('Game.views.saimoe.SaiMoeShopItemCell').new(shop[tostring(k)])
			cell:setPosition(display.cx - 440 + index*340, 180)
			viewData.view:addChild(cell)
			cell:setLeftPurchaseCount(v)
			cell.toggleView:setTag(tonumber(k))
			cell.goodNode:setTag(tonumber(k))
			self.cells[tostring(k)] = cell
			cell.toggleView:setOnClickScriptHandler(handler(self, self.ShopItemCellClickHandler))
			cell.goodNode:setOnClickScriptHandler(handler(self, self.ShopItemCellClickHandler))
			if 1 == openShop then
				cell.eventnode:setScale(0)
				cell.eventnode:setOpacity(0)
				transition.execute(cell.eventnode, cc.Spawn:create({cc.ScaleTo:create(time, 1), cc.FadeIn:create(time)}), {delay = (time+0.1)*index})
			end
			index = index + 1
		end
	end
	if 1 == openShop then
		local aniTime = 0.3

		viewData.view:setOpacity(0)
		viewData.view:setPosition(display.cx, display.cy - 20)
		transition.execute(viewData.view, cc.Spawn:create(
				cc.FadeIn:create(aniTime),
				cc.MoveBy:create(aniTime, cc.p(0, 20))
		), {complete = AnimationEnd})
	else
		AnimationEnd()
	end
end

function SaiMoeShopMediator:TemporaryLeaveBtnClickHandler( sender )
	PlayAudioByClickClose()

	shareFacade:UnRegsitMediator(NAME)
end

function SaiMoeShopMediator:PermanentLeaveBtnClickHandler( sender )
	local scene = uiMgr:GetCurrentScene()
	local CommonTip = require('common.NewCommonTip').new({
		text     = __('确认要放弃购买吗？'),
		extra = __('放弃后不可返回'),
		isOnlyOK = false, callback = function()
			self:SendSignal(POST.SAIMOE_CLOSE_SHOP.cmdName)
		end })
	CommonTip:setPosition(display.center)
	scene:AddDialog(CommonTip)
	CommonTip.extra:setHorizontalAlignment(display.TAC)
end

function SaiMoeShopMediator:ShopItemCellClickHandler( sender )
    local scene = uiMgr:GetCurrentScene()
    local tag = sender:getTag()
    if 0 >= checkint(self.datas.shopList[tostring(tag)]) then
        uiMgr:ShowInformationTips(__('已购买'))
    else
        local shop = CommonUtils.GetConfigAllMess('shop', 'cardComparison')[tostring(tag)]
        local tempdata = {}
        tempdata.goodsId = shop.rewards[1].goodsId
        tempdata.num = shop.rewards[1].num
        tempdata.currency = shop.consume[1].goodsId
        tempdata.price = shop.consume[1].num

        local marketPurchasePopup  = require('Game.views.ShopPurchasePopup').new({
            tag = 5001,
            mediatorName = "SaiMoeShopMediator",
            data = tempdata,
            btnTag = tag
        })
        display.commonUIParams(marketPurchasePopup, {ap = cc.p(0.5, 0.5), po = cc.p(display.width * 0.5, display.height * 0.5)})
        marketPurchasePopup:setTag(5001)
        scene:AddDialog(marketPurchasePopup)
        marketPurchasePopup.viewData.purchaseBtn:setOnClickScriptHandler(handler(self, self.PurchaseBtnCallback))
        marketPurchasePopup.viewData.purchaseBtn:setTag(tag)
    end
end

--[[
购买按钮点击回调
--]]
function SaiMoeShopMediator:PurchaseBtnCallback( sender )
    PlayAudioByClickNormal()
    local tag = sender:getTag()
    local shop = CommonUtils.GetConfigAllMess('shop', 'cardComparison')[tostring(tag)]
    local currency = shop.consume[1].goodsId
    local money = CommonUtils.GetCacheProductNum(currency)
    local price = shop.consume[1].num
    if checkint(money) >= checkint(price) then
        self:SendSignal(POST.SAIMOE_SHOPPING.cmdName ,{rewardId = tag , num = 1 })
		local scene = uiMgr:GetCurrentScene()
		scene:RemoveDialogByTag(5001)
	else
		if GAME_MODULE_OPEN.NEW_STORE and checkint(currency) == DIAMOND_ID then
			app.uiMgr:showDiamonTips()
		else
			local goodOneData = CommonUtils.GetConfig('goods','goods',currency ) or {}
			local des = goodOneData.name or __('货币')
			uiMgr:ShowInformationTips(string.fmt(__('_des_不足'),{_des_ = des}))
		end
    end
end

function SaiMoeShopMediator:OnRegist(  )
	regPost(POST.SAIMOE_SHOPPING)
	regPost(POST.SAIMOE_CLOSE_SHOP)
end

function SaiMoeShopMediator:OnUnRegist(  )
	unregPost(POST.SAIMOE_SHOPPING)
	unregPost(POST.SAIMOE_CLOSE_SHOP)
	local scene = uiMgr:GetCurrentScene()
	scene:RemoveGameLayer(self.viewComponent)
end

return SaiMoeShopMediator
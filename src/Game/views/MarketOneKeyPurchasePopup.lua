--[[
市场购买界面
--]]
local CommonDialog = require('common.CommonDialog')
local MarketOneKeyPurchasePopup = class('MarketOneKeyPurchasePopup', CommonDialog)

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")

local CreateView
local RES_DICT = {
	COMMON_BG_7                    = _res('ui/common/common_bg_7.png'),
	COMMON_BTN_ORANGE              = _res('ui/common/common_btn_orange.png'),
	COMMON_BG_TITLE_2              = _res('ui/common/common_bg_title_2.png'),
	MARKET_BG_CHOICE_TYPE_DEFAULT  = _res("ui/home/market/market_bg_choice_type_default.png"),
	MARKET_BG_CHOICE_TYPE_SELECTED = _res("ui/home/market/market_bg_choice_type_selected.png"),
	MARKET_CHOICE_BG_PRIZCE        = _res("ui/home/market/market_choice_bg_prizce.png"),
	MARKET_CHOICE_ICO_LINE         = _res("ui/home/market/market_choice_ico_line.png"),
}

function MarketOneKeyPurchasePopup:InitialUI()
	local typeDatas = self.args.typeDatas or {}
	self.categoryDatas = self.args.categoryDatas or {}
	self.selectIndexs = {}

	app:RegistObserver("MARKET_GOOD_CHANGE", mvc.Observer.new(handler(self, self.MarketGoodChangeCallback), self))

	xTry(function ( )
		self.viewData = CreateView(typeDatas)
		display.commonUIParams(self.viewData.purchaseBtn, {cb = handler(self, self.PurchaseBtnCallback)})
		for index, categoryBtn in ipairs(self.viewData.categoryBtns) do
			display.commonUIParams(categoryBtn, {cb = handler(self, self.CategoryBtnCallback), animate = false})
		end
	end, __G__TRACKBACK__)
end

function MarketOneKeyPurchasePopup:onCleanup()
	app:UnRegistObserver("MARKET_GOOD_CHANGE",     self)
end

function MarketOneKeyPurchasePopup:MarketGoodChangeCallback(stage, signal)
	self:SetCategoryDatas(signal:GetBody() or {})
end

function MarketOneKeyPurchasePopup:PurchaseBtnCallback(sender)
	if next(self.selectIndexs) == nil then
		app.uiMgr:ShowInformationTips(__("请选择购买类别"))
		return
	end

	local totalPrice = 0
	for key, price in pairs(self.selectIndexs) do
		totalPrice = totalPrice + price
	end
	if checkint(gameMgr:GetUserInfo().gold) < totalPrice then
		uiMgr:ShowInformationTips(__('您的当前金币不足，请保证金币充足再进行尝试'))
		return
	end
	
	app:DispatchObservers("MARKET_ONE_KEY_PURCHASE", {selectIndexs = self.selectIndexs})
	self:CloseHandler()
end

function MarketOneKeyPurchasePopup:CategoryBtnCallback(sender)
	local index = sender:getTag()
	local checked = sender:isChecked()
	local nameLabel = sender:getChildByName('nameLabel')
	if checked then
		-- calc price
		self.selectIndexs[index] = self:GetPriceByCategoryIndex(index)
		if self.selectIndexs[index] <= 0 then
			sender:setChecked(false)
			uiMgr:ShowInformationTips(__("该类别当前没有可以购买的商品"))
			return
		end

		display.commonLabelParams(nameLabel, {color = '#bbada6'})
	else
		self.selectIndexs[index] = nil
		display.commonLabelParams(nameLabel, {color = '#ffffff'})
	end

	local totalPrice = 0
	for key, price in pairs(self.selectIndexs) do
		totalPrice = totalPrice + price
	end

	display.reloadRichLabel(self:GetViewData().priceLabel, {c = {
		fontWithColor(4, {text = totalPrice}),
		{img = CommonUtils.GetGoodsIconPathById(GOLD_ID), scale = 0.2}
	}})
end

function MarketOneKeyPurchasePopup:GetPriceByCategoryIndex(categoryIndex)
	local selectData = self.categoryDatas[categoryIndex] or {}
	local price = 0
	for index, value in ipairs(selectData) do
		if value.status ~= 2 then
			price = price + (value.discount or value.price)
		end
	end
	return price
end

function MarketOneKeyPurchasePopup:ReloadSelectIndexs()
	local totalPrice = 0
	for index, _ in pairs(self.selectIndexs) do
		local price = self:GetPriceByCategoryIndex(index)
		self.selectIndexs[index] = price
		totalPrice = totalPrice + price
	end

	display.reloadRichLabel(self:GetViewData().priceLabel, {c = {
		fontWithColor(4, {text = totalPrice}),
		{img = CommonUtils.GetGoodsIconPathById(GOLD_ID), scale = 0.2}
	}})
end

function MarketOneKeyPurchasePopup:SetCategoryDatas(categoryDatas)
	self.categoryDatas = categoryDatas
	self:ReloadSelectIndexs()
end

CreateView = function (typeDatas)
	local bg = display.newImageView(RES_DICT.COMMON_BG_7, 0, 0)
	local bgSize = bg:getContentSize()
	-- bg view
	local view = display.newLayer(0, 0, {size = bgSize, ap = cc.p(0.5, 0.5)})
	display.commonUIParams(bg, {po = cc.p(utils.getLocalCenter(view))})
	view:addChild(bg)

	local middleX = bgSize.width * 0.5
	local middleY = bgSize.height * 0.5
	-- title
	local titleBg = display.newButton(0, 0, {n = RES_DICT.COMMON_BG_TITLE_2, animation = false})
	display.commonUIParams(titleBg, {po = cc.p(bgSize.width * 0.5, bgSize.height - titleBg:getContentSize().height * 0.5)})
	display.commonLabelParams(titleBg,
		{text = __('选择类别'),
		fontSize = fontWithColor('3').fontSize, color = fontWithColor('3').color,
		offset = cc.p(0, -2)})
	bg:addChild(titleBg)

	local tipLabel = display.newLabel(bgSize.width * 0.5, bgSize.height - 76, fontWithColor(4, {text = __("请选择需要购买的类别"),w = 460 , hAlign = display.TAC}))
	view:addChild(tipLabel)

	local count = 0
	local startPosY = bgSize.height - 140
	local offsetY = 0
	local categoryBtns = {}
	for index, value in ipairs(typeDatas) do
		local goodsType = checkint(value.goodsType)
		if goodsType ~= -1 then
			local temp = count % 2
			local offsetX = temp == 0 and -20 or 20
			local ap = temp == 0 and display.RIGHT_CENTER or display.LEFT_CENTER
			offsetY = (count ~= 0 and temp == 0) and -90 * count * 0.5 or offsetY
			local categoryBtn = display.newCheckBox(middleX + offsetX, startPosY + offsetY, 
				{ap = ap, n = RES_DICT.MARKET_BG_CHOICE_TYPE_DEFAULT, s = RES_DICT.MARKET_BG_CHOICE_TYPE_SELECTED})
				
			local nameLabel = display.newLabel(104, 33.5, fontWithColor(14, {fontSize = 22, text = tostring(value.name)}))
			categoryBtn:addChild(nameLabel)
			nameLabel:setName('nameLabel')
			-- categoryBtn.nameLabel = nameLabel
			view:addChild(categoryBtn)

			categoryBtn:setTag(index)

			count = count + 1
			table.insert(categoryBtns, categoryBtn)
		end
	end

	local line = display.newNSprite(RES_DICT.MARKET_CHOICE_ICO_LINE, middleX, middleY - 30)
	view:addChild(line) 

	local totalPriceLabel = display.newLabel(middleX, middleY - 80, fontWithColor(4, {text = __('总价'), ap = display.CENTER}))
	view:addChild(totalPriceLabel) 

	local totalPriceBg = display.newNSprite(RES_DICT.MARKET_CHOICE_BG_PRIZCE, middleX, middleY - 125)
	view:addChild(totalPriceBg)

	local priceLabel = display.newRichLabel(92, 24, {ap = display.CENTER, c = {
		fontWithColor(4, {text = 0}),
		{img = CommonUtils.GetGoodsIconPathById(GOLD_ID), scale = 0.2}
	}})
	priceLabel:reloadData()
	totalPriceBg:addChild(priceLabel)

	local purchaseBtn = display.newButton(middleX, 60, {n = RES_DICT.COMMON_BTN_ORANGE})
	display.commonLabelParams(purchaseBtn, fontWithColor(14, {text = __("确认")}))
	view:addChild(purchaseBtn) 
	return {
		view         = view,
		priceLabel   = priceLabel,
		categoryBtns = categoryBtns,
		purchaseBtn  = purchaseBtn,
	}

end

function MarketOneKeyPurchasePopup:GetViewData()
	return self.viewData
end

return MarketOneKeyPurchasePopup
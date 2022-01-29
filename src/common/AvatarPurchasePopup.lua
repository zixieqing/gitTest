--[[
兑换界面
--]]
local CommonDialog = require('common.CommonDialog')
local AvatarPurchasePopup = class('AvatarPurchasePopup', CommonDialog)

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local DragNode = require('Game.views.restaurant.DragNode')

local CreateView     = nil
local CreateDragNode = nil

local RES_DICT = {
    COMMON_BG_7                     = _res('ui/common/common_bg_7.png'),
    COMMON_BG_TITLE_2               = _res('ui/common/common_bg_title_2.png'),
    COMMON_BTN_ORANGE               = _res('ui/common/common_btn_orange.png'),
    COMMON_TITLE_5                  = _res('ui/common/common_title_5.png'),
    SUMMON_SHOP_ICO_LINE            = _res('ui/home/capsuleNew/skinCapsule/shop/summon_shop_ico_line.png'),
    MARKET_BUY_BG_INFO              = _res('ui/home/commonShop/market_buy_bg_info.png'),
    MARKET_SOLD_BTN_PLUS            = _res('ui/home/market/market_sold_btn_plus.png'),
    MARKET_SOLD_BTN_SUB             = _res('ui/home/market/market_sold_btn_sub.png'),
}

function AvatarPurchasePopup:InitialUI()
	self.marketData = self.args.data
	self.selectNum  = 1
	self.maxSelectNum = self.args.maxSelectNum or checkint(self.marketData.leftPurchaseNum)
	local size = self.args.size or cc.size(558, 589)
	xTry(function ( )
		self.viewData = CreateView(size)

		self:initView()

	end, __G__TRACKBACK__)
end

function AvatarPurchasePopup:initView()
	local viewData = self.viewData
	display.commonUIParams(viewData.numBtn,      {cb = handler(self, self.onClickNumAction)})
	display.commonUIParams(viewData.minusBtn,    {cb = handler(self, self.onClickMinusAction)})
	display.commonUIParams(viewData.addBtn,      {cb = handler(self, self.onClickAddAction)})
	display.commonUIParams(viewData.goodsLayer, {cb = handler(self, self.onClickGoodsAction)})
	-- display.commonUIParams(viewData.purchaseBtn, {cb = handler(self, self.onClickPurchaseAction)})
	
	self:refreshUI()
end

function AvatarPurchasePopup:refreshUI()
	local viewData		   = self.viewData
	local marketData       = self.marketData	
	local goodsId          = marketData.goodsId
	local goodsConfig      = CommonUtils.GetConfig('goods', 'goods', goodsId) or {}
	
	-- 暂时只处理avatar类型
	if CommonUtils.GetGoodTypeById(goodsId) == GoodsType.TYPE_AVATAR then
		self:updateDragNode(viewData, goodsId)
	end
	
	local goodsName        = viewData.goodsName
	display.commonLabelParams(goodsName, {text = tostring(goodsConfig.name)})

	local ownNumLabel           = viewData.ownNumLabel
	local ownNum = checkint(gameMgr:GetAmountByIdForce(goodsId))
    ownNumLabel:setVisible(ownNum > 0)
    if ownNum > 0 then
        display.commonLabelParams(ownNumLabel, {text = string.format(__('拥有:%s'), ownNum)})
	end
	
	local leftPurchaseNum  = checkint(marketData.leftPurchaseNum)
	local stockLabel       = viewData.stockLabel
	local isShowStock      = leftPurchaseNum ~= -1
	display.commonLabelParams(stockLabel, {text = string.fmt(__('库存:_num_'), {['_num_'] = tostring(leftPurchaseNum)})})
	
	viewData.goodsIcon:setTexture(CommonUtils.GetGoodsIconPathById(marketData.currency))
	local price            = marketData.price
	self:updateSelectNum()
end

function AvatarPurchasePopup:updateDragNode(viewData, goodsId)
	local goodsLayer       = viewData.goodsLayer
	goodsLayer:setTag(goodsId)
	local goodsLayerSize = goodsLayer:getContentSize()
	local dragNode = RestaurantUtils.UpdateDragNode(viewData.dragNode, goodsId, cc.size(300, 200))
	if dragNode then
		display.commonUIParams(dragNode, {ap = display.CENTER, po = cc.p(goodsLayerSize.width / 2, goodsLayerSize.height / 2)})
		goodsLayer:addChild(dragNode)
		viewData.dragNode = nil
		viewData.dragNode = dragNode
	end
end

function AvatarPurchasePopup:updateSelectNum()
	local numBtn = self.viewData.numBtn
	display.commonLabelParams(numBtn, {text = self.selectNum})
	self.viewData.purchaseBtn:setUserTag(self.selectNum)
	self:updatePrice()
end

function AvatarPurchasePopup:updatePrice()
	local viewData		   = self.viewData
	local priceNum         = viewData.priceNum
	priceNum:setString(self.selectNum * checkint(self.marketData.price))
	self:updatePricePos()
end

function AvatarPurchasePopup:updatePricePos()
	local viewData		   = self.viewData
	local priceNum         = viewData.priceNum
	local goodsIcon        = viewData.goodsIcon
	local centrePosX        = viewData.centrePosX
	local priceNumSize     = priceNum:getContentSize()
	local goodsIconSize    = goodsIcon:getContentSize()

	priceNum:setPositionX(centrePosX - goodsIconSize.width / 2 * goodsIcon:getScale())
	goodsIcon:setPositionX(centrePosX + priceNumSize.width / 2)
end

function AvatarPurchasePopup:onClickNumAction(sender)
	PlayAudioByClickNormal()
	
	local tempData = {}
	tempData.callback = handler(self, self.numkeyboardCallBack)
	tempData.titleText = __('请输入需要兑换的数量')
	tempData.nums = 3
	tempData.model = NumboardModel.freeModel

	local NumKeyboardMediator = require( 'Game.mediator.NumKeyboardMediator' )
	local mediator = NumKeyboardMediator.new(tempData)
	app:RegistMediator(mediator)
end

function AvatarPurchasePopup:numkeyboardCallBack(data)
	if data then
		self.selectNum = self:checkSelectNum(data)
		self:updateSelectNum()
		-- self:updatePrice(self.selectNum * self.marketData.price)
	end
end

function AvatarPurchasePopup:onClickMinusAction(sender)
	PlayAudioByClickNormal()
	self.selectNum = self:checkSelectNum(self.selectNum - 1)
	self:updateSelectNum()
	-- self:updatePrice(price)
end

function AvatarPurchasePopup:onClickAddAction(sender)
	PlayAudioByClickNormal()
	local selectNum = self.selectNum + 1
	if selectNum > self.maxSelectNum then
		local goodConf = CommonUtils.GetConfig('goods', 'goods', self.marketData.goodsId) or {}
		uiMgr:ShowInformationTips(string.fmt(__('_name_最多拥有_num_个'),{_name_ = tostring(goodConf.name), _num_ = self.marketData.stock}))
		return
	end
	self.selectNum = self:checkSelectNum(self.selectNum + 1)
	self:updateSelectNum()
end

function AvatarPurchasePopup:onClickGoodsAction(sender)
	PlayAudioByClickNormal()
	local marketData       = self.marketData	
	local goodsId          = marketData.goodsId
	uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = goodsId, type = 1})
end

function AvatarPurchasePopup:checkSelectNum(num)
	return math.max(math.min(checkint(num), checkint(self.maxSelectNum)), 1)
end

CreateView = function (size)
	------------------view start-------------------

	local centrePosX = size.width / 2
	local centrePosY = size.height / 2

	local view = display.newLayer(0, 0, {size = size})

	local bg = display.newNSprite(RES_DICT.COMMON_BG_7, centrePosX, size.height / 2,
	{
		ap = display.CENTER,
	})
	view:addChild(bg)

	local title = display.newButton(centrePosX, 543,
	{
		ap = display.CENTER,
		n = RES_DICT.COMMON_BG_TITLE_2,
		scale9 = true, size = cc.size(256, 36),
		enable = false,
	})
	display.commonLabelParams(title, fontWithColor(7, {text = __('兑换'), fontSize = 24, offset = cc.p(0, -2)}))
	view:addChild(title)

	local goodsLayer = display.newLayer(centrePosX, centrePosY + 114, {ap = display.CENTER, color = cc.c4b(0,0,0,0), enable = true, size = cc.size(200,200)})
	view:addChild(goodsLayer)

	local goodsName = display.newLabel(centrePosX, 287, fontWithColor(11, {
		text = 'dfewf',
		ap = display.CENTER,
	}))
	view:addChild(goodsName)

	local ownNumLabel = display.newLabel(centrePosX, 261,
	{
		ap = display.CENTER,
		fontSize = 22,
		color = '#5c5c5c',
	})
	view:addChild(ownNumLabel)


	local numBtn = display.newButton(centrePosX, 173,
	{
		ap = display.CENTER,
		n = RES_DICT.MARKET_BUY_BG_INFO,
		enable = true, scale9 = true, size = cc.size(180, 44)
	})
	display.commonLabelParams(numBtn, {text = '1', fontSize = 28, color = '#7c7c7c'})
	view:addChild(numBtn)

	local minusBtn = display.newButton(195, 172,
	{
		ap = display.CENTER,
		n = RES_DICT.MARKET_SOLD_BTN_SUB,
		scale9 = true, size = cc.size(52, 53),
		enable = true,
	})
	view:addChild(minusBtn)

	local addBtn = display.newButton(358, 173,
	{
		ap = display.CENTER,
		n = RES_DICT.MARKET_SOLD_BTN_PLUS,
		scale9 = true, size = cc.size(52, 53),
		enable = true,
	})
	view:addChild(addBtn)

	
	view:addChild(display.newNSprite(RES_DICT.SUMMON_SHOP_ICO_LINE, centrePosX, 246, {ap = display.CENTER}))

	local purchaseNumTitle = display.newButton(279, 220,
	{
		ap = display.CENTER,
		n = RES_DICT.COMMON_TITLE_5,
		scale9 = true, size = cc.size(186, 31),
		enable = false,
	})
	display.commonLabelParams(purchaseNumTitle, fontWithColor(16, {text = __('兑换数量')}))
	view:addChild(purchaseNumTitle)

	local purchaseBtn = display.newButton(centrePosX, 96,
	{
		ap = display.CENTER,
		n = RES_DICT.COMMON_BTN_ORANGE,
		scale9 = true, size = cc.size(123, 62),
		enable = true,
	})
	display.commonLabelParams(purchaseBtn, fontWithColor(14, {text = __('兑换')}))
	view:addChild(purchaseBtn)

	local stockLabel = display.newLabel(391, 158, fontWithColor(6, {ap = display.LEFT_CENTER}))
	view:addChild(stockLabel)

	local priceNum = cc.Label:createWithBMFont('font/small/common_text_num.fnt', '0')
	priceNum:setAnchorPoint(display.CENTER)
	priceNum:setHorizontalAlignment(display.TAR)
	priceNum:setPosition(centrePosX, 50)
	view:addChild(priceNum)

	local goodsIcon = display.newImageView(CommonUtils.GetGoodsIconPathById(GOLD_ID), centrePosX, priceNum:getPositionY())
	goodsIcon:setScale(0.2)
	view:addChild(goodsIcon)

	-------------------view end--------------------
	return {
		view                    = view,
		bg                      = bg,
		title                   = title,
		goodsLayer              = goodsLayer,
		numBtn                  = numBtn,
		minusBtn                = minusBtn,
		addBtn                  = addBtn,
		goodsName               = goodsName,
		ownNumLabel             = ownNumLabel,
		purchaseNumTitle        = purchaseNumTitle,
		purchaseBtn             = purchaseBtn,
		stockLabel              = stockLabel,
		priceNum                = priceNum,
		goodsIcon               = goodsIcon,

		centrePosX              = centrePosX,
	}

end

CreateDragNode = function (goodsId)
    local avatarConfig   =  CommonUtils.GetConfigNoParser('restaurant', 'avatar', goodsId)
    local locationConfig =  CommonUtils.GetConfigNoParser('restaurant', 'avatarLocation', goodsId)
    local nType = checkint(avatarConfig.mainType)
    local goodIcon = DragNode.new({id = goodsId, avatarId = goodsId, nType = nType, configInfo = locationConfig, enable = false})
    return goodIcon
end

return AvatarPurchasePopup

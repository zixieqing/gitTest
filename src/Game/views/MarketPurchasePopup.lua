--[[
市场购买界面
--]]
local CommonDialog = require('common.CommonDialog')
local MarketPurchasePopup = class('MarketPurchasePopup', CommonDialog)

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")

function MarketPurchasePopup:InitialUI()
	local marketData = self.args.data
	dump(marketData)
	if marketData.discount then--说明有折扣。价格根据折扣价格走
		marketData.price = marketData.discount 
	end
	self.marketData = marketData
	local btnTag = self.args.btnTag
	local showChooseUi = self.args.showChooseUi or false
	self.selectNum = 1
	local goodsData = CommonUtils.GetConfig('goods', 'goods', marketData.goodsId)
	local function CreateView()
		-- bg
		local bg = display.newImageView(_res('ui/common/common_bg_9.png'), 0, 0)
		local bgSize = bg:getContentSize()
		-- bg view
		local view = display.newLayer(0, 0, {size = bgSize, ap = cc.p(0.5, 0.5)})
		display.commonUIParams(bg, {po = cc.p(utils.getLocalCenter(view))})
		view:addChild(bg, 5)
		-- title
		local titleBg = display.newButton(0, 0, {n = _res('ui/common/common_bg_title_2.png'), animation = false})
		display.commonUIParams(titleBg, {po = cc.p(bgSize.width * 0.5, bgSize.height - titleBg:getContentSize().height * 0.5)})
		display.commonLabelParams(titleBg,
			{text = __('购买'),
			fontSize = fontWithColor('3').fontSize, color = fontWithColor('3').color,
			offset = cc.p(0, -2)})
		bg:addChild(titleBg)
		-- 物品
		-- local goodsBg = display.newImageView(_res('ui/common/common_frame_goods_' .. goodsData.quality .. '.png'), bgSize.width/2, 384, {ap = cc.p(0.5, 0), scale9 = true, size = cc.size(93, 93)})
		-- view:addChild(goodsBg, 10)
		-- local goodsIcon = display.newImageView(CommonUtils.GetGoodsIconPathById(marketData.goodsId), goodsBg:getContentSize().width/2, goodsBg:getContentSize().height/2)
		-- goodsBg:addChild(goodsIcon, 10)
		-- goodsIcon:setScale(0.55)

	    local goodNode = require('common.GoodNode').new({id = marketData.goodsId,showAmount = false})
	    goodNode:setAnchorPoint(cc.p(0.5,0))
	    goodNode:setPosition(cc.p(bgSize.width/2, 384))
	    view:addChild(goodNode, 10)
	    
		local goodsName = display.newLabel(bgSize.width/2, 350, {ap = cc.p(0.5, 0), text = goodsData.name, fontSize = fontWithColor('11').fontSize, color = fontWithColor('11').color})
		view:addChild(goodsName, 10)
		-- local bagNumBg = display.newImageView(_res('ui/home/market/market_bg_bag_num.png'), 347, 418, {ap = cc.p(0, 0)})
		-- view:addChild(bagNumBg, 5)
		-- local bagIcon = display.newImageView(_res('ui/home/market/market_btn_bag.png'), 330, 413, {ap = cc.p(0, 0)})
		-- view:addChild(bagIcon, 10)
		-- local bagNum = tostring(gameMgr:GetAmountByGoodId(marketData.goodsId))
		-- local bagNumLabel = display.newLabel(398, 433, {text = bagNum, fontSize = 22, color = '#ffffff'})
		-- view:addChild(bagNumLabel, 10)
		-- 简介
		local descrBg = display.newImageView(_res('ui/common/commcon_bg_text.png'), bgSize.width/2, 200, {ap = cc.p(0.5, 0), scale9 = true, size = cc.size(397, 134)})
		view:addChild(descrBg, 5)
		local descrLabel = display.newLabel(43, 318, {w = 380, ap = cc.p(0, 1), text = goodsData.descr, fontSize = fontWithColor('6').fontSize, color = fontWithColor('6').color})
		view:addChild(descrLabel, 10)
		-- 购买数量
		local purchaseNumLabel = display.newLabel(150, 169, {ap = cc.p(1, 0.5), text = __('购买数量') ,reqW = 125, fontSize = fontWithColor('16').fontSize, color = fontWithColor('16').color})
		view:addChild(purchaseNumLabel, 10)
		local purchaseNumBg = display.newImageView(_res('ui/home/market/market_buy_bg_info.png'), 270, 169, {ap = cc.p(0.5, 0.5)})
		view:addChild(purchaseNumBg, 5)
		local purchaseNum = cc.Label:createWithBMFont('font/common_num_1.fnt', tostring(marketData.num or marketData.goodsNum ))
		purchaseNum:setAnchorPoint(cc.p(0, 0.5))
		purchaseNum:setHorizontalAlignment(display.TAR)
		purchaseNum:setPosition(175, 169)
		view:addChild(purchaseNum, 10)
		purchaseNum:setScale(1)
		-- 售价
		local priceLabel = display.newLabel(150, 127, {ap = cc.p(1, 0.5), text = __('售价'),reqW = 125, fontSize = fontWithColor('16').fontSize, color = fontWithColor('16').color})
		view:addChild(priceLabel, 10)
		local priceBg = display.newImageView(_res('ui/home/market/market_buy_bg_info.png'), 270, 127, {ap = cc.p(0.5, 0.5)})
		view:addChild(priceBg, 5)
		local priceNum = cc.Label:createWithBMFont('font/common_num_1.fnt', tostring(marketData.price))
		priceNum:setAnchorPoint(cc.p(0, 0.5))
		priceNum:setHorizontalAlignment(display.TAR)
		priceNum:setPosition(175, 127)
		view:addChild(priceNum, 10)
		priceNum:setScale(1)
		local goldIcon = display.newImageView(_res(CommonUtils.GetGoodsIconPathById(marketData.currency or GOLD_ID)), priceNum:getContentSize().width + 190, 127)
		goldIcon:setScale(0.2)
		view:addChild(goldIcon, 10)

		-- 购买按钮
		local purchaseBtn = display.newButton(bgSize.width/2, 60, {tag = btnTag, n = _res('ui/common/common_btn_orange.png')})
		view:addChild(purchaseBtn, 10)
		display.commonLabelParams(purchaseBtn, {text = __('购买'), fontSize = fontWithColor('14').fontSize, color = fontWithColor('14').color, ttf = true, font = fontWithColor('14').font})
		purchaseBtn:setUserTag(1)
		local chooseNumLayout = display.newLayer(0, 0, {size = purchaseNumBg:getContentSize(), ap = cc.p(0.5, 0.5)})--display.newLayer(purchaseNumBg:getContentSize())
		view:addChild(chooseNumLayout,11)
		chooseNumLayout:setPosition(cc.p(270, 169))
		chooseNumLayout:setBackgroundColor(cc.c4b(23, 67, 128, 128))
		chooseNumLayout:setVisible(showChooseUi)
		--选择数量
		local btn_num = display.newButton(0, 0, {n = _res('ui/home/market/market_buy_bg_info.png'),scale9 = true, size = cc.size(180, 44)})
		display.commonUIParams(btn_num, {po = cc.p(chooseNumLayout:getContentSize().width*0.5, -5),ap = cc.p(0.5,0)})
		display.commonLabelParams(btn_num, {text = '1', fontSize = 28, color = '#7c7c7c'})
		chooseNumLayout:addChild(btn_num)

		--减号btn
		local btn_minus = display.newButton(0, 0, {n = _res('ui/home/market/market_sold_btn_sub.png')})
		display.commonUIParams(btn_minus, {po = cc.p(chooseNumLayout:getContentSize().width*0.5 - 90, -10),ap = cc.p(0.5,0)})
		chooseNumLayout:addChild(btn_minus)
		btn_minus:setTag(1)

		--加号btn
	    local btn_add = display.newButton(0, 0, {n = _res('ui/home/market/market_sold_btn_plus.png')})
		display.commonUIParams(btn_add, {po = cc.p(chooseNumLayout:getContentSize().width*0.5 + 90, -10),ap = cc.p(0.5,0)})
		chooseNumLayout:addChild(btn_add)
		btn_add:setTag(2)



		return {
			view        = view,
			purchaseBtn = purchaseBtn,

			chooseNumLayout = chooseNumLayout,
			btn_num 	= btn_num,
			btn_minus 	= btn_minus,
			btn_add 	= btn_add,
			priceNum = priceNum,
			goldIcon = goldIcon
		}
	end
	xTry(function ( )
		self.viewData = CreateView( )
		self.viewData.purchaseBtn:setOnClickScriptHandler(handler(self, self.PurchaseBtnCallback))
		if showChooseUi then
			self.viewData.btn_minus:setOnClickScriptHandler(handler(self,self.ChooseNumBtnCallback))
			self.viewData.btn_add:setOnClickScriptHandler(handler(self,self.ChooseNumBtnCallback))
			self.viewData.btn_num:setOnClickScriptHandler(handler(self,self.SetNumBtnCallback))
		end

	end, __G__TRACKBACK__)
end


function MarketPurchasePopup:ChooseNumBtnCallback( sender )
	local tag = sender:getTag()

	local viewData = self.viewData
	local btn_num = viewData.btn_num
	if tag == 1 then--减
		if self.selectNum <= 0 then
			return
		end
		if checkint(self.selectNum) > 1 then
			self.selectNum = self.selectNum - 1
		end
	elseif tag == 2 then--加
		if checkint(self.marketData.stock) ~= -1 then 
			if checkint(self.selectNum) >= checkint((self.marketData.leftPurchasedNum or 1)) then
				uiMgr:ShowInformationTips(string.fmt(__('每次合成数量最大值为_num_个'),{_num_ = (self.marketData.leftPurchasedNum or 1)}))
				return
			end
		end
		self.selectNum = self.selectNum + 1
	end

	btn_num:getLabel():setString(tostring(self.selectNum))
	self.viewData.purchaseBtn:setUserTag(self.selectNum)
	self.viewData.priceNum:setString(tostring(self.selectNum*self.marketData.price))
	self.viewData.goldIcon:setPositionX(self.viewData.priceNum:getContentSize().width + 190)
	
end

function MarketPurchasePopup:SetNumBtnCallback( sender )
	local tempData = {}
	tempData.callback = handler(self, self.numkeyboardCallBack)
	tempData.titleText = __('请输入需要购买的数量')
	tempData.nums = 3
	tempData.model = NumboardModel.freeModel

	local NumKeyboardMediator = require( 'Game.mediator.NumKeyboardMediator' ) 
	local mediator = NumKeyboardMediator.new(tempData)
	AppFacade.GetInstance():RegistMediator(mediator)
end



function MarketPurchasePopup:numkeyboardCallBack(data)
	if data then
		if data == '' then
			data = '1'
		end
		if checkint(data) <= 0 then
			data = 1
		end

		if self.marketData.leftPurchasedNum then
			if checkint(data) > checkint(self.marketData.leftPurchasedNum) then
				data = self.marketData.leftPurchasedNum
			end
		end

		self.selectNum = checkint(data)
		self.viewData.btn_num:getLabel():setString(tostring(self.selectNum))
		self.viewData.purchaseBtn:setUserTag(self.selectNum)

		self.viewData.priceNum:setString(tostring(self.selectNum*self.marketData.price))
		self.viewData.goldIcon:setPositionX(self.viewData.priceNum:getContentSize().width + 190)
	end
end
--[[
商品购买回调
--]]
function MarketPurchasePopup:PurchaseBtnCallback( sender )
	local mediator = AppFacade.GetInstance():RetrieveMediator('MarketPurchaseMediator')
	mediator:PurchaseEvent(self.args.data)
end



return MarketPurchasePopup
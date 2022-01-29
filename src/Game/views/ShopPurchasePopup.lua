--[[
购买界面
--]]
local CommonDialog = require('common.CommonDialog')
local ShopPurchasePopup = class('ShopPurchasePopup', CommonDialog)

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")

function ShopPurchasePopup:InitialUI()
	local marketData = self.args.data
	-- dump(marketData)
	self.price = marketData.price
	if marketData.discountLeftSeconds then
		if marketData.discountLeftSeconds == -1 then
			if marketData.discount  then--说明有折扣。价格根据折扣价格走
				if checkint(marketData.discount) < 100 and checkint(marketData.discount) > 0 then
					marketData.price = marketData.discount * marketData.price / 100
				end
			end
		else
			if marketData.discountLeftSeconds > 0 then
				if marketData.discount  then--说明有折扣。价格根据折扣价格走
					if checkint(marketData.discount) < 100 and checkint(marketData.discount) > 0 then
						marketData.price = marketData.discount * marketData.price / 100
					end
				end
			end
		end
	end
	self.marketData = marketData
	local btnTag = self.args.btnTag
	local showChooseUi = self.args.showChooseUi or false
	self.selectNum = 1
	local goodsData = CommonUtils.GetConfig('goods', 'goods', marketData.goodsId) or {}
	local function CreateView()
		-- bg
		local bg = display.newImageView(_res('ui/common/common_bg_7.png'), 0, 0)
		local bgSize = bg:getContentSize()
		-- bg view
		local view = display.newLayer(0, 0, {size = bgSize, ap = cc.p(0.5, 0.5)})
		display.commonUIParams(bg, {po = cc.p(utils.getLocalCenter(view))})
		view:addChild(bg, 5)
		-- title
		local titleBg = display.newButton(0, 0, {n = _res('ui/common/common_bg_title_2.png'), animation = false ,scale9 = true  })
		display.commonUIParams(titleBg, {po = cc.p(bgSize.width * 0.5, bgSize.height - titleBg:getContentSize().height * 0.5 - 3)})
		display.commonLabelParams(titleBg,
			{text = __('购买'),paddingW = 20 ,
			fontSize = fontWithColor('3').fontSize, color = fontWithColor('3').color,
			 font = TTF_GAME_FONT, ttf = true,
			offset = cc.p(0, -2)})
		bg:addChild(titleBg)
		-- 物品

	    local goodNode = require('common.GoodNode').new({id = marketData.goodsId, showAmount = false, callBack = function (sender)
			uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = sender.goodId, type = 1})
		end})
	    goodNode:setAnchorPoint(cc.p(0.5,0))
	    goodNode:setPosition(cc.p(bgSize.width*0.25, 374))
	    view:addChild(goodNode, 10)

		local goodsName = display.newLabel(bgSize.width*0.25, 375, { w = 500 , hAlign = display.TAC,  ap = cc.p(0.5, 1), text = goodsData.name, fontSize =20 , color = fontWithColor('11').color})
		view:addChild(goodsName, 10)


		-- 简介
		local descrBg = display.newImageView(_res('ui/common/commcon_bg_text.png'), bgSize.width/2, 200, {ap = cc.p(0.5, 0), scale9 = true, size = cc.size(397, 134)})
		view:addChild(descrBg, 5)

		local descrLabel = ui.textArea({size = cc.resize(descrBg:getContentSize(), -10, -10), dir = display.SDIR_H, fnt = FONT.D6})
		descrLabel:updateLabel({text = tostring(goodsData.descr)})
		view:addList(descrLabel, 10):alignTo(descrBg, ui.cc)
		-- 购买数量
		local purchaseNumLabel = display.newLabel(180, 159, {ap = cc.p(1, 0.5), text = __('购买数量'), fontSize = fontWithColor('16').fontSize, color = fontWithColor('16').color})
		view:addChild(purchaseNumLabel, 10)
		local purchaseNumBg = display.newImageView(_res('ui/home/market/market_buy_bg_info.png'), 300, 159, {ap = cc.p(0.5, 0.5)})
		view:addChild(purchaseNumBg, 5)
		local purchaseNum = cc.Label:createWithBMFont('font/common_num_1.fnt', tostring(marketData.num or marketData.goodsNum ))
		purchaseNum:setAnchorPoint(cc.p(0, 0.5))
		purchaseNum:setHorizontalAlignment(display.TAR)
		purchaseNum:setPosition(205, 159)
		view:addChild(purchaseNum, 10)
		purchaseNum:setScale(1)
		-- 售价
		local priceLabel = display.newLabel(180, 107, {ap = cc.p(1, 0.5), text = __('售价'), reqW = 150,  fontSize = fontWithColor('16').fontSize, color = fontWithColor('16').color})
		view:addChild(priceLabel, 10)
		local priceBg = display.newImageView(_res('ui/home/market/market_buy_bg_info.png'), 300, 107, {ap = cc.p(0.5, 0.5)})
		view:addChild(priceBg, 5)
		local priceNum = cc.Label:createWithBMFont('font/common_num_1.fnt', tostring(marketData.price))
		priceNum:setAnchorPoint(cc.p(0, 0.5))
		priceNum:setHorizontalAlignment(display.TAR)
		priceNum:setPosition(205, 107)
		view:addChild(priceNum, 10)
		priceNum:setScale(1)
		local goldIcon = display.newImageView(_res(CommonUtils.GetGoodsIconPathById(marketData.currency or GOLD_ID)), priceNum:getContentSize().width + 220, 107)
		goldIcon:setScale(0.2)
		view:addChild(goldIcon, 10)

		-- 购买按钮
		local purchaseBtn = display.newButton(bgSize.width/2, 50, {tag = btnTag, n = _res('ui/common/common_btn_orange.png') , scale9 = true })
		view:addChild(purchaseBtn, 10)
		display.commonLabelParams(purchaseBtn, {paddingW = 20 ,  text = __('购买'), fontSize = fontWithColor('14').fontSize, color = fontWithColor('14').color, ttf = true, font = fontWithColor('14').font, outline = '#734441'})
		purchaseBtn:setUserTag(1)
		local chooseNumLayout = display.newLayer(0, 0, {size = purchaseNumBg:getContentSize(), ap = cc.p(0.5, 0.5)})--display.newLayer(purchaseNumBg:getContentSize())
		view:addChild(chooseNumLayout,11)
		chooseNumLayout:setPosition(cc.p(300, 159))
		-- chooseNumLayout:setBackgroundColor(cc.c4b(23, 67, 128, 128))
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


		local discountLeftcon = {}
		if marketData.discountLeftSeconds then
			if marketData.shelfLeftSeconds ~= -1 then
				if marketData.discountLeftSeconds <= 86400 then
					discountLeftcon = {
						fontWithColor('15', {fontSize = 20, text = __('折扣销售：'), color = "ae8668"}),
						fontWithColor('15', {fontSize = 20,text = string.formattedTime(checkint(marketData.discountLeftSeconds or 0),'%02i:%02i:%02i') , color = "d23d3d"}),
					}
				else
					discountLeftcon = {
						fontWithColor('15', {fontSize = 20, text = __('折扣销售：'), color = "ae8668"}),
						fontWithColor('15', {fontSize = 20,text = math.floor((marketData.discountLeftSeconds or 0) /86400), color = "d23d3d"}),
						fontWithColor('15', {fontSize = 20,text = __('天'), color = "d23d3d"}),
					}
				end
			else
				discountLeftcon = {
					fontWithColor('15', {fontSize = 20, text = __('折扣销售：'), color = "ae8668"}),
					fontWithColor('15', {fontSize = 20,text = string.formattedTime(checkint(0),'%02i:%02i:%02i') , color = "d23d3d"}),
				}
			end
		else
			discountLeftcon = {
				fontWithColor('15', {fontSize = 20, text = __('折扣销售：'), color = "ae8668"}),
				fontWithColor('15', {fontSize = 20,text = string.formattedTime(checkint(0),'%02i:%02i:%02i') , color = "d23d3d"}),
			}
		end

		local shelfLeftSecondscon = {}
		if marketData.shelfLeftSeconds then
			if marketData.shelfLeftSeconds ~= -1 then
				if marketData.shelfLeftSeconds <= 86400 then
					shelfLeftSecondscon = {
					fontWithColor('15', {fontSize = 20, text = __('限时销售：'), color = "ae8668"}),
					fontWithColor('15', {fontSize = 20,text = string.formattedTime(checkint(marketData.shelfLeftSeconds or 0),'%02i:%02i:%02i') , color = "d23d3d"}),
					}
				else
					shelfLeftSecondscon = {
						fontWithColor('15', {fontSize = 20, text = __('限时销售：'), color = "ae8668"}),
						fontWithColor('15', {fontSize = 20,text = math.floor((marketData.shelfLeftSeconds or 0) /86400), color = "d23d3d"}),
						fontWithColor('15', {fontSize = 20,text = __('天'), color = "d23d3d"}),
					}
				end
			else
				shelfLeftSecondscon = {
					fontWithColor('15', {fontSize = 20, text = __('限时销售：'), color = "ae8668"}),
					fontWithColor('15', {fontSize = 20,text = string.formattedTime(checkint(0),'%02i:%02i:%02i') , color = "d23d3d"}),
				}
			end
		else
			shelfLeftSecondscon = {
				fontWithColor('15', {fontSize = 20, text = __('限时销售：'), color = "ae8668"}),
				fontWithColor('15', {fontSize = 20,text = string.formattedTime(checkint(0),'%02i:%02i:%02i') , color = "d23d3d"}),
			}
		end
		local Ctable = nil
		if self.args.mediatorName == "UnionShopMediator" then
			Ctable = {
				{
					fontWithColor('15', {fontSize = 20, text = __('当前库存：'), color = "ae8668"}),
					fontWithColor('15', {fontSize = 20,text = self:GetTimesNums(), color = "ac5a4a"}),
				},
				shelfLeftSecondscon,
				discountLeftcon,
			}
		else
			Ctable = {
				{fontWithColor('15', {fontSize = 20, text = string.format(__('剩余购买次数:%d'), self:GetTimesNums()), color = "ae8668"})},
				-- {
				-- 	fontWithColor('15', {fontSize = 20, text = __('剩余购买'), color = "ae8668"}),
				-- 	fontWithColor('15', {fontSize = 20,text = self:GetTimesNums(), color = "ac5a4a"}),
				-- 	fontWithColor('15', {fontSize = 20,text = __('次'), color = "ae8668"}),
				-- },
				shelfLeftSecondscon,
				discountLeftcon,
			}
		end
		local richLabel = {}
		local tempNUm = 0
		for i=1,3 do
			local messBg = display.newImageView(_res('ui/home/market/shop_bg_time_white'),bgSize.width*0.64,bgSize.height - 72 - (i-1)*45, {scale9 = true, size = cc.size(300, 30)})
			view:addChild(messBg, 10)

		    local sellLabel = display.newRichLabel(10, messBg:getContentSize().height/2,
		    	{ap = cc.p(0,0.5), c = {fontWithColor('14', {text = ''})}})
    		messBg:addChild(sellLabel)
    		display.reloadRichLabel(sellLabel, { c = Ctable[i] })
    		table.insert(richLabel,sellLabel)
    		if i == 1 then

				local times = self:GetTimesNums()
    			if times <= 0 then
    				messBg:setVisible(false)
    				tempNUm = tempNUm + 1
    			end

    		elseif i == 2 then
    			if not marketData.shelfLeftSeconds or checkint(marketData.shelfLeftSeconds) <= 0  then
    				messBg:setVisible(false)
    				tempNUm = tempNUm + 1
    			end

			elseif i == 3 then
    			if not marketData.discountLeftSeconds or checkint(marketData.discountLeftSeconds) <= 0 then
    				messBg:setVisible(false)
    				tempNUm = tempNUm + 1
    			end

			end
		end

		if tempNUm == table.nums(Ctable) then
			goodNode:setPositionX(bgSize.width*0.5)
			goodsName:setPositionX(bgSize.width*0.5)
		end


		return {
			view        = view,
			titleBg     = titleBg,
			purchaseNumLabel = purchaseNumLabel,
			purchaseBtn = purchaseBtn,
			richLabel = richLabel,
			chooseNumLayout = chooseNumLayout,
			goodsName = goodsName,
			descrLabel 	= descrLabel,
			goodNode 	= goodNode,
			btn_num 	= btn_num,
			btn_minus 	= btn_minus,
			btn_add 	= btn_add,
			priceNum = priceNum,
			goldIcon = goldIcon
		}
	end
	xTry(function ( )
		self.viewData = CreateView( )

		if showChooseUi then
			self.viewData.btn_minus:setOnClickScriptHandler(handler(self,self.ChooseNumBtnCallback))
			self.viewData.btn_add:setOnClickScriptHandler(handler(self,self.ChooseNumBtnCallback))
			self.viewData.btn_num:setOnClickScriptHandler(handler(self,self.SetNumBtnCallback))
		end

		self.scheduler = nil
		local tempBool = false
		if marketData.shelfLeftSeconds then
			if checkint(marketData.shelfLeftSeconds) ~= -1 and checkint(marketData.shelfLeftSeconds) >= 0 then
				tempBool = true
			end
		end

		if marketData.discountLeftSeconds then
			if checkint(marketData.discountLeftSeconds) ~= -1 and checkint(marketData.discountLeftSeconds) >= 0 then
				tempBool = true
			end
		end
		if tempBool == true then
			self.preTime = os.time()
            self.scheduler = scheduler.scheduleGlobal(handler(self, self.scheduleCallback), 1)
        end


	end, __G__TRACKBACK__)
end


--[[
定时器回调
--]]
function ShopPurchasePopup:scheduleCallback()
	local discountLeftcon = {}
	local curTime = os.time()
	local deltaTime = curTime - checkint(self.preTime)
	self.preTime = curTime
	if self.marketData.discountLeftSeconds then
		if self.marketData.discountLeftSeconds > 0 then
			self.marketData.discountLeftSeconds = self.marketData.discountLeftSeconds - deltaTime
		end
		if self.marketData.discountLeftSeconds <= 0 then
			self.marketData.discountLeftSeconds = 0
			self.marketData.price = self.price
			self.viewData.priceNum:setString(tostring(self.selectNum*self.marketData.price))
			self.viewData.goldIcon:setPositionX(self.viewData.priceNum:getContentSize().width + 220)
		end
		if self.marketData.discountLeftSeconds <= 86400 then
			discountLeftcon = {
			fontWithColor('15', {fontSize = 20, text = __('折扣销售：'), color = "ae8668"}),
			fontWithColor('15', {fontSize = 20,text = string.formattedTime(checkint(self.marketData.discountLeftSeconds or 0),'%02i:%02i:%02i') , color = "d23d3d"}),
			}
		else
			discountLeftcon = {
				fontWithColor('15', {fontSize = 20, text = __('折扣销售：'), color = "ae8668"}),
				fontWithColor('15', {fontSize = 20,text = math.floor((self.marketData.discountLeftSeconds or 0) /86400), color = "d23d3d"}),
				fontWithColor('15', {fontSize = 20,text = __('天'), color = "d23d3d"}),
			}
		end
	else
		self.marketData.discountLeftSeconds = 0
		discountLeftcon = {
			fontWithColor('15', {fontSize = 20, text = __('折扣销售：'), color = "ae8668"}),
			fontWithColor('15', {fontSize = 20,text = string.formattedTime(checkint(0),'%02i:%02i:%02i') , color = "d23d3d"}),
		}
	end

	local shelfLeftSecondscon = {}
	if self.marketData.shelfLeftSeconds then
		if self.marketData.shelfLeftSeconds > 0 then
			self.marketData.shelfLeftSeconds = self.marketData.shelfLeftSeconds - deltaTime
			if self.marketData.shelfLeftSeconds < 0 then
				self.marketData.shelfLeftSeconds = 0
			end
			if self.marketData.shelfLeftSeconds <= 86400 then
				shelfLeftSecondscon = {
					fontWithColor('15', {fontSize = 20, text = __('限时销售：'), color = "ae8668"}),
					fontWithColor('15', {fontSize = 20,text = string.formattedTime(checkint(self.marketData.shelfLeftSeconds or 0),'%02i:%02i:%02i') , color = "d23d3d"}),
				}
			else
				shelfLeftSecondscon = {
					fontWithColor('15', {fontSize = 20, text = __('限时销售：'), color = "ae8668"}),
					fontWithColor('15', {fontSize = 20,text = math.floor((self.marketData.shelfLeftSeconds or 0) /86400), color = "d23d3d"}),
					fontWithColor('15', {fontSize = 20,text = __('天'), color = "d23d3d"}),
				}
			end
		else
			self.marketData.shelfLeftSeconds = 0
			shelfLeftSecondscon = {
				fontWithColor('15', {fontSize = 20, text = __('限时销售：'), color = "ae8668"}),
				fontWithColor('15', {fontSize = 20,text = string.formattedTime(checkint(0),'%02i:%02i:%02i') , color = "d23d3d"}),
			}
		end


	else
		shelfLeftSecondscon = {
			fontWithColor('15', {fontSize = 20, text = __('限时销售：'), color = "ae8668"}),
			fontWithColor('15', {fontSize = 20,text = string.formattedTime(checkint(0),'%02i:%02i:%02i') , color = "d23d3d"}),
		}
	end

	local Ctable = {
		{fontWithColor('15', {fontSize = 20, text = string.format(__('剩余购买次数:%d'), self:GetTimesNums()), color = "ae8668"})},
		-- {
		-- 	fontWithColor('15', {fontSize = 20, text = __('剩余购买'), color = "ae8668"}),
		-- 	fontWithColor('15', {fontSize = 20,text = self:GetTimesNums(), color = "ac5a4a"}),
		-- 	fontWithColor('15', {fontSize = 20,text = __('次'), color = "ae8668"}),
		-- },
		shelfLeftSecondscon,
		discountLeftcon,
	}
	local tempNUm = 0
	for i,v in ipairs(self.viewData.richLabel) do
		display.reloadRichLabel(v, { c = Ctable[i] })
		if i == 2 then
			if not self.marketData.shelfLeftSeconds then
				v:getParent():setVisible(false)
				tempNUm = tempNUm + 1
			else
				if self.marketData.shelfLeftSeconds <= 0 then
					v:getParent():setVisible(false)
					tempNUm = tempNUm + 1
				end
			end
		elseif i == 3 then
			if not self.marketData.discountLeftSeconds then
				v:getParent():setVisible(false)
				tempNUm = tempNUm + 1
			else
				if self.marketData.discountLeftSeconds <= 0 then
					v:getParent():setVisible(false)
					tempNUm = tempNUm + 1
				end
			end

		end
	end

	if tempNUm == 2 then
		scheduler.unscheduleGlobal(self.scheduler)
		self.preTime = nil
	end
end
function ShopPurchasePopup:GetTimesNums()
	local totalNum =  self.marketData.lifeLeftPurchasedNum
	local todayNum =  self.marketData.todayLeftPurchasedNum
	local times  = 0
	if  totalNum then
		times = totalNum > todayNum and todayNum or totalNum
	else
		times = todayNum
	end
	return checkint(times)
end
function ShopPurchasePopup:onExit()
	if self.scheduler then
		scheduler.unscheduleGlobal(self.scheduler)
		self.scheduler = nil
	end
end

function ShopPurchasePopup:ChooseNumBtnCallback( sender )
	PlayAudioByClickNormal()

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
		local times  =self:GetTimesNums()
		times = times > 0 and times or 1
		if checkint(self.marketData.stock) ~= -1  then
			if checkint(self.selectNum) >= checkint((times or 1)) then
				uiMgr:ShowInformationTips(string.fmt(__('数量最大值为_num_个'),{_num_ = times}))
				return
			end
		end
		self.selectNum = self.selectNum + 1
	end

	btn_num:getLabel():setString(tostring(self.selectNum))
	self.viewData.purchaseBtn:setUserTag(self.selectNum)
	self.viewData.priceNum:setString(tostring(self.selectNum*self.marketData.price))
	self.viewData.goldIcon:setPositionX(self.viewData.priceNum:getContentSize().width + 220)

end

function ShopPurchasePopup:SetNumBtnCallback( sender )
	PlayAudioByClickNormal()
	
	local tempData = {}
	tempData.callback = handler(self, self.numkeyboardCallBack)
	tempData.titleText = __('请输入需要购买的数量')
	tempData.nums = 3
	tempData.model = NumboardModel.freeModel

	local NumKeyboardMediator = require( 'Game.mediator.NumKeyboardMediator' )
	local mediator = NumKeyboardMediator.new(tempData)
	AppFacade.GetInstance():RegistMediator(mediator)
end



function ShopPurchasePopup:numkeyboardCallBack(data)
	if data then
		if data == '' then
			data = '1'
		end
		if checkint(data) <= 0 then
			data = 1
		end

		if self.marketData.todayLeftPurchasedNum then
			if self:GetTimesNums() > 0 then
				if checkint(data) > self:GetTimesNums() then
					data = self:GetTimesNums()
				end
			end
		end

		self.selectNum = checkint(data)
		self.viewData.btn_num:getLabel():setString(tostring(self.selectNum))
		self.viewData.purchaseBtn:setUserTag(self.selectNum)

		self.viewData.priceNum:setString(tostring(self.selectNum*self.marketData.price))
		self.viewData.goldIcon:setPositionX(self.viewData.priceNum:getContentSize().width + 220)
	end
end



function ShopPurchasePopup:close()
	self:CloseHandler()
end



return ShopPurchasePopup

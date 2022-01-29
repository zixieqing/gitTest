local Mediator = mvc.Mediator
---@class CardSkinShopViewMediator:Mediator
local CardSkinShopViewMediator = class("CardSkinShopViewMediator", Mediator)


local NAME = "CardSkinShopViewMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
---@type CardSkinShopCell
local CardSkinShopCell = require('Game.views.CardSkinShopCell')

local formatTime = nil

function CardSkinShopViewMediator:ctor(params, viewComponent )
	self.super:ctor(NAME,viewComponent)
	self.str = ''
	self.clickShopType = nil
	self.showTopUiType = 1
	self.shopData = {}
	self.allShelfLeftSeconds = {} --全部商品限时上架剩余秒数.
	self.allPreLeftSeconds = {} --全部商品限时上架 上次剩余秒数.
	self.gridContentOffset = cc.p(0,0)
	if params then
		if params.type then
			self.showTopUiType = params.type
		end
		if params.data then
			self.shopData = params.data
		end
	end
end

function CardSkinShopViewMediator:InterestSignals()
	local signals = {
		SIGNALNAMES.All_Shop_Buy_Callback,
	}

	return signals
end

function CardSkinShopViewMediator:ProcessSignal(signal )
	local name = signal:GetName()
	local body = signal:GetBody()
	if name == SIGNALNAMES.All_Shop_Buy_Callback then
		if signal:GetBody().requestData.name ~= 'CardSkinShopView' then return end
		-- uiMgr:AddDialog('common.RewardPopup', {rewards = body.rewards})
		local data = {}
		for i,v in ipairs(self.shopData) do
			if checkint(v.productId) == checkint(body.requestData.productId) then
				if checkint(v.type) == 2 then--一个一个购买否则一次性全部购买
					self.shopData[i].todayLeftPurchasedNum = v.todayLeftPurchasedNum - body.requestData.num
				else
					self.shopData[i].todayLeftPurchasedNum = 0
				end
				data = clone(v)
				break
			end
		end
		local Trewards = {}
		if next(data) ~= nil then
			if body.requestData.currency then
				local price_ = self:GetGoodsPrice(checknumber(data.sale[tostring(body.requestData.currency)]), checknumber(data.discount), checknumber(data.memberDiscount))
				table.insert(Trewards,{goodsId = body.requestData.currency, num = -price_})
			end
        end
		for i,v in ipairs(body.rewards) do
			table.insert(Trewards,{goodsId = v.goodsId, num = v.num})
		end


		-- dump(self.shopData)
		CommonUtils.DrawRewards(Trewards)

        --更新皮肤券的数量显示
        AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.CACHE_MONEY_UPDATE_UI)
		local scene = uiMgr:GetCurrentScene()
		if scene:GetDialogByTag( 5001 ) then
			scene:GetDialogByTag( 5001 ):runAction(cc.RemoveSelf:create())--购买详情弹出框
		end


		self.viewData.gridView:reloadData()
		self.viewData.gridView:setContentOffset(self.gridContentOffset)

		-- if self.ShowCardSkinLayer then
		-- 	self.ShowCardSkinLayer:UpdataUI()
		-- end

		-- 购买成功 显示获取界面
		self:BuyCardSkinCallback(checkint(data.goodsId))

		AppFacade.GetInstance():DispatchObservers(EVENT_PAY_SKIN_SUCCESS)
	end
end


function CardSkinShopViewMediator:Initial( key )
	self.super.Initial(self,key)

	local viewComponent  = require( 'Game.views.CommonShopView' ).new()
	self:SetViewComponent(viewComponent)

	local isRecommendOpen = gameMgr:GetUserInfo().isRecommendOpen
	local data = {
		shopData = self.shopData,   --商品数据
		isShowTopUI = true,         --是否显示顶部信息
		isUseGridView = true,       --是否使用滑动层
		showTopUiType = 6,	       	--顶部信息显示不同需求组合
	}

	if not isRecommendOpen then
		data.isShowTopUI = false
		data.showTopUiType = 4
	end

	viewComponent:InitShowUiAndTopUi(data)

	self.viewData = nil
	self.viewData = viewComponent.viewData

	for i,v in ipairs(self.shopData) do
		-- v.discount = 20
		--  v.shelfLeftSeconds = 20
		if v.shelfLeftSeconds then
			if v.shelfLeftSeconds ~= -1 then
				if not self.allShelfLeftSeconds[tostring(i)] then
					self.allShelfLeftSeconds[tostring(i)] = {}
				end
				self.allShelfLeftSeconds[tostring(i)] = v
			end
		end
	end
	-- dump(self.shopData)

	local gridView = self.viewData.gridView
	gridView:setSizeOfCell(cc.size(206, 420))--206
    gridView:setDataSourceAdapterScriptHandler(handler(self,self.OnDataSourceAction))

    gridView:setCountOfCell(table.nums(self.shopData))
    gridView:reloadData()

	local promoterBtn = self.viewData.promoterBtn
	display.commonUIParams(promoterBtn, {cb = function ()
		local PromotersMediator = require( 'Game.mediator.PromotersMediator' )
		local mediator = PromotersMediator.new()
		AppFacade.GetInstance():RegistMediator(mediator)
	end})

	self.scheduler = nil
	if next(self.allShelfLeftSeconds) ~= nil then

		for k,v in pairs(self.allShelfLeftSeconds) do
			self.allPreLeftSeconds[k] = os.time()
		end
    	self.scheduler = scheduler.scheduleGlobal(handler(self, self.scheduleCallback), 1)
	end
end

--[[
定时器回调
--]]
function CardSkinShopViewMediator:scheduleCallback()
	local gridView = self.viewData.gridView
	local num  = 0
	for k,v in pairs(self.allShelfLeftSeconds) do
		if  v.shelfLeftSeconds ~= -1 then
			if v.shelfLeftSeconds > 0 then
				local curTime = os.time()
				local preTime = self.allPreLeftSeconds[k]
				v.shelfLeftSeconds = v.shelfLeftSeconds - (curTime - preTime)
				self.allPreLeftSeconds[k] = curTime
			end
			local cell = gridView:cellAtIndex(checkint(k) - 1)
			if cell then
				if v.shelfLeftSeconds <= 0 then
					num  = num + 1
					v.shelfLeftSeconds = 0
					cell.refreshTimeLabel:setString(__('已结束'))
				else
					-- cell.refreshTimeLabel:setString(string.formattedTime(checkint(v.shelfLeftSeconds),'%02i:%02i:%02i'))
					cell.refreshTimeLabel:setString(formatTime(checkint(v.shelfLeftSeconds)))
				end

			end
		else
			num  = num + 1
		end
	end

	if num == table.nums(self.allShelfLeftSeconds) then
		scheduler.unscheduleGlobal(self.scheduler)
		self.scheduler = nil
		self.allPreLeftSeconds = {}
	end

	-- print('1')
	-- dump(self.shopData)
end


function CardSkinShopViewMediator:UpDataUI()
	-- dump(self.shopData.products)
	self:InitTopUI()
    self.viewData.gridView:setCountOfCell(table.nums(self.shopData))
    self.viewData.gridView:reloadData()
end

function CardSkinShopViewMediator:OnDataSourceAction(p_convertview,idx)
    local pCell = p_convertview
    local pButton = nil
    local index = idx + 1
    local sizee = cc.size(206 , 420)
    local tempData = self.shopData[index]

   	if pCell == nil then

        pCell = CardSkinShopCell.new(sizee)
        display.commonUIParams(pCell.toggleView, {animate = false, cb = handler(self, self.CellButtonAction)})
    else

    end
	xTry(function()
		local skinId   = checkint(tempData.goodsId)
		local drawPath = CardUtils.GetCardDrawPathBySkinId(skinId)
		pCell.imgHero:setTexture(drawPath)

		local skinConf = CardUtils.GetCardSkinConfig(skinId) or {}
		local cardDrawName = ""
		if skinConf then
			cardDrawName = skinConf.photoId
		end

		local locationInfo = CommonUtils.GetConfig('cards', 'coordinate', cardDrawName)
		if nil == locationInfo or not locationInfo[COORDINATE_TYPE_TEAM] then
			print('\n**************\n', '立绘坐标信息未找到', cardDrawName, '\n**************\n')
			locationInfo = {x = 0, y = 0, scale = 50, rotate = 0}
		else
			locationInfo = locationInfo[COORDINATE_TYPE_TEAM]
		end
		pCell.imgHero:setScale(locationInfo.scale/100)
		pCell.imgHero:setRotation( (locationInfo.rotate))
		pCell.imgHero:setPosition(cc.p(locationInfo.x ,(-1)*(locationInfo.y-540) - 148))

		local cardConf  = CardUtils.GetCardConfig(skinConf.cardId) or {}
		local qualityId = cardConf.qualityId
		pCell.imgBg:setTexture(CardUtils.GetCardTeamBgPathBySkinId(skinId))

		pCell.toggleView:setTag(index)
		pCell:setTag(index)
		local priceTable = {}
		local originalPriceTable  = {}
		for i, v in pairs(tempData.sale or {}) do
			originalPriceTable[tostring(i)] = v
		end

		for i, v in pairs(tempData.sale or {}) do
			priceTable[tostring(i)] = self:GetGoodsPrice(checknumber(v), checknumber(tempData.discount), checknumber(tempData.memberDiscount))
		end

		display.commonLabelParams(pCell.skinNameLabel , {text = tostring(skinConf.name) , reqW = 180})
		pCell.cardNameLabel:setString(tostring(cardConf.name))

		local cData = {}
		local count = table.nums(priceTable)
		local index = 0
		for i, v in pairs(priceTable or {}) do
			index = index +1
			cData[#cData+1] = fontWithColor('14' , {text = v  , fontSize = 22})
			cData[#cData+1] = {img = CommonUtils.GetGoodsIconPathById(i) , scale = 0.2 }
			if index ~=  count  then
				cData[#cData+1] = fontWithColor('14' , {text = '/' .."  " , fontSize = 22 })
			end
		end
		pCell.markerBtn:getLabel():setString(__('热卖'))
		if next(cData)  then
			display.reloadRichLabel(pCell.priceRichLabel , {
				c = cData
			})
		end
		local rect = pCell.priceRichLabel:getBoundingBox()
		local contentSize = pCell.priceRichLabel:getContentSize()
		local standerWidth = 180
		if rect.width  > standerWidth then
			pCell.priceRichLabel:setScale(standerWidth/contentSize.width)
		end
		pCell.discountLayout:setVisible(false)
		if tempData.discount  then--有折扣价格
			if checkint(tempData.discount) < 100 and checkint(tempData.discount) > 0 then
				pCell.discountLayout:setVisible(true )
				local cData = {}
				local count = table.nums(originalPriceTable)
				local index = 0
				for i, v in pairs(originalPriceTable or {}) do
					index = index +1
					cData[#cData+1] = fontWithColor('14' , {text = v  , fontSize = 22})

					cData[#cData+1] = {img = CommonUtils.GetGoodsIconPathById(i) , scale = 0.2 }

					if index ~=  count  then
						cData[#cData+1] = fontWithColor('14' , {text = "/" .."  " , fontSize = 22 })
					end
				end
				display.reloadRichLabel(pCell.discountRichLabel ,{ c = cData})
				pCell.markerBtn:getLabel():setString(string.format(__('%s折'), CommonUtils.GetDiscountOffFromCN(tempData.discount)))
				local rect = pCell.discountRichLabel:getBoundingBox()
				local contentSize = pCell.discountRichLabel:getContentSize()
				if rect.width  > standerWidth then
					pCell.discountRichLabel:setScale(standerWidth/contentSize.width)
				end
			end
		end
		CommonUtils.AddRichLabelTraceEffect(pCell.priceRichLabel)
		-- dump(tempData)
		pCell.topBg:setVisible(false)
		if tempData.shelfLeftSeconds and tempData.shelfLeftSeconds > 0 then--限时上架剩余秒数.
			pCell.topBg:setVisible(true)
			pCell.refreshTimeLabel:setString(formatTime(checkint(tempData.shelfLeftSeconds)))
		end
		local height = pCell.bottomSize.height -20
		local bottonHeight = 20
		pCell.isHasLabel:setVisible(false)
		pCell.isHasImg:setVisible(false)
		pCell.markerBtn:setVisible(true)
		if app.cardMgr.IsHaveCardSkin(tempData.goodsId) then
			pCell.priceRichLabel:setVisible(false)
			pCell.markerBtn:setVisible(false)
			pCell.isHasImg:setVisible(true)
			pCell.isHasLabel:setVisible(true)
			pCell.cardNameLabel:setPositionY( height /2 + bottonHeight)
			pCell.skinNameLabel:setPositionY( height /3* 2.5 + bottonHeight)
			pCell.isHasLabel:setPositionY(height /3* 0.5 + bottonHeight)
		elseif checkint(tempData.discount) < 100 and checkint(tempData.discount) > 0 then
			pCell.cardNameLabel:setPositionY( pCell.bottomSize.height  /4* 2.5 )
			pCell.skinNameLabel:setPositionY( pCell.bottomSize.height  /4* 3.5 )
			pCell.priceRichLabel:setPositionY(pCell.bottomSize.height  /4* 0.5 )
			pCell.discountLayout:setPositionY(pCell.bottomSize.height  /4* 1.5)
			pCell.discountLayout:setVisible(true)
		else
			pCell.cardNameLabel:setPositionY( pCell.bottomSize.height  /2 )
			pCell.skinNameLabel:setPositionY( pCell.bottomSize.height  /3* 2.5 )
			pCell.priceRichLabel:setPositionY(pCell.bottomSize.height  /3* 0.5 )
		end

	end,__G__TRACKBACK__)

    return pCell
end

function CardSkinShopViewMediator:CellButtonAction(sender)
	local tag = sender:getTag()
	-- dump(tag)
	local data = self.shopData[tag]

	self.gridContentOffset = self.viewData.gridView:getContentOffset()

	self.clickIndex = tag
	if app.cardMgr.IsHaveCardSkin(data.goodsId) then
		uiMgr:ShowInformationTips(__('已经拥有该皮肤'))
		return
	end
	if checkint(data.todayLeftPurchasedNum) > 0 or checkint(data.lifeStock) == -1 then

		local callBack = function( sender )
			print(self.clickIndex)
			self:PurchaseBtnCallback( )
		end
		local cancelCallback = function( sender )
			self.ShowCardSkinLayer = nil
		end
		local priceTable = {}
		for i, v in pairs(data.sale or {}) do
			priceTable[tostring(i)] = self:GetGoodsPrice(checknumber(v), checknumber(data.discount), checknumber(data.memberDiscount))
		end
		local ShowCardSkinLayer = require('common.CommonCardGoodsDetailView').new({
			goodsId = checkint(data.goodsId),
			consumeConfig = {
				priceTable = priceTable ,
			},
			confirmCallback = handler(self, self.PurchaseBtnClickHandler),
			cancelCallback = cancelCallback
		})
		---@type  ShopMediator
		local mediator =  self:GetFacade():RetrieveMediator("ShopMediator")
		if mediator then
			mediator:GetViewComponent():addChild(ShowCardSkinLayer)
			ShowCardSkinLayer:setPosition(display.center)
		end

		--scene:AddDialog(ShowCardSkinLayer)
		self.ShowCardSkinLayer = ShowCardSkinLayer
	else
		uiMgr:ShowInformationTips(__('已购买'))
	end

end

--[[
购买按钮回调
--]]
function CardSkinShopViewMediator:PurchaseBtnClickHandler(sender)
	local tag = self.clickIndex
	local data = self.shopData[tag]

	------------ 检查商品是否可以购买 ------------
	-- 库存
	if (0 >= checkint(data.stock)) or
		(-1 ~= checkint(data.lifeStock) and 0 >= checkint(data.lifeStock)) then

		uiMgr:ShowInformationTips(__('库存不足!!!'))
		return

	end

	-- 购买次数
	if 0 >= checkint(data.todayLeftPurchasedNum) or
		(-1 ~= checkint(data.lifeLeftPurchasedNum) and 0 >= checkint(data.lifeLeftPurchasedNum)) then

		uiMgr:ShowInformationTips(__('购买次数不足!!!'))
		return

	end

	-- 上架时间
	if 0 == checkint(data.shelfLeftSeconds) then

		uiMgr:ShowInformationTips(__('商品已下架!!!'))
		return

	end

	-- 货币是否足够
	local discount, memberDiscount = 100, 100

	if 0 ~= checkint(data.discountLeftSeconds) then
		discount, memberDiscount = checknumber(data.discount), checknumber(data.memberDiscount)
	end
	local consumeGoodsId = sender:getTag()
	local price = self:GetGoodsPrice(checkint(data.sale[tostring(consumeGoodsId)]), discount, memberDiscount)
	local consumeGoodsConfig = CommonUtils.GetConfig('goods', 'goods', consumeGoodsId)
	if price > gameMgr:GetAmountByGoodId(consumeGoodsId) then
		uiMgr:ShowInformationTips(string.format(__('%s不足!!!'), tostring(consumeGoodsConfig.name)))
		uiMgr:AddDialog("common.GainPopup", {goodId = checkint(consumeGoodsId)})
		return
	end
	------------ 检查商品是否可以购买 ------------

	-- 可以购买 弹出确认框
	local commonTip = require('common.CommonTip').new({
		text = __('确认购买?'),
		descrRich = {fontWithColor('8',{ text =__('购买前请再次确认价格') .. "\n" }) ,
					 fontWithColor('14',{ text = price , color = "#826d5e"}),
					 { img = CommonUtils.GetGoodsIconPathById(consumeGoodsId) , scale = 0.2  }

		} ,
		descrRichOutLine = {price},
		callback = function ()
			self:SendSignal(COMMANDS.COMMANDS_All_Shop_Buy,{productId = data.productId, num = 1, name = 'CardSkinShopView' , currency = consumeGoodsId })
		end
	})
	CommonUtils.AddRichLabelTraceEffect(commonTip.descrTip , nil , nil ,{2})
	commonTip:setPosition(display.center)
	uiMgr:GetCurrentScene():AddDialog(commonTip)

end

function CardSkinShopViewMediator:PurchaseBtnCallback(  )
	local tag = self.clickIndex
	local data = self.shopData[tag]
	local money = gameMgr:GetAmountByGoodId(SKIN_COUPON_ID)
	local des = __('外观券')
    if checkint(data.currency) == SKIN_COUPON_ID then
        local price = data.price
        if data.discount  then--有折扣价格
            if checkint(data.discount) < 100 and checkint(data.discount) > 0 then
                price = data.discount * data.price / 100
            end
        end
        if checkint(money) >= checkint(price) then
            self:SendSignal(COMMANDS.COMMANDS_All_Shop_Buy,{productId = data.productId,num = 1,name = 'CardSkinShopView'})
		else
			local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
			uiMgr:AddDialog("common.GainPopup", {goodId = checkint(data.currency)})
        end
    end
end

formatTime = function (seconds)
	local c = nil
	if seconds >= 86400 then
		local day = math.floor(seconds/86400)
		local overflowSeconds = seconds - day * 86400
		local hour = math.floor(overflowSeconds / 3600)

		c = string.fmt(__('_num1_天'), {['_num1_'] = tostring(day)})
	else
		local hour   = math.floor(seconds / 3600)
		local minute = math.floor((seconds - hour*3600) / 60)
		local sec    = (seconds - hour*3600 - minute*60)
		c = string.format("%.2d:%.2d:%.2d", hour, minute, sec)
	end
	return c
end

--[[
皮肤购买成功
@params skinId int 皮肤id
--]]
function CardSkinShopViewMediator:BuyCardSkinCallback(skinId)
	-- 关闭购买界面
	if nil ~= self.ShowCardSkinLayer then
		self.ShowCardSkinLayer:setVisible(false)
		self.ShowCardSkinLayer:runAction(cc.RemoveSelf:create())
		self.ShowCardSkinLayer = nil
	end

	uiMgr:ShowInformationTips(__('购买成功!!!'))

	local layerTag = 7218
	local getCardSkinView = require('common.CommonCardGoodsShareView').new({
		goodsId = skinId,
		confirmCallback = function (sender)
			-- 确认按钮 关闭此界面
			local layer = uiMgr:GetCurrentScene():GetDialogByTag(layerTag)
			if nil ~= layer then
				layer:setVisible(false)
				layer:runAction(cc.RemoveSelf:create())
			end
		end
	})
	display.commonUIParams(getCardSkinView, {ap = cc.p(0.5, 0.5), po = display.center})
	uiMgr:GetCurrentScene():AddDialog(getCardSkinView)
	getCardSkinView:setTag(layerTag)
end

function CardSkinShopViewMediator:OnRegist(  )
	local ShopCommand = require( 'Game.command.ShopCommand')
	self:GetFacade():RegistSignal(COMMANDS.COMMANDS_All_Shop_Buy, ShopCommand)

end

function CardSkinShopViewMediator:OnUnRegist(  )
	--称出命令
	if self.scheduler then
		scheduler.unscheduleGlobal(self.scheduler)
		self.scheduler = nil
	end

	-- local scene = uiMgr:GetCurrentScene()
	-- scene:RemoveDialog(self.viewComponent)
	-- self:GetFacade():UnRegsitSignal(COMMANDS.COMMANDS_All_Shop_Buy)

end

--[[
获取道具购买价格
@params price int 原始价格
@params discount int 普通折扣 百分数
@params memberDiscount int 会员折扣 百分数
@return dicountedPrice, discount int, int 打折后的真实价格, 折扣 百分数
--]]
function CardSkinShopViewMediator:GetGoodsPrice(price, discount, memberDiscount)
	local discountedPrice = checknumber(price)
	local discount_ = 100
	local reverse_ = 0.01

	if nil ~= memberDiscount then
		if (0 < checknumber(memberDiscount) and 100 > checknumber(memberDiscount)) then
			-- 有会员打折
			discountedPrice = math.round(discountedPrice * memberDiscount * reverse_)
			discount_ = memberDiscount
		end
	end

	if nil ~= discount and 100 <= discount_ then
		-- 当不存在会员打折时 检查是否存在普通打折
		if (0 < checknumber(discount) and 100 > checknumber(discount)) then
			-- 有普通打折
			discountedPrice = math.round(discountedPrice * discount * reverse_)
			discount_ = discount
		end
	end

	return discountedPrice, discount_
end

return CardSkinShopViewMediator

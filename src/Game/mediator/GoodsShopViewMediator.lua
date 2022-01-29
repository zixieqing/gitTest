---@type Mediator
local Mediator = mvc.Mediator

local GoodsShopViewMediator = class("GoodsShopViewMediator", Mediator)
local FeatureName = {
	["shop_tag_iconid_1"] = __('推荐'),
	["shop_tag_iconid_2"] = __('热卖'),
	["shop_tag_iconid_3"] = __('超值'),
	["shop_tag_iconid_4"] = __('特惠'),
	["shop_tag_iconid_5"] = __('限购一次'),
	["shop_tag_iconid_6"] = __('每日限购')
}

local NAME = "GoodsShopViewMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local CommonShopCell = require('Game.views.CommonShopCell')

local formatTime = nil

function GoodsShopViewMediator:ctor(params, viewComponent )
	self.super:ctor(NAME,viewComponent)
	self.str = ''
	self.clickShopType = nil
	self.showTopUiType = 1
	self.shopData = {}
	self.allShelfLeftSeconds = {} --全部商品限时上架剩余秒数.
	self.allPreLeftSeconds   = {} --全部商品限时上架 上次剩余秒数.
	if params then
		if params.type then
			self.showTopUiType = params.type
		end
		if params.data then
			self.shopData = params.data
		end
	end
	-- dump(self.shopData)
end

function GoodsShopViewMediator:InterestSignals()
	local signals = {
		SIGNALNAMES.All_Shop_Buy_Callback,
	}

	return signals
end

function GoodsShopViewMediator:ProcessSignal(signal )
	local name = signal:GetName()
	print(name)
	local body = signal:GetBody()
	if name == SIGNALNAMES.All_Shop_Buy_Callback then
		if signal:GetBody().requestData.name ~= 'GoodsShopView' then return end
		uiMgr:AddDialog('common.RewardPopup', {rewards = body.rewards})
		local data = {}
		for i,v in ipairs(self.shopData) do
			if checkint(v.productId) == checkint(body.requestData.productId) then
				if checkint(v.type) == 2 then--一个一个购买否则一次性全部购买
					self.shopData[i].todayLeftPurchasedNum = v.todayLeftPurchasedNum - body.requestData.num
					self.shopData[i].lifeLeftPurchasedNum =  v.lifeLeftPurchasedNum - body.requestData.num
				else
					self.shopData[i].todayLeftPurchasedNum = 0
				end
				data = clone(v)
				break
			end
		end
		local Trewards = {}
		if next(data) ~= nil then
			if data.discount  then--说明有折扣。价格根据折扣价格走
				if checkint(data.discount) < 100 and checkint(data.discount) > 0 then
					data.price = data.price * data.discount / 100
				end
			end
			if checkint(data.currency) == checkint(GOLD_ID) then
				local goldNum = -data.price * checkint(body.requestData.num or 1)
				table.insert(Trewards,{goodsId = GOLD_ID, num = goldNum})
			elseif checkint(data.currency) == checkint(DIAMOND_ID) then
				local diamondNum = -data.price * checkint(body.requestData.num or 1)
				table.insert(Trewards,{goodsId = DIAMOND_ID, num = diamondNum})
			elseif checkint(data.currency) == checkint(TIPPING_ID) then
				local tipNum = -data.price * checkint(body.requestData.num or 1)
				table.insert(Trewards,{goodsId = TIPPING_ID, num = tipNum})
            else
                local tipNum = -data.price * checkint(body.requestData.num or 1)
                table.insert(Trewards,{goodsId = data.currency, num = tipNum})
			end
		end
		-- dump(self.shopData)
		CommonUtils.DrawRewards(Trewards)

		local scene = uiMgr:GetCurrentScene()
		if scene:GetDialogByTag( 5001 ) then
			scene:GetDialogByTag( 5001 ):runAction(cc.RemoveSelf:create())--购买详情弹出框
		end

		AppFacade.GetInstance():DispatchObservers(EVENT_GOODS_COUNT_UPDATE, body.rewards)
	end
	self:UpDataUI()
end


function GoodsShopViewMediator:Initial( key )
	self.super.Initial(self,key)

	local viewComponent  = require( 'Game.views.CommonShopView' ).new()
	self:SetViewComponent(viewComponent)

	local data = {
		shopData = self.shopData,    --商品数据
		isShowTopUI = false,         --是否显示顶部信息
		isUseGridView = true,        --是否使用滑动层
		showTopUiType = 5,	         --顶部信息显示不同需求组合
	}
	viewComponent:InitShowUiAndTopUi(data)

	self.viewData = nil
	self.viewData = viewComponent.viewData

	for i,v in ipairs(self.shopData) do
		-- v.shelfLeftSeconds = 188
		-- v.discountLeftSeconds = 10
		-- v.discount = 20
		if v.shelfLeftSeconds ~= -1 or v.discountLeftSeconds ~= -1 then
			if not self.allShelfLeftSeconds[tostring(i)] then
				self.allShelfLeftSeconds[tostring(i)] = {}
			end
			self.allShelfLeftSeconds[tostring(i)] = v
		end
	end

	local gridView = self.viewData.gridView

    gridView:setDataSourceAdapterScriptHandler(handler(self,self.OnDataSourceAction))

    gridView:setCountOfCell(table.nums(self.shopData))
    gridView:reloadData()


	self.scheduler = nil
	if next(self.allShelfLeftSeconds) ~= nil then
		for k,v in pairs(self.allShelfLeftSeconds) do
			self.allPreLeftSeconds[k] = os.time()
		end
    	self.scheduler = scheduler.scheduleGlobal(handler(self, self.scheduleCallback), 1)
	end

	-- dump(self.allShelfLeftSeconds)
end

--[[
定时器回调
--]]
function GoodsShopViewMediator:scheduleCallback()
	local gridView = self.viewData.gridView
	local num  = 0
	for k,v in pairs(self.allShelfLeftSeconds) do
		if v.shelfLeftSeconds then
			if v.shelfLeftSeconds ~= -1 then
				-- if v.shelfLeftSeconds > 0 then
				-- 	v.shelfLeftSeconds = v.shelfLeftSeconds - 1

				-- 	local shelfLeftSeconds = v.shelfLeftSeconds
				-- 	local str = formatTime(shelfLeftSeconds)
				-- 	if cell then
				-- 		cell.refreshTimeLabel:setString(str)
				-- 	end
				-- elseif v.shelfLeftSeconds <= 0 then
				-- 	v.shelfLeftSeconds = 0
				-- 	num = num + 1
				-- 	if cell then
				-- 		cell.refreshTimeLabel:setString(__('已结束'))
				-- 	end
				-- end
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
				num = num + 1
			end
		end


		if v.discountLeftSeconds then
			if v.discountLeftSeconds ~= -1 then
				if v.discountLeftSeconds > 0 then
					v.discountLeftSeconds = v.discountLeftSeconds - 1
				else
					v.discountLeftSeconds = 0
					cell.discountLine:setVisible(false)
					cell.discountPriceNum:setVisible(false)
					cell.discountCastIcon:setVisible(false)

					cell.numLabel:setString(v.price or '9999')
					cell.numLabel:setPositionX(101)
					cell.castIcon:setPositionX(cell.castIcon:getPositionX())
					self.shopData[checkint(k)].discount = nil
				end
			end
		end
	end

	if num == table.nums(self.allShelfLeftSeconds) then
		scheduler.unscheduleGlobal(self.scheduler)
		self.scheduler = nil
		self.allPreLeftSeconds = {}
	end
	-- dump(self.shopData)
end


function GoodsShopViewMediator:UpDataUI()
	-- dump(self.shopData.products)
	-- self:InitTopUI()
    self.viewData.gridView:setCountOfCell(table.nums(self.shopData))
    self.viewData.gridView:reloadData()
end


function GoodsShopViewMediator:OnDataSourceAction(p_convertview,idx)
    local pCell = p_convertview
    local pButton = nil
    local index = idx + 1
    local sizee = cc.size(202 , 252)
    local tempData = self.shopData[index]
   	if pCell == nil then
        pCell = CommonShopCell.new(sizee)
        pCell.toggleView:setOnClickScriptHandler(handler(self,self.CellButtonAction))
    else

    end
	xTry(function()
		pCell.goodNode:setTouchEnabled(false)
		pCell.goodNode:RefreshSelf({goodsId = tempData.goodsId,amount = tempData.goodsNum})
		pCell.toggleView:setTag(index)
		pCell:setTag(index)
		pCell.leftTimesLabel:setTag(index)

		-- pCell.goodNode:setOnClickScriptHandler(function(sender)
		-- 	uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = tempData.goodsId, type = 1})
		-- end)
		pCell.numLabel:setString(tostring(tempData.price))
		pCell.numLabel:setPositionY(- 8 )
		pCell.castIcon:setTexture(_res(CommonUtils.GetGoodsIconPathById(tempData.currency)))
		pCell.castIcon:setPosition(pCell.numLabel:getPositionX()+pCell.numLabel:getBoundingBox().width*0.5 + 4, -8)
        local priceHotImage = pCell:getChildByName('HOTIMAGE')
		local priceHotLabel = pCell:getChildByName('HOTIMAGELABEL')
        if tempData.icon and string.len(tempData.icon) > 0 then
            local filePath = _res(string.format('ui/home/commonShop/%s.png',tempData.icon))
            if priceHotImage then
                if cc.FileUtils:getInstance():isFileExist(filePath) then
                    priceHotImage:setVisible(true)
					priceHotLabel:setVisible(true)
					priceHotImage:setTexture(filePath)
					display.commonLabelParams(priceHotLabel , fontWithColor('14', {reqW = 180 ,  ttf = false,text = (tempData.iconTitle ~= '' and tempData.iconTitle) or FeatureName[tempData.icon] }))
					local contentSize = display.getLabelContentSize( priceHotLabel)

					local priceHotImageSize = priceHotImage:getContentSize()
					local maxWidth = 190
					maxWidth = contentSize.width + 20 > maxWidth and maxWidth or contentSize.width + 20
					priceHotImage:setScaleX(maxWidth/ priceHotImageSize.width )

                else
					priceHotLabel:setVisible(false)
                    priceHotImage:setVisible(false)
                end
            end
        else
            if priceHotImage then
				priceHotLabel:setVisible(false)
                priceHotImage:setVisible(false)
            end
        end

		pCell.refreshTimeLabel:setVisible(false)
		pCell.refreshLabel:setVisible(false)
		if tempData.shelfLeftSeconds then
			if tempData.shelfLeftSeconds ~= -1 and tempData.shelfLeftSeconds >= 0 then--限时上架剩余秒数.
				pCell.refreshTimeLabel:setVisible(true)
				pCell.refreshLabel:setVisible(true)
				-- pCell.refreshTimeLabel:setString(string.formattedTime(checkint(tempData.shelfLeftSeconds),'%02i:%02i:%02i'))
				local shelfLeftSeconds = checkint(tempData.shelfLeftSeconds)
				local str = formatTime(shelfLeftSeconds)
				pCell.refreshTimeLabel:setString(str)

				local refreshTimeLabelSize = display.getLabelContentSize(pCell.refreshTimeLabel)
				local refreshLabelSize = display.getLabelContentSize(pCell.refreshLabel)
				pCell.refreshLabel:setPositionX(100 - refreshTimeLabelSize.width / 2 - 1)
				pCell.refreshTimeLabel:setPositionX(100 + refreshLabelSize.width / 2 + 1)

			end
		end
		if checkint(tempData.lifeStock) == -1 then
	        display.reloadRichLabel(pCell.leftTimesLabel, { c = {fontWithColor('8', { color = "ae8668" ,fontSize = 20 , text = __('今日剩余购买')}) ,
	        	fontWithColor('8', { color = "#ac5a4a" ,fontSize = 20 , text = tostring(tempData.todayLeftPurchasedNum)}),
	        	fontWithColor('8', { color = "#ae8668" ,fontSize = 20 , text = __('次数')}) }})

			pCell.sellLabel:setVisible(false)
			pCell.toggleView:setNormalImage(_res('ui/home/commonShop/shop_btn_goods_default.png'))
			pCell.toggleView:setSelectedImage(_res('ui/home/commonShop/shop_btn_goods_default.png'))

			pCell.leftTimesLabel:setVisible(false)
			
		else

			if tempData.todayLeftPurchasedNum  then
				local callfuncOne = function()
					pCell.leftTimesLabel:setVisible(true)
			        display.reloadRichLabel(pCell.leftTimesLabel, { c = {fontWithColor('8', { color = "ae8668" ,fontSize = 20 , text = __('今日剩余购买')}) ,
			        	fontWithColor('8', { color = "#ac5a4a" ,fontSize = 20 , text = tostring(tempData.todayLeftPurchasedNum)}),
			        	fontWithColor('8', { color = "#ae8668" ,fontSize = 20 , text = __('次数')}) }})


					pCell.sellLabel:setVisible(false)
					pCell.toggleView:setNormalImage(_res('ui/home/commonShop/shop_btn_goods_default.png'))
					pCell.toggleView:setSelectedImage(_res('ui/home/commonShop/shop_btn_goods_default.png'))

					pCell.leftTimesLabel:setOnTextRichClickScriptHandler(handler(self,self.CellButtonAction))
				end


				local callfuncTwo  = function()
					pCell.leftTimesLabel:setVisible(false)
					pCell.sellLabel:setVisible(true)
					pCell.toggleView:setNormalImage(_res('ui/home/commonShop/shop_btn_goods_sellout.png'))
					pCell.toggleView:setSelectedImage(_res('ui/home/commonShop/shop_btn_goods_sellout.png'))

					pCell.refreshTimeLabel:setVisible(false)
					pCell.refreshLabel:setVisible(false)
				end
				local data  =tempData
				local totalNum = checkint(data.lifeLeftPurchasedNum)
				local todayNum = checkint(data.todayLeftPurchasedNum)
				if  todayNum >= totalNum then
					pCell.leftTimesLabel:setVisible(true)
					if totalNum > 0  then
						callfuncOne()
						display.reloadRichLabel(pCell.leftTimesLabel , {
							c = {
								{text = string.fmt(__("限购_num_次"), {_num_ = totalNum}), fontSize = 20, color = '5c5c5c'}
							}})
						pCell.toggleView:setNormalImage(_res('ui/home/commonShop/shop_btn_goods_default.png'))
						pCell.toggleView:setSelectedImage(_res('ui/home/commonShop/shop_btn_goods_default.png'))

						pCell.leftTimesLabel:setOnTextRichClickScriptHandler(handler(self,self.CellButtonAction))

					else
						callfuncTwo()
						display.reloadRichLabel(pCell.leftTimesLabel, {
							c = {
								fontWithColor(14, {text = __('已售罄') })
							}})
					end
				else
					if todayNum > 0 then
						callfuncOne()
							display.reloadRichLabel(pCell.leftTimesLabel  , {
						c = {
						{text = string.fmt(__("今日可购_num_次"), {_num_ = todayNum}),fontSize = 20, color = '5c5c5c'}
						}})
					elseif  todayNum == 0 then
						callfuncOne()
						display.reloadRichLabel(pCell.leftTimesLabel  , {
							c = {
								{text =__('已售罄'),fontSize = 20, color = '5c5c5c'}
							}})
					end
				end
		    else
		    	if checkint(tempData.stock) > 0 then
					pCell.leftTimesLabel:setVisible(true)
			        display.reloadRichLabel(pCell.leftTimesLabel, { c = {fontWithColor('8', { color = "ae8668" ,fontSize = 20 , text = __('库存剩余')}) ,
			        	fontWithColor('8', { color = "ac5a4a" ,fontSize = 20 , text = tostring(tempData.stock)}),
			        	fontWithColor('8', { color = "ae8668" ,fontSize = 20 , text = __('次数')}) }})
					local leftTimesLabelSize =  pCell.leftTimesLabel:getContentSize()
					pCell.sellLabel:setVisible(false)
					pCell.toggleView:setNormalImage(_res('ui/home/commonShop/shop_btn_goods_default.png'))
					pCell.toggleView:setSelectedImage(_res('ui/home/commonShop/shop_btn_goods_default.png'))

					pCell.leftTimesLabel:setOnTextRichClickScriptHandler(handler(self,self.CellButtonAction))
		    	else
			    	pCell.leftTimesLabel:setVisible(false)

					pCell.sellLabel:setVisible(true)
					pCell.toggleView:setNormalImage(_res('ui/home/commonShop/shop_btn_goods_sellout.png'))
					pCell.toggleView:setSelectedImage(_res('ui/home/commonShop/shop_btn_goods_sellout.png'))

					pCell.refreshTimeLabel:setVisible(false)
					pCell.refreshLabel:setVisible(false)
		    	end
			end
		end
		local leftTimesLabelSize =  pCell.leftTimesLabel:getContentSize()
		if leftTimesLabelSize.width > 170  then
			local shoudlerScale  = 170 / leftTimesLabelSize.width
			pCell.leftTimesLabel:setScale(shoudlerScale)
		end
		pCell.discountLine:setVisible(false)
		pCell.discountPriceNum:setVisible(false)
		pCell.discountCastIcon:setVisible(false)
		pCell.discountBg:setVisible(false)


		if tempData.discount  then--有折扣价格
			if checkint(tempData.discount) < 100 and checkint(tempData.discount) > 0 then
				pCell.discountLine:setVisible(true)
				pCell.discountPriceNum:setVisible(true)
				pCell.discountCastIcon:setVisible(true)
				pCell.discountBg:setVisible(true)

				pCell.discountNum:setString(string.format(__('%s折'), tempData.discount/10))


				pCell.discountPriceNum:setString(tempData.price or '9999')
				pCell.discountCastIcon:setTexture(_res(CommonUtils.GetGoodsIconPathById(tempData.currency)))
				pCell.discountCastIcon:setPositionX(pCell.discountPriceNum:getPositionX()+pCell.discountPriceNum:getBoundingBox().width )

				pCell.numLabel:setString( tempData.price*tempData.discount/100 or '9999')
				pCell.numLabel:setPositionX(sizee.width * 0.5 + 40)
				pCell.castIcon:setPositionX(pCell.numLabel:getPositionX() + 30)

				pCell.discountPriceNum:setPositionY(pCell.numLabel:getPositionY())
				pCell.discountCastIcon:setPositionY(pCell.castIcon:getPositionY())
				pCell.discountLine:setPositionY(10)
			else
				pCell.discountLine:setVisible(false)
				pCell.discountPriceNum:setVisible(false)
				pCell.discountCastIcon:setVisible(false)
				pCell.discountBg:setVisible(false)
			end
		else
			pCell.discountLine:setVisible(false)
			pCell.discountPriceNum:setVisible(false)
			pCell.discountCastIcon:setVisible(false)
			pCell.discountBg:setVisible(false)
		end



	end,__G__TRACKBACK__)
    return pCell

end

function GoodsShopViewMediator:CellButtonAction(sender)
	local tag = sender:getTag()
	local data = self.shopData[tag]

	local callfunc =  function ()
		local tempdata  = clone(data)
		if checkint(tempdata.type) == 2 then--一个一个购买否则一次性全部购买
			tempdata.goodsNum = 1
		end
		local scene = uiMgr:GetCurrentScene()
		local marketPurchasePopup  = require('Game.views.ShopPurchasePopup').new({tag = 5001, mediatorName = "GoodsShopViewMediator", data = tempdata, btnTag = tag,showChooseUi = true,})
		display.commonUIParams(marketPurchasePopup, {ap = cc.p(0.5, 0.5), po = cc.p(display.width * 0.5, display.height * 0.5)})
		marketPurchasePopup:setTag(5001)
		scene:AddDialog(marketPurchasePopup)
		marketPurchasePopup.viewData.purchaseBtn:setOnClickScriptHandler(handler(self, self.PurchaseBtnCallback))
		marketPurchasePopup.viewData.purchaseBtn:setTag(tag)
	end
	local callfuncTwo = function()
		local totalNum = checkint(data.lifeLeftPurchasedNum)
		local todayNum = checkint(data.todayLeftPurchasedNum)
		if checkint(data.lifeStock) == -1 or checkint(data.stock) > 0 then
			if data.todayLeftPurchasedNum  then  -- 存在剩余购买次数
				local canNext = 1
				if todayNum >= totalNum then
					--限购次数显示
					if totalNum == 0 then
						uiMgr:ShowInformationTips(__('已售罄'))
						canNext = 0
					end
				else
					if todayNum <= 0 then
						uiMgr:ShowInformationTips(__('已售罄'))
						canNext = 0
					end
				end
				if canNext == 0 then return end
			end
			callfunc()
		else -- 不存在剩余购买次数
			uiMgr:ShowInformationTips(__('库存不足'))
		end
	end
	if checkint(data.shelfLeftSeconds)  ~= -1   then
		-- 限时上架剩余秒数
		if checkint(data.shelfLeftSeconds)  > 0  then
			callfuncTwo()
		else
			uiMgr:ShowInformationTips(__('道具剩余时间已结束'))
		end
	else
		callfuncTwo()
	end
end
function GoodsShopViewMediator:PurchaseBtnCallback( sender )
	local tag = sender:getTag()
	local num = sender:getUserTag()
	-- dump(num)
	local data = self.shopData[tag]
	if data.shelfLeftSeconds then
		if data.shelfLeftSeconds ~= -1 then
			if data.shelfLeftSeconds <= 0 then
				uiMgr:ShowInformationTips(__('出售时间已结束'))
				return
			end
		end
	end

	local money = 0
	local des = __('货币')
	if checkint(data.currency) == GOLD_ID then --金币
		des = __('金币')
		money = gameMgr:GetUserInfo().gold
	elseif checkint(data.currency) == DIAMOND_ID then -- 幻晶石
		des = __('幻晶石')
		money = gameMgr:GetUserInfo().diamond
	elseif checkint(data.currency) == TIPPING_ID then -- 小费
		des = __('小费')
		money = gameMgr:GetUserInfo().tip
    else
        money = gameMgr:GetAmountByIdForce(data.currency)
	    local t = CommonUtils.GetConfig('goods', 'goods',data.currency) or {}
        if t and t.name then
            des = t.name
        end
	end
	local price = data.price * checkint(num)

	if data.discount  then--有折扣价格
		if checkint(data.discount) < 100 and checkint(data.discount) > 0 then
			price = data.discount * data.price / 100 * checkint(num)
		end
	end

 	if checkint(money) >= checkint(price) then
 		self:SendSignal(COMMANDS.COMMANDS_All_Shop_Buy,{productId = data.productId,num = checkint(num),name = 'GoodsShopView'})
	else
		if GAME_MODULE_OPEN.NEW_STORE and checkint(data.currency) == DIAMOND_ID then
			app.uiMgr:showDiamonTips()
		else
			uiMgr:ShowInformationTips(string.fmt(__('_des_不足'),{_des_ = des}))
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

function GoodsShopViewMediator:OnRegist(  )
	local ShopCommand = require( 'Game.command.ShopCommand')
	self:GetFacade():RegistSignal(COMMANDS.COMMANDS_All_Shop_Buy, ShopCommand)

end

function GoodsShopViewMediator:OnUnRegist(  )
	--称出命令

	if self.scheduler then
		scheduler.unscheduleGlobal(self.scheduler)
		self.scheduler = nil
	end

end

return GoodsShopViewMediator

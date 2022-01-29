local Mediator = mvc.Mediator

local ChestShopViewMediator = class("ChestShopViewMediator", Mediator)


local NAME = "ChestShopViewMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local CommonShopCell = require('Game.views.DiamondShopCell')
local FeatureName = {
    ["shop_tag_iconid_1"] = __('推荐'),
    ["shop_tag_iconid_2"] = __('热卖'),
    ["shop_tag_iconid_3"] = __('超值'),
    ["shop_tag_iconid_4"] = __('特惠'),
    ["shop_tag_iconid_5"] = __('限购一次'),
    ["shop_tag_iconid_6"] = __('每日限购')
}
local formatTime = nil

function ChestShopViewMediator:ctor(params, viewComponent )
	self.super:ctor(NAME,viewComponent)
	self.str = ''
	self.clickShopType = nil
	self.showTopUiType = 1
	self.shopData = {}
    self.clickTag = 1
    self.allShelfLeftSeconds = {} --全部商品限时上架剩余秒数.
    self.allPreLeftSeconds   = {} --全部商品限时上架 上次剩余秒数.
    self.goodBuyState        = {} --全部商品 购买状态
	if params then
		if params.type then
			self.showTopUiType = params.type
		end
		if params.data then
			self.shopData = params.data
		end
    end
end

function ChestShopViewMediator:InterestSignals()
	local signals = {
		SIGNALNAMES.Restaurant_Shop_GetPayOrder_Callback,
        EVENT_PAY_MONEY_SUCCESS_UI,
        "APP_STORE_PRODUCTS",
	}

	return signals
end

function ChestShopViewMediator:ProcessSignal(signal )
	local name = signal:GetName()
	print(name)
	local body = signal:GetBody()
	-- dump(body)
	if name == SIGNALNAMES.Restaurant_Shop_GetPayOrder_Callback then
		if signal:GetBody().requestData.name ~= 'ChestShopView' then return end
		if body.orderNo then
	        if device.platform == 'android' or device.platform == 'ios' then
                if DEBUG > 0 and checkint(Platform.id) <= 1002 then
                    --mac机器上点击直接成功的逻辑
                    AppFacade.GetInstance():DispatchObservers(EVENT_PAY_MONEY_SUCCESS, {type = PAY_TYPE.PT_GIFT, rewards = {{goodsId = GOLD_ID, num = 10}}})
                else
                    local price = checkint(self.shopData[self.clickTag].price)
                    local AppSDK = require('root.AppSDK')
                    AppSDK.GetInstance():InvokePay({amount = price, property = body.orderNo,goodsId = tostring(self.shopData[self.clickTag].channelProductId),
                    goodsName = __('幻晶石'), quantifier = __('个'),price = 0.1, count = 1})
                end
			else
                --mac机器上点击直接成功的逻辑
                AppFacade.GetInstance():DispatchObservers(EVENT_PAY_MONEY_SUCCESS, {type = PAY_TYPE.PT_GIFT, rewards = {{goodsId = GOLD_ID, num = 10}}})
            end
		end
	elseif name == EVENT_PAY_MONEY_SUCCESS_UI then
		if checkint(body.type) == PAY_TYPE.PT_GIFT then
            local clickData = self.shopData[self.clickTag]
            local todayNum = checkint(clickData.todayLeftPurchasedNum)
            local totalNum = checkint(clickData.lifeLeftPurchasedNum)
            self.shopData[self.clickTag].lifeLeftPurchasedNum = math.max(totalNum - 1 , 0 )
            self.shopData[self.clickTag].todayLeftPurchasedNum =math.max(todayNum - 1 , 0 )
            local gridView = self.viewData.gridView
            if gridView then gridView:reloadData() end
		end
    elseif name == 'APP_STORE_PRODUCTS' then
        if isElexSdk() then
            local gridView = self.viewData.gridView
            gridView:setCountOfCell(table.nums(self.shopData))
            gridView:reloadData()
        end
	end
end


function ChestShopViewMediator:Initial( key )
	self.super.Initial(self,key)

	local viewComponent  = require( 'Game.views.CommonShopView' ).new()
	self:SetViewComponent(viewComponent)

	local data = {
		shopData = self.shopData,   --商品数据
		isShowTopUI = false,         --是否显示顶部信息
		isUseGridView = true,       --是否使用滑动层
		showTopUiType = 5,	       	--顶部信息显示不同需求组合
	}
	viewComponent:InitShowUiAndTopUi(data)
	self.viewData = nil
	self.viewData = viewComponent.viewData

	-- self:InitTopUI()

    local gridView = self.viewData.gridView
    if isElexSdk() then
        gridView:setSizeOfCell(cc.size(208 , 308))
    else
        gridView:setSizeOfCell(cc.size(208 , 258))
    end
    gridView:setDataSourceAdapterScriptHandler(handler(self,self.OnDataSourceAction))
    gridView:setCountOfCell(table.nums(self.shopData))
    gridView:reloadData()
    if isElexSdk() then
        local t = {}
        for name,val in pairs(self.shopData) do
            if val.channelProductId then
                table.insert(t, val.channelProductId)
            end
        end
        require('root.AppSDK').GetInstance():QueryProducts(t)
    end
    for i,v in ipairs(self.shopData) do
        if v.shelfLeftSeconds ~= -1 and v.todayLeftPurchasedNum > 0 then
			if not self.allShelfLeftSeconds[tostring(i)] then
				self.allShelfLeftSeconds[tostring(i)] = {}
			end
            self.allShelfLeftSeconds[tostring(i)] = v
            self.allPreLeftSeconds[tostring(i)] = os.time()
            self.goodBuyState[tostring(i)] = false
		end
	end

    self.scheduler = nil
	if next(self.allShelfLeftSeconds) ~= nil then
    	self.scheduler = scheduler.scheduleGlobal(handler(self, self.scheduleCallback), 1)
	end

end

function ChestShopViewMediator:scheduleCallback()
    local gridView = self.viewData.gridView
    local num  = 0

    for k,v in pairs(self.allShelfLeftSeconds) do
        if v.shelfLeftSeconds then
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
                    self.goodBuyState[k] = true
                -- else
                    -- cell.refreshTimeLabel:setString(string.formattedTime(checkint(v.shelfLeftSeconds),'%02i:%02i:%02i'))
                end
                cell.refreshTimeLabel:setString(formatTime(checkint(v.shelfLeftSeconds)))
            end
        else
            num = num + 1
        end
    end

    if num >= table.nums(self.allShelfLeftSeconds) then
		scheduler.unscheduleGlobal(self.scheduler)
		self.scheduler = nil
		self.allPreLeftSeconds = {}
	end
end

function ChestShopViewMediator:UpDataUI()
	self:InitTopUI()
    self.viewData.gridView:setCountOfCell(table.nums(self.shopData))
    self.viewData.gridView:reloadData()
end


function ChestShopViewMediator:InitTopUI()
	local refreshLabel     = self.viewData.refreshLabel
	local refreshBtn  	   = self.viewData.refreshBtn
	local refreshTimeLabel = self.viewData.refreshTimeLabel
	local selectBtn        = self.viewData.selectBtn
	local hasNumsLabel     = self.viewData.hasNumsLabel
	local diamondCostLabel = self.viewData.diamondCostLabel
	local refreshBtnLabel = self.viewData.refreshBtnLabel


	refreshLabel:setVisible(false)
	refreshBtn:setVisible(false)
	refreshTimeLabel:setVisible(false)
	selectBtn:setVisible(false)
	hasNumsLabel:setVisible(false)

end


function ChestShopViewMediator:OnDataSourceAction(p_convertview,idx)
    local pCell = p_convertview
    local pButton = nil
    local index = idx + 1
    local sizee = cc.size(208 , 258)
    if isElexSdk() then
        sizee = cc.size(208 , 308)
    end
    local tempData = self.shopData[index]
   	if pCell == nil then
        if isElexSdk() then
            pCell = CommonShopCell.new(sizee ,  true )
        else
            pCell = CommonShopCell.new(sizee)
        end

        pCell.toggleView:setOnClickScriptHandler(handler(self,self.CellButtonAction))
        local purchargeLabel = pCell:getChildByName('NUMLABEL')
        if purchargeLabel then
            display.commonUIParams(purchargeLabel, {fontSize = 20})
            display.commonUIParams(purchargeLabel, {po = cc.p(purchargeLabel:getPositionX(), 90)})
        end
        pCell.diamondLabel:setVisible(true)
    else

    end
	xTry(function()
		pCell.toggleView:setTag(index)
		pCell:setTag(index)
		pCell.goodNode:setScale(0.8)
		pCell.goodNode:setTexture(_res(CommonUtils.GetGoodsIconPathById(tempData.photo)))

		pCell.diamondImage:setVisible(false)
		pCell.sellLabel:setVisible(true)
        local priceHotImage = pCell:getChildByName('HOTIMAGE')
        local priceHotLabel = pCell:getChildByName('HOTIMAGELABEL')
        if tempData.icon and string.len(tempData.icon) > 0 then
            local filePath = _res(string.format('ui/home/commonShop/%s.png',tempData.icon))
            if priceHotImage then
                priceHotImage:setPosition(sizee.width+4 , sizee.height - 70 )
                priceHotLabel:setPosition(sizee.width-2 , sizee.height - 73 )
                if cc.FileUtils:getInstance():isFileExist(filePath) then
                    priceHotImage:setVisible(true)
                    priceHotLabel:setVisible(true)
                    priceHotImage:setTexture(filePath)
                    display.commonLabelParams(priceHotLabel , fontWithColor('14', {reqW = 120 , ttf =  false ,text = (tempData.iconTitle ~= '' and tempData.iconTitle) or FeatureName[tempData.icon]}))
                    local contentSize = display.getLabelContentSize( priceHotLabel)
                    local priceHotImageSize = priceHotImage:getContentSize()
                    local maxWidth = 120
                    maxWidth =(contentSize.width + 20)>  maxWidth and maxWidth  or (contentSize.width + 10)
                    priceHotImage:setScaleX( maxWidth / priceHotImageSize.width)

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
        local totalNum = checkint(tempData.lifeLeftPurchasedNum)
        local todayNum = checkint(tempData.todayLeftPurchasedNum)
        local purchargeLabel = nil
        if todayNum >= totalNum then
            --限购次数显示
            purchargeLabel = pCell:getChildByName('NUMLABEL')

            if totalNum > 0 then
                local price = tostring(tempData.price)
                if isElexSdk() then
                    local sdkInstance = require("root.AppSDK").GetInstance()
                    if sdkInstance.loadedProducts[tostring(tempData.channelProductId)] then
                        price = sdkInstance.loadedProducts[tostring(tempData.channelProductId)].priceLocale
                    else
                        price = string.format( __('￥%s'),price )
                    end
                else
                    price = string.format( __('￥%s'),price )
                end
                display.reloadRichLabel(pCell.sellLabel, {
                        c = {
                            fontWithColor(18, {fontSize = 28, text = price , color = "#ffffff" })
                    }})
                if purchargeLabel then
                    purchargeLabel:setVisible(true)
                    purchargeLabel:setString(string.fmt(__("限购_num_次"), {_num_ = totalNum}))
                end
            else
                if totalNum == 0  then
                    display.reloadRichLabel(pCell.sellLabel, {
                        c = {
                            fontWithColor(14, {text = __('已售罄') })
                        }})
                    if purchargeLabel then
                        purchargeLabel:setVisible(true)
                        display.commonLabelParams(purchargeLabel , {text =__('已售罄') })
                    end
                end
            end
        else
            purchargeLabel = pCell:getChildByName('NUMLABEL')
            if todayNum > 0 then
                if isJapanSdk() then
                    purchargeLabel:setString('')
                end
                purchargeLabel:setString(__('已售罄'))
            end
            if todayNum > 0 then
                local price = tostring(tempData.price)
                if isElexSdk() then
                    local sdkInstance = require("root.AppSDK").GetInstance()
                    if sdkInstance.loadedProducts[tostring(tempData.channelProductId)] then
                        price = sdkInstance.loadedProducts[tostring(tempData.channelProductId)].priceLocale
                    else
                        price = string.format( __('￥%s'),price )
                    end
                end
                if isJapanSdk() then
                    price = string.format( __('￥%s'),price )
                end

                if purchargeLabel then
                    purchargeLabel:setVisible(true)
                    purchargeLabel:setString(string.fmt(__("今日可购_num_次"), {_num_ = todayNum}))
                end
                display.reloadRichLabel(pCell.sellLabel, {
                        c = {
                            fontWithColor(18, {fontSize = 28, text = price , color = "#ffffff" })
                    }})
            else
                if purchargeLabel then
                    purchargeLabel:setVisible(true)
                    purchargeLabel:setString(__('已售罄'))
                end
                display.reloadRichLabel(pCell.sellLabel, {
                        c = {
                            fontWithColor(14, {text = __('已售罄') })
                    }})

            end
        end

        if tempData.shelfLeftSeconds then
            pCell.refreshLabel:setVisible(true)
            pCell.refreshTimeLabel:setVisible(true)
            -- tempData.shelfLeftSeconds = 100
            display.commonLabelParams(pCell.refreshTimeLabel, {text = formatTime(tempData.shelfLeftSeconds)})
            local contentSize = display.getLabelContentSize(pCell.refreshTimeLabel)
            if contentSize.width > 60   then
                pCell.refreshTimeLabel:setPosition(sizee.width  * 0.75, sizee.height - 40 )
            else
                pCell.refreshTimeLabel:setPosition(sizee.width  * 0.80, sizee.height - 40)
            end
        else
            pCell.refreshLabel:setVisible(false)
            pCell.refreshTimeLabel:setVisible(false)
        end

        display.commonLabelParams(purchargeLabel ,{reqW = 170})
  		-- display.reloadRichLabel(pCell.diamondLabel, { c = {fontWithColor('14', {text = goodsName , color = "934714"}) } })
 		display.reloadRichLabel(pCell.diamondLabel, { c = {fontWithColor('14', {text = tempData.name , color = "934714"})} })

        pCell:enableOutline(pCell.sellLabel)
        CommonUtils.SetNodeScale(pCell.diamondLabel , {width = 180 })
	end,__G__TRACKBACK__)

    return pCell

end

function ChestShopViewMediator:CellButtonAction(sender)
    local tag = sender:getTag()
    if self.goodBuyState[tostring(tag)] then
        uiMgr:ShowInformationTips(__('时间已结束, 不可购买'))
        return
    end
	local data = self.shopData[tag]
	self.clickTag = tag
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
            self:ShowChestDetailMess()
        else
            uiMgr:ShowInformationTips(__('库存不足'))
        end
    end
    if data.shelfLeftSeconds  then
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
    else
        callfuncTwo()
    end

end

function ChestShopViewMediator:SureBuyCallBack( )
	self:SendSignal(COMMANDS.COMMANDS_All_Shop_GetPayOrder,{productId = self.shopData[self.clickTag].productId,name = 'ChestShopView'})
end

function ChestShopViewMediator:ShowChestDetailMess()
	-- dump(self.shopData[self.clickTag])
	local tempData = self.shopData[self.clickTag]
	tempData.callback = handler(self, self.SureBuyCallBack)
	local ChooseBattleHeroView  = require( 'Game.views.ShowRewardsLayer' ).new(tempData)
	ChooseBattleHeroView:setPosition(display.center)
	uiMgr:GetCurrentScene():AddDialog(ChooseBattleHeroView)
end


function ChestShopViewMediator:PurchaseBtnCallback( sender )
	local tag = sender:getTag()
	local data = self.shopData[tag]
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
	end
 	if checkint(money) >= checkint(data.price) then
 		-- self:SendSignal(COMMANDS.COMMANDS_All_Shop_Buy,{productId = data.productId,num = 1,name = 'ChestShopView'})
	else
		uiMgr:ShowInformationTips(string.fmt(__('_des_不足'),{_des_ = des}))
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

function ChestShopViewMediator:OnRegist(  )
	local ShopCommand = require( 'Game.command.ShopCommand')

end

function ChestShopViewMediator:OnUnRegist(  )
    --称出命令

    if self.scheduler then
		scheduler.unscheduleGlobal(self.scheduler)
		self.scheduler = nil
	end
end

return ChestShopViewMediator

local Mediator = mvc.Mediator
---@class DiamondShopViewMediator:Mediator
local DiamondShopViewMediator = class("DiamondShopViewMediator", Mediator)


local NAME = "DiamondShopViewMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
---@type DiamondShopCell
local DiamondShopCell = require('Game.views.DiamondLimitShopCell')

local IsForeign = true -- 是否是海外

local function FilterDiamondShopDatas(datas)
    local startPoc = 0
    if datas and #datas > 0 then
        for i,val in pairs(datas) do
            if val.sequence then
                --如果存在此字段时插入指定位置
                val.startIndex = checkint(val.sequence)
                startPoc = startPoc + 1
            elseif val.ismember then
                --是月卡的情况
                val.startIndex = 100 + i
                startPoc = startPoc + 1
            else
                val.startIndex = 200 + i
            end
        end
        sortByMember(datas,"startIndex", true)
    end
    return startPoc
end

function DiamondShopViewMediator:ctor(params, viewComponent )
	self.super:ctor(NAME,viewComponent)
	self.str = ''
	self.clickShopType = nil
	self.showTopUiType = 5
	self.isAnyFirst = true
    self.curData = nil
	self.shopData = {}
	if params then
		if params.type then
			self.showTopUiType = params.type
		end
		if params.data then
			self.shopData = params.data
		end


        self.startPoc = FilterDiamondShopDatas(self.shopData)
		-- self.cardNum = 0 -- 月卡的选项
		-- for k , v in pairs(self.shopData) do
			-- if v.ismember then
				-- self.cardNum  = self.cardNum +1
			-- end
		-- end
	end
end
function DiamondShopViewMediator:JudageIsAnyFirst()
	for i =1 , #self.shopData do
		if checkint(self.shopData[i].isFirst) > 1   then
			self.isAnyFirst = false
		end
	end
end
function DiamondShopViewMediator:InterestSignals()
	local signals = {
		SIGNALNAMES.Restaurant_Shop_Home_Callback,
		SIGNALNAMES.Restaurant_Shop_Buy_Callback,
		SIGNALNAMES.Restaurant_Shop_Refresh_Callback,
		SIGNALNAMES.Restaurant_Shop_GetPayOrder_Callback,
        EVENT_PAY_MONEY_SUCCESS_UI,
        --POST.ACTIVITY_DRAW_FIRSTPAY.sglName
        "APP_STORE_PRODUCTS",
	}

	return signals
end

function DiamondShopViewMediator:ProcessSignal(signal )
	local name = signal:GetName()
    local body = signal:GetBody()
    if name == SIGNALNAMES.Restaurant_Shop_GetPayOrder_Callback then
        if signal:GetBody().requestData.name ~= 'DiamondShopView' then return end
        if body.orderNo then
            if device.platform == 'android' or device.platform == 'ios' then
                local AppSDK = require('root.AppSDK')
                AppSDK.GetInstance():InvokePay({amount = self.curData.price, property = body.orderNo, goodsId = tostring(self.curData.channelProductId),
                    goodsName = __('幻晶石'), quantifier = __('个'),price = 0.1, count = 1})
            end
        end
    elseif name == EVENT_PAY_MONEY_SUCCESS_UI then
        self:GetViewComponent():runAction(cc.Sequence:create(cc.DelayTime:create(0.2) , cc.CallFunc:create(function ()
            local httpManager = AppFacade.GetInstance():GetManager("HttpManager")
            httpManager:Post("mall/home",SIGNALNAMES.Restaurant_Shop_Home_Callback)
        end)))
    elseif name == SIGNALNAMES.Restaurant_Shop_Home_Callback then
        local diamondData = body.diamond
        local memberData = body.member
        self.shopData ={}
        for k , v in pairs(body.member) do
            v.ismember = true
            table.insert(self.shopData,#self.shopData+1 , v )
        end
        for k , v in pairs(body.diamond) do
            table.insert(self.shopData,#self.shopData+1 , v )
        end
        self.startPoc = FilterDiamondShopDatas(self.shopData)
        local gridView = self.viewData.gridView
        gridView:setDataSourceAdapterScriptHandler(handler(self,self.OnDataSourceAction))
        gridView:setCountOfCell(table.nums(self.shopData))
        gridView:reloadData()

        local shareUserDefault = cc.UserDefault:getInstance()
        shareUserDefault:setIntegerForKey("DIAMOND_KEY_ID", os.time())
        shareUserDefault:flush()

    --elseif name == POST.ACTIVITY_DRAW_FIRSTPAY.sglName then
    --	if gameMgr:GetUserInfo().firstPay == 1 then
    --		gameMgr:GetUserInfo().firstPay = 3
    --		uiMgr:AddDialog('common.RewardPopup', {rewards = body.rewards, msg = __('恭喜获得首充奖励')})
    --	end
    elseif name == "APP_STORE_PRODUCTS" then
        local gridView = self.viewData.gridView
        gridView:setCountOfCell(table.nums(self.shopData))
        gridView:reloadData()
    end
end


function DiamondShopViewMediator:Initial( key )
	self.super.Initial(self,key)

	local viewComponent  = require( 'Game.views.CommonShopView' ).new({ type = self.showTopUiType ,  isForeign  = true  ,isAnyDouble  = false})
	self:SetViewComponent(viewComponent)
	self.viewData = nil
	self.viewData = viewComponent.viewData
	self:JudageIsAnyFirst()
	local gridView = self.viewData.gridView
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
end

function DiamondShopViewMediator:UpDataUI()
	self:InitTopUI()
    self.viewData.gridView:setCountOfCell(table.nums(self.shopData))
    self.viewData.gridView:reloadData()
end




function DiamondShopViewMediator:OnDataSourceAction(p_convertview,idx)
    local pCell = p_convertview
    local pButton = nil
    local index = idx + 1
    --local sizee = cc.size(2 , 200)
    local tempData = self.shopData[index]
   	if pCell == nil then
		---@type DiamondShopCell
        pCell = DiamondShopCell.new(sizee)
        pCell.toggleView:setOnClickScriptHandler(handler(self,self.CellButtonAction))
		pCell.diamondLabel:setOnTextRichClickScriptHandler(handler(self,self.CellButtonAction))

    end
	xTry(function()
		pCell.toggleView:setTag(index)
		pCell.diamondLabel:setTag(index)
		pCell:RefreshShopCell(self.shopData[index] ,false,false, index, self.startPoc)
		--pCell.diamondLabel:setVisible(false)

	end,__G__TRACKBACK__)
    return pCell

end


function DiamondShopViewMediator:CellButtonAction(sender)
	local tag = sender:getTag()
	local data = self.shopData[tag]
	if data.ismember then
		--- 月卡在此处调用
		local MemberShopViewMediator = require( 'Game.mediator.MemberShopViewMediator' )
		local mediator = MemberShopViewMediator.new({data = data})
		self:GetFacade():RegistMediator(mediator)
	else
		self.curData = self.shopData[tag]
        local canNext = 1
        if self.curData.sequence then
            local totalNum = checkint(self.curData.lifeLeftPurchasedNum)
            local todayNum = checkint(self.curData.todayLeftPurchasedNum)
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
        end
        if canNext == 0 then return end
		if checktable(GAME_MODULE_OPEN).DUAL_DIAMOND then
			self:ShowJapanCustomLayer(tag)
		else
			self:SendSignal(COMMANDS.COMMANDS_All_Shop_GetPayOrder,{productId = self.shopData[tag].productId , name = 'DiamondShopView'})
		end
	end
end

function DiamondShopViewMediator:ShowJapanCustomLayer( tag )
	local scene = uiMgr:GetCurrentScene()
	local DiamondPurchasePopup  = require('Game.views.DiamondPurchasePopup').new({tag = 5001, mediatorName = "DiamondShopViewMediator", data = self.curData, cb = function ()
		self:SendSignal(COMMANDS.COMMANDS_All_Shop_GetPayOrder,{productId = self.shopData[tag].productId , name = 'DiamondShopView'})
	end})
	display.commonUIParams(DiamondPurchasePopup, {ap = cc.p(0.5, 0.5), po = cc.p(display.width * 0.5, display.height * 0.5)})
	DiamondPurchasePopup:setTag(5001)
	scene:AddDialog(DiamondPurchasePopup)
end

function DiamondShopViewMediator:PurchaseBtnCallback( sender )
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
 		self:SendSignal(COMMANDS.COMMANDS_Restaurant_Shop_Buy,{productId = data.productId})

		-- self:GetFacade():DispatchObservers(SureBuyItem_Callback,data.productId)
	else
		uiMgr:ShowInformationTips(string.fmt(__('_des_不足'),{_des_ = des}))
	end
end

function DiamondShopViewMediator:OnRegist(  )
    local ShopCommand = require( 'Game.command.ShopCommand')
	--regPost(POST.ACTIVITY_DRAW_FIRSTPAY)
	-- local ShopCommand = require( 'Game.command.ShopCommand')
	-- self:GetFacade():RegistSignal(COMMANDS.COMMANDS_Restaurant_Shop_Home, ShopCommand)
	-- self:GetFacade():RegistSignal(COMMANDS.COMMANDS_Restaurant_Shop_Buy, ShopCommand)
	-- self:GetFacade():RegistSignal(COMMANDS.COMMANDS_Restaurant_Shop_Refresh, ShopCommand)

end

function DiamondShopViewMediator:OnUnRegist(  )
    --unregPost(POST.ACTIVITY_DRAW_FIRSTPAY)
	--称出命令
	-- local scene = uiMgr:GetCurrentScene()
	-- scene:RemoveDialog(self.viewComponent)

	-- self:GetFacade():UnRegsitSignal(COMMANDS.COMMANDS_Restaurant_Shop_Home)
	-- self:GetFacade():UnRegsitSignal(COMMANDS.COMMANDS_Restaurant_Shop_Buy)
	-- self:GetFacade():UnRegsitSignal(COMMANDS.COMMANDS_Restaurant_Shop_Refresh)

end

return DiamondShopViewMediator

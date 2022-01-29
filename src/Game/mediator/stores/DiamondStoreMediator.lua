--[[
 * author : kaishiqi
 * descpt : 新游戏商店 - 钻石商店中介者
]]
---@type DiamondStoreView
local DiamondStoreView     = require('Game.views.stores.DiamondStoreView')

---@type DiamondStoreCellView
local DiamondStoreCellView     = require('Game.views.stores.DiamondStoreCellView')
local uiMgr = app.uiMgr

---@class DiamondStoreMediator:Mediator
local DiamondStoreMediator = class('DiamondStoreMediator', mvc.Mediator)
function DiamondStoreMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'DiamondStoreMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end


-------------------------------------------------
-- inheritance method

function DiamondStoreMediator:Initial(key)
    self.super.Initial(self, key)

    -- init vars
    self.ownerNode_      = self.ctorArgs_.ownerNode
    self.isControllable_ = true

    -- create view
    if self.ownerNode_ then

        self.storesView_ = DiamondStoreView.new(self.ownerNode_:getContentSize())
        self:SetViewComponent(self.storesView_)
        self.ownerNode_:addChild(self.storesView_)
    end
end


function DiamondStoreMediator:CleanupView()
    if self.storesView_  and (not tolua.isnull(self.storesView_)) then
        self.storesView_:runAction(cc.RemoveSelf:create())
        self.storesView_ = nil
    end
end


function DiamondStoreMediator:OnRegist()
    regPost(POST.GAME_STORE_DIAMOND)
end


function DiamondStoreMediator:OnUnRegist()
    unregPost(POST.GAME_STORE_DIAMOND)
end


function DiamondStoreMediator:InterestSignals()
    return {
        SHOP_BUY_DIAMOND_EVENT ,
        SHOP_BUY_ACTICITY_DIAMOND_EVENT , 
        EVENT_PAY_MONEY_SUCCESS_UI ,
        SIGNALNAMES.Restaurant_Shop_GetPayOrder_Callback,
        POST.GAME_STORE_DIAMOND.sglName,
        EVENT_APP_STORE_PRODUCTS,
    }
end
function DiamondStoreMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()
    if name == SHOP_BUY_DIAMOND_EVENT then
        local tag = checkint(data.tag)
        local storeData = self.diamondData or {}

        if isJapanSdk() then
            local gameMgr = app.gameMgr
            local uiMgr = app.uiMgr
            local curData = storeData[tag]
			if 0 == checkint(gameMgr:GetUserInfo().jpAge) then
				local JapanAgeConfirmMediator = require( 'Game.mediator.JapanAgeConfirmMediator' )
				local mediator = JapanAgeConfirmMediator.new({cb = function (  )
					self:ShowJapanCustomLayer(curData)
				end})
				self:GetFacade():RegistMediator(mediator)
			else
				if tonumber(curData.price) < checkint(gameMgr:GetUserInfo().jpAgePaymentLimitLeft) or -1 == checkint(gameMgr:GetUserInfo().jpAgePaymentLimitLeft) then
					self:ShowJapanCustomLayer(curData)
				else
					uiMgr:ShowInformationTips(__('本月购买幻晶石数量已达上限'))
				end
			end
		else
            self:SendSignal(COMMANDS.COMMANDS_All_Shop_GetPayOrder,{productId = storeData[tag].productId , name = "DiamondShopView" })
		end
    elseif name == EVENT_PAY_MONEY_SUCCESS_UI then
        self:GetViewComponent():runAction(cc.Sequence:create(cc.DelayTime:create(0.2) , cc.CallFunc:create(function ()
            self:SendSignal(POST.GAME_STORE_DIAMOND.cmdName , {})
        end)))
    elseif name ==  SIGNALNAMES.Restaurant_Shop_GetPayOrder_Callback then
        if signal:GetBody().requestData.name ~= 'DiamondShopView' then return end
        local requestData = data.requestData
        local productId = requestData.productId
        local curData =  self:GetDiamondOrderInfo(productId)
        if data.orderNo then
            if device.platform == 'android' or device.platform == 'ios' then
                local AppSDK = require('root.AppSDK')
                AppSDK.GetInstance():InvokePay({amount = curData.price, property = data.orderNo, goodsId = tostring(curData.channelProductId),
                                                goodsName = __('幻晶石'), quantifier = __('个'),price = 0.1, count = 1})
            end
        end
    elseif name == POST.GAME_STORE_DIAMOND.sglName then
        self.storeData.storeData = data.diamond
        self.storeData.dataTimestamp  = os.time()
        self:setStoreData(self.storeData)
    elseif name == SHOP_BUY_ACTICITY_DIAMOND_EVENT then
        local tag = checkint(data.tag)
        self:BuyActicityDiamond(tag)
    elseif name == EVENT_APP_STORE_PRODUCTS then
        if self.storesView_ and  (not tolua.isnull(self.storesView_)) and  self.storesView_.viewData_ then
            local viewData_ = self.storesView_.viewData_
            if self.activityData and  table.nums(self.activityData) > 0  then
                self:InsertActivity()
            end
            viewData_.gridView:setDataSourceAdapterScriptHandler(handler(self, self.OnDataSource))
            viewData_.gridView:setCountOfCell(table.nums(self.diamondData))
            viewData_.gridView:reloadData()
        end

    end
end
function DiamondStoreMediator:GetDiamondOrderInfo(productId)
    local productId = checkint(productId)
    for index , diamondData in pairs(self.storeData.storeData) do
        if checkint(diamondData.productId)  == productId  then
            return diamondData
        end
    end
end

function DiamondStoreMediator:ShowJapanCustomLayer( curData )
    local canNext = 1
    local gameMgr = app.gameMgr
    local uiMgr = app.uiMgr
    if curData.sequence then
        local totalNum = checkint(curData.lifeLeftPurchasedNum)
        local todayNum = checkint(curData.todayLeftPurchasedNum)
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
		local scene = uiMgr:GetCurrentScene()
		local DiamondPurchasePopup  = require('Game.views.DiamondPurchasePopup').new({tag = 5001, mediatorName = "DiamondStoreMediator", data = curData, cb = function ()
			self:SendSignal(COMMANDS.COMMANDS_All_Shop_GetPayOrder,{productId = curData.productId , name = "DiamondShopView" })
		end})
		display.commonUIParams(DiamondPurchasePopup, {ap = cc.p(0.5, 0.5), po = cc.p(display.width * 0.5, display.height * 0.5)})
		DiamondPurchasePopup:setTag(5001)
		scene:AddDialog(DiamondPurchasePopup)
	else
		self:SendSignal(COMMANDS.COMMANDS_All_Shop_GetPayOrder,{productId = curData.productId , name = "DiamondShopView" })
	end
end

-------------------------------------------------
-- get / set

function DiamondStoreMediator:getStoresView()
    return self.storesView_
end
function DiamondStoreMediator:getStoresViewData()
    return self:getStoresView() and self:getStoresView():getViewData() or {}
end


-------------------------------------------------
-- public

function DiamondStoreMediator:close()
    self:GetFacade():UnRegsitMediator(self:GetMediatorName())
end


function DiamondStoreMediator:setStoreData(storeDatas)
    self.storeData = storeDatas
    self.diamondData = {}
    self.activityData = {}
    local viewData_ = self.storesView_.viewData_
    local activityData ={}
    local storeData = {}
    for index, diamondData in pairs(self.storeData.storeData) do
        if checkint(diamondData.productId) > 10000 then
            activityData[#activityData+1] = diamondData
        else
            storeData[#storeData+1] = diamondData
        end
    end
    -- 给钻石排序
    if table.nums(storeData) > 0  then
        table.sort(storeData , function(aDiamondData, bDiamondData)
            if checkint(aDiamondData.productId) >=  checkint(bDiamondData.productId) then
                return false
            end
            return true
        end)
        self.diamondData = storeData
    end
    -- 给活动钻石档位排序
    if table.nums(activityData) > 0  then
        table.sort(activityData , function(aDiamondData, bDiamondData)
            if checkint(aDiamondData.sequence) >=  checkint(bDiamondData.sequence) then
                return false
            end
            return true
        end)
        self.activityData = activityData
    end
    if table.nums(storeData) > 0  then
        local isHaveActivity = false
        if self.activityData and  table.nums(self.activityData) > 0  then
            isHaveActivity = true
        end
        if not  viewData_.gridView then
            self.storesView_:CreateGridView(isHaveActivity)
            self.storesView_:CreateTopView(isHaveActivity)
            if isHaveActivity then
                self:UpdateTopView()
            end
        end
    end
    if self.activityData and  table.nums(self.activityData) > 0  then
        self:InsertActivity()
    end
    viewData_.gridView:setDataSourceAdapterScriptHandler(handler(self, self.OnDataSource))
    viewData_.gridView:setCountOfCell(table.nums(self.diamondData))
    viewData_.gridView:reloadData()
    if isElexSdk() then
        local t = {}
        for name,val in pairs(self.storeData.storeData) do
            if val.channelProductId then
                table.insert(t, val.channelProductId)
            end
        end
        require('root.AppSDK').GetInstance():QueryProducts(t)
    end
end
function DiamondStoreMediator:InsertActivity()
    if  self.storesView_ and (not tolua.isnull(self.storesView_)) and  self.storesView_.viewData_ then
        local viewData_ = self.storesView_.viewData_
        viewData_.activityList:removeAllNodes()
        local activityData = self.activityData
        for index =1 , #activityData do
            local  cell = require('Game.views.stores.DiamondStoreActivityCellView').new()
            cell:UpdateSellLeftTimes(activityData[index] , index )
            viewData_.activityList:insertNodeAtLast(cell)
        end
        local num = #activityData <= 3 and #activityData or 3
        viewData_.activityList:setContentSize(cc.size(280 * num,128) )
        viewData_.activityList:reloadData()
    end
end
function DiamondStoreMediator:UpdateTopView()
    local endTime =  checkint(self.activityData[1].leftSeconds) +  checkint(self.storeData.dataTimestamp)
    self.storesView_:UpdateTopView(endTime)
end
function DiamondStoreMediator:BuyActicityDiamond(tag)
    local activityData = self.activityData
    local data = activityData[tag]
    local callfunc =  function ()
        local tempdata  = clone(data)
        if isJapanSdk() then
            local gameMgr = app.gameMgr
            local uiMgr = app.uiMgr
			if 0 == checkint(gameMgr:GetUserInfo().jpAge) then
				local JapanAgeConfirmMediator = require( 'Game.mediator.JapanAgeConfirmMediator' )
				local mediator = JapanAgeConfirmMediator.new({cb = function (  )
					self:ShowJapanCustomLayer(tempdata)
				end})
				self:GetFacade():RegistMediator(mediator)
			else
				if tonumber(tempdata.price) < checkint(gameMgr:GetUserInfo().jpAgePaymentLimitLeft) or -1 == checkint(gameMgr:GetUserInfo().jpAgePaymentLimitLeft) then
					self:ShowJapanCustomLayer(tempdata)
				else
					uiMgr:ShowInformationTips(__('本月购买幻晶石数量已达上限'))
				end
			end
		else
            self:SendSignal(COMMANDS.COMMANDS_All_Shop_GetPayOrder,{productId = tempdata.productId , name = "DiamondShopView" })
        end
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
    if checkint(data.leftSeconds)  ~= -1   then
        -- 限时上架剩余秒数DiamondStoreCellView
        local leftSeconds =  self.storeData.dataTimestamp + data.leftSeconds - os.time()
        if checkint(leftSeconds)  > 0  then
            callfuncTwo()
        else
            uiMgr:ShowInformationTips(__('道具剩余时间已结束'))
        end
    else
        callfuncTwo()
    end
end

function DiamondStoreMediator:OnDataSource(cell , idx )
    local index = idx +1
    local data = self.diamondData[index]
    if  not  cell then
        cell =DiamondStoreCellView.new()
    end
    xTry(function()
        cell:UpdateCell(data,index)
    end, __G__TRACKBACK__)
    return cell
end
return DiamondStoreMediator

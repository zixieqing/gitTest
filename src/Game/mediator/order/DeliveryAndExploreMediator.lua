---
--- Created by xingweihao.
--- DateTime: 27/09/2017 2:35 PM
--- 交易和探索的修改

local Mediator = mvc.Mediator
---@class DeliveryAndExploreMediator :Mediator
local DeliveryAndExploreMediator = class("DeliveryAndExploreMediator", Mediator)
local NAME = "DeliveryAndExploreMediator"
---@type UIManager
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
---@type GameManager
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
---@type TakeawayManager
local takeawayInstance = AppFacade.GetInstance():GetManager('TakeawayManager')
local RED_TAG = 1115
local MODULE = {
    TAKEAWAY = 1 ,  -- 订单模块
    EXPLORE = 2 ,   -- 外卖车模块
}
local DINGING_CAR_STATUS = {
    LOCK_CAR = 1,
    UNLOCK_CAR = 2,
    DELIVERY_CAR = 3,
    REWARD_CAR = 4,
    EXPLORE_DOING = 5, -- 正在探索中
    EXPLORE_DONE = 6, -- 探索已经完成
}
function DeliveryAndExploreMediator:ctor( params, viewComponent )
    self.super:ctor(NAME,viewComponent)
    self.isAction = false
    self.freshSuccess = takeawayInstance.freshSuccess
    self.datas = {}
    self.sortData = {}
end

function DeliveryAndExploreMediator:InterestSignals()
    local signals = {
        POST.BUSINESS_ORDER.sglName ,
        POST.DELIVERY_ONE_KEY_DRAW.sglName ,
        SIGNALNAMES.SIGNALNAMES_TAKEAWAY_UNLOCK_CAR,
        FRESH_TAKEAWAY_POINTS ,
        FRESH_TAKEAWAY_ORDER_POINTS ,
        'DELIVERY_ORDER_FINISHED',
        "REFRESH_NOT_CLOSE_GOODS_EVENT" ,
        "UPGRAGE_AND_UNLOCK_CHECK_RED_AND_LEVEL"
    }
    return signals
end
function DeliveryAndExploreMediator:Initial( key )
    self.super.Initial(self,key)
    self:InitUI()
end

function DeliveryAndExploreMediator:InitUI()

    if self.freshSuccess then
        local  viewComponent =  require("Game.views.order.DeliveryAndExploreView").new()
        --viewComponent:setPosition(display.center)
        self:SetViewComponent(viewComponent)

        ---@type DeliveryAndExploreView
        self.viewComponent = viewComponent

        self:SetViewComponent(self.viewComponent)
        viewComponent.viewData.oneKeyBtn:setOnClickScriptHandler(handler(self, self.OnOneKeyBtnAction))
        ---@type OrderMediator
        local mediator = AppFacade.GetInstance():RetrieveMediator("OrderMediator")
        ---@type OrderView
        local orderView = mediator:GetViewComponent()
        orderView.viewData.bgLayer:addChild(viewComponent)

    end
end

function DeliveryAndExploreMediator:UpdateOneKeyBtnState(  )
    local oneKeyBtn = self.viewComponent.viewData.oneKeyBtn
    oneKeyBtn:setEnabled(true)
    if not app.badgeMgr:CheckOrderTimeAndRed() then
        oneKeyBtn:setNormalImage(_res('ui/common/common_btn_big_orange_disabled_2.png'))
        oneKeyBtn:setSelectedImage(_res('ui/common/common_btn_big_orange_disabled_2.png'))
    else
        oneKeyBtn:setNormalImage(_res('ui/common/common_btn_orange_big.png'))
        oneKeyBtn:setSelectedImage(_res('ui/common/common_btn_orange_big.png'))
    end
end

function DeliveryAndExploreMediator:OnOneKeyBtnAction( sender )
    PlayAudioByClickNormal()
    if not app.badgeMgr:CheckOrderTimeAndRed() then
        if 0 >= table.nums(self.sortData) then
            uiMgr:ShowInformationTips(__('再点也没有正在配送订单呢'))
        else
            uiMgr:ShowInformationTips(__('努力配送中'))
        end
    else
        self:SendSignal(POST.DELIVERY_ONE_KEY_DRAW.cmdName)
    end
end

function DeliveryAndExploreMediator:EnterLayer()
    self:SendSignal(POST.BUSINESS_ORDER.cmdName)
end
function DeliveryAndExploreMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()
    if name == FRESH_TAKEAWAY_POINTS or name == FRESH_TAKEAWAY_ORDER_POINTS then
        if self.freshSuccess then
            self.viewComponent.viewData.listView:removeAllNodes()
            self:EnterLayer()
        else
            self.freshSuccess = takeawayInstance.freshSuccess
            if self.viewComponent then
                self.viewComponent:removeFromParent()
            end
            self:InitUI()
            self:EnterLayer()
        end
    elseif name == POST.BUSINESS_ORDER.sglName  then
        for k , v in pairs(data.exploreOrder) do  -- 给探索添加定时器
            -- 添加探索的对事情
            app.badgeMgr:AddSetExploreTimeInfoRed(v.areaFixedPointId, v.needTime)
        end
        for k , v in pairs(data.takeawayOrder) do -- 给不同模块添加标志
            v.moulde = MODULE.TAKEAWAY
            -- 把已经配送的外卖车状态改为  加入到已经使用的列表中
        end
        for k , v in pairs(data.exploreOrder) do
            v.moulde = MODULE.EXPLORE
        end
        self.datas = data
        self:SortDeliveryAndExploreData()
        self:UpdateCellView()
        self:CheckBtnRedDot()
        self:UpdateOneKeyBtnState()
    elseif name == POST.DELIVERY_ONE_KEY_DRAW.sglName  then -- 一键领取外卖奖励
        local rewardData = data.rewards
		uiMgr:AddDialog('common.RewardPopup', {rewards = checktable(rewardData), mainExp = checkint(data.mainExp),popularity = checkint(data.popularity), highestPopularity = checkint(data.highestPopularity)})
        takeawayInstance:DeliveryAllArrived(data.diningCars)
        for _,v in pairs(data.diningCars) do
            for k,taorder in pairs(self.datas.takeawayOrder) do
                if checkint(taorder.diningCarId) == checkint(v) then
                    table.remove( self.datas.takeawayOrder, k )
                    break
                end
            end
        end
        self:SortDeliveryAndExploreData()
        self:UpdateCellView()
        self:CheckBtnRedDot()
        self:UpdateOneKeyBtnState()

		takeawayInstance:DirectRfreshOrder() -- 刷新外卖订单
		app.badgeMgr:CheckOrderRed()
    elseif name == SIGNALNAMES.SIGNALNAMES_TAKEAWAY_UNLOCK_CAR then
        local diningCarData = takeawayInstance:GetDatas().diningCar or {}
        if diningCarData then
            local diningCarId = checkint(signal:GetBody().requestData.diningCarId)
            local data =  {
                diningCarId = diningCarId,
                level = 1,
                status = 1
            }
            table.insert(diningCarData,#diningCarData+1 ,data)
            self:ReduceGoodsCache(diningCarId) --更新数量
            local index = self:GetCellIndex( "CAR_".. diningCarId)
            if index then
                -- 删除当前的cell 项
                self.viewComponent.viewData.listView:removeNodeAtIndex(index - 1)
                local exploreNum =  table.nums( self.datas.exploreOrder)
                local takeawayNum =  table.nums( self.datas.takeawayOrder)
                local countNum = exploreNum + takeawayNum

                local type = DINGING_CAR_STATUS.UNLOCK_CAR
                local data= {
                    Name = "CAR_".. diningCarId,
                    callback = handler(self, self.DeliveryDiningCarUnLockAndLookAndRewardCallBack)
                }
                local  DiningCarCellView = require("Game.views.DiningCarCellView")
                local cell = DiningCarCellView.new( {type = type })
                cell:RefreshCellUI(data)
                self.viewComponent.viewData.listView:insertNode(cell ,countNum )
                self.viewComponent.viewData.listView:reloadData()
            end
            self:CheckBtnRedDot()
        end
    elseif name == "DELIVERY_ORDER_FINISHED" then
        self:UpdateOneKeyBtnState()
    elseif name == "REFRESH_NOT_CLOSE_GOODS_EVENT" then
        self:CheckBtnRedDot()
    elseif name == "UPGRAGE_AND_UNLOCK_CHECK_RED_AND_LEVEL" then
         self:CheckBtnRedDot()
    end
end

-- 获取到cell 的位置
function DeliveryAndExploreMediator:GetCellIndex(name)
    local nodes = self.viewComponent.viewData.listView:getNodes()
    for k ,v in pairs(nodes) do
        if v:getName() == name then -- 证明是相同的node
            return k
        end
    end
    return nil
end
-- 排序发车和探索的数据
function DeliveryAndExploreMediator:SortDeliveryAndExploreData()
    -- 探索的数据
    self.sortData = {}
    for k ,v in pairs(self.datas.exploreOrder or {}) do
        -- 满足外卖领取的致前
        if checkint(v.needTime) == 0 then
            table.insert(self.sortData, 1, v)
        else
            table.insert(self.sortData, #self.sortData+1, v)
        end

    end
    -- 已经发车的外卖车
    for k , v in pairs( self.datas.takeawayOrder or {}) do
        -- 满足订单领取的致前
        local orderInfo  = takeawayInstance:GetOrderInfoByOrderInfo({ orderId = v.orderId , orderType = v.orderType})
        if orderInfo then
            v.leftSeconds = orderInfo.leftSeconds
            v.status = orderInfo.status
            if (checkint(v.leftSeconds) == 0  and checkint(v.status) > 1)  or checkint(v.status) == 4 then
                table.insert(self.sortData, 1, v)
            else
                table.insert(self.sortData, #self.sortData+1, v)
            end
        end
    end

end
-- 刷新cell的信息
function DeliveryAndExploreMediator:UpdateCellView()
    local DiningCarCellView = require("Game.views.DiningCarCellView")
    -- 首先显示的应该是正在使用的外卖车和探索的队伍
    local index = 0
    for k , v in pairs(self.sortData) do
        if v.moulde == MODULE.TAKEAWAY then
            local data = {
                Name = "CAR_" .. v.diningCarId ,
                callback = handler(self, self.DeliveryDiningCarUnLockAndLookAndRewardCallBack) ,
                mouldData = v
            }
            local type = DINGING_CAR_STATUS.REWARD_CAR
            if checkint(v.status)  == 4 or (checkint(v.leftSeconds) == 0  and  checkint(v.status)  >1)  then
                type = DINGING_CAR_STATUS.REWARD_CAR
            else
                type = DINGING_CAR_STATUS.DELIVERY_CAR
            end
            index = index +1
            local cell = DiningCarCellView.new( {type = type ,index = index})
            cell:RefreshCellUI(data)
            self.viewComponent.viewData.listView:insertNodeAtLast(cell)
        elseif v.moulde == MODULE.EXPLORE then
            local data = {
                Name = "EXPLORE_" .. v.areaFixedPointId ,
                callback = handler(self, self.GoToExplorePoint) ,
                mouldData = v
            }
            local type = DINGING_CAR_STATUS.EXPLORE_DOING
            if checkint(v.needTime) == 0 then  -- 需要时间为零的时候 证明订单完成
                type = DINGING_CAR_STATUS.EXPLORE_DONE
            end
            index = index + 1
            local cell = DiningCarCellView.new( {type = type,index =index })
            cell:RefreshCellUI(data)
            self.viewComponent.viewData.listView:insertNodeAtLast(cell)
        end
    end
    -- 接下来显示的是空闲的外卖车
    local diningCarNotUse =  self:GetDinigCarUnLockAndNotUse()
    for k , v in pairs(diningCarNotUse) do
        local data = {
            Name = "CAR_" .. v.diningCarId ,
            callback = handler(self, self.DeliveryDiningCarUnLockAndLookAndRewardCallBack) ,
        }
        local type = DINGING_CAR_STATUS.UNLOCK_CAR
        index = index + 1
        local cell = DiningCarCellView.new( {type = type ,index = index})
        cell:RefreshCellUI(data)
        self.viewComponent.viewData.listView:insertNodeAtLast(cell)
    end
    -- 最后显示的是还没解锁的外卖车
    local diningCarLockData = self:GetLockDiningCar()
    for k , v in pairs(diningCarLockData) do
        local data = {
            Name = "CAR_" .. v.diningCarId ,
            callback = handler(self, self.DeliveryDiningCarUnLockAndLookAndRewardCallBack) ,
        }
        local type = DINGING_CAR_STATUS.LOCK_CAR
        index = index +1
        local cell = DiningCarCellView.new( {type = type ,index = index})
        cell:RefreshCellUI(data)
        self.viewComponent.viewData.listView:insertNodeAtLast(cell)
    end
    -- 刷新显示
    self.viewComponent.viewData.listView:reloadData()
end

-- 获取外卖车已经解锁 并且尚未使用的外卖车
function DeliveryAndExploreMediator:GetDinigCarUnLockAndNotUse()
    local diningCarNotUse = {}
    local diningCarData = takeawayInstance:GetDatas().diningCar or {} -- 获取到已经使用的外卖车数据
    local diningCarUse = self.datas.takeawayOrder or {}
    for k , v in pairs(diningCarData) do
        local isUse =  false
        for kk, vv in pairs(diningCarUse) do
            if checkint(v.diningCarId) == checkint(vv.diningCarId) then
                isUse = true
                break
            end

        end
        if not  isUse then
           table.insert(diningCarNotUse,#diningCarNotUse+1 , v)
        end
    end
    return diningCarNotUse
end

-- 获取到尚未解锁的外卖车
function DeliveryAndExploreMediator:GetLockDiningCar()
    local diningCarData = takeawayInstance:GetDatas().diningCar or {} -- 获取到已经使用的外卖车数据
    local diningCarNum = table.nums(diningCarData)
    local diningCarLockData = {}
    if diningCarNum == DINING_CAR_LIMITE_NUM then
        return {}
    elseif  diningCarNum <   DINING_CAR_LIMITE_NUM then
        for i =   1 , DINING_CAR_LIMITE_NUM do
            local isHave = false
            for k ,v in pairs(diningCarData) do
                if checkint(v.diningCarId) ==  i then
                    isHave = true
                end
            end
            if not isHave then
                local data = {diningCarId = i}
                table.insert(diningCarLockData, #diningCarLockData+1, data)
            end
        end
        return diningCarLockData
    end
end


--[[
    修正缓存的时候 不发送通知事件
]]
function DeliveryAndExploreMediator:ReduceGoodsCache(diningCarId)
    local carConfig = CommonUtils.GetConfigAllMess('diningCar','takeaway')
    local carId = checkint(diningCarId)
    if carConfig[tostring(carId)] then
        local types = carConfig[tostring(carId)].unlockType
        --更新升级所需的相关属性变化
        local data = {}
        for k,v in pairs(types) do
            if checkint(k) ~= UnlockTypes.AS_LEVEL and checkint(k) ~= UnlockTypes.PLAYER then
                if checkint(k) == UnlockTypes.GOLD then
                    data[#data+1] = {goodsId = GOLD_ID, num  = - checkint(v.targetNum)}
                elseif checkint(k) == UnlockTypes.DIAMOND then
                    data[#data+1] = {goodsId = DIAMOND_ID, num  = - checkint(v.targetNum)}
                elseif checkint(k) == UnlockTypes.GOODS then
                    data[#data+1] = {goodsId = checkint(v.targetId), num  = - checkint(v.targetNum)}
                end
            end
        end
        if table.nums(data) > 0  then -- 如果有道具扣除，事件刷新
            CommonUtils.DrawRewards(data , nil ,nil, false )
        end
    end
end


-- 外卖车的解锁  车查看   领取奖励
function DeliveryAndExploreMediator:DeliveryDiningCarUnLockAndLookAndRewardCallBack(sender)
    PlayAudioByClickNormal()
    local name = sender:getName()
    local x, y  = string.find(name, "%d+")
    if x and y then
        local diningCarId = checkint(string.sub(name,x,y))
        local diningCarData = takeawayInstance:GetDatas().diningCar or {}
        local isHave = false
        for k , v in pairs(diningCarData) do
            if checkint(v.diningCarId) == diningCarId then
                isHave = true
                break
            end
        end
        -- 如果升级界面存在首先删除升级界面
        local mediator = self:GetFacade():RetrieveMediator("TakeawayCarUpgradeMediator")
        if mediator then
            self:GetFacade():UnRegsitMediator("TakeawayCarUpgradeMediator")
        end
        if not isHave then -- 该外卖车尚未解锁
            local carConfig = CommonUtils.GetConfigAllMess('diningCar','takeaway')
            local carId = checkint(diningCarId)
            if carConfig[tostring(carId)] then
                local types = carConfig[tostring(carId)].unlockType or {}
                if types[tostring(UnlockTypes.AS_LEVEL)] then
                    if checkint(gameMgr:GetUserInfo().restaurantLevel) < checkint(types[tostring(UnlockTypes.AS_LEVEL)].targetNum) then
                        -- 餐厅等级需要特别提示 其他走通用的方法 等级不足的时候所要走的逻辑
                        local typeInfos = CommonUtils.GetConfigAllMess('unlockType')
                        uiMgr:ShowInformationTips(string.fmt(typeInfos[tostring(UnlockTypes.AS_LEVEL)],{_target_num_ = checkint(types[tostring(UnlockTypes.AS_LEVEL)].targetNum)}))
                        return
                    elseif   checkint(gameMgr:GetUserInfo().level) >=  checkint(types[tostring(UnlockTypes.AS_LEVEL)].targetNum) then
                        local isLock =  CommonUtils.CheckLockCondition(types)
                        if not isLock then
                            local CommonTip  = require( 'common.NewCommonTip' ).new({text = string.format(__('确定消耗%s金币，解锁第%s辆外卖车？'),tostring( types[tostring(UnlockTypes.GOLD)].targetNum) , tostring(diningCarId) ) ,
                                                                                     isOnlyOK = false, callback = function ()
                                    self:SendSignal(COMMANDS.COMMANDS_TAKEAWAY, {action = 'Takeaway/unlockDiningCar',diningCarId = carId})
                                end})
                            CommonTip:setPosition(display.center)
                            local scene = uiMgr:GetCurrentScene()
                            scene:AddDialog(CommonTip)
                        else
                            uiMgr:ShowInformationTips(__('解锁外卖车金币不足'))
                        end
                    end
                else
                    local isLock =  CommonUtils.CheckLockCondition(types)
                    if not isLock then
                        if arConfig[tostring(carId)].unlockType[tostring(UnlockTypes.GOLD)] then
                            local CommonTip  = require( 'common.NewCommonTip' ).new({text = string.format(__('确定消耗%s金币，解锁第%s辆外卖车？'),tostring( types[tostring(UnlockTypes.GOLD)].targetNum) , tostring(diningCarId) ) ,
                                                                                     isOnlyOK = false, callback = function ()
                                    self:SendSignal(COMMANDS.COMMANDS_TAKEAWAY, {action = 'Takeaway/unlockDiningCar',diningCarId = carId})
                                end})
                            CommonTip:setPosition(display.center)
                            local scene = uiMgr:GetCurrentScene()
                            scene:AddDialog(CommonTip)
                        else
                            self:SendSignal(COMMANDS.COMMANDS_TAKEAWAY, {action = 'Takeaway/unlockDiningCar',diningCarId = carId})
                        end

                    else
                        uiMgr:ShowInformationTips(__('解锁外卖车金币不足'))
                    end
                end
            end
        elseif  isHave  then  -- 该外卖车正在使用中
            for k ,v in pairs(diningCarData) do  -- 找到当前的外卖车

                if  checkint(v.diningCarId) == diningCarId then
                    for kk , vv in pairs(self.datas.takeawayOrder) do
                        if checkint(vv.diningCarId) ==  checkint(diningCarId) then
                            local orderInfo  = takeawayInstance:GetOrderInfoByOrderInfo({ orderId =vv.orderId , orderType = vv.orderType})    -- 重新遍历索引确保数据的一致
                            if orderInfo then
                                if checkint(orderInfo.status ) >1   then
                                    local LargeAndOrdinaryMediator = require( 'Game.mediator.LargeAndOrdinaryMediator')
                                    local mediator = LargeAndOrdinaryMediator.new(orderInfo)
                                    self:GetFacade():RegistMediator(mediator)
                                    return
                                end
                            end
                        end
                    end
                    if checkint(v.status )  <= 1 then -- 在休息状态
                        -- TODO 此处添加跳转
                        local TakeawayCarUpgradeMediator = require("Game.mediator.TakeawayCarUpgradeMediator")
                        local mediator = TakeawayCarUpgradeMediator.new({ diningCarId = diningCarId })
                        self:GetFacade():RegistMediator(mediator)
                        break
                    end
                end
            end
        end
    end
end
-- 检测红点的逻辑 涉及红点和等级的提升
function DeliveryAndExploreMediator:CheckBtnRedDot()
    local nodes = self.viewComponent.viewData.listView:getNodes()
    for k ,v in pairs(nodes) do
        local index =  nil
        local name = v:getName()
        local x, y  = string.find(name, "%d+")
        if x and y then
            index = checkint(checkint(string.sub(name,x,y)))
        end
        if checkint(v.type) == DINGING_CAR_STATUS.LOCK_CAR then
            local carConfig = CommonUtils.GetConfigAllMess('diningCar','takeaway')
            local carId = checkint(index)
            if carConfig[tostring(carId)] then
                local types = carConfig[tostring(carId)].unlockType
                if types[tostring(UnlockTypes.AS_LEVEL)] then
                    local isLock =  CommonUtils.CheckLockCondition(types)
                    local btn = v.viewData.unLocakBtn
                    self:ClearBtnRedDot(btn)
                    if not isLock then
                        self:AddBtnRedDot(btn)
                    end
                end
            end
        elseif   checkint(v.type) == DINGING_CAR_STATUS.UNLOCK_CAR then
            local data = CommonUtils.GetConfigAllMess('diningCarLevelUp', 'takeaway')
            local diningCarData = takeawayInstance:GetDatas().diningCar
            local level = 2
            for k , v in pairs(diningCarData) do
                if checkint(v.diningCarId) == index then
                    level = checkint(v.level)
                    break
                end
            end
            local nextLevel = level + 1
            local maxLevel =  table.nums(data)
            --if nextLevel <= maxLevel then
            --    local btn = v.viewData.infoBtn
            --    self:ClearBtnRedDot(btn)
            --    -- 判断道具是否充足
            --    local isEnough , _ = self:JuageConsumeEnough(level)
            --    if isEnough then
            --        self:AddBtnRedDot(btn)
            --    end
            --else
            --    local btn = v.viewData.infoBtn
            --    self:ClearBtnRedDot(btn)
            --end
            -- 设置等级
            if v.viewData.levelBtn and (not tolua.isnull(v.viewData.levelBtn)) then
                display.commonLabelParams(v.viewData.levelBtn ,{text = string.format(__('%d级'), level)} )
            end
        end
    end
end
--[[
   判断升级消耗道具是否充足
--]]
function DeliveryAndExploreMediator:JuageConsumeEnough(level)
    local consumeTable ={}
    local isEnough = true
    local data = CommonUtils.GetConfigAllMess('diningCarLevelUp', 'takeaway')
    local maxLevel = table.nums(data)
    local nextLevel = checkint(level)+1
    if nextLevel <=  maxLevel then
        local consumedata = clone(data[tostring(nextLevel)]["consumeGoods"])
        for	 k, val  in  pairs(consumedata) do
            table.insert(consumeTable,#consumeTable+1,val)
            local count = CommonUtils.GetCacheProductNum(val.goodsId)
            if checkint(val.num)  > count  then
                isEnough = false
            end
            consumeTable[#consumeTable].num = 0  - consumeTable[#consumeTable].num
        end
    end
    return isEnough ,consumeTable
end
function DeliveryAndExploreMediator:AddBtnRedDot(btn)
    local node = btn:getChildByTag(RED_TAG)
    if not  node  then
        local image = display.newImageView(_res('ui/common/common_hint_circle_red_ico.png'))
        image:setTag(RED_TAG)
        local size =  btn:getContentSize()
        image:setPosition(cc.p(size.width-20,size.height-20))
        btn:addChild(image,10)
    end
end
-- 清理红点
function DeliveryAndExploreMediator:ClearBtnRedDot(btn)
    local image =  btn:getChildByTag(RED_TAG)
    if image and not  tolua.isnull(image) then
        image:removeFromParent()
    end
end
-- 前往探索点的事件
function DeliveryAndExploreMediator:GoToExplorePoint(sender)
    PlayAudioByClickNormal()
    local name = sender:getName()
    local x, y  = string.find(name, "%d+")
    if x and y then
        name = string.sub(name,x,y)
        local  ExplorationMediator = require("Game.mediator.ExplorationMediator")
        local mediator = ExplorationMediator.new({ id = checkint(name)  })
        self:GetFacade():RegistMediator(mediator)
        self:GetFacade():UnRegsitMediator(NAME)
    end
end
function DeliveryAndExploreMediator:OnRegist(  )
    regPost(POST.BUSINESS_ORDER)
    regPost(POST.DELIVERY_ONE_KEY_DRAW)
    -- 如果数据还没有请求出来 直接请求数据
    local TakeAwayCommand = require( 'Game.command.TakeAwayCommand')
    self:GetFacade():RegistSignal(COMMANDS.COMMANDS_TAKEAWAY, TakeAwayCommand)
    if self.freshSuccess then
        self:EnterLayer()
    end
    -- 然后才做其他请求
end
function DeliveryAndExploreMediator:UnRegsitMediator()
    AppFacade.GetInstance():UnRegsitMediator(NAME)
end
function DeliveryAndExploreMediator:SetVisible(isVisible)
    local viewComponent = self:GetViewComponent()
    viewComponent:setVisible(isVisible)
end
function DeliveryAndExploreMediator:OnUnRegist(  )
    -- 称出命令
    unregPost(POST.BUSINESS_ORDER)
    unregPost(POST.DELIVERY_ONE_KEY_DRAW)
    local mediator = self:GetFacade():RetrieveMediator("TakeawayCarUpgradeMediator")
    if mediator then
        self:GetFacade():UnRegsitMediator("TakeawayCarUpgradeMediator")
    end
    self:GetFacade():UnRegsitSignal(COMMANDS.COMMANDS_TAKEAWAY)
    -- 关闭的时候检测是否有红点出现
    app.badgeMgr:CheckOrderRed()
    AppFacade.GetInstance():DispatchObservers(SGL.BREAK_TO_HOME_MEDIATOR)
end

return DeliveryAndExploreMediator
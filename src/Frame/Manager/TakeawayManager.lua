--[[
卡片工具管理模块
--]]
local scheduler   = require('cocos.framework.scheduler')
local ManagerBase = require( "Frame.Manager.ManagerBase" )
---@class TakeawayManager
local TakeawayManager = class('TakeawayManager',ManagerBase)
TakeawayManager.instances = {}


---------------------------------------------------
-- mediator extend begin --
---------------------------------------------------
function TakeawayManager:ctor( key )
	self.super.ctor(self)
	if TakeawayManager.instances[key] ~= nil then
		funLog(Logger.INFO,"注册相关的facade类型" )
		return
	end
	self.orderDatas = {} --定单信息的数据
	self.interval = 1 --1 计时器
    self.freshSuccess = false --是否刷新成功，
    self.freshDelta = 2 --2秒钟刷新一次请求 如果是请求失败的情况下
    self.freshHandle = nil --用来发请求的
    self.handle = nil
    self.freshOrderTimeHandle  =  nil
	TakeawayManager.instances[key] = self
    self:OnRegisterTakeawayManager()
    self:OnRegisterTakeawayPublicHttp()
end



function TakeawayManager.GetInstance(key)
	key = (key or "TakeawayManager")
	if TakeawayManager.instances[key] == nil then
		TakeawayManager.instances[key] = TakeawayManager.new(key)
	end
	return TakeawayManager.instances[key]
end


function TakeawayManager.Destroy( key )
	key = (key or "TakeawayManager")
	if TakeawayManager.instances[key] == nil then
		return
	end
	--清除配表数据
    local instance = TakeawayManager.instances[key]
    instance:GetFacade():UnRegistObserver("TakeawayManager", instance)
    instance:GetFacade():UnRegistObserver("TakeawayPublic", instance)
    instance:GetFacade():UnRegistObserver("RobberyData", instance)
    instance:Stop()
	TakeawayManager.instances[key] = nil
end

function TakeawayManager:GetDatas()

    return self.orderDatas
end

--[[
-- 是否存在定单数据，公有与私有的数据
-- @areaId --区域id 判断某个区域是否有外卖定单
--]]
function TakeawayManager:IsHaveOrder(areaId)
    local have = false
    for k,v in pairs(self.orderDatas.privateOrder or {}) do
        if checkint(v.areaId) == areaId then
            have = true
            break
        end
    end
    if have == false then
        for k,v in pairs(self.orderDatas.publicOrder or {}) do
            if checkint(v.areaId) == areaId then
                have = true
                break
            end
        end
    end
    return have
end

--[[
    刷新缓存的数据的逻辑
    orderType
    orderId == id
]]
function TakeawayManager:UpdateCacheData(orderType,orderId, data)
    if orderType == Types.TYPE_TAKEAWAY_PRIVATE then
        for k,v in pairs(self.orderDatas.privateOrder) do
            if checkint(v.orderId) == checkint(orderId) then
                table.merge(v, data)
                break
            end
        end
    elseif orderType == Types.TYPE_TAKEAWAY_PUBLIC then
        for k,v in pairs(self.orderDatas.publicOrder) do
            if checkint(v.orderId) == checkint(orderId) then
                table.merge(v, data)
                break
            end
        end
    end
    if data.diningCar then
        if self.orderDatas.diningCar then
            for k,v in pairs(self.orderDatas.diningCar) do
                if checkint(v.diningCarId) == checkint(data.diningCar.diningCarId) then
                    table.merge(v, data.diningCar)
                end
            end
        end
    end
    -- app.gameMgr:setDeliveryTeam(self.orderDatas.diningCar) --更新数据
end

--[[
--清除所有已到达外卖缓存
--@diningCars 到达的外卖车
--]]
function TakeawayManager:DeliveryAllArrived(diningCars)
    local diningCarTable = self.orderDatas.diningCar
    for _,v in pairs(diningCars) do
        for k, dicar in pairs(diningCarTable) do 
            if checkint(v) == checkint(dicar.diningCarId) then
                local orderId = checkint(dicar.orderId)
                for i,porder in pairs(self.orderDatas.privateOrder) do
                    if checkint(porder.orderId) == orderId then
                        table.remove(self.orderDatas.privateOrder, i)
                        break
                    end
                end
                for i,porder in pairs(self.orderDatas.publicOrder) do
                    if checkint(porder.orderId) == orderId then
                        table.remove(self.orderDatas.publicOrder, i)
                        break
                    end
                end
                app.gameMgr:setMutualTakeAwayToTeam(dicar.teamId , CARDPLACE.PLACE_TAKEAWAY,CARDPLACE.PLACE_TEAM)

                --将状态改为待送状态
                dicar.status = 1
                dicar.teamId = nil
                dicar.orderType = nil
                dicar.orderId = nil
                break
            end
        end
    end
end


--[[
--清除一个外卖缓存，用来作领取奖励与取消的逻辑的功能
--发车的逻辑
--@orderId
--@orderType 类型
--@data 变换类型的数据要更新的数据，如果是删除数据请不要传这个参数
--]]
function TakeawayManager:DeliveryOrDeleteCacheData(orderType, orderId, data)
    if data then
        self:UpdateCacheData(orderType,orderId, data)
    else
        local data   = clone(self:GetOrderInfoByOrderInfo({orderId = orderId, orderType = orderType}))   --获取订单表
        if orderType == Types.TYPE_TAKEAWAY_PRIVATE then
            for i,v in pairs(self.orderDatas.privateOrder) do
                if checkint(v.orderId) == checkint(orderId) then
                    table.remove(self.orderDatas.privateOrder, i)
                    break
                end
            end
        end
        if orderType == Types.TYPE_TAKEAWAY_PUBLIC then
            for i,v in pairs(self.orderDatas.publicOrder) do
                if checkint(v.orderId) == checkint(orderId) then
                    table.remove(self.orderDatas.publicOrder, i)
                    break
                end
            end
        end
        local diningCarTable = self:GetDatas().diningCar
        for k, v in pairs(diningCarTable) do  --插入diningCar 表
            if checkint(data.diningCarId)  == checkint(v.diningCarId)  then
                    --不能移除要将状态改为待送状态
                v.status = 1
                v.teamId = nil
                v.orderType = nil
                v.orderId = nil
                break
            end

        end
        -- app.gameMgr:setDeliveryTeam(self.orderDatas.diningCar) --更新数据
    end
end

--[[
    根据车的信息获取订单的相关信息
    carInfo = {
        orderId = 100,
        orderType = 2
    }
]]
function TakeawayManager:GetOrderInfoByOrderInfo(carInfo)
    local orderId = checkint(carInfo.orderId)
    local orderType = checkint(carInfo.orderType)
    local orderInfo = nil
    if orderType == Types.TYPE_TAKEAWAY_PRIVATE then
         for k,v in pairs(self.orderDatas.privateOrder) do
            if checkint(v.orderId) == orderId then
                orderInfo = v
                break
            end
        end
    elseif orderType == Types.TYPE_TAKEAWAY_PUBLIC then
        for k,v in pairs(self.orderDatas.publicOrder) do
            if checkint(v.orderId) == orderId then
                orderInfo = v
                break
            end
        end
    end
    return orderInfo
end


--[[
    处理领取时间的请求 是否是增加延时处理
    五分钟以内加上五秒钟后做延时处理
--]]
function TakeawayManager:juageNetWorkTime()
    if self.orderDatas.privateOrder then
        for k , v in pairs( self.orderDatas.privateOrder)  do
            if  checkint(v.status) > 1 and checkint(v.status)  < 4 then
                if  checkint(v.leftSeconds) > 0 then
                    v.leftSeconds  =  1 + checkint(v.leftSeconds)
                end
            end
        end
        for k , v in pairs( self.orderDatas.publicOrder)  do
            if  checkint(v.status) > 1 and checkint(v.status)  < 4 then
                if   checkint(v.leftSeconds) > 0 then
                    v.leftSeconds = 1  + checkint(v.leftSeconds)
                end
            end
        end
    end
    local nextPrivateOrderRefreshTime = self.orderDatas.nextPrivateOrderRefreshTime
    if nextPrivateOrderRefreshTime  > 0 then
        nextPrivateOrderRefreshTime = 1 + nextPrivateOrderRefreshTime
        self.orderDatas.nextPrivateOrderRefreshTime = nextPrivateOrderRefreshTime
    end
    local nextPublicOrderRefreshTime = self.orderDatas.nextPublicOrderRefreshTime
    if nextPublicOrderRefreshTime  > 0 then
        nextPublicOrderRefreshTime = 1 + nextPublicOrderRefreshTime
        self.orderDatas.nextPublicOrderRefreshTime   =  nextPublicOrderRefreshTime
    end
end

function TakeawayManager:OnRegisterTakeawayManager ()
    self:GetFacade():RegistObserver("TakeawayManager", mvc.Observer.new(function(context, signal)
        --注册请求成功的处理的逻辑
        self.orderDatas = signal:GetBody()
        if self.orderDatas == nil then return end
        
        if not self.freshSuccess then -- 外卖第一次回来请求数据 其他地方检测
            app.badgeMgr:CheckOrderRed()
        end
        self.freshSuccess = true --刷新成功的逻辑,开始添加一个计时下次刷新的倒计时的逻辑

        for k ,v in pairs(self.orderDatas.privateOrder or {}) do
            v.orderType = 1
        end
        for k ,v in pairs(self.orderDatas.publicOrder or {}) do
            v.orderType = 2
        end
        -- self.orderDatas = {}

        -- app.gameMgr:setDeliveryTeam(self.orderDatas.diningCar)  -- 首先更新编队
        self.orderDatas.nextPrivateOrderRefreshTime = checkint(self.orderDatas.nextPrivateOrderRefreshTime)
        self.orderDatas.nextPublicOrderRefreshTime  =  checkint(self.orderDatas.nextPublicOrderRefreshTime)
        self:juageNetWorkTime()
        self:UpdateNextPriveateTimeAndPublicTime()
        self.orderDatas.nextPrivateOrderRefreshTime = checkint(self.orderDatas.nextPrivateOrderRefreshTime)
        self.orderDatas.nextPublicOrderRefreshTime  =  checkint(self.orderDatas.nextPublicOrderRefreshTime)
        local nextPrivateOrderRefreshTime = checkint(self.orderDatas.nextPrivateOrderRefreshTime)
        local nextPublicOrderRefreshTime = checkint(self.orderDatas.nextPublicOrderRefreshTime)
        local interval =  0
        if nextPublicOrderRefreshTime == -1 or nextPrivateOrderRefreshTime == -1 then --  道计时<-1 取最大
            interval =  math.max(nextPrivateOrderRefreshTime , nextPublicOrderRefreshTime)
        else
            interval = math.min(nextPrivateOrderRefreshTime , nextPublicOrderRefreshTime)
        end
        if ( interval > 0  ) then
            self:Start(interval)
        else
            if (self.orderDatas.privateOrder and table.nums(self.orderDatas.privateOrder) > 0) or
                (self.orderDatas.publicOrder and table.nums(self.orderDatas.publicOrder) > 0 ) then
                self:RegistCountDown()
            end
            if self.handle then
                scheduler.unscheduleGlobal(self.handle)
                self.handle = nil
            end
        end

        if not app.gameMgr:isShowHomeRobberyMap() then
            self:GetFacade():DispatchObservers(FRESH_TAKEAWAY_POINTS)
        else
            self:GetFacade():DispatchObservers(FRESH_TAKEAWAY_ORDER_POINTS)
        end

        -- set unlock order data
        local appMediator = AppFacade.GetInstance():RetrieveMediator('AppMediator')
        local unlockOData = appMediator and appMediator:getUpgradeUnlockOrderData() or nil
        if unlockOData and next(unlockOData) == nil then
            for i, orderData in ipairs(self.orderDatas.privateOrder) do
                if checkint(orderData.status) == 1 then
                    appMediator:setUpgradeUnlockOrderData(orderData)

                    local homeMediator      = AppFacade.GetInstance():RetrieveMediator('HomeMediator')
                    local unlockFunctionMdt = AppFacade.GetInstance():RetrieveMediator('HomeUnlockFunctionMediator')
                    if homeMediator and not unlockFunctionMdt then
                        AppFacade.GetInstance():DispatchObservers(SGL.BREAK_TO_HOME_MEDIATOR)
                    end
                    break
                end
            end
        end

    end,self))
end
--[[
    注册公有订单的http请求
--]]
function TakeawayManager:OnRegisterTakeawayPublicHttp()
    self:GetFacade():RegistObserver("TakeawayPublic", mvc.Observer.new(function(context, signal)
        local publicData = signal:GetBody()
        self.orderDatas.nextPublicOrderRefreshTime = checkint(publicData.nextPublicOrderRefreshTime)
        for i, v in pairs(publicData.publicOrder or {}) do
            local isHave = false 
            if v.orderId  then
                for ii, vv in pairs(checktable(self.orderDatas).publicOrder or {}) do
                    if v.orderId and  (checkint(vv.orderId)  ==   checkint(v.orderId))   then
                        -- 检测出来相同的订单 合并数据
                        isHave = true
                        table.merge( v,vv )
                        break
                    end
                end
                if not isHave  then
                    v.status = 1
                    self.orderDatas.publicOrder[#self.orderDatas.publicOrder+1] = v
                end
            end
        end
        AppFacade.GetInstance():DispatchObservers("TakeawayManager" ,self.orderDatas)
    end,self))
end
function TakeawayManager:FreshData()
    if not CommonUtils.GetModuleAvailable(MODULE_SWITCH.TAKEWAY) and not CommonUtils.GetModuleAvailable(MODULE_SWITCH.PUBLIC_ORDER) then
        return
    end
        --没有请求过 发起一次请求的逻辑
    if self.freshSuccess then

    else
        if not self.freshHandle then
            self.freshHandle = scheduler.scheduleGlobal(function(dt)
                --执行请求的逻辑
                if not self.freshSuccess then
                    xTry(function()
                        self:GetHttpManager():Post('Takeaway/home', "TakeawayManager",{}, function(msg)
                            --如果是请求失败的情况下
                            self.freshSuccess = false --刷新失败的 下次10秒后再刷新一次请求
                        end, true)
                    end,function()
                        self:Stop() --出异常后停掉功能
                    end)
                end
            end, self.freshDelta, false)
        end
    end
end


-- 发送请求
function TakeawayManager:postRobberyNetWork()
    self:GetHttpManager():Post('Takeaway/robberyList', "RobberyData",{})
end

function TakeawayManager:GetOrderTimerKey(areaId, orderType, orderId)
    return string.format('ItemNodeView_%d_%d_%d', checkint(areaId), checkint(orderType), checkint(orderId))
end
function TakeawayManager:GetOrderTimerINfo(areaId, orderType, orderId)
    return app.timerMgr:RetriveTimer(self:GetOrderTimerKey(areaId, orderType, orderId))
end

function TakeawayManager:RegistCountDown()
    -- clean all timer
    for i, timerInfo in ipairs(self.timerList_ or {}) do
        app.timerMgr:RemoveTimer(timerInfo.name)
    end

    -- create timer
    self.timerList_ = {}
    local orderList = {}
    for _, orderData in pairs(checktable(self.orderDatas).publicOrder or {}) do
        local orderStatus = checkint(orderData.status)
        if orderStatus == 1 or orderStatus == 2 or orderStatus == 3 then
            orderData.orderType = Types.TYPE_TAKEAWAY_PUBLIC
            table.insert(orderList, orderData)
        end
    end
    for _, orderData in pairs(checktable(self.orderDatas).privateOrder or {}) do
        local orderStatus = checkint(orderData.status)
        if orderStatus == 2 or orderStatus == 3 then
            orderData.orderType = Types.TYPE_TAKEAWAY_PRIVATE
            table.insert(orderList, orderData)
        end
    end
    for _, orderData in ipairs(orderList) do
        local orderType = orderData.orderType
        local countdown = checkint(orderData.status) == 1 and checkint(orderData.endLeftSeconds) or checkint(orderData.leftSeconds)
        local timerKey  = self:GetOrderTimerKey(orderData.areaId, orderType, orderData.orderId)
        local timerInfo = app.timerMgr:AddTimer({name = timerKey, countdown = countdown, tag = RemindTag.TAKEAWAY_TIMER, datas = orderData})
        table.insert(self.timerList_, timerInfo)

        -- dispatch ui update
        -- self:GetFacade():DispatchObservers(COUNT_DOWN_ACTION_UI, {countdown = countdown, timeNum = countdown, orderType = orderType, datas = orderData})
    end

    -- add timer countdown listener
    self:GetFacade():RegistObserver(COUNT_DOWN_ACTION, mvc.Observer.new(function(item, signal)
        xTry(function()
            local body = signal:GetBody()
            if body.tag == RemindTag.TAKEAWAY_TIMER then
                local orderData = checktable(body.datas)
                local orderType = checkint(orderData.orderType)
                local orderId   = checkint(orderData.orderId)

                -- check order is exist
                if self:GetOrderInfoByOrderInfo({orderId = orderId, orderType = orderType}) then
                    local nowTime     = checkint(body.countdown)
                    local endTime     = checkint(body.timeNum)
                    local orderStatus = checkint(orderData.status)

                    -- check countdown
                    if nowTime > 0 then

                        -- update countdown cache
                        if orderStatus == 1 then
                            self:UpdateCacheData(orderType, orderId, {endLeftSeconds = nowTime})
                        else
                            self:UpdateCacheData(orderType, orderId, {leftSeconds = nowTime})
                        end

                    else
                        if orderStatus == 1 then
                            if orderType == Types.TYPE_TAKEAWAY_PUBLIC then
                                -- remove public order
                                for i, v in pairs(checktable(self.orderDatas).publicOrder or {}) do
                                    if checkint(v.orderId) == orderId then
                                        app.timerMgr:RemoveTimer(body.timerName)
                                        table.remove(self.orderDatas.publicOrder, i)
                                        self:GetFacade():DispatchObservers(FRESH_TAKEAWAY_POINTS)
                                        break
                                    end
                                end
                            end
                        else
                            -- order status to done
                            self:UpdateCacheData(orderType, orderId, {leftSeconds = nowTime, status = 4, diningCar = {diningCarId = orderData.diningCarId, status = 4}})
                            app.timerMgr:RemoveTimer(body.timerName)

                            -- add redDot notification
                            app.dataMgr:AddRedDotNofication(tostring(RemindTag.ORDER), tostring(RemindTag.ORDER), "[外卖订单]-COUNT_DOWN_ACTION")
                            AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, {tag = RemindTag.ORDER, countdown = 0})
                        end
                    end

                    -- dispatch ui update
                    self:GetFacade():DispatchObservers(COUNT_DOWN_ACTION_UI, {countdown = nowTime, timeNum = endTime, orderType = orderType, datas = orderData})

                else
                    app.timerMgr:RemoveTimer(body.timerName)
                    self:GetFacade():DispatchObservers(FRESH_TAKEAWAY_POINTS)
                end
            end
        end, __G__TRACKBACK__)
    end, self))
end
function TakeawayManager:GetTakeAwayGoodData()
    local takeawayActivityData = self.orderDatas.takeawayActivity or {}
    local data= {}
    for k ,v in pairs(takeawayActivityData) do
        if checkint(v.leftSeconds)  > 0 then
            data[#data+1] = {goodsId = checkint(v.goods)  , num =  1  }
        end
    end
    return data
end

--[[
    更新活动的倒计时
--]]
function TakeawayManager:UpdeateActivity(countDown)
    local takeawayActivityData = self.orderDatas.takeawayActivity or {}
    for k ,v in pairs(takeawayActivityData) do
        if checkint(v.leftSeconds)  > 0 then
            v.leftSeconds =  checkint(v.leftSeconds)  - countDown
        end
    end
end
--==============================--
--desc:用于检测是否有外卖车
--time:2017-06-29 06:30:04
--@return
--==============================--
function TakeawayManager:CheckDiningCarNum(  )
    -- body
end
function TakeawayManager:Start(interval)
    --启动循环器
    self:RegistCountDown()
    --if not interval then interval = 10 end
    --self.interval = interval
    --if self.handle then
    --    scheduler.unscheduleGlobal(self.handle)
    --    self.handle = nil
    --end
    --if not self.handle then
    --    self.handle = scheduler.scheduleGlobal(handler(self,self.onTimerScheduler), self.interval, false)
    --end
end

function TakeawayManager:Stop()
    --启动循环器
    self:GetFacade():UnRegistObserver(COUNT_DOWN_ACTION, self)
    self.freshSuccess = true
    if self.freshHandle then
        scheduler.unscheduleGlobal(self.freshHandle)
        self.freshHandle = nil
    end
    if self.freshOrderTimeHandle then
        scheduler.unscheduleGlobal(self.freshOrderTimeHandle)
        self.freshOrderTimeHandle = nil
    end
    if self.handle then
        scheduler.unscheduleGlobal(self.handle)
        self.handle = nil
    end
end

--[[
内部的定时器
@param dt 时间间隔
--]]
function TakeawayManager:onTimerScheduler(dt)
    --时间到了请求一次
    if dt >= self.interval then
        if self.freshSuccess then
            xTry(function()
                self:GetHttpManager():Post('Takeaway/home', "TakeawayManager",{}, function(msg)
                --如果是请求失败的情况下
                self.freshSuccess = false --刷新失败的 下次2秒后再刷新一次请求
                end, true)
            end,function()
                --停掉计时器
                self:Stop()
            end)
        end
    end
end
-- 撤销订单或者领取奖励要重新刷新一次
function TakeawayManager:DirectRfreshOrder()
     xTry(function()
        self:GetHttpManager():Post('Takeaway/home', "TakeawayManager",{})
    end)
end
-- 撤销订单或者领取奖励要重新刷新一次
function TakeawayManager:TakeawayHttpPublish()
    xTry(function()
        self:GetHttpManager():Post('Takeaway/publicOrder', "TakeawayPublic",{})
    end)
end
--==============================--
--desc:用于数据的刷新，修正外卖的时间
--time:2017-06-29 03:07:46
--@return
--==============================--
-- function TakeawayManager:RegistAmendmentTime()
--     self:getFacade():RegistObserver(APP_ENTER_FOREGROUND, mvc.Observer.new(function (item , singale)
--         self:DirectRfreshOrder()
--     end))
-- end
--[[
    更新订单刷新的信息
--]]
function TakeawayManager:UpdateNextPriveateTimeAndPublicTime()
    local startTime = checkint(os.time())
    if  self.freshOrderTimeHandle then
        scheduler.unscheduleGlobal(self.freshOrderTimeHandle)
        self.freshOrderTimeHandle  = nil
        self.freshOrderTimeHandle = scheduler.scheduleGlobal(
            function ()
                local curTime =  os.time()
                local distance = curTime - startTime
                startTime = curTime
                local curNextPrivateOrderRefreshTime = self.orderDatas.nextPrivateOrderRefreshTime
                local curNextPublicOrderRefreshTime = self.orderDatas.nextPublicOrderRefreshTime
                if  self.orderDatas.nextPrivateOrderRefreshTime > 0   then
                    self.orderDatas.nextPrivateOrderRefreshTime  =  self.orderDatas.nextPrivateOrderRefreshTime -distance
                end
                if  self.orderDatas.nextPublicOrderRefreshTime > 0   then
                    self.orderDatas.nextPublicOrderRefreshTime  =  self.orderDatas.nextPublicOrderRefreshTime - distance
                end
                if (curNextPrivateOrderRefreshTime > 0 and self.orderDatas.nextPrivateOrderRefreshTime <= 0) then -- 判断是否做刷新订单的请求

                    self:DirectRfreshOrder()

                elseif (curNextPublicOrderRefreshTime > 0 and self.orderDatas.nextPublicOrderRefreshTime <= 0) then
                    self:TakeawayHttpPublish()
                end

                if  self.orderDatas.nextPublicOrderRefreshTime <= 0  and   self.orderDatas.nextPrivateOrderRefreshTime <= 0  then

                    scheduler.unscheduleGlobal(self.freshOrderTimeHandle)
                    self.freshOrderTimeHandle = nil
                end
                self:UpdeateActivity(distance)
            end , 1, false
        )
    else
        self.freshOrderTimeHandle = scheduler.scheduleGlobal(
            function ()
                local curTime =  os.time()
                local distance = curTime - startTime
                local curNextPrivateOrderRefreshTime = self.orderDatas.nextPrivateOrderRefreshTime
                local curNextPublicOrderRefreshTime = self.orderDatas.nextPublicOrderRefreshTime
                startTime = curTime
                if self.orderDatas.nextPrivateOrderRefreshTime > 0   then
                    self.orderDatas.nextPrivateOrderRefreshTime  =  self.orderDatas.nextPrivateOrderRefreshTime - distance

                end
                if self.orderDatas.nextPublicOrderRefreshTime > 0   then
                    self.orderDatas.nextPublicOrderRefreshTime  =  self.orderDatas.nextPublicOrderRefreshTime - distance
                end
                if (curNextPrivateOrderRefreshTime > 0 and self.orderDatas.nextPrivateOrderRefreshTime <= 0) then -- 判断是否做刷新订单的请求
                    self:DirectRfreshOrder()
                elseif (curNextPublicOrderRefreshTime > 0 and self.orderDatas.nextPublicOrderRefreshTime <= 0) then
                    self:TakeawayHttpPublish()
                end
                if  self.orderDatas.nextPublicOrderRefreshTime <= 0  and   self.orderDatas.nextPrivateOrderRefreshTime <= 0  then
                    scheduler.unscheduleGlobal(self.freshOrderTimeHandle)
                    self.freshOrderTimeHandle = nil
                end
                self:UpdeateActivity(distance)
            end , 1, false
        )
    end

end


-- 判断外卖是否符合等级刷新
function TakeawayManager:FreshTakeawayData()
    -- 判断
    local openLevel = checkint(CommonUtils.GetGameModuleConf()[tostring(MODULE_DATA[tostring(RemindTag.CARVIEW)])].openLevel)
    if app.gameMgr:GetUserInfo().level >= openLevel then
        -- 做刷新的请求
        self:DirectRfreshOrder()
    end

end


return TakeawayManager

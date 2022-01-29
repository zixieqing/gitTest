--[[
厨房Mediator
--]]
local Mediator = mvc.Mediator

local AvatarMediator = class("AvatarMediator", Mediator)

local NAME = "AvatarMediator"


local shareFacade = AppFacade.GetInstance()
local uiMgr = shareFacade:GetManager("UIManager")
local gameMgr = shareFacade:GetManager("GameManager")
local socketMgr = shareFacade:GetManager('SocketManager')
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
local timerMgr = AppFacade.GetInstance():GetManager("TimerManager")
local scheduler = require('cocos.framework.scheduler')
local DragNode = require('Game.views.restaurant.DragNode')


local TILED_WIDTH = RESTAURANT_TILED_WIDTH
local TILED_HEIGHT = RESTAURANT_TILED_HEIGHT
local TILED_SIZE = RESTAURANT_TILED_SIZE
local EAT_STATS = RESTAURANT_EAT_STATS
local RoleType = RESTAURANT_ROLE_TYPE


function AvatarMediator:ctor(params, viewComponent)
	self.super.ctor(self, NAME, viewComponent)
    self.datas = checktable(params)

    self.canBack = true
    self.serveNo = 1 --表示第一个人

    self.isFirstLookFriend = true  -- 标识 第一次查看好友

    -------------------代理店长容错------------------
    if self.datas.managerLeftSeconds and checkint(self.datas.managerLeftSeconds) < 0 then
        self.datas.managerLeftSeconds = 0
        self.datas.mangerId = 0
    end
    -------------------代理店长容错------------------

    -------------------定时器容错------------------
    if self.datas.nextRestaurantTaskLeftSeconds and checkint(self.datas.nextRestaurantTaskLeftSeconds) > 0 and checkint(self.datas.nextRestaurantTaskLeftSeconds) < 600 then
        self.datas.nextRestaurantTaskLeftSeconds = self.datas.nextRestaurantTaskLeftSeconds + 3
    end
    -------------------定时器容错------------------
    self.handleData = {} --当前的操作点数据
    self.tiledWidth = TILED_WIDTH--所有的格子数
    self.tiledHeight = TILED_HEIGHT-- 格子高
    self.minTileHeight = math.floor((1002 - display.height) / 2 / TILED_SIZE)
    self.maxTileHeight = math.ceil((DRAG_AREA_RECT.y + DRAG_AREA_RECT.height) / TILED_SIZE)


    self.isStop = false --是否暂时停当前所有的计时器

    self.decorationing = false --是否在装修中

    self.canVisitor = true --是否可请求食客

    self.canServiceLock = true --当前是否可上菜的锁
    self.deskInfoLock = true --是否可以请求餐桌信息

    self.requestQueue = {} --上菜请求的接口的逻辑功能

    self.waitingCustomNodeQueue = {} --门口等待的客人临时节点
    self.waitingQueue = {} --等待的顾客数据的逻辑
    self.servicingQueue = {} --正位置上的数据信息{[seatId]= data}
    self.waiterQueue = {} --所有服务员数据
    self.bugQueue = {} -- 虫子区域id列表
    self.clickCardId = nil --点击卡牌的cardid
    funLog(Logger.INFO, string.format('dragArea-- startHeight[%d] -- endHeight[%d]', self.minTileHeight, self.maxTileHeight))
    self.blocks = {}
    for i=1,self.tiledWidth do
        for j=1,self.tiledHeight do
            local block = {}
            block.w = i
            block.h = j
            block.pos = cc.p(0 + TILED_SIZE * 0.5 + (i - 1) * TILED_SIZE, 0 + TILED_SIZE* 0.5 + (j - 1) * TILED_SIZE)
            block.couldCross = true
            if j > self.maxTileHeight then
                block.couldCross = false
            elseif j < self.minTileHeight then
                block.couldCross = false
            end
            self.blocks[string.format('%d_%d',i,j)] = block
        end
    end

    gameMgr:GetUserInfo().avatarCacheData = checktable(self.datas)
    self.houseLocation = checktable(self.datas.location)
    for idx,val in pairs(checktable(self.datas.customerWaitingSeat)) do
        table.insert(self.waitingQueue, val) --进入队列的数据
    end

    for key,val in pairs(checktable(self.datas.seat)) do
        if val.customerUuid then
            --表示座位上有人存在的逻辑
            val.hasCustomer = 1 --存在人的逻辑
        else
            val.hasCustomer = 0 --不存在食客的逻辑
        end
        val.seatId = key
        self.servicingQueue[tostring(key)] = val --餐桌信息
    end
    for name,val in pairs(checktable(self.datas.waiter)) do
        --更新下服务员vigour
        self.waiterQueue[tostring(name)] = val
        gameMgr:UpdateCardDataById(checkint(name), {vigour = checkint(val.vigour)})
    end
    if CommonUtils.GetModuleAvailable(MODULE_SWITCH.PERISH_BUG) then
        self.bugQueue = checktable(self.datas.bug)
    end
    local view = uiMgr:SwitchToTargetScene('Game.views.restaurant.AvatarView',{ids = self.datas.location})
    -- 刷新等级 经验
    self:SetViewComponent(view)
    -- 更新任务按钮状态
    self:UpdateTaskButtonStatus()
    -- 更新情报按钮的状态
    self:UpdateInformationButtonStatus()
    -- 更新装修与家具商店红点状态
    self:UpdateAvatarRenovationRemind(table.nums(gameMgr:GetUserInfo().avatarCacheRestaurantLevels) > 0 or table.nums(gameMgr:GetUserInfo().avatarCacheRestaurantNews) > 0)
    -- 更新餐厅活动状态
    self:UpdateAvatarTopBtnLayer()
    self:StartAgentShopownerCountDown()
    -- 领取知名度排名奖励
    if self.datas.lastPopularityRankRewards then
        uiMgr:AddDialog('common.RankRewardPopup', {rewards = checktable(self.datas.lastPopularityRankRewards), scoreText = __('上赛季知名度'), rank = self.datas.myLastPopularityRank, score = self.datas.myLastPopularityScore})
        CommonUtils.DrawRewards(checktable(self.datas.lastPopularityRankRewards))
    end
    self:FreshDoorAnimate()
end

--获取点击服务员或者厨师cardid
function AvatarMediator:SetClickCardId( id )
    if id then
        self.clickCardId = id
    end
end
--[[
--添加请求入队列现阶段是指6007
--]]
function AvatarMediator:PushRequestQueue(cmd)
    table.insert(self.requestQueue, checkint(cmd))
end

function AvatarMediator:PopRequestQueue()
    table.remove(self.requestQueue, 1)
    -- dump(self.requestQueue)
end

function AvatarMediator:InterestSignals()
	local signals = {
        APP_ENTER_FOREGROUND,
        APP_ENTER_BACKGROUND,
        RESTAURANT_EVENTS.EVENT_UPDATA_COOKLIMIT_NUM,
        RESTAURANT_EVENTS.EVENT_EMPTY_RECIPE,
        RESTAURANT_EVENTS.EVENT_EMPTY_ONE_RECIPE,
        RESTAURANT_EVENTS.EVENT_CLOSE_MAKE_RECIPE,
        RESTAURANT_EVENTS.EVENT_DESTINATION,
        RESTAURANT_EVENTS.EVENT_SERVICE_ANIMATION,
        RESTAURANT_EVENTS.EVENT_SWITCH_WAITER,
        RESTAURANT_EVENTS.EVENT_NEW_CUSTOM_ARRIVAL,
        RESTAURANT_EVENTS.EVENT_DESK_INFO,
        RESTAURANT_EVENTS.EVENT_BACK_DECORATE,
        RESTAURANT_EVENTS.EVENT_CLICK_DESK,
        RESTAURANT_EVENTS.EVENT_AVATAR_SHOP,
        RESTAURANT_EVENTS.EVENT_AVARAR_DATA_SYS,
        SIGNALNAMES.CACHE_MONEY_UPDATE_UI,
        SIGNALNAMES.SIGNALNAME_HOME_AVATAR, --主界面的请求信息
        SIGNALNAMES.SIGNALNAME_BUY_AVATAR,
        SIGNALNAMES.SIGNALNAME_UNLOCK_AVATAR,
        SIGNALNAMES.SIGNALNAME_GET_TASK,
        SIGNALNAMES.SIGNALNAME_DRAW_TASK,
        SIGNALNAMES.SIGNALNAME_6001,
        SIGNALNAMES.SIGNALNAME_6002,
        SIGNALNAMES.SIGNALNAME_6003,
        SIGNALNAMES.SIGNALNAME_6004,
        SIGNALNAMES.SIGNALNAME_6005,
        SIGNALNAMES.SIGNALNAME_6006,
        SIGNALNAMES.SIGNALNAME_6007,
        SIGNALNAMES.SIGNALNAME_6008,
        SIGNALNAMES.SIGNALNAME_2027,
        SGL.SIGNALNAME_CLEAN_ALL_AVATAR,
        RESTAURANT_TESK_PROGRESS,
        SIGNALNAMES.SIGNALNAME_CANCEL_AVATAR_QUEST, --取消霸王餐
        SIGNALNAMES.SIGNALNAME_Home_RecipeCookingDone, --菜谱cd完成
        RESTAURANT_EVENTS.EVENT_CLOSED_MAKING_SCHEDULER, --关闭做菜倒计时
        SGL.REFRESH_NOT_CLOSE_GOODS_EVENT, -- 道具变动时检索餐厅是否可升级
        POST.RESTAURANT_AGENT_SHOPOWNER.sglName, --  购买代理店长
        POST.RESTAURANT_CANCEL_AGENT_SHOPOWNER.sglName, -- 取消代理店长
        AvatarScene_ChangeCenterContainer,
        "AVATAR_BACK",
        -- SIGNALNAMES.SIGNALNAME_FRIEND_AVATAR_STATE,
        RESTAURANT_EVENTS.EVENT_AVATAR_SHOP_SIGN_OUT,
        RESTAURANT_EVENTS.EVENT_AVATAR_SHOP_UPDATE_REMIND,
        SIGNALNAMES.IcePlace_AddCard_Callback,--放入冰场
        SIGNALNAMES.Lobby_EmployeeSwitch_Callback,
        'SHARE_BUTTON_EVENT',
        'SHARE_BUTTON_BACK_EVENT',
        FRIEND_UPDATE_LOBBY_FRIEND_BTN_STATE,
        SIGNALNAMES.Friend_REMOVE_BUGAT_Callback, -- 更新 bugat
        COUNT_DOWN_ACTION,
        LOBBY_FESTIVAL_ACTIVITY_END,
        LOBBY_FESTIVAL_ACTIVITY_PREVIEW_END,
        'CLOSE_TEAM_FORMATION',
        SGL.RESTAURANT_APPLY_SUIT_RESULT,
        SGL.RESTAURANT_PREVIEW_SUIT,
    }
	return signals
end

local startTime = getServerTime()
local loopStartTime = startTime

function AvatarMediator:ProcessSignal( signal )
	local name = signal:GetName()
    local body = checktable(checktable(signal:GetBody()))
    -- dump(body)
    if name == RESTAURANT_EVENTS.EVENT_BACK_DECORATE then
        self:SwitchDecorate()
    elseif name == 'AVATAR_BACK' then
        --返回的操作逻辑
        if  shareFacade:RetrieveMediator('ShopMediator') then
            shareFacade:UnRegsitMediator('ShopMediator')
        else
            local node = self.viewComponent:getChildByName('DecorateView')
            if node and node:isVisible() then
                node:setVisible(false)
                local catView = self.viewComponent:getChildByName("CatView")
                if catView and catView:isVisible() then catView:setVisible(false) end
                shareFacade:DispatchObservers(RESTAURANT_EVENTS.EVENT_BACK_DECORATE)
            else
                if  CommonUtils.GetModuleAvailable(MODULE_SWITCH.HOMELAND) and CommonUtils.UnLockModule(JUMP_MODULE_DATA.HOME_LAND)  then
                    app:RetrieveMediator("Router"):Dispatch({name =  'HomeMediator'} , {name =  "HomelandMediator" })
                else
                    shareFacade:BackMediator()
                end
                -- self:GetFacade():RetrieveMediator("Router"):RegistBackMediators()
                GuideUtils.DispatchStepEvent()
            end
        end
    elseif name == RESTAURANT_EVENTS.EVENT_AVATAR_SHOP then

        -- self.viewComponent.viewData.friendBtn:setVisible(false)
        local AvatarShopMediator = require( 'Game.mediator.AvatarShopMediator' )
        local mediator = AvatarShopMediator.new()
        self:GetFacade():RegistMediator(mediator)
    elseif name == RESTAURANT_EVENTS.EVENT_AVATAR_SHOP_UPDATE_REMIND then
        -- 1. 查询
        local restaurantLevel = body.restaurantLevel
        if restaurantLevel then
            local showRemind = restaurantLevel ~= -1
            if not showRemind then
                -- 移除 全局 餐厅等级 缓存
                gameMgr:GetUserInfo().avatarCacheRestaurantLevels = {}
            else
                gameMgr:GetUserInfo().avatarCacheRestaurantLevels[tostring(restaurantLevel)] = restaurantLevel
            end
            self:UpdateAvatarRenovationRemind(showRemind)
        else
            gameMgr:GetUserInfo().avatarCacheRestaurantLevels = {}
            self:UpdateAvatarRenovationRemind(false)
        end
        -- gameMgr:GetUserInfo().showRedPointForAvatarShop = checkbool(body.showRemind)

    elseif name == SIGNALNAMES.CACHE_MONEY_UPDATE_UI then
        --更新界面显示
        self:GetViewComponent():UpdateCountUI()
        self:UpdateInformationButtonStatus()
    elseif name == SGL.REFRESH_NOT_CLOSE_GOODS_EVENT then
        self:UpdateInformationButtonStatus()
    elseif name == RESTAURANT_EVENTS.EVENT_UPDATA_COOKLIMIT_NUM then
        self:UpDataNowRecipeNumAndMess()
    elseif name == RESTAURANT_EVENTS.EVENT_EMPTY_RECIPE then
        self.datas.recipe = {}
        self:UpDataNowRecipeNumAndMess()
    elseif name == RESTAURANT_EVENTS.EVENT_EMPTY_ONE_RECIPE then
        self:UpDataNowRecipeNumAndMess()
    elseif name == RESTAURANT_EVENTS.EVENT_CLOSE_MAKE_RECIPE then
        self:UpdateScheduleMap()
    elseif name == RESTAURANT_EVENTS.EVENT_CLOSED_MAKING_SCHEDULER then
        for i,v in pairs(self.recipeCdUpdateFunc) do
            if checkint(i) == signal:GetBody() then
                if v then
                    scheduler.unscheduleGlobal(v)
                end
            end
        end
        self:UpDataNowRecipeNumAndMess()
    elseif name == SIGNALNAMES.SIGNALNAME_Home_RecipeCookingDone then
        local data = signal:GetBody()
        local playerCardId = gameMgr:GetUserInfo().chef[tostring(data.requestData.employeeId)]
        local  recipeCooking = self.datas.recipeCooking[tostring(playerCardId)] or {}
        local recipeId = recipeCooking.recipeId
        local recipeNum = recipeCooking.recipeNum
        local bool = false
        for k,v in pairs(self.datas.recipe) do
            if checkint(k) == checkint(recipeId) then
                bool = true
                self.datas.recipe[k] = v + recipeNum
                break
            end
        end
        if bool == false then
            self.datas.recipe[tostring(recipeId)] = recipeNum
        end
        AppFacade.GetInstance():DispatchObservers(EVENT_MAKE_DONE,data)
        self.datas.recipeCooking[tostring(playerCardId)] = nil
        self:UpDataNowRecipeNumAndMess()
    elseif name == APP_ENTER_FOREGROUND then
        --从后台回来的逻辑
        local deltaTime = getServerTime() - startTime
        --更新队列信息数据
        local queue = clone(self.waitingQueue)
        local leaved = {}
        for idx,val in pairs(queue) do
            local leftSeconds = checkint(val.leftSeconds)
            if leftSeconds >= 0 then
                leftSeconds = leftSeconds - deltaTime
                val.leftSeconds = leftSeconds
                if leftSeconds <= 0 then
                    table.remove(self.waitingQueue, idx)
                    table.insert(leaved, val)
                end
            end
        end
        --发送离开的逻辑
        if #leaved > 0 then
            for idx,val in ipairs(leaved) do
                socketMgr:SendPacket(NetCmd.CustomerLeave)
            end
        end
        self:FreshDoorAnimate()
    elseif name == APP_ENTER_BACKGROUND then
        startTime = getServerTime()
    elseif name == SIGNALNAMES.SIGNALNAME_GET_TASK then
        --任务cd结束更新任务数据
        self.datas.restaurantTasks = body.restaurantTasks
    elseif name == SIGNALNAMES.SIGNALNAME_DRAW_TASK then
        --任务领奖
        self.datas.restaurantTasks = {}
        self:UpdateTaskButtonStatus(body.nextRestaurantTaskLeftSeconds)
        uiMgr:AddDialog('common.RewardPopup', {rewards = checktable(body.rewards)})
    elseif name == RESTAURANT_TESK_PROGRESS then
        -- 任务进度更新
        if body.progress and table.nums(self.datas.restaurantTasks) > 0  then
            if self.datas.restaurantTasks[1] then
                local progress = checkint(body.progress)
                self.datas.restaurantTasks[1].progress = progress

                local targetNum = checkint(self.datas.restaurantTasks[1].targetNum)
                if progress >= targetNum then
                    self:UpdateTaskButtonStatus()
                end
                if AppFacade.GetInstance():RetrieveMediator('LobbyTaskMediator') then
                    AppFacade.GetInstance():RetrieveMediator('LobbyTaskMediator'):UpdateTaskProgress(progress, targetNum)
                end
            end
        end
    elseif name == RESTAURANT_EVENTS.EVENT_CLICK_DESK then
        --桌子的正常点击的逻辑
        PlayAudioByClickNormal()
        local AvatarFeedMediator = require( 'Game.mediator.AvatarFeedMediator')
        local delegate = AvatarFeedMediator.new({id = body.avatarId, type = body.type, data = body, friendData = body.friendData})
        AppFacade.GetInstance():RegistMediator(delegate)
    elseif name == RESTAURANT_EVENTS.EVENT_SWITCH_WAITER then
        --上了新的服务员
        local idex = checkint(body.index)
        local oldCardId = checkint(body.oldCardId) --旧服务员删除的操作
        local id = gameMgr:GetUserInfo().waiter[tostring(idex)]
        -- print('------>>> new cardId ---->>', id)
        if oldCardId then
            --删除旧位置上的人物
            if self.waiterQueue[tostring(oldCardId)] then
                local node = self.waiterQueue[tostring(oldCardId)].node
                self.waiterQueue[tostring(oldCardId)] = nil
                if node then node:removeFromParent() end
                --如果旧的人物在场上的桌子的状态为不在吃饭的时候需要改在正在吃饭的状态
                self:SwitchCustomerToEatingState(oldCardId)
            end
        end
        if id then
            local cardId = gameMgr:GetCardDataById(id).cardId
            if not self.waiterQueue[tostring(id)] then
                --计算cd时间的逻辑
                local roleNode = self.viewComponent:ConstructNpc(cardId,cardId, RoleType.Waiters, WaiterPositions[idex - 3])
                roleNode:setLocalZOrder(DragNode.OrderTags.Role_Order)
                local tempSkill = {}
                tempSkill = CommonUtils.GetBusinessSkillByCardId(cardId)
                local vigour = vigour
                if gameMgr:GetCardDataById(id) then
                    vigour = checkint(gameMgr:GetCardDataById(id).vigour) or 0
                end
                self.waiterQueue[tostring(id)] = {id = id, node = roleNode,vigour = vigour}
                -- dump(tempSkill)
                local t = {}
                if tempSkill then
                    local tbool = false
                    for i,v in ipairs(tempSkill) do
                        if checkint(v.module) == checkint(CARD_BUSINESS_SKILL_MODEL_LOBBY) then
                            for i,vv in ipairs(v.employee) do
                                if checkint(vv) == checkint(LOBBY_WAITER) then
                                    tbool = true
                                    t  = v
                                    break
                                end
                            end
                            if tbool then
                                break
                            end
                        end
                    end
                end
                self:PushRequestQueue(6007)
            end
        end
        self:UpDataNowRecipeNumAndMess()
    elseif name == RESTAURANT_EVENTS.EVENT_NEW_CUSTOM_ARRIVAL then
        --新的队列人物需要穿建的逻辑
        self:StreamPeoples(body)
    elseif name == RESTAURANT_EVENTS.EVENT_DESK_INFO then
        --得到所有的空位置的信息然后请求
        --并且有等待的人的时候才需要请求
        local emptyChair = self:GetSeatWithoutCustomer()
        local waitingLen = table.nums(self.waitingQueue)
        funLog(Logger.INFO, string.format("--->>>位置信息接口的逻辑6008--[%d]--[%d]--->>>", table.nums(emptyChair), waitingLen))
        if table.nums(emptyChair) > 0 then
            if self.deskInfoLock then
                self.deskInfoLock = false
                local keys = table.keys(emptyChair)
                socketMgr:SendPacket(NetCmd.Request_6008, {seats = table.concat(keys, ',')})
                if table.nums(self.waitingCustomNodeQueue) > 0 then
                    for name,val in pairs(self.waitingCustomNodeQueue) do
                        --停止计时
                        val.startCountDown = false
                    end
                end
            end
        else
            --桌子信息完成后判断是否建立客人
            local hasWaiter = 0
            if self.servicingQueue then
                for seatId,val in pairs(self.servicingQueue) do
                    if val.customerUuid and val.waiterId then
                        hasWaiter = 1
                        break
                    end
                end
            end
            if hasWaiter == 0 then
                funLog(Logger.INFO, "--->>>食客坐在座子上但没有服务员去服务的情况需要判断是否要服务员要去服务------->>>")
                if self.deskInfoLock then
                    self.deskInfoLock = false
                    local keys = table.keys(self.servicingQueue)
                    socketMgr:SendPacket(NetCmd.Request_6008, {seats = table.concat(keys, ',')})
                    if table.nums(self.waitingCustomNodeQueue) > 0 then
                        for name,val in pairs(self.waitingCustomNodeQueue) do
                            --停止计时
                            val.startCountDown = false
                        end
                    end
                end
            else
                funLog(Logger.INFO, "--->>>位置信息接口的没有空位置建立客流量------->>>")
                shareFacade:DispatchObservers(RESTAURANT_EVENTS.EVENT_NEW_CUSTOM_ARRIVAL)
            end
        end
    elseif name == SIGNALNAMES.SIGNALNAME_UNLOCK_AVATAR then
        --解锁某物件的逻辑
        local goodsId = checkint(body.requestData.goodsId)
        local num = checkint(body.requestData.num)
        CommonUtils.DrawRewards({{goodsId = goodsId, num = num}})
        table.insert(checktable(gameMgr:GetUserInfo().avatarCacheData.unlockAvatars), goodsId)
        --刷新列表
        local viewComponent = self.viewComponent
        local layer = require('Game.views.restaurant.BuyView').new({avatarId = goodsId,name = 'Game.views.restaurant.BuyView', tag = 12345})
        display.commonUIParams(layer, {ap = cc.p(0.5, 0.5), po = cc.p(display.width * 0.5, display.height * 0.5)})
        viewComponent:AddDialog(layer)
        local decorateView = viewComponent:getChildByTag(1345)
        if decorateView then
            --刷新列表
            decorateView:freshAvatarList()
        end
    elseif name == RESTAURANT_EVENTS.EVENT_DESTINATION then
        --到达服务地点
        local seatId = body.seatId
        local npcType = checkint(body.npcType)
        if npcType == RoleType.Visitors then
            local seatData = self:GetSeatCacheInfoBySeatId(seatId)
            -- seatData.hasCustomer = 1
            local ids = string.split(seatId, '_')
            local id = ids[1]
            self:SearchNode('DragNode', id, function(node)
                --找到节点，添加visitor
                node:AddVisitor(seatId, {visitorId = seatData.customerUuid, avatarId = seatData.customerId, npcType = RoleType.Visitors, isEating = checkint(seatData.isEating)})
            end)
            funLog(Logger.INFO, "------------->>请求服务接口的逻辑------>>>")
            local seatData = self:GetSeatCacheInfoBySeatId(seatId)
            if checkint(seatData.isEating) == EAT_STATS.WAITING then
                self:PushRequestQueue(6007)
            end
        else
            --如果是服务员走到指定的地点时
            --中间需要播放相关的喂食动画等
            local children = self.viewComponent.viewData.view:getChildren()
            local chair = {}
            for idx,val in pairs(children) do
                if val.name == 'DragNode' then
                    local id = val:getUserTag()
                    for pseatId,seatInfo in pairs(self.servicingQueue) do
                        if pseatId == seatId then
                            local tId = string.split(seatId, '_')[1]
                            if checkint(id) == checkint(tId) then
                                --找到某一张桌子
                                local visitorNode = val:getChildByName(seatId)
                                if visitorNode then
                                    --服务员走到位置时开始吃饭
                                    seatInfo.isEating = EAT_STATS.EATING --将状态变为等待的逻辑
                                    visitorNode:BeforEatAnimation()
                                end
                            end
                            break
                        end
                    end
                end
            end
            funLog(Logger.INFO, "---------------->>服务员走到指定目标点喂食结束后需人物离开与新桌子信息请求------>>>")
            --人物离开 --食客离开的动画播放
            local seatData = self:GetSeatCacheInfoBySeatId(seatId)
            if seatData and seatData.waiterId then
                local waiterInfo = self.waiterQueue[tostring(seatData.waiterId)]
                if waiterInfo then
                    local waiterNode = waiterInfo.node
                    if waiterNode then
                        waiterNode:LeaveAction(true)
                        --人物头像上要显示活力值不足的问题
                        waiterNode:VigourState()
                    end
                end
            end
        end
    elseif name == RESTAURANT_EVENTS.EVENT_SERVICE_ANIMATION then
        --食客动画播完后的桌子信息请求的逻辑，以及相关人物的离开
        funLog(Logger.INFO, "---------------->>食客动画播完后的桌子信息请求的逻辑，以及相关人物的离开------>>>")
        local seatId = body.seatId
        local expressionId = checkint(body.expressionId)--只是简单的正常人物的离开的逻辑

        local waiterId = self.servicingQueue[seatId].waiterId
        local customerUuid = checkint(self.servicingQueue[seatId].customerUuid)
        local customerId = checkint(self.servicingQueue[seatId].customerId)
        local npcNode = self.viewComponent:ConstructNpc(checkint(customerUuid),checkint(customerId), RoleType.Visitors)
        if expressionId > 0 then
            npcNode:ShowExpression(expressionId)
        end
        local ids = string.split(seatId, '_')
        local id = ids[1]
        funLog(Logger.INFO, "------------->>创建食客的临时位置点------>>>")
        --移到位置，从建立节点到上面来先清数据再人物离开
        -- local seatInfo = self:GetSeatCacheInfoBySeatId(seatId)
        self.servicingQueue[seatId] = {hasCustomer = 0}
        -- seatInfo.gold = nil
        -- seatInfo.vigour = nil
        -- seatInfo.tip = nil
        -- seatInfo.hasCustomer = 0
        -- seatInfo.customerUuid = nil
        -- seatInfo.questEventId = nil
        self:SearchNode('DragNode', id, function(targetNode)
            --服务员走到目标点去
            local tiledPos = targetNode:GetTargetDeskTile(seatId,RoleType.Visitors)
            if tiledPos then
                display.commonUIParams(npcNode, {ap = display.CENTER_BOTTOM, po = cc.p(tiledPos.w * TILED_SIZE - TILED_SIZE * 0.5, (tiledPos.h - 0.5) * TILED_SIZE)})
                local lorder = targetNode:getLocalZOrder()
                local torder = TILED_HEIGHT - tiledPos.h
                if lorder - torder <= 2 then
                    torder = lorder + 1
                else
                    torder = lorder - 1
                end
                npcNode:setLocalZOrder(torder)
                npcNode:LeaveAction(true)
            end
        end)
        --人物离开的情况调接口
        socketMgr:SendPacket(NetCmd.CustomerLeave,{seatId = seatId})
    elseif name == SIGNALNAMES.SIGNALNAME_BUY_AVATAR then
        --购买成后后的提示 刷新表示，移除购买页面
        local avatarId = checkint(body.requestData.goodsId)
        local num = checkint(body.requestData.num)
        --此时是一个增量值
        local deltaGold = checkint(body.gold) - checkint(gameMgr:GetUserInfo().gold)
        local deltaDiamond = checkint(body.diamond) - checkint(gameMgr:GetUserInfo().diamond)
        CommonUtils.DrawRewards({{goodsId = avatarId, num = num}, {goodsId = GOLD_ID, num = deltaGold}, {goodsId = DIAMOND_ID, num = deltaDiamond}})
        uiMgr:ShowInformationTips(__('购买成功~~'))
        local decorateView = self.viewComponent:getChildByName("DecorateView")
        if decorateView then
            --刷新列表
            decorateView:reloadAvatarList()
        end
        self.viewComponent:RemoveDialogByTag(12345)
    elseif name == RESTAURANT_EVENTS.EVENT_AVATAR_SHOP_SIGN_OUT then
        local decorateView = self.viewComponent:getChildByName("DecorateView")
        if decorateView then
            --刷新列表
            decorateView:reloadAvatarList()
        end

    elseif name == SIGNALNAMES.SIGNALNAME_6001 then
        --有客人到来
        local errorCode = checkint(body.data.errcode)
        if errorCode == 0 then
            local leftSeconds = checkint(body.data.data.nextCustomerArrivalLeftSeconds)
            gameMgr:GetUserInfo().avatarCacheData.nextCustomerArrivalLeftSeconds = (leftSeconds + 3)
            table.insert(self.waitingQueue, body.data.data)
            if body.data.data.seatId then
                --更新下位置信息上的缓存
                local cacheInfo = self:GetSeatCacheInfoBySeatId(body.data.data.seatId)
                if cacheInfo and checkint(cacheInfo.hasCustomer) == 1 then
                    cacheInfo.isEating = EAT_STATS.WAITING
                    shareFacade:DispatchObservers(RESTAURANT_EVENTS.EVENT_NEW_CUSTOM_ARRIVAL)
                else
                    local serverInfo = body.data.data
                    serverInfo.hasCustomer = 1
                    serverInfo.isEating = EAT_STATS.WAITING
                    self:UpdateSeatInfo(body.data.data.seatId, serverInfo)
                    shareFacade:DispatchObservers(RESTAURANT_EVENTS.EVENT_NEW_CUSTOM_ARRIVAL)
                end
            else
                --是否需要请求座位信息的逻辑
                local emptyChair = self:RetriveEmptySeatNodes()
                if table.nums(emptyChair) == 0 then
                    --防止一个人也没有的时候进行人物上场
                    funLog(Logger.INFO, "----------场上没有人存在了----------->>" .. tostring(table.nums(emptyChair)))
                    shareFacade:DispatchObservers(RESTAURANT_EVENTS.EVENT_DESK_INFO)
                end
            end
        else
            gameMgr:GetUserInfo().avatarCacheData.nextCustomerArrivalLeftSeconds = math.floor(3600 / checkint(self.datas.traffic)) + 3
            local emptyChair = self:RetriveEmptySeatNodes()
            if table.nums(emptyChair) == 0 then
                shareFacade:DispatchObservers(RESTAURANT_EVENTS.EVENT_DESK_INFO)
            end
        end
        if self.visitorUpdateFunc then
            scheduler.unscheduleGlobal(self.visitorUpdateFunc)
        end

        self.canVisitor = true
        self:FreshDoorAnimate()
    elseif name == SIGNALNAMES.SIGNALNAME_6002 then
        --离开人员时的逻辑
        local errorCode = checkint(body.data.errcode)
        if errorCode ~= 0 then
            if DEBUG > 0 then
                -- uiMgr:ShowInformationTips(tostring(body.data.errmsg))
            end
        end
        --客人离开的时候将位置上是否有客人置空
        local emptyChair = self:RetriveEmptySeatNodes()
        if table.nums(emptyChair) > 0 then --表示是在桌子上人的离开
            --需要检查桌子信息信息
            funLog(Logger.INFO, string.format('----------empty chair len >> %d', table.nums(emptyChair)))
            shareFacade:DispatchObservers(RESTAURANT_EVENTS.EVENT_DESK_INFO)
        else
            --正常的客流量
            shareFacade:DispatchObservers(RESTAURANT_EVENTS.EVENT_NEW_CUSTOM_ARRIVAL)
        end
    elseif name == SIGNALNAMES.SIGNALNAME_2027 then
        ---霸王餐需要离开的逻辑
        --取出当前在服务的人员中是霸王餐的数据让其离开
        local targetSeatInfo = nil
        for name,val in pairs(self.servicingQueue) do
            if val.questEventId and checkint(val.questEventId) > 0 then
                targetSeatInfo = val
                break
            end
        end
        if targetSeatInfo then
            --弹个提示霸王餐被打了，然后如果是霸王餐在开着，需要关掉
            uiMgr:ShowInformationTips(__('您的霸王餐被好友帮忙赶走了~~'))
            local seatId = targetSeatInfo.seatId
            local ids = string.split(seatId, '_')
            local id = ids[1]
            self:SearchNode('DragNode', id, function(targetNode)
                --否则服务员直接变成吃饭的状态的逻辑
                local visitorNode = targetNode:getChildByName(seatId)
                if visitorNode then
                    visitorNode:AfterEatAnimation()
                end
            end)

            local feedAvatarMediator = shareFacade:RetrieveMediator('AvatarFeedMediator')
            if feedAvatarMediator and checkint(feedAvatarMediator.type) == 3 then
                -- 如果霸王餐的页面存存时需要移除
                feedAvatarMediator:VisitorIsLeave(1) ---当前对应的霸王餐已经离开
            end
        end
    elseif name == SGL.SIGNALNAME_CLEAN_ALL_AVATAR then
        local cleanList = checktable(body.cleanList)
        local errorCode = checkint(body.errcode)
        if errorCode == 0 then
            for _, avatarData in ipairs(cleanList) do
                local goodsId    = avatarData.goodsId
                local avatarConf = CommonUtils.GetConfigNoParser("restaurant", 'avatar', goodsId) or {}
                local avatarType = checkint(avatarConf.mainType)
                self:removeAvatar_({
                    isRepeat  = avatarType == RESTAURANT_AVATAR_TYPE.CEILING,
                    goodsUuid = avatarData.goodsUuid,
                    goodsId   = avatarData.goodsId,
                })
            end
            local decorateView = self.viewComponent:getChildByName('DecorateView')
            if self.newDragId and decorateView then
                self:removeAvatar_({
                    goodsUuid = self.newDragId,
                    goodsId   = decorateView:getSelectedAvatarId(),
                })
            end
            -- self.newDragId = nil
        else
            if DEBUG > 0 then
                uiMgr:ShowInformationTips(tostring(body.errmsg))
            end
        end
    elseif name == SIGNALNAMES.SIGNALNAME_6004 then
        --添加一个物品上去的逻辑
        local id = checkint(body.data.data.goodsUuid)
        local errorCode = checkint(body.data.errcode)
        if errorCode == 0 then
            if checkbool(self.handleData.fix) then
                --固定步件的更换
                local goodsId = checkint(self.handleData.goodsId)
                local curCate = checkint(self.handleData.type)
                local ogoodsId, ngoodsId = self.viewComponent:ReplaceFixParts(curCate, goodsId)
                --要清除旧的再放上新的在缓存中去
                local locations = checktable(gameMgr.userInfo.avatarCacheData.location)
                for id,val in pairs(locations) do
                    if checkint(val.goodsId) == ogoodsId then
                        locations[tostring(id)] = nil
                        break
                    end
                end
                local avatarLocationConfig = CommonUtils.GetConfigNoParser('restaurant', 'avatarLocation', goodsId)
                if avatarLocationConfig.location then
                    local point = string.split(avatarLocationConfig.location[1], ',')
                    --添加新的物品
                    local tx, ty = point[1],point[2]
                    locations[tostring(id)] = {id = id, goodsId = goodsId,location = {x = tx, y = ty}}
                    socketMgr:SendPacket(NetCmd.RestuarantMoveGoods,{goodsUuid = id, goodsId = goodsId,x = tx, y = ty})

                    --是否刷新底部装饰面板的数量的逻辑
                    local decorateView = self.viewComponent:getChildByName('DecorateView')
                    if decorateView then
                        decorateView:freshAvatarList()
                    end
                end

            else
                --可拖动的步件添加节点到上面去
                if self.newDragId then
                    local testNode = self.viewComponent.viewData.view:getChildByName('HandleNode')
                    if testNode then testNode:VisibleState(false) end
                    --如果之前已经存在一个部件，将其移除，再添加新的点
                    local children = self.viewComponent.viewData.view:getChildren()
                    for idx,val in ipairs(children) do
                        if val.name and val.name == 'DragNode' and val:getUserTag() == self.newDragId then
                            val:removeFromParent()
                            break
                        end
                    end
                    self.newDragId = nil
                    if self.curNode then
                        self.curNode.upload = false --恢复可点
                        self.curNode = nil
                    end
                end
                --移除拖动界面的页面
                local goodsId = checkint(self.handleData.goodsId)
                self.newDragId = id --新上场的拖动部件的id暂存下
                self:AddTempAvatar(id, goodsId)
            end
        else
            -- if DEBUG > 0 then
                -- uiMgr:ShowInformationTips(tostring(body.data.errmsg))
            -- end
        end
    elseif name == SIGNALNAMES.SIGNALNAME_6005 then
        --撤下道具
        local errorCode = checkint(body.data.errcode)
        if errorCode == 0 then
            -- dump(self.handleData)
            self:removeAvatar_({
                isRepeat  = self.handleData.fix,
                goodsUuid = self.handleData.id,
                goodsId   = self.handleData.goodsId,
            })
        else
            -- if DEBUG > 0 then
                -- uiMgr:ShowInformationTips(tostring(body.data.errmsg))
            -- end
        end
    elseif name == SIGNALNAMES.SIGNALNAME_6006 then
        --移动道具
        -- dump(self.handleData)
        local errorCode = checkint(body.data.errcode)
        if errorCode == 0 then
            --如果是新上场的置空临时缓存的逻辑
            --成功后引导才向下走一步
            GuideUtils.DispatchStepEvent()
            if not self.handleData.fix then
                --固定部件不作处理
                local id = checkint(self.handleData.id)
                local avatarId = checkint(self.handleData.goodsId)
                local tx = checkint(self.handleData.x)
                local ty = checkint(self.handleData.y)
                gameMgr:UpdateAvatarLocalLocations({id = id, goodsId = avatarId, x = tx, y = ty})

                local avatarLocationConfig = CommonUtils.GetConfigNoParser('restaurant', 'avatarLocation', avatarId)
                if checkint(avatarLocationConfig.additionNum) > 0 then
                    for i=1,checkint(avatarLocationConfig.additionNum) do
                        --拿到seatId
                        local seatId = string.format('%d_%d', checkint(id), i)
                        self:UpdateSeatInfo(seatId, {hasCustomer = 0}) --添加新出现的空位置的缓存
                    end
                end

                self:UpdateAllBlocks()

                if self.curNode then
                    self.curNode.upload = false --恢复可点
                    self.curNode = nil
                end
                self.newDragId = nil
                local node = self.viewComponent.viewData.view:getChildByName('HandleNode')
                if node then node:VisibleState(false) end

                self:HiddenAllDirectionView()

                --是否刷新底部装饰面板的数量的逻辑
                local decorateView = self.viewComponent:getChildByName('DecorateView')
                if decorateView then
                    decorateView:setSelectedAvatarId(0)
                    decorateView:freshAvatarList()
                end
            end
        else
            -- if DEBUG > 0 then
                -- uiMgr:ShowInformationTips(tostring(body.data.errmsg))
            -- end
        end
    elseif name == SIGNALNAMES.SIGNALNAME_6007 then
        --招待客人的请求
        local errorCode = checkint(body.data.errcode)
        if DEBUG > 0 then
            dump(body.data)
        end
        if errorCode == 0 then
            -- 更新数据
            local isUpdate = false -- 是否更新
            if next(self.datas.bill) ~= nil then
                for i,v in ipairs(self.datas.bill) do
                    if checkint(v.customerId) == checkint(body.data.data.customerId) then
                        v.gold = v.gold + body.data.data.gold - gameMgr:GetUserInfo().gold
                        v.popularity = v.popularity + body.data.data.popularity - gameMgr:GetUserInfo().popularity
                        v.sellNum = v.sellNum + body.data.data.recipeNum
                        isUpdate = true
                        break
                    end
                end
            else
                table.insert(self.datas.bill, {
                    customerId = body.data.data.customerId,
                    gold       = body.data.data.gold - gameMgr:GetUserInfo().gold,
                    popularity = body.data.data.popularity - gameMgr:GetUserInfo().popularity,
                    sellNum    = body.data.data.recipeNum
                })
                isUpdate = true
            end
            if not isUpdate then
                table.insert(self.datas.bill, {
                    customerId = body.data.data.customerId,
                    gold       = body.data.data.gold - gameMgr:GetUserInfo().gold,
                    popularity = body.data.data.popularity - gameMgr:GetUserInfo().popularity,
                    sellNum    = body.data.data.recipeNum
                })
            end
            self.datas.todayPopularity = self.datas.todayPopularity + checkint(body.data.data.popularity - gameMgr:GetUserInfo().popularity)
            gameMgr:GetUserInfo().avatarCacheData.todayPopularity = self.datas.todayPopularity
            gameMgr:GetUserInfo().avatarCacheData.bill = self.datas.bill
            local data = body.data.data

            local deltaGold = checkint(data.gold) - checkint(gameMgr:GetUserInfo().gold)
            local deltaPoputy = checkint(data.popularity) - checkint(gameMgr:GetUserInfo().popularity)
            local deltaTip = checkint(data.tip) - checkint(gameMgr:GetUserInfo().tip)
            local rewards = {{goodsId = GOLD_ID, num = deltaGold}, {goodsId = POPULARITY_ID, num = deltaPoputy}, {goodsId = TIPPING_ID, num = deltaTip}}
            if data.activityRewards then
                for i,v in ipairs(data.activityRewards) do
                    table.insert(rewards, v)
                end
            end
            CommonUtils.DrawRewards(rewards)
            local originNum = checkint(gameMgr:GetUserInfo().avatarCacheData.recipe[tostring(data.recipeId)])
            local targetNum = originNum - checkint(data.recipeNum)
            data.deltaGold = deltaGold
            data.deltaTip = deltaTip
            data.isEating  = EAT_STATS.SERVICING --服务员将要去服务的状态的逻辑
            if targetNum <= 0 then
                --删除菜单的缓存数据
                gameMgr:GetUserInfo().avatarCacheData.recipe[tostring(data.recipeId)] = nil
            elseif checkint(self.datas.mangerId) <= 0 then
                -- 没有店长时  才减
                gameMgr:GetUserInfo().avatarCacheData.recipe[tostring(data.recipeId)] = originNum - checkint(data.recipeNum)
            end

            self.datas.recipe[tostring(data.recipeId)] = gameMgr:GetUserInfo().avatarCacheData.recipe[tostring(data.recipeId)]

            --更新服务员的新鲜度
            self:UpdateSeatInfo(data.seatId, data)
            -- dump(self:GetSeatCacheInfoBySeatId(data.seatId))
            local waiterId = checkint(data.waiterId)
            gameMgr:UpdateCardDataById(waiterId, {vigour = checkint(data.vigour)})
            -- 有店长时 recipeNum 置为0  没有时  正常扣除
            AppFacade.GetInstance():DispatchObservers(EVENT_EAT_FOODS,{recipeId = data.recipeId,recipeNum = checkint(self.datas.mangerId) <= 0 and data.recipeNum or 0})
            local waiterInfo = self.waiterQueue[tostring(waiterId)] or {}
            waiterInfo.vigour = checkint(data.vigour)
            self:UpDataNowRecipeNumAndMess()
            --将指定的位置信息标记为需要移除的状态，防止从装修切换过来桌子上的人还在的问题
            local seatId = data.seatId
            local ids = string.split(seatId, '_')
            local id = ids[1]
            self:SearchNode('DragNode', id, function(targetNode)
                --标记指定的位置上的人为可移除状态
                funLog(Logger.INFO, '-----------------------<< 查找到座位的id-->>>' .. tostring(seatId))
                local isInChair = targetNode:MarkChair(seatId)
                if isInChair then
                    funLog(Logger.INFO, '-----------------------<< 查找到座位的id--实际确未存在-->>>' .. tostring(seatId))
                    local tiledPos = targetNode:GetTargetDeskTile(seatId,RoleType.Waiters)
                    if tiledPos and waiterInfo.node and (not tolua.isnull(waiterInfo.node)) then
                        --服务员需要到新的位置去服务其他人员
                        waiterInfo.node:SwitchToNewCustomer() --停止动作
                        waiterInfo.node:UpdateDestination(cc.p(tiledPos.w * TILED_SIZE - TILED_SIZE * 0.5, (tiledPos.h - 0.5) * TILED_SIZE), seatId)
                    else
                        --否则服务员直接变成吃饭的状态的逻辑
                        local visitorNode = targetNode:getChildByName(seatId)
                        if visitorNode then
                            -- self:UpdateSeatInfo(seatId, {isEating = EAT_STATS.EATING})
                            visitorNode:BeforEatAnimation()
                        end
                    end
                    --某瞬间要走去又被移除
                    self:UpdateSeatInfo(seatId, {isEating = EAT_STATS.EATING})
                end
            end)
            -- 刷新信息页面
            local mediator = AppFacade.GetInstance():RetrieveMediator('LobbyInformationMediator')
            if mediator and mediator.showLayer and mediator.showLayer['1001'] then
                mediator.showLayer['1001']:RefreshUI()
            end
        else
            -- if DEBUG > 0 then
                -- uiMgr:ShowInformationTips(tostring(body.data.errmsg))
            -- end
        end
        if self.serviceUpdateFunc then
            scheduler.unscheduleGlobal(self.serviceUpdateFunc)
        end
        self.canServiceLock = true --可以进行下一个请求的逻辑
    elseif name == SIGNALNAMES.SIGNALNAME_6008 then
        --桌子信息
        local errorCode = checkint(body.data.errcode)
        if errorCode == 0 then
            local waitingQueueIndex = 1
            for idx,val in pairs(body.data.data) do
                if val.customerUuid and val.seatId then
                    local waitItem = self.waitingQueue[waitingQueueIndex]
                    if waitItem then
                        --存在某一个人时
                        table.merge(val, waitItem)
                        self.waitingQueue[waitingQueueIndex] = val --将等待数据更新到最新的点
                    end
                    val.hasCustomer = 1 --表示存在人物的逻辑
                    val.isEating = EAT_STATS.WAITING --等待吃饭服务的逻辑
                    self:UpdateSeatInfo(val.seatId, val)
                    waitingQueueIndex = waitingQueueIndex + 1
                end
            end
            if waitingQueueIndex > 1 then
                --stream people
                self:StreamPeoples() --检查人走过去的逻辑
            end
        else
            -- if DEBUG > 0 then
                -- uiMgr:ShowInformationTips(tostring(body.data.errmsg))
            -- end
        end
        self.deskInfoLock = true --可以进行下一次请求了
    elseif name == SIGNALNAMES.SIGNALNAME_CANCEL_AVATAR_QUEST then
        --取消了霸王餐的逻辑
        local seatId = body.requestData.seatId
        local ids = string.split(seatId, '_')
        local id = ids[1]
        local customerUuid = checkint(self.servicingQueue[seatId].customerUuid)
        local customerId = checkint(self.servicingQueue[seatId].customerId)
        --移除界面
        AppFacade.GetInstance():UnRegsitMediator('AvatarFeedMediator')
        self:SearchNode('DragNode', id, function(targetNode)
            --服务员离开的逻辑
            targetNode:removeChildByName(seatId) --移除桌子上的人
            -- local npcNode = self.viewComponent:ConstructNpc(checkint(customerUuid),checkint(customerId), RoleType.Visitors)
            local tiledPos = targetNode:GetTargetDeskTile(seatId,RoleType.Visitors)
            if tiledPos then
                local npcNode = self.viewComponent:ConstructNpc(checkint(customerUuid),checkint(customerId), RoleType.Visitors, tiledPos, true)
                -- display.commonUIParams(npcNode, {ap = display.CENTER_BOTTOM, po = cc.p(tiledPos.w * TILED_SIZE - TILED_SIZE * 0.5, (tiledPos.h - 0.5) * TILED_SIZE)})
                local lorder = targetNode:getLocalZOrder()
                local torder = TILED_HEIGHT - tiledPos.h
                if lorder - torder <= 2 then
                    torder = lorder + 1
                else
                    torder = lorder - 1
                end
                --清除缓存的逻辑
                self.servicingQueue[seatId] = {hasCustomer = 0}
                npcNode:setLocalZOrder(torder)
                npcNode:LeaveAction(true)
                -- npcNode:UpdateDestination(cc.p(256,16 + 32 * 2), seatId)
            end
        end)
        --发送桌子信息请求
        AppFacade.GetInstance():DispatchObservers(RESTAURANT_EVENTS.EVENT_DESK_INFO)
    elseif name == SIGNALNAMES.SIGNALNAME_HOME_AVATAR then
        --主界面请求各应的逻辑
        if checkint(body.showCaptcha) == 1 then
            AppFacade.GetInstance():DispatchSignal(POST.CAPTCHA_HOME.cmdName)
        end
        self.datas = checktable(body)
        self:HomeAction()
        self:UpdateScheduleMap()
        app:DispatchObservers(RESTAURANT_EVENTS.EVENT_AVARAR_DATA_SYS , { recipeCooking =  self.datas.recipeCooking  ,  recipe = self.datas.recipe})
    elseif name == AvatarScene_ChangeCenterContainer then
        local body = signal:GetBody()
        if body == "show" then
            self:GetViewComponent():getChildByName('TOP_LAYOUT'):setVisible(true)
            uiMgr:UpdatePurchageNodeState(false)
        elseif body == 'hide' then
            self:GetViewComponent():getChildByName('TOP_LAYOUT'):setVisible(false)
        end
    elseif name == SIGNALNAMES.Friend_REMOVE_BUGAT_Callback then
        -- 虫子区域ID, 为0表示全部清除
        local bugAreaId = checkint(body.bugId)
        if bugAreaId > 0 then
            self:removeBugAt(bugAreaId)
        else
            for i = #checktable(self.bugQueue), 1, -1 do
                self:removeBugAt(checktable(self.bugQueue)[i])
            end
        end
    -- elseif name == SIGNALNAMES.SIGNALNAME_FRIEND_AVATAR_STATE then
    --     local friendId    = checkint(body.friendId)
    --     local commandId   = checkint(body.cmd)
    --     local commandData = checktable(body.cmdData)
    --     local bugId       = checkint(commandData.bugId)

    --     if friendId == checkint(gameMgr:GetUserInfo().playerId) then

    --         -- 好友帮忙清除了虫子
    --         if commandId == NetCmd.RequestRestaurantBugClear then

    --             -- 虫子区域ID, 为0表示全部清除
    --             local bugAreaId = checkint(commandData.bugId)
    --             if bugAreaId > 0 then
    --                 self:removeBugAt(bugAreaId)
    --             else
    --                 for i = #checktable(self.bugQueue), 1, -1 do
    --                     self:removeBugAt(checktable(self.bugQueue)[i])
    --                 end
    --             end
    --         end
    --     end

    --     -- 更新好友列表数据
    --     self:updateFriendListState(commandId, friendId, bugId)

    elseif name == FRIEND_UPDATE_LOBBY_FRIEND_BTN_STATE then
        local showBtn = true
        if body and body.showBtn ~= nil then
            showBtn = checkbool(body.showBtn)
        end
        self:GetViewComponent().viewData.friendBtn:setVisible(showBtn and CommonUtils.GetModuleAvailable(MODULE_SWITCH.FRIEND))
        -- self:GetViewComponent().viewData.chatBtn:setVisible(showBtn)


    elseif name == SIGNALNAMES.Lobby_EmployeeSwitch_Callback then
        if not AppFacade.GetInstance():RetrieveMediator('LobbyPeopleManagementMediator') then
            local errorCode = checkint(checktable(body.data).errcode)
            --服务员直接去冰场的逻辑，长连接未出错的情况下才执行
            if errorCode == 0 then
                if self.clickCardId then
					if body.data.data and body.data.data.icePlaceId then
						AppFacade.GetInstance():DispatchSignal(COMMANDS.COMMANDS_ICEPLACE, {icePlaceId = body.data.data.icePlaceId, playerCardId = self.clickCardId})
					end
                end
            end
        end
    elseif name == SIGNALNAMES.IcePlace_AddCard_Callback then
        if not signal:GetBody().errcode then
            for k,v in pairs(gameMgr:GetUserInfo().employee) do
                local typee =  CommonUtils.GetConfigNoParser('restaurant','employee',k).type
                local waiterId = checkint(signal:GetBody().newPlayerCard.playerCardId)
                if typee == LOBBY_WAITER and checkint(v) == waiterId then
                    gameMgr:DelCardOnePlace( waiterId, CARDPLACE.PLACE_ASSISTANT)
                    gameMgr:SetCardPlace({}, {{id = waiterId}}, CARDPLACE.PLACE_ICE_ROOM)
                    if checktable(signal:GetBody().oldPlayerCard).playerCardId then
                        local oldCardId = checkint(signal:GetBody().oldPlayerCard.playerCardId)
                        local ovigour = checkint(signal:GetBody().oldPlayerCard.vigour)
                        gameMgr:UpdateCardDataById(oldCardId, {vigour = ovigour})
                        gameMgr:DelCardOnePlace( oldCardId ,CARDPLACE.PLACE_ICE_ROOM)
                    end
                    gameMgr:GetUserInfo().waiter[k] = nil
                    gameMgr:GetUserInfo().employee[k] = nil
                    AppFacade.GetInstance():DispatchObservers(RESTAURANT_EVENTS.EVENT_SWITCH_WAITER,{index = k,oldCardId = signal:GetBody().newPlayerCard.playerCardId})
                    AppFacade.GetInstance():UnRegsitMediator("AvatarFeedMediator")
                    uiMgr:ShowInformationTips(__('添加成功'))
                    break
                end
            end
        end
    elseif name == 'SHARE_BUTTON_EVENT' then
        --分享按钮事件触发
        self:ShareButtonAction()
    elseif name == 'SHARE_BUTTON_BACK_EVENT' then
        local topView = self.viewComponent:getChildByName('TOP_LAYOUT')
        if topView then topView:setVisible(true) end
        self.viewComponent.viewData.shopBtn:setVisible(true and CommonUtils.GetModuleAvailable(MODULE_SWITCH.SHOP))
        self.viewComponent.viewData.shareView:setVisible(true)
        self.viewComponent.viewData.friendBtn:setVisible(true and CommonUtils.GetModuleAvailable(MODULE_SWITCH.FRIEND))
        -- self.viewComponent.viewData.chatBtn:setVisible(true)

        local decorateView = self.viewComponent:getChildByName('DecorateView')
        if decorateView then
            decorateView:setVisible(true)
        end
        local children = self.viewComponent.viewData.view:getChildren()
        for idx,val in ipairs(children) do
            if val.name == 'DragNode' then
                val.canTouch = true
            end
        end
        local node = self.viewComponent:getChildByName('ShareNode')
        if node then
            node:runAction(cc.Spawn:create(cc.FadeOut:create(0.15),cc.RemoveSelf:create()))
        end
    elseif name == COUNT_DOWN_ACTION then
        local tag = checkint(body.tag)

        if tag == RemindTag.LOBBY_FESTIVAL_ACTIVITY then
            local seconds  = checkint(body.countdown)
            -- dump(self.avatarTopBtns, '22avatarTopBtns')
            local topBtn   = self.avatarTopBtns[tostring(tag)]
            if topBtn == nil then
                return
            end
            local countdownLayout = topBtn:getChildByName('countdownLayout')
            countdownLayout:setVisible(true)
            local countdownLabel  = countdownLayout:getChildByName('countdownLabel')

            local formatTime = function(seconds)
                local c = nil
                if seconds >= 86400 then
                    local day = math.floor(seconds/86400)
                    c = string.fmt(__('_num1_天'), {['_num1_'] = tostring(day)})
                else
                    local hour   = math.floor(seconds / 3600)
                    local minute = math.floor((seconds - hour*3600) / 60)
                    local sec    = (seconds - hour*3600 - minute*60)
                    c = string.format("%.2d:%.2d:%.2d", hour, minute, sec)
                end
                return c
            end

            display.commonLabelParams(countdownLabel, {text = formatTime(seconds)})

        elseif tag == RemindTag.LOBBY_FESTIVAL_ACTIVITY_PREVIEW  then
        elseif tag == RemindTag.LOBBY_AGENT_SHOPOWNER  then
            local seconds  = checkint(body.countdown)
            -- dump(self.avatarTopBtns, '22avatarTopBtns')
            local topBtn   = self.avatarTopBtns[tostring(tag)]
            if topBtn == nil then return end
            local countdownLayout = topBtn:getChildByName('countdownLayout')

            if countdownLayout then
                local countdownLabel  = countdownLayout:getChildByName('countdownLabel')
                countdownLayout:setVisible(true)
                display.commonLabelParams(countdownLabel, {text = CommonUtils.getTimeFormatByType(seconds, 2)})
            end
            if seconds <= 0 then
                self.datas.mangerId = 0
                gameMgr:GetUserInfo().avatarCacheData.mangerId = 0
                self:StartAgentShopownerCountDown(seconds)
                self:UpdateAvatarTopBtnLayer()
            end
        end
    elseif name == LOBBY_FESTIVAL_ACTIVITY_END then
        self:UpdateAvatarTopBtnLayer()
    elseif name == LOBBY_FESTIVAL_ACTIVITY_PREVIEW_END then
        self:UpdateAvatarTopBtnLayer()
    elseif name == POST.RESTAURANT_AGENT_SHOPOWNER.sglName then
        self.datas.mangerId = checkint(body.requestData.managerId)
        gameMgr:GetUserInfo().avatarCacheData.mangerId = self.datas.mangerId
        -- 1. 移除所有 虫子
        for i = #checktable(self.bugQueue), 1, -1 do
            self:removeBugAt(checktable(self.bugQueue)[i])
        end

        -- 2. 移除所有霸王餐
        for seatId,val in pairs(self.servicingQueue) do
            if val.questEventId then
                self:GetFacade():DispatchObservers(SIGNALNAMES.SIGNALNAME_CANCEL_AVATAR_QUEST, {requestData = {seatId = seatId}})
            end
        end

        -- 3. update top ui
        local RESTAURANT_MANAGER_CONF = CommonUtils.GetConfigAllMess('manager', 'restaurant')
        local data = nil
        for i,v in pairs(RESTAURANT_MANAGER_CONF) do
            if checkint(v.id) == self.datas.mangerId then
                data = v
                break
            end
        end

        if data then
            local time = checkint(data.time)
            self:StartAgentShopownerCountDown(time)
            self:UpdateAvatarTopBtnLayer()
        end
    elseif name == POST.RESTAURANT_CANCEL_AGENT_SHOPOWNER.sglName then
        self.datas.mangerId = 0
        gameMgr:GetUserInfo().avatarCacheData.mangerId = 0
        self:StartAgentShopownerCountDown(0)
        self:UpdateAvatarTopBtnLayer()

    elseif name == 'CLOSE_TEAM_FORMATION' then
        -- 关闭编队界面
		self:GetFacade():DispatchObservers(TeamFormationScene_ChangeCenterContainer)

    elseif name == SGL.RESTAURANT_APPLY_SUIT_RESULT then
        local decorateView = self.viewComponent:getChildByName('decorateView')
        if decorateView then
            decorateView:freshAvatarList()
        end

        -- 更新椅子数据
        for _, avatarData in pairs(self.houseLocation) do
            local avatarId = checkint(avatarData.goodsId)
            local avatarLocationConfig = CommonUtils.GetConfigNoParser('restaurant', 'avatarLocation', avatarId)
            if checkint(avatarLocationConfig.additionNum) > 0 then
                for i=1,checkint(avatarLocationConfig.additionNum) do
                    local seatId = string.format('%d_%d', checkint(avatarData.id), i)
                    self:UpdateSeatInfo(seatId, {hasCustomer = 0}) --添加新出现的空位置的缓存
                end
            end
        end


        -- TODO 有位不进来是为啥
    
        -- self:UpdateAllBlocks()
        -- self:HiddenAllDirectionView()

    elseif name == SGL.RESTAURANT_PREVIEW_SUIT then
        for _, avatarData in pairs(self.houseLocation or {}) do
            local goodsId    = avatarData.goodsId
            local avatarConf = CommonUtils.GetConfigNoParser("restaurant", 'avatar', goodsId) or {}
            local avatarType = checkint(avatarConf.mainType)
            self:removeAvatar_({
                isRepeat  = avatarType == RESTAURANT_AVATAR_TYPE.CEILING,
                goodsUuid = avatarData.id,
                goodsId   = avatarData.goodsId,
                isRetain  = true,
            })
        end


        -- refresh data
        if app.restaurantMgr:getHousePresetSuitId() > 0 then
            self.houseLocation = app.restaurantMgr:getSuitDataBySuitId(app.restaurantMgr:getHousePresetSuitId())
        else
            self.houseLocation = app.gameMgr:GetUserInfo().avatarCacheData.location
        end

        -- refresh view
        self.viewComponent:InitViews(self.houseLocation)
    end
end


--[[
--分享事件的功能
--]]
function AvatarMediator:ShareButtonAction()
    --最上方的条，小费商店，分享按钮不显示，装修页面
    local topView = self.viewComponent:getChildByName('TOP_LAYOUT')
    if topView then topView:setVisible(false) end
    self.viewComponent.viewData.shopBtn:setVisible(not CommonUtils.GetModuleAvailable(MODULE_SWITCH.SHOP))
    self.viewComponent.viewData.shareView:setVisible(false)
    self.viewComponent.viewData.friendBtn:setVisible(not CommonUtils.GetModuleAvailable(MODULE_SWITCH.FRIEND))
    if self.viewComponent.viewData.chatBtn then self.viewComponent.viewData.chatBtn:setVisible(false) end
    self.viewComponent.viewData.avatarTopBtnLayer:setVisible(false)

    local decorateView = self.viewComponent:getChildByName('DecorateView')
    if decorateView then
        decorateView:setVisible(false)
    end
    local children = self.viewComponent.viewData.view:getChildren()
    for idx,val in ipairs(children) do
        if val.name == 'DragNode' then
            val.canTouch = false
        end
    end
    --添加分享层
    local node = self.viewComponent:getChildByName('ShareNode')
    if not node then
        local ShareNode = require('common.ShareNode')
        node = ShareNode.new({visitNode = self.viewComponent})
        node:setName('ShareNode')
        display.commonUIParams(node, {po = display.center})
        self.viewComponent:addChild(node,100)
    end
end

--[[
--装修时返回的请求回调的逻辑
--]]
function AvatarMediator:HomeAction()
    gameMgr:GetUserInfo().avatarCacheData = checktable(self.datas)
    self.waitingCustomNodeQueue = {} --门口等待的客人临时节点
    self.waitingQueue = {} --等待的顾客数据的逻辑
    self.servicingQueue = {} --正位置上的数据信息{[seatId]= data}
    self.houseLocation = gameMgr:GetUserInfo().avatarCacheData.location

    for idx,val in pairs(checktable(self.datas.customerWaitingSeat)) do
        table.insert(self.waitingQueue, val) --进入队列的数据
    end
    for key,val in pairs(checktable(self.datas.seat)) do
        if val.customerUuid then
            --表示座位上有人存在的逻辑
            val.hasCustomer = 1 --存在人的逻辑
        else
            val.hasCustomer = 0 --不存在食客的逻辑
        end
        val.seatId = key
        self.servicingQueue[tostring(key)] = val --餐桌信息
    end
    for name,val in pairs(checktable(self.datas.waiter)) do
        --更新下服务员vigour
        local waiterInfo = self.waiterQueue[tostring(name)]
        if waiterInfo  and  type(waiterInfo) == 'table' then
            table.merge(waiterInfo, val)
            gameMgr:UpdateCardDataById(checkint(name), {vigour = checkint(val.vigour)})
        end

    end

    --判断相关数据的更新态,重新创建各位置的人物
    for seatId,val in pairs(self.servicingQueue) do
        if checkint(val.hasCustomer) == 1 then
            local ids = string.split(seatId, '_')
            local id = ids[1]
            self:SearchNode('DragNode', id, function(node)
                --找到节点，添加visitor
                node:AddVisitor(seatId, {visitorId = val.customerUuid, avatarId = val.customerId, npcType = RoleType.Visitors, isEating = checkint(val.isEating)})
            end)
        end
        if checkint(val.isEating) == EAT_STATS.WAITING and (not questEventId) then
            --等待服务
            self:PushRequestQueue(6007)
        end
    end
    --更新剩余时间的状态
    -- if gameMgr:GetUserInfo().avatarCacheData.events and table.nums(gameMgr:GetUserInfo().avatarCacheData.events) > 0 then
    --     local head = gameMgr:GetUserInfo().avatarCacheData.events[1]
    --     if head then
    --         local eventInfo = CommonUtils.GetConfigNoParser('restaurant', 'event', head.eventId)
    --         if eventInfo and eventInfo.name then
    --             self.viewComponent.viewData.eventButton:setText(eventInfo.name)
    --             self.viewComponent.viewData.eventTimeLabel:setString(string.formattedTime(checkint(head.leftSeconds), __('剩%02i:%02i:%02i结束')))
    --         end
    --     end
    -- end
    if table.nums(self.datas.offlineRewards) > 0 and table.nums(self.datas.offlineRecipe) > 0 then

        local recipes = {}
        for name,val in pairs(self.datas.offlineRecipe) do
            table.insert(recipes, {goodsId = checkint(name), num = checkint(val)})
        end
        self:GetViewComponent():runAction(cc.Sequence:create(cc.DelayTime:create(0.2), cc.CallFunc:create(function()
            local offlineView = require('common.AvatarPopUpReward').new({rewardData = self.datas.offlineRewards ,consumeData = recipes, msg = __('在您离开的这段时间获得了')})
            display.commonUIParams(offlineView, {po = display.center})
            offlineView:setName('offlineView')
            self:GetViewComponent():addChild(offlineView, 1000)
        end)))
    end

    self.canServiceLock = true --当前是否可上菜的锁
    self.deskInfoLock = true --是否可以请求餐桌信息
    self.canVisitor = true --是否可请求食客
    loopStartTime = getServerTime()
    self.isStop = false
    --新的客人到来的逻辑
    shareFacade:DispatchObservers(RESTAURANT_EVENTS.EVENT_NEW_CUSTOM_ARRIVAL)
end
--[[
-- 更新所有可行走路径的信息
--]]
function AvatarMediator:UpdateAllBlocks()
    for name,val in pairs(self.blocks) do
        val.couldCross = true
        if val.h > self.maxTileHeight then
            val.couldCross = false
        elseif val.h < self.minTileHeight then
            val.couldCross = false
        end
    end
    local children  = self.viewComponent.viewData.view:getChildren()
    local locations = self.houseLocation or {}
    for idx,val in ipairs(children) do
        if val.name and val.name == 'DragNode' then
            --更新可走动的点的逻辑
            local collisionWidth = checkint(val.collisionWidth)
            local collisionHeight = checkint(val.collisionHeight)
            -- local offsetP = string.split(val.configInfo.offset[1],',')
            local tt = locations[tostring(val.id)]
            if tt then
                local nblocks = self:ConvertRectAreaToTileds(cc.rect(tt.location.x ,tt.location.y ,collisionWidth, collisionHeight))
                self:UpdateTileState(nblocks, false)
            end
        end
    end
    if DEBUG > 0 then
        -- self:DrawBlocks()
    end
end

--[[
--获取空闲未服务的服务员的逻辑
--]]
function AvatarMediator:GetIdleWaiter()
    local idleWaiters = {}
    for id,val in pairs(self.waiterQueue) do
        if val.node and (not tolua.isnull(val.node)) then
            local vigour = checkint(gameMgr:GetCardDataById(id).vigour)
            -- 有代理店长时 无视 服务员有没有新鲜度
            if (checkint(self.datas.mangerId) > 0 or vigour > 0) and checkint(val.node.isServing) == 0 then
                table.insert(idleWaiters, {id = id, val = val})
            end
        end
    end

    local len = table.nums(idleWaiters)
    if len > 0 then
        --取到可用的服务员的数量
        local mode = self.serveNo % len
        if mode == 0 then mode = len end
        self.serveNo = self.serveNo + 1
        return idleWaiters[mode]
    end
end

--[[
--将指定的服务对应的服务员状态变成吃饭的状态
--]]
function AvatarMediator:SwitchCustomerToEatingState(waiterId)
    for name,val in pairs(self.servicingQueue) do
        if checkint(val.waiterId) == checkint(waiterId) then
            if val.customerUuid and val.seatId and val.isEating and checkint(val.hasCustomer) == 1 then
                local seatId = tostring(val.seatId)
                local ids = string.split(seatId, '_')
                local id = ids[1]
                self:SearchNode('DragNode', id, function(targetNode)
                    local visitorNode = targetNode:getChildByName(seatId)
                    if visitorNode then
                        val.isEating = EAT_STATS.EATING --将状态变为等待的逻辑
                        visitorNode:BeforEatAnimation()
                    end
                end)
            end
        end
    end
end
--[[
--判断是否当前服务员是否可更换的状态
--]]
function AvatarMediator:CheckWaiterCanSwitch(id)
    local canSwitch = 1
    if self.waiterQueue[tostring(id)] then
        --如果存在这个服务员
        local val = self.waiterQueue[tostring(id)]
        if val.node and (not tolua.isnull(val.node)) then
            if checkint(val.node.isServing) == 1 then
                --当前服务员正在服务客人
                canSwitch = 0
            end
        end
    end
    return canSwitch
end
--[[
--上菜的处理逻辑
--@datas options
--]]
function AvatarMediator:UpTableDish()
    --如果能够上菜时，直接进行上菜的请求，如果条件不满足时人物去掉定点等
    local haveWaiter = 0
    local haveRecipe = 0
    --判断是否存在服务员的逻辑
    local len = table.nums(self.waiterQueue)
    local serviceNum = 0
    for id,val in pairs(self.waiterQueue) do
        local vigour = checkint(gameMgr:GetCardDataById(id).vigour)
        -- 有代理店长时 无视 服务员有没有新鲜度
        if (checkint(self.datas.mangerId) > 0 or vigour > 0) and (not tolua.isnull(val.node)) and checkint(val.node.isServing) == 0 then
            serviceNum = serviceNum + 1
        end
    end
    if serviceNum > 0 then
        haveWaiter = 1
    end
    if table.nums(checktable(gameMgr:GetUserInfo().avatarCacheData.recipe)) > 0 then
        haveRecipe = 1
    end
    --是否存在客人没有人服务的
    local haveCustomer = 0
    for name,val in pairs(self.servicingQueue) do
        --有服务员 有客人 --必需为普通客人，不能为霸王餐
        if val.customerUuid and val.seatId and val.isEating and checkint(val.hasCustomer) == 1 then
            --如果座位上有人时的逻辑，需要进行招待了
            -- if checkint(val.isSpecialCustomer) == 0 or (checkint(val.isSpecialCustomer) == 0 and val.questEventId) then --霸王餐请求招待会报错
            if checkint(val.isSpecialCustomer) == 0 or (not val.questEventId) then
                if checkint(val.isEating) == EAT_STATS.WAITING and val.isSeated and checkint(val.isSeated) == 1 then
                    --等待被服务的状态的逻辑,人要走到座位上后才能发起服务的逻辑
                    -- dump(val)
                    haveCustomer = 1
                    break
                end
            end
        end
    end
    --还要判断所有服务员且没有在服务的人员的活力值是否满足
    funLog(Logger.INFO, '----------判断是否有上菜的条件的逻辑---------' .. tostring(haveWaiter) .. tostring(haveRecipe) .. tostring(haveCustomer))
    logInfo.add(logInfo.Types.GAME, '----------判断是否有上菜的条件的逻辑---------' .. tostring(haveWaiter) .. tostring(haveRecipe) .. tostring(haveCustomer))
    if haveWaiter == 1 and haveRecipe == 1 and haveCustomer == 1 then --且有空位置没有人服务
        --表示是可服务的调用招待客人接口的逻辑
        local waiterInfo = self:GetIdleWaiter()
        if waiterInfo then
            funLog(Logger.INFO, "---------------服务客人接口----------->>>")
            socketMgr:SendPacket(NetCmd.RestuarantService, {waiterId = waiterInfo.id})
            --开始一个计时器用来做解除锁定的问题
            if self.serviceUpdateFunc then
                scheduler.unscheduleGlobal(self.serviceUpdateFunc)
            end
            local startTime = os.time()
            self.serviceUpdateFunc = scheduler.scheduleGlobal(function(dt)
                local deltaTime = math.floor(os.time() - startTime)
                if deltaTime >= 6 then
                    scheduler.unscheduleGlobal(self.serviceUpdateFunc)
                    self.canServiceLock = true
                end
            end, 0.2)
        else
            self.canServiceLock = true
        end
    else
        self.canServiceLock = true
    end
end


function AvatarMediator:ChangeWaiterState(id)
    local waiter = self.waiterQueue[tostring(id)]
    if waiter and (not tolua.isnull(waiter.node)) then
        --活力值存在了移除表情
        waiter.node:AddVigourEffect()
    end
end

function AvatarMediator:HiddenAllDirectionView(goodsUuid)
    local children = self.viewComponent.viewData.view:getChildren()
    local locations = self.houseLocation or {}
    for idx,val in ipairs(children) do
        if val.name and val.name == 'DragNode' then
            val:EnableGimos(false)
            val:EnableMove(false)
            -- val.viewData.directionView:setVisible(false)
            if goodsUuid then
                -- if val:getUserTag() ~= goodsUuid then
                    --不是当前拖动的点时，其他的点复原到原来的位置
                    local oUuid = val:getUserTag()
                    local tx, ty = val:getPosition()
                    if locations[tostring(oUuid)] then
                        local x = checkint(locations[tostring(oUuid)].location.x)
                        local y = checkint(locations[tostring(oUuid)].location.y)
                        if x ~= tx or y ~= ty  then
                            val:setPosition(cc.p(x,y))
                            -- val:runAction(cc.EaseOut:create(cc.MoveTo:create(0.1,cc.p(x,y)),0.1))
                        end
                        val:setLocalZOrder(TILED_HEIGHT - math.floor(y / TILED_SIZE))
                    end
                -- end
            else
                local oUuid = val:getUserTag()
                local tx, ty = val:getPosition()
                if locations[tostring(oUuid)] then
                    local x = checkint(locations[tostring(oUuid)].location.x)
                    local y = checkint(locations[tostring(oUuid)].location.y)
                    if x ~= tx or y ~= ty  then
                        val:setPosition(cc.p(x,y))
                        -- val:runAction(cc.EaseOut:create(cc.MoveTo:create(0.1,cc.p(x,y)),0.1))
                    end
                    val:setLocalZOrder(TILED_HEIGHT - math.floor(y / TILED_SIZE))
                end
            end
        end
    end
end
--[[
-- 移除等待队列中的数据
-- 两种情况移出:
--      1. 本身是等待的客人时间到了自动离开
--      2. 最开始创建人物有座位信息的人需要直接移除
---]]
function AvatarMediator:PopVisitorQueue()
    --移除第一个食客
    if #self.waitingQueue > 0 then
        local tempData = clone(self.waitingQueue)
        local pos = 1
        for idx,val in ipairs(tempData) do
            if checkint(val.leftSeconds) >= 0 then
                pos = idx
                break
            end
        end
        --移除第一个时间到了的食客
        local removeItem = table.remove(self.waitingQueue,pos)
        for idx,val in ipairs(self.waitingQueue) do
            if checkint(val.leftSeconds) > 0 then
                val.leftSeconds = checkint(val.leftSeconds) - checkint(removeItem.leftSeconds)
            end
        end
        -- dump(self.waitingQueue)
    end
    self.waitingCustomNodeQueue = {} --重置临时缓存数据
end

function AvatarMediator:SwitchDecorate()
    self.decorationing = (not self.decorationing)
    self.isStop = true --暂时食客相关的进入的一切计时器逻辑
    local viewComponent = self:GetViewComponent()
    viewComponent.viewData.bottomView:setVisible((not self.decorationing))
    viewComponent.viewData.bugLayer:setVisible(not self.decorationing)
    viewComponent.viewData.shareView:setVisible(false)
    viewComponent.viewData.friendBtn:setVisible(not self.decorationing and CommonUtils.GetModuleAvailable(MODULE_SWITCH.FRIEND))
    if viewComponent.viewData.chatBtn then viewComponent.viewData.chatBtn:setVisible(not self.decorationing) end
    viewComponent.viewData.restuarantButton:setVisible(not self.decorationing)
    viewComponent.viewData.avatarTopBtnLayer:setVisible(not self.decorationing)

    if self.decorationing == false then
        --如果是装
        self:RemoveTempDragNode()
        self:HiddenAllDirectionView(self.id)
        self:UpdateAllBlocks()
    end
    --更新所有的服务员与食客的的状态
    local children = viewComponent.viewData.view:getChildren()
    for idx,val in ipairs(children) do
        if val.name and val.name == 'RoleNode' then
            if self.decorationing == true then
                val:AbortWalking() --停止行走的逻辑
            else
                if val.npcType == RoleType.Waiters then
                    val:setVisible(true)
                    local cInfo = gameMgr:GetCardDataByCardId(val.id)
                    val.isServing = 0
                    local posIndex = gameMgr:GetWaiterLocateId(cInfo.id)
                    local tile = WaiterPositions[checkint(posIndex)]
                    if tile then
                        val:setPosition(cc.p((tile.w - 0.5) * TILED_SIZE,(tile.h - 0.5) * TILED_SIZE))
                        val.role:setAnimation(0,'idle', true)
                        val.role:setScaleX(1)
                        val:WillShowExpression()
                    end
                end
            end
        elseif val.name == 'DragNode' then
            val:ToDecorateView((not self.decorationing))
            -- viewComponent:GimosDraw(self.decorationing)
        end
    end
    if #self.waitingCustomNodeQueue > 0 then
        for idx,val in ipairs(self.waitingCustomNodeQueue) do
            if not tolua.isnull(val) then
                -- val:setVisible((not self.decorationing))
                val:removeFromParent() --半小人移除
            end
        end
        self.waitingCustomNodeQueue = {} --置空的逻辑
    end

    -- viewComponent.viewData.debugDraw:clear()

    if self.decorationing == false then
        --发送主界面home接口请求的逻辑
        shareFacade:DispatchSignal(COMMANDS.COMMAND_HOME_AVATAR)
    end
end

function AvatarMediator:RemoveTempDragNode()
    local testNode = self.viewComponent.viewData.view:getChildByName('HandleNode')
    if testNode then testNode:VisibleState(false) end
    if self.curNode then
        local tempNode = self.curNode
        if not tolua.isnull(tempNode) then
            tempNode:removeFromParent()
        end
        -- self.curNode:runAction(cc.Spawn:create(cc.Hide:create(), cc.RemoveSelf:create()))
        self.curNode = nil
        self.newDragId = nil
    end
    local decorateView = self.viewComponent:getChildByName('DecorateView')
    if decorateView then
        decorateView:setSelectedAvatarId(0)
    end
end

--ui事件
function AvatarMediator:ButtonActions(sender)
    PlayAudioByClickNormal()
    local tag = sender:getTag()
    -- dump(tag)
    if tag == RemindTag.BTN_AVATAR_DECORATE then
        if CommonUtils.UnLockModule(RemindTag.BTN_AVATAR_DECORATE, true) then
            --
            self:SwitchDecorate()

            -- share view
            self.viewComponent.viewData.shareView:setVisible(true)

            -- DecorateView
            local node = self.viewComponent:getChildByName('DecorateView')
            if node then node:removeFromParent() end
            node = require('Game.views.restaurant.DecorateView').new()
            node:setName('DecorateView')
            self.viewComponent:addChild(node, 50)

            --
            self:UpdateAvatarRenovationRemind(table.nums(gameMgr:GetUserInfo().avatarCacheRestaurantLevels) > 0 or table.nums(gameMgr:GetUserInfo().avatarCacheRestaurantNews) > 0)
        end
    elseif tag == RemindTag.LOBBY_TASK then
        --任务
        if checkint(self.datas.nextRestaurantTaskLeftSeconds) <= 0 then
            if #self.datas.restaurantTasks == 1 and checkint(self.datas.restaurantTasks[1].progress) >= checkint(self.datas.restaurantTasks[1].targetNum) then
                self:SendSignal(COMMANDS.COMMAND_DRAW_TASK)
            else
                local t = {}
                t.restaurantTasks = self.datas.restaurantTasks
                local LobbyTaskMediator = require( 'Game.mediator.LobbyTaskMediator' )
                local mediator = LobbyTaskMediator.new(t)
                self:GetFacade():RegistMediator(mediator)
            end
            GuideUtils.DispatchStepEvent()
        else
            uiMgr:ShowInformationTips(__('任务冷却中'))
        end
    elseif tag == RemindTag.LOBBY_MEMBER then
        --人员管理
        -- dump(self.datas.employee)
        -- dump(self.datas.waiter)
        local t = {}
        t.employee = self.datas.employee
        t.recipeCooking = self.datas.recipeCooking
        t.waiter = self.waiterQueue
        local LobbyPeopleManagementMediator = require( 'Game.mediator.LobbyPeopleManagementMediator' )
        local mediator = LobbyPeopleManagementMediator.new(t)
        self:GetFacade():RegistMediator(mediator)
        GuideUtils.DispatchStepEvent()
    elseif tag == RemindTag.LOBBY_DISH then
        --菜
        -- for i,v in pairs(self.recipeCdUpdateFunc) do
        --     if v then
        --         scheduler.unscheduleGlobal(v)
        --     end
        -- end
        AppFacade.GetInstance():GetManager("DataManager"):ClearRedDotNofication(tostring(RemindTag.LOBBY_DISH),RemindTag.LOBBY_DISH,"[餐厅avatar]-RemindTag.LOBBY_DISH")
        AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, {countdown = 0, tag = RemindTag.LOBBY_DISH})

        local t = {}
        t.recipe = self.datas.recipe
        t.recipeCooking = self.datas.recipeCooking
        local LobbyCookingMediator = require( 'Game.mediator.LobbyCookingMediator' )
        local mediator = LobbyCookingMediator.new(t)
        self:GetFacade():RegistMediator(mediator)
        GuideUtils.DispatchStepEvent()
    elseif tag == RemindTag.LOBBY_INFORMATION then
        --情报
        local t = {}
        t.popularityRank = self.datas.popularityRank
        t.popularityRankLeftSeconds = self.datas.popularityRankLeftSeconds
        t.lastPopularityRank = self.datas.lastPopularityRank
        t.myPopularityRank = self.datas.myPopularityRank
        t.myLastPopularitRank = self.datas.myLastPopularitRank
        t.myPopularityScore = self.datas.myPopularityScore
        t.myLastPopularityScore = self.datas.myLastPopularityScore
        -- 客流量
        t.traffic = self.datas.traffic
        -- 账目
        t.bill = self.datas.bill
        -- 露比
        t.bug = self.datas.bug
        -- 服务员
        t.waiterNum = table.nums(checktable(self.waiterQueue))
        local LobbyInformationMediator = require( 'Game.mediator.LobbyInformationMediator' )
        local mediator = LobbyInformationMediator.new(t)
        self:GetFacade():RegistMediator(mediator)
        GuideUtils.DispatchStepEvent()
    elseif tag == 100 then
        uiMgr:ShowInformationTips(string.fmt(__('等待的顾客数量：_num_'),{_num_ = table.nums(self.waitingQueue)}))
    elseif tag == 300 then
        self:ShowNowRecipeNumAndMess()
    elseif tag == 400 then
        self:ShowRandomBuffMess()
    elseif tag == RemindTag.LOBBY_SHOP then
        if GAME_MODULE_OPEN.NEW_STORE then
            app.uiMgr:showGameStores({storeType = GAME_STORE_TYPE.GROCERY, subType = GAME_STORE_TYPE.RESTAURANT})
        else
            app.router:Dispatch({name = "HomeMediator"}, {name = "ShopMediator", params = {goShopIndex = 'restaurant'}})
        end
    elseif tag == RemindTag.LOBBY_FRIEND then
        local LobbyFriendMediator = self:GetFacade():RetrieveMediator('LobbyFriendMediator')
        if LobbyFriendMediator then
            LobbyFriendMediator:GetViewComponent():setVisible(true)
            return
        end
        LobbyFriendMediator = require('Game.mediator.LobbyFriendMediator')
        local mediator = LobbyFriendMediator.new({isFirstLookFriend = self.isFirstLookFriend})
        self:GetFacade():RegistMediator(mediator)

        self.isFirstLookFriend = false
    elseif tag == RemindTag.LOBBY_FESTIVAL_ACTIVITY or tag == RemindTag.LOBBY_FESTIVAL_ACTIVITY_PREVIEW then
        local LobbyFestivalActivityMediator = require('Game.mediator.LobbyFestivalActivityMediator')
        local mediator = LobbyFestivalActivityMediator.new({tag = tag})
        self:GetFacade():RegistMediator(mediator)
    elseif tag == RemindTag.LOBBY_AGENT_SHOPOWNER then
        if CommonUtils.UnLockModule(RemindTag.LOBBY_AGENT_SHOPOWNER, true) then
            local LobbyAgentShopOwnerMediator = require('Game.mediator.LobbyAgentShopOwnerMediator')
            local mediator = LobbyAgentShopOwnerMediator.new({mangerId = self.datas.mangerId})
            self:GetFacade():RegistMediator(mediator)
        end
    end
end


function AvatarMediator:onClickPresetBtnHandler_(sender)
    local presetMdt = require('Game.mediator.restaurant.PresetMediator').new({serveringQueue = self.servicingQueue})
    app:RegistMediator(presetMdt)
end


function AvatarMediator:FreshDoorAnimate()
    local doorAvatar = self.viewComponent.viewData.doorAvatar
    doorAvatar:update(0)
    doorAvatar:setVisible(true)
    if table.nums(self.waitingQueue) <= 0 then
        doorAvatar:setVisible(false)
    elseif table.nums(self.waitingQueue) > 0 and table.nums(self.waitingQueue) < 4 then
         doorAvatar:setAnimation(0, 'idle', true)
    elseif table.nums(self.waitingQueue) >= 4 and table.nums(self.waitingQueue) < 10 then
        doorAvatar:setAnimation(0, 'idle2', true)
    elseif table.nums(self.waitingQueue) >= 10 then
        doorAvatar:setAnimation(0, 'idle3', true)
    end
end


--[[
--刷新指定节点的逻辑
--]]
function AvatarMediator:FreshComponents(name, func)
    local children = self.viewComponent.viewData.view:getChildren()
    if children then
        for i,v in ipairs(children) do
            if v.name and v.name == name then
                func(v)
            end
        end
    end
end

function AvatarMediator:SearchNode(name, id, cb)
    local children = self.viewComponent.viewData.view:getChildren()
    for idx,val in pairs(children) do
        if val.name == name and val:getUserTag() == checkint(id) then
            if cb then cb(val) end
            break
        end
    end
end


function AvatarMediator:OnRegist(  )
    --注册ui事件
    socketMgr.onConnected = function( connected)
        --重连接成功后需要将锁定标识还原
        self.canServiceLock = true
        self.deskInfoLock = true --是否可以请求餐桌信息
        self.canVisitor = true --是否可以请求餐桌信息

        if not self.decorationing then
            --更新所有的服务员与食客的的状态
            local children = self:GetViewComponent().viewData.view:getChildren()
            for idx,val in ipairs(children) do
                if val.name and val.name == 'RoleNode' then
                    if self.decorationing == true then
                        val:AbortWalking() --停止行走的逻辑
                    else
                        if val.npcType == RoleType.Waiters then
                            val:setVisible(true)
                            local cInfo = gameMgr:GetCardDataByCardId(val.id)
                            val.isServing = 0
                            local posIndex = gameMgr:GetWaiterLocateId(cInfo.id)
                            local tile = WaiterPositions[checkint(posIndex)]
                            if tile then
                                val:setPosition(cc.p((tile.w - 0.5) * TILED_SIZE,(tile.h - 0.5) * TILED_SIZE))
                                val.role:setAnimation(0,'idle', true)
                                val.role:setScaleX(1)
                                val:WillShowExpression()
                            end
                        end
                    end
                elseif val.name == 'DragNode' then
                    val:ToDecorateView((not self.decorationing))
                end
            end
            if #self.waitingCustomNodeQueue > 0 then
                for idx,val in ipairs(self.waitingCustomNodeQueue) do
                    if not tolua.isnull(val) then
                        -- val:setVisible((not self.decorationing))
                        val:removeFromParent() --半小人移除
                    end
                end
                self.waitingCustomNodeQueue = {} --置空的逻辑
            end

            --发送主界面home接口请求的逻辑
            shareFacade:DispatchSignal(COMMANDS.COMMAND_HOME_AVATAR)
        end
    end
    local AvatarCommand = require( 'Game.command.AvatarCommand')
    self:GetFacade():RegistSignal(COMMANDS.COMMAND_BUY_AVATAR, AvatarCommand)
    self:GetFacade():RegistSignal(COMMANDS.COMMAND_UNLOCK_AVATAR, AvatarCommand)
    self:GetFacade():RegistSignal(COMMANDS.COMMAND_GET_TASK, AvatarCommand)
    self:GetFacade():RegistSignal(COMMANDS.COMMAND_DRAW_TASK, AvatarCommand)
    self:GetFacade():RegistSignal(COMMANDS.COMMAND_CANCEL_QUEST, AvatarCommand)
    self:GetFacade():RegistSignal(COMMANDS.COMMAND_HOME_AVATAR, AvatarCommand)
    self:GetFacade():RegistSignal(COMMANDS.COMMANDS_Home_RecipeCookingDone, AvatarCommand)
    self:GetFacade():RegistSignal(COMMANDS.COMMANDS_ICEPLACE, AvatarCommand)
    self:GetFacade():RegistSignal(COMMANDS.COMMANDS_ICEPLACE_HOME, AvatarCommand)

    self.viewComponent.viewData.lobbyInfoButton:setTag(100) --门的逻辑，是否有点击
    self.viewComponent.viewData.lobbyInfoButton:setOnClickScriptHandler(handler(self, self.ButtonActions))
    self.viewComponent.viewData.gotoAvatarButton:setTag(RemindTag.BTN_AVATAR_DECORATE) --装拌
    self.viewComponent.viewData.gotoAvatarButton:setOnClickScriptHandler(handler(self, self.ButtonActions))
    self.viewComponent.viewData.restuarantButton:setTag(300) --服务员处
    self.viewComponent.viewData.restuarantButton:setOnClickScriptHandler(handler(self, self.ButtonActions))
    -- self.viewComponent.viewData.eventButton:setTag(400) --事件
    -- self.viewComponent.viewData.eventButton:setOnClickScriptHandler(handler(self, self.ButtonActions))
    ui.bindClick(self.viewComponent.viewData.presetBtn, handler(self, self.onClickPresetBtnHandler_))
    self.viewComponent.viewData.shareBtn:setOnClickScriptHandler(function(sender)
        shareFacade:DispatchObservers('SHARE_BUTTON_EVENT')
    end)
    for idx,val in ipairs(self.viewComponent.viewData.actionButtons) do
        val:setOnClickScriptHandler(handler(self, self.ButtonActions))
        if val:getTag() == RemindTag.LOBBY_DISH then
            if self.datas.recipe and next(self.datas.recipe) ~= nil then
                AppFacade.GetInstance():GetManager("DataManager"):ClearRedDotNofication(tostring(RemindTag.LOBBY_DISH),RemindTag.LOBBY_DISH)
            else
                AppFacade.GetInstance():GetManager("DataManager"):AddRedDotNofication(tostring(RemindTag.LOBBY_DISH),RemindTag.LOBBY_DISH)
                AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, {countdown = 0, tag = RemindTag.LOBBY_DISH})
            end
        end
    end
    if CommonUtils.GetModuleAvailable(MODULE_SWITCH.SHOP) then
        self.viewComponent.viewData.shopBtn:setOnClickScriptHandler(handler(self, self.ButtonActions))
    else
        self.viewComponent.viewData.shopBtn:setVisible(false)
    end
    self.viewComponent.viewData.navBackButton:setOnClickScriptHandler(function(sender)
        if shareFacade:HasMediator('AvatarShopMediator') then
            -- shareFacade:UnRegsitMediator('AvatarShopMediator')
            shareFacade:DispatchObservers(RESTAURANT_EVENTS.EVENT_AVATAR_SHOP_THEME_VISIBLE_UNREGIST)
        elseif shareFacade:HasMediator('FriendMediator') then
            shareFacade:UnRegsitMediator('FriendMediator')
        else
            if self.canBack then
                shareFacade:DispatchObservers('AVATAR_BACK')
            end
        end
    end)
    if CommonUtils.GetModuleAvailable(MODULE_SWITCH.FRIEND) then
        self.viewComponent.viewData.friendBtn:setOnClickScriptHandler(handler(self, self.ButtonActions))
    else
        self.viewComponent.viewData.friendBtn:setVisible(false)
    end

    self.viewComponent:InitViews()
    PlayBGMusic(AUDIOS.BGM.Restaurant.id)

    for seatId,val in pairs(self.servicingQueue) do
        if checkint(val.hasCustomer) == 1 then
            local ids = string.split(seatId, '_')
            local id = ids[1]
            self:SearchNode('DragNode', id, function(node)
                --找到节点，添加visitor
                node:AddVisitor(seatId, {visitorId = val.customerUuid, avatarId = val.customerId, npcType = RoleType.Visitors, isEating = checkint(val.isEating)})
            end)
        end
        if checkint(val.isEating) == EAT_STATS.WAITING and (not val.questEventId) then
            --等待服务
            self:PushRequestQueue(6007)
        end
    end

    if table.nums(self.waiterQueue) > 0 then
        self.canBack = false
        local loader = CCResourceLoader:getInstance()
        local shareSpineCache = SpineCache(SpineCacheName.GLOBAL)
        loader:registerScriptHandler(function ( event )
            --回调加载的进步以及是否完成的逻辑
            if event.event == 'done' then
                if tolua.isnull(self.viewComponent) then return end
                for id,info in orderedPairs(self.waiterQueue) do
                    local cardId = gameMgr:GetCardDataById(id).cardId
                    local positionId = gameMgr:GetWaiterLocateId(id)
                    local roleNode = self.viewComponent:ConstructNpc(cardId,cardId, RoleType.Waiters, WaiterPositions[positionId])
                    roleNode:setLocalZOrder(DragNode.OrderTags.Desk_Order + (TILED_SIZE - WaiterPositions[positionId].h))
                    self.waiterQueue[tostring(id)].node = roleNode
                    roleNode:WillShowExpression() --是否显表情的逻辑
                end
                self.canBack = true
            end
        end)
        for id,val in pairs(self.waiterQueue) do
            local cardData   = gameMgr:GetCardDataById(id) or {}
            local cardId     = tostring(cardData.cardId)
            local shareKey   = tostring(cardData.defaultSkinId)
            local pathPrefix = CardUtils.GetCardSpinePathBySkinId(cardData.defaultSkinId)
            if app.gameResMgr:verifySpine(pathPrefix) then
                loader:addCustomTask(cc.CallFunc:create(function ( )
                    shareSpineCache:addCacheData(pathPrefix, shareKey, 0.4)
                end),0.05)
            end
        end
        loader:run() --执行循环
    end

    -- 虫子
    if CommonUtils.GetModuleAvailable(MODULE_SWITCH.PERISH_BUG) then
        for _, bugAreaId in ipairs(self.bugQueue) do
            self.viewComponent:addBugAt(bugAreaId)
        end
        if table.nums(self.bugQueue) > 0 then
            PlayAudioClip(AUDIOS.UI.ui_lubi_appear.id)
        end
    end

    -- if gameMgr:GetUserInfo().avatarCacheData.events and table.nums(gameMgr:GetUserInfo().avatarCacheData.events) > 0 then
    --     local head = gameMgr:GetUserInfo().avatarCacheData.events[1]
    --     if head then
    --         local eventInfo = CommonUtils.GetConfigNoParser('restaurant', 'event', head.eventId)
    --         if eventInfo and eventInfo.name then
    --             self.viewComponent.viewData.eventButton:setText(eventInfo.name)
    --             self.viewComponent.viewData.eventTimeLabel:setString(string.formattedTime(checkint(head.leftSeconds), __('剩%02i:%02i:%02i结束')))
    --         end
    --     end
    -- end

    self.recipeCdUpdateFunc = {}
    self:UpdateScheduleMap()
    --启动循环监听器，用来启动服务员去服务具体人员的逻辑
    loopStartTime = getServerTime()
    self.updateFunc = scheduler.scheduleGlobal(function(dt)
        if not self.isStop then
            if not self.decorationing then
                local delta = math.floor(getServerTime()- loopStartTime)
                if delta >= 1 then
                    loopStartTime = getServerTime()
                    --不在装修的情况下的处理逻辑
                    --下一个时间点到来后建立食客人的逻辑
                    if self.canVisitor then
                        local nextCustomArrivalSeconds = checkint(gameMgr:GetUserInfo().avatarCacheData.nextCustomerArrivalLeftSeconds)
                        nextCustomArrivalSeconds = (nextCustomArrivalSeconds - 1)
                        gameMgr:GetUserInfo().avatarCacheData.nextCustomerArrivalLeftSeconds = nextCustomArrivalSeconds
                        if nextCustomArrivalSeconds <= -3 then nextCustomArrivalSeconds = -3 end
                        if nextCustomArrivalSeconds == -3 then
                            -- print('--------start quest')
                            --发送接口请求6001客人到达的接口的逻辑
                            self.canVisitor = false
                            socketMgr:SendPacket(NetCmd.CustomerArrival)
                            --开始一个计时器用来做解除锁定的问题
                            if self.visitorUpdateFunc then
                                scheduler.unscheduleGlobal(self.visitorUpdateFunc)
                            end
                            local startTime = os.time()
                            self.visitorUpdateFunc = scheduler.scheduleGlobal(function(dt)
                                local deltaTime = math.floor(os.time() - startTime)
                                if deltaTime >= 6 then
                                    scheduler.unscheduleGlobal(self.visitorUpdateFunc)
                                    self.canVisitor = true
                                end
                            end, 0.2)
                    end
                end
                --判断是否需要发请求的逻辑
                if self.canServiceLock then
                    if table.nums(self.requestQueue) > 0 then
                        --如果存在队列的逻辑，需要判断是否可以上菜的请求的逻辑
                        self.canServiceLock = false --不能再迭代请求的逻辑
                        self:PopRequestQueue()
                        ---上菜服务的逻辑
                        self:UpTableDish()
                    else
                        self.canServiceLock = true--不能再迭代请求的逻辑
                    end
                end
            end
            end
        end
    end, 1.0)
    if DEBUG > 0 then
        -- self:DrawBlocks()
    end
    shareFacade:DispatchObservers(RESTAURANT_EVENTS.EVENT_NEW_CUSTOM_ARRIVAL)
    --是否显示离线奖励的逻辑
    if table.nums(checktable(self.datas.offlineRewards)) > 0 and table.nums(checktable(self.datas.offlineRecipe)) > 0 then

        local recipes = {}
        for name,val in pairs(self.datas.offlineRecipe) do
            table.insert(recipes, {goodsId = checkint(name), num = checkint(val)})
        end
        self:GetViewComponent():runAction(cc.Sequence:create(cc.DelayTime:create(0.2), cc.CallFunc:create(function()
            local offlineView = require('common.AvatarPopUpReward').new({rewardData = self.datas.offlineRewards ,consumeData = recipes, msg = __('在您离开的这段时间获得了')})
            display.commonUIParams(offlineView, {po = display.center})
            offlineView:setName('offlineView')
            self:GetViewComponent():addChild(offlineView, 1000)
        end)))
    end
    --更新引导的下一步的逻辑
    if CommonUtils.UnLockModule(RemindTag.BTN_AVATAR_DECORATE, false) then
        --已经解锁的逻辑
        if GuideUtils.HasModule(GUIDE_MODULES.MODULE_AVATAR) then
            GuideUtils.SwitchModule(GUIDE_MODULES.MODULE_AVATAR)
        else
            GuideUtils.DispatchStepEvent()
        end
    else
        local restaurantStepId = checkint(GuideUtils.GetModuleData(GUIDE_MODULES.MODULE_LOBBY))
        if (not GuideUtils.IsGuiding() and restaurantStepId == 0 and 
            not GuideUtils.CheckHaveRestaurantManagementMember({dontShowTips = true}) and
            not GuideUtils.CheckIsHaveSixCards({dontShowTips = true}) ) then
            GuideUtils.SwitchModule(GUIDE_MODULES.MODULE_LOBBY, 7)
        else
            GuideUtils.DispatchStepEvent()
        end
    end

    self:UpDataNowRecipeNumAndMess()

    -- friend quest return
    if gameMgr:GetUserInfo().avatarFriendCacheData_ then
        gameMgr:GetUserInfo().restaurantEventHelpLeftTimes = checkint(gameMgr:GetUserInfo().restaurantEventHelpLeftTimes) - 1

        local friendId        = checkint(gameMgr:GetUserInfo().avatarFriendCacheData_.friendId)
        local isPassed        = checkint(gameMgr:GetUserInfo().avatarFriendCacheData_.isPassed) == 1
        local friendAvatarMdt = require('Game.mediator.FriendAvatarMediator').new({friendId = friendId})
        AppFacade.GetInstance():RegistMediator(friendAvatarMdt)

        if isPassed then
            self:updateFriendListState(NetCmd.Request2027, friendId)
            gameMgr:GetUserInfo().avatarFriendVisitData_ = gameMgr:GetUserInfo().avatarFriendVisitData_ or {}
            gameMgr:GetUserInfo().avatarFriendVisitData_[tostring(AVATAR_FRIEND_MESSAGE_TYPE.TYPE_PERISH_RESTAURANT_QUEST_EVENT)] = true
        end

        gameMgr:GetUserInfo().avatarFriendId_        = friendId
        gameMgr:GetUserInfo().avatarFriendCacheData_ = nil
    end

    if self.viewComponent.viewData.chatBtn then self.viewComponent.viewData.chatBtn:delayRenderingList() end

end

function AvatarMediator:updateFriendListState(cmd, friendId, bugId)

    for i,v in ipairs(gameMgr:GetUserInfo().friendList) do
        if v.friendId == friendId then
            local isCanUpdate = true
            if cmd == NetCmd.RequestRestaurantBugClear then
                if bugId == 0 then
                    gameMgr:GetUserInfo().friendList[i].restaurantBug = 1
                    self:GetFacade():DispatchObservers(UPDATE_LOBBY_FRIEND_BUG_STATE, {cmd = cmd, friendId = friendId})
                end
                break
            elseif cmd == NetCmd.RequestRestaurantBugAppear then
                gameMgr:GetUserInfo().friendList[i].restaurantBug = 2
                self:GetFacade():DispatchObservers(UPDATE_LOBBY_FRIEND_BUG_STATE, {cmd = cmd, friendId = friendId})
                break
            elseif cmd == NetCmd.RequestRestaurantBugHelp then
                gameMgr:GetUserInfo().friendList[i].restaurantBug = 3
                self:GetFacade():DispatchObservers(UPDATE_LOBBY_FRIEND_BUG_STATE, {cmd = cmd, friendId = friendId})
                break
            elseif cmd == NetCmd.Request2027 then
                gameMgr:GetUserInfo().friendList[i].restaurantQuestEvent = 1
                self:GetFacade():DispatchObservers(UPDATE_LOBBY_FRIEND_BUG_STATE, {cmd = cmd, friendId = friendId})
                break
            elseif cmd == NetCmd.RequestRestaurantQuestEventHelp then
                gameMgr:GetUserInfo().friendList[i].restaurantQuestEvent = 2
                self:GetFacade():DispatchObservers(UPDATE_LOBBY_FRIEND_BUG_STATE, {cmd = cmd, friendId = friendId})
                break
            elseif cmd == NetCmd.RequestRestaurantQuestEventFighting then
                gameMgr:GetUserInfo().friendList[i].restaurantQuestEvent = 3
                self:GetFacade():DispatchObservers(UPDATE_LOBBY_FRIEND_BUG_STATE, {cmd = cmd, friendId = friendId})
                break
            end
        end
    end

    -- self:GetFacade():DispatchObservers(UPDATE_LOBBY_FRIEND_BUG_STATE, {cmd = cmd, friendId = friendId})

end

--[[
--得到seatInfo相关的信息的逻辑
--]]
function AvatarMediator:GetSeatCacheInfoBySeatId(seatId)
    -- dump(self.servicingQueue)
    return self.servicingQueue[tostring(seatId)]
end

--[[
--将新的位置信息添加到服务队列中去
--]]
function AvatarMediator:UpdateSeatInfo(seatId, datas)
    local seatInfo = {}
    if self.servicingQueue[seatId] then
        seatInfo = self.servicingQueue[seatId]
    else
        self.servicingQueue[seatId] = seatInfo
    end
    if datas then
        for key,val in pairs(datas) do
            if seatInfo.customerId and key == 'customerId' then
                val = seatInfo.customerId --以本地模型为准防止穿模型
            end
            seatInfo[key] = val
        end
        -- table.merge(self.servicingQueue[seatId], datas)
    end
    funLog(Logger.INFO, '---------------------桌子信息------------------------')
    -- dump(self.servicingQueue)--各桌子信息
end

function AvatarMediator:ClearCacheSeat(seatId)
    funLog(Logger.INFO, '<<------------->> ClearCacheSeat---->>>>')
    self.servicingQueue[seatId] = nil
end


--[[
--得到当前没有创建
--]]
function AvatarMediator:GetSeatWithoutCustomer()
    local children = self:GetViewComponent().viewData.view:getChildren()
    local seats = {}
    for idx,val in ipairs(children) do
        --得到所有的桌子然后获取位置
        if val.name and val.name == 'DragNode' and table.nums(val.chairsInfos) > 0 then
            for seatId,_ in pairs(val.chairsInfos) do
                local seatInfo = self.servicingQueue[seatId]
                if seatInfo then
                    if checkint(seatInfo.hasCustomer) == 0 then
                        seats[seatId] = val
                    -- else
                        -- 但是人还没有到位置上去的时候
                        -- local node = val:getChildByName(seatId)
                        -- if not node then
                            -- dump(seatInfo)
                            -- seats[seatId] = val
                        -- end
                    end
                else
                    cclog('-------------未找到缓存数据--------->>>', seatId)
                end
            end
        end
    end
    return seats

end


--[[
--得到所有的没有人的位置节点
--]]
function AvatarMediator:RetriveEmptySeatNodes()
    local children = self:GetViewComponent().viewData.view:getChildren()
    local seats = {}
    for idx,val in ipairs(children) do
        --得到所有的桌子然后获取位置
        if val.name and val.name == 'DragNode' and table.nums(val.chairsInfos) > 0 then
            for seatId,_ in pairs(val.chairsInfos) do
                local seatInfo = self.servicingQueue[seatId]
                if seatInfo then
                    if checkint(seatInfo.hasCustomer) == 0 then
                        seats[seatId] = val
                    else
                        --但是人还没有到位置上去的时候
                        local node = val:getChildByName(seatId)
                        if not node then
                            seats[seatId] = val
                        end
                    end
                end
            end
        end
    end
    return seats
end
--[[
--构建人流量的逻辑
--@data --相关的数据
--]]
function AvatarMediator:StreamPeoples(data)
    --1.如果是有空位的情况下，先让人到空位置
    --  1.如果有个等待的人直接走到空位置
    --2.如果没有空位的情况下，构建等待的人k
    if not self.decorationing then
        local chairSeats = self:RetriveEmptySeatNodes()
        local len = table.nums(chairSeats) --空桌子的数量
        local waitingLen = table.nums(self.waitingQueue)
        if len > 0 and waitingLen > 0 then
            funLog(Logger.INFO, "-->>>---->> 需要走到座位上的逻辑------->>")
            local startIdx = 1
            --先判断是否有门前的人
            local front = checktable(self.waitingQueue[1])
            local seatId = front.seatId
            if seatId then
                table.remove(self.waitingQueue, 1)
                --得到seatId对应的桌子然后人走过的去的逻辑
                local targetNode = chairSeats[seatId]
                if targetNode then
                    local tiledPos = targetNode:GetTargetDeskTile(seatId,RoleType.Visitors)
                    if tiledPos then
                        local seatInfo = self.servicingQueue[seatId]
                        if #self.waitingCustomNodeQueue == 1 then
                            --已创建的人去指定的座位点动画
                            local npcNode = self.waitingCustomNodeQueue[1]
                            funLog(Logger.INFO, "-->>>---->> 正在等待的人去位置 ------->>")
                            npcNode:SetNpcData(seatInfo)
                            npcNode:setName(seatId)
                            npcNode:UpdateDestination(cc.p(tiledPos.w * TILED_SIZE - TILED_SIZE * 0.5, (tiledPos.h - 0.5) * TILED_SIZE), seatId)
                            self.waitingCustomNodeQueue = {} --等待的人结束直接离开
                        else
                            --需要创建人去具体的位置
                            funLog(Logger.INFO, "-->>>---->> 新建人走到座位上的逻辑------->>")
                            local npcNode = self.viewComponent:ConstructNpc(checkint(front.customerUuid),checkint(front.customerId), RoleType.Visitors)
                            npcNode:SetNpcData(seatInfo)
                            npcNode:setName(seatId)
                            npcNode:UpdateDestination(cc.p(tiledPos.w * TILED_SIZE - TILED_SIZE * 0.5, (tiledPos.h - 0.5) * TILED_SIZE),seatId)
                        end
                    end
                else
                    funLog(Logger.INFO, "-->>>---->> 空位置与数据对不上 ------->>"..tostring(#self.waitingQueue))
                end
            else
                --需要在门前等的逻辑
                startIdx = startIdx + 1
                if #self.waitingCustomNodeQueue == 0 then
                    funLog(Logger.INFO, "-->>>---->> 门口是否需要建立等待的人------->>"..tostring(#self.waitingQueue))
                    local customer = self.waitingQueue[1]
                    local avatarId = checkint(customer.customerId)
                    local id = avatarId
                    if customer.customerUuid then
                        id = checkint(customer.customerUuid)
                    end
                    local npcNode = self.viewComponent:ConstructNpc(id, avatarId, RoleType.Visitors)
                    npcNode:DoorWaitingVisitor()
                    npcNode:SetNpcData(clone(customer))
                    --加入临时缓存中去
                    table.insert(self.waitingCustomNodeQueue, npcNode)
                end
            end
            --下面是处理其他空位置的逻辑
            local chairSeats = self:RetriveEmptySeatNodes()
            -- dump(chairSeats)
            -- dump(self.waitingQueue)
            local len = table.nums(chairSeats) --空桌子的数量
            local waitingLen = table.nums(self.waitingQueue)
            local loopLen = math.min(len, waitingLen)
            if waitingLen > 0 and loopLen >= startIdx then
                for i=startIdx,loopLen do
                    local front = checktable(self.waitingQueue[i])
                    local seatId = front.seatId
                    if seatId then
                        --直接需要建立人去目标地的逻辑
                        table.remove(self.waitingQueue, 1)
                        local targetNode = chairSeats[seatId]
                        if targetNode then
                            local tiledPos = targetNode:GetTargetDeskTile(seatId,RoleType.Visitors)
                            if tiledPos then
                                local seatInfo = self.servicingQueue[seatId]
                                funLog(Logger.INFO, "-->>>---->> 队列位置新建人走到座位上的逻辑------->>" .. tostring(i))
                                local npcNode = self.viewComponent:ConstructNpc(checkint(front.customerUuid),checkint(front.customerId), RoleType.Visitors)
                                npcNode:SetNpcData(seatInfo)
                                npcNode:setName(seatId)
                                npcNode:UpdateDestination(cc.p(tiledPos.w * TILED_SIZE - TILED_SIZE * 0.5, (tiledPos.h - 0.5) * TILED_SIZE),seatId)
                            end
                        else
                            funLog(Logger.INFO, "-->>>---->> 空位置与数据对不上2222 ------->>"..tostring(#self.waitingQueue))
                        end
                    end
                end
            end
        elseif len == 0 and waitingLen > 0 then
            --如果是没有空桌子时判断是否需要建立门口等着的人
            if #self.waitingCustomNodeQueue == 0 then
                funLog(Logger.INFO, "-->>>---->> 没有空桌子建立门口等待的人------->>>>>>>>" .. tostring(waitingLen))
                local customer = checktable(self.waitingQueue[1])
                local avatarId = checkint(customer.customerId)
                local id = avatarId
                if customer.customerUuid then
                    id = checkint(customer.customerUuid)
                end
                local npcNode = self.viewComponent:ConstructNpc(id, avatarId, RoleType.Visitors)
                npcNode:DoorWaitingVisitor()
                npcNode:SetNpcData(clone(customer))
                --加入临时缓存中去
                table.insert(self.waitingCustomNodeQueue, npcNode)
            end
        end
        self:FreshDoorAnimate()
    end
end

function AvatarMediator:OnUnRegist(  )
    self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_BUY_AVATAR)
    self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_UNLOCK_AVATAR)
    self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_GET_TASK)
    self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_DRAW_TASK)
    self:GetFacade():UnRegsitSignal(COMMANDS.COMMANDS_Home_RecipeCookingDone)
    self:GetFacade():UnRegsitSignal(COMMANDS.COMMANDS_ICEPLACE)
    self:GetFacade():UnRegsitSignal(COMMANDS.COMMANDS_ICEPLACE_HOME)

    if next(self.datas.recipe) ~= nil then
        gameMgr:GetUserInfo().showRedPointForRestaurantRecipeNum = false
        AppFacade.GetInstance():GetManager("DataManager"):ClearRedDotNofication(tostring(RemindTag.MANAGER),RemindTag.MANAGER, "[餐厅入口]-AvatarMediator:OnUnRegist")
    else
        gameMgr:GetUserInfo().showRedPointForRestaurantRecipeNum = true
        AppFacade.GetInstance():GetManager("DataManager"):AddRedDotNofication(tostring(RemindTag.MANAGER),RemindTag.MANAGER, "[餐厅入口]-AvatarMediator:OnUnRegist")
        AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, {countdown = 0, tag = RemindTag.MANAGER})
    end

    if table.nums(self.waiterQueue) > 0 then
        for id,val in pairs(self.waiterQueue) do
            local shareKey = tostring(gameMgr:GetCardDataById(id).defaultSkinId)
            SpineCache(SpineCacheName.GLOBAL):removeCacheData(shareKey)
        end
    end
    self.waiterQueue = {}
    self.servicingQueue = {}
    self.requestQueue = {}

    gameMgr:GetUserInfo().avatarFriendId_ = nil

    socketMgr.onConnected = nil --删除回调的逻辑
    if self.updateFunc then
        scheduler.unscheduleGlobal(self.updateFunc)
    end
    -- if self.timeUpdateFunc then
    --     scheduler.unscheduleGlobal(self.timeUpdateFunc)
    -- end
    if self.taskUpdateFunc then
        scheduler.unscheduleGlobal(self.taskUpdateFunc)
    end

    for i,v in pairs(self.recipeCdUpdateFunc) do
        if v then
            scheduler.unscheduleGlobal(v)
        end
    end
    if self.visitorUpdateFunc then
        scheduler.unscheduleGlobal(self.visitorUpdateFunc)
    end
    if self.serviceUpdateFunc then
        scheduler.unscheduleGlobal(self.serviceUpdateFunc)
    end
    PlayBGMusic()
    CCResourceLoader:getInstance():abortAll()
    local shareSpineCache = SpineCache(SpineCacheName.GLOBAL)
    shareSpineCache:clearCache()
end


function AvatarMediator:DrawBlocks()
    self.viewComponent.viewData.debugDraw:clear()
    for name,val in pairs(self.blocks) do
        local pos = val.pos
        local color = cc.c4f(1.0,0.4,0.4,1.0)
        if val.couldCross then
            color = cc.c4f(0.4,0.5,1.0,0.5)
        end
        self.viewComponent.viewData.debugDraw:drawRect(cc.p(pos.x - 6, pos.y - 6), cc.p(pos.x + 6, pos.y + 6),color)
    end
end
--[[
--计算路径的逻辑
--]]
function AvatarMediator:SearchPath(startPos, targetPos, isDebug)
    local PathFinder = require('root.PathFinder')
    PathFinder.clear_cache()
    funLog(Logger.INFO, "[start] = " .. string.format('(%f, %f)', startPos.x, startPos.y) ..  string.format('[target] = (%f, %f)', targetPos.x, targetPos.y))
    local PathObj = PathFinder.calculate(startPos, targetPos, self.blocks, false)
    if PathObj then
        local points = PathObj:getWayPoints()
        if DEBUG > 0 then
            -- self.viewComponent.viewData.debugDraw:clear()
            -- for idx,val in ipairs(points) do
                -- self.viewComponent.viewData.debugDraw:drawDot(val, 6, cc.c4f(1.0,0.3,0.4,1.0))
            -- end
            -- self:DrawBlocks()
        end
    else
        funLog(Logger.INFO, '----------->>> ---------------------------->>')
        funLog(Logger.INFO, '----------->>> 未查找到路径信息---------->>')
    end
    return PathObj
end

function AvatarMediator:UpdateTileState(tiles, cross)
    for idx,val in ipairs(tiles) do
        local block = self.blocks[string.format("%d_%d", val.w, val.h)]
        if block then
            block.couldCross = cross
        end
    end
    -- self:DrawBlocks()
end
--[[
--@params oldRect 旧的矩形区域
--@params newRect 新的区域
--]]
function AvatarMediator:UpdateDrageNodeBlocksInformation(oldRect, newRect)
    local oblocks = self:ConvertRectAreaToTileds(oldRect)
    local nblocks = self:ConvertRectAreaToTileds(newRect)
    self:UpdateTileState(oblocks, true)
    self:UpdateTileState(nblocks, false)
end


function AvatarMediator:ConvertRectAreaToTileds(rect)
    -- rect = cc.rect(rect.x + 16, rect.y + 16, rect.width - 16, rect.height - 16)
    local minX = cc.rectGetMinX(rect)
    local minY = cc.rectGetMinY(rect)
    local maxX = cc.rectGetMaxX(rect)
    local maxY = cc.rectGetMaxY(rect)

    -- print(string.format('------%f --%f --%f --%f', minX, minY, maxX, maxY))
    local minTiledX = math.ceil(minX / TILED_SIZE)
    local minTiledY = math.ceil(minY / TILED_SIZE)
    local maxTiledX = math.ceil(maxX / TILED_SIZE)
    local maxTiledY = math.ceil(maxY / TILED_SIZE)
    --为了防止堵死处理下
    if maxTiledX - minTiledX > 2 then
        minTiledX = minTiledX + 1
        maxTiledX = maxTiledX - 1
    else
        minTiledX = maxTiledX
    end
    if maxTiledY - minTiledY > 2 then
        minTiledY = minTiledY + 1
        maxTiledY = maxTiledY - 1
    else
        minTiledY = maxTiledY
    end
    -- print(minTiledX, minTiledY, maxTiledX, maxTiledY)
    local blocks = {}
    for i= minTiledX,maxTiledX, 1 do
        for j= minTiledY,maxTiledY, 1 do
            table.insert(blocks,{w = i, h = j})
        end
    end
    return blocks
end

--[[
--更新添加上场时的拖动逻辑处理
--]]
function AvatarMediator:AddTempAvatar(id, avatarId)
    --添加节点
    if not self.curNode then
        local avatarConfig = CommonUtils.GetConfigNoParser("restaurant", 'avatar', avatarId)
        local locationConfig = CommonUtils.GetConfigNoParser('restaurant', 'avatarLocation', avatarId)
        local nType = RestaurantUtils.GetAvatarSubType(avatarConfig.mainType, avatarConfig.subType)
        local dragNode = DragNode.new({id = id,avatarId = avatarId, nType = nType, configInfo = locationConfig, upload = true, effectLayer = self.viewComponent.viewData.effectLayer})
        display.commonUIParams(dragNode, {ap = display.LEFT_BOTTOM,po = cc.p(768, 8 + 24 * TILED_SIZE)})
        dragNode:setUserTag(id)
        -- dragNode:EnableTouch(true)
        dragNode:EnableMove(true)
        dragNode.isDecorating = true
        -- dragNode:setLocalZOrder(TILED_HEIGHT - 8)
        dragNode:setLocalZOrder(DragNode.OrderTags.Temp_Avatar)
        self.viewComponent.viewData.view:addChild(dragNode)
        local iscollision = dragNode:IsCollision(768, 8 + 24 * TILED_SIZE)
        dragNode.isCollided = iscollision
        self.curNode = dragNode
        local testNode = self.viewComponent.viewData.view:getChildByName('HandleNode')
        local collisionWidth = checkint(locationConfig.collisionBoxWidth)
        local collisionHeight = checkint(locationConfig.collisionBoxLength)
        local offset = string.split(locationConfig.offset[1],',')
        local x,y = dragNode:getPosition()
        if not testNode then
            testNode = require('Game.views.restaurant.HandleNode').new({id = id, avatarId = avatarId,collisionWidth = collisionWidth,collisionHeight = collisionHeight,upload = true})
            testNode:setName('HandleNode')
            self.viewComponent.viewData.view:addChild(testNode, 600)
        else
            testNode:RestoreState(id, avatarId, collisionWidth, collisionHeight, true)
            testNode:VisibleState(true)
        end
        testNode.isCollided = iscollision
        display.commonUIParams(testNode, {ap = display.CENTER_BOTTOM, po = cc.p(x + collisionWidth * 0.5 + checkint(offset[1]), y + collisionHeight * 0.5 + checkint(offset[2]))})
    end

    local decorateView = self.viewComponent:getChildByName('DecorateView')
    if decorateView then
        decorateView:setSelectedAvatarId(avatarId)
    end
end

--[[
--判断当前tile是否被占用了如果占用找附近一个可用点
--]]
function AvatarMediator:IsTileAvailable(tile)
    if tile.w > TILED_WIDTH then tile.w = TILED_WIDTH end
    if tile.h > TILED_HEIGHT then tile.h = TILED_HEIGHT end
    local isAvailable = false
    if self.blocks[string.format('%d_%d', tile.w, tile.h)] then
        isAvailable = self.blocks[string.format('%d_%d', tile.w, tile.h)].couldCross
    end
    return isAvailable
end



--获取预计可售卖时间
function AvatarMediator:GetTimeForHangUp()
    local num = 0--总菜品数量
    local time = 0--总菜品花费时间
    for k,v in pairs(self.datas.recipe) do
        num = num + v
        local recipeConf = CommonUtils.GetConfigNoParser('cooking','recipe',k) or {}
        local eatingTime = checkint(recipeConf.eatingTime)
        time = time + (v*eatingTime)
    end

    local vigourNum = 0--当前新鲜度总数
    for k,v in pairs(self.waiterQueue) do
        vigourNum = vigourNum + checkint(v.vigour)
    end
    local finalTime = 0
    if num ~= 0 then
        local averageTime = time/num--平均时间
        local seatNum = checkint(CommonUtils.GetConfigNoParser('restaurant', 'levelUp', gameMgr:GetUserInfo().restaurantLevel).seatNum)--当前座位数
        finalTime = averageTime * math.min(num,vigourNum) / math.min(seatNum, 3600 / app.restaurantMgr:GetTraffic())
        -- dump(finalTime)
        -- dump(averageTime)
        -- dump(time)
        -- dump(num)
        -- dump(vigourNum)
        -- dump(seatNum)
        -- dump(3600/app.restaurantMgr:GetTraffic())
    end
    -- dump(string.formattedTime(finalTime,'%02i:%02i:%02i'))
    return finalTime-- string.formattedTime(finalTime,'%02i:%02i:%02i')
end

--[[`
--当前菜品销售情况
--]]
function AvatarMediator:ShowNowRecipeNumAndMess()
    -- if table.nums(self.datas.recipe) <= 0 then
    --     uiMgr:ShowInformationTips(__('没有已制作的菜品'))
    -- else
        self:GetTimeForHangUp()
        if not self.viewComponent:getChildByTag(99998) then
            local cview = CLayout:create(display.size)
            cview:setAnchorPoint(display.CENTER)
            cview:setPosition(cc.p(display.cx + display.SAFE_L, display.cy))
            self.viewComponent:addChild(cview,100)
            cview:setTag(99998)
            -- cview:setBackgroundColor(cc.c4b(23, 67, 128, 128))

            local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 0))
            eaterLayer:setTouchEnabled(true)
            eaterLayer:setContentSize(display.size)
            eaterLayer:setAnchorPoint(cc.p(0,0))
            eaterLayer:setPosition(cc.p(0, 0))
            cview:addChild(eaterLayer, -1)

            eaterLayer:setOnClickScriptHandler(function( sender )
                if self.viewComponent:getChildByTag(99998) then
                    self.viewComponent:getChildByTag(99998):setVisible(false)
                end
            end)
            local size = cc.size(656,380)
            local view = CLayout:create(size)
            display.commonUIParams(view, {ap = cc.p(0,0), po = cc.p(20,120)})
            cview:addChild(view,10)
            view:setTag(8888)
            -- view:setBackgroundColor(cc.c4b(0, 0, 0, 140))

            local bg = display.newImageView(_res("ui/common/common_bg_tips.png"),size.width * 0.5,  size.height*0.5,--
            {ap = cc.p(0.5, 0.5),scale9 = true,size = size})
            view:addChild(bg)

            local num = 0
            local time = 0
            local tempT = {}
            for k,v in pairs(self.datas.recipe) do
                local t = {}
                t.recipeId = k
                t.recipeNum = v
                num = num + v
                -- lo
                -- time = time + tempNum
                table.insert(tempT,t)
            end


            local tempLabel = display.newLabel(33,312,
                {text = __('预计可售卖时间'),fontSize = 24,color = '5c5c5c', ap = cc.p(0, 0)})--2b2017
            view:addChild(tempLabel,1)

            local lineImg = display.newImageView(_res("avatar/ui/recipeMess/restaurant_ico_selling_line.png"), 33, 311,--
            {ap = cc.p(0, 0)})
            view:addChild(lineImg,3)

            local tempBg = display.newImageView(_res("avatar/ui/recipeMess/restaurant_ico_selling_frame.png"), 33, 311,--
            {ap = cc.p(0, 1)})
            view:addChild(tempBg,3)
            local tempImg = display.newImageView(_res("avatar/ui/recipeMess/restaurant_ico_selling_timer.png"), 3, 3,--
            {ap = cc.p(0, 0)})
            tempBg:addChild(tempImg,3)



            local saleTimeNum = cc.Label:createWithBMFont('font/small/common_text_num.fnt', '')
            saleTimeNum:setHorizontalAlignment(display.TAR)
            saleTimeNum:setPosition(60, 311)
            saleTimeNum:setAnchorPoint(cc.p(0, 1))
            view:addChild(saleTimeNum, 10)
            saleTimeNum:setTag(101)
            saleTimeNum:setString(string.formattedTime(self:GetTimeForHangUp(),'%02i:%02i:%02i'))






            local tempLabel = display.newLabel(33,199,
                { text = __('橱窗总菜品数'),fontSize = 24,color = '5c5c5c', ap = cc.p(0, 0)})--2b2017
            view:addChild(tempLabel,1)

            local lineImg = display.newImageView(_res("avatar/ui/recipeMess/restaurant_ico_selling_line.png"), 33, 198,--
            {ap = cc.p(0, 0)})
            view:addChild(lineImg,3)


            local tempBg = display.newImageView(_res("avatar/ui/recipeMess/restaurant_ico_selling_frame.png"), 33, 198,--
            {ap = cc.p(0, 1)})
            view:addChild(tempBg,3)
            local tempImg = display.newImageView(_res("avatar/ui/recipeMess/restaurant_ico_selling_plates.png"), 3, 3,--
            {ap = cc.p(0, 0)})
            tempBg:addChild(tempImg,3)


            local allRecipeNum = cc.Label:createWithBMFont('font/small/common_text_num.fnt', '')
            allRecipeNum:setHorizontalAlignment(display.TAR)
            allRecipeNum:setPosition(60, 199)
            allRecipeNum:setAnchorPoint(cc.p(0, 1))
            view:addChild(allRecipeNum, 10)
            allRecipeNum:setTag(102)
            local shopWindowLimit = CommonUtils.GetConfigNoParser('restaurant','levelUp',gameMgr:GetUserInfo().restaurantLevel).shopWindowLimit
            shopWindowLimit = app.restaurantMgr:getCookCanScaleFoodsNum( shopWindowLimit )
            allRecipeNum:setString(string.fmt('_Num1_/_Num2_',{_Num1_ = num,_Num2_ = shopWindowLimit}))



            local maxNum = CommonUtils.GetConfigNoParser('restaurant','levelUp',gameMgr:GetUserInfo().restaurantLevel).sellFoodLimit
            for i=1,4 do

                -- local data = tempT[i]
                local v = CLayout:create(cc.size(80,80))
                v:setAnchorPoint(cc.p(0,0))
                v:setPosition(cc.p(233 + 90*(i-1),198 ))
                view:addChild(v,1)
                v:setTag(i)
                -- v:setBackgroundColor(cc.c4b(23, 67, 128, 128))
                v:setVisible(true)

                local recipeImg = display.newImageView(_res("avatar/ui/recipeMess/restaurant_ico_selling_foodempty.png"),v:getContentSize().width*0.5,v:getContentSize().height*0.5,--
                {ap = cc.p(0.5, 0.5)})
                recipeImg:setScale(1)
                v:addChild(recipeImg,1)
                recipeImg:setTag(5)
                local recipeNums = display.newLabel(v:getContentSize().width *0.5,-4,
                    { text = (' '),fontSize = 22,color = '7e6454', ap = cc.p(0.5, 1)})--2b2017
                v:addChild(recipeNums,1)
                recipeNums:setTag(6)

                local lockImg = display.newImageView(_res('ui/common/common_ico_lock.png'),v:getContentSize().width*0.5,v:getContentSize().height*0.5,--
                {ap = cc.p(0.5, 0.5)})
                v:addChild(lockImg,2)
                lockImg:setVisible(false)
                lockImg:setTag(7)

                if not tempT[i] then
                    if checkint(i) > checkint(maxNum) then
                        recipeNums:setString(__('未解锁'))
                        lockImg:setVisible(true)
                    else
                        recipeNums:setString(__('空'))
                    end
                else
                    local recipeId = tempT[i].recipeId
                    local recipeNum = tempT[i].recipeNum
                    local data = CommonUtils.GetConfig('goods','recipe',recipeId)
                    local iconId = CommonUtils.GetConfigNoParser('cooking','recipe',recipeId).foods[1].goodsId
                    recipeImg:setTexture(CommonUtils.GetGoodsIconPathById(iconId))
                    recipeImg:setScale(0.6)
                    recipeNums:setString(recipeNum)
                end
            end


            local tempLabel = display.newLabel(33,69,
                { text = __('服务员总新鲜度'),fontSize = 24,color = '5c5c5c', ap = cc.p(0, 0)})--2b2017
            view:addChild(tempLabel,1)

            local lineImg = display.newImageView(_res("avatar/ui/recipeMess/restaurant_ico_selling_line.png"), 33, 69,--
            {ap = cc.p(0, 0)})
            view:addChild(lineImg,3)



            local tempBg = display.newImageView(_res("avatar/ui/recipeMess/restaurant_ico_selling_frame.png"), 33, 69,--
            {ap = cc.p(0, 1)})
            view:addChild(tempBg,3)
            local tempImg = display.newImageView(_res("avatar/ui/recipeMess/restaurant_ico_selling_leaf.png"), 3, 3,--
            {ap = cc.p(0, 0)})
            tempBg:addChild(tempImg,3)


            local allWaiterVigourNum = cc.Label:createWithBMFont('font/small/common_text_num.fnt', '')
            allWaiterVigourNum:setHorizontalAlignment(display.TAR)
            allWaiterVigourNum:setPosition(60, 69)
            allWaiterVigourNum:setAnchorPoint(cc.p(0, 1))
            view:addChild(allWaiterVigourNum, 10)
            allWaiterVigourNum:setTag(103)

            local num = 0
            local vigourNum = 0
            local tempT = {}
            for k,v in pairs(self.waiterQueue) do
                local t = {}
                t.playerCardId = k
                t.vigour = checkint(v.vigour)
                local tempNum = app.restaurantMgr:getCardVigourLimit( k )
                vigourNum = vigourNum + tempNum
                num = num + checkint(v.vigour)
                table.insert(tempT,t)
            end

            allWaiterVigourNum:setString(string.fmt('_Num1_/_Num2_',{_Num1_ = num,_Num2_ = vigourNum}))

            local unlockMess = {}
            for i,v in ipairs(self.datas.employee) do
                unlockMess[tostring(v)] = v
            end
            -- dump(unlockMess)
            for i=5,8 do
                local v = CLayout:create(cc.size(80,80))
                v:setAnchorPoint(cc.p(0,0))
                v:setPosition(cc.p(233 + 90*(i-5),70 ))
                view:addChild(v,1)
                v:setTag(i)
                -- v:setBackgroundColor(cc.c4b(23, 67, 128, 128))
                v:setVisible(true)

                local waiterBg = display.newImageView(_res('ui/common/kapai_frame_bg_nocard.png'), v:getContentSize().width*0.5,v:getContentSize().height*0.5)
                waiterBg:setScale(0.42)
                v:addChild(waiterBg, 1)
                local waiterFrame = display.newImageView(_res('ui/common/kapai_frame_nocard.png'), waiterBg:getContentSize().width/2, waiterBg:getContentSize().height/2)
                waiterBg:addChild(waiterFrame)
                waiterBg:setTag(9)

                local waiterImg = display.newImageView(_res("avatar/ui/recipeMess/restaurant_ico_selling_cardempty.png"),v:getContentSize().width*0.5,v:getContentSize().height*0.5,--
                {ap = cc.p(0.5, 0.5)})
                v:addChild(waiterImg,1)
                waiterImg:setTag(10)
                waiterImg:setScale(0.42)
                waiterImg:setVisible(true)
                local vigourNums = display.newLabel(v:getContentSize().width *0.5,-4,
                    { text = (' '),fontSize = 22,color = '7e6454', ap = cc.p(0.5, 1)})--2b2017
                v:addChild(vigourNums,1)
                vigourNums:setTag(11)

                local lockImg = display.newImageView(_res('ui/common/common_ico_lock.png'),v:getContentSize().width*0.5,v:getContentSize().height*0.5,--
                {ap = cc.p(0.5, 0.5)})
                v:addChild(lockImg,2)
                lockImg:setVisible(false)
                lockImg:setTag(12)

                if not tempT[i-4] then
                    waiterImg:setVisible(false)
                    if not unlockMess[tostring(i-1)] then
                        vigourNums:setString(__('未解锁'))
                        lockImg:setVisible(true)
                    else
                        vigourNums:setString(__('空'))
                    end
                else
                    local playerCardId = tempT[i-4].playerCardId
                    local vigour = tempT[i-4].vigour
                    if gameMgr:GetCardDataById(playerCardId) then
                        local path = CardUtils.GetCardHeadPathBySkinId(gameMgr:GetCardDataById(playerCardId).defaultSkinId)
                        waiterImg:setTexture(path)
                    else
                        waiterImg:setVisible(false)
                    end

                    vigourNums:setString(tostring(vigour))
                end
            end
        else
            self.viewComponent:getChildByTag(99998):setVisible(true)
            local view = self.viewComponent:getChildByTag(99998):getChildByTag(8888)

            local num = 0
            local tempT = {}
            for k,v in pairs(self.datas.recipe) do
                local t = {}
                t.recipeId = k
                t.recipeNum = v
                table.insert(tempT,t)
                num = num + v
            end
            local maxNum = CommonUtils.GetConfigNoParser('restaurant','levelUp',gameMgr:GetUserInfo().restaurantLevel).sellFoodLimit
            for i=1,4 do
                local v = view:getChildByTag(i)
                local recipeImg = v:getChildByTag(5)
                recipeImg:setTexture(_res("avatar/ui/recipeMess/restaurant_ico_selling_foodempty.png"))
                recipeImg:setScale(1)
                local recipeNums = v:getChildByTag(6)
                local lockImg = v:getChildByTag(7)
                if not tempT[i] then
                    if checkint(i) > checkint(maxNum) then
                        recipeNums:setString(__('未解锁'))
                        lockImg:setVisible(true)
                    else
                        recipeNums:setString(__('空'))
                    end
                else
                    local recipeId = tempT[i].recipeId
                    local recipeNum = tempT[i].recipeNum
                    local data = CommonUtils.GetConfig('goods','recipe',recipeId)
                    local iconId = CommonUtils.GetConfigNoParser('cooking','recipe',recipeId).foods[1].goodsId
                    recipeImg:setTexture(CommonUtils.GetGoodsIconPathById(iconId))
                    recipeImg:setScale(0.6)
                    recipeNums:setString(recipeNum)
                end
            end

            local num1 = 0
            local vigourNum = 0
            local tempT = {}
            for k,v in pairs(self.waiterQueue) do
                local t = {}
                t.playerCardId = k
                t.vigour = checkint(v.vigour)
                local tempNum = app.restaurantMgr:getCardVigourLimit( k )
                vigourNum = vigourNum + tempNum
                num1 = num1 + checkint(v.vigour)
                table.insert(tempT,t)
            end

            local unlockMess = {}
            for i,v in ipairs(self.datas.employee) do
                unlockMess[tostring(v)] = v
            end

            for i=5,8 do
                local v = view:getChildByTag(i)
                local waiterBg = v:getChildByTag(9)
                local waiterImg = v:getChildByTag(10)
                waiterImg:setTexture(_res("avatar/ui/recipeMess/restaurant_ico_selling_cardempty.png"))
                waiterImg:setScale(0.42)
                local vigourNums = v:getChildByTag(11)
                local lockImg = v:getChildByTag(12)
                if not tempT[i-4] then
                    waiterImg:setVisible(false)
                    if not unlockMess[tostring(i-1)] then
                        vigourNums:setString(__('未解锁'))
                        lockImg:setVisible(true)
                    else
                        vigourNums:setString(__('空'))
                    end
                else
                    local playerCardId = tempT[i-4].playerCardId
                    local vigour = tempT[i-4].vigour
                    if gameMgr:GetCardDataById(playerCardId) then
                        local path = CardUtils.GetCardHeadPathBySkinId(gameMgr:GetCardDataById(playerCardId).defaultSkinId)
                        waiterImg:setTexture(path)
                    else
                        waiterImg:setVisible(false)
                    end

                    vigourNums:setString(tostring(vigour))
                end
            end
            local saleTimeNum = view:getChildByTag(101)
            saleTimeNum:setString(string.formattedTime(self:GetTimeForHangUp(),'%02i:%02i:%02i'))

            local allRecipeNum = view:getChildByTag(102)
            local shopWindowLimit = CommonUtils.GetConfigNoParser('restaurant','levelUp',gameMgr:GetUserInfo().restaurantLevel).shopWindowLimit
            shopWindowLimit = app.restaurantMgr:getCookCanScaleFoodsNum( shopWindowLimit )
            allRecipeNum:setString(string.fmt('_Num1_/_Num2_',{_Num1_ = num,_Num2_ = shopWindowLimit}))

            local allWaiterVigourNum = view:getChildByTag(103)
            allWaiterVigourNum:setString(string.fmt('_Num1_/_Num2_',{_Num1_ = num1,_Num2_ = vigourNum}))
        end
    -- end
end

--[[`
--刷新菜品销售情况
--]]
function AvatarMediator:UpDataNowRecipeNumAndMess()
    local num = 0
    local num1 = 0
    local vigourNum = 0
    local tempT = {}
    for k,v in pairs(self.datas.recipe) do
        local t = {}
        t.recipeId = k
        t.recipeNum = v
        table.insert(tempT,t)
        num = num + v
    end

    local tempTT = {}
    for k,v in pairs(self.waiterQueue) do
        local t = {}
        t.playerCardId = k
        t.vigour = checkint(v.vigour)
        local tempNum = app.restaurantMgr:getCardVigourLimit( k )
        vigourNum = vigourNum + tempNum
        num1 = num1 + checkint(v.vigour)
        table.insert(tempTT,t)
    end
    if self.viewComponent:getChildByTag(99998) then
        local view = self.viewComponent:getChildByTag(99998):getChildByTag(8888)
        local maxNum = CommonUtils.GetConfigNoParser('restaurant','levelUp',gameMgr:GetUserInfo().restaurantLevel).sellFoodLimit
        for i=1,4 do
            local v = view:getChildByTag(i)
            local recipeImg = v:getChildByTag(5)
            recipeImg:setTexture(_res("avatar/ui/recipeMess/restaurant_ico_selling_foodempty.png"))
            recipeImg:setScale(1)
            local recipeNums = v:getChildByTag(6)
            local lockImg = v:getChildByTag(7)

            if not tempT[i] then
                if checkint(i) > checkint(maxNum) then
                    recipeNums:setString(__('未解锁'))
                    lockImg:setVisible(true)
                else
                    recipeNums:setString(__('空'))
                    lockImg:setVisible(false)
                end
            else
                local recipeId = tempT[i].recipeId
                local recipeNum = tempT[i].recipeNum
                local data = CommonUtils.GetConfig('goods','recipe',recipeId)
                local iconId = CommonUtils.GetConfigNoParser('cooking','recipe',recipeId).foods[1].goodsId
                recipeImg:setTexture(CommonUtils.GetGoodsIconPathById(iconId))
                recipeImg:setScale(0.6)
                recipeNums:setString(recipeNum)
                lockImg:setVisible(false)
            end
        end





        local unlockMess = {}
        for i,v in ipairs(self.datas.employee) do
            unlockMess[tostring(v)] = v
        end

        for i=5,8 do
            local v = view:getChildByTag(i)
            local waiterBg = v:getChildByTag(9)
            local waiterImg = v:getChildByTag(10)
            waiterImg:setTexture(_res("avatar/ui/recipeMess/restaurant_ico_selling_cardempty.png"))
            waiterImg:setScale(0.42)
            local vigourNums = v:getChildByTag(11)
            local lockImg = v:getChildByTag(12)
            if not tempTT[i-4] then
                waiterImg:setVisible(false)
                if not unlockMess[tostring(i-1)] then
                    vigourNums:setString(__('未解锁'))
                    lockImg:setVisible(true)
                else
                    vigourNums:setString(__('空'))
                    lockImg:setVisible(false)
                end
            else
                local playerCardId = tempTT[i-4].playerCardId
                local vigour = tempTT[i-4].vigour
                if gameMgr:GetCardDataById(playerCardId) then
                    local path = CardUtils.GetCardHeadPathBySkinId(gameMgr:GetCardDataById(playerCardId).defaultSkinId)
                    waiterImg:setTexture(path)
                    waiterImg:setVisible(true)
                    lockImg:setVisible(false)
                else
                    waiterImg:setVisible(false)
                    lockImg:setVisible(true)
                end
                vigourNums:setString(tostring(vigour))
            end
        end

        local allRecipeNum = view:getChildByTag(102)
        local shopWindowLimit = CommonUtils.GetConfigNoParser('restaurant','levelUp',gameMgr:GetUserInfo().restaurantLevel).shopWindowLimit
        shopWindowLimit = app.restaurantMgr:getCookCanScaleFoodsNum( shopWindowLimit )
        allRecipeNum:setString(string.fmt('_Num1_/_Num2_',{_Num1_ = num,_Num2_ = shopWindowLimit}))

        local allWaiterVigourNum = view:getChildByTag(103)
        allWaiterVigourNum:setString(string.fmt('_Num1_/_Num2_',{_Num1_ = num1,_Num2_ = vigourNum}))
    end


    for i,v in ipairs(self.viewComponent.viewData.someThingMess) do
        if i == 1 then
            v:setString(num1)
        elseif i == 2 then
            v:setString(num)
        elseif i == 3 then
            if self:GetTimeForHangUp() > 3600 then
                v:setString(math.floor(self:GetTimeForHangUp()/3600)..__('小时'))
            else
                v:setString(math.floor(self:GetTimeForHangUp()/60)..__('分钟'))
            end
        end
    end


    -----------刷新餐厅信息页面------------
    if AppFacade.GetInstance():RetrieveMediator('LobbyInformationMediator') then
        local mediator = AppFacade.GetInstance():RetrieveMediator('LobbyInformationMediator')
        if mediator and mediator.showLayer['1001'] then
            mediator.showLayer['1001']:RefreshUI()
        end
    end
    -----------刷新餐厅信息页面------------
end

--[[
--全局buf详情
--]]
function AvatarMediator:ShowRandomBuffMess()
    if gameMgr:GetUserInfo().avatarCacheData.events and table.nums(gameMgr:GetUserInfo().avatarCacheData.events) > 0 then
    -- if table.nums(self.datas.recipe) <= 0 then
        -- uiMgr:ShowInformationTips(__('没有已制作的菜品'))
    --     dump(self.datas.recipe)
        if not self.viewComponent:getChildByTag(99997) then
            -- dump(uiMgr:GetCurrentScene())
            local cview = CLayout:create(display.size)
            -- display.commonUIParams(cview, {ap = cc.p(0.5,0.5), po = cc.p(display.size.width*0.5,display.size.height*0.5)})
            cview:setAnchorPoint(display.CENTER)
            cview:setPosition(cc.p(display.cx + display.SAFE_L, display.cy))
            self.viewComponent:addChild(cview,100)
            cview:setTag(99997)
            -- cview:setBackgroundColor(cc.c4b(23, 67, 128, 128))

            local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 0))
            eaterLayer:setTouchEnabled(true)
            eaterLayer:setContentSize(display.size)
            eaterLayer:setAnchorPoint(cc.p(0,0))
            eaterLayer:setPosition(cc.p(0, 0))
            cview:addChild(eaterLayer, -1)


            eaterLayer:setOnClickScriptHandler(function( sender )
                if self.viewComponent:getChildByTag(99997) then
                    self.viewComponent:getChildByTag(99997):setVisible(false)
                end
            end)
            local size = cc.size(362,160)
            local view = CLayout:create(size)
            display.commonUIParams(view, {ap = cc.p(0,0), po = cc.p(382,120)})
            cview:addChild(view,10)
            view:setTag(8888)
            -- view:setBackgroundColor(cc.c4b(0, 0, 0, 140))

            local bg = display.newImageView(_res("ui/common/common_bg_tips.png"),size.width * 0.5,  size.height*0.5,--
            {ap = cc.p(0.5, 0.5),scale9 = true,size = size})
            view:addChild(bg)


            local tempLabel1 = display.newLabel(20,size.height - 10,
                {text = ('剩余剩余剩余剩余'),fontSize = 24,color = '5c5c5c', ap = cc.p(0, 1),w = size.width - 30,h = size.height*0.8})--2b2017
            view:addChild(tempLabel1,1)



            local tempLabel2 = display.newLabel(10,4,
                { text = (' '),fontSize = 24,color = '5c5c5c', ap = cc.p(0, 0)})--2b2017
            view:addChild(tempLabel2,1)

            local lineImg = display.newImageView(_res("ui/home/lobby/cooking/kitchen_tool_split_line.png"), size.width * 0.5, 34,--
            {ap = cc.p(0.5, 0)})    --630, size.height - 20
            view:addChild(lineImg,3)


            if gameMgr:GetUserInfo().avatarCacheData.events and table.nums(gameMgr:GetUserInfo().avatarCacheData.events) > 0 then
                -- dump(gameMgr:GetUserInfo().avatarCacheData.events)
                local head = gameMgr:GetUserInfo().avatarCacheData.events[1]
                if head then
                    local eventInfo = CommonUtils.GetConfigNoParser('restaurant', 'event', head.eventId)
                    -- dump(eventInfo)
                    if eventInfo and eventInfo.descr then
                        tempLabel1:setString(eventInfo.descr)
                        -- tempLabel2:setString(string.formattedTime(checkint(head.leftSeconds),'剩%02i:%02i:%02i结束'))
                    end
                end
            end

        else
            self.viewComponent:getChildByTag(99997):setVisible(true)
            local view = self.viewComponent:getChildByTag(99997):getChildByTag(8888)
        end
    end
end


--[[
更新任务按钮状态
@params leftSeconds int  剩余秒数
--]]
function AvatarMediator:UpdateTaskButtonStatus( leftSeconds )
    if leftSeconds and checkint(leftSeconds) > 0 and checkint(leftSeconds) < 600 then
        leftSeconds = leftSeconds + 3
    end
    if leftSeconds then
        self.datas.nextRestaurantTaskLeftSeconds = leftSeconds
    end
    local bottomView = self:GetViewComponent().viewData.bottomView
    if bottomView:getChildByTag(2323) then
        bottomView:getChildByTag(2323):runAction(cc.RemoveSelf:create())
    end
    if self.datas.nextRestaurantTaskLeftSeconds > 0 then
        local taskTimeBg = display.newImageView(_res('ui/home/lobby/cooking/restaurant_main_bg_task_time.png'), display.cx + 46, 56, {tag = 2323})
        bottomView:addChild(taskTimeBg, 10)
        local taskTimeLabel = cc.Label:createWithBMFont('font/common_num_2.fnt', string.formattedTime(checkint(self.datas.nextRestaurantTaskLeftSeconds),'%02i:%02i:%02i'))
        taskTimeLabel:setHorizontalAlignment(display.TAR)
        taskTimeLabel:setScale(0.8)
        taskTimeLabel:setPosition(utils.getLocalCenter(taskTimeBg))
        taskTimeBg:addChild(taskTimeLabel)
        self.taskUpdateFunc = scheduler.scheduleGlobal(function(dt)
            if not self.isStop then
                self.datas.nextRestaurantTaskLeftSeconds = self.datas.nextRestaurantTaskLeftSeconds - 1
                if self.datas.nextRestaurantTaskLeftSeconds > 0 then
                    taskTimeLabel:setString(string.formattedTime(checkint(self.datas.nextRestaurantTaskLeftSeconds),'%02i:%02i:%02i'))
                else
                    self:SendSignal(COMMANDS.COMMAND_GET_TASK)
                    if bottomView:getChildByTag(2323) then
                        bottomView:getChildByTag(2323):runAction(cc.RemoveSelf:create())
                    end
                    scheduler.unscheduleGlobal(self.taskUpdateFunc)
                end
            end
        end, 1.0)
    else
        if #self.datas.restaurantTasks == 1 and checkint(self.datas.restaurantTasks[1].progress) == checkint(self.datas.restaurantTasks[1].targetNum) then
            bottomView:removeChildByName('TASK_RED_HEAT')
            local redIcon = display.newImageView(_res('ui/common/common_hint_circle_red_ico.png'), display.cx + (742 - 1334/2), 86,{tag = 2323})
            redIcon:setName("TASK_RED_HEAT")
            bottomView:addChild(redIcon, 10)
        end
    end
end
--[[
更新信息按钮状态(小红点)
--]]
function AvatarMediator:UpdateInformationButtonStatus()
    local canUpgrade = true
    local nextLevel = checkint(gameMgr:GetUserInfo().restaurantLevel)
    local levelConfigs = CommonUtils.GetConfigAllMess('levelUp', 'restaurant')
    if (nextLevel + 1) > table.nums(levelConfigs) then
        nextLevel = nextLevel
    else
        nextLevel = nextLevel + 1
    end
    local upgradeDatas = CommonUtils.GetConfigNoParser('restaurant', 'levelUp', nextLevel)
    if checkint(gameMgr:GetUserInfo().popularity) < checkint(upgradeDatas.popularity) then
        canUpgrade = false
    end
    for i,v in ipairs(upgradeDatas.consumeGoods) do
        if v.goodsId == GOLD_ID then
            if gameMgr:GetUserInfo().gold < v.num then
                canUpgrade = false
            end
        else
            local hasNum = gameMgr:GetAmountByGoodId(v.goodsId)
            if hasNum < v.num then
                canUpgrade = false
            end
        end
    end
    -- 如果可升级，添加小红点
    local bottomView = self:GetViewComponent().viewData.bottomView
    if canUpgrade then
        if bottomView:getChildByName('INFORMATION_RED_HEAT') then
            bottomView:removeChildByName('INFORMATION_RED_HEAT')
        end
        local redIcon = display.newImageView(_res('ui/common/common_hint_circle_red_ico.png'), display.cx + (1122 - 1334/2), 86,{tag = 2324})
        redIcon:setName("INFORMATION_RED_HEAT")
        bottomView:addChild(redIcon, 10)
    else
        if bottomView:getChildByName('INFORMATION_RED_HEAT') then
            bottomView:removeChildByName('INFORMATION_RED_HEAT')
        end
    end
end

function AvatarMediator:UpdateAvatarRenovationRemind(showRemind)
    local decorateView = self:GetViewComponent():getChildByName("DecorateView")
    local gotoAvatarButton = self:GetViewComponent().viewData.gotoAvatarButton

    local function updateRemindState(node)
        local redPointIcon = node:getChildByName("redPointIcon")
        if redPointIcon then
            redPointIcon:setVisible(checkbool(showRemind))
        end
    end

    if decorateView then
        decorateView:updateShopButtonTip(checkbool(showRemind))
    end

    if gotoAvatarButton then
        updateRemindState(gotoAvatarButton)
    end
end

function AvatarMediator:UpdateAvatarTopBtnLayer()
    local layer = self:GetViewComponent().viewData.avatarTopBtnLayer
    if layer:getChildrenCount() > 0 then
        layer:removeAllChildren()
    end

    local btnsData = {}
    local isUnlockAgentShopowner = CommonUtils.UnLockModule(RemindTag.LOBBY_AGENT_SHOPOWNER)
    -- if isUnlockAgentShopowner then
    local managerLeftSeconds = checkint(self.datas.managerLeftSeconds)
    local isCreateCoundownTip = managerLeftSeconds > 0
    local namePath = _res('avatar/ui/agentShopowner/restaurant_btn_agent_active.png')
    local iconData = {
        img = isCreateCoundownTip and RestaurantUtils.GetLobbyAgentShopOwnerIconByMangerId(self.datas.mangerId) or _res('avatar/ui/agentShopowner/restaurant_btn_agent_inactive.png'),
        offset = cc.p(0, -5),
        scale = isCreateCoundownTip and 0.4 or 1,
    }
    if CommonUtils.GetModuleAvailable(MODULE_SWITCH.MANAGER) then
        table.insert(btnsData, {
            namePath = namePath,
            font = __('代理店长'),
            tag = RemindTag.LOBBY_AGENT_SHOPOWNER,
            isCreateTip = false,
            isCreateCoundownTip = isCreateCoundownTip,
            countdown = managerLeftSeconds,
            iconData = iconData,
            fontSize = 20 ,
            width = 100 ,
            isNeedLock = not isUnlockAgentShopowner
        })
    end
    -- end


    if app.activityMgr:isOpenLobbyFestivalActivity() then
        local data = {namePath = _res('avatar/ui/restaurant_btn_festival'), font = __('餐厅节日'), tag = RemindTag.LOBBY_FESTIVAL_ACTIVITY, isCreateTip = false, isCreateCoundownTip = true}
        local leftSeconds = gameMgr:GetUserInfo().restaurantActivity.leftSeconds
        if gameMgr:GetUserInfo().restaurantActivity.leftSeconds > 0 then
            data.countdown = leftSeconds
        end
        table.insert(btnsData, data)
    end

    if app.activityMgr:isOpenLobbyFestivalPreviewActivity() then
        local data = {namePath = _res('avatar/ui/restaurant_btn_festival_notice'), font = __('节日预告'), tag = RemindTag.LOBBY_FESTIVAL_ACTIVITY_PREVIEW, isCreateTip = false, isCreateCoundownTip = false}
        table.insert(btnsData, data)
    end

    local btnLayouts = {}
    if #btnsData > 0 then
        local layerSize = cc.size(#btnsData * 150, 110)
        layer:setContentSize(layerSize)

        for i,v in ipairs(btnsData) do
            local tag = v.tag
            local btnLayout = CommonUtils.CreateTopIcon(btnsData[i])
            local btn = btnLayout:getChildByTag(tag)
            display.commonUIParams(btn, {cb = handler(self, self.ButtonActions)})
            display.commonUIParams(btnLayout, {po = cc.p(layerSize.width - 50 - (i - 1) * 150, 102)})
            layer:addChild(btnLayout)

            btnLayouts[tostring(tag)] = btnLayout
        end

        self.avatarTopBtns = btnLayouts
    end

end

function AvatarMediator:StartAgentShopownerCountDown(leftSeconds)
    if leftSeconds then
        self.datas.managerLeftSeconds = checkint(leftSeconds)
    end
    local managerLeftSeconds = checkint(self.datas.managerLeftSeconds)
    local timeName = NAME .. RemindTag.LOBBY_AGENT_SHOPOWNER
    local timerInfo = timerMgr:RetriveTimer(timeName)
    if managerLeftSeconds > 0 then
        -- 如果有则更新倒计时
        if timerInfo then
            timerInfo.countdown = managerLeftSeconds
        else
            timerMgr:AddTimer({name = timeName, countdown = managerLeftSeconds, tag = RemindTag.LOBBY_AGENT_SHOPOWNER})
        end
    else
        if timerInfo then
            timerMgr:RemoveTimer(timeName)
        end
    end
end

function AvatarMediator:removeBugAt(bugAreaId)
    for i = #self.bugQueue, 1, -1 do
        if checkint(bugAreaId) == checkint(self.bugQueue[i]) then
            table.remove(self.bugQueue, i)
            break
        end
    end

    self:GetViewComponent():removeBugAt(bugAreaId)
end

function AvatarMediator:uploadFriendVisitLog()
    local socketManager   = AppFacade.GetInstance():GetManager('SocketManager')
    local friendVisitId   = checkint(gameMgr:GetUserInfo().avatarFriendId_)
    local friendVisitData = checktable(gameMgr:GetUserInfo().avatarFriendVisitData_)
    if friendVisitId > 0 then
        if next(friendVisitData) == nil then
            friendVisitData[tostring(AVATAR_FRIEND_MESSAGE_TYPE.TYPE_NORMAL)] = true
        end
        for visitId, _ in pairs(friendVisitData) do
            socketManager:SendPacket(NetCmd.FRIEND_RESTUARANT_LOG, {friendId = friendVisitId, type = checkint(visitId)})
        end
    end
    gameMgr:GetUserInfo().avatarFriendVisitData_ = nil
end
function AvatarMediator:UpdateScheduleMap()
    for i,v in pairs(self.recipeCdUpdateFunc) do
        if v then
            scheduler.unscheduleGlobal(v)
        end
    end
    for k,v in pairs(self.datas.recipeCooking) do
        local employeeId = 2
        for kk,vv in pairs(gameMgr:GetUserInfo().chef) do
            if checkint(k) == checkint(vv) then
                employeeId = kk
                break
            end
        end
        if checkint(v.cd) <= 0 then
            self:SendSignal(COMMANDS.COMMANDS_Home_RecipeCookingDone,{employeeId = employeeId})
        else
            local index = 1
            if checkint(employeeId) == 2 then
                index = 1
            elseif checkint(employeeId) == 3 then
                index = 2
            end
            local updateFunc = self.recipeCdUpdateFunc[tostring(index)]
            if updateFunc then scheduler.unscheduleGlobal(updateFunc) end
            v.startTime = os.time()
            self.recipeCdUpdateFunc[tostring(index)] = scheduler.scheduleGlobal(function(dt)
                --事件的计时器
                local curTime = os.time()
                local deltaTime = (curTime - v.startTime)
                if deltaTime >= 1.0 then
                    --事件的计时器
                    v.startTime = curTime
                    v.cd = checkint(v.cd) - math.floor(deltaTime)
                    if checkint(v.cd) <= 0 then
                        scheduler.unscheduleGlobal(self.recipeCdUpdateFunc[tostring(index)])
                        self:SendSignal(COMMANDS.COMMANDS_Home_RecipeCookingDone,{employeeId = employeeId})
                    else
                        --更新cooking页面的计时器的逻辑
                        AppFacade.GetInstance():DispatchObservers('COOKING_TIME_COUNT', {index = index})
                    end
                end
            end,1.0)
        end
    end
end


function AvatarMediator:removeAvatar_(avatarData)
    --是否刷新底部装饰面板的数量的逻辑
    local decorateView = self.viewComponent:getChildByName('DecorateView')
    if avatarData.isRepeat then
        --移除屋顶灯
        local id = checkint(avatarData.goodsUuid)

        if not avatarData.isRetain then
            gameMgr:DeleteAvatarLocalLocation(id)
        end
        --移除部件
        local node = self.viewComponent.viewData.view:getChildByName('OrderTags.CEIL_TAG')
        if node then
            node:removeFromParent()
        end
    else
        local node = self.viewComponent.viewData.view:getChildByName('HandleNode')
        if node then node:VisibleState(false) end
        --需要清除对应的座位缓存
        local id = checkint(avatarData.goodsUuid)
        if not avatarData.isRetain then
            gameMgr:DeleteAvatarLocalLocation(id)
        end
        --移除部件
        local avatarId = checkint(avatarData.goodsId)
        local avatarLocationConfig = CommonUtils.GetConfigNoParser('restaurant', 'avatarLocation', avatarId)
        if checkint(avatarLocationConfig.additionNum) > 0 then
            for i=1,checkint(avatarLocationConfig.additionNum) do
                --拿到seatId
                local seatId = string.format('%d_%d', checkint(id), i)
                self:ClearCacheSeat(seatId)
            end
        end

        local children = self.viewComponent.viewData.view:getChildren()
        for idx,val in ipairs(children) do
            if val.name and val.name == 'DragNode' and checkint(val.id) == checkint(avatarData.goodsUuid) then
                --更新可走动的点的逻辑
                val:removeFromParent()
                --队列移除的逻辑
                break
            end
        end
        self:UpdateAllBlocks()

        if decorateView then
            decorateView:setSelectedAvatarId(0)
        end
    end
    --是否刷新底部装饰面板的数量的逻辑
    if decorateView then
        decorateView:freshAvatarList()
    end
end

return AvatarMediator

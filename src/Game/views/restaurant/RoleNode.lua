local RoleNode = class('RoleNode', function()
    local node = CLayout:create()
    node:enableNodeEvents()
    node.name = 'RoleNode'
    return node
end)

--通用实例
local shareFacade = AppFacade.GetInstance()
local gameMgr = shareFacade:GetManager("GameManager")
local cardMgr = shareFacade:GetManager("CardManager")

local socketMgr = shareFacade:GetManager('SocketManager')

local ServiceType = {
    IDLE = 100, --空闲状态是否可以进行一些其他的操作
    BUSY = 200, --忙的状态
    SWEEP = 300, --打扫的状态
    STOP = 400, --停止动作
    WALKING = 500, --走动状态
}

-- local DEFAULT_VELOCITY = 5 -- 5px

local TIME_INTERVAL = 0.15

local TILED_SIZE = RESTAURANT_TILED_SIZE

local RoleType = RESTAURANT_ROLE_TYPE

local EXPRESSION_TAG_NAME = 'EXPRESSION_TAG_NAME'

function RoleNode:ctor(...)
    local args = unpack({...})
    self.id = args.id --对应的id值用来判断是创建哪个npc
    self.avatarId = args.avatarId --资源图片取的id值
    self.seatId = args.seatId --凳子id 字符串
    self.npcType = args.nType
    self.destination = (args.destination or {}) --当前要到终点的位置
    self.serviceState = ServiceType.IDLE --当前的服务状态，是否在服务
    self.reverse = false
    self.startCountDown = false --是否开始计时器
    self.canTouch = true --是否可点击
    self.isLeave = false --是否是服务完离开的状态的逻辑

    self.isServing = 0 --表示在空闲状态可用去服务

    self.pathObj = nil
    self.skinId_ = args.skinId
    self.friendData_ = args.friendData

    local touchNode = CColorView:create(cc.c4b(100,100,100,0))
    touchNode:setPosition(utils.getLocalCenter(self))
    self:addChild(touchNode)
    touchNode:setTouchEnabled(true)
    if self.npcType == RoleType.Waiters then
        -- touchNode:setTouchEnabled(true)
        touchNode:setOnClickScriptHandler(handler(self, self.WaiterClickAction))
    end
    self.touchView = touchNode

    if self.npcType == RoleType.Waiters then
        local size = cc.size(120, 180)
        self:setContentSize(size)
        touchNode:setContentSize(size)
        touchNode:setPosition(utils.getLocalCenter(self))
        --服务员的逻辑
        local shareKey = tostring(self.skinId_)
        self:setTag(checkint(self.id))
        self:setUserTag(checkint(self.id))
        local role = nil
        local shareSpineCache = SpineCache(SpineCacheName.GLOBAL)
        if shareSpineCache:hasSpineCacheData(shareKey) then
            role = AssetsUtils.GetCardSpineNode({skinId = self.skinId_, scale = 0.4, cacheName = SpineCacheName.GLOBAL, spineName = shareKey})
        else
            role = AssetsUtils.GetCardSpineNode({skinId = self.skinId_, scale = 0.4})
        end
        role:setToSetupPose()
        role:setAnimation(0, 'idle', true)
        display.commonUIParams(role, {po = cc.p(size.width * 0.5, 0)})
        self:addChild(role,10)
        self.role = role

    elseif self.npcType == RoleType.Visitors then
        local size = cc.size(120, 180)
        self:setContentSize(size)
        touchNode:setContentSize(size)
        touchNode:setPosition(utils.getLocalCenter(self))
        local pathPrefix = string.format("avatar/visitors/%s", tostring(self.avatarId))
        if FTUtils:isPathExistent(string.format("%s.json", pathPrefix)) then
            local role = sp.SkeletonAnimation:create(string.format("%s.json", pathPrefix),string.format('%s.atlas', pathPrefix), 0.35)
            role:setToSetupPose()
            role:setAnimation(0, VISITOR_STATES.RUN.name, true)
            display.commonUIParams(role, {po = cc.p(size.width * 0.5, 0)})
            self:addChild(role,10)
            self.role = role
        end
    end
end

function RoleNode:DoorWaitingVisitor()
    local actionMgr = cc.Director:getInstance():getActionManager()
    actionMgr:removeActionByTag(200, self)
    local seq = cc.Sequence:create(cc.DelayTime:create(1.0),cc.CallFunc:create(function()
        if not self.isLeave then
            if self.startCountDown then
                --开始计时
                self:CountDownAction()
            end
        end
    end))
    local action = cc.RepeatForever:create(seq)
    action:setTag(200)
    self:runAction(action)
end


function RoleNode:LeaveAction(isLeave)
    if isLeave == nil then isLeave = false end
    self.isLeave = isLeave
    if self.isLeave then
        self.serviceState = ServiceType.WALKING --停止其他动作更新
        if self.role then
            self.role:setScaleX(-1)
        end
        if self.npcType == RoleType.Waiters then
            self.destination = self.startPos
            if self.role then
                self.role:setAnimation(0,'run', true)
            end
            self:FreshSearchPath()
        elseif self.npcType == RoleType.Visitors then
            self.destination = cc.p(256 + 300,8 + TILED_SIZE* 10)
            self:FreshSearchPath()
        end
    end
end
--[[
--调整服务员点击的相关处理
--]]
function RoleNode:WaiterClickAction(sender)
    PlayAudioByClickNormal()
    if self.friendData_ then
        local AvatarFeedMediator = require( 'Game.mediator.AvatarFeedMediator')
        local delegate = AvatarFeedMediator.new({id = self.avatarId, type = 1, friendData = self.friendData_})
        AppFacade.GetInstance():RegistMediator(delegate)
    else
        local mediator = AppFacade.GetInstance():RetrieveMediator('AvatarMediator')
        local cardInfo = gameMgr:GetCardDataByCardId(self.id)
        if mediator and mediator:CheckWaiterCanSwitch(cardInfo.id) == 1 then
            local cardInfo = gameMgr:GetCardDataByCardId(self.id)
            local AvatarFeedMediator = require( 'Game.mediator.AvatarFeedMediator')
            local delegate = AvatarFeedMediator.new({id = cardInfo.id, type = 1})
            AppFacade.GetInstance():RegistMediator(delegate)
            mediator:SetClickCardId(cardInfo.id)
        end
    end
end

function RoleNode:UpdateDestination(pos, seatId)
    if pos.x ~= self.destination.x and pos.y ~= self.destination.y then
        self.destination = pos --设置新的位置点
        self.seatId = seatId --
        --然后走过去
        self:FreshSearchPath()
    end
end


--[[
--单独刷新重绘下路径
--]]
function RoleNode:FreshSearchPath()
    if self.destination and checkint(self.destination.x) >= 8 and checkint(self.destination.y) >= 8 then
        local mediator = AppFacade.GetInstance():RetrieveMediator('AvatarMediator')
        if mediator then
            local x,y = self:getPosition()
            self.pathObj = mediator:SearchPath(cc.p(x,y),self.destination,false)
            if self.pathObj then
                if self.npcType == RoleType.Waiters and self.role then
                    self.role:setAnimation(0,'run', true)
                    if self.role:getChildByName(EXPRESSION_TAG_NAME) then
                        self.role:removeChildByName('EXPRESSION_TAG_NAME')
                    end
                end
                self.serviceState = ServiceType.WALKING
                if self.npcType == RoleType.Waiters then
                    self.isServing = 1
                end

                --启动行走的动作
                local len  = table.nums(self.pathObj)
                local interval = TIME_INTERVAL
                if len >= 24 then
                    interval = math.floor(6 / len)
                end
                local actionMgr = cc.Director:getInstance():getActionManager()
                actionMgr:removeActionByTag(300, self)
                local seq = cc.Sequence:create(cc.DelayTime:create(interval),cc.CallFunc:create(handler(self, self.Update)))
                local action = cc.RepeatForever:create(seq)
                action:setTag(300)
                self:runAction(action)
            end
        end
    end
end

--[[
--是否显示表情的逻辑
--存在倒计时
--]]
function RoleNode:WillShowExpression()
    if self.npcType == RoleType.Waiters and self.role then
        self:VigourState()
    end
end


function RoleNode:SwitchToNewCustomer()
    self.serviceState = ServiceType.STOP --停止其他动作更新
    self.isLeave = false --禁用离开的逻辑,可能需要直接去服务新的人
    if self:IsInWalking() then
        --正在行走中的逻辑
        self.pathObj:clear()
        if self.npcType == RoleType.Waiters then
            if self.role then
                self:setLocalZOrder(200) --防止表情挡的问题
                self.role:setAnimation(0,'idle', true)
                self:WillShowExpression()
            end
        end
    end
end

--[[
--停止行走的逻辑，用来突然切到装修时人物需要不显示的逻辑
--]]
function RoleNode:AbortWalking()
    self.serviceState = ServiceType.STOP --停止其他动作更新
    if self:IsInWalking() then
        --正在行走中的逻辑
        self.pathObj:clear()
        if self.npcType == RoleType.Waiters then
            --服务员
            self:setVisible(false)
            if self.role then
                self:setLocalZOrder(200) --防止表情挡的问题
                self.role:setAnimation(0,'idle', true)
                self:WillShowExpression()
            end

        elseif self.npcType == RoleType.Visitors then
            --客人需要直接移除的逻辑
            self:setVisible(false)
            self:runAction(cc.RemoveSelf:create())
        end
    else
        self:setVisible(false)
    end
    if self.npcType == RoleType.Waiters then
        self.isServing = 0
    end
end

function RoleNode:IsInWalking()
    local isWalking = false
    --是否正在走路中
    if self.pathObj and table.nums(self.pathObj:getWayPoints()) > 0 then
        --正在行走中的逻辑
        if self.serviceState == ServiceType.WALKING then
            isWalking = true
        else
            --防止未清除的逻辑
            self.pathObj:clear()
        end
    end
    return isWalking
end

function RoleNode:StopWaiter()
    self.serviceState = ServiceType.STOP --停止其他动作更新
    --行走完成后产生一个消息事件比如食客上桌子上
    if self.pathObj then
        self.pathObj:clear()
    end
    if self.reverse then
        self.reverse = false
        self.serviceState = ServiceType.WALKING --停止其他动作更新
        self.destination = self.startPos
        self:FreshSearchPath()
    else
        if self.npcType == RoleType.Visitors then
            self:runAction(cc.Sequence:create(cc.Hide:create(),cc.RemoveSelf:create()))
        else
            if self.npcType == RoleType.Waiters and self.role then
                self.isLeave = false --状态还原
                self.role:setAnimation(0,'idle', true)
            end
        end
    end
    if self.npcType == RoleType.Waiters then
        self.isServing = 0
    end
end

function RoleNode:Update(dt)
    -- if self.serviceState == ServiceType.WALKING then return end
    if self.serviceState == ServiceType.WALKING then
        --可以走到指定的位置
        if self.pathObj then
            if not self.pathObj:finished() then
                local block = self.pathObj:currentWayPoint()
                local tile = RestaurantUtils.ConvertPixelsToTiled(block)
                self.pathObj:goToNextWayPoint()
                local nextBlock = self.pathObj:currentWayPoint()
                if self.role then
                    if nextBlock and block then
                        if nextBlock.x >= block.x then
                            self.role:setScaleX(1)
                        else
                            self.role:setScaleX(-1)
                        end
                    else
                        self.role:setScaleX(1)
                    end
                else
                    self.pathObj:clear()
                end
                if block then
                    self:runAction(cc.Sequence:create(cc.MoveTo:create(TIME_INTERVAL,cc.p(block.x,block.y)),cc.CallFunc:create(function()
                        self:setLocalZOrder(RESTAURANT_TILED_HEIGHT - tile.h)
                    end)))
                end
            else
                if self.isLeave then
                    --如果是人物离开的逻辑
                    self.serviceState = ServiceType.STOP --停止其他动作更新
                    self.pathObj:clear()
                    if self.npcType == RoleType.Visitors then
                        --食客
                        self:runAction(cc.Sequence:create(cc.Hide:create(),cc.RemoveSelf:create()))
                    else
                        --服务员
                        if self.npcType == RoleType.Waiters and self.role then
                            self.isLeave = false --离开结束了 要进去正常的状态了服务员
                            local tile = RestaurantUtils.ConvertPixelsToTiled(self.startPos)
                            self:setLocalZOrder(200 + (TILED_SIZE - tile.h)) --防止表情挡的问题
                            self.role:setAnimation(0,'idle', true)
                            self:WillShowExpression()
                            --服务员回到初始位置,serving状态改为0
                            self.isServing = 0 --可用状态
                            local mediator = shareFacade:RetrieveMediator('AvatarMediator')
                            if mediator then
                                print('---------------------->>>服务下一个客人的请求------------>>')
                                mediator:PushRequestQueue(6007) --开始服务下一个客人的逻辑
                            end
                        end
                    end
                else
                    --正常去服务的逻辑
                    self:StopWaiter()
                    if self.npcType == RoleType.Visitors then
                        shareFacade:DispatchObservers(RESTAURANT_EVENTS.EVENT_DESTINATION, {seatId = self.seatId, id = self.id, npcType = self.npcType})
                    else
                        --如果是服务员到达
                        shareFacade:DispatchObservers(RESTAURANT_EVENTS.EVENT_DESTINATION, {seatId = self.seatId, id = self.id, npcType = self.npcType})
                    end
                end
            end
        end
    end
end



--[[
--计时器数据的逻辑功能
--]]
function RoleNode:CountDownAction()
    if self.npcType == RoleType.Visitors then
        --食客
        local leftSeconds = tonumber(self.datas.leftSeconds)
        leftSeconds = leftSeconds - 1.0
        if leftSeconds <= 0 then leftSeconds = 0 end
        self.datas.leftSeconds = leftSeconds
        if leftSeconds == 0 then
            --移除自已，然后发送离开的请求，并清除食客队列的数据
            self.startCountDown = false
            self.canTouch = false --禁用可能的点击
            -- local seatId = checkint(self.datas.seatId)
            local seatId = self.datas.seatId
            local mediator = shareFacade:RetrieveMediator('AvatarMediator')
            if mediator then
                if seatId then
                    if not mediator.servicingQueue[seatId].waiterId then
                        --没有服务员服务才能离开的逻辑
                        mediator.servicingQueue[seatId].hasCustomer = 0
                        socketMgr:SendPacket(NetCmd.CustomerLeave,{seatId = seatId})
                        self:runAction(cc.Spawn:create(cc.Hide:create(), cc.RemoveSelf:create()))
                    else
                        self.canTouch = true
                    end
                else
                    --等待的人离开时
                    --不存在空位的时候方可离开
                    mediator:PopVisitorQueue()
                    socketMgr:SendPacket(NetCmd.CustomerLeave)
                    self:runAction(cc.Sequence:create(cc.CallFunc:create(function()
                        self:ShowExpression(7)
                    end), cc.DelayTime:create(2),cc.CallFunc:create(function()
                    --执行离开的动作
                    self:LeaveAction(true)
                end)))
            end
        end
        end
    else
    end
end


function RoleNode:onEnter()
    local x, y = self:getPosition()
    local tile = RestaurantUtils.ConvertPixelsToTiled(cc.p(x,y))
    self:setLocalZOrder(RESTAURANT_TILED_HEIGHT - tile.h)
    self.startPos = cc.p(x,y) --起点的tile点
    -- self:VigourState() --检测显示人物的动态
end

--[[
--显示表情节点的逻辑
--@id 表情节点的id
--]]
function RoleNode:ShowExpression(id)
    if self.role then
        if self.role:getChildByName(EXPRESSION_TAG_NAME) then
            self.role:removeChildByName(EXPRESSION_TAG_NAME)
        end
        local prefix = string.format('avatar/animate/common_ico_expression_%d',checkint(id))
        local animateNode = sp.SkeletonAnimation:create(string.format("%s.json", prefix),string.format("%s.atlas",prefix), 0.8)
        animateNode:setAnimation(0, 'idle', true)
        animateNode:setName(EXPRESSION_TAG_NAME)
        local size = self:getContentSize()
        if self.npcType == RoleType.Waiters then
            display.commonUIParams(animateNode, {ap = display.CENTER_BOTTOM,po = cc.p(size.width * 0.35, size.height - 80)})
        else
            display.commonUIParams(animateNode, {ap = display.CENTER_BOTTOM,po = cc.p(size.width * 0.2, size.height - 40)})
        end
        self.role:addChild(animateNode,10)
    end
end


--[[
--添加喂食特效的逻辑
--]]
function RoleNode:AddVigourEffect()
    if self.npcType == RoleType.Waiters then
        if self.role:getChildByName(EXPRESSION_TAG_NAME) then
            self.role:removeChildByName(EXPRESSION_TAG_NAME)
        end
        local animateNode = self:getChildByName('AddVigourEffect')
        if animateNode then return end
        local animateNode = sp.SkeletonAnimation:create("arts/effects/xxd.json","arts/effects/xxd.atlas", 0.8)
        animateNode:setAnimation(0, 'idle', false)
        animateNode:setName("AddVigourEffect")
        local size = self:getContentSize()
        display.commonUIParams(animateNode, {ap = display.CENTER_BOTTOM,po = cc.p(size.width * 0.5, 0)})
        animateNode:registerSpineEventHandler(handler(self, self.SpineAction), sp.EventType.ANIMATION_COMPLETE)
        self:addChild(animateNode,10)
    end
end

function RoleNode:SpineAction(event)
    local animateNode = self:getChildByName('AddVigourEffect')
    if animateNode then
        animateNode:unregisterSpineEventHandler(sp.EventType.ANIMATION_COMPLETE)
        animateNode:runAction(cc.Spawn:create(cc.FadeOut:create(0.1),cc.RemoveSelf:create()))
    end
end

function RoleNode:VigourState()
    if self.npcType == RoleType.Waiters then
        local vigour = 0
        if self.friendData_ then
            vigour = checkint(self.friendData_.vigour)
        else
            local cardInfo = gameMgr:GetCardDataByCardId(self.id)
            vigour = checkint(cardInfo.vigour)
        end
        if vigour <= 0 and self.serviceState ~= ServiceType.WALKING then
            --添加表情的逻辑
            self:ShowExpression(6)
        else
            -- self.role:removeChildByName(EXPRESSION_TAG_NAME)
            if self.serviceState ~= ServiceType.WALKING and self.role then
                if self.role:getChildByName(EXPRESSION_TAG_NAME) then
                    self.role:removeChildByName(EXPRESSION_TAG_NAME)
                end
                self.role:setAnimation(0,'idle', true)
            end
        end
    end
end


function RoleNode:CanReversePath()
    self.reverse = true
end

--[[
--设置当前食客或者服务员的数据信息
--@datas --数据
--]]
function RoleNode:SetNpcData(datas)
    datas.leftSeconds = checkint(datas.leftSeconds) + 5
    self.datas = datas
    -- dump(datas)
    local isSpecialCustomer = checkint(datas.isSpecialCustomer)
    if isSpecialCustomer == 0 then --非特殊客人
        if datas.customerUuid and datas.seatId then
            --存在座位信息时，不走计时品的逻辑
            self.startCountDown = false--启动计时器
            -- if checkint(datas.leftSeconds) <= 0 and (not datas.questEventId) then
                -- self.startCountDown = true--启动计时器
            -- end
        else
            self.startCountDown = true --启动计时器
        end
    end
end

return RoleNode

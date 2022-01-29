local VisitorNode = class('VisitorNode', function()
    local node = CColorView:create(ccc4FromInt("#ff807300"))
    node:enableNodeEvents()
    node.name = 'VisitorNode'
    return node
end)

local shareFacade = AppFacade.GetInstance()

local socketMgr = shareFacade:GetManager('SocketManager')

local gameMgr = shareFacade:GetManager("GameManager")

local EXPRESSION_TAG_NAME = 'EXPRESSION_TAG_NAME'

local EAT_STATS = RESTAURANT_EAT_STATS


function VisitorNode:getSeatInfo()
    local avatarMediator = shareFacade:RetrieveMediator('AvatarMediator')
    if avatarMediator then
        return self.friendData and self.friendData.seatData or avatarMediator:GetSeatCacheInfoBySeatId(self.seatId)
    else
        return self.friendData and self.friendData.seatData or nil
    end
end

function VisitorNode:ctor(...)
    local args = unpack({...})
    self.isOver = false
    self.dbId = args.id

    self.friendData = args.friendData
    self.avatarId = args.avatarId
    self.seatId = args.seatId
    self.autoRemove = false --需要从装修回来后移除的逻辑

    self.start = true
    self.isWaiting = true
    self:setName(self.seatId)

    self.isClicking = true
    self:setContentSize(cc.size(100,134))
    self:setTouchEnabled(true)

    local tids = string.split(self.seatId, '_')
    self:setLocalZOrder(checkint(tids[2]))
    local seatInfo = self:getSeatInfo()
    self:setOnTouchBeganScriptHandler(function(sender, touch)
        return 1
    end)
    self:setOnTouchEndedScriptHandler(function(sender, touch)
        local parentNode = self:getParent()
        if parentNode and self.isClicking == true then
            local touchEndPos = parentNode:convertToNodeSpace(touch:getLocation())
            local rect = self:getBoundingBox()
            if cc.rectContainsPoint(rect, touchEndPos) then
                local seatInfo = self:getSeatInfo()
                if seatInfo then
                    seatInfo.seatId = self.seatId
                    shareFacade:DispatchObservers(RESTAURANT_EVENTS.EVENT_CLICK_DESK,{id = self.dbId, avatarId = self.avatarId, type = 3, seatInfo = seatInfo, friendData = self.friendData})
                end
            end
        end
        return true
    end)

    --[[
    self:setOnClickScriptHandler(function(sender)
        --食客被点击的逻辑
        if self.isClicking then
            local seatInfo = avatarMediator:GetSeatCacheInfoBySeatId(self.seatId)
            seatInfo.seatId = self.seatId
            shareFacade:DispatchObservers(RESTAURANT_EVENTS.EVENT_CLICK_DESK,{id = self.dbId, avatarId = self.avatarId, type = 3, seatInfo = seatInfo})
        end
    end)
    --]]

    self:setAnchorPoint(cc.p(0.5,0))
    if seatInfo then
        local isSpecialCustomer = checkint(seatInfo.isSpecialCustomer)
        local pathPrefix = string.format("avatar/visitors/%s", tostring(self.avatarId))
        if isSpecialCustomer == 1 then
            local customerData = CommonUtils.GetConfigNoParser('restaurant', 'specialCustomer', seatInfo.customerId)
            if customerData and next(customerData) ~= nil then
                pathPrefix = string.format('avatar/visitors/%s', tostring(customerData.type))
            end
        end
        local role = sp.SkeletonAnimation:create(string.format("%s.json", pathPrefix),string.format('%s.atlas', pathPrefix), 0.35)
        role:setTag(self.dbId)
        role:setToSetupPose()
        local width = self:getContentSize().width
        role:setPosition(cc.p(width * 0.5,0))
        if seatInfo.questEventId then
            role:setAnimation(0, VISITOR_STATES.IDLE3.name, true)
        else
            role:setAnimation(0, VISITOR_STATES.IDLE.name, true)
        end
        self:addChild(role,2)
        self.role = role

        local leftSeconds = checkint(seatInfo.leftSeconds)
        local waiterId = checkint(seatInfo.waiterId)
        local isEating = checkint(seatInfo.isEating)
        local startTime = getServerTime()
        self:schedule(function()
            local avatarMediator = shareFacade:RetrieveMediator('AvatarMediator')
            if avatarMediator then
                local delta = math.floor(getServerTime() - startTime)
                if delta >= 1 then
                    startTime = getServerTime()
                    local seatInfo = self:getSeatInfo()
                    local eatingState = checkint(seatInfo.isEating)
                    local isSpecialCustomer = checkint(seatInfo.isSpecialCustomer)
                    local hasCustomer = checkint(seatInfo.hasCustomer)
                    if eatingState == EAT_STATS.WAITING then --正在等待吃饭的逻辑
                        if isSpecialCustomer == 0 and waiterId == 0 and self.isWaiting and hasCustomer == 1 then
                            --常规客人且没有服务的时候需要离开的操作
                            local leftSeconds = checkint(seatInfo.leftSeconds)
                            leftSeconds = leftSeconds - 1
                            if leftSeconds < - 8 then leftSeconds = 0 end
                            seatInfo.leftSeconds = leftSeconds
                            if leftSeconds == 0 then
                                --调用离开的接口的逻辑
                                funLog(Logger.INFO, '---------->>---------等待的人离开---------->>')
                                self.isWaiting = false --停止动作
                                local newestSeatInfo = self:getSeatInfo()
                                local leftSeconds = checkint(newestSeatInfo.leftSeconds)
                                local waiterId = checkint(newestSeatInfo.waiterId)
                                if newestSeatInfo.questEventId then
                                    -- self:ShowExpression(5)
                                else
                                    ---最新的位置信息
                                    self.isClicking = false
                                    local avatarMediator = shareFacade:RetrieveMediator('AvatarMediator')
                                    self:runAction(cc.Sequence:create(
                                            cc.CallFunc:create(function()
                                                --没有人服务的情况下生成的表情
                                                self:ShowExpression(3)
                                            end),
                                            cc.DelayTime:create(2),
                                            cc.CallFunc:create(function()
                                                local avatarMediator = shareFacade:RetrieveMediator('AvatarMediator')
                                                if avatarMediator and avatarMediator.decorationing == false then
                                                    --如果是在装修状态时不发送这个状态
                                                    shareFacade:DispatchObservers(RESTAURANT_EVENTS.EVENT_SERVICE_ANIMATION, {seatId = self.seatId, isLeave = true, expressionId = 3})
                                                end
                                            end), cc.Spawn:create(cc.Hide:create(), cc.RemoveSelf:create())))
                                        end
                                    end
                                end
                            elseif eatingState == EAT_STATS.EATING then
                                local hasCustomer = checkint(seatInfo.hasCustomer)
                                if hasCustomer == 1 then
                                    if isSpecialCustomer == 0 or (isSpecialCustomer == 0 and seatInfo.questEventId) then
                                        local leftSeconds = checkint(seatInfo.leftSeconds)
                                        leftSeconds = leftSeconds - 1
                                        if leftSeconds < -6 then leftSeconds = 0 end
                                        seatInfo.leftSeconds = leftSeconds
                                        if leftSeconds == 0 then
                                            self.isClicking = false --吃饭的人物不再可点击
                                            seatInfo.isEating = EAT_STATS.FINISHING --吃完饭的逻辑
                                            --需要手动调用下离开的接口
                                            self:AfterEatAnimation() --吃完饭的逻辑
                                        end
                                    end
                                end
                            end
                        end
                    end
        end,1.0)
    end
end


function VisitorNode:onTouchBegan(touch, event)
    -- local touchEndPos = self:convertToWorldSpaceAR(cc.p(0,0))
    local parentNode = self:getParent()
    if parentNode then
        local touchEndPos = parentNode:convertToNodeSpace(touch:getLocation())
        local rect = self:getBoundingBox()
        if cc.rectContainsPoint(rect, touchEndPos) then
            parentNode.canTouch = false
            return true
        else
            parentNode.canTouch = true
            return false
        end

    else
        return false
    end
end
function VisitorNode:onTouchMoved(touch, event)
end
function VisitorNode:onTouchEnded(touch, event)
	local touchEndPos = self:getParent():convertToNodeSpace(touch:getLocation())
	local rect = self:getBoundingBox()
	if cc.rectContainsPoint(rect, touchEndPos) then
        if self.isClicking then
            local seatInfo = self:getSeatInfo()
            if seatInfo then
                seatInfo.seatId = self.seatId
                shareFacade:DispatchObservers(RESTAURANT_EVENTS.EVENT_CLICK_DESK,{id = self.dbId, avatarId = self.avatarId, type = 3, seatInfo = seatInfo, friendData = self.friendData})
            end
        end
	end
end




function VisitorNode:ShowExpression(id)
    if self:getChildByName(EXPRESSION_TAG_NAME) then
        self:removeChildByName(EXPRESSION_TAG_NAME)
    end
    --[[
    local ExpressionNode = require('Game.views.restaurant.ExpressionNode')
    local animateNode = ExpressionNode.new({id = id, cb = function()
        local feedMdt = shareFacade:RetrieveMediator("Game.mediator.AvatarFeedMediator")
        if self.isClicking and (not feedMdt) then
            local seatInfo = self:getSeatInfo()
            if seatInfo then
                seatInfo.seatId = self.seatId
                shareFacade:DispatchObservers(RESTAURANT_EVENTS.EVENT_CLICK_DESK,{id = self.dbId, avatarId = self.avatarId, type = 3, seatInfo = seatInfo, friendData = self.friendData})
            end
        end
    end})
    animateNode:setName(EXPRESSION_TAG_NAME)
    local size = self:getContentSize()
    display.commonUIParams(animateNode, {ap = display.CENTER_BOTTOM,po = cc.p(size.width * 0.5 + 10, size.height - 10)})
    self:addChild(animateNode,10)
--]]
    local prefix = string.format('avatar/animate/common_ico_expression_%d',checkint(id))
    --吃的东西的契合度
    local animateNode = sp.SkeletonAnimation:create(string.format("%s.json", prefix),string.format("%s.atlas",prefix), 0.6)
    animateNode:setAnimation(0, 'idle', true)
    animateNode:setName(EXPRESSION_TAG_NAME)
    local size = self:getContentSize()
    display.commonUIParams(animateNode, {ap = display.CENTER_BOTTOM,po = cc.p(size.width * 0.5 + 10, size.height - 24)})
    self:addChild(animateNode,10)
end

function VisitorNode:SetFlipX(flip)
    local role = self:getChildByTag(self.dbId)
    if role then
        role:setScaleX(-1)
    end
end



function VisitorNode:BeforEatAnimation()
    --开始吃饭
    funLog(Logger.INFO, "------->>> 食客吃的动画的逻辑----->>>")
    local seatCacheInfo = self:getSeatInfo()
    --霸王餐与普通客人要吃饭的逻辑
    if seatCacheInfo.recipeId or (checkint(seatCacheInfo.isSpecialCustomer) == 0 and seatCacheInfo.questEventId) then
        --如果是霸王餐吃完了不能离开的逻辑
        funLog(Logger.INFO, "------->>> 开始食客吃的动画的逻辑----->>>")
        local recipeId = checkint(seatCacheInfo.recipeId)
        -- local recipeNum = checkint(seatCacheInfo.recipeNum) --用来判断是否是大食量的客人
        local recipeInfo = CommonUtils.GetConfigNoParser('cooking','recipe',recipeId)
        if recipeInfo and table.nums(checktable(recipeInfo.foods)) > 0 then
            local iconId = checktable(recipeInfo.foods[1]).goodsId
            local iconPath = CommonUtils.GetGoodsIconPathById(iconId)
            local seats = string.split(self.seatId, '_')
            local locateId = checkint(seats[2])
            local seatInfo = self.friendData and self.friendData.locations[tostring(seats[1])] or gameMgr:GetUserInfo().avatarCacheData.location[tostring(seats[1])]
            if seatInfo then
                local goodsId = checkint(seatInfo.goodsId)
                local avatarLocationConfig = CommonUtils.GetConfigNoParser('restaurant', 'avatarLocation', goodsId)
                local dragNode = self:getParent()
                if iconPath and avatarLocationConfig and checkint(avatarLocationConfig.canPut) == 1 then
                    --路径
                    local thingData = avatarLocationConfig.putThings[locateId]
                    if thingData then
                        local x = thingData.x
                        local y = thingData.y
                        local tagName = string.format('%d_%d', x, y)
                        dragNode:removeChildByName(tagName)
                        local reciptNode = display.newImageView(iconPath,x + 16,y + 16)
                        reciptNode:setScale(0.45)
                        reciptNode:setName(tagName)
                        display.commonUIParams(reciptNode, {ap = display.CENTER})
                        local animateNode = sp.SkeletonAnimation:create('avatar/animate/canpan.json','avatar/animate/canpan.atlas', 1.5)
                        animateNode:setAnimation(0, 'idle', true)
                        reciptNode:addChild(animateNode,2)
                        display.commonUIParams(animateNode, {po = utils.getLocalCenter(reciptNode)})
                        dragNode:addChild(reciptNode, 301)
                        self.role:setAnimation(0, VISITOR_STATES.EAT.name, true)
                    end
                end
            end
        else
            funLog(Logger.ERROR, "配表出现一些错误".. tostring(recipeId))
        end
    end

end

function VisitorNode:AfterEatAnimation()
    --吃饭完后
    funLog(Logger.INFO, "------->>> 食客吃饭完后的动画的逻辑----->>>")
    --判断食材吃的什么显示食品，添加吃的动画
    local seatCacheInfo = self:getSeatInfo()
    -- dump(seatCacheInfo)
    if seatCacheInfo.recipeId or (checkint(seatCacheInfo.isSpecialCustomer) == 0 and seatCacheInfo.questEventId) then
        --如果是霸王餐吃完了不能离开的逻辑
        --如果是霸王餐吃完了不能离开的逻辑
        local recipeId = checkint(seatCacheInfo.recipeId)
        local recipeNum = checkint(seatCacheInfo.recipeNum) --用来判断是否是大食量的客人
        local seats = string.split(self.seatId, '_')
        local locateId = checkint(seats[2])
        local seatInfo = self.friendData and self.friendData.locations[tostring(seats[1])] or gameMgr:GetUserInfo().avatarCacheData.location[tostring(seats[1])]
        local foods = CommonUtils.GetConfigNoParser('cooking','recipe',recipeId).foods
        if foods then
            local iconId = checktable(foods[1]).goodsId
            local iconPath = CommonUtils.GetGoodsIconPathById(iconId)
            if seatInfo then
                local goodsId = checkint(seatInfo.goodsId)
                local avatarLocationConfig = CommonUtils.GetConfigNoParser('restaurant', 'avatarLocation', goodsId)
                local dragNode = self:getParent()
                if iconPath and avatarLocationConfig and checkint(avatarLocationConfig.canPut) == 1 then
                    --路径
                    local thingData = avatarLocationConfig.putThings[locateId]
                    if thingData then
                        local x = thingData.x
                        local y = thingData.y
                        local tagName = string.format('%d_%d', x, y)
                        --添加表情动画
                        local isHappy = 0
                        local expressionId = 0
                        if seatCacheInfo.questEventId then
                            --霸王餐的逻辑吃完后不能离开
                            dragNode:removeChildByName(tagName) --移除位置上的节点的食品的节点
                            --将盘子再换回去的逻辑
                            self.role:setAnimation(0, VISITOR_STATES.IDLE3.name, true)
                            --然后人再移除的功能逻辑
                            local frontImage = AssetsUtils.GetRestaurantBigAvatarNode(thingData.thingId,0,0)
                            display.commonUIParams(frontImage, {ap = display.LEFT_BOTTOM, po = cc.p(x, y)})
                            frontImage:setName(tagName)
                            dragNode:addChild(frontImage,301)
                            local seatInfo = self:getSeatInfo()

                            if seatInfo.deltaGold then
                                -- self:ShowGoldTips(checkint(seatInfo.deltaGold))
                                self:ShowGoldTips(checkint(seatInfo.deltaGold), GOLD_ID)
                            end
                            if checkint(seatInfo.deltaTip) > 0 then
                                -- self:ShowGoldTips(checkint(seatInfo.deltaTip), true)
                                self:ShowGoldTips(checkint(seatInfo.deltaTip), POPULARITY_ID)
                            end
                            --显示表情动画真接显示霸王餐的逻辑
                            self:ShowExpression(5)
                            self.isClicking = true--吃饭的人物不再可点击
                        else
                            --普通客人的逻辑
                            dragNode:removeChildByName(tagName) --移除位置上的节点的食品的节点
                            --将盘子再换回去的逻辑
                            self.role:setAnimation(0, VISITOR_STATES.IDLE.name, true)
                            --然后人再移除的功能逻辑
                            local frontImage = AssetsUtils.GetRestaurantBigAvatarNode(thingData.thingId,0,0)
                            display.commonUIParams(frontImage, {ap = display.LEFT_BOTTOM, po = cc.p(x, y)})
                            frontImage:setName(tagName)
                            dragNode:addChild(frontImage,301)
                            --显示表情动画
                            local foodDemonds = CommonUtils.GetConfigNoParser('cooking', 'recipe', recipeId)
                            if recipeNum > 1 then
                                --吃的东西的契合度
                                expressionId = 2
                                self:ShowExpression(2)
                            else
                                --是否满足契合度
                                if table.nums(foodDemonds) > 0 then
                                    local customerInfo = CommonUtils.GetConfigNoParser('restaurant', 'customer', self.avatarId)
                                    local demandAttr = checkint(customerInfo.demandAttr)
                                    for name,id in pairs(foodDemonds) do
                                        local growthData = CommonUtils.GetConfigNoParser('cooking', 'growth',id)
                                        if growthData and checkint(growthData.taste) == demandAttr then
                                            isHappy = 1
                                            break
                                        end
                                    end
                                    if isHappy == 1 then
                                        --食物的契合度比较高的时候的表示出现的逻辑
                                        expressionId = 2
                                        self:ShowExpression(1)
                                    end
                                end
                            end

                            local seatInfo = self:getSeatInfo()
                            if seatInfo.deltaGold then
                                self:ShowGoldTips(checkint(seatInfo.deltaGold), GOLD_ID)
                                -- self:ShowGoldTips(checkint(seatInfo.deltaGold))
                            end
                            if checkint(seatInfo.deltaTip) > 0 then
                                -- self:ShowGoldTips(checkint(seatInfo.deltaTip), true)
                                self:ShowGoldTips(checkint(seatInfo.deltaTip), POPULARITY_ID)
                            end
                            if seatInfo.activityRewards then
                                seatInfo.activityRewards = checktable(seatInfo.activityRewards)
                                for i,v in ipairs(seatInfo.activityRewards) do
                                    self:ShowGoldTips(checkint(v.num), tostring(v.goodsId))
                                end
                            end

                            self:runAction(cc.Sequence:create(cc.DelayTime:create(1),cc.CallFunc:create(function()
                                shareFacade:DispatchObservers(RESTAURANT_EVENTS.EVENT_SERVICE_ANIMATION, {seatId = self.seatId, expressionId = expressionId})
                            end),cc.Spawn:create(cc.Hide:create(), cc.RemoveSelf:create())))
                        end
                    end
                end
            end
        else
            if seatCacheInfo and seatCacheInfo.questEventId then
                self:runAction(cc.Sequence:create(cc.CallFunc:create(function()
                    shareFacade:DispatchObservers(RESTAURANT_EVENTS.EVENT_SERVICE_ANIMATION, {seatId = self.seatId, expressionId = 5})
                end),cc.Spawn:create(cc.Hide:create(), cc.RemoveSelf:create())))
            end
        end
    end
end

function VisitorNode:getGoldNameByTag(id)
    if id == GOLD_ID or id == POPULARITY_ID then
        return CommonUtils.GetCacheProductName(id)
    else
        local goodsConfig = CommonUtils.GetConfig('goods', 'goods', id)
        return goodsConfig.name
    end
end

function VisitorNode:ShowGoldTips(gold, id)
    local x,y  = self:getPosition()
    -- local worldP = cc.p(x,y)
    local pos = cc.p(x, y)
	-- local parentNode = self:getParent()
	-- local pos = parentNode:convertToNodeSpace(worldP)

    local name = tostring(self:getGoldNameByTag(id))

    -- 辅助型数值
    local colorPath = 'green'

	local fps = 20
    -- 为辅助型错开一定的横坐标
    pos.x = pos.x + math.random(-6, 15)

    local deltaP1 = cc.p(0, math.random(45) + math.random(60))
    -- if isTip then
    --     deltaP1 = cc.p(0, 40 + math.random(60))
    -- end
    local actionP1 = cc.pAdd(pos, deltaP1)
    local actionP2 = cc.pAdd(actionP1, cc.p(0, deltaP1.y * 0.5))

    actionSeq = cc.Sequence:create(
    cc.EaseSineIn:create(
    cc.Spawn:create(
    cc.ScaleTo:create(9 / fps, 1),
    cc.MoveTo:create(9 / fps, actionP1))
    ),
    cc.Spawn:create(
    cc.Sequence:create(
    cc.MoveTo:create(19 / fps, actionP2),
    cc.MoveTo:create(11 / fps, pos)),
    cc.Sequence:create(
    cc.DelayTime:create(13 / fps),
    cc.ScaleTo:create(17 / fps, 0)),
    cc.Sequence:create(
    cc.DelayTime:create(19 / fps),
    cc.FadeTo:create(11 / fps, 0))
    ),
    cc.RemoveSelf:create()
    )

    local text = string.format(__('获得%d%s'), math.ceil(gold), name)
    -- if isTip then
    --     text = string.format(__('获得%d小费'), math.ceil(gold))
    -- end
    local damageLabel = display.newLabel(pos.x, pos.y, fontWithColor(2,{ text = text, fontSize = 20, color = '5b3c25'}))
	damageLabel:setAnchorPoint(cc.p(0.5, 0.5))
	self:addChild(damageLabel, 30)

	-- 初始化动画状态
	damageLabel:setScale(0)
	if actionSeq then
		damageLabel:runAction(actionSeq)
	end

end

function VisitorNode:onEnter()
    --[[
    self:setScale(0)
    self:runAction(
    cc.Sequence:create(cc.DelayTime:create(0.04),cc.FadeIn:create(0.33),cc.Spawn:create(cc.MoveBy:create(0.13, cc.p(0, 56)), cc.ScaleTo:create(0.13, 0.84)),
    cc.ScaleTo:create(0.066, 1.08),
    cc.Spawn:create(cc.MoveBy:create(0.033, cc.p(0, 4)), cc.ScaleTo:create(0.033, 0.99)),
    cc.ScaleTo:create(0.099, 1.02),
    cc.Spawn:create(cc.MoveBy:create(0.099, cc.p(0, -65)), cc.ScaleTo:create(0.099, 1)),
    cc.MoveBy:create(0.033, cc.p(0, 9)),
    cc.MoveBy:create(0.033, cc.p(0, -4))
    ))
    ]]
    -- self.touchListener_ = cc.EventListenerTouchOneByOne:create()
    -- self.touchListener_:setSwallowTouches(true)
    -- self.touchListener_:registerScriptHandler(handler(self, self.onTouchBegan), cc.Handler.EVENT_TOUCH_BEGAN)
    -- self.touchListener_:registerScriptHandler(handler(self, self.onTouchMoved), cc.Handler.EVENT_TOUCH_MOVED)
    -- self.touchListener_:registerScriptHandler(handler(self, self.onTouchEnded), cc.Handler.EVENT_TOUCH_ENDED)
    -- self:getEventDispatcher():addEventListenerWithFixedPriority(self.touchListener_, 1)
    -- self:getEventDispatcher():addEventListenerWithSceneGraphPriority(self.touchListener_, selfaddEventListenerWithFixedPriority)

    -- self:StartEatAnimation()
    -- self:ShowGoldTips()
    local seatInfo = self:getSeatInfo()
    if (not seatInfo.questEventId) and checkint(seatInfo.isSpecialCustomer) == 0 then
        seatInfo.isSeated = 1 --已经座到座位上了
    end
    local isEating = checkint(seatInfo.isEating)
    -- if seatInfo.questEventId and isEating > EAT_STATS.EATING then
    if seatInfo.questEventId and isEating >= EAT_STATS.WAITING then
        --表示吃完饭后才显示为霸王餐，人物不离开的逻辑
        self:ShowExpression(5)
    end
    if isEating == EAT_STATS.EATING then
        --如果正在吃饭需要创建吃饭的动画的逻辑
        self.isWaiting = false
        self:BeforEatAnimation()
    end
end

function VisitorNode:onCleanup()
    local avatarMediator = shareFacade:RetrieveMediator('AvatarMediator')
    if avatarMediator then
        local seatInfo = self:getSeatInfo()
        if seatInfo then
            seatInfo.isSeated = 0 --已经离开了座位上了
        end
    end
end

return VisitorNode



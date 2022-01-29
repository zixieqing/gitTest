local AvatarNode = require('common.RestaurantAvatarNode')
local DragNode = class('DragNode', function()
    -- local node = CColorView:create(cc.c4b(100,100,100,0))
    local node = CLayout:create()
    node:setBackgroundColor(cc.c4b(100,100,100,0))
    node:enableNodeEvents()
    node.name = 'DragNode'
    return node
end)

local OrderTags = {
    Hit_Order = 20,
    Chair_Order = 100,
    Visitor_Order = 150,
    Role_Order = 200,
    Desk_Order = 300,
    Temp_Avatar = 400,
    Debug_Order = 999,
}
DragNode.OrderTags = OrderTags


local shareFacade = AppFacade.GetInstance()

local FIX_COLLISION = 16

local TILED_SIZE = RESTAURANT_TILED_SIZE

local RoleType = RESTAURANT_ROLE_TYPE


function DragNode:ctor(...)
    local args = unpack({...})
    self.id = args.id
    self.avatarId = args.avatarId --配表中对应的id
    self.type = args.nType --当前节点的类别
    self.configInfo = args.configInfo
    self.chairsInfos = {} --当前所有的凳子也算是食客
    local enableTouch = true
    if args.enable then
        enableTouch = checkbool(args.enable)
    end
    self.upload = (args.upload or false)
    self.canTouch = true
    self.isCollided = false
    self.isDecorating = false --是否正在装饰中的逻辑

    self.enableMoving = false --是否禁用拖动
    self.isMoving = false --是否存在拖动过的操作

    self.waiterId = nil -- 设置当前桌子的服务员

    self.viewData = {}
    if self.configInfo then
        --创建节点
        local hasAddition = checkint(self.configInfo.hasAddition) > 0
        self.avatarNode_  = AvatarNode.new({confId = self.avatarId, ap = display.LEFT_BOTTOM, enable = not hasAddition, effectLayer = args.effectLayer})
        self:addChild(self.avatarNode_, OrderTags.Desk_Order, OrderTags.Desk_Order)

        -- collision layer
        self.collisionWidth = checkint(self.configInfo.collisionBoxWidth)
        self.collisionHeight = checkint(self.configInfo.collisionBoxLength)
        local directionLayout = CLayout:create(cc.size(self.collisionWidth, self.collisionHeight))
        display.commonUIParams(directionLayout, {ap = display.LEFT_BOTTOM, po = cc.p(0,0)})
        self:addChild(directionLayout)
        directionLayout:setVisible(false) --不显示这个方向的逻辑

        -- set content size
        local avatarSize = self.avatarNode_:getContentSize()
        local nodeW = math.max(avatarSize.width, self.collisionWidth)
        local nodeH = math.max(avatarSize.height, self.collisionHeight + 100)

        self:setContentSize(cc.size(nodeW, nodeH))

        if RESTAURANT_AVATAR_NODE_DEBUG then
            local offset = string.split(self.configInfo.offset[1], ',')
            self:addChild(display.newLayer(0, 0, {size = self:getContentSize(), color = cc.r4b(150)}))
            self:addChild(display.newLayer(offset[1], offset[2], {size = cc.size(self.collisionWidth, self.collisionHeight), color = cc.c4b(0,0,0,150)}), OrderTags.Debug_Order)
        end

        --[[
        local leftRow = display.newImageView(_res('avatar/ui/decorate_ico_arrow_left'),0,self.collisionHeight * 0.5)
        display.commonUIParams(leftRow, { ap = display.RIGHT_CENTER})
        directionLayout:addChild(leftRow)
        local rightRow = display.newImageView(_res('avatar/ui/decorate_ico_arrow_right'),self.collisionWidth,self.collisionHeight * 0.5)
        display.commonUIParams(rightRow, { ap = display.LEFT_CENTER})
        directionLayout:addChild(rightRow)
        local topRow = display.newImageView(_res('avatar/ui/decorate_ico_arrow_top'),self.collisionWidth * 0.5,self.collisionHeight)
        display.commonUIParams(topRow, { ap = display.CENTER_BOTTOM})
        directionLayout:addChild(topRow)
        local bottomRow = display.newImageView(_res('avatar/ui/decorate_ico_arrow_bottom'),self.collisionWidth * 0.5,0)
        display.commonUIParams(bottomRow, { ap = display.CENTER_TOP})
        directionLayout:addChild(bottomRow)
        self.viewData.directionView = directionLayout
        --]]

        -- touch layer
        local touchView = CColorView:create(cc.c4b(0.5,0.5,0.5,0))
        display.commonUIParams(touchView, {ap = display.LEFT_BOTTOM, po = display.LEFT_BOTTOM})
        touchView:setContentSize(cc.size(nodeW, nodeH + 20))
        touchView:setTouchEnabled(true)
        self:addChild(touchView,10)

        --碰撞区域
        assert(self.configInfo.offset, 'conf.offset is nil : ' .. self.avatarId)
        local offset = string.split(self.configInfo.offset[1], ',')
        local dragArea = cc.DrawNode:create(2)
        self:addChild(dragArea)
        dragArea:setName('DrawNode')
        dragArea:setLocalZOrder(OrderTags.Hit_Order)
        if self.upload then
            self:EnableGimos(true)
            self:EnableNodeTouch(false)
        end

        if hasAddition then
            --存在凳子相关
            --测试添加一个编号的逻辑
            if DEBUG > 0 and cc.Application:getInstance():getTargetPlatform() == cc.PLATFORM_OS_MAC then
                local idLabel = display.newLabel(nodeW * 0.5, nodeH * 0.5, fontWithColor(14,{fontSize = 30, color = '6c6c6c', text = tostring(self.id)}))
                self:addChild(idLabel, 1000)
            end
            local len = checkint(self.configInfo.additionNum)
            for i=1,len do
                local appendImage = AssetsUtils.GetRestaurantBigAvatarNode(string.format('%s_%d', tostring(self.avatarId), i),0,0)
                display.commonUIParams(appendImage, {ap = display.LEFT_BOTTOM})
                appendImage:setUserTag(i) --设置几号凳子,可能还有个id值
                appendImage:setTag(i) --设置几号凳子,可能还有个id值
                self:addChild(appendImage,OrderTags.Chair_Order)
            end

            if self.configInfo.additions then
                for i,addition in ipairs(self.configInfo.additions) do
                    local tt = string.split(addition.sitLocation,',')
                    local tile = RestaurantUtils.ConvertPixelsToTiled(cc.p(checkint(tt[1]), checkint(tt[2])))
                    local seatId = string.format('%d_%d', checkint(self.id), i)
                    self.chairsInfos[seatId] = {id = seatId, status = VISITOR_STATES.IDLE.id,
                        w = tile.w, h = tile.h, direction = checkint(addition.additionDirection)}
                end
            end
        end

        if checkint(self.configInfo.canPut) == 1 then
            --表面物品
            for i,v in ipairs(self.configInfo.putThings) do
                local frontImage = AssetsUtils.GetRestaurantBigAvatarNode(v.thingId,0,0)
                local tagName = string.format('%d_%d', v.x, v.y)
                frontImage:setName(tagName)
                display.commonUIParams(frontImage, {ap = display.LEFT_BOTTOM, po = cc.p(v.x,v.y)})
                self:addChild(frontImage,OrderTags.Desk_Order+ 1)
            end
        end

        --offset是表示碰撞框的offset位置
        self.originPosX, self.originPosY = 0,0
        if enableTouch then
            touchView:setOnTouchBeganScriptHandler(handler(self, self.TouchBeginAction))
            touchView:setOnTouchMovedScriptHandler(handler(self, self.TouchMoveAction))
            touchView:setOnTouchEndedScriptHandler(handler(self, self.TouchEndAction))
        end
    end
end

local function retriveMinMaxTiled(rect)
    local minX = cc.rectGetMinX(rect)
    local minY = cc.rectGetMinY(rect)
    local maxX = cc.rectGetMaxX(rect)
    local maxY = cc.rectGetMaxY(rect)

    local minTiledX = math.ceil(minX / TILED_SIZE)
    local minTiledY = math.ceil(minY / TILED_SIZE)
    local maxTiledX = math.ceil(maxX / TILED_SIZE)
    local maxTiledY = math.ceil(maxY / TILED_SIZE)
    --为了防止堵死处理下
    -- print(minTiledX, minTiledY, maxTiledX, maxTiledY)
    -- if maxTiledX - minTiledX > 2 then
        -- minTiledX = minTiledX + 1
        -- maxTiledX = maxTiledX - 1
    -- end
    -- if maxTiledY - minTiledY > 2 then
        -- minTiledY = minTiledY + 1
        -- maxTiledY = maxTiledY - 1
    -- end
    return minTiledX,maxTiledX,minTiledY,maxTiledY
end


--[[
--判断当前点是否存在碰撞的逻辑
--]]
function DragNode:IsCollision(x,y)
    local rect = cc.rect(x - FIX_COLLISION , y - FIX_COLLISION , self.collisionWidth + FIX_COLLISION, self.collisionHeight + FIX_COLLISION)
    local avatarMediator = shareFacade:RetrieveMediator('AvatarMediator')
    local iscollision = false
    local minX = cc.rectGetMinX(rect)
    local minY = cc.rectGetMinY(rect)
    local maxX = cc.rectGetMaxX(rect)
    local maxY = cc.rectGetMaxY(rect)
    local minTiledX = math.ceil(minX / TILED_SIZE)
    local minTiledY = math.ceil(minY / TILED_SIZE)
    local maxTiledX = math.ceil(maxX / TILED_SIZE)
    local maxTiledY = math.ceil(maxY / TILED_SIZE)
    local blocks = {}
    for i= minTiledX,maxTiledX, 1 do
        for j= minTiledY,maxTiledY, 1 do
            table.insert(blocks,{w = i, h = j})
        end
    end

    for name,val in pairs(blocks) do
        if not avatarMediator:IsTileAvailable(val) then
            iscollision = true
            break
        end
    end
    return iscollision
end


function DragNode:TouchBeginAction(sender, touch)
    self.originPosX, self.originPosY = self:getPosition()
    return 1
end
function DragNode:TouchMoveAction(sender, touch)
    if self.enableMoving and self.canTouch and self.isDecorating == true then
        xTry(function()
            self.isMoving = true
            local p = touch:getLocation()
            local pre = touch:getPreviousLocation()
            local offsetX = p.x - pre.x
            local offsetY = p.y - pre.y
            local xx,yy = self:getPosition()
            xx = xx + offsetX
            yy = yy + offsetY
            if xx <= DRAG_AREA_RECT.x then xx = DRAG_AREA_RECT.x end
            if yy <= DRAG_AREA_RECT.y then yy =  DRAG_AREA_RECT.y end
            if (xx + self.collisionWidth) >= (DRAG_AREA_RECT.width + DRAG_AREA_RECT.x) then xx = (DRAG_AREA_RECT.width + DRAG_AREA_RECT.x - self.collisionWidth) end
            if (yy + self.collisionHeight) >= (DRAG_AREA_RECT.height + DRAG_AREA_RECT.y) then yy = (DRAG_AREA_RECT.height + DRAG_AREA_RECT.y - self.collisionHeight) end

            self:setPosition(cc.p(xx, yy))
            -- self:setLocalZOrder(RESTAURANT_TILED_HEIGHT - math.floor(yy / TILED_SIZE))
            local offsetP = string.split(self.configInfo.offset[1],',')
            self:setLocalZOrder(OrderTags.Chair_Order)
            local avatarView = self:getParent()
            if avatarView then
                local testNode = avatarView:getChildByName('HandleNode')
                if testNode then
                    --更改碰撞的逻辑
                    if self:IsCollision(xx, yy) then
                    -- if self:IsRectCollistion(rect) then
                        self:EnableGimos(true)
                        self.isCollided = true
                        testNode.isCollided = true
                        --判断左边的层级要高的逻辑TODO
                    else
                        self:EnableGimos(false)
                        self.isCollided = false
                        testNode.isCollided = false
                    end
                    testNode:TouchMove(cc.p(xx + self.collisionWidth * 0.5 + checkint(offsetP[1]),yy + self.collisionHeight * 0.5 + checkint(offsetP[2])))
                end
            end
            --[[ --更改碰撞的逻辑 ]]
            -- if self:IsCollision(xx, yy) then
                -- self:EnableGimos(true)
                -- self.isCollided = true
                -- --判断左边的层级要高的逻辑TODO
            -- else
                -- self:EnableGimos(false)
                -- self.isCollided = false
            --[[ end ]]
        end, __G__TRACKBACK__)
    end
    return true
end
function DragNode:TouchEndAction(sender, touch)
    if self.canTouch then
        xTry(function()
            if self.isDecorating then
                local collisionWidth = checkint(self.configInfo.collisionBoxWidth)
                local collisionHeight = checkint(self.configInfo.collisionBoxLength)
                local offsetP = string.split(self.configInfo.offset[1],',')
                local x,y = self:getPosition()
                local mediator = AppFacade.GetInstance():RetrieveMediator('AvatarMediator')
                if self.isMoving then
                    -- print('=====================end===========')
                    -- print(self.originPosX, self.originPosY)
                    -- self:setLocalZOrder(RESTAURANT_TILED_HEIGHT - math.floor(y / TILED_SIZE))
                else
                    --单点时的逻辑
                    -- print('-------点击操作---')
                    if not self.upload then
                        --新上场的数据节点不显示移功能
                        local avatarView = self:getParent()
                        -- print('-------点击操作---')
                        if avatarView and not mediator.curNode then
                            local testNode = avatarView:getChildByName('HandleNode')
                            if testNode then
                                testNode:RestoreState(self.id, self.avatarId,collisionWidth, collisionHeight, false, cc.p(x + collisionWidth * 0.5 + checkint(offsetP[1]), y + collisionHeight * 0.5 + checkint(offsetP[2])))
                                testNode:VisibleState(true)
                                --此处调用两次的问题需要处理
                                mediator:HiddenAllDirectionView(self.id)
                                mediator:UpdateAllBlocks()
                            else
                                testNode = require('Game.views.restaurant.HandleNode').new({id = self.id, avatarId = self.avatarId,collisionWidth = collisionWidth,collisionHeight = collisionHeight,upload = false})
                                testNode:setName('HandleNode')
                                avatarView:addChild(testNode, 600)
                                testNode:setAnchorPoint(cc.p(0.5,0))
                                testNode:PositionState(x + collisionWidth * 0.5 + checkint(offsetP[1]), y + collisionHeight * 0.5 + checkint(offsetP[2]))
                                mediator:HiddenAllDirectionView(self.id)
                                mediator:UpdateAllBlocks()
                            end
                            self:EnableMove(true)
                            local tiles = mediator:ConvertRectAreaToTileds(cc.rect(x ,y , self.collisionWidth, self.collisionHeight))
                            mediator:UpdateTileState(tiles, true) --暂时清除位置的cross状态

                            local decorateView = mediator:GetViewComponent():getChildByName('DecorateView')
                            if decorateView then
                                decorateView:setSelectedAvatarId(self.avatarId)
                            end
                        end
                    end
                    self.isMoving = false
                end
            else
                --餐桌子被点击的逻辑
                -- print('--------------正常情况下的点击')
                -- shareFacade:DispatchObservers(RESTAURANT_EVENTS.EVENT_CLICK_DESK,{id = self.id, avatarId = self.avatarId, type = 2})
            end
        end, __G__TRACKBACK__)
    end
    return true
end


-- 弃用了？？
--[[
--是否区域冲突
--]]
function DragNode:IsRectCollistion(rect)
    local avatarView = self:getParent()
    local isCollided = false
    if avatarView then
        local children = avatarView:getChildren()
        for name,val in pairs(children) do
            if val.name and val.name == 'DragNode' then
                if ID(val) ~= ID(self) then
                    local targetRect = val:getBoundingBox()
                    if cc.rectIntersectsRect(rect, targetRect) then
                        isCollided = true
                        break
                    end
                end
            end
        end
    end
    return isCollided
end

-- 弃用了？？
--[[
--设置服务员
--@waiterId --服务员id
--]]
function DragNode:SetWaiterId(waiterId)
    self.waiterId = waiterId
end


--[[
--重到凳子对应的id的tile信息
--@param seatId
--@param npcType --判断是服务员还是客人
--]]
function DragNode:GetTargetDeskTile(seatId, npcType)
    local addition = app.restaurantMgr:GetSeatConfigBySeatId(seatId)
    local x,y = self:getPosition()
    local tt = string.split(addition.sitLocation,',')
    local locTile = RestaurantUtils.ConvertPixelsToTiled(cc.p(x + tt[1], y + tt[2]))
    local minX,maxX, minY,maxY = retriveMinMaxTiled(cc.rect(x,y, self.configInfo.collisionBoxWidth,self.configInfo.collisionBoxLength))
    local midY = math.ceil((maxY - minY + 1) / 2)
    local midX = math.ceil((maxX - minX + 1) / 2)
    local direction = checkint(addition.additionDirection)
    if direction == 1 then
        --右边位置
        if locTile.h >= (minY + midY) then
            if npcType == RoleType.Visitors then --客人
                return {w = locTile.w, h = maxY + 1}
            elseif npcType == RoleType.Waiters then
                return {w = (minX + midX - 1), h = maxY + 1}
            end
        else
            if npcType == RoleType.Visitors then
                -- return {w = locTile.w, h = minY - 1}
                return {w = locTile.w, h = minY}
            else
                -- return {w = (minX + midX - 1), h = minY - 1}
                return {w = (minX + midX - 1), h = minY }
            end
        end
    elseif direction == 2 then
        if locTile.h >= (minY + midY) then
            if npcType == RoleType.Visitors then
                return {w = locTile.w, h = maxY + 1}
            else
                return {w = minX + midX + 1, h = maxY + 1}
            end
        else
            if npcType == RoleType.Visitors then
                return {w = locTile.w, h = minY }
                -- return {w = minX + 1 , h = minY - 1}
            else
                return {w = minX + 1 , h = minY }
                -- return {w = minX + midX + 1, h = minY - 1}
            end
        end
    end
end

--[[
--装饰页面的切换的逻辑
--]]
function DragNode:ToDecorateView(isBack)
    if isBack == nil then isBack = false end
    --判断各位置的食客的数据，然后更新其位置
    self.isDecorating = (isBack == false)
    local avatarView  = self:getParent()
    local hasAddition = checkint(self.configInfo.hasAddition) > 0
    self:EnableNodeTouch(not self.isDecorating)
    if hasAddition then
        --存在凳子相关
        if table.nums(self.chairsInfos) > 0 then
            local mediator = shareFacade:RetrieveMediator('AvatarMediator')
            for seatId,val in pairs(self.chairsInfos) do
                --处理每张凳子的逻辑
                local info = mediator.servicingQueue[seatId]
                --移除走动的人的逻辑功能
                --此处移到外面切换处
                -- local animaterNode = avatarView:getChildByName(seatId)
                -- if animaterNode then
                -- animaterNode:setVisible(false)
                -- animaterNode:runAction(cc.RemoveSelf:create())
                -- end
                if info and checkint(info.isEating) >= RESTAURANT_EAT_STATS.EATING then
                    local node = self:getChildByName(seatId)
                    if node then
                        node:removeFromParent()
                    end
                    if checkint(self.configInfo.canPut) == 1 then
                        --路径
                        local seats = string.split(seatId, '_')
                        local locateId = checkint(seats[2])
                        local thingData = self.configInfo.putThings[locateId]
                        if thingData then
                            local x = thingData.x
                            local y = thingData.y
                            local tagName = string.format('%d_%d', x, y)
                            self:removeChildByName(tagName)
                            --然后人再移除的功能逻辑
                            local frontImage = AssetsUtils.GetRestaurantBigAvatarNode(thingData.thingId,0,0)
                            display.commonUIParams(frontImage, {ap = display.LEFT_BOTTOM, po = cc.p(x, y)})
                            frontImage:setName(tagName)
                            self:addChild(frontImage,OrderTags.Desk_Order + 1)
                        end
                    end
                    local avatarMediator = shareFacade:RetrieveMediator('AvatarMediator')
                    avatarMediator.servicingQueue[seatId].hasCustomer = 0
                end
                local node = self:getChildByName(seatId)
                if node then
                    local avatarMediator = shareFacade:RetrieveMediator('AvatarMediator')
                    node:removeFromParent()
                    avatarMediator.servicingQueue[seatId].hasCustomer = 0
                end
            end
        end
    end
end

--[[
--标记为可移除状态
--]]
function DragNode:MarkChair(pseatId)
    local avatarView = self:getParent()
    local isInChair = false
    if checkint(self.configInfo.hasAddition) == 1 then
        --存在凳子相关
        if table.nums(self.chairsInfos) > 0 then
            for seatId,val in pairs(self.chairsInfos) do
                --处理每张凳子的逻辑
                if seatId == pseatId then
                    --找到指定的位置信息
                    local visitorNode = self:getChildByName(seatId)
                    if visitorNode then
                        visitorNode.autoRemove = true
                        visitorNode.start = false
                    end
                    isInChair = true
                    break
                end
            end
        end
    end
    return isInChair
end

function DragNode:EnableNodeTouch(enable)
    local hasAddition = checkint(self.configInfo.hasAddition) > 0
    if self.avatarNode_ then
        if enable then
            self.avatarNode_:setTouchEnabled(not hasAddition)
        else
            self.avatarNode_:setTouchEnabled(false)
        end
    end
end

function DragNode:EnableGimos(enable)
    local drawNode = self:getChildByName('DrawNode')
    if drawNode then
        if enable then
            drawNode:clear()
            local offsetInfo = string.split(self.configInfo.offset[1], ',')
            local starPoint  = cc.p(checkint(offsetInfo[1]), checkint(offsetInfo[2]))
            local endPoint   = cc.p(starPoint.x + self.collisionWidth, starPoint.y + self.collisionHeight)
            local rectColor  = ccc4fFromInt('#FF9664')
            local lineColor  = ccc4fFromInt('#FF4B0D')
            lineColor.a = 0.3
            drawNode:drawSolidRect(starPoint, endPoint, lineColor)
            drawNode:drawRect(starPoint, endPoint, rectColor)
        else
            drawNode:clear()
        end
    end
end

function DragNode:EnableTouch(enable)
    if enable == nil then enable = false end
    self.canTouch = enable
end

function DragNode:EnableMove(enable)
    if enable == nil then enable = false end
    self.enableMoving = enable
    self.isMoving = false --是否正在移动的逻辑
    -- self.viewData.directionView:setVisible(enable)
end

--[[
--@param id  凳子的id值
--@params {visitorId = visitorId, avatarId = avatarId, npcType = npcType}
--]]
function DragNode:AddVisitor(seatId, params)
    local chairInfo = self.chairsInfos[seatId]
    if chairInfo then
        table.merge(chairInfo, {visitorId = params.visitorId, avatarId = params.avatarId, npcType = params.npcType, isEating = checkint(params.isEating)})
        if chairInfo and checkint(chairInfo.visitorId) > 0 then
            local visitorId = checkint(chairInfo.visitorId)
            local node = self:getChildByName(seatId)
            if not node then
                local addition = app.restaurantMgr:GetSeatConfigBySeatId(seatId, params.friendData and params.locations or nil)
                local tt = string.split(addition.sitLocation,',')
                local VisitorNode = require('Game.views.restaurant.VisitorNode')
                local role = VisitorNode.new({id = visitorId, avatarId = checkint(chairInfo.avatarId),seatId = seatId, isEating = checkint(params.isEating), friendData = params.friendData})
                if role:getSeatInfo() then
                    display.commonUIParams(role, {po = cc.p(tt[1],tt[2])})
                    local tids = string.split(seatId, '_')
                    role:setLocalZOrder(OrderTags.Visitor_Order + checkint(tids[2]))
                    self:addChild(role)
                    if checkint(addition.additionDirection) == 1 then
                        --右边
                        role:SetFlipX(-1)
                    end
                end
            end
        end
    end
end

function DragNode:onEnter()
end

function DragNode:onCleanup()
end

return DragNode


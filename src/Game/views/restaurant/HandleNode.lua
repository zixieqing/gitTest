local HandleNode = class('HandleNode', function()
    local node = CLayout:create()
    node:setBackgroundColor(cc.c4b(100,100,100,0))
    node:enableNodeEvents()
    node:setName('HandleNode')
    node.name = 'HandleNode'
    return node
end)

local socketMgr = AppFacade.GetInstance():GetManager('SocketManager')
local gameMgr = AppFacade.GetInstance():GetManager('GameManager')
local uiMgr = AppFacade.GetInstance():GetManager('UIManager')


function HandleNode:ctor(...)
    local args = unpack({...})
    local size = cc.size(280,120)
    self.canMove = true
    self.isMoving = false
    self.upload = (args.upload or false)
    self.id = args.id
    self.avatarId = args.avatarId
    self.isCollided = false
    self.collisionWidth = args.collisionWidth
    self.collisionHeight = args.collisionHeight
    --设置新位置
    self:setContentSize(size)

    local handleBg = display.newImageView(_res('avatar/ui/decorate_bg_state'))
    display.commonUIParams(handleBg, {po = utils.getLocalCenter(handleBg)})
    self:addChild(handleBg,1)
    local closeButton = display.newButton(0, size.height, {n = _res('avatar/ui/decorate_btn_delete'),cb = function(sender)
        -- print('-------------close------------')
        local avatarMediator = AppFacade.GetInstance():RetrieveMediator('AvatarMediator')
        if not self.upload then
            --如果是原有的位置删除需要做是否有特殊成员的判断
            local canDelete = 1
            local avatarLocationConfig = CommonUtils.GetConfigNoParser('restaurant', 'avatarLocation', self.avatarId)
            if checkint(avatarLocationConfig.additionNum) > 0 then
                for i=1,checkint(avatarLocationConfig.additionNum) do
                    --拿到seatId
                    local seatId = string.format('%d_%d', checkint(self.id), i)
                    local seatInfo = avatarMediator:GetSeatCacheInfoBySeatId(seatId)
                    if seatInfo and checkint(seatInfo.leftSeconds) == -1 and seatInfo.customerUuid then
                        --特殊事件的位置不能删除
                        canDelete = 2
                    elseif seatInfo and (checkint(seatInfo.isSpecialCustomer) == 1 or checkint(seatInfo.questEventId) > 0) then
                        --特殊客人的位置不能删除
                        canDelete = 2
                    -- elseif seatInfo and checkint(seatInfo.isEating) > RESTAURANT_EAT_STATS.WAITING then
                        -- canDelete = 3
                    end
                end
            end
            if canDelete == 1 then
                avatarMediator.handleData = {id = self.id, goodsId = self.avatarId}
                socketMgr:SendPacket(NetCmd.RestuarantRemoveGoods,{goodsUuid = self.id, goodsId = self.avatarId})
            else
                if canDelete == 3 then
                    uiMgr:ShowInformationTips(__('有客人正在吃饭不能移除哟'))
                else
                    uiMgr:ShowInformationTips(__('当前桌子存在特殊客人不能删除哟'))
                end
            end
        else
            --当前一个节点移除
            avatarMediator:RemoveTempDragNode()
        end
    end})
    display.commonUIParams(closeButton, {ap = display.LEFT_TOP,po = cc.p(4,114)})
    self:addChild(closeButton,10)

    local confirmButton = display.newButton(0, size.height, {n = _res('avatar/ui/decorate_btn_right'),cb = function(sender)
        -- print('-------------confirm------------')
        local targetNode = nil
        local avatarMediator = AppFacade.GetInstance():RetrieveMediator('AvatarMediator')
        local children = avatarMediator:GetViewComponent().viewData.view:getChildren()
        for idx,val in ipairs(children) do
            if val.name == 'DragNode' then
                local tId = val:getUserTag()
                if tId == checkint(self.id) then
                    targetNode = val
                    break
                end
            end
        end
        if targetNode then
            local tx, ty = targetNode:getPosition()
            if not self.upload then
                if not self.isCollided then
                    avatarMediator.handleData = {id = self.id, goodsId = self.avatarId,x = tx, y = ty}
                    socketMgr:SendPacket(NetCmd.RestuarantMoveGoods,{goodsUuid = self.id, goodsId = self.avatarId,x = tx, y = ty})
                else
                    uiMgr:ShowInformationTips(__('当前放置的位置不合法，请重新移动尝试保存^_^'))
                end
            else
                --确定在场上ok了，还需判断位置是否合法的逻辑
                if not self.isCollided then
                    avatarMediator.handleData = {id = self.id, goodsId = self.avatarId,x = tx, y = ty}
                    socketMgr:SendPacket(NetCmd.RestuarantMoveGoods,{goodsUuid = self.id, goodsId = self.avatarId,x = tx, y = ty})
                else
                    uiMgr:ShowInformationTips(__('当前放置的位置不合法，请重新移动尝试保存^_^'))
                end
            end
        end
    end})
    confirmButton:setName('CONFIRM_BUTTON')
    display.commonUIParams(confirmButton, {ap = display.RIGHT_TOP,po = cc.p(280 - 4,114)})
    self:addChild(confirmButton,10)

    -- local avatarLocationsConfig = CommonUtils.GetConfigNoParser('restaurant', 'avatarLocation', self.avatarId)

    -- local collisionWidth = checkint(avatarLocationsConfig.collisionBoxWidth)
    -- local collisionHeight = checkint(avatarLocationsConfig.collisionBoxLength)
    self.viewData = {
        handleBg = handleBg,
        closeButton = closeButton,
        confirmButton = confirmButton
    }
end


function HandleNode:RestoreState(id, avatarId, collisionWidth, collisionHeight, upload, pos)
    self.canMove = true
    self.isMoving = false
    self.upload = (upload or false)
    self.id = id
    self.avatarId = avatarId
    self.isCollided = false
    self.collisionWidth = collisionWidth
    self.collisionHeight = collisionHeight
    if pos and (pos.x + 160 >= display.width + 10) then
        self.canMove = false
        self:setContentSize(cc.size(120, 280))
        self.viewData.handleBg:setTexture(_res('avatar/ui/decorate_bg_state_left'))
        display.commonUIParams(self.viewData.handleBg, {po = utils.getLocalCenter(self)})
        display.commonUIParams(self.viewData.confirmButton, {ap = display.CENTER_TOP,po = cc.p(60,280 - 4)})
        self:setPosition(cc.p(pos.x, pos.y - 140))
    else
        self:setContentSize(cc.size(280, 120))
        self.viewData.handleBg:setTexture(_res('avatar/ui/decorate_bg_state'))
        display.commonUIParams(self.viewData.handleBg, {po = utils.getLocalCenter(self)})
        display.commonUIParams(self.viewData.confirmButton, {ap = display.RIGHT_TOP,po = cc.p(280 - 4,114)})
        if pos then
            self:setPosition(cc.p(pos.x, pos.y))
        end
    end
end

function HandleNode:PositionState(x, y)
    if (x + 160) >= (display.width + 10) then
        self.canMove = false
        self:setContentSize(cc.size(120, 280))
        self.viewData.handleBg:setTexture(_res('avatar/ui/decorate_bg_state_left'))
        display.commonUIParams(self.viewData.handleBg, {po = utils.getLocalCenter(self)})
        display.commonUIParams(self.viewData.confirmButton, {ap = display.CENTER_TOP,po = cc.p(60,280 - 4)})
        self:setPosition(cc.p(x, y - 140))
    else
        self.canMove = true
        self:setPosition(cc.p(x, y ))
    end
end

function HandleNode:VisibleState(isVisible)
    self:setVisible(isVisible)
    self.touchEventListener:setEnabled(isVisible)
end

function HandleNode:TouchMove(position)
    if self.canMove then
        if position.x + 140 >= display.width + 10 then
            self.canMove = false
            self:setContentSize(cc.size(120, 280))
            self.viewData.handleBg:setTexture(_res('avatar/ui/decorate_bg_state_left'))
            display.commonUIParams(self.viewData.handleBg, {po = utils.getLocalCenter(self)})
            -- display.commonUIParams(self.viewData.closeButton, {ap = display.RIGHT_TOP,po = cc.p(280 - 4,114)})
            display.commonUIParams(self.viewData.confirmButton, {ap = display.CENTER_TOP,po = cc.p(60,280 - 4)})
            self:setPosition(cc.p(position.x, position.y - 140))
        else
            self:setContentSize(cc.size(280, 120))
            self.viewData.handleBg:setTexture(_res('avatar/ui/decorate_bg_state'))
            display.commonUIParams(self.viewData.handleBg, {po = utils.getLocalCenter(self)})
            display.commonUIParams(self.viewData.confirmButton, {ap = display.RIGHT_TOP,po = cc.p(280 - 4,114)})
            self:setPosition(position)
        end
    else
        if position.x + 140 <= display.width then
            self.canMove = true
        else
            self:setPosition(cc.p(display.width - 130, position.y - 140))
        end
    end
end

function HandleNode:onEnter()
    self.touchEventListener = cc.EventListenerTouchOneByOne:create()
    self.touchEventListener:registerScriptHandler(function(touch,event)
        return true
    end,cc.Handler.EVENT_TOUCH_BEGAN)
    self.touchEventListener:registerScriptHandler(function(touch,event)
        self.isMoving = true
    end,cc.Handler.EVENT_TOUCH_MOVED)
    self.touchEventListener:registerScriptHandler(function(touch, event)
        --处理点其他区域的逻辑
        -- print('-------------xxx-end--------')
        xTry(function()
            -- if not self.isMoving  and  (not self.upload) then
            local avatarMediator = AppFacade.GetInstance():RetrieveMediator('AvatarMediator')
            if not self.isMoving  and  (not self.upload) then
                --清除方向指示剪头
                local pp = self:getParent():convertToNodeSpace(touch:getLocation())
                if not cc.rectContainsPoint(self:getBoundingBox(), pp) then
                    local avatarMediator = AppFacade.GetInstance():RetrieveMediator('AvatarMediator')
                    if avatarMediator then
                        avatarMediator:HiddenAllDirectionView(self.id)
                        avatarMediator:UpdateAllBlocks() --更新所有位置信息
                        avatarMediator:RemoveTempDragNode() --移除手指操作页面
                    end
                end
            elseif self.upload then
                --[[
                    local avatarMediator = AppFacade.GetInstance():RetrieveMediator('AvatarMediator')
                    if avatarMediator then
                        avatarMediator:HiddenAllDirectionView(self.id)
                        avatarMediator:UpdateAllBlocks() --更新所有位置信息
                    end
                    --]]
            end
            self.isMoving = false
        end,__G__TRACKBACK__)
    end, cc.Handler.EVENT_TOUCH_ENDED)
    self:getEventDispatcher():addEventListenerWithFixedPriority(self.touchEventListener,1)
end

function HandleNode:onCleanup()
    if self.touchEventListener then
        self:getEventDispatcher():removeEventListener(self.touchEventListener)
    end
end
return HandleNode



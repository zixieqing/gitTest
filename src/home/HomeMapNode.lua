--[[
 * author : kaishiqi
 * descpt : 主界面地图 - 地图点
]]
local RemindIcon  = require('common.RemindIcon')
local HomeMapNode = class('HomeMapNode', function()
    return display.newLayer(0, 0, {name = 'home.HomeMapNode', enableEvent = true, ap = display.CENTER})
end)

local RES_DICT = {
    QUEST_ARMY_NAME      = 'ui/home/nmain/main_maps_bg_name_explore.png',
    QUEST_NORMAL_NAME    = 'ui/home/nmain/main_maps_bg_name_local.png',
    QUEST_HARD_NAME_N    = 'ui/home/nmain/main_maps_bg_name_hard.png',
    QUEST_HARD_NAME_D    = 'ui/home/nmain/main_maps_bg_name_hard_disabled.png',
    QUEST_INFO_BAR       = 'ui/home/nmain/main_maps_bg_star_number.png',
    QUEST_INFO_POINT     = 'ui/home/nmain/main_maps_ico_fire_point.png',
    STORY_FRAME_IMG      = 'ui/home/takeaway/main_maps_bg_branch_line_yellow.png',
    STORY_FRAME_BG       = 'ui/home/takeaway/main_maps_ico_branch_circle_m.png',
    STORY_QUEST_ICON     = 'ui/home/takeaway/main_maps_ico_task.png',
    STORY_BRANCH_ICON    = 'ui/home/takeaway/main_maps_ico_role_unlock.png',
    ORDER_PRIVATE_FRAME  = 'ui/home/takeaway/main_maps_bg_branch_line_yellow.png',
    ORDER_PUBLIC_FRAME   = 'ui/home/takeaway/main_maps_bg_branch_line_red.png',
    ORDER_PUBLIC_CIRCLE  = 'ui/home/takeaway/main_maps_ico_branch_circle_m.png',
    ORDER_PRIVATE_CIRCLE = 'ui/home/takeaway/main_maps_ico_branch_circle_m.png',
    ORDER_PUBLIC_SHADOW  = 'ui/home/takeaway/main_maps_ico_branch_circle_light_l.png',
    ORDER_PRIVATE_SHADOW = 'ui/home/takeaway/main_maps_ico_branch_circle_light_m.png',
    ORDER_WHAIT_ICON     = 'ui/home/takeaway/main_maps_ico_role_unlock.png',
    ORDER_SEND_ICON      = 'ui/home/takeaway/main_maps_ico_order.png',
    ORDER_REWARD_ICON    = 'ui/home/takeaway/main_maps_ico_task.png',
    ORDER_TIMER_BAR      = 'ui/home/takeaway/main_maps_bg_countdown.png',
    REMIND_ICON_PATH     = 'ui/common/common_hint_circle_red_ico.png',
}

local CreateEmptyNode = nil
local CreateQuestNode = nil
local CreateStoryNode = nil
local CreateOrderNode = nil


function HomeMapNode:ctor(...)
    local ctorArgs = unpack({...})
    local nodeType = checkint(ctorArgs.type)
    local nodeData = checktable(ctorArgs.data)
    local areaId   = checkint(ctorArgs.areaId)
    self.nodeData_ = nodeData
    self.nodeType_ = nodeType

    xTry(function()
        -------------------------------------------------
        if self:isQuestType() then
            -- create quest node
            self.viewData_ = CreateQuestNode(nodeType, areaId)
            self:addChild(self.viewData_.view)

            -- update quest node
            local nodeImgPath = string.format('arts/maps/world/%s', tostring(nodeData.photoId))
            self.viewData_.nodeImgLayer:addChild(display.newImageView(_res(nodeImgPath)))

            if self.viewData_.nodeNameBar then
                display.commonLabelParams(self.viewData_.nodeNameBar, {text = tostring(nodeData.name)})
            end


        -------------------------------------------------
        elseif self:isStoryType() then
            -- create story node
            self.viewData_ = CreateStoryNode(nodeType)
            self:addChild(self.viewData_.view)

            -- update story node
            local roleImgPath = string.format('arts/roles/head/%s_head_1.png', tostring(nodeData.roleId))
            self.viewData_.roleImgLayer:addChild(display.newImageView(_res(roleImgPath), 0, 0, {scale = 0.47}))


        -------------------------------------------------
        elseif self:isOrderType() then
            -- create order node
            self.viewData_ = CreateOrderNode(nodeType)
            self.orderId_  = checkint(nodeData.orderId)
            self:addChild(self.viewData_.view)

            -- update order node
            local takeawayRoleConf = CommonUtils.GetConfig('takeaway', 'role', nodeData.roleId) or {}
            local takeawayRolePath = string.format('arts/roles/head/%s_head_1.png', CommonUtils.GetSwapRoleId(takeawayRoleConf.realRoleId))
            self.viewData_.roleImgLayer:addChild(display.newImageView(_res(takeawayRolePath), 0, 0, {scale = 0.47}))
            self:setOrderStatus(nodeData.status)


        -------------------------------------------------
        else
            -- create empty node
            self.viewData_ = CreateEmptyNode()
            self:addChild(self.viewData_.view)
        end
    end, __G__TRACKBACK__)


    if self.viewData_ and self.viewData_.view then
        self:setContentSize(self.viewData_.view:getContentSize())
    end
end


CreateEmptyNode = function()
    local size = cc.size(90, 90)
    local view = display.newLayer(0, 0, {size = size, color = cc.r4b(150)})

    view:addChild(display.newLabel(size.width/2, size.height/2, fontWithColor(20, {text = '??'})))

    return {
        view = view
    }
end


CreateQuestNode = function(nodeType, areaId)
    local size = cc.size(180, 144)
    local view = display.newLayer(0, 0, {size = size})

    -- node image layer
    local nodeImgLayer = display.newLayer(size.width/2, size.height/2)
    view:addChild(nodeImgLayer)
    
    -- node name bar
    local nameImgPath = nil
    local nodeNameBar = nil
    if nodeType == Types.TYPE_ARMY then
        nameImgPath = app.plistMgr:checkSpriteFrame(RES_DICT.QUEST_ARMY_NAME)
    elseif nodeType == Types.TYPE_QUEST then
        nameImgPath = app.plistMgr:checkSpriteFrame(RES_DICT.QUEST_NORMAL_NAME)

        RemindIcon.addRemindIcon({imgPath = RES_DICT.REMIND_ICON_PATH, parent = view, tag = app.badgeMgr:GetZreaRemindTag(areaId), po = cc.p(size.width - 5, 30)})
        
    elseif nodeType == Types.TYPE_QUEST_HARD then
        -- check is unlock hard quest
        if CommonUtils.UnLockModule(RemindTag.DIFFICULT_MAP, false) then
            local result, errLog = CommonUtils.CanEnterChapterByChapterIdAndDiff(app.gameMgr:GetAreaId(), QUEST_DIFF_HARD)
            if result == false then
                nameImgPath = app.plistMgr:checkSpriteFrame(RES_DICT.QUEST_HARD_NAME_D)
            else
                nameImgPath = app.plistMgr:checkSpriteFrame(RES_DICT.QUEST_HARD_NAME_N)
            end
        else
            nameImgPath = app.plistMgr:checkSpriteFrame(RES_DICT.QUEST_HARD_NAME_D)
        end
    end
    if nameImgPath then
        local offset = nodeType == Types.TYPE_ARMY and cc.p(12, 0) or cc.p(0, -4)
        nodeNameBar  = display.newButton(size.width/2, nodeImgLayer:getPositionY() - 55, {n = nameImgPath, enable = false})
        display.commonLabelParams(nodeNameBar, fontWithColor(19, {fontSize = 24, outline = '#000000', outlineSize = 1, offset = offset}))
        view:addChild(nodeNameBar)
    end

    -- node info bar
    local nodeInfoBar = nil
    if nodeType == Types.TYPE_QUEST or nodeType == Types.TYPE_QUEST_HARD then
        nodeInfoBar = display.newButton(size.width/2, 0, {n = app.plistMgr:checkSpriteFrame(RES_DICT.QUEST_INFO_BAR), ap = display.CENTER_TOP})
        nodeInfoBar:addChild(display.newImageView(app.plistMgr:checkSpriteFrame(RES_DICT.QUEST_INFO_POINT), 28, nodeInfoBar:getContentSize().height/2))
        display.commonLabelParams(nodeInfoBar, fontWithColor(14, {offset = cc.p(18, 0)}))
        view:addChild(nodeInfoBar)
    end

    -- click area
    local clickArea = display.newLayer(0, 0, {size = size, color = cc.r4b(0), enable = true})
    view:addChild(clickArea)
    
    return {
        view         = view,
        clickArea    = clickArea,
        nodeImgLayer = nodeImgLayer,
        nodeNameBar  = nodeNameBar,
        nodeInfoBar  = nodeInfoBar,
    }
end


CreateStoryNode = function(nodeType)
    local size = cc.size(90, 118)
    local view = display.newLayer(0, 0, {size = size})

    -- story frame
    local imgPath = HOME_THEME_STYLE_DEFINE.ORDER_PRIVATE or app.plistMgr:checkSpriteFrame(RES_DICT.STORY_FRAME_IMG)
    view:addChild(display.newImageView(imgPath, size.width/2, size.height/2))
    view:addChild(display.newImageView(app.plistMgr:checkSpriteFrame(RES_DICT.STORY_FRAME_BG), size.width/2, size.height/2 + 14))
    
    -- role image layer
    local roleImgLayer = display.newLayer(size.width/2, size.height/2 + 14)
    view:addChild(roleImgLayer)

    view:addChild(display.newImageView(app.plistMgr:checkSpriteFrame(RES_DICT.ORDER_PRIVATE_SHADOW), size.width/2, size.height/2 + 14))
    
    -- story icon
    if nodeType == Types.TYPE_STORY then
        view:addChild(display.newImageView(app.plistMgr:checkSpriteFrame(RES_DICT.STORY_QUEST_ICON), size.width - 20, size.height - 10))
    else
        view:addChild(display.newImageView(app.plistMgr:checkSpriteFrame(RES_DICT.STORY_BRANCH_ICON), size.width - 20, size.height - 10))
    end

    -- click area
    local clickArea = display.newLayer(0, 0, {size = size, color = cc.r4b(0), enable = true})
    view:addChild(clickArea)

    return {
        view         = view,
        roleImgLayer = roleImgLayer,
        clickArea    = clickArea,
    }
end


CreateOrderNode = function(nodeType)
    local size = cc.size(90, 118)
    local view = display.newLayer(0, 0, {size = size})

    -- order frame
    local outsidePath1 = HOME_THEME_STYLE_DEFINE.ORDER_PUBLIC or app.plistMgr:checkSpriteFrame(RES_DICT.ORDER_PUBLIC_FRAME)
    local outsidePath2 = HOME_THEME_STYLE_DEFINE.ORDER_PRIVATE or app.plistMgr:checkSpriteFrame(RES_DICT.ORDER_PRIVATE_FRAME)
    local insideFrame  = nodeType == Types.TYPE_TAKEAWAY_PUBLIC and app.plistMgr:checkSpriteFrame(RES_DICT.ORDER_PUBLIC_CIRCLE) or app.plistMgr:checkSpriteFrame(RES_DICT.ORDER_PRIVATE_CIRCLE)
    local outsideFrame = nodeType == Types.TYPE_TAKEAWAY_PUBLIC and outsidePath1 or outsidePath2
    view:addChild(display.newImageView(outsideFrame, size.width/2, size.height/2))
    view:addChild(display.newImageView(insideFrame, size.width/2, size.height/2 + 15))

    -- role image layer
    local roleImgLayer = display.newLayer(size.width/2, size.height/2 + 15)
    view:addChild(roleImgLayer)
    
    -- shadow frame
    local shadowFrame  = orderType == Types.TYPE_TAKEAWAY_PUBLIC and app.plistMgr:checkSpriteFrame(RES_DICT.ORDER_PUBLIC_SHADOW) or app.plistMgr:checkSpriteFrame(RES_DICT.ORDER_PRIVATE_SHADOW)
    view:addChild(display.newImageView(shadowFrame, size.width/2, size.height/2 + 15))

    -- reward spine
    local rewardSpine = display.newCacheSpine(SpineCacheName.GLOBAL, 'ui/home/takeaway/baoxiang', 0.6)
    rewardSpine:setPosition(size.width/2 - 2, size.height/2 - 11)
    rewardSpine:setAnimation(0, 'baoxiang1', true)
    view:addChild(rewardSpine)

    -- status icons
    local statusIconPos   = cc.p(size.width - 20, size.height - 10)
    local orderWhaitIcon  = display.newImageView(app.plistMgr:checkSpriteFrame(RES_DICT.ORDER_WHAIT_ICON), statusIconPos.x, statusIconPos.y)
    local orderSendIcon   = display.newImageView(app.plistMgr:checkSpriteFrame(RES_DICT.ORDER_SEND_ICON), statusIconPos.x, statusIconPos.y)
    local orderRewardIcon = display.newImageView(app.plistMgr:checkSpriteFrame(RES_DICT.ORDER_REWARD_ICON), statusIconPos.x, statusIconPos.y)
    view:addChild(orderWhaitIcon)
    view:addChild(orderSendIcon)
    view:addChild(orderRewardIcon)

    -- countdown bar
    local countdownBar = display.newButton(size.width/2, size.height/2 - 15, {n = app.plistMgr:checkSpriteFrame(RES_DICT.ORDER_TIMER_BAR), enable = false, scale9 = true, size = cc.size(98, 24)})
    display.commonLabelParams(countdownBar, {fontSize = 20, color = '#5b3c25', ttf = true, font = TTF_GAME_FONT})
    view:addChild(countdownBar)

    -- click area
    local clickArea = display.newLayer(0, 0, {size = size, color = cc.r4b(0), enable = true})
    view:addChild(clickArea)

    return {
        view            = view,
        roleImgLayer    = roleImgLayer,
        rewardSpine     = rewardSpine,
        orderSendIcon   = orderSendIcon,
        orderWhaitIcon  = orderWhaitIcon,
        orderRewardIcon = orderRewardIcon,
        countdownBar    = countdownBar,
        clickArea       = clickArea,
    }
end


-------------------------------------------------
-- get / set

function HomeMapNode:getViewData()
    return self.viewData_
end


function HomeMapNode:getNodeType()
    return self.nodeType_
end


function HomeMapNode:getNodeData()
    return self.nodeData_
end


function HomeMapNode:getOrderStatus()
    return self.orderStatus_
end
function HomeMapNode:setOrderStatus(status)
    self.orderStatus_ = checkint(status)
    self:updateOrderNodeStatus_()
end


function HomeMapNode:isQuestType()
    return self:getNodeType() == Types.TYPE_ARMY or 
            self:getNodeType() == Types.TYPE_QUEST or 
            self:getNodeType() == Types.TYPE_QUEST_HARD
end


function HomeMapNode:isStoryType()
    return self:getNodeType() == Types.TYPE_STORY or 
            self:getNodeType() == Types.TYPE_BRANCH
end


function HomeMapNode:isOrderType()
    return self:getNodeType() == Types.TYPE_TAKEAWAY_PUBLIC or 
            self:getNodeType() == Types.TYPE_TAKEAWAY_PRIVATE
end


-------------------------------------------------
-- public method

function HomeMapNode:showAction(endCb)
    self:stopAllActions()

    if self:isQuestType() then
        self:setScale(0)
        self:runAction(cc.Sequence:create(
            cc.DelayTime:create(0.08 + math.random(20)/100 - math.random(20)/100),
            cc.ScaleTo:create(0.3, 1)
        ))

    else
        self:setScale(0)
        self:runAction(cc.Sequence:create(
            cc.DelayTime:create(0.08 + math.random(20)/100 - math.random(20)/100),
            cc.Spawn:create(
                cc.MoveBy:create(0.13, cc.p(0, 56)), 
                cc.ScaleTo:create(0.13, 0.84)
            ),
            cc.ScaleTo:create(0.066, 1.08),
            cc.Spawn:create(
                cc.MoveBy:create(0.033, cc.p(0, 4)), 
                cc.ScaleTo:create(0.033, 0.99)
            ),
            cc.ScaleTo:create(0.099, 1.02),
            cc.Spawn:create(
                cc.MoveBy:create(0.099, cc.p(0, -44)), 
                cc.ScaleTo:create(0.099, 1)
            ),
            cc.MoveBy:create(0.033, cc.p(0, 9)),
            cc.MoveBy:create(0.033, cc.p(0, -4))
        ))
    end
end


function HomeMapNode:hideAction(endCb)
    self:stopAllActions()

    if self:isQuestType() then
        self:setScale(1)
        self:runAction(cc.Sequence:create({
            cc.ScaleTo:create(0.2, 0),
            cc.RemoveSelf:create()
        }))

    else
        self:setScale(1)
        self:runAction(cc.Sequence:create({
            cc.Spawn:create({
                cc.ScaleTo:create(0.2, 0),
                cc.MoveBy:create(0.2, cc.p(0, -self:getContentSize().height/2))
            }),
            cc.RemoveSelf:create()
        }))
    end
end


-------------------------------------------------
-- private method

function HomeMapNode:updateOrderNodeStatus_()
    if not self:isOrderType() then return end

    local viewData        = self:getViewData()
    local orderData       = self:getNodeData()
    local orderStatus     = self:getOrderStatus()
    local takeawayManager = AppFacade.GetInstance():GetManager('TakeawayManager')
    local orderTimerInfo  = takeawayManager:GetOrderTimerINfo(orderData.areaId, orderData.orderType, orderData.orderId) or {}

    -- 1:配送等待
    if orderStatus == 1 then
        viewData.rewardSpine:setVisible(false)
        viewData.roleImgLayer:setVisible(true)
        viewData.orderSendIcon:setVisible(false)
        viewData.orderWhaitIcon:setVisible(true)
        viewData.orderRewardIcon:setVisible(false)

        if self:getNodeType() == Types.TYPE_TAKEAWAY_PUBLIC then
            -- add countdown listener
            AppFacade.GetInstance():RegistObserver(COUNT_DOWN_ACTION_UI, mvc.Observer.new(self.onOrderNodeCountDownHandler_, self))
            self:updateOrderLeftCountdown_(checkint(orderTimerInfo.countdown), checkint(orderTimerInfo.timeNum))
            
            viewData.countdownBar:setVisible(true)
        else
            viewData.countdownBar:setVisible(false)
        end


    -- 2:配送前往 / 3:配送返回
    elseif orderStatus == 2 or orderStatus == 3 then
        viewData.rewardSpine:setVisible(false)
        viewData.roleImgLayer:setVisible(true)
        viewData.countdownBar:setVisible(true)
        viewData.orderSendIcon:setVisible(true)
        viewData.orderWhaitIcon:setVisible(false)
        viewData.orderRewardIcon:setVisible(false)

        -- add countdown listener
        AppFacade.GetInstance():RegistObserver(COUNT_DOWN_ACTION_UI, mvc.Observer.new(self.onOrderNodeCountDownHandler_, self))
        self:updateOrderSendCountdown_(checkint(orderTimerInfo.countdown), checkint(orderTimerInfo.timeNum))


    -- 4:配送完成
    elseif orderStatus == 4 then
        viewData.rewardSpine:setVisible(true)
        viewData.roleImgLayer:setVisible(false)
        viewData.countdownBar:setVisible(false)
        viewData.orderSendIcon:setVisible(false)
        viewData.orderWhaitIcon:setVisible(false)
        viewData.orderRewardIcon:setVisible(true)

    
    else
        viewData.rewardSpine:setVisible(false)
        viewData.roleImgLayer:setVisible(false)
        viewData.countdownBar:setVisible(false)
        viewData.orderSendIcon:setVisible(false)
        viewData.orderWhaitIcon:setVisible(false)
        viewData.orderRewardIcon:setVisible(false)
    end
end
function HomeMapNode:updateOrderLeftCountdown_(nowTime, endTime)
    local viewData = self:getViewData()
    display.commonLabelParams(viewData.countdownBar, {color = '#d23d35', text = string.formattedTime(nowTime, '%02i:%02i:%02i')})
end
function HomeMapNode:updateOrderSendCountdown_(nowTime, endTime)
    local viewData = self:getViewData()
    display.commonLabelParams(viewData.countdownBar, {color = '#5b3c25', text = string.formattedTime(nowTime, '%02i:%02i:%02i')})
end


-------------------------------------------------
-- handler

function HomeMapNode:onCleanup()
    AppFacade.GetInstance():UnRegistObserver(COUNT_DOWN_ACTION_UI, self)
end


function HomeMapNode:onOrderNodeCountDownHandler_(signal)
    local dataBody    = signal:GetBody()
    local nowTime     = checkint(dataBody.countdown)
    local endTime     = checkint(dataBody.timeNum)
    local orderData   = checktable(dataBody.datas)
    local orderStatus = checkint(orderData.status)

    if self:getNodeType() == checkint(orderData.orderType) and self.orderId_ == checkint(orderData.orderId) then

        -- update status
        if orderStatus ~= self:getOrderStatus() then
            self:setOrderStatus(orderStatus)

        else
            -- update countdown
            if orderStatus == 1 then
                self:updateOrderLeftCountdown_(nowTime, endTime)
            else
                self:updateOrderSendCountdown_(nowTime, endTime)
            end
        end
    end
end


return HomeMapNode

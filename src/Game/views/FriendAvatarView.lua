--[[
 * author : kaishiqi
 * descpt : 好友餐厅界面
]]
local GoodPurchaseNode = require('common.GoodPurchaseNode')
local AvatarBaseNode   = require('common.RestaurantAvatarNode')
local AvatarDragNode   = require('Game.views.restaurant.DragNode')
local WaiterRoleNode   = require('Game.views.restaurant.RoleNode')
local AvatarBugNode    = require('Game.views.restaurant.BugNode')
local FriendAvatarView = class('FriendAvatarView', function()
    return display.newLayer(0, 0, {name = 'Game.views.FriendAvatarView'})
end)

local RES_DICT = {
    BTN_BACK          = 'ui/common/common_btn_back.png',
    COUNT_INFO_BAR    = 'avatar/ui/restaurant_friend_bg_clean_number.png',
    MONEY_INFO_BAR    = 'ui/home/nmain/main_bg_money.png',
    FRIEND_HEAD_BG    = 'ui/common/common_avatar_frame_bg.png',
    FRIEND_HEAD_FRAME = 'ui/common/common_avatar_frame_default.png',
    FRIEND_NAME_BAR   = 'avatar/ui/restaurant_friends_bg_avator_name.png',
    FRIEND_LEVEL_BAR  = 'avatar/ui/restaurant_friends_bg_level.png',
    SWITCH_DOOR       = 'avatar/ui/restaurant_anime_door.png'
}

local CreateView     = nil
local CreateDoorView = nil


function FriendAvatarView:ctor(args)
    self.avatarNodeMap_ = {}

    xTry(function()
        self.viewData_ = CreateView()
        self:addChild(self.viewData_.view)
    end, __G__TRACKBACK__)

    self:hideBlackBg()
    self:updateMoneyBar()
end


CreateView = function()
    local view = display.newLayer()
    local size = view:getContentSize()

    local blockLayer = display.newLayer(0, 0, {color = cc.c4b(0,0,0,0), enable = true})
    view:addChild(blockLayer)

    -- black bg
    local blackBg = display.newLayer(0, 0, {color = cc.c4b(0,0,0,255)})
    view:addChild(blackBg)

    -- avatar layers
    local avatarLayer = display.newLayer(size.width/2, size.height/2, {ap = display.CENTER, size = cc.size(1334, 1002)})
    view:addChild(avatarLayer)

    local avatarFloorLayer = display.newLayer()
    avatarLayer:addChild(avatarFloorLayer)
    
    local avatarWallLayer = display.newLayer()
    avatarLayer:addChild(avatarWallLayer)

    local avatarNodeLayer = display.newLayer()
    avatarLayer:addChild(avatarNodeLayer)

    local avatarCeilingLayer = display.newLayer()
    avatarLayer:addChild(avatarCeilingLayer)

    local avatarElemLayers = {
        avatarFloorLayer,
        avatarWallLayer,
        avatarNodeLayer,
        avatarCeilingLayer,
    }

    -- waiter layer
    local waiterLayer = display.newLayer()
    avatarLayer:addChild(waiterLayer)

    -- bug layer
    local bugLayer = display.newLayer()
    avatarLayer:addChild(bugLayer)
    
    -- effect layer
    local effectLayer = display.newLayer(0, 0, {ap = display.CENTER})
    effectLayer:setPosition(utils.getLocalCenter(avatarLayer))
    avatarLayer:addChild(effectLayer)


    -------------------------------------------------
    -- money info
    local moneysSize = cc.size(size.width, 80)
    local moneysBar  = display.newLayer(0, display.height, {size = moneysSize, ap = display.LEFT_TOP})
    view:addChild(moneysBar)

    moneysBar:addChild(display.newImageView(_res(RES_DICT.MONEY_INFO_BAR), display.SAFE_R + 60, moneysSize.height, {ap = display.RIGHT_TOP, scale9 = true, size = cc.size(860 + 60, 54)}))
    
    local moneyNodes = {}
    local moneySpace = 16
    local moneyInfoX = display.SAFE_R - 20
    local moneysData = {TIPPING_ID, POPULARITY_ID, GOLD_ID, DIAMOND_ID}
    for i = #moneysData, 1, -1 do
        local moneyId   = moneysData[i]
        local moneyNode = GoodPurchaseNode.new({id = moneyId, animate = true})
        moneyNode.viewData.touchBg:setTag(checkint(moneyId))
        moneyNode:setPosition(moneyInfoX, moneysSize.height - 26)
        moneyNode:setAnchorPoint(display.RIGHT_CENTER)
        moneysBar:addChild(moneyNode)

        moneyInfoX = moneyInfoX - moneyNode:getContentSize().width - moneySpace
        moneyNodes[tostring(moneyId)] = moneyNode
    end


    -------------------------------------------------
    -- help info layer
    local helpInfoLayer       = display.newLayer(0, 0, {size = size})
    local helpBugCountLable   = display.newLabel(display.SAFE_R - 10, size.height - 55, fontWithColor(19, {ap = display.RIGHT_CENTER, text = '0'}))
    local helpQuestCountLable = display.newLabel(display.SAFE_R - 10, size.height - 20, fontWithColor(19, {ap = display.RIGHT_CENTER, text = '0'}))
    local helpBugTipLable     = display.newLabel(display.SAFE_R - 50, size.height - 55, fontWithColor(1, {ap = display.RIGHT_CENTER, text = __('今日剩余 帮打扫次数：')}))
    local helpQuestTipLable   = display.newLabel(display.SAFE_R - 50, size.height - 20, fontWithColor(1, {ap = display.RIGHT_CENTER, text = __('今日剩余 帮打霸王餐次数：')}))
    helpInfoLayer:addChild(helpBugCountLable)
    helpInfoLayer:addChild(helpQuestCountLable)
    helpInfoLayer:addChild(helpBugTipLable)
    helpInfoLayer:addChild(helpQuestTipLable)

    local helpInfoSize = cc.size(math.max(display.getLabelContentSize(helpBugTipLable).width, display.getLabelContentSize(helpQuestTipLable).width) + 60 + 120, 76)
    local helpInfoBar  = display.newImageView(_res(RES_DICT.COUNT_INFO_BAR), display.SAFE_R + 60, size.height, {scale9 = true, size = helpInfoSize, ap = display.RIGHT_TOP})
    view:addChild(helpInfoBar)
    view:addChild(helpInfoLayer)


    -------------------------------------------------
    -- friend info bar

    local friendInfoLayer = display.newLayer(display.SAFE_L, 0)
    view:addChild(friendInfoLayer)

    local friendRNameBar = display.newButton(0, 10, {n = _res(RES_DICT.FRIEND_NAME_BAR), ap = display.CENTER_BOTTOM, scale9 = true, enable = false})
    display.commonLabelParams(friendRNameBar, fontWithColor(16))
    friendInfoLayer:addChild(friendRNameBar)
    
    local friendHeaderNode = require('root.CCHeaderNode').new({bg = _res(RES_DICT.FRIEND_HEAD_BG), pre = '', tsize = cc.size(90,90)})
    friendHeaderNode:setPosition(50, 50)
    friendInfoLayer:addChild(friendHeaderNode)
    -- friendInfoLayer:addChild(display.newImageView(_res(RES_DICT.FRIEND_HEAD_FRAME), 50, 50))

    local friendLevelLable = cc.Label:createWithBMFont('font/small/common_text_num.fnt', '---')
    friendLevelLable:setAnchorPoint(display.RIGHT_BOTTOM)
    friendLevelLable:setPosition(92, 3)
    friendInfoLayer:addChild(friendLevelLable)

    -------------------------------------------------
    -- back button
    local backBtn = display.newButton(display.SAFE_L + 75, size.height - 52, {n = _res(RES_DICT.BTN_BACK)})
    view:addChild(backBtn)
    

    return {
        view                = view,
        backBtn             = backBtn,
        blackBg             = blackBg,
        avatarLayer         = avatarLayer,
        avatarWallLayer     = avatarWallLayer,
        avatarFloorLayer    = avatarFloorLayer,
        avatarNodeLayer     = avatarNodeLayer,
        avatarCeilingLayer  = avatarCeilingLayer,
        avatarElemLayers    = avatarElemLayers,
        waiterLayer         = waiterLayer,
        bugLayer            = bugLayer,
        effectLayer         = effectLayer,
        moneysBar           = moneysBar,
        -- infoBar             = infoBar,
        moneyNodeMap        = moneyNodes,
        helpBugCountLable   = helpBugCountLable,
        helpQuestCountLable = helpQuestCountLable,
        friendHeaderNode    = friendHeaderNode,
        friendLevelLable    = friendLevelLable,
        friendRNameBar      = friendRNameBar,
    }
end


CreateDoorView = function()
    local view  = display.newLayer(0, 0, {color = cc.c4b(0,0,0,0), enable = true})
    local doorL = display.newImageView(_res(RES_DICT.SWITCH_DOOR), display.cx, display.cy, {ap = display.RIGHT_CENTER})
    local doorR = display.newImageView(_res(RES_DICT.SWITCH_DOOR), display.cx, display.cy, {ap = display.LEFT_CENTER})
    view:addChild(doorL)
    view:addChild(doorR)

    -- view:addChild(display.newImageView(_res(RES_DICT.SWITCH_DOOR), display.SAFE_L, display.cy, {ap = display.RIGHT_CENTER}))
    -- view:addChild(display.newImageView(_res(RES_DICT.SWITCH_DOOR), display.SAFE_R, display.cy, {ap = display.LEFT_CENTER}))
    return {
        view  = view,
        doorL = doorL,
        doorR = doorR,
    }
end


function FriendAvatarView:CreateDoorView()
    return CreateDoorView()
end


function FriendAvatarView:getViewData()
    return self.viewData_
end


function FriendAvatarView:updateMoneyBar()
    for moneyId, moneyNode in pairs(self:getViewData().moneyNodeMap) do
        moneyNode:updataUi(checkint(moneyId)) --刷新每一个金币数量
    end
end


function FriendAvatarView:showBlackBg()
    self:getViewData().blackBg:setVisible(true)
end
function FriendAvatarView:hideBlackBg()
    self:getViewData().blackBg:setVisible(false)
end


function FriendAvatarView:cleanAvatars()
    for i, layer in ipairs(self:getViewData().avatarElemLayers) do
        layer:removeAllChildren()
    end
    self.avatarNodeMap_ = {}
end
function FriendAvatarView:reloadAvatars(avatarMap)
    for avatarUuid, avatarData in pairs(avatarMap or {}) do
        local avatarId     = checkint(avatarData.goodsId)
        local avatarConf   = CommonUtils.GetConfigNoParser('restaurant', 'avatar', avatarId) or {}
        local locationConf = CommonUtils.GetConfigNoParser('restaurant', 'avatarLocation', avatarId) or {}
        local avatarType   = RestaurantUtils.GetAvatarSubType(avatarConf.mainType, avatarConf.subType)

        if avatarType == RESTAURANT_AVATAR_TYPE.WALL then
            local location   = string.split(checkstr(checktable(locationConf.location)[1]), ',')
            local avatarX    = self:getViewData().avatarLayer:getContentSize().width/2
            local avatarNode = AvatarBaseNode.new({confId = avatarId, x = avatarX, y = location[2], ap = display.CENTER_BOTTOM})
            self:getViewData().avatarWallLayer:addChild(avatarNode)

        elseif avatarType == RESTAURANT_AVATAR_TYPE.FLOOR then
            local location   = string.split(checkstr(checktable(locationConf.location)[1]), ',')
            local avatarX    = self:getViewData().avatarLayer:getContentSize().width/2
            local avatarNode = AvatarBaseNode.new({confId = avatarId, x = avatarX, y = location[2], ap = display.CENTER_BOTTOM})
            self:getViewData().avatarFloorLayer:addChild(avatarNode)

        elseif avatarType == RESTAURANT_AVATAR_TYPE.CEILING then
            local location   = string.split(checkstr(checktable(locationConf.location)[1]), ',')
            local avatarX    = self:getViewData().avatarLayer:getContentSize().width/2
            local avatarNode = AvatarBaseNode.new({confId = avatarId, x = avatarX, y = location[2], ap = display.CENTER_BOTTOM})
            self:getViewData().avatarCeilingLayer:addChild(avatarNode)

        else
            local dragNode = AvatarDragNode.new({id = avatarUuid, avatarId = avatarId, nType = avatarType, configInfo = locationConf, effectLayer = self:getViewData().effectLayer})
            display.commonUIParams(dragNode, {ap = display.LEFT_BOTTOM, po = cc.p(avatarData.location.x, avatarData.location.y)})

            local nodeTile = RestaurantUtils.ConvertPixelsToTiled(cc.p(dragNode:getPosition()))
            dragNode:setLocalZOrder(RESTAURANT_TILED_HEIGHT - nodeTile.h)
            self:getViewData().avatarNodeLayer:addChild(dragNode)
            self.avatarNodeMap_[tostring(avatarUuid)] = dragNode
        end
    end
end


function FriendAvatarView:cleanWaiters()
    self:getViewData().waiterLayer:removeAllChildren()
end
function FriendAvatarView:reloadWaiters(waiterMap)
    local shareSpineCache = SpineCache(SpineCacheName.GLOBAL)
    for waiterSiteId, waiterData in pairs(waiterMap or {}) do
        local cardId   = checkint(waiterData.cardId)
        if cardId > 0 then
            local cardPath = CardUtils.GetCardSpinePathBySkinId(waiterData.skinId)
            if app.gameResMgr:verifySpine(cardPath) then
                if not shareSpineCache:hasSpineCacheData(cardPath) then
                    shareSpineCache:addCacheData(cardPath, waiterData.skinId, 0.4)
                end
            end

            local waiterIndex = checkint(waiterSiteId) - 3
            local waiterTile  = WaiterPositions[waiterIndex]
            local friendData  = {
                siteId        = waiterSiteId,
                cardId        = waiterData.cardId,
                skinId        = waiterData.skinId,
                vigour        = waiterData.vigour,
                maxVigour     = waiterData.maxVigour,
                breakLevel    = waiterData.breakLevel,
                businessSkill = waiterData.businessSkill,
                cardName      = waiterData.cardName,
            }
            local waiterRole  = WaiterRoleNode.new({id = cardId, avatarId = cardId, skinId = waiterData.skinId, nType = RESTAURANT_ROLE_TYPE.Waiters, friendData = friendData})
            display.commonUIParams(waiterRole, {ap = display.CENTER_BOTTOM, po = cc.p((waiterTile.w - 0.5) * RESTAURANT_TILED_SIZE, (waiterTile.h - 0.5) * RESTAURANT_TILED_SIZE)})
            self:getViewData().waiterLayer:addChild(waiterRole)
            waiterRole:setLocalZOrder(RESTAURANT_TILED_SIZE - waiterTile.h)
            waiterRole:WillShowExpression()  -- 显活力值表情的逻辑
        end
    end
end
function FriendAvatarView:reloadCustomers(seatMap, avatarMap, friendId)
    for seatKey, customerData in pairs(seatMap or {}) do
        local dragNode = self:getDragNode(seatKey)
        if dragNode then
            dragNode:AddVisitor(seatKey, {
                npcType   = RESTAURANT_ROLE_TYPE.Visitors,
                avatarId  = customerData.customerId,
                visitorId = customerData.customerUuid,
                isEating  = checkint(customerData.isEating),
                locations = avatarMap,
                friendData = {
                    friendId  = friendId,
                    locations = avatarMap,
                    seatData  = {
                        seatId            = seatKey,
                        customerId        = customerData.customerId,
                        isSpecialCustomer = customerData.isSpecialCustomer,
                        questEventId      = customerData.questEventId,
                        isEating          = customerData.isEating,
                        recipeId          = customerData.recipeId,
                        recipeNum         = customerData.recipeNum,
                        leftSeconds       = 0,
                        hasCustomer       = 0,
                    }
                }
            })
        end
    end
end
function FriendAvatarView:getDragNode(seatKey)
    local seatKeyIds = string.split(seatKey, '_')
    local avatarUuid = seatKeyIds[1]
    local additionId = seatKeyIds[2]
    return self.avatarNodeMap_[tostring(avatarUuid)]
end


function FriendAvatarView:cleanBugs()
    self:getViewData().bugLayer:removeAllChildren()
end
function FriendAvatarView:reloadBugs(bugList, friendId)
    local friendData = {
        friendId = friendId
    }
    for _, bugAreaId in ipairs(bugList or {}) do
        local bugNode = AvatarBugNode.new(bugAreaId, friendData)
        self:getViewData().bugLayer:addChild(bugNode)
    end
end
function FriendAvatarView:removeBugAt(areaId)
    local areaIndex = checkint(areaId)
    local bugNode   = self:getViewData().bugLayer:getChildByTag(areaIndex)
    if bugNode then
        bugNode:clean()
    end
end


return FriendAvatarView

--avatar节点的逻辑类
local GameScene = require( "Frame.GameScene" )

local AvatarView = class('AvatarView',GameScene)


local DragNode = require('Game.views.restaurant.DragNode')
local AvatarNode = require('common.RestaurantAvatarNode')
local GoodPurchaseNode = require('common.GoodPurchaseNode')

local RemindIcon = require('common.RemindIcon')
local OrderTags = {
    BG_TAG = 80,
    FLOOR_TAG = 100, -- 地板
    CEIL_TAG = 1003, --吊顶物件
    BUG_TAG = 1004, -- 虫子
    EFFECT_TAG = 1005, -- 全屏特效
}

local VIEW_SIZE = cc.size(1334, 1002)
local VIEW_CENTER_X = checkint(VIEW_SIZE.width / 2)
local TILED_SIZE = RESTAURANT_TILED_SIZE

-- local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local shareFacade = AppFacade.GetInstance()


function AvatarView:ctor(...)
	self.super.ctor(self,'views.AvatarView')
    local args = unpack({...})
    self.ids = args.ids -- 所有的id列表

    self.viewData = nil

    local function CreateView()
        local view = CLayout:create(VIEW_SIZE)
        display.commonUIParams(view, {po = display.center})
        view:setName('AvatarView')
        self:addChild(view)

        local debugDraw = nil
        if DEBUG then
            debugDraw = cc.DrawNode:create(2)
            view:addChild(debugDraw)
            debugDraw:setLocalZOrder(1)
        end
        local dragArea = cc.DrawNode:create(3)
        view:addChild(dragArea)
        dragArea:setLocalZOrder(1)

        ---UI层的视图
        local uiBg = display.newImageView(_res('avatar/ui/restaurant_main_bg_bottom_home'),display.cx + 400,0)
        display.commonUIParams(uiBg, {ap = display.CENTER_BOTTOM})
        local bsize = cc.size(display.width,150)
        local bottomView = CLayout:create(bsize)
        display.commonUIParams(bottomView, { ap = display.CENTER_BOTTOM, po = cc.p(display.cx, 0)})
        bottomView:setName('BottomView')
        self:addChild(bottomView,10)
        bottomView:addChild(uiBg)

        -------------------------------------------------
        -- door
        local lobbyInfoButton = display.newButton(display.cx - 95,8,{
            n = _res('avatar/ui/restaurant_main_anime_door'),ap = display.CENTER_BOTTOM
        })
        -- display.commonLabelParams(lobbyInfoButton, fontWithColor(14,{text = __('餐厅信息'), offset = cc.p(0, - 56)}))
        lobbyInfoButton:setName('lobbyInfoButton')
        bottomView:addChild(lobbyInfoButton,1)

        local doorAvatar = sp.SkeletonAnimation:create('avatar/animate/restaurant_main_anime_crowd.json','avatar/animate/restaurant_main_anime_crowd.atlas', 1.0)
        display.commonUIParams(doorAvatar, {po = utils.getLocalCenter(lobbyInfoButton)})
        lobbyInfoButton:addChild(doorAvatar,1)
        doorAvatar:setToSetupPose()
        doorAvatar:setAnimation(0, 'idle', true)
        doorAvatar:setVisible(false)

        -------------------------------------------------
        -- decorate button
        local gotoAvatarButton = display.newButton(display.cx + 582,60,{
            n = _res('ui/common/story_tranparent_bg'),scale9 = true, size = cc.size(136,126)
        })
        gotoAvatarButton:setName('gotoAvatarButton')
        bottomView:addChild(gotoAvatarButton,1)

        local qAvatar = sp.SkeletonAnimation:create('avatar/animate/restaurant_main_anime_decorate.json','avatar/animate/restaurant_main_anime_decorate.atlas', 1.0)
        display.commonLabelParams(gotoAvatarButton, fontWithColor(14,{text = __('装修'), offset = cc.p(0, - 40)}))
        display.commonUIParams(qAvatar, {po = utils.getLocalCenter(gotoAvatarButton)})
        gotoAvatarButton:getLabel():setLocalZOrder(2)
        gotoAvatarButton:addChild(qAvatar,1)
        qAvatar:setToSetupPose()
        qAvatar:setAnimation(0, 'idle', true)

        local redPointIcon = display.newImageView(_res('ui/common/common_hint_circle_red_ico.png'), 136 - 15, 126 - 10)
        redPointIcon:setVisible(false)
        redPointIcon:setName('redPointIcon')
        gotoAvatarButton:addChild(redPointIcon, 1)

        -------------------------------------------------
        -- board frame
        local restuarantButton = display.newButton(display.cx - 315,0,{
            n = _res('avatar/ui/recipeMess/restaurant_bg_selling_board'),ap = display.LEFT_BOTTOM
        })
        -- display.commonLabelParams(restuarantButton, fontWithColor(14,{text = __('厨房')}))
        self:addChild(restuarantButton,10)

        local t = {
            {img = _res("avatar/ui/recipeMess/restaurant_ico_selling_leaf.png")},
            {img = _res("avatar/ui/recipeMess/restaurant_ico_selling_plates.png")},
            {img = _res("avatar/ui/recipeMess/restaurant_ico_selling_timer.png")},
        }
        local someThingMess = {}
        for i,v in ipairs(t) do
            local tempImg = display.newImageView(v.img, 22, 6 + 24*(i-1),--
            {ap = cc.p(0, 0)})
            restuarantButton:addChild(tempImg,3)

            --
            local lineImg = display.newImageView(_res('avatar/ui/recipeMess/restaurant_ico_selling_line2'), 25, 2+ 24*(i-1),--
            {ap = cc.p(0, 0)})
            restuarantButton:addChild(lineImg,3)


            local tempLabel = display.newLabel( 125, 2 + 24*(i-1),
                fontWithColor(14,{fontSize = 18, text = tostring(i),ap = cc.p(1,0)}))--e0491a
            restuarantButton:addChild(tempLabel,1)

            table.insert(someThingMess,tempLabel)
        end

        -------------------------------------------------
        -- event
        -- local eventButton  = display.newButton(display.cx - 155,58,{
        --     n = _res('avatar/ui/restaurant_main_btn_event'),
        -- })
        -- eventButton:setVisible(false)
        -- display.commonLabelParams(eventButton, fontWithColor(14,{text = '', color ='ffffff', }))
        -- bottomView:addChild(eventButton,1)

        -- local eventTimeLabel = display.newLabel(eventButton:getPositionX(), 20,fontWithColor(14,{fontSize = 20, text = '', color = 'ffffff'}))
        -- eventTimeLabel:setVisible(false)
        -- bottomView:addChild(eventTimeLabel,2)

        -------------------------------------------------
        -- functions
        local tt = {
            {id = RemindTag.LOBBY_TASK, name = 'LOBBY_TASK',pos = cc.p(712, 62), text = __('任务'), image = _res('avatar/ui/restaurant_ico_task')},
            {id = RemindTag.LOBBY_DISH, name = 'LOBBY_DISH',pos = cc.p(836, 62), text = __('备菜'),image = _res('avatar/ui/restaurant_ico_kitchen')},
            {id = RemindTag.LOBBY_MEMBER, name = 'LOBBY_MEMBER', pos = cc.p(962, 62), text = __('雇员'),image = _res('avatar/ui/restaurant_ico_office')},
            {id = RemindTag.LOBBY_INFORMATION, name = 'LOBBY_INFORMATION', pos = cc.p(1084, 62), text = __('情报'),image = _res('avatar/ui/restaurant_ico_info')},
            -- {id = RemindTag.LOBBY_SHOP, name = 'LOBBY_SHOP', pos = cc.p(display.size.width - 64, display.size.height - TOP_HEIGHT - 44), text = __('小费商城'),image = _res('ui/home/nmain/restaurant_ico_tip_shop')},
        }
        local actionButtons = {}
        for idx,val in ipairs(tt) do
            local btn = display.newButton(0, 0, {n = _res(val.image)})
            display.commonUIParams(btn, {po = cc.p(display.cx + (val.pos.x - 1334/2) + 8, val.pos.y)})
            bottomView:addChild(btn)
            btn:setName(val.name)
            btn:setTag(val.id)
            RemindIcon.addRemindIcon({parent = btn, tag = val.id, po = cc.p(btn:getContentSize().width * 0.5 + 28, btn:getContentSize().height * 0.5 + 24)})
            local nameLabel = display.newButton(btn:getContentSize().width * 0.5, 10, {n = _res('avatar/ui/main_bg_name_ico')})
            display.commonLabelParams(nameLabel,fontWithColor(14, {reqW = 85, fontSize = 22, text = val.text, color = 'ffffff'}))
            btn:addChild(nameLabel,2)
            table.insert( actionButtons, btn )
        end

        -------------------------------------------------
        -- 聊天入口
        local chatBtn = nil
        if ChatUtils.IsModuleAvailable() then
            chatBtn = require('common.CommonChatPanel').new()
            display.commonUIParams(chatBtn, {po = cc.p(0, 0), ap = display.LEFT_BUTTOM})
            self:addChild(chatBtn)
        end
        
        -------------------------------------------------
        local bgSize = cc.size(display.width, 80)
        local moneyNode = CLayout:create(bgSize)
        moneyNode:setName('TOP_LAYOUT')
        display.commonUIParams(moneyNode, {ap = display.CENTER_TOP, po = cc.p(display.cx, display.height)})
        self:addChild(moneyNode,100)

        local backBtn = display.newButton(0, 0, {n = _res("ui/common/common_btn_back")})
        display.commonUIParams(backBtn, {po = cc.p(display.SAFE_L + backBtn:getContentSize().width * 0.5 + 30, bgSize.height - 18 - backBtn:getContentSize().height * 0.5)})
        backBtn:setName('btn_backButton')
        moneyNode:addChild(backBtn, 5)
        -- top icon
        local imageImage = display.newImageView(_res('ui/home/nmain/main_bg_money.png'),0,0,{enable = false, scale9 = true, size = cc.size(860 + display.SAFE_L,54)})
        display.commonUIParams(imageImage,{ap = cc.p(1.0,1.0), po = cc.p(display.width,80)})
        moneyNode:addChild(imageImage)
        local moneyNods = {}
        local iconData = args.iconIds or {TIPPING_ID,POPULARITY_ID, GOLD_ID, DIAMOND_ID}
        for i,v in ipairs(iconData) do
            local purchaseNode = GoodPurchaseNode.new({id = v, animate = true})
            display.commonUIParams(purchaseNode,
            {ap = cc.p(1, 0.5), po = cc.p(display.SAFE_R - 20 - (( 4 - i) * (purchaseNode:getContentSize().width + 16)), imageImage:getPositionY()- 26)})
            moneyNode:addChild(purchaseNode, 5)
            purchaseNode:setName('purchaseNode' .. i)
            purchaseNode.viewData.touchBg:setTag(checkint(v))
            moneyNods[tostring( v )] = purchaseNode
        end

        local bugLayer = display.newLayer()
        bugLayer:setLocalZOrder(OrderTags.BUG_TAG)
        view:addChild(bugLayer)
        
        local effectLayer = display.newLayer(VIEW_SIZE.width/2, VIEW_SIZE.height/2, {ap = display.CENTER})
        effectLayer:setLocalZOrder(OrderTags.EFFECT_TAG)
        view:addChild(effectLayer)

        -------------------------------------------------
        -- shop
        local shopBtn = display.newButton(0, 0, {n = _res('ui/home/nmain/restaurant_ico_tip_shop')})
        display.commonUIParams(shopBtn, {po = cc.p(display.SAFE_R - 64, display.size.height - TOP_HEIGHT - 44)})
        self:addChild(shopBtn)
        shopBtn:setName(__('小费商城'))
        shopBtn:setTag(RemindTag.LOBBY_SHOP)
        RemindIcon.addRemindIcon({parent = shopBtn, tag = RemindTag.LOBBY_SHOP, po = cc.p(shopBtn:getContentSize().width * 0.5 + 28, shopBtn:getContentSize().height * 0.5 + 24)})
        display.commonLabelParams(shopBtn,fontWithColor(14, {text = __('小费商城'),w= 120 , hAlign = display.TAC ,color = 'ffffff',offset = cc.p(0,-26)}))

        -- 餐厅 活动 layer  分享 显示时 隐藏餐厅活动layer
        local avatarTopBtnLayer = display.newLayer(display.SAFE_R - 120, display.size.height - TOP_HEIGHT - 44, {ap = display.RIGHT_CENTER, size = cc.size(100, 100)})
        self:addChild(avatarTopBtnLayer)
        --添加分享按钮
        local btnView = CLayout:create(cc.size(132,88))
        -- btnView:setBackgroundColor(cc.c4b(100,100,100,100))
        local shareBtn = require('common.CommonShareButton').new({})
        display.commonUIParams(shareBtn, {po = cc.p(
                    66, 44)})
        btnView:addChild(shareBtn,1)
        --[[ local bgImage = display.newImageView(_res('share/main_bg_go_restaurant'),66,0, {ap = display.CENTER_BOTTOM, scale9 = true, size = cc.size(132, 30)}) ]]
        -- local titleLabel = display.newLabel(10, 15, fontWithColor(14,{ap = display.LEFT_CENTER,text = string.fmt(__('奖励%1'), 20), fontSize = 22}))
        -- local goodIconPath = CommonUtils.GetGoodsIconPathById(DIAMOND_ID)
        -- local icon = display.newImageView(goodIconPath,124,15,{ap = display.RIGHT_CENTER})
        -- icon:setScale(0.2)
        -- bgImage:addChild(icon)
        -- bgImage:addChild(titleLabel)
        --[[ btnView:addChild(bgImage,2) ]]
        display.commonUIParams(btnView, {po = cc.p(shopBtn:getPositionX() - 140, display.size.height - TOP_HEIGHT - 44)})
        btnView:setName('SHARE_BUTTON')
        btnView:setVisible(false)
        self:addChild(btnView)

        -------------------------------------------------
        -- 好友
        local friendBtn = display.newButton(display.SAFE_R + 4, (display.size.height - TOP_HEIGHT) / 2 + 60, {n = _res('avatar/ui/restaurant_btn_my_friends'), ap = display.RIGHT_CENTER})
        friendBtn:setTag(RemindTag.LOBBY_FRIEND)
        self:addChild(friendBtn, GameScene.TAGS.TagGameLayer)
        -- RemindIcon.addRemindIcon({parent = friendBtn, tag = RemindTag.LOBBY_FRIEND, po = cc.p(friendBtn:getContentSize().width * 0.5 + 28, friendBtn:getContentSize().height * 0.5 + 24)})

		return {
            view                  = view,
            drawNode              = dragArea,
            debugDraw             = debugDraw,
            bottomView            = bottomView,
			navBackButton         = backBtn,
			moneyNods             = moneyNods,
            lobbyInfoButton       = lobbyInfoButton,
            gotoAvatarButton      = gotoAvatarButton,
            shareBtn              = shareBtn,
            shareView             = btnView,
            restuarantButton      = restuarantButton,
            -- eventButton      = eventButton,
            actionButtons         = actionButtons,
            -- eventTimeLabel   = eventTimeLabel,
            doorAvatar            = doorAvatar,
            shopBtn               = shopBtn,
            someThingMess         = someThingMess,
            friendBtn             = friendBtn,
            bugLayer              = bugLayer,
            effectLayer           = effectLayer,
            chatBtn               = chatBtn,
            avatarTopBtnLayer     = avatarTopBtnLayer,
        }
    end

    self.viewData = CreateView()
    self:UpdateCountUI()

    -- self:addChild(display.newImageView(_res('avatar/ui/restaurant_anime_door.png'), display.SAFE_L, display.cy, {ap = display.RIGHT_CENTER}), 101)
    -- self:addChild(display.newImageView(_res('avatar/ui/restaurant_anime_door.png'), display.SAFE_R, display.cy, {ap = display.LEFT_CENTER}), 101)
end

--更新数量ui值
function AvatarView:UpdateCountUI()
	if self.viewData.moneyNods then
		for id,v in pairs(self.viewData.moneyNods) do
			v:updataUi(checkint(id)) --刷新每一个金币数量
		end
	end
end
--[[
--初始化物件
--]]
function AvatarView:InitViews(ids)
    for idx,val in pairs(ids or checktable(self.ids)) do
        local avatarId = checkint(val.goodsId)
        local avatarConfig =  CommonUtils.GetConfigNoParser('restaurant', 'avatar', avatarId)
        local avatarLocationsConfig =  CommonUtils.GetConfigNoParser('restaurant', 'avatarLocation', avatarId)
        if avatarConfig and avatarLocationsConfig then
            local nType = RestaurantUtils.GetAvatarSubType(avatarConfig.mainType, avatarConfig.subType)
            local centerX = checkint(VIEW_SIZE.width / 2)
            -- wall
            if nType == RESTAURANT_AVATAR_TYPE.WALL  then
                local location = string.split(avatarLocationsConfig.location[1], ',')
                local imageView = AvatarNode.new({confId = avatarId, x = VIEW_CENTER_X, y = location[2], ap = display.CENTER_BOTTOM})
                imageView:setUserTag(avatarId)
                imageView:setLocalZOrder(2)
                imageView:setName('OrderTags.BG_TAG')
                self.viewData.view:addChild(imageView)

            -- floor
            elseif nType == RESTAURANT_AVATAR_TYPE.FLOOR then
                local location = string.split(avatarLocationsConfig.location[1], ',')
                local imageView = AvatarNode.new({confId = avatarId, x = VIEW_CENTER_X, y = location[2], ap = display.CENTER_BOTTOM})
                imageView:setLocalZOrder(1)
                imageView:setUserTag(avatarId)
                imageView:setName('OrderTags.FLOOR_TAG')
                self.viewData.view:addChild(imageView)

            -- ceiling
            elseif nType == RESTAURANT_AVATAR_TYPE.CEILING then
                local location = string.split(avatarLocationsConfig.location[1], ',')
                local imageView = AvatarNode.new({confId = avatarId, x = VIEW_CENTER_X, y = location[2], ap = display.CENTER_BOTTOM})
                imageView:setLocalZOrder(OrderTags.CEIL_TAG)
                imageView:setUserTag(avatarId)
                imageView:setName('OrderTags.CEIL_TAG')
                self.viewData.view:addChild(imageView, OrderTags.CEIL_TAG)

            -- other
            else
                --其他可拖动类型的建立
                self:AddAvatarComponents(val, nType)
            end
        end
    end
end

function AvatarView:CreateAvatarTopBtns()
    local avatarTopBtnLayer = self.viewData.avatarTopBtnLayer
    local btnsData = {
        {imgPath = _res('ui/home/nmain/restaurant_ico_tip_shop'), name = __('小费商城'), color = 'ffffff', offset = cc.p(0,-26), tag = RemindTag.LOBBY_SHOP}
    }

end

function AvatarView:ReplaceFixParts(atype, avatarId)
    local avatarLocationsConfig =  CommonUtils.GetConfigNoParser('restaurant', 'avatarLocation', avatarId)

    -- wall
    if atype == RESTAURANT_AVATAR_TYPE.WALL then
        -- local imageView = self.viewData.view:getChildByTag(OrderTags.BG_TAG)
        local imageView = self.viewData.view:getChildByName('OrderTags.BG_TAG')
        local oldGoodsId = 0
        if imageView then
            oldGoodsId = imageView:getUserTag()
            imageView:removeFromParent()
        end
        --添加新的
        local location  = string.split(avatarLocationsConfig.location[1], ',')
        local imageView = AvatarNode.new({confId = avatarId, x = VIEW_CENTER_X, y = location[2], ap = display.CENTER_BOTTOM})
        imageView:setUserTag(avatarId)
        imageView:setName('OrderTags.BG_TAG')
        self.viewData.view:addChild(imageView, 2)
        return oldGoodsId,avatarId

    -- floor
    elseif atype == RESTAURANT_AVATAR_TYPE.FLOOR then
        local imageView = self.viewData.view:getChildByName('OrderTags.FLOOR_TAG')
        local oldGoodsId = 0
        if imageView then
            oldGoodsId = imageView:getUserTag()
            imageView:removeFromParent()
        end
        --添加新的
        local location  = string.split(avatarLocationsConfig.location[1], ',')
        local imageView = AvatarNode.new({confId = avatarId, x = VIEW_CENTER_X, y = location[2], ap = display.CENTER_BOTTOM})
        imageView:setUserTag(avatarId)
        imageView:setName('OrderTags.FLOOR_TAG')
        self.viewData.view:addChild(imageView, 1)
        return oldGoodsId,avatarId

    -- ceiling
    elseif atype == RESTAURANT_AVATAR_TYPE.CEILING then
        local imageView = self.viewData.view:getChildByName('OrderTags.CEIL_TAG')
        local oldGoodsId = 0
        if imageView then
            oldGoodsId = imageView:getUserTag()
            imageView:removeFromParent()
        end
        --添加新的
        local location  = string.split(avatarLocationsConfig.location[1], ',')
        local imageView = AvatarNode.new({confId = avatarId, x = VIEW_CENTER_X, y = location[2], ap = display.CENTER_BOTTOM})
        imageView:setUserTag(avatarId)
        imageView:setName('OrderTags.CEIL_TAG')
        self.viewData.view:addChild(imageView, OrderTags.CEIL_TAG)
        return oldGoodsId,avatarId
    end
end
---[[
--添加相关的组件
--]]
function AvatarView:AddAvatarComponents(val, nType)
    local avatarId = checkint(val.goodsId)
    local avatarConfig =  CommonUtils.GetConfigNoParser('restaurant', 'avatar', avatarId)
    local locationConfig =  CommonUtils.GetConfigNoParser('restaurant', 'avatarLocation', avatarId)
    if nType >= RESTAURANT_AVATAR_TYPE.CHAIR_SIGNLE then
        --拖动区域的东西
        local mediator = AppFacade.GetInstance():RetrieveMediator('AvatarMediator')
        if mediator then
            local dragNode = DragNode.new({id = val.id, avatarId = avatarId, nType = nType, configInfo = locationConfig, effectLayer = self.viewData.effectLayer})
            display.commonUIParams(dragNode, {ap = display.LEFT_BOTTOM,po = cc.p(val.location.x, val.location.y)})
            dragNode:setUserTag(checkint(val.id))
            local tile = RestaurantUtils.ConvertPixelsToTiled(cc.p(val.location.x,val.location.y))
            dragNode:setLocalZOrder(RESTAURANT_TILED_HEIGHT - tile.h)
            self.viewData.view:addChild(dragNode)
            local t = mediator:ConvertRectAreaToTileds(cc.rect(val.location.x,val.location.y, checkint(locationConfig.collisionBoxWidth),checkint(locationConfig.collisionBoxLength)))
            mediator:UpdateTileState(t, false)
        end
    end
end
--[[
--是否画出可拖放的区域
--]]
function AvatarView:GimosDraw(enable)
    if enable then
        self.viewData.drawNode:clear()
        self.viewData.drawNode:drawSolidRect(cc.p(DRAG_AREA_RECT.x, DRAG_AREA_RECT.y), cc.p(DRAG_AREA_RECT.x + DRAG_AREA_RECT.width,DRAG_AREA_RECT.y + DRAG_AREA_RECT.height), cc.c4f(1.0,0.6,0.6,0.6))
        self.viewData.drawNode:drawRect(cc.p(DRAG_AREA_RECT.x, DRAG_AREA_RECT.y), cc.p(DRAG_AREA_RECT.x + DRAG_AREA_RECT.width,DRAG_AREA_RECT.y + DRAG_AREA_RECT.height), cc.c4f(1.0,0.3,0.3,1.0))
        --画路径
    else
        self.viewData.drawNode:clear()
    end
end

--[[
--@id npc 角色id
--@nType npc类型是服务员还是食客
--]]
function AvatarView:ConstructNpc(id,avatarId, nType, tile, isLeave)
    local roleNode = nil
    if nType == 1 then
        local gameMgr    = AppFacade.GetInstance():GetManager("GameManager")
        local cardData   = gameMgr:GetCardDataByCardId(checkint(avatarId))
        local cardSkinId = tostring(cardData.defaultSkinId)
        roleNode = require('Game.views.restaurant.RoleNode').new({id = id, avatarId = avatarId, nType = nType, skinId = cardSkinId})
    else
        roleNode = require('Game.views.restaurant.RoleNode').new({id = id, avatarId = avatarId, nType = nType})
    end
    if isLeave ~= nil then roleNode.isLeave = checkbool(isLeave) end
    if nType == 1 then --服务员
        if tile then
            display.commonUIParams(roleNode, {ap = display.CENTER_BOTTOM, po = cc.p((tile.w - 0.5) * TILED_SIZE,(tile.h - 0.5) * TILED_SIZE)})
        end
    elseif nType == 2 then --来客
        display.commonUIParams(roleNode, {ap = display.CENTER_BOTTOM, po = cc.p(256 + 300,8 + TILED_SIZE* 10)})
    end
    roleNode:setUserTag(id)
    roleNode:setTag(checkint(id) + 1000)
    self.viewData.view:addChild(roleNode)
    return roleNode
end

function AvatarView:onCleanup()
end

function AvatarView:addBugAt(areaId)
    local areaIndex = checkint(areaId)
    local bugNode   = require('Game.views.restaurant.BugNode').new(areaIndex)
    self.viewData.bugLayer:addChild(bugNode)
end
function AvatarView:removeBugAt(areaId)
    local areaIndex = checkint(areaId)
    local bugNode   = self.viewData.bugLayer:getChildByTag(areaIndex)
    if bugNode then
        bugNode:clean()
    end
end

return AvatarView

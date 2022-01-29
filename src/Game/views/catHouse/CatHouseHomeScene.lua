--[[
 * author : kaishiqi
 * descpt : 猫屋 - 主界面 场景
]]
local GameScene         = require('Frame.GameScene')
local DecorLayer        = require('Game.views.catHouse.CatHouseDecorateView')
local AvatarLayer       = require('Game.views.catHouse.CatHouseAvatarView')
local FriendLayer       = require('Game.views.catHouse.CatHouseFriendView')
local CatHouseHomeScene = class('CatHouseHomeScene', GameScene)

local RES_DICT = {
    --              = top
    COM_BACK_BTN    = _res('ui/common/common_btn_back.png'),
    COM_TITLE_BAR   = _res('ui/common/common_title.png'),
    COM_TIPS_ICON   = _res('ui/common/common_btn_tips.png'),
    BTN_UI_NORMAL   = _res('ui/catHouse/home/cat_house_ico_open.png'),
    BTN_UI_SELECTED = _res('ui/catHouse/home/cat_house_ico_close.png'),
    --              = bottom
    SHOW_BTN        = _res('ui/catHouse/home/cat_house_ico_show.png'),
    CAT_BTN         = _res('ui/catHouse/home/cat_house_ico_cat.png'),
    COLL_BTN        = _res('ui/catHouse/home/cat_house_ico_collect.png'),
    DECOR_BTN       = _res('ui/catHouse/home/cat_house_ico_decoration.png'),
    INFO_BTN        = _res('ui/catHouse/home/cat_house_ico_information.png'),
    SHOP_BTN        = _res('ui/catHouse/home/cat_house_ico_shops.png'),
    --              = right
    RANK_BTN        = _res('ui/catHouse/home/cat_house_ico_ranking.png'),
    FRIEND_BTN      = _res('avatar/ui/restaurant_btn_my_friends.png'),
    --              = left
    EVENT_BTN       = _res('ui/catHouse/home/cat_house_ico_events.png'),
    FUNC_NAME_BAR   = _res('ui/catHouse/home/cat_icon_name_bg.png'),
    SKIN_HEAD_FRAME = _res('ui/home/handbook/pokedex_card_bg_skin_head.png'),
    SKIN_HEAD_MASK  = _res('ui/home/handbook/pokedex_card_bg_skin_head_unlock.png'),
    BTN_NORMAL      = _res("update/common_btn_orange.png"),
    HEAD_DETAIL_BG  = _res('ui/catHouse/home/common_bg_tips.png'),
    HOME_TITLE_BG   = _res('ui/catHouse/home/cat_friend_name_bg.png'),
    --              = center
    SWITCH_DOOR     = _res('avatar/ui/restaurant_anime_door.png'),
    --              = event
    EVENT_BG        = _res('ui/catHouse/home/common_bg_tips.png'),
    EVENT_BG_ARROW  = _res('ui/catHouse/home/common_bg_tips_horn.png'),
    TITLE_LINE      = _res('ui/catHouse/home/kitchen_tool_split_line.png'),
    LINE_BG         = _res('ui/catHouse/home/restaurant_ico_selling_line.png'),
    RED_ICON        = _res('ui/common/common_hint_circle_red_ico.png'),
    EVENT_INFO_BG   = _res('ui/catHouse/event/cat_event_bg_1.png'),
    EVENT_BTN_N     = _res('ui/catHouse/event/cat_btn_tab_default.png'),
    EVENT_BTN_S     = _res('ui/catHouse/event/cat_btn_tab_select.png'),
}

local BTN_TAG = {
    DISPLAY  = 1001,
    INFO     = 1002,
    SHOP     = 1003,
    COLLECT  = 1004,
    CAT      = 1005,
    DECORATE = 1006,
}

local SLIDE_FRIEND_SHOW_TAG = {
    [BTN_TAG.INFO]    = 1,
    [BTN_TAG.COLLECT] = 2,
}

local SLIDE_SELF_SHOW_TAG = {
    [BTN_TAG.DISPLAY]  = 1,
    [BTN_TAG.INFO]     = 2,
    [BTN_TAG.SHOP]     = 3,
    [BTN_TAG.COLLECT]  = 4,
    [BTN_TAG.CAT]      = 5,
    [BTN_TAG.DECORATE] = 6,
}

local SLIDE_BTN_INFO = {
    [BTN_TAG.DISPLAY]  = {title = __("展示"),  img = RES_DICT.SHOW_BTN},
    [BTN_TAG.INFO]     = {title = __("信息"),  img = RES_DICT.INFO_BTN},
    [BTN_TAG.SHOP]     = {title = __("商店"),  img = RES_DICT.SHOP_BTN},
    [BTN_TAG.COLLECT]  = {title = __("收藏柜"), img = RES_DICT.COLL_BTN},
    [BTN_TAG.CAT]      = {title = __("猫咪"),  img = RES_DICT.CAT_BTN},
    [BTN_TAG.DECORATE] = {title = __("装修"),  img = RES_DICT.DECOR_BTN},
}


function CatHouseHomeScene:ctor(args)
    self.super.ctor(self, 'Game.views.catHouse.CatHouseHomeScene')

    -- create view
    self.viewData_ = CatHouseHomeScene.CreateView()
    self:addChild(self.viewData_.view)
end


function CatHouseHomeScene:getViewData()
    return self.viewData_
end


function CatHouseHomeScene:getEventViewData()
    return self:getViewData().eventViewData
end


function CatHouseHomeScene:showUI(endCB)
    local viewData = self:getViewData()
    viewData.topLayer:setPosition(viewData.topLayerHidePos)
    viewData.titleBtn:setPosition(viewData.titleBtnHidePos)
    viewData.titleBtn:runAction(cc.EaseBounceOut:create(cc.MoveTo:create(1, viewData.titleBtnShowPos)))
    
    local actTime = 0.2
    self:runAction(cc.Sequence:create({
        cc.TargetedAction:create(viewData.topLayer, cc.MoveTo:create(actTime, viewData.topLayerShowPos)),
        cc.CallFunc:create(function()
            if endCB then endCB() end
        end)
    }))
end


function CatHouseHomeScene:initChatPanel()
    if self:getViewData().chatPanel then
        self:getViewData().chatPanel:delayInit()
    end
end


function CatHouseHomeScene:updateUIVisible(visible)
    self:getViewData().topLayer:stopAllActions()
    self:getViewData().bottomLayer:stopAllActions()
    self:getViewData().leftLayer:stopAllActions()
    self:getViewData().rightLayer:stopAllActions()
    if visible then
        self:getViewData().topLayer:runAction(cc.Spawn:create(cc.FadeIn:create(0.5), cc.MoveTo:create(0.5, cc.p(0, 0))))
        self:getViewData().bottomLayer:runAction(cc.Spawn:create(cc.FadeIn:create(0.5), cc.MoveTo:create(0.5, cc.p(0, 0))))
        self:getViewData().leftLayer:runAction(cc.Spawn:create(cc.FadeIn:create(0.5), cc.MoveTo:create(0.5, cc.p(0, 0))))
        self:getViewData().rightLayer:runAction(cc.Spawn:create(cc.FadeIn:create(0.5), cc.MoveTo:create(0.5, cc.p(0, 0))))
    else
        self:getViewData().topLayer:runAction(cc.Spawn:create(cc.FadeOut:create(0.5), cc.MoveTo:create(0.5, cc.p(0, 200))))
        self:getViewData().bottomLayer:runAction(cc.Spawn:create(cc.FadeOut:create(0.5), cc.MoveTo:create(0.5, cc.p(0, -200))))
        self:getViewData().leftLayer:runAction(cc.Spawn:create(cc.FadeOut:create(0.5), cc.MoveTo:create(0.5, cc.p(-200, 0))))
        self:getViewData().rightLayer:runAction(cc.Spawn:create(cc.FadeOut:create(0.5), cc.MoveTo:create(0.5, cc.p(200, 0))))
    end
end

-------------------------------------------------
-- event update

function CatHouseHomeScene:isEventViewVisible()
    return self:getEventViewData().view:isVisible()
end
function CatHouseHomeScene:setEventViewVisible(statue)
    self:getEventViewData().view:setVisible(statue)
end


function CatHouseHomeScene:updateEventView(curEventNum)
    local eventViewData = self:getEventViewData()
    eventViewData.tableView:resetCellCount(curEventNum)
    eventViewData.emptyEventLayer:setVisible(curEventNum <= 0)
end


function CatHouseHomeScene:updateEventRedVisible(visible)
    local redIcon = self:getViewData().eventBtn:getChildByTag(1)
    if redIcon then
        redIcon:setVisible(visible)
    end
end
-------------------------------------------------
-- head udpate

function CatHouseHomeScene:setDisplayHeadId(skinId)
    local headIconPath = CardUtils.GetCardHeadPathBySkinId(skinId)
    self:getViewData().headImgLayer:removeAllChildren()
    self:getViewData().headImgLayer:addChild(ui.image({img = headIconPath, scale = 0.6}))
end


-------------------------------------------------
-- switch sceneMode

function CatHouseHomeScene:setSceneDisplayType(ownerId)
    local houseOwnerId     = checkint(ownerId)
    local ownerIsSelf      = app.gameMgr:IsPlayerSelf(houseOwnerId)
    local displayMap       = ownerIsSelf and SLIDE_SELF_SHOW_TAG or SLIDE_FRIEND_SHOW_TAG
    local displayBtnGroups = {}

    -- update funcBtnGroup
    for btnTag, btnNode in pairs(self:getViewData().funcBtnGroup) do
        if displayMap[btnTag] then
            displayBtnGroups[displayMap[btnTag]] = btnNode
        end
        btnNode:setVisible(displayMap[btnTag] ~= nil)
    end
    ui.flowLayout(cc.p(display.SAFE_R - 30, 20), displayBtnGroups, {ap = ui.rb, type = ui.flowH, gapW = 10})

    -- event button
    self:getViewData().eventBtn:setVisible(ownerIsSelf)

    -- house homeInfo
    self:getViewData().homeLayer:setVisible(not ownerIsSelf)

    if not ownerIsSelf then
        local friendData =  CommonUtils.GetFriendData(houseOwnerId)
        self:getViewData().firendHouseTitle:updateLabel({text = string.fmt(__("_name_的家"), {_name_ = tostring(friendData.name)}), fnt = FONT.D16})
        self:getViewData().friendHouseLvl:setString(string.fmt(__("御主之屋:_num_级"), {_num_ = checkint(friendData.houseLevel)}))
    end
end


-------------------------------------------------
-- switch decorting

function CatHouseHomeScene:setDecortingStatue(isDecorting)
    app.catHouseMgr:setDecoratingMode(isDecorting)
    self:getViewData().friendBtn:setVisible(not isDecorting)
    self:getViewData().eventBtn:setVisible(not isDecorting)
    self:getViewData().decorLayer:setVisible(isDecorting)
    -- self:getViewData().rankBtn:setVisible(not isDecorting)
    self:getViewData().funcBtnLayer:setVisible(not isDecorting)
    self:getViewData().skinHeadLayer:setVisible(not isDecorting)
    self:getViewData().uiButton:setVisible(not isDecorting)
    self:getViewData().avatarLayer:setDecortingStatue(isDecorting) 
    if self:getViewData().chatPanel then
        self:getViewData().chatPanel:setVisible(not isDecorting)
    end
end


-------------------------------------------------
-- door update

function CatHouseHomeScene:getSwitchDoorViewData()
    if not self.switchDoorViewData_ then
        self.switchDoorViewData_ = CatHouseHomeScene.CreateDoorView()
        app.uiMgr:GetCurrentScene():AddDialog(self.switchDoorViewData_.view)
    end
    return self.switchDoorViewData_
end


function CatHouseHomeScene:openSwitchDoor(endCb)
    self:getSwitchDoorViewData().view:setVisible(true)
    self:getSwitchDoorViewData().doorL:setPositionX(display.cx)
    self:getSwitchDoorViewData().doorR:setPositionX(display.cx)

    local actionTime = 0.25
    self:getSwitchDoorViewData().view:stopAllActions()
    self:getSwitchDoorViewData().view:runAction(cc.Sequence:create({
        cc.Spawn:create({
            cc.TargetedAction:create(self:getSwitchDoorViewData().doorL, cc.MoveTo:create(actionTime, cc.p(0, display.cy))),
            cc.TargetedAction:create(self:getSwitchDoorViewData().doorR, cc.MoveTo:create(actionTime, cc.p(display.width, display.cy)))
        }),
        cc.DelayTime:create(0.2),
        cc.CallFunc:create(function()
            self:getSwitchDoorViewData().view:setVisible(false)
            if endCb then endCb() end
        end)
    }))
end


function CatHouseHomeScene:closeSwitchDoor(endCb)
    self:getSwitchDoorViewData().view:setVisible(true)
    self:getSwitchDoorViewData().doorL:setPositionX(0)
    self:getSwitchDoorViewData().doorR:setPositionX(display.width)
    PlayAudioClip(AUDIOS.UI.ui_restaurant_enter.id)

    local actionTime = 0.25
    self:getSwitchDoorViewData().view:stopAllActions()
    self:getSwitchDoorViewData().view:runAction(cc.Sequence:create({
        cc.Spawn:create({
            cc.TargetedAction:create(self:getSwitchDoorViewData().doorL, cc.MoveTo:create(actionTime, display.center)),
            cc.TargetedAction:create(self:getSwitchDoorViewData().doorR, cc.MoveTo:create(actionTime, display.center))
        }),
        cc.DelayTime:create(0.2),
        cc.CallFunc:create(function()
            if endCb then endCb() end
        end)
    }))
end


function CatHouseHomeScene:updateHeadDetailViewVisible(visible)
    self:getViewData().skinHeadDetailNode:setVisible(visible)
end


-------------------------------------------------------------------------------
-- view define
-------------------------------------------------------------------------------

function CatHouseHomeScene.CreateView()
    local view = ui.layer()
    local size = view:getContentSize()
    local cpos = cc.sizep(size, ui.cc)

    -- block layer
    local blockLayer = ui.layer({color = cc.r4b(0), enable = true})
    view:add(blockLayer)


    ------------------------------------------------- [center]
    local centerLayer = ui.layer()
    view:add(centerLayer)

    -- avatar layer
    local avatarLayer = AvatarLayer.new()
    centerLayer:add(avatarLayer)

    -- btn ui
    local uiButton = ui.tButton({n = RES_DICT.BTN_UI_NORMAL, s = RES_DICT.BTN_UI_SELECTED})
    view:addList(uiButton):alignTo(nil, ui.rt, {offsetX = -display.SAFE_L, offsetY = -70})
    ------------------------------------------------- [bottom]
    local bottomLayer = ui.layer()
    view:add(bottomLayer)

    -- chat panel
    local chatPanel = nil
    if ChatUtils.IsModuleAvailable() then
        chatPanel = require('common.CommonChatPanel').new({channelId = CHAT_CHANNELS.CHANNEL_HOUSE})
        display.commonUIParams(chatPanel, {ap = display.LEFT_BUTTOM})
        bottomLayer:addChild(chatPanel)
    end

    -- home title
    local homeLayer = ui.layer({bg = RES_DICT.HOME_TITLE_BG})
    bottomLayer:addList(homeLayer):alignTo(nil, ui.lb, {offsetX = display.SAFE_L + 360})

    local homeInfoGroup = homeLayer:addList({
        ui.label({fnt = FONT.D17, text = "--"}),
        ui.image({img = RES_DICT.TITLE_LINE}),
        ui.label({fnt = FONT.D16, text = "--"}),
    })
    ui.flowLayout(cc.rep(cc.sizep(homeLayer, ui.cc), 0, -5), homeInfoGroup, {type = ui.flowV, ap = ui.cc})
    
    -- function buttons
    local funcBtnLayer = ui.layer()
    bottomLayer:add(funcBtnLayer)

    local funcBtnGroup = {}
    for btnTag, btnInfo in pairs(SLIDE_BTN_INFO) do
        local button = ui.button({n = btnInfo.img, tag = btnTag})
        funcBtnLayer:add(button)

        local title = ui.title({img = RES_DICT.FUNC_NAME_BAR, size = cc.size(100, 28), cut = cc.dir(5, 5, 5, 5)}):updateLabel({fnt = FONT.D14, fontSize = 22, text = btnInfo.title, reqW = 90})
        button:addList(title):alignTo(nil, ui.cb, {offsetY = -10})

        funcBtnGroup[btnTag] = button
    end
    
    ------------------------------------------------- [left]
    local leftLayer = ui.layer()
    view:add(leftLayer)
    
    -- event button
    local eventBtn = ui.button({n = RES_DICT.EVENT_BTN})
    leftLayer:addList(eventBtn):alignTo(nil, ui.lb, {offsetX = display.SAFE_L + 20, offsetY = 100})

    local eventTitle = ui.title({img = RES_DICT.FUNC_NAME_BAR, size = cc.size(100, 28), cut = cc.dir(5, 5, 5, 5)}):updateLabel({fnt = FONT.D14, fontSize = 22, text = __('今日事件'), reqW = 90})
    eventBtn:addList(eventTitle):alignTo(nil, ui.cb, {offsetY = -10})

    local eventRed = ui.image({img = RES_DICT.RED_ICON})
    eventRed:setTag(1)
    eventBtn:addList(eventRed):alignTo(nil, ui.rt, {offsetX = -10})

    -- skin head layer
    local skinHeadSize  = cc.size(106, 106)
    local skinHeadLayer = ui.layer({size = skinHeadSize, color = cc.r4b(0), enable = true})
    leftLayer:addList(skinHeadLayer):alignTo(nil, ui.lt, {offsetX = display.SAFE_L + 22, offsetY = -125})

    -- [clipNode | frameImg | titleBar]
    local skinHeadCPos  = cc.sizep(skinHeadSize, ui.cc)
    local skinHeadGroup = {
        ui.clipNode({size = skinHeadSize, stencil = {img = RES_DICT.SKIN_HEAD_MASK, scale = 0.86, p = skinHeadCPos}}),
        ui.image({img = RES_DICT.SKIN_HEAD_FRAME}),
        ui.title({img = RES_DICT.FUNC_NAME_BAR, mt = 50}):updateLabel({fnt = FONT.D14, fontSize = 22, text = __('更换形象'), reqW = 90})
    }
    skinHeadLayer:addList(skinHeadGroup)
    ui.flowLayout(skinHeadCPos, skinHeadGroup, {ap = ui.cc, type = ui.flowC})
    
    -- skin head image
    local headImgLayer = ui.layer({p = skinHeadCPos})
    skinHeadGroup[1]:add(headImgLayer)


    ------------------------------------------------- [right]
    local rightLayer = ui.layer()
    view:add(rightLayer)

    -- rank button
    local rankBtn = ui.button({n = RES_DICT.RANK_BTN})
    rightLayer:addList(rankBtn):alignTo(nil, ui.rt, {offsetX = -display.SAFE_L - 30, offsetY = -75})
    rankBtn:setVisible(false)

    local rankTitle = ui.title({img = RES_DICT.FUNC_NAME_BAR, size = cc.size(100, 28), cut = cc.dir(5, 5, 5, 5)}):updateLabel({fnt = FONT.D14, fontSize = 22, text = __('排行榜'), reqW = 90})
    rankBtn:addList(rankTitle):alignTo(nil, ui.cb, {offsetY = -10})

    -- friend button
    local friendBtn = ui.button({n = RES_DICT.FRIEND_BTN})
    rightLayer:addList(friendBtn):alignTo(nil, ui.rc, {offsetX = -display.SAFE_L + 4})


    ------------------------------------------------- detail layer
    -- head detail view
    local headDetailNode = ui.layer()
    headDetailNode:setVisible(false)
    view:add(headDetailNode)


    local headDetailGroup = headDetailNode:addList({
        ui.layer({color = cc.r4b(0), enable = true}),
        ui.layer({ap = ui.ct, bg = RES_DICT.HEAD_DETAIL_BG, size = cc.size(150, 230), scale9 = true, cut = cc.dir(5, 5, 5, 5)}),
    })
    local headDetailView = headDetailGroup[2]
    headDetailView:alignTo(skinHeadLayer, ui.cb, {offsetY = 30})

    local headDetailBtnGroups = headDetailView:addList({
        ui.button({n = RES_DICT.BTN_NORMAL}):updateLabel({fnt = FONT.D14, reqW = 110, text = __("形象")}),
        ui.button({n = RES_DICT.BTN_NORMAL}):updateLabel({fnt = FONT.D14, reqW = 110, text = CatHouseUtils.GetAvatarStyleTypeName(CatHouseUtils.AVATAR_STYLE_TYPE.BUBBLE)}),
        ui.button({n = RES_DICT.BTN_NORMAL}):updateLabel({fnt = FONT.D14, reqW = 110, text = CatHouseUtils.GetAvatarStyleTypeName(CatHouseUtils.AVATAR_STYLE_TYPE.IDENTITY)}),
    })
    ui.flowLayout(cc.rep(cc.sizep(headDetailView, ui.ct), 0, -10), headDetailBtnGroups, {type = ui.flowV, ap = ui.cb, gapH = 10})


    -- decorate view
    local decorLayer = DecorLayer:new()
    view:addChild(decorLayer)

    local eventViewData = CatHouseHomeScene.CreateEventView()
    view:addChild(eventViewData.view)

    eventViewData.view:setVisible(false)
    eventViewData.eventLayer:alignTo(eventBtn, ui.rt, {offsetX = -eventBtn:getContentSize().width * 0.8, offsetY = 20})


    ------------------------------------------------- [top]
    local topLayer = ui.layer()
    view:addChild(topLayer)

    -- money bar
    local moneyBar = require('common.CommonMoneyBar').new({})
    moneyBar:reloadMoneyBar()
    topLayer:add(moneyBar)

    -- back button
    local backBtn = ui.button({n = RES_DICT.COM_BACK_BTN})
    topLayer:addList(backBtn):alignTo(nil, ui.lt, {offsetX = display.SAFE_L + 35, offsetY = -15})

    -- title button
    local titleBtn = ui.button({n = RES_DICT.COM_TITLE_BAR}):updateLabel({fnt = FONT.D1, text = __('御主之屋'), offset = cc.p(0,-10)})
    topLayer:addList(titleBtn):alignTo(backBtn, ui.rc, {offsetX = 2, offsetY = 10})

    titleBtn:addList(ui.image({img = RES_DICT.COM_TIPS_ICON})):alignTo(nil, ui.rc, {offsetX = -15, offsetY = -10})
    titleBtn:setVisible(false)

    -- friend layer
    local friendLayer = FriendLayer:new()
    view:addChild(friendLayer)


    return {
        view                = view,
        --                  = top
        topLayer            = topLayer,
        topLayerHidePos     = cc.p(topLayer:getPositionX(), 100),
        topLayerShowPos     = cc.p(topLayer:getPosition()),
        titleBtn            = titleBtn,
        titleBtnHidePos     = cc.p(titleBtn:getPositionX(), titleBtn:getPositionY() + 190),
        titleBtnShowPos     = cc.p(titleBtn:getPosition()),
        backBtn             = backBtn,
        --                  = bottom
        chatPanel           = chatPanel,
        showBtn             = funcBtnGroup[BTN_TAG.DISPLAY],
        infoBtn             = funcBtnGroup[BTN_TAG.INFO],
        shopBtn             = funcBtnGroup[BTN_TAG.SHOP],
        collBtn             = funcBtnGroup[BTN_TAG.COLLECT],
        catBtn              = funcBtnGroup[BTN_TAG.CAT],
        decorBtn            = funcBtnGroup[BTN_TAG.DECORATE],
        decorLayer          = decorLayer,
        homeLayer           = homeLayer,
        funcBtnGroup        = funcBtnGroup,
        funcBtnLayer        = funcBtnLayer,
        --                  = left
        eventBtn            = eventBtn,
        skinHeadLayer       = skinHeadLayer,
        headImgLayer        = headImgLayer,
        skinHeadDetailNode  = headDetailNode,
        skinHeadDetailBlock = headDetailGroup[1],
        skinHeadBtn         = headDetailBtnGroups[1],
        skinBubbleBtn       = headDetailBtnGroups[2],
        skinIdentityBtn     = headDetailBtnGroups[3],
        friendHouseLvl      = homeInfoGroup[1],
        firendHouseTitle    = homeInfoGroup[3],
        --                  = right
        rankBtn             = rankBtn,
        friendBtn           = friendBtn,
        uiButton            = uiButton,
        --                  = center
        centerLayer         = centerLayer,
        avatarLayer         = avatarLayer,
        friendLayer         = friendLayer,
        eventViewData       = eventViewData,
        bottomLayer         = bottomLayer,
        leftLayer           = leftLayer,
        rightLayer          = rightLayer,
    }
end


function CatHouseHomeScene.CreateDoorView()
    local view  = ui.layer()

    local doorGroup = view:addList({
        ui.image({img = RES_DICT.SWITCH_DOOR, p = display.center, ap = ui.rc}),
        ui.image({img = RES_DICT.SWITCH_DOOR, p = display.center, ap = ui.lc}),
    })
    ui.flowLayout(cc.sizep(view, ui.cc), doorGroup, {type = ui.flowH, ap = ui.cc})

    return {
        view  = view,
        doorL = doorGroup[1],
        doorR = doorGroup[2],
    }
end


function CatHouseHomeScene.CreateEventView()
    local view       = ui.layer()
    local cellSize   = cc.size(230, 50)
    local tableViewH = 4.5 * cellSize.height
    local bgSize     = cc.size(cellSize.width + 10, tableViewH + 100 + 10)
  
    --[ blockLayer | eventLayer ]
    local frameGroup = view:addList({
        ui.layer({color = cc.r4b(0), enable = true}),
        ui.layer({size = bgSize}),
    })

    -- event layer
    local eventLayer = frameGroup[2]
    local bgGroup = eventLayer:addList({
        ui.layer({size = bgSize, color = cc.r4b(0), enable = true}),
        ui.layer({size = bgSize, scale9 = true, bg = RES_DICT.EVENT_BG}),
    })

    local eventInfoLayer = bgGroup[2]
    local titleGroup = eventInfoLayer:addList({
        ui.label({fnt = FONT.D6, text = __("待处理事件"), reqW = 200}),
        ui.image({img = RES_DICT.TITLE_LINE}),
        ui.layer({size = cc.size(cellSize.width, 40)}),
        ui.layer({bg = RES_DICT.EVENT_INFO_BG, mt = -7, size = cc.size(225, tableViewH), scale9 = true}),
    })
    ui.flowLayout(cc.rep(cc.sizep(eventInfoLayer, ui.ct), 0, -20), titleGroup, {type = ui.flowV, ap = ui.cb, gapH = 3})

    -- event btnList
    local eventTabLayer = titleGroup[3]
    local eventTabGroup = {}
    for _, eventConf in pairs(CONF.CAT_HOUSE.EVENT_TYPE:GetAll()) do
        local tButton = ui.tButton({n = RES_DICT.EVENT_BTN_N, s = RES_DICT.EVENT_BTN_S})
        tButton:setTag(eventConf.id)

        local descr = ui.label({fnt = FONT.D14, fontSize = 18, outline = "#311717", text = tostring(eventConf.name), reqW = tButton:getContentSize().width - 8})
        tButton:addList(descr):alignTo(nil, ui.cc)

        eventTabGroup[checkint(eventConf.id)] = tButton
    end
    eventTabLayer:addList(eventTabGroup)
    ui.flowLayout(cc.sizep(eventTabLayer, ui.cc), eventTabGroup, {type = ui.flowH, ap = ui.cc})

    -- event tableView
    local tableViewLayer = titleGroup[4]
    local tableView = ui.tableView({size = cc.size(cellSize.width, tableViewH), dir = display.SDIR_V, csizeH = cellSize.height, ap = ui.lb, p = cc.p(5, 5)})
    tableView:setCellCreateHandler(CatHouseHomeScene.CreateEventCell)
    tableViewLayer:addList(tableView):alignTo(nil, ui.cc)

    local eventBgLayer    = titleGroup[4]
    local emptyEventLayer = ui.layer({size = eventBgLayer:getContentSize()})
    emptyEventLayer:addList(ui.label({fnt = FONT.D4, text = __("暂无事件"), reqW = 200})):alignTo(nil, ui.cc)
    eventBgLayer:addList(emptyEventLayer):alignTo(nil, ui.cc)

    local arrowBg = ui.image({img = RES_DICT.EVENT_BG_ARROW, scaleY = -1, p = cc.p(30, 2)})
    eventInfoLayer:add(arrowBg)
    
    return {
        view               = view,
        eventBlock         = frameGroup[1],
        tableView          = tableView,
        titleGroup         = titleGroup,
        eventTabGroup      = eventTabGroup,
        eventLayer         = eventLayer,
        eventBlockLayer    = frameGroup[2],
        emptyEventLayer    = emptyEventLayer,
    }
end


function CatHouseHomeScene.CreateEventCell(parent)
    local size = parent:getContentSize()
    local view = ui.layer({size = size, color = cc.r4b(0), enable = true})
    parent:addList(view):alignTo(nil, ui.cc)

    local cellGroup = view:addList{
        ui.label({fnt = FONT.D6, color = "#754a34", text = "--"}),
        ui.image({img = RES_DICT.LINE_BG}),
    }
    ui.flowLayout(cc.rep(cc.sizep(size, ui.cc), 0, -10), cellGroup, {type = ui.flowV, ap = ui.cc, gapH = 10})

    return {
        view  = view,
        title = cellGroup[1],
    }
end


return CatHouseHomeScene

--[[
 * author : kaishiqi
 * descpt : 工会 - 大厅场景
]]
local RemindIcon      = require('common.RemindIcon')
local CommonChatPanel = require('common.CommonChatPanel')
local UnionLobbyScene = class('UnionLobbyScene', require('Frame.GameScene'))

local RES_DICT = {
    TITLE_BAR       = 'ui/common/common_title.png',
    BTN_TIPS        = 'ui/common/common_btn_tips.png',
    BTN_BACK        = 'ui/common/common_btn_back.png',
    BTN_CONFIM      = 'ui/common/common_btn_orange.png',
    FUNC_NAME_BAR   = 'ui/union/lobby/guild_icon_name_bg.png',
    CHANNEL_BTN     = 'ui/union/lobby/guild_home_btn_channel.png',
    IMPEACHMENT_BTN = 'ui/union/lobby/guild_btn_impeachment.png',
    CHANNEL_FRAME   = 'ui/union/lobby/guild_bg_channel.png',
    CHANNEL_CELL_D  = 'ui/union/lobby/guild_btn_channel_default.png',
    CHANNEL_CELL_S  = 'ui/union/lobby/guild_btn_channel_select.png',
    AVATAR_NAME_BAR = 'ui/union/lobby/guild_name_bg.png',
    SWITCH_DOOR     = 'avatar/ui/restaurant_anime_door.png',
    AVATAR_SHADOW   = 'ui/battle/battle_role_shadow.png',
    CHANNEL_FG_DOWN = 'ui/union/lobby/guild_img_down.png',
    CHANNEL_FG_UP   = 'ui/union/lobby/guild_img_up.png',
    SKIN_HEAD_FRAME = 'ui/home/handbook/pokedex_card_bg_skin_head.png',
    SKIN_HEAD_MASK  = 'ui/home/handbook/pokedex_card_bg_skin_head_unlock.png'
}

local FUNC_TAG = {
    INFO     = RemindTag.UNION_INFO,
    TASK     = RemindTag.UNION_TASK,
    MONSTER  = RemindTag.UNION_MONSTER,
    BUILD    = RemindTag.UNION_BUILD,
    ACTIVITY = RemindTag.UNION_ACTIVITY,
    BATTLE   = RemindTag.UNION_BATTLE,
    SHOP     = RemindTag.UNION_SHOP,
}

-- local AVATAR_POSITION = {
--     {9, 5, 4, 6, 10},
--     {7, 2, 1, 3, 8}
-- }
local AVATAR_POSITION = {
    {x = 0.55, y = 0.15},  -- 1
    {x = 0.35, y = 0.24},  -- 2
    {x = 0.74, y = 0.33},  -- 3
    {x = 0.44, y = 0.82},  -- 4
    {x = 0.62, y = 0.95},  -- 5
    {x = 0.19, y = 0.42},  -- 6
    {x = 0.08, y = 0.88},  -- 7
    {x = 0.86, y = 0.76},  -- 8
    {x = 0.06, y = 0.06},  -- 9
    {x = 0.93, y = 0.08},  -- 10
}

local CreateView            = nil
local CreateUIView          = nil
local CreateFuncBtn         = nil
local CreateChannelView     = nil
local CreateChannelCell     = nil
local CreateAvatarCell      = nil
local CreateDoorView        = nil
local CreateImpeachmentView = nil


function UnionLobbyScene:ctor(...)
    self.super.ctor(self, 'Game.views.UnionLobbyScene')

    xTry(function ( )
        -- create view
        self.viewData_ = CreateView()
        self:AddGameLayer(self.viewData_.view)

        -- create uiView
        self.uiViewData_ = CreateUIView()
        self:AddUILayer(self.uiViewData_.view)

        -- create channelView
        self.channelViewData_ = CreateChannelView()
        self:AddUILayer(self.channelViewData_.view)

        -- create switchDoor
        self.doorViewData_ = CreateDoorView()
        self:AddDialog(self.doorViewData_.view)

        -- init views
        self:getUIViewData().titleBtn:setPositionY(display.height + 190)
        self:getUIViewData().titleBtn:runAction(cc.EaseBounceOut:create(
            cc.MoveTo:create(1, cc.p(self:getUIViewData().titleBtnX, display.height + 2))
        ))

        self:openSwitchDoor(nil, true)
        self:hideChannelPopup(nil, true)
	end, __G__TRACKBACK__)
end


CreateView = function()
    local view = display.newLayer()
    local size = view:getContentSize()

    local bgImgLayer = display.newLayer(size.width/2, size.height/2, {ap = display.LEFT_BOTTOM})
    view:addChild(bgImgLayer)

    local avatarLayerSize   = cc.size(960, 320)
    local avatarLayerOrigin = cc.p(size.width/2 - avatarLayerSize.width/2, size.height/2 + 80 - avatarLayerSize.height)
    local avatarRangeLayer  = display.newLayer(avatarLayerOrigin.x, avatarLayerOrigin.y, {size = avatarLayerSize, color = cc.r4b(0), enable = true})
    view:addChild(avatarRangeLayer)

    local avatarCellsLayer = display.newLayer()
    view:addChild(avatarCellsLayer)

    local avatarPointMap  = {}
    -- local avatarGapW = math.floor(avatarLayerSize.width / #AVATAR_POSITION[1])
    -- local avatarGapH = 220--math.floor(avatarLayerSize.height / #AVATAR_POSITION)
    -- local avatarOffY = avatarLayerOrigin.y + #AVATAR_POSITION * avatarGapH + 30
    -- for r, aRowPositions in ipairs(AVATAR_POSITION) do
    --     for c, positionId in ipairs(aRowPositions) do
    --         local positionX = avatarLayerOrigin.x + avatarGapW * (c - 0.5)
    --         local positionY = avatarOffY - avatarGapH * r
    --         avatarPointMap[tostring(positionId)] = cc.p(positionX, positionY)
    --     end
    -- end
    for positionId, position in ipairs(AVATAR_POSITION) do
        local positionX = avatarLayerOrigin.x + checkint(position.x * avatarLayerSize.width)
        local positionY = avatarLayerOrigin.y + checkint(position.y * avatarLayerSize.height)
        avatarPointMap[tostring(positionId)] = cc.p(positionX, positionY)
    end

    return {
        view              = view,
        bgImgLayer        = bgImgLayer,
        avatarLayerSize   = avatarLayerSize,
        avatarLayerOrigin = avatarLayerOrigin,
        avatarRangeLayer  = avatarRangeLayer,
        avatarCellsLayer  = avatarCellsLayer,
        avatarPointMap    = avatarPointMap,
    }
end


CreateAvatarCell = function()
    local size = cc.size(120, 180)
    local view = display.newLayer(0, 0, {size = size, ap = display.CENTER_BOTTOM})

    view:addChild(display.newImageView(_res(RES_DICT.AVATAR_SHADOW), size.width/2, 0, {scale = 0.35}))

    local avatarLayer = display.newLayer(size.width/2, 0)
    view:addChild(avatarLayer)

    local nameBar = display.newButton(size.width/2, 0, {n = _res(RES_DICT.AVATAR_NAME_BAR), ap = display.CENTER_TOP, scale9 = true, enable = true})
    display.commonLabelParams(nameBar, fontWithColor(14, {fontSize = 22, ttf = false}))
    view:addChild(nameBar)

    local clickArea = display.newLayer(0, 0, {size = size, color = cc.r4b(0), enable = true})
    view:addChild(clickArea)

    return {
        view        = view,
        nameBar     = nameBar,
        clickArea   = clickArea,
        avatarLayer = avatarLayer,
        targetPoint = nil,
    }
end


CreateUIView = function()
    local view = display.newLayer()
    local size = view:getContentSize()

    -------------------------------------------------
    -- top layer
    local topLayer = display.newLayer()
    view:addChild(topLayer)

    -- back button
    local backBtn = display.newButton(display.SAFE_L + 75, size.height - 52, {n = _res(RES_DICT.BTN_BACK)})
    topLayer:addChild(backBtn)

    -- title button
    local titleBtn = display.newButton(display.SAFE_L + 120, size.height, {n = _res(RES_DICT.TITLE_BAR), ap = display.LEFT_TOP, enable = true, scale9 = true, capInsets = cc.rect(100, 70, 80, 1)})
    display.commonLabelParams(titleBtn, fontWithColor(1, {text = '', offset = cc.p(0, -10), ttf = false}))
    topLayer:addChild(titleBtn)

    local titleSize = titleBtn:getContentSize()
    local tipsIcon  = display.newImageView(_res(RES_DICT.BTN_TIPS), titleSize.width - 50, titleSize.height/2 - 10)
    titleBtn:addChild(tipsIcon)

    -- money bar
    local moneyBar = require('common.CommonMoneyBar').new({})
    topLayer:add(moneyBar)

    -- skin head layer
    local skinHeadSize  = cc.size(106, 106)
    local skinHeadLayer = display.newLayer(display.SAFE_R - 22, size.height - 180, {size = skinHeadSize, ap = display.RIGHT_TOP, color = cc.r4b(0), enable = true})
    topLayer:addChild(skinHeadLayer)

    -- skin head layer clip node
    local skinHeadCenterPos = cc.p(skinHeadSize.width/2, skinHeadSize.height/2)
    local skinHeadClipNode  = cc.ClippingNode:create()
    skinHeadClipNode:setContentSize(skinHeadSize)
    skinHeadClipNode:setAnchorPoint(display.CENTER)
    skinHeadClipNode:setPosition(skinHeadCenterPos)
    skinHeadClipNode:setAlphaThreshold(0.1)
    skinHeadLayer:addChild(skinHeadClipNode)

    -- skin head layer mask image
    local skinHeadNodeMask = display.newImageView(_res(RES_DICT.SKIN_HEAD_MASK), skinHeadCenterPos.x, skinHeadCenterPos.y, {scale = 0.86})
    skinHeadClipNode:setStencil(skinHeadNodeMask)

    -- skin head layer image layer
    local headImgLayer = display.newLayer(skinHeadCenterPos.x, skinHeadCenterPos.y)
    skinHeadClipNode:addChild(headImgLayer)

    -- skin head layer frame
    skinHeadLayer:addChild(display.newImageView(_res(RES_DICT.SKIN_HEAD_FRAME), skinHeadCenterPos.x, skinHeadCenterPos.y))

    -- skin head layer nameBar
    local skinHeadNameBar = display.newButton(skinHeadSize.width/2, 0, {n = _res(RES_DICT.FUNC_NAME_BAR), enable = false , scale9 = true   })
    display.commonLabelParams(skinHeadNameBar, fontWithColor(14, {fontSize = 22, text = __('更换形象'),reqW = 130  }))
    skinHeadLayer:addChild(skinHeadNameBar)
    local skinHeadNameBarLabelSize = display.getLabelContentSize(skinHeadNameBar:getLabel())
    local skinHeadNameBarSize = skinHeadNameBar:getContentSize()
    local reqW =skinHeadNameBarLabelSize.width + 10
    if reqW > skinHeadNameBarSize.width  then
        local width = reqW> 130 and 130 or reqW
        skinHeadNameBar:setContentSize(cc.size(width , skinHeadNameBarSize.height))
    end



    -- channel button
    local channelBtn = display.newButton(display.SAFE_R - 12, size.height - 65, {n = _res(RES_DICT.CHANNEL_BTN), ap = display.RIGHT_TOP})
    topLayer:addChild(channelBtn)

    local channelSize = channelBtn:getContentSize()
    local channelTips = display.newLabel(channelSize.width/2, 14, fontWithColor(18, {color = '#ffecc3', text = __('更改区域 ▾') , reqW = 170}))
    channelBtn:addChild(channelTips)

    local channelRLabel = display.newRichLabel(channelSize.width/2, channelSize.height - 24)
    channelBtn:addChild(channelRLabel)

    -- impeachment layer
    local impeachmentViewSize = cc.size(338, 59)
    local impeachmentView = display.newLayer(channelBtn:getPositionX() - channelBtn:getContentSize().width - 30, size.height - 65, {ap = display.RIGHT_TOP, size = impeachmentViewSize})
    topLayer:addChild(impeachmentView)
    impeachmentView:setVisible(false)

    local impeachmentBtnImg = display.newNSprite(_res(RES_DICT.IMPEACHMENT_BTN), impeachmentViewSize.width * 0.5, impeachmentViewSize.height * 0.5, {ap = display.CENTER})
    impeachmentView:addChild(impeachmentBtnImg)

    local impeachmentTouchViewSize = cc.size(impeachmentViewSize.width - 52, impeachmentViewSize.height)
    local impeachmentTouchView = display.newLayer(0, 0, {size = impeachmentTouchViewSize, enable = true, color = cc.c4b(0, 0, 0, 0)})
    impeachmentView:addChild(impeachmentTouchView)

    local impeachmentLabel = display.newLabel(30, impeachmentTouchViewSize.height * 0.5, fontWithColor(7, {ap = display.LEFT_CENTER, text = __('弹劾会长'), fontSize = 24, color = '#950000',}))
    impeachmentTouchView:addChild(impeachmentLabel)

    local impeachmentTimesLabel = display.newLabel(impeachmentLabel:getPositionX() + display.getLabelContentSize(impeachmentLabel).width + 10, 
        impeachmentLabel:getPositionY(), fontWithColor(16, {ap = display.LEFT_CENTER}))
    impeachmentTouchView:addChild(impeachmentTimesLabel)

    local impeachmentTipsIcon  = display.newButton(impeachmentViewSize.width - 32, impeachmentViewSize.height * 0.5 + 3, {n = _res(RES_DICT.BTN_TIPS)})
    impeachmentView:addChild(impeachmentTipsIcon)

    -------------------------------------------------
    -- bottom layer
    local bottomLayer = display.newLayer()
    view:addChild(bottomLayer)

    -- chat panel
    local chatPanel = nil
    if ChatUtils.IsModuleAvailable() then
        chatPanel = CommonChatPanel.new({channelId = CHAT_CHANNELS.CHANNEL_UNION, isTopmost = false})
        bottomLayer:addChild(chatPanel)
    end

    -- func layer
    local funcLayer = display.newLayer()
    bottomLayer:addChild(funcLayer)

    -- func define
    local unionBottomTabNameTable = { "activityBtn" ,"monsterBtn" ,"shopBtn","taskBtn" , "buildBtn" ,  "infoBtn" }
    local unionBottomTabTable = {}
    local funcDefine = {
        -- {col = 1, row = 1, name = __('工会战斗'), tag = FUNC_TAG.BATTLE,   icon = 'ui/union/lobby/guild_home_btn_battle.png'},
        {col = 1, row = 1, name = __('工会活动'), tag = FUNC_TAG.ACTIVITY, icon = 'ui/union/lobby/guild_home_btn_activity.png'},
        {col = 2, row = 1, name = __('远古堕神'), tag = FUNC_TAG.MONSTER,  icon = 'ui/union/lobby/guild_home_btn_monster.png'},
        {col = 3, row = 1, name = __('工会商店'), tag = FUNC_TAG.SHOP,     icon = 'ui/union/lobby/guild_home_btn_shop.png'},
        {col = 4, row = 1, name = __('工会任务'), tag = FUNC_TAG.TASK,     icon = 'ui/union/lobby/guild_home_btn_task.png'},
        {col = 5, row = 1, name = __('工会建造'), tag = FUNC_TAG.BUILD,    icon = 'ui/union/lobby/guild_home_btn_build.png'},
        {col = 6, row = 1, name = __('工会信息'), tag = FUNC_TAG.INFO,     icon = 'ui/union/lobby/guild_home_btn_information.png'},
    }

    --if isNewUSSdk() then
    --
    --    unionBottomTabNameTable = {"monsterBtn" ,"shopBtn","taskBtn" , "buildBtn" ,  "infoBtn" }
    --    funcDefine = {
    --        -- {col = 1, row = 1, name = __('工会战斗'), tag = FUNC_TAG.BATTLE,   icon = 'ui/union/lobby/guild_home_btn_battle.png'},
    --        {col = 1, row = 1, name = __('远古堕神'), tag = FUNC_TAG.MONSTER,  icon = 'ui/union/lobby/guild_home_btn_monster.png'},
    --        {col = 2, row = 1, name = __('工会商店'), tag = FUNC_TAG.SHOP,     icon = 'ui/union/lobby/guild_home_btn_shop.png'},
    --        {col = 3, row = 1, name = __('工会任务'), tag = FUNC_TAG.TASK,     icon = 'ui/union/lobby/guild_home_btn_task.png'},
    --        {col = 4, row = 1, name = __('工会建造'), tag = FUNC_TAG.BUILD,    icon = 'ui/union/lobby/guild_home_btn_build.png'},
    --        {col = 5, row = 1, name = __('工会信息'), tag = FUNC_TAG.INFO,     icon = 'ui/union/lobby/guild_home_btn_information.png'},
    --    }
    --end
    local funcBtnList = {}
    local funcBtnSize = cc.size(122, 100)
    for i, define in ipairs(funcDefine) do
        local funcBtn = CreateFuncBtn(funcBtnSize, define)
        funcBtn.view:setPositionX(display.SAFE_R - funcBtnSize.width/2 - 10 - funcBtnSize.width * (define.col-1))
        funcBtn.view:setPositionY(30 + funcBtnSize.height/2 + (funcBtnSize.height + 30) * (define.row-1))
        funcBtn.view:setTag(define.tag)
        funcLayer:addChild(funcBtn.view)
        funcBtnList[i] = funcBtn
        unionBottomTabTable[tostring(unionBottomTabNameTable[i])] = funcBtn.view
        RemindIcon.addRemindIcon({parent = funcBtn.view, tag = define.tag, po = cc.p(funcBtnSize.width - 25, funcBtnSize.height - 15)})
    end

    return {
        view                  = view,
        topLayer              = topLayer,
        backBtn               = backBtn,
        titleBtn              = titleBtn,
        titleBtnX             = titleBtn:getPositionX(),
        tipsIcon              = tipsIcon,
        chatPanel             = chatPanel,
        channelBtn            = channelBtn,
        channelRLabel         = channelRLabel,
        impeachmentView       = impeachmentView,
        impeachmentBtnImg     = impeachmentBtnImg,
        impeachmentTouchView  = impeachmentTouchView,
        impeachmentTimesLabel = impeachmentTimesLabel,
        impeachmentTipsIcon   = impeachmentTipsIcon,
        -- battleBtn     = funcBtnList[1].view,
        activityBtn           = funcBtnList[1].view,
        monsterBtn            = funcBtnList[2].view,
        shopBtn               = funcBtnList[3].view,
        taskBtn               = funcBtnList[4].view,
        buildBtn              = funcBtnList[5].view,
        infoBtn               = funcBtnList[6].view,
        skinHeadLayer         = skinHeadLayer,
        headImgLayer          = headImgLayer,
    }
end


CreateFuncBtn = function(size, define)
    local view = display.newLayer(0, 0, {size = size, color = cc.r4b(0), enable = true, ap = display.CENTER})

    local iconOffsetX = checkint(define.offsetY)
    view:addChild(display.newImageView(_res(define.icon), size.width/2, 10 + iconOffsetX, {ap = display.CENTER_BOTTOM}))

    local nameBar = display.newButton(size.width/2, 15, {n = _res(RES_DICT.FUNC_NAME_BAR), enable = false})
    display.commonLabelParams(nameBar, fontWithColor(14, {fontSize = 22, text = tostring(define.name) , reqW = 110}))
    view:addChild(nameBar)

    return {
        view = view
    }
end


CreateChannelView = function()
    local view = display.newLayer()
    local size = view:getContentSize()

    local blockBg = display.newLayer(0, 0, {color = cc.r4b(0), enable = true})
    view:addChild(blockBg)

    local channelPanel = display.newLayer(display.SAFE_R + 2, size.height - 115, {bg = _res(RES_DICT.CHANNEL_FRAME), ap = display.RIGHT_TOP})
    view:addChild(channelPanel)

    local channelPanelSize  = channelPanel:getContentSize()
    local channelTableSize  = cc.size(channelPanelSize.width - 60, channelPanelSize.height - 8)
    local channelTablePoint = cc.p(channelPanelSize.width/2, channelPanelSize.height - 4)
    local channelTableView  = CTableView:create(channelTableSize)
    channelTableView:setSizeOfCell(cc.size(channelTableSize.width, 80))
    channelTableView:setDirection(eScrollViewDirectionVertical)
    channelTableView:setAnchorPoint(display.CENTER_TOP)
    channelTableView:setPosition(channelTablePoint)
    -- channelTableView:setBackgroundColor(cc.r4b(100))
    channelPanel:addChild(channelTableView)

    channelPanel:addChild(display.newImageView(_res(RES_DICT.CHANNEL_FG_UP), channelTablePoint.x, channelTablePoint.y, {ap = display.CENTER_TOP}))
    channelPanel:addChild(display.newImageView(_res(RES_DICT.CHANNEL_FG_DOWN), channelTablePoint.x, channelTablePoint.y - channelTableSize.height, {ap = display.CENTER_BOTTOM}))

    return {
        view             = view,
        blockBg          = blockBg,
        channelPanel     = channelPanel,
        channelTableView = channelTableView,
    }
end


CreateChannelCell = function(size)
    local view = CTableViewCell:new()
    view:setContentSize(size)

    local normalBg = display.newImageView(_res(RES_DICT.CHANNEL_CELL_D), size.width/2, size.height/2)
    local selectBg = display.newImageView(_res(RES_DICT.CHANNEL_CELL_S), size.width/2, size.height/2)
    view:addChild(normalBg)
    view:addChild(selectBg)

    local nameLabel   = display.newLabel(size.width/2, size.height/2 + 14, {fontSize = 20, color = '#493328'})
    local numberLabel = display.newLabel(size.width/2, size.height/2 - 14, {fontSize = 22, color = '#b65600'})
    view:addChild(nameLabel)
    view:addChild(numberLabel)

    local clickArea = display.newLayer(0, 0, {size = size, color = cc.r4b(0), enable = true})
    view:addChild(clickArea)

    return {
        view        = view,
        normalBg    = normalBg,
        selectBg    = selectBg,
        nameLabel   = nameLabel,
        numberLabel = numberLabel,
        clickArea   = clickArea,
    }
end


CreateDoorView = function()
    local view  = display.newLayer(0, 0, {color = cc.c4b(0,0,0,0), enable = true})
    local doorL = display.newImageView(_res(RES_DICT.SWITCH_DOOR), display.cx, display.cy, {ap = display.RIGHT_CENTER})
    local doorR = display.newImageView(_res(RES_DICT.SWITCH_DOOR), display.cx, display.cy, {ap = display.LEFT_CENTER})
    view:addChild(doorL)
    view:addChild(doorR)

    return {
        view  = view,
        doorL = doorL,
        doorR = doorR,
    }
end

function UnionLobbyScene:getViewData()
    return self.viewData_
end
function UnionLobbyScene:getUIViewData()
    return self.uiViewData_
end
function UnionLobbyScene:getChannelViewData()
    return self.channelViewData_
end
function UnionLobbyScene:getDoorViewData()
    return self.doorViewData_
end


function UnionLobbyScene:setTitleText(text)
    display.commonLabelParams(self:getUIViewData().titleBtn, {text = tostring(text), paddingW = 72, safeW = 200, offset = cc.p(-35, -10)})
    self:getUIViewData().tipsIcon:setPositionX(self:getUIViewData().titleBtn:getContentSize().width - 50)
end


function UnionLobbyScene:setCurrentChannelTitle(channelName, channelPeople)
    display.reloadRichLabel(self:getUIViewData().channelRLabel, {c = {
        {fontSize = 22, color = '#FFFFFF', text = tostring(channelName)},
        {fontSize = 24, color = '#FFEEBC', text = string.fmt(' (%1/%2)', checkint(channelPeople), UNION_ROOM_MEMBERS)},
    }})
    CommonUtils.SetNodeScale(self:getUIViewData().channelRLabel ,{width = 210 })
end


function UnionLobbyScene:setBackgroundImg(imgName)
    local bgImgName  = checkstr(imgName)
    local bgImgLayer = self:getViewData().bgImgLayer
    bgImgLayer:removeAllChildren()

    if string.len(bgImgName) > 0 then
        local bgImgPath = string.fmt('ui/union/lobbyBg/%1', bgImgName)
        bgImgLayer:addChild(display.newImageView(_res(bgImgPath)))
    end
end


function UnionLobbyScene:createChannelCell()
    local channelCellSize = self:getChannelViewData().channelTableView:getSizeOfCell()
    return CreateChannelCell(channelCellSize)
end
function UnionLobbyScene:reloadChannelTable(channelData, isLockOffset)
    local oldOffsetPos = self:getChannelViewData().channelTableView:getContentOffset()
    self:getChannelViewData().channelTableView:setCountOfCell(table.nums(channelData or {}))
    self:getChannelViewData().channelTableView:reloadData()
    if isLockOffset then
        self:getChannelViewData().channelTableView:setContentOffset(oldOffsetPos)
    end
end


function UnionLobbyScene:showChannelPopup(endCB, isFast)
    local channelViewData = self:getChannelViewData()
    channelViewData.view:setVisible(true)

    local finishFunc = function()
        channelViewData.channelPanel:setScaleX(1)
        channelViewData.channelPanel:setScaleY(1)
        if endCB then endCB() end
    end

    self:stopAllActions()
    if isFast then
        finishFunc()
    else
        local actionTime = 0.2
        self:runAction(cc.Sequence:create(
            cc.TargetedAction:create(channelViewData.channelPanel, cc.EaseCubicActionOut:create(cc.ScaleTo:create(actionTime, 1, 1))),
            cc.CallFunc:create(finishFunc)
        ))
    end
end
function UnionLobbyScene:hideChannelPopup(endCB, isFast)
    local channelViewData = self:getChannelViewData()
    channelViewData.view:setVisible(true)

    local finishFunc = function()
        channelViewData.channelPanel:setScaleX(1)
        channelViewData.channelPanel:setScaleY(0)
        channelViewData.view:setVisible(false)
        if endCB then endCB() end
    end

    self:stopAllActions()
    if isFast then
        finishFunc()
    else
        local actionTime = 0.2
        self:runAction(cc.Sequence:create(
            cc.TargetedAction:create(channelViewData.channelPanel, cc.EaseCubicActionOut:create(cc.ScaleTo:create(actionTime, 1, 0))),
            cc.CallFunc:create(finishFunc)
        ))
    end
end


function UnionLobbyScene:cleanAvatarLayer()
    local avatarCellsLayer = self:getViewData().avatarCellsLayer
    avatarCellsLayer:removeAllChildren()
end
function UnionLobbyScene:removeAvatarCell(avatarCell)
    if avatarCell and avatarCell.view then
        avatarCell.view:runAction(cc.RemoveSelf:create())
    end
end
function UnionLobbyScene:appendAvatarCell(positionId, avatarName)
    local avatarCell  = CreateAvatarCell()
    local avatarLayer = self:getViewData().avatarCellsLayer
    local avatarPoint = self:getViewData().avatarPointMap[tostring(positionId)] or cc.p(0,0)
    display.commonLabelParams(avatarCell.nameBar, {text = tostring(avatarName), paddingW = 6})
    avatarCell.view:setPosition(avatarPoint)
    avatarLayer:addChild(avatarCell.view)
    return avatarCell
end
function UnionLobbyScene:reorderAvatarLayer()
    local avatarCells   = {}
    local avatarLayer   = self:getViewData().avatarCellsLayer
    local containerSize = self:getViewData().avatarLayerSize
    for i, cellNode in ipairs(avatarLayer:getChildren()) do
        local posX   = checkint(cellNode:getPositionX())
        local posY   = checkint(cellNode:getPositionY())
        local zorder = (containerSize.height - posY) * containerSize.width + posX
        cellNode:setLocalZOrder(zorder)
    end
end

function UnionLobbyScene:showImpeachmentSuccessPopup(unionData)
    local view = require("Game.views.union.UnionImpeachmentSuccessView").new(unionData)
    view:setPosition(display.center)
    app.uiMgr:GetCurrentScene():AddDialog(view)
    
    self:hideImpeachmentView()
end

function UnionLobbyScene:updateImpeachmentTimes(impeachmentTimes, impeachmentTotalTimes)
    local uiViewData           = self:getUIViewData()
    uiViewData.impeachmentView:setVisible(true)
    -- updata impeachment times label
    display.commonLabelParams(uiViewData.impeachmentTimesLabel, {text = string.format('%d/%d', impeachmentTimes, impeachmentTotalTimes)})
end

function UnionLobbyScene:hideImpeachmentView()
    if self:getUIViewData().impeachmentView then
        self:getUIViewData().impeachmentView:setVisible(false)
    end
end

function UnionLobbyScene:openSwitchDoor(endCb, isFirst)
    local doorViewData = self:getDoorViewData()
    doorViewData.view:setVisible(true)
    doorViewData.view:stopAllActions()
    doorViewData.doorL:setPositionX(display.cx)
    doorViewData.doorR:setPositionX(display.cx)

    local finishFunc = function()
        doorViewData.view:setVisible(false)
        doorViewData.doorL:setPositionX(0)
        doorViewData.doorR:setPositionX(display.width)
        if endCb then endCb() end
    end

    if isFirst then
        finishFunc()
    else
        local actionTime = 0.2
        doorViewData.view:runAction(cc.Sequence:create({
            cc.Spawn:create({
                cc.TargetedAction:create(doorViewData.doorL, cc.MoveTo:create(actionTime, cc.p(0, display.cy))),
                cc.TargetedAction:create(doorViewData.doorR, cc.MoveTo:create(actionTime, cc.p(display.width, display.cy)))
            }),
            cc.DelayTime:create(0.2),
            cc.CallFunc:create(function()
                finishFunc()
            end)
        }))
    end
end
function UnionLobbyScene:closeSwitchDoor(endCb, isFirst)
    local doorViewData = self:getDoorViewData()
    doorViewData.view:setVisible(true)
    doorViewData.view:stopAllActions()
    doorViewData.doorL:setPositionX(0)
    doorViewData.doorR:setPositionX(display.width)

    local finishFunc = function()
        doorViewData.doorL:setPositionX(display.cx)
        doorViewData.doorR:setPositionX(display.cx)
        if endCb then endCb() end
    end

    if isFirst then
        finishFunc()
    else
        local actionTime = 0.2
        PlayAudioClip(AUDIOS.UI.ui_restaurant_enter.id)
        doorViewData.view:runAction(cc.Sequence:create({
            cc.Spawn:create({
                cc.TargetedAction:create(doorViewData.doorL, cc.MoveTo:create(actionTime, display.center)),
                cc.TargetedAction:create(doorViewData.doorR, cc.MoveTo:create(actionTime, display.center))
            }),
            cc.DelayTime:create(0.2),
            cc.CallFunc:create(function()
                finishFunc()
            end)
        }))
    end
end


function UnionLobbyScene:setSkinHeadIcon(skinId)
    local headIconPath = CardUtils.GetCardHeadPathBySkinId(skinId)
    self:getUIViewData().headImgLayer:removeAllChildren()
    self:getUIViewData().headImgLayer:addChild(display.newImageView(headIconPath, 0, 0, {scale = 0.6}))
end


return UnionLobbyScene

--[[
 * author : kaishiqi
 * descpt : 爬塔 - 地图UI界面
]]
local TowerQuestMapUIView = class('TowerQuestMapUIView', function()
    return display.newLayer(0, 0, {name = 'Game.views.TowerQuestMapUIView'})
end)

local RES_DICT = {
    UP_FRAME          = 'ui/tower/map/tower_bg_up.png',
    BOTTOM_FRAME      = 'ui/tower/map/tower_bg_below_2.png',
    BTN_EXIT          = 'ui/common/tower_btn_quit.png',
    FIGHT_BTN_FRAME   = 'ui/tower/map/tower_bg_below_fight.png',
    BTN_FIGHT_D       = 'ui/tower/map/maps_fight_btn_cancel.png',
    BTN_FIGHT_N       = 'ui/tower/map/maps_fight_btn_fight.png',
    TIMES_BAR         = 'ui/tower/ready/tower_label_title.png',
    BOSS_LOOK_ICON    = 'ui/tower/map/tower_ico_boss_details.png',
    BOSS_NAME_BAR     = 'ui/tower/map/tower_label_point_editable.png',
}

local CreateView = nil


function TowerQuestMapUIView:ctor(args)
    xTry(function()
        self.viewData_ = CreateView()
        self:addChild(self.viewData_.view)

        self.viewData_.topLayer:setPosition(0, 130)
        self.viewData_.bottomLayer:setPosition(0, -180)
    end, __G__TRACKBACK__)
end


CreateView = function()
    local view = display.newLayer()
    local size = view:getContentSize()

    -------------------------------------------------
    -- top layer
    local topLayer = display.newLayer()
    view:addChild(topLayer)
    
    topLayer:addChild(display.newImageView(_res(RES_DICT.UP_FRAME), size.width/2, size.height, {ap = display.CENTER_TOP}))

    -- weather layer
    local weatherLayer = display.newLayer(size.width/2 + 340, size.height - 40, {ap = display.CENTER})
    topLayer:addChild(weatherLayer)

    -- boss frame
    local bossFrame  = display.newLayer(size.width/2 + 16, size.height - 52, {ap = display.CENTER})
    local bossCenter = utils.getLocalCenter(bossFrame)
    topLayer:addChild(bossFrame)

    -- boos layer
    local bossLayer = display.newLayer(bossCenter.x, bossCenter.y, {ap = display.CENTER})
    bossFrame:addChild(bossLayer)

    -- bossCheck bar
    local bossCheckBar = display.newButton(bossCenter.x, bossCenter.y - 40, {n = _res(RES_DICT.BOSS_NAME_BAR), scale9 = true, size = cc.size(280,34), enable = false})
    display.commonLabelParams(bossCheckBar, fontWithColor(14, {text = __('查看情报'), offset = cc.p(10,0)}))
    bossCheckBar:addChild(display.newImageView(_res(RES_DICT.BOSS_LOOK_ICON), 60, 17))
    bossFrame:addChild(bossCheckBar)
    bossCheckBar:setVisible(false)

    -- boss hotspot
    local bossHotspot = display.newLayer(bossCenter.x, bossCenter.y - 6, {size = cc.size(380,110), color = cc.r4b(0), enable = true, ap = display.CENTER})
    bossFrame:addChild(bossHotspot)


    -------------------------------------------------
    -- bottom layer
    local bottomLayer = display.newLayer()
    view:addChild(bottomLayer)
    bottomLayer:addChild(display.newImageView(_res(RES_DICT.BOTTOM_FRAME), size.width/2, 0, {ap = display.CENTER_BOTTOM, scale9 = true, size = cc.size(display.width, 60)}))
    bottomLayer:addChild(display.newImageView(_res(RES_DICT.FIGHT_BTN_FRAME), display.SAFE_R + 60, 0, {ap = display.RIGHT_BOTTOM}))

    -- exit button
    local exitBtn = display.newButton(display.SAFE_L -20, 40, {n = _res(RES_DICT.BTN_EXIT), ap = display.LEFT_CENTER ,scale9 = true })
    display.commonLabelParams(exitBtn, fontWithColor(4, {text = __('放弃挑战'), color = '#FFe4cb', offset = cc.p(5,0),paddingW = 20 }))
    bottomLayer:addChild(exitBtn)

    -- floor label
    local floorLabel = display.newLabel(display.SAFE_R - 330, 20, fontWithColor(16, {fontSize = 26}))
    bottomLayer:addChild(floorLabel)

    -- recommand label
    local recommendLabel = display.newLabel(display.SAFE_R - 230, 60, {ap = display.RIGHT_CENTER})
    display.commonLabelParams(recommendLabel, fontWithColor(4, {color = '#fec7a8'}))
    bottomLayer:addChild(recommendLabel)
    recommendLabel:setVisible(false)  -- FIXME 虽说临时，大概会永久性关闭

    -- fight button
    local fightBtn = require('common.CommonBattleButton').new()
    fightBtn:setPosition(display.SAFE_R - 98, 80)
    bottomLayer:addChild(fightBtn)
    fightBtn:setEnabled(false)

    return {
        view           = view,
        topLayer       = topLayer,
        weatherLayer   = weatherLayer,
        bossLayer      = bossLayer,
        bossHotspot    = bossHotspot,
        -- bossLeftBtn    = bossLeftBtn,
        -- bossRightBtn   = bossRightBtn,
        bottomLayer    = bottomLayer,
        exitBtn        = exitBtn,
        floorLabel     = floorLabel,
        recommendLabel = recommendLabel,
        fightBtn       = fightBtn,
    }
end


function TowerQuestMapUIView:getViewData()
    return self.viewData_
end


function TowerQuestMapUIView:createWeatherIcon(weatherId)
    local weatherFrame = display.newImageView(_res('ui/battle/battle_bg_weather.png'), 0, 0, {enable = true})
    local weatherIcon  = display.newImageView(_res(string.fmt('ui/common/fight_ico_weather_%1.png', weatherId)), 0, 0, {scale = 0.38})
    weatherIcon:setPosition(utils.getLocalCenter(weatherFrame))
    weatherFrame:addChild(weatherIcon)
    return weatherFrame
end


function TowerQuestMapUIView:createBossIcon(bossId)
    local cardManager = AppFacade.GetInstance():GetManager('CardManager')
    local monsterConf = CommonUtils.GetConfigAllMess('monster','monster')
    local iconLayer   = display.newLayer(0, 0, {bg = _res('ui/bossdetail/bosspokedex_boss_head_3.png'), ap = display.CENTER})
    local iconCenter  = utils.getLocalCenter(iconLayer)
    local iconSize    = iconLayer:getContentSize()

    local bossHeadId    = checkint(checktable(monsterConf[tostring(bossId)]).drawId)
    local bossHeadImage = display.newImageView(AssetsUtils.GetCardHeadPath(bossHeadId), iconCenter.x, iconCenter.y, {scale = 0.65})
    local stencilImage  = display.newImageView(_res('ui/bossdetail/bosspokedex_boss_head_3.png'), 0, 0, {ap = display.LEFT_BOTTOM})
    local clippingNode  = cc.ClippingNode:create()
    clippingNode:setAnchorPoint(display.CENTER)
    clippingNode:setContentSize(iconSize)
    clippingNode:setPosition(iconCenter)
    clippingNode:addChild(bossHeadImage)
    clippingNode:setStencil(stencilImage)
    clippingNode:setAlphaThreshold(0)
    iconLayer:addChild(clippingNode)

    iconLayer:addChild(display.newImageView(_res('ui/bossdetail/bosspokedex_boss_head_2.png'), iconCenter.x, iconCenter.y))
    iconLayer:setScale(0.8)
    return iconLayer
end


function TowerQuestMapUIView:showUI(endCb)
    local actionTime = 0.25
    self:runAction(cc.Sequence:create({
        cc.Spawn:create({
            cc.TargetedAction:create(self.viewData_.topLayer, cc.MoveTo:create(actionTime, PointZero)),
            cc.TargetedAction:create(self.viewData_.bottomLayer, cc.MoveTo:create(actionTime, PointZero))
        }),
        cc.CallFunc:create(function()
            if endCb then endCb() end
        end)
    }))
end


return TowerQuestMapUIView

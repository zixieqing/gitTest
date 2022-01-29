--[[
 * author : kaishiqi
 * descpt : 2020周年庆 - 探索入口 场景
]]
local Anniversary20ExploreMainScene = class('Anniversary20ExploreMainScene', require('Frame.GameScene'))

local RES_DICT = {
    --              = top
    BACK_BTN        = _res('ui/common/common_btn_back.png'),
    COM_TITLE_BAR   = _res('ui/common/common_title.png'),
    COM_TIPS_ICON   = _res('ui/common/common_btn_tips.png'),
    --              = center
    BG_IMAGE        = _res('ui/anniversary20/explore/wonderland_tower_bg.jpg'),
    FG_IMAGE        = _res('ui/anniversary20/explore/wonderland_tower_bg_plant.png'),
    TITLE_BG        = _res('ui/anniversary20/explore/wonderland_tower_bg_area.png'),
    ENTRANCE_TXT_BG = _res('ui/anniversary20/explore/wonderland_explore_go_label_title.png'),
    --              = spine
    STREET_SPINE    = _spn('ui/anniversary20/explore/effects/wonderland_tower_btn_land_street'),
    TEA_SPINE       = _spn('ui/anniversary20/explore/effects/wonderland_tower_btn_land_tea'),
    CASTLE_SPINE    = _spn('ui/anniversary20/explore/effects/wonderland_tower_btn_land_castle'),
    SWEEP_SPINE     = _spn('ui/anniversary20/explore/effects/wonderland_tower_kill'),
}

Anniversary20ExploreMainScene.ENTRANCE_STATUE = {
    UNLOCKING = 1,  -- 解锁重（动画）
    UNLOCKED  = 2,  -- 已解锁
    LOCKED    = 3,  -- 未解锁
    PASSED    = 4,  -- 已通关
}

function Anniversary20ExploreMainScene:ctor(args)
    self.super.ctor(self, 'Game.views.anniversary20.Anniversary20ExploreMainScene')

    -- create view
    self.viewData_ = Anniversary20ExploreMainScene.CreateView()
    self:addChild(self.viewData_.view)
end


function Anniversary20ExploreMainScene:getViewData()
    return self.viewData_
end


function Anniversary20ExploreMainScene:showUI(endCB)
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


-------------------------------------------------------------------------------
-- view define
-------------------------------------------------------------------------------

function Anniversary20ExploreMainScene.CreateView()
    local view = ui.layer()
    local size = view:getContentSize()
    local cpos = cc.sizep(size, ui.cc)

    -- bgImg / block layer
    local backGroundGroup = view:addList({
        ui.image({img = RES_DICT.BG_IMAGE, p = cpos}),
        ui.layer({color = cc.r4b(0), enable = true}),
        ui.image({img = RES_DICT.FG_IMAGE, p = cpos}),
    })


    ------------------------------------------------- [top]
    local topLayer = ui.layer()
    view:add(topLayer)

    -- back button
    local backBtn = ui.button({n = RES_DICT.BACK_BTN})
    topLayer:addList(backBtn):alignTo(nil, ui.lt, {offsetX = display.SAFE_L + 30, offsetY = -15})

    -- title button
    local titleBtn = ui.button({n = RES_DICT.COM_TITLE_BAR}):updateLabel({fnt = FONT.D1, text = __('梦魇侵蚀'), offset = cc.p(0,-10)})
    topLayer:addList(titleBtn):alignTo(backBtn, ui.rc, {offsetX = 2, offsetY = 10})

    titleBtn:addList(ui.image({img = RES_DICT.COM_TIPS_ICON})):alignTo(nil, ui.rc, {offsetX = -15, offsetY = -10})

    -- money bar
    local moneyBar = require('common.CommonMoneyBar').new({})
    moneyBar:reloadMoneyBar({ app.anniv2020Mgr:getHpGoodsId() })
    topLayer:add(moneyBar)


    ------------------------------------------------- [center]
    local centerLayer = ui.layer()
    view:add(centerLayer)

    -- entrance buttons
    local entranceBtns  = {}
    local resSpinePaths = {RES_DICT.TEA_SPINE, RES_DICT.CASTLE_SPINE, RES_DICT.STREET_SPINE}
    for index, moduleId in ipairs(CONF.ANNIV2020.EXPLORE_ENTRANCE:GetIdListUp()) do
        local entranceConf = CONF.ANNIV2020.EXPLORE_ENTRANCE:GetValue(moduleId)
        local entranceBtn  = Anniversary20ExploreMainScene.CreateEntranceNode(entranceConf, resSpinePaths[index], index == 2 and 0 or -260)
        entranceBtn:setTag(checkint(entranceConf.id))
        entranceBtns[index] = entranceBtn
    end
    centerLayer:addList(entranceBtns)
    ui.flowLayout(cc.rep(cc.sizep(centerLayer, ui.cc), 0, -20), entranceBtns, {type = ui.flowH, ap = ui.cb, gapW = 100})

    -- sweepButtons
    local sweepBtn = ui.colorBtn({size = cc.size(160, 130), color = cc.r4b(0)}):updateLabel({fnt = FONT.D20, text = __("扫荡"), fontSize = 24, outline = "#5a3d19", ap = ui.ct})
    view:addList(sweepBtn):alignTo(nil, ui.rc, {offsetX = -display.SAFE_L, offsetY = 150})

    local sweepSpine = ui.spine({path = RES_DICT.SWEEP_SPINE, init = "play1"})
    sweepBtn:addList(sweepSpine, -1):alignTo(nil, ui.cc, {offsetY = -22, offsetX = 5})

    return {
        view            = view,
        --              = top
        topLayer        = topLayer,
        topLayerHidePos = cc.p(topLayer:getPositionX(), 100),
        topLayerShowPos = cc.p(topLayer:getPosition()),
        titleBtn        = titleBtn,
        titleBtnHidePos = cc.p(titleBtn:getPositionX(), titleBtn:getPositionY() + 190),
        titleBtnShowPos = cc.p(titleBtn:getPosition()),
        backBtn         = backBtn,
        --              = center
        entranceBtns    = entranceBtns,
        sweepBtn        = sweepBtn,
    }
end


function Anniversary20ExploreMainScene.CreateEntranceNode(entranceConf, spinePath, mb)
    local entranceBtn = ui.layer({color = cc.r4b(0), size = cc.size(300, 300), mb = mb, enable = true})

    -- [ spineNode | titleFrame | titleLabel | goodsFrame | goodsNumRLabel ]
    local entranceGroup = entranceBtn:addList{
        ui.spine({path = spinePath, init = "idle"}),
        ui.title({img = RES_DICT.TITLE_BG, mt = 90}):updateLabel({text = tostring(entranceConf.name), mt = 90, fnt = FONT.D20, fontSize = 28, outline = "#7e6648", paddingW = 50}),
        ui.image({img = RES_DICT.ENTRANCE_TXT_BG, mt = 140}),
        ui.rLabel({r = true, mt = 140, c = {
            {img = GoodsUtils.GetIconPathById(app.anniv2020Mgr:getHpGoodsId()), scale = 0.2},
            {text = " x" .. entranceConf.consumeNum, fontSize = 24, color = "#cbbfaa"}
        }}),
    }
    ui.flowLayout(cc.sizep(entranceBtn, ui.cc), entranceGroup, {type = ui.flowC, ap = ui.cc})
    entranceBtn.entranceSpine = entranceGroup[1]

    return entranceBtn
end


function Anniversary20ExploreMainScene:updateEntranceStatus(entranceBtnNode, statusCode, args)
    local entranceSpine = entranceBtnNode.entranceSpine

    if statusCode == Anniversary20ExploreMainScene.ENTRANCE_STATUE.UNLOCKING then
        entranceSpine:setAnimation(0, 'play1', false)
        entranceSpine:registerSpineEventHandler(function(event)
            if event.animation == 'play1' then
                entranceSpine:unregisterSpineEventHandler(sp.EventType.ANIMATION_COMPLETE)
                entranceSpine:setAnimation(0, 'play2', true)
                if args.unlockedCB then
                    args.unlockedCB()
                end
            end
        end, sp.EventType.ANIMATION_COMPLETE)

    elseif statusCode == Anniversary20ExploreMainScene.ENTRANCE_STATUE.UNLOCKED then
        entranceSpine:setAnimation(0, 'play2', true)

    elseif statusCode == Anniversary20ExploreMainScene.ENTRANCE_STATUE.LOCKED then
        entranceSpine:setAnimation(0, 'idle', true)

    elseif statusCode == Anniversary20ExploreMainScene.ENTRANCE_STATUE.PASSED then
        entranceSpine:setAnimation(0, 'stop', true)
    end
end

----------------------public methods-------------------

return Anniversary20ExploreMainScene

--[[
 * author : panmeng
 * descpt : 猫屋
]]

local CatModuleMainView = class('CatModuleMainView', function()
    return ui.layer({name = 'Game.views.catModule.CatModuleMainView', enableEvent = true})
end)

local RES_DICT = {
    --            = top
    COM_BACK_BTN  = _res('ui/common/common_btn_back.png'),
    COM_TITLE_BAR = _res('ui/common/common_title.png'),
    COM_TIPS_ICON = _res('ui/common/common_btn_tips.png'),
    --            = center
    BG_IMAGE      = _res('ui/catModule/main/grow_main_bg.jpg'),
    ENTRANCE_BG   = _res('ui/castle/main/castle_main_btn_enter.png'),
    SHOP_IMAGE    = _spn('ui/catModule/main/anim/cat_grow_main_toy'),
    CATTERY_IMG   = _spn('ui/catModule/main/anim/cat_grow_main_house'),
    FAMILY_IMG    = _spn('ui/catModule/main/anim/cat_grow_main_book'),
    CAT_LIST_IMG  = _spn('ui/catModule/main/anim/cat_grow_main_toy'),
}

local ENTRANCE_TAG  = {
    SHOP     = 4,
    CATTERY  = 1,
    FAMILY   = 2,
    CAT_LIST = 3,
}

local ENTRANCE_INFO = {
    [ENTRANCE_TAG.CATTERY]  = {size = cc.size(300, 250), scale = 0.75, p = cc.p(-230, 90),   initPos = cc.p(0, 0), init = "play1", title = __("生育屋"),   path = RES_DICT.CATTERY_IMG},
    [ENTRANCE_TAG.FAMILY]   = {size = cc.size(300, 190), scale = 1,    p = cc.p(470, 60),    initPos = cc.p(40, -50), init = "idle",  title = __("喵呜族谱"), path = RES_DICT.FAMILY_IMG},
    [ENTRANCE_TAG.SHOP]     = {size = cc.size(300, 240), scale = 1,    p = cc.p(-400, -210), initPos = cc.p(0, 0), init = "idle",  title = __("喵呜市场")},
    [ENTRANCE_TAG.CAT_LIST] = {size = cc.size(660, 300), scale = 1,    p = cc.p(200, -190),  initPos = cc.p(20, -20), init = "idle",  title = __("喵呜一览"), path = RES_DICT.CAT_LIST_IMG},
}

function CatModuleMainView:ctor(args)
    -- create view
    self.viewData_ = CatModuleMainView.CreateView()
    self:addChild(self.viewData_.view)
end


function CatModuleMainView:getViewData()
    return self.viewData_
end


function CatModuleMainView:showUI(endCB)
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

function CatModuleMainView.CreateView()
    local view = ui.layer()
    local size = view:getContentSize()
    local cpos = cc.sizep(size, ui.cc)

    -- black / block layer
    local backGroundGroup = view:addList({
        ui.image({img = RES_DICT.BG_IMAGE, p = cpos}),
        ui.layer({color = cc.r4b(0), enable = true}),
    })

    ------------------------------------------------- [top]
    local topLayer = ui.layer()
    view:add(topLayer)

    -- back button
    local backBtn = ui.button({n = RES_DICT.COM_BACK_BTN})
    topLayer:addList(backBtn):alignTo(nil, ui.lt, {offsetX = display.SAFE_L + 35, offsetY = -15})

    -- title button
    local titleBtn = ui.button({n = RES_DICT.COM_TITLE_BAR}):updateLabel({fnt = FONT.D1, text = __('猫咪养成'), offset = cc.p(0,-10)})
    topLayer:addList(titleBtn):alignTo(backBtn, ui.rc, {offsetX = 2, offsetY = 10})

    titleBtn:addList(ui.image({img = RES_DICT.COM_TIPS_ICON})):alignTo(nil, ui.rc, {offsetX = -15, offsetY = -10})

    local moneyBar = require('common.CommonMoneyBar').new({isEnableGain = true})
    moneyBar:reloadMoneyBar({CAT_COPPER_COIN_ID, CAT_SILVER_COIN_ID, CAT_GOLD_COIN_ID, CAT_STUDY_COIN_ID}, true)
    topLayer:add(moneyBar)
 
    ------------------------------------------------- [center]
    local centerLayer = ui.layer()
    view:add(centerLayer)

    local entranceBtnMap = {}
    for btnTag, btnInfo in ipairs(ENTRANCE_INFO) do
        local entranceBtn = CatModuleMainView.CreateBtnEntrance(btnInfo)
        entranceBtnMap[btnTag] = entranceBtn
        centerLayer:addChild(entranceBtn)
    end


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
        centerLayer     = centerLayer,
        shopBtn         = entranceBtnMap[ENTRANCE_TAG.SHOP],
        catteryBtn      = entranceBtnMap[ENTRANCE_TAG.CATTERY],
        familyBtn       = entranceBtnMap[ENTRANCE_TAG.FAMILY],
        catListBtn      = entranceBtnMap[ENTRANCE_TAG.CAT_LIST],
    }
end


function CatModuleMainView.CreateBtnEntrance(entranceInfo)
    local view = ui.layer({size = entranceInfo.size, color = cc.r4b(0), enable = true, p = cc.rep(display.center, entranceInfo.p.x, entranceInfo.p.y), ap = ui.cc})

    if entranceInfo.path then
        local entranceSpine = ui.spine({path = entranceInfo.path, init = entranceInfo.init, scale = entranceInfo.scale})
        local offset = checktable(entranceInfo.initPos)
        view:addList(entranceSpine, -1):alignTo(nil, ui.cc, {offsetX = checkint(offset.x), offsetY = checkint(offset.y)})
    end
    
    local title = ui.title({n = RES_DICT.ENTRANCE_BG}):updateLabel({fnt = FONT.D20, fontSize = 32, outline = "#5f1e13", text = tostring(entranceInfo.title), offset = cc.p(0, 10), reqW = 240})
    view:addList(title):alignTo(nil, ui.cb, {offsetY = -20})

    return view
end


return CatModuleMainView

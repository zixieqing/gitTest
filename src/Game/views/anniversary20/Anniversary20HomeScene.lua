--[[
 * author : kaishiqi
 * descpt : 2020周年庆 - 主界面
]]
local Anniversary20HomeScene = class('Anniversary20HomeScene', require('Frame.GameScene'))

local RES_DICT = {
    --             = top
    COM_BACK_BTN   = _res('ui/common/common_btn_back.png'),
    COM_TITLE_BAR  = _res('ui/common/common_title.png'),
    COM_TIPS_ICON  = _res('ui/common/common_btn_tips.png'),
    DRAW_BTN       = _res('ui/anniversary20/home/wonderland_main_btn_receive.png'),
    SHOP_BTN       = _res('ui/anniversary20/home/wonderland_main_btn_shop.png'),
    STORY_BTN      = _res('ui/anniversary20/home/wonderland_main_btn_story.png'),
    --             = center
    BG_IMAGE       = _res('ui/anniversary20/home/wonderland_bg.png'),
    EXPORE_BTN     = _res('ui/anniversary20/home/wonderland_main_btn_copies.png'),
    HANG_BTN      = _res('ui/anniversary20/home/wonderland_main_btn_play.png'),
    PUZZLE_BTN     = _res('ui/anniversary20/home/wonderland_main_btn_puzzle.png'),
    NAME_FRAME     = _res('ui/anniversary20/home/wonderland_main_btn_subtitle.png'),
    TIME_FRAME     = _res('ui/anniversary20/home/wonderland_main_label_num.png'),
    SHOP_LVBAR_BG  = _res("ui/anniversary20/home/allround_bg_bar_grey.png"),
    SHOP_LVBAR_IMG = _res("ui/anniversary20/home/allround_bg_bar_active.png"),
    EXPORE_SPINE   = _spn("ui/anniversary20/home/effects/wonderland_main_savitar"),
    BG_LIGHT_SPINE = _spn("ui/anniversary20/home/effects/wonderland_main_starlight"),
}


function Anniversary20HomeScene:ctor(args)
    self.super.ctor(self, 'Game.views.anniversary20.Anniversary20HomeScene')

    -- create view
    self.viewData_ = Anniversary20HomeScene.CreateView()
    self:addChild(self.viewData_.view)
end


function Anniversary20HomeScene:getViewData()
    return self.viewData_
end


function Anniversary20HomeScene:showUI(endCB)
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


-------------------------------------------------
-- public

function Anniversary20HomeScene:updateDrawHpTime(leftSeconds)
    local hasLeftSeconds = checkint(leftSeconds) > 0
    self:getViewData().hpTimeBar:setVisible(hasLeftSeconds)
    self:getViewData().drawBtn:getLabel():setVisible(not hasLeftSeconds)

    if hasLeftSeconds then
        local timeText = CommonUtils.getTimeFormatByType(checkint(leftSeconds))
        self:getViewData().hpTimeBar:updateLabel({text = timeText})
    end
end


function Anniversary20HomeScene:updateOpenChestTime(leftSeconds)
    local hasLeftSeconds = checkint(leftSeconds) > 0
    self:getViewData().hangTimeBar:setVisible(hasLeftSeconds)

    if hasLeftSeconds then
        local timeText = CommonUtils.getTimeFormatByType(checkint(leftSeconds))
        self:getViewData().hangTimeBar:updateLabel({text = timeText})
    end
end


function Anniversary20HomeScene:updateShopExpProgress(minExp, maxExp, nowExp, levelNum)
    local currExp  = checkint(nowExp) - checkint(minExp)
    local totalExp = checkint(maxExp) - checkint(minExp)
    local percent  = totalExp > 0 and checkint(currExp / totalExp * 100) or 0
    local barValue = math.max(0, math.min(percent, 100))
    self:getViewData().shopLevelPbar:setValue(barValue)

    local isMaxLevel = app.anniv2020Mgr:isShopMaxLevel()
    local levelText  = string.fmt(__('等级：_level_（_current_ / _total_）'), {_level_ = levelNum, _current_ = currExp, _total_ = totalExp})
    self:getViewData().shopLevelBar:updateLabel({text = isMaxLevel and __('等级：满级') or levelText})

    if levelNum > 0 then
        local animationIndex = math.max(3, math.ceil(levelNum/2)) -- 最高动画只做到了3
        self:getViewData().exploreSpine:setAnimation(0, 'play' .. animationIndex, false)
        self:getViewData().exploreSpine:addAnimation(0, 'idle' .. animationIndex, true)
    else
        self:getViewData().exploreSpine:setAnimation(0, 'idle0', true)
    end
end


-------------------------------------------------------------------------------
-- view define
-------------------------------------------------------------------------------

function Anniversary20HomeScene.CreateView()
    local view = ui.layer()
    local size = view:getContentSize()
    local cpos = cc.sizep(size, ui.cc)

    -- bgImg / block layer
    local backGroundGroup = view:addList({
        ui.image({img = RES_DICT.BG_IMAGE, p = cpos}),
        ui.layer({color = cc.r4b(0), enable = true}),
    })
    

    ------------------------------------------------- [center]
    local centerLayer = ui.layer()
    view:add(centerLayer)

    -- center func [explore | hang | puzzle]
    local centerFuncGroup = centerLayer:addList({
        Anniversary20HomeScene.CreateEntranceBtn(cc.size(280, 600), RES_DICT.EXPORE_BTN, __('空中花园'), {r = 445, b = 0}),
        Anniversary20HomeScene.CreateEntranceBtn(cc.size(340, 300), RES_DICT.HANG_BTN, __('马车之旅'), {r = 60, t = 120}),
        Anniversary20HomeScene.CreateEntranceBtn(cc.size(500, 380), RES_DICT.PUZZLE_BTN, __('魔镜城堡'), {l = 400, b = 40}),
    })
    ui.flowLayout(cpos, centerFuncGroup, {type = ui.flowC, ap = ui.cc})

    -- hangTimeBar
    local hangTimeBar = ui.title({n = RES_DICT.TIME_FRAME}):updateLabel({fnt = FONT.D19, fontSize = 24, text = '00:00:00'})
    centerLayer:addList(hangTimeBar):alignTo(centerFuncGroup[2], ui.cb, {offsetY = -25})
    hangTimeBar:setVisible(false)

    -- shopLevelPbar
    local shopLevelPbar = ui.pBar({bg = RES_DICT.SHOP_LVBAR_BG, img = RES_DICT.SHOP_LVBAR_IMG, dir = display.PDIR_LR, min = 0, max = 100})
    centerLayer:addList(shopLevelPbar):alignTo(centerFuncGroup[1], ui.cb, {offsetY = -30})
    
    -- shopLevelBar
    local shopLevelBar = ui.label({fnt = FONT.D19, fontSize = 16})
    centerLayer:addList(shopLevelBar):alignTo(shopLevelPbar, ui.cc, {offsetY1 = -25})

    -- effects group
    local effectsGroup = centerLayer:addList({
        ui.spine({path = RES_DICT.BG_LIGHT_SPINE, init = 'animation'}),
        ui.spine({path = RES_DICT.EXPORE_SPINE, init = 'idle0'}),
    })
    ui.flowLayout(cpos, effectsGroup, {type = ui.flowC, ap = ui.cc})
    

    ------------------------------------------------- [top]
    local topLayer = ui.layer()
    view:add(topLayer)

    -- money bar
    local moneyBar = require('common.CommonMoneyBar').new({})
    moneyBar:reloadMoneyBar({ 
        app.anniv2020Mgr:getHpGoodsId(),
        app.anniv2020Mgr:getShopCurrencyId(),
        app.anniv2020Mgr:getPuzzleGoodsId(),
    }, true, {
        [app.anniv2020Mgr:getShopCurrencyId()] = {hidePlus = true, disable = true},
        [app.anniv2020Mgr:getPuzzleGoodsId()]  = {hidePlus = true, disable = true},
    })
    topLayer:add(moneyBar)

    -- back button
    local backBtn = ui.button({n = RES_DICT.COM_BACK_BTN})
    topLayer:addList(backBtn):alignTo(nil, ui.lt, {offsetX = display.SAFE_L + 35, offsetY = -15})

    -- title button
    local titleBtn = ui.button({n = RES_DICT.COM_TITLE_BAR}):updateLabel({fnt = FONT.D1, text = __('梦中迷途'), offset = cc.p(0,-10)})
    topLayer:addList(titleBtn):alignTo(backBtn, ui.rc, {offsetX = 2, offsetY = 10})

    titleBtn:addList(ui.image({img = RES_DICT.COM_TIPS_ICON})):alignTo(nil, ui.rc, {offsetX = -15, offsetY = -10})


    -- top func [shop | draw | story]
    local createBtn = function(res, str)
        local button = ui.button({n = res})
        local text   = ui.label({fnt = FONT.D14, outline = '#591F1F', w = 125, text = str, hAlign = display.TAC, ap = ui.ct})
        button:addList(text):alignTo(nil, ui.cb, {offsetY = -10})

        return button
    end
    local topFuncGroup = topLayer:addList({
        createBtn(RES_DICT.SHOP_BTN, __('疯帽子商店')),
        createBtn(RES_DICT.DRAW_BTN, __('鹿球的祝福')),
        createBtn(RES_DICT.STORY_BTN, __('剧情收集')),
    })
    ui.flowLayout(cc.rep(cc.sizep(size, ui.rt), -display.SAFE_L - 30, -60), topFuncGroup, {type = ui.flowH, ap = ui.rt, gapW = 30})

    -- hpTimer bar
    local hpTimeBar = ui.title({img = RES_DICT.TIME_FRAME}):updateLabel({fnt = FONT.D18, text = '00:00:00', scale9 = true, paddingW = 12})
    topLayer:addList(hpTimeBar):alignTo(topFuncGroup[2], ui.cc, {offsetY = -55})
    hpTimeBar:setVisible(false)


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
        shopBtn         = topFuncGroup[1],
        drawBtn         = topFuncGroup[2],
        storyBtn        = topFuncGroup[3],
        hpTimeBar       = hpTimeBar,
        --              = center
        centerLayer     = centerLayer,
        exploreBtn      = centerFuncGroup[1],
        hangBtn         = centerFuncGroup[2],
        puzzleBtn       = centerFuncGroup[3],
        hangTimeBar     = hangTimeBar,
        shopLevelBar    = shopLevelBar,
        shopLevelPbar   = shopLevelPbar,
        exploreSpine    = effectsGroup[2],
    }
end


function Anniversary20HomeScene.CreateEntranceBtn(size, image, name, margin)
    local entranceBtn = ui.layer({size = size, color = cc.r4b(0), enable = true, ap = ui.cc, ml = margin.l, mr = margin.r, mt = margin.t, mb = margin.b})
    entranceBtn:add(ui.image({img = image, p = cc.sizep(size, ui.cc)}))

    local nameBar = ui.title({n = RES_DICT.NAME_FRAME}):updateLabel({fnt = FONT.D20, fontSize = 24, text = name})
    entranceBtn:addList(nameBar):alignTo(nil, ui.cb, {offsetY = -25})
    
    return entranceBtn
end


return Anniversary20HomeScene

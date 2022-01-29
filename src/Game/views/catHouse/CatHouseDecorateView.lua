--[[
 * author : panmeng
 * descpt : 猫屋 - 装饰界面
]]
local CatHouseDecorateView = class('CatHouseDecorateView', function()
    return ui.layer({name = 'Game.views.catHouse.CatHouseDecorateView', enableEvent = true})
end)

local RES_DICT = {
    VIEW_FRAME        = _res('ui/common/common_bg_2.png'),
    BACK_BTN          = _res('ui/common/common_btn_back.png'),
    TITLE_BAR         = _res('ui/common/common_bg_title_2.png'),
    LIST_FRAME        = _res('ui/common/common_bg_list_3.png'),
    BTN_CANCEL        = _res('ui/common/common_btn_white_default.png'),
    BTN_CONFIRM       = _res('ui/common/common_btn_orange.png'),
    BTN_TYPE_N        = _res('avatar/ui/restaurant_bg_banner_default.png'),
    BTN_TYPE_S        = _res('avatar/ui/restaurant_bg_banner_selected.png'),
    BTN_DOWN          = _res('avatar/ui/restaurant_btn_avator_tab.png'),
    ICON_DOWN         = _res('avatar/ui/restaurant_ico_avator_pull_down.png'),
    BTN_CLEAN_ALL     = _res('avatar/ui/decorate_btn_clear_all.png'),
    BOTTOM_BAR        = _res('avatar/ui/decorate_bg_down.png'),
    BTN_SHOP          = _res('avatar/ui/restaurant_main_btn_shop.png'),
    ICON_HEART        = _res('ui/common/common_hint_circle_red_ico.png'),
    LABEL_BAR         = _res('avatar/ui/card_bar_bg.png'),
    CELL_FRAME_D      = _res('avatar/ui/avator_bg_goods_disabled.png'),
    CELL_FRAME_N      = _res('avatar/ui/avator_bg_goods_dsfault.png'),
    CELL_FRAME_S      = _res('avatar/ui/avator_bg_goods_selected.png'),
    SHOP_FRAME        = _res('avatar/ui/restaurant_main_bg_bottom.png'),
    PRESET_BTN        = _res('ui/catHouse/preset/cat_house_ico_presets.png'),
    FUNC_NAME_BAR     = _res('ui/catHouse/home/cat_icon_name_bg.png'),
    BTN_DISABLED      = _res('ui/common/common_btn_orange_disable.png'),
    MENU_CELL_N       = _res('ui/catHouse/preset/avator_bg_presets_dsfault.png'),
    MENU_CELL_S       = _res('ui/catHouse/preset/avator_bg_presets_selected.png'),
    MENU_CELL_DISPLAY = _res('ui/catHouse/preset/avator_bg_presets.png'),
    MENU_BG           = _res('ui/catHouse/preset/decorate_bg_presets_down.png'),
    NENU_TITLE_BG     = _res('ui/catHouse/preset/avator_title_bg_presets.png'),
}

CatHouseDecorateView.TYPE_LIST = {
    CatHouseUtils.AVATAR_TAB_TYPE.ALL,
    CatHouseUtils.AVATAR_TAB_TYPE.LIVING_ROOM,
    CatHouseUtils.AVATAR_TAB_TYPE.BEDROOM,
    CatHouseUtils.AVATAR_TAB_TYPE.HALL,
    CatHouseUtils.AVATAR_TAB_TYPE.CATTERY,
    CatHouseUtils.AVATAR_TAB_TYPE.FLOOR,
    CatHouseUtils.AVATAR_TAB_TYPE.WALL,
    CatHouseUtils.AVATAR_TAB_TYPE.CELLING,
}

CatHouseDecorateView.TYPE_ALL_INDEX = 0
CatHouseDecorateView.AVATAR_CELL_W  = 100


function CatHouseDecorateView:ctor(args)
    -- create view
    self.viewData_ = CatHouseDecorateView.CreateView()
    self:addChild(self.viewData_.view)
end


function CatHouseDecorateView:getViewData()
    return self.viewData_
end


function CatHouseDecorateView:toFoldAvatar_()
    local actionTime     = 0.15
    self.isControllable_ = false

    self:stopAllActions()
    self:runAction(cc.Sequence:create(
        cc.TargetedAction:create(self:getViewData().typeBarLayer, cc.MoveTo:create(actionTime, self:getViewData().viewFlodPos)),
        cc.CallFunc:create(function()
            self:getViewData().downIcon:setScaleY(-1)
            self.isControllable_ = true
        end)
    ))
end


function CatHouseDecorateView:toUnfoldAvatar_()
    local actionTime     = 0.15
    self.isControllable_ = false

    self:stopAllActions()
    self:runAction(cc.Sequence:create(
        cc.TargetedAction:create(self:getViewData().typeBarLayer, cc.MoveTo:create(actionTime, self:getViewData().viewUnflodPos)),
        cc.CallFunc:create(function()
            self:getViewData().downIcon:setScaleY(1)
            self.isControllable_ = true
        end)
    ))
end


-------------------------------------------------
-- menu cell

function CatHouseDecorateView:updateMenuCellStatus(cellViewData, isEmpty)
    local confirmBtnStr = isEmpty == true and __("保存") or __("替换")
    cellViewData.confirmBtn:updateLabel({text = confirmBtnStr, reqW = 100})
    cellViewData.applyBtn:setEnabled(not isEmpty)

    if isEmpty == true then
        local grayFilter = GrayFilter:create()
        cellViewData.decorateBg:setFilter(grayFilter)
    else
        cellViewData.decorateBg:clearFilter()
    end
end


-------------------------------------------------
-- avatar cell

function CatHouseDecorateView:updateCellHandler_(cellIndex, cellViewData, avatarData)
    cellViewData.view:setTag(cellIndex)
    cellViewData.imageLayer:removeAllChildren()

    local avatarImgNode = AssetsUtils.GetCatHouseSmallAvatarNode(avatarData.avatarId)
    avatarImgNode:setScale(0.45)
    cellViewData.imageLayer:addList(avatarImgNode):alignTo(nil, ui.cc)
    cellViewData.heartIcon:setVisible(checkbool(avatarData.isHasRed))

    -- updatcelle 
    self:updateAvatarCellStatus_(cellIndex, cellViewData, avatarData)
    return pCell
end


function CatHouseDecorateView:updateAvatarCellStatus_(cellIndex, cellViewData, avatarData)
    local avatarTableView = self:getViewData().avatarTableView
    local avatarViewData  = cellViewData or avatarTableView:cellAtIndex(cellIndex - 1)
    
    if avatarViewData then
        local totalNum = checkint(avatarData.totalNum)
        local usedNum  = checkint(avatarData.usedNum)
        display.commonLabelParams(cellViewData.countLabel, {text = string.fmt('%1/%2', usedNum, totalNum)})
    
        local isEmpty = usedNum >= totalNum and not checkbool(avatarData.isSelected)
        cellViewData.frameBtn:setEnabled(not isEmpty)
        cellViewData.frameBtn:setChecked(checkbool(avatarData.isSelected))
        cellViewData.imageLayer:setColor(isEmpty and cc.c3b(180,180,180) or cc.c3b(255,255,255))
    end
end


-------------------------------------------------------------------------------
-- view define
-------------------------------------------------------------------------------

function CatHouseDecorateView.CreateView()
    local view = ui.layer()
    local size = view:getContentSize()
    local cpos = cc.sizep(size, ui.cc)

    -- typeBar layer
    local centerLayer = ui.layer()
    view:add(centerLayer)

    local presetBtn = ui.button({n = RES_DICT.PRESET_BTN})
    centerLayer:addList(presetBtn):alignTo(nil, ui.rt, {offsetX = -20 -display.SAFE_L, offsetY = -70})

    local presetTitle = ui.title({img = RES_DICT.FUNC_NAME_BAR, size = cc.size(100, 28), cut = cc.dir(5, 5, 5, 5)}):updateLabel({fnt = FONT.D14, fontSize = 22, text =__("预设"), reqW = 90})
    presetBtn:addList(presetTitle):alignTo(nil, ui.cb, {offsetY = -10})

    
    local typeBarLayer = ui.layer({size = cc.size(display.width, 148)})
    view:add(typeBarLayer)

    local typeBtnViewDataGroup = {}
    local typeBtnGroup         = {}
    for _, typeId in pairs(CatHouseDecorateView.TYPE_LIST) do
        local typeViewData = CatHouseDecorateView.CreateTypeView(typeId)
        typeViewData.view:setTag(typeId)
        typeBarLayer:addChild(typeViewData.view)
        typeBtnViewDataGroup[typeId] = typeViewData
        table.insert(typeBtnGroup, typeViewData.view)
    end
    ui.flowLayout(cc.rep(cc.sizep(typeBarLayer, ui.lt), 120 + display.SAFE_L, 0), typeBtnGroup, {type = ui.flowH, ap = ui.lt})

    -- down button
    local downBtn = ui.button({n = RES_DICT.BTN_DOWN})
    typeBarLayer:addList(downBtn):alignTo(nil, ui.lt, {offsetX = display.SAFE_L})

    local downIcon = ui.image({img = RES_DICT.ICON_DOWN})
    downBtn:addList(downIcon):alignTo(nil, ui.cc, {offsetY = 3})

    -- bottom bar
    typeBarLayer:addList(ui.image({img = RES_DICT.BOTTOM_BAR, scale9 = true, size = cc.size(display.width, 110)})):alignTo(nil, ui.cb)



    -- cleanAll btn
    local cleanAllBtn = ui.button({n = RES_DICT.BTN_CLEAN_ALL}):updateLabel({fnt = FONT.D16, text = __("清除全部"), offset = cc.p(-5, -30), reqW = 90})
    typeBarLayer:addList(cleanAllBtn):alignTo(nil, ui.lb, {offsetX = display.SAFE_L})

    -- shop button
    local shopFrame = ui.image({img = RES_DICT.SHOP_FRAME})
    typeBarLayer:addList(shopFrame):alignTo(nil, ui.rb, {offsetX = -display.SAFE_L + 60})

    local shopButton = ui.button({n = RES_DICT.BTN_SHOP})
    typeBarLayer:addList(shopButton):alignTo(shopFrame, ui.cc, {offsetX = -5, offsetY = 15})

    local redPointIcon = ui.image({img = RES_DICT.ICON_HEART})
    redPointIcon:setName('redPointIcon')
    redPointIcon:setVisible(false)
    typeBarLayer:addList(redPointIcon):alignTo(shopButton, ui.rt, {offsetX = -50, offsetY = - 70})

    local shopNameBar = ui.title({n = RES_DICT.LABEL_BAR}):updateLabel({fnt = FONT.D14, text = __("家具商店"), color = "#ffffff", reqW = 100})
    shopButton:addList(shopNameBar):alignTo(nil, ui.cb)

    -- avatar pageView
    local avatarTableView = ui.tableView({size = cc.size(display.SAFE_RECT.width - 320, 100), dir = display.SDIR_H, csizeW = CatHouseDecorateView.AVATAR_CELL_W})
    typeBarLayer:addList(avatarTableView):alignTo(nil, ui.lb, {offsetX = display.SAFE_L + 115})
    avatarTableView:setCellCreateHandler(CatHouseDecorateView.CreateAvatarCell)

    local presetFrameView = ui.layer()
    view:addList(presetFrameView)
    presetFrameView:setVisible(false)

    local presetBgGroup = presetFrameView:addList({
        ui.layer({color = cc.r4b(0), enable = true}),
        ui.layer(),
    })

    local presetView = presetBgGroup[2]
    local titleNode = ui.title({n = RES_DICT.NENU_TITLE_BG}):updateLabel({fnt = FONT.D14, fontSize = 20, outline = "#000000", text = __("预设菜单"), reqW = 100})
    presetView:addList(titleNode):alignTo(nil, ui.lb, {offsetX = display.SAFE_L + 30, offsetY = 240})

    local menuBg = ui.image({img = RES_DICT.MENU_BG, scale9 = true, size = cc.size(display.width + 20, 252)})
    presetView:addList(menuBg):alignTo(nil, ui.cb)

    local menuTableView = ui.tableView({size = cc.size(display.SAFE_RECT.width, 240), dir = display.SDIR_H, csizeW = 323})
    presetView:addList(menuTableView):alignTo(nil, ui.cb)
    
    menuTableView:setCellCreateHandler(CatHouseDecorateView.CreateMenuCell)


    return {
        view                 = view,
        downBtn              = downBtn,
        downIcon             = downIcon,
        viewFlodPos          = cc.p(typeBarLayer:getPositionX(), typeBarLayer:getPositionY() - 100),
        viewUnflodPos        = cc.p(typeBarLayer:getPosition()),
        typeBarLayer         = typeBarLayer,
        shopButton           = shopButton,
        cleanAllBtn          = cleanAllBtn,
        typeBtnViewDataGroup = typeBtnViewDataGroup,
        avatarTableView      = avatarTableView,
        presetBtn            = presetBtn,
        presetFrameView      = presetFrameView,
        menuTableView        = menuTableView,
    }
end


function CatHouseDecorateView.CreateTypeView(typeId)
    local size = cc.size(120, 45)
    local view = ui.layer({size = size})

    local titleBtn = ui.tButton({n = RES_DICT.BTN_TYPE_N, s = RES_DICT.BTN_TYPE_S})
    view:addList(titleBtn):alignTo(nil, ui.cc)

    local titleStr = CatHouseUtils.GetAvatarTabTypeName(typeId)
    local titleLabel = ui.label({fnt = FONT.D6, text = titleStr, reqW = titleBtn:getContentSize().width - 20})
    titleBtn:getNormalImage():addList(titleLabel):alignTo(nil, ui.cc, {offsetY = -10})

    local titleIcon = ui.image({img = _res(CatHouseUtils.GetAvatarTabTypeIcon(typeId))})
    titleBtn:getSelectedImage():setPositionY(titleBtn:getSelectedImage():getPositionY() - 6)
    titleBtn:getSelectedImage():addList(titleIcon):alignTo(nil, ui.cc, {offsetY = 30})

    local heartIcon = ui.image({img = _res(RES_DICT.ICON_HEART), p = cc.p(size.width - 10, size.height - 10)})
    view:addChild(heartIcon)

    return {
        view       = view,
        titleBtn   = titleBtn,
        heartIcon  = heartIcon,
    }
end


function CatHouseDecorateView.CreateAvatarCell(cellParent)
    local size = cellParent:getContentSize()
    local view = ui.layer({size = size})
    cellParent:add(view)--:alignTo(nil, ui.cc)

    local frameBtn = ui.tButton({n = RES_DICT.CELL_FRAME_N, s = RES_DICT.CELL_FRAME_S, d = RES_DICT.CELL_FRAME_D, scale9 = true, cut = cc.dir(8, 8, 78, 78)})
    view:addList(frameBtn):alignTo(nil, ui.cc)

    local imageLayer = ui.layer({size = size})
    view:add(imageLayer)

    local countLabel = ui.label({fnt = FONT.D19, ap = ui.cb})
    view:addList(countLabel):alignTo(nil, ui.cb)

    local heartIcon = ui.image({img = RES_DICT.ICON_HEART, ap = ui.rt})
    view:addList(heartIcon):alignTo(nil, ui.rt)
    view.heartIcon = heartIcon

    return {
        view            = view,
        frameBtn        = frameBtn,
        imageLayer      = imageLayer,
        countLabel      = countLabel,
        heartIcon       = heartIcon,
    }
end


function CatHouseDecorateView.CreateMenuCell(cellParent)
    local size = cellParent:getContentSize()
    local view = ui.layer({size = size})
    cellParent:addList(view):alignTo(nil, ui.rc)

    local toggleBtn = ui.tButton({n = RES_DICT.MENU_CELL_N, s = RES_DICT.MENU_CELL_S})
    view:addList(toggleBtn):alignTo(nil, ui.cc)

    local menuGroup = view:addList({
        FilteredSpriteWithOne:create(RES_DICT.MENU_CELL_DISPLAY),
        ui.layer({size = cc.size(size.width, 60)}),   
    })
    ui.flowLayout(cc.sizep(view, ui.cc), menuGroup, {type = ui.flowV, ap = ui.cc, gapH = 10})

    local buttonGroup = menuGroup[2]:addList({
        ui.button({n = RES_DICT.BTN_CONFIRM}):updateLabel({fnt = FONT.D14, text = "--", reqW = 100}),
        ui.button({n = RES_DICT.BTN_CONFIRM, d = RES_DICT.BTN_DISABLED}):updateLabel({fnt = FONT.D14, text = __("启用"), reqW = 100}),
    })
    ui.flowLayout(cc.sizep(menuGroup[2], ui.cc), buttonGroup, {type = ui.flowH, ap = ui.cc, gapW = 10})
    
    return {
        view       = view,
        toggleBtn  = toggleBtn,
        confirmBtn = buttonGroup[1],
        applyBtn   = buttonGroup[2],
        decorateBg = menuGroup[1],
    }
end


return CatHouseDecorateView

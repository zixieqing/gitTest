local PresetView = class('PresetView', function()
    return ui.layer({name = 'Game.views.restaurant.PresetView', enableEvent = true})
end)

local RES_DICT = {
    MENU_CELL_N       = _res('ui/catHouse/preset/avator_bg_presets_dsfault.png'),
    MENU_CELL_S       = _res('ui/catHouse/preset/avator_bg_presets_selected.png'),
    MENU_CELL_DISPLAY = _res('avatar/ui/restaurant_bg_presets.png'),
    MENU_BG           = _res('ui/catHouse/preset/decorate_bg_presets_down.png'),
    NENU_TITLE_BG     = _res('ui/catHouse/preset/avator_title_bg_presets.png'),
    BTN_CANCEL        = _res('ui/common/common_btn_white_default.png'),
    BTN_CONFIRM       = _res('ui/common/common_btn_orange.png'),
}


function PresetView:ctor(args)
    -- create view
    self.viewData_ = PresetView.CreateView()
    self:addChild(self.viewData_.view)
end


function PresetView:getViewData()
    return self.viewData_
end

function PresetView:updateMeneCellHandler(cellViewData, isEmpty)
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

-------------------------------------------------------------------------------
-- view define
-------------------------------------------------------------------------------

function PresetView.CreateView()
    local view = ui.layer()
    local size = view:getContentSize()
    local cpos = cc.sizep(size, ui.cc)

    -- black / block layer
    local backGroundGroup = view:addList({
        ui.layer({color = cc.r4b(0), enable = true}),
        ui.layer(),
    })

    ------------------------------------------------- [center]
    local centerLayer = backGroundGroup[2]
    local titleNode = ui.title({n = RES_DICT.NENU_TITLE_BG}):updateLabel({fnt = FONT.D14, fontSize = 20, outline = "#000000", text = __("预设菜单"), reqW = 100})
    centerLayer:addList(titleNode):alignTo(nil, ui.lb, {offsetX = display.SAFE_L + 30, offsetY = 240})

    local menuBg = ui.image({img = RES_DICT.MENU_BG, scale9 = true, size = cc.size(display.width + 20, 252)})
    centerLayer:addList(menuBg):alignTo(nil, ui.cb)

    local menuTableView = ui.tableView({size = cc.size(display.SAFE_RECT.width, 240), dir = display.SDIR_H, csizeW = 323})
    centerLayer:addList(menuTableView):alignTo(nil, ui.cb)
    
    menuTableView:setCellCreateHandler(PresetView.CreateMenuCell)


    return {
        view            = view,
        blockLayer      = backGroundGroup[1],
        --              = top
        menuTableView   = menuTableView,
    }
end


function PresetView.CreateMenuCell(cellParent)
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


return PresetView

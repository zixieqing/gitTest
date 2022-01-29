--[[
 * author : liuzhipeng
 * descpt : 猫屋 - 交配事件 视图
]]
local CatHeadNode = require('Game.views.catModule.cat.CatHeadNode')
---@class CatHouseMatingEventView
local CatHouseMatingEventView = class('CatHouseMatingEventView', function()
    return ui.layer({name = 'Game.views.catHouse.CatHouseMatingEventView', enableEvent = true})
end)

local RES_DICT = {
    VIEW_FRAME  = _res('ui/common/common_bg_2.png'),
    TITLE_BAR   = _res('ui/common/common_bg_title_2.png'),
    LIST_FRAME  = _res('ui/common/common_bg_list_3.png'),
    BTN_CANCEL  = _res('ui/common/common_btn_white_default.png'),
    BTN_CONFIRM = _res('ui/common/common_btn_orange.png'),
    OUT_TIP_BG  = _res('ui/catHouse/chooseCat/cat_select_tips_bg.png'),
}


function CatHouseMatingEventView:ctor(args)
    -- create view
    self.viewData_ = CatHouseMatingEventView.CreateView()
    self:addChild(self.viewData_.view)
end


function CatHouseMatingEventView:getViewData()
    return self.viewData_
end


function CatHouseMatingEventView:updateDescr(descrText)
    local scrollView = self:getViewData().scrollView
    local descrLabel = self:getViewData().descrLabel
    descrLabel:updateLabel({text = tostring(descrText)})
    
    local scrollSize = scrollView:getContentSize()
    local descrSize  = descrLabel:getSize()
    scrollView:setContainerSize(descrSize)
    scrollView:setDragable(scrollSize.height < descrSize.height)
    scrollView:setContentOffset(cc.p(0, scrollSize.height - descrSize.height))
end


-------------------------------------------------------------------------------
-- view define
-------------------------------------------------------------------------------

function CatHouseMatingEventView.CreateView()
    local view = ui.layer()
    local size = view:getContentSize()
    local cpos = cc.sizep(size, ui.cc)

    -- black / block layer
    local backGroundGroup = view:addList({
        ui.layer({color = cc.c4b(0,0,0,150)}),
        ui.layer({color = cc.r4b(0), enable = true}),
    })


    ------------------------------------------------- [top]
    local topLayer = ui.layer()
    view:add(topLayer)


    ------------------------------------------------- [center]
    local centerLayer = ui.layer()
    view:add(centerLayer)

    -- view frame
    local viewFrameNode = ui.layer({p = cpos, bg = RES_DICT.VIEW_FRAME, ap = ui.cc, enable = true})
    local viewFrameSize = viewFrameNode:getContentSize()
    centerLayer:add(viewFrameNode)


    -- title bar
    local titleBar = ui.title({img = RES_DICT.TITLE_BAR}):updateLabel({fnt = FONT.D3, text = __('请选择生育猫咪'), paddingW = 60, safeW = 120, offset = cc.p(0,-2)})
    viewFrameNode:addList(titleBar):alignTo(nil, ui.ct, {offsetY = -4})

    -- scroll view
    local scrollView = ui.scrollView({size = cc.resize(viewFrameSize, -60, -160), dir = display.SDIR_B, bgColor = cc.r4b(100)})
    viewFrameNode:addList(scrollView):alignTo(nil, ui.ct, {offsetY = -50})

    -- descr label
    local descrLabel = ui.label({fnt = FONT.D4, ap = ui.lb})
    scrollView:getContainer():add(descrLabel)


    -- cancel / confirm button
    local funcBtnGroup = view:addList({
        ui.button({n = RES_DICT.BTN_CANCEL}):updateLabel({fnt = FONT.D14, text = __('取消')}),
        ui.button({n = RES_DICT.BTN_CONFIRM}):updateLabel({fnt = FONT.D14, text = __('确认')}),
    })
    ui.flowLayout(cc.p(cpos.x, 110), funcBtnGroup, {ap = ui.cc, type = ui.flowH, gapW = 100})

    -- time label
    local timeTitle = ui.label({fnt = FONT.D4, ap = ui.cc})
    viewFrameNode:addList(timeTitle):alignTo(nil, ui.cb, {offsetY = 30})

    -- friend catHeadNode
    local friendCatHeadNode = CatHeadNode.new()
    viewFrameNode:addList(friendCatHeadNode):alignTo(nil, ui.lb, {offsetY = 80})

    -- myself catHeadNode
    local myselfCatHeadNode = CatHeadNode.new()
    viewFrameNode:addList(myselfCatHeadNode):alignTo(nil, ui.rb, {offsetY = 80})


    ------------------------------------------------- [right]
    local rightLayer = ui.layer()
    view:add(rightLayer)

    local catsPanelSize = cc.size(240 + display.SAFE_L, display.height)
    local catsPanelNode = ui.layer({size = catsPanelSize})
    rightLayer:addList(catsPanelNode):alignTo(nil, ui.rc)

    local catsPanelBg = ui.layer({size = catsPanelSize, color = cc.r4b(150), enable = true})
    catsPanelNode:addList(catsPanelBg)

    local catsTitleBar = ui.title({img = RES_DICT.TITLE_BAR}):updateLabel({fnt = FONT.D3, text = __('猫咪列表'), paddingW = 60, safeW = 120, offset = cc.p(0,-2)})
    catsPanelNode:addList(catsTitleBar):alignTo(nil, ui.ct, {offsetW = display.SAFE_L, offsetY = -4})

    -- cats tableView
    local catsTableView = ui.tableView({size = cc.resize(catsPanelSize, -80, -60), csizeH = 210, dir = display.SDIR_V})
    catsPanelNode:addList(catsTableView):alignTo(nil, ui.cb, {offsetW = display.SAFE_L, offsetY = 8})
    catsTableView:setCellCreateHandler(CatHouseMatingEventView.CreateCatCell)

    -- cat emptyLabel
    local catEmpthLabel = ui.label({fnt = FONT.D20, text = __('暂无猫咪')})
    catsPanelNode:addList(catEmpthLabel):alignTo(catsTableView, ui.cc)


    return {
        view              = view,
        blackLayer        = backGroundGroup[1],
        blockLayer        = backGroundGroup[2],
        --                = center
        scrollView        = scrollView,
        descrLabel        = descrLabel,
        cancelBtn         = funcBtnGroup[1],
        confirmBtn        = funcBtnGroup[2],
        timeTitle         = timeTitle,
        friendCatHeadNode = friendCatHeadNode,
        myselfCatHeadNode = myselfCatHeadNode,
        --                = right
        catsTableView     = catsTableView,
        catEmpthLabel     = catEmpthLabel,
    }
end


function CatHouseMatingEventView.CreateCatCell(cellParent)
    local view = cellParent
    local size = cellParent:getContentSize()
    local cpos = cc.sizep(size, ui.cc)

    local catHeadNode = CatHeadNode.new()
    view:addList(catHeadNode):alignTo(nil, ui.cc)

    local matingTips = ui.title({n = RES_DICT.OUT_TIP_BG}):updateLabel({fnt = FONT.D14, fontSize = 22, outline = "#311717", text = __("不可交配"), reqW = 160})
    view:addList(matingTips):alignTo(nil, ui.cc)

    local clickArea = ui.layer({size = size, color = cc.r4b(0), enable = true})
    view:addList(clickArea):alignTo(nil, ui.cc)

    return {
        view        = view,
        catHeadNode = catHeadNode,
        matingTips  = matingTips,
        clickArea   = clickArea,
    }
end


return CatHouseMatingEventView

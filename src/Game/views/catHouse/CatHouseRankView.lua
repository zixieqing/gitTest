--[[
 * author : zhipeng
 * descpt : 猫屋 - 排行榜 界面
]]
local CatHouseRankView = class('CatHouseRankView', function()
    return ui.layer({name = 'Game.views.catHouse.CatHouseRankView', enableEvent = true})
end)

local RES_DICT = {
    VIEW_FRAME  = _res('ui/common/common_bg_2.png'),
    BACK_BTN    = _res('ui/common/common_btn_back.png'),
    TITLE_BAR   = _res('ui/common/common_bg_title_2.png'),
    LIST_FRAME  = _res('ui/common/common_bg_list_3.png'),
    BTN_CANCEL  = _res('ui/common/common_btn_white_default.png'),
    BTN_CONFIRM = _res('ui/common/common_btn_orange.png'),
}


function CatHouseRankView:ctor(args)
    -- create view
    self.viewData_ = CatHouseRankView.CreateView()
    self:addChild(self.viewData_.view)
end


function CatHouseRankView:getViewData()
    return self.viewData_
end


function CatHouseRankView:updateDescr(descrText)
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

function CatHouseRankView.CreateView()
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

    -- back button
    local backBtn = ui.button({n = RES_DICT.BACK_BTN})
    topLayer:addList(backBtn):alignTo(nil, ui.lt, {offsetX = display.SAFE_L + 35, offsetY = -15})


    ------------------------------------------------- [center]
    local centerLayer = ui.layer()
    view:add(centerLayer)

    -- view frame
    local viewFrameNode = ui.layer({p = cpos, bg = RES_DICT.VIEW_FRAME, ap = ui.cc, enable = true})
    local viewFrameSize = viewFrameNode:getContentSize()
    centerLayer:add(viewFrameNode)


    -- title bar
    local titleBar = ui.title({img = RES_DICT.TITLE_BAR}):updateLabel({fnt = FONT.D3, text = __('排行榜'), paddingW = 60, safeW = 120, offset = cc.p(0,-2)})
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


    return {
        view         = view,
        blackLayer   = backGroundGroup[1],
        blockLayer   = backGroundGroup[2],
        --           = top
        backBtn      = backBtn,
        --           = center
        scrollView   = scrollView,
        descrLabel   = descrLabel,
        cancelBtn    = funcBtnGroup[1],
        confirmBtn   = funcBtnGroup[2],
    }
end


return CatHouseRankView

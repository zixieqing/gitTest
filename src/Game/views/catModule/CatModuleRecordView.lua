local CatModuleRecordView = class('CatModuleRecordView', function()
    return ui.layer({name = 'Game.views.catModule.CatModuleRecordView', enableEvent = true})
end)

CatModuleRecordView.PAGE_TAG = {
    INFO = 1, -- 信息
    NOTE = 2, -- 日记
    LIKE = 3, -- 好感
}

local PAGE_INFO = {
    [CatModuleRecordView.PAGE_TAG.INFO] = {title = __("信息"), path = "Game.views.catModule.CatModuleRecordInfoView"},
    [CatModuleRecordView.PAGE_TAG.NOTE] = {title = __("日记"), path = "Game.views.catModule.CatModuleRecordDailyView"},
    [CatModuleRecordView.PAGE_TAG.LIKE] = {title = __("好感"), path = "Game.views.catModule.CatModuleRecordFavorabilityView"},
}

local RES_DICT = {
    VIEW_FRAME  = _res('ui/catModule/catRecord/grow_cat_record_love_bg_book.png'),
    BTN_N       = _res('ui/catModule/catRecord/grow_cat_record_love_btn_type_grey.png'),
    BTN_S       = _res('ui/catModule/catRecord/grow_cat_record_love_btn_type_light.png'),
    DESCR_BG    = _res('ui/common/commcon_bg_text.png'),
    ARROW_BG    = _res("ui/anniversary20/hang/common_bg_tips_horn.png"),
}


function CatModuleRecordView:ctor(args)
    -- create view
    self.viewData_ = CatModuleRecordView.CreateView()
    self:addChild(self.viewData_.view)

    self.pageNode = {}
end


function CatModuleRecordView:getViewData()
    return self.viewData_
end

-------------------------------------------------------------------------------
-- get/set
-------------------------------------------------------------------------------
function CatModuleRecordView:showGeneDetailView(parent, closeCB)
    local geneId = checkint(parent:getTag())
    local geneViewData = CatModuleRecordView.CreateGeneDetailView(geneId, closeCB)
    local worldPos = parent:getParent():convertToWorldSpace(cc.p(parent:getPosition()))
    geneViewData.centerLayer:setPosition(cc.rep(worldPos, 130, -10))

    self:add(geneViewData.view)
end

-------------------------------------------------------------------------------
-- view define
-------------------------------------------------------------------------------
function CatModuleRecordView.CreateView()
    local view = ui.layer()
    local size = view:getContentSize()

    -- black layer | block layer | center layer
    local bg = ui.layer({bg = RES_DICT.VIEW_FRAME})
    local frameSize = cc.resize(bg:getContentSize(), 100, 0)
    local backGroundGroup = view:addList({
        ui.layer({color = cc.c4b(0,0,0,150), enable = true}),
        ui.layer({color = cc.r4b(0), enable = true, size = frameSize, ml = 50}),
        ui.layer({size = frameSize, ml = 50}),
    })
    ui.flowLayout(cc.sizep(size, ui.cc), backGroundGroup, {type = ui.flowC, ap = ui.cc})

    local centerLayer = backGroundGroup[3]
    centerLayer:addList(bg):alignTo(nil, ui.lc)
    ------------------------------------------------- [center]
    -- cancel / confirm button
    local funcBtnGroup = {}
    for index, btnInfo in ipairs(PAGE_INFO) do
        local btn = ui.tButton({n = RES_DICT.BTN_N, s = RES_DICT.BTN_S})
        local label = ui.label({fnt = FONT.D14, text = btnInfo.title})
        btn:addList(label):alignTo(nil, ui.cc)
        btn:setTag(index)
        table.insert(funcBtnGroup, btn)
    end
    centerLayer:addList(funcBtnGroup)
    ui.flowLayout(cc.rep(cc.sizep(centerLayer, ui.rt), 0, -50), funcBtnGroup, {ap = ui.rb, type = ui.flowV, gapH = 10})


    return {
        view         = view,
        blockLayer   = backGroundGroup[1],
        funcBtnGroup = funcBtnGroup,
        centerLayer  = centerLayer,
    }
end


return CatModuleRecordView

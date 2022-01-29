local VIEW_SIZE = cc.size(960, 600)
local CatModuleRecordInfoView = class('CatModuleRecordInfoView', function()
    return ui.layer({name = 'Game.views.catModule.CatModuleRecordInfoView', enableEvent = true, size = VIEW_SIZE})
end)

local RES_DICT = {
    DESCR_BG = _res('ui/common/commcon_bg_text.png'),
    TITLE_BG = _res("ui/catModule/catRecord/grow_cat_record_news_bg_head.png"),
    LINE_BG  = _res('ui/catModule/catRecord/grow_cat_record_love_line_message.png'),
    ARROW_BG = _res("ui/anniversary20/hang/common_bg_tips_horn.png"),
}


function CatModuleRecordInfoView:ctor(args)
    -- create view
    self.viewData_ = CatModuleRecordInfoView.CreateView()
    self:addChild(self.viewData_.view)
end


function CatModuleRecordInfoView:getViewData()
    return self.viewData_
end


function CatModuleRecordInfoView:updateDescr(geneIdList, raceId)
    local descr = __("这是一只_descr__name_")
    local geneDescr = ""
    for index, geneId in ipairs(geneIdList) do
        local geneConf = CONF.CAT_HOUSE.CAT_GENE:GetValue(geneId)
        geneDescr = geneDescr .. tostring(geneConf.descr2)
    end

    local raceConf = CONF.CAT_HOUSE.CAT_RACE:GetValue(raceId)
    local raceDescr = tostring(raceConf.name)

    self:getViewData().descrLabel:setString(string.fmt(descr, {_descr_ = geneDescr, _name_ = raceDescr}))
    local descrSize      = display.getLabelContentSize(self:getViewData().descrLabel)
    local scrollViewSize = self:getViewData().descrScroll:getContentSize()
    local containerH     = math.max(scrollViewSize.height, descrSize.height + 10)
    self:getViewData().descrScroll:setContainerSize(cc.size(scrollViewSize.width, containerH))
    self:getViewData().descrLabel:setPosition(cc.p(5, containerH - 5))
end


-------------------------------------------------------------------------------
-- view define
-------------------------------------------------------------------------------

function CatModuleRecordInfoView.CreateView()
    local view = ui.layer({size = VIEW_SIZE})

    local viewFrameGroup = view:addList({
        ui.label({fnt = FONT.D1, fontSize = 24, color = "#532922", text = __("猫猫信息"), ml = 10}),
        ui.layer({size = cc.size(900, 240)}),
        ui.image({img = RES_DICT.LINE_BG}),
        ui.layer({size = cc.size(900, 180), mt = -20})
    })
    ui.flowLayout(cc.rep(cc.sizep(VIEW_SIZE, ui.lt), 30, -10), viewFrameGroup, {type = ui.flowV, ap = ui.lb, gapH = 20})


    local infoLayer = viewFrameGroup[2]
    local infoGroup = infoLayer:addList({
        ui.title({n = RES_DICT.TITLE_BG, ml = 20}):updateLabel({fnt = FONT.D4, color = "#75563e", text = __("猫猫详情"), reqW = 100, offset = cc.p(-20, 0)}),
        ui.layer({size = cc.size(820, 162), bg = RES_DICT.DESCR_BG, scale9 = true, ml = 40}),
    })
    ui.flowLayout(cc.sizep(infoLayer, ui.lc), infoGroup, {type = ui.flowV, ap = ui.lc, gapH = 10})

    local descrSLayer = infoGroup[2]
    local descrScroll = ui.scrollView({size = descrSLayer:getContentSize(), dir = display.SDIR_V})
    descrSLayer:addList(descrScroll):alignTo(nil, ui.cc)

    local descrLabel = ui.label({fnt = FONT.D4, color = "#70645b", text = "--", w = descrSLayer:getContentSize().width - 10, p = cc.p(5, 5), ap = ui.lt})
    descrScroll:getContainer():addChild(descrLabel)

    local geneInfoLayer = viewFrameGroup[4]
    local geneInfoGroup = geneInfoLayer:addList({
        ui.title({n = RES_DICT.TITLE_BG, ml = 20}):updateLabel({fnt = FONT.D4, color = "#75563e", text = __("携带基因"), reqW = 100, offset = cc.p(-20, 0)}),
        ui.gridView({size = cc.size(820, 140), dir = display.SDIR_V, cols = 3, csizeH = 80, ml = 40}),
    })
    ui.flowLayout(cc.sizep(geneInfoLayer, ui.lc), geneInfoGroup, {type = ui.flowV, ap = ui.lc, gapH = 10})

    local geneGridView = geneInfoGroup[2]
    geneGridView:setCellCreateClass(require('Game.views.catModule.cat.CatGeneNode'), {defaultCB = true})

    return {
        view         = view,
        descrLabel   = descrLabel,
        descrScroll  = descrScroll,
        geneGridView = geneGridView,
    }
end


return CatModuleRecordInfoView

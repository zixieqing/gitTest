local VIEW_SIZE = cc.size(960, 600)
local CatModuleRecordDailyView = class('CatModuleRecordDailyView', function()
    return ui.layer({name = 'Game.views.catModule.CatModuleRecordDailyView', enableEvent = true, size = VIEW_SIZE})
end)

local RES_DICT = {
    BG_FRAME = _res("ui/catModule/catRecord/grow_cat_record_day_bg_news.png"),
    BG_LINE  = _res("ui/catModule/catRecord/grow_cat_record_day_line_tips.png"),
    BG_PROG  = _res("ui/catModule/catRecord/grow_cat_record_day_bg_tips.png"),
    WEATHER  = _res("ui/catModule/catRecord/day_ico_1.png"),
    EMPTY_BG = _res("ui/catModule/catRecord/grow_cat_record_love_bg_book_empty.png"),
}

function CatModuleRecordDailyView:ctor(args)
    -- create view
    self.viewData_ = CatModuleRecordDailyView.CreateView()
    self:addChild(self.viewData_.view)

    self:getViewData().dailyGridView:resetCellCount(5)
end


function CatModuleRecordDailyView:getViewData()
    return self.viewData_
end


function CatModuleRecordDailyView:updateProgress(curProgress, totalProgress)
    self:getViewData().progress:updateLabel({text = string.fmt("_num1_/_num2_", {_num1_ = tostring(curProgress), _num2_ = tostring(totalProgress)})})
    self:getViewData().emptyTip:setVisible(curProgress <= 0)
end


function CatModuleRecordDailyView:updateJournalHandler(cellIndex, cellViewData, journalData)
    if not journalData then
        return
    end
    local osTime = os.date("!*t", journalData.timestamp)
    cellViewData.timeLabel:setString(string.format("%d.%02d.%02d", osTime.year, osTime.month, osTime.day))

    local journalConf = CONF.CAT_HOUSE.CAT_JOURNAL:GetValue(journalData.journalId)
    cellViewData.journalLabel:setString(tostring(journalConf.descr))

    local descrSize      = display.getLabelContentSize(cellViewData.journalLabel)
    local scrollViewSize = cellViewData.scrollView:getContentSize()
    local containerH     = math.max(scrollViewSize.height, descrSize.height + 10)
    cellViewData.scrollView:setContainerSize(cc.size(scrollViewSize.width, math.max(containerH, scrollViewSize.height)))
    cellViewData.scrollView:setContentOffsetToTop()
    cellViewData.journalLabel:setPosition(cc.p(5, containerH - 5))

    local iconPath = _res(string.format("ui/catModule/catRecord/%s.png", tostring(journalConf.weatherIcon)))
    cellViewData.weatherIcon:setTexture(iconPath)
end

-------------------------------------------------------------------------------
-- view define
-------------------------------------------------------------------------------
function CatModuleRecordDailyView.CreateDailyCell(cellParent)
    local size = cellParent:getContentSize()
    local view = ui.layer({size = size})
    cellParent:addList(view):alignTo(nil, ui.cc)

    local bg = ui.image({img = RES_DICT.BG_FRAME})
    view:addList(bg):alignTo(nil, ui.cc)

    local frameGroup = view:addList({
        ui.layer({size = cc.size(380, 50)}),
        ui.image({img = RES_DICT.BG_LINE}),
        ui.scrollView({size = cc.size(380, 110), dir = display.SDIR_V}),
    })
    ui.flowLayout(cc.sizep(size, ui.cc), frameGroup, {type = ui.flowV, ap = ui.cc})

    local titleLayer = frameGroup[1]
    local timeLabel = ui.label({fnt = FONT.D4, color = "#76553b", text = "--", ap = lc})
    titleLayer:addList(timeLabel):alignTo(nil, ui.lc, {offsetX = 40})

    local weatherIcon = ui.image({img = RES_DICT.WEATHER})
    titleLayer:addList(weatherIcon):alignTo(nil, ui.rc, {offsetX = 30})

    local scrollView = frameGroup[3]
    local journalLabel = ui.label({fnt = FONT.D4, color = "#A48d7a", text = "--", ap = ui.lt, w = scrollView:getContentSize().width - 10})
    scrollView:getContainer():add(journalLabel)


    return {
        view         = view,
        timeLabel    = timeLabel,
        scrollView   = scrollView,
        journalLabel = journalLabel,
        weatherIcon  = weatherIcon,
    }
end

function CatModuleRecordDailyView.CreateView()
    local view = ui.layer({size = VIEW_SIZE})

    local viewFrameGroup = view:addList({
        ui.title({n = RES_DICT.BG_PROG, ml = -10, scale9 = true, ap = ui.lc}):updateLabel({fnt = FONT.D9, color = "#DDBC89", text = "--", offset = cc.p(-20, 0)}),
        ui.gridView({size = cc.size(930, 480), dir = display.SDIR_V, cols = 2, csizeH = 220, mt = -16}),
    })
    ui.flowLayout(cc.rep(cc.sizep(VIEW_SIZE, ui.lt), 20, -4), viewFrameGroup, {type = ui.flowV, ap = ui.lb, gapH = 20})

    local dailyGridView = viewFrameGroup[2]
    dailyGridView:setCellCreateHandler(CatModuleRecordDailyView.CreateDailyCell)

    local emptyTip = ui.title({img = RES_DICT.EMPTY_BG}):updateLabel({fnt = FONT.D4, color = "#cfc6bb", text = __("尚无日记"), reqW = 320, offset = cc.p(50, 5)})
    view:addList(emptyTip):alignTo(nil, ui.cc)


    return {
        view          = view,
        dailyGridView = dailyGridView,
        progress      = viewFrameGroup[1],
        emptyTip      = emptyTip,
    }
end


return CatModuleRecordDailyView

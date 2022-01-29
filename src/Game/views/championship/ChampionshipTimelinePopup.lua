--[[
 * author : kaishiqi
 * descpt : 武道会 - 时间线弹窗
]]
local CommonDialog              = require('common.CommonDialog')
local ChampionshipTimelinePopup = class('ChampionshipTimelinePopup', CommonDialog)

local RES_DICT = {
    VIEW_FRAME   = _res('ui/championship/report/budo_pvp_bg_report.png'),
    CELL_FRAME_N = _res('ui/championship/report/budo_pvp_bg_report_list_grey.png'),
    CELL_FRAME_D = _res('ui/championship/report/budo_pvp_bg_report_list.png'),
    CELL_FRAME_S = _res('ui/championship/report/budo_pvp_btn_report_list_top.png'),
    CELL_CLINE   = _res('ui/championship/report/budo_pvp_bg_time_line_2.png'),
}

local MAIN_PROXY_NAME   = FOOD.CHAMPIONSHIP.MAIN.PROXY_NAME
local MAIN_PROXY_STRUCT = FOOD.CHAMPIONSHIP.MAIN.PROXY_STRUCT


function ChampionshipTimelinePopup:InitialUI()
    self.timelineBeganStep_ = FOOD.CHAMPIONSHIP.STEP.AUDITIONS
    self.timelineEndedStep_ = FOOD.CHAMPIONSHIP.STEP.RESULT_1_1
    self.isControllable_    = true

    -- init model
    self.mainProxy_    = app:RetrieveProxy(MAIN_PROXY_NAME)
    self.scheduleStep_ = self.mainProxy_:get(MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.SCHEDULE_STEP)
    self.isPromotion_  = self.mainProxy_:get(MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.PROMOTION_QUALIFIED) == 1

    -- create view
    self.viewData = ChampionshipTimelinePopup.CreateView()

    -- init view
    self:getViewData().timelineTableView:setCellUpdateHandler(handler(self, self.onUpdateTimelineCellHandler_))

    -- update view
    self:updateTimelineInfo_()
end


function ChampionshipTimelinePopup:onCleanup()
end


function ChampionshipTimelinePopup:getViewData()
    return self.viewData
end


-------------------------------------------------
-- private

function ChampionshipTimelinePopup:calculateStepTime_(stepId)
    local seasonId     = self.mainProxy_:get(MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.SEASON_ID)
    local seasonConf   = CONF.CHAMPIONSHIP.SCHEDULE:GetValue(seasonId)
    local startTime    = checkint(seasonConf.startTimestamp)
    local timelineConf = CONF.CHAMPIONSHIP.TIMELINE:GetValue(tostring(stepId))
    return startTime + checkint(timelineConf.start)
end


function ChampionshipTimelinePopup:updateTimelineInfo_()
    local timelineSteps = self.timelineEndedStep_ - self.timelineBeganStep_ + 1
    self:getViewData().timelineTableView:resetCellCount(timelineSteps)

    local currentCellIndex  = self.scheduleStep_ - self.timelineBeganStep_ + 1
    self:getViewData().timelineTableView:setContentOffsetAt(currentCellIndex)
end


-------------------------------------------------
-- handler


function ChampionshipTimelinePopup:onUpdateTimelineCellHandler_(cellIndex, cellViewData)
    if cellViewData == nil then return end

    local cellStepId = self.timelineBeganStep_ + cellIndex - 1

    if cellStepId == self.scheduleStep_ then
        cellViewData.frameNormal:setVisible(false)
        cellViewData.frameDisable:setVisible(false)
        cellViewData.frameSelect:setVisible(true)
    elseif cellStepId < self.scheduleStep_ then
        cellViewData.frameNormal:setVisible(false)
        cellViewData.frameDisable:setVisible(true)
        cellViewData.frameSelect:setVisible(false)
    else
        cellViewData.frameNormal:setVisible(true)
        cellViewData.frameDisable:setVisible(false)
        cellViewData.frameSelect:setVisible(false)
    end

    local steTitleFunc = self.isPromotion_ and FOOD.CHAMPIONSHIP.MATCH_TITLE[cellStepId] or FOOD.CHAMPIONSHIP.GUESS_TITLE[cellStepId]
    cellViewData.stepLabel:updateLabel({text = steTitleFunc and steTitleFunc() or ''})

    local stepTimestamp = self:calculateStepTime_(cellStepId) - getServerTimezone() + getClientTimezone()
    cellViewData.dateLabel:updateLabel({text = os.date('%Y-%m-%d', stepTimestamp)})
    cellViewData.timeLabel:updateLabel({text = os.date('%H:%M', stepTimestamp)})
end


-------------------------------------------------------------------------------
-- view define
-------------------------------------------------------------------------------

function ChampionshipTimelinePopup.CreateView()
    local size = cc.size(550, 680)
    local view = ui.layer({size = size})
    local cpos = cc.sizep(size, ui.cc)

    -- view frame
    local viewFrameNode = ui.layer({p = cpos, bg = RES_DICT.VIEW_FRAME, ap = ui.cc, enable = true})
    local viewFrameSize = viewFrameNode:getContentSize()
    view:add(viewFrameNode)

    -- title bar
    local titleBar = ui.label({fnt = FONT.D14, text = __('时间表')})
    viewFrameNode:addList(titleBar):alignTo(nil, ui.ct, {offsetY = -70})

    -- report group
    local timelineTableSize = cc.resize(viewFrameSize, -40, -140)
    local timelineTableView = ui.tableView({size = timelineTableSize, dir = display.SDIR_V, csizeH = 100})
    viewFrameNode:addList(timelineTableView):alignTo(nil, ui.cc, {offsetX = 2, offsetY = -30})
    timelineTableView:setCellCreateHandler(ChampionshipTimelinePopup.CreateTimelineCell)

    return {
        view              = view,
        teamVDList        = teamVDList,
        timelineTableView = timelineTableView,
    }
end


function ChampionshipTimelinePopup.CreateTimelineCell(cellParent)
    local view = cellParent
    local size = view:getContentSize()
    local cpos = cc.sizep(size, ui.cc)

    -- frame [normal | disable | select]
    local frameSize = cc.resize(size, -4, -8)
    local frameCut  = cc.dir(20, 20, 20, 20)
    local frameGroup = view:addList({
        ui.image({img = RES_DICT.CELL_FRAME_D, cut = frameCut, size = frameSize}),
        ui.image({img = RES_DICT.CELL_FRAME_N, cut = frameCut, size = frameSize}),
        ui.image({img = RES_DICT.CELL_FRAME_S, cut = frameCut, size = frameSize}),
    })
    ui.flowLayout(cpos, frameGroup, {type = ui.flowC, ap = ui.cc})

    -- cline image
    view:add(ui.image({img = RES_DICT.CELL_CLINE, p = cc.rep(cpos, -80, 0)}))

    -- step label
    local stepLabel = ui.label({fnt = FONT.D1, color = '#6C2923', fontSize = 24, w = 300, hAlign = display.TAC})
    view:addList(stepLabel):alignTo(nil, ui.cc, {offsetX = 90})
    
    -- date label
    local dateLabel = ui.label({fnt = FONT.D3, color = '#775134', ap = ui.lb})
    view:addList(dateLabel):alignTo(nil, ui.lc, {offsetX = 25, offsetY = 2})

    -- time label
    local timeLabel = ui.label({fnt = FONT.D3, color = '#A38670', ap = ui.lt})
    view:addList(timeLabel):alignTo(nil, ui.lc, {offsetX = 25, offsetY = -2})
    
    return {
        view         = view,
        frameNormal  = frameGroup[1],
        frameDisable = frameGroup[2],
        frameSelect  = frameGroup[3],
        stepLabel    = stepLabel,
        dateLabel    = dateLabel,
        timeLabel    = timeLabel,
    }
end


return ChampionshipTimelinePopup

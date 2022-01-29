--[[
 * author : kaishiqi
 * descpt : 打牌游戏 - PVP开放时间弹窗
]]
local CommonDialog           = require('common.CommonDialog')
local TTGamePvpOpenDatePopup = class('TripleTriadGamePvpOpenDatePopup', CommonDialog)

local RES_DICT = {
    BG_FRAME      = _res('ui/common/common_bg_9.png'),
    COM_TITLE     = _res('ui/common/common_bg_title_2.png'),
    LIST_FRAME_BG = _res('ui/home/capsule/draw_probability_text_bg.png'),
    LIST_CELL_BG  = _res('ui/home/capsule/draw_probability_text_frame.png'),
}

local CreateView     = nil
local CreateDateCell = nil


function TTGamePvpOpenDatePopup:InitialUI()
    -- init vars
    self.dateCellDict_ = {}
    self.dateListData_ = {}

    -- create view
    self.viewData = CreateView()

    -- add listener
    self:getViewData().dateListView:setDataSourceAdapterScriptHandler(handler(self, self.onDateListDataAdapterHandler_))

    -- update view
    local dateListData = {}
    for _, scheduleId in ipairs(self.args.scheduleIdList or {}) do
        local scheduleConf = TTGameUtils.GetConfAt(TTGAME_DEFINE.CONF_TYPE.SCHEDULE, scheduleId)
        local openDate   = checkstr(scheduleConf.date)
        local beginTime   = checkstr(scheduleConf.pvpStartTime)
        local endedTime   = checkstr(scheduleConf.pvpEndTime)
        if string.len(beginTime) > 0 and string.len(endedTime) > 0 then
            table.insert(dateListData, {
                scheduleId = scheduleId,
                openDate   = openDate,
                beginTime  = beginTime,
                endedTime  = endedTime,
            })
        end
    end
    self:setDateListData(dateListData)
end


CreateView = function()
    local size = cc.size(460, 600)
    local view = display.newLayer(0, 0, {size = size, bg = RES_DICT.BG_FRAME, scale9 = true})

    local titleBar = display.newButton(size.width/2, size.height - 20, {n = RES_DICT.COM_TITLE, enable = false})
    display.commonLabelParams(titleBar, fontWithColor(3, {text = __('开放时间'), offset = cc.p(0, -2)}))
    view:addChild(titleBar)

    local dateFrameSize = cc.size(size.width - 80, size.height - 80)
    view:addChild(display.newImageView(RES_DICT.LIST_FRAME_BG, size.width/2, 20, {ap = display.CENTER_BOTTOM, size = dateFrameSize, scale9 = true}))

    local dateListSize = cc.size(dateFrameSize.width - 6, dateFrameSize.height - 6)
    local dateListView = CTableView:create(dateListSize)
    dateListView:setSizeOfCell(cc.size(dateListSize.width, 70))
    dateListView:setDirection(eScrollViewDirectionVertical)
    dateListView:setAnchorPoint(display.CENTER_BOTTOM)
    dateListView:setPosition(size.width/2, 23)
    -- dateListView:setBackgroundColor(cc.r4b(250))
    view:addChild(dateListView)
    
    return {
        view         = view,
        dateListView = dateListView,
    }
end


CreateDateCell = function(size)
    local view = CTableViewCell:new()
    view:setContentSize(size)

    local infoSize  = cc.size(size.width, size.height/2)
    local dateLayer = display.newLayer(size.width/2, size.height/2, {size = infoSize, color1 = '#493328', ap = display.CENTER_BOTTOM})
    local timeLayer = display.newLayer(size.width/2, size.height/2, {size = infoSize, color1 = '#826d5e', ap = display.CENTER_TOP})
    view:addChild(dateLayer)
    view:addChild(timeLayer)

    timeLayer:addChild(display.newImageView(RES_DICT.LIST_CELL_BG, infoSize.width/2, infoSize.height/2, {scale9 = true, size = infoSize}))
    
    local dateLabel = display.newLabel(20, infoSize.height/2, fontWithColor(3, {color = '#9b7e68', text = '----', ap = display.LEFT_CENTER}))
    local timeLabel = display.newLabel(infoSize.width - 20, infoSize.height/2, fontWithColor(3, {color = '#6c4a31', text = '----', ap = display.RIGHT_CENTER}))
    dateLayer:addChild(dateLabel)
    timeLayer:addChild(timeLabel)

    return {
        view      = view,
        dateLabel = dateLabel,
        timeLabel = timeLabel,
    }
end


function TTGamePvpOpenDatePopup:getViewData()
    return self.viewData
end


function TTGamePvpOpenDatePopup:getDateListData()
    return self.dateListData_
end
function TTGamePvpOpenDatePopup:setDateListData(data)
    self.dateListData_ = data or {}
    self:getViewData().dateListView:setCountOfCell(#self:getDateListData())
    self:getViewData().dateListView:reloadData()
end


function TTGamePvpOpenDatePopup:initDateCell_(viewData)
end
function TTGamePvpOpenDatePopup:updateDateCell_(cellIndex, viewData)
    local dateListView = self:getViewData().dateListView
    local cellViewData = viewData or self.dateCellDict_[dateListView:cellAtIndex(cellIndex - 1)]
    local cellListData = self:getDateListData()[cellIndex] or {}

    if cellViewData then
        local dateString   = checkstr(cellListData.openDate)
        local timeString   = string.fmt('%1 - %2', checkstr(cellListData.beginTime), checkstr(cellListData.endedTime))
        display.commonLabelParams(cellViewData.dateLabel, {text = dateString})
        display.commonLabelParams(cellViewData.timeLabel, {text = timeString})
    end
end


function TTGamePvpOpenDatePopup:onDateListDataAdapterHandler_(cell, idx)
    local pCell = cell
    local index = idx + 1

    if pCell == nil then
        local cellNodeSize = self:getViewData().dateListView:getSizeOfCell()
        local cellViewData = CreateDateCell(cellNodeSize)
        self.dateCellDict_[cellViewData.view] = cellViewData
        self:initDateCell_(cellViewData)
        pCell = cellViewData.view
    end
    
    local cellViewData = self.dateCellDict_[pCell]
    self:updateDateCell_(index, cellViewData)
    return pCell
end


return TTGamePvpOpenDatePopup
